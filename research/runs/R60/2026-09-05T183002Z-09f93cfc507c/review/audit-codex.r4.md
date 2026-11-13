decision-sha256: 12aaf65c88f6bbcde915723913257f78d2e2e483c6deac4ee808b41af122ef43
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r4
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: F1 — U8 and the ruling-provenance statements are false: docs/port/OWNER-REVIEW.md:72-91 now records the binding standard, refused OV-01, selected option (b), zero overrides, and no waived SHOULD.

## Rerun

argv: `bash review/evidence/r60-standard-pin-r4.sh`; `bash review/evidence/r60-preservation-diff-r4.sh`; `bash review/evidence/r60-snapshot-provenance-r4.sh`; then the recorded Cargo metadata pair with `version = "v0.1.0"` and `version = "0.1.0"`.

cwd: this run directory; the scripts were also replayed from a clean `git archive HEAD` extraction. Toolchain: `rustc 1.98.0`, `cargo 1.98.0`, macOS `aarch64`. Clean replay exits: standard-pin `2`; preservation-diff `0`; snapshot-provenance `0` (the documented no-git variance: 14 checks and 5 `UNVERIFIABLE-HERE`). The one-off Cargo pair exited `101` then `0`. Complete log: `review/evidence/audit-cli-parsing-framework-r4.log` (sha256 `483018cf0188e1777635a9ff1585b2a8b2176aa6e3ea93190e8ab6ef35ab2dc5`). Output does not match the decision's recorded all-zero revision-4 script result.

## Findings

### F1 — stale claim that makes E13 fail

`review/DECISION.md:650-660` says the ruling is not in the repository and `:1330` carries that assertion as U8. The durable owner record contradicts it: `docs/port/OWNER-REVIEW.md:72-91` binds standard 1.4.14/blob `f9de0437`, records OV-01 as refused, selects option (b), and states zero overrides with no waived `SHOULD`. Accordingly the exact r4 standard-pin rerun failed C16h/C16i (`OV-01` count `3`, `2026-09-14` count `1`) rather than its recorded 115/0. Remove or revise U8 and its surrounding provenance assertions, then update the C16/E13 evidence and recorded result.

## Assessment

The owner-ruling implementation itself is otherwise supported: the pinned `clap_builder 4.6.6` parser source returns `Err(self.version_err(use_long))` at `parser.rs:1322-1331`; the corrected R4.6 span is `:275-277`; AC2/AC3/AC7, the retired OV-01 record, and R66's related-not-conflict classification are present. The five source refetches in the provenance replay (standard, two crate tarballs, and two Python snapshots) matched their pinned bytes. U1, U3, and the unexecuted acceptance criteria remain correctly labeled unproven.
