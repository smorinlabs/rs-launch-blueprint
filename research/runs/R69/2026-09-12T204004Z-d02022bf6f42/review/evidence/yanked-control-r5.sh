#!/usr/bin/env bash
# shellcheck disable=SC2015,SC2016,SC2329
#   SC2015 (`A && B || C` is not if-then-else) - the two `&& echo OK || { echo FAIL; rc=1; }`
#          chains below are deliberate: B is an `echo` that cannot fail, so C runs only when A
#          is false.
#   SC2016 (expressions do not expand in single quotes) - the two awk programs below are quoted
#          exactly so that `$3`, the `/^source = "registry\+/` pattern and awk's own `name`
#          variable reach awk unexpanded.
#   SC2329 (function never invoked) - `cleanup` is invoked indirectly, by `trap cleanup EXIT`.
#   These are the same three informational codes `feature-shape-check-r4.sh` disables, and they
#   are the only codes shellcheck raises against this file. The repository runs shellcheck over
#   every staged *.sh file from a pre-commit hook. The directive is a comment: it does not
#   change a byte of this script's output, which is why the run made before it was added diffs
#   empty against the cited log.
#
# R69 evidence, revision 5: the EMPTY-`CARGO_HOME`, YANKED-LOOKUP-ENABLED CONTROL,
# with its error-line count asserted rather than recalled.
#
# WHY THIS SCRIPT EXISTS. Revision 4 of `review/DECISION.md` explains why section 8 of
# `feature-shape-check-r4.sh` disables cargo-audit's yanked lookup, and it reports, as an
# observed result, what the rejected alternative does instead: an isolated but UNPOPULATED
# `CARGO_HOME` with `[yanked] enabled` left at its default `true`. Revision 4 stated that
# variant printed 55 `couldn't check if the package is yanked` error lines. The round-4
# empirical audit recreated the variant and observed 54
# (`review/evidence/audit-codex-r4-empty-cargo-home-yanked.log:59`) and rejected revision 4 on
# that single finding.
#
# 55 is the LOCKFILE PACKAGE COUNT - the figure in cargo-audit's own
# `Scanning Cargo.lock for vulnerabilities (55 crate dependencies)` line, which revision 4 also
# asserts, correctly, in check 2. The yanked lookup does not run over all 55: it is a crates.io
# registry query, so it runs only over the packages whose lockfile entry carries a
# `source = "registry+https://github.com/rust-lang/crates.io-index"` key. The root package
# `r69_feature_shape` is a path package with no `source`, so 54 packages are looked up and 54
# error lines are printed. Revision 4 wrote the count it had to hand instead of the count the
# run produced. This script makes the figure TRUE BY CONSTRUCTION: it runs the variant and
# ASSERTS the number, so the count in revision 5's prose cannot drift from the run again.
#
# This script does NOT replace `feature-shape-check-r4.sh` and changes nothing about it. The
# r4 script and `feature-shape-check-r4.log` are left BYTE-IDENTICAL as revision 4's repair,
# which the round-4 audit reproduced five ways (three in-place runs, a temporary-index
# `git archive` extraction, a `HEAD` `git archive` extraction, and a run made while a separate
# process held `flock(LOCK_EX)` on `~/.cargo/.package-cache`). The r4 header comment's own
# "55 lines" sentence therefore also stays byte-identical and carries the superseded figure;
# revision 5's note records that, and this script is the live record of the count.
#
# WHAT IT RUNS. The variant the round-4 audit ran, with the same pinned inputs check 2 uses:
#
#   * the same probe package, `review/empirical/feature-shape/`, read `--locked`;
#   * the same pinned advisory database, `RustSec/advisory-db` at commit
#     b50980aad8b8f14f77e25a97b32dd94bf008b0af, cloned into a scratch directory under
#     ${TMPDIR:-/tmp} - NEVER inside this run directory, because a nested git repository has
#     had to be stripped from this programme's index once already - and asserted to be at that
#     commit, a mismatch being a FAIL and never a SKIP;
#   * an isolated `CARGO_HOME` from `mktemp -d` containing ONLY `bin/cargo-audit`, a symlink to
#     the cargo-audit binary already on PATH. There is deliberately NO `audit.toml`, so
#     `[yanked] enabled` keeps its default `true` - that is the whole point of this control;
#   * `CARGO_HOME=<isolated> cargo audit --db <clone> --no-fetch --stale`.
#
# WHAT IT ASSERTS. Content, never an exit code alone:
#
#   1. the pinned advisory database loaded 1,243 advisories, and the scan reported
#      55 crate dependencies - the same two constants check 2 asserts;
#   2. the count of `couldn't check if the package is yanked` lines, counted with
#      `/usr/bin/grep -cF`, is exactly 54, with a control showing the same test rejects 55 so
#      it can fail;
#   3. the lockfile holds 55 `[[package]]` entries and 54 `source = "registry+` keys, which is
#      WHY the two figures differ;
#   4. the sorted crate names in the 54 error lines are exactly the sorted names of the
#      lockfile's 54 registry-sourced packages (`diff` must be empty), and the one lockfile
#      package missing from the error lines is the root path package `r69_feature_shape`.
#
# The absolute path of the scratch clone and of the isolated home are normalised to
# `<pinned-advisory-db>` and `<isolated-cargo-home>`, as in `feature-shape-check-r4.sh`, so
# this log is byte-reproducible across runs whose `mktemp` names differ.
#
# It does NOT build a web surface: src/lib.rs and the gated binary in the probe are empty.
set -o pipefail
set -u

# The POSIX grep at its absolute path. Named explicitly and used by absolute path everywhere
# below because an interactive agent shell on this machine resolves a typed `grep` to ugrep,
# which honours .gitignore and would silently change what a search sees. Inside this script
# only /usr/bin/grep is ever invoked.
GREP=/usr/bin/grep
SED=/usr/bin/sed
AWK=/usr/bin/awk
[ -x "$GREP" ] || { echo "FAIL: $GREP is not executable"; exit 1; }
[ -x "$SED" ]  || { echo "FAIL: $SED is not executable";  exit 1; }
[ -x "$AWK" ]  || { echo "FAIL: $AWK is not executable";  exit 1; }

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
FS="$(cd "$HERE/../empirical/feature-shape" && pwd)"

ADVISORY_DB_COMMIT="b50980aad8b8f14f77e25a97b32dd94bf008b0af"
ADVISORY_DB_EXPECTED_ADVISORIES="1243"
ADVISORY_DB_URL="${R69_ADVISORY_DB_URL:-https://github.com/RustSec/advisory-db.git}"
ADVISORY_DB_MIRROR="${R69_ADVISORY_DB_MIRROR:-$HOME/.cargo/advisory-db}"

# The observed figures this control asserts.
EXPECTED_YANKED_LINES="54"
EXPECTED_LOCK_PACKAGES="55"

# Sentinels: never real paths, so `norm` is safe before the clone and the isolated home exist.
DB_DIR="/nonexistent/r69-pinned-advisory-db"
ISO_CARGO_HOME="/nonexistent/r69-isolated-cargo-home"
SCRATCH=""
ISO_SCRATCH=""
WORK=""
cleanup() {
  [ -n "$SCRATCH" ] && [ -d "$SCRATCH" ] && rm -rf "$SCRATCH"
  [ -n "$ISO_SCRATCH" ] && [ -d "$ISO_SCRATCH" ] && rm -rf "$ISO_SCRATCH"
  [ -n "$WORK" ] && [ -d "$WORK" ] && rm -rf "$WORK"
  return 0
}
trap cleanup EXIT

rc=0

# Path normalisation plus the one classified line class carried over from
# `feature-shape-check-r4.sh`: cargo's package-cache/build-directory contention notice. Nothing
# in this script runs cargo under the real CARGO_HOME, so it is not expected to appear; the
# pattern is kept because `cargo audit --version` and the scan are still cargo invocations.
norm() { "$SED" -e "s|$DB_DIR|<pinned-advisory-db>|g" \
                -e "s|$ISO_CARGO_HOME|<isolated-cargo-home>|g" \
                -e '/^[[:space:]]*Blocking waiting for file lock on /d'; }

say() { printf '\n== %s ==\n' "$1"; }

cd "$FS" || exit 1

echo "toolchain: $(rustc --version) / $(cargo --version)"
echo "host: $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null)"
echo "grep binary: /usr/bin/grep (the POSIX grep, invoked by absolute path; never a shell alias, never ugrep)"
echo "probe dir: <feature-shape> (absolute paths are normalised in this log)"
echo "classified line class: '    Blocking waiting for file lock on ...' is deleted by norm; it is the only one"

say "1. the lockfile arithmetic that explains 55 vs 54"
lock_pkgs=$("$GREP" -c '^\[\[package\]\]' Cargo.lock)
lock_reg=$("$GREP" -c '^source = "registry+' Cargo.lock)
echo "Cargo.lock [[package]] entries            : $lock_pkgs"
echo "Cargo.lock entries with a registry source : $lock_reg"
[ "$lock_pkgs" = "$EXPECTED_LOCK_PACKAGES" ] \
  && echo "OK: the lockfile holds $EXPECTED_LOCK_PACKAGES packages, the figure cargo-audit's 'Scanning' line reports" \
  || { echo "FAIL: expected $EXPECTED_LOCK_PACKAGES lockfile packages, got $lock_pkgs"; rc=1; }
[ "$lock_reg" = "$EXPECTED_YANKED_LINES" ] \
  && echo "OK: $EXPECTED_YANKED_LINES of them carry a crates.io registry source, so only those can be looked up" \
  || { echo "FAIL: expected $EXPECTED_YANKED_LINES registry-sourced packages, got $lock_reg"; rc=1; }

say "2. the isolated, UNPOPULATED CARGO_HOME with the yanked lookup at its default"
CA_BIN="$(command -v cargo-audit || true)"
[ -n "$CA_BIN" ] || CA_BIN="$HOME/.cargo/bin/cargo-audit"
[ -x "$CA_BIN" ] || { echo "FAIL: cargo-audit binary not found (looked on PATH and at \$HOME/.cargo/bin/cargo-audit)"; rc=1; }
ISO_SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/r69-cargo-home-yanked.XXXXXX")"
ISO_CARGO_HOME="$ISO_SCRATCH"
mkdir -p "$ISO_CARGO_HOME/bin"
[ -x "$CA_BIN" ] && ln -sf "$CA_BIN" "$ISO_CARGO_HOME/bin/cargo-audit"
echo "isolated CARGO_HOME       : <isolated-cargo-home> (mktemp -d under \${TMPDIR})"
echo "isolated CARGO_HOME holds : $(cd "$ISO_CARGO_HOME" && find . -mindepth 1 -maxdepth 2 -print | "$SED" 's|^\./||' | sort | tr '\n' ' ')"
if [ -e "$ISO_CARGO_HOME/audit.toml" ]; then
  echo "FAIL: an audit.toml exists; this control REQUIRES the default [yanked] enabled = true"
  rc=1
else
  echo "OK: no audit.toml, so cargo-audit 0.22.1 keeps its default [yanked] enabled = true"
fi
CARGO_HOME="$ISO_CARGO_HOME" cargo audit --version 2>&1 | norm

say "3. the pinned advisory database"
echo "pinned advisory-db repo   : $ADVISORY_DB_URL"
echo "pinned advisory-db commit : $ADVISORY_DB_COMMIT"
SCRATCH="$(mktemp -d "${TMPDIR:-/tmp}/r69-advisory-db-yanked.XXXXXX")"
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
  echo "SKIP: yanked-control-skipped-pinned-db-unavailable"
  echo "      The pinned commit could not be obtained from the network or from a local"
  echo "      mirror, so the control did not run and asserts nothing."
  printf '\nyanked-control-r5 rc=%s (SKIPPED)\n' "$rc"
  exit "$rc"
fi
echo "advisory-db obtained from : $db_source (clone lives under \${TMPDIR}, never inside the run directory)"
got="$(git -C "$DB_DIR" rev-parse HEAD)"
echo "advisory-db HEAD          : $got"
if [ "$got" = "$ADVISORY_DB_COMMIT" ]; then
  echo "OK: the checked-out advisory-db commit is the pinned one"
else
  echo "FAIL: advisory-db HEAD $got is not the pinned $ADVISORY_DB_COMMIT"
  rc=1
fi

say "4. the rejected variant, run"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/r69-yanked-out.XXXXXX")"
OUT="$WORK/scan.txt"
CARGO_HOME="$ISO_CARGO_HOME" cargo audit --db "$DB_DIR" --no-fetch --stale > "$OUT" 2>&1
st=$?
"$SED" -e "s|$DB_DIR|<pinned-advisory-db>|g" -e "s|$ISO_CARGO_HOME|<isolated-cargo-home>|g" \
       -e '/^[[:space:]]*Blocking waiting for file lock on /d' "$OUT" > "$WORK/scan.norm"
head -4 "$WORK/scan.norm"
echo "  ... (the per-crate error lines are counted, not printed in full; the full set is"
echo "      reproduced by the crate-name comparison in section 5)"
tail -1 "$WORK/scan.norm"
echo "cargo-audit exit=$st"
[ "$st" -eq 0 ] || { echo "NOTE: a non-zero exit here would mean findings, which the pinned corpus does not report"; }

if "$GREP" -qF "Loaded $ADVISORY_DB_EXPECTED_ADVISORIES security advisories (from <pinned-advisory-db>)" "$WORK/scan.norm"; then
  echo "OK: the pinned database loaded exactly $ADVISORY_DB_EXPECTED_ADVISORIES advisories"
else
  echo "FAIL: the pinned database did not load $ADVISORY_DB_EXPECTED_ADVISORIES advisories"
  rc=1
fi
if "$GREP" -qF "Scanning Cargo.lock for vulnerabilities ($EXPECTED_LOCK_PACKAGES crate dependencies)" "$WORK/scan.norm"; then
  echo "OK: the scan reported $EXPECTED_LOCK_PACKAGES crate dependencies"
else
  echo "FAIL: the scan did not report $EXPECTED_LOCK_PACKAGES crate dependencies"
  rc=1
fi

say "5. THE COUNT revision 4 got wrong, asserted"
yanked_lines=$("$GREP" -cF "couldn't check if the package is yanked" "$WORK/scan.norm")
echo "yanked-error-lines (/usr/bin/grep -cF): $yanked_lines"
if [ "$yanked_lines" = "$EXPECTED_YANKED_LINES" ]; then
  echo "OK: the variant printed exactly $EXPECTED_YANKED_LINES 'couldn't check if the package is yanked' lines"
else
  echo "FAIL: expected $EXPECTED_YANKED_LINES such lines, got $yanked_lines"
  rc=1
fi
echo "control: the count assertion must be able to fail"
if [ "$yanked_lines" = "$EXPECTED_LOCK_PACKAGES" ]; then
  echo "CONTROL-FAIL: the count $EXPECTED_LOCK_PACKAGES (revision 4's figure) was wrongly accepted"
  rc=1
else
  echo "OK: the same test rejects $EXPECTED_LOCK_PACKAGES, the figure revision 4 stated, so it can fail"
fi

echo "why the two figures differ, checked against the lockfile rather than asserted in prose:"
"$GREP" -F "couldn't check if the package is yanked" "$WORK/scan.norm" \
  | "$SED" -e 's/.*No such crate in crates.io index: //' | sort > "$WORK/from-errors.txt"
"$AWK" '/^name = /{name=$3} /^source = "registry\+/{gsub(/"/,"",name); print name}' Cargo.lock | sort > "$WORK/from-lock.txt"
echo "names extracted from the error lines : $(wc -l < "$WORK/from-errors.txt" | tr -d ' ')"
echo "registry-sourced names in Cargo.lock : $(wc -l < "$WORK/from-lock.txt" | tr -d ' ')"
if diff -u "$WORK/from-lock.txt" "$WORK/from-errors.txt" > "$WORK/names.diff" 2>&1; then
  echo "OK: the looked-up crates are exactly the lockfile's registry-sourced packages (diff empty)"
else
  echo "FAIL: the looked-up crates differ from the lockfile's registry-sourced packages:"
  cat "$WORK/names.diff"
  rc=1
fi
"$AWK" '/^name = /{gsub(/"/,"",$3); print $3}' Cargo.lock | sort > "$WORK/all-lock.txt"
missing="$(comm -23 "$WORK/all-lock.txt" "$WORK/from-errors.txt" | tr '\n' ' ' | "$SED" 's/ $//')"
echo "lockfile packages NOT looked up      : $missing"
if [ "$missing" = "r69_feature_shape" ]; then
  echo "OK: the single package the yanked lookup skips is the root PATH package, which has no"
  echo "    crates.io source; $EXPECTED_LOCK_PACKAGES - 1 = $EXPECTED_YANKED_LINES is the whole of the difference"
else
  echo "FAIL: expected the root path package r69_feature_shape to be the only one skipped, got '$missing'"
  rc=1
fi

printf '\nyanked-control-r5 rc=%s\n' "$rc"
exit $rc
