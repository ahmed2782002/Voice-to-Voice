import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import '../../../../core/services/audio/audio_limits.dart';
import '../../../../core/utils/constants/app_strings.dart';
import '../../data/model/translation_language.dart';
import '../../data/model/translation_result.dart';

enum RecordStatus { idle, recording, recorded }

enum TranslateStatus { idle, processing, ready }

enum AudioTrack { none, source, translated }

enum LanguagesStatus { idle, loading, ready, failed }

enum TranslatorFailure {
  permissionDenied,
  permissionPermanentlyDenied,
  recordingTooShort,
  recordingEmpty,
  recordingTooLarge,
  recordingFailed,
  playbackFailed,
  network,
  timeout,
  server,
  unsupportedInput,
  languagesFailed,
  rateLimited,
  noSpeech,
  textTooLong,
  badRequest,
  unsupportedSourceLanguage,
  unsupportedTargetLanguage,
  serviceUnavailable,
  sessionFailed,
}

class TranslatorState extends Equatable {
  const TranslatorState({
    this.recordStatus = RecordStatus.idle,
    this.translateStatus = TranslateStatus.idle,
    this.failure,
    this.sourcePath,
    this.sourceDuration = Duration.zero,
    this.recordElapsed = Duration.zero,
    this.liveLevels = const [],
    this.sourceLevels = const [],
    this.result,
    this.translatedDuration = Duration.zero,
    this.language = TranslationLanguage.arabic,
    this.activeTrack = AudioTrack.none,
    this.isPlaying = false,
    this.position = Duration.zero,
    this.searchQuery = '',
    this.languages = const [],
    this.languagesStatus = LanguagesStatus.idle,
    this.showAiNotice = true,
  });

  final RecordStatus recordStatus;
  final TranslateStatus translateStatus;
  final TranslatorFailure? failure;
  final String? sourcePath;
  final Duration sourceDuration;
  final Duration recordElapsed;
  final List<double> liveLevels;
  final List<double> sourceLevels;
  final TranslationResult? result;
  final Duration translatedDuration;
  final TranslationLanguage language;
  final AudioTrack activeTrack;
  final bool isPlaying;
  final Duration position;
  final String searchQuery;
  final List<TranslationLanguage> languages;
  final LanguagesStatus languagesStatus;
  final bool showAiNotice;

  bool get isRecording => recordStatus == RecordStatus.recording;
  bool get hasSource => recordStatus == RecordStatus.recorded;
  bool get isProcessing => translateStatus == TranslateStatus.processing;
  bool get isReady =>
      translateStatus == TranslateStatus.ready && result != null;
  bool get canTranslate => hasSource && !isProcessing;
  bool get canRecord => !isProcessing;
  bool get canPickLanguage => !isProcessing && languages.isNotEmpty;
  bool get isLoadingLanguages => languagesStatus == LanguagesStatus.loading;

  String? get languageStatusLabel => switch (languagesStatus) {
    LanguagesStatus.loading => AppStrings.loadingLanguages,
    LanguagesStatus.failed => AppStrings.retryLanguages,
    _ => null,
  };
  double get currentLevel => liveLevels.isEmpty ? 0 : liveLevels.last;

  List<TranslationLanguage> get filteredLanguages =>
      languages.where((language) => language.matches(searchQuery)).toList();

  List<double> get recordingBars {
    const count = AudioLimits.liveWaveformBars;
    if (liveLevels.length >= count) {
      return liveLevels.sublist(liveLevels.length - count);
    }
    return [...List.filled(count - liveLevels.length, 0.0), ...liveLevels];
  }

  List<double> get translatedBars => List.generate(
    AudioLimits.liveWaveformBars,
    (index) =>
        0.25 +
        0.75 * (math.sin(index * 0.7).abs() * math.cos(index * 0.23).abs()),
  );

  String? get failureMessage => switch (failure) {
    null => null,
    TranslatorFailure.permissionDenied => AppStrings.errorPermissionDenied,
    TranslatorFailure.permissionPermanentlyDenied =>
      AppStrings.errorPermissionPermanentlyDenied,
    TranslatorFailure.recordingTooShort => AppStrings.errorRecordingTooShort,
    TranslatorFailure.recordingEmpty => AppStrings.errorRecordingEmpty,
    TranslatorFailure.recordingTooLarge => AppStrings.errorRecordingTooLarge,
    TranslatorFailure.recordingFailed => AppStrings.errorRecordingFailed,
    TranslatorFailure.playbackFailed => AppStrings.errorPlaybackFailed,
    TranslatorFailure.network => AppStrings.errorNetwork,
    TranslatorFailure.timeout => AppStrings.errorTimeout,
    TranslatorFailure.server => AppStrings.errorServer,
    TranslatorFailure.unsupportedInput => AppStrings.errorUnsupportedInput,
    TranslatorFailure.languagesFailed => AppStrings.errorLanguagesFailed,
    TranslatorFailure.rateLimited => AppStrings.errorRateLimited,
    TranslatorFailure.noSpeech => AppStrings.errorNoSpeech,
    TranslatorFailure.textTooLong => AppStrings.errorTextTooLong,
    TranslatorFailure.badRequest => AppStrings.errorBadRequest,
    TranslatorFailure.unsupportedSourceLanguage =>
      AppStrings.errorUnsupportedSourceLanguage,
    TranslatorFailure.unsupportedTargetLanguage =>
      AppStrings.errorUnsupportedTargetLanguage,
    TranslatorFailure.serviceUnavailable => AppStrings.errorServiceUnavailable,
    TranslatorFailure.sessionFailed => AppStrings.errorSessionFailed,
  };

  String get failureAction => switch (failure) {
    TranslatorFailure.permissionPermanentlyDenied => AppStrings.openSettings,
    TranslatorFailure.recordingTooShort ||
    TranslatorFailure.recordingEmpty ||
    TranslatorFailure.recordingTooLarge ||
    TranslatorFailure.unsupportedInput ||
    TranslatorFailure.noSpeech ||
    TranslatorFailure.textTooLong ||
    TranslatorFailure.badRequest ||
    TranslatorFailure.unsupportedSourceLanguage => AppStrings.recordAgain,
    TranslatorFailure.unsupportedTargetLanguage ||
    TranslatorFailure.serviceUnavailable => AppStrings.dismiss,
    _ => AppStrings.tryAgain,
  };

  bool isPlayingTrack(AudioTrack track) => activeTrack == track && isPlaying;

  Duration durationOf(AudioTrack track) => switch (track) {
    AudioTrack.source => sourceDuration,
    AudioTrack.translated => translatedDuration,
    AudioTrack.none => Duration.zero,
  };

  Duration positionOf(AudioTrack track) =>
      activeTrack == track ? position : Duration.zero;

  double progressOf(AudioTrack track) {
    final total = durationOf(track).inMilliseconds;
    if (total <= 0 || activeTrack != track) return 0;
    return (position.inMilliseconds / total).clamp(0.0, 1.0);
  }

  TranslatorState copyWith({
    RecordStatus? recordStatus,
    TranslateStatus? translateStatus,
    TranslatorFailure? failure,
    bool clearFailure = false,
    String? sourcePath,
    bool clearSource = false,
    Duration? sourceDuration,
    Duration? recordElapsed,
    List<double>? liveLevels,
    List<double>? sourceLevels,
    TranslationResult? result,
    bool clearResult = false,
    Duration? translatedDuration,
    TranslationLanguage? language,
    AudioTrack? activeTrack,
    bool? isPlaying,
    Duration? position,
    String? searchQuery,
    List<TranslationLanguage>? languages,
    LanguagesStatus? languagesStatus,
    bool? showAiNotice,
  }) {
    return TranslatorState(
      recordStatus: recordStatus ?? this.recordStatus,
      translateStatus: translateStatus ?? this.translateStatus,
      failure: clearFailure ? null : failure ?? this.failure,
      sourcePath: clearSource ? null : sourcePath ?? this.sourcePath,
      sourceDuration: sourceDuration ?? this.sourceDuration,
      recordElapsed: recordElapsed ?? this.recordElapsed,
      liveLevels: liveLevels ?? this.liveLevels,
      sourceLevels: sourceLevels ?? this.sourceLevels,
      result: clearResult ? null : result ?? this.result,
      translatedDuration: translatedDuration ?? this.translatedDuration,
      language: language ?? this.language,
      activeTrack: activeTrack ?? this.activeTrack,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      searchQuery: searchQuery ?? this.searchQuery,
      languages: languages ?? this.languages,
      languagesStatus: languagesStatus ?? this.languagesStatus,
      showAiNotice: showAiNotice ?? this.showAiNotice,
    );
  }

  @override
  List<Object?> get props => [
    recordStatus,
    translateStatus,
    failure,
    sourcePath,
    sourceDuration,
    recordElapsed,
    liveLevels,
    sourceLevels,
    result,
    translatedDuration,
    language,
    activeTrack,
    isPlaying,
    position,
    searchQuery,
    languages,
    languagesStatus,
    showAiNotice,
  ];
}
