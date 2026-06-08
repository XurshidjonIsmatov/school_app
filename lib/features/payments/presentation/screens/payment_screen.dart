import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/features/payments/data/models/payment_model.dart';
import 'package:school_app/core/providers/student_provider.dart';
class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchPaymentStudents();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Qidiruv paneli
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Student name or phone...',
                prefixIcon: const Icon(Icons.search),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged:
                  (val) => context.read<StudentProvider>().setSearchQuery(val),
            ),
          ),

          // O'quvchilar ro'yxati
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                final students = provider.filteredPaymentStudents;

                if (students.isEmpty) {
                  return const Center(child: Text('No students found.'));
                }

                return ListView.builder(
                  itemCount: students.length,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemBuilder: (context, index) {
                    final data = students[index];
                    final req =
                        (data['total_required'] as num?)?.toDouble() ?? 0.0;
                    final paid =
                        (data['total_paid'] as num?)?.toDouble() ?? 0.0;
                    final debt = req - paid;

                    Color statusColor = Colors.grey;
                    String statusText = "No Groups";

                    if (req > 0) {
                      if (debt <= 0) {
                        statusColor = Colors.green;
                        statusText = "Fully Paid";
                      } else if (paid > 0) {
                        statusColor = Colors.orange;
                        statusText = "Partially Paid";
                      } else {
                        statusColor = Colors.red;
                        statusText = "Not Paid";
                      }
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        onTap: () => _showStudentPaymentDetails(context, data),
                        leading: CircleAvatar(
                          backgroundColor: statusColor.withOpacity(0.1),
                          child: Icon(Icons.person, color: statusColor),
                        ),
                        title: Text(
                          data['name'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          statusText,
                          style: TextStyle(color: statusColor, fontSize: 12),
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "${paid.toStringAsFixed(0)} / ${req.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (debt > 0)
                              Text(
                                "-${debt.toStringAsFixed(0)} UZS",
                                style: const TextStyle(
                                  color: Colors.red,
                                  fontSize: 11,
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showStudentPaymentDetails(
    BuildContext context,
    Map<String, dynamic> studentData,
  ) {
    final student = Student.fromMap(studentData);
    final req = (studentData['total_required'] as num?)?.toDouble() ?? 0.0;
    final paid = (studentData['total_paid'] as num?)?.toDouble() ?? 0.0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (sheetCtx) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (scrollCtx, scrollController) => Column(
                  children: [
                    Container(
                      margin: const EdgeInsets.all(12),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Text(
                      student.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildSummaryItem("Required", req, Colors.blue),
                          _buildSummaryItem("Paid", paid, Colors.green),
                          _buildSummaryItem("Debt", req - paid, Colors.red),
                        ],
                      ),
                    ),
                    const Divider(height: 32),
                    Expanded(
                      child: FutureBuilder<List<Payment>>(
                        future: scrollCtx
                            .read<StudentProvider>()
                            .getStudentPayments(student.id!),
                        builder: (context, snapshot) {
                          final history = snapshot.data ?? [];
                          if (history.isEmpty) {
                            return const Center(
                              child: Text("No payment history"),
                            );
                          }
                          return ListView.builder(
                            controller: scrollController,
                            itemCount: history.length,
                            itemBuilder:
                                (context, i) => ListTile(
                                  leading: Icon(
                                    history[i].type == 'karta'
                                        ? Icons.credit_card
                                        : Icons.money,
                                    size: 20,
                                  ),
                                  title: Text(
                                    "${history[i].amount.toStringAsFixed(0)} UZS",
                                  ),
                                  subtitle: Text(history[i].date),
                                ),
                          );
                        },
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(scrollCtx);
                          _showAddPaymentDialog(context, student);
                        },
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text("Receive Payment"),
                      ),
                    ),
                  ],
                ),
          ),
    );
  }

  Widget _buildSummaryItem(String label, double amount, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        Text(
          amount.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  void _showAddPaymentDialog(BuildContext context, Student student) {
    final controller = TextEditingController();
    String type = 'naqd';

    showDialog(
      context: context,
      builder:
          (dialogCtx) => StatefulBuilder(
            builder:
                (stfCtx, setDialogState) => AlertDialog(
                  title: Text("Payment: ${student.name}"),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: controller,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Amount",
                          prefixText: "UZS ",
                        ),
                      ),
                      const SizedBox(height: 16),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(value: 'naqd', label: Text('Cash')),
                          ButtonSegment(value: 'karta', label: Text('Card')),
                        ],
                        selected: {type},
                        onSelectionChanged:
                            (val) => setDialogState(() => type = val.first),
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogCtx),
                      child: const Text("Cancel"),
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        if (controller.text.isEmpty) return;

                        // Ekran hali ochiqligini tekshiramiz
                        if (!context.mounted) return;
                        final provider = context.read<StudentProvider>();

                        await provider.addPayment(
                          Payment(
                            studentId: student.id!,
                            amount: double.parse(controller.text),
                            date: DateTime.now().toString().substring(0, 10),
                            type: type,
                          ),
                        );

                        // Dialog hali ochiqligini tekshiramiz
                        if (dialogCtx.mounted) Navigator.pop(dialogCtx);
                      },
                      child: const Text("Save"),
                    ),
                  ],
                ),
          ),
    );
  }
}
