class Student {
  final int? id;
  final String name;
  final String phone;
  final String parentPhone;
  final String? telegramHandle;
  final String? parentTelegram;
  final String? freeTime;
  final double? customPrice;

  Student({
    this.id,
    required this.name,
    required this.phone,
    required this.parentPhone,
    this.telegramHandle,
    this.parentTelegram,
    this.freeTime,
    this.customPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'parent_phone': parentPhone,
      'telegram_handle': telegramHandle,
      'parent_telegram': parentTelegram,
      'free_time': freeTime,
      'custom_price': customPrice,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'],
      name: map['name'],
      phone: map['phone'],
      parentPhone: map['parent_phone'],
      telegramHandle: map['telegram_handle'],
      parentTelegram: map['parent_telegram'],
      freeTime: map['free_time'],
      customPrice: (map['custom_price'] as num?)?.toDouble(),
    );
  }

  Student copyWith({
    int? id,
    String? name,
    String? phone,
    String? parentPhone,
    String? telegramHandle,
    String? parentTelegram,
    String? freeTime,
    double? customPrice,
  }) {
    return Student(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      parentPhone: parentPhone ?? this.parentPhone,
      telegramHandle: telegramHandle ?? this.telegramHandle,
      parentTelegram: parentTelegram ?? this.parentTelegram,
      freeTime: freeTime ?? this.freeTime,
      customPrice: customPrice ?? this.customPrice,
    );
  }
}
