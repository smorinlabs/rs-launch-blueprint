# Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: whether `rs-launch-blueprint` starts its release-please-managed version at pre-1.0 with `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` semantics (ts's shape, currently at 0.1.3) or starts post-1.0 with standard semver bump semantics (py's shape, currently at 2.4.2). Item kind: `pattern`. Value test: if this answer is wrong, the template's first-published version number, `release-please-config.json`'s bump-strategy flags, and `Cargo.toml`'s initial `version` field all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): only ts has this feature — it is pre-1.0 and configures release-please's pre-1.0 bump dampening; py is already post-1.0 and has no such config. Evidence: ts `release-please-config.json:6` — `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` both set `true`; py: none (`release-please-config.json` has no equivalent keys; py's current version is 2.4.2, ts's is 0.1.3). Ledger row F070 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `ts-only`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The version source of truth is `Cargo.toml`'s `[package] version` field (ledger row F063, `COMMON → REUSE`, not a research item) — this item decides the bump-strategy semantics applied to that field, not where the field lives.
- Prior decisions of the TypeScript port that explain the current shape: D-021(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "`package.json` version bumped exclusively by release-please v5.0.0 manifest-mode Release PRs (`release-type: node`, `bump-minor-pre-major`, `include-v-in-tag`), GitHub App token auth; tags remain the release trigger" — `rs-launch-blueprint`, as a brand-new Rust port with no prior 1.0 release, is in the same "starting fresh" position ts was when it made this choice.

## Out of scope
- The release-please auth mechanism, publish-workflow tag/version consistency guard, and OIDC Trusted Publishing shape — those are separate `COMMON → REUSE` rows (F072 auth token, F074 tag/version guard, F075 OIDC publishing); this item decides only the numeric bump-strategy semantics.
- Whether `rs-launch-blueprint` uses release-please at all as its release tool — both source repos already use it (ledger rows F063, F066 and F073, `COMMON → REUSE`) and this item assumes that choice; it decides only the pre-1.0-vs-post-1.0 bump dampening within it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R25
- owns:
- consumes:
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` launches at a pre-1.0 version with release-please's `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` dampening enabled (feat commits bump the minor digit, not major; fix commits bump patch even under a `0.x` minor) or launches post-1.0 with standard semver bump semantics from its first release.
- HIGH: Given `rs-launch-blueprint` is a brand-new Rust port with no existing consumers or published crate history, does the Rust/Cargo ecosystem's own convention for a new crate's initial version (`0.1.0` vs `1.0.0`) argue for one strategy over the other independent of what py or ts did?
- HIGH: Does `cargo`'s own semver interpretation of a `0.x` version (where a minor bump is treated as breaking, per Cargo's caret-requirement default) change how `bump-minor-pre-major` should be understood for a Rust crate specifically, versus npm's `0.x` semver interpretation ts's choice was made under?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: What do release-please's own current-version docs say about the `bump-minor-pre-major`/`bump-patch-for-minor-pre-major` flags' interaction with a `release-type: rust` (or generic) config, and are both flags supported identically for Rust as for Node?
- LOW: Does the template's library-crate nature (published to crates.io, unlike py's application-shaped nature) push toward pre-1.0 caution (many crates.io libraries stay pre-1.0 for years) more strongly than it pushed for ts?

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
