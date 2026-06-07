import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'secure_storage_service.dart';
import 'dashboard_screen.dart';
import 'shake_widget.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _pinController = TextEditingController();
  final _shakeKey = GlobalKey<ShakeWidgetState>();
  bool _hasError = false;
  bool _isVerifying = true;

  // Master kod - PIN unutilganda kirish uchun
  static const String _masterPin = "1559";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkInitialAccess();
    });
  }

  Future<void> _checkInitialAccess() async {
    final storage = context.read<SecureStorageService>();

    // 1. PIN-kod yoqilganligini tekshirish
    bool pinEnabled = await storage.getIsPinEnabled();
    if (!pinEnabled) {
      _navigateToHome();
      return;
    }

    setState(() => _isVerifying = false);
  }

  void _navigateToHome() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const DashboardScreen()),
    );
  }

  Future<void> _checkPin() async {
    final storage = context.read<SecureStorageService>();
    final savedPin = await storage.getPin();

    if (_pinController.text == savedPin || _pinController.text == _masterPin) {
      _navigateToHome();
    } else {
      _shakeKey.currentState?.shake();
      setState(() {
        _hasError = true;
      });
      Future.delayed(
        const Duration(seconds: 1),
        () => setState(() => _hasError = false),
      );

      if (mounted) {
        _pinController.clear();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Xato PIN-kod kiritildi')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isVerifying) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 20),
            const Text(
              'School App',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Ilovaga kirish uchun PIN-kodni kiriting',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 50),
            ShakeWidget(
              key: _shakeKey,
              child: TextField(
                controller: _pinController,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: 'PIN-kod',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  focusedBorder: _hasError
                      ? const OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2),
                          borderRadius: BorderRadius.all(Radius.circular(16)),
                        )
                      : null,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                onChanged: (v) {
                  if (v.length == 4) _checkPin();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
