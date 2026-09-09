#!/usr/bin/env bash
# R06 empirical driver. Runs the recommended `unsafe` policy fixture through its
# positive and negative variants and prints everything to stdout (the caller
# redirects to review/evidence/<leg>.log). Deliberately no `set -e`: several
# commands are EXPECTED to fail, and every command's exit code is printed.
#
# Environment:
#   R06_CARGO   the cargo invocation for this leg, e.g. "/opt/homebrew/bin/cargo"
#           or "$HOME/.cargo/bin/cargo +1.96.0"   (default: cargo). Named R06_* so as not to collide with Cargo's own CARGO/RUSTC env vars.
#   R06_RUSTC   the matching rustc invocation, e.g. "$HOME/.cargo/bin/rustc +1.96.0"
#           (default: rustc)
#   R06_CLIPPY  "yes" to run the clippy legs, anything else to skip them (default: no)
#   CARGO_TARGET_DIR  where build artifacts go (default: ${TMPDIR:-/tmp}/r06-empirical-target)
set -u
FIX="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$FIX" || exit 99
read -r -a CARGO_CMD <<< "${R06_CARGO:-cargo}"
read -r -a RUSTC_CMD <<< "${R06_RUSTC:-rustc}"
CLIPPY="${R06_CLIPPY:-no}"
export CARGO_TARGET_DIR="${CARGO_TARGET_DIR:-${TMPDIR:-/tmp}/r06-empirical-target}"

LIB="$FIX/crates/demo/src/lib.rs"
ROOT="$FIX/Cargo.toml"
cp "$ROOT" "$FIX/.Cargo.toml.orig"
restore() {
  cp "$FIX/variants/safe.rs" "$LIB"
  cp "$FIX/.Cargo.toml.orig" "$ROOT"
  rm -f "$FIX/.Cargo.toml.orig"
}
trap restore EXIT

banner() { printf '\n### %s\n' "$1"; }
run() {
  printf '$ %s\n' "$*"
  "$@"
  local rc=$?
  printf 'exit=%d\n' "$rc"
  return "$rc"
}
variant() { cp "$FIX/variants/$1" "$LIB"; printf '[lib.rs <- variants/%s]\n' "$1"; }

banner "environment"
date -u +"%Y-%m-%dT%H:%M:%SZ"
uname -a
[ -r /etc/os-release ] && grep -E '^(PRETTY_NAME|VERSION_ID)=' /etc/os-release
printf 'R06_CARGO=%s\nR06_RUSTC=%s\nR06_CLIPPY=%s\nRUSTC (Cargo env var)=%s\nRUSTDOC (Cargo env var)=%s\nPATH head=%s\nCARGO_TARGET_DIR=%s\nfixture=%s\n' "${R06_CARGO:-cargo}" "${R06_RUSTC:-rustc}" "$CLIPPY" "${RUSTC:-<unset>}" "${RUSTDOC:-<unset>}" "$(printf '%s' "$PATH" | cut -d: -f1-2)" "$CARGO_TARGET_DIR" "$FIX"
printf -- '-- rustdoc on PATH: %s -> ' "$(command -v rustdoc)"; rustdoc --version
run "${RUSTC_CMD[@]}" -vV
run "${CARGO_CMD[@]}" --version
if [ "$CLIPPY" = "yes" ]; then run "${CARGO_CMD[@]}" clippy --version; fi
# Self-attestation: the compiler cargo ACTUALLY invokes for this leg (a rustup
# `+toolchain` proxy does not put the toolchain's bin dir first on PATH, so a
# foreign `rustc` on PATH can be picked up unless Cargo's RUSTC var is set).
printf -- '-- compiler cargo actually invokes (cargo rustc -- -vV, separate probe target dir):\n'
CARGO_TARGET_DIR="$CARGO_TARGET_DIR/probe" run "${CARGO_CMD[@]}" rustc -p demo --lib -- -vV

banner "fixture: root Cargo.toml (recommended configuration)"
cat "$ROOT"
banner "fixture: member Cargo.toml"
cat "$FIX/crates/demo/Cargo.toml"

banner "P1 safe resting state: cargo check --workspace (expect exit 0; memchr builds under forbid)"
variant safe.rs
run "${CARGO_CMD[@]}" check --workspace
printf 'resolved memchr: '; grep -A1 '^name = "memchr"' "$FIX/Cargo.lock" | tr '\n' ' '; printf '\n'

banner "P2 safe resting state: cargo test --workspace (expect exit 0)"
run "${CARGO_CMD[@]}" test --workspace

if [ "$CLIPPY" = "yes" ]; then
  banner "P3 safe resting state: cargo clippy --workspace --all-targets -- -D warnings (expect exit 0; the shipped clippy table costs nothing on clean safe code)"
  run "${CARGO_CMD[@]}" clippy --workspace --all-targets -- -D warnings
  banner "P4 safe code with a stray SAFETY comment, still under forbid: cargo check passes (expect exit 0), then clippy -D warnings (expect failure: unnecessary safety comment; unnecessary_safety_comment is live under forbid)"
  variant safe-stray-safety-comment.rs
  run "${CARGO_CMD[@]}" check --workspace
  run "${CARGO_CMD[@]}" clippy --workspace --all-targets -- -D warnings
else
  banner "P3/P4 skipped: clippy not run on this leg (CLIPPY=$CLIPPY)"
fi

banner "N1 unsafe block: cargo check (expect failure: usage of an unsafe block, note -F unsafe-code)"
variant unsafe-block.rs
run "${CARGO_CMD[@]}" check --workspace

banner "N2 #[allow(unsafe_code)] override: cargo check (expect failure: E0453 incompatible with previous forbid)"
variant allow-override.rs
run "${CARGO_CMD[@]}" check --workspace

banner "N3 #[expect(unsafe_code, reason)] override: cargo check (expect failure: E0453 as well)"
variant expect-override.rs
run "${CARGO_CMD[@]}" check --workspace

banner "N4 #[unsafe(no_mangle)] attribute: cargo check (expect failure: usage of the unsafe no_mangle attribute)"
variant no-mangle.rs
run "${CARGO_CMD[@]}" check --workspace

banner "R1 runner-up contrast: root switched forbid -> deny (one-token edit)"
sed -i.bak 's/^unsafe_code = "forbid"/unsafe_code = "deny"/' "$ROOT" && rm -f "$ROOT.bak"
grep -n '^unsafe_code' "$ROOT"
variant deny-with-safety-comment.rs
printf -- '-- R1a cargo check under deny with #[expect] + SAFETY comment (expect exit 0)\n'
run "${CARGO_CMD[@]}" check --workspace
if [ "$CLIPPY" = "yes" ]; then
  printf -- '-- R1b cargo clippy -D warnings, SAFETY comment present (expect exit 0)\n'
  run "${CARGO_CMD[@]}" clippy --workspace --all-targets -- -D warnings
  variant deny-without-safety-comment.rs
  printf -- '-- R1c cargo clippy -D warnings, SAFETY comment removed (expect failure: unsafe block missing a safety comment)\n'
  run "${CARGO_CMD[@]}" clippy --workspace --all-targets -- -D warnings
else
  printf -- '-- R1b/R1c skipped: clippy not run on this leg\n'
fi

banner "restore: resting state re-established by trap (verified below)"
restore
trap - EXIT
if cmp -s "$FIX/variants/safe.rs" "$LIB"; then echo "lib.rs == variants/safe.rs: yes"; else echo "lib.rs == variants/safe.rs: NO"; fi
grep -n '^unsafe_code' "$ROOT"
banner "done"
