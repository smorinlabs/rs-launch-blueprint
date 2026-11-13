#!/usr/bin/env bash
# R75 check E2 — the variants the engines and the owner reference proposed, each run to
# show what it actually does: N01 owner-reference C11 order (as quoted by the opus leg),
# N02 muse/gemini route_layer access log, N03 stock PropagateRequestIdLayer under a replay,
# N04 no CatchPanicLayer, N05 `overriding` header semantics, N06 ServiceBuilder spelling.
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/probe-crate.sh" > /dev/null
cd "${R75_PROBE_DIR:-${TMPDIR:-/tmp}/r75-synth-probe}"
echo "== E2 negative-controls — $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC), $(uname -sm), $(rustc --version)"
echo "== Cargo.lock sha256: $(shasum -a 256 Cargo.lock | cut -d' ' -f1)"
out="$(cargo test --offline --locked --test negative -- --nocapture --test-threads=1 2>&1)"
grep -E '(PASS|FAIL) N[0-9]|^test result:' <<< "$out" | sed -E 's/^test n[0-9a-z_]+ \.\.\. //'
echo "== $(grep -cE '(^| )PASS N' <<< "$out") pass, $(grep -cE '(^| )FAIL N' <<< "$out" || true) fail"
