actor: codex
model: gpt-6
family: openai
decision-sha256: bef3b1202e75f8e2f841c95d9b31c7fd848ecba1c1376896f077b19b0bf6b654
verdict: approve
unresolved-findings: none

# R40 empirical re-run audit — revision 3

The decision hash matched the supplied hash before any other work. This audit applies the outcome-changing `BLOCKING` bar in `research/RUNBOOK.md` §7.1. It checks execution and log drift, not the recommendation's prose merits.

I reset and recreated `CARGO_HOME=/tmp/cargo-s61-R40-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s61-R40-evr-target`. The first `r40-install.sh` attempt could not resolve `index.crates.io` in the network-restricted sandbox. The same script then completed with network access. Each individual script ran from the repository root with its output under `/tmp/r40-codex-r3/`. The unmodified, byte-checked `r40-rerun-all.sh` and its nine evidence scripts also ran from a `/tmp` mirror so the runner's log writes could not change the committed evidence. Every command was foreground and bounded below 1,200 seconds.

## Re-execution and byte comparison

`shellcheck` passed over all 10 scripts. The aggregate pass (`/tmp/r40-codex-r3/r40-rerun-all.log`) ran from `2026-09-27T21:54:22Z` to `21:56:56Z`: all nine evidence scripts exited 0, and the seven asserting scripts passed 192 of 192 assertions. The individual pass had the same exit codes and totals. `r40-citations.sh` passed 104 of 104 assertions against the aggregate pass's fresh mirrored logs, including its policy check at fresh `r40-citations.log:9`.

The table reports `cmp -s` of each aggregate fresh log against its committed log. A separate `cmp -s` over the individual logs gave the same identity/difference pattern.

| Script | Fresh result | `cmp` | Difference, if any |
|---|---:|---|---|
| `r40-install.sh` | exit 0, `DONE` | differs | private Cargo paths and source-build wall times |
| `r40-ec.sh` | 14/14 | identical | — |
| `r40-yaml.sh` | 19/19 | identical | — |
| `r40-typos.sh` | 11/11 | identical | — |
| `r40-actionlint.sh` | 17/17 | differs | lefthook and `A8` elapsed times |
| `r40-insta.sh` | 8/8 | differs | scratch directory, Cargo path, thread identifier and elapsed times |
| `r40-compose.sh` | 19/19 | differs | private tool paths, parallel hook output order and elapsed times |
| `r40-figures.sh` | exit 0, `DONE` | differs | retrieval timestamp and two GitHub star counts |
| `r40-citations.sh` | 104/104 | identical | — |
| `r40-rerun-all.sh` | exit 0 | differs | start and finish timestamps only |

## Revision-note repairs

- Revision 3 EF-1 holds at the quoted script lines: `r40-actionlint.sh:33,37`, `r40-compose.sh:33`, and `r40-citations.sh:24,29,156` use `grep` with a here-string. `r40-typos.sh:42-46` captures each tool's output before searching it. Both passes kept the two recorded typos lines byte-identical and passed `A5`–`A7` and `C3`.
- Revision 3 EF-2 holds: `r40-citations.sh:39-40` uses `jq -cS` on `.engine_overrides.R40`, `.items.R40` and `.pilot` for both policy files. Fresh `r40-citations.log:9` reports `PASS run policy snapshot equals research/EXECUTION.json on .engine_overrides.R40, .items.R40 and .pilot`; its total remains 104/104. The live policy is treated as the point-in-time citation in `DECISION.md:6,14`, under the no-repin rule in `RUNBOOK.md` §7.7.
- Revision 2's recorded repairs remain present: provenance at `DECISION.md:12-16`, the corrected Pacific-date explanation at `:16`, gate-3 `unsafe` notes at `:202,226`, gate-6 acquisition/build-cost notes at `:178,202,226,247`, and counted prompt/policy checks at `r40-citations.sh:37,40,185`. The rerun confirmed both checks contribute to the 104/104 total.

## Findings

- **OBS-1 — volatile execution output.** `r40-install.log` changed source-build times from 35/36 seconds to 44/42 seconds in the aggregate pass. `r40-actionlint.log` and `r40-compose.log` changed elapsed times; `r40-insta.log` changed scratch paths and a thread identifier; lefthook reordered parallel output. The aggregate `r40-rerun-all.log` changed only its two timestamps. `DECISION.md:8,16,394-439` binds the recorded times and host to the final evidence pass. All behavior assertions and versions stayed the same. No recommendation or load-bearing claim moved.
- **OBS-2 — retrieved figures.** In the aggregate fresh `r40-figures.log`, `retrieved_at` moved from `2026-09-27T19:35:38Z` to `21:55:58Z`; `editorconfig-checker` stars changed 639 → 640 and `actionlint` stars 4,266 → 4,268. These are the only figure-log byte differences. `DECISION.md:8,16` identifies retrieval timing and re-pinned volatile counts; the maintenance signals at `:201,225,246` (versions, issue-response counts and zero `actionlint` commits since 2026-04-20) reproduced. No recommendation or load-bearing claim moved.

No `BLOCKING` findings. The decision's evidence sufficiency and recommendation survive this re-run.
