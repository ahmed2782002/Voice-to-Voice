# VoxBridge — agent instructions

## No comments in this project

- Never write comments of any kind in project code: no `//`, no `///`, no `/* */`, no `TODO`, no commented-out code.
- This applies to `lib/`, `test/`, and config files you edit (`pubspec.yaml`, `analysis_options.yaml`, manifests).
- Names explain the code. If something needs explaining, rename it or move the logic into the Cubit.
- This rule overrides any guidance in `lib/core/doc/` that asks for a justification comment (`MAINT-3`, `MAINT-6`, the `///` exception in `PROJECT.md`).

لا تكتب أي كومنتات في المشروع نهائيًا.

## Engineering policy

Before any non-trivial change, read `lib/core/doc/flutter_full_agent/flutter-expert.md` and follow the loop and precedence it defines. `PROJECT.md` in that folder describes a different repository (Laundo); measure this repository instead of trusting it.

Tests follow `lib/core/doc/code_test/WIDGET_TEST_GUIDELINES.md`, `UNIT_TEST_GUIDELINES.md` and `INTEGRATION_TEST_GUIDELINES.md`.

## Project layout

```
lib/core/config/                SupabaseConfig (project URL, publishable key, functions URL)
lib/core/services/audio/        recorder, player and file picker interfaces plus device implementations, limits, import formats
lib/core/services/auth/         AccessTokenProvider, SupabaseSessionService (silent anonymous sign-in)
lib/core/services/preferences/  AiNoticeStore, PreferencesAiNoticeStore (AI notice shown until the first translation)
lib/core/routing/               FadeRoute
lib/core/theme/                 AppTheme (light and dark ThemeData), ThemeCubit (saved ThemeMode)
lib/core/utils/constants/       AppPalette (dark and light), AppColors (context.colors), AppText (context.text), AppIcons, AppStrings, AppRadii
lib/core/utils/format/          DurationFormat (localized digits)
lib/core/widgets/               GlassCard, AudioWaveform, AudioControlButton, AppLogo, PulseRingsPainter, settings sheets (language, theme)
lib/feature/splash/             SplashScreen, SplashStage, SplashMotion (pure animation curves)
lib/feature/history/            local translation history: TranslationHistoryEntry, FileTranslationHistoryStore, HistoryCubit, HistoryScreen
lib/feature/translator/
  data/model/                   TranslationLanguage, TranslationResult, TranslatorApiException
  data/repo/                    TranslatorRepo (GET /languages, POST /translate-voice)
  presentation/view/screen/     TranslatorScreen
  presentation/view/widgets/    one public widget per file
  presentation/view_model/      TranslatorCubit, TranslatorState
assets/translations/            en.json, ar.json (easy_localization)
test/helpers/                   fakes.dart, pump_app.dart
test/feature/translator/        widget, cubit and repo tests
test/feature/splash/            splash motion and screen tests
test/core/theme/                ThemeCubit tests
test/feature/history/           history store and cubit tests
assets/branding/                app icon, adaptive icon layers, native splash logo
```

Colors are theme-aware: read them with `context.colors` and text styles with `context.text`, never as static constants. Add a new color to both `AppPalette.dark` and `AppPalette.light`. After changing `assets/branding/`, run `dart run flutter_launcher_icons` and `dart run flutter_native_splash:create`.

The Supabase publishable key is the only key in the app. Edge Functions need the anonymous user's JWT as the Bearer token; the publishable key goes in the `apikey` header only.

## Rules that apply here

- State management is `flutter_bloc` Cubit. One Cubit per screen, created in its `BlocProvider`.
- Screens are `StatelessWidget`. Logic and derived values live in the Cubit or the state.
- No private widget classes, no methods that return widgets, one class per file.
- Colors, text styles, icons and strings come from `lib/core/utils/constants/`. No inline hex, `TextStyle`, `Icons.*` or literal UI text in features.
- Every user-facing string is added to both `assets/translations/en.json` and `ar.json`.
- Never force `Directionality`. Use `EdgeInsetsDirectional` and `AlignmentDirectional`.
- The OpenAI API key never goes in the Flutter app, its assets, or the repository.
- Run `flutter analyze` and `flutter test` before saying a change is done.
