# Integration Test Guidelines (Flutter)

> **Scope:** General-purpose, project-independent guidelines for writing integration (end-to-end) tests in any Flutter project using the official `integration_test` package.
> These rules do not assume any architecture, backend, or state-management solution.
> Anything tied to a specific package or service is explicitly marked **(optional)**.

---

## Table of Contents

1. [Purpose](#1-purpose)
2. [When to Use](#2-when-to-use)
3. [When NOT to Use](#3-when-not-to-use)
4. [Testing Principles](#4-testing-principles)
5. [Recommended Structure](#5-recommended-structure)
6. [Naming Conventions](#6-naming-conventions)
7. [Setup and Teardown](#7-setup-and-teardown)
8. [Mocking / Fakes](#8-mocking--fakes)
9. [Common Patterns](#9-common-patterns)
10. [Examples](#10-examples)
11. [Common Mistakes](#11-common-mistakes)
12. [Do / Don't Rules](#12-do--dont-rules)
13. [How to Run the Tests](#13-how-to-run-the-tests)
14. [Final Checklist](#14-final-checklist)

---

## 1. Purpose

An **integration test** runs the real app (or a large part of it) on a **real device, emulator, or simulator** and drives it like a user would, verifying that multiple layers work together: UI, navigation, state, storage, platform plugins, and (optionally) a real or test backend.

Integration tests exist to:

- Prove that **business-critical user flows** work end to end.
- Catch problems that unit and widget tests cannot: plugin integration, platform channels, real rendering, real navigation stacks, app startup, configuration.
- Serve as a release gate before shipping to stores.

### Unit vs Widget vs Integration

| Aspect           | Unit test                    | Widget test                        | Integration test                                  |
| ---------------- | ---------------------------- | ---------------------------------- | ------------------------------------------------- |
| Scope            | One function/class           | One widget/screen                  | Whole app / full user flow                        |
| Runs on          | Dart VM                      | Headless Flutter test env          | Device / emulator / simulator (or desktop/web)    |
| Speed            | Milliseconds                 | Milliseconds–seconds               | Seconds–minutes                                   |
| Dependencies     | Faked/mocked                 | Faked/mocked                       | Real app wiring; backend real, test, or faked     |
| Plugins/native   | Not available                | Not available (must be faked)      | Available                                         |
| Time             | Real (or `fake_async`)       | Fake async (`pump(duration)`)      | Real time                                         |
| Confidence       | Logic correctness            | UI behavior                        | System works as a whole                           |
| Cost / flakiness | Lowest                       | Low                                | Highest                                           |
| Quantity         | Many                         | Many                               | Few, focused on critical paths                    |

---

## 2. When to Use

Use integration tests for a **small number of high-value flows**:

- **App launch**: app starts, splash/initialization completes, first screen appears.
- **Authentication**: sign up, sign in, sign out, session restore, invalid credentials.
- **Navigation flows**: deep navigation paths, tab switching, back behavior, deep links.
- **Forms** that submit real data: checkout, profile update, onboarding.
- **API-backed flows**: fetch → display → act → confirm, against a **test** backend or controlled fake server.
- **Database-backed flows**: data persists across screens and app restarts.
- **Business-critical flows**: payments (sandbox), ordering, booking, anything that loses money or users if broken.
- **Plugin integrations**: camera/gallery pickers, maps, secure storage, local notifications (where automatable).
- **Performance-sensitive flows** (optional): scrolling, startup, measured in profile mode.

Cover both **success** and key **failure** scenarios (e.g. wrong password, offline, server error, validation failure).

---

## 3. When NOT to Use

Do **not** use integration tests for:

- **Exhaustive input combinations or validation rules** → unit tests.
- **Every visual state of every widget** → widget tests.
- **Pure logic** (calculators, mappers, parsers) → unit tests.
- **Third-party services' own correctness** (that Firebase stores data, that the payment gateway works).
- **Production systems or production data** — never.
- **Flows requiring human judgment** (subjective visual quality) → manual QA or golden tests.
- **Flows that cannot be made deterministic** (real SMS OTP, real email links, real push delivery) unless the environment provides test hooks.

Rule of thumb: if a bug could be caught by a unit or widget test, write that test instead.

---

## 4. Testing Principles

1. **Test user journeys, not screens.** Each test tells a story: *user opens app → signs in → adds item → checks out → sees confirmation*.
2. **Critical paths first.** Prioritize by business impact and risk.
3. **Independence.** Every test must pass alone and in any order. Never rely on data created by a previous test.
4. **Isolation from production.** Use dedicated environments, test accounts, and test data.
5. **Determinism.** Control backend responses, seed data, locale, time zone, and feature flags.
6. **Explicit waiting.** Wait for **conditions** (a widget appears), not arbitrary durations.
7. **Stable selectors.** Use keys and user-visible text; never widget indices.
8. **Clean up.** Leave the environment as you found it (delete created data, sign out, clear storage).
9. **Observability.** On failure, capture screenshots and logs to diagnose quickly.
10. **Keep them few and valuable.** A small, reliable suite beats a large, flaky one.

---

## 5. Recommended Structure

### 5.1 Folder structure

```text
project_root/
├── integration_test/
│   ├── app_launch_test.dart
│   ├── auth_flow_test.dart
│   ├── checkout_flow_test.dart
│   ├── robots/                  # optional: page objects / robots
│   │   ├── login_robot.dart
│   │   └── home_robot.dart
│   └── helpers/
│       ├── test_app.dart        # boots the app with test configuration
│       ├── waiters.dart         # pumpUntilFound, etc.
│       └── test_data.dart       # test accounts, seed data builders
├── test_driver/                 # optional: only for `flutter drive` / some device farms
│   └── integration_test.dart
└── test/                        # unit & widget tests (separate)
```

- Integration tests live in `integration_test/` (not `test/`), and file names end with `_test.dart`.
- Group files by **flow**, not by screen.

### 5.2 Required dependency

The `integration_test` package ships with the Flutter SDK. It must be declared as a dev dependency in the project's `pubspec.yaml` (this guide does not modify it; add it only as part of adopting integration tests):

```yaml
dev_dependencies:
  integration_test:
    sdk: flutter
  flutter_test:
    sdk: flutter
```

### 5.3 Minimal test file

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App launch', () {
    testWidgets('shows the welcome screen on first launch', (tester) async {
      await startTestApp(tester);

      expect(find.text('Welcome'), findsOneWidget);
    });
  });
}
```

### 5.4 Robot / Page Object pattern (optional, recommended for larger suites)

Encapsulate **how** to interact with a screen so tests read as **what** the user does.

```dart
class LoginRobot {
  LoginRobot(this.tester);
  final WidgetTester tester;

  Future<void> enterEmail(String email) =>
      tester.enterText(find.byKey(const Key('login_emailField')), email);

  Future<void> enterPassword(String password) =>
      tester.enterText(find.byKey(const Key('login_passwordField')), password);

  Future<void> submit() async {
    await tester.tap(find.byKey(const Key('login_submitButton')));
    await tester.pumpAndSettle();
  }

  Future<void> signIn(String email, String password) async {
    await enterEmail(email);
    await enterPassword(password);
    await submit();
  }

  void expectErrorVisible(String message) =>
      expect(find.text(message), findsOneWidget);
}
```

---

## 6. Naming Conventions

| Item          | Convention                                   | Example                                              |
| ------------- | -------------------------------------------- | ---------------------------------------------------- |
| File          | `<flow>_flow_test.dart` / `<feature>_test.dart` | `auth_flow_test.dart`                             |
| Group         | Flow name                                    | `group('Authentication flow', ...)`                  |
| Test          | User journey + expected outcome              | `'user signs in with valid credentials and sees home'` |
| Robot         | `<Screen>Robot`                              | `LoginRobot`, `CartRobot`                            |
| Test accounts | Purpose-based, clearly non-production        | `e2e.buyer@example.test`                             |
| Keys          | `Key('<screen>_<element>')`                  | `Key('checkout_payButton')`                          |

**Good:** `user completes checkout with saved card and sees order confirmation`, `shows error when signing in with wrong password`.

**Bad:** `test login`, `flow 1`, `checkout works`.

---

## 7. Setup and Teardown

### 7.1 Binding

`IntegrationTestWidgetsFlutterBinding.ensureInitialized()` must be called **first** in `main()`. It connects the test to the device, reports results to the host, and enables features like screenshots and performance tracing.

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  // binding can be used for screenshots and traceAction (see §9)
}
```

### 7.2 Booting the app

Prefer a **test entry point** that lets you inject configuration over calling the production `main()` directly:

```dart
// integration_test/helpers/test_app.dart
import 'package:flutter_test/flutter_test.dart';

Future<void> startTestApp(
  WidgetTester tester, {
  TestConfig config = const TestConfig(),
}) async {
  // 1. Initialize services with TEST configuration (test API URL, test Firebase project, etc.)
  // 2. Reset local state (storage, caches, DB) so every test starts clean.
  // 3. Pump the root widget.
  await tester.pumpWidget(buildApp(config)); // buildApp = the project's root widget factory
  await tester.pumpAndSettle();
}
```

If the app only exposes `main()`, calling `app.main()` works, but it is harder to inject configuration and reset state.

> Services that are initialized once per process (e.g. some SDKs that throw if initialized twice) must be guarded so multiple tests in the same file can boot the app.

### 7.3 Setup / teardown per test

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestUser user;

  setUpAll(() async {
    // Once per file: e.g. verify test backend is reachable.
  });

  setUp(() async {
    user = await TestData.createUser();   // fresh, unique data per test
    await LocalState.clear();             // storage, DB, secure storage, caches
  });

  tearDown(() async {
    await TestData.deleteUser(user);      // clean remote data
    await LocalState.clear();
  });

  testWidgets('...', (tester) async { /* ... */ });
}
```

### 7.4 Test ordering

- All `testWidgets` in one file usually run **in the same app process**, in declaration order. Global state (singletons, caches, logged-in session, storage) **persists between them** unless you reset it.
- Different files are typically built and run as **separate app launches**.
- Do not design tests that depend on order. Reset state in `setUp`/`tearDown` so each test can run alone.

---

## 8. Mocking / Fakes

Integration tests use the **real app wiring**, but you still choose what sits at the edges.

| Boundary        | Options (from most real to most controlled)                                   |
| --------------- | ----------------------------------------------------------------------------- |
| Backend API     | Dedicated test/staging environment → local mock server → fake repository injected at boot |
| Firebase        | Separate test project → **Firebase Local Emulator Suite** (optional, recommended) |
| Payments        | Provider **sandbox/test mode** with test cards                                |
| Auth / OTP      | Test phone numbers / fixed OTP provided by the auth provider, or test backdoor in test env only |
| Time            | Inject clock via test configuration                                           |
| Feature flags   | Force values via test configuration                                           |
| Analytics/crash | Disable or send to a test project                                             |

Guidance:

- **API-backed flows**: use a test environment with seeded, resettable data, or a controlled fake server for deterministic failure scenarios (500s, timeouts, empty responses).
- **Fakes at boot**: for flows where the backend is not the subject, inject fake repositories through the app's DI when building the test app. This yields fast, deterministic E2E UI flows.
- Never point integration tests at production APIs, production databases, or production payment keys.

### Environment configuration with `--dart-define`

```dart
abstract final class Env {
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.test.example.com',
  );
  static const useFirebaseEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR');
}
```

```bash
flutter test integration_test \
  --dart-define=API_BASE_URL=https://api.test.example.com \
  --dart-define=USE_FIREBASE_EMULATOR=true
```

Optional: `--dart-define-from-file=env/test.json` to keep environment values in a file (never commit secrets).

---

## 9. Common Patterns

### 9.1 `pumpAndSettle()` and timeouts

- `pumpAndSettle()` pumps until no frames are scheduled. It **does not** wait for network requests that haven't triggered a frame, and it **never settles** while infinite animations (spinners, shimmer) are on screen, so it eventually throws a timeout error.
- On a real device, time is real; network calls take real time.

### 9.2 Waiting for UI changes (condition-based waiting)

Add a reusable helper instead of fixed delays:

```dart
// integration_test/helpers/waiters.dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

extension WaitFor on WidgetTester {
  /// Pumps frames until [finder] finds at least one widget or [timeout] elapses.
  Future<void> pumpUntilFound(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(step);
      if (finder.evaluate().isNotEmpty) return;
    }
    throw TestFailure('Timed out after $timeout waiting for $finder');
  }

  /// Pumps frames until [finder] disappears or [timeout] elapses.
  Future<void> pumpUntilGone(
    Finder finder, {
    Duration timeout = const Duration(seconds: 20),
    Duration step = const Duration(milliseconds: 100),
  }) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await pump(step);
      if (finder.evaluate().isEmpty) return;
    }
    throw TestFailure('Timed out after $timeout waiting for $finder to disappear');
  }
}
```

Usage:

```dart
await tester.tap(find.byKey(const Key('login_submitButton')));
await tester.pumpUntilFound(find.byKey(const Key('home_screen')));
```

### 9.3 Per-test timeouts

```dart
testWidgets(
  'user completes checkout',
  (tester) async { /* ... */ },
  timeout: const Timeout(Duration(minutes: 3)),
);
```

Keep timeouts generous enough for slow CI devices, but not unlimited — a hung test should fail, not block the pipeline.

### 9.4 App launch

```dart
testWidgets('app launches and shows login for signed-out user', (tester) async {
  await startTestApp(tester);

  await tester.pumpUntilFound(find.byKey(const Key('login_screen')));
  expect(find.text('Sign in'), findsOneWidget);
});
```

### 9.5 Authentication flow (success + failure)

```dart
group('Authentication flow', () {
  testWidgets('user signs in with valid credentials and sees home', (tester) async {
    await startTestApp(tester);
    final login = LoginRobot(tester);

    await login.signIn(TestAccounts.standard.email, TestAccounts.standard.password);

    await tester.pumpUntilFound(find.byKey(const Key('home_screen')));
    expect(find.textContaining('Welcome'), findsOneWidget);
  });

  testWidgets('shows error for wrong password and stays on login', (tester) async {
    await startTestApp(tester);
    final login = LoginRobot(tester);

    await login.signIn(TestAccounts.standard.email, 'wrong-password');

    await tester.pumpUntilFound(find.text('Incorrect email or password'));
    expect(find.byKey(const Key('home_screen')), findsNothing);
  });

  testWidgets('user signs out and returns to login', (tester) async {
    await startTestApp(tester, config: const TestConfig(signedIn: true));

    await tester.tap(find.byTooltip('Account'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sign out'));

    await tester.pumpUntilFound(find.byKey(const Key('login_screen')));
  });
});
```

### 9.6 Navigation flow

```dart
testWidgets('user navigates from list to details and back', (tester) async {
  await startTestApp(tester, config: const TestConfig(signedIn: true));

  await tester.pumpUntilFound(find.text('Products'));
  await tester.tap(find.text('Test Product A'));
  await tester.pumpAndSettle();

  expect(find.byKey(const Key('productDetails_screen')), findsOneWidget);

  await tester.pageBack();
  await tester.pumpAndSettle();

  expect(find.text('Products'), findsOneWidget);
});
```

### 9.7 Forms and API-backed flows

```dart
testWidgets('user updates profile name and it persists after reopening', (tester) async {
  await startTestApp(tester, config: const TestConfig(signedIn: true));

  await tester.tap(find.byTooltip('Profile'));
  await tester.pumpAndSettle();

  await tester.enterText(find.byKey(const Key('profile_nameField')), 'E2E Updated');
  await tester.tap(find.text('Save'));
  await tester.pumpUntilFound(find.text('Profile updated'));

  // Leave and come back: verify the data came from the backend/storage, not local widget state.
  await tester.pageBack();
  await tester.pumpAndSettle();
  await tester.tap(find.byTooltip('Profile'));
  await tester.pumpAndSettle();

  expect(find.text('E2E Updated'), findsOneWidget);
});
```

### 9.8 Database-backed flows

- Start each test from a **known database state** (empty or seeded).
- Verify persistence by navigating away and back, or by restarting the app root in the same test (re-pumping the root widget after disposing the old one).
- Clear the database in `setUp`/`tearDown`.

### 9.9 Scrolling in real lists

```dart
await tester.scrollUntilVisible(
  find.text('Test Product Z'),
  400,
  scrollable: find.byType(Scrollable).first,
);
await tester.tap(find.text('Test Product Z'));
await tester.pumpAndSettle();
```

### 9.10 Screenshots on important steps / failures

```dart
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('checkout confirmation', (tester) async {
    await startTestApp(tester);
    // ... flow ...

    // Android requires converting the Flutter surface before taking screenshots.
    await binding.convertFlutterSurfaceToImage();
    await tester.pumpAndSettle();
    await binding.takeScreenshot('checkout_confirmation');
  });
}
```

> Saving screenshots to disk requires running via `flutter drive` with a driver that handles screenshot data (see §13). Behavior can vary by platform and SDK version.

### 9.11 Performance measurement (optional, profile mode)

```dart
testWidgets('product list scrolls smoothly', (tester) async {
  await startTestApp(tester, config: const TestConfig(signedIn: true));

  await binding.traceAction(() async {
    await tester.fling(find.byType(ListView), const Offset(0, -600), 3000);
    await tester.pumpAndSettle();
  }, reportKey: 'product_list_scroll');
});
```

Run with `flutter drive --profile ...` on a **physical device** for meaningful numbers.

### 9.12 Firebase considerations (optional, only if the project uses Firebase)

- Use a **separate Firebase project** for testing, or the **Firebase Local Emulator Suite** (Auth, Firestore, Realtime Database, Storage, Functions).
- Connect to emulators during test boot, before any usage:

```dart
// Illustrative — call only when the test config enables emulators.
// await FirebaseAuth.instance.useAuthEmulator(host, 9099);
// FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
```

- Host: `localhost` works for iOS simulator; the Android emulator reaches the host machine at `10.0.2.2`.
- Clear emulator data between runs (emulator REST endpoints or restarting emulators).
- Disable or isolate Analytics/Crashlytics in tests.
- Guard `Firebase.initializeApp()` so repeated boots in one file don't fail.

### 9.13 Permissions

Native permission dialogs are **outside Flutter's widget tree**, so `WidgetTester` cannot tap them.

Options:

| Approach                                      | Notes                                                    |
| --------------------------------------------- | -------------------------------------------------------- |
| Pre-grant before running (Android)            | `adb shell pm grant <package> android.permission.CAMERA` |
| Pre-grant (iOS simulator)                     | `xcrun simctl privacy booted grant camera <bundle-id>`   |
| Abstract permission service + fake in tests   | Deterministic; tests the app's reaction, not the OS dialog |
| Native-automation tools (optional)            | e.g. Patrol, or native UI test frameworks, to interact with system dialogs |

Test both **granted** and **denied** paths where the app behavior differs.

### 9.14 Notifications and deep links (when applicable)

Deep links:

```bash
# Android
adb shell am start -a android.intent.action.VIEW -d "myapp://product/123" <package>

# iOS simulator
xcrun simctl openurl booted "myapp://product/123"
```

Inside a test, prefer driving the app's own route handling (e.g. boot the test app with an initial route/URI via test configuration) so the test stays self-contained; use OS-level commands for manual or scripted verification.

Notifications:

- Real push delivery is not deterministic; test **notification handling** (tap → correct screen) by invoking the app's handler with a sample payload through test configuration.
- Local notifications may be verifiable on-device; system notification shade interaction requires native-automation tools (optional).

### 9.15 Test data and test accounts

- Use **dedicated test accounts** with clearly non-production identifiers (e.g. `@example.test` domains).
- Prefer **creating unique data per test** (e.g. suffix with a timestamp/UUID) over sharing mutable accounts.
- Keep read-only reference data (seeded catalog items) stable and versioned.
- Store credentials in **CI secrets / environment variables**, never in source code.
- Provide a way to **reset** the test environment (API endpoint, script, or emulator reset).

```dart
abstract final class TestAccounts {
  static const standard = TestAccount(
    email: String.fromEnvironment('E2E_USER_EMAIL'),
    password: String.fromEnvironment('E2E_USER_PASSWORD'),
  );
}
```

### 9.16 Android, iOS, emulator, simulator, and physical devices

| Target            | Notes                                                                                     |
| ----------------- | ----------------------------------------------------------------------------------------- |
| Android emulator  | Fast feedback & CI. Use a fixed API level/image. Host machine = `10.0.2.2`. Disable animations for stability (`adb shell settings put global animator_duration_scale 0`, plus `window_animation_scale`, `transition_animation_scale`). |
| iOS simulator     | Requires macOS + Xcode. Grant permissions via `simctl`. Some features (push, some hardware) unavailable. |
| Physical Android  | Real performance and hardware; enable USB debugging.                                      |
| Physical iOS      | Requires code signing/provisioning; slower setup; best for release validation.           |
| Device farms (optional) | e.g. Firebase Test Lab or other cloud device services; usually require a driver/runner setup per platform. |

Always pin device models/OS versions in CI so results are reproducible.

### 9.17 Debug / profile / release considerations

| Mode        | Use for                                   | Notes                                                 |
| ----------- | ----------------------------------------- | ----------------------------------------------------- |
| **Debug**   | Writing and running functional tests      | Default for `flutter test integration_test`; slower, asserts enabled |
| **Profile** | Performance tests (`traceAction`)         | `flutter drive --profile`; physical device recommended |
| **Release** | Validating release-only behavior          | Limited tooling; verify obfuscation/minification doesn't break flows (e.g. reflection, serialization) |

- Code behind `kDebugMode` behaves differently in profile/release — don't rely on debug-only helpers for critical logic.
- Asserts are disabled outside debug; do not rely on asserts to catch failures.

### 9.18 CI/CD considerations

- Run integration tests on **pull requests for critical flows** and the **full suite nightly or before release**.
- Use reproducible emulators/simulators (fixed images), with animations disabled.
- Provide environment values via `--dart-define` from CI secrets.
- Start dependencies first (mock server, Firebase emulators), then run tests.
- Collect artifacts on failure: screenshots, device logs (`adb logcat`, simulator logs), test reports.
- Set a job-level timeout; retry **infrastructure** failures (emulator boot) but do not blindly retry failing tests — fix flakiness.
- Shard long suites across devices/jobs by file.

Illustrative CI step sequence:

```text
1. flutter pub get
2. Start emulator/simulator (fixed image), wait until booted, disable animations
3. Start test dependencies (mock server / Firebase emulators) if used
4. flutter test integration_test -d <device-id> --dart-define=...
5. Upload screenshots, logs, and reports as artifacts
```

### 9.19 Avoiding flaky integration tests

| Cause                                  | Fix                                                          |
| -------------------------------------- | ------------------------------------------------------------ |
| Fixed `Future.delayed` waits           | Condition-based waiting (`pumpUntilFound`)                   |
| `pumpAndSettle` with spinners/shimmers | Wait for the target widget instead                           |
| Shared accounts/data between tests     | Unique data per test; cleanup in `tearDown`                  |
| Leftover local state                   | Clear storage/DB/cache in `setUp`                            |
| Test order dependency                  | Each test boots from a clean state                           |
| Unstable backend                       | Dedicated test env or controlled fake server                 |
| System animations on device            | Disable device animations in CI                              |
| Permission dialogs                     | Pre-grant or abstract permissions                            |
| Locale/time zone differences           | Pin locale and time zone via test config / device settings   |
| Keyboard covering widgets              | `ensureVisible` / scroll before tapping; dismiss keyboard    |
| Index-based finders                    | Keys and visible text                                        |

---

## 10. Examples

### 10.1 Good vs bad

**❌ Bad: production data, fixed sleeps, order-dependent, vague**

```dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('test 1', (tester) async {
    app.main(); // production config → production API
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).first, 'real.customer@gmail.com');
    await tester.enterText(find.byType(TextField).last, 'RealPassword!');
    await tester.tap(find.byType(ElevatedButton));
    await Future.delayed(const Duration(seconds: 8)); // arbitrary wait
    await tester.pump();
  });

  testWidgets('test 2', (tester) async {
    // Assumes test 1 already logged in — breaks if run alone or reordered.
    await tester.tap(find.text('Buy'));
    await tester.pumpAndSettle();
    expect(find.text('Order placed'), findsOneWidget);
  });
}
```

Problems: hits production with a real customer account, fixed delays, index-based finders, no assertions in test 1, test 2 depends on test 1, no cleanup, meaningless names.

**✅ Good: isolated, deterministic, readable, cleans up**

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'helpers/test_app.dart';
import 'helpers/test_data.dart';
import 'helpers/waiters.dart';
import 'robots/cart_robot.dart';
import 'robots/login_robot.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late TestUser user;

  setUp(() async {
    user = await TestData.createUser();   // unique test user in TEST environment
    await LocalState.clear();
  });

  tearDown(() async {
    await TestData.deleteUser(user);
    await LocalState.clear();
  });

  group('Checkout flow', () {
    testWidgets(
      'signed-in user buys a product and sees order confirmation',
      (tester) async {
        await startTestApp(tester);

        await LoginRobot(tester).signIn(user.email, user.password);
        await tester.pumpUntilFound(find.byKey(const Key('home_screen')));

        final cart = CartRobot(tester);
        await cart.addProduct('E2E Test Product');
        await cart.openCart();
        await cart.checkoutWithTestCard();

        await tester.pumpUntilFound(find.text('Order placed'));
        expect(find.textContaining('Order #'), findsOneWidget);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );

    testWidgets(
      'shows payment error when test card is declined',
      (tester) async {
        await startTestApp(tester);

        await LoginRobot(tester).signIn(user.email, user.password);
        await tester.pumpUntilFound(find.byKey(const Key('home_screen')));

        final cart = CartRobot(tester);
        await cart.addProduct('E2E Test Product');
        await cart.openCart();
        await cart.checkoutWithDeclinedTestCard();

        await tester.pumpUntilFound(find.text('Payment was declined'));
        expect(find.text('Order placed'), findsNothing);
      },
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}
```

### 10.2 Good vs bad waiting

| ❌ Bad                                              | ✅ Good                                                   |
| -------------------------------------------------- | -------------------------------------------------------- |
| `await Future.delayed(Duration(seconds: 5));`      | `await tester.pumpUntilFound(find.text('Done'));`         |
| `await tester.pumpAndSettle();` with a spinner on screen | Wait for the result widget to appear                |
| `await tester.pump(Duration(seconds: 30));` "just in case" | Condition + bounded timeout                        |

---

## 11. Common Mistakes

1. **Forgetting `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`** at the start of `main()`.
2. **Running against production** APIs, databases, Firebase projects, or payment keys.
3. **Fixed sleeps** instead of condition-based waits → slow and flaky.
4. **`pumpAndSettle()` with infinite animations** → timeouts.
5. **Tests depending on each other** or on execution order.
6. **Shared, mutable test accounts** modified by multiple tests or parallel CI jobs.
7. **No cleanup** → data accumulates and later runs fail.
8. **Too many integration tests** covering what unit/widget tests should cover.
9. **Index-based or generic finders** → break with small UI changes.
10. **Ignoring native permission dialogs** → tests hang.
11. **Double-initializing SDKs** when booting the app multiple times in one file.
12. **Hard-coded credentials** in source code.
13. **Unpinned emulator/simulator versions in CI** → inconsistent results.
14. **Measuring performance in debug mode** → meaningless numbers.
15. **Retrying flaky tests instead of fixing them** → hides real problems.

---

## 12. Do / Don't Rules

| ✅ Do                                                              | ❌ Don't                                                     |
| ----------------------------------------------------------------- | ----------------------------------------------------------- |
| Cover a few business-critical flows end to end                    | Duplicate unit/widget coverage in integration tests         |
| Call `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` first | Skip the binding                                         |
| Boot the app through a configurable test entry point              | Hard-wire production configuration                          |
| Use dedicated test environments, accounts, and data               | Touch production systems or real customer data              |
| Create unique data per test and clean up                          | Share mutable accounts across tests/jobs                     |
| Wait for conditions with bounded timeouts                          | Use fixed `Future.delayed` sleeps                           |
| Use keys and visible text; robots for large suites                | Use `.at(index)` or generic layout finders                   |
| Test success **and** key failure paths                            | Only test the happy path                                     |
| Pre-grant or abstract permissions                                 | Leave tests blocked on native dialogs                        |
| Pin devices/OS images and disable animations in CI                | Run on random, unpinned devices                              |
| Capture screenshots/logs on failure                               | Debug failures without artifacts                             |
| Use profile mode on physical devices for performance              | Measure performance in debug mode                            |
| Keep secrets in CI secrets / `--dart-define`                      | Commit credentials or API keys                               |

---

## 13. How to Run the Tests

### 13.1 List devices

```bash
flutter devices
flutter emulators
flutter emulators --launch <emulator_id>
open -a Simulator            # macOS: open iOS simulator
```

### 13.2 Run with `flutter test` (recommended for most cases)

```bash
# Run all integration tests on the default/connected device
flutter test integration_test

# Run a single file
flutter test integration_test/auth_flow_test.dart

# Run on a specific device
flutter test integration_test -d emulator-5554
flutter test integration_test -d "iPhone 15"

# Run with environment configuration
flutter test integration_test \
  --dart-define=API_BASE_URL=https://api.test.example.com \
  --dart-define=E2E_USER_EMAIL=$E2E_USER_EMAIL \
  --dart-define=E2E_USER_PASSWORD=$E2E_USER_PASSWORD

# Filter by test name
flutter test integration_test --name "user signs in"

# Verbose reporter
flutter test integration_test -r expanded
```

### 13.3 Run with `flutter drive` (optional: screenshots, profile mode, some device farms)

Driver file:

```dart
// test_driver/integration_test.dart
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver();
```

For saving screenshots, use a driver that handles screenshot bytes (e.g. `integrationDriver(onScreenshot: ...)` from `package:integration_test/integration_test_driver_extended.dart`), writing them to a folder your CI uploads.

```bash
# Debug
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/auth_flow_test.dart \
  -d <device-id>

# Profile mode (performance), physical device recommended
flutter drive --profile \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/performance_test.dart \
  -d <device-id>
```

### 13.4 Desktop / web (optional)

```bash
# Desktop (if the project supports it)
flutter test integration_test -d macos
flutter test integration_test -d windows
flutter test integration_test -d linux

# Web requires a WebDriver (e.g. chromedriver) running, then flutter drive:
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_launch_test.dart \
  -d chrome
```

### 13.5 Device preparation helpers

```bash
# Android: disable animations
adb shell settings put global window_animation_scale 0
adb shell settings put global transition_animation_scale 0
adb shell settings put global animator_duration_scale 0

# Android: pre-grant a permission
adb shell pm grant <package> android.permission.CAMERA

# iOS simulator: pre-grant a permission
xcrun simctl privacy booted grant photos <bundle-id>
```

> Commands and flags may vary by SDK/tool version. Check `flutter test --help`, `flutter drive --help`, and platform tool documentation.

---

## 14. Final Checklist

- [ ] Tests live in `integration_test/`, files end with `_test.dart`, grouped by flow.
- [ ] `IntegrationTestWidgetsFlutterBinding.ensureInitialized()` is called first.
- [ ] Each test covers a real, business-relevant user journey.
- [ ] Success and key failure scenarios are covered.
- [ ] The app boots with **test** configuration (API, Firebase, flags) — never production.
- [ ] Test accounts and data are dedicated, non-production, and preferably unique per test.
- [ ] Credentials come from CI secrets / `--dart-define`, not source code.
- [ ] Local state (storage, DB, cache, session) is reset before each test.
- [ ] Remote test data is cleaned up after each test.
- [ ] Each test passes alone and in any order.
- [ ] Waiting is condition-based with bounded timeouts; no fixed sleeps.
- [ ] `pumpAndSettle()` is not used while infinite animations are on screen.
- [ ] Finders use keys and visible text; robots/page objects used for larger suites.
- [ ] Native permissions are pre-granted or abstracted.
- [ ] Deep links / notifications (if applicable) are tested through controllable entry points.
- [ ] Verified on Android and iOS targets relevant to the project (emulator/simulator and, before release, physical devices).
- [ ] CI uses pinned device images, disabled animations, timeouts, and uploads screenshots/logs on failure.
- [ ] Performance tests (if any) run in profile mode on physical devices.
- [ ] The suite is small, stable, and focused on critical paths.
