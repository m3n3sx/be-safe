// ignore_for_file: constant_identifier_names

/// be:Safe v2 — Serenity Guard Design Tokens
///
/// Single source of truth for the Serenity Guard design system.
/// Based on `design/stitch_v2/DESIGN.md` (Google Stitch export, 2026-05-12).
///
/// Design philosophy:
/// - "Vigilant yet calm" — reduce cortisol, increase trust
/// - Whitespace-driven (not density-driven)
/// - Glow orb as signature (radial gradient + subtle pulse)
/// - Weight contrasts > size contrasts (Inter 100-500)
///
/// Usage:
///   import 'package:alertmap/theme/design_tokens.dart';
///   Container(color: SerenityColors.primaryContainer);
///   Text('9/10', style: SerenityText.displayLg);

library;
import 'package:flutter/material.dart';

// ============================================================================
// COLORS — Material You palette (Serenity Guard light mode)
// ============================================================================

class SerenityColors {
  SerenityColors._();

  // Primary — almost-black ink, grounding
  static const primary          = Color(0xFF03080E);
  static const onPrimary        = Color(0xFFFFFFFF);
  static const primaryContainer = Color(0xFF1A2027); // deep navy (nav pill)
  static const onPrimaryContainer = Color(0xFF828790);
  static const inversePrimary   = Color(0xFFC1C7D0);
  static const primaryFixed     = Color(0xFFDDE3ED);
  static const primaryFixedDim  = Color(0xFFC1C7D0);
  static const onPrimaryFixed   = Color(0xFF161C23);
  static const onPrimaryFixedVariant = Color(0xFF41474F);

  // Secondary — safe-mint (calm confirmation)
  static const secondary          = Color(0xFF006C4C);
  static const onSecondary        = Color(0xFFFFFFFF);
  static const secondaryContainer = Color(0xFF9DF4CB); // glow orb core
  static const onSecondaryContainer = Color(0xFF0F7252);
  static const secondaryFixed     = Color(0xFF9DF4CB);
  static const secondaryFixedDim  = Color(0xFF81D7B0);
  static const onSecondaryFixed   = Color(0xFF002115);
  static const onSecondaryFixedVariant = Color(0xFF005138);

  // Tertiary — alert-coral (warning, not panic)
  static const tertiary          = Color(0xFF190001);
  static const onTertiary        = Color(0xFFFFFFFF);
  static const tertiaryContainer = Color(0xFF480008);
  static const onTertiaryContainer = Color(0xFFDB5F60);
  static const tertiaryFixed     = Color(0xFFFFDAD8);
  static const tertiaryFixedDim  = Color(0xFFFFB3B1);
  static const onTertiaryFixed   = Color(0xFF410007);
  static const onTertiaryFixedVariant = Color(0xFF862026);

  // Error
  static const error          = Color(0xFFBA1A1A);
  static const onError        = Color(0xFFFFFFFF);
  static const errorContainer = Color(0xFFFFDAD6);
  static const onErrorContainer = Color(0xFF93000A);

  // Surface — near-white, breathable
  static const surface                    = Color(0xFFFCF8F9);
  static const surfaceBright              = Color(0xFFFCF8F9);
  static const surfaceDim                 = Color(0xFFDCD9DA);
  static const surfaceContainerLowest     = Color(0xFFFFFFFF); // cards
  static const surfaceContainerLow        = Color(0xFFF6F3F3);
  static const surfaceContainer           = Color(0xFFF0EDED);
  static const surfaceContainerHigh       = Color(0xFFEAE7E8);
  static const surfaceContainerHighest    = Color(0xFFE5E2E2);
  static const onSurface                  = Color(0xFF1C1B1C);
  static const onSurfaceVariant           = Color(0xFF44474B);
  static const surfaceVariant             = Color(0xFFE5E2E2);
  static const inverseSurface             = Color(0xFF313031);
  static const inverseOnSurface           = Color(0xFFF3F0F0);
  static const surfaceTint                = Color(0xFF595F67);

  // Outline — only where absolutely needed (prefer whitespace)
  static const outline        = Color(0xFF75777B);
  static const outlineVariant = Color(0xFFC5C6CB);

  // Background (alias to surface)
  static const background     = Color(0xFFFCF8F9);
  static const onBackground   = Color(0xFF1C1B1C);

  // Glow orb base tints — used as `Color.fromARGB` in gradients
  static const glowSafeMint = Color(0xFF9DF4CB);   // "wszystko OK"
  static const glowCalmAqua = Color(0xFF9EEBEC);   // passive monitoring
  static const glowAlertCoral = Color(0xFFFF7A7A); // urgent (non-panic)
}

// ============================================================================
// TYPOGRAPHY — Inter, weight-contrast driven
// ============================================================================

class SerenityText {
  SerenityText._();

  static const _family = 'Inter';

  /// 80 / 100w / -0.04em — big stat numbers (e.g. "9/10")
  static const displayLg = TextStyle(
    fontFamily: _family,
    fontSize: 80,
    height: 96 / 80,
    fontWeight: FontWeight.w100,
    letterSpacing: -0.04 * 80,
    color: SerenityColors.primary,
  );

  /// 64 / 200w / -0.02em — hero messages
  static const displayMd = TextStyle(
    fontFamily: _family,
    fontSize: 64,
    height: 72 / 64,
    fontWeight: FontWeight.w200,
    letterSpacing: -0.02 * 64,
    color: SerenityColors.primary,
  );

  /// 32 / 300w / -0.01em — screen titles (desktop/tablet)
  static const headlineHero = TextStyle(
    fontFamily: _family,
    fontSize: 32,
    height: 40 / 32,
    fontWeight: FontWeight.w300,
    letterSpacing: -0.01 * 32,
    color: SerenityColors.primary,
  );

  /// 28 / 300w — screen titles (mobile)
  static const headlineHeroMobile = TextStyle(
    fontFamily: _family,
    fontSize: 28,
    height: 36 / 28,
    fontWeight: FontWeight.w300,
    color: SerenityColors.primary,
  );

  /// 16 / 400w — default reading text
  static const bodyMain = TextStyle(
    fontFamily: _family,
    fontSize: 16,
    height: 24 / 16,
    fontWeight: FontWeight.w400,
    color: SerenityColors.onSurfaceVariant,
  );

  /// 14 / 500w — buttons, nav labels
  static const labelButton = TextStyle(
    fontFamily: _family,
    fontSize: 14,
    height: 20 / 14,
    fontWeight: FontWeight.w500,
    color: SerenityColors.primary,
  );

  /// 12 / 500w / +0.05em — uppercase tiny labels ("POZIOM BEZPIECZEŃSTWA")
  static const labelCaps = TextStyle(
    fontFamily: _family,
    fontSize: 12,
    height: 16 / 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.05 * 12,
    color: SerenityColors.onSurfaceVariant,
  );
}

// ============================================================================
// SHAPES — large, friendly radii + pill nav
// ============================================================================

class SerenityShapes {
  SerenityShapes._();

  static const radiusSm = 4.0;      // 0.25rem
  static const radiusDefault = 8.0; // 0.5rem
  static const radiusMd = 12.0;     // 0.75rem
  static const radiusLg = 16.0;     // 1rem — secondary cards
  static const radiusXl = 24.0;     // 1.5rem — DEFAULT cards, inputs
  static const radiusFull = 9999.0; // pills

  static const cardRadius = radiusXl;

  static BorderRadius card() => BorderRadius.circular(radiusXl);
  static BorderRadius pill() => BorderRadius.circular(radiusFull);
  static BorderRadius input() => BorderRadius.circular(radiusXl);
}

// ============================================================================
// SPACING — 8px grid
// ============================================================================

class SerenitySpacing {
  SerenitySpacing._();

  static const unit = 8.0;

  static const xxs = 4.0;    // 0.5u
  static const xs = 8.0;     // 1u
  static const sm = 12.0;    // 1.5u
  static const md = 16.0;    // 2u — gutter
  static const lg = 20.0;    // 2.5u — card-gap (between related widgets)
  static const xl = 24.0;    // 3u — container-padding (side margins)
  static const xxl = 32.0;   // 4u
  static const xxxl = 48.0;  // 6u — section-margin (between blocks)
}

// ============================================================================
// ELEVATION — glassmorphism + soft shadows
// ============================================================================

class SerenityElevation {
  SerenityElevation._();

  /// Base card elevation — soft, high-diffusion shadow.
  /// Blur 40dp, opacity 4%, color = #1A2027 (primaryContainer).
  static List<BoxShadow> card() => [
    BoxShadow(
      color: SerenityColors.primaryContainer.withValues(alpha: 0.04),
      blurRadius: 40,
      offset: const Offset(0, 40),
      spreadRadius: 0,
    ),
  ];

  /// Slightly stronger for floating widgets (FAB, nav bar).
  static List<BoxShadow> floating() => [
    BoxShadow(
      color: SerenityColors.primaryContainer.withValues(alpha: 0.15),
      blurRadius: 40,
      offset: const Offset(0, 20),
      spreadRadius: 0,
    ),
  ];

  /// Pronounced for highest elements (nav pill).
  static List<BoxShadow> nav() => [
    BoxShadow(
      color: SerenityColors.primaryContainer.withValues(alpha: 0.25),
      blurRadius: 40,
      offset: const Offset(0, 20),
      spreadRadius: 0,
    ),
  ];
}

// ============================================================================
// ANIMATIONS — timings used across Serenity widgets
// ============================================================================

class SerenityAnim {
  SerenityAnim._();

  /// Glow orb breathing (90% ↔ 110% scale).
  static const orbBreath = Duration(milliseconds: 4000);

  /// Standard micro-interactions (press, tap, focus).
  static const tap = Duration(milliseconds: 200);

  /// Panel / sheet transitions.
  static const sheet = Duration(milliseconds: 300);
}
