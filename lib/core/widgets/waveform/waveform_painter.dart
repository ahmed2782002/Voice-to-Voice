import 'package:flutter/material.dart';

class WaveformPainter extends CustomPainter {
  const WaveformPainter({
    required this.levels,
    required this.progress,
    required this.activeColor,
    required this.inactiveColor,
    required this.textDirection,
  });

  final List<double> levels;
  final double progress;
  final Color activeColor;
  final Color inactiveColor;
  final TextDirection textDirection;

  @override
  void paint(Canvas canvas, Size size) {
    if (levels.isEmpty) return;
    final slot = size.width / levels.length;
    final barWidth = slot * 0.55;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = barWidth;
    final center = size.height / 2;
    for (var index = 0; index < levels.length; index++) {
      final level = levels[index].clamp(0.06, 1.0);
      final half = size.height * level / 2;
      final offset = slot * index + slot / 2;
      final x = textDirection == TextDirection.rtl
          ? size.width - offset
          : offset;
      paint.color = (index + 0.5) / levels.length <= progress
          ? activeColor
          : inactiveColor;
      canvas.drawLine(
        Offset(x, center - half),
        Offset(x, center + half),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.levels != levels ||
      oldDelegate.progress != progress ||
      oldDelegate.activeColor != activeColor ||
      oldDelegate.inactiveColor != inactiveColor ||
      oldDelegate.textDirection != textDirection;
}
