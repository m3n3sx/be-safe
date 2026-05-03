import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/alert.dart';

class CacheService {
  static Database? _db;

  static Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await openDatabase(
      join(await getDatabasesPath(), 'alertmap_cache.db'),
      version: 1,
      onCreate: (db, _) => db.execute(
        'CREATE TABLE alerts_cache (id TEXT PRIMARY KEY, data TEXT, cached_at INTEGER)',
      ),
    );
    return _db!;
  }

  static Future<void> cacheAlerts(List<AlertModel> alerts) async {
    final d = await db;
    final batch = d.batch();
    batch.delete('alerts_cache');
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final a in alerts) {
      batch.insert('alerts_cache', {'id': a.id, 'data': jsonEncode(a.toJson()), 'cached_at': now}, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  static Future<List<AlertModel>> getCachedAlerts() async {
    final d = await db;
    final rows = await d.query('alerts_cache', orderBy: 'cached_at DESC');
    return rows.map((r) => AlertModel.fromJson(jsonDecode(r['data'] as String))).toList();
  }
}
