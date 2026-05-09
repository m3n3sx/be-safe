import 'dart:convert';
import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/alert.dart';

/// Offline alert cache with per-region TTL.
///
/// Schema v2:
/// - `alerts_cache` stores per-alert snapshots (kept for legacy calls).
/// - `region_cache` stores alert IDs grouped by a quantized region key with
///   an expiry timestamp. Regions are 1000 m squares keyed by rounded
///   lat/lng so nearby lookups reuse the same bucket.
class CacheService {
  static Database? _db;
  static const Duration defaultTtl = Duration(minutes: 5);
  static const int _schemaVersion = 2;

  /// Size of a region bucket in degrees (~1.1 km at equator, ~700 m at 52°N).
  /// Small enough for city-level reuse, large enough to cap cache size.
  static const double _regionStep = 0.01;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'alertmap_cache.db'),
      version: _schemaVersion,
      onCreate: (db, _) async {
        await db.execute(
          'CREATE TABLE alerts_cache (id TEXT PRIMARY KEY, data TEXT, cached_at INTEGER)',
        );
        await db.execute(
          'CREATE TABLE region_cache ('
          'region_key TEXT PRIMARY KEY, '
          'alert_ids TEXT NOT NULL, '
          'cached_at INTEGER NOT NULL, '
          'expires_at INTEGER NOT NULL)',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'CREATE TABLE IF NOT EXISTS region_cache ('
            'region_key TEXT PRIMARY KEY, '
            'alert_ids TEXT NOT NULL, '
            'cached_at INTEGER NOT NULL, '
            'expires_at INTEGER NOT NULL)',
          );
        }
      },
    );
    return _db!;
  }

  // Legacy API — global cache (still used for simple flows).
  static Future<void> cacheAlerts(List<AlertModel> alerts) async {
    final d = await db;
    final batch = d.batch();
    batch.delete('alerts_cache');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final a in alerts) {
      batch.insert('alerts_cache',
        {'id': a.id, 'data': jsonEncode(a.toJson()), 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<AlertModel>> getCachedAlerts() async {
    final d = await db;
    final rows = await d.query('alerts_cache', orderBy: 'cached_at DESC');
    return rows.map((r) => AlertModel.fromJson(jsonDecode(r['data'] as String))).toList();
  }

  // ---- Per-region API ----

  /// Quantize a coordinate to a region key.
  /// Two calls with coordinates within ~1 km of each other share the key.
  static String regionKey(LatLng center, {double stepDeg = _regionStep}) {
    final lat = (center.latitude / stepDeg).round() * stepDeg;
    final lng = (center.longitude / stepDeg).round() * stepDeg;
    return '${lat.toStringAsFixed(3)},${lng.toStringAsFixed(3)}';
  }

  /// Also seed neighbouring buckets if the requested radius exceeds the cell.
  static List<String> regionKeysCovering(LatLng center, double radiusM) {
    // Roughly convert radius metres to degrees (lat fixed; lng scaled by cos).
    final latDeg = radiusM / 111320.0;
    final lngDeg = radiusM / (111320.0 * math.cos(center.latitude * math.pi / 180));
    final latStep = (latDeg / _regionStep).ceil();
    final lngStep = (lngDeg / _regionStep).ceil();
    final keys = <String>{};
    for (int dy = -latStep; dy <= latStep; dy++) {
      for (int dx = -lngStep; dx <= lngStep; dx++) {
        final lat = center.latitude + dy * _regionStep;
        final lng = center.longitude + dx * _regionStep;
        keys.add(regionKey(LatLng(lat, lng)));
      }
    }
    return keys.toList();
  }

  /// Cache alerts for a specific region with TTL.
  static Future<void> cacheAlertsForRegion(
    LatLng center,
    List<AlertModel> alerts, {
    Duration ttl = defaultTtl,
  }) async {
    final d = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    final expires = now + ttl.inMilliseconds;
    final key = regionKey(center);
    final batch = d.batch();

    // Update per-alert cache
    for (final a in alerts) {
      batch.insert('alerts_cache',
        {'id': a.id, 'data': jsonEncode(a.toJson()), 'cached_at': now},
        conflictAlgorithm: ConflictAlgorithm.replace);
    }

    // Update region entry
    batch.insert('region_cache', {
      'region_key': key,
      'alert_ids': jsonEncode(alerts.map((a) => a.id).toList()),
      'cached_at': now,
      'expires_at': expires,
    }, conflictAlgorithm: ConflictAlgorithm.replace);

    await batch.commit(noResult: true);
  }

  /// Returns alerts cached for a region if entry exists and is not expired.
  /// Returns null if no valid cache — caller should fetch from network.
  static Future<List<AlertModel>?> getCachedAlertsForRegion(LatLng center) async {
    final d = await db;
    final key = regionKey(center);
    final now = DateTime.now().millisecondsSinceEpoch;

    final rows = await d.query(
      'region_cache',
      where: 'region_key = ? AND expires_at > ?',
      whereArgs: [key, now],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final ids = (jsonDecode(rows.first['alert_ids'] as String) as List).cast<String>();
    if (ids.isEmpty) return [];

    final placeholders = List.filled(ids.length, '?').join(',');
    final alertRows = await d.query(
      'alerts_cache',
      where: 'id IN ($placeholders)',
      whereArgs: ids,
    );

    // Preserve order from stored list
    final byId = {for (final r in alertRows) r['id'] as String: r};
    final list = <AlertModel>[];
    for (final id in ids) {
      final r = byId[id];
      if (r != null) {
        list.add(AlertModel.fromJson(jsonDecode(r['data'] as String)));
      }
    }
    return list;
  }

  /// Manually invalidate a region (e.g. after POST /alerts so user sees their new alert).
  static Future<void> invalidateRegion(LatLng center) async {
    final d = await db;
    await d.delete('region_cache', where: 'region_key = ?', whereArgs: [regionKey(center)]);
  }

  /// Drop all expired region entries and orphaned alert rows.
  /// Call periodically (e.g. on app start) to keep cache small.
  static Future<void> purgeExpired() async {
    final d = await db;
    final now = DateTime.now().millisecondsSinceEpoch;
    await d.delete('region_cache', where: 'expires_at < ?', whereArgs: [now]);
    // Drop alert rows older than 24h and not referenced by any live region.
    final cutoff = now - const Duration(hours: 24).inMilliseconds;
    await d.rawDelete(
      'DELETE FROM alerts_cache WHERE cached_at < ? AND id NOT IN (SELECT DISTINCT id FROM alerts_cache)',
      [cutoff],
    );
  }

  /// Diagnostic: how many regions are currently cached and when oldest expires.
  static Future<Map<String, dynamic>> stats() async {
    final d = await db;
    final regions = Sqflite.firstIntValue(
        await d.rawQuery('SELECT COUNT(*) FROM region_cache')) ?? 0;
    final alerts = Sqflite.firstIntValue(
        await d.rawQuery('SELECT COUNT(*) FROM alerts_cache')) ?? 0;
    return {'regions': regions, 'alerts': alerts};
  }
}
