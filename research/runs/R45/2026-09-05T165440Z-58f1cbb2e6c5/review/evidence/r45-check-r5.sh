#!/usr/bin/env bash
# R45 revision-5 empirical check.
#
# Why it exists: the round-4 empirical audit rejected revision 4 on
#   `D16d fails: the live Greptile corpus contains 39 @greptileai occurrences,
#    not the 40 that the decision and r45-check-r3.sh assert`.
# Nothing about the recommendation moved; a check bound a LIVE third-party count
# as if it were a fixed fact. This script re-binds the decision's Greptile prose
# to a COMMITTED observation -- review/evidence/r45-greptile-corpus-2026-09-17.snapshot
# and its line extract -- and re-fetches the live corpus only as a VOLATILE
# report that is printed and never asserted, so a later vendor edit changes what
# this script PRINTS and never what it CONCLUDES.
#
# r45-check.sh (revision 2), r45-check-r3.sh (revision 3) and every log either of
# them produced are left byte-identical; E4 asserts exactly that by hashing them.
#
# Verification only: no source-repository, template or workflow file is written,
# no workflow is enabled, no bot is invoked, no comment is posted and no
# repository variable is set. Durable writes: none. Ephemeral writes: files
# inside a private `mktemp -d` removed by the EXIT trap.
#
# Host preconditions: none that are path-hardcoded. The repository root is
# derived from this script's own location, so the script runs unmodified from a
# `git archive HEAD` extraction. Network access is used by E5 alone and E5
# cannot fail the run. E6 needs a `.git` directory and SKIPs by name without one.
# shellcheck disable=SC2016
# SC2016 is disabled deliberately and file-wide: every single-quoted argument
# below is a FIXED string passed to `grep -F`, and several contain backticks.
# Expanding them would change the string being searched for, which would turn a
# content assertion into a vacuous one.
set -uo pipefail

SELF_DIR="$(cd "$(dirname "$0")" && pwd)"
EVID="$SELF_DIR"
R45DIR="$(cd "$SELF_DIR/../.." && pwd)"
REPO="$(cd "$SELF_DIR/../../../../../.." && pwd)"
R45DEC="$R45DIR/review/DECISION.md"
SNAP="$EVID/r45-greptile-corpus-2026-09-17.snapshot"
EXTRACT="$EVID/r45-greptile-handle-lines-2026-09-17.txt"
R45R2SH="$EVID/r45-check.sh"
R45R2LOG="$EVID/r18-trigger-phrase-pin.log"
R45R3SH="$EVID/r45-check-r3.sh"
R45R3LOG="$EVID/r45-r18-credential-gate-r3.log"

# sha256 of the artifacts revision 5 must leave byte-identical, as committed at
# revision 4 (commit a86f266).
R2SHSHA=233789ea6c1d1531f1c6707b59f8f1f246b92dd8bfb291488a06a758bde3c0bc
R2LOGSHA=86974f9894d6eb34e5720edd78929c9f945585b71f238efe74012cda704362de
R3SHSHA=56461a6c60a1393a9805a18ea79f2343cdf4a5b2a72b22bec32df0b5cd0b8be8
R3LOGSHA=ccb63f4b09cc5e663a4973553f632982c529b40ce9e2f3875f807fa4f6c5d899

# the superseded revision-3 assertion, quoted verbatim so the supersession is
# legible in this log rather than only in the decision.
SUPERSEDED='C8 still counts 40 @greptileai'

SCRATCH="$(mktemp -d)"
trap 'rm -rf "$SCRATCH"' EXIT
FAILS=0

# check <id> <label> <observed> <expected>
check () {
  if [ "$3" = "$4" ]; then
    printf '  %-5s PASS  %s\n        observed: %s\n' "$1" "$2" "$3"
  else
    printf '  %-5s FAIL  %s\n        observed: %s\n        expected: %s\n' "$1" "$2" "$3" "$4"
    FAILS=$((FAILS + 1))
  fi
}
# present <id> <label> <file> <fixed-string>  -- asserts at least one occurrence
present () {
  local n
  n=$(/usr/bin/grep -c -F "$4" "$3")
  if [ "$n" -ge 1 ]; then
    printf '  %-5s PASS  %s\n        %s occurrence(s) of: %s\n' "$1" "$2" "$n" "$4"
  else
    printf '  %-5s FAIL  %s\n        0 occurrences of: %s\n' "$1" "$2" "$4"
    FAILS=$((FAILS + 1))
  fi
}
# atleast <id> <label> <observed-number> <floor>  -- asserts a FLOOR, not a value
atleast () {
  if [ "$3" -ge "$4" ]; then
    printf '  %-5s PASS  %s\n        observed: %s (floor %s)\n' "$1" "$2" "$3" "$4"
  else
    printf '  %-5s FAIL  %s\n        observed: %s (floor %s)\n' "$1" "$2" "$3" "$4"
    FAILS=$((FAILS + 1))
  fi
}
# skip <id> <label> <reason>
skip () { printf '  %-5s SKIP  %s\n        %s\n' "$1" "$2" "$3"; }
# field <key>  -- reads "key: value" out of the snapshot record
field () { /usr/bin/sed -n "s/^$1: //p" "$SNAP" | head -1; }

echo "# r45-greptile-snapshot-r5.log"
printf 'captured: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
echo

echo "=== E0 - provenance of this check ==="
echo "  repository root (derived from this script's path): $REPO"
echo "  working directory: $(pwd)"
echo "  bash:   $(bash --version | head -1)"
echo "  curl:   $(/usr/bin/curl --version | head -1)"
echo "  grep:   $(/usr/bin/grep --version | head -1)"
echo "  uname:  $(uname -srm)"
echo "  writes: none durable; ephemeral only inside $SCRATCH, removed on exit"
echo "  exit status depends on E1 to E4 and E6 only. E5 is VOLATILE and cannot fail the run."
echo

echo "=== E1 - the committed observation record, which is what the decision is asserted against ==="
if [ ! -f "$SNAP" ] || [ ! -f "$EXTRACT" ]; then
  echo "  E1    FAIL  the committed snapshot or its extract is missing"
  FAILS=$((FAILS + 1))
else
  SNAP_AI=$(field greptileai-occurrences)
  SNAP_APPS=$(field greptile-apps-occurrences)
  SNAP_LINES=$(field greptileai-lines)
  SNAP_WHEN=$(field observed-utc)
  SNAP_SHA=$(field corpus-sha256)
  SNAP_BYTES=$(field corpus-bytes)
  echo "  record: $SNAP"
  printf '  observed-utc %s; %s bytes; corpus sha256 %s\n' "$SNAP_WHEN" "$SNAP_BYTES" "$SNAP_SHA"
  check E1a "the record carries the observation instant"                 "$SNAP_WHEN"  "2026-09-17T01:14:29Z"
  check E1b "the record's @greptileai count"                             "$SNAP_AI"    "39"
  check E1c "the record's @greptile-apps count"                          "$SNAP_APPS"  "0"
  check E1d "the extract recounts to the record's count, independently"  "$(/usr/bin/grep -o -F '@greptileai' "$EXTRACT" | /usr/bin/wc -l | tr -d ' ')" "$SNAP_AI"
  check E1e "the extract's line count matches the record"                "$(/usr/bin/wc -l < "$EXTRACT" | tr -d ' ')" "$SNAP_LINES"
  check E1f "39 occurrences over 38 lines, so one line carries two"       "$(( SNAP_AI - SNAP_LINES ))" "1"
  present E1g "the extract carries the manual-trigger instruction the decision quotes" "$EXTRACT" 'manual trigger via `@greptileai` only'
  echo "  boundary: the extract proves the 39 positively. The 0 for @greptile-apps is an"
  echo "            ABSENCE over the whole corpus, recorded against corpus-sha256 above and"
  echo "            re-observed unasserted in E5; an extract of matching lines cannot show it."
fi
echo

echo "=== E2 - what the count is evidence OF: a presence/absence relation, asserted as a floor ==="
if [ -f "$SNAP" ]; then
  atleast E2a "@greptileai is used in the corpus (floor, not a value)" "$(field greptileai-occurrences)" 1
  check   E2b "@greptile-apps is absent from the corpus"               "$(field greptile-apps-occurrences)" "0"
  echo "  This is the relation the recommendation rests on, and it survived the drift from 40"
  echo "  to 39. The decision states the consequence at '## Engines' disagreement 2: 'if the"
  echo "  count were reversed tomorrow, the recommendation would not change.'"
else
  echo "  E2    FAIL  no snapshot to read"
  FAILS=$((FAILS + 1))
fi
echo

echo "=== E3 - the decision's prose quotes the committed observation, and keeps the prior one as history ==="
present E3a "the current reading, with its counts"    "$R45DEC" '39 occurrences of `@greptileai` and zero of `@greptile-apps`'
present E3b "the current reading, with its instant"   "$R45DEC" '2026-09-17T01:14:29Z'
present E3c "the current reading, with its corpus sha256" "$R45DEC" '2b26da66'
present E3d "the 2026-09-10 reading, kept as history"  "$R45DEC" '40 occurrences of `@greptileai` and zero of `@greptile-apps`'
present E3e "the superseded revision-3 assertion, quoted in the decision" "$R45DEC" "$SUPERSEDED"
present E3f "the recommendation, unchanged from revision 2" "$R45DEC" 'carries **no "Review Trigger" section and no `@`-mention of any review bot**'
echo

echo "=== E4 - the cited scripts and logs of revisions 2 and 3 are byte-identical ==="
echo "  superseded assertion, quoted verbatim: $SUPERSEDED"
echo "  It is left in r45-check-r3.sh unedited; revision 5 supersedes it in the decision"
echo "  rather than rewriting a script an audit has already reproduced."
check E4a "revision 2's script"  "$(/usr/bin/shasum -a 256 "$R45R2SH"  | cut -d' ' -f1)" "$R2SHSHA"
check E4b "revision 2's log"     "$(/usr/bin/shasum -a 256 "$R45R2LOG" | cut -d' ' -f1)" "$R2LOGSHA"
check E4c "revision 3's script"  "$(/usr/bin/shasum -a 256 "$R45R3SH"  | cut -d' ' -f1)" "$R3SHSHA"
check E4d "revision 3's log"     "$(/usr/bin/shasum -a 256 "$R45R3LOG" | cut -d' ' -f1)" "$R3LOGSHA"
present E4e "revision 3's script still carries the superseded assertion" "$R45R3SH" "$SUPERSEDED"
echo

echo "=== E5 - VOLATILE: the live corpus, re-fetched, REPORTED AND NEVER ASSERTED ==="
echo "  A live third-party corpus is outside this repository's control. Whatever this"
echo "  section prints, it does not change the exit status. That is the repair."
if /usr/bin/curl -sS -L --max-time 25 \
     -A 'https://github.com/smorinlabs/rs-launch-blueprint' \
     -o "$SCRATCH/live.txt" https://www.greptile.com/docs/llms-full.txt 2>"$SCRATCH/curl.err"; then
  LIVE_BYTES=$(/usr/bin/wc -c < "$SCRATCH/live.txt" | tr -d ' ')
  LIVE_SHA=$(/usr/bin/shasum -a 256 "$SCRATCH/live.txt" | cut -d' ' -f1)
  LIVE_AI=$(/usr/bin/grep -o -F '@greptileai' "$SCRATCH/live.txt" | /usr/bin/wc -l | tr -d ' ')
  LIVE_APPS=$(/usr/bin/grep -o -F '@greptile-apps' "$SCRATCH/live.txt" | /usr/bin/wc -l | tr -d ' ')
  printf '  live: %s bytes, sha256 %s\n' "$LIVE_BYTES" "$LIVE_SHA"
  printf '  live: @greptileai %s, @greptile-apps %s\n' "$LIVE_AI" "$LIVE_APPS"
  if [ "$LIVE_SHA" = "$(field corpus-sha256)" ]; then
    echo "  VOLATILE-AGREES  the live corpus is byte-identical to the committed observation"
  else
    echo "  VOLATILE-DRIFTED the live corpus has changed since the committed observation."
    printf '                   committed: %s bytes, @greptileai %s, @greptile-apps %s\n' \
      "$(field corpus-bytes)" "$(field greptileai-occurrences)" "$(field greptile-apps-occurrences)"
    if [ "$LIVE_AI" -ge 1 ] && [ "$LIVE_APPS" -eq 0 ]; then
      echo "                   the presence/absence relation E2 asserts still holds live."
    else
      echo "                   the presence/absence relation E2 asserts DOES NOT hold live."
      echo "                   That is a re-verify trigger for this decision, not a failure of"
      echo "                   this script; see the re-verify: line of '## Decision'."
    fi
  fi
else
  echo "  VOLATILE-UNREACHABLE the corpus could not be fetched: $(cat "$SCRATCH/curl.err")"
  echo "                   Recorded, not failed. The committed observation stands on its own."
fi
echo

echo "=== E6 - the observation record and its extract are tracked, not scratch files ==="
# `-e`, not `-d`: in a git WORKTREE .git is a file pointing at the real gitdir,
# and a `-d` test would mis-report this repository as an archive extraction.
if [ -e "$REPO/.git" ]; then
  for rel in review/evidence/r45-greptile-corpus-2026-09-17.snapshot \
             review/evidence/r45-greptile-handle-lines-2026-09-17.txt \
             review/evidence/r45-check-r5.sh; do
    if git -C "$REPO" ls-files --error-unmatch "research/runs/R45/2026-09-05T165440Z-58f1cbb2e6c5/$rel" > /dev/null 2>&1; then
      printf '  %-5s PASS  tracked: %s\n' "E6" "$rel"
    else
      printf '  %-5s FAIL  untracked: %s\n' "E6" "$rel"
      FAILS=$((FAILS + 1))
    fi
  done
else
  skip E6 "the three new artifacts are tracked in git" "no .git at $REPO -- this is a git archive extraction, where tracking is already established by construction"
fi
echo

echo "=== end of checks ==="
echo "failed checks: $FAILS"
echo
echo "=== script source (emitted by this script, so the log is self-contained) ==="
cat "$0"
exit "$([ "$FAILS" -eq 0 ] && echo 0 || echo 1)"
