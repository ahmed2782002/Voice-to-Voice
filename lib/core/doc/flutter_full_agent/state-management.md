# State management (Cubit) — canonical rules

**Canonical home for:** `STATE-1` … `STATE-7`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Adjacent canonical homes:** cubit registration lifetime is `ARCH-1` (`architecture.md`);
never storing `BuildContext` in a cubit is `ARCH-3`; the widget-lifecycle rules that decide when
a cubit is the wrong tool at all are `LIFE-3`/`LIFE-4` (`lifecycle.md`); cancellation of
superseded requests is `NET-3` (`networking.md`).

---

## 6.6 State management (`STATE-*`)

**`STATE-1` 🟠 — `isClosed` before every `emit` that follows an `await`.**
*Note:* the check is specifically for an `emit` **after** an await, not every await — an await
that emits nothing doesn't need it.

**`STATE-2` 🟠 — Use the guarded emit helper (e.g. `safeEmit`) — never a raw `emit` that skips
it.**

**`STATE-3` 🟠 — `clearError: true` when a request starts.**
*Exception:* a silent background refresh must not clear an error the user still needs to see.

**`STATE-4` 🟠 — Every disposable is released; controllers live in the cubit, disposed in
`close()`.**
*Exception:* a controller for local widget state (scroll offset, focus) belongs in the `State`,
not the cubit. *Trap:* a cubit registered as a singleton (violating `ARCH-1`) outlives the screen
and its controllers with it.

**`STATE-5` 🔴 — Model the legal states you can be in; don't combine booleans that allow illegal
combinations.**
*Why:* three independent `bool`s allow eight combinations when usually only some are legal.
Prefer one field with a closed set of values and let the compiler reject the rest.

**`STATE-6` 🟠 — Stale results must not win.**
*Why:* every async result should answer two questions before it's emitted: is this cubit still
open (`isClosed`, `STATE-1`), and is this still the request the user wants (a sequence number or
a cancel token, `NET-3`)? `STATE-1` alone only covers the first.

**`STATE-7` 🟠 — Optimistic updates carry their rollback in the same commit as the optimistic
path.**
*Why:* a rollback added later tends never to get added — write it at the same time as the
optimistic replace/call.
