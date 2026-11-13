#!/usr/bin/env bash
# Shared helpers for the R32 evidence scripts. Sourced, never executed.
# shellcheck disable=SC2034  # PASS/FAIL/WORK are read by the sourcing script
PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); echo "PASS $1 — $2"; }
bad() { FAIL=$((FAIL+1)); echo "FAIL $1 — $2"; }
# chk ID DESCRIPTION CMD...   — PASS when CMD exits 0 (CMD output discarded)
chk() { local id="$1" desc="$2"; shift 2; if "$@" >/dev/null 2>&1; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }
# has ID DESCRIPTION FILE ERE  — PASS when FILE contains a line matching ERE
has() { chk "$1" "$2" /usr/bin/grep -Eq -- "$4" "$3"; }
# hasnt ID DESCRIPTION FILE ERE — PASS when no line of FILE matches ERE
# (grep exit 1 only: an unreadable file or a bad pattern is a FAIL, never a PASS)
hasnt() { local r; set +e; /usr/bin/grep -Eq -- "$4" "$3"; r=$?; set -e; if [ "$r" -eq 1 ]; then ok "$1" "$2"; else bad "$1" "$2"; fi; }
indent() { while IFS= read -r l; do printf 'INFO   %s\n' "$l"; done; }
now() { python3 -c 'import time; print(f"{time.time():.3f}")'; }
elapsed() { python3 -c "print(f'{$2 - $1:.2f}')"; }
# run OUTFILE CMD... — run CMD, capture stdout+stderr in OUTFILE, set RC
run() { local out="$1"; shift; set +e; "$@" > "$out" 2>&1; RC=$?; set -e; }
finish() { echo "RESULT PASS=$PASS FAIL=$FAIL"; [ "$FAIL" -eq 0 ]; }
: "${CARGO_HOME:?CARGO_HOME must be set to the private cargo home}"
export PATH="$CARGO_HOME/bin:$PATH"
FIXTURE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/fixture"
# stage NAME — copy the fixture to a scratch dir, cd into it, give it its own target dir
stage() {
  WORK="$(mktemp -d "${TMPDIR:-/tmp}/r32-$1.XXXXXX")"
  # shellcheck disable=SC2064  # expand WORK now
  trap "rm -rf '$WORK'" EXIT
  cp -R "$FIXTURE/." "$WORK/"
  export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-$WORK/target}/r32-$1"
  cd "$WORK"
  echo "INFO scratch copy of fixture/ at $WORK; CARGO_TARGET_DIR=$CARGO_TARGET_DIR"
  echo "INFO rustc: $(rustc --version); $(cargo nextest --version | head -1)"
}
