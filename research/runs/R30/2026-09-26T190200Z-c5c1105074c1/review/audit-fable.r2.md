# R30 — type-check-gate — judgment audit of DECISION.md revision 2

actor: fable
model: claude-opus-5-5
family: anthropic
decision: research/runs/R30/2026-09-26T190200Z-c5c1105074c1/review/DECISION.md (revision 2)
decision-sha256: d15d4cee636494fac69c6996017c9c099860dad8b1c205d1b45fbde7ac86d687
verdict: reject
unresolved-findings:
1. JF-5 — the toolchain-channel coupling is handed to the wrong owner, and member 3's Cargo ≥ 1.97 precondition is not handed to the item that owns the channel. Details under "Findings".

## Scope and method

- Hash verified first with `shasum -a 256`: `d15d4cee…6d687`, equal to the expected value.
- Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §3–§5 (roles, decision shape, audit contract); `raw/muse.md` and `raw/opus.md` (cited lines spot-checked); the consumed prerequisite `research/topics/11-ci-workflow-job-structure/DECISION.md` (lines 221, 227, 268, 278, 286); and the evidence scripts and logs under `review/evidence/`.
- Also read, because the decision couples to it: `research/topics/42-dev-toolchain-provisioning/DECISION.md` (published; sha256 `a2504aa7…f574f5e1c`, which matches its `acceptance.json`), and the R27 prompt's F103 context line.
- Not read, as instructed: every `review/audit-*.md` file and `review/R30-r1-snapshot.md`. As a result, the revision note's figures attributed to the audits (for example, "6.69 s in the empirical auditor's rerun") are **unverified by this audit**. They decide nothing.
- No git writes, no runner commands, no paid APIs. No scripts were rerun; the logs were spot-checked.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass | Every figure quoted in the prose appears in the logs at the cited line. `r30-wiring-cost.log`: `:35` 5.53 s (`H2a`); `:42` 0.24 s and `:49` 0.12 s (`H2b`, `H2c`); `:61` 0.44 s, `:70` 0.25 s and `:82` 0.48 s (`H2d`–`H2f`); `:168` 0.50 s and `:184` 0.26 s (`H3e`, `H3f`); `:165` and `:181` read "done in 0.11 / 0.20 seconds"; `:200` has 4 units and 0.27 s (`H4a`). The stack table, the settled rows, the D1–D9 resolutions and the acceptance table agree with each other. |
| JF-2 prompt questions and constraints | pass, with a note | Every question is answered: HIGH-1 (F105), HIGH-2 (F108), HIGH-3 (F110), HIGH-4 (the principle and agreement-level table), MEDIUM suppression (F111), MEDIUM severity (F112), MEDIUM scope (F113), LOW tier (F106). The out-of-scope items (F109, R31, CI job shape, clippy/rustfmt config) are handed off rather than decided. The `ubuntu-latest` gap is stated honestly (criterion 8; gap 2). **Note, not a finding:** the prompt's six fitness gates are not enumerated one by one in the decision. It states only "No crate is added" and the license. The raws carry the per-gate treatment (`opus.md:355-370`; `muse.md:3`), and RUNBOOK §5 does not require the gates inside `DECISION.md`. |
| JF-3 Engines fidelity and disagreements | pass | Spot-checked each disagreement against the raws. D1: `muse.md:33`, `:121` vs `opus.md:319-323`. D2: `muse.md:161`, `:259`. D3: `opus.md:152`, `:253`, `:513` vs `muse.md:33`, `:221`, `:259`. D4: `muse.md:117`, `:125` vs `opus.md:325-327`, `:733`. D5: `muse.md:185`, `:262`, `:276` vs `opus.md:293`, `:333`, `:934-936`. D6: `muse.md:225` vs `opus.md:258-259`. D7: `opus.md:800-801`, `:814-817`; `muse.md:145`. D8: `opus.md:14`, `:296-297`. D9: `muse.md:15`, `:17`, `:287`. Every citation says what the decision says it says. Each disagreement is resolved on an executed case (`S5`/`S6`, `W1`/`W3`, `L2`/`L3`, `X8`–`X10`, `H2`/`H3`) or is explicitly left undecided (D6). Muse omits `--keep-going`; the decision adopts it on `S8` and does not frame it as a disagreement. That omission is immaterial. |
| JF-4 load-bearing claims trace | pass | Headers of the cited cases were found in the logs: `S4`, `S6`, `S7` (`r30-scope.log:53-101`); `W2` (`r30-severity.log:85`, `:94`); `X6`, `X8a`, `X9a`, `X9b`, `X10a` (`r30-suppression.log:48-91`); `L1a`, `L2b`, `L3` (`r30-lints.log:40`, `:99`, `:122`); `H1c`, `H4b`; `V1b`, `V3`. The upstream quotations are in `r30-upstream-docs.log`: `continuous-integration.md:209-210` (blob `f1261a53`); `CHANGELOG.md:394`, `:399`, `:4151`, `:4156`; `manifest.md:532`, `:553`; and rust-analyzer `config.rs` `:787`, `:847`, `:878`, `:884`, `:891`, `:901`, `:962` (blob `1e7c8257`). The R11 citations resolve: `:221` covers the `-p` scoping of the feature-off *test* step and the four-package layout; `:278` is the partition rule; `:286` is R30's slot; `:268` records that R42 commits `rust-toolchain.toml`. The `:227` gloss "proves compilation, not warning-cleanliness" is an inference; the line itself says the floor job runs only `cargo hack check --rust-version`. The inference is sound. |
| JF-5 couplings hand over owned choices | **fail** | See finding 1. The other hand-offs are correctly routed: R28 (F109, editor features setting, `allow_attributes*`, clippy `-D warnings`); R40 (the `allow(warnings)` text check); R32 (doctests); R37 (hook job form); P03 (criteria 7 and 8). |
| JF-6 assumes lines byte-identical to the live registry | pass | All five `- assumes` values compared exactly against the value cells of live `docs/port/PARAMETERS.md` rows 7–10 and 12, and against `inputs/parameters.json`: all equal, including the 8,093-character `ci-job-structure` value. The R42 and R69 rows cited as prose (`PARAMETERS.md:14`, `:17`) are identical between the live file and `inputs/PARAMETERS.md`. |
| JF-7 no conflict with accepted/published prereq values | pass | The consumed R11 decision `410e88e5…` and acceptance `774f7649…` match `prerequisites.json`. The two `typecheck` steps are ordered steps of `check` under `--locked` and `!cancelled()`, as R11's rule requires. They add no job and no cache-bearing job id. No `CONFLICT:` line is needed. The R69 nesting claim (otel and metrics require web) matches the live R69 row. |
| JF-8 evidence scripts exist and counts match | pass, with a note | All eight scripts and logs are present. The PASS counts, counted with `/usr/bin/grep -c PASS`, are: scope 20, severity 17, suppression 16, lints 14, wiring-cost 17, wiring-severity 8. Every log ends `# summary: failures=0`. Upstream-docs reports 0 missing. **Note:** `r30-inputs.log` has 45 lines beginning `PASS` while its summary and the decision say 37. The 8 extra lines (`I-fig-cold` … `I-fig-lefthook`) are sub-assertions printed inside the single counted case `I-fig-all` (`r30-inputs.sh:103-143`), so "37" is accurate. |
| JF-9 decision shape | pass | The H2s are, in order, `## Decision`, `## Parameters`, `## Empirical check`, `## Engines`, with no `## Supersedes` (nothing has been published). `## Decision` carries the recommendation, versions, the settled F105–F108/F110–F113 rows, `### Principles and implementation`, and a `re-verify:` line. This matches RUNBOOK §5. |
| JF-10 recommendation follows from evidence | pass, conditional on finding 1 | Named gate A2 follows from `S5`/`S6` (two configurations), `W1`–`W3` (`build.warnings` over `RUSTFLAGS`), `L1`–`L3` (table contents), `X8`–`X10` (`cfg_attr(expect)`) and `H2`/`H3` (pre-commit). The runner-ups B and C are ranked on stated grounds. Member 3's value depends on the toolchain the gate actually runs on, which finding 1 addresses. |

## Findings

### 1. JF-5 — toolchain-channel coupling routed to R42 instead of R27; member 3's version precondition is not handed off

**Failed claims (quoted):**
- `DECISION.md:172`: "The residual source of spontaneous failure is a new stable toolchain; the pin is R42's (R11 `DECISION.md:268` records that R42 commits `rust-toolchain.toml`)."
- `DECISION.md:220` (Hand-offs): "**R42** (toolchain provisioning): the toolchain pin that keeps a new stable's lints from failing forks spontaneously".
- `DECISION.md:223` (re-verify): "R42 leaving the CI or contributor toolchain unpinned, which lets a new stable's lints fail forks spontaneously".
- `DECISION.md:37`: "The stack is Cargo and rustc from the toolchain the template already requires. One member has a version floor: `build.warnings` needs Cargo ≥ 1.97".

**Evidence:**
- R42 is published and accepted (`research/topics/42-dev-toolchain-provisioning/DECISION.md`, sha256 `a2504aa7…`, matching its `acceptance.json`). It commits the file but explicitly does not set the channel. Line 26 says: "The `channel` **value** is R27's through F103/F190 and is not set here." Line 458 says: "`rust-toolchain.toml` (channel per R27, …)". Its re-verify list (lines 468-469) defers to "R27 settles F103 with a `channel` …".
- The R27 prompt (`research/topics/27-formatter-config-surface/prompts/*.md:14`) confirms the ownership: "The file's `channel` and `components` are decided here (F103)".
- R42's own reference implementation commits `channel = "stable"` (`DECISION.md:439`). That is an unpinned channel, so "keep the toolchain pinned" is not already guaranteed by any published item.
- The decision shows that the severity switch is silently inert when the running cargo is below 1.97 (`W1`: `CARGO_BUILD_WARNINGS=deny` exits 0 on 1.96.0; `W2`). It accepts this only for the floor job, on the ground that the floor job does not assert warning-cleanliness. It does not state that the recipe, the hook and the `check` job must run on a channel whose cargo is ≥ 1.97. It also hands that constraint to no one. The phrase "the toolchain the template already requires" refers to a value that R27 has not yet settled.

**Consequence:** R27 owns the channel. It could settle F103 on a channel below 1.97 without seeing any R30 constraint. For example, it could pin the development toolchain to the `msrv-policy` floor, which is currently 1.96. In that case member 3 would deny nothing in the gate, the hook or CI, with no diagnostic. Acceptance criterion 2 would then silently fail in the rendered template. Separately, the "new stable's lints fail forks" hand-off and its re-verify trigger go to R42, which has already disclaimed the value, so neither would ever fire at the right owner.

**Repair (without deciding R27's value):**
- Re-route the pin hand-off at `:172` and `:220` to **R27 (F103, `rust-toolchain.toml` `channel`)**. Keep R42 only as the owner of the file and its components.
- Add to that R27 hand-off the constraint member 3 needs: "the channel the recipe, hook and `check` job run on must carry Cargo ≥ 1.97, or `CARGO_BUILD_WARNINGS=deny` is inert (`W1`)." State that choosing a pinned or a `stable` channel remains R27's decision. If R27 cannot meet the floor, the fallback is the recorded runner-up `RUSTFLAGS="-D warnings"`.
- Change the re-verify trigger at `:223` from "R42 leaving … unpinned" to "R27 settling F103 on an unpinned `stable` channel (new-stable lint risk) or on a channel whose Cargo is below 1.97 (member 3 inert)".
- Reword `:37` "the toolchain the template already requires" to name the owner: "the toolchain whose channel R27 settles under F103".

## Observations (non-blocking, for the controller)

- **The live policy file has moved since this revision was written.** The live `research/EXECUTION.json` now hashes to `acdcbfff…bf137`, not the frozen `c670184d…` that the decision (`I-policy`) and `r30-inputs.log:5` recorded. The file's mtime is 2026-09-26 23:30 local; the decision's is 21:54. A normalized diff shows only added `empirical_auditor_overrides` entries, R30 among them (`"R30": "claude"`). The decision was accurate when written, so this is not a decision defect. However, acceptance's current-inputs check will need a re-freeze or an explicit record of the change.
- The date recorded for Q17.A (2026-09-27, quoted from `RUNBOOK.md:73`) is later than this decision's Pacific date (2026-09-26). The decision quotes the RUNBOOK faithfully; if the RUNBOOK date is a UTC date, the correction belongs in the RUNBOOK.
- `manifest.json` still records the pre-amendment dispatch (codex, opus; prompt `a883b22d…`). The decision flags this itself (gap 8) as a controller step.
