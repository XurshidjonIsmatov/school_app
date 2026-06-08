import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecureStorageService {
  static const _storage = FlutterSecureStorage();
  static const _pinKey = 'admin_pin';
  final LocalAuthentication _auth = LocalAuthentication();
  static const _botTokenKey = 'tg_bot_token';
  static const _adminChatIdKey = 'tg_admin_chat_id';
  static const _themeModeKey = 'theme_mode';
  static const _useBiometricKey = 'use_biometric';
  static const _isPinEnabledKey = 'is_pin_enabled';

  Future<void> setPin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  Future<void> setBotToken(String token) async {
    await _storage.write(key: _botTokenKey, value: token);
  }

  Future<String?> getBotToken() async {
    return await _storage.read(key: _botTokenKey);
  }

  Future<void> setAdminChatId(String id) async {
    await _storage.write(key: _adminChatIdKey, value: id);
  }

  Future<String?> getAdminChatId() async {
    return await _storage.read(key: _adminChatIdKey);
  }

  Future<void> setThemeMode(String mode) async {
    await _storage.write(key: _themeModeKey, value: mode);
  }

  Future<String?> getThemeMode() async {
    return await _storage.read(key: _themeModeKey);
  }

  Future<void> setUseBiometric(bool value) async {
    await _storage.write(key: _useBiometricKey, value: value.toString());
  }

  Future<bool> getUseBiometric() async {
    String? val = await _storage.read(key: _useBiometricKey);
    return val == 'true';
  }

  Future<void> setPinEnabled(bool value) async {
    await _storage.write(key: _isPinEnabledKey, value: value.toString());
  }

  Future<bool> getIsPinEnabled() async {
    String? val = await _storage.read(key: _isPinEnabledKey);
    return val != 'false'; // Odatiy holatda true
  }

  Future<bool> authenticateBiometric() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate =
          canAuthenticateWithBiometrics || await _auth.isDeviceSupported();

      if (!canAuthenticate) return false;

      return await _auth.authenticate(
        localizedReason: 'Ilovaga xavfsiz kirish uchun shaxsingizni tasdiqlang',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly:
              false, // Allows PIN/Pattern fallback if biometrics fail
        ),
      );
    } catch (e) {
      return false;
    }
  }
}
