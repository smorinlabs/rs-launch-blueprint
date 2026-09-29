#!/usr/bin/env bash
# R74 — every registry, repository and advisory figure this decision cites, asserted
# against the payloads snapshotted under snapshots/ by r74-fetch-snapshots.sh.
#
# This script TOUCHES NO NETWORK. Its output is reproducible byte-for-byte for as long
# as the snapshots are unchanged, which is the point: download counters and star counts
# move daily, so the decision reads the snapshot and the snapshot carries its endpoint
# and its UTC retrieval time in snapshots/MANIFEST.tsv.
#
# To see drift, run r74-fetch-snapshots.sh (which overwrites the snapshots) and re-run this.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
chk()  { if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi; }

need() { # need <file> -> 0 if present
  if [ -f "$SNAP/$1" ]; then return 0; fi
  return 1
}

echo "grep:  $(/usr/bin/grep --version | head -1)"
echo "jq:    $(jq --version)"
echo "snapshots: $SNAP"
echo

# ---------------------------------------------------------------------------
echo "=== 0. the snapshot set itself ==="
if need MANIFEST.tsv; then
  rows="$(( $(/usr/bin/grep -c . "$SNAP/MANIFEST.tsv") - 1 ))"
  chk "S0a snapshot manifest rows" "37" "$rows"
  if /usr/bin/grep -q 'https://crates.io/api/v1/crates/governor/versions' "$SNAP/MANIFEST.tsv"; then ok "S0b the manifest records each payload's endpoint"; else bad "S0b endpoint column missing"; fi
  echo "     retrieval window: $(cut -f3 "$SNAP/MANIFEST.tsv" | tail -n +2 | sort | head -1) .. $(cut -f3 "$SNAP/MANIFEST.tsv" | tail -n +2 | sort | tail -1)"
else
  skip "S0a snapshots/MANIFEST.tsv absent"; skip "S0b snapshots/MANIFEST.tsv absent"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 1. the MSRV floor ==="
if need channel-rust-stable-pkg-rust.txt; then
  stable="$(/usr/bin/grep -m1 '^version = ' "$SNAP/channel-rust-stable-pkg-rust.txt" | sed -E 's/version = "([0-9.]+).*/\1/')"
  chk "F1a current stable (static.rust-lang.org channel-rust-stable.toml, [pkg.rust].version)" "1.98.1" "$stable"
  # msrv-policy = stable minus 2 minor versions
  minor="$(echo "$stable" | cut -d. -f2)"
  chk "F1b the floor stable-minus-2-minors" "1.96" "1.$((minor - 2))"
else
  skip "F1a channel snapshot absent"; skip "F1b channel snapshot absent"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 2. crates.io: downloads, newest non-yanked release, licence, rust-version ==="
# name | recent | all | num | created(date) | rust_version | license
while IFS='|' read -r name recent all num created rv lic; do
  [ -z "$name" ] && continue
  if ! need "cio-crate-$name.json" || ! need "cio-versions-$name.json"; then
    for f in dl90 dlall num rv lic; do skip "F2-$f $name — snapshot absent"; done
    continue
  fi
  chk "F2-dl90  $name crate.recent_downloads" "$recent" "$(jq -r '.crate.recent_downloads' "$SNAP/cio-crate-$name.json")"
  chk "F2-dlall $name crate.downloads"        "$all"    "$(jq -r '.crate.downloads' "$SNAP/cio-crate-$name.json")"
  v="$(jq -r '[.versions[]|select(.yanked==false)][0]' "$SNAP/cio-versions-$name.json")"
  chk "F2-num   $name newest non-yanked num"  "$num"     "$(echo "$v" | jq -r '.num')"
  chk "F2-date  $name newest non-yanked created_at" "$created" "$(echo "$v" | jq -r '.created_at[0:10]')"
  chk "F2-rv    $name newest non-yanked rust_version (GATE 2)" "$rv" "$(echo "$v" | jq -r '.rust_version')"
  chk "F2-lic   $name newest non-yanked license"               "$lic" "$(echo "$v" | jq -r '.license')"
done <<'ROWS'
tower_governor|1711259|4682920|0.8.0|2025-08-14|null|MIT OR Apache-2.0
governor|15833152|77888772|0.10.4|2025-12-16|null|MIT
tower-rate-limiter|294|294|0.1.6|2026-08-13|1.96.0|MIT OR Apache-2.0
axum-governor|12628|19973|2.1.0|2026-09-05|1.95|MIT
axum_gcra|60|7595|0.1.1|2024-08-11|null|MIT OR Apache-2.0
gcra|368570|2173132|0.6.0|2024-08-01|1.80.0|MIT
tower-resilience-ratelimiter|6279|14764|0.13.0|2026-08-21|1.85.0|MIT OR Apache-2.0
axum|118121099|476017735|0.8.9|2026-04-14|1.80|MIT
tower|174508765|670171877|0.5.3|2026-01-12|1.64.0|MIT
ROWS

# Control: the gate-2 reader must be able to report a DECLARED version, so the two
# `null` results above cannot be an artefact of reading the wrong field.
if need cio-versions-axum.json; then
  if [ "$(jq -r '[.versions[]|select(.yanked==false)][0].rust_version' "$SNAP/cio-versions-axum.json")" = "null" ]; then
    bad "F2-control the reader returned null for axum, which declares 1.80 — the nulls are not evidence"
  else
    ok  "F2-control the reader reports a declared rust_version for axum, so governor's and tower_governor's null is a real absence"
  fi
else
  skip "F2-control axum versions snapshot absent"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 3. crates.io: reverse dependencies (the practice-evidence figure) ==="
while IFS='|' read -r name total; do
  [ -z "$name" ] && continue
  if need "cio-revdeps-$name.json"; then
    chk "F3 $name reverse_dependencies meta.total" "$total" "$(jq -r '.meta.total' "$SNAP/cio-revdeps-$name.json")"
  else
    skip "F3 $name — snapshot absent"
  fi
done <<'ROWS'
governor|483
tower_governor|81
gcra|0
axum-governor|0
axum_gcra|0
tower-rate-limiter|0
ROWS

# ---------------------------------------------------------------------------
echo
echo "=== 4. RustSec (gate 3) ==="
if need rustsec-status.txt; then
  for c in tower_governor governor gcra axum-governor axum_gcra tower-rate-limiter; do
    chk "F4 rustsec.org/packages/$c.html" "404" "$(/usr/bin/grep -m1 "^$c " "$SNAP/rustsec-status.txt" | awk '{print $2}')"
  done
  # Control: a package that DOES have an advisory page must return 200, or the 404s
  # above would just be a blanket network failure.
  chk "F4-control rustsec.org/packages/dashmap.html (a package with a real advisory page)" "200" "$(/usr/bin/grep -m1 '^dashmap ' "$SNAP/rustsec-status.txt" | awk '{print $2}')"
else
  skip "F4 rustsec snapshot absent"; skip "F4-control rustsec snapshot absent"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 5. GitHub: maintenance state ==="
ghfield() { jq -r "$2" "$SNAP/$1"; }
if need gh-repo-benwis-tower-governor.json; then
  chk "F5a benwis/tower-governor stargazers_count" "351"        "$(ghfield gh-repo-benwis-tower-governor.json .stargazers_count)"
  chk "F5b benwis/tower-governor archived"         "false"      "$(ghfield gh-repo-benwis-tower-governor.json .archived)"
  chk "F5c benwis/tower-governor pushed_at"        "2025-08-14" "$(ghfield gh-repo-benwis-tower-governor.json .pushed_at | cut -c1-10)"
else
  skip "F5a-c tower-governor repo snapshot absent"
fi
if need gh-issues-open-tower-governor.json; then
  chk "F5d benwis/tower-governor open issues (search/issues total_count, never open_issues_count)" "19" "$(ghfield gh-issues-open-tower-governor.json .total_count)"
  # and the figure the prompt forbids, recorded so the difference is visible
  chk "F5e benwis/tower-governor open_issues_count (NOT used: it counts pull requests too)" "24" "$(ghfield gh-repo-benwis-tower-governor.json .open_issues_count)"
else
  skip "F5d-e issue-search snapshot absent"
fi
if need gh-repo-boinkor-net-governor.json; then
  chk "F5f boinkor-net/governor stargazers_count" "938"        "$(ghfield gh-repo-boinkor-net-governor.json .stargazers_count)"
  chk "F5g boinkor-net/governor archived"         "false"      "$(ghfield gh-repo-boinkor-net-governor.json .archived)"
  chk "F5h boinkor-net/governor pushed_at"        "2026-08-24" "$(ghfield gh-repo-boinkor-net-governor.json .pushed_at | cut -c1-10)"
else
  skip "F5f-h governor repo snapshot absent"
fi
if need gh-repo-canmi21-axum-governor.json; then
  chk "F5i canmi21/axum-governor stargazers_count" "25"         "$(ghfield gh-repo-canmi21-axum-governor.json .stargazers_count)"
  chk "F5j canmi21/axum-governor created_at"       "2025-09-03" "$(ghfield gh-repo-canmi21-axum-governor.json .created_at | cut -c1-10)"
else
  skip "F5i-j axum-governor repo snapshot absent"
fi
if need gh-repo-nivek-ph-tower-rate-limiter.json; then
  chk "F5k tower-rate-limiter stargazers_count"  "7"          "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .stargazers_count)"
  chk "F5l tower-rate-limiter repo created_at"   "2026-08-02" "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .created_at | cut -c1-10)"
  # the openai leg cited two different owners for this repo; both resolve, because the
  # account was renamed and GitHub redirects. Recorded so the leg is not called wrong.
  chk "F5m the nivek-ph/... path redirects to the renamed owner" "nivek3/tower-rate-limiter" "$(ghfield gh-repo-nivek-ph-tower-rate-limiter.json .full_name)"
else
  skip "F5k-m tower-rate-limiter repo snapshot absent"
fi

# ---------------------------------------------------------------------------
echo
echo "=== 6. GATE 2 at master, not only at the release ==="
b64() { jq -r '.content' "$SNAP/$1" | base64 -d; }
for pair in "gh-contents-governor-Cargo.toml.json governor" \
            "gh-contents-tower-governor-Cargo.toml.json tower_governor"; do
  read -r f label <<< "$pair"
  if need "$f"; then
    if b64 "$f" | /usr/bin/grep -qE '^rust-version[[:space:]]*='; then
      bad "F6 $label declares a rust-version at master — the release-lag reading would then apply"
    else
      ok  "F6 $label declares NO rust-version at master either, so the gate-2 failure is a standing property, not release lag"
    fi
  else
    skip "F6 $label — contents snapshot absent"
  fi
done
# Control: the same decoder must FIND a rust-version where one exists at master.
if need gh-contents-trl-Cargo.toml.json; then
  rv="$(b64 gh-contents-trl-Cargo.toml.json | /usr/bin/grep -m1 -E '^rust-version[[:space:]]*=' | sed -E 's/.*"([^"]*)".*/\1/')"
  chk "F6-control tower-rate-limiter rust-version at master (so F6's two absences are real)" "1.96.0" "$rv"
else
  skip "F6-control tower-rate-limiter contents snapshot absent"
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
