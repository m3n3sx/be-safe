import 'dart:math' as math;

class CollisionItem {
  final String id;
  final double lat;
  final double lng;
  final String kind;
  final Map<String, dynamic> payload;
  const CollisionItem({
    required this.id,
    required this.lat,
    required this.lng,
    required this.kind,
    this.payload = const {},
  });
}

class CollisionGroup {
  final List<CollisionItem> items;
  final double anchorLat;
  final double anchorLng;
  final bool displayOnly;
  const CollisionGroup({
    required this.items,
    required this.anchorLat,
    required this.anchorLng,
    required this.displayOnly,
  });
}

const _kindOrder = {'sos': 0, 'hazard': 1, 'member': 2, 'aed': 3};

double haversineMeters(double lat1, double lng1, double lat2, double lng2) {
  const r = 6371000.0;
  final dLat = (lat2 - lat1) * math.pi / 180;
  final dLng = (lng2 - lng1) * math.pi / 180;
  final a1 = lat1 * math.pi / 180;
  final a2 = lat2 * math.pi / 180;
  final h = math.pow(math.sin(dLat / 2), 2) +
      math.cos(a1) * math.cos(a2) * math.pow(math.sin(dLng / 2), 2);
  return 2 * r * math.asin(math.min(1, math.sqrt(h)));
}

bool _samePoint(CollisionItem a, CollisionItem b) =>
    (a.lat - b.lat).abs() < 1e-5 && (a.lng - b.lng).abs() < 1e-5;

typedef ScreenPoint = ({double x, double y});

List<CollisionGroup> clusterItems(
  List<CollisionItem> items, {
  required ScreenPoint Function(CollisionItem item) project,
  double pixelThreshold = 48,
  double metersThreshold = 15,
}) {
  final parent = List<int>.generate(items.length, (i) => i);
  int find(int i) {
    while (parent[i] != i) {
      parent[i] = parent[parent[i]];
      i = parent[i];
    }
    return i;
  }

  for (var i = 0; i < items.length; i++) {
    for (var j = i + 1; j < items.length; j++) {
      final left = project(items[i]);
      final right = project(items[j]);
      final dx = left.x - right.x;
      final dy = left.y - right.y;
      final closePixels = math.sqrt(dx * dx + dy * dy) < pixelThreshold;
      final closeMeters = metersThreshold > 0 &&
          haversineMeters(items[i].lat, items[i].lng, items[j].lat, items[j].lng) < metersThreshold;
      if (_samePoint(items[i], items[j]) || closeMeters || closePixels) {
        parent[find(i)] = find(j);
      }
    }
  }
  final buckets = <int, List<CollisionItem>>{};
  for (var i = 0; i < items.length; i++) {
    buckets.putIfAbsent(find(i), () => []).add(items[i]);
  }
  return buckets.values.map((bucket) {
    final sorted = [...bucket]..sort((a, b) {
        final byKind = (_kindOrder[a.kind] ?? 9) - (_kindOrder[b.kind] ?? 9);
        if (byKind != 0) return byKind;
        return a.id.compareTo(b.id);
      });
    final identical = sorted.every((item) => _samePoint(item, sorted.first));
    final lat = identical
        ? sorted.first.lat
        : sorted.map((e) => e.lat).reduce((a, b) => a + b) / sorted.length;
    final lng = identical
        ? sorted.first.lng
        : sorted.map((e) => e.lng).reduce((a, b) => a + b) / sorted.length;
    return CollisionGroup(
      items: sorted,
      anchorLat: lat,
      anchorLng: lng,
      displayOnly: sorted.length > 1,
    );
  }).toList();
}

ScreenPoint Function(CollisionItem item) mercatorProject({
  required double lat,
  required double lng,
  required double zoom,
  required double width,
  required double height,
}) {
  final scale = 256 * math.pow(2, zoom);
  double xOf(double longitude) => (longitude + 180) / 360 * scale;
  double yOf(double latitude) {
    final clamped = latitude.clamp(-85, 85).toDouble();
    final s = math.sin(clamped * math.pi / 180);
    return (0.5 - math.log((1 + s) / (1 - s)) / (4 * math.pi)) * scale;
  }

  final cx = xOf(lng);
  final cy = yOf(lat);
  return (item) => (x: xOf(item.lng) - cx + width / 2, y: yOf(item.lat) - cy + height / 2);
}
