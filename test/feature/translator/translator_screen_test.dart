import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/core/services/audio/audio_recorder_service.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_result.dart';
import 'package:voice_to_voice/feature/translator/data/model/translator_api_exception.dart';
import 'package:voice_to_voice/feature/translator/presentation/view/widgets/translator_header.dart';
import 'package:voice_to_voice/feature/translator/presentation/view_model/translator_cubit.dart';

import '../../helpers/fakes.dart';
import '../../helpers/pump_app.dart';

abstract final class TranslatorKeys {
  static const record = Key('translator_recordButton');
  static const translate = Key('translator_translateButton');
  static const sourceCard = Key('translator_sourceCard');
  static const translatedCard = Key('translator_translatedCard');
  static const processingCard = Key('translator_processingCard');
  static const errorCard = Key('translator_errorCard');
  static const errorAction = Key('translator_errorAction');
  static const discard = Key('translator_source_discard');
  static const languageSelector = Key('translator_languageSelector');
  static const languageSearch = Key('translator_languageSearch');
  static const translatedPlay = Key('translator_translated_play');
  static const translatedPause = Key('translator_translated_pause');
}

void main() {
  late FakeAudioRecorderService recorder;
  late FakeAudioPlayerService player;
  late FakeTranslator translator;
  late FakeClock clock;
  late FakeLanguageLoader languages;
  late FakeAiNoticeStore aiNotice;

  setUp(() {
    recorder = FakeAudioRecorderService();
    player = FakeAudioPlayerService();
    translator = FakeTranslator();
    clock = FakeClock();
    languages = FakeLanguageLoader();
    aiNotice = FakeAiNoticeStore();
  });

  TranslatorCubit buildCubit() => TranslatorCubit(
    recorder: recorder,
    player: player,
    translate: translator.call,
    loadLanguages: languages.call,
    aiNotice: aiNotice,
    clock: clock.call,
  )..loadLanguages();

  Future<void> recordVoice(
    WidgetTester tester, {
    Duration length = const Duration(seconds: 3),
    double level = 0.6,
  }) async {
    await tester.tap(find.byKey(TranslatorKeys.record));
    await tester.pump();
    recorder.amplitude.add(level);
    await tester.pump();
    clock.advance(length);
    await tester.tap(find.byKey(TranslatorKeys.record));
    for (var cycle = 0; cycle < 3; cycle++) {
      await tester.pump();
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    }
    await tester.pump();
  }

  Future<void> tapKey(WidgetTester tester, Key key) async {
    await tester.ensureVisible(find.byKey(key));
    await tester.pump();
    await tester.tap(find.byKey(key));
  }

  Future<void> tapTranslate(WidgetTester tester) async {
    await tapKey(tester, TranslatorKeys.translate);
    await tester.pump();
  }

  group('TranslatorScreen', () {
    group('idle', () {
      testWidgets('shows the AI notice, the empty hint and a default target', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());

        expect(find.textContaining('AI-generated translation'), findsOneWidget);
        expect(
          find.text('Tap the mic and speak in any language'),
          findsOneWidget,
        );
        expect(find.text('Arabic - العربية'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.translatedCard), findsNothing);
      });

      testWidgets('does not submit when there is no recording', (tester) async {
        await tester.pumpTranslator(buildCubit());

        await tapTranslate(tester);

        expect(translator.calls, 0);
        expect(find.byKey(TranslatorKeys.processingCard), findsNothing);
      });
    });

    group('recording', () {
      testWidgets('shows the live timer while recording', (tester) async {
        await tester.pumpTranslator(buildCubit());

        await tester.tap(find.byKey(TranslatorKeys.record));
        await tester.pump();

        expect(find.text('Recording…'), findsOneWidget);
        expect(find.byKey(const Key('translator_recordTimer')), findsOneWidget);
        expect(recorder.startCalls, 1);
      });

      testWidgets('shows the original voice controls after stopping', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());

        await recordVoice(tester);

        expect(find.text('Original Voice'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.discard), findsOneWidget);
        expect(find.byKey(TranslatorKeys.errorCard), findsNothing);
      });

      testWidgets('rejects a recording shorter than one second', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());

        await recordVoice(tester, length: const Duration(milliseconds: 400));

        expect(find.textContaining('too short'), findsOneWidget);
        expect(find.text('Original Voice'), findsNothing);
        expect(recorder.deletedPaths, contains('/tmp/source.m4a'));
      });

      testWidgets('rejects a silent recording as empty', (tester) async {
        await tester.pumpTranslator(buildCubit());

        await recordVoice(tester, level: 0);

        expect(find.textContaining('No voice was detected'), findsOneWidget);
        expect(find.text('Record again'), findsOneWidget);
      });

      testWidgets('discard removes the recording and deletes its file', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapKey(tester, TranslatorKeys.discard);
        await tester.pump();

        expect(find.text('Original Voice'), findsNothing);
        expect(
          find.text('Tap the mic and speak in any language'),
          findsOneWidget,
        );
        expect(recorder.deletedPaths, contains('/tmp/source.m4a'));
      });
    });

    group('microphone permission', () {
      testWidgets('shows a retry path when permission is denied', (
        tester,
      ) async {
        recorder.permission = MicPermission.denied;
        await tester.pumpTranslator(buildCubit());

        await tester.tap(find.byKey(TranslatorKeys.record));
        await tester.pump();

        expect(
          find.textContaining('Microphone access is needed'),
          findsOneWidget,
        );
        expect(recorder.startCalls, 0);

        recorder.permission = MicPermission.granted;
        await tapKey(tester, TranslatorKeys.errorAction);
        await tester.pump();

        expect(find.text('Recording…'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.errorCard), findsNothing);
      });

      testWidgets('opens settings when permission is permanently denied', (
        tester,
      ) async {
        recorder.permission = MicPermission.permanentlyDenied;
        await tester.pumpTranslator(buildCubit());

        await tester.tap(find.byKey(TranslatorKeys.record));
        await tester.pump();
        await tapKey(tester, TranslatorKeys.errorAction);
        await tester.pump();

        expect(recorder.openSettingsCalls, 1);
      });
    });

    group('translation', () {
      testWidgets('shows processing once and ignores a duplicate submit', (
        tester,
      ) async {
        translator.pending = Completer<TranslationResult>();
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);
        await tapTranslate(tester);

        expect(find.byKey(TranslatorKeys.processingCard), findsOneWidget);
        expect(find.text('Translating…'), findsWidgets);
        expect(translator.calls, 1);

        translator.pending!.complete(
          TranslationResult(
            audioPath: '/tmp/translated.m4a',
            language: translator.requests.single,
          ),
        );
        translator.pending = null;
        await tester.pump();

        expect(find.byKey(TranslatorKeys.processingCard), findsNothing);
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
      });

      testWidgets('shows a network error with retry and no result', (
        tester,
      ) async {
        translator.error = const SocketException('offline');
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);

        expect(find.textContaining('No internet connection'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.translatedCard), findsNothing);

        translator.error = null;
        await tapKey(tester, TranslatorKeys.errorAction);
        await tester.pump();

        expect(translator.calls, 2);
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
      });

      testWidgets('removes the AI notice after the first translation', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());
        expect(find.textContaining('AI-generated translation'), findsOneWidget);
        await recordVoice(tester);

        await tapTranslate(tester);
        await tester.pumpAndSettle();

        expect(find.textContaining('AI-generated translation'), findsNothing);
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
      });

      testWidgets('never shows the AI notice once it was seen', (tester) async {
        aiNotice.seen = true;

        await tester.pumpTranslator(buildCubit());

        expect(find.textContaining('AI-generated translation'), findsNothing);
      });

      testWidgets('shows the original and translated text with the audio', (
        tester,
      ) async {
        translator.originalText = 'مرحبا بك';
        translator.translatedText = 'Welcome';
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);

        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
        expect(find.text('مرحبا بك'), findsOneWidget);
        expect(find.text('Welcome'), findsOneWidget);
      });

      testWidgets('offers a retry when the service is rate limited', (
        tester,
      ) async {
        translator.error = const TranslatorApiException(
          code: TranslatorErrorCode.rateLimited,
          statusCode: 429,
          retryable: true,
        );
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);

        expect(find.textContaining('Too many requests'), findsOneWidget);
        expect(find.text('Try again'), findsOneWidget);

        translator.error = null;
        await tapKey(tester, TranslatorKeys.errorAction);
        await tester.pump();

        expect(translator.calls, 2);
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
      });

      testWidgets('asks to record again when no speech is recognized', (
        tester,
      ) async {
        translator.error = const TranslatorApiException(
          code: TranslatorErrorCode.noSpeech,
          statusCode: 422,
        );
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);

        expect(find.textContaining('No speech was recognized'), findsOneWidget);
        expect(find.text('Record again'), findsOneWidget);
      });

      testWidgets('shows a timeout error when the service never answers', (
        tester,
      ) async {
        translator.pending = Completer<TranslationResult>();
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);

        await tapTranslate(tester);
        await tester.pump(const Duration(seconds: 91));

        expect(find.textContaining('took too long'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.translatedCard), findsNothing);
      });

      testWidgets('changing the target clears the old result and resubmits', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);
        await tapTranslate(tester);
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);

        await tester.ensureVisible(find.byKey(TranslatorKeys.languageSelector));
        await tester.tap(find.byKey(TranslatorKeys.languageSelector));
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(TranslatorKeys.languageSearch),
          'japan',
        );
        await tester.pump();
        await tester.tap(find.text('Japanese'));
        await tester.pumpAndSettle();

        expect(find.text('Japanese - 日本語'), findsOneWidget);
        expect(find.byKey(TranslatorKeys.translatedCard), findsNothing);
        expect(recorder.deletedPaths, contains('/tmp/translated_ar_1.m4a'));

        await tapTranslate(tester);

        expect(translator.requests.last.code, 'ja');
        expect(find.byKey(TranslatorKeys.translatedCard), findsOneWidget);
      });

      testWidgets('plays and pauses the translated voice', (tester) async {
        await tester.pumpTranslator(buildCubit());
        await recordVoice(tester);
        await tapTranslate(tester);

        await tapKey(tester, TranslatorKeys.translatedPlay);
        await tester.pump();

        expect(player.playCalls, 1);
        expect(player.openedPath, '/tmp/translated_ar_1.m4a');

        await tapKey(tester, TranslatorKeys.translatedPause);
        await tester.pump();

        expect(player.pauseCalls, 1);
      });
    });

    group('header menu', () {
      Future<void> openMenuItem(WidgetTester tester, String action) async {
        await tester.tap(find.byKey(const Key('translator_menuButton')));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(Key('translator_menu_$action')));
        await tester.pumpAndSettle();
      }

      testWidgets('offers language and appearance options', (tester) async {
        await tester.pumpTranslator(buildCubit());

        await tester.tap(find.byKey(const Key('translator_menuButton')));
        await tester.pumpAndSettle();

        expect(find.text('App language'), findsOneWidget);
        expect(find.text('Appearance'), findsOneWidget);
      });

      testWidgets('switches the app to Arabic from the language sheet', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());

        await openMenuItem(tester, 'language');
        await tester.tap(find.byKey(const Key('settings_language_ar')));
        await tester.pumpAndSettle();

        expect(find.text('ترجم الصوت'), findsOneWidget);
        expect(find.byKey(const Key('settings_language_ar')), findsNothing);
      });

      testWidgets('switches to light mode from the appearance sheet', (
        tester,
      ) async {
        final theme = await tester.pumpTranslator(buildCubit());

        await openMenuItem(tester, 'theme');
        expect(find.text('Dark'), findsOneWidget);
        expect(find.text('Light'), findsOneWidget);

        await tester.tap(find.byKey(const Key('settings_theme_light')));
        await tester.pumpAndSettle();

        expect(theme.state, ThemeMode.light);
        final context = tester.element(find.byType(TranslatorHeader));
        expect(Theme.of(context).brightness, Brightness.light);
      });
    });

    group('localization and layout', () {
      testWidgets('renders Arabic copy without overflow on a small phone', (
        tester,
      ) async {
        await tester.pumpTranslator(
          buildCubit(),
          locale: const Locale('ar'),
          size: const Size(320, 640),
        );

        expect(find.text('الصوت الأصلي'), findsOneWidget);
        expect(find.text('ترجم الصوت'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('lists every supported target language in the picker', (
        tester,
      ) async {
        await tester.pumpTranslator(buildCubit());

        await tester.tap(find.byKey(TranslatorKeys.languageSelector));
        await tester.pumpAndSettle();

        expect(find.text('3 supported spoken languages'), findsOneWidget);
        expect(find.text('English'), findsOneWidget);
      });

      testWidgets('reloads languages from the selector after a failure', (
        tester,
      ) async {
        languages.error = const SocketException('offline');
        await tester.pumpTranslator(buildCubit());

        expect(find.textContaining('languages could not be loaded'), findsOne);
        expect(find.text('Tap to load languages again'), findsOneWidget);

        languages.error = null;
        await tapKey(tester, TranslatorKeys.errorAction);
        await tester.pump();

        expect(languages.calls, 2);
        expect(find.byKey(TranslatorKeys.errorCard), findsNothing);
        expect(find.text('Arabic - العربية'), findsOneWidget);
      });
    });
  });
}
