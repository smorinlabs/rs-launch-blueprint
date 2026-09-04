# Deep-research prompt — Secret-scanning CI workflow (R17, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named tool (with a version range) for: whether and how `rs-launch-blueprint` runs a dedicated CI-tier secret-scanning workflow, matching py's separate TruffleHog job (verified-only, diff-scan on PR, full scan on push) rather than relying solely on a commit-hook-tier scanner. Item kind: `crate`. Value test: if this answer is wrong, the CI-tier secret-scan workflow file, its scan-mode/trigger configuration, and any tool-setup step all get rewritten around a different tool or dropped entirely.

## Context
- Inherited pattern (spec §2, presumption of reuse): py runs a dedicated CI-tier secret-scanning workflow, distinct in both tool and tier from any commit-hook-tier scanner; ts has no CI-level secret-scan workflow at all. Evidence: py `.github/workflows/secret-scan.yml:1` — TruffleHog, `--only-verified`, diff-scan on PR / full scan on push; ts: none (no CI secret-scan workflow exists anywhere in `.github/workflows/`). Ledger row F050 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a CI-tier secret-scanning workflow, so `TS_PORT_DECISIONS.md` has no entry to carry forward.

## Out of scope
- The pre-commit/pre-push hook-tier secret-scanning tool and its allowlist/fingerprint-suppression configuration (a gitleaks-equivalent); R39 (`secret-scanning-hooks`) owns F163-F166 — this item decides only the CI-workflow-tier tool, a genuinely separate tool and tier from R39's hook-tier scanner, not bundled with it.
- Where in the job graph the resulting workflow's result is aggregated into a single required check; R11 (`ci-workflow-job-structure`) decides what jobs exist and R12 (`aggregate-required-status-check`) decides how their results fold into one required check — this item's tool choice is independent of both.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R17
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` runs a dedicated CI-tier secret-scanning workflow at all and, if so, which tool, in what scan mode, on what triggers.
- HIGH: Does a Rust-ecosystem-relevant tool exist that reaches parity with TruffleHog's verified-only detection (reducing false positives to confirmed live credentials) as a GitHub Actions step, or does the template need to keep using TruffleHog's own GitHub Action regardless of language?
- HIGH: Should the CI-tier scan run in diff-scan mode on pull requests and full-repository mode on pushes to `main` (py's split), or is a single scan mode sufficient given the template also (per R39) may run a hook-tier scanner locally?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`).
- MEDIUM: What is the maintenance and false-positive-rate trade-off between TruffleHog and alternative secret-detection engines (e.g. Gitleaks used as a CI action rather than a hook, detect-secrets) when run as a standalone CI job rather than a pre-commit hook?
- LOW: Does the chosen tool need any repository-specific configuration (custom detectors, path exclusions) beyond its default ruleset for a Rust CLI/library/web template?

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
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
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
