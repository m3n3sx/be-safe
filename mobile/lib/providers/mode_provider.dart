import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'auth_provider.dart';

/// ModeProvider — źródło prawdy o aktywnym trybie aplikacji (KIDS/SENIOR/NORMAL).
///
/// Działa w 2 fazach:
/// 1) PRZED loginem (po onboardingu) — wybór trybu trafia tylko do
///    SharedPreferences pod kluczem [_prefsKey]. AuthGate korzysta z tej
///    wartości żeby zdecydować jakie ekrany pokazać po rejestracji.
/// 2) PO loginie — [syncFromUser] kopiuje wartość z [User.appMode] (czyli
///    wartości z backendu). Zmiany wykonujemy przez [setMode] który pisze
///    do backendu przez [AuthProvider.updateAppMode] oraz lokalnie do prefs.
class ModeProvider extends ChangeNotifier {
  static const String _prefsKey = 'app_mode';

  AppMode _mode = AppMode.normal;
  bool _initialized = false;

  AppMode get mode => _mode;
  bool get initialized => _initialized;

  bool get isKids => _mode == AppMode.kids;
  bool get isSenior => _mode == AppMode.senior;
  bool get isNormal => _mode == AppMode.normal;

  /// Wczytuje tryb z SharedPreferences. Wywołać raz przy starcie aplikacji
  /// (zanim AuthGate zdecyduje co pokazać).
  Future<void> init() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      _mode = AppModeX.fromString(raw);
    } catch (_) {
      _mode = AppMode.normal;
    }
    _initialized = true;
    notifyListeners();
  }

  /// Po zalogowaniu — bierze wartość z backendu i synchronizuje do prefs.
  /// Wywoływane z AuthGate po `auth.tryAutoLogin()` lub po login/register.
  Future<void> syncFromUser(User user) async {
    if (_mode == user.appMode) return;
    _mode = user.appMode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, _mode.apiValue);
    } catch (_) {}
    notifyListeners();
  }

  /// Zmienia tryb lokalnie (zapis prefs) — używane przed loginem.
  Future<void> setLocal(AppMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.apiValue);
    } catch (_) {}
    notifyListeners();
  }

  /// Zmienia tryb dla zalogowanego użytkownika — pisze do backendu + prefs.
  /// Zwraca true gdy zapis na serwerze się udał.
  Future<bool> setMode(AppMode mode, AuthProvider auth) async {
    final prev = _mode;
    // Optymistyczny update
    _mode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, mode.apiValue);
    } catch (_) {}

    if (auth.isLoggedIn) {
      final ok = await auth.updateAppMode(mode);
      if (!ok) {
        // Rollback
        _mode = prev;
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_prefsKey, prev.apiValue);
        } catch (_) {}
        notifyListeners();
        return false;
      }
    }
    return true;
  }
}
