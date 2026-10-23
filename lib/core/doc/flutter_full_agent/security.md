# Security & data integrity — canonical rules

**Canonical home for:** `SEC-1` … `SEC-9`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Precedence note:** every `SEC-*` rule sits at position 1 of the precedence order (§0.3) — it
outranks the task itself. A `SEC-*` violation sitting in code your task already touches is the
one exception to change-scope control (§0.6).

---

## 6.1 Security & data integrity (`SEC-*`)

**`SEC-1` 🔴 — Tokens in secure storage only, never in general prefs/shared-storage.**
*Why:* general prefs are not encrypted at rest and are backed up more permissively on most
platforms. *Exception:* none. *Verification:* grep the token-handling code path for anywhere it
writes outside the secure-storage module.

**`SEC-2` 🔴 — Never log a token, password, OTP code, or message body.**
*Why:* logs routinely leave the device (crash reports, log aggregation) and are not a secure
channel. *Exception:* none, including in debug-only logging — a debug log has shipped to
production before on this stack via a missed build flag.

**`SEC-3` 🔴 — Never send a credential anywhere the user did not explicitly ask for.**
*Exception:* none.

**`SEC-4` 🔴 — Never trust a client-side gate as security; say in the PR where the server must
enforce it.**
*Why:* a disabled button, a hidden route, or a client-only permission check can always be
bypassed by calling the endpoint directly. *Exception:* none — this is true even when the UI gate
is also correct and necessary for UX.

**`SEC-5` 🔴 — `Either<Failure, T>`, never `Either<String, T>`, never a thrown string.**
*Why:* a closed `Failure` type lets the compiler enforce exhaustive handling; a string does not.

**`SEC-6` 🔴 — No `dynamic` in the network or model layers.**
*Verification:* enforced by the `avoid_dynamic_calls` analyzer rule (§7) — this should be a build
failure, not a review comment.

**`SEC-7` 🔴 — A status carrying no body is a failure. Never parse `{}` into a model the caller
will act on.**
*Why:* see `§4.1` for the full failure chain this prevents. `''` is as bodiless as `null` — many
HTTP clients return `''` for a zero-length payload. *Exception:* none. *Verification:* for any
new or touched parser, ask explicitly "what does this produce on an empty body, and who acts on
it?" and write the answer down if it isn't obviously safe.

**`SEC-8` 🔴 — Never compute a distance, price, or entitlement on the client from raw inputs.**
*Why:* these are exactly the values a modified client can falsify; they must be server-computed
and merely displayed.

**`SEC-9` 🔴 — `context.mounted` after every `await` in a widget, before touching that context.**
```dart
onTap: () async {
  final ok = await showDialog<bool>(...);
  if (!context.mounted) return;      // ← the missing line
  if (ok == true) Navigator.pop(context);
}
```
*Why:* prevents `Looking up a deactivated widget's ancestor is unsafe` — a failure that only
shows up when the user acts faster than the network, so it rarely appears in manual testing.
*Exception:* none; if the `context` comes from a fresher `builder`, say so in a comment rather
than treating it as exempt. *Verification:* enforced by `use_build_context_synchronously` (§7).
*Note:* this is the same rule wherever a `BuildContext` in a widget survives an `await` — do not
restate it as a separate "widget rule"; the cubit/repo/service equivalent is `ARCH-3`.
