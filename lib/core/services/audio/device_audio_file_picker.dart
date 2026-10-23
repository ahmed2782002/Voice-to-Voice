import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'audio_file_picker.dart';
import 'audio_limits.dart';

class DeviceAudioFilePicker implements AudioFilePicker {
  @override
  Future<String?> pick() async {
    final picked = await FilePicker.pickFile(type: FileType.audio);
    if (picked == null) return null;
    final extension = AudioLimits.extensionOf(picked.name);
    final directory = await getTemporaryDirectory();
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final copy = File(
      '${directory.path}/source_import_$stamp${extension.isEmpty ? '' : '.$extension'}',
    );
    await copy.writeAsBytes(await picked.xFile.readAsBytes(), flush: true);
    return copy.path;
  }
}
