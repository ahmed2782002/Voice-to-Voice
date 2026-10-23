import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/feature/splash/presentation/view/screen/splash_screen.dart';
import 'package:voice_to_voice/feature/splash/presentation/view_model/splash_motion.dart';

import '../../helpers/pump_app.dart';

void main() {
  group('SplashScreen', () {
    testWidgets('shows the brand and then opens the next screen', (
      tester,
    ) async {
      await tester.pumpShell(
        SplashScreen(
          next: (_) => const Scaffold(body: Text('home', key: Key('home'))),
        ),
      );

      expect(find.byKey(const Key('splash_screen')), findsOneWidget);
      expect(find.byKey(const Key('home')), findsNothing);

      await tester.pump(SplashMotion.duration);
      expect(find.text('VoxBridge'), findsOneWidget);
      expect(
        find.text('Speak once. Be understood everywhere.'),
        findsOneWidget,
      );

      await tester.pumpAndSettle();

      expect(find.byKey(const Key('home')), findsOneWidget);
      expect(find.byKey(const Key('splash_screen')), findsNothing);
    });

    testWidgets('renders in Arabic on a small phone without overflow', (
      tester,
    ) async {
      await tester.pumpShell(
        SplashScreen(next: (_) => const SizedBox.shrink()),
        locale: const Locale('ar'),
        size: const Size(320, 640),
      );

      await tester.pump(SplashMotion.duration * 0.8);

      expect(find.text('تكلّم بلغتك، ويفهمك العالم.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
