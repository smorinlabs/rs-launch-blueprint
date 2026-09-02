#!/usr/bin/env bash
# Does an engine answer fill the §7.7 template? Usage: check-answer-shape.sh <answer.md> <crate|pattern|bundle> [override]
set -uf
f="${1:?answer file}"; kind="${2:?kind}"; ov="${3:-}"; fail=0
common="Recommendation|Ranked runner-up|Tradeoffs|Parameters|Migration implications|Validation strategy|Confidence & re-verify trigger|Sources"
case "$kind" in
  crate)   want="Dominant choice|Qualified shortlist|Excluded by gate|Up-and-comers|Fit for this template|$common" ;;
  pattern) want="Dominant choice|Options|Excluded by gate|Up-and-comers|Fit for this template|$common" ;;
  bundle)  want="Recommendation|Members|Compatibility|Parameters|Migration implications|Validation strategy|Confidence & re-verify trigger|Sources" ;;
  *) echo "FAIL: kind '$kind' not crate|pattern|bundle"; exit 1 ;;
esac
[ "$ov" = override ] && want="$want|Inherited default|Rust-specific argument|Options rejected|Override justified|Resulting verdict"
while IFS= read -r field; do
  grep -qx "### $field" "$f" || { printf 'FAIL: missing field "### %s"\n' "$field"; fail=1; }
done < <(printf '%s' "$want" | tr '|' '\n')
[ "$fail" -eq 0 ] && echo "OK: $f fills the $kind template${ov:+ (+override)}"; exit "$fail"
