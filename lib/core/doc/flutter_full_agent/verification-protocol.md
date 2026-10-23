# Final verification protocol

**Canonical home for:** §10 (the pre-completion gate).

**Owner document:** `flutter-expert.md` — this file is the VERIFY phase of the
operating loop (§1) and the source of the "verification performed" line in every report (§11).
**Section numbers** below are the original policy's and are unchanged; the Section map in
`flutter-expert.md` resolves them to files.

**How to run it.** Scale the gate to the change (§10's own instruction), and state which rows you
skipped and why — silence is not a skip, it reads as a pass. `TEST-1` (`testing.md`) governs
what you may claim about any row you did run: a row you did not execute is never reported as green,
and a partial pass is reported as a partial pass, naming the failure. Rows that fail and cannot be
fixed inside this task's scope (§0.6) become register entries (`register.md` §9), not
omissions.

---

# 10. Final verification protocol

Before declaring a task complete, run whichever of these apply to the size and nature of the
change — and **state which ones you skipped and why**, rather than silently omitting them.

```
[ ] flutter analyze              → zero issues
[ ] flutter format                → no diff
[ ] flutter test                  → all pass; name any that don't (TEST-1)
[ ] affected-feature tests        → re-run, not just the new one
[ ] regression test for the fix   → present (TEST-2) or explicitly waived
[ ] flutter build (relevant target) → succeeds
[ ] generated code (build_runner, etc.) → regenerated if inputs changed
[ ] environment / base URL        → the intended one (PROD-3)
[ ] security-sensitive paths touched → re-checked against SEC-*
[ ] lifecycle paths touched        → re-checked against LIFE-4
[ ] localization / RTL             → checked if UI changed
[ ] accessibility                  → checked if UI changed (A11Y-*)
[ ] network failure states         → airplane mode / error path checked if network code changed
[ ] stale-request / cancellation   → checked if the change touches async list/search flows
[ ] production configuration       → checked if release-affecting files changed
```

A one-line copy fix does not need the network or lifecycle rows — say so. A change to the HTTP
client does need `NET-*` and `PROD-3` rows regardless of how small the diff looks.
