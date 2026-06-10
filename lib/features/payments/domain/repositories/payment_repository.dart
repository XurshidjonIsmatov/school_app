import 'package:school_app/features/payments/data/models/monthly_charge_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/features/payments/domain/entities/dashboard_stats_entity.dart';
import 'package:school_app/features/payments/domain/entities/student_finance_entity.dart';
import 'package:school_app/features/students/data/models/student_model.dart';

abstract class PaymentRepository {
  Future<int> createMonthlyCharge(MonthlyChargeModel charge);
  Future<void> updateMonthlyCharge(MonthlyChargeModel charge);
  Future<List<MonthlyChargeModel>> getChargesByStudent(int studentId);
  Future<MonthlyChargeModel?> getChargeForPeriod(
    int studentId,
    int month,
    int year,
  );
  Future<List<MonthlyChargeModel>> getUnpaidCharges(int studentId);
  Future<List<MonthlyChargeModel>> getAllChargesForMonth(int month, int year);
  Future<List<Student>> getMonthlyStudents();
  Future<Student?> getStudentById(int id);
  Future<void> updateStudentDeposit(int studentId, double balance);
  Future<void> updateStudent(Student student);
  Future<double?> getGroupMonthlyFee(int groupId);
  Future<int> createPaymentRecord(Payment payment);
  Future<List<Payment>> getPaymentsByStudent(int studentId);
  Future<Payment?> getLastPayment(int studentId);
  Future<List<Map<String, dynamic>>> getMonthlyPaymentsReport(String monthYear);
  Future<List<StudentFinanceEntity>> getAllStudentFinance(int month, int year);
  Future<DashboardStatsEntity> getDashboardStats(int month, int year);
}
