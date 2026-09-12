decision-sha256: d35d4f5a681b1d6572b80533393963bb55a435a71ca59fcca21d10b4c461bd6c
actor: audit-codex-2026-09-05T183002Z-09f93cfc507c-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: R1.3 MUST violation: R60 makes `projects` a canonical documented resource noun and its acceptance criteria omit a singular canonical `project` form; the decision does not pin the applied CLI Design Standard version 1.4.14

## Rerun

argv: `rustup run 1.96.0 cargo generate-lockfile`; then `cargo-audit audit --db /private/tmp/r60-audit-rustsec-db-3`.
cwd: isolated `/private/tmp/r60-audit.6Mm9TS` resolution fixture; no template files were changed.
toolchain: macOS `arm64`; `rustc 1.96.0 (ac68faa20 2026-05-25)` and `cargo 1.96.0 (30a34c682 2026-05-25)`.
exit code: lockfile generation `0`; advisory audit `0`.
log path: `review/evidence/audit-cli-parsing-framework-r1.log`.
output match: yes for the declared headline check — Cargo locked 28 registry packages at the declared `rust-version = "1.96"`, Cargo.lock contains 29 stanzas including the local root, and the audit scanned 29 crate dependencies with exit `0`. The intended `clap 4.6.6`, `clap_complete 4.6.9`, and transitive `strsim 0.11.1` resolved.

The requested Linux command was attempted. The installed `ubuntu` VM was stopped, and starting it failed because this sandbox cannot unlink that VM's host log. The documented macOS-only fallback was therefore used.

## Findings

1. Blocker — R1.3 of the CLI Design Standard version 1.4.14 says a resource noun's canonical form **MUST** be singular. R60 proposes and tests the documented command `<tool> projects list` at `review/DECISION.md:347,351-354`, and describes `projects` as one of the command groups at `:129-136`. It supplies neither canonical `<tool> project list` nor an undocumented plural alias. A `SHOULD` waiver cannot waive this MUST. Change the canonical grammar and acceptance criteria to `project`; if desired, accept `projects` as an undocumented alias. This is independent of the valid OV-01 waiver proposal.

2. Required correction — the decision depends on the CLI Design Standard but never pins its version. The standard is version `1.4.14`; the applied CLI-standards audit workflow requires every deliverable to state the version it was produced against. R60's file-and-line citations and retrieval date are otherwise consistent with R67's treatment of R6.1 as an org-locked MUST. Add the version at the first standard citation or in the decision status so future amendments cannot silently change the meaning of its citations.

OV-01 itself is correctly formed for the charter: it states an `Argument`, gives three explicit `Options`, identifies b and c as conforming, and says no owner waiver record exists. It therefore does not claim owner approval.

The exact four `assumes` values match `docs/port/PARAMETERS.md` byte-for-byte. No saved R60 check script exists to reproduce the entire historical evidence log; the two headline commands that the decision attributes to the empirical check were rerun and matched.

## Assessment

The recommended pins and selected features resolve at the declared floor and pass the advisory audit. Reads of the four published crate tarballs, each matching the recorded digest, confirm the feature and API claims without relying on a repository branch. The decision's R67-style treatment of organisation-standard rules is substantively consistent, and OV-01 correctly remains pending an owner waiver.

Reject because the chosen command grammar contradicts the same standard's non-waivable singular-noun rule, and because the applied standard is not version-pinned. No CLI was built or run; the decision accurately describes its proposed P03 acceptance criteria as unexecuted.
