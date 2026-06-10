enum PaymentType {
  monthly('monthly'),
  fullOnce('full_once');

  const PaymentType(this.value);
  final String value;

  static PaymentType fromString(String? value) {
    return PaymentType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => PaymentType.monthly,
    );
  }

  String get label {
    switch (this) {
      case PaymentType.monthly:
        return 'Oylik';
      case PaymentType.fullOnce:
        return 'Bir martalik';
    }
  }
}
