# Project — Laundo

> 🔴 **STALE IN THIS REPOSITORY — read this first.**
>
> This file, and `register.md` beside it, describe **Laundo**. They were copied into
> **yummy_diet** along with `lib/core/`, and almost every fact in them is false here. Precedence
> position 3 (§0.3) says the repository you are actually in outranks the document — which in this
> case means **measure, do not read** (§2, §3). Verified in yummy_diet on **2026-08-30**:
>
> | This file says | yummy_diet actually has |
> |---|---|
> | 21 features under `lib/feature/` | **2** — `choose_language`, `splesh` |
> | `figma.json` at the repository root | `lib/core/doc/figma/` — a per-screen export of the *Yummy Diet* Figma file, with `README.md` |
> | Design system measured at 375×812, family **Cairo**, 105 colours | measured at **390×844**, family **Noto Sans Arabic**, and the constants were rewritten from the Yummy Diet Figma on 2026-08-30 |
> | `app_strings.dart`, 453 keys, laundry domain | **470 keys**, Yummy Diet domain, regenerated from the Figma copy |
> | `applicationId` `com.nahr.laundo.laundo` | `com.nahr.yummy_diet.yummy_diet` |
> | `cached_network_image` declared | **not declared** — no remote-image dependency at all |
> | `main.dart` initialises easy_localization + ScreenUtil, 21 `BlocProvider` sites | **the default Flutter counter demo.** Nothing in `lib/core/` is wired up |
>
> What is still true here: the rule files (`security.md`, `architecture.md`, … — they describe the
> stack, not a repository), the contents of `lib/core/base/`, `lib/core/network/` and
> `lib/core/failure/`, and the two Project-Specific Exceptions at the bottom of this file.
>
> **This banner is not a fix.** Rewriting the body for yummy_diet is a task of its own; doing it as
> a side effect of an unrelated change is what §0.6 forbids. Until then, treat every unmarked
> statement below as a fact about a different repository.

**What this file is.** The facts about **this** repository: what it actually is, not what a typical
app on this stack looks like. It holds no generic Flutter rules — those live in the rule files beside
this one, and the orchestrator that uses them is `flutter-expert.md`.

**Why it matters.** Precedence position 3 (§0.3) says the verified architecture and existing
contracts of the repository you are actually in outrank this policy's assumptions. This file is where
that verified reality is written down. A value here is usable; a value guessed from the stack
description is not (§0.4).

**Status.** Baseline verified **2026-08-25** by reading this repository. Every fact below names the
file or command it came from. Anything unverified still carries `UNKNOWN - needs verification` or
`BLOCKED` — honest states, not omissions, and they may not be filled in by inference (§0.4).

**Related, not duplicated.** Gaps between what this repository does and what the policy requires go
in the register (`register.md` §9), not here. This file records what *is*; the register records what
is *missing*. Historical examples from past projects (`engineering-knowledge.md`) are never a source
for this file.

---

## Architecture

**VERIFIED** — two roots under `lib/`:

```
lib/core/      base · cache · failure · local_storage · network · services/di · utils · widgets
lib/feature/   21 features
lib/main.dart
```

Per-feature layout (`lib/feature/<name>/`):

```
data/repo/<name>_repo.dart                      data/model/…
presentation/view/<name>_view.dart              presentation/view/widgets/…
presentation/view_model/<name>_cubit.dart       presentation/view_model/<name>_state.dart
```

Three naming facts that break greps if you assume otherwise:

- The directory is **`lib/feature/`, singular** — not `lib/features/`. A policy grep written against
  `lib/features/` returns `0` here and reads as "no violations" (§0.5). This is the corrected
  measurement in §3 of `architecture.md`.
- **`lib/feature/Home/` is capitalised**; every other feature is lower_snake. Imports of it are
  case-sensitive on a Linux CI runner.
- **`lib/feature/splesh/`** is the splash feature — spelled that way in the tree.

Nested sub-features exist and are the stated `ARCH-2` exception:
`lib/feature/location/{add_new_address,location_selection}/`.

Source: `find lib -type d`, `lib/main.dart`.

## Flutter/Dart Version

**VERIFIED (partial)** — `pubspec.yaml`: `environment: sdk: ^3.10.0`.

**UNKNOWN - needs verification** — the Flutter SDK version itself is pinned **nowhere**: no `.fvmrc`,
no `fvm_config.json`, no CI (`PROD-2`). Two machines can build this repo on different Flutter
versions with nothing to detect it.

## State Management

**VERIFIED** — `flutter_bloc: ^9.1.1`, `equatable: ^2.0.7`. Cubit only, one state class per cubit.

`lib/core/base/base_cubit.dart` — `BaseCubit<S extends BaseState>` already covers most of `STATE-*`.
Use it; do not re-implement any of it (§2.1):

| Member | What it gives you | Rule |
|---|---|---|
| `safeEmit(S)` | `isClosed`-guarded emit — **the only way this app emits** | `STATE-1`, `STATE-2` |
| `safeEmitIfCurrent(int, S)` | emits only if this is still the request the user wants | `STATE-6` |
| `nextSequence()` / `isCurrent(int)` | monotonic request id, so a slow first response cannot overwrite a fast second | `STATE-6` |
| `cancelToken` / `cancelInFlight([reason])` | one token per cubit, cancelled in `close()` and on supersede | `NET-3` |
| `startLoading()` | `loading` + `clearFailure: true` | `STATE-3` |
| `startRefreshing({silent})` | `refreshing`, content stays; `silent: true` **is** `STATE-3`'s stated exception | `STATE-3` |
| `emitSuccess()` / `emitEmpty()` | success vs. legitimately-empty, kept distinct | `A11Y-3` |
| `emitFailure(Failure)` | drops `CancelledFailure` silently — the user caused it | `NET-3` |

`lib/core/base/base_state.dart` — `BaseState extends Equatable` with `ViewStatus`:
`initial · loading · refreshing · success · empty · failure`. One closed enum, not combinable
booleans (`STATE-5`). `copyWith` takes an explicit `clearFailure` flag because
`copyWith(failure: null)` cannot express "remove it". `Equatable` here is load-bearing, not
decoration — `BlocSelector` over a composite without a correct `==` rebuilds on every emit
(`PERF-2`).

`refreshing` is a separate value from `loading` on purpose: a screen that keeps its list visible
while refreshing cannot express that with `Loading`/`Loaded` classes.

## Dependency Injection

**VERIFIED** — `get_it: ^8.2.0`, one file: `lib/core/services/di/injection.dart`,
`configureDependencies()` awaited in `main()`.

Registered — **core only**, all `registerLazySingleton`: `Dio`, `Connectivity`,
`FlutterSecureStorage`, `SecureStorage`, `SessionExpiredHandler`, `TokenRefresher`, `NetworkInfo`,
`DioClient`.

**Cubits and repositories are not in GetIt at all.** `grep -rn "getIt<" lib/feature` → `0`. Cubits are
constructed per screen at 21 `BlocProvider(create: (_) => XCubit())` sites, which delivers the
factory-per-screen lifetime `ARCH-1` protects (no cubit outlives its screen) through a different
mechanism than the one `ARCH-1` names.

**Follow this existing pattern** (precedence 3, §0.3): a new cubit goes in its screen's
`BlocProvider(create:)`, not into GetIt. Do not fork a second wiring style into the same codebase.
Recorded as a divergence in the register, not as a defect to drive-by fix (§0.6).

Source: `lib/core/services/di/injection.dart`, `grep -rn "BlocProvider" lib`.

## Networking

**VERIFIED** — `dio: ^5.9.0`, `connectivity_plus: ^7.0.0`. One entry point:
`lib/core/network/dio_client.dart`. Nothing above the repo layer constructs a `Dio` or imports `dio`.

Timeouts — three separate values, `NET-1` satisfied:

```
connectTimeout 10s · receiveTimeout 30s · sendTimeout 30s
DioClient.uploadOptions() → send 5min, receive 2min   (per-request override for multipart)
```

`validateStatus = (s) => s != null && s < 600` — non-2xx reaches the interceptors on purpose so an
ABP error envelope inside a 4xx/5xx can still be read. The status guard lives in `ErrorMapper`, which
rejects a bodiless response first (`SEC-7`).

Every method takes `cancelToken`. `post`/`patch` default `idempotent: false`; `put`/`delete` default
`true`; `upload` forces `false`. The flag is written into `options.extra` and read by
`RetryInterceptor` — `NET-5`'s "write the answer at the call site", already mechanised.

Interceptor classes that exist (`lib/core/network/interceptors/`):

- `AuthInterceptor` — attaches `Authorization: Bearer <token>`; on 401 does exactly one
  refresh-and-retry, then ends the session. **403 is deliberately not handled here** (`NET-6`).
- `TokenRefresher` — single-flight via `Future<bool>? _inFlight` (`NET-4`). `refreshCall` is injected.
- `RetryInterceptor` — retries `502/503/504`, connection error, connect/receive timeout; **never** a
  4xx, never a request not marked idempotent, never `sendTimeout` (bytes may already have landed).
  Backoff `1s → 2s → 4s`, `maxAttempts: 3`, re-checks `cancelToken` after the backoff. `500` excluded
  on purpose (`NET-2`).
- `LoggingInterceptor` — redacts `authorization`/`cookie`/`set-cookie`/`x-api-key` headers and the
  `password`/`otp`/`token`/`pin` family of body fields, walks nested maps and lists, summarises
  `FormData`, truncates at 1000 chars (`SEC-2`).

> 🔴 **None of these four is attached to any `Dio` instance.** `grep -rn "interceptors" lib` returns
> two imports and one comment — there is no `.interceptors.add(...)` anywhere, and `injection.dart`
> registers a bare `Dio.new`. Consequence: no `Authorization` header is ever sent, no retry ever
> happens, no redacted logging ever runs. Register: `NET-WIRING-1`.

Error path: `lib/core/base/base_repository.dart` → `safeCall<T>({request, parse, tag})`, the single
place a call becomes `Either<Failure, T>`. The guard order **is** the method and must not be
reordered: **connectivity → body present → status → parse.** `parse` is never called with `{}` as a
stand-in for a missing body (§4.1).

`lib/core/network/error_mapper.dart` — `fromDio` / `hasBody` / `extractMessage` /
`extractFieldErrors` / `Retry-After` (delta-seconds form only; the HTTP-date form is ignored because
it needs a trusted clock). `hasBody` treats `null`, `''` and whitespace-only as bodiless, and
`{}`/`[]` as present (`SEC-7`).

## Backend

**BLOCKED — nothing about this backend is verified, and nothing can be until a base URL exists.**

- `lib/core/network/endpoints.dart` is the entire endpoint surface:
  `static String get baseUrl => ""`. An empty string, no `--dart-define`, and no other endpoint
  constant in the repository.
- Every feature repository file is an empty stub (0–2 bytes): `wallet_repo.dart` `0B`,
  `complaints_support_repo.dart` `1B`, `home_repo.dart` `2B`, and seven more.
- Screens run on hard-coded sample data (e.g. `ActiveOrder.sample` in
  `lib/feature/Home/presentation/view_model/home_cubit.dart`).

So **no endpoint has been called, no response has been observed, and the ABP question is open.**
Whether this backend wraps responses in the ABP envelope or serves raw `[DontWrapResult]` JSON is
`UNKNOWN`, per endpoint (§5). `ErrorMapper.extractMessage` already reads the ABP
`{ error: { message } }` shape *and* four flat keys, so it is prepared for either — that preparation
is not evidence about the server.

**Before writing any DTO, model, mapper, repository method, or endpoint constant: run
`api-investigator.md`.** Its first findings will be `BLOCKED` until someone supplies the base URL and
Swagger location. Record them; do not guess past them (§0.4).

Blocker owner: backend team. What unblocks it: a reachable base URL plus a live Swagger/OpenAPI URL.

## Authentication

**VERIFIED (client side)** — bearer token, `Authorization: Bearer <token>`, attached by
`AuthInterceptor` — which is not attached to `Dio` (see Networking).

Storage: `lib/core/local_storage/secure_storage.dart` wrapping `flutter_secure_storage: ^9.2.4` with
`AndroidOptions(encryptedSharedPreferences: true)` and
`IOSOptions(accessibility: KeychainAccessibility.first_unlock)`. Keys `access_token` /
`refresh_token`. API: `accessToken`, `refreshToken`, `saveTokens`, `hasSession`, `clearSession`.

`SEC-1` verified clean: `lib/core/cache/shared_pref_keys.dart` holds locale, onboarding flag,
`is_guest`, and cached display-only profile fields — **no token**, and the file says so itself.
`is_guest` defaults to `true` when absent: no stored session means no session, and the safe default
grants nothing.

Session expiry: `lib/core/network/session_expired_handler.dart` clears tokens and broadcasts on
`onExpired`, guarded so ten simultaneous 401s fire it once. It deliberately does **not** navigate
(`core/` must not import a feature, `ARCH-6`); the app shell is meant to listen and route to login.

**UNKNOWN - needs verification** — the refresh endpoint. `TokenRefresher.refreshCall` is `null`
(never passed in `injection.dart`), so `refresh()` logs `no refreshCall wired`, returns `false`, and
every 401 ends the session. Conservative and correct as a default, but it means `NET-6`'s
one-refresh-one-retry path is entirely unexercised. Register: `AUTH-1`.

401 vs 403: verified correct. `ErrorCode.isSessionOver` is `unauthorized` only; `403` maps to
`ForbiddenFailure` and never signs the user out (`NET-6`).

## Localization

**VERIFIED** — `easy_localization: ^3.0.8`, initialised in `lib/main.dart`:

```
supportedLocales: [Locale('ar'), Locale('en')]      fallbackLocale: ar
path: 'assets/translations'                          useOnlyLangCode: true
startLocale: LanguageCubit.storedLanguage.locale     (persisted in SharedPref key 'locale')
```

Translation files: `assets/translations/ar.json`, `assets/translations/en.json`.

User-facing strings route through `lib/core/utils/constants/app_strings.dart` (453 lines) with
`.tr()` (`STYLE-1`). That file's size is `MAINT-1`'s stated exception for a constant registry — do
not split it.

## RTL

**VERIFIED** — Arabic is the default locale, so RTL is the default rendering, not a mode (`A11Y-5`).

Directional-inset usage is **mixed and unaudited**: `EdgeInsetsDirectional` ×7,
`AlignmentDirectional` ×5, plain `EdgeInsets.only` ×6. Zero hand-rolled `Directionality`, which is
the part `A11Y-5` cares most about. Whether each of those six `EdgeInsets.only` sites is symmetric
(fine) or start/end-biased (a bug in Arabic) has **not** been checked per site. Register: `A11Y-5`.

## Design System

**VERIFIED** — measured from `figma.json` and centralised in `lib/core/utils/constants/`:

| Constant file | Contents | Rule |
|---|---|---|
| `app_colors.dart` | every colour. **105 `Color(0xFF…)` literals, all inside this file, zero at any call site** | `STYLE-2` ✅ |
| `styles.dart` | `Styles.*` typography. Family **Cairo**, static faces 400/500/600/700, `_lineHeight = 1.45`. No `light()` — Cairo ships no w300, and asking for one would silently render as regular | `STYLE-3` |
| `app_dimens.dart` | spacing/radii/heights as **raw** 375×812 values; `.w`/`.h`/`.r` applied at the use site; `contentWidth` derived by equation | `STYLE-6`, `STYLE-11` |
| `app_images.dart` | raster paths. Rule stated in-file: a constant is added in the **same commit** as the file, never before | `STYLE-4` |
| `app_strings.dart` | all user-facing text | `STYLE-1` |

ScreenUtil: `designSize: Size(375, 812)` in `lib/main.dart`. Text scale is clamped to **1.0–1.6** in
`MaterialApp.builder` via `MediaQuery.withClampedTextScaling`, so `A11Y-1`'s 200% test is effectively
a **160%** test in this app. Test at 160% — and know that a fixed `height` around text still clips
there.

Shared widgets under `lib/core/widgets/`: `AppButton`, `AppTextField`, `AppPhoneField`,
`AppBackButton`, `AppStatusBadge`, `AppShimmer`, `OrderQrSheet`, plus two that carry rules:

- `states/app_state_view.dart` — `AppStateView`, the `loading · empty · error+retry · content`
  renderer (`A11Y-3`). Content builds for `success` **and** `refreshing`, so pull-to-refresh keeps
  what is on screen. Use it for every data screen.
- `toast/toast.dart` — `AppToast.success/error/info`, called **from the cubit only**, never a
  `SnackBar`, never from a widget (`STYLE-8`).

**Missing:** there is no shared remote-image widget. `cached_network_image: ^3.4.1` is declared and
has **zero call sites**, so `STYLE-7`'s `errorWidget` and `PERF-4`'s `memCacheWidth` have nowhere to
live yet. Write that widget once, in `core/widgets/`, before the first remote image ships.
Register: `STYLE-7`.

Logger: `lib/core/utils/app_logger.dart` — `AppLogger.d/i/w/e` plus `AppLogger.redact()`. Every
method is `kDebugMode`-guarded, i.e. **compiles out in release** — which is exactly why it is not a
substitute for crash reporting (`PROD-1`). `print` ×0; one `debugPrint` remains.

## Figma

**VERIFIED (as a file)** — `figma.json` at the repository root: a raw Figma REST document dump
(`{"document":{"id":"0:0",…}}`). It is the source `styles.dart` and `app_dimens.dart` state they were
measured from.

**UNKNOWN - needs verification** — the Figma file/board URL, which screens it covers, and whether it
still matches the current designs. `figma.json` is a snapshot with no date recorded anywhere.

## Features

**VERIFIED** — 21 directories under `lib/feature/`:

```
Home · auth · complaints_support · create_request · language · layout · location · my_account
my_requests · notifications · onboarding · order_details · order_tracking · otp · payment
prices · rating · splesh · wallet · welcome_screen
```

`location/` is a parent holding two sub-features (`add_new_address`, `location_selection`) that share
the parent tree — the stated `ARCH-2` exception.

**~35 cross-feature imports exist** and are `ARCH-6` violations, not facts to normalise. Highest
counts: `layout/` ×5, `order_details/` ×4, `create_request/` ×4, `order_tracking/` ×3,
`location/` ×3. `HomeCubit` alone imports six other features' views. Register: `ARCH-6`.

## Environment Configuration

**VERIFIED — zero usable environments.** `Endpoints.baseUrl` returns `""`; no `--dart-define` is read
anywhere in `lib/`; no flavours, no scheme split. The comment in `endpoints.dart` says "Injected at
build time. Never a literal" — the injection was never wired. Register: `PROD-3`.

## Build Configuration

**VERIFIED:**

- `applicationId` = `namespace` = `com.nahr.laundo.laundo` (`android/app/build.gradle.kts`); iOS
  `PRODUCT_BUNDLE_IDENTIFIER` = `com.nahr.laundo.laundo`. Not `com.example.*`, so `PROD-4`'s first
  clause is satisfied — but the duplicated `laundo.laundo` segment should be a deliberate decision
  **before** Google/Apple OAuth clients bind to it, because that binding is permanent.
- 🔴 **`INTERNET` is only in `android/app/src/debug/AndroidManifest.xml`.** The main manifest
  (`android/app/src/main/AndroidManifest.xml`) declares no `uses-permission` at all. This is
  `PROD-4`'s named failure verbatim: release builds get no network. Register: `PROD-4`.
- Deep links: the main manifest has exactly one `intent-filter` — `MAIN`/`LAUNCHER`. No custom
  scheme, no App Links, so `PROD-5` has no surface to validate **yet**; it applies the moment one is
  added.
- No CI: `.github/` does not exist. Register: `PROD-2`.
- **UNKNOWN - needs verification** — the signing config, and whether any release build has used
  `--obfuscate --split-debug-info` (nothing in the repository records it).

## Known Backend Behavior

**Nothing verified.** No endpoint has been called from this repository (see Backend). This section
stays empty until `api-investigator.md` returns a `VERIFIED` fact with its date and its raw capture.
An `ASSUMPTION` is not promoted into this section by being written here (§0.4).

## Known Issues

Real, and verified by reading the code. Each is also a register entry — recorded once there, linked
here by ID:

1. **Interceptors written but never attached** — `NET-WIRING-1`. No auth header, no retry, no
   redacted logging.
2. **`Endpoints.baseUrl == ""`** — `PROD-3`. No request can succeed.
3. **`TokenRefresher.refreshCall == null`** — `AUTH-1`. Every 401 ends the session.
4. **`INTERNET` missing from the main manifest** — `PROD-4`. No network in a release build.
5. **Feature repositories are empty stubs; cubits serve sample data** — `BACKEND-1`. Not a defect in
   itself (the API is blocked), but every screen's data path is unimplemented.
6. **No crash reporting** — `PROD-1`. `AppLogger` compiles out in release, so production failures are
   currently invisible.

## Project-Specific Exceptions

Two, each with a stated architectural reason (§0.7):

**1 — Cubits live in `BlocProvider(create:)`, not GetIt.**
- *Rule set aside:* `ARCH-1`'s "cubits `registerFactory`".
- *Why it does not apply:* `ARCH-1` exists to stop a cubit outliving its screen. A cubit constructed
  in its screen's `BlocProvider` cannot outlive it — the protection is achieved by a different
  mechanism.
- *What replaces the protection:* the widget tree's own lifetime, plus `BaseCubit.close()` cancelling
  its `CancelToken`.
- *Recorded:* here, and as a divergence in `register.md`.

**2 — `///` doc comments on shared/core APIs are the house style.**
- *Why this needs stating:* the house rule in feature code is **no comments — logic lives in the
  cubit**, while `lib/core/` is visibly the opposite. Both are intentional.
- *Why it is not a `MAINT-3` violation:* every `///` block in `lib/core/` states a **why** or a trap,
  never a what — which is what `MAINT-3` asks for. They are the reason the guard order in `safeCall`
  will survive the next edit.
- *How the conflict resolves:* in feature code, prefer zero comments and put the logic in the cubit.
  In `lib/core/`, a `///` on a shared member explaining *why* is expected. Where `MAINT-6` (`late`
  needs a justification) or §0.7 (record the exception at the point of deviation) asks for a comment,
  **a `///` doc line on the member is the accepted form** — not an inline `//`.
- *Recorded:* here.

## Important Existing Patterns

Reuse these; do not re-invent them (§2.1, `MAINT-5`):

| Concern | Use this | Rule |
|---|---|---|
| Network call → `Either<Failure, T>` | `BaseRepository.safeCall({request, parse, tag})` | `SEC-5`, `SEC-7` |
| Guarded emit | `BaseCubit.safeEmit` / `safeEmitIfCurrent` | `STATE-1`, `STATE-2` |
| Stale-result guard | `nextSequence()` + `isCurrent()` | `STATE-6` |
| Cancellation | `BaseCubit.cancelToken` + `cancelInFlight()` | `NET-3` |
| Single-flight | `TokenRefresher._inFlight` — the named pattern to copy | `NET-4` |
| Idempotency declaration | `DioClient`'s `idempotent:` flag → `options.extra` | `NET-5` |
| Four screen states | `AppStateView` | `A11Y-3` |
| Toasts | `AppToast`, from the cubit | `STYLE-8` |
| Failures | `sealed class Failure` + `ErrorCode` enum; branch on `code`, never on message text | `SEC-5` |
| Empty-body check | `ErrorMapper.hasBody` | `SEC-7` |
| Secret-safe logging | `AppLogger` + `AppLogger.redact` | `SEC-2`, `STYLE-10` |
| Retry policy | `RetryInterceptor` — do not add a second retry path | `NET-2` |

**Does not exist yet** — build it once, in `core/`, when first needed, and record it here: a
paginated-list base (`ARCH-4`), a shared remote-image widget (`STYLE-7`, `PERF-4`), an `AppIcon`
registry (`STYLE-4` currently covers images only), and any DTO/Model/Mapper triple (`ARCH-7` — none
exists, so the first one sets the pattern).

## Important Files

Verified paths. Read contents, not names (§2.2).

| Concern | Path in this repository |
|---|---|
| Repository base class | `lib/core/base/base_repository.dart` |
| Cubit base class | `lib/core/base/base_cubit.dart` |
| State base class | `lib/core/base/base_state.dart` (`ViewStatus` lives here) |
| HTTP client | `lib/core/network/dio_client.dart` |
| Interceptors (401 / retry / logging) | `lib/core/network/interceptors/{auth,retry,logging}_interceptor.dart` — **none attached** |
| Token refresher | `lib/core/network/interceptors/auth_interceptor.dart` (`TokenRefresher`, same file) |
| Session expiry | `lib/core/network/session_expired_handler.dart` |
| Failure hierarchy / error codes | `lib/core/failure/failure.dart` (sealed), `lib/core/failure/error_code.dart` |
| Error mapping / envelope reading | `lib/core/network/error_mapper.dart` |
| Response envelope class | none — `ErrorMapper` does the envelope reading |
| Endpoint constants | `lib/core/network/endpoints.dart` (`baseUrl` only, empty) |
| Dependency injection | `lib/core/services/di/injection.dart` |
| Secure storage | `lib/core/local_storage/secure_storage.dart` |
| Prefs / cache | `lib/core/cache/shared_preferences_manager.dart`, `shared_pref_keys.dart` |
| Connectivity | `lib/core/network/network_info.dart` |
| Logger | `lib/core/utils/app_logger.dart` |
| Remote image widget | **does not exist** (`cached_network_image` declared, 0 call sites) |
| Paginated cubit base | **does not exist** |
| Four-state renderer | `lib/core/widgets/states/app_state_view.dart` |
| Toasts | `lib/core/widgets/toast/toast.dart` |
| Localization init | `lib/main.dart` + `assets/translations/{ar,en}.json` |
| Theme / shared constants | `lib/core/utils/constants/{app_colors,styles,app_dimens,app_images,app_strings}.dart` |
| Global navigator / context | `lib/core/utils/constants/app_context.dart`, `lib/core/utils/nav.dart` |
| Router / deep links | no router; `Navigator.push` via `nav.dart`. Deep links: none configured |
| `analysis_options.yaml` | repository root — matches §7's baseline, all nine rules present |
| CI configuration | **does not exist** |
| Superseded policy (v7) | `flutter_full_agent_v7.md` at the repository root — **historical**; see the citation legend below |

---

## Citation legend — v7 numbers in code comments

`lib/` carries **67 citations in the previous policy's numbering** (`Tier x.y` ×23, `§n.m` ×44),
written when `flutter_full_agent_v7.md` was the live document. They are not wrong, they are *stale*:
a `§8.6` in a code comment resolves against nothing in this folder.

**Do not mass-rewrite them** — that is unrelated cleanup (§0.6). Translate on read with this table,
and update a citation only inside a comment you are already editing for another reason.

Mapping verified against `flutter_full_agent_v7.md` §13 and §§3–11 on 2026-08-25.

| v7 | Now | | v7 | Now |
|---|---|---|---|---|
| `Tier 1.1` | `SEC-1` | | `§3.1` | `§4.1` |
| `Tier 1.2` | `SEC-2` | | `§3.2` | `§4.2` |
| `Tier 1.3` | `SEC-3` | | `§3.3` | `§4.3` |
| `Tier 1.4` | `SEC-4` | | `§3.4` | `§4.6` |
| `Tier 1.5` | `SEC-5` | | `§3.5` | `§4.4` |
| `Tier 1.6` | `SEC-6` | | `§3.6` | `§4.5` |
| `Tier 1.7` | `SEC-7` | | `§4` (tooling) | `§7` |
| `Tier 1.8` | `SEC-8` | | `§5.1` | `SEC-9` |
| `Tier 1.9` | `SEC-9` | | `§5.2` | `LIFE-2` |
| `Tier 2.10` | `STATE-1` | | `§5.3` | `LIFE-3` |
| `Tier 2.11` | `STATE-2` | | `§5.4` | `LIFE-4` |
| `Tier 2.12` | `STATE-3` | | `§5.5` | `LIFE-5` |
| `Tier 2.13` | `STATE-4` | | `§6.1`…`§6.6` | `PERF-1`…`PERF-6` |
| `Tier 2.14` | `ARCH-1` | | `§7.1`…`§7.5` | `TEST-1`…`TEST-5` |
| `Tier 2.15` | `ARCH-2` | | `§8.1`…`§8.7` | `NET-1`…`NET-7` |
| `Tier 2.16` | `ARCH-3` | | `§9.1` | `STATE-5` |
| `Tier 2.17` | `ARCH-4` | | `§9.2` | `STATE-6` |
| `Tier 2.18` | `ARCH-5` | | `§9.3` | `STATE-7` |
| `Tier 2.19` | `NET-3` | | `§9.4` | `ARCH-2` |
| `Tier 2.20` | `STATE-7` | | `§10.1`…`§10.5` | `A11Y-1`…`A11Y-5` |
| `Tier 2.21` | `ARCH-6` | | `§11.1`…`§11.7` | `PROD-1`…`PROD-7` |
| `Tier 2.22` | `ARCH-7` | | `§12` | `§9` (register) |
| `Tier 3.23` | `STYLE-1` | | `§13` | `§6.x` rule tables |
| `Tier 3.24` | `STYLE-2` | | `§14` | `§11` |
| `Tier 3.25` | `STYLE-3` | | `§15` | `§12` |
| `Tier 3.26` | `STYLE-4` | | `§16` | `§5` |
| `Tier 3.27` | `STYLE-5` | | `§17` | `§10` |
| `Tier 3.28` | `STYLE-6` | | `§18` | `§13` |
| `Tier 3.29` | `STYLE-7` | | | |
| `Tier 3.30` | `STYLE-8` | | | |
| `Tier 3.31` | `PERF-2` | | | |
| `Tier 3.32` | `STYLE-9` | | | |
| `Tier 3.33` | `A11Y-5` | | | |
| `Tier 3.34` | `STYLE-10` | | | |
| `Tier 3.35` | `STYLE-11` | | | |
| `Tier 4.36`…`4.41` | `MAINT-1`…`MAINT-6` | | | |

**One bad citation in the code**, wrong in v7's own numbering, so it translates to nothing:
`analysis_options.yaml` cites `§8.6` for `unawaited_futures`, but v7 §8.6 is the status-code rule.
The correct home is §7's automation bucket (`tooling-lint.md`); no rule ID covers that lint. Left
as-is deliberately — the file is outside this folder and outside any current task's scope (§0.6).

**One dangling reference:** `Tier 3.29` names `PostMediaImage`, a widget from a previous project that
does not exist here. `STYLE-7` is the rule; the widget still has to be written (see Design System).
