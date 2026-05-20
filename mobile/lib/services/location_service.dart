import 'dart:math' as math;
import 'package:geolocator/geolocator.dart';

class LocationService {
  static Position? _lastTrusted;
  static DateTime? _lastTrustedAt;

  /// GPS spoofing heurystyka.
  /// - `isMocked: true` (Position.isMocked) → instant red flag.
  /// - Prędkość między ostatnią a aktualną pozycją > 280 m/s (~1000 km/h) → spoof.
  /// - Skok > 50 km w < 60s → spoof.
  static bool isSpoofed(Position pos) {
    if (pos.isMocked) return true;
    final prev = _lastTrusted;
    final prevAt = _lastTrustedAt;
    if (prev != null && prevAt != null) {
      final dt = DateTime.now().difference(prevAt).inSeconds;
      if (dt > 0 && dt < 600) {
        final meters = _haversine(prev.latitude, prev.longitude, pos.latitude, pos.longitude);
        final mps = meters / dt;
        // > 1000 km/h to fizycznie nierealne dla użytkownika
        if (mps > 280) return true;
        // > 50 km w 60s = 3000 km/h
        if (meters > 50000 && dt < 60) return true;
      }
    }
    _lastTrusted = pos;
    _lastTrustedAt = DateTime.now();
    return false;
  }

  static double _haversine(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371000.0;
    final dLat = (lat2 - lat1) * math.pi / 180;
    final dLon = (lon2 - lon1) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
            math.sin(dLon / 2) * math.sin(dLon / 2);
    return 2 * r * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  Future<Position?> getCurrentPosition() async {
    if (!await Geolocator.isLocationServiceEnabled()) return null;

    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied) return null;
    }
    if (perm == LocationPermission.deniedForever) return null;

    final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    if (isSpoofed(pos)) {
      // Spoofing — zwracamy null, klient powinien zinterpretować jako "brak zaufanej lokalizacji"
      return null;
    }
    return pos;
  }

  Stream<Position> getPositionStream() => Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 50),
  );
}
