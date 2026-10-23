import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/core/services/audio/audio_recorder_service.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_language.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_result.dart';
import 'package:voice_to_voice/feature/translator/data/model/translator_api_exception.dart';
import 'package:voice_to_voice/feature/translator/presentation/view_model/translator_cubit.dart';
import 'package:voice_to_voice/feature/translator/presentation/view_model/translator_state.dart';

import '../../helpers/fakes.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeAudioRecorderService recorder;
  late FakeAudioPlayerService player;
  late FakeTranslator translator;
  late FakeClock clock;
  late FakeLanguageLoader languages;
  late FakeAiNoticeStore aiNotice;
  late TranslatorCubit cubit;

  setUp(() {
    recorder = FakeAudioRecorderService();
    player = FakeAudioPlayerService();
    translator = FakeTranslator();
    clock = FakeClock();
    languages = FakeLanguageLoader();
    aiNotice = FakeAiNoticeStore();
    cubit = TranslatorCubit(
      recorder: recorder,
      player: player,
      translate: translator.call,
      loadLanguages: languages.call,
      aiNotice: aiNotice,
      clock: clock.call,
    );
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  Future<void> record({
    Duration length = const Duration(seconds: 3),
    double level = 0.6,
  }) async {
    await cubit.startRecording();
    recorder.amplitude.add(level);
    await flush();
    clock.advance(length);
    await cubit.stopRecording();
  }

  group('TranslatorCubit', () {
    group('recording', () {
      test(
        'moves idle → recording → recorded with the measured duration',
        () async {
          final statuses = <RecordStatus>[];
          final subscription = cubit.stream.listen(
            (state) => statuses.add(state.recordStatus),
          );

          await record();
          await flush();
          await subscription.cancel();

          expect(statuses.first, RecordStatus.recording);
          expect(statuses.last, RecordStatus.recorded);
          expect(cubit.state.sourcePath, '/tmp/source.m4a');
          expect(cubit.state.sourceDuration, const Duration(seconds: 3));
          expect(cubit.state.failure, isNull);
        },
      );

      test('reports permission denial without starting the recorder', () async {
        recorder.permission = MicPermission.denied;

        await cubit.startRecording();

        expect(cubit.state.failure, TranslatorFailure.permissionDenied);
        expect(cubit.state.recordStatus, RecordStatus.idle);
        expect(recorder.startCalls, 0);
      });

      test('rejects a recording larger than the file-size limit', () async {
        recorder.recordedBytes = 5 * 1024 * 1024 + 1;

        await record();

        expect(cubit.state.failure, TranslatorFailure.recordingTooLarge);
        expect(cubit.state.sourcePath, isNull);
        expect(recorder.deletedPaths, ['/tmp/source.m4a']);
      });

      test('rejects a recording below the server minimum size', () async {
        recorder.recordedBytes = 2 * 1024 - 1;

        await record();

        expect(cubit.state.failure, TranslatorFailure.recordingTooShort);
        expect(cubit.state.hasSource, isFalse);
      });

      test('auto-stops when the maximum duration is reached', () async {
        await cubit.startRecording();
        clock.advance(const Duration(minutes: 2));
        recorder.amplitude.add(0.7);
        await flush();
        await flush();

        expect(cubit.state.recordStatus, RecordStatus.recorded);
      });

      test('maps a recorder start failure to recordingFailed', () async {
        recorder.failOnStart = true;

        await cubit.startRecording();

        expect(cubit.state.failure, TranslatorFailure.recordingFailed);
        expect(cubit.state.isRecording, isFalse);
      });
    });

    group('languages', () {
      test('loads target languages and keeps the current selection', () async {
        await cubit.loadLanguages();

        expect(cubit.state.languagesStatus, LanguagesStatus.ready);
        expect(cubit.state.languages, SampleLanguages.all);
        expect(cubit.state.language, TranslationLanguage.arabic);
      });

      test(
        'falls back to the first language when the current one is missing',
        () async {
          languages.languages = const [
            SampleLanguages.english,
            SampleLanguages.japanese,
          ];

          await cubit.loadLanguages();

          expect(cubit.state.language, SampleLanguages.english);
        },
      );

      test('reports a load failure and reloads on retry', () async {
        languages.error = const SocketException('offline');
        await cubit.loadLanguages();

        expect(cubit.state.failure, TranslatorFailure.languagesFailed);
        expect(cubit.state.languagesStatus, LanguagesStatus.failed);

        languages.error = null;
        await cubit.retry();

        expect(languages.calls, 2);
        expect(cubit.state.failure, isNull);
        expect(cubit.state.languagesStatus, LanguagesStatus.ready);
      });

      test('keeps loaded languages after a new recording starts', () async {
        await cubit.loadLanguages();

        await record();

        expect(cubit.state.languages, SampleLanguages.all);
      });
    });

    group('translation', () {
      test(
        'emits processing then ready and clears the previous failure',
        () async {
          await record();
          final statuses = <TranslateStatus>[];
          final subscription = cubit.stream.listen(
            (state) => statuses.add(state.translateStatus),
          );

          await cubit.translate();
          await flush();
          await subscription.cancel();

          expect(statuses.first, TranslateStatus.processing);
          expect(statuses.last, TranslateStatus.ready);
          expect(cubit.state.result?.language, TranslationLanguage.arabic);
          expect(cubit.state.translatedDuration, const Duration(seconds: 4));
        },
      );

      test(
        'never marks a failed request as a successful translation',
        () async {
          await record();
          translator.error = const HttpException('500');

          await cubit.translate();

          expect(cubit.state.failure, TranslatorFailure.server);
          expect(cubit.state.isReady, isFalse);
          expect(cubit.state.result, isNull);
        },
      );

      const apiFailures = {
        TranslatorErrorCode.badRequest: TranslatorFailure.badRequest,
        TranslatorErrorCode.emptyRecording: TranslatorFailure.recordingEmpty,
        TranslatorErrorCode.fileTooLarge: TranslatorFailure.recordingTooLarge,
        TranslatorErrorCode.unsupportedTargetLanguage:
            TranslatorFailure.unsupportedTargetLanguage,
        TranslatorErrorCode.unsupportedSourceLanguage:
            TranslatorFailure.unsupportedSourceLanguage,
        TranslatorErrorCode.noSpeech: TranslatorFailure.noSpeech,
        TranslatorErrorCode.textTooLong: TranslatorFailure.textTooLong,
        TranslatorErrorCode.unsupportedInput:
            TranslatorFailure.unsupportedInput,
        TranslatorErrorCode.rateLimited: TranslatorFailure.rateLimited,
        TranslatorErrorCode.upstreamError: TranslatorFailure.server,
        TranslatorErrorCode.upstreamTimeout: TranslatorFailure.timeout,
        TranslatorErrorCode.upstreamUnreachable: TranslatorFailure.server,
        TranslatorErrorCode.serverMisconfigured:
            TranslatorFailure.serviceUnavailable,
        TranslatorErrorCode.unauthorized: TranslatorFailure.sessionFailed,
      };

      for (final MapEntry(key: code, value: failure) in apiFailures.entries) {
        test('maps ${code.wire} to $failure', () async {
          await record();
          translator.error = TranslatorApiException(
            code: code,
            statusCode: 400,
          );

          await cubit.translate();

          expect(cubit.state.failure, failure);
          expect(cubit.state.isProcessing, isFalse);
        });
      }

      test('maps a malformed response to a server failure', () async {
        await record();
        translator.error = const FormatException('bad json');

        await cubit.translate();

        expect(cubit.state.failure, TranslatorFailure.server);
      });

      test(
        'hides the AI notice after the first translation and saves it',
        () async {
          expect(cubit.state.showAiNotice, isTrue);
          await record();

          await cubit.translate();

          expect(cubit.state.showAiNotice, isFalse);
          expect(aiNotice.markSeenCalls, 1);
        },
      );

      test('keeps the AI notice when the first translation fails', () async {
        await record();
        translator.error = const SocketException('offline');

        await cubit.translate();

        expect(cubit.state.showAiNotice, isTrue);
        expect(aiNotice.markSeenCalls, 0);
      });

      test('starts without the AI notice once it was seen', () async {
        final seenCubit = TranslatorCubit(
          recorder: FakeAudioRecorderService(),
          player: FakeAudioPlayerService(),
          translate: translator.call,
          loadLanguages: languages.call,
          aiNotice: FakeAiNoticeStore(seen: true),
        );
        addTearDown(seenCubit.close);

        expect(seenCubit.state.showAiNotice, isFalse);
      });

      test('retries the same recording after a rate limit', () async {
        await record();
        translator.error = const TranslatorApiException(
          code: TranslatorErrorCode.rateLimited,
          statusCode: 429,
          retryable: true,
        );
        await cubit.translate();
        translator.error = null;

        await cubit.retry();

        expect(translator.calls, 2);
        expect(cubit.state.isReady, isTrue);
        expect(cubit.state.failure, isNull);
      });

      test(
        'drops a stale result that arrives after the recording is discarded',
        () async {
          await record();
          translator.pending = Completer<TranslationResult>();
          final pending = cubit.translate();

          await cubit.discardRecording();
          translator.pending!.complete(
            const TranslationResult(
              audioPath: '/tmp/late.m4a',
              language: TranslationLanguage.arabic,
            ),
          );
          await pending;

          expect(cubit.state.result, isNull);
          expect(cubit.state.hasSource, isFalse);
          expect(recorder.deletedPaths, contains('/tmp/late.m4a'));
        },
      );

      test(
        'keeps the recording so the same audio can target another language',
        () async {
          await record();
          await cubit.translate();
          const japanese = SampleLanguages.japanese;

          await cubit.selectLanguage(japanese);
          await cubit.translate();

          expect(cubit.state.sourcePath, '/tmp/source.m4a');
          expect(translator.requests.map((language) => language.code), [
            'ar',
            'ja',
          ]);
          expect(cubit.state.result?.language, japanese);
        },
      );
    });

    group('playback', () {
      test(
        'switching tracks stops the previous one so audio never overlaps',
        () async {
          await record();
          await cubit.translate();

          await cubit.togglePlayback(AudioTrack.source);
          await cubit.togglePlayback(AudioTrack.translated);
          await flush();

          expect(cubit.state.activeTrack, AudioTrack.translated);
          expect(player.openedPath, '/tmp/translated_ar_1.m4a');
          expect(player.stopCalls, greaterThanOrEqualTo(2));
        },
      );

      test('reports a playback failure without losing the recording', () async {
        await record();
        player.failOnOpen = true;

        await cubit.togglePlayback(AudioTrack.source);

        expect(cubit.state.failure, TranslatorFailure.playbackFailed);
        expect(cubit.state.hasSource, isTrue);
      });
    });

    group('cleanup', () {
      test(
        'close deletes temporary files and releases audio resources',
        () async {
          await record();
          await cubit.translate();

          await cubit.close();

          expect(
            recorder.deletedPaths,
            containsAll(['/tmp/source.m4a', '/tmp/translated_ar_1.m4a']),
          );
          expect(player.disposed, isTrue);
          expect(recorder.disposed, isTrue);
        },
      );
    });
  });
}
