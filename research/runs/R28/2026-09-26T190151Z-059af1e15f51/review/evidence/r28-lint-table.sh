#!/usr/bin/env bash
# R28 revision 1 — lint-table mechanics. Builds a scratch two-member workspace
# under mktemp (no network: no external dependencies), then asserts, case by
# case, the behaviours the decision's rule-selection member rests on.
# Every case prints PASS or FAIL; the script exits 1 if any case fails.
# Manifest variants are written whole by functions (no in-place sed edits), so
# the script behaves the same under BSD and GNU userlands.
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
rustc -vV | sed -n '1,4p'

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-lint-table.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
cd "$scratch" || exit 1
echo "== scratch: $scratch (outside any repository)"

# The recommended [workspace.lints.clippy] body. R06's three unsafe entries are
# carried from raw/opus.md:159-161; the five picks are this decision's.
RECOMMENDED_CLIPPY='undocumented_unsafe_blocks = "deny"
multiple_unsafe_ops_per_block = "deny"
unnecessary_safety_comment = "deny"
allow_attributes_without_reason = "warn"
dbg_macro = "warn"
todo = "warn"
unimplemented = "warn"
unwrap_used = "warn"'

# raw/muse.md:239-242 (priority form of all/pedantic plus one named lint).
MUSE_CLIPPY='all = { level = "deny", priority = -1 }
pedantic = { level = "warn", priority = -1 }
undocumented_unsafe_blocks = "warn"'

# write_root_manifest [group-lines] [clippy-body]
write_root_manifest() {
  local groups=${1:-} body=${2:-$RECOMMENDED_CLIPPY}
  {
    cat <<'EOF'
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
EOF
    [ -n "$groups" ] && printf '%s\n' "$groups"
    printf '%s\n' "$body"
  } > Cargo.toml
}

write_fixture() {
  mkdir -p crates/core/src crates/core/tests crates/cli/src
  write_root_manifest
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
  cat > crates/core/src/lib.rs <<'EOF'
//! Core library of the scratch fixture.

pub mod extra;

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
        assert_eq!(double("2".parse().unwrap()), 4);
    }
}
EOF
  printf '//! Items the cases below append to.\n' > crates/core/src/extra.rs
  cat > crates/core/tests/integration.rs <<'EOF'
#[test]
fn integration_doubles() {
    assert_eq!(r28_core::double("3".parse().unwrap()), 6);
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
    #[cfg(feature = "web")]
    println!("web");
}
EOF
  cargo generate-lockfile --offline >/dev/null 2>&1 || cargo generate-lockfile
}

gate() { cargo clippy --workspace --all-targets --locked "$@" -- -D warnings 2>&1; }

write_fixture

echo
echo "== L1 recommended fixture, feature off"
echo '$ cargo clippy --workspace --all-targets --locked -- -D warnings'
out=$(gate); rc=$?
printf '%s\n' "$out" | tail -n 2
if [ "$rc" -eq 0 ]; then pass L1 "clean fixture passes the gate (exit $rc)"; else fail L1 "exit $rc"; fi

echo
echo "== L2 recommended fixture, feature on (R11's check job runs clippy feature off and on)"
echo '$ cargo clippy --workspace --all-targets --locked --features web -- -D warnings   (the recipe spelling; only r28-cli defines web)'
out=$(gate --features web); rc=$?
printf '%s\n' "$out" | tail -n 2
echo '$ cargo clippy --workspace --all-targets --locked --all-features -- -D warnings'
gate --all-features >/dev/null; rc_all=$?
if [ "$rc" -eq 0 ] && [ "$rc_all" -eq 0 ]; then pass L2 "clean fixture passes with --features web (exit $rc) and with --all-features (exit $rc_all)"; else fail L2 "--features web exit $rc, --all-features exit $rc_all"; fi

echo
echo "== L3 tests still run"
echo '$ cargo test --workspace --locked'
out=$(cargo test --workspace --locked 2>&1); rc=$?
printf '%s\n' "$out" | grep -E '^test result' || true
if [ "$rc" -eq 0 ]; then pass L3 "cargo test passes (exit $rc)"; else fail L3 "exit $rc"; fi

echo
echo "== L4 dbg!/todo! in shipped code fail the gate"
cp crates/core/src/extra.rs extra.rs.orig
cat >> crates/core/src/extra.rs <<'EOF'

/// Unfinished.
pub fn unfinished() -> u32 {
    dbg!(1);
    todo!()
}
EOF
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^(error|warning)' || true
if [ "$rc" -ne 0 ] && grep -q 'the `dbg!` macro is intended as a debugging tool' <<<"$out" \
   && grep -q '`todo` should not be present in production code' <<<"$out"; then
  pass L4 "dbg_macro and todo both fire and the gate fails (exit $rc)"
else
  fail L4 "exit $rc"
fi
cp extra.rs.orig crates/core/src/extra.rs

echo
echo "== L5 a group line without priority beside named lints is rejected"
write_root_manifest 'all = "warn"'
grep -n '^all' Cargo.toml
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 3 || true
if [ "$rc" -ne 0 ] && grep -q 'lint group `all` has the same priority (0) as a lint' <<<"$out"; then
  pass L5 "lint_groups_priority rejects the bare group line (exit $rc)"
else
  fail L5 "exit $rc"
fi
write_root_manifest

echo
echo "== L6 all = warn at priority -1 downgrades the deny-by-default correctness group"
cat >> crates/core/src/extra.rs <<'EOF'

/// Always false for an unsigned value.
#[must_use]
pub fn is_negative(x: u32) -> bool {
    x < 0
}
EOF
out_default=$(gate); rc_default=$?
printf '%s\n' "$out_default" | grep -E 'absurd_extreme_comparisons|^error: this comparison|^warning: this comparison' || true
write_root_manifest 'all = { level = "warn", priority = -1 }'
out_all=$(cargo clippy --workspace --all-targets --locked 2>&1); rc_all=$?
printf '%s\n' "$out_all" | grep -E 'absurd_extreme_comparisons|^error: this comparison|^warning: this comparison' || true
if grep -q 'error: this comparison involving the minimum or maximum element' <<<"$out_default" \
   && [ "$rc_default" -ne 0 ] \
   && grep -q 'warning: this comparison involving the minimum or maximum element' <<<"$out_all" \
   && [ "$rc_all" -eq 0 ]; then
  pass L6 "default: error (exit $rc_default); with all = warn: warning and exit $rc_all without -D warnings (downgrade observed)"
else
  fail L6 "default rc $rc_default, all=warn rc $rc_all"
fi
write_root_manifest
cp extra.rs.orig crates/core/src/extra.rs

echo
echo "== L7 a member may not override the workspace lint table"
cp crates/cli/Cargo.toml cli.toml.orig
cat >> crates/cli/Cargo.toml <<'EOF'

[lints.clippy]
unwrap_used = "allow"
EOF
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E 'error|cannot override' | head -n 3 || true
if [ "$rc" -ne 0 ] && grep -q 'cannot override `workspace.lints` in `lints`' <<<"$out"; then
  pass L7 "member override is a manifest error (exit $rc)"
else
  fail L7 "exit $rc"
fi
cp cli.toml.orig crates/cli/Cargo.toml

echo
echo "== L8 clippy.toml does not accept lint levels"
cp clippy.toml clippy.toml.orig
printf 'unwrap_used = "deny"\n' >> clippy.toml
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 2 || true
if [ "$rc" -ne 0 ] && grep -q 'unknown field `unwrap_used`' <<<"$out"; then
  pass L8 "a lint-level key in clippy.toml is an unknown-field error (exit $rc)"
else
  fail L8 "exit $rc"
fi
cp clippy.toml.orig clippy.toml

echo
echo "== L9 a pedantic warning passes the Muse recipe (no -D warnings) and fails R11's gate (-D warnings)"
write_root_manifest '' "$MUSE_CLIPPY"
sed -n '/^\[workspace.lints.clippy\]$/,$p' Cargo.toml
cat >> crates/core/src/extra.rs <<'EOF'

/// Widens a byte.
#[must_use]
pub fn widen(x: u8) -> u32 {
    x as u32
}
EOF
echo '$ cargo clippy --workspace --all-targets --locked   (raw/muse.md:167 recipe shape: no -D warnings)'
out_m=$(cargo clippy --workspace --all-targets --locked 2>&1); rc_m=$?
printf '%s\n' "$out_m" | grep -E '^(error|warning)' | head -n 3 || true
echo '$ cargo clippy --workspace --all-targets --locked -- -D warnings   (R11 DECISION.md:268)'
out_d=$(gate); rc_d=$?
printf '%s\n' "$out_d" | grep -E '^error' | head -n 2 || true
if [ "$rc_m" -eq 0 ] && grep -q 'can be expressed infallibly' <<<"$out_m" && [ "$rc_d" -ne 0 ]; then
  pass L9 "pedantic warning passes without -D warnings (exit $rc_m) and fails with it (exit $rc_d)"
else
  fail L9 "no -D warnings rc $rc_m, with -D warnings rc $rc_d"
fi
cp extra.rs.orig crates/core/src/extra.rs

echo
echo "== L10 a style lint: the Muse table (all = deny) blocks a local run; the recommended table warns locally and gates under -D warnings"
cat >> crates/core/src/extra.rs <<'EOF'

/// Triples its input.
#[must_use]
pub fn triple(x: u32) -> u32 {
    return x * 3;
}
EOF
out_m=$(cargo clippy --workspace --all-targets --locked 2>&1); rc_m=$?
printf '%s\n' "$out_m" | grep -E '^(error|warning): unneeded `return`' || true
write_root_manifest
out_r=$(cargo clippy --workspace --all-targets --locked 2>&1); rc_r=$?
printf '%s\n' "$out_r" | grep -E '^(error|warning): unneeded `return`' || true
gate >/dev/null; rc_g=$?
if [ "$rc_m" -ne 0 ] && grep -q '^error: unneeded `return`' <<<"$out_m" \
   && [ "$rc_r" -eq 0 ] && grep -q '^warning: unneeded `return`' <<<"$out_r" && [ "$rc_g" -ne 0 ]; then
  pass L10 "Muse table local exit $rc_m (error); recommended local exit $rc_r (warning); recommended gate exit $rc_g"
else
  fail L10 "muse $rc_m, recommended local $rc_r, recommended gate $rc_g"
fi
cp extra.rs.orig crates/core/src/extra.rs

echo
echo "== L11 rustc warnings also fail the gate under -D warnings"
cp crates/cli/src/main.rs main.rs.orig
cat >> crates/cli/src/main.rs <<'EOF'

fn unused_helper() -> u32 {
    7
}
EOF
out=$(gate); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 2 || true
if [ "$rc" -ne 0 ] && grep -q 'function `unused_helper` is never used' <<<"$out"; then
  pass L11 "dead_code fails the gate (exit $rc)"
else
  fail L11 "exit $rc"
fi
cp main.rs.orig crates/cli/src/main.rs

echo
echo "== L12 non-virtual workspace (a root package, the shape R11's owns line describes): without --workspace a member's test target is not linted"
nv="$scratch/nonvirtual"
mkdir -p "$nv/src" "$nv/crates/core/src" "$nv/crates/core/tests"
cat > "$nv/Cargo.toml" <<'EOF'
[package]
name = "r28-root"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[dependencies]
r28-core = { path = "crates/core" }

[workspace]
resolver = "3"
members = ["crates/core"]
EOF
printf 'fn main() {\n    println!("{}", r28_core::double(21));\n}\n' > "$nv/src/main.rs"
cat > "$nv/crates/core/Cargo.toml" <<'EOF'
[package]
name = "r28-core"
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"
EOF
cat > "$nv/crates/core/src/lib.rs" <<'EOF'
//! Core.

/// Doubles its input.
#[must_use]
pub fn double(x: u32) -> u32 {
    x * 2
}
EOF
cat > "$nv/crates/core/tests/integration.rs" <<'EOF'
#[test]
fn pi_is_close() {
    let pi = 3.14_f64;
    assert!(pi > 3.0);
}
EOF
( cd "$nv" && { cargo generate-lockfile --offline >/dev/null 2>&1 || cargo generate-lockfile; } )
echo '$ cargo clippy --all-targets --locked   (at the root; the raw/muse.md:167 recipe omits --workspace)'
out_n=$(cd "$nv" && cargo clippy --all-targets --locked 2>&1); rc_n=$?
printf '%s\n' "$out_n" | grep -E '^(error|warning)|Checking' | head -n 4 || true
echo '$ cargo clippy --workspace --all-targets --locked'
out_w=$(cd "$nv" && cargo clippy --workspace --all-targets --locked 2>&1); rc_w=$?
printf '%s\n' "$out_w" | grep -E '^error|-->' | head -n 3 || true
if [ "$rc_n" -eq 0 ] && ! grep -q 'approximate value' <<<"$out_n" \
   && [ "$rc_w" -ne 0 ] && grep -q 'approximate value of `f64::consts::PI` found' <<<"$out_w"; then
  pass L12 "root-only run exit $rc_n misses crates/core/tests; --workspace run exit $rc_w catches the deny-by-default lint"
else
  fail L12 "root-only rc $rc_n, --workspace rc $rc_w"
fi

echo
echo "== L13 missing_safety_doc is on by default (not a pedantic lint)"
sd="$scratch/safetydoc"
mkdir -p "$sd/src"
cat > "$sd/Cargo.toml" <<'EOF'
[package]
name = "r28-safetydoc"
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"

# Its own workspace root, so the scratch workspace above does not claim it.
[workspace]
EOF
cat > "$sd/src/lib.rs" <<'EOF'
//! Deliberately undocumented unsafe fn.

/// Does nothing.
pub unsafe fn nothing() {}
EOF
( cd "$sd" && { cargo generate-lockfile --offline >/dev/null 2>&1 || cargo generate-lockfile; } )
echo '$ cargo clippy --locked   (no [lints] table: clippy defaults only)'
out=$(cd "$sd" && cargo clippy --locked 2>&1); rc=$?
printf '%s\n' "$out" | grep -E '^warning: unsafe function|missing_safety_doc' | head -n 3 || true
if [ "$rc" -eq 0 ] && grep -q '#\[warn(clippy::missing_safety_doc)\]` on by default' <<<"$out"; then
  pass L13 "missing_safety_doc warns with no group enabled (exit $rc)"
else
  fail L13 "exit $rc"
fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
