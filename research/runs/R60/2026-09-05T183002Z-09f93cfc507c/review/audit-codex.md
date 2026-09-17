decision-sha256: 16d2db72028bc368e0f857e2a168d488d40dffdbea78b99b01519d02dd120651
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r9
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash review/evidence/r60-preservation-diff-r7.sh`; cwd: this run directory and a `.git`-free full-repository `git archive 7d501e1` extraction; toolchain: Bash with `/usr/bin/grep`; exit: `2`; log: `review/evidence/r60-preservation-diff-r7-against-r9.log`. Both runs report `CHECKS RUN: 183   FAILURES: 2`, with only the changed four-feature pin and `C4h` failing. `C4k9` passes.
- argv: `bash review/evidence/r60-preservation-diff-r8.sh`; same two cwd modes and toolchain; exit: `1`; log: `review/evidence/r60-preservation-diff-r8-against-r9.log`. Both runs report `CHECKS RUN: 239   FAILURES: 1`, with `C4h` alone failing. `C4k9` and `C4o28` pass.
- The two preservation logs match each rerun byte-for-byte after the wrapper appends the recorded `EXIT STATUS` line. `standard-lines-r8.sh` returns `0`, `49/0`, and `r60-feature-ground-r8.sh` returns `0`, `28/0`; each matches its committed log byte-for-byte in both modes.
- The full-repository archive is `.git`-free and includes `docs/port/PARAMETERS.md`. The four decision `assumes` rows exactly match its four fixed registry rows. Five cited endpoints returned HTTP 200 with `curl`.

## Findings

None. The revision-9 decision corrects F8 and does not assert more than the recorded commands establish. The specified `4b56f12..HEAD` evidence range contains 21 additions because intermediate commit `8cde9eb` checkpointed the round-8 empirical audit after `4b56f12`; that range is not the revision-9 delta. `git diff 7d501e1^..7d501e1 -- review/evidence` contains exactly the two new preservation logs, and its decision diff has exactly the title, 36-line note, and 67-line F8-block hunks.

## Assessment

Approved. The F8 mechanism is correctly described: the superseded sentence makes r7's flattened-document `C4k9` pass, while r8's updated `C4k9` and `C4o28` distinguish the current preamble from the labelled historical quotation. Gate 1 remains correctly recorded as inapplicable under Q7.B.
