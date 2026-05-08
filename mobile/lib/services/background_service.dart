import 'dart:ui';
import 'dart:async';
import 'package:battery_plus/battery_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'socket_service.dart';

class BackgroundService {
  final ApiService _api;
  final SocketService _socket;
  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _locationSub;
  Timer? _pollTimer;
  Timer? _batteryTimer;
  final _battery = Battery();
  final Set<String> _notifiedAlertIds = {};

  BackgroundService(this._api, this._socket);

  Future<void> init() async {
    await _notifications.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

    // Request notification permission (Android 13+)
    final androidPlugin = _notifications.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'danger_alerts', 'Alerty zagrożeń',
      description: 'Powiadomienia o zagrożeniach w okolicy',
      importance: Importance.max, playSound: true, enableVibration: true, enableLights: true,
    ));
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      'family_alerts', 'Alerty rodzinne',
      description: 'Geofence i lokalizacja rodziny',
      importance: Importance.high, playSound: true, enableVibration: true,
    ));
  }

  void startTracking(String token) {
    // WebSocket — real-time gdy apka jest otwarta
    _socket.connect(token,
      onNewAlert: (data) async {
        final id = data['id']?.toString() ?? '';
        if (id.isNotEmpty) _notifiedAlertIds.add(id);
        if (!await _prefEnabled('notif_alerts')) return;
        _showDangerNotification(
          '⚠️ ${_categoryLabel(data['category']?.toString())}',
          data['title'] ?? 'Nowe zagrożenie w okolicy',
          data['description']?.toString(),
        );
      },
      onGeofenceExit: (data) async {
        if (!await _prefEnabled('notif_family')) return;
        _showFamilyNotification(
          '🚨 Dziecko opuściło bezpieczną strefę!',
          '${data['username'] ?? 'Dziecko'} opuścił/a strefę "${data['geofence_name'] ?? ''}"',
        );
      },
    );

    // Location tracking
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((pos) {
      _socket.updateLocation(pos.latitude, pos.longitude);
      _api.post('/users/me/location', {'lat': pos.latitude, 'lng': pos.longitude}).catchError((_) {});
    });

    // Polling — co 60s sprawdza nowe alerty (działa nawet gdy WebSocket padnie)
    _startPolling();

    // Battery reporting — co 10 min
    _reportBattery();
    _batteryTimer = Timer.periodic(const Duration(minutes: 10), (_) => _reportBattery());
  }

  Future<void> _reportBattery() async {
    try {
      final level = await _battery.batteryLevel;
      await _api.put('/users/me/battery', {'level': level});
    } catch (_) {}
  }

  void _startPolling() {
    // Pierwszy poll od razu po 5 sekundach (daj czas na GPS)
    var lastCheck = DateTime.now().subtract(const Duration(minutes: 5)).toUtc().toIso8601String();

    Future<void> poll() async {
      try {
        if (!await _prefEnabled('notif_alerts')) return;
        final res = await _api.get('/alerts/new', {'since': lastCheck});
        lastCheck = DateTime.now().toUtc().toIso8601String();
        final alerts = res['alerts'] as List? ?? [];

        for (final a in alerts) {
          final id = a['id']?.toString() ?? '';
          if (_notifiedAlertIds.contains(id)) continue;
          _notifiedAlertIds.add(id);
          _showDangerNotification(
            '⚠️ ${_categoryLabel(a['category']?.toString())}',
            a['title'] ?? 'Nowe zagrożenie',
            a['description']?.toString(),
          );
        }
      } catch (_) {}
    }

    // Pierwszy poll po 5s
    Future.delayed(const Duration(seconds: 5), poll);
    // Potem co 60s
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => poll());
  }

  void stopTracking() {
    _locationSub?.cancel();
    _pollTimer?.cancel();
    _batteryTimer?.cancel();
    _socket.disconnect();
  }

  String _categoryLabel(String? cat) => switch (cat) {
    'aggression' => 'Agresywne osoby',
    'theft' => 'Kradzież',
    'accident' => 'Wypadek',
    'fire' => 'Pożar',
    'flood' => 'Powódź',
    'animal' => 'Niebezpieczne zwierzę',
    'dark_area' => 'Nieoświetlony teren',
    'drugs' => 'Narkotyki',
    'stranger_danger' => 'Podejrzana osoba',
    'traffic_danger' => 'Niebezpieczne przejście',
    _ => 'ZAGROŻENIE',
  };

  Future<bool> _prefEnabled(String key) async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(key) ?? true;
  }

  Future<bool> get _soundEnabled async => _prefEnabled('notif_sound');
  Future<bool> get _vibrationEnabled async => _prefEnabled('notif_vibration');

  Future<void> _showDangerNotification(String title, String body, [String? bigText]) async {
    final sound = await _soundEnabled;
    final vibration = await _vibrationEnabled;
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'danger_alerts', 'Alerty zagrożeń',
          importance: Importance.max, priority: Priority.max,
          fullScreenIntent: true, category: AndroidNotificationCategory.alarm,
          visibility: NotificationVisibility.public,
          playSound: sound, enableVibration: vibration,
          styleInformation: bigText != null ? BigTextStyleInformation(bigText, contentTitle: title) : null,
          ticker: title, colorized: true, color: const Color(0xFFFF1744),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true, interruptionLevel: InterruptionLevel.critical),
      ),
    );
  }

  Future<void> _showFamilyNotification(String title, String body) async {
    final sound = await _soundEnabled;
    final vibration = await _vibrationEnabled;
    await _notifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000, title, body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'family_alerts', 'Alerty rodzinne',
          importance: Importance.high, priority: Priority.high,
          fullScreenIntent: true, category: AndroidNotificationCategory.alarm,
          playSound: sound, enableVibration: vibration,
          colorized: true, color: const Color(0xFFFF6D00),
        ),
        iOS: const DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }
}
