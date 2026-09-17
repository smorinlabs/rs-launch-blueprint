#!/usr/bin/env bash
# R02 crate-boundary-enforcement -- shape and parameter-grammar check on the
# decision this run produced.
#
# The packaging validator (scripts/research_validation.py, the block around
# `expected_assumptions = expected_fixed | expected_consumed`) reads everything
# after "= " on an `- owns`/`- assumes` line as the value and compares it
# byte-for-byte with docs/port/PARAMETERS.md, and it FAILS publication if the
# assumed set is not exactly the fixed plus consumed sets. This item's prompt
# consumes nothing, so the assumed set must be exactly the four fixed registry
# parameters -- no more, no fewer. This script asserts that mechanically rather
# than by reading, and asserts the rest of the required shape with it.
#
# It reads only committed files, never .git, so it runs unchanged from a clean
# `git archive HEAD` extraction; each check SKIPs by name if its input is absent.
#
# Exit 0 only when FAILURES is 0.

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
HERE=$(cd "$(dirname "$0")" && pwd)
REVIEW=$(cd "$HERE/.." && pwd)
RUN=$(cd "$REVIEW/.." && pwd)
REPO_ROOT=$(cd "$RUN/../../../.." && pwd)
DECISION="$REVIEW/DECISION.md"
REG="$REPO_ROOT/docs/port/PARAMETERS.md"
PROMPT="$RUN/inputs/prompt.md"

CHECKS=0
FAILURES=0
SKIPPED=0

note() { printf '\n=== %s ===\n' "$1"; }
eq() {
  local name="$1" what="$2" got="$3" want="$4"
  CHECKS=$((CHECKS + 1))
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s == %s\n' "$name" "$what" "$got"
  else
    printf 'FAIL %s: %s -- wanted [%s], got [%s]\n' "$name" "$what" "$want" "$got"
    FAILURES=$((FAILURES + 1))
  fi
}
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP %s: %s\n' "$1" "$2"; }

note "0 inputs present"
for f in "$DECISION" "$REG" "$PROMPT"; do
  if [ -f "$f" ]; then printf 'present: %s\n' "${f#"$REPO_ROOT/"}"; else printf 'ABSENT: %s\n' "$f"; fi
done

if [ ! -f "$DECISION" ]; then
  skip S1 "DECISION.md is absent from this extraction"
else
  note "1 required shape"
  eq S1a "title line" "$(head -1 "$DECISION")" \
    "# 2026-09-17 — R02 — crate-boundary-enforcement (bundle, Deep) — decision (revision 1)"
  "$GREP" -n '^## ' "$DECISION" | cut -d: -f2- > "$HERE/snapshots/decision-h2.txt"
  cat "$HERE/snapshots/decision-h2.txt"
  eq S1b "the H2 set, in order, and nothing else" \
    "$(tr '\n' '|' < "$HERE/snapshots/decision-h2.txt")" \
    "## Decision|## Parameters|## Empirical check|## Engines|"
  eq S1c "the required H3 inside ## Decision" \
    "$("$GREP" -c '^### Principles and implementation$' "$DECISION")" "1"
  eq S1d "no ## Supersedes (this is the first revision)" \
    "$("$GREP" -c '^## Supersedes' "$DECISION" || true)" "0"
  eq S1e "exactly one re-verify: line" \
    "$("$GREP" -c '^re-verify: ' "$DECISION")" "1"
  eq S1f "gate 1 recorded as inapplicable with the owner ruling as its reason" \
    "$("$GREP" -cF 'inapplicable — owner ruling 2026-09-12 (Q7.B)' "$DECISION")" "1"

  note "2 the OVERRIDE number"
  eq S2a "OV-03 is declared once as a heading" \
    "$("$GREP" -c '^### OVERRIDE (OV-03) ' "$DECISION")" "1"
  eq S2b "no second override is declared" \
    "$("$GREP" -c '^### OVERRIDE (OV-0[124-9])' "$DECISION" || true)" "0"

  note "3 the CONFLICT line"
  eq S3a "exactly one CONFLICT: line" \
    "$("$GREP" -c '^CONFLICT: ' "$DECISION")" "1"
  eq S3b "and it is R69's owned parameter" \
    "$("$GREP" -c '^CONFLICT: R69 web-extra-surface — ' "$DECISION")" "1"
  eq S3c "the CONFLICT line sits inside ## Parameters, after the assumes list" \
    "$(awk '/^## Parameters$/{p=1} /^## Empirical check$/{p=0} p && /^CONFLICT: /{n++} END{print n+0}' "$DECISION")" "1"
fi

if [ ! -f "$DECISION" ] || [ ! -f "$REG" ]; then
  skip S4 "DECISION.md or docs/port/PARAMETERS.md is absent from this extraction"
else
  note "4 the ## Parameters grammar the packaging validator enforces"
  awk -F'|' 'NF>=6 && $3 ~ /fixed/ {gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$5); print "- assumes "$2" = "$5}' \
    "$REG" | sort > "$HERE/snapshots/expected-assumes.txt"
  "$GREP" '^- assumes ' "$DECISION" | sort > "$HERE/snapshots/actual-assumes.txt"
  printf 'expected (from the live registry):\n'; cat "$HERE/snapshots/expected-assumes.txt"
  printf 'actual (from DECISION.md):\n'; cat "$HERE/snapshots/actual-assumes.txt"
  CHECKS=$((CHECKS + 1))
  if diff -u "$HERE/snapshots/expected-assumes.txt" "$HERE/snapshots/actual-assumes.txt"; then
    printf 'PASS S4a: every assumes line is byte-identical to its registry row, and the set matches exactly\n'
  else
    printf 'FAIL S4a: the assumes list does not match the registry byte-for-byte\n'
    FAILURES=$((FAILURES + 1))
  fi
  eq S4b "no owns line, because the prompt's - owns: line carries no parameter" \
    "$("$GREP" -c '^- owns ' "$DECISION" || true)" "0"
  eq S4c "no assumes line carries a backtick, a citation or trailing commentary" \
    "$("$GREP" -c '^- assumes [a-z0-9-]* = .*[`(]' "$DECISION" || true)" "0"
fi

if [ ! -f "$PROMPT" ]; then
  skip S5 "inputs/prompt.md is absent from this extraction"
else
  note "5 the prompt's couplings, which decide the parameter sets above"
  eq S5a "the prompt's - owns: line carries no parameter" \
    "$("$GREP" -c '^- owns: *$' "$PROMPT")" "1"
  eq S5b "the prompt's - consumes: line carries no parameter" \
    "$("$GREP" -c '^- consumes: *$' "$PROMPT")" "1"
  eq S5c "control -- the prompt really does have a Couplings section, so the two zeros are not vacuous" \
    "$("$GREP" -c '^## Couplings$' "$PROMPT")" "1"
fi

note "6 nothing was built, and no private address was written"
find "$RUN" \( -name '*.rs' -o -name 'Cargo.toml' -o -name 'Cargo.lock' \) -print \
  > "$HERE/snapshots/run-rust-artifacts.txt" 2>/dev/null || true
cat "$HERE/snapshots/run-rust-artifacts.txt"
eq S6a "no Rust or Cargo artifact anywhere in the run directory (P03 builds; this run scaffolds nothing)" \
  "$(wc -l < "$HERE/snapshots/run-rust-artifacts.txt" | tr -d ' ')" "0"
find "$RUN" -type d \( -name src -o -name target \) -print \
  > "$HERE/snapshots/run-rust-dirs.txt" 2>/dev/null || true
eq S6b "and no src/ or target/ directory either" \
  "$(wc -l < "$HERE/snapshots/run-rust-dirs.txt" | tr -d ' ')" "0"
# The pattern is assembled at run time so that this script does not itself
# contain the literal it searches for, which would make the check self-matching.
PRIVATE_DOMAIN="concept""m.com"
CHECKS=$((CHECKS + 1))
if "$GREP" -rqF -- "@$PRIVATE_DOMAIN" "$REVIEW"; then
  printf 'FAIL S6c: a personal address appears somewhere under review/\n'
  "$GREP" -rlF -- "@$PRIVATE_DOMAIN" "$REVIEW"
  FAILURES=$((FAILURES + 1))
else
  # The matched pattern is deliberately NOT echoed: printing it would write the
  # literal into this log and make the next run of this check find itself.
  printf 'PASS S6c: no personal address under review/ (by %s -rqF over the whole directory, searching for an at-sign followed by the owner private domain assembled at run time)\n' "$GREP"
fi
CHECKS=$((CHECKS + 1))
if "$GREP" -rqE -- 'gh[pousr]_[A-Za-z0-9]{16,}' "$REVIEW"; then
  printf 'FAIL S6d: a GitHub token-shaped string appears under review/\n'
  FAILURES=$((FAILURES + 1))
else
  printf 'PASS S6d: no GitHub token-shaped string under review/\n'
fi

note "7 every evidence artifact this decision cites is present"
for f in r02-workspace-probe.sh r02-workspace-probe.log \
         r02-ecosystem-figures.sh r02-ecosystem-figures.log \
         r02-cargo-deny-bans.sh r02-cargo-deny-bans.log \
         r02-decision-shape.sh; do
  CHECKS=$((CHECKS + 1))
  if [ -f "$HERE/$f" ]; then
    printf 'PASS S7-%s: present\n' "$f"
  else
    printf 'FAIL S7-%s: absent\n' "$f"
    FAILURES=$((FAILURES + 1))
  fi
done
for s in r02-workspace-probe r02-ecosystem-figures r02-cargo-deny-bans; do
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qE '^CHECKS RUN: [0-9]+ FAILURES: 0' "$HERE/$s.log"; then
    printf 'PASS S7-%s.log: its own summary records zero failures -- %s\n' \
      "$s" "$("$GREP" -E '^CHECKS RUN: ' "$HERE/$s.log")"
  else
    printf 'FAIL S7-%s.log: summary line missing or non-zero failures\n' "$s"
    FAILURES=$((FAILURES + 1))
  fi
done

note "8 every check label the decision cites resolves to a real PASS line"
if [ ! -f "$DECISION" ]; then
  skip 8 "DECISION.md is absent from this extraction"
else
  # Labels are namespaced: EF* (ecosystem figures), CD* (cargo-deny), S* (this
  # script), and the bare letters A/B#/C#/D#/E/F/G/H (workspace probe). Pull
  # every label the decision cites out of its backticks and resolve each one.
  # shellcheck disable=SC2016  # the pattern is a regex containing backticks; it must not expand
  "$GREP" -oE '`(EF[0-9][A-Za-z0-9_.-]*|CD[0-9][a-z]?|S[0-9][a-z]?|[A-H][0-9]?)`' "$DECISION" \
    | tr -d '`' | sort -u > "$HERE/snapshots/decision-cited-labels.txt"
  printf 'labels cited by the decision: %s\n' \
    "$(tr '\n' ' ' < "$HERE/snapshots/decision-cited-labels.txt")"
  unresolved=0
  while read -r lab; do
    [ -n "$lab" ] || continue
    case "$lab" in
      EF*) src="$HERE/r02-ecosystem-figures.log" ;;
      CD*) src="$HERE/r02-cargo-deny-bans.log" ;;
      S*)  src="$HERE/r02-decision-shape.sh" ;;   # this script's own labels, by definition
      *)   src="$HERE/r02-workspace-probe.log" ;;
    esac
    if [ ! -f "$src" ]; then unresolved=$((unresolved + 1)); printf '  UNRESOLVED %s: %s absent\n' "$lab" "$src"; continue; fi
    case "$lab" in
      S*) "$GREP" -qE "(^|[ \"'])${lab}[ :\"]" "$src" || { unresolved=$((unresolved + 1)); printf '  UNRESOLVED %s (not defined in this script)\n' "$lab"; } ;;
      *)  "$GREP" -qE "^PASS $lab:" "$src" || { unresolved=$((unresolved + 1)); printf '  UNRESOLVED %s (no PASS line in %s)\n' "$lab" "$(basename "$src")"; } ;;
    esac
  done < "$HERE/snapshots/decision-cited-labels.txt"
  eq S8a "cited labels that do not resolve to a PASS line (or, for this script's own, to a definition)" \
    "$unresolved" "0"
  n=$(wc -l < "$HERE/snapshots/decision-cited-labels.txt" | tr -d ' ')
  CHECKS=$((CHECKS + 1))
  if [ "$n" -ge 40 ]; then
    printf 'PASS S8b: the decision cites %s distinct check labels, so the zero above is not a vacuous scan\n' "$n"
  else
    printf 'FAIL S8b: only %s distinct labels found; the resolver may not be matching the decision text\n' "$n"
    FAILURES=$((FAILURES + 1))
  fi
fi

note "SUMMARY"
printf 'CHECKS RUN: %s FAILURES: %s SKIPPED: %s\n' "$CHECKS" "$FAILURES" "$SKIPPED"
[ "$FAILURES" -eq 0 ]
