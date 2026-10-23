#!/usr/bin/env bash
# Structural validator for this policy folder.
#
# It checks the things this system claims about itself and nothing else. It does
# not read the app, run tests, or check rule content — it checks that every
# reference resolves, every rule ID has exactly one home, and no file points at a
# directory layout that does not exist.
#
# Run from inside the folder:   bash validate.sh
# Exit code 0 = every check passed. Non-zero = the count of failures.
#
# A check that fails prints FAIL and the offending lines. Nothing here prints OK
# on a mismatch — that was the defect in the validation report this replaces.

cd "$(dirname "$0")" || exit 1

fails=0
note() { printf '%s\n' "$*"; }
pass() { printf 'PASS  %s\n' "$*"; }
fail() { printf 'FAIL  %s\n' "$*"; fails=$((fails + 1)); }

RULE_FILES="security.md architecture.md lifecycle.md performance.md networking.md
state-management.md testing.md accessibility-localization.md production.md style.md
maintainability.md"

note '=============================================================================='
note "CHECK 1: every referenced .md file resolves — in this folder, or at the repo root"
note '=============================================================================='
# Files that are deliberately optional: mentioned as something the repository owner
# may create, not as a reference this folder depends on. Absent is not a failure.
OPTIONAL="CLAUDE.md"
ROOT="../../../.."
missing=0
for ref in $(grep -rhoE '`[a-zA-Z0-9_.-]+\.md`' ./*.md | tr -d '`' | sort -u); do
  [ -f "$ref" ] && continue
  if [ -f "$ROOT/$ref" ]; then
    printf '  at repo root (ok): %s\n' "$ref"
    continue
  fi
  case " $OPTIONAL " in
    *" $ref "*) printf '  optional, not present (ok): %s\n' "$ref"; continue ;;
  esac
  printf '  missing: %-34s cited in: %s\n' "$ref" \
    "$(grep -rl "\`$ref\`" ./*.md | tr '\n' ' ')"
  missing=$((missing + 1))
done
if [ "$missing" -eq 0 ]; then
  pass "all referenced .md files resolve"
else
  fail "$missing referenced file(s) do not exist"
fi

note ''
note '=============================================================================='
note "CHECK 2: no reference to a subdirectory layout (this folder is flat)"
note '=============================================================================='
badpaths=$(grep -rnE '(\.claude/|(^|[^a-z-])(agents|rules|workflows)/)[a-z-]+\.md' ./*.md)
if [ -z "$badpaths" ]; then
  pass "no agents/ rules/ workflows/ .claude/ path references"
else
  fail "directory-prefixed references found:"
  printf '%s\n' "$badpaths" | sed 's/^/    /'
fi

note ''
note '=============================================================================='
note "CHECK 3: every rule ID is defined exactly once, in its own category file"
note '=============================================================================='
dupes=0
orphans=0
total=0
for p in SEC ARCH LIFE PERF NET STATE TEST A11Y PROD STYLE MAINT; do
  for i in $(seq 1 11); do
    id="$p-$i"
    homes=$(grep -l "^\*\*\`$id\`\|^| \`$id\` |" $RULE_FILES 2>/dev/null | wc -l)
    [ "$homes" -eq 0 ] && continue
    total=$((total + 1))
    if [ "$homes" -gt 1 ]; then
      printf '  %-10s defined in %s files: %s\n' "$id" "$homes" \
        "$(grep -l "^\*\*\`$id\`\|^| \`$id\` |" $RULE_FILES | tr '\n' ' ')"
      dupes=$((dupes + 1))
    fi
  done
done
# A cited ID with no definition anywhere is an orphan citation.
for id in $(grep -rhoE '`(SEC|ARCH|LIFE|PERF|NET|STATE|TEST|A11Y|PROD|STYLE|MAINT)-[0-9]+`' \
            ./*.md | tr -d '`' | sort -u); do
  if ! grep -q "^\*\*\`$id\`\|^| \`$id\` |" $RULE_FILES 2>/dev/null; then
    printf '  cited but never defined: %s\n' "$id"
    orphans=$((orphans + 1))
  fi
done
note "  rule IDs defined: $total"
if [ "$dupes" -eq 0 ] && [ "$orphans" -eq 0 ]; then
  pass "$total rule IDs, each with exactly one canonical home, no orphan citations"
else
  [ "$dupes" -gt 0 ] && fail "$dupes rule ID(s) defined in more than one file"
  [ "$orphans" -gt 0 ] && fail "$orphans cited rule ID(s) have no definition"
fi

note ''
note '=============================================================================='
note "CHECK 4: severity markers present on every non-table rule"
note '=============================================================================='
nosev=$(grep -hoE '^\*\*`[A-Z0-9]+-[0-9]+`[^🔴🟠🟡⚪]*—' $RULE_FILES 2>/dev/null |
        grep -v 'LIFE-1')
if [ -z "$nosev" ]; then
  pass "every prose-form rule carries 🔴/🟠/🟡/⚪ (LIFE-1 exempt: it is a pointer)"
else
  fail "rule(s) with no severity marker:"
  printf '%s\n' "$nosev" | sed 's/^/    /'
fi
note "  counts: 🔴 $(grep -ho '🔴' $RULE_FILES | wc -l) · 🟠 $(grep -ho '🟠' $RULE_FILES | wc -l) · 🟡 $(grep -ho '🟡' $RULE_FILES | wc -l)"

note ''
note '=============================================================================='
note "CHECK 5: the register names a real baseline date, not a placeholder"
note '=============================================================================='
if grep -q 'EMPTY — NOT YET POPULATED' register.md; then
  fail "register.md live section is still the empty placeholder"
elif grep -qE '^\*\*Baseline run:\*\* [0-9]{4}-[0-9]{2}-[0-9]{2}' register.md; then
  pass "register baseline: $(grep -oE '^\*\*Baseline run:\*\* [0-9-]+' register.md | head -1 | sed 's/\*\*//g')"
else
  fail "register.md has no dated baseline line"
fi

note ''
note '=============================================================================='
note "CHECK 6: PROJECT.md carries verified facts, not an all-UNKNOWN skeleton"
note '=============================================================================='
unk=$(grep -c 'UNKNOWN - needs verification' PROJECT.md)
ver=$(grep -c '\*\*VERIFIED' PROJECT.md)
note "  VERIFIED sections: $ver · remaining UNKNOWN markers: $unk"
if [ "$ver" -gt 0 ] && [ "$unk" -lt "$ver" ]; then
  pass "PROJECT.md is populated ($ver verified vs $unk unknown)"
else
  fail "PROJECT.md is still mostly unverified ($ver verified vs $unk unknown)"
fi

note ''
note '=============================================================================='
note "CHECK 7: one routing table only (no second source of truth)"
note '=============================================================================='
routers=$(grep -l 'If the task touches…\|TASK → FILE SELECTION MATRIX' ./*.md | tr '\n' ' ')
count=$(printf '%s' "$routers" | wc -w)
if [ "$count" -eq 1 ]; then
  pass "routing lives in exactly one file: $routers"
else
  fail "$count files carry a routing table: $routers"
fi

note ''
note '=============================================================================='
if [ "$fails" -eq 0 ]; then
  note "ALL CHECKS PASSED"
else
  note "$fails CHECK(S) FAILED — see FAIL lines above"
fi
note '=============================================================================='
exit "$fails"
