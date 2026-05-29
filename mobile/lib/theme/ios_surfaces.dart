/// be:Safe v98 — iOS surface tokens with light/dark awareness.
///
/// Replaces direct usage of `SerenityColors.groupedBackground` /
/// `SerenityColors.groupedSurface` / `separator` / `secondaryLabel` in
/// widgets and screens so dark-mode flips them automatically.
///
/// Usage:
///   Container(color: context.iosBackground);
///   Text('hi', style: TextStyle(color: context.iosSecondaryLabel));

library;

import 'package:flutter/material.dart';
import 'design_tokens.dart';

extension IosSurfaceTokens on BuildContext {
  bool get _isDark => Theme.of(this).brightness == Brightness.dark;

  /// iOS systemGroupedBackground — page bg behind cards.
  Color get iosBackground => _isDark
      ? SerenityColors.groupedBackgroundDark
      : SerenityColors.groupedBackground;

  /// iOS systemBackground — solid card surface (white in light).
  Color get iosCardSurface => _isDark
      ? SerenityColors.groupedSurfaceDark
      : SerenityColors.groupedSurface;

  /// Elevated container surface — chip / pill / row hover bg.
  Color get iosCardSurfaceHigh => _isDark
      ? SerenityColors.groupedSurfaceHighDark
      : SerenityColors.surfaceContainerHigh;

  /// 1pt hairline on cards.
  Color get iosSeparator =>
      _isDark ? SerenityColors.separatorDark : SerenityColors.separator;

  /// Subtitle / chevron grey.
  Color get iosSecondaryLabel => _isDark
      ? SerenityColors.secondaryLabelDark
      : SerenityColors.secondaryLabel;

  /// Primary on-surface text.
  Color get iosLabel =>
      _isDark ? SerenityColors.onSurfaceDark : SerenityColors.primary;

  /// Subtle navy / mint glow used for iOS shadows. On dark we widen alpha
  /// to compensate for low contrast against black.
  List<BoxShadow> get iosShadow => _isDark
      ? [
          BoxShadow(
            color: SerenityColors.voltMint.withValues(alpha: 0.04),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ]
      : [
          BoxShadow(
            color: SerenityColors.primaryContainer.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ];
}
