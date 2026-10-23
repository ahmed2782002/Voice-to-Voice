import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(_read(_preferences));

  static const String storageKey = 'theme_mode';

  final SharedPreferences _preferences;

  bool get isDark => state != ThemeMode.light;

  Future<void> select(ThemeMode mode) async {
    if (mode == state) return;
    emit(mode);
    await _preferences.setString(storageKey, mode.name);
  }

  static ThemeMode _read(SharedPreferences preferences) =>
      switch (preferences.getString(storageKey)) {
        'light' => ThemeMode.light,
        _ => ThemeMode.dark,
      };
}
