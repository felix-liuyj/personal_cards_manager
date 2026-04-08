import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class SecurityService {
  static SecurityService? _instance;
  static SecurityService get instance => _instance ??= SecurityService._();

  SecurityService._();

  final _secureStorage = const FlutterSecureStorage();
  final _localAuth = LocalAuth();

  static const String _pinKey = 'user_pin';
  static const String _pinAttemptsKey = 'pin_attempts';
  static const String _lockoutTimeKey = 'lockout_time';
  static const String _isInitializedKey = 'is_initialized';

  Future<bool> isDeviceSupported() async {
    return await _localAuth.isDeviceSupported();
  }

  Future<bool> hasBiometrics() async {
    return await _localAuth.canCheckBiometrics;
  }

  Future<List<BiometricType>> getAvailableBiometrics() async {
    return await _localAuth.getAvailableBiometrics();
  }

  Future<bool> authenticateWithBiometrics({String reason = '请验证身份'}) async {
    try {
      return await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
        ),
      );
    } catch (e) {
      return false;
    }
  }

  Future<bool> hasPin() async {
    final pin = await _secureStorage.read(key: _pinKey);
    return pin != null && pin.isNotEmpty;
  }

  Future<void> setPin(String pin) async {
    await _secureStorage.write(key: _pinKey, value: pin);
  }

  Future<bool> verifyPin(String pin) async {
    if (await isLockedOut()) {
      return false;
    }

    final storedPin = await _secureStorage.read(key: _pinKey);
    if (storedPin == null) return false;

    if (storedPin == pin) {
      await _resetAttempts();
      return true;
    } else {
      await _incrementAttempts();
      return false;
    }
  }

  Future<bool> canChangePin() async {
    return !(await isLockedOut());
  }

  Future<void> _incrementAttempts() async {
    final attemptsStr = await _secureStorage.read(key: _pinAttemptsKey);
    final attempts = (attemptsStr != null ? int.tryParse(attemptsStr) : 0) ?? 0;
    final newAttempts = attempts + 1;

    await _secureStorage.write(
      key: _pinAttemptsKey,
      value: newAttempts.toString(),
    );

    if (newAttempts >= 5) {
      await _secureStorage.write(
        key: _lockoutTimeKey,
        value: DateTime.now().toIso8601String(),
      );
    }
  }

  Future<void> _resetAttempts() async {
    await _secureStorage.delete(key: _pinAttemptsKey);
    await _secureStorage.delete(key: _lockoutTimeKey);
  }

  Future<bool> isLockedOut() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return false;

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();
    final difference = now.difference(lockoutTime);

    if (difference.inSeconds >= 300) {
      await _resetAttempts();
      return false;
    }

    return true;
  }

  Future<int> getRemainingLockoutSeconds() async {
    final lockoutTimeStr = await _secureStorage.read(key: _lockoutTimeKey);
    if (lockoutTimeStr == null) return 0;

    final lockoutTime = DateTime.parse(lockoutTimeStr);
    final now = DateTime.now();
    final difference = now.difference(lockoutTime);
    final remaining = 300 - difference.inSeconds;

    return remaining > 0 ? remaining : 0;
  }

  Future<bool> isInitialized() async {
    final value = await _secureStorage.read(key: _isInitializedKey);
    return value == 'true';
  }

  Future<void> setInitialized(bool initialized) async {
    await _secureStorage.write(
      key: _isInitializedKey,
      value: initialized.toString(),
    );
  }

  Future<void> clearAll() async {
    await _secureStorage.deleteAll();
  }
}
