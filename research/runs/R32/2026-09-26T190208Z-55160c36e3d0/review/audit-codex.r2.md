actor: codex
model: gpt-6
family: openai
decision-sha256: 256ac65e50e69f8f6a09f7ae62fb8f4e7ac71bac46f494da5aa88c15ef01ad0b
verdict: approve
unresolved-findings: none

# R32 empirical re-run audit — revision 2

The target hash was recomputed with `sha256sum` before reading the decision and matched the dispatch value. This is an empirical audit under RUNBOOK §7 and Q23. The dispatch's `EXECUTION.json` hash is a point-in-time reference; this worker did not read the live file.

All twelve `review/evidence/r32-*.sh` scripts were rerun in the foreground from copies staged under `/tmp/r32-codex-r2`. The environment set `CARGO_HOME=/tmp/cargo-s73-R32-evr` and `CARGO_TARGET_DIR=/tmp/cargo-s73-R32-evr-target`. Script-written snapshots and install output stayed in `/tmp`. The final reruns report **PASS=271 FAIL=0**. Whole rerun output was byte-compared with each committed `.log`, and a complete unified diff for every changed log was inspected. `r32-shape.log` is byte-identical. The other eleven logs differ as detailed below; none changes a check's result or the recommendation.

## Findings

- **OBS-1 — Run-local output differs.** Scratch paths, target paths, build/download messages, elapsed times, temporary child identifiers, and `r32-citations.sh`'s staged root differ from the committed logs. Every script has the same ordered check IDs and final PASS/FAIL counts as its committed log. The timeout probe still reported `TIMEOUT [60.004s]` and a 60.18 s wall-clock run against the committed 60.003 s and 60.22 s; its child was gone. The two-binary parallel probe measured 2.09 s for `cargo test`, 1.19 s for default nextest, and 2.20 s for `-j 1`, versus the committed 2.21 s, 1.30 s, and 2.57 s. All satisfy the recorded thresholds. The decision discloses that these are one-host, two-test fixture measurements (`DECISION.md:263-267`, `:307`).
- **OBS-2 — Live source figures changed after their dated capture.** `r32-sources.sh` still passes all 23 checks and retains the selected newest versions. The full diff shows changed 90-day and all-time download counts for four crates and nextest GitHub stars of 3,304 versus 3,303. `r32-r2-sources.sh` still returns `predicates` open issues `total_count` 23 and passes all seven pinned-source checks. The decision dates the original figures at `DECISION.md:190` and the revision 2 issue count at `:203`; this is disclosed point-in-time drift, not a contradiction.
- **OBS-3 — Fresh installation instead of an already installed tool.** The committed `r32-install.log` says Cargo ignored an already installed `cargo-nextest` 0.9.146. The rerun built and installed that same version into the private `/tmp` Cargo home in 42 s, then passed E1a–E1e. A first sandboxed attempt could not compile `nextest-runner` because macOS denied DTrace header access; the final process-enabled rerun succeeded. The final evidence, not the failed environment attempt, is the comparison above.

## Revision 2 repairs

1. **Local suite and hook feature scope:** `DECISION.md:33`, `:41-42`, `:120-132`, `:149`, and `:210` consistently make `just test` and its doc-test step feature-on. E8e/E8e2/E8f2–E8f5 confirm the web tier and its gated doc example run with `--features web`, while the feature-off control skips that example. E6t confirms `just test-all` runs all eight tests. The rerun logs retain PASS=13 for E8 and PASS=22 for E6.
2. **Partitioned execution order:** `DECISION.md:93` distinguishes deterministic `slice:` and `hash:` sharding from random order, calls `count:` deprecated, and leaves CI topology to R11. `DECISION.md:337` records both legs' statements. E12a–E12f pass against the pinned partitioning page.
3. **`predicates` figures:** `DECISION.md:203` records 23 open issues, confirmed by E12g. `DECISION.md:204` and `:341` label responsiveness unmeasured as G9, state the reason, and acknowledge direct `predicates::str::contains` use. The repair does not present the missing measure as inapplicable.

No BLOCKING finding was observed. Under Q23, zero BLOCKING findings yields `approve`.
