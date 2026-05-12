/// be:Safe v2 — Pill Navigation Bar
///
/// Floating glassmorphic dark-navy pill that hovers at the bottom of the screen.
/// Icons are monolinear white, active state = filled icon + pulsing dot below.
///
/// Usage:
///   Scaffold(
///     bottomNavigationBar: SizedBox.shrink(),  // disable default
///     body: Stack(
///       children: [
///         YourContent(),
///         Positioned(
///           left: 24, right: 24, bottom: 24,
///           child: PillNavBar(
///             currentIndex: 0,
///             onTap: (i) => ...,
///           ),
///         ),
///       ],
///     ),
///   )

library;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

class PillNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<PillNavItem> items;

  /// Whether to apply glassmorphism (backdrop blur). Default true.
  /// Set false for an opaque variant if backdrop becomes distracting.
  final bool glassmorphic;

  const PillNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items = defaultItems,
    this.glassmorphic = true,
  });

  static const List<PillNavItem> defaultItems = [
    PillNavItem(icon: Icons.map_outlined, activeIcon: Icons.map, label: 'Mapa'),
    PillNavItem(
      icon: Icons.notifications_none,
      activeIcon: Icons.notifications_active,
      label: 'Alerty',
    ),
    PillNavItem(
      icon: Icons.family_restroom_outlined,
      activeIcon: Icons.family_restroom,
      label: 'Rodzina',
    ),
    PillNavItem(
      icon: Icons.person_outline,
      activeIcon: Icons.person,
      label: 'Profil',
    ),
    PillNavItem(icon: Icons.sos_outlined, activeIcon: Icons.sos, label: 'SOS'),
  ];

  @override
  Widget build(BuildContext context) {
    final bar = Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: glassmorphic
            ? SerenityColors.primaryContainer.withValues(alpha: 0.9)
            : SerenityColors.primaryContainer,
        borderRadius: SerenityShapes.pill(),
        boxShadow: SerenityElevation.nav(),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          for (var i = 0; i < items.length; i++)
            _NavIcon(
              item: items[i],
              selected: i == currentIndex,
              onTap: () => onTap(i),
            ),
        ],
      ),
    );

    if (!glassmorphic) return bar;

    return ClipRRect(
      borderRadius: SerenityShapes.pill(),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: bar,
      ),
    );
  }
}

class PillNavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const PillNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
}

class _NavIcon extends StatelessWidget {
  final PillNavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _NavIcon({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? SerenityColors.onPrimary
        : SerenityColors.onPrimary.withValues(alpha: 0.5);

    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        splashColor: SerenityColors.onPrimary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: AnimatedScale(
          scale: selected ? 1.0 : 0.95,
          duration: SerenityAnim.tap,
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(selected ? item.activeIcon : item.icon, color: color, size: 26),
              const SizedBox(height: 4),
              AnimatedContainer(
                duration: SerenityAnim.tap,
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  color: selected
                      ? SerenityColors.onPrimary
                      : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
