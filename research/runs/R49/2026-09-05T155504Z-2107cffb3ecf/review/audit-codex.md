decision-sha256: b7adf7d8f8ff380cdb25b40ff331d6b83291b2f7ea75a42407684ce2919cbcf9
actor: audit-codex-2026-09-05T155504Z-2107cffb3ecf-r1
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: owned parameter overstates Cargo.lock inclusion as unconditional

## Rerun

I reran the documentation, Cargo-help, Cargo source, cargo-dist tag, pinned-source,
and practice-manifest checks from
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R49/2026-09-05T155504Z-2107cffb3ecf`.
The named toolchain was `cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)` on
macOS. The read-only source and help probe groups exited 0. The requested Linux
VM could not be started in this sandbox because Lima lacked permission to unlink
its `ha.stdout.log`; no Linux probe ran. The detailed output is
`review/evidence/audit-build-target-declaration-r1.log`.

The output matches the decision for artifact locations, one library, the explicit
single binary with `autobins = false`, no present `build.rs`, the allow-list
semantics, the dirty-tree guard, cargo-dist support at v0.32.0, and the 7:2
practice split. It does not match the owned parameter's unconditional
`Cargo.lock` statement.

## Findings

1. **Owned parameter says `Cargo.lock` is unconditional when Cargo provides an
   override.** `review/DECISION.md:312` says that a minimized `Cargo.lock` is
   included "regardless." Cargo 1.98's manifest reference supports only that it
   is automatically included despite the manifest `include` or `exclude` fields.
   Cargo 1.98's `cargo package` reference and installed `cargo package --help`
   also document `--exclude-lockfile` as "Don't include the lock file when
   packaging." The value must say it is automatic under normal manifest
   selection, or name the command-line override. This is an owned-value scope
   defect, not an implementation failure.

## Assessment

The substantive recommendation is supported by the named Cargo 1.98.0 sources.
The baseline correction is correctly narrow: Cargo's default is not
tracked-files-only, and the untracked path is guarded by dirty-tree refusal
unless `--allow-dirty` is passed. The cargo-dist migration is deprecated at
v0.23.0 and still supported at v0.32.0. The allow-list choice accurately records
that it is a minority practice choice with medium confidence. The decision must
narrow the unconditional `Cargo.lock` claim before this audit can approve it.
