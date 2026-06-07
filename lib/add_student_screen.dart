import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'student_model.dart';
import 'secure_storage_service.dart';
import 'student_provider.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      _nameController.text = widget.student!.name;
      _phoneController.text = widget.student!.phone;
      _parentPhoneController.text = widget.student!.parentPhone;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _saveStudent() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final storage = context.read<SecureStorageService>();
      final studentProvider = context.read<StudentProvider>();

      // 1. Telegram sozlamalarini xavfsiz xotiradan olamiz
      final botToken = await storage.getBotToken();
      final chatId = await storage.getAdminChatId();

      // 2. O'quvchi obyektini yaratamiz
      final newStudent = Student(
        id: widget.student?.id,
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
      );

      if (widget.student == null) {
        // Yangi qo'shish
        await studentProvider.addStudent(
          newStudent,
          botToken: botToken,
          adminChatId: chatId,
        );
      } else {
        // Mavjudini tahrirlash
        await studentProvider.updateStudent(newStudent);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.student == null
                  ? 'O\'quvchi muvaffaqiyatli qo\'shildi!'
                  : 'Ma\'lumotlar yangilandi!',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Xatolik yuz berdi: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.student != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEditing ? 'Tahrirlash' : 'Yangi o\'quvchi')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'O\'quvchi ismi',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().length < 3
                    ? 'Kamida 3 ta harf kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telefon raqami',
                  prefixText: '+998 ',
                  prefixIcon: Icon(Icons.phone),
                  border: OutlineInputBorder(),
                  hintText: '901234567',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                keyboardType: TextInputType.phone,
                validator: (v) => v!.isEmpty ? 'Telefonni kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentPhoneController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveStudent(),
                decoration: const InputDecoration(
                  labelText: 'Ota-ona telefon raqami',
                  prefixText: '+998 ',
                  prefixIcon: Icon(Icons.contact_phone),
                  border: OutlineInputBorder(),
                  hintText: '901234567',
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(9),
                ],
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.isEmpty ? 'Ota-ona telefonini kiriting' : null,
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveStudent,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : Text(
                        isEditing
                            ? 'O\'zgarishlarni saqlash'
                            : 'Saqlash va Xabar yuborish',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
