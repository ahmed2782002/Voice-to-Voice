import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';
import 'helpers/waiters.dart';
import 'robots/translator_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestApp app;

  tearDown(() async => app.dispose());

  group('Offline flow', () {
    testWidgets('user opens the app offline and sees the offline page', (
      tester,
    ) async {
      app = await TestApp.create(online: false);
      app.server.languagesDown = true;

      await app.launch(tester);
      await tester.pumpUntilFound(find.byKey(TranslatorRobot.offline));

      expect(find.text("You're offline"), findsOneWidget);
      await tester.pumpUntilGone(find.byKey(TranslatorRobot.record));
    });

    testWidgets(
      'the app comes back and reloads languages when the network returns',
      (tester) async {
        app = await TestApp.create(online: false);
        app.server.languagesDown = true;
        await app.launch(tester);
        await tester.pumpUntilFound(find.byKey(TranslatorRobot.offline));

        app.server.languagesDown = false;
        app.connectivity.emit(true);
        await tester.pumpUntilFound(find.byKey(TranslatorRobot.record));

        await tester.pumpUntilGone(find.byKey(TranslatorRobot.offline));
        expect(
          app.server.paths.where((path) => path.endsWith('/languages')),
          hasLength(2),
        );
      },
    );

    testWidgets('user loses the network while recording', (tester) async {
      app = await TestApp.create();
      await app.launch(tester);
      await tester.pumpUntilFound(find.byKey(TranslatorRobot.record));

      await tester.tapVisible(find.byKey(TranslatorRobot.record));
      app.connectivity.emit(false);
      await tester.pumpUntilFound(find.byKey(TranslatorRobot.offline));

      app.connectivity.online = true;
      await tester.tapVisible(find.byKey(TranslatorRobot.retryConnection));
      await tester.pumpUntilFound(find.byKey(TranslatorRobot.record));

      await tester.pumpUntilGone(find.byKey(TranslatorRobot.offline));
    });
  });
}
