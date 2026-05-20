import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM BG] ${message.messageId}: ${message.notification?.title}');
}

/// Globalny navigatorKey — używany przez FcmService.handlePayload i AuthGate.
final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

/// Callback rejestrowany przez UI (np. MapScreen / HomeScreen / main) który decyduje co zrobić z payloadem.
/// Wywoływany dla wszystkich routingów: tap notification (background/quit), foreground.
typedef FcmPayloadHandler = Future<void> Function(Map<String, dynamic> data);
FcmPayloadHandler? _payloadHandler;

void registerFcmPayloadHandler(FcmPayloadHandler handler) {
  _payloadHandler = handler;
}

class FcmService {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Inicjalizuje Firebase + FCM. Wywołać po zalogowaniu użytkownika.
  static Future<void> init(ApiService api) async {
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('[FCM] Firebase init failed (skipping): $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    await messaging.requestPermission(alert: true, badge: true, sound: true);
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Local notifications init z handlerem tapnięcia
    await _local.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        final payload = response.payload;
        if (payload == null || payload.isEmpty) return;
        try {
          final data = jsonDecode(payload) as Map<String, dynamic>;
          _dispatch(data);
        } catch (e) {
          debugPrint('[FCM] Bad payload: $e ($payload)');
        }
      },
    );

    // Pobierz token i wyślij na backend
    try {
      final token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Got token: ${token.substring(0, 20)}... (len=${token.length})');
        final res = await api.put('/users/me/fcm-token', {'fcm_token': token});
        debugPrint('[FCM] Register response: $res');
      } else {
        debugPrint('[FCM] getToken() returned NULL — check Firebase config / Play Services');
      }
    } catch (e, st) {
      debugPrint('[FCM] Token registration failed: $e\n$st');
    }

    messaging.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed: ${newToken.substring(0, 20)}...');
      try {
        final res = await api.put('/users/me/fcm-token', {'fcm_token': newToken});
        debugPrint('[FCM] Refresh registered: $res');
      } catch (e) {
        debugPrint('[FCM] Refresh register failed: $e');
      }
    });

    // Foreground messages → pokaż local notification z payloadem
    FirebaseMessaging.onMessage.listen(_showLocal);

    // Tap powiadomienia gdy app był w tle
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage msg) {
      debugPrint('[FCM] onMessageOpenedApp: ${msg.data}');
      _dispatch(msg.data);
    });

    // Tap powiadomienia gdy app był ubity — sprawdzamy initial message
    final initial = await FirebaseMessaging.instance.getInitialMessage();
    if (initial != null) {
      debugPrint('[FCM] getInitialMessage: ${initial.data}');
      WidgetsBinding.instance.addPostFrameCallback((_) => _dispatch(initial.data));
    }

    _initialized = true;
  }

  static Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;
    final payload = jsonEncode(Map<String, dynamic>.from(msg.data));
    await _local.show(
      msg.hashCode,
      n.title ?? 'be:Safe',
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'danger_alerts',
          'Alerty zagrożeń',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }

  /// Centralny dispatcher payloadów.
  /// Najpierw próbuje wywołać zarejestrowany handler (np. ustawiony przez AuthGate / Home).
  /// Jeśli nie ma handlera — używa navigatorKey i prostego routingu po polu `type`.
  static Future<void> _dispatch(Map<String, dynamic> data) async {
    if (data.isEmpty) return;
    debugPrint('[FCM] dispatch: $data');
    if (_payloadHandler != null) {
      try {
        await _payloadHandler!(data);
        return;
      } catch (e) {
        debugPrint('[FCM] payload handler error: $e');
      }
    }
    // Fallback — bezpośrednio routujemy
    final nav = appNavigatorKey.currentState;
    if (nav == null) {
      debugPrint('[FCM] no navigator available — payload dropped');
      return;
    }
    final type = data['type'];
    // Importy ekranów są w warstwie dispatch przekazanego handlera — fallback działa tylko na nazwie route.
    switch (type) {
      case 'new_alert':
      case 'child_in_alert_area':
      case 'family_alert_near_child':
        final alertId = data['alert_id'];
        if (alertId is String) {
          nav.pushNamed('/alert-detail', arguments: {'alert_id': alertId});
        }
        break;
      case 'family_sos':
        nav.pushNamed('/family-sos', arguments: data);
        break;
      case 'geofence_exit':
      case 'geofence_enter':
        nav.pushNamed('/family', arguments: data);
        break;
      case 'family_ping':
        nav.pushNamed('/ping-response', arguments: data);
        break;
      case 'ping_response':
        nav.pushNamed('/family');
        break;
      case 'route_exit':
      case 'route_return':
        nav.pushNamed('/family', arguments: data);
        break;
      case 'escort_invite':
      case 'escort_panic':
      case 'escort_completed':
        nav.pushNamed('/escort');
        break;
      case 'family_message':
        nav.pushNamed('/family', arguments: data);
        break;
      case 'pet_lost':
      case 'pet_lost_nearby':
      case 'pet_found':
      case 'pet_sighting':
        nav.pushNamed('/family', arguments: data);
        break;
    }
  }
}
