import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService _api;
  User? _user;
  bool _loading = false;
  final _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  AuthProvider(this._api);

  User? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get loading => _loading;

  Future<bool> register(String email, String password, String username) async {
    _loading = true; notifyListeners();
    try {
      final res = await _api.post('/auth/register', {'email': email, 'password': password, 'username': username});
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

  Future<bool> loginWithGoogle() async {
    _loading = true; notifyListeners();
    try {
      try { await _googleSignIn.disconnect(); } catch (_) {}
      final account = await _googleSignIn.signIn();
      if (account == null) { _loading = false; notifyListeners(); return false; }
      final res = await _api.post('/auth/google', {
        'email': account.email,
        'display_name': account.displayName ?? account.email.split('@')[0],
        'avatar_url': account.photoUrl,
      });
      if (res['token'] != null) {
        await _api.setToken(res['token']);
        final u = res['user'];
        _user = User(id: u['id'], email: u['email'], username: u['username'] ?? '',
          avatarUrl: u['avatar_url'], alertRadiusM: u['alert_radius_m'] ?? 500, reputationScore: u['reputation_score'] ?? 100);
        _loading = false;
        notifyListeners();
        return true;
      }
    } catch (_) {}
    _loading = false; notifyListeners();
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
    if (_api.token != null) {
      final res = await _api.get('/users/me');
      if (res['id'] != null) _user = User.fromJson(res);
      notifyListeners();
    }
  }
}
