# Deep-research prompt — Contributors-bot trigger cadence (R07, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: what triggers the automated contributors-list bot-PR workflow — a push-to-main event (py's shape) or a weekly scheduled cron plus manual dispatch (ts's shape). Item kind: `pattern`. Value test: if this answer is wrong, the `on:` trigger block of the template's contributors-bot workflow file gets rewritten and either stacks redundant noise on every merge to main or delays contributor recognition by up to a week.

## Context
- Inherited pattern (spec §2, presumption of reuse): py and ts diverge on trigger cadence for the same bot workflow. py fires the contributors-list update on every push to main (with paths-ignore) plus manual dispatch; ts deliberately moved to a weekly cron plus manual dispatch to avoid stacking noise on top of CI/CodeQL/dependency-review, which already run on every push. Evidence: py `.github/workflows/update-contributors.yml:3` — push to main with paths-ignore, plus workflow_dispatch; ts `.github/workflows/update-contributors.yml:49` — weekly cron schedule plus workflow_dispatch. Ledger row: F026 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: the bot action/tool itself and its wiring (branch-sync idempotency, bot commit, PR-not-push) is inherited as-is (F060, `docs/port/COMMONALITY.md`, `COMMON → REUSE`; tool `smorinlabs/contributors-please-action`) — this item decides only when the workflow fires, not what it runs. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none found — `TS_PORT_DECISIONS.md` D-022(11) covers only the bot pattern's port (`smorinlabs/contributors-please-action`), not the cadence change; the weekly-cron rationale is stated only in the area evidence note above, with no numbered decision record.

## Out of scope
- The bot workflow's underlying tool, its PR-not-push mechanics, and idempotency behavior; that tool is inherited as-is (F060, `COMMON → REUSE`) and is not re-researched here.
- The bot's credential source (dedicated repo secret vs. `GITHUB_TOKEN`); R21 (`contributors-bot-credential-source`) owns F061.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R07
- owns:
- consumes:
- related (not a registry dependency): R21 (`contributors-bot-credential-source`) decides the bot's credential source (F061) on the same workflow file; this item decides only the `on:` trigger, not the auth mechanism.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what event(s) trigger `rs-launch-blueprint`'s contributors-list bot-PR workflow — push-to-main with a path filter, a scheduled cron, both, or neither, plus manual dispatch.
- HIGH: Does a Rust template's contributors-list warrant push-triggered updates (immediate recognition, more workflow runs stacked on every merge) or is a scheduled cadence (ts's choice) the better default given CI, CodeQL, and dependency-review already run per-push?
- HIGH: If scheduled, what cadence (weekly, as ts chose, or another interval) balances contributor-recognition latency against workflow-run volume for a template repository with presumably lower commit frequency than either source's production repo?
- MEDIUM: Does a path filter (as py uses, `paths-ignore`) still make sense if the trigger moves to a schedule, or does path-filtering become moot once the trigger is time-based rather than event-based?
- LOW: Should `workflow_dispatch` (present in both sources) be kept regardless of the chosen automatic trigger, to let a maintainer force an update out-of-cycle?

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

### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up
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
