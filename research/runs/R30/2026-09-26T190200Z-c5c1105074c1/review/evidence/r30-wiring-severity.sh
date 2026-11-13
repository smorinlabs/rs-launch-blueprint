#!/usr/bin/env bash
# R30 check V — the severity switch through the real wiring: that CARGO_BUILD_WARNINGS=deny,
# written as a Justfile line prefix and as a lefthook 2.x per-job `env:` key, actually reaches
# cargo (a warning, not a hard error, must fail both); and how the recipe and the hook differ
# when BOTH configurations fail (just stops at its first failing line; lefthook runs every job).
# Zero registry dependencies; scratch git repository outside the repository.
# Usage: bash r30-wiring-severity.sh > r30-wiring-severity.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
unset RUSTFLAGS CARGO_BUILD_WARNINGS CARGO_ENCODED_RUSTFLAGS

echo "# r30-wiring-severity.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)"
echo "# stable: $(cargo --version) / $(rustc --version)"
echo "# just $(just --version | cut -d' ' -f2)  lefthook $(lefthook version)"

WS=$(mktemp -d "${TMPDIR:-/tmp}/r30-wsev.XXXXXX")
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
  echo "\$ $*"
  printf '%s\n' "$out" | sed -e 's/\x1b\[[0-9;]*m//g' -e 's#'"$WS"'#<ws>#g' \
    | grep -E '^(error|warning)(\[|:)|warnings are denied|Recipe .* failed|typecheck \(|^ *-->' | grep -v '^warning: build failed'
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}
commit() { git -c user.email=probe@example.invalid -c user.name=probe commit -q --no-verify -m "$1"; }

mkdir -p src
cat > Cargo.toml <<'EOF'
[package]
name = "facade"
version = "0.1.0"
edition = "2024"

[features]
web = []
EOF
echo 'pub fn f() -> u32 { 1 }' > src/lib.rs
cargo generate-lockfile --offline >/dev/null 2>&1

# the recommended recipe and hook, verbatim
cat > Justfile <<'EOF'
# Type-check every target in both feature configurations; lint warnings from workspace packages fail
[group('dev')]
typecheck:
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --locked --keep-going
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going

alias tc := typecheck
EOF
cat > lefthook.yml <<'EOF'
pre-commit:
  jobs:
    - name: typecheck (default features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: cargo check --workspace --all-targets --locked --keep-going
    - name: typecheck (all features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: cargo check --workspace --all-targets --all-features --locked --keep-going
EOF
git init -q . && git add -A && commit init

echo
echo "# --- V1: a lint WARNING (unused variable), not a hard error, staged"
printf 'pub fn g() { let unused = 5; }\n' >> src/lib.rs && git add src/lib.rs
run "V1a plain cargo check — lax, exit 0" 0 cargo check --workspace --all-targets --locked
run "V1b just typecheck — the line-prefix variable reaches cargo, recipe fails" 101 just typecheck
run "V1c lefthook run pre-commit — the per-job env: key reaches cargo, hook fails" 1 lefthook run pre-commit
git reset -q src/lib.rs && git checkout -q -- src/lib.rs
echo '# note' > NOTE.md && git add NOTE.md
run "V1d restored, staged harmless change — just typecheck green" 0 just typecheck
run "V1e restored — lefthook run pre-commit green" 0 lefthook run pre-commit
git reset -q NOTE.md && rm -f NOTE.md

echo
echo "# --- V2: both configurations fail differently — default-only warning AND web-only type error"
cat >> src/lib.rs <<'EOF'
#[cfg(not(feature = "web"))]
pub fn offonly() { let unused_off = 1; }
#[cfg(feature = "web")]
pub fn webonly() -> u32 { "x" }
EOF
git add src/lib.rs
run "V2a just typecheck — stops at the first failing line; the all-features error is not shown" 101 just typecheck
run "V2b lefthook run pre-commit — runs both jobs; both failures are shown" 1 lefthook run pre-commit
git reset -q src/lib.rs && git checkout -q -- src/lib.rs

echo
echo "# --- V3: --locked at the pre-commit tier refuses a manifest edit whose lockfile update is missing"
printf '\n[dependencies]\nlocalpath = { path = "localpath" }\n' >> Cargo.toml
mkdir -p localpath/src
printf '[package]\nname = "localpath"\nversion = "0.1.0"\nedition = "2024"\n' > localpath/Cargo.toml
echo 'pub fn h() {}' > localpath/src/lib.rs
git add Cargo.toml localpath
run "V3 Cargo.toml gains a dependency, Cargo.lock not updated — hook fails on --locked" 1 lefthook run pre-commit

echo
echo "# summary: failures=$fails"
exit "$fails"
