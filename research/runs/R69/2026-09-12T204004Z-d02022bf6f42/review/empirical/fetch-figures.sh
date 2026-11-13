#!/usr/bin/env bash
# R69 evidence, figure fetcher. Queries every endpoint the prompt's figure table
# names and writes a REDUCED snapshot -- only the fields that table names -- into
# review/evidence/snapshots/, which IS committed. Reducing is deliberate: the raw
# /versions payloads are megabytes of version history nobody reviews, and a
# snapshot a human can read is more auditable than one they cannot.
# assert-figures.sh reads these snapshots, never the live endpoints, so its log
# reproduces byte-for-byte; re-run THIS script to refresh the figures.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
S="$HERE/../evidence/snapshots"
UA='https://github.com/smorinlabs/rs-launch-blueprint'
mkdir -p "$S"
rc=0
NOW=$(date -u +%Y-%m-%dT%H:%M:%SZ)

CRATES="axum tokio tower bacon watchexec-cli cargo-watch actix-web warp poem salvo rocket ntex xitca-web pavex viz tide loco-rs dropshot hyper tower-http systemfd listenfd"
REPOS="tokio-rs/axum:axum tokio-rs/tokio:tokio tower-rs/tower:tower Canop/bacon:bacon watchexec/watchexec:watchexec watchexec/cargo-watch:cargo-watch actix/actix-web:actix-web seanmonstar/warp:warp poem-web/poem:poem rwf2/Rocket:rocket"

echo "== crates.io: crate.recent_downloads, crate.downloads, and the newest =="
echo "== non-yanked version's num / created_at / rust_version / license      =="
for c in $CRATES; do
  u1="https://crates.io/api/v1/crates/$c"; u2="$u1/versions"
  b1=$(curl -sS -L --max-time 60 -H "User-Agent: $UA" "$u1") || { echo "ERR $u1"; rc=1; continue; }
  b2=$(curl -sS -L --max-time 60 -H "User-Agent: $UA" "$u2") || { echo "ERR $u2"; rc=1; continue; }
  printf '%s\n%s\n' "$b1" "$b2" | jq -s --arg c "$c" --arg t "$NOW" --arg u1 "$u1" --arg u2 "$u2" '
    {crate: $c, retrieved_at: $t, endpoints: {crate: $u1, versions: $u2},
     recent_downloads: .[0].crate.recent_downloads,
     downloads:        .[0].crate.downloads,
     repository:       .[0].crate.repository,
     versions_total:   (.[1].versions | length),
     newest_non_yanked: ([.[1].versions[] | select(.yanked == false)] | sort_by(.created_at) | last
                         | {num, created_at, yanked, rust_version, license})}' > "$S/crate-$c.json" \
    || { echo "ERR reduce $c"; rc=1; continue; }
  echo "  $c -> crate-$c.json"
done
for c in axum tokio; do
  u="https://crates.io/api/v1/crates/$c/reverse_dependencies?per_page=1"
  curl -sS -L --max-time 60 -H "User-Agent: $UA" "$u" \
    | jq --arg t "$NOW" --arg u "$u" '{retrieved_at: $t, endpoint: $u, reverse_dependencies: .meta.total}' \
    > "$S/revdeps-$c.json" || { echo "ERR $u"; rc=1; }
done

echo "== GitHub: stargazers_count / archived / pushed_at, and the search =="
echo "== endpoint's total_count for open issues (never open_issues_count) =="
for pair in $REPOS; do
  slug="${pair%%:*}"; key="${pair##*:}"
  gh api "repos/$slug" --jq '{full_name, stargazers_count, archived, pushed_at, license: (.license.spdx_id // null)}' \
    | jq --arg t "$NOW" --arg u "https://api.github.com/repos/$slug" '. + {retrieved_at: $t, endpoint: $u}' \
    > "$S/gh-repo-$key.json" || { echo "ERR repos/$slug"; rc=1; }
  gh api -X GET search/issues -f q="repo:$slug is:issue is:open" --jq '{open_issues: .total_count}' \
    | jq --arg t "$NOW" --arg u "https://api.github.com/search/issues?q=repo:$slug+is:issue+is:open" '. + {retrieved_at: $t, endpoint: $u}' \
    > "$S/gh-issues-$key.json" || { echo "ERR issues $slug"; rc=1; }
  echo "  $slug -> gh-repo-$key.json, gh-issues-$key.json"
done

echo "== issue responsiveness inputs: the 10 most recently OPENED issues, =="
echo "== with each issue's comments reduced to author, association, time  =="
for pair in tokio-rs/axum:axum Canop/bacon:bacon tokio-rs/tokio:tokio; do
  slug="${pair%%:*}"; key="${pair##*:}"
  items=$(gh api -X GET search/issues -f q="repo:$slug is:issue" -f sort=created -f order=desc -f per_page=10 \
          --jq '[.items[] | {number, created_at, author: .user.login}]') || { echo "ERR newest $slug"; rc=1; continue; }
  tmp=$(mktemp)
  echo "$items" | jq -c '.[]' | while read -r it; do
    n=$(printf '%s' "$it" | jq -r .number)
    cm=$(gh api "repos/$slug/issues/$n/comments?per_page=100" \
         --jq '[.[] | {created_at, author: .user.login, type: .user.type, assoc: .author_association}]' 2>/dev/null || echo '[]')
    printf '%s' "$it" | jq --argjson cm "$cm" '. + {comments: $cm}' >> "$tmp"
  done
  jq -s --arg t "$NOW" --arg slug "$slug" '{repo: $slug, retrieved_at: $t, rule: "prompt table: 10 most recently opened issues; first comment whose author_association is OWNER/MEMBER/COLLABORATOR, excluding bots and the issue author", issues: .}' "$tmp" > "$S/gh-newest-issues-$key.json"
  rm -f "$tmp"
  echo "  $slug -> gh-newest-issues-$key.json"
done

echo "== RustSec package pages: HTTP status plus the advisory ids listed =="
for c in axum tokio tower bacon watchexec-cli hyper; do
  u="https://rustsec.org/packages/$c.html"
  body=$(curl -sS -L --max-time 60 -H "User-Agent: $UA" -w '\n%{http_code}' "$u") || { echo "ERR $u"; rc=1; continue; }
  code=$(printf '%s' "$body" | tail -1)
  ids=$(printf '%s' "$body" | grep -oE 'RUSTSEC-[0-9]{4}-[0-9]{4}' | sort -u | jq -R . | jq -s .)
  jq -n --arg c "$c" --arg t "$NOW" --arg u "$u" --arg code "$code" --argjson ids "$ids" \
    '{crate: $c, retrieved_at: $t, endpoint: $u, http_status: ($code|tonumber),
      note: "RustSec serves HTTP 404 for a crate with no advisory", advisories_listed: $ids}' \
    > "$S/rustsec-$c.json" || { echo "ERR reduce rustsec $c"; rc=1; }
  echo "  $code  $u"
done

printf 'retrieved-at: %s\n' "$NOW" > "$S/RETRIEVED-AT.txt"
echo "fetch-figures rc=$rc"
exit $rc
