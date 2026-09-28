actor: codex
model: gpt-6
family: openai
decision-sha256: 8dc8ce955c58abd508d45bd74a6b2c3f9eb96bde5c43ae20538f2439c8867aae
verdict: approve
unresolved-findings: none

# R58 revision 2 empirical re-run

The decision hash above was recomputed with `shasum -a 256` before any other read and matched the assigned revision. This is the Q23 empirical worker report; S1 owns the later finding triage.

## Re-execution

The three reproducible evidence scripts ran in the foreground. Their output was written only to `/tmp/r58-codex-r2-*.log`. Each exited 0 and was byte-identical (`cmp`) to its committed log:

| Script and committed log | Result | SHA-256 of both logs |
|---|---|---|
| `r58-probe.sh`, `r58-probe.log` | `PASS=33 FAIL=0 SKIP=0 TOTAL=33` | `2921d8f2bdfe396aa4ca46995a9f308cd36e3af35703ba59b4ce3aa8b6ac0673` |
| `r58-standards.sh`, `r58-standards.log` | `PASS=48 FAIL=0 SKIP=0 TOTAL=48` | `9359508c50536bb5af386e3cc8a3a98e1a1eba49bc9b393888a5e94b0ddd63fb` |
| `r58-figures.sh`, `r58-figures.log` | `PASS=161 FAIL=0 SKIP=0 TOTAL=161` | `9203aab1c59334c846e5cf01b2c83ec7d08bf95979b6bb5384e5caeeacc868b4` |

The result is **242 PASS = 33 + 48 + 161**, with zero failures and zero skips. The first probe attempt could not resolve `index.crates.io` in the restricted network and stopped at its build check (`PASS=0 FAIL=1 SKIP=0 TOTAL=1`). A second foreground run with network access reused the declared `CARGO_HOME=/tmp/cargo-s69-R58-evr` and completed with the byte-identical 33-check result. No script or committed log was changed.

The helper scripts `r58-assert-figures.py`, `r58-gate1-wording.py`, and `r58-param-lines.py` also ran through the figure and standards scripts. Separately, `r58-gate1-wording.py` found the ruling wording in five places, `r58-param-lines.py` emitted five parameter lines, and `r58-sample-issues.py` reproduced the committed ten-issue number list byte for byte.

## Revision-note checks and observations

- **OBS — route (b) adoption matches the recorded evidence.** The current evidence script hashes match the revision-note table: probe `d908a4d3…a58418`, standards `d39ceb48…7836`, figures `6de25b3d…f775d`, and fetcher `c82900cc…8957c`. The probe manifest pins `tracing = "=0.1.44"` and `tracing-subscriber = "=0.3.23"`; `probe/Cargo.lock` is present. The fetch log has 46 lines, including both `rustsec advisory:` entries; the snapshot directory has 95 files and its retrieval stamp reads `2026-09-27T05:48:12Z`. The fetcher rewrites snapshots, so it was inspected as provenance and was not rerun.
- **OBS — EC-1 and EC-2 repairs hold.** `DECISION.md` lines 1551–1553 and 1807–1813 state the same 33/48/161 counts that reran. `r58-probe.sh` exports `CARGO_TARGET_DIR="$WORK/target"` and its `run()` function records a failed binary exit. The successful run included the partial-host S4c/S4d checks at `r58-probe.log:39–40`.
- **OBS — standards and claim lines hold.** `r58-standards.log:16–23` passes the four quoted R5.1 lines. `DECISION.md:496–507` puts all flag rungs above `RSLBP_LOG_LEVEL`; `DECISION.md:450–460` distinguishes a preexisting dispatcher from a refused `log` bridge. The four revision-rule checks passed, including the gate-1 wording. The revision note discloses registry, toolchain, and version-label limitations (DR-1–DR-3); this run found no undisclosed output drift.
- **OBS — fetch timing is a provenance limit, not a contradictory result.** The 46-line fetch log contains endpoint names without timestamps. Its single-invocation and start-time claims cannot be independently reconstructed from that log alone; its output shape, advisory entries, 95 files, and terminal retrieval stamp match the revision note. The snapshot fetcher was not invoked because it would replace the frozen evidence.

No BLOCKING finding was observed. The recommendation's executed checks and the load-bearing evidence claims examined here reproduce against the adopted revision 2 baseline.
