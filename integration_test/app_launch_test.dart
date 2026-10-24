import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';
import 'helpers/waiters.dart';
import 'robots/translator_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestApp app;

  setUp(() async => app = await TestApp.create());

  tearDown(() async => app.dispose());

  group('App launch', () {
    testWidgets(
      'user opens the app and lands on the translator after the splash',
      (tester) async {
        await app.launch(tester);

        expect(find.byKey(const Key('splash_screen')), findsNothing);
        expect(find.text('Translate Voice'), findsOneWidget);
        expect(find.byKey(TranslatorRobot.aiNotice), findsOneWidget);
        expect(find.byKey(TranslatorRobot.record), findsOneWidget);
      },
    );

    testWidgets('loads target languages from the server on launch', (
      tester,
    ) async {
      await app.launch(tester);
      await tester.pumpUntilFound(find.byKey(TranslatorRobot.record));

      await tester.tapVisible(
        find.byKey(const Key('translator_languageSelector')),
      );
      await tester.pumpUntilFound(find.text('Choose a language'));

      expect(app.server.paths, contains(endsWith('/languages')));
      expect(find.text('3 supported spoken languages'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);
    });
  });
}
