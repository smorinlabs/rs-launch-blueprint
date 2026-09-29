# R14 — large-file-guard-strategy — judgment audit of DECISION.md revision 2

actor: fable
model: claude-opus-5-5
family: anthropic
decision-sha256: 9c7e39804f80396bad9affe77020c148957cc0fa4535438bb5fc6f702b4daf86
verdict: reject
unresolved-findings: JF4-1, JF4-2, JF2-1

The auditor is a fresh Claude context (Opus family, running the fable judgment seat). It produced neither raw report and did not write the decision. It did not read any `review/audit-*.md` file or `review/R14-r1-snapshot.md`. The decision hash was recomputed with `shasum -a 256` before any other step. It matches the expected value above.

## Scope and method

This audit judges reasoning and fidelity, not execution. It spot-checked the committed evidence and did not rerun it. Files read:

- the decision;
- `inputs/prompt.md`, `inputs/prerequisites.json`, `inputs/EXECUTION.json` and `manifest.json`;
- `research/RUNBOOK.md` §2 and §5;
- `raw/muse.md` and `raw/opus.md`;
- the R11 decision `research/topics/11-ci-workflow-job-structure/DECISION.md` (sha256 `410e88e5…`, which matches `prerequisites.json`);
- the R81 and R17 topic decisions (grep only);
- `docs/port/PARAMETERS.md`;
- every `review/evidence/*.log` and `SHA256SUMS`;
- `review/evidence/check-large-files.sh`;
- the decision-shape parsers in `scripts/research_package.py` and `scripts/research_validation.py`, called read-only.

One public read-only query was made: `gh api repos/github/docs/contents/data/reusables/gated-features/repo-rules.md?ref=18945a31`. It succeeded.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass (with note) | The total of 78 checks equals the per-log PASS counts: guard 29 + inputs 27 + lefthook 4 + merge 4 + pybody 5 + workflow 9. The pybody row now says 5 and names `BODY`. The command comment at line 208 (`pybody checks: 4`) reproduces the log's trailer verbatim, and the table row explains the fifth PASS line. Note: line 196 cites the range `R1`–`R9`, but `r14-rev1-guard.log` has no `R2` (it has `R1`, `R3`, `R3e`, `R4`–`R9`). This is cosmetic, and the count of 29 is still right. |
| JF-2 prompt questions and constraints | **fail** (JF2-1) | HIGH-1 is answered: two tiers, with `L2` and `L3` as evidence. HIGH-2 is answered: 1 MiB, and the Rust binary sizes are carried from the Opus leg. HIGH-3 is answered by the principle table with agreement levels and the py/ts follow-on. MEDIUM is answered: attribute exemption, none shipped, with `I9e` and `I12` as evidence. LOW is answered: one script constant plus `.gitattributes`. Fitness gates 1–6 are each dispositioned at lines 169–180. Note on gate 4: "satisfied as stated in this paragraph" self-qualifies, because the same paragraph says the `ubuntu-latest`/`macos-latest` hosted runs are proposed. I accept that as a note, not a finding. The failure is the engine line: the pinned prompt's `- engines: codex, opus` and the pinned `inputs/EXECUTION.json` require Codex, and the decision never discloses the substitution (finding JF2-1). |
| JF-3 `## Engines` fidelity | pass | D1–D7 match each leg's text. Muse (`raw/muse.md`): dedicated file citing R17 (lines 221, 240); `--diff-filter=A` added-only; all-zero base skip; `docs/assets/` prefix; `{staged_files}` argv (line 34); "accidental drift" provenance; env-overridable threshold (declined at line 256). Opus (`raw/opus.md`): hygiene step (407–417); blob scope; fail-closed; attribute exemption; provenance finding (228–256). Each disagreement is decided by a cited check or by registry text. Both reports pass `scripts/check-answer-shape.sh … bundle` (re-run by this auditor: `OK` twice). The Opus actor `claude-opus-5-5` matches `raw/opus.md:3`. The "42 fixture checks" figure matches `raw/opus.md:36` (`FAILS=0 of 42`). |
| JF-4 load-bearing claims trace to evidence | **fail** (JF4-1, JF4-2) | Verified: the push-ruleset gating quote at pin `18945a31` ("Push rulesets are available for the … Team plan in internal and private repositories…"); the R11 slot-rule quote (`PARAMETERS.md:12`, "a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job"); the secret-scanning carve-out ("no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files"); the 2.08 ratio (1048576 / 503922 = 2.081); `H2`/`H3` under both shells; `H8`/`H9` under `/bin/sh` only (the log agrees with revision 2's corrected prose); `M1a`–`M1d`; `L1a`–`L3`; `W2a` (7 lines). Two claims fail. The headroom sentence at lines 96–97 is broader than both its source and the carried table (JF4-1). The "one value" acceptance row at line 70 cites checks that do not test it (JF4-2). |
| JF-5 couplings | pass | R37 keeps the hook manager: the entry is only "run a command at pre-commit" (line 115). R12 keeps required-check aggregation (line 129). R81 is consumed as evidence only. R11: the `fetch-depth: 0` addition is openly written as a slot note to R11's owner, not a `CONFLICT:` (lines 180–183). A re-verify trigger fires when `hygiene` changes. R11 has previously accepted slot steps added into `hygiene` (R11 decision lines 3, 12, 102). Neither R12 nor R37 has a published decision (only `prompts/` exists), so neither is pre-empted. |
| JF-6 assumes lines vs live registry | pass | All four `assumes` lines are byte-identical to column 4 of `docs/port/PARAMETERS.md` (programmatic comparison: 4/4 `True`). The live registry sha256 `85f998c1…` equals `inputs/PARAMETERS.md` and `manifest.json` `input_hashes.parameters`. The parser `declarations()` returns 4 `assumes` lines and 0 `owns` lines, which matches the empty `- owns:` and `- consumes:` in the prompt. |
| JF-7 no conflict with prerequisite values | pass | The R11 decision's sha256 equals `prerequisites.json` `410e88e5…`. The placement follows R11's registered slot rule. `hygiene` stays free of any `needs:` edge and any `if:` (`W4a`, `W4b`). No consumed value is changed. |
| JF-8 evidence scripts and counts | pass | `shasum -a 256 -c SHA256SUMS` gives 14/14 `OK`. Each cited log has its script. Each log's trailer reads `failures: 0` and `exit=0`. `check-large-files.sh` has 46 lines, sha256 `3492598c…`. `ci.hygiene-with-guard.yml` sha256 is `aa37e31a…`. The `trap` at line 12 removes `$tmp`, `$tmp.sizes` and `$tmp.objs`, as line 254 says. |
| JF-9 decision shape | pass | The H2s are in the order Decision, Parameters, Empirical check, Engines, and none is empty. There is exactly one `### Principles and implementation`. `research_package.reverify_of()` parses one `re-verify:` line at column 0 (line 155). No `## Supersedes` is needed, because R14 is unpublished. |
| JF-10 recommendation follows from evidence | pass | Two tiers, one script, blob scope, fail-closed bases and hygiene placement each follow from executed checks and registry text. The 1 MiB value follows from the carried size profile once JF4-1's scope is restored: the value survives, and only the stated margin was overstated. |

## Unresolved findings

### JF4-1 — the headroom claim is broader than its source, and the carried table contradicts it

**Failed claim** (decision lines 92–97): "every template-shaped repository has zero blobs over 512000 bytes, while legitimately growing generated files reach 503922 bytes (`Cargo.lock`) and 449255 bytes (`CHANGELOG.md`) … 1048576 bytes gives at least 2.08× headroom over every legitimate file observed."

**Evidence.** The source sentence, `raw/opus.md:373–375`, is qualified: "at least 2.08× headroom over every legitimate file observed **in any template-shaped repository and over every growing generated file observed anywhere**." The decision dropped both qualifiers. The unqualified form is false against the 14-repository table that the decision carries (`raw/opus.md:149–163`):

- `sharkdp/bat` `assets/syntaxes.bin` is 1,012,454 bytes and marked "intentional". Its headroom is 1.036×, not 2.08×.
- The Opus leg states that "every file above 1 MiB in the table is intentional" (`raw/opus.md:172`). Blobs in cargo (2,449,408 B), typos, uv, ruff, bevy and zed are therefore legitimate, and their headroom is below 1×.

"Template-shaped" is also never defined in the decision. The Opus table's own Shape column labels bat, cargo, typos, uv and ruff as `CLI`, and bat has one blob over 512000 bytes. "Every template-shaped repository has zero blobs over 512000 bytes" is therefore true only of the seven repositories the Opus leg selected at `raw/opus.md:166–168`. A minor related point: the pointer "`### Sources` in `raw/opus.md`" (line 93) leads to a line that defers to `### Landscape` (`raw/opus.md:940`), which is where the profile table lives.

**Repair.** This is a text edit only; no evidence moves and the recommendation stands. Rewrite lines 92–97 to restore the leg's scope, for example: "the seven repositories the Opus leg classes as template-shaped (tokio, axum, clap, ripgrep, prek, pydantic-core, crates.io; `### Landscape` in `raw/opus.md`) have zero blobs over 512000 bytes … 1048576 bytes gives at least 2.08× headroom over every blob in those seven repositories and over every growing generated file in the 14-repository profile. Intentional assets near or above the limit (bat `syntaxes.bin` 1,012,454 B; cargo, typos, uv, ruff, bevy and zed above 1 MiB) are the `large-file-ok` or LFS case, not headroom."

### JF4-2 — the "one value" acceptance criterion cites checks that do not test it

**Failed claim** (decision line 70, principle "One value, both tiers, all repos"): "The byte value exists in exactly one file; hook and CI report the same limit (`H3`, `R1`)."

**Evidence.** `H3` is the staged-mode boundary: "1048577 fails" (`r14-rev1-guard.log`). `R1` is a range-mode add-then-delete case ("added-then-deleted fails") at a size above the limit. Neither check shows that the value exists in one file. Neither shows that range mode reports the same limit, because no range-mode boundary case exists. The property does hold by construction:

- `grep -c 1048576` gives 2 in `check-large-files.sh` (a comment at line 6 and `max=1048576` at line 10);
- the same grep gives 0 in `ci.hygiene-with-guard.yml`;
- both modes read `max` from the one script.

However, the decision's cited evidence does not show this. Line 257 also claims that "a one-file `grep` can prove" it, and no committed check runs that grep.

**Repair.** Either cite `check-large-files.sh:10` (`max=1048576`) and the zero-occurrence result for `ci.hygiene-with-guard.yml` in place of `H3`/`R1`, or mark the criterion as proposed for P03 (a `grep` check plus a range-mode 1048576/1048577 boundary case). Keep `H3` as evidence for the hook half only.

### JF2-1 — the engine substitution is undisclosed against the pinned inputs

**Failed claim** (decision lines 13–15 and 226–228): "Item kind `bundle`, effort tier `focused` (two engines)." and "**Reports.** `raw/muse.md` (actor `research-muse-…`, Muse/Meta) and `raw/opus.md` …". The decision presents Muse as a matter of course.

**Evidence.** The run's pinned inputs require Codex:

- `inputs/prompt.md:22` reads `- engines: codex, opus`;
- `inputs/EXECUTION.json` `items.R14` is `{'tier': 'focused', 'engines': ['codex', 'opus'], …}`, with no `engine_overrides` entry for R14;
- `manifest.json` `required_engines` is `["codex", "opus"]`.

The substitution's authority exists only in live files outside the run:

- the live `research/EXECUTION.json` has `engine_overrides.R14 = ["muse", "opus"]`;
- `research/RUNBOOK.md` §2 records it as owner decision Q17.A, dated 2026-09-27, which is later than this run and this decision (2026-09-26);
- the live topic prompt differs from the pinned `inputs/prompt.md` in exactly the `- engines:` line and one added sentence.

The decision's "Inputs read" line cites the pinned prompt but never reconciles its engines line. RUNBOOK §5 requires that acceptance check "current inputs". As written, a reader cannot tell from the decision why no Codex report exists or whether the Muse leg satisfies the tier.

**Repair.** Add one sentence to the actor paragraph or to `**Reports.**`. It should say that the pinned `inputs/prompt.md` and `inputs/EXECUTION.json` name `codex, opus`, and that Muse replaced Codex under the `engine_overrides` pilot (live `research/EXECUTION.json` `R14: ["muse", "opus"]`, RUNBOOK §2, owner decision Q17.A). Controller note, not the synthesizer's repair: the run's pinned inputs and `manifest.json` `required_engines` still say Codex, and Q17.A's recorded date (2026-09-27) postdates the run. The controller should reconcile both before acceptance.

## Notes that are not findings

- The `R1`–`R9` range cites a nonexistent `R2` (JF-1). This is cosmetic.
- The gate 4 wording self-qualifies (JF-2).
- The `fetch-depth: 0` edit to R11's `hygiene` checkout is a slot note that R11's owner must accept. The Opus leg's option (b), where the step deepens its own clone, is a fallback the decision could name if the owner declines. It is not required.
