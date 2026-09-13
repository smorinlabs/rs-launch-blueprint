#!/usr/bin/env bash
# R19 — negative control for r19-check-5f.sh.
#
# "A check that cannot fail is not evidence." This script proves the sibling
# checker can fail: it copies the committed snapshot to a scratch directory,
# appends the literal `rust-version` to one file in the corpus, runs the checker
# there, and asserts that the run exits 1 with exactly the two expected failures
# — the blob-sha integrity check and the zero-occurrence check. The committed
# snapshot is never modified.
#
#   bash research/runs/R19/2026-09-06T043454Z-33c81db94a3b/review/evidence/r19-check-5f-negative-control.sh
set -uo pipefail

FAILS=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS+1)); }
hdr()  { printf '\n===== %s =====\n' "$1"; }

E="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/r19-negctl.XXXXXX")"
trap 'rm -rf "$T"' EXIT

hdr "0. Setup"
date -u '+run-utc %Y-%m-%dT%H:%M:%SZ'
printf 'scratch copy %s\n' "$T"
cp -R "$E/dependabot-core-1abafc5c" "$E/issue-5423.json" "$E/issue-5423.retrieved" "$E/r19-check-5f.sh" "$T/"
TAMPER="$T/dependabot-core-1abafc5c/cargo/lib/dependabot/cargo/update_checker.rb"
printf '# rust-version\n' >> "$TAMPER"
printf 'tampered: appended "# rust-version" to cargo/lib/dependabot/cargo/update_checker.rb\n'

hdr "1. Run the checker against the tampered copy"
bash "$T/r19-check-5f.sh" > "$T/out.log" 2>&1
RC=$?
printf 'checker exit status %s\n' "$RC"
grep -E '^FAIL |^failed assertions' "$T/out.log"

hdr "2. Assertions about the failure"
[ "$RC" -eq 1 ] \
  && pass "the checker exits 1 when its snapshot is tampered with" \
  || fail "the checker exited $RC, expected 1"
grep -qF 'FAIL  snapshot does not re-derive the pin'"'"'s blob shas (21 read, 1 defective)' "$T/out.log" \
  && pass "the blob-sha integrity check caught the edit" \
  || fail "the blob-sha integrity check did not catch the edit"
grep -qF 'FAIL  3b the literal rust-version occurs 1 time(s) under cargo/lib — the claim is wrong' "$T/out.log" \
  && pass "the zero-occurrence check caught the inserted key" \
  || fail "the zero-occurrence check did not catch the inserted key"
grep -qF 'failed assertions: 2' "$T/out.log" \
  && pass "exactly 2 assertions failed — no other check is coupled to this edit" \
  || fail "the tampered run did not report exactly 2 failed assertions"

hdr "3. The committed snapshot is untouched"
if bash "$E/r19-check-5f.sh" >/dev/null 2>&1; then
  pass "the committed snapshot still passes its own checker"
else
  fail "the committed snapshot no longer passes — this script must never modify it"
fi

hdr "SUMMARY"
printf 'failed assertions: %s\n' "$FAILS"
[ "$FAILS" -eq 0 ] || exit 1
exit 0
