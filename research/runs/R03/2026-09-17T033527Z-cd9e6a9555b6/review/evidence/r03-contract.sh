#!/usr/bin/env bash
# shellcheck disable=SC2016
#   SC2016 is disabled file-wide and deliberately: every single-quoted
#   search string below is a literal quotation of a source file, a
#   registry cell or a compiler message, and the backticks, `$` signs and
#   Markdown emphasis inside them must NOT expand. Single quotes are the
#   point, not an oversight.
#
# R03 port-absence-vs-failure-contract — synthesizer check 1 of 3.
#
# Verifies the record-level claims this decision makes: the five `- assumes`
# lines are byte-identical to the current registry, R03 owns nothing, the run's
# inputs match the registry on every row this item consumes, the two published
# prerequisites are the ones `inputs/prerequisites.json` pins, and every
# `PortError` variant this decision proposes lands on an R67 catalogue row that
# already exists. Implements nothing: no template module, no port, no adapter.
#
# Determinism contract
# --------------------
#   * Every input is a file inside this repository, read relative to this
#     script's own location, so the script runs unchanged inside a
#     `git archive HEAD` extraction. Nothing is read from the network and
#     nothing is read from `.git`.
#   * No machine-dependent text reaches stdout — no paths outside the
#     repository, no timestamps, no hostnames. So
#     `bash r03-contract.sh | diff - r03-contract.log` is empty on any rerun.
#
# Usage: bash r03-contract.sh          (run from anywhere)

set -uo pipefail

GREP=/usr/bin/grep
HERE=$(cd -- "$(dirname -- "$0")" && pwd)
EVID="$HERE"
RUN=$(cd -- "$EVID/../.." && pwd)
REPO=$(cd -- "$RUN/../../../.." && pwd)

REGISTRY="$REPO/docs/port/PARAMETERS.md"
INPUT_REGISTRY="$RUN/inputs/PARAMETERS.md"
PROMPT="$RUN/inputs/prompt.md"
PREREQ="$RUN/inputs/prerequisites.json"
DECISION="$RUN/review/DECISION.md"
R01="$REPO/research/topics/01-ports-and-adapters-seam/DECISION.md"
R67="$REPO/research/topics/67-error-and-exit-code-contract/DECISION.md"
LEDGER="$REPO/docs/port/COMMONALITY.md"
INDEX="$REPO/research/CLAUDE.md"

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

FAILED=0
section() { printf '\n========== %s ==========\n' "$1"; }
claim()   { printf '\n--- %s ---\n' "$1"; }
skip()    { printf 'SKIP %s — %s\n' "$1" "$2"; }

# assert <label> <expected> <actual>
assert() {
  if [ "$2" = "$3" ]; then
    printf 'PASS %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
  else
    printf 'FAIL %s (expected %s, got %s; binary: %s)\n' "$1" "$2" "$3" "$GREP"
    FAILED=$((FAILED + 1))
  fi
}

# count <file> <fixed-string>  — match count, binary named by assert
count() { $GREP -c -F -- "$2" "$1" 2>/dev/null || true; }

# param_value <registry-file> <param-name>  — the registry row's `value` cell
param_value() {
  awk -F'|' -v want="$2" '
    /^\| / && NF == 7 {
      name = $2; val = $5
      gsub(/^ +| +$/, "", name); gsub(/^ +| +$/, "", val)
      if (name == want) { print val; found = 1 }
    }
    END { if (!found) exit 3 }
  ' "$1"
}

# A partial extraction (the run directory alone) has no docs/ or research/topics/
# tree to read. Say so by name once, rather than failing every assertion.
if [ ! -f "$REGISTRY" ] || [ ! -f "$R67" ]; then
  skip 'every repository-file check' \
    'this extraction contains the run directory only; docs/port/ and research/topics/ are absent. Extract the whole tree (git archive HEAD) and rerun.'
  printf '\n========== RESULT ==========\nSKIPPED (partial extraction)\n'
  exit 0
fi

section '1. The five `- assumes` values, byte-for-byte against the registry'

# The validator reads everything after `= ` and compares it with the registry
# cell. So the expected block is generated from the registry, never typed.
: > "$WORK/expected-assumes.txt"
for p in msrv-policy rust-edition target-os-matrix license error-taxonomy-exit-codes; do
  v=$(param_value "$REGISTRY" "$p")
  st=$?
  if [ "$st" -ne 0 ]; then
    printf 'FAIL registry row missing: %s\n' "$p"
    FAILED=$((FAILED + 1))
    continue
  fi
  printf -- '- assumes %s = %s\n' "$p" "$v" >> "$WORK/expected-assumes.txt"
done
assert 'registry rows extracted (5 fixed+consumed)' 5 "$(wc -l < "$WORK/expected-assumes.txt" | tr -d ' ')"

claim 'each generated line, keyed and length-checked (the value text itself is in the registry, not repeated here)'
while IFS= read -r line; do
  key=${line#- assumes }
  key=${key%% = *}
  printf '%-28s %6s bytes\n' "$key" "$(printf '%s' "$line" | wc -c | tr -d ' ')"
done < "$WORK/expected-assumes.txt"

claim 'DECISION.md carries exactly those five lines and no others'
if [ -f "$DECISION" ]; then
  $GREP -F -- '- assumes ' "$DECISION" > "$WORK/actual-assumes.txt" || true
  assert 'decision `- assumes` line count' 5 "$(wc -l < "$WORK/actual-assumes.txt" | tr -d ' ')"
  if diff -q "$WORK/expected-assumes.txt" "$WORK/actual-assumes.txt" > /dev/null 2>&1; then
    assert 'decision `- assumes` block byte-identical to registry' same same
  else
    assert 'decision `- assumes` block byte-identical to registry' same differs
    diff "$WORK/expected-assumes.txt" "$WORK/actual-assumes.txt" | head -20
  fi
  assert 'decision `- owns ` line count' 0 "$(count "$DECISION" '- owns ')"
else
  skip 'decision-file checks' 'review/DECISION.md not present yet'
fi

section '2. R03 owns no registry parameter'

claim 'the prompt `## Couplings` block'
$GREP -n -E '^- (id|owns|consumes|effort|engines):' "$PROMPT"
assert 'prompt `- owns:` line is empty' 1 "$($GREP -c -x -- '- owns:' "$PROMPT")"
assert 'prompt consumes exactly R67 error-taxonomy-exit-codes' 1 \
  "$($GREP -c -x -- '- consumes: R67: error-taxonomy-exit-codes' "$PROMPT")"

claim 'the registry names no R03-owned row, and the index records `—`'
assert 'registry rows whose owner cell is R03' 0 \
  "$(awk -F'|' '/^\| / && NF == 7 { o = $4; gsub(/^ +| +$/, "", o); if (o == "R03") n++ } END { print n + 0 }' "$REGISTRY")"
$GREP -n '^| R03 |' "$INDEX"
assert 'index R03 row owns column is an em dash' 1 \
  "$($GREP -c -F -- '| R03 | port-absence-vs-failure-contract | pattern | different | DIVERGENT | — |' "$INDEX")"

section '3. The run inputs against the current registry'

claim 'inputs/PARAMETERS.md vs docs/port/PARAMETERS.md — which rows differ'
diff "$INPUT_REGISTRY" "$REGISTRY" > "$WORK/registry.diff" 2>&1
awk -F'|' '/^[<>] \| / && NF == 7 { m = $1; gsub(/^[<>] \| +| +$/, "", m); print substr($0,1,1) " " m }' "$WORK/registry.diff"
assert 'differing rows all name web-extra-surface' 0 \
  "$(awk -F'|' '/^[<>] \| / && NF == 7 { m = $2; gsub(/^ +| +$/, "", m); if (m != "web-extra-surface") n++ } END { print n + 0 }' "$WORK/registry.diff")"

claim 'every row this item consumes is byte-identical in both files'
for p in msrv-policy rust-edition target-os-matrix license error-taxonomy-exit-codes; do
  a=$(param_value "$INPUT_REGISTRY" "$p")
  b=$(param_value "$REGISTRY" "$p")
  if [ "$a" = "$b" ]; then
    assert "input row identical: $p" same same
  else
    assert "input row identical: $p" same differs
  fi
done

section '4. The two published prerequisites are the ones the run pins'

for pair in "R01 $R01" "R67 $R67"; do
  id=${pair%% *}
  path=${pair#* }
  want=$($GREP -A2 "\"$id\"" "$PREREQ" | $GREP '"decision"' | sed 's/.*"decision": "//; s/".*//')
  got=$(shasum -a 256 "$path" | cut -d' ' -f1)
  assert "$id topic DECISION.md sha256 matches inputs/prerequisites.json" "$want" "$got"
done

section '5. Every failure this pattern can produce lands on an existing R67 row'

claim 'the catalogue rows and the exit integers this decision cites, read from the registry cell'
param_value "$REGISTRY" error-taxonomy-exit-codes > "$WORK/r67.txt"
for s in '`RSLB000` unexpected → 1' \
         '`RSLB101` I/O → 1' \
         '`RSLB102` transport (DNS/connect/timeout/TLS) → 1' \
         '`RSLB103` remote-API failure → 1' \
         '`RSLB301` resource not found → 3' \
         '`RSLB402` credentials rejected → 4' \
         '`RSLB501` conflict/precondition failed → 5'; do
  assert "R67 row present: $s" 1 "$(count "$WORK/r67.txt" "$s")"
  printf '    %s\n' "$s"
done

claim 'no per-resource not-found row exists, so no second code is available to request'
assert 'RSLB302 absent from the catalogue' 0 "$(count "$WORK/r67.txt" 'RSLB302')"
assert 'append-only over a non_exhaustive enum is stated' 1 \
  "$(count "$WORK/r67.txt" 'stable and append-only')"

claim 'the two R67 clauses that settle engine disagreements 3 and 4'
assert 'main returns ExitCode, no process::exit on the error path' 1 \
  "$(count "$WORK/r67.txt" '`main` returns `ExitCode` and does not call `process::exit` on the error path')"
assert 'library crate must not depend on anyhow' 1 \
  "$(count "$WORK/r67.txt" 'the library crate must not depend on `anyhow`')"
assert 'the registry cell itself cites R7.6 (the hint field must name the offending input)' 1 \
  "$(count "$WORK/r67.txt" 'R7.6')"
claim 'and the R67 decision body states the not-found message R7.6 requires'
$GREP -n -m2 -F 'R7.6' "$R67" | cut -c1-200

section '6. The seam this pattern decorates, as R01 published it'

assert 'R01 reserves this items slot in src/core/ports.rs' 2 \
  "$(count "$R01" 'absence shape R03')"
$GREP -n -m1 -F 'the port error type (vocabulary R67's, absence shape R03's)' "$R01" | cut -c1-240
assert 'R01 routes a poisoned fake lock to PortError::Unavailable' 2 \
  "$(count "$R01" '`PortError::Unavailable`')"
assert 'R01 contemplates Json<Option<Project>> at the web handler' 2 \
  "$(count "$R01" 'Json<Option<Project>>')"

section '7. The ledger row this decision settles'

$GREP -n '^| F012 |' "$LEDGER"
assert 'F012 row is DIVERGENT and assigned to R03' 1 \
  "$(count "$LEDGER" '| F012 | Port absence-vs-failure contract | workspace-architecture | different | DIVERGENT | R03 |')"

section 'RESULT'
if [ "$FAILED" -eq 0 ]; then
  printf 'ALL CHECKS PASSED\n'
else
  printf '%s CHECK(S) FAILED\n' "$FAILED"
fi
exit "$FAILED"
