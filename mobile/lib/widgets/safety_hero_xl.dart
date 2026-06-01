/// be:Safe v100 — Safety Hero (Figma redesign)
///
/// Inspired by Figma file V7gYh6uA0axopciUTSn4Ib (user m2445):
///   - Headline ("Wszystko w porządku") above
///   - Large blurred ellipse with linear gradient as ambient halo
///     (green = safe ≥7, orange = caution 4-6, red = danger ≤3)
///   - Subtitle "Poziom bezpieczeństwa w twojej okolicy" centered
///   - Massive "10" 96pt thin + " /10" 24pt secondary
///   - Black pill "Sprawdź na mapie." below
///
/// Previous v97 implementation (Voltgear progress ring) replaced wholesale.
/// User m2445: "teksty nad kolorowymi stanami zagrożenia są w linku
/// przykładowe więc zostaw takie jakie są w apce" — passed via [headline].

library;

import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../theme/ios_surfaces.dart';

class SafetyHeroXL extends StatefulWidget {
  /// 0..10 safety score (10 = best).
  final int level;

  /// Headline (e.g. "Wszystko w porządku") — set by HomeScreen.
  final String headline;

  /// Subtitle (e.g. "1 alert w pobliżu") — currently unused on canvas,
  /// kept for API compatibility.
  final String subtitle;

  /// Base color of the halo (varies with safety level — see HomeScreen._orbColor).
  final Color ringColor;

  /// Alert count (unused in v100 canvas — kept for API compat).
  final int alertsNearby;

  /// Tap handler wired to "Sprawdź na mapie." pill.
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
  late final AnimationController _drift;

  @override
  void initState() {
    super.initState();
    // Long, slow loop driving the blob drift. Each blob picks its own phase
    // & orbit radius from this single ticker — Aceternity-style meta balls.
    _drift = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..repeat();
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  /// Linear gradient stops per Figma (V7gYh6uA0axopciUTSn4Ib):
  ///   - green:  73°, rgba(65,255,75,.53) → #44FE00
  ///   - orange: 67°, rgba(255,170,0,.67) → #EB6A00
  ///   - red:    72°, rgba(255,124,98,.76) → #CE2200
  List<Color> get _gradientColors {
    final base = widget.ringColor;
    if (base == const Color(0xFF44FE00)) {
      return const [Color(0x8741FF4B), Color(0xFF44FE00)];
    }
    if (base == const Color(0xFFEB6A00)) {
      return const [Color(0xAAFFAA00), Color(0xFFEB6A00)];
    }
    return const [Color(0xC2FF7C62), Color(0xFFCE2200)];
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Animated blob halo (Aceternity-style meta balls).
          //    v106: edge-to-edge — halo wycieka POD status bar (top -180),
          //    twardszy fade na dole zeby NIE dotykac karty 'Moja rodzina'.
          Positioned(
            top: -180,
            left: -40,
            right: -40,
            child: SizedBox(
              height: 600,
              child: ClipRect(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) => const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.55, 0.78, 0.92],
                    colors: [
                      Colors.white,
                      Colors.white,
                      Color(0x22FFFFFF), // ~13% opacity
                      Colors.transparent,
                    ],
                  ).createShader(rect),
                  child: _AnimatedBlobs(
                    drift: _drift,
                    colors: _gradientColors,
                  ),
                ),
              ),
            ),
          ),
          // 2. Foreground content
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 50),
              // Headline — big bold (e.g. "Wszystko w porządku")
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  widget.headline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                    height: 1.21,
                    color: context.iosLabel,
                  ),
                ),
              ),
              const SizedBox(height: 56),
              // Subtitle (per Figma — fixed wording)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Poziom bezpieczeństwa\nw twojej okolicy',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    fontSize: 13,
                    height: 1.18,
                    color: context.iosLabel,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Big number "N" + "/10"
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.level}',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 96,
                        height: 1.0,
                        letterSpacing: -8,
                        color: context.iosLabel,
                      ),
                    ),
                    TextSpan(
                      text: ' /10',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w400,
                        fontSize: 24,
                        letterSpacing: -0.5,
                        color: context.iosLabel,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 56),
              // Black pill "Sprawdź na mapie."
              _MapPill(onTap: widget.onMapTap),
              const SizedBox(height: 24),
            ],
          ),
        ],
      ),
    );
  }
}

/// Aceternity-style background gradient animation — meta-ball drift.
///
/// Six soft "blobs" orbit around the hero centre with independent phases,
/// frequencies and radii, then the whole stack passes through a heavy
/// `ImageFilter.blur(80)` so adjacent blobs melt together. The effect is a
/// slow, organic fog that breathes through the safety-level area and reaches
/// up behind the greeting line.
///
/// Inspired by https://ui.aceternity.com/components/background-gradient-animation
class _AnimatedBlobs extends StatelessWidget {
  final Animation<double> drift;
  final List<Color> colors;
  const _AnimatedBlobs({required this.drift, required this.colors});

  @override
  Widget build(BuildContext context) {
    final c1 = colors.first.withValues(alpha: 0.55);
    final c2 = colors.last.withValues(alpha: 0.70);
    final c3 = Color.lerp(c1, c2, 0.5)!.withValues(alpha: 0.60);
    // Phase, amplitudeX, amplitudeY, baseX (0..1), baseY (0..1), size, color
    final blobs = <_BlobSpec>[
      _BlobSpec(phase: 0.00, ampX: 70, ampY: 50, baseX: .50, baseY: .55, size: 280, color: c1),
      _BlobSpec(phase: 0.25, ampX: 60, ampY: 80, baseX: .35, baseY: .35, size: 220, color: c2),
      _BlobSpec(phase: 0.50, ampX: 90, ampY: 40, baseX: .65, baseY: .40, size: 260, color: c3),
      _BlobSpec(phase: 0.10, ampX: 50, ampY: 70, baseX: .40, baseY: .65, size: 200, color: c2),
      _BlobSpec(phase: 0.65, ampX: 80, ampY: 30, baseX: .60, baseY: .60, size: 240, color: c1),
      _BlobSpec(phase: 0.85, ampX: 40, ampY: 60, baseX: .50, baseY: .25, size: 180, color: c3),
    ];
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
      child: AnimatedBuilder(
        animation: drift,
        builder: (ctx, _) {
          return LayoutBuilder(
            builder: (_, c) {
              return Stack(
                children: [
                  for (final b in blobs) _positionedBlob(b, c, drift.value),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _positionedBlob(_BlobSpec b, BoxConstraints c, double t) {
    final cx = c.maxWidth * b.baseX - b.size / 2;
    final cy = c.maxHeight * b.baseY - b.size / 2;
    final angle = (t + b.phase) * 2 * math.pi;
    final dx = math.cos(angle) * b.ampX;
    final dy = math.sin(angle * 1.3) * b.ampY;
    return Positioned(
      left: cx + dx,
      top: cy + dy,
      child: Container(
        width: b.size,
        height: b.size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: b.color,
        ),
      ),
    );
  }
}

class _BlobSpec {
  final double phase;
  final double ampX;
  final double ampY;
  final double baseX;
  final double baseY;
  final double size;
  final Color color;
  const _BlobSpec({
    required this.phase,
    required this.ampX,
    required this.ampY,
    required this.baseX,
    required this.baseY,
    required this.size,
    required this.color,
  });
}

class _MapPill extends StatelessWidget {
  final VoidCallback? onTap;
  const _MapPill({this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFFE5E7EB) : const Color(0xFF030303);
    final fg = isDark ? const Color(0xFF030303) : Colors.white;
    return Material(
      color: bg,
      borderRadius: BorderRadius.circular(37),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(37),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
          child: Text(
            'Sprawdź na mapie.',
            style: TextStyle(
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.18,
              color: fg,
            ),
          ),
        ),
      ),
    );
  }
}


