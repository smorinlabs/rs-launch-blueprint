#!/usr/bin/env bash
# R35 revision 1 — install check for cargo-llvm-cov 0.9.1.
# Builds the pinned tool from crates.io with the template's MSRV-floor toolchain
# (1.96) into the private CARGO_HOME, so a pass is an executed proof that the
# tool's install MSRV sits within msrv-policy's floor. Reads the packaged
# Cargo.toml and README.md of the exact crate that was built, and copies the
# README into snapshots/ so later scripts cite it offline.
# Usage: bash r35-install.sh   (from any directory; CARGO_HOME must be set)
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots"
mkdir -p "$snap"
: "${CARGO_HOME:?CARGO_HOME must point at the private cargo home}"
export PATH="$HOME/.cargo/bin:$CARGO_HOME/bin:$PATH"
unset CARGO_TARGET_DIR
build_target="$(mktemp -d)"
trap 'rm -rf "$build_target"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }

info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ) host=$(uname -srm)"
info "CARGO_HOME=$CARGO_HOME cargo=$(command -v cargo) rustup=$(command -v rustup)"

floor_rustc="$(rustc +1.96 --version)"
info "floor toolchain: $floor_rustc"
case "$floor_rustc" in
  "rustc 1.96."*) ok I0 "floor toolchain is a 1.96.x release (stable 1.98 minus 2 minor versions)";;
  *) bad I0 "floor toolchain is not 1.96.x: $floor_rustc";;
esac

start=$(date +%s)
if cargo +1.96 install cargo-llvm-cov --version 0.9.1 --locked --force \
     --target-dir "$build_target" >"$build_target/install.log" 2>&1; then
  ok I1 "cargo +1.96 install cargo-llvm-cov --version 0.9.1 --locked succeeded in $(( $(date +%s) - start ))s"
else
  tail -20 "$build_target/install.log"
  bad I1 "install failed on the 1.96 floor"
fi
grep -E '^ *(Installing|Installed|Replaced|Finished)' "$build_target/install.log" | sed 's/^ */INFO install: /' || true

bin="$CARGO_HOME/bin/cargo-llvm-cov"
if [ -x "$bin" ]; then
  ok I2 "binary present at \$CARGO_HOME/bin/cargo-llvm-cov"
else
  bad I2 "binary missing at $bin"
fi
ver="$("$bin" llvm-cov --version 2>&1 || true)"
info "version output: $ver"
check I3 "reports 'cargo-llvm-cov 0.9.1' (observed: $ver)" test "$ver" = "cargo-llvm-cov 0.9.1"

src="$(find "$CARGO_HOME/registry/src" -maxdepth 2 -type d -name 'cargo-llvm-cov-0.9.1' | head -n 1)"
if [ -n "$src" ]; then
  ok I4 "packaged source extracted at registry/src/*/cargo-llvm-cov-0.9.1"
  cp "$src/README.md" "$snap/cargo-llvm-cov-0.9.1-README.md"
  cp "$src/Cargo.toml" "$snap/cargo-llvm-cov-0.9.1-Cargo.toml"
  info "snapshot sha256 README: $(shasum -a 256 "$snap/cargo-llvm-cov-0.9.1-README.md" | cut -d' ' -f1)"
  rv="$(/usr/bin/grep -E '^rust-version = ' "$src/Cargo.toml" || true)"
  check I5 "packaged Cargo.toml declares rust-version 1.87, within floor 1.96 (observed: $rv)" test "$rv" = 'rust-version = "1.87"'
  lic="$(/usr/bin/grep -E '^license = ' "$src/Cargo.toml" || true)"
  check I6 "packaged licence is Apache-2.0 OR MIT (observed: $lic)" test "$lic" = 'license = "Apache-2.0 OR MIT"'
  if /usr/bin/grep -q '^#!\[forbid(unsafe_code)\]' "$src/src/main.rs"; then
    ok I7 "src/main.rs carries #![forbid(unsafe_code)] at line $(/usr/bin/grep -n '^#!\[forbid(unsafe_code)\]' "$src/src/main.rs" | cut -d: -f1)"
  else
    bad I7 "no #![forbid(unsafe_code)] in src/main.rs"
  fi
else
  bad I4 "no extracted source for cargo-llvm-cov-0.9.1 under $CARGO_HOME/registry/src"
fi

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
