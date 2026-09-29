#!/usr/bin/env bash
# R51 container-image — live registry and package-index checks.
#
# Re-reads at their documented endpoints every figure this decision carries: the
# three base-image digests, the Rust release channel, cargo-chef's manifest at
# its tag, and its maintenance signals. Each check asserts on the VALUE it
# expects. Since revision 2 a pinned digest is checked by resolving it (HTTP 200
# on the manifest by digest), because a re-pushed tag does not unpin a digest;
# the tags' current digests are printed as dated observations.
#
# GitHub REST is reached through a keyring-authenticated `gh`, never more than
# one call per 20 seconds. Network-dependent checks SKIP by name when the host
# is offline; gh-dependent checks SKIP when gh is absent or not logged in.
#
# The cargo-chef manifest carries a maintainer's address, so this script reads
# only KEY COUNTS out of it and never echoes its contents.
set -euo pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS  %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL  %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP  %s — %s\n' "$1" "$2"; }
assert_eq() {
  if [ "$2" = "$3" ]; then pass "$1" "$4: $3"; else fail "$1" "$4: expected [$2], got [$3]"; fi
}

RUST_DIGEST=sha256:ca5c572a3d4e8acfa44bc065aa6d9dafbee398bf14ec376d2bcf955820a4c9f3
BOOKWORM_DIGEST=sha256:8d50cf1cfb8929fbf0c2c1bf654c1f21693862c1facf42d2926d7fed716422ac
BUSYBOX_DIGEST=sha256:32b5cdad7cce41dfd53d0ae06baebcf8357a147ee7694dc706911c373bc30c37
RUNTIME_DIGEST=sha256:54df941ed0d06a1bd95ef5e0ce391fd8d9f94b64782dc9a60062727849ee3f97

echo "=== R51 registry checks"
echo "date-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "grep:     $($GREP --version | head -1)"
echo "curl:     $(curl --version 2>/dev/null | head -1 || echo absent)"

TMP="$(mktemp -d "${TMPDIR:-/tmp}/r51-registries.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

online=no
if command -v curl >/dev/null 2>&1 \
   && curl -s -o /dev/null --max-time 20 https://static.rust-lang.org/dist/channel-rust-stable.toml; then
  online=yes
fi

UA="rs-launch-blueprint-research (+https://github.com/smorinlabs/rs-launch-blueprint)"

hub_digest() {
  curl -sS --max-time 30 "https://hub.docker.com/v2/repositories/library/$1/tags/$2" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin).get("digest",""))'
}

# Anonymous pull token for the Docker Hub registry API, the OCI distribution
# endpoint behind the hub.docker.com tag pages above.
hub_token() {
  curl -sS --max-time 20 \
    "https://auth.docker.io/token?service=registry.docker.io&scope=repository:library/$1:pull" \
    | python3 -c 'import sys,json; print(json.load(sys.stdin)["token"])'
}
IDX_ACCEPT='application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.list.v2+json'
# HTTP status of a HEAD on library/<repo>@<digest>: 200 means the pin still resolves.
hub_resolves() {
  curl -s -o /dev/null -w '%{http_code}' -I --max-time 30 \
    -H "Authorization: Bearer $(hub_token "$1")" -H "Accept: $IDX_ACCEPT" \
    "https://registry-1.docker.io/v2/library/$1/manifests/$2"
}
BOGUS_DIGEST=sha256:0000000000000000000000000000000000000000000000000000000000000000

if [ "$online" = yes ]; then
  # -------------------------------------------------- D1 the builder base image
  # Revision 2: the Dockerfile pins a DIGEST, so what must hold is that the
  # pinned digest still resolves. Docker Official Image tags are re-pushed on
  # every base-image rebuild, so the tag's current digest is printed as a dated
  # observation and is not asserted.
  assert_eq D1a 200 "$(hub_resolves rust "$RUST_DIGEST")" "rust@$RUST_DIGEST (the pinned builder) resolves"
  t=$(hub_digest rust 1.98.1-slim-trixie)
  s=$(hub_digest rust 1.98.1-slim)
  b=$(hub_digest rust 1.98.1-slim-bookworm)
  echo "observed-tag-digest rust:1.98.1-slim-trixie: $t"
  echo "observed-tag-digest rust:1.98.1-slim: $s"
  echo "observed-tag-digest rust:1.98.1-slim-bookworm: $b"
  # The decision states that `rust:<ver>-slim` MEANS trixie: the two tags carry
  # one digest today, whatever that digest is.
  if [ -n "$t" ] && [ "$s" = "$t" ]; then
    pass D1b "rust:1.98.1-slim and rust:1.98.1-slim-trixie carry the same current digest"
  else
    fail D1b "rust:1.98.1-slim [$s] differs from -slim-trixie [$t]; the suite-drift claim must be restated"
  fi
  if [ -n "$b" ] && [ "$b" != "$t" ]; then
    pass D1c "rust:1.98.1-slim-bookworm carries a different digest from -slim-trixie (suites really differ)"
  else
    fail D1c "bookworm [$b] and trixie [$t] share a digest; the suite-drift warning would be false"
  fi
  assert_eq D1d 200 "$(hub_resolves rust "$BOOKWORM_DIGEST")" "rust@$BOOKWORM_DIGEST (the runner-up builder) resolves"
  assert_eq D1e 404 "$(hub_resolves rust "$BOGUS_DIGEST")" \
    "an all-zero digest does not resolve (the control that keeps D1a/D1d/D2a from passing vacuously)"

  # ---------------------------------------------------------- D2 the probe image
  assert_eq D2a 200 "$(hub_resolves busybox "$BUSYBOX_DIGEST")" "busybox@$BUSYBOX_DIGEST (the pinned probe) resolves"
  echo "observed-tag-digest busybox:1.38.0-musl: $(hub_digest busybox 1.38.0-musl)"

  # -------------------------------------------------------- D3 the runtime image
  curl -sS -I --max-time 30 -H 'Accept: application/vnd.oci.image.index.v1+json' \
    "https://gcr.io/v2/distroless/cc-debian13/manifests/nonroot" > "$TMP/d13.head"
  r=$(tr -d '\r' < "$TMP/d13.head" | awk 'tolower($1)=="docker-content-digest:" {print $2}')
  echo "observed-tag-digest gcr.io/distroless/cc-debian13:nonroot: $r"
  code=$(curl -s -o /dev/null -w '%{http_code}' -I --max-time 30 -H "Accept: $IDX_ACCEPT" \
    "https://gcr.io/v2/distroless/cc-debian13/manifests/$RUNTIME_DIGEST")
  assert_eq D3a 200 "$code" "gcr.io/distroless/cc-debian13@$RUNTIME_DIGEST (the pinned runtime) resolves"
  ct=$(tr -d '\r' < "$TMP/d13.head" | awk 'tolower($1)=="content-type:" {print $2}')
  assert_eq D3b 'application/vnd.oci.image.index.v1+json' "$ct" \
    "the :nonroot tag is a multi-architecture OCI index"
  # The cc-debian13 line EXISTING is the single fact that moves this decision
  # away from the owner reference's cc-debian12. It is read, not assumed.
  curl -sS --max-time 45 "https://gcr.io/v2/distroless/cc-debian13/tags/list" > "$TMP/d13.tags"
  n=$(python3 -c 'import sys,json; print(len(json.load(open(sys.argv[1]))["tags"]))' "$TMP/d13.tags")
  if [ "$n" -gt 1000 ]; then
    pass D3c "cc-debian13 publishes $n tags"
  else
    fail D3c "cc-debian13 published only $n tags"
  fi
  for t in latest nonroot debug debug-nonroot; do
    if python3 -c 'import sys,json; sys.exit(0 if sys.argv[2] in json.load(open(sys.argv[1]))["tags"] else 1)' \
        "$TMP/d13.tags" "$t"; then
      pass "D3-$t" "cc-debian13 publishes the :$t tag"
    else
      fail "D3-$t" "cc-debian13 does not publish :$t"
    fi
  done

  # ---------------------------------------------------- D4 the Rust release channel
  curl -sS --max-time 30 https://static.rust-lang.org/dist/channel-rust-stable.toml > "$TMP/channel.toml"
  python3 - "$TMP/channel.toml" > "$TMP/channel.txt" <<'PY'
import re, sys
text = open(sys.argv[1], encoding="utf-8").read()
print(re.search(r'^date = "([^"]+)"', text, re.M).group(1))
start = text.index("[pkg.rust]")
print(re.search(r'version = "([^"]+)"', text[start:start + 400]).group(1))
PY
  chan_date=$(sed -n 1p "$TMP/channel.txt")
  chan_ver=$(sed -n 2p "$TMP/channel.txt")
  assert_eq D4a '2026-09-03' "$chan_date" "the stable channel's own date"
  case "$chan_ver" in
    1.98.1*) pass D4b "stable is $chan_ver, so the msrv-policy floor is 1.96 and the builder satisfies it" ;;
    *) fail D4b "stable has moved to [$chan_ver]; the 1.96 floor and the builder tag must be recomputed" ;;
  esac

  # -------------------------------------------------------- D5 crates.io figures
  curl -sS --max-time 30 -A "$UA" "https://crates.io/api/v1/crates/cargo-chef/versions" > "$TMP/chef.json"
  python3 - "$TMP/chef.json" > "$TMP/chef.txt" <<'PYCHEF'
import json, sys
data = json.load(open(sys.argv[1], encoding="utf-8"))
live = [v for v in data["versions"] if not v["yanked"]]
newest = max(live, key=lambda v: v["created_at"])
print(newest["num"])
print("null" if newest.get("rust_version") is None else newest["rust_version"])
print(newest["created_at"])
print(len(live))
PYCHEF
  chef_ver=$(sed -n 1p "$TMP/chef.txt")
  chef_rv=$(sed -n 2p "$TMP/chef.txt")
  chef_at=$(sed -n 3p "$TMP/chef.txt")
  chef_n=$(sed -n 4p "$TMP/chef.txt")
  assert_eq D5a '0.1.78' "$chef_ver" "cargo-chef's newest non-yanked version, by created_at"
  assert_eq D5b 'null' "$chef_rv" "cargo-chef 0.1.78's declared rust_version on crates.io"
  case "$chef_at" in
    2026-08-12*) pass D5c "0.1.78 was published $chef_at, five weeks before the research date" ;;
    *) fail D5c "0.1.78 created_at moved to [$chef_at]" ;;
  esac
  if [ "$chef_n" -gt 50 ]; then
    pass D5d "the listing carries $chef_n live versions, so D5a picked a maximum rather than the only row"
  else
    fail D5d "only $chef_n live versions returned"
  fi
  curl -sS --max-time 30 -A "$UA" "https://crates.io/api/v1/crates/cargo-chef" > "$TMP/chefcrate.json"
  python3 - "$TMP/chefcrate.json" > "$TMP/chefdl.txt" <<'PYDL'
import json, sys
crate = json.load(open(sys.argv[1], encoding="utf-8"))["crate"]
print(crate["recent_downloads"])
print(crate["downloads"])
PYDL
  recent=$(sed -n 1p "$TMP/chefdl.txt")
  alltime=$(sed -n 2p "$TMP/chefdl.txt")
  if [ "$recent" -gt 100000 ] && [ "$alltime" -gt "$recent" ]; then
    pass D5e "cargo-chef recent_downloads $recent, downloads $alltime (adoption is real; the gate is not about it)"
  else
    fail D5e "unexpected download figures: recent $recent, all-time $alltime"
  fi

  # ------------------------------------------------------------- D6 RustSec
  # 404 means "no advisory page", which is only meaningful once the convention
  # is checked against a package that DOES have one.
  code_chef=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://rustsec.org/packages/cargo-chef.html)
  code_ctl=$(curl -s -o /dev/null -w '%{http_code}' --max-time 20 https://rustsec.org/packages/atty.html)
  assert_eq D6a '404' "$code_chef" "rustsec.org page for cargo-chef"
  assert_eq D6b '200' "$code_ctl" "rustsec.org page for atty (the positive control)"
else
  for id in D1a D1b D1c D1d D1e D2a D3a D3b D3c D3-latest D3-nonroot D3-debug D3-debug-nonroot \
            D4a D4b D5a D5b D5c D5d D5e D6a D6b; do
    skip "$id" "this host has no network reach to the documented endpoints"
  done
fi

# ------------------------------------------------- G1 the gate-2 manifest read
# Read at the TAG, not from a package summary. Only counts leave this block.
if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
  echo "gh-call-1-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if gh api "repos/LukeMathWalker/cargo-chef/contents/Cargo.toml?ref=v0.1.78" --jq '.content' \
      2>/dev/null | base64 -d > "$TMP/chef.toml"; then
    bytes=$(wc -c < "$TMP/chef.toml" | tr -d ' ')
    rv=$({ $GREP -c -i -E '^[[:space:]]*rust-version[[:space:]]*=' "$TMP/chef.toml" || true; })
    ed=$({ $GREP -c -i -E '^[[:space:]]*edition[[:space:]]*=' "$TMP/chef.toml" || true; })
    if [ "$bytes" -gt 200 ]; then
      pass G1a "cargo-chef's manifest read at tag v0.1.78 ($bytes bytes)"
    else
      fail G1a "the fetched manifest is only $bytes bytes"
    fi
    assert_eq G1b 0 "$rv" "rust-version keys in cargo-chef's manifest at v0.1.78 (gate 2 FAILS)"
    if [ "$ed" -ge 1 ]; then
      pass G1c "the same search finds $ed edition key(s), so G1b's zero is not a failed read"
    else
      fail G1c "no edition key found; G1b's zero proves nothing"
    fi
    edv=$({ $GREP -m1 -i -E '^[[:space:]]*edition[[:space:]]*=' "$TMP/chef.toml" || true; })
    assert_eq G1d 'edition = "2018"' "$edv" "cargo-chef's declared edition"
  else
    skip G1a "gh could not read the tagged manifest"
    skip G1b "gh could not read the tagged manifest"
    skip G1c "gh could not read the tagged manifest"
    skip G1d "gh could not read the tagged manifest"
  fi

  sleep 21
  echo "gh-call-2-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if gh api "repos/LukeMathWalker/cargo-chef/issues?state=all&sort=created&direction=desc&per_page=10" \
      --jq '.[] | [(if .pull_request then "PR" else "ISSUE" end), .comments] | @tsv' \
      > "$TMP/issues.tsv" 2>/dev/null; then
    rows=$(wc -l < "$TMP/issues.tsv" | tr -d ' ')
    issues=$({ $GREP -c '^ISSUE' "$TMP/issues.tsv" || true; })
    silent=$({ $GREP -c -E '^ISSUE\s+0$' "$TMP/issues.tsv" || true; })
    assert_eq G2a 10 "$rows" "items returned by the ten-most-recent listing"
    if [ "$issues" -gt 0 ] && [ "$silent" -eq "$issues" ]; then
      pass G2b "all $issues issues among the ten most recent items carry 0 comments (the at-risk signal)"
    else
      fail G2b "$silent of $issues recent issues are unanswered; the at-risk verdict must be restated"
    fi
    if [ "$issues" -lt 10 ]; then
      pass G2c "the rubric's ten-issue sample is only $issues deep here, and is reported as such"
    else
      pass G2c "a full ten-issue sample was available"
    fi
  else
    skip G2a "gh could not read the issue listing"
    skip G2b "gh could not read the issue listing"
    skip G2c "gh could not read the issue listing"
  fi

  # Revision 2: the prompt's rubric samples the "10 most recently opened
  # issues". The listing above mixes pull requests in, so the rubric's own
  # sample is read separately, issues only.
  sleep 21
  echo "gh-call-2b-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if gh api "search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue&sort=created&order=desc&per_page=10" \
      --jq '.items[] | [.number, .comments, .created_at[0:10]] | @tsv' > "$TMP/issues10.tsv" 2>/dev/null; then
    n10=$(wc -l < "$TMP/issues10.tsv" | tr -d ' ')
    z10=$(awk -F'\t' '$2 == 0' "$TMP/issues10.tsv" | wc -l | tr -d ' ')
    first=$(tail -1 "$TMP/issues10.tsv" | cut -f3); last=$(head -1 "$TMP/issues10.tsv" | cut -f3)
    nums=$(cut -f1 "$TMP/issues10.tsv" | tr '\n' ' ')
    echo "issue-sample-numbers: $nums"
    assert_eq G2d 10 "$n10" "issues in the rubric's ten-most-recently-opened sample"
    if [ "$n10" -gt 0 ] && [ "$z10" -eq "$n10" ]; then
      pass G2e "all $z10 of $n10 sampled issues ($first to $last) carry 0 comments: unanswered $z10 of $n10"
    else
      fail G2e "$z10 of $n10 sampled issues carry 0 comments; the at-risk reading must be restated"
    fi
  else
    skip G2d "gh could not run the issues-only search"
    skip G2e "gh could not run the issues-only search"
  fi

  sleep 21
  echo "gh-call-3-utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  if open=$(gh api "search/issues?q=repo:LukeMathWalker/cargo-chef+is:issue+is:open" --jq '.total_count' 2>/dev/null); then
    if [ "$open" -gt 0 ]; then
      pass G3a "cargo-chef open issues by the prompt's endpoint: $open"
    else
      fail G3a "the open-issue search returned $open"
    fi
  else
    skip G3a "gh could not run the open-issue search"
  fi
else
  for id in G1a G1b G1c G1d G2a G2b G2c G2d G2e G3a; do
    skip "$id" "gh is absent or not authenticated on this host"
  done
fi

echo
echo "grep-version: $($GREP --version | head -1)"
echo "SUMMARY: PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS + FAIL + SKIP))"
[ "$FAIL" -eq 0 ] || exit 1
exit 0
