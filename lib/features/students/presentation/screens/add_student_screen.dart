import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/core/services/secure_storage_service.dart';
import 'package:school_app/features/payments/domain/enums/payment_method.dart';
import 'package:school_app/features/payments/domain/enums/payment_type.dart';
import 'package:school_app/core/providers/student_provider.dart';

class AddStudentScreen extends StatefulWidget {
  final Student? student;
  const AddStudentScreen({super.key, this.student});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _fatherNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _telegramController = TextEditingController();
  final _parentPhoneController = TextEditingController();
  final _parentTelegramController = TextEditingController();
  final _freeTimeController = TextEditingController();
  final _customPriceController = TextEditingController();

  PaymentType _paymentType = PaymentType.monthly;
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  int? _selectedGroupId;
  DateTime _joinDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.student != null) {
      // Ismni qismlarga bo'lish yoki modelni yangilangan deb hisoblash
      final names = widget.student!.name.split(' ');
      _firstNameController.text = names.isNotEmpty ? names[0] : '';
      _lastNameController.text = names.length > 1 ? names[1] : '';
      _fatherNameController.text = names.length > 2
          ? names.sublist(2).join(' ')
          : '';
      _phoneController.text = widget.student!.phone;
      _parentPhoneController.text = widget.student!.parentPhone;
      _telegramController.text = widget.student!.telegramHandle ?? '';
      _parentTelegramController.text = widget.student!.parentTelegram ?? '';
      _freeTimeController.text = widget.student!.freeTime ?? '';
      _customPriceController.text = widget.student!.customPrice != null
          ? widget.student!.customPrice!.toStringAsFixed(0)
          : '';
      _paymentType = widget.student!.paymentType;
      _paymentMethod = widget.student!.paymentMethod;
      _selectedGroupId = widget.student!.groupId;
      if (widget.student!.joinDate != null) {
        _joinDate = DateTime.parse(widget.student!.joinDate!);
      }
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _fatherNameController.dispose();
    _phoneController.dispose();
    _telegramController.dispose();
    _parentPhoneController.dispose();
    _parentTelegramController.dispose();
    _customPriceController.dispose();
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
        name:
            "${_firstNameController.text.trim()} ${_lastNameController.text.trim()} ${_fatherNameController.text.trim()}",
        phone: _phoneController.text.trim(),
        parentPhone: _parentPhoneController.text.trim(),
        telegramHandle: _telegramController.text.trim(),
        parentTelegram: _parentTelegramController.text.trim(),
        freeTime: _freeTimeController.text.trim(),
        customPrice: double.tryParse(_customPriceController.text.trim()),
        joinDate: _joinDate.toIso8601String().substring(0, 10),
        groupId: _selectedGroupId,
        paymentType: _paymentType,
        paymentMethod: _paymentMethod,
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
                controller: _firstNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ismi (Majburiy)',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ismni kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _lastNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Familiyasi (Majburiy)',
                  prefixIcon: Icon(Icons.person_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Familiyani kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _fatherNameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Otasining ismi (Majburiy)',
                  prefixIcon: Icon(Icons.group),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Otasining ismini kiriting'
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
                controller: _telegramController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Telegram manzili (Ixtiyoriy)',
                  prefixIcon: Icon(Icons.alternate_email),
                  hintText: '@username',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentPhoneController,
                textInputAction: TextInputAction.next,
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
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _parentTelegramController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Ota-ona telegrami (Ixtiyoriy)',
                  prefixIcon: Icon(Icons.contact_mail_outlined),
                  hintText: '@parent_username',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _freeTimeController,
                textInputAction: TextInputAction.next,
                onFieldSubmitted: (_) => _saveStudent(),
                decoration: const InputDecoration(
                  labelText: 'Bo\'sh vaqti (Masalan: 14:00)',
                  prefixIcon: Icon(Icons.access_time),
                  hintText: 'Avtomatik guruhlash uchun',
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _customPriceController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Individual oylik summa (Ixtiyoriy)',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  hintText: 'Bo\'sh qoldirilsa, guruh narxi ishlatiladi',
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Consumer<StudentProvider>(
                builder: (context, provider, _) {
                  return DropdownButtonFormField<int?>(
                    value: _selectedGroupId,
                    decoration: const InputDecoration(
                      labelText: 'Guruh',
                      prefixIcon: Icon(Icons.group),
                    ),
                    items: [
                      const DropdownMenuItem(
                        value: null,
                        child: Text('Guruh tanlanmagan'),
                      ),
                      ...provider.groups.map(
                        (g) => DropdownMenuItem(
                          value: g.id,
                          child: Text(
                            '${g.name} (${g.monthlyFee.toStringAsFixed(0)} so\'m)',
                          ),
                        ),
                      ),
                    ],
                    onChanged: (val) => setState(() => _selectedGroupId = val),
                  );
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentType>(
                value: _paymentType,
                decoration: const InputDecoration(
                  labelText: 'To\'lov turi',
                  prefixIcon: Icon(Icons.calendar_month),
                ),
                items:
                    PaymentType.values
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.label),
                          ),
                        )
                        .toList(),
                onChanged:
                    (val) => setState(() => _paymentType = val ?? _paymentType),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<PaymentMethod>(
                value: _paymentMethod,
                decoration: const InputDecoration(
                  labelText: 'To\'lov usuli',
                  prefixIcon: Icon(Icons.payment),
                ),
                items:
                    PaymentMethod.values
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(m.label),
                          ),
                        )
                        .toList(),
                onChanged:
                    (val) =>
                        setState(() => _paymentMethod = val ?? _paymentMethod),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.event),
                title: const Text('Qo\'shilgan sana'),
                subtitle: Text(_joinDate.toString().substring(0, 10)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _joinDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setState(() => _joinDate = picked);
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),
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
