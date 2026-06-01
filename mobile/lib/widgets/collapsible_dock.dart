/// be:Safe v100 — Global Dock + global "Zgłoś" FAB (Figma redesign)
///
/// Source: Figma file V7gYh6uA0axopciUTSn4Ib node 2050:51 (user m2445).
///
/// Dock = black pill (368×64, radius 62) holding 5 items:
///   Mapa | Home | Rodzina | SOS | Profil
///
/// Active item rendered as a mint pill (#A0FF3B, 68×52 radius 27pt) with
/// the icon in pure black; inactive items are white outline icons.
/// SOS is a text glyph ("SOS", Medula One 32pt → falls back to system bold
/// condensed when the font is missing) instead of a Material icon.
///
/// "Zgłoś" no longer lives inside the dock (user m2445: "przycisk zgłoś
/// jedna jako osobny a nie w docku"). It is rendered as a circular red FAB
/// just above the dock, on every logged-in screen.
///
/// Visibility kontrolowane przez `dockVisible` (`ValueNotifier<bool>`),
/// active tab przez `dockActiveIndex` (updated by `navigateToTab` in
/// nav_routes.dart).
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
const double _kRadius = 62;

/// Delikatne odstępy docka od krawędzi ekranu.
const double _kSideMargin = 11;
const double _kBottomMargin = 6;

/// FAB "Zgłoś" — rozmiary + pozycja względem docka.
const double _kFabSize = 56;
const double _kFabGap = 12; // odstęp FAB od górnej krawędzi docka

/// Łączna wysokość zarezerwowanego dolnego paska (dock + FAB lift).
double _reservedBottom(MediaQueryData mq) =>
    _kBarHeight + _kFabSize / 2 + _kFabGap + mq.padding.bottom + _kBottomMargin;

/// Public: ile pikseli zarezerwowane jest na dolny dock (bar + FAB unoszenie
/// + bezpieczna strefa systemowa). Bottom sheets/dialogi/scrollery muszą to
/// dodać do swojego paddingu, inaczej dock zasłoni przyciski w stopce
/// (np. "Zapisz" w sheetach Profilu).
double kDockReservedHeight(BuildContext context) {
  if (!dockVisible.value) return 0;
  return _reservedBottom(MediaQuery.of(context));
}

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
        final reserved = visible ? _reservedBottom(mq) : 0.0;
        return Stack(
          children: [
            MediaQuery(
              data: mq.copyWith(
                padding: mq.padding.copyWith(bottom: reserved),
                viewPadding: mq.viewPadding.copyWith(bottom: reserved),
              ),
              child: child,
            ),
            if (visible) ...[
              const Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Material(
                  type: MaterialType.transparency,
                  child: _DockBar(),
                ),
              ),
              // FAB unosi się nad dockiem, prawy róg.
              Positioned(
                right: 16,
                bottom: _kBarHeight + _kBottomMargin + _kFabGap +
                    mq.padding.bottom,
                child: const Material(
                  type: MaterialType.transparency,
                  child: _ReportFab(),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DockBar extends StatelessWidget {
  const _DockBar();

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
          color: const Color(0xFF000000), // czarny pill
          borderRadius: BorderRadius.circular(_kRadius),
          boxShadow: SerenityElevation.nav(),
        ),
        clipBehavior: Clip.antiAlias,
        child: ValueListenableBuilder<int>(
          valueListenable: dockActiveIndex,
          builder: (_, idx, __) => Row(
            children: [
              _DockSlot(
                item: _kItems[0], // Mapa
                selected: idx == NavTabs.map,
                onTap: () => _onTabTap(context, NavTabs.map, idx),
              ),
              _DockSlot(
                item: _kItems[1], // Home
                selected: idx == NavTabs.home,
                onTap: () => _onTabTap(context, NavTabs.home, idx),
              ),
              _DockSlot(
                item: _kItems[2], // Rodzina
                selected: idx == NavTabs.family,
                onTap: () => _onTabTap(context, NavTabs.family, idx),
              ),
              _DockSlot(
                item: _kItems[3], // SOS (text glyph)
                selected: idx == NavTabs.sos,
                onTap: () => _onTabTap(context, NavTabs.sos, idx),
              ),
              _DockSlot(
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
}

class _DockItem {
  /// SVG asset path; null → fall back to material `icon`/`activeIcon`.
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

/// Kolejność dock per Figma (V7gYh6uA0axopciUTSn4Ib node 2050:51):
/// Mapa | Home | Rodzina | SOS | Profil.
/// SOS render text "SOS" (Medula One), pozostałe — SVG outline ikony.
const List<_DockItem> _kItems = [
  _DockItem(
    svg: 'assets/icons/dock/map.svg',
    icon: Icons.map_outlined,
    activeIcon: Icons.map,
    label: 'Mapa',
  ),
  _DockItem(
    svg: 'assets/icons/dock/home.svg',
    icon: Icons.home_outlined,
    activeIcon: Icons.home,
    label: 'Home',
  ),
  _DockItem(
    svg: 'assets/icons/dock/family.svg',
    icon: Icons.family_restroom_outlined,
    activeIcon: Icons.family_restroom,
    label: 'Rodzina',
  ),
  // v103: back to Icons.sos (v95 style). User m2517: "w docku przycisk sos
  // zmień czcionkę na taką jaka była w v95".
  _DockItem(
    icon: Icons.sos_outlined,
    activeIcon: Icons.sos,
    label: 'SOS',
  ),
  _DockItem(
    svg: 'assets/icons/dock/profile.svg',
    icon: Icons.person_outline,
    activeIcon: Icons.person,
    label: 'Profil',
  ),
];

/// Active mint pill color (Figma node 2050:50, fill #A0FF3B).
const Color _kActivePillColor = Color(0xFFA0FF3B);

/// Active pill dimensions inside the 64h dock.
const double _kPillW = 68;
const double _kPillH = 52;
const double _kPillRadius = 27;

class _DockSlot extends StatelessWidget {
  final _DockItem item;
  final bool selected;
  final VoidCallback onTap;

  const _DockSlot({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final iconColor = selected ? Colors.black : Colors.white;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: InkWell(
          onTap: onTap,
          splashColor: Colors.white.withValues(alpha: 0.08),
          highlightColor: Colors.white.withValues(alpha: 0.04),
          child: SizedBox.expand(
            child: Center(
              child: selected
                  ? Container(
                      width: _kPillW,
                      height: _kPillH,
                      decoration: BoxDecoration(
                        color: _kActivePillColor,
                        borderRadius: BorderRadius.circular(_kPillRadius),
                      ),
                      alignment: Alignment.center,
                      child: _slotGlyph(iconColor),
                    )
                  : _slotGlyph(iconColor),
            ),
          ),
        ),
      ),
    );
  }

  Widget _slotGlyph(Color color) {
    if (item.svg != null) {
      return SvgPicture.asset(
        item.svg!,
        width: 24,
        height: 24,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      );
    }
    return Icon(
      selected ? item.activeIcon : item.icon,
      color: color,
      size: 24,
    );
  }
}

/// "Zgłoś" — globalny okrągły czerwony FAB, NIE w docku.
/// User m2445: "przycisk zgłoś jedna jako osobny a nie w docku".
class _ReportFab extends StatelessWidget {
  const _ReportFab();

  @override
  Widget build(BuildContext context) {
    const red = Color(0xFFFF4848); // Figma node 2050:33 fill #FF4848
    return Semantics(
      button: true,
      label: 'Zgłoś alert',
      child: Material(
        color: red,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: red.withValues(alpha: 0.5),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _openCreateAlert(context),
          splashColor: Colors.white.withValues(alpha: 0.18),
          highlightColor: Colors.white.withValues(alpha: 0.08),
          child: const SizedBox(
            width: _kFabSize,
            height: _kFabSize,
            child: Icon(
              Icons.add,
              color: Colors.white,
              size: 28,
            ),
          ),
        ),
      ),
    );
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
