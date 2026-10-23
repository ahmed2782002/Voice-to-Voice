import '../../../translator/data/model/translation_result.dart';
import '../model/translation_history_entry.dart';

abstract interface class TranslationHistoryStore {
  Future<List<TranslationHistoryEntry>> load();

  Future<void> save(TranslationResult result, String sourceName);

  Future<void> delete(String id);

  Future<void> clear();
}
