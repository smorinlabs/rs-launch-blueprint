#!/usr/bin/env bash
# R28 revision 1 — autofix policy. Scratch workspace under mktemp (no network).
# NOTE: cases F3-F5 run `git init` and `git commit` INSIDE THE SCRATCH
# DIRECTORY ONLY, because `cargo fix` consults version control; no repository
# outside mktemp is read or written.
# Every case prints PASS or FAIL; the script exits 1 if any case fails.
# Patterns below are literal tool messages containing backticks, so single
# quotes are intended throughout.
# shellcheck disable=SC2016
set -uo pipefail
export RUSTUP_AUTO_INSTALL=0

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

echo "== toolchain on PATH"
echo "CARGO_HOME=${CARGO_HOME:-unset}"
command -v cargo cargo-clippy git
cargo --version
cargo clippy --version
git --version

echo
echo "== F1 clippy's own contract for --fix"
echo '$ cargo clippy --help'
help=$(cargo clippy --help 2>&1)
printf '%s\n' "$help" | grep -E -- '--fix|--no-deps|--all-targets|Automatically apply' || true
if grep -q 'Automatically apply lint suggestions' <<<"$help" \
   && grep -q 'implies `--no-deps` and `--all-targets`\|implies --no-deps and --all-targets' <<<"$help"; then
  pass F1 "--fix is an explicit flag that implies --no-deps and --all-targets"
else
  fail F1 "help text differs"
fi

scratch=$(mktemp -d "${TMPDIR:-/tmp}/r28-autofix.XXXXXX")
trap 'rm -rf "$scratch"' EXIT
cd "$scratch" || exit 1
echo
echo "== scratch: $scratch (outside any repository)"

mkdir -p crates/core/src
cat > Cargo.toml <<'EOF'
[workspace]
resolver = "3"
members = ["crates/core"]

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.lints.clippy]
allow_attributes_without_reason = "warn"
dbg_macro = "warn"
todo = "warn"
unimplemented = "warn"
unwrap_used = "warn"
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

/// Triples its input.
#[must_use]
pub fn triple(x: u32) -> u32 {
    return x * 3;
}
EOF
printf '/target\n' > .gitignore
cargo generate-lockfile --offline >/dev/null 2>&1 || cargo generate-lockfile

digest() { find . -path ./target -prune -o -path ./.git -prune -o -type f -print | LC_ALL=C sort | xargs shasum -a 256 | shasum -a 256; }

echo
echo "== F2 the check-only gate fails on a fixable lint and rewrites nothing"
before=$(digest)
echo '$ cargo clippy --workspace --all-targets --locked -- -D warnings'
out=$(cargo clippy --workspace --all-targets --locked -- -D warnings 2>&1); rc=$?
printf '%s\n' "$out" | grep -E '^error|-->' | head -n 3 || true
after=$(digest)
echo "tree digest before: $before"
echo "tree digest after:  $after"
if [ "$rc" -ne 0 ] && grep -q 'unneeded `return` statement' <<<"$out" && [ "$before" = "$after" ]; then
  pass F2 "gate exit $rc; source tree byte-identical"
else
  fail F2 "exit $rc"
fi

git init -q .
git -c user.name=r28 -c user.email=r28@example.invalid -c commit.gpgsign=false add -A
git -c user.name=r28 -c user.email=r28@example.invalid -c commit.gpgsign=false commit -q -m fixture
echo
echo "== scratch git: $(git rev-parse --short HEAD) committed (scratch only)"

echo
echo "== F3 the lint-fix recipe refuses a dirty tree (no --allow-dirty)"
printf '\n// uncommitted edit\n' >> crates/core/src/lib.rs
echo '$ cargo clippy --fix --workspace --all-targets'
out=$(cargo clippy --fix --workspace --all-targets 2>&1); rc=$?
printf '%s\n' "$out" | grep -E '^error' | head -n 2 || true
if [ "$rc" -ne 0 ] && grep -q 'has uncommitted changes' <<<"$out" && grep -q -- '--allow-dirty' <<<"$out"; then
  pass F3 "dirty-tree refusal (exit $rc)"
else
  fail F3 "exit $rc"
fi
git checkout -q -- crates/core/src/lib.rs

echo
echo "== F4 on a clean tree the lint-fix recipe applies the machine-applicable fix"
echo '$ cargo clippy --fix --workspace --all-targets'
out=$(cargo clippy --fix --workspace --all-targets 2>&1); rc=$?
printf '%s\n' "$out" | tail -n 3
diff=$(git diff -U0 -- crates/core/src/lib.rs)
printf '%s\n' "$diff"
if [ "$rc" -eq 0 ] && grep -q '^-    return x \* 3;$' <<<"$diff" && grep -q '^+    x \* 3$' <<<"$diff"; then
  pass F4 "needless_return rewritten (exit $rc)"
else
  fail F4 "exit $rc"
fi

echo
echo "== F5 after the fix the check-only gate passes"
out=$(cargo clippy --workspace --all-targets --locked -- -D warnings 2>&1); rc=$?
printf '%s\n' "$out" | tail -n 1
if [ "$rc" -eq 0 ]; then pass F5 "exit $rc"; else fail F5 "exit $rc"; fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
