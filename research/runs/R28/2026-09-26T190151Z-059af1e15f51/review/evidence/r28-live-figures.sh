#!/usr/bin/env bash
# R28 revision 1 — live figures from the prompt's named endpoints only:
# GET https://api.github.com/repos/<o>/<r>, GET https://api.github.com/search/issues,
# https://rustsec.org/packages/<name>.html, GET https://crates.io/api/v1/crates/<name>.
# GET https://crates.io/api/v1/crates/<name>/versions. Ten requests in total. Figures move between retrievals; only the
# archived flag and the rustsec status are asserted.
# Every case prints PASS or FAIL; exit 1 on any FAIL.
set -uo pipefail

fails=0
pass() { printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { printf 'FAIL %s — %s\n' "$1" "$2"; fails=$((fails + 1)); }

echo "== retrieved $(date -u +%Y-%m-%dT%H:%M:%SZ)"
command -v gh curl jq

n=0
for repo in rust-lang/rust-clippy rust-lang/rust-analyzer vadimcn/codelldb; do
  n=$((n + 1))
  echo
  echo "== G$n GET https://api.github.com/repos/$repo"
  if row=$(gh api "repos/$repo" --jq '{stargazers_count, archived, pushed_at, license: .license.spdx_id}' 2>&1); then
    echo "$row"
    if [ "$(jq -r .archived <<<"$row")" = "false" ]; then pass "G$n" "$repo not archived"; else fail "G$n" "$repo archived or unreadable"; fi
  else
    echo "$row"; fail "G$n" "request failed"
  fi
  echo "== G$n-issues GET https://api.github.com/search/issues?q=repo:$repo+is:issue+is:open"
  if cnt=$(gh api "search/issues?q=repo:$repo+is:issue+is:open&per_page=1" --jq .total_count 2>&1); then
    echo "total_count $cnt"
  else
    echo "$cnt"; fail "G$n-issues" "request failed"
  fi
done

n=0
for name in clippy rust-analyzer; do
  n=$((n + 1))
  echo
  echo "== S$n https://rustsec.org/packages/$name.html"
  code=$(curl -s -o /dev/null -w '%{http_code}' "https://rustsec.org/packages/$name.html")
  echo "HTTP $code"
  if [ "$code" = "404" ]; then pass "S$n" "no advisory page for $name"; else fail "S$n" "HTTP $code"; fi
done

echo
echo "== C1 GET https://crates.io/api/v1/crates/clippy (the retired shim, not the rustup component)"
if row=$(curl -s -A 'rs-launch-blueprint-R28-research' https://crates.io/api/v1/crates/clippy \
    | jq -c '{max_stable_version: .crate.max_stable_version, created_at: .crate.created_at, recent_downloads: .crate.recent_downloads, downloads: .crate.downloads, repository: .crate.repository}'); then
  echo "$row"
  if [ "$(jq -r .max_stable_version <<<"$row")" = "0.0.302" ]; then pass C1 "shim version 0.0.302"; else fail C1 "unexpected version"; fi
else
  fail C1 "request failed"
fi

echo
echo "== C2 GET https://crates.io/api/v1/crates/clippy/versions (newest non-yanked num and created_at)"
if row=$(curl -s -A 'rs-launch-blueprint-R28-research' https://crates.io/api/v1/crates/clippy/versions \
    | jq -c '[.versions[] | select(.yanked == false)] | sort_by(.created_at) | last | {num, created_at}'); then
  echo "$row"
  if [ "$(jq -r .num <<<"$row")" = "0.0.302" ]; then pass C2 "newest non-yanked version 0.0.302"; else fail C2 "unexpected version"; fi
else
  fail C2 "request failed"
fi

echo
echo "== summary: $fails failing case(s)"
[ "$fails" -eq 0 ]
