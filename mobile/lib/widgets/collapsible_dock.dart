/// be:Safe — Global Dock (edge-to-edge, top-rounded)
///
/// Pasek nawigacji renderowany przez MaterialApp.builder, widoczny na każdym
/// ekranie po zalogowaniu (poza auth/onboarding/biometric/session-check).
///
/// Styl v87+: dock klei się do dolnej i bocznych krawędzi ekranu, zaokrąglone
/// tylko lewy i prawy GÓRNY narożnik (większość telefonów ma już zaokrąglone
/// rogi obudowy). Pełna szerokość, bez bocznych/dolnych marginesów.
///
/// Aktywny tab kontrolowany przez globalny `dockActiveIndex` (ValueNotifier),
/// który aktualizuje `navigateToTab()` w nav_routes.dart.
///
/// Visibility kontrolowane przez `dockVisible` (`ValueNotifier<bool>`),
/// ustawiane przez _AuthGate w main.dart.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/design_tokens.dart';
import 'nav_routes.dart';

/// Globalny notifier aktywnego tabu w docku. Domyślnie home (1).
final ValueNotifier<int> dockActiveIndex = ValueNotifier<int>(NavTabs.home);

/// Globalny notifier widoczności docka.
final ValueNotifier<bool> dockVisible = ValueNotifier<bool>(false);

/// No-op (kept for backwards compat z main.dart `await initDockState()`).
Future<void> initDockState() async {}

/// Wysokość samego paska (powyżej safe-area bottom).
const double _kBarHeight = 64;

/// Promień zaokrąglenia GÓRNYCH narożników docka.
/// Większy radius daje wyraźny "scoop"/wcięcie w dolnych rogach ekranu.
const double _kTopRadius = 44;

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
        // Dock zajmuje _kBarHeight + safe-area bottom (gesture/nav bar).
        final reserved = visible ? _kBarHeight + mq.padding.bottom : 0.0;
        return Stack(
          children: [
            // Child dostaje powiększone bottom padding tak, że content
            // mieści się NAD dockiem. Usuwamy też viewPadding.bottom żeby
            // SafeArea wewnątrz ekranów nie dodawała kolejnej rezerwacji.
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
                  // Material ancestor — żeby Text nie dostawał żółtego
                  // podkreślenia z DefaultTextStyle.
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
    return Container(
      // Pełna szerokość, brak bocznych marginesów.
      decoration: BoxDecoration(
        color: SerenityColors.primaryContainer,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(_kTopRadius),
          topRight: Radius.circular(_kTopRadius),
        ),
        boxShadow: SerenityElevation.nav(),
      ),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: _kBarHeight + mq.padding.bottom,
        child: Padding(
          // Dolny padding = gesture/nav bar, żeby ikony były nad nim.
          padding: EdgeInsets.only(bottom: mq.padding.bottom),
          child: ValueListenableBuilder<int>(
            valueListenable: dockActiveIndex,
            builder: (_, idx, __) => Row(
              children: [
                for (var i = 0; i < _kItems.length; i++)
                  Expanded(
                    child: _DockButton(
                      item: _kItems[i],
                      selected: i == idx,
                      onTap: () {
                        if (i == idx) {
                          HapticFeedback.selectionClick();
                          return;
                        }
                        navigateToTab(
                          context,
                          targetIndex: i,
                          currentIndex: idx,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DockItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _DockItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

const List<_DockItem> _kItems = [
  _DockItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Mapa'),
  _DockItem(icon: Icons.home_outlined, activeIcon: Icons.home, label: 'Home'),
  _DockItem(
    icon: Icons.family_restroom_outlined,
    activeIcon: Icons.family_restroom,
    label: 'Rodzina',
  ),
  _DockItem(icon: Icons.sos_outlined, activeIcon: Icons.sos, label: 'SOS'),
  _DockItem(
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

    return Semantics(
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
              Icon(
                selected ? item.activeIcon : item.icon,
                color: color,
                size: 24,
              ),
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
    );
  }
}
