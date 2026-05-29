/// be:Safe v97 — Safety Hero XL
///
/// Voltgear-inspired oversized hero: 280pt mint ring with a breathing glow,
/// thin level number centered, sub-pill chip with alert count.
///
/// Replaces the previous GlowOrb hero (lib/widgets/glow_orb.dart) on the
/// NORMAL Home screen. Calmer Serenity mint stays the baseline; voltMint
/// is used for the urgent gradient stop on the progress ring.

library;

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/design_tokens.dart';

class SafetyHeroXL extends StatefulWidget {
  /// 0..10 safety score (10 = best).
  final int level;

  /// Headline rendered above the ring (e.g. "Wszystko w porządku").
  final String headline;

  /// Subtitle rendered below the headline.
  final String subtitle;

  /// Base color of the ring + glow (varies with safety level).
  final Color ringColor;

  /// Alert count for the sub-pill ("3 alerty w pobliżu").
  final int alertsNearby;

  /// Optional tap handler — wires the "Zobacz mapę →" link.
  final VoidCallback? onMapTap;

  const SafetyHeroXL({
    super.key,
    required this.level,
    required this.headline,
    required this.subtitle,
    required this.ringColor,
    required this.alertsNearby,
    this.onMapTap,
  });

  @override
  State<SafetyHeroXL> createState() => _SafetyHeroXLState();
}

class _SafetyHeroXLState extends State<SafetyHeroXL>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    // 4-second breathing loop (matches SerenityAnim.orbBreath).
    _breath = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final progress = (widget.level / 10).clamp(0.0, 1.0);
    final pillLabel = widget.alertsNearby == 0
        ? 'Brak alertów · sprawdź mapę'
        : (widget.alertsNearby == 1
            ? '1 alert w pobliżu'
            : (widget.alertsNearby < 5
                ? '${widget.alertsNearby} alerty w pobliżu'
                : '${widget.alertsNearby} alertów w pobliżu'));

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          // Headline + subtitle, calm.
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.headline,
              style: SerenityText.displayMd.copyWith(
                fontSize: 36,
                height: 44 / 36,
                fontWeight: FontWeight.w200,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              widget.subtitle,
              style: SerenityText.bodyMain,
              textAlign: TextAlign.center,
            ),
          ),

          // The XL ring.
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: AnimatedBuilder(
              animation: _breath,
              builder: (ctx, _) {
                // 0..1 breathing factor with smooth ease.
                final t = Curves.easeInOut.transform(_breath.value);
                final glowAlpha = 0.18 + 0.22 * t; // 0.18..0.40
                final scale = 0.985 + 0.015 * t; // very subtle pulse
                return Transform.scale(
                  scale: scale,
                  child: SizedBox(
                    width: 296,
                    height: 296,
                    child: CustomPaint(
                      painter: _RingPainter(
                        progress: progress,
                        baseColor: widget.ringColor,
                        accentColor: SerenityColors.voltMint,
                        glowAlpha: glowAlpha,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'POZIOM BEZPIECZEŃSTWA',
                              style: SerenityText.iosSectionHeader.copyWith(
                                fontSize: 11,
                                letterSpacing: 1.4,
                              ),
                            ),
                            const SizedBox(height: 12),
                            RichText(
                              textAlign: TextAlign.center,
                              text: TextSpan(
                                children: [
                                  TextSpan(
                                    text: '${widget.level}',
                                    style: SerenityText.displayLg.copyWith(
                                      fontSize: 96,
                                      height: 1.0,
                                      fontWeight: FontWeight.w100,
                                      letterSpacing: -4,
                                    ),
                                  ),
                                  TextSpan(
                                    text: ' / 10',
                                    style: SerenityText.bodyMain.copyWith(
                                      fontSize: 22,
                                      color: SerenityColors.secondaryLabel,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Sub-pill: alerts in vicinity.
          _SubPill(text: pillLabel),

          const SizedBox(height: 18),

          // "Zobacz mapę →" link.
          GestureDetector(
            onTap: widget.onMapTap,
            behavior: HitTestBehavior.opaque,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 8, horizontal: 24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Zobacz mapę', style: SerenityText.labelButton),
                  SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward,
                    size: 16,
                    color: SerenityColors.primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubPill extends StatelessWidget {
  final String text;
  const _SubPill({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: SerenityColors.primaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.white,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}

/// Paints the XL safety ring:
///   1. soft outer glow (blur, base color)
///   2. faint track ring (12% alpha)
///   3. progress sweep (base → voltMint gradient) starting at top
class _RingPainter extends CustomPainter {
  final double progress; // 0..1
  final Color baseColor;
  final Color accentColor;
  final double glowAlpha; // 0..1

  _RingPainter({
    required this.progress,
    required this.baseColor,
    required this.accentColor,
    required this.glowAlpha,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final r = size.shortestSide / 2;
    final strokeWidth = 18.0;
    final ringRadius = r - strokeWidth / 2 - 8;

    // 1. Outer glow halo.
    final glowPaint = Paint()
      ..color = baseColor.withValues(alpha: glowAlpha)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 36);
    canvas.drawCircle(center, ringRadius + 4, glowPaint);

    // 2. Inner radial wash — calm, behind text.
    final innerWashPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.18),
          baseColor.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromCircle(center: center, radius: ringRadius));
    canvas.drawCircle(center, ringRadius, innerWashPaint);

    // 3. Track ring (faint).
    final trackPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = SerenityColors.separator.withValues(alpha: 0.35);
    canvas.drawCircle(center, ringRadius, trackPaint);

    // 4. Progress sweep starting at top (-π/2).
    final rect = Rect.fromCircle(center: center, radius: ringRadius);
    final sweep = 2 * math.pi * progress;
    final progressPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: -math.pi / 2 + sweep,
        colors: [baseColor, accentColor],
      ).createShader(rect);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.baseColor != baseColor ||
      old.glowAlpha != glowAlpha;
}
