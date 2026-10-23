import 'package:flutter/material.dart';

import '../utils/constants/app_palette.dart';

abstract final class AppTheme {
  static ThemeData get dark => _build(AppPalette.dark);

  static ThemeData get light => _build(AppPalette.light);

  static ThemeData _build(AppPalette palette) {
    final scheme =
        ColorScheme.fromSeed(
          seedColor: palette.cyan,
          brightness: palette.brightness,
        ).copyWith(
          primary: palette.cyanBright,
          secondary: palette.accent,
          surface: palette.surface,
          error: palette.error,
          onSurface: palette.textPrimary,
        );
    return ThemeData(
      brightness: palette.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: palette.backgroundBottom,
      extensions: [palette],
      popupMenuTheme: PopupMenuThemeData(
        color: palette.surfaceRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: palette.border),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.surface,
        surfaceTintColor: Colors.transparent,
        modalBarrierColor: Colors.black.withValues(alpha: 0.45),
      ),
    );
  }
}
