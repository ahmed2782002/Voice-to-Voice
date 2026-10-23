# Refactor notes — v9 monolith → modular structure

**This file is a refactor artifact, not policy.** It records where every part of the
original `flutter-expert.md` went, what was added, and what a human should look at. No rule
is defined here; nothing here may be cited as a requirement.

Source of truth for the refactor: the original single-file policy (955 lines, v9 frontmatter),
treated as immutable input. Rule text in the new tree is byte-identical to it.

---

## 1. Section → file mapping

| Original section | New file | Rule IDs | Status |
| --- | --- | --- | --- |
| Frontmatter (`name`/`description`/`model`/`color`) | `flutter-expert.md` | — | PRESERVED, description updated to describe the orchestrator role |
| Intro paragraphs (stack description, one-ID-one-place principle) | `flutter-expert.md` | — | VERBATIM |
| §0.1 Rule language (MUST/SHOULD/MAY/REGISTER) | `flutter-expert.md` | — | VERBATIM |
| §0.2 Canonical home | `flutter-expert.md` | — | VERBATIM |
| §0.3 Rule precedence | `flutter-expert.md` | — | VERBATIM |
| §0.4 Do-not-invent | `flutter-expert.md` | — | VERBATIM |
| §0.5 Negative claims require adequate evidence | `flutter-expert.md` | — | VERBATIM |
| §0.6 Change-scope control | `flutter-expert.md` | — | VERBATIM |
| §0.7 Exception governance | `flutter-expert.md` | — | VERBATIM |
| §1 Agent operating loop (11-phase table) | `flutter-expert.md` | — | VERBATIM |
| §2.1 Existing-pattern-first | `architecture.md` | — | VERBATIM |
| §2.2 Discovery checklist | `architecture.md` | — | VERBATIM |
| §3 Baseline measurements | `architecture.md` | — | VERBATIM |
| §4 Decision framework (§4.1–§4.6, historical) | `engineering-knowledge.md` | — | VERBATIM |
| §5 Backend source-of-truth hierarchy + ABP envelope note | `networking.md` | — | VERBATIM |
| §6 preamble (rule-entry format) | `flutter-expert.md` | — | VERBATIM (heading replaced by prose lead-in) |
| §6.1 Security & data integrity | `security.md` | `SEC-1`…`SEC-9` | VERBATIM |
| §6.2 Architecture & DI | `architecture.md` | `ARCH-1`…`ARCH-7` | VERBATIM |
| §6.3 Widget, context & lifecycle | `lifecycle.md` | `LIFE-1`…`LIFE-5` | VERBATIM |
| §6.4 Performance | `performance.md` | `PERF-1`…`PERF-6` | VERBATIM |
| §6.5 Networking | `networking.md` | `NET-1`…`NET-7` | VERBATIM |
| §6.6 State management | `state-management.md` | `STATE-1`…`STATE-7` | VERBATIM |
| §6.7 Testing & evidence | `testing.md` | `TEST-1`…`TEST-5` | VERBATIM |
| §6.8 Accessibility & localization | `accessibility-localization.md` | `A11Y-1`…`A11Y-5` | VERBATIM |
| §6.9 Production readiness | `production.md` | `PROD-1`…`PROD-7` | VERBATIM |
| §6.10 Style & consistency | `style.md` | `STYLE-1`…`STYLE-11` | VERBATIM |
| §6.11 Maintainability | `maintainability.md` | `MAINT-1`…`MAINT-6` | VERBATIM |
| §7 Tooling & lint governance + `analysis_options.yaml` | `tooling-lint.md` | — | VERBATIM |
| §8 Testing & evidence governance (evidence taxonomy) | `testing.md` | — | VERBATIM |
| §9 Register (statuses, table rules, illustrative table) | `register.md` | — | VERBATIM + new empty live-register section |
| §10 Final verification protocol | `verification-protocol.md` | — | VERBATIM |
| §11 Reporting contract | `flutter-expert.md` | — | VERBATIM |
| §12 Recurring mistake patterns (historical) | `engineering-knowledge.md` | — | VERBATIM |
| §13 Mindset | `flutter-expert.md` | — | VERBATIM |

## 2. Rule ID → canonical file

Each ID below is defined in exactly one file, and its definition line (ID + severity marker +
requirement sentence) is byte-identical to the original.

| Rule ID | Severity (unchanged) | Canonical file |
| --- | --- | --- |
| `SEC-1` | 🔴 | `security.md` |
| `SEC-2` | 🔴 | `security.md` |
| `SEC-3` | 🔴 | `security.md` |
| `SEC-4` | 🔴 | `security.md` |
| `SEC-5` | 🔴 | `security.md` |
| `SEC-6` | 🔴 | `security.md` |
| `SEC-7` | 🔴 | `security.md` |
| `SEC-8` | 🔴 | `security.md` |
| `SEC-9` | 🔴 | `security.md` |
| `ARCH-1` | 🟠 | `architecture.md` |
| `ARCH-2` | 🟠 | `architecture.md` |
| `ARCH-3` | 🔴 | `architecture.md` |
| `ARCH-4` | 🟠 | `architecture.md` |
| `ARCH-5` | 🟡 | `architecture.md` |
| `ARCH-6` | 🟠 | `architecture.md` |
| `ARCH-7` | 🟠 | `architecture.md` |
| `LIFE-1` | pointer (see `SEC-9`) | `lifecycle.md` |
| `LIFE-2` | 🟠 | `lifecycle.md` |
| `LIFE-3` | 🟠 | `lifecycle.md` |
| `LIFE-4` | 🟠 | `lifecycle.md` |
| `LIFE-5` | 🟡 | `lifecycle.md` |
| `PERF-1` | 🔴 | `performance.md` |
| `PERF-2` | 🟠 | `performance.md` |
| `PERF-3` | 🟠 | `performance.md` |
| `PERF-4` | 🟠 | `performance.md` |
| `PERF-5` | 🟡 | `performance.md` |
| `PERF-6` | 🟡 | `performance.md` |
| `NET-1` | 🔴 | `networking.md` |
| `NET-2` | 🟠 | `networking.md` |
| `NET-3` | 🔴 | `networking.md` |
| `NET-4` | 🟠 | `networking.md` |
| `NET-5` | 🟠 | `networking.md` |
| `NET-6` | 🟠 | `networking.md` |
| `NET-7` | 🟡 | `networking.md` |
| `STATE-1` | 🟠 | `state-management.md` |
| `STATE-2` | 🟠 | `state-management.md` |
| `STATE-3` | 🟠 | `state-management.md` |
| `STATE-4` | 🟠 | `state-management.md` |
| `STATE-5` | 🔴 | `state-management.md` |
| `STATE-6` | 🟠 | `state-management.md` |
| `STATE-7` | 🟠 | `state-management.md` |
| `TEST-1` | 🔴 | `testing.md` |
| `TEST-2` | 🔴 | `testing.md` |
| `TEST-3` | 🟠 | `testing.md` |
| `TEST-4` | 🟠 | `testing.md` |
| `TEST-5` | 🟡 | `testing.md` |
| `A11Y-1` | 🟠 | `accessibility-localization.md` |
| `A11Y-2` | 🟠 | `accessibility-localization.md` |
| `A11Y-3` | 🟡 | `accessibility-localization.md` |
| `A11Y-4` | 🟡 | `accessibility-localization.md` |
| `A11Y-5` | 🟡 | `accessibility-localization.md` |
| `PROD-1` | 🔴 | `production.md` |
| `PROD-2` | 🔴 | `production.md` |
| `PROD-3` | 🔴 | `production.md` |
| `PROD-4` | 🔴 | `production.md` |
| `PROD-5` | 🔴 | `production.md` |
| `PROD-6` | 🟠 | `production.md` |
| `PROD-7` | 🟡 | `production.md` |
| `STYLE-1` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-2` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-3` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-4` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-5` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-6` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-7` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-8` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-9` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-10` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `STYLE-11` | table entry (`STYLE`/`MAINT` one-liner) | `style.md` |
| `MAINT-1` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |
| `MAINT-2` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |
| `MAINT-3` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |
| `MAINT-4` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |
| `MAINT-5` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |
| `MAINT-6` | table entry (`STYLE`/`MAINT` one-liner) | `maintainability.md` |

## 3. File inventory

Line counts are live as of 2026-08-25. Re-read them with `wc -l *.md` rather than trusting
this table if the folder has been edited since — a stale inventory is the same defect as a
stale baseline (§3).

| File | Lines | Nature |
| --- | --- | --- |
| `AI_INSTRUCTION_FILE_MAP.md` | 100 | Entry note + file index. **Rewritten 2026-08-25** — was a 690-line second routing table; now defers all routing to `flutter-expert.md` |
| `PROJECT.md` | 482 | Facts about this repository. **Populated 2026-08-25** from a real baseline; was an all-`UNKNOWN` skeleton. Also holds the v7-citation legend |
| `REFACTOR-NOTES.md` | 356 | This file. Refactor + install history. An artifact, never policy |
| `accessibility-localization.md` | 41 | §6.8 `A11Y-*` |
| `api-investigator.md` | 169 | Sub-agent: backend verification |
| `architecture.md` | 146 | §2, §3, §6.2 `ARCH-*`. §3 cross-feature grep corrected 2026-08-25 |
| `engineering-knowledge.md` | 146 | §4, §12 — historical examples only |
| `feature-workflow.md` | 221 | Feature delivery workflow, built on §1 phases |
| `flutter-expert.md` | 377 | Orchestrator: §0, §1, §1.1, §6 preamble, §11, §13, Section map, routing, delegation |
| `lifecycle.md` | 51 | §6.3 `LIFE-*` |
| `maintainability.md` | 26 | §6.11 `MAINT-*` |
| `networking.md` | 100 | §5, §6.5 `NET-*` |
| `performance.md` | 60 | §6.4 `PERF-*` |
| `production.md` | 61 | §6.9 `PROD-*` |
| `register.md` | 172 | §9 policy + **this repository live register, populated 2026-08-25**: baseline, open gaps, blocked items, divergences, verified-clean |
| `reviewer.md` | 168 | Sub-agent: defect-hunting review |
| `security.md` | 69 | §6.1 `SEC-*` |
| `state-management.md` | 49 | §6.6 `STATE-*` |
| `style.md` | 31 | §6.10 `STYLE-*` |
| `testing.md` | 69 | §6.7, §8 `TEST-*` |
| `tooling-lint.md` | 61 | §7 tooling and lint governance |
| `verification-protocol.md` | 43 | §10 pre-completion gate |
| `validate.sh` | 160 | **New 2026-08-25.** Structural validator; replaces the un-runnable pasted report that used to be §4 |

## 4. Validation

**What was here before, and why it is gone.** This section used to hold a transcribed console
report ending in `VALIDATION PASSED — all checks above returned OK`. One of its checks read:

```
CHECK 5: severity markers preserved (counts must match exactly)
  MUST 🔴           source=36   new=42   OK
```

`36` is not `42`, the check itself said the counts must match exactly, and the line was labelled
`OK` anyway — as were seven more like it. The counts differing is not itself a defect (a rule ID
gets cited in more files than it did in one monolith, so markers legitimately multiply), but a
report that prints `OK` on a mismatch and then claims `VALIDATION PASSED` is not evidence of
anything. It is precisely the failure `TEST-1` and §0.5 exist to prevent, sitting inside the
document that introduces them. Pasted output that cannot be re-run is also not evidence — nobody
could check it.

**What replaces it.** `validate.sh`, in this folder, re-runnable, exits non-zero on any failure and
never prints a pass on a mismatch:

```bash
cd lib/core/doc/flutter_full_agent && bash validate.sh
```

It checks what this system claims about itself: that every `.md` reference resolves, that no file
points at a directory layout that does not exist, that all 75 rule IDs have exactly one canonical
home with no orphan citations, that every prose-form rule carries a severity marker, that the
register has a dated baseline rather than a placeholder, that `PROJECT.md` holds verified facts
rather than an all-`UNKNOWN` skeleton, and that exactly one file carries a routing table. It does
**not** check rule content, and it does not read the app — it is a structural check, and it says so.

**Real output, 2026-08-25** (exit status 0):

```
==============================================================================
CHECK 1: every referenced .md file resolves — in this folder, or at the repo root
==============================================================================
  optional, not present (ok): CLAUDE.md
  at repo root (ok): flutter_full_agent_v7.md
PASS  all referenced .md files resolve

==============================================================================
CHECK 2: no reference to a subdirectory layout (this folder is flat)
==============================================================================
PASS  no agents/ rules/ workflows/ .claude/ path references

==============================================================================
CHECK 3: every rule ID is defined exactly once, in its own category file
==============================================================================
  rule IDs defined: 75
PASS  75 rule IDs, each with exactly one canonical home, no orphan citations

==============================================================================
CHECK 4: severity markers present on every non-table rule
==============================================================================
PASS  every prose-form rule carries 🔴/🟠/🟡/⚪ (LIFE-1 exempt: it is a pointer)
  counts: 🔴 23 · 🟠 26 · 🟡 11

==============================================================================
CHECK 5: the register names a real baseline date, not a placeholder
==============================================================================
PASS  register baseline: Baseline run: 2026-08-25

==============================================================================
CHECK 6: PROJECT.md carries verified facts, not an all-UNKNOWN skeleton
==============================================================================
  VERIFIED sections: 13 · remaining UNKNOWN markers: 5
PASS  PROJECT.md is populated (13 verified vs 5 unknown)

==============================================================================
CHECK 7: one routing table only (no second source of truth)
==============================================================================
PASS  routing lives in exactly one file: ./flutter-expert.md 

==============================================================================
ALL CHECKS PASSED
==============================================================================
```

Re-run it after any edit to this folder. A structural claim about this system that `validate.sh`
does not cover is a claim with no evidence behind it (§0.5).

## 5. Structural decisions (where the requested layout was adjusted)

The requested layout listed ten rule files. Five original sections had no home in that list, so five
files were added rather than forcing content into a category it does not belong to. Each addition is
one original section, kept whole:

| Added file | Holds | Why not folded elsewhere |
| --- | --- | --- |
| `lifecycle.md` | §6.3 `LIFE-*` | `LIFE-2` (`MediaQuery` scoping) and `LIFE-5` (`PopScope`) are widget rules, not Cubit rules; folding §6.3 into `state-management.md` would have mixed two categories and split `LIFE-*` across files |
| `tooling-lint.md` | §7 | §7 is the verification mechanism cited by `SEC-6`, `SEC-9`, `PERF-5`, `STATE-4`; putting it under any one of those would make three of them cite another category's file |
| `engineering-knowledge.md` | §4, §12 | Both are explicitly historical. Keeping them together and labelled is what stops them being read as facts about the current repository |
| `register.md` | §9 | Register is governance plus per-repository state; it is neither a rule category nor a workflow |
| `verification-protocol.md` | §10 | §10 is the VERIFY gate, used by both the loop (§1) and the feature workflow; duplicating it into either would violate one-canonical-home |

Other decisions worth knowing:

- **§-numbers were not rewritten into file paths.** Rules cite each other as `§4.1`, `§7`, `§9`,
  `§2.2`. Rewriting those citations would have meant editing rule text. Instead the numbers stay and
  the **Section map** in `flutter-expert.md` resolves each one to a file. Every rule file
  repeats a one-line pointer to that map — a pointer, not a copy of it.
- **§2 and §3 both went into `architecture.md`**, per the requested grouping of repository
  discovery with `ARCH-*`. §3 is a measurement protocol rather than an architecture rule; it lives
  there because its output feeds discovery and the register, and because a separate file for one
  table would have been a split for its own sake.
- **§9 was kept whole inside one file** and its three kinds of content separated by labelling rather
  than by splitting: policy (statuses and table rules), Historical example (the original's
  illustrative table, which the original already labels as from a past project), and Project state
  (a new, explicitly empty *Live register* section).
- **`flutter-expert.md` no longer contains the rule catalog.** It retains §0, §1, the §6
  rule-entry format, §11 and §13 — the loop, the precedence order, and the reporting contract — plus
  new orchestration sections.

## 6. Conflicts and ambiguities discovered

1. **`LIFE-1` is a pointer, not a rule.** The original defines it as *"see `SEC-9`"* with an explicit
   note not to split the requirement in two. Preserved exactly as a pointer in `lifecycle.md`.
   It therefore has no severity marker of its own — deliberate, and inherited from the source.
2. **`NET-2` is 🟠 but contains a 🔴 sub-rule** (*"a non-idempotent create endpoint must never
   retry"*). Preserved verbatim. Flagged because any tooling that reads a rule's severity from its
   header line will grade that sub-rule as SHOULD when the text says MUST.
3. **`STYLE-6` restates `A11Y-1`'s `minHeight`-around-text requirement**, with a citation to
   `A11Y-1`. **`STYLE-9` restates `LIFE-3`**, with a citation and a "per `LIFE-3`" exception. These
   are the closest things to duplication in the source. They were **left exactly as written** — the
   instruction not to remove information that merely looks similar outranks the de-duplication pass,
   and in both cases the original chose to cite rather than merge. A human may want to decide whether
   `STYLE-6`/`STYLE-9` should become pure pointers in the style of `LIFE-1`.
4. **`PROD-1` restates `SEC-2`'s no-PII requirement** at the crash-reporter boundary, with a
   citation. Same treatment: left as written, noted as a cross-reference rather than a second rule.
5. **`NET-6`'s empty-body row and `SEC-7`** overlap by design; `NET-6` cites `SEC-7` instead of
   restating the requirement. Verified as a citation, no change.
6. **§11's "never claim a test, build, or API call passed"** is, by the original's own words, *"not a
   separate rule, it's the enforcement of `TEST-1` at report time."* Preserved as such: `TEST-1` is
   defined once in `testing.md`; §11 and §10 cite it.
7. **A typo was preserved deliberately.** §0.3 contains *"silently comitting"*. It is inside rule
   text, so it was not touched. Fixing it is safe, but it is a human's call, not a refactor's.
8. **`PERF-3`'s requirement text contains a mid-word line break** (`ListView.\nbuilder`) in the
   original markdown. Preserved byte-for-byte; it renders correctly but greps for `ListView.builder`
   inside that one line will miss it.
9. **No repository was available to inspect *at refactor time*.** The refactor input was the policy
   file alone, which is why `PROJECT.md` shipped entirely `UNKNOWN - needs verification` and the live
   register shipped empty. **Resolved 2026-08-25** — see §9: the repository was inspected, both files
   are populated from real evidence, and the remaining `UNKNOWN`/`BLOCKED` markers are the ones that
   genuinely could not be verified (everything backend-side, which has no reachable base URL).
10. **The frontmatter `description` field was edited** — the one piece of non-rule original text that
    changed — to describe the orchestrator role and to say where the rule catalog now lives. `name`
    and `color` are unchanged; `model` was changed from `default` to `inherit` on 2026-08-25 (§9),
    because `default` is not a value the agent loader recognises.

## 7. What is NEW (no new rules)

**No new rule was added, and no rule ID was created.** Nothing in the new files imposes a
requirement that was not already in the source. The new material is organisational or was explicitly
requested:

| New content | Where | Nature |
| --- | --- | --- |
| Agent identity, core responsibilities, rule-loading protocol, "when to inspect which rules" routing table, delegation criteria, Section map | `flutter-expert.md` | Navigation and orchestration; every entry points at an existing rule or section |
| Reviewer agent: review passes, duplication/assumption/invention passes, evidence audit, finding format, report shape | `reviewer.md` | Requested. Every pass maps to existing rule IDs; the evidence audit is `TEST-1`/`TEST-3`/§0.5/§8/§0.7 applied at review time |
| CRITICAL / HIGH / MEDIUM / LOW severity ladder | `reviewer.md` | Requested. Presentation only, derived mechanically from §0.1 (🔴→CRITICAL, 🟠→HIGH, 🟡→MEDIUM, ⚪→LOW) so the reviewer cannot re-grade the policy |
| API investigator: investigation order, 17-item coverage checklist, `VERIFIED`/`ASSUMPTION`/`UNKNOWN`/`BLOCKED` labels, report template | `api-investigator.md` | Requested. Executes §5 and §0.4; the checklist items each cite an existing rule |
| Feature workflow: requirements, acceptance criteria, discovery gate, API-verification gate, architecture plan, review gate, final report contents | `feature-workflow.md` | Requested. Built on §1's phases, which it references rather than restates |
| `PROJECT.md` skeleton | `PROJECT.md` | Requested. All values `UNKNOWN - needs verification` |
| Live register section (empty) | `register.md` | Separates project state from §9's policy and illustrative example |
| Per-file navigation headers | every rule file | Canonical-home declaration, owner pointer, §-number pointer |

Two things in the new material are worth a human's eye because they are judgement calls, not
transcriptions: the reviewer's severity ladder (does 🟡 → MEDIUM match how your team triages?) and
the feature workflow's acceptance-criteria list (it names the criteria features on this stack
routinely forget, each traced to an existing rule ID — confirm the list is the right one).

## 8. How to use this structure during normal development

1. **Every task starts with two files:** `PROJECT.md` (what this repository is) and
   `flutter-expert.md` (loop, precedence, reporting). Nothing else is read by default.
2. **Route by what the task touches**, using the routing table in the orchestrator. Load two or three
   rule files, not all of them. Loading the wrong file costs tokens; guessing a rule's exception
   costs a release.
3. **Small fix:** run §1 directly. State the phases you skipped.
   **Feature:** run `feature-workflow.md`, which is §1 plus the discovery, API-verification,
   and review gates.
4. **Before any DTO, model, mapper, repository method, or endpoint constant:** run
   `api-investigator.md`. Build on `VERIFIED`; carry `ASSUMPTION` forward as a label; never
   build on `UNKNOWN` or `BLOCKED`.
5. **Before the final report on anything non-trivial:** run `reviewer.md` against the real
   diff. Fix every CRITICAL before reporting.
6. **Before declaring done:** run `verification-protocol.md`, scaled to the change, and say
   which rows you skipped.
7. **Cite rules by ID, always.** `SEC-9`, not "the mounted rule". If you cannot cite the ID, open the
   file — a remembered rule is missing its exception, and the exception is the part most often wrong.
8. **When policy and repository disagree:** follow the repository, open a register entry, do not fork
   a competing pattern (§0.3). When you find a gap you are not fixing: register entry, not a
   drive-by (§0.6).
9. **Fill `PROJECT.md` opportunistically.** Every time discovery verifies a fact, write it down with
   where you read it. That is what stops the next session re-deriving it — or guessing it.
10. **If you ever find the same requirement stated twice under two IDs, that is a defect in this
    system.** Report it; do not pick one.

---

## 9. Post-install corrections — 2026-08-25

The refactor produced a correct rule catalog that **could not actually be loaded or trusted**: every
cross-reference pointed at directories that do not exist, the file that was supposed to route tasks
duplicated the orchestrator, the two files carrying repository state were empty, and §4 claimed a
validation pass over numbers that did not match. This pass fixed all of it. **No rule text, rule ID,
or severity was changed.** Nothing below adds a requirement.

### Structural

| # | Was | Now | Why |
|---|---|---|---|
| 1 | 365 references to `.claude/agents/…`, `rules/…`, `workflows/…` | all rewritten to bare filenames | Nothing lived at those paths. Every reference in the system resolved to nothing, including the one telling you to read the rule before applying it. `validate.sh` CHECK 2 now guards this |
| 2 | `AI_INSTRUCTION_FILE_MAP.md`, 690 lines, carried a second routing table that no file referenced and that had already drifted from the orchestrator's | 100-line entry note + file index; routing removed and delegated to `flutter-expert.md` | Two routing tables is the exact failure §0.2 exists to prevent. `validate.sh` CHECK 7 now guards this |
| 3 | §2's "Rule ID → canonical file" table listed **`REFACTOR-NOTES.md`** as the canonical home of all 75 IDs | regenerated from the files themselves; each ID resolves to its real category file | The one table implementing canonical-home violated it in all 75 rows, and pointed at an artifact that says it may never be cited as policy |
| 4 | §4 held a pasted report ending `VALIDATION PASSED`, with checks such as `source=36 new=42 OK` under a heading saying counts must match exactly | `validate.sh` + its real output, exit 0 | A pass printed over a mismatch is what `TEST-1` and §0.5 forbid, inside the document that introduces them |
| 5 | §3's inventory listed `.claude/`-prefixed paths and stale line counts | regenerated from `wc -l`, dated | A stale inventory is a stale baseline (§3) |
| 6 | `model: default` in all three agent frontmatters | `model: inherit` | `default` is not a recognised value; the field was silently doing nothing |

### Content

| # | What | Why |
|---|---|---|
| 7 | **`PROJECT.md` populated** — 13 verified sections with the file or command behind each fact, plus every pattern in `core/` worth reusing and the two project-specific exceptions | It is the file read before every task, and it held zero information. Every task was paying full discovery cost |
| 8 | **`register.md` live register populated** — §3 baseline re-measured with corrected paths, 22 open gaps, 4 blocked items, 2 deliberate divergences, 11 rules verified clean | §9 requires per-repository evidence. Six of the gaps are 🔴 and were sitting in the code unrecorded, including `INTERNET` present only in the debug manifest and four interceptors never attached to `Dio` |
| 9 | **§3's cross-feature grep corrected** — it hard-coded `lib/features/`; this repository uses `lib/feature/`, so the command returned `0` and read as "no violations". The real count is ~35. §3 now says to confirm the directory name first, and warns that a wrong path is a §0.5 false negative | It is the same failure §12 records as history: a grep too narrow to support its own conclusion. It was live in the measurement table |
| 10 | **v7-citation legend added to `PROJECT.md`** — `lib/` carries 67 `Tier x.y` / `§n.m` citations from the superseded v7 policy, mapped to current rule IDs, verified against `flutter_full_agent_v7.md` §13 | A `§8.6` in a code comment resolved against nothing. Mass-rewriting them would be unrelated cleanup (§0.6), so the legend translates on read instead |
| 11 | **§1.1 "Scaling the loop" added** to `flutter-expert.md` — Touch / Change / Feature, with the rule that what a change can break decides its size, not the diff | Ten phases and an eleven-point report for a copy fix made "state the phases you skipped" cost more than the phases. Orchestration guidance, no new requirement |

### What was deliberately *not* done

- **Nothing outside this folder was touched.** No `.claude/` tree, no root `CLAUDE.md`, no
  `analysis_options.yaml`. `AI_INSTRUCTION_FILE_MAP.md` documents the one line that would wire this
  folder into a session automatically — creating that file is the repository owner's call, not this
  pass's (§0.6).
- **No app code was changed.** The six 🔴 gaps found are recorded in the register, not fixed —
  fixing them is not what this task was about (§0.6), and each one deserves its own change with its
  own evidence.
- **The `"silently comitting"` typo in §0.3 is still there** (see §6 item 7). Still a human's call.
- **`PERF-3`'s mid-word line break** is still there (§6 item 8), for the same reason.
