#!/usr/bin/env bash
# R69 evidence: the R01 coupling claim.
#
# CLAIM UNDER TEST: the erased service R01 publishes satisfies axum 0.8.9's
# application-state bound `S: Clone + Send + Sync + 'static`
# (axum-0.8.9/src/routing/mod.rs:138-141, read at the published artifact)
# WITHOUT `ProjectsService` deriving `Clone` -- i.e. this item needs no change
# to R01's accepted parameter value.
#
# This is a TYPE-LEVEL check. The three crates have ZERO dependencies: no axum,
# no tokio, no handler, no router, no listener, no port method, no behavior.
# The bound is transcribed from axum's published source; the seam types are
# transcribed from R01's published DECISION.md. Nothing here builds, wires or
# runs the recommendation.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
P="$HERE/state-bound"
rc=0

echo "toolchain: $(rustc --version) / $(cargo --version)"
echo "host: $(uname -sm)"
echo

run_case() { # run_case <dir> <expect-pass|expect-fail> <must-contain>
  local dir="$1" expect="$2" needle="$3" out st
  echo "=================================================================="
  echo "case: $(basename "$dir")   expect: $expect"
  echo "------------------------------------------------------------------"
  out="$(cd "$dir" && cargo build --quiet --offline 2>&1)"; st=$?
  # --offline is a no-network assertion: these crates have no dependencies, so a
  # network fetch would mean something unintended crept into the manifest.
  echo "$out"
  echo "exit=$st"
  if [ "$expect" = "expect-pass" ]; then
    if [ "$st" -ne 0 ]; then echo "FAIL: expected a clean build, got exit=$st"; rc=1; return; fi
    if [ -n "$out" ]; then echo "FAIL: expected no diagnostics"; rc=1; return; fi
    echo "OK: built clean, no diagnostics"
  else
    if [ "$st" -eq 0 ]; then echo "FAIL: expected a compile error, build succeeded"; rc=1; return; fi
    if ! printf '%s' "$out" | grep -qF "$needle"; then
      echo "FAIL: expected error text not found: $needle"; rc=1; return
    fi
    echo "OK: failed to compile, and the diagnostic contains: $needle"
  fi
}

run_case "$P/positive"           expect-pass ""
run_case "$P/neg-by-value"       expect-fail 'the trait `Clone` is not implemented for `ProjectsService<Arc<(dyn ProjectsPort'
run_case "$P/neg-no-supertraits" expect-fail 'the trait `Sync` is not implemented for `(dyn ProjectsPort'

echo
echo "state-bound-check rc=$rc"
exit $rc
