#!/usr/bin/env bash
# R77 revision 4 — one-shot snapshot fetcher. NOT an evidence check: it has no
# assertions. It writes review/evidence/snapshots-r4/, which drift-r4.sh asserts
# against. Revision 1's snapshots/ directory is never written by this script.
#
# Same endpoints and User-Agent as revision 1's fetch-snapshots.sh, plus one
# GitHub call revision 4 needs: the Figment commits pushed after 2024-09-13,
# so that the renewed `pushed_at` can be read rather than guessed at.
#
# GitHub REST is called no more often than once per 21 seconds.
set -euo pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
snap="$here/snapshots-r4"
mkdir -p "$snap"

UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'

crates_io=(envy config figment confique envconfig serde-env envious dotenvy serde pathdiff winnow)

echo "# fetch started $(date -u +%Y-%m-%dT%H:%M:%SZ)"

for name in "${crates_io[@]}"; do
  curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
    "https://crates.io/api/v1/crates/${name}/versions" \
    | python3 -m json.tool --sort-keys > "$snap/cratesio-${name}-versions.json"
  echo "wrote snapshots-r4/cratesio-${name}-versions.json"
done

curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
  https://static.rust-lang.org/dist/channel-rust-stable.toml \
  > "$snap/channel-rust-stable.toml"
echo "wrote snapshots-r4/channel-rust-stable.toml"

repos=(softprops/envy rust-cli/config-rs SergioBenitez/Figment
       LukasKalbertodt/confique greyblake/envconfig-rs
       Xuanwo/serde-env TheNeikos/envious)

first=1
for repo in "${repos[@]}"; do
  slug=${repo//\//__}
  [ "$first" -eq 1 ] || sleep 21
  first=0
  gh api "repos/${repo}" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({k: d[k] for k in ("full_name","stargazers_count","archived","pushed_at")}, indent=2, sort_keys=True))' \
    > "$snap/gh-repo-${slug}.json"
  echo "wrote snapshots-r4/gh-repo-${slug}.json"
  sleep 21
  gh api "search/issues?q=repo:${repo}+is:issue+is:open" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); print(json.dumps({"total_count": d["total_count"]}, indent=2))' \
    > "$snap/gh-openissues-${slug}.json"
  echo "wrote snapshots-r4/gh-openissues-${slug}.json"
done

sleep 21
gh api "repos/SergioBenitez/Figment/commits?since=2024-09-14T00:00:00Z&per_page=100" \
  | python3 -c 'import json,sys
d=json.load(sys.stdin)
print(json.dumps([{"sha": c["sha"][:12], "date": c["commit"]["committer"]["date"],
                   "subject": c["commit"]["message"].splitlines()[0]} for c in d], indent=2))' \
  > "$snap/gh-commits-SergioBenitez__Figment-since-2024-09-14.json"
echo "wrote snapshots-r4/gh-commits-SergioBenitez__Figment-since-2024-09-14.json"

echo "# fetch finished $(date -u +%Y-%m-%dT%H:%M:%SZ)"
