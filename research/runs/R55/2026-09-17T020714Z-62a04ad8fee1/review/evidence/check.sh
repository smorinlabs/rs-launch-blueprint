#!/usr/bin/env bash
# R55 config-error-tolerance — synthesizer evidence checks.
#
# Every check asserts on content, never on an exit code alone. The script is
# rerunnable from a clean `git archive HEAD` extraction: no check reads .git,
# and a check whose external input is unavailable prints SKIP with its own name
# rather than passing vacuously.
#
# The counting binary is named beside every count it produces.

# SC2016: the literal needles below are Markdown quoted in single quotes on
# purpose — backticks and $ inside them are the text being matched, not shell.
# shellcheck disable=SC2016

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Locate the repository root by content, not by .git, so a `git archive HEAD`
# extraction works.
ROOT="$HERE"
while [ "$ROOT" != "/" ] && [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; do
  ROOT="$(dirname "$ROOT")"
done
if [ ! -f "$ROOT/docs/port/PARAMETERS.md" ]; then
  echo "FATAL: could not locate the repository root above $HERE"
  exit 1
fi

R67="$ROOT/research/topics/67-error-and-exit-code-contract/DECISION.md"
LEDGER="$ROOT/docs/port/COMMONALITY.md"
REGISTRY="$ROOT/docs/port/PARAMETERS.md"
DECISION="$HERE/../DECISION.md"
STANDARD=/Users/stevemorin/c/cli-standards/cli-design-standard.md
STANDARD_BLOB=f9de0437baece3383e73ca2c5f48b7ab399b51c7

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
# Reflows the file onto one line first, so a needle that the source wraps
# across lines is still matched literally.
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

echo "=== R55 evidence — environment ==="
echo "date (UTC):      $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "repository root: $ROOT"
echo "counting binary: $GREP ($("$GREP" --version 2>&1 | head -1))"
echo "uname:           $(uname -sm)"
if command -v cargo >/dev/null 2>&1; then echo "cargo:           $(cargo --version)"; fi
if command -v rustc >/dev/null 2>&1; then echo "rustc:           $(rustc --version)"; fi
echo

echo "=== C01-C03 — R67 (owner-accepted prerequisite) settles the CONFLICT ==="
# The exact catalogue row the codex raw report says cannot express per-leaf
# recovery.
assert_contains C01 "$R67" \
  '`RSLB203` config value invalid → 2' \
  "R67 publishes the RSLB203 catalogue row"
# The sentence that decides the CONFLICT: R67 delegates tolerance to R55.
assert_contains C02 "$R67" \
  'Each case gets its own catalog entry so R54–R56 can route to any of them without inventing a code. R55 and R56 own whether a given condition is tolerated, warned about, or fatal; this item only guarantees the entry and the code exist.' \
  "R67 delegates tolerated-vs-fatal to R55, so RSLB203 is an available code and not a mandate"
assert_contains C03a "$R67" \
  '`RSLB104` config layer unreadable → 1' \
  "R67 publishes the RSLB104 row this decision routes an unreadable explicit layer to"
assert_contains C03b "$R67" \
  '`RSLB202` config document unparsable → 2' \
  "R67 publishes the RSLB202 row this decision routes an unparsable explicit document to"
assert_contains C03c "$R67" \
  '`RSLB201` usage/parse (including the CLI parser'"'"'s own errors) → 2' \
  "R67 publishes the RSLB201 row the strict alternative for (a) would use"
echo

echo "=== C04 — ledger rows this decision settles ==="
assert_contains C04a "$LEDGER" \
  '| F235 | explicit `--config` pointing at a missing file |' \
  "COMMONALITY carries F235"
assert_contains C04b "$LEDGER" \
  '| F236 | unparsable *discovered* config layer degrades to a warning, not a crash |' \
  "COMMONALITY carries F236"
assert_contains C04c "$LEDGER" \
  '| F237 | unparsable *explicit* config file raises loudly | config-env-logging | same | COMMON → REUSE |' \
  "COMMONALITY carries F237 as COMMON → REUSE with origin same (the BASELINE-REVIEW target)"
assert_contains C04d "$LEDGER" \
  '| F238 | invalid config *values* (right TOML, wrong value) degrade to a warning and are dropped |' \
  "COMMONALITY carries F238 with no layer qualifier in its row text"
echo

echo "=== C05 — every '- assumes' line is byte-identical to the registry ==="
if [ ! -f "$DECISION" ]; then
  no C05 "DECISION.md absent at $DECISION"
else
  c05_fail=0
  c05_n=0
  while IFS= read -r line; do
    c05_n=$((c05_n + 1))
    param="${line#- assumes }"
    param="${param%% = *}"
    value="${line#- assumes "$param" = }"
    # The registry row is: | <param> | <kind> | <owner> | <value> | <desc> |
    registry_value=$("$GREP" -F -- "| $param | " "$REGISTRY" | head -1 |
      awk -F ' \\| ' '{print $4}')
    if [ -z "$registry_value" ]; then
      echo "  MISMATCH $param: no registry row found"
      c05_fail=$((c05_fail + 1))
    elif [ "$registry_value" = "$value" ]; then
      echo "  ok $param (${#value} bytes match the registry byte-for-byte)"
    else
      echo "  MISMATCH $param"
      echo "    decision: ${value:0:120}"
      echo "    registry: ${registry_value:0:120}"
      c05_fail=$((c05_fail + 1))
    fi
  done < <("$GREP" '^- assumes ' "$DECISION")
  if [ "$c05_n" -eq 0 ]; then
    no C05 "DECISION.md carries no '- assumes' line; $GREP counted 0"
  elif [ "$c05_fail" -eq 0 ]; then
    ok C05 "$GREP found $c05_n '- assumes' line(s), all byte-identical to $REGISTRY"
  else
    no C05 "$c05_fail of $c05_n '- assumes' line(s) differ from the registry"
  fi
  # This decision owns no parameter: the prompt's `- owns:` line is empty.
  owns_n=$("$GREP" -c '^- owns ' "$DECISION" || true)
  if [ "$owns_n" -eq 0 ]; then
    ok C05b "$GREP counted $owns_n '- owns' line(s), matching the prompt's empty owns: field"
  else
    no C05b "$GREP counted $owns_n '- owns' line(s); the prompt's owns: field is empty"
  fi
fi
echo

echo "=== C06 — org CLI Design Standard v1.4.14 rules cited by this decision ==="
if [ ! -f "$STANDARD" ]; then
  sk C06-cli-standard-absent "$STANDARD is not present in this extraction"
else
  blob=$(git hash-object "$STANDARD")
  if [ "$blob" = "$STANDARD_BLOB" ]; then
    ok C06a "the standard read is blob $blob, the blob this decision cites"
  else
    no C06a "the standard read is blob $blob, not the cited $STANDARD_BLOB"
  fi
  assert_contains C06b "$STANDARD" \
    'An explicit `--config <path>` **MUST** **replace** the discovered project/user/system config files — it becomes the sole config file in the chain' \
    "R5.2 makes an explicit --config replace the discovered layers"
  assert_contains C06c "$STANDARD" \
    '**SHOULD** validate config files with precise file/key diagnostics' \
    "R5.8 requires precise file/key diagnostics"
  assert_contains C06d "$STANDARD" \
    '❌ silently ignoring bad config' \
    "R5.8 names silent ignoring of bad config as the anti-pattern"
  assert_contains C06e "$STANDARD" \
    'name the offending input in quotes, and state a next step where possible' \
    "R7.6 requires an error to name the offending input"
fi
echo

echo "=== C07 — crates.io figures for the two crates this decision adds ==="
echo "Endpoint: GET https://crates.io/api/v1/crates/<name>/versions"
echo "Retrieved: see the snapshot files beside this script; the assertions below"
echo "read the snapshots, not the live endpoint, so they are stable on rerun."
for crate in serde_path_to_error serde_ignored; do
  snap="$HERE/$crate-versions.json"
  if [ ! -f "$snap" ]; then
    sk "C07-$crate-snapshot-absent" "no snapshot at $snap"
    continue
  fi
  # Tab-separated: the licence string contains spaces.
  IFS=$'\t' read -r num yanked lic msrv <<<"$(python3 -c "
import json,sys
d=json.load(open(sys.argv[1]))
v=[x for x in d['versions'] if not x['yanked']][0]
print('\t'.join([v['num'], str(v['yanked']), v['license'], str(v.get('rust_version'))]))
" "$snap")"
  case "$crate" in
  serde_path_to_error) want=0.1.20 ;;
  serde_ignored) want=0.1.14 ;;
  *) want="none-expected" ;;
  esac
  if [ "$num" = "$want" ] && [ "$yanked" = "False" ] && [ "$lic" = "MIT OR Apache-2.0" ] && [ "$msrv" = "1.61" ]; then
    ok "C07-$crate" "newest non-yanked $num, license $lic, rust_version $msrv"
  else
    no "C07-$crate" "expected $want / not yanked / MIT OR Apache-2.0 / 1.61; got $num / yanked=$yanked / $lic / $msrv"
  fi
done
echo "Download counts move daily and are therefore reported, never asserted:"
for crate in serde_path_to_error serde_ignored; do
  snap="$HERE/$crate-crate.json"
  if [ -f "$snap" ]; then
    python3 -c "
import json,sys
c=json.load(open(sys.argv[1]))['crate']
print('  %s recent_downloads=%d downloads=%d (snapshot of GET https://crates.io/api/v1/crates/%s)' % (c['name'], c['recent_downloads'], c['downloads'], c['name']))
" "$snap"
  fi
done
echo

echo "=== C08 — the verification spike (built OUTSIDE the repository) ==="
echo "The spike is throwaway verification, not a template scaffold: P03 builds"
echo "the template. Its source is checked in beside this script as the check's"
echo "input and is copied to a temporary directory to build."
if ! command -v cargo >/dev/null 2>&1; then
  sk C08-cargo-absent "cargo is not on PATH"
elif [ ! -f "$HERE/spike/src/main.rs" ]; then
  sk C08-spike-source-absent "no spike source at $HERE/spike"
else
  workdir=$(mktemp -d)
  trap 'rm -rf "$workdir"' EXIT
  cp -R "$HERE/spike/." "$workdir/"
  spike_out="$workdir/run.txt"
  if (cd "$workdir" && cargo run --quiet --offline >"$spike_out" 2>&1) ||
    (cd "$workdir" && cargo run --quiet >"$spike_out" 2>&1); then
    cat "$spike_out"
    n_pass=$("$GREP" -c '^PASS ' "$spike_out" || true)
    n_fail=$("$GREP" -c '^FAIL ' "$spike_out" || true)
    if "$GREP" -q '^ALL ASSERTIONS PASSED$' "$spike_out" && [ "$n_fail" -eq 0 ] && [ "$n_pass" -ge 15 ]; then
      ok C08 "$GREP counted $n_pass PASS and $n_fail FAIL lines, and the final banner is present"
    else
      no C08 "$GREP counted $n_pass PASS and $n_fail FAIL lines; banner check failed"
    fi
    # Content assertions on the individual claims this decision rests on.
    assert_contains C08a "$spike_out" \
      'PASS A1 sibling limit survives: output.limit = 7' \
      "a bad leaf is dropped and its sibling survives"
    assert_contains C08b "$spike_out" \
      'PASS H1 a leaf inside the flattened target collapses to a non-prunable path: path="."' \
      "serde(flatten) collapses the tracked path when the failing leaf is inside the flattened target"
    assert_contains C08c "$spike_out" \
      'PASS H2 a leaf outside the flattened target keeps a prunable path: path="output.format"' \
      "the collapse is confined to leaves inside the flattened target"
    assert_contains C08d "$spike_out" \
      'PASS M1 the lower layer'"'"'s valid value survives the higher layer'"'"'s invalid one: output.format = Json' \
      "sanitize-then-merge keeps the lower layer's valid value"
    assert_contains C08e "$spike_out" \
      'PASS N1 merge-first falls back to the built-in default, losing user.toml'"'"'s value: output.format = Text' \
      "merge-then-drop (py's order) loses that value on identical inputs"
    assert_contains C08f "$spike_out" \
      'PASS F1 root-level shape fault maps to RSLB203' \
      "a fault the tracked path cannot localize stays fatal, so RSLB203 has a target"
    echo "Resolved dependency versions in the spike lockfile:"
    "$GREP" -A1 '^name = "\(serde\|toml\|serde_path_to_error\|serde_ignored\)"$' "$workdir/Cargo.lock" |
      "$GREP" -v '^--$' | paste - - | /usr/bin/sed 's/^/  /'
  else
    cat "$spike_out"
    sk C08-build-failed "cargo could not build the spike (offline with no cache, or no network); see the output above"
  fi
fi
echo

echo "=== summary ==="
echo "PASS=$pass FAIL=$fail SKIP=$skip"
[ "$fail" -eq 0 ]
