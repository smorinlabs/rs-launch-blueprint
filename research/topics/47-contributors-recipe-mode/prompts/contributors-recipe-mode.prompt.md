# Deep-research prompt — Contributors-recipe mode (R47, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: which `contributors-please` subcommand `rs-launch-blueprint`'s local Justfile recipe invokes — a from-scratch bootstrap (`init`, py's pattern) or a ledger-to-Markdown render (`render`, ts's pattern) — relative to the CI bot workflow's own `pull-request` action mode. Item kind: `pattern`. Value test: if this answer is wrong, the local Justfile's contributors-update recipe body (which `contributors-please` subcommand it calls, and against what inputs) is rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos wire the same CI bot workflow (`contributors-please-action` in `mode: pull-request`), but their local Justfile recipes diverge in which `contributors-please` subcommand they call. py's local recipe runs a from-scratch bootstrap subcommand; ts's local recipe runs a render subcommand that reproduces the ledger-to-Markdown step the CI action itself performs. Evidence: py `Justfile:462` — `update-contributors:` runs `npx contributors-please@1 init --non-interactive ...`; ts `Justfile:244` — `@contributors:` runs `pnpm dlx contributors-please render`. Ledger row: F210 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Already decided, do not re-open: the CI-side automated contributors-list bot-PR workflow itself (the `contributors-please-action` in `mode: pull-request`) is `COMMON → REUSE` (F060, `docs/port/COMMONALITY.md`), and the `.contributors.yml`/`.contributors.jsonl` config schema is also `COMMON → REUSE` (F209) — this item decides only the local recipe's subcommand choice, not the CI workflow or the config schema underneath it. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-024(9) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — replaced py's `update_contributors.py` script plus its divergent Justfile recipe with the org's own `contributors-please` package (npm) and `contributors-please-action`, giving the recipe and the CI workflow a single shared implementation rather than py's bespoke from-scratch bootstrap script; the why-text explicitly calls py's local `init` recipe an "orphan" divergent from the CI action's own behavior, while ts's local `render` recipe reproduces the same ledger-to-Markdown render step the CI action performs.

## Out of scope
- The CI bot workflow itself and the `.contributors.yml`/`.contributors.jsonl` config schema; both are already `COMMON → REUSE` (F060, F209) — this item decides only which subcommand the local Justfile recipe calls.
- The task-runner tool (`just`) and its recipe-grouping/alias conventions; those are already `COMMON → REUSE` (F176–F178) — this item is a content pick within one recipe, not a tooling choice.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R47
- owns:
- consumes:
- related (not a registry dependency): none — the CI-side workflow this recipe complements is already settled (F060, `COMMON → REUSE`), so this item has no other research item's output as an input.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s local `contributors-please` Justfile recipe runs a from-scratch bootstrap subcommand (py's `init`) or a ledger-render subcommand that mirrors the CI bot's own action mode (ts's `render`), given `contributors-please` is a `pnpm dlx`/`npx`-invoked npm package in both source repos regardless of which recipe mode wins.
- HIGH: As of the research date, what subcommands does the current `contributors-please` npm package expose, and does a `render` (or equivalently-named) subcommand still reproduce the exact ledger-to-Markdown step the `contributors-please-action`'s `pull-request` mode performs — confirming ts's D-024(9) rationale still holds?
- HIGH: Is there still no Rust-native or Cargo-installable equivalent to `contributors-please` (it remains an npm package invoked via a package-manager-runner, e.g. `npx`/`pnpm dlx`), meaning this template's local recipe must shell out to Node regardless of which subcommand it calls?
- MEDIUM: Does a from-scratch bootstrap subcommand (py's `init`) serve any purpose a Rust template still needs — e.g. first-time `.contributors.jsonl` seeding — that a render-only recipe (ts's `render`) cannot cover, given `rs-launch-blueprint` starts from an empty history rather than porting an existing contributors ledger?
- LOW: Should the recipe's invocation mechanism (`npx contributors-please@1` vs. a package-manager-agnostic runner) itself be pinned to a version the way py's `@1` major-version pin does, or does that belong to a separate package-manager-invocation decision (R42, `package-manager-invocation`)?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).

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
