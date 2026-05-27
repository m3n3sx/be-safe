/// Unified navigation helper for the 5-tab dock across the app.
///
/// Tab indexes (v94+ new order with center Zgłoś FAB):
///   0 = Home
///   1 = Mapa
///   2 = SOS
///   3 = Rodzina
///   4 = Profil
///
/// Center FAB "Zgłoś" is a non-tab action that opens CreateAlertScreen.
///
/// Use [navigateToTab] from any screen with [PillNavBar] to switch tabs
/// in a consistent way (no stack-pop tricks, always reach the destination).

library;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/user.dart' show AppMode;
import '../providers/mode_provider.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/home_kids_screen.dart';
import '../screens/home/home_senior_screen.dart';
import '../screens/map/map_screen.dart';
import '../screens/family/family_screen.dart';
import '../screens/sos/sos_screen.dart';
import '../screens/sos/sos_kids_screen.dart';
import '../screens/sos/sos_senior_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../services/fcm_service.dart' show appNavigatorKey;
import 'collapsible_dock.dart' show dockActiveIndex;

/// The canonical 5-tab order used by [PillNavBar.defaultItems].
class NavTabs {
  static const int home = 0;
  static const int map = 1;
  static const int sos = 2;
  static const int family = 3;
  static const int profile = 4;
}

/// Navigate to a top-level tab by index from anywhere in the app.
///
/// - If [currentIndex] matches [targetIndex] the call is a no-op (with haptic).
/// - Uses `pushReplacement` for first-level tabs to avoid an ever-growing stack.
/// - Always provides haptic feedback for tactile confirmation.
void navigateToTab(
  BuildContext context, {
  required int targetIndex,
  required int currentIndex,
}) {
  if (targetIndex == currentIndex) return;
  HapticFeedback.selectionClick();

  // Aktualizuj globalny indeks docka — także gdy navigacja wychodzi
  // z ekranu bez własnego PillNavBar (sub-screen typu Settings).
  dockActiveIndex.value = targetIndex;

  // F33: routing per app_mode dla Home + SOS.
  // Globalny dock w MaterialApp.builder przekazuje swój własny context, który
  // bywa POZA Navigatorem MaterialApp — dlatego pchamy przez `appNavigatorKey`.
  // ModeProvider jest dostarczany WYŻEJ niż MaterialApp, więc context.read działa.
  final navigatorState = appNavigatorKey.currentState;
  if (navigatorState == null) return;
  final mode = context.read<ModeProvider>().mode;

  Widget destination;
  switch (targetIndex) {
    case NavTabs.map:
      destination = const MapScreen();
      break;
    case NavTabs.home:
      switch (mode) {
        case AppMode.kids:
          destination = const HomeKidsScreen();
          break;
        case AppMode.senior:
          destination = const HomeSeniorScreen();
          break;
        case AppMode.normal:
          destination = const HomeScreen();
          break;
      }
      break;
    case NavTabs.family:
      destination = const FamilyScreen();
      break;
    case NavTabs.sos:
      switch (mode) {
        case AppMode.kids:
          destination = const SosKidsScreen();
          break;
        case AppMode.senior:
          destination = const SosSeniorScreen();
          break;
        case AppMode.normal:
          destination = const SosScreen();
          break;
      }
      break;
    case NavTabs.profile:
      destination = const ProfileScreen();
      break;
    default:
      return;
  }

  navigatorState.pushReplacement(
    PageRouteBuilder(
      pageBuilder: (_, __, ___) => destination,
      transitionDuration: const Duration(milliseconds: 180),
      reverseTransitionDuration: const Duration(milliseconds: 120),
      transitionsBuilder: (_, animation, __, child) =>
          FadeTransition(opacity: animation, child: child),
    ),
  );
}
