import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

/// Semantic design tokens (DESIGN.md §3, mirrored in packages/ui/tokens.json).
///
/// Components must consume these via `TqTokens.of(context)` rather than
/// hardcoding hex values, so light/dark modes both meet WCAG AA contrast.
class TqTokens extends ThemeExtension<TqTokens> {
  const TqTokens({
    required this.primary,
    required this.primaryOn,
    required this.surface,
    required this.surfaceVariant,
    required this.background,
    required this.textBase,
    required this.textSubtle,
    required this.priorityHigh,
    required this.priorityHighBg,
    required this.priorityMed,
    required this.priorityMedBg,
    required this.priorityLow,
    required this.priorityLowBg,
    required this.priorityCritical,
    required this.priorityCriticalBg,
  });

  final Color primary;
  final Color primaryOn;
  final Color surface;
  final Color surfaceVariant;
  final Color background;
  final Color textBase;
  final Color textSubtle;
  final Color priorityHigh;
  final Color priorityHighBg;
  final Color priorityMed;
  final Color priorityMedBg;
  final Color priorityLow;
  final Color priorityLowBg;
  final Color priorityCritical;
  final Color priorityCriticalBg;

  static const light = TqTokens(
    primary: Color(0xFF2D593E),
    primaryOn: Color(0xFFFFFFFF),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF0F2F1),
    background: Color(0xFFF0F2F1),
    textBase: Color(0xFF000000),
    textSubtle: Color(0xFF595F5D),
    priorityHigh: Color(0xFFD93644),
    priorityHighBg: Color(0xFFF9E0E3),
    priorityMed: Color(0xFFE69200),
    priorityMedBg: Color(0xFFF7EBD4),
    priorityLow: Color(0xFF218A32),
    priorityLowBg: Color(0xFFDEF0E1),
    priorityCritical: Color(0xFF9B1D1D),
    priorityCriticalBg: Color(0xFFF6DADA),
  );

  static const dark = TqTokens(
    primary: Color(0xFF58976C),
    primaryOn: Color(0xFFFFFFFF),
    surface: Color(0xFF1A1D1E),
    surfaceVariant: Color(0xFF222628),
    background: Color(0xFF121415),
    textBase: Color(0xFFE0E3E1),
    textSubtle: Color(0xFF8C9290),
    priorityHigh: Color(0xFFEE6773),
    priorityHighBg: Color(0xFF4B1C22),
    priorityMed: Color(0xFFFFC14D),
    priorityMedBg: Color(0xFF4A3A14),
    priorityLow: Color(0xFF57CB72),
    priorityLowBg: Color(0xFF16391E),
    priorityCritical: Color(0xFFF08080),
    priorityCriticalBg: Color(0xFF5C1519),
  );

  static TqTokens of(BuildContext context) =>
      Theme.of(context).extension<TqTokens>() ??
      (Theme.of(context).brightness == Brightness.dark ? dark : light);

  @override
  TqTokens copyWith({
    Color? primary,
    Color? primaryOn,
    Color? surface,
    Color? surfaceVariant,
    Color? background,
    Color? textBase,
    Color? textSubtle,
    Color? priorityHigh,
    Color? priorityHighBg,
    Color? priorityMed,
    Color? priorityMedBg,
    Color? priorityLow,
    Color? priorityLowBg,
    Color? priorityCritical,
    Color? priorityCriticalBg,
  }) {
    return TqTokens(
      primary: primary ?? this.primary,
      primaryOn: primaryOn ?? this.primaryOn,
      surface: surface ?? this.surface,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      background: background ?? this.background,
      textBase: textBase ?? this.textBase,
      textSubtle: textSubtle ?? this.textSubtle,
      priorityHigh: priorityHigh ?? this.priorityHigh,
      priorityHighBg: priorityHighBg ?? this.priorityHighBg,
      priorityMed: priorityMed ?? this.priorityMed,
      priorityMedBg: priorityMedBg ?? this.priorityMedBg,
      priorityLow: priorityLow ?? this.priorityLow,
      priorityLowBg: priorityLowBg ?? this.priorityLowBg,
      priorityCritical: priorityCritical ?? this.priorityCritical,
      priorityCriticalBg: priorityCriticalBg ?? this.priorityCriticalBg,
    );
  }

  @override
  TqTokens lerp(TqTokens? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return TqTokens(
      primary: mix(primary, other.primary),
      primaryOn: mix(primaryOn, other.primaryOn),
      surface: mix(surface, other.surface),
      surfaceVariant: mix(surfaceVariant, other.surfaceVariant),
      background: mix(background, other.background),
      textBase: mix(textBase, other.textBase),
      textSubtle: mix(textSubtle, other.textSubtle),
      priorityHigh: mix(priorityHigh, other.priorityHigh),
      priorityHighBg: mix(priorityHighBg, other.priorityHighBg),
      priorityMed: mix(priorityMed, other.priorityMed),
      priorityMedBg: mix(priorityMedBg, other.priorityMedBg),
      priorityLow: mix(priorityLow, other.priorityLow),
      priorityLowBg: mix(priorityLowBg, other.priorityLowBg),
      priorityCritical: mix(priorityCritical, other.priorityCritical),
      priorityCriticalBg: mix(priorityCriticalBg, other.priorityCriticalBg),
    );
  }
}

/// Shape and spacing tokens (DESIGN.md §3).
abstract final class TqRadius {
  static const double card = 16;
  static const double button = 8;
  static const double input = 8;

  /// Badges & chips are full pills.
  static const double badge = 100;
}

/// Platform shape kit: Material 3 geometry on Android/web, iOS 26
/// continuous ("squircle") corners on Apple platforms.
class TqShapes extends ThemeExtension<TqShapes> {
  const TqShapes({
    required this.card,
    required this.input,
    required this.squircle,
  });

  final double card;
  final double input;

  /// Apple platforms use continuous superellipse corners.
  final bool squircle;

  /// Material 3 kit (Android, web, desktop).
  static const material3 = TqShapes(card: 12, input: 8, squircle: false);

  /// iOS 26 kit (iOS, macOS).
  static const ios26 = TqShapes(card: 22, input: 14, squircle: true);

  static TqShapes of(BuildContext context) =>
      Theme.of(context).extension<TqShapes>() ?? material3;

  ShapeBorder get cardShape => squircle
      // Continuous rectangles need ~1.8x the radius to read the same.
      ? ContinuousRectangleBorder(
          borderRadius: BorderRadius.circular(card * 1.8))
      : RoundedRectangleBorder(borderRadius: BorderRadius.circular(card));

  @override
  TqShapes copyWith({double? card, double? input, bool? squircle}) {
    return TqShapes(
      card: card ?? this.card,
      input: input ?? this.input,
      squircle: squircle ?? this.squircle,
    );
  }

  @override
  TqShapes lerp(TqShapes? other, double t) {
    if (other == null) return this;
    return TqShapes(
      card: lerpDouble(card, other.card, t) ?? card,
      input: lerpDouble(input, other.input, t) ?? input,
      squircle: t < 0.5 ? squircle : other.squircle,
    );
  }
}

abstract final class TqSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Minimum interactive target size (WCAG / DESIGN.md §2).
const double kTqMinTouchTarget = 48;

/// Legacy named colors, aligned to the light-mode token values.
/// Prefer `TqTokens.of(context)` in new code.
abstract final class TqColors {
  static const forestGreen = Color(0xFF2D593E);
  static const forestGreenDark = Color(0xFF224731);
  static const forestGreenLight = Color(0xFF58976C);
  static const moss = Color(0xFF58976C);
  static const cream = Color(0xFFF0F2F1);
  static const sand = Color(0xFFE1E5E3);
  static const bark = Color(0xFF000000);
  static const charcoal = Color(0xFF121415);
  static const slate = Color(0xFF595F5D);
  static const mist = Color(0xFF8C9290);

  static const priorityHigh = Color(0xFFD93644);
  static const priorityMedium = Color(0xFFE69200);
  static const priorityLow = Color(0xFF218A32);
  static const priorityCritical = Color(0xFF9B1D1D);

  static const darkSurface = Color(0xFF121415);
  static const darkCard = Color(0xFF1A1D1E);
  static const darkElevated = Color(0xFF222628);
}
