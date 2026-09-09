decision-sha256: 2fc432d4384bf492c03b7276fab4458c8cc52d734ef73e60f68d1ebc378e9c99
actor: audit-codex-2026-09-05T151356Z-c46d732f98ed-r3
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I copied `review/empirical/` to `/private/tmp/r38-empirical-r3.dmzuAJ/empirical` before executing either recorded command. The source fixture, its `tools/` directory, its `.work/` repositories, and its Cargo target directory were not used.

`bash run-checks.sh` ran in that copy with `rustc 1.98.0`, `cargo 1.98.0`, `git 2.50.1`, and `committed 1.1.11` on macOS 26.4 arm64. It exited 0 and reported `PASS=34 FAIL=0 RECORD=5`, matching the decision. Its full output is `review/evidence/audit-commit-message-linter-r3.log`.

`bash audit-deps.sh` then ran unchanged in the same copy. Its process exit was 1, so that exact rerun does not match the decision's recorded exit 0. The only failure was `cargo audit` being unable to acquire `/Users/stevemorin/.cargo/advisory-db..lock`: this execution environment permits that default cache path to be read but not written. The script downloaded the published crate and completed its manifest, lockfile, and source-reachability output before exiting. Its full output is in the same log.

As a diagnostic only, I reran the identical script with `CARGO_HOME` set to a new directory under `/private/tmp`; this is not recorded as the required command's result. That repeat exited 0, loaded 1,239 advisories, scanned 181 locked dependencies, reported exactly the three recorded `unsound` warnings (`RUSTSEC-2026-0183`, `RUSTSEC-2026-0184`, `RUSTSEC-2026-0190`), and reproduced the zero-use results for `downcast`, `unsafe`, `Remote::`, `.remote(`, `remotes(`, `blame(`, `BlameHunk`, and the `Buf` type. It supports the decision's historical Gate-3 result and identifies the exact-command mismatch as sandbox cache setup, not a changed dependency result.

## Findings

1. **The current decision resolves revision 2's blocking advisory finding.** Gate 3 now records the locked-tree audit, the three non-reachable `unsound` warnings, the relevant API surface, the `git2 = "0.20"` upgrade constraint, and a re-verification trigger limited to vulnerability-class advisories or unsound APIs actually used by `committed`. The fresh source audit above confirms the reported locked versions and reachability evidence. No decision change is needed.

2. **The empirical evidence proves the claimed contract rather than merely starting the tool.** The fresh harness rejects an invalid type, subject/body/footer width violations, and an invalid hook commit while retaining `HEAD`; it also shows `--no-verify` creates the invalid commit and the range invocation rejects it. Cases R3b and R4b independently show that the bot configuration preserves grammar and the eleven-type enum while relaxing only widths. The four F160 adapter tests passed.

3. **Five upstream citation spot-checks support the decision at tag `v1.1.11`.** `Cargo.toml` reports `MIT OR Apache-2.0`, edition 2024, and Rust 1.89; `crates/committed/Cargo.toml` specifies `git2 = { version = "0.20", default-features = false }`; `checks.rs` passes `line_length()` to `check_hard_line_length`; `.pre-commit-hooks.yaml` supplies `--fixup --wip --commit-file` at `commit-msg`; and `action/entrypoint.sh` pins `VERSION=1.1.11` and forwards `INPUT_ARGS` and `INPUT_COMMITS`. The tag reference returned annotated-tag SHA `0a8b458c6aa66455e1f477618783ecc3f4277e7a`; the decision's cited commit is the corresponding peeled commit.

4. **The two-engine limit is disclosed, not concealed.** `## Engines` identifies the Codex and Opus raw reports, identifies Doxa as pending billing, labels this as revision 3, and commits to supersession when the third report arrives. Under the requested current-revision scope, that is a stated evidence boundary rather than an unresolved defect.

## Assessment

Approve revision 3. It has the exact `1.1.11` pin, executable hook and CI-range designs, a selective bot exception that does not bypass invalid types, and a complete Gate-3 treatment of the currently known advisory warnings. The exact dependency-audit rerun was blocked only by this sandbox's read-only default Cargo advisory cache; the separately labelled isolated-cache diagnostic reproduced its recorded result. The decision need not change before acceptance.
