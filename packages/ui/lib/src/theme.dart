import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'colors.dart';

/// App themes built from the semantic tokens in DESIGN.md §3.
abstract final class TrailQueueTheme {
  static ThemeData get light => _build(TqTokens.light, Brightness.light);

  static ThemeData get dark => _build(TqTokens.dark, Brightness.dark);

  static ThemeData _build(TqTokens tokens, Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(
        seedColor: tokens.primary,
        brightness: brightness,
      ).copyWith(
        primary: tokens.primary,
        onPrimary: tokens.primaryOn,
        surface: tokens.surface,
        onSurface: tokens.textBase,
        surfaceContainerHighest: tokens.surfaceVariant,
        error: tokens.priorityHigh,
      ),
      scaffoldBackgroundColor: tokens.background,
      extensions: [tokens],
    );

    // DESIGN.md §3: Inter / system sans, dynamic type friendly (no fixed
    // heights; sizes come from the Material scale and honor textScaler).
    final text = GoogleFonts.interTextTheme(base.textTheme).copyWith(
      displayLarge: GoogleFonts.inter(
          textStyle: base.textTheme.displayLarge, fontWeight: FontWeight.w700),
      displayMedium: GoogleFonts.inter(
          textStyle: base.textTheme.displayMedium, fontWeight: FontWeight.w700),
      displaySmall: GoogleFonts.inter(
          textStyle: base.textTheme.displaySmall, fontWeight: FontWeight.w700),
      headlineLarge: GoogleFonts.inter(
          textStyle: base.textTheme.headlineLarge, fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.inter(
          textStyle: base.textTheme.headlineMedium,
          fontWeight: FontWeight.w700),
      headlineSmall: GoogleFonts.inter(
          textStyle: base.textTheme.headlineSmall, fontWeight: FontWeight.w700),
      titleLarge: GoogleFonts.inter(
          textStyle: base.textTheme.titleLarge, fontWeight: FontWeight.w700),
      titleMedium: GoogleFonts.inter(
          textStyle: base.textTheme.titleMedium, fontWeight: FontWeight.w600),
    );

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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TqRadius.card),
        ),
      ),
      chipTheme: base.chipTheme.copyWith(shape: const StadiumBorder()),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: tokens.primary,
          foregroundColor: tokens.primaryOn,
          minimumSize: const Size.fromHeight(52),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TqRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: tokens.textBase,
          backgroundColor: tokens.surfaceVariant,
          minimumSize: const Size.fromHeight(52),
          side: BorderSide(color: tokens.textSubtle.withValues(alpha: 0.4)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(TqRadius.button),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: tokens.surface,
        hintStyle: TextStyle(color: tokens.textSubtle),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TqRadius.input),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TqRadius.input),
          borderSide: BorderSide(color: tokens.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: tokens.surface,
        indicatorColor: tokens.primary.withValues(alpha: 0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? tokens.primary : tokens.textSubtle,
          );
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TqRadius.card)),
        ),
      ),
    );
  }
}
