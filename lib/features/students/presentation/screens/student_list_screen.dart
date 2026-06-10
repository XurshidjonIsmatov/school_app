// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
// import 'package:school_app/core/providers/student_provider.dart';
// import 'package:school_app/features/students/data/models/student_model.dart';
// import 'package:school_app/features/students/presentation/screens/add_student_screen.dart';
// import 'package:school_app/features/students/presentation/widgets/assign_group_dialog.dart';
// import 'package:school_app/features/payments/presentation/screens/payment_history_screen.dart';
// import 'package:school_app/features/students/presentation/screens/student_attendance_history_screen.dart';
// import 'package:school_app/core/widgets/pending_messages_stats_widget.dart';
// import 'package:school_app/core/widgets/neumorphic_card.dart';

// class StudentListScreen extends StatelessWidget {
//   const StudentListScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Column(
//         children: [
//           // Navbatdagi xabarlar vidjeti
//           const PendingMessagesStatsWidget(),
//           // Qidiruv maydoni
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 hintText: 'Ism yoki telefon orqali qidirish...',
//                 prefixIcon: const Icon(Icons.search),
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(10),
//                 ),
//               ),
//               onChanged:
//                   (val) => context.read<StudentProvider>().setSearchQuery(val),
//             ),
//           ),

//           // Guruhlar filtri (Horizontal List)
//           Consumer<StudentProvider>(
//             builder: (context, provider, child) {
//               return SizedBox(
//                 height: 50,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: provider.groups.length + 1,
//                   itemBuilder: (context, index) {
//                     if (index == 0) {
//                       return Padding(
//                         padding: const EdgeInsets.symmetric(horizontal: 4),
//                         child: ChoiceChip(
//                           label: const Text('Barchasi'),
//                           selected: provider.selectedGroupId == null,
//                           onSelected: (_) => provider.setFilterGroup(null),
//                         ),
//                       );
//                     }
//                     final group = provider.groups[index - 1];
//                     return Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 4),
//                       child: ChoiceChip(
//                         label: Text(group.name),
//                         selected: provider.selectedGroupId == group.id,
//                         onSelected: (_) => provider.setFilterGroup(group.id),
//                       ),
//                     );
//                   },
//                 ),
//               );
//             },
//           ),

//           // O'quvchilar ro'yxati
//           Expanded(
//             child: Consumer<StudentProvider>(
//               builder: (context, provider, child) {
//                 if (provider.isLoading) {
//                   return const Center(child: CircularProgressIndicator());
//                 }
//                 if (provider.students.isEmpty) {
//                   return const Center(child: Text('O\'quvchilar topilmadi'));
//                 }
//                 return AnimationLimiter(
//                   child: ListView.builder(
//                     itemCount: provider.students.length,
//                     itemBuilder: (context, index) {
//                       final student = provider.students[index];
//                       return AnimationConfiguration.staggeredList(
//                         position: index,
//                         duration: const Duration(milliseconds: 375),
//                         child: SlideAnimation(
//                           verticalOffset: 50.0,
//                           child: FadeInAnimation(
//                             child: Dismissible(
//                               key: Key('student_${student.id}'),
//                               direction: DismissDirection.horizontal,
//                               confirmDismiss: (direction) async {
//                                 if (direction == DismissDirection.startToEnd) {
//                                   Navigator.push(
//                                     context,
//                                     MaterialPageRoute(
//                                       builder:
//                                           (_) => AddStudentScreen(
//                                             student: student,
//                                           ),
//                                     ),
//                                   );
//                                   return false;
//                                 } else {
//                                   return await _confirmDeleteStudent(
//                                     context,
//                                     student,
//                                   );
//                                 }
//                               },
//                               onDismissed: (direction) {
//                                 if (direction == DismissDirection.endToStart) {
//                                   provider.deleteStudent(student.id!);
//                                 }
//                               },
//                               background: Container(
//                                 alignment: Alignment.centerLeft,
//                                 padding: const EdgeInsets.only(left: 20.0),
//                                 color: Colors.blue.withValues(alpha: 0.2),
//                                 child: const Icon(
//                                   Icons.edit_outlined,
//                                   color: Colors.blue,
//                                 ),
//                               ),
//                               secondaryBackground: Container(
//                                 alignment: Alignment.centerRight,
//                                 padding: const EdgeInsets.only(right: 20.0),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red,
//                                   borderRadius: BorderRadius.circular(12),
//                                 ),
//                                 child: const Icon(
//                                   Icons.delete_outline,
//                                   color: Colors.white,
//                                 ),
//                               ),
//                               child: NeumorphicCard(
//                                 margin: const EdgeInsets.symmetric(
//                                   vertical: 6,
//                                   horizontal: 16,
//                                 ),
//                                 child: ListTile(
//                                   leading: CircleAvatar(
//                                     child: Text(student.name[0]),
//                                   ),
//                                   title: Text(student.name),
//                                   subtitle: Text(student.phone),
//                                   trailing: Row(
//                                     mainAxisSize: MainAxisSize.min,
//                                     children: [
//                                       IconButton(
//                                         icon: const Icon(
//                                           Icons.edit,
//                                           color: Colors.blue,
//                                         ),
//                                         onPressed:
//                                             () => Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (_) => AddStudentScreen(
//                                                       student: student,
//                                                     ),
//                                               ),
//                                             ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(
//                                           Icons.calendar_month,
//                                           color: Colors.teal,
//                                         ),
//                                         onPressed:
//                                             () => Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (_) =>
//                                                         StudentAttendanceHistoryScreen(
//                                                           student: student,
//                                                         ),
//                                               ),
//                                             ),
//                                       ),
//                                       IconButton(
//                                         icon: const Icon(
//                                           Icons.history,
//                                           color: Colors.orange,
//                                         ),
//                                         onPressed:
//                                             () => Navigator.push(
//                                               context,
//                                               MaterialPageRoute(
//                                                 builder:
//                                                     (_) => PaymentHistoryScreen(
//                                                       student: student,
//                                                     ),
//                                               ),
//                                             ),
//                                       ),
//                                       provider.selectedGroupId != null
//                                           ? IconButton(
//                                             icon: const Icon(
//                                               Icons.group_remove,
//                                               color: Colors.red,
//                                             ),
//                                             onPressed: () {
//                                               _showRemoveDialog(
//                                                 context,
//                                                 provider,
//                                                 student,
//                                               );
//                                             },
//                                           )
//                                           : const Icon(Icons.chevron_right),
//                                     ],
//                                   ),
//                                   onLongPress: () {
//                                     _confirmDeleteStudent(context, student);
//                                   },
//                                   onTap: () {
//                                     showDialog(
//                                       context: context,
//                                       builder:
//                                           (context) => AssignGroupDialog(
//                                             student: student,
//                                           ),
//                                     );
//                                   },
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       );
//                     },
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   void _showRemoveDialog(
//     BuildContext context,
//     StudentProvider provider,
//     Student student,
//   ) {
//     showDialog(
//       context: context,
//       builder:
//           (ctx) => AlertDialog(
//             icon: const Icon(Icons.group_remove_outlined),
//             title: const Text('Guruhdan o\'chirish'),
//             content: Text(
//               '${student.name}ni ushbu guruhdan o\'chirmoqchimisiz?',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx),
//                 child: const Text('Bekor qilish'),
//               ),
//               FilledButton.tonal(
//                 onPressed: () {
//                   provider.removeStudentFromGroup(
//                     student.id!,
//                     provider.selectedGroupId!,
//                   );
//                   Navigator.pop(ctx);
//                 },
//                 child: const Text(
//                   'O\'chirish',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }

//   Future<bool?> _confirmDeleteStudent(
//     BuildContext context,
//     Student student,
//   ) async {
//     return await showDialog<bool>(
//       context: context,
//       builder:
//           (ctx) => AlertDialog(
//             icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
//             title: const Text('O\'quvchini o\'chirish'),
//             content: Text(
//               '${student.name}ni butunlay bazadan o\'chirmoqchimisiz? '
//               'Bunda unga bog\'liq barcha to\'lov va davomat ma\'lumotlari ham o\'chib ketadi.',
//             ),
//             actions: [
//               TextButton(
//                 onPressed: () => Navigator.pop(ctx, false),
//                 child: const Text('Ortga'),
//               ),
//               FilledButton.tonal(
//                 onPressed: () => Navigator.pop(ctx, true),
//                 child: const Text(
//                   'O\'chirish',
//                   style: TextStyle(color: Colors.red),
//                 ),
//               ),
//             ],
//           ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/students/data/models/student_model.dart';
import 'package:school_app/features/students/presentation/screens/add_student_screen.dart';
import 'package:school_app/features/students/presentation/widgets/assign_group_dialog.dart';
import 'package:school_app/features/payments/presentation/screens/payment_history_screen.dart';
import 'package:school_app/features/students/presentation/screens/student_attendance_history_screen.dart';
import 'package:school_app/features/students/presentation/screens/student_card_screen.dart';
import 'package:school_app/core/widgets/pending_messages_stats_widget.dart';
import 'package:school_app/core/widgets/neumorphic_card.dart';

class StudentListScreen extends StatelessWidget {
  const StudentListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Scaffold olib tashlandi -> Toza SafeArea va Column qoldi
    return SafeArea(
      child: Column(
        children: [
          // Navbatdagi xabarlar vidjeti
          const PendingMessagesStatsWidget(),

          // Qidiruv va Sortlash qatori
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                // Qidiruv maydoni
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ism yoki telefon orqali qidirish...',
                      prefixIcon: const Icon(Icons.search),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    onChanged:
                        (val) =>
                            context.read<StudentProvider>().setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 10),
                // O'ng tarafdagi SORTLASH tugmasi
                Container(
                  decoration: BoxDecoration(
                    color:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.sort_rounded),
                    tooltip: 'Sortlash',
                    onPressed: () => _showSortMenu(context),
                  ),
                ),
              ],
            ),
          ),

          // Aktiv filtrlar indikatori (Agar biror narsa filtr qilingan bo'lsa foydalanuvchiga ko'rinib turadi)
          _buildActiveFiltersIndicator(context),

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
                    padding: const EdgeInsets.only(
                      bottom: 80,
                    ), // FAB tugmasi kodni yopib qo'ymasligi uchun
                    itemBuilder: (context, index) {
                      final student = provider.students[index];
                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 30.0,
                          child: FadeInAnimation(
                            child: Dismissible(
                              key: Key('student_${student.id}'),
                              direction: DismissDirection.horizontal,
                              confirmDismiss: (direction) async {
                                if (direction == DismissDirection.startToEnd) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (_) => AddStudentScreen(
                                            student: student,
                                          ),
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
                                color: Colors.blue.withOpacity(0.2),
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
                                    backgroundColor:
                                        Theme.of(
                                          context,
                                        ).colorScheme.primaryContainer,
                                    child: Text(student.name[0].toUpperCase()),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          student.name,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Telegram Bot holati status nishoni (Badge)
                                      _buildBotStatusBadge(student),
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(student.phone),
                                      const SizedBox(height: 2),
                                      // To'lov statusi matni
                                      _buildPaymentStatusSubtitle(
                                        student,
                                        provider,
                                      ),
                                    ],
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.calendar_month,
                                          color: Colors.teal,
                                        ),
                                        onPressed:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) =>
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
                                        onPressed:
                                            () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (_) => PaymentHistoryScreen(
                                                      student: student,
                                                    ),
                                              ),
                                            ),
                                      ),
                                    ],
                                  ),
                                  onLongPress:
                                      () => _confirmDeleteStudent(
                                        context,
                                        student,
                                      ),
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => StudentCardScreen(
                                              student: student,
                                            ),
                                      ),
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
    );
  }

  // Telegram botdan ro'yxatdan o'tganlik status nishoni
  Widget _buildBotStatusBadge(Student student) {
    // Modelda botStatus yoki telegramId borligiga qarab tekshiramiz (Masalan: student.isBotRegistered)
    bool isBotRegistered =
        student.telegramHandle != null &&
        student.telegramHandle!.isNotEmpty;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color:
            isBotRegistered
                ? Colors.blue.withOpacity(0.1)
                : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(
            isBotRegistered ? Icons.smart_toy : Icons.link_off,
            size: 12,
            color: isBotRegistered ? Colors.blue : Colors.grey,
          ),
          const SizedBox(width: 2),
          Text(
            isBotRegistered ? 'Bot' : 'No Bot',
            style: TextStyle(
              fontSize: 10,
              color: isBotRegistered ? Colors.blue : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // To'lov holatiga ko'ra subtitly yaratish
  Widget _buildPaymentStatusSubtitle(
    Student student,
    StudentProvider provider,
  ) {
    final finance = provider.paymentStudents.firstWhere(
      (p) => p['id'] == student.id,
      orElse: () => {'charge_status': 'unpaid', 'current_due': 0},
    );
    final status = finance['charge_status']?.toString() ?? 'unpaid';
    final due = (finance['current_due'] as num?)?.toDouble() ?? 0;
    final isPaid = status == 'paid' || due <= 0;
    return Text(
      isPaid ? 'To\'langan' : 'Qarzdorlik bor',
      style: TextStyle(
        fontSize: 12,
        color: isPaid ? Colors.green : Colors.red,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  // Sortlash menyusi (Ism va Sana bo'yicha)
  void _showSortMenu(BuildContext context) {
    final provider = context.read<StudentProvider>();
    showMenu(
      context: context,
      position: const RelativeRect.fromLTRB(100, 150, 16, 0),
      items: [
        PopupMenuItem(
          value: 'name_asc',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color:
                    provider.currentSort == 'name_asc'
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 10),
              const Text('Ism (A-Z)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'name_desc',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color:
                    provider.currentSort == 'name_desc'
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 10),
              const Text('Ism (Z-A)'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date_desc',
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color:
                    provider.currentSort == 'date_desc'
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 10),
              const Text('Yangi qo\'shilganlar'),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'date_asc',
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color:
                    provider.currentSort == 'date_asc'
                        ? Colors.blue
                        : Colors.grey,
              ),
              const SizedBox(width: 10),
              const Text('Eski qo\'shilganlar'),
            ],
          ),
        ),
      ],
    ).then((value) {
      if (value != null) {
        provider.setSortOption(
          value,
        ); // Provider ichida tartiblash funksiyasini chaqiradi
      }
    });
  }

  // Aktiv filtrlarni ko'rsatib turuvchi panelcha
  Widget _buildActiveFiltersIndicator(BuildContext context) {
    return Consumer<StudentProvider>(
      builder: (context, provider, child) {
        if (!provider.isFilterActive) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4),
          child: Row(
            children: [
              Text(
                'Filtrlar aktiv',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => provider.clearAllFilters(),
                child: const Text(
                  'Tozalash',
                  style: TextStyle(fontSize: 12, color: Colors.red),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // _confirmDeleteStudent va _showRemoveDialog eski holatda qoladi...
  Future<bool?> _confirmDeleteStudent(
    BuildContext context,
    Student student,
  ) async {
    return await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            icon: const Icon(Icons.person_remove_outlined, color: Colors.red),
            title: const Text('O\'quvchini o\'chirish'),
            content: Text(
              '${student.name}ni butunlay bazadan o\'chirmoqchimisiz?',
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
