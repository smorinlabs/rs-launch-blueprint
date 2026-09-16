#!/usr/bin/env bash
# fetch-owner-reference-r6.sh — FETCHER, not a check.
#
# Revision 6 of R69 reconciles the owner-supplied reference architecture
# `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` row by row
# (owner decision 11, 2026-09-16). That document's own caveat says its patterns were
# "compiled in my head, not against the toolchain", so every fact revision 6 relies on
# from it is re-verified at a primary source. This script performs those retrievals and
# writes a REDUCED snapshot of each — only the fields the decision cites — under
#     review/evidence/snapshots/r6/
# which IS committed. `owner-reference-check-r6.sh` then asserts against the committed
# snapshots and never touches the network, which is what makes that check rerunnable
# offline and byte-identical after this decision is committed.
#
# This script is NOT a check: it makes no assertion about the decision and its output is
# not cited as evidence for any claim. It is the sibling of `fetch-figures.sh`.
#
# No personal email address appears in any request: the User-Agent names the repository,
# per the precedent set by R42 revision 7.
#
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C`): deliberate here — every `B` is an `echo` that cannot fail.
#   SC2016 (single-quoted expansion): the single-quoted `jq` programs must reach jq
#          unexpanded by the shell.
#   SC2329 (function never invoked): `cleanup` is invoked indirectly by `trap cleanup EXIT`.
set -o pipefail
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/snapshots/r6"
UA="rs-launch-blueprint-research/R69 (+https://github.com/smorinlabs/rs-launch-blueprint)"
JQ="${JQ:-/opt/homebrew/bin/jq}"
GREP=/usr/bin/grep
SED=/usr/bin/sed
TR=/usr/bin/tr

TMP="$(mktemp -d "${TMPDIR:-/tmp}/r69-r6-fetch.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

mkdir -p "$OUT"

get() { # get <url> <outfile> ; follows redirects, prints the effective URL and status
  local url="$1" dest="$2"
  curl -sSL -A "$UA" -H 'Accept: application/vnd.github+json' \
       -w '%{http_code} %{url_effective}\n' "$url" -o "$dest"
}

echo "== fetch-owner-reference-r6 =="
echo "user-agent: $UA"

# ---------------------------------------------------------------- 1. axum releases
# Row 1: the document's "axum 0.8.9 is the current, stable line and there is no 0.9/1.0".
get 'https://crates.io/api/v1/crates/axum/versions' "$TMP/axum-versions.json" \
  | { read -r st eff; echo "axum/versions: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://crates.io/api/v1/crates/axum' "$TMP/axum-crate.json" \
  | { read -r st eff; echo "axum: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n \
  --slurpfile v "$TMP/axum-versions.json" \
  --slurpfile c "$TMP/axum-crate.json" \
  '{
     source: "https://crates.io/api/v1/crates/axum/versions",
     source_crate: "https://crates.io/api/v1/crates/axum",
     versions_total: ($v[0].versions | length),
     max_version: $c[0].crate.max_version,
     max_stable_version: $c[0].crate.max_stable_version,
     newest_version: $c[0].crate.newest_version,
     newest_non_yanked: ([$v[0].versions[] | select(.yanked == false)][0]
        | {num, created_at, rust_version, license, yanked}),
     versions_0_9_or_later:
        ([$v[0].versions[].num
          | select(startswith("0.9") or startswith("1.") or startswith("2."))]),
     line_0_8_nums: ([$v[0].versions[].num | select(startswith("0.8"))])
   }' > "$OUT/crates-axum-versions.json" || exit 1

# ------------------------------------------------------- 2. axum-test (C12 test idiom)
# Row 5: the document ranks `axum-test 18` (stated as requiring axum >= 0.8.7) over
# `tower::ServiceExt::oneshot`. Both halves are checked at the registry.
get 'https://crates.io/api/v1/crates/axum-test' "$TMP/axum-test.json" \
  | { read -r st eff; echo "axum-test: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

for v in 18.0.0 18.3.0 18.7.0 21.1.0 22.0.0-rc.1; do
  get "https://crates.io/api/v1/crates/axum-test/$v/dependencies" "$TMP/dep-$v.json" \
    | { read -r st eff; echo "axum-test $v deps: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
done

"$JQ" -n \
  --slurpfile t "$TMP/axum-test.json" \
  --slurpfile d180 "$TMP/dep-18.0.0.json" \
  --slurpfile d183 "$TMP/dep-18.3.0.json" \
  --slurpfile d187 "$TMP/dep-18.7.0.json" \
  --slurpfile d211 "$TMP/dep-21.1.0.json" \
  --slurpfile d220 "$TMP/dep-22.0.0-rc.1.json" \
  'def axumreq($x): [$x[0].dependencies[]
                     | select(.crate_id == "axum" and .kind == "normal") | .req][0];
   {
     source: "https://crates.io/api/v1/crates/axum-test",
     source_deps: "https://crates.io/api/v1/crates/axum-test/<version>/dependencies",
     max_stable_version: $t[0].crate.max_stable_version,
     newest_version: $t[0].crate.newest_version,
     newest_non_yanked: ([$t[0].versions[] | select(.yanked == false)][0]
        | {num, created_at, rust_version, license, yanked}),
     newest_stable: ([$t[0].versions[]
        | select(.yanked == false and (.num | test("-") | not))][0]
        | {num, created_at, rust_version, license, yanked}),
     axum_requirement: {
       "18.0.0":      axumreq($d180),
       "18.3.0":      axumreq($d183),
       "18.7.0":      axumreq($d187),
       "21.1.0":      axumreq($d211),
       "22.0.0-rc.1": axumreq($d220)
     },
     rust_version: ([$t[0].versions[]
        | select(.num == "18.0.0" or .num == "18.7.0" or .num == "21.1.0"
                 or .num == "22.0.0-rc.1")
        | {key: .num, value: .rust_version}] | from_entries)
   }' > "$OUT/crates-axum-test.json" || exit 1

# ---------------------------------------- 3. the axum 0.9 timeline statement (row 1)
get 'https://api.github.com/repos/tokio-rs/axum/issues/3809' "$TMP/i3809.json" \
  | { read -r st eff; echo "axum#3809: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://api.github.com/repos/tokio-rs/axum/issues/3809/comments?per_page=20' "$TMP/c3809.json" \
  | { read -r st eff; echo "axum#3809 comments: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n --slurpfile i "$TMP/i3809.json" --slurpfile c "$TMP/c3809.json" \
  '{ source: "https://api.github.com/repos/tokio-rs/axum/issues/3809",
     html_url: $i[0].html_url,
     number: $i[0].number, state: $i[0].state, title: $i[0].title,
     created_at: $i[0].created_at, closed_at: $i[0].closed_at,
     is_pull_request: ($i[0] | has("pull_request")),
     comments: [$c[0][] | {login: .user.login, author_association, created_at, body}] }' \
  > "$OUT/gh-axum-issue-3809.json" || exit 1

# ------------------------------- 4. axum#3003, the WebSocket graceful-shutdown hazard
get 'https://api.github.com/repos/tokio-rs/axum/issues/3003' "$TMP/i3003.json" \
  | { read -r st eff; echo "axum#3003: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n --slurpfile i "$TMP/i3003.json" \
  '{ source: "https://api.github.com/repos/tokio-rs/axum/issues/3003",
     html_url: $i[0].html_url,
     number: $i[0].number, state: $i[0].state, title: $i[0].title,
     created_at: $i[0].created_at, closed_at: $i[0].closed_at,
     is_pull_request: ($i[0] | has("pull_request")),
     reported_against_version:
       ($i[0].body | capture("### Version\\s+(?<v>[^\\n]+)").v | gsub("^\\s+|\\s+$"; "")),
     body_excerpt:
       ($i[0].body | capture("(?<x>The task spawned in[^\\n]+)").x) }' \
  > "$OUT/gh-axum-issue-3003.json" || exit 1

# --------------------------------- 5. the unreleased-0.9 state: release PR and 0.9 work
get 'https://api.github.com/repos/tokio-rs/axum/pulls/3745' "$TMP/p3745.json" \
  | { read -r st eff; echo "axum#3745: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://api.github.com/repos/tokio-rs/axum/pulls/3819' "$TMP/p3819.json" \
  | { read -r st eff; echo "axum#3819: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n --slurpfile p "$TMP/p3745.json" \
  '{ source: "https://api.github.com/repos/tokio-rs/axum/pulls/3745",
     html_url: $p[0].html_url,
     number: $p[0].number, state: $p[0].state, title: $p[0].title,
     merged: $p[0].merged, merged_at: $p[0].merged_at,
     created_at: $p[0].created_at, closed_at: $p[0].closed_at,
     proposed_axum_bump:
       ($p[0].body | capture("`axum`: (?<x>[0-9.]+ -> [0-9.]+)").x),
     breaking_symbols:
       [$p[0].body | splits("\n") | select(test("^  (function|trait|type) "))
        | gsub("^\\s+|\\s+$"; "")] }' \
  > "$OUT/gh-axum-pr-3745.json" || exit 1

"$JQ" -n --slurpfile p "$TMP/p3819.json" \
  '{ source: "https://api.github.com/repos/tokio-rs/axum/pulls/3819",
     html_url: $p[0].html_url,
     number: $p[0].number, state: $p[0].state, title: $p[0].title,
     created_at: $p[0].created_at, closed_at: $p[0].closed_at,
     milestone: $p[0].milestone.title }' \
  > "$OUT/gh-axum-pr-3819.json" || exit 1

# ---------------------------------------- 6. Google's Cloud Run container runtime contract
# Row 4: the document quotes a 10-second SIGTERM-to-SIGKILL window. The published sentence
# wraps across several source lines, so the extraction collapses whitespace first.
CR_URL='https://cloud.google.com/run/docs/container-contract'
read -r CR_STATUS CR_EFF < <(get "$CR_URL" "$TMP/cloudrun.html") || exit 1
echo "cloud-run contract: $CR_STATUS $CR_EFF"
[ "$CR_STATUS" = 200 ] || exit 1

"$SED" -e 's/<[^>]*>/ /g' "$TMP/cloudrun.html" \
  | "$SED" -e 's/&#39;/'"'"'/g; s/&quot;/"/g; s/&amp;/\&/g' \
  | "$TR" -s ' \n' '  ' > "$TMP/cloudrun.txt" || exit 1
{
  echo "requested_url: $CR_URL"
  echo "effective_url: $CR_EFF"
  echo "http_status: $CR_STATUS"
  echo "section: Container instance lifecycle > Shutdown (For services)"
  echo "services_sentence:"
  "$GREP" -o -E 'Before shutting down an instance[^.]*SIGKILL signal\.' "$TMP/cloudrun.txt" || exit 1
  echo "jobs_sentence:"
  "$GREP" -o -E "If the instance doesn't shut down on its own within a few seconds after receiving SIGTERM , Cloud Run sends a SIGKILL signal for a forced termination \." "$TMP/cloudrun.txt" || exit 1
} > "$OUT/gcp-cloudrun-container-contract.txt" || exit 1

# ----------------------------------- 7. Cargo's default (caret) version-requirement rule
# Row 1: whether a bare `"0.8.9"` already excludes 0.9, which is the document's only
# stated reason for advising an `=` pin.
CARGO_URL='https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html'
read -r CG_STATUS CG_EFF < <(get "$CARGO_URL" "$TMP/cargo-dep.html") || exit 1
echo "cargo specifying-dependencies: $CG_STATUS $CG_EFF"
[ "$CG_STATUS" = 200 ] || exit 1

"$SED" -e 's/<[^>]*>/ /g' "$TMP/cargo-dep.html" \
  | "$SED" -e 's/&gt;/>/g; s/&lt;/</g' | "$TR" -s ' \n' '  ' > "$TMP/cargo-dep.txt" || exit 1
{
  echo "requested_url: $CARGO_URL"
  echo "effective_url: $CG_EFF"
  echo "http_status: $CG_STATUS"
  echo "section: Version requirement syntax > Default requirements / Caret requirements"
  echo "default_requirement_table_row:"
  "$GREP" -o -E '0\.2\.3 := >=0\.2\.3, <0\.3\.0' "$TMP/cargo-dep.txt" | head -1 || exit 1
  echo "caret_is_default:"
  "$GREP" -o -E 'Caret requirements are the default version requirement strategy\.' "$TMP/cargo-dep.txt" | head -1 || exit 1
  echo "bare_equals_caret:"
  "$GREP" -o -E 'Leaving off the caret is a simplified equivalent syntax to using caret requirements\.' "$TMP/cargo-dep.txt" | head -1 || exit 1
} > "$OUT/cargo-specifying-dependencies.txt" || exit 1

date -u +%Y-%m-%dT%H:%M:%SZ > "$OUT/RETRIEVED-AT.txt"
echo "retrieved-at: $(cat "$OUT/RETRIEVED-AT.txt")"
echo "fetch-owner-reference-r6 rc=0"
