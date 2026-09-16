#!/usr/bin/env bash
# R60 revision 8 — prove by diff against the committed revision-1 through
# revision-7 baselines what this revision did and did not change, and assert
# revision 8's four repairs in the decision text. This file is
# `r60-preservation-diff-r7.sh` with five regions changed;
# `r60-preservation-diff-r7.sh` is left BYTE-IDENTICAL beside it as the artifact
# the round-7 empirical audit reran and diffed.
#
# WHAT REVISION 8 CHANGED IN THIS SCRIPT, AND WHY EACH CHANGE IS LOAD-BEARING.
#
#   1. `C2a0`-`C2a3` REPLACE the four-feature preservation check, and they
#      assert a CHANGE rather than a preservation. Revisions 1 through 7 all
#      carried `preserved 'clap = { version = "4.6.6", features = ["derive",
#      "env", "string", "wrap_help"] }'`. Revision 8 removes the `string`
#      feature under finding F6, so that revision-1 line is no longer verbatim
#      and that check would now report CHANGED. Deleting it would hide the move;
#      inverting it records the move and pins both halves — the old line must be
#      ABSENT as a stack row, the new three-feature line must be PRESENT, and the
#      decision must QUOTE the superseded four-feature pin so a reader sees what
#      the owner accepted and what replaced it. THIS IS THE ONE PLACE IN EIGHT
#      REVISIONS WHERE THE RECOMMENDATION MOVES, and the script says so out loud.
#
#   2. A SEVENTH BASELINE, `r60-decision-r7-baseline.md`, the text both round-7
#      audits read (`67d7a7d2...`). Unlike the sixth, it is anchored by hash AND
#      the two round-7 reports are anchored by their own sha256 — NOT read —
#      because both still sit at live, overwritten paths: `review/audit-codex.md`
#      and `review/audit-fable.md`. That is finding F3's rule applied to a second
#      live path that did not exist when revision 7 was written.
#
#   3. `C1y`/`C1y0` EXTEND `C1x` to the judgment-audit path. Revision 7 forbade
#      `/review/audit-codex.md` on any executable line. `review/audit-fable.md`
#      is the same kind of path — the controller overwrites it with each round's
#      judgment report — and it did not exist when revision 7 was written. A
#      structural control that named only the path that had already burned this
#      item would be the instance again, so both live paths are forbidden and
#      each has its own positive control.
#
#   4. THE ROUND-6 REPORT IS NOW ASSERTED. Revision 7 stated, as a gap one
#      assertion wide, that `review/audit-codex.r6.md` did not exist when it was
#      written and that nothing in its evidence bound that report's bytes. The
#      controller has since archived it under that round name, so `C1z`-`C1z4`
#      read it at its archived path and assert its `decision-sha256:`, `verdict:`,
#      its finding F3 and its `actor:`. The gap revision 7 declared is closed by
#      revision 8 rather than carried.
#
#   5. `C4o1`-`C4o14` are new: revision 8's own repairs, one family per finding.
#      F4's corrected citations and its new script, F5's two measurable triggers
#      on the `re-verify:` line, F6's per-feature grounds and the `string`
#      removal, and F7's qualification 5 with its six-not-five correction.
#      `C4h` now requires the title to read revision 8, so
#      `r60-preservation-diff-r7.sh` run against the revision-8 text fails on
#      that check and on the four-feature preservation check. THAT FAILURE SET IS
#      MEASURED, NOT PREDICTED — see the decision's Revision-8 run section, which
#      records the observed exit status and the exact labels, because finding F3
#      rejected a predicted list.
#
# Everything below this header is revision 7's script except for those five
# regions. Its own header follows, unedited.
#
# R60 revision 7 — prove by diff against the committed revision-1, revision-2,
# revision-3, revision-4, revision-5 and revision-6 texts that what the audits
# did not challenge is unchanged, and that every changed line is in scope.
#
# WHAT REVISION 7 CHANGED IN THIS SCRIPT, AND WHY. This is
# `r60-preservation-diff-r6.sh` with every assertion about an audit report moved
# onto ARCHIVED rounds only, one new structural control, a sixth baseline and the
# usual title check moved on. The revision-6 audit rejected the draft on one
# finding, F3, quoted here verbatim from `review/audit-codex.md`:
#
#   F3 — the post-landing assertion is incomplete. `review/DECISION.md:157-159`
#   and `r60-preservation-diff-r6.sh:339-344` say that only `C1t2`, `C1u2`,
#   `C1u3`, and `C1v` fail when this report replaces the canonical round-5
#   report. The post-landing rerun instead exits `5`, with exactly five real
#   failures: those four plus `C1u`. `C1u` requires `verdict: reject`; this
#   report correctly carries `verdict: approve`, so it must fail too. Evidence:
#   `review/evidence/audit-cli-parsing-framework-r6-post-landing.log`.
#
# THE FINDING IS CORRECT, AND THE DEFECT IS STRUCTURAL RATHER THAN ARITHMETIC.
# This is the THIRD round in which this script family has been rejected for what
# it says about a report that lands AFTER it is written: round 5 rejected a
# directory wildcard (F2), round 6 rejected a post-landing failure list that was
# incomplete (F3). Both are the same mistake in two spellings. Any assertion
# about `review/audit-codex.md` — the path the controller OVERWRITES with each
# round's incoming report — is an assertion whose subject is replaced while the
# script sits committed beside the decision it supports. A script that asserts
# the CURRENT round's report is therefore wrong the moment the next report lands,
# and no list of expected post-landing failures can repair that, because the list
# itself is not knowable when the list is written.
#
# TWO MEASUREMENTS, NOT ONE, SHOW WHY THE LIST IS NOT KNOWABLE. They differ, and
# neither is wrong:
#
#   1. THE AUDITOR'S. Against a round-6 report carrying `verdict: approve` and
#      `unresolved-findings: none`, `r60-preservation-diff-r6.sh` exited 5,
#      failing C1t2, C1u, C1u2, C1u3 and C1v — the four the r6 script predicted
#      plus C1u, because C1u requires `verdict: reject`. That is F3, and its log
#      is `review/evidence/audit-cli-parsing-framework-r6-post-landing.log`.
#   2. THIS REVISION'S. The report that actually LANDED at
#      `review/audit-codex.md` carries `verdict: reject` (it is the rejection
#      that produced this revision). Rerun in place against the revision-6 text
#      on 2026-09-15, `r60-preservation-diff-r6.sh` exited 4: C1u PASSED, because
#      the incoming verdict happened to match the outgoing one, while C1t2, C1u2,
#      C1u3 and C1v failed.
#
#   So the very check F3 names passes or fails according to a verdict written by
#   someone else after the script was committed. That is the proof that the
#   failure set was never the script's to state.
#
# REVISION 7 ASSERTS ARCHIVED ROUNDS ONLY, BY EXPLICIT PATH, AND SAYS NOTHING
# ABOUT THE LIVE REPORT. The reports this script reads are
# `review/audit-codex.r1.md`, `.r2.md`, `.r3.md`, `.r4.md` and `.r5.md`: five
# files the controller writes once, under a round name, and never overwrites.
# `review/audit-codex.md` is read by NO line of this script, so nothing it
# prints and nothing it asserts changes meaning when the next report lands.
# `C1x` is the structural control that keeps it that way — no executable line of
# this file may contain the path `/review/audit-codex.md` — with `C1x0` as its
# positive control, requiring the pattern to occur in this file at all so that a
# search which had stopped working could not satisfy `C1x` by finding nothing.
#
# WHAT IS DELIBERATELY NOT ASSERTED, STATED SO THE GAP IS VISIBLE RATHER THAN
# FOUND. The round-6 report — the one carrying F3 — is not asserted by any check
# here. When this script was written it existed at exactly one path, the live
# `review/audit-codex.md`, and `review/audit-codex.r6.md` did not exist: the
# controller archives the outgoing report under its round name at the NEXT
# audit's start, which is after this script is committed. Naming a file that does
# not exist yet would fail this script's own rerun; naming the live path would be
# F3 again. So the round-6 report is quoted in this comment and in the decision,
# and asserted nowhere. The sixth baseline is anchored by its own sha256 instead
# (`C1w`/`C1w2`), which pins bytes without reading any report at all.
#
#   A SIXTH BASELINE, the rejected revision-6 text, at the sha256 its own audit
#   report names (89d888fb...), committed as `r60-decision-r6-baseline.md`.
#   `C11` enumerates the r6->r7 diff, which is the delta an auditor of revision 7
#   has to review — the same role the r5 diff played for revision 6. Like the
#   fourth and fifth baselines it is not added to `snapshots/MANIFEST.txt`, for
#   the reason spelled out below: a new MANIFEST row would change
#   `r60-snapshot-provenance-r4.sh`'s recorded totals, and that script is
#   unchanged by this revision and stays its own artifact.
#
#   `C4h` now requires the title to read revision 7, so
#   `r60-preservation-diff-r6.sh` run against the revision-7 text fails on that
#   check in addition to the four report checks measured above. That r6 script is
#   left BYTE-IDENTICAL beside this one, as the artifact the revision-6 audit ran.
#
#   `C4n` is the new family asserting revision 7's repair in the decision text.
#   `C4m10` is RELABELLED rather than dropped: the revision-6 cost sentence it
#   matches is kept in the decision as the superseded record, the way every other
#   falsified sentence in that document is kept, so the check still holds — what
#   changes is that its label no longer calls that sentence current.
#
# WHAT REVISION 6 CHANGED IN THIS SCRIPT, AND WHY. This is
# `r60-preservation-diff-r5.sh` with its report lookup rewritten, one new control
# family, a fifth baseline and the usual title check moved on. The revision-5
# audit rejected the draft on one finding, F2, quoted here verbatim from
# `review/audit-codex.md`:
#
#   **F2 — the preservation script is not insulated from untracked audit files.**
#   `r60-preservation-diff-r5.sh` claims to read committed files only. Its C1o
#   instead searches `"$RUN_DIR"/review/audit-codex*.md`. The live run already
#   contained the untracked `review/audit-codex.r4.md`, a byte-for-byte r4-audit
#   copy beside the canonical `review/audit-codex.md`. Both files contain
#   revision 4's decision hash. C1o therefore observed two matching reports,
#   failed its required one-report assertion, and made the in-place r5
#   preservation rerun exit 1 with 133 checks and one failure. The committed log
#   and decision claim exit 0 with no failures.
#
# The finding is correct. Revision 5's `C1i` and `C1o` located an audit report by
# SEARCHING the run's `review/` directory with a wildcard for whichever file
# named a given decision hash, then asserted that exactly one file matched. Two
# distinct defects follow from reading a directory instead of naming a file, and
# the audit found the first:
#
#   1. THE COUNT IS NOT THE SCRIPT'S TO CONTROL. Any extra copy of a report —
#      tracked or untracked, placed by anyone working in this shared worktree —
#      enters the match set. That is F2 as observed: an untracked byte-for-byte
#      copy of the revision-4 report sat beside the canonical one, the count came
#      back 2, the one-report assertion failed, and the in-place rerun exited 1
#      with 133 checks and one failure while the committed log recorded 133/0.
#   2. THE RESULT IS PRINTED, SO THE LOG MOVES WITH THE DIRECTORY. When the
#      revision-5 audit landed, the controller archived the revision-4 report
#      under its round name; the wildcard followed it, and the printed basename
#      changed from `audit-codex.md` to `audit-codex.r4.md`. Rerun in place on
#      2026-09-15 the r5 script therefore exited 0 with 133 checks and no
#      failures, yet its output differed from the committed log on that one
#      printed line. A passing count is not a reproducing log.
#
# REVISION 6 NAMES EVERY REPORT FILE EXPLICITLY and asserts the bytes that bind
# it: its `decision-sha256:` line, its `actor:` line and its `verdict:` line. No
# directory is searched, so a file this script does not name cannot be read and
# cannot change what it prints; and each report is now pinned to content that
# only that round's auditor wrote, so the check cannot pass by accident. `C1r`
# forbids the wildcard from coming back: it requires the pattern to occur in this
# file (so the search is demonstrably live) and requires every occurrence to sit
# on a comment line.
#
# THE ONE COST OF NAMING, STATED HERE RATHER THAN LEFT FOR AN AUDITOR, AND AT
# THE PRECISION THE OBSERVED CONVENTION SUPPORTS. The CURRENT round's report
# lives at the fixed path `review/audit-codex.md`. The controller's observed
# sequence in round 5 was: copy the outgoing report to its round name at the
# audit's start (`review/audit-codex.r4.md`, 00:01), then overwrite
# `review/audit-codex.md` with the incoming one at the audit's end (00:10). So
# `review/audit-codex.md` still binds revision 5 for the whole of a round-6
# audit and C1t-C1v pass while that audit runs; the moment the round-6 report
# LANDS, that path binds revision 6's hash instead and C1t2, C1u2, C1u3 and C1v
# fail. C1t itself does not: the file is still present at that path. That is the
# same expected historical-control failure as `C4h`'s title check, and it is why
# every superseded script in this directory is kept byte-identical beside this
# one instead of being edited. A candidate list of both possible names was
# considered and rejected: it would restore exactly the ambiguity F2 found, since
# the failure mode observed was a report present under BOTH names at once.
#
#   A FIFTH BASELINE, the rejected revision-5 text, at the sha256 its own audit
#   report names (2a665e73...), committed as `r60-decision-r5-baseline.md`.
#   `C10` enumerates the r5->r6 diff, which is the delta an auditor of revision 6
#   has to review — the same role the r4 diff played for revision 5. It is not
#   added to `snapshots/MANIFEST.txt`, for the reason spelled out for the fourth
#   baseline below: a new MANIFEST row would change
#   `r60-snapshot-provenance-r4.sh`'s recorded totals, and that script is
#   unchanged by this revision and stays its own artifact.
#
#   `C4h` now requires the title to read revision 6, so
#   `r60-preservation-diff-r5.sh` run against the revision-6 text fails on
#   exactly that check and nothing else. That r5 script is left BYTE-IDENTICAL
#   beside this one, as the artifact the revision-5 audit ran.
#
#   `C4m` is the new family asserting revision 6's repair in the decision text.
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
#
# SHELLCHECK NOTE, NEW IN REVISION 7 AND THE ONLY LINE HERE THAT IS NOT ABOUT
# FINDING F3. This repository gained a pre-commit hook on 2026-09-15 that runs
# `shellcheck` over every staged `.sh` file and fails on any finding, info level
# included. This script's expectation strings are markdown quoted from the
# decision: they contain backticks, and single-quoting them is what keeps them
# LITERAL, which is the whole point of an expectation. ShellCheck reads those
# backticks as unexpanded command substitutions and reports SC2016 fourteen
# times. The rule is suppressed file-wide rather than by rewriting the strings,
# because rewriting them would change what this script asserts.
# shellcheck disable=SC2016
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
R5="$HERE/r60-decision-r5-baseline.md"
R6="$HERE/r60-decision-r6-baseline.md"
R7="$HERE/r60-decision-r7-baseline.md"
R1_SHA256="d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c"
R2_SHA256="18769c3a522c94ee59c5635a338828781efa9c6bc8aa4e13ac9443a5773c5c2c"
R3_SHA256="14f66259aad6063f9506410735e61e9a58a026fc24200cb048b9bbc71bbc2100"
R4_SHA256="12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43"
R5_SHA256="2a665e73f5a5d93794fe49520615e204be294d156f1d537b7bafe1421c042c06"
R6_SHA256="89d888fb3a649ed7a99c895e4bc279a1afcc61438c3c41b6db8a966b6459db38"
R7_SHA256="67d7a7d2a76c7d10c88edf9cd309c46484ada95a00074d902943a94410b8b9f2"
# The two round-7 reports are pinned by their own content hashes and are NOT
# read: both still sit at live paths the controller overwrites (the empirical
# report at the path C1x forbids, the judgment report at the path C1y forbids).
# Hashing bytes is not reading a path, so these two constants carry no F3 risk;
# they exist so that a later round can prove which reports this revision answered.
R7CODEX_SHA256="065410f1949c71d8b5c37987acc809191a90a647a35350b9a7292eb6f3616b31"
R7FABLE_SHA256="7e238e0ec9924d3360d39617cd1b1b5694b87529975f57d706b9d32bcde3426b"
REGISTRY="$REPO_ROOT/docs/port/PARAMETERS.md"

# Every audit report this script reads is named here, explicitly and relatively,
# and every one of them is an ARCHIVED round: a file the controller writes once
# under its round name and never overwrites. Nothing below searches a directory
# for a report, and nothing below reads the live `review/audit-codex.md`, whose
# bytes are replaced by each incoming round. See the revision-7 header note.
R1REPORT="$RUN_DIR/review/audit-codex.r1.md"
R2REPORT="$RUN_DIR/review/audit-codex.r2.md"
R3REPORT="$RUN_DIR/review/audit-codex.r3.md"
R4REPORT="$RUN_DIR/review/audit-codex.r4.md"
R5REPORT="$RUN_DIR/review/audit-codex.r5.md"
R6REPORT="$RUN_DIR/review/audit-codex.r6.md"
SELF="$HERE/$(basename "${BASH_SOURCE[0]}")"

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
out="$("$GREP" -c "$R1_SHA256" "$R1REPORT")"
echo "occurrences of the revision-1 sha256 in audit-codex.r1.md: $out"
check "C1e the revision-1 auditor's own report names that hash" "count=1" "count=$out"
out="$("$GREP" -c "$R2_SHA256" "$R2REPORT")"
echo "occurrences of the revision-2 sha256 in audit-codex.r2.md: $out"
check "C1f the revision-2 auditor's own report names that hash" "count=1" "count=$out"
out="$(sha "$R3")"
echo "revision-3 snapshot sha256: $out"
check "C1g the revision-3 baseline is the draft audit-codex.md APPROVED" "$R3_SHA256" "$out"
out="$("$GREP" -F "$R3_SHA256" "$SNAP/MANIFEST.txt" | cut -d'|' -f2)"
echo "MANIFEST row naming the revision-3 sha256: $out"
check "C1h MANIFEST.txt records the revision-3 baseline" "r60-decision-r3.md" "$out"
# THE REVISION-3 REPORT IS NAMED, NOT SEARCHED FOR. Revision 5 located it by
# searching the review directory for whichever file carried the revision-3 hash
# and required exactly one match. That is the defect finding F2 named, and it is
# the defect this check carried too — its count came back 1 by luck of timing,
# not by construction. The report has been archived under its round name since
# the revision-4 audit landed and does not move again, so it is named directly
# and pinned to the three header lines only its own auditor wrote.
out="$([ -f "$R3REPORT" ] && echo present || echo MISSING)"
echo "revision-3 audit report at review/audit-codex.r3.md: $out"
check "C1i the revision-3 audit report is at its archived name" "present" "$out"
out="$("$GREP" -E '^decision-sha256:' "$R3REPORT")"
echo "the hash that report binds: $out"
check "C1i2 it binds the revision-3 decision hash" "decision-sha256: $R3_SHA256" "$out"
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
# The baseline file is anchored by the sha256 its own audit report names. The
# report itself is NAMED — `review/audit-codex.r4.md`, where the controller
# archived it when the revision-5 audit landed — and pinned to its own header
# lines. This is the exact check finding F2 rejected: revision 5 searched for it
# instead, an untracked duplicate entered the match set, and the in-place rerun
# exited 1. See the revision-6 header note for the full quotation.
out="$([ -f "$R4" ] && echo present || echo MISSING)"
echo "revision-4 baseline file: $out"
check "C1m the revision-4 baseline is committed in review/evidence/" "present" "$out"
out="$(sha "$R4")"
echo "revision-4 baseline sha256: $out"
check "C1n it is the draft the revision-4 audit REJECTED" "$R4_SHA256" "$out"
out="$([ -f "$R4REPORT" ] && echo present || echo MISSING)"
echo "revision-4 audit report at review/audit-codex.r4.md: $out"
check "C1o the revision-4 audit report is at its archived name" "present" "$out"
out="$("$GREP" -E '^decision-sha256:' "$R4REPORT")"
echo "the hash that report binds: $out"
check "C1o2 it binds the revision-4 decision hash" "decision-sha256: $R4_SHA256" "$out"
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

echo "-- the fifth baseline: the REJECTED revision-5 text, and the report that rejected it --"
# REVISION 7 MOVES THIS FAMILY OFF THE LIVE PATH. Revision 6 read the round-5
# report at `review/audit-codex.md`, the convention path the controller
# OVERWRITES with each incoming report, and stated which of these checks would
# fail once the round-6 report landed. Finding F3 rejected that statement, and
# the two measurements in the header show the list was not knowable when it was
# written. The round-5 report has since been archived under its round name,
# `review/audit-codex.r5.md`, where it is written once and never overwritten, so
# it is read there. Every assertion below therefore keeps its meaning when the
# next report lands, and the next, because no incoming report can reach any file
# this family names.
out="$([ -f "$R5" ] && echo present || echo MISSING)"
echo "revision-5 baseline file: $out"
check "C1s the revision-5 baseline is committed in review/evidence/" "present" "$out"
out="$(sha "$R5")"
echo "revision-5 baseline sha256: $out"
check "C1s2 it is the draft the revision-5 audit REJECTED" "$R5_SHA256" "$out"
out="$([ -f "$R5REPORT" ] && echo present || echo MISSING)"
echo "revision-5 audit report at review/audit-codex.r5.md: $out"
check "C1t the revision-5 audit report is at its archived name" "present" "$out"
out="$("$GREP" -E '^decision-sha256:' "$R5REPORT")"
echo "the hash that report binds: $out"
check "C1t2 it binds the revision-5 decision hash" "decision-sha256: $R5_SHA256" "$out"
out="$("$GREP" -E '^verdict:' "$R5REPORT")"
echo "revision-5 audit verdict: $out"
check "C1u the revision-5 audit REJECTED, so revision 6 implements a finding" "verdict: reject" "$out"
out="$("$GREP" -E '^unresolved-findings:' "$R5REPORT")"
echo "revision-5 unresolved findings: $out"
check "C1u2 the finding is F2" "F2" "$out"
check "C1u3 and it names the script whose lookup it rejected" "r60-preservation-diff-r5.sh" "$out"
out="$("$GREP" -E '^actor:' "$R5REPORT")"
echo "revision-5 audit actor: $out"
check "C1v the rejecting actor is the revision-5 auditor" \
  "actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r5" "$out"

echo "-- the sixth baseline: the REJECTED revision-6 text, anchored by hash alone --"
# NO REPORT IS READ FOR THIS BASELINE, AND THAT IS THE POINT. The round-6 report
# is the one that carries finding F3. When this script was written it existed at
# exactly one path — the live `review/audit-codex.md` — and
# `review/audit-codex.r6.md` did not exist, because the controller archives the
# outgoing report under its round name at the NEXT audit's start. Naming the
# archive path would fail this script's own rerun today; naming the live path
# would be F3 again. So this baseline is pinned by its own sha256, which fixes
# bytes without reading any report, and the round-6 report is quoted in this
# script's header and in the decision instead of being asserted anywhere.
out="$([ -f "$R6" ] && echo present || echo MISSING)"
echo "revision-6 baseline file: $out"
check "C1w the revision-6 baseline is committed in review/evidence/" "present" "$out"
out="$(sha "$R6")"
echo "revision-6 baseline sha256: $out"
check "C1w2 it is the draft the revision-6 audit REJECTED" "$R6_SHA256" "$out"

echo "-- C1z. the ROUND-6 REPORT, now archived: the gap revision 7 declared, closed --"
# Revision 7 stated plainly that nothing in its evidence bound the round-6
# report's bytes, because that report existed only at the live path C1x forbids.
# The controller has since archived it under its round name, which the controller
# writes once and never overwrites, so revision 8 asserts it the way every other
# archived round is asserted — at a named path, against lines only that round's
# auditor wrote.
out="$([ -f "$R6REPORT" ] && echo present || echo MISSING)"
echo "round-6 audit report at its archived name: $out"
check "C1z the revision-6 audit report is at its archived name" "present" "$out"
out="$(sed -n '1p' "$R6REPORT")"
echo "$out"
check "C1z2 it binds the revision-6 decision hash" "decision-sha256: $R6_SHA256" "$out"
out="$(sed -n '5p' "$R6REPORT")"
echo "$out"
check "C1z3 the revision-6 audit REJECTED, so revision 7 implements a finding" "verdict: reject" "$out"
out="$(sed -n '6p' "$R6REPORT")"
echo "$out"
check "C1z4 the finding is F3, the incomplete post-landing list" "F3" "$out"
out="$(sed -n '2p' "$R6REPORT")"
echo "$out"
check "C1z5 the rejecting actor is the revision-6 auditor" \
  "actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r6" "$out"

echo "-- the seventh baseline: the ACCEPTED-AND-THEN-REJECTED revision-7 text --"
# Revision 7 was APPROVED by the round-7 empirical audit and REJECTED by the
# round-7 judgment audit, the item's first. Both reports are at live paths this
# script must not read, so the baseline text is anchored by its own sha256 and
# each report by its own — bytes pinned, no path read.
out="$([ -f "$R7" ] && echo present || echo MISSING)"
echo "revision-7 baseline file: $out"
check "C1w3 the revision-7 baseline is committed in review/evidence/" "present" "$out"
out="$(sha "$R7")"
echo "revision-7 baseline sha256: $out"
check "C1w4 it is the draft both round-7 audits bound" "$R7_SHA256" "$out"
echo "round-7 empirical report sha256 (pinned, not read): $R7CODEX_SHA256"
echo "round-7 judgment  report sha256 (pinned, not read): $R7FABLE_SHA256"
check "C1w5 the two round-7 report hashes are distinct, so two reports are pinned" "distinct=yes" \
  "distinct=$([ "$R7CODEX_SHA256" != "$R7FABLE_SHA256" ] && echo yes || echo no)"

echo "-- C1x. no line of this script reads the live, overwritten report path --"
# THE STRUCTURAL CONTROL FINDING F3 ASKS FOR. `review/audit-codex.md` is the one
# path in this run whose BYTES are replaced by whoever audits next. If no
# executable line of this script contains that path, then nothing this script
# asserts and nothing it prints can change when the next report lands — which is
# the property F3 found missing, stated as a check rather than as a promise. The
# pattern is the PATH form, with its leading slash: the decision's prose quotes
# the bare name inside backticks (`review/audit-codex.md`), and those quotations
# appear as expectation strings on executable lines of the C4m family below,
# where they are text this script searches FOR, not a file this script reads.
# C1x0 keeps C1x from passing vacuously: the path form must occur somewhere in
# this file — it occurs on the next comment line, and in the header note — so a
# search that had stopped working would fail the control instead of satisfying
# the check. The form a file read takes here is "$RUN_DIR/review/audit-codex.md",
# and that is the string neither this line nor any other may put into code.
live_all="$("$GREP" -c '/review/audit-codex\.md' "$SELF")"
live_code="$("$GREP" -n '/review/audit-codex\.md' "$SELF" | "$GREP" -vc ':[[:space:]]*#')"
echo "occurrences of the live report PATH anywhere in this script: $live_all"
echo "of those, occurrences on a non-comment line: $live_code"
check "C1x0 the live-path search is live: the pattern does occur in this file" "live=yes" \
  "live=$([ "$live_all" -ge 1 ] && echo yes || echo no)"
check "C1x no executable line of this script reads the live report path" "count=0" "count=$live_code"

echo "-- C1r. this script names its inputs: no audit-report wildcard survives --"
# F2 named a CLASS of defect, not one instance, so its absence is checked rather
# than promised. The wildcard appears above in the quotation of F2 itself, which
# is what makes this search demonstrably live: C1r0 requires the pattern to be
# found somewhere in this file, and C1r requires every occurrence of it to sit on
# a comment line. A regression that reintroduced a directory search on an
# executable line would fail C1r; a regression that broke the search itself —
# leaving C1r trivially satisfied by finding nothing — would fail C1r0.
glob_all="$("$GREP" -c 'audit-codex\*' "$SELF")"
glob_code="$("$GREP" -n 'audit-codex\*' "$SELF" | "$GREP" -vc ':[[:space:]]*#')"
echo "occurrences of an audit-codex wildcard anywhere in this script: $glob_all"
echo "of those, occurrences on a non-comment line: $glob_code"
check "C1r0 the wildcard search is live: the pattern does occur in this file" "live=yes" \
  "live=$([ "$glob_all" -ge 1 ] && echo yes || echo no)"
check "C1r no executable line in this script reads an audit-codex wildcard" "count=0" "count=$glob_code"

echo "-- C1y. the SECOND live path: the judgment report, forbidden the same way --"
# THE CLASS, EXTENDED. `review/audit-fable.md` is the path the controller
# overwrites with each round's JUDGMENT report, exactly as it overwrites
# `review/audit-codex.md` with each round's empirical report. It did not exist
# when revision 7 wrote C1x, so C1x names only the path that had already burned
# this item three times. A control that covers one live path and not the other is
# the instance again, which is precisely what findings F2 and F3 rejected. Both
# are forbidden here, each with its own positive control so a search that had
# stopped working fails the control instead of satisfying the check. The pattern
# is the PATH form with its leading slash — /review/audit-fable.md — which
# occurs on this comment line and nowhere executable, and that is exactly what
# C1y0 requires and C1y forbids.
fable_all="$("$GREP" -c '/review/audit-fable\.md' "$SELF")"
fable_code="$("$GREP" -n '/review/audit-fable\.md' "$SELF" | "$GREP" -vc ':[[:space:]]*#')"
echo "occurrences of the live judgment-report PATH anywhere in this script: $fable_all"
echo "of those, occurrences on a non-comment line: $fable_code"
check "C1y0 the judgment-path search is live: the pattern does occur in this file" "live=yes" \
  "live=$([ "$fable_all" -ge 1 ] && echo yes || echo no)"
check "C1y no executable line of this script reads the live judgment-report path" "count=0" "count=$fable_code"

echo "=== C2. what the audits did NOT challenge is byte-identical ==="
echo "-- the recommended crate and feature set: ONE DELIBERATE CHANGE, asserted as one --"
# THIS IS THE ONLY PLACE IN EIGHT REVISIONS WHERE THE RECOMMENDATION MOVES.
# Revisions 1 through 7 recommended four clap features and this script's ancestor
# asserted that the revision-1 stack row was still verbatim. Finding F6 found
# `string` supported by adopter agreement alone, with the raw report's two stated
# reasons — a runtime-built `long_version` and a `mut_args` post-pass — removed
# by this decision's own later rulings (option (b) and R5.4). Revision 8 drops
# the feature. The preservation check is therefore INVERTED rather than deleted:
# deleting it would let the move pass unremarked, which is what a preservation
# apparatus exists to prevent. All four halves are asserted.
r1_pin='clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }'
r8_pin='clap = { version = "4.6.6", features = ["derive", "env", "wrap_help"] }'
flat_dec="$(tr '\n' ' ' < "$DEC" | tr -s ' ')"
out="$("$GREP" -cF -- "$r1_pin" "$R1")"
echo "revision-1 lines carrying the four-feature pin: $out"
check "C2a0 the four-feature pin really was revision 1's, so this check is not vacuous" "count=1" "count=$out"
# -F, not a pattern: the pin contains `[`, `{` and `}`, which a basic regular
# expression reads as a bracket expression and an interval. An early draft of
# this check used them unescaped, so C2a1 passed by matching nothing — a check
# that cannot fail is not evidence, and it took C2a2's failure to surface it.
out="$("$GREP" -cF -- "| Argument parser | \`$r1_pin\`" "$DEC" || true)"
echo "revision-8 stack rows still carrying the four-feature pin: $out"
check "C2a1 the four-feature pin is no longer the stack row — the feature set MOVED" "count=0" "count=$out"
out="$("$GREP" -cF -- "| Argument parser | \`$r8_pin\`" "$DEC" || true)"
echo "revision-8 stack rows carrying the three-feature pin: $out"
check "C2a2 the stack row now names exactly derive, env and wrap_help" "count=1" "count=$out"
# The control that keeps C2a1's zero from being vacuous: the same -F search must
# find the four-feature pin in the revision-1 baseline, where it IS a stack row.
out="$("$GREP" -cF -- "| Argument parser | \`$r1_pin\`" "$R1" || true)"
echo "revision-1 stack rows carrying the four-feature pin: $out"
check "C2a1x the -F search works: it finds that row in the revision-1 baseline" "count=1" "count=$out"
check "C2a3 the superseded four-feature pin is QUOTED in the text, so the move is visible" \
  "$r1_pin" "$flat_dec"
check "C2a4 and the decision says in terms that the owner is re-asked, not re-bound" \
  "this revision does not re-bind the acceptance; the owner is asked again" "$flat_dec"
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
out="$("$GREP" -c 'revision 8, 2026-09-16' "$DEC")"
echo "title lines recording revision 8: $out"
check "C4h the title records revision 8" "count=1" "count=$out"
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
# C4k9's expectation MOVED IN REVISION 8 and is updated rather than dropped.
# Revision 5 wrote it to assert that the unproven table names which rows remain
# unproven after U8 was resolved; revision 8 adds U9 for gate 2's unread CI half,
# so the sentence now reads "U1-U7 and the new U9". The assertion is the same
# assertion — the table states its own live set — and the decision keeps the old
# wording quoted beside the new one, which C4o28 requires.
check "C4k9 the unproven table says which rows are still unproven" \
  "U1–U7 and the new U9 are unproven and are P03's to prove" "$FLAT"
check "C4o28 and the superseded U1–U7 wording is kept and labelled, not silently replaced" \
  "Revisions 1 through 7 said \"U1–U7 are unproven\"; that count is corrected" "$FLAT"
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
echo "-- THE REVISION-6 REPAIR: the report lookup, and the claim it falsified (finding F2) --"
# Revision 5 said its two offline scripts "read only files committed in this
# repository". The preservation script's report lookup searched a directory
# instead, so an untracked copy could enter it — and did. These checks assert the
# repair in the decision text: F2 is quoted rather than paraphrased, BOTH in-place
# observations are recorded with their numbers, the false sentence is kept and
# corrected in place rather than deleted, and the new script's own cost is stated.
check "C4m1 the finding F2 is quoted in the revision note, not paraphrased" \
  "**F2 — the preservation script is not insulated from untracked audit files.**" "$FLAT"
check "C4m2 the repaired script is named" \
  "r60-preservation-diff-r6.sh" "$FLAT"
check "C4m3 the rejected script is kept byte-identical as the audited artifact" \
  "is left byte-identical as the artifact the revision-5 audit ran" "$FLAT"
check "C4m4 the auditor's in-place result is recorded with its numbers" \
  "exited \`1\` with 133 checks and one failure" "$FLAT"
check "C4m5 the second in-place observation, the moving printed name, is recorded" \
  "the printed basename changed from \`audit-codex.md\` to \`audit-codex.r4.md\`" "$FLAT"
# Read from the flattened text: this prose is hard-wrapped, and the sentence in
# question breaks across a line, so a line-scoped search would miss it.
check "C4m6 the falsified reproducibility sentence is kept verbatim as the superseded record" \
  "read only files committed in this repository and make no network call" "$FLAT"
check "C4m7 and its correction follows it, so it does not read as current" \
  "That sentence was true of \`r60-standard-pin-r5.sh\` and false of" "$FLAT"
out="$("$GREP" -cF '| `r60-preservation-diff-r5.sh` | `r60-preservation-diff-r5.log` | exit `0`, `CHECKS RUN: 133   FAILURES: 0`' "$DEC")"
echo "occurrences of the revision-5 results-table row the audit falsified: $out"
check "C4m8 the revision-5 results row is kept rather than rewritten" "count=1" "count=$out"
check "C4m9 the beyond-brief correction is reported: C1i carried the same defect" \
  "\`C1i\` carried the identical defect" "$FLAT"
# C4m10 IS RELABELLED, NOT DROPPED. Revision 6 stated this cost as a prediction
# about the round-6 report; finding F3 falsified the prediction. The sentence is
# kept in the decision as the superseded record — the practice this document
# applies to every falsified sentence — with its correction beside it, so the
# check still holds and only the label moves off the present tense.
check "C4m10 the revision-6 cost sentence is kept verbatim as the superseded record" \
  "will fail once the round-6 audit lands and \`review/audit-codex.md\` binds revision 6's hash instead" "$FLAT"
check "C4m11 the revision note states revision 6's scope" \
  "revision 6's scope is finding F2 and the evidence apparatus it names, and nothing else" "$FLAT"
echo "-- THE REVISION-7 REPAIR: assertions about audit reports cover archived rounds only (finding F3) --"
# Revision 6 asserted the CURRENT round's report and stated which of those
# assertions would fail once the next report landed. The statement was incomplete,
# and the two measurements recorded in this script's header show that no such
# statement could have been complete. These checks assert the repair in the
# decision text: F3 is quoted rather than paraphrased, the defect is named as
# structural and as the third round of the same mistake, the new invariance
# property is stated, BOTH post-landing measurements are recorded with their
# numbers and with what produced each, the falsified sentence is kept and
# corrected in place rather than deleted, and what this script deliberately does
# not assert is stated rather than left for an auditor to discover.
check "C4n1 the finding F3 is quoted in the revision note, not paraphrased" \
  "F3 — the post-landing assertion is incomplete." "$FLAT"
check "C4n2 the repaired script is named" \
  "r60-preservation-diff-r7.sh" "$FLAT"
check "C4n3 the rejected script is kept byte-identical as the audited artifact" \
  "\`r60-preservation-diff-r6.sh\` is left byte-identical" "$FLAT"
check "C4n4 the defect is recorded as structural and as the third round of the same mistake" \
  "the third round in which this decision's preservation script has been rejected" "$FLAT"
check "C4n5 the new invariance property is stated: archived rounds only, live report never" \
  "asserts only archived audit reports, by explicit path, and reads the live \`review/audit-codex.md\` nowhere" "$FLAT"
check "C4n6 the auditor's post-landing measurement is recorded with its numbers" \
  "exited \`5\`, failing \`C1t2\`, \`C1u\`, \`C1u2\`, \`C1u3\` and \`C1v\`" "$FLAT"
check "C4n7 and what produced it: a draft report carrying verdict approve" \
  "Against a round-6 report carrying \`verdict: approve\`" "$FLAT"
check "C4n8 this revision's own measurement against the landed report is recorded" \
  "exited \`4\`: \`C1u\` passed" "$FLAT"
check "C4n9 the conclusion the two measurements support is stated" \
  "the failure set was never the script's to state" "$FLAT"
check "C4n10 the falsified post-landing sentence is kept verbatim with its correction beside it" \
  "kept here verbatim as the record of what revision 6 predicted, and corrected immediately below" "$FLAT"
check "C4n11 what this script does NOT assert is stated: the round-6 report itself" \
  "the round-6 report is asserted by no check in \`r60-preservation-diff-r7.sh\`" "$FLAT"
check "C4n12 with the reason it is not, so the gap is visible rather than found" \
  "\`review/audit-codex.r6.md\` did not exist when that script was written" "$FLAT"
check "C4n13 the revision note states revision 7's scope" \
  "revision 7's scope is finding F3 and the evidence apparatus it names, and nothing else" "$FLAT"

echo "-- THE REVISION-8 REPAIRS: the first judgment audit's four findings (F4-F7) --"
# One family, four findings, and the only revision in this item's history whose
# repairs reach the recommendation. Each check names the finding it discharges.
check "C4o1 finding F4 is quoted in the revision note by its label, not paraphrased" \
  "F4 — row E5's \"every other standard line this decision cites\" verifies twelve" "$FLAT"
# Each expectation below stays inside ONE source line of the document. This
# prose is hard-wrapped and the findings are quoted as blockquotes, so a
# flattened search for text spanning a wrap would have to match the "> " marker
# the next line begins with; an expectation that crossed a wrap failed here
# before this note was written.
check "C4o2 finding F5 is quoted by its label" \
  "F5 — the \`bpaf\` promotion condition is unmeasurable and is not on the" "$FLAT"
check "C4o3 finding F6 is quoted by its label" \
  "F6 — two of the four clap features are carried by adopter agreement" "$FLAT"
check "C4o4 finding F7 is quoted by its label" \
  "F7 — gate 2 is read as a bar for exclusions and as a declaration check for" "$FLAT"
check "C4o5 the revision note states up front that the recommendation moves" \
  "THE RECOMMENDATION MOVES, in exactly one place" "$FLAT"
check "C4o6 and cites the acceptance rule that makes it a re-ask rather than a re-bind" \
  "docs/port/OWNER-ACCEPTANCES.md:55" "$FLAT"
check "C4o7 both round-7 verdicts are recorded, approve on evidence and reject on judgment" \
  "**approved** on evidence" "$FLAT"
# F4: the three corrected citations, each with the wrong number kept and named.
check "C4o8 F4 — R9.1's shells quote is corrected from :483 to :484, the wrong number named" \
  "revisions 1-7 cited \`:483\`, which is R9.1's heading and names no shell" "$FLAT"
check "C4o9 F4 — R4.5's -o/--output spelling is corrected from :270 to :271" \
  "revisions 1 through 7 cited the \`:270\` heading" "$FLAT"
check "C4o10 F4 — R9.3's range is tightened from :491-493 to :492" \
  "whose first line is R9.3's heading and whose last is blank" "$FLAT"
check "C4o11 F4 — the new body-reading script is named in the decision" \
  "standard-lines-r8.sh" "$FLAT"
check "C4o12 F4 — row E5's scope is restated to the twelve specs C8 actually reads" \
  "\`C8\` carries exactly **twelve** \`<line>|<expected>\` specs and no more" "$FLAT"
# F5: two measurable triggers, and they are on the re-verify line itself.
REV="$("$GREP" -m1 '^re-verify: ' "$DEC")"
echo "re-verify line length (characters): ${#REV}"
check "C4o13 F5 — the cadence trigger is ON the re-verify line, with its date" \
  "no \`clap\` release published by 2027-02-06" "$REV"
check "C4o14 F5 — the compile-time trigger is ON the re-verify line, with its method" \
  "cargo build --timings" "$REV"
check "C4o15 F5 — the unmeasurable sentence is kept and corrected rather than deleted" \
  "The sentence immediately above is kept where it stands and corrected here" "$FLAT"
# F6: a ground per feature, and the removal.
check "C4o16 F6 — the per-feature grounding subsection exists" \
  "WHY EACH CLAP FEATURE IS IN THE SET" "$FLAT"
check "C4o17 F6 — wrap_help is grounded in R7.3's rule body at :390, not in adopter manifests" \
  "R7.3 \`(SHOULD)\` at \`:390\`" "$FLAT"
check "C4o18 F6 — string's two dropped reasons are named and their removals cited" \
  "long_version\` built at runtime, and a \`mut_args\` post-pass" "$FLAT"
check "C4o19 F6 — the removal is stated plainly" \
  "no requirement of this template needs \`string\`, and the feature is dropped" "$FLAT"
check "C4o20 F6 — the clap-minimal benchmark row is added to qualification 3" \
  "377 KiB" "$FLAT"
check "C4o21 F6 — cited to the raw report by file and line range" \
  "(\`raw/opus.md:209-215\`, retrieved 2026-09-10)" "$FLAT"
check "C4o21b F6 — with the limit stated: no log in this run carries that row" \
  "**No log in this run carries it**" "$FLAT"
# F7: qualification 5, its six candidates, and U9.
check "C4o22 F7 — qualification 5 carries gate 2's unread CI half" \
  "Gate 2, the half of the policy this run did not read" "$FLAT"
check "C4o23 F7 — in the same words qualification 2 uses for gate 4" \
  "**No CI configuration was read in this run**" "$FLAT"
check "C4o24 F7 — it says the unread half cannot overturn an exclusion" \
  "a missing declaration fails a both-halves gate regardless" "$FLAT"
check "C4o25 F7 — the six-not-five correction is reported rather than made quietly" \
  "the round-7 judgment audit names **five** candidates passed on the declaration" "$FLAT"
out="$("$GREP" -c '^| U9 |' "$DEC")"
echo "U9 rows in the unproven table: $out"
check "C4o26 F7 — U9 is added to the unproven table" "count=1" "count=$out"
check "C4o27 the qualification count is corrected from four to five rather than left stale" \
  "**Five** qualifications on that table" "$FLAT"
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
  review/evidence/standard-lines-r8.sh \
  review/evidence/standard-lines-r8.log \
  review/evidence/r60-feature-ground-r8.sh \
  review/evidence/r60-feature-ground-r8.log \
  review/evidence/r60-preservation-diff-r8.sh \
  review/evidence/r60-preservation-diff-r8.log \
  review/evidence/r60-decision-r7-baseline.md \
  review/evidence/audit-cli-parsing-framework-r7.log \
  review/audit-codex.r6.md \
  review/evidence/snapshots/clap_derive-4.6.4-src-item.rs.txt \
  review/evidence/snapshots/clap_builder-4.6.6-src-builder-command.rs.txt \
  review/evidence/r60-standard-pin-r5.sh \
  review/evidence/r60-standard-pin-r5.log \
  review/evidence/r60-preservation-diff-r7.sh \
  review/evidence/r60-preservation-diff-r7.log \
  review/evidence/r60-decision-r6-baseline.md \
  review/evidence/audit-cli-parsing-framework-r6.log \
  review/evidence/audit-cli-parsing-framework-r6-post-landing.log \
  review/audit-codex.r5.md \
  review/evidence/r60-preservation-diff-r6.sh \
  review/evidence/r60-preservation-diff-r6.log \
  review/evidence/r60-decision-r5-baseline.md \
  review/evidence/audit-cli-parsing-framework-r5.log \
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
# Revision 4 was REJECTED on one finding, F1: its statement that the owner's
# ruling was not recorded in this repository had gone stale. This list is that
# repair plus revision 6's, since the current text is revision 6 — no crate pin,
# no gate row, no parameter line, no acceptance criterion and no part of OV-01's
# argument or options table appears in it. The delta an auditor of revision 6 has
# to review on its own is C10 below.
removed4="$(diff "$R4" "$DEC" | "$GREP" -c '^<')"
added4="$(diff "$R4" "$DEC" | "$GREP" -c '^>')"
printf 'revision-4 lines replaced or removed: %s\n' "$removed4"
check "C9 the r4 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed4" -gt 0 ] && [ "$added4" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-4 lines replaced or removed ---"
diff "$R4" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C10. every line that differs from revision 5, enumerated ==="
# THIS is the delta an auditor of revision 6 has to review. Revision 5 was
# REJECTED on one finding, F2: its preservation script located audit reports by
# searching a directory, so an untracked copy entered the match set and the
# in-place rerun did not reproduce. Everything here is that repair and the
# corrections to the claims it falsified, and nothing else — no crate pin, no
# gate row, no parameter line, no acceptance criterion, no part of OV-01's
# argument or options table, and nothing about the owner's ruling.
removed5="$(diff "$R5" "$DEC" | "$GREP" -c '^<')"
added5="$(diff "$R5" "$DEC" | "$GREP" -c '^>')"
printf 'revision-5 lines replaced or removed: %s\n' "$removed5"
check "C10 the r5 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed5" -gt 0 ] && [ "$added5" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-5 lines replaced or removed ---"
diff "$R5" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C11. every line that differs from revision 6, enumerated ==="
# THIS is the delta an auditor of revision 7 has to review. Revision 6 was
# REJECTED on one finding, F3: its preservation script asserted the CURRENT
# round's audit report and stated an incomplete list of the checks that would
# fail once the next report landed. Everything here is that repair and the
# corrections to the claims it falsified, and nothing else — no crate pin, no
# gate row, no parameter line, no acceptance criterion, no part of OV-01's
# argument or options table, and nothing about the owner's ruling.
removed6="$(diff "$R6" "$DEC" | "$GREP" -c '^<')"
added6="$(diff "$R6" "$DEC" | "$GREP" -c '^>')"
printf 'revision-6 lines replaced or removed: %s\n' "$removed6"
check "C11 the r6 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed6" -gt 0 ] && [ "$added6" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-6 lines replaced or removed ---"
diff "$R6" "$DEC" | "$GREP" '^<' | cut -c1-160

echo "=== C12. every line that differs from revision 7, enumerated ==="
# THIS is the delta an auditor of revision 8 has to review. Revision 7 was
# APPROVED on evidence and REJECTED on judgment, on four findings — F4 through
# F7 — and everything here is those four repairs. Read this diff with one thing
# in mind that is true of no earlier delta in this item: it contains a change to
# the RECOMMENDATION. The `string` feature leaves the stack table, which re-asks
# the owner rather than re-binding the acceptance he gave at revision 7's hash.
# Everything else is citation corrections, two measurable re-verify triggers, a
# per-feature grounding subsection, a fifth qualification and a ninth unproven
# row. No crate, no version, no gate verdict, no parameter line, no acceptance
# criterion and no part of OV-01's record moves.
removed7="$(diff "$R7" "$DEC" | "$GREP" -c '^<')"
added7="$(diff "$R7" "$DEC" | "$GREP" -c '^>')"
printf 'revision-7 lines replaced or removed: %s\n' "$removed7"
check "C12 the r7 diff is non-empty in both directions, so the revision landed" "yes" \
  "$([ "$removed7" -gt 0 ] && [ "$added7" -gt 0 ] && echo yes || echo no)"
echo "--- full list of revision-7 lines replaced or removed ---"
diff "$R7" "$DEC" | "$GREP" '^<' | cut -c1-160

echo
printf 'CHECKS RUN: %d   FAILURES: %d\n' "$checks" "$fails"
if [ "$fails" -eq 0 ]; then echo "RESULT: all checks passed"; else echo "RESULT: FAILED"; fi
exit "$fails"
