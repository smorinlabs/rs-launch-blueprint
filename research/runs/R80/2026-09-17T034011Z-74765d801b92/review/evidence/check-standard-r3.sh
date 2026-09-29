#!/usr/bin/env bash
# R80 revision 3 — the override renumber, checked.
#
# Revision 3 is a MECHANICAL RENUMBER and nothing else: revision 2 and R77's
# revision 2 each allocated OVERRIDE (OV-04) by concurrent "next free number"
# searches, and the controller assigned R77 OV-04 and this item OV-05 (ledger
# entry "OVERRIDE NUMBER COLLISION, 2026-09-18").
#
#   R1..R5  the renumber itself: OV-05 everywhere this item's override is named,
#           OV-04 nowhere as its identifier, the surviving OV-04 mentions
#           accounted for line by line, and the decision's shape unmoved.
#   R6      every artifact of revisions 1 and 2 byte-identical, by sha256.
#   R7      the controlled re-run of the UNEDITED revision-2 script, recording
#           exactly which two of its assertions the renumber breaks and why — the
#           same pattern check C9 used for O25 one revision earlier.
#
# Revision 4 re-baselined this script against the current decision (audits
# EA-3 and EA-5 of revision 3): R1 pins the current H1, R6 pins the revision-4
# bytes of the seventeen artifacts it guards, R7 expects the re-baselined
# revision-2 script to pass outright, and no assertion pipes a variable into an
# early-exiting `grep -q`. The exact OVERRIDE (OV-05) count the prose states is
# asserted by check V10 in check-standard-r4.sh.
#
# Usage: bash check-standard-r3.sh [repo-root]
# Exit status: 0 when no check FAILs, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
ROOT="${1:-}"
if [ -z "$ROOT" ]; then
  HERE0="$(cd "$(dirname "$0")" && pwd)"
  ROOT="$(cd "$HERE0/../../../../../.." && pwd)"
fi
HERE="$(cd "$(dirname "$0")" && pwd)"
RUN="research/runs/R80/2026-09-17T034011Z-74765d801b92"
DECISION="$ROOT/$RUN/review/DECISION.md"

PASS=0
FAIL=0
SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }
# Indent a captured block for the log without reaching for sed.
indent() { while IFS= read -r line; do printf '  %s\n' "$line"; done <<<"$1"; }

R3_PY=""
R4_PY=""
cleanup() { [ -n "$R3_PY" ] && rm -f "$R3_PY"; [ -n "$R4_PY" ] && rm -f "$R4_PY"; return 0; }
trap cleanup EXIT

echo "=== R80 check-standard-r3.sh ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "python3: $(python3 --version 2>&1)"
if [ -e "$ROOT/.git" ]; then echo "git metadata: present"; else echo "git metadata: absent (archive extraction)"; fi

if [ ! -f "$DECISION" ]; then
  for id in R1 R2 R3 R4 R5; do skip "$id" "DECISION.md is absent"; done
else
  # ------------------------------------------------------------- R1 --------
  IFS= read -r H1 <"$DECISION" || true
  if [ "$H1" = '# 2026-09-27 — R80 — health-probe-endpoints (bundle, Focused) — decision (revision 7)' ]; then
    pass R1 "the H1 is the date-first title of the current revision, 7"
  else
    fail R1 "the H1 is not the prescribed revision-7 title"
  fi

  # ------------------------------------------------------------- R2 --------
  # The narrow, checkable claim: this item's override is named OV-05 and never
  # OV-04. Bare "OV-04" survives only where it names R77's override, revision
  # 2's superseded choice, or the collision — R3 accounts for those separately.
  OLD_HEAD="$($GREP -c 'OVERRIDE (OV-04)' "$DECISION" || true)"
  NEW_HEAD="$($GREP -c 'OVERRIDE (OV-05)' "$DECISION" || true)"
  echo "  'OVERRIDE (OV-04)' occurrences: $OLD_HEAD; 'OVERRIDE (OV-05)': $NEW_HEAD"
  if [ "$OLD_HEAD" -eq 0 ] && [ "$NEW_HEAD" -ge 1 ] &&
     $GREP -qF "#### \`OVERRIDE (OV-05)\` — the probe paths are unversioned, non-resource names" "$DECISION"; then
    pass R2 "this item's override is named OVERRIDE (OV-05) — $NEW_HEAD times, including its own H4 heading — and OVERRIDE (OV-04) appears 0 times (counted with $($GREP --version | head -1))"
  else
    fail R2 "the override identifier did not renumber cleanly (OV-04 heads $OLD_HEAD, OV-05 heads $NEW_HEAD)"
  fi

  # ------------------------------------------------------------- R3 --------
  # Every surviving bare OV-04 is accounted for by region, so a stray one in the
  # rule table or the conformance note cannot hide inside a legitimate total.
  R3_PY="$(mktemp "${TMPDIR:-/tmp}/r80-r3-audit.XXXXXXXX.py")"
  cat >"$R3_PY" <<'PYEOF'
import pathlib, sys
lines = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8").splitlines()
hits = [(i + 1, line) for i, line in enumerate(lines) if "OV-04" in line]
print("ov04_lines=%d" % len(hits))
print("ov04_occurrences=%d" % sum(line.count("OV-04") for _, line in hits))
# The three regions where naming R77s override, the superseded choice or the
# collision is correct: the revision-3 note, the allocation paragraph, and the
# Supersedes history.
note_end = next((i + 1 for i, line in enumerate(lines)
                 if line.startswith("**Revision note (revision 2).**")), 0)
alloc_start = next((i + 1 for i, line in enumerate(lines)
                    if line.startswith("#### `OVERRIDE (OV-05)`")), 0)
alloc_end = next((i + 1 for i, line in enumerate(lines[alloc_start:], start=alloc_start)
                  if line.startswith("**Options:**")), 0)
hist_start = next((i + 1 for i, line in enumerate(lines) if line == "## Supersedes"), 0)
stray = [n for n, _ in hits
         if not (n < note_end or (alloc_start <= n <= alloc_end) or n >= hist_start)]
print("regions note<%d alloc=%d..%d history>=%d" % (note_end, alloc_start, alloc_end, hist_start))
print("stray=%s" % (",".join(str(n) for n in stray) if stray else "none"))
PYEOF
  set +e
  R3_OUT="$(python3 "$R3_PY" "$DECISION" 2>&1)"
  R3_STATUS=$?
  set -e
  indent "$R3_OUT"
  if [ "$R3_STATUS" -eq 0 ] &&
     $GREP -qF 'ov04_lines=11' <<<"$R3_OUT" &&
     $GREP -qF 'ov04_occurrences=11' <<<"$R3_OUT" &&
     $GREP -qF 'stray=none' <<<"$R3_OUT"; then
    pass R3 "all eleven surviving OV-04 occurrences sit in the revision-3 note (revision 4's note, above it, names the old number 0 times), the allocation paragraph or the history — the three places that name R77's override, revision 2's superseded choice or the collision. None is in the rule table, the conformance note or the override's argument"
  else
    fail R3 "a bare OV-04 survives outside the three regions that may carry it, or the counts moved"
  fi

  # ------------------------------------------------------------- R4 --------
  # The renumber must not have moved the decision's shape or its parameters.
  R4_PY="$(mktemp "${TMPDIR:-/tmp}/r80-r3-shape.XXXXXXXX.py")"
  cat >"$R4_PY" <<'PYEOF'
import sys, pathlib
sys.path.insert(0, "scripts")
from research_validation import _line_states, _current_decision, _headings_with_bodies
text = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
h2 = [line for line, fenced in _line_states(text) if not fenced and line.startswith("## ")]
current = [name for name, _ in _headings_with_bodies(_current_decision(text), "## ")]
reverify = [line for line, fenced in _line_states(text)
            if not fenced and line.startswith("re-verify: ")]
print("h2_unfenced=%d" % len(h2))
print("supersedes=%d" % len([h for h in h2 if h == "## Supersedes"]))
print("reverify=%d" % len(reverify))
print("current_h2=%s" % "|".join(current))
PYEOF
  set +e
  R4_OUT="$(cd "$ROOT" && python3 "$R4_PY" "$DECISION" 2>&1)"
  R4_STATUS=$?
  set -e
  indent "$R4_OUT"
  if [ "$R4_STATUS" -eq 0 ] &&
     $GREP -qF 'h2_unfenced=5' <<<"$R4_OUT" &&
     $GREP -qF 'supersedes=1' <<<"$R4_OUT" &&
     $GREP -qF 'reverify=1' <<<"$R4_OUT" &&
     $GREP -qF 'current_h2=Decision|Parameters|Empirical check|Engines' <<<"$R4_OUT"; then
    pass R4 "the decision's shape is unmoved, counted outside code fences as the publication validator counts: five H2s, one Supersedes, one re-verify line, and the current entry's four H2s in order"
  else
    fail R4 "the renumber moved the decision's shape (see the counts above)"
  fi

  # ------------------------------------------------------------- R5 --------
  ASSUMES="$($GREP -c '^- assumes ' "$DECISION" || true)"
  OWNS="$($GREP -c '^- owns ' "$DECISION" || true)"
  ARG="$($GREP -c '^\*\*Argument:\*\*' "$DECISION" || true)"
  OPT="$($GREP -c '^\*\*Options:\*\*' "$DECISION" || true)"
  GATE1="$($GREP -c 'inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool' "$DECISION" || true)"
  echo "  assumes=$ASSUMES owns=$OWNS Argument=$ARG Options=$OPT gate1=$GATE1"
  if [ "$ASSUMES" -eq 7 ] && [ "$OWNS" -eq 0 ] && [ "$ARG" -eq 1 ] && [ "$OPT" -eq 1 ] && [ "$GATE1" -eq 1 ]; then
    pass R5 "the substance is unmoved: seven '- assumes' lines, no '- owns' line, one **Argument:** and one **Options:** block, and the gate-1 wording intact"
  else
    fail R5 "the renumber changed something it must not have (see the counts above)"
  fi
fi

# --------------------------------------------------------------- R6 --------
# Every artifact of revisions 1 and 2, by digest, at the bytes revision 4
# re-recorded under its audit repair orders; revisions 5 and 6 each re-baselined
# C2 in the revision-2 script to their H1 and re-recorded that script's log.
declare -a PRIOR=(
  "fccff1b713954954766e3dc01a7be6ebe72fac99df7b4094116ab553db1ca82d check-offline.sh"
  "020fdbd7c299a18e790c4cdcf2ce629083afaf592e38f761eaa26bb9526cb759 check-offline.log"
  "6a8ffed8dfc3f9be69ecbdbc4805572641cd88111c556f8691b272bbaea75f51 check-probe.sh"
  "c2fb16f6322303049f25f91800d3592d75004236fcf9227429941a76bedb342d check-probe.log"
  "fb08bb557f110fd48c55bd591fdcfbe367442ce52c4a1dfd3351449297129f8f check-live.sh"
  "2a2183f8c15f651b70bdc0036c3385561be254b711dfb0200c25ca543541b749 check-live.log"
  "74e9db37ec4aad2348402b646fd6363f5c304095e8d29e4e3e6b454167f8eafc shellcheck.log"
  "8cec46b5155bb8bb721723139b21a5ae906357ac7affe30c1a93a1dbbd72aff0 probe/core-src/lib.rs"
  "77e1683ef45a8b464e8e8d7fd12b022ef1176e18d5f08529be66cb64da928399 probe/web-src/lib.rs"
  "419751b3de90f4caf26536b63b2d8ee66082ee1ed74f03c4bbb7dcd4c631a3b1 probe/web-tests/probes.rs"
  "e99cdf289ec32f4410284a0430de3c60b060b6d2386c93a985f5a698f08d03b6 probe/facade-src/lib.rs"
  "c9d539a22585de8bb9a4707bdd0fe10c6a1079bcf6ac3fc69dfd790e3743d364 probe/facade-tests/version_hazard.rs"
  "e74254d547eb78da768b2b4c9c83ba5ad863e277790d4054a4f2809484f5267f check-standard-r2.sh"
  "49ae8df9206f8b741805691a2ca1d25f9e7f4d09e0bbd7773364f235bf7ff3e6 check-standard-r2.log"
  "f227ee8602ab12b10e267d85b228fd65247d9b6218bea73859c9cee8c384239c probe-r2/web-src/lib.rs"
  "4542f02ea972c4cb15dec5a399b05f4770aa66160aad435d0f9b42b15865f80c probe-r2/web-tests/conformance.rs"
  "e6f054b46927e6c9fcd0104b9c0e3032be715524227f8718ddef3c145e418b00 shellcheck-r2.log"
)
R6_BAD=0
for entry in "${PRIOR[@]}"; do
  read -r want path <<<"$entry"
  if [ ! -f "$HERE/$path" ]; then
    echo "  MISSING $path"; R6_BAD=$((R6_BAD + 1)); continue
  fi
  got="$(shasum -a 256 "$HERE/$path" | cut -d' ' -f1)"
  if [ "$got" = "$want" ]; then
    printf '  unchanged  %s\n' "$path"
  else
    printf '  CHANGED    %s (%s, expected %s)\n' "$path" "$got" "$want"
    R6_BAD=$((R6_BAD + 1))
  fi
done
if [ "$R6_BAD" -eq 0 ]; then
  pass R6 "all seventeen artifacts of revisions 1 and 2 — three scripts plus the revision-2 script, their logs, the shellcheck records and all seven probe sources — are byte-identical to the bytes revision 7 cites"
else
  fail R6 "$R6_BAD prior artifact(s) changed since revision 7 recorded them"
fi

# --------------------------------------------------------------- R7 --------
# The controlled re-run of the revision-2 script into a separate file. Through
# revision 3 it expected exactly C2 and C4 to FAIL; revision 4 re-baselined both
# to the current H1 and override name, so the re-run must now pass outright.
if [ -f "$HERE/check-standard-r2.sh" ]; then
  set +e
  bash "$HERE/check-standard-r2.sh" "$ROOT" >"$HERE/check-standard-r2.r3-rerun.log" 2>&1
  set -e
  R7_FAILS="$($GREP -c '^FAIL ' "$HERE/check-standard-r2.r3-rerun.log" || true)"
  R7_PASSES="$($GREP -c '^PASS ' "$HERE/check-standard-r2.r3-rerun.log" || true)"
  echo "  revision-2 script re-run into a separate file: $R7_PASSES PASS, $R7_FAILS FAIL"
  $GREP '^FAIL ' "$HERE/check-standard-r2.r3-rerun.log" | sed 's/^/    /' || true
  if [ "$R7_FAILS" -eq 0 ] && [ "$R7_PASSES" -eq 42 ]; then
    pass R7 "re-running the revision-2 script into check-standard-r2.r3-rerun.log yields all 42 checks PASS and 0 FAIL, its nested offline re-run (C9) included"
  else
    fail R7 "re-running the revision-2 script did not yield exactly 42 PASS and 0 FAIL ($R7_PASSES PASS, $R7_FAILS FAIL)"
  fi
else
  skip R7 "revision 2's check-standard-r2.sh is absent"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
