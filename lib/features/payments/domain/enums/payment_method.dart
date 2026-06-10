enum PaymentMethod {
  cash('cash'),
  card('card');

  const PaymentMethod(this.value);
  final String value;

  static PaymentMethod fromString(String? value) {
    if (value == 'naqd') return PaymentMethod.cash;
    if (value == 'karta') return PaymentMethod.card;
    return PaymentMethod.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentMethod.cash,
    );
  }

  String get dbValue {
    switch (this) {
      case PaymentMethod.cash:
        return 'naqd';
      case PaymentMethod.card:
        return 'karta';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.cash:
        return 'Naqd';
      case PaymentMethod.card:
        return 'Karta';
    }
  }
}
