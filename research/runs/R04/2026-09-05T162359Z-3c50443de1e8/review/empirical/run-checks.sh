#!/usr/bin/env bash
# R04 public-api-surface-enforcement — empirical check.
#
# Usage: bash run-checks.sh
#   TOOLCHAIN=1.96.0   run every cargo command as `cargo +1.96.0` (MSRV leg)
#   RUN_TOOLS=0        skip the cargo-semver-checks and `cargo publish --dry-run` cases
#   SEMVER_BIN=<path>  cargo-semver-checks binary
#                      (default: .tools/<macos|linux>/cargo-semver-checks, else PATH)
#   WORK_DIR=<path>    scratch directory for generated variants (default: ./.work)
#
# Exit status: 0 when every case passed, 1 otherwise. Per-case output is echoed
# inline and also kept under $WORK_DIR/logs/<case>.log.
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TOOLCHAIN="${TOOLCHAIN:-}"
RUN_TOOLS="${RUN_TOOLS:-1}"
WORK_DIR="${WORK_DIR:-$HERE/.work}"
case "$(uname -s)" in
  Darwin) DEFAULT_SEMVER="$HERE/.tools/macos/cargo-semver-checks" ;;
  Linux)  DEFAULT_SEMVER="$HERE/.tools/linux/cargo-semver-checks" ;;
  *)      DEFAULT_SEMVER="cargo-semver-checks" ;;
esac
SEMVER_BIN="${SEMVER_BIN:-$DEFAULT_SEMVER}"
LOG_DIR="$WORK_DIR/logs"
PASS=0
FAIL=0

cargo_() { if [ -n "$TOOLCHAIN" ]; then cargo "+$TOOLCHAIN" "$@"; else cargo "$@"; fi; }
rustc_() { if [ -n "$TOOLCHAIN" ]; then rustc "+$TOOLCHAIN" "$@"; else rustc "$@"; fi; }

# run_case <id> <expect: 0|nonzero> <must-contain> <must-not-contain> <dir> <cmd...>
# Fixed-string matches; an empty pattern means "no constraint".
run_case() {
  local id="$1" expect="$2" must="$3" mustnot="$4" dir="$5"
  shift 5
  local log="$LOG_DIR/$id.log"
  echo
  echo "--- case $id: (cd ${dir#"$HERE"/} && $*)"
  echo "    expect: exit $expect${must:+; output contains \"$must\"}${mustnot:+; output lacks \"$mustnot\"}"
  ( cd "$dir" && "$@" ) >"$log" 2>&1
  local rc=$?
  sed 's/^/    | /' "$log"
  local ok=1
  if [ "$expect" = 0 ] && [ "$rc" -ne 0 ]; then ok=0; fi
  if [ "$expect" = nonzero ] && [ "$rc" -eq 0 ]; then ok=0; fi
  if [ -n "$must" ] && ! grep -qF -- "$must" "$log"; then ok=0; fi
  if [ -n "$mustnot" ] && grep -qF -- "$mustnot" "$log"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    PASS=$((PASS + 1)); echo "RESULT $id: PASS (exit $rc)"
  else
    FAIL=$((FAIL + 1)); echo "RESULT $id: FAIL (exit $rc)"
  fi
}

# variant <name>: fresh copy of surface_demo (sources only) under $WORK_DIR/<name>
variant() {
  local dst="$WORK_DIR/$1"
  rm -rf "$dst"
  mkdir -p "$dst/src"
  cp "$HERE/surface_demo/Cargo.toml" "$dst/Cargo.toml"
  cp "$HERE/surface_demo/src/lib.rs" "$HERE/surface_demo/src/internal.rs" "$dst/src/"
}

# consumer <name> <lib-dir> <main.rs body>: a binary crate depending on <lib-dir> by path
consumer() {
  local dst="$WORK_DIR/$1" lib="$2" body="$3"
  rm -rf "$dst"
  mkdir -p "$dst/src"
  cat >"$dst/Cargo.toml" <<EOF
[package]
name = "$1"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
publish = false

[dependencies]
surface_demo = { path = "$lib" }

[workspace]
EOF
  printf '%s\n' "$body" >"$dst/src/main.rs"
}

rm -rf "$WORK_DIR"
mkdir -p "$LOG_DIR"

echo "== R04 empirical check: public API surface enforcement =="
echo "date: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "os: $(uname -a)"
echo "toolchain argument: ${TOOLCHAIN:-<default>}"
echo "rustc: $(rustc_ --version)"
echo "cargo: $(cargo_ --version)"
echo "rustup toolchains:"; rustup toolchain list | sed 's/^/    /'
echo "fixture: $HERE"
echo "work dir: $WORK_DIR"
if [ "$RUN_TOOLS" = 1 ]; then
  echo "cargo-semver-checks: $SEMVER_BIN -> $("$SEMVER_BIN" --version 2>&1)"
else
  echo "cargo-semver-checks: skipped (RUN_TOOLS=0)"
fi

# 01 — the reference crate builds and its doctests run: two compile_fail,E0603 deep imports and one passing root import.
run_case 01-doctests 0 "test result: ok" "FAILED" "$HERE/surface_demo" cargo_ test

# 02 — an external consumer using the root path compiles and runs.
run_case 02-consumer-ok 0 "consumer_ok: root-path import works, id=7" "" "$HERE/consumer_ok" cargo_ run --quiet

# 03 — an external consumer naming the private module is refused (the ts `exports`-map analogue, at compile time).
run_case 03-deep-import-refused nonzero "error[E0603]" "" "$HERE/deep_import" cargo_ check --quiet

# 04 — an unreachable `pub` item in a private module is a build error under deny(unreachable_pub).
variant leaked
printf '\n/// Never re-exported: must fail under deny(unreachable_pub).\npub struct Leaked;\n' >>"$WORK_DIR/leaked/src/internal.rs"
run_case 04-unreachable-pub-denied nonzero 'unreachable `pub` item' "" "$WORK_DIR/leaked" cargo_ check --quiet

# 05 — discriminating check: same leak with the deny attribute removed. Observes the lint's default level.
#      PASS = the build succeeds with no `unreachable` diagnostic (allow-by-default, so the template must opt in).
variant no_lint
printf '\n/// Never re-exported; no lint attribute is present.\npub struct Leaked;\n' >>"$WORK_DIR/no_lint/src/internal.rs"
grep -v 'deny(unreachable_pub)' "$WORK_DIR/no_lint/src/lib.rs" >"$WORK_DIR/no_lint/src/lib.rs.tmp"
mv "$WORK_DIR/no_lint/src/lib.rs.tmp" "$WORK_DIR/no_lint/src/lib.rs"
run_case 05-unreachable-pub-default-level 0 "" "unreachable" "$WORK_DIR/no_lint" cargo_ check

# 06 — a pub(crate) type in a public signature is a build error under deny(private_interfaces).
variant private_in_public
cat >>"$WORK_DIR/private_in_public/src/internal.rs" <<'EOF'

impl Widget {
    /// Exposes a crate-private type: must fail under deny(private_interfaces).
    pub fn engine(&self) -> Engine {
        Engine
    }
}
EOF
run_case 06-private-interface-denied nonzero "more private than" "" "$WORK_DIR/private_in_public" cargo_ check --quiet

# 07 — a pub(crate) item cannot be widened by a root `pub use`.
variant widen
printf '\n/// Attempt to widen a pub(crate) item: must fail.\npub use internal::Engine;\n' >>"$WORK_DIR/widen/src/lib.rs"
run_case 07-pub-crate-cannot-widen nonzero "cannot be re-exported" "" "$WORK_DIR/widen" cargo_ check --quiet

# 08 — the two documented escape hatches really bypass the surface: #[doc(hidden)] and #[macro_export].
variant escape
cat >>"$WORK_DIR/escape/src/internal.rs" <<'EOF'

/// Hidden from rustdoc but reachable: the Rust analogue of py's `__all__` hole.
#[doc(hidden)]
pub fn escape_hatch() -> u32 {
    SECRET
}

/// Exported at the crate root regardless of module privacy.
#[macro_export]
macro_rules! shout {
    () => {
        "escaped"
    };
}
EOF
printf '\n#[doc(hidden)]\npub use internal::escape_hatch;\n' >>"$WORK_DIR/escape/src/lib.rs"
consumer escape_consumer "$WORK_DIR/escape" 'fn main() {
    println!("{} {}", surface_demo::shout!(), surface_demo::escape_hatch());
}'
run_case 08-escape-hatches-reachable 0 "escaped 42" "" "$WORK_DIR/escape_consumer" cargo_ run --quiet

if [ "$RUN_TOOLS" = 1 ]; then
  # 09 — cargo-semver-checks on the active (stable) toolchain catches a removed public method.
  variant semver_baseline
  variant semver_removed
  cat >"$WORK_DIR/semver_removed/src/internal.rs" <<'EOF'
//! Variant: `Widget::id` removed.

pub(crate) const SECRET: u32 = 42;

/// Crate-internal helper type; never exported.
pub(crate) struct Engine;

/// A widget identified by a number.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct Widget {
    #[allow(dead_code)]
    id: u32,
}

impl Widget {
    /// Creates a widget with the given id.
    pub fn new(id: u32) -> Self {
        let _ = Engine;
        let _ = SECRET;
        Self { id }
    }
}
EOF
  run_case 09-semver-removal-fails nonzero "inherent_method_missing" "" "$WORK_DIR" \
    "$SEMVER_BIN" semver-checks --manifest-path "$WORK_DIR/semver_removed/Cargo.toml" --baseline-root "$WORK_DIR/semver_baseline"

  # 10 — the same gate does not flag an added public method (the accepted addition gap).
  variant semver_added
  cat >>"$WORK_DIR/semver_added/src/internal.rs" <<'EOF'

impl Widget {
    /// A new public method that touches neither lib.rs nor any semver rule.
    pub fn undocumented_addition(&self) -> u32 {
        0
    }
}
EOF
  run_case 10-semver-addition-passes 0 "no semver update required" "" "$WORK_DIR" \
    "$SEMVER_BIN" semver-checks --manifest-path "$WORK_DIR/semver_added/Cargo.toml" --baseline-root "$WORK_DIR/semver_baseline"

  # 11 — a published crate cannot depend on a `publish = false` workspace member.
  run_case 11-publish-false-under-published nonzero "no matching package" "" "$HERE/publish_demo" \
    cargo_ publish --dry-run -p rs_publish_demo_public --allow-dirty
fi

echo
echo "summary: PASS=$PASS FAIL=$FAIL"
if [ "$FAIL" -eq 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
