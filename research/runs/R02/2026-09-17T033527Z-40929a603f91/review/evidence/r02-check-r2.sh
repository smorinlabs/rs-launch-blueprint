#!/usr/bin/env bash
# R02 crate-boundary-enforcement -- revision 2 checks.
#
# Revision 2 is EVIDENCE-ONLY: it answers the four non-blocking findings of the
# round-1 judgment audit (review/audit-fable.md, verdict approve) and records the
# resolution of the `CONFLICT:` line the owner settled. The topology, the four
# enforcement mechanisms, OVERRIDE (OV-03), the rankings and the tier assignment
# do not move, and no parameter value moves.
#
# This script asserts, against committed files only:
#   R2-1  JF-1 -- the cargo-deny wall-clock figure is cited BY LABEL and the
#         label's value in the committed log is 0.437 s; the orphan 0.509 is gone.
#   R2-2  JF-2 -- the R01 / R49 / R69 hit counts in the three Doxa twins that
#         refute one clause of Disagreement 1's ground, and the prompt's own R01
#         count that explains where the legs got it.
#   R2-3  JF-3 -- the "survives verbatim" wording is replaced by the wording the
#         finding asks for.
#   R2-4  JF-4 -- R49's fired re-verify trigger is recorded with its outcome.
#   R2-5  the resolution -- R69 revision 10's `- owns` line, read from its own run
#         file, carries each of the six substituted clauses this item's CONFLICT
#         line specified, and the resolution paragraph names W1-R02 and W0-R69c.
#   R2-6  the CONFLICT line is still byte-identical to raw/opus.md's.
#   R2-7  every revision-1 script and log is byte-identical to its revision-1
#         sha256, because revision 2 adds a check rather than editing one.
#   R2-8  the revision-2 shape: title, H2 set, and the four `- assumes` lines
#         byte-identical to the live registry. These take over from
#         r02-decision-shape.sh, whose check S1a binds the revision-1 title and
#         which is therefore NOT rerun for revision 2.
#
# It reads no .git directory and runs unchanged from a clean `git archive HEAD`
# extraction; every check SKIPs BY NAME when its input file is absent.
#
# Exit 0 only when FAILURES is 0.

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
HERE=$(cd "$(dirname "$0")" && pwd)
REVIEW=$(cd "$HERE/.." && pwd)
RUN=$(cd "$REVIEW/.." && pwd)
REPO_ROOT=$(cd "$RUN/../../../.." && pwd)
DECISION="$REVIEW/DECISION.md"
REG="$REPO_ROOT/docs/port/PARAMETERS.md"
PROMPT="$RUN/inputs/prompt.md"
OPUS="$RUN/raw/opus.md"
R69="$REPO_ROOT/research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md"
R69_SHA=d34ab6e8339b6f416a510d070ee54daca38a9086a901a6bfbb9df0517f7fce0a
OWNER="$REPO_ROOT/docs/port/OWNER-REVIEW.md"

CHECKS=0
FAILURES=0
SKIPPED=0

note() { printf '\n=== %s ===\n' "$1"; }
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP %s: %s\n' "$1" "$2"; }

eq() {
  local name="$1" what="$2" got="$3" want="$4"
  CHECKS=$((CHECKS + 1))
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s == %s\n' "$name" "$what" "$got"
  else
    printf 'FAIL %s: %s -- wanted [%s], got [%s]\n' "$name" "$what" "$want" "$got"
    FAILURES=$((FAILURES + 1))
  fi
}

ok() {
  local name="$1" what="$2" file="$3"
  shift 3
  CHECKS=$((CHECKS + 1))
  local pat missing=0
  for pat in "$@"; do
    if ! "$GREP" -qF -- "$pat" "$file"; then
      printf 'FAIL %s: %s -- missing substring: %s\n' "$name" "$what" "$pat"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    printf 'PASS %s: %s\n' "$name" "$what"
  else
    FAILURES=$((FAILURES + 1))
  fi
}

# count NAME WHAT FILE PATTERN WANT  -- line count by absolute-path grep
lines() {
  local name="$1" what="$2" file="$3" pat="$4" want="$5" got
  CHECKS=$((CHECKS + 1))
  got=$("$GREP" -cF -- "$pat" "$file" || true)
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s (%s lines matching %s, by %s)\n' "$name" "$what" "$got" "$pat" "$GREP"
  else
    printf 'FAIL %s: %s -- wanted %s lines matching %s, got %s (by %s)\n' \
      "$name" "$what" "$want" "$pat" "$got" "$GREP"
    FAILURES=$((FAILURES + 1))
  fi
}

sha_is() {
  local name="$1" file="$2" want="$3" got
  CHECKS=$((CHECKS + 1))
  if [ ! -f "$file" ]; then
    printf 'FAIL %s: %s is absent\n' "$name" "$(basename "$file")"
    FAILURES=$((FAILURES + 1))
    return
  fi
  got=$(shasum -a 256 "$file" | awk '{print $1}')
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s is byte-identical to its revision-1 sha256 %s\n' "$name" "$(basename "$file")" "$got"
  else
    printf 'FAIL %s: %s changed -- wanted %s, got %s\n' "$name" "$(basename "$file")" "$want" "$got"
    FAILURES=$((FAILURES + 1))
  fi
}

# quoted_only NAME WHAT FILE PATTERN  -- the pattern may appear, but every line
# carrying it must ALSO be marked as a quotation of superseded wording or as the
# revision note's finding row. A repaired claim is quoted, never deleted, so the
# test is "no LIVE occurrence" rather than "no occurrence".
quoted_only() {
  local name="$1" what="$2" file="$3" pat="$4" total marked
  CHECKS=$((CHECKS + 1))
  total=$("$GREP" -cF -- "$pat" "$file" || true)
  marked=$("$GREP" -F -- "$pat" "$file" | "$GREP" -cE 'Superseded wording of revision 1|\*\*JF-[0-9]\*\*' || true)
  if [ "$total" -gt 0 ] && [ "$total" = "$marked" ]; then
    printf 'PASS %s: %s (%s of %s lines carrying it are marked as superseded wording or as the revision note, by %s)\n' \
      "$name" "$what" "$marked" "$total" "$GREP"
  elif [ "$total" -eq 0 ]; then
    printf 'FAIL %s: %s -- the superseded wording was DELETED rather than quoted (0 occurrences)\n' "$name" "$what"
    FAILURES=$((FAILURES + 1))
  else
    printf 'FAIL %s: %s -- %s of %s lines carrying it are unmarked, so it survives as a LIVE claim\n' \
      "$name" "$what" "$((total - marked))" "$total"
    "$GREP" -nF -- "$pat" "$file" | "$GREP" -vE 'Superseded wording of revision 1|\*\*JF-[0-9]\*\*' || true
    FAILURES=$((FAILURES + 1))
  fi
}

note "R2-0 inputs"
for f in "$DECISION" "$REG" "$PROMPT" "$OPUS" "$R69" "$OWNER"; do
  if [ -f "$f" ]; then printf 'present: %s\n' "${f#"$REPO_ROOT/"}"; else printf 'ABSENT:  %s\n' "${f#"$REPO_ROOT/"}"; fi
done

############################################################################
# R2-1  JF-1: the wall-clock figure, cited by label
############################################################################
note "R2-1 JF-1 -- the cargo-deny wall-clock figure"
CDLOG="$HERE/r02-cargo-deny-bans.log"
if [ ! -f "$CDLOG" ] || [ ! -f "$DECISION" ]; then
  skip R2-1 "r02-cargo-deny-bans.log or DECISION.md is absent from this extraction"
else
  lines R2-1a "the committed log records the measured value twice -- the elapsed line and PASS CD6" \
    "$CDLOG" "0.437 s" 2
  ok R2-1b "and both carry the check label the decision cites" "$CDLOG" \
    'PASS CD6: one bans pass on this probe completed in 0.437 s'
  lines R2-1c "the orphan figure is gone as a LIVE bullet" \
    "$DECISION" "- The 0.509 s figure is a floor" 0
  quoted_only R2-1c2 "and every surviving mention of it is marked as superseded wording or as the revision note's JF-1 row" \
    "$DECISION" "0.509"
  ok R2-1d "and the repaired unproven bullet cites the figure BY LABEL, as the checks discipline requires" \
    "$DECISION" \
    "Check \`CD6\`'s wall-clock figure — **0.437 s** in the committed log"
  ok R2-1e "with the superseded wording quoted rather than deleted" "$DECISION" \
    "Superseded wording of revision 1" \
    "The 0.509 s figure is a floor on a six-package registry-free graph, not a measurement of the template."
  # negative control: the number really is absent rather than the search being broken
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qF -- "0.437" "$DECISION"; then
    printf 'PASS R2-1f: control -- 0.437 IS found in the decision, so R2-1c'"'"'s zero for 0.509 is a real absence and not a broken search\n'
  else
    printf 'FAIL R2-1f: control failed -- neither 0.509 nor 0.437 found; the search is not working\n'
    FAILURES=$((FAILURES + 1))
  fi
fi

############################################################################
# R2-2  JF-2: what the Doxa twins actually cite
############################################################################
note "R2-2 JF-2 -- R01 / R49 / R69 in the three Doxa twins and in the prompt"
MISSING_TWIN=0
for t in openai perplexity gemini; do
  [ -f "$RUN/raw/doxa-$t.normalized.md" ] || MISSING_TWIN=1
done
if [ "$MISSING_TWIN" -eq 1 ] || [ ! -f "$PROMPT" ] || [ ! -f "$DECISION" ]; then
  skip R2-2 "one of the three normalized twins, inputs/prompt.md or DECISION.md is absent from this extraction"
else
  lines R2-2a "openai twin names R01 -- the finding's 14" "$RUN/raw/doxa-openai.normalized.md" "R01" 14
  lines R2-2b "perplexity twin names R01 -- the finding's 7" "$RUN/raw/doxa-perplexity.normalized.md" "R01" 7
  lines R2-2c "gemini twin names R01 -- the finding's 1" "$RUN/raw/doxa-gemini.normalized.md" "R01" 1
  for t in openai perplexity gemini; do
    lines "R2-2d-$t" "$t twin never names R49 -- the half of the ground that survives" \
      "$RUN/raw/doxa-$t.normalized.md" "R49" 0
    lines "R2-2e-$t" "$t twin never names R69" \
      "$RUN/raw/doxa-$t.normalized.md" "R69" 0
  done
  eq R2-2f "the prompt names R01 eight times -- occurrences, not lines: this is where all three legs got it" \
    "$("$GREP" -oF 'R01' "$PROMPT" | wc -l | tr -d ' ')" "8"
  lines R2-2f2 "on three lines of it" "$PROMPT" "R01" 3
  lines R2-2g "and the prompt never names R49" "$PROMPT" "R49" 0
  lines R2-2h "nor R69" "$PROMPT" "R69" 0
  ok R2-2i "the narrowed ground names only R49 and R69, and says how the legs came by R01" \
    "$DECISION" \
    "none of the three Doxa providers cites R49 or R69 anywhere" \
    "name R01 from this prompt's own couplings without having read its published value"
  quoted_only R2-2j "the refuted three-item wording survives only as quoted superseded wording, never as a live claim" \
    "$DECISION" "none of the three Doxa providers cites R49, R69 or R01 anywhere"
fi

############################################################################
# R2-3  JF-3: the "survives verbatim" wording
############################################################################
note "R2-3 JF-3 -- the four gated things"
if [ ! -f "$DECISION" ]; then
  skip R2-3 "DECISION.md is absent from this extraction"
else
  ok R2-3a "the repaired wording is the one the finding asks for" "$DECISION" \
    "the four gated things remain the same four, at the member's paths"
  quoted_only R2-3b "the self-contradicting sentence survives only as quoted superseded wording" \
    "$DECISION" "Every other clause of R69's value survives verbatim"
  ok R2-3c "and the decision marks superseded wording as such rather than deleting it" "$DECISION" \
    "Superseded wording of revision 1"
fi

############################################################################
# R2-4  JF-4: R49's fired trigger
############################################################################
note "R2-4 JF-4 -- R49's re-verify trigger fires with a different outcome"
if [ ! -f "$DECISION" ]; then
  skip R2-4 "DECISION.md is absent from this extraction"
else
  ok R2-4a "the decision records that R49's own trigger fires and names its outcome" "$DECISION" \
    "R49's published re-verify trigger" \
    "no field moves"
fi

############################################################################
# R2-5  The resolution: R69 revision 10 carries the six substitutions
############################################################################
note "R2-5 the CONFLICT resolution"
if [ ! -f "$R69" ]; then
  skip R2-5 "R69's revision-10 run DECISION.md is absent from this extraction"
else
  got=$(shasum -a 256 "$R69" | awk '{print $1}')
  eq R2-5a "R69 revision 10 is the file this decision names" "$got" "$R69_SHA"
  eq R2-5b "and it is revision 10" "$(head -1 "$R69")" \
    "# 2026-09-17 — R69 — web-framework-stack — decision (revision 10)"
  # R69 carries its previous revision under ## Supersedes, so that file holds two
  # `- owns` lines. Read only the CURRENT decision -- everything above the first
  # `## Supersedes` heading -- which is the same rule the packaging validator uses.
  awk '/^## Supersedes/{exit} {print}' "$R69" \
    | "$GREP" '^- owns web-extra-surface = ' > "$HERE/snapshots/r69-rev10-owns.txt"
  eq R2-5c0 "the file does carry a superseded copy, so restricting to the current decision is not a no-op" \
    "$("$GREP" -c '^- owns web-extra-surface = ' "$R69")" "2"
  eq R2-5c "it carries exactly one owned web-extra-surface line" \
    "$(wc -l < "$HERE/snapshots/r69-rev10-owns.txt" | tr -d ' ')" "1"
  # The six substitutions this item's CONFLICT line specified, each asserted on
  # that line and nowhere else in the file.
  ok R2-5d "substitution 1 -- the feature names the optional member, on the root package" \
    "$HERE/snapshots/r69-rev10-owns.txt" \
    'web = ["dep:rs-launch-blueprint-web"]' \
    'declared on the root package rs-launch-blueprint'
  ok R2-5e "substitution 2 -- axum and tokio declared non-optionally inside the member" \
    "$HERE/snapshots/r69-rev10-owns.txt" \
    'axum 0.8.9 declared non-optionally in crates/web/Cargo.toml' \
    'tokio 1.53.1 declared non-optionally in crates/web/'
  ok R2-5f "substitution 3 -- the gated tree reads crates/web/src/" \
    "$HERE/snapshots/r69-rev10-owns.txt" 'crates/web/src/'
  ok R2-5g "substitution 4 -- the tests move and need no file-level cfg" \
    "$HERE/snapshots/r69-rev10-owns.txt" 'crates/web/tests/' 'no file-level'
  ok R2-5h "substitution 5 -- tower 0.5.3 is the member's dev-dependency" \
    "$HERE/snapshots/r69-rev10-owns.txt" "tower 0.5.3 is crates/web's dev-dependency"
  ok R2-5i "substitution 6 -- the skip-gating paths read crates/web/**" \
    "$HERE/snapshots/r69-rev10-owns.txt" 'crates/web/**'
  # negative control: the superseded revision-9 clauses must be gone from that line
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qF -- 'web = ["dep:axum", "dep:tokio"]' "$HERE/snapshots/r69-rev10-owns.txt"; then
    printf 'FAIL R2-5j: control -- revision 10 still carries the revision-9 feature body\n'
    FAILURES=$((FAILURES + 1))
  else
    printf 'PASS R2-5j: control -- the revision-9 feature body is absent from revision 10, so the six PASSes above are a real substitution\n'
  fi
fi

if [ ! -f "$REG" ]; then
  skip R2-5k "docs/port/PARAMETERS.md is absent from this extraction"
else
  awk -F'|' 'NF>=6 {gsub(/^ +| +$/,"",$2); if ($2=="web-extra-surface") {gsub(/^ +| +$/,"",$5); print $5}}' \
    "$REG" > "$HERE/snapshots/r2-registry-web-extra-surface.txt"
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qF -- 'web = ["dep:axum", "dep:tokio"]' "$HERE/snapshots/r2-registry-web-extra-surface.txt"; then
    printf 'PASS R2-5k: the live registry row still carries revision 9, exactly as the resolution paragraph states -- the CONFLICT is discharged at R69 revision 10 PUBLICATION, not before\n'
  else
    printf 'FAIL R2-5k: the registry row no longer carries revision 9; the resolution paragraph must be re-read against it\n'
    FAILURES=$((FAILURES + 1))
  fi
fi

if [ ! -f "$DECISION" ] || [ ! -f "$OWNER" ]; then
  skip R2-5l "DECISION.md or docs/port/OWNER-REVIEW.md is absent from this extraction"
else
  ok R2-5l "the resolution paragraph names the owner ruling and the re-bind" "$DECISION" \
    "W1-R02" "W0-R69c" "2026-09-17" "2026-09-18"
  ok R2-5m "and the owner record it names exists at its heading" "$OWNER" \
    "### 2026-09-17 — R69 \`web-extra-surface\` revised to name the optional web member (W1-R02)"
  ok R2-5n "the decision records that the CONFLICT re-verify trigger has fired" "$DECISION" \
    "has fired"
fi

############################################################################
# R2-6  The CONFLICT line is still the Opus raw's, byte for byte
############################################################################
note "R2-6 the CONFLICT line is unchanged"
if [ ! -f "$DECISION" ] || [ ! -f "$OPUS" ]; then
  skip R2-6 "DECISION.md or raw/opus.md is absent from this extraction"
else
  "$GREP" '^CONFLICT: ' "$DECISION" > "$HERE/snapshots/r2-conflict-decision.txt"
  "$GREP" '^CONFLICT: ' "$OPUS" > "$HERE/snapshots/r2-conflict-opus.txt"
  eq R2-6a "the decision carries exactly one CONFLICT: line" \
    "$(wc -l < "$HERE/snapshots/r2-conflict-decision.txt" | tr -d ' ')" "1"
  CHECKS=$((CHECKS + 1))
  if diff -u "$HERE/snapshots/r2-conflict-opus.txt" "$HERE/snapshots/r2-conflict-decision.txt" > /dev/null; then
    printf 'PASS R2-6b: it is byte-identical to the one raw/opus.md raised\n'
  else
    printf 'FAIL R2-6b: the CONFLICT line no longer matches raw/opus.md\n'
    diff -u "$HERE/snapshots/r2-conflict-opus.txt" "$HERE/snapshots/r2-conflict-decision.txt" || true
    FAILURES=$((FAILURES + 1))
  fi
fi

############################################################################
# R2-7  Every revision-1 artifact is byte-identical
############################################################################
note "R2-7 revision 1's scripts and logs are untouched"
sha_is R2-7a "$HERE/r02-workspace-probe.sh"   c5f882ed90ef7c07ca03a4611362a8ce27a35c1bf662666344efb8f55e34c9de
sha_is R2-7b "$HERE/r02-ecosystem-figures.sh" fb92a60043b3826902653ce734c3f4449faa915d17ac489d8d3616a39abdf0cf
sha_is R2-7c "$HERE/r02-cargo-deny-bans.sh"   3cd76a5cd7218f69d76bc513a269de7bda426a8317c37513c6237eae75eaff66
sha_is R2-7d "$HERE/r02-decision-shape.sh"    bca478e952639861b8eb201b5d362689983e9c08984dbb1854ee37f90f142917
sha_is R2-7e "$HERE/r02-workspace-probe.log"   50aad59e823a2d6d540f0515e54e5a43a52f97363311b50d55e700bc79363ad3
sha_is R2-7f "$HERE/r02-ecosystem-figures.log" ad970dde3151d4a4f389b5e45bdfe9587c2da8a884a7d2b9ada9228f63b0e834
sha_is R2-7g "$HERE/r02-cargo-deny-bans.log"   2b89762979cc3711b128f763596e573e256685c8bf2d075990a1491c2f7d0b86
sha_is R2-7h "$HERE/r02-decision-shape.log"    a0ea7fde4c8ad33cfba87f250168cf01fb041ffe20011987d89f3f61e595961d
if [ ! -f "$HERE/r02-decision-shape.sh" ]; then
  skip R2-7i "r02-decision-shape.sh is absent from this extraction"
else
  ok R2-7i "and r02-decision-shape.sh's title assertion binds the REVISION-1 title, which is why revision 2 does not rerun it" \
    "$HERE/r02-decision-shape.sh" \
    "# 2026-09-17 — R02 — crate-boundary-enforcement (bundle, Deep) — decision (revision 1)"
fi

############################################################################
# R2-8  Revision-2 shape and the parameter grammar
############################################################################
note "R2-8 revision-2 shape"
if [ ! -f "$DECISION" ]; then
  skip R2-8 "DECISION.md is absent from this extraction"
else
  eq R2-8a "title line, date first, revision 2" "$(head -1 "$DECISION")" \
    "# 2026-09-18 — R02 — crate-boundary-enforcement (bundle, Deep) — decision (revision 2)"
  "$GREP" '^## ' "$DECISION" | cut -d: -f1- > "$HERE/snapshots/r2-decision-h2.txt"
  eq R2-8b "the H2 set is unchanged, in order, and nothing else" \
    "$(tr '\n' '|' < "$HERE/snapshots/r2-decision-h2.txt")" \
    "## Decision|## Parameters|## Empirical check|## Engines|"
  eq R2-8c "no ## Supersedes (this item is unpublished)" \
    "$("$GREP" -c '^## Supersedes' "$DECISION" || true)" "0"
  eq R2-8d "exactly one re-verify: line" "$("$GREP" -c '^re-verify: ' "$DECISION")" "1"
  eq R2-8e "OVERRIDE (OV-03) is still declared once and did not move" \
    "$("$GREP" -c '^### OVERRIDE (OV-03) ' "$DECISION")" "1"
  ok R2-8f "the revision note names all four findings and the resolution" "$DECISION" \
    "JF-1" "JF-2" "JF-3" "JF-4" "revision 2"
  ok R2-8g "the open item handed to P03 and R04 is recorded and explicitly not decided here" \
    "$DECISION" "OPEN ITEM"
fi

if [ ! -f "$DECISION" ] || [ ! -f "$REG" ]; then
  skip R2-8h "DECISION.md or docs/port/PARAMETERS.md is absent from this extraction"
else
  awk -F'|' 'NF>=6 && $3 ~ /fixed/ {gsub(/^ +| +$/,"",$2); gsub(/^ +| +$/,"",$5); print "- assumes "$2" = "$5}' \
    "$REG" | sort > "$HERE/snapshots/r2-expected-assumes.txt"
  "$GREP" '^- assumes ' "$DECISION" | sort > "$HERE/snapshots/r2-actual-assumes.txt"
  cat "$HERE/snapshots/r2-actual-assumes.txt"
  CHECKS=$((CHECKS + 1))
  if diff -u "$HERE/snapshots/r2-expected-assumes.txt" "$HERE/snapshots/r2-actual-assumes.txt"; then
    printf 'PASS R2-8h: the four assumes lines are still byte-identical to their live registry rows, and the set still matches exactly\n'
  else
    printf 'FAIL R2-8h: the assumes list no longer matches the registry byte-for-byte\n'
    FAILURES=$((FAILURES + 1))
  fi
  eq R2-8i "still no owns line" "$("$GREP" -c '^- owns ' "$DECISION" || true)" "0"
fi

############################################################################
# R2-9  Two revision-1 checks no longer pass against the post-acceptance tree.
#       Both are expected consequences of this item being accepted, not defects,
#       and this group pins each one so the claim is auditable rather than asserted.
############################################################################
note "R2-9 the two revision-1 checks that the tree has moved under"
if [ ! -d "$REPO_ROOT/docs/port" ]; then
  skip R2-9 "docs/port is absent from this extraction"
else
  {
    "$GREP" -rlF -- 'OV-03' "$REPO_ROOT/docs/port" || true
    for f in "$REPO_ROOT"/research/topics/*/DECISION.md "$REPO_ROOT"/research/runs/*/*/review/DECISION.md; do
      [ -f "$f" ] || continue
      case "$f" in *"/R02/"*) continue ;; esac
      "$GREP" -lF -- 'OV-03' "$f" || true
    done
  } | sed "s|^$REPO_ROOT/||" | sort > "$HERE/snapshots/r2-ov03-references.txt"
  cat "$HERE/snapshots/r2-ov03-references.txt"
  eq R2-9a "OV-03 is now named outside this item, where revision 1's check EF6a required zero" \
    "$(wc -l < "$HERE/snapshots/r2-ov03-references.txt" | tr -d ' ')" "2"
  ok R2-9b "and both files are owner records under docs/port/, not competing decisions" \
    "$HERE/snapshots/r2-ov03-references.txt" \
    "docs/port/OWNER-ACCEPTANCES.md" "docs/port/OWNER-REVIEW.md"
  ok R2-9c "the OWNER-REVIEW hit is this item's own acceptance record, naming R02 and F021" \
    "$OWNER" "\`OVERRIDE (OV-03)\` against F021"
  # The number is still not CLAIMED by another decision: a competing claim would be
  # a heading, which is how this decision and R61's declare theirs.
  n=0
  for f in "$REPO_ROOT"/research/topics/*/DECISION.md "$REPO_ROOT"/research/runs/*/*/review/DECISION.md; do
    [ -f "$f" ] || continue
    case "$f" in *"/R02/"*) continue ;; esac
    if "$GREP" -q '^### OVERRIDE (OV-03)' "$f"; then n=$((n + 1)); fi
  done
  eq R2-9d "no decision outside this item DECLARES an override numbered OV-03" "$n" "0"
  m=0
  for f in "$REPO_ROOT"/research/topics/*/DECISION.md "$REPO_ROOT"/research/runs/*/*/review/DECISION.md; do
    [ -f "$f" ] || continue
    case "$f" in *"/R02/"*) continue ;; esac
    if "$GREP" -q '^### OVERRIDE (OV-02)' "$f"; then m=$((m + 1)); fi
  done
  CHECKS=$((CHECKS + 1))
  if [ "$m" -ge 1 ]; then
    printf 'PASS R2-9e: control -- %s decision(s) outside this item DO declare an override by heading (OV-02), so R2-9d'"'"'s zero is not vacuous\n' "$m"
  else
    printf 'FAIL R2-9e: control failed -- no OV-02 heading found anywhere, so the OV-03 zero is unreliable\n'
    FAILURES=$((FAILURES + 1))
  fi
fi

note "SUMMARY"
printf 'CHECKS RUN: %s FAILURES: %s SKIPPED: %s\n' "$CHECKS" "$FAILURES" "$SKIPPED"
[ "$FAILURES" -eq 0 ]
