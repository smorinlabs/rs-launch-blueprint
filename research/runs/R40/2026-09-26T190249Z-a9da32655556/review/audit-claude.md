actor: audit-claude-R40-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 1dbba012637838b7d78330cfed304d57b7eca0226420bd8bfa5631512d52006b
verdict: reject
unresolved-findings:
1. Stale provenance claims: the citations evidence script now fails (101 PASS, 1 FAIL, 2 unrecorded mismatches).
2. `r40-citations.sh` does not record a failure from its two `cmp` checks.
3. Disagreement 5 quotes the wrong date for the `actionlint` commit figure.

# R40 empirical audit — revision 1

Target: `research/runs/R40/2026-09-26T190249Z-a9da32655556/review/DECISION.md`, revision 1.
Before any other step, I checked the expected sha256 with `shasum -a 256`. It matched `1dbba012…2006b`.
Scope: execution truth and evidence support only. I read the decision, focusing on `## Empirical check` and `## Engines`, and `research/RUNBOOK.md` §5.

## Rerun

**Host.** macOS, `Darwin 25.4.0 arm64`, Homebrew `rustc 1.98.1`. The private `CARGO_HOME` was `/tmp/cargo-s14-R40-emp` and `CARGO_TARGET_DIR` was `/tmp/cargo-s14-R40-emp-target`. The working directory was the repository root.

**Command.** `r40-rerun-all.sh` writes each log into `review/evidence/`, so I did not run it as committed. I ran `/tmp/r40-audit/run.sh`, a copy with the same order and the same reset steps. The reset runs `cargo uninstall typos-cli ryl` and `rm -rf /tmp/r40-synth-tools`, and the copy then runs `shellcheck` over all 10 scripts. It runs each of the 9 scripts as `bash "$E/r40-$s.sh" > /tmp/r40-audit/r40-$s.log 2>&1`. Nothing under `evidence/` was written. The pass ran from `2026-09-27T04:00:06Z` to `04:02:44Z`. This audit's execution of `r40-rerun-all.sh` is that /tmp copy.

**Driver output** (`/tmp/r40-audit/driver.log`), verbatim:

```text
shellcheck: clean over 10 scripts
r40-install.sh exit=0 TOTAL n/a (last line: DONE)
r40-ec.sh exit=0 TOTAL PASS=14 FAIL=0
r40-yaml.sh exit=0 TOTAL PASS=19 FAIL=0
r40-typos.sh exit=0 TOTAL PASS=11 FAIL=0
r40-actionlint.sh exit=0 TOTAL PASS=17 FAIL=0
r40-insta.sh exit=0 TOTAL PASS=8 FAIL=0
r40-compose.sh exit=0 TOTAL PASS=19 FAIL=0
r40-figures.sh exit=0 TOTAL n/a (last line: DONE)
r40-citations.sh exit=1 TOTAL PASS=101 FAIL=1
```

**Totals.** The committed pass had 192 PASS and 0 FAIL. This pass had 189 PASS, 1 FAIL, and 2 mismatches that the script did not record (see finding 2). All 7 non-citation scripts reproduce their assertion totals exactly (88/88). `r40-install.sh` and `r40-figures.sh` make no assertions. Skipped: none. `shellcheck` is clean over all 10 scripts.

**Byte comparison** (`cmp` of the committed `.log` against the fresh `/tmp/r40-audit/*.log`):

| Log | Result | First differing lines and assessment |
|---|---|---|
| `r40-ec.log` | identical | — |
| `r40-yaml.log` | identical | — |
| `r40-typos.log` | identical | — |
| `r40-install.log` | differ at line 6 | `CARGO_HOME=/tmp/cargo-s9r-R40` vs `/tmp/cargo-s14-R40-emp` (the auditor's private home). Build times: `typos-cli` 36 s vs 44 s, `ryl` 40 s vs 46 s. Environment and timing only. `no executable named ec in the 4.0.2 darwin-all tarball` reproduces. |
| `r40-actionlint.log` | differ at line 61 | `summary: (done in 0.05 seconds)` vs `0.06`; timing runs `0.069/0.065/0.065 s` vs `0.067/0.067/0.069 s`. Timing only. |
| `r40-insta.log` | differ at line 8 | the `mktemp` directory name (`r40-insta.iEu0DS` vs `r40-insta.93QHxD`), the test time `0.03s` vs `0.04s`, the thread id, and the `CARGO_HOME` path in the panic location. Nondeterministic only. The `I3` failure lines reproduce. |
| `r40-compose.log` | differ at line 3 | `ryl -> /tmp/cargo-s9r-R40/bin/ryl` vs `/tmp/cargo-s14-R40-emp/bin/ryl`. Lefthook runs jobs in parallel, so job output order differs (for example, the `yaml-lint` block moved from line 27 to line 22). Timings differ. The same jobs pass, fail, and skip, and all 19 assertions pass. |
| `r40-figures.log` | differ at line 1 | `retrieved_at=2026-09-27T02:35:36Z` vs `04:01:50Z`. Every figure line is byte-identical. |
| `r40-citations.log` | differ at line 8 | **Substantive** (finding 1). Committed: `PASS run prompt is byte-identical to the canonical prompt`, `PASS run policy snapshot is byte-identical to research/EXECUTION.json`, and `PASS R40 is absent from engine_overrides (policy engines for R40: ["codex","opus"])`. Fresh: `…/inputs/prompt.md research/topics/40-auxiliary-hygiene-hooks/prompts/auxiliary-hygiene-hooks.prompt.md differ: char 6063, line 24`, then `…/inputs/EXECUTION.json research/EXECUTION.json differ: char 1130, line 91`, then `FAIL R40 unexpectedly in engine_overrides`. The total line is `TOTAL PASS=104 FAIL=0` vs `TOTAL PASS=101 FAIL=1`. |

**Quoted observed-output lines.** I checked all 12 lines in the decision's observed-output block with `grep -F` against the fresh logs. Each is present in the log the decision names: `r40-install`, `r40-ec` (×2), `r40-yaml`, `r40-typos`, `r40-actionlint` (×2), `r40-insta` (×2), `r40-compose` and `r40-figures` (×2).

## Figures re-derived at source (read-only, public)

- `gh api "repos/rhysd/actionlint/commits?sha=main&per_page=2"` returned `011a6d15e749 2026-04-19T14:46:58Z` and `575dc0658351 2026-04-19T14:03:02Z`.
- `gh api repos/rhysd/actionlint` returned `main pushed_at=2026-07-16T06:05:57Z stars=4265`. This matches the decision's `pushed_at` and its star count.
- The `editorconfig-checker` `v4.0.2` release assets include `editorconfig-checker-darwin-all.tar.gz`. My fresh install listed the tarball, and it contains no `ec` executable.

## Findings

1. **Stale provenance claims, and the citations evidence now fails.**
   - *Failed claim* (`DECISION.md:5`): "`inputs/prompt.md` (sha256 `83eccf5e…`, byte-identical to the canonical prompt)".
   - *Failed claim* (`DECISION.md:7`): "The run's `manifest.json` and the policy both name `codex` and `opus` for R40. `research/EXECUTION.json` has no `R40` entry under `engine_overrides` … The substitution itself is unrecorded."
   - *Failed claim* (`DECISION.md:440`): "It filled the Codex seat without an `engine_overrides` entry".
   - *Failed claim* (`DECISION.md:410` and `:432`): `r40-citations.sh` "104/104", and "192 of 192 assertions … No assertion failed".
   - *Evidence.* A fresh `r40-citations.sh` exits 1 with `TOTAL PASS=101 FAIL=1` and prints `FAIL R40 unexpectedly in engine_overrides`.
   - *Evidence.* `jq '.engine_overrides.R40' research/EXECUTION.json` returns `["muse","opus"]`, and `.items.R40.engines` is `["muse","opus"]`. The canonical prompt, `research/topics/40-auxiliary-hygiene-hooks/prompts/auxiliary-hygiene-hooks.prompt.md`, now reads `- engines: muse, opus` at line 24. It also adds the sentence "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot" at line 71. Neither change is in the run's `inputs/prompt.md` or in `inputs/EXECUTION.json`.
   - *Evidence.* Both canonical files have mtime `2026-09-26T19:57:56-0700`, which is `02:57:56Z`. That is after the synthesis evidence pass, which ended at `02:36:27Z`, and after the decision file's mtime of 19:39 PDT. These are uncommitted working-tree changes. HEAD `e0b0d1c1` has no `R40` override.
   - *Evidence.* `manifest.json` still records `required_engines=["codex","opus"]`, so the manifest and the policy no longer agree.
   - *Impact.* The claims were true when the decision was written. Against the current inputs, they are false. RUNBOOK §5 requires current consumed values for acceptance.
   - *Repair.* Issue revision 2, re-bound to the current policy and prompt:
     - Restate the engine provenance as a substitution recorded under the `engine_overrides` pilot.
     - Replace the "byte-identical to the canonical prompt" claim. Either record the new canonical prompt hash and the one-line difference, or have the controller re-snapshot the run inputs.
     - Invert or replace the `engine_overrides` assertion in `r40-citations.sh`.
     - Note or resolve the mismatch between the manifest's `required_engines` and the policy.
     - Rerun the pass and restate the totals.

2. **`r40-citations.sh` does not record a failure from its two `cmp` checks.**
   - *Failed claim* (`DECISION.md:410`, the `r40-citations.sh` row): `104/104`, with the implication that every check is counted.
   - *Evidence.* Lines 37 and 38 of `r40-citations.sh` use the form `cmp A B && ok "…"`. When the files differ, `cmp` prints a message and neither `ok` nor `bad` runs. `set -e` does not stop the script, because `cmp` is not the last command of the `&&` list. The fresh run therefore reports 102 checks, with 2 mismatches uncounted, instead of 104 with 3 FAILs.
   - *Repair.* Use `if cmp -s A B; then ok "…"; else bad "…"; fi` for both checks, and rerun.

3. **Disagreement 5 quotes the wrong date for the `actionlint` commit figure** (minor).
   - *Failed claim* (`DECISION.md:459`): "0 commits on `main` since 2026-04-19".
   - *Evidence.* `r40-figures.log` reads `commits on main since 2026-04-20: 0` and `newest commit on main: 011a6d15e749 2026-04-19T14:46:58Z`. The GitHub API confirms two commits dated 2026-04-19. Decision line 239 correctly says "since 2026-04-20".
   - *Repair.* Change line 459 to "0 commits on `main` since 2026-04-20 (newest 2026-04-19)".

## Supported

Apart from the three findings above, every behavioural assertion reproduced on this host:

- `E0`–`E9` (`r40-ec.sh`): the `Version` pin must carry the `v` prefix.
- `Y1`–`Y9` (`r40-yaml.sh`): `ryl` and `yamllint` give the same verdicts; `truthy` is a warning by default and an error when raised.
- `T1`–`T2b` (`r40-typos.sh`): the default walk skips `.github/`.
- `A5`–`A7` (`r40-actionlint.sh`): the three hook shapes behave as described.
- `I3` and `I5n` (`r40-insta.sh`): an editor trim breaks the snapshot, and `.snap` is a default exclude.
- `C1`–`C6` (`r40-compose.sh`): hook/CI parity and the loud missing-tool failure.
- `r40-install.sh`: no `ec` executable in the tarball.

The figures reproduce byte for byte, except for the retrieval timestamp.
