/// Diagnostic metrics collector — incremental POST per metric.
///
/// Każdy call duration/check/value/note natychmiast POST'uje do backendu
/// (fire-and-forget). Backend appenduje do /tmp/besafe_metrics/<runId>.json.
///
/// Powód: Patrol odpala każdy patrolTest w osobnym izolacie/procesie,
/// więc statyczne pole _store nie przeżywa między testami. Incremental
/// POST omija ten problem.
///
/// W diagnostic mode NIGDY nie failujemy testu - tylko logujemy.
library;

import 'dart:convert';

import 'package:http/http.dart' as http;

import 'test_config.dart';

class TestMetrics {
  static String get _runId =>
      runIdOverride.isNotEmpty ? runIdOverride : 'default';

  static Future<void> _send({
    required String suite,
    required Persona? persona,
    required Map<String, dynamic> entry,
  }) async {
    try {
      await http
          .post(
            Uri.parse('$apiBaseUrl/test/metrics'),
            headers: {
              'Content-Type': 'application/json',
              'X-Test-Secret': testResetSecret,
            },
            body: jsonEncode({
              'run_id': _runId,
              'persona': persona?.username ?? 'global',
              'suite': suite,
              'entry': {
                ...entry,
                'at': DateTime.now().toIso8601String(),
              },
            }),
          )
          .timeout(const Duration(seconds: 5));
    } catch (_) {
      // fire-and-forget; nie failuj testu
    }
  }

  /// Record a duration measurement (auto-passes/fails vs budget if provided).
  static Future<void> duration(
    Persona? persona,
    String suite,
    String name,
    Duration value, {
    Duration? budget,
    String? note,
  }) async {
    final passed = budget == null ? null : value <= budget;
    final flag = passed == null
        ? '📊'
        : passed
            ? '✅'
            : '⚠️';
    final budgetTxt =
        budget == null ? '' : ' (budżet ${budget.inMilliseconds}ms)';
    // ignore: avoid_print
    print('$flag [${persona?.username ?? "global"}] $suite/$name: '
        '${value.inMilliseconds}ms$budgetTxt${note != null ? " // $note" : ""}');
    await _send(suite: suite, persona: persona, entry: {
      'name': name,
      'unit': 'ms',
      'value': value.inMilliseconds,
      if (budget != null) 'budget_ms': budget.inMilliseconds,
      if (passed != null) 'passed': passed,
      if (note != null) 'note': note,
    });
  }

  /// Record a boolean check.
  static Future<void> check(
    Persona? persona,
    String suite,
    String name,
    bool ok, {
    String? note,
  }) async {
    final flag = ok ? '✅' : '❌';
    // ignore: avoid_print
    print('$flag [${persona?.username ?? "global"}] $suite/$name'
        '${note != null ? ": $note" : ""}');
    await _send(suite: suite, persona: persona, entry: {
      'name': name,
      'passed': ok,
      if (note != null) 'note': note,
    });
  }

  /// Record arbitrary numeric value (e.g. touch-target size in dp).
  static Future<void> value(
    Persona? persona,
    String suite,
    String name,
    num val,
    String unit, {
    String? note,
  }) async {
    // ignore: avoid_print
    print('📏 [${persona?.username ?? "global"}] $suite/$name: $val $unit'
        '${note != null ? " // $note" : ""}');
    await _send(suite: suite, persona: persona, entry: {
      'name': name,
      'unit': unit,
      'value': val,
      if (note != null) 'note': note,
    });
  }

  /// Note that something happened (no value).
  static Future<void> note(
    Persona? persona,
    String suite,
    String name, {
    required String note,
  }) async {
    // ignore: avoid_print
    print('📝 [${persona?.username ?? "global"}] $suite/$name: $note');
    await _send(suite: suite, persona: persona, entry: {
      'name': name,
      'note': note,
    });
  }

  /// Legacy no-op — incremental POST już zrobił robotę.
  static Future<void> flushAll({String runId = 'default'}) async {
    // ignore: avoid_print
    print('💾 metrics already sent incrementally; runId=$runId');
  }

  /// No-op (incremental mode).
  static void clear() {}
}
