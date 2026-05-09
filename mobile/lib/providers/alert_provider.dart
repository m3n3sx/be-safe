import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';
import '../services/api_service.dart';
import '../services/socket_service.dart';
import '../services/cache_service.dart';

class AlertProvider extends ChangeNotifier {
  final ApiService _api;
  final SocketService _socket;
  List<AlertModel> _alerts = [];
  Set<AlertCategory> _activeFilters = {};
  bool _loading = false;

  AlertProvider(this._api, this._socket);

  List<AlertModel> get alerts => _activeFilters.isEmpty
      ? _alerts
      : _alerts.where((a) => _activeFilters.contains(a.category)).toList();
  List<AlertModel> get allAlerts => _alerts;
  bool get loading => _loading;
  Set<AlertCategory> get activeFilters => _activeFilters;

  void toggleFilter(AlertCategory cat) {
    if (_activeFilters.contains(cat)) {
      _activeFilters.remove(cat);
    } else {
      _activeFilters.add(cat);
    }
    notifyListeners();
  }

  void clearFilters() { _activeFilters.clear(); notifyListeners(); }

  Future<void> loadNearby(LatLng pos, {int radiusM = 2000}) async {
    _loading = true; notifyListeners();

    // 1. Seed UI z cache (jeśli świeży) — natychmiastowa odpowiedź offline / slow network
    try {
      final cached = await CacheService.getCachedAlertsForRegion(pos);
      if (cached != null && cached.isNotEmpty) {
        _alerts = cached;
        notifyListeners();
      }
    } catch (_) {}

    try {
      final res = await _api.get('/alerts/nearby', {
        'lat': pos.latitude.toString(),
        'lng': pos.longitude.toString(),
        'radius_m': radiusM.toString(),
      });
      if (res['alerts'] != null) {
        _alerts = (res['alerts'] as List).map((a) => AlertModel.fromJson(a)).toList();
        CacheService.cacheAlertsForRegion(pos, _alerts).catchError((_) {});
      } else if (res['error'] != null && _alerts.isEmpty) {
        // Fallback: retry-wyczerpany / sieć leży → weź z legacy globalnego cache
        try { _alerts = await CacheService.getCachedAlerts(); } catch (_) {}
      }
    } catch (_) {
      // Offline / exception — fallback do legacy cache
      if (_alerts.isEmpty) {
        try { _alerts = await CacheService.getCachedAlerts(); } catch (_) {}
      }
    } finally { _loading = false; notifyListeners(); }
  }

  Future<void> vote(String alertId, String voteType) async {
    await _api.post('/alerts/$alertId/vote', {'vote': voteType});
    // Update local state
    final idx = _alerts.indexWhere((a) => a.id == alertId);
    if (idx >= 0) {
      final res = await _api.get('/alerts/$alertId');
      if (res['id'] != null) _alerts[idx] = AlertModel.fromJson(res);
      notifyListeners();
    }
  }

  void connectSocket(String token) {
    _socket.connect(token, onNewAlert: (data) {
      try {
        _alerts.insert(0, AlertModel.fromJson(data));
        notifyListeners();
      } catch (_) {}
    });
  }

  void disconnectSocket() => _socket.disconnect();
}
