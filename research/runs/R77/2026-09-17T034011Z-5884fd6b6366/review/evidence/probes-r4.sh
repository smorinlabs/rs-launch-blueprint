#!/usr/bin/env bash
# shellcheck disable=SC2016
#   File-wide: the expected-output strings asserted below are literals, quoted
#   exactly as the crates print them (they contain `backticks`).
# R77 revision 4 — Rust probes that revision 4 adds or hardens.
#
# Revision 1's probes.sh is NOT edited; it remains the record of what revision 1
# checked. Revision 4's empirical audit found that its P6 group reads
# `$W/c_$n/target/release/c_$n` while an inherited CARGO_TARGET_DIR sends the
# build elsewhere, so a missing binary was measured as 0 bytes (`|| echo 0`) and
# the two "under 50 KB" checks passed on nothing. This script supersedes P6:
#
#   T   the target-directory defect, closed: CARGO_TARGET_DIR is recorded and
#       unset, and every cargo call also passes an explicit --target-dir
#   N   negative control: the size reader FAILs on a binary that does not exist
#   P6r4  package counts and stripped sizes for revision 1's six mechanisms
#       plus config 0.15.26, with build failures and missing or empty binaries
#       reported as FAIL, never as 0 bytes
#   P3r4  config 0.15.26's error string for RSLBP_WEB_PORT=eighty, from the
#       process environment and from an injected map (the test seam)
#   P7  the Muse report's exact loader shape — Environment::with_prefix(..)
#       .separator("_") — against a multi-word field name, beside the
#       revision-1 runner-up shape (no separator)
#
# It writes no Rust file into the repository: every crate is created under a
# directory this script makes with mktemp and removes on exit.
set -euo pipefail

pass=0; fail=0; skip=0
ok()   { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no()   { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk()   { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
assert_has() {
  if printf '%s' "$3" | /usr/bin/grep -qF -- "$2"; then ok "$1"; else
    no "$1"; printf '     expected substring: %s\n     actual: %s\n' "$2" "$3"; fi
}
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}
finish() {
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  [ "$fail" -eq 0 ] || exit 1
  exit 0
}

printf '# R77 probes, revision 4 — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

echo '## T — the inherited target directory is removed before any build'
printf '# inherited CARGO_TARGET_DIR: %s\n' "${CARGO_TARGET_DIR:-<unset>}"
unset CARGO_TARGET_DIR
if [ -z "${CARGO_TARGET_DIR+x}" ]; then ok "T1 CARGO_TARGET_DIR is unset for every cargo call below"
else no "T1 CARGO_TARGET_DIR is still set"; fi

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  sk "N, P6r4, P3r4, P7 — cargo/rustc not on PATH"
  finish
fi
printf '# rustc: %s\n# cargo: %s\n# host: %s\n' \
  "$(rustc --version)" "$(cargo --version)" "$(uname -sm)"

W=$(mktemp -d "${TMPDIR:-/tmp}/r77-probes-r4.XXXXXX")
trap 'rm -rf "$W"' EXIT

# size_of <path>: prints the byte size, or nothing if the file is missing or empty.
size_of() {
  local b=""
  [ -f "$1" ] || return 0
  b=$(stat -f%z "$1" 2>/dev/null || stat -c%s "$1" 2>/dev/null || true)
  [ -n "$b" ] && [ "$b" -gt 0 ] && printf '%s' "$b"
  return 0
}

echo
echo '## N — negative control: a missing binary is a FAIL, never 0 bytes'
missing=$(size_of "$W/does-not-exist/target/release/nothing")
if [ -z "$missing" ]; then ok "N1 size_of reports nothing for a binary that was never built"
else no "N1 size_of returned '$missing' for a nonexistent path"; fi
: > "$W/empty-binary"
empty=$(size_of "$W/empty-binary")
if [ -z "$empty" ]; then ok "N2 size_of reports nothing for a zero-byte file"
else no "N2 size_of returned '$empty' for a zero-byte file"; fi

############################################################################
echo
echo '## P6r4 — package count and stripped release size, build status checked'
COMMON='#[derive(Debug, serde::Deserialize)]
struct S { #[serde(default = "dh")] host: String, #[serde(default = "dp")] port: u16 }
fn dh() -> String { "127.0.0.1".into() }
fn dp() -> u16 { 8000 }'
mkcost() { # $1 name  $2 extra deps  $3 body
  mkdir -p "$W/c_$1/src"
  { printf '[package]\nname = "c_%s"\nversion = "0.0.0"\nedition = "2024"\npublish = false\n' "$1"
    printf '[[bin]]\nname = "c_%s"\npath = "src/main.rs"\n' "$1"
    printf '[dependencies]\nserde = { version = "=1.0.229", features = ["derive"] }\n%s\n' "$2"
    printf '[profile.release]\nstrip = true\nopt-level = "z"\nlto = true\ncodegen-units = 1\npanic = "abort"\n[workspace]\n'
  } > "$W/c_$1/Cargo.toml"
  printf '%s\n' "$3" > "$W/c_$1/src/main.rs"
}
# The six bodies are revision 1's probes.sh P6 bodies, byte for byte; the
# seventh is the fourth with the version pin moved to 0.15.26.
mkcost baseline '' "$COMMON
fn main() {
    let mut s = S { host: dh(), port: dp() };
    for (k, v) in std::env::vars() {
        if let Some(f) = k.strip_prefix(\"RSLBP_WEB_\") {
            match f { \"HOST\" => s.host = v, \"PORT\" => s.port = v.parse().unwrap_or(dp()), _ => {} }
        }
    }
    println!(\"{s:?}\");
}"
mkcost envy 'envy = "=0.4.2"' "$COMMON
fn main() { println!(\"{:?}\", envy::prefixed(\"RSLBP_WEB_\").from_env::<S>()); }"
mkcost confique 'confique = "=0.4.0"' '#[derive(Debug, confique::Config)]
struct S {
    #[config(env = "RSLBP_WEB_HOST", default = "127.0.0.1")] host: String,
    #[config(env = "RSLBP_WEB_PORT", default = 8000)] port: u16,
}
fn main() { println!("{:?}", <S as confique::Config>::builder().env().load()); }'
CONFIG_BODY="$COMMON
fn main() { println!(\"{:?}\", config::Config::builder()
    .add_source(config::Environment::with_prefix(\"RSLBP_WEB\"))
    .build().and_then(|c| c.try_deserialize::<S>())); }"
mkcost confignodefault 'config = { version = "=0.15.25", default-features = false }' "$CONFIG_BODY"
mkcost figment 'figment = { version = "=0.10.19", features = ["env"] }' "$COMMON
fn main() { println!(\"{:?}\", figment::Figment::from(figment::providers::Env::prefixed(\"RSLBP_WEB_\"))
    .extract::<S>()); }"
mkcost configdefault 'config = "=0.15.25"' "$CONFIG_BODY"
mkcost confignodefault26 'config = { version = "=0.15.26", default-features = false }' "$CONFIG_BODY"

names="baseline envy confique confignodefault figment configdefault confignodefault26"
want_pkgs="8 9 12 11 16 55 11"
printf '%-18s %9s %14s\n' mechanism packages stripped_bytes
i=1
declare -a SZ=()
for n in $names; do
  want=$(echo "$want_pkgs" | cut -d' ' -f"$i")
  td="$W/c_$n/target"
  if ! cargo generate-lockfile --quiet --manifest-path "$W/c_$n/Cargo.toml" >"$W/lock_$n.err" 2>&1; then
    no "P6r4 lockfile for $n could not be generated"; sed 's/^/     /' "$W/lock_$n.err"
  fi
  # cargo tree builds nothing, so it takes no --target-dir; its failure is
  # reported rather than counted as zero packages.
  if cargo tree --locked -e normal --prefix none \
       --manifest-path "$W/c_$n/Cargo.toml" >"$W/tree_$n.out" 2>"$W/tree_$n.err"; then
    cnt=$(/usr/bin/sed 's/ (\*)//' "$W/tree_$n.out" | sort -u | /usr/bin/grep -c . || true)
  else
    no "P6r4 cargo tree failed for $n"; sed 's/^/     /' "$W/tree_$n.err"; cnt=""
  fi
  if cargo build --release --quiet --locked --target-dir "$td" \
       --manifest-path "$W/c_$n/Cargo.toml" >"$W/build_$n.err" 2>&1; then
    ok "P6r4 $n builds in release"
  else
    no "P6r4 $n failed to build"; sed 's/^/     /' "$W/build_$n.err"
  fi
  bytes=$(size_of "$td/release/c_$n")
  if [ -n "$bytes" ]; then ok "P6r4 $n produced a non-empty binary at the target directory this script chose"
  else no "P6r4 $n: no binary at $td/release/c_$n — not measured as 0"; bytes=""; fi
  printf '%-18s %9s %14s\n' "$n" "$cnt" "${bytes:-MISSING}"
  assert_eq "P6r4 package count for $n" "$want" "$cnt"
  SZ[i]="$bytes"
  i=$((i+1))
done

delta() { # $1 index; empty if either side is missing
  if [ -n "${SZ[$1]:-}" ] && [ -n "${SZ[1]:-}" ]; then echo $(( SZ[$1] - SZ[1] )); fi
}
gt() { # label delta threshold
  if [ -z "$2" ]; then no "$1 — not measurable (a binary is missing)"; return; fi
  if [ "$2" -gt "$3" ]; then ok "$1 (${2} B > $3)"; else no "$1 (${2} B, expected > $3)"; fi
}
lt() {
  if [ -z "$2" ]; then no "$1 — not measurable (a binary is missing)"; return; fi
  if [ "$2" -lt "$3" ]; then ok "$1 (${2} B < $3)"; else no "$1 (${2} B, expected < $3)"; fi
}
d_envy=$(delta 2); d_confique=$(delta 3); d_config=$(delta 4)
d_figment=$(delta 5); d_configdefault=$(delta 6); d_config26=$(delta 7)
printf 'stripped-size deltas over the baseline: envy=%s confique=%s config-0.15.25-no-default=%s figment=%s config-0.15.25-default=%s config-0.15.26-no-default=%s\n' \
  "$d_envy" "$d_confique" "$d_config" "$d_figment" "$d_configdefault" "$d_config26"
gt "P6r4 config 0.15.25 without default features costs more than 50 KB" "$d_config" 50000
gt "P6r4 figment costs more than 50 KB"                                  "$d_figment" 50000
lt "P6r4 envy costs less than 50 KB"                                      "$d_envy" 50000
lt "P6r4 confique costs less than 50 KB"                                  "$d_confique" 50000
gt "P6r4 config 0.15.25 with default features costs more than 100 KB"   "$d_configdefault" 100000
gt "P6r4 config 0.15.26 without default features costs more than 50 KB" "$d_config26" 50000

############################################################################
echo
echo '## P3r4 and P7 — config 0.15.26: error string, injected seam, separator'
mkdir -p "$W/p7/src"
cat > "$W/p7/Cargo.toml" <<'EOF'
[package]
name = "p7"
version = "0.0.0"
edition = "2024"
publish = false
[dependencies]
serde = { version = "=1.0.229", features = ["derive"] }
config = { version = "=0.15.26", default-features = false }
[workspace]
EOF
cat > "$W/p7/src/main.rs" <<'RS'
#![forbid(unsafe_code)]
#![allow(dead_code)] // the probe only prints its structs through Debug
use std::collections::HashMap;
const WEB_ENV_PREFIX: &str = "RSLBP_WEB_";
#[derive(Debug, serde::Deserialize)]
struct Two { #[serde(default = "dh")] host: String, #[serde(default = "dp")] port: u16 }
fn dh() -> String { "127.0.0.1".into() }
fn dp() -> u16 { 8000 }
#[derive(Debug, serde::Deserialize)]
struct Multi { #[serde(default = "dp")] port: u16,
               #[serde(default = "dg")] graceful_shutdown_seconds: u64 }
fn dg() -> u64 { 8 }
fn map(pairs: &[(&str, &str)]) -> HashMap<String, String> {
    pairs.iter().map(|(k, v)| (k.to_string(), v.to_string())).collect()
}
fn load<T: serde::de::DeserializeOwned + std::fmt::Debug>(env: config::Environment) -> String {
    match config::Config::builder().add_source(env).build().and_then(|c| c.try_deserialize::<T>()) {
        Ok(v) => format!("OK | {v:?}"), Err(e) => format!("ERR | {e}"),
    }
}
fn main() {
    let mode = std::env::args().nth(1).unwrap_or_default();
    println!("process RSLBP_WEB_PORT={:?}", std::env::var("RSLBP_WEB_PORT").ok());
    if mode == "process" {
        // P3r4 run 1: the runner-up shape reading the real process environment.
        println!("p3-process | {}", load::<Two>(
            config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_'))));
        return;
    }
    // P3r4 run 2: the process environment is clean; only the injected map has it.
    let bad = map(&[("RSLBP_WEB_HOST", "127.0.0.1"), ("RSLBP_WEB_PORT", "eighty")]);
    println!("p3-injected | {}", load::<Two>(
        config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_')).source(Some(bad))));
    // P7: one multi-word field, set to a non-default value.
    let good = map(&[("RSLBP_WEB_PORT", "9000"), ("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", "3")]);
    println!("p7-runner-up-shape | {}", load::<Multi>(
        config::Environment::with_prefix("RSLBP_WEB").source(Some(good.clone()))));
    println!("p7-muse-shape | {}", load::<Multi>(
        config::Environment::with_prefix("RSLBP_WEB").separator("_").source(Some(good.clone()))));
    println!("p7-trailing-underscore | {}", load::<Multi>(
        config::Environment::with_prefix("RSLBP_WEB_").source(Some(good))));
}
RS
if cargo build --quiet --target-dir "$W/p7/target" --manifest-path "$W/p7/Cargo.toml" >"$W/p7.err" 2>&1; then
  ok "P7 probe crate builds against config 0.15.26"
else
  no "P7 probe crate failed to build"; sed 's/^/     /' "$W/p7.err"
fi
p3a=$(env RSLBP_WEB_HOST=127.0.0.1 RSLBP_WEB_PORT=eighty \
      cargo run --quiet --target-dir "$W/p7/target" --manifest-path "$W/p7/Cargo.toml" -- process 2>&1 || true)
p7=$(env -u RSLBP_WEB_HOST -u RSLBP_WEB_PORT -u RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS \
      cargo run --quiet --target-dir "$W/p7/target" --manifest-path "$W/p7/Cargo.toml" 2>&1 || true)
printf '%s\n%s\n' "$p3a" "$p7"
assert_has "P3r4.1 config 0.15.26 prints revision 1's 0.15.25 string verbatim, from the process environment" \
  'p3-process | ERR | invalid type: string "eighty", expected an integer for key `port` in the environment' "$p3a"
assert_has "P3r4.2 the process environment is clean for the injected run" 'process RSLBP_WEB_PORT=None' "$p7"
assert_has "P3r4.3 config 0.15.26 reports the same error from the injected map alone (the seam holds)" \
  'p3-injected | ERR | invalid type: string "eighty", expected an integer for key `port` in the environment' "$p7"
assert_has "P7.1 runner-up shape (no separator) reads the multi-word field" \
  'p7-runner-up-shape | OK | Multi { port: 9000, graceful_shutdown_seconds: 3 }' "$p7"
assert_has "P7.2 Muse's .separator(\"_\") shape silently drops the multi-word field to its default" \
  'p7-muse-shape | OK | Multi { port: 9000, graceful_shutdown_seconds: 8 }' "$p7"
assert_has "P7.3 a prefix passed with its trailing underscore matches nothing (Muse's own observation)" \
  'p7-trailing-underscore | OK | Multi { port: 8000, graceful_shutdown_seconds: 8 }' "$p7"

finish
