/// be:Safe v97 — Stagger list reveal
///
/// Wraps a list of children in a staggered fade + slide-up animation.
/// Used on Home and Profile to give cards an Apple-style cascade entrance.
///
/// Each child appears `delayPerItem` ms after the previous one, fading from
/// 0 → 1 opacity while sliding up `offset` pixels.

library;

import 'package:flutter/material.dart';

class StaggerColumn extends StatefulWidget {
  final List<Widget> children;
  final Duration itemDuration;
  final Duration delayPerItem;
  final double offset;

  const StaggerColumn({
    super.key,
    required this.children,
    this.itemDuration = const Duration(milliseconds: 380),
    this.delayPerItem = const Duration(milliseconds: 55),
    this.offset = 14,
  });

  @override
  State<StaggerColumn> createState() => _StaggerColumnState();
}

class _StaggerColumnState extends State<StaggerColumn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    final total = widget.itemDuration +
        widget.delayPerItem * widget.children.length;
    _ctrl = AnimationController(vsync: this, duration: total)..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.children.isEmpty) return const SizedBox.shrink();
    final total = _ctrl.duration!.inMilliseconds;
    final itemMs = widget.itemDuration.inMilliseconds;
    final delayMs = widget.delayPerItem.inMilliseconds;

    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: List.generate(widget.children.length, (i) {
            final startMs = (i * delayMs).toDouble();
            final endMs = (startMs + itemMs).clamp(0.0, total.toDouble());
            final begin = startMs / total;
            final end = endMs / total;
            final curved = CurvedAnimation(
              parent: _ctrl,
              curve: Interval(begin, end, curve: Curves.easeOutCubic),
            );
            return AnimatedBuilder(
              animation: curved,
              builder: (c, child) {
                final t = curved.value;
                return Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * widget.offset),
                    child: child,
                  ),
                );
              },
              child: widget.children[i],
            );
          }),
        );
      },
    );
  }
}

/// Wraps a single sliver child in the same stagger entrance.
/// Use inside a CustomScrollView when you cannot use [StaggerColumn].
class StaggerSliverItem extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final Duration duration;
  final double offset;

  const StaggerSliverItem({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.duration = const Duration(milliseconds: 380),
    this.offset = 14,
  });

  @override
  State<StaggerSliverItem> createState() => _StaggerSliverItemState();
}

class _StaggerSliverItemState extends State<StaggerSliverItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    Future.delayed(widget.delay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (ctx, child) {
        final t = Curves.easeOutCubic.transform(_ctrl.value);
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, (1 - t) * widget.offset),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
