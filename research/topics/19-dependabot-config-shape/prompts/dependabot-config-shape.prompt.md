# Deep-research prompt — Dependabot config shape (R19, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of `dependabot.yml` configuration conventions (with the `cargo` ecosystem's current option set) for: which package ecosystems `rs-launch-blueprint`'s Dependabot config declares and what update-grouping strategy it applies, choosing between py's richer named-groups-plus-cooldown-plus-labels shape and ts's single minor/patch group per ecosystem. Item kind: `bundle`. Value test: if this answer is wrong, `.github/dependabot.yml`'s ecosystem list and its `groups`/`cooldown`/`labels`/commit-message-prefix keys all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos configure Dependabot, but diverge on ecosystems and grouping richness. Evidence: py `.github/dependabot.yml:14` — ecosystems `uv`, `github-actions`, `npm` (Bun-related deps only); ts `.github/dependabot.yml:28` — ecosystems `github-actions`, `npm` (covers the pnpm lockfile, since Dependabot's ecosystem id for pnpm stays `npm`). Ledger row F053, verdict `DIVERGENT`. py `.github/dependabot.yml:28` — named groups (runtime, dev-tools, lint-and-format, test) plus a 5-day cooldown, labels, and a commit-message prefix contract; ts `.github/dependabot.yml:34` — a single minor/patch update-type group per ecosystem, no cooldown/labels/commit-message customization. Ledger row F054, verdict `DIVERGENT`. Both rows are one Dependabot-config-shape decision (`docs/port/COMMONALITY.md` notes: "ecosystems and grouping are one Dependabot-config-shape decision").
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(8) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Dependabot via `.github/dependabot.yml` with `github-actions` + JS package ecosystems (`npm` key covers npm/pnpm/yarn; `bun` key if Bun wins), weekly, grouped minor/patch; Renovate documented as alternative only", chosen for GitHub-native zero-infrastructure automation that works from a single committed file for template consumers.

## Out of scope
- Whether a competing dependency-update bot (e.g. Renovate) should replace Dependabot entirely; both source repos use Dependabot and D-022(8) explicitly considered and rejected Renovate for ts — this item configures Dependabot, it does not re-open the bot-choice question.
- The scheduled full-dependency-graph vulnerability audit and the manual on-demand SCA scan tool; those are bundled into R13 (`dependency-vulnerability-scanning`)'s separate vulnerability-scanning decision, not this config-shape item.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R19
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which package ecosystems `rs-launch-blueprint`'s `dependabot.yml` declares (at minimum `cargo` and `github-actions`) and whether its update-grouping strategy follows py's named-groups-plus-cooldown-plus-labels shape or ts's single minor/patch group per ecosystem.
- HIGH: Does Dependabot's `cargo` ecosystem support the same grouping keys (`groups`, update-type filters) and the `cooldown` key that py's `uv`-ecosystem config uses, at Dependabot's current schema version?
- HIGH: For a template repository (not a long-lived application), does py's richer grouping (four named groups: runtime, dev-tools, lint-and-format, test) reduce PR noise meaningfully over ts's single minor/patch group, or is the added config complexity not worth it for a template's smaller Rust dependency surface?
- MEDIUM: Should the config also declare an ecosystem entry for the CI workflow files themselves (`github-actions`), and does that ecosystem's grouping need any Rust-specific adjustment versus py/ts's shared `github-actions` config?
- MEDIUM: Does py's 5-day cooldown and commit-message-prefix contract have a direct Dependabot-schema equivalent that a Cargo-ecosystem config can reuse unchanged?
- LOW: What labels (if any) should Dependabot apply to opened PRs, and does that choice depend on any label taxonomy already established elsewhere in the template's CI/lint conventions?

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
