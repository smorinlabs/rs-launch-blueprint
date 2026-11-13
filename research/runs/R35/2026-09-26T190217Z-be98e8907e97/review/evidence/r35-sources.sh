#!/usr/bin/env bash
# R35 revision 1 — live source figures that adjudicate the two raw legs.
# Endpoints: crates.io API, api.github.com (REST through `gh api`, never GraphQL)
# and rustsec.org — the three the prompt's figure table names. Every body is
# saved under snapshots/sources/ so the claims can be re-read offline.
# Live counts drift daily: exact figures are INFO lines; PASS/FAIL asserts only
# the claims the DECISION relies on.
# Usage: bash r35-sources.sh
set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots/sources"
mkdir -p "$snap"
ua="rs-launch-blueprint-R35-synthesis (https://github.com/smorinlabs/rs-launch-blueprint)"

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }

crates() { curl -fsS -A "$ua" "https://crates.io/api/v1/crates/$1" -o "$snap/crate-$1.json"; curl -fsS -A "$ua" "https://crates.io/api/v1/crates/$1/versions" -o "$snap/crate-$1-versions.json"; sleep 1; }
gh_get() { gh api -H "Accept: application/vnd.github+json" "$1" >"$snap/$2"; }
newest() { jq -r '[.versions[] | select(.yanked == false)] | sort_by(.created_at) | last | "\(.num) \(.created_at) rust_version=\(.rust_version) license=\(.license)"' "$snap/crate-$1-versions.json"; }

info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ)"

# --- crates.io figures (S1-S3) ---------------------------------------------
for c in cargo-llvm-cov cargo-tarpaulin grcov; do
  crates "$c"
  info "crates.io $c recent_downloads=$(jq .crate.recent_downloads "$snap/crate-$c.json") downloads=$(jq .crate.downloads "$snap/crate-$c.json") newest: $(newest "$c")"
done
l_new="$(newest cargo-llvm-cov)"; t_new="$(newest cargo-tarpaulin)"; g_new="$(newest grcov)"
s1a() { [[ "$l_new" == "0.9.1 2026-09-06T"*" rust_version=1.87 license=Apache-2.0 OR MIT" ]]; }
s2a() { [[ "$t_new" == "0.37.5 2026-09-27T"*" rust_version=null license=MIT OR Apache-2.0" ]]; }
s3a() { [[ "$g_new" == "0.10.7 2026-03-03T"*" license=MPL-2.0" ]]; }
check S1a "cargo-llvm-cov newest non-yanked is 0.9.1 created 2026-09-06, rust_version 1.87" s1a
check S2a "cargo-tarpaulin newest non-yanked is 0.37.5 created 2026-09-27 with no rust_version declared (revision 4; 0.37.4 of 2026-09-21 until then)" s2a
check S3a "grcov newest non-yanked is 0.10.7 created 2026-03-03 under MPL-2.0 (no release in >6 months)" s3a
lr="$(jq .crate.recent_downloads "$snap/crate-cargo-llvm-cov.json")"; tr="$(jq .crate.recent_downloads "$snap/crate-cargo-tarpaulin.json")"
info "90-day ratio cargo-llvm-cov/cargo-tarpaulin = $(awk -v a="$lr" -v b="$tr" 'BEGIN{printf "%.2f", a/b}')"
s1b() { [ "$lr" -gt $(( 5 * tr )) ]; }
check S1b "cargo-llvm-cov 90-day downloads exceed 5x cargo-tarpaulin's (both legs report 5.7x)" s1b

# --- GitHub repository figures (S4) ----------------------------------------
for r in taiki-e/cargo-llvm-cov xd009642/tarpaulin mozilla/grcov; do
  f="repo-${r//\//_}.json"; gh_get "repos/$r" "$f"
  info "github $r stars=$(jq .stargazers_count "$snap/$f") archived=$(jq .archived "$snap/$f") pushed_at=$(jq -r .pushed_at "$snap/$f")"
  check "S4-${r##*/}" "$r is not archived" test "$(jq .archived "$snap/$f")" = false
  q="repo:$r+is:issue+is:open"
  gh api "search/issues?q=$q&per_page=1" >"$snap/open-${r//\//_}.json"
  info "github $r open issues (search total_count)=$(jq .total_count "$snap/open-${r//\//_}.json")"
  sleep 2
done

# --- issue responsiveness over the 10 most recently opened issues (S5) -------
responsiveness() {
  local r="$1" tag="$2" answered=0 unanswered=0 days=()
  # The issues endpoint also returns pull requests; read up to 300 items so the
  # ten newest true issues are found even behind a run of bot pull requests.
  for page in 1 2 3; do
    gh api "repos/$r/issues?state=all&sort=created&direction=desc&per_page=100&page=$page"
  done | jq -s 'add | [.[] | select(has("pull_request") | not)] | .[:10]' >"$snap/issues-$tag.json"
  info "$tag sampled issues: $(jq -r 'map("#\(.number)") | join(" ")' "$snap/issues-$tag.json")"
  while IFS=$'\t' read -r num created; do
    gh api "repos/$r/issues/$num/comments?per_page=100" >"$snap/comments-$tag-$num.json"
    first="$(jq -r '[.[] | select(.author_association == "OWNER" or .author_association == "MEMBER" or .author_association == "COLLABORATOR")] | first | .created_at // empty' "$snap/comments-$tag-$num.json")"
    if [ -n "$first" ]; then
      answered=$((answered + 1))
      d="$(jq -rn --arg a "$created" --arg b "$first" '(($b | fromdateiso8601) - ($a | fromdateiso8601)) / 86400 | . * 100 | round / 100')"
      days+=("$d"); info "$tag #$num first maintainer response after $d days"
    else
      unanswered=$((unanswered + 1)); info "$tag #$num no maintainer comment"
    fi
  done < <(jq -r '.[] | [.number, .created_at] | @tsv' "$snap/issues-$tag.json")
  median="$( ( [ "${#days[@]}" -eq 0 ] || printf '%s\n' "${days[@]}" ) | sort -n | awk '{a[NR]=$1} END{if(NR==0){print "n/a"} else if(NR%2){print a[(NR+1)/2]} else {printf "%.2f", (a[NR/2]+a[NR/2+1])/2}}')"
  info "$tag responsiveness: answered=$answered unanswered=$unanswered median_days_over_answered=$median"
  echo "$answered $unanswered $median"
}
read -r g_ans g_unans g_med < <(responsiveness mozilla/grcov grcov | tee /dev/stderr | tail -n 1)
check S5a "grcov: at least 6 of its 10 newest issues have no maintainer comment (Opus: 8 of 10; the at-risk signal)" test "$g_unans" -ge 6
info "grcov answered=$g_ans median=$g_med"
read -r l_ans l_unans l_med < <(responsiveness taiki-e/cargo-llvm-cov llvmcov | tee /dev/stderr | tail -n 1)
check S5b "cargo-llvm-cov: a majority of its 10 newest issues received a maintainer comment" test "$l_ans" -ge 6
info "cargo-llvm-cov unanswered=$l_unans median=$l_med"

# --- RustSec (S6) ------------------------------------------------------------
for c in cargo-llvm-cov cargo-tarpaulin grcov; do
  code="$(curl -sS -A "$ua" -o "$snap/rustsec-$c.html" -w '%{http_code}' "https://rustsec.org/packages/$c.html")"
  info "rustsec packages/$c.html HTTP $code"
  if [ "$c" = grcov ]; then
    check S6-grcov "grcov package page exists (one historical advisory)" test "$code" = 200
  else
    check "S6-$c" "$c has no RustSec package page (HTTP 404 = never advised)" test "$code" = 404
  fi
done
curl -fsS -A "$ua" -o "$snap/rustsec-RUSTSEC-2025-0005.html" "https://rustsec.org/advisories/RUSTSEC-2025-0005.html"
# The page encodes ">" as the entity &#62;.
check S6b "RUSTSEC-2025-0005 lists the patched range >0.8.20, so grcov 0.10.7 is unaffected" /usr/bin/grep -q '&#62;0\.8\.20' "$snap/rustsec-RUSTSEC-2025-0005.html"

# --- rust-lang/rust tracking issues (S7) ---------------------------------------
for n in 84605 79649 79417 119164; do
  gh_get "repos/rust-lang/rust/issues/$n" "rust-issue-$n.json"
  info "rust-lang/rust#$n state=$(jq -r .state "$snap/rust-issue-$n.json") title=$(jq -r .title "$snap/rust-issue-$n.json")"
  check "S7-$n" "rust-lang/rust#$n is open" test "$(jq -r .state "$snap/rust-issue-$n.json")" = open
done

# --- rustc book, instrument-coverage chapter (S8) ------------------------------
gh api -H "Accept: application/vnd.github.raw" "repos/rust-lang/rust/contents/src/doc/rustc/src/instrument-coverage.md" >"$snap/rustc-book-instrument-coverage.md"
check S8a "rustc book names llvm-tools-preview 'the recommended path'" /usr/bin/grep -qi 'recommended path' "$snap/rustc-book-instrument-coverage.md"
check S8b "rustc book: doc-test coverage needs -Z unstable-options --persist-doctests" /usr/bin/grep -q 'persist-doctests' "$snap/rustc-book-instrument-coverage.md"
check S8c "rustc book: LLVM tools interface not subject to Rust's usual stability guarantees" /usr/bin/grep -qi 'stability guarantees' "$snap/rustc-book-instrument-coverage.md"
/usr/bin/grep -n -i 'recommended path\|persist-doctests\|stability guarantees' "$snap/rustc-book-instrument-coverage.md" | sed 's/^/INFO rustc-book: /'

# --- codecov-action README: tokenless uploads (S9) ------------------------------
gh api -H "Accept: application/vnd.github.raw" "repos/codecov/codecov-action/readme" >"$snap/codecov-action-README.md"
gh_get "repos/codecov/codecov-action/releases/latest" "codecov-action-latest.json"
info "codecov-action latest release $(jq -r '.tag_name + " " + .published_at' "$snap/codecov-action-latest.json")"
check S9a "codecov-action README: 'Tokenless uploading is unsupported' (forks to public repos excepted)" /usr/bin/grep -q 'Tokenless uploading is unsupported' "$snap/codecov-action-README.md"
/usr/bin/grep -n 'Tokenless uploading is unsupported' "$snap/codecov-action-README.md" | sed 's/^/INFO codecov README: /'

# --- adopter workflow spot-checks (S10) -----------------------------------------
adopter() {
  local repo="$1" path="$2" tool="$3" tag="$4" f
  f="wf-${repo//\//_}-${path##*/}"
  gh api -H "Accept: application/vnd.github.raw" "repos/$repo/contents/$path" >"$snap/$f"
  info "$repo $path: $(/usr/bin/grep -c -i "$tool" "$snap/$f") line(s) naming $tool; fail-under occurrences=$(/usr/bin/grep -c -i 'fail-under\|fail_under' "$snap/$f" || true)"
  runs_tool_without_gate() { /usr/bin/grep -qi "$tool" "$snap/$f" && ! /usr/bin/grep -qi 'fail-under\|fail_under' "$snap/$f"; }
  check "S10-$tag" "$repo $path runs $tool and carries no fail-under gate" runs_tool_without_gate
}
adopter ratatui/ratatui .github/workflows/ci.yml llvm-cov ratatui
adopter starship/starship .github/workflows/workflow.yml llvm-cov starship
adopter clap-rs/clap .github/workflows/ci.yml tarpaulin clap

# --- cargo-llvm-cov's own CI platforms (S11) -------------------------------------
gh api -H "Accept: application/vnd.github.raw" "repos/taiki-e/cargo-llvm-cov/contents/.github/workflows/ci.yml" >"$snap/cargo-llvm-cov-ci.yml"
/usr/bin/grep -n -E 'rust: |os: ' "$snap/cargo-llvm-cov-ci.yml" | sed 's/^/INFO cargo-llvm-cov ci.yml: /'
check S11a "cargo-llvm-cov's own CI names a macOS runner" /usr/bin/grep -q 'macos' "$snap/cargo-llvm-cov-ci.yml"

( cd "$snap" && shasum -a 256 -- * ) >"$here/SHA256SUMS-sources"
info "snapshot digests written to SHA256SUMS-sources ($(wc -l <"$here/SHA256SUMS-sources" | tr -d ' ') files)"
echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
