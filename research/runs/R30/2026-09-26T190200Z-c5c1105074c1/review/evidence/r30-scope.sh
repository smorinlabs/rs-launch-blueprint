#!/usr/bin/env bash
# R30 check S — gate scope: which targets and which feature configurations a
# `cargo check` invocation type-checks, and whether one --all-features run is enough.
# Zero external dependencies; scratch workspace outside the repository.
# Usage: bash r30-scope.sh > r30-scope.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
# tcargo T ARGS — run toolchain T's cargo AND its own rustc. Without RUSTC, `rustup run T cargo`
# on this host resolves `rustc` through PATH to Homebrew's 1.98.1, so a "floor" run would not be one.
tcargo() { local t=$1; shift; RUSTC="$(rustup which --toolchain "$t" rustc)" "$(rustup which --toolchain "$t" cargo)" "$@"; }
STABLE=(cargo)
FLOOR=(tcargo 1.96.0)

echo "# r30-scope.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
echo "# stable: $(cargo --version) / $(rustc --version)"
echo "# floor: $(tcargo 1.96.0 --version) / $(RUSTC=$(rustup which --toolchain 1.96.0 rustc); "$RUSTC" --version)"

WS=$(mktemp -d "${TMPDIR:-/tmp}/r30-scope.XXXXXX")
WS=$(cd "$WS" && pwd -P)
# private target dir inside the scratch workspace, so "cold" means cold and no other run shares fingerprints
export CARGO_TARGET_DIR="$WS/target"
echo "# CARGO_TARGET_DIR=<ws>/target"
trap 'rm -rf "$WS"' EXIT
cd "$WS" || exit 1

# run LABEL EXPECTED_EXIT CMD... — prints the command, cargo's diagnostics lines, exit code, and PASS/FAIL
fails=0
run() {
  local label=$1 want=$2; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  echo
  echo "== $label"
  echo "\$ $*"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|could not compile|Finished|-->' | sed 's#'"$WS"'#<ws>#g'
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}

mkdir -p src tests examples crates/core/src
cat > Cargo.toml <<'EOF'
[package]
name = "facade"
version = "0.1.0"
edition = "2024"

[features]
web = []

[dependencies]
core-crate = { path = "crates/core" }

[workspace]
members = ["crates/core"]
EOF
cat > crates/core/Cargo.toml <<'EOF'
[package]
name = "core-crate"
version = "0.1.0"
edition = "2024"
EOF
cat > crates/core/src/lib.rs <<'EOF'
pub fn answer() -> u32 { 42 }
EOF
cat > src/lib.rs <<'EOF'
//! Facade.
pub fn answer() -> u32 { core_crate::answer() }
#[cfg(feature = "web")]
pub mod web;
EOF
cat > src/web.rs <<'EOF'
pub fn route() -> u32 { crate::answer() }
EOF
cat > tests/it.rs <<'EOF'
#[test]
fn it_works() { assert_eq!(facade::answer(), 42); }
EOF
cat > examples/demo.rs <<'EOF'
fn main() { println!("{}", facade::answer()); }
EOF
"${STABLE[@]}" generate-lockfile --offline >/dev/null 2>&1

TC_OFF=(env CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going)
TC_ALL=(env CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going)

run "S0 clean tree, default features" 0 "${TC_OFF[@]}"
run "S0 clean tree, all features" 0 "${TC_ALL[@]}"

# S1: E0308 in an integration test file
cp tests/it.rs tests/it.rs.bak
printf 'fn _bad() -> u32 { "x" }\n' >> tests/it.rs
run "S1 tests/ E0308 — plain workspace check (lib+bins only)" 0 cargo check --workspace --locked
run "S1 tests/ E0308 — --all-targets" 101 cargo check --workspace --all-targets --locked
mv tests/it.rs.bak tests/it.rs

# S2: E0308 inside a #[cfg(test)] unit-test module of a member crate
cp crates/core/src/lib.rs lib.bak
printf '#[cfg(test)]\nmod t { fn _bad() -> u32 { "x" } }\n' >> crates/core/src/lib.rs
run "S2 #[cfg(test)] E0308 — plain workspace check" 0 cargo check --workspace --locked
run "S2 #[cfg(test)] E0308 — --all-targets" 101 cargo check --workspace --all-targets --locked
mv lib.bak crates/core/src/lib.rs

# S3: E0308 in an example
cp examples/demo.rs demo.bak
printf 'fn _bad() -> u32 { "x" }\n' >> examples/demo.rs
run "S3 examples/ E0308 — plain workspace check" 0 cargo check --workspace --locked
run "S3 examples/ E0308 — --all-targets" 101 cargo check --workspace --all-targets --locked
mv demo.bak examples/demo.rs

# S4: E0308 in the feature-gated web tree (web is off by default, as in R69's registry row)
cp src/web.rs web.bak
printf 'pub fn _bad() -> u32 { "x" }\n' >> src/web.rs
run "S4 web-gated E0308 — --all-targets, default features" 0 "${TC_OFF[@]}"
run "S4 web-gated E0308 — --all-targets --all-features" 101 "${TC_ALL[@]}"
mv web.bak src/web.rs

# S5: a warning that exists ONLY with the feature off: an import used solely by web-gated code
cp src/lib.rs lib.bak
cat > src/lib.rs <<'EOF'
//! Facade.
use core_crate::answer as core_answer;
pub fn answer() -> u32 { 42 }
#[cfg(feature = "web")]
pub fn web_answer() -> u32 { core_answer() }
#[cfg(feature = "web")]
pub mod web;
EOF
run "S5 feature-off-only unused import — gate with --all-features only" 0 "${TC_ALL[@]}"
run "S5 feature-off-only unused import — gate with default features" 101 "${TC_OFF[@]}"
mv lib.bak src/lib.rs

# S6: a type error that exists ONLY with the feature off
cp src/lib.rs lib.bak
printf '#[cfg(not(feature = "web"))]\npub fn _fallback() -> u32 { "x" }\n' >> src/lib.rs
run "S6 cfg(not(web)) E0308 — gate with --all-features only" 0 "${TC_ALL[@]}"
run "S6 cfg(not(web)) E0308 — gate with default features" 101 "${TC_OFF[@]}"
mv lib.bak src/lib.rs

# S7: doctests are outside every cargo check form
cp crates/core/src/lib.rs lib.bak
cat > crates/core/src/lib.rs <<'EOF'
/// ```
/// let s: u32 = "doctest type error";
/// ```
pub fn answer() -> u32 { 42 }
EOF
run "S7 doctest E0308 — cargo check --all-targets --all-features" 0 "${TC_ALL[@]}"
run "S7 doctest E0308 — cargo test --doc" 101 cargo test --workspace --doc --locked
mv lib.bak crates/core/src/lib.rs

# S8: --keep-going reports every failing crate; accepted on the 1.96.0 floor
# two independent units: core's unit-test target and facade's example (neither depends on the other)
cp crates/core/src/lib.rs lib.bak
cp examples/demo.rs demo.bak
printf '#[cfg(test)]\nmod t { fn _bad() -> u32 { "x" } }\n' >> crates/core/src/lib.rs
printf 'fn _bad() -> u32 { "x" }\n' >> examples/demo.rs
run "S8 two independent failing units, -j1, without --keep-going (stable)" 101 cargo check --workspace --all-targets --locked -j1
run "S8 two independent failing units, -j1, with --keep-going (stable)" 101 cargo check --workspace --all-targets --locked -j1 --keep-going
run "S8 --keep-going accepted on floor 1.96.0" 101 "${FLOOR[@]}" check --workspace --all-targets --locked -j1 --keep-going
mv lib.bak crates/core/src/lib.rs
mv demo.bak examples/demo.rs
run "S9 restored tree green again (floor 1.96.0, both configurations)" 0 "${FLOOR[@]}" check --workspace --all-targets --all-features --locked --keep-going

echo
echo "# summary: failures=$fails"
exit "$fails"
