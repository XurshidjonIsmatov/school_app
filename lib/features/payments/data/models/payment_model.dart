import 'package:school_app/features/payments/domain/enums/payment_method.dart';

class Payment {
  final int? id;
  final int studentId;
  final double amount;
  final String date;
  final String type;
  final String? note;

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.date,
    required this.type,
    this.note,
  });

  PaymentMethod get paymentMethod => PaymentMethod.fromString(type);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'date': date,
      'type': type,
      'note': note,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['student_id'],
      amount: (map['amount'] as num).toDouble(),
      date: map['date'],
      type: map['type'],
      note: map['note'],
    );
  }

  Payment copyWith({
    int? id,
    int? studentId,
    double? amount,
    String? date,
    String? type,
    String? note,
  }) {
    return Payment(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      type: type ?? this.type,
      note: note ?? this.note,
    );
  }
}
