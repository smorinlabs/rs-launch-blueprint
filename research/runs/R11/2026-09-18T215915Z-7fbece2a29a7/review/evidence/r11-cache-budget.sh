#!/usr/bin/env bash
# R11 check 3 - the cache-entry arithmetic, computed from the fixture rather
# than asserted, and checked against the threshold R10's accepted decision
# wrote down before this item existed. This check also settles a disagreement
# with R10's own shorthand: see B4.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
ROOT="$(cd "$HERE/../../../../../.." && pwd)"
FIXTURE="$HERE/ci.candidate.yml"
R10="$ROOT/research/runs/R10/2026-09-17T020715Z-b3b67fdb5328/review/DECISION.md"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

for f in "$FIXTURE" "$R10"; do
  if [ ! -f "$f" ]; then
    fail "B0 required input is missing: $f"
    printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
    exit 1
  fi
done
pass "B0 the fixture and R10's accepted decision are both readable"

# --- derive, per job id, whether it carries a rust-cache step and how many
#     runners it runs on -----------------------------------------------------
TABLE="$(awk '
  /^jobs:$/ { inside = 1; next }
  inside && /^  [a-z][a-z-]*:$/ {
    if (job != "") print job, cached, runners
    job = $1; sub(/:$/, "", job); cached = 0; runners = 1; next
  }
  inside && /Swatinem\/rust-cache@/ { cached = 1 }
  inside && /^        os: \[/ {
    n = split($0, parts, ",")
    runners = n
  }
  END { if (job != "") print job, cached, runners }
' "$FIXTURE")"

printf 'INFO per-job table (job cached runners):\n%s\n' "$TABLE"

CACHED_IDS="$(printf '%s\n' "$TABLE" | awk '$2 == 1 {print $1}' | sort | tr '\n' ' ')"
if [ "$CACHED_IDS" = "check install-smoke msrv-floor " ]; then
  pass "B1 exactly three job ids carry a rust-cache step: check install-smoke msrv-floor. plan, hygiene and workflow-lint compile nothing and carry none"
else
  fail "B1 cache-bearing job ids are '$CACHED_IDS', expected 'check install-smoke msrv-floor '"
fi

ENTRIES="$(printf '%s\n' "$TABLE" | awk '$2 == 1 {sum += $3} END {print sum + 0}')"
if [ "$ENTRIES" -eq 4 ]; then
  pass "B2 the design claims 4 cache-bearing job-runner pairs, and summing the table gives 4: check x 2 runners, msrv-floor x 1, install-smoke x 1"
else
  fail "B2 the table sums to $ENTRIES job-runner pairs, not the 4 the decision states"
fi

# Per-runner counts, which is the unit R10's threshold is expressed in.
UBUNTU="$(printf '%s\n' "$TABLE" | awk '$2 == 1 {n += 1} END {print n + 0}')"
MACOS="$(printf '%s\n' "$TABLE" | awk '$2 == 1 && $3 == 2 {n += 1} END {print n + 0}')"
if [ "$UBUNTU" -eq 3 ] && [ "$MACOS" -eq 1 ]; then
  pass "B3 cache-bearing job ids per runner: ubuntu-latest 3, macos-latest 1. Total job ids in the file: 6"
else
  fail "B3 per-runner cache-bearing job ids are ubuntu $UBUNTU / macos $MACOS, expected 3 / 1"
fi

# --- B4: the disagreement with R10's own shorthand -------------------------
if "$GREP" -qF "the entry count against the storage budget is two times the number" "$R10"; then
  pass "B4a R10's decision does say 'the entry count against the storage budget is two times the number of job ids'"
else
  fail "B4a R10's 'two times the number of job ids' sentence is not present at the path this check reads"
fi
TWO_TIMES=$(( 3 * 2 ))
if [ "$TWO_TIMES" -ne "$ENTRIES" ]; then
  pass "B4b R10's shorthand applied to this design gives $TWO_TIMES, the computed figure is $ENTRIES. The shorthand is the special case where EVERY cache-bearing job is matrixed across both entries of target-os-matrix; msrv-floor and install-smoke are single-runner, so the general formula is the sum over cache-bearing job ids of that job id's runner count"
else
  fail "B4b the two figures coincide, so this check establishes nothing about the formula"
fi

# --- B5: R10's threshold ---------------------------------------------------
if "$GREP" -qF "R11 resolving with a job count materially above six per OS" "$R10"; then
  pass "B5a R10's re-verify line names the threshold: 'R11 resolving with a job count materially above six per OS'"
else
  fail "B5a R10's six-per-OS threshold sentence is not present"
fi
ALL_IDS="$(printf '%s\n' "$TABLE" | awk 'NF {n += 1} END {print n + 0}')"
if [ "$UBUNTU" -le 6 ] && [ "$ALL_IDS" -le 6 ]; then
  pass "B5b this design is under the threshold on both readings: $UBUNTU cache-bearing job ids on the busier runner, and $ALL_IDS job ids in the file"
else
  fail "B5b this design is over R10's threshold"
fi

# --- B6: alternative B, one job per check, for the same check list ----------
# The twelve slots the raw report enumerates: fmt, clippy, test-feature-off,
# test-feature-on, doc, build-serve, install-smoke, msrv, coverage, deny,
# docs-gate, openapi-snapshot.
ALT_B=12
if [ "$ALT_B" -gt 6 ]; then
  pass "B6 alternative B (one job per check) is $ALT_B job ids for this template's slot list against this design's 6, so it crosses R10's threshold by construction rather than by measurement"
else
  fail "B6 the alternative-B count is not above the threshold, so the argument against it does not stand on this ground"
fi

# --- B7: the matrix caveat R10 handed here ---------------------------------
if "$GREP" -qF "does not include matrix values" "$R10"; then
  pass "B7a R10 assertion A3.6: add-job-id-key reads GITHUB_JOB, which 'does not include matrix values'"
else
  fail "B7a R10's matrix-values sentence is not present"
fi
MATRIX_DIMS="$("$GREP" -cE '^        (os|[a-z]+): \[' "$FIXTURE")"
if [ "$MATRIX_DIMS" -eq 1 ] && "$GREP" -qE '^        os: \[ubuntu-latest, macos-latest\]$' "$FIXTURE"; then
  pass "B7b the fixture declares exactly one matrix dimension and it is os: [ubuntu-latest, macos-latest], so no leg changes the build graph without changing the key - no extra key: segment is needed"
else
  fail "B7b the fixture declares $MATRIX_DIMS matrix dimension(s); a non-os dimension would need R10's extra key: segment"
fi
if "$GREP" -q 'features: \[' "$FIXTURE"; then
  fail "B7c the fixture contains a Cargo-feature matrix dimension, which is the exact collision R10 warned about"
else
  pass "B7c the fixture contains no Cargo-feature matrix dimension; the two feature configurations are ordered STEPS of one job sharing one target/"
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
