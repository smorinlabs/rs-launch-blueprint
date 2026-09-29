# R30 type-check-gate — judgment audit, decision revision 3

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 163ba8334d75debd3add4d620269e8608bf2164c5b0cd6fc464147fca9eb6cf5
verdict: approve
unresolved-findings: none

Target: `research/runs/R30/2026-09-26T190200Z-c5c1105074c1/review/DECISION.md`, revision 3. The sha256 was recomputed with `shasum -a 256` before reading and again before writing. Both values equal the expected `163ba833…6cf5`.

This audit judges reasoning and fidelity, not execution. Its read set was the decision, `inputs/prompt.md`, `research/RUNBOOK.md` §2 and §5, `raw/muse.md`, `raw/opus.md`, the evidence scripts and logs under `review/evidence/`, the R11 `DECISION.md` (the consumed prerequisite), the R42 `DECISION.md`, the R27 prompt, and the live `docs/port/PARAMETERS.md` and `research/EXECUTION.json`. Under the auditor contract this seat read no `review/audit-*.md` and no `review/R30-r*-snapshot.md`. It ran no runner command, made no git write and called no paid API. The only command it ran on the evidence was `shellcheck`, which is read-only.

## What this seat could not verify

- **Figures from the revision-2 empirical audit.** The decision quotes figures from `review/audit-claude.r2.md` in D5, in gap 10 and in `## Empirical check` (line 262): 0.56–2.41 s for `H3a`–`H3f`, 11.36 s cold, at a 1-minute load of about 250. This seat was forbidden to read that file, so none of these figures was checked. They are not load-bearing. They only widen the recorded variance.
- **Revision 2's lightly loaded figures.** D5 says "The resolution rests on the lightly loaded figures". Those figures are revision 2's 0.26–0.50 s at a load of about 5. They survive only in `review/R30-r2-snapshot.md`, which this seat was also forbidden to read, and not in this revision's committed logs. The sub-second conclusion can still be traced without them. This run's own `H3e` took 0.69 s and `H3f` took 0.49 s through the installed hook (`r30-wiring-cost.log:168`, `:184`), under the heavier load of 75–102. Opus's real-dependency E9 measured 0.13–0.39 s warm (`opus.md:293`, verified). JF-4 passes on that basis, not on the snapshot.

## Checks

**JF-1: internal consistency. Pass.**
- Revision 3 changes only the channel routing, the policy re-freeze and the figures. The three revision notes, the stack table, the hand-offs, `## Parameters` (`msrv-policy`), D1 and the re-verify line all route the channel to R27 (F103). R42 is left with the file and its components (lines 43, 51, 178, 226–229, 232, 247, 369).
- The figures agree wherever they appear. The F106 row, option A2, the scope bullet, D5 and the excerpt block give 0.12–0.14 s warm no-op, 0.22–0.49 s incremental, 16.01 s cold, 0.49–0.69 s per hook commit and 0.62 s for clippy after the gate.
- The component counts add up. `rust_2018_idioms` has five lints: three added and two already hard errors in edition 2024 (lines 181, 248). The file says "eight scripts" for shellcheck and "seven" for the evidence pass, which matches the 8 `.sh` files, 7 of them evidence scripts plus `r30-inputs.sh`.
- One wording point, not a defect: D1 says that on the 1.96 floor the variable "does nothing and prints nothing". The floor case prints the ordinary warning (`r30-severity.log:21-28`); what it never prints is any notice about the variable. The meaning is clear from `W1`.

**JF-2: every prompt question answered and every constraint honored. Pass.**
- All eight questions are answered:

  | Prompt question | Where the decision answers it |
  |---|---|
  | HIGH: engine and a distinct step | F105 row and option table |
  | HIGH: second checker | F108 row |
  | HIGH: strictness analogue | F110 row and member 4 |
  | HIGH: principles and agreement level | `### Principles and implementation`, with an agreement table covering all eight rows |
  | MEDIUM: suppression, including how clippy differs | F111 row, member 5, the clippy `allow_attributes*` hand-off to R28 |
  | MEDIUM: severity | F112 row, member 3, D1 |
  | MEDIUM: scope | F113 row, `S1`–`S7` |
  | LOW: hook tier | F106 row, D5 |

- The constraints hold:
  - **Stable only and edition 2024:** only stable toolchains were run, and the entry was checked against the 2024 edition's hard errors (`L4`).
  - **MSRV:** the gate is green on the pinned 1.96.0 rustc (`S9`, `W4`, `L1f`).
  - **Both CI operating systems:** only macOS was executed; `ubuntu-latest` is labelled proposed (criterion 8, gap 2).
- The out-of-scope items are handed off, not decided: clippy and rustfmt surfaces to R28/R27, F109 to R28, CI job shape to R11.
- **Fitness gates.** The decision never uses the words "fitness gate" or "inapplicable", although the published R04, R06 and R07 decisions do. The RUNBOOK §5 `DECISION.md` contract does not require the gate walk. The prompt's instruction to state `inapplicable` applies to the raw answer template, and the raws carry it (`muse.md:3`: "no crates.io / GitHub / RustSec figures apply"). No crate is added. The one gate with force is MSRV (gate 2): `build.warnings` needs Cargo ≥ 1.97 against the 1.96 floor. It is decided explicitly under member 3, D1, `## Parameters` (`msrv-policy`) and the R27 hand-off, with `RUSTFLAGS` recorded as the runner-up. Gate 4 (both OSes) is criterion 8. This audit treats the omission of the labels as acceptable. It is not a defect in substance.

**JF-3: `## Engines` states each engine's position faithfully and settles every disagreement with evidence. Pass.**
Spot-checked citations to the raw reports:
- Muse puts `RUSTFLAGS="-D warnings"` on the CI steps (`muse.md:33`, `:121`).
- Muse's local recipe uses a `ci` parameter or environment passthrough (`muse.md:161`, `:259`).
- Muse scopes the feature-off leg with `-p` "per R11" (`muse.md:33`, `:221`, `:259`).
- Muse denies `unexpected_cfgs` with `check-cfg` (`muse.md:125`, `:145`).
- Muse places the gate at pre-push running `just typecheck`, with a cold time it only expects to be "minutes-scale" (`muse.md:185`, `:225`, `:262`, `:276`).
- Opus runs one `--all-features` command (`opus.md:152`, `:253`).
- Opus says R42 forbids a runner prefix (`opus.md:258-259`).
- Opus's E9 and E10 timings (`opus.md:293-294`) and its E13 example (`:297`).
- Opus ran the floor as `rustup run 1.96.0 cargo` (`opus.md:14`).

All of these match the decision's descriptions. Each of D1–D8 is settled by named executed cases:
- D1: `W1`, `W3b`–`W3e`, and the Cargo guide lines 209–210.
- D2: `L1b`, `W2`.
- D3: `S5`, `S6`, and R11 line 221, where the `-p` scoping belongs to the feature-off *test* step (verified).
- D4: `L0a`, `L1a`, `L2a`–`L2c`, `L3`.
- D5: `H2`, `H3`.
- D7: `X8b`, `X9a`/`X9b`, `X10a`/`X10b`.
- D8: the floor rerun on the pinned rustc (`L1c`, `X11`, `S8`, `S9`).

D6 is correctly left undecided, because the question belongs to R37 and R42. D9 lists the Muse claims that were not verified and states that none of them decides anything.

**JF-4: every load-bearing claim traces to a cited log line, figure or source. Pass.**
- **Timing lines.** `r30-wiring-cost.log` lines `:35` (16.01 s), `:42` (0.14 s), `:49` (0.12 s), `:61` (0.29 s), `:70` (0.22 s), `:82` (0.49 s), `:165`/`:181` (lefthook "done in 0.14/0.39 seconds"), `:168` (0.69 s), `:184` (0.49 s) and `:200` (4 units, 0.62 s) all match the decision exactly.
- **Workspace size.** The synthetic workspace has 24 dependency crates and 8,664 generated lines (`r30-wiring-cost.log:219`).
- **Upstream quotations.** `r30-upstream-docs.log` shows each quoted line at the cited number:
  - the Cargo guide, `continuous-integration.md:209-210`;
  - Cargo's changelog: 1.97 at `:394`, the `build.warnings` stabilization at `:399`, 1.74 at `:4151`, the `[lints]` stabilization at `:4156`;
  - the manifest reference, `manifest.md:532`, `:553-554`;
  - the lint-levels page, `levels.md:37`, `:278`;
  - rust-analyzer's `config.rs:787`, `:847`, `:878`, `:884`, `:891`, `:901`, `:962`.
- **R11, R42 and R27 citations.**
  - R11 line 221 (the feature-off test scoping), line 227 (the floor job runs one `check`-style command rather than `check`'s step list), line 268 (clippy `-D warnings`), and lines 278/286 (the R30 slot: "compiling → an ordered step of `check`").
  - R42 line 26 ("The `channel` **value** is R27's through F103/F190 and is not set here"), line 439 (the reference implementation commits `channel = "stable"`) and line 458 ("channel per R27").
  - The R27 prompt, line 14 ("The file's `channel` and `components` are decided here (F103)").

  All were read and match.
- **Hook-tier cost.** The cost claim is load-bearing, and its basis is recorded above under "What this seat could not verify".

**JF-5: every coupling hands other items their owned choices without deciding them. Pass.**
- The R27 hand-off repairs the prior JF-5 finding. The Cargo ≥ 1.97 requirement constrains R27's options; it sets no channel value. The decision records a fallback (the runner-up `RUSTFLAGS="-D warnings"` in the same three places) if R27 cannot meet it, leaves "pin or track `stable`" explicitly to R27, and adds re-verify triggers for both outcomes.
- R42 keeps the file and its components, consistent with R42 line 26. The R27 prompt also claims `components` "in coordination with R42"; that overlap lies between R27 and R42, and this decision correctly takes no side.
- The R28 items are framed as "whether to": the rust-analyzer features setting, `cargo.targetDir`, the `allow_attributes*` lints, and whether clippy keeps `-D warnings`.
- R37 gets the form of the hook jobs under the `H1` invariant; R40 gets the `allow(warnings)` text check; R32 gets doctests.
- The CI steps are proposed as slots inside R11's `check` job and do not reshape the job.

**JF-6: `assumes` lines byte-identical to the live registry. Pass.**
Each of the five `- assumes` lines (`msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `ci-job-structure`) was compared programmatically, as an exact string, with the value cell of the live `docs/port/PARAMETERS.md`, and all five are equal. They also equal the values in `inputs/parameters.json`. One observation about repository state, not a defect in the decision: the live `ci-job-structure` row is a working-tree edit, and `HEAD` still shows `—`. The R11 topic files are untracked, so R11's publication is not yet committed. Gap 11 covers the same situation for `EXECUTION.json` but not for `PARAMETERS.md`. This pass is against the working tree as the live registry at 2026-09-27.

**JF-7: no conflict with accepted or published prerequisite values. Pass.**
- R11 `DECISION.md` sha256 is `410e88e5…418c` and its `acceptance.json` is `774f7649…eac1`. Both match the decision and `prerequisites.json`.
- The design follows R11: ordered steps of `check`, `--locked` on every cargo command, `!cancelled()` on every cargo step, no new job id.
- R42's published `package-manager-invocation` value is equal in the frozen and live files. The recipe and hook call bare `cargo check`, which complies.
- R69's `web-extra-surface` value (`otel = ["web", …]`, `metrics = ["web", …]`) supports the argument that two configurations suffice.
- No `CONFLICT:` line is needed, and none is raised.

**JF-8: evidence scripts exist for every cited log, and the claimed counts match. Pass.**
- There are eight `.sh`/`.log` pairs. Counting `PASS` lines gives scope 20, severity 17, suppression 16, lints 14, wiring-cost 17 and wiring-severity 8, each ending `failures=0`.
- `r30-upstream-docs.sh` passes 22 patterns (5+2+4+2+2+7) across 6 files, with no `MISSING` line.
- `r30-inputs.log` ends `PASS=43 FAIL=0`. It includes `I-r42-channel`, `I-r27-f103`, `I-jf5`, `I-eao-r30`, `I-fig-all` and `I-fig-stale`.
- The header timestamps are 07:24:53Z first and 07:25:58Z last, as stated.
- `CARGO_HOME=/tmp/cargo-s34-R30-r3` is on line 2 of exactly the five logs named.
- `shellcheck *.sh` is clean.
- The input hashes match the decision's table for the prompt (`2c83ee19…`, equal to the live prompt), the policy (`acdcbfff…`, equal to the live `EXECUTION.json`), the raws (`7661d2e3…`, 301 lines; `bbda3eff…`, 1130 lines), `parameters.json` and `prerequisites.json`.
- The live policy has 50 `empirical_auditor_overrides` entries, including `R30 → claude`, and `engine_overrides.R30` and `items.R30.engines` are both `["muse","opus"]`.
- RUNBOOK lines 73–76 list R30 under Q17.A, and lines 98–104 define the empirical-audit override.

**JF-9: the decision's shape follows the published contract. Pass.**
- The H2s are, in order, `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`.
- `## Decision` carries the recommendation, the version floor (Cargo ≥ 1.97; no crate), the settled rows F105–F108 and F110–F113, `### Principles and implementation`, and a `re-verify:` line.
- `## Empirical check` gives the toolchains and OS, the commands, the working directory (`mktemp -d` scratch) and the observed output.
- `## Supersedes` is correctly absent, because nothing for R30 has been published.

**JF-10: the recommendation follows from the assembled evidence. Pass.**
- `cargo check` as the engine follows from type errors being hard errors in every cargo command (`S1`–`S6`, `H4b`).
- Two feature configurations follow from `S5` and `S6`.
- `build.warnings` over `RUSTFLAGS` follows from `W1` and `W3`, and from the Cargo guide. Its floor inertness is contained by R11 line 227 and by the R27 constraint.
- `#[expect]` scoped with `cfg_attr` follows from `X8b` and `X9`.
- Pre-commit follows from the measured warm cost. The decision states the variance with load honestly and keeps pre-push as the runner-up under a concrete condition.
- The majority-practice departure (option B, clippy as the gate) is argued on preserving the principle plus the measured 0.62 s reuse cost. It is not argued from agreement.

## Findings

None.
