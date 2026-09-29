# R76 revision 5 empirical re-run audit

actor: codex
model: gpt-6
family: openai
decision-sha256: fd1647b8f46f66adb1817f6387f5b1a977cd58c76e32c319e839fe05deb84278
execution-sha256-pin: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
verdict: approve
unresolved-findings: none

## Re-execution and byte comparison

All five evidence scripts ran from `review/evidence/`, wrote their captured output to `/tmp/r76-r5-*.log`, and exited 0. Each captured log was byte-compared with its committed namesake. All five byte comparisons differ; all `ASSERT` lines match their committed logs byte-for-byte. There are no `ASSERT FAIL` lines. The committed lockfile and measured `CHECK` lines match, including the `X1`, `X9`, `X10`, and `X11` checks of the revision 4 expose-list repair. Network-dependent reruns used read-only network access after restricted attempts skipped those sections.

| Script | Rerun result | Byte comparison |
|---|---|---|
| `decision-self-check.sh` | 74 pass, 0 fail, 0 skip | UTC timestamp only |
| `registry-figures.sh` | 56 pass, 0 fail, 0 skip | UTC timestamp and live registry / default-branch figures |
| `probe-checks.sh` | 29 pass, 0 fail, 0 skip | UTC timestamp, scratch path, and unasserted build seconds; stripped sizes remain 502,264 and 668,728 bytes, a 166,464-byte difference |
| `muse-adjudication.sh` | 27 pass, 0 fail, 0 skip | UTC timestamp, live input / policy hashes and manifest state, plus live download, dependency, and star counts |
| `rest-conformance-r2.sh` | 66 pass, 0 fail, 0 skip | UTC timestamp, decision hash, nested self-check count, and live `OVERRIDE` token counts |

## Revision 5 line checks

The flag-day `web-extra-surface` value in `review/DECISION.md:787` matches R69 revision 11's `- owns web-extra-surface` at `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1885` after the prefix swap; R69's decision hashes to `2806a1f04517a09334afde96eea1063e3da799d0e3bd66268e433baf56bc1815`. The revised `crates/web` dependency and path claims appear at `review/DECISION.md:708`, `:753-766`, and `:794-807`; re-verify trigger 1 names R69 revision 11 at `:773`. The revision note states the limited touch-up and unchanged recommendation at `:11-27`. The retargeted self-check verifies the revision 5 title and R69 source at `review/evidence/decision-self-check.sh:14-23`, `:73-74`, and `:103-147`; its rerun passes. The revision 4 expose-list repair remains stated at `review/DECISION.md:40` and `:142`, with the measured `X` checks unchanged.

## Findings

- **OBS-1:** The live registry figures, default-branch commit, scratch path, and build seconds changed. `review/DECISION.md:1049-1059` explicitly says `FIGURE`/`HEAD` lines are point-in-time and build seconds and the `mktemp` path never reproduce byte-for-byte. The crate recommendation remains `tower-http` 0.7.1, and the rerun preserves the measured behavior and binary-size result.
- **OBS-2:** `muse-adjudication.sh` prints changed prompt, `EXECUTION.json`, `RUNBOOK.md`, and manifest bytes/state. Its engine and answer assertions still pass. The current `EXECUTION.json` matches the S79 pin in this header; Q23's `research/RUNBOOK.md:332-342` says input and policy citation drift is point-in-time and never a re-pin finding.
- **OBS-3:** The committed `rest-conformance-r2.log` header names revision 4's decision hash `c732bf24633eb386db07c186324af00a74c7d43f9932e4327c519a37aa40d641` and its nested self-check reports 73 passes; the rerun names revision 5's hash and reports 74 passes. `review/DECISION.md:11-27` discloses the title and self-check retargeting. The conformance script itself passes all 66 assertions, and its measured `X` lines match the committed log.
