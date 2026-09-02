# Deep-research prompt — Workflow permission hardening (R08, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation, no crate involved) for: how broadly `rs-launch-blueprint`'s GitHub Actions workflows apply checkout credential-persistence hardening (`persist-credentials: false`) and how consistently every workflow follows the deny-all-plus-re-grant permission pattern, including the contributors-bot workflow's own permission declaration style. Item kind: `bundle`. Value test: if this answer is wrong, the `permissions:` blocks and `actions/checkout` steps across every workflow file in the template get rewritten, and a workflow either leaks a persistable credential to a compromised action or fails from an over-narrow permission grant.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos already apply the deny-all-plus-re-grant permission baseline (F028, `COMMON → REUSE`, inherited as-is), but diverge on two related hardening questions. py applies `persist-credentials: false` narrowly, only on the shared difftree template workflow; ts applies it broadly, across `ci.yml`, `codeql.yml`, `publish.yml`, `dependency-review.yml`, and `manual-pr-security-scan.yml`. Separately, py's contributors-bot workflow declares its three permissions (contents/pull-requests/issues, all write) explicitly at the top level with no deny-all wrapper, while ts wraps the same workflow in the deny-all-plus-re-grant pattern used everywhere else. Evidence: py `.github/workflows/difftree-pr-comment.yml:55` — `persist-credentials: false` applied only there; ts `.github/workflows/ci.yml:57` — applied broadly (also `codeql.yml:101-102`, `publish.yml:51-52`, `dependency-review.yml:57-58`, `manual-pr-security-scan.yml:67-68`); py `.github/workflows/update-contributors.yml:11` — explicit contents/pull-requests/issues write at top level, no deny-all; ts `.github/workflows/update-contributors.yml:56` — deny-all `permissions: {}` at top, job re-grants the same three scopes. Ledger rows: F029, F030 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: the deny-all-plus-re-grant permission baseline itself is inherited as-is (F028, `COMMON → REUSE`); this item decides only how far `persist-credentials: false` extends and whether the contributors-bot workflow follows the same deny-all-plus-re-grant shape as every other workflow, not whether the baseline pattern is adopted. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(9) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "reuse existing repo decision"; D-022(10) — "Workflow permissions hygiene → Explicit top-level permissions on every workflow: contents: read baseline; permissions: {} deny-all with per-job grants on release/token-bearing workflows... Normalizes the source's declared-but-inconsistent least-privilege intent using the org's established deny-all pattern." ts's own evidence note additionally labels `persist-credentials: false` "the zizmor artipacked mitigation," naming the specific supply-chain attack class the broad application defends against.

## Out of scope
- Third-party GitHub Action pinning policy (SHA-pin vs. major-tag); R20 (`third-party-action-pinning-policy`) owns F055 — a separate hardening axis from permission scoping.
- Which specific jobs exist and how many workflows are split into how many jobs; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides the permission-declaration style applied to whatever jobs exist, not the job topology itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R08
- owns:
- consumes:
- related (not a registry dependency): R11 (`ci-workflow-job-structure`) decides how many jobs exist per workflow and owns `ci-job-structure`; this item's per-job re-grant pattern applies uniformly regardless of R11's answer, so no parameter value is needed from it.

If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how broadly `rs-launch-blueprint` applies `persist-credentials: false` on `actions/checkout` steps, and whether every workflow — including the contributors-bot workflow — follows the deny-all-plus-re-grant permission-declaration pattern with no exceptions.
- HIGH: Should `persist-credentials: false` be applied to every workflow's checkout step by default (ts's broad application, the zizmor artipacked mitigation) or only where a demonstrated risk exists (py's narrow application, one shared template workflow)? What does current GitHub Actions security guidance (zizmor, GitHub's own hardening docs) recommend as of the retrieval date?
- HIGH: Should the contributors-bot workflow follow the same deny-all-plus-re-grant pattern as every other workflow (ts's choice) or is an explicit top-level grant (py's choice) an acceptable, equally auditable alternative for a workflow with a fixed, small permission set?
- MEDIUM: Is there a case where `persist-credentials: false` breaks a legitimate downstream step (e.g., a step that needs the checked-out credential to push) that the template must special-case?
- LOW: Does a lint or CI check (e.g., zizmor itself) exist that could enforce "every checkout step sets `persist-credentials: false`" mechanically, closing the gap between a stated policy and actual per-workflow conformance?

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
