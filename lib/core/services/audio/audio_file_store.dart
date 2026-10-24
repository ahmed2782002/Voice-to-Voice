import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'audio_format.dart';

class AudioFileStore {
  AudioFileStore({Future<Directory> Function()? directory})
    : _directory = directory ?? getTemporaryDirectory;

  final Future<Directory> Function() _directory;

  Future<String> save(
    Uint8List bytes, {
    required String prefix,
    required String mimeType,
  }) async {
    final directory = await _directory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(
      '${directory.path}/${prefix}_$stamp.${AudioFormat.extensionOf(mimeType)}',
    );
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
