#!/usr/bin/env bash
# R56 evidence — fetch the volatile registry/repository/advisory responses once and
# snapshot them under snapshots/, so check-registry.sh reads bytes that do not drift.
# Re-run this ONLY to deliberately refresh the figures; the recorded decision cites
# the snapshots, each of which carries its endpoint and retrieval date in
# snapshots/MANIFEST.txt. Never prints a token or the environment.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots"
mkdir -p "$snap"
ua='rs-launch-blueprint-research/1.0 (P02 R56 synthesizer)'
manifest="$snap/MANIFEST.txt"
: > "$manifest"

note() { printf '%s\t%s\t%s\n' "$1" "$2" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$manifest"; }

# Only the crates whose figures the decision actually cites. `nix` is fetched below as
# the RustSec positive control, and needs no crates.io record.
crates='secrecy zeroize keyring-core apple-native-keyring-store zbus-secret-service-keyring-store'
for c in $crates; do
  curl -sS -A "$ua" "https://crates.io/api/v1/crates/${c}" -o "$snap/crate-${c}.json"
  note "$snap/crate-${c}.json" "GET https://crates.io/api/v1/crates/${c}"
  curl -sS -A "$ua" "https://crates.io/api/v1/crates/${c}/versions" -o "$snap/versions-${c}.json"
  note "$snap/versions-${c}.json" "GET https://crates.io/api/v1/crates/${c}/versions"
done

curl -sS -A "$ua" "https://crates.io/api/v1/crates/secrecy/0.10.3/dependencies" -o "$snap/deps-secrecy-0.10.3.json"
note "$snap/deps-secrecy-0.10.3.json" 'GET https://crates.io/api/v1/crates/secrecy/0.10.3/dependencies'

# RustSec package pages: a page exists only where an advisory does. `nix` is the
# positive control that proves a 200 is reachable and a 404 is a real absence.
for c in secrecy zeroize keyring-core apple-native-keyring-store zbus-secret-service-keyring-store nix; do
  code=$(curl -sS -A "$ua" -o "$snap/rustsec-${c}.html" -w '%{http_code}' "https://rustsec.org/packages/${c}.html" || true)
  printf '%s\n' "$code" > "$snap/rustsec-${c}.status"
  note "$snap/rustsec-${c}.status" "GET https://rustsec.org/packages/${c}.html"
done

# GitHub REST through the authenticated gh binary. --jq keeps the response small;
# no Authorization header, token or environment is ever printed.
gh api repos/iqlusioninc/crates \
  --jq '{stargazers_count,archived,pushed_at}' > "$snap/gh-iqlusioninc-crates.json"
note "$snap/gh-iqlusioninc-crates.json" 'GET https://api.github.com/repos/iqlusioninc/crates'
gh api repos/RustCrypto/utils \
  --jq '{stargazers_count,archived,pushed_at}' > "$snap/gh-RustCrypto-utils.json"
note "$snap/gh-RustCrypto-utils.json" 'GET https://api.github.com/repos/RustCrypto/utils'
gh api repos/open-source-cooperative/keyring-core \
  --jq '{stargazers_count,archived,pushed_at}' > "$snap/gh-keyring-core.json"
note "$snap/gh-keyring-core.json" 'GET https://api.github.com/repos/open-source-cooperative/keyring-core'
gh api "search/issues?q=repo:iqlusioninc/crates+is:issue+is:open" \
  --jq '{total_count}' > "$snap/gh-issues-iqlusioninc-crates.json"
note "$snap/gh-issues-iqlusioninc-crates.json" 'GET https://api.github.com/search/issues?q=repo:iqlusioninc/crates+is:issue+is:open'
gh api "search/issues?q=repo:RustCrypto/utils+is:issue+is:open" \
  --jq '{total_count}' > "$snap/gh-issues-RustCrypto-utils.json"
note "$snap/gh-issues-RustCrypto-utils.json" 'GET https://api.github.com/search/issues?q=repo:RustCrypto/utils+is:issue+is:open'

# secrecy's own published source at the pinned version, for the unsafe-posture question.
# The .crate tarball itself is NOT snapshotted: .gitignore excludes research/runs/**/*.crate
# deliberately, so an ignored file could never be read back by a rerun. The two text files
# the check actually reads are extracted and snapshotted instead.
crate_work="$(mktemp -d "${TMPDIR:-/tmp}/r56crate-XXXXXX")"
curl -sS -A "$ua" -L "https://static.crates.io/crates/secrecy/secrecy-0.10.3.crate" \
  -o "$crate_work/secrecy-0.10.3.crate"
tar xzf "$crate_work/secrecy-0.10.3.crate" -C "$crate_work"
cp "$crate_work/secrecy-0.10.3/src/lib.rs"     "$snap/secrecy-0.10.3-lib.rs"
cp "$crate_work/secrecy-0.10.3/Cargo.toml"     "$snap/secrecy-0.10.3-Cargo.toml"
note "$snap/secrecy-0.10.3-lib.rs" 'src/lib.rs from GET https://static.crates.io/crates/secrecy/secrecy-0.10.3.crate'
note "$snap/secrecy-0.10.3-Cargo.toml" 'Cargo.toml from GET https://static.crates.io/crates/secrecy/secrecy-0.10.3.crate'
rm -rf "$crate_work"

printf 'refreshed %s snapshot files\n' "$(/usr/bin/grep -c . "$manifest")"
