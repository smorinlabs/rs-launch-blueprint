#!/usr/bin/env bash
# R19 — negative control for r19-check-r5.sh.
#
# "A check that cannot fail is not evidence." This script proves the sibling
# checker can fail: it copies the committed snapshot to a scratch directory,
# rewrites the one sentence that settles the configured `cooldown` case so that
# it says the opposite, runs the checker there, and asserts that the run exits 1
# with exactly the two expected failures — the blob-sha integrity check and the
# line-187 content assertion. The committed snapshot is never modified.
#
#   bash research/runs/R19/2026-09-06T043454Z-33c81db94a3b/review/evidence/r19-check-r5-negative-control.sh
set -uo pipefail

GREP=/usr/bin/grep
FAILS=0
pass() { printf 'PASS  %s\n' "$1"; }
fail() { printf 'FAIL  %s\n' "$1"; FAILS=$((FAILS+1)); }
hdr()  { printf '\n===== %s =====\n' "$1"; }

E="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
T="$(mktemp -d "${TMPDIR:-/tmp}/r19-r5-negctl.XXXXXX")"
trap 'rm -rf "$T"' EXIT
DOC_PATH=content/code-security/reference/supply-chain-security/dependabot-options-reference.md

hdr "0. Setup"
date -u '+run-utc %Y-%m-%dT%H:%M:%SZ'
printf 'scratch copy %s\n' "$T"
cp -R "$E/github-docs-dd75c5f3" "$E/r19-check-r5.sh" "$T/"
TAMPER="$T/github-docs-dd75c5f3/$DOC_PATH"
sed -i '' 's/only available for _version_ updates, not _security_ updates/also available for _security_ updates/' "$TAMPER"
printf 'tampered: line 187 now reads\n'
sed -n '187p' "$TAMPER"

hdr "1. Run the checker against the tampered copy"
bash "$T/r19-check-r5.sh" > "$T/out.log" 2>&1
RC=$?
printf 'checker exit status %s\n' "$RC"
"$GREP" -E '^FAIL |^failed assertions' "$T/out.log"

hdr "2. Assertions about the failure"
[ "$RC" -eq 1 ] \
  && pass "the checker exits 1 when its snapshot is tampered with" \
  || fail "the checker exited $RC, expected 1"
"$GREP" -qF 'FAIL  1a snapshot does not re-derive the pin' "$T/out.log" \
  && pass "the blob-sha integrity check caught the edit" \
  || fail "the blob-sha integrity check did not catch the edit"
"$GREP" -qF 'FAIL  2a the pinned cooldown section states the option is only available for version updates, not security updates' "$T/out.log" \
  && pass "the line-187 content assertion caught the reversed sentence" \
  || fail "the line-187 content assertion did not catch the reversed sentence"
"$GREP" -qF 'failed assertions: 2' "$T/out.log" \
  && pass "exactly 2 assertions failed — no other check is coupled to this edit" \
  || fail "the tampered run did not report exactly 2 failed assertions"

hdr "3. The committed snapshot is untouched"
if bash "$E/r19-check-r5.sh" >/dev/null 2>&1; then
  pass "the committed snapshot still passes its own checker"
else
  fail "the committed snapshot no longer passes — this script must never modify it"
fi

hdr "SUMMARY"
printf 'failed assertions: %s\n' "$FAILS"
[ "$FAILS" -eq 0 ] || exit 1
exit 0
