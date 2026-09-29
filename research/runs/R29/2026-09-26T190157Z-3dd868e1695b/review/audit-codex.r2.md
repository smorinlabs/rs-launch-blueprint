# R29 revision 2 empirical audit

- actor: codex-empirical-r29-r2
- model: gpt-6
- family: openai
- decision-sha256: 4b8dac24ff10d60d5b7a692ac1d0cfc3050d931636b713f7220cc7d14893cd9b
- verdict: blocked
- unresolved-findings: B1

## Findings

- **BLOCKING B1 — Evidence re-execution is incomplete.** The decision claims that `r29-dprint-stack.sh`, `r29-lefthook.sh`, and `r29-taplo-compare.sh` execute the fixture checks, and that `r29-decision-checks.sh` validates the revision-2 citations (`DECISION.md:9,160-173`). Their committed logs cannot be accepted as independently reproduced under this assignment's prohibitions. The three fixture scripts invoke `git` subcommands (`r29-dprint-stack.sh:26`, `r29-lefthook.sh:18`, `r29-taplo-compare.sh:23`); `r29-decision-checks.sh` reads `inputs/` (`:45` and subsequent checks); `r29-sources.sh` reads `snapshots/` (`:8-9`); `r29-provision.sh` reads `snapshots/` (`:66-69`); and `r29-snapshots.sh` writes `snapshots/` (`:10-12`). The assignment forbids `git` (any subcommand), `inputs/`, and `snapshots/`, and permits in-repository writes only to this audit. None of the seven evidence scripts was executed. Thus no whole-output comparison against their seven committed logs is available, leaving the empirical support for the recommendation unverified by this audit. This is an evidence-sufficiency finding, not a claim that a committed check failed.
- **OBS O1 — Revision-2 repair text is present.** The wiring table assigns `check-files` to the checking composite and `format-files` to the writing composite (`DECISION.md:63`). The hand-off preserves R27's F102 scope (`:124`). Disagreement J explicitly settles the Muse/Opus split for option (a) (`:248-255`). This is a line check, not execution of the composite.
- **OBS O2 — ShellCheck log reproduces byte-for-byte.** ShellCheck 0.11.0 ran against all seven evidence scripts; `cmp` found the complete `/tmp/r29-shellcheck-codex-r2.log` identical to the committed `shellcheck.log`. This validates shell syntax only; it does not replace the seven empirical reruns.

Live `research/EXECUTION.json` was not read or checked. Point-in-time policy drift was not considered a finding.
