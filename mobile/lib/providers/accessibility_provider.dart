import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Globalna flaga „ogranicz animacje" — animowane widgety (GlowOrb, halo,
/// shimmer, puls SOS) czytają ją bez potrzeby BuildContext / Providera.
/// Aktualizowana przez AccessibilityProvider oraz z systemowego
/// MediaQuery.disableAnimations w builderze MaterialApp.
final ValueNotifier<bool> reduceMotionNotifier = ValueNotifier<bool>(false);

/// Ustawienia ułatwień dostępu (WCAG): skala tekstu, wysoki kontrast,
/// ograniczenie animacji, pogrubienie. Persystencja w SharedPreferences,
/// z opcją respektowania ustawień systemowych Androida.
class AccessibilityProvider extends ChangeNotifier {
  double _textScale = 1.0; // 1.0 / 1.15 / 1.3 / 1.5
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _boldText = false;
  bool _respectSystem = true;

  double get textScale => _textScale;
  bool get highContrast => _highContrast;
  bool get reduceMotion => _reduceMotion;
  bool get boldText => _boldText;
  bool get respectSystem => _respectSystem;

  AccessibilityProvider() {
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    _textScale = p.getDouble('a11y_text_scale') ?? 1.0;
    _highContrast = p.getBool('a11y_high_contrast') ?? false;
    _reduceMotion = p.getBool('a11y_reduce_motion') ?? false;
    _boldText = p.getBool('a11y_bold_text') ?? false;
    _respectSystem = p.getBool('a11y_respect_system') ?? true;
    reduceMotionNotifier.value = _reduceMotion;
    notifyListeners();
  }

  Future<void> _saveD(String k, double v) async =>
      (await SharedPreferences.getInstance()).setDouble(k, v);
  Future<void> _saveB(String k, bool v) async =>
      (await SharedPreferences.getInstance()).setBool(k, v);

  set textScale(double v) {
    _textScale = v;
    _saveD('a11y_text_scale', v);
    notifyListeners();
  }

  set highContrast(bool v) {
    _highContrast = v;
    _saveB('a11y_high_contrast', v);
    notifyListeners();
  }

  set reduceMotion(bool v) {
    _reduceMotion = v;
    reduceMotionNotifier.value = v;
    _saveB('a11y_reduce_motion', v);
    notifyListeners();
  }

  set boldText(bool v) {
    _boldText = v;
    _saveB('a11y_bold_text', v);
    notifyListeners();
  }

  set respectSystem(bool v) {
    _respectSystem = v;
    _saveB('a11y_respect_system', v);
    notifyListeners();
  }

  /// Skala tekstu łącząca ustawienie aplikacji z systemowym (gdy respect).
  /// Ograniczona do 2.0 by layouty nie pękały.
  double effectiveTextScale(double systemScale) {
    final s = _respectSystem ? _textScale * systemScale : _textScale;
    return s.clamp(0.85, 2.0);
  }

  bool effectiveReduceMotion(bool systemDisable) =>
      _reduceMotion || (_respectSystem && systemDisable);

  bool effectiveBold(bool systemBold) =>
      _boldText || (_respectSystem && systemBold);
}
