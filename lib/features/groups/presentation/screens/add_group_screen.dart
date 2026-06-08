import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/features/groups/data/models/group_model.dart';
import 'package:school_app/core/providers/student_provider.dart';

class AddGroupScreen extends StatefulWidget {
  final Group? group;
  const AddGroupScreen({super.key, this.group});

  @override
  State<AddGroupScreen> createState() => _AddGroupScreenState();
}

class _AddGroupScreenState extends State<AddGroupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _maxStudentsController = TextEditingController(text: '20');
  final _startTimeController = TextEditingController(text: '00:00');
  final _durationController = TextEditingController(text: '2');

  final List<String> _weekDays = [
    'Dush',
    'Sesh',
    'Chor',
    'Pay',
    'Jum',
    'Shan',
    'Yak',
  ];
  final List<String> _selectedDays = [];
  final List<int> _selectedStudentIds = [];

  @override
  void initState() {
    super.initState();
    if (widget.group != null) {
      _nameController.text = widget.group!.name;
      _priceController.text = widget.group!.price.toStringAsFixed(0);
      _maxStudentsController.text = widget.group!.maxStudents.toString();

      // Hafta kunlarini ajratib olish: "Dush-Chor" -> ["Dush", "Chor"]
      _selectedDays.addAll(widget.group!.schedule.split('-'));

      // Vaqt va davomiylikni ajratib olish: "09:00 - 11:00"
      final parts = widget.group!.time.split(' - ');
      if (parts.length == 2) {
        _startTimeController.text = parts[0];
        final startHour = int.tryParse(parts[0].split(':')[0]) ?? 0;
        final endHour = int.tryParse(parts[1].split(':')[0]) ?? 0;

        int duration = endHour - startHour;
        if (duration <= 0) duration += 24; // Kun o'zgarishini hisobga olish
        _durationController.text = duration.toString();
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _maxStudentsController.dispose();
    _startTimeController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 0, minute: 0),
    );
    if (picked != null) {
      setState(() {
        _startTimeController.text =
            '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveGroup() async {
    if (!_formKey.currentState!.validate() || _selectedDays.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Iltimos, barcha maydonlarni to\'ldiring va hafta kunlarini tanlang',
          ),
        ),
      );
      return;
    }

    final start = _startTimeController.text;
    final duration = int.tryParse(_durationController.text) ?? 2;
    final hour = int.parse(start.split(':')[0]);
    final minute = start.split(':')[1];
    final endHour = (hour + duration) % 24;
    final timeRange = '$start - ${endHour.toString().padLeft(2, '0')}:$minute';

    final groupToSave = Group(
      id: widget.group?.id,
      name: _nameController.text.trim(),
      schedule: _selectedDays.join('-'),
      time: timeRange,
      price: double.tryParse(_priceController.text) ?? 0,
      maxStudents: int.tryParse(_maxStudentsController.text) ?? 20,
    );

    if (widget.group == null) {
      await context.read<StudentProvider>().addGroup(
        groupToSave,
        studentIds: _selectedStudentIds,
      );
    } else {
      await context.read<StudentProvider>().updateGroup(groupToSave);
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final students = context.watch<StudentProvider>().students;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.group == null ? 'Yangi guruh yaratish' : 'Guruhni tahrirlash',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Guruh nomi',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v!.isEmpty ? 'Nom kiriting' : null,
            ),
            const SizedBox(height: 16),
            const Text(
              'Hafta kunlari:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Wrap(
              spacing: 8,
              children:
                  _weekDays.map((day) {
                    final isSelected = _selectedDays.contains(day);
                    return FilterChip(
                      label: Text(day),
                      selected: isSelected,
                      onSelected: (bool selected) {
                        setState(() {
                          selected
                              ? _selectedDays.add(day)
                              : _selectedDays.remove(day);
                        });
                      },
                    );
                  }).toList(),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startTimeController,
                    decoration: InputDecoration(
                      labelText: 'Boshlanish vaqti',
                      suffixIcon: IconButton(
                        onPressed: _selectTime,
                        icon: const Icon(Icons.access_time),
                      ),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _durationController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Davomiyligi (soat)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Narxi (so\'m)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _maxStudentsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Max o\'quvchi',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (widget.group == null) ...[
              const Text(
                'O\'quvchilarni biriktirish:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child:
                    students.isEmpty
                        ? const Center(child: Text('O\'quvchilar mavjud emas'))
                        : ListView.builder(
                          itemCount: students.length,
                          itemBuilder: (ctx, i) {
                            final s = students[i];
                            final isSelected = _selectedStudentIds.contains(
                              s.id,
                            );
                            final isFull =
                                _selectedStudentIds.length >=
                                (int.tryParse(_maxStudentsController.text) ??
                                    20);

                            return CheckboxListTile(
                              title: Text(s.name),
                              subtitle: Text(s.phone),
                              value: isSelected,
                              onChanged: (val) {
                                setState(() {
                                  if (val == true) {
                                    if (!isFull) {
                                      _selectedStudentIds.add(s.id!);
                                    } else {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Guruh sig\'imi to\'ldi!',
                                          ),
                                        ),
                                      );
                                    }
                                  } else {
                                    _selectedStudentIds.remove(s.id);
                                  }
                                });
                              },
                            );
                          },
                        ),
              ),
            ],
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saveGroup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                widget.group == null
                    ? 'Guruhni shakllantirish'
                    : 'O\'zgarishlarni saqlash',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
