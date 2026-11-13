decision-sha256: 968fe27ec7c3bc65e614ae46c68da7644a91c02a09387e4018bb29386464a916
actor: audit-codex-2026-09-05T160304Z-1e904d50d29e-r5
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1: DECISION.md line 302 says a resolution-changing .cargo/config.toml [patch] was not exercised, contradicted by executed F5 and H1-H2 cases

## Rerun

- argv: `WORK_DIR=<fresh /private/tmp/r41-audit-macos-r5.*> bash ./run-checks.sh "floor-1.96.0=$(dirname "$(rustup which --toolchain 1.96.0 cargo)")" "stable-1.98.0-homebrew="`; Linux: `bash ./run-linux-leg.sh`.
- cwd: `review/empirical` for both legs. The Linux driver copied the runner and fixture into a fresh Lima VM directory before execution.
- toolchain: macOS floor `cargo`/`rustc` 1.96.0 selected by prepending the directory returned by `rustup which --toolchain 1.96.0 cargo`, plus Homebrew Cargo 1.98.0; Lima Ubuntu floor 1.96.0 and stable 1.98.1. As recorded by the decision, direct `cargo +1.96.0 --version` fails because Homebrew Cargo is first on `PATH`; the control reproduced that failure and the `rustup which` route succeeded.
- exit code: macOS 0 and Linux driver 0. Each leg ran both supported toolchains and ended `summary: PASS=436 FAIL=0 RECORD=76` and `RESULT: PASS`.
- log path: `review/evidence/audit-lockfile-freshness-check-r5.log` (sha256 `3734526b625f07b2f2718ad417153fa9666fe076cb7632f533547224a9257ac1`).
- output matches the decision: yes. The full rerun matches the recorded r5 result. H1a and H2d reproduce the revision-4 false pass and false refusal; H1b/H1c refuse the registry-form lock under the nested root configuration; H2b/H2c accept the in-directory repaired lock; H3 leaves the ignored lock unchanged; H4 reports the below-root configuration; and F5 refuses the top-level manifest patch.

## Findings

- **F1 — decision text is internally inconsistent and must be corrected.** `review/DECISION.md:302` lists “a `.cargo/config.toml` that changes resolution (source replacement, `[patch]`) was not exercised” as remaining uncertainty. This revision executes `[patch.crates-io]` cases: F5 uses a top-level manifest patch, and H1b/H1c plus H2b/H2c use `nested/.cargo/config.toml` containing a patch in stale and repaired states. The rerun confirmed those cases on macOS and Linux at both toolchains. The remaining uncertainty may retain unexercised source replacement, but it must not state that `[patch]` was unexercised.

## Assessment

The revision-5 implementation fixes the judgment audit’s revision-4 defect. In both OS families and both toolchains, the root-directory `cargo update --workspace` applies `nested/.cargo/config.toml`, yields the correct refusal for the stale registry lock, accepts the repaired patched lock, and differs from the retained revision-4 control in both directions. The new F5, H3, and H4 cases also behaved as stated. The runner, driver, and fixture script pass shell syntax checking. Six cited primary-source endpoints returned HTTP 200; the logged content spot-checks confirmed Cargo’s workspace-update wording, Cargo’s current-directory configuration hierarchy, uv’s `lock --check` semantic, and the pinned Cargo orphan-package source comment.

I reject solely because the current decision claims an executed `[patch]` category was not exercised. That is a factual status error in the acceptance record, despite the behavior being correctly tested and documented elsewhere. Removing `[patch]` from that uncertainty (or narrowing it to source replacement) resolves this audit finding without changing the selected mechanism.
