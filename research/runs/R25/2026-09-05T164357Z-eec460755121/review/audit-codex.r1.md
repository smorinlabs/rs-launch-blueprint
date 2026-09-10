decision-sha256: 75d8edd839ae6ad7f69004a4e7947cd43c6d8af73414f81215f876a5a8dc7fc0
actor: audit-codex-2026-09-05T164357Z-eec460755121
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: the TypeScript-history claim says v0.1.1 was published, but the cited Git log proves only a release-please release commit and tag; npm returns 404 for ts-launch-blueprint@0.1.1

## Rerun

The Linux rerun used `limactl shell ubuntu -- bash -lc` after `source $HOME/.cargo/env`,
with the working directory `/Users/stevemorin/c/rs-launch-blueprint-p02-plan/research/runs/R25/2026-09-05T164357Z-eec460755121` and temporary inputs under `/tmp`.
The VM used `rustc`/`cargo` 1.98.1 on Linux aarch64. It has no `node`, `npm`, or `sw_vers`, so
the Node-dependent check 3 ran on macOS with Node 26.5.0 and a `/private/tmp` npm cache.

Checks 2, 5, and 6 reproduced with HTTP 200 responses. Check 4 reproduced after a complete
throwaway Cargo package was supplied: `cargo new` emitted `0.1.0`, and the resolver selected
`bitflags` 0.9.1 for `0.9.0`, 1.3.2 for `1.0.0`, and `axum` 0.7.9 for `0.7.0`.
Check 3 reproduced all 36 rows at release-please 17.11.2. The first npm attempt failed because
the shared cache was root-owned; the retry used an isolated cache and exited 0. The first Cargo
attempt had an incomplete auditor fixture; the final retry exited 0. Those setup failures are
preserved in the log and do not contradict the decision.

The substantive release-please and Cargo output matches the decision. The host-record check is
necessarily different on Linux, and the public-registry lookup below disproves one TypeScript
publication statement. Complete output: `review/evidence/audit-r25.log`.

## Findings

1. **Reject: “first published” is unsupported and currently contradicted.**
   `review/evidence/registry-and-source-repos.log` supports that commit `19ff9b5` seeded
   `{ ".": "0.1.0" }`, and that `bdc7567` is the first release-please release commit with the
   message `chore(release): publish v0.1.1`. It does not establish an npm publication. The
   independent check found the tag `ts-launch-blueprint-v0.1.1`, but
   `npm view ts-launch-blueprint@0.1.1 version dist.tarball --json` returned `E404`.
   Therefore the decision must replace statements that TypeScript “first published v0.1.1” with
   the narrower, proven fact: its first release-please release commit/tag was `v0.1.1` after a
   manifest seed of `0.1.0`. That fact still supports the source-level inference that a manifest
   seed is read as an already-released version; it cannot serve as proof of registry publication.

2. **Confirmed: the correction to the binding prompt is right.**
   At release-please v17.11.2, the schema says `bump-minor-pre-major` makes *breaking* changes
   bump minor below 1.0.0, while `bump-patch-for-minor-pre-major` makes *feature* changes bump
   patch. `src/versioning-strategies/default.ts` uses exactly that branch order. The executed
   probe confirms that both flags yield `fix`/`feat` -> patch and `feat!` -> minor at 0.x.
   Thus the binding prompt’s gloss reverses the flag roles, and the decision corrects it correctly.

3. **Confirmed: the cited logs otherwise support the claims for which they are used.**
   The toolchain log is a host record; the source log supports schema, Rust default initial version,
   configuration mapping, and action dependency range; the bump-probe log supports the 36-row
   arithmetic; the Cargo log supports the initial version and caret-band examples; the quotation
   log supports its five quoted authorities; and the registry/source log supports the dated API
   figures and source-tree facts. The only overreach is promoting the TypeScript release commit/tag
   into a verified external publication.

## Assessment

The release-please flag correction and the empty-manifest source reasoning are technically sound.
The decision correctly leaves P03’s six listed implementation and integration questions unproven;
that is required research-phase boundary discipline, not a defect. This audit rejects only until
the TypeScript “published v0.1.1” wording is narrowed to the evidence actually available.
