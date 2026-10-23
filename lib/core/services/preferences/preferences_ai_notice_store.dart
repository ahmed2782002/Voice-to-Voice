import 'package:shared_preferences/shared_preferences.dart';

import 'ai_notice_store.dart';

class PreferencesAiNoticeStore implements AiNoticeStore {
  PreferencesAiNoticeStore(this._preferences);

  static const String storageKey = 'ai_notice_seen';

  final SharedPreferences _preferences;

  @override
  bool get seen => _preferences.getBool(storageKey) ?? false;

  @override
  Future<void> markSeen() => _preferences.setBool(storageKey, true);
}
