actor: audit-fable-r61r6-2026-09-22
model: claude-opus-5-5
family: anthropic
decision-sha256: 1ecf07f26d946e98c77a20d020fcd094ea0b53362965e7406cb313ac3d053c0c
verdict: reject
unresolved-findings:
- F1 (JF-2, JF-4): P5's must-agree cell fixes exit `130` for py, ts and rs, and the py pin exits `4`.

# Judgment audit — R61 `interactive-prompts`, DECISION.md revision 6

Target: `research/runs/R61/2026-09-17T020714Z-98ef5e1e7d37/review/DECISION.md`.
The sha256 was recomputed with `shasum -a 256` before reading. It matches the expected value `1ecf07f2…053c0c`.

Read for this audit: the decision; `inputs/prompt.md`; `research/RUNBOOK.md` §3–§5 (the roles, the decision H2 contract, and the audit contract); both pinned raws (`raw/codex-a22fcc08….md` and `raw/opus-162d21ed….md`, each hash recomputed and each byte-identical to `codex.md` and `opus.md`); the prerequisite `research/topics/67-error-and-exit-code-contract/DECISION.md`; and the coupling passages in the R01, R49, R60, R65 and R69 decisions. I also read the py pin `b08bccfb` and the ts pin `cb1cbcb2` through `git show` in `/Users/stevemorin/c/{py,ts}-launch-blueprint`, the py checkout's installed `click` 8.4.2 source, the live registry `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md`, `docs/port/DIVERGENCE-ANALYSIS.md:199`, and the evidence directory.

I did not read any prior `audit-fable*.md`, any `audit-claude*.md`, or any `R61-r*-snapshot.md`. I made no git writes, ran no runner commands, and called no paid API.

## Checks

| Check | Result | Evidence |
|---|---|---|
| JF-1 internal consistency | pass, with one inconsistency carried into F1 | Line spot-checks agree: 35 − 11 = 24 packages; the 1.96 floor minus 1.85.0 leaves 11 minors; 109 + 4 = 113 assertions. The `--dry-run` order is consistent across the precedence ladder, the class table, the outcome table, criterion 10 and U1. Criteria 1, 2, 5, 6 and 10, the paragraph after the criteria, and U1/U5 agree on the `ScriptedPrompter` instrument and on the PTY variant. One inconsistency remains. The decision states that the cross-repo rule "fixes that the run refuses, not the integer it exits with" (line 112), and it moves P3's exit integer to the may-vary column. P5, two rows later, still fixes an integer across all three repos. That is F1. |
| JF-2 every question answered, every constraint honoured | **fail (F1)** | All seven prompt questions are answered: the single crate; name/value and the output stream; principles; non-TTY behaviour; defaults and retry; `--dry-run`/`--yes`; and one `--no-input` behaviour, which is the class rule. The out-of-scope items are respected: R60's parser, R67's F299 exit code, and no owner Rust prior art. The HIGH principles question also requires distinguishing "missing capability or accidental drift from justified ecosystem differences". P5 asserts a three-repo agreement that py does not meet, and it records no drift or missing-capability note (F1). |
| JF-3 `## Engines` fidelity and adjudication | pass (non-blocking note N1) | The Codex raw recommends `dialoguer = { version = "0.12.0", default-features = false }` (`codex.md:31`) and makes it conditional on `cargo deny` because of the RustSec 404. It says "`dialoguer` itself also rejects a nonterminal `Term`" (`:17`) and emits the `BASELINE-REVIEW: F360` line (`:25`), which the decision quotes with only the stated rendering changes. Codex excludes `cliclack` on the MSRV and platform-test gates (`:59`). The Opus raw uses `OV-01` (`opus.md:236`), lists `bitwarden/clients` at 13,792 stars (`:74`), and states the dry-run-after-consent sentence (`:192`). All five disagreements are adjudicated with evidence: the crate; delegating the gate (settled by execution, with case B PASS at `r61-claims-r1.log:341-344`); advisories (the positive control); F360; and the gate-2 classification. |
| JF-4 load-bearing claims trace to sources | **fail (F1)**; all other spot-checks pass | py pin: `config.py:82-83` (`if assume_yes: chosen = current`), `:94` (`click.prompt`), `:101` and `:181` (`if dry_run:`), `:184` (`return`), `:188` (the read), `:196` (`and not confirm(`) and `:202-203` (`SystemExit(int(ExitCode.INTERRUPT))`); `options.py:263-278`; `errors.py:41-42` (`CONFIG = 1`, `AUTH = 2`), `:45` (`INTERRUPT = 5`) and `:55` (`PLBP004`). ts pin: `projects.ts:146` (comment), `:147` (the conjunction), `:164-166` (`else { selected = projects; }`) and `:170-174` (the empty-selection no-op); `adapters.ts:23` (`export type Prompter`) and `:41` (`realPrompter`). R67: `RSLB205`, `RSLB903`, `RSLB501` → 5, the no-prompt-local-handler rule (`:304-306`), "product question for R61" (`:303-304`), and `:408-411`. `DIVERGENCE-ANALYSIS.md:199` records harmonize = `partly`. Ledger rows F276/F279/F280/F360 are `DIVERGENT` under R61, and F277/F278 are `ADOPT`. All of these read as cited. P5's cross-repo `130` does not trace (F1). |
| JF-5 couplings hand over owned choices without deciding them | pass | R02 owns crate placement. The decision marks the paths as illustrative, places the dependency on "whichever crate hosts the CLI binary target", and adds a re-verify trigger; this matches R69:222 and R69:1406. R65's chain is consumed rather than re-decided. R67 rows are bound, none is added, and no `CONFLICT:` is raised. R01's `http-transport-injection-seam` value is cited accurately (`R01 DECISION.md:422`). The `no_input` field on R60's `GlobalArgs` is F275's `COMMON → REUSE` flag, which no research item owns; R60 declares no `--no-input`. |
| JF-6 `assumes` lines byte-identical to the live registry | pass | Every `- assumes` value for `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` equals column 4 of `docs/port/PARAMETERS.md:7-10` and `inputs/parameters.json`. There are no `owns` lines, which is correct because the prompt's `- owns:` is empty. No unpublished revision is presented as a registry value. |
| JF-7 no conflict with accepted/published prerequisite values | pass | The live R67 `DECISION.md` sha256 `16947ab1…9497` and `acceptance.json` sha256 `b13d6e80…f422` equal `inputs/prerequisites.json`. Every outcome maps onto published `error-contract/v1` rows (`R67:383`). OV-02 needs no catalogue row, which is consistent with R67 leaving ESC versus `^C` to R61 (`:303`, `:616`). |
| JF-8 evidence scripts exist and counts match | pass | `r61-claims.sh` and all cited logs exist. `r61-claims.log`: `TOTAL pass=109 fail=0 skip=4`, executed `2026-09-23T10:44:13Z`. `r61-claims-r1.log`: `pass=97 fail=0 skip=0`, `05:43:30Z`. `r61-claims-r5.log`: 109/0/4, `07:31:45Z`. The four SKIPs are `C13c`–`C13f`, with the openpty `EPERM` reason. `r61-claims-rerun.diff` is 36 lines with 10 `<`/`>` lines, which is 5 changed lines, as stated. Spot-checked assertions: `C5f` = 0, `C5g`, `C6a`, `C4a`, `C12a`–`C12c` = 9/35/11, `C12d`, `C12h`, `C12i`, `C15a` = 0 and `C16a` = 0. The r1 log's six-crate stars and `ast-grep` 15,932 match the table. |
| JF-9 decision shape | pass | The H2s are `## Decision` (with `### Principles and implementation` and a `re-verify:` line at :309), `## Parameters`, `## Empirical check` (toolchain, OS, command, working directory, observed output) and `## Engines` (reports, disagreements and resolving evidence). No `## Supersedes` is needed because no prior entry is reversed. This matches RUNBOOK §5. |
| JF-10 recommendation follows the evidence | pass | The architecture is compared (alternatives A–E) before libraries. Gates are applied before popularity. The runner-up's measured +2 against +26 package advantage is stated as the strongest counter-argument. The `inquire` choice rests on three verified differentiators: typed `^C` for `RSLB903`, values rather than indices, and no stdout path. The decision names this as the judgement most likely to flip and states its triggers. |

## Finding F1 — P5 fixes an exit integer across three repos, and py does not exit with it

**Failed claim** (P5 in the principles table, `DECISION.md:172`):
> P5 | Prompt cancellation is a defined outcome, not a panic or a stray exit code | **capability** — ledger F299, published by R67 as `RSLB903 → 130` | that `^C` mid-prompt ends the process at 130 | …

The column header is "Must agree across py / ts / rs".

**Evidence.**
- At py pin `b08bccfb`, the guided value prompt is `click.prompt` (`config.py:94`) and the confirm is `click.confirm` (`options.py:278`).
- In `click` 8.4.2, the version installed in the py checkout's `.venv`, both functions catch `(KeyboardInterrupt, EOFError)` and `raise Abort()` (`click/termui.py:195-201`, `:284-285`). `Abort` subclasses `RuntimeError` (`click/exceptions.py:362`).
- The `@global_options` wrapper that runs every command (`config_init` at `config.py:62-63`) catches `PyError`, then `KeyboardInterrupt`, then `Exception` (`options.py:210-229`). `Abort` is neither a `PyError` nor a `KeyboardInterrupt`, so it falls to the last arm. That arm prints `PLBP000` (unexpected), writes a crash log, and exits `ExitCode.IO = 4`.
- If a bare `KeyboardInterrupt` did reach the wrapper, the result would still not be `130`: it exits `ExitCode.INTERRUPT = 5` with `PLBP004` (`options.py:215-219`, `errors.py:45,55`).
- Only ts exits `130` (`src/router.ts:193-200`, D-033; `src/lib/errors.ts:20`). The ledger records F299 as `ts-only` (`COMMONALITY.md:303`).

The cited authority, R67's `RSLB903`, is an rs contract and cannot establish a py value. The decision's own rule for P3, stated at line 112 and in P3's may-vary cell, is that the cross-repo agreement fixes the outcome and leaves the integer ecosystem-specific. P5 breaks that rule. It also declares no drift or missing capability for py, which the HIGH principles question requires.

This is the same defect class as a shared exit `2` for P3, which the decision already corrected by moving the integer to the may-vary column.

**Repair.**
- P5 must-agree: "`^C` mid-prompt ends the process with a defined, documented interruption outcome, performs no mutation, and is distinguishable from ESC/decline."
- P5 may-vary: "the exit integer. rs-specific: `130` via R67 `RSLB903`; ts: `130` (D-033)."
- Add one sentence that names py's current behaviour at the pin. `click.prompt`/`click.confirm` turn `^C` into `click.Abort`, which py's wrapper reports as `PLBP000` with a crash log and exit `4`. The sentence should classify this as accidental drift or missing capability (F299 is `ts-only`) for the py/ts follow-on project, not as a justified ecosystem difference. It should state that this decision changes no py file.
- No recommendation, parameter, figure or check changes.

## Non-blocking notes

- **N1 (JF-3).** U10 says issue responsiveness for `cliclack` was "not measured". The Codex raw measured it: a 0.35-day median over 7 answered issues, with 3 unanswered (`codex.md:59`). The Codex raw also gives `inquire` a 0.18-day median over its 3 answered issues (`:55`), and the decision reports only "undefined" from the Opus raw. Neither point changes a verdict: `cliclack` is excluded at gate 2, and 7 of 10 unanswered supports `at-risk` either way. A future revision could carry both raws' figures.
- **N2.** In the outcome table, the row "`Ok(vec![])` from `MultiSelect`" is `Ok(Some(vec![]))` under `prompt_skippable()`, which line 50 already states. This is notation only.
