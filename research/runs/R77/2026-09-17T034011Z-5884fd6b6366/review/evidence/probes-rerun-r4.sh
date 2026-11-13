#!/usr/bin/env bash
# R77 revision 4 — rerun of revision 1's carried probes.sh, both ways.
#
# claude audit finding 1: probes.sh P6 reads `$W/c_$n/target/release/c_$n`, so an
# inherited CARGO_TARGET_DIR sends the builds elsewhere and P6 measures 0 bytes.
# probes.sh is NOT edited (probes-r4.sh supersedes P6). This wrapper records
# what the carried script reports:
#
#   run 1  as written, with the caller's CARGO_TARGET_DIR inherited
#          (a scratch directory is supplied when the caller has none)
#   run 2  with CARGO_TARGET_DIR removed from the environment
#
# Each run's full output is printed, then the PASS/FAIL/SKIP totals are asserted:
# run 1 is expected to report 31/3/0 with the three FAILs all in P6, run 2 34/0/0.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
probes="$here/probes.sh"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}

printf '# R77 rerun of carried probes.sh, revision 4 — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# probes.sh sha256: %s\n' "$(shasum -a 256 "$probes" | cut -d' ' -f1)"

S=$(mktemp -d "${TMPDIR:-/tmp}/r77-probes-rerun.XXXXXX")
trap 'rm -rf "$S"' EXIT
inherited=${CARGO_TARGET_DIR:-$S/inherited-target}

echo
printf '## run 1 — as written, CARGO_TARGET_DIR=%s\n' "$inherited"
set +e
CARGO_TARGET_DIR=$inherited bash "$probes" > "$S/run1.log" 2>&1
rc1=$?
set -e
/usr/bin/sed 's/^/  | /' "$S/run1.log"

echo
echo '## run 2 — CARGO_TARGET_DIR removed'
set +e
env -u CARGO_TARGET_DIR bash "$probes" > "$S/run2.log" 2>&1
rc2=$?
set -e
/usr/bin/sed 's/^/  | /' "$S/run2.log"

echo
echo '## assertions'
assert_eq "run 1 exit status" 1 "$rc1"
assert_eq "run 1 totals" "PASS=31 FAIL=3 SKIP=0 TOTAL=34" "$(/usr/bin/grep -E '^PASS=' "$S/run1.log" | tail -1)"
assert_eq "run 1: every FAIL is in P6" 3 "$(/usr/bin/grep -c '^FAIL P6 ' "$S/run1.log" || true)"
assert_eq "run 1: the two under-50 KB checks pass on 0 B (the vacuous PASS)" 2 \
  "$(/usr/bin/grep -cE '^PASS P6 .*under 50 KB.*\(0 B\)' "$S/run1.log" || true)"
assert_eq "run 2 exit status" 0 "$rc2"
assert_eq "run 2 totals" "PASS=34 FAIL=0 SKIP=0 TOTAL=34" "$(/usr/bin/grep -E '^PASS=' "$S/run2.log" | tail -1)"

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
