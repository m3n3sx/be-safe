// F04 Crash detection
//
// Monitoruje accelerometer i wykrywa potencjalne wypadki:
// 1. Spike akceleracji > 2.5g (25 m/s²) przez minimum 200ms — typowy crash
// 2. Po wykryciu uruchamia 30s countdown z głośnym alarmem + wibracjami
// 3. Jeśli użytkownik nie anuluje → automatyczny SOS (POST /alerts category=aggression)
//
// Opt-in przez SharedPreferences ('crash_detection_enabled')
// Wymaga running BackgroundService dla wykrywania gdy app w tle

import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../theme/design_tokens.dart';
import 'api_service.dart';

class CrashDetectionService {
  static const _prefKey = 'crash_detection_enabled';
  static const double _gForceThreshold = 25.0; // ~2.5g w m/s²
  static const Duration _minSpikeDuration = Duration(milliseconds: 200);
  static const Duration _cooldownAfterDetection = Duration(seconds: 60);
  static const Duration _gracePeriod = Duration(seconds: 30);

  static final CrashDetectionService _instance = CrashDetectionService._();
  factory CrashDetectionService() => _instance;
  CrashDetectionService._();

  StreamSubscription<UserAccelerometerEvent>? _sub;
  DateTime? _spikeStart;
  DateTime? _lastDetection;
  bool _enabled = false;
  bool _dialogOpen = false;

  /// Globalny navigatorKey do pokazania dialogu z dowolnego miejsca
  static GlobalKey<NavigatorState>? navigatorKey;

  /// Inicjalizacja - wczytuje opt-in z SharedPreferences i startuje jeśli enabled
  Future<void> init({required ApiService api}) async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_prefKey) ?? false;
    if (_enabled) await _start(api);
  }

  bool get isEnabled => _enabled;

  Future<void> setEnabled(bool value, {required ApiService api}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey, value);
    _enabled = value;
    if (value) {
      await _start(api);
    } else {
      await _stop();
    }
  }

  Future<void> _start(ApiService api) async {
    await _stop();
    _sub = userAccelerometerEventStream(
      samplingPeriod: const Duration(milliseconds: 50),
    ).listen((event) => _handle(event, api));
  }

  Future<void> _stop() async {
    await _sub?.cancel();
    _sub = null;
    _spikeStart = null;
  }

  void _handle(UserAccelerometerEvent e, ApiService api) {
    if (_dialogOpen) return;
    if (_lastDetection != null &&
        DateTime.now().difference(_lastDetection!) < _cooldownAfterDetection) {
      return;
    }

    final magnitude = math.sqrt(e.x * e.x + e.y * e.y + e.z * e.z);

    if (magnitude > _gForceThreshold) {
      _spikeStart ??= DateTime.now();
      if (DateTime.now().difference(_spikeStart!) >= _minSpikeDuration) {
        _lastDetection = DateTime.now();
        _spikeStart = null;
        _triggerCrashDialog(api, magnitude);
      }
    } else {
      _spikeStart = null;
    }
  }

  void _triggerCrashDialog(ApiService api, double magnitude) {
    final ctx = navigatorKey?.currentContext;
    if (ctx == null) return;
    _dialogOpen = true;
    HapticFeedback.heavyImpact();

    showDialog<void>(
      context: ctx,
      barrierDismissible: false,
      builder: (dialogCtx) => _CrashDetectedDialog(
        magnitude: magnitude,
        onCancel: () {
          Navigator.of(dialogCtx).pop();
          _dialogOpen = false;
        },
        onConfirm: () async {
          Navigator.of(dialogCtx).pop();
          _dialogOpen = false;
          await _fireAutoSos(api);
        },
      ),
    );
  }

  Future<void> _fireAutoSos(ApiService api) async {
    HapticFeedback.heavyImpact();
    try {
      double lat = 52.2297;
      double lng = 21.0122;
      try {
        final pos = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        ).timeout(const Duration(seconds: 5));
        lat = pos.latitude;
        lng = pos.longitude;
      } catch (_) {}

      await api.post('/alerts', {
        'category': 'aggression',
        'title': '🚨 SOS — Wykryto wypadek (automatyczne)',
        'description': 'Crash detection wykryło nagłe zatrzymanie. '
            'Sprawdź czy potrzebna pomoc.',
        'lat': lat,
        'lng': lng,
        'radius_m': 500,
      });

      final ctx = navigatorKey?.currentContext;
      if (ctx != null && ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(
            backgroundColor: SerenityColors.glowAlertCoral,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
            ),
            content: const Text(
              '🚨 Wysłano automatyczne SOS — Rodzina i sąsiedzi powiadomieni',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[crash] auto SOS failed: $e');
    }
  }
}

class _CrashDetectedDialog extends StatefulWidget {
  const _CrashDetectedDialog({
    required this.magnitude,
    required this.onCancel,
    required this.onConfirm,
  });

  final double magnitude;
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  @override
  State<_CrashDetectedDialog> createState() => _CrashDetectedDialogState();
}

class _CrashDetectedDialogState extends State<_CrashDetectedDialog>
    with SingleTickerProviderStateMixin {
  late int _remaining;
  Timer? _timer;
  Timer? _hapticTimer;
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _remaining = CrashDetectionService._gracePeriod.inSeconds;
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _hapticTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      HapticFeedback.heavyImpact();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _remaining--);
      if (_remaining <= 0) {
        t.cancel();
        _hapticTimer?.cancel();
        widget.onConfirm();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _hapticTimer?.cancel();
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: SerenityColors.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
        ),
        contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ScaleTransition(
              scale: Tween<double>(begin: 0.95, end: 1.05).animate(_pulse),
              child: Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: SerenityColors.glowAlertCoral,
                  boxShadow: [
                    BoxShadow(
                      color: SerenityColors.glowAlertCoral.withValues(alpha: 0.4),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Wykryto wypadek',
              style: SerenityText.headlineHeroMobile.copyWith(
                color: SerenityColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Czy wszystko w porządku?\nSOS zostanie wysłane za:',
              style: SerenityText.bodyMain.copyWith(
                color: SerenityColors.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            Text(
              '$_remaining s',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 56,
                fontWeight: FontWeight.w800,
                color: SerenityColors.glowAlertCoral,
                letterSpacing: -2,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onCancel,
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: SerenityColors.primaryContainer,
                        width: 2,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SerenityShapes.radiusLg),
                      ),
                    ),
                    child: Text(
                      'Anuluj',
                      style: SerenityText.labelButton.copyWith(
                        color: SerenityColors.primaryContainer,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: widget.onConfirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: SerenityColors.glowAlertCoral,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(SerenityShapes.radiusLg),
                      ),
                    ),
                    child: Text(
                      'Wyślij SOS',
                      style: SerenityText.labelButton.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
