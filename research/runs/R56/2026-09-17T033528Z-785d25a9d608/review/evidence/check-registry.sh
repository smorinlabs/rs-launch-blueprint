#!/usr/bin/env bash
# R56 evidence — assert the crate figures, licences, MSRV floors, dependency edges and
# advisory status the decision cites. It reads the SNAPSHOTS in snapshots/, not the live
# endpoints, because `crate.recent_downloads` and `pushed_at` move continuously and a
# check that re-fetches cannot be rerun and diffed. refresh-snapshots.sh is the fetcher;
# snapshots/MANIFEST.txt records each file's endpoint and retrieval timestamp.
# Every figure printed here therefore carries its endpoint and its retrieval date.
set -euo pipefail
set -o pipefail

here="$(cd "$(dirname "$0")" && pwd)"
snap="$here/snapshots"
fail=0
ok()   { printf 'PASS %s — %s\n' "$1" "$2"; }
bad()  { printf 'FAIL %s — %s\n' "$1" "$2"; fail=$((fail + 1)); }
want() { if [ "$2" = "$3" ]; then ok "$1" "$3"; else bad "$1" "expected [$2], got [$3]"; fi; }

if [ ! -f "$snap/MANIFEST.txt" ]; then
  printf 'SKIP check-registry — snapshots/MANIFEST.txt is absent\n'
  exit 0
fi

printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'snapshot manifest (file, endpoint, retrieved-utc):\n'
sed 's|^.*/snapshots/|  |' "$snap/MANIFEST.txt"

newest_field() { # crate, field -> value of the newest unyanked version
  python3 -c '
import json,sys
vs=[v for v in json.load(open(sys.argv[1]))["versions"] if not v["yanked"]]
print(vs[0].get(sys.argv[2]) if vs[0].get(sys.argv[2]) is not None else "")' \
    "$snap/versions-$1.json" "$2"
}
crate_field() {
  python3 -c '
import json,sys
print(json.load(open(sys.argv[1]))["crate"][sys.argv[2]])' "$snap/crate-$1.json" "$2"
}

# --- the four recommended members, each at the version the decision names ---------
member_row() { # crate version msrv created license...
  local crate="$1" version="$2" msrv="$3" created="$4"; shift 4
  local lic="$*"
  want "R-${crate}-version" "$version" "$(newest_field "$crate" num)"
  want "R-${crate}-msrv"    "$msrv"    "$(newest_field "$crate" rust_version)"
  want "R-${crate}-license" "$lic"     "$(newest_field "$crate" license)"
  want "R-${crate}-created" "$created" "$(newest_field "$crate" created_at | cut -c1-10)"
  printf 'R-%s-downloads — crate.recent_downloads=%s crate.downloads=%s (GET https://crates.io/api/v1/crates/%s, retrieved per snapshots/MANIFEST.txt)\n' \
    "$crate" "$(crate_field "$crate" recent_downloads)" "$(crate_field "$crate" downloads)" "$crate"
}
member_row secrecy                           0.10.3 1.60 2024-10-09 'Apache-2.0 OR MIT'
member_row zeroize                           1.9.0  1.85 2026-06-12 'Apache-2.0 OR MIT'
member_row keyring-core                      1.0.0  1.85 2026-04-21 'MIT OR Apache-2.0'
member_row apple-native-keyring-store        1.0.2  1.85 2026-08-06 'MIT OR Apache-2.0'
member_row zbus-secret-service-keyring-store 1.0.1  1.88 2026-08-15 'MIT OR Apache-2.0'

# --- the declared dependency edge the compatibility claim rests on ----------------
zeroize_req="$(python3 -c '
import json
d=[x for x in json.load(open("'"$snap"'/deps-secrecy-0.10.3.json"))["dependencies"] if x["crate_id"]=="zeroize"][0]
print(d["req"], d["default_features"], ",".join(d["features"]), d["optional"])')"
want 'R-secrecy-depends-zeroize' '^1.6 False alloc False' "$zeroize_req"
serde_opt="$(python3 -c '
import json
d=[x for x in json.load(open("'"$snap"'/deps-secrecy-0.10.3.json"))["dependencies"] if x["crate_id"]=="serde"][0]
print(d["optional"])')"
want 'R-secrecy-serde-optional' 'True' "$serde_opt"

# --- secrecy 0.10.3 source: the unsafe posture, read rather than asserted ---------
#     A silent guard here would make the decision cite three assertions the rerun does not
#     emit, so an absent snapshot SKIPs BY NAME instead.
if [ -f "$snap/secrecy-0.10.3-lib.rs" ] && [ -f "$snap/secrecy-0.10.3-Cargo.toml" ]; then
  forbid="$(/usr/bin/grep -c '^#!\[forbid(unsafe_code)\]' "$snap/secrecy-0.10.3-lib.rs" || true)"
  want 'R-secrecy-forbid-unsafe' '1' "$forbid"
  features="$(/usr/bin/grep -c '^\[features\]' "$snap/secrecy-0.10.3-Cargo.toml" || true)"
  want 'R-secrecy-no-features-table' '0' "$features"
  want 'R-secrecy-edition' 'edition = "2021"' "$(/usr/bin/grep '^edition = ' "$snap/secrecy-0.10.3-Cargo.toml")"
  want 'R-secrecy-declared-msrv-in-source' 'rust-version = "1.60"' \
    "$(/usr/bin/grep '^rust-version = ' "$snap/secrecy-0.10.3-Cargo.toml")"
else
  printf 'SKIP R-secrecy-forbid-unsafe, R-secrecy-no-features-table, R-secrecy-edition, R-secrecy-declared-msrv-in-source — the extracted secrecy 0.10.3 source snapshots are absent\n'
fi

# --- advisories. A rustsec package page exists only where an advisory does, so a 404
#     is the absence of one. `nix` is the positive control proving a 200 is reachable.
for c in secrecy zeroize keyring-core apple-native-keyring-store zbus-secret-service-keyring-store; do
  want "R-rustsec-${c}" '404' "$(cat "$snap/rustsec-${c}.status")"
done
want 'R-rustsec-nix-positive-control' '200' "$(cat "$snap/rustsec-nix.status")"
nix_adv="$(/usr/bin/grep -c 'RUSTSEC-2021-0119' "$snap/rustsec-nix.html" || true)"
if [ "$nix_adv" -ge 1 ]; then
  ok 'R-rustsec-control-content' "the nix page lists RUSTSEC-2021-0119, so a 200 really carries advisory text ($nix_adv occurrences, binary /usr/bin/grep)"
else
  bad 'R-rustsec-control-content' 'the nix control page carries no advisory id'
fi

# --- repository state --------------------------------------------------------------
for f in gh-iqlusioninc-crates gh-RustCrypto-utils gh-keyring-core; do
  archived="$(python3 -c 'import json,sys;print(json.load(open(sys.argv[1]))["archived"])' "$snap/$f.json")"
  want "R-${f}-archived" 'False' "$archived"
  printf 'R-%s-detail — %s\n' "$f" "$(tr -d '\n' < "$snap/$f.json")"
done
printf 'R-open-issues — iqlusioninc/crates=%s RustCrypto/utils=%s (GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open, total_count, never open_issues_count)\n' \
  "$(python3 -c 'import json;print(json.load(open("'"$snap"'/gh-issues-iqlusioninc-crates.json"))["total_count"])')" \
  "$(python3 -c 'import json;print(json.load(open("'"$snap"'/gh-issues-RustCrypto-utils.json"))["total_count"])')"

# --- the engine-disagreement facts that had to be settled against the registry -----
# Gemini reported secrecy's newest release as 0.8.0 and its all-time downloads as
# 24,105,992. Both are contradicted by the snapshot; the assertion records by how much.
gem_version="$(newest_field secrecy num)"
if [ "$gem_version" != "0.8.0" ]; then
  ok 'R-gemini-secrecy-version-wrong' "the newest unyanked secrecy is ${gem_version}, not the 0.8.0 the Doxa/Gemini report states"
else
  bad 'R-gemini-secrecy-version-wrong' 'the snapshot agrees with 0.8.0; the disagreement must be restated'
fi
gem_dl="$(crate_field secrecy downloads)"
if [ "$gem_dl" -gt 24105992 ]; then
  ok 'R-gemini-secrecy-downloads-wrong' "crate.downloads is ${gem_dl}, not the 24,105,992 the Doxa/Gemini report states"
else
  bad 'R-gemini-secrecy-downloads-wrong' "crate.downloads is ${gem_dl}"
fi

printf 'CHECK_FAILURES=%s\n' "$fail"
[ "$fail" -eq 0 ]
