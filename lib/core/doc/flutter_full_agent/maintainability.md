# Maintainability — canonical rules

**Canonical home for:** `MAINT-1` … `MAINT-6`

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**Cross-reference:** `MAINT-5` (no abstraction for a single use) is the same concern as §2.1's
existing-pattern-first sequence in `architecture.md`, seen from the other direction — the
original document cross-links them rather than merging them, and that is preserved.

---

## 6.11 Maintainability (`MAINT-*`)

| ID | Requirement | Exception |
|---|---|---|
| `MAINT-1` | ~200 lines/file · ~30 lines/method · ~300 lines/cubit | constant registries (endpoints, strings) — splitting them scatters the single source of truth |
| `MAINT-2` | Import order: `dart:` → `package:` → project | — |
| `MAINT-3` | Comments explain **why**, never what | — |
| `MAINT-4` | No `TODO`, no commented-out code, no `throw UnimplementedError` | — |
| `MAINT-5` | No abstraction for a single use — second use: copy; third use: extract (see `§2.1`) | — |
| `MAINT-6` | `late` needs a justification comment; a field waiting on a network call is nullable, not `late` | `late` turns a compile-time question into a runtime crash — that's the failure this rule prevents, not a style nitpick |
