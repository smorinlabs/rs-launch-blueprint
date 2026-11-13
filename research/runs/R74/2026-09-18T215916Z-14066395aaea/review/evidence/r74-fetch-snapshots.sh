#!/usr/bin/env bash
# R74 — fetch every live payload this decision reads, into a snapshot directory.
#
# Revision 2: the target directory is $R74_SNAP_DIR (default: snapshots-r2/, next to this
# script). The revision-1 payloads in snapshots/ (retrieved 2026-09-19) are never
# overwritten; r74-registry-figures.sh reads both sets and reports the drift between them.
#
# This script TOUCHES THE NETWORK and OVERWRITES whatever is in the target directory. Its own output is
# therefore NOT reproducible byte-for-byte: download counters, star counts and
# pushed_at timestamps move. It exists so an auditor can re-fetch and see the drift.
# Every ASSERTION this decision makes is in r74-registry-figures.sh, which reads the
# committed snapshots and touches no network, and is reproducible byte-for-byte.
#
# GitHub: one request per 20 seconds (repo policy). crates.io: one per second.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="${R74_SNAP_DIR:-$HERE/snapshots-r2}"
UA="rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)"
MANIFEST="$SNAP/MANIFEST.tsv"

mkdir -p "$SNAP"
printf 'file\tendpoint\tretrieved_utc\n' > "$MANIFEST"

note() {
  # note <file> <endpoint>
  printf '%s\t%s\t%s\n' "$1" "$2" "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" >> "$MANIFEST"
  echo "SAVED $1  <- $2"
}

cio() {
  # cio <outfile> <path-after-/api/v1/>
  local out="$1" path="$2" url
  url="https://crates.io/api/v1/$path"
  curl -sS --fail-with-body -A "$UA" "$url" -o "$SNAP/$out"
  note "$out" "$url"
  sleep 1
}

ghapi() {
  # ghapi <outfile> <gh-api-path>  — 20 s spacing, enforced before each call
  local out="$1" path="$2"
  sleep 20
  if gh api "$path" > "$SNAP/$out" 2> "$SNAP/$out.err"; then
    rm -f "$SNAP/$out.err"
  else
    mv "$SNAP/$out.err" "$SNAP/$out"
  fi
  note "$out" "https://api.github.com/$path"
}

echo "=== crates.io: crate endpoints ==="
for c in tower-rate-limiter tower_governor governor axum-governor axum_gcra gcra axum tower tower-resilience-ratelimiter loco-rs; do
  cio "cio-crate-$c.json" "crates/$c"
done

echo "=== crates.io: versions endpoints ==="
for c in tower-rate-limiter tower_governor governor axum-governor axum_gcra gcra axum tower tower-resilience-ratelimiter; do
  cio "cio-versions-$c.json" "crates/$c/versions"
done

echo "=== crates.io: reverse-dependency totals ==="
for c in tower-rate-limiter tower_governor governor axum-governor axum_gcra gcra; do
  cio "cio-revdeps-$c.json" "crates/$c/reverse_dependencies?per_page=1"
done

echo "=== crates.io: first page of reverse dependencies, for the named adopters (revision 2) ==="
# The Muse leg names adopters of governor and tower_governor; a per_page=1 total cannot
# show them, so one 100-row page of each is kept.
for c in governor tower_governor; do
  cio "cio-revdeps-page-$c.json" "crates/$c/reverse_dependencies?per_page=100"
done

echo "=== RustSec package pages (status code only) ==="
: > "$SNAP/rustsec-status.txt"
for c in tower-rate-limiter tower_governor governor axum-governor gcra axum_gcra dashmap; do
  code="$(curl -sS -o /dev/null -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$c.html")"
  printf '%s %s\n' "$c" "$code" >> "$SNAP/rustsec-status.txt"
  sleep 1
done
note "rustsec-status.txt" "https://rustsec.org/packages/<name>.html"

echo "=== current stable toolchain ==="
curl -sS --fail-with-body -A "$UA" https://static.rust-lang.org/dist/channel-rust-stable.toml \
  | /usr/bin/grep -A2 '^\[pkg\.rust\]' > "$SNAP/channel-rust-stable-pkg-rust.txt"
note "channel-rust-stable-pkg-rust.txt" "https://static.rust-lang.org/dist/channel-rust-stable.toml"

echo "=== GitHub REST (20 s apart) ==="
ghapi "gh-repo-boinkor-net-governor.json"          "repos/boinkor-net/governor"
ghapi "gh-repo-benwis-tower-governor.json"         "repos/benwis/tower-governor"
ghapi "gh-repo-nivek-ph-tower-rate-limiter.json"   "repos/nivek-ph/tower-rate-limiter"
ghapi "gh-repo-canmi21-axum-governor.json"         "repos/canmi21/axum-governor"
ghapi "gh-contents-governor-Cargo.toml.json"       "repos/boinkor-net/governor/contents/governor/Cargo.toml"
ghapi "gh-contents-tower-governor-Cargo.toml.json" "repos/benwis/tower-governor/contents/Cargo.toml"
ghapi "gh-contents-trl-Cargo.toml.json"            "repos/nivek-ph/tower-rate-limiter/contents/Cargo.toml"
ghapi "gh-issues-open-tower-governor.json"         "search/issues?q=repo:benwis/tower-governor+is:issue+is:open"
ghapi "gh-issues-open-tower-rate-limiter.json"     "search/issues?q=repo:nivek-ph/tower-rate-limiter+is:issue+is:open"

echo "=== org REST API Design Standard — pinned blob excerpts ==="
STD_REPO="/Users/stevemorin/c/rest-standards"
STD_BLOB="71bd813c1cf61286586b4ee41ed83ff065e5c8d9"
if [ -e "$STD_REPO/.git" ]; then
  git -C "$STD_REPO" cat-file blob "$STD_BLOB" > "$SNAP/rest-api-standard.md"
  note "rest-api-standard.md" "git -C $STD_REPO cat-file blob $STD_BLOB"
else
  echo "SKIP rest-api-standard.md — $STD_REPO is not a git repository here"
fi

echo
echo "Snapshot manifest:"
cat "$MANIFEST"
