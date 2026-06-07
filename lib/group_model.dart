class Group {
  final int? id;
  final String name;
  final String schedule; // Masalan: "Dush-Sesh-Chor"
  final String time;
  final double price; // Yangi maydon
  final int studentCount;

  Group({
    this.id,
    required this.name,
    required this.schedule,
    required this.time,
    required this.price,
    this.studentCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schedule': schedule,
      'time': time,
      'price': price,
    };
  }

  factory Group.fromMap(Map<String, dynamic> map) {
    return Group(
      id: map['id'],
      name: map['name'],
      schedule: map['schedule'],
      time: map['time'],
      price: (map['price'] ?? 0).toDouble(),
      studentCount: map['student_count'] ?? 0,
    );
  }
}
