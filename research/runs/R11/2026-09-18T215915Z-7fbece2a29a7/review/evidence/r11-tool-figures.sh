#!/usr/bin/env bash
# R11 check 6 - the figures for the one crate any part of this decision names,
# and for the two third-party detector actions it compares, asserted OFFLINE
# against JSON snapshots committed under review/evidence/snapshots/.
#
# Each snapshot carries its own endpoint and UTC retrieval time as fields, so
# the log below is reproducible byte-for-byte while the live counters move.
# The snapshots were taken on 2026-09-18 by this run; the figures were NOT
# carried from the Opus raw report, they were re-derived and then found to
# agree with it, which is recorded under ## Engines.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SNAP="$HERE/snapshots"
PASS=0; FAIL=0; SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s\n' "$*"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s\n' "$*"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s\n' "$*"; }

if ! command -v jq >/dev/null 2>&1; then
  skip "T0 jq is not on PATH - every figure assertion in this script is unrun"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
  exit 1
fi

# field <id> <snapshot> <jq filter> <expected> <what it establishes>
field() {
  f_id="$1"; f_snap="$2"; f_jq="$3"; f_want="$4"; f_says="$5"
  if [ ! -f "$SNAP/$f_snap" ]; then
    skip "$f_id snapshot $f_snap is absent, so this figure is unrun"
    return
  fi
  f_got="$(jq -r "$f_jq" "$SNAP/$f_snap")"
  if [ "$f_got" = "$f_want" ]; then
    pass "$f_id $f_snap $f_jq = $f_got ($(jq -r .retrieved_utc "$SNAP/$f_snap")) - $f_says"
  else
    fail "$f_id $f_snap $f_jq = '$f_got', recorded '$f_want' - the snapshot has changed since the decision cited it"
  fi
}

# --- cargo-hack: the crate the reference floor command names ---------------
field T1 cargo-hack-crate.json .recent_downloads 219720 \
  "90-day downloads, crate.recent_downloads"
field T2 cargo-hack-crate.json .downloads 1893214 \
  "all-time downloads, crate.downloads"
field T3 cargo-hack-versions.json .newest_non_yanked.num 0.6.45 \
  "newest non-yanked version"
field T4 cargo-hack-versions.json .newest_non_yanked.created_at 2026-05-30T14:50:51.511255Z \
  "its release date - inside six months of this decision, so the no-release-in-6-months trigger does not fire"
field T5 cargo-hack-versions.json .newest_non_yanked.license "Apache-2.0 OR MIT" \
  "recorded only; fitness gate 1 is inapplicable under the owner ruling of 2026-09-12 (Q7.B)"
field T6 cargo-hack-versions.json .newest_non_yanked.rust_version 1.85 \
  "its own declared rust-version, relevant to gate 2 only if the MSRV gate reaches a non-linked developer tool at all, which is an open owner question"
field T7 cargo-hack-repo.json .stargazers_count 862 \
  "stars"
field T8 cargo-hack-repo.json .archived false \
  "not archived"
field T9 cargo-hack-repo.json .pushed_at 2026-09-02T12:45:59Z \
  "last push - sixteen days before this decision, so maintenance state is active"
field T10 cargo-hack-open-issues.json .total_count 35 \
  "open issues, from search/issues total_count and never open_issues_count"

# --- dorny/paths-filter: the ranked runner-up detector mechanism -----------
field T11 dorny-paths-filter-repo.json .stargazers_count 3337 \
  "stars - the long-standing third-party detector action"
field T12 dorny-paths-filter-repo.json .archived false \
  "not archived"
field T13 dorny-paths-filter-repo.json .pushed_at 2026-08-05T12:20:34Z \
  "last push"

# --- tj-actions/changed-files: excluded, and on what ground ---------------
field T14 tj-actions-advisory.json .ghsa_id GHSA-mrrh-fwg8-r2c3 \
  "the advisory that disqualifies the newer detector action"
field T15 tj-actions-advisory.json .severity high \
  "severity"
field T16 tj-actions-advisory.json .published_at 2025-03-15T06:30:34Z \
  "published"

# --- RustSec, with a control so the absence is a real absence -------------
if [ -f "$SNAP/rustsec-status.txt" ]; then
  # shellcheck disable=SC1091
  . "$SNAP/rustsec-status.txt"
  if [ "${CARGO_HACK_HTTP:-}" = "404" ] && [ "${ATTY_CONTROL_HTTP:-}" = "200" ]; then
    pass "T17 rustsec.org/packages/cargo-hack.html returned 404 while the atty control returned 200, so the absence of an advisory is a real absence and not a broken fetch (fitness gate 3)"
  else
    fail "T17 the recorded RustSec statuses are cargo-hack=${CARGO_HACK_HTTP:-unset} atty=${ATTY_CONTROL_HTTP:-unset}, which does not establish a real absence"
  fi
else
  skip "T17 snapshots/rustsec-status.txt is absent, so the RustSec gate is unrun"
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$PASS" "$FAIL" "$SKIP" "$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ]
