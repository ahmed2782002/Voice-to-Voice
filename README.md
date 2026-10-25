# VoxBridge: Multilingual Voice-to-Voice Translator

VoxBridge is a Flutter app that translates speech into speech. The user records a message (or imports an audio file) in any supported language, picks a target language, and gets back a playable recording that says the same thing in that language, together with the original and translated text.

Translation runs through real OpenAI models behind a Supabase Edge Functions backend. The OpenAI key exists only on that backend.

---

## Contents

1. [Status against the assessment](#status-against-the-assessment)
2. [Versions](#versions)
3. [Setup and run](#setup-and-run)
4. [Configuration](#configuration)
5. [Backend service](#backend-service)
6. [Models used](#models-used)
7. [Architecture](#architecture)
8. [Processing flow](#processing-flow)
9. [User interface and states](#user-interface-and-states)
10. [Language coverage](#language-coverage)
11. [Languages tested](#languages-tested)
12. [Recording and file limits](#recording-and-file-limits)
13. [Audio privacy and API security](#audio-privacy-and-api-security)
14. [Tests](#tests)
15. [Manual end-to-end test log](#manual-end-to-end-test-log)
16. [Platforms and devices tested](#platforms-and-devices-tested)
17. [Known issues and limitations](#known-issues-and-limitations)

---

## Status against the assessment

| Requirement | Status |
|---|---|
| Record, stop, preview, discard and re-record inside the app | ✅ `record` + `just_audio` |
| Microphone permission requested, denial and permanent denial handled | ✅ `permission_handler`, retry and "open settings" paths |
| Any supported source language accepted, auto-detected | ✅ Backend detects the spoken language |
| Every supported target language in the selector, no fixed subset | ✅ 57 languages loaded from `GET /languages`, searchable |
| Playable translated audio that keeps names, numbers and questions | ✅ Verified with real OpenAI responses (see [test log](#manual-end-to-end-test-log)) |
| Translate only: no answering, summarising or added content | ✅ Verified on a recording that contains a question |
| Original and translated recordings clearly distinguished, play/pause/replay | ✅ Separate cards, one shared player, no overlapping audio |
| Same recording re-submitted for another target language | ✅ Verified on device (English to Arabic, then to Japanese) |
| New recording or translation without restarting | ✅ |
| Idle, recording, processing, ready-to-play and error states | ✅ |
| Duplicate-submit prevention, retry after recoverable failures | ✅ Retry for network, timeout, `RATE_LIMITED`, `UPSTREAM_*` |
| Permission denial, empty/invalid recording, network/API failures | ✅ Each mapped to a clear message and recovery action |
| A failed request never appears as a successful translation | ✅ Covered by tests |
| Clear notice that the translated voice is AI-generated | ✅ Banner until the first translation, plus a permanent "AI-generated voice" label on every result |
| Clear notice that audio is sent for processing | ✅ Under the Translate button |
| Recording and file limits documented, temporary files cleaned up | ✅ See [limits](#recording-and-file-limits) |
| Resources released on navigation, backgrounding and repeated actions | ✅ Playback/recording paused on background and when opening history |
| OpenAI key kept off the app, on a backend | ✅ Supabase Edge Functions, anonymous session + `requireUser` |
| Separate presentation, application logic and API/audio services | ✅ See [architecture](#architecture) |
| Automated tests for state transitions and failure handling | ✅ 109 tests |
| Optional: import existing audio files | ✅ mp3, m4a, mp4, wav, webm, ogg/opus, flac |
| Optional: show original and translated text | ✅ |
| Optional: local translation history with deletion | ✅ On device only, delete one or all |
| Optional: additional mobile platform | ⚠️ iOS project configured, not built or tested (no macOS machine) |

## Versions

| Tool | Version |
|---|---|
| Flutter | 3.47.1 (stable) |
| Dart | 3.13.1 |
| Android | `minSdk` 24 (Flutter default), `compileSdk` 37 |

Main packages: `flutter_bloc`, `equatable`, `supabase_flutter`, `dio`, `connectivity_plus`, `record`, `just_audio`, `permission_handler`, `path_provider`, `file_picker`, `shared_preferences`, `easy_localization`, `flutter_screenutil`, `shimmer`, `flutter_native_splash`. Dev: `bloc_test`, `flutter_launcher_icons`.

## Setup and run

```bash
git clone https://github.com/ahmed2782002/Voice-to-Voice.git
cd Voice_to_Voice
flutter pub get
flutter run
```

Build the Android APK:

```bash
flutter build apk --release
```

The APK is written to `build/app/outputs/flutter-apk/app-release.apk`. The release build is signed with the debug key so it installs directly for review; it is not a store build.

Regenerate the launcher icon and native splash after changing `assets/branding/`:

```bash
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

**iOS only:** the generated `ios/Podfile` must enable the microphone permission for `permission_handler`:

```ruby
post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    target.build_configurations.each do |config|
      config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] ||= [
        '$(inherited)',
        'PERMISSION_MICROPHONE=1',
      ]
    end
  end
end
```

## Configuration

All app configuration is in `lib/core/config/supabase_config.dart`:

| Value | Purpose |
|---|---|
| `url` | Supabase project URL |
| `publishableKey` | Supabase publishable key (public by design, identifies the project) |
| `functionsUrl` | `<url>/functions/v1` |

The publishable key is not a secret and cannot call OpenAI by itself. Every function also requires a signed-in user's JWT. To point the app at another project, replace both values with your own:

```dart
static const String url = 'https://<your-project-ref>.supabase.co';
static const String publishableKey = '<your-publishable-key>';
```

The app contains **no OpenAI key, no Supabase secret key and no service-role key**.

Platform configuration:

| File | Setting |
|---|---|
| `android/app/src/main/AndroidManifest.xml` | `RECORD_AUDIO`, `INTERNET` |
| `ios/Runner/Info.plist` | `NSMicrophoneUsageDescription`, `en` and `ar` localizations |

## Backend service

The supporting service is a set of Supabase Edge Functions (`languages` and `translate-voice`) deployed on project `fvxeleurmrxwieqokxpv`.

| | Link |
|---|---|
| App repository | https://github.com/ahmed2782002/Voice-to-Voice |
| Edge Functions (Supabase dashboard, project members only) | https://supabase.com/dashboard/project/fvxeleurmrxwieqokxpv/functions |
| Functions base URL used by the app | `https://fvxeleurmrxwieqokxpv.supabase.co/functions/v1` |

The OpenAI key is stored as an Edge Function secret in that project and is never sent to the app.

Contract used by the app:

| Endpoint | Request | Response |
|---|---|---|
| `GET /functions/v1/languages` | `Authorization: Bearer <user JWT>`, `apikey` | `{"source": [...], "target": [...], "references": {"input": "...", "output": "..."}}`, each item `{code, name, native, input, output}` |
| `POST /functions/v1/translate-voice` | multipart: `audio` (file), `targetLanguage`, optional `sourceLanguage` | `{sourceLanguage, targetLanguage, originalText, translatedText, audio: {mimeType, base64}, aiGenerated}` |

Errors are always `{"error": {"code", "message", "retryable"}}`. The app maps every code to an Arabic and English message:

| Code | HTTP | App behaviour |
|---|---|---|
| `BAD_REQUEST` | 400 | "Record again" |
| `UNAUTHORIZED` | 401 | Refreshes the session once, then "Try again" |
| `EMPTY_RECORDING` | 422 | "Record again" |
| `FILE_TOO_LARGE` | 413 | "Record again" |
| `UNSUPPORTED_TARGET_LANGUAGE` | 400 | "OK", pick another language |
| `UNSUPPORTED_SOURCE_LANGUAGE` | per backend | "Record again" |
| `NO_SPEECH`, `TEXT_TOO_LONG` | per backend | "Record again" |
| `UNSUPPORTED_INPUT` | 422 | "Record again" |
| `RATE_LIMITED` | 429 | "Try again" (retryable) |
| `UPSTREAM_ERROR`, `UPSTREAM_UNREACHABLE` | 502 | "Try again" (retryable) |
| `UPSTREAM_TIMEOUT` | 504 | "Try again" (retryable) |
| `SERVER_MISCONFIGURED` | 500 | "OK", try later |

Access is restricted to signed-in Supabase users: the app signs in anonymously and silently, and every function calls `requireUser`. The publishable key alone returns `401 UNAUTHORIZED`.

## Models used

All three steps call the OpenAI API from the `translate-voice` Edge Function:

| Step | Model | OpenAI endpoint | Settings |
|---|---|---|---|
| Speech to text (STT), with language detection | `gpt-4o-transcribe` | `POST /v1/audio/transcriptions` | — |
| Text translation | `gpt-4o-mini` | `POST /v1/chat/completions` | `temperature: 0`, JSON response |
| Text to speech (TTS) | `gpt-4o-mini-tts` | `POST /v1/audio/speech` | voice `alloy`, MP3 output |

The backend returns the translated speech as `audio/mpeg`. The app adds no other AI model or third-party AI service.

## Architecture

Three layers, one Cubit per screen:

```
lib/
  core/
    config/          SupabaseConfig
    services/audio/  recorder, player, file picker interfaces and device implementations, limits
    services/auth/   AccessTokenProvider, SupabaseSessionService (silent anonymous sign-in)
    services/preferences/  AI-notice flag
    theme/           light and dark ThemeData, ThemeCubit
    utils/           palette, text styles, icons, strings, formatting
    widgets/         shared widgets (cards, waveform, sheets, dialogs, logo)
  feature/
    splash/          animated splash
    translator/
      data/model/    TranslationLanguage, TranslationResult, TranslatorApiException
      data/repo/     TranslatorRepo (HTTP calls, parsing, error mapping)
      presentation/  TranslatorScreen, widgets, TranslatorCubit, TranslatorState
    history/
      data/          TranslationHistoryEntry, FileTranslationHistoryStore
      presentation/  HistoryScreen, widgets, HistoryCubit, HistoryState
```

| Layer | Responsibility |
|---|---|
| Presentation | Stateless screens and widgets. They render state and forward taps. |
| Application logic | `TranslatorCubit`, `HistoryCubit`, `ThemeCubit`: every state transition, validation, retry decision and resource cleanup. |
| API and audio services | `TranslatorRepo`, `SupabaseSessionService`, `DeviceAudioRecorderService`, `DeviceAudioPlayerService`, `DeviceAudioFilePicker`, `FileTranslationHistoryStore`, all behind interfaces so tests use fakes. |

**Why Cubit.** The screen is a small state machine: idle, recording, recorded, processing, ready, error. Its transitions come from user taps and async results. A Cubit keeps that logic in plain methods with a single immutable state, is easy to unit-test without widgets, and avoids the event boilerplate of a full Bloc. Stale async results are dropped with a request counter, so a late response can never overwrite a newer recording.

## Processing flow

```
Record (AAC-LC .m4a)  or  Import file (mp3/m4a/wav/ogg/webm/flac)
        │  client checks: ≥ 1 s, 2 KB – 5 MB, supported extension, not silent
        ▼
TranslatorRepo ── Authorization: Bearer <anonymous JWT>, apikey ──▶ POST /translate-voice
        │                                                     backend: validate → transcribe
        │                                                     → translate → synthesize
        ▼
200 JSON: texts + base64 audio ──▶ decoded to a temp .mp3 ──▶ player
        │
        └──▶ copied to on-device history (optional feature)
```

Session handling: `SupabaseSessionService` signs in anonymously when there is no session, refreshes an expired one, and re-signs in if refresh fails. A `401` from a function triggers one retry with a fresh token.

## User interface and states

| State | What the user sees |
|---|---|
| Idle | Hint, limits, supported import formats |
| Recording | Live waveform, timer, stop button |
| Recorded or imported | Waveform, play/pause/replay, discard |
| Processing | Shimmer card with "This can take up to a minute", disabled Translate button |
| Ready | Translated card with "AI-generated voice" label, play/pause/replay, original and translated text |
| Error | Error card with a message and one recovery action (Try again, Record again, Choose another file, Open settings, OK) |

Also: animated splash, dark and light themes (saved), Arabic and English UI with full RTL (saved), header menu with History, App language and Appearance.

## Language coverage

`GET /languages` returns **57 input languages and 57 output languages**, every language listed in OpenAI's official references:

- Input (speech to text): https://platform.openai.com/docs/guides/speech-to-text#supported-languages
- Output (text to speech): https://platform.openai.com/docs/guides/text-to-speech#supported-languages

The app shows every language whose `output` flag is true as a target and accepts speech in any language whose `input` flag is true (auto-detected). Nothing is hard-coded in the app.

Afrikaans (af), Arabic (ar), Armenian (hy), Azerbaijani (az), Belarusian (be), Bosnian (bs), Bulgarian (bg), Catalan (ca), Chinese (zh), Croatian (hr), Czech (cs), Danish (da), Dutch (nl), English (en), Estonian (et), Finnish (fi), French (fr), Galician (gl), German (de), Greek (el), Hebrew (he), Hindi (hi), Hungarian (hu), Icelandic (is), Indonesian (id), Italian (it), Japanese (ja), Kannada (kn), Kazakh (kk), Korean (ko), Latvian (lv), Lithuanian (lt), Macedonian (mk), Malay (ms), Maori (mi), Marathi (mr), Nepali (ne), Norwegian (no), Persian (fa), Polish (pl), Portuguese (pt), Romanian (ro), Russian (ru), Serbian (sr), Slovak (sk), Slovenian (sl), Spanish (es), Swahili (sw), Swedish (sv), Tagalog (tl), Tamil (ta), Thai (th), Turkish (tr), Ukrainian (uk), Urdu (ur), Vietnamese (vi), Welsh (cy).

## Languages tested

Tested with real OpenAI responses on 23 October 2026:

| Source | Target | Where | Result |
|---|---|---|---|
| English | Arabic | API and Android device | ✅ Name, time, gate number and question kept |
| Arabic | English | API (input was the Arabic MP3 output) | ✅ |
| English | Japanese | API and Android device | ✅ |
| English | Spanish (source sent explicitly) | API | ✅ |

The sample sentence: "Hello, my name is Ahmed Hassan. My flight lands at 7:30 on Thursday, gate 14. Can you meet me at the airport?" It contains a name, numbers and a question.

All other supported pairs are untested but go through the same pipeline. Reviewers can pick any pair in the selector.

## Recording and file limits

| Limit | Value | Where |
|---|---|---|
| Maximum recording length | 2 minutes (auto-stop) | `AudioLimits.maxRecording` |
| Minimum recording length | 1 second | `AudioLimits.minRecording` |
| Minimum file size | 2 KB (server `EMPTY_RECORDING`) | `AudioLimits.minFileBytes` |
| Maximum file size | 5 MB (server `FILE_TOO_LARGE`) | `AudioLimits.maxFileBytes` |
| Recording format | AAC-LC, `.m4a`, 44.1 kHz mono, 64 kbps | `DeviceAudioRecorderService` |
| Import formats | mp3, mpeg, mpga, m4a, mp4, wav, webm, ogg, opus, flac | `AudioLimits.importExtensions` |
| Client timeout per translation | 90 seconds | `AudioLimits.translationTimeout` |
| Saved history | Up to 50 translations, on device | `FileTranslationHistoryStore.maxEntries` |

Temporary files (recordings, imported copies, decoded translated audio) live in the app's temp directory. They are deleted when the user discards, re-records, imports another file, changes the target language, or closes the screen.

## Audio privacy and API security

- The OpenAI key lives only in the backend's secrets. It is not in the app, its assets, its build configuration, or this repository.
- The app holds only the Supabase publishable key, which is public by design. Every function requires a signed-in user's JWT, so the key alone cannot use the service.
- Users never see a login screen: the app signs in anonymously and silently, and the session is persisted by `supabase_flutter`.
- The UI says, before sending, that the recording is sent to the server for translation and is not stored.
- Translation history is **local to the device only**, holds the translated audio and text, and can be deleted per item or all at once.
- In debug builds only, the raw `/languages` response is printed once. No audio, transcript or token is logged.

## Tests

```bash
flutter analyze
flutter test
```

Result: `No issues found`, **109 tests passed**.

| File | Covers |
|---|---|
| `test/feature/translator/translator_cubit_test.dart` | Recording states and limits, permission denial, every API error code mapped to its failure, retry, stale results dropped, import (cancel, unsupported type, size, picker failure), history saving, AI notice, languages loading and retry, cleanup on close |
| `test/feature/translator/translator_screen_test.dart` | Widget flows: recording, permission, processing and duplicate submit, network error and retry, timeout, rate limit, target change, playback, import, AI-voice label, history screen (delete one, delete all with confirmation), header menu, Arabic layout on a small phone |
| `test/feature/translator/translator_repo_test.dart` | Language response shapes, headers, 401 refresh, multipart upload and file types, size validation, error parsing |
| `test/feature/history/*` | File store (save, order, delete, clear, 50-entry limit), HistoryCubit (play, pause, switch, delete, clear, failures) |
| `test/feature/splash/*`, `test/core/theme/*` | Splash animation and navigation, theme persistence |

Automated tests use fakes for the recorder, player, picker, network and storage. They do not call OpenAI.

## Manual end-to-end test log

Date: 23 October 2026. Backend: live Supabase project. Real OpenAI responses.

| # | Scenario | Steps | Result |
|---|---|---|---|
| 1 | Full translation (API) | `POST /translate-voice` with an English WAV, target `ar` | ✅ 200 in ~10 s, correct Arabic text and MP3 audio |
| 2 | Reverse pair, non-m4a input | Arabic MP3 from #1, target `en` | ✅ 200, faithful English |
| 3 | Other targets | English WAV to `ja`, and to `es` with `sourceLanguage=en` | ✅ 200 |
| 4 | Empty recording | 1.5 KB file | ✅ 422 `EMPTY_RECORDING` |
| 5 | Unsupported format | 4 KB random bytes | ✅ 422 `UNSUPPORTED_INPUT` |
| 6 | File too large | 6 MB file | ✅ 413 `FILE_TOO_LARGE` |
| 7 | Unsupported or missing target | `targetLanguage=xx`, then none | ✅ 400 `UNSUPPORTED_TARGET_LANGUAGE`, 400 `BAD_REQUEST` |
| 8 | No session | Publishable key only | ✅ 401 `UNAUTHORIZED` |
| 9 | Languages | `GET /languages` with an anonymous session | ✅ 57 input, 57 output, official references |
| 10 | Device: import and translate | Release APK on Android 9, import WAV from Downloads, target Arabic | ✅ Imported label and 0:11 duration, translated card with AI label, texts, 0:12 audio |
| 11 | Device: playback | Play translated audio | ✅ Progress and waveform advance, pause and replay available |
| 12 | Device: same recording, new target | Pick Japanese, translate again | ✅ New Japanese audio and text |
| 13 | Device: history | Menu, then Translation history | ✅ Both translations listed with language pair and date |
| 14 | Device: AI notice | First translation | ✅ Banner hidden afterwards, AI-voice label stays on each result |

Network failure, microphone denial and empty recording on device are covered by automated widget tests and are shown in the demo recording.

## Platforms and devices tested

| Platform | Device | Build | Status |
|---|---|---|---|
| Android 9 | LDPlayer emulator, 540×960 | Release APK | ✅ Tested |
| Flutter test VM | — | — | ✅ 109 tests |
| iOS | — | — | ⚠️ Configured, not built or tested (no macOS machine) |

## Known issues and limitations

- **iOS is untested.** The project, permissions and Podfile snippet are in place, but no iOS build was made.
- **TTS voices are tuned for English.** OpenAI notes that its voices are optimised for English, so other languages may sound accented.
- **No manual source-language picker.** The source language is always auto-detected. Very short or mixed-language recordings can be detected as the wrong language.
- **Model translation errors.** None were seen in the tested samples. As with any model, idioms, rare names and homophones can be mistranslated, and the app cannot detect that.
- **Release signing.** The APK is signed with the debug key for easy installation. A store release needs a real signing key.
- **Native splash is always dark.** The OS splash shows before the app knows the saved theme, so light-mode users see a brief dark frame.
- **Imported files** are limited by size (5 MB), not duration. A long, highly compressed file can exceed the backend's text limit and return `TEXT_TOO_LONG`.
- **History** keeps the newest 50 translations and stores only translated audio and text, never the original recording.
