import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'student_provider.dart';
import 'student_model.dart';

class AssignGroupDialog extends StatelessWidget {
  final Student student;

  const AssignGroupDialog({super.key, required this.student});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StudentProvider>();
    final groups = provider.groups;

    return AlertDialog(
      title: Text("${student.name}ni guruhga qo'shish"),
      content: groups.isEmpty
          ? const Text("Hozircha guruhlar mavjud emas. Avval guruh yarating.")
          : SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: groups.length,
                itemBuilder: (context, index) {
                  final group = groups[index];
                  return ListTile(
                    title: Text(group.name),
                    subtitle: Text("${group.schedule} | ${group.time}"),
                    onTap: () async {
                      await context
                          .read<StudentProvider>()
                          .assignStudentToGroup(student.id!, group.id!);
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "${student.name} ${group.name} guruhiga qo'shildi",
                            ),
                          ),
                        );
                      }
                    },
                  );
                },
              ),
            ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Yopish"),
        ),
      ],
    );
  }
}
