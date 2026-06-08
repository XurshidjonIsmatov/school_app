import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/groups/presentation/screens/add_group_screen.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';

class GroupListScreen extends StatelessWidget {
  const GroupListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.groups.isEmpty) {
            return const Center(child: Text('Guruhlar topilmadi'));
          }

          return ListView.builder(
            itemCount: provider.groups.length,
            itemBuilder: (context, index) {
              final group = provider.groups[index];
              return Dismissible(
                key: Key('group_${group.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddGroupScreen(group: group),
                      ),
                    );
                    return false;
                  } else {
                    return await _confirmDelete(context, group);
                  }
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    provider.deleteGroup(group.id!);
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
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Colors.red,
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: ListTile(
                  title: Text(group.name),
                  subtitle: Text(
                    "${group.schedule} | ${group.time}\n"
                    "O'quvchilar soni: ${group.studentCount} ta",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed:
                            () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => AddGroupScreen(group: group),
                              ),
                            ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(context, group),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context, Group group) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
            title: const Text('Guruhni o\'chirish'),
            content: Text('${group.name} guruhini o\'chirmoqchimisiz?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Ortga'),
              ),
              FilledButton.tonal(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'O\'chirish',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );
  }
}
