#!/usr/bin/env bash
# R28 revision 1 — test-code lint relaxation. Scratch two-member workspace
# under mktemp (no network), recommended lint table, then one case per claim.
# Every case prints PASS or FAIL; the script exits 1 if any case fails.
# Patterns below are literal compiler messages containing backticks, so
# single quotes are intended throughout.
# shellcheck disable=SC2016
set -uo pipefail
export RUSTUP_AUTO_INSTALL=0

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

echo "== toolchain on PATH"
echo "CARGO_HOME=${CARGO_HOME:-unset}"
command -v cargo cargo-clippy
cargo --version
cargo clippy --version

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-test-relax.XXXXXX")
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
write_integration() {
  cat > crates/core/tests/integration.rs <<'EOF'
#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double("3".parse().unwrap()), 6);
}
EOF
}
write_lib
write_integration
cat > crates/cli/Cargo.toml <<'EOF'
[package]
name = "r28-cli"
version.workspace = true
edition.workspace = true
rust-version.workspace = true
license.workspace = true

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

gate() { cargo clippy --workspace --all-targets --locked -- -D warnings 2>&1; }
show() { printf '%s\n' "$1" | grep -E '^(error|warning)|-->' | head -n "${2:-6}" || true; }

echo
echo "== T1 unwrap and dbg! in a #[cfg(test)] module and unwrap in a #[test] fn pass under clippy.toml allow-*-in-tests"
echo '$ cargo clippy --workspace --all-targets --locked -- -D warnings'
out=$(gate); rc=$?
show "$out"
if [ "$rc" -eq 0 ]; then pass T1 "exit $rc"; else fail T1 "exit $rc"; fi

echo
echo "== T2 negative control: the same code fails once clippy.toml is removed"
mv clippy.toml clippy.toml.off
out=$(gate); rc=$?
show "$out" 8
if [ "$rc" -ne 0 ] && grep -q 'used `unwrap()` on a `Result` value' <<<"$out" \
   && grep -q 'the `dbg!` macro is intended as a debugging tool' <<<"$out"; then
  pass T2 "unwrap_used and dbg_macro fire without the config keys (exit $rc)"
else
  fail T2 "exit $rc"
fi
mv clippy.toml.off clippy.toml

echo
echo "== T3 unwrap in a non-test helper fn of an integration-test crate still fails"
cat > crates/core/tests/integration.rs <<'EOF'
fn setup() -> u32 {
    "3".parse().unwrap()
}

#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double(setup()), 6);
}
EOF
out=$(gate); rc=$?
show "$out"
if [ "$rc" -ne 0 ] && grep -q 'used `unwrap()` on a `Result` value' <<<"$out" \
   && grep -q 'tests/integration.rs:2' <<<"$out"; then
  pass T3 "helper unwrap fires at tests/integration.rs:2 (exit $rc)"
else
  fail T3 "exit $rc"
fi

echo
echo "== T4 a reasoned crate-level allow as the first line relaxes that crate"
{ printf '#![allow(clippy::unwrap_used, reason = "integration-test crate: a panic is the test failure")]\n\n'; cat crates/core/tests/integration.rs; } > t.rs
mv t.rs crates/core/tests/integration.rs
out=$(gate); rc=$?
show "$out"
if [ "$rc" -eq 0 ]; then pass T4 "exit $rc"; else fail T4 "exit $rc"; fi

echo
echo "== T5 the same allow without a reason fails (allow_attributes_without_reason)"
{ printf '#![allow(clippy::unwrap_used)]\n'; tail -n +2 crates/core/tests/integration.rs; } > t.rs
mv t.rs crates/core/tests/integration.rs
head -n 1 crates/core/tests/integration.rs
out=$(gate); rc=$?
show "$out"
if [ "$rc" -ne 0 ] && grep -q '`allow` attribute without specifying a reason' <<<"$out"; then
  pass T5 "exit $rc"
else
  fail T5 "exit $rc"
fi

echo
echo "== T6 #[cfg(test)] on the helper also relaxes it"
cat > crates/core/tests/integration.rs <<'EOF'
#[cfg(test)]
fn setup() -> u32 {
    "3".parse().unwrap()
}

#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double(setup()), 6);
}
EOF
out=$(gate); rc=$?
show "$out"
if [ "$rc" -eq 0 ]; then pass T6 "exit $rc"; else fail T6 "exit $rc"; fi

echo
echo "== T7 #![expect] where the lint no longer fires is an error (unfulfilled expectation)"
write_integration
{ printf '#![expect(clippy::unwrap_used, reason = "integration-test crate")]\n\n'; cat crates/core/tests/integration.rs; } > t.rs
mv t.rs crates/core/tests/integration.rs
out=$(gate); rc=$?
show "$out"
if [ "$rc" -ne 0 ] && grep -q 'this lint expectation is unfulfilled' <<<"$out"; then
  pass T7 "exit $rc"
else
  fail T7 "exit $rc"
fi
write_integration

echo
echo "== T8 the raw/muse.md:423 bare blanket allow on a test module fails under the recommended table"
cat > crates/core/src/lib.rs <<'EOF'
//! Core library of the scratch fixture.

/// Doubles its input.
#[must_use]
pub fn double(x: u32) -> u32 {
    x * 2
}

#[cfg(test)]
#[allow(clippy::all, clippy::pedantic)]
mod tests {
    use super::double;

    #[test]
    fn doubles() {
        assert_eq!(double(2), 4);
    }
}
EOF
out=$(gate); rc=$?
show "$out"
if [ "$rc" -ne 0 ] && grep -q '`allow` attribute without specifying a reason' <<<"$out"; then
  pass T8 "exit $rc"
else
  fail T8 "exit $rc"
fi

echo
echo "== T9 control: a correctness lint (approx_constant, deny by default) fires in a test module"
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
        let pi = 3.14_f64;
        assert!(pi > 3.0);
        assert_eq!(double(2), 4);
    }
}
EOF
out=$(gate); rc=$?
show "$out"
if [ "$rc" -ne 0 ] && grep -q 'error: approximate value of `f64::consts::PI` found' <<<"$out"; then
  pass T9 "approx_constant is an error inside the test module (exit $rc)"
else
  fail T9 "exit $rc"
fi

echo
echo "== T10 the raw/muse.md:423 blanket allow (given a reason) silences that correctness lint too"
awk '/^mod tests \{$/ { print "#[allow(clippy::all, clippy::pedantic, reason = \"raw/muse.md:423 shape\")]" } { print }' crates/core/src/lib.rs > t.rs
mv t.rs crates/core/src/lib.rs
grep -n 'allow(clippy::all' crates/core/src/lib.rs
out=$(gate); rc=$?
show "$out"
if [ "$rc" -eq 0 ] && ! grep -q 'approximate value' <<<"$out"; then
  pass T10 "the gate passes with the 3.14 literal in place (exit $rc): the blanket allow hides correctness lints"
else
  fail T10 "exit $rc"
fi
write_lib

echo
echo "== T11 cargo test on the restored fixture"
out=$(cargo test --workspace --locked 2>&1); rc=$?
printf '%s\n' "$out" | grep -E '^test result' || true
if [ "$rc" -eq 0 ]; then pass T11 "exit $rc"; else fail T11 "exit $rc"; fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
