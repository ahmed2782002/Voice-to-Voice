import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.brightness,
    required this.backgroundTop,
    required this.backgroundBottom,
    required this.surface,
    required this.surfaceRaised,
    required this.border,
    required this.onAction,
    required this.cyan,
    required this.cyanBright,
    required this.accentDeep,
    required this.accent,
    required this.accentLight,
    required this.mintDeep,
    required this.mintSurface,
    required this.mint,
    required this.mintBright,
    required this.coral,
    required this.coralLight,
    required this.coralSurface,
    required this.textPrimary,
    required this.textSecondary,
    required this.textMuted,
    required this.error,
    required this.errorSurface,
    required this.recording,
    required this.glowStrength,
  });

  final Brightness brightness;
  final Color backgroundTop;
  final Color backgroundBottom;
  final Color surface;
  final Color surfaceRaised;
  final Color border;
  final Color onAction;
  final Color cyan;
  final Color cyanBright;
  final Color accentDeep;
  final Color accent;
  final Color accentLight;
  final Color mintDeep;
  final Color mintSurface;
  final Color mint;
  final Color mintBright;
  final Color coral;
  final Color coralLight;
  final Color coralSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color error;
  final Color errorSurface;
  final Color recording;
  final double glowStrength;

  static const AppPalette dark = AppPalette(
    brightness: Brightness.dark,
    backgroundTop: Color(0xFF0B1E2D),
    backgroundBottom: Color(0xFF050C14),
    surface: Color(0xFF10263A),
    surfaceRaised: Color(0xFF163049),
    border: Color(0xFF21405A),
    onAction: Color(0xFF04121C),
    cyan: Color(0xFF0FB5C9),
    cyanBright: Color(0xFF2EE6F2),
    accentDeep: Color(0xFF0E2F52),
    accent: Color(0xFF3B82F6),
    accentLight: Color(0xFF7CB8FF),
    mintDeep: Color(0xFF0B2E2A),
    mintSurface: Color(0xFF12393A),
    mint: Color(0xFF7FE3C4),
    mintBright: Color(0xFF34EDC0),
    coral: Color(0xFFF5A35B),
    coralLight: Color(0xFFF8C995),
    coralSurface: Color(0xFF3A2A1C),
    textPrimary: Color(0xFFF4F8FB),
    textSecondary: Color(0xFFB4C6D6),
    textMuted: Color(0xFF7C93A8),
    error: Color(0xFFFF6B7F),
    errorSurface: Color(0xFF3B1A26),
    recording: Color(0xFFFF4D6D),
    glowStrength: 1,
  );

  static const AppPalette light = AppPalette(
    brightness: Brightness.light,
    backgroundTop: Color(0xFFF3F8FB),
    backgroundBottom: Color(0xFFE2EEF4),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFEFF5F9),
    border: Color(0xFFCFDDE7),
    onAction: Color(0xFF04121C),
    cyan: Color(0xFF0891B2),
    cyanBright: Color(0xFF06B6D4),
    accentDeep: Color(0xFFDCEBFF),
    accent: Color(0xFF2563EB),
    accentLight: Color(0xFF60A5FA),
    mintDeep: Color(0xFFD5F1E7),
    mintSurface: Color(0xFFEAF8F2),
    mint: Color(0xFF0B8F6C),
    mintBright: Color(0xFF10B981),
    coral: Color(0xFFE07B2E),
    coralLight: Color(0xFF8A4A14),
    coralSurface: Color(0xFFFFF1E3),
    textPrimary: Color(0xFF0E1B2A),
    textSecondary: Color(0xFF3E5468),
    textMuted: Color(0xFF6B8196),
    error: Color(0xFFD33A55),
    errorSurface: Color(0xFFFDEBEE),
    recording: Color(0xFFE11D48),
    glowStrength: 0.5,
  );

  bool get isDark => brightness == Brightness.dark;

  SystemUiOverlayStyle get overlayStyle => isDark
      ? SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: backgroundBottom,
        )
      : SystemUiOverlayStyle.dark.copyWith(
          statusBarColor: Colors.transparent,
          systemNavigationBarColor: backgroundBottom,
        );

  LinearGradient get background => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [backgroundTop, backgroundBottom],
  );

  LinearGradient get action => LinearGradient(
    colors: [cyanBright, mintBright, accentLight],
    stops: const [0, 0.55, 1],
  );

  LinearGradient get mic => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanBright, accent],
  );

  LinearGradient get micRecording => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [coral, recording],
  );

  LinearGradient get translatedCard => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [mintSurface, mintDeep],
  );

  List<BoxShadow> get actionGlow => [
    BoxShadow(
      color: cyanBright.withValues(alpha: 0.4 * glowStrength),
      blurRadius: 24,
      spreadRadius: 1,
    ),
  ];

  List<BoxShadow> get micGlow => [
    BoxShadow(
      color: cyanBright.withValues(alpha: 0.5 * glowStrength),
      blurRadius: 32,
      spreadRadius: 4,
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.4 * glowStrength),
      blurRadius: 48,
      spreadRadius: 8,
    ),
  ];

  List<BoxShadow> get logoGlow => [
    BoxShadow(
      color: cyanBright.withValues(alpha: 0.35 * glowStrength),
      blurRadius: 40,
    ),
    BoxShadow(
      color: accent.withValues(alpha: 0.3 * glowStrength),
      blurRadius: 72,
      offset: const Offset(0, 12),
    ),
  ];

  List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: isDark ? const Color(0x26000000) : const Color(0x0F0E1B2A),
      offset: const Offset(0, 8),
      blurRadius: isDark ? 24 : 18,
    ),
  ];

  List<BoxShadow> get micRecordingGlow => [
    BoxShadow(
      color: recording.withValues(alpha: 0.5 * glowStrength),
      blurRadius: 32,
      spreadRadius: 4,
    ),
  ];

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}
