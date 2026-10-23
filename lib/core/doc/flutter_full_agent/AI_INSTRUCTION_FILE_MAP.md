# START HERE — what this folder is

The engineering policy for AI coding agents working on **Laundo**. Twenty-two files, flat, in this
one directory. `flutter-expert.md` is the entry point; everything else is either a rule catalog it
routes to, a sub-agent it delegates to, or a record of this repository.

> **This file used to duplicate the orchestrator's routing table.** It no longer does. Two routing
> tables is two sources of truth, which is the failure §0.2 exists to prevent — and they had already
> drifted apart. **Routing lives in `flutter-expert.md` only**, in its *When to inspect which rules*
> table. This file is an index and an install note, nothing more. If anything here appears to state a
> rule, the rule file wins (§0.2, and Rule 7 of the old version of this file).

---

## How a session actually loads this

Nothing here is loaded automatically. This folder sits under `lib/core/doc/`, which no tool reads on
its own, so an agent that is not pointed at it will work without it and never know.

**Per session, one line is enough:**

```
Read lib/core/doc/flutter_full_agent/flutter-expert.md and PROJECT.md, then do: <the task>
```

**To make it automatic**, add one line to a `CLAUDE.md` at the repository root (this folder does not
create that file — where the project keeps its agent wiring is the repository owner's call):

```markdown
Engineering policy: read `lib/core/doc/flutter_full_agent/flutter-expert.md` and `PROJECT.md`
before any non-trivial change, and follow the loop and precedence they define.
```

**To register the three agents as real sub-agents**, their files carry `name`/`description`/`model`
frontmatter and are drop-in ready for a `.claude/agents/` directory — copy or symlink them there if
and when the project wants that wiring. They work read-as-documents without it.

## Reading order

1. **`PROJECT.md`** — what this repository actually is. Always. It also carries the legend for the
   67 stale `Tier x.y` / `§n.m` citations still in `lib/`.
2. **`flutter-expert.md`** — the loop (§1), how to size it (§1.1), precedence (§0.3), the reporting
   contract (§11), and the routing table that says which rule files this task needs.
3. **Whatever that table sends you to.** Two or three files, not twenty. Loading a rule file is
   cheap; guessing its exception is not.
4. **`register.md`** — before claiming a gap is new, and again before finishing if you found one.

## File index

**Orchestrator and sub-agents**

| File | What it is |
|---|---|
| `flutter-expert.md` | Entry point. §0 (rule language, precedence, do-not-invent, negative claims, change scope, exceptions), §1 operating loop, §1.1 loop sizing, §11 reporting, §13 mindset, the Section map, and all routing |
| `reviewer.md` | Defect-hunter. Runs against a real diff; reports, does not edit. Includes the evidence audit most reviews skip |
| `api-investigator.md` | Backend verification. 17-item coverage checklist; labels every fact `VERIFIED` / `ASSUMPTION` / `UNKNOWN` / `BLOCKED` |

**Rule catalog** — one canonical home per rule ID

| File | Rule IDs / sections |
|---|---|
| `security.md` | `SEC-1`…`SEC-9` |
| `architecture.md` | `ARCH-1`…`ARCH-7`, plus §2 repository discovery and §3 baseline measurements |
| `networking.md` | `NET-1`…`NET-7`, plus §5 backend source-of-truth hierarchy |
| `state-management.md` | `STATE-1`…`STATE-7` |
| `lifecycle.md` | `LIFE-1`…`LIFE-5` |
| `performance.md` | `PERF-1`…`PERF-6` |
| `testing.md` | `TEST-1`…`TEST-5`, plus §8 evidence taxonomy |
| `accessibility-localization.md` | `A11Y-1`…`A11Y-5` |
| `production.md` | `PROD-1`…`PROD-7` |
| `style.md` | `STYLE-1`…`STYLE-11` |
| `maintainability.md` | `MAINT-1`…`MAINT-6` |
| `tooling-lint.md` | §7 automation buckets and the `analysis_options.yaml` baseline |
| `engineering-knowledge.md` | §4 decision framework and §12 recurring mistakes — **historical examples only**, never facts about this repository |

**Workflows**

| File | What it is |
|---|---|
| `feature-workflow.md` | §1 plus the gates a whole feature needs: acceptance criteria, the API-verification gate, the architecture plan, the review gate |
| `verification-protocol.md` | §10, the pre-completion gate. Scale it to the change and state what you skipped |

**This repository's state**

| File | What it is |
|---|---|
| `PROJECT.md` | Verified facts about Laundo, its exceptions, its patterns to reuse, and the v7-citation legend. Baseline 2026-08-25 |
| `register.md` | §9 policy, plus this repository's live register: measured baseline, open gaps, blocked items, deliberate divergences, and what was verified clean |
| `REFACTOR-NOTES.md` | Refactor and install history. **An artifact, not policy** — nothing in it may be cited as a requirement |

## Four things that are easy to get wrong

- **Cite rules by ID.** `SEC-9`, not "the mounted rule". A paraphrase loses the exception, and the
  exception is the part most often wrong from memory (§0.2).
- **Never claim compliance with a file you did not open.** Nor a test, build, or API call you did not
  run (`TEST-1`).
- **Historical is not current.** `engineering-knowledge.md` describes bugs from *other* projects.
  Facts about this one come from §2 discovery, §3 measurement, and `PROJECT.md`.
- **If the same requirement appears under two IDs, that is a defect in this system.** Report it;
  do not pick one.
