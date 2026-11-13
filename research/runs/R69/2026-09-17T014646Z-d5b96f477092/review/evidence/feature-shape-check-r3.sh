#!/usr/bin/env bash
# R69 evidence, revision 3: the `web-extra-surface` feature shape, measured on a
# manifest, with the advisory scan given a PINNED input.
#
# Why this script exists beside `../empirical/feature-shape-check.sh`. The round-2
# empirical audit rejected revision 2 with this finding, quoted verbatim:
#
#   "check 2 is not reproducible as claimed. feature-shape-check.sh invokes bare
#    `cargo audit`, which fetches and updates the advisory database. Its recorded
#    log says 1,243 advisories; the successful private-db rerun observed 1,246.
#    The original exact rerun failed only on the sandbox's read-only database
#    lock, but it likewise did not reproduce. The decision says checks 1, 2, 5,
#    and 6 reproduce byte-for-byte and that all six immediate reruns had no
#    differences. The check needs a fixed advisory-db input (or the decision must
#    stop claiming byte-identical check-2 reproduction)."
#
# The finding is correct: section 8 of the revision-1 script consumed a MUTABLE
# input. `../empirical/feature-shape-check.sh` and its cited log
# `feature-shape-check.log` are left byte-identical as the record of revision 1;
# this file replaces it as the live check and is what revision 3 of the decision
# cites.
#
# The repair, and what it does and does not make reproducible:
#
#  * Sections 1-7 and 9 are the DETERMINISTIC feature-shape assertions. Their
#    inputs are the two committed probe manifests and their committed
#    `Cargo.lock` files, read with `--locked`. Every absolute path they would
#    print is normalised to a placeholder (see `norm`), so they reproduce
#    byte-for-byte from any extraction directory, including a clean
#    `git archive HEAD` extraction, on the toolchain named in the first lines of
#    the output.
#  * Section 8 is the advisory scan. It no longer runs bare `cargo audit`.
#    It clones the RustSec advisory database into a scratch directory under
#    ${TMPDIR:-/tmp} AT THE PINNED COMMIT recorded below, ASSERTS the checked-out
#    commit hash, and runs `cargo audit --db <that clone> --no-fetch --stale`, so
#    the advisory corpus is a fixed input and the loaded-advisory count is an
#    assertable constant rather than a moving number.
#  * The clone is made with `mktemp -d` under ${TMPDIR:-/tmp} and removed by the
#    EXIT trap. It is NEVER written inside this run directory: a nested git
#    repository committed into a run directory has already had to be stripped
#    from the index once in this programme, and must not happen again.
#  * `--no-fetch` means this scan does NOT refresh the crates.io index, so the
#    line `Updating crates.io index` that the revision-1 log printed is absent
#    here by design. That line belonged to cargo-audit's yanked-crate lookup, not
#    to the advisory corpus; no advisory result depends on it.
#  * If the pinned database can be obtained from neither the network nor a local
#    mirror, section 8 prints the single named marker
#    `SKIP: advisory-scan-skipped-pinned-db-unavailable` and contributes nothing
#    to the exit status. The SKIP is scoped to section 8 alone: the feature-shape
#    status (`rc_shape`) is computed independently and always reaches the exit
#    code, so a skipped advisory scan can never mask a failed feature-shape
#    assertion. A commit-hash MISMATCH is a FAIL, never a SKIP.
#
# It does NOT build a web surface: src/lib.rs and the gated binary are empty.
set -o pipefail
set -u

# The POSIX grep at its absolute path. Named explicitly and used by absolute path
# everywhere below because an interactive agent shell on this machine resolves a
# typed `grep` to ugrep, which honours .gitignore and would silently change what
# a search sees. Inside this script only /usr/bin/grep is ever invoked.
GREP=/usr/bin/grep
SED=/usr/bin/sed
AWK=/usr/bin/awk
[ -x "$GREP" ] || { echo "FAIL: $GREP is not executable"; exit 1; }
[ -x "$SED" ]  || { echo "FAIL: $SED is not executable";  exit 1; }
[ -x "$AWK" ]  || { echo "FAIL: $AWK is not executable";  exit 1; }
JQ="$(command -v jq || true)"
[ -n "$JQ" ] || { echo "FAIL: jq not found on PATH"; exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FS="$(cd "$HERE/../empirical/feature-shape" && pwd)"
R01BASE="$(cd "$HERE/../empirical/feature-shape-r01base" && pwd)"

# The pinned advisory-database input. Changing either constant is a deliberate
# re-pin and moves the recorded log.
ADVISORY_DB_COMMIT="b50980aad8b8f14f77e25a97b32dd94bf008b0af"
ADVISORY_DB_EXPECTED_ADVISORIES="1243"
ADVISORY_DB_URL="${R69_ADVISORY_DB_URL:-https://github.com/RustSec/advisory-db.git}"
ADVISORY_DB_MIRROR="${R69_ADVISORY_DB_MIRROR:-$HOME/.cargo/advisory-db}"

# Sentinel: never a real path, so `norm` is safe before the clone exists.
DB_DIR="/nonexistent/r69-pinned-advisory-db"
SCRATCH=""
cleanup() { [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] && rm -rf "$SCRATCH"; return 0; }
trap cleanup EXIT

rc_shape=0
rc_audit=0
audit_skipped=0

# Path normalisation. R01BASE is replaced FIRST because FS is a prefix of it.
norm() { "$SED" -e "s|$R01BASE|<feature-shape-r01base>|g" \
                -e "s|$FS|<feature-shape>|g" \
                -e "s|$DB_DIR|<pinned-advisory-db>|g"; }

say() { printf '\n== %s ==\n' "$1"; }
must()     { printf '%s' "$2" | "$GREP" -qF -- "$1" && echo "OK: found '$1'" || { echo "FAIL: expected '$1'"; rc_shape=1; }; }
must_not() { printf '%s' "$2" | "$GREP" -qF -- "$1" && { echo "FAIL: '$1' should be absent"; rc_shape=1; } || echo "OK: '$1' absent"; }

cd "$FS" || exit 1

echo "toolchain: $(rustc --version) / $(cargo --version)"
echo "host: $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null)"
echo "grep binary: /usr/bin/grep (the POSIX grep, invoked by absolute path; never a shell alias, never ugrep)"
echo "manifest floor: rust-version = $("$GREP" -m1 '^rust-version' Cargo.toml)"
echo "probe dir: <feature-shape> (absolute paths are normalised in this log)"

say "1. feature OFF: cargo tree -e normal"
off="$(cargo tree -e normal --locked --no-default-features 2>&1 | norm)"; st=$?
echo "$off"; echo "exit=$st"; [ "$st" -eq 0 ] || rc_shape=1
for c in axum tokio hyper tower; do must_not " $c v" "$off"; done
off_n=$(printf '%s\n' "$off" | "$GREP" -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "distinct packages in the NON-DEV base tree: $off_n  (base deps are deliberately empty, so this is the root alone)"

say "2. feature ON: cargo tree -e normal --features web"
on="$(cargo tree -e normal --locked --features web 2>&1 | norm)"; st=$?
echo "$on" | head -40; echo "  ... (full tree truncated for readability; counts below)"; echo "exit=$st"; [ "$st" -eq 0 ] || rc_shape=1
for c in axum tokio hyper tower; do must " $c v" "$on"; done
must "axum v0.8.9"  "$on"
must "tokio v1.53.1" "$on"
on_n=$(printf '%s\n' "$on" | "$GREP" -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "distinct packages in the NON-DEV tree with the feature on: $on_n"
echo "the feature's own non-dev dependency cost: $((on_n - off_n)) packages"

say "3. the feature's own dependency cost (unique packages, cargo metadata)"
on_pkgs=$(cargo metadata --locked --features web --format-version 1 2>/dev/null | "$JQ" '[.packages[].id] | length')
off_pkgs=$(cargo metadata --locked --no-default-features --format-version 1 2>/dev/null | "$JQ" '[.packages[].id] | length')
echo "cargo metadata packages, feature off: $off_pkgs"
echo "cargo metadata packages, feature on : $on_pkgs"
echo "NOTE: cargo metadata resolves dev-dependencies too, so these are not the"
echo "      cargo-tree -e normal numbers; the comparable figure is the delta."

say "4. non-dev resolved tree: highest declared rust-version (gate 2, resolved tree)"
RVALL="$(mktemp "${TMPDIR:-/tmp}/r69-rv.XXXXXX")"
RVDEPS="$(mktemp "${TMPDIR:-/tmp}/r69-rv-deps.XXXXXX")"
cargo metadata --locked --features web --format-version 1 2>/dev/null \
 | "$JQ" -r '
    (.resolve.nodes | map({key: .id, value: .deps}) | from_entries) as $g
    | (.resolve.root) as $root
    | ([$root] | reduce range(0;12) as $_ (.;
        . + ([.[] | $g[.] // [] | .[] | select(.dep_kinds | any(.kind == null)) | .pkg] // []) | unique)) as $reach
    | [ .packages[] | select(.id as $i | $reach | index($i)) | {name, version, rv: .rust_version, lic: .license} ]
    | sort_by(.rv // "0.0") | .[]
    | "\(.name) \(.version)  rust-version=\(.rv // "none")  license=\(.lic // "none")"' \
 | tee "$RVALL" | tail -25
"$GREP" -v '^r69_feature_shape ' "$RVALL" > "$RVDEPS"
maxrv=$("$AWK" '{for(i=1;i<=NF;i++) if ($i ~ /^rust-version=/) {split($i,a,"="); if (a[2] != "none") print a[2]}}' "$RVDEPS" | sort -t. -k1,1n -k2,2n -k3,3n | tail -1)
echo "(the probe package's own rust-version, 1.96, IS the floor and is excluded)"
echo "highest declared rust-version among the DEPENDENCIES: ${maxrv:-<none>}"
must "axum 0.8.9  rust-version=1.80" "$(cat "$RVDEPS")"
nodecl=$("$GREP" -c 'rust-version=none' "$RVDEPS" || true)
echo "dependencies declaring no rust-version at all: $nodecl"
[ -n "$maxrv" ] || { echo "FAIL: could not compute the resolved-tree MSRV"; rc_shape=1; }
"$AWK" -v m="$maxrv" 'BEGIN{split(m,x,"."); if (x[1]==1 && x[2]+0 <= 96) print "OK: " m " is inside the 1.96 floor"; else {print "FAIL: " m " exceeds the 1.96 floor"; exit 1}}' || rc_shape=1
echo "control: a floor this tree does NOT satisfy must be reported as a failure"
"$AWK" -v m="$maxrv" 'BEGIN{split(m,x,"."); if (x[1]==1 && x[2]+0 <= 70) print "CONTROL-FAIL: 1.80 wrongly passed a 1.70 floor"; else print "OK: the same test rejects a 1.70 floor, so it can fail"}'
rm -f "$RVALL" "$RVDEPS"

say "5. does tower arrive transitively through axum? (settles dev-dep vs gated runtime dep)"
tw="$(cargo tree -e normal --locked --features web --invert tower 2>&1 | norm)"; echo "$tw" | head -12
must "axum v0.8.9" "$tw"
echo "-> tower is already in the non-dev tree via axum; a DIRECT tower entry is"
echo "   needed only to bring tower::ServiceExt into scope in tests, so it belongs"
echo "   under [dev-dependencies], not inside the web feature."

say "6. the serve binary target is gated by required-features (cargo metadata)"
tg="$(cargo metadata --locked --no-deps --format-version 1 2>/dev/null | "$JQ" -c '.packages[0].targets[] | {name, kind, rf: .["required-features"]}')"
echo "$tg"
must '"name":"probe-serve"' "$(printf '%s' "$tg" | tr -d ' ')"
must '"rf":["web"]' "$(printf '%s' "$tg" | tr -d ' ')"
must '"name":"r69_feature_shape","kind":["lib"],"rf":null' "$(printf '%s' "$tg" | tr -d ' ')"

say "7. behavioral confirmation: with no features, no serve binary is produced"
cargo clean --quiet
cargo build --quiet --locked --no-default-features --bins 2>&1 | norm | tail -3
st=${PIPESTATUS[0]}; echo "build exit=$st"; [ "$st" -eq 0 ] || rc_shape=1
if [ -e target/debug/probe-serve ]; then echo "FAIL: probe-serve exists with the feature off"; rc_shape=1; else echo "OK: target/debug/probe-serve: No such file or directory"; fi

say "8. advisories against the resolved lockfile (cargo audit, PINNED advisory database)"
echo "pinned advisory-db repo   : $ADVISORY_DB_URL"
echo "pinned advisory-db commit : $ADVISORY_DB_COMMIT"
echo "expected advisories loaded: $ADVISORY_DB_EXPECTED_ADVISORIES"
cargo audit --version
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/r69-advisory-db.XXXXXX")"
DB_DIR="$SCRATCH/advisory-db"
db_source=""
# 1) the network, by exact commit. GitHub serves a reachable SHA to a depth-1 fetch.
if git init -q "$DB_DIR" >/dev/null 2>&1 \
   && git -C "$DB_DIR" remote add origin "$ADVISORY_DB_URL" >/dev/null 2>&1 \
   && git -C "$DB_DIR" fetch -q --depth 1 origin "$ADVISORY_DB_COMMIT" >/dev/null 2>&1 \
   && git -C "$DB_DIR" checkout -q FETCH_HEAD >/dev/null 2>&1; then
  db_source="network"
else
  # 2) a local mirror that already contains the pinned commit (no network needed).
  rm -rf "$DB_DIR"
  if [ "${R69_NO_LOCAL_MIRROR:-0}" != "1" ] && [ -d "$ADVISORY_DB_MIRROR/.git" ] \
     && git -C "$ADVISORY_DB_MIRROR" cat-file -e "$ADVISORY_DB_COMMIT^{commit}" >/dev/null 2>&1 \
     && git clone -q --shared --no-checkout "$ADVISORY_DB_MIRROR" "$DB_DIR" >/dev/null 2>&1 \
     && git -C "$DB_DIR" checkout -q "$ADVISORY_DB_COMMIT" >/dev/null 2>&1; then
    db_source="local-mirror"
  fi
fi
if [ -z "$db_source" ]; then
  audit_skipped=1
  echo "SKIP: advisory-scan-skipped-pinned-db-unavailable"
  echo "      The pinned commit could not be obtained from the network or from a"
  echo "      local mirror. Section 8 contributes nothing to the exit status; the"
  echo "      feature-shape status below is unaffected and still decides it."
else
  echo "advisory-db obtained from : $db_source (clone lives under \${TMPDIR}, never inside the run directory)"
  got="$(git -C "$DB_DIR" rev-parse HEAD)"
  echo "advisory-db HEAD          : $got"
  if [ "$got" = "$ADVISORY_DB_COMMIT" ]; then
    echo "OK: the checked-out advisory-db commit is the pinned one"
  else
    echo "FAIL: advisory-db HEAD $got is not the pinned $ADVISORY_DB_COMMIT"
    rc_audit=1
  fi
  aud="$(cargo audit --db "$DB_DIR" --no-fetch --stale 2>&1 | norm)"; st=$?
  echo "$aud"
  echo "cargo-audit exit=$st"
  [ "$st" -eq 0 ] || { echo "FAIL: cargo audit reported findings"; rc_audit=1; }
  if printf '%s' "$aud" | "$GREP" -qF "Loaded $ADVISORY_DB_EXPECTED_ADVISORIES security advisories (from <pinned-advisory-db>)"; then
    echo "OK: the pinned database loaded exactly $ADVISORY_DB_EXPECTED_ADVISORIES advisories"
  else
    echo "FAIL: the pinned database did not load $ADVISORY_DB_EXPECTED_ADVISORIES advisories"
    rc_audit=1
  fi
  if printf '%s' "$aud" | "$GREP" -qF "Scanning Cargo.lock for vulnerabilities (55 crate dependencies)"; then
    echo "OK: the scan covered the 55-crate resolved lockfile"
  else
    echo "FAIL: the scan did not report 55 crate dependencies"
    rc_audit=1
  fi
  echo "control: the advisory-count assertion must be able to fail"
  if printf '%s' "$aud" | "$GREP" -qF "Loaded 99999 security advisories"; then
    echo "CONTROL-FAIL: a count this database cannot have was reported as present"
    rc_audit=1
  else
    echo "OK: the same assertion rejects a count of 99999, so it can fail"
  fi
fi

say "9. second probe, base = R01's published crate members (serde + serde_json)"
echo "Why: the opus raw reports base=13 / --features web=52 non-dev packages."
echo "An empty base cannot reproduce that, so this probe carries R01's members."
cd "$R01BASE" || exit 1
r_off=$(cargo tree -e normal --locked --no-default-features 2>/dev/null | "$GREP" -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
r_on=$(cargo tree -e normal --locked --features web 2>/dev/null  | "$GREP" -oE '[a-zA-Z0-9_-]+ v[0-9][^ ]*' | sort -u | wc -l | tr -d ' ')
echo "feature OFF = $r_off non-dev packages; feature ON = $r_on; delta = $((r_on - r_off))"
[ "$r_on" = "52" ] && echo "OK: the feature-on tree is 52 packages, matching the opus report exactly" \
                   || { echo "FAIL: expected 52 with the feature on, got $r_on"; rc_shape=1; }
[ "$r_off" = "12" ] && echo "NOTE: base is 12 here vs the opus report's 13; that probe carried one further" \
                    && echo "      base dependency this one does not. The delta is 40 here, 39 there." \
                    || echo "NOTE: base is $r_off here; the opus report's base was 13."
cd "$FS" || exit 1

rc=0
[ "$rc_shape" -eq 0 ] || rc=1
if [ "$audit_skipped" -eq 1 ]; then
  audit_state="skipped (pinned database unavailable; contributes nothing to rc)"
else
  audit_state="rc_audit=$rc_audit"
  [ "$rc_audit" -eq 0 ] || rc=1
fi
printf '\nfeature-shape (sections 1-7, 9, deterministic): rc_shape=%s\n' "$rc_shape"
printf 'advisory scan (section 8, pinned input): %s\n' "$audit_state"
printf 'feature-shape-check-r3 rc=%s\n' "$rc"
exit $rc
