import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/features/settings/data/models/template_model.dart';
import 'package:school_app/core/providers/student_provider.dart';

class TemplateSettingsScreen extends StatelessWidget {
  const TemplateSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Xabar shablonlari')),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.templates.isEmpty) {
            return const Center(child: Text('Hozircha shablonlar yo\'q'));
          }
          return ListView.builder(
            itemCount: provider.templates.length,
            itemBuilder: (context, index) {
              final template = provider.templates[index];
              return Dismissible(
                key: Key('template_${template.id}'),
                direction: DismissDirection.horizontal,
                confirmDismiss: (direction) async {
                  if (direction == DismissDirection.startToEnd) {
                    _showEditDialog(context, template);
                    return false; // Tahrirlashda element o'chib ketmasligi kerak
                  } else {
                    return await _confirmDelete(context, template);
                  }
                },
                onDismissed: (direction) {
                  if (direction == DismissDirection.endToStart) {
                    provider.deleteTemplate(template.id!);
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
                  color: Colors.red.withValues(alpha: 0.2),
                  child: const Icon(Icons.delete_outline, color: Colors.white),
                ),
                child: ListTile(
                title: Text(template.title),
                subtitle: Text(
                  template.content,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                leading: Icon(
                  template.type == 'telegram' ? Icons.send : Icons.sms,
                  color: Colors.blueAccent,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, color: Colors.blue),
                      onPressed: () => _showEditDialog(context, template),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _confirmDelete(context, template),
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

  void _showEditDialog(BuildContext context, MessageTemplate template) {
    final titleController = TextEditingController(text: template.title);
    final contentController = TextEditingController(text: template.content);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.edit_note_rounded),
        title: const Text('Shablonni tahrirlash'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Shablon nomi'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: contentController,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Xabar matni',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Placeholderlar: [ism], [qarz]',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton.tonal(
            onPressed: () {
              context.read<StudentProvider>().updateTemplate(
                MessageTemplate(
                  id: template.id,
                  title: titleController.text.trim(),
                  content: contentController.text.trim(),
                  type: template.type,
                ),
              );
              Navigator.pop(ctx);
            },
            child: const Text('Saqlash'),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDelete(
      BuildContext context, MessageTemplate template) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.delete_sweep_outlined, color: Colors.red),
        title: const Text('Shablonni o\'chirish'),
        content: Text('"${template.title}" shablonini o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Ortga'),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(ctx, true),
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
