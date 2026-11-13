#!/usr/bin/env bash
# shellcheck disable=SC2016
#   File-wide: the quoted ledger and decision texts asserted below are literals.
#
# R77 revision 3 — the only new evidence script. It does three things:
#
#   A  Records the controller's OVERRIDE-number allocation ruling and asserts
#      that R77 is the named holder of OV-04 and R80 of OV-05.
#   B  DEMONSTRATES the defect in revision 2's own OV check rather than
#      asserting it in prose: that check excluded `runs/R77/` from an
#      un-normalized path whose every element already contains `runs/R77/`, so
#      it swallowed all of its input and could not fail. The demonstration is
#      run here, and the corrected, non-vacuous search is run beside it.
#   C  Pins revision 1's ten evidence files by sha256 and re-runs revision 2's
#      script, so "carried byte-identical" is checkable rather than asserted.
#
# Revision 2's rest-conformance-r2.sh is NOT edited: it is the historical record
# of what revision 2 checked. Against a revision-3 title it now reports 90/1/0 —
# the one failure being its own revision-2 title check, which binds that title by
# design — and one of its 90 passes is the vacuous check group B exposes.
set -euo pipefail
set -o pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
# Resolve the repository root to a REAL path. Revision 2's bug was reasoning
# about a path still carrying `..` segments; `cd … && pwd` removes them.
root=$(cd -- "$here/../../../../../.." && pwd)
decision="$here/../DECISION.md"
ledger="$root/docs/planning/p02/execution-ledger.md"
r80="$root/research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
file_has() {
  if [ ! -f "$2" ]; then sk "$1 — $2 not present"; return; fi
  if /usr/bin/grep -qF -- "$3" "$2"; then ok "$1"; else
    no "$1"; printf '     %s does not contain: %s\n' "$2" "$3"; fi
}
count_is() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}

printf '# R77 revision 3 — OVERRIDE-number allocation — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# /usr/bin/grep version: %s\n' "$(/usr/bin/grep --version | head -1)"
printf '# repository root, fully resolved: %s\n' "$root"

if [ -f "$root/docs/port/PARAMETERS.md" ] && [ -f "$root/research/CLAUDE.md" ]; then
  ok "repository root resolves, with no .. segments left in it"
else
  no "repository root did not resolve (tried $root)"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  exit 1
fi
case "$root" in
  *..*) no "the resolved root still contains a .. segment — revision 2's bug would recur" ;;
  *)    ok "the resolved root contains no .. segment" ;;
esac

############################################################################
echo
echo '## A — the controller allocates OV numbers, and R77 holds OV-04'
file_has "the ledger records the collision and the resolution" "$ledger" \
  "OVERRIDE NUMBER COLLISION, 2026-09-18: R77 revision 2 (d36492b) and R80 revision 2 (ce291fe) both allocated OV-04 by concurrent \"next free number\" searches."
file_has "the resolution moves allocation to the controller" "$ledger" \
  "Resolution: OV numbers are allocated by the controller from now on."
file_has "the allocation table gives OV-04 to R77 revision 2" "$ledger" \
  "OV-04 R77 revision 2 (R8.1 plaintext listener; committed first, keeps the number)"
file_has "the allocation table renumbers R80 to OV-05" "$ledger" \
  "OV-05 R80 (renumbered from OV-04 in a revision 3)"
file_has "later items ask the controller rather than searching" "$ledger" \
  "Later items ask the controller for a number instead of searching."
file_has "the ledger records R77 revision 2 landing with OV-04" "$ledger" \
  "R77 REVISION 2 LANDED, 2026-09-18"

# R80 must actually have renumbered, or the collision is unresolved in the tree.
if [ -f "$r80" ]; then
  got=$(head -1 "$r80")
  case "$got" in
    *"(revision 3)"*) ok "R80's decision is at revision 3, the renumbering revision" ;;
    *) no "R80's decision is not at revision 3; its H1 reads: $got" ;;
  esac
  file_has "R80 now records OVERRIDE (OV-05)" "$r80" "OVERRIDE (OV-05)"
else
  sk "R80's decision is not in the tree (2 checks)"
fi

# The live census, done the way it must be done: on resolved paths.
holders=$(find "$root/docs" "$root/research" -name '*.md' -type f -print0 2>/dev/null \
          | xargs -0 /usr/bin/grep -l 'OVERRIDE (OV-04)' 2>/dev/null \
          | /usr/bin/sed "s|^$root/||" | sort || true)
printf 'live holders of the literal "OVERRIDE (OV-04)":\n%s\n' "$holders"
# Two holders are required. R80's file is NOT one of them: it is another agent's
# live working file in this shared worktree and may gain or lose a renumber note
# at any moment, so requiring a mention there would make this check flap. What
# must hold is that R80 no longer CLAIMS the number (group A above) and that no
# THIRD item claims it.
for expect in \
  "research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md" \
  "docs/planning/p02/execution-ledger.md"; do
  if printf '%s\n' "$holders" | /usr/bin/grep -qxF -- "$expect"; then
    ok "required OV-04 holder present: $expect"
  else
    no "required OV-04 holder missing: $expect"
  fi
done
stray=$(printf '%s\n' "$holders" \
        | { /usr/bin/grep -v '^research/runs/R77/' || true; } \
        | { /usr/bin/grep -v '^docs/planning/p02/execution-ledger\.md$' || true; } \
        | { /usr/bin/grep -v '^research/runs/R80/' || true; })
if [ -z "$stray" ]; then
  ok "no third item claims OV-04 (only this item, the ledger, and optionally R80's renumber note)"
else
  no "a third item claims OV-04: $stray"
fi

############################################################################
echo
echo '## B — revision 2 s OV check was vacuous: demonstrated, not asserted'
# Revision 2 computed its root as "$run/../../../.." WITHOUT resolving it, so
# every path it produced began with .../runs/R77/<run-id>/review/evidence/../…
# and its `grep -v runs/R77/` therefore matched — and discarded — every line.
unresolved="$here/../../../../../.."          # exactly revision 2's expression
raw=$(find "$unresolved/docs" "$unresolved/research" -name '*.md' -type f -print0 2>/dev/null \
      | xargs -0 /usr/bin/grep -l 'OVERRIDE (OV-04)' 2>/dev/null | /usr/bin/grep -c . || true)
filtered=$(find "$unresolved/docs" "$unresolved/research" -name '*.md' -type f -print0 2>/dev/null \
      | xargs -0 /usr/bin/grep -l 'OVERRIDE (OV-04)' 2>/dev/null \
      | { /usr/bin/grep -v 'runs/R77/' || true; } | /usr/bin/grep -c . || true)
printf 'unresolved-path search: %s files matched, %s survived the revision-2 exclusion\n' "$raw" "$filtered"
if [ "$raw" -gt 0 ] && [ "$filtered" -eq 0 ]; then
  ok "revision 2's exclusion discarded all $raw matching files — the check could not fail (the defect, reproduced)"
else
  no "the defect did not reproduce: raw=$raw filtered=$filtered; revision 3's account of revision 2 is wrong"
fi
# The corrected form, on resolved paths, keeps the other holders visible.
corrected=$(find "$root/docs" "$root/research" -name '*.md' -type f -print0 2>/dev/null \
      | xargs -0 /usr/bin/grep -l 'OVERRIDE (OV-04)' 2>/dev/null \
      | { /usr/bin/grep -v "^$root/research/runs/R77/" || true; } | /usr/bin/grep -c . || true)
if [ "$corrected" -ge 1 ]; then
  ok "the corrected search sees $corrected OV-04 holder(s) outside this item, where revision 2's saw 0"
else
  no "the corrected search found no holder outside this item; the ledger must name OV-04"
fi
file_has "revision 2's script still contains the vacuous expression, unedited" \
  "$here/rest-conformance-r2.sh" "/usr/bin/grep -v 'runs/R77/'"
file_has "the decision records the defect rather than quietly repairing it" "$decision" \
  "could not fail, and revision 3 says so"

############################################################################
echo
echo '## C — revision 1 and revision 2 evidence carried byte-identical'
while IFS='|' read -r name want; do
  [ -n "$name" ] || continue
  f="$here/$name"
  if [ ! -f "$f" ]; then no "carried file $name is missing"; continue; fi
  got=$(shasum -a 256 "$f" | awk '{print $1}')
  count_is "$name is unchanged" "$want" "$got"
done <<'SHAS'
figures.sh|d70b89cdd15898078182f696540bd992be7d17c9ba7262441bc4395d29dd25a6
sources.sh|a63bb281280bc3d530f7aacf24e3825994f94c2f980db4df7c0041cb9fe05f34
probes.sh|4af088a3945a2ba47ab7f60ef71f0714fd4075b9f01cfe81606edd45d1b62747
fetch-snapshots.sh|9c26e9ea96b101e88398b60baf3b709bc3b3e0aae28bfd8d9b77c4442e51c642
figures.log|493ba961663fbf19d28432610d38ff168558239e074026d02ced7bf28a58f086
sources.log|455841ce2b0d76cf94d46a5563d3a50a9144e454bf4f5218235ee32c1b3f3923
probes.log|fe848ea72828e4220f7030caca562c48517f16207565d9b05c6edf2a58672ae7
fetch-snapshots.log|8eae6a9c2af53ec40384968efed1ed40b16e5d7c7523240336fd7e25c84f5226
rerun-diff.log|d6b4d0fee8b741eb8850d00c38810ddf832d0c161f6f0d0cc4530e36dd96028a
archive-rerun.log|b341895ab9f790914d3475f70a34b4aa7aae0c07eaea39100a3f3b7e7ad15d1a
SHAS

# Revision 2's script must still RUN, and exactly one of its 91 checks must now
# fail: the one that binds revision 2's own H1 by design. Any other failure
# would mean revision 3 broke something real.
r2out=$(bash "$here/rest-conformance-r2.sh" 2>&1 || true)
last=$(printf '%s\n' "$r2out" | tail -1)
count_is "revision 2's script still runs, now 90/1/0 against a revision-3 title" \
  "PASS=90 FAIL=1 SKIP=0 TOTAL=91" "$last"
r2fails=$(printf '%s\n' "$r2out" | { /usr/bin/grep '^FAIL' || true; })
count_is "its single failure is the revision-2 title check, and nothing else" \
  "FAIL H1 is the date-first revision-2 title" "$r2fails"

############################################################################
echo
echo '## D — revision-3 document discipline'
if [ ! -f "$decision" ]; then
  sk "DECISION.md not present beside this script — document discipline (6 checks)"
else
  got=$(head -1 "$decision")
  count_is "H1 is the date-first revision-3 title" \
    "# 2026-09-18 — R77 — web-env-settings (crate, Focused) — decision (revision 3)" "$got"
  n=$(/usr/bin/grep -c '^## Supersedes' "$decision" || true)
  count_is "no Supersedes section" 0 "$n"
  n=$(/usr/bin/grep -c '^re-verify: ' "$decision" || true)
  count_is "exactly one re-verify line" 1 "$n"
  n=$(/usr/bin/grep -c '^- owns ' "$decision" || true)
  count_is "no owned parameter" 0 "$n"
  n=$(/usr/bin/grep -c '^- assumes ' "$decision" || true)
  count_is "exactly six assumes lines" 6 "$n"
  file_has "the revision history names all three revisions" "$decision" \
    "**Revision 3** (2026-09-18, this file)"
  file_has "the OV-04 ground is now the controller's allocation, not a search" "$decision" \
    "allocated by the controller"
  file_has "the substance of revision 2 is declared unmoved" "$decision" \
    "Nothing in the conformance pass moves"
  for p in msrv-policy rust-edition target-os-matrix license web-extra-surface error-taxonomy-exit-codes; do
    reg=$(python3 - "$root" "$p" <<'PY'
import sys
sys.path.insert(0, sys.argv[1] + "/scripts")
from pathlib import Path
from research_validation import _parse_parameters
v = _parse_parameters(Path(sys.argv[1]), [])
row = v.get(sys.argv[2])
print("- assumes %s = %s" % (sys.argv[2], row["value"] if row else "!!MISSING!!"))
PY
)
    dec=$(/usr/bin/grep -m1 "^- assumes $p = " "$decision" || true)
    if [ "$reg" = "$dec" ]; then
      ok "assumes $p still byte-identical to docs/port/PARAMETERS.md (${#reg} bytes)"
    else
      no "assumes $p differs from the registry row"
      printf '     registry: %s\n     decision: %s\n' "$reg" "$dec"
    fi
  done
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
