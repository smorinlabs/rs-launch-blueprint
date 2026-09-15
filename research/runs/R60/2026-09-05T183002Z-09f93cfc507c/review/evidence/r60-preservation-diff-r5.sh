#!/usr/bin/env bash
# R60 revision 5 — prove by diff against the committed revision-1, revision-2,
# revision-3 and revision-4 texts that what the audits did not challenge is
# unchanged, and that every changed line is in scope.
#
# WHAT REVISION 5 CHANGED IN THIS SCRIPT, AND WHY. This is
# `r60-preservation-diff-r4.sh` with three regions added and one line changed.
# The revision-4 audit rejected the draft on one finding, F1: the decision said
# the owner's ruling of 2026-09-14 was not recorded in this repository, and by
# the time it was audited the controller had written it into
# docs/port/OWNER-REVIEW.md:72-91. Revision 5 repairs that claim and nothing else.
#
#   1. C4h now requires the title to read revision 5. Run against the revision-5
#      text, `r60-preservation-diff-r4.sh` fails on exactly this one check and
#      nothing else — which is itself the evidence that revision 5's edit set is
#      confined to the repair, and it is recorded in the decision rather than
#      predicted. That r4 script is left BYTE-IDENTICAL beside this one.
#   2. A FOURTH BASELINE, the rejected revision-4 text, at the sha256 its own
#      audit report names (12aaf65c...). C9 enumerates the r4->r5 diff, which is
#      the delta an auditor of revision 5 has to review — the same role the r3
#      diff played for revision 4.
#      WHY IT IS NOT IN `snapshots/MANIFEST.txt` like the other three baselines:
#      adding a MANIFEST row would change `r60-snapshot-provenance-r4.sh`'s
#      recorded totals, and that script is unchanged by this revision and stays
#      its own artifact. The baseline is anchored instead by the sha256 the
#      revision-4 audit report itself names, located by that hash rather than by
#      a file name (C1m-C1q) — the same anchor C1i uses for revision 3, and the
#      stronger of the two, because the audit report is what says which bytes
#      were judged.
#   3. A NEW C4k FAMILY asserting the repair: that the decision now cites both
#      durable records by path and section, that the stale paragraph is kept and
#      labelled as corrected rather than deleted, and that U8 is re-labelled
#      RESOLVED rather than dropped from the unproven list.
#
#   GREP is pinned to /usr/bin/grep by absolute path. A typed `grep` in an agent
#   shell on this machine can resolve to `ugrep`, which honors .gitignore.
#
# WHAT REVISION 4 CHANGED IN THIS SCRIPT, AND WHY.
# Revision 4 implements an OWNER RULING, not an audit finding: revision 3 was
# APPROVED (`review/audit-codex.md`, verdict `approve`, unresolved-findings none).
# On 2026-09-14 the owner REFUSED OV-01's SHOULD waiver and selected F267's own
# conforming option (b). Three consequences for this harness:
#
#   1. A third baseline. Revision 3's approved text is committed as
#      `snapshots/r60-decision-r3.md` and identified by the sha256 its own audit
#      report names, exactly as r1 and r2 are. C8 enumerates the r3->r4 diff,
#      which is the delta an auditor of revision 4 has to review.
#   2. The C4f family is INVERTED. Revision 3 asserted that the waiver was
#      outstanding and that nothing claimed otherwise. Revision 4 asserts the
#      opposite: the waiver is refused, OV-01 is retired, the decision declares
#      ZERO overrides, and no SHOULD is waived. The old assertions are not
#      deleted where they still hold — C4g (no claim that the owner GRANTED the
#      waiver) is still true and still checked, because a refusal is not a grant.
#   3. The preservation targets are unchanged and still checked against r1 and
#      r2. The owner's ruling touches F267's mechanism and its acceptance
#      criteria; it touches no crate pin, no gate row, no parameter line, and no
#      part of OV-01's argument or options table, which are kept unedited as the
#      record of how the choice was reached.
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
#   * "the revision landed" is the r1->r4, r2->r4 and r3->r4 diffs being non-empty;
#   * the script writes nothing anywhere.
#
# No absolute path is printed and `shasum` is fed on stdin, so the saved log is
# byte-identical when this is rerun from any directory.
#
# Harness note, carried from revision 2: the counter is kept in the current shell
# (no piped function bodies), and check C0 proves the harness can fail.
set -o pipefail

GREP=/usr/bin/grep   # absolute, never PATH: a typed `grep` here can be ugrep

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SNAP="$HERE/snapshots"
RUN_DIR="$(cd "$HERE/../.." && pwd)"
REPO_ROOT="$(cd "$RUN_DIR/../../../.." && pwd)"

DEC="$RUN_DIR/review/DECISION.md"
R1="$SNAP/r60-decision-r1.md"
R2="$SNAP/r60-decision-r2.md"
R3="$SNAP/r60-decision-r3.md"
R4="$HERE/r60-decision-r4-baseline.md"
R1_SHA256="d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c"
R2_SHA256="18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c"
R3_SHA256="14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100"
R4_SHA256="12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43"
REGISTRY="$REPO_ROOT/docs/port/PARAMETERS.md"

fails=0; checks=0

check() { # check <label> <expected-substring> <actual>
  local label="$1" want="$2" got="$3"
  checks=$((checks + 1))
  if [ -z "$want" ]; then
    printf 'BUG   %s — empty expectation\n' "$label"; fails=$((fails + 1)); return
  fi
  if printf '%s' "$got" | "$GREP" -qF -- "$want"; then printf 'PASS  %s\n' "$label"
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
    "$GREP" -qxF -- "$line" "$DEC" || { missing=$((missing + 1)); printf '  MISSING: %s\n' "$line"; }
  done < <("$GREP" -F -- "$want" "$R1")
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

echo "=== C-grep. the search binary every count below was produced by ==="
GREP_VERSION="$("$GREP" --version 2>&1 | head -1)"
echo "grep binary:  $GREP"
echo "grep version: $GREP_VERSION"

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

check "C-grep the search binary is an absolute /usr/bin/grep that reports a version" \
  "grep" "$GREP:$GREP_VERSION"

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
out="$("$GREP" -F "$R1_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-1 sha256: $out"
check "C1c MANIFEST.txt records the revision-1 baseline" "r60-decision-r1.md" "$out"
out="$("$GREP" -F "$R2_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-2 sha256: $out"
check "C1d MANIFEST.txt records the revision-2 baseline" "r60-decision-r2.md" "$out"
out="$("$GREP" -c "$R1_SHA256" "$RUN_DIR/review/audit-codex.r1.md")"
echo "occurrences of the revision-1 sha256 in audit-codex.r1.md: $out"
check "C1e the revision-1 auditor's own report names that hash" "count=1" "count=$out"
out="$("$GREP" -c "$R2_SHA256" "$RUN_DIR/review/audit-codex.r2.md")"
echo "occurrences of the revision-2 sha256 in audit-codex.r2.md: $out"
check "C1f the revision-2 auditor's own report names that hash" "count=1" "count=$out"
out="$(sha "$R3")"
echo "revision-3 snapshot sha256: $out"
check "C1g the revision-3 baseline is the draft audit-codex.md APPROVED" "$R3_SHA256" "$out"
out="$("$GREP" -F "$R3_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-3 sha256: $out"
check "C1h MANIFEST.txt records the revision-3 baseline" "r60-decision-r3.md" "$out"
# The revision-3 report is located BY THE HASH IT NAMES, not by a fixed file
# name. This run's controller keeps the newest report at `audit-codex.md` and
# renames the previous one to `audit-codex.rN.md` when the next audit lands, so a
# check hard-coded to either name would break exactly the way revision 2's
# `HEAD:<path>` check broke once the next revision was committed. Exactly one
# `audit-codex*.md` names the revision-3 decision hash, under either name, and
# only its basename is printed so the output stays location-independent.
out="$("$GREP" -lF "$R3_SHA256" "$RUN_DIR"/review/audit-codex*.md | wc -l | tr -d ' ')"
echo "audit reports naming the revision-3 sha256: $out"
check "C1i exactly one audit report names the revision-3 hash" "count=1" "count=$out"
R3REPORT="$("$GREP" -lF "$R3_SHA256" "$RUN_DIR"/review/audit-codex*.md | head -1)"
echo "that report is: ${R3REPORT##*/}"
check "C1i2 it is an audit-codex report" "audit-codex" "${R3REPORT##*/}"
# Revision 4 exists because of a RULING, not because of a FINDING. That is a
# checkable property of the audit report, so it is checked rather than asserted.
out="$("$GREP" -E '^verdict:' "$R3REPORT")"
echo "revision-3 audit verdict: $out"
check "C1j the revision-3 audit APPROVED, so revision 4 implements no finding" "verdict: approve" "$out"
out="$("$GREP" -E '^unresolved-findings:' "$R3REPORT")"
echo "revision-3 unresolved findings: $out"
check "C1k the revision-3 audit left no unresolved finding" "unresolved-findings: none" "$out"
out="$("$GREP" -E '^actor:' "$R3REPORT")"
echo "revision-3 audit actor: $out"
check "C1l the approving actor is the revision-3 auditor" \
  "actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r3" "$out"

echo "-- the fourth baseline: the REJECTED revision-4 text --"
# Anchored by the sha256 its own audit report names, and located by that hash
# rather than by a file name, for the reason spelled out above C1i: the
# controller renames the newest report to audit-codex.md and the previous one to
# audit-codex.rN.md, so a hard-coded name breaks at the next audit.
out="$([ -f "$R4" ] && echo present || echo MISSING)"
echo "revision-4 baseline file: $out"
check "C1m the revision-4 baseline is committed in review/evidence/" "present" "$out"
out="$(sha "$R4")"
echo "revision-4 baseline sha256: $out"
check "C1n it is the draft audit-codex.md REJECTED" "$R4_SHA256" "$out"
out="$("$GREP" -lF "$R4_SHA256" "$RUN_DIR"/review/audit-codex*.md | wc -l | tr -d ' ')"
echo "audit reports naming the revision-4 sha256: $out"
check "C1o exactly one audit report names the revision-4 hash" "count=1" "count=$out"
R4REPORT="$("$GREP" -lF "$R4_SHA256" "$RUN_DIR"/review/audit-codex*.md | head -1)"
echo "that report is: ${R4REPORT##*/}"
check "C1o2 it is an audit-codex report" "audit-codex" "${R4REPORT##*/}"
out="$("$GREP" -E '^verdict:' "$R4REPORT")"
echo "revision-4 audit verdict: $out"
check "C1p the revision-4 audit REJECTED, so revision 5 implements a finding" "verdict: reject" "$out"
out="$("$GREP" -E '^unresolved-findings:' "$R4REPORT")"
echo "revision-4 unresolved findings: $out"
check "C1p2 the finding is F1, the stale U8 provenance claim" "F1" "$out"
check "C1p3 and it names the durable owner record that falsified it" "docs/port/OWNER-REVIEW.md" "$out"
out="$("$GREP" -E '^actor:' "$R4REPORT")"
echo "revision-4 audit actor: $out"
check "C1q the rejecting actor is the revision-4 auditor" \
  "actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r4" "$out"

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
    "$GREP" -qxF -- "$line" "$DEC" || { missing=$((missing + 1)); printf '  MISSING: %s\n' "$line"; }
  done < <("$GREP" -F -- "$want" "$R2")
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
# The 2026-09-12 status line is preserved as HISTORY, not as this revision's
# position: the text immediately above it in the decision says so, and C4f below
# asserts that the refusal supersedes it. Preserving a superseded record verbatim
# and labelling it is the charter's OVERRIDE discipline; deleting it would erase
# how the choice was reached.
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
  out="$("$GREP" -F "| $name | fixed | owner | $val |" "$REGISTRY")"
  check "C3 $name = $val matches docs/port/PARAMETERS.md" "| $name | fixed | owner | $val |" "$out"
done < <("$GREP" '^- assumes ' "$DEC")
out="$("$GREP" -c '^- assumes ' "$DEC")"
echo "assumes lines in the decision: $out"
check "C3x exactly four assumes lines" "count=4" "count=$out"
out="$("$GREP" -c '^- owns ' "$DEC")"
echo "owns lines in the decision: $out"
check "C3y no owns line, because the prompt's - owns: line is empty" "count=0" "count=$out"

echo "=== C4. structural invariants ==="
out="$("$GREP" -c '^## ' "$DEC")"
echo "H2 count: $out"
check "C4a exactly four H2 sections" "count=4" "count=$out"
out="$("$GREP" '^## ' "$DEC" | tr '\n' ' ')"
echo "H2s: $out"
check "C4b they are Decision, Parameters, Empirical check, Engines in order" \
  "## Decision ## Parameters ## Empirical check ## Engines" "$out"
out="$("$GREP" -c '^## Supersedes' "$DEC")"
check "C4c no ## Supersedes section" "count=0" "count=$out"
# C4d and C4e2 were inherited from revision 3 and are RELABELLED here rather than
# dropped. Their assertions still hold and still matter — OV-01 must remain named
# and its block must remain present, because deleting a retired override would
# erase how the choice was reached — but revision 3's labels said "this decision's
# only override" and "OV-01 is declared as an override", which would print a PASS
# line contradicting a revision that declares zero. C4e (no OV-02..OV-09) and the
# zero-override assertion in the C4f family are what carry the count.
out="$("$GREP" -c 'OV-01' "$DEC")"
echo "OV-01 mentions: $out"
check "C4d OV-01 is still named, as a RETIRED override" "yes" \
  "$([ "$out" -gt 0 ] && echo yes || echo no)"
# Scoped to override DECLARATIONS, not to any mention of the string: the prose
# names OV-02..OV-09 when stating that none was invented.
out="$("$GREP" -coE 'OVERRIDE \(OV-0[2-9]\)' "$DEC")"
echo "OVERRIDE (OV-02..OV-09) declarations: $out"
check "C4e no second override was declared" "count=0" "count=$out"
out="$("$GREP" -coE 'OVERRIDE \(OV-01\)' "$DEC")"
echo "OVERRIDE (OV-01) declarations: $out"
check "C4e2 the OVERRIDE (OV-01) block is present, so the record was relabelled rather than deleted" "yes" \
  "$([ "$out" -ge 1 ] && echo yes || echo no)"
out="$("$GREP" -c 'requested, not granted' "$DEC")"
echo "'requested, not granted' occurrences (the preserved 2026-09-12 record, plus the narrative citing it): $out"
check "C4f the 2026-09-12 request is still recorded, as history" "yes" \
  "$([ "$out" -ge 1 ] && echo yes || echo no)"
out="$("$GREP" -F '**Waiver status, as of 2026-09-12: requested, not granted.**' "$DEC")"
echo "the preserved 2026-09-12 status line: $out"
check "C4f2 the 2026-09-12 status line is preserved byte-identical" \
  "**Waiver status, as of 2026-09-12: requested, not granted.**" "$out"
# Prose wraps across lines, so these assertions read the whitespace-normalized text
# rather than single lines; a line-scoped grep would fail on the wrap alone.
FLAT="$(tr '\n' ' ' < "$DEC" | tr -s ' ')"
# --- THE INVERSION. Revision 3 required the waiver to be outstanding. The owner
# --- refused it on 2026-09-14 and selected option (b), so each half of the new
# --- state is asserted here, and the 2026-09-12 record above is asserted to be
# --- labelled as superseded rather than silently left standing.
echo "-- the 2026-09-14 refusal and its consequences --"
check "C4f3 the decision records the refusal, dated" \
  "**REFUSED 2026-09-14.**" "$FLAT"
check "C4f4 it records that the owner selected option (b)" \
  "The owner declined the waiver and selected **option (b)**" "$FLAT"
check "C4f5 OV-01 is re-labelled as a RETIRED override, not deleted" \
  "**RETIRED OVERRIDE (OV-01)" "$FLAT"
check "C4f6 the decision declares ZERO overrides" \
  "**R60 declares zero overrides**" "$FLAT"
check "C4f7 and states that no SHOULD of the pinned standard is waived" \
  "no \`SHOULD\` of the pinned standard is waived" "$FLAT"
check "C4f8 the conformance record says every cited rule is satisfied with no waiver on file" \
  "every rule this decision cites is satisfied as written, with no waiver on file" "$FLAT"
check "C4f9 the superseded 2026-09-12 record is labelled as superseded" \
  "It is superseded by the refusal above and is not this revision's position" "$FLAT"
check "C4f10 the argument and options table are labelled as kept unedited" \
  "The argument and the options exactly as filed, kept unedited." "$FLAT"
# OV-01's own structure must survive its retirement: the charter asks for the
# argument and the options, and the owner chose from exactly this table.
check "C4f11 OV-01 still states its Argument" "**Argument:** R4.6" "$FLAT"
check "C4f12 OV-01 still states its Options" "**Options:**" "$FLAT"
# Revision 3 predicted that adopting (b) would rewrite "only AC2/AC3". It did not.
# Revision 4 must say so rather than work to it silently.
check "C4f13 the too-narrow 'only AC2/AC3' prediction is corrected in place" \
  "That last sentence was wrong on one clause" "$FLAT"
check "C4f14 the widening beyond AC2/AC3 is stated, not absorbed" \
  "That prediction was too narrow and this revision says so" "$FLAT"
echo "-- F267's decided mechanism is option (b), in the row and in the criteria --"
out="$("$GREP" -F '| F267 | extended `--version` |' "$DEC")"
check "C4f15 the F267 row drops Command::long_version" \
  "**No \`Command::long_version\`.**" "$out"
check "C4f16 the F267 row names the single conformant line on both spellings" \
  "\`-V\` and \`--version\` each print the single conformant line" "$out"
check "C4f17 the F267 row names the JSON path and its R4.6 permission" \
  "which R4.6 permits (\`:276-277\`)" "$out"
out="$("$GREP" -F '| AC2 |' "$DEC")"
check "C4f18 AC2 asserts -V and --version are byte-identical" \
  "produce byte-identical output" "$out"
check "C4f19 AC2 asserts the no-leading-v MUST" "no leading" "$out"
out="$("$GREP" -F '| AC3 |' "$DEC")"
check "C4f20 AC3 is the JSON version object behind the format flag" \
  "json\` emits one JSON object" "$out"
check "C4f21 AC3 omits commit and built under R4.6's MAY" \
  "\`commit\` and \`built\` are **absent**" "$out"
out="$("$GREP" -F '| AC7 |' "$DEC")"
check "C4f22 AC7 records that --version no longer travels the error path" \
  "returns through \`Ok\`" "$out"
echo "-- the R66 coupling is recorded as related, and no CONFLICT line is raised --"
check "C4f23 the R66 note is recorded as related, not a registry dependency" \
  "related (not a registry dependency)" "$FLAT"
check "C4f24 with the checked reason: R66 owns no registry parameter" \
  "**R66 owns no registry parameter.**" "$FLAT"
out="$("$GREP" -c '^CONFLICT:' "$DEC")"
echo "CONFLICT: lines in the decision: $out"
check "C4f25 no CONFLICT line is raised, because there is no parameter to conflict over" "count=0" "count=$out"
echo "-- the fired re-verify trigger is removed, and the R66 one added --"
out="$("$GREP" -F 're-verify: 2027-03-10' "$DEC")"
check "C4f26 the OV-01 re-verify trigger is marked fired and removed" \
  "has fired and is removed" "$out"
check "C4f27 the one R66 outcome that reopens F267 is a re-verify trigger" \
  "leaves no format-selection flag acceptable on the root command under any spelling" "$out"
echo "-- all six fitness gates are enumerated and answered --"
for g in \
  '**Gate 1, licence:**' \
  '**Gate 2, MSRV within the policy:**' \
  '**Gate 3, RustSec advisories' \
  '**Gate 4, builds and is tested on' \
  '**Gate 5, default features and async-runtime coupling:**' \
  '**Gate 6, binary-size and compile-time cost:**' \
; do
  check "C4f28 the closing enumeration answers $g" "$g" "$FLAT"
done
check "C4f29 the enumeration states that all six are answered" \
  "All six are answered, none is omitted, and none is answered by a bare exit status." "$FLAT"
# C4g SURVIVES THE INVERSION AND STILL MEANS SOMETHING: a REFUSAL is not a GRANT,
# so no affirmative grant claim may appear even now. Affirmative claims only — a
# bare /owner.*granted/ would match the document's own sentence saying that zero
# such claims exist, so each pattern is an assertion that the waiver WAS given,
# and non-assertive forms are excluded explicitly.
#
# 'whether' joined that exclusion list in revision 4, for a reason worth stating:
# revision 4 reports the question that was put to the owner — "whether OV-01's
# SHOULD waiver was granted" — and an interrogative is not an assertion. Excluding
# it could weaken the control, so a POSITIVE control is added immediately after:
# the same pattern set is run over synthetic text that really does claim a grant,
# and it must fire. A filter that excused everything would fail that control.
# SCANNED SENTENCE-WISE, NOT LINE-WISE, and that is a repair rather than a
# convenience: this prose is hard-wrapped, so revision 3's line-scoped scan could
# see 'waiver was granted' on one line while its 'whether' sat on the line above.
# The flattened text is split at sentence boundaries so each pattern is judged
# against the whole sentence that carries it, which is how a reader judges it.
EXCL='no such|not |never|zero|without|whether'
SENTENCES="$(tr '\n' ' ' < "$DEC" | tr -s ' ' | sed 's/\. /.\n/g')"
PATS='the owner has granted
the owner granted
owner has approved
owner approved
waiver (is|was|has been) granted
waiver granted
owner waiver record exists
approved by the owner'
echo "-- affirmative owner-approval claims (each must be absent) --"
appr=0
while IFS= read -r pat; do
  [ -z "$pat" ] && continue
  hits="$(printf '%s\n' "$SENTENCES" | "$GREP" -inE "$pat" | "$GREP" -viE "$EXCL" | wc -l | tr -d ' ')"
  printf '  %-34s %s\n' "$pat" "$hits"
  appr=$((appr + hits))
done <<< "$PATS"
echo "total affirmative owner-approval claims: $appr"
check "C4g no claim that the owner granted the waiver" "count=0" "count=$appr"
# Positive control for C4g: the same patterns, the same exclusions, over text that
# DOES claim a grant. If this comes back 0 the check above proves nothing.
CTRL="line one is filler
the owner granted the waiver on some date
the SHOULD waiver was granted
this deviation was approved by the owner"
ctrl_hits=0
while IFS= read -r pat; do
  [ -z "$pat" ] && continue
  h="$(printf '%s\n' "$CTRL" | "$GREP" -inE "$pat" | "$GREP" -viE "$EXCL" | wc -l | tr -d ' ')"
  ctrl_hits=$((ctrl_hits + h))
done <<< "$PATS"
echo "positive-control hits on synthetic grant text: $ctrl_hits"
check "C4g2 the C4g pattern set still detects a real grant claim" "positive=yes" \
  "positive=$([ "$ctrl_hits" -ge 3 ] && echo yes || echo no)"
out="$("$GREP" -c 'revision 5, 2026-09-14' "$DEC")"
echo "title lines recording revision 5: $out"
check "C4h the title records revision 5" "count=1" "count=$out"
echo "-- THE REVISION-5 REPAIR: the owner's ruling is cited, not asserted (finding F1) --"
# Revision 4 said the ruling was in no file in this repository and carried that as
# U8. The controller then wrote it into the port's durable record, which is what
# the revision-4 audit found (F1). These checks assert the repair: the two records
# are cited by path and by section, the stale paragraph is KEPT and labelled as
# corrected rather than deleted, and U8 is re-labelled RESOLVED rather than
# dropped. Every one of them reads the flattened text, because this prose wraps.
check "C4k1 the finding F1 is quoted in the revision note, not paraphrased" \
  "**F1 — stale claim that makes E13 fail.**" "$FLAT"
check "C4k2 the port's durable record is cited by path and line range" \
  "\`docs/port/OWNER-REVIEW.md:72-91\`" "$FLAT"
check "C4k3 and by its section heading, so the citation survives a line shift" \
  "### 2026-09-14 — the CLI Design Standard binds, and OV-01 is refused" "$FLAT"
check "C4k4 the planning record is cited by path and line range" \
  "\`docs/planning/p02/owner-decisions.md:261-292\`" "$FLAT"
check "C4k5 and by its section heading" \
  "## 9. Whether your CLI Design Standard binds this port -- ANSWERED 2026-09-14" "$FLAT"
check "C4k6 the stale paragraph is corrected in place rather than deleted" \
  "That whole paragraph was true when revision 4 wrote it and is false now, and" "$FLAT"
check "C4k7 the correction states plainly that the ruling IS written here" \
  "**the ruling IS written into two files in this repository**" "$FLAT"
check "C4k8 U8 is re-labelled RESOLVED and kept" \
  "**RESOLVED 2026-09-14 by revision 5, and kept on this list as the record rather than deleted.**" "$FLAT"
check "C4k9 the unproven table says which rows are still unproven" \
  "U1–U7 are unproven and are P03's to prove" "$FLAT"
# The stale sentences are PRESERVED, not removed: the charter's discipline is to
# correct a superseded record in place and label it. So the two sentences the
# audit named must still be present verbatim, with their correction beside them.
out="$("$GREP" -cF 'It is not written into any file in this repository' "$DEC")"
echo "occurrences of the revision-4 sentence the audit named: $out"
check "C4k10 the revision-4 sentence is kept verbatim as the superseded record" "count=1" "count=$out"
out="$("$GREP" -cF 'The ruling itself is not recorded in' "$DEC")"
echo "occurrences of the revision-4 Engines sentence the audit named: $out"
check "C4k11 that sentence is kept too, with its correction immediately after" "count=1" "count=$out"
check "C4k12 and the correction follows it, so neither reads as current" \
  "That last sentence was true when revision 4 wrote it and is false now" "$FLAT"
# The ruling itself is NOT re-opened. Revision 5 repairs a provenance claim; the
# override state it produced is untouched, and the C4f family above already
# asserts that state. This is the one-line statement that says so.
check "C4k13 the revision note states that the ruling is not re-opened" \
  "the owner's ruling is not re-opened" "$FLAT"
echo "-- gate 1 is recorded as inapplicable, not deleted (owner ruling 2026-09-12) --"
check "C4i the decision records gate 1 as inapplicable with the ruling as its reason" \
  "inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool" \
  "$FLAT"
out="$("$GREP" -c '^| Candidate | 1\. license' "$DEC")"
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
  review/evidence/r60-standard-pin-r5.sh \
  review/evidence/r60-standard-pin-r5.log \
  review/evidence/r60-preservation-diff-r5.sh \
  review/evidence/r60-preservation-diff-r5.log \
  review/evidence/r60-snapshot-provenance-r4.sh \
  review/evidence/r60-snapshot-provenance-r4.log \
  review/evidence/r60-standard-pin-r4.sh \
  review/evidence/r60-standard-pin-r4.log \
  review/evidence/r60-preservation-diff-r4.sh \
  review/evidence/r60-preservation-diff-r4.log \
  review/evidence/r60-decision-r4-baseline.md \
  review/evidence/r60-cli-parsing-verification.log \
  review/evidence/audit-cli-parsing-framework-r1.log \
  review/evidence/audit-cli-parsing-framework-r3.log \
  review/evidence/audit-cli-parsing-framework-r4.log \
  review/evidence/snapshots/MANIFEST.txt \
  review/evidence/snapshots/clap_builder-4.6.6-src-parser-parser.rs.txt \
  review/evidence/snapshots/r60-decision-r3.md \
; do
  out="$([ -f "$RUN_DIR/$f" ] && echo present || echo MISSING)"
  printf '  %-58s %s\n' "$f" "$out"
  check "C5c $f exists" "present" "$out"
done

echo "=== C6. every line that differs from revision 1, enumerated ==="
removed="$(diff "$R1" "$DEC" | "$GREP" -c '^<')"
added="$(diff "$R1" "$DEC" | "$GREP" -c '^>')"
printf 'revision-1 lines replaced or removed: %s\n' "$removed"
check "C6 the r1 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed" -gt 0 ] && [ "$added" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-1 lines replaced or removed ---"
diff "$R1" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C7. every line that differs from revision 2, enumerated ==="
# Revision 2 was rejected on one finding (its evidence scripts were not rerunnable
# after commit) and revision 3 also recorded gate 1 as inapplicable under the
# owner's 2026-09-12 ruling. The delta an auditor of revision 4 has to review is
# the r3 diff, C8 below.
removed2="$(diff "$R2" "$DEC" | "$GREP" -c '^<')"
added2="$(diff "$R2" "$DEC" | "$GREP" -c '^>')"
printf 'revision-2 lines replaced or removed: %s\n' "$removed2"
check "C7 the r2 diff is non-empty in both directions" "yes" \
  "$([ "$removed2" -gt 0 ] && [ "$added2" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-2 lines replaced or removed ---"
diff "$R2" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C8. every line that differs from revision 3, enumerated ==="
# This is the delta an auditor of revision 4 has to review. Revision 3 was
# APPROVED with no unresolved finding, so everything here is the owner's ruling of
# 2026-09-14 and nothing else: OV-01 retired, F267 moved to option (b), its clap
# wiring and acceptance criteria moved with it, and the R66 coupling recorded.
removed3="$(diff "$R3" "$DEC" | "$GREP" -c '^<')"
added3="$(diff "$R3" "$DEC" | "$GREP" -c '^>')"
printf 'revision-3 lines replaced or removed: %s\n' "$removed3"
check "C8 the r3 diff is non-empty in both directions" "yes" \
  "$([ "$removed3" -gt 0 ] && [ "$added3" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-3 lines replaced or removed ---"
diff "$R3" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C9. every line that differs from revision 4, enumerated ==="
# THIS is the delta an auditor of revision 5 has to review. Revision 4 was
# REJECTED on one finding, F1: its statement that the owner's ruling was not
# recorded in this repository had gone stale. Everything here is that repair and
# the evidence apparatus it required, and nothing else — no crate pin, no gate
# row, no parameter line, no acceptance criterion and no part of OV-01's argument
# or options table appears in this list.
removed4="$(diff "$R4" "$DEC" | "$GREP" -c '^<')"
added4="$(diff "$R4" "$DEC" | "$GREP" -c '^>')"
printf 'revision-4 lines replaced or removed: %s\n' "$removed4"
check "C9 the r4 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed4" -gt 0 ] && [ "$added4" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-4 lines replaced or removed ---"
diff "$R4" "$DEC" | "$GREP" '^<' | cut -c1-160

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
