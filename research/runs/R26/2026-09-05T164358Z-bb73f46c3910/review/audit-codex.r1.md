decision-sha256: 7befd2f99bc093c1fd5a4f5915cb3cd86f3cc3f73a2a7e3273ddbd529b07b8aa
actor: audit-codex-2026-09-05T164358Z-bb73f46c3910-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: the saved empirical script does not emit cited phases 8-10, so the decision's stream-separation, Cargo.toml.orig/projection, and stale-archive claims are not reproducibly supported by an archived command

## Rerun

- argv: `bash /private/tmp/r26-audit-macos.JWAxsC/r26-check.sh`, an audit-owned copy of `review/evidence/r26-check.sh` with only `SCRATCH` repointed.
- cwd: `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R26/2026-09-05T164358Z-bb73f46c3910`.
- toolchain: `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`; macOS 26.4 arm64.
- exit code: 0. The full 234-line output is [`review/evidence/audit-packed-artifact-content-guard-r1.log`](evidence/audit-packed-artifact-content-guard-r1.log).
- output comparison: phases 0-7 have the same substantive outcomes as decision log lines 2-234. The rerun differs only in unordered directory listing order and compressed-byte counts, which do not affect the asserted checks. It cannot match decision log lines 236-363 because the saved script ends after phase 7.
- publish safety: inspected the saved script before execution. It contains no invocation of `cargo publish`; the literal `npm publish --dry-run` appears only in output produced by `git show` of the TypeScript precedent. No publish command, including a dry run, was invoked.
- Linux: `/opt/homebrew/bin/limactl` is callable, but `ubuntu` was stopped and `limactl start ubuntu` failed with `unlinkat /Users/stevemorin/.lima/ubuntu/ha.stdout.log: operation not permitted`. No Linux result was produced by this audit.

## Findings

1. **Reject — cited checks are not reproducible from the archived empirical script.** The command recorded at `review/DECISION.md:70` names `bash review/evidence/r26-check.sh` and says that the script produces phases 0-7, while the decision relies on phase 8 for stream separation (lines 84 and 97), phase 9 for the `cmp` and packaged-manifest projection (lines 85-86 and 94), and phase 10 for the stale-archive hazard (lines 87 and 126). The saved script ends at its `===== DONE =====` line after phase 7. The cited log adds phases 8-10 at lines 236-363, but it preserves outputs rather than the promised full shell commands. The macOS rerun likewise ended at phase 7. The decision must integrate phases 8-10 into `r26-check.sh`, or archive a complete addendum script and invoke it from that script, then regenerate the cited log and its hash. Until then, those claims are recorded observations without a saved reproducible check.

2. **Confirmed — the load-bearing Cargo claim holds at the installed binary's pin.** At `797e8a9bca276c1c9f9f738d2a20f484fa4eea9d`, the pinned `prepare_target_for_publish` source warns when a target source is absent from the packed files and returns `Ok(None)`. The replay's healthy guard returned 0; fault A made `cargo package` return 0, printed the binary-pruning warning, removed `rsguard-serve` from the normalized packaged-target projection, and made the guard return 1; fault B made the file-set diff fail and made the guard return 1. Five cited URLs were reachable by `curl` (three pinned Cargo files, the pinned Python workflow, and Cargo's package documentation). The decision also correctly rejects the raw report's obsolete citation: the old `src/workspace/parser/mod.rs` path returned HTTP 404 at the pin, while `src/cargo/util/toml/mod.rs` returned HTTP 200.

3. **Confirmed — parameter and platform scope are stated correctly.** All four `- assumes` values at decision lines 59-62 match their `docs/port/PARAMETERS.md` values byte-for-byte after stripping Markdown table-cell padding. The decision records macOS-only execution and an unproven Linux half of `target-os-matrix`; its `ubuntu-latest` and `macos-latest` sentence is an explicitly future P03 acceptance criterion, not a claim that the macOS probe proved the whole matrix.

## Assessment

The decision correctly establishes the core silent-pruning risk and correctly limits its platform claim. However, revision 1 claims and cites phase-8 through phase-10 results that its saved script does not run. This violates the empirical-audit requirement that a decision assert only what archived commands demonstrate. Restore a complete executable record, rerun it, and submit the regenerated decision for another empirical audit. The Linux evidence remains unproven because the available VM could not start in this sandbox.
