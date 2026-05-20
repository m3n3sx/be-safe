/// Wywołuje admin endpointy /api/v1/test/* przed/po każdym scenariuszu.
/// Wymaga `--dart-define=TEST_RESET_SECRET=<sekret>` przy starcie testów.
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'test_config.dart';

class FixtureHelper {
  /// Resetuje stan jednej persony (alerty/votes/notif/historia/checkins/fcm_token).
  /// Nie usuwa konta ani grup.
  static Future<void> resetPersona(Persona p) async {
    if (testResetSecret.isEmpty) {
      throw StateError(
        'TEST_RESET_SECRET nieustawione — uruchom przez '
        '--dart-define=TEST_RESET_SECRET=<sekret>',
      );
    }
    final r = await http
        .post(
          Uri.parse('$apiBaseUrl/test/reset-persona'),
          headers: {
            'Content-Type': 'application/json',
            'X-Test-Secret': testResetSecret,
          },
          body: jsonEncode({'username': p.username}),
        )
        .timeout(const Duration(seconds: 10));
    if (r.statusCode != 200) {
      throw StateError('resetPersona ${p.username} failed: '
          '${r.statusCode} ${r.body}');
    }
  }

  /// Resetuje wszystkie persony jednym strzałem.
  static Future<void> resetAll() async {
    if (testResetSecret.isEmpty) return;
    await http
        .post(
          Uri.parse('$apiBaseUrl/test/reset-all'),
          headers: {
            'Content-Type': 'application/json',
            'X-Test-Secret': testResetSecret,
          },
        )
        .timeout(const Duration(seconds: 15));
  }

  /// Sanity-check: czy backend jest live i secret skonfigurowany.
  static Future<bool> healthCheck() async {
    try {
      final r = await http
          .get(Uri.parse('$apiBaseUrl/test/health'))
          .timeout(const Duration(seconds: 5));
      if (r.statusCode != 200) return false;
      final body = jsonDecode(r.body) as Map<String, dynamic>;
      return body['ok'] == true && body['secret_configured'] == true;
    } catch (_) {
      return false;
    }
  }
}
