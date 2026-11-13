#!/usr/bin/env bash
# R28 revision 1 — the recommended lint table at the msrv-policy floor.
# Current stable is 1.98.1, so "stable minus 2 minor versions" is 1.96 today.
# The floor toolchain's own bin/ is put FIRST on PATH: through the rustup proxy
# (`cargo +1.96 clippy`) cargo resolves the `clippy` subcommand by searching
# PATH, where this host's Homebrew cargo-clippy 0.1.98 comes first, so the
# proxy form silently lints with the newer clippy. F0 asserts the version.
# Scratch workspace under mktemp; no network.
# Every case prints PASS or FAIL; the script exits 1 if any case fails.
# Patterns below are literal compiler messages containing backticks, so
# single quotes are intended throughout.
# shellcheck disable=SC2016
set -uo pipefail
export RUSTUP_AUTO_INSTALL=0

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

FLOOR_BIN=${FLOOR_BIN:-$HOME/.rustup/toolchains/1.96-aarch64-apple-darwin/bin}
PATH="$FLOOR_BIN:$PATH"
export PATH

echo "== floor toolchain"
echo "CARGO_HOME=${CARGO_HOME:-unset}"
echo "FLOOR_BIN=$FLOOR_BIN"
command -v cargo cargo-clippy clippy-driver rustc
cv=$(cargo --version); echo "$cv"
kv=$(cargo clippy --version); echo "$kv"
rv=$(rustc --version); echo "$rv"
case "$cv|$kv|$rv" in
  "cargo 1.96."*"|clippy 0.1.96"*"|rustc 1.96."*) pass F0 "cargo, clippy and rustc are all the 1.96 floor" ;;
  *) fail F0 "floor toolchain not resolved"; echo "== summary: $fails failing case(s)"; exit 1 ;;
esac

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-floor.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
cd "$scratch" || exit 1
echo "== scratch: $scratch (outside any repository)"

mkdir -p crates/core/src crates/core/tests crates/cli/src
cat > Cargo.toml <<'EOF'
[workspace]
resolver = "3"
members = ["crates/core", "crates/cli"]

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
undocumented_unsafe_blocks = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment = "deny"
allow_attributes_without_reason = "warn"
dbg_macro = "warn"
todo = "warn"
unimplemented = "warn"
unwrap_used = "warn"
EOF
cat > clippy.toml <<'EOF'
allow-unwrap-in-tests = true
allow-dbg-in-tests = true
EOF
cat > crates/core/Cargo.toml <<'EOF'
[package]
name = "r28-core"
version.workspace = true
edition.workspace = true
rust-version.workspace = true
license.workspace = true

[lints]
workspace = true
EOF
write_lib() {
  cat > crates/core/src/lib.rs <<'EOF'
//! Core library of the scratch fixture.

/// Doubles its input.
#[must_use]
pub fn double(x: u32) -> u32 {
    x * 2
}

#[cfg(test)]
mod tests {
    use super::double;

    #[test]
    fn doubles() {
        let parsed: u32 = "2".parse().unwrap();
        dbg!(parsed);
        assert_eq!(double(parsed), 4);
    }
}
EOF
}
write_lib
cat > crates/core/tests/integration.rs <<'EOF'
#![allow(clippy::unwrap_used, reason = "integration-test crate: a panic is the test failure")]

fn setup() -> u32 {
    "3".parse().unwrap()
}

#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double(setup()), 6);
}
EOF
cat > crates/cli/Cargo.toml <<'EOF'
[package]
name = "r28-cli"
version.workspace = true
edition.workspace = true
rust-version.workspace = true
license.workspace = true

[features]
web = []

[dependencies]
r28-core = { path = "../core" }

[lints]
workspace = true
EOF
cat > crates/cli/src/main.rs <<'EOF'
fn main() {
    println!("{}", r28_core::double(21));
}
EOF
cargo generate-lockfile --offline >/dev/null 2>&1 || cargo generate-lockfile

gate() { cargo clippy --workspace --all-targets --locked "$@" -- -D warnings 2>&1; }

echo
echo "== F1 recommended fixture (test relaxations included) passes at the floor, feature off and on"
echo '$ cargo clippy --workspace --all-targets --locked -- -D warnings'
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^(error|warning)|Finished' | head -n 4 || true
gate --features web >/dev/null; rc_f=$?
if [ "$rc" -eq 0 ] && [ "$rc_f" -eq 0 ]; then
  pass F1 "exit $rc; --features web exit $rc_f"
else
  fail F1 "exit $rc; --features web exit $rc_f"
fi

echo
echo "== F2 the named picks fire at the floor"
cat >> crates/core/src/lib.rs <<'EOF'

/// Unfinished.
pub fn unfinished() -> u32 {
    dbg!(1);
    todo!()
}
EOF
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 3 || true
if [ "$rc" -ne 0 ] && grep -q 'the `dbg!` macro is intended as a debugging tool' <<<"$out" \
   && grep -q '`todo` should not be present in production code' <<<"$out"; then
  pass F2 "exit $rc"
else
  fail F2 "exit $rc"
fi
write_lib

echo
echo "== F3 allow_attributes_without_reason fires at the floor"
cat > crates/core/tests/integration.rs <<'EOF'
#![allow(clippy::unwrap_used)]

fn setup() -> u32 {
    "3".parse().unwrap()
}

#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double(setup()), 6);
}
EOF
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 2 || true
if [ "$rc" -ne 0 ] && grep -q '`allow` attribute without specifying a reason' <<<"$out"; then
  pass F3 "exit $rc"
else
  fail F3 "exit $rc"
fi

echo
echo "== F4 lint_groups_priority rejects a bare group line at the floor"
cp Cargo.toml Cargo.toml.orig
awk '{ print } /^\[workspace.lints.clippy\]$/ { print "all = \"warn\"" }' Cargo.toml.orig > Cargo.toml
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 1 || true
if [ "$rc" -ne 0 ] && grep -q 'lint group `all` has the same priority (0) as a lint' <<<"$out"; then
  pass F4 "exit $rc"
else
  fail F4 "exit $rc"
fi
cp Cargo.toml.orig Cargo.toml

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
