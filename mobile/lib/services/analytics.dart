import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Prosty analytics — buforuje eventy i wysyła batchem co 30s lub przy 20 eventach.
/// Nie wymaga Firebase/Mixpanel, używa własnego endpointu backend /events.
class Analytics {
  static ApiService? _api;
  static final List<Map<String, dynamic>> _buffer = [];
  static Timer? _flushTimer;
  static String? _sessionId;
  static bool _enabled = true;

  static void init(ApiService api) {
    _api = api;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    _loadOptOut();
    _flushTimer = Timer.periodic(const Duration(seconds: 30), (_) => flush());
  }

  static Future<void> _loadOptOut() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = !(prefs.getBool('analytics_opt_out') ?? false);
  }

  static Future<void> setOptOut(bool optOut) async {
    _enabled = !optOut;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('analytics_opt_out', optOut);
  }

  static bool get enabled => _enabled;

  /// Rejestruje event z dowolnymi parametrami.
  /// Przykład: Analytics.track('alert_created', {'category': 'aggression'});
  static void track(String event, [Map<String, dynamic>? params]) {
    if (!_enabled) return;
    _buffer.add({
      'event': event,
      'session': _sessionId,
      'ts': DateTime.now().toIso8601String(),
      if (params != null) ...params,
    });
    if (_buffer.length >= 20) flush();
  }

  static Future<void> flush() async {
    if (_buffer.isEmpty || _api == null) return;
    final batch = List<Map<String, dynamic>>.from(_buffer);
    _buffer.clear();
    try {
      await _api!.post('/events', {'events': batch});
    } catch (_) {
      // On failure, drop events (don't accumulate — prevents memory bloat)
    }
  }

  static void dispose() {
    _flushTimer?.cancel();
    flush();
  }
}
