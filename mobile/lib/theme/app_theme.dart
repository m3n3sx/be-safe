/// be:Safe v2 — Serenity Guard Theme
///
/// Material 3 ThemeData wired to SerenityColors + SerenityText tokens.
/// Call `buildSerenityTheme(Brightness.light)` in MaterialApp.theme.

library;
import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// iOS-style bouncy scroll behavior. Use as `MaterialApp.scrollBehavior`
/// to give all ListView/CustomScrollView the rubber-band bounce-back at
/// the edges (matches Cupertino feel on every platform).
class SerenityScrollBehavior extends MaterialScrollBehavior {
  const SerenityScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }

  // Ukrywamy scrollbary globalnie — iOS-style invisible scroll (rubber-band only).
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

ThemeData buildSerenityTheme({Brightness brightness = Brightness.light}) {
  final isDark = brightness == Brightness.dark;

  // Dark mode swaps primary ↔ primaryContainer for contrast,
  // surface → inverseSurface. Subtle, not full-invert.
  final colorScheme = isDark
      ? const ColorScheme(
          brightness: Brightness.dark,
          // Voltgear-inspired dark: voltMint as accent, charcoal surfaces.
          primary: SerenityColors.voltMint,
          onPrimary: SerenityColors.voltMintInk,
          primaryContainer: SerenityColors.groupedSurfaceHighDark,
          onPrimaryContainer: SerenityColors.onSurfaceDark,
          secondary: SerenityColors.secondaryContainer,
          onSecondary: SerenityColors.onSecondaryFixed,
          secondaryContainer: SerenityColors.groupedSurfaceDark,
          onSecondaryContainer: SerenityColors.secondaryContainer,
          tertiary: SerenityColors.glowAlertCoral,
          onTertiary: SerenityColors.onTertiary,
          tertiaryContainer: SerenityColors.tertiary,
          onTertiaryContainer: SerenityColors.onTertiaryContainer,
          error: SerenityColors.errorContainer,
          onError: SerenityColors.onErrorContainer,
          errorContainer: SerenityColors.error,
          onErrorContainer: SerenityColors.errorContainer,
          surface: SerenityColors.groupedBackgroundDark,
          onSurface: SerenityColors.onSurfaceDark,
          surfaceContainerLowest: SerenityColors.groupedSurfaceDark,
          surfaceContainerLow: SerenityColors.groupedSurfaceDark,
          surfaceContainer: SerenityColors.groupedSurfaceDark,
          surfaceContainerHigh: SerenityColors.groupedSurfaceHighDark,
          surfaceContainerHighest: SerenityColors.groupedSurfaceHighDark,
          onSurfaceVariant: SerenityColors.secondaryLabelDark,
          outline: SerenityColors.separatorDark,
          outlineVariant: SerenityColors.separatorDark,
          inverseSurface: SerenityColors.surface,
          onInverseSurface: SerenityColors.onSurface,
          inversePrimary: SerenityColors.primary,
        )
      : const ColorScheme(
          brightness: Brightness.light,
          primary: SerenityColors.primary,
          onPrimary: SerenityColors.onPrimary,
          primaryContainer: SerenityColors.primaryContainer,
          onPrimaryContainer: SerenityColors.onPrimary,
          secondary: SerenityColors.secondary,
          onSecondary: SerenityColors.onSecondary,
          secondaryContainer: SerenityColors.secondaryContainer,
          onSecondaryContainer: SerenityColors.onSecondaryContainer,
          tertiary: SerenityColors.tertiary,
          onTertiary: SerenityColors.onTertiary,
          tertiaryContainer: SerenityColors.tertiaryContainer,
          onTertiaryContainer: SerenityColors.onTertiaryContainer,
          error: SerenityColors.error,
          onError: SerenityColors.onError,
          errorContainer: SerenityColors.errorContainer,
          onErrorContainer: SerenityColors.onErrorContainer,
          surface: SerenityColors.surface,
          onSurface: SerenityColors.onSurface,
          surfaceContainerHighest: SerenityColors.surfaceContainerHighest,
          onSurfaceVariant: SerenityColors.onSurfaceVariant,
          outline: SerenityColors.outline,
          outlineVariant: SerenityColors.outlineVariant,
          inverseSurface: SerenityColors.inverseSurface,
          onInverseSurface: SerenityColors.inverseOnSurface,
          inversePrimary: SerenityColors.inversePrimary,
        );

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    fontFamily: 'Inter',

    // Przełączniki: w trybie ciemnym off-state miał ciemny tor zlewający się
    // z kafelkiem. Dajemy jaśniejszy tor + wyraźny obrys + jasny kciuk.
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return colorScheme.onPrimary;
        return isDark ? const Color(0xFFAEB6C2) : null;
      }),
      trackColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return colorScheme.primary;
        return isDark ? const Color(0xFF2A323D) : null;
      }),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) {
        if (s.contains(WidgetState.selected)) return Colors.transparent;
        return isDark ? const Color(0xFF4A5560) : null;
      }),
    ),
    scaffoldBackgroundColor: colorScheme.surface,
    canvasColor: colorScheme.surface,

    // iOS-style page transitions globally (slide-right + parallax).
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: <TargetPlatform, PageTransitionsBuilder>{
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.linux: CupertinoPageTransitionsBuilder(),
        TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
        TargetPlatform.windows: CupertinoPageTransitionsBuilder(),
      },
    ),

    textTheme: _textTheme(colorScheme),

    // App bar — flat, transparent, light text
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: colorScheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: SerenityText.headlineHeroMobile.copyWith(
        color: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurface),
    ),

    // Buttons — pill-shaped, primaryContainer fill, white text
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimary,
        textStyle: SerenityText.labelButton,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimary,
        textStyle: SerenityText.labelButton,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: const StadiumBorder(),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: SerenityText.labelButton,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        textStyle: SerenityText.labelButton,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: BorderSide(color: colorScheme.primary.withValues(alpha: 0.1)),
        shape: const StadiumBorder(),
      ),
    ),

    // FAB — pill with icon + label, primaryContainer
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: colorScheme.primaryContainer,
      foregroundColor: colorScheme.onPrimary,
      elevation: 0,
      highlightElevation: 4,
      extendedIconLabelSpacing: 8,
      extendedPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      extendedTextStyle: SerenityText.labelButton,
      shape: const StadiumBorder(),
    ),

    // Cards — soft shadow, 24px radius, white
    cardTheme: CardThemeData(
      color: colorScheme.surfaceContainerLowest,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: SerenityShapes.card()),
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
    ),

    // Inputs — soft fill, no hard border, 24px radius
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: colorScheme.surfaceContainerLow,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: SerenityShapes.input(),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: SerenityShapes.input(),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: SerenityShapes.input(),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: SerenityShapes.input(),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      labelStyle: SerenityText.labelButton.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      hintStyle: SerenityText.bodyMain.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),

    // Chips — rounded, subtle
    chipTheme: ChipThemeData(
      backgroundColor: colorScheme.surfaceContainer,
      labelStyle: SerenityText.labelButton,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SerenityShapes.radiusFull),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),

    // Divider — hairline, subtle
    dividerTheme: const DividerThemeData(
      color: SerenityColors.outlineVariant,
      thickness: 1,
      space: 1,
    ),

    // Icons — match text weight (thin)
    iconTheme: IconThemeData(color: colorScheme.onSurface, size: 24),

    // NavigationBar (Material 3) — fallback when not using custom pill nav
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: colorScheme.primaryContainer,
      indicatorColor: colorScheme.onPrimary.withValues(alpha: 0.12),
      labelTextStyle: WidgetStatePropertyAll(
        SerenityText.labelCaps.copyWith(color: colorScheme.onPrimary),
      ),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: colorScheme.onPrimary.withValues(
            alpha: states.contains(WidgetState.selected) ? 1.0 : 0.5,
          ),
        );
      }),
    ),

    // BottomSheet — rounded top, clean
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),

    // Dialog
    dialogTheme: DialogThemeData(
      backgroundColor: colorScheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(SerenityShapes.radiusXl),
      ),
      titleTextStyle: SerenityText.headlineHeroMobile.copyWith(
        color: colorScheme.primary,
      ),
      contentTextStyle: SerenityText.bodyMain.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
    ),
  );
}

TextTheme _textTheme(ColorScheme c) {
  // Map M3 default text roles to Serenity tokens.
  return TextTheme(
    displayLarge: SerenityText.displayLg.copyWith(color: c.onSurface),
    displayMedium: SerenityText.displayMd.copyWith(color: c.onSurface),
    displaySmall: SerenityText.headlineHero.copyWith(color: c.onSurface),
    headlineLarge: SerenityText.headlineHero.copyWith(color: c.onSurface),
    headlineMedium: SerenityText.headlineHeroMobile.copyWith(color: c.onSurface),
    headlineSmall: SerenityText.headlineHeroMobile.copyWith(
      color: c.onSurface,
      fontSize: 24,
    ),
    titleLarge: SerenityText.labelButton.copyWith(
      fontSize: 20,
      color: c.onSurface,
    ),
    titleMedium: SerenityText.labelButton.copyWith(
      fontSize: 16,
      color: c.onSurface,
    ),
    titleSmall: SerenityText.labelButton.copyWith(color: c.onSurface),
    bodyLarge: SerenityText.bodyMain.copyWith(color: c.onSurface),
    bodyMedium: SerenityText.bodyMain.copyWith(color: c.onSurfaceVariant),
    bodySmall: SerenityText.bodyMain.copyWith(
      fontSize: 14,
      color: c.onSurfaceVariant,
    ),
    labelLarge: SerenityText.labelButton.copyWith(color: c.onSurface),
    labelMedium: SerenityText.labelCaps.copyWith(color: c.onSurfaceVariant),
    labelSmall: SerenityText.labelCaps.copyWith(
      color: c.onSurfaceVariant,
      fontSize: 11,
    ),
  );
}
