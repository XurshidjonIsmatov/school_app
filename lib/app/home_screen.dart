import 'package:flutter/material.dart';
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

  List<Widget>? _buildActions() {
    // Har bir tab uchun alohida amallar (masalan, sorting yoki filtr)
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
    return null;
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
