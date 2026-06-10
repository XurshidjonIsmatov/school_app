import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_app/core/providers/student_provider.dart';
import 'package:school_app/features/settings/presentation/screens/settings_screen.dart';
import 'package:school_app/app/dashboard_screen.dart';
import 'package:school_app/features/groups/presentation/screens/group_list_screen.dart';
import 'package:school_app/features/students/presentation/screens/student_list_screen.dart';
import 'package:school_app/features/payments/presentation/screens/payment_screen.dart';
import 'package:school_app/features/groups/presentation/screens/add_group_screen.dart';
import 'package:school_app/features/reports/presentation/screens/reports_hub_screen.dart';
import 'package:school_app/features/students/presentation/screens/add_student_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // Placeholder screens for central navigation
  final List<Widget> _pages = [
    const DashboardScreen(),
    const GroupListScreen(),
    const StudentListScreen(),
    const PaymentScreen(), // To'lovlar bo'limi
    const ReportsHubScreen(), // Yangilangan hisobotlar markazi
  ];

  final List<String> _titles = [
    'Dashboard',
    'Groups',
    'Students',
    'Payments',
    'Reports',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  void _onFabPressed() {
    switch (_currentIndex) {
      case 1: // Groups
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddGroupScreen()),
        );
        break;
      case 2: // Students
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddStudentScreen()),
        );
        break;
      case 3: // Payments
        // To'lovlar bo'limida FAB bosilganda qidiruv maydoniga fokus berish
        // yoki o'quvchini tanlash uchun dialog ochish mumkin.
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please select a student from the list to receive payment',
            ),
          ),
        );
        break;
    }
  }

  // List<Widget>? _buildActions() {
  //   // Har bir tab uchun alohida amallar (masalan, sorting yoki filtr)
  //   if (_currentIndex == 0) {
  //     return [
  //       IconButton(
  //         icon: const Icon(Icons.settings_outlined),
  //         onPressed:
  //             () => Navigator.push(
  //               context,
  //               MaterialPageRoute(builder: (_) => const SettingsScreen()),
  //             ),
  //       ),
  //     ];
  //   }
  //   return null;
  // }

  List<Widget>? _buildActions() {
    // 1. Dashboard sahifasida faqat Sozlamalar tugmasi ko'rinadi
    if (_currentIndex == 0) {
      return [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          onPressed:
              () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
        ),
      ];
    }

    // 2. Groups (1), Students (2) va Payments (3) sahifalarida FILTR tugmasi ko'rinadi
    if (_currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3) {
      return [
        IconButton(
          icon: const Icon(Icons.filter_list), // Filtr belgisi
          tooltip: 'Filtrlash',
          onPressed: () {
            _handleFilterPressed();
          },
        ),
      ];
    }

    // 3. Reports (4) sahifasida hech qanday tugma ko'rinmaydi
    return null;
  }

  // Filtr tugmasi bosilganda ishlaydigan yangi funksiya
  // void _handleFilterPressed() {
  //   switch (_currentIndex) {
  //     case 1: // Groups filtratsiyasi
  //       print('Guruhlarni filtrlash bosildi');
  //       // Bu yerda guruhlarni holati yoki vaqtiga ko'ra filtrlaydigan dialog ochishingiz mumkin
  //       break;
  //     case 2: // Students filtratsiyasi
  //       print('O\'quvchilarni filtrlash bosildi');
  //       // Bu yerda o'quvchilarni qarzdorligi yoki guruhi bo'yicha filtrlaydigan dialog ochishingiz mumkin
  //       break;
  //     case 3: // Payments filtratsiyasi
  //       print('To\'lovlarni filtrlash bosildi');
  //       // Bu yerda to'lovlarni oyi yoki turi bo'yicha filtrlaydigan dialog ochishingiz mumkin
  //       break;
  //   }
  // }

  void _handleFilterPressed() {
    if (_currentIndex == 2) {
      // Faqat Students sahifasi uchun namuna
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (context) {
          return Consumer<StudentProvider>(
            builder: (context, provider, child) {
              return Padding(
                padding: EdgeInsets.only(
                  top: 24,
                  left: 24,
                  right: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'O\'quvchilarni filtrlash',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const Divider(),
                    const SizedBox(height: 10),

                    // 1. Guruhlar bo'yicha filtr
                    const Text(
                      'Guruh bo\'yicha',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<int>(
                      value: provider.selectedGroupId,
                      hint: const Text('Guruhni tanlang'),
                      items:
                          provider.groups.map((g) {
                            return DropdownMenuItem<int>(
                              value: g.id,
                              child: Text(g.name),
                            );
                          }).toList(),
                      onChanged: (val) => provider.setFilterGroup(val),
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // 2. To'lov holati bo'yicha filtr
                    const Text(
                      'To\'lov holati',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Barchasi'),
                          selected: provider.paymentFilter == 'all',
                          onSelected: (_) => provider.setPaymentFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('To\'laganlar'),
                          selected: provider.paymentFilter == 'paid',
                          onSelected: (_) => provider.setPaymentFilter('paid'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Qarzdorlar'),
                          selected: provider.paymentFilter == 'unpaid',
                          onSelected:
                              (_) => provider.setPaymentFilter('unpaid'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // 3. Telegram Bot holati bo'yicha filtr
                    const Text(
                      'Telegram Bot Status',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Barchasi'),
                          selected: provider.botStatusFilter == 'all',
                          onSelected: (_) => provider.setBotStatusFilter('all'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Botdan o\'tgan'),
                          selected: provider.botStatusFilter == 'registered',
                          onSelected:
                              (_) => provider.setBotStatusFilter('registered'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('O\'tmagan'),
                          selected: provider.botStatusFilter == 'unregistered',
                          onSelected:
                              (_) =>
                                  provider.setBotStatusFilter('unregistered'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Natijani ko'rsatish tugmasi
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          provider
                              .applyAllFilters(); // Filtrni bazaga/listga qo'llash
                          Navigator.pop(context);
                        },
                        child: const Text('Filtrni qo\'llash'),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
        actions: _buildActions(),
      ),
      // Navigation Drawer (Sidebar)
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
              ),
              child: const SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.school, size: 48, color: Colors.white),
                    SizedBox(height: 12),
                    Text(
                      'School App Menyu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person_outline),
              title: const Text('Profil'),
              onTap: () => print('Profile drawer item tapped'),
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('Sozlamalar'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Yordam'),
              onTap: () => print('Help drawer item tapped'),
            ),
            const Spacer(),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Versiya 1.0.0',
                style: TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
      // Main Content Area
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: _pages[_currentIndex],
      ),
      // Global Add Button
      floatingActionButton:
          (_currentIndex == 1 || _currentIndex == 2 || _currentIndex == 3)
              ? FloatingActionButton(
                onPressed: _onFabPressed,
                elevation: 4,
                tooltip:
                    _currentIndex == 1
                        ? 'Add Group'
                        : (_currentIndex == 2 ? 'Add Student' : 'Quick Pay'),
                child: const Icon(Icons.add),
              )
              : null,
      // Primary Navigation
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Theme.of(context).colorScheme.primary,
          unselectedItemColor: Colors.grey.shade600,
          showUnselectedLabels: true,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.group_outlined),
              activeIcon: Icon(Icons.group),
              label: 'Groups',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.school_outlined),
              activeIcon: Icon(Icons.school),
              label: 'Students',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.payments_outlined),
              activeIcon: Icon(Icons.payments),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              activeIcon: Icon(Icons.analytics),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}
