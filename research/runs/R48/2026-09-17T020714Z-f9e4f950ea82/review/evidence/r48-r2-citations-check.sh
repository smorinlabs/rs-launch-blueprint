#!/usr/bin/env bash
# R48 mocking-crates — revision 2, citation and uniform-gate-2 check (JF-1, JF-3, JF-7).
#
# Purpose. Revision 1 stated three adopter claims that were the entire basis for
# three gate-4 dispositions, and stated a declared-`rust-version` fact for six
# further candidates, with no endpoint on any of them (JF-3). It also applied
# fitness gate 2 two ways inside one document (JF-1). This script re-reads each
# of those facts at its primary source so the decision cites an executed check
# rather than a carried figure, and records the `shellcheck` run that revision 1
# claimed but never logged (JF-7).
#
# The gate-2 rule this checks against is the programme's, not this item's:
# `docs/planning/p02/execution-ledger.md:414` withdrew the permissive reading
# ("insufficient evidence to PASS a gate the prompt says must be passed") and
# `:640` applies the strict one. An absent declared `rust-version` therefore
# fails gate 2.
#
# Determinism contract
# --------------------
#   * Every line beginning "# " is volatile (retrieval timestamp, host, tool
#     banners). Every PASS / FAIL / SKIP line and the RESULT line asserts a
#     stable fact and reproduces byte-for-byte:
#         bash r48-r2-citations-check.sh > new.log
#         diff <(grep -v '^# ' new.log) <(grep -v '^# ' r48-r2-citations-check.log)
#     must be empty.
#   * No star count, download counter, open-issue count or reverse-dependency
#     total is printed: those drift by the hour.
#   * E01-E03 assert the adopter's currently declared dependency version as a
#     tripwire. If an adopter bumps its pin the check FAILs, which is the signal
#     that the figure the decision cites needs updating -- not a defect.
#
# Usage: bash r48-r2-citations-check.sh     (runnable from any working directory)

set -uo pipefail

SCRIPT_DIR=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
UA='rs-launch-blueprint-research/1.0'
GREP=/usr/bin/grep

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

FAILED=0
pass() { printf 'PASS %s: %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s: %s\n' "$1" "$2"; FAILED=$((FAILED + 1)); }
skip() { printf 'SKIP %s: %s\n' "$1" "$2"; }

fetch() { curl -sS -A "$UA" -o "$2" -w '%{http_code}' "$1"; }

printf '# R48 mocking-crates — revision 2 citation and gate-2 check (JF-1, JF-3, JF-7)\n'
printf '# retrieved: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
printf '# host: %s\n' "$(uname -sm)"
printf '# grep binary: %s (%s)\n' "$GREP" "$("$GREP" --version 2>&1 | head -n 1)"
printf '# shellcheck: %s\n' "$(shellcheck --version 2>/dev/null | "$GREP" '^version:' || echo 'not installed')"
printf '#\n'

# ---------------------------------------------------------------------------
# E01-E03 — the three adopter claims that carried three gate-4 dispositions in
# revision 1 with no endpoint. Each asserts the declared dependency line in the
# project's own manifest and at least one macos-latest occurrence in its own CI.
# ---------------------------------------------------------------------------
adopter_check() { # adopter_check <id> <manifest-url> <manifest-pattern> <ci-url> <prose>
  local id=$1 murl=$2 mpat=$3 curl_=$4 prose=$5 mcode ccode nm nmac
  mcode=$(fetch "$murl" "$WORK/$id-manifest.toml")
  ccode=$(fetch "$curl_" "$WORK/$id-ci.yml")
  if [ "$mcode" != "200" ] || [ "$ccode" != "200" ]; then
    fail "$id" "manifest returned HTTP $mcode and CI returned HTTP $ccode, expected 200 and 200"
    return
  fi
  nm=$("$GREP" -c "$mpat" "$WORK/$id-manifest.toml")
  nmac=$("$GREP" -c 'macos-latest' "$WORK/$id-ci.yml")
  if [ "$nm" = "1" ] && [ "$nmac" -ge 1 ]; then
    pass "$id" "$prose (1 matching manifest line and at least one macos-latest occurrence in the project's own CI, counts by $GREP -c)"
  else
    fail "$id" "$prose — manifest matches $nm (expected 1), macos-latest occurrences $nmac (expected at least 1), counts by $GREP -c"
  fi
}

adopter_check E01 \
  "https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml" \
  '^mockall = "0\.13\.0"$' \
  "https://raw.githubusercontent.com/tokio-rs/tokio/master/.github/workflows/ci.yml" \
  "tokio-rs/tokio declares mockall = \"0.13.0\" and runs CI on macos-latest — corroborating adopter evidence for mockall on macOS, at 0.13.0 and NOT at the recommended 0.15.0, which is why revision 2 closes gate 4 for 0.15.0 by executed compile instead (see r48-r2-msrv-macos-spike.log D03)"

adopter_check E02 \
  "https://raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/Cargo.toml" \
  '^wiremock = [{] version = "0\.6\.5"' \
  "https://raw.githubusercontent.com/matrix-org/matrix-rust-sdk/main/.github/workflows/ci.yml" \
  "matrix-org/matrix-rust-sdk declares wiremock = { version = \"0.6.5\" } and runs CI on macos-latest — the adopter evidence behind wiremock's gate-4 sentence, which stands even though wiremock is excluded on gate 2"

adopter_check E03 \
  "https://raw.githubusercontent.com/apache/iceberg-rust/main/Cargo.toml" \
  '^mockito = "1"$' \
  "https://raw.githubusercontent.com/apache/iceberg-rust/main/.github/workflows/ci.yml" \
  "apache/iceberg-rust declares mockito = \"1\" and names macos-latest in its own CI — the adopter evidence behind mockito's gate-4 disposition; that its macOS lanes are build-only and its tests job is ubuntu-only is carried from the opus report, 2026-09-17, and is NOT asserted here"

# ---------------------------------------------------------------------------
# E04 — fitness gate 2 applied by one rule to every remaining candidate. Under
# the programme's strict reading an absent declared rust-version fails the gate.
# ---------------------------------------------------------------------------
declared=""
e04_ok=1
for crate in mockall httpmock mockito unimock faux wiremock httptest mry double stubr rvcr; do
  code=$(fetch "https://crates.io/api/v1/crates/$crate/versions" "$WORK/$crate.json")
  if [ "$code" != "200" ]; then
    e04_ok=0
    declared="$declared $crate=HTTP$code"
    continue
  fi
  rv=$(python3 - "$WORK/$crate.json" << 'PY'
import json, sys
with open(sys.argv[1]) as fh:
    newest = [v for v in json.load(fh)["versions"] if not v["yanked"]][0]
print("%s:%s" % (newest["num"], newest.get("rust_version") or "NONE"))
PY
  )
  declared="$declared $crate=$rv"
done
expected=" mockall=0.15.0:1.77.0 httpmock=0.8.3:1.88.0 mockito=1.7.2:1.70 unimock=0.6.8:1.70 faux=0.1.13:1.65 wiremock=0.6.5:NONE httptest=0.16.4:NONE mry=0.14.0:NONE double=0.2.4:NONE stubr=0.6.2:NONE rvcr=0.2.1:NONE"
if [ "$e04_ok" = "1" ] && [ "$declared" = "$expected" ]; then
  pass E04 "newest non-yanked version and declared rust-version for every candidate:$declared — five declare a version inside the 1.96 floor and clear gate 2 (mockall, httpmock, mockito, unimock, faux); six declare none and therefore fail gate 2 under the strict reading the programme applies (wiremock, httptest, mry, double, stubr, rvcr)"
else
  fail E04 "declared rust-versions read as$declared; expected$expected"
fi

# ---------------------------------------------------------------------------
# E05 — the claim revision 1 made about its own evidence scripts but never
# logged: that they pass shellcheck with no findings.
# ---------------------------------------------------------------------------
if command -v shellcheck > /dev/null 2>&1; then
  sc_out="$WORK/shellcheck.txt"
  : > "$sc_out"
  sc_fail=0
  sc_n=0
  for s in r48-claims-check.sh r48-r2-msrv-macos-spike.sh r48-r2-citations-check.sh; do
    if [ -f "$SCRIPT_DIR/$s" ]; then
      sc_n=$((sc_n + 1))
      shellcheck "$SCRIPT_DIR/$s" >> "$sc_out" 2>&1 || sc_fail=$((sc_fail + 1))
    fi
  done
  lines=$(wc -l < "$sc_out" | tr -d ' ')
  if [ "$sc_n" = "3" ] && [ "$sc_fail" = "0" ] && [ "$lines" = "0" ]; then
    pass E05 "shellcheck reports no findings and exits 0 for all 3 evidence scripts in this run (r48-claims-check.sh, r48-r2-msrv-macos-spike.sh, r48-r2-citations-check.sh); its output was 0 lines long"
  else
    fail E05 "shellcheck: scripts found $sc_n (expected 3), non-zero exits $sc_fail (expected 0), output lines $lines (expected 0)"
  fi
else
  skip E05 "shellcheck is not on PATH; the evidence scripts were not linted here"
fi

printf '#\n'
if [ "$FAILED" = "0" ]; then
  printf 'RESULT: all checks passed (0 FAIL)\n'
else
  printf 'RESULT: %s check(s) FAILED\n' "$FAILED"
fi
exit "$FAILED"
