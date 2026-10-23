# Feature workflow

**What this is.** The standard route for delivering a whole feature. It is the §1 agent operating
loop — unchanged, same phases, same order, same names — with the extra gates a feature needs that a
one-line fix does not.

**Owner document:** `flutter-expert.md` — §1 defines the phases, their allowed
actions, their forbidden assumptions, and their outputs. **This file does not restate §1's table.**
Read §1 first; this file adds to it. Section numbers below are the original policy's; the Section map
in the owner document resolves them to files.

**When to use it.** Any new feature, any feature-sized change, anything that adds a screen, a cubit,
a repository method, or a backend contract. For a small fix, run §1 directly and skip this file —
saying so in the report (§1's rule about stating skipped phases applies to skipping this workflow
too).

```
UNDERSTAND → INSPECT → MEASURE → MAP → DECIDE → IMPLEMENT → TEST → VERIFY
           → UPDATE REGISTER → REPORT
```

Two gates sit inside that loop for a feature and cannot be reordered out of it: **API verification
happens before any model or repository is written** (inside INSPECT/MAP), and **review happens
before the final report** (after TEST/VERIFY). Everything else below hangs off a phase you already
know.

---

## UNDERSTAND — requirements & acceptance criteria

**Requirements.** State what the feature actually has to do, in the terms the user of the app would
recognise. Behavior, inputs, states, edge cases, what is explicitly out of scope. If the ask is
genuinely ambiguous, ask — an ambiguous ask does not have one obvious reading (§1).

**Acceptance criteria — written before implementation, not after.** Explicit, checkable, and each one
traceable to a phase that will produce evidence for it. Include the ones features on this stack
routinely forget:

- Every data-bearing screen has its four states: loading · empty · error+retry · content (`A11Y-3`).
- Error and empty are visually distinguishable from each other (`A11Y-3`).
- The failure path is specified, not just the happy path: no network, expired token, 403 vs 401
  (`NET-6`), empty body (`SEC-7`).
- Behavior in RTL is stated, because RTL is the default and not a mode (`A11Y-5`).
- Behavior at 200% font scale is stated (`A11Y-1`).
- Anything the client gates is named alongside where the server must also enforce it (`SEC-4`).
- Any value the user could benefit from falsifying is server-computed (`SEC-8`).

Criteria you cannot get evidence for are not acceptance criteria — rewrite them until you can (§8).

**Output:** the one-line restatement §1 asks for, plus the requirement list and the acceptance
criteria.

## INSPECT — existing code discovery

Run §2 (`architecture.md`) against this repository, and read `PROJECT.md` before anything else.

**Find the reusable implementation before creating a new one.** §2.1's sequence is the rule: search
for the concern, search for it under a *different* name, read the actual content, reuse, extend, and
only then create — stating why (§2.1, `MAINT-5`). For a feature, the concerns to search for
specifically are the base repository, the base cubit, the base state, the paginated base (`ARCH-4`),
the shared remote-image widget (`STYLE-7`), the toast path (`STYLE-8`), the endpoint constants
(`STYLE-5`), and the DI module (`ARCH-1`).

**Verify content, not filenames** (§2.2). A matching name is not evidence of matching behavior — this
has produced a false "doesn't exist" on this stack before (§12).

**A "nothing exists" conclusion is a negative claim** and needs a search wide enough to support it
(§0.5). One narrow grep is not that search (§12).

**Output:** the concrete files and symbols the feature will touch, plus a reuse inventory.

## MEASURE — only what this feature touches

Run the §3 rows that are relevant (`architecture.md`), scoped to what the feature actually
changes. A feature adding a server-driven list needs the `ListView`/`SingleChildScrollView`,
`CancelToken`, and image-decode rows; it does not need every row in the table. A stale baseline is
worse than none (§3).

**Output:** the numbers, and what they imply for the design.

## MAP — API verification & reuse decision

**API verification is a gate, not a step.** Before any DTO, model, mapper, repository method, or
endpoint constant is written, run `api-investigator.md` and get back a report whose facts are
labelled `VERIFIED` / `ASSUMPTION` / `UNKNOWN` / `BLOCKED` under §5 (`networking.md`).

- Build on `VERIFIED`.
- Build on an `ASSUMPTION` only by carrying the label into the code (a comment where it is relied on)
  and into the final report.
- Do not build on `UNKNOWN` or `BLOCKED` (§0.4). Report the blocker and stop that branch of the work
  — a `BLOCKED` contract becomes a register entry (§9), not a guess.

Backend "done" is a hypothesis until the live API agrees (§4.6). This applies to the mobile team's
own claims too.

**Reuse decision.** Close §2.1 explicitly: reuse / extend / create-new for each concern, with the
reason. A create-new with no stated reason is a finding in review.

**Output:** the labelled API contract, and the reuse/extend/create-new verdict per concern.

## DECIDE — architecture plan

Write the plan before writing the code. It contains, at minimum:

1. **Files to change** — each with the reason it must change.
2. **Files to create** — each with the reason nothing existing covers it (§2.1, `MAINT-5`).
3. **Existing code to reuse** — named, with the file, so the reviewer can check it was actually used.
4. **Why this approach is correct** — the constraint that decides it, and the rule IDs it satisfies.
5. **Rule IDs in scope** — the ones this feature must be checked against at VERIFY time.
6. **Data flow** — DTO → Model → Mapper boundaries (`ARCH-7`), which layer owns which shape.
7. **State design** — the legal states, modelled as legal states rather than as combinable booleans
   (`STATE-5`); the cubit's registration lifetime (`ARCH-1`); what is widget-local instead
   (`LIFE-3`).
8. **Async design** — what is cancellable (`NET-3`), what is single-flight (`NET-4`), what must not
   retry (`NET-2`'s 🔴 sub-rule), whether each mutating call is idempotent (`NET-5`), how stale
   results are prevented from winning (`STATE-6`), and where the rollback for any optimistic update
   lives (`STATE-7`).
9. **Failure design** — prefer the loud failure (§4.5): what the user sees, and what the logs and
   crash reporter get without PII (`SEC-2`, `PROD-1`).
10. **Exceptions being invoked** — each answered against all four §0.7 questions.
11. **Anything deliberately left alone** — pre-existing violations the feature will not fix (§0.6),
    which become register candidates rather than drive-by edits.

Use §4 (`engineering-knowledge.md`) for anything resembling a known failure class — as a
decision template only, and never inferring a cause from symptom similarity (§4's governing rule).

**Output:** the plan. It is also the document the reviewer checks the diff against.

## IMPLEMENT — after discovery and planning, not before

Write the code the plan describes, against the rule files in scope. Follow the repository's existing
pattern where it conflicts with this policy, and open a register entry for the conflict rather than
forking a competing pattern (§0.3).

Stay inside the change scope: the requested change and the supporting changes it requires. Unrelated
cleanup gets mentioned in the report, not performed — the single exception being a `SEC-*` (🔴)
violation sitting in code the feature already touches (§0.6).

If implementation reveals the plan was wrong, say so and update the plan. A plan quietly abandoned
mid-implementation is how a feature ends up with no reviewable intent.

**Output:** the diff.

## TEST — evidence

Pick the evidence type that fits what changed, from §8's taxonomy (`testing.md`), and get real
output. For a feature that usually means more than one type: a mapper test for the DTO↔Model
boundary (`ARCH-7`), a cubit test asserting the state sequence (`TEST-4`), a repository/network test
for envelope and empty-body handling (`SEC-7`), and a real API verification for anything whose
correctness depends on live behavior (§5).

Mock HTTP, storage, clock, and platform channels; never the mapper, `Failure`, or your own models
(`TEST-3`). Check the mock exercises the path you think it does — a green test whose setup bypasses
the behavior under test is not evidence (`TEST-3`, §8).

Every acceptance criterion from UNDERSTAND gets checked here, and any that cannot be checked is
reported as unverified rather than assumed (`TEST-1`).

**Output:** real test output — pass/fail, with any failure named, including one that predates the
feature (`TEST-1`).

## VERIFY — the gate

Run `verification-protocol.md` (§10), scaled to the change. A feature is not a small change:
expect the network-failure, RTL/localization, accessibility, and stale-request rows to apply, plus
the production rows if any release-affecting file moved.

State which rows you skipped and why. A row not run is never reported as green (`TEST-1`).

**Output:** which checks ran, which were skipped, and why.

## REVIEW — run the reviewer against the implementation

Before the final report, run `reviewer.md` against the actual diff and the code around it,
with the DECIDE plan as the intent to check against.

- Fix every `CRITICAL` before reporting. A `CRITICAL` finding is a 🔴 violation, an invented API, or
  an unsupported claim of fixed/verified — none of those may survive into the report.
- Fix every `HIGH`, or state the reason it stands (§0.1's SHOULD deviation, recorded at the point of
  deviation).
- Carry `MEDIUM` and `LOW` findings into the report as either fixed or explicitly deferred.
- Findings about pre-existing code outside the feature's scope become register candidates (§0.6, §9).

Re-run TEST and VERIFY for anything the review caused you to change. A review-driven fix with no
re-run is an untested change.

**Output:** the findings, and what you did about each one.

## UPDATE REGISTER

Add, update, or close entries in `register.md` (§9) — with evidence for *this* repository, in
this repository's live register section. An entry closes to `VERIFIED` only on evidence, never by
inference or age; an `OPEN`/`IN_PROGRESS`/`BLOCKED` entry is never deleted (§9).

New gaps this feature revealed and did not fix belong here, including anything `BLOCKED` on the
backend (`api-investigator.md`).

**Output:** the register diff, if any.

## REPORT — final report

Report under §11 (`flutter-expert.md`), matching the shape to the ask. For a feature, the
report contains:

1. **Files changed** — and **why** each one changed.
2. **Files created** — and why nothing existing covered it (§2.1).
3. **Existing code reused** — named.
4. **Tests** — what was written and what was run, with real results; partial passes reported as
   partial, failures named (`TEST-1`).
5. **Verification** — which §10 rows ran, which were skipped and why.
6. **Review outcome** — findings by severity, and what was fixed vs. deferred.
7. **Remaining risks** — what could still be wrong, and what would surface it.
8. **Assumptions** — every `ASSUMPTION` carried forward from API verification or elsewhere, and what
   breaks if it is wrong.
9. **Intentionally untouched code** — pre-existing violations and cleanup deliberately not performed
   (§0.6), plus their register entries.
10. **Exceptions invoked** — each with all four §0.7 answers.
11. **Register changes** — added, updated, closed.

Never claim a test, build, or API call passed unless you ran it and saw the result (`TEST-1`, §11).
"Should work" is the same claim as "passed" (§1, REPORT).
