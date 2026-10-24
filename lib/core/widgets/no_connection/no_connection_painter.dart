import 'dart:math' as math;

import 'package:flutter/animation.dart';
import 'package:flutter/rendering.dart';

class NoConnectionPainter extends CustomPainter {
  const NoConnectionPainter({
    required this.progress,
    required this.waveColor,
    required this.slashColor,
  });

  final double progress;
  final Color waveColor;
  final Color slashColor;

  static const Curve _slashCurve = Interval(
    0.55,
    0.9,
    curve: Curves.easeOutCubic,
  );

  static double waveOpacity(double progress, int index) => Interval(
    0.08 + 0.12 * index,
    0.3 + 0.12 * index,
    curve: Curves.easeOut,
  ).transform(progress);

  static double slashProgress(double progress) =>
      _slashCurve.transform(progress);

  @override
  void paint(Canvas canvas, Size size) {
    final width = size.width;
    final stroke = width * 0.085;
    final center = Offset(width / 2, size.height * 0.84);
    final slash = slashProgress(progress);
    final dim = 1 - 0.55 * slash;

    canvas.saveLayer(Offset.zero & size, Paint());
    canvas.drawCircle(
      center,
      width * 0.065,
      Paint()
        ..color = waveColor.withValues(alpha: waveOpacity(progress, 0) * dim),
    );
    for (var index = 1; index <= 3; index++) {
      final radius = width * (0.06 + 0.18 * index);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi * 0.75,
        math.pi * 0.5,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round
          ..color = waveColor.withValues(
            alpha: waveOpacity(progress, index) * dim,
          ),
      );
    }
    if (slash > 0) {
      final start = Offset(width * 0.14, size.height * 0.1);
      final end = Offset.lerp(
        start,
        Offset(width * 0.86, size.height * 0.94),
        slash,
      )!;
      canvas.drawLine(
        start,
        end,
        Paint()
          ..blendMode = BlendMode.clear
          ..strokeWidth = stroke * 2.4
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = slashColor
          ..strokeWidth = stroke
          ..strokeCap = StrokeCap.round,
      );
      return;
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(NoConnectionPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.waveColor != waveColor ||
      oldDelegate.slashColor != slashColor;
}
