#!/usr/bin/env bash
# R83 synthesis evidence — the contract-fuzz architecture, observed.
#
# Copies the committed fixture at review/evidence/contract-fuzz-probe/ into a scratch
# directory created under $TMPDIR, builds it, and runs six legs of the harness. The
# fixture is a THROWAWAY probe, not template code and not an implementation of the
# recommendation: it exists only so the synthesis can watch the architecture behave.
#
# Every check asserts on CONTENT. Exits non-zero if any check FAILs.
set -euo pipefail

GREP=/usr/bin/grep
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FIXTURE="$SCRIPT_DIR/contract-fuzz-probe"

PASS=0
FAIL=0
SKIP=0

check() { # check <name> <expected-substring> <file>
  local name="$1" expected="$2" file="$3"
  if $GREP -qF -- "$expected" "$file"; then
    printf 'PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  else
    printf 'FAIL  %s  (expected substring not found: %s)\n' "$name" "$expected"
    FAIL=$((FAIL + 1))
  fi
}

check_absent() { # check_absent <name> <forbidden-substring> <file>
  local name="$1" forbidden="$2" file="$3"
  if $GREP -qF -- "$forbidden" "$file"; then
    printf 'FAIL  %s  (forbidden substring present: %s)\n' "$name" "$forbidden"
    FAIL=$((FAIL + 1))
  else
    printf 'PASS  %s\n' "$name"
    PASS=$((PASS + 1))
  fi
}

skip() { printf 'SKIP  %s  (%s)\n' "$1" "$2"; SKIP=$((SKIP + 1)); }

# Prints the libtest portion of a leg's output with the two fields that legitimately vary
# between runs replaced by placeholders: the OS thread id in a panic line and the
# wall-clock duration. Everything else in this log is byte-reproducible.
show() {
  sed -n '/^running /,$p' "$1" \
    | sed -E -e "s/^(thread '[^']*') \([0-9]+\)/\1 (<thread-id>)/" \
             -e 's/finished in [0-9]+\.[0-9]+s/finished in <duration>/'
}

printf '== environment ==\n'
printf 'grep: %s\n' "$($GREP --version | head -1)"
if ! command -v cargo >/dev/null 2>&1; then
  skip 'A0..A22 (the whole probe)' 'cargo is not on PATH'
  printf '\n== totals ==\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 0
fi
rustc --version
cargo --version
printf 'os: %s %s\n' "$(uname -s)" "$(uname -m)"

test -d "$FIXTURE" || { printf 'FAIL  fixture directory missing: %s\n' "$FIXTURE"; exit 1; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r83-probe-XXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

cp -R "$FIXTURE/." "$WORK/"
mv "$WORK/Cargo.toml.fixture" "$WORK/Cargo.toml"

printf '\n== build ==\n'
if ! ( cd "$WORK" && cargo build --tests ) >"$WORK/build.log" 2>&1; then
  tail -30 "$WORK/build.log"
  if $GREP -qi 'failed to download\|no such host\|network\|offline' "$WORK/build.log"; then
    skip 'A0..A22 (the whole probe)' 'the crate registry could not be reached'
    printf '\n== totals ==\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
    exit 0
  fi
  printf 'FAIL  A0 probe builds\n'
  exit 1
fi
printf 'PASS  A0 probe builds\n'
PASS=$((PASS + 1))

run_leg() { # run_leg <log-name> [VAR=VALUE ...]
  local log="$WORK/$1.log"; shift
  ( cd "$WORK" && env "$@" cargo test --test contract_fuzz -- --nocapture --test-threads=1 ) \
    >"$log" 2>&1 || true
  printf '%s' "$log"
}

printf '\n== leg 1: no seeded defect ==\n'
L1="$(run_leg leg1 R83_LEG=clean)"
show "$L1"
check 'A1 the served 3.1 document parses and validates' 'document version: 3.1.0' "$L1"
check 'A2 every documented operation is enumerated from the document' 'operations discovered: 2' "$L1"
check 'A3 the create operation is fuzzed with no operation name in the harness' 'projects-create: 16 cases, no finding' "$L1"
check 'A4 the read operation is fuzzed' 'projects-read: 16 cases, no finding' "$L1"
check 'A5 a conformant service passes all three oracles' 'test result: ok. 3 passed' "$L1"

printf '\n== leg 2: seeded 5xx on a documented-valid input ==\n'
L2="$(run_leg leg2 R83_SEED_DEFECT=1)"
show "$L2"
check 'A6 the 5xx oracle fires (principle P3, py parity)' '500 Internal Server Error for POST /projects' "$L2"
check 'A7 the failure names a minimized request' 'minimal failing input: ("/projects", Some(Object {"name": String("a"), "limit": Number(0)}))' "$L2"
check 'A8 the suite fails' 'test result: FAILED' "$L2"

printf '\n== leg 3: seeded R4.3 violation (bare array top level, 201, not a 5xx) ==\n'
L3="$(run_leg leg3 R83_SEED_ARRAY_BODY=1)"
show "$L3"
check 'A9 the R4.3 oracle fires on a non-5xx standard violation' 'non-object JSON top level ([{"name":"a"}]) for POST /projects' "$L3"
check_absent 'A10 the 5xx oracle did not fire on that leg' '500 Internal Server Error' "$L3"

printf '\n== leg 4: seeded R5.2 violation (unregistered status 299) ==\n'
L4="$(run_leg leg4 R83_SEED_UNREGISTERED_STATUS=1)"
show "$L4"
check 'A11 the R5.2 oracle fires on an unregistered status' 'unregistered status 299' "$L4"
check_absent 'A12 the 5xx oracle did not fire on that leg' '500 Internal Server Error' "$L4"

printf '\n== leg 5: the same seeded 5xx, boundary bias removed from the mapper ==\n'
L5="$(run_leg leg5 R83_SEED_DEFECT=1 R83_NO_BOUNDARY_BIAS=1)"
show "$L5"
check 'A13 a uniform-only mapper misses the seeded defect and the suite passes' 'projects-create: 16 cases, no finding' "$L5"
check 'A14 boundary bias reaches the declared boundary under every seed, uniform draws do not' 'with explicit boundary bias: 20/20' "$L5"
check 'A15 the uniform arm reaches it under 2 of 20 seeds' 'uniform draw only:           2/20' "$L5"

printf '\n== leg 6: the OpenAPI version range oas3 0.22.0 will validate ==\n'
check 'A16 a 3.1.0 document validates' '3.1.0 validate_version: Ok("3.1.0")' "$L1"
check 'A17 the same document relabelled 3.0.3 does not' '3.0.3 validate_version: Err(UnsupportedSpecFileVersion' "$L1"
check 'A18 a 3.0.3 document still parses and still enumerates' '3.0.3 operations still enumerated: 2' "$L1"

printf '\n== dependency cost ==\n'
( cd "$WORK" && cargo tree -e normal --prefix none 2>/dev/null ) | sed '/^$/d' | sort -u > "$WORK/normal.txt"
( cd "$WORK" && cargo tree -e normal,dev --prefix none 2>/dev/null ) | sed '/^$/d' | sort -u > "$WORK/withdev.txt"
NORMAL=$(wc -l < "$WORK/normal.txt" | tr -d ' ')
WITHDEV=$(wc -l < "$WORK/withdev.txt" | tr -d ' ')
printf 'packages in the normal graph: %s\npackages with dev-dependencies: %s\n' "$NORMAL" "$WITHDEV"
if [ "$WITHDEV" -gt "$NORMAL" ]; then
  printf 'PASS  A19 the harness crates enter only through dev-dependencies (%s > %s)\n' "$WITHDEV" "$NORMAL"
  PASS=$((PASS + 1))
else
  printf 'FAIL  A19 the harness crates were expected to be dev-only\n'
  FAIL=$((FAIL + 1))
fi
# oas3 and proptest are the two crates this decision would ADD. Neither may reach the
# normal graph.
for crate in oas3 proptest; do
  if $GREP -q "^$crate " "$WORK/normal.txt"; then
    printf 'FAIL  A20.%s %s must not appear in the normal graph\n' "$crate" "$crate"
    FAIL=$((FAIL + 1))
  elif $GREP -q "^$crate " "$WORK/withdev.txt"; then
    printf 'PASS  A20.%s %s appears only with dev-dependencies\n' "$crate" "$crate"
    PASS=$((PASS + 1))
  else
    printf 'FAIL  A20.%s %s was not found in either graph\n' "$crate" "$crate"
    FAIL=$((FAIL + 1))
  fi
done

# tower is different, and the difference is a finding rather than a defect: R69 declares
# it as a dev-dependency for the oneshot idiom, but axum depends on tower itself, so it is
# already in the runtime graph. Declaring it dev-only adds no runtime crate; it does not
# keep tower out of the shipped binary.
if $GREP -q '^tower ' "$WORK/normal.txt"; then
  printf 'PASS  A21 tower is already in the normal graph through axum, not added by this design\n'
  PASS=$((PASS + 1))
else
  printf 'FAIL  A21 tower was expected in the normal graph as an axum dependency\n'
  FAIL=$((FAIL + 1))
fi
if ( cd "$WORK" && cargo tree -e normal -i tower ) 2>/dev/null | $GREP -q 'axum'; then
  printf 'PASS  A22 the path to tower in the normal graph runs through axum\n'
  PASS=$((PASS + 1))
else
  printf 'FAIL  A22 tower in the normal graph was expected to be reached through axum\n'
  FAIL=$((FAIL + 1))
fi

printf '\n== resolved versions of the three crates this decision names ==\n'
( cd "$WORK" && cargo tree -e normal,dev --prefix none 2>/dev/null ) | sed '/^$/d' | sort -u \
  | $GREP -E '^(oas3|proptest|tower|axum) ' || true

printf '\n== totals ==\n'
printf 'PASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
