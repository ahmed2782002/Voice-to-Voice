import 'dart:async';

import 'package:just_audio/just_audio.dart';

import 'audio_player_service.dart';

class DeviceAudioPlayerService implements AudioPlayerService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get positionChanges => _player.positionStream;

  @override
  Stream<bool> get playingChanges => _player.playerStateStream.map(
    (state) =>
        state.playing && state.processingState != ProcessingState.completed,
  );

  @override
  Future<Duration?> open(String path) => _player.setFilePath(path);

  @override
  Future<Duration?> probeDuration(String path) async {
    final probe = AudioPlayer();
    try {
      return await probe.setFilePath(path);
    } finally {
      await probe.dispose();
    }
  }

  @override
  Future<void> play() async {
    if (_player.processingState == ProcessingState.completed) {
      await _player.seek(Duration.zero);
    }
    unawaited(_player.play());
  }

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> replay() async {
    await _player.seek(Duration.zero);
    unawaited(_player.play());
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
