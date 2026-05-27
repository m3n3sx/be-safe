/// be:Safe — Global Dock (v96: 6 buttons, SVG icons from /design/dock.svg,
/// transparent Zgłoś with red circle)
///
/// Pasek nawigacji renderowany przez MaterialApp.builder, widoczny na każdym
/// ekranie po zalogowaniu (poza auth/onboarding/biometric/session-check).
///
/// Layout (od lewej): Home | Mapa | SOS | Zgłoś (czerwony) | Rodzina | Profil.
/// "Zgłoś" to równy przycisk w docku z czerwonym tłem — nie tab, otwiera
/// CreateAlertScreen.
///
/// Aktywny tab kontrolowany przez globalny `dockActiveIndex` (ValueNotifier),
/// który aktualizuje `navigateToTab()` w nav_routes.dart.
///
/// Visibility kontrolowane przez `dockVisible` (`ValueNotifier<bool>`),
/// ustawiane przez _AuthGate w main.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' show LatLng;
import 'package:provider/provider.dart';

import '../providers/alert_provider.dart';
import '../screens/alerts/create_alert_screen.dart';
import '../services/fcm_service.dart' show appNavigatorKey;
import '../theme/design_tokens.dart';
import 'nav_routes.dart';

/// Globalny notifier aktywnego tabu w docku. Domyślnie home (0).
final ValueNotifier<int> dockActiveIndex = ValueNotifier<int>(NavTabs.home);

/// Globalny notifier widoczności docka.
final ValueNotifier<bool> dockVisible = ValueNotifier<bool>(false);

/// No-op (kept for backwards compat z main.dart `await initDockState()`).
Future<void> initDockState() async {}

/// Wysokość samego paska (powyżej safe-area bottom).
const double _kBarHeight = 64;

/// Promień zaokrąglenia wszystkich 4 narożników docka.
const double _kRadius = 22;

/// Delikatne odstępy docka od krawędzi ekranu.
const double _kSideMargin = 8;
const double _kBottomMargin = 6;

/// Wrapper do owinięcia child z MaterialApp.builder.
class GlobalDockOverlay extends StatelessWidget {
  final Widget child;
  const GlobalDockOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: dockVisible,
      builder: (_, visible, __) {
        final mq = MediaQuery.of(context);
        final reserved =
            visible ? _kBarHeight + mq.padding.bottom + _kBottomMargin : 0.0;
        return Stack(
          children: [
            MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: reserved),
                viewPadding: mq.viewPadding.copyWith(bottom: reserved),
              ),
              child: child,
            ),
            if (visible)
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  type: MaterialType.transparency,
                  child: _EdgeDock(),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _EdgeDock extends StatelessWidget {
  const _EdgeDock();

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        _kSideMargin,
        0,
        _kSideMargin,
        mq.padding.bottom + _kBottomMargin,
      ),
      child: Container(
        height: _kBarHeight,
        decoration: BoxDecoration(
          color: SerenityColors.primaryContainer,
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: SerenityElevation.nav(),
        ),
        clipBehavior: Clip.antiAlias,
        child: ValueListenableBuilder<int>(
          valueListenable: dockActiveIndex,
          builder: (_, idx, __) => Row(
            children: [
              _DockButton(
                item: _kItems[0], // Home
                selected: idx == NavTabs.home,
                onTap: () => _onTabTap(context, NavTabs.home, idx),
              ),
              _DockButton(
                item: _kItems[1], // Mapa
                selected: idx == NavTabs.map,
                onTap: () => _onTabTap(context, NavTabs.map, idx),
              ),
              _DockButton(
                item: _kItems[2], // SOS
                selected: idx == NavTabs.sos,
                onTap: () => _onTabTap(context, NavTabs.sos, idx),
              ),
              _ReportButton(onTap: () => _openCreateAlert(context)),
              _DockButton(
                item: _kItems[3], // Rodzina
                selected: idx == NavTabs.family,
                onTap: () => _onTabTap(context, NavTabs.family, idx),
              ),
              _DockButton(
                item: _kItems[4], // Profil
                selected: idx == NavTabs.profile,
                onTap: () => _onTabTap(context, NavTabs.profile, idx),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTabTap(BuildContext context, int target, int current) {
    if (target == current) {
      HapticFeedback.selectionClick();
      return;
    }
    navigateToTab(context, targetIndex: target, currentIndex: current);
  }

  Future<void> _openCreateAlert(BuildContext context) async {
    HapticFeedback.mediumImpact();
    final navState = appNavigatorKey.currentState;
    final navCtx = appNavigatorKey.currentContext;
    if (navState == null) return;

    // Pobierz pozycję: świeża GPS → fallback cache alertów → Warszawa.
    LatLng? pos;
    try {
      final perm = await Geolocator.checkPermission();
      if (perm != LocationPermission.denied &&
          perm != LocationPermission.deniedForever) {
        final p = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
          timeLimit: const Duration(seconds: 5),
        );
        pos = LatLng(p.latitude, p.longitude);
      }
    } catch (_) {}

    if (pos == null && navCtx != null) {
      try {
        final alerts = navCtx.read<AlertProvider>().allAlerts;
        if (alerts.isNotEmpty) pos = alerts.first.location;
      } catch (_) {}
    }
    pos ??= const LatLng(52.2297, 21.0122); // Warsaw fallback

    await navState.push(
      MaterialPageRoute(
        builder: (_) => CreateAlertScreen(position: pos!),
      ),
    );
  }
}

class _DockItem {
  /// SVG asset path; null oznacza fallback do `icon` (Material) — używamy
  /// dla SOS, który zachowuje obecny wygląd.
  final String? svg;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _DockItem({
    this.svg,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

/// Kolejność tabów (5): Home, Mapa, SOS, Rodzina, Profil.
/// "Zgłoś" jako 6-ty przycisk renderowany osobno (czerwony, nie tab).
/// Ikony Home/Mapa/Rodzina/Profil z /design/dock.svg (user feedback v96).
const List<_DockItem> _kItems = [
  _DockItem(
    svg: 'assets/icons/dock/home.svg',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  _DockItem(
    svg: 'assets/icons/dock/map.svg',
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    label: 'Mapa',
  ),
  _DockItem(
    icon: Icons.sos_outlined,
    activeIcon: Icons.sos,
    label: 'SOS',
  ),
  _DockItem(
    svg: 'assets/icons/dock/family.svg',
    icon: Icons.family_restroom_outlined,
    activeIcon: Icons.family_restroom,
    label: 'Rodzina',
  ),
  _DockItem(
    svg: 'assets/icons/dock/profile.svg',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profil',
  ),
];

class _DockButton extends StatelessWidget {
  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DockButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SerenityColors.onPrimary
        : SerenityColors.onPrimary.withValues(alpha: 0.55);

    final Widget iconWidget = item.svg != null
        ? SvgPicture.asset(
            item.svg!,
            width: 24,
            height: 24,
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          )
        : Icon(
            selected ? item.activeIcon : item.icon,
            color: color,
            size: 24,
          );

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          splashColor: SerenityColors.onPrimary.withValues(alpha: 0.08),
          highlightColor: SerenityColors.onPrimary.withValues(alpha: 0.04),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                SizedBox(height: 24, width: 24, child: iconWidget),
                const SizedBox(height: 4),
                Text(
                  item.label,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.visible,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// "Zgłoś" — przezroczyste tło (jak inne taby), CZERWONE kółko 24px
/// (#FF1D25) z białym obramowaniem 2px i białym plusem w środku.
/// Etykieta "Zgłoś" biała jak inne. Otwiera CreateAlertScreen.
class _ReportButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ReportButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF1D25);
    return Expanded(
      child: Semantics(
        button: true,
        label: 'Zgłoś alert',
        child: InkWell(
          onTap: onTap,
          splashColor: SerenityColors.onPrimary.withValues(alpha: 0.08),
          highlightColor: SerenityColors.onPrimary.withValues(alpha: 0.04),
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.max,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: red,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(
                    Icons.add,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Zgłoś',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.2,
                    height: 1.1,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
