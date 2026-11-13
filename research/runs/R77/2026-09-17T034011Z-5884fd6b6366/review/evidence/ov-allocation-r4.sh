#!/usr/bin/env bash
# R77 revision 4 — the OVERRIDE-number census, scoped to declarations.
#
# Revision 3's ov-allocation-r3.sh counted every Markdown file under docs/ and
# research/ that MENTIONS the literal `OVERRIDE (OV-04)` as an item that CLAIMS
# it. Auditor reports and notes quote the literal, so its "no third item claims
# OV-04" check failed in the live tree for reasons unrelated to the claim. This
# script is not an edit of that one; it supersedes its census:
#
#   A  the controller's allocation ruling in the ledger (unchanged facts)
#   B  the census counts DECLARATIONS only: a Markdown heading naming
#      `OVERRIDE (OV-04)`, in a file named DECISION.md under research/runs or
#      research/topics. Auditor reports, ledgers and notes are out of scope by
#      construction, and no audit file is opened.
#   C  controls: the same search finds R77's own OV-04 heading and R80's OV-05
#      heading (positive), and finds a heading planted in a scratch tree but not
#      a bare quotation planted beside it (negative)
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
root=$(cd -- "$here/../../../../../.." && pwd)
ledger="$root/docs/planning/p02/execution-ledger.md"
self_rel="research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md"
r80_rel="research/runs/R80/2026-09-17T034011Z-74765d801b92/review/DECISION.md"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
file_has() {
  if /usr/bin/grep -qF -- "$3" "$2"; then ok "$1"; else
    no "$1"; printf '     %s does not contain: %s\n' "$2" "$3"; fi
}

printf '# R77 revision 4 — OVERRIDE-number census (declarations only) — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# repository root, fully resolved: %s\n' "$root"
case "$root" in
  *..*) no "the resolved root still contains a .. segment" ;;
  *)    ok "the resolved root contains no .. segment" ;;
esac

# declarers <tree> <number>: relative paths of DECISION.md files with a heading
# that names `OVERRIDE (<number>)`.
declarers() {
  local tree=$1 num=$2 d
  for d in "$tree/research/runs" "$tree/research/topics"; do
    [ -d "$d" ] && find "$d" -name DECISION.md -type f -print0
  done | xargs -0 /usr/bin/grep -lE "^#+ .*OVERRIDE \\($num\\)" 2>/dev/null \
       | /usr/bin/sed "s|^$tree/||" | sort || true
}

echo
echo '## A — the controller allocates OV numbers; R77 holds OV-04, R80 OV-05'
file_has "the ledger records the collision" "$ledger" \
  "OVERRIDE NUMBER COLLISION, 2026-09-18: R77 revision 2 (d36492b) and R80 revision 2 (ce291fe) both allocated OV-04"
file_has "allocation moved to the controller" "$ledger" \
  "Resolution: OV numbers are allocated by the controller from now on."
file_has "OV-04 is allocated to R77" "$ledger" \
  "OV-04 R77 revision 2 (R8.1 plaintext listener; committed first, keeps the number)"
file_has "OV-05 is allocated to R80" "$ledger" \
  "OV-05 R80 (renumbered from OV-04 in a revision 3)"

echo
echo '## B — who DECLARES OVERRIDE (OV-04)'
n_files=$(for d in "$root/research/runs" "$root/research/topics"; do
            find "$d" -name DECISION.md -type f; done | /usr/bin/grep -c . || true)
printf 'DECISION.md files searched: %s\n' "$n_files"
if [ "$n_files" -gt 1 ]; then ok "the census searched more than one decision ($n_files)"
else no "the census searched $n_files decision(s) — the search is not reaching the tree"; fi
holders=$(declarers "$root" "OV-04")
printf 'declarers of OVERRIDE (OV-04):\n%s\n' "$holders"
if [ "$holders" = "$self_rel" ]; then
  ok "exactly one decision declares OV-04, and it is this one"
else
  no "the OV-04 declarers are not exactly this decision"
fi
case "$holders" in
  *audit-*) no "an audit file entered the census" ;;
  *)        ok "no audit file is in the census (only DECISION.md files are searched)" ;;
esac
tracked=$(git -C "$root" ls-files --error-unmatch "$self_rel" >/dev/null 2>&1 && echo tracked || echo untracked)
printf 'this decision is %s in git\n' "$tracked"

echo
echo '## C — controls'
r80=$(declarers "$root" "OV-05")
printf 'declarers of OVERRIDE (OV-05):\n%s\n' "$r80"
if printf '%s\n' "$r80" | /usr/bin/grep -qxF -- "$r80_rel"; then
  ok "positive control: the same search finds R80's OV-05 heading"
else
  no "positive control failed: R80's OV-05 heading was not found"
fi
S=$(mktemp -d "${TMPDIR:-/tmp}/r77-ov-r4.XXXXXX")
trap 'rm -rf "$S"' EXIT
mkdir -p "$S/research/runs/RXX/run/review" "$S/research/runs/RYY/run/review"
# shellcheck disable=SC2016  # the backticks are Markdown, written literally
printf '# t\n\n#### `OVERRIDE (OV-04)` — planted declaration\n' > "$S/research/runs/RXX/run/review/DECISION.md"
printf '# t\n\nThe audit quotes OVERRIDE (OV-04) in prose.\n' > "$S/research/runs/RYY/run/review/DECISION.md"
printf 'OVERRIDE (OV-04) in an audit file\n' > "$S/research/runs/RYY/run/review/audit-x.md"
planted=$(declarers "$S" "OV-04")
if [ "$planted" = "research/runs/RXX/run/review/DECISION.md" ]; then
  ok "negative control: a planted heading is found; a prose quotation and an audit file are not"
else
  no "negative control: expected only the planted heading, got: $planted"
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
