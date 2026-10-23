# Widget, context & lifecycle — canonical rules

**Canonical home for:** `LIFE-1` … `LIFE-5`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Note on `LIFE-1`:** it is a pointer, not a duplicate. The requirement is defined once as `SEC-9`
in `security.md`; `ARCH-3` (`architecture.md`) is the cubit/repository/service side of
the same concern. This preserves the original document's own treatment of the rule.

---

## 6.3 Widget, context & lifecycle (`LIFE-*`)

**`LIFE-1` — see `SEC-9`.** (No separate widget-vs-cubit split for this rule; the requirement is
identical, only the object holding the stale context differs.)

**`LIFE-2` 🟠 — Scope `MediaQuery` reads.**
```dart
MediaQuery.of(context).size    // rebuilds on keyboard, rotation, font scale, insets
MediaQuery.sizeOf(context)     // rebuilds only when the size itself changes
```
*Why:* an unscoped read on a screen with a `TextField` rebuilds the whole subtree on every
keyboard open/close. *Exception:* needing four or more `MediaQuery` fields — then `.of` is
clearer than four scoped calls.

**`LIFE-3` 🟠 — `StatefulWidget` for state that belongs to one widget and dies with it (open/
closed, animation, focus, scroll offset); a Cubit for state read elsewhere or that survives the
screen.**
*Why:* a blanket "screens are `StatelessWidget`" rule doesn't say when a cubit is overkill — the
failure mode of following it too literally is a cubit, a state class, and a DI registration for
one `bool`.

**`LIFE-4` 🟠 — Handle app lifecycle explicitly for anything live: open sockets, session TTLs,
counters that can go stale.**
```
paused   → close sockets, cancel timers, stop location work
resumed  → reconnect, revalidate the token, refresh counters
detached → release native resources
```
*Why:* prevents an app returning after a background spell with a dead socket and stale counters,
**showing no sign it's disconnected** — plus a background timer retrying with an expired token.
*Exception:* a screen with nothing live may ignore lifecycle entirely; say so rather than adding
an empty observer.

**`LIFE-5` 🟡 — `PopScope` on any screen holding unsaved input.**
*Exception:* never on a read-only screen — it turns back into a confirmation prompt for nothing.
