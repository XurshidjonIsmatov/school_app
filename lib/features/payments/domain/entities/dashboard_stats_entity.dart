class DashboardStatsEntity {
  final int totalStudents;
  final int paidStudents;
  final int debtorStudents;
  final double expectedRevenue;
  final double cashRevenue;
  final double cardRevenue;
  final double totalDeposits;

  const DashboardStatsEntity({
    required this.totalStudents,
    required this.paidStudents,
    required this.debtorStudents,
    required this.expectedRevenue,
    required this.cashRevenue,
    required this.cardRevenue,
    required this.totalDeposits,
  });
}
