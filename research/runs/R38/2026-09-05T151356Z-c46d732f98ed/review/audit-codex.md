decision-sha256: 563ffa5c65413a61e6caa0f5906789dde69c131d9f54e42965ef6acf2f0bb6f5
actor: audit-codex-2026-09-05T151356Z-c46d732f98ed-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

- argv: `bash run-checks.sh`
- cwd: a fresh disposable copy of `review/empirical` at `/private/tmp/r38-empirical-audit.tjGjjy/empirical-audit`; the copy excluded `tools/` and `repo-hygiene/target/`, so the runner provisioned `committed` again. The requested output-only scope prevents retaining a third fixture directory under `review/`.
- toolchain: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `git version 2.50.1 (Apple Git-155)`; macOS 26.4 arm64.
- exit code: 0.
- log path: `review/evidence/audit-commit-message-linter-r2.log`.
- output matches the decision's recorded result: yes. The fresh install reported `committed 1.1.11`, 3,868,064 bytes; the runner reported `PASS=34 FAIL=0 RECORD=5` and `RESULT: PASS`.

## Findings

1. **Prior bot-exemption rejection is resolved.** The current `committed.bot.toml` keeps `style` and the eleven `allowed_types`, but sets only `subject_length` and `line_length` to zero. Fresh cases R3b and R4b respectively reject a dependabot-authored `wibble` commit (exit 1) and accept the same bot path only when it violates widths (exit 0). This proves the selected bot configuration does not use the former whole-commit `ignore_author_re` bypass.

2. **The exact version policy executes and has a defined upgrade gate.** The fresh harness installed and asserted `committed 1.1.11`; the decision names the same pin for hook setup and action SHA. Curl confirmed that the cited SHA resolves its `action.yml` and `action/entrypoint.sh`; the action defaults to `-vv --no-merge-commit`, passes `INPUT_ARGS` and `INPUT_COMMITS`, and hardcodes `VERSION=1.1.11`. The locally installed binary also accepts `--no-merge-commit` and `--config`, which are the action arguments. The documented later-release procedure re-reads `checks.rs`, reruns the harness with `COMMITTED_VERSION=X`, requires zero failures, and moves all pins together.

3. **Citation spot-check: supported.** Curl checked five cited tagged upstream sources: `Cargo.toml` supplies `MIT OR Apache-2.0`, edition 2024, and MSRV 1.89; `checks.rs` shows the `hard_line_length` path receives `line_length`; CI lists Ubuntu, Windows, and macOS; `.pre-commit-hooks.yaml` supplies `--fixup --wip --commit-file` at `commit-msg`; and the action entrypoint downloads version 1.1.11 and forwards its inputs. The current environment returned HTTP 403 for crates.io and GitHub API figure endpoints, so the reported download and GitHub figures were not refreshed; it returned the recorded HTTP 404 for the RustSec package page. The decision already labels both limitations and does not use either as unqualified proof of advisory absence.

4. **Doxa is an explicit, non-concealed evidence limit.** `## Engines` says the two available reports were synthesized, identifies billing as the reason the third report is absent, and states that a third report will supersede this revision. That matches the requested current-revision scope; it does not invalidate the two-engine empirical conclusion.

## Assessment

The current decision corrects both defects in the rejected revision, and the independent fresh run proves the relevant behavioral contract: invalid types fail for people and bots, widths are selectively relaxed only by the bot CI configuration, a hook bypass is caught on the range path, and the F160 configuration/template adapter passes. The version, configuration, hook arguments, and action path are executable at the stated `1.1.11` pin. Approve this current two-engine revision; Doxa remains a disclosed future supersession trigger rather than an unresolved defect in this audit.
