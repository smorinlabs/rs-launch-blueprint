#!/usr/bin/env bash
# R30 check W — warning severity tier: Cargo's build.warnings (CARGO_BUILD_WARNINGS=deny)
# versus RUSTFLAGS="-D warnings", per toolchain (1.96.0 floor, 1.97.1, 1.98.1 stable),
# the committed-config form, and the effect of each on Cargo's fingerprints (re-checks).
# Zero external dependencies; scratch workspace outside the repository.
# Usage: bash r30-severity.sh > r30-severity.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
unset RUSTFLAGS CARGO_BUILD_WARNINGS CARGO_ENCODED_RUSTFLAGS

# tcargo T ARGS — run toolchain T's cargo AND its own rustc. Without RUSTC, `rustup run T cargo`
# on this host resolves `rustc` through PATH to Homebrew's 1.98.1, so a "floor" run would not be one.
tcargo() { local t=$1; shift; RUSTC="$(rustup which --toolchain "$t" rustc)" "$(rustup which --toolchain "$t" cargo)" "$@"; }
# with VAR=VALUE CMD... — run CMD (a function or a command) with one extra environment variable
# shellcheck disable=SC2329  # invoked indirectly, as the first word of run's "$@"
with() { local kv=$1; shift; ( export "${kv?}"; "$@" ); }

echo "# r30-severity.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
for tc in 1.96.0 1.97.1; do echo "# $tc: $(tcargo "$tc" --version) / $("$(rustup which --toolchain "$tc" rustc)" --version)"; done
echo "# stable (PATH): $(cargo --version) / $(rustc --version)"

WS=$(mktemp -d "${TMPDIR:-/tmp}/r30-severity.XXXXXX")
WS=$(cd "$WS" && pwd -P)
# private target dir inside the scratch workspace, so "cold" means cold and no other run shares fingerprints
export CARGO_TARGET_DIR="$WS/target"
echo "# CARGO_TARGET_DIR=<ws>/target"
trap 'rm -rf "$WS"' EXIT
cd "$WS" || exit 1

fails=0
# run LABEL EXPECTED_EXIT CMD... — prints command, diagnostics and the units cargo (re)checked
run() {
  local label=$1 want=$2; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  echo
  echo "== $label"
  echo "\$ $*"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|^ +Checking |warnings are denied|Finished' | sed 's#'"$WS"'#<ws>#g'
  echo "units re-checked: $(printf '%s\n' "$out" | grep -c '^ *Checking ')"
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}

mkdir -p src crates/leaf/src
cat > Cargo.toml <<'EOF'
[package]
name = "app"
version = "0.1.0"
edition = "2024"

[dependencies]
leaf = { path = "crates/leaf" }

[workspace]
members = ["crates/leaf"]
EOF
cat > crates/leaf/Cargo.toml <<'EOF'
[package]
name = "leaf"
version = "0.1.0"
edition = "2024"
EOF
echo 'pub fn one() -> u32 { 1 }' > crates/leaf/src/lib.rs
cat > src/lib.rs <<'EOF'
pub fn two() -> u32 { let unused = 5; leaf::one() + 1 }
EOF
cargo generate-lockfile --offline >/dev/null 2>&1

CHECK=(check --workspace --all-targets --locked --keep-going)

echo
echo "# --- W1: CARGO_BUILD_WARNINGS=deny per toolchain (one unused-variable warning in the tree)"
for tc in 1.96.0 1.97.1; do
  run "W1 $tc plain" 0 tcargo "$tc" "${CHECK[@]}"
  if [[ $tc == 1.96.0 ]]; then want=0; else want=101; fi
  run "W1 $tc CARGO_BUILD_WARNINGS=deny" "$want" with CARGO_BUILD_WARNINGS=deny tcargo "$tc" "${CHECK[@]}"
done
run "W1 1.98.1 plain" 0 cargo "${CHECK[@]}"
run "W1 1.98.1 CARGO_BUILD_WARNINGS=deny" 101 env CARGO_BUILD_WARNINGS=deny cargo "${CHECK[@]}"
run "W1 1.96.0 RUSTFLAGS=-Dwarnings (works on the floor)" 101 with RUSTFLAGS=-Dwarnings tcargo 1.96.0 "${CHECK[@]}"

echo
echo "# --- W2: committed config-file form, [build] warnings = \"deny\""
mkdir -p .cargo
printf '[build]\nwarnings = "deny"\n' > .cargo/config.toml
run "W2 1.96.0 with .cargo/config.toml build.warnings=deny (key unknown to 1.96)" 0 tcargo 1.96.0 "${CHECK[@]}"
run "W2 1.98.1 with .cargo/config.toml — every plain local build now fails" 101 cargo "${CHECK[@]}"
rm -rf .cargo

echo
echo "# --- W3: fingerprint effect on 1.98.1, fresh target dir"
rm -rf "$CARGO_TARGET_DIR"
run "W3a plain (cold)" 0 cargo "${CHECK[@]}"
run "W3b CARGO_BUILD_WARNINGS=deny after plain — expect 0 units re-checked, warning replayed as failure" 101 env CARGO_BUILD_WARNINGS=deny cargo "${CHECK[@]}"
run "W3c plain again — expect 0 units re-checked" 0 cargo "${CHECK[@]}"
run "W3d RUSTFLAGS=-Dwarnings after plain — expect every unit re-checked (new fingerprint)" 101 env RUSTFLAGS=-Dwarnings cargo "${CHECK[@]}"
run "W3e plain after RUSTFLAGS — plain artifacts still present, 0 re-checked" 0 cargo "${CHECK[@]}"

echo
echo "# --- W4: with the warning fixed, the denying gate is green on every toolchain"
echo 'pub fn two() -> u32 { leaf::one() + 1 }' > src/lib.rs
for tc in 1.96.0 1.97.1; do
  run "W4 $tc CARGO_BUILD_WARNINGS=deny, clean tree" 0 with CARGO_BUILD_WARNINGS=deny tcargo "$tc" "${CHECK[@]}"
done
run "W4 1.98.1 CARGO_BUILD_WARNINGS=deny, clean tree" 0 env CARGO_BUILD_WARNINGS=deny cargo "${CHECK[@]}"

echo
echo "# summary: failures=$fails"
exit "$fails"
