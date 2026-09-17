#!/usr/bin/env bash
# R02 crate-boundary-enforcement -- executes the F008 manifest guard.
#
# The Opus raw report recommends `cargo-deny` 0.20.2 `check bans` with
# `deny[].wrappers` for F008 but could execute nothing, because the tool is not
# installed on this machine; it lists three consequences as unverified:
#   (1) that a banned framework added to crates/core fails the check,
#   (2) whether the default graph includes [dev-dependencies] edges,
#   (3) the wall-clock cost, which is the input F116's tier line turns on.
# It also predicts from reading src/bans.rs that a `tokio` row cannot work,
# because `wrappers` demands that EVERY direct dependent of the banned crate be
# listed and `axum` depends on `tokio` directly.
#
# This script downloads the published 0.20.2 binary, verifies it against the
# release's own .sha256 asset, and runs the tool against a throwaway workspace
# under $TMPDIR, resolving all four questions. The probe uses path-only stand-in
# packages named `axum` 0.8.9 and `tokio` 1.53.1 so the whole run is offline and
# no crates.io index is needed; the stand-ins reproduce the dependency SHAPE the
# real crates have (axum depends on tokio directly), which is what `wrappers` is
# keyed on. They are not the real crates and no claim is made about their code.
#
# Network use: one GitHub release download (authenticated via gh for the asset
# URL; no token or environment is printed). Everything else is offline.
#
# Exit 0 only when FAILURES is 0.

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
CD_VERSION=0.20.2
CD_TARGET=aarch64-apple-darwin
CHECKS=0
FAILURES=0
SKIPPED=0

note() { printf '\n=== %s ===\n' "$1"; }

ok() {
  local name="$1" what="$2" file="$3"
  shift 3
  CHECKS=$((CHECKS + 1))
  local pat missing=0
  for pat in "$@"; do
    if ! "$GREP" -qF -- "$pat" "$file"; then
      printf 'FAIL %s: %s -- missing substring: %s\n' "$name" "$what" "$pat"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    printf 'PASS %s: %s\n' "$name" "$what"
  else
    FAILURES=$((FAILURES + 1))
  fi
}

absent() {
  local name="$1" what="$2" file="$3" pat="$4"
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qF -- "$pat" "$file"; then
    printf 'FAIL %s: %s -- unexpected substring: %s\n' "$name" "$what" "$pat"
    FAILURES=$((FAILURES + 1))
  else
    printf 'PASS %s: %s (absent: %s)\n' "$name" "$what" "$pat"
  fi
}

eq() {
  local name="$1" what="$2" got="$3" want="$4"
  CHECKS=$((CHECKS + 1))
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s == %s\n' "$name" "$what" "$got"
  else
    printf 'FAIL %s: %s -- wanted %s, got %s\n' "$name" "$what" "$want" "$got"
    FAILURES=$((FAILURES + 1))
  fi
}

note "C0 environment"
uname -sm
cargo --version
command -v gh >/dev/null || { echo "FATAL: gh is required for the release asset URL"; exit 2; }
case "$(uname -sm)" in
  "Darwin arm64") ;;
  *) printf 'SKIP: this script downloads the %s build; rerun on that target or change CD_TARGET\n' "$CD_TARGET"; exit 0 ;;
esac

D=$(mktemp -d "${TMPDIR:-/tmp}/r02-deny.XXXXXX")
cleanup() { rm -rf "$D"; }
trap cleanup EXIT
printf 'probe root: %s (deleted on exit)\n' "$D"

############################################################################
# 0. Fetch and verify the tool
############################################################################
note "0 cargo-deny $CD_VERSION $CD_TARGET, verified against the release's own .sha256 asset"
TARBALL="cargo-deny-$CD_VERSION-$CD_TARGET.tar.gz"
BASE="https://github.com/EmbarkStudios/cargo-deny/releases/download/$CD_VERSION"
curl -sSL -o "$D/$TARBALL" "$BASE/$TARBALL"
curl -sSL -o "$D/$TARBALL.sha256" "$BASE/$TARBALL.sha256"
PUBLISHED=$(tr -d ' \n' < "$D/$TARBALL.sha256")
OBSERVED=$(shasum -a 256 "$D/$TARBALL" | awk '{print $1}')
printf 'published sha256: %s\nobserved  sha256: %s\n' "$PUBLISHED" "$OBSERVED"
eq CD0a "the downloaded tarball matches the checksum EmbarkStudios published beside it" \
  "$OBSERVED" "$PUBLISHED"
eq CD0b "and that checksum is the one this decision pins" \
  "$OBSERVED" "fe67d82a10d8597a3549364cb733a3f9cc1bfff9031b7ae46384a9f2a72090c3"
tar xzf "$D/$TARBALL" -C "$D"
CD="$D/cargo-deny-$CD_VERSION-$CD_TARGET/cargo-deny"
"$CD" --version > "$D/version.txt" 2>&1
cat "$D/version.txt"
ok CD0c "the binary runs and reports the pinned version" "$D/version.txt" "cargo-deny $CD_VERSION"

############################################################################
# Probe workspace
############################################################################
W="$D/ws"
mkdir -p "$W/src" "$W/crates/core/src" "$W/crates/cli/src" "$W/crates/web/src" \
         "$W/vendor/axum/src" "$W/vendor/tokio/src"

cat > "$W/Cargo.toml" <<'TOML'
[workspace]
members = ["crates/*", "vendor/*"]
resolver = "3"

[package]
name = "rs-launch-blueprint"
version = "0.1.0"
edition = "2024"

[lib]
path = "src/lib.rs"

[features]
web = ["dep:rs-launch-blueprint-web"]

[dependencies]
rs-launch-blueprint-core = { path = "crates/core" }
rs-launch-blueprint-cli = { path = "crates/cli" }
rs-launch-blueprint-web = { path = "crates/web", optional = true }
TOML
: > "$W/src/lib.rs"

core_manifest() {
  cat > "$W/crates/core/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-core"
version = "0.1.0"
edition = "2024"

[dependencies]
TOML
  if [ "$#" -gt 0 ]; then printf '%s\n' "$@" >> "$W/crates/core/Cargo.toml"; fi
}
core_manifest
for p in cli web; do
  cat > "$W/crates/$p/Cargo.toml" <<TOML
[package]
name = "rs-launch-blueprint-$p"
version = "0.1.0"
edition = "2024"

[dependencies]
TOML
  : > "$W/crates/$p/src/lib.rs"
done
: > "$W/crates/core/src/lib.rs"
cat >> "$W/crates/web/Cargo.toml" <<'TOML'
axum = { path = "../../vendor/axum" }
tokio = { path = "../../vendor/tokio" }
TOML
cat > "$W/vendor/axum/Cargo.toml" <<'TOML'
[package]
name = "axum"
version = "0.8.9"
edition = "2024"

[dependencies]
tokio = { path = "../tokio" }
TOML
cat > "$W/vendor/tokio/Cargo.toml" <<'TOML'
[package]
name = "tokio"
version = "1.53.1"
edition = "2024"
TOML
: > "$W/vendor/axum/src/lib.rs"
: > "$W/vendor/tokio/src/lib.rs"

deny_axum() {
  cat > "$W/deny.toml" <<'TOML'
[bans]
multiple-versions = "warn"
deny = [
  { crate = "axum", wrappers = ["rs-launch-blueprint-web"], reason = "core and the CLI are framework-agnostic (F008)" },
]
TOML
}
deny_axum

relock() { ( cd "$W" && cargo generate-lockfile --offline ) >/dev/null 2>&1; }
run_deny() {
  local out="$1"; shift
  set +e
  ( cd "$W" && "$CD" "$@" ) > "$out" 2>&1
  local st=$?
  set -e
  printf '%s' "$st"
}

############################################################################
# 1. Clean tree passes
############################################################################
note "1 clean tree: cargo deny --all-features check bans"
relock
S=$(run_deny "$D/1.log" --all-features check bans)
cat "$D/1.log"
printf 'exit status: %s\n' "$S"
eq CD1a "a conforming workspace exits 0" "$S" "0"
ok CD1b "and says so" "$D/1.log" "bans ok"

############################################################################
# 2. The framework added to crates/core [dependencies] -- Opus's unverified (1)
############################################################################
note "2 axum added to crates/core [dependencies]"
core_manifest 'axum = { path = "../../vendor/axum" }'
relock
S=$(run_deny "$D/2.log" --all-features check bans)
cat "$D/2.log"
printf 'exit status: %s\n' "$S"
eq CD2a "the check fails" "$S" "2"
ok CD2b "naming the offending member as an unmatched wrapper, and the ban that fired" \
  "$D/2.log" \
  "direct parent 'rs-launch-blueprint-core = 0.1.0' of banned crate 'axum = 0.8.9' was not marked as a wrapper" \
  "error[banned]: crate 'axum = 0.8.9' is explicitly banned" \
  "bans FAILED"
ok CD2c "and the reason string reaches the diagnostic" "$D/2.log" \
  "core and the CLI are framework-agnostic (F008)"

############################################################################
# 3. The framework added to crates/core [dev-dependencies] -- Opus's unverified (2)
############################################################################
note "3 axum added to crates/core [dev-dependencies] instead"
core_manifest '' '[dev-dependencies]' 'axum = { path = "../../vendor/axum" }'
relock
S=$(run_deny "$D/3.log" --all-features check bans)
cat "$D/3.log"
printf 'exit status: %s\n' "$S"
eq CD3a "ANSWERED: the default graph DOES include dev edges, so a dev-dependency back door also fails" \
  "$S" "2"
ok CD3b "with the ban firing" "$D/3.log" \
  "error[banned]: crate 'axum = 0.8.9' is explicitly banned" "bans FAILED"

############################################################################
# 4. The tokio row Opus predicted cannot work
############################################################################
note "4 tokio banned with wrappers, on a CLEAN tree"
core_manifest
cat > "$W/deny.toml" <<'TOML'
[bans]
multiple-versions = "warn"
deny = [
  { crate = "tokio", wrappers = ["rs-launch-blueprint-web"], reason = "probe of the wrappers semantics" },
]
TOML
relock
S=$(run_deny "$D/4.log" --all-features check bans)
cat "$D/4.log"
printf 'exit status: %s\n' "$S"
eq CD4a "CONFIRMED: a wrappers row for a crate that other crates also depend on directly fails a CLEAN tree" \
  "$S" "2"
ok CD4b "and the diagnostic shows axum as the second direct parent that makes it impossible" \
  "$D/4.log" "axum v0.8.9" "error[banned]: crate 'tokio = 1.53.1' is explicitly banned"

############################################################################
# 5. Flag position and feature scope -- an operational finding no raw carries
############################################################################
note "5 --all-features is a GLOBAL flag, and it decides whether the optional member is in the graph"
deny_axum
relock
set +e
( cd "$W" && "$CD" check bans --all-features ) > "$D/5a.log" 2>&1
S=$?
set -e
cat "$D/5a.log"
printf 'exit status: %s\n' "$S"
ok CD5a "'cargo deny check bans --all-features' -- the form both the Opus and perplexity legs imply -- is rejected by the argument parser" \
  "$D/5a.log" "unexpected argument '--all-features' found"

( cd "$W" && "$CD" list ) > "$D/5b.log" 2>&1 || true
cat "$D/5b.log"
ok CD5b "without --all-features the graph holds only the three non-optional packages" \
  "$D/5b.log" "rs-launch-blueprint@0.1.0" "rs-launch-blueprint-cli@0.1.0" "rs-launch-blueprint-core@0.1.0"
absent CD5c "the optional web member is NOT in the default graph, so a framework reachable only through it is invisible to a default-feature run" \
  "$D/5b.log" "rs-launch-blueprint-web@0.1.0"

( cd "$W" && "$CD" --all-features list ) > "$D/5d.log" 2>&1 || true
cat "$D/5d.log"
ok CD5d "with the global flag the optional member and both frameworks enter the graph" \
  "$D/5d.log" "rs-launch-blueprint-web@0.1.0" "axum@0.8.9" "tokio@1.53.1"

############################################################################
# 6. Wall clock -- Opus's unverified (3), F116's input
############################################################################
note "6 wall clock of one bans pass"
relock
START=$(python3 -c 'import time;print(time.time())')
run_deny "$D/6.log" --all-features check bans > /dev/null
END=$(python3 -c 'import time;print(time.time())')
ELAPSED=$(python3 -c "print('%.3f' % ($END - $START))")
printf 'elapsed wall clock for one "cargo deny --all-features check bans": %s s\n' "$ELAPSED"
printf 'SCOPE LIMIT: this is a 6-package, path-only, zero-registry workspace on macOS arm64.\n'
printf 'It is a FLOOR, not a figure for the real template, whose resolved graph will hold\n'
printf 'hundreds of crates. It establishes that the tool is not seconds-slow on a small\n'
printf 'graph; it does not establish the real cost, which P03 must measure on both runners.\n'
CHECKS=$((CHECKS + 1))
if python3 -c "import sys; sys.exit(0 if $ELAPSED < 10 else 1)"; then
  printf 'PASS CD6: one bans pass on this probe completed in %s s, under the 10 s bound this check asserts\n' "$ELAPSED"
else
  printf 'FAIL CD6: one bans pass took %s s, at or above the 10 s bound\n' "$ELAPSED"
  FAILURES=$((FAILURES + 1))
fi

note "SUMMARY"
printf 'CHECKS RUN: %s FAILURES: %s SKIPPED: %s\n' "$CHECKS" "$FAILURES" "$SKIPPED"
[ "$FAILURES" -eq 0 ]
