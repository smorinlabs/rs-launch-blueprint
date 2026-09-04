# Deep-research prompt — Large-file guard strategy (R14, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation, no crate involved) for: whether `rs-launch-blueprint` guards against accidentally-committed large files at both the CI tier (a dedicated workflow rejecting new files over a size threshold) and the git-hook tier (a pre-commit/pre-push hook rejecting staged files over a size threshold), and, if both tiers are kept, what size threshold and path-exemption rule each uses. Item kind: `bundle`. Value test: if this answer is wrong, either a CI-level `large-file-guard.yml`-equivalent workflow or the hook-tier large-file check (or both) get added, removed, or re-thresholded, changing what a contributor can accidentally commit and how late in the pipeline it is caught.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs a large-file guard at two independent tiers with two different thresholds and exemption rules. At the CI tier, a dedicated `large-file-guard.yml` workflow rejects any new file over 1 MB, exempting files under `docs/assets/`. At the hook tier, `lefthook.yml`'s `large-files` job rejects staged files over `1048576` bytes (1 MB), with the same `docs/assets/*` exemption. ts has no CI-tier guard at all, and its hook-tier `check-large-files` job uses a stricter 500 KB threshold (`512000` bytes) with no path exemption. Evidence: py `.github/workflows/large-file-guard.yml:4` — rejects new files over 1 MB outside `docs/assets/`; ts: none (py-only; ts has no CI-tier large-file workflow); py `lefthook.yml:137`,`lefthook.yml:143` — `large-files` job rejects staged files over `1048576` bytes (1 MB), exempting `docs/assets/*`; ts `lefthook.yml:42` — `check-large-files` job rejects staged files over `512000` bytes (500 KB), no path exemption. Ledger rows: F043 (`docs/port/COMMONALITY.md`, area `ci-workflows`), F172 (`docs/port/COMMONALITY.md`, area `git-hooks-commit-hygiene`), verdict `DIVERGENT`.
- Already decided, do not re-open: which hook manager runs the hook-tier check (`lefthook` or an alternative) is R37's decision (`hook-manager-distribution`) — this item decides only whether a large-file check exists at each tier and its threshold/exemption rule, not which tool executes the hook-tier half. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-020(6) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Extent of hook duties in lefthook.yml → pre-commit: parallel staged lint/format with stage_fixed (tool from T04) + tsc --noEmit + minimal hygiene checks (large-files etc., delegating whitespace/EOF to the formatter...)"; ts's decision record folds the large-file check into a broader "minimal hygiene checks" bucket with no separate rationale for its stricter 500 KB threshold or the dropped path exemption — ts's own D-020 "Why" section does not explain the specific threshold change.

## Out of scope
- Which hook manager executes the hook-tier check (`lefthook` vs. an alternative); R37 (`hook-manager-distribution`) owns that decision — this item assumes whatever hook manager R37 selects can run a file-size check and decides only the check's existence, threshold, and exemption rule.
- Every other hook-tier hygiene check bundled separately in py's `lefthook.yml` (whitespace/EOL, YAML lint, spell-check, actionlint); R40 (`auxiliary-hygiene-hooks`) owns F167-F170 — distinct checks, not bundled with the large-file guard.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R14
- owns:
- consumes:
- related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides whether `rs-launch-blueprint`'s CI checks are separate workflow files or jobs/steps inside `ci.yml`; py's CI-tier large-file guard is already its own dedicated workflow file (`large-file-guard.yml`), independent of `ci.yml`'s internal job structure, so this item's CI-tier recommendation does not need R11's value to be answered, only to be placed correctly relative to it.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` needs a CI-tier large-file guard in addition to a hook-tier one, and what size threshold and path-exemption rule each tier uses.
- HIGH: Does the hook-tier check alone (which every contributor's local git hooks enforce before a commit is even made) provide sufficient protection, or does the CI-tier guard earn its keep as a backstop against a contributor who bypasses hooks (`--no-verify`) or force-pushes from an environment where hooks were never installed?
- HIGH: What size threshold fits a Rust template — py's 1 MB or ts's stricter 500 KB — given Rust binaries, `target/` artifacts, and any bundled fixtures have different typical file-size profiles than Python or Node projects, and given `target/` is gitignored so committed-file size expectations are driven by source, docs, and test fixtures only?
- MEDIUM: Does a `docs/assets/*`-style path exemption (py's choice) make sense for `rs-launch-blueprint`, or does the template's docs tree (whichever shape R81's `docs-delivery-model` decision produces) have a different natural home for large binary assets that warrants a different exemption path or no exemption at all?
- LOW: Should the CI-tier and hook-tier checks share one threshold/exemption definition (a single source of truth referenced by both) to avoid the drift ts's port introduced (500 KB vs. py's 1 MB, with no stated reason), or is independent tuning per tier acceptable given they catch different failure windows?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

## Required evidence
Collect every figure exactly this way and cite endpoint + retrieval date (spec §7.6):
| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` | `crate.recent_downloads` |
| All-time downloads | same | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/<name>/versions` | newest with `yanked: false`: `num`, `created_at` |
| Stars, archived | `GET https://api.github.com/repos/<o>/<r>` | `stargazers_count`, `archived`, `pushed_at` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` | `total_count` (never `open_issues_count`) |
| Issue responsiveness | 10 most recently opened issues | median days to first maintainer response; unanswered count |
| Advisories | `https://rustsec.org/packages/<name>.html` | open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

Maintenance state by rubric, one of `active | stable-quiet | at-risk | dormant | archived`: no release in 6 months is a trigger to investigate, never the verdict; `at-risk` needs a concrete signal; `dormant` needs an unpatched advisory, a broken build on current stable, or a maintainer's own notice.

Fitness gates, answered per candidate **before** popularity is weighed; a failed gate lists the candidate under *Excluded by gate*:
1. license compatible with `MIT OR Apache-2.0`;
2. crate and dependency-tree MSRV within `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`;
3. no open RustSec advisory; `unsafe` posture stated;
4. builds and is tested on every OS in `ubuntu-latest, macos-latest` (CI badge or a stated platform list); Windows support noted, not required;
5. default features and any async-runtime coupling stated;
6. binary-size and compile-time cost stated qualitatively.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
### Parameters
`owns <param> = <value>` per owned parameter; `assumes <param> = <value>` per consumed one; any `CONFLICT:` lines.
### Migration implications
File-level changes in the template.
### Validation strategy
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
