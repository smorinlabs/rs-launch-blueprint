#!/usr/bin/env bash
# R77 — empirical check, part 1 of 3: every published figure this decision cites.
#
# Two kinds of check, kept apart on purpose:
#   (A) SNAPSHOT checks — assert that the numbers written into DECISION.md equal
#       the bytes in review/evidence/snapshots/, which were retrieved on
#       2026-09-18 (UTC) by review/evidence/fetch-snapshots.sh. These reproduce
#       byte-for-byte for ever, because the snapshots are committed.
#   (B) LIVE checks — re-fetch and assert only the IMMUTABLE fields of a
#       published version (version number, publication date, declared
#       rust-version, licence) and of the RustSec pages. Download counters,
#       star counts and pushed_at are monotonic or volatile: they are printed
#       as DRIFT lines, never asserted. Without network the live half SKIPs.
#
# Rule for comparing across a re-run: a SNAPSHOT line must match exactly; a
# DRIFT line may move upward for a counter and forward for a timestamp.
set -euo pipefail
set -o pipefail

here=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
snap="$here/snapshots"
decision="$here/../DECISION.md"

pass=0; fail=0; skip=0
ok() { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no() { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk() { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1 ($3)"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}
# assert that DECISION.md contains a literal string
assert_doc() {
  if [ ! -f "$decision" ]; then sk "$1 — DECISION.md not present beside this script"; return; fi
  if /usr/bin/grep -qF -- "$2" "$decision"; then ok "$1"; else
    no "$1"; printf '     DECISION.md does not contain: %s\n' "$2"; fi
}

printf '# R77 figures — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# /usr/bin/grep version: %s\n' "$(/usr/bin/grep --version | head -1)"
printf '# snapshots retrieved 2026-09-18 (UTC) by fetch-snapshots.sh\n\n'

if [ ! -d "$snap" ]; then
  no "snapshot directory missing at $snap"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  exit 1
fi

field() { # $1 file  $2 python expression over the parsed JSON bound to d
  python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
print(eval(sys.argv[2]))' "$1" "$2"
}

echo '## A — crates.io figures, asserted against the committed snapshots'
# name              recent        all-time      newest    created      rust_version
while IFS='|' read -r name recent alltime newest created rustver; do
  [ -n "$name" ] || continue
  f="$snap/cratesio-${name}.json"; v="$snap/cratesio-${name}-versions.json"
  if [ ! -f "$f" ] || [ ! -f "$v" ]; then sk "crates.io snapshot for $name"; continue; fi
  assert_eq "crates.io $name crate.recent_downloads" "$recent"  "$(field "$f" 'd["crate"]["recent_downloads"]')"
  assert_eq "crates.io $name crate.downloads"        "$alltime" "$(field "$f" 'd["crate"]["downloads"]')"
  newest_num=$(field "$v" '[x for x in d["versions"] if not x["yanked"]][0]["num"]')
  newest_at=$(field  "$v" '[x for x in d["versions"] if not x["yanked"]][0]["created_at"][:10]')
  newest_rv=$(field  "$v" 'str([x for x in d["versions"] if not x["yanked"]][0].get("rust_version"))')
  assert_eq "crates.io $name newest non-yanked num"        "$newest"  "$newest_num"
  assert_eq "crates.io $name newest non-yanked created_at" "$created" "$newest_at"
  assert_eq "crates.io $name newest non-yanked rust_version" "$rustver" "$newest_rv"
done <<'ROWS'
envy|3574490|20877399|0.4.2|2021-01-04|None
config|18581807|114271945|0.15.25|2026-06-26|1.85.0
figment|10072166|38648096|0.10.19|2024-05-17|None
confique|158359|490326|0.4.0|2025-10-27|1.68.2
envconfig|1472437|10008963|0.11.1|2025-12-10|None
serde-env|944262|2883110|0.3.0|2026-04-15|None
envious|66319|570440|0.3.0|2026-05-29|None
dotenvy|46188632|167331109|0.15.7|2023-03-22|1.56.1
serde|314208639|1410307353|1.0.229|2026-07-18|1.56
pathdiff|37311348|191737074|0.2.3|2024-11-25|None
winnow|265501982|911347434|1.0.4|2026-07-13|1.65.0
ROWS

echo
echo '## A — GitHub figures, asserted against the committed snapshots'
while IFS='|' read -r repo stars archived pushed issues; do
  [ -n "$repo" ] || continue
  slug=${repo//\//__}
  r="$snap/gh-repo-${slug}.json"; i="$snap/gh-openissues-${slug}.json"
  if [ ! -f "$r" ] || [ ! -f "$i" ]; then sk "GitHub snapshot for $repo"; continue; fi
  assert_eq "github $repo stargazers_count" "$stars"    "$(field "$r" 'd["stargazers_count"]')"
  assert_eq "github $repo archived"         "$archived" "$(field "$r" 'd["archived"]')"
  assert_eq "github $repo pushed_at (date)" "$pushed"   "$(field "$r" 'd["pushed_at"][:10]')"
  assert_eq "github $repo open issues total_count (search/issues, never open_issues_count)" \
            "$issues" "$(field "$i" 'd["total_count"]')"
done <<'ROWS'
softprops/envy|981|False|2024-06-07|14
rust-cli/config-rs|3210|False|2026-09-15|110
SergioBenitez/Figment|913|False|2024-09-13|21
LukasKalbertodt/confique|223|False|2025-10-27|19
greyblake/envconfig-rs|232|False|2025-12-10|6
Xuanwo/serde-env|25|False|2026-04-15|1
TheNeikos/envious|60|False|2026-05-30|2
ROWS

echo
echo '## A — current stable Rust, asserted against the committed snapshot'
if [ -f "$snap/channel-rust-stable.toml" ]; then
  stable=$(python3 -c 'import re,sys
t=open(sys.argv[1]).read()
m=re.search(r"\[pkg\.rust\]\nversion = \"([^\"]+)\"", t)
print(m.group(1) if m else "NOT-FOUND")' "$snap/channel-rust-stable.toml")
  assert_eq "static.rust-lang.org [pkg.rust] version" "1.98.1 (48a229cea 2026-09-01)" "$stable"
else
  sk "channel-rust-stable.toml snapshot"
fi

echo
echo '## A — the figures actually appear in DECISION.md'
assert_doc "DECISION.md states the 1.96 MSRV floor"          "1.96"
assert_doc "DECISION.md states config declares 1.85.0"       "1.85.0"
assert_doc "DECISION.md states confique declares 1.68.2"     "1.68.2"
assert_doc "DECISION.md states envy's 90-day downloads"      "3,574,490"
assert_doc "DECISION.md states config's 90-day downloads"    "18,581,807"
assert_doc "DECISION.md states figment's 90-day downloads"   "10,072,166"
assert_doc "DECISION.md states confique's 90-day downloads"  "158,359"
assert_doc "DECISION.md names the retrieval date"            "2026-09-18"
assert_doc "DECISION.md records config's transitive pathdiff 0.2.3 declaring no rust-version" "pathdiff\` 0.2.3"

echo
echo '## B — live re-fetch: immutable fields only (drift is printed, not asserted)'
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
if ! curl -sS --fail --max-time 25 -H "User-Agent: $UA" \
     https://crates.io/api/v1/crates/serde -o /dev/null 2>/dev/null; then
  sk "live crates.io re-fetch — no network or endpoint refused"
  sk "live RustSec re-fetch — no network or endpoint refused"
else
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/r77-figures.XXXXXX"); trap 'rm -rf "$tmp"' EXIT
  while IFS='|' read -r name version rustver license; do
    [ -n "$name" ] || continue
    curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
      "https://crates.io/api/v1/crates/${name}/versions" > "$tmp/$name.json"
    got_rv=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
v=[x for x in d["versions"] if x["num"]==sys.argv[2]]
print(str(v[0].get("rust_version")) if v else "VERSION-ABSENT")' "$tmp/$name.json" "$version")
    got_lic=$(python3 -c 'import json,sys
d=json.load(open(sys.argv[1]))
v=[x for x in d["versions"] if x["num"]==sys.argv[2]]
print(str(v[0].get("license")) if v else "VERSION-ABSENT")' "$tmp/$name.json" "$version")
    assert_eq "live: $name $version rust_version (immutable for a published version)" "$rustver" "$got_rv"
    assert_eq "live: $name $version license (metadata only — gate 1 is inapplicable)" "$license" "$got_lic"
    snap_recent=$(field "$snap/cratesio-${name}.json" 'd["crate"]["recent_downloads"]')
    live_recent=$(curl -sS --fail --max-time 30 -H "User-Agent: $UA" \
      "https://crates.io/api/v1/crates/${name}" | python3 -c 'import json,sys; print(json.load(sys.stdin)["crate"]["recent_downloads"])')
    printf 'DRIFT %s crate.recent_downloads snapshot=%s live=%s (counter; not asserted)\n' \
      "$name" "$snap_recent" "$live_recent"
  done <<'ROWS'
envy|0.4.2|None|MIT
config|0.15.25|1.85.0|MIT OR Apache-2.0
figment|0.10.19|None|MIT OR Apache-2.0
confique|0.4.0|1.68.2|MIT OR Apache-2.0
envconfig|0.11.1|None|MIT
serde-env|0.3.0|None|Apache-2.0
envious|0.3.0|None|MIT OR Apache-2.0
pathdiff|0.2.3|None|MIT/Apache-2.0
winnow|1.0.4|1.65.0|MIT
ROWS

  echo
  echo '## B — RustSec advisory pages (404 = no package page = no advisory)'
  # Two known-advisory pages are fetched as controls, so a 404 cannot be read
  # as "the method is broken".
  for n in envy config figment confique serde envconfig serde-env envious; do
    code=$(curl -s -o "$tmp/rs.html" -w '%{http_code}' --max-time 25 -H "User-Agent: $UA" \
           "https://rustsec.org/packages/${n}.html")
    hits=$(/usr/bin/grep -c 'RUSTSEC-' "$tmp/rs.html" || true)
    assert_eq "rustsec $n has no advisory page (HTTP 404, 0 RUSTSEC- mentions)" "404 0" "$code $hits"
  done
  for n in atty time; do
    code=$(curl -s -o "$tmp/rs.html" -w '%{http_code}' --max-time 25 -H "User-Agent: $UA" \
           "https://rustsec.org/packages/${n}.html")
    hits=$(/usr/bin/grep -c 'RUSTSEC-' "$tmp/rs.html" || true)
    if [ "$code" = "200" ] && [ "$hits" -gt 0 ]; then
      ok "rustsec CONTROL $n returns HTTP 200 with $hits RUSTSEC- mentions — the 404s above are real"
    else
      no "rustsec CONTROL $n returned HTTP $code with $hits RUSTSEC- mentions; the 404 method is unproven"
    fi
  done
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
