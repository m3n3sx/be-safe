// F07 Panic gesture (shake-to-SOS)
//
// Monitoruje accelerometer i wykrywa intencjonalny gest paniczny:
// - 3 wyraźne potrząśnięcia (peak > 18 m/s² ≈ 1.8g) w ciągu 1.5s
// - Próg niższy niż F04 (crash 25 m/s²) bo to intencjonalny gest
// - Cooldown 30s pomiędzy detekcjami
// - Po detekcji: HapticFeedback.heavyImpact ×2 + nawigacja do SosScreen
//   (NIE auto-fire jak crash — user musi świadomie potwierdzić w SOS)
//
// Opt-in przez SharedPreferences ('shake_to_sos_enabled')

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../screens/sos/sos_screen.dart';

class ShakeDetectionService {
  static const _prefKey = 'shake_to_sos_enabled';
  static const double _shakeThreshold = 18.0; // m/s², niższy niż crash 25
  static const int _shakesRequired = 3;
  static const Duration _shakeWindow = Duration(milliseconds: 1500);
  static const Duration _minBetweenShakes = Duration(milliseconds: 150);
  static const Duration _cooldown = Duration(seconds: 30);

  static final ShakeDetectionService _instance = ShakeDetectionService._();
  factory ShakeDetectionService() => _instance;
  ShakeDetectionService._();

  StreamSubscription<UserAccelerometerEvent>? _sub;
  final List<DateTime> _peaks = [];
  DateTime? _lastDetection;
  DateTime? _lastPeak;
  bool _enabled = false;

  /// Globalny navigatorKey (przypisany w main.dart)
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Inicjalizacja - wczytuje opt-in z SharedPreferences
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    if (_enabled) await _start();
  }

  bool get isEnabled => _enabled;

  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _enabled = value;
    if (value) {
      await _start();
    } else {
      await _stop();
    }
  }

  Future<void> _start() async {
    await _stop();
    _sub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen(_handle);
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _peaks.clear();
  }

  void _handle(UserAccelerometerEvent e) {
    // Cooldown po ostatniej detekcji
    if (_lastDetection != null &&
        DateTime.now().difference(_lastDetection!) < _cooldown) {
      return;
    }

    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);
    if (magnitude < _shakeThreshold) return;

    final now = DateTime.now();
    // Debouncing - min 150ms między peakami
    if (_lastPeak != null && now.difference(_lastPeak!) < _minBetweenShakes) {
      return;
    }
    _lastPeak = now;

    // Usuń stare peaki (poza oknem 1.5s)
    _peaks.removeWhere((t) => now.difference(t) > _shakeWindow);
    _peaks.add(now);

    if (_peaks.length >= _shakesRequired) {
      _lastDetection = now;
      _peaks.clear();
      _triggerSosNavigation();
    }
  }

  void _triggerSosNavigation() {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;

    // Double haptic dla feedbacku
    HapticFeedback.heavyImpact();
    Future.delayed(const Duration(milliseconds: 120), () {
      HapticFeedback.heavyImpact();
    });

    // Nawigacja do SosScreen
    Navigator.of(ctx).push(
      MaterialPageRoute<void>(builder: (_) => const SosScreen()),
    );
  }
}
