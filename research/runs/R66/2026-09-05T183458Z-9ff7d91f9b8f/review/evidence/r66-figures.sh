#!/usr/bin/env bash
# R66 — output-format-surface. Live figure and fitness-gate check.
#
# Queries the endpoints the binding prompt names and asserts on the STABLE
# fields this decision rests on: the newest un-yanked version, its declared
# `rust_version` (gate 2), its declared `license`, its feature set, whether the
# repository is archived, and the RustSec advisory state (gate 3). It also
# re-runs, against the crate's own published source, the two claims that decide
# an architectural alternative: that `tabled`'s `Style::markdown()` escapes no
# pipe, and that `hyperfine`'s Markdown exporter escapes none either.
#
# What varies between runs, and the rule for comparing across it. Download
# counters, star counts and `pushed_at` move continuously, so this script never
# prints them and never asserts on them: the dated figures quoted in the
# decision come from `snapshots/crates-2026-09-15.json`, captured once by
# `--record` and committed beside this script. Everything this script prints is
# a stable field, so its log reproduces byte-for-byte until an upstream release,
# a yank, an advisory, or a licence change moves one — each of which is a
# re-verify trigger the decision names.
#
# Usage: bash r66-figures.sh            assert live stable fields (default)
#        bash r66-figures.sh --record   additionally rewrite the dated snapshot
# Exit 0 = every check passed. Exit 1 = at least one failed.

set -u
set -o pipefail

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
ROOT=$(cd "$SCRIPT_DIR/../../../../../.." && pwd)
UA="rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)"
RECORD=0
[ "${1:-}" = "--record" ] && RECORD=1

RUN=0
FAIL=0
INDET=0
pass() { RUN=$((RUN + 1)); printf 'PASS %-6s %s\n' "$1" "$2"; }
fail() { RUN=$((RUN + 1)); FAIL=$((FAIL + 1)); printf 'FAIL %-6s %s\n' "$1" "$2"; }
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1" "$4 == $2"; else fail "$1" "$4: expected [$2] got [$3]"; fi
}

WORK=$(mktemp -d) || exit 1
trap 'rm -rf "$WORK"' EXIT

# api.github.com allows 60 unauthenticated requests per hour per IP. This script
# spends 13 of them, so two or three runs in the same hour exhaust the quota and
# every GitHub check then sees HTTP 403. That is neither a pass nor a content
# failure, so it is reported as INDETERMINATE and the script exits 2 — a state an
# auditor can tell apart from "the claim is false". Exporting GH_TOKEN or
# GITHUB_TOKEN raises the limit to 5,000/hour; the token is sent as a header and
# is never written to the log.
GH_AUTH=""
if [ -n "${GH_TOKEN:-}" ]; then GH_AUTH="${GH_TOKEN}"; elif [ -n "${GITHUB_TOKEN:-}" ]; then GH_AUTH="${GITHUB_TOKEN}"; fi

# get <url> <outfile> -> prints the HTTP status, non-zero on transport failure
get() {
  case "$1" in
    https://api.github.com/*)
      if [ -n "$GH_AUTH" ]; then
        curl -sS -H "User-Agent: $UA" -H "Authorization: Bearer $GH_AUTH" --max-time 60 -o "$2" -w '%{http_code}' "$1"
      else
        curl -sS -H "User-Agent: $UA" --max-time 60 -o "$2" -w '%{http_code}' "$1"
      fi
      ;;
    *) curl -sS -H "User-Agent: $UA" --max-time 60 -o "$2" -w '%{http_code}' "$1" ;;
  esac
}

# gh_quota_exhausted <outfile> — true when a 403 body is GitHub's rate-limit
# refusal rather than a real denial.
gh_quota_exhausted() {
  /usr/bin/grep -q -F 'rate limit exceeded' "$1"
}
indet() { RUN=$((RUN + 1)); INDET=$((INDET + 1)); printf 'INDET %-6s %s\n' "$1" "$2"; }

echo "=== R66 figure and fitness-gate check — live endpoints ==="
echo "host:      $(uname -srm)"
echo "bash:      ${BASH_VERSION}"
echo "curl:      $(curl --version | head -1)"
echo "jq:        $(jq --version)"
echo "grep:      /usr/bin/grep -> $(/usr/bin/grep --version 2>&1 | head -1)"
echo "ROOT:      $ROOT"
if [ -f "$ROOT/AGENTS.md" ]; then pass A0 "ROOT sentinel AGENTS.md present"; else fail A0 "ROOT sentinel missing"; fi
echo

# --------------------------------------------- A1: crates.io newest un-yanked
echo "--- A1 crates.io newest un-yanked version, licence, declared MSRV, features ---"
# crate|expected num|expected rust_version (null = undeclared)|expected license|expected features
CRATES='serde|1.0.229|1.56|MIT OR Apache-2.0|alloc,default,derive,rc,std,unstable
serde_json|1.0.151|1.71|MIT OR Apache-2.0|
tabled|0.22.0|null|MIT|ansi,assert,default,derive,macros,std
tempfile|3.27.0|1.63|MIT OR Apache-2.0|
csv|1.4.0|1.73|Unlicense/MIT|
comfy-table|8.0.0|null|MIT|_debug,_integration_test,custom_styling,default,reexport_crossterm,tty'

while IFS='|' read -r crate xnum xrv xlic xfeat; do
  [ -n "$crate" ] || continue
  code=$(get "https://crates.io/api/v1/crates/$crate/versions" "$WORK/$crate.versions.json") || {
    fail "A1-$crate" "transport failure querying crates.io"
    continue
  }
  assert_eq "A1h-$crate" "200" "$code" "GET /crates/$crate/versions HTTP"
  newest=$(jq -r '[.versions[] | select(.yanked==false)] | .[0]' "$WORK/$crate.versions.json")
  assert_eq "A1n-$crate" "$xnum" "$(printf '%s' "$newest" | jq -r '.num')" "$crate newest un-yanked num"
  assert_eq "A1m-$crate" "$xrv"  "$(printf '%s' "$newest" | jq -r '.rust_version')" "$crate declared rust_version (gate 2)"
  assert_eq "A1l-$crate" "$xlic" "$(printf '%s' "$newest" | jq -r '.license')" "$crate declared license (recorded; gate 1 inapplicable)"
  if [ -n "$xfeat" ]; then
    assert_eq "A1f-$crate" "$xfeat" "$(printf '%s' "$newest" | jq -r '.features|keys|join(",")')" "$crate feature keys"
  fi
done <<EOF
$CRATES
EOF
echo

# ------------------------------------------------------- A2: GitHub repo state
echo "--- A2 GitHub repository state (archived is a gate; counters are not printed) ---"
for r in serde-rs/serde serde-rs/json zhiburt/tabled Nukesor/comfy-table Stebalien/tempfile BurntSushi/rust-csv nushell/nushell sharkdp/hyperfine; do
  code=$(get "https://api.github.com/repos/$r" "$WORK/gh.json") || { fail "A2-$r" "transport failure"; continue; }
  if [ "$code" = "403" ] && gh_quota_exhausted "$WORK/gh.json"; then
    indet "A2h-$r" "GET /repos/$r — GitHub REST quota exhausted for this IP; not a content result"
    indet "A2a-$r" "$r archived — not determined, see above"
    continue
  fi
  assert_eq "A2h-$r" "200" "$code" "GET /repos/$r HTTP"
  assert_eq "A2a-$r" "false" "$(jq -r '.archived' "$WORK/gh.json")" "$r archived"
done
echo

# ------------------------------- A3: RustSec advisory state, with both controls
echo "--- A3 RustSec (gate 3) — 404 means 'no advisory' only if a known-bad crate returns 200 ---"
for p in serde serde_json tabled comfy-table tempfile csv; do
  code=$(get "https://rustsec.org/packages/$p.html" "$WORK/rs.html") || { fail "A3-$p" "transport failure"; continue; }
  assert_eq "A3-$p" "404" "$code" "rustsec.org/packages/$p.html (no advisory page)"
done
# Positive controls: two crates with published advisories MUST return 200, or
# every 404 above would be indistinguishable from a broken endpoint.
for p in atty time; do
  code=$(get "https://rustsec.org/packages/$p.html" "$WORK/rs-$p.html") || { fail "A3c-$p" "transport failure"; continue; }
  assert_eq "A3c-$p" "200" "$code" "positive control: $p has an advisory page"
  if /usr/bin/grep -q -F 'RUSTSEC-' "$WORK/rs-$p.html"; then
    pass "A3d-$p" "positive control: $p page names at least one RUSTSEC- id"
  else
    fail "A3d-$p" "positive control: $p page returned 200 but names no RUSTSEC- id"
  fi
done
echo

# ------------------------- A4: the escaping defect that rejects alternative ALT-2
echo "--- A4 Markdown escaping in the two candidate renderers ---"
code=$(get "https://crates.io/api/v1/crates/tabled/0.22.0/download" "$WORK/tabled.crate") || { fail A4 "transport failure"; }
# crates.io serves the tarball behind a redirect; follow it explicitly.
curl -sS -L -H "User-Agent: $UA" --max-time 120 -o "$WORK/tabled.crate" \
  "https://crates.io/api/v1/crates/tabled/0.22.0/download" || fail A4 "download failed"
if tar xzf "$WORK/tabled.crate" -C "$WORK"; then pass A4 "tabled-0.22.0.crate extracted"; else fail A4 "extraction failed"; fi
TSRC="$WORK/tabled-0.22.0/src"
# Positive control: the function this decision discusses must exist, or the
# absence search below would pass against an empty or wrong tree.
NMD=$(/usr/bin/grep -rc -F 'pub const fn markdown()' "$TSRC" 2>/dev/null | /usr/bin/grep -v ':0$' | wc -l | tr -d ' ')
assert_eq A4a "1" "$NMD" "positive control: exactly one file declares 'pub const fn markdown()' (/usr/bin/grep -rc -F)"
# The claim: nowhere in tabled's source is a literal '|' replaced or escaped.
NPIPE=$(/usr/bin/grep -rn -F 'replace("|"' "$TSRC" 2>/dev/null | wc -l | tr -d ' ')
assert_eq A4b "0" "$NPIPE" "tabled src has no replace(\"|\" call site (/usr/bin/grep -rn -F, lines)"
NESC=$(/usr/bin/grep -rn -F '\\|' "$TSRC" 2>/dev/null | wc -l | tr -d ' ')
assert_eq A4c "0" "$NESC" "tabled src emits no backslash-pipe escape (/usr/bin/grep -rn -F, lines)"
# hyperfine is this item's closest maintained reference implementation, and it
# does not escape either: the template must be stricter than its reference.
code=$(get "https://raw.githubusercontent.com/sharkdp/hyperfine/master/src/export/markdown.rs" "$WORK/hf-md.rs") || fail A4d "transport failure"
assert_eq A4d "200" "$code" "GET hyperfine src/export/markdown.rs HTTP"
if /usr/bin/grep -q -F 'format!("| {} |\n", cells.join(" | "))' "$WORK/hf-md.rs"; then
  pass A4e "hyperfine joins cells with ' | ' verbatim (positive control on the file's identity)"
else
  fail A4e "hyperfine markdown.rs no longer contains the cell join this decision quotes"
fi
NHF=$(/usr/bin/grep -c -F 'replace' "$WORK/hf-md.rs" 2>/dev/null || true)
assert_eq A4f "0" "${NHF:-0}" "hyperfine markdown exporter performs no replace/escape (/usr/bin/grep -c -F)"
echo

# ------------------------------------- A5: practice evidence read at the source
echo "--- A5 practice evidence (adopter manifests read directly) ---"
code=$(get "https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-table/Cargo.toml" "$WORK/nu-table.toml") || fail A5 "transport failure"
assert_eq A5 "200" "$code" "GET nushell crates/nu-table/Cargo.toml HTTP"
if /usr/bin/grep -q -F 'tabled = { workspace = true, features = ["ansi"], default-features = false }' "$WORK/nu-table.toml"; then
  pass A5a "nushell's nu-table enables tabled's ansi feature with default-features = false"
else
  fail A5a "nushell's nu-table no longer carries the tabled ansi configuration"
fi
code=$(get "https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml" "$WORK/nu-root.toml") || fail A5b "transport failure"
assert_eq A5b "200" "$code" "GET nushell root Cargo.toml HTTP"
NUPIN=$(/usr/bin/grep -F 'tabled = { version =' "$WORK/nu-root.toml" | head -1)
# Recorded, not asserted equal to the version this decision recommends: the
# adopter's pin and this template's pin are allowed to differ, and the decision
# states that they do.
echo "     note   nushell workspace pin: ${NUPIN:-<none found>}"
if [ -n "$NUPIN" ]; then pass A5c "nushell declares a workspace tabled pin"; else fail A5c "no tabled pin found in nushell's root manifest"; fi
code=$(get "https://raw.githubusercontent.com/sharkdp/hyperfine/master/Cargo.toml" "$WORK/hf.toml") || fail A5d "transport failure"
assert_eq A5d "200" "$code" "GET hyperfine Cargo.toml HTTP"
for dep in 'csv = "1.3"' 'serde_json = "1.0"'; do
  if /usr/bin/grep -q -F "$dep" "$WORK/hf.toml"; then pass "A5e" "hyperfine declares $dep"; else fail "A5e" "hyperfine no longer declares $dep"; fi
done
NTBL=$(/usr/bin/grep -c -E '^(tabled|comfy-table|prettytable|markdown)' "$WORK/hf.toml" || true)
assert_eq A5f "0" "${NTBL:-0}" "hyperfine declares no table or markdown crate (/usr/bin/grep -c -E)"
echo

# ---------------- A6: maintainers' own MSRV and semver statements (gate 2 tie-break)
echo "--- A6 maintainers' stated MSRV and semver policies ---"
code=$(get "https://raw.githubusercontent.com/Nukesor/comfy-table/main/README.md" "$WORK/ct-readme.md") || fail A6 "transport failure"
assert_eq A6 "200" "$code" "GET comfy-table README HTTP"
if /usr/bin/grep -q -F 'Comfy-table is written for the current `stable` Rust version.' "$WORK/ct-readme.md"; then
  pass A6a "comfy-table states it targets the CURRENT stable Rust version only"
else
  fail A6a "comfy-table README no longer carries its current-stable-only statement"
fi
if /usr/bin/grep -q -F "Older Rust versions may work but aren't officially supported." "$WORK/ct-readme.md"; then
  pass A6b "comfy-table states older Rust versions are not officially supported"
else
  fail A6b "comfy-table README no longer carries its unsupported-older-Rust statement"
fi
code=$(get "https://raw.githubusercontent.com/zhiburt/tabled/master/README.md" "$WORK/tb-readme.md") || fail A6c "transport failure"
assert_eq A6c "200" "$code" "GET tabled README HTTP"
if /usr/bin/grep -q -F 'We often do breaking changes on minor version bump.' "$WORK/tb-readme.md"; then
  pass A6d "tabled states it breaks on minor version bumps"
else
  fail A6d "tabled README no longer carries its breaking-minor statement"
fi
if /usr/bin/grep -q -F "It's likely better to depend on constant version e.g. \`=0.8.0\`" "$WORK/tb-readme.md"; then
  pass A6e "tabled directs consumers to pin an exact version"
else
  fail A6e "tabled README no longer directs consumers to an exact pin"
fi
if /usr/bin/grep -q -F 'Breaking MSRV considered to be a breaking change' "$WORK/tb-readme.md"; then
  pass A6f "tabled treats an MSRV bump as a breaking change"
else
  fail A6f "tabled README no longer treats an MSRV bump as breaking"
fi
echo

# ------------------------------- A7: gate 4, upstream CI operating-system matrix
echo "--- A7 gate 4: does each crate's own CI run on macos-latest? ---"
# expected: repo-path|expected macos-latest present (yes|no)
CI='serde-rs/serde/master|no
serde-rs/json/master|no
zhiburt/tabled/master|yes
Stebalien/tempfile/master|yes
BurntSushi/rust-csv/master|yes'
while IFS='|' read -r path want; do
  [ -n "$path" ] || continue
  code=$(get "https://raw.githubusercontent.com/$path/.github/workflows/ci.yml" "$WORK/ci.yml") || { fail "A7-$path" "transport failure"; continue; }
  assert_eq "A7h-$path" "200" "$code" "GET $path/.github/workflows/ci.yml HTTP"
  n=$(/usr/bin/grep -c -i -F 'macos-latest' "$WORK/ci.yml" || true)
  got=no; [ "${n:-0}" -ge 1 ] && got=yes
  assert_eq "A7-$path" "$want" "$got" "$path CI declares macos-latest"
  # Control on the same file: every one of these matrices names ubuntu-latest,
  # so a zero macOS count cannot be an empty or wrong file.
  nu=$(/usr/bin/grep -c -i -F 'ubuntu-latest' "$WORK/ci.yml" || true)
  if [ "${nu:-0}" -ge 1 ]; then pass "A7u-$path" "control: $path CI names ubuntu-latest"; else fail "A7u-$path" "control: $path CI names no ubuntu-latest — file is not a matrix"; fi
done <<EOF
$CI
EOF
echo

# ------------------------------------------------------ optional: dated capture
if [ "$RECORD" -eq 1 ]; then
  SNAP="$SCRIPT_DIR/snapshots"
  mkdir -p "$SNAP"
  OUT="$SNAP/crates-$(date -u +%Y-%m-%d).json"
  {
    printf '{\n  "retrieved_utc": "%s",\n  "endpoints": {\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
    first=1
    for c in serde serde_json tabled comfy-table tempfile csv; do
      get "https://crates.io/api/v1/crates/$c" "$WORK/$c.crate.json" >/dev/null || continue
      [ $first -eq 1 ] || printf ',\n'
      first=0
      printf '    "%s": %s' "$c" \
        "$(jq -c '{endpoint:"https://crates.io/api/v1/crates/'"$c"'", recent_downloads:.crate.recent_downloads, downloads:.crate.downloads, max_stable_version:.crate.max_stable_version}' "$WORK/$c.crate.json")"
    done
    printf '\n  },\n  "github": {\n'
    first=1
    for r in serde-rs/serde serde-rs/json zhiburt/tabled Nukesor/comfy-table Stebalien/tempfile BurntSushi/rust-csv nushell/nushell sharkdp/hyperfine; do
      get "https://api.github.com/repos/$r" "$WORK/gh2.json" >/dev/null || continue
      oi=$(get "https://api.github.com/search/issues?q=repo:$r+is:issue+is:open" "$WORK/oi.json" >/dev/null && jq -r '.total_count' "$WORK/oi.json")
      [ $first -eq 1 ] || printf ',\n'
      first=0
      printf '    "%s": %s' "$r" \
        "$(jq -c --arg oi "${oi:-null}" '{endpoint:"https://api.github.com/repos/'"$r"'", stargazers_count:.stargazers_count, archived:.archived, pushed_at:.pushed_at, open_issues_search_total_count:($oi|tonumber?)}' "$WORK/gh2.json")"
      sleep 1
    done
    printf '\n  }\n}\n'
  } >"$OUT"
  echo "recorded snapshot: ${OUT#"$ROOT"/}"
fi

echo "CHECKS RUN: $RUN   FAILURES: $FAIL   INDETERMINATE: $INDET"
[ "$FAIL" -eq 0 ] || exit 1
if [ "$INDET" -gt 0 ]; then
  echo "INDETERMINATE: $INDET GitHub REST checks could not run because this IP's"
  echo "unauthenticated quota (60 requests/hour) is exhausted. This is NOT a content"
  echo "failure. Retry after the reset reported by"
  echo "  curl -sS -D - -o /dev/null https://api.github.com/rate_limit | grep -i x-ratelimit-reset"
  echo "or export GH_TOKEN / GITHUB_TOKEN and rerun. Every non-GitHub check above stands."
  exit 2
fi
exit 0
