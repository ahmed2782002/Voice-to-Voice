# Unit Test Guidelines (Flutter / Dart)

> **Scope:** General-purpose, project-independent guidelines for writing unit tests in any Flutter or Dart project.
> These rules apply regardless of architecture (layered, feature-first, Clean Architecture, MVC, MVVM, etc.) and regardless of state-management solution.
> Anything tied to a specific package is explicitly marked **(optional)**.

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

A **unit test** verifies the behavior of a single unit of code — a function, method, or class — **in isolation** from its real dependencies (network, database, file system, platform channels, UI, clock, randomness).

Unit tests exist to:

- Catch regressions in business rules early and cheaply.
- Document the expected behavior of a unit in executable form.
- Enable safe refactoring: if behavior is unchanged, tests stay green.
- Provide fast feedback (milliseconds per test, the whole suite in seconds).

Unit tests form the **base of the testing pyramid**: they should be the most numerous, the fastest, and the most stable tests in a project.

| Property      | Unit test expectation                              |
| ------------- | -------------------------------------------------- |
| Speed         | Milliseconds per test                              |
| Scope         | One class / function                               |
| Dependencies  | Replaced with fakes, stubs, or mocks               |
| Environment   | Pure Dart VM, no device, no emulator, no network   |
| Determinism   | Same input → same result, every run, in any order  |

---

## 2. When to Use

Write unit tests for any code that contains **logic** — decisions, transformations, calculations, or rules.

| Unit type                        | What to verify                                                       |
| -------------------------------- | -------------------------------------------------------------------- |
| Pure Dart classes / functions    | Output for given input, including edge cases                         |
| Business logic                   | Rules, calculations, state transitions, decisions                    |
| Repositories                     | Correct delegation to data sources, mapping, error translation, caching |
| Services                         | Orchestration of dependencies, retries, error handling               |
| Use cases / interactors          | Correct calls to collaborators and correct result/failure            |
| Models                           | `fromJson` / `toJson`, equality, `copyWith`, default values          |
| Validation logic                 | Valid, invalid, boundary, empty, and null inputs                     |
| Utilities / helpers / extensions | Formatting, parsing, conversions, date/number helpers                |
| State holders (optional)         | Emitted states for given events/method calls (e.g. Cubit/Bloc, ChangeNotifier, controllers) |
| Mappers / converters             | DTO ↔ domain entity conversion                                        |

---

## 3. When NOT to Use

Do **not** use unit tests for:

- **Widget rendering and layout** → use widget tests.
- **Full user flows across screens** → use integration tests.
- **Third-party package internals** (e.g. that `http` sends a request correctly, that `json_serializable` generates valid code). Trust the library; test *your* usage of it.
- **Trivial code with no logic** (plain getters, constant declarations, simple data holders with no behavior) unless it is part of a contract such as serialization or equality.
- **Generated code** (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) directly — test the behavior that relies on it instead.
- **Private methods directly** — test them through the public API that uses them.
- **Real backends, real databases, real file systems** — that is integration territory.

---

## 4. Testing Principles

### 4.1 Arrange → Act → Assert (AAA)

Every test has three clearly separated phases:

```dart
test('returns total price including tax', () {
  // Arrange
  final calculator = PriceCalculator(taxRate: 0.14);

  // Act
  final total = calculator.totalFor(100);

  // Assert
  expect(total, 114);
});
```

- **Arrange:** create the unit under test (often called `sut`) and its dependencies; configure stubs.
- **Act:** perform **one** action — the behavior under test.
- **Assert:** verify the outcome (returned value, emitted state, thrown error, or interaction).

### 4.2 F.I.R.S.T. principles

| Principle         | Meaning                                                                 |
| ----------------- | ----------------------------------------------------------------------- |
| **Fast**          | No real I/O, no real delays, no network.                                |
| **Isolated**      | Tests never depend on each other or on shared mutable state.            |
| **Repeatable**    | Same result on every machine, every run, in any order.                  |
| **Self-validating** | Pass/fail is decided by assertions, never by reading logs.            |
| **Timely**        | Written alongside (or before) the production code.                      |

### 4.3 Behavior over implementation

- Assert **what** the unit produces, not **how** it produces it.
- Prefer checking returned values and states over verifying internal calls.
- Verify interactions (`verify(...)`) only when the interaction **is** the behavior (e.g. "saves the token", "sends analytics event", "does not call the API when cached").

### 4.4 One behavior per test

A test should fail for exactly one reason. Multiple `expect` calls are fine **if they describe the same behavior** (e.g. several fields of one parsed object).

### 4.5 Determinism

- Never depend on `DateTime.now()`, `Random()`, real timers, locale of the machine, or execution order.
- Inject clocks, random generators, and ID generators as dependencies.

---

## 5. Recommended Structure

### 5.1 Folder structure

Mirror the `lib/` directory inside `test/`. This makes tests easy to find regardless of the project's architecture.

```text
project_root/
├── lib/
│   └── src/
│       ├── models/
│       │   └── user.dart
│       ├── services/
│       │   └── auth_service.dart
│       └── utils/
│           └── email_validator.dart
└── test/
    ├── helpers/                 # shared fakes, fixtures, builders, matchers
    │   ├── fakes.dart
    │   └── fixtures/
    │       └── user.json
    └── src/
        ├── models/
        │   └── user_test.dart
        ├── services/
        │   └── auth_service_test.dart
        └── utils/
            └── email_validator_test.dart
```

Optional: some teams separate test types at the top level:

```text
test/
├── unit/
├── widget/
└── helpers/
```

Either approach is fine — **be consistent within a project**.

### 5.2 File rules

- Test files **must** end with `_test.dart` (otherwise `flutter test` ignores them).
- One test file per production file, as a default.
- Shared test utilities go in `test/helpers/` and never inside `lib/`.
- Fixtures (sample JSON, etc.) live under `test/helpers/fixtures/` or `test/fixtures/`.

### 5.3 Inside a test file

```dart
import 'package:test/test.dart'; // or: package:flutter_test/flutter_test.dart

void main() {
  group('ClassUnderTest', () {
    // shared declarations
    // setUp / tearDown

    group('methodName', () {
      test('does X when Y', () { /* ... */ });
      test('throws Z when W', () { /* ... */ });
    });
  });
}
```

> Use `package:flutter_test` when the code under test imports Flutter; use `package:test` for pure Dart packages. Both provide `test`, `group`, `expect`, and the setup/teardown functions.

---

## 6. Naming Conventions

| Item          | Convention                                   | Example                                  |
| ------------- | -------------------------------------------- | ---------------------------------------- |
| Test file     | `<source_file>_test.dart`                    | `auth_service_test.dart`                 |
| Top group     | Class or function name                       | `group('AuthService', ...)`              |
| Nested group  | Method / feature name                        | `group('login', ...)`                    |
| Test          | Behavior sentence: *does/returns/throws X when Y* | `'returns user when credentials are valid'` |
| Mock class    | `Mock` + type                                | `MockAuthApi`                            |
| Fake class    | `Fake` + type                                | `FakeAuthApi`                            |
| Unit under test | `sut` or a descriptive name                | `late AuthService sut;`                  |

**Good test names**

- `returns empty list when API returns no items`
- `throws InvalidEmailException when email has no @`
- `emits [loading, success] when fetch succeeds`

**Bad test names**

- `test1`, `works`, `login test`, `should work correctly`

The combined output of `group` + `test` should read like a sentence:
`AuthService login returns user when credentials are valid`.

---

## 7. Setup and Teardown

| Function         | Runs                                 | Use for                                               |
| ---------------- | ------------------------------------ | ----------------------------------------------------- |
| `test()`         | Defines one test case                | A single behavior                                     |
| `group()`        | Groups related tests                 | Organizing by class/method/scenario; scoping setup    |
| `setUp()`        | Before **each** test in its scope    | Creating a fresh `sut` and fresh mocks                |
| `tearDown()`     | After **each** test in its scope     | Closing streams, disposing objects, resetting state   |
| `setUpAll()`     | Once before **all** tests in scope   | Expensive, immutable setup (e.g. loading fixtures, `registerFallbackValue`) |
| `tearDownAll()`  | Once after **all** tests in scope    | Releasing resources from `setUpAll`                   |
| `addTearDown()`  | After the current test               | Cleanup declared next to the resource it cleans       |

```dart
void main() {
  late MockUserApi api;
  late UserRepository sut;

  setUpAll(() {
    // Runs once. Only for immutable / expensive setup.
  });

  setUp(() {
    // Runs before every test: fresh instances = isolated tests.
    api = MockUserApi();
    sut = UserRepository(api: api);
  });

  tearDown(() {
    sut.dispose();
  });

  tearDownAll(() {
    // Runs once after all tests.
  });

  group('UserRepository', () {
    test('...', () {});
  });
}
```

**Rules**

- Create mutable objects (mocks, `sut`, controllers) in `setUp`, **never** in `setUpAll` — shared mutable state causes order-dependent tests.
- Keep `setUp` minimal; test-specific stubbing belongs in the test's **Arrange** step.
- `setUp` in a nested `group` runs **after** the outer group's `setUp`.
- Prefer `addTearDown(resource.dispose)` right after creating a resource inside a test.

---

## 8. Mocking / Fakes

### 8.1 Test doubles

| Double    | Description                                                        | When to use                                     |
| --------- | ------------------------------------------------------------------ | ----------------------------------------------- |
| **Fake**  | Working, simplified implementation (e.g. in-memory repository)     | Default choice; readable and robust             |
| **Stub**  | Returns canned answers                                             | Controlling inputs to the unit                   |
| **Mock**  | Records calls so they can be verified                              | When the interaction itself is the behavior      |
| **Spy**   | Wraps a real object and records calls                              | Rarely needed                                    |

Prefer **fakes** for simple, stable contracts and **mocks** when you need to stub many scenarios or verify interactions.

### 8.2 Hand-written fake (no package required)

```dart
abstract interface class TokenStorage {
  Future<void> save(String token);
  Future<String?> read();
}

class FakeTokenStorage implements TokenStorage {
  String? _token;

  @override
  Future<void> save(String token) async => _token = token;

  @override
  Future<String?> read() async => _token;
}
```

### 8.3 Mockito vs Mocktail (both optional)

| Aspect              | Mockito                                        | Mocktail                                        |
| ------------------- | ---------------------------------------------- | ----------------------------------------------- |
| Code generation     | Required (`build_runner`)                      | Not required                                    |
| Stub syntax         | `when(api.get(any))`                           | `when(() => api.get(any()))`                    |
| Null safety         | Via generated classes                          | Via closures; needs `registerFallbackValue` for custom types used with `any()` |
| Setup cost          | Higher (generation step)                       | Lower                                           |
| Maintained by       | Dart team                                      | Community (Felix Angelov)                       |

Pick **one** per project and use it consistently.

**Mocktail (optional)**

```dart
import 'package:mocktail/mocktail.dart';

class MockUserApi extends Mock implements UserApi {}

void main() {
  late MockUserApi api;

  setUpAll(() {
    registerFallbackValue(const UserRequest(id: '')); // for any() on custom types
  });

  setUp(() => api = MockUserApi());

  test('stubbing and verifying', () async {
    when(() => api.fetch(any())).thenAnswer((_) async => const UserDto(id: '1'));

    await api.fetch(const UserRequest(id: '1'));

    verify(() => api.fetch(any())).called(1);
    verifyNoMoreInteractions(api);
  });
}
```

**Mockito (optional)**

```dart
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'user_repository_test.mocks.dart';

@GenerateNiceMocks([MockSpec<UserApi>()])
void main() {
  late MockUserApi api;

  setUp(() => api = MockUserApi());

  test('stubbing and verifying', () async {
    when(api.fetch(any)).thenAnswer((_) async => const UserDto(id: '1'));

    await api.fetch(const UserRequest(id: '1'));

    verify(api.fetch(any)).called(1);
  });
}
// Generate mocks: dart run build_runner build --delete-conflicting-outputs
```

**Stub cheat sheet**

| Goal                        | Mocktail                                          | Mockito                                   |
| --------------------------- | ------------------------------------------------- | ----------------------------------------- |
| Sync return                 | `.thenReturn(value)`                              | `.thenReturn(value)`                      |
| Future return               | `.thenAnswer((_) async => value)`                 | `.thenAnswer((_) async => value)`         |
| Stream return               | `.thenAnswer((_) => Stream.value(x))`             | `.thenAnswer((_) => Stream.value(x))`     |
| Throw                       | `.thenThrow(Exception())`                         | `.thenThrow(Exception())`                 |
| Never called                | `verifyNever(() => api.x())`                      | `verifyNever(api.x())`                    |

> Use `thenAnswer` (not `thenReturn`) for `Future` and `Stream` return types.

### 8.4 Avoiding real API / network calls

- The unit under test must receive its dependencies (HTTP client, API client, storage) **through its constructor or a factory** so they can be replaced.
- Never instantiate a real `http.Client`, `Dio`, database, or `SharedPreferences` inside the class under test without a way to override it.
- If an HTTP client must be exercised, use an in-memory stand-in (e.g. `MockClient` from `package:http/testing.dart`, or an adapter/interceptor for your client) — **no real sockets**.

```dart
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

final client = MockClient((request) async {
  return http.Response('{"id":"1","name":"Ann"}', 200);
});
final api = UserApi(client: client);
```

### 8.5 Dependency Injection considerations

- **Constructor injection** is the simplest and most testable form of DI. Prefer it.
- Depend on **abstractions** (abstract classes / interfaces) at boundaries (network, storage, platform).
- If the project uses a service locator or DI container, **register fakes in `setUp` and reset in `tearDown`** so tests do not leak registrations.
- Avoid global singletons and static state in business logic; if unavoidable, expose a reset hook for tests.
- Inject non-deterministic sources: clock, random, UUID generator, connectivity checker.

```dart
typedef Clock = DateTime Function();

class SessionPolicy {
  SessionPolicy({Clock? clock}) : _now = clock ?? DateTime.now;
  final Clock _now;

  bool isExpired(DateTime expiresAt) => _now().isAfter(expiresAt);
}

// Test
final policy = SessionPolicy(clock: () => DateTime(2025, 1, 1, 12));
```

---

## 9. Common Patterns

### 9.1 Pure Dart classes and utility functions

```dart
group('formatCurrency', () {
  test('formats integers with two decimals', () {
    expect(formatCurrency(10), '10.00');
  });

  test('rounds half up', () {
    expect(formatCurrency(1.005), '1.01');
  });

  test('handles zero', () {
    expect(formatCurrency(0), '0.00');
  });

  test('handles negative values', () {
    expect(formatCurrency(-5.5), '-5.50');
  });
});
```

### 9.2 Table-driven tests (many inputs, same behavior)

```dart
group('EmailValidator.isValid', () {
  const cases = <String, bool>{
    'user@example.com': true,
    'user.name+tag@example.co': true,
    '': false,
    'user': false,
    'user@': false,
    '@example.com': false,
    'user@example': false,
    ' user@example.com ': false,
  };

  cases.forEach((input, expected) {
    test('returns $expected for "$input"', () {
      expect(EmailValidator.isValid(input), expected);
    });
  });
});
```

### 9.3 Validation logic (null / empty / invalid / boundary)

```dart
group('PasswordValidator.validate', () {
  test('returns error when value is null', () {
    expect(PasswordValidator.validate(null), PasswordError.required);
  });

  test('returns error when value is empty', () {
    expect(PasswordValidator.validate(''), PasswordError.required);
  });

  test('returns error when shorter than 8 characters', () {
    expect(PasswordValidator.validate('Ab1234!'), PasswordError.tooShort);
  });

  test('returns null at exactly 8 valid characters (boundary)', () {
    expect(PasswordValidator.validate('Ab12345!'), isNull);
  });
});
```

### 9.4 Models: serialization / deserialization / equality

```dart
group('User', () {
  const json = {'id': '1', 'name': 'Ann', 'email': 'ann@example.com'};
  const user = User(id: '1', name: 'Ann', email: 'ann@example.com');

  test('fromJson creates a valid model', () {
    expect(User.fromJson(json), user);
  });

  test('toJson returns the expected map', () {
    expect(user.toJson(), json);
  });

  test('round trip keeps data intact', () {
    expect(User.fromJson(user.toJson()), user);
  });

  test('fromJson handles missing optional fields', () {
    final result = User.fromJson(const {'id': '1', 'name': 'Ann'});
    expect(result.email, isNull);
  });

  test('fromJson throws when a required field is missing', () {
    expect(() => User.fromJson(const {'name': 'Ann'}), throwsA(isA<TypeError>()));
  });

  test('copyWith changes only the given fields', () {
    final updated = user.copyWith(name: 'Bob');
    expect(updated.name, 'Bob');
    expect(updated.id, user.id);
  });
});
```

> The exact exception type for missing fields depends on how deserialization is implemented. Assert the type your code **documents**; if your code converts errors to a domain exception, assert that instead.

Loading a JSON fixture (optional helper):

```dart
import 'dart:convert';
import 'dart:io';

Map<String, dynamic> fixture(String name) =>
    jsonDecode(File('test/helpers/fixtures/$name').readAsStringSync())
        as Map<String, dynamic>;
```

### 9.5 Repositories

Verify mapping, error translation, and caching — not the data source itself.

```dart
group('UserRepository.getUser', () {
  test('returns mapped domain user on success', () async {
    when(() => api.fetchUser('1'))
        .thenAnswer((_) async => const UserDto(id: '1', fullName: 'Ann'));

    final result = await sut.getUser('1');

    expect(result, const User(id: '1', name: 'Ann'));
  });

  test('throws UserNotFoundException when API returns 404', () async {
    when(() => api.fetchUser('1')).thenThrow(const ApiException(statusCode: 404));

    expect(() => sut.getUser('1'), throwsA(isA<UserNotFoundException>()));
  });

  test('returns cached user without calling API on second request', () async {
    when(() => api.fetchUser('1'))
        .thenAnswer((_) async => const UserDto(id: '1', fullName: 'Ann'));

    await sut.getUser('1');
    await sut.getUser('1');

    verify(() => api.fetchUser('1')).called(1);
  });
});
```

### 9.6 Services and use cases

```dart
group('PlaceOrder', () {
  test('charges payment then saves order when cart is valid', () async {
    when(() => payments.charge(any())).thenAnswer((_) async => const PaymentId('p1'));
    when(() => orders.save(any())).thenAnswer((_) async {});

    final result = await sut(cart);

    expect(result.isSuccess, isTrue);
    verifyInOrder([
      () => payments.charge(any()),
      () => orders.save(any()),
    ]);
  });

  test('does not save order when payment fails', () async {
    when(() => payments.charge(any())).thenThrow(PaymentDeclined());

    final result = await sut(cart);

    expect(result.isFailure, isTrue);
    verifyNever(() => orders.save(any()));
  });

  test('returns failure immediately when cart is empty', () async {
    final result = await sut(Cart.empty());

    expect(result.isFailure, isTrue);
    verifyNoMoreInteractions(payments); // no calls were made to payments
  });
});
```

### 9.7 Success, failure, exceptions, and edge cases

For every non-trivial unit, cover at least:

| Category       | Examples                                                             |
| -------------- | -------------------------------------------------------------------- |
| Success        | Valid input, expected output                                         |
| Failure        | Dependency error, invalid state, business rule violation             |
| Exceptions     | Correct exception **type** (and message/code if part of the contract) |
| Edge cases     | Zero, negative, max values, boundaries (n-1, n, n+1)                 |
| Null / empty   | `null`, `''`, `[]`, `{}`, whitespace-only strings                    |
| Invalid values | Malformed JSON, wrong types, unexpected enum values                  |

Exception assertions:

```dart
// Synchronous
expect(() => parseAge('abc'), throwsFormatException);
expect(() => parseAge('-1'), throwsA(isA<ArgumentError>()));

// With details
expect(
  () => parseAge('-1'),
  throwsA(isA<ArgumentError>().having((e) => e.name, 'name', 'age')),
);

// Asynchronous
await expectLater(sut.load(), throwsA(isA<NetworkException>()));
```

> For sync code, wrap the call in a closure `() => ...`. For async code, pass the `Future` itself and `await expectLater(...)`.

### 9.8 Asynchronous code: Futures

```dart
test('returns data asynchronously', () async {
  when(() => api.fetch()).thenAnswer((_) async => 42);

  final result = await sut.load();

  expect(result, 42);
});

test('completes with value', () {
  expect(sut.load(), completion(42));
});
```

- Always `await` or return the Future; otherwise the test may finish before the assertion runs.
- Never use real `Future.delayed` to "wait" in unit tests.

### 9.9 Asynchronous code: Streams

```dart
test('emits values in order then closes', () {
  final stream = sut.countdown(from: 3);

  expect(stream, emitsInOrder([3, 2, 1, 0, emitsDone]));
});

test('emits error when source fails', () {
  when(() => source.watch()).thenAnswer((_) => Stream.error(Exception('boom')));

  expect(sut.watch(), emitsError(isA<Exception>()));
});

test('emits updates pushed to controller', () async {
  final controller = StreamController<int>();
  addTearDown(controller.close);
  when(() => source.watch()).thenAnswer((_) => controller.stream);

  final future = expectLater(sut.watchDoubled(), emitsInOrder([2, 4]));
  controller
    ..add(1)
    ..add(2);

  await future;
});
```

Useful stream matchers: `emits`, `emitsInOrder`, `emitsInAnyOrder`, `emitsThrough`, `emitsError`, `emitsDone`, `neverEmits`, `mayEmit`.

### 9.10 Time-dependent code (optional: `fake_async`)

```dart
import 'package:fake_async/fake_async.dart';

test('debouncer fires once after delay', () {
  fakeAsync((async) {
    var calls = 0;
    final debouncer = Debouncer(const Duration(milliseconds: 300));

    debouncer.run(() => calls++);
    debouncer.run(() => calls++);
    async.elapse(const Duration(milliseconds: 299));
    expect(calls, 0);

    async.elapse(const Duration(milliseconds: 1));
    expect(calls, 1);
  });
});
```

Alternatively, inject a clock/timer abstraction and control it from the test.

### 9.11 Error handling

Test that errors are **caught, translated, and surfaced** as designed:

```dart
test('maps SocketException to NoConnectionFailure', () async {
  when(() => api.fetch()).thenThrow(const SocketException('offline'));

  final result = await sut.load();

  expect(result, const Result<int>.failure(NoConnectionFailure()));
});

test('logs unexpected errors and rethrows', () async {
  when(() => api.fetch()).thenThrow(StateError('unexpected'));

  await expectLater(sut.load(), throwsStateError);
  verify(() => logger.error(any(), any())).called(1);
});
```

### 9.12 State holders (Cubit / Bloc / ChangeNotifier / controllers) — when appropriate

Only applicable if the project uses such classes. Test them as units: given an initial state and an action, verify the resulting state(s).

**Generic approach (any state holder)**

```dart
test('increment updates value and notifies listeners', () {
  final controller = CounterController();
  addTearDown(controller.dispose);
  var notified = 0;
  controller.addListener(() => notified++);

  controller.increment();

  expect(controller.value, 1);
  expect(notified, 1);
});
```

**Cubit / Bloc with `bloc_test` (optional)**

```dart
import 'package:bloc_test/bloc_test.dart';

blocTest<ProfileCubit, ProfileState>(
  'emits [loading, loaded] when load succeeds',
  setUp: () {
    when(() => repository.getProfile()).thenAnswer((_) async => profile);
  },
  build: () => ProfileCubit(repository),
  act: (cubit) => cubit.load(),
  expect: () => [const ProfileState.loading(), ProfileState.loaded(profile)],
  verify: (_) => verify(() => repository.getProfile()).called(1),
);

blocTest<ProfileCubit, ProfileState>(
  'emits [loading, error] when load fails',
  setUp: () {
    when(() => repository.getProfile()).thenThrow(Exception());
  },
  build: () => ProfileCubit(repository),
  act: (cubit) => cubit.load(),
  expect: () => [const ProfileState.loading(), isA<ProfileError>()],
);
```

Useful `blocTest` parameters: `seed` (start state), `wait` (debounce), `skip` (ignore first N states), `errors` (expected errors).

Without `bloc_test`, use stream matchers:

```dart
test('emits loading then loaded', () {
  final cubit = ProfileCubit(repository);
  addTearDown(cubit.close);

  expectLater(cubit.stream, emitsInOrder([isA<ProfileLoading>(), isA<ProfileLoaded>()]));
  cubit.load();
});
```

### 9.13 Avoiding flaky tests

| Cause of flakiness                  | Fix                                                       |
| ----------------------------------- | --------------------------------------------------------- |
| `DateTime.now()`                    | Inject a clock                                            |
| `Random()` / UUIDs                  | Inject a seeded generator or ID provider                  |
| Real delays / timers                | `fake_async` (optional) or injected scheduler              |
| Shared mutable state between tests  | Create fresh objects in `setUp`; reset singletons         |
| Test order dependency               | Run with `--test-randomize-ordering-seed random`           |
| Real network / file system          | Fakes / mocks / in-memory implementations                  |
| Machine locale / timezone           | Pass explicit locale; use UTC dates in assertions          |
| Floating-point equality             | `closeTo(expected, delta)`                                 |
| Unordered collections               | `unorderedEquals([...])`                                   |
| Unawaited Futures                   | Always `await` / `expectLater`                             |

---

## 10. Examples

### 10.1 Good vs bad

**❌ Bad: vague name, real dependency, multiple behaviors, no isolation**

```dart
final repo = UserRepository(api: UserApi(client: http.Client())); // real network, shared

test('user test', () async {
  final user = await repo.getUser('1');            // hits real server
  expect(user != null, true);                     // weak assertion
  await repo.updateName('1', 'Bob');              // second behavior in same test
  expect((await repo.getUser('1')).name, 'Bob');  // depends on server state
});
```

Problems: network dependent, non-deterministic, shared state, weak assertions, unclear intent.

**✅ Good: isolated, deterministic, one behavior, descriptive**

```dart
void main() {
  late MockUserApi api;
  late UserRepository sut;

  setUp(() {
    api = MockUserApi();
    sut = UserRepository(api: api);
  });

  group('UserRepository', () {
    group('getUser', () {
      test('returns mapped user when API succeeds', () async {
        // Arrange
        when(() => api.fetchUser('1'))
            .thenAnswer((_) async => const UserDto(id: '1', fullName: 'Ann'));

        // Act
        final user = await sut.getUser('1');

        // Assert
        expect(user, const User(id: '1', name: 'Ann'));
      });
    });

    group('updateName', () {
      test('sends trimmed name to API', () async {
        when(() => api.patchName(any(), any())).thenAnswer((_) async {});

        await sut.updateName('1', '  Bob  ');

        verify(() => api.patchName('1', 'Bob')).called(1);
      });

      test('throws ArgumentError when name is blank', () {
        expect(() => sut.updateName('1', '   '), throwsArgumentError);
        verifyNever(() => api.patchName(any(), any()));
      });
    });
  });
}
```

### 10.2 Good vs bad assertions

| ❌ Bad                                   | ✅ Good                                              |
| --------------------------------------- | --------------------------------------------------- |
| `expect(result != null, true);`         | `expect(result, isNotNull);`                         |
| `expect(list.length == 2, isTrue);`     | `expect(list, hasLength(2));`                        |
| `expect(error is MyError, true);`       | `expect(error, isA<MyError>());`                     |
| `expect(price, 0.30000000000000004);`   | `expect(price, closeTo(0.3, 1e-9));`                 |
| `try { f(); fail(''); } catch (_) {}`   | `expect(() => f(), throwsA(isA<MyError>()));`        |
| `expect(result.toString(), 'User(1)');` | `expect(result, const User(id: '1'));`               |

---

## 11. Common Mistakes

1. **Hitting real APIs, databases, or files** — makes tests slow and flaky.
2. **Forgetting `await`** — the test passes before the assertion runs.
3. **Using `thenReturn` for Futures/Streams** — use `thenAnswer`.
4. **Creating mocks in `setUpAll`** — leaks stubs/verifications between tests.
5. **Testing private methods or internal fields** — couples tests to implementation.
6. **Over-verifying** — `verify` on every call makes refactoring painful.
7. **Only testing the happy path** — failures and edge cases are where bugs live.
8. **Relying on `DateTime.now()` or `Random()`** — non-deterministic results.
9. **Huge tests with many acts** — hard to diagnose when they fail.
10. **Copy-pasted setup everywhere** — extract builders/helpers into `test/helpers/`.
11. **Asserting on `toString()` output** — brittle; compare values or fields.
12. **Mocking value objects/models** — use real instances; mock only collaborators.
13. **Chasing 100% coverage with meaningless tests** — coverage measures execution, not correctness.
14. **Not closing StreamControllers / disposing objects** — leaks and "pending timer" failures.
15. **Leaving `print` debugging or commented-out tests** — clean up before committing.

---

## 12. Do / Don't Rules

| ✅ Do                                                         | ❌ Don't                                                   |
| ------------------------------------------------------------ | --------------------------------------------------------- |
| Follow Arrange → Act → Assert                                | Mix multiple unrelated behaviors in one test              |
| Name tests as behavior sentences                             | Use names like `test1` or `works`                          |
| Create fresh objects in `setUp`                              | Share mutable state across tests                          |
| Inject dependencies through constructors                     | Instantiate real clients inside business classes          |
| Mock/fake boundaries (network, storage, platform, clock)     | Mock the class under test or simple data models           |
| Cover success, failure, exceptions, edge, null/empty cases   | Test only the happy path                                   |
| Use precise matchers (`isA`, `hasLength`, `closeTo`, `emitsInOrder`) | Use `expect(x == y, true)`                          |
| `await` every Future; use `expectLater` for async matchers   | Leave Futures unawaited                                    |
| Keep tests fast (ms) and deterministic                       | Use real delays or real time                              |
| Keep test helpers in `test/helpers/`                         | Put test-only code in `lib/`                               |
| Label optional packages and use one mocking library consistently | Mix Mockito and Mocktail in the same project          |
| Treat tests as production code (readable, reviewed)          | Commit skipped, commented-out, or flaky tests              |

---

## 13. How to Run the Tests

### 13.1 Basic commands

```bash
# Run all tests under test/
flutter test

# Pure Dart package (no Flutter dependency)
dart test

# Run a folder
flutter test test/unit

# Run a single file
flutter test test/src/services/auth_service_test.dart

# Run a single test / group by name (regex)
flutter test --name "returns user when credentials are valid"

# Run by exact (non-regex) name
flutter test --plain-name "AuthService login"

# Verbose, one line per test
flutter test -r expanded

# Detect order dependency
flutter test --test-randomize-ordering-seed random

# Stop at the first failure (useful locally)
flutter test --fail-fast
```

> Available flags can vary slightly between Flutter/Dart SDK versions. Run `flutter test --help` to see what your SDK supports.

### 13.2 Tags (optional)

```dart
@Tags(['slow'])
library;

import 'package:test/test.dart';
```

```bash
flutter test --tags slow
flutter test --exclude-tags slow
```

### 13.3 Code coverage

```bash
# Generate lcov report (coverage/lcov.info)
flutter test --coverage

# Optional: HTML report (requires lcov installed on the machine)
genhtml coverage/lcov.info -o coverage/html
# Open coverage/html/index.html
```

Coverage guidance:

- Use coverage to **find untested logic**, not as the goal itself.
- Focus on business logic, validation, mapping, and error-handling paths.
- Exclude generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) from coverage reports if your tooling supports it.
- A reasonable team target for business-logic layers is often 80%+; UI and generated code usually have lower targets. Agree on thresholds per project.

### 13.4 Generating mocks (only if using Mockito)

```bash
dart run build_runner build --delete-conflicting-outputs
```

---

## 14. Final Checklist

Before considering a unit test (or test file) complete:

- [ ] File name ends with `_test.dart` and mirrors the source path.
- [ ] Tests are grouped by class and method using `group()`.
- [ ] Each test name describes a behavior (*does X when Y*).
- [ ] Each test follows Arrange → Act → Assert.
- [ ] Each test verifies **one** behavior.
- [ ] The unit is isolated: no real network, database, file system, platform channel, or UI.
- [ ] Dependencies are injected and replaced with fakes/stubs/mocks.
- [ ] Mutable objects are created in `setUp`, not `setUpAll`.
- [ ] Resources are cleaned up (`tearDown` / `addTearDown`).
- [ ] Success cases are covered.
- [ ] Failure cases and error handling are covered.
- [ ] Exceptions are asserted by type (and details when part of the contract).
- [ ] Edge cases, boundaries, null, empty, and invalid values are covered.
- [ ] Async code is awaited; Streams use stream matchers.
- [ ] No dependence on real time, randomness, locale, or test order.
- [ ] Assertions use precise matchers.
- [ ] `verify` is used only where the interaction is the behavior.
- [ ] Optional packages (Mockito, Mocktail, bloc_test, fake_async) are used consistently and only if the project has adopted them.
- [ ] Tests pass locally with `flutter test` and with `--test-randomize-ordering-seed random`.
- [ ] No skipped, commented-out, or `print`-debugging code remains.
