# Deep-research prompt — Packed-artifact content guard (R26, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of tooling/checks (with versions) for: whether `rs-launch-blueprint`'s publish workflow asserts, before publishing, that only the expected files are packed and that `cargo publish` has not silently altered package metadata — matching ts's `npm pack --dry-run --json` file-list assertion plus its guard against npm auto-correcting the `bin` field. Item kind: `bundle`. Value test: if this answer is wrong, the publish workflow's pre-publish verification step(s) — whatever asserts packed-file contents and metadata integrity — get rewritten or removed.

## Context
- Inherited pattern (spec §2, presumption of reuse): only ts has this guard, expressed as two related but distinct checks in its publish workflow; py has neither. Evidence: py: none for both facts below. F039 — ts `.github/workflows/publish.yml:112` — `npm pack --dry-run --json` parsed to assert `dist/`-plus-whitelist contents; runs at publish time, not in `ci.yml`. F078 — ts `.github/workflows/publish.yml:199` — fails the publish job if npm auto-corrects the package's `bin` field. Ledger rows F039 (`ci-workflows` area) and F078 (`release-versioning` area), both `docs/port/COMMONALITY.md`, verdict `DIVERGENT`, origin `ts-only`, explicitly bundled together in both rows' Notes as "one publish-content-verification item."
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-021(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — the publish workflow verify job checks tag-vs-`package.json`-version consistency, tag-on-main ancestry, and a pack dry-run, before a protected `npm` environment publish via OIDC Trusted Publishing; the `bin`-field auto-correction guard (F078) and the packed-file-list assertion (F039) are both part of that same verify job's content-integrity checks. D-035 (package-manager selection to pnpm 10) explains why the workflow installs/builds with pnpm but still runs `npm pack`/`npm publish` for the guard and the publish step themselves.

## Out of scope
- Whether the packed artifact, once published, actually installs and runs (an ephemeral install-and-run smoke test); R50 (`install-smoke-test`) owns F222 — confirmed as a separate decision at the Task 10 reconciliation: this item verifies packaged *content* before publish ("does what's packaged match expectations"), R50 verifies the installed artifact *runs*, and answering one does not settle the other.
- The publish workflow's tag/version consistency guard (tag reachable from main, tag equals the manifest version) and its OIDC Trusted Publishing mechanism; those are `same`-verdict, non-research facts already common to both source repos, not part of this item's content-integrity guard.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R26
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust-native check(s) `rs-launch-blueprint`'s publish workflow runs, before `cargo publish`, to assert that only the expected files are packed and that no package-metadata field has been silently altered.
- HIGH: Does `cargo package --list` (or `cargo publish --dry-run`, which also runs packaging) enumerate the exact file set that will ship, in a form a CI step can diff against an expected allowlist the way ts parses `npm pack --dry-run --json`'s file array?
- HIGH: Is there a Cargo-specific analogue to npm's `bin`-field auto-correction (a documented case where `cargo package`/`cargo publish` silently rewrites a `Cargo.toml` field from what the author wrote), or does Cargo's packaging step have no equivalent silent-rewrite behavior to guard against — and if none exists, does this half of the bundle become a documented non-issue rather than an active check?
- MEDIUM: Does `cargo package`'s default file-inclusion rules (respecting `.gitignore`/`include`/`exclude` in `Cargo.toml`) make an unexpected-file leak less likely than npm's default (which ships everything not excluded, a frequent source of accidental inclusion) — does that lower the value of this guard for a Rust template versus ts's Node one?
- MEDIUM: Where should the chosen check run — inside the publish workflow's verify job (ts's placement, at publish time) or earlier, as a CI-gate step on every PR (a stricter placement neither source repo uses)?
- LOW: Is there a maintained crate or GitHub Action that wraps `cargo package --list` diffing (rather than a hand-rolled shell/jq step, which is how ts implements its `npm pack` parsing), and is it worth adopting over a hand-rolled equivalent?

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
