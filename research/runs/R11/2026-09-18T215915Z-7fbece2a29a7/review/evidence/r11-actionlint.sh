#!/usr/bin/env bash
# R11 check 1 - actionlint against the candidate job graph, plus five negative
# controls. Every control asserts that its mutation actually changed the file
# BEFORE linting, because a mutation that silently fails to apply turns a
# control into a false pass (the Opus raw recorded exactly that failure with a
# BSD `sed` and a GNU `0,/re/` address range).
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
FIXTURE="$HERE/ci.candidate.yml"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

TMPROOT="$(mktemp -d "${TMPDIR:-/tmp}/r11-actionlint.XXXXXX")"
trap 'rm -rf "$TMPROOT"' EXIT

AL="$(command -v actionlint || true)"
if [ -z "$AL" ]; then
  skip "A0 actionlint is not on PATH - every actionlint assertion in this script is unrun"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
fi

AL_VERSION="$("$AL" -version | head -1)"
if [ "$AL_VERSION" = "1.7.12" ]; then
  pass "A0 actionlint version is 1.7.12 at $AL"
else
  fail "A0 actionlint version is '$AL_VERSION' at $AL, expected 1.7.12 - every diagnostic below is that build's, not 1.7.12's"
fi

SC="$(command -v shellcheck || true)"
if [ -n "$SC" ]; then
  pass "A0b shellcheck is on PATH at $SC, so actionlint's shellcheck integration is active on every run: block"
else
  skip "A0b shellcheck is not on PATH - actionlint lints the run: blocks without it"
fi

if [ -f "$FIXTURE" ]; then
  pass "A1 the candidate fixture exists at review/evidence/ci.candidate.yml"
else
  fail "A1 the candidate fixture is missing at $FIXTURE"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
fi

FIX_SHA="$(shasum -a 256 "$FIXTURE" | cut -d' ' -f1)"
FIX_LINES="$(wc -l < "$FIXTURE" | tr -d ' ')"
printf 'INFO fixture sha256=%s lines=%s\n' "$FIX_SHA" "$FIX_LINES"

# --- the control -----------------------------------------------------------
CTRL_OUT="$TMPROOT/control.out"
set +e
"$AL" -no-color -oneline "$FIXTURE" > "$CTRL_OUT" 2>&1
CTRL_EXIT=$?
set -e
if [ "$CTRL_EXIT" -eq 0 ] && [ ! -s "$CTRL_OUT" ]; then
  pass "A2 CONTROL: actionlint exits 0 with no diagnostic on the unmutated candidate"
else
  fail "A2 CONTROL: actionlint exit=$CTRL_EXIT with $(wc -l < "$CTRL_OUT" | tr -d ' ') diagnostic line(s): $(head -2 "$CTRL_OUT")"
fi

# A control that cannot fail is not evidence: assert the six job ids the
# decision names are the six job ids the linted file actually declares.
JOBIDS="$(awk '/^jobs:$/{inside=1; next} inside && /^  [a-z][a-z-]*:$/{gsub(/[ :]/,""); print}' "$FIXTURE" | sort | tr '\n' ' ')"
if [ "$JOBIDS" = "check hygiene install-smoke msrv-floor plan workflow-lint " ]; then
  pass "A3 the linted file declares exactly the six job ids check hygiene install-smoke msrv-floor plan workflow-lint"
else
  fail "A3 job ids are '$JOBIDS', not the six the decision names"
fi

# --- the negative controls -------------------------------------------------
# run_nc <id> <sed-expression> <expected-exit> <expected-substring> <what it establishes>
run_nc() {
  nc_id="$1"; nc_sed="$2"; nc_exit="$3"; nc_sub="$4"; nc_says="$5"
  nc_file="$TMPROOT/$nc_id.yml"
  sed "$nc_sed" "$FIXTURE" > "$nc_file"
  if cmp -s "$FIXTURE" "$nc_file"; then
    fail "$nc_id MUTATION DID NOT APPLY - the file is byte-identical to the fixture, so this control proves nothing"
    return
  fi
  nc_out="$TMPROOT/$nc_id.out"
  set +e
  "$AL" -no-color -oneline "$nc_file" > "$nc_out" 2>&1
  nc_got=$?
  set -e
  if [ "$nc_got" -ne "$nc_exit" ]; then
    fail "$nc_id exit=$nc_got, expected $nc_exit ($nc_says)"
    return
  fi
  if [ -z "$nc_sub" ]; then
    pass "$nc_id mutation applied; actionlint exit=$nc_got with $(wc -l < "$nc_out" | tr -d ' ') diagnostic line(s) - $nc_says"
    return
  fi
  if "$GREP" -qF "$nc_sub" "$nc_out"; then
    pass "$nc_id mutation applied; actionlint exit=$nc_got and the diagnostic contains '$nc_sub' - $nc_says"
  else
    fail "$nc_id exit matched but the diagnostic does not contain '$nc_sub': $(head -1 "$nc_out")"
  fi
}

run_nc NC1 's/needs\.plan\.outputs\.code/needs.plan.outputs.codee/g' 1 \
  'property "codee" is not defined in object type' \
  "a misspelled relayed output name is type-checked against the producing job's declared outputs:, so a renamed key cannot silently disable a gate"

run_nc NC2 "s/== 'true'/!= 'false'/g" 0 '' \
  "THE FINDING: actionlint does NOT reject the fail-open negated predicate, so the positive-predicate rule must travel in prose to R12, R13 and every other consumer"

run_nc NC3 "s|needs.plan.outputs.workflows == 'true'|secrets.SOME_TOKEN != ''|" 1 \
  'context "secrets" is not allowed here' \
  "a job-level if: cannot read secrets, which is why a credential gate is a preflight JOB - the same structural device as this item's detector job"

run_nc NC4 's/needs: plan$/needs: planx/' 1 \
  'which does not exist in this workflow' \
  "the needs graph itself is checked, so a job renamed out from under a gate fails the lint"

run_nc NC5 's/set -euo pipefail/set -eu/' 0 '' \
  "actionlint does NOT reject a detector body without pipefail either, so the detector's own set -euo pipefail is a design rule this toolchain does not enforce"

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
