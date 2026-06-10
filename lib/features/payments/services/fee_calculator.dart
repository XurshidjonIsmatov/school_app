class FeeCalculator {
  /// Oylik to'lov: individual yoki guruh narxi
  static double effectiveMonthlyFee({
    required double? individualMonthlyFee,
    required double groupMonthlyFee,
  }) {
    if (individualMonthlyFee != null && individualMonthlyFee > 0) {
      return individualMonthlyFee;
    }
    return groupMonthlyFee;
  }

  /// Oy o'rtasida qo'shilganda pro-rata hisoblash
  static double calculateProRataFee({
    required double monthlyFee,
    required DateTime joinDate,
  }) {
    if (monthlyFee <= 0) return 0;

    final daysInMonth = DateTime(joinDate.year, joinDate.month + 1, 0).day;
    final remainingDays = daysInMonth - joinDate.day;
    if (remainingDays <= 0) return 0;

    final dailyFee = monthlyFee / daysInMonth;
    return dailyFee * remainingDays;
  }

  /// Qo'shilish oyi uchun to'lov miqdorini aniqlash
  static double chargeAmountForMonth({
    required double monthlyFee,
    required DateTime joinDate,
    required int month,
    required int year,
  }) {
    if (monthlyFee <= 0) return 0;

    final isJoinMonth = joinDate.month == month && joinDate.year == year;
    if (isJoinMonth && joinDate.day > 1) {
      return calculateProRataFee(monthlyFee: monthlyFee, joinDate: joinDate);
    }
    return monthlyFee;
  }

  static int daysInMonth(int month, int year) {
    return DateTime(year, month + 1, 0).day;
  }
}
