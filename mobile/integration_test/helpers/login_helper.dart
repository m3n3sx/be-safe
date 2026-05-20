/// Pomocniki do logowania persony w testach Patrol.
///
/// UWAGA: be:Safe ma ciągłe animacje (GlowOrb, shimmer, SOS pulse) i
/// Socket.io reconnect → `pumpAndSettle` nigdy się nie kończy.
/// Wszędzie używamy `pump(Duration)` zamiast pumpAndSettle.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'test_config.dart';

class LoginHelper {
  /// Pump krótkimi krokami aż finder się pojawi lub timeout.
  static Future<bool> _waitFor(
    PatrolIntegrationTester $,
    PatrolFinder finder, {
    Duration timeout = const Duration(seconds: 8),
    Duration step = const Duration(milliseconds: 200),
  }) async {
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      if (finder.exists) return true;
      await $.pump(step);
    }
    return finder.exists;
  }

  /// Grant native permissions before app.main() (call once per test).
  static Future<void> grantPermissions(PatrolIntegrationTester $) async {
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (_) {}
    try {
      await $.native.selectFineLocation();
    } catch (_) {}
  }

  /// Pełny entry-flow z guard'ami: deleguje do `setupAndFillCredentials` +
  /// `tapLoginAndWaitForHome`. Jeśli auto-login już zalogowany — sanity-wait
  /// na "Mapa" i return.
  static Future<void> loginAs(PatrolIntegrationTester $, Persona persona) async {
    await setupAndFillCredentials($, persona);
    await tapLoginAndWaitForHome($);
  }

  /// Faza setup PRZED tapem Zaloguj (onboarding skip + permissions + enterText).
  /// Zwraca [Duration] = TTI samej fazy setup (tap-Zaloguj NIE wliczony).
  static Future<Duration> setupAndFillCredentials(
    PatrolIntegrationTester $,
    Persona persona,
  ) async {
    final sw = Stopwatch()..start();
    await $.pump(const Duration(seconds: 2));

    // Native permissions (location/notifications)
    try { await $.native.grantPermissionWhenInUse(); } catch (_) {}
    try { await $.native.grantPermissionWhenInUse(); } catch (_) {}

    // Onboarding skip
    for (var i = 0; i < 5; i++) {
      final s = $('Pomiń');
      if (!s.exists) break;
      await s.tap();
      await $.pump(const Duration(milliseconds: 500));
    }
    final rozpocznij = $('Rozpocznij');
    if (rozpocznij.exists) {
      await rozpocznij.tap();
      await $.pump(const Duration(seconds: 1));
    }

    // ModePickerScreen — pre-login pojawia się z allowSkip:false (main.dart:350),
    // brak "Pomiń wybór". Wybieramy "Standardowy" (NORMAL mode); backend
    // nadpisze app_mode z user.app_mode po loginie przez _AuthGate._handleAuth.
    final pomijModePick = $('Pomiń wybór — zdecyduję później');
    if (pomijModePick.exists) {
      await pomijModePick.tap();
      await $.pump(const Duration(seconds: 1));
    } else {
      // Fallback: pre-login flow. ModePicker (allowSkip:false) — tap
      // "Standardowy" card. Karta może być poza viewport (SingleChildScrollView),
      // więc najpierw scrollUntilVisible przez Scrollable, potem tap.
      final standardowyFinder = find.text('Standardowy');
      try {
        await $.tester.scrollUntilVisible(
          standardowyFinder,
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await $.pump(const Duration(milliseconds: 300));
      } catch (_) {}
      final standardowy = $('Standardowy');
      if (standardowy.exists) {
        // Tap na całą kartę — InkWell jest 2 poziomy wyżej (Material > InkWell
        // > Container > Row > Column > Text). Patrol tap na text powinno
        // bubble do nearest tappable, ale po scrollUntilVisible widget jest
        // hit-testable.
        await standardowy.tap();
        await $.pump(const Duration(seconds: 2));
      }
    }

    // BiometricLockScreen fallback (rzadkie w fresh installce)
    for (var i = 0; i < 3; i++) {
      final s = $('Pomiń');
      if (!s.exists) break;
      await s.tap();
      await $.pump(const Duration(milliseconds: 500));
    }

    // Auto-logout jeśli zalogowany. Wykrywamy: brak "Zaloguj się" + widoczne
    // "Mapa" / "Profil" / "Start" (Home navbar). Wówczas wylogowujemy
    // żeby zmierzyć pełny flow logowania.
    final zalogujBtn = $('Zaloguj się');
    final loggedIn = !zalogujBtn.exists &&
        ($('Mapa').exists ||
            $('Profil').exists ||
            $('Start').exists ||
            $('Rodzina').exists);
    if (loggedIn) {
      final profilTab = $('Profil');
      if (profilTab.exists) {
        await profilTab.tap();
        await $.pump(const Duration(seconds: 1));
        // przewiń do "Wyloguj się"
        try {
          await $.tester.dragUntilVisible(
            find.text('Wyloguj się'),
            find.byType(Scrollable).first,
            const Offset(0, -200),
          );
        } catch (_) {}
        final wylogujTile = $('Wyloguj się');
        if (wylogujTile.exists) {
          await wylogujTile.tap();
          await $.pump(const Duration(milliseconds: 500));
          final wyloguj = $('Wyloguj');
          if (wyloguj.exists) {
            await wyloguj.tap();
            await $.pump(const Duration(seconds: 2));
          }
        }
      }
    }

    // Czekaj na TextField. Jeśli się nie pojawi (auto-login → HomeScreen)
    // — wracamy z timem setup, fillu credentials nie ma.
    final emailVisible = await _waitFor(
      $,
      $(TextField).first,
      timeout: UxBudget.settle,
    );
    if (!emailVisible) {
      // Auto-login flow — TextField już nie istnieje, jesteśmy na HomeScreen.
      // Próbujemy poczekać na "Mapa" jako sanity check.
      await _waitFor($, $('Mapa'), timeout: UxBudget.homeLoaded);
      sw.stop();
      return sw.elapsed;
    }
    // Guard: sprawdź faktyczną liczbę TextField przed .at(1)
    final fields = $(TextField);
    final count = fields.evaluate().length;
    if (count < 2) {
      // LoginScreen w trybie register ma 4 fields, login 2. Jeśli widzimy <2,
      // próbujemy fall-back: może to tylko jeden TextField (search bar?)
      throw StateError('LoginScreen ma tylko $count TextField, oczekiwano ≥2');
    }
    final emailField = fields.at(0);
    final passField = fields.at(1);
    await emailField.enterText(persona.email);
    await $.pump(const Duration(milliseconds: 300));
    await passField.enterText(testPassword);
    await $.pump(const Duration(milliseconds: 300));

    sw.stop();
    return sw.elapsed;
  }

  /// Tap Zaloguj + czekanie aż Home (Mapa) widoczne.
  /// Zwraca [Duration] = pure TTI od tap do widocznego Home.
  static Future<Duration> tapLoginAndWaitForHome(
    PatrolIntegrationTester $,
  ) async {
    final sw = Stopwatch()..start();
    final loginBtn = $('Zaloguj się');
    if (!loginBtn.exists) {
      // Już zalogowany (auto-login) — pomiar to po prostu czas do Home.
      await _waitFor($, $('Mapa'), timeout: UxBudget.homeLoaded);
      sw.stop();
      return sw.elapsed;
    }
    await loginBtn.first.tap();
    // Wait dla 'Mapa' lub 'Home' (różne ekrany home zależne od app_mode)
    final mapaSeen = await _waitFor($, $('Mapa'), timeout: UxBudget.homeLoaded);
    if (!mapaSeen) {
      // Spróbuj 'Home' (alt dock label) lub czekaj dłużej.
      await _waitFor(
        $,
        $('Home'),
        timeout: const Duration(seconds: 5),
      );
    }
    sw.stop();
    return sw.elapsed;
  }
}
