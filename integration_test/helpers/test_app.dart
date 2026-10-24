import 'dart:io';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_to_voice/core/network/dio_client.dart';
import 'package:voice_to_voice/core/services/audio/audio_file_store.dart';
import 'package:voice_to_voice/core/services/preferences/preferences_ai_notice_store.dart';
import 'package:voice_to_voice/feature/history/data/repo/file_translation_history_store.dart';
import 'package:voice_to_voice/feature/translator/data/repo/translator_repo.dart';
import 'package:voice_to_voice/feature/translator/presentation/view/screen/translator_screen.dart';
import 'package:voice_to_voice/feature/translator/presentation/view_model/translator_cubit.dart';
import 'package:voice_to_voice/main.dart';

import '../../test/helpers/fakes.dart';
import 'fake_translator_server.dart';
import 'waiters.dart';

class TestApp {
  TestApp._(this.directory, this.preferences, this.sourcePath, bool online)
    : connectivity = FakeConnectivityService(online: online);

  final Directory directory;
  final SharedPreferences preferences;
  final String sourcePath;
  final FakeConnectivityService connectivity;
  final FakeTranslatorServer server = FakeTranslatorServer();
  final FakeClock clock = FakeClock();
  final FakeAudioFilePicker picker = FakeAudioFilePicker();
  late FakeAudioRecorderService recorder;
  late FakeAudioPlayerService player;

  static Future<TestApp> create({bool online = true}) async {
    final directory = await Directory.systemTemp.createTemp('voxbridge_e2e');
    final source = File('${directory.path}/source.m4a');
    await source.writeAsBytes(List.filled(4096, 1), flush: true);
    final preferences = await SharedPreferences.getInstance();
    await preferences.clear();
    return TestApp._(directory, preferences, source.path, online);
  }

  Future<void> launch(WidgetTester tester) async {
    await EasyLocalization.ensureInitialized();
    final history = FileTranslationHistoryStore(
      root: () async => Directory('${directory.path}/history').create(),
    );
    final repo = TranslatorRepo(
      client: DioClient(
        tokens: FakeAccessTokenProvider(),
        baseUrl: 'https://voxbridge.test/',
        adapter: server,
        retryDelays: const [],
      ),
      audioStore: AudioFileStore(directory: () async => directory),
    );
    await tester.pumpWidget(
      EasyLocalization(
        supportedLocales: const [Locale('en'), Locale('ar')],
        fallbackLocale: const Locale('en'),
        startLocale: const Locale('en'),
        path: 'assets/translations',
        useOnlyLangCode: true,
        child: VoxBridgeApp(
          preferences: preferences,
          history: history,
          createPlayer: FakeAudioPlayerService.new,
          createTranslatorCubit: () {
            recorder = FakeAudioRecorderService(
              recordedPath: sourcePath,
              recordedBytes: 4096,
            );
            player = FakeAudioPlayerService();
            return TranslatorCubit(
              recorder: recorder,
              player: player,
              translate: repo.translateVoice,
              loadLanguages: repo.fetchLanguages,
              picker: picker,
              saveToHistory: history.save,
              connectivity: connectivity,
              aiNotice: PreferencesAiNoticeStore(preferences),
              clock: clock.call,
            );
          },
        ),
      ),
    );
    await tester.pumpUntilFound(find.byType(TranslatorScreen));
    await tester.pumpUntilGone(find.byKey(const Key('splash_screen')));
  }

  Future<void> relaunch(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await launch(tester);
  }

  Future<void> dispose() async {
    await preferences.clear();
    if (await directory.exists()) await directory.delete(recursive: true);
  }
}
