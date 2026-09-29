#!/usr/bin/env bash
# R75 check E3 — F327 under a real listener (axum::serve, 127.0.0.1:0), a GLOBAL tracing
# subscriber that records every event at every level, and a counting `log` logger.
# The test installs F327's panic hook as the serve binary does (F05); F06 counts the
# plain-text `thread '..' panicked at` lines std's default hook would write (expected 0).
set -euo pipefail
here="$(cd "$(dirname "$0")" && pwd)"
bash "$here/probe-crate.sh" > /dev/null
cd "${R75_PROBE_DIR:-${TMPDIR:-/tmp}/r75-synth-probe}"
echo "== E3 framework-log-foldin — $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC), $(uname -sm), $(rustc --version)"
out="$(cargo test --offline --locked --test foldin -- --nocapture 2>&1)"
grep -E '^(STATUS|TALLY|LOG-RECORD) |(PASS|FAIL) F[0-9]|^test result:' <<< "$out" | sed -E 's/^test [a-z_]+ \.\.\. //'
echo "== plain-text lines outside the tracing pipeline (std default panic hook):"
grep -E "^thread '.*' .*panicked at" <<< "$out" | sed -E "s/\(([0-9]+)\)/(<tid>)/" || echo "(none)"
plain="$(grep -cE "^thread '.*' .*panicked at" <<< "$out" || true)"
pass="$(grep -cE '(^| )PASS F' <<< "$out" || true)" fail="$(grep -cE '(^| )FAIL F' <<< "$out" || true)"
if [[ "$plain" -eq 0 ]]; then
  echo "PASS F06 no plain-text panic line outside the pipeline :: plain_lines=$plain"; pass=$((pass + 1))
else
  echo "FAIL F06 no plain-text panic line outside the pipeline :: plain_lines=$plain"; fail=$((fail + 1))
fi
echo "== $pass pass, $fail fail"
