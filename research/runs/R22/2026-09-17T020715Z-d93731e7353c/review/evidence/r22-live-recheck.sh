#!/usr/bin/env bash
# R22 runtime-version-accessor -- live re-checks against the recorded endpoints.
#
# THIS LOG DOES NOT REPRODUCE BYTE-FOR-BYTE, deliberately. It queries live
# endpoints, and three things in it move: the `run-started-utc` line, the
# download counters (crates.io `recent_downloads` is a rolling 90-day window and
# can fall as well as rise), and the star counts. Those are PRINTED, never
# asserted. What IS asserted is the small set of facts this decision rests on
# and that are supposed to hold still: the advisory posture of the four crates,
# the newest published version of each candidate, and the current Rust stable
# release that sets the MSRV floor. Each of those assertions is also this item's
# re-verify trigger made executable -- when one fails, the decision needs
# re-reading, which is exactly what a re-verify trigger is for.
#
# Every request carries a User-Agent naming the repository, never a personal
# address. With no network reachable every check becomes a NAMED SKIP and the
# script still exits 0; a reachable endpoint returning the wrong content is a
# FAIL.
set -euo pipefail

GREP=/usr/bin/grep
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
PASS=0
FAIL=0
SKIP=0

pass() { PASS=$((PASS + 1)); printf 'PASS %s -- %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s -- %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s -- %s\n' "$1" "$2"; }

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SNAP="$SCRIPT_DIR/snapshots"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r22-live.XXXXXX")"
trap 'rm -rf "$WORK"' EXIT

echo "=== R22 live re-check (volatile; see the header for what varies) ==="
echo "run-started-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep: $($GREP --version | head -1)"
echo "curl: $(curl --version | head -1)"
echo

ONLINE=no
if curl -sS -m 20 -o /dev/null -H "User-Agent: $UA" https://rustsec.org/ 2>/dev/null; then
  ONLINE=yes
fi
if [ "$ONLINE" = no ]; then
  echo "No network reachable from this host; every check below is skipped by name."
fi

# http_code <url> -> prints the status, or the empty string when unreachable
http_code() {
  curl -sS -m 30 -o /dev/null -w '%{http_code}' -H "User-Agent: $UA" "$1" 2>/dev/null || true
}

# ---------------------------------------------------------------------------
# L1 -- advisory posture, with both controls, so the 404 is read correctly.
#
# rustsec.org serves /packages/<name>.html only for a crate that has at least
# one advisory on record. serde is the negative control (an enormous crate that
# has never had one) and tokio and git2 are positive controls. Without the
# controls a 404 would mean "status unknown", which is how the raw report read
# it; with them it means "no advisory".
# ---------------------------------------------------------------------------
check_rustsec() {
  local name="$1" want="$2" note="$3" code
  if [ "$ONLINE" = no ]; then
    skip "L1-$name" "rustsec.org unreachable; advisory posture for $name not re-checked"
    return
  fi
  code="$(http_code "https://rustsec.org/packages/$name.html")"
  if [ "$code" = "$want" ]; then
    pass "L1-$name" "rustsec.org/packages/$name.html -> $code ($note)"
  else
    fail "L1-$name" "rustsec.org/packages/$name.html -> $code, expected $want ($note)"
  fi
}
check_rustsec serde 404 "negative control: a crate with no advisory has no page"
check_rustsec tokio 200 "positive control: a crate with advisories has a page"
check_rustsec git2 200 "positive control: carries RUSTSEC-2026-0183 and -0184"
check_rustsec built 404 "no advisory on record against built"
check_rustsec vergen-gix 404 "no advisory on record against vergen-gix"
check_rustsec shadow-rs 404 "no advisory against shadow-rs ITSELF; its default git2 dependency is the problem"

# ---------------------------------------------------------------------------
# L2 -- the candidates' newest published version. Asserted against the
# snapshot; the download and star figures beside it are printed, not asserted.
# ---------------------------------------------------------------------------
check_crate() {
  local name="$1" expect_num="$2"
  if [ "$ONLINE" = no ]; then
    skip "L2-$name" "crates.io unreachable; $name's newest version not re-checked"
    return
  fi
  if ! curl -sS -m 30 -H "User-Agent: $UA" \
      -o "$WORK/$name-versions.json" "https://crates.io/api/v1/crates/$name/versions"; then
    skip "L2-$name" "crates.io versions endpoint for $name did not respond"
    return
  fi
  if ! curl -sS -m 30 -H "User-Agent: $UA" \
      -o "$WORK/$name.json" "https://crates.io/api/v1/crates/$name"; then
    skip "L2-$name" "crates.io crate endpoint for $name did not respond"
    return
  fi
  local got
  got="$(python3 -c "
import json,sys
v=json.load(open(sys.argv[1]))['versions']
c=json.load(open(sys.argv[2]))['crate']
n=next(x for x in v if not x['yanked'])
print(n['num'], n['created_at'][:10], c['recent_downloads'], c['downloads'])
" "$WORK/$name-versions.json" "$WORK/$name.json")"
  local num
  num="$(echo "$got" | cut -d' ' -f1)"
  printf 'DRIFT %s: newest_non_yanked/created_at/recent_downloads/downloads = %s\n' "$name" "$got"
  if [ "$num" = "$expect_num" ]; then
    pass "L2-$name" "$name's newest non-yanked version is still $num, as snapshotted 2026-09-18"
  else
    fail "L2-$name" "$name's newest non-yanked version is now $num, was $expect_num on 2026-09-18"
  fi
}
check_crate built 0.8.1
check_crate shadow-rs 2.0.0
check_crate vergen-gix 10.0.3

# ---------------------------------------------------------------------------
# L3 -- the Rust stable release that sets the MSRV floor. A bump here moves the
# floor by one minor and is a re-verify trigger for every gate-2 verdict.
# ---------------------------------------------------------------------------
if [ "$ONLINE" = no ]; then
  skip L3 "static.rust-lang.org unreachable; the MSRV floor was not re-derived"
else
  if curl -sS -m 60 -H "User-Agent: $UA" \
      -o "$WORK/channel.toml" https://static.rust-lang.org/dist/channel-rust-stable.toml; then
    NOW_STABLE="$(awk '/^\[pkg\.rust\]/{f=1} f&&/^version/{print; exit}' "$WORK/channel.toml" \
      | sed 's/^version = "//; s/ .*//')"
    SNAP_STABLE="$($GREP -m1 '^version = ' "$SNAP/channel-rust-stable-excerpt.toml" \
      | sed 's/^version = "//; s/ .*//')"
    printf 'DRIFT rust-stable: now %s, snapshotted %s\n' "$NOW_STABLE" "$SNAP_STABLE"
    if [ "$NOW_STABLE" = "$SNAP_STABLE" ]; then
      pass L3 "Rust stable is still $NOW_STABLE, so the msrv-policy floor is still 1.96"
    else
      fail L3 "Rust stable moved to $NOW_STABLE; re-derive the floor and re-read every gate-2 verdict"
    fi
  else
    skip L3 "the stable channel manifest did not download"
  fi
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAIL: $FAIL  SKIP: $SKIP"
if [ "$SKIP" -ne 0 ]; then
  echo "NOTE: every skip above names the endpoint that was unreachable."
fi
if [ "$FAIL" -ne 0 ]; then
  echo "RESULT: FAIL"
  exit 1
fi
echo "RESULT: PASS"
