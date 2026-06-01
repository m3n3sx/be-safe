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
  late final AnimationController _breath;

  @override
  void initState() {
    super.initState();
    // 4-second breathing loop matches SerenityAnim.orbBreath. Subtle
    // pulse on opacity (0.85 → 1.0) keeps the static gradient ellipse alive.
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

  AlignmentGeometry get _gradientBegin {
    // ≈73° → top-left to bottom-right
    return Alignment.topLeft;
  }

  AlignmentGeometry get _gradientEnd => Alignment.bottomRight;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // 1. Blurred halo ellipse (behind everything)
          Positioned.fill(
            child: Center(
              child: AnimatedBuilder(
                animation: _breath,
                builder: (_, __) {
                  final t = Curves.easeInOut.transform(_breath.value);
                  final scale = 0.97 + 0.03 * t;
                  return Transform.scale(
                    scale: scale,
                    child: _BlurredHalo(
                      colors: _gradientColors,
                      begin: _gradientBegin,
                      end: _gradientEnd,
                    ),
                  );
                },
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

/// Soft "cloud" halo — multi-ellipse stack pushed through a heavy gaussian
/// blur, exactly as in Figma (V7gYh6uA0axopciUTSn4Ib): not a solid ring,
/// not a hard circle, just diffuse coloured fog hovering behind the score.
/// Three offset ellipses with `BlendMode.plus` overlap into a chunky, organic
/// shape; `ImageFilter.blur(60)` melts the edges into the page background.
class _BlurredHalo extends StatelessWidget {
  final List<Color> colors;
  final AlignmentGeometry begin;
  final AlignmentGeometry end;
  const _BlurredHalo({
    required this.colors,
    required this.begin,
    required this.end,
  });

  @override
  Widget build(BuildContext context) {
    final c1 = colors.first.withValues(alpha: 0.65);
    final c2 = colors.last.withValues(alpha: 0.75);
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 60, sigmaY: 60),
      child: SizedBox(
        width: 360,
        height: 360,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Główna chmura — szeroka elipsa, obrócona o ~20°, BlendMode.plus
            Transform.rotate(
              angle: 0.35,
              child: Container(
                width: 280,
                height: 210,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(140),
                  color: c1,
                ),
              ),
            ),
            // Druga warstwa — kolor docelowy gradientu, w prawo-dół, mniejsza
            Positioned(
              right: 40,
              bottom: 60,
              child: Container(
                width: 220,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(120),
                  color: c2,
                ),
              ),
            ),
            // Akcent — mała plamka w lewy-górny, kolor pośredni
            Positioned(
              left: 50,
              top: 70,
              child: Container(
                width: 160,
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(90),
                  color: Color.lerp(c1, c2, 0.5)!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
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


