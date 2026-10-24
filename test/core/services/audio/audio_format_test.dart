import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/core/services/audio/audio_format.dart';

void main() {
  group('AudioFormat', () {
    test('keeps the extension of an importable file', () {
      expect(AudioFormat.uploadExtension('/tmp/voice.OGG'), 'ogg');
    });

    test('falls back to m4a for a recording without a known extension', () {
      expect(AudioFormat.uploadExtension('/tmp/source'), 'm4a');
      expect(AudioFormat.uploadExtension('/tmp/source.txt'), 'm4a');
    });

    test('maps upload extensions to MIME types', () {
      expect(AudioFormat.mimeTypeOf('mpga'), 'audio/mpeg');
      expect(AudioFormat.mimeTypeOf('opus'), 'audio/ogg');
      expect(AudioFormat.mimeTypeOf('m4a'), 'audio/mp4');
    });

    test('maps response MIME types to file extensions', () {
      expect(AudioFormat.extensionOf('audio/X-WAV'), 'wav');
      expect(AudioFormat.extensionOf('audio/x-m4a'), 'm4a');
      expect(AudioFormat.extensionOf('audio/unknown'), 'mp3');
    });
  });
}
