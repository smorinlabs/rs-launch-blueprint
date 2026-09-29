actor: audit-claude-R28-r1
model: claude-opus-5-5
family: anthropic
decision-sha256: 90cbe6ce44b7291afdeca2c3a373f6e2d6a584e204672fc8e6f098ff7511759b
verdict: approve
unresolved-findings: none

# R28 revision 1 — empirical audit (audit-claude-R28-r1)

**Scope.** Execution truth and evidence support for `review/DECISION.md` revision 1 only. Before any other action, I checked the hash with `shasum -a 256 review/DECISION.md`. It printed `90cbe6ce44b7291afdeca2c3a373f6e2d6a584e204672fc8e6f098ff7511759b`, which matches the expected value. I read the decision in full and RUNBOOK §5. I read no audit file, no `research/topics/*/raw/`, and no snapshot file.

**Result.** All 9 evidence scripts reran. Eight reproduce every PASS/FAIL line of their committed logs. `r28-inputs.sh` reproduces 110 of 111 cases. Its one failure, `I1-canon`, comes from an uncommitted edit that was made outside the run directory after the decision was written. That edit is the controller action the decision itself names under `## Engines`. The claim holds against committed state at HEAD `e0b0d1c1`, and no revision of this decision could change the outcome. It is therefore recorded below as an observation, not an unresolved finding. **This approve does not clear acceptance** (see "Notes for the controller").

## Host

- macOS `Darwin 25.4.0 arm64`
- `CARGO_HOME=/tmp/cargo-s14-R28-emp`, a private cargo home
- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`
- `clippy 0.1.98`
- floor `rustup run 1.96-aarch64-apple-darwin rustc --version` → `rustc 1.96.1 (31fca3adb 2026-06-26)`
- `~/.cargo/bin/rust-analyzer --version` → `rust-analyzer 1.94.0 (4a4ef493 2026-03-02)`
- ruff at the script's default path, `~/.local/share/mise/installs/ruff/0.15.15/…/ruff` → `ruff 0.15.15`. A bare `ruff` in my shell fails with a mise "No version is set for shim" error. The script does not use that shim, so the failure does not affect the rerun.

These versions match the decision's `## Empirical check` host paragraph.

## Reruns

**Command.** From `review/evidence/` I ran, for each script `<s>`: `bash <s>.sh > /tmp/r28-emp/<s>.log 2>&1`. I then ran `cmp -s /tmp/r28-emp/<s>.log <s>.log`, and `diff` on any mismatch. The scripts ran one at a time. Nothing under `evidence/` was written: after the reruns, every file's mtime is still between 17:58 and 18:19, as before.

**Totals.** 169 PASS, 1 FAIL, 0 SKIP over 170 cases. The decision's table sums to 170 cases, all passing.

| Script | Exit | PASS / FAIL (decision) | `cmp` | Every differing line, by class |
|---|---|---|---|---|
| `r28-autofix.sh` | 0 | 5 / 0 (5 / 0) | differ | `CARGO_HOME` header; mktemp scratch path; scratch git short sha (`cb98542` → `3af59cf`); cargo `Finished … in Ns` timings |
| `r28-editor-config.sh` | 0 | 6 / 0 (6 / 0) | differ | `CARGO_HOME` header only |
| `r28-floor.sh` | 0 | 5 / 0 (5 / 0) | differ | `CARGO_HOME` header; scratch path; one timing |
| `r28-inputs.sh` | **1** | **110 / 1** (111 / 0) | differ | line 13 `PASS I1-canon` → `FAIL I1-canon`; the summary line (see the next section) |
| `r28-lint-table.sh` | 0 | 13 / 0 (13 / 0) | differ | `CARGO_HOME` header; scratch path in the `Checking`/`error: failed to load manifest` lines; timings |
| `r28-live-figures.sh` | 0 | 7 / 0 (7 / 0) | differ | line 1 `== retrieved` timestamp only (`2026-09-27T01:11:29Z` → `03:40:54Z`) |
| `r28-ruff-fix-default.sh` | 0 | 2 / 0 (2 / 0) | differ | scratch path only |
| `r28-sources.sh` | 0 | 10 / 0 (10 / 0) | differ | line 1 `== retrieved` timestamp only (`01:11:15Z` → `03:41:00Z`) |
| `r28-test-relaxation.sh` | 0 | 11 / 0 (11 / 0) | differ | `CARGO_HOME` header; scratch path; one test timing (`0.01s` → `0.00s`); the committed line 28 `warning: build failed, waiting for other jobs to finish...` is absent in the rerun. That line depends on cargo job scheduling, which is nondeterministic, and it sits inside a case whose expected result is a failed build |

In the eight scripts other than `r28-inputs.sh`, no `PASS`/`FAIL` line changed and no asserted exit code changed. Each ends `== summary: 0 failing case(s)`.

## Observation: `I1-canon` fails on the current working tree

**Failed line** (`/tmp/r28-emp/r28-inputs.log:13`):

```
FAIL I1-canon — inputs/prompt.md is byte-identical to the canonical prompt
```

The run ends with `== summary: 1 failing case(s)`. The committed log's line 13 reads `PASS I1-canon — …`.

**Cause, established at source.**

| Artifact | sha256 |
|---|---|
| run input `inputs/prompt.md` | `d21a739c0f95e8a7bcaa7e5e0a1be3f93eda0463ab06560183eda5bf0ce63c38` |
| `manifest.json` `input_hashes.prompt` | `d21a739c0f95…` (`I1-prompt` PASS) |
| canonical prompt at HEAD (`git show HEAD:research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md \| shasum -a 256`), HEAD `e0b0d1c1` | `d21a739c0f95e8a7bcaa7e5e0a1be3f93eda0463ab06560183eda5bf0ce63c38` |
| canonical prompt in the working tree | `f50ecd2a898ea2d2ab21f62fabdf8df822f89a3dc68c5e045201e3f8995f985b` |

- `git status --short` on the canonical prompt prints ` M research/topics/28-linter-and-editor-tooling/prompts/linter-and-editor-tooling.prompt.md`. The file has an uncommitted modification.
- The file's mtime is `Sep 26 19:57:56 2026`. `DECISION.md`'s mtime is `Sep 26 18:19:24 2026`, so the edit came after the decision was written.
- `diff inputs/prompt.md <canonical>` shows exactly two changed lines: line 28 `- engines: codex, opus` → `- engines: muse, opus`, and line 79, where the sentence `This item substitutes Muse (Meta) for Codex under the \`engine_overrides\` pilot; its mirrored \`- engines:\` line is authoritative.` is appended.
- The uncommitted working-tree `research/EXECUTION.json` diff also adds an `R28` entry of `["muse", "opus"]`. This corroborates that the controller is recording the substitution.

**Judgment.** The decision's claim, `r28-inputs.sh` 111 PASS / 0 FAIL, was true when it was written, and it still holds against committed HEAD. The present failure is the drift this case exists to detect. The drift is the controller's pending resolution of provenance fact (1), which the decision flags: "record a substitution of Muse for Codex on R28 that postdates this run's snapshot, which would change the policy input hash" (`## Engines`). No edit to `DECISION.md` repairs it, so it is not an unresolved finding against revision 1.

## Re-derivations at source

- **Raw hashes and line counts.** `raw/muse.md` sha256 is `729bc9fc3c8ca14c2aa424284708d7b953dc880d232cfc16968b0cd1fae4c3c8` and has 946 lines. `raw/opus.md` sha256 is `7e7c8f1d32fe13bc2fca136742b5d58ed6f47bcb8fd4f7769838eee35a1ad314` and has 943 lines. Both match the revision note and the `## Engines` table. I did not read the raw contents beyond this.
- **Provenance facts.** In the snapshot `inputs/EXECUTION.json`, R28's `engines` list begins with `"codex"`. `manifest.json` has `"required_engines": ["codex", "opus"]` and `"operations": {}`. `operations/` is empty. Both provenance facts hold as the decision states them.
- **Citations.**
  - `research/topics/42-dev-toolchain-provisioning/DECISION.md:26` contains `components = ["rustfmt", "clippy"]`.
  - R42 lines 519–521 contain "R28's clippy invocation … is written `cargo clippy …` inside the Justfile recipe that owns it, not `cargo lint` behind an alias".
  - `research/topics/11-ci-workflow-job-structure/DECISION.md:82` contains the owner ruling `2026-09-12 (Q7.B): licence compatibility is not evaluated`.
  - R11 line 268 contains "`-D warnings` is on both clippy steps".
  - R11 line 320 contains `clippy with the feature on`.
- **Live figures.** The rerun's `r28-live-figures.log` contains every figure the decision quotes, verbatim:
  - `stargazers_count` 13536 (clippy), 16877 (rust-analyzer) and 3309 (codelldb), with `license` Apache-2.0 / Apache-2.0 / MIT
  - `pushed_at` `2026-09-24T14:26:18Z`, `2026-09-26T10:35:50Z` and `2026-08-23T22:32:49Z`
  - `clippy` shim `max_stable_version` `0.0.302`, crate `created_at` `2015-05-09`, version `created_at` `2018-10-05T19:39:15`, `recent_downloads` 95559, `downloads` 2067318
- **Load-bearing cases in the fresh logs.** The following lines read `PASS` with the exit codes the decision quotes: L9 (exit 0 / exit 101), L10, L12 (root-only exit 0; `--workspace` exit 101), L13, T9, T10, F0 (the floor toolchain is 1.96), F4 in the autofix script, V1 (`check.command default "check"`), S2 and S7.
- **shellcheck.** `shellcheck *.sh` in `evidence/` exited 0, and `r28-inputs.sh` I10 passes for each script.

## Not verified by this audit

- A7 and A8 remain proposals. There is no VS Code on this host.
- There was no ubuntu-latest run.
- `raw/*.md` content, R06 and R16 content, and the py/ts source citations were not read. The decision labels them as carried.
- Engine provenance policy is the controller's decision, not this auditor's.

## Notes for the controller (non-blocking for this verdict)

1. Acceptance stays blocked by the decision's own two provenance facts: the Muse leg is unauthorized under the snapshot, and there are no operation receipts.
2. Once the working-tree prompt and `EXECUTION.json` edits are committed, this run's recorded `prompt` hash (`d21a739c…`) and its policy input will no longer be current. The checker's current-inputs check and `r28-inputs.sh` `I1-canon` will then fail for this run until it is re-bound or re-run under the new inputs.
