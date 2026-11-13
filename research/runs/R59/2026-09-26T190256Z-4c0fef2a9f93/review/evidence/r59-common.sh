#!/usr/bin/env bash
# R59 synthesis evidence — shared helper, sourced by every r59-*.sh check. Not a check itself
# and has no log. It locates the probe crate (review/evidence/r59-check, committed with its
# Cargo.lock), builds it with --locked into a target directory OUTSIDE the repository, and
# provides the assertion counter. Nothing is written into the repository by any check.
#
# House rules: set -u and pipefail; /usr/bin/grep by absolute path (a typed grep in an agent
# shell may be ugrep honouring .gitignore); no count is taken from head-truncated output; the
# exit status of every check is its number of failed assertions.

set -u
set -o pipefail

GREP=/usr/bin/grep
EVID="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
CRATE="$EVID/r59-check"
: "${CARGO_TARGET_DIR:=${TMPDIR:-/tmp}/r59-synth-target}"
export CARGO_TARGET_DIR
# shellcheck disable=SC2034  # used by every sourcing check
BIN="$CARGO_TARGET_DIR/release/r59-check"
FAILS=0
CHECKS=0

# check <id> <description> <expected> <actual>
check() {
  CHECKS=$((CHECKS + 1))
  if [[ "$3" == "$4" ]]; then
    printf 'PASS %s — %s — expected=[%s] actual=[%s]\n' "$1" "$2" "$3" "$4"
  else
    FAILS=$((FAILS + 1))
    printf 'FAIL %s — %s — expected=[%s] actual=[%s]\n' "$1" "$2" "$3" "$4"
  fi
}

# field <key> <text>: value of the first `key=value` token for key in text ('' if absent).
field() {
  printf '%s\n' "$2" | tr ' ' '\n' | "$GREP" -m1 "^$1=" | cut -d= -f2-
}

build_probe() {
  printf 'probe crate: %s\n' "$CRATE"
  printf 'CARGO_TARGET_DIR: %s\n' "$CARGO_TARGET_DIR"
  printf 'Cargo.lock sha256: %s\n' "$(shasum -a 256 "$CRATE/Cargo.lock" | cut -d' ' -f1)"
  if ! (cd "$CRATE" && cargo build --release --locked --quiet); then
    printf 'FATAL: probe build failed\n'
    exit 99
  fi
}

finish() {
  printf '\nSUMMARY: %d checks, %d failed, 0 skipped\n' "$CHECKS" "$FAILS"
  exit "$FAILS"
}

header() {
  printf '# %s\n' "$1"
  printf 'run (UTC): %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
  printf 'host: %s\n' "$(uname -srm)"
  printf 'rustc: %s\n' "$(rustc --version)"
}
