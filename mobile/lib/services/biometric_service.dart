import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// F24: Biometryczna autentyfikacja (fingerprint/face).
/// Opt-in z poziomu Settings. Po włączeniu wymaga biometrii przy starcie aplikacji.
class BiometricService {
  static final BiometricService _instance = BiometricService._();
  factory BiometricService() => _instance;
  BiometricService._();

  static const _enabledKey = 'biometric_enabled';
  final LocalAuthentication _auth = LocalAuthentication();
  bool _enabled = false;

  bool get enabled => _enabled;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _enabled = prefs.getBool(_enabledKey) ?? false;
    } catch (_) {}
  }

  Future<bool> isDeviceSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } catch (_) {
      return false;
    }
  }

  Future<List<BiometricType>> availableBiometrics() async {
    try {
      return await _auth.getAvailableBiometrics();
    } catch (_) {
      return const [];
    }
  }

  Future<bool> setEnabled(bool value) async {
    if (value) {
      final ok = await authenticate(
        reason: 'Potwierdź tożsamość aby włączyć logowanie biometryczne',
      );
      if (!ok) return false;
    }
    _enabled = value;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, value);
    } catch (_) {}
    return true;
  }

  /// Wywołanie biometryczne. Zwraca true tylko gdy user autoryzował.
  Future<bool> authenticate({
    String reason = 'Potwierdź swoją tożsamość',
  }) async {
    try {
      final supported = await isDeviceSupported();
      if (!supported) return false;
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false, // dopuszczamy PIN/wzór fallback
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
