import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';

class PendingMessagesStatsWidget extends StatelessWidget {
  const PendingMessagesStatsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        final count = provider.pendingMessagesCount;

        if (count == 0) return const SizedBox.shrink();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          color: Colors.blue.shade50,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.blue.shade200),
          ),
          child: InkWell(
            onTap: () => provider.fetchPendingMessagesCount(),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.sync_problem_rounded, color: Colors.blue),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Yuborilmagan xabarlar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text('$count ta xabar navbatda turibdi'),
                      ],
                    ),
                  ),
                  const Icon(Icons.refresh, size: 20, color: Colors.grey),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
