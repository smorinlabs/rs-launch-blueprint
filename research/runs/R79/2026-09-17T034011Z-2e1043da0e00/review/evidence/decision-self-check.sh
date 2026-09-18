#!/usr/bin/env bash
# R79 prometheus-metrics — checks this decision against the rules that govern it
# and against the evidence logs beside it.
#
# It is deliberately offline and deliberately git-free: it locates the repository
# root by walking up from $0, never from the working directory, and never shells
# out to git, so it runs unchanged inside a `git archive HEAD` extraction where
# there is no .git at all. Where a worktree .git is a FILE rather than a
# directory, the presence test below uses -e, not -d.
#
# Exits non-zero if any check FAILs. Every SKIP is named.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
review="$(cd "$here/.." && pwd)"
run="$(cd "$review/.." && pwd)"
# run -> R79 -> runs -> research -> repository root
root="$(cd "$run/../../../.." && pwd)"

DECISION="$review/DECISION.md"
RAW="$run/raw/opus.md"
RAW_SHA=c1d02b81cd0929881f66c7810af782496a84f73a8f45472e86e773a0300145ac
REGISTRY="$root/docs/port/PARAMETERS.md"
INDEX="$root/research/CLAUDE.md"
GATE1='inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool'

GREP=/usr/bin/grep

pass_count=0
fail_count=0
skip_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS  %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { skip_count=$((skip_count + 1)); printf 'SKIP  %s\n' "$*"; }

scratch="$(mktemp -d "${TMPDIR:-/tmp}/rslb-r79-selfcheck.XXXXXX")"
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

echo "== environment =="
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'repository root resolved by walking up from the script path: %s\n' "$root"
if [ -e "$root/.git" ]; then
  if [ -d "$root/.git" ]; then
    printf 'context: a git checkout (.git is a directory)\n'
  else
    printf 'context: a git worktree (.git is a FILE, which is why the test is -e and not -d)\n'
  fi
else
  printf 'context: no .git present -- this is a clean extraction, and every check below still runs\n'
fi
"$GREP" --version | head -1
echo

for required in "$DECISION" "$RAW" "$REGISTRY" "$INDEX"; do
  if [ -f "$required" ]; then
    pass "required input present: ${required#"$root"/}"
  else
    fail "required input MISSING: ${required#"$root"/}"
  fi
done
if [ ! -f "$DECISION" ] || [ ! -f "$REGISTRY" ]; then
  echo
  echo "== summary =="
  printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
    "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
  exit 1
fi
printf 'DECISION.md sha256 %s\n' "$(shasum -a 256 "$DECISION" | awk '{print $1}')"
echo

# ------------------------------------------------- identity of the raw report --
echo "== the engine report this decision synthesizes =="
raw_actual="$(shasum -a 256 "$RAW" | awk '{print $1}')"
printf 'raw/opus.md sha256 %s\n' "$raw_actual"
if [ "$raw_actual" = "$RAW_SHA" ]; then
  pass "raw/opus.md matches the sha256 the controller's task message names"
else
  fail "raw/opus.md sha256 is $raw_actual, not the $RAW_SHA the task message names"
fi
if [ -f "$run/raw/opus-$RAW_SHA.md" ]; then
  if cmp -s "$RAW" "$run/raw/opus-$RAW_SHA.md"; then
    pass "raw/opus.md is byte-identical to its content-addressed twin"
  else
    fail "raw/opus.md differs from its content-addressed twin"
  fi
else
  skip "content-addressed twin comparison (raw/opus-<sha>.md is not present in this extraction)"
fi
raw_report_count="$(find "$run/raw" -maxdepth 1 -name '*.md' ! -name "*-$RAW_SHA.md" | wc -l | tr -d ' ')"
if [ "$raw_report_count" = "1" ]; then
  pass "exactly one non-content-addressed engine report is registered (the Codex leg is absent)"
else
  fail "the raw/ directory holds an unexpected number of engine reports"
fi
echo

# ------------------------------------------------------------- answer shape ----
echo "== raw-answer shape, via the module's own validator =="
if python3 - "$RAW" <<'PY' > "$scratch/answer.txt" 2>&1
import sys, pathlib
scripts = pathlib.Path(sys.argv[1]).resolve().parents[5] / "scripts"
sys.path.insert(0, str(scripts))
from research_validation import validate_answer_text
errors = validate_answer_text(pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), "crate")
for line in errors:
    print(line)
sys.exit(1 if errors else 0)
PY
then
  pass "validate_answer_text(raw/opus.md, \"crate\") returns no diagnostics"
else
  if "$GREP" -q "ModuleNotFoundError\|No module named" "$scratch/answer.txt"; then
    skip "validate_answer_text (scripts/research_validation.py is not importable from this extraction)"
  else
    fail "validate_answer_text(raw/opus.md, \"crate\") reported diagnostics"
  fi
  sed 's/^/    /' "$scratch/answer.txt"
fi
echo

# --------------------------------------------------------- decision shape -----
echo "== decision shape, via the module's own decision validator =="
# validate_answer_text checks the fifteen H3 fields of a RAW ANSWER. The validator
# that governs a DECISION.md is _validate_decision_text in the same module, and it
# is the one run here, seeded with this decision's own re-verify text so the
# heading, principles and single-trigger rules are all exercised.
if python3 - "$DECISION" <<'DECISION_SHAPE' > "$scratch/decision-shape.txt" 2>&1
import sys, pathlib
path = pathlib.Path(sys.argv[1]).resolve()
sys.path.insert(0, str(path.parents[5] / "scripts"))
import research_validation as rv
text = path.read_text(encoding="utf-8")
triggers = [l.strip() for l in text.splitlines() if l.strip().startswith("re-verify:")]
if len(triggers) != 1:
    print("expected exactly one re-verify line, found %d" % len(triggers))
    sys.exit(1)
errors = []
rv._validate_decision_text(text, "R79", {"reverify": triggers[0][len("re-verify: "):]}, errors)
for line in errors:
    print(line)
sys.exit(1 if errors else 0)
DECISION_SHAPE
then
  pass "_validate_decision_text(DECISION.md, \"R79\") returns no diagnostics"
else
  if "$GREP" -q "ModuleNotFoundError\|No module named" "$scratch/decision-shape.txt"; then
    skip "_validate_decision_text (scripts/research_validation.py is not importable from this extraction)"
  else
    fail "_validate_decision_text(DECISION.md, \"R79\") reported diagnostics"
  fi
  sed 's/^/    /' "$scratch/decision-shape.txt"
fi
echo

echo "== decision shape, against docs/superpowers/plans/p02-roles/synthesizer.md =="
expected_h1='# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 1)'
actual_h1="$(head -1 "$DECISION")"
if [ "$actual_h1" = "$expected_h1" ]; then
  pass "H1 is the date-first form the revision rules require"
else
  fail "H1 is '$actual_h1', not '$expected_h1'"
fi

"$GREP" -n '^## ' "$DECISION" > "$scratch/h2.txt" || true
sed 's/^/    /' "$scratch/h2.txt"
h2_list="$(awk -F'^[0-9]+:## ' '{print $2}' "$scratch/h2.txt" | paste -sd'|' -)"
if [ "$h2_list" = "Decision|Parameters|Empirical check|Engines" ]; then
  pass "H2 sections are exactly Decision, Parameters, Empirical check, Engines, in order"
else
  fail "H2 sections are '$h2_list'"
fi

if "$GREP" -q '^## Supersedes' "$DECISION"; then
  fail "a first revision must not carry '## Supersedes'"
else
  pass "no '## Supersedes' section, as required of a first revision"
fi

h3_principles="$("$GREP" -c '^### Principles and implementation$' "$DECISION" || true)"
if [ "$h3_principles" = "1" ]; then
  pass "exactly one '### Principles and implementation' H3"
else
  fail "found $h3_principles '### Principles and implementation' headings, expected exactly 1"
fi
# It must live inside ## Decision, i.e. before ## Parameters.
principles_line="$("$GREP" -n '^### Principles and implementation$' "$DECISION" | head -1 | cut -d: -f1)"
parameters_line="$("$GREP" -n '^## Parameters$' "$DECISION" | head -1 | cut -d: -f1)"
if [ -n "$principles_line" ] && [ -n "$parameters_line" ] && [ "$principles_line" -lt "$parameters_line" ]; then
  pass "'### Principles and implementation' sits inside '## Decision' (line $principles_line < $parameters_line)"
else
  fail "'### Principles and implementation' is not inside '## Decision'"
fi

reverify_n="$("$GREP" -c '^re-verify:' "$DECISION" || true)"
if [ "$reverify_n" = "1" ]; then
  pass "exactly one line begins 're-verify:'"
else
  fail "found $reverify_n lines beginning 're-verify:', expected exactly 1"
fi
reverify_line="$("$GREP" -n '^re-verify:' "$DECISION" | head -1 | cut -d: -f1)"
if [ -n "$reverify_line" ] && [ "$reverify_line" -lt "$parameters_line" ]; then
  pass "the re-verify line is inside '## Decision' (line $reverify_line < $parameters_line)"
else
  fail "the re-verify line is not inside '## Decision'"
fi
# It must be the last non-blank line of ## Decision.
last_decision_line="$(awk -v stop="$parameters_line" 'NR < stop && NF { n = NR } END { print n }' "$DECISION")"
if [ "$reverify_line" = "$last_decision_line" ]; then
  pass "the re-verify line is the final content line of '## Decision'"
else
  fail "the final content line of '## Decision' is $last_decision_line, not the re-verify line at $reverify_line"
fi

if "$GREP" -q '^## Decision' "$DECISION" && \
   "$GREP" -q 'proposal validated in the implementation phase' "$DECISION"; then
  pass "'## Decision' records that this is a proposal validated in the implementation phase"
else
  fail "'## Decision' does not record the 2026-09-10 proposal-validated-in-P03 ruling"
fi
echo

# ---------------------------------------------------------- the licence gate ---
echo "== fitness gate 1, under owner ruling 2026-09-12 (Q7.B) =="
if "$GREP" -qF "$GATE1" "$DECISION"; then
  pass "the exact gate-1 'inapplicable' string is recorded"
else
  fail "the exact gate-1 'inapplicable' string is missing"
fi
echo "-- mechanical enumeration: every line carrying a licence subject --"
"$GREP" -niE 'licen|MIT|Apache|GPL|copyleft|permissive|patent grant|gate 1' "$DECISION" \
  > "$scratch/licence-lines.txt" || true
awk -F: '{ printf "    %s: %.150s\n", $1, substr($0, index($0, ":") + 1) }' "$scratch/licence-lines.txt"
printf 'lines carrying a licence subject: %s\n' "$(wc -l < "$scratch/licence-lines.txt" | tr -d ' ')"
# No line may assert a gate-1 verdict of its own.
if "$GREP" -niE '(licen[cs]e[^|]*(—|-) *pass)|(gate 1[^|]*pass)|(licen[cs]e compatible[^|]*pass)' "$DECISION" \
     > "$scratch/gate1-verdicts.txt"; then
  fail "a gate-1 PASS verdict survives; the ruling strikes the gate rather than passing it"
  sed 's/^/    /' "$scratch/gate1-verdicts.txt"
else
  pass "no line asserts a gate-1 pass verdict anywhere in the decision"
fi
# The fixed `license` parameter line must survive: the ruling does not touch it.
if "$GREP" -q '^- assumes license = MIT OR Apache-2.0$' "$DECISION"; then
  pass "the fixed 'license' parameter line survives the ruling, as it must"
else
  fail "the fixed 'license' parameter line is missing"
fi
echo

# ------------------------------------------------------------- parameters -----
echo "== parameter lines, byte-compared with docs/port/PARAMETERS.md =="
# Pull the registry's value column mechanically. The table row shape is
# | param | kind | owner | value | description |
awk -F'|' 'NF >= 6 {
  name = $2; gsub(/^[ \t]+|[ \t]+$/, "", name)
  value = $5; gsub(/^[ \t]+|[ \t]+$/, "", value)
  if (name ~ /^[a-z0-9-]+$/ && name != "param") print name "\t" value
}' "$REGISTRY" > "$scratch/registry.tsv"
printf 'registry rows parsed: %s\n' "$(wc -l < "$scratch/registry.tsv" | tr -d ' ')"

"$GREP" -n '^- \(owns\|assumes\) ' "$DECISION" | sed 's/^\([0-9]*\):/\1 /' > "$scratch/declared.txt" || true
printf 'declared parameter lines in the decision: %s\n' "$(wc -l < "$scratch/declared.txt" | tr -d ' ')"
awk '{ printf "    line %s: %.90s...\n", $1, substr($0, index($0, " ") + 1) }' "$scratch/declared.txt"

owns_n="$("$GREP" -c '^- owns ' "$DECISION" || true)"
if [ "$owns_n" = "0" ]; then
  pass "no '- owns' line, matching the prompt's empty '- owns:' coupling"
else
  fail "found $owns_n '- owns' lines; R79's prompt owns no parameter"
fi

assumes_names="$("$GREP" '^- assumes ' "$DECISION" | sed 's/^- assumes \([a-z0-9-]*\) = .*/\1/' | sort | paste -sd',' -)"
if [ "$assumes_names" = "license,msrv-policy,rust-edition,target-os-matrix" ]; then
  pass "the assumed parameter set is exactly the four fixed parameters (the prompt's '- consumes:' line is empty)"
else
  fail "the assumed parameter set is '$assumes_names', not the four fixed parameters"
fi

while IFS= read -r line; do
  name="$(printf '%s' "$line" | sed 's/^- assumes \([a-z0-9-]*\) = .*/\1/')"
  value="$(printf '%s' "$line" | sed 's/^- assumes [a-z0-9-]* = //')"
  registry_value="$(awk -F'\t' -v want="$name" '$1 == want { print $2 }' "$scratch/registry.tsv")"
  if [ -z "$registry_value" ]; then
    fail "parameter '$name' has no row in docs/port/PARAMETERS.md"
  elif [ "$value" = "$registry_value" ]; then
    pass "'$name' is byte-identical to its registry row (${#value} bytes)"
  else
    fail "'$name' differs from its registry row"
    printf '%s\n' "$value"          > "$scratch/decl.txt"
    printf '%s\n' "$registry_value" > "$scratch/reg.txt"
    diff "$scratch/reg.txt" "$scratch/decl.txt" | sed 's/^/    /' || true
  fi
  case "$value" in
    *'`'*) fail "'$name' carries a backtick; the validator compares the raw bytes after '= '" ;;
    *)     pass "'$name' carries no backtick or inline citation" ;;
  esac
done < <("$GREP" '^- assumes ' "$DECISION")

# The R69 value is consumed in prose, not as a parameter line. Prove the prose
# quotation is the registry's own bytes rather than a paraphrase.
web_value="$(awk -F'\t' '$1 == "web-extra-surface" { print $2 }' "$scratch/registry.tsv")"
for fragment in \
  'otel = ["web", ...] for R78 and metrics = ["web", ...] for R79' \
  'tower 0.5.3 is a dev-dependency only'; do
  if printf '%s' "$web_value" | "$GREP" -qF -- "$fragment" \
     && "$GREP" -qF -- "$fragment" "$DECISION"; then
    pass "the decision quotes the registry's own web-extra-surface bytes: \"${fragment:0:44}...\""
  else
    fail "the fragment \"${fragment:0:44}...\" is not present in both the registry row and the decision"
  fi
done
if "$GREP" -q '^- assumes web-extra-surface' "$DECISION"; then
  fail "web-extra-surface appears as an '- assumes' line; R79's '- consumes:' is empty and publication would fail"
else
  pass "web-extra-surface is consumed in prose, not declared as an '- assumes' line"
fi
echo

# --------------------------------------- figures cross-checked with the logs ---
echo "== every measured figure the decision quotes, cross-checked with its own log =="
# check_figure <figure-as-the-decision-writes-it> <log> <label>
# The decision writes large numbers with thousands separators and the tools print
# them bare, so the decision is searched for the separated form and the log for
# the same digits with the separators removed. Both must hit.
check_figure() {
  local needle="$1" log="$2" label="$3" bare
  bare="$(printf '%s' "$needle" | tr -d ',')"
  if [ ! -f "$log" ]; then
    skip "$label (log not present: ${log#"$root"/})"
    return
  fi
  if ! "$GREP" -qF -- "$needle" "$DECISION"; then
    fail "$label -- '$needle' is not in the decision"
    return
  fi
  if ! "$GREP" -qE "(^|[^0-9])$bare([^0-9]|$)" "$log"; then
    fail "$label -- '$bare' is not in ${log##*/}"
    return
  fi
  pass "$label (decision '$needle' = log '$bare')"
}
probes="$here/cargo-probes.log"
sources="$here/crate-sources.log"

check_figure "1,307,968"  "$probes" "stripped binary, feature off, agrees with the probe log" || true
check_figure "1,686,016"  "$probes" "stripped binary, feature on, agrees with the probe log" || true
for pair in \
  "37:E2 lower crate count" \
  "81:E2 upper crate count" \
  "51:E3 lower crate count" \
  "79:E3 upper crate count" \
  "118:E4 packages locked at Rust 1.96" \
  "1251:E5 advisory-database size" \
  "119:E5 crate dependencies scanned" \
  "82:runner-up crate count"; do
  number="${pair%%:*}"
  label="${pair#*:}"
  if "$GREP" -qE "(^|[^0-9,])$number([^0-9]|$)" "$probes"; then
    pass "$label ($number) is present in cargo-probes.log"
  else
    fail "$label ($number) is NOT in cargo-probes.log"
  fi
done
check_figure "1.85.0" "$probes" "highest declared tree rust-version agrees with the probe log" || true
check_figure "1,199"  "$sources" "metrics reverse-dependency total (decision) matches the log's 1199" || true
echo "   note: the decision writes registry counts with thousands separators and the logs print them bare;"
echo "   the two forms are compared field by field in the rows above rather than by naive substring match."
for bare_pair in \
  "1199:metrics reverse dependencies" \
  "460:exporter reverse dependencies" \
  "20185758:metrics 90-day downloads" \
  "108173967:metrics all-time downloads" \
  "13007165:exporter 90-day downloads" \
  "47578577:exporter all-time downloads"; do
  number="${bare_pair%%:*}"
  label="${bare_pair#*:}"
  if "$GREP" -qE "(^|[^0-9])$number([^0-9]|$)" "$sources" 2>/dev/null; then
    pass "$label ($number) is present in crate-sources.log"
  else
    fail "$label ($number) is NOT in crate-sources.log"
  fi
done

# The corrected unsafe figures must appear in the decision AND in the log.
for needle in "27 in \`src/cow.rs\`" "5 in \`src/recorder/cell.rs\`" "3 in \`src/recorder/mod.rs\`"; do
  if "$GREP" -qF -- "$needle" "$DECISION"; then
    pass "the corrected unsafe figure is recorded in the decision: $needle"
  else
    fail "the corrected unsafe figure is missing from the decision: $needle"
  fi
done
if [ -f "$sources" ] && "$GREP" -q "total across src/: 35 ; in src/cow.rs alone: 27" "$sources"; then
  pass "the corrected unsafe figures are backed by crate-sources.log"
else
  fail "crate-sources.log does not carry the corrected unsafe measurement"
fi

# promtool: the check the raw left proposed, executed here.
if [ -f "$probes" ] && "$GREP" -q "promtool check metrics accepted the exposition text" "$probes"; then
  pass "the promtool conformance parse is recorded as EXECUTED in cargo-probes.log"
else
  fail "cargo-probes.log does not record an executed promtool conformance parse"
fi
if [ -f "$here/scrape-sample.txt" ]; then
  pass "the exposition text promtool parsed is committed at review/evidence/scrape-sample.txt"
else
  fail "review/evidence/scrape-sample.txt is missing"
fi
echo

# ------------------------------------------------- hygiene and cross-checks ---
echo "== hygiene =="
if "$GREP" -rnE '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}' \
     "$DECISION" "$here"/*.sh > "$scratch/emails.txt"; then
  fail "an email address appears in the decision or an evidence script"
  sed 's/^/    /' "$scratch/emails.txt"
else
  pass "no email address in the decision or any evidence script"
fi
# Match a token VALUE, not a bare prefix: a bare prefix would make this line
# match itself and report a finding on the very check that looks for one.
if "$GREP" -rnE 'gh[pousr]_[A-Za-z0-9]{36,}|github_pat_[A-Za-z0-9_]{20,}' \
     "$DECISION" "$here"/*.sh "$here"/*.log > "$scratch/tokens.txt"; then
  fail "something that looks like a GitHub token appears in a committed artefact"
  sed 's/^/    /' "$scratch/tokens.txt"
else
  pass "no token-shaped bytes in the decision, the scripts or the logs"
fi
if "$GREP" -qF 'https://github.com/smorinlabs/rs-launch-blueprint' "$here/crate-sources.sh"; then
  pass "the network scripts identify themselves with the repository URL, not a person"
else
  fail "the network User-Agent does not use the repository URL"
fi
lock_count="$(find "$here/locks" -maxdepth 1 -name '*.lock' 2>/dev/null | wc -l | tr -d ' ')"
if [ -d "$here/locks" ] && [ "$lock_count" -ge 4 ]; then
  pass "the probe lockfile snapshots are committed, which is what makes the counts reproducible"
else
  fail "review/evidence/locks/ does not hold the probe lockfile snapshots"
fi
if find "$here" -name target -type d -o -name '.git' | "$GREP" -q .; then
  fail "a target/ tree or a nested .git is present under review/evidence/"
else
  pass "no target/ tree and no nested repository under review/evidence/"
fi

echo "-- every evidence script ends in a counted summary and a non-zero exit on FAIL --"
for script in "$here"/*.sh; do
  name="$(basename "$script")"
  if "$GREP" -q 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s' "$script" \
     && "$GREP" -q 'set -euo pipefail' "$script"; then
    pass "$name sets 'set -euo pipefail' and prints a counted summary"
  else
    fail "$name is missing 'set -euo pipefail' or its counted summary"
  fi
done
if command -v shellcheck > /dev/null 2>&1; then
  shellcheck --version | head -2 | tail -1 | sed 's/^/    shellcheck /'
  if shellcheck "$here"/*.sh > "$scratch/shellcheck.txt" 2>&1; then
    pass "every evidence script is shellcheck-clean"
  else
    fail "shellcheck reported findings"
    sed 's/^/    /' "$scratch/shellcheck.txt"
  fi
else
  skip "shellcheck (not installed in this environment)"
fi

echo "-- the research index still carries R79 with the slug and kind this decision assumes --"
if "$GREP" -qE '^\| R79 \| prometheus-metrics \| crate \|' "$INDEX"; then
  pass "research/CLAUDE.md row R79 is 'prometheus-metrics', kind 'crate'"
else
  fail "research/CLAUDE.md row R79 no longer matches this decision's item, slug and kind"
fi
if "$GREP" -qE '^\| F326 \|' "$root/docs/port/COMMONALITY.md" \
   && "$GREP" -n '^| F326 |' "$root/docs/port/COMMONALITY.md" | "$GREP" -q '^330:'; then
  pass "F326 is still at docs/port/COMMONALITY.md:330, the line this decision cites"
else
  fail "F326 is no longer at docs/port/COMMONALITY.md:330"
fi
echo

echo "== summary =="
printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
  "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
