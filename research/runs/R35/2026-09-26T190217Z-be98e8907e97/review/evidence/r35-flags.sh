#!/usr/bin/env bash
# R35 revision 1 — the flag surface the two legs disagree about, executed.
#   doc tests on stable (Muse: `--doc` includes them; Opus: nightly-only),
#   one report format per invocation (the basis for the --no-report recipe),
#   branch coverage on stable, the report subcommand's gate flags,
#   and the README statements on exclusions and known limitations.
# Tiny fixture: one library crate with a unit test and a doc test.
# Toolchain: rustup 1.93.0 (the only local toolchain carrying llvm-tools-preview).
# Usage: bash r35-flags.sh   (CARGO_HOME must hold cargo-llvm-cov 0.9.1)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
readme="$here/snapshots/cargo-llvm-cov-0.9.1-README.md"
: "${CARGO_HOME:?CARGO_HOME must point at the private cargo home}"
export PATH="$HOME/.cargo/bin:$CARGO_HOME/bin:$PATH"
export RUSTUP_TOOLCHAIN=1.93.0 CARGO_LLVM_COV_SETUP=no CARGO_TERM_COLOR=never
unset CARGO_TARGET_DIR RUSTFLAGS
fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }
# Runs a command expected to FAIL; records its exit status and first error line.
expect_fail() {
  local id="$1" desc="$2" out; shift 2
  set +e; out="$("$@" 2>&1)"; local rc=$?; set -e
  info "$id: \`$*\` exit=$rc: $(/usr/bin/grep -m1 -i 'error' <<<"$out" || head -n1 <<<"$out")"
  if [ "$rc" -ne 0 ]; then ok "$id" "$desc"; else bad "$id" "$desc (it succeeded)"; fi
}

info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ) | $(rustc --version) | $(cargo llvm-cov --version)"
mkdir -p "$fx/src"
cat >"$fx/Cargo.toml" <<'EOF'
[package]
name = "flagfx"
version = "0.1.0"
edition = "2024"
publish = false
EOF
cat >"$fx/src/lib.rs" <<'EOF'
/// Doubles `x`.
///
/// ```
/// assert_eq!(flagfx::double(2), 4);
/// ```
pub fn double(x: i32) -> i32 {
    x * 2
}

/// Reached only by the doc test below.
///
/// ```
/// assert_eq!(flagfx::triple(2), 6);
/// ```
pub fn triple(x: i32) -> i32 {
    x * 3
}

#[cfg(test)]
mod tests {
    #[test]
    fn doubles() {
        assert_eq!(super::double(3), 6);
    }
}
EOF
cd "$fx"
cargo generate-lockfile >/dev/null 2>&1

# --- report subcommand gate/format flags (replaces a citation to the help text) ---
rhelp="$(cargo llvm-cov report --help)"
for f in --fail-under-lines --fail-under-functions --fail-under-regions --show-missing-lines \
         --ignore-filename-regex --lcov --html --cobertura --json --output-path; do
  check "F1${f}" "cargo llvm-cov report accepts $f" /usr/bin/grep -q -- "$f" <<<"$rhelp"
done
mhelp="$(cargo llvm-cov --help)"
check F2a "main help marks --doctests as unstable" /usr/bin/grep -q -A1 -- '--doctests$' <<<"$mhelp"
/usr/bin/grep -A1 -E -- '^ +--(doctests|branch|doc)$' <<<"$mhelp" | sed 's/^/INFO help: /'
check F2b "main help documents --no-report" /usr/bin/grep -q -- '--no-report' <<<"$mhelp"

# --- baseline: plain instrumented run works on stable ----------------------------
if cargo llvm-cov --locked --summary-only >"$fx/../base.log" 2>&1; then
  ok F3 "cargo llvm-cov (no doc flags) succeeds on stable 1.93.0"
else
  bad F3 "baseline run failed"; tail -20 "$fx/../base.log"
fi
tri="$(cargo llvm-cov report --json --summary-only | jq -r '.data[0].totals.functions | "\(.covered)/\(.count)"')"
info "functions covered without doc tests: $tri — double, triple, and the in-file #[cfg(test)] fn doubles"
cargo llvm-cov report --lcov --output-path "$fx/../flags.info" >/dev/null 2>&1
/usr/bin/grep -E '^FNDA:' "$fx/../flags.info" | sed 's/^/INFO flags lcov: /'
check F3b "without doc tests, triple() (reached only by its doc test) is recorded with zero executions" \
  /usr/bin/grep -q -E '^FNDA:0,.*triple' "$fx/../flags.info"
check F3c "an in-file #[cfg(test)] test function is itself counted as a function (the default regex excludes tests/ dirs and tests.rs files only)" \
  /usr/bin/grep -q -E '^FNDA:[1-9][0-9]*,.*doubles' "$fx/../flags.info"

# --- doc tests on stable -----------------------------------------------------------
expect_fail F4a "cargo llvm-cov --doctests is rejected on stable" cargo llvm-cov --doctests --locked
expect_fail F4b "cargo llvm-cov --doc (Muse's flag) is rejected on stable" cargo llvm-cov --doc --locked
check F4c "cargo test --doc still runs the doc tests uninstrumented (R32's F132 path)" \
  bash -c 'cargo test --doc --locked >/dev/null 2>&1'

# --- branch coverage on stable -------------------------------------------------------
expect_fail F5 "cargo llvm-cov --branch is rejected on stable (regions are not branches)" cargo llvm-cov --branch --locked

# --- one format per invocation ------------------------------------------------------
expect_fail F6a "--lcov and --html together are rejected (one format per invocation)" cargo llvm-cov --lcov --html --locked
cargo llvm-cov clean --workspace >/dev/null 2>&1
cargo llvm-cov --no-report --locked >/dev/null 2>&1
cargo llvm-cov report --html >/dev/null 2>&1
cargo llvm-cov report --lcov --output-path target/llvm-cov/lcov.info >/dev/null 2>&1
check F6b "one --no-report run feeds both report --html and report --lcov" \
  test -s target/llvm-cov/html/index.html -a -s target/llvm-cov/lcov.info
set +e; cargo llvm-cov report --fail-under-lines 100 >/dev/null 2>&1; gate=$?; set -e
info "report --fail-under-lines 100 exit=$gate"
check F6c "the gate flag on report fails a below-floor run" test "$gate" -ne 0

# --- external-test escape hatch named in the DECISION -------------------------------
check F7 "cargo llvm-cov show-env prints the instrumentation environment" \
  bash -c 'cargo llvm-cov show-env | /usr/bin/grep -q RUSTFLAGS'

# --- README statements (packaged README of the installed 0.9.1) ---------------------
check F8a "README Known limitations: doc-test support is unstable" \
  /usr/bin/grep -q '^- Support for doc tests is unstable' "$readme"
check F8b "README Known limitations: branch coverage is unstable" \
  /usr/bin/grep -q '^- Support for branch coverage is unstable' "$readme"
# shellcheck disable=SC2016  # the backticks are literal Markdown in the README, not substitutions
check F8c "README: #[coverage(off)] is unstable (item-level exclusion is nightly-only)" \
  /usr/bin/grep -q 'Since `#\[coverage(off)\]` is unstable' "$readme"
check F8d "README default ignore regex excludes tests/examples/benches directories" \
  /usr/bin/grep -q '(tests|examples|benches){SEPARATOR}' "$readme"
check F8e "README default ignore regex excludes the Cargo registry" \
  /usr/bin/grep -q '{CARGO_HOME}{SEPARATOR}(registry|git)' "$readme"
check F8f "README names no threshold environment variable (the flags are the only declaration)" \
  bash -c "! /usr/bin/grep -q 'FAIL_UNDER' '$readme'"
# shellcheck disable=SC2016  # the backticks are literal Markdown in the README, not substitutions
/usr/bin/grep -n '^- Support for\|Since `#\[coverage(off)\]` is unstable\|(tests|examples|benches){SEPARATOR}' "$readme" | sed 's/^/INFO README:/'

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
