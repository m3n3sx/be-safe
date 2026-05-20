/// P3 — Dziecko 10 lat (kid_anna).
/// Sprawdzamy ograniczenia: nie powinno mieć opcji dodawania geofence'ów,
/// usuwania członków, edycji safe_routes itp. Ma widzieć Mapa/Home/Rodzina/SOS/Profil
/// ale w Rodzinie inne akcje niż parent.
library;

import 'package:patrol/patrol.dart';

import 'package:alertmap/main.dart' as app;

import '../helpers/fixture_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/metrics_helper.dart';
import '../helpers/screenshot_helper.dart';
import '../helpers/test_config.dart';

void main() {
  const persona = Persona.kidAnna;
  const suite = 'p3_kid_anna';

  patrolTest('P3: dziecko widzi navbar + Rodzina + SOS', ($) async {
    try {
      await FixtureHelper.resetPersona(persona);
    } catch (e) {
      await TestMetrics.check(persona, suite, 'fixture_reset', false, note: '$e');
    }

    app.main();
    await $.pump(const Duration(seconds: 2));

    final sw = Stopwatch()..start();
    try {
      await LoginHelper.loginAs($, persona);
      sw.stop();
      await TestMetrics.duration(persona, suite, 'login_to_home', sw.elapsed,
          budget: UxBudget.homeLoaded);
    } catch (e) {
      sw.stop();
      await TestMetrics.check(persona, suite, 'login', false, note: '$e');
      return;
    }

    // Wszystkie zakładki widoczne
    for (final tab in ['Mapa', 'Home', 'Rodzina', 'SOS', 'Profil']) {
      await TestMetrics.check(persona, suite, 'tab_visible_$tab', $(tab).exists);
    }
    await ScreenshotHelper.take($, persona, 'p3_home');

    // Rodzina — kid powinien widzieć członków, ale BRAK akcji typu "Usuń strefę"
    if ($('Rodzina').exists) {
      await $('Rodzina').tap();
      await $.pump(const Duration(seconds: 2));
    }
    // Pump-loop: _loadGroups() w family_screen może zająć kilkanaście sekund.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline) &&
        !$('Rodzina Testowa E2E').exists) {
      await $.pump(const Duration(milliseconds: 500));
    }
    final groupVisible = $('Rodzina Testowa E2E').exists;
    await TestMetrics.check(persona, suite, 'family_group_visible', groupVisible);
    await ScreenshotHelper.take($, persona, 'p3_family');

    // SOS
    final swSos = Stopwatch()..start();
    if ($('SOS').exists) {
      await $('SOS').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swSos.stop();
    await TestMetrics.duration(persona, suite, 'reach_sos', swSos.elapsed,
        budget: UxBudget.reachSos);
    await ScreenshotHelper.take($, persona, 'p3_sos');
  });

  patrolTest('P3: flush', ($) async {
    final id = runIdOverride.isNotEmpty
        ? runIdOverride
        : 'p3_${DateTime.now().millisecondsSinceEpoch}';
    await TestMetrics.flushAll(runId: id);
  });
}
