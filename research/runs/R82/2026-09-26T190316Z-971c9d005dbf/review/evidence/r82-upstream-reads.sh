#!/usr/bin/env bash
# R82 revision 1 synthesis: upstream facts both legs cite for the lychee members,
# re-read by the synthesizer through the prompt's named endpoints only
# (api.github.com via authenticated `gh api`, crates.io API, rustsec.org).
# lychee itself cannot be installed here: every install path (static.crates.io,
# GitHub release assets, Homebrew bottles) is off the named endpoints.
# Usage: bash r82-upstream-reads.sh > r82-upstream-reads.log 2>&1
set -euo pipefail

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

UA="rs-launch-blueprint-R82-synthesis"
raw() { gh api -H "Accept: application/vnd.github.raw" "$1"; }

echo "# r82-upstream-reads — run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# gh $(gh --version | head -1)"
echo

echo "## U1 lycheeverse/lychee-action tag v2.9.0 -> commit"
gh api "repos/lycheeverse/lychee-action/git/ref/tags/v2.9.0" --jq '"ref=\(.ref) object.type=\(.object.type) object.sha=\(.object.sha)"'
echo "## U1b releases (newest 3)"
gh api "repos/lycheeverse/lychee-action/releases?per_page=3" --jq '.[] | "\(.tag_name) published=\(.published_at) prerelease=\(.prerelease)"'
echo

echo "## U2 lychee-action action.yml at v2.9.0"
raw "repos/lycheeverse/lychee-action/contents/action.yml?ref=v2.9.0" > "$scratch/action.yml"
echo "sha256=$(shasum -a 256 "$scratch/action.yml" | cut -c1-64) lines=$(wc -l < "$scratch/action.yml" | tr -d ' ')"
grep -n -A3 -E '^  (lycheeVersion|fail|failIfEmpty|token|jobSummary|args):' "$scratch/action.yml" | grep -nE 'default|^[0-9]+:  [a-zA-Z]' | sed 's/^[0-9]*://' || true
echo "installer lines (curl/tar/sha256/checksum):"
grep -n -iE 'curl|tar -|sha256|checksum' "$scratch/action.yml" || true
echo

echo "## U3 lychee-bin/src/client.rs at tag lychee-v0.24.2 (offline scheme restriction)"
raw "repos/lycheeverse/lychee/contents/lychee-bin/src/client.rs?ref=lychee-v0.24.2" > "$scratch/client.rs"
echo "sha256=$(shasum -a 256 "$scratch/client.rs" | cut -c1-64)"
grep -n -B2 -A4 'offline' "$scratch/client.rs" | head -30
echo

echo "## U4 lychee-lib/src/filter/mod.rs at tag lychee-v0.24.2 (scheme filter -> Excluded)"
raw "repos/lycheeverse/lychee/contents/lychee-lib/src/filter/mod.rs?ref=lychee-v0.24.2" > "$scratch/filter.rs"
echo "sha256=$(shasum -a 256 "$scratch/filter.rs" | cut -c1-64)"
grep -n -iE 'scheme' "$scratch/filter.rs" | head -20
echo

echo "## U5 lychee-bin/Cargo.toml at tag lychee-v0.24.2"
raw "repos/lycheeverse/lychee/contents/lychee-bin/Cargo.toml?ref=lychee-v0.24.2" > "$scratch/Cargo.toml"
grep -n -E '^(version|license|rust-version|edition) *=' "$scratch/Cargo.toml"
echo

echo "## U6 lychee README at tag lychee-v0.24.2: flags the recommendation uses"
raw "repos/lycheeverse/lychee/contents/README.md?ref=lychee-v0.24.2" > "$scratch/README.md"
echo "sha256=$(shasum -a 256 "$scratch/README.md" | cut -c1-64) lines=$(wc -l < "$scratch/README.md" | tr -d ' ')"
for f in '--offline[' '--include-fragments[' '--root-dir <' '--max-retries <' '--retry-wait-time <' '--timeout <' '--accept <' '--cache[' '--max-cache-age <' '--cache-exclude-status <' '--config <' '--exclude-path <' '--no-progress['; do
  n="$(grep -n -m1 -F -- "$f" "$scratch/README.md" || true)"
  printf '%-24s %s\n' "$f" "$(printf '%s' "$n" | cut -c1-150)"
done
echo "exit-code section:"
grep -n -A12 -iE '^#+ *exit codes' "$scratch/README.md" | head -16 || true
echo "default config file name / lychee.toml mentions:"
grep -n -m6 -E 'lychee\.toml' "$scratch/README.md" || true
echo

echo "README: gitignore handling, default extensions, fragments, private-address exclusion"
grep -n -iE 'gitignore|--extensions <|--exclude-all-private|--no-ignore' "$scratch/README.md" | head -12 || true
sed -n '566,578p' "$scratch/README.md"
echo

echo "## U6b lychee-action README at v2.9.0: --root-dir form and cache example"
raw "repos/lycheeverse/lychee-action/contents/README.md?ref=v2.9.0" > "$scratch/action-README.md"
grep -n -E 'root-dir|restore-keys|lycheecache' "$scratch/action-README.md" | head -10 || true
echo

echo "## U10 practice examples each leg relies on (default branch at retrieval; blob sha recorded)"
show_on() { # show_on <repo> <path> <grep-regex>
  local sha; sha="$(gh api "repos/$1/contents/$2" --jq .sha)"
  echo "-- $1 $2 (blob $sha)"
  raw "repos/$1/contents/$2" | grep -n -E "$3" | head -12 || true
}
show_on lycheeverse/lychee .github/workflows/links.yml '^on:|^  [a-z_]+:|cron'
show_on lycheeverse/lychee .github/workflows/ci.yml 'RUSTDOCFLAGS|cargo doc'
show_on ZcashFoundation/zebra .github/workflows/advisory.yml 'cron|lychee|^  [a-z_]+:$'
show_on BurntSushi/ripgrep .github/workflows/ci.yml 'RUSTDOCFLAGS|cargo doc'
show_on tokio-rs/axum .github/workflows/CI.yml 'RUSTDOCFLAGS|cargo doc'
echo

echo "## U7 crates.io: lychee newest non-yanked version"
curl -sS -A "$UA" "https://crates.io/api/v1/crates/lychee/versions?per_page=5" > "$scratch/v.json"
python3 - "$scratch/v.json" <<'PY'
import json, sys
vs = [v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
v = vs[0]
print(f'num={v["num"]} created_at={v["created_at"]} rust_version={v.get("rust_version")} license={v["license"]}')
PY
echo

echo "## U8 issue responsiveness, 10 most recently opened issues (PRs excluded), two counting methods"
echo "#   method M (maintainer): first comment whose author_association is OWNER, MEMBER or COLLABORATOR (the prompt's 'first maintainer response')"
echo "#   method N (any non-opener): first comment by anyone other than the issue's author"
for repo in lycheeverse/lychee becheran/mlc deadlinks/cargo-deadlinks untitaker/hyperlink Michael-F-Bryan/mdbook-linkcheck; do
  gh api --paginate --slurp "repos/$repo/issues?state=all&sort=created&direction=desc&per_page=100" > "$scratch/issues.json"
  python3 - "$scratch/issues.json" > "$scratch/ten.txt" <<'PY'
import json, sys
pages = json.load(open(sys.argv[1]))
iss = [i for page in pages for i in page if "pull_request" not in i][:10]
for i in iss:
    print(i["number"], i["created_at"], i["user"]["login"], i["comments"])
PY
  : > "$scratch/rows.txt"
  while read -r num created opener ncom; do
    if [ "$ncom" = 0 ]; then echo "[]" > "$scratch/c.json"; else gh api "repos/$repo/issues/$num/comments?per_page=100" > "$scratch/c.json"; fi
    python3 - "$scratch/c.json" "$num" "$created" "$opener" >> "$scratch/rows.txt" <<'PY'
import json, sys
from datetime import datetime
cs = json.load(open(sys.argv[1])); num, created, opener = sys.argv[2], sys.argv[3], sys.argv[4]
t0 = datetime.fromisoformat(created.replace("Z", "+00:00"))
def first(pred):
    for c in cs:
        if pred(c):
            return round((datetime.fromisoformat(c["created_at"].replace("Z", "+00:00")) - t0).total_seconds() / 86400, 2)
    return None
m = first(lambda c: c["author_association"] in ("OWNER", "MEMBER", "COLLABORATOR"))
n = first(lambda c: c["user"]["login"] != opener)
print(num, created[:10], m, n)
PY
  done < "$scratch/ten.txt"
  python3 - "$repo" "$scratch/rows.txt" <<'PY'
import sys, statistics
repo, rows = sys.argv[1], [l.split() for l in open(sys.argv[2])]
def summ(idx):
    vals = [float(r[idx]) for r in rows if r[idx] != "None"]
    med = round(statistics.median(vals), 2) if vals else None
    return f"answered={len(vals)}/{len(rows)} median_days={med}"
print(f"{repo}: M {summ(2)} | N {summ(3)}")
for r in rows:
    print(f"   #{r[0]} opened {r[1]}  M={r[2]}  N={r[3]}")
PY
done
echo

echo "## U8b mdbook-linkcheck issues the Opus leg cites as the at-risk signal"
for n in 92 96; do
  gh api "repos/Michael-F-Bryan/mdbook-linkcheck/issues/$n" --jq '"#\(.number) state=\(.state) opened=\(.created_at) title=\(.title)"'
done
gh api "repos/Michael-F-Bryan/mdbook-linkcheck" --jq '"repo archived=\(.archived) pushed_at=\(.pushed_at)"'
echo

echo "## U9 rustsec.org package pages (404 = no advisory recorded; time.html is the positive control)"
for c in lychee lychee-lib mlc cargo-deadlinks mdbook-linkcheck hyperlink time; do
  printf '%-18s HTTP %s\n' "$c" "$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$c.html")"
done
