import 'package:school_app/core/database/database_helper.dart';
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

class PaymentRepositoryImpl implements PaymentRepository {
  final DatabaseHelper _db;

  PaymentRepositoryImpl(this._db);

  @override
  Future<int> createMonthlyCharge(MonthlyChargeModel charge) =>
      _db.createMonthlyCharge(charge);

  @override
  Future<void> updateMonthlyCharge(MonthlyChargeModel charge) =>
      _db.updateMonthlyCharge(charge);

  @override
  Future<List<MonthlyChargeModel>> getChargesByStudent(int studentId) =>
      _db.getChargesByStudent(studentId);

  @override
  Future<MonthlyChargeModel?> getChargeForPeriod(
    int studentId,
    int month,
    int year,
  ) => _db.getChargeForPeriod(studentId, month, year);

  @override
  Future<List<MonthlyChargeModel>> getUnpaidCharges(int studentId) =>
      _db.getUnpaidCharges(studentId);

  @override
  Future<List<MonthlyChargeModel>> getAllChargesForMonth(int month, int year) =>
      _db.getAllChargesForMonth(month, year);

  @override
  Future<List<Student>> getMonthlyStudents() => _db.getMonthlyPaymentStudents();

  @override
  Future<Student?> getStudentById(int id) => _db.getStudentById(id);

  @override
  Future<void> updateStudentDeposit(int studentId, double balance) =>
      _db.updateStudentDeposit(studentId, balance);

  @override
  Future<void> updateStudent(Student student) => _db.updateStudent(student);

  @override
  Future<double?> getGroupMonthlyFee(int groupId) =>
      _db.getGroupMonthlyFee(groupId);

  @override
  Future<int> createPaymentRecord(Payment payment) =>
      _db.createPayment(payment);

  @override
  Future<List<Payment>> getPaymentsByStudent(int studentId) =>
      _db.getPaymentsByStudent(studentId);

  @override
  Future<Payment?> getLastPayment(int studentId) =>
      _db.getLastPayment(studentId);

  @override
  Future<List<Map<String, dynamic>>> getMonthlyPaymentsReport(
    String monthYear,
  ) => _db.getMonthlyPaymentsReport(monthYear);

  @override
  Future<List<StudentFinanceEntity>> getAllStudentFinance(
    int month,
    int year,
  ) async {
    final monthYear = '$year-${month.toString().padLeft(2, '0')}';
    final rows = await _db.getStudentsFinanceStatus(monthYear);

    return rows.map((row) {
      final groupFee = (row['group_monthly_fee'] as num?)?.toDouble() ?? 0;
      final individual = (row['custom_price'] as num?)?.toDouble();
      final effective = FeeCalculator.effectiveMonthlyFee(
        individualMonthlyFee: individual,
        groupMonthlyFee: groupFee,
      );

      return StudentFinanceEntity(
        studentId: row['id'],
        fullName: row['name'],
        phone: row['phone'],
        groupId: row['group_id'],
        groupName: row['group_name'],
        paymentType: PaymentType.fromString(row['payment_type']),
        paymentMethod: PaymentMethod.fromString(row['payment_method']),
        monthlyFee: groupFee,
        individualMonthlyFee: individual,
        effectiveMonthlyFee: effective,
        depositBalance: (row['deposit_balance'] as num?)?.toDouble() ?? 0,
        currentMonthCharge: (row['total_required'] as num?)?.toDouble() ?? 0,
        currentMonthPaid: (row['total_paid'] as num?)?.toDouble() ?? 0,
        currentMonthDue: (row['current_due'] as num?)?.toDouble() ?? 0,
        totalDebt: (row['total_debt'] as num?)?.toDouble() ?? 0,
        lastPaymentDate:
            row['last_payment_date'] != null
                ? DateTime.tryParse(row['last_payment_date'])
                : null,
        currentMonthStatus: ChargeStatus.fromString(row['charge_status']),
      );
    }).toList();
  }

  @override
  Future<DashboardStatsEntity> getDashboardStats(int month, int year) async {
    final stats = await _db.getDashboardPaymentStats(month, year);
    return DashboardStatsEntity(
      totalStudents: stats['total_students'] as int,
      paidStudents: stats['paid_students'] as int,
      debtorStudents: stats['debtor_students'] as int,
      expectedRevenue: stats['expected_revenue'] as double,
      cashRevenue: stats['cash_revenue'] as double,
      cardRevenue: stats['card_revenue'] as double,
      totalDeposits: stats['total_deposits'] as double,
    );
  }
}
