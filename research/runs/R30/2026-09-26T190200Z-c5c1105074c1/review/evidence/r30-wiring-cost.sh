#!/usr/bin/env bash
# R30 check H — wiring and cost of the recommended gate, end to end with the real tools:
#   * the `typecheck` Justfile recipe run by `just`, and the same commands as lefthook
#     pre-commit jobs run by `lefthook run pre-commit`, plus a CI-step fixture;
#   * that the three places carry byte-identical cargo commands (the identity invariant);
#   * cold / no-op / incremental wall-clock of the gate on a synthetic 4-member workspace
#     (facade, core, cli, web — R02's accepted shape) with 24 generated path "dependency"
#     crates outside the workspace; NOT the template and NOT its real dependency tree;
#   * what `cargo clippy` re-checks after the gate, and that clippy reports type errors.
# Zero registry dependencies. Scratch directory outside the repository.
# Usage: bash r30-wiring-cost.sh > r30-wiring-cost.log 2>&1
set -uo pipefail

export CARGO_TERM_COLOR=never
unset RUSTFLAGS CARGO_BUILD_WARNINGS CARGO_ENCODED_RUSTFLAGS

echo "# r30-wiring-cost.sh  run $(date -u +%Y-%m-%dT%H:%M:%SZ)  host $(uname -sm)  cpus $(sysctl -n hw.ncpu 2>/dev/null || nproc)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
echo "# stable: $(cargo --version) / $(rustc --version) / $(cargo clippy --version)"
echo "# just $(just --version | cut -d' ' -f2)  lefthook $(lefthook version)  git $(git --version | cut -d' ' -f3)"

ROOT=$(mktemp -d "${TMPDIR:-/tmp}/r30-wiring.XXXXXX")
ROOT=$(cd "$ROOT" && pwd -P)
WS="$ROOT/proj"
export CARGO_TARGET_DIR="$WS/target"
echo "# CARGO_TARGET_DIR=<ws>/target"
trap 'rm -rf "$ROOT"' EXIT

fails=0
# run LABEL EXPECTED_EXIT CMD... — prints command, diagnostics, re-checked unit count, wall-clock
run() {
  local label=$1 want=$2; shift 2
  local out rc t0 t1
  t0=$EPOCHREALTIME
  out=$("$@" 2>&1); rc=$?
  t1=$EPOCHREALTIME
  echo
  echo "== $label"
  echo "\$ $*"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|warnings are denied|^ *(Checking|Finished) |^ *-->|typecheck|EXECUTE|✔️|🥊|summary' \
    | grep -Ev '^ *Checking (dep[0-9]+) ' | sed -e 's#'"$ROOT"'#<root>#g' -e 's/\x1b\[[0-9;]*m//g'
  echo "units re-checked: $(printf '%s\n' "$out" | grep -c '^ *Checking ')  wall-clock: $(awk -v a="$t0" -v b="$t1" 'BEGIN{printf "%.2f s", b-a}')"
  if [[ $rc == "$want" ]]; then echo "exit=$rc (expected $want) PASS"; else echo "exit=$rc (expected $want) FAIL"; fails=$((fails+1)); fi
}

# ---- 24 generated dependency crates, outside the workspace (stand-ins for registry crates)
NDEPS=24
for i in $(seq 1 "$NDEPS"); do
  d="$ROOT/vendor/dep$i"; mkdir -p "$d/src"
  printf '[package]\nname = "dep%s"\nversion = "0.1.0"\nedition = "2024"\n' "$i" > "$d/Cargo.toml"
  if (( i > 1 )); then printf '\n[dependencies]\ndep%s = { path = "../dep%s" }\n' "$((i-1))" "$((i-1))" >> "$d/Cargo.toml"; fi
  {
    echo "pub trait Shape$i { fn area(&self) -> f64; fn name(&self) -> String { format!(\"s{}\", self.area()) } }"
    for j in $(seq 1 120); do
      echo "#[derive(Debug, Clone, PartialEq)] pub struct S${j}<T: Clone> { pub a: T, pub b: Vec<T>, pub c: Option<Box<T>> }"
      echo "impl<T: Clone + Into<f64>> Shape$i for S${j}<T> { fn area(&self) -> f64 { self.a.clone().into() * ${j}.0 + self.b.len() as f64 } }"
      echo "pub fn f${j}<T: Clone + Into<f64>>(s: &S${j}<T>) -> f64 { s.area() + s.b.iter().cloned().map(Into::into).sum::<f64>() }"
    done
  } > "$d/src/lib.rs"
done

# ---- the workspace: root facade + crates/core, crates/cli, crates/web; web is an off-by-default feature
mkdir -p "$WS/src" "$WS/tests" "$WS/crates/core/src" "$WS/crates/cli/src" "$WS/crates/web/src"
cd "$WS" || exit 1
cat > Cargo.toml <<EOF
[package]
name = "facade"
version = "0.1.0"
edition = "2024"

[features]
web = ["dep:web"]

[dependencies]
core = { path = "crates/core", package = "app-core" }
web = { path = "crates/web", package = "app-web", optional = true }

[lints]
workspace = true

[workspace]
members = ["crates/core", "crates/cli", "crates/web"]

[workspace.lints.rust]
rust_2018_idioms = { level = "warn", priority = -1 }
EOF
for m in core cli web; do
  printf '[package]\nname = "app-%s"\nversion = "0.1.0"\nedition = "2024"\n\n[lints]\nworkspace = true\n\n[dependencies]\n' "$m" > "crates/$m/Cargo.toml"
done
printf 'dep%s = { path = "../../../vendor/dep%s" }\n' "$NDEPS" "$NDEPS" >> crates/core/Cargo.toml
printf 'app-core = { path = "../core" }\n' >> crates/cli/Cargo.toml
printf 'app-core = { path = "../core" }\n' >> crates/web/Cargo.toml
cat > crates/core/src/lib.rs <<EOF
pub fn area() -> f64 { dep$NDEPS::f1(&dep$NDEPS::S1 { a: 1.0_f64, b: vec![2.0], c: None }) }
#[cfg(test)]
mod tests { #[test] fn t() { assert!(super::area() > 0.0); } }
EOF
echo 'pub fn run() -> f64 { app_core::area() }' > crates/cli/src/lib.rs
echo 'pub fn route() -> f64 { app_core::area() * 2.0 }' > crates/web/src/lib.rs
cat > src/lib.rs <<'EOF'
pub use core::area;
#[cfg(feature = "web")]
pub fn route() -> f64 { web::route() }
EOF
echo '#[test] fn it() { assert!(facade::area() > 0.0); }' > tests/it.rs
echo '# probe' > README.md
cargo generate-lockfile --offline >/dev/null 2>&1

# ---- the three places the gate lives: recipe, hook, CI step. One pair of commands, written once here.
CMD_OFF='cargo check --workspace --all-targets --locked --keep-going'
CMD_ALL='cargo check --workspace --all-targets --all-features --locked --keep-going'
cat > Justfile <<EOF
# Type-check every target in both feature configurations; lint warnings from workspace packages fail
[group('dev')]
typecheck:
    CARGO_BUILD_WARNINGS=deny $CMD_OFF
    CARGO_BUILD_WARNINGS=deny $CMD_ALL

alias tc := typecheck
EOF
cat > lefthook.yml <<EOF
pre-commit:
  jobs:
    - name: typecheck (default features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: $CMD_OFF
    - name: typecheck (all features)
      env:
        CARGO_BUILD_WARNINGS: deny
      run: $CMD_ALL
EOF
cat > ci-steps.yml <<EOF
      - name: typecheck (default features)
        if: \${{ !cancelled() }}
        env:
          CARGO_BUILD_WARNINGS: deny
        run: $CMD_OFF
      - name: typecheck (all features)
        if: \${{ !cancelled() }}
        env:
          CARGO_BUILD_WARNINGS: deny
        run: $CMD_ALL
EOF
git init -q . && git add -A && git -c user.email=probe@example.invalid -c user.name=probe commit -qm init

echo
echo "# --- H1: identity invariant — the cargo commands in Justfile, lefthook.yml and the CI steps are byte-identical"
extract() { grep -o 'cargo check .*' "$1"; }
run "H1a Justfile vs lefthook.yml" 0 diff <(extract Justfile) <(extract lefthook.yml)
run "H1b Justfile vs CI steps" 0 diff <(extract Justfile) <(extract ci-steps.yml)
run "H1c the check detects drift (a hook job missing --all-targets)" 1 diff <(extract Justfile) <(sed 's/ --all-targets//' lefthook.yml | grep -o 'cargo check .*')

echo
echo "# --- H2: cost on this host (macOS arm64); synthetic workspace, 24 generated dependency crates"
run "H2a cold: just typecheck (both configurations)" 0 just typecheck
run "H2b warm no-op: just typecheck" 0 just typecheck
run "H2c warm no-op again: just typecheck" 0 just typecheck
echo 'pub fn extra() -> u32 { 1 }' >> crates/core/src/lib.rs
run "H2d after editing crates/core (every workspace member depends on it)" 0 just typecheck
echo 'pub fn extra() -> u32 { 2 }' >> crates/web/src/lib.rs
run "H2e after editing crates/web" 0 just typecheck
echo 'pub fn extra2() -> u32 { 1 }' >> crates/core/src/lib.rs
run "H2f after a second crates/core edit" 0 just typecheck

echo
echo "# --- H3: the gate through lefthook's pre-commit tier"
# lefthook 2.x skips a job when nothing is staged ("no matching staged files"), even a job with no
# glob, so every case stages its change first — as a real commit always does.
git add -A && git -c user.email=probe@example.invalid -c user.name=probe commit -qm "H2 edits" --no-verify
run "H3a nothing staged — both jobs skip (lefthook 2.x behaviour)" 0 lefthook run pre-commit
echo '# note' >> README.md && git add README.md
run "H3b a harmless staged change, clean tree — both jobs run, green" 0 lefthook run pre-commit
printf 'pub fn _bad() -> u32 { "x" }\n' >> crates/cli/src/lib.rs && git add crates/cli/src/lib.rs
run "H3c E0308 staged in crates/cli — the hook fails" 1 lefthook run pre-commit
git reset -q crates/cli/src/lib.rs && git checkout -q -- crates/cli/src/lib.rs
printf '#[cfg(feature = "web")]\npub fn _bad2() -> u32 { "x" }\n' >> src/lib.rs && git add src/lib.rs
run "H3d E0308 staged behind the web feature — the all-features job fails" 1 lefthook run pre-commit
run "H3e the same through a real commit with the hook installed — commit refused" 1 bash -c 'lefthook install >/dev/null && git -c user.email=probe@example.invalid -c user.name=probe commit -qm bad'
echo "HEAD subject after H3e (must still be the H2 commit): $(git log -1 --format=%s)"
git reset -q src/lib.rs && git checkout -q -- src/lib.rs
run "H3f green again after restoring — commit accepted through the hook" 0 git -c user.email=probe@example.invalid -c user.name=probe commit -qm "readme note"
echo "HEAD subject after H3f: $(git log -1 --format=%s)"

echo
echo "# --- H4: clippy after the gate, same flags; and clippy's own type-error reporting"
run "H4a cargo clippy --all-features after the gate — re-checks workspace members only, no dependency" 0 cargo clippy --workspace --all-targets --all-features --locked
printf 'pub fn _bad() -> u32 { "x" }\n' >> crates/cli/src/lib.rs
run "H4b cargo clippy reports a type error as error[E0308]" 101 cargo clippy --workspace --all-targets --locked
git checkout -q -- crates/cli/src/lib.rs

echo
echo "# --- H5: size of what was checked"
echo "workspace members: 4; generated dependency crates: $NDEPS; generated dependency source lines: $(cat "$ROOT"/vendor/dep*/src/lib.rs | wc -l | tr -d ' ')"
echo "target dir size: $(du -sh "$CARGO_TARGET_DIR" | cut -f1)"

echo
echo "# summary: failures=$fails"
exit "$fails"
