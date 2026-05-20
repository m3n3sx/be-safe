/// P1 — Rodzic techniczny (parent_tech).
/// Pełny flow: zaloguj → przejdź przez wszystkie 5 zakładek → otwórz Profil →
/// otwórz Ustawienia → odczytaj wersję.
///
/// DIAGNOSTIC MODE — pomiary nie failują testu.
library;

import 'package:patrol/patrol.dart';

import 'package:alertmap/main.dart' as app;

import '../helpers/fixture_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/metrics_helper.dart';
import '../helpers/screenshot_helper.dart';
import '../helpers/test_config.dart';

void main() {
  const persona = Persona.parentTech;
  const suite = 'p1_parent_tech';

  patrolTest('P1: pełny tour 5 zakładek + Ustawienia', ($) async {
    try {
      await FixtureHelper.resetPersona(persona);
    } catch (e) {
      await TestMetrics.check(persona, suite, 'fixture_reset', false, note: '$e');
    }

    app.main();
    await $.pump(const Duration(seconds: 2));

    final swLogin = Stopwatch()..start();
    try {
      await LoginHelper.loginAs($, persona);
      swLogin.stop();
      await TestMetrics.duration(persona, suite, 'login_to_home', swLogin.elapsed,
          budget: UxBudget.homeLoaded);
    } catch (e) {
      swLogin.stop();
      await TestMetrics.check(persona, suite, 'login', false, note: '$e');
      return;
    }

    await ScreenshotHelper.take($, persona, 'p1_home');

    // Tour: Mapa
    final swMap = Stopwatch()..start();
    if ($('Mapa').exists) {
      await $('Mapa').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swMap.stop();
    await TestMetrics.duration(persona, suite, 'open_map', swMap.elapsed);
    await ScreenshotHelper.take($, persona, 'p1_map');

    // Rodzina
    final swFamily = Stopwatch()..start();
    if ($('Rodzina').exists) {
      await $('Rodzina').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swFamily.stop();
    await TestMetrics.duration(persona, suite, 'open_family', swFamily.elapsed);
    final hasGroup = $('Rodzina Testowa E2E').exists;
    await TestMetrics.check(persona, suite, 'family_group_visible', hasGroup,
        note: hasGroup ? 'Widoczna grupa E2E' : 'Brak grupy E2E na ekranie');
    await ScreenshotHelper.take($, persona, 'p1_family');

    // Home
    if ($('Home').exists) {
      await $('Home').tap();
      await $.pump(const Duration(seconds: 1));
    }
    await ScreenshotHelper.take($, persona, 'p1_home_tab');

    // SOS — pomiar czasu dotarcia
    final swSos = Stopwatch()..start();
    if ($('SOS').exists) {
      await $('SOS').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swSos.stop();
    await TestMetrics.duration(persona, suite, 'reach_sos', swSos.elapsed,
        budget: UxBudget.reachSos);
    await ScreenshotHelper.take($, persona, 'p1_sos');

    // Profil + Ustawienia
    final swProfile = Stopwatch()..start();
    if ($('Profil').exists) {
      await $('Profil').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swProfile.stop();
    await TestMetrics.duration(persona, suite, 'open_profile', swProfile.elapsed);
    await ScreenshotHelper.take($, persona, 'p1_profile');

    // Otwórz Ustawienia (próba przez tile lub ikonę koła zębatego)
    final swSettings = Stopwatch()..start();
    final settingsTile = $('Ustawienia');
    if (settingsTile.exists) {
      await settingsTile.tap();
      await $.pump(const Duration(seconds: 1));
    }
    swSettings.stop();
    await TestMetrics.duration(persona, suite, 'open_settings', swSettings.elapsed);
    await ScreenshotHelper.take($, persona, 'p1_settings');

    // Logout (sprawdza czy 'Wyloguj się' jest widoczne i klikalne)
    final hasLogout = $('Wyloguj się').exists;
    await TestMetrics.check(persona, suite, 'logout_available', hasLogout);
  });

  patrolTest('P1: flush', ($) async {
    final id = runIdOverride.isNotEmpty
        ? runIdOverride
        : 'p1_${DateTime.now().millisecondsSinceEpoch}';
    await TestMetrics.flushAll(runId: id);
  });
}
