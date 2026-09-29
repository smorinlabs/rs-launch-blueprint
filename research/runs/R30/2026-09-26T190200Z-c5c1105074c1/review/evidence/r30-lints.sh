#!/usr/bin/env bash
# R30 check L — the strictness surface: [workspace.lints.rust] inheritance, the
# rust_2018_idioms entry (Opus leg) on the floor and on stable, and whether a
# misspelled feature cfg needs an explicit unexpected_cfgs entry (Muse leg).
# Zero external dependencies; scratch workspace outside the repository.
# Usage: bash r30-lints.sh > r30-lints.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
unset RUSTFLAGS CARGO_BUILD_WARNINGS CARGO_ENCODED_RUSTFLAGS

# tcargo T ARGS — run toolchain T's cargo AND its own rustc (see r30-severity.sh for why RUSTC is pinned)
tcargo() { local t=$1; shift; RUSTC="$(rustup which --toolchain "$t" rustc)" "$(rustup which --toolchain "$t" cargo)" "$@"; }

echo "# r30-lints.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
echo "# stable: $(cargo --version) / $(rustc --version)"
echo "# 1.96.0: $(tcargo 1.96.0 --version) / $("$(rustup which --toolchain 1.96.0 rustc)" --version)"

WS=$(mktemp -d "${TMPDIR:-/tmp}/r30-lints.XXXXXX")
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
  echo "\$ $*" | sed "s#$HOME#~#g"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|warnings are denied|Finished|-->|#\[(warn|deny)\(' | sed 's#'"$WS"'#<ws>#g'
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}

mkdir -p src crates/inherits/src crates/optout/src
write_root() {
  cat > Cargo.toml <<EOF
[package]
name = "facade"
version = "0.1.0"
edition = "2024"

[features]
web = []

[lints]
workspace = true

[workspace]
members = ["crates/inherits", "crates/optout"]

[workspace.lints.rust]
$1
EOF
}
for m in inherits optout; do
  cat > "crates/$m/Cargo.toml" <<EOF
[package]
name = "$m"
version = "0.1.0"
edition = "2024"
EOF
done
printf '\n[lints]\nworkspace = true\n' >> crates/inherits/Cargo.toml
# A signature that ONLY elided_lifetimes_in_paths flags: a borrowed type in argument position,
# with no other elided lifetime for mismatched_lifetime_syntaxes to compare it with.
TAKE='pub struct Wrap<'"'"'a>(pub &'"'"'a str);
pub fn len(w: Wrap) -> usize { w.0.len() }'
printf '%s\n' "$TAKE" > crates/inherits/src/lib.rs
printf '%s\n' "$TAKE" > crates/optout/src/lib.rs
echo 'pub fn f() -> u32 { 1 }' > src/lib.rs
write_root 'rust_2018_idioms = { level = "warn", priority = -1 }'
cargo generate-lockfile --offline >/dev/null 2>&1

GATE=(env CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going)

echo
echo "# --- L0: the Opus leg's E13 example needs no table entry: rustc's default lints already flag it"
cat > crates/optout/src/lib.rs <<'EOF'
pub struct Wrap<'a>(pub &'a str);
pub fn mk(s: &str) -> Wrap { Wrap(s) }
EOF
run "L0a fn mk(s: &str) -> Wrap in the member WITHOUT the table — default lint warns, gate fails" 101 "${GATE[@]}"
run "L0b same, on the 1.96.0 floor rustc — the default lint warns there too" 0 tcargo 1.96.0 check --workspace --all-targets --locked
printf '%s\n' "$TAKE" > crates/optout/src/lib.rs

echo
echo "# --- L1: rust_2018_idioms through [workspace.lints.rust]; only the member with [lints] workspace = true inherits it"
run "L1a stable gate — inherits fails on elided_lifetimes_in_paths, optout (same code) is silent" 101 "${GATE[@]}"
run "L1b stable plain cargo check — same warning, exit 0 (the lax local tier survives)" 0 cargo check --workspace --all-targets --locked
run "L1c 1.96.0 floor rustc — the table is read, same warning emitted" 0 tcargo 1.96.0 check --workspace --all-targets --locked
run "L1d 1.96.0 floor rustc with RUSTFLAGS=-Dwarnings — denied there too" 101 env RUSTFLAGS=-Dwarnings RUSTC="$(rustup which --toolchain 1.96.0 rustc)" "$(rustup which --toolchain 1.96.0 cargo)" check --workspace --all-targets --locked
cat > crates/inherits/src/lib.rs <<'EOF'
pub struct Wrap<'a>(pub &'a str);
pub fn len(w: Wrap<'_>) -> usize { w.0.len() }
EOF
run "L1e fixed to Wrap<'_> — stable gate green" 0 "${GATE[@]}"
run "L1f fixed to Wrap<'_> — floor green" 0 tcargo 1.96.0 check --workspace --all-targets --locked

echo
echo "# --- L2: a misspelled feature name in cfg, with NO unexpected_cfgs entry in the table"
printf '%s\n' 'pub fn f() -> u32 { 1 }' '#[cfg(feature = "wbe")]' 'pub fn typo() {}' > src/lib.rs
run "L2a stable plain — Cargo's automatic --check-cfg already warns (unexpected_cfgs)" 0 cargo check --workspace --all-targets --locked
run "L2b stable gate — the warning fails the gate with no table entry" 101 "${GATE[@]}"
run "L2c 1.96.0 floor rustc — warns there too" 0 tcargo 1.96.0 check --workspace --all-targets --locked

echo
echo "# --- L3: the Muse leg's entry, unexpected_cfgs = \"deny\" in the committed table"
write_root 'rust_2018_idioms = { level = "warn", priority = -1 }
unexpected_cfgs = "deny"'
run "L3 stable plain cargo check — now a hard error in every local build (lax local tier lost)" 101 cargo check --workspace --all-targets --locked

echo
echo "# --- L4: what rust_2018_idioms contains, and which of its members edition 2024 already makes hard errors"
echo "\$ rustc -W help | grep rust-2018-idioms   (stable, then 1.96.0)"
rustc -W help 2>/dev/null | grep -E '^ +rust-2018-idioms ' | sed 's/^ *//'
"$(rustup which --toolchain 1.96.0 rustc)" -W help 2>/dev/null | grep -E '^ +rust-2018-idioms ' | sed 's/^ *//'
write_root ''
printf '%s\n' 'pub fn f(_: Box<Fn()>) {}' > src/lib.rs
run "L4a bare_trait_objects: a bare trait object is a hard error in edition 2024 with no table entry" 101 cargo check -p facade --locked
printf '%s\n' 'pub fn g(x: u8) -> bool { match x { 0...9 => true, _ => false } }' > src/lib.rs
run "L4b ellipsis_inclusive_range_patterns: \`...\` is a hard error in edition 2024 with no table entry" 101 cargo check -p facade --locked

echo
echo "# summary: failures=$fails"
exit "$fails"
