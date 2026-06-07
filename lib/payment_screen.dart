import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'student_model.dart';
import 'payment_model.dart';
import 'student_provider.dart';
import 'secure_storage_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _amountController = TextEditingController();
  Student? _selectedStudent;
  String _paymentType = 'naqd'; // 'naqd' yoki 'karta'
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('To\'lovlar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.analytics),
            onPressed: () => _showReportDialog(context, provider),
            tooltip: 'Oylik hisobot',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownMenu<Student>(
                initialSelection: _selectedStudent,
                hintText: 'O\'quvchini tanlang',
                dropdownMenuEntries: provider.students
                    .map(
                      (s) => DropdownMenuEntry<Student>(
                        value: s,
                        label: s.name,
                      ),
                    )
                    .toList(),
                onSelected: (val) => setState(() => _selectedStudent = val),
                expandedInsets: EdgeInsets.zero,
                inputDecorationTheme: const InputDecorationTheme(
                  border: OutlineInputBorder(),
                ),
              ),
              if (_selectedStudent == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'O\'quvchini tanlang',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _amountController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Summa',
                  border: OutlineInputBorder(),
                  prefixText: 'UZS ',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) {
                    return 'Summani kiriting';
                  }
                  if (double.tryParse(v) == null || double.parse(v) <= 0) {
                    return 'To\'g\'ri summa kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'naqd', label: Text('Naqd')),
                  ButtonSegment(value: 'karta', label: Text('Karta')),
                ],
                selected: {_paymentType},
                onSelectionChanged: (selected) {
                  setState(() => _paymentType = selected.first);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () async {
                  if (_selectedStudent == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('O\'quvchini tanlang')),
                    );
                    return;
                  }
                  if (!_formKey.currentState!.validate()) return;

                  await provider.addPayment(
                    Payment(
                      studentId: _selectedStudent!.id!,
                      amount: double.parse(_amountController.text),
                      date: DateTime.now().toString().substring(0, 10),
                      type: _paymentType,
                    ),
                  );

                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('To\'lov saqlandi')),
                  );
                  _amountController.clear();
                  setState(() => _selectedStudent = null);
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('Saqlash'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showReportDialog(
    BuildContext context,
    StudentProvider provider,
  ) async {
    final storage = context.read<SecureStorageService>();
    final botToken = await storage.getBotToken();
    final chatId = await storage.getAdminChatId();
    final currentMonth = DateTime.now().toString().substring(0, 7);

    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Oylik hisobot'),
        content: Text(
          '$currentMonth oyi uchun hisobotni Telegramga yubormoqchimisiz?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.sendMonthlyPaymentReport(
                currentMonth,
                botToken: botToken,
                adminChatId: chatId,
              );
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );
  }
}
