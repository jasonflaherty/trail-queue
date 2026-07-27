import 'package:flutter/material.dart';

import '../colors.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.showWordmark = true, this.compact = false});

  final bool showWordmark;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final size = compact ? 28.0 : 36.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomPaint(
          size: Size(size, size),
          painter: _MountainPainter(),
        ),
        if (showWordmark) ...[
          const SizedBox(width: 10),
          Text(
            'TRAIL QUEUE',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              fontSize: compact ? 14 : 16,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ],
    );
  }
}

class _MountainPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = TqColors.forestGreen
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(size.width * 0.08, size.height * 0.85)
      ..lineTo(size.width * 0.38, size.height * 0.28)
      ..lineTo(size.width * 0.55, size.height * 0.55)
      ..lineTo(size.width * 0.72, size.height * 0.22)
      ..lineTo(size.width * 0.92, size.height * 0.85)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
