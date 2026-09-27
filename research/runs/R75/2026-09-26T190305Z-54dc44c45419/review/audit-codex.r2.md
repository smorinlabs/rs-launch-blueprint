# R75 empirical re-run audit — decision revision 2

actor: codex-r75-empirical-r2
model: gpt-6
family: openai
decision-sha256: 98f574432fe565bdc77588aed42d171689585392667d6cebd51d62beaa7b31c7
verdict: approve
unresolved-findings: none

## Scope and result

I recomputed the decision SHA-256 before reading or writing other files. It matched the assigned value. I ran all seven unchanged `review/evidence/*.sh` scripts from the run directory, with `CARGO_HOME=/tmp/cargo-s61-R75-evr`, `CARGO_TARGET_DIR=/tmp/cargo-s61-R75-evr-target`, and `R75_PROBE_DIR=/tmp/r75-codex-r2-probe`. The Cargo directories were removed and recreated before the successful probe. Fresh stdout logs are in `/tmp/r75-codex-r2-logs/`; each script had a 1,000-second alarm. `cmp` found that **all seven** fresh logs differ from their committed counterparts. The differences are classified below.

The first probe attempt could not resolve `index.crates.io` under restricted network access. After a fresh Cargo setup with network access, `probe-crate.sh` succeeded. The first E3 run could not bind `127.0.0.1:0` under restricted socket permissions; its unchanged retry with network permission passed. These sandbox attempts produced no evidence against the stack.

| Check | Fresh result | Comparison with committed log |
|---|---|---|
| E0 `probe-crate.sh` | exit 0; lock SHA-256 `5e89a57d3a9d8513487aeee2fa4e2f07afde2eddc7c3584ae90c3be7b01d43cb`; 58 normal-tree packages, 5 only through `tower-http` | Different timestamp and scratch path; Cargo tree feature lines appear in a different order. Source hashes, versions, feature set, and package counts hold. |
| E1 `stack-acceptance.sh` | exit 0; 15 pass, 0 fail on both rustc 1.98.1 and 1.96.0 | Different timestamp, UUIDs, and elapsed times; assertions and outcomes hold. A12 measured `duration_ms=202.1` on both toolchains, versus committed 202.0 and 202.2. |
| E2 `negative-controls.sh` | exit 0; 12 pass, 0 fail | Different timestamp, UUIDs, and one test elapsed time; assertions and outcomes hold. |
| E3 `framework-log-foldin.sh` | exit 0; 4 pass, 0 fail; 7 `axum::serve` TRACE, 3 access INFO, 1 catch-panic ERROR, 0 `log` records | Timestamp only. |
| E4 `figures.sh` | exit 0; no `GAP` lines; same newest crate versions, issue responses, and advisories | Retrieval time, download counters, and two GitHub star counts changed. |
| E5 `practice-check.sh` | exit 0; six upstream files read; same cited source excerpts and unsafe census | Retrieval time and `rust-lang/crates.io/Cargo.toml` source SHA changed from `985aae3b53c5b6d5e814ec916e116fc3f3203740` to `765bbf478827f421a93ea2634997b2b4f55c87f4`. The relevant axum and `tower-http` version lines remain the same. |
| E6 `decision-shape-check.sh` | exit 1; 125 pass, 1 fail (`S02`) | Revision SHA and line count changed as expected; private Cargo path changed; the sole failed assertion is the obsolete title baseline below. All other citation, parameter, and shape assertions passed. |

## Findings

- **OBS E0–E3 — run-specific output drift.** The byte differences are generated IDs, timestamps, timing, scratch paths, and Cargo tree ordering. The decision labels A12's 202.0/202.2 values as observations from the committed log at line 551; the executable assertion is `duration_ms >= 200`, and both fresh measurements are 202.1. The decision's empirical table at lines 527–537 reports the same passing counts. No load-bearing claim changes.
- **OBS E4 — live counter drift.** The committed retrieval is explicitly dated at decision line 354, and lines 521–523 state that `figures.sh` re-observes rather than reproduces numbers. All changed downloads and stars are live counters; the version, maintenance, and advisory conclusions still hold.
- **OBS E5 — upstream source SHA drift.** The `crates.io` `Cargo.toml` commit changed, while the two cited `axum` 0.8.9 and `tower-http` 0.7.1 dependency excerpts did not. This is a point-in-time re-pin, with no effect on the recommendation.
- **OBS E6/S02 — obsolete revision-1 title baseline.** The script's exact expected string is `# 2026-09-27 — R75 — http-middleware-stack (bundle, Deep) — decision (revision 1)` (`decision-shape-check.sh:32`). The exact current title is `# 2026-09-27 — R75 — http-middleware-stack (bundle, Deep) — decision (revision 2)` (`DECISION.md:1`). **They do not match.** Under RUNBOOK §7.1, title drift is recorded and does not cost a round.

## Revision-note repair checks

1. **JF-7 / JF-1 holds.** `DECISION.md:479–492` adopts R72's clause-(4) interpretation and cites `research/topics/72-api-pagination/DECISION.md:260–300`; that source says the feature literal records R69's two dependencies without closing the list (`:286–289`). The R69 hand-off at `DECISION.md:426` says `joins`, and the `Cargo.toml` row at `:432` no longer says `needs R69`. `DECISION.md:464` retains `No CONFLICT: line is raised`.
2. **JF-8 holds.** `DECISION.md:551` quotes the committed A12 measurements exactly: 202.0 milliseconds on the host and 202.2 milliseconds on rustc 1.96.0. The fresh measurements are also above the 200-millisecond assertion threshold.
3. **JF-1 holds.** `DECISION.md:216–217` says `the four functions`, consistent with the decision's summary at `:68` and its four function definitions.

The revision-1 snapshot SHA-256 is `7b936d861827d81e7f9bff2023b29511980864ec9c7d593b8034ba433ab7a4e5`, as the revision note states. A diff against that snapshot contains the revision note and the three stated repairs.

The supplied frozen-seat policy identifies `research/EXECUTION.json` as `55f51017f3ab` at its stated point in time. The local file read during this audit hashes to `fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c`. I did not treat this policy-citation drift as a finding or request a re-pin, as RUNBOOK §7.7 directs. The Q23 outcome bar leaves **zero BLOCKING findings**.
