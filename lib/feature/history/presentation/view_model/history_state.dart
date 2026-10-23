import 'package:equatable/equatable.dart';

import '../../data/model/translation_history_entry.dart';

enum HistoryStatus { loading, ready, failed }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.loading,
    this.entries = const [],
    this.activeId,
    this.isPlaying = false,
    this.playbackFailed = false,
  });

  final HistoryStatus status;
  final List<TranslationHistoryEntry> entries;
  final String? activeId;
  final bool isPlaying;
  final bool playbackFailed;

  bool get isEmpty => status == HistoryStatus.ready && entries.isEmpty;
  bool get canClear => entries.isNotEmpty;

  bool isPlayingEntry(String id) => activeId == id && isPlaying;

  HistoryState copyWith({
    HistoryStatus? status,
    List<TranslationHistoryEntry>? entries,
    String? activeId,
    bool clearActive = false,
    bool? isPlaying,
    bool playbackFailed = false,
  }) {
    return HistoryState(
      status: status ?? this.status,
      entries: entries ?? this.entries,
      activeId: clearActive ? null : activeId ?? this.activeId,
      isPlaying: isPlaying ?? this.isPlaying,
      playbackFailed: playbackFailed,
    );
  }

  @override
  List<Object?> get props => [
    status,
    entries,
    activeId,
    isPlaying,
    playbackFailed,
  ];
}
