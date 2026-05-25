/// PressableScale — Apple-style press feedback wrapper.
///
/// Wraps any child with a subtle scale-down on press (0.97) + spring-back
/// on release using real SpringSimulation physics (mass/stiffness/damping)
/// for a natural iOS feel. Optional haptic feedback.
///
/// If [onTap] is null, no scale is applied (read-only mode).
library;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final bool haptic;
  final HitTestBehavior behavior;

  /// When [scaleOnly] is true, all gesture callbacks (tap/longPress)
  /// are NOT consumed here — only the scale animation runs in response
  /// to raw pointer events. Use this when an inner InkWell or another
  /// gesture detector already handles the tap.
  final bool scaleOnly;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.97,
    this.haptic = true,
    this.behavior = HitTestBehavior.opaque,
    this.scaleOnly = false,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Spring tuned to feel like iOS button press: snappy down, soft bounce up.
  // mass=1, stiffness=320, damping=20 → ~critically damped with slight bounce.
  static const SpringDescription _spring = SpringDescription(
    mass: 1,
    stiffness: 320,
    damping: 20,
  );

  @override
  void initState() {
    super.initState();
    // Range [0..1] where 0 = released, 1 = fully pressed.
    _ctrl = AnimationController.unbounded(vsync: this, value: 0);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _animateTo(double target) {
    final sim = SpringSimulation(_spring, _ctrl.value, target, 0);
    _ctrl.animateWith(sim);
  }

  void _down() => _animateTo(1.0);
  void _up() => _animateTo(0.0);

  @override
  Widget build(BuildContext context) {
    final scaled = AnimatedBuilder(
      animation: _ctrl,
      builder: (_, child) {
        // Map t∈[0..1] to scale [1.0 .. pressedScale].
        final t = _ctrl.value.clamp(0.0, 1.0);
        final scale = 1.0 + (widget.pressedScale - 1.0) * t;
        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );

    if (widget.scaleOnly) {
      // Only listen for pointer events — do not consume the gesture.
      // Inner InkWell / GestureDetector will still receive the tap.
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) => _down(),
        onPointerUp: (_) => _up(),
        onPointerCancel: (_) => _up(),
        child: scaled,
      );
    }

    final disabled = widget.onTap == null && widget.onLongPress == null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: disabled ? null : (_) => _down(),
      onTapUp: disabled ? null : (_) => _up(),
      onTapCancel: disabled ? null : _up,
      onTap: disabled
          ? null
          : () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            },
      onLongPress: widget.onLongPress == null
          ? null
          : () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress?.call();
            },
      child: scaled,
    );
  }
}
