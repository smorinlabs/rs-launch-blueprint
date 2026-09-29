# R28 — linter-and-editor-tooling — judgment audit of DECISION.md revision 1

actor: audit-fable-R28-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 90cbe6ce44b7291afdeca2c3a373f6e2d6a584e204672fc8e6f098ff7511759b
verdict: reject
unresolved-findings:
1. JF-1/JF-4/JF-5 — toolchain `channel` misattributed to R42, and R27's open choice presumed.
2. JF-2 — fitness gates 2–6, the maintenance-state verdict and the crate-figure `inapplicable` statements are omitted for every member.
3. JF-2/JF-5 — the prompt's R27 exclude-scope coordination (F100) is not answered.

## Scope and method

- Target: `research/runs/R28/2026-09-26T190151Z-059af1e15f51/review/DECISION.md`, revision 1. `shasum -a 256` recomputed `90cbe6ce…511759b` before any other read; it matches the expected hash.
- Read: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §2–§5; `raw/muse.md` (sha256 `729bc9fc…4c3c8`) and `raw/opus.md` (sha256 `7e7c8f1d…d314`), both matching the hashes the decision records; `manifest.json`; `inputs/EXECUTION.json` and live `research/EXECUTION.json`; `inputs/prerequisites.json`; `docs/port/PARAMETERS.md`; the accepted prerequisite decisions `research/topics/11-ci-workflow-job-structure/DECISION.md` and `research/topics/42-dev-toolchain-provisioning/DECISION.md`; the resolved `research/topics/06-unsafe-code-policy/DECISION.md` (R06, read because the decision embeds R06's values); every `review/evidence/*.log` (spot-checked, not rerun).
- Not read, per the forbidden list: any `review/audit-*.md` and any `review/Rxx-r*-snapshot.md`.
- This audit judges reasoning and fidelity. The empirical audit reruns the scripts.

## Findings (each blocks approval)

### Finding 1 — the toolchain channel is attributed to R42, and R27's open choice is presumed

**Failed claims.**
- `DECISION.md:117`: "A toolchain bump can add warn-by-default lints that turn `-D warnings` red. Because R42 pins the channel, such a bump is a reviewable pull request."
- `DECISION.md:96`: "The toolchain is pinned by R42's `rust-toolchain.toml`."

**Evidence.**
- The accepted R42 decision (sha256 `a2504aa7…f5e1c`, equal to `inputs/prerequisites.json`) says the opposite. `R42 DECISION.md:26`: "The `channel` **value** is R27's through F103/F190 and is not set here." `:302-306` and `:1711-1713` repeat this.
- R42's own reference evidence includes an unpinned channel. `R42 DECISION.md:439`: `cargo-bins/cargo-binstall` commits `channel = "stable"`. `:303-305` records 8 of 9 surveyed repositories pinning an exact version and 1 using `channel = "stable"`.
- R27 (`formatter-config-surface`) is `open` in `research/CLAUDE.md`. The channel is therefore undecided.
- The decision contradicts itself. Its own re-verify line (`DECISION.md:119`) names "R27 changing the `rust-toolchain.toml` channel" as a trigger, which is the correct owner.

**Why it matters.** The maintenance argument at `:117` holds only if R27 pins an exact version. If R27 selects `channel = "stable"`, a new stable release can add a warn-by-default lint. Under R11's `-D warnings`, that lint turns CI red with no code change and no reviewable pull request. The decision therefore relies on a choice another item has not made (JF-5) and cites R42 for a claim R42 disclaims (JF-4).

**Repair.**
1. At `:96` and `:117`, attribute the channel to R27 through F103/F190. R42 commits the file and its `components`; R27 owns the `channel` value.
2. Make the maintenance claim conditional. If R27 pins an exact version, a toolchain bump is a reviewable pull request. If R27 selects `stable`, a new warn-by-default lint can turn `-D warnings` red on an unchanged tree.
3. Hand that consequence to R27 as an input to its F103 choice, without deciding the choice. Keep the existing R27 re-verify trigger.

### Finding 2 — gates 2–6, the maintenance verdict and the `inapplicable` statements are missing for every member

**Failed claim (by omission).** The decision records only "Fitness gate 1 (licence)" (`DECISION.md:7`). It also records advisory 404s and repository figures (`:163-168`). It records none of the following for `clippy`, `rust-analyzer` or CodeLLDB:
- gate 2 (MSRV), stated per member;
- gate 3's `unsafe`-posture limb;
- gate 4's stated platform list;
- gate 5 (default features and async-runtime coupling), even as `inapplicable`;
- gate 6 (binary size and compile time), stated qualitatively or as `inapplicable`;
- the maintenance verdict from the `active | stable-quiet | at-risk | dormant | archived` rubric;
- a statement that crate figures are `inapplicable` for the two editor extensions, with the reason.

**Evidence.**
- `inputs/prompt.md:81`: "Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently."
- `inputs/prompt.md:68` requires the maintenance state "by rubric".
- The data exists in both legs, so this is a carry, not new research:
  - maintenance `active`: `raw/opus.md:266`, `:622`, `:694`; `raw/muse.md:205`, `:577`, `:680`;
  - crate figures `inapplicable` for rust-analyzer, with the reason: `raw/opus.md:624-628`.
- The decision's own re-verify trigger, "CodeLLDB going six months without a release" (`:119`), has no recorded last-release date to measure from.
- Precedent: the published `research/topics/53-config-schema-validation/DECISION.md:19` records a blocking JF-1 for omitting exactly these gate limbs under the same prompt sentence.

**Repair.** Add a per-member gate table to `## Decision`, covering `clippy`, `rust-analyzer` and CodeLLDB. For each member:
- give gates 1–6, answering or marking each `inapplicable` with its reason;
- give the maintenance verdict;
- for CodeLLDB, give the last-release version and date with its endpoint.

Carry the entries from the cited raw lines and label them as carried where this synthesizer did not re-measure them. For gate 2, the floor run (`r28-floor.log` F0–F4) already covers `clippy`. For the two extensions, state why an MSRV does not apply.

### Finding 3 — the R27 exclude-scope coordination (F100) is not answered

**Failed claim (by omission).** `inputs/prompt.md:32`: "F100's exclude-list scope question depends on this item's clippy config shape — coordinate the answer's exclude-scope recommendation with R27's, but do not decide R27's formatter config here." `grep -n 'F100\|exclude' DECISION.md` finds no answer. The only R27 mention is the channel trigger at `:119`.

**Evidence.** The Muse leg answers this directly (`raw/muse.md:416-421`). It says lint relaxation is module-based and formatter excludes are path-based, so F100's exclude-scope question concerns only the formatter side. The decision's own test-relaxation row supports the same conclusion (`:19`, `:94`: "Cargo has no per-path lint table"), but the decision never hands it to R27.

**Repair.** Add one coupling statement, under `## Decision` or `### Principles and implementation`. It should say that R28 defines no path-scoped lint excludes, because relaxation is semantic or module-scoped. F100's exclude list therefore constrains only `rustfmt`, and R27 owns it. Cite `raw/muse.md:416-421` and the test-relaxation evidence T1–T6. Do not decide R27's list.

## JF-1 … JF-10

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (Finding 1) | `:96` and `:117` say R42 pins the channel; `:119` says R27 changes it. Everything else is consistent. The Decision table (`:13-23`), the TOML, Justfile and JSON blocks (`:27-77`), acceptance criteria A1–A8 (`:100-109`) and the Engines rulings (`:186-205`) agree with one another. Minor, non-blocking: case labels collide across logs (autofix F1–F5 vs floor F0–F4; live-figures S1/S2 vs sources S1–S10), and Disagreement 10 cites bare "(F3)" and "(F4)". Context disambiguates them; prefixing the log name would remove the ambiguity. |
| JF-2 questions answered, constraints honoured | **fail** (Findings 2, 3) | All nine prompt questions are answered (`:15-23`, `:83`, `:87-96`). Stable-only is honoured (dylint and marker are excluded on nightly, `:115`). Edition and MSRV are honoured: the floor is executed at clippy 0.1.96 (`r28-floor.log` F0–F4). The ubuntu-latest gap is disclosed honestly (`:170-172`). Missing: gates 2–6, the maintenance verdict, and the `inapplicable` statements (Finding 2); the F100 coordination (Finding 3). |
| JF-3 Engines faithful, disagreements adjudicated | pass | I spot-checked 17 Muse and 17 Opus citations. Each says what the decision attributes to it. Muse `:240-244` holds `all` deny, `pedantic` warn and `undocumented_unsafe_blocks = "warn"`. Muse `:167`, `:423`, `:481`, `:564`, `:704-707`, `:715` and `:802` all match. Opus `:21-23`, `:49`, `:90-94`, `:125-132`, `:159-161`, `:200`, `:207-212`, `:283-292`, `:624-628`, `:728-740`, `:808-815` and `:941-943` all match. Each of the 12 disagreements is resolved on an executed case or a pinned source (L5–L13, T8–T10, S1–S7, V1, V2, V6, F3, F4). The legs' agreement is not used as evidence. Muse's "(or narrower)" at `:423` does not change the fairness of Disagreement 4. |
| JF-4 load-bearing claims trace to evidence | **fail** (Finding 1) | These claims trace correctly: licences Apache-2.0/Apache-2.0/MIT (`r28-live-figures.log` G1–G3); the star and issue figures (`:164-168`, matching the log exactly); L6 downgrade; L9 and L10 exit codes; L12 `--workspace` gap; T9 and T10 blanket-allow masking; S1 bundled server; S2 and V1 `check.command` default `"check"`; S7 ruff's one key; S9 uv's 15 allows; floor F0 toolchain assertion. R11 `:82`, `:268` and `:320`, and R42 `:26` and `:519-521`, say what the decision cites them for, except that R42 `:26` disclaims the channel that `:96` and `:117` credit to R42. |
| JF-5 couplings hand over owned choices | **fail** (Findings 1, 3) | These couplings are handled correctly: R06's levels are left to R06 (`:198`); R16 and R31 are deferred (`:20`); R11 owns the CI spelling (`:61`); R42 owns the invocation (`:52`, `:91`); R49 and R69 own the targets (`:79`); R30 is not re-decided; D-024(4)'s extra extensions are "not decided here" (`:63`). Two couplings fail: the channel maintenance claim presumes R27's undecided choice, and the F100 handoff to R27 is missing. |
| JF-6 assumes lines byte-identical to the live registry | pass | A Python comparison against the value column of `docs/port/PARAMETERS.md` (working tree at audit time) found all six `assumes` lines equal in both the live registry and the run snapshot `inputs/PARAMETERS.md`. The lines are `msrv-policy`, `rust-edition`, `target-os-matrix`, `license`, `ci-job-structure` (8093 bytes) and `package-manager-invocation` (667 bytes). `PARAMETERS.md` has one uncommitted changed line, which is not one of these six rows. `owns: none` matches the index. |
| JF-7 no conflict with accepted or published prerequisite values | pass | R11 is sha256 `410e88e5…418c` and R42 is `a2504aa7…f5e1c`; both equal `inputs/prerequisites.json`, so both are current. The gate command matches R11's two clippy steps with `-D warnings` and `--locked`. `cargo clippy …` in the owning recipe with no alias matches R42. R06, which the decision carried and did not read: its `DECISION.md:23-33` holds `unsafe_code = "forbid"` plus the three clippy unsafe entries at `deny`, exactly the values the fixture used. The decision's request that the controller check this composition (`:132`) is therefore satisfied by this audit. R06 `:42` also independently corroborates L13 (`missing_safety_doc` on by default). R69's `web` feature, declared on one crate, matches the `--features web` spelling (`:61`). No `CONFLICT:` is needed. Finding 1 is a misattribution, not a value conflict. |
| JF-8 evidence scripts exist and counts match | pass | All 9 scripts and 9 logs are present. Per-log `PASS` counts are 13, 11, 5, 5, 6, 10, 7, 2 and 111, matching the table at `:142-152`. Each log ends with `summary: 0 failing case(s)`. The cited cases L1–L13, T1–T11, F0–F4 (floor), F1–F5 (autofix), V1–V6, S1–S10, G1–G3 and C1–C2 each have a matching PASS line whose text agrees with the decision's description. One observation, for the empirical audit: the floor F1 log shows only the feature-off command's output, and its PASS line asserts the `--features web` exit code. |
| JF-9 decision shape follows the contract | pass | The H2s are `## Decision`, `## Parameters`, `## Empirical check` and `## Engines`, in that order. `### Principles and implementation` sits under `## Decision`. A `re-verify:` line is present (`:119`). `## Supersedes` is correctly absent. `narrowed: no` is stated. The F### rows settled are F085, F086, F093, F094, F096, F101, F109, F195 and F196, and all nine prompt rows are present. The OVERRIDE carries `**Argument:**` and `**Options:**`. The BASELINE-REVIEW line uses the required form. |
| JF-10 recommendation follows from the evidence | pass | Each member follows from executed cases or pinned sources: clippy uncontested; the workspace table and a values-only `clippy.toml` (L7, L8); default groups plus five picks over `all`/`pedantic` (L6, L9, L10); an opt-in fix (F2–F5); semantic test relaxation (T1–T11); rust-analyzer alone with the one-key override (V1, S2, S7); CodeLLDB with the `cargo` property (S5, S6, S8). None of the three findings would change a member of the stack. They affect the maintenance claim, the completeness of the per-member record, and one coupling. |

## Controller notes (not findings)

- **Engine provenance.** The decision's statements about the snapshot are accurate. `inputs/EXECUTION.json` has no R28 override, and `manifest.json` records `required_engines` as `["codex","opus"]` and `operations: {}`. Live `research/EXECUTION.json` now carries `"R28": ["muse","opus"]`, and `RUNBOOK.md:73-76` cites owner decision Q17.A (2026-09-27) extending the substitution to R28. Under RUNBOOK §3 ("Changed prompt, policy, parameter or prerequisite → invalidate affected acceptance and revalidate against current inputs"), the controller must re-snapshot or revalidate the policy input and record receipts for both legs before acceptance. This is not a defect in the decision.
- **Independence disclosure.** The synthesizer ran as `claude-opus-5-5` on an Opus seat, not the default Fable context. This auditor runs on the same model ID. Both facts are disclosed for the controller's actor-independence check.
