import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/students/presentation/screens/student_list_screen.dart';
import 'package:school_app/features/groups/presentation/screens/group_list_screen.dart';
import 'package:school_app/features/attendance/presentation/screens/attendance_screen.dart';
import 'package:school_app/features/payments/presentation/screens/payment_screen.dart';
import 'package:school_app/features/payments/presentation/screens/debt_list_screen.dart';
import 'package:school_app/core/widgets/attendance_stats_widget.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    final provider = context.read<StudentProvider>();
    await provider.fetchStudents();
    await provider.fetchMonthlyFinance();
    await provider.fetchStudentFlow();
    await provider.loadAttendance();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        return RefreshIndicator(
          onRefresh: _refreshData,
          child: ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              const SizedBox(height: 16),
              _buildFinanceCard(provider),
              const SizedBox(height: 16),
              _buildStatsGrid(provider),
              const SizedBox(height: 16),
              _buildStudentFlowChart(provider),
              const SizedBox(height: 16),
              const AttendanceStatsWidget(),
              const SizedBox(height: 24),
              const Text(
                'Tezkor Menyular',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _buildGridMenu(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatsGrid(StudentProvider provider) {
    final stats = provider.dashboardStats;
    if (stats == null) return const SizedBox.shrink();

    final items = [
      ('O\'quvchilar', '${stats.totalStudents}', Icons.people),
      ('To\'laganlar', '${stats.paidStudents}', Icons.check_circle),
      ('Qarzdorlar', '${stats.debtorStudents}', Icons.warning),
      ('Kutilayotgan', '${stats.expectedRevenue.toStringAsFixed(0)}', Icons.schedule),
      ('Depozitlar', '${stats.totalDeposits.toStringAsFixed(0)}', Icons.savings),
    ];

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 2.2,
      children:
          items.map((item) {
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Row(
                      children: [
                        Icon(item.$3, size: 18),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.$1,
                            style: const TextStyle(fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.$2,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
    );
  }

  Widget _buildFinanceCard(StudentProvider provider) {
    return _buildGlassContainer(
      color: Theme.of(
        context,
      ).colorScheme.primaryContainer.withValues(alpha: 0.7),
      child: Card(
        color: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Oylik Tushum (Joriy oy)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              const Divider(),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildFinanceItem(
                    'Naqd',
                    provider.monthlyCashTotal,
                    Colors.green.shade700,
                  ),
                  _buildFinanceItem(
                    'Karta',
                    provider.monthlyCardTotal,
                    Colors.blue.shade700,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  'Jami: ${provider.monthlyTotal.toStringAsFixed(0)} UZS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFinanceItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          '${amount.toStringAsFixed(0)} UZS',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassContainer({required Widget child, required Color color}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildStudentFlowChart(StudentProvider provider) {
    final data = provider.studentFlow;
    final monthNames = [
      'Yan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Iyun',
      'Iyul',
      'Avg',
      'Sen',
      'Okt',
      'Noy',
      'Dek',
    ];

    return _buildGlassContainer(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'O\'quvchilar oqimi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 &&
                              value.toInt() < data.length) {
                            int monthIdx =
                                (data[value.toInt()]['month'] as int) - 1;
                            return Padding(
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Text(
                                monthNames[monthIdx],
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots:
                          data.isEmpty
                              ? [const FlSpot(0, 0)]
                              : List.generate(data.length, (index) {
                                return FlSpot(
                                  index.toDouble(),
                                  (data[index]['count'] as int).toDouble(),
                                );
                              }),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 4,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridMenu(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        'title': 'O\'quvchilar',
        'icon': Icons.people_outline_rounded,
        'color': Theme.of(context).colorScheme.primary,
        'screen': const StudentListScreen(),
      },
      {
        'title': 'Guruhlar',
        'icon': Icons.account_tree_outlined,
        'color': Theme.of(context).colorScheme.secondary,
        'screen': const GroupListScreen(),
      },
      {
        'title': 'Davomat',
        'icon': Icons.fact_check_outlined,
        'color': Colors.orange.shade800,
        'screen': const AttendanceScreen(),
      },
      {
        'title': 'To\'lovlar',
        'icon': Icons.account_balance_wallet_outlined,
        'color': Colors.green.shade800,
        'screen': const PaymentScreen(),
      },
      {
        'title': 'Qarzdorlar',
        'icon': Icons.error_outline_rounded,
        'color': Colors.red.shade800,
        'screen': const DebtListScreen(),
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        return AnimationConfiguration.staggeredGrid(
          position: index,
          duration: const Duration(milliseconds: 375),
          columnCount: 2,
          child: ScaleAnimation(
            child: FadeInAnimation(
              child: Card(
                color: Theme.of(context).colorScheme.surface,
                child: InkWell(
                  onTap:
                      () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => item['screen']),
                      ),
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(item['icon'], color: item['color'], size: 30),
                      const SizedBox(height: 8),
                      Text(
                        item['title'],
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
