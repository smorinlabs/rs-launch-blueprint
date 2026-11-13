#!/usr/bin/env bash
# R50 install-smoke-test — synthesizer empirical check.
#
# Proves, on throwaway fixture crates under a scratch directory, the claims the
# R50 decision rests on. It builds nothing in this repository, installs nothing
# outside its own scratch root, and never invokes `cargo publish` in any form.
#
# Rerunnable from a clean `git archive HEAD` extraction: the repository root is
# derived from this script's own path, never from `git rev-parse`, and the one
# phase that needs a second checkout announces `SKIP` by name when it is absent.
#
# Every assertion prints `PASS <name>` or `FAIL <name>`; the script exits
# non-zero if any assertion failed.

set -o pipefail
set -u

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../../../.." && pwd)"
RUN_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
TS_REPO="$HOME/c/ts-launch-blueprint"
TS_PIN="cb1cbcb2e88b898e8c081b0abbfabc1630079c00"
GREP=/usr/bin/grep

FAILURES=0
pass() { printf 'PASS %s\n' "$1"; }
fail() { printf 'FAIL %s\n' "$1"; FAILURES=$((FAILURES + 1)); }
skip() { printf 'SKIP %s — %s\n' "$1" "$2"; }

# assert_contains <name> <file> <literal>
assert_contains() {
  local name="$1" file="$2" needle="$3" n
  n="$("$GREP" -c -F -- "$needle" "$file")" || n=0
  if [ "$n" -ge 1 ]; then
    printf 'PASS %s (/usr/bin/grep -c -F matched %s line(s) for %s)\n' "$name" "$n" "$needle"
  else
    fail "$name (/usr/bin/grep -c -F matched 0 lines for $needle)"
  fi
}

# assert_absent <name> <file> <literal>
assert_absent() {
  local name="$1" file="$2" needle="$3" n
  n="$("$GREP" -c -F -- "$needle" "$file")" || n=0
  if [ "$n" -eq 0 ]; then
    printf 'PASS %s (/usr/bin/grep -c -F matched 0 lines for %s)\n' "$name" "$needle"
  else
    fail "$name (/usr/bin/grep -c -F matched $n line(s) for $needle)"
  fi
}

assert_status() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf 'PASS %s (exit %s)\n' "$name" "$actual"
  else
    fail "$name (expected exit $expected, observed $actual)"
  fi
}

assert_count() {
  local name="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then
    printf 'PASS %s (count %s)\n' "$name" "$actual"
  else
    fail "$name (expected count $expected, observed $actual)"
  fi
}

TMPBASE="${TMPDIR:-/tmp}"
SCRATCH="$(mktemp -d "${TMPBASE%/}/r50-check.XXXXXX")"
trap 'rm -rf "$SCRATCH"' EXIT
# macOS resolves /var to /private/var, and cargo prints both forms; normalise
# against each so the saved log is comparable across reruns.
SCRATCH_REAL="$(cd "$SCRATCH" && pwd -P)"

# Normalise the volatile parts of Cargo output so the saved log is comparable
# across reruns: the scratch path, compile/install durations, and the file
# counts and byte sizes cargo prints for a packaged archive.
norm() {
  sed -e '/Blocking waiting for file lock/d' \
      -e "s#$SCRATCH_REAL#<SCRATCH>#g" \
      -e "s#$SCRATCH#<SCRATCH>#g" \
      -e "s#$HOME#<HOME>#g" \
      -e 's# in [0-9][0-9]*\.[0-9][0-9]*s# in <T>s#g' \
      -e 's#([0-9][0-9]* files, [0-9.]*[KMG]*i*B)#(<N> files, <SIZE>)#g' \
      -e 's#[0-9][0-9]* files, [0-9.]*[KMG]*i*B#<N> files, <SIZE>#g'
}

echo "=============================================================="
echo "R50 install-smoke-test — empirical check"
echo "=============================================================="

echo
echo "--- Phase A — toolchain and host identity -------------------"
cargo --version
rustc --version
just --version
uname -sm
sw_vers 2>/dev/null || echo "sw_vers: not a macOS host"
echo "repo root:  $REPO_ROOT"
echo "run dir:    $RUN_DIR"
echo "scratch:    <SCRATCH>"

echo
echo "--- Phase B — fixed-parameter registry parity ----------------"
# The decision's four `- assumes` lines must carry the CURRENT registry values.
# This run's inputs/PARAMETERS.md was snapshotted before R69 published, so the
# two files are compared row by row for exactly the four fixed parameters.
REG="$REPO_ROOT/docs/port/PARAMETERS.md"
SNAP="$RUN_DIR/inputs/PARAMETERS.md"
for param in msrv-policy rust-edition target-os-matrix license; do
  live="$("$GREP" -n "^| $param | fixed | owner |" "$REG")"
  snapped="$("$GREP" -n "^| $param | fixed | owner |" "$SNAP")"
  live_value="${live#*| fixed | owner | }"; live_value="${live_value%% |*}"
  snap_value="${snapped#*| fixed | owner | }"; snap_value="${snap_value%% |*}"
  if [ -n "$live_value" ] && [ "$live_value" = "$snap_value" ]; then
    printf 'PASS registry/fixed/%s (live == snapshot)\n' "$param"
    printf '     %s = %s\n' "$param" "$live_value"
  else
    fail "registry/fixed/$param (live '$live_value' != snapshot '$snap_value')"
  fi
done
# The snapshot discrepancy the task names, asserted rather than asserted-away:
# web-extra-surface is `—` in the snapshot and carries R69's value live. R50's
# prompt registers no consumption of it, so no `- assumes` line may carry it.
snap_web="$("$GREP" -c "^| web-extra-surface | researched | R69 | — |" "$SNAP")" || snap_web=0
assert_count "registry/web-extra-surface/snapshot-is-em-dash" 1 "$snap_web"
live_web="$("$GREP" -c "^| web-extra-surface | researched | R69 | — |" "$REG")" || live_web=0
assert_count "registry/web-extra-surface/live-is-not-em-dash" 0 "$live_web"
consumes_line="$("$GREP" -c '^- consumes:$' "$RUN_DIR/inputs/prompt.md")" || consumes_line=0
assert_count "prompt/consumes-line-is-empty" 1 "$consumes_line"
owns_line="$("$GREP" -c '^- owns:$' "$RUN_DIR/inputs/prompt.md")" || owns_line=0
assert_count "prompt/owns-line-is-empty" 1 "$owns_line"

echo
echo "--- Phase C — ts pack-check at pin cb1cbcb2 (BASELINE-REVIEW) -"
if [ ! -d "$TS_REPO/.git" ]; then
  skip "ts-pin/all" "checkout absent at $TS_REPO"
else
  TS_JUST="$SCRATCH/ts-Justfile"
  if git -C "$TS_REPO" show "$TS_PIN:Justfile" > "$TS_JUST"; then
    pass "ts-pin/read-Justfile-at-$TS_PIN"
    # The header comment the correction quotes (:268-269).
    sed -n '268,269p' "$TS_JUST" > "$SCRATCH/ts-268-269"
    assert_contains "ts-pin/header-comment-268" "$SCRATCH/ts-268-269" "then pack + install into a /private/tmp"
    assert_contains "ts-pin/header-comment-269" "$SCRATCH/ts-268-269" "scratch project and smoke-test the bin + ESM lib import"
    sed -n '275,276p' "$TS_JUST" > "$SCRATCH/ts-275-276"
    assert_contains "ts-pin/group-attributes-275" "$SCRATCH/ts-275-276" "[group('releases'), group('build')]"
    assert_contains "ts-pin/recipe-name-276" "$SCRATCH/ts-275-276" "pack-check:"
    # The install-and-run half the ledger records as absent (:299-312).
    sed -n '299,312p' "$TS_JUST" > "$SCRATCH/ts-299-312"
    assert_contains "ts-pin/scratch-dir-299" "$SCRATCH/ts-299-312" "SCRATCH=\$(mktemp -d /private/tmp/ts-pack-check.XXXXXX)"
    assert_contains "ts-pin/pack-302" "$SCRATCH/ts-299-312" "npm pack --ignore-scripts --pack-destination"
    assert_contains "ts-pin/install-304" "$SCRATCH/ts-299-312" "npm install --no-save --no-package-lock"
    assert_contains "ts-pin/run-installed-bin-306" "$SCRATCH/ts-299-312" "node_modules/.bin/{{command_name}}\" --version"
    assert_contains "ts-pin/version-equality-307" "$SCRATCH/ts-299-312" "EXPECTED=\"{{command_name}} \$VERSION\""
    assert_contains "ts-pin/lib-import-312" "$SCRATCH/ts-299-312" "import(\"{{ts_package_name}}\")"
    # No alias for pack-check anywhere in the file.
    alias_n="$("$GREP" -c -E '^alias [a-z]+ := pack-check$' "$TS_JUST")" || alias_n=0
    assert_count "ts-pin/pack-check-has-no-alias" 0 "$alias_n"
    # F221 stands: no workflow at the pin invokes the recipe.
    git -C "$TS_REPO" ls-tree --name-only "$TS_PIN:.github/workflows" > "$SCRATCH/ts-workflows"
    wf_count="$(wc -l < "$SCRATCH/ts-workflows" | tr -d ' ')"
    printf 'INFO ts-pin/workflow-file-count = %s\n' "$wf_count"
    sed -n 'p' "$SCRATCH/ts-workflows"
    : > "$SCRATCH/ts-workflows-all"
    while IFS= read -r wf; do
      git -C "$TS_REPO" show "$TS_PIN:.github/workflows/$wf" >> "$SCRATCH/ts-workflows-all" || fail "ts-pin/read-workflow-$wf"
    done < "$SCRATCH/ts-workflows"
    assert_absent "ts-pin/no-workflow-invokes-pack-check" "$SCRATCH/ts-workflows-all" "pack-check"
    assert_absent "ts-pin/no-workflow-invokes-pack_check" "$SCRATCH/ts-workflows-all" "pack_check"
  else
    fail "ts-pin/read-Justfile-at-$TS_PIN"
  fi
fi

echo
echo "--- Phase D — ledger and prompt statements the correction hits -"
assert_contains "ledger/F222-origin-py-only" "$REPO_ROOT/docs/port/COMMONALITY.md" \
  "| F222 | ephemeral wheel/sdist install-and-run smoke test | packaging-distribution | py-only |"
assert_contains "area/F222-ts-cell-em-dash" "$REPO_ROOT/docs/port/areas/packaging-distribution.md" \
  "uvx --from \"\$(ls dist/*.whl)\" plbp --version\` | — | py-only |"
assert_contains "prompt/ts-none-claim" "$RUN_DIR/inputs/prompt.md" \
  "ts: none (py-only; ts's \`pack-check\` recipe covers packed-content assertion, not an install-and-run step"

echo
echo "--- Phase E — cargo install flag surface ---------------------"
cargo install --help > "$SCRATCH/install-help" 2>&1
assert_status "cargo-install-help/exit" 0 "$?"
for flag in "--path" "--root" "--locked" "--debug" "--no-track" "--target-dir" "--features"; do
  assert_contains "cargo-install-help/has-$flag" "$SCRATCH/install-help" "$flag"
done
assert_contains "cargo-install-help/dry-run-is-unstable" "$SCRATCH/install-help" "unstable"

# ---------------------------------------------------------------------------
# Fixture builder. Zero dependencies, so nothing below touches the network.
# ---------------------------------------------------------------------------
make_fixture() {
  # make_fixture <dir> <workspace|plain> <include-helper:yes|no> <required-features:yes|no>
  local dir="$1" shape="$2" include_helper="$3" reqfeat="$4"
  mkdir -p "$dir/src"
  {
    echo '[package]'
    echo 'name = "r50spike"'
    echo 'version = "0.4.2"'
    echo 'edition = "2024"'
    echo 'license = "MIT OR Apache-2.0"'
    echo 'description = "R50 throwaway spike fixture"'
    if [ "$include_helper" = yes ]; then
      echo 'include = ["/src", "/Cargo.toml"]'
    else
      echo 'include = ["/src/main.rs", "/Cargo.toml"]'
    fi
    echo 'autobins = false'
    echo
    echo '[lib]'
    echo 'path = "src/lib.rs"'
    echo
    echo '[[bin]]'
    echo 'name = "rslbpspike"'
    echo 'path = "src/main.rs"'
    if [ "$reqfeat" = yes ]; then
      echo 'required-features = ["web"]'
    fi
    echo
    echo '[features]'
    echo 'default = []'
    echo 'web = []'
    if [ "$shape" = workspace ]; then
      echo
      echo '[workspace]'
    fi
  } > "$dir/Cargo.toml"
  cat > "$dir/src/lib.rs" <<'RS'
pub fn version() -> &'static str {
    env!("CARGO_PKG_VERSION")
}
RS
  cat > "$dir/src/helper.rs" <<'RS'
pub fn banner() -> &'static str {
    "r50spike"
}
RS
  cat > "$dir/src/main.rs" <<'RS'
mod helper;

fn main() {
    let mut args = std::env::args().skip(1);
    match args.next().as_deref() {
        Some("--version") => println!("{} {}", helper::banner(), env!("CARGO_PKG_VERSION")),
        _ => println!("{}", helper::banner()),
    }
}
RS
  ( cd "$dir" && cargo generate-lockfile --offline > /dev/null 2>&1 )
}

echo
echo "--- Phase F — option C on a workspace-rooted package ----------"
WS="$SCRATCH/ws"
make_fixture "$WS" workspace yes no
( cd "$WS" && cargo package --locked --offline --no-verify ) > "$SCRATCH/pkg-ws.log" 2>&1
pkg_status=$?
norm < "$SCRATCH/pkg-ws.log"
assert_status "optionC/package/exit" 0 "$pkg_status"
assert_absent "optionC/package/no-verify-skips-the-second-compile" "$SCRATCH/pkg-ws.log" "Verifying"
if [ -f "$WS/target/package/r50spike-0.4.2.crate" ]; then
  pass "optionC/package/crate-archive-exists (target/package/r50spike-0.4.2.crate)"
else
  fail "optionC/package/crate-archive-exists"
fi

# `--no-verify` leaves no extracted copy on disk at all: the extracted tree is a
# by-product of the verification build, not of packaging.
if [ -d "$WS/target/package/r50spike-0.4.2" ]; then
  fail "optionC/package/no-verify-leaves-no-extracted-copy (the directory exists)"
else
  pass "optionC/package/no-verify-leaves-no-extracted-copy (no target/package/r50spike-0.4.2/)"
fi

echo
echo "  F1 — cargo package WITH verification, inside a workspace"
# Cargo's own verification path manufactures an ephemeral workspace so that an
# extracted package sitting inside a workspace can still be built. It succeeds,
# and it extracts the copy that F2 then installs from in-tree.
( cd "$WS" && cargo package --locked --offline ) > "$SCRATCH/pkg-verify.log" 2>&1
verify_status=$?
norm < "$SCRATCH/pkg-verify.log"
assert_status "optionC/package-with-verify/exit" 0 "$verify_status"
assert_contains "optionC/package-with-verify/verifies" "$SCRATCH/pkg-verify.log" "Verifying r50spike"
assert_contains "optionC/package-with-verify/second-compile" "$SCRATCH/pkg-verify.log" "Compiling r50spike"
if [ -d "$WS/target/package/r50spike-0.4.2" ]; then
  pass "optionC/package-with-verify/extracted-copy-exists (target/package/r50spike-0.4.2/)"
else
  fail "optionC/package-with-verify/extracted-copy-exists"
fi

echo
echo "  F2a — install from the IN-TREE extracted copy, root-package workspace"
# Opus's raw report argues that installing from `target/package/<pkg>-<ver>`
# invites the workspace-membership problem `cargo package`'s own verification
# path bypasses with an ephemeral workspace. That claim was NOT reproduced; the
# outcome is recorded as observed, and the decision does not rest on it.
( cd "$WS" && cargo install --path "target/package/r50spike-0.4.2" \
    --root "$SCRATCH/root-intree" --locked --offline --debug --no-track ) \
    > "$SCRATCH/install-intree.log" 2>&1
intree_status=$?
norm < "$SCRATCH/install-intree.log"
assert_status "in-tree/root-package-workspace/install" 0 "$intree_status"
assert_absent "in-tree/root-package-workspace/no-wrong-workspace-error" \
  "$SCRATCH/install-intree.log" "member of the wrong workspace"
assert_absent "in-tree/root-package-workspace/no-believes-in-workspace-error" \
  "$SCRATCH/install-intree.log" "believes it's in a workspace"

echo
echo "  F2b — install from the IN-TREE extracted copy, virtual workspace"
# R02 (which crate hosts the binary targets) is open, so the other live layout
# is a virtual workspace root with the package in a member directory.
VW="$SCRATCH/vws"
mkdir -p "$VW/crates/app"
{
  echo '[workspace]'
  echo 'resolver = "3"'
  echo 'members = ["crates/*"]'
} > "$VW/Cargo.toml"
make_fixture "$VW/crates/app" plain yes no
( cd "$VW" && cargo generate-lockfile --offline > /dev/null 2>&1 )
( cd "$VW" && cargo package -p r50spike --locked --offline ) > "$SCRATCH/pkg-vws.log" 2>&1
vws_pkg_status=$?
norm < "$SCRATCH/pkg-vws.log"
assert_status "in-tree/virtual-workspace/package" 0 "$vws_pkg_status"
( cd "$VW" && cargo install --path "target/package/r50spike-0.4.2" \
    --root "$SCRATCH/root-vws" --locked --offline --debug --no-track ) \
    > "$SCRATCH/install-vws.log" 2>&1
vws_status=$?
norm < "$SCRATCH/install-vws.log"
assert_status "in-tree/virtual-workspace/install" 0 "$vws_status"
assert_absent "in-tree/virtual-workspace/no-wrong-workspace-error" \
  "$SCRATCH/install-vws.log" "member of the wrong workspace"

echo
echo "  F3 — install from a copy extracted OUTSIDE the package tree"
EXT="$SCRATCH/extract"
mkdir -p "$EXT"
tar -tzf "$WS/target/package/r50spike-0.4.2.crate" > "$SCRATCH/ws-listing"
sed -n 'p' "$SCRATCH/ws-listing"
# AC2: `cargo package` adds a minimized Cargo.lock to the archive; that is what
# makes `--locked` meaningful on the install step.
assert_contains "optionC/archive-carries-Cargo.lock" "$SCRATCH/ws-listing" "r50spike-0.4.2/Cargo.lock"
assert_contains "optionC/archive-carries-Cargo.toml" "$SCRATCH/ws-listing" "r50spike-0.4.2/Cargo.toml"
tar -xzf "$WS/target/package/r50spike-0.4.2.crate" -C "$EXT"
( cargo install --path "$EXT/r50spike-0.4.2" --root "$SCRATCH/root-ok" \
    --locked --offline --debug --no-track --target-dir "$SCRATCH/tdir-ok" ) \
    > "$SCRATCH/install-outside.log" 2>&1
outside_status=$?
norm < "$SCRATCH/install-outside.log"
assert_status "optionC/outside-install/exit" 0 "$outside_status"
assert_contains "optionC/outside-install/dev-profile" "$SCRATCH/install-outside.log" "\`dev\` profile [unoptimized + debuginfo]"
if [ -x "$SCRATCH/root-ok/bin/rslbpspike" ]; then
  pass "optionC/outside-install/installed-binary-is-executable (<SCRATCH>/root-ok/bin/rslbpspike)"
else
  fail "optionC/outside-install/installed-binary-is-executable"
fi
bin_count="$(find "$SCRATCH/root-ok/bin" -type f | wc -l | tr -d ' ')"
assert_count "optionC/outside-install/exactly-one-binary-installed" 1 "$bin_count"
"$SCRATCH/root-ok/bin/rslbpspike" --version > "$SCRATCH/run-version.log" 2>&1
run_status=$?
cat "$SCRATCH/run-version.log"
assert_status "optionC/run-installed/exit" 0 "$run_status"
assert_contains "optionC/run-installed/stdout-carries-the-manifest-version" "$SCRATCH/run-version.log" "0.4.2"

echo
echo "--- Phase G — AC7 negative control: a hole in \`include\` -------"
# The discriminating case between option B (install the working tree) and
# option C (install the packaged bytes): src/helper.rs is required by
# src/main.rs but is not in the `include` allow-list.
HOLE="$SCRATCH/hole"
make_fixture "$HOLE" workspace no no
( cd "$HOLE" && cargo package --locked --offline --no-verify ) > "$SCRATCH/pkg-hole.log" 2>&1
assert_status "AC7/package/exit" 0 "$?"
norm < "$SCRATCH/pkg-hole.log"
tar -tzf "$HOLE/target/package/r50spike-0.4.2.crate" > "$SCRATCH/hole-listing"
sed -n 'p' "$SCRATCH/hole-listing"
assert_absent "AC7/packaged-set-omits-helper" "$SCRATCH/hole-listing" "r50spike-0.4.2/src/helper.rs"
HOLE_EXT="$SCRATCH/hole-extract"
mkdir -p "$HOLE_EXT"
tar -xzf "$HOLE/target/package/r50spike-0.4.2.crate" -C "$HOLE_EXT"
( cargo install --path "$HOLE_EXT/r50spike-0.4.2" --root "$SCRATCH/root-hole" \
    --locked --offline --debug --no-track --target-dir "$SCRATCH/tdir-hole" ) \
    > "$SCRATCH/install-hole-C.log" 2>&1
hole_c_status=$?
norm < "$SCRATCH/install-hole-C.log"
if [ "$hole_c_status" -ne 0 ]; then
  pass "AC7/optionC-fails-on-the-hole (exit $hole_c_status)"
else
  fail "AC7/optionC-fails-on-the-hole (it succeeded)"
fi
# Option B installs the working tree, where the omitted file is still on disk.
( cd "$HOLE" && cargo install --path . --root "$SCRATCH/root-hole-B" \
    --locked --offline --debug --no-track --target-dir "$SCRATCH/tdir-hole-b" ) \
    > "$SCRATCH/install-hole-B.log" 2>&1
hole_b_status=$?
norm < "$SCRATCH/install-hole-B.log"
assert_status "AC7/optionB-passes-on-the-same-hole" 0 "$hole_b_status"
if [ -x "$SCRATCH/root-hole-B/bin/rslbpspike" ]; then
  pass "AC7/optionB-installed-a-binary-from-the-unpackaged-tree"
else
  fail "AC7/optionB-installed-a-binary-from-the-unpackaged-tree"
fi

echo
echo "--- Phase H — required-features: exit 0 having installed nothing -"
# The ground for asserting the installed file exists rather than trusting the
# exit status: with every binary gated behind an off-by-default feature and no
# --bin flag, cargo warns and succeeds having installed nothing.
RQ="$SCRATCH/reqfeat"
make_fixture "$RQ" workspace yes yes
( cd "$RQ" && cargo install --path . --root "$SCRATCH/root-rq" \
    --locked --offline --debug --no-track --target-dir "$SCRATCH/tdir-rq" ) \
    > "$SCRATCH/install-reqfeat.log" 2>&1
rq_status=$?
norm < "$SCRATCH/install-reqfeat.log"
assert_status "reqfeat/exit-is-zero" 0 "$rq_status"
assert_contains "reqfeat/warns-no-binaries-available" "$SCRATCH/install-reqfeat.log" \
  "none of the package's binaries are available for install using the selected features"
if [ -e "$SCRATCH/root-rq/bin/rslbpspike" ]; then
  fail "reqfeat/nothing-was-installed (the binary exists)"
else
  pass "reqfeat/nothing-was-installed (no <SCRATCH>/root-rq/bin/rslbpspike)"
fi
# With the feature on, the same package installs and runs.
( cd "$RQ" && cargo install --path . --root "$SCRATCH/root-rq-on" --features web \
    --locked --offline --debug --no-track --target-dir "$SCRATCH/tdir-rq" ) \
    > "$SCRATCH/install-reqfeat-on.log" 2>&1
rq_on_status=$?
norm < "$SCRATCH/install-reqfeat-on.log"
assert_status "reqfeat/with-feature-on/exit" 0 "$rq_on_status"
if [ -x "$SCRATCH/root-rq-on/bin/rslbpspike" ]; then
  pass "reqfeat/with-feature-on/binary-installed"
else
  fail "reqfeat/with-feature-on/binary-installed"
fi

echo
echo "--- Phase I — nothing outside the scratch root was installed ---"
# $CARGO_HOME/bin must be untouched: every install above passed --root.
if [ -e "${CARGO_HOME:-$HOME/.cargo}/bin/rslbpspike" ]; then
  fail "safety/no-install-into-cargo-home"
else
  pass "safety/no-install-into-cargo-home (no \$CARGO_HOME/bin/rslbpspike)"
fi
publish_n="$("$GREP" -c -E '^[^#]*cargo publish' "$0")" || publish_n=0
assert_count "safety/no-cargo-publish-invocation-in-this-script" 0 "$publish_n"

echo
echo "=============================================================="
if [ "$FAILURES" -eq 0 ]; then
  echo "r50-check: all assertions passed"
else
  echo "r50-check: $FAILURES assertion(s) failed"
fi
echo "=============================================================="
exit "$FAILURES"
