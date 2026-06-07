import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'student_provider.dart';
import 'student_model.dart';
import 'add_student_screen.dart';
import 'assign_group_dialog.dart';
import 'payment_history_screen.dart';
import 'student_attendance_history_screen.dart';
import 'pending_messages_stats_widget.dart';
import 'neumorphic_card.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('O\'quvchilar'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (val) =>
                context.read<StudentProvider>().setSortOption(val),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'name', child: Text('Ismi bo\'yicha')),
              const PopupMenuItem(
                value: 'time',
                child: Text('Vaqti bo\'yicha'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Navbatdagi xabarlar vidjeti
          const PendingMessagesStatsWidget(),
          // Qidiruv maydoni
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Ism yoki telefon orqali qidirish...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (val) =>
                  context.read<StudentProvider>().setSearchQuery(val),
            ),
          ),

          // Guruhlar filtri (Horizontal List)
          Consumer<StudentProvider>(
            builder: (context, provider, child) {
              return SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: provider.groups.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: ChoiceChip(
                          label: const Text('Barchasi'),
                          selected: provider.selectedGroupId == null,
                          onSelected: (_) => provider.setFilterGroup(null),
                        ),
                      );
                    }
                    final group = provider.groups[index - 1];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(group.name),
                        selected: provider.selectedGroupId == group.id,
                        onSelected: (_) => provider.setFilterGroup(group.id),
                      ),
                    );
                  },
                ),
              );
            },
          ),

          // O'quvchilar ro'yxati
          Expanded(
            child: Consumer<StudentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.students.isEmpty) {
                  return const Center(child: Text('O\'quvchilar topilmadi'));
                }
                return AnimationLimiter(
                  child: ListView.builder(
                    itemCount: provider.students.length,
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: Dismissible(
                              key: Key('student_${student.id}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          AddStudentScreen(student: student),
                                    ),
                                  );
                                  return false;
                                } else {
                                  return await _confirmDeleteStudent(
                                    context,
                                    student,
                                  );
                                }
                              },
                              onDismissed: (direction) {
                                if (direction == DismissDirection.endToStart) {
                                  provider.deleteStudent(student.id!);
                                }
                              },
                              background: Container(
                                alignment: Alignment.centerLeft,
                                padding: const EdgeInsets.only(left: 20.0),
                                color: Colors.blue.withValues(alpha: 0.2),
                                child: const Icon(
                                  Icons.edit_outlined,
                                  color: Colors.blue,
                                ),
                              ),
                              secondaryBackground: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.only(right: 20.0),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.white,
                                ),
                              ),
                              child: NeumorphicCard(
                                margin: const EdgeInsets.symmetric(
                                  vertical: 6,
                                  horizontal: 16,
                                ),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    child: Text(student.name[0]),
                                  ),
                                  title: Text(student.name),
                                  subtitle: Text(student.phone),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.edit,
                                          color: Colors.blue,
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) => AddStudentScreen(
                                              student: student,
                                            ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.calendar_month,
                                          color: Colors.teal,
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StudentAttendanceHistoryScreen(
                                                  student: student,
                                                ),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.history,
                                          color: Colors.orange,
                                        ),
                                        onPressed: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                PaymentHistoryScreen(
                                                  student: student,
                                                ),
                                          ),
                                        ),
                                      ),
                                      provider.selectedGroupId != null
                                          ? IconButton(
                                              icon: const Icon(
                                                Icons.group_remove,
                                                color: Colors.red,
                                              ),
                                              onPressed: () {
                                                _showRemoveDialog(
                                                  context,
                                                  provider,
                                                  student,
                                                );
                                              },
                                            )
                                          : const Icon(Icons.chevron_right),
                                    ],
                                  ),
                                  onLongPress: () {
                                    _confirmDeleteStudent(context, student);
                                  },
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) =>
                                          AssignGroupDialog(student: student),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStudentScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showRemoveDialog(
    BuildContext context,
    StudentProvider provider,
    Student student,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.group_remove_outlined),
        title: const Text('Guruhdan o\'chirish'),
        content: Text('${student.name}ni ushbu guruhdan o\'chirmoqchimisiz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Bekor qilish'),
          ),
          FilledButton.tonal(
            onPressed: () {
              provider.removeStudentFromGroup(
                student.id!,
                provider.selectedGroupId!,
              );
              Navigator.pop(ctx);
            },
            child: const Text(
              'O\'chirish',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool?> _confirmDeleteStudent(
    BuildContext context,
    Student student,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
        title: const Text('O\'quvchini o\'chirish'),
        content: Text(
          '${student.name}ni butunlay bazadan o\'chirmoqchimisiz? '
          'Bunda unga bog\'liq barcha to\'lov va davomat ma\'lumotlari ham o\'chib ketadi.',
        ),
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
