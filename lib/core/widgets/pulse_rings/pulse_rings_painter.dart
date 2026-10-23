import 'dart:math' as math;

import 'package:flutter/rendering.dart';

class PulseRingsPainter extends CustomPainter {
  const PulseRingsPainter({
    required this.phases,
    required this.opacity,
    required this.color,
    required this.innerRadius,
  });

  final List<double> phases;
  final double opacity;
  final Color color;
  final double innerRadius;

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;
    final center = size.center(Offset.zero);
    final outerRadius = math.min(size.width, size.height) / 2;
    for (final phase in phases) {
      final radius = innerRadius + (outerRadius - innerRadius) * phase;
      final fade = (1 - phase) * opacity;
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2 + 2 * (1 - phase)
          ..color = color.withValues(alpha: 0.55 * fade),
      );
    }
  }

  @override
  bool shouldRepaint(PulseRingsPainter oldDelegate) =>
      oldDelegate.phases != phases ||
      oldDelegate.opacity != opacity ||
      oldDelegate.color != color ||
      oldDelegate.innerRadius != innerRadius;
}
