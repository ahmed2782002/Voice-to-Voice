import 'package:flutter_test/flutter_test.dart';
import 'package:voice_to_voice/feature/history/data/model/translation_history_entry.dart';
import 'package:voice_to_voice/feature/history/presentation/view_model/history_cubit.dart';
import 'package:voice_to_voice/feature/history/presentation/view_model/history_state.dart';

import '../../helpers/fakes.dart';

TranslationHistoryEntry sampleEntry(String id) => TranslationHistoryEntry(
  id: id,
  createdAt: DateTime(2026, 10, 23, 9, int.parse(id)),
  sourceName: 'Arabic',
  targetName: 'English',
  originalText: 'مرحبا $id',
  translatedText: 'Hello $id',
  audioPath: '/tmp/history_$id.mp3',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeHistoryStore store;
  late FakeAudioPlayerService player;
  late HistoryCubit cubit;

  setUp(() {
    store = FakeHistoryStore()
      ..entries.addAll([sampleEntry('2'), sampleEntry('1')]);
    player = FakeAudioPlayerService();
    cubit = HistoryCubit(store: store, player: player);
  });

  tearDown(() async {
    if (!cubit.isClosed) await cubit.close();
  });

  Future<void> flush() => Future<void>.delayed(Duration.zero);

  group('HistoryCubit', () {
    test('loads saved translations', () async {
      await cubit.load();

      expect(cubit.state.status, HistoryStatus.ready);
      expect(cubit.state.entries.map((entry) => entry.id), ['2', '1']);
    });

    test('reports a load failure', () async {
      store.loadError = Exception('broken index');

      await cubit.load();

      expect(cubit.state.status, HistoryStatus.failed);
    });

    test('plays, pauses and switches between entries', () async {
      await cubit.load();
      final first = cubit.state.entries.first;
      final second = cubit.state.entries.last;

      await cubit.togglePlayback(first);
      await flush();
      expect(cubit.state.isPlayingEntry(first.id), isTrue);
      expect(player.openedPath, first.audioPath);

      await cubit.togglePlayback(first);
      await flush();
      expect(cubit.state.isPlayingEntry(first.id), isFalse);

      await cubit.togglePlayback(second);
      await flush();
      expect(cubit.state.isPlayingEntry(second.id), isTrue);
      expect(player.openedPath, second.audioPath);
    });

    test('reports a playback failure', () async {
      await cubit.load();
      player.failOnOpen = true;

      await cubit.togglePlayback(cubit.state.entries.first);

      expect(cubit.state.playbackFailed, isTrue);
      expect(cubit.state.activeId, isNull);
    });

    test('deletes an entry and stops it when it is playing', () async {
      await cubit.load();
      final first = cubit.state.entries.first;
      await cubit.togglePlayback(first);

      await cubit.delete(first);

      expect(store.deleted, [first.id]);
      expect(cubit.state.entries.map((entry) => entry.id), ['1']);
      expect(cubit.state.activeId, isNull);
      expect(player.stopCalls, greaterThanOrEqualTo(2));
    });

    test('clears every entry', () async {
      await cubit.load();

      await cubit.clear();

      expect(store.clearCalls, 1);
      expect(cubit.state.entries, isEmpty);
      expect(cubit.state.isEmpty, isTrue);
    });

    test('releases the player on close', () async {
      await cubit.close();

      expect(player.disposed, isTrue);
    });
  });
}
