import 'package:school_app/features/payments/domain/enums/charge_status.dart';

class MonthlyChargeEntity {
  final int? id;
  final int studentId;
  final double amount;
  final double paidAmount;
  final DateTime chargeDate;
  final int month;
  final int year;
  final ChargeStatus status;

  const MonthlyChargeEntity({
    this.id,
    required this.studentId,
    required this.amount,
    this.paidAmount = 0,
    required this.chargeDate,
    required this.month,
    required this.year,
    required this.status,
  });

  double get remaining => (amount - paidAmount).clamp(0, amount);

  String get periodLabel => '$year-${month.toString().padLeft(2, '0')}';

  MonthlyChargeEntity copyWith({
    int? id,
    int? studentId,
    double? amount,
    double? paidAmount,
    DateTime? chargeDate,
    int? month,
    int? year,
    ChargeStatus? status,
  }) {
    return MonthlyChargeEntity(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      paidAmount: paidAmount ?? this.paidAmount,
      chargeDate: chargeDate ?? this.chargeDate,
      month: month ?? this.month,
      year: year ?? this.year,
      status: status ?? this.status,
    );
  }
}
