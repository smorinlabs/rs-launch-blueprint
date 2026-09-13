decision-sha256: 1b5a6b99ecedb88f7358d16a4567aa9b56838a2102e9e4feda99d00bc787513f
actor: audit-codex-2026-09-05T155504Z-2107cffb3ecf-r2
model: gpt-5.6-terra
family: openai
verdict: approve
unresolved-findings: none

## Rerun

I ran `bash review/evidence/check-lockfile-inclusion.sh` from
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R49/2026-09-05T155504Z-2107cffb3ecf`
with Homebrew `cargo 1.98.0 (797e8a9bc 2026-08-05)` and `rustc 1.98.0`
against Cargo tag `rust-1.98.0`; exit code: 0. Complete output is
`review/evidence/audit-build-target-declaration-r2.log`. The positive output has
13 assertions and matches the decision: only `retrieved:` differs across two
fresh reruns. Linux could not start because Lima was denied access to its host
log; the equivalent read-only check completed on macOS. No package, publish,
dry-run, or registry-write operation ran.

## Findings

1. **The owned parameter has the correct scope.** Cargo's manifest reference at
   `rust-1.98.0` says `Cargo.toml`, a minimized `Cargo.lock`, and a specified
   `license-file` are included regardless of manifest `include` or `exclude`.
   Cargo's package reference, installed `cargo package --help`, and
   `commands/package.rs` establish the `--exclude-lockfile` exception. The
   package operation generates an absent lockfile only when `include_lockfile`
   is true.
2. **The publish qualification is supported.** Installed `cargo publish --help`
   contains zero `exclude-lockfile` lines, while `registry/publish.rs` hardcodes
   `include_lockfile: true`. The tag-wide source enumeration finds exactly the
   two assignments stated by the decision. The statement that the future P03
   template will not pass the package-only flag is a recorded design constraint,
   not a claim that a template already exists; AC3 names the implementation-time
   proof.
3. **The predecessor's confirmed facts are unchanged.** The revision-1 to
   revision-2 diff changes only the lockfile qualification, exhaustive check,
   revision framing, and the accurate statement that `--help` is not packaging
   or publishing work. It does not change the cargo-dist responsiveness figures,
   deprecated-but-still-supported configuration refinement, narrowed F218
   baseline-review statement, or 7:2 practice-majority / medium-confidence
   record. The current decision is byte-identical to revision-2 commit
   `2ac02e1`.
4. **Registry inputs are exact.** All four `assumes` lines match
   `docs/port/PARAMETERS.md` byte-for-byte.

## Assessment

Revision 2 fixes the rejection cause without overstating the evidence. It proves
manifest-selection inclusion and clearly preserves the package-command override;
it also verifies that the publish command exposes no corresponding flag. The
negative controls fail in both the missing-assertion and unexpected-presence
directions. Approve.
