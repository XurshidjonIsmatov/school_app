import 'package:school_app/features/payments/domain/enums/payment_method.dart';
import 'package:school_app/features/payments/domain/enums/payment_type.dart';

class Student {
  final int? id;
  final String name;
  final String phone;
  final String parentPhone;
  final String? telegramHandle;
  final String? parentTelegram;
  final String? freeTime;
  final double? customPrice;
  final String? joinDate;
  final int? groupId;
  final PaymentType paymentType;
  final PaymentMethod paymentMethod;
  final double depositBalance;

  Student({
    this.id,
    required this.name,
    required this.phone,
    required this.parentPhone,
    this.telegramHandle,
    this.parentTelegram,
    this.freeTime,
    this.customPrice,
    this.joinDate,
    this.groupId,
    this.paymentType = PaymentType.monthly,
    this.paymentMethod = PaymentMethod.cash,
    this.depositBalance = 0,
  });

  String get fullName => name;
  double? get individualMonthlyFee => customPrice;

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
      'join_date': joinDate,
      'group_id': groupId,
      'payment_type': paymentType.value,
      'payment_method': paymentMethod.value,
      'deposit_balance': depositBalance,
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
      joinDate: map['join_date'],
      groupId: map['group_id'],
      paymentType: PaymentType.fromString(map['payment_type']),
      paymentMethod: PaymentMethod.fromString(map['payment_method']),
      depositBalance: (map['deposit_balance'] as num?)?.toDouble() ?? 0,
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
    String? joinDate,
    int? groupId,
    PaymentType? paymentType,
    PaymentMethod? paymentMethod,
    double? depositBalance,
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
      joinDate: joinDate ?? this.joinDate,
      groupId: groupId ?? this.groupId,
      paymentType: paymentType ?? this.paymentType,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      depositBalance: depositBalance ?? this.depositBalance,
    );
  }
}
