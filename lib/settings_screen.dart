import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'secure_storage_service.dart';
import 'student_provider.dart';
import 'template_settings_screen.dart';
import 'change_pin_screen.dart';
import 'login_screen.dart';
import 'pin_setup_screen.dart';
import 'sent_messages_log_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tokenController = TextEditingController();
  final _chatIdController = TextEditingController();
  bool _isPinEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final storage = context.read<SecureStorageService>();
    final token = await storage.getBotToken();
    final chatId = await storage.getAdminChatId();
    final pinEnabled = await storage.getIsPinEnabled();

    setState(() {
      _tokenController.text = token ?? '';
      _chatIdController.text = chatId ?? '';
      _isPinEnabled = pinEnabled;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      final storage = context.read<SecureStorageService>();

      await storage.setBotToken(_tokenController.text.trim());
      await storage.setAdminChatId(_chatIdController.text.trim());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Sozlamalar saqlandi!')));
      }
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Telegram Sozlamalari')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Bot orqali xabarnomalar yuborish uchun quyidagi ma\'lumotlarni kiriting:',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextFormField(
                        controller: _tokenController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Telegram Bot Token',
                          border: OutlineInputBorder(),
                          hintText: '123456:ABC-DEF...',
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'Tokenni kiriting'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _chatIdController,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _saveSettings(),
                        decoration: const InputDecoration(
                          labelText: 'Admin Chat ID',
                          border: OutlineInputBorder(),
                          hintText: '123456789',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) => value == null || value.isEmpty
                            ? 'Chat IDni kiriting'
                            : null,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: _saveSettings,
                        icon: const Icon(Icons.save),
                        label: const Text('Saqlash'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      const Text(
                        'Xavfsizlik',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      SwitchListTile(
                        title: const Text('PIN-koddan foydalanish'),
                        subtitle: const Text('Ilovaga kirishda kod so\'rash'),
                        value: _isPinEnabled,
                        onChanged: (bool value) async {
                          final storage = context.read<SecureStorageService>();
                          await storage.setPinEnabled(value);
                          setState(() => _isPinEnabled = value);
                        },
                      ),
                      const SizedBox(height: 10),
                      Consumer<StudentProvider>(
                        builder: (context, provider, child) {
                          return SwitchListTile(
                            title: const Text('Qorong\'u rejim'),
                            secondary: Icon(
                              provider.themeMode == ThemeMode.dark
                                  ? Icons.dark_mode
                                  : Icons.light_mode,
                            ),
                            value: provider.themeMode == ThemeMode.dark,
                            onChanged: (bool value) {
                              provider.setThemeMode(
                                value ? ThemeMode.dark : ThemeMode.light,
                              );
                            },
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      const Divider(),
                      ListTile(
                        leading: const Icon(
                          Icons.message,
                          color: Colors.blueAccent,
                        ),
                        title: const Text('Xabar shablonlarini boshqarish'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TemplateSettingsScreen(),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.history_edu_rounded,
                          color: Colors.teal,
                        ),
                        title: const Text('Xabarlar tarixi (Log)'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SentMessagesLogScreen(),
                          ),
                        ),
                      ),
                      ListTile(
                        leading: const Icon(Icons.backup, color: Colors.orange),
                        title: const Text('Ma\'lumotlarni zaxiralash (Backup)'),
                        subtitle: const Text(
                          'Barcha ma\'lumotlarni JSON formatida saqlash',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final path = await context
                              .read<StudentProvider>()
                              .exportBackup();
                          if (!context.mounted) return;
                          if (path != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Zaxira nusxasi yaratildi: $path',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Zaxira nusxasini yaratishda xatolik yuz berdi',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.restore, color: Colors.green),
                        title: const Text(
                          'Ma\'lumotlarni qayta tiklash (Restore)',
                        ),
                        subtitle: const Text(
                          'Zaxira faylidan ma\'lumotlarni bazaga yuklash',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final success = await context
                              .read<StudentProvider>()
                              .restoreBackup();
                          if (!context.mounted) return;
                          if (success) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Ma\'lumotlar muvaffaqiyatli tiklandi!',
                                ),
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Tiklash bekor qilindi yoki xatolik yuz berdi',
                                ),
                              ),
                            );
                          }
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.lock_outline,
                          color: Colors.blueGrey,
                        ),
                        title: const Text('PIN-kodni o\'zgartirish'),
                        subtitle: const Text(
                          'Xavfsizlik uchun kirish kodini yangilang',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ChangePinScreen(),
                          ),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.blue),
                        title: const Text('Tizimdan chiqish'),
                        onTap: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                            (route) => false,
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(
                          Icons.delete_forever,
                          color: Colors.red,
                        ),
                        title: const Text(
                          'Ilovani tozalash (Reset)',
                          style: TextStyle(color: Colors.red),
                        ),
                        subtitle: const Text(
                          'Barcha ma\'lumotlar va PIN-kod o\'chiriladi',
                        ),
                        onTap: () => _confirmAppReset(context),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  void _confirmAppReset(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Ilovani tozalash'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Barcha ma\'lumotlar o\'chiriladi. Davom etish uchun maxsus parolni kiriting:',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Maxsus parol',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Bekor qilish'),
            ),
            TextButton(
              onPressed: () async {
                if (passwordController.text == 'RESET1559') {
                  Navigator.pop(ctx);
                  _executeReset();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Noto\'g\'ri parol!')),
                  );
                }
              },
              child: const Text(
                'Tozalash',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _executeReset() async {
    final storage = context.read<SecureStorageService>();
    final provider = context.read<StudentProvider>();

    // Ma'lumotlarni o'chirish
    await storage.setPin('');
    await storage.setBotToken('');
    await storage.setAdminChatId('');
    await storage.setPinEnabled(true);
    await storage.setUseBiometric(false);

    await provider.clearAllAppData();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const PinSetupScreen()),
      (route) => false,
    );
  }
}
