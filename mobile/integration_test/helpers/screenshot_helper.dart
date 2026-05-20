/// Pomocnik do zrzutów ekranu w testach Patrol.
///
/// Zapisuje do reports/screenshots/[persona]/[test_name]__[step].png
/// na hoście (przez integration_test bridge → flutter drive).
library;

import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

class ScreenshotHelper {
  /// Zapisuje zrzut z nazwą `<persona>__<step>`. Bezpiecznie pomija jeśli
  /// binding niedostępny (np. uruchamiane bez integration_test).
  static Future<void> take(PatrolIntegrationTester $, Persona persona, String step) async {
    final name = '${persona.name}__$step';
    try {
      final binding = IntegrationTestWidgetsFlutterBinding.instance;
      await binding.takeScreenshot(name);
    } catch (_) {
      // binding niedostępny lub screenshot bug — ignoruj, nie failuj testu
    }
  }
}
