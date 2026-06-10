/// be:Safe v2 — Glow Orb widget
///
/// Signature element of the Serenity Guard design.
/// A breathing radial gradient representing safety status.
///
/// Usage:
///   GlowOrb(
///     size: 280,
///     color: SerenityColors.glowSafeMint,
///     child: Column(
///       children: [
///         Text('POZIOM BEZPIECZEŃSTWA', style: SerenityText.labelCaps),
///         Text('9/10', style: SerenityText.displayLg),
///       ],
///     ),
///   )

library;
import 'package:flutter/material.dart';
import '../theme/design_tokens.dart';
import '../providers/accessibility_provider.dart';

class GlowOrb extends StatefulWidget {
  /// Diameter of the orb in logical pixels. Default 280.
  final double size;

  /// Core color of the orb at 100% opacity.
  /// Use [SerenityColors.glowSafeMint] for "wszystko OK",
  /// [SerenityColors.glowCalmAqua] for passive monitoring,
  /// [SerenityColors.glowAlertCoral] for urgent states.
  final Color color;

  /// Optional child centered in the orb (e.g. status label + big number).
  final Widget? child;

  /// Whether to animate a subtle breathing pulse (scale 0.9 ↔ 1.1).
  final bool pulse;

  /// Pulse duration (default 4s — should feel organic, not digital).
  final Duration pulseDuration;

  /// Opacity at center (default 0.8 — mint is quite saturated).
  final double coreOpacity;

  const GlowOrb({
    super.key,
    this.size = 280,
    this.color = SerenityColors.glowSafeMint,
    this.child,
    this.pulse = true,
    this.pulseDuration = SerenityAnim.orbBreath,
    this.coreOpacity = 0.8,
  });

  @override
  State<GlowOrb> createState() => _GlowOrbState();
}

class _GlowOrbState extends State<GlowOrb>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: widget.pulseDuration,
    );
    _scale = Tween<double>(begin: 0.9, end: 1.1).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    _applyMotion();
    reduceMotionNotifier.addListener(_applyMotion);
  }

  /// Uruchamia/zatrzymuje pulsowanie zależnie od reduce-motion.
  void _applyMotion() {
    if (!mounted) return;
    if (widget.pulse && !reduceMotionNotifier.value) {
      _ctrl.repeat(reverse: true);
    } else {
      _ctrl.stop();
      _ctrl.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(covariant GlowOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pulseDuration != widget.pulseDuration) {
      _ctrl.duration = widget.pulseDuration;
    }
    if (oldWidget.pulse != widget.pulse ||
        oldWidget.pulseDuration != widget.pulseDuration) {
      _applyMotion();
    }
  }

  @override
  void dispose() {
    reduceMotionNotifier.removeListener(_applyMotion);
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Animated radial gradient (the actual orb)
          ScaleTransition(
            scale: _scale,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.color.withValues(alpha: widget.coreOpacity),
                    widget.color.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.7],
                ),
              ),
            ),
          ),
          // Static centered content
          if (widget.child != null) widget.child!,
        ],
      ),
    );
  }
}
