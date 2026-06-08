import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/features/settings/data/models/template_model.dart';
import 'package:school_app/core/providers/student_provider.dart';

class DebtListScreen extends StatefulWidget {
  const DebtListScreen({super.key});

  @override
  State<DebtListScreen> createState() => _DebtListScreenState();
}

class _DebtListScreenState extends State<DebtListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StudentProvider>().fetchDebtors();
      context.read<StudentProvider>().fetchTemplates();
    });
  }

  /// SMS yuborish funksiyasi
  Future<void> _sendSMS(String phoneNumber, String message) async {
    final Uri smsLaunchUri = Uri(
      scheme: 'sms',
      path: phoneNumber,
      queryParameters: <String, String>{'body': message},
    );
    if (await canLaunchUrl(smsLaunchUri)) {
      await launchUrl(smsLaunchUri);
    }
  }

  /// Barcha qarzdorlarga SMS yuborish (Navbat bilan)
  Future<void> _sendBulkSMS(List<Map<String, dynamic>> debtors) async {
    if (debtors.isEmpty) return;

    const defaultTemplate =
        "Salom, [ism]ning o'quv markazidan qarzi [qarz] so'mni tashkil qilmoqda. Iltimos, to'lovni amalga oshiring.";
    final String? customTemplate = await _showEditTemplateDialog(
      'sms',
      defaultTemplate,
    );

    if (customTemplate == null || customTemplate.isEmpty) return;
    if (!mounted) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ommaviy SMS yuborish'),
        content: Text(
          '${debtors.length} ta o\'quvchiga SMS tayyorlanmoqda. Davom etasizmi?\n\nEslatma: Har bir xabarni SMS ilovasida tasdiqlashingiz kerak bo\'ladi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Bekor qilish'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yuborish'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    for (final data in debtors) {
      final required = (data['total_required'] as num).toDouble();
      final paid = (data['total_paid'] as num?)?.toDouble() ?? 0.0;
      final debt = required - paid;
      final msg = customTemplate
          .replaceAll('[ism]', data['name'])
          .replaceAll('[qarz]', debt.toStringAsFixed(0));
      final phone = data['parent_phone'] ?? data['phone'];

      await _sendSMS(phone, msg);
      // Operatsion tizim SMS ilovasini ochishi uchun vaqt beramiz
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  /// Xabar shablonini tahrirlash dialogi (Telegram yoki SMS)
  Future<String?> _showEditTemplateDialog(
    String type,
    String initialMessage,
  ) async {
    final controller = TextEditingController(text: initialMessage);
    final titleController = TextEditingController();
    bool saveAsTemplate = false;
    final String label = type == 'telegram' ? 'Telegram' : 'SMS';

    return showDialog<String>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) {
            final provider = context.watch<StudentProvider>();
            return AlertDialog(
              title: Text('$label xabarini tahrirlash'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (provider.templates.any((t) => t.type == type)) ...[
                      DropdownButtonFormField<MessageTemplate>(
                        decoration: const InputDecoration(
                          labelText: 'Shablonni tanlang',
                          border: OutlineInputBorder(),
                        ),
                        items: provider.templates
                            .where((t) => t.type == type)
                            .map(
                              (t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.title),
                              ),
                            )
                            .toList(),
                        onChanged: (template) {
                          if (template != null) {
                            controller.text = template.content;
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    const Text(
                      'Placeholderlar: [ism] - Ism, [qarz] - Summa',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: controller,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Xabar matni...',
                      ),
                    ),
                    const SizedBox(height: 10),
                    CheckboxListTile(
                      title: const Text('Shablon sifatida saqlash'),
                      value: saveAsTemplate,
                      onChanged: (val) => setState(() => saveAsTemplate = val!),
                    ),
                    if (saveAsTemplate)
                      TextField(
                        controller: titleController,
                        decoration: const InputDecoration(
                          labelText: 'Shablon nomi',
                          hintText: 'Masalan: Bayram tabrigi',
                        ),
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
                  onPressed: () {
                    if (saveAsTemplate && titleController.text.isNotEmpty) {
                      provider.addTemplate(
                        MessageTemplate(
                          title: titleController.text.trim(),
                          content: controller.text.trim(),
                          type: type,
                        ),
                      );
                    }
                    Navigator.pop(ctx, controller.text);
                  },
                  child: const Text('Saqlash'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Barcha qarzdorlarga Telegram orqali xabar yuborish
  Future<void> _sendBulkTelegram(List<Map<String, dynamic>> debtors) async {
    if (debtors.isEmpty) return;

    final storage = context.read<SecureStorageService>();
    final provider = context.read<StudentProvider>();

    const defaultTemplate =
        "⚠️ <b>Qarz haqida eslatma</b>\n\nO'quvchi: <b>[ism]</b>\nQarzdorlik miqdori: <b>[qarz] UZS</b>\n\n<i>Iltimos, to'lovni o'z vaqtida amalga oshiring.</i>";
    final String? customTemplate = await _showEditTemplateDialog(
      'telegram',
      defaultTemplate,
    );

    if (customTemplate == null || customTemplate.isEmpty) return;

    final chatId = await storage.getAdminChatId();

    if (!mounted) return;

    if (chatId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Telegram sozlamalari topilmadi')),
      );
      return;
    }

    for (final data in debtors) {
      final required = (data['total_required'] as num).toDouble();
      final paid = (data['total_paid'] as num?)?.toDouble() ?? 0.0;
      final debt = required - paid;

      final finalMessage = customTemplate
          .replaceAll('[ism]', data['name'])
          .replaceAll('[qarz]', debt.toStringAsFixed(0));

      await provider.sendDebtReminderTelegram(
        message: finalMessage,
        adminChatId: chatId,
      );
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Barcha Telegram xabarlar navbatga qo\'shildi'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Qarzdorlar (Qizil ro\'yxat)'),
        actions: [
          Consumer<StudentProvider>(
            builder: (context, provider, child) {
              if (provider.debtors.isEmpty) return const SizedBox.shrink();
              return Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.sms_outlined),
                    tooltip: 'Barchaga SMS yuborish',
                    onPressed: () => _sendBulkSMS(provider.debtors),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send_rounded),
                    tooltip: 'Barchaga Telegram yuborish',
                    onPressed: () => _sendBulkTelegram(provider.debtors),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Consumer<StudentProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.debtors.isEmpty) {
            return const Center(child: Text('Hozircha qarzdorlar yo\'q'));
          }

          return ListView.builder(
            itemCount: provider.debtors.length,
            itemBuilder: (context, index) {
              final data = provider.debtors[index];
              final required = (data['total_required'] as num).toDouble();
              final paid = (data['total_paid'] as num?)?.toDouble() ?? 0.0;
              final debt = required - paid;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.red.shade50,
                child: ListTile(
                  leading: const Icon(Icons.warning, color: Colors.red),
                  title: Text(
                    data['name'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tel: ${data['phone']}'),
                      Text(
                        '${debt.toStringAsFixed(0)} UZS',
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // SMS yuborish tugmasi
                      IconButton(
                        icon: const Icon(Icons.sms, color: Colors.blue),
                        onPressed: () async {
                          const initialMsg =
                              "Salom, [ism]ning o'quv markazidan qarzi [qarz] so'mni tashkil qilmoqda. Iltimos, to'lovni amalga oshiring.";
                          final editedMsg = await _showEditTemplateDialog(
                            'sms',
                            initialMsg,
                          );

                          if (editedMsg != null && editedMsg.isNotEmpty) {
                            final finalMsg = editedMsg
                                .replaceAll('[ism]', data['name'])
                                .replaceAll('[qarz]', debt.toStringAsFixed(0));
                            _sendSMS(
                              data['parent_phone'] ?? data['phone'],
                              finalMsg,
                            );
                          }
                        },
                      ),
                      // Telegram yuborish tugmasi
                      IconButton(
                        icon: const Icon(Icons.send, color: Colors.teal),
                        onPressed: () async {
                          final storage = context.read<SecureStorageService>();
                          final chatId = await storage.getAdminChatId();

                          const initialMsg =
                              "⚠️ <b>Qarz haqida eslatma</b>\n\nO'quvchi: <b>[ism]</b>\nQarzdorlik miqdori: <b>[qarz] UZS</b>\n\n<i>Iltimos, to'lovni o'z vaqtida amalga oshiring.</i>";
                          final editedMsg = await _showEditTemplateDialog(
                            'telegram',
                            initialMsg,
                          );

                          if (editedMsg != null &&
                              editedMsg.isNotEmpty &&
                              chatId != null) {
                            final finalMsg = editedMsg
                                .replaceAll('[ism]', data['name'])
                                .replaceAll('[qarz]', debt.toStringAsFixed(0));

                            await provider.sendDebtReminderTelegram(
                              message: finalMsg,
                              adminChatId: chatId,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Telegram xabar navbatga qo\'shildi',
                                  ),
                                ),
                              );
                            }
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Telegram sozlamalari topilmadi',
                                  ),
                                ),
                              );
                            }
                          }
                        },
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
}
