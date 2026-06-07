import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'secure_storage_service.dart';
import 'dashboard_screen.dart';

class PinSetupScreen extends StatefulWidget {
  const PinSetupScreen({super.key});

  @override
  State<PinSetupScreen> createState() => _PinSetupScreenState();
}

class _PinSetupScreenState extends State<PinSetupScreen> {
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  Future<void> _savePin() async {
    if (_formKey.currentState!.validate()) {
      final storage = context.read<SecureStorageService>();
      await storage.setPin(_pinController.text);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN-kod o\'rnatish')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Ilovaga kirish uchun PIN-kod o\'rnating',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _pinController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Yangi PIN',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (v) => v!.length < 4 ? '4 ta raqam kiriting' : null,
              ),
              const SizedBox(height: 15),
              TextFormField(
                controller: _confirmPinController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'PIN-kodni tasdiqlang',
                  border: OutlineInputBorder(),
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (v) =>
                    v != _pinController.text ? 'PIN-kodlar mos kelmadi' : null,
                onChanged: (v) {
                  if (v.length == 4) _savePin();
                },
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _savePin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Saqlash', style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
