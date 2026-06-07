import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../student_provider.dart';

class AttendanceStatsWidget extends StatelessWidget {
  const AttendanceStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        final total = provider.totalStudentCount;
        if (total == 0) return const SizedBox.shrink();

        final present = provider.presentCount;
        final absent = provider.absentCount;
        final percent = provider.attendancePercentage;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem(
                      "Kelganlar",
                      present.toString(),
                      Colors.green,
                    ),
                    _buildStatItem(
                      "Kelmaganlar",
                      absent.toString(),
                      Colors.red,
                    ),
                    _buildStatItem(
                      "Davomat",
                      "${(percent * 100).toStringAsFixed(0)}%",
                      Colors.blue,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: percent,
                    minHeight: 8,
                    backgroundColor: Colors.red.shade100,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}
