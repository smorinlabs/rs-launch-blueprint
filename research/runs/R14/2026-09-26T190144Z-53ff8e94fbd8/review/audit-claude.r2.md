actor: claude
model: claude-opus-5-5
family: anthropic
decision-sha256: 9c7e39804f80396bad9affe77020c148957cc0fa4535438bb5fc6f702b4daf86
verdict: reject
unresolved-findings:
1. EA-1: the Q17.A input re-freeze is absent. The run's frozen inputs do not authorize the Muse leg that the decision adopts.
   - Failed claim (`## Decision` preamble): "Inputs read: `inputs/prompt.md` (sha256 `2b501625…`, `I1`)". Also `## Engines`: "`raw/muse.md` (actor `research-muse-…`, Muse/Meta) and `raw/opus.md` … Focused tier (two engines)". The revision note says "Three prose claims move, all text edits inside this file" and "no evidence was rerun".
   - Evidence:
     - The frozen `inputs/prompt.md` has sha256 `2b501625…`. Line 22 reads `- engines: codex, opus`.
     - The live prompt at `prompt_source` (`research/topics/14-large-file-guard-strategy/prompts/large-file-guard-strategy.prompt.md`) has sha256 `8ea107a4f7098eb2039650a249af28b71ad564513e3a522a5c85e3f43245765a`. Its line 22 reads `- engines: muse, opus`, and line 69 adds the `engine_overrides` pilot sentence. That edit is uncommitted: HEAD still hashes to `2b501625…`.
     - `manifest.json` records `"required_engines": ["codex", "opus"]` and `input_hashes.policy` `2a3ca155…`. The frozen `inputs/EXECUTION.json` gives R14 the engines `codex, opus`. Its `engine_overrides` keys do not include R14 (they are R02 … R86, 19 keys).
     - The live `research/EXECUTION.json` has sha256 `c670184d…`. It adds R14 to `engine_overrides` as `muse, opus`. `research/RUNBOOK.md:73` dates this Q17.A extension 2026-09-27.
     - `DECISION.md` never mentions Q17.A (`grep -c Q17` gives 0). `I1` in `r14-rev1-inputs.sh` still pins `want=2b501625…` and checks only the frozen copy, so `I1` passes while the recorded prompt and policy hashes differ from current inputs.
     - Revision 2 therefore does not re-freeze inputs. Its recorded inputs name a Codex leg that does not exist (`raw/` holds `muse.md` and `opus.md`). Its Muse leg is authorized only by uncommitted live edits that the decision does not cite.
   - Repair:
     1. Re-freeze the run inputs against the Q17.A policy: `inputs/prompt.md` becomes the `8ea107a4…` bytes, `inputs/EXECUTION.json` becomes the current policy, and `manifest.json` gets updated `input_hashes.prompt`, `input_hashes.policy`, `policy_item` and `required_engines: ["muse","opus"]`. This is done through the controller or runner, not by hand.
     2. Change `I1`'s `want` to the re-frozen prompt hash. Rerun `r14-rev1-inputs.sh` and commit the new log and `SHA256SUMS`.
     3. In `DECISION.md`, cite the new prompt hash and state that the Muse-for-Codex substitution rests on owner decision Q17.A (2026-09-27, `engine_overrides`).

## Scope and identity

I am a fresh empirical auditor from the Claude Opus family, model `claude-opus-5-5`. I judge execution truth and evidence support only.

- **Target:** `review/DECISION.md`, revision 2. `shasum -a 256` gives `9c7e39804f80396bad9affe77020c148957cc0fa4535438bb5fc6f702b4daf86`, which equals the expected hash. I verified this before doing anything else.
- **Not read:** any `review/audit-*.md` file, `review/R14-r1-snapshot.md`, or any `research/topics/*/raw/` path.
- **Host:** Darwin 25.4.0 arm64, `git version 2.50.1 (Apple Git-155)`.
- **Run date:** 2026-09-27T04:26Z.
- **Scratch:** `TMPDIR=/tmp/r14-audit-r2/tmp`. Fresh logs are in `/tmp/r14-audit-r2/`. Nothing under `evidence/` was written.

## Evidence integrity

`cd review/evidence && shasum -a 256 -c SHA256SUMS` passes 14/14. This includes `check-large-files.sh` (`3492598c…`), `ci.hygiene-with-guard.yml` (`aa37e31a…`), all six `r14-rev1-*.sh` scripts and all six logs. `wc -l check-large-files.sh` gives 46, matching the "46-line" claim.

## Reruns

Each harness ran from `review/evidence/` as `sh r14-rev1-<name>.sh 2>&1`. The committed logs have four wrapper lines that the scripts do not print themselves: `UTC now`, `host`, `cmd` and `exit=`. My wrapper reproduces them.

For all six harnesses, `cmp` against the committed log first differs at "char 19, line 1". That line is the UTC timestamp: committed `2026-09-26T21:46:12Z`, fresh `2026-09-27T04:26:26Z`. `cmp` on lines 2 through the end is byte-identical in all six cases.

| Script | Fresh log `/tmp/r14-audit-r2/…` | cmp vs committed | PASS | FAIL | exit |
|---|---|---|---|---|---|
| `r14-rev1-inputs.sh` | `r14-rev1-inputs.log` | identical except the UTC line | 27 | 0 | 0 |
| `r14-rev1-guard.sh` | `r14-rev1-guard.log` | identical except the UTC line | 29 | 0 | 0 |
| `r14-rev1-merge.sh` | `r14-rev1-merge.log` | identical except the UTC line | 4 | 0 | 0 |
| `r14-rev1-pybody.sh` | `r14-rev1-pybody.log` | identical except the UTC line | 5 | 0 | 0 |
| `r14-rev1-workflow.sh` | `r14-rev1-workflow.log` | identical except the UTC line | 9 | 0 | 0 |
| `r14-rev1-lefthook.sh` | `r14-rev1-lefthook.log` | identical except the UTC line | 4 | 0 | 0 |
| **Total** | | | **78** | **0** | |

Tallies come from `grep -c ' PASS'` and `grep -c ' FAIL'` on the fresh logs.

**`check-large-files.sh` has no paired log, so no byte comparison was done.** I ran it directly and recorded the output in `/tmp/r14-audit-r2/check-large-files.log`:

- No arguments: `usage: …/check-large-files.sh --staged | --range BASE HEAD`, with `exit=2`.
- Scratch repository, 1048577-byte `big.bin` staged, `--staged`: `FAIL: big.bin is 1048577 bytes (> 1048576). Remove it, track it with Git LFS, or mark it large-file-ok in .gitattributes.`, with `exit=1`.
- The same repository after staging `.gitattributes` containing `big.bin large-file-ok`: `ALLOW: big.bin is 1048577 bytes (large-file-ok)`, with `exit=0`.

**Rerun totals:** 7 scripts run; 6 byte-compared (identical apart from the timestamp); 1 with no baseline, so the comparison was skipped and the output was observed as above; 0 script failures.

## Re-derived figures

- **"78 checks pass":** 27 + 29 + 4 + 5 + 9 + 4 = 78. This matches the revision-2 table, including the corrected pybody row: 5 PASS lines, `BODY` plus `P1`–`P4`.
  - The Commands block quotes `pybody checks: 4 failures: 0`. That string is the script's literal counter line: `n` counts only the P-cases, and `BODY` echoes outside `chk`. The block reproduces the log accurately, so this is not a finding.
- **JF-4 prose (`H1`–`H7b` and `H10` under both shells; `H8` and `H9` under macOS `/bin/sh` only):** the guard log shows the `[dash]` tag for `H1`–`H7b` and `H10`, and only `H8[sh]` and `H9[sh]` for the last two. The claim is confirmed.
- **Boundary claim (1048576 passes, 1048577 fails):** `H2` and `H3` pass under both shells, and my direct run fails at 1048577. Confirmed.
- **JF-9 (`re-verify:` line):** it is one unbolded line starting at column 0. Confirmed.
- **"No evidence rerun; `SHA256SUMS` 14/14":** confirmed, and every harness still reproduces.
- **Re-freeze versus Q17.A:** not performed. The decision does not claim a re-freeze, and none of its recorded inputs reflect Q17.A. See EA-1.

## Verdict rationale

Every executed claim reproduces: 78 of 78 checks pass, and the logs match byte-for-byte apart from their timestamp. All three revision-2 prose fixes are accurate against the evidence.

The rejection rests only on EA-1. The decision's recorded inputs are the prompt hash `2b501625…`, the policy hash `2a3ca155…` and `required_engines: codex, opus`. None of these support the Muse+Opus engine set the decision adopts. The re-freeze that would bind the decision to Q17.A was not done, and the decision does not cite Q17.A.
