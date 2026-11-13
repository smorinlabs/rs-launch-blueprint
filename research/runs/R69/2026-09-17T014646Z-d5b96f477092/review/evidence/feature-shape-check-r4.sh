#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C` is not if-then-else) - every `&& echo OK || { echo FAIL; rc=1; }`
#          below is deliberate: B is an `echo` that cannot fail, so C runs only when A is false.
#   SC2016 (expressions do not expand in single quotes) - the jq and awk programs are quoted
#          exactly so that `$g`, `$root`, `$i` and `$i ~ /.../` reach jq and awk unexpanded.
#   SC2329 (function never invoked) - `cleanup` is invoked indirectly, by `trap cleanup EXIT`.
#   This directive is the ONLY difference between this file and the shellcheck output of
#   `feature-shape-check-r3.sh`, which raises the same three informational findings; the
#   repository gained a shellcheck pre-commit hook after revision 3 was committed.
#
# R69 evidence, revision 4: the `web-extra-surface` feature shape, measured on a
# manifest, with the advisory scan given a PINNED input and an ISOLATED
# `CARGO_HOME`.
#
# Why this script exists beside `feature-shape-check-r3.sh`. The round-3
# empirical audit rejected revision 3 with this finding, quoted verbatim:
#
#   "Reject - the repaired check is still not byte-reproducible under the
#    decision's stated conditions. Each successful rerun inserted `warning:
#    couldn't open crates.io index: I/O operation failed: failed to obtain lock
#    file '/Users/stevemorin/.cargo/.package-cache'` after `Loaded 1243 security
#    advisories`; `diff -u review/evidence/feature-shape-check-r3.log
#    review/evidence/audit-feature-shape-check-r3-inplace-1.log` shows this sole
#    difference. The decision names a *missing* cached index as the warning
#    condition, but the observed cause is an unavailable package-cache lock on a
#    machine that has the cache. Cargo-audit 0.22.1's `src/auditor.rs:115-167`
#    takes the same `CachedIndex::open` branch for `--no-fetch` and warns on any
#    open failure, including a lock failure. Its stated conditions for cited-log
#    identity must include a readable, unlocked cached crates.io index (or the
#    claim must be narrowed to the deterministic feature-shape sections);
#    otherwise its claim that the two named variations are exhaustive is false."
#
# The finding is correct. `feature-shape-check-r3.sh` and its cited log
# `feature-shape-check-r3.log` are left BYTE-IDENTICAL as the record of revision
# 3, exactly as revision 1's `../empirical/feature-shape-check.sh` and
# `feature-shape-check.log` were left as the record of revision 1. This file
# replaces r3 as the live check and is what revision 4 of the decision cites.
#
# THE REPAIR, and why this form. The round-3 finding offered two remedies: make
# the warning impossible, or narrow the byte-identity claim to the deterministic
# sections and classify the scan section's environment-dependent lines. This
# script takes the FIRST form for the warning itself, because the warning can be
# made structurally impossible rather than merely classified:
#
#  * Section 8 now runs `cargo audit` under an ISOLATED `CARGO_HOME`: a
#    `mktemp -d` directory under ${TMPDIR:-/tmp} containing exactly two things,
#    an `audit.toml` holding
#
#        [yanked]
#        enabled = false
#
#    and a `bin/cargo-audit` symlink to the cargo-audit binary already on PATH.
#    Per cargo-audit 0.22.1's `src/commands.rs` (`CONFIG_FILE = "audit.toml"`,
#    `config_path()`: project `./.cargo/audit.toml` first, then
#    `home::cargo_home().join("audit.toml")`, and `home::cargo_home()` honours
#    `$CARGO_HOME`), that file IS the configuration this invocation loads; the
#    probe directory has no `./.cargo`, so nothing outranks it.
#  * With `yanked.enabled = false`, `src/auditor.rs:115-167` takes its
#    `} else { None }` arm: neither `CachedIndex::fetch` nor `CachedIndex::open`
#    is ever called. The crates.io index is not read, no `.package-cache` lock is
#    taken, and the `couldn't open crates.io index: ...` warning that the round-3
#    audit observed CANNOT be emitted. The ambient `~/.cargo` is not consulted at
#    all, so neither a readable nor an unlocked cached index is required.
#  * WHAT THAT COSTS, stated plainly rather than hidden: this scan no longer
#    reports yanked crates. A crate's yanked status is a MUTABLE attribute of the
#    live crates.io registry, not part of the pinned advisory corpus; it is
#    exactly the kind of moving input that got revisions 2 and 3 rejected. The
#    decision asserts no yanked result and gate 3 is answered on advisories
#    alone. Yanked-crate detection belongs to P03's live CI against a current
#    index, and is recorded there, not here.
#  * The empty-`CARGO_HOME` variant that the round-3 repair brief suggested was
#    tested and REJECTED on evidence: with an isolated but unpopulated
#    `CARGO_HOME` and `yanked.enabled` left at its default `true`,
#    `CachedIndex::open` SUCCEEDS against a newly created empty index and
#    cargo-audit then prints 55 lines of
#    `error: couldn't check if the package is yanked: not found: No such crate in
#    crates.io index: <name>`. Asserting the warning's absence would have passed
#    while the log grew 55 lines. Disabling the lookup is the form that makes the
#    claim true by construction.
#  * Section 8 asserts the repair rather than assuming it: the normalised
#    cargo-audit output must contain neither `couldn't open crates.io index` nor
#    `couldn't check if the package is yanked`, AND must be exactly two lines.
#    The line-count assertion is the one that catches a line nobody has seen yet;
#    a string blocklist cannot. A control shows the same absence test detects a
#    line that IS present, so it can fail.
#
# THE SECOND ENVIRONMENT-DEPENDENT LINE, found while repairing the first, and
# handled by the R63 classifier discipline because it CANNOT be made impossible.
# Sections 1, 2, 5 and 7 run cargo under the REAL `CARGO_HOME` (they need the
# populated registry cache to resolve `--locked`) and capture its stderr. When
# another process holds `~/.cargo/.package-cache` - ten agents share this
# worktree - cargo prints
#
#     Blocking waiting for file lock on package cache
#
# (and, for the build-directory lock, `... on build directory`) and then
# proceeds normally. This was reproduced deliberately, by holding an exclusive
# `flock` on `~/.cargo/.package-cache` from a separate process and running
# section 1's `cargo tree` command; the line appeared and the tree was otherwise
# identical. `norm` therefore deletes it with ONE named, anchored pattern,
#
#     /^[[:space:]]*Blocking waiting for file lock on /d
#
# which is the only classified line class in this log. It carries no information
# about the feature shape, it is deleted before section 7's `tail -3` window is
# taken so it cannot shift that window, and when no lock is contended it does not
# appear and nothing is deleted. Every line the classifier can remove is named
# here and in the decision.
#
# WHAT IS OTHERWISE UNCHANGED FROM r3, and is deliberately byte-identical in
# behaviour: the pinned advisory-database commit b50980aad8b8f14f77e25a97b32dd94bf008b0af
# and its 1,243-advisory / 55-crate assertions; the advisory-count control; the
# `--db <clone> --no-fetch --stale` form; the scratch clone under ${TMPDIR:-/tmp}
# removed by the EXIT trap and NEVER written inside this run directory (a nested
# git repository has already had to be stripped from this programme's index once
# and must not happen again); the named, narrowly scoped
# `SKIP: advisory-scan-skipped-pinned-db-unavailable` that contributes nothing to
# the exit status; the separate `rc_shape` that always reaches the exit code so a
# skipped scan cannot mask a failed feature-shape assertion; a pinned-hash
# MISMATCH being a FAIL and never a SKIP; and sections 1-7 and 9 themselves.
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

# Sentinels: never real paths, so `norm` is safe before the clone and the
# isolated CARGO_HOME exist.
DB_DIR="/nonexistent/r69-pinned-advisory-db"
ISO_CARGO_HOME="/nonexistent/r69-isolated-cargo-home"
SCRATCH=""
ISO_SCRATCH=""
cleanup() {
  [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] && rm -rf "$SCRATCH"
  [ -n "$ISO_SCRATCH" ] && [ -d "$ISO_SCRATCH" ] && rm -rf "$ISO_SCRATCH"
  return 0
}
trap cleanup EXIT

rc_shape=0
rc_audit=0
audit_skipped=0

# Path normalisation, plus the single named classified line class.
# R01BASE is replaced FIRST because FS is a prefix of it.
# The final expression is the R63-style classifier described in the header: it
# deletes cargo's file-lock contention notice, the one environment-dependent line
# class this log can carry, and nothing else.
norm() { "$SED" -e "s|$R01BASE|<feature-shape-r01base>|g" \
                -e "s|$FS|<feature-shape>|g" \
                -e "s|$DB_DIR|<pinned-advisory-db>|g" \
                -e "s|$ISO_CARGO_HOME|<isolated-cargo-home>|g" \
                -e '/^[[:space:]]*Blocking waiting for file lock on /d'; }

say() { printf '\n== %s ==\n' "$1"; }
must()     { printf '%s' "$2" | "$GREP" -qF -- "$1" && echo "OK: found '$1'" || { echo "FAIL: expected '$1'"; rc_shape=1; }; }
must_not() { printf '%s' "$2" | "$GREP" -qF -- "$1" && { echo "FAIL: '$1' should be absent"; rc_shape=1; } || echo "OK: '$1' absent"; }

cd "$FS" || exit 1

echo "toolchain: $(rustc --version) / $(cargo --version)"
echo "host: $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null)"
echo "grep binary: /usr/bin/grep (the POSIX grep, invoked by absolute path; never a shell alias, never ugrep)"
echo "manifest floor: rust-version = $("$GREP" -m1 '^rust-version' Cargo.toml)"
echo "probe dir: <feature-shape> (absolute paths are normalised in this log)"
echo "classified line class: '    Blocking waiting for file lock on ...' (cargo's package-cache/build-directory contention notice) is deleted by norm; it is the only one"

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
cargo clean --quiet 2>&1 | norm
cargo build --quiet --locked --no-default-features --bins 2>&1 | norm | tail -3
st=${PIPESTATUS[0]}; echo "build exit=$st"; [ "$st" -eq 0 ] || rc_shape=1
if [ -e target/debug/probe-serve ]; then echo "FAIL: probe-serve exists with the feature off"; rc_shape=1; else echo "OK: target/debug/probe-serve: No such file or directory"; fi

say "8. advisories against the resolved lockfile (cargo audit, PINNED advisory database, ISOLATED CARGO_HOME)"
echo "pinned advisory-db repo   : $ADVISORY_DB_URL"
echo "pinned advisory-db commit : $ADVISORY_DB_COMMIT"
echo "expected advisories loaded: $ADVISORY_DB_EXPECTED_ADVISORIES"

# The isolated CARGO_HOME. It holds exactly an audit.toml disabling the yanked
# lookup and a symlink to the cargo-audit binary, so `cargo audit` resolves and
# runs without ever reading the ambient ~/.cargo index or taking its lock.
CA_BIN="$(command -v cargo-audit || true)"
[ -n "$CA_BIN" ] || CA_BIN="$HOME/.cargo/bin/cargo-audit"
if [ ! -x "$CA_BIN" ]; then
  echo "FAIL: cargo-audit binary not found (looked on PATH and at \$HOME/.cargo/bin/cargo-audit)"
  rc_audit=1
fi
ISO_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/r69-cargo-home.XXXXXX")"
ISO_CARGO_HOME="$ISO_SCRATCH"
mkdir -p "$ISO_CARGO_HOME/bin"
printf '[yanked]\nenabled = false\n' > "$ISO_CARGO_HOME/audit.toml"
[ -x "$CA_BIN" ] && ln -sf "$CA_BIN" "$ISO_CARGO_HOME/bin/cargo-audit"
echo "isolated CARGO_HOME       : <isolated-cargo-home> (mktemp -d under \${TMPDIR}; contains only audit.toml and bin/cargo-audit)"
echo "isolated audit.toml       : $(tr '\n' ' ' < "$ISO_CARGO_HOME/audit.toml")"
echo "  -> with [yanked] enabled = false, cargo-audit 0.22.1 src/auditor.rs:115-167 takes its"
echo "     'else { None }' arm: CachedIndex::open and CachedIndex::fetch are never called, so no"
echo "     crates.io index is read, no ~/.cargo/.package-cache lock is taken, and the round-3"
echo "     audit's \"couldn't open crates.io index\" warning cannot be emitted."
echo "  -> cost, stated: this scan does not report yanked crates. Yanked status is a mutable"
echo "     crates.io attribute, not part of the pinned corpus; no claim in the decision rests on"
echo "     it, and P03's live CI covers it."
CARGO_HOME="$ISO_CARGO_HOME" cargo audit --version 2>&1 | norm

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
  aud="$(CARGO_HOME="$ISO_CARGO_HOME" cargo audit --db "$DB_DIR" --no-fetch --stale 2>&1 | norm)"; st=$?
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
  # The round-3 repair, asserted rather than assumed.
  for absent in "couldn't open crates.io index" "couldn't check if the package is yanked"; do
    if printf '%s' "$aud" | "$GREP" -qF -- "$absent"; then
      echo "FAIL: '$absent' appeared; the isolated CARGO_HOME did not suppress the index read"
      rc_audit=1
    else
      echo "OK: '$absent' is absent from the scan output"
    fi
  done
  echo "control: the warning-absence test must be able to fail"
  if printf '%s' "$aud" | "$GREP" -qF -- "Scanning Cargo.lock for vulnerabilities"; then
    echo "OK: the same absence test reports a line that IS present, so it can fail"
  else
    echo "CONTROL-FAIL: the absence test did not see a line known to be present"
    rc_audit=1
  fi
  # A blocklist cannot catch a line nobody has seen. The line count can.
  aud_lines=$(printf '%s\n' "$aud" | wc -l | tr -d ' ')
  echo "normalised cargo-audit output lines: $aud_lines"
  if [ "$aud_lines" = "2" ]; then
    echo "OK: the scan emitted exactly the 2 expected lines and nothing else"
  else
    echo "FAIL: expected exactly 2 lines of cargo-audit output, got $aud_lines"
    rc_audit=1
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
printf 'advisory scan (section 8, pinned input, isolated CARGO_HOME): %s\n' "$audit_state"
printf 'feature-shape-check-r4 rc=%s\n' "$rc"
exit $rc
