/// be:Safe v2 — Serenity Card
///
/// White card with 24dp radius and soft high-diffusion shadow.
/// Use as the primary container for grouped content.
///
/// Usage:
///   SerenityCard(
///     child: Column(children: [...]),
///   )
///
/// For glassmorphic variant (semi-transparent + blur, for floating overlays):
///   SerenityCard.glass(child: ...)

library;
import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/ios_surfaces.dart';
import '../theme/design_tokens.dart';

class SerenityCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final bool showShadow;
  final bool bordered;

  const SerenityCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SerenitySpacing.xl),
    this.color,
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
    this.showShadow = true,
    this.bordered = false,
  });

  /// Glassmorphic variant: white@80% + backdrop blur.
  /// Ideal for floating widgets over map / imagery.
  const SerenityCard.glass({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(SerenitySpacing.xl),
    this.width,
    this.height,
    this.onTap,
    this.borderRadius,
  })  : color = null,
        showShadow = true,
        bordered = true;

  @override
  Widget build(BuildContext context) {
    final isGlass = color == null && bordered;
    final radius = borderRadius ?? SerenityShapes.card();

    Widget content = Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: isGlass
            ? context.iosCardSurface.withValues(alpha: 0.8)
            : (color ?? context.iosCardSurface),
        borderRadius: radius,
        boxShadow: showShadow ? SerenityElevation.card() : null,
        border: bordered
            ? Border.all(
                color: context.iosSeparator.withValues(alpha: 0.5),
                width: 1,
              )
            : null,
      ),
      child: child,
    );

    if (isGlass) {
      content = ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: content,
        ),
      );
    }

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: content,
        ),
      );
    }

    return content;
  }
}
