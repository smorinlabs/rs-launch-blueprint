# Deep-research prompt — Contributors-bot credential source (R21, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: what credential the contributors-bot workflow's PAT fallback uses to open its bot PR — py's dedicated repo secret (`CONTRIBUTORS_PLEASE_PAT`) or ts's zero-extra-secret `GITHUB_TOKEN`. Item kind: `pattern`. Value test: if this answer is wrong, `.github/workflows/update-contributors.yml`'s credential-fallback step and this template's repo-secrets setup documentation both get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos run `smorinlabs/contributors-please-action` in `mode: pull-request` with the same PAT-fallback structure, but source the fallback token differently. Evidence: py `.github/workflows/update-contributors.yml:34` — `secrets.CONTRIBUTORS_PLEASE_PAT` (a dedicated repo secret the maintainer must configure); ts `.github/workflows/update-contributors.yml:80` — `secrets.GITHUB_TOKEN` (no extra secret needed). Ledger row F061 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, notes: "ts's choice lets the template work with zero extra repo secrets configured."
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-022(11) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Port the pattern as-is (branch-sync idempotency, bot commit, PR-not-push) with `checkout@v6` and current-major `peter-evans/create-pull-request`"; D-022(11) states that porting decision but not the credential-source rationale. The credential choice itself is `GITHUB_TOKEN`, and the reason is recorded in the ledger's F061 Notes (`docs/port/COMMONALITY.md`): "ts's choice lets the template work with zero extra repo secrets configured."
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): For this one, we should model it on what PyLaunch Blueprint does.

## Out of scope
- The contributors-bot workflow's trigger cadence (push-with-paths-ignore vs. a weekly cron schedule); R07 (`contributors-bot-trigger-cadence`) owns F026 — this item decides only the PAT-fallback credential source, not when the workflow runs.
- Whether the workflow uses `mode: pull-request` at all, or the action's other invocation modes — both source repos already agree on this (ledger row F060, `COMMON → REUSE`), it is not a research question for this item.
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
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: Is there a security trade-off between a long-lived dedicated PAT stored as a repo secret versus the ambient, automatically-scoped, automatically-rotated `GITHUB_TOKEN`, and how does that trade-off weigh for a public template whose consumers may not follow least-privilege PAT hygiene?
- LOW: Does documenting a "zero extra secret" setup story materially reduce first-run friction for template consumers compared to py's documented PAT-setup step, based on any adopter feedback or setup-guide comparison across similar GitHub template repositories?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + source link demonstrating adoption and why the project is a relevant, well-regarded reference |

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

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
