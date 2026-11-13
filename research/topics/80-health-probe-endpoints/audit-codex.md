actor: codex
model: gpt-6
family: openai
decision-sha256: 4b63412a4dc1df4c2e31caa51fa20ca509c8e8cd430595f72b94de0843d4c204
verdict: approve
unresolved-findings: none

# R80 revision 6 — empirical re-run audit

This is the single Q23 empirical worker audit. The decision hash above matched `shasum -a 256` before the decision was read and again before this audit was written. Scope is execution truth and evidence support. No inputs, snapshots, scripts, decisions, or other repository files were changed.

Repository root and working directory: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. The scripts ran from a copied evidence tree at `/tmp/r80-codex-r6.Ezqf4wWo/evidence`; fetch mode used a second copy at `/tmp/r80-codex-r6.Ezqf4wWo/live-fetch-evidence`. All output went to `/tmp/r80-codex-r6.Ezqf4wWo/`. The supplied `CARGO_HOME` and `CARGO_TARGET_DIR` remained set; no command exceeded 1200 seconds. The first probe attempt encountered an incomplete private Cargo cache and unavailable DNS in the restricted sandbox; it was stopped, then the unchanged script ran successfully with public network access. A subsequent warm-cache run also passed.

## Re-execution and byte comparison

`cmp -s` and `shasum -a 256` compared each fresh log with its named paired log in `review/evidence/`. Counts below are PASS/FAIL/SKIP. "Raw bytes" includes date stamps, temporary paths, Cargo output, and live counters.

| Script or mode | Fresh count | Raw bytes against paired log | Assertion lines and total |
|---|---:|---|---|
| `check-offline.sh` | 27/1/0 | differ from `check-offline.log` | differ: `O5` and total |
| `check-probe.sh`, warm cache | 13/0/0 | differ from `check-probe.log` | identical |
| `check-standard-r2.sh` | 41/1/0 | differ from `check-standard-r2.log` | differ: `C9` and total |
| `check-standard-r3.sh` | 6/1/0 | differ from `check-standard-r3.log` | differ: `R7` and total |
| `check-standard-r4.sh` | 12/2/0 | differ from `check-standard-r4.log` | differ: `V6`, `V14`, and total |
| `check-live.sh --snapshots` | 9/0/0 | differ from `check-live.r4-snapshots.log` only by the UTC stamp | identical |
| `check-live.sh`, public fetch | 9/0/0 | differ from `check-live.r4-fetch.log` | identical |
| `shellcheck` on all six scripts | exit 0, empty output | byte-identical to `shellcheck-r4.log` | empty |

The original `check-live.log` and the fresh snapshot-mode log differ only in the `mode: fetch` versus `mode: snapshots` banner and UTC stamp; all nine checks otherwise match. After normalizing the decision's stated UTC stamp and temporary workspace path, `check-live.r4-snapshots.log` is byte-identical to the fresh snapshot log. The warm probe log differs after those normalizations only in Cargo target paths and three test timing lines. The fresh standard-r2 log also has a Cargo target path and timing difference. Fetch mode kept all nine checks passing; the live `q=liveness` denominator changed from the recorded 29,607 to 29,734, as the decision says live counters can do.

## Findings

1. **OBS — R69 source-line drift causes four direct or nested check failures.** The decision says R69 revision 10's owned value is at "line 1791" (`DECISION.md:589-592`), and the revision-6 log recorded 28/0/0 offline, 42/0/0 for r2, 7/0/0 for r3, and 14/0/0 for r4 (`DECISION.md:1051-1056`). The fresh log instead says `FAIL O5 ... (owns line: 1885)`; `C9`, `R7`, and `V14` then fail solely because they require their nested script to have zero failures. `V6` separately reads line 1791 of R69's current working decision and fails. R69's `R69-r10-snapshot.md` has the cited owned value at line 1791. Its current revision-11 `DECISION.md` has the owned value at line 1885, **byte-identical** to the snapshot line, including `crates/web/Cargo.toml` and `web = ["dep:rs-launch-blueprint-web"]`. The live parameter registry still has the `src/web/` form that `O5` checks. The load-bearing facade-to-web dependency and the stated publication lag therefore remain supported. Q23 §7.7 treats live citations as point-in-time and says drift does not trigger a re-pin.
2. **OBS — The accepted R02 byte location moved.** The recorded offline log says `O17` found R02's accepted revision-2 bytes at its working `DECISION.md`; the fresh log finds the same accepted bytes in `R02-r2-snapshot.md`. `O17` itself passes and verifies the accepted digest. This is a path-only difference in the log.
3. **OBS — Build and live-source output varies outside assertions.** The probe's first successful network run downloaded locked crates into the supplied private Cargo home; the warm run passed 13/0/0. Its assertion lines match the paired log byte-for-byte. Cargo target paths and timings differ. The standard-r2 build also differs in target path and timing. Live fetch counters changed, while version, status, and structure assertions remained 9/0/0. The decision explicitly says `check-probe.log` and `check-standard-r2.log` can differ in build timing while their assertions reproduce (`DECISION.md:1286-1290`), and says `check-live.sh` cannot reproduce byte-for-byte because counters move (`DECISION.md:1319-1325`).

No BLOCKING finding: the failures above arise from an R69 line-number change whose source text is unchanged. They do not contradict the probe behavior, lockfile pins, engine seat, or other load-bearing execution claim. Under Q23 §7.1, `approve` follows from zero BLOCKING findings.

## Revision-note repair checks

- **Revision 6, Codex finding 1 (`DECISION.md:16`):** The note says `V3` now reads `seat_overrides.get(item, "codex")`. `check-standard-r4.sh:136-155` reads the default `codex` seat, and the fresh log prints `policy_empirical_auditor_R80=codex` followed by `PASS V3`. The `## Engines` text says R80 has no seat override and uses that default (`DECISION.md:1363-1377`). The paired log's recorded `PASS V3` matches the fresh result.
- **Revision 6, Codex finding 2 (`DECISION.md:17`):** The note now names `review/audit-claude.r4.md` line 9 as the surviving record. That line says the old log contained `grep: empty (sub)expression` "six times" at lines 32, 34, 36, 38, 40, and 42. The revision-5 EF-1 row repeats that exact citation (`DECISION.md:45`). The historical count is supported by the named audit line; no old log was reconstructed.
- **Revision 5, EF-1 (`DECISION.md:45-54`):** The repaired `V8` patterns at `check-standard-r4.sh:266-267` escape the leading pipes. The fresh log quotes `positive control ... count 1, grep status 0`, six scans at `0 (grep status 1)`, and `PASS V8`; it contains no grep syntax error. `shellcheck-r4.log` remains empty.
- **Revision 4 repairs (`DECISION.md:85-97`):** The fresh `V2`-`V5` results pass the Muse substitution and raw-report checks; `V7` and `O28` pass the R55/R57 publication checks; `O17` passes the accepted-digest binding; `V8` passes the early-exit grep scan; `V9` and the 13/0/0 probe confirm committed lockfiles and `--locked`; `V10` and `V11` pass the corrected figures and archive-diff sizes. The R22/facade edge tested by `V6` also holds in R69's revision-10 snapshot and byte-identical revision-11 owned line; its current-line assertion fails as finding 1 describes. `V1` and `V13` pass the revision snapshots and 22 artifact digests.
