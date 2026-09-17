#!/usr/bin/env bash
# R50 revision 2 — JF-3: the retained artifact for the archive-extraction rerun.
#
# Revision 1 asserted, without keeping a log, that `r50-check.sh` still runs from
# a clean `git archive HEAD` extraction with no `.git` and skips its one
# checkout-dependent phase by name. This wrapper performs that rerun and saves
# its normalised output, so the claim is checkable rather than merely consistent.
#
# It does NOT modify `r50-check.sh` or `r50-check.log`; both are carried into
# revision 2 byte-identical. It runs the copy of `r50-check.sh` that is committed
# at HEAD, which is the point of the exercise.
#
# Stability note: the inner check reads `docs/port/PARAMETERS.md`, the run's
# `inputs/`, `docs/port/COMMONALITY.md` and `docs/port/areas/packaging-distribution.md`
# out of the same archive. Its output therefore stays constant while those files
# do; if the F222 ledger correction this decision proposes is ever applied, the
# inner phase-D assertions change and this log is expected to change with them.
#
# Every assertion prints `PASS <name>` or `FAIL <name>`; the script exits
# non-zero if any assertion failed.

set -o pipefail
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"
REL="research/runs/R50/2026-09-17T020715Z-b7ef95f12806/review/evidence/r50-check.sh"
GREP=/usr/bin/grep

FAILURES=0
fail() { printf 'FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); }

assert_count() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf 'PASS %s (count %s)\n' "$name" "$actual"
  else
    fail "$name (expected count $expected, observed $actual)"
  fi
}

assert_status() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf 'PASS %s (exit %s)\n' "$name" "$actual"
  else
    fail "$name (expected exit $expected, observed $actual)"
  fi
}

echo "=============================================================="
echo "R50 revision 2 — archive-extraction rerun of r50-check.sh"
echo "=============================================================="
echo
echo "repo root: $REPO_ROOT"
echo "inner check (from the archive): $REL"

if [ ! -e "$REPO_ROOT/.git" ]; then
  printf '\nSKIP archive-rerun/all — no .git entry at the repository root; this wrapper needs git archive\n'
  exit 0
fi

TMPBASE="${TMPDIR:-/tmp}"
SCRATCH="$(mktemp -d "${TMPBASE%/}/r50-r2-archive.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT
SCRATCH_REAL="$(cd "$SCRATCH" && pwd -P)"

norm() {
  sed -e "s#$SCRATCH_REAL#<SCRATCH>#g" -e "s#$SCRATCH#<SCRATCH>#g"
}

mkdir -p "$SCRATCH/tree" "$SCRATCH/nohome"
git -C "$REPO_ROOT" archive HEAD | tar -x -C "$SCRATCH/tree"
archive_status=$?
assert_status "archive/extract" 0 "$archive_status"

if [ -e "$SCRATCH/tree/.git" ]; then
  fail "archive/extraction-has-no-git (a .git entry is present)"
else
  printf 'PASS archive/extraction-has-no-git (no <SCRATCH>/tree/.git)\n'
fi

if [ -x "$SCRATCH/tree/$REL" ]; then
  printf 'PASS archive/inner-check-is-committed-and-executable (%s)\n' "$REL"
else
  fail "archive/inner-check-is-committed-and-executable ($REL)"
fi

# Byte-identity of the archived copy against the working tree, so the log names
# which revision of the check was rerun.
inner_sha="$(shasum -a 256 < "$SCRATCH/tree/$REL")"
tree_sha="$(shasum -a 256 < "$REPO_ROOT/$REL")"
printf 'INFO archive/inner-check-sha256 = %s\n' "${inner_sha%% *}"
if [ "$inner_sha" = "$tree_sha" ]; then
  printf 'PASS archive/inner-check-matches-the-working-tree\n'
else
  fail "archive/inner-check-matches-the-working-tree (archived ${inner_sha%% *}, working tree ${tree_sha%% *})"
fi

echo
echo "--- running the archived check with \$HOME pointed at an empty directory ---"
HOME="$SCRATCH/nohome" "$SCRATCH/tree/$REL" > "$SCRATCH/out.txt" 2>&1
inner_status=$?
norm < "$SCRATCH/out.txt"

echo
echo "--- assertions on that run -----------------------------------"
assert_status "archive-rerun/exit" 0 "$inner_status"
pass_n="$("$GREP" -c "^PASS" "$SCRATCH/out.txt")" || pass_n=0
fail_n="$("$GREP" -c "^FAIL" "$SCRATCH/out.txt")" || fail_n=0
skip_n="$("$GREP" -c "^SKIP" "$SCRATCH/out.txt")" || skip_n=0
assert_count "archive-rerun/PASS" 54 "$pass_n"
assert_count "archive-rerun/FAIL" 0 "$fail_n"
assert_count "archive-rerun/SKIP" 1 "$skip_n"
skip_named="$("$GREP" -c -F "SKIP ts-pin/all — checkout absent at" "$SCRATCH/out.txt")" || skip_named=0
assert_count "archive-rerun/the-skip-names-its-phase" 1 "$skip_named"
# The 54 is 68 minus phase C's 14 ts-pin assertions, and nothing else.
tspin_n="$("$GREP" -c "^PASS ts-pin/" "$SCRATCH/out.txt")" || tspin_n=0
assert_count "archive-rerun/no-ts-pin-assertion-ran" 0 "$tspin_n"

echo
echo "=============================================================="
if [ "$FAILURES" -eq 0 ]; then
  echo "r50-r2-archive-rerun: all assertions passed"
else
  echo "r50-r2-archive-rerun: $FAILURES assertion(s) failed"
fi
echo "=============================================================="
exit "$FAILURES"
