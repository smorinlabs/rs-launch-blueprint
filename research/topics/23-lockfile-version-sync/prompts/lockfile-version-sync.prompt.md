# Deep-research prompt — Lockfile version sync in release commit (R23, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: whether release-please's release commit must also bump `Cargo.lock`'s workspace-member version entries, matching py's `extra-files` sync of `uv.lock`'s editable-root version rather than ts's no-sync-needed stance (`pnpm-lock.yaml` carries no root version field). Item kind: `pattern`. Value test: if this answer is wrong, `release-please-config.json`'s `extra-files` array either gains or loses a `Cargo.lock` entry, and the release-PR diff either does or does not include a `Cargo.lock` change.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's lockfile encodes a version release-please must sync; ts's does not. Evidence: py `release-please-config.json:16` — an `extra-files` jsonpath entry bumps `uv.lock`'s editable-root version; ts `.github/workflows/release-please.yml:27` — a comment stating `pnpm-lock.yaml` has no root version field, so no sync is needed. Ledger row F065 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. The area file's own note observes: "Cargo.lock does encode workspace-member versions, like uv.lock" — i.e. Rust's lockfile shape matches py's, not ts's.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts's decision here is a negative one ("no sync needed") that does not transfer, since `Cargo.lock`, unlike `pnpm-lock.yaml`, does encode a workspace member's version.

## Out of scope
- The publish workflow's separate tag/version consistency guard (verifying the pushed tag matches the manifest version before publishing); that is a distinct release-versioning decision from this item's release-commit lockfile sync.
- Whether release-please's `extra-files` mechanism itself (versus some other bump mechanism) is used at all for any file; that tool choice is settled — release-please is inherited under spec §2 (ledger rows F063, F066 and F073, `COMMON → REUSE`, no research item) — this item only asks whether `Cargo.lock` is one of the files it targets.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R23
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s release-please config must sync `Cargo.lock`'s workspace-member version entries in the same release commit that bumps `Cargo.toml`, and by what jsonpath/mechanism.
- HIGH: Does `Cargo.lock` actually encode a workspace member's own package version in a way that goes stale if `Cargo.toml`'s `[package] version` is bumped without also regenerating the lockfile — confirm this against a real `cargo build`/`cargo update -p <workspace-member>` run's effect on `Cargo.lock`'s `[[package]] version` entry for that member?
- HIGH: Does release-please's `extra-files` `jsonpath` mechanism (used for `uv.lock` in py) work against `Cargo.lock`'s TOML structure, or does `Cargo.lock` need a different release-please `extra-files` type (e.g. a generic regex/TOML updater) or a companion `cargo update -p <name> --precise <version>` step run by the release workflow itself?
- MEDIUM: If release-please cannot directly patch `Cargo.lock`, is the idiomatic alternative a pre-tag CI step that runs `cargo update -p <workspace-member>` and commits the result, and does that fit release-please's Release-PR flow without introducing a second commit after the PR is opened?
- LOW: Does a multi-crate Cargo workspace (if the template ends up as one) change which member(s) `Cargo.lock` needs synced, versus a single-crate layout?

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

### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
### Recommendation
### Ranked runner-up
And the condition under which it wins.
### Tradeoffs
What the pick gives up versus each runner-up and why that cost is accepted.
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
