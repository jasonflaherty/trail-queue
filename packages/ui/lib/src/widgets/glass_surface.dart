import 'dart:ui';

import 'package:flutter/material.dart';

import '../colors.dart';

/// Frosted translucent surface in the iOS 26 "Liquid Glass" style:
/// a backdrop blur under a tinted, mostly-transparent layer.
///
/// On non-Apple platforms prefer solid surfaces; this widget is used where
/// the iOS 26 theme wants floating glass (e.g. the bottom tab bar).
class TqGlassSurface extends StatelessWidget {
  const TqGlassSurface({
    super.key,
    required this.child,
    this.blur = 24,
    this.opacity = 0.75,
    this.borderRadius = BorderRadius.zero,
  });

  final Widget child;
  final double blur;
  final double opacity;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    final tokens = TqTokens.of(context);
    return ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: ColoredBox(
          color: tokens.surface.withValues(alpha: opacity),
          child: child,
        ),
      ),
    );
  }
}
