#!/usr/bin/env bash
# R60 revision 3 — prove by diff against the committed revision-1 and revision-2
# texts that what the audits did not challenge is unchanged, and that every changed
# line is in scope.
#
# WHY THIS SCRIPT EXISTS IN THIS FORM. Revision 2's equivalent script was rejected
# because three of its checks read the *working tree's dirty state* — it required
# `git status --porcelain` to report exactly six modified paths and `DECISION.md`
# among them. Those conditions held only while the revision was uncommitted; the
# moment it was committed the tree went clean and the checks failed. It also wrote
# a sidecar file into the run directory as a side effect, and reached the repository
# through the authoring machine's home directory.
#
# This rewrite asserts on CONTENT that survives committing:
#   * the revision-1 and revision-2 texts are committed under
#     `review/evidence/snapshots/`, so no git object lookup is needed;
#   * "nothing was scaffolded" is a `find` over the committed run directory, not a
#     diff against the index;
#   * "the revision landed" is the r1->r3 and r2->r3 diffs being non-empty;
#   * the script writes nothing anywhere.
#
# No absolute path is printed and `shasum` is fed on stdin, so the saved log is
# byte-identical when this is rerun from any directory.
#
# Harness note, carried from revision 2: the counter is kept in the current shell
# (no piped function bodies), and check C0 proves the harness can fail.
set -o pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"

DEC="$RUN_DIR/review/DECISION.md"
R1="$SNAP/r60-decision-r1.md"
R2="$SNAP/r60-decision-r2.md"
R1_SHA256="d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c"
R2_SHA256="18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c"
REGISTRY="$REPO_ROOT/docs/port/PARAMETERS.md"

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

sha() { shasum -a 256 < "$1" | awk '{print $1}'; }   # stdin, so no path is printed

# preserved <substring> <label> — SUBSET test: every revision-1 line containing
# <substring> must still be present, byte-identical, in the current file.
#
# It is deliberately a subset test and not a set-equality test. The current text
# quotes several of these strings when it explains what it preserved, which would
# make an equality test report a change that did not happen. What the claim actually
# asserts is that no revision-1 line was altered or removed, so that is what is
# checked: each original line must still occur verbatim.
preserved() {
  local want="$1" label="$2" missing=0 total=0 line
  checks=$((checks + 1))
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    total=$((total + 1))
    grep -qxF -- "$line" "$DEC" || { missing=$((missing + 1)); printf '  MISSING: %s\n' "$line"; }
  done < <(grep -F -- "$want" "$R1")
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

echo "=== C1. the committed baselines are the texts the two audits read ==="
# Revision 2's version of this check resolved HEAD:<path> and required it to be the
# revision-1 blob, which stopped being true the instant revision 2 was committed.
# The baselines are now committed files, identified by the content hashes the audit
# reports name, so the check holds at every later commit.
out="$(sha "$R1")"
echo "revision-1 snapshot sha256: $out"
check "C1a the revision-1 baseline is the draft audit-codex.r1.md rejected" "$R1_SHA256" "$out"
out="$(sha "$R2")"
echo "revision-2 snapshot sha256: $out"
check "C1b the revision-2 baseline is the draft audit-codex.r2.md rejected" "$R2_SHA256" "$out"
out="$(grep -F "$R1_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-1 sha256: $out"
check "C1c MANIFEST.txt records the revision-1 baseline" "r60-decision-r1.md" "$out"
out="$(grep -F "$R2_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-2 sha256: $out"
check "C1d MANIFEST.txt records the revision-2 baseline" "r60-decision-r2.md" "$out"
out="$(grep -c "$R1_SHA256" "$RUN_DIR/review/audit-codex.r1.md")"
echo "occurrences of the revision-1 sha256 in audit-codex.r1.md: $out"
check "C1e the revision-1 auditor's own report names that hash" "count=1" "count=$out"
out="$(grep -c "$R2_SHA256" "$RUN_DIR/review/audit-codex.r2.md")"
echo "occurrences of the revision-2 sha256 in audit-codex.r2.md: $out"
check "C1f the revision-2 auditor's own report names that hash" "count=1" "count=$out"

echo "=== C2. what the audits did NOT challenge is byte-identical ==="
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
echo "-- the compared alternatives and the fitness-gate rows --"
preserved '| A | Declarative single-source parser, derive front-end' 'architecture A'
preserved '| E | Small derive parser aimed at binary size' 'architecture E'
preserved '| `clap 4.6.6` | `MIT OR Apache-2.0` | declares `1.85`' 'clap fitness-gate data row'
preserved '`casey/just` | ships **exactly** this decision' 'the just composition evidence'
echo "-- what revision 2 added and this revision keeps --"
preserved_r2() { # same subset test, but against the revision-2 baseline
  local want="$1" label="$2" missing=0 total=0 line
  checks=$((checks + 1))
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    total=$((total + 1))
    grep -qxF -- "$line" "$DEC" || { missing=$((missing + 1)); printf '  MISSING: %s\n' "$line"; }
  done < <(grep -F -- "$want" "$R2")
  if [ "$total" -eq 0 ]; then
    printf 'BUG        %s — the substring matched nothing in revision 2; the check proves nothing\n' "$label"
    fails=$((fails + 1))
  elif [ "$missing" -eq 0 ]; then
    printf 'PRESERVED  %s (%d revision-2 line(s) still verbatim)\n' "$label" "$total"
  else
    printf 'CHANGED    %s (%d of %d revision-2 line(s) no longer verbatim)\n' "$label" "$missing" "$total"
    fails=$((fails + 1))
  fi
}
preserved_r2 '**Waiver status, as of 2026-09-12: requested, not granted.**' "OV-01's dated not-granted status line"
# Scoped to the `## Decision` quotation of R1.3, not to every line containing the
# rule's words: the `## Empirical check` row that also quotes it is rewritten by
# this revision, and a target matching both would report that rewrite as a lost
# preservation.
preserved_r2 '"Resource nouns **MUST** be **singular** in their canonical form. The plural' "R1.3's rule text as revision 2 quoted it in ## Decision"
preserved_r2 '| Content sha256 | `9fb05d3dfaa5ea11fbf66422e988b0ae8c050e22a39b9fc6dd9688734f02463f`' 'the standard pin row carrying the content hash'

echo "=== C3. the four assumes lines match the registry byte-for-byte ==="
while IFS= read -r line; do
  name="${line#- assumes }"; name="${name%% = *}"
  val="${line#*= }"
  out="$(grep -F "| $name | fixed | owner | $val |" "$REGISTRY")"
  check "C3 $name = $val matches docs/port/PARAMETERS.md" "| $name | fixed | owner | $val |" "$out"
done < <(grep '^- assumes ' "$DEC")
out="$(grep -c '^- assumes ' "$DEC")"
echo "assumes lines in the decision: $out"
check "C3x exactly four assumes lines" "count=4" "count=$out"
out="$(grep -c '^- owns ' "$DEC")"
echo "owns lines in the decision: $out"
check "C3y no owns line, because the prompt's - owns: line is empty" "count=0" "count=$out"

echo "=== C4. structural invariants ==="
out="$(grep -c '^## ' "$DEC")"
echo "H2 count: $out"
check "C4a exactly four H2 sections" "count=4" "count=$out"
out="$(grep '^## ' "$DEC" | tr '\n' ' ')"
echo "H2s: $out"
check "C4b they are Decision, Parameters, Empirical check, Engines in order" \
  "## Decision ## Parameters ## Empirical check ## Engines" "$out"
out="$(grep -c '^## Supersedes' "$DEC")"
check "C4c no ## Supersedes section" "count=0" "count=$out"
out="$(grep -c 'OV-01' "$DEC")"
echo "OV-01 mentions: $out"
check "C4d OV-01 is named (this decision's only override)" "yes" \
  "$([ "$out" -gt 0 ] && echo yes || echo no)"
# Scoped to override DECLARATIONS, not to any mention of the string: the prose
# names OV-02..OV-09 when stating that none was invented.
out="$(grep -coE 'OVERRIDE \(OV-0[2-9]\)' "$DEC")"
echo "OVERRIDE (OV-02..OV-09) declarations: $out"
check "C4e no second override was declared" "count=0" "count=$out"
out="$(grep -coE 'OVERRIDE \(OV-01\)' "$DEC")"
echo "OVERRIDE (OV-01) declarations: $out"
check "C4e2 OV-01 is declared as an override" "yes" \
  "$([ "$out" -ge 1 ] && echo yes || echo no)"
out="$(grep -c 'requested, not granted' "$DEC")"
echo "'requested, not granted' occurrences (the status line, plus the revision narrative citing it): $out"
check "C4f the waiver-not-granted wording is present" "yes" \
  "$([ "$out" -ge 1 ] && echo yes || echo no)"
out="$(grep -F '**Waiver status, as of 2026-09-12: requested, not granted.**' "$DEC")"
echo "OV-01 status line: $out"
check "C4f2 OV-01 carries a dated, explicit not-granted status line" \
  "**Waiver status, as of 2026-09-12: requested, not granted.**" "$out"
# Prose wraps across lines, so these assertions read the whitespace-normalized text
# rather than single lines; a line-scoped grep would fail on the wrap alone.
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
# Affirmative claims only. A bare /owner.*granted/ would match the document's own
# sentence saying that zero such claims exist, so each pattern is an assertion that
# the waiver WAS given, and negated forms are excluded explicitly.
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
check "C4g no claim that the owner granted the waiver" "count=0" "count=$appr"
out="$(grep -c 'revision 3, 2026-09-13' "$DEC")"
echo "title lines recording revision 3: $out"
check "C4h the title records revision 3" "count=1" "count=$out"
echo "-- gate 1 is recorded as inapplicable, not deleted (owner ruling 2026-09-12) --"
check "C4i the decision records gate 1 as inapplicable with the ruling as its reason" \
  "inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool" \
  "$FLAT"
out="$(grep -c '^| Candidate | 1\. license' "$DEC")"
echo "fitness-gate table headers still carrying a gate-1 column: $out"
check "C4j the gate-1 row is kept in the table rather than removed" "count=1" "count=$out"

echo "=== C5. no crate was scaffolded and no command surface was written ==="
# Revision 2 asserted this against the working tree's dirty paths, which is why it
# could not be rerun after the commit. It is now a property of the committed run
# directory itself, which is true at every later commit.
out="$(find "$RUN_DIR" -type f \( -name '*.rs' -o -name 'Cargo.toml' -o -name 'Cargo.lock' \) | wc -l | tr -d ' ')"
echo "Rust/Cargo files anywhere in this run directory: $out"
check "C5a no .rs, Cargo.toml or Cargo.lock exists in this run" "count=0" "count=$out"
out="$(find "$RUN_DIR" -type d \( -name 'src' -o -name 'target' \) | wc -l | tr -d ' ')"
echo "src/ or target/ directories in this run directory: $out"
check "C5b no crate skeleton exists in this run" "count=0" "count=$out"
echo "-- every evidence file this revision cites exists --"
for f in \
  review/evidence/r60-standard-pin-r3.sh \
  review/evidence/r60-standard-pin-r3.log \
  review/evidence/r60-preservation-diff-r3.sh \
  review/evidence/r60-preservation-diff-r3.log \
  review/evidence/r60-snapshot-provenance-r3.sh \
  review/evidence/r60-snapshot-provenance-r3.log \
  review/evidence/r60-cli-parsing-verification.log \
  review/evidence/audit-cli-parsing-framework-r1.log \
  review/evidence/snapshots/MANIFEST.txt \
; do
  out="$([ -f "$RUN_DIR/$f" ] && echo present || echo MISSING)"
  printf '  %-58s %s\n' "$f" "$out"
  check "C5c $f exists" "present" "$out"
done

echo "=== C6. every line that differs from revision 1, enumerated ==="
removed="$(diff "$R1" "$DEC" | grep -c '^<')"
added="$(diff "$R1" "$DEC" | grep -c '^>')"
printf 'revision-1 lines replaced or removed: %s\n' "$removed"
check "C6 the r1 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed" -gt 0 ] && [ "$added" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-1 lines replaced or removed ---"
diff "$R1" "$DEC" | grep '^<' | cut -c1-160

echo "=== C7. every line that differs from revision 2, enumerated ==="
# This is the delta an auditor of revision 3 has to review: revision 2 was rejected
# on one finding (its evidence scripts were not rerunnable after commit) and this
# revision also records gate 1 as inapplicable under the owner's 2026-09-12 ruling.
removed2="$(diff "$R2" "$DEC" | grep -c '^<')"
added2="$(diff "$R2" "$DEC" | grep -c '^>')"
printf 'revision-2 lines replaced or removed: %s\n' "$removed2"
check "C7 the r2 diff is non-empty in both directions" "yes" \
  "$([ "$removed2" -gt 0 ] && [ "$added2" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-2 lines replaced or removed ---"
diff "$R2" "$DEC" | grep '^<' | cut -c1-160

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
