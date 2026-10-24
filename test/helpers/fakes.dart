import 'dart:async';
import 'dart:io';

import 'package:voice_to_voice/core/services/audio/audio_file_picker.dart';
import 'package:voice_to_voice/core/services/audio/audio_player_service.dart';
import 'package:voice_to_voice/core/services/audio/audio_recorder_service.dart';
import 'package:voice_to_voice/core/services/auth/access_token_provider.dart';
import 'package:voice_to_voice/core/services/connectivity/connectivity_service.dart';
import 'package:voice_to_voice/core/services/preferences/ai_notice_store.dart';
import 'package:voice_to_voice/feature/history/data/model/translation_history_entry.dart';
import 'package:voice_to_voice/feature/history/data/repo/translation_history_store.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_language.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_result.dart';

class FakeAudioRecorderService implements AudioRecorderService {
  FakeAudioRecorderService({
    this.permission = MicPermission.granted,
    this.recordedPath = '/tmp/source.m4a',
    this.recordedBytes = 32000,
  });

  MicPermission permission;
  String? recordedPath;
  int recordedBytes;
  bool failOnStart = false;
  int startCalls = 0;
  int openSettingsCalls = 0;
  bool disposed = false;
  final List<String> deletedPaths = [];
  final StreamController<double> amplitude =
      StreamController<double>.broadcast();

  @override
  Stream<double> get amplitudeChanges => amplitude.stream;

  @override
  Future<MicPermission> requestPermission() async => permission;

  @override
  Future<void> openSettings() async => openSettingsCalls++;

  @override
  Future<void> start() async {
    startCalls++;
    if (failOnStart) throw const FileSystemException('start failed');
  }

  @override
  Future<String?> stop() async => recordedPath;

  @override
  Future<void> cancel() async {}

  @override
  Future<int> fileSize(String path) async => recordedBytes;

  @override
  Future<void> deleteFile(String path) async => deletedPaths.add(path);

  @override
  Future<void> dispose() async {
    disposed = true;
    await amplitude.close();
  }
}

class FakeAudioPlayerService implements AudioPlayerService {
  FakeAudioPlayerService({this.trackDuration = const Duration(seconds: 4)});

  Duration trackDuration;
  bool failOnOpen = false;
  String? openedPath;
  int playCalls = 0;
  int pauseCalls = 0;
  int replayCalls = 0;
  int stopCalls = 0;
  bool disposed = false;
  final StreamController<Duration> position =
      StreamController<Duration>.broadcast();
  final StreamController<bool> playing = StreamController<bool>.broadcast();

  @override
  Stream<Duration> get positionChanges => position.stream;

  @override
  Stream<bool> get playingChanges => playing.stream;

  @override
  Future<Duration?> probeDuration(String path) async => trackDuration;

  @override
  Future<Duration?> open(String path) async {
    if (failOnOpen) throw const FileSystemException('cannot open');
    openedPath = path;
    return trackDuration;
  }

  @override
  Future<void> play() async {
    playCalls++;
    playing.add(true);
  }

  @override
  Future<void> pause() async {
    pauseCalls++;
    playing.add(false);
  }

  @override
  Future<void> replay() async {
    replayCalls++;
    playing.add(true);
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    playing.add(false);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
    await position.close();
    await playing.close();
  }
}

class FakeTranslator {
  final List<TranslationLanguage> requests = [];
  Completer<TranslationResult>? pending;
  Object? error;
  String originalText = '';
  String translatedText = '';
  String? sourceLanguageCode;

  int get calls => requests.length;

  Future<TranslationResult> call({
    required String sourcePath,
    required TranslationLanguage language,
  }) {
    requests.add(language);
    if (pending != null) return pending!.future;
    if (error != null) return Future.error(error!);
    return Future.value(
      TranslationResult(
        audioPath: '/tmp/translated_${language.code}_${requests.length}.m4a',
        language: language,
        originalText: originalText,
        translatedText: translatedText,
        sourceLanguageCode: sourceLanguageCode,
      ),
    );
  }
}

class FakeClock {
  DateTime now = DateTime(2026, 10, 22, 12);

  DateTime call() => now;

  void advance(Duration duration) => now = now.add(duration);
}

abstract final class SampleLanguages {
  static const english = TranslationLanguage(code: 'en', name: 'English');
  static const japanese = TranslationLanguage(
    code: 'ja',
    name: 'Japanese',
    nativeName: '日本語',
  );
  static const all = [TranslationLanguage.arabic, english, japanese];
}

class FakeLanguageLoader {
  List<TranslationLanguage> languages = SampleLanguages.all;
  Object? error;
  int calls = 0;

  Future<List<TranslationLanguage>> call() {
    calls++;
    if (error != null) return Future.error(error!);
    return Future.value(languages);
  }
}

class FakeAccessTokenProvider implements AccessTokenProvider {
  final List<bool> requests = [];
  int refreshes = 0;

  @override
  Future<String> accessToken({bool forceRefresh = false}) async {
    requests.add(forceRefresh);
    if (forceRefresh) refreshes++;
    return 'user-jwt-$refreshes';
  }
}

class FakeAiNoticeStore implements AiNoticeStore {
  FakeAiNoticeStore({this.seen = false});

  @override
  bool seen;
  int markSeenCalls = 0;

  @override
  Future<void> markSeen() async {
    markSeenCalls++;
    seen = true;
  }
}

class FakeAudioFilePicker implements AudioFilePicker {
  String? pickedPath = '/tmp/source_import.mp3';
  Object? error;
  int calls = 0;

  @override
  Future<String?> pick() async {
    calls++;
    if (error != null) throw error!;
    return pickedPath;
  }
}

class FakeHistoryStore implements TranslationHistoryStore {
  final List<TranslationHistoryEntry> entries = [];
  final List<(TranslationResult, String)> saved = [];
  final List<String> deleted = [];
  Object? loadError;
  int clearCalls = 0;

  @override
  Future<List<TranslationHistoryEntry>> load() async {
    if (loadError != null) throw loadError!;
    return List.of(entries);
  }

  @override
  Future<void> save(TranslationResult result, String sourceName) async =>
      saved.add((result, sourceName));

  @override
  Future<void> delete(String id) async {
    deleted.add(id);
    entries.removeWhere((entry) => entry.id == id);
  }

  @override
  Future<void> clear() async {
    clearCalls++;
    entries.clear();
  }
}

class FailingAccessTokenProvider implements AccessTokenProvider {
  FailingAccessTokenProvider(this.error);

  final Exception error;

  @override
  Future<String> accessToken({bool forceRefresh = false}) async => throw error;
}

class FakeConnectivityService implements ConnectivityService {
  FakeConnectivityService({this.online = true});

  bool online;
  final StreamController<bool> changes = StreamController<bool>.broadcast();

  @override
  Future<bool> isOnline() async => online;

  @override
  Stream<bool> get onlineChanges => changes.stream;

  void emit(bool value) {
    online = value;
    changes.add(value);
  }
}
