#!/usr/bin/env bash
# R11 check 4 - the platform facts this decision rests on, asserted OFFLINE
# against snapshots committed under review/evidence/snapshots/. The snapshots
# were fetched once on 2026-09-18 from
#   https://raw.githubusercontent.com/github/docs/<SHA>/<path>
# at SHA 1fa3a6df3560daedd7c8a69e8eff1a730b58c1af. They are read here rather
# than re-fetched, so this script is reproducible without a network and a
# rendered page that reorders a list cannot move the result.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SNAP="$HERE/snapshots"
GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

# sha256 of each snapshot as fetched, so a later edit to a snapshot is caught.
check_sha() {
  s_name="$1"; s_want="$2"
  s_file="$SNAP/$s_name"
  if [ ! -f "$s_file" ]; then
    fail "P0 snapshot $s_name is missing"
    return 1
  fi
  s_got="$(shasum -a 256 "$s_file" | cut -d' ' -f1)"
  if [ "$s_got" = "$s_want" ]; then
    pass "P0 $s_name sha256 $s_got matches the value recorded when it was fetched"
    return 0
  fi
  fail "P0 $s_name sha256 is $s_got, recorded $s_want - the snapshot has been edited since it was fetched"
  return 1
}

check_sha troubleshooting-required-status-checks.md \
  9b5561c1111ad4a6e3430d1656cc17d7f923539794df8224638952984e1e2990 || true
check_sha path-filtering-required-workflows.md \
  c6e62dacda695e578bae48e956372ef541fd097a6dfc4d14fbe61a0869c47c5d || true
check_sha section-using-jobs-in-a-workflow-needs.md \
  cbee2b26a5e4f1f63ae514ccf3d9fa01dc8405da04c94364a65263a5e42d5cfa || true
check_sha contexts.md \
  7dd35d881dc2502922b2911b8f620542cb9fe174236a414bc02481089f3d2aac || true

assert_in() {
  a_id="$1"; a_file="$2"; a_text="$3"; a_says="$4"
  if [ ! -f "$SNAP/$a_file" ]; then
    skip "$a_id snapshot $a_file is absent, so this assertion is unrun"
    return
  fi
  if "$GREP" -qF "$a_text" "$SNAP/$a_file"; then
    pass "$a_id $a_says"
  else
    fail "$a_id '$a_text' is NOT in $a_file - $a_says"
  fi
}

assert_absent() {
  a_id="$1"; a_file="$2"; a_text="$3"; a_says="$4"
  if "$GREP" -qF "$a_text" "$SNAP/$a_file"; then
    fail "$a_id '$a_text' unexpectedly IS in $a_file - $a_says"
  else
    pass "$a_id $a_says"
  fi
}

# P1 - the fact that removes alternative D outright.
assert_in P1a troubleshooting-required-status-checks.md \
  'Associated checks stay in a "Pending" state and block merging' \
  'a workflow skipped by path filtering leaves its checks Pending and BLOCKS MERGING'
assert_in P1b troubleshooting-required-status-checks.md \
  'A job is skipped by a conditional | The job reports "Success"' \
  'a job skipped by a conditional reports SUCCESS - the two skips are different outcomes on the same vendor page'
# shellcheck disable=SC2016  # the backticks are markdown code spans inside quoted documentation text, not command substitutions
assert_in P1c troubleshooting-required-status-checks.md \
  'Successful check statuses are `success`, `skipped`, and `neutral`' \
  'skipped is one of the three successful check statuses'
assert_in P1d path-filtering-required-workflows.md \
  'You should not use path or branch filtering to skip workflow runs if the workflow is required to pass before merging' \
  "GitHub's own instruction against on.<event>.paths on a required workflow, verbatim"
assert_absent P1e troubleshooting-required-status-checks.md \
  'A job is skipped by a conditional | The job reports "Pending"' \
  'the page does NOT say a conditionally skipped job reports Pending - the negative control on P1b'

# P2 - the skip-propagation rule that makes a gated job skip when plan skips.
assert_in P2a section-using-jobs-in-a-workflow-needs.md \
  'If a job fails or is skipped, all jobs that need it are skipped unless the jobs use a conditional expression that causes the job to continue' \
  'a failed or skipped dependency skips its dependents unless they opt out'
# shellcheck disable=SC2016  # the backticks are markdown code spans inside quoted documentation text, not command substitutions
assert_in P2b troubleshooting-required-status-checks.md \
  'Use `always()` with `needs` for required checks that depend on other jobs' \
  "the platform's own instruction for an aggregate required check - R12's rule, inherited from this file's job ids"

# P3 - why the predicate must be positive.
assert_in P3a contexts.md \
  '"result": "failure",' \
  "the needs-context worked example shows a non-successful job"
assert_in P3b contexts.md \
  '"outputs": {}' \
  'and its outputs are an EMPTY MAP, so needs.<job>.outputs.<key> is the empty string; the empty string != the literal false, which is why a negated gate runs the heavy job in exactly the case the gate exists to prevent'

# P4 - the context table row that makes a credential gate a preflight job,
# independently reproduced by negative control NC3 in r11-actionlint.sh.
# shellcheck disable=SC2016  # the backticks are markdown code spans inside quoted documentation text, not command substitutions
assert_in P4a contexts.md \
  '| `jobs.<job_id>.if` | `github, needs, vars, inputs` |' \
  'a job-level if: may read github, needs, vars and inputs - and not secrets'

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
