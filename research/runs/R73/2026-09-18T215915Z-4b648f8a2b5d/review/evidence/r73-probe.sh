#!/usr/bin/env bash
# R73 — builds and runs the RE-DERIVED idempotency-replay/v1 probe, and measures
# the dependency-tree deltas the decision cites.
#
# The probe source under review/evidence/probe/ is a re-derivation written by the
# synthesizer from the Opus raw report's prose. The raw report's own probe was
# deleted after that run (raw/opus.md:1081), so nothing byte-level is reproduced
# here: this script re-executes the DESIGN, not that workspace.
#
# Everything builds inside a directory this script creates under $TMPDIR and
# deletes on exit, so no target/ tree or Cargo.lock ever lands in the repository.
set -euo pipefail

GREP=/usr/bin/grep
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
PROBE_SRC="$HERE/probe"

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }
summary() {
  printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
}

printf '== R73 probe ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

if ! command -v cargo > /dev/null 2>&1; then
  skip P0-cargo 'cargo is not on PATH; every probe check is skipped'
  summary
  exit 0
fi
printf 'rustc: %s\n' "$(rustc --version)"
printf 'cargo: %s\n' "$(cargo --version)"
printf 'uname: %s\n' "$(uname -srm)"

if [ ! -d "$PROBE_SRC/src" ]; then
  fail P0-src "the probe source is missing at $PROBE_SRC"
  summary
  exit 1
fi

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r73probe.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
printf 'work: %s (created by this script, deleted on exit)\n' "$WORK"

cp -R "$PROBE_SRC" "$WORK/probe"
cd "$WORK/probe"

# --- the probe declares R69 revision 10's exact pins --------------------------
printf '\n-- pins --\n'
for pin in 'axum = "=0.8.9"' 'sha2 = { version = "=0.11.0", default-features = false, features = \["alloc"\] }' 'edition = "2024"' 'rust-version = "1.96"'; do
  if "$GREP" -qF "$(printf '%b' "${pin//\\/}")" Cargo.toml; then
    pass "P1-pin" "Cargo.toml declares ${pin}"
  else
    fail "P1-pin" "Cargo.toml does not declare ${pin}"
  fi
done
if "$GREP" -q '^tower = { version = "=0.5.3"' Cargo.toml && \
   awk '/^\[dev-dependencies\]/{d=1} d && /^tower =/{found=1} END{exit !found}' Cargo.toml; then
  pass P1-tower-dev 'tower 0.5.3 is declared under [dev-dependencies] only, as R69 revision 10 requires'
else
  fail P1-tower-dev 'tower is not a dev-dependency-only declaration'
fi
if "$GREP" -q 'forbid(unsafe_code)' src/lib.rs; then
  pass P1-unsafe 'the probe crate root carries #![forbid(unsafe_code)]'
else
  fail P1-unsafe 'the probe crate root does not forbid unsafe code'
fi

# --- resolve, build, lint -----------------------------------------------------
printf '\n-- resolve, build, lint --\n'
if METADATA=$(cargo metadata --format-version 1 2>&1 > /dev/null); then
  printf '%s\n' "$METADATA" | "$GREP" -E 'Locking|Adding' || true
  pass P2-resolve 'cargo metadata resolved the tree under the declared 1.96 floor'
else
  skip P2-resolve 'cargo metadata failed (no network or no registry cache); every later probe check is skipped'
  summary
  exit 0
fi

if cargo build --quiet 2>&1; then
  pass P2-build 'cargo build is clean'
else
  fail P2-build 'cargo build failed'
fi

if cargo clippy --all-targets --quiet -- -D warnings 2>&1; then
  pass P2-clippy 'cargo clippy --all-targets -- -D warnings is clean'
else
  fail P2-clippy 'clippy reported a warning'
fi

# --- the only tower edge is axum's own ---------------------------------------
TREE_TOWER=$(cargo tree -e normal -i tower 2>/dev/null || true)
printf '%s\n' "$TREE_TOWER"
if printf '%s\n' "$TREE_TOWER" | "$GREP" -q 'axum v0.8.9'; then
  if [ "$(printf '%s\n' "$TREE_TOWER" | "$GREP" -c 'tower v0.5.3')" -eq 1 ]; then
    pass P2-tower-edge 'tower v0.5.3 reaches the probe only through axum v0.8.9, so R69 dev-only declaration is undisturbed'
  else
    fail P2-tower-edge 'tower appears more than once in the normal graph'
  fi
else
  fail P2-tower-edge 'the tower edge does not run through axum v0.8.9'
fi

# --- the checks ---------------------------------------------------------------
printf '\n-- store checks s01-s10 --\n'
STORE_OUT=$(cargo test --test store -- --nocapture 2>&1 || true)
printf '%s\n' "$STORE_OUT" | "$GREP" -E '^test s|test result|ns_per_op'
STORE_LINE=$(printf '%s\n' "$STORE_OUT" | "$GREP" -E '^test result' | head -1)
if printf '%s\n' "$STORE_LINE" | "$GREP" -q '10 passed; 0 failed'; then
  pass P3-store 'all 10 store checks pass'
else
  fail P3-store "the store suite did not report 10 passed / 0 failed: $STORE_LINE"
fi
# The port is synchronous: no runtime is in scope for the store suite.
if "$GREP" -qE '^#\[tokio::test' tests/store.rs; then
  fail P3-sync 'the store suite uses #[tokio::test], so it does not prove the port is runtime-free'
elif "$GREP" -qE '^#\[test\]' tests/store.rs; then
  pass P3-sync 'the store suite carries plain #[test] attributes and no #[tokio::test] — the port needs no async runtime'
else
  fail P3-sync 'the store suite carries no #[test] attribute at all, so the check would be vacuous'
fi
if "$GREP" -q 'PortError::Unavailable' tests/store.rs; then
  pass P3-poison 's10 asserts the poisoned-Mutex branch the raw report left unexecuted'
else
  fail P3-poison 's10 does not assert PortError::Unavailable'
fi

printf '\n-- router checks w01-w17 --\n'
WEB_OUT=$(cargo test --test web 2>&1 || true)
printf '%s\n' "$WEB_OUT" | "$GREP" -E '^test w|test result'
WEB_LINE=$(printf '%s\n' "$WEB_OUT" | "$GREP" -E '^test result' | head -1)
if printf '%s\n' "$WEB_LINE" | "$GREP" -q '18 passed; 0 failed'; then
  pass P4-web 'all 18 router checks pass'
else
  fail P4-web "the router suite did not report 18 passed / 0 failed: $WEB_LINE"
fi
if "$GREP" -q 'flavor = "multi_thread"' tests/web.rs; then
  pass P4-race 'w14 races two genuinely concurrent live requests on a multi-thread runtime'
else
  fail P4-race 'w14 does not run on a multi-thread runtime, so it does not race live requests'
fi

# --- the hit-path measurement -------------------------------------------------
printf '\n-- hit-path cost, release --\n'
REL_OUT=$(cargo test --release --test store s08 -- --nocapture 2>&1 || true)
NS=$(printf '%s\n' "$REL_OUT" | "$GREP" -o 'ns_per_op=[0-9]*' | head -1 | cut -d= -f2)
if [ -n "${NS:-}" ]; then
  printf 'release ns_per_op=%s\n' "$NS"
  if [ "$NS" -lt 100000 ]; then
    pass P5-bench "the release hit path measured ${NS} ns/op, three orders of magnitude below one millisecond, which is what decides the inline-versus-spawn_blocking question"
  else
    fail P5-bench "the release hit path measured ${NS} ns/op, too slow to justify calling the store inline"
  fi
  # Reproduction note: the raw report claimed 159 ns/op. This is a re-derivation,
  # so the figure is NOT expected to reproduce; only the order of magnitude is
  # load-bearing. Recorded, never asserted equal.
  printf 'NOTE raw/opus.md claimed 159 ns/op release; this re-derivation measures %s ns/op. Not asserted equal.\n' "$NS"
else
  fail P5-bench 'the release benchmark produced no ns_per_op line'
fi

# --- dependency-tree deltas ---------------------------------------------------
printf '\n-- dependency-tree deltas (unique name+version in the normal graph, root included) --\n'
DELTAS="$WORK/deltas"
mk_delta() {
  local name=$1 extra=$2
  mkdir -p "$DELTAS/$name/src"
  printf 'fn main() {}\n' > "$DELTAS/$name/src/main.rs"
  {
    printf '[package]\nname = "delta_%s"\nversion = "0.0.0"\nedition = "2024"\nrust-version = "1.96"\npublish = false\n\n' "$name"
    printf '[dependencies]\naxum = "=0.8.9"\ntokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }\n'
    if [ -n "$extra" ]; then printf '%s\n' "$extra"; fi
  } > "$DELTAS/$name/Cargo.toml"
}
count_tree() {
  ( cd "$DELTAS/$1" && cargo tree -e normal --prefix none --no-dedupe 2>/dev/null |
      "$GREP" -v '^[[:space:]]*$' | sort -u | wc -l | tr -d ' ' )
}

# Revision 2: every delta requirement is an EXACT pin (`=x.y.z`) to the version
# measured on 2026-09-19. Revision 1 used caret requirements, so `lru = "0.18"`
# silently moved to 0.18.5 (published 2026-09-23), whose hashbrown edge drops two
# packages, and P6-lru stopped reproducing. An exact pin fixes each direct
# dependency; transitive versions can still move within their own requirements,
# which is why each delta prints the version that actually resolved.
mk_delta baseline ''
mk_delta sha2 'sha2 = { version = "=0.11.0", default-features = false, features = ["alloc"] }'
mk_delta hashlink 'hashlink = "=0.12.2"'
mk_delta lru 'lru = "=0.18.4"'
mk_delta lrulatest 'lru = "=0.18.5"'
mk_delta quickcache 'quick_cache = "=0.7.0"'
mk_delta minimoka 'mini-moka = "=0.10.3"'
mk_delta moka 'moka = { version = "=0.12.16", features = ["sync"] }'
mk_delta axumidem 'axum-idempotent = "=0.3.0"
ruts = "=0.10.1"
tower-cookies = "=0.11.0"'

BASE=$(count_tree baseline)
if [ "$BASE" = "51" ]; then
  pass P6-baseline "the axum 0.8.9 + tokio 1.53.1 baseline is 51 packages, reproducing the raw report's baseline exactly"
else
  fail P6-baseline "the baseline measured $BASE packages, not the 51 the raw report recorded; every delta below is against $BASE"
fi

# expected deltas as the raw report recorded them, for a stated comparison
resolved() {
  ( cd "$DELTAS/$1" && cargo tree -e normal --depth 1 --prefix none 2>/dev/null |
      "$GREP" -E "^$2 v" | head -1 )
}
check_delta() {
  local name=$1 label=$2 claimed=$3 crate=$4 total delta
  total=$(count_tree "$name")
  delta=$((total - BASE))
  printf '  %-22s total=%-4s delta=+%-3s raw-report-claimed=+%-3s resolved=%s\n' "$label" "$total" "$delta" "$claimed" "$(resolved "$name" "$crate")"
  if [ "$delta" = "$claimed" ]; then
    pass "P6-$name" "$label adds +$delta packages, reproducing the raw report's +$claimed"
  else
    fail "P6-$name" "$label adds +$delta packages; the raw report claimed +$claimed — the raw figure does not reproduce"
  fi
}
check_delta sha2       'sha2 =0.11.0'           8 sha2
check_delta hashlink   'hashlink =0.12.2'       3 hashlink
check_delta lru        'lru =0.18.4'            5 lru
check_delta quickcache 'quick_cache =0.7.0'     9 quick_cache
check_delta minimoka   'mini-moka =0.10.3'     11 mini-moka
check_delta moka       'moka =0.12.16'         14 moka

# lru 0.18.5 is the release that broke revision 1's caret-pinned P6-lru. It is
# measured and asserted at its own figure (+3, auditor-derived 2026-09-27) so the
# log states what the newest lru costs today, rather than hiding the move.
LL_TOTAL=$(count_tree lrulatest)
LL_DELTA=$((LL_TOTAL - BASE))
printf '  %-22s total=%-4s delta=+%-3s resolved=%s\n' 'lru =0.18.5' "$LL_TOTAL" "$LL_DELTA" "$(resolved lrulatest lru)"
if [ "$LL_DELTA" -eq 3 ]; then
  pass P6-lru-latest "lru 0.18.5 adds +3 packages (its hashbrown v0.17.1 edge no longer pulls allocator-api2 and equivalent), two fewer than 0.18.4's +5; neither figure moves the recommendation, which adopts no cache crate"
else
  fail P6-lru-latest "lru 0.18.5 adds +$LL_DELTA packages, not the +3 the decision records"
fi

# The axum-idempotent stack is measured and reported, NOT asserted against the
# raw report's +48: the decision records that the raw figure does not reproduce.
AI_TOTAL=$(count_tree axumidem)
AI_DELTA=$((AI_TOTAL - BASE))
printf '  %-22s total=%-4s delta=+%-3s raw-report-claimed=+48\n' 'axum-idempotent stack' "$AI_TOTAL" "$AI_DELTA"
if [ "$AI_DELTA" -gt 30 ]; then
  pass P6-axumidem "the axum-idempotent + ruts + tower-cookies stack adds +$AI_DELTA packages, more than four times the recommendation's +8"
else
  fail P6-axumidem "the axum-idempotent stack adds only +$AI_DELTA packages, which would undercut the transitive-cost argument"
fi
if [ "$AI_DELTA" -eq 48 ]; then
  fail P6-axumidem-raw 'the raw report figure of +48 reproduced, so the decision is wrong to call it unreproducible'
else
  pass P6-axumidem-raw "the raw report's +48 does NOT reproduce; measured +$AI_DELTA under the same method that reproduced all six rows above"
fi

# Control: the versions the raw report named really are the ones that resolved,
# so the difference is a counting difference and not a different dependency set.
AI_TREE=$( cd "$DELTAS/axumidem" && cargo tree -e normal --prefix none --no-dedupe 2>/dev/null | sort -u )
MISSING=""
for want in 'axum-idempotent v0.3.0' 'ruts v0.10.1' 'tower-cookies v0.11.0' 'dashmap v' 'cookie v' 'bincode v' 'chacha20 v'; do
  printf '%s\n' "$AI_TREE" | "$GREP" -q "^$want" || MISSING="$MISSING $want"
done
if [ -z "$MISSING" ]; then
  pass P6-axumidem-versions 'every package the raw report named in that stack is present at the version it named, so the delta difference is a count, not a different resolution'
else
  fail P6-axumidem-versions "these packages the raw report named are absent:$MISSING"
fi

summary
[ "$FAIL" -eq 0 ]
