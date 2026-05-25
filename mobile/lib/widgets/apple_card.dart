/// AppleCard — single-purpose inline card (iOS style).
///
/// White surface (`groupedSurface`), 16pt radius, gentle ios() shadow.
/// Use for hero widgets, alert cards, AQI tile, quick-action cells.
/// For lists of rows use InsetGroupedSection instead.
library;

import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';

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
    final bg = backgroundColor ?? SerenityColors.groupedSurface;
    final child0 = Padding(padding: padding, child: child);

    return Padding(
      padding: margin,
      child: ClipRRect(
        borderRadius: SerenityShapes.iosInlineCard(),
        child: Container(
          decoration: BoxDecoration(
            color: bg,
            borderRadius: SerenityShapes.iosInlineCard(),
            boxShadow: SerenityElevation.ios(),
          ),
          child: onTap == null
              ? child0
              : Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: onTap,
                    splashColor: SerenityColors.separator.withValues(alpha: 0.4),
                    highlightColor: SerenityColors.separator.withValues(alpha: 0.2),
                    child: child0,
                  ),
                ),
        ),
      ),
    );
  }
}
