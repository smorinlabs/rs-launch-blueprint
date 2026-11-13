#!/usr/bin/env bash
# Fetch the live registry, GitHub and RustSec figures R58's decision cites and
# write them as snapshots under review/evidence/snapshots/. The snapshots are
# committed; r58-figures.sh asserts against them, so that the assertions stay
# reproducible byte-for-byte after the live counters have moved.
#
# This script is the provenance record for the snapshots, NOT a reproducible
# check: rerunning it rewrites the snapshots with whatever the endpoints say
# today. GitHub calls are paced at one per 21 seconds (>= the 20 s floor this
# programme requires). Authentication is the machine's keyring `gh` session; no
# token byte is read, echoed or written by this script.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
mkdir -p "$SNAP"
UA='rs-launch-blueprint-R58 (https://github.com/smorinlabs/rs-launch-blueprint)'

crates=(tracing tracing-core tracing-subscriber tracing-log tracing-serde log
        env_logger fern log4rs slog tracing-opentelemetry tracing-bunyan-formatter
        tracing-tree tracing-stackdriver fastrace logforth redactable
        tracing-appender secrecy)

for c in "${crates[@]}"; do
  curl -sSfL -H "User-Agent: $UA" "https://crates.io/api/v1/crates/${c}" \
    -o "$SNAP/cratesio-${c}.json"
  sleep 1
  curl -sSfL -H "User-Agent: $UA" "https://crates.io/api/v1/crates/${c}/versions?per_page=40" \
    -o "$SNAP/cratesio-${c}-versions.json"
  sleep 1
  curl -sSfL -H "User-Agent: $UA" \
    "https://crates.io/api/v1/crates/${c}/reverse_dependencies?per_page=1" \
    -o "$SNAP/cratesio-${c}-revdeps.json"
  sleep 1
  echo "crates.io: ${c}"
done

gh_api() {  # $1 = endpoint, $2 = output file
  gh api "$1" > "$2"
  echo "github: $1"
  sleep 21
}

gh_api "repos/tokio-rs/tracing" "$SNAP/gh-repo-tokio-rs-tracing.json"
gh_api "repos/tokio-rs/tracing-opentelemetry" "$SNAP/gh-repo-tokio-rs-tracing-opentelemetry.json"
gh_api "search/issues?q=repo:tokio-rs/tracing+is:issue+is:open" \
  "$SNAP/gh-search-open-issues-tracing.json"
gh_api "repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60" \
  "$SNAP/gh-issues-tracing.json"

# The ten most recently opened issues, pull requests filtered out.
python3 "$HERE/r58-sample-issues.py" "$SNAP/gh-issues-tracing.json" \
  > "$SNAP/gh-responsiveness-sample.txt"
while read -r n; do
  [ -n "$n" ] || continue
  gh_api "repos/tokio-rs/tracing/issues/${n}/comments?per_page=100" \
    "$SNAP/gh-issue-${n}-comments.json"
done < "$SNAP/gh-responsiveness-sample.txt"

for p in tracing tracing-core tracing-subscriber tracing-log log env_logger fern log4rs slog redactable; do
  code=$(curl -sS -o "$SNAP/rustsec-${p}.html" -w '%{http_code}' \
    -H "User-Agent: $UA" "https://rustsec.org/packages/${p}.html" || true)
  echo "rustsec: ${p} http=${code}"
  echo "$code" > "$SNAP/rustsec-${p}.http"
  sleep 1
done

for a in RUSTSEC-2023-0078 RUSTSEC-2025-0055; do
  curl -sSfL -H "User-Agent: $UA" "https://rustsec.org/advisories/${a}.html" \
    -o "$SNAP/rustsec-advisory-${a}.html"
  echo "rustsec advisory: ${a}"
  sleep 1
done

date -u '+%Y-%m-%dT%H:%M:%SZ' > "$SNAP/RETRIEVED-UTC.txt"
echo "snapshots written to $SNAP"
