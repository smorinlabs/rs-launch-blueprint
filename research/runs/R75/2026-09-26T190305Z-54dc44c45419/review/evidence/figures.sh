#!/usr/bin/env bash
# R75 check E4 — every figure the decision cites, fetched fresh from the endpoints the
# prompt names: crates.io API (crate + versions), GitHub REST via authenticated `gh api`
# (repo, open-issue search, ten most recent issues with comments), and rustsec.org.
# crates.io is called at most once per second (its crawler policy). Any failed request
# is printed as GAP and never replaced by an estimate.
set -uo pipefail
UA="rs-launch-blueprint-research (R75 synthesis)"
echo "== E4 figures — retrieved $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"

crate_figures() {
  local c="$1" meta vers
  meta="$(curl -fsS -A "$UA" "https://crates.io/api/v1/crates/$c")" || { echo "GAP crates.io/$c"; return; }
  sleep 1
  vers="$(curl -fsS -A "$UA" "https://crates.io/api/v1/crates/$c/versions")" || { echo "GAP crates.io/$c/versions"; return; }
  sleep 1
  jq -r --arg c "$c" '"CRATE \($c) recent_downloads=\(.crate.recent_downloads) downloads=\(.crate.downloads)"' <<< "$meta"
  jq -r --arg c "$c" '[.versions[] | select(.yanked == false)] | sort_by(.created_at) | last
    | "CRATE \($c) newest_non_yanked=\(.num) created_at=\(.created_at) license=\(.license) rust_version=\(.rust_version // "null")"' <<< "$vers"
}
for c in tower-http tracing uuid tower tower-helmet axum-helmet helmet-core tower-request-id; do
  crate_figures "$c"
done

repo_figures() {
  local r="$1"
  gh api "repos/$r" --jq '"REPO '"$r"' stars=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)"' \
    || echo "GAP github repos/$r"
  gh api "search/issues?q=repo:$r+is:issue+is:open" --jq '"REPO '"$r"' open_issues_search_total=\(.total_count)"' \
    || echo "GAP github search/issues $r"
}
for r in tower-rs/tower-http tokio-rs/tracing uuid-rs/uuid tower-rs/tower; do
  repo_figures "$r"
done

# Issue responsiveness: the 10 most recently opened issues; first comment by an
# OWNER/MEMBER/COLLABORATOR who is not the issue's author; median days over answered issues.
responsiveness() {
  local r="$1" issues n num author created first days answered=() unanswered=0
  issues="$(gh api "search/issues?q=repo:$r+is:issue&sort=created&order=desc&per_page=10" \
    --jq '.items[] | "\(.number) \(.user.login) \(.created_at) \(.state)"')" || { echo "GAP responsiveness $r"; return; }
  while read -r num author created state; do
    first="$(gh api "repos/$r/issues/$num/comments?per_page=100" --jq \
      "[.[] | select((.author_association == \"OWNER\" or .author_association == \"MEMBER\" or .author_association == \"COLLABORATOR\") and .user.login != \"$author\")][0].created_at // \"none\"")" \
      || first="GAP"
    if [[ "$first" == none || "$first" == GAP ]]; then
      unanswered=$((unanswered + 1)); days="$first"
    else
      days="$(jq -rn --arg a "$created" --arg b "$first" '(($b|fromdateiso8601) - ($a|fromdateiso8601)) / 86400 | . * 10 | round / 10')"
      answered+=("$days")
    fi
    echo "ISSUE $r #$num opened=$created state=$state first_maintainer_response_days=$days"
  done <<< "$issues"
  n="${#answered[@]}"
  if (( n > 0 )); then
    printf '%s\n' "${answered[@]}" | sort -g | awk -v r="$r" -v u="$unanswered" '{a[NR]=$1} END {m=(NR%2)?a[(NR+1)/2]:(a[NR/2]+a[NR/2+1])/2; printf "RESPONSIVENESS %s answered=%d unanswered=%d median_days=%s\n", r, NR, u, m}'
  else
    echo "RESPONSIVENESS $r answered=0 unanswered=$unanswered median_days=n/a"
  fi
}
responsiveness tower-rs/tower-http
responsiveness tokio-rs/tracing

for p in tower-http tracing uuid tower; do
  code="$(curl -sS -o /tmp/r75-rustsec-$$.html -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$p.html")" || code="GAP"
  ids="$( { grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' /tmp/r75-rustsec-$$.html || true; } | sort -u | tr '\n' ' ')"
  echo "RUSTSEC $p http=$code advisories=[${ids% }]"
  for id in $ids; do
    page="$(curl -fsS -A "$UA" "https://rustsec.org/advisories/$id.html")" || { echo "GAP rustsec $id"; continue; }
    patched="$(perl -pe 's/<[^>]*>/ /g' <<< "$page" | tr -s ' \n' ' ' | grep -oE 'Patched[^A-Z]{0,80}' | head -1)"
    withdrawn="$(grep -c -i 'withdrawn' <<< "$page" || true)"
    echo "ADVISORY $id package=$p ${patched:-Patched: (not stated)} withdrawn_mentions=$withdrawn"
  done
done
rm -f /tmp/r75-rustsec-$$.html
echo "== end"
