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

  /// Pełny entry-flow:
  /// 1. Jeśli OnboardingScreen widoczny → tap "Pomiń"
  /// 2. Jeśli HomeScreen widoczny → tap "Wyloguj" (najpierw przez profil)
  /// 3. Logowanie email + hasło + "Zaloguj się"
  static Future<void> loginAs(PatrolIntegrationTester $, Persona persona) async {
    // Warm-up: kilka pumpów żeby app się załadowała
    await $.pump(const Duration(seconds: 2));

    // Native permissions (location/notifications) jeśli pojawi się dialog
    try {
      await $.native.grantPermissionWhenInUse();
    } catch (_) {}
    try {
      await $.native.grantPermissionWhenInUse(); // FCM notification permission
    } catch (_) {}

    // Krok 1: onboarding skip (max 5 ekranów)
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

    // Krok 1b: ModePickerScreen — pojawia się po onboardingu dla nowych instalek.
    // Tap "Pomiń wybór — zdecyduję później" żeby pominąć (default to normal mode).
    final pomijModePick = $('Pomiń wybór — zdecyduję później');
    if (pomijModePick.exists) {
      await pomijModePick.tap();
      await $.pump(const Duration(seconds: 1));
    }

    // Krok 1c: BiometricLockScreen — jeśli włączona biometria, użytkownik musi
    // odblokować. W testach nie ma realnej autentykacji, więc szukamy "Pomiń"
    // albo "Użyj hasła" jako fallback. Najczęściej w fresh installce nie ma.
    for (var i = 0; i < 3; i++) {
      final s = $('Pomiń');
      if (!s.exists) break;
      await s.tap();
      await $.pump(const Duration(milliseconds: 500));
    }

    // Krok 2: jeśli zalogowany → wyloguj przez Profil
    final zalogujBtn = $('Zaloguj się');
    if (!zalogujBtn.exists) {
      final profilTab = $('Profil');
      if (profilTab.exists) {
        await profilTab.tap();
        await $.pump(const Duration(seconds: 1));
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

    // Krok 3: LoginScreen — wpisz dane
    // Czekaj na pojawienie się pola email
    await _waitFor($, $(TextField).first, timeout: UxBudget.warmStart);

    final emailField = $(TextField).at(0);
    final passField = $(TextField).at(1);
    await emailField.enterText(persona.email);
    await $.pump(const Duration(milliseconds: 300));
    await passField.enterText(testPassword);
    await $.pump(const Duration(milliseconds: 300));

    final loginBtn = $('Zaloguj się');
    if (loginBtn.exists) {
      await loginBtn.first.tap();
    }
    // Po loginie czekaj aż pojawi się "Mapa" lub "Rodzina" (Home navbar)
    await _waitFor($, $('Mapa'), timeout: UxBudget.homeLoaded);
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

    // ModePickerScreen — pomiń (nowe instalki)
    final pomijModePick = $('Pomiń wybór — zdecyduję później');
    if (pomijModePick.exists) {
      await pomijModePick.tap();
      await $.pump(const Duration(seconds: 1));
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
    final emailField = $(TextField).at(0);
    final passField = $(TextField).at(1);
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
    await _waitFor($, $('Mapa'), timeout: UxBudget.homeLoaded);
    sw.stop();
    return sw.elapsed;
  }
}
