import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/services/audio/audio_player_service.dart';
import '../../data/model/translation_history_entry.dart';
import '../../data/repo/translation_history_store.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required this._store, required this._player})
    : super(const HistoryState()) {
    _playingSubscription = _player.playingChanges.listen(_onPlaying);
    _lifecycle = AppLifecycleListener(onPause: pause);
  }

  final TranslationHistoryStore _store;
  final AudioPlayerService _player;
  StreamSubscription<bool>? _playingSubscription;
  AppLifecycleListener? _lifecycle;

  Future<void> load() async {
    emit(state.copyWith(status: HistoryStatus.loading));
    try {
      final entries = await _store.load();
      if (isClosed) return;
      emit(state.copyWith(status: HistoryStatus.ready, entries: entries));
    } catch (_) {
      if (isClosed) return;
      emit(state.copyWith(status: HistoryStatus.failed));
    }
  }

  Future<void> togglePlayback(TranslationHistoryEntry entry) async {
    if (state.isPlayingEntry(entry.id)) {
      await _player.pause();
      return;
    }
    try {
      if (state.activeId != entry.id) {
        await _player.stop();
        await _player.open(entry.audioPath);
        if (isClosed) return;
        emit(state.copyWith(activeId: entry.id));
      }
      await _player.play();
    } catch (_) {
      if (isClosed) return;
      emit(
        state.copyWith(
          clearActive: true,
          isPlaying: false,
          playbackFailed: true,
        ),
      );
    }
  }

  Future<void> delete(TranslationHistoryEntry entry) async {
    if (state.activeId == entry.id) await _stop();
    await _store.delete(entry.id);
    if (isClosed) return;
    emit(
      state.copyWith(
        entries: state.entries.where((item) => item.id != entry.id).toList(),
      ),
    );
  }

  Future<void> clear() async {
    await _stop();
    await _store.clear();
    if (isClosed) return;
    emit(state.copyWith(entries: const []));
  }

  Future<void> pause() async {
    if (state.isPlaying) await _player.pause();
  }

  Future<void> _stop() async {
    await _player.stop();
    if (isClosed) return;
    emit(state.copyWith(clearActive: true, isPlaying: false));
  }

  void _onPlaying(bool playing) {
    if (isClosed || playing == state.isPlaying) return;
    emit(state.copyWith(isPlaying: playing));
  }

  @override
  Future<void> close() async {
    _lifecycle?.dispose();
    await _playingSubscription?.cancel();
    await _player.dispose();
    return super.close();
  }
}
