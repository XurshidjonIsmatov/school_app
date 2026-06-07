import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'group_model.dart';
import 'student_provider.dart';

class AddGroupScreen extends StatefulWidget {
  final Group? group;
  const AddGroupScreen({super.key, this.group});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _scheduleController = TextEditingController();
  final _timeController = TextEditingController();
  final _priceController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _scheduleController.text = widget.group!.schedule;
      _timeController.text = widget.group!.time;
      _priceController.text = widget.group!.price.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _scheduleController.dispose();
    _timeController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    final newGroup = Group(
      id: widget.group?.id,
      name: _nameController.text.trim(),
      schedule: _scheduleController.text.trim(),
      time: _timeController.text.trim(),
      price: double.tryParse(_priceController.text.trim()) ?? 0,
    );

    if (widget.group == null) {
      await context.read<StudentProvider>().addGroup(newGroup);
    } else {
      await context.read<StudentProvider>().updateGroup(newGroup);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.group == null ? 'Guruh yaratildi!' : 'Guruh tahrirlandi!',
          ),
        ),
      );
      Navigator.pop(context);
    }
    setState(() => _isSaving = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group == null ? 'Yangi guruh' : 'Guruhni tahrirlash',
        ),
      ),
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
                  labelText: 'Guruh nomi',
                  prefixIcon: Icon(Icons.group_work),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Guruh nomini kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _scheduleController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Kunlar (masalan: Dush-Chor-Jum)',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Dars kunlarini kiriting'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _timeController,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _saveGroup(),
                decoration: const InputDecoration(
                  labelText: 'Vaqt (masalan: 14:00)',
                  prefixIcon: Icon(Icons.access_time),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vaqtni kiriting';
                  final timeRegex = RegExp(r'^([01]?[0-9]|2[0-3]):[0-5][0-9]$');
                  if (!timeRegex.hasMatch(v)) {
                    return 'Format noto\'g\'ri (HH:mm)';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                textInputAction: TextInputAction.done,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Oylik to\'lov (so\'m)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Narxni kiriting';
                  }
                  if (double.tryParse(v.trim()) == null) {
                    return 'To\'g\'ri summa kiriting';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveGroup,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator()
                    : const Text(
                        'Guruhni saqlash',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
