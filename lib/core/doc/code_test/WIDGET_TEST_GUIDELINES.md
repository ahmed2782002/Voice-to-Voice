# Widget Test Guidelines (Flutter)

> **Scope:** General-purpose, project-independent guidelines for writing widget tests in any Flutter project.
> These rules do not assume any architecture or state-management solution (BLoC, Cubit, Riverpod, Provider, GetX, `setState`, `ValueNotifier`, etc.).
> Anything tied to a specific package is explicitly marked **(optional)**.
>
> **Core rule:** Test what the **user can see and do**, not how the widget is implemented internally.

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

A **widget test** (sometimes called a component test) builds a widget tree in a test environment, lets you interact with it, and verifies what is rendered.

Widget tests exist to:

- Verify that UI renders the correct content for a given state (loading, success, error, empty).
- Verify that user interactions (tap, type, scroll, drag) produce the correct visible result.
- Verify form validation messages, dialogs, bottom sheets, and navigation outcomes.
- Catch UI regressions without the cost of running a full app on a device.

Widget tests run in a headless Flutter environment (no device, no emulator), are fast (tens to hundreds of milliseconds each), and sit in the **middle of the testing pyramid**.

| Property      | Widget test expectation                                  |
| ------------- | -------------------------------------------------------- |
| Speed         | Fast (ms per test)                                       |
| Scope         | One widget, one screen, or a small subtree               |
| Dependencies  | Replaced with fakes/mocks (repositories, services, APIs) |
| Environment   | Headless test binding, fake async time                   |
| Focus         | Observable behavior: text, icons, enabled state, navigation |

---

## 2. When to Use

Write widget tests for:

- **Reusable components**: buttons, cards, list tiles, custom inputs.
- **Screens/pages** with their different visual states.
- **Forms**: input, validation messages, submit behavior, disabled/enabled buttons.
- **Conditional UI**: widgets that show/hide content based on data or permissions.
- **Interactions**: taps, text entry, scrolling, swiping, long press.
- **Dialogs and bottom sheets**: open, content, confirm/cancel actions.
- **Navigation outcomes**: "tapping X shows screen Y" or "back returns to previous screen".
- **Accessibility**: semantics labels, tap target size, text contrast (when appropriate).
- **Responsive layouts**: different layouts for different screen sizes/orientations.
- **Localization/theming** when widgets change based on locale or theme.

---

## 3. When NOT to Use

Do **not** use widget tests for:

- **Pure business logic** (calculations, validation rules, mapping) → unit tests.
- **Complete multi-screen flows with real backends** → integration tests.
- **Native platform behavior** (real camera, real permissions dialog, push notifications, real maps SDK) → integration/manual tests.
- **Exact pixel positions, padding values, or colors** unless they are a real requirement → golden tests (sparingly) or none.
- **Framework widgets themselves** (that `Text` renders text, that `ListView` scrolls).
- **Private state or private methods** of a `State` class.
- **Real network images, real HTTP, real databases** — they are unavailable or non-deterministic in the test environment.

---

## 4. Testing Principles

### 4.1 Arrange → Act → Assert

```dart
testWidgets('shows greeting after tapping the button', (tester) async {
  // Arrange
  await tester.pumpWidget(const MaterialApp(home: GreetingScreen()));

  // Act
  await tester.tap(find.text('Say hello'));
  await tester.pump();

  // Assert
  expect(find.text('Hello!'), findsOneWidget);
});
```

### 4.2 Test observable behavior

| ✅ Test this (observable)                     | ❌ Not this (implementation detail)                 |
| -------------------------------------------- | -------------------------------------------------- |
| "Error message is visible"                   | "`_hasError` field is `true`"                      |
| "Submit button is disabled"                  | "`setState` was called twice"                       |
| "Tapping item shows details screen"          | "Widget tree contains exactly 3 `Padding` widgets" |
| "List shows 3 items with names"              | "Private `_buildItem` method was invoked"          |

### 4.3 Prefer user-facing finders

In order of preference:

1. `find.text` / `find.textContaining` — what the user reads.
2. `find.bySemanticsLabel` / `find.byTooltip` — what assistive technology reads.
3. `find.byIcon` — what the user sees.
4. `find.byKey` — stable, explicit hook for elements without unique text.
5. `find.byType` — for your own custom widgets; avoid for generic framework types (`Container`, `Padding`).

### 4.4 Isolation and determinism

- Replace all external dependencies with fakes/mocks.
- Control time with `pump(duration)` instead of real waiting.
- Pin screen size, locale, and theme when the output depends on them.
- Each `testWidgets` gets a fresh widget tree; do not rely on state from previous tests.

---

## 5. Recommended Structure

### 5.1 Folder structure

Mirror `lib/` inside `test/`:

```text
test/
├── helpers/
│   ├── pump_app.dart          # shared wrapper (MaterialApp, theme, localization, DI)
│   ├── fakes.dart             # fake repositories/services
│   └── finders.dart           # optional custom finders
├── src/
│   ├── widgets/
│   │   └── primary_button_test.dart
│   └── screens/
│       └── login_screen_test.dart
└── goldens/                   # optional: golden image files
```

Optional alternative: `test/unit/`, `test/widget/`, `test/helpers/`. Be consistent.

### 5.2 A shared "pump app" helper

Almost every widget needs `MaterialApp` (or `CupertinoApp`/`WidgetsApp`) ancestors for `Directionality`, `MediaQuery`, `Theme`, `Navigator`, and `Localizations`. Centralize this:

```dart
// test/helpers/pump_app.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    ThemeData? theme,
    Locale? locale,
    List<LocalizationsDelegate<dynamic>> localizationsDelegates = const [],
    List<Locale> supportedLocales = const [Locale('en')],
    List<NavigatorObserver> navigatorObservers = const [],
  }) {
    return pumpWidget(
      MaterialApp(
        theme: theme,
        locale: locale,
        localizationsDelegates: localizationsDelegates,
        supportedLocales: supportedLocales,
        navigatorObservers: navigatorObservers,
        home: Scaffold(body: widget),
      ),
    );
  }
}
```

If the project uses a DI container or state-management provider, extend this helper to wrap the widget with the project's providers **using fakes** — the helper is the single place to adapt to any architecture.

---

## 6. Naming Conventions

| Item          | Convention                                 | Example                                   |
| ------------- | ------------------------------------------ | ----------------------------------------- |
| Test file     | `<widget_file>_test.dart`                  | `login_screen_test.dart`                  |
| Top group     | Widget name                                | `group('LoginScreen', ...)`               |
| Nested group  | State or feature                           | `group('validation', ...)`                |
| Test          | *shows / hides / enables / navigates … when …* | `'shows error text when email is invalid'` |
| Keys          | `Key('<screen>_<element>')` or `ValueKey`  | `Key('login_submitButton')`               |

**Good:** `shows loading indicator while submitting`, `disables submit button when form is empty`, `navigates to HomeScreen after successful login`.

**Bad:** `login screen test`, `test button`, `works`.

Keys used by tests should be **constants** defined once (e.g. in the widget file or a shared keys file) so tests and widgets never drift apart.

```dart
abstract final class LoginKeys {
  static const email = Key('login_emailField');
  static const password = Key('login_passwordField');
  static const submit = Key('login_submitButton');
}
```

---

## 7. Setup and Teardown

The same `group`, `setUp`, `setUpAll`, `tearDown`, `tearDownAll`, and `addTearDown` functions from unit tests are available.

```dart
void main() {
  late FakeAuthService auth;

  setUp(() {
    auth = FakeAuthService(); // fresh fake for every test
  });

  group('LoginScreen', () {
    testWidgets('...', (tester) async {
      await tester.pumpApp(LoginScreen(auth: auth));
      // ...
    });
  });
}
```

Test-scoped cleanup inside a widget test:

```dart
testWidgets('adapts to tablet width', (tester) async {
  tester.view.physicalSize = const Size(1200, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset); // always restore view settings

  // ...
});
```

**Rules**

- Create fakes/mocks in `setUp`, not `setUpAll`.
- Always reset changed view/screen settings with `addTearDown`.
- Dispose controllers you create in the test (`addTearDown(controller.dispose)`).
- The framework fails a test that leaves **pending timers**; make sure animations/timers finish or are disposed.

---

## 8. Mocking / Fakes

### 8.1 Principle

A widget test should never reach a real backend. Provide dependencies through whatever mechanism the project uses — **constructor parameters, an inherited widget, a provider, a DI container** — and pass fakes or mocks.

### 8.2 Fake repository (no package required)

```dart
class FakeProductRepository implements ProductRepository {
  FakeProductRepository({this.products = const [], this.error});

  final List<Product> products;
  final Object? error;
  Completer<List<Product>>? pending; // for controlling loading state

  @override
  Future<List<Product>> fetchAll() {
    if (pending != null) return pending!.future;
    if (error != null) return Future.error(error!);
    return Future.value(products);
  }
}
```

### 8.3 Mocks (optional: Mocktail or Mockito)

```dart
import 'package:mocktail/mocktail.dart';

class MockProductRepository extends Mock implements ProductRepository {}

final repo = MockProductRepository();
when(() => repo.fetchAll()).thenAnswer((_) async => [product]);
```

### 8.4 Injecting into the widget tree (architecture-agnostic)

```dart
// Constructor injection (works everywhere)
await tester.pumpApp(ProductsScreen(repository: fakeRepo));

// Or via the project's own mechanism, for example (illustrative only):
// - InheritedWidget:     AppDependencies(repository: fakeRepo, child: ...)
// - Provider (optional): Provider<ProductRepository>.value(value: fakeRepo, child: ...)
// - Riverpod (optional): ProviderScope(overrides: [repoProvider.overrideWithValue(fakeRepo)], child: ...)
// - Bloc (optional):     BlocProvider.value(value: mockCubit, child: ...)
// - Service locator:     register fakeRepo in setUp, reset in tearDown
```

### 8.5 Widgets that depend on state management

Two valid strategies — choose deliberately:

| Strategy                           | How                                                       | Good for                              |
| ---------------------------------- | --------------------------------------------------------- | ------------------------------------- |
| **Real state holder + fake data**  | Real Cubit/ViewModel/Notifier, fake repository            | Testing UI + state wiring together    |
| **Mocked state holder**            | Mock/stub the state holder to emit fixed states           | Testing pure rendering of each state  |

Example with a generic `ValueNotifier` (no package):

```dart
testWidgets('renders counter value from notifier', (tester) async {
  final counter = ValueNotifier<int>(5);
  addTearDown(counter.dispose);

  await tester.pumpApp(CounterView(counter: counter));
  expect(find.text('5'), findsOneWidget);

  counter.value = 6;
  await tester.pump();
  expect(find.text('6'), findsOneWidget);
});
```

### 8.6 Things that must be faked in widget tests

| Dependency                   | Why                                                 | Approach                                              |
| ---------------------------- | --------------------------------------------------- | ----------------------------------------------------- |
| HTTP / APIs                  | No network in tests                                 | Fake repository/service                               |
| `Image.network`              | Test HTTP client returns errors by default          | Inject an image provider, use a placeholder, or optional helper packages for network image mocking |
| Platform channels / plugins  | No native side in headless tests                    | Wrap plugins behind an interface and fake it; or mock the channel via `TestDefaultBinaryMessengerBinding` |
| Local storage                | Real persistence breaks isolation                   | In-memory fake (or the plugin's own test helper, if provided) |
| Clock / timers               | Determinism                                         | Inject clock; control time with `tester.pump(duration)` |

---

## 9. Common Patterns

### 9.1 Core API reference

| API                         | Purpose                                                               |
| --------------------------- | --------------------------------------------------------------------- |
| `testWidgets(desc, cb)`     | Defines a widget test; gives you a `WidgetTester`                     |
| `WidgetTester`              | Builds widgets, simulates input, advances frames/time                 |
| `pumpWidget(widget)`        | Renders the given widget as the root and triggers one frame           |
| `pump([duration])`          | Triggers one frame, optionally advancing fake time by `duration`      |
| `pumpAndSettle([duration])` | Pumps repeatedly until no frames are scheduled (animations finished); **times out** if something animates forever |
| `tap(finder)`               | Taps the center of the found widget                                   |
| `longPress(finder)`         | Long-presses the found widget                                         |
| `enterText(finder, text)`   | Focuses a text field and replaces its text                            |
| `drag(finder, offset)`      | Drags the found widget by an offset                                   |
| `fling(finder, offset, speed)` | Flings (fast drag) the widget                                      |
| `scrollUntilVisible(finder, delta)` | Scrolls a scrollable until the target is built and visible   |
| `ensureVisible(finder)`     | Scrolls ancestors so the widget is visible                            |
| `pageBack()`                | Simulates the back button of `AppBar`/`CupertinoNavigationBar`        |
| `runAsync(cb)`              | Runs real async work (e.g. real I/O) outside fake async — use rarely  |

### 9.2 Finders and matchers

```dart
find.text('Login');                          // exact text
find.textContaining('Welcome');              // partial text
find.byType(ProductCard);                    // widget type (prefer your own types)
find.byKey(LoginKeys.submit);                // key
find.byIcon(Icons.delete);                   // icon
find.byTooltip('Delete');                    // tooltip
find.bySemanticsLabel('Close');              // semantics label
find.widgetWithText(ElevatedButton, 'Save'); // widget of type containing text
find.descendant(of: find.byType(AppBar), matching: find.text('Home'));
find.ancestor(of: find.text('Item 1'), matching: find.byType(ListTile));
```

| Matcher                    | Meaning                          |
| -------------------------- | -------------------------------- |
| `findsOneWidget`           | Exactly one match                |
| `findsNothing`             | No matches                       |
| `findsWidgets`             | One or more                      |
| `findsNWidgets(n)`         | Exactly `n`                      |
| `findsAtLeastNWidgets(n)`  | At least `n`                     |

Reading widget properties (for user-observable state like enabled/disabled):

```dart
final button = tester.widget<ElevatedButton>(find.byKey(LoginKeys.submit));
expect(button.onPressed, isNull); // disabled
```

### 9.3 `pump()` vs `pumpAndSettle()`

| Situation                                                  | Use                                      |
| ---------------------------------------------------------- | ---------------------------------------- |
| `setState` / state change, no animation                    | `pump()`                                 |
| Future completed (already-resolved fake)                   | `pump()` (sometimes two pumps)           |
| Navigation push/pop, dialog, bottom sheet, animations      | `pumpAndSettle()`                        |
| Debounce / timer of known length                           | `pump(const Duration(milliseconds: 300))`|
| Infinite animation on screen (e.g. `CircularProgressIndicator`) | `pump()` — **never** `pumpAndSettle()` (it will time out) |

### 9.4 Buttons and interactions

```dart
testWidgets('calls onPressed when tapped', (tester) async {
  var taps = 0;
  await tester.pumpApp(PrimaryButton(label: 'Save', onPressed: () => taps++));

  await tester.tap(find.text('Save'));
  await tester.pump();

  expect(taps, 1);
});

testWidgets('does not react when disabled', (tester) async {
  await tester.pumpApp(const PrimaryButton(label: 'Save', onPressed: null));

  await tester.tap(find.text('Save'), warnIfMissed: false);
  await tester.pump();

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  expect(button.onPressed, isNull);
});
```

### 9.5 Forms, text fields, and validation

```dart
group('LoginForm validation', () {
  testWidgets('shows errors when submitted empty', (tester) async {
    await tester.pumpApp(LoginForm(onSubmit: (_, __) {}));

    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('shows error for invalid email', (tester) async {
    await tester.pumpApp(LoginForm(onSubmit: (_, __) {}));

    await tester.enterText(find.byKey(LoginKeys.email), 'not-an-email');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('submits trimmed values when valid', (tester) async {
    String? email;
    String? password;
    await tester.pumpApp(LoginForm(onSubmit: (e, p) {
      email = e;
      password = p;
    }));

    await tester.enterText(find.byKey(LoginKeys.email), ' ann@example.com ');
    await tester.enterText(find.byKey(LoginKeys.password), 'Secret123!');
    await tester.tap(find.byKey(LoginKeys.submit));
    await tester.pump();

    expect(email, 'ann@example.com');
    expect(password, 'Secret123!');
    expect(find.textContaining('required'), findsNothing);
  });
});
```

Text field tips:

- `enterText` replaces the whole text; it does not append.
- To test live (on-change) validation, `pump()` after `enterText`.
- To submit via keyboard: `await tester.testTextInput.receiveAction(TextInputAction.done);`

### 9.6 Loading, success, error, and empty states

Use a `Completer` to hold the loading state open deterministically:

```dart
group('ProductsScreen states', () {
  testWidgets('shows loading indicator while fetching', (tester) async {
    final repo = FakeProductRepository()..pending = Completer();
    await tester.pumpApp(ProductsScreen(repository: repo));
    await tester.pump(); // start the fetch; do NOT pumpAndSettle (spinner animates)

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    repo.pending!.complete([]); // let the test finish cleanly
    await tester.pumpAndSettle();
  });

  testWidgets('shows products on success', (tester) async {
    final repo = FakeProductRepository(products: [
      const Product(id: '1', name: 'Apple'),
      const Product(id: '2', name: 'Banana'),
    ]);
    await tester.pumpApp(ProductsScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Apple'), findsOneWidget);
    expect(find.text('Banana'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows error message and retry on failure', (tester) async {
    final repo = FakeProductRepository(error: Exception('boom'));
    await tester.pumpApp(ProductsScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('Something went wrong'), findsOneWidget);
    expect(find.widgetWithText(TextButton, 'Retry'), findsOneWidget);
  });

  testWidgets('shows empty message when there are no products', (tester) async {
    final repo = FakeProductRepository(products: []);
    await tester.pumpApp(ProductsScreen(repository: repo));
    await tester.pumpAndSettle();

    expect(find.text('No products yet'), findsOneWidget);
  });
});
```

### 9.7 Dialogs

```dart
testWidgets('confirms deletion via dialog', (tester) async {
  var deleted = false;
  await tester.pumpApp(DeleteButton(onConfirmed: () => deleted = true));

  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle(); // dialog open animation

  expect(find.byType(AlertDialog), findsOneWidget);
  expect(find.text('Delete this item?'), findsOneWidget);

  await tester.tap(find.text('Delete'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsNothing);
  expect(deleted, isTrue);
});

testWidgets('cancel closes dialog without deleting', (tester) async {
  var deleted = false;
  await tester.pumpApp(DeleteButton(onConfirmed: () => deleted = true));

  await tester.tap(find.byIcon(Icons.delete));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Cancel'));
  await tester.pumpAndSettle();

  expect(find.byType(AlertDialog), findsNothing);
  expect(deleted, isFalse);
});
```

### 9.8 Bottom sheets

```dart
testWidgets('opens sort options bottom sheet and applies selection', (tester) async {
  SortOrder? selected;
  await tester.pumpApp(SortButton(onChanged: (s) => selected = s));

  await tester.tap(find.byTooltip('Sort'));
  await tester.pumpAndSettle();

  expect(find.text('Price: low to high'), findsOneWidget);

  await tester.tap(find.text('Price: low to high'));
  await tester.pumpAndSettle();

  expect(find.text('Price: low to high'), findsNothing); // sheet closed
  expect(selected, SortOrder.priceAsc);
});
```

### 9.9 Navigation

Assert the **destination is visible** rather than inspecting the navigator internals.

```dart
testWidgets('tapping a product opens its details', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: ProductsList(products: const [Product(id: '1', name: 'Apple')]),
    // Use the same routing setup the widget expects (routes, onGenerateRoute,
    // or a router configuration). Keep it minimal and test-local.
  ));

  await tester.tap(find.text('Apple'));
  await tester.pumpAndSettle();

  expect(find.byType(ProductDetailsScreen), findsOneWidget);
});

testWidgets('back returns to list', (tester) async {
  // ...navigate to details first...
  await tester.pageBack();
  await tester.pumpAndSettle();

  expect(find.byType(ProductsList), findsOneWidget);
});
```

Optional: verify navigation calls with a mocked `NavigatorObserver` (`didPush`), or with a mocked router/navigation service if the project abstracts navigation. Prefer asserting visible results when possible.

### 9.10 Scrolling and dragging

```dart
testWidgets('finds item far down the list', (tester) async {
  await tester.pumpApp(ItemsList(items: List.generate(100, (i) => 'Item $i')));

  await tester.scrollUntilVisible(
    find.text('Item 80'),
    300, // scroll delta per step
    scrollable: find.byType(Scrollable).first,
  );

  expect(find.text('Item 80'), findsOneWidget);
});

testWidgets('swipe to dismiss removes item', (tester) async {
  await tester.pumpApp(DismissibleList(items: const ['A', 'B']));

  await tester.drag(find.text('A'), const Offset(-500, 0));
  await tester.pumpAndSettle();

  expect(find.text('A'), findsNothing);
  expect(find.text('B'), findsOneWidget);
});
```

> Lists are **lazily built**: an item that is off-screen is not in the tree, so `find.text` returns nothing until you scroll to it.

### 9.11 Asynchronous UI updates and animations

- Widget tests run in **fake async**: `Future.delayed` and `Timer` only progress when you `pump(duration)`.
- Use `pump(duration)` to advance debounce timers, snackbars, auto-dismiss toasts.
- Use `pumpAndSettle()` for finite animations (routes, dialogs, `AnimatedContainer`).
- For infinite animations, use `pump()`/`pump(duration)` and assert.
- Use `tester.runAsync(() async { ... })` only when real async work is unavoidable (e.g. decoding a real image file); keep it rare.

```dart
testWidgets('snackbar disappears after 4 seconds', (tester) async {
  await tester.pumpApp(const SaveButton());

  await tester.tap(find.text('Save'));
  await tester.pump(); // start snackbar animation
  expect(find.text('Saved'), findsOneWidget);

  await tester.pump(const Duration(seconds: 4));
  await tester.pumpAndSettle();
  expect(find.text('Saved'), findsNothing);
});
```

### 9.12 Accessibility and semantics (when appropriate)

```dart
testWidgets('icon button has an accessible label', (tester) async {
  final handle = tester.ensureSemantics();

  await tester.pumpApp(const FavoriteButton());

  expect(find.bySemanticsLabel('Add to favorites'), findsOneWidget);

  handle.dispose();
});

testWidgets('meets accessibility guidelines', (tester) async {
  final handle = tester.ensureSemantics();
  await tester.pumpApp(const LoginScreenBody());

  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));

  handle.dispose();
});
```

### 9.13 Localization

```dart
testWidgets('shows translated title in Arabic', (tester) async {
  await tester.pumpWidget(MaterialApp(
    locale: const Locale('ar'),
    supportedLocales: const [Locale('en'), Locale('ar')],
    localizationsDelegates: const [
      // The project's own delegate(s), e.g. AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,  // from flutter_localizations
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    home: const WelcomeScreen(),
  ));
  await tester.pumpAndSettle(); // localization delegates load asynchronously

  expect(find.text('مرحبا'), findsOneWidget);
});
```

- Pin the locale explicitly; never rely on the machine's locale.
- For RTL layouts, assert `Directionality.of(context)` behavior indirectly via visible order or use golden tests.
- If asserting translated strings is brittle, assert via keys and test translations separately.

### 9.14 Themes

```dart
testWidgets('uses dark theme surface color', (tester) async {
  await tester.pumpApp(const StatusBadge(), theme: ThemeData.dark());

  final context = tester.element(find.byType(StatusBadge));
  expect(Theme.of(context).brightness, Brightness.dark);
});
```

Test theme-dependent **behavior** (e.g. an icon changes in dark mode) rather than exact color values, unless colors are a documented requirement.

### 9.15 MediaQuery, screen size, text scale, and responsive layouts

```dart
testWidgets('shows side navigation on wide screens', (tester) async {
  tester.view.physicalSize = const Size(1400, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpApp(const AdaptiveShell());

  expect(find.byType(NavigationRail), findsOneWidget);
  expect(find.byType(NavigationBar), findsNothing);
});

testWidgets('shows bottom navigation on phones', (tester) async {
  tester.view.physicalSize = const Size(390, 844);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  await tester.pumpApp(const AdaptiveShell());

  expect(find.byType(NavigationBar), findsOneWidget);
});

testWidgets('does not overflow at large text scale', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: MediaQuery(
      data: const MediaQueryData(textScaler: TextScaler.linear(2.0)),
      child: const Scaffold(body: ProfileHeader()),
    ),
  ));

  expect(tester.takeException(), isNull); // RenderFlex overflow would surface here
});
```

> `tester.view` requires a recent Flutter SDK. On older SDKs the equivalent API was `tester.binding.window.physicalSizeTestValue`. Use what your SDK supports.

### 9.16 Golden tests (optional, use sparingly)

Golden tests compare a rendered widget against a stored reference image.

```dart
testWidgets('PrimaryButton matches golden', (tester) async {
  await tester.pumpApp(const PrimaryButton(label: 'Save', onPressed: null));

  await expectLater(
    find.byType(PrimaryButton),
    matchesGoldenFile('goldens/primary_button_disabled.png'),
  );
});
```

```bash
flutter test --update-goldens   # create/update reference images
```

| Appropriate                                          | Not appropriate                                  |
| ---------------------------------------------------- | ------------------------------------------------ |
| Stable design-system components                      | Screens that change frequently                   |
| Visual regressions that behavior tests can't catch   | Replacing behavior assertions                    |
| Charts, custom painters, complex layouts             | Widgets containing dynamic data (dates, random)  |

Caveats:

- Rendering (especially fonts/anti-aliasing) can differ across operating systems; **generate and compare goldens on the same platform** (commonly the CI OS).
- Default test font renders text as boxes unless real fonts are loaded; optional helper packages exist for loading fonts and multi-device goldens.
- Review updated goldens in code review like any other change.

---

## 10. Examples

### 10.1 Good vs bad

**❌ Bad: implementation details, fragile, real dependency, unclear**

```dart
testWidgets('login', (tester) async {
  await tester.pumpWidget(MaterialApp(home: LoginScreen(auth: RealAuthService())));

  expect(find.byType(Padding), findsNWidgets(7));          // layout detail
  expect(find.byType(Column), findsOneWidget);             // structure detail

  await tester.enterText(find.byType(TextField).at(0), 'a@b.com'); // index-based
  await tester.enterText(find.byType(TextField).at(1), '123456');
  await tester.tap(find.byType(ElevatedButton));
  await tester.pumpAndSettle(const Duration(seconds: 5));  // hits real API

  final state = tester.state<LoginScreenState>(find.byType(LoginScreen));
  expect(state.isLoggedIn, true);                          // private state
});
```

Problems: real network, asserts widget counts and private state, index-based finders, one test for everything, vague name.

**✅ Good: behavior-focused, isolated, readable**

```dart
void main() {
  late FakeAuthService auth;

  setUp(() => auth = FakeAuthService());

  group('LoginScreen', () {
    Future<void> fillAndSubmit(WidgetTester tester) async {
      await tester.enterText(find.byKey(LoginKeys.email), 'ann@example.com');
      await tester.enterText(find.byKey(LoginKeys.password), 'Secret123!');
      await tester.tap(find.byKey(LoginKeys.submit));
    }

    testWidgets('shows loading indicator while signing in', (tester) async {
      auth.pending = Completer<void>();
      await tester.pumpApp(LoginScreen(auth: auth));

      await fillAndSubmit(tester);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      auth.pending!.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('shows error message when credentials are wrong', (tester) async {
      auth.error = const InvalidCredentials();
      await tester.pumpApp(LoginScreen(auth: auth));

      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.text('Incorrect email or password'), findsOneWidget);
    });

    testWidgets('navigates to home after successful sign in', (tester) async {
      await tester.pumpApp(LoginScreen(auth: auth));

      await fillAndSubmit(tester);
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });
}
```

### 10.2 Good vs bad finders

| ❌ Fragile                                   | ✅ Robust                                              |
| ------------------------------------------- | ----------------------------------------------------- |
| `find.byType(TextField).at(1)`              | `find.byKey(LoginKeys.password)`                      |
| `find.byType(Container)`                    | `find.byType(ProductCard)`                            |
| `find.byType(ElevatedButton)` (many exist)  | `find.widgetWithText(ElevatedButton, 'Save')`         |
| `find.text('Loading...')` hard-coded in several places | Shared constant or key                     |
| Asserting `findsNWidgets(12)` for padding   | Asserting the visible items the user cares about      |

---

## 11. Common Mistakes

1. **Using `pumpAndSettle()` with an infinite animation** (spinners, shimmer) → "pumpAndSettle timed out". Use `pump()`.
2. **Forgetting to `pump()` after an interaction** → UI not rebuilt; assertion fails.
3. **Not wrapping in `MaterialApp`/`Scaffold`** → missing `Directionality`, `MediaQuery`, `Material`, or `Navigator` errors.
4. **Real network calls or `Image.network`** → failures or flakiness.
5. **Testing private `State` fields** → breaks on every refactor.
6. **Index-based finders (`.at(n)`)** → break when layout order changes.
7. **Asserting layout details** (number of `Padding`, exact sizes) that users don't care about.
8. **Not resetting `tester.view`** changes → leaks into other tests.
9. **Leaving pending timers** (debounce, polling) → "A Timer is still pending" failure. Advance time or dispose.
10. **Tapping off-screen widgets** → tap misses; use `ensureVisible` or `scrollUntilVisible` first.
11. **Relying on machine locale/theme** → different results on CI.
12. **Overusing golden tests** → noisy, platform-dependent failures.
13. **One giant test for a whole screen** → hard to diagnose; split by state/behavior.
14. **Duplicated wrapper setup in every file** → use a shared `pumpApp` helper.
15. **Forgetting `ensureSemantics()`** when asserting semantics.

---

## 12. Do / Don't Rules

| ✅ Do                                                              | ❌ Don't                                                |
| ----------------------------------------------------------------- | ------------------------------------------------------ |
| Test what the user sees and does                                  | Test private state or internal method calls            |
| Use `find.text`, semantics, icons, keys, own widget types         | Use generic `Container`/`Padding` finders or `.at(n)`   |
| Use a shared `pumpApp` helper                                     | Repeat `MaterialApp` setup in every test               |
| Inject fakes/mocks through the project's DI mechanism             | Call real APIs, databases, or plugins                  |
| Test loading, success, error, and empty states separately         | Only test the happy path                               |
| Use `Completer` to control loading state                          | Use real delays to "catch" a loading state             |
| Use `pump()` for spinners, `pumpAndSettle()` for finite animations | Blindly call `pumpAndSettle()` everywhere             |
| Pin screen size, locale, theme when output depends on them        | Depend on the machine's defaults                       |
| Reset view changes with `addTearDown`                             | Leak screen-size changes to other tests                |
| Define test keys as shared constants                              | Hard-code key strings in multiple places               |
| Keep each test focused on one behavior                            | Write one test that covers an entire screen            |
| Use goldens only for stable visual components (optional)          | Replace behavior tests with goldens                    |

---

## 13. How to Run the Tests

```bash
# Run all tests (unit + widget) under test/
flutter test

# Run only widget tests (if separated into a folder)
flutter test test/widget

# Run a single file
flutter test test/src/screens/login_screen_test.dart

# Run tests matching a name (regex)
flutter test --name "LoginScreen shows error"

# Verbose output
flutter test -r expanded

# Detect order dependency
flutter test --test-randomize-ordering-seed random

# Coverage report (coverage/lcov.info)
flutter test --coverage

# Golden tests (optional): create/update reference images
flutter test --update-goldens

# Update goldens for a single file
flutter test --update-goldens test/src/widgets/primary_button_test.dart
```

> Flags can vary between SDK versions; see `flutter test --help`.

Debugging tips:

- `debugDumpApp()` inside a test prints the widget tree.
- `tester.takeException()` returns (and clears) the last exception thrown during build/layout.
- `find.byType(X).evaluate()` lists matched elements when a finder unexpectedly fails.

---

## 14. Final Checklist

- [ ] File name ends with `_test.dart` and mirrors the source path.
- [ ] Tests are grouped by widget and by state/feature.
- [ ] Test names describe user-visible behavior.
- [ ] Each test follows Arrange → Act → Assert and checks one behavior.
- [ ] Widget is wrapped with the required ancestors via a shared helper.
- [ ] All external dependencies (APIs, storage, plugins, images) are faked or mocked.
- [ ] No real network, database, or platform calls.
- [ ] Finders are user-facing or key-based; no index-based or generic layout finders.
- [ ] Loading, success, error, and empty states are covered where applicable.
- [ ] Forms cover empty, invalid, and valid submissions.
- [ ] Dialogs/bottom sheets cover open, confirm, and cancel.
- [ ] Navigation is verified by the visible destination.
- [ ] `pump()` / `pumpAndSettle()` are used correctly (no settle on infinite animations).
- [ ] No pending timers or undisposed controllers remain.
- [ ] Screen size, locale, and theme are pinned where relevant and reset afterward.
- [ ] Accessibility/semantics checked where appropriate.
- [ ] Golden tests (if any) are limited to stable visual components and generated on a consistent platform.
- [ ] No assertions on private state or implementation details.
- [ ] Tests pass with `flutter test` and with randomized ordering.
