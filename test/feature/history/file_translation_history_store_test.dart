import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/feature/history/data/repo/file_translation_history_store.dart';
import 'package:voice_to_voice/feature/translator/data/model/translation_result.dart';

import '../../helpers/fakes.dart';

void main() {
  late Directory root;
  late DateTime now;
  late FileTranslationHistoryStore store;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('history_store_test');
    now = DateTime(2026, 10, 23, 9);
    store = FileTranslationHistoryStore(
      root: () async => root,
      clock: () => now = now.add(const Duration(minutes: 1)),
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<TranslationResult> result(String text) async {
    final audio = File('${root.path}/translated_$text.mp3');
    await audio.writeAsBytes(List.filled(64, 3));
    return TranslationResult(
      audioPath: audio.path,
      language: SampleLanguages.english,
      sourceLanguageCode: 'ar',
      originalText: 'مرحبا $text',
      translatedText: 'Hello $text',
    );
  }

  group('FileTranslationHistoryStore', () {
    test('saves a copy of the audio and returns newest first', () async {
      await store.save(await result('one'), 'Arabic');
      await store.save(await result('two'), 'Arabic');

      final entries = await store.load();

      expect(entries.map((entry) => entry.translatedText), [
        'Hello two',
        'Hello one',
      ]);
      expect(entries.first.sourceName, 'Arabic');
      expect(entries.first.targetName, 'English');
      expect(entries.first.audioPath, contains('translation_history'));
      expect(await File(entries.first.audioPath).exists(), isTrue);
    });

    test('keeps the saved audio after the temporary file is deleted', () async {
      final saved = await result('one');
      await store.save(saved, 'Arabic');

      await File(saved.audioPath).delete();
      final entries = await store.load();

      expect(await File(entries.single.audioPath).exists(), isTrue);
    });

    test('deletes one entry together with its audio', () async {
      await store.save(await result('one'), 'Arabic');
      await store.save(await result('two'), 'Arabic');
      final target = (await store.load()).last;

      await store.delete(target.id);

      final entries = await store.load();
      expect(entries.map((entry) => entry.translatedText), ['Hello two']);
      expect(await File(target.audioPath).exists(), isFalse);
    });

    test('clears every entry and file', () async {
      await store.save(await result('one'), 'Arabic');
      final audio = (await store.load()).single.audioPath;

      await store.clear();

      expect(await store.load(), isEmpty);
      expect(await File(audio).exists(), isFalse);
    });

    test('keeps only the newest entries within the limit', () async {
      for (
        var index = 0;
        index < FileTranslationHistoryStore.maxEntries + 2;
        index++
      ) {
        await store.save(await result('$index'), 'Arabic');
      }

      final entries = await store.load();

      expect(entries, hasLength(FileTranslationHistoryStore.maxEntries));
      expect(entries.first.translatedText, 'Hello 51');
    });
  });
}
