#!/usr/bin/env bash
# R69 evidence, source fetcher. Downloads the upstream files read at an exact
# version, tag or commit, into review/evidence/sources/ -- which is NOT
# committed, for two reasons: it is third-party source (one of it, bacon, is
# AGPL-3.0, and the owner's 2026-09-12 ruling does not touch the rule against
# committing third-party copyleft files INTO this repository), and every file
# here is fetched at an immutable coordinate, so re-fetching reproduces it
# exactly. assert-figures.sh calls this script automatically when the files are
# absent, so an auditor runs assert-figures.sh and nothing else.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$HERE/../evidence/sources"
UA='https://github.com/smorinlabs/rs-launch-blueprint'
mkdir -p "$SRC/artifacts"
rc=0

get() { # get <url> <outfile>
  local code
  code=$(curl -sS -L --max-time 120 -H "User-Agent: $UA" -w '%{http_code}' -o "$2.tmp" "$1") \
    || { echo "FETCH-ERR $1"; rc=1; rm -f "$2.tmp"; return 1; }
  printf '%s' "$code" > "$2.httpcode"; mv "$2.tmp" "$2"
  echo "  $code  $1"
}
dl() { # dl <name> <version> -- a published .crate is immutable once released
  local n="$1" v="$2"
  [ -d "$SRC/artifacts/$n-$v" ] && { echo "  cached $n $v"; return 0; }
  curl -sS -L --max-time 180 -H "User-Agent: $UA" \
    -o "$SRC/artifacts/$n-$v.crate" "https://crates.io/api/v1/crates/$n/$v/download" \
    || { echo "DL-ERR $n $v"; rc=1; return 1; }
  ( cd "$SRC/artifacts" && tar xzf "$n-$v.crate" ) || { echo "UNTAR-ERR $n $v"; rc=1; return 1; }
  echo "  extracted $n $v"
}

echo "== published .crate artifacts, read at the exact recommended version =="
dl axum 0.8.9
dl tokio 1.53.1
dl bacon 3.25.0
dl watchexec-cli 2.7.2

echo "== upstream CI workflows at pinned tags (gate 4) =="
get "https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/.github/workflows/CI.yml"   "$SRC/ci-axum-v0.8.9.yml"
get "https://raw.githubusercontent.com/tokio-rs/tokio/tokio-1.53.1/.github/workflows/ci.yml" "$SRC/ci-tokio-1.53.1.yml"
get "https://raw.githubusercontent.com/Canop/bacon/v3.25.0/.github/workflows/tests.yml"      "$SRC/ci-bacon-v3.25.0.yml"

echo "== the reference implementation at commit 3df99c2 =="
B=https://raw.githubusercontent.com/rust-lang/crates.io/3df99c214d640090ab38aad14ae9c34289b0dec0
get "$B/Cargo.toml"                     "$SRC/cratesio-Cargo.toml"
get "$B/src/router.rs"                  "$SRC/cratesio-router.rs"
get "$B/src/bin/crates-io/server.rs"    "$SRC/cratesio-server.rs"
get "https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/graceful-shutdown/src/main.rs" "$SRC/axum-graceful-shutdown-example.rs"
get "https://raw.githubusercontent.com/watchexec/cargo-watch/v8.5.3/README.md" "$SRC/cargo-watch-README.md"

echo "fetch-sources rc=$rc"
exit $rc
