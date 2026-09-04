# Deep-research prompt — PR-comment bot re-review trigger block (R45, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s PR template includes a "Review Trigger" section documenting the `@coderabbitai review` / `@greptile-apps review` / `@cubic-dev-ai review`-style comment commands that re-invoke AI review bots on demand. Item kind: `pattern`. Value test: if this answer is wrong, `.github/pull_request_template.md`'s content changes — a documented bot re-review trigger block is added or removed.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's PR template documents a "Review Trigger" section listing the `@`-mention comment commands that manually re-invoke each configured AI review bot; ts's PR template carries no such section, relying on the bots' auto-review-on-push behavior instead. Evidence: py `.github/pull_request_template.md:90` — "Review Trigger" section with `@coderabbitai review` / `@greptile-apps review` / `@cubic-dev-ai review`; ts: none (not carried into the ts PR template; ts relies on bots' auto-review-on-push only). Ledger row: F204 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: the PR template's pre-flight checklist section is `COMMON → REUSE` (F203, `docs/port/COMMONALITY.md`) — both repos keep a checklist, with wording tracking each repo's own tool names; this item decides only the separate re-review trigger block, not the checklist. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` has no entry addressing the PR-comment bot re-review trigger block; the ts port simply did not carry it forward.

## Out of scope
- Which AI review bots are configured at all (CodeRabbit, Greptile, cubic, or the org's own `claude-code-review` workflow) and their CI-side wiring; R18 (`ai-assisted-review-workflows`) owns F051/F052 — this item only decides whether a documented comment-trigger block exists in the PR template for whichever bots R18 resolves to, not which bots run.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R45
- owns:
- consumes:
- related (not a registry dependency): R18 (`ai-assisted-review-workflows`) decides which AI-assisted review bots this template configures at all; this item's trigger-block content, if adopted, must name whichever bots R18 resolves to rather than inventing its own bot list.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s PR template documents a "Review Trigger" comment-command section for manually re-invoking AI review bots, or omits it and relies on auto-review-on-push alone.
- HIGH: Do the currently-configured AI review bots for this org (CodeRabbit, Greptile, cubic, and/or `claude-code-review`) still support an `@`-mention comment command for manual re-review as of the research date, and what is each command's exact current syntax?
- HIGH: Is a documented re-review trigger block still a common, actively-recommended pattern among current GitHub PR-template conventions, or has auto-review-on-push made explicit re-trigger documentation redundant?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: Does documenting bot-specific comment commands in the PR template create a maintenance burden (staleness when a bot's command syntax changes) that argues for a lighter-weight approach — e.g. linking to each bot's own docs instead of inlining the command syntax?
- LOW: Should the trigger block live in the PR template itself (py's placement) or in a contributor-facing doc (e.g. `CONTRIBUTING.md`) that the PR template links to, given the PR template is user-facing per-PR content?

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
