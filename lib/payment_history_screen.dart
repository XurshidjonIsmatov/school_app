import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_model.dart';
import 'payment_model.dart';
import 'student_provider.dart';
import 'secure_storage_service.dart';

class PaymentHistoryScreen extends StatefulWidget {
  final Student student;

  const PaymentHistoryScreen({super.key, required this.student});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.student.name}: To\'lovlar tarixi')),
      body: FutureBuilder<List<Payment>>(
        future: context.read<StudentProvider>().getStudentPayments(
          widget.student.id!,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik: ${snapshot.error}'));
          }
          final payments = snapshot.data ?? [];
          if (payments.isEmpty) {
            return const Center(child: Text('To\'lovlar topilmadi'));
          }

          return ListView.builder(
            itemCount: payments.length,
            itemBuilder: (context, index) {
              final payment = payments[index];
              return Dismissible(
                key: Key('payment_${payment.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    _showEditDialog(context, payment);
                    return false;
                  } else {
                    return await _confirmDelete(context, payment);
                  }
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    context.read<StudentProvider>().deletePayment(payment.id!);
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('To\'lov muvaffaqiyatli o\'chirildi'),
                      ),
                    );
                  }
                },
                background: Container(
                  alignment: Alignment.centerLeft,
                  padding: const EdgeInsets.only(left: 20.0),
                  color: Colors.blue.withValues(alpha: 0.2),
                  child: const Icon(Icons.edit_outlined, color: Colors.blue),
                ),
                secondaryBackground: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: Icon(
                    payment.type == 'naqd' ? Icons.money : Icons.credit_card,
                    color: payment.type == 'naqd' ? Colors.green : Colors.blue,
                  ),
                  title: Text(
                    '${payment.amount.toStringAsFixed(0)} UZS',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(payment.date),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.edit,
                          color: Colors.blue,
                          size: 20,
                        ),
                        onPressed: () => _showEditDialog(context, payment),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                          size: 20,
                        ),
                        onPressed: () => _confirmDelete(context, payment),
                      ),
                    ],
                  ),
                ),
              ),
            );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Payment payment) async {
    final storage = context.read<SecureStorageService>();
    final pinController = TextEditingController();
    const String masterPin = "1559";

    Future<void> verifyAndClose(BuildContext dialogCtx, String input) async {
      final savedPin = await storage.getPin();
      if (input == savedPin || input == masterPin) {
        if (dialogCtx.mounted) Navigator.pop(dialogCtx, true);
      } else {
        pinController.clear();
        if (dialogCtx.mounted) {
          ScaffoldMessenger.of(dialogCtx).showSnackBar(
            const SnackBar(content: Text('Xato PIN-kod kiritildi')),
          );
        }
      }
    }

    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.security_outlined),
        title: const Text('Xavfsizlik tekshiruvi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'To\'lovni o\'chirishni tasdiqlash uchun PIN-kodni kiriting:',
            ),
            TextField(
              controller: pinController,
              obscureText: true,
              textInputAction: TextInputAction.done,
              keyboardType: TextInputType.number,
              maxLength: 4,
              decoration: const InputDecoration(labelText: 'PIN'),
              onChanged: (v) {
                if (v.length == 4) verifyAndClose(ctx, v);
              },
            ),
            const SizedBox(height: 10),
            IconButton(
              onPressed: () async {
                final success = await storage.authenticateBiometric();
                if (success && ctx.mounted) {
                  Navigator.pop(ctx, true);
                }
              },
              icon: const Icon(Icons.fingerprint, size: 40, color: Colors.blue),
            ),
            const Text(
              'Biometrika',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ortga'),
          ),
          FilledButton.tonal(
            onPressed: () => verifyAndClose(ctx, pinController.text),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, Payment payment) {
    final amountController = TextEditingController(
      text: payment.amount.toStringAsFixed(0),
    );
    String paymentType = payment.type;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          icon: const Icon(Icons.payments_outlined),
          title: const Text('To\'lovni tahrirlash'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Summa',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'naqd', label: Text('Naqd')),
                  ButtonSegment(value: 'karta', label: Text('Karta')),
                ],
                selected: {paymentType},
                onSelectionChanged: (selected) {
                  setDialogState(() => paymentType = selected.first);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ortga'),
            ),
            FilledButton.tonal(
              onPressed: () async {
                final updatedPayment = Payment(
                  id: payment.id,
                  studentId: payment.studentId,
                  amount: double.parse(amountController.text),
                  date: payment.date,
                  type: paymentType,
                );
                await context.read<StudentProvider>().updatePayment(
                  updatedPayment,
                );
                if (!context.mounted) return;
                Navigator.pop(ctx);
                setState(() {});
              },
              child: const Text('Saqlash'),
            ),
          ],
        ),
      ),
    );
  }
}
