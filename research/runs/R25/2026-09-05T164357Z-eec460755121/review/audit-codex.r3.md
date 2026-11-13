decision-sha256: 23d42766b5319c95de680b50dc20334332243e66079eab5f0b981b02c6df9fbd
actor: audit-codex-2026-09-05T164357Z-eec460755121-r3
model: gpt-5.6-terra
family: openai
verdict: reject
unresolved-findings: seeded 0.1.0 does not unconditionally make the first Release PR or released version 0.1.1

## Rerun

I reran the revision-3 release-please claims from the run directory on macOS. The focused rerun
fetched the pinned `v17.11.2` README, schema, manifest source, manifest documentation, Rust and
base strategies, and default versioning strategy. It installed `release-please@17.11.2` in an
isolated `/private/tmp` directory with an isolated npm cache, then executed the recorded
four-configuration, three-start-version, three-commit-type bump probe. I also compared the four
`- assumes` lines directly with `docs/port/PARAMETERS.md`. The Linux VM was deliberately not
started because the task required light host use. The rerun exited 0. Its complete output is
`review/evidence/audit-r25-r3.log`. The vocabulary, division of labour, manifest-existence claim,
bootstrap-sha claim, bump table, and parameters match the decision. The unconditional `0.1.1`
claims do not match the rerun.

## Findings

1. **Reject: the seeded-manifest consequence is overstated.** `review/DECISION.md:29`,
   `review/DECISION.md:295-296`, and `review/DECISION.md:635-640` state that seeding
   `{ ".": "0.1.0" }` makes the first release or Release PR `0.1.1`. The pinned manifest
   documentation supports the narrower premise: a manifest entry is the package's
   last-released/current version. `Manifest` then backfills it as `latestRelease`, and
   `BaseStrategy.buildNewVersion` applies the versioning strategy to subsequent conventional
   commits. The fresh pinned-package probe shows the counterexample: from `0.1.0` with both
   recommended flags, `feat!:` produces `0.2.0`. The decision must say that the seed makes
   `0.1.0` the previous release and that the next proposed version depends on the subsequent
   commits; it may describe `0.1.1` only for the demonstrated TypeScript history or for a stated
   patch/feature-only history.

2. **Confirmed: the vocabulary and division of labour are now accurate.** The pinned README says
   release-please maintains Release PRs, tells the repository to merge one, then tags the commit
   and creates a GitHub Release. It also says release-please does not publish to package managers.
   The decision no longer attributes the merge to release-please or infer registry publication
   from a tag or Release PR.

3. **Confirmed: the three other corrected tool-behaviour claims are supported.** The manifest
   documentation says a manifest file must exist at the target-branch tip and may be empty on the
   first run; `src/manifest.ts` uses `createIfMissing: false`. The same documentation says a first
   Release PR collects the default-branch history and names `bootstrap-sha` as the boundary. The
   revised runner statement no longer limits release-please to GitHub-hosted runners; it correctly
   scopes execution to the workflow's `runs-on` runner.

4. **Confirmed: the four fixed-parameter lines match byte-for-byte.** The audit's direct diff
   exited 0 for `msrv-policy`, `rust-edition`, `target-os-matrix`, and `license`.

## Assessment

Reject pending a narrow correction to the three unconditional `0.1.1` statements. The evidence
supports the empty-manifest recommendation and the release-actor vocabulary, but it does not fix
the next version independently of commit history. No implementation work was performed.
