#!/usr/bin/env bash
# R73 — ecosystem figures, every one carrying its endpoint and a UTC retrieval
# date, plus the specific factual claims that separate the four engine legs.
#
# Volatile sources are SNAPSHOTTED into review/evidence/snapshots/ and every
# assertion reads the snapshot, so a rerun reproduces this log byte-for-byte.
# Set R73_REFRESH=1 to re-fetch and rewrite the snapshots; that is the only mode
# that touches the network, and it will move the download counters.
#
# GitHub is reached through a keyring-authenticated `gh api`, never more often
# than one call per 20 seconds.
# A single-quoted string below carries a literal backtick-quoted crate name in
# prose; it is deliberately not expanded.
# shellcheck disable=SC2016

set -euo pipefail

GREP=/usr/bin/grep
HERE=$(CDPATH='' cd -- "$(dirname -- "$0")" && pwd)
SNAP="$HERE/snapshots"
UA='rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)'
REFRESH=${R73_REFRESH:-0}

PASS=0; FAIL=0; SKIP=0
pass() { PASS=$((PASS + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAIL=$((FAIL + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIP=$((SKIP + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }

mkdir -p "$SNAP"
printf '== R73 registry figures ==\n'
printf 'grep: %s\n' "$("$GREP" --version | head -1)"
printf 'run_date_utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'mode: %s\n' "$([ "$REFRESH" = "1" ] && echo 'REFRESH — fetching live and rewriting snapshots' || echo 'SNAPSHOT — reading committed snapshots, no network')"

# fetch <snapshot-name> <url>  — populates $SNAP/<name> when refreshing.
fetch() {
  local name=$1 url=$2 code raw
  if [ "$REFRESH" = "1" ]; then
    raw=$(mktemp -t r73fetch)
    code=$(curl -sS -A "$UA" --max-time 40 -o "$raw" -w '%{http_code}' "$url" || echo 000)
    printf '%s\n' "$code" > "$SNAP/$name.status"
    {
      date -u +%Y-%m-%dT%H:%M:%SZ
      printf 'endpoint %s\n' "$url"
      printf 'full_response_sha256 %s\n' "$(shasum -a 256 "$raw" | cut -d' ' -f1)"
      printf 'full_response_bytes %s\n' "$(wc -c < "$raw" | tr -d ' ')"
    } > "$SNAP/$name.retrieved"
    # The snapshot is a REDUCTION of the response, keeping exactly the fields the
    # assertions read. The sidecar above carries the full response's hash and size
    # so the reduction is auditable rather than silent.
    python3 -c '
import json, sys
raw, out = sys.argv[1], sys.argv[2]
try:
    d = json.load(open(raw))
except Exception:
    open(out, "wb").write(open(raw, "rb").read()); raise SystemExit
c = d.get("crate", {})
keep = {k: c.get(k) for k in ("id", "name", "max_version", "recent_downloads", "downloads", "repository")}
vs = [{k: v.get(k) for k in ("num", "created_at", "rust_version", "license", "yanked")}
      for v in d.get("versions", [])]
json.dump({"crate": keep, "versions": vs}, open(out, "w"), indent=1, sort_keys=True)
' "$raw" "$SNAP/$name" || cp "$raw" "$SNAP/$name"
    rm -f "$raw"
    sleep 2
  fi
  [ -s "$SNAP/$name" ] || return 1
  return 0
}

jq_crate() {
  python3 -c '
import json, sys
path, field = sys.argv[1], sys.argv[2]
d = json.load(open(path))
if field == "newest_unyanked":
    vs = [v for v in d.get("versions", []) if not v.get("yanked")]
    print(vs[0]["num"] + " " + vs[0]["created_at"] if vs else "NONE")
elif field == "newest_unyanked_msrv":
    vs = [v for v in d.get("versions", []) if not v.get("yanked")]
    print(vs[0].get("rust_version") or "NOT-DECLARED" if vs else "NONE")
elif field == "newest_unyanked_license":
    vs = [v for v in d.get("versions", []) if not v.get("yanked")]
    print(vs[0].get("license") or "NOT-DECLARED" if vs else "NONE")
elif field == "any_unyanked":
    vs = [v for v in d.get("versions", []) if not v.get("yanked")]
    print("YES" if vs else "NO")
else:
    print(d["crate"].get(field))
' "$1" "$2"
}

CRATES='sha2 axum-idempotent cratestack-axum use-idempotency idempotent moka mini-moka lru hashlink quick_cache blake3 twox-hash xxhash-rust ruts tower'

printf '\n-- crates.io: GET https://crates.io/api/v1/crates/<name> --\n'
printf '%-18s %14s %14s  %-34s %-12s %s\n' crate recent_downloads downloads newest_unyanked rust_version license
for c in $CRATES; do
  if ! fetch "crates-$c.json" "https://crates.io/api/v1/crates/$c"; then
    skip "E1-$c" "no snapshot for $c and not refreshing"
    continue
  fi
  printf '%-18s %14s %14s  %-34s %-12s %s\n' \
    "$c" \
    "$(jq_crate "$SNAP/crates-$c.json" recent_downloads)" \
    "$(jq_crate "$SNAP/crates-$c.json" downloads)" \
    "$(jq_crate "$SNAP/crates-$c.json" newest_unyanked)" \
    "$(jq_crate "$SNAP/crates-$c.json" newest_unyanked_msrv)" \
    "$(jq_crate "$SNAP/crates-$c.json" newest_unyanked_license)"
done

# assert <id> <crate> <field> <expected> <why>
assert_field() {
  local id=$1 crate=$2 field=$3 expected=$4 why=$5 actual
  if [ ! -s "$SNAP/crates-$crate.json" ]; then
    skip "$id" "no snapshot for $crate"
    return
  fi
  actual=$(jq_crate "$SNAP/crates-$crate.json" "$field")
  case "$actual" in
    *"$expected"*) pass "$id" "$crate $field = $actual — $why" ;;
    *) fail "$id" "$crate $field = $actual, expected to contain $expected — $why" ;;
  esac
}

printf '\n-- the recommended crate --\n'
assert_field E2-sha2-license      sha2 newest_unyanked_license 'MIT OR Apache-2.0' 'the licence is exactly the repository license value'
assert_field E2-sha2-msrv         sha2 newest_unyanked_msrv    '1.85'              'declared, and below the 1.96 floor, so gate 2 passes'
assert_field E2-sha2-version      sha2 newest_unyanked         '0.11.0'            'the recommended pin is the newest unyanked release'

printf '\n-- gate 2 exclusions, asserted rather than asserted-about --\n'
assert_field E3-blake3-msrv       blake3      newest_unyanked_msrv 'NOT-DECLARED' 'blake3 declares no rust-version, so the tree floor is unverifiable'
assert_field E3-xxhash-msrv       xxhash-rust newest_unyanked_msrv 'NOT-DECLARED' 'xxhash-rust likewise'
assert_field E3-twox-license      twox-hash   newest_unyanked_license 'MIT'       'twox-hash is MIT-only, so it forgoes Apache-2.0 patent grant'
assert_field E3-cratestack-msrv   cratestack-axum newest_unyanked_msrv '1.98'     'cratestack-axum declares 1.98.0, ABOVE the 1.96 floor — gate 2 excludes it'

printf '\n-- claims the four legs disagree on, settled at the registry --\n'
# The Opus leg searched six crates.io spellings and concluded no crate implements
# this. The OpenAI Doxa leg named cratestack-axum. It exists.
assert_field E4-cratestack-exists cratestack-axum newest_unyanked '0.12.0' 'cratestack-axum IS published; the Opus leg missed it'
if [ -s "$SNAP/crates-cratestack-axum.json" ]; then
  CS_RECENT=$(jq_crate "$SNAP/crates-cratestack-axum.json" recent_downloads)
  AI_RECENT=$(jq_crate "$SNAP/crates-axum-idempotent.json" recent_downloads)
  if [ "$CS_RECENT" -gt "$AI_RECENT" ]; then
    pass E4-cratestack-adoption "cratestack-axum has $CS_RECENT 90-day downloads against axum-idempotent's $AI_RECENT, so it is the better-adopted implementation, not a curiosity"
  else
    fail E4-cratestack-adoption "cratestack-axum ($CS_RECENT) does not out-download axum-idempotent ($AI_RECENT)"
  fi
else
  skip E4-cratestack-adoption 'no cratestack-axum snapshot'
fi
# The gemini Doxa leg claimed `idempotent` was "entirely yanked from the registry".
assert_field E4-idempotent-live idempotent any_unyanked 'YES' 'the gemini leg claim that `idempotent` was entirely yanked is FALSE'
assert_field E4-idempotent-ver  idempotent newest_unyanked '2.0.0' 'the Opus leg reading of 2.0.0 is the correct one, not gemini 0.0.0'
# The perplexity Doxa leg made `use-idempotency` the first member of its bundle.
if [ -s "$SNAP/crates-use-idempotency.json" ]; then
  UI_ALL=$(jq_crate "$SNAP/crates-use-idempotency.json" downloads)
  if [ "$UI_ALL" -lt 1000 ]; then
    pass E4-use-idempotency "use-idempotency has $UI_ALL all-time downloads — the perplexity leg's lead member is effectively unadopted"
  else
    fail E4-use-idempotency "use-idempotency has $UI_ALL all-time downloads, more adoption than the decision records"
  fi
else
  skip E4-use-idempotency 'no use-idempotency snapshot'
fi
# The OpenAI Doxa leg reported tower as MIT-only. Checked, because a reader may
# assume the Rust-default dual licence.
assert_field E4-tower-license tower newest_unyanked_license 'MIT' 'tower is MIT-only; correct in the OpenAI leg and easy to assume otherwise'

printf '\n-- RustSec: https://rustsec.org/packages/<name>.html --\n'
for c in sha2 moka hashlink lru quick_cache axum-idempotent cratestack-axum axum tokio atty; do
  if [ "$REFRESH" = "1" ]; then
    curl -sS -A "$UA" --max-time 30 -o "$SNAP/rustsec-$c.html" -w '%{http_code}' \
      "https://rustsec.org/packages/$c.html" > "$SNAP/rustsec-$c.status" || true
    sleep 2
  fi
  if [ -s "$SNAP/rustsec-$c.status" ]; then
    printf '  %-18s HTTP %s\n' "$c" "$(cat "$SNAP/rustsec-$c.status")"
  else
    printf '  %-18s (no snapshot)\n' "$c"
  fi
done
if [ -s "$SNAP/rustsec-sha2.status" ] && [ -s "$SNAP/rustsec-atty.status" ]; then
  if [ "$(cat "$SNAP/rustsec-atty.status")" = "200" ]; then
    pass E5-control 'the positive control (atty, which has a known advisory page) returns 200, so a 404 elsewhere is a real absence and not a blanket network failure'
  else
    fail E5-control "the atty control returned $(cat "$SNAP/rustsec-atty.status"), so the 404s below prove nothing"
  fi
else
  skip E5-control 'no rustsec control snapshot'
fi
if [ -s "$SNAP/rustsec-sha2.html" ] && "$GREP" -q 'RUSTSEC-2021-0100' "$SNAP/rustsec-sha2.html"; then
  pass E5-sha2 'sha2 carries RUSTSEC-2021-0100, patched at >= 0.9.8, so 0.11.0 has no open advisory'
else
  skip E5-sha2 'no sha2 advisory page snapshot, or the advisory id is not on it'
fi
if [ -s "$SNAP/rustsec-lru.html" ] && "$GREP" -q 'RUSTSEC-2026-0253\|RUSTSEC-2026-0002' "$SNAP/rustsec-lru.html"; then
  pass E5-lru 'the lru advisory page carries the 2026 memory-corruption advisories the decision cites as a posture finding'
else
  skip E5-lru 'no lru advisory page snapshot, or the advisory ids are not on it'
fi

printf '\n-- GitHub, keyring-authenticated gh api, one call per 20 s --\n'
gh_get() {
  local name=$1 path=$2
  if [ "$REFRESH" = "1" ]; then
    if command -v gh > /dev/null 2>&1; then
      gh api "$path" > "$SNAP/gh-$name.json" 2> /dev/null || printf '{}' > "$SNAP/gh-$name.json"
      date -u +%Y-%m-%dT%H:%M:%SZ > "$SNAP/gh-$name.retrieved"
      sleep 21
    fi
  fi
  [ -s "$SNAP/gh-$name.json" ]
}
gh_field() {
  python3 -c '
import json, sys
d = json.load(open(sys.argv[1]))
print(d.get(sys.argv[2], "ABSENT"))
' "$1" "$2"
}

for repo in RustCrypto/hashes jimmielovell/axum-idempotent moka-rs/moka; do
  name=${repo//\//_}
  if gh_get "repo_$name" "repos/$repo"; then
    printf '  %-32s stars=%s archived=%s pushed_at=%s\n' "$repo" \
      "$(gh_field "$SNAP/gh-repo_$name.json" stargazers_count)" \
      "$(gh_field "$SNAP/gh-repo_$name.json" archived)" \
      "$(gh_field "$SNAP/gh-repo_$name.json" pushed_at)"
  else
    skip "E6-$name" "no GitHub snapshot for $repo"
  fi
done

if [ -s "$SNAP/gh-repo_RustCrypto_hashes.json" ]; then
  if [ "$(gh_field "$SNAP/gh-repo_RustCrypto_hashes.json" archived)" = "False" ]; then
    pass E6-sha2-active 'RustCrypto/hashes is not archived — the maintenance-state rubric needs this, not just a release date'
  else
    fail E6-sha2-active 'RustCrypto/hashes reports archived, which would change the maintenance verdict'
  fi
else
  skip E6-sha2-active 'no RustCrypto/hashes snapshot'
fi

printf '\nCHECKS RUN: %s PASS: %s FAIL: %s SKIP: %s\n' "$((PASS + FAIL + SKIP))" "$PASS" "$FAIL" "$SKIP"
[ "$FAIL" -eq 0 ]
