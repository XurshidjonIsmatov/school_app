import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/features/payments/presentation/screens/debt_list_screen.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/core/providers/student_provider.dart';

/// Central hub for attendance, payment, and debt reports.
class ReportsHubScreen extends StatefulWidget {
  const ReportsHubScreen({super.key});

  @override
  State<ReportsHubScreen> createState() => _ReportsHubScreenState();
}

class _ReportsHubScreenState extends State<ReportsHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StudentProvider>();
      provider.fetchStudents();
      provider.fetchMonthlyFinance();
      provider.fetchDebtors();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, _) {
        return RefreshIndicator(
          onRefresh: () async {
            await provider.fetchStudents();
            await provider.fetchMonthlyFinance();
            await provider.fetchDebtors();
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _sectionTitle(context, 'Moliyaviy hisobot'),
              _financeSummaryCard(context, provider),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Davomat hisoboti'),
              if (provider.groups.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Guruhlar mavjud emas'),
                    subtitle: Text('Avval guruh yarating'),
                  ),
                )
              else
                ...provider.groups.map(
                  (group) => _groupReportTile(context, provider, group),
                ),
              const SizedBox(height: 24),
              _sectionTitle(context, 'Boshqa hisobotlar'),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.send, color: Colors.blue),
                      title: const Text('Oylik to\'lov hisobotini yuborish'),
                      subtitle: const Text('Telegram orqali admin kanaliga'),
                      onTap: () => _sendPaymentReport(context, provider),
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.warning_amber, color: Colors.red),
                      title: const Text('Qarzdorlar ro\'yxati'),
                      subtitle: Text('${provider.debtors.length} ta qarzdor'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DebtListScreen(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _financeSummaryCard(BuildContext context, StudentProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Joriy oy: ${DateTime.now().toString().substring(0, 7)}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _financeChip('Naqd', provider.monthlyCashTotal, Colors.green),
                _financeChip('Karta', provider.monthlyCardTotal, Colors.blue),
                _financeChip(
                  'Jami',
                  provider.monthlyTotal,
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _financeChip(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 12, color: color)),
        const SizedBox(height: 4),
        Text(
          amount.toStringAsFixed(0),
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _groupReportTile(
    BuildContext context,
    StudentProvider provider,
    Group group,
  ) {
    final currentMonth = DateTime.now().toString().substring(0, 7);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(group.name),
        subtitle: Text('${group.schedule} | ${group.studentCount} o\'quvchi'),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.picture_as_pdf, color: Colors.teal),
              tooltip: 'PDF hisobot',
              onPressed: () =>
                  provider.generateMonthlyPdfReport(group, currentMonth),
            ),
            IconButton(
              icon: const Icon(Icons.table_view, color: Colors.green),
              tooltip: 'Excel hisobot',
              onPressed: () async {
                final path = await provider.generateMonthlyExcelReport(
                  group,
                  currentMonth,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Excel saqlandi: $path')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendPaymentReport(
    BuildContext context,
    StudentProvider provider,
  ) async {
    final storage = context.read<SecureStorageService>();
    final chatId = await storage.getAdminChatId();

    if (chatId == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Telegram bot sozlamalarini to\'ldiring'),
          ),
        );
      }
      return;
    }

    final monthYear = DateTime.now().toString().substring(0, 7);
    await provider.sendMonthlyPaymentReport(
      monthYear,
      adminChatId: chatId,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hisobot Telegramga yuborildi')),
      );
    }
  }
}
