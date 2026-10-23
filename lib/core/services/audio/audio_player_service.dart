abstract interface class AudioPlayerService {
  Stream<Duration> get positionChanges;

  Stream<bool> get playingChanges;

  Future<Duration?> open(String path);

  Future<void> play();

  Future<void> pause();

  Future<void> replay();

  Future<void> stop();

  Future<void> dispose();
}
