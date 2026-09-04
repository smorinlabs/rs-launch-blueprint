# Deep-research prompt — AI-assisted review workflows (R18, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of workflow tooling (with versions) for: whether `rs-launch-blueprint` ships py's pair of AI-assisted GitHub Actions workflows — an automatic PR code-review job and an `@mention`-triggered assistant job, both built on the `anthropics/claude-code-action` family — and if so, on what triggers and with what bot-authorship guards. Item kind: `bundle`. Value test: if this answer is wrong, `.github/workflows/claude-code-review.yml` and `.github/workflows/claude.yml` (or their absence) and their trigger/permission configuration all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py ships two AI-assisted workflows from the same action family, adopted or dropped together; ts has neither. Evidence: py `.github/workflows/claude-code-review.yml:1` — `anthropics/claude-code-action@v1.0.175` on PR open/sync, skips bot-authored/bot-sent PRs; py `.github/workflows/claude.yml:1` — triggers on issue/PR-review comments and issues containing `@claude`; ts: none (neither workflow exists in `ts-launch-blueprint`). Ledger rows F051, F052 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, bundled together — same `claude-code-action` family, plausibly adopted or dropped together.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never adopted either workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The general permission-hardening pattern (deny-all baseline with per-job least-privilege grants) applied across every workflow in the repository; R08 (`workflow-permission-hardening`) owns that repo-wide convention — this item states what permissions these two specific workflows need, not the repo-wide hardening pattern itself.
- Whether the two workflows should be adopted independently rather than as one bundle is itself a question this item answers — do not treat "bundled together" as pre-decided; argue it from the same-action-family evidence above.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R18
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` ships an automatic AI-assisted PR code-review workflow, an `@mention`-triggered AI assistant workflow, both, or neither, and on what triggers, version pin, and bot-authorship guard.
- HIGH: Is `anthropics/claude-code-action` (or its current successor) still the maintained, versioned action family for both use cases, and what is its current stable version and release cadence?
- HIGH: Does the automatic PR-review workflow's bot-authored/bot-sent-PR skip guard (avoiding review loops on bot-opened PRs, e.g. from release-please or Dependabot) need any Rust-specific adjustment, or does py's guard logic (`.github/workflows/claude-code-review.yml:1`) port unchanged?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: What triggers should gate the `@mention` assistant workflow (issue comments, PR review comments, issue bodies) for a template repository, and does the action support scoping to just those three event types cleanly?
- MEDIUM: What secrets/credentials does the action require (an Anthropic API key, a GitHub App token, or both), and how does that requirement interact with a public template repository that downstream consumers fork?
- LOW: Are there known cost, rate-limit, or false-trigger issues reported by adopters running this action family on public template/starter repositories specifically?

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
