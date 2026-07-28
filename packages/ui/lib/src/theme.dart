import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// Platform-adaptive app themes built from the semantic tokens in
/// DESIGN.md §3.
///
/// - Android / web / desktop: Material Design 3 kit (seeded ColorScheme,
///   M3 shapes, Inter type).
/// - iOS / macOS: iOS 26 kit (SF system type, capsule buttons, continuous
///   "squircle" corners, Cupertino transitions, no ink splash).
abstract final class TrailQueueTheme {
  static ThemeData get light => build(brightness: Brightness.light);

  static ThemeData get dark => build(brightness: Brightness.dark);

  static ThemeData build({
    required Brightness brightness,
    TargetPlatform? platform,
  }) {
    platform ??= defaultTargetPlatform;
    final tokens =
        brightness == Brightness.dark ? TqTokens.dark : TqTokens.light;
    final isApple = platform == TargetPlatform.iOS ||
        platform == TargetPlatform.macOS;
    return isApple
        ? _ios26(tokens, brightness, platform)
        : _material3(tokens, brightness);
  }

  static ColorScheme _scheme(TqTokens tokens, Brightness brightness) {
    return ColorScheme.fromSeed(
      seedColor: tokens.primary,
      brightness: brightness,
    ).copyWith(
      primary: tokens.primary,
      onPrimary: tokens.primaryOn,
      surface: tokens.surface,
      onSurface: tokens.textBase,
      surfaceContainerHighest: tokens.surfaceVariant,
      error: tokens.priorityHigh,
    );
  }

  // ---------------------------------------------------------------------
  // Material Design 3 kit (Android, web, desktop)
  // ---------------------------------------------------------------------

  static ThemeData _material3(TqTokens tokens, Brightness brightness) {
    const shapes = TqShapes.material3;
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: _scheme(tokens, brightness),
      scaffoldBackgroundColor: tokens.background,
      extensions: [tokens, shapes],
    );

    final text = _interTextTheme(base.textTheme);

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        foregroundColor: tokens.textBase,
        titleTextStyle: text.titleLarge?.copyWith(color: tokens.textBase),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        shape: shapes.cardShape,
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      // M3 filled buttons are full pills by default; we only pin brand
      // colors and a >=48dp touch target.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.primaryOn,
          minimumSize: const Size.fromHeight(52),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textBase,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: tokens.textSubtle.withValues(alpha: 0.4)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: _inputTheme(tokens, shapes),
      navigationBarTheme: _navBarTheme(tokens, opaque: true),
      bottomSheetTheme: BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(shapes.card + 4)),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // iOS 26 kit (iOS, macOS)
  // ---------------------------------------------------------------------

  static ThemeData _ios26(
    TqTokens tokens,
    Brightness brightness,
    TargetPlatform platform,
  ) {
    const shapes = TqShapes.ios26;
    // Leaving fontFamily unset with an Apple platform gives the SF system
    // fonts (matching iOS 26 typography) and native scroll physics.
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      platform: platform,
      colorScheme: _scheme(tokens, brightness),
      scaffoldBackgroundColor: tokens.background,
      splashFactory: NoSplash.splashFactory,
      highlightColor: tokens.textBase.withValues(alpha: 0.06),
      extensions: [tokens, shapes],
    );

    return base.copyWith(
      cupertinoOverrideTheme: NoDefaultCupertinoThemeData(
        brightness: brightness,
        primaryColor: tokens.primary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        foregroundColor: tokens.textBase,
        titleTextStyle: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.4,
          color: tokens.textBase,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: tokens.surface,
        shape: shapes.cardShape,
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      // iOS 26 action buttons are capsules.
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.primaryOn,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textBase,
          backgroundColor: tokens.surfaceVariant.withValues(alpha: 0.7),
          minimumSize: const Size.fromHeight(52),
          side: BorderSide.none,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 17,
            letterSpacing: -0.4,
          ),
        ),
      ),
      inputDecorationTheme: _inputTheme(tokens, shapes),
      // Translucent bar; AppBottomNav adds the frosted-glass blur behind it.
      navigationBarTheme: _navBarTheme(tokens, opaque: false),
      bottomSheetTheme: BottomSheetThemeData(
        shape: ContinuousRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(shapes.card * 1.8),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------
  // Shared pieces
  // ---------------------------------------------------------------------

  static TextTheme _interTextTheme(TextTheme base) {
    final text = GoogleFonts.interTextTheme(base);
    TextStyle? bold(TextStyle? style) =>
        style == null ? null : GoogleFonts.inter(textStyle: style, fontWeight: FontWeight.w700);
    return text.copyWith(
      displayLarge: bold(base.displayLarge),
      displayMedium: bold(base.displayMedium),
      displaySmall: bold(base.displaySmall),
      headlineLarge: bold(base.headlineLarge),
      headlineMedium: bold(base.headlineMedium),
      headlineSmall: bold(base.headlineSmall),
      titleLarge: bold(base.titleLarge),
      titleMedium: GoogleFonts.inter(
          textStyle: base.titleMedium, fontWeight: FontWeight.w600),
    );
  }

  static InputDecorationTheme _inputTheme(TqTokens tokens, TqShapes shapes) {
    return InputDecorationTheme(
      filled: true,
      fillColor: tokens.surface,
      hintStyle: TextStyle(color: tokens.textSubtle),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(shapes.input),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(shapes.input),
        borderSide: BorderSide(color: tokens.primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static NavigationBarThemeData _navBarTheme(
    TqTokens tokens, {
    required bool opaque,
  }) {
    return NavigationBarThemeData(
      backgroundColor:
          opaque ? tokens.surface : tokens.surface.withValues(alpha: 0.75),
      elevation: 0,
      indicatorColor: tokens.primary.withValues(alpha: 0.15),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        final selected = states.contains(WidgetState.selected);
        return TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? tokens.primary : tokens.textSubtle,
        );
      }),
    );
  }
}
