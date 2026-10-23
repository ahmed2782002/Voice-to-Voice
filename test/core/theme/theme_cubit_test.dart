import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voice_to_voice/core/theme/theme_cubit.dart';

void main() {
  Future<SharedPreferences> preferencesWith(Map<String, Object> values) {
    SharedPreferences.setMockInitialValues(values);
    return SharedPreferences.getInstance();
  }

  group('ThemeCubit', () {
    test('starts in dark mode when nothing is saved', () async {
      final cubit = ThemeCubit(await preferencesWith({}));
      addTearDown(cubit.close);

      expect(cubit.state, ThemeMode.dark);
      expect(cubit.isDark, isTrue);
    });

    test('restores a saved light mode', () async {
      final cubit = ThemeCubit(
        await preferencesWith({ThemeCubit.storageKey: 'light'}),
      );
      addTearDown(cubit.close);

      expect(cubit.state, ThemeMode.light);
    });

    test('persists the selected mode', () async {
      final preferences = await preferencesWith({});
      final cubit = ThemeCubit(preferences);
      addTearDown(cubit.close);

      await cubit.select(ThemeMode.light);

      expect(cubit.state, ThemeMode.light);
      expect(preferences.getString(ThemeCubit.storageKey), 'light');
    });
  });
}
