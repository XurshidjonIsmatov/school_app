import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'secure_storage_service.dart';

class ChangePinScreen extends StatefulWidget {
  const ChangePinScreen({super.key});

  @override
  State<ChangePinScreen> createState() => _ChangePinScreenState();
}

class _ChangePinScreenState extends State<ChangePinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPinController = TextEditingController();
  final _newPinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  // Foydalanuvchi kodni unutganda ishlatiladigan yashirin kod
  static const String _masterPin = "1559";

  Future<void> _updatePin() async {
    if (_formKey.currentState!.validate()) {
      final storage = context.read<SecureStorageService>();
      final savedPin = await storage.getPin();

      // Eski PIN-kodni yoki master-kodni tekshirish
      if (_oldPinController.text != savedPin &&
          _oldPinController.text != _masterPin) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Eski PIN-kod noto\'g\'ri!')),
          );
        }
        return;
      }

      // Biometrik autentifikatsiyani tekshirish
      bool authenticated = await storage.authenticateBiometric();
      if (!authenticated) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Biometrik tasdiqlash bajarilmadi!')),
          );
        }
        return;
      }

      // Yangi kodni saqlash
      await storage.setPin(_newPinController.text);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PIN-kod muvaffaqiyatli yangilandi!')),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  void dispose() {
    _oldPinController.dispose();
    _newPinController.dispose();
    _confirmPinController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PIN-kodni o\'zgartirish')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _oldPinController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Eski PIN-kod',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (v) => v!.length < 4 ? '4 ta raqam kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _newPinController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Yangi PIN-kod',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (v) => v!.length < 4 ? '4 ta raqam kiriting' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _confirmPinController,
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Yangi PIN-kodni tasdiqlang',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 4,
                validator: (v) => v != _newPinController.text
                    ? 'PIN-kodlar mos kelmadi'
                    : null,
                onChanged: (v) {
                  if (v.length == 4) _updatePin();
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _updatePin,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
                child: const Text('PIN-kodni yangilash'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
