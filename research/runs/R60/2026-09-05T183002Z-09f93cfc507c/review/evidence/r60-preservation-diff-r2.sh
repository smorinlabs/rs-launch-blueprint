#!/usr/bin/env bash
# R60 revision 2 — prove by diff against the revision-1 blob that what the audit
# did not challenge is unchanged, and that every changed line is in scope.
#
# Harness note: as in r60-standard-pin-r2.sh, the counter is kept in the current
# shell (no piped function bodies), and check C0 proves the harness can fail.
set -o pipefail

REPO="$HOME/c/rs-launch-blueprint-p02-plan"
DEC="$REPO/research/runs/R60/2026-09-05T183002Z-09f93cfc507c/review/DECISION.md"
R1_BLOB="5ae06c378ee71a8d6b16eb394862806284c72ca5"
R1_SHA256="d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c"
R1_FILE="$(mktemp -t r60-rev1)"

fails=0; checks=0

check() { # check <label> <expected-substring> <actual>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation\n' "$label"; fails=$((fails + 1)); return
  fi
  if printf '%s' "$got" | grep -qF -- "$want"; then printf 'PASS  %s\n' "$label"
  else printf 'FAIL  %s\n      wanted: %s\n      got: %s\n' "$label" "$want" "$got"; fails=$((fails + 1)); fi
}

# preserved <substring> <label> — SUBSET test: every revision-1 line containing
# <substring> must still be present, byte-identical, in the current file.
#
# It is deliberately a subset test and not a set-equality test. Revision 2's own
# prose quotes several of these strings when it explains what it preserved, which
# would make an equality test report a change that did not happen. What the claim
# actually asserts is that no revision-1 line was altered or removed, so that is
# what is checked: each original line must still occur verbatim.
preserved() {
  local want="$1" label="$2" missing=0 total=0 line
  checks=$((checks + 1))
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    total=$((total + 1))
    grep -qxF -- "$line" "$DEC" || { missing=$((missing + 1)); printf '  MISSING: %s\n' "$line"; }
  done < <(grep -F -- "$want" "$R1_FILE")
  if [ "$total" -eq 0 ]; then
    printf 'BUG        %s — the substring matched nothing in revision 1; the check proves nothing\n' "$label"
    fails=$((fails + 1))
  elif [ "$missing" -eq 0 ]; then
    printf 'PRESERVED  %s (%d revision-1 line(s) still verbatim)\n' "$label" "$total"
  else
    printf 'CHANGED    %s (%d of %d revision-1 line(s) no longer verbatim)\n' "$label" "$missing" "$total"
    fails=$((fails + 1))
  fi
}

echo "=== C0. negative control: prove this harness can fail ==="
echo "--- the next two failures are deliberate ---"
check "C0a control (expected FAIL)" "ABSENT-SUBSTRING" "present text"
preserved "THIS-TEXT-IS-IN-NEITHER-FILE" "C0b control (expected BUG: a substring absent from revision 1 proves nothing)"
if [ "$fails" -eq 2 ] && [ "$checks" -eq 2 ]; then
  echo "PASS  C0 both harness paths detect a mismatch"
else
  echo "BUG   C0 harness does not register mismatches (fails=$fails) — results meaningless"; exit 99
fi
echo "--- controls accounted for; counters reset ---"
fails=0; checks=0

echo "=== C1. recover the revision-1 blob and confirm it is the rejected draft ==="
git -C "$REPO" cat-file blob "$R1_BLOB" > "$R1_FILE" 2>/dev/null
out="$(shasum -a 256 "$R1_FILE" | awk '{print $1}')"
echo "revision-1 blob $R1_BLOB sha256: $out"
check "C1 the blob is the draft the audit rejected" "$R1_SHA256" "$out"

echo "=== C2. what the audit did NOT challenge is byte-identical ==="
echo "-- the recommended crate and feature set --"
preserved 'clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }' 'clap 4.6.6 pin and its four features'
preserved 'clap_complete = "4.6.9"' 'clap_complete 4.6.9 pin'
preserved 'resolved at `0.11.1` on 2026-09-10' 'strsim 0.11.1, transitive only'
preserved "a dependency-free \`build.rs\` reading Cargo's \`TARGET\`" 'the dependency-free build.rs mechanism'
preserved '`default = []`; requires `clap >= 4.5.20`' 'clap_complete default features and clap floor'
echo "-- the lockfile generation and advisory audit that both exited zero --"
preserved 'Locking 28 packages to latest Rust 1.96 compatible versions' 'lockfile generation, 28 packages'
preserved '`cargo generate-lockfile` and `cargo tree -e normal`' 'the lockfile command itself'
preserved '`cargo audit` **exit 0**, 1,243 advisories loaded, 29 crate dependencies scanned' 'advisory audit, exit 0'
echo "-- the four fixed parameter lines --"
preserved '- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI' 'assumes msrv-policy'
preserved '- assumes rust-edition = 2024' 'assumes rust-edition'
preserved '- assumes target-os-matrix = ubuntu-latest, macos-latest' 'assumes target-os-matrix'
preserved '- assumes license = MIT OR Apache-2.0' 'assumes license'
echo "-- OV-01's argument and its three options --"
preserved '**SHOULD** print a single line `acme <semver>`' "OV-01 Argument's R4.6 quotation"
preserved '| b | `-V` *and* `--version` both one line' 'OV-01 option b, conforming'
preserved '| c | `-V` and `--version` both one line; extended data moved to a `doctor` verb' 'OV-01 option c, conforming'
preserved 'The owner'"'"'s ruling is needed because only the owner can record a `SHOULD`' 'OV-01 owner-ruling sentence'
echo "-- the compared alternatives and the fitness gates --"
preserved '| A | Declarative single-source parser, derive front-end' 'architecture A'
preserved '| E | Small derive parser aimed at binary size' 'architecture E'
preserved '| `clap 4.6.6` | `MIT OR Apache-2.0` | declares `1.85`' 'clap fitness-gate row'
preserved '`casey/just` | ships **exactly** this decision' 'the just composition evidence'

echo "=== C3. the four assumes lines match the registry byte-for-byte ==="
while IFS= read -r line; do
  name="${line#- assumes }"; name="${name%% = *}"
  val="${line#*= }"
  out="$(grep -F "| $name | fixed | owner | $val |" "$REPO/docs/port/PARAMETERS.md")"
  check "C3 $name = $val matches docs/port/PARAMETERS.md" "| $name | fixed | owner | $val |" "$out"
done < <(grep '^- assumes ' "$DEC")

echo "=== C4. structural invariants ==="
out="$(grep -c '^## ' "$DEC")"
echo "H2 count: $out"
check "C4a exactly four H2 sections" "4" "$out"
out="$(grep '^## ' "$DEC" | tr '\n' ' ')"
echo "H2s: $out"
check "C4b they are Decision, Parameters, Empirical check, Engines in order" \
  "## Decision ## Parameters ## Empirical check ## Engines" "$out"
out="$(grep -c '^## Supersedes' "$DEC")"
check "C4c no ## Supersedes section" "0" "$out"
out="$(grep -c 'OV-01' "$DEC")"
echo "OV-01 mentions: $out"
check "C4d OV-01 is named (this decision's only override)" "1" \
  "$([ "$out" -gt 0 ] && echo 1 || echo 0)"
# Scoped to override DECLARATIONS, not to any mention of the string: revision 2's
# own prose names OV-02..OV-09 when stating that none was invented.
out="$(grep -coE 'OVERRIDE \(OV-0[2-9]\)' "$DEC")"
echo "OVERRIDE (OV-02..OV-09) declarations: $out"
check "C4e no second override was declared" "0" "$out"
out="$(grep -coE 'OVERRIDE \(OV-01\)' "$DEC")"
echo "OVERRIDE (OV-01) declarations: $out"
check "C4e2 OV-01 is declared as an override" "1" \
  "$([ "$out" -ge 1 ] && echo 1 || echo 0)"
out="$(grep -c 'requested, not granted' "$DEC")"
echo "'requested, not granted' occurrences (the status line, plus the revision narrative citing it): $out"
check "C4f the waiver-not-granted wording is present" "1" \
  "$([ "$out" -ge 1 ] && echo 1 || echo 0)"
out="$(grep -F '**Waiver status, as of 2026-09-12: requested, not granted.**' "$DEC")"
echo "OV-01 status line: $out"
check "C4f2 OV-01 carries a dated, explicit not-granted status line" \
  "**Waiver status, as of 2026-09-12: requested, not granted.**" "$out"
# Prose wraps across lines, so these two assertions read the whitespace-normalized
# text rather than single lines; a line-scoped grep would fail on the wrap alone.
FLAT="$(tr '\n' ' ' < "$DEC" | tr -s ' ')"
check "C4f3 OV-01 says the owner has not answered the waiver request" \
  "The owner has not answered the waiver request" "$FLAT"
check "C4f4 OV-01 names option (b) as a conforming alternative" \
  "The conforming alternatives are named in the Options table below and are **option (b)**" "$FLAT"
check "C4f5 OV-01 names option (c) as a conforming alternative" \
  "and **option (c)** — extended data moved to a \`doctor\` verb" "$FLAT"
check "C4f6 OV-01 states that only the owner can record the waiver and no record exists" \
  "Only the owner can record a \`SHOULD\` waiver (\`:50\`), no such record exists" "$FLAT"
check "C4f7 OV-01 states its Argument" "**Argument:** R4.6" "$FLAT"
check "C4f8 OV-01 states its Options" "**Options:**" "$FLAT"
# Affirmative claims only. A bare /owner.*granted/ would match revision 2's own
# sentence saying that zero such claims exist, so each pattern is an assertion
# that the waiver WAS given, and negated forms are excluded explicitly.
echo "-- affirmative owner-approval claims (each must be absent) --"
appr=0
for pat in \
  'the owner has granted' \
  'the owner granted' \
  'owner has approved' \
  'owner approved' \
  'waiver (is|was|has been) granted' \
  'waiver granted' \
  'owner waiver record exists' \
  'approved by the owner' \
; do
  hits="$(grep -inE "$pat" "$DEC" | grep -viE 'no such|not |never|zero|without' | wc -l | tr -d ' ')"
  printf '  %-34s %s\n' "$pat" "$hits"
  appr=$((appr + hits))
done
echo "total affirmative owner-approval claims: $appr"
check "C4g no claim that the owner granted the waiver" "0" "$appr"
out="$(grep -c 'revision 2, 2026-09-12' "$DEC")"
check "C4h the title records revision 2" "1" "$out"

echo "=== C5. no crate was scaffolded and no command surface was written ==="
# Scoped to this item's run directory: the shared branch carries concurrent work
# on other research items, reported at the end but not part of this revision.
RUNDIR="research/runs/R60/2026-09-05T183002Z-09f93cfc507c"
out="$(git -C "$REPO" status --porcelain -- "$RUNDIR" | awk '{print $2}' \
  | grep -E '\.rs$|Cargo\.toml$|Cargo\.lock$' | wc -l | tr -d ' ')"
echo "Rust/Cargo files changed under $RUNDIR: $out"
check "C5a no .rs, Cargo.toml or Cargo.lock added or modified in this run" "0" "$out"
echo "--- this revision's change set ---"
git -C "$REPO" status --porcelain -- "$RUNDIR"
out="$(git -C "$REPO" status --porcelain -- "$RUNDIR" | wc -l | tr -d ' ')"
echo "paths changed by this revision: $out"
# Six: DECISION.md, the two scripts, their two logs, and the sidecar written above.
# (The sidecar is created by this very script, so a run before it exists sees 5;
# every run after it sees 6. Asserting 6 keeps the script idempotent.)
check "C5b this revision touched exactly 6 paths (DECISION.md + 2 scripts + 2 logs + 1 sidecar)" "6" "$out"
out="$(git -C "$REPO" status --porcelain -- "$RUNDIR" | grep -c 'DECISION.md')"
check "C5c DECISION.md is modified, so the revision landed" "1" "$out"
# Concurrent work by OTHER items on this shared branch is reported, never staged.
# It is written to a sidecar rather than into this log: other sessions write to
# this branch while the script runs, so including it here would make the log
# non-reproducible for a reason unrelated to anything the log asserts.
SIDECAR="$(dirname "$DEC")/evidence/r60-concurrent-branch-state-r2.txt"
{
  echo "Concurrent work by other research items on branch research/p02-execution."
  echo "Captured by r60-preservation-diff-r2.sh. VOLATILE: other sessions write to"
  echo "this branch, so this file legitimately differs between runs. Nothing in"
  echo "R60's decision rests on it; it exists so this revision's change set is"
  echo "distinguishable from work that is not R60's. Reported, never staged."
  echo
  git -C "$REPO" status --porcelain | grep -v "$RUNDIR" \
    | sed 's|^\(..\) research/runs/\(R[0-9]*\)/.*|\1 \2 (other item)|' | sort -u
} > "$SIDECAR"
echo "--- concurrent work by OTHER items: reported, NOT staged ---"
echo "written to evidence/r60-concurrent-branch-state-r2.txt (volatile by nature, excluded from this log)"

echo "=== C6. every line that differs from revision 1, enumerated ==="
removed="$(diff "$R1_FILE" "$DEC" | grep -c '^<')"
added="$(diff "$R1_FILE" "$DEC" | grep -c '^>')"
printf 'lines changed/removed from revision 1: %s\nlines added by revision 2: %s\n' "$removed" "$added"
check "C6 the diff is non-empty, so the revision actually landed" "1" \
  "$([ "$removed" -gt 0 ] && [ "$added" -gt 0 ] && echo 1 || echo 0)"
echo "--- full list of revision-1 lines replaced or removed ---"
diff "$R1_FILE" "$DEC" | grep '^<' | cut -c1-160

rm -f "$R1_FILE"
echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
