/// P4 — Senior 68 lat (senior_jadwiga).
/// Specjalnie wolniejszy: budżety mają 1.5× narzut. Sprawdzamy:
/// 1. Czas dotarcia do SOS (LIFE-CRITICAL!).
/// 2. Czy etykiety zakładek są widoczne (PillNavBar bez ikon).
/// 3. Czy dialog wylogowania działa (UX 4 z audytu).
library;

import 'package:flutter/widgets.dart' show Scrollable;
import 'package:flutter_test/flutter_test.dart' show find;
import 'package:patrol/patrol.dart';

import 'package:alertmap/main.dart' as app;

import '../helpers/fixture_helper.dart';
import '../helpers/login_helper.dart';
import '../helpers/metrics_helper.dart';
import '../helpers/screenshot_helper.dart';
import '../helpers/test_config.dart';

void main() {
  const persona = Persona.seniorJadwiga;
  const suite = 'p4_senior';

  patrolTest('P4: senior — czas do SOS + etykiety navbar', ($) async {
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
      // dla seniora dajemy 1.5× budżet
      await TestMetrics.duration(persona, suite, 'login_to_home', sw.elapsed,
          budget: const Duration(seconds: 8));
    } catch (e) {
      sw.stop();
      await TestMetrics.check(persona, suite, 'login', false, note: '$e');
      return;
    }

    // Etykiety tekstowe muszą być widoczne (audyt UX #1)
    for (final tab in ['Mapa', 'Home', 'Rodzina', 'SOS', 'Profil']) {
      await TestMetrics.check(persona, suite, 'tab_label_visible_$tab', $(tab).exists,
          note: 'PillNavBar bez etykiet = anti-pattern dla 60+');
    }
    await ScreenshotHelper.take($, persona, 'p4_home');

    // KRYTYCZNE: czas dotarcia do SOS
    final swSos = Stopwatch()..start();
    if ($('SOS').exists) {
      await $('SOS').tap();
      await $.pump(const Duration(seconds: 2));
    }
    swSos.stop();
    await TestMetrics.duration(persona, suite, 'reach_sos', swSos.elapsed,
        budget: const Duration(seconds: 6),
        note: 'LIFE-CRITICAL: senior musi dojść do SOS w panice');
    final hasHoldLabel = $('Wciśnij i przytrzymaj').exists ||
        $('PRZYTRZYMAJ 2 SEKUNDY').exists;
    await TestMetrics.check(persona, suite, 'sos_hold_label_visible', hasHoldLabel,
        note: 'Widoczna instrukcja hold-to-fire');
    await ScreenshotHelper.take($, persona, 'p4_sos');

    // Profil → sprawdź dialog wylogowania (UX #4)
    if ($('Profil').exists) {
      await $('Profil').tap();
      await $.pump(const Duration(seconds: 2));
    }
    // Wyloguj się button może być poza viewport — scroll go do widoku.
    try {
      await $.tester.scrollUntilVisible(
        find.text('Wyloguj się'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await $.pump(const Duration(milliseconds: 300));
    } catch (_) {}
    await ScreenshotHelper.take($, persona, 'p4_profile');

    final hasLogout = $('Wyloguj się').exists;
    await TestMetrics.check(persona, suite, 'logout_visible', hasLogout);

    if (hasLogout) {
      await $('Wyloguj się').tap();
      await $.pump(const Duration(seconds: 1));
      // dialog powinien zawierać 'Anuluj' i 'Wyloguj' (audyt UX #4)
      final dialogOk =
          $('Anuluj').exists && ($('Wyloguj').exists || $('Wyloguj się').exists);
      await TestMetrics.check(persona, suite, 'logout_confirm_dialog', dialogOk,
          note: dialogOk
              ? 'Dialog wylogowania pokazuje się'
              : 'Brak dialogu — UX#4 nie wdrożone');
      await ScreenshotHelper.take($, persona, 'p4_logout_dialog');

      // Anuluj żeby nie wylogowywać
      if ($('Anuluj').exists) {
        await $('Anuluj').tap();
        await $.pump(const Duration(seconds: 1));
      }
    }
  });

  patrolTest('P4: flush', ($) async {
    final id = runIdOverride.isNotEmpty
        ? runIdOverride
        : 'p4_${DateTime.now().millisecondsSinceEpoch}';
    await TestMetrics.flushAll(runId: id);
  });
}
