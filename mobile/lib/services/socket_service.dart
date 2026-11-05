import 'dart:async';
import 'package:socket_io_client/socket_io_client.dart' as io;

typedef CommentHandler = void Function(Map<String, dynamic>);
typedef TypingHandler = void Function(Map<String, dynamic>);

class SocketService {
  static const serverUrl = 'https://besafe.org.pl';
  io.Socket? _socket;
  String? _token;
  final _alertCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _geoCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _locCtrl = StreamController<Map<String, dynamic>>.broadcast();
  final _noteCtrl = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get alerts => _alertCtrl.stream;
  Stream<Map<String, dynamic>> get geofenceExits => _geoCtrl.stream;
  Stream<Map<String, dynamic>> get familyLocations => _locCtrl.stream;
  Stream<Map<String, dynamic>> get notifications => _noteCtrl.stream;

  // F14: broadcast stream for family chat messages
  final StreamController<Map<String, dynamic>> _familyMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onFamilyMessage => _familyMessageCtrl.stream;

  // F14: broadcast stream for neighborhood (geofence) chat messages
  final StreamController<Map<String, dynamic>> _neighborhoodMessageCtrl =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onNeighborhoodMessage =>
      _neighborhoodMessageCtrl.stream;

  // Per-alert listener callbacks. Keyed by alert id so we can register/unregister
  // independently of the main `connect()` subscription.
  final Map<String, List<CommentHandler>> _commentHandlers = {};
  final Map<String, List<CommentHandler>> _commentDeleteHandlers = {};
  final Map<String, List<TypingHandler>> _typingHandlers = {};

  bool get connected => _socket?.connected ?? false;

  void ensureConnected(String token) {
    if (_socket != null && _token == token) return;
    _socket?.disconnect();
    _socket?.dispose();
    _token = token;
    _socket = io.io(serverUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'token': token})
      .enableReconnection()
      .setReconnectionDelay(1000)
      .setReconnectionDelayMax(10000)
      .build());

    _socket!.on('alert:new', (data) => _alertCtrl.add(Map<String, dynamic>.from(data as Map)));
    _socket!.on('family:location', (data) => _locCtrl.add(Map<String, dynamic>.from(data as Map)));
    _socket!.on('family:geofence_exit', (data) => _geoCtrl.add(Map<String, dynamic>.from(data as Map)));
    _socket!.on('notification:new', (data) => _noteCtrl.add(Map<String, dynamic>.from(data as Map)));
    _socket!.on('family:ping', (data) {
      final ping = Map<String, dynamic>.from(data as Map);
      _noteCtrl.add({
        'id': ping['notification_id'] ?? ping['ping_id'],
        'type': 'family_ping',
        'title': 'Prośba o kontakt w be:Safe',
        'body': '${ping['from_username'] ?? 'Bliska osoba'} prosi o znak życia.',
        'ping_id': ping['ping_id'],
        'data': ping,
      });
    });
    _socket!.on('family:message', (data) {
      _familyMessageCtrl.add(Map<String, dynamic>.from(data));
    });
    _socket!.on('neighborhood:message', (data) {
      _neighborhoodMessageCtrl.add(Map<String, dynamic>.from(data));
    });

    _socket!.on('comment:new', (data) {
      final m = Map<String, dynamic>.from(data);
      final id = m['alert_id']?.toString();
      if (id == null) return;
      for (final h in (_commentHandlers[id] ?? const <CommentHandler>[])) {
        h(m);
      }
    });
    _socket!.on('comment:deleted', (data) {
      final m = Map<String, dynamic>.from(data);
      final id = m['alert_id']?.toString();
      if (id == null) return;
      for (final h in (_commentDeleteHandlers[id] ?? const <CommentHandler>[])) {
        h(m);
      }
    });
    _socket!.on('alert:typing', (data) {
      final m = Map<String, dynamic>.from(data);
      final id = m['alert_id']?.toString();
      if (id == null) return;
      for (final h in (_typingHandlers[id] ?? const <TypingHandler>[])) {
        h(m);
      }
    });
  }

  void updateLocation(double lat, double lng) {
    _socket?.emit('location:update', {'lat': lat, 'lng': lng});
  }

  // ---- Live chat per alert ----

  /// Subscribe to a specific alert's comment stream. Returns an unsubscribe fn.
  void Function() subscribeToAlert(
    String alertId, {
    CommentHandler? onNewComment,
    CommentHandler? onCommentDeleted,
    TypingHandler? onTyping,
  }) {
    _socket?.emit('alert:join', alertId);

    if (onNewComment != null) {
      _commentHandlers.putIfAbsent(alertId, () => []).add(onNewComment);
    }
    if (onCommentDeleted != null) {
      _commentDeleteHandlers.putIfAbsent(alertId, () => []).add(onCommentDeleted);
    }
    if (onTyping != null) {
      _typingHandlers.putIfAbsent(alertId, () => []).add(onTyping);
    }

    return () {
      _commentHandlers[alertId]?.remove(onNewComment);
      _commentDeleteHandlers[alertId]?.remove(onCommentDeleted);
      _typingHandlers[alertId]?.remove(onTyping);
      _socket?.emit('alert:leave', alertId);
    };
  }

  void emitTyping(String alertId, bool isTyping) {
    _socket?.emit('alert:typing', {'alert_id': alertId, 'is_typing': isTyping});
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _token = null;
  }
}
