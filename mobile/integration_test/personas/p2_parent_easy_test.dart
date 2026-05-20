/// P2 — Rodzic nietechniczny (parent_easy).
/// Skupiony na proste, podstawowe flow: zaloguj → spojrzy na Home → otworzy
/// Rodzinę → spojrzy gdzie jest SOS. Wszystko musi być widoczne BEZ przewijania.
library;

import 'package:patrol/patrol.dart';

import 'package:alertmap/main.dart' as app;

import '../helpers/fixture_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/metrics_helper.dart';
import '../helpers/screenshot_helper.dart';
import '../helpers/test_config.dart';

void main() {
  const persona = Persona.parentEasy;
  const suite = 'p2_parent_easy';

  patrolTest('P2: prosty flow widzialność navbar + rodzina', ($) async {
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

    // Wszystkie 5 zakładek widzialnych BEZ scrollowania?
    final tabs = {
      'Mapa': $('Mapa').exists,
      'Home': $('Home').exists,
      'Rodzina': $('Rodzina').exists,
      'SOS': $('SOS').exists,
      'Profil': $('Profil').exists,
    };
    for (final entry in tabs.entries) {
      await TestMetrics.check(persona, suite, 'tab_visible_${entry.key}', entry.value);
    }

    await ScreenshotHelper.take($, persona, 'p2_home');

    // Rodzina widoczność grupy + member tile
    final swFamily = Stopwatch()..start();
    if ($('Rodzina').exists) {
      await $('Rodzina').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swFamily.stop();
    await TestMetrics.duration(persona, suite, 'open_family', swFamily.elapsed);

    // Pump-loop: _loadGroups() w family_screen może zająć kilkanaście sekund.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (DateTime.now().isBefore(deadline) &&
        !$('Rodzina Testowa E2E').exists) {
      await $.pump(const Duration(milliseconds: 500));
    }
    final groupVisible = $('Rodzina Testowa E2E').exists;
    await TestMetrics.check(persona, suite, 'family_group_visible', groupVisible);
    await ScreenshotHelper.take($, persona, 'p2_family');

    // SOS widoczność dużego przycisku — sprawdzamy że ma tekst
    if ($('SOS').exists) {
      await $('SOS').tap();
      await $.pump(const Duration(seconds: 2));
    }
    final hasHoldLabel = $('Wciśnij i przytrzymaj').exists ||
        $('PRZYTRZYMAJ 2 SEKUNDY').exists;
    await TestMetrics.check(persona, suite, 'sos_hold_label_visible', hasHoldLabel);
    await ScreenshotHelper.take($, persona, 'p2_sos');
  });

  patrolTest('P2: flush', ($) async {
    final id = runIdOverride.isNotEmpty
        ? runIdOverride
        : 'p2_${DateTime.now().millisecondsSinceEpoch}';
    await TestMetrics.flushAll(runId: id);
  });
}
