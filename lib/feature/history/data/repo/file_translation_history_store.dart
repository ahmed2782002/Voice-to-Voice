import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../../../core/services/audio/audio_limits.dart';
import '../../../translator/data/model/translation_result.dart';
import '../model/translation_history_entry.dart';
import 'translation_history_store.dart';

class FileTranslationHistoryStore implements TranslationHistoryStore {
  FileTranslationHistoryStore({
    Future<Directory> Function()? root,
    DateTime Function()? clock,
  }) : _root = root ?? getApplicationDocumentsDirectory,
       _clock = clock ?? DateTime.now;

  static const int maxEntries = 50;

  final Future<Directory> Function() _root;
  final DateTime Function() _clock;
  Future<void> _queue = Future.value();

  @override
  Future<List<TranslationHistoryEntry>> load() => _serial(_read);

  @override
  Future<void> save(TranslationResult result, String sourceName) =>
      _serial(() async {
        final directory = await _directory();
        final now = _clock();
        final id = '${now.microsecondsSinceEpoch}';
        final extension = AudioLimits.extensionOf(result.audioPath);
        final suffix = extension.isEmpty ? '' : '.$extension';
        final audio = await File(result.audioPath)
            .copy('${directory.path}/$id$suffix');
        final entry = TranslationHistoryEntry(
          id: id,
          createdAt: now,
          sourceName: sourceName,
          targetName: result.language.displayName,
          originalText: result.originalText,
          translatedText: result.translatedText,
          audioPath: audio.path,
        );
        final entries = [entry, ...await _read()];
        for (final dropped in entries.skip(maxEntries)) {
          await _deleteAudio(dropped);
        }
        await _write(entries.take(maxEntries).toList());
      });

  @override
  Future<void> delete(String id) => _serial(() async {
    final entries = await _read();
    for (final entry in entries.where((entry) => entry.id == id)) {
      await _deleteAudio(entry);
    }
    await _write(entries.where((entry) => entry.id != id).toList());
  });

  @override
  Future<void> clear() => _serial(() async {
    final directory = await _directory();
    await directory.delete(recursive: true);
  });

  Future<T> _serial<T>(Future<T> Function() task) {
    final next = _queue.then((_) => task());
    _queue = next.then<void>((_) {}, onError: (Object _) {});
    return next;
  }

  Future<Directory> _directory() async {
    final root = await _root();
    final directory = Directory('${root.path}/translation_history');
    if (!await directory.exists()) await directory.create(recursive: true);
    return directory;
  }

  Future<File> _index() async {
    final directory = await _directory();
    return File('${directory.path}/index.json');
  }

  Future<List<TranslationHistoryEntry>> _read() async {
    final index = await _index();
    if (!await index.exists()) return [];
    final json = jsonDecode(await index.readAsString());
    if (json is! List<dynamic>) return [];
    final entries = [
      for (final item in json) ?TranslationHistoryEntry.fromJson(item),
    ];
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<void> _write(List<TranslationHistoryEntry> entries) async {
    final index = await _index();
    await index.writeAsString(
      jsonEncode([for (final entry in entries) entry.toJson()]),
      flush: true,
    );
  }

  Future<void> _deleteAudio(TranslationHistoryEntry entry) async {
    final file = File(entry.audioPath);
    if (await file.exists()) await file.delete();
  }
}
