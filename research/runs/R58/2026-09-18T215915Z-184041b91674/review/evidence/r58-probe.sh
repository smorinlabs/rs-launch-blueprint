#!/usr/bin/env bash
# R58 empirical check A - behaviour of tracing-subscriber 0.3.23's formatter and
# installation seams, executed against a throwaway Cargo probe.
#
# The probe is built under a directory this script creates inside $TMPDIR and
# deletes on exit, so no target/ tree and no nested git repository is ever
# written into this repository. probe/main.rs and probe/Cargo.toml.in are the
# committed inputs; nothing here builds any part of the recommended template.
set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0; FAIL=0; SKIP=0

ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }

# assert_has <label> <file> <fixed-string>
assert_has() {
  if "$GREP" -qF -- "$3" "$2"; then ok "$1"; else bad "$1 (expected to find: $3)"; fi
}
# assert_lacks <label> <file> <fixed-string>
assert_lacks() {
  if "$GREP" -qF -- "$3" "$2"; then bad "$1 (should NOT contain: $3)"; else ok "$1"; fi
}

echo "== toolchain =="
rustc --version
cargo --version
uname -sm
echo "$GREP version: $("$GREP" --version | head -1)"
echo

if ! command -v cargo > /dev/null 2>&1; then
  skip "cargo not installed - every probe scenario skipped"
  echo; echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"
  [ "$FAIL" -eq 0 ] || exit 1
  exit 0
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r58probe.XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
mkdir -p "$WORK/src"
cp "$HERE/probe/Cargo.toml.in" "$WORK/Cargo.toml"
cp "$HERE/probe/main.rs" "$WORK/src/main.rs"

echo "== build =="
if ! ( cd "$WORK" && cargo build --quiet ); then
  bad "probe builds on this toolchain"
  echo; echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"
  exit 1
fi
ok "probe builds on this toolchain (tracing 0.1.44 + tracing-subscriber 0.3.23, edition 2024, rust-version 1.96)"
BIN="$WORK/target/debug/r58probe"
OUT="$WORK/out"; mkdir -p "$OUT"
run() { "$BIN" "$1" > "$OUT/$1.stdout" 2> "$OUT/$1.stderr"; }

echo
echo "== S1  stock Format<Json> vs a redacting FormatFields =="
run json-stock-leak
cat "$OUT/json-stock-leak.stdout"
assert_has   "S1a stock .json() leaks the event field 'token' in clear" \
             "$OUT/json-stock-leak.stdout" '"token":"sk_live_EVENTSECRET"'
assert_has   "S1b stock .json() leaks the event field 'password' in clear" \
             "$OUT/json-stock-leak.stdout" '"password":"hunter2"'
assert_has   "S1c the SPAN field IS redacted by the same FormatFields" \
             "$OUT/json-stock-leak.stdout" '"api_key":"[REDACTED]"'

echo
echo "== S2  template-owned FormatEvent + FormatFields =="
run json-owned
cat "$OUT/json-owned.stdout"
assert_has   "S2a owned formatter redacts the event field 'token'" \
             "$OUT/json-owned.stdout" '"token":"[REDACTED]"'
assert_has   "S2b owned formatter redacts the event field 'password'" \
             "$OUT/json-owned.stdout" '"password":"[REDACTED]"'
assert_has   "S2c owned formatter redacts the span field 'api_key'" \
             "$OUT/json-owned.stdout" '"span":{"request_id":"abc-123","api_key":"[REDACTED]"}'
assert_lacks "S2d no secret byte survives on the owned structured profile" \
             "$OUT/json-owned.stdout" 'sk_live_'

echo
echo "== S3  human profile, DefaultFields wrapper =="
run human-redact
cat "$OUT/human-redact.stdout"
assert_has   "S3a human profile redacts the span field" \
             "$OUT/human-redact.stdout" 'api_key="[REDACTED]"'
assert_has   "S3b human profile redacts the event field 'token'" \
             "$OUT/human-redact.stdout" 'token="[REDACTED]"'
assert_lacks "S3c no secret byte survives on the human profile" \
             "$OUT/human-redact.stdout" 'sk_live_'

echo
echo "== S4  the global dispatcher installs once =="
run second-init
cat "$OUT/second-init.stdout"
assert_has   "S4a the first try_init() succeeds" "$OUT/second-init.stdout" 'FIRST_IS_OK=true'
assert_has   "S4b the second try_init() is Err, not a panic and not a takeover" \
             "$OUT/second-init.stdout" 'SECOND_IS_ERR=true'

echo
echo "== S5  reload::Layer swaps the filter after installation =="
run reload
cat "$OUT/reload.stdout"
assert_lacks "S5a an info! before the swap is filtered out by EnvFilter(warn)" \
             "$OUT/reload.stdout" 'BEFORE-SWAP-INFO'
assert_has   "S5b an info! after the swap renders" "$OUT/reload.stdout" 'AFTER-SWAP-INFO'
assert_has   "S5c a debug! after the swap renders" "$OUT/reload.stdout" 'AFTER-SWAP-DEBUG'

echo
echo "== S6  the log bridge is installed by try_init with no explicit call =="
run logbridge
cat "$OUT/logbridge.stderr"
assert_has   "S6a a log::info! reaches the fmt layer with no LogTracer call" \
             "$OUT/logbridge.stderr" 'S6:LOG-CRATE-RECORD'
assert_has   "S6b a tracing::info! reaches the same layer" \
             "$OUT/logbridge.stderr" 'S6:TRACING-RECORD'

echo
echo "== S7  a secrecy::SecretString never renders its value =="
run secrecy
cat "$OUT/secrecy.stdout"
assert_has   "S7a SecretString renders as SecretBox<str>([REDACTED])" \
             "$OUT/secrecy.stdout" 'secret_value=SecretBox<str>([REDACTED])'
assert_lacks "S7b the secret's plaintext never appears" "$OUT/secrecy.stdout" 'sk_live_TOPSECRET'

echo
echo "== S8  RUSTSEC-2025-0055: control bytes are escaped, not emitted raw =="
run ansi-escape
cat "$OUT/ansi-escape.stdout"
assert_has   "S8a no raw ESC (0x1b) byte reaches the sink" \
             "$OUT/ansi-escape.stdout" 'RAW_ESC_PRESENT=false'
assert_has   "S8b no raw BEL (0x07) byte reaches the sink" \
             "$OUT/ansi-escape.stdout" 'RAW_BEL_PRESENT=false'
assert_has   "S8c the escape is printed in Rust escape notation" \
             "$OUT/ansi-escape.stdout" 'untrusted="\u{1b}[31mRED\u{1b}[0m\u{7}"'

echo
echo "== S9  a log::Record carries no field keys to redact =="
run log-facade-fields
cat "$OUT/log-facade-fields.stdout"
assert_has   "S9a a secret inside a log::Record's message survives in clear" \
             "$OUT/log-facade-fields.stdout" 'connecting token=sk_live_LOGFACADE password=hunter2'
assert_has   "S9b the same key on a tracing::Event IS redacted" \
             "$OUT/log-facade-fields.stdout" 'token="[REDACTED]"'

echo
echo "== S10 the residual gap in key-based masking (grounds OV-09) =="
run redaction-gap
cat "$OUT/redaction-gap.stdout"
assert_has   "S10a a secret under a SENSITIVE key is masked" \
             "$OUT/redaction-gap.stdout" 'KEYED_SECRET_MASKED=true'
assert_has   "S10b a secret inside a NON-sensitive key's value is NOT masked" \
             "$OUT/redaction-gap.stdout" 'IN_VALUE_SECRET_MASKED=false'

echo
echo "== S11 dependency-graph size per manifest (gate 6) =="
tree_count() { # $1 = label, $2 = dependency block
  d="$WORK/tree_$1"; mkdir -p "$d/src"; echo 'fn main(){}' > "$d/src/main.rs"
  { echo '[package]'; echo "name = \"t_$1\""; echo 'version = "0.0.0"';
    echo 'edition = "2024"'; echo 'rust-version = "1.96"'; echo 'publish = false';
    echo; echo '[dependencies]'; echo "$2"; echo; echo '[workspace]'; } > "$d/Cargo.toml"
  ( cd "$d" && cargo tree -e normal --prefix none --quiet ) \
    | sed 's/ (\*)$//' | sort -u | "$GREP" -vc "^t_$1 " || true
}
CORE=$(tree_count core 'tracing = { version = "0.1.44", default-features = false, features = ["std"] }')
FACADE=$(tree_count facade 'tracing = "0.1.44"')
ROOT=$(tree_count root 'tracing = "0.1.44"
tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }
serde_json = "1"')
ROOTJSON=$(tree_count rootjson 'tracing = "0.1.44"
tracing-subscriber = { version = "0.3.23", features = ["env-filter", "json"] }
serde_json = "1"')
echo "core=$CORE facade=$FACADE root=$ROOT root_with_json=$ROOTJSON"
expect_count() { # $1 = label, $2 = observed, $3 = expected
  if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected $3, observed $2)"; fi
}
expect_count "S11a crates/core line resolves to 4 crates"        "$CORE"     4
expect_count "S11b tracing default features resolve to 9 crates" "$FACADE"   9
expect_count "S11c recommended root line resolves to 26 crates"  "$ROOT"     26
expect_count "S11d the json feature adds exactly 2 crates"       "$ROOTJSON" 28

echo
echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"
[ "$FAIL" -eq 0 ] || exit 1
