#!/usr/bin/env bash
# R75 check E1 — the recommended stack's contract (A01-A15), in-process via
# tower::ServiceExt::oneshot, on the host toolchain and on the MSRV floor (1.96.0).
# Materializes the probe with probe-crate.sh (outside the repository), then runs
# offline and locked.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/probe-crate.sh" > /dev/null
cd "${R75_PROBE_DIR:-${TMPDIR:-/tmp}/r75-synth-probe}"
echo "== E1 stack-acceptance — $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC), $(uname -sm)"
echo "== Cargo.lock sha256: $(shasum -a 256 Cargo.lock | cut -d' ' -f1)"
for tc in host 1.96.0; do
  if [[ "$tc" == host ]]; then
    echo "== toolchain: $(rustc --version)"
    out="$(cargo test --offline --locked --test acceptance -- --nocapture --test-threads=1 2>&1)"
  else
    echo "== toolchain: $(rustup run "$tc" rustc --version)"
    out="$(rustup run "$tc" cargo test --offline --locked --test acceptance -- --nocapture --test-threads=1 2>&1)"
  fi
  grep -E '(^| )(PASS|FAIL) A[0-9]|^test result:' <<< "$out" | sed 's/^test recommended_stack_contract \.\.\. //'
  echo "== $tc: $(grep -cE '(^| )PASS A' <<< "$out") pass, $(grep -cE '(^| )FAIL A' <<< "$out" || true) fail"
done
