#!/usr/bin/env bash
# R80 health-probe-endpoints — empirical check, part 3 of 3: the live sources.
#
# Re-verifies at their recorded endpoints the figures and quotations raw/opus.md
# rests on: the Kubernetes probe contract, the crates.io version and MSRV facts
# that decide gate 2, the RustSec advisory state, the maintainers' own
# documentation for the build-script family, and the two production probe
# implementations read at a URL.
#
#   bash check-live.sh              # fetch live, refresh ./snapshots, assert
#   bash check-live.sh --snapshots  # assert against the committed ./snapshots
#
# The counters crates.io and GitHub report move between runs, so the assertions
# below are on STRUCTURE and on PINS (version strings, null-ness, HTTP status,
# quoted sentences), never on a download total. Every moving figure is printed
# with its endpoint so a reader can see what it was when the log was written.
#
# Exit status: 0 when no check FAILs, 1 otherwise.

set -euo pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "$0")" && pwd)"
SNAP="$HERE/snapshots"
UA='rs-launch-blueprint-research (+https://github.com/smorinlabs/rs-launch-blueprint)'
MODE=fetch
if [ "${1:-}" = "--snapshots" ]; then MODE=snapshots; fi

PASS=0
FAIL=0
SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

echo "=== R80 check-live.sh (mode: $MODE) ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "curl: $(curl --version 2>/dev/null | head -1 || echo absent)"
echo "jq: $(jq --version 2>/dev/null || echo absent)"
echo "user-agent: $UA"
mkdir -p "$SNAP"

HAVE_NET=1
if [ "$MODE" = fetch ]; then
  if ! command -v curl >/dev/null 2>&1 || ! command -v jq >/dev/null 2>&1; then
    HAVE_NET=0
  elif ! curl -sS -m 20 -o /dev/null -A "$UA" https://crates.io/api/v1/crates/serde; then
    HAVE_NET=0
  fi
fi

# get <snapshot-name> <url> -> writes $SNAP/<name> and echoes the HTTP status
get() {
  local name="$1" url="$2" code
  if [ "$MODE" = snapshots ] || [ "$HAVE_NET" -eq 0 ]; then
    if [ -f "$SNAP/$name.status" ]; then cat "$SNAP/$name.status"; else echo 000; fi
    return 0
  fi
  code="$(curl -sS -m 40 -A "$UA" -w '%{http_code}' -o "$SNAP/$name" "$url" || echo 000)"
  printf '%s' "$code" >"$SNAP/$name.status"
  printf '%s' "$code"
}

# gh_get <snapshot-name> <api-path> — keyring-authenticated, never faster than
# one call per 20 s, and the token bytes never reach a file or this log.
GH_LAST=0
gh_get() {
  local name="$1" path="$2" now wait
  if [ "$MODE" = snapshots ] || [ "$HAVE_NET" -eq 0 ] || ! command -v gh >/dev/null 2>&1; then
    if [ -f "$SNAP/$name.status" ]; then cat "$SNAP/$name.status"; else echo 000; fi
    return 0
  fi
  now="$(date +%s)"
  if [ "$GH_LAST" -ne 0 ]; then
    wait=$((21 - (now - GH_LAST)))
    if [ "$wait" -gt 0 ]; then sleep "$wait"; fi
  fi
  GH_LAST="$(date +%s)"
  if gh api "$path" >"$SNAP/$name" 2>"$SNAP/$name.err"; then
    printf '200' >"$SNAP/$name.status"
  else
    # gh prints the HTTP status in its error text; 422 is a real observation here.
    if $GREP -qF 'HTTP 422' "$SNAP/$name.err"; then printf '422' >"$SNAP/$name.status";
    else printf '000' >"$SNAP/$name.status"; fi
  fi
  cat "$SNAP/$name.status"
}

# Two source families answer with bodies far larger than the facts read out of
# them (crates.io returns every version ever published; a kubernetes.io page is
# half a megabyte of site chrome). A fetched snapshot of those is REDUCED in
# place, to the documented projection below, before any assertion runs — so the
# committed artifact and the artifact the assertions read are the same bytes in
# both modes. Nothing else is reduced.
reduce_json() { # snapshot-name, jq filter
  [ "$MODE" = fetch ] || return 0
  [ -s "$SNAP/$1" ] || return 0
  if jq "$2" "$SNAP/$1" >"$SNAP/$1.tmp" 2>/dev/null; then mv "$SNAP/$1.tmp" "$SNAP/$1";
  else rm -f "$SNAP/$1.tmp"; fi
}
reduce_lines() { # snapshot-name, extended regex of lines to keep
  [ "$MODE" = fetch ] || return 0
  [ -s "$SNAP/$1" ] || return 0
  { echo "<!-- reduced snapshot: only lines matching /$2/ are kept -->"
    $GREP -E "$2" "$SNAP/$1" || true
  } >"$SNAP/$1.tmp"
  mv "$SNAP/$1.tmp" "$SNAP/$1"
}

if [ "$MODE" = fetch ] && [ "$HAVE_NET" -eq 0 ]; then
  echo "NOTE: no reachable network (or curl/jq absent); falling back to the committed snapshots"
fi

# --------------------------------------------------------------- L1 ----------
# The version pins every member of the recommendation names.
declare -a PINNED=(
  "serde 1.0.229" "serde_json 1.0.151" "axum 0.8.9" "tokio 1.53.1"
  "built 0.8.1" "vergen 10.0.3" "shadow-rs 2.0.0" "git-version 0.3.9"
)
L1_BAD=0
for entry in "${PINNED[@]}"; do
  read -r crate pin <<<"$entry"
  code="$(get "cratesio-$crate.json" "https://crates.io/api/v1/crates/$crate")"
  reduce_json "cratesio-$crate.json" '{crate: {name: .crate.name, newest_version: .crate.newest_version, max_stable_version: .crate.max_stable_version, recent_downloads: .crate.recent_downloads, downloads: .crate.downloads, repository: .crate.repository}}'
  if [ "$code" != 200 ] || [ ! -s "$SNAP/cratesio-$crate.json" ]; then
    echo "  $crate: HTTP $code (no body)"; L1_BAD=$((L1_BAD + 1)); continue
  fi
  newest="$(jq -r '.crate.newest_version' "$SNAP/cratesio-$crate.json")"
  maxstable="$(jq -r '.crate.max_stable_version' "$SNAP/cratesio-$crate.json")"
  recent="$(jq -r '.crate.recent_downloads' "$SNAP/cratesio-$crate.json")"
  total="$(jq -r '.crate.downloads' "$SNAP/cratesio-$crate.json")"
  printf '  %-12s pinned=%-8s newest=%-8s max_stable=%-8s recent_downloads=%-12s downloads=%s\n' \
    "$crate" "$pin" "$newest" "$maxstable" "$recent" "$total"
  if [ "$maxstable" != "$pin" ]; then L1_BAD=$((L1_BAD + 1)); fi
done
if [ "$L1_BAD" -eq 0 ]; then
  pass L1 "GET https://crates.io/api/v1/crates/<name>: max_stable_version still equals the pin this decision names for all eight crates (download counters move and are printed, not asserted)"
else
  fail L1 "$L1_BAD of 8 crates no longer sit at the pinned max_stable_version, or could not be fetched"
fi

# --------------------------------------------------------------- L2 ----------
# Fitness gate 2's load-bearing fact: shadow-rs and git-version declare no
# minimum Rust version, so they are EXCLUDED under the strict reading the owner
# adopted; built and vergen declare one.
declare -a MSRV=( "shadow-rs null" "git-version null" "built 1.87" "vergen 1.96.0" )
L2_BAD=0
for entry in "${MSRV[@]}"; do
  read -r crate want <<<"$entry"
  code="$(get "cratesio-$crate-versions.json" "https://crates.io/api/v1/crates/$crate/versions")"
  reduce_json "cratesio-$crate-versions.json" '{versions: [.versions[] | {num, yanked, rust_version, created_at}][0:20]}'
  if [ "$code" != 200 ] || [ ! -s "$SNAP/cratesio-$crate-versions.json" ]; then
    echo "  $crate/versions: HTTP $code"; L2_BAD=$((L2_BAD + 1)); continue
  fi
  got="$(jq -r '[.versions[] | select(.yanked == false)] | first | .rust_version // "null"' \
    "$SNAP/cratesio-$crate-versions.json")"
  num="$(jq -r '[.versions[] | select(.yanked == false)] | first | .num' "$SNAP/cratesio-$crate-versions.json")"
  created="$(jq -r '[.versions[] | select(.yanked == false)] | first | .created_at' "$SNAP/cratesio-$crate-versions.json")"
  printf '  %-12s newest non-yanked=%-8s created_at=%-26s rust_version=%s (expected %s)\n' \
    "$crate" "$num" "$created" "$got" "$want"
  if [ "$got" != "$want" ]; then L2_BAD=$((L2_BAD + 1)); fi
done
if [ "$L2_BAD" -eq 0 ]; then
  pass L2 "GET https://crates.io/api/v1/crates/<name>/versions: shadow-rs and git-version still return rust_version null on their newest non-yanked version (gate 2 exclusion holds), while built declares 1.87 and vergen 1.96.0"
else
  fail L2 "$L2_BAD of 4 declared-MSRV facts no longer hold"
fi

# --------------------------------------------------------------- L3 ----------
# RustSec, with atty as the positive control: a 404 means "no advisory page",
# which is only evidence if a known-vulnerable crate still answers 200.
ATTY="$(get rustsec-atty.html https://rustsec.org/packages/atty.html)"
L3_BAD=0
L3_NOTE=""
for crate in serde serde_json axum built vergen shadow-rs git-version; do
  code="$(get "rustsec-$crate.html" "https://rustsec.org/packages/$crate.html")"
  echo "  rustsec/$crate: HTTP $code (expected 404 = no advisory)"
  if [ "$code" != 404 ]; then L3_BAD=$((L3_BAD + 1)); L3_NOTE="$L3_NOTE $crate=$code"; fi
done
TOKIO_SEC="$(get rustsec-tokio.html https://rustsec.org/packages/tokio.html)"
echo "  rustsec/tokio: HTTP $TOKIO_SEC (expected 200 = historical entries exist)"
echo "  rustsec/atty (control): HTTP $ATTY (expected 200)"
if [ "$ATTY" = 200 ] && [ "$L3_BAD" -eq 0 ] && [ "$TOKIO_SEC" = 200 ]; then
  pass L3 "the atty control answers 200 while seven of the eight crates have no advisory page (404) and tokio's page exists — so the 404s are evidence, not an outage"
else
  fail L3 "the advisory picture changed (control=$ATTY, tokio=$TOKIO_SEC, unexpected:$L3_NOTE)"
fi

# --------------------------------------------------------------- L4 ----------
# tokio 1.53.1 is outside every Patched range of its newest advisory.
code="$(get rustsec-2025-0023.html https://rustsec.org/advisories/RUSTSEC-2025-0023.html)"
# The page HTML-escapes ">=" as "&#62;=", so the needle is written escaped. The
# load-bearing entry is the OPEN-ENDED range: it has no upper bound, so every
# version at or above 1.44.2 — 1.53.1 included — is patched.
if [ "$code" = 200 ]; then
  echo "  RUSTSEC-2025-0023 Patched entries:"
  $GREP -o '<code>&#62;=[^<]*</code>' "$SNAP/rustsec-2025-0023.html" | sed 's/^/    /' || true
fi
if [ "$code" = 200 ] && $GREP -qF '<code>&#62;=1.44.2</code>' "$SNAP/rustsec-2025-0023.html"; then
  pass L4 "RUSTSEC-2025-0023 lists an open-ended patched range '>=1.44.2' with no upper bound, so tokio 1.53.1 carries no open advisory"
else
  fail L4 "RUSTSEC-2025-0023 could not be read or no longer names an open-ended >=1.44.2 patched range (HTTP $code)"
fi

# --------------------------------------------------------------- L5 ----------
# Kubernetes is normative for what a probe MEANS; the whole contract hangs on
# these two sentences, so they are asserted verbatim rather than paraphrased.
K1="$(get k8s-probes.html https://kubernetes.io/docs/concepts/workloads/pods/probes/)"
K2="$(get k8s-configure-probes.html https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/)"
reduce_lines k8s-probes.html 'Liveness probes determine|Readiness probes determine|removes the Pod|Startup probes|cascading failures'
reduce_lines k8s-configure-probes.html 'greater than or equal to 200|livenessProbe|readinessProbe|path: /health'
K_OK=1
[ "$K1" = 200 ] || K_OK=0
[ "$K2" = 200 ] || K_OK=0
if [ "$K_OK" -eq 1 ]; then
  $GREP -qF 'Liveness probes determine when to restart a container' "$SNAP/k8s-probes.html" || K_OK=0
  $GREP -qF 'Readiness probes determine when a container is ready to accept traffic' "$SNAP/k8s-probes.html" || K_OK=0
  $GREP -qF 'removes the Pod' "$SNAP/k8s-probes.html" || K_OK=0
  $GREP -qF 'Any code greater than or equal to 200 and less than 400 indicates success' "$SNAP/k8s-configure-probes.html" || K_OK=0
fi
if [ "$K_OK" -eq 1 ]; then
  pass L5 "kubernetes.io still says liveness failure restarts the container, readiness failure removes the Pod from its EndpointSlices, and that any code in [200,400) is success — the three facts that fix this design"
else
  fail L5 "the Kubernetes probe pages could not be read or no longer carry the quoted sentences (probes=$K1, configure=$K2)"
fi

# --------------------------------------------------------------- L6 ----------
# The build-script family is excluded ON FIT by R49's no-build.rs clause. The
# maintainers' own documentation is what establishes that they need one.
declare -a READMES=(
  "built https://raw.githubusercontent.com/lukaslueg/built/master/README.md"
  "vergen https://raw.githubusercontent.com/rustyhorde/vergen/master/README.md"
  "shadow-rs https://raw.githubusercontent.com/baoyachi/shadow-rs/master/README.md"
)
L6_BAD=0
for entry in "${READMES[@]}"; do
  read -r crate url <<<"$entry"
  code="$(get "readme-$crate.md" "$url")"
  if [ "$code" = 200 ] && $GREP -qiF 'build.rs' "$SNAP/readme-$crate.md"; then
    hits="$($GREP -ciF 'build.rs' "$SNAP/readme-$crate.md" || true)"
    echo "  $crate README: HTTP 200, 'build.rs' on $hits line(s)"
  else
    echo "  $crate README: HTTP $code, no build.rs mention"; L6_BAD=$((L6_BAD + 1))
  fi
done
GV="$(get readme-git-version.md https://raw.githubusercontent.com/fusion-engineering/rust-git-version/master/git-version/README.md)"
if [ "$GV" = 200 ] && $GREP -qF "you must have \`git\` installed somewhere in your \`PATH\`" "$SNAP/readme-git-version.md"; then
  echo "  git-version README: HTTP 200, requires the git binary at compile time"
else
  echo "  git-version README: HTTP $GV, the git-binary sentence was not found"; L6_BAD=$((L6_BAD + 1))
fi
if [ "$L6_BAD" -eq 0 ]; then
  pass L6 "built, vergen and shadow-rs each instruct a Cargo build script in their own README — which R49's published no-build.rs clause excludes — and git-version requires a git binary and a .git tree a crates.io tarball does not have"
else
  fail L6 "$L6_BAD of 4 maintainer documents could not be read or no longer carry the stated requirement"
fi

# --------------------------------------------------------------- L7 ----------
# The two production probe implementations, read at a URL rather than asserted.
KUBERT="$(get kubert-admin.rs https://raw.githubusercontent.com/olix0r/kubert/main/kubert/src/admin.rs)"
K_OK=1
if [ "$KUBERT" = 200 ]; then
  $GREP -qF '/live' "$SNAP/kubert-admin.rs" || K_OK=0
  $GREP -qF '/ready' "$SNAP/kubert-admin.rs" || K_OK=0
  $GREP -qF 'AtomicBool' "$SNAP/kubert-admin.rs" || K_OK=0
  $GREP -qiF 'cannot be overridden' "$SNAP/kubert-admin.rs" || K_OK=0
else
  K_OK=0
fi
APOLLO="$(get apollo-healthcheck.rs https://raw.githubusercontent.com/apollographql/router/dev/apollo-router/src/plugins/healthcheck/mod.rs)"
A_OK=1
if [ "$APOLLO" = 200 ]; then
  $GREP -qF 'SERVICE_UNAVAILABLE' "$SNAP/apollo-healthcheck.rs" || A_OK=0
  $GREP -qF 'AtomicBool' "$SNAP/apollo-healthcheck.rs" || A_OK=0
  $GREP -qF "It's hard to get k8s to parse payloads" "$SNAP/apollo-healthcheck.rs" || A_OK=0
else
  A_OK=0
fi
if [ "$K_OK" -eq 1 ] && [ "$A_OK" -eq 1 ]; then
  pass L7 "both surveyed production systems still latch readiness in an AtomicBool — kubert hard-reserves /live and /ready ('cannot be overridden'), Apollo Router answers SERVICE_UNAVAILABLE and records in-source that k8s reads the status code, not the body"
else
  fail L7 "the production probe sources could not be read or changed (kubert HTTP $KUBERT ok=$K_OK, apollo HTTP $APOLLO ok=$A_OK)"
fi

# --------------------------------------------------------------- L8 ----------
# The census that answers the prompt's LOW question. The denominators move, so
# they are printed; what is asserted is that the one named HTTP-probe crate is
# still three orders of magnitude below the crates this template already uses.
L8_OK=1
for term in health probe liveness; do
  code="$(get "cratesio-search-$term.json" "https://crates.io/api/v1/crates?q=$term&per_page=12&sort=downloads")"
  reduce_json "cratesio-search-$term.json" '{meta: .meta, crates: [.crates[] | {name, recent_downloads, description}]}'
  if [ "$code" = 200 ]; then
    total="$(jq -r '.meta.total' "$SNAP/cratesio-search-$term.json")"
    echo "  q=$term: meta.total=$total; top 3 by downloads: $(jq -r '[.crates[0:3][].name] | join(", ")' "$SNAP/cratesio-search-$term.json")"
  else
    echo "  q=$term: HTTP $code"; L8_OK=0
  fi
done
RH="$(get cratesio-rocket_healthz.json https://crates.io/api/v1/crates/rocket_healthz)"
reduce_json cratesio-rocket_healthz.json '{crate: {name: .crate.name, newest_version: .crate.newest_version, max_stable_version: .crate.max_stable_version, recent_downloads: .crate.recent_downloads, downloads: .crate.downloads, updated_at: .crate.updated_at}}'
if [ "$RH" = 200 ]; then
  rh_recent="$(jq -r '.crate.recent_downloads' "$SNAP/cratesio-rocket_healthz.json")"
  serde_recent="$(jq -r '.crate.recent_downloads' "$SNAP/cratesio-serde.json")"
  echo "  rocket_healthz recent_downloads=$rh_recent vs serde recent_downloads=$serde_recent"
  if [ "$rh_recent" -lt 100000 ] && [ "$serde_recent" -gt 100000000 ]; then
    :
  else
    L8_OK=0
  fi
else
  echo "  rocket_healthz: HTTP $RH"; L8_OK=0
fi
if [ "$L8_OK" -eq 1 ]; then
  pass L8 "the crates.io census still shows no adopted first-class HTTP liveness/readiness crate: the only name-matched candidate, rocket_healthz, sits below 100,000 recent downloads while serde is above 100,000,000 — the absence is the finding"
else
  fail L8 "the census could not be reproduced or an adopted probe crate has appeared"
fi

# --------------------------------------------------------------- L9 ----------
# GitHub, keyring-authenticated, never faster than one call per 20 s. Only the
# four build-metadata repositories are queried here: the serde/axum/tokio figures
# are consumed from R66's and R69's published records, not re-collected.
declare -a REPOS=( lukaslueg/built rustyhorde/vergen baoyachi/shadow-rs fusion-engineering/rust-git-version )
L9_BAD=0
L9_422=0
for repo in "${REPOS[@]}"; do
  key="$(printf '%s' "$repo" | tr '/' '-')"
  code="$(gh_get "gh-repo-$key.json" "repos/$repo")"
  if [ "$code" = 200 ]; then
    printf '  %-38s stars=%-6s archived=%-6s pushed_at=%s\n' "$repo" \
      "$(jq -r '.stargazers_count' "$SNAP/gh-repo-$key.json")" \
      "$(jq -r '.archived' "$SNAP/gh-repo-$key.json")" \
      "$(jq -r '.pushed_at' "$SNAP/gh-repo-$key.json")"
    if [ "$(jq -r '.archived' "$SNAP/gh-repo-$key.json")" != "false" ]; then L9_BAD=$((L9_BAD + 1)); fi
  else
    echo "  $repo: HTTP $code"; L9_BAD=$((L9_BAD + 1))
  fi
  # The open-issue figure MUST come from the search endpoint; open_issues_count
  # counts pull requests too and the prompt forbids substituting it.
  scode="$(gh_get "gh-issues-$key.json" "search/issues?q=repo:$repo+is:issue+is:open")"
  if [ "$scode" = 200 ]; then
    echo "    open issues (search total_count): $(jq -r '.total_count' "$SNAP/gh-issues-$key.json")"
  elif [ "$scode" = 422 ]; then
    echo "    open issues: HTTP 422 'The listed users and repositories cannot be searched' — figure ABSENT, open_issues_count not substituted"
    L9_422=$((L9_422 + 1))
  else
    echo "    open issues: HTTP $scode"; L9_BAD=$((L9_BAD + 1))
  fi
done
if [ "$L9_BAD" -eq 0 ]; then
  pass L9 "all four build-metadata repositories answer 200 and report archived=false; $L9_422 of them refuse the issue-search endpoint with HTTP 422, and that figure is recorded absent rather than substituted"
else
  fail L9 "$L9_BAD GitHub reads failed or a repository is archived"
fi

printf '\n=== %d PASS, %d FAIL, %d SKIP ===\n' "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
