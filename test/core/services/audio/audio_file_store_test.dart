import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/core/services/audio/audio_file_store.dart';

void main() {
  late Directory directory;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('audio_file_store_test');
  });

  tearDown(() async {
    if (await directory.exists()) await directory.delete(recursive: true);
  });

  group('AudioFileStore', () {
    test('writes the bytes with an extension from the MIME type', () async {
      final store = AudioFileStore(directory: () async => directory);

      final path = await store.save(
        Uint8List.fromList([1, 2, 3]),
        prefix: 'translated_en',
        mimeType: 'audio/wav',
      );

      expect(path, startsWith('${directory.path}/translated_en_'));
      expect(path, endsWith('.wav'));
      expect(await File(path).readAsBytes(), [1, 2, 3]);
    });
  });
}
