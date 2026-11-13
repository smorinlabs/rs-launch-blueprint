#!/usr/bin/env bash
# R35 revision 1 — how cargo-llvm-cov finds the LLVM tools.
#   T1: rustup toolchain WITH llvm-tools-preview -> works (positive control).
#   T2: rustup toolchain WITHOUT the component and CARGO_LLVM_COV_SETUP=no ->
#       fails, which is why the CI job must add the component explicitly.
#   T3: Homebrew cargo first on PATH (a non-rustup toolchain) -> fails with the
#       message the Opus leg quotes from src/context.rs (raw/opus.md:167).
#   T4: R42's presence test for a rustup component reads rustup's component list.
# Usage: bash r35-toolchain.sh   (CARGO_HOME must hold cargo-llvm-cov 0.9.1)
set -euo pipefail

: "${CARGO_HOME:?CARGO_HOME must point at the private cargo home}"
unset CARGO_TARGET_DIR RUSTFLAGS LLVM_COV LLVM_PROFDATA RUSTUP_TOOLCHAIN
export CARGO_LLVM_COV_SETUP=no CARGO_TERM_COLOR=never
rustup_path="$HOME/.cargo/bin:$CARGO_HOME/bin:$PATH"
brew_path="/opt/homebrew/bin:$CARGO_HOME/bin:$PATH"
fx="$(mktemp -d)"
trap 'rm -rf "$fx"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }
run_in() { # run_in <PATH> <toolchain or ""> <log> -- cmd...
  local p="$1" tc="$2" log="$3"; shift 3
  if [ -n "$tc" ]; then env PATH="$p" RUSTUP_TOOLCHAIN="$tc" "$@" >"$log" 2>&1; else env PATH="$p" "$@" >"$log" 2>&1; fi
}

mkdir -p "$fx/src"
printf '[package]\nname = "tcfx"\nversion = "0.1.0"\nedition = "2024"\npublish = false\n' >"$fx/Cargo.toml"
printf 'pub fn one() -> u8 { 1 }\n#[test]\nfn t() { assert_eq!(one(), 1); }\n' >"$fx/src/lib.rs"
cd "$fx"
env PATH="$rustup_path" RUSTUP_TOOLCHAIN=1.93.0 cargo generate-lockfile >/dev/null 2>&1
info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
info "rustup cargo: $(env PATH="$rustup_path" command -v cargo); Homebrew cargo: $(env PATH="$brew_path" command -v cargo) ($(/opt/homebrew/bin/cargo --version))"

# T1 — positive control
if run_in "$rustup_path" 1.93.0 "$fx/../t1.log" cargo llvm-cov --locked --summary-only; then
  ok T1 "rustup 1.93.0 with llvm-tools-preview: cargo llvm-cov succeeds"
else
  bad T1 "positive control failed"; tail -10 "$fx/../t1.log"
fi

# T2 — rustup toolchain without the component
comps="$(env PATH="$rustup_path" rustup component list --installed --toolchain 1.96 | tr '\n' ' ')"
info "1.96 installed components: $comps"
if run_in "$rustup_path" 1.96 "$fx/../t2.log" cargo llvm-cov --locked --summary-only; then
  bad T2 "1.96 without llvm-tools-preview unexpectedly succeeded"
else
  ok T2 "rustup 1.96 without llvm-tools-preview and CARGO_LLVM_COV_SETUP=no: cargo llvm-cov fails"
fi
/usr/bin/grep -m2 -i 'llvm-tools\|error' "$fx/../t2.log" | sed 's/^/INFO t2: /'
check T2b "the T2 error names llvm-tools-preview" /usr/bin/grep -q 'llvm-tools-preview' "$fx/../t2.log"

# T3 — Homebrew cargo first on PATH
if run_in "$brew_path" "" "$fx/../t3.log" cargo llvm-cov --locked --summary-only; then
  bad T3 "Homebrew cargo unexpectedly succeeded"
else
  ok T3 "Homebrew cargo first on PATH: cargo llvm-cov fails"
fi
/usr/bin/grep -m2 -i 'llvm-tools\|error' "$fx/../t3.log" | sed 's/^/INFO t3: /'
check T3b "the T3 error is the non-rustup message (install llvm-tools-preview or set LLVM_COV and LLVM_PROFDATA)" \
  /usr/bin/grep -q 'LLVM_COV and LLVM_PROFDATA' "$fx/../t3.log"

# T4 — R42's presence rule for a rustup component
check T4a "rustup component list --installed shows llvm-tools on 1.93.0" \
  bash -c "env PATH='$rustup_path' rustup component list --installed --toolchain 1.93.0 | /usr/bin/grep -q '^llvm-tools'"
check T4b "and does not on 1.96 (the component is per toolchain)" \
  bash -c "! env PATH='$rustup_path' rustup component list --installed --toolchain 1.96 | /usr/bin/grep -q '^llvm-tools'"

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
