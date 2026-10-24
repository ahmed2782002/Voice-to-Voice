import 'audio_limits.dart';

abstract final class AudioFormat {
  static const String recordingExtension = 'm4a';

  static String uploadExtension(String path) => AudioLimits.isImportable(path)
      ? AudioLimits.extensionOf(path)
      : recordingExtension;

  static String mimeTypeOf(String extension) => switch (extension) {
    'mp3' || 'mpeg' || 'mpga' => 'audio/mpeg',
    'wav' => 'audio/wav',
    'webm' => 'audio/webm',
    'ogg' || 'opus' => 'audio/ogg',
    'flac' => 'audio/flac',
    _ => 'audio/mp4',
  };

  static String extensionOf(String mimeType) =>
      switch (mimeType.toLowerCase()) {
        'audio/wav' || 'audio/x-wav' || 'audio/wave' => 'wav',
        'audio/ogg' || 'audio/opus' => 'ogg',
        'audio/aac' => 'aac',
        'audio/mp4' || 'audio/m4a' || 'audio/x-m4a' => 'm4a',
        _ => 'mp3',
      };
}
