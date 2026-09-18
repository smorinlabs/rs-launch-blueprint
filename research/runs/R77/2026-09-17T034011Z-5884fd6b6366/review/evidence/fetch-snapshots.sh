#!/usr/bin/env bash
# R77 — one-shot snapshot fetcher. NOT an evidence check: it has no assertions.
# It writes the immutable-field snapshots that `registry-figures.sh` and
# `github-figures.sh` assert against. Re-run it only to refresh a snapshot
# deliberately; the assertion scripts are the evidence.
#
# GitHub REST is called no more often than once per 21 seconds (AGENTS/global
# rule: never more frequently than once every 20 s).
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
snap="$here/snapshots"
mkdir -p "$snap"

UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

crates_io=(envy config figment confique envconfig serde-env envious dotenvy serde pathdiff winnow)

echo "# fetch started $(date -u +%Y-%m-%dT%H:%M:%SZ)"

for name in "${crates_io[@]}"; do
  curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
    "https://crates.io/api/v1/crates/${name}" \
    | python3 -m json.tool --sort-keys > "$snap/cratesio-${name}.json"
  echo "wrote snapshots/cratesio-${name}.json"
  curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
    "https://crates.io/api/v1/crates/${name}/versions" \
    | python3 -m json.tool --sort-keys > "$snap/cratesio-${name}-versions.json"
  echo "wrote snapshots/cratesio-${name}-versions.json"
done

curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
  https://static.rust-lang.org/dist/channel-rust-stable.toml \
  > "$snap/channel-rust-stable.toml"
echo "wrote snapshots/channel-rust-stable.toml"

repos=(softprops/envy rust-cli/config-rs SergioBenitez/Figment
       LukasKalbertodt/confique greyblake/envconfig-rs
       Xuanwo/serde-env TheNeikos/envious)

first=1
for repo in "${repos[@]}"; do
  slug=${repo//\//__}
  [ "$first" -eq 1 ] || sleep 21
  first=0
  gh api "repos/${repo}" > "$snap/gh-repo-${slug}.json"
  echo "wrote snapshots/gh-repo-${slug}.json"
  sleep 21
  gh api "search/issues?q=repo:${repo}+is:issue+is:open" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"total_count": d["total_count"]}, indent=2))' \
    > "$snap/gh-openissues-${slug}.json"
  echo "wrote snapshots/gh-openissues-${slug}.json"
done

echo "# fetch finished $(date -u +%Y-%m-%dT%H:%M:%SZ)"
