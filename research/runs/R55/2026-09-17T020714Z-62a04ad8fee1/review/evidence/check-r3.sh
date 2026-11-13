#!/usr/bin/env bash
# R55 config-error-tolerance — revision 3 evidence checks.
#
# Supersedes evidence/check-r2.sh, which stays byte-identical as the record of
# what revision 2 ran. Revision 2's four `assert_stream` checks sat at the tail
# of a pipeline, so `ok`/`no` mutated `pass`/`fail` in a subshell: the counters
# were lost and a FAIL among those four could not trip the closing gate. Round-2
# finding JF-7. This script feeds `assert_stream` from a here-string instead, so
# both counters and the gate survive, and check JF7 below proves that at run time
# rather than asserting it. It also adds the pins round-2 finding JF-9 asked for
# (JF9a, JF9b) and the two R53 locations round-2 finding JF-8 names (JF8a, JF8b).
#
# Revision 1's evidence/check.sh and its logs are NOT edited; neither are
# revision 2's. This script re-runs every revision-2 check with working counters
# and adds five, so the count it prints is the count the decision cites.
#
# Every check asserts on content, never on an exit code alone. The script finds
# the repository root by content rather than by .git, so it reruns from a clean
# `git archive HEAD` extraction; a check whose external input is unavailable
# prints SKIP with its own name rather than passing vacuously.
#
# The counting binary is named beside every count it produces.

# SC2016: the literal needles below are Markdown or Rust quoted in single quotes
# on purpose — backticks and $ inside them are the text being matched, not shell.
# shellcheck disable=SC2016

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

ROOT="$HERE"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT="$(dirname "$ROOT")"
done
if [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; then
  echo "FATAL: could not locate the repository root above $HERE"
  exit 1
fi

R53="$ROOT/research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md"
R53_SHA256=be59d65bfa7ee087766a315af09c0ba4c93a8fa211927091314c86222cbb9af9
STANDARD=/Users/stevemorin/c/cli-standards/cli-design-standard.md
PY_REPO=/Users/stevemorin/c/py-launch-blueprint
TS_REPO=/Users/stevemorin/c/ts-launch-blueprint
PY_PIN=b08bccfb
TS_PIN=cb1cbcb2

pass=0
fail=0
skip=0

ok() {
  echo "PASS $1: $2"
  pass=$((pass + 1))
}
no() {
  echo "FAIL $1: $2"
  fail=$((fail + 1))
}
sk() {
  echo "SKIP $1: $2"
  skip=$((skip + 1))
}

# assert_contains <check-id> <file> <literal needle> <description>
# Reflows the file onto one line first, so a needle the source wraps across
# lines is still matched literally.
assert_contains() {
  local id="$1" file="$2" needle="$3" desc="$4" n
  if [ ! -f "$file" ]; then
    no "$id" "$desc — file absent: $file"
    return
  fi
  n=$(tr '\n' ' ' <"$file" | tr -s ' ' | "$GREP" -c -F -- "$needle" || true)
  if [ "$n" -ge 1 ]; then
    ok "$id" "$desc — $GREP counted $n occurrence(s) of the literal needle"
  else
    no "$id" "$desc — $GREP counted 0 occurrences of: $needle"
  fi
}

# assert_stream <check-id> <description> <needle> — reads the text to search on
# stdin. MUST be fed by a here-string, never by a pipeline: as a pipeline's last
# element it would run in a subshell and its ok/no would not reach the counters.
assert_stream() {
  local id="$1" desc="$2" needle="$3" n
  n=$(tr '\n' ' ' | tr -s ' ' | "$GREP" -c -F -- "$needle" || true)
  if [ "$n" -ge 1 ]; then
    ok "$id" "$desc — $GREP counted $n occurrence(s) of the literal needle"
  else
    no "$id" "$desc — $GREP counted 0 occurrences of: $needle"
  fi
}

echo "=== R55 revision-3 evidence — environment ==="
echo "date (UTC):      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "repository root: $ROOT"
echo "counting binary: $GREP ($("$GREP" --version 2>&1 | head -1))"
echo "uname:           $(uname -sm)"
if command -v cargo >/dev/null 2>&1; then echo "cargo:           $(cargo --version)"; fi
if command -v rustc >/dev/null 2>&1; then echo "rustc:           $(rustc --version)"; fi
echo

echo "=== D01-D04 — the R53 decision this revision reconciles against ==="
if [ ! -f "$R53" ]; then
  no D01 "R53 decision absent at $R53"
else
  got=$(shasum -a 256 "$R53" | awk '{print $1}')
  if [ "$got" = "$R53_SHA256" ]; then
    ok D01 "R53 decision pinned at sha256 $got"
  else
    no D01 "R53 decision is sha256 $got, not the pinned $R53_SHA256 — reconcile again"
  fi
  # The per-key loop's published signature: it returns the partial value AND the
  # issue list, which is what lets R55 sanitize per layer on top of it.
  assert_contains D02 "$R53" \
    'pub fn validate(self) -> (ConfigFile, Vec<Issue>) { /* per-key loop over toml::Table */ }' \
    "R53 publishes the per-key loop returning a partial value beside the issue list"
  # The Issue type that carries the dotted path R55 prunes on.
  assert_contains D03a "$R53" \
    'pub struct Issue { pub path: String, pub message: String, pub span: Option<Range<usize>> }' \
    "R53 publishes Issue with the dotted path R55 sanitizes on"
  # The coupling sentence that names R55 and hands it both questions.
  assert_contains D03b "$R53" \
    'R53'"'"'s per-key loop supplies leaf-level dotted paths and free unknown-key detection' \
    "R53 names the coupling and hands the two questions to R55"
  assert_contains D03c "$R53" \
    'Under the per-key loop, unknown-key *detection* is free (any key in the table the loop did not consume), so the policy is a one-line branch rather than an attribute decision.' \
    "R53 states unknown-key detection is free and leaves the policy to R55"
  assert_contains D03d "$R53" \
    '*Whether unknown keys are tolerated* — also R55'"'"'s.' \
    "R53 hands unknown-key policy to R55 in terms"
  # R53 selects no dedicated validation crate, so R55 inherits no new dependency.
  assert_contains D04 "$R53" \
    '**No dependency is added by this item.**' \
    "R53 adds no crate, so the reconciled R55 stack adds none either"
fi
echo

echo "=== JF-7 — the harness itself: a here-string reaches the counters, a pipeline does not ==="
# Round-2 finding JF-7. Revision 2 fed assert_stream from a pipeline, whose last
# element bash runs in a subshell, so ok/no incremented a copy of pass/fail and a
# FAIL among those four checks left fail=0 and could not trip the closing gate.
# This check proves the repaired form at run time, in this shell, rather than
# asserting it in prose: it must show the pipeline form losing an increment and
# the here-string form keeping one, for BOTH counters.
jf7_probe=$(bash -c '
  set -euo pipefail
  p=0; f=0
  inc_ok() { p=$((p + 1)); }
  inc_no() { f=$((f + 1)); }
  printf "x\n" | inc_ok
  printf "x\n" | inc_no
  echo "pipeline pass=$p fail=$f"
  inc_ok <<<"x"
  inc_no <<<"x"
  echo "herestring pass=$p fail=$f"
')
echo "$jf7_probe" | /usr/bin/sed 's/^/  /'
if [ "$(printf '%s\n' "$jf7_probe" | "$GREP" -c -F 'pipeline pass=0 fail=0')" -eq 1 ] &&
  [ "$(printf '%s\n' "$jf7_probe" | "$GREP" -c -F 'herestring pass=1 fail=1')" -eq 1 ]; then
  ok JF7 "the pipeline form loses both counters and the here-string form keeps both, so this script's gate can trip"
else
  no JF7 "the counter probe did not behave as expected: $jf7_probe"
fi
# And the four repaired checks are written with a here-string, not a pipeline.
n_pipe=$("$GREP" -c '| *$' "$HERE/check-r3.sh" | head -1 || true)
n_here=$("$GREP" -c '<<<"\$(git -C' "$HERE/check-r3.sh" || true)
if [ "$n_here" -eq 4 ]; then
  ok JF7b "$GREP counted $n_here here-string-fed assert_stream call(s) in this script, one per repaired check"
else
  no JF7b "$GREP counted $n_here here-string-fed assert_stream call(s), expected 4 (trailing-pipe lines: $n_pipe)"
fi
echo

echo "=== JF-2 — the figures revision 1 asserted from artifacts its log did not print ==="
LOCK1="$HERE/spike/Cargo.lock"
if [ ! -f "$LOCK1" ]; then
  no JF2a "revision 1's spike lockfile absent at $LOCK1"
else
  n=$("$GREP" -c '^\[\[package\]\]' "$LOCK1" || true)
  if [ "$n" -eq 20 ]; then
    ok JF2a "$GREP counted $n [[package]] stanzas in revision 1's spike lockfile, the 20-package figure the decision cites"
  else
    no JF2a "$GREP counted $n [[package]] stanzas, not the 20 the decision cites"
  fi
fi
if [ ! -f "$HERE/check-archive.log" ]; then
  no JF2b "evidence/check-archive.log absent — the archive rerun is unrecorded"
else
  assert_contains JF2b "$HERE/check-archive.log" \
    'PASS=25 FAIL=0 SKIP=0' \
    "the recorded git archive HEAD rerun of revision 1's check.sh ends with the same summary"
fi
echo

echo "=== JF-3 — the R5.7 half of the Disagreement-5 citation ==="
if [ ! -f "$STANDARD" ]; then
  sk JF3-cli-standard-absent "$STANDARD is not present in this extraction"
else
  assert_contains JF3 "$STANDARD" \
    '❌ no way to see why a setting took the value it did' \
    "R5.7 carries the anti-pattern line revision 1 cited without a check covering it"
fi
echo

echo "=== JF-4 / JF-5 — citations read through the source pins ==="
if [ ! -d "$PY_REPO/.git" ]; then
  sk JF4-py-repo-absent "$PY_REPO is not a git repository on this machine"
else
  assert_stream JF4a "py config.py:127-128 carries the --config collapse docstring" \
    '``--config`` collapses discovery to that single file; otherwise the' \
    <<<"$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/config.py" | sed -n '127,128p')"
  assert_stream JF4b "py config.py:148-150 carries the load_config tolerance docstring" \
    'Tolerant by design — with one exception: an *explicit* ``--config`` file that exists but cannot be parsed raises :class:`ConfigError`. Discovered layers and invalid values degrade to warnings' \
    <<<"$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/config.py" | sed -n '148,150p')"
  assert_stream JF5a "py config.py:103 is the line returning the discovered-layer warning, not :102" \
    'return {}, f"ignoring unreadable config file {path}: {exc}"' \
    <<<"$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/config.py" | sed -n '103p')"
fi
if [ ! -d "$TS_REPO/.git" ]; then
  sk JF5-ts-repo-absent "$TS_REPO is not a git repository on this machine"
else
  assert_stream JF5b "ts config.ts:154 is the click.Path(exists=True) parity comment, not :153" \
    'click.Path(exists=True) parity: a usage error, exit 2.' \
    <<<"$(git -C "$TS_REPO" show "$TS_PIN:src/lib/config.ts" | sed -n '154p')"
fi
echo

echo "=== JF-8 / JF-9 — where the R8a gap sits, and the pins revision 2 left off ==="
if [ ! -f "$R53" ]; then
  no JF8a "R53 decision absent at $R53"
else
  # The must-agree row the silent-section gap bears on.
  assert_contains JF8a "$R53" \
    '| A value outside a key'"'"'s allowed set is rejected, never silently coerced | Whether the check is a type, a derive attribute, or a hand-written predicate |' \
    "R53's own must-agree table carries the row the silent non-table section does not satisfy"
fi
R53_VERIFY="$ROOT/research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/evidence/verify.sh"
if [ ! -f "$R53_VERIFY" ]; then
  no JF8b "R53 evidence script absent at $R53_VERIFY"
else
  # The line that produces the silence: as_table() returning None skips the body.
  assert_contains JF8b "$R53_VERIFY" \
    'if let Some(t) = table.get("output").and_then(toml::Value::as_table) {' \
    "R53's published loop reaches a section through as_table, so a non-table section skips the body"
  # JF-9(ii): the helper begins at :649, not :650.
  helper_line=$(awk 'NR==649' "$R53_VERIFY")
  if [ "$helper_line" = "fn field<T: serde::de::DeserializeOwned>(" ]; then
    ok JF9c "R53 verify.sh:649 is the first line of the per-key helper, correcting revision 2's :650-657 to :649-657"
  else
    no JF9c "R53 verify.sh:649 reads: $helper_line"
  fi
fi
if [ ! -d "$PY_REPO/.git" ]; then
  sk JF9a-py-repo-absent "$PY_REPO is not a git repository on this machine"
else
  # JF-9(i), py half: all three models tolerate unknown keys.
  n=$(git -C "$PY_REPO" show "$PY_PIN:src/py_launch_blueprint/core/settings.py" |
    "$GREP" -c -F 'model_config = {"extra": "ignore"}' || true)
  if [ "$n" -eq 3 ]; then
    ok JF9a "$GREP counted $n occurrences of model_config = {\"extra\": \"ignore\"} in py settings.py at $PY_PIN — all three models tolerate unknown keys"
  else
    no JF9a "$GREP counted $n occurrences, expected 3"
  fi
fi
if [ ! -d "$TS_REPO/.git" ]; then
  sk JF9b-ts-repo-absent "$TS_REPO is not a git repository on this machine"
else
  # JF-9(i), ts half: z.object with neither .strict() nor .passthrough() strips.
  ts_schema=$(git -C "$TS_REPO" show "$TS_PIN:src/lib/config.ts" | sed -n '37,41p')
  n_obj=$(printf '%s\n' "$ts_schema" | "$GREP" -c -F '= z.object({' || true)
  n_strict=$(printf '%s\n' "$ts_schema" | "$GREP" -c -E '\.strict\(\)|\.passthrough\(\)' || true)
  if [ "$n_obj" -eq 1 ] && [ "$n_strict" -eq 0 ]; then
    ok JF9b "$GREP counted $n_obj z.object declaration and $n_strict .strict()/.passthrough() calls in ts config.ts:37-41 at $TS_PIN — zod strips unknown keys by default"
  else
    no JF9b "$GREP counted $n_obj z.object and $n_strict strict/passthrough in ts config.ts:37-41"
  fi
fi
echo

echo "=== D05 — the reconciliation probe, unchanged from revision 2 (built OUTSIDE the repository) ==="
echo "The probe measures R53's published per-key loop against serde_ignored and"
echo "serde_path_to_error on identical inputs. It depends on those two crates"
echo "only in order to measure them; the decision recommends neither."
if ! command -v cargo >/dev/null 2>&1; then
  sk D05-cargo-absent "cargo is not on PATH"
elif [ ! -f "$HERE/spike-r2/src/main.rs" ]; then
  sk D05-probe-source-absent "no probe source at $HERE/spike-r2"
else
  workdir=$(mktemp -d)
  trap 'rm -rf "$workdir"' EXIT
  cp -R "$HERE/spike-r2/." "$workdir/"
  out="$workdir/run.txt"
  if (cd "$workdir" && cargo run --quiet --offline >"$out" 2>&1) ||
    (cd "$workdir" && cargo run --quiet >"$out" 2>&1); then
    cat "$out"
    n_pass=$("$GREP" -c '^PASS ' "$out" || true)
    n_fail=$("$GREP" -c '^FAIL ' "$out" || true)
    if "$GREP" -q '^ALL R2 PROBE ASSERTIONS PASSED$' "$out" && [ "$n_fail" -eq 0 ] && [ "$n_pass" -ge 9 ]; then
      ok D05 "$GREP counted $n_pass PASS and $n_fail FAIL lines, and the final banner is present"
    else
      no D05 "$GREP counted $n_pass PASS and $n_fail FAIL lines; banner check failed"
    fi
    # The two findings that move the member list.
    assert_contains D05a "$out" \
      'PASS R3 the two unknown-key reports are identical: R53=["output.colour", "verbose"] serde_ignored=["output.colour", "verbose"]' \
      "R53's loop reports the same unknown keys as serde_ignored, at both depths"
    assert_contains D05b "$out" \
      'PASS R4 every reported path pruned, siblings survive, second pass is clean' \
      "R53's Issue.path addresses a prunable leaf, so no path-tracking crate is needed"
    # The four-clause rule, reproduced on R53's mechanism.
    assert_contains D05c "$out" \
      'PASS R5 the lower layer'"'"'s valid value survives and the final pass is clean' \
      "clause 4 (sanitize per layer, merge, one pass) holds on R53's loop"
    assert_contains D05d "$out" \
      'PASS R6 merge-first falls back to the default, losing the user layer'"'"'s value' \
      "merge-first still loses that value on R53's loop"
    # The two constraints revision 2 places on how P03 writes R53's loop.
    assert_contains D05e "$out" \
      'PASS R7 leaves at a nesting level the key list does not enumerate are reported as unknown, never validated' \
      "the key list and serde(flatten) must agree about nesting"
    assert_contains D05f "$out" \
      'PASS R8a R53'"'"'s loop as published reports nothing and returns silent defaults' \
      "a section key that is not a table is silent under the loop as published"
    assert_contains D05g "$out" \
      'PASS R8b the repair makes it a localizable value-level fault, prunable, second pass clean' \
      "the one-line repair R55 requires restores P2 for that fault"
    echo "Resolved dependency versions in the probe lockfile:"
    "$GREP" -A1 '^name = "\(serde\|toml\|serde_path_to_error\|serde_ignored\)"$' "$workdir/Cargo.lock" |
      "$GREP" -v '^--$' | paste - - | /usr/bin/sed 's/^/  /'
    n_pkg=$("$GREP" -c '^\[\[package\]\]' "$workdir/Cargo.lock" || true)
    echo "  $GREP counted $n_pkg [[package]] stanzas in the probe lockfile"
  else
    cat "$out"
    sk D05-build-failed "cargo could not build the probe (offline with no cache, or no network); see the output above"
  fi
fi
echo

echo "=== summary ==="
echo "PASS=$pass FAIL=$fail SKIP=$skip"
[ "$fail" -eq 0 ]
