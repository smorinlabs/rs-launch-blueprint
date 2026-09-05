#!/usr/bin/env bash
# R23 lockfile-version-sync — empirical acceptance runner.
# Entry point: `bash run-checks.sh` from this directory. Exit 0 only when every
# asserted case matches. Fixtures under single/, ws/, ws-inherit/ are pristine;
# every scenario works on a fresh copy under .work/ (git-ignored).
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK="$HERE/.work"
rm -rf "$WORK" && mkdir -p "$WORK"
export CARGO_TARGET_DIR="$WORK/target"
export CARGO_TERM_COLOR=never NO_COLOR=1
MSRV_FLOOR="${MSRV_FLOOR:-1.96.0}"     # stable 1.98 minus 2 minors (msrv-policy)
BELOW_FLOOR="${BELOW_FLOOR:-1.91.1}"   # an installed toolchain under rust-version
DRIVER="$HERE/rp-driver.cjs"
# release-please is pinned by the committed package-lock.json; install it once if absent
# (added after the recorded run; a no-op whenever node_modules/release-please exists).
[ -d "$HERE/node_modules/release-please" ] || (cd "$HERE" && npm ci --no-audit --no-fund --loglevel=error)
PASS=0; FAIL=0; RECORD=0

section() { printf '\n===== %s =====\n' "$*"; }
# run <label> <expected-exit> <dir> <cmd...>
run() {
  local label="$1" expect="$2" dir="$3"; shift 3
  local out rc
  out="$(cd "$dir" && "$@" 2>&1)"; rc=$?
  printf -- '--- %s\n(cwd %s)\n$ %s\n%s\n[exit %s, expected %s]\n' "$label" "${dir#$HERE/}" "$*" "$out" "$rc" "$expect"
  if [ "$rc" = "$expect" ]; then PASS=$((PASS+1)); echo "PASS: $label"; else FAIL=$((FAIL+1)); echo "FAIL: $label"; fi
  LAST_OUT="$out"
}
# record <label> <dir> <cmd...>   (observed, not asserted)
record() {
  local label="$1" dir="$2"; shift 2
  local out rc
  out="$(cd "$dir" && "$@" 2>&1)"; rc=$?
  printf -- '--- %s (recorded)\n(cwd %s)\n$ %s\n%s\n[exit %s]\n' "$label" "${dir#$HERE/}" "$*" "$out" "$rc"
  RECORD=$((RECORD+1))
  LAST_OUT="$out"
}
assert_eq() {
  local label="$1" got="$2" want="$3"
  if [ "$got" = "$want" ]; then PASS=$((PASS+1)); echo "PASS: $label ($got)"; else FAIL=$((FAIL+1)); echo "FAIL: $label (got '$got', want '$want')"; fi
}
assert_contains() {
  local label="$1" needle="$2"
  if printf '%s' "$LAST_OUT" | grep -qF -- "$needle"; then PASS=$((PASS+1)); echo "PASS: $label (output contains '$needle')"; else FAIL=$((FAIL+1)); echo "FAIL: $label (output lacks '$needle')"; fi
}
fresh() { # fresh <fixture> <scenario> -> prints the copy's path
  local dst="$WORK/$2"
  rm -rf "$dst" && cp -R "$HERE/$1" "$dst" && rm -rf "$dst/target"
  echo "$dst"
}
bump_manifest() { # bump_manifest <Cargo.toml> <old> <new>  — the hand edit release-please's CargoToml would make
  perl -pi -e "s/^version = \"\Q$2\E\"\$/version = \"$3\"/" "$1"
}
show_diff() { # show_diff <label> <pristine> <changed>
  printf -- '--- diff %s\n' "$1"; diff -u "$2" "$3" | sed '1,2d'; echo "[end diff]"
}
added_lines() { diff "$1" "$2" | grep -c '^>'; }
# tc_env <toolchain> <cmd...>: run with BOTH cargo and rustc from that rustup toolchain.
# (`rustup run <tc> cargo` picks the toolchain cargo, but that cargo resolves `rustc`
# from PATH, which is Homebrew rustc 1.98 on this host, so rust-version was never checked.)
tc_env() { local tc="$1"; shift; env PATH="$(rustup run "$tc" rustc --print sysroot)/bin:$PATH" "$@"; }
bump_dep_requirement() { # bump_dep_requirement <Cargo.toml> <dep> <old> <new>
  perl -pi -e "s/^(\Q$2\E = \{[^}]*version = )\"\Q$3\E\"/\${1}\"$4\"/" "$1"
}

section "S0 toolchain"
run "rustc --version" 0 "$HERE" rustc --version
run "cargo --version" 0 "$HERE" cargo --version
run "floor toolchain $MSRV_FLOOR (cargo and rustc)" 0 "$HERE" tc_env "$MSRV_FLOOR" sh -c 'command -v cargo; cargo --version; rustc --version'
run "below-floor toolchain $BELOW_FLOOR (cargo and rustc)" 0 "$HERE" tc_env "$BELOW_FLOOR" sh -c 'command -v cargo; cargo --version; rustc --version'
run "node --version" 0 "$HERE" node --version
run "release-please resolved version" 0 "$HERE" node -p "require('$HERE/node_modules/release-please/package.json').version"
record "OS" "$HERE" uname -srm
record "macOS version (if macOS)" "$HERE" sh -c 'sw_vers 2>/dev/null || cat /etc/os-release'

section "S1 single crate, committed lock consistent with Cargo.toml"
S1="$(fresh single s1)"
run "S1 cargo build --locked" 0 "$S1" cargo build --locked
run "S1 cargo metadata --locked" 0 "$S1" sh -c 'cargo metadata --locked --format-version 1 >/dev/null'
run "S1 cargo test --locked (F133 meta-tests at consistent state)" 0 "$S1" cargo test --locked --test version_consistency
assert_contains "S1 three meta-tests pass" "3 passed"
record "S1 Cargo.lock entry for demo-single" "$S1" grep -A1 'name = "demo-single"' Cargo.lock

section "S2 single crate, Cargo.toml bumped 0.1.0 -> 0.2.0, Cargo.lock left stale"
S2="$(fresh single s2)"
bump_manifest "$S2/Cargo.toml" 0.1.0 0.2.0
show_diff "S2 Cargo.toml" "$HERE/single/Cargo.toml" "$S2/Cargo.toml"
run "S2 cargo build --locked refuses the stale lock" 101 "$S2" cargo build --locked
assert_contains "S2 refusal names --locked" "--locked"
run "S2 cargo metadata --locked refuses the stale lock" 101 "$S2" sh -c 'cargo metadata --locked --format-version 1 >/dev/null'
run "S2 Cargo.lock untouched by the refusals" 0 "$S2" cmp Cargo.lock "$HERE/single/Cargo.lock"

section "S3 is a test-level Cargo.toml<->Cargo.lock assertion observable through cargo?"
S3="$(fresh single s3)"
bump_manifest "$S3/Cargo.toml" 0.1.0 0.2.0
run "S3 cargo test WITHOUT --locked, lock assertion only" 0 "$S3" cargo test --test version_consistency cargo_lock_entry_matches_cargo_toml
assert_contains "S3 lock assertion passed although the committed lock was stale" "1 passed"
show_diff "S3 Cargo.lock after plain cargo test (cargo rewrote it before the test ran)" "$HERE/single/Cargo.lock" "$S3/Cargo.lock"
assert_eq "S3 cargo rewrote exactly one lock line" "$(added_lines "$HERE/single/Cargo.lock" "$S3/Cargo.lock")" 1
run "S3 the .release-please-manifest.json assertion is observable (fails at this state)" 101 "$S3" cargo test --test version_consistency release_please_manifest_matches_cargo_toml
assert_contains "S3 manifest assertion failed" "1 failed"
S3B="$(fresh single s3b)"
bump_manifest "$S3B/Cargo.toml" 0.1.0 0.2.0
run "S3 cargo test --locked never reaches the tests" 101 "$S3B" cargo test --locked --test version_consistency
assert_eq "S3 no test binary ran under --locked" "$(printf '%s' "$LAST_OUT" | grep -c 'running ')" 0

section "S4 single crate, release-please release-type rust (Rust strategy -> CargoToml + CargoLock)"
S4="$(fresh single s4)"
run "S4 Rust.buildUpdates at path '.' 0.1.0 -> 0.2.0" 0 "$HERE" node "$DRIVER" rust-strategy "$S4" . 0.1.0 0.2.0
assert_contains "S4 strategy scheduled Cargo.lock" "Cargo.toml, Cargo.lock"
assert_contains "S4 Cargo.lock updated by CargoLock" "Cargo.lock: updated by CargoLock"
run "S4 manifest-layer bump of .release-please-manifest.json" 0 "$HERE" node "$DRIVER" bump-rp-manifest "$S4/.release-please-manifest.json" . 0.2.0
show_diff "S4 Cargo.toml" "$HERE/single/Cargo.toml" "$S4/Cargo.toml"
show_diff "S4 Cargo.lock" "$HERE/single/Cargo.lock" "$S4/Cargo.lock"
show_diff "S4 .release-please-manifest.json" "$HERE/single/.release-please-manifest.json" "$S4/.release-please-manifest.json"
assert_eq "S4 Cargo.lock diff is exactly one line" "$(added_lines "$HERE/single/Cargo.lock" "$S4/Cargo.lock")" 1
run "S4 cargo build --locked accepts the release-please-updated lock" 0 "$S4" cargo build --locked
run "S4 cargo test --locked (F133 meta-tests pass after the release update)" 0 "$S4" cargo test --locked --test version_consistency
assert_contains "S4 three meta-tests pass" "3 passed"

section "S5 runner-up: generic TOML extra-files jsonpath against Cargo.lock"
S5="$(fresh single s5)"
run "S5 CargoToml 0.2.0" 0 "$HERE" node "$DRIVER" cargo-toml "$S5/Cargo.toml" 0.2.0 demo-single=0.2.0
# The natural jsonpath (the shape a reader would copy from py's uv.lock entry minus its `.value`) matches nothing:
# GenericToml parses with release-please's TaggedTOMLParser (util/toml-edit.js:63), so scalars are {value: ...} nodes.
run "S5a GenericToml with the natural jsonpath silently changes nothing (exit 0)" 0 "$HERE" node "$DRIVER" generic-toml "$S5/Cargo.lock" '$.package[?(@.name=="demo-single")].version' 0.2.0
assert_contains "S5a only a warning is emitted" "No entries modified"
run "S5a Cargo.lock untouched" 0 "$S5" cmp Cargo.lock "$HERE/single/Cargo.lock"
run "S5a cargo build --locked therefore still refuses" 101 "$S5" cargo build --locked
run "S5b GenericToml with the tagged-AST jsonpath (.name.value)" 0 "$HERE" node "$DRIVER" generic-toml "$S5/Cargo.lock" '$.package[?(@.name.value=="demo-single")].version' 0.2.0
show_diff "S5b Cargo.lock" "$HERE/single/Cargo.lock" "$S5/Cargo.lock"
assert_eq "S5b Cargo.lock diff is exactly one line" "$(added_lines "$HERE/single/Cargo.lock" "$S5/Cargo.lock")" 1
run "S5b cargo build --locked accepts the jsonpath-updated lock" 0 "$S5" cargo build --locked
run "S5b GenericToml output is byte-identical to the CargoLock output" 0 "$S5" cmp Cargo.lock "$S4/Cargo.lock"

section "S6 virtual-root workspace, members with literal versions"
S6="$(fresh ws s6)"
run "S6 cargo build --locked --workspace (pristine)" 0 "$S6" cargo build --locked --workspace
run "S6a Rust strategy at '.' on a virtual root (glob members)" 3 "$HERE" node "$DRIVER" rust-strategy "$S6" . 0.1.0 0.2.0
assert_contains "S6a strategy does not expand member globs" "member crates/* declared but did not find Cargo.toml"
assert_contains "S6a root CargoToml throws on a virtual manifest" "is not a package manifest (might be a cargo workspace)"
S6C="$(fresh ws s6c)"
perl -pi -e 's|^members = \["crates/\*"\]$|members = ["crates/demo-lib", "crates/demo-app"]|' "$S6C/Cargo.toml"
run "S6c Rust strategy at '.' on a virtual root (literal members)" 3 "$HERE" node "$DRIVER" rust-strategy "$S6C" . 0.1.0 0.2.0
assert_contains "S6c members found" "found workspace with 2 members"
assert_contains "S6c root CargoToml still throws" "is not a package manifest (might be a cargo workspace)"
S6D="$(fresh ws s6d)"
run "S6d cargo-workspace plugin enumerates the members" 0 "$HERE" node "$DRIVER" cargo-workspace-plugin "$S6D"
assert_contains "S6d plugin sees demo-app" "crates/demo-app  demo-app  0.1.0"
assert_contains "S6d plugin sees demo-lib" "crates/demo-lib  demo-lib  0.1.0"
run "S6d Rust strategy at path crates/demo-app (manifest-mode per-crate package)" 0 "$HERE" node "$DRIVER" rust-strategy "$S6D" crates/demo-app 0.1.0 0.2.0
assert_contains "S6d per-crate Cargo.lock is absent and skipped" "crates/demo-app/Cargo.lock: did not exist"
run "S6d plugin step: CargoLock(updatedVersions) on the root Cargo.lock" 0 "$HERE" node "$DRIVER" cargo-lock "$S6D/Cargo.lock" demo-app=0.2.0
show_diff "S6d crates/demo-app/Cargo.toml" "$HERE/ws/crates/demo-app/Cargo.toml" "$S6D/crates/demo-app/Cargo.toml"
show_diff "S6d root Cargo.lock" "$HERE/ws/Cargo.lock" "$S6D/Cargo.lock"
assert_eq "S6d root Cargo.lock diff is exactly one line (demo-lib entry and the dependency edge untouched)" "$(added_lines "$HERE/ws/Cargo.lock" "$S6D/Cargo.lock")" 1
run "S6d demo-lib manifest untouched" 0 "$S6D" cmp crates/demo-lib/Cargo.toml "$HERE/ws/crates/demo-lib/Cargo.toml"
run "S6d cargo build --locked --workspace" 0 "$S6D" cargo build --locked --workspace
S6E="$(fresh ws s6e)"
run "S6e both members bump: CargoToml demo-lib" 0 "$HERE" node "$DRIVER" cargo-toml "$S6E/crates/demo-lib/Cargo.toml" 0.2.0 demo-lib=0.2.0 demo-app=0.2.0
run "S6e both members bump: CargoToml demo-app (path dep requirement follows)" 0 "$HERE" node "$DRIVER" cargo-toml "$S6E/crates/demo-app/Cargo.toml" 0.2.0 demo-lib=0.2.0 demo-app=0.2.0
assert_contains "S6e dependency requirement on demo-lib bumped" "updating dependencies.demo-lib from 0.1.0 to 0.2.0"
run "S6e CargoLock both members" 0 "$HERE" node "$DRIVER" cargo-lock "$S6E/Cargo.lock" demo-lib=0.2.0 demo-app=0.2.0
show_diff "S6e crates/demo-app/Cargo.toml" "$HERE/ws/crates/demo-app/Cargo.toml" "$S6E/crates/demo-app/Cargo.toml"
show_diff "S6e root Cargo.lock" "$HERE/ws/Cargo.lock" "$S6E/Cargo.lock"
assert_eq "S6e root Cargo.lock diff is exactly two lines" "$(added_lines "$HERE/ws/Cargo.lock" "$S6E/Cargo.lock")" 2
run "S6e cargo build --locked --workspace" 0 "$S6E" cargo build --locked --workspace

section "S7 workspace with [workspace.package] version inheritance"
S7="$(fresh ws-inherit s7)"
run "S7 cargo build --locked --workspace (pristine)" 0 "$S7" cargo build --locked --workspace
bump_manifest "$S7/Cargo.toml" 0.1.0 0.2.0
show_diff "S7 root Cargo.toml" "$HERE/ws-inherit/Cargo.toml" "$S7/Cargo.toml"
run "S7 inherited bump: cargo build --locked refuses (demo-app's demo-lib ^0.1.0 requirement is unsatisfiable)" 101 "$S7" cargo build --locked --workspace
run "S7 cargo update -w cannot resolve either: the requirement, not the lock, is the blocker" 101 "$S7" cargo update -w
assert_contains "S7 the intra-workspace requirement is the blocker" 'failed to select a version for the requirement `demo-lib = "^0.1.0"`'
bump_dep_requirement "$S7/crates/demo-app/Cargo.toml" demo-lib 0.1.0 0.2.0
show_diff "S7 crates/demo-app/Cargo.toml (requirement bumped, as CargoToml versionsMap does)" "$HERE/ws-inherit/crates/demo-app/Cargo.toml" "$S7/crates/demo-app/Cargo.toml"
run "S7 with the requirement bumped, --locked now refuses purely on the stale lock (both inherited entries)" 101 "$S7" cargo build --locked --workspace
assert_contains "S7 refusal names --locked" "--locked"
run "S7 cargo update -w after the requirement bump" 0 "$S7" cargo update -w
show_diff "S7 root Cargo.lock after cargo update -w" "$HERE/ws-inherit/Cargo.lock" "$S7/Cargo.lock"
assert_eq "S7 two lock lines moved" "$(added_lines "$HERE/ws-inherit/Cargo.lock" "$S7/Cargo.lock")" 2
S7C="$(fresh ws-inherit s7c)"
run "S7c cargo-workspace plugin rejects version.workspace = true" 2 "$HERE" node "$DRIVER" cargo-workspace-plugin "$S7C"
assert_contains "S7c ConfigurationError" "invalid [package.version]"
record "S7c Rust strategy at crates/demo-app on an inheriting member" "$HERE" node "$DRIVER" rust-strategy "$S7C" crates/demo-app 0.1.0 0.2.0
show_diff "S7c crates/demo-app/Cargo.toml after the strategy" "$HERE/ws-inherit/crates/demo-app/Cargo.toml" "$S7C/crates/demo-app/Cargo.toml"
record "S7c cargo metadata after the strategy" "$S7C" sh -c 'cargo metadata --locked --format-version 1 >/dev/null'

section "S8 msrv-policy floor and declared rust-version"
run "S8 floor toolchain builds the release-updated single crate --locked" 0 "$S4" tc_env "$MSRV_FLOOR" cargo build --locked
run "S8 floor toolchain builds the release-updated workspace --locked" 0 "$S6D" tc_env "$MSRV_FLOOR" cargo build --locked --workspace
run "S8 a toolchain below rust-version is refused" 101 "$S4" tc_env "$BELOW_FLOOR" cargo build --locked
assert_contains "S8 refusal cites the declared rust-version" "requires rustc 1.96"

section "S9 excluded alternative: cargo-native repair after the manifest bump (a second commit)"
S9="$(fresh single s9)"
bump_manifest "$S9/Cargo.toml" 0.1.0 0.2.0
run "S9 cargo update -w" 0 "$S9" cargo update -w
show_diff "S9 Cargo.lock" "$HERE/single/Cargo.lock" "$S9/Cargo.lock"
assert_eq "S9 Cargo.lock diff is exactly one line" "$(added_lines "$HERE/single/Cargo.lock" "$S9/Cargo.lock")" 1
run "S9 release-please CargoLock output is byte-identical to cargo's own update" 0 "$S9" cmp Cargo.lock "$S4/Cargo.lock"

section "summary"
echo "summary: PASS=$PASS FAIL=$FAIL RECORD=$RECORD"
if [ "$FAIL" = 0 ]; then echo "RESULT: PASS"; exit 0; else echo "RESULT: FAIL"; exit 1; fi
