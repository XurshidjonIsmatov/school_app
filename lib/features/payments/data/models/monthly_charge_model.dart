import 'package:school_app/features/payments/domain/entities/monthly_charge_entity.dart';
import 'package:school_app/features/payments/domain/enums/charge_status.dart';

class MonthlyChargeModel {
  final int? id;
  final int studentId;
  final double amount;
  final double paidAmount;
  final String chargeDate;
  final int month;
  final int year;
  final ChargeStatus status;

  MonthlyChargeModel({
    this.id,
    required this.studentId,
    required this.amount,
    this.paidAmount = 0,
    required this.chargeDate,
    required this.month,
    required this.year,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'paid_amount': paidAmount,
      'charge_date': chargeDate,
      'month': month,
      'year': year,
      'status': status.value,
    };
  }

  factory MonthlyChargeModel.fromMap(Map<String, dynamic> map) {
    return MonthlyChargeModel(
      id: map['id'],
      studentId: map['student_id'],
      amount: (map['amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0,
      chargeDate: map['charge_date'],
      month: map['month'],
      year: map['year'],
      status: ChargeStatus.fromString(map['status']),
    );
  }

  MonthlyChargeEntity toEntity() {
    return MonthlyChargeEntity(
      id: id,
      studentId: studentId,
      amount: amount,
      paidAmount: paidAmount,
      chargeDate: DateTime.parse(chargeDate),
      month: month,
      year: year,
      status: status,
    );
  }

  MonthlyChargeModel copyWith({
    int? id,
    int? studentId,
    double? amount,
    double? paidAmount,
    String? chargeDate,
    int? month,
    int? year,
    ChargeStatus? status,
  }) {
    return MonthlyChargeModel(
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

  static ChargeStatus computeStatus(double amount, double paidAmount) {
    if (paidAmount <= 0) return ChargeStatus.unpaid;
    if (paidAmount >= amount) return ChargeStatus.paid;
    return ChargeStatus.partial;
  }
}
