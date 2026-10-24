import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:voice_to_voice/feature/translator/presentation/view/screen/translator_screen.dart';

import 'helpers/test_app.dart';
import 'helpers/waiters.dart';
import 'robots/translator_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestApp app;

  setUp(() async => app = await TestApp.create());

  tearDown(() async => app.dispose());

  Brightness brightness(WidgetTester tester) =>
      Theme.of(tester.element(find.byType(TranslatorScreen))).brightness;

  group('Settings flow', () {
    testWidgets('user switches to Arabic and keeps it after a restart', (
      tester,
    ) async {
      await app.launch(tester);
      final robot = TranslatorRobot(tester, app);

      await robot.openMenu('language');
      await tester.pumpUntilFound(
        find.byKey(const Key('settings_language_ar')),
      );
      await tester.tap(find.byKey(const Key('settings_language_ar')));
      await tester.pumpUntilFound(find.text('ترجم الصوت'));

      await app.relaunch(tester);
      await tester.pumpUntilFound(find.text('ترجم الصوت'));

      expect(find.text('Translate Voice'), findsNothing);
    });

    testWidgets('user switches to light mode and keeps it after a restart', (
      tester,
    ) async {
      await app.launch(tester);
      final robot = TranslatorRobot(tester, app);
      expect(brightness(tester), Brightness.dark);

      await robot.openMenu('theme');
      await tester.pumpUntilFound(
        find.byKey(const Key('settings_theme_light')),
      );
      await tester.tap(find.byKey(const Key('settings_theme_light')));
      await tester.pumpUntilGone(find.byKey(const Key('settings_theme_light')));

      expect(brightness(tester), Brightness.light);

      await app.relaunch(tester);

      expect(brightness(tester), Brightness.light);
    });
  });
}
