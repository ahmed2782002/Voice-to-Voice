# Production readiness — canonical rules

**Canonical home for:** `PROD-1` … `PROD-7`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Cross-reference:** `PROD-1`'s no-PII-in-reports clause applies `SEC-2` (`security.md`) at
the crash-reporter boundary; it is not a second rule. Release-affecting changes pull the
production rows of §10 (`verification-protocol.md`) into scope regardless of diff size.

---

## 6.9 Production readiness (`PROD-*`)

**`PROD-1` 🔴 — Verify crash reporting exists before assuming it does; don't rely on a logger that
compiles out in release.**
*Required, if missing:* a crash reporter, `FlutterError.onError` and `PlatformDispatcher.onError`
wired to it, non-fatal reports for handled `Failure`s worth watching — **and no PII, tokens, or
message bodies in any report** (`SEC-2` applies here too). This is the highest-value 🔴 in this
catalog whenever it applies: every other rule prevents a bug you already know about; this one
shows you the ones you don't.

**`PROD-2` 🔴 — Verify CI actually runs on PRs before trusting "analyze is clean" as a guarantee
rather than a habit.**
```
On every PR: analyze (zero issues) · format --set-exit-if-changed ·
             test · build apk --release
```

**`PROD-3` 🔴 — More than one environment must be reachable without editing source.**
```dart
static const String baseUrl = 'https://example.nahrdev.website/api/';  // ← the failure mode
```
*Fix:* `--dart-define` with a compile-time default. *Exception:* none — never a debug flag that
could ship pointing at production.

**`PROD-4` 🔴 — Release build requirements.**
- `applicationId`/bundle id must not be `com.example.*` — decide the real one **before**
  Google/Apple OAuth clients are registered, since those bind to it.
- `--obfuscate --split-debug-info` on release, with symbols archived.
- The `INTERNET` permission belongs in the **main** manifest, not only debug/profile — an app on
  this stack has shipped without it once, and release builds had no network at all.

**`PROD-5` 🔴 — Deep links are an entry surface; validate before acting.**
```
Validate the destination and every parameter before navigating.
Never perform a side effect from a link without user confirmation.
```
*Why:* a link that resolves to a destructive action is a one-tap exploit.

**`PROD-6` 🟠 — Validate uploads (type, size) on the client whenever the backend doesn't
guarantee it.**
*Verification:* check the current backend's own docs for upload validation before assuming the
server is the only limit that matters.

**`PROD-7` 🟡 — Decide `FLAG_SECURE`/screenshot policy for sensitive screens before building
them, not after.**
