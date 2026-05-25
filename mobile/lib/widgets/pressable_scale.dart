/// PressableScale — Apple-style press feedback wrapper.
///
/// Wraps any child with a subtle scale-down on press (0.97) + spring-back
/// on release. Optional haptic feedback. Use around AppleCard, list rows,
/// big CTA buttons — anywhere a "tap" should feel tactile.
///
/// If [onTap] is null, no scale is applied (read-only mode).
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/design_tokens.dart';

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
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: SerenityAnim.tap,
      reverseDuration: const Duration(milliseconds: 260),
    );
    // Spring-like curve for release (overshoot a little).
    _scale = Tween<double>(begin: 1.0, end: widget.pressedScale).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.elasticOut,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _down(_) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _ctrl.forward();
  }

  void _up(_) {
    if (widget.onTap == null && widget.onLongPress == null) return;
    _ctrl.reverse();
  }

  void _cancel() {
    _ctrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final scaled = AnimatedBuilder(
      animation: _scale,
      builder: (_, child) => Transform.scale(
        scale: _scale.value,
        child: child,
      ),
      child: widget.child,
    );

    if (widget.scaleOnly) {
      // Only listen for pointer events — do not consume the gesture.
      // Inner InkWell / GestureDetector will still receive the tap.
      return Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: (_) {
          _ctrl.forward();
        },
        onPointerUp: (_) {
          _ctrl.reverse();
        },
        onPointerCancel: (_) => _cancel(),
        child: scaled,
      );
    }

    final disabled = widget.onTap == null && widget.onLongPress == null;
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: _down,
      onTapUp: _up,
      onTapCancel: _cancel,
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
