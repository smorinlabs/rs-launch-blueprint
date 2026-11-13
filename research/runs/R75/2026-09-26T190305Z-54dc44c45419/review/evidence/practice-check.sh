#!/usr/bin/env bash
# R75 check E5 — practice evidence and two inherited gate items, re-read at source:
# axum's own examples (request-id order, timeout status), crates.io's production middleware
# (timeout, access log, headers), tower-http's CI platform list (gate 4), and the `unsafe`
# posture of the crates the stack adds (gate 3). GitHub REST via authenticated `gh api`;
# crate sources from the private CARGO_HOME that probe-crate.sh populated.
set -uo pipefail
echo "== E5 practice-check — $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"

fetch() { # repo path -> decoded file on stdout, plus the blob sha on stderr-free first line
  local repo="$1" path="$2" sha
  sha="$(gh api "repos/$repo/commits?per_page=1&path=$path" --jq '.[0].sha' 2>/dev/null)" || sha="GAP"
  echo "SOURCE $repo/$path @ ${sha:-GAP}"
  gh api "repos/$repo/contents/$path" --jq '.content' 2>/dev/null | base64 -d 2>/dev/null \
    || echo "GAP $repo/$path"
}
show() { # label regex file-text
  local label="$1" re="$2" text="$3"
  grep -nE "$re" <<< "$text" | sed "s/^/$label /" || echo "$label (no match for: $re)"
}

t="$(fetch tokio-rs/axum examples/request-id/src/main.rs)"; head -1 <<< "$t"
show AXUM-REQUEST-ID 'set_x_request_id|propagate_x_request_id|TraceLayer|info_span' "$t"
t="$(fetch tokio-rs/axum examples/graceful-shutdown/src/main.rs)"; head -1 <<< "$t"
show AXUM-GRACEFUL 'TimeoutLayer|REQUEST_TIMEOUT|from_secs' "$t"
t="$(fetch rust-lang/crates.io src/middleware.rs)"; head -1 <<< "$t"
show CRATESIO-MIDDLEWARE 'TimeoutLayer|StatusCode::|from_secs|CatchPanicLayer|log_request|common_headers|ServiceBuilder' "$t"
t="$(fetch rust-lang/crates.io src/middleware/common_headers.rs)"; head -1 <<< "$t"
show CRATESIO-HEADERS 'STRICT_TRANSPORT|X_CONTENT_TYPE|X_FRAME|REFERRER|CONTENT_SECURITY' "$t"
t="$(fetch rust-lang/crates.io Cargo.toml)"; head -1 <<< "$t"
show CRATESIO-CARGO '^tower-http|^axum =' "$t"
t="$(fetch tower-rs/tower-http .github/workflows/CI.yml)"; head -1 <<< "$t"
show TOWER-HTTP-CI 'os:|ubuntu|macos|windows|msrv|rust-version|cargo hack' "$t"

src="$(find "$CARGO_HOME/registry/src" -mindepth 1 -maxdepth 1 -type d | head -1)"
for c in tower-http-0.7.1 tracing-0.1.44 uuid-1.26.1 axum-0.8.9; do
  attr="$(grep -hoE '#!\[(deny|forbid)\(unsafe_code\)\]' "$src/$c/src/lib.rs" | head -1)"
  n="$(grep -rE '\bunsafe (fn|impl|\{)|unsafe\s*\{' "$src/$c/src" | wc -l | tr -d ' ')"
  echo "UNSAFE $c crate_attr=${attr:-none} unsafe_sites=$n"
done
echo "== end"
