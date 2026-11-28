decision-sha256: f85670a92cee8bc9777198cb4f6032cfe06460dba8e81df821c3b61a0fe740b9
actor: audit-fable-r32-r3b-2026-11-27
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none

# R32 revision 3 (r3b): judgment audit after the Codex F1 repair

**Outcome.** Codex F1 is resolved. In R02's root-package workspace, every local recipe now selects the whole workspace, and so does CI's feature-on doc-test step. Executed evidence shows the change is load-bearing. The `CONFLICT: R11` line is still byte-identical. Its **RESOLVED** paragraph correctly treats it as a fill of R11's delegated R32 slot. The recommendation, the member versions and the principles are unchanged. I found no BLOCKING finding under RUNBOOK §7.1. Three observations are recorded below. Under §7.1 they are recorded and do not cost a round.

This audit was read-only. No repository file was edited.

## 1. Integrity

| Check | Method | Result |
|---|---|---|
| Draft hash | `shasum -a 256 /tmp/p02-flagday/drafts/R32-DECISION.md` | **PASS**. The hash is `f85670a92cee8bc9777198cb4f6032cfe06460dba8e81df821c3b61a0fe740b9`, the expected value. |
| Supersession tail | Draft lines 368–708 compared by `cmp` with `research/topics/32-test-harness-and-execution/DECISION.md` | **PASS**. `cmp` exited 0, and both hash to `256ac65e50e69f8f6a09f7ae62fb8f4e7ac71bac46f494da5aa88c15ef01ad0b`. The tail starts directly under `## Supersedes` (line 366), after one blank line. |
| H2 structure before the tail | `grep '^## '` | **PASS**. The order is `Decision` (20), `Parameters` (251), `Empirical check` (273), `Engines` (332), `Supersedes` (366). `## Supersedes` appears once before the tail, and `re-verify:` appears once (249). |
| `assumes web-extra-surface` | R69 run `review/DECISION.md:1885` with `- owns ` changed to `- assumes `, compared with draft line 261 | **PASS**. Both lines hash to `44950fd7…`. The R69 revision 11 file hashes to `2806a1f0…`, the value the draft cites. |
| Probe log | `shasum -a 256 /tmp/p02-flagday/r32-r3-workspace-probe.log` | **PASS**. The hash is `5a6bd6b58f5301efd9d782fd5ed6b8107d997ee69ec1895087bb63557eaee658`, the value the draft cites (lines 6 and 317). |

## 2. Codex F1: resolved

**What F1 said.** Revision 3's first draft ran `--features web` with no package flag. In R02's root-package workspace (`research/topics/02-crate-boundary-enforcement/DECISION.md:106`, option E, "Chosen"), Cargo then tests only the root package. As a result, the local suite and the hook skipped `crates/core`, `crates/cli`, `crates/web/tests/` and the `crates/web` doc-tests.

**The evidence settles the mechanism.** All six probe commands exited 0, so the probe judges each check by which tests ran, not by exit code. I confirmed each row against the raw log:

| Check | What the log shows |
|---|---|
| NEG-1 (`cargo test --locked --features web`) | Only root targets ran: `root_unit` and the doc-test `root_marker`. No core, cli or web test ran. |
| NEG-2 (doc-tests, no `--workspace`) | Only `Doc-tests rs_launch_blueprint` ran. |
| POS-1 (`--workspace --features web`) | `cli_unit`, `core_unit`, `web_unit`, `web_integration_smoke` (`Running tests/web/main.rs` under `rs-launch-blueprint-web`) and `crates/web/src/lib.rs - web_health` all ran. |
| POS-2 (doc-tests with `--workspace`) | Doc-tests ran for all four crates, including `web_health`. |
| CI-OFF (`-p` for the three non-web packages) | No `rs-launch-blueprint-web` target ran. |
| TIER-WEB (`-p rs-launch-blueprint-web --test web`) | `web_integration_smoke` ran alone. |

**Each repair site in the draft:**

| Site | Line | State |
|---|---|---|
| `Justfile` block | 125–141 | All four recipes pass `--locked --workspace --features web`, in both nextest steps and doc-test steps. The lead-in says that the carried `fixture/Justfile` still records the single-package revision 2 layout. |
| F117 | 41 | Names both workspace commands and states the root-only failure. Cites NEG-1, NEG-2, POS-1 and POS-2. |
| F129 | 46 | Revised to `crates/web/tests/web/main.rs` with no file-level cfg, as Codex asked. Gives the executed member-layout selector (TIER-WEB). Says honestly that `binary(web)` ran only in the single-package fixture. |
| F132 | 49 | Names `cargo test --doc --locked --workspace --features web`. States that `--workspace` is load-bearing (NEG-2 against POS-2). |
| F173 | 50 | Separates what was executed in the fixture (the hook, E8) from what was executed under `cargo test` in the workspace (POS-1, POS-2). Hands the full four-package hook run to P07. |
| `BASELINE-REVIEW: F129` | 56 | Uses the member path. Records that `-p` package selection, not a cfg, now excludes the web tests from the feature-off run (CI-OFF). |
| **Local scope** | 157 | Gives package selection as the reason, and gives the runner-up and the tradeoff. States that the feature-off build is CI's property, enforced by the `-p` list. |
| **Layout** | 169 | Web line moved to `crates/web/tests/web/main.rs`, with no file-level cfg. |
| `## Empirical check` | 317–328 | The new probe paragraph and table match the log. The **What the probe does not establish** paragraph lists what was not executed: `cargo nextest run`, `binary(web)`, the filtersets, `--run-ignored`, the hook, and any spawn of `rslbp-serve`. |
| `re-verify:` | 249 | Adds triggers for an R02 member change, a nextest package selection that differs from the probe, and the serve smoke's location. |

**Remaining nextest gap.** The probe ran Cargo, not nextest. The draft says so (line 328) and gives the reason it expects the same result: nextest inherits Cargo's default-member rule, the source Codex cited. The draft also hands the actual nextest run to P07. That makes this an evidence-sufficiency limit, not a contradiction. `--workspace` is nextest's documented package flag, so I do not expect a different result.

## 3. `CONFLICT: R11`: preserved and cleanly discharged

- **The line is byte-identical.** The `CONFLICT: R11 ci-job-structure …` line hashes to `e9b4bc35…` in both revision 2 and the draft.
- **The slot is real.** `research/topics/11-ci-workflow-job-structure/DECISION.md:282` gives R32 "the tier names inside `check`'s test steps". The rule on that row says a tier stays an ordered step of `check` unless it needs its own toolchain, runner or `target/`. The four steps listed under **RESOLVED** are all ordered steps of `check`: provisioning, feature-off nextest scoped by `-p`, feature-on nextest over the workspace, and doc-tests over the workspace. They add 0 jobs and 0 cache-bearing job ids.
- **The owner approval is real.** `docs/superpowers/specs/2026-11-27-rs-implementation-roadmap-design.md:4` reads "Owner-approved (review gate accepted 2026-11-27)". Line 41 assigns Area 8 (Testing & Coverage), including R32's `cargo-nextest` and `cargo test --doc`, to `P07` and `P10`.
- **The registered value is unchanged.** R11's `ci-job-structure` text, at draft line 258, already says "cargo test with the feature off scoped by -p to the non-web packages … cargo test over the workspace with the feature on". The discharge keeps that package scoping and replaces only the runner and the tier steps. That is exactly what the slot delegates.
- **The consequence is closed.** The "stays `in-progress`" consequence in the carried paragraph at line 267 is explicitly discharged at line 265. The **Registered values and this design** paragraph (line 271) agrees.

## 4. Recommendation, principles and agreement level: unchanged

I diffed revision 2 lines 3–341 against draft lines 11–365. The only changed hunks are the ones the revision note lists at line 8: ledger rows F117, F129, F132 and F173; `BASELINE-REVIEW: F129`; the `Justfile` lead-in and body; **Local scope**; the **Layout** web line; `re-verify:`; the `assumes web-extra-surface` line; the inserted **RESOLVED** paragraph; **Registered values**; the probe paragraph; and the cosmetic edit for the supersession-section wording.

The following are byte-unchanged:

- the member table M1–M6, with `cargo-nextest` 0.9.146, `assert_cmd` 2.2.2 and `predicates` 3.1.4
- `.config/nextest.toml`
- the P1–P10 table and the architectural alternatives
- `### Members`
- the agreement and disagreement sections under `## Engines`
- the 271-check evidence table

Adding `--features web` to `test-slow` and `test-live` falls under the disclosed rule that every recipe passes `--workspace --features web` (lines 6 and 157). It does not change any class selection.

## 5. Observations (non-blocking under §7.1)

| # | Severity | Location | Observation | Why it is not BLOCKING |
|---|---|---|---|---|
| O1 | observation | line 190 | Untouched carried prose still says "the serve-binary tests live only in `tests/web/main.rs`, which compiles only with the feature on". That contradicts the revised **Layout** (line 169) and R69 revision 11. | The draft itself says the serve smoke's location is unverified. `CARGO_BIN_EXE_<name>` is set only for the test's own package (line 328), and `re-verify:` makes this a P07 trigger (line 249). No recommendation or coverage claim depends on the stale path. Suggested micro-repair under §7.5, if the controller wants one: change the sentence's reference to point at the line 328 caveat. |
| O2 | observation | line 218 (M2 heading and body) | The heading still reads `cargo test --doc --locked --features web` without `--workspace`. | Its claim, that the doc-test step gets the same selection as the nextest step, is still true: the recipes now pass both flags to both steps. F132 and **RESOLVED** state the full command. This is wording drift only. |
| O3 | publication precondition | lines 6 and 317 | The cited `evidence/2026-11-27-r32-r3-workspace-probe.log` is not yet under the R32 run's `review/evidence/` in this worktree. Today it exists only at `/tmp/p02-flagday/`, with the matching hash. | The bytes are verified. The publishing commit must place the file at the cited path with hash `5a6bd6b5…`. |

## 6. BLOCKING-contradiction sweep (RUNBOOK §7.1, Q23)

I found no contradiction that moves the recommendation, a load-bearing claim, or the evidence for either:

- Local commands, hook, CI steps and ledger rows all agree on `--workspace --features web` for feature-on runs and `-p` for the three non-web packages for the feature-off run.
- The F173 "full suite" claim holds at the package-selection level (POS-1, POS-2). The claim's remaining gaps (nextest form, hook, real dependencies) are stated and assigned to P07.
- The `assumes` lines, the `CONFLICT:` line and the supersession tail are byte-verified.

O1 and O2 are wording drift in untouched carried prose. Under §7.1 they are recorded, not rounded.