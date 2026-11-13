#!/usr/bin/env bash
# R22 runtime-version-accessor -- throwaway rustc/cargo probes.
#
# Measures, rather than asserts, what env!("CARGO_PKG_VERSION") and option_env!
# actually do: where the value comes from, when it is bound, whether it survives
# the binary leaving its build tree, whether a Cargo feature can change it, and
# whether an accessor-equality test can fail.
#
# Every package is created with --vcs none, so no nested git repository is ever
# written. All work happens in a directory created under $TMPDIR and removed on
# exit. Nothing is written inside the repository.
set -euo pipefail

GREP=/usr/bin/grep
PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s -- %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s -- %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s -- %s\n' "$1" "$2"; }

# assert_eq <id> <expected> <actual> <what>
assert_eq() {
  if [ "$2" = "$3" ]; then
    pass "$1" "$4: got [$3]"
  else
    fail "$1" "$4: expected [$2] got [$3]"
  fi
}

# assert_ne <id> <not-expected> <actual> <what>
assert_ne() {
  if [ "$2" != "$3" ]; then
    pass "$1" "$4: [$3] differs from [$2] as required"
  else
    fail "$1" "$4: expected a difference, both are [$3]"
  fi
}

# assert_contains <id> <file> <fixed-string> <what>
assert_contains() {
  if $GREP -F -q -- "$3" "$2"; then
    pass "$1" "$4"
  else
    fail "$1" "$4: [$3] not found in $2"
  fi
}

echo "=== R22 cargo/rustc probe ==="
echo "run-started-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "uname: $(uname -sm)"
echo "rustc: $(rustc --version)"
echo "cargo: $(cargo --version)"
echo

SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/r22-probe.XXXXXX")"
cleanup() { rm -rf "$SCRATCH"; }
trap cleanup EXIT
echo "scratch: (a fresh mktemp -d under \$TMPDIR, removed on exit)"
echo

# ---------------------------------------------------------------------------
# Package A: one package, a library constant and a binary that prints it.
# ---------------------------------------------------------------------------
cd "$SCRATCH"
cargo new --quiet --vcs none --lib pkga
cd "$SCRATCH/pkga"
cat > src/lib.rs <<'RUST'
/// The package version from Cargo.toml, bound when this crate is compiled.
pub const VERSION: &str = env!("CARGO_PKG_VERSION");

/// Present only when the `web` feature is on; returns the same constant.
#[cfg(feature = "web")]
pub fn web_version() -> &'static str {
    VERSION
}
RUST
mkdir -p src/bin
cat > src/bin/show.rs <<'RUST'
fn main() {
    println!("{}", pkga::VERSION);
}
RUST
cat >> Cargo.toml <<'TOML'

[features]
web = []
TOML

# C1 -- the constant equals the manifest's [package] version field.
MANIFEST_VERSION="$($GREP -m1 '^version = ' Cargo.toml | sed 's/^version = "//; s/"$//')"
cargo build --quiet --offline --bin show
OUT1="$("$SCRATCH/pkga/target/debug/show")"
assert_eq C1 "$MANIFEST_VERSION" "$OUT1" \
  "env!(\"CARGO_PKG_VERSION\") returns the [package] version field"

# C1b -- the manifest value is not the empty string, so C1 is not vacuous.
if [ -n "$MANIFEST_VERSION" ]; then
  pass C1b "the manifest version parsed out of Cargo.toml is non-empty [$MANIFEST_VERSION]"
else
  fail C1b "the manifest version parsed out of Cargo.toml is empty; C1 would be vacuous"
fi

# C2 -- keep a copy of this binary, then change the manifest version.
cp "$SCRATCH/pkga/target/debug/show" "$SCRATCH/show-built-at-$MANIFEST_VERSION"
sed -i.bak 's/^version = ".*"$/version = "9.8.7-rc.1"/' Cargo.toml
rm -f Cargo.toml.bak
NEW_MANIFEST_VERSION="$($GREP -m1 '^version = ' Cargo.toml | sed 's/^version = "//; s/"$//')"
assert_eq C2a "9.8.7-rc.1" "$NEW_MANIFEST_VERSION" "the manifest edit landed"

cargo build --quiet --offline --bin show
OUT2="$("$SCRATCH/pkga/target/debug/show")"
assert_eq C2b "9.8.7-rc.1" "$OUT2" \
  "after recompiling, the accessor tracks the edited manifest version"

# C3 -- the binary built BEFORE the edit still reports the old value, with the
# edited manifest sitting right beside it. That is the compile-time binding
# measured rather than asserted: the value travels in the artifact.
OUT3="$("$SCRATCH/show-built-at-$MANIFEST_VERSION")"
assert_eq C3a "$MANIFEST_VERSION" "$OUT3" \
  "the pre-edit binary still reports its compiled-in version"
assert_ne C3b "$OUT2" "$OUT3" \
  "the pre-edit binary and the post-edit binary disagree"

# C4 -- run the pre-edit binary from a directory containing no Cargo.toml and
# no target/ anywhere above it. No runtime metadata lookup is possible there.
mkdir -p "$SCRATCH/isolated/deep"
cp "$SCRATCH/show-built-at-$MANIFEST_VERSION" "$SCRATCH/isolated/deep/show"
FOUND_MANIFEST="$(find "$SCRATCH/isolated" -name Cargo.toml -o -name '*.rlib' | wc -l | tr -d ' ')"
assert_eq C4a "0" "$FOUND_MANIFEST" "the isolated directory holds no manifest and no rlib"
OUT4="$(cd "$SCRATCH/isolated/deep" && ./show)"
assert_eq C4b "$MANIFEST_VERSION" "$OUT4" \
  "the binary reports its version with no manifest or package metadata on disk"

# C5 -- the optional feature does not move the value.
sed -i.bak 's/^version = ".*"$/version = "1.2.3"/' Cargo.toml
rm -f Cargo.toml.bak
cargo build --quiet --offline --bin show
OUT_NOWEB="$("$SCRATCH/pkga/target/debug/show")"
cargo build --quiet --offline --features web --bin show
OUT_WEB="$("$SCRATCH/pkga/target/debug/show")"
assert_eq C5a "1.2.3" "$OUT_NOWEB" "without --features web the accessor reads the manifest"
assert_eq C5b "$OUT_NOWEB" "$OUT_WEB" \
  "building with and without --features web yields a byte-identical version"

# C6 -- an accessor-equality test FAILS when the constant is a stale literal.
# This is the check that decides whether ledger row F133's retained assertion is
# vacuous in Rust. It is not.
mkdir -p tests
cat > tests/accessor_equality.rs <<'RUST'
#[test]
fn accessor_matches_cargo_package_version() {
    assert_eq!(pkga::VERSION, env!("CARGO_PKG_VERSION"));
}
RUST
if cargo test --quiet --offline --test accessor_equality > "$SCRATCH/test-good.txt" 2>&1; then
  pass C6a "the accessor-equality test passes while the accessor is env!(\"CARGO_PKG_VERSION\")"
else
  fail C6a "the accessor-equality test failed on a correctly wired accessor"
fi
cat > src/lib.rs <<'RUST'
/// Deliberately wrong: a literal that has drifted from Cargo.toml.
pub const VERSION: &str = "0.0.0";
RUST
set +e
cargo test --quiet --offline --test accessor_equality > "$SCRATCH/test-bad.txt" 2>&1
BAD_STATUS=$?
set -e
assert_ne C6b "0" "$BAD_STATUS" \
  "cargo test exits non-zero once the accessor is a stale literal (status $BAD_STATUS)"
assert_contains C6c "$SCRATCH/test-bad.txt" "accessor_matches_cargo_package_version" \
  "the failing test is named in cargo's output"
assert_contains C6d "$SCRATCH/test-bad.txt" "0.0.0" \
  "the failure report carries the drifted literal"

# ---------------------------------------------------------------------------
# Package set B: a two-member workspace. A binary in one member reading the
# OTHER member's constant is the second way F133's assertion can fail.
# ---------------------------------------------------------------------------
mkdir -p "$SCRATCH/ws"
cd "$SCRATCH/ws"
cargo new --quiet --vcs none --lib verlib
cargo new --quiet --vcs none --bin verbin
cat > Cargo.toml <<'TOML'
[workspace]
resolver = "3"
members = ["verlib", "verbin"]
TOML
sed -i.bak 's/^version = ".*"$/version = "0.1.0"/' verlib/Cargo.toml && rm -f verlib/Cargo.toml.bak
sed -i.bak 's/^version = ".*"$/version = "0.2.0"/' verbin/Cargo.toml && rm -f verbin/Cargo.toml.bak
cat >> verbin/Cargo.toml <<'TOML'
verlib = { path = "../verlib" }
TOML
cat > verlib/src/lib.rs <<'RUST'
pub const VERSION: &str = env!("CARGO_PKG_VERSION");
RUST
cat > verbin/src/main.rs <<'RUST'
fn main() {
    println!("lib={} bin={}", verlib::VERSION, env!("CARGO_PKG_VERSION"));
}
RUST
cargo build --quiet --offline --bin verbin
WS_OUT="$("$SCRATCH/ws/target/debug/verbin")"
assert_eq C7a "lib=0.1.0 bin=0.2.0" "$WS_OUT" \
  "each crate's env! expands to its OWN package version, not the workspace's"
LIB_V="${WS_OUT%% bin=*}"; LIB_V="${LIB_V#lib=}"
BIN_V="${WS_OUT##*bin=}"
assert_ne C7b "$LIB_V" "$BIN_V" \
  "a binary re-exporting another member's constant reports a different version"

# ---------------------------------------------------------------------------
# C8 -- option_env! and env! on an unset variable.
# ---------------------------------------------------------------------------
cd "$SCRATCH"
cargo new --quiet --vcs none --bin optprobe
cat > optprobe/src/main.rs <<'RUST'
fn main() {
    match option_env!("RSLBP_R22_DEFINITELY_UNSET") {
        Some(v) => println!("some:{v}"),
        None => println!("none"),
    }
}
RUST
(cd optprobe && cargo build --quiet --offline)
unset RSLBP_R22_DEFINITELY_UNSET || true
OPT_OUT="$("$SCRATCH/optprobe/target/debug/optprobe")"
assert_eq C8a "none" "$OPT_OUT" \
  "option_env! of a variable unset at compile time expands to None"
RSLBP_R22_DEFINITELY_UNSET=set-at-runtime "$SCRATCH/optprobe/target/debug/optprobe" \
  > "$SCRATCH/opt-runtime.txt"
assert_eq C8b "none" "$(cat "$SCRATCH/opt-runtime.txt")" \
  "setting the variable at RUN time does not change the expansion; option_env! is compile-time"

cat > optprobe/src/main.rs <<'RUST'
fn main() {
    println!("{}", env!("RSLBP_R22_DEFINITELY_UNSET"));
}
RUST
set +e
(cd optprobe && cargo build --quiet --offline) > "$SCRATCH/env-unset.txt" 2>&1
ENV_STATUS=$?
set -e
assert_ne C8c "0" "$ENV_STATUS" \
  "env! of a variable unset at compile time is a compile error (status $ENV_STATUS)"
assert_contains C8d "$SCRATCH/env-unset.txt" "environment variable" \
  "the compiler names the missing environment variable"

# ---------------------------------------------------------------------------
# C9 -- Cargo refuses a [package] version that is not SemVer, so the value the
# accessor returns cannot carry a leading `v` (CLI Design Standard R4.6 MUST).
# ---------------------------------------------------------------------------
cd "$SCRATCH"
cargo new --quiet --vcs none --bin semverprobe
cd semverprobe
sed -i.bak 's/^version = ".*"$/version = "v0.1.0"/' Cargo.toml && rm -f Cargo.toml.bak
set +e
cargo build --quiet --offline > "$SCRATCH/semver-bad.txt" 2>&1
SEMVER_STATUS=$?
set -e
assert_ne C9a "0" "$SEMVER_STATUS" \
  "Cargo rejects version = \"v0.1.0\" (status $SEMVER_STATUS)"
assert_contains C9b "$SCRATCH/semver-bad.txt" "v0.1.0" \
  "the rejection names the offending version string"
sed -i.bak 's/^version = ".*"$/version = "0.1.0"/' Cargo.toml && rm -f Cargo.toml.bak
if cargo build --quiet --offline > "$SCRATCH/semver-good.txt" 2>&1; then
  pass C9c "with version = \"0.1.0\" and nothing else changed the same build succeeds"
else
  fail C9c "the control build failed, so C9a cannot be attributed to the leading v"
fi

# ---------------------------------------------------------------------------
# C10 -- no nested git repository was created anywhere in the scratch tree.
# ---------------------------------------------------------------------------
GITDIRS="$(find "$SCRATCH" -name .git | wc -l | tr -d ' ')"
assert_eq C10 "0" "$GITDIRS" "the probe created no nested git repository"

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
if [ "$SKIP" -ne 0 ]; then
  echo "NOTE: skips above are named on their SKIP lines."
fi
if [ "$FAIL" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
