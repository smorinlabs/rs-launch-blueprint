# Deep-research prompt — Third-party GitHub Action pinning policy (R20, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: how `rs-launch-blueprint`'s workflows pin third-party (non-`actions/*`, non-`github/*`) GitHub Actions — py's floating major-version tag versus ts's full-commit-SHA pin plus a version comment. Item kind: `pattern`. Value test: if this answer is wrong, every third-party `uses:` line across the workflow files gets rewritten to a different pin format, and the Dependabot `github-actions` ecosystem config (which keeps SHA pins fresh) either gains or loses a reason to exist.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos pin official `actions/*`/`github/*` actions the same way (major-version tag); they diverge only on third-party actions. Evidence: py `.github/workflows/update-contributors.yml:27` — `smorinlabs/contributors-please-action@v1.3.9` (floating major-version tag); ts `.github/workflows/update-contributors.yml:74` — `smorinlabs/contributors-please-action@3c6dbff9…` (full SHA, with a version comment). Ledger row F055 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). Official `actions/*`/`github/*` actions stay major-tag-pinned in both source repos — this item does not re-open that half of the policy, only the third-party half.
- Prior decisions of the TypeScript port that explain the current shape: D-022(9) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Hybrid: major-tag pins for official `actions/*` and `github/*` actions; full-SHA pin + version comment for security-sensitive/third-party actions, kept fresh by Dependabot's `github-actions` ecosystem", chosen to follow the org's newest deliberate precedent (`difftree-action`'s `release-please.yml`) and because SHA pins pair with an update bot that keeps them current.

## Out of scope
- Which actionlint config entries (self-hosted runner labels, `RUNNER_*` config-variables) are needed; R09 (`self-hosted-runner-indirection`) owns that decision — this item's pinning-format question is contingent on nothing R09 decides.
- The Dependabot ecosystem list and grouping strategy that keeps SHA pins current; R19 (`dependabot-config-shape`) owns that config-shape decision — this item only decides whether third-party actions are SHA-pinned, not how the update bot is configured.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R20
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s third-party (non-`actions/*`, non-`github/*`) GitHub Actions are pinned by a floating major-version tag (py's shape) or by a full commit SHA plus a version comment (ts's shape), and what "third-party" means precisely for this template's action inventory.
- HIGH: What is the current supply-chain-security guidance (from GitHub's own documentation, OpenSSF, or a widely cited security advisory such as the `tj-actions/changed-files` incident) on SHA-pinning third-party GitHub Actions versus major-tag pinning, and does it draw the same official-vs-third-party boundary py/ts do?
- HIGH: Does SHA-pinning meaningfully increase maintenance burden for a template repository (versus an application repository) given the template ships example workflows a consumer will fork and may not re-pin themselves?
- MEDIUM: Is there a linting or CI tool (e.g. `zizmor`, actionlint extensions, or a dedicated SHA-pin-checker action) that enforces the chosen policy automatically, and would adopting it change the answer?
- LOW: Does the version-comment convention next to a SHA pin (`@<sha> # vX.Y.Z`) have an established idiom the template should follow verbatim, or does it vary meaningfully across adopters?

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
name · where documented · adopters that practice it · date of the most recent authoritative write-up.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
