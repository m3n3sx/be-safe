/// AppleCard — single-purpose inline card (iOS style).
///
/// White surface (`groupedSurface`), 16pt radius, gentle ios() shadow.
/// Use for hero widgets, alert cards, AQI tile, quick-action cells.
/// For lists of rows use InsetGroupedSection instead.
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../theme/ios_surfaces.dart';
import 'pressable_scale.dart';

class AppleCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  final EdgeInsets margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;

  const AppleCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = EdgeInsets.zero,
    this.onTap,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? context.iosCardSurface;
    final child0 = Padding(padding: padding, child: child);

    final card = ClipRRect(
      borderRadius: SerenityShapes.iosInlineCard(),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: SerenityShapes.iosInlineCard(),
          boxShadow: context.iosShadow,
        ),
        child: onTap == null
            ? child0
            : Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: onTap,
                  splashColor: context.iosSeparator.withValues(alpha: 0.4),
                  highlightColor: context.iosSeparator.withValues(alpha: 0.2),
                  child: child0,
                ),
              ),
      ),
    );

    return Padding(
      padding: margin,
      child: onTap == null
          ? card
          : PressableScale(scaleOnly: true, child: card),
    );
  }
}
