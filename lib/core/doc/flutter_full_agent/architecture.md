# Architecture, dependency injection & repository discovery — canonical rules

**Canonical home for:** `ARCH-1` … `ARCH-7`, plus repository discovery (§2) and baseline measurements (§3)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Read this file during INSPECT, MEASURE and MAP** (§1). §2 is the existing-pattern-first and
discovery-checklist policy; §3 is the measurement protocol whose output feeds the register
(`register.md` §9). The discovery checklist and the baseline table both cite rule IDs owned
by other files — follow the ID, don't re-derive the rule.

---

# 2. Repository discovery — before writing anything

## 2.1 Existing-pattern-first

Before introducing any new abstraction — a base class, a helper, a service — do this, in order:

1. Search for an existing implementation of the same concern.
2. Search for equivalent behavior under a *different* name (a "retry" concern might be
   `RetryPolicy`, `withRetry`, or live inline inside an interceptor with no name at all).
3. Read the existing implementation's actual content and confirm it's correct and compatible —
   a matching name is not evidence of matching behavior.
4. Reuse it if compatible.
5. Extend it if a small, non-breaking addition covers your need.
6. Create something new only if none of the above hold — and state, in your report, why.

Forking a second, slightly different version of an existing concern is how two versions of the
same guard start disagreeing with each other inside one codebase, or across the org's repos.
(See `MAINT-5` for the single-use-abstraction angle on the same problem.)

## 2.2 Discovery checklist

Verify each row by reading the file's actual contents, not by trusting its filename or assuming
it matches another repo's version — different projects on this stack name these differently.

| Concern | Where to look first | Verify — don't assume |
|---|---|---|
| Repository base class | `core/base/base_repository.dart` or similar | Its real method signatures, not just that a `safeCall`-shaped thing exists |
| Cubit base class | `core/base/base_cubit.dart` | Whether it exposes a guarded emit (`STATE-2`) and loading/error helpers, or just wraps `emit` |
| State base class | `core/base/base_state.dart` | Whether `copyWith` can explicitly *clear* an error, not just set one |
| HTTP client | `core/network/*client*.dart` | Whether `cancelToken` is actually threaded through every method, or only declared on some (`NET-3`) |
| Interceptors (401 / retry) | `core/network/*interceptor*.dart` | Whether 401 refresh is single-flight; whether a retry interceptor exists at all (`NET-2`) |
| Token refresh | `core/network/token_refresher.dart` | Whether it's actually single-flight, or only intended to be (`NET-4`) |
| Failure hierarchy | `core/failure/failure.dart`, `error_code.dart` | Whether it's a closed (`sealed`) set, or an open class that invites string comparison (`SEC-5`) |
| Response envelope | `core/network/*response*.dart` | Its actual "is this a failure" logic — does it treat an empty body as success? (`SEC-7`) |
| Endpoint constants | `core/network/endpoints.dart` | Whether path casing is copied verbatim from the API docs or silently normalized (`ARCH-5`) |
| Dependency injection | `core/services/di/*.dart` | Actual registration lifetime per class — factory vs. lazy singleton (`ARCH-1`) |
| Storage — secrets vs. prefs | `core/local_storage/*`, `core/cache/*` | That tokens genuinely live only in the secure one (`SEC-1`) |
| Logging | `core/utils/app_logger.dart` | Whether it compiles out in release — raises `PROD-1`'s urgency if so |
| Remote image widget | `core/widgets/*image*.dart` | Whether it already has an `errorWidget` and any decode-size tuning (`PERF-4`) |
| Pagination | `core/base/paginated_cubit.dart` | Whether every paged list actually uses it, or some rolled their own (`ARCH-4`) |
| Localization / RTL | wherever `easy_localization` is initialized | Whether `*Directional` insets are used consistently (`A11Y-5`) |
| Theme / shared constants | `core/utils/constants/*` | That strings/colors/styles/icons genuinely route through here, not inlined (`STYLE-1..4`) |
| Routing / deep links | router config + manifest `intent-filter` entries | Whether any validation code exists for what a link resolves to (`PROD-5`) |
| Crash reporting | `pubspec.yaml` | Presence of Crashlytics/Sentry, not just `firebase_core` (`PROD-1`) |
| CI | repo root / `.github`, `.gitlab-ci.yml`, etc. | Whether it actually runs on PRs, not just whether a config file exists (`PROD-2`) |
| Environment configuration | wherever the base URL is defined | Whether it's a single hard-coded literal or `--dart-define`-backed (`PROD-3`) |

If a required abstraction genuinely does not exist: don't pretend it does, don't silently invent
a second competing one, record the gap in REGISTER (§9), and introduce the smallest compatible
abstraction only if the current task actually needs it to proceed.

---

# 3. Baseline measurements

Run these against **the repository you're in**, scoped to what the current task actually
touches — you don't need to re-measure everything for a one-line fix. The right-hand column is
illustrative, from a past project on this stack, to show what each number tells you; it is not a
claim about your repository.

**A command is not portable just because it ran somewhere.** Every path below is a guess about
directory names until you check it (`ls lib`). A grep pointed at a directory this repository does not
have returns `0`, and a `0` reads as "clean" — that is a false negative, and §0.5 makes it your
problem, not the command's. Confirm the path, then run the grep.

**This repository's measured baseline, with the paths corrected, is in `register.md`** under
*Baseline measurements*. Re-run those, not these, and update them in place rather than adding a
second table.

| Measurement | Command (adapt paths) | Illustrative finding elsewhere | Feeds into |
|---|---|---|---|
| `BlocSelector`/`BlocBuilder`/`BlocConsumer` counts | `grep -rn "BlocSelector<\|BlocBuilder<\|BlocConsumer<" lib --include=*.dart \| wc -l` | 66 / 32 / 0 | `PERF-2` |
| `buildWhen` + `listenWhen` | `grep -rn "buildWhen\|listenWhen" lib --include=*.dart \| wc -l` | 8, used but undocumented | `PERF-2` |
| `SingleChildScrollView` vs. `ListView.builder` vs. unbounded `ListView(` | `grep -rn "SingleChildScrollView\|ListView.builder\|ListView(" lib --include=*.dart` | 33 / 8 / 0 | `PERF-3` |
| `CancelToken` at call sites | `grep -rn "CancelToken" lib --include=*.dart \| grep -v <http_client_file>` | 0, despite full client support | `NET-3` |
| `compute` / `Isolate` usage | `grep -rn "compute(\|Isolate\." lib --include=*.dart \| wc -l` | 0, with `Skipped N frames` in the device log | `PERF-1` |
| `memCacheWidth` / image cache tuning | `grep -rn "memCacheWidth\|imageCache" lib --include=*.dart \| wc -l` | 0 | `PERF-4` |
| `Semantics(` / `textScaler` | `grep -rn "Semantics(\|textScaler" lib --include=*.dart \| wc -l` | 3 / 0 | `A11Y-1`, `A11Y-4` |
| `PopScope` | `grep -rn "PopScope" lib --include=*.dart \| wc -l` | 0 | `LIFE-5` |
| `AppLifecycleState` handling | `grep -rn "AppLifecycleState" lib --include=*.dart \| wc -l` | 4, one feature only | `LIFE-4` |
| Cross-feature imports | **Confirm the directory name first** (`ls lib`) — it is `feature/` in some repos on this stack and `features/` in others. Then: `grep -rno "\.\./\.\./\.\./[a-zA-Z_]*/" lib/<features-dir> --include=*.dart \| sed 's/.*\.\.\///' \| sort \| uniq -c \| sort -rn` and discount the `core/` rows | 0 | `ARCH-6` |
| Custom lint rules enabled | Read `analysis_options.yaml` | every custom rule commented out | §7 |
| Test files vs. recent bugfix commits | `find . -name "*_test.dart" \| wc -l`, diff against recent fixes | 4 files, 1 of 5 recent fixes covered | `TEST-2` |
| Crash reporting present | Check `pubspec.yaml` | `firebase_core` + `firebase_messaging` only, no reporter | `PROD-1` |
| CI workflows present | `ls .github/workflows` (or equivalent) | absent | `PROD-2` |
| Environments | Read the base-URL constant / `--dart-define` usage | one hard-coded literal | `PROD-3` |
| `applicationId` / bundle id | `android/app/build.gradle`, iOS bundle id | still `com.example.*` | `PROD-4` |
| `intent-filter` vs. deep-link handling code | `grep -c intent-filter AndroidManifest.xml`, then grep for a link parser | 2 filters, 0 lines of handling | `PROD-5` |
| HTTP client timeouts | Read the Dio/HTTP client config | one 30s timeout shared by connect/receive/send, on an app that uploads video | `NET-1` |
| Retry interceptor | `grep -rn "RetryInterceptor\|dio_smart_retry" lib` | none | `NET-2` |

Keep the resulting facts somewhere the next session on this file can re-run them. A stale
baseline is worse than none — it tells you a gap is closed when it isn't.

---

## 6.2 Architecture & dependency injection (`ARCH-*`)

**`ARCH-1` 🟠 — GetIt constructor injection only. Repositories `registerLazySingleton`, cubits
`registerFactory`.**
*Why:* a cubit registered as a singleton outlives the screen, and its controllers outlive it with
it — a live leak that only shows up as a slow memory climb, not a crash. *Verification:* check
every cubit's registration lifetime in `§2.2`'s DI row.

**`ARCH-2` 🟠 — No cubit-to-cubit calls; communicate through a repository or a service stream.**
*Why:* this is the rule that keeps features independent from each other. *Exception:* a parent
feature with sub-features (e.g. a `messages/*` tree) may share a cubit internally.

**`ARCH-3` 🔴 — Never pass or store `BuildContext` in a cubit, repository, or service.**
*Why:* these objects can outlive the widget tree that created the context, and holding it there
invites exactly the deactivated-context failure `SEC-9` prevents in widgets. *Exception:* none.

**`ARCH-4` 🟠 — Use the shared paginated-list base for every paged list; no second
implementation.**
*Exception:* unpaged lookups (countries, interests, similar small fixed sets) don't need it.

**`ARCH-5` 🟡 — Copy query-parameter casing verbatim from the API docs.**
*Why:* inconsistent casing across endpoints on the same backend is common on this stack (e.g.
`SkipCount` on one endpoint, `skipCount` on another) — normalizing it silently is not a cleanup,
it's a bug against the real contract.

**`ARCH-6` 🟠 — No feature imports another feature; shared code moves to `core/`.**
*Verification:* the `§3` cross-feature-import grep should read zero; if it doesn't, that's a
`§9` REGISTER entry, not something to fix as an unrelated drive-by (`§0.6`).

**`ARCH-7` 🟠 — Keep DTO, Model, and Mapper separate.**
DTO speaks the server's field names and is fully nullable; Model speaks the app's names and is
non-null; the Mapper is the only thing that knows both. *Why:* with this separation, a backend
field rename costs one file, not twenty.
