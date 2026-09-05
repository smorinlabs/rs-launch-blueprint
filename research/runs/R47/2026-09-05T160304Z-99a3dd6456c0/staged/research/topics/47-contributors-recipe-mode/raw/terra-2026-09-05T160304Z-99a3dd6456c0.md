## Figures

Checked 2026-09-05 by `evidence-terra-2026-09-05T160304Z-99a3dd6456c0`.

- **ok** — `GET https://registry.npmjs.org/contributors-please` reports `latest` = `1.4.3`, matching the report.
- **ok** — The same npm endpoint records version `1.4.3` at `2026-06-17T20:17:06.907Z`, matching the reported 2026-06-17 release date.
- **ok** — The same npm endpoint reports MIT license and Node engine `>=24` for `1.4.3`.
- **ok** — `contributors-please-action` `package.json` and `package-lock.json` report action version `1.3.9`; its lockfile's `../contributors-please` package is version `1.4.3`.
- **ok** — The action's `action.yml` declares `runs.using: node24`.
- **unverifiable** — The bounded absence claim for a maintained Rust-native equivalent cannot be repeated: both `https://crates.io/search?q=contributors` and the crates API search returned HTTP 403. The raw report properly frames this as a bounded survey and evidence gap, not proof of universal absence.

No crate download, release, advisory, GitHub stars, open-issue, or responsiveness figures appear in the raw report. That is appropriate for this pattern item: it selects an external npm repository recipe rather than a Cargo crate. GitHub's repository metadata endpoint also returned HTTP 403, but the report does not rely on GitHub REST figures.

## Gates

- **ok** — The external-tool license gate passes: npm metadata for `contributors-please@1.4.3` is MIT. Rust MSRV, RustSec, `unsafe`, Cargo features, binary size, and compile cost are inapplicable because this is not a Cargo dependency.
- **ok** — The action's Node 24 runtime is verified from `action.yml`; the report correctly leaves local Ubuntu/macOS provisioning to R42 rather than asserting that R47 establishes it.
- **ok** — `render` reads the configured state file and renders/writes Markdown, while `init` creates a GitHub client, calls `Contributors.run()`, and writes both state and output. `Contributors.run()` rejects a missing state file unless `bootstrap` is true; `openPullRequest()` calls that same `run()` before its Git and pull-request side effects.
- **ok** — `git-cliff` is correctly excluded by capability. Its maintained documentation describes a Git-history changelog generator; it does not provide the contributor JSONL ledger, identity join, and path-classification contract required here. Its published Cargo manifest is MIT OR Apache-2.0, so this is not a license exclusion.
- **unverifiable** — The gate exclusion for a hypothetical Rust-native exact equivalent cannot be independently repeated because the cited crates.io search is currently unavailable (HTTP 403). No contrary candidate was found through the checked maintained references.

## References

- **ok** — The maintained `contributors-please` implementation exists: npm's current published package is `1.4.3`, its Git remote resolves at HEAD, and its `main` commit feed was updated 2026-09-01. Its README, CLI, and engine confirm the documented `validate`, `render`, and `init` operations.
- **ok** — The maintained `contributors-please-action` implementation exists: its Git remote resolves at HEAD, its `main` commit feed was updated 2026-09-01, and its action metadata/source verify `pull-request` dispatch and bootstrap support.
- **ok** — The cited pinned reference implementations exist in the local source repositories: py's `Justfile` invokes `npx {{contributors_package}} init --non-interactive`; ts's `Justfile` invokes `pnpm dlx contributors-please render`; ts's workflow uses `mode: pull-request` and `bootstrap: 'true'`.
- **ok** — The proposed guarded bootstrap-plus-render recipe is not claimed to be an existing adopter pattern. Its two branches are supported by the maintained CLI/action behavior, so it is a valid reference implementation for the recommendation.

## Verdict

**sound.** There are no wrong checked figures, gate claims, or reference claims. The only limitation is the current crates.io HTTP 403, which prevents rerunning the report's bounded negative search but does not contradict its explicitly limited absence claim.
