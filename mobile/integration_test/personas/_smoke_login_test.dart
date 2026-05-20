/// Smoke test E2E: dla każdej persony loginujemy się i sprawdzamy że HomeScreen
/// jest osiągalna.
///
/// DIAGNOSTIC MODE: assertions nie failują testu - tylko logujemy metryki
/// do TestMetrics. Cel: zebrać baseline UX z prawdziwych telefonów.
///
/// Uruchomienie:
/// patrol test --target integration_test/personas/_smoke_login_test.dart \
///   --dart-define=TEST_RESET_SECRET=$(cat /tmp/test_reset_secret.txt) \
///   -d ZY32HKMT45
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'package:alertmap/main.dart' as app;

import '../helpers/fixture_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/metrics_helper.dart';
import '../helpers/screenshot_helper.dart';
import '../helpers/test_config.dart';

void main() {
  patrolTest('healthCheck: backend reachable', ($) async {
    final ok = await FixtureHelper.healthCheck();
    await TestMetrics.check(null, 'smoke', 'backend_healthcheck', ok,
        note: ok ? 'OK' : 'Backend nieosiągalny lub brak secretu');
    expect(ok, isTrue,
        reason:
            'Backend /test/health musi zwracać ok=true. Sprawdź TEST_RESET_SECRET.');
  });

  for (final persona in Persona.values) {
    patrolTest('smoke: ${persona.label} (${persona.username}) — TTI Home',
        ($) async {
      // Pre: reset fixtury
      final swReset = Stopwatch()..start();
      try {
        await FixtureHelper.resetPersona(persona);
        swReset.stop();
        await TestMetrics.duration(persona, 'smoke', 'fixture_reset', swReset.elapsed,
            budget: const Duration(seconds: 3));
      } catch (e) {
        swReset.stop();
        await TestMetrics.check(persona, 'smoke', 'fixture_reset', false,
            note: 'Wyjątek: $e');
        return; // bez resetu nie ma sensu kontynuować
      }

      // Cold start app
      final swStart = Stopwatch()..start();
      app.main();
      await $.pump(const Duration(seconds: 2));
      swStart.stop();
      await TestMetrics.duration(persona, 'smoke', 'app_warm_start', swStart.elapsed,
          budget: UxBudget.warmStart);

      // Login flow rozdzielony na 3 fazy dla dokładnej diagnozy:
      // 1. setup: onboarding skip + permissions + enterText (overhead testu, nie aplikacji)
      // 2. tap_to_home: faktyczny TTI od tap "Zaloguj" do widocznej Home (= TTI aplikacji)
      // 3. login_to_home: total (legacy metric dla porównania z poprzednim run)
      final swTotal = Stopwatch()..start();
      try {
        final setupDur = await LoginHelper.setupAndFillCredentials($, persona);
        await TestMetrics.duration(persona, 'smoke', 'login_setup', setupDur,
            note: 'Test overhead (skip+perms+enterText)');

        final tapToHome = await LoginHelper.tapLoginAndWaitForHome($);
        await TestMetrics.duration(persona, 'smoke', 'tap_to_home', tapToHome,
            budget: UxBudget.homeLoaded,
            note: 'Pure TTI: tap Zaloguj → Home visible');

        swTotal.stop();
        await TestMetrics.duration(persona, 'smoke', 'login_to_home', swTotal.elapsed,
            budget: UxBudget.homeLoaded,
            note: 'Legacy: setup + tap_to_home');
      } catch (e) {
        swTotal.stop();
        await TestMetrics.duration(persona, 'smoke', 'login_to_home', swTotal.elapsed,
            note: 'Login wyjątek: $e');
      }

      // Sprawdź czy HomeScreen pojawił się (PillNavBar z Mapą/Rodziną/SOS)
      final hasNav =
          $('Mapa').exists || $('Rodzina').exists || $('SOS').exists;
      await TestMetrics.check(persona, 'smoke', 'home_nav_visible', hasNav,
          note: hasNav ? null : 'Brak PillNavBar po loginie');

      // Screenshot baseline
      try {
        await ScreenshotHelper.take($, persona, 'home_after_login');
        await TestMetrics.note(persona, 'smoke', 'screenshot_home',
            note: 'OK home_after_login');
      } catch (e) {
        await TestMetrics.note(persona, 'smoke', 'screenshot_home',
            note: 'screenshot fail: $e');
      }
    });
  }

  // Po wszystkich testach: flush metryk do /sdcard
  patrolTest('zzz_flush_metrics', ($) async {
    final id = runIdOverride.isNotEmpty
        ? runIdOverride
        : 'smoke_${DateTime.now().millisecondsSinceEpoch}';
    await TestMetrics.flushAll(runId: id);
  });
}
