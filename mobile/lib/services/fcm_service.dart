import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'api_service.dart';

@pragma('vm:entry-point')
Future<void> _fcmBackgroundHandler(RemoteMessage message) async {
  // Background handler — just log. Local notifications są pokazywane automatycznie przez system.
  debugPrint('[FCM BG] ${message.messageId}: ${message.notification?.title}');
}

class FcmService {
  static final _local = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  /// Inicjalizuje Firebase + FCM. Wywołać po zalogowaniu użytkownika.
  /// Jeśli Firebase nie jest skonfigurowany (brak google-services.json), FCM jest pomijany.
  static Future<void> init(ApiService api) async {
    // Always re-register token (even if Firebase already initialized)
    try {
      if (!_initialized) {
        await Firebase.initializeApp();
      }
    } catch (e) {
      debugPrint('[FCM] Firebase init failed (skipping): $e');
      return;
    }

    final messaging = FirebaseMessaging.instance;

    // Android 13+ wymaga uprawnień
    await messaging.requestPermission(alert: true, badge: true, sound: true);

    // Background handler
    FirebaseMessaging.onBackgroundMessage(_fcmBackgroundHandler);

    // Local notifications setup
    await _local.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    ));

    // Pobierz token i wyślij na backend
    final token = await messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token: ${token.substring(0, 20)}...');
      try {
        await api.put('/users/me/fcm-token', {'fcm_token': token});
      } catch (_) {}
    }

    // Refresh token listener
    messaging.onTokenRefresh.listen((newToken) async {
      try {
        await api.put('/users/me/fcm-token', {'fcm_token': newToken});
      } catch (_) {}
    });

    // Foreground messages — pokaż local notification
    FirebaseMessaging.onMessage.listen((RemoteMessage msg) {
      _showLocal(msg);
    });

    _initialized = true;
  }

  static Future<void> _showLocal(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null) return;
    await _local.show(
      msg.hashCode,
      n.title ?? 'be:Safe',
      n.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'danger_alerts', 'Alerty zagrożeń',
          importance: Importance.max,
          priority: Priority.high,
          fullScreenIntent: true,
          category: AndroidNotificationCategory.alarm,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
