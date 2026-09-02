# Deep-research prompt — Contributors-bot credential source (R21, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: what credential the contributors-bot workflow's PAT fallback uses to open its bot PR — py's dedicated repo secret (`CONTRIBUTORS_PLEASE_PAT`) or ts's zero-extra-secret `GITHUB_TOKEN`. Item kind: `pattern`. Value test: if this answer is wrong, `.github/workflows/update-contributors.yml`'s credential-fallback step and this template's repo-secrets setup documentation both get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos run `smorinlabs/contributors-please-action` in `mode: pull-request` with the same PAT-fallback structure, but source the fallback token differently. Evidence: py `.github/workflows/update-contributors.yml:34` — `secrets.CONTRIBUTORS_PLEASE_PAT` (a dedicated repo secret the maintainer must configure); ts `.github/workflows/update-contributors.yml:80` — `secrets.GITHUB_TOKEN` (no extra secret needed). Ledger row F061 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, notes: "ts's choice lets the template work with zero extra repo secrets configured."
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(11) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Port the pattern as-is (branch-sync idempotency, bot commit, PR-not-push) with `checkout@v6` and current-major `peter-evans/create-pull-request`"; D-022(11) states that porting decision but not the credential-source rationale. The credential choice itself is `GITHUB_TOKEN`, and the reason is recorded in the ledger's F061 Notes (`docs/port/COMMONALITY.md`): "ts's choice lets the template work with zero extra repo secrets configured."

## Out of scope
- The contributors-bot workflow's trigger cadence (push-with-paths-ignore vs. a weekly cron schedule); R07 (`contributors-bot-trigger-cadence`) owns F026 — this item decides only the PAT-fallback credential source, not when the workflow runs.
- Whether the workflow uses `mode: pull-request` at all, or the action's other invocation modes — both source repos already agree on this, it is not a research question for this item.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R21
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether the contributors-bot workflow's PAT-fallback token is sourced from a dedicated repo secret the maintainer must configure (py's shape) or from the ambient `secrets.GITHUB_TOKEN` (ts's shape), for a public template repository whose consumers fork it.
- HIGH: Does the default `GITHUB_TOKEN` in a forked/templated repository have sufficient permissions (with the workflow's declared `permissions:` grants) to open a bot PR via `peter-evans/create-pull-request` or `smorinlabs/contributors-please-action`'s `pull-request` mode, without any consumer setup step?
- HIGH: What capability, if any, does a dedicated PAT provide that `GITHUB_TOKEN` cannot — e.g. triggering downstream workflows on the bot's own PR (a known `GITHUB_TOKEN` limitation), or writing to protected branches — and does the contributors-bot PR actually need that capability?
- MEDIUM: Is there a security trade-off between a long-lived dedicated PAT stored as a repo secret versus the ambient, automatically-scoped, automatically-rotated `GITHUB_TOKEN`, and how does that trade-off weigh for a public template whose consumers may not follow least-privilege PAT hygiene?
- LOW: Does documenting a "zero extra secret" setup story materially reduce first-run friction for template consumers compared to py's documented PAT-setup step, based on any adopter feedback or setup-guide comparison across similar GitHub template repositories?

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
