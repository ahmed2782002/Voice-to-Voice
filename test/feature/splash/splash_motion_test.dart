import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/feature/splash/presentation/view_model/splash_motion.dart';

void main() {
  group('SplashMotion', () {
    test('grows the logo from a small seed to full size', () {
      expect(SplashMotion.logoScale(0), closeTo(0.35, 0.001));
      expect(SplashMotion.logoScale(1), closeTo(1, 0.001));
      expect(SplashMotion.logoOpacity(0), 0);
      expect(SplashMotion.logoTurn(1), closeTo(0, 0.001));
    });

    test('reveals the title after the logo and settles it in place', () {
      expect(SplashMotion.titleOpacity(0.2), 0);
      expect(SplashMotion.titleOpacity(1), 1);
      expect(SplashMotion.titleOffset(1), 0);
    });

    test('keeps every ring phase inside one cycle', () {
      for (final t in [0.0, 0.3, 0.77, 1.0]) {
        final phases = SplashMotion.ringPhases(t);
        expect(phases, hasLength(SplashMotion.ringCount));
        expect(phases.every((phase) => phase >= 0 && phase < 1), isTrue);
      }
    });

    test('keeps the waveform flat until its entrance', () {
      expect(SplashMotion.bars(0).every((level) => level == 0), isTrue);
      final settled = SplashMotion.bars(1);
      expect(settled, hasLength(SplashMotion.barCount));
      expect(settled.every((level) => level >= 0 && level <= 1), isTrue);
    });
  });
}
