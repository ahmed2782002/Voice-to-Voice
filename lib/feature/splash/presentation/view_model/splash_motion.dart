import 'dart:math' as math;

import 'package:flutter/animation.dart';

abstract final class SplashMotion {
  static const Duration duration = Duration(milliseconds: 2800);
  static const Duration exit = Duration(milliseconds: 450);
  static const int ringCount = 3;
  static const int barCount = 28;

  static const Interval _logoIn = Interval(0, 0.42, curve: Curves.elasticOut);
  static const Interval _logoFade = Interval(0, 0.18, curve: Curves.easeOut);
  static const Interval _logoTurn = Interval(0, 0.5, curve: Curves.easeOutBack);
  static const Interval _ringsIn = Interval(0.12, 0.32, curve: Curves.easeOut);
  static const Interval _title = Interval(
    0.32,
    0.58,
    curve: Curves.easeOutCubic,
  );
  static const Interval _tagline = Interval(
    0.46,
    0.72,
    curve: Curves.easeOutCubic,
  );
  static const Interval _bars = Interval(0.55, 0.8, curve: Curves.easeOut);

  static double logoScale(double t) => 0.35 + 0.65 * _logoIn.transform(t);

  static double logoOpacity(double t) => _logoFade.transform(t);

  static double logoTurn(double t) => (1 - _logoTurn.transform(t)) * -0.6;

  static double ringsOpacity(double t) => _ringsIn.transform(t);

  static List<double> ringPhases(double t) =>
      List.generate(ringCount, (index) => (t * 1.8 + index / ringCount) % 1);

  static double titleOpacity(double t) => _title.transform(t);

  static double titleOffset(double t) => (1 - _title.transform(t)) * 28;

  static double taglineOpacity(double t) => _tagline.transform(t);

  static double taglineOffset(double t) => (1 - _tagline.transform(t)) * 18;

  static List<double> bars(double t) {
    final envelope = _bars.transform(t);
    return List.generate(barCount, (index) {
      final wave = math.sin(t * math.pi * 6 + index * 0.55).abs();
      final shape = math.sin((index + 1) / (barCount + 1) * math.pi);
      return (0.15 + 0.85 * wave * shape) * envelope;
    });
  }
}
