# R28 revision 3 — empirical re-run audit (r3c)

decision-sha256: c607a34e01f36673d0be729a826ee10fdd5ed77c94a31dcde3726ab2cd7e8519
actor: codex-empirical-r28-r3c
model: claude-opus-5-5
family: anthropic
verdict: approve
unresolved-findings: none
execution-pin-sha256: fd746cb86e545023aed589b9d0c4db7125673a62849181ac898db56a5fa3545c
rerun-date: 2026-09-29

This audit fills the Codex seat, but the engine that ran it is Claude Opus (`claude-opus-5-5`, Anthropic). It supersedes `review/audit-codex.r3b.md` against the same DECISION revision 3. Under the S87 dispatch, STANDING RULE (1) makes inputs-vs-provenance drift a disclose-only observation. That rule reclassifies r3b's E1 as an observation (OBS-1 below), and this audit does not re-argue it.

## Method

- **Binding.** `review/DECISION.md` hashed to `c607a34e…8519` before anything else was read. It hashed to the same value again immediately before this file was written.
- **Scope (Q23, RUNBOOK §7).** This was a rerun only. No judgment audit and no verifier pair were run, and nothing was fixed.
- **Execution.** All nine scripts ran unmodified from `review/evidence/` as `bash <script>.sh > /tmp/s87-r28-rerun/<script>.log 2>&1`.
  - Cargo used `CARGO_HOME=/tmp/cargo-s87-r28` and `CARGO_TARGET_DIR=/tmp/cargo-s87-r28-target`.
  - Every fixture was built under `mktemp -d`. `r28-autofix.sh` ran `git init` and `git commit` only inside its scratch directory, which STANDING RULE (2) permits.
  - No git write touched the checkout.
  - The sources and live-figures scripts made only their own read-only public HTTP requests. The first attempt of every script succeeded.
- **Comparison.** For each script I compared the whole file with `cmp`, reviewed the full `diff -u` output, and diffed only the `PASS`/`FAIL` lines against the committed log.
- **Host.** `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)`, rustup toolchain `1.96-aarch64-apple-darwin` present, `shellcheck 0.11.0`, macOS `Darwin 25.4.0 arm64`.

## Rerun results

| Script | Exit | Rerun PASS / FAIL | Committed PASS / FAIL | Whole-file bytes | Case lines |
|---|---|---|---|---|---|
| `r28-lint-table.sh` | 0 | 13 / 0 | 13 / 0 | differ (run-local) | identical |
| `r28-test-relaxation.sh` | 0 | 11 / 0 | 11 / 0 | differ (run-local) | identical |
| `r28-autofix.sh` | 0 | 5 / 0 | 5 / 0 | differ (run-local) | identical |
| `r28-floor.sh` | 0 | 5 / 0 | 5 / 0 | differ (run-local) | identical |
| `r28-editor-config.sh` | 0 | 6 / 0 | 6 / 0 | differ (`CARGO_HOME` line only) | identical |
| `r28-sources.sh` | 0 | 10 / 0 | 10 / 0 | differ (retrieval timestamp only) | identical |
| `r28-live-figures.sh` | 0 | 7 / 0 | 7 / 0 | differ (retrieval-time figures) | identical |
| `r28-ruff-fix-default.sh` | 0 | 2 / 0 | 2 / 0 | differ (scratch path only) | identical |
| `r28-inputs.sh` | 1 | 154 / 3 | 157 / 0 | differ | 3 FAIL plus 2 hash lines differ (OBS-1) |

**The 59 empirical outcomes are identical.** The eight empirical scripts produce 13 + 11 + 5 + 5 + 6 + 10 + 7 + 2 = 59 PASS and 0 FAIL, and each case line is byte-identical to its committed log. This reproduces the decision's revision-3 rerun claim: "each script's `PASS`/`FAIL` lines are identical to its committed log (59 PASS, 0 FAIL)" (`review/DECISION.md:177`). The cases the adjudication rests on (L9, L10, L12, L13, T9, T10, F4, and V2, listed at `review/DECISION.md:181-191`) all PASS again with the same case text.

**No rerun contradicts a decision claim.** The STOP TRIGGER did not fire. The decision's claim that the scripts pass `shellcheck` with no diagnostics (`review/DECISION.md:160`) also reproduces: `shellcheck 0.11.0` over `review/evidence/*.sh` exits 0 with zero output lines.

## Observations (not fixed; rerun only)

- **OBS-1: `inputs/` drift in `r28-inputs.sh` (E1 class, disclose-only under STANDING RULE 1).**
  - **Claim and evidence agree.** The decision claims 157 PASS and 0 FAIL (`review/DECISION.md:173`). The committed `r28-inputs.log` records exactly that.
  - **The live rerun differs.** It records 154 PASS and 3 FAIL. The failing cases are:
    - `FAIL I1-canon — canonical prompt differs from inputs/prompt.md only by the Q17.A edit (line 28 engines, line 79 Muse sentence)`
    - `FAIL I8-engines — R28 engines ['muse', 'opus'], tier focused`
    - `FAIL I8-override — no engine_overrides entry for R28`
  - **Cause.** The run's inputs were re-snapshotted to the post-Q17.A state after the log was produced. `inputs/prompt.md` now hashes to `f50ecd2a…` (it was `d21a739c…`). `inputs/EXECUTION.json` now hashes to `fd746cb8…` (it was `2a3ca155…`). That value equals both the S87 execution pin and live `research/EXECUTION.json`.
  - **Why `I1-prompt` and `I1-policy` still PASS.** `manifest.json`'s input hashes moved with the files, so both cases pass with the new values.
  - **How to read the `I8-override` line.** The text after the dash is the script's fixed expectation, not an observation. An R28 `engine_overrides` entry now exists (`inputs/EXECUTION.json:445-448`, `muse, opus`).
  - **Effect on the decision.** None of this bears on the empirical outcomes. It concerns the `## Engines` snapshot-provenance prose (`review/DECISION.md:201`), which revision 3 already leaves to the controller.
  - **Controller question, recorded only.** `manifest.json` still records `required_engines: ["codex", "opus"]`.
- **OBS-2: the run directory is untracked in git.** `git status --porcelain -- research/runs/R28` prints `?? research/runs/R28/`. Here, "committed log" therefore means the on-disk file under `review/evidence/`, which has no git baseline. This audit did not change those files.
- **OBS-3: live figures have kept moving.** Retrieved 2026-09-29T18:04:58Z:

  | Figure | Committed log | Rerun |
  |---|---|---|
  | `rust-lang/rust-clippy` stars / open issues | 13,536 / 2,506 | 13,547 / 2,507 |
  | `rust-lang/rust-clippy` pushed | 2026-09-24T14:26:18Z | 2026-09-29T16:59:39Z |
  | `rust-lang/rust-analyzer` stars / open issues | 16,877 / 1,696 | 16,884 / 1,698 |
  | `rust-lang/rust-analyzer` pushed | 2026-09-26T10:35:50Z | 2026-09-28T04:52:16Z |
  | `vadimcn/codelldb` stars | 3,309 | 3,310 |
  | `clippy` shim downloads, recent / all-time | 95,559 / 2,067,318 | 97,737 / 2,070,772 |

  The shim figures have also passed the decision's revision-3 rerun values (95,952 / 2,067,711). The licences, `archived: false`, the shim version `0.0.302`, and the rustsec 404 outcomes are unchanged. The decision already discloses this retrieval-time drift (`review/DECISION.md:177,186-191`).
- **OBS-4: run-local noise in `r28-lint-table.log`.**
  - The lines `error: could not compile` and `warning: build failed, waiting for other jobs…` appear in swapped order.
  - The L11 compiler-target label toggles from `bin "r28-cli"` to `bin "r28-cli" test`. L11 still PASSes, and prior audits saw the same toggle.
  - Everything else in the whole-file differences across the eight scripts is run-local: `CARGO_HOME`, `mktemp` scratch paths, the scratch commit ID, and build and test durations.

## Priors

This audit only read `review/audit-*.md` (the other seats' files), `review/R28-r1-snapshot.md`, `review/R28-r2-snapshot.md`, the evidence scripts, and the committed logs. Their SHA-256 values were recorded before this file was written and rechecked afterwards (`/tmp/s87-r28-rerun/priors-pre.sha`). This file is the only one added under `review/`.
