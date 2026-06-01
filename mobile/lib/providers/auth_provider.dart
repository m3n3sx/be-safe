import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _loading = false;
  bool _autoLoginInProgress = false;
  bool _autoLoginAttempted = false;
  // Web OAuth client ID z google-services.json (type=3) — wymagany na Androidzie
  // żeby Google Sign-In zwracał idToken zamiast rzucać ApiException:10.
  final _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    serverClientId: '1098119585965-1dmn79cgjbhsr84f1iu3dibvpilc906p.apps.googleusercontent.com',
  );

  AuthProvider(this._api);

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  /// True while tryAutoLogin is fetching session from server.
  /// UI should show "checking session" spinner instead of LoginScreen
  /// to avoid flash of unauthenticated state.
  bool get autoLoginInProgress => _autoLoginInProgress;

  /// True after tryAutoLogin has completed (success or fail).
  /// Used by _AuthGate to decide if LoginScreen should be shown.
  bool get autoLoginAttempted => _autoLoginAttempted;

  Future<bool> register(String email, String password, String username, {String? referralCode}) async {
    _loading = true; notifyListeners();
    try {
      final body = <String, dynamic>{'email': email, 'password': password, 'username': username};
      if (referralCode != null && referralCode.trim().isNotEmpty) body['referral_code'] = referralCode.trim().toUpperCase();
      final res = await _api.post('/auth/register', body);
      if (res['token'] != null) {
        await _api.setToken(res['token']);
        _user = User.fromJson(res['user']);
        notifyListeners();
        return true;
      }
      return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<bool> login(String email, String password) async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.post('/auth/login', {'email': email, 'password': password});
      if (res['token'] != null) {
        await _api.setToken(res['token']);
        _user = User.fromJson(res['user']);
        notifyListeners();
        return true;
      }
      return false;
    } finally { _loading = false; notifyListeners(); }
  }

  Future<bool> demoLogin() async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.post('/auth/demo', {});
      if (res['token'] != null) {
        await _api.setToken(res['token']);
        _user = User.fromJson(res['user']);
        notifyListeners();
        return true;
      }
      return false;
    } catch (_) { return false; }
    finally { _loading = false; notifyListeners(); }
  }

  Future<bool> loginWithGoogle({String? referralCode}) async {
    _loading = true;
    notifyListeners();
    try {
      await _googleSignIn.signOut();
      final account = await _googleSignIn.signIn();
      if (account == null) {
        return false;
      }
      final body = <String, dynamic>{
        'email': account.email,
        'display_name': account.displayName ?? account.email.split('@')[0],
        'avatar_url': account.photoUrl,
      };
      if (referralCode != null && referralCode.trim().isNotEmpty) {
        body['referral_code'] = referralCode.trim().toUpperCase();
      }
      final res = await _api.post('/auth/google', body);
      if (res['token'] != null) {
        await _api.setToken(res['token']);
        _user = User.fromJson(res['user']);
        return true;
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
    return false;
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _googleSignIn.signOut();
    _user = null;
    notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    await _api.loadToken();
    if (_api.token == null) {
      _autoLoginAttempted = true;
      notifyListeners();
      return;
    }
    // Token istnieje — pokazujemy "Sprawdzam sesję..." zamiast LoginScreen
    _autoLoginInProgress = true;
    notifyListeners();
    try {
      // Timeout 6s — jeśli serwer nie odpowiada, fallback do LoginScreen
      // (zachowany token, więc po ręcznym loginie znów spróbuje auto)
      final res = await _api
          .get('/users/me')
          .timeout(const Duration(seconds: 6), onTimeout: () => <String, dynamic>{});
      if (res['id'] != null) {
        _user = User.fromJson(res);
      }
    } catch (_) {
      // Token nieaktualny lub sieć padła — zostawiamy LoginScreen
    } finally {
      _autoLoginInProgress = false;
      _autoLoginAttempted = true;
      notifyListeners();
    }
  }

  /// Odśwież profil użytkownika z serwera bez ponownego logowania.
  Future<void> refreshMe() async {
    if (_api.token == null) return;
    final res = await _api.get('/users/me');
    if (res['id'] != null) {
      _user = User.fromJson(res);
      notifyListeners();
    }
  }

  /// Zmienia tryb aplikacji użytkownika. Aktualizuje lokalnie + PATCH do backendu.
  /// Zwraca true gdy zapis się powiódł.
  Future<bool> updateAppMode(AppMode mode) async {
    if (_user == null) return false;
    final prev = _user!.appMode;
    // Optymistyczny update
    _user = _user!.copyWith(appMode: mode);
    notifyListeners();
    try {
      final res = await _api.patch('/users/me', {'app_mode': mode.apiValue});
      if (res['error'] != null) {
        // Rollback
        _user = _user!.copyWith(appMode: prev);
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      _user = _user!.copyWith(appMode: prev);
      notifyListeners();
      return false;
    }
  }
}
