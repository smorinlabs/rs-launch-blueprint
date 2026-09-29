#!/usr/bin/env bash
# R84 revision 1 — executed probe of the Rust-native incumbent, progenitor
# 0.15.0, through its recipe-shaped mode (`cargo progenitor`, the static-crate
# generator), against the same OpenAPI 3.1.0 fixture the pick was probed on,
# plus two derived variants: the fixture relabelled 3.0.3, and that 3.0.3
# document with every operationId removed.
#
#   P01  the installed cargo-progenitor reports 0.15.0
#   P02  the real 3.1.0 fixture: rejected while parsing (3.1 type arrays)
#   P02b 3.0 syntax labelled 3.1.0: rejected by the version check
#   P03  3.0.3 input on this stable toolchain: panics in rustfmt configuration
#   P04  that panic leaves a Cargo.toml and no Rust source
#   P05  3.0.3 input without operationIds: rejected, naming the missing id
#
# Reproducibility: no timestamp, PID or temporary path is printed; the
# thread-id in Rust's panic line is masked. Cache: $R84_CACHE, default
# ${TMPDIR:-/tmp}/r84-synth-cache (tool binary and a private CARGO_HOME).

set -uo pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
check() { local label=$1; shift; if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; fi; }
summary() { echo; echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"; exit "$FAIL"; }

HERE=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
FIXTURE="$HERE/fixtures/api-3.1.json"
CACHE=${R84_CACHE:-${TMPDIR:-/tmp}/r84-synth-cache}
mkdir -p "$CACHE/cargo-home"
export CARGO_HOME="$CACHE/cargo-home"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/r84-prog.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "R84 progenitor probe (revision 1)"
echo "grep: $($GREP --version | head -1)"
echo "fixture: fixtures/api-3.1.json, sha256 $(shasum -a 256 "$FIXTURE" | cut -d' ' -f1)"
echo "rustc: $(rustc --version 2>/dev/null || echo absent)"
echo "rustfmt: $(rustfmt --version 2>/dev/null || echo absent)"
echo

for t in cargo jq; do
  command -v "$t" >/dev/null 2>&1 || { skip "S0 required tool '$t' is absent"; summary; }
done

BIN="$CACHE/progenitor/bin/cargo-progenitor"
if [ ! -x "$BIN" ]; then
  cargo install --locked --quiet --root "$CACHE/progenitor" cargo-progenitor --version 0.15.0 >/dev/null 2>&1
fi
[ -x "$BIN" ] || { skip "S1 cargo-progenitor 0.15.0 could not be installed"; summary; }
export PATH="$CACHE/progenitor/bin:$PATH"

# `cargo progenitor --version` takes a value (the generated crate's version),
# so the installed version is read from cargo install's own record.
check "P01 cargo install's record names cargo-progenitor 0.15.0 from crates.io" \
  $GREP -qF '"cargo-progenitor 0.15.0 (registry+https://github.com/rust-lang/crates.io-index)"' "$CACHE/progenitor/.crates.toml"

gen() { # gen <spec> <outdir> -> prints masked stdout+stderr, returns exit status
  cargo progenitor -i "$1" -o "$2" -n rslbp-client -v 0.1.0 --license-name "MIT OR Apache-2.0" 2>&1 \
    | sed -E 's/thread .main. \([0-9]+\)/thread main (<id>)/; s#/[^ ]*/(cargo-progenitor-0\.15\.0/)#<registry>/\1#g'
  return "${PIPESTATUS[0]}"
}

OUT31=$(gen "$FIXTURE" "$WORK/o31"); rc31=$?
while IFS= read -r l; do echo "      $l"; done <<<"$OUT31"
check "P02 the real 3.1.0 fixture is refused (exit $rc31) while parsing: a 3.1 type array is 'invalid type: sequence, expected a string'" \
  bash -c "test $rc31 != 0 && $GREP -qF 'invalid type: sequence, expected a string' <<<\"\$1\"" _ "$OUT31"

jq '.openapi = "3.0.3" | .components.schemas.Project.properties.description = {"type":"string","nullable":true} | .components.schemas.ProjectPage.properties.next_cursor = {"type":"string","nullable":true} | del(.info.license.identifier)' \
  "$FIXTURE" > "$WORK/api-3.0.json"
OUT30=$(gen "$WORK/api-3.0.json" "$WORK/o30"); rc30=$?
while IFS= read -r l; do echo "      $l"; done <<<"$OUT30"
check "P03 on a 3.0.3 document the stable toolchain panics (exit $rc30) on Unstable(\"wrap_comments, normalize_doc_attributes\")" \
  bash -c "test $rc30 = 101 && $GREP -qF 'Unstable(\"wrap_comments, normalize_doc_attributes\")' <<<\"\$1\"" _ "$OUT30"
jq '.openapi = "3.1.0"' "$WORK/api-3.0.json" > "$WORK/api-3.1-label-only.json"
OUTL=$(gen "$WORK/api-3.1-label-only.json" "$WORK/ol"); rcl=$?
while IFS= read -r l; do echo "      $l"; done <<<"$OUTL"
check "P02b the same document with 3.0 syntax but labelled 3.1.0 is refused (exit $rcl) with UnexpectedFormat(\"invalid version: 3.1.0\")" \
  bash -c "test $rcl != 0 && $GREP -qF 'UnexpectedFormat(\"invalid version: 3.1.0\")' <<<\"\$1\"" _ "$OUTL"
RS=$(find "$WORK/o30" -name '*.rs' 2>/dev/null | wc -l | tr -d ' ')
check "P04 the panic leaves Cargo.toml and $RS Rust source files" \
  bash -c "test -f '$WORK/o30/Cargo.toml' && test '$RS' = 0"

jq 'del(.paths[][].operationId)' "$WORK/api-3.0.json" > "$WORK/api-3.0-noopid.json"
OUTN=$(gen "$WORK/api-3.0-noopid.json" "$WORK/on"); rcn=$?
while IFS= read -r l; do echo "      $l"; done <<<"$OUTN"
check "P05 without operationIds a 3.0.3 document is refused (exit $rcn) with 'is missing operation ID'" \
  bash -c "test $rcn != 0 && $GREP -qF 'is missing operation ID' <<<\"\$1\"" _ "$OUTN"

summary
