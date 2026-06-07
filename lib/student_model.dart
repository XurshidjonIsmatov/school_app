class Student {
  final int? id;
  final String name;
  final String phone;
  final String parentPhone;

  Student({
    this.id,
    required this.name,
    required this.phone,
    required this.parentPhone,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      parentPhone: map['parent_phone'],
    );
  }
}
