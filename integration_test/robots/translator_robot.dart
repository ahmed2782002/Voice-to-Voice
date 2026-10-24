import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_app.dart';
import '../helpers/waiters.dart';

class TranslatorRobot {
  TranslatorRobot(this.tester, this.app);

  final WidgetTester tester;
  final TestApp app;

  static const record = Key('translator_recordButton');
  static const translate = Key('translator_translateButton');
  static const sourceCard = Key('translator_sourceCard');
  static const translatedCard = Key('translator_translatedCard');
  static const errorCard = Key('translator_errorCard');
  static const errorAction = Key('translator_errorAction');
  static const aiNotice = Key('translator_aiNotice');
  static const offline = Key('translator_offline');
  static const retryConnection = Key('noConnection_retry');
  static const menu = Key('translator_menuButton');

  Future<void> recordVoice({
    Duration length = const Duration(seconds: 3),
  }) async {
    await tester.tapVisible(find.byKey(record));
    await tester.pumpUntilFound(
      find.byKey(const Key('translator_recordTimer')),
    );
    app.recorder.amplitude.add(0.7);
    await tester.pump();
    app.clock.advance(length);
    await tester.tapVisible(find.byKey(record));
    await tester.pumpUntilFound(
      find.byKey(const Key('translator_source_play')),
    );
  }

  Future<void> translateAndWait() async {
    await tester.tapVisible(find.byKey(translate));
    await tester.pumpUntilFound(find.byKey(translatedCard));
  }

  Future<void> openMenu(String action) async {
    await tester.tap(find.byKey(menu));
    await tester.pumpUntilFound(find.byKey(Key('translator_menu_$action')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(Key('translator_menu_$action')));
    await tester.pumpAndSettle();
  }
}
