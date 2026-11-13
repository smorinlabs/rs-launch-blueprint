#!/usr/bin/env bash
# R48 mocking-crates — revision 2, throwaway compile spike (JF-2, JF-4).
#
# Purpose. Revision 1 recorded `mockall` 0.15.0's gate 4 (`target-os-matrix` =
# ubuntu-latest, macos-latest) as a pass inferred from an adopter carrying
# 0.13.0, and recorded no candidate's dependency-TREE MSRV at all. This spike
# replaces both inferences with observation on this macOS host:
#
#   * the two SELECTED crate members install and compile on macOS, and
#   * their whole resolved dependency trees compile and their tests pass at the
#     `msrv-policy` floor of 1.96.0, which is the dependency-tree half of gate 2.
#
# Scope, stated so this is not read as more than it is. This is a THROWAWAY
# probe crate built in a temporary directory OUTSIDE the repository and deleted
# when the script exits. It is not the template, not a seam, and not a scaffold:
# the synthesizer role permits confirming "a version pin exists and installs",
# and R01 closed the identical macOS gap for `serde` the same way. The probe
# trait is deliberately named `ProbePort`, NOT R01's `ProjectsPort` — what is
# proven here is that the mock generated for a `Send + Sync` trait erases to
# `Arc<dyn Trait>`, a property of the mechanism. Confirming it against R01's
# actual trait remains P03's. `httpmock` is linked and its types named; no
# `MockServer` is started, because starting one would be exercising the
# recommendation rather than confirming the pin.
#
# Determinism contract
# --------------------
#   * Every line beginning "# " is volatile: the retrieval timestamp, the host
#     and toolchain banners, and the appendix carrying cargo's raw output and
#     the resolved lockfile (cargo prints compile order, wall-clock times and
#     hashed artifact paths, and an MSRV-aware resolve may pick different
#     transitive PATCH versions on a later day).
#   * Every PASS / FAIL / SKIP line and the RESULT line asserts a stable fact
#     and reproduces byte-for-byte:
#         bash r48-r2-msrv-macos-spike.sh > new.log
#         diff <(grep -v '^# ' new.log) <(grep -v '^# ' r48-r2-msrv-macos-spike.log)
#     must be empty.
#   * Every check SKIPs by name when its toolchain is absent, so the script is
#     runnable from a clean `git archive HEAD` extraction on a machine without
#     rustup, without the 1.96.0 toolchain, or without the Homebrew toolchain.
#
# Usage: bash r48-r2-msrv-macos-spike.sh    (runnable from any working directory)

set -uo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
# evidence -> review -> <run> -> R48 -> runs -> research -> repository root
REPO=$(CDPATH='' cd -- "$SCRIPT_DIR/../../../../../.." && pwd)
MSRV=1.96.0
RUSTUP_CARGO="$HOME/.cargo/bin/cargo"
STABLE_CARGO=/opt/homebrew/bin/cargo
GREP=/usr/bin/grep

FAILED=0
pass() { printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; FAILED=$((FAILED + 1)); }
skip() { printf 'SKIP %s: %s\n' "$1" "$2"; }
note() { sed 's/^/# /'; }

SPIKE=$(mktemp -d /private/tmp/r48-r2-spike-XXXXXX)
trap 'rm -rf "$SPIKE"' EXIT

printf '# R48 mocking-crates — revision 2 compile spike (JF-2, JF-4)\n'
printf '# retrieved: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '# host: %s; macOS product version %s\n' "$(uname -sm)" "$(sw_vers -productVersion 2> /dev/null || echo 'n/a')"
printf '# msrv cargo: %s\n' "$("$RUSTUP_CARGO" "+$MSRV" --version 2>&1 | head -n 1)"
printf '# stable cargo: %s\n' "$("$STABLE_CARGO" --version 2>&1 | head -n 1)"
printf '# stable rustc: %s\n' "$(rustc --version 2>&1 | head -n 1)"
printf '# probe directory (temporary, deleted on exit): %s\n' "$SPIKE"
printf '#\n'

# ---------------------------------------------------------------------------
# The probe crate. Edition 2024 and rust-version 1.96.0 mirror the owner-fixed
# `rust-edition` and the floor implied by `msrv-policy`, so compiling it also
# shows an edition-2024 package consuming the edition-2021 `mockall` 0.15.0 and
# the edition-2021 `httpmock` 0.8.3.
# ---------------------------------------------------------------------------
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

# ---------------------------------------------------------------------------
# D00 — the probe is built outside the repository, as the role requires.
# ---------------------------------------------------------------------------
case "$SPIKE" in
  "$REPO"*) fail D00 "probe directory is inside the repository tree" ;;
  *) pass D00 "probe crate is built in a temporary directory outside the repository and removed when this script exits; no template, seam or scaffold is created inside the repository" ;;
esac

have_msrv=0
if [ -x "$RUSTUP_CARGO" ] && "$RUSTUP_CARGO" "+$MSRV" --version > /dev/null 2>&1; then
  have_msrv=1
fi
have_stable=0
if [ -x "$STABLE_CARGO" ]; then
  have_stable=1
fi

# ---------------------------------------------------------------------------
# D01 — the whole resolved tree compiles and the base suite passes at the
# `msrv-policy` floor, with the `mock` feature OFF. One integration test runs
# (the httpmock pin); the mockall test is gated out.
# ---------------------------------------------------------------------------
if [ "$have_msrv" = "1" ]; then
  rm -f "$SPIKE/Cargo.lock"
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" test) > "$SPIKE/msrv-nofeature.txt" 2>&1
  d01_exit=$?
  n=$("$GREP" -c '^test result: ok\. 1 passed' "$SPIKE/msrv-nofeature.txt")
  if [ "$d01_exit" = "0" ] && [ "$n" = "1" ]; then
    pass D01 "cargo +$MSRV test (feature off) exit 0 with exactly 1 'test result: ok. 1 passed' line (count by $GREP -c) — mockall's and httpmock's resolved dependency trees compile at the msrv-policy floor of $MSRV on this macOS host, which is the dependency-tree half of gate 2, and the gated mockall test is correctly invisible without the feature"
  else
    fail D01 "cargo +$MSRV test (feature off) exit $d01_exit with $n 'test result: ok. 1 passed' lines (count by $GREP -c); expected exit 0 and 1"
  fi
else
  skip D01 "rustup cargo or the $MSRV toolchain is absent; the MSRV-floor build was not run"
fi

# ---------------------------------------------------------------------------
# D02 — the same tree with the `mock` feature ON: the proc macro expands, the
# generated mock satisfies the trait's Send + Sync supertraits, and it erases
# to Arc<dyn ProbePort>. The test compiling is itself that proof.
# ---------------------------------------------------------------------------
if [ "$have_msrv" = "1" ]; then
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" test --features mock) > "$SPIKE/msrv-feature.txt" 2>&1
  d02_exit=$?
  n=$("$GREP" -c '^test result: ok\. 1 passed' "$SPIKE/msrv-feature.txt")
  ok=$("$GREP" -c '^test generated_mock_is_send_sync_and_dyn_erasable \.\.\. ok$' "$SPIKE/msrv-feature.txt")
  if [ "$d02_exit" = "0" ] && [ "$n" = "2" ] && [ "$ok" = "1" ]; then
    pass D02 "cargo +$MSRV test --features mock exit 0 with 2 'test result: ok. 1 passed' lines and 1 'test generated_mock_is_send_sync_and_dyn_erasable ... ok' line (counts by $GREP -c) — at $MSRV on macOS the #[automock] macro expands, the generated mock is Send + Sync, and Arc::new(mock) as Arc<dyn ProbePort> compiles and returns the programmed value under a .with(eq(7)).times(1) expectation"
  else
    fail D02 "cargo +$MSRV test --features mock exit $d02_exit with $n ok-1-passed lines and $ok named-test lines (counts by $GREP -c); expected 0, 2 and 1"
  fi
else
  skip D02 "rustup cargo or the $MSRV toolchain is absent; the MSRV-floor feature build was not run"
fi

# ---------------------------------------------------------------------------
# D03 — the same lockfile at current stable. Gate 4's macOS half, observed.
# ---------------------------------------------------------------------------
if [ "$have_stable" = "1" ] && [ -f "$SPIKE/Cargo.lock" ]; then
  (cd "$SPIKE" && "$STABLE_CARGO" test --locked --features mock) > "$SPIKE/stable-feature.txt" 2>&1
  d03_exit=$?
  n=$("$GREP" -c '^test result: ok\. 1 passed' "$SPIKE/stable-feature.txt")
  if [ "$d03_exit" = "0" ] && [ "$n" = "2" ]; then
    pass D03 "cargo test --locked --features mock at current stable exit 0 with 2 'test result: ok. 1 passed' lines (count by $GREP -c) — mockall 0.15.0 and httpmock 0.8.3 build and their tests pass on macOS at stable as well as at the floor, against the one lockfile D01 resolved; gate 4's macOS half is observed rather than inferred from a 0.13.0 adopter"
  else
    fail D03 "stable cargo test --locked --features mock exit $d03_exit with $n ok-1-passed lines (count by $GREP -c); expected 0 and 2"
  fi
elif [ "$have_stable" = "1" ]; then
  skip D03 "no Cargo.lock was produced (D01 did not run); the stable build was not run"
else
  skip D03 "$STABLE_CARGO is absent; the stable build was not run"
fi

# ---------------------------------------------------------------------------
# D04 — the pins the decision recommends are the versions that resolved.
# ---------------------------------------------------------------------------
if [ -f "$SPIKE/Cargo.lock" ]; then
  pins=$(python3 - "$SPIKE/Cargo.lock" << 'PY'
import re, sys
with open(sys.argv[1]) as fh:
    text = fh.read()
out = []
for name in ("mockall", "mockall_derive", "httpmock"):
    m = re.search(r'name = "%s"\nversion = "([^"]+)"' % re.escape(name), text)
    out.append("%s %s" % (name, m.group(1) if m else "ABSENT"))
print("; ".join(out))
PY
  )
  if [ "$pins" = "mockall 0.15.0; mockall_derive 0.15.0; httpmock 0.8.3" ]; then
    pass D04 "the resolved Cargo.lock pins are exactly: $pins — the versions this decision recommends are the ones that built above"
  else
    fail D04 "resolved pins are '$pins'; expected 'mockall 0.15.0; mockall_derive 0.15.0; httpmock 0.8.3'"
  fi
else
  skip D04 "no Cargo.lock was produced; resolved pins were not read"
fi

# ---------------------------------------------------------------------------
# D05 — the gate is real: with the feature off, nothing in the build graph
# depends on mockall. cargo exits non-zero with a specific message.
# ---------------------------------------------------------------------------
if [ "$have_msrv" = "1" ] && [ -f "$SPIKE/Cargo.lock" ]; then
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" tree --edges normal,build -i mockall) > "$SPIKE/tree-off.txt" 2>&1
  off_exit=$?
  (cd "$SPIKE" && "$RUSTUP_CARGO" "+$MSRV" tree --features mock --edges normal,build -i mockall) > "$SPIKE/tree-on.txt" 2>&1
  on_exit=$?
  n_off=$("$GREP" -c 'package ID specification .mockall. did not match any packages' "$SPIKE/tree-off.txt")
  n_on=$("$GREP" -c '^mockall v0\.15\.0$' "$SPIKE/tree-on.txt")
  if [ "$off_exit" != "0" ] && [ "$n_off" = "1" ] && [ "$on_exit" = "0" ] && [ "$n_on" = "1" ]; then
    pass D05 "cargo tree -i mockall with the feature off exits non-zero with 1 'did not match any packages' line, and with the feature on exits 0 printing 1 'mockall v0.15.0' root (counts by $GREP -c) — the off-by-default gate keeps mockall out of the build graph, and the check can fail, because the two invocations differ"
  else
    fail D05 "cargo tree -i mockall: feature-off exit $off_exit with $n_off no-match lines, feature-on exit $on_exit with $n_on root lines (counts by $GREP -c); expected non-zero/1 and 0/1"
  fi
else
  skip D05 "rustup cargo, the $MSRV toolchain or the lockfile is absent; the dependency-graph probe was not run"
fi

printf '#\n'
printf '# ---- appendix, volatile: cargo output and the resolved lockfile ----\n'
for f in msrv-nofeature msrv-feature stable-feature tree-off tree-on; do
  if [ -f "$SPIKE/$f.txt" ]; then
    printf '# ===== %s.txt =====\n' "$f"
    note < "$SPIKE/$f.txt"
  fi
done
if [ -f "$SPIKE/Cargo.lock" ]; then
  printf '# ===== Cargo.lock: package count and every name/version pair =====\n'
  printf '# packages: %s (count by %s -c)\n' "$("$GREP" -c '^name = ' "$SPIKE/Cargo.lock")" "$GREP"
  python3 - "$SPIKE/Cargo.lock" << 'PY' | note
import re, sys
with open(sys.argv[1]) as fh:
    text = fh.read()
for name, version in re.findall(r'name = "([^"]+)"\nversion = "([^"]+)"', text):
    print("%s %s" % (name, version))
PY
fi
printf '#\n'
if [ "$FAILED" = "0" ]; then
  printf 'RESULT: all checks passed (0 FAIL)\n'
else
  printf 'RESULT: %s check(s) FAILED\n' "$FAILED"
fi
exit "$FAILED"
