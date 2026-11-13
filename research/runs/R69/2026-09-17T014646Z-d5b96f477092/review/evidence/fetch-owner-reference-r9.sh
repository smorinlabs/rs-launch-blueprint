#!/usr/bin/env bash
# fetch-owner-reference-r9.sh — FETCHER, not a check.
#
# Revision 9 adds three rows to the reconciliation revision 6 began with the owner-supplied
# reference architecture `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
# (owner decision 11, 2026-09-16): the reference `Cargo.toml`'s
# `tokio = { version = "1", features = ["full"] }`, its `axum-extra` dependency, and its
# `[profile.release]` block. The brief drafter found all three carried no disposition.
#
# This script performs the two registry retrievals those rows need and writes a REDUCED
# snapshot of each — only the fields the decision cites — under
#     review/evidence/snapshots/r9/
# which IS committed. `owner-reference-check-r9.sh` then asserts against the committed
# snapshots and never touches the network, which is what makes that check rerunnable offline
# and byte-identical after this decision is committed. It is the same division of labour as
# `fetch-owner-reference-r6.sh` / `owner-reference-check-r6.sh`, and neither of those files is
# touched by revision 9.
#
# Only PUBLISHED CRATE METADATA is snapshotted — version, licence, declared `rust-version`,
# the `[features]` map and the dependency requirements, all served by the crates.io API. No
# third-party SOURCE file is written into this repository; the rule against committing
# third-party copyleft files, which the owner's 2026-09-12 ruling explicitly does not touch,
# is therefore not engaged.
#
# No personal email address appears in any request: the User-Agent names the repository, per
# the precedent set by R42 revision 7.
#
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C`): deliberate here — every `B` is an `echo` that cannot fail.
#   SC2016 (single-quoted expansion): the single-quoted `jq` programs must reach jq unexpanded.
#   SC2329 (function never invoked): `cleanup` is invoked indirectly by `trap cleanup EXIT`.
set -o pipefail
set -u

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OUT="$HERE/snapshots/r9"
UA="rs-launch-blueprint-research/R69 (+https://github.com/smorinlabs/rs-launch-blueprint)"
JQ="${JQ:-/opt/homebrew/bin/jq}"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/r69-r9-fetch.XXXXXX")"
cleanup() { rm -rf "$TMP"; }
trap cleanup EXIT

mkdir -p "$OUT"

get() { # get <url> <outfile> ; prints "<status> <effective-url>"
  curl -sSL -A "$UA" -w '%{http_code} %{url_effective}\n' "$1" -o "$2"
}

echo "== fetch-owner-reference-r9 =="
echo "user-agent: $UA"

# ----------------------------------------------- 1. tokio 1.53.1's own [features] map (row A)
# The reference Cargo.toml writes `tokio = { version = "1", features = ["full"] }`; this
# decision selects six named features. `full` is a feature tokio itself defines, so tokio's
# published metadata is the primary source for what it expands to.
get 'https://crates.io/api/v1/crates/tokio/1.53.1' "$TMP/tokio.json" \
  | { read -r st eff; echo "tokio 1.53.1: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://crates.io/api/v1/crates/tokio/1.53.1/dependencies' "$TMP/tokio-deps.json" \
  | { read -r st eff; echo "tokio 1.53.1 deps: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n --slurpfile t "$TMP/tokio.json" --slurpfile td "$TMP/tokio-deps.json" \
  '$t[0].version as $v
   | ["rt-multi-thread","net","signal","macros","time","sync"] as $selected
   | ($v.features.full) as $full
   | {
       source: "https://crates.io/api/v1/crates/tokio/1.53.1",
       num: $v.num, license: $v.license, rust_version: $v.rust_version, yanked: $v.yanked,
       default_feature: $v.features.default,
       full_feature: $full,
       full_feature_count: ($full | length),
       selected_by_this_decision: $selected,
       selected_count: ($selected | length),
       # what the six already imply: rt-multi-thread enables rt
       rt_multi_thread_expands_to: $v.features["rt-multi-thread"],
       # names in `full` that the six neither name nor imply through rt-multi-thread
       full_adds_beyond_selected:
         ($full - $selected - ($v.features["rt-multi-thread"] // [])),
       # the feature definitions those additions carry, for the dependency-cost reading
       definitions_of_additions:
         ([ ($full - $selected - ($v.features["rt-multi-thread"] // []))[]
            | {key: ., value: ($v.features[.] // [])} ] | from_entries),
       # `parking_lot` carries no feature body because it is the IMPLICIT feature an optional
       # dependency of that name creates; its cost is therefore a crate, not a code path.
       optional_dependency_additions:
         ([ $td[0].dependencies[]
            | select(.kind == "normal")
            | select(.crate_id == "parking_lot" or .crate_id == "bytes")
            | {key: .crate_id, value: {req: .req, optional: .optional}} ] | from_entries)
     }' > "$OUT/crates-tokio-features.json" || exit 1

# --------------------------------------------------------- 2. axum-extra 0.12.6 (row B)
get 'https://crates.io/api/v1/crates/axum-extra/0.12.6' "$TMP/axum-extra.json" \
  | { read -r st eff; echo "axum-extra 0.12.6: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://crates.io/api/v1/crates/axum-extra' "$TMP/axum-extra-crate.json" \
  | { read -r st eff; echo "axum-extra: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1
get 'https://crates.io/api/v1/crates/axum-extra/0.12.6/dependencies' "$TMP/axum-extra-deps.json" \
  | { read -r st eff; echo "axum-extra 0.12.6 deps: $st $eff"; [ "$st" = 200 ] || exit 1; } || exit 1

"$JQ" -n \
  --slurpfile v "$TMP/axum-extra.json" \
  --slurpfile c "$TMP/axum-extra-crate.json" \
  --slurpfile d "$TMP/axum-extra-deps.json" \
  '$v[0].version as $ver
   | ["cookie","cookie-private","typed-header"] as $ref_features
   | {
       source: "https://crates.io/api/v1/crates/axum-extra/0.12.6",
       source_crate: "https://crates.io/api/v1/crates/axum-extra",
       source_deps: "https://crates.io/api/v1/crates/axum-extra/0.12.6/dependencies",
       description: $c[0].crate.description,
       max_stable_version: $c[0].crate.max_stable_version,
       newest_version: $c[0].crate.newest_version,
       num: $ver.num, created_at: $ver.created_at, yanked: $ver.yanked,
       license: $ver.license, rust_version: $ver.rust_version,
       default_feature: $ver.features.default,
       features_the_reference_enables:
         ([ $ref_features[] | {key: ., value: ($ver.features[.] // null)} ] | from_entries),
       requirements:
         ([ $d[0].dependencies[]
            | select(.kind == "normal")
            | select(.crate_id == "axum" or .crate_id == "cookie" or .crate_id == "headers")
            | {key: .crate_id, value: {req: .req, optional: .optional}} ] | from_entries)
     }' > "$OUT/crates-axum-extra.json" || exit 1

date -u +%Y-%m-%dT%H:%M:%SZ > "$OUT/RETRIEVED-AT.txt"
echo "retrieved-at: $(cat "$OUT/RETRIEVED-AT.txt")"
echo "fetch-owner-reference-r9 rc=0"
