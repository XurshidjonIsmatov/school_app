import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'secure_storage_service.dart';
import 'student_provider.dart';
import 'attendance_stats_widget.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().loadAttendance();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Davomat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            onPressed: () async {
              final provider = context.read<StudentProvider>();
              final picked = await showDatePicker(
                context: context,
                initialDate: provider.selectedDate,
                firstDate: DateTime(2023),
                lastDate: DateTime.now(),
              );
              if (picked != null) {
                provider.setSelectedDate(picked);
              }
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.selectedGroupId == null) {
            return const Center(
              child: Text('Davomat uchun avval guruh tanlang'),
            );
          }

          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final students = provider.students;
          if (students.isEmpty) {
            return const Center(child: Text('Guruhda o\'quvchilar yo\'q'));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Sana: ${provider.formattedDate}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const AttendanceStatsWidget(),
              Expanded(
                child: ListView.builder(
                  itemCount: students.length,
                  itemBuilder: (context, index) {
                    final student = students[index];
                    final isPresent =
                        provider.attendanceMap[student.id] ?? false;
                    return CheckboxListTile(
                      title: Text(student.name),
                      value: isPresent,
                      onChanged: (_) => provider.toggleAttendance(student.id!),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton(
                  onPressed: () => _showConfirmationDialog(context, provider),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                  ),
                  child: const Text('Saqlash'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showConfirmationDialog(
    BuildContext context,
    StudentProvider provider,
  ) async {
    final storage = context.read<SecureStorageService>();
    final botToken = await storage.getBotToken();
    final chatId = await storage.getAdminChatId();

    final absentStudents = provider.getAbsentStudents();
    String message =
        "<b>Davomat hisoboti (${provider.formattedDate}):</b>\n\n"
        "Bugun quyidagi o'quvchilar darsga kelmadi:\n";

    for (var s in absentStudents) {
      message += "• ${s.name} (Ota-ona: ${s.parentPhone})\n";
    }

    final TextEditingController controller = TextEditingController(
      text: message,
    );

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Saqlash va Xabar yuborish'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Xabar matnini tahrirlashingiz mumkin:'),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                maxLines: 10,
                decoration: const InputDecoration(border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          ElevatedButton(
            onPressed: () async {
              await provider.saveAttendance(
                botToken: botToken,
                adminChatId: chatId,
                customMessage: controller.text,
              );
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Davomat saqlandi va xabar yuborildi'),
                  ),
                );
              }
            },
            child: const Text('Tasdiqlash'),
          ),
        ],
      ),
    );
  }
}
