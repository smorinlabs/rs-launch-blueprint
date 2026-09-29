actor: fable-judgment-r14-2026-09-26T190144Z-53ff8e94fbd8-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: ea3fb15b674185126831ecb03870b236da7c4829a0a1b170e2a7320b452570f5
verdict: reject
unresolved-findings:
1. JF-9 — the `re-verify` line breaks the published decision contract. Failed claim (DECISION.md:145-148): "**re-verify:** when R37 selects the hook manager; when R11's `hygiene` job or / R12's required-check set changes; ... otherwise by 2027-03-26." Evidence: RUNBOOK §5 requires `re-verify: <date or event>`. `scripts/research_package.py:156-159` collects only lines whose stripped text starts with `re-verify:` and requires exactly one, written as `re-verify: <value>`. `scripts/research_validation.py:525-527` applies the same rule. This line starts with `**`, so the packager finds zero triggers and refuses the decision. Even without the bold markup, the value is wrapped over four lines, so only the first line would be read. None of the 47 published `research/topics/*/DECISION.md` files uses the bold form. Repair: replace lines 145-148 with a single unbolded line: `re-verify: when R37 selects the hook manager; when R11's hygiene job or R12's required-check set changes; when the template's Cargo.lock or CHANGELOG.md passes 700000 bytes; if GitHub makes push rulesets available to public repositories; otherwise by 2027-03-26`.
2. JF-1 / JF-8 — the stated check total does not match the table. Failed claims: "78 checks pass, 0 fail" (DECISION.md:184) and the table row "`r14-rev1-pybody.sh` ... | 4 pass (`r14-rev1-pybody.log`)" (DECISION.md:191). Evidence: the six table rows give 27 + 29 + 4 + 4 + 9 + 4 = 77. The logs contain 78 PASS lines. `r14-rev1-pybody.log` holds 5 of them: `BODY PASS verbatim py body` plus `P1`-`P4`. Its own summary line nevertheless says `pybody checks: 4`, because `r14-rev1-pybody.sh:23` prints BODY outside the counter. So the total (78) and the pybody row (4) cannot both be right as written. Repair: either change the pybody row to "5 pass (BODY verbatim-extraction check plus `P1`-`P4`)", or change the total to 77 and state that BODY is a precondition, not a counted check. Make lines 141, 184, 226 and 248 all use the corrected figure.
3. JF-4 / JF-8 — the two-shell execution is claimed for cases that ran under one shell. Failed claim (DECISION.md:168-169): "executed under macOS `/bin/sh` (bash 3.2) and `/bin/dash` (Ubuntu's `/bin/sh`) (`H1`–`H10`, both shells)". Evidence: `r14-rev1-guard.log` records `H1`-`H7b` and `H10` under both `[sh]` and `[dash]`. `H8` (the LFS pointer) and `H9` (the gitlink skip) appear only as `H8[sh]` and `H9[sh]`, and `r14-rev1-guard.sh:69` and `:80` run them with `/bin/sh` only. This sentence carries the `target-os-matrix` portability argument, so it must match what ran. Repair: write "(`H1`–`H7b` and `H10` under both shells; `H8` and `H9` under macOS `/bin/sh` only)", or add `[dash]` runs of H8 and H9 to the guard script and update the log counts.

# R14 judgment audit — revision 1

**Verdict: reject.** The recommendation's reasoning is sound, and the engine adjudication is faithful and well evidenced. The rejection is on form and count fidelity: one defect blocks publication (finding 1), and two count or labeling claims do not match the evidence files (findings 2 and 3). All three repairs are text edits. None of them changes the recommendation. A revision 2 that makes exactly these edits should pass this seat.

Target verified before any other step: `shasum -a 256 review/DECISION.md` gave `ea3fb15b674185126831ecb03870b236da7c4829a0a1b170e2a7320b452570f5`, which matches the expected hash. `review/evidence/SHA256SUMS` verifies all 14 files as `OK`.

## Inputs read

- The decision (revision 1).
- `inputs/prompt.md` (sha256 `2b501625…`, matching `manifest.json` `input_hashes.prompt`).
- `inputs/prerequisites.json`: R11 decision `410e88e5…`. The live `research/topics/11-ci-workflow-job-structure/DECISION.md` recomputes to the same hash.
- `research/RUNBOOK.md` §2 and §5.
- `raw/muse.md` and `raw/opus.md`, in full where load-bearing.
- `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md:49,176` and `docs/port/DIVERGENCE-ANALYSIS.md:96-98`.
- The R17 and R81 topic decisions.
- The R11 fixture `ci.candidate.r2.yml` (sha256 `4eb498c2…`, matching the hash the Opus leg cites).
- All evidence scripts and logs. They were not rerun; the empirical seat reruns them.
- `research/EXECUTION.json` `engine_overrides.R14 = [muse, opus]`. This confirms that the Muse leg replaces the prompt's `engines: codex, opus` under Q17.A.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | **fail** (finding 2) | The recommendation, principles table, migration list, placement and follow-on text agree with one another. The check-count total (78) contradicts the table rows (77). |
| JF-2 prompt questions and constraints | pass | HIGH-1: hook tier alone is rejected; `--no-verify` bypass is shown by `L2` and caught by `L3`. HIGH-2: 1 MiB over 500 KB, with the scope-then-value argument. HIGH-3: the principles table with agreement levels, plus the py/ts follow-on with rationale. MEDIUM: no shipped prefix, per-path attribute (`I9e`, `I12`). LOW: one script plus `.gitattributes`. R37 and R40 scope is respected; the hook entry is manager-agnostic. There is no prior-art citation from the owner's other Rust repositories. Fitness gates are addressed as `inapplicable`, with reasons (DECISION.md:162-173). The survey and landscape figures are carried from `raw/opus.md` with the retrieval date. |
| JF-3 Engines fidelity and adjudication | pass | D1-D7 match the legs. D1: Muse `raw/muse.md:221-224,240` (dedicated file, R17 precedent) versus Opus hygiene step. D2: Muse `--diff-filter=A` (`:95`) versus Opus blob scope. D3: Muse's skip branch versus Opus fail-closed. D4: `docs/assets/` (`:115`) versus attribute. D5: `{staged_files}` versus `--staged`. D6: Muse "accidental drift" (`:103-106`) versus Opus provenance. D7: evidence bases. Each verdict cites executed or registry evidence. D1 relies on the live R11 value text: "no ... secret-scanning ... job, which are separate workflow files" and "a check that compiles nothing is a step of hygiene". Both are verified in `PARAMETERS.md:12`. Muse's valid point (a separately requireable check identity) is correctly handed to R12. |
| JF-4 load-bearing claims trace | **fail** (finding 3) | Spot-checks that passed: push-ruleset gating (`github/docs@18945a31` `repo-rules.md` read now: "Push rulesets are available for the Team plan in internal and private repositories…"); py `docs/assets` has 0 entries at `b08bccfb`; ADR 0018:88-90; `fe96899^:.pre-commit-config.yaml` bare `check-added-large-files`; ts `lefthook.yml:34-35` comment; the 2.08× headroom figure (1048576 / 503922 = 2.081); the reference-script provenance (diff against the Opus listing is exactly the one `trap` line). Failed: the "H1–H10, both shells" claim. |
| JF-5 couplings | pass | The hook manager is left to R37, required-check identity to R12, and the job graph to R11. `fetch-depth: 0` on `hygiene` is raised as a slot note to R11's owner, not decided as a parameter change. R11's value fixes `plan`'s depth, not `hygiene`'s. R81 is only read. |
| JF-6 assumes lines | pass | All four values are byte-identical to `PARAMETERS.md` rows 7-10, extracted and compared field by field. |
| JF-7 prerequisite conflict | pass | The R11 hash is current. The composed file changes R11's fixture by 7 added lines and 0 removed (diff read). It keeps `hygiene` free of `needs:` and `if:` gates, and it adds no trigger path filter. It conflicts with no accepted value from R11, R17 or R81. |
| JF-8 evidence scripts and counts | **fail** (findings 2, 3) | Every cited log has its script. All 14 digests verify. Per-log PASS counts: inputs 27, guard 29, merge 4, pybody 5, workflow 9, lefthook 4; total 78. The pybody row and the two-shell claim do not match the files. |
| JF-9 decision shape | **fail** (finding 1) | The required H2s are present in order (`Decision`, `Parameters`, `Empirical check`, `Engines`). There is no `Supersedes`, which is correct for a first publication. The `re-verify` line is bold and wrapped, so the packager's `re-verify:` rule rejects it. |
| JF-10 recommendation follows from evidence | pass | Blob scope is justified by `M1a`-`M1d` together with the merge-commit policy. The 1 MiB value follows from the blob-scope choice plus the carried size profile, and the decision labels that profile as carried and gives its confidence as medium. Fail-closed handling follows from `P2`, `R3` and `R7`. The hygiene placement follows from the registry text. Confidence levels match the evidence. |

## Observations (not findings)

- In the composed file, the guard step comes after `cargo fmt --all --check` and has no `!cancelled()` condition. A formatting failure therefore hides the guard's own verdict for that run. The merge is still blocked, because `hygiene` fails either way. So the claim "coverage equals a dedicated file's" holds for blocking, but not for per-check reporting. P03 may want `if: ${{ !cancelled() }}` on the guard step.
- The decision does not state that the Muse leg replaces the prompt's `codex` engine. The substitution is policy (`EXECUTION.json` `engine_overrides.R14`, RUNBOOK §2, Q17.A), so this is controller provenance, not a defect in the reasoning.
