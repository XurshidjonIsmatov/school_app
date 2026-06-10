import 'package:school_app/features/payments/domain/enums/charge_status.dart';
import 'package:school_app/features/payments/domain/enums/payment_method.dart';
import 'package:school_app/features/payments/domain/enums/payment_type.dart';

class StudentFinanceEntity {
  final int studentId;
  final String fullName;
  final String phone;
  final int? groupId;
  final String? groupName;
  final PaymentType paymentType;
  final PaymentMethod paymentMethod;
  final double monthlyFee;
  final double? individualMonthlyFee;
  final double effectiveMonthlyFee;
  final double depositBalance;
  final double currentMonthCharge;
  final double currentMonthPaid;
  final double currentMonthDue;
  final double totalDebt;
  final DateTime? lastPaymentDate;
  final ChargeStatus currentMonthStatus;

  const StudentFinanceEntity({
    required this.studentId,
    required this.fullName,
    required this.phone,
    this.groupId,
    this.groupName,
    required this.paymentType,
    required this.paymentMethod,
    required this.monthlyFee,
    this.individualMonthlyFee,
    required this.effectiveMonthlyFee,
    required this.depositBalance,
    required this.currentMonthCharge,
    required this.currentMonthPaid,
    required this.currentMonthDue,
    required this.totalDebt,
    this.lastPaymentDate,
    required this.currentMonthStatus,
  });

  bool get isPaidThisMonth =>
      currentMonthDue <= 0 && currentMonthCharge > 0;
}
