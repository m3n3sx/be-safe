import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:battery_plus/battery_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import 'socket_service.dart';

const String _fgsNotificationChannelId = 'be_safe_fgs';
const int _fgsNotificationId = 777;

/// BackgroundService steers two execution paths:
///
/// 1. **Foreground** (app active): uses WebSocket + in-process Geolocator
///    stream (existing behaviour).
/// 2. **Background / killed app**: a Foreground Service runs
///    [_onBackgroundStart] in a separate isolate, polling GPS + `/alerts/new`
///    every minute, showing local notifications for nearby alerts.
///
/// The two paths deduplicate via the `_notifiedAlertIds` set (in-memory in
/// each isolate) and the server's `alert_notifications` table (dedup by
/// user_id + alert_id when FCM is used).
class BackgroundService {
  final ApiService _api;
  final SocketService _socket;
  final _notifications = FlutterLocalNotificationsPlugin();
  StreamSubscription<Position>? _locationSub;
  Timer? _pollTimer;
  Timer? _batteryTimer;
  final _battery = Battery();
  final Set<String> _notifiedAlertIds = {};
  bool _configured = false;

  BackgroundService(this._api, this._socket);

  Future<void> init() async {
    await _notifications.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

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
    await androidPlugin?.createNotificationChannel(const AndroidNotificationChannel(
      _fgsNotificationChannelId, 'be:Safe działa w tle',
      description: 'Pozwala apce wysyłać powiadomienia o zagrożeniach gdy jest zamknięta',
      importance: Importance.low,
      playSound: false, enableVibration: false, showBadge: false,
    ));

    await _configureBackgroundService();
  }

  Future<void> _configureBackgroundService() async {
    if (_configured) return;
    final svc = FlutterBackgroundService();
    await svc.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onBackgroundStart,
        autoStart: false, // uruchamiamy ręcznie po zalogowaniu
        isForegroundMode: true,
        notificationChannelId: _fgsNotificationChannelId,
        initialNotificationTitle: 'be:Safe — monitoring zagrożeń',
        initialNotificationContent: 'Otrzymasz powiadomienie gdy w okolicy pojawi się alert.',
        foregroundServiceNotificationId: _fgsNotificationId,
        foregroundServiceTypes: [
          AndroidForegroundType.location,
          AndroidForegroundType.dataSync,
        ],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: _onBackgroundStart,
        onBackground: _onIosBackground,
      ),
    );
    _configured = true;
  }

  void startTracking(String token) {
    // Zapisz token aby background isolate mógł go odczytać przez SharedPreferences.
    SharedPreferences.getInstance().then((p) => p.setString('jwt_token', token));

    // Uruchom Foreground Service (przetrwa kill apki na Androidzie).
    FlutterBackgroundService().startService().catchError((e) {
      debugPrint('[BG] startService failed: $e');
      return false;
    });

    // WebSocket — real-time gdy apka otwarta
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

    // Foreground GPS stream (gdy app otwarta, background robi własne)
    _locationSub = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
    ).listen((pos) {
      _socket.updateLocation(pos.latitude, pos.longitude);
      _api.post('/users/me/location', {'lat': pos.latitude, 'lng': pos.longitude}).catchError((_) => <String, dynamic>{});
    });

    _startPolling();
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

    Future.delayed(const Duration(seconds: 5), poll);
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => poll());
  }

  void stopTracking() {
    _locationSub?.cancel();
    _pollTimer?.cancel();
    _batteryTimer?.cancel();
    _socket.disconnect();
    FlutterBackgroundService().invoke('stopService');
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

// ---------------------------------------------------------------------------
// Background isolate entry point. Musi być top-level + @pragma('vm:entry-point').
// Runs w osobnym isolate — nie ma dostępu do Providerów/BuildContext.
// Komunikacja z main isolate: SharedPreferences + service.invoke().
// ---------------------------------------------------------------------------

@pragma('vm:entry-point')
void _onBackgroundStart(ServiceInstance service) async {
  // Loguj do Android logcat
  debugPrint('[BG isolate] started');

  // Zatrzymanie na żądanie
  service.on('stopService').listen((event) async {
    debugPrint('[BG isolate] stopService received');
    await service.stopSelf();
  });

  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('jwt_token');
  if (token == null || token.isEmpty) {
    debugPrint('[BG isolate] brak tokenu — stop');
    await service.stopSelf();
    return;
  }

  // Update FGS notification (Android)
  if (service is AndroidServiceInstance) {
    service.setForegroundNotificationInfo(
      title: 'be:Safe — monitoring zagrożeń',
      content: 'Nasłuchuję alertów w Twojej okolicy.',
    );
  }

  final localNotif = FlutterLocalNotificationsPlugin();
  await localNotif.initialize(const InitializationSettings(
    android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    iOS: DarwinInitializationSettings(),
  ));

  final seenAlertIds = <String>{};
  var lastCheck = DateTime.now().subtract(const Duration(minutes: 5)).toUtc().toIso8601String();
  double? lastLat;
  // ignore: unused_local_variable
  double? lastLng;

  Future<void> pushLocation() async {
    try {
      final hasPerm = await Geolocator.checkPermission();
      if (hasPerm == LocationPermission.denied || hasPerm == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      );
      lastLat = pos.latitude;
      lastLng = pos.longitude;
      await http.post(
        Uri.parse('${ApiService.baseUrl}/users/me/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'lat': pos.latitude, 'lng': pos.longitude}),
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      debugPrint('[BG isolate] location push failed: $e');
    }
  }

  Future<void> pollAlerts() async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/alerts/new').replace(queryParameters: {'since': lastCheck});
      final res = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 15));
      lastCheck = DateTime.now().toUtc().toIso8601String();
      if (res.statusCode >= 400) return;
      final data = jsonDecode(res.body);
      final alerts = data['alerts'] as List? ?? [];
      for (final a in alerts) {
        final id = a['id']?.toString() ?? '';
        if (id.isEmpty || seenAlertIds.contains(id)) continue;
        seenAlertIds.add(id);
        await localNotif.show(
          DateTime.now().millisecondsSinceEpoch ~/ 1000,
          '⚠️ ${a['title'] ?? 'Nowe zagrożenie'}',
          a['description']?.toString() ?? 'Sprawdź szczegóły w aplikacji.',
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'danger_alerts', 'Alerty zagrożeń',
              importance: Importance.max, priority: Priority.max,
              playSound: true, enableVibration: true,
              colorized: true, color: Color(0xFFFF1744),
            ),
            iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
          ),
        );
      }
    } catch (e) {
      debugPrint('[BG isolate] poll failed: $e');
    }
  }

  // Pierwszy cykl po ~5s (daj czas GPS)
  Future.delayed(const Duration(seconds: 5), () async {
    await pushLocation();
    await pollAlerts();
  });

  // Cykl co 60s — lokalizacja co 2 minuty, poll co minutę
  int tick = 0;
  Timer.periodic(const Duration(seconds: 60), (t) async {
    tick++;
    if (tick % 2 == 0) await pushLocation();
    await pollAlerts();
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(
        title: 'be:Safe — monitoring zagrożeń',
        content: lastLat != null
          ? 'Ostatnia aktualizacja ${DateTime.now().hour.toString().padLeft(2, '0')}:${DateTime.now().minute.toString().padLeft(2, '0')}'
          : 'Czekam na lokalizację…',
      );
    }
  });
}

@pragma('vm:entry-point')
Future<bool> _onIosBackground(ServiceInstance service) async {
  // iOS background modes są ograniczone — tylko szybkie operacje.
  // Pełny tracking wymaga APNs silent push lub Significant Location Changes (poza zakresem).
  return true;
}
