#!/usr/bin/env bash
# R30 check X — suppression discipline under the denying gate (CARGO_BUILD_WARNINGS=deny):
# which suppression forms rustc rejects or flags, the blanket-allow gap, and #[expect]
# versus #[allow] for a lint that fires in only one feature configuration.
# Zero external dependencies; scratch crate outside the repository.
# Usage: bash r30-suppression.sh > r30-suppression.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
unset RUSTFLAGS CARGO_BUILD_WARNINGS CARGO_ENCODED_RUSTFLAGS

# tcargo T ARGS — run toolchain T's cargo AND its own rustc (see r30-severity.sh for why RUSTC is pinned)
tcargo() { local t=$1; shift; RUSTC="$(rustup which --toolchain "$t" rustc)" "$(rustup which --toolchain "$t" cargo)" "$@"; }

echo "# r30-suppression.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
echo "# stable: $(cargo --version) / $(rustc --version)"
echo "# 1.96.0: $(tcargo 1.96.0 --version) / $("$(rustup which --toolchain 1.96.0 rustc)" --version)"

WS=$(mktemp -d "${TMPDIR:-/tmp}/r30-suppression.XXXXXX")
WS=$(cd "$WS" && pwd -P)
export CARGO_TARGET_DIR="$WS/target"
echo "# CARGO_TARGET_DIR=<ws>/target"
trap 'rm -rf "$WS"' EXIT
cd "$WS" || exit 1

fails=0
run() {
  local label=$1 want=$2; shift 2
  local out rc
  out=$("$@" 2>&1); rc=$?
  echo
  echo "== $label"
  echo "\$ $*"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|warnings are denied|Finished' | sed 's#'"$WS"'#<ws>#g'
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}

mkdir -p src
cat > Cargo.toml <<'EOF'
[package]
name = "supp"
version = "0.1.0"
edition = "2024"

[features]
web = []
EOF
echo 'pub fn used() -> u32 { 1 }' > src/lib.rs
cargo generate-lockfile --offline >/dev/null 2>&1
BASE='pub fn used() -> u32 { 1 }'
GATE=(env CARGO_BUILD_WARNINGS=deny cargo check --all-targets --locked --keep-going)
GATE_ALL=(env CARGO_BUILD_WARNINGS=deny cargo check --all-targets --all-features --locked --keep-going)

case_src() { printf '%s\n%s\n' "$BASE" "$1" > src/lib.rs; }

case_src '#[allow]
pub fn a() {}'
run "X1 bare #[allow] — malformed attribute is a hard error" 101 "${GATE[@]}"

case_src '#[allow()]
pub fn a() {}'
run "X2 #[allow()] — names nothing; warns, so the denying gate fails" 101 "${GATE[@]}"

case_src '#[allow(unused_variabels)]
pub fn a() { let x = 1; }'
run "X3 misspelled lint name — unknown_lints (and the real warning) fail the gate" 101 "${GATE[@]}"

case_src '#[expect(dead_code, reason = "probe")]
pub fn a() {}'
run "X4 #[expect] that suppresses nothing — unfulfilled_lint_expectations fails the gate" 101 "${GATE[@]}"

case_src '#[expect(unused_variables, reason = "kept for the probe")]
pub fn a() { let x = 1; }'
run "X5 fulfilled #[expect(lint, reason)] — silent, gate green" 0 "${GATE[@]}"

# an inner attribute must precede every item, so this case writes the file itself
printf '%s\n' '#![allow(warnings)]' "$BASE" 'pub fn a() { let x = 1; }' > src/lib.rs
run "X6 crate-level #![allow(warnings)] — silences the warning; gate green (the known gap)" 0 "${GATE[@]}"

# X7/X8: a private helper used only by web-gated code is dead code only when web is off.
case_src 'fn helper() -> u32 { 2 }
#[cfg(feature = "web")]
pub fn route() -> u32 { helper() }'
run "X7a no suppression, default features — dead_code warning fails the gate" 101 "${GATE[@]}"
run "X7b no suppression, --all-features — clean" 0 "${GATE_ALL[@]}"

case_src '#[expect(dead_code, reason = "used only by the web feature")]
fn helper() -> u32 { 2 }
#[cfg(feature = "web")]
pub fn route() -> u32 { helper() }'
run "X8a #[expect] on the configuration-dependent lint, default features — fulfilled" 0 "${GATE[@]}"
run "X8b #[expect] on the configuration-dependent lint, --all-features — unfulfilled, gate fails" 101 "${GATE_ALL[@]}"

case_src '#[cfg_attr(not(feature = "web"), expect(dead_code, reason = "used only by the web feature"))]
fn helper() -> u32 { 2 }
#[cfg(feature = "web")]
pub fn route() -> u32 { helper() }'
run "X9a cfg_attr(not(web), expect(...)), default features — fulfilled" 0 "${GATE[@]}"
run "X9b cfg_attr(not(web), expect(...)), --all-features — absent, clean" 0 "${GATE_ALL[@]}"

case_src '#[allow(dead_code, reason = "used only by the web feature")]
fn helper() -> u32 { 2 }
#[cfg(feature = "web")]
pub fn route() -> u32 { helper() }'
run "X10a #[allow(lint, reason)], default features — clean" 0 "${GATE[@]}"
run "X10b #[allow(lint, reason)], --all-features — clean" 0 "${GATE_ALL[@]}"

case_src '#[expect(unused_variables, reason = "floor probe")]
pub fn a() { let x = 1; }'
run "X11 #[expect(lint, reason)] accepted by the 1.96.0 floor rustc" 0 tcargo 1.96.0 check --all-targets --locked
case_src '#[expect(dead_code, reason = "floor probe")]
pub fn a() {}'
run "X12 unfulfilled #[expect] warns on the 1.96.0 floor rustc (deny via RUSTFLAGS there)" 101 env RUSTFLAGS=-Dwarnings RUSTC="$(rustup which --toolchain 1.96.0 rustc)" "$(rustup which --toolchain 1.96.0 cargo)" check --all-targets --locked

echo
echo "# summary: failures=$fails"
exit "$fails"
