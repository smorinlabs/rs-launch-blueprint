#!/usr/bin/env bash
# R01 revision 3 — assert that the licence-ruling repair is complete.
#
# Every assertion is on CONTENT, not on an exit code, and each command's status is
# captured on its own line rather than through a pipeline, so a failing command
# cannot be masked by a succeeding one further down the pipe. The script counts
# failures and exits with that count. Check 7 works from an explicit list of the
# nine phrases revision 2 used to reason from a licence (`void_phrases.py`), not
# from a keyword scan: a keyword scan over this document's long paragraph lines
# was tried first and silently passed a reverted repair, because the reverted
# sentence shared its line with the sentence that marks the clause struck.
# Check 12 is the negative control: the same nine phrases, run against the
# SUPERSEDED revision-2 text carried in the history, must all still be found. If
# they are not, the list has gone stale and check 7's pass means nothing.
# Reverting any single repair was verified to make check 7 exit non-zero.
#
# The revision-2 baseline is taken from THIS FILE's own Supersedes history and
# pinned by sha256, never from research/topics/.../DECISION.md. That path holds
# revision 2 only until revision 3 is published; reading it would make the script
# pass today and fail three assertions the moment the publisher overwrites it.
# The script therefore reads exactly one input, resolved from its own location,
# so neither the working directory nor the publication state can change the
# result, and no network source is queried: the log does not drift.
set -o pipefail
set -u

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$here/../../../../../.." && pwd)
decision="$root/research/runs/R01/2026-09-05T155123Z-52a17c034dad/review/DECISION.md"
evidence="$root/research/runs/R01/2026-09-05T155123Z-52a17c034dad/review/evidence"

# The published revision-2 digest, as recorded in
# research/topics/01-ports-and-adapters-seam/acceptance.json and in
# docs/planning/p02/execution-ledger.md. Checks 1, 5 and 6 are anchored to it.
REV2_SHA256=8025fd5b1a959b1e76fa9a738176071b418fd411aa2ba6ad5c6e4bffbd9a018f
REV2_HEADING='# R01 ports-and-adapters-seam — decision (revision 2, 2026-09-10)'

checks=0
failures=0

report() { # report <name> <ok|FAIL> <detail>
  checks=$((checks + 1))
  if [ "$2" = ok ]; then
    printf 'check %2d  PASS  %-38s %s\n' "$checks" "$1" "$3"
  else
    failures=$((failures + 1))
    printf 'check %2d  FAIL  %-38s %s\n' "$checks" "$1" "$3"
  fi
}

if [ ! -f "$decision" ]; then
  printf 'fatal: missing input %s\n' "$decision"
  exit 99
fi

RULING='`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`'

work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT

# The current entry is everything before the Supersedes heading; the history is
# everything after it. Every assertion below that speaks of "the decision" means
# the current entry, because the history is required to be verbatim and therefore
# still carries the text this revision struck.
awk 'BEGIN{p=1} /^## Supersedes$/{p=0} p' "$decision" > "$work/current.md"
status=$?
[ $status -eq 0 ] || { printf 'fatal: could not split the decision (awk exit %d)\n' "$status"; exit 99; }
awk 'f{print} /^## Supersedes$/{f=1}' "$decision" > "$work/history.md"
status=$?
[ $status -eq 0 ] || { printf 'fatal: could not split the decision (awk exit %d)\n' "$status"; exit 99; }

printf 'R01 revision 3 — licence-repair assertions\n'
printf 'decision   research/runs/R01/2026-09-05T155123Z-52a17c034dad/review/DECISION.md\n'
printf 'baseline   revision 2, extracted from that file own history, pinned sha256 %s\n\n' "$REV2_SHA256"

# 1 — the published revision-2 bytes survive verbatim in the history.
#     Extracted by byte offset from this file's own history and hashed; matching
#     the pinned digest proves the preserved bytes ARE published revision 2, which
#     a substring test against a live path could not, and which stays true after
#     revision 3 is published over that path.
python3 - "$decision" "$REV2_HEADING" "$work/rev2.md" > "$work/verbatim.txt" 2>&1 <<'EXTRACT'
import sys, pathlib, hashlib
data = pathlib.Path(sys.argv[1]).read_bytes()
marker = ("\n" + sys.argv[2] + "\n").encode("utf-8")
if data.count(marker) != 1:
    print("MARKER-COUNT-%d" % data.count(marker)); raise SystemExit(0)
rev2 = data[data.find(marker) + 1:]
pathlib.Path(sys.argv[3]).write_bytes(rev2)
print(hashlib.sha256(rev2).hexdigest())
EXTRACT
status=$?
verbatim=$(cat "$work/verbatim.txt")
if [ $status -eq 0 ] && [ "$verbatim" = "$REV2_SHA256" ]; then
  report supersedes-bytes-are-rev2 ok "history tail hashes to the published revision-2 digest"
else
  report supersedes-bytes-are-rev2 FAIL "got: $verbatim (python exit $status)"
fi

# 2 — exactly one Supersedes heading, at the top level.
count=$(grep -c '^## Supersedes$' "$decision")
status=$?
if [ $status -eq 0 ] && [ "$count" = 1 ]; then
  report supersedes-heading-once ok "1 heading line"
else
  report supersedes-heading-once FAIL "found $count (grep exit $status)"
fi

# 3 — the current entry's H2 sequence is the one the packaging validator requires.
h2=$(grep '^## ' "$work/current.md" | tr '\n' '|')
status=$?
expected='## Decision|## Parameters|## Empirical check|## Engines|'
if [ $status -eq 0 ] && [ "$h2" = "$expected" ]; then
  report current-h2-sequence ok "$expected"
else
  report current-h2-sequence FAIL "got: $h2 (grep exit $status)"
fi

# 4 — the current entry opens with a dated heading, which the publisher's
#     check_history guard requires of a revision.
dated=$(grep -c -E '^#( ##)? [0-9]{4}-[0-9]{2}-[0-9]{2}( |$)' "$work/current.md")
status=$?
if [ $status -eq 0 ] && [ "$dated" -ge 1 ]; then
  report current-entry-dated ok "$(grep -m1 -E '^# [0-9]{4}-[0-9]{2}-[0-9]{2}' "$work/current.md")"
else
  report current-entry-dated FAIL "no dated H1 in the current entry (grep exit $status)"
fi

# 5 — the owned parameter line is byte-identical to the published one. R69 is
#     consuming this value; a moved byte would invalidate a published parameter.
#     The baseline is the hash-verified revision 2 extracted by check 1.
grep '^- owns ' "$work/current.md" > "$work/owns-new.txt"
status_new=$?
grep '^- owns ' "$work/rev2.md" > "$work/owns-old.txt"
status_old=$?
if [ $status_new -eq 0 ] && [ $status_old -eq 0 ] && cmp -s "$work/owns-new.txt" "$work/owns-old.txt"; then
  report owns-line-byte-identical ok "http-transport-injection-seam identical to revision 2 ($(wc -c < "$work/owns-new.txt" | tr -d ' ') bytes)"
else
  report owns-line-byte-identical FAIL "differs, or absent (grep exits $status_new/$status_old)"
fi

# 6 — all four assumed parameter lines are byte-identical, in order.
grep '^- assumes ' "$work/current.md" > "$work/assumes-new.txt"
status_new=$?
grep '^- assumes ' "$work/rev2.md" > "$work/assumes-old.txt"
status_old=$?
lines=$(wc -l < "$work/assumes-new.txt" | tr -d ' ')
if [ $status_new -eq 0 ] && [ $status_old -eq 0 ] && [ "$lines" = 4 ] && cmp -s "$work/assumes-new.txt" "$work/assumes-old.txt"; then
  report assumes-lines-byte-identical ok "4 lines unchanged: msrv-policy, rust-edition, target-os-matrix, license"
else
  report assumes-lines-byte-identical FAIL "$lines line(s), or content differs (grep exits $status_new/$status_old)"
fi

# 7 — the repair is complete. Each of the nine phrases revision 2 used to
#     reason from a licence must be gone from the current entry, except the
#     patent-grant clause, which is quoted once so a reader can see what was
#     removed and must be immediately followed by the sentence that strikes it.
#     The phrase list lives in `void_phrases.py` beside this script.
"$here/void_phrases.py" "$work/current.md" repaired > "$work/void-repaired.txt" 2>&1
void_status=$?
printf 'check  7  detail (void phrases, repaired text)\n'
cat "$work/void-repaired.txt"
if [ $void_status -eq 0 ]; then
  report void-phrases-struck ok "9 of 9 phrases repaired"
else
  report void-phrases-struck FAIL "$void_status phrase(s) still reason from a licence"
fi

# 8 — gate 1 is recorded as inapplicable with the ruling, not deleted.
if grep -q -F "**Fitness gate 1 (licence) — $RULING.**" "$work/current.md"; then
  report gate-1-recorded-inapplicable ok "gate row present with the ruling verbatim"
else
  report gate-1-recorded-inapplicable FAIL "gate 1 row missing or its ruling text differs"
fi

# 9 — the withdrawn acceptance criterion is recorded, not deleted.
if grep -q -F "That criterion is $RULING.**" "$work/current.md" \
   && grep -q -F "recorded here rather than deleted" "$work/current.md"; then
  report resolved-pins-criterion-recorded ok "permissive-licence criterion marked inapplicable in check 3"
else
  report resolved-pins-criterion-recorded FAIL "the withdrawn criterion is not recorded in check 3"
fi

# 10 — each excluded crate's surviving independent ground is present in the
#      decision's own outcome text.
missing=""
grep -q -F '"no push through two years of releases", against the table'\''s own figures' "$work/current.md" || missing="$missing test-case-at-risk"
grep -q -F '`test-case` varies *values*' "$work/current.md" || missing="$missing test-case-fit"
grep -q -F 'with "liberal use of unsafe" per its own documentation' "$work/current.md" || missing="$missing faux-unsafe"
grep -q -F 'mocks a concrete struct instead of implementing the port trait' "$work/current.md" || missing="$missing faux-fit"
grep -q -F 'the category alternative F rejects outright' "$work/current.md" || missing="$missing nject-category"
grep -q -F 'is 0 reverse dependencies' "$work/current.md" || missing="$missing nject-adoption"
if [ -z "$missing" ]; then
  report independent-grounds-present ok "test-case, faux and nject each keep two stated grounds"
else
  report independent-grounds-present FAIL "missing:$missing"
fi

# 11 — checks 1 to 4's logs are the bytes this decision has always cited. Revision
#      3 re-ran none of them, so any difference here means a log was disturbed.
cat > "$work/log-hashes.txt" <<'EOF'
56d7800f8bb7eb04b107b1a17d987fb1fc35353f1a49e016ef08faf3b40a0638  macos-stable-clippy-fmt.log
2063d4f57864f68abec1dedb0eb41e496725515d834bbf4ae4f46bd2b94dd0da  compile-fail-reasons.log
01546304a676040e68f7f5906492bf4fa4c56870b9bd3193f4e9909bd47dd642  dependency-msrv-license.log
66240e5f0171199c46a6e0b2d865d4449d8571c155a80db10f6b5be12d10dd0e  cargo-audit.log
EOF
bad=""
while read -r want name; do
  # `set -o pipefail` is in force, so this pipeline reports shasum's status
  # when shasum fails, not awk's.
  got=$(shasum -a 256 "$evidence/$name" | awk '{print $1}')
  status=$?
  [ $status -eq 0 ] && [ "$got" = "$want" ] || bad="$bad $name"
done < "$work/log-hashes.txt"
if [ -z "$bad" ]; then
  report checks-1-to-4-logs-unchanged ok "4 logs match their recorded sha256"
else
  report checks-1-to-4-logs-unchanged FAIL "changed or unreadable:$bad"
fi

# 12 — negative control. The same phrase list, run against the
#      superseded revision-2 text carried in the history, MUST find every phrase
#      still reasoning from a licence. If it finds none the list has gone stale
#      and check 7's pass means nothing: a check that cannot fail is not evidence.
"$here/void_phrases.py" "$work/history.md" superseded > "$work/void-superseded.txt" 2>&1
control_status=$?
printf 'check 12  detail (same phrases, superseded revision-2 text)\n'
cat "$work/void-superseded.txt"
if [ $control_status -eq 0 ]; then
  report negative-control-phrases-found ok "all 9 phrases found in revision 2, as expected"
else
  report negative-control-phrases-found FAIL "$control_status phrase(s) not found; the list is stale"
fi

printf '\nchecks=%d failures=%d\n' "$checks" "$failures"
exit "$failures"
