#!/usr/bin/env bash
# R35 revision 3 — cargo-tarpaulin's own README at the ranked version (S12).
# Endpoint: api.github.com (REST through `gh api`), the contents endpoint pinned
# to tag 0.37.4, so every quoted line belongs to the release the DECISION ranks.
# The body is saved as snapshots/cargo-tarpaulin-0.37.4-README.md and its sha256
# printed here; it sits outside snapshots/sources/, which SHA256SUMS-sources defines.
# Revision 4 adds S12h: 0.37.5 was published 2026-09-27, so the README at tag
# 0.37.5 is fetched to a scratch file and compared byte for byte with the 0.37.4
# snapshot, keeping every S12 line citation valid for the current release.
# Usage: bash r35-tarpaulin.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
tag="0.37.4"
rd="$here/snapshots/cargo-tarpaulin-$tag-README.md"

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }
# at <line> <phrase>: the phrase occurs on that line of the snapshot.
at() { sed -n "${1}p" "$rd" | /usr/bin/grep -q -F -- "$2"; }
# span <first> <last> <phrase>: the phrase occurs in those lines joined by spaces.
span() { sed -n "${1},${2}p" "$rd" | tr '\n' ' ' | /usr/bin/grep -q -F -- "$3"; }

info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
gh api -H "Accept: application/vnd.github.raw" "repos/xd009642/tarpaulin/contents/README.md?ref=$tag" >"$rd"
info "snapshot $(basename "$rd") lines=$(wc -l <"$rd" | tr -d ' ') sha256=$(shasum -a 256 "$rd" | cut -d' ' -f1)"

check S12a "README:14 — Tarpaulin's line coverage 'may still contain  minor inaccuracies' (said without naming an engine)" \
  at 14 'may still contain  minor inaccuracies in the results'
check S12b "README:19-21 — ptrace is the Linux default (x86_64 only), --engine llvm switches it, LLVM is the default on Mac and Windows" \
  span 19 21 "default tracing backend is still Ptrace and will only work on x86\\_64 processors. This can be changed to the llvm coverage instrumentation with \`--engine llvm\`. For Mac and Windows, this is the default"
check S12c "README:73 — the --forward option list entry says forwarding 'is now the default behaviour'" \
  at 73 'Forwards unexpected signals to test. This is now the default behaviour'
check S12d "README:113 is the heading '### Note on tests using signals'" \
  test "$(sed -n 113p "$rd")" = '### Note on tests using signals'
check S12e "README:115-116 — tests using unix signals 'may not work with ptrace instrumentation'" \
  span 115 116 'they may not work with ptrace instrumentation in Tarpaulin'
check S12f "README:118-119 — the --forward option forwards signals to the test binary" \
  span 118 119 "\`--forward\` option results in forwarding the signals"
check S12g "README:123 — LLVM coverage is 'generally being far more accurate'" \
  at 123 'Despite generally being far more accurate there are some nuances with the LLVM'
new_tag="0.37.5"
nrd="$(mktemp /tmp/r35-tarpaulin-readme.XXXXXX)"; trap 'rm -f "$nrd"' EXIT
gh api -H "Accept: application/vnd.github.raw" "repos/xd009642/tarpaulin/contents/README.md?ref=$new_tag" >"$nrd"
info "README at tag $new_tag lines=$(wc -l <"$nrd" | tr -d ' ') sha256=$(shasum -a 256 "$nrd" | cut -d' ' -f1)"
check S12h "the README at tag $new_tag is byte-identical to the $tag snapshot, so S12a-S12g hold for $new_tag" \
  cmp -s "$rd" "$nrd"
/usr/bin/grep -n -F -e 'minor inaccuracies' -e 'default tracing backend' -e 'now the default behaviour' -e 'Note on tests using signals' -e 'may not work with' -e 'far more accurate' "$rd" | sed 's/^/INFO README: /'

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
