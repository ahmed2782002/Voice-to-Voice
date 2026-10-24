import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/network/network_exception.dart';
import '../../../../core/services/audio/audio_file_picker.dart';
import '../../../../core/services/audio/audio_limits.dart';
import '../../../../core/services/audio/audio_player_service.dart';
import '../../../../core/services/audio/audio_recorder_service.dart';
import '../../../../core/services/connectivity/connectivity_service.dart';
import '../../../../core/services/preferences/ai_notice_store.dart';
import '../../data/model/translation_language.dart';
import '../../data/model/translation_result.dart';
import '../../data/model/translator_api_exception.dart';
import 'translator_state.dart';

class TranslatorCubit extends Cubit<TranslatorState> {
  TranslatorCubit({
    required this._recorder,
    required this._player,
    required this._translate,
    required this._loadLanguages,
    required this._picker,
    required this._saveToHistory,
    required this._connectivity,
    required AiNoticeStore aiNotice,
    DateTime Function()? clock,
  }) : _aiNotice = aiNotice,
       _clock = clock ?? DateTime.now,
       super(TranslatorState(showAiNotice: !aiNotice.seen)) {
    _positionSubscription = _player.positionChanges.listen(_onPosition);
    _playingSubscription = _player.playingChanges.listen(_onPlaying);
    _lifecycle = AppLifecycleListener(onPause: pauseEverything);
    _connectivitySubscription = _connectivity.onlineChanges.listen(
      _onConnectivity,
      onError: (Object _) {},
    );
    unawaited(checkConnectivity());
  }

  final AudioRecorderService _recorder;
  final AudioPlayerService _player;
  final AiNoticeStore _aiNotice;
  final TranslateVoice _translate;
  final LoadLanguages _loadLanguages;
  final AudioFilePicker _picker;
  final SaveTranslation _saveToHistory;
  final ConnectivityService _connectivity;
  final TextEditingController searchController = TextEditingController();
  final DateTime Function() _clock;
  DateTime? _startedAt;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _connectivitySubscription;
  AppLifecycleListener? _lifecycle;
  StreamSubscription<double>? _amplitudeSubscription;
  bool _recordingTransition = false;
  int _request = 0;

  Future<void> loadLanguages() async {
    if (state.isLoadingLanguages) return;
    emit(
      state.copyWith(
        languagesStatus: LanguagesStatus.loading,
        clearFailure: state.failure == TranslatorFailure.languagesFailed,
      ),
    );
    try {
      final languages = await _loadLanguages();
      if (isClosed) return;
      emit(
        state.copyWith(
          languages: languages,
          languagesStatus: LanguagesStatus.ready,
          language: _resolveTarget(languages),
        ),
      );
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          languagesStatus: LanguagesStatus.failed,
          failure: state.failure ?? TranslatorFailure.languagesFailed,
        ),
      );
    }
  }

  Future<void> importAudio() async {
    if (_recordingTransition || !state.canImport) return;
    _recordingTransition = true;
    String? path;
    try {
      await _stopPlayback();
      path = await _picker.pick();
      if (isClosed || path == null) return;
      final failure = await _validateImport(path);
      if (isClosed) return;
      if (failure != null) {
        await _recorder.deleteFile(path);
        emit(state.copyWith(failure: failure));
        return;
      }
      final duration = await _probe(path);
      if (isClosed) return;
      _request++;
      await _deleteRecordings();
      emit(
        TranslatorState(
          recordStatus: RecordStatus.recorded,
          sourcePath: path,
          sourceDuration: duration,
          sourceIsImported: true,
          language: state.language,
          searchQuery: state.searchQuery,
          languages: state.languages,
          languagesStatus: state.languagesStatus,
          showAiNotice: state.showAiNotice,
          isOffline: state.isOffline,
        ),
      );
    } catch (_) {
      if (path != null) await _recorder.deleteFile(path);
      if (!isClosed) {
        emit(state.copyWith(failure: TranslatorFailure.importFailed));
      }
    } finally {
      _recordingTransition = false;
    }
  }

  Future<void> toggleRecording() =>
      state.isRecording ? stopRecording() : startRecording();

  Future<void> startRecording() async {
    if (_recordingTransition || state.isRecording || !state.canRecord) return;
    _recordingTransition = true;
    try {
      await _stopPlayback();
      final permission = await _recorder.requestPermission();
      if (isClosed) return;
      if (permission != MicPermission.granted) {
        emit(state.copyWith(failure: _permissionFailure(permission)));
        return;
      }
      await _deleteRecordings();
      emit(
        TranslatorState(
          recordStatus: RecordStatus.recording,
          language: state.language,
          searchQuery: state.searchQuery,
          languages: state.languages,
          languagesStatus: state.languagesStatus,
          showAiNotice: state.showAiNotice,
          isOffline: state.isOffline,
        ),
      );
      _amplitudeSubscription = _recorder.amplitudeChanges.listen(_onAmplitude);
      await _recorder.start();
      _startedAt = _clock();
    } catch (_) {
      await _amplitudeSubscription?.cancel();
      if (!isClosed) {
        emit(
          state.copyWith(
            recordStatus: RecordStatus.idle,
            failure: TranslatorFailure.recordingFailed,
          ),
        );
      }
    } finally {
      _recordingTransition = false;
    }
  }

  Future<void> stopRecording() async {
    if (_recordingTransition || !state.isRecording) return;
    _recordingTransition = true;
    try {
      final elapsed = _elapsed;
      _startedAt = null;
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      final path = await _recorder.stop();
      if (isClosed) return;
      final failure = await _validate(path, elapsed);
      if (isClosed) return;
      if (failure != null) {
        if (path != null) await _recorder.deleteFile(path);
        emit(
          TranslatorState(
            language: state.language,
            failure: failure,
            searchQuery: state.searchQuery,
            languages: state.languages,
            languagesStatus: state.languagesStatus,
            showAiNotice: state.showAiNotice,
            isOffline: state.isOffline,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          recordStatus: RecordStatus.recorded,
          sourcePath: path,
          sourceDuration: elapsed,
          recordElapsed: elapsed,
          sourceLevels: _downsample(state.liveLevels),
          clearFailure: true,
        ),
      );
    } catch (_) {
      if (!isClosed) {
        emit(
          state.copyWith(
            recordStatus: RecordStatus.idle,
            failure: TranslatorFailure.recordingFailed,
          ),
        );
      }
    } finally {
      _recordingTransition = false;
    }
  }

  Future<void> discardRecording() async {
    if (state.isProcessing || state.isRecording) return;
    _request++;
    await _stopPlayback();
    await _deleteRecordings();
    if (isClosed) return;
    emit(
      TranslatorState(
        language: state.language,
        languages: state.languages,
        languagesStatus: state.languagesStatus,
        showAiNotice: state.showAiNotice,
        isOffline: state.isOffline,
      ),
    );
  }

  Future<void> selectLanguage(TranslationLanguage language) async {
    if (language == state.language || state.isProcessing) return;
    await _clearTranslation();
    if (isClosed) return;
    emit(
      state.copyWith(
        language: language,
        translateStatus: TranslateStatus.idle,
        clearResult: true,
        clearFailure: true,
      ),
    );
  }

  Future<void> translate() async {
    final sourcePath = state.sourcePath;
    if (!state.canTranslate || sourcePath == null) return;
    final request = ++_request;
    final language = state.language;
    await _stopPlayback();
    await _clearTranslation();
    if (isClosed) return;
    emit(
      state.copyWith(
        translateStatus: TranslateStatus.processing,
        clearResult: true,
        clearFailure: true,
      ),
    );
    try {
      final result = await _translate(
        sourcePath: sourcePath,
        language: language,
      ).timeout(AudioLimits.translationTimeout);
      if (isClosed || request != _request) {
        await _recorder.deleteFile(result.audioPath);
        return;
      }
      final duration = await _player.open(result.audioPath);
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          translateStatus: TranslateStatus.ready,
          result: result,
          translatedDuration: duration ?? Duration.zero,
          activeTrack: AudioTrack.translated,
          position: Duration.zero,
          showAiNotice: false,
        ),
      );
      if (!_aiNotice.seen) unawaited(_aiNotice.markSeen());
      unawaited(_remember(result));
    } catch (error) {
      if (isClosed || request != _request) return;
      emit(
        state.copyWith(
          translateStatus: TranslateStatus.idle,
          failure: _translationFailure(error),
        ),
      );
    }
  }

  Future<void> togglePlayback(AudioTrack track) async {
    if (state.isPlayingTrack(track)) {
      await _player.pause();
      return;
    }
    if (await _activate(track)) await _player.play();
  }

  Future<void> replay(AudioTrack track) async {
    if (await _activate(track)) await _player.replay();
  }

  Future<void> retry() async {
    switch (state.failure) {
      case TranslatorFailure.permissionPermanentlyDenied:
        await _recorder.openSettings();
      case TranslatorFailure.importFailed || TranslatorFailure.unsupportedFile:
        emit(state.copyWith(clearFailure: true));
        await importAudio();
      case TranslatorFailure.languagesFailed:
        await loadLanguages();
      case TranslatorFailure.network ||
          TranslatorFailure.timeout ||
          TranslatorFailure.server ||
          TranslatorFailure.rateLimited ||
          TranslatorFailure.sessionFailed:
        if (state.languages.isEmpty) unawaited(loadLanguages());
        if (state.canTranslate) {
          await translate();
        } else {
          emit(state.copyWith(clearFailure: true));
        }
      case TranslatorFailure.playbackFailed ||
          TranslatorFailure.unsupportedTargetLanguage ||
          TranslatorFailure.serviceUnavailable:
        emit(state.copyWith(clearFailure: true));
      case TranslatorFailure.unsupportedInput ||
          TranslatorFailure.noSpeech ||
          TranslatorFailure.textTooLong ||
          TranslatorFailure.badRequest ||
          TranslatorFailure.unsupportedSourceLanguage:
        await discardRecording();
        await startRecording();
      case _:
        await startRecording();
    }
  }

  void onSearchChanged(String query) =>
      emit(state.copyWith(searchQuery: query));

  void resetSearch() {
    searchController.clear();
    emit(state.copyWith(searchQuery: ''));
  }

  Future<void> pauseEverything() async {
    if (state.isRecording) await stopRecording();
    if (state.isPlaying) await _player.pause();
  }

  Duration get _elapsed {
    final startedAt = _startedAt;
    return startedAt == null ? Duration.zero : _clock().difference(startedAt);
  }

  Future<bool> _activate(AudioTrack track) async {
    if (state.isRecording || state.isProcessing) return false;
    if (state.activeTrack == track) return true;
    final path = switch (track) {
      AudioTrack.source => state.sourcePath,
      AudioTrack.translated => state.result?.audioPath,
      AudioTrack.none => null,
    };
    if (path == null) return false;
    try {
      await _player.stop();
      final duration = await _player.open(path);
      if (isClosed) return false;
      emit(
        state.copyWith(
          activeTrack: track,
          position: Duration.zero,
          sourceDuration: track == AudioTrack.source ? duration : null,
          translatedDuration: track == AudioTrack.translated ? duration : null,
          clearFailure: true,
        ),
      );
      return true;
    } catch (_) {
      if (!isClosed) {
        emit(state.copyWith(failure: TranslatorFailure.playbackFailed));
      }
      return false;
    }
  }

  void _onAmplitude(double level) {
    if (isClosed || !state.isRecording) return;
    final elapsed = _elapsed;
    emit(
      state.copyWith(
        liveLevels: [...state.liveLevels, level],
        recordElapsed: elapsed,
      ),
    );
    if (elapsed >= AudioLimits.maxRecording) unawaited(stopRecording());
  }

  void _onPosition(Duration position) {
    if (isClosed || state.activeTrack == AudioTrack.none) return;
    emit(state.copyWith(position: position));
  }

  void _onPlaying(bool playing) {
    if (isClosed || playing == state.isPlaying) return;
    emit(state.copyWith(isPlaying: playing));
  }

  Future<TranslatorFailure?> _validateImport(String path) async {
    if (!AudioLimits.isImportable(path)) {
      return TranslatorFailure.unsupportedFile;
    }
    final size = await _recorder.fileSize(path);
    if (size == 0) return TranslatorFailure.importFailed;
    if (size < AudioLimits.minFileBytes) {
      return TranslatorFailure.recordingTooShort;
    }
    if (size > AudioLimits.maxFileBytes) {
      return TranslatorFailure.recordingTooLarge;
    }
    return null;
  }

  Future<Duration> _probe(String path) async {
    try {
      return await _player.probeDuration(path) ?? Duration.zero;
    } catch (_) {
      return Duration.zero;
    }
  }

  Future<void> _remember(TranslationResult result) async {
    final code = result.sourceLanguageCode;
    final source = state.languages.where((language) => language.code == code);
    try {
      await _saveToHistory(
        result,
        source.isEmpty ? (code ?? '').toUpperCase() : source.first.displayName,
      );
    } catch (_) {
      return;
    }
  }

  Future<TranslatorFailure?> _validate(String? path, Duration elapsed) async {
    if (path == null) return TranslatorFailure.recordingFailed;
    if (elapsed < AudioLimits.minRecording) {
      return TranslatorFailure.recordingTooShort;
    }
    final size = await _recorder.fileSize(path);
    if (size == 0) return TranslatorFailure.recordingFailed;
    if (size < AudioLimits.minFileBytes) {
      return TranslatorFailure.recordingTooShort;
    }
    if (size > AudioLimits.maxFileBytes) {
      return TranslatorFailure.recordingTooLarge;
    }
    final peak = state.liveLevels.fold<double>(0, math.max);
    if (peak < AudioLimits.silenceThreshold) {
      return TranslatorFailure.recordingEmpty;
    }
    return null;
  }

  List<double> _downsample(List<double> levels) {
    const count = AudioLimits.liveWaveformBars;
    if (levels.length <= count) return levels;
    final chunk = levels.length / count;
    return List.generate(count, (index) {
      final start = (index * chunk).floor();
      final end = math.min(levels.length, ((index + 1) * chunk).ceil());
      return levels.sublist(start, end).fold<double>(0, math.max);
    });
  }

  TranslatorFailure _permissionFailure(MicPermission permission) =>
      permission == MicPermission.permanentlyDenied
      ? TranslatorFailure.permissionPermanentlyDenied
      : TranslatorFailure.permissionDenied;

  TranslatorFailure _translationFailure(Object error) => switch (error) {
    TranslatorApiException(:final code) => _apiFailure(code),
    TimeoutException() ||
    RequestTimeoutException() => TranslatorFailure.timeout,
    NoConnectionException() => TranslatorFailure.network,
    _ => TranslatorFailure.server,
  };

  TranslatorFailure _apiFailure(TranslatorErrorCode code) => switch (code) {
    TranslatorErrorCode.badRequest => TranslatorFailure.badRequest,
    TranslatorErrorCode.unauthorized => TranslatorFailure.sessionFailed,
    TranslatorErrorCode.emptyRecording => TranslatorFailure.recordingEmpty,
    TranslatorErrorCode.fileTooLarge => TranslatorFailure.recordingTooLarge,
    TranslatorErrorCode.unsupportedTargetLanguage =>
      TranslatorFailure.unsupportedTargetLanguage,
    TranslatorErrorCode.unsupportedSourceLanguage =>
      TranslatorFailure.unsupportedSourceLanguage,
    TranslatorErrorCode.noSpeech => TranslatorFailure.noSpeech,
    TranslatorErrorCode.textTooLong => TranslatorFailure.textTooLong,
    TranslatorErrorCode.unsupportedInput => TranslatorFailure.unsupportedInput,
    TranslatorErrorCode.rateLimited => TranslatorFailure.rateLimited,
    TranslatorErrorCode.upstreamTimeout => TranslatorFailure.timeout,
    TranslatorErrorCode.upstreamError ||
    TranslatorErrorCode.upstreamUnreachable ||
    TranslatorErrorCode.unknown => TranslatorFailure.server,
    TranslatorErrorCode.serverMisconfigured =>
      TranslatorFailure.serviceUnavailable,
  };

  TranslationLanguage _resolveTarget(List<TranslationLanguage> languages) {
    for (final language in languages) {
      if (language == state.language) return language;
    }
    return languages.first;
  }

  Future<void> _stopPlayback() async {
    if (state.activeTrack == AudioTrack.none && !state.isPlaying) return;
    await _player.stop();
    if (isClosed) return;
    emit(
      state.copyWith(
        activeTrack: AudioTrack.none,
        isPlaying: false,
        position: Duration.zero,
      ),
    );
  }

  Future<void> _clearTranslation() async {
    if (state.activeTrack == AudioTrack.translated) await _stopPlayback();
    final path = state.result?.audioPath;
    if (path != null) await _recorder.deleteFile(path);
  }

  Future<void> _deleteRecordings() async {
    final paths = [state.sourcePath, state.result?.audioPath].nonNulls;
    for (final path in paths) {
      await _recorder.deleteFile(path);
    }
  }

  Future<void> checkConnectivity() async {
    try {
      _onConnectivity(await _connectivity.isOnline());
    } catch (_) {
      return;
    }
  }

  void _onConnectivity(bool online) {
    if (isClosed || state.isOffline == !online) return;
    if (!online) unawaited(pauseEverything());
    emit(state.copyWith(isOffline: !online));
    if (online && state.languagesStatus == LanguagesStatus.failed) {
      loadLanguages();
    }
  }

  @override
  Future<void> close() async {
    _lifecycle?.dispose();
    await _amplitudeSubscription?.cancel();
    await _positionSubscription?.cancel();
    await _playingSubscription?.cancel();
    await _connectivitySubscription?.cancel();
    if (state.isRecording) await _recorder.cancel();
    await _player.dispose();
    await _deleteRecordings();
    await _recorder.dispose();
    searchController.dispose();
    return super.close();
  }
}
