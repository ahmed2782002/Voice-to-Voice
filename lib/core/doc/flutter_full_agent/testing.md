# Testing, evidence & evidence governance — canonical rules

**Canonical home for:** `TEST-1` … `TEST-5`, plus the evidence taxonomy and testing governance (§8)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Enforcement of `TEST-1`** happens at report time under §11 (`flutter-expert.md`) and at
gate time under §10 (`verification-protocol.md`). Neither of those restates the rule —
both cite it.

---

## 6.7 Testing & evidence (`TEST-*`) — see §8 for the full evidence taxonomy

**`TEST-1` 🔴 — Never report "fixed" without one of: a real API response copied verbatim, a
passing test, or `git stash` proving the failure pre-dates your change.**
*Also:* never report a partial pass as a full pass — "9 passing, 1 failing" is reported as
exactly that, naming the failure, even when it predates your change.

**`TEST-2` 🔴 — A fixed bug ships with a test.**
*Why:* a bug whose cause you can state precisely is the cheapest possible test to write — you
already know the input and the wrong output. *Exception:* a purely visual defect (a colour, a
gap) — use a golden test if the harness exists, otherwise say so in one line rather than skipping
silently.

**`TEST-3` 🟠 — Mock HTTP, storage, clock, and platform channels. Never mock the mapper (it's the
thing under test), `Failure`, or your own models.**
*Why:* an incomplete mock is a green test guarding something else entirely — on a past project, a
`500`-with-empty-body test passed for the wrong reason until connectivity was mocked, because the
base repository was returning a network failure before the request even went out.

**`TEST-4` 🟠 — Cubit tests assert the sequence, not the endpoint.**
```
Assert: state order · isClosed honoured after await · clearError on start ·
        rollback on failure · no duplicate emit for one action
```

**`TEST-5` 🟡 — Golden tests for any widget shared across more than one screen.**
*Why:* a layout defect that covers content (`§4.2`) is exactly the class a golden catches on the
first run.

---

# 8. Testing & evidence governance

A claim of "fixed," "passing," or "verified" is only as good as the evidence behind it. Use the
right evidence type for what changed — don't force a unit test where a real API check is what's
actually needed, and don't accept a unit test where only a live check would do.

| Evidence type | Appropriate for |
|---|---|
| Unit test | Pure logic: mappers, formatters, calculations |
| Cubit/state test | State sequences, `isClosed` handling, rollback (`TEST-4`) |
| Mapper test | DTO↔Model correctness (`ARCH-7`) — never mock the thing under test |
| Repository/network test | Envelope parsing, failure mapping, empty-body handling (`SEC-7`) |
| Widget test | Interaction and rendering logic that doesn't need a real backend |
| Golden test | Shared visual components (`TEST-5`) |
| Integration test | Cross-cubit / cross-screen flows |
| Real API verification | Anything whose correctness depends on live backend behavior (§5) |
| Isolation proof (`git stash`, minimal repro) | Establishing a failure pre-dates your change |

**A green test is not evidence if its setup bypasses the behavior under test** (`TEST-3`) — check
that the mock actually exercises the path you think it does, not a shortcut around it. Do not
require an evidence type that doesn't fit what changed (a visual-only tweak doesn't need a cubit
test); do state, explicitly, when you're deliberately skipping one (`TEST-2`'s exception).
