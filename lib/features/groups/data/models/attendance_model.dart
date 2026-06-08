class Attendance {
  final int? id;
  final int studentId;
  final int groupId;
  final String date;
  final bool isPresent;

  Attendance({
    this.id,
    required this.studentId,
    required this.groupId,
    required this.date,
    required this.isPresent,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'student_id': studentId,
      'group_id': groupId,
      'date': date,
      'is_present': isPresent ? 1 : 0,
    };
  }

  factory Attendance.fromMap(Map<String, dynamic> map) {
    return Attendance(
      id: map['id'],
      studentId: map['student_id'],
      groupId: map['group_id'],
      date: map['date'],
      isPresent: map['is_present'] == 1,
    );
  }
}
