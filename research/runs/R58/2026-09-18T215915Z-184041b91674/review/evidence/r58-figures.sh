#!/usr/bin/env bash
# R58 empirical check C - every registry, GitHub and RustSec figure the decision
# cites, asserted against the committed snapshots under snapshots/.
#
# crates.io download counters and GitHub stars move every hour, so asserting
# against the live endpoints would make this script unreproducible by design.
# r58-fetch-snapshots.sh is the provenance record (it hits the endpoints, paced,
# and writes snapshots/); this script is the reproducible check and reads only
# the snapshots. Rerunning it produces byte-identical output on any machine that
# has the snapshot files, with or without a network.
set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"

echo "== environment =="
echo "$GREP version: $("$GREP" --version | head -1)"
echo "python3:       $(python3 --version 2>&1)"
if [ -f "$SNAP/RETRIEVED-UTC.txt" ]; then
  echo "snapshots retrieved (UTC): $(cat "$SNAP/RETRIEVED-UTC.txt")"
else
  echo "SKIP  snapshots/ absent - every figure assertion skipped"
  echo "PASS=0 FAIL=0 SKIP=1 TOTAL=1"
  exit 0
fi
echo

python3 "$HERE/r58-assert-figures.py" "$SNAP"
