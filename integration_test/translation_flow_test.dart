import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/fake_translator_server.dart';
import 'helpers/test_app.dart';
import 'helpers/waiters.dart';
import 'robots/translator_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestApp app;

  setUp(() async => app = await TestApp.create());

  tearDown(() async => app.dispose());

  group('Translation flow', () {
    testWidgets('user records, translates, and finds the result in history', (
      tester,
    ) async {
      await app.launch(tester);
      final robot = TranslatorRobot(tester, app);

      await robot.recordVoice();
      await robot.translateAndWait();

      expect(find.text('مرحبا بك'), findsOneWidget);
      expect(find.text('Welcome'), findsOneWidget);
      expect(find.byKey(const Key('translator_aiVoiceBadge')), findsOneWidget);
      expect(app.player.openedPath, isNotNull);
      await tester.pumpUntilGone(find.byKey(TranslatorRobot.aiNotice));

      await robot.openMenu('history');
      await tester.pumpUntilFound(find.byKey(const Key('history_screen')));
      await tester.pumpUntilFound(find.text('Welcome'));

      expect(find.text('Translation history'), findsOneWidget);
      expect(find.byKey(const Key('history_empty')), findsNothing);
    }, timeout: const Timeout(Duration(minutes: 2)));

    testWidgets(
      'user sees a rate limit error and succeeds after trying again',
      (tester) async {
        app.server.translateReplies.add(FakeTranslatorServer.rateLimited);
        await app.launch(tester);
        final robot = TranslatorRobot(tester, app);

        await robot.recordVoice();
        await tester.tapVisible(find.byKey(TranslatorRobot.translate));
        await tester.pumpUntilFound(find.byKey(TranslatorRobot.errorCard));

        expect(
          find.text(
            'Too many requests in a short time. Wait a moment and try again.',
          ),
          findsOneWidget,
        );
        expect(find.byKey(TranslatorRobot.translatedCard), findsNothing);

        await tester.tapVisible(find.byKey(TranslatorRobot.errorAction));
        await tester.pumpUntilFound(find.byKey(TranslatorRobot.translatedCard));

        expect(app.server.translateCalls, 2);
        expect(find.byKey(TranslatorRobot.errorCard), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}
