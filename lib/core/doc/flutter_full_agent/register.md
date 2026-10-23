# Register — per-repository gap tracker (POLICY + PROJECT STATE)

**Canonical home for:** §9 (register statuses and table rules)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Three kinds of content, kept apart on purpose:**

1. **Policy** — §9's statuses and table rules below. Applies to every repository on this stack.
2. **Historical example** — the sample table at the end of §9 is explicitly labelled by the
   original document as *from a past project (illustrative)*. It is a shape to copy, never a set
   of facts to inherit. Treat every row in it as belonging to another repository.
3. **Project state** — the *Live register* section at the bottom of this file, which is the only
   place entries about **this** repository may be written.

A register entry is a rule about honesty (§0.1), not a rule about code: it is never silently
fixed as a side effect of an unrelated task (§0.6) and never closed without evidence.

---

# 9. Register — per-repository gap tracker

`§6` states what this policy requires everywhere on this stack. This section tracks where a
*specific* repository currently falls short. It is populated from your `§3` baseline for that
repository — never copied from another project's clean (or dirty) table.

**Statuses:**

- `OPEN` — known gap, not yet worked.
- `IN_PROGRESS` — actively being closed.
- `VERIFIED` — closed, with evidence attached (a commit, a passing test, a re-run measurement).
- `WONT_APPLY_WITH_REASON` — deliberately not applicable to this repository; the reason is
  written down, not implied.
- `BLOCKED` — cannot proceed without an external dependency (backend change, design decision);
  name the blocker.

**Rules for this table:**
- An entry moves to `VERIFIED` only with evidence for *this* repository — not because it got old,
  and not by inference from another project's state.
- An entry is never deleted while `OPEN`/`IN_PROGRESS`/`BLOCKED`. A resolved entry is marked
  `VERIFIED`, kept, and dated.
- `WONT_APPLY_WITH_REASON` still requires the reason in the table — an empty reason is treated as
  `OPEN`.

Example shape, from a past project (illustrative — build your own per repository):

| Rule | Gap | Severity | Status |
|---|---|---|---|
| `PROD-1` | No crash reporting at all | 🔴 | OPEN |
| `PROD-2` | No CI | 🔴 | OPEN |
| `PROD-3` | Base URL hard-coded, single environment | 🔴 | OPEN |
| `PROD-5` | Intent-filters present, no deep-link validation | 🔴 | OPEN |
| `§7` | Zero custom lint rules enabled | 🔴 | OPEN |
| `NET-1` | One 30s timeout for connect, receive and upload | 🔴 | IN_PROGRESS |
| `NET-3` | Zero `CancelToken` call sites despite client support | 🔴 | OPEN |
| `NET-2` | No retry interceptor | 🟠 | OPEN |
| `TEST-2` | Most recent fixes have no regression test | 🔴 | OPEN |
| `TEST-5` | No golden tests | 🟡 | OPEN |
| `A11Y-1` | `textScaler` never considered; fixed heights around text | 🟠 | OPEN |
| `A11Y-4` | Almost no `Semantics` usage | 🟡 | OPEN |
| `PERF-4` | No image decode limits | 🟠 | VERIFIED (2026-08-20, `memCacheWidth` added to shared image widget) |
| `LIFE-4` | Lifecycle handled for one feature only | 🟠 | IN_PROGRESS |
| `LIFE-5` | No `PopScope` on composing screens | 🟡 | OPEN |

---

# Live register — this repository

> 🔴 **The register below is Laundo's, not yummy_diet's.** It arrived with the copied `lib/core/`.
> Every count, every path, every status in it was measured against a different repository on
> 2026-08-25 and none of it has been re-verified here. See the banner at the top of `PROJECT.md`.
> **Do not close, reuse, or cite an entry below as a fact about yummy_diet** (§0.5). The
> yummy_diet baseline is the section immediately following; it is the only measured state for this
> repository.

## Baseline measurements — yummy_diet, 2026-08-30

Run against **this** repository. Scoped to what the design-system retheme touched plus the §3 rows
that were cheap to re-run; rows §3 lists that are not here were **not** measured, and their absence
is not a clean result (§0.5).

| Measurement | Command | Result | Feeds |
|---|---|---|---|
| Features | `ls lib/feature` | **2** — `choose_language`, `splesh` | §2 |
| Dart files under `lib/` | `find lib -name "*.dart" -not -path "*/doc/*"` | 40 | — |
| Inline colours | `grep -rn "Color(0x" lib --include=*.dart \| grep -v app_colors` | **0** (all inside `app_colors.dart`) | `STYLE-2` ✅ |
| `print` / `debugPrint` | `grep -rn "print(\|debugPrint" lib --include=*.dart` | 1 | `STYLE-10` |
| Interceptors attached to `Dio` | `grep -rn "interceptors.add" lib --include=*.dart` | **0** | `NET-2`, `NET-6`, `SEC-2` |
| `getIt<` in features | `grep -rn "getIt<" lib/feature --include=*.dart` | 0 | `ARCH-1` |
| Tests | `find test -name "*_test.dart"` | **1** (the default `widget_test.dart`) | `TEST-2`, `TEST-4` |
| CI | `ls .github/workflows` | absent | `PROD-2` |
| Crash reporting | `grep -c "crashlytics\|sentry" pubspec.yaml` | 0 | `PROD-1` |
| `applicationId` / namespace | `android/app/build.gradle.kts` | `applicationId` is `com.nahr.yummy_diet`; `namespace` and the `MainActivity` package stay `com.nahr.yummy_diet.yummy_diet` | `PROD-4` |
| `INTERNET` in main manifest | `grep -c INTERNET android/app/src/main/AndroidManifest.xml` | **0** — CLOSED since `3de4f3b`, which added it | `PROD-4` |
| Environments | read `endpoints.dart` | `baseUrl => ""` | `PROD-3` |
| Files > 200 lines | `find lib -name "*.dart"` + `wc -l` | 3 (`app_strings.dart` is the `MAINT-1` registry exception and is not counted) | `MAINT-1` |
| Design frame | `lib/core/doc/figma/index.json` | 390×844, 57 screens on page *Ready to View* | `STYLE-6` |
| Font family | `lib/core/doc/figma/design_tokens.json` | Noto Sans Arabic, 4546 of 4830 text nodes; 5 static faces bundled | `STYLE-3` |
| `flutter analyze` | `flutter analyze` | 0 errors, 3 infos | §10 |
| `flutter build bundle` | `flutter build bundle` | exit 0; all 5 font faces and both translation files in `FontManifest.json` / `AssetManifest` | §10 |

## Open gaps — yummy_diet, 2026-08-30

| Rule | Gap | Severity | Status |
|---|---|---|---|
| `SETUP-1` | `lib/main.dart` is the **default Flutter counter demo**. `ScreenUtilInit(designSize: Size(390, 844))`, `EasyLocalization`, the GetIt `configureDependencies()` call and the app theme are all absent, so nothing in `lib/core/` is reachable at runtime. Every `.sp`/`.w`/`.r` in the shared widgets and every `.tr()` will throw or fall back until this is wired | 🔴 | OPEN |
| `DOC-1` | `PROJECT.md` and the Laundo section of this file describe a different repository. Banners added 2026-08-30; the bodies are not rewritten | 🟠 | OPEN |
| `STYLE-4` | `AppImages` and `AppIcons` are empty. The design's 138 image fills exist only as expiring Figma URLs in `design_tokens.json`, and its icons are `VECTOR` nodes with no path data — both need exporting from Figma before a constant can point at one | 🟠 | OPEN |
| `STYLE-1` | `en.json` is a **translation by the agent that generated it**, not reviewed copy. `ar.json` is transcribed verbatim from the design and is the trustworthy side | 🟡 | OPEN |
| `PROD-3` | `Endpoints.baseUrl => ""`, no `--dart-define`, no flavours — carried over unchanged from Laundo and equally true here | 🔴 | OPEN |
| `PROD-4` | No `uses-permission` in `android/app/src/main/AndroidManifest.xml`. Release builds get no network | 🔴 | OPEN |
| `PROD-1` | No crash reporter; `AppLogger` is `kDebugMode`-guarded | 🔴 | OPEN |
| `PROD-2` | No CI | 🔴 | OPEN |
| `NET-2`/`NET-6`/`SEC-2` | All four interceptors exist and **none is attached** to a `Dio` instance (`interceptors.add` ×0) | 🔴 | OPEN |
| `TEST-4` | 1 test file — the generated `widget_test.dart`, which still tests the counter demo | 🟠 | OPEN |
| `STYLE-10` | One `debugPrint` outside `AppLogger` | 🟡 | OPEN |
| `A11Y-1` | No text-bearing screen has been tested at a raised font scale — there is no screen yet | 🟠 | OPEN |

## Auth wiring — yummy_diet, 2026-09-14

The first feature connected to the real API. Source of truth: `lib/core/doc/API_FLUTTER.md`
(extracted from the Laravel source) and `lib/core/doc/api.json`. The Postman collection that
preceded it is **wrong** on verbs, on the envelope, and on what `/auth/otp/verify` returns — do not
build from it.

### Closed

| Rule | Was | Evidence |
|---|---|---|
| `PROD-3` | `Endpoints.baseUrl => ""` | now defaults to the documented dev host and still throws on a `prod` build without `BASE_URL` |
| `BACKEND-1` (auth only) | every repository an empty stub | `AuthRepository` and `LocationsRepository` call live endpoints through `safeCall`; `flutter analyze` clean, `flutter build bundle` exit 0 |
| `ARCH-7` (auth only) | no DTO/Mapper layer anywhere | `user_dto.dart` / `auth_mapper.dart` / `auth_user.dart` and the locations triple establish the pattern for the remaining 32 features |

### Deliberate divergences

| Rule | Divergence | Status |
|---|---|---|
| `NET-6` | **No refresh-and-retry on 401.** The API issues Sanctum tokens that never expire and exposes no refresh endpoint (`API_FLUTTER.md` §1, §6.3), so the "refresh once, retry once" half of the rule has nothing to call. A 401 means the token was revoked — by logout, a password reset, or account deletion — and no retry can recover it. The protection the rule provides is kept: expiry fires exactly once through `SessionExpiredHandler`, which clears storage and announces it. `TokenRefresher` was deleted rather than left as a class that looks wired and is not | WONT_APPLY_WITH_REASON |
| "branch on the code, never the message" | `AuthRepository._classifyLoginFailure` matches on message text. `API_FLUTTER.md` Appendix B lists a set of business failures the server sends as `code: 400` with **no `reason`**, so text is the only discriminator it offers. The match happens once, in the repository, and everything above it branches on the stable `AuthReason.*` codes it synthesises | WONT_APPLY_WITH_REASON — revisit when the backend adds reasons |
| `NET-6` (401 detection point) | Expiry is detected in `onResponse`, not `onError`. Every response on this API is HTTP 200 with the real status in the body, so an `onError` handler would never run | WONT_APPLY_WITH_REASON — forced by the contract |

### Verified against the live server, 2026-09-14

Run on a real device against `https://yummydiet.nahrdev.net/api`. Not inferred — read off the
device log:

| Flow | Result |
|---|---|
| `POST /auth/login` with bad credentials | `{key: fail, msg: "Invalid phone number or password."}` → mapped, announced, no crash |
| `GET /locations/cities` | `{key: success, data:[{id, name:{en,ar}, country_id}]}` → the `{en,ar}` object exception confirmed |
| `GET /locations/districts?city_id=1` | success, district scoped to the city |
| `POST /auth/register` | `{key: success, msg: "Registered successfully, please verify your phone number."}`, no `data` |
| `POST /auth/otp/verify` (`purpose: register`) | `{key: success, msg: "Verified successfully."}`, **no token** — confirms the flow needs the follow-up login |
| `POST /auth/login` after verification | `{key: success, data:{token, user}}`, full `UserResource` incl. `calorie_profile_complete: false` and nested `city`/`district` |

### OTP login is not buildable — probed live 2026-09-15

The design has a `الدخول باستخدام رمز التحقق` button (`auth.loginWithOtp`, a translation key with
zero call sites). It cannot be built against this API. Three calls to
`https://yummydiet.nahrdev.net/api`, run with the user's go-ahead:

| Call | Response |
|---|---|
| `POST /auth/otp/send` `purpose=login` | `{"key":"success","data":{"debug_otp":null},"msg":"Verification code sent.","code":200}` |
| `POST /auth/otp/verify` `purpose=login` `otp=123456` | `{"key":"success","msg":"Verified successfully.","code":200}` |
| `POST /auth/otp/verify` `purpose=login,reset` | `{"key":"fail","msg":"The selected purpose is invalid.","code":422}` |

The second response is the answer: **no `data` key at all** — not `data: null`,
absent. `purpose: login` is accepted on the request and yields nothing on the
response, and `POST /auth/login` (phone + password) is the only route in all 90
that returns a `token`. A verified login OTP cannot be exchanged for a session.

Backend needs one of: `otp/verify` with `purpose: login` returning
`{token, user}`, or a route that trades the verification for one. Until then the
button stays unbuilt — a flow that ends on "Verified successfully" and no session
looks shipped and is not.

Second blocker, independent of the first: `debug_otp` came back **null**, so
`APP_DEBUG` is off on dev and the code is never returned to the client — and no
SMS gateway is wired. Today the only way to know the OTP is that the source
hardcodes `"123456"`. Registration survives this because it has a password;
an OTP-only sign-in would lock everyone out.

Incidental confirmations: every one of the three answered **HTTP 200**, the 422
included — §2's rule, live. And a success that omits `data` entirely is exactly
what `ApiEnvelope.hasData` and `requireMap()` were built for.

### Open gaps this raised

| Rule | Gap | Severity | Status |
|---|---|---|---|
| — | `AppStateView` screens will show a full error page **and** a toast once wired, because `BaseCubit.emitFailure` now announces every failure. `emitFailure(f, notify: false)` is the opt-out | 🟡 | RULE RECORDED — not reachable today: `emitFailure` has 5 call sites, all in auth, none of which use `AppStateView`, and the 49 screens that do have no repository and so no failure path. The rule is in `PROJECT-LOG.md` §9.1 for whoever wires each feature |
| `PROD-4` | `flutter_secure_storage` logs `KeyStore exception (code 7)` twice on first launch on the test device (Android 9). It recovers — the token saved and the session worked — but it is the keystore path for every token on the app | 🟡 | OPEN — watch, do not assume benign |
| `TEST-4` | `sign up` left the overflow matrix: it starts a lookup request as it builds, and the spinner cannot settle against the real `LocationsRepository` under `flutter_test`. Needs a stubbed repository registered in GetIt for that file | 🟠 | OPEN — the user owns tests |
| `BACKEND-2` | OTP length is **unresolved**. `API_FLUTTER.md` §6.7 documents length 5 while the server hardcodes `"123456"` (6 characters) and no SMS gateway is wired. The app stayed at 6 because that is the value the server actually sends; a real generator at length 5 breaks the screen | 🟠 | BLOCKED — needs the backend to confirm before release testing |
| `A11Y-*` | The sign-up city/district pickers are new UI and have not been checked at a raised text scale or in both locales — the test that would have caught it is the one that had to be removed above | 🟡 | OPEN |

### Session lifecycle closed — 2026-09-15

The auth wiring left three ends loose. Each was code that existed and was never
called, so nothing failed loudly; the device log of 2026-09-14 shows the first
one plainly — `POST /auth/login` went out carrying `Authorization: Bearer …b474`
from a session that had supposedly been signed out.

| Was | Now |
|---|---|
| `AccountCubit.logout()` flipped a flag and the view navigated away; `AuthRepository.logout()` was never called and the token stayed in secure storage | the cubit awaits the repository, which revokes the token server-side and clears storage either way; the view navigates from a `BlocListener` on `isSignedOut` |
| `SpleshCubit` branched on the stored locale only; `hasSession` and `me()` were dead, so a stored token sent the user through onboarding again | the splash reads the token beside its branding delay and lands on `UserTypeView` — where signing in lands — when one is present |
| `SessionExpiredHandler.onExpired` had zero subscribers: a revoked token cleared storage into a stream nobody read | `main` subscribes, announces `error.sessionExpired`, and clears the stack to `WelcomeView`. `core/` still does not import a feature — the composition root supplies the destination |

Supporting change: `SecureStorage._read` and `_delete` no longer throw. A
keystore failure (`KeyStore exception (code 7)` is in the device log) would now
travel up through the splash's session check and strand the launch on the logo;
an unreadable token and an absent one mean the same thing, so it is logged and
reported as "no session". `saveTokens` deliberately still throws — a write that
silently fails would report a login that cannot be resumed.

Verified: `flutter analyze` 7 info / 0 errors, `flutter build bundle` exit 0,
`overflow_matrix_test` 62/62. Not verified without a device: the expiry path
needs a revoked token to fire.

### Cleanup — 2026-09-15

| What | Why |
|---|---|
| `lib/core/network/api_error_codes.dart` deleted | 71 lines of another project's vocabulary — `AUTH_PASSWORD_MISMATCH`, `POST_BANNED_WORD`, `SUPPORT_TICKET_CLOSED`. Zero references anywhere in `lib` or `test`. This API signals business refusals with a flat snake_case `reason`, which `ApiEnvelope.reason` and `BusinessFailure` already carry. `abp_response.dart` went in the same sweep; this file was missed |
| `LocationsRepository` caches rows, not mapped cities | the cache held names already resolved against the locale at parse time, so switching language kept serving the old ones until restart |
| `configureDependencies()` added to two test `setUpAll`s | `activity_and_account_states_test` and `child_home_smoke_test` both build `AccountView`, which now resolves `AuthRepository` from GetIt for the logout call. Repairing a break this work caused, not authoring tests — the same two lines `overflow_matrix_test` already carries |

Suite after: **268 pass / 2 fail**, and the two are the pre-existing pair below.

### Pre-existing test failures, unrelated

`cart_and_order_summary_test.dart` ("cart removing every line falls to the empty state") and
`meal_details_transition_test.dart` ("the photo flies from the card to the details hero") fail on
`HEAD` (3de4f3b) as well — verified by running both in a clean worktree at that commit before any
of this work. The cart one asserts an empty state that §4 of `PROJECT-LOG.md` records as
deliberately removed.

## Deliberate composition — yummy_diet, 2026-08-30

Not divergences from a rule; §0.7 disclosures where a token is assembled rather than measured.

| Token | What was composed, and why |
|---|---|
| `AppColors.pendingSurface` | The `جاري التجهيز` pill in Figma is bare text with **no fill**. Aliased to `primaryTint` (`#1A006B32`, measured, 6 nodes) so the pending tone has the same shape as the other four in `AppStatusBadge` |
| `AppColors.shimmerBase` / `shimmerHighlight` | The design has no skeleton state. Aliased to `surfaceGrey` / `surfaceMuted` — two neutrals already in the palette — rather than introducing a hex the design does not contain |
| `Styles._lineHeight = 1.4` | The usage-weighted mean of the ratios the **designer set explicitly**. 24% of text nodes sit at 2.11, which is Figma *Auto* (the font's own metric), not a choice; including them would have given a misleading 1.6 |
| `AppDimens.minTapTarget = 44` | `A11Y-2`'s requirement, not a Figma measurement. The design's icon buttons are 20×20 artwork |

---

# Live register — Laundo (copied in, not re-verified)

**Project state.** This is the only place a gap for *this* repository is recorded.

**Baseline run:** 2026-08-25, against this repository, by reading files and running the §3
measurements below. Not seeded from §9's illustrative table, from `engineering-knowledge.md`, or from
any other project's register — §9 forbids that. Facts about what this repository *is* live in
`PROJECT.md`; what it is *missing* lives here.

## Baseline measurements — 2026-08-25

§3's table adapted to this repository's real paths. **The features directory is `lib/feature/`,
singular** — the generic `lib/features/` grep returns `0` here and reads as a clean result (§0.5).

| Measurement | Command | Result | Feeds |
|---|---|---|---|
| Bloc widgets | `grep -rn "BlocSelector<\|BlocBuilder<\|BlocConsumer<\|BlocListener<" lib --include=*.dart` | 33 / 17 / 2 / 2 | `PERF-2` |
| `buildWhen` + `listenWhen` | `grep -rn "buildWhen\|listenWhen" lib --include=*.dart` | 9 / 4 | `PERF-2` |
| Scroll containers | `grep -rn "SingleChildScrollView\|ListView.builder\|ListView(" lib --include=*.dart` | 11 / **0** / 9 | `PERF-3` |
| `CancelToken` outside the client | `grep -rn "CancelToken" lib --include=*.dart \| grep -v core/network` | 4 | `NET-3` |
| `compute` / `Isolate` | `grep -rn "compute(\|Isolate\." lib --include=*.dart` | 0 | `PERF-1` |
| Image decode tuning | `grep -rn "memCacheWidth\|imageCache" lib --include=*.dart` | 0 | `PERF-4` |
| `Semantics(` / `textScaler` | `grep -rn "Semantics(\|textScaler" lib --include=*.dart` | 17 / 4 | `A11Y-1`, `A11Y-4` |
| `PopScope` | `grep -rn "PopScope" lib --include=*.dart` | 2 | `LIFE-5` |
| `AppLifecycleState` | `grep -rn "AppLifecycleState" lib --include=*.dart` | 0 | `LIFE-4` |
| Cross-feature imports | `grep -rno "\.\./\.\./\.\./[a-zA-Z_]*/" lib/feature --include=*.dart` | ~35 (excl. `core/`) | `ARCH-6` |
| Inline colours | `grep -rn "Color(0xFF" lib --include=*.dart \| grep -v app_colors` | **0** (105 all inside `app_colors.dart`) | `STYLE-2` |
| `print` / `debugPrint` | `grep -rn "print(\|debugPrint" lib --include=*.dart` | 0 / 1 | `STYLE-10` |
| Directional insets | `grep -rn "EdgeInsetsDirectional\|AlignmentDirectional\|EdgeInsets.only" lib` | 7 / 5 / 6 | `A11Y-5` |
| Custom lint rules | read `analysis_options.yaml` | 9 rules, 3 promoted to `error` | §7 |
| Tests | `find test -name "*_test.dart"` / `find test -name "*cubit*"` | 16 / **0** | `TEST-4` |
| Files > 200 lines | `find lib -name "*.dart"` + `wc -l` | 20+, largest 480 | `MAINT-1` |
| Crash reporting | `grep -n "crashlytics\|sentry" pubspec.yaml` | 0 | `PROD-1` |
| CI | `ls .github/workflows` | absent | `PROD-2` |
| Environments | read `endpoints.dart` | `baseUrl => ""` | `PROD-3` |
| `applicationId` / bundle id | `android/app/build.gradle.kts`, iOS pbxproj | `com.nahr.laundo.laundo` (both) | `PROD-4` |
| `INTERNET` permission | grep both manifests | **debug manifest only** — since closed | `PROD-4` |
| `intent-filter` vs. link handling | grep main manifest | 1 (`MAIN`/`LAUNCHER`), no custom scheme | `PROD-5` |
| HTTP timeouts | read `dio_client.dart` | 10s / 30s / 30s + upload override | `NET-1` |
| Retry interceptor | `grep -rn "RetryInterceptor" lib` | class exists, **never attached** | `NET-2` |

## Open gaps

| Rule | Gap | Severity | Status |
|---|---|---|---|
| `PROD-3` | `Endpoints.baseUrl => ""`. No `--dart-define`, no flavours — zero reachable environments | 🔴 | OPEN |
| `PROD-4` | `INTERNET` only in `android/app/src/debug/AndroidManifest.xml`; main manifest has no `uses-permission`. Release builds get no network | 🔴 | CLOSED — added to the main manifest in `3de4f3b` |
| `PROD-1` | No crash reporter (`grep crashlytics\|sentry pubspec.yaml` → 0), and `AppLogger` is `kDebugMode`-guarded, so production failures are invisible | 🔴 | OPEN |
| `PROD-2` | No CI. "analyze is clean" is currently a habit, not a guarantee | 🔴 | OPEN |
| `NET-6` | `AuthInterceptor` exists but is **never attached** to `Dio` — no `Authorization` header is sent and the 401 refresh-and-retry path is dead code | 🟠 | OPEN |
| `NET-2` | `RetryInterceptor` exists but is **never attached** — no retry, no backoff, despite a correct implementation | 🟠 | OPEN |
| `NET-4` | `TokenRefresher`'s single-flight guard is correct, but `refreshCall` is `null` in `injection.dart`, so `refresh()` always returns `false` and every 401 ends the session | 🟠 | OPEN |
| `SEC-2` | `LoggingInterceptor` (the redacting one) is **never attached**. No leak today because nothing logs bodies — but the guard that would prevent one is not in place | 🔴 | OPEN |
| `ARCH-6` | ~35 cross-feature imports under `lib/feature/`; `HomeCubit` alone imports six other features' views | 🟠 | OPEN |
| `PERF-3` | `ListView.builder` ×0 against `SingleChildScrollView` ×11 and `ListView(` ×9. Correct while every list is mock data; wrong the moment one becomes server-driven | 🟠 | OPEN |
| `PERF-4` | `memCacheWidth` ×0 — and there is no shared remote-image widget for it to live in | 🟠 | OPEN |
| `STYLE-7` | No shared remote-image widget. `cached_network_image` is declared with **0 call sites**, so there is no `errorWidget` path | 🟡 | OPEN |
| `TEST-4` | 16 widget tests, **0 cubit tests**. No state sequence, `isClosed`, `clearError` or rollback is asserted anywhere | 🟠 | OPEN |
| `TEST-5` | No golden tests, on a codebase with 9 shared widgets in `core/widgets/` | 🟡 | OPEN |
| `A11Y-1` | Text scale is clamped to 1.6 in `main.dart`, and no text-bearing screen has been tested at that scale | 🟠 | OPEN |
| `A11Y-4` | `Semantics(` ×17 — present, but coverage of icon-only controls has not been audited per control | 🟡 | OPEN |
| `A11Y-5` | 6 plain `EdgeInsets.only` sites are unaudited for start/end bias in Arabic. Zero hand-rolled `Directionality`, which is the part the rule cares most about | 🟡 | OPEN |
| `LIFE-4` | `AppLifecycleState` ×0. Nothing live exists yet, but `order_tracking` is the feature that will need `paused`/`resumed` handling first | 🟠 | OPEN |
| `LIFE-5` | `PopScope` ×2. `create_request` carries unsaved input across multiple steps; per-screen coverage unaudited | 🟡 | OPEN |
| `MAINT-1` | 20+ files over ~200 lines (largest `payment_sections.dart`, 480). `app_strings.dart` at 453 is the stated constant-registry exception and is **not** counted | 🟡 | OPEN |
| `STYLE-10` | One `debugPrint` remains outside `AppLogger` | 🟡 | OPEN |
| `ARCH-4` | No paginated-list base exists. No paged list exists either, so nothing is violating it today — the entry exists so the first paged list builds the shared base instead of a private one | 🟠 | OPEN |

## Blocked

| Rule | Gap | Severity | Status |
|---|---|---|---|
| `BACKEND-1` | Every feature repository file is an empty stub (0–2 bytes) and every screen renders hard-coded sample data. No endpoint has ever been called from this repository | 🔴 | BLOCKED — needs a reachable base URL + live Swagger/OpenAPI. Owner: backend team |
| `ARCH-7` | No DTO/Model/Mapper triple exists anywhere, so the boundary the rule governs has not been established once | 🟠 | BLOCKED — by `BACKEND-1`. The first verified endpoint sets the pattern |
| `NET-5` | Idempotency is declarable at the call site (`DioClient`'s `idempotent:` flag) but has never been decided for a real endpoint | 🟠 | BLOCKED — by `BACKEND-1` |
| `PROD-6` | Whether the backend validates upload type/size is unknown, so whether the client must is undecided | 🟠 | BLOCKED — by `BACKEND-1` |

## Deliberate divergences

| Rule | Divergence | Status |
|---|---|---|
| `ARCH-1` | Cubits are constructed in `BlocProvider(create:)` per screen rather than `registerFactory` in GetIt. `ARCH-1` exists to stop a cubit outliving its screen; a cubit built in its screen's `BlocProvider` cannot. The protection is achieved by the widget tree's lifetime plus `BaseCubit.close()` cancelling its `CancelToken` | WONT_APPLY_WITH_REASON — reason above, and in `PROJECT.md` → Project-Specific Exceptions |
| `MAINT-3` | `lib/core/` uses `///` doc comments heavily while feature code uses none. Every `core/` block states a *why* or a trap, never a *what* — which is what `MAINT-3` asks for | WONT_APPLY_WITH_REASON — full four-question answer in `PROJECT.md` → Project-Specific Exceptions |
| `STYLE-4` | 29 recurring inline `Icons.*` stay at their call sites, because they cannot be promoted yet: **two classes are named `AppIcons`** — asset paths in `app_images.dart` (265 usages) and `IconData` in `app_icon.dart` (41 importers). A file can import one or the other, never both, and 28 of the 29 sites are in files that import the asset-path one, where `AppIcons.check` does not compile. Unblock: rename the asset-path class to `AppIconPaths`, or fold it into `app_icon.dart`'s `AppIconsAssets`, which is what that class already is | BLOCKED_WITH_REASON — a 265-site rename is outside a UI remediation's scope; Phase 11 runs immediately after it |
| `STYLE-2` | `_MapPainter`'s ten cartography colours stay local to `map_canvas.dart` (ground, block, park ×2, street ×2, highway ×2, here-dot ×2). They are one illustration's palette, not the app's: promoting ten map hues into `AppColors` would put entries in the palette that no screen may legitimately reuse, and the file they belong to is itself a stand-in for a real map SDK — when that SDK lands, the painter and its palette go together. The other **six** call-site literals were promoted (Phase 12D): three payment-scheme brand colours under a `brand*` prefix, plus `primaryGlow`, `kidsHeaderWash` and `surfaceGlassFaint` | WONT_APPLY_WITH_REASON — narrow to one file, stated at the point of use, and it disappears with the mock map |

## Verified clean at baseline

Not closed entries — these were never gaps. Recorded so the next session does not re-derive them,
and so a regression here is visible as a change (§3: a stale baseline is worse than none).

| Rule | Evidence, 2026-08-25 |
|---|---|
| `SEC-1` | Tokens exist only in `secure_storage.dart`; `shared_pref_keys.dart` holds no secret and says so |
| `SEC-5` | `sealed class Failure` + `ErrorCode` enum; no `Either<String, T>`, no thrown string |
| `SEC-7` | `ErrorMapper.hasBody` treats `null`, `''` and whitespace as bodiless; `safeCall` checks it **before** the status switch |
| `NET-1` | Three separate timeouts (10s/30s/30s) plus `uploadOptions()` at 5min send |
| `NET-6` | `ErrorCode.isSessionOver` is `unauthorized` only; 403 → `ForbiddenFailure`, never a sign-out |
| `STATE-5` | One `ViewStatus` enum, not combinable booleans |
| `STYLE-1` | User-facing text routes through `app_strings.dart` + `.tr()` |
| ~~`STYLE-2`~~ | ~~105 `Color(0xFF…)` literals, **all** inside `app_colors.dart`, 0 at call sites~~ **WRONG — see the divergence table above.** There were 16 at call sites in 5 files. The likely cause of the mistake: the adjacent `Colors.*` sweep genuinely was zero, and the two results were conflated |
| `STYLE-8` | `AppToast` only; no `SnackBar` anywhere |
| `A11Y-3` | `AppStateView` renders all four states, and builds content for `refreshing` as well as `success` |
| §7 | `analysis_options.yaml` matches §7's baseline: all nine lints present, `use_build_context_synchronously` / `unawaited_futures` / `avoid_dynamic_calls` promoted to `error`, `strict-casts` and `strict-raw-types` on |
