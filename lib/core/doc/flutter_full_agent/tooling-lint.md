# Tooling & lint governance — canonical policy

**Canonical home for:** §7 (automation buckets and the `analysis_options.yaml` baseline)

**Owner document:** `flutter-expert.md` — rule language (§0.1), canonical-home
rule (§0.2), precedence (§0.3), operating loop (§1), reporting contract (§11).
**Section numbers** (`§4.1`, `§7`, `§9`, …) are the original policy's section numbers and are
kept unchanged; the Section map in `flutter-expert.md` says which file each one lives in.
**Do not restate any rule from this file elsewhere** — cite its Rule ID instead (§0.2).

**This file is the enforcement mechanism** referenced by `SEC-6`, `SEC-9`, `PERF-5` and `STATE-4`.
Those rules cite §7 for verification; §7 does not restate them. An unavailable lint rule becomes a
register entry (`register.md` §9), never a silent downgrade.

---

# 7. Tooling & lint governance

Don't ask a human (or yourself, in review) to manually re-check something a tool can check on
every commit. Sort every requirement in this document into exactly one of these buckets, and
handle each differently:

- **Automatable now** (lint rule, analyzer flag, formatter, a CI-run test, a grep/search check
  that can be scripted) — this should be wired into `analysis_options.yaml` and/or CI, not held
  in a human's head.
- **Requires code review** — an architectural judgment call (e.g. `ARCH-2`'s cubit-to-cubit ban)
  that no lint rule captures well; a human reviewer is the enforcement mechanism.
- **Requires runtime verification** — something you can only confirm by running the app (e.g.
  `A11Y-1`'s 200%-font-scale check, `PROD-1`'s "a test crash arrived").
- **Requires backend verification** — anything that depends on live API behavior (§5) rather than
  client code alone.

```yaml
# analysis_options.yaml — the automatable slice of this policy
include: package:flutter_lints/flutter.yaml

analyzer:
  language:
    strict-casts: true
    strict-raw-types: true
  errors:
    use_build_context_synchronously: error   # SEC-9 / ARCH-3
    unawaited_futures: error
    avoid_dynamic_calls: error                # SEC-6

linter:
  rules:
    - use_build_context_synchronously
    - unawaited_futures
    - avoid_dynamic_calls
    - cancel_subscriptions                    # STATE-4
    - close_sinks                              # STATE-4
    - prefer_const_constructors                # PERF-5
    - avoid_slow_async_io
    - always_declare_return_types
```

If a lint rule this policy assumes is unavailable or incompatible with the current project's
`analysis_options.yaml`: don't claim it's enabled, record it as a `§9` REGISTER entry, and suggest
the safest available substitute (a CI grep check, a code-review checklist item) instead of
silently downgrading the requirement to "best effort."
