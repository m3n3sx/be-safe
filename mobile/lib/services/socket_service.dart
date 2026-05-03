import 'package:socket_io_client/socket_io_client.dart' as io;

class SocketService {
  static const serverUrl = 'https://alert.u235.pl';
  io.Socket? _socket;

  void connect(String token, {
    Function(Map<String, dynamic>)? onNewAlert,
    Function(Map<String, dynamic>)? onFamilyLocation,
    Function(Map<String, dynamic>)? onGeofenceExit,
  }) {
    _socket = io.io(serverUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setQuery({'token': token})
      .build());

    _socket!.on('alert:new', (data) => onNewAlert?.call(Map<String, dynamic>.from(data)));
    _socket!.on('family:location', (data) => onFamilyLocation?.call(Map<String, dynamic>.from(data)));
    _socket!.on('family:geofence_exit', (data) => onGeofenceExit?.call(Map<String, dynamic>.from(data)));
  }

  void updateLocation(double lat, double lng) {
    _socket?.emit('location:update', {'lat': lat, 'lng': lng});
  }

  void disconnect() => _socket?.disconnect();
}
