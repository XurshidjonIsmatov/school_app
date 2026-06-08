class Payment {
  final int? id;
  final int studentId;
  final double amount;
  final String date;
  final String type; // 'naqd' yoki 'karta'

  Payment({
    this.id,
    required this.studentId,
    required this.amount,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'amount': amount,
      'date': date,
      'type': type,
    };
  }

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'],
      studentId: map['student_id'],
      amount: map['amount'],
      date: map['date'],
      type: map['type'],
    );
  }
}
