#!/usr/bin/env bash
# R27 synthesis check C5 — one-shot re-fetch of the figures the two legs report differently
# or that this decision relies on. Endpoints: api.github.com, crates.io/api/v1, rustsec.org
# only (the prompt's evidence table). Every call runs exactly once; nothing polls.
# An API failure prints "NO DATA" and is never counted as a value.
set -uo pipefail
GH=/opt/homebrew/bin/gh
JQ=/opt/homebrew/bin/jq
UA="rs-launch-blueprint-R27-synthesis"
echo "== retrieved $(date -u +%Y-%m-%dT%H:%M:%SZ); $("$GH" --version | head -1); $("$JQ" --version)"
ghq() { "$GH" api "$1" --jq "$2" 2>/dev/null || echo "NO DATA ($1)"; }
file_or_404() { # file_or_404 <owner/repo> <path>
  local b64
  if b64=$("$GH" api "repos/$1/contents/$2" --jq '.content' 2>/dev/null); then
    printf '%s' "$b64" | base64 -d 2>/dev/null | grep -v '^[[:space:]]*#' | sed '/^[[:space:]]*$/d' | tr '\n' ';'
  else echo "absent (HTTP 404 or error)"; fi
}

echo
echo "-- F1 current stable Rust: GET repos/rust-lang/rust/releases?per_page=4 (tag_name, published_at)"
ghq "repos/rust-lang/rust/releases?per_page=4" '.[] | "   \(.tag_name) \(.published_at)"'

echo
echo "-- F2 rustfmt repository: GET repos/rust-lang/rustfmt"
ghq "repos/rust-lang/rustfmt" '"   stargazers_count=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at) license=\(.license.spdx_id)"'
echo "-- F3 open issues: GET search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open (total_count)"
ghq "search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open" '"   total_count=\(.total_count)"'

echo
echo "-- F4 issue responsiveness: 10 most recently opened issues (PRs excluded); first comment whose"
echo "   author_association is OWNER, MEMBER or COLLABORATOR. Undercounts members with private org membership."
issues=$("$GH" api "repos/rust-lang/rustfmt/issues?state=all&sort=created&direction=desc&per_page=40" \
  --jq '[.[] | select(.pull_request == null)][:10][] | "\(.number) \(.created_at) \(.state)"' 2>/dev/null) || issues=""
if [ -z "$issues" ]; then echo "   NO DATA (issue list)"; fi
answered=0; unanswered=0; lat=()
while read -r num created state; do
  [ -z "${num:-}" ] && continue
  first=$("$GH" api "repos/rust-lang/rustfmt/issues/$num/comments?per_page=100" \
    --jq '[.[] | select(.author_association == "OWNER" or .author_association == "MEMBER" or .author_association == "COLLABORATOR")][0].created_at // "none"' 2>/dev/null) || first="NO DATA"
  if [ "$first" = "none" ] || [ "$first" = "NO DATA" ]; then
    unanswered=$((unanswered + 1)); echo "   #$num opened $created ($state): no qualifying comment [$first]"
  else
    d=$(python3 -c "from datetime import datetime as D;f='%Y-%m-%dT%H:%M:%SZ';print(round((D.strptime('$first',f)-D.strptime('$created',f)).total_seconds()/86400,2))")
    answered=$((answered + 1)); lat+=("$d"); echo "   #$num opened $created ($state): first qualifying comment after $d days"
  fi
done <<<"$issues"
med=$(python3 -c "import statistics,sys;v=[float(x) for x in sys.argv[1:]];print(statistics.median(v) if v else 'n/a')" "${lat[@]}")
echo "   answered=$answered unanswered=$unanswered median_days_answered=$med"

echo
echo "-- F5 rust-toolchain.toml channel in reference repositories (GET repos/<o>/<r>/contents/rust-toolchain.toml)"
for r in astral-sh/uv astral-sh/ruff zed-industries/zed cargo-bins/cargo-binstall nushell/nushell; do
  echo "   $r: $(file_or_404 "$r" rust-toolchain.toml)"
done

echo
echo "-- F6 rustfmt.toml in reference repositories (GET repos/<o>/<r>/contents/{rustfmt.toml,.rustfmt.toml})"
for r in tokio-rs/tokio clap-rs/clap serde-rs/serde rust-lang/crates.io astral-sh/uv BurntSushi/ripgrep casey/just tauri-apps/tauri rust-lang/cargo; do
  a=$(file_or_404 "$r" rustfmt.toml); b=$(file_or_404 "$r" .rustfmt.toml)
  echo "   $r: rustfmt.toml=[$a] .rustfmt.toml=[$b]"
done
for r in tokio-rs/tokio clap-rs/clap serde-rs/serde rust-lang/crates.io; do
  ghq "repos/$r" "\"   $r stargazers_count=\(.stargazers_count) archived=\(.archived) pushed_at=\(.pushed_at)\""
done

echo
echo "-- F7 tokio's CI formatter step (GET repos/tokio-rs/tokio/contents/.github/workflows/ci.yml)"
if c=$("$GH" api repos/tokio-rs/tokio/contents/.github/workflows/ci.yml --jq '.content' 2>/dev/null); then
  printf '%s' "$c" | base64 -d | grep -n 'rustfmt' | sed 's/^/   ci.yml:/'
else echo "   NO DATA"; fi

echo
echo "-- F8 Dependabot's rust-toolchain ecosystem exists (GET repos/dependabot/dependabot-core/contents/rust_toolchain)"
ghq "repos/dependabot/dependabot-core/contents/rust_toolchain" '"   entries: " + ([.[].name] | join(", "))'
ghq "repos/dependabot/dependabot-core/contents/rust_toolchain/lib/dependabot" '"   lib/dependabot: " + ([.[].name] | join(", "))'

echo
echo "-- F9 crates.io figures (GET https://crates.io/api/v1/crates/<name> and /versions)"
for c in rustfmt-nightly genemichaels topiary-cli prettyplease; do
  meta=$(curl -fsS -A "$UA" "https://crates.io/api/v1/crates/$c" 2>/dev/null) || meta=""
  vers=$(curl -fsS -A "$UA" "https://crates.io/api/v1/crates/$c/versions?per_page=20" 2>/dev/null) || vers=""
  if [ -z "$meta" ] || [ -z "$vers" ]; then echo "   $c: NO DATA"; continue; fi
  m=$("$JQ" -r '"recent_downloads=\(.crate.recent_downloads) downloads=\(.crate.downloads)"' <<<"$meta")
  v=$("$JQ" -r '[.versions[] | select(.yanked == false)] | sort_by(.created_at) | last | "newest=\(.num) at \(.created_at) license=\(.license)"' <<<"$vers")
  echo "   $c: $m $v"
done

echo
echo "-- F10 RustSec advisory pages (HTTP status of https://rustsec.org/packages/<name>.html)"
for c in rustfmt-nightly genemichaels topiary-cli prettyplease; do
  s=$(curl -s -o /dev/null -w '%{http_code}' -A "$UA" "https://rustsec.org/packages/$c.html" 2>/dev/null) || s="NO DATA"
  echo "   $c: HTTP $s"
done
echo
echo "== done (figures are observations, not assertions; no pass/fail count)"
