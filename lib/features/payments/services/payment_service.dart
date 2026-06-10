import 'package:school_app/features/payments/data/models/monthly_charge_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/features/payments/domain/entities/dashboard_stats_entity.dart';
import 'package:school_app/features/payments/domain/entities/student_finance_entity.dart';
import 'package:school_app/features/payments/domain/enums/charge_status.dart';
import 'package:school_app/features/payments/domain/enums/payment_method.dart';
import 'package:school_app/features/payments/domain/enums/payment_type.dart';
import 'package:school_app/features/payments/domain/repositories/payment_repository.dart';
import 'package:school_app/features/payments/services/fee_calculator.dart';
import 'package:school_app/features/students/data/models/student_model.dart';

class PaymentService {
  final PaymentRepository _repository;

  PaymentService(this._repository);

  /// O'quvchi qo'shilganda birinchi oylik qarz yaratish
  Future<void> createInitialChargeForStudent(Student student) async {
    if (student.paymentType != PaymentType.monthly) return;
    if (student.id == null) return;

    final joinDate =
        student.joinDate != null
            ? DateTime.parse(student.joinDate!)
            : DateTime.now();
    final month = joinDate.month;
    final year = joinDate.year;

    final existing = await _repository.getChargeForPeriod(
      student.id!,
      month,
      year,
    );
    if (existing != null) return;

    final groupFee =
        student.groupId != null
            ? await _repository.getGroupMonthlyFee(student.groupId!) ?? 0
            : 0;

    final monthlyFee = FeeCalculator.effectiveMonthlyFee(
      individualMonthlyFee: student.individualMonthlyFee,
      groupMonthlyFee: groupFee.toDouble(),
    );

    if (monthlyFee <= 0) return;

    final amount = FeeCalculator.chargeAmountForMonth(
      monthlyFee: monthlyFee,
      joinDate: joinDate,
      month: month,
      year: year,
    );

    await _createChargeWithDeposit(
      studentId: student.id!,
      amount: amount,
      month: month,
      year: year,
      chargeDate: joinDate,
      depositBalance: student.depositBalance,
    );
  }

  /// Har oyning 1-sanasida barcha monthly o'quvchilar uchun qarz yaratish
  Future<int> generateMonthlyCharges({DateTime? forDate}) async {
    final date = forDate ?? DateTime.now();
    final month = date.month;
    final year = date.year;
    final chargeDate = DateTime(year, month, 1);

    final students = await _repository.getMonthlyStudents();
    var created = 0;

    for (final student in students) {
      if (student.id == null) continue;

      final existing = await _repository.getChargeForPeriod(
        student.id!,
        month,
        year,
      );
      if (existing != null) continue;

      final joinDate =
          student.joinDate != null
              ? DateTime.parse(student.joinDate!)
              : DateTime(year, month, 1);

      // Qo'shilish oyi allaqachon yaratilgan bo'lsa, o'tkazib yuborish
      if (joinDate.year == year &&
          joinDate.month == month &&
          joinDate.day > 1) {
        continue;
      }

      final groupFee =
          student.groupId != null
              ? await _repository.getGroupMonthlyFee(student.groupId!) ?? 0
              : 0;

      final monthlyFee = FeeCalculator.effectiveMonthlyFee(
        individualMonthlyFee: student.individualMonthlyFee,
        groupMonthlyFee: groupFee.toDouble(),
      );

      if (monthlyFee <= 0) continue;

      await _createChargeWithDeposit(
        studentId: student.id!,
        amount: monthlyFee,
        month: month,
        year: year,
        chargeDate: chargeDate,
        depositBalance: student.depositBalance,
      );
      created++;
    }

    return created;
  }

  Future<void> _createChargeWithDeposit({
    required int studentId,
    required double amount,
    required int month,
    required int year,
    required DateTime chargeDate,
    required double depositBalance,
  }) async {
    var paidFromDeposit = 0.0;
    var remainingDeposit = depositBalance;

    if (depositBalance > 0) {
      paidFromDeposit = depositBalance >= amount ? amount : depositBalance;
      remainingDeposit = depositBalance - paidFromDeposit;
    }

    final paidAmount = paidFromDeposit;
    final status = MonthlyChargeModel.computeStatus(amount, paidAmount);

    await _repository.createMonthlyCharge(
      MonthlyChargeModel(
        studentId: studentId,
        amount: amount,
        paidAmount: paidAmount,
        chargeDate: chargeDate.toIso8601String().substring(0, 10),
        month: month,
        year: year,
        status: status,
      ),
    );

    if (paidFromDeposit > 0) {
      await _repository.updateStudentDeposit(studentId, remainingDeposit);
    }
  }

  /// To'lov qabul qilish: avval qarzlarga, ortiqcha depozitga
  Future<void> processPayment({
    required int studentId,
    required double amount,
    required PaymentMethod method,
    String? note,
  }) async {
    if (amount <= 0) return;

    var remaining = amount;
    final student = await _repository.getStudentById(studentId);
    if (student == null) return;

    final unpaidCharges = await _repository.getUnpaidCharges(studentId);

    for (final charge in unpaidCharges) {
      if (remaining <= 0) break;
      if (charge.id == null) continue;

      final due = charge.amount - charge.paidAmount;
      if (due <= 0) continue;

      final applied = remaining >= due ? due : remaining;
      final newPaid = charge.paidAmount + applied;
      final status = MonthlyChargeModel.computeStatus(charge.amount, newPaid);

      await _repository.updateMonthlyCharge(
        charge.copyWith(paidAmount: newPaid, status: status),
      );
      remaining -= applied;
    }

    var newDeposit = student.depositBalance;
    if (remaining > 0) {
      newDeposit += remaining;
      await _repository.updateStudentDeposit(studentId, newDeposit);
    }

    await _repository.createPaymentRecord(
      Payment(
        studentId: studentId,
        amount: amount,
        date: DateTime.now().toIso8601String().substring(0, 10),
        type: method.dbValue,
        note: note,
      ),
    );
  }

  Future<StudentFinanceEntity?> getStudentFinance(int studentId) async {
    final now = DateTime.now();
    final all = await _repository.getAllStudentFinance(now.month, now.year);
    for (final finance in all) {
      if (finance.studentId == studentId) return finance;
    }
    return null;
  }

  Future<List<StudentFinanceEntity>> getAllStudentFinance() async {
    final now = DateTime.now();
    return _repository.getAllStudentFinance(now.month, now.year);
  }

  Future<DashboardStatsEntity> getDashboardStats() async {
    final now = DateTime.now();
    return _repository.getDashboardStats(now.month, now.year);
  }

  Future<List<MonthlyChargeModel>> getStudentCharges(int studentId) =>
      _repository.getChargesByStudent(studentId);
}
