enum MicPermission { granted, denied, permanentlyDenied }

abstract interface class AudioRecorderService {
  Stream<double> get amplitudeChanges;

  Future<MicPermission> requestPermission();

  Future<void> openSettings();

  Future<void> start();

  Future<String?> stop();

  Future<void> cancel();

  Future<int> fileSize(String path);

  Future<void> deleteFile(String path);

  Future<void> dispose();
}
