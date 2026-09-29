#!/usr/bin/env bash
# R80 health-probe-endpoints — empirical check, part 2 of 3: the throwaway axum
# probe workspace.
#
# Re-executes the thirteen checks raw/opus.md reports (A, B, T1-T8, C9-C11)
# against the exact crate versions R69 revision 10 and R66 select, in a workspace
# created under $TMPDIR from the committed sources in ./probe/ and deleted on
# exit. It MEASURES; it does not build the template, which does not exist.
#
# Usage: bash check-probe.sh
# Exit status: 0 when no check FAILs, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE_SRC="$HERE/probe"

PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

assert_contains() { # id, needle, haystack-file, description
  if $GREP -qF -- "$2" "$3"; then pass "$1" "$4"; else fail "$1" "$4 (missing: $2)"; fi
}

echo "=== R80 check-probe.sh ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "uname: $(uname -srm)"

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  for id in A B T1 T2 T3 T4 T5 T6 T7 T8 C9 C10 C11; do
    skip "$id" "no cargo/rustc on PATH; the probe workspace cannot be built"
  done
  printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
  exit 0
fi

echo "rustc: $(rustc --version)"
echo "cargo: $(cargo --version)"

if [ ! -d "$PROBE_SRC" ]; then
  echo "probe sources missing at $PROBE_SRC" >&2
  exit 1
fi

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r80-probe.XXXXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT
echo "workspace: $WORK (deleted on exit)"

mkdir -p "$WORK/src" "$WORK/tests" "$WORK/crates/core/src" "$WORK/crates/web/src" "$WORK/crates/web/tests"
cp "$PROBE_SRC/facade-src/lib.rs" "$WORK/src/lib.rs"
cp "$PROBE_SRC/facade-tests/version_hazard.rs" "$WORK/tests/version_hazard.rs"
cp "$PROBE_SRC/core-src/lib.rs" "$WORK/crates/core/src/lib.rs"
cp "$PROBE_SRC/web-src/lib.rs" "$WORK/crates/web/src/lib.rs"
cp "$PROBE_SRC/web-tests/probes.rs" "$WORK/crates/web/tests/probes.rs"

install_variant() { # variant letter
  cp "$PROBE_SRC/manifests-$1/facade.toml" "$WORK/Cargo.toml"
  cp "$PROBE_SRC/manifests-$1/core.toml" "$WORK/crates/core/Cargo.toml"
  cp "$PROBE_SRC/manifests-$1/web.toml" "$WORK/crates/web/Cargo.toml"
  # Revision 4 (audit EA-4): each variant carries its committed lockfile and
  # every cargo call below passes --locked, so the measured tree is rebuildable
  # from the committed bytes whether or not the registry cache is warm.
  cp "$PROBE_SRC/manifests-$1/Cargo.lock" "$WORK/Cargo.lock"
}

# --offline succeeds only from a warm local registry cache; from a cold cache the
# online fallback is expected, and --locked holds the resolution either way.
CARGO_FLAGS=(--locked --offline)
install_variant a
if ! (cd "$WORK" && cargo metadata "${CARGO_FLAGS[@]}" --format-version 1 >/dev/null 2>"$WORK/metadata.err"); then
  echo "NOTE: --offline metadata failed; retrying online, still --locked"
  cat "$WORK/metadata.err" >&2 || true
  CARGO_FLAGS=(--locked)
fi
echo "cargo network flags: '${CARGO_FLAGS[*]}'"

# ---------------------------------------------------------------- check A ----
# Variant a: literal per-member versions. The facade is 0.4.2, the members 0.1.0.
set +e
(cd "$WORK" && R80_EXPECTED_MEMBER_VERSION=0.1.0 \
  cargo test "${CARGO_FLAGS[@]}" -p facade --test version_hazard -- --nocapture) >"$WORK/a.log" 2>&1
A_STATUS=$?
set -e
echo "--- variant a (no [workspace.package] version) ---"
cat "$WORK/a.log"
if [ "$A_STATUS" -ne 0 ]; then
  fail A "variant a test run exited $A_STATUS"
else
  if $GREP -qF 'facade_env_CARGO_PKG_VERSION=0.4.2' "$WORK/a.log" &&
     $GREP -qF 'web_member_env_CARGO_PKG_VERSION=0.1.0' "$WORK/a.log" &&
     $GREP -qE 'std_env_consts_OS=[a-z]+' "$WORK/a.log" &&
     $GREP -qE 'std_env_consts_ARCH=[a-z0-9_]+' "$WORK/a.log" &&
     $GREP -qF 'os_and_arch_are_static_str=true' "$WORK/a.log"; then
    pass A "env!(CARGO_PKG_VERSION) inside a member reports the MEMBER's version (facade 0.4.2, web member 0.1.0); std::env::consts::{OS,ARCH} resolve as &'static str with no build.rs in the tree"
  else
    fail A "variant a did not print the expected version hazard lines"
  fi
fi
if [ -e "$WORK/build.rs" ] || [ -e "$WORK/crates/core/build.rs" ] || [ -e "$WORK/crates/web/build.rs" ]; then
  fail A "a build.rs exists in the probe workspace; the no-build-script claim is not being tested"
fi

# ---------------------------------------------------------------- check B ----
install_variant b
set +e
(cd "$WORK" && R80_EXPECTED_MEMBER_VERSION=0.4.2 \
  cargo test "${CARGO_FLAGS[@]}" -p facade --test version_hazard -- --nocapture) >"$WORK/b.log" 2>&1
B_STATUS=$?
set -e
echo "--- variant b ([workspace.package] version + version.workspace = true) ---"
cat "$WORK/b.log"
if [ "$B_STATUS" -ne 0 ]; then
  fail B "variant b test run exited $B_STATUS"
elif $GREP -qF 'facade_env_CARGO_PKG_VERSION=0.4.2' "$WORK/b.log" &&
     $GREP -qF 'web_member_env_CARGO_PKG_VERSION=0.4.2' "$WORK/b.log" &&
     $GREP -qF 'core_member_env_CARGO_PKG_VERSION=0.4.2' "$WORK/b.log"; then
  pass B "[workspace.package] version = 0.4.2 with version.workspace = true makes every member report 0.4.2"
else
  fail B "variant b did not repair the version hazard"
fi

# ------------------------------------------------------------- T1 .. T8 -----
set +e
(cd "$WORK" && cargo test "${CARGO_FLAGS[@]}" -p probe-web --test probes -- --nocapture --test-threads=1) \
  >"$WORK/t.log" 2>&1
T_STATUS=$?
set -e
echo "--- probe handler tests T1-T8 (variant b) ---"
cat "$WORK/t.log"

if [ "$T_STATUS" -ne 0 ]; then
  echo "NOTE: the probe test binary exited $T_STATUS; individual assertions below still evaluate the captured output"
fi

# Under --nocapture the harness interleaves a test's stdout with its own
# "test <name> ... " prefix, so the trailing "ok" lands on a later line. The
# per-test assertions below therefore pair the harness line with the printed
# content, and the suite-level result line is asserted once, here.
if ! $GREP -qF 'test result: ok. 8 passed; 0 failed; 0 ignored' "$WORK/t.log"; then
  echo "NOTE: the probe suite did not report 8 passed / 0 failed; every T-check below will fail"
fi

t_ok() { # test-fn-name
  $GREP -qE "^test ${1} \.\.\. " "$WORK/t.log" &&
    $GREP -qF 'test result: ok. 8 passed; 0 failed; 0 ignored' "$WORK/t.log"
}

if t_ok t1_healthz_200_and_four_fields &&
   $GREP -qE 'T1 GET /healthz status=200 OK body=\{"status":"ok","version":"0\.4\.2","os":"[a-z]+","arch":"[a-z0-9_]+"\}' "$WORK/t.log"; then
  pass T1 "GET /healthz answers 200 with exactly {status,version,os,arch}, version from the core accessor"
else
  fail T1 "liveness body or status not as asserted"
fi

if t_ok t2_healthz_body_is_byte_stable && $GREP -qF 'T2 byte-stable=true' "$WORK/t.log"; then
  pass T2 "two successive liveness bodies are byte-identical"
else
  fail T2 "liveness body is not byte-stable"
fi

if t_ok t3_warn_only_checks_keep_readiness &&
   $GREP -qF 'T3 GET /readyz status=200 OK' "$WORK/t.log" &&
   $GREP -qF '"name":"config-file","status":"warn"' "$WORK/t.log"; then
  pass T3 "a missing config file and a missing credential are warn-level and readiness holds at 200"
else
  fail T3 "warn-only readiness did not hold at 200 with the expected check set"
fi

if t_ok t4_drain_latch_removes_traffic &&
   $GREP -qF 'T4 GET /readyz (draining) status=503 Service Unavailable' "$WORK/t.log" &&
   $GREP -qF '"status":"unavailable"' "$WORK/t.log"; then
  pass T4 "after Readiness::begin_draining() readiness answers 503 and still carries the report"
else
  fail T4 "the drain latch did not remove traffic"
fi

if t_ok t5_draining_is_not_a_restart_signal &&
   $GREP -qF 'T5 GET /healthz (draining) status=200 OK' "$WORK/t.log"; then
  pass T5 "liveness stays 200 while the process drains, so draining is not a restart signal"
else
  fail T5 "liveness changed during drain"
fi

if t_ok t6_error_report_yields_503_without_touching_the_environment &&
   $GREP -qF 'T6 readiness_response(false, <one error check>) status=503 Service Unavailable' "$WORK/t.log"; then
  pass T6 "one error-level check yields 503 through the pure response function, with no environment read"
else
  fail T6 "the 503 diagnostic branch did not fire"
fi

if t_ok t7_post_healthz_is_405_with_allow &&
   $GREP -qF 'T7 POST /healthz status=405 Method Not Allowed allow=Some("GET,HEAD")' "$WORK/t.log"; then
  pass T7 "axum 0.8.9's MethodRouter answers POST with 405 and Allow: GET,HEAD, with no code written for it"
else
  fail T7 "405/Allow behaviour not as asserted"
fi

if t_ok t8_head_is_served_by_the_get_handler &&
   $GREP -qF 'T8 HEAD /healthz status=200 OK body_len=0' "$WORK/t.log"; then
  pass T8 "HEAD /healthz is served by the GET handler and answers 200 with an empty body"
else
  fail T8 "HEAD was not served by the GET handler"
fi

# ------------------------------------------------------------ C9 .. C11 -----
set +e
(cd "$WORK" && cargo tree "${CARGO_FLAGS[@]}" -p facade --edges normal) >"$WORK/c9.log" 2>&1
C9_STATUS=$?
set -e
echo "--- C9: cargo tree -p facade --edges normal (feature off) ---"
cat "$WORK/c9.log"
AXUM_OFF="$($GREP -c 'axum' "$WORK/c9.log" || true)"
if [ "$C9_STATUS" -eq 0 ] && [ "$AXUM_OFF" -eq 0 ]; then
  pass C9 "a default build's normal dependency graph contains axum on 0 lines (counted with $($GREP --version | head -1))"
else
  fail C9 "default build graph unexpectedly contains axum on $AXUM_OFF line(s) (tree exit $C9_STATUS)"
fi

set +e
(cd "$WORK" && cargo tree "${CARGO_FLAGS[@]}" -p facade --features web --edges normal) >"$WORK/c10.log" 2>&1
C10_STATUS=$?
set -e
echo "--- C10: cargo tree -p facade --features web --edges normal ---"
cat "$WORK/c10.log"
AXUM_ON="$($GREP -c 'axum v0.8.9' "$WORK/c10.log" || true)"
if [ "$C10_STATUS" -eq 0 ] && [ "$AXUM_ON" -ge 1 ] && $GREP -qF 'probe-web v0.4.2' "$WORK/c10.log"; then
  pass C10 "--features web brings the optional web member and axum v0.8.9 back into the normal graph ($AXUM_ON axum line(s))"
else
  fail C10 "--features web did not restore the web member and axum (tree exit $C10_STATUS, axum lines $AXUM_ON)"
fi

set +e
(cd "$WORK" && cargo tree "${CARGO_FLAGS[@]}" -p probe-core --edges normal) >"$WORK/c11.log" 2>&1
C11_STATUS=$?
set -e
echo "--- C11: cargo tree -p probe-core --edges normal ---"
cat "$WORK/c11.log"
CORE_WEB="$($GREP -cE 'axum|tokio|hyper|tower' "$WORK/c11.log" || true)"
if [ "$C11_STATUS" -eq 0 ] && [ "$CORE_WEB" -eq 0 ] && $GREP -qF 'serde v1.0.229' "$WORK/c11.log"; then
  pass C11 "the member holding run_diagnostics resolves serde v1.0.229 and names no web crate (axum|tokio|hyper|tower matched on $CORE_WEB lines)"
else
  fail C11 "the core member's graph is not serde-only (tree exit $C11_STATUS, web-crate lines $CORE_WEB)"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
