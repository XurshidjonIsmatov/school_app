import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_model.dart';
import 'student_provider.dart';

class StudentAttendanceHistoryScreen extends StatelessWidget {
  final Student student;

  const StudentAttendanceHistoryScreen({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${student.name}: Davomat tarixi')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: context.read<StudentProvider>().getStudentAttendance(
          student.id!,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Xatolik yuz berdi: ${snapshot.error}'));
          }
          final records = snapshot.data ?? [];
          if (records.isEmpty) {
            return const Center(child: Text('Davomat yozuvlari topilmadi'));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];
              final bool isPresent = record['is_present'] == 1;
              final String date = record['date'];
              final String groupName = record['group_name'];

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: Icon(
                    isPresent ? Icons.check_circle : Icons.cancel,
                    color: isPresent ? Colors.green : Colors.red,
                    size: 32,
                  ),
                  title: Text(
                    isPresent ? 'Keldi' : 'Kelmagan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isPresent ? Colors.green : Colors.red,
                    ),
                  ),
                  subtitle: Text('$groupName | $date'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
