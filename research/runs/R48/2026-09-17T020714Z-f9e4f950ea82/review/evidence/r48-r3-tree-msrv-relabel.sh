#!/usr/bin/env bash
# R48 mocking-crates — revision 3, corrected attribution of the two MSRV-floor
# compiles (JF-9). Prose-only revision otherwise; this script gathers no new
# evidence and changes no outcome.
#
# Why it exists. Revision 2's spike script labelled its first check, D01, as
# showing that "mockall's and httpmock's resolved dependency trees compile at the
# msrv-policy floor". D01 runs `cargo test` with the `mock` feature OFF, and
# `mockall` is an optional dependency behind that feature, so `mockall` is not in
# that build graph at all — which revision 2's own D05 proves from the other side
# ("cargo tree -i mockall … did not match any packages"). The underlying claim is
# true and the evidence is in the committed logs; only the attribution was wrong:
#
#     httpmock's resolved tree compiles at the floor  -> D01 (feature off), G01 here
#     mockall's  resolved tree compiles at the floor  -> D02 (feature on),  G02 here
#
# The revision-2 script `r48-r2-msrv-macos-spike.sh` and its log are committed
# artifacts that the round-2 audit read line by line, so neither is edited. This
# script re-runs the same two commands on the same probe crate and writes the
# corrected labels into its own log, `r48-r3-tree-msrv-relabel.log`. Where the two
# logs disagree in wording, THIS one is correct and the revision note says so.
#
# Scope. Same as the revision-2 spike and no wider: a throwaway probe crate in a
# temporary directory OUTSIDE the repository, deleted when the script exits. It is
# not the template, not a seam and not a scaffold. It starts no `httpmock` server.
#
# Determinism contract
# --------------------
#   * Every line beginning "# " is volatile (timestamp, host and toolchain
#     banners, and the appendix carrying cargo's raw output: cargo prints compile
#     order, wall-clock times and hashed artifact paths).
#   * Every PASS / FAIL / SKIP line and the RESULT line asserts a stable fact and
#     reproduces byte-for-byte:
#         bash r48-r3-tree-msrv-relabel.sh > new.log
#         diff <(grep -v '^# ' new.log) <(grep -v '^# ' r48-r3-tree-msrv-relabel.log)
#     must be empty.
#   * Both checks SKIP by name when the 1.96.0 toolchain is absent, so the script
#     is runnable from a clean `git archive HEAD` extraction on a machine without
#     rustup.
#
# Usage: bash r48-r3-tree-msrv-relabel.sh    (runnable from any working directory)

set -uo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# evidence -> review -> <run> -> R48 -> runs -> research -> repository root
REPO=$(CDPATH='' cd -- "$SCRIPT_DIR/../../../../../.." && pwd)
MSRV=1.96.0
RUSTUP_CARGO="$HOME/.cargo/bin/cargo"
GREP=/usr/bin/grep

FAILED=0
pass() { printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; FAILED=$((FAILED + 1)); }
skip() { printf 'SKIP %s: %s\n' "$1" "$2"; }
note() { sed 's/^/# /'; }

SPIKE=$(mktemp -d "${TMPDIR:-/private/tmp}/r48-r3-relabel-XXXXXX")
trap 'rm -rf "$SPIKE"' EXIT

printf '# R48 mocking-crates — revision 3 attribution correction for the MSRV-floor compiles (JF-9)\n'
printf '# retrieved: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '# host: %s; macOS product version %s\n' "$(uname -sm)" "$(sw_vers -productVersion 2> /dev/null || echo 'n/a')"
printf '# msrv cargo: %s\n' "$("$RUSTUP_CARGO" "+$MSRV" --version 2>&1 | head -n 1)"
printf '# probe directory (temporary, deleted on exit): %s\n' "$SPIKE"
printf '# This log supersedes the WORDING of the D01 PASS line in r48-r2-msrv-macos-spike.log,\n'
printf '# which credited D01 with compiling both members trees. That log is a committed\n'
printf '# artifact and is not edited; its D02 and D05 lines were correct as written.\n'
printf '#\n'

mkdir -p "$SPIKE/src" "$SPIKE/tests"

cat > "$SPIKE/Cargo.toml" << 'TOML'
[package]
name = "r48-mockall-probe"
version = "0.0.0"
edition = "2024"
rust-version = "1.96.0"
publish = false

[dependencies]
mockall = { version = "=0.15.0", optional = true }

[dev-dependencies]
httpmock = { version = "=0.8.3", default-features = false }

[features]
mock = ["dep:mockall"]

[lib]
path = "src/lib.rs"
TOML

cat > "$SPIKE/src/lib.rs" << 'RS'
use std::sync::Arc;

#[cfg_attr(feature = "mock", mockall::automock)]
pub trait ProbePort: Send + Sync {
    fn ping(&self, n: u32) -> Result<String, String>;
}

pub fn call_through(port: &Arc<dyn ProbePort>, n: u32) -> Result<String, String> {
    port.ping(n)
}
RS

cat > "$SPIKE/tests/probe.rs" << 'RS'
#![cfg(feature = "mock")]
use mockall::predicate::eq;
use r48_mockall_probe::{MockProbePort, ProbePort, call_through};
use std::sync::Arc;

#[test]
fn generated_mock_is_send_sync_and_dyn_erasable() {
    let mut m = MockProbePort::new();
    m.expect_ping()
        .with(eq(7u32))
        .times(1)
        .returning(|n| Ok(format!("pong-{n}")));
    let erased: Arc<dyn ProbePort> = Arc::new(m);
    assert_eq!(call_through(&erased, 7).unwrap(), "pong-7");
}
RS

cat > "$SPIKE/tests/httpmock_pin.rs" << 'RS'
#[test]
fn httpmock_pin_links_and_its_types_are_nameable() {
    let n = std::any::type_name::<httpmock::MockServer>();
    assert!(n.contains("MockServer"), "unexpected type name: {n}");
    let t = std::any::type_name::<httpmock::Then>();
    assert!(t.contains("Then"), "unexpected type name: {t}");
}
RS

case "$SPIKE" in
  "$REPO"*) fail G00 "probe directory is inside the repository tree" ;;
  *) pass G00 "probe crate is built in a temporary directory outside the repository and removed when this script exits; no template, seam or scaffold is created inside the repository" ;;
esac

have_msrv=0
if [ -x "$RUSTUP_CARGO" ] && "$RUSTUP_CARGO" "+$MSRV" --version > /dev/null 2>&1; then
  have_msrv=1
fi

# ---------------------------------------------------------------------------
# G01 — what the feature-OFF run actually establishes: httpmock's resolved tree,
# and NOT mockall's, which is not in that build graph at all.
# ---------------------------------------------------------------------------
if [ "$have_msrv" = "1" ]; then
  rm -f "$SPIKE/Cargo.lock"
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" test) > "$SPIKE/off.txt" 2>&1
  g01_exit=$?
  n_pass=$("$GREP" -c '^test result: ok\. 1 passed' "$SPIKE/off.txt")
  n_http=$("$GREP" -c '^   Compiling httpmock v0\.8\.3$' "$SPIKE/off.txt")
  n_mock=$("$GREP" -c '^   Compiling mockall v' "$SPIKE/off.txt")
  n_derive=$("$GREP" -c '^   Compiling mockall_derive v' "$SPIKE/off.txt")
  if [ "$g01_exit" = "0" ] && [ "$n_pass" = "1" ] && [ "$n_http" = "1" ] && [ "$n_mock" = "0" ] && [ "$n_derive" = "0" ]; then
    pass G01 "cargo +$MSRV test (feature off) exit 0, 1 'test result: ok. 1 passed' line, 1 'Compiling httpmock v0.8.3' line, 0 'Compiling mockall v' lines and 0 'Compiling mockall_derive v' lines (counts by $GREP -c) — this run establishes that HTTPMOCK's resolved dependency tree compiles at the msrv-policy floor, and establishes NOTHING about mockall's, which is behind an off-by-default feature and absent from this build graph"
  else
    fail G01 "cargo +$MSRV test (feature off) exit $g01_exit, ok-1-passed $n_pass, httpmock-compiling $n_http, mockall-compiling $n_mock, mockall_derive-compiling $n_derive (counts by $GREP -c); expected 0, 1, 1, 0, 0"
  fi
else
  skip G01 "rustup cargo or the $MSRV toolchain is absent; the feature-off build was not run"
fi

# ---------------------------------------------------------------------------
# G02 — the run that does establish mockall's tree: feature ON.
# ---------------------------------------------------------------------------
if [ "$have_msrv" = "1" ]; then
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" test --features mock) > "$SPIKE/on.txt" 2>&1
  g02_exit=$?
  n_pass=$("$GREP" -c '^test result: ok\. 1 passed' "$SPIKE/on.txt")
  n_mock=$("$GREP" -c '^   Compiling mockall v0\.15\.0$' "$SPIKE/on.txt")
  n_derive=$("$GREP" -c '^   Compiling mockall_derive v0\.15\.0$' "$SPIKE/on.txt")
  n_named=$("$GREP" -c '^test generated_mock_is_send_sync_and_dyn_erasable \.\.\. ok$' "$SPIKE/on.txt")
  if [ "$g02_exit" = "0" ] && [ "$n_pass" = "2" ] && [ "$n_mock" = "1" ] && [ "$n_derive" = "1" ] && [ "$n_named" = "1" ]; then
    pass G02 "cargo +$MSRV test --features mock exit 0, 2 'test result: ok. 1 passed' lines, 1 'Compiling mockall v0.15.0' line, 1 'Compiling mockall_derive v0.15.0' line and 1 'test generated_mock_is_send_sync_and_dyn_erasable ... ok' line (counts by $GREP -c) — THIS is the run that establishes mockall 0.15.0's resolved dependency tree compiles at the msrv-policy floor, and that the generated mock is Send + Sync and erases to Arc<dyn ProbePort>"
  else
    fail G02 "cargo +$MSRV test --features mock exit $g02_exit, ok-1-passed $n_pass, mockall-compiling $n_mock, mockall_derive-compiling $n_derive, named-test $n_named (counts by $GREP -c); expected 0, 2, 1, 1, 1"
  fi
else
  skip G02 "rustup cargo or the $MSRV toolchain is absent; the feature-on build was not run"
fi

# ---------------------------------------------------------------------------
# G03 — the lint guarantee, extended to the script revision 3 adds. Check E05 in
# the revision-2 log covers the three scripts that existed then and is frozen at
# that number; this covers all four.
# ---------------------------------------------------------------------------
if command -v shellcheck > /dev/null 2>&1; then
  sc_out="$SPIKE/shellcheck.txt"
  : > "$sc_out"
  sc_fail=0
  sc_n=0
  for s in r48-claims-check.sh r48-r2-msrv-macos-spike.sh r48-r2-citations-check.sh r48-r3-tree-msrv-relabel.sh; do
    if [ -f "$SCRIPT_DIR/$s" ]; then
      sc_n=$((sc_n + 1))
      shellcheck "$SCRIPT_DIR/$s" >> "$sc_out" 2>&1 || sc_fail=$((sc_fail + 1))
    fi
  done
  lines=$(wc -l < "$sc_out" | tr -d ' ')
  if [ "$sc_n" = "4" ] && [ "$sc_fail" = "0" ] && [ "$lines" = "0" ]; then
    pass G03 "shellcheck reports no findings and exits 0 for all 4 evidence scripts in this run (r48-claims-check.sh, r48-r2-msrv-macos-spike.sh, r48-r2-citations-check.sh, r48-r3-tree-msrv-relabel.sh); its output was 0 lines long"
  else
    fail G03 "shellcheck: scripts found $sc_n (expected 4), non-zero exits $sc_fail (expected 0), output lines $lines (expected 0)"
  fi
else
  skip G03 "shellcheck is not on PATH; the evidence scripts were not linted here"
fi

printf '#\n'
printf '# ---- appendix, volatile: cargo output for the two runs ----\n'
for f in off on; do
  if [ -f "$SPIKE/$f.txt" ]; then
    printf '# ===== %s.txt =====\n' "$f"
    note < "$SPIKE/$f.txt"
  fi
done
printf '#\n'
if [ "$FAILED" = "0" ]; then
  printf 'RESULT: all checks passed (0 FAIL)\n'
else
  printf 'RESULT: %s check(s) FAILED\n' "$FAILED"
fi
exit "$FAILED"
