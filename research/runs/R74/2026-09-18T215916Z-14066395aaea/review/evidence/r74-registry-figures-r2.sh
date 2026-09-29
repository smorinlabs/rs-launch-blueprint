#!/usr/bin/env bash
# R74 revision 2 — every registry, repository and advisory figure the decision cites,
# asserted against the payloads r74-fetch-snapshots.sh saved under snapshots-r2/
# (retrieved 2026-09-27T06:26Z–06:30Z, per snapshots-r2/MANIFEST.tsv).
#
# Revision 1's r74-registry-figures.sh and its log are kept unchanged: they assert the
# 2026-09-19 figures against snapshots/ and stay reproducible byte-for-byte. Section 7 of
# this script asserts the drift between the two snapshot sets field by field, for every
# field a conclusion rests on, so a moved figure is recorded rather than asserted away.
#
# This script TOUCHES NO NETWORK. Its output is reproducible byte-for-byte for as long as
# both snapshot sets are unchanged.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots-r2"
OLD="$HERE/snapshots"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }

for f in MANIFEST.tsv channel-rust-stable-pkg-rust.txt rustsec-status.txt; do
  if [ ! -f "$SNAP/$f" ]; then echo "FATAL: $SNAP/$f is absent; run r74-fetch-snapshots.sh"; exit 1; fi
done

echo "grep:  $(/usr/bin/grep --version | head -1)"
echo "jq:    $(jq --version)"
echo "snapshots: snapshots-r2/ (revision 2) against snapshots/ (revision 1)"
echo

# ---------------------------------------------------------------------------
echo "=== 0. the snapshot set itself ==="
rows="$(( $(/usr/bin/grep -c . "$SNAP/MANIFEST.tsv") - 1 ))"
chk "S0a snapshot manifest rows (revision 1's 37 plus two reverse-dependency pages)" "39" "$rows"
if /usr/bin/grep -q 'https://crates.io/api/v1/crates/governor/versions' "$SNAP/MANIFEST.tsv"; then ok "S0b the manifest records each payload's endpoint"; else bad "S0b endpoint column missing"; fi
chk "S0c retrieval window start" "2026-09-27T06:26:22Z" "$(cut -f3 "$SNAP/MANIFEST.tsv" | tail -n +2 | sort | head -1)"
chk "S0d retrieval window end"   "2026-09-27T06:30:16Z" "$(cut -f3 "$SNAP/MANIFEST.tsv" | tail -n +2 | sort | tail -1)"

# ---------------------------------------------------------------------------
echo
echo "=== 1. the MSRV floor ==="
stable="$(/usr/bin/grep -m1 '^version = ' "$SNAP/channel-rust-stable-pkg-rust.txt" | sed -E 's/version = "([0-9.]+).*/\1/')"
chk "F1a current stable (static.rust-lang.org channel-rust-stable.toml, [pkg.rust].version)" "1.98.1" "$stable"
minor="$(echo "$stable" | cut -d. -f2)"
chk "F1b the floor stable-minus-2-minors" "1.96" "1.$((minor - 2))"

# ---------------------------------------------------------------------------
echo
echo "=== 2. crates.io: downloads, newest non-yanked release, licence, rust-version ==="
# name | recent | all | num | created(date) | rust_version | license
while IFS='|' read -r name recent all num created rv lic; do
  [ -z "$name" ] && continue
  chk "F2-dl90  $name crate.recent_downloads" "$recent" "$(jq -r '.crate.recent_downloads' "$SNAP/cio-crate-$name.json")"
  chk "F2-dlall $name crate.downloads"        "$all"    "$(jq -r '.crate.downloads' "$SNAP/cio-crate-$name.json")"
  v="$(jq -r '[.versions[]|select(.yanked==false)][0]' "$SNAP/cio-versions-$name.json")"
  chk "F2-num   $name newest non-yanked num"  "$num"     "$(echo "$v" | jq -r '.num')"
  chk "F2-date  $name newest non-yanked created_at" "$created" "$(echo "$v" | jq -r '.created_at[0:10]')"
  chk "F2-rv    $name newest non-yanked rust_version (GATE 2)" "$rv" "$(echo "$v" | jq -r '.rust_version')"
  chk "F2-lic   $name newest non-yanked license"               "$lic" "$(echo "$v" | jq -r '.license')"
done <<'ROWS'
tower_governor|1751434|4850651|0.8.0|2025-08-14|null|MIT OR Apache-2.0
governor|16487740|79753999|0.10.4|2025-12-16|null|MIT
tower-rate-limiter|296|296|0.1.6|2026-08-13|1.96.0|MIT OR Apache-2.0
axum-governor|12901|20931|2.1.2|2026-09-26|1.95|MIT
axum_gcra|57|7595|0.1.1|2024-08-11|null|MIT OR Apache-2.0
gcra|390704|2224275|0.6.0|2024-08-01|1.80.0|MIT
tower-resilience-ratelimiter|6978|15545|0.13.0|2026-08-21|1.85.0|MIT OR Apache-2.0
axum|121285860|488346635|0.8.9|2026-04-14|1.80|MIT
tower|178757718|687830161|0.5.3|2026-01-12|1.64.0|MIT
ROWS

# axum-governor released twice since revision 1; every release since 2.1.0 still declares 1.95.
while IFS='|' read -r num date rv; do
  [ -z "$num" ] && continue
  got="$(jq -r --arg n "$num" '.versions[]|select(.num==$n)|"\(.created_at[0:10])|\(.rust_version)|\(.yanked)"' "$SNAP/cio-versions-axum-governor.json")"
  chk "F2-ag axum-governor $num created_at|rust_version|yanked" "$date|$rv|false" "$got"
done <<'ROWS'
2.1.2|2026-09-26|1.95
2.1.1|2026-09-23|1.95
2.1.0|2026-09-05|1.95
ROWS

chk "F2-loco loco-rs newest version (crates.io crate.max_stable_version)" "1.2.0" "$(jq -r '.crate.max_stable_version' "$SNAP/cio-crate-loco-rs.json")"
chk "F2-loco loco-rs crate.recent_downloads" "107284" "$(jq -r '.crate.recent_downloads' "$SNAP/cio-crate-loco-rs.json")"

if [ "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$SNAP/cio-versions-axum.json")" = "null" ]; then
  bad "F2-control the reader returned null for axum, which declares 1.80 — the nulls are not evidence"
else
  ok  "F2-control the reader reports a declared rust_version for axum, so governor's and tower_governor's null is a real absence"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 3. crates.io: reverse dependencies (the practice-evidence figure) ==="
while IFS='|' read -r name total; do
  [ -z "$name" ] && continue
  chk "F3 $name reverse_dependencies meta.total" "$total" "$(jq -r '.meta.total' "$SNAP/cio-revdeps-$name.json")"
done <<'ROWS'
governor|489
tower_governor|82
gcra|0
axum-governor|0
axum_gcra|0
tower-rate-limiter|0
ROWS
# The adopters the Muse leg names, read from one 100-row page of each crate's dependents.
for pair in "governor foundations" "governor alloy-transport" "governor librespot-core" "governor sc-rpc-server" \
            "tower_governor iroh-dns-server" "tower_governor snarkos-node-rest" "tower_governor miden-node-utils" "tower_governor taxy"; do
  read -r crate adopter <<< "$pair"
  if jq -r '.versions[].crate' "$SNAP/cio-revdeps-page-$crate.json" | /usr/bin/grep -qx -- "$adopter"; then
    ok "F3-adopter $adopter depends on $crate (first 100 dependents, 2026-09-27)"
  else
    bad "F3-adopter $adopter is not among $crate's first 100 dependents"
  fi
done
if jq -r '.versions[].crate' "$SNAP/cio-revdeps-page-governor.json" | /usr/bin/grep -qx 'no-such-crate-r74'; then
  bad "F3-adopter-control the adopter reader matched a crate name that does not exist"
else
  ok "F3-adopter-control the adopter reader does not match an absent name"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 4. RustSec (gate 3) ==="
for c in tower_governor governor gcra axum-governor axum_gcra tower-rate-limiter; do
  chk "F4 rustsec.org/packages/$c.html" "404" "$(/usr/bin/grep -m1 "^$c " "$SNAP/rustsec-status.txt" | awk '{print $2}')"
done
chk "F4-control rustsec.org/packages/dashmap.html (a package with a real advisory page)" "200" "$(/usr/bin/grep -m1 '^dashmap ' "$SNAP/rustsec-status.txt" | awk '{print $2}')"

# ---------------------------------------------------------------------------
echo
echo "=== 5. GitHub: maintenance state ==="
ghfield() { jq -r "$2" "$SNAP/$1"; }
chk "F5a benwis/tower-governor stargazers_count" "352"        "$(ghfield gh-repo-benwis-tower-governor.json .stargazers_count)"
chk "F5b benwis/tower-governor archived"         "false"      "$(ghfield gh-repo-benwis-tower-governor.json .archived)"
chk "F5c benwis/tower-governor pushed_at"        "2025-08-14" "$(ghfield gh-repo-benwis-tower-governor.json .pushed_at | cut -c1-10)"
chk "F5d benwis/tower-governor open issues (search/issues total_count, never open_issues_count)" "19" "$(ghfield gh-issues-open-tower-governor.json .total_count)"
chk "F5e benwis/tower-governor open_issues_count (NOT used: it counts pull requests too)" "24" "$(ghfield gh-repo-benwis-tower-governor.json .open_issues_count)"
chk "F5f boinkor-net/governor stargazers_count" "938"        "$(ghfield gh-repo-boinkor-net-governor.json .stargazers_count)"
chk "F5g boinkor-net/governor archived"         "false"      "$(ghfield gh-repo-boinkor-net-governor.json .archived)"
chk "F5h boinkor-net/governor pushed_at"        "2026-08-24" "$(ghfield gh-repo-boinkor-net-governor.json .pushed_at | cut -c1-10)"
chk "F5i canmi21/axum-governor stargazers_count" "26"         "$(ghfield gh-repo-canmi21-axum-governor.json .stargazers_count)"
chk "F5j canmi21/axum-governor created_at"       "2025-09-03" "$(ghfield gh-repo-canmi21-axum-governor.json .created_at | cut -c1-10)"
chk "F5j2 canmi21/axum-governor pushed_at"       "2026-09-26" "$(ghfield gh-repo-canmi21-axum-governor.json .pushed_at | cut -c1-10)"
chk "F5k tower-rate-limiter stargazers_count"  "7"          "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .stargazers_count)"
chk "F5l tower-rate-limiter repo created_at"   "2026-08-02" "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .created_at | cut -c1-10)"
chk "F5m the nivek-ph/... path redirects to the renamed owner" "nivek3/tower-rate-limiter" "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .full_name)"
# the issue search against the pre-rename owner fails; recorded, not omitted
if /usr/bin/grep -qF 'HTTP 422' "$SNAP/gh-issues-open-tower-rate-limiter.json"; then ok "F5n the tower-rate-limiter open-issue search still returns HTTP 422 (renamed owner)"; else bad "F5n the tower-rate-limiter issue search no longer returns 422"; fi

# ---------------------------------------------------------------------------
echo
echo "=== 6. GATE 2 at master, not only at the release ==="
b64() { jq -r '.content' "$SNAP/$1" | base64 -d; }
for pair in "gh-contents-governor-Cargo.toml.json governor" \
            "gh-contents-tower-governor-Cargo.toml.json tower_governor"; do
  read -r f label <<< "$pair"
  if b64 "$f" | /usr/bin/grep -qE '^rust-version[[:space:]]*='; then
    bad "F6 $label declares a rust-version at master — the release-lag reading would then apply"
  else
    ok  "F6 $label declares NO rust-version at master either, so the gate-2 failure is a standing property, not release lag"
  fi
done
rv="$(b64 gh-contents-trl-Cargo.toml.json | /usr/bin/grep -m1 -E '^rust-version[[:space:]]*=' | sed -E 's/.*"([^"]*)".*/\1/')"
chk "F6-control tower-rate-limiter rust-version at master (so F6's two absences are real)" "1.96.0" "$rv"

# ---------------------------------------------------------------------------
echo
echo "=== 7. drift, 2026-09-19 (snapshots/) -> 2026-09-27 (snapshots-r2/), decision-bearing fields ==="
# drift <label> <expected-old> <expected-new> <old-value> <new-value>
drift() {
  if [ "$4" = "$2" ] && [ "$5" = "$3" ]; then
    if [ "$2" = "$3" ]; then ok "$1 unchanged: $2"; else ok "$1 moved: $2 -> $3"; fi
  else
    bad "$1: expected [$2 -> $3] got [$4 -> $5]"
  fi
}
newest() { jq -r '[.versions[]|select(.yanked==false)][0]|"\(.num) rv=\(.rust_version)"' "$1/cio-versions-$2.json"; }
for n in tower_governor governor tower-rate-limiter axum_gcra gcra tower-resilience-ratelimiter axum tower; do
  o="$(newest "$OLD" "$n")"; w="$(newest "$SNAP" "$n")"
  drift "DR-rel $n newest release and rust_version" "$o" "$o" "$o" "$w"
done
drift "DR-rel axum-governor newest release and rust_version" "2.1.0 rv=1.95" "2.1.2 rv=1.95" "$(newest "$OLD" axum-governor)" "$(newest "$SNAP" axum-governor)"
while IFS='|' read -r n o w; do
  [ -z "$n" ] && continue
  drift "DR-rev $n reverse_dependencies" "$o" "$w" "$(jq -r .meta.total "$OLD/cio-revdeps-$n.json")" "$(jq -r .meta.total "$SNAP/cio-revdeps-$n.json")"
done <<'ROWS'
governor|483|489
tower_governor|81|82
gcra|0|0
axum-governor|0|0
axum_gcra|0|0
tower-rate-limiter|0|0
ROWS
for f in gh-repo-benwis-tower-governor gh-repo-boinkor-net-governor gh-repo-canmi21-axum-governor gh-repo-nivek-ph-tower-rate-limiter; do
  o="$(jq -r .archived "$OLD/$f.json")"; w="$(jq -r .archived "$SNAP/$f.json")"
  drift "DR-arch $f archived" "false" "false" "$o" "$w"
done
drift "DR-push benwis/tower-governor pushed_at" "2025-08-14T19:44:19Z" "2025-08-14T19:44:19Z" "$(jq -r .pushed_at "$OLD/gh-repo-benwis-tower-governor.json")" "$(jq -r .pushed_at "$SNAP/gh-repo-benwis-tower-governor.json")"
drift "DR-push canmi21/axum-governor pushed_at" "2026-09-08T22:46:01Z" "2026-09-26T08:06:45Z" "$(jq -r .pushed_at "$OLD/gh-repo-canmi21-axum-governor.json")" "$(jq -r .pushed_at "$SNAP/gh-repo-canmi21-axum-governor.json")"
drift "DR-rustsec the seven status lines" "$(cat "$OLD/rustsec-status.txt" | tr '\n' ' ')" "$(cat "$OLD/rustsec-status.txt" | tr '\n' ' ')" "$(cat "$OLD/rustsec-status.txt" | tr '\n' ' ')" "$(cat "$SNAP/rustsec-status.txt" | tr '\n' ' ')"
drift "DR-stable current stable" "1.98.1" "1.98.1" "$(/usr/bin/grep -m1 '^version = ' "$OLD/channel-rust-stable-pkg-rust.txt" | sed -E 's/version = "([0-9.]+).*/\1/')" "$stable"
if cmp -s "$OLD/rest-api-standard.md" "$SNAP/rest-api-standard.md"; then ok "DR-std the REST standard snapshot is byte-identical in both sets"; else bad "DR-std the REST standard snapshot differs between the sets"; fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
