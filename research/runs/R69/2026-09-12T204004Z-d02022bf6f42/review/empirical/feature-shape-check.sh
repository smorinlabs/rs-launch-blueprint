#!/usr/bin/env bash
# R69 evidence: the `web-extra-surface` feature shape, measured on a manifest.
#
# What this checks, and nothing more: that the feature name gates the two
# recommended crates and the serve binary target; what the feature's own
# dependency cost is; that the resolved tree's highest declared `rust-version`
# sits inside the msrv-policy floor; that no RustSec advisory applies to it; and
# that `tower` arrives transitively through axum (which settles whether it must
# be a gated runtime dependency or only a dev-dependency for the test idiom).
#
# It does NOT build a web surface: src/lib.rs and the gated binary are empty.
set -o pipefail
set -u
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FS="$HERE/feature-shape"
rc=0
cd "$FS" || exit 1

say() { printf '\n== %s ==\n' "$1"; }
must()      { printf '%s' "$2" | grep -qF -- "$1" && echo "OK: found '$1'" || { echo "FAIL: expected '$1'"; rc=1; }; }
must_not()  { printf '%s' "$2" | grep -qF -- "$1" && { echo "FAIL: '$1' should be absent"; rc=1; } || echo "OK: '$1' absent"; }

echo "toolchain: $(rustc --version) / $(cargo --version)"
echo "host: $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null)"
echo "manifest floor: rust-version = $(grep -m1 '^rust-version' Cargo.toml)"

say "1. feature OFF: cargo tree -e normal"
off="$(cargo tree -e normal --locked --no-default-features 2>&1)"; st=$?
echo "$off"; echo "exit=$st"; [ "$st" -eq 0 ] || rc=1
for c in axum tokio hyper tower; do must_not " $c v" "$off"; done
off_n=$(printf '%s\n' "$off" | grep -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "distinct packages in the NON-DEV base tree: $off_n  (base deps are deliberately empty, so this is the root alone)"

say "2. feature ON: cargo tree -e normal --features web"
on="$(cargo tree -e normal --locked --features web 2>&1)"; st=$?
echo "$on" | head -40; echo "  ... (full tree truncated for readability; counts below)"; echo "exit=$st"; [ "$st" -eq 0 ] || rc=1
for c in axum tokio hyper tower; do must " $c v" "$on"; done
must "axum v0.8.9"  "$on"
must "tokio v1.53.1" "$on"
on_n=$(printf '%s\n' "$on" | grep -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "distinct packages in the NON-DEV tree with the feature on: $on_n"
echo "the feature's own non-dev dependency cost: $((on_n - off_n)) packages"

say "3. the feature's own dependency cost (unique packages, cargo metadata)"
on_pkgs=$(cargo metadata --locked --features web --format-version 1 2>/dev/null | jq '[.packages[].id] | length'); st=$?
off_pkgs=$(cargo metadata --locked --no-default-features --format-version 1 2>/dev/null | jq '[.packages[].id] | length')
echo "cargo metadata packages, feature off: $off_pkgs"
echo "cargo metadata packages, feature on : $on_pkgs"
echo "NOTE: cargo metadata resolves dev-dependencies too, so these are not the"
echo "      cargo-tree -e normal numbers; the comparable figure is the delta."

say "4. non-dev resolved tree: highest declared rust-version (gate 2, resolved tree)"
cargo metadata --locked --features web --format-version 1 2>/dev/null \
 | jq -r '
    (.resolve.nodes | map({key: .id, value: .deps}) | from_entries) as $g
    | (.resolve.root) as $root
    | ([$root] | reduce range(0;12) as $_ (.;
        . + ([.[] | $g[.] // [] | .[] | select(.dep_kinds | any(.kind == null)) | .pkg] // []) | unique)) as $reach
    | [ .packages[] | select(.id as $i | $reach | index($i)) | {name, version, rv: .rust_version, lic: .license} ]
    | sort_by(.rv // "0.0") | .[]
    | "\(.name) \(.version)  rust-version=\(.rv // "none")  license=\(.lic // "none")"' \
 | tee /tmp/r69-rv.txt | tail -25
grep -v '^r69_feature_shape ' /tmp/r69-rv.txt > /tmp/r69-rv-deps.txt
maxrv=$(awk '{for(i=1;i<=NF;i++) if ($i ~ /^rust-version=/) {split($i,a,"="); if (a[2] != "none") print a[2]}}' /tmp/r69-rv-deps.txt | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
echo "(the probe package's own rust-version, 1.96, IS the floor and is excluded)"
echo "highest declared rust-version among the DEPENDENCIES: ${maxrv:-<none>}"
must "axum 0.8.9  rust-version=1.80" "$(cat /tmp/r69-rv-deps.txt)"
nodecl=$(grep -c 'rust-version=none' /tmp/r69-rv-deps.txt || true)
echo "dependencies declaring no rust-version at all: $nodecl"
[ -n "$maxrv" ] || { echo "FAIL: could not compute the resolved-tree MSRV"; rc=1; }
awk -v m="$maxrv" 'BEGIN{split(m,x,"."); if (x[1]==1 && x[2]+0 <= 96) print "OK: " m " is inside the 1.96 floor"; else {print "FAIL: " m " exceeds the 1.96 floor"; exit 1}}' || rc=1
echo "control: a floor this tree does NOT satisfy must be reported as a failure"
awk 'BEGIN{split("1.70",x,"."); if (x[1]==1 && x[2]+0 <= 96) print "control-BROKEN"; else print "control-ok"}' >/dev/null
awk -v m="$maxrv" 'BEGIN{split(m,x,"."); if (x[1]==1 && x[2]+0 <= 70) print "CONTROL-FAIL: 1.80 wrongly passed a 1.70 floor"; else print "OK: the same test rejects a 1.70 floor, so it can fail"}' 

say "5. does tower arrive transitively through axum? (settles dev-dep vs gated runtime dep)"
tw="$(cargo tree -e normal --locked --features web --invert tower 2>&1)"; echo "$tw" | head -12
must "axum v0.8.9" "$tw"
echo "-> tower is already in the non-dev tree via axum; a DIRECT tower entry is"
echo "   needed only to bring tower::ServiceExt into scope in tests, so it belongs"
echo "   under [dev-dependencies], not inside the web feature."

say "6. the serve binary target is gated by required-features (cargo metadata)"
tg="$(cargo metadata --locked --no-deps --format-version 1 2>/dev/null | jq -c '.packages[0].targets[] | {name, kind, rf: .["required-features"]}')"
echo "$tg"
must '"name":"probe-serve"' "$(printf '%s' "$tg" | tr -d ' ')"
must '"rf":["web"]' "$(printf '%s' "$tg" | tr -d ' ')"
must '"name":"r69_feature_shape","kind":["lib"],"rf":null' "$(printf '%s' "$tg" | tr -d ' ')"

say "7. behavioral confirmation: with no features, no serve binary is produced"
cargo clean --quiet
cargo build --quiet --locked --no-default-features --bins 2>&1 | tail -3
st=${PIPESTATUS[0]}; echo "build exit=$st"; [ "$st" -eq 0 ] || rc=1
if [ -e target/debug/probe-serve ]; then echo "FAIL: probe-serve exists with the feature off"; rc=1; else echo "OK: target/debug/probe-serve: No such file or directory"; fi

say "8. advisories against the resolved lockfile (cargo audit)"
cargo audit --version
cargo audit 2>&1 | tail -12
st=${PIPESTATUS[0]}; echo "cargo-audit exit=$st"; [ "$st" -eq 0 ] || { echo "FAIL: cargo audit reported findings"; rc=1; }

say "9. second probe, base = R01's published crate members (serde + serde_json)"
echo "Why: the opus raw reports base=13 / --features web=52 non-dev packages."
echo "An empty base cannot reproduce that, so this probe carries R01's members."
cd "$HERE/feature-shape-r01base" || exit 1
r_off=$(cargo tree -e normal --locked --no-default-features 2>/dev/null | grep -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
r_on=$(cargo tree -e normal --locked --features web 2>/dev/null  | grep -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "feature OFF = $r_off non-dev packages; feature ON = $r_on; delta = $((r_on - r_off))"
[ "$r_on" = "52" ] && echo "OK: the feature-on tree is 52 packages, matching the opus report exactly" \
                   || { echo "FAIL: expected 52 with the feature on, got $r_on"; rc=1; }
[ "$r_off" = "12" ] && echo "NOTE: base is 12 here vs the opus report's 13; that probe carried one further" \
                    && echo "      base dependency this one does not. The delta is 40 here, 39 there." \
                    || echo "NOTE: base is $r_off here; the opus report's base was 13."
cd "$FS" || exit 1

printf '\nfeature-shape-check rc=%s\n' "$rc"
exit $rc
