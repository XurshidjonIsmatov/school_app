enum ChargeStatus {
  paid('paid'),
  partial('partial'),
  unpaid('unpaid');

  const ChargeStatus(this.value);
  final String value;

  static ChargeStatus fromString(String? value) {
    return ChargeStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => ChargeStatus.unpaid,
    );
  }

  String get label {
    switch (this) {
      case ChargeStatus.paid:
        return 'To\'langan';
      case ChargeStatus.partial:
        return 'Qisman';
      case ChargeStatus.unpaid:
        return 'To\'lanmagan';
    }
  }
}
