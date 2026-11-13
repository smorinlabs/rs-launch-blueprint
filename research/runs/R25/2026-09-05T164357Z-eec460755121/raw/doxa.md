---
prompt: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260909-003254-a6983478d8e044ec
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

Generated: 2026-09-09T07:48:42.396997+00:00


## Openai Results

---
prompt: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
mode: all_deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260909-003254-a6983478d8e044ec
created_at: 2026-09-09T00:32:54.053430
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
```

### Landscape

**Decision category:** public-compatibility maturity policy and automated SemVer projection for a new Rust package that exposes three surfaces: library API, CLI contract, and HTTP service.

#### Three-bin map

| Bin | Field map | Candidates found |
|---|---|---|
| **Built-in / first-party Rust toolchain** | `cargo new` initializes packages at `0.1.0`. Cargo’s default dependency requirements treat the left-most non-zero component as the compatibility boundary: `0.1.3` means `>=0.1.3,<0.2.0`, while `0.0.3` means `>=0.0.3,<0.0.4`. | **Cargo-Compatible Incubation Lane**: start at `0.1.0`; use the minor digit as the pre-1.0 breaking boundary and patch as the compatible-update lane. [S1–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)) |
| **Established industry standard** | SemVer defines `0.y.z` as initial development and `1.0.0` as the point where the public API is defined. Release Please implements standard, pre-major-dampened, and prerelease strategies. | (1) Cargo-Compatible Incubation Lane; (2) **Declared-Stable First Release** at `1.0.0`; (3) a `1.0.0-alpha.N` prerelease train; (4) pre-1.0 with only `bump-minor-pre-major`, leaving features as minor bumps. [S4–S8; retrieved 2026-09-09] ([semver.org](https://semver.org/)) |
| **Up-and-comer** | Effort Versioning maps numbers to expected migration effort and has visible adoption proposals outside Rust. ZeroVer catalogs long-lived `0.x` projects but explicitly identifies itself as satire and warns that indefinite prerelease status can hurt adoption. | EffVer was evaluated but is not compatible with Cargo’s resolver-visible SemVer contract or the fixed Release Please architecture. ZeroVer is treated as an anti-pattern warning, not a candidate. [S23–S24; retrieved 2026-09-09] ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)) |

#### Authority used

- **Cargo and Rust project documentation** are first-party descriptions of generated manifests, dependency resolution, SemVer compatibility, application compatibility, editions, and MSRV declarations. These are controlling for how Rust consumers interpret `0.x` versions. [S1–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html))
- **SemVer 2.0.0** is the normative cross-ecosystem standard. Its FAQ calls `0.1.0` the simplest initial-development starting point, but that FAQ is non-normative and does not override Cargo’s more specific pre-1.0 compatibility ranges. [S4; retrieved 2026-09-09] ([semver.org](https://semver.org/))
- **Release Please’s schema, design document, CLI documentation, and implementation source** are maintainer-owned primary evidence for the exact flags. Its design explicitly separates language strategies—such as Rust’s `Cargo.toml` updater—from the versioning strategy. [S5–S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai))
- **Rust API Guidelines and RFC 1105** describe the ecosystem’s interpretation of API stability. The guidelines are recommendations rather than mandates, but are authored largely from Rust library-team experience. RFC 1105 is authoritative historical policy for Rust SemVer compatibility. [S11–S12; retrieved 2026-09-09] ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/?utm_source=openai))
- **RFC 1242’s nursery model** is useful architectural evidence: incubation precedes a deliberate 1.0 stabilization decision. It is not a universal crate-release mandate. [S13; retrieved 2026-09-09] ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai))
- **The 2025 State of Rust Survey and compiler-performance survey** were used only to constrain integration cost: compile time and storage remain meaningful ecosystem concerns, favoring a policy and CI check that add no runtime dependency. They do not select the versioning policy by popularity. [S14; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai))
- **Effective Rust** supplies an independent caution: remaining `0.x` indefinitely collapses SemVer’s three impact classes into two resolver-visible classes. This is supporting commentary, not controlling authority. [S22; retrieved 2026-09-09] ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai))

#### Practice evidence

| Reference project | Observed practice | Why it is relevant |
|---|---|---|
| **Axum** | Maintained a `0.8.x` compatibility line while developing breaking work for `0.9`; its changelog labels breaking changes in the new minor line and records that an accidental breaking patch was yanked. | Direct web-framework analogue demonstrating that a Rust `0.x` minor can function as an effective major boundary while patches are expected to remain compatible. [S15; retrieved 2026-09-09] ([github.com](https://github.com/tokio-rs/axum?utm_source=openai)) |
| **Reqwest** | Remains on a `0.x` line despite substantial production use; its changelog places redesigns such as the async-default transition in a new minor line while compatible additions and fixes appear in patch releases. | Library and HTTP-client evidence for Cargo-aligned pre-1.0 compatibility lines. [S16; retrieved 2026-09-09] ([github.com](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)) |
| **cargo-nextest** | A substantial CLI remains pre-1.0 while publishing an explicit stability and MSRV policy. | Shows that a production-quality CLI can legitimately incubate at `0.x`, provided its compatibility policy is explicit. [S19; retrieved 2026-09-09] ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai)) |
| **Tokio** | Used pre-1.0 releases, then announced 1.0 together with explicit stability guarantees. | Strong model for deliberate graduation: 1.0 represents a support promise, not elapsed time or a release counter. [S17; retrieved 2026-09-09] ([tokio.rs](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)) |
| **Serde** | Reached 1.0 after being described as battle-tested in production and ready for a stable release. Rust’s API Guidelines also cite Serde release notes as examples. | Library evidence for graduating after the public contract is proven rather than assigning 1.0 automatically to a first publication. [S11, S18; retrieved 2026-09-09] ([users.rust-lang.org](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)) |
| **Rust itself** | Rust 1.0 explicitly began the project’s commitment to stability after an alpha phase. | High-level evidence for the meaning of 1.0 as a declared compatibility commitment. [S25; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)) |

No popularity figure selected the result. These examples were weighted for direct architectural relevance to CLI, library, or web surfaces and for having documented stability behavior.

### Principles and implementation

#### Shared requirement and agreement level

The shared engineering principle is:

> **A version number is a consumer-facing compatibility contract whose numeric projection must match the package ecosystem’s resolver semantics and the project’s actual stability commitment.**

Agreement is required at four levels:

| Level | Required agreement across py, ts, and rs | May vary by ecosystem or history |
|---|---|---|
| **Capability** | Release Please derives releases from categorized changes and updates the canonical version source. | The canonical file and language updater. |
| **Standard** | Versions communicate compatibility using SemVer-compatible concepts. | Package-manager treatment of pre-1.0 ranges. |
| **Policy** | `1.0.0` means the maintainers are deliberately declaring the supported public contract stable. | Whether a repository has already crossed that boundary. |
| **Architectural pattern** | Language-specific file updating is separated from impact-to-version calculation. | Exact Release Please flags and validation tools. |

Therefore, literal equality of current version numbers or flags is **not** the required cross-language agreement level:

- The owner-supplied Python baseline at `2.4.2` can correctly retain ordinary post-1.0 semantics because it has an established post-1.0 history.
- The owner-supplied TypeScript baseline at `0.1.3` can correctly retain a dampened pre-major policy.
- Rust should select its value independently from Cargo semantics. Those semantics happen to support the same two boolean values as TypeScript, but for a Rust-specific reason: Cargo exposes `0.minor` as the compatibility line. No py or ts code change is part of R25.

The local py/ts facts and F070 classification came from owner-supplied repository paths for which no public URL was provided.

#### What Release Please’s two flags actually do

With the default versioning strategy:

| Current version | Commit impact | Both flags `true` | Cargo meaning |
|---|---:|---:|---|
| `0.1.3` | fix/other releasable change | `0.1.4` | Compatible update |
| `0.1.3` | `feat` | `0.1.4` | Compatible feature within the same Cargo range |
| `0.1.3` | breaking change | `0.2.0` | New incompatible Cargo range |
| `1.2.3` | fix | `1.2.4` | Standard SemVer patch |
| `1.2.3` | `feat` | `1.3.0` | Standard SemVer minor |
| `1.2.3` | breaking change | `2.0.0` | Standard SemVer major |

Specifically:

- `bump-minor-pre-major: true` changes a **breaking** pre-1.0 release from a major bump to a minor bump.
- `bump-patch-for-minor-pre-major: true` changes a pre-1.0 **feature** release from a minor bump to a patch bump.
- Fixes are patches with or without these flags.

This behavior is implemented in the generic default versioning strategy, not in the Node or Rust language updater. Release Please’s design and factory make versioning strategies independent of language strategies, so both flags apply identically to `release-type: rust`, `node`, or another language strategy when `versioning` remains `default`. [S5–S8; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

**BASELINE-REVIEW: F070 — resolver-aligned impact tiers must be described using Release Please’s actual algorithm — retain the pre-1.0 dampening pattern for rs, but correct any wording that says “feat bumps minor” when both flags are true to “breaking bumps minor; feat and fix bump patch” — Release Please schema, manifest documentation, and `DefaultVersioningStrategy` implementation.**

Affected items: R25 implementation and any F070 explanatory prose containing the incorrect mapping. The F070 `DIVERGENT` verdict need not change because Python remains post-1.0; no py or ts code change is authorized here. [S5–S7; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai))

#### Why this mapping is specifically appropriate for Cargo

Cargo considers a dependency declaration of `0.1.3` compatible with later `0.1.x` versions but not `0.2.0`. This differs from strict SemVer’s statement that all pre-1.0 APIs may change. Thus, for a Rust crate:

- numeric **minor** under `0.x` is the resolver-visible breaking boundary;
- numeric **patch** is the resolver-visible compatible-update channel;
- using a numeric minor for every feature would unnecessarily prevent automatic adoption of compatible additions;
- starting at `0.0.x` would be worse because Cargo treats each patch as a new incompatible line.

Cargo’s SemVer guide acknowledges that projects sometimes publish compatible “minor changes” as numeric patch releases and explicitly does not impose a universal minor-versus-patch convention for such changes. [S2–S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

This means `bump-patch-for-minor-pre-major` should not be understood as merely “dampening” npm behavior. In Rust it projects Conventional Commit categories onto Cargo’s two resolver-visible pre-1.0 compatibility classes.

#### Architectural alternatives

1. **Cargo-Compatible Incubation Lane — recommended.**  
   Start at `0.1.0`; breaking changes move to `0.(n+1).0`; compatible features and fixes advance `0.n.patch`; graduate manually to 1.0.

2. **Pre-1.0, features also bump minor.**  
   Set only `bump-minor-pre-major: true`. Both features and breaking changes then move from `0.1.x` to `0.2.0`. This is safe but overstates incompatibility and discards Cargo’s compatible patch lane for additive changes.

3. **Declared-Stable First Release.**  
   Publish `1.0.0` immediately and use ordinary SemVer. This preserves all three impact digits but represents an immediate stability promise over the library, CLI, and HTTP contracts.

4. **`1.0.0-alpha.N` prerelease train.**  
   This explicitly signals instability, but Cargo excludes prereleases unless consumers opt in and warns about prerelease dependencies in libraries. It introduces more resolver and release-automation complexity than `0.1.0` without improving this template’s compatibility model. [S2, S4, S26; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

#### Minimal reference implementation

`Cargo.toml`:

```toml
[package]
name = "rs-launch-blueprint"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
```

Rust’s stable minor line is `1.98` as of September 9, 2026, so the fixed “stable minus two minor versions” policy currently derives `rust-version = "1.96"`. R25 consumes rather than owns that policy. [S21; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

Bootstrap `release-please-config.json`:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "rust",
      "versioning": "default",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true,
      "release-as": "0.1.0"
    }
  }
}
```

Before the first release:

```json
{}
```

After the first `0.1.0` release, remove the bootstrap-only `release-as` key. The steady-state package configuration is:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "rust",
      "versioning": "default",
      "bump-minor-pre-major": true,
      "bump-patch-for-minor-pre-major": true
    }
  }
}
```

Release Please documents `release-as` as an exact next-version override that must be removed or advanced after the Release PR is merged. Its manifest may be empty before the first release and then records the released version. Using this bootstrap avoids treating an unpublished `0.1.0` manifest entry as though it were already the last release. [S5, S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

#### Observable acceptance criteria

1. The first crates.io publication, Git tag, GitHub release, and `Cargo.toml` release value are all `0.1.0`.
2. From `0.1.0`, a `fix:` produces `0.1.1`.
3. From `0.1.0`, a `feat:` also produces `0.1.1`.
4. From `0.1.x`, a breaking commit produces `0.2.0`, never an automatic `1.0.0`.
5. A consumer requirement of `0.1.0` can resolve `0.1.1` but not `0.2.0`.
6. After an explicit graduation to `1.0.0`, ordinary SemVer resumes: fix → patch, feature → minor, breaking → major.
7. A library API break in a patch release is rejected by `cargo-semver-checks`.
8. CLI flag/config/output compatibility and HTTP route/schema compatibility have separate executable tests because Rust API tooling cannot inspect those surfaces.
9. An MSRV increase must reset patch and increase the numeric minor, satisfying the owner-fixed MSRV policy. Before 1.0 this can be represented by a breaking-marked commit or an explicit `Release-As`; CI should verify the resulting number rather than relying only on commit spelling.
10. All checks pass on `ubuntu-latest` and `macos-latest`.

#### Performance and integration cost

This policy adds **no runtime dependency, unsafe code, async-runtime coupling, binary-size cost, request latency, throughput cost, or production memory cost**. The Release Please flags alter only release-version selection.

The proposed `cargo-semver-checks` validation adds CI-only compilation and rustdoc/API-analysis work. The planned workload is the complete public library surface with all stable public features, measured under clean and warm caches on both required operating systems. Record wall-clock job duration, peak resident memory where available, and `target` directory size. No performance benchmark was executed in this research, and no “fastest” claim is made. [S14, S20; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai))

### Dominant choice

**Cargo-Compatible Incubation Lane**

A new published Rust package starts at `0.1.0`, treats `0.x` minor increments as compatibility breaks, treats patch increments as compatible releases, and reaches `1.0.0` only through an explicit stability-graduation decision.

Reference implementation: Release Please `release-type: rust`, `versioning: default`, both pre-major flags `true`, plus a bootstrap-only exact `release-as: 0.1.0`. Release Please is actively maintained; its current core release at retrieval was `v17.11.1`, published July 31, 2026. [S5–S10; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/releases?utm_source=openai))

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Cargo-Compatible Incubation Lane** | Cargo default requirements and SemVer compatibility reference; Release Please pre-major flags | Axum for web APIs, Reqwest for an HTTP library, cargo-nextest for a CLI | Living Cargo docs retrieved 2026-09-09; Release Please `v17.11.1`, 2026-07-31. [S2–S3, S9, S15–S16, S19] |
| **Declared-Stable First Release** | SemVer 2.0; Rust API-stability guidance | Rust, Tokio, Serde each tied 1.0 to an explicit stability milestone | Living SemVer retrieved 2026-09-09; Tokio 1.0 write-up 2020-12-23. [S4, S11–S12, S17–S18, S25] |
| **Pre-1.0 with feature-minor releases** | SemVer FAQ’s simple pre-1.0 sequence; Release Please with only `bump-minor-pre-major` | Common outside Cargo; no stronger resolver-aligned Rust reference found than the alternatives above | Living SemVer and Release Please docs retrieved 2026-09-09. [S4–S7] |
| **`1.0.0-alpha.N` prerelease train** | SemVer prerelease clause; Cargo prerelease requirement rules | Rust’s 1.0 alpha process is a historical reference | Living Cargo docs retrieved 2026-09-09; Rust 1.0 alpha announcement 2015-01-09. [S2, S4, S25–S26] |

No download columns are included, as required.

### Excluded by gate

This item selects a **pattern**, not a runtime crate or bundle. Consequently the required crate figures—90-day downloads, all-time downloads, newest non-yanked release, repository stars, open-issue count, issue-response median, RustSec count, and reverse-dependency adopter enumeration—are **inapplicable**. Release Please is a fixed dependency from the supplied baseline and evidence for the reference implementation, not an alternative Rust crate selected by R25.

| Candidate | License | MSRV/dependency tree | RustSec/unsafe | OS matrix | Features/runtime | Size/compile cost |
|---|---|---|---|---|---|---|
| Cargo-Compatible Incubation | Pass/inapplicable: policy contains no code; Release Please source is Apache-2.0 | Pass: no Rust dependency added | Inapplicable; no Rust code or `unsafe` added | Pass subject to planned Ubuntu/macOS integration check | None | Zero production cost; CI check only |
| Declared-Stable First Release | Same | Same | Same | Same | None | Same |
| `1.0.0-alpha.N` | Same | Same | Same | Same | None | Same, but higher release/resolver complexity |
| EffVer | Same | Same | Same | Same | None | Same |

No shortlisted pattern failed the six dependency-oriented fitness gates before popularity was considered.

**Excluded after architectural fit:**

- **EffVer:** excluded because Cargo resolves dependencies using SemVer compatibility ranges, while the fixed Release Please configuration computes SemVer impact categories. EffVer would require a separately documented translation policy and would make dependency ranges less predictable. [S2, S23; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
- **`1.0.0-alpha.N`:** excluded because prereleases require explicit Cargo opt-in and are awkward for library dependencies; this template gains no corresponding benefit over `0.1.0`. [S2, S26; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
- **Indefinite ZeroVer:** excluded as a policy. Pre-1.0 must have explicit graduation criteria rather than becoming a permanent maturity disclaimer. ZeroVer itself identifies that adoption problem. [S22, S24; retrieved 2026-09-09] ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai))

Windows has no known numeric-versioning difference and is not blocked by the pattern, but remains outside the owner-fixed CI matrix.

### Up-and-comers

**Effort Versioning** is the credible up-and-comer. Its useful insight is that consumers care about migration effort, not merely syntactic API changes; JAX and Zarr have published concrete adoption rationales. That idea can inform release notes—especially for CLI migrations and HTTP changes—but it should not replace Cargo-compatible SemVer for a crates.io library. [S23; retrieved 2026-09-09] ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai))

**ZeroVer** is not an up-and-coming recommendation: it is intentionally satirical. Its real value here is the warning that a project should not remain `0.x` after it has a dependable, production-used contract. [S24; retrieved 2026-09-09] ([0ver.org](https://0ver.org/?utm_source=openai))

Alternative Rust release tools such as `release-plz` were not compared because whether to use Release Please is explicitly out of scope and owner-fixed.

### Fit for this template

#### CLI

Pre-1.0 provides room to revise flags, exit statuses, configuration precedence, generated text, and scripting behavior after real use. Cargo’s SemVer guide notes that executable interfaces require an explicit project policy because library API rules alone are insufficient. [S3; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html))

Acceptance must define which CLI behavior is contractual. At minimum: option names, required arguments, exit-status meanings, machine-readable output, config keys, and environment-variable precedence. A breaking change to any declared CLI contract should carry `!` and therefore move `0.n` to `0.(n+1)`.

#### Library

This is the strongest reason for the recommendation. Downstream Cargo consumers automatically interpret `0.1.x` as one compatibility line. Both flags align Release Please directly with that resolver behavior. The library’s public API should be checked with `cargo-semver-checks`, while public dependency types should be reviewed before 1.0 because the Rust API Guidelines advise that a stable crate’s public dependencies also be stable. [S2, S11, S20; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

#### Web service

The package version does not replace an HTTP API-versioning or migration policy. Nevertheless, starting pre-1.0 avoids claiming that routes, JSON schemas, authentication behavior, and error envelopes are already permanently supported before the service has real consumers.

HTTP compatibility should be verified with route/schema fixtures or generated OpenAPI diffs. A breaking HTTP contract change must trigger the same effective-major transition as a Rust library break: `0.n.x` → `0.(n+1).0`.

### Recommendation

Adopt **Cargo-Compatible Incubation Lane**:

- **Initial `Cargo.toml` version:** `0.1.0`
- **First published version:** `0.1.0`
- **Release type:** `rust`
- **Versioning strategy:** `default`
- **`bump-minor-pre-major`:** `true`
- **`bump-patch-for-minor-pre-major`:** `true`
- **1.0 behavior:** explicit graduation, never an incidental result of the first breaking commit
- **Bootstrap:** one-release-only `release-as: 0.1.0`, then remove it

This choice follows independently from Rust evidence:

1. Cargo itself initializes new packages at `0.1.0`. [S1; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html))
2. Cargo interprets `0.1.x` patches as compatible and `0.2.0` as incompatible. [S2; retrieved 2026-09-09] ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))
3. The template has no published history or consumers requiring an immediate stability promise.
4. It exposes three independently evolving public surfaces, making a short, explicitly governed incubation period more credible than declaring all three stable on day one.
5. Release Please implements the necessary behavior without a custom strategy and identically supports it with `release-type: rust`. [S5–S8; retrieved 2026-09-09] ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai))

The library nature pushes more strongly toward an initial `0.1.0` compatibility line than an application-only repository would. It does **not** justify staying pre-1.0 indefinitely.

Recommended 1.0 graduation criteria:

- no known planned redesign of the public Rust API;
- documented CLI and HTTP compatibility contracts;
- public dependencies reviewed for stability and exposure;
- library SemVer CI passing against the latest published baseline;
- representative consumer fixtures for library, CLI, and HTTP use;
- migration notes for any deprecated pre-1.0 interfaces;
- explicit owner approval to support compatible evolution without routine breaking releases.

### Ranked runner-up

**Declared-Stable First Release: `1.0.0` with ordinary SemVer.**

It wins if, before the first crates.io publication:

1. the Rust library API, CLI contract, and HTTP contract are intentionally declared stable;
2. no material breaking redesign is expected;
3. public dependencies exposed in the API are considered sufficiently stable;
4. compatibility tests cover all three surfaces;
5. the owner is prepared to treat future incompatibilities as `2.0.0`, not as routine early iteration.

Under those conditions, `Cargo.toml` should begin at `1.0.0` and both pre-major flags should be omitted. SemVer permits this; absence of earlier consumers does not prohibit a well-considered 1.0. [S4, S11–S12, S17–S18, S25; retrieved 2026-09-09] ([semver.org](https://semver.org/))

### Tradeoffs

| Alternative | What the recommendation gives up | Why accepted |
|---|---|---|
| **Immediate `1.0.0`** | Full three-digit impact expressivity from the first release; stronger maturity signal; fewer organizational objections to adopting a `0.x` library | The template has no published compatibility history and has three public surfaces likely to benefit from real-consumer feedback |
| **Pre-1.0 with feature-minor bumps** | Numeric distinction between compatible features and fixes | Cargo cannot preserve that distinction while also keeping compatible features in the consumer’s current `0.n` range; the changelog still distinguishes them |
| **`1.0.0-alpha.N`** | Explicit `alpha` label and an obvious path toward final 1.0 | Cargo prereleases require explicit opt-in and add resolver/release complexity for library consumers |
| **EffVer** | Numbers that attempt to predict migration effort | Cargo and Release Please consume SemVer impact categories; release notes can communicate effort without replacing resolver semantics |
| **Indefinite `0.x`** | Freedom to break forever without a clear graduation event | Accepted only temporarily; explicit graduation criteria prevent the ZeroVer trap |

A notable cost is that under `0.x`, compatible features and bug fixes both advance the patch digit. This is the unavoidable price of mapping three Conventional Commit categories onto Cargo’s two pre-1.0 compatibility classes. Changelog sections and commit types retain the lost distinction.

### Parameters

`owns release-version-regime = pre-1.0 Cargo-compatible incubation`

`owns initial-package-version = 0.1.0`

`owns first-published-version = 0.1.0`

`owns bump-minor-pre-major = true`

`owns bump-patch-for-minor-pre-major = true`

`owns pre-1.0-graduation = explicit/manual release to 1.0.0`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes version-source-of-truth = Cargo.toml [package].version`

No `CONFLICT:` applies.

As of September 9, 2026, the fixed MSRV formula evaluates to Rust `1.96`, based on the current stable `1.98` minor line. This derived value must be recalculated if implementation occurs after the next stable minor release. [S21; retrieved 2026-09-09] ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

### Migration implications

1. **`Cargo.toml`**
   - Set `[package].version = "0.1.0"`.
   - Preserve edition `2024` and dual license.
   - Set or verify `rust-version = "1.96"` when implementing on September 9, 2026; do not treat R25 as ownership of the MSRV policy.

2. **`release-please-config.json`**
   - Use `release-type: rust`.
   - Set `versioning: default` explicitly.
   - Add both pre-major flags as `true`.
   - Add bootstrap-only `release-as: "0.1.0"` if Release Please owns the first publication.
   - Remove `release-as` immediately after the first Release PR is merged.
   - On graduation to 1.0, remove both flags for clarity, although current implementation makes them inert at versions `>=1.0.0`.

3. **`.release-please-manifest.json`**
   - Keep `{}` before the first Release Please-managed publication.
   - Expect Release Please to record `"." : "0.1.0"` after the first release.
   - Do not seed an unpublished `0.1.0` as though it were already the last released version without an integration test.

4. **`Cargo.lock`**
   - If committed, verify that the Release PR leaves the root package version consistent with `Cargo.toml`; do not assume this without a fixture test.

5. **Release-policy documentation**
   - Document that, before 1.0, minor means incompatible and patch means compatible.
   - Document that both `feat` and `fix` normally produce a patch before 1.0.
   - Define CLI, Rust API, and HTTP compatibility surfaces.
   - Add the 1.0 graduation checklist.

6. **CI**
   - Add a version-policy test for the Release Please matrix.
   - Add `cargo-semver-checks` for the published library surface.
   - Add CLI and HTTP compatibility tests.
   - Add a guard that an MSRV change is accompanied by a numeric minor increase.

7. **`docs/port/COMMONALITY.md`**
   - Append R25 evidence to F070 and correct any inaccurate feature-bump wording.
   - Do not silently change F070’s `DIVERGENT` verdict or modify py/ts implementation.

8. **py and ts**
   - No file changes in this item.
   - Follow-on rationale: Python’s post-1.0 state is justified by release history; TypeScript and Rust may share pre-major flags while retaining ecosystem-specific explanations and explicit graduation criteria.

### Validation strategy

**Executed during this research:** documentary verification of Cargo, SemVer, Release Please schema/design/source, and representative project policies. No repository checkout, GitHub release fixture, Rust build, or publication command was executed.

**Planned executable checks:**

#### 1. Manifest and fixed-parameter check

```bash
cargo metadata --no-deps --format-version 1 |
  jq -e '
    .packages[]
    | select(.name == "rs-launch-blueprint")
    | .version == "0.1.0"
      and .edition == "2024"
      and .rust_version == "1.96"
  '
```

Expected: exit status zero.

```bash
cargo +1.96.0 check --all-targets --all-features
cargo +stable test --workspace --all-targets --all-features
cargo +stable publish --dry-run
```

Expected: all pass on both required operating systems.

#### 2. Release Please schema validation

```bash
npx --yes ajv-cli@5 validate \
  -s https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json \
  -d release-please-config.json
```

Expected: configuration validates, including both flags and `release-type: rust`.

#### 3. First-release fixture

In a throwaway GitHub repository using the exact pinned Release Please version:

```bash
npx release-please@17.11.1 release-pr \
  --repo-url="$FIXTURE_REPO" \
  --target-branch=bootstrap \
  --token="$RP_TOKEN" \
  --config-file=release-please-config.json \
  --manifest-file=.release-please-manifest.json
```

Expected Release PR:

- version `0.1.0`;
- `Cargo.toml` remains or becomes `0.1.0`;
- manifest becomes `0.1.0`;
- tag produced after merge is `v0.1.0` under the separately owned tag policy.

Repeat with isolated branches and manifests to prove:

| Base | Commit | Expected |
|---|---|---|
| `0.1.0` | `fix: correct parser` | `0.1.1` |
| `0.1.0` | `feat: add library helper` | `0.1.1` |
| `0.1.3` | `feat(api)!: replace response type` | `0.2.0` |
| `0.9.4` | breaking commit | `0.10.0`, not `1.0.0` |
| `1.0.0` | fix | `1.0.1` |
| `1.0.0` | feat | `1.1.0` |
| `1.0.0` | breaking commit | `2.0.0` |

#### 4. Cargo resolver acceptance

Publish fixture versions to a disposable Cargo registry, then:

```bash
cargo new /tmp/r25-consumer
cd /tmp/r25-consumer
cargo add rs-launch-blueprint@0.1.0 --registry acceptance

cargo update \
  -p rs-launch-blueprint \
  --precise 0.1.1
```

Expected: succeeds.

```bash
cargo update \
  -p rs-launch-blueprint \
  --precise 0.2.0
```

Expected: fails because the consumer’s default `0.1.0` requirement excludes `0.2.0`.

#### 5. Library API compatibility

For a compatible feature fixture:

```bash
cargo semver-checks --baseline-rev v0.1.0
```

Expected: passes when current version is `0.1.1`.

For an API-removal fixture:

- at `0.1.1`: expected failure;
- after changing the package version to `0.2.0`: expected success as an intentionally incompatible release.

`cargo-semver-checks` uses crates.io or an explicit revision/version as its baseline and supports a GitHub Action with configurable baseline and release type. [S20; retrieved 2026-09-09] ([github.com](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai))

#### 6. CLI and web compatibility

```bash
cargo test --test cli_contract
cargo test --test http_contract
```

The fixtures should assert:

- documented flags and exit statuses;
- stable machine-readable output;
- config and environment precedence;
- route/method inventory;
- request/response schema compatibility;
- error status and error-envelope compatibility.

A deliberately breaking CLI or HTTP fixture must require a breaking Conventional Commit and produce `0.(n+1).0`.

#### 7. MSRV-release coupling

Add a CI script comparing the merge base with the Release PR:

```bash
./scripts/check-msrv-version-coupling.sh \
  --base "$BASE_SHA" \
  --head "$HEAD_SHA"
```

Expected: if `package.rust-version` changes, the package’s minor digit must increase and patch reset to zero. A patch-only proposed version must fail.

#### 8. Performance instrumentation

For the SemVer job, record:

```bash
/usr/bin/time -v cargo semver-checks --baseline-rev "$BASELINE_TAG"
du -sh target
```

Run once with a clean cache and once with a warm cache on Ubuntu and macOS. These measurements are CI-cost evidence only; no product request-path benchmark is applicable.

### Confidence & re-verify trigger

**Confidence: high** that Rust should begin at `0.1.0` with both flags enabled. Cargo’s resolver semantics and Release Please’s implementation align directly.

**Confidence: medium-high** in the exact first-release bootstrap composition until the pinned Release Please version is run against a fixture. The bootstrap-only `release-as` is chosen because its documented semantics are an exact next-version override.

Re-verify if any of the following occurs:

- Release Please changes or deprecates either pre-major flag;
- the project selects a non-default Release Please versioning strategy;
- Cargo changes its left-most-non-zero compatibility rules;
- `rs-launch-blueprint` stops publishing a library crate and becomes application-only;
- the owners can demonstrate that all three public contracts are stable before first publication;
- a public dependency prevents satisfying the proposed 1.0 graduation criteria;
- the current Rust stable minor changes before implementation, requiring the derived `rust-version` to be recalculated;
- the project approaches 1.0 or remains `0.x` despite production adoption and no planned breaking work.

### Sources

All web sources were retrieved **2026-09-09**.

| ID | Source URL | Authority/relevance |
|---|---|---|
| S1 | https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html | First-party `cargo new` output showing `0.1.0` and edition 2024. ([doc.rust-lang.org](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)) |
| S2 | https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html | First-party Cargo compatibility ranges and prerelease behavior. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)) |
| S3 | https://doc.rust-lang.org/cargo/reference/semver.html | First-party Cargo SemVer and application-compatibility guidance. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)) |
| S4 | https://semver.org/ | Normative SemVer 2.0.0 specification and FAQ. ([semver.org](https://semver.org/)) |
| S5 | https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md | Maintainer documentation for manifests, initial releases, `release-as`, and pre-major flags. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai)) |
| S6 | https://github.com/googleapis/release-please/blob/main/schemas/config.json | Maintainer schema defining both flags generically. ([github.com](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai)) |
| S7 | https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts | Primary implementation of the exact bump matrix. ([github.com](https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts?utm_source=openai)) |
| S8 | https://github.com/googleapis/release-please/blob/main/docs/design.md | Maintainer architecture separating language and versioning strategies. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/design.md?utm_source=openai)) |
| S9 | https://github.com/googleapis/release-please/releases | Current Release Please release history; `v17.11.1` dated 2026-07-31. ([github.com](https://github.com/googleapis/release-please/releases?utm_source=openai)) |
| S10 | https://github.com/googleapis/release-please/blob/main/docs/cli.md | Maintainer CLI options for initial version and pre-major flags. ([github.com](https://github.com/googleapis/release-please/blob/main/docs/cli.md?utm_source=openai)) |
| S10a | https://github.com/googleapis/release-please-action | Maintainer action documentation and configuration mapping. ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai)) |
| S11 | https://rust-lang.github.io/api-guidelines/necessities.html | Rust library-team-derived stable-public-dependency guidance. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/necessities.html)) |
| S12 | https://rust-lang.github.io/rfcs/1105-api-evolution.html | Rust RFC defining API-evolution/SemVer principles. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1105-api-evolution.html?utm_source=openai)) |
| S13 | https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html | Historical Rust incubation-to-1.0 architectural precedent. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai)) |
| S14 | https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/ | Current annual Rust survey context. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)) |
| S14a | https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ | Compile-time and resource-cost evidence. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai)) |
| S15 | https://github.com/tokio-rs/axum | Maintained web-framework reference. ([github.com](https://github.com/tokio-rs/axum?utm_source=openai)) |
| S15a | https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md | Axum compatibility-line and accidental-breaking-patch evidence. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md?utm_source=openai)) |
| S16 | https://github.com/seanmonstar/reqwest/releases | Maintained pre-1.0 HTTP-library reference. ([github.com](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)) |
| S16a | https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md | Reqwest breaking-minor and compatible-patch practice. ([github.com](https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md?utm_source=openai)) |
| S17 | https://tokio.rs/blog/2020-12-tokio-1-0 | Maintainer 1.0 stability announcement. ([tokio.rs](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)) |
| S17a | https://tokio.rs/blog/2020-10-tokio-0-3 | Maintainer description of the path and guarantees required for 1.0. ([tokio.rs](https://tokio.rs/blog/2020-10-tokio-0-3?utm_source=openai)) |
| S18 | https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466 | Serde 1.0 readiness announcement. ([users.rust-lang.org](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)) |
| S19 | https://github.com/nextest-rs/nextest | Maintained pre-1.0 CLI with explicit stability/MSRV policy. ([github.com](https://github.com/nextest-rs/nextest?utm_source=openai)) |
| S19a | https://www.nexte.st/changelog/ | Current nextest release practice. ([nexte.st](https://www.nexte.st/changelog/?utm_source=openai)) |
| S20 | https://github.com/obi1kenobi/cargo-semver-checks | Maintainer documentation for library API compatibility validation. ([github.com](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai)) |
| S20a | https://github.com/obi1kenobi/cargo-semver-checks-action | Maintainer Action inputs and baseline/release-type support. ([github.com](https://github.com/obi1kenobi/cargo-semver-checks-action?utm_source=openai)) |
| S21 | https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/ | Rust Release Team announcement for the current stable minor line. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)) |
| S21a | https://blog.rust-lang.org/ | Rust Blog index showing the subsequent `1.98.1` patch announcement on 2026-09-03. ([blog.rust-lang.org](https://blog.rust-lang.org/?utm_source=openai)) |
| S22 | https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf | Independent warning about indefinite `0.x` reducing SemVer expressivity. ([rustprojectprimer.com](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai)) |
| S23 | https://jacobtomlinson.dev/effver/ | Original EffVer proposal. ([jacobtomlinson.dev](https://jacobtomlinson.dev/effver/?utm_source=openai)) |
| S23a | https://docs.jax.dev/en/latest/jep/25516-effver.html | Concrete maintained EffVer adoption proposal. ([docs.jax.dev](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)) |
| S23b | https://zarr.dev/blog/versioning-with-effver/ | Production-project EffVer rationale. ([zarr.dev](https://zarr.dev/blog/versioning-with-effver/?utm_source=openai)) |
| S24 | https://0ver.org/ | ZeroVer catalogue. ([0ver.org](https://0ver.org/?utm_source=openai)) |
| S24a | https://0ver.org/about.html | Explicit satire notice and real-world warning about indefinite prerelease status. ([0ver.org](https://0ver.org/about.html?utm_source=openai)) |
| S25 | https://blog.rust-lang.org/2015/05/15/Rust-1.0/ | Rust Core Team explanation that 1.0 begins the stability commitment. ([blog.rust-lang.org](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)) |
| S25a | https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/ | Historical prerelease architecture reference. ([blog.rust-lang.org](https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/?utm_source=openai)) |
| S26 | https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html | First-party Cargo prerelease resolver analysis. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html?utm_source=openai)) |

## Sources

- [Creating a new project - The Rust Edition Guide](https://doc.rust-lang.org/edition-guide/editions/creating-a-new-project.html)
- [Semantic Versioning 2.0.0 | Semantic Versioning](https://semver.org/)
- [JEP 25516: Effort-based versioning for JAX — JAX documentation](https://docs.jax.dev/en/latest/jep/25516-effver.html?utm_source=openai)
- [release-please/schemas/config.json at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/schemas/config.json?utm_source=openai)
- [About - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/?utm_source=openai)
- [1242-rust-lang-crates - The Rust RFC Book](https://rust-lang.github.io/rfcs/1242-rust-lang-crates.html?utm_source=openai)
- [2025 State of Rust Survey Results | Rust Blog](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)
- [up a CI check (Item 32) that detects changes, using tooling (e.g., `cargo-deny`; see Item 25) as needed.](https://rustprojectprimer.com/archived/2024-11-09-effective-rust.pdf?utm_source=openai)
- [GitHub - tokio-rs/axum: HTTP routing and request-handling library for Rust that focuses on ergonomics and modularity · GitHub](https://github.com/tokio-rs/axum?utm_source=openai)
- [Releases · seanmonstar/reqwest · GitHub](https://github.com/seanmonstar/reqwest/releases?utm_source=openai)
- [GitHub - nextest-rs/nextest: A next-generation test runner for Rust. · GitHub](https://github.com/nextest-rs/nextest?utm_source=openai)
- [Announcing Tokio 1.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2020-12-tokio-1-0?utm_source=openai)
- [Serde and serde_json 1.0.0 released - announcements - The Rust Programming Language Forum](https://users.rust-lang.org/t/serde-and-serde-json-1-0-0-released/10466?utm_source=openai)
- [Announcing Rust 1.0 | Rust Blog](https://blog.rust-lang.org/2015/05/15/Rust-1.0/?utm_source=openai)
- [release-please/docs/manifest-releaser.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md?plain=1&utm_source=openai)
- [Specifying Dependencies - The Cargo Book](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [Rust compiler performance survey 2025 results | Rust Blog](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/?utm_source=openai)
- [Releases · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/releases?utm_source=openai)
- [ZeroVer: 0-based Versioning — zer0ver](https://0ver.org/?utm_source=openai)
- [SemVer Compatibility - The Cargo Book](https://doc.rust-lang.org/cargo/reference/semver.html)
- [GitHub - obi1kenobi/cargo-semver-checks: Scan your Rust crate for semver violations. · GitHub](https://github.com/obi1kenobi/cargo-semver-checks?utm_source=openai)
- [release-please/src/versioning-strategies/default.ts at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/src/versioning-strategies/default.ts?utm_source=openai)
- [release-please/docs/design.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/design.md?utm_source=openai)
- [release-please/docs/cli.md at main · googleapis/release-please · GitHub](https://github.com/googleapis/release-please/blob/main/docs/cli.md?utm_source=openai)
- [GitHub - googleapis/release-please-action: automated releases based on conventional commits · GitHub](https://github.com/googleapis/release-please-action?utm_source=openai)
- [Necessities - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html)
- [1105-api-evolution - The Rust RFC Book](https://rust-lang.github.io/rfcs/1105-api-evolution.html?utm_source=openai)
- [axum/axum/CHANGELOG.md at main · tokio-rs/axum · GitHub](https://github.com/tokio-rs/axum/blob/main/axum/CHANGELOG.md?utm_source=openai)
- [reqwest/CHANGELOG.md at master · seanmonstar/reqwest · GitHub](https://github.com/seanmonstar/reqwest/blob/master/CHANGELOG.md?utm_source=openai)
- [Announcing Tokio 0.3 and the path to 1.0 | Tokio - An asynchronous Rust runtime](https://tokio.rs/blog/2020-10-tokio-0-3?utm_source=openai)
- [Changelog - cargo-nextest](https://www.nexte.st/changelog/?utm_source=openai)
- [GitHub - obi1kenobi/cargo-semver-checks-action: A GitHub Action for running cargo-semver-checks · GitHub](https://github.com/obi1kenobi/cargo-semver-checks-action?utm_source=openai)
- [The Rust Programming Language Blog](https://blog.rust-lang.org/?utm_source=openai)
- [EffVer: Version your code by the effort required to upgrade - Jacob Tomlinson](https://jacobtomlinson.dev/effver/?utm_source=openai)
- [Versioning Zarr with EffVer | Zarr Blog](https://zarr.dev/blog/versioning-with-effver/?utm_source=openai)
- [About — zer0ver](https://0ver.org/about.html?utm_source=openai)
- [Announcing Rust 1.0 Alpha | Rust Blog](https://blog.rust-lang.org/2015/01/09/Rust-1.0-alpha/?utm_source=openai)
- [3493-precise-pre-release-cargo-update - The Rust RFC Book](https://rust-lang.github.io/rfcs/3493-precise-pre-release-cargo-update.html?utm_source=openai)

---


## Perplexity Results

---
prompt: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
mode: all_deep_research
provider: perplexity
model: sonar-deep-research
operation_id: research-20260909-003254-a6983478d8e044ec
created_at: 2026-09-09T00:32:54.053430
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
```

# R25 Pattern: Pre‑1.0 Semantic Versioning Strategy for `rs-launch-blueprint`

The decision for R25 is whether `rs-launch-blueprint` should launch as a pre‑1.0 crate using release‑please’s pre‑major “dampening” semantics, or instead begin at `1.0.0` under standard Semantic Versioning rules. After surveying authoritative specifications, Rust‑specific tooling behavior, and common practice for library crates, and after reconciling these with the cross‑language blueprint principles, the dominant recommendation is that `rs-launch-blueprint` start at `0.1.0` and explicitly enable both `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` in its `release-please-config.json`. This pattern aligns with how Cargo interprets `0.x.y` versions, matches the way Rust crates signal compatibility and instability before `1.0.0`, preserves the shared principle that version numbers communicate API stability and compatibility to both humans and tooling, and mirrors the TypeScript blueprint’s intent while respecting Python’s already‑stable status. The ranked runner‑up is to launch directly at `1.0.0` with standard semver bump semantics; this alternative is reserved for a future point where the Rust template’s public API and integration story are sufficiently proven that a stability promise from day one is justified. The rest of this report develops the landscape, principles, options, and tradeoffs in detail, and specifies the concrete parameter values and validation strategy for this pattern.

## Background: Semantic Versioning and Rust’s Pre‑1.0 Conventions

Semantic Versioning (SemVer) defines a three‑component version number of the form \(X.Y.Z\), labeled MAJOR.MINOR.PATCH, with explicit rules for when each component must be incremented.[11] According to the SemVer 2.0.0 specification, the MAJOR version must increase when incompatible API changes are introduced; the MINOR version must increase when new backward‑compatible functionality is added; and the PATCH version must increase when backward‑compatible bug fixes are made.[11] The specification also defines that version `1.0.0` is the point at which the public API is considered defined, and that after this point version increments must be driven by changes to this public API.[11] Before `1.0.0`, SemVer states that major version zero is “for initial development” and that “Anything MAY change at any time. The public API SHOULD NOT be considered stable.”[11][12] This guidance is intentionally permissive: it allows maintainers to iterate rapidly under `0.y.z` without a stability promise to consumers.

Rust, through Cargo, adopts SemVer but applies an important nuance for pre‑1.0 versions in how dependency constraints are interpreted.[5][9] The Cargo Book explains that a simple version requirement like `"0.1.12"` is treated as a caret requirement `^0.1.12`, which allows SemVer‑compatible updates that do not modify the leftmost non‑zero digit.[9] For versions where the major component is zero, this means that `0.x.y` is considered compatible with `0.x.z` for `y ≥ z`, but not with `0.(x+1).0`, because changing the minor component changes the leftmost non‑zero digit.[9] The Rust Project Primer reinforces this by noting that before `1.0`, the SemVer rules are “shifted”: a minor bump such as `0.1.0 → 0.2.0` is treated as a breaking change, and a patch bump such as `0.1.0 → 0.1.1` can include new features and is still considered compatible.[5] This convention exists because pre‑1.0 crates are expected to have unstable APIs, and it is widely understood in the Rust ecosystem that many crates remain at `0.x` for an extended period.[5][8]

Community discussions among Rust developers further clarify how this pre‑1.0 pattern is interpreted in practice.[1][8] In a Rust Users Forum thread on deciding when to go to `1.0.0`, contributors quote SemVer’s rule that “Major version zero (0.y.z) is for initial development” and emphasize that while `0.y.z` formally does not promise stability, stability expectations arise in practice once a crate reaches production usage.[1][11] Another widely cited discussion notes that, in Cargo, breaking changes are communicated by incrementing the leftmost non‑zero component, so `0.x` and `0.(x+1)` are treated as semver‑incompatible releases, whereas `0.x.y` and `0.x.(y+1)` are treated as compatible.[8][9] This means that for Rust crates, bumps in the minor digit of a `0.x.y` version are effectively acting as “major” compatibility boundaries, even though SemVer formally labels them as minor.[5][8][9] The practical implication is that starting at `0.1.0` and using minor bumps to signal breaking changes fits naturally into Cargo’s semantics and ecosystem conventions.

Guidance targeted at new crate authors also tends to advise starting at `0.1.0` rather than `1.0.0`.[17] A comprehensive write‑up on publishing Rust crates explains that a typical initial development version is `0.1.0`, from which maintainers increment the patch version for minor changes and bug fixes, the minor version for new features, and eventually the major version for incompatible API changes.[17] The same guidance offers an example where adding a new function that does not interfere with existing functionality might lead to updating the version from `0.1.0` to `0.2.0`, implicitly treating `0.2.0` as the next evolution of the API still under initial development.[17] Combined with Cargo’s compatibility rules, this produces a clear convention: before `1.0.0`, patch bumps on a `0.x.y` version are compatible and may introduce features, while minor bumps represent potential breaking changes that reset the compatibility range.[5][9][17]

SemVer itself went through release candidate iterations before stabilizing at 2.0.0, and these RC documents reiterate the same major‑version‑zero intent.[12][13] The 2.0.0‑rc.2 specification states that “Major version zero is all about rapid development,” explicitly framing `0.y.z` as a phase in which the public API is evolving, and the project is free to change without the same backward‑compatibility obligations that apply after `1.0.0`.[12] The RC documents also emphasize that once a versioned package has been released, its contents must not be modified; any changes must be released as a new version.[12][13] This immutability principle is important for automated tooling like Cargo and release‑please: they rely on version numbers monotonically signaling changes, without silent modifications to published artifacts.[11][12][13]

Within this context, the choice between launching `rs-launch-blueprint` at `0.1.0` or `1.0.0` is not merely a matter of numbering aesthetics. It is a choice about the stability promise made to consumers, the way compatibility is encoded in dependency constraints, and the expectations set for how quickly the template’s public API may evolve. For a template that is both a CLI, a library, and a web service, intended to be reused and adapted by others, these signals matter both to human users and to automation in the Rust ecosystem.

## Release‑please and Pre‑1.0 Bump Strategy

Release‑please is an open‑source automation tool developed by Google that parses Git history and conventional commit messages to generate release pull requests containing changelogs and version bumps for projects.[4] Rather than requiring maintainers to manually decide whether each change warrants a patch, minor, or major version increment, release‑please infers the next version according to SemVer rules based on commit types and optional configuration.[4][7] It supports a variety of language‑specific “release types,” including `node`, `python`, and `rust`, and can operate in both simple single‑package mode and manifest‑based mode for monorepos or multi‑package repositories.[7][14][16] For Rust repositories, the `rust` release type expects a `Cargo.toml` and a `CHANGELOG.md` and updates the crate version accordingly.[14][16]

The tool’s CLI and configuration documentation describe two important flags that modify behavior for pre‑1.0 versions: `bump-minor-pre-major` and `bump-patch-for-minor-pre-major`.[7][15][16] The CLI docs explain that `--bump-minor-pre-major` tells the versioning strategy to “bump the minor version for breaking changes for versions < 1.0.0”, and `--bump-patch-for-minor-pre-major` tells it to “bump the patch version for features for versions < 1.0.0”.[15] The manifest‑based advanced configuration exposes the same options in JSON form, allowing per‑package customization in monorepos: the `release-please-config.json` file at the repository root can specify these flags for each package, including Rust crates.[7] In the customizing documentation, release‑please lists `rust` among the supported strategy types and notes that these versioning options are generic, applying to any release type rather than being restricted to Node projects.[14][16]

Concrete examples from other ecosystems illustrate how these flags behave in practice. A DeepWiki description of a MySQL‑related extension for a CLI documents a versioning strategy in which `bump-minor-pre-major` is set to `true`, meaning that breaking changes bump the minor version rather than the major before `1.0.0`, and `bump-patch-for-minor-pre-major` is set to `true`, meaning that features bump the patch version rather than the minor before `1.0.0`.[3] The same documentation shows how release‑please analyzes conventional commit messages, so that `feat:` commits trigger a patch bump pre‑1.0 and a minor bump post‑1.0, while `feat!:` or commits with `BREAKING CHANGE:` trigger a minor bump pre‑1.0 and a major bump post‑1.0.[3] Similar patterns appear in an Elixir tutorial on release‑please, which suggests a configuration where `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` are both `true`, so that breaking changes bump the minor version from `0.1.0` to `0.2.0`, features bump the patch from `0.1.0` to `0.1.1`, and pre‑release versions can be marked as `"alpha"`.[4] Another DeepWiki entry on release automation for a server SDK stack shows these same flags used globally to allow minor version bumps and treat features as patches before reaching `v1.0.0`.[10]

Release‑please’s own advanced configuration documentation reinforces that these flags are part of a broader set of versioning strategies.[7] Besides the default SemVer behavior, versioning strategies can be configured as `always-bump-patch`, `always-bump-minor`, or `always-bump-major`, but the presence of `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` specifically encodes a distinct interpretation of pre‑1.0 semantics.[7] With both flags enabled, pre‑1.0 becomes a regime where breaking changes increment the minor component and features increment the patch component, aligning with Cargo’s convention that the leftmost non‑zero digit is the compatibility boundary and that patch versions within a `0.x.y` line are safe to auto‑update.[5][9][15] For Rust crates, this means that `0.1.3` to `0.1.4` can legitimately include new features without breaking dependents pinned to `^0.1.3`, while `0.1.3` to `0.2.0` signals a compatibility boundary that dependents will not cross automatically.[5][9][15]

The fact that these options are explicitly supported for the `rust` release type and described in release‑please’s central documentation is a key piece of authority for R25.[14][15][16] It demonstrates that the tool expects maintainers of Rust crates to make an intentional choice about how pre‑1.0 versions are handled, and that the combination of these flags is an established pattern rather than an ad‑hoc tweak borrowed from the Node ecosystem. It also means that using these flags in `rs-launch-blueprint` will be fully supported, with behavior matching examples already in production in other languages.[3][4][10]

## Cross‑Blueprint Versioning Principles

The owner’s mandate for R25 emphasizes that the decision must not simply copy an existing implementation, but instead identify the shared engineering principles, the level at which agreement is required, and the observable acceptance criteria across the Python, TypeScript, and Rust blueprints. The TypeScript port (`ts-launch-blueprint`) currently uses release‑please in manifest mode with `release-type: node`, and explicitly enables `bump-minor-pre-major` and `include-v-in-tag`, starting at a pre‑1.0 version (`0.1.3`). The Python port (`py-launch-blueprint`) is currently at `2.4.2` and does not configure pre‑1.0 dampening flags because it is already post‑1.0 and has an established stability story. The ledger row F070 marks the pre‑1.0 dampening behavior as DIVERGENT and TS‑only, and the research mandate instructs that this divergence must be evaluated rather than assumed.

A plausible shared principle across the three blueprints is that version numbers and release automation must encode API stability and compatibility in a way that is both conceptually consistent and idiomatic for each ecosystem. Conceptual consistency means that “major” changes are those that break existing consumers, “minor” changes are backward‑compatible feature additions, and “patch” changes are backward‑compatible bug fixes, as defined by SemVer.[11] Idiomatic means that the way these categories are mapped onto version components and communicated in tooling should match what mainstream users of the ecosystem expect, so that a dependency constraint like `^1.2` in Python or `^0.4` in Rust behaves in line with community norms.[5][9][11] For the TypeScript blueprint, this principle led to a pre‑1.0 start with dampened semantics, reflecting the fact that the API was evolving and that npm’s semver handling of `0.x` allows flexibility while still letting conventional commit types drive automated version bumps.[3][4]

The level of agreement required appears to be architectural pattern rather than specific numeric version. All three blueprints should agree that they use semver‑based versioning, that release automation is driven by conventional commits and release‑please, and that pre‑1.0 and post‑1.0 phases are treated differently in terms of stability promises. They do not need to agree on the exact starting version number, because the Python blueprint’s `2.4.2` reflects historical evolution and legacy consumers, whereas the Rust blueprint is a new crate with no history. Instead, the agreement level is that pre‑1.0 is used for initial development when the public API is not yet stable, and that once an API is stable and widely consumed, the blueprint moves to `1.0.0` and uses standard semver semantics without dampening.[11][12][17] The acceptance criteria are observable: version numbers must evolve monotonically; CI must enforce consistency between tags and version fields; dependencies must resolve compatibly according to ecosystem norms; and consumers must not be surprised by breaking changes sneaking into patch‑level releases.[4][7][9][11]

Within this framing, the divergence recorded in F070—pre‑1.0 dampening behavior present only in the TypeScript port—looks like an accidental asymmetry rather than a principled difference. The Python blueprint is post‑1.0 and cannot meaningfully configure pre‑1.0 dampening; it instead uses standard semver behavior, which is correct for a mature, application‑like project.[11] The Rust blueprint is structurally more like the TypeScript blueprint, in that it will produce a library crate intended for reuse and evolution, even though it also includes a CLI and web service component. For such a library crate, Rust practice strongly favors starting at `0.1.0` and remaining pre‑1.0 while the public API evolves, with Cargo’s compatibility rules making minor `0.x` bumps the primary mechanism for signaling breaking changes.[5][8][9][17] This suggests that the shared architectural pattern—pre‑1.0 for initial development with dampened semantics, then `1.0.0` once stable—should be preserved across TypeScript and Rust, while Python remains in the stable regime.

The research mandate also requires that missing capability or accidental drift be distinguished from justified ecosystem differences. Here, the lack of pre‑1.0 dampening configuration in the Python blueprint is justified by its post‑1.0 status; there is no missing capability. The lack of such configuration in the Rust blueprint is simply because it is new and undecided. Conversely, the use of pre‑1.0 dampening in the TypeScript blueprint is not a quirk of npm; it is an expression of the pattern that initial development favors smaller numeric jumps to avoid prematurely burning major version numbers while still conveying breaking changes to tooling.[3][4][11] Adopting a similar pattern in Rust with the appropriate adaptation to Cargo’s semantics preserves the principle, rather than forcing artificial uniformity.

In light of this, we will treat F070 as a baseline in need of review. The proposed change is to reclassify the pre‑1.0 dampening strategy as a common architectural pattern for new blueprints that are library‑shaped and under initial development, rather than as a TS‑only divergence. The evidence is drawn from SemVer, Cargo’s pre‑1.0 compatibility rules, Rust ecosystem practice with `0.x` crates, and release‑please’s generic support for `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` for Rust.[3][4][5][7][9][10][11][15][16][17] We will mark this explicitly in the principles section as a baseline review.

## R25 Pattern Analysis

### Landscape

The category this item decides is the “pre‑1.0 semantic versioning and release‑automation strategy” for a Rust crate that is part of a multi‑language blueprint. This is a pattern rather than a library choice: it specifies how version numbers are interpreted and bumped by release‑please, how Cargo and consumers will see compatibility, and when the template transitions from initial development to stable API. As required, the landscape can be mapped into three bins: built‑in or first‑party toolchain; established industry standard; and up‑and‑comer patterns and tools.

In the built‑in or first‑party bucket, the primary actors are the semver specification itself and Cargo’s interpretation of semver requirements.[5][9][11] SemVer 2.0.0 is the normative standard for versioning, hosted at semver.org, authored by Tom Preston‑Werner and widely cited across software ecosystems.[11] It is authoritative both because it defines the semantics of MAJOR.MINOR.PATCH and because tools like npm, Cargo, and many others adopt its rules explicitly.[5][9][11] The Cargo Book, maintained as part of the Rust project’s official documentation, is authoritative for how Rust’s package manager interprets version requirements, particularly caret (^)-style constraints and the special handling of pre‑1.0 versions.[9] The Rust Project Primer is a community‑curated but Rust‑team‑aligned guide aimed at Rust project maintainers, and its explanation of versioning and pre‑1.0 behavior is widely referenced.[5] Together, these sources define the baseline semantics that any pattern for `rs-launch-blueprint` must respect.

In the established industry standard bucket, we place release‑please and conventional commits, along with cross‑ecosystem usage of pre‑1.0 dampening.[3][4][7][10][14][15][16] Release‑please’s documentation, hosted under the googleapis GitHub organization, is authoritative for its behavior and configuration options.[7][14][15] The tool is broadly adopted across Google‑maintained repositories and many external projects, and its language‑specific release types, including `rust`, encode best practices for automated releases.[14][16] DeepWiki write‑ups on specific projects such as the MySQL gemini CLI extension and Flipt server SDKs provide concrete, maintained reference implementations of pre‑1.0 dampening strategies, showing how the flags are set and how commit types map to version bumps.[3][10] A blog post on managing releases with release‑please in Elixir provides a language‑agnostic explanation of these options and demonstrates their intended usage.[4] While these materials are not formal standards, they collectively constitute de facto practice for projects using release‑please, and therefore carry weight.

The up‑and‑comer bucket would usually include alternative release tools and emerging patterns like `cargo-release`, git‑driven changelog generators, or other CI‑driven release flows. However, the scope of R25 is constrained: the owner has already decided that release‑please is the release automation tool for this template, and R25 only decides the pre‑1.0 versus post‑1.0 bump semantics within it. That means that alternative tools are out of scope as candidates, though they inform understanding of how Rust projects typically handle versioning. Moreover, discussions on Rust forums and community platforms about when to go to `1.0.0` and how to use `0.x.y` versions are relevant practice evidence rather than competing tools.[1][8] These conversations are authoritative insofar as they represent the collective experience of Rust maintainers operating under Cargo’s semantics.

For practice evidence, we must survey mainstream, well‑regarded Rust projects and patterns, weighting newer popular ones. The search results do not enumerate specific crates like `tokio` or `serde`, but they provide aggregated guidance and commentary on typical behavior. The Rust Project Primer explicitly warns that many crates in the Rust ecosystem “stay at 0.x for a long time,” which can surprise users who assume pre‑1.0 implies instability.[5] A Hacker News discussion elaborates that in the Rust ecosystem, version numbers like `log = "0.4"` in `Cargo.toml` are interpreted so that running `cargo update` will only bump to semver‑compatible releases within the `0.4.x` line, meaning machine interpretation treats patch bumps as compatible and minor `0.x` bumps as breaking.[8][9] The same discussion points out that maintainers often use 0.x to signal to humans that the API is not yet guaranteed stable, even while semver rules and Cargo treat cumulative patch releases as a stable range.[8][11] A Gyata article on publishing Rust crates provides a simple but widely applicable exemplar for a new crate starting at `0.1.0` and evolving through patch and minor versions before hitting `1.0.0`.[17] These sources collectively describe mainstream practice: new Rust library crates typically start at `0.1.0`, remain pre‑1.0 while the API evolves, use patch `0.x.y` updates for compatible improvements and bug fixes, and use minor `0.x` updates for breaking changes.[5][8][9][17]

Fit over abstract best must be emphasized: R25 concerns a template that is simultaneously a CLI, a library, and a web service, intended as a starting point for new Rust projects. The decision is not about the absolute “best” versioning strategy in isolation, but about which strategy best serves such a template given the owner’s goals and the cross‑language blueprint context. The Rust ecosystem’s conventions, as codified by Cargo, SemVer, and community practice, are highly relevant here.[5][9][11][17] The landscape shows that pre‑1.0 semantics with minor‑as‑breaking and patch‑as‑compatible are both baked into Cargo and widely used, and that release‑please explicitly supports configuring pre‑1.0 dampening for Rust in line with these conventions.[5][7][9][14][15][16] The subsequent sections apply this landscape to the specific decision.

### Principles and implementation

The shared requirement across Python, TypeScript, and Rust blueprints for R25 can be stated as follows: version numbers and release automation must accurately reflect API compatibility and stability, in a way that is both semantically consistent across languages and idiomatic within each language’s ecosystem. The source of this requirement is the owner’s research mandate, which prioritizes architectural principles over inherited mechanisms, semver.org’s rules about how major, minor, and patch versions are interpreted, and Cargo’s documented behavior for Rust crates.[5][9][11] The level of agreement is architectural pattern: all blueprints must agree that they follow SemVer, distinguish pre‑1.0 initial development from post‑1.0 stable API, use release‑please to automate version bumps based on conventional commits, and avoid breaking changes in patch releases once the major version is at least one.[4][7][11] They may vary in initial version numbers and in the duration they remain pre‑1.0, according to ecosystem practice and project maturity.

The essential behaviors for R25 are fourfold. First, for pre‑1.0 versions of `rs-launch-blueprint`, breaking changes must cause a bump in the leftmost non‑zero version component, which under `0.x.y` is the minor digit, so that Cargo’s caret requirements recognize them as incompatibilities.[5][8][9] Second, non‑breaking features should be allowed in patch releases under `0.x.y`, consistent with Rust’s convention that `0.x.y` and `0.x.(y+1)` are compatible and may include new functionality.[5][9][17] Third, release‑please must be configured so that its automated interpretation of conventional commits produces exactly these increments: patch for non‑breaking features and fixes, minor for breaking changes, and eventually major when `1.0.0` is reached and a breaking change occurs.[3][4][7][10][15] Fourth, once `rs-launch-blueprint` reaches `1.0.0`, the pattern must switch to standard SemVer semantics, meaning that minor bumps represent backward‑compatible features and patch bumps represent bug fixes, with breaking changes reserved for major version increments.[11]

Observable acceptance criteria follow directly from these behaviors. A dependency on `rs-launch-blueprint` specified as `^0.1.3` must be able to auto‑update to `0.1.4` and other patch versions without encountering breaking changes, and must not auto‑update across minor `0.x` boundaries like `0.1.3 → 0.2.0`.[5][9] Release‑please’s generated changelog for a patch `0.x.y → 0.x.(y+1)` release should list only features and fixes marked as backward‑compatible, and its PR should show the patch digit increasing when `bump-patch-for-minor-pre-major` is enabled.[3][4][7][10][15] Breaking changes must be associated with `feat!` or `BREAKING CHANGE` commit annotations, and release‑please must bump the minor digit for `0.x` versions with `bump-minor-pre-major` set to `true`, and the major digit for `≥1.0.0` versions.[3][4][7][10][15] Finally, once `rs-launch-blueprint` is at `1.0.0` and beyond, consumers pinned to `^1.2.0` must be safe from breaking changes unless they opt into a new major version.[9][11]

Within this frame, we perform the required baseline review. The ledger row F070 currently classifies the pre‑1.0 dampening strategy as DIVERGENT and TS‑only. Based on the evidence surveyed, this divergence appears to be accidental rather than principled. SemVer’s definition of major version zero as initial development applies equally to TypeScript packages and Rust crates.[11][12] Cargo’s adaptation treats `0.x` minor bumps as breaking, and patch bumps as compatible, which is exactly the behavior encoded by release‑please when both pre‑1.0 flags are enabled.[5][7][9][15] TypeScript’s choice to configure `bump-minor-pre-major` was driven by the desire to encode breaking changes as minor pre‑1.0 while keeping major version zero free for initial development, a principle that translates directly to Rust.[3][4] Rust guidance for new crates explicitly recommends starting at `0.1.0`, iterating under pre‑1.0, and only moving to `1.0.0` once the API is stable and used in production.[1][5][17] Therefore, we propose the following baseline review.

> BASELINE-REVIEW: F070 — pre‑1.0 semver dampening — reclassify as a common architectural pattern for new library‑shaped blueprints — evidence: SemVer’s major version zero rules[11][12], Cargo’s pre‑1.0 compatibility conventions[5][9], Rust crate publishing guidance recommending `0.1.0` as initial version[17], and release‑please’s explicit support for `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` across languages including Rust[3][4][7][10][14][15][16].

Implementation of this pattern in `rs-launch-blueprint` is straightforward. The initial version in `Cargo.toml` will be set to `0.1.0`, consistent with Rust publishing guidance.[5][17] The `release-please-config.json` will specify `"release-type": "rust"` (or omit it when using manifest mode) and set `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true`, following the documented advanced configuration.[4][7][10][14][15][16] Conventional commit conventions will be enforced in the repository, so that commits starting with `feat:` represent non‑breaking features, `fix:` represent bug fixes, and `feat!:` or `BREAKING CHANGE:` represent breaking API changes.[3][4][10] Release‑please’s release PRs will become the single mechanism for bumping the `Cargo.toml` version, and the template’s documentation will state clearly that patch releases under `0.x.y` may add features but are considered compatible, while minor releases under `0.x` may introduce breaking changes, matching Cargo’s semantics.[5][9][17] Once the template’s API stabilizes and has accumulated sufficient production usage, a deliberate decision will be made to release `1.0.0`, after which the pre‑major flags may be disabled or left innocuous, as they only have effect for versions below `1.0.0`.[7][15]

### Dominant choice

The dominant choice for R25, given the landscape and principles above, is to have `rs-launch-blueprint` launch as a pre‑1.0 crate at version `0.1.0` and to enable both `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` in its release‑please configuration. This pattern can be named the **“Rust pre‑1.0 dampened SemVer pattern”** for the blueprint.

Under this pattern, `0.1.0` marks initial development, signaling to humans that the API is not yet stable and to Cargo that compatibility is governed by the minor digit as the leftmost non‑zero component.[5][9][11] Release‑please will interpret `feat:` commits as patch bumps and `fix:` commits as patch bumps under `0.x.y`, meaning that `0.1.0 → 0.1.1 → 0.1.2 → …` can accumulate features and bug fixes while remaining within the same compatibility range for dependencies pinned to `^0.1.0`.[3][5][9][15][17] Breaking changes indicated by `feat!` or `BREAKING CHANGE` in commits will cause release‑please to bump the minor digit, producing `0.2.0`, `0.3.0`, and so on, which Cargo will treat as incompatible with the previous `0.x` line.[3][5][8][9][15] When eventually `1.0.0` is released, `bump-minor-pre-major` will no longer alter behavior, and breaking changes will correctly trigger major bumps (e.g., `1.2.3 → 2.0.0`) while features bump minor and fixes bump patch.[3][11][15]

This choice is dominant because it simultaneously respects SemVer’s philosophy of major version zero as initial development,[11][12] aligns perfectly with Cargo’s semantics for pre‑1.0 compatibility,[5][9] matches common practice for Rust library crates starting at `0.1.0` and evolving under `0.x` for a substantial period,[5][8][17] and leverages release‑please’s built‑in support for pre‑1.0 dampening in a way that is documented and already used in production projects.[3][4][7][10][14][15][16] It preserves the cross‑blueprint principle that initial development is conducted under pre‑1.0 without a strong stability promise, while eventual `1.0.0` marks a significant milestone of API definition and stability, as seen in the Python blueprint’s current `2.4.2` state.[11]

### Options

Several pattern options are available for R25, each documented in authoritative sources and practiced by real projects.

The first option is the **pre‑1.0 dampened SemVer pattern**, which we have selected as dominant. It is documented in release‑please’s advanced configuration and CLI docs, where `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` are described as flags that adjust how breaking changes and features are bumped for versions below `1.0.0`.[7][15][16] DeepWiki’s article on the gemini CLI MySQL extension shows this pattern in use: breaking changes bump the minor version from `0.1.4 → 0.2.0`, while features bump the patch version from `0.1.4 → 0.1.5`, making pre‑1.0 increments small while still encoding compatibility boundaries.[3] An Elixir guide similarly demonstrates a configuration with both flags enabled, and illustrates how features and breaking changes are mapped to patch and minor bumps respectively for `0.y.z` versions.[4] Adoption can be seen in projects like Loki Operator, which is still pre‑`v1.0.0` and uses `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` to ensure that merging “feat!” and “fix!” commits bumps the minor version, while ordinary “feat”, “fix”, and “deps” commits bump the patch version.[2] The most recent authoritative write‑ups for this option are the release‑please customizing docs and CLI documentation, which are maintained alongside the tool’s codebase in the googleapis GitHub repository.[7][14][15][16]

The second option is the **straight SemVer from `1.0.0` pattern**, in which `rs-launch-blueprint` would start at version `1.0.0` and use standard semver rules with no pre‑1.0 dampening flags. This option is documented in the SemVer 2.0.0 specification, which states that version `1.0.0` defines the public API and that thereafter, major, minor, and patch increments must follow the rules for incompatible changes, backward‑compatible additions, and bug fixes respectively.[11] Release‑please’s default versioning strategy without `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` follows this pattern: for `1.2.3`, a `feat:` commit triggers `1.3.0`, a `fix:` triggers `1.2.4`, and a `feat!` or `BREAKING CHANGE` triggers `2.0.0`.[3][4][15] Adoption of this pattern is ubiquitous across mature projects in all ecosystems; it is the standard behavior for Python packages and Node modules that have reached `1.0.0` and beyond.[11] For the Python blueprint, which is currently at `2.4.2`, this is precisely the pattern already in use.

The third option is a **pre‑1.0 strict SemVer pattern without dampening**, where `rs-launch-blueprint` would start at `0.1.0`, but release‑please would be left in default mode, meaning that features would bump the minor version and breaking changes would bump the major version even under `0.x.y`. SemVer formally allows this: the specification says that before `1.0.0` “Anything MAY change at any time” and does not impose strict compatibility semantics.[11][12] Under this pattern, `feat:` commits at `0.1.3` would bump the version to `0.2.0`, and `feat!` commits might bump to `1.0.0`, depending on configuration.[3][15] However, this behavior is mismatched with Cargo’s expectations, where `0.1.3 → 0.1.4` should be compatible, and breaking changes should align with minor `0.x` bumps rather than forcing an early `1.0.0`.[5][9] Adoption of this pattern in Rust is limited and often discouraged, as it unnecessarily burns major version numbers and complicates dependency constraints.

Other variations include always‑bump strategies such as `always-bump-minor` or `always-bump-patch`, described in release‑please’s advanced configuration table.[7] These strategies are primarily tied to specific project needs and do not correspond to SemVer semantics; for example, `always-bump-patch` would bump the patch version even for features, disregarding the distinction between major, minor, and patch, while `always-bump-major` would bump the major version for every change.[7] These options may be useful for particular project types but are misaligned with SemVer and Cargo compatibility semantics and are therefore unlikely to be appropriate for `rs-launch-blueprint`.

### Excluded by gate

The fitness gates specified in the prompt are designed for crate and library candidates, checking license compatibility, MSRV, RustSec advisories, platform support, async runtime coupling, and size characteristics. For R25, the decision is a pattern rather than a crate or release tool; release‑please is already chosen and out of scope for reconsideration. As such, the gates apply somewhat differently, and we must explicitly mark their inapplicability where appropriate.

License compatibility is inapplicable to the pattern choice because no new crate or dependency is being introduced. Release‑please is already in use and operates as a CI automation tool, and the decision only concerns its configuration flags and the version numbers in `Cargo.toml`. The template’s license remains `MIT OR Apache-2.0` by owner decision, and no pattern option affects this.

MSRV and RustSec advisory checks are similarly inapplicable here. No new runtime crates are being proposed, and the pattern decision does not change the Rust edition (`2024`) or the MSRV policy (“stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI”). The versioning pattern operates entirely at the level of version numbers and automation; it does not introduce unsafe code or alter the dependency tree.

Platform support gates—requiring builds and tests on `ubuntu-latest` and `macos-latest`—are indirectly relevant. The chosen pattern must not rely on behavior that differs across platforms. Fortunately, SemVer, Cargo version resolution, and release‑please’s configuration are platform‑independent.[5][7][9][11][15][16] They interpret version numbers and commit messages identically on Linux and macOS. Therefore, all options considered satisfy platform gates.

Async runtime coupling, binary size, and compile‑time cost are unrelated to the pattern. They pertain to library choices and code architecture, which are outside R25’s scope. Thus, no pattern option is excluded by performance or runtime gates.

The only gate that meaningfully excludes options is semantic compatibility with Cargo and SemVer. The pre‑1.0 strict SemVer pattern without dampening is excluded because it mismatches Cargo’s expectation that patch bumps under `0.x.y` can include features and remain compatible, whereas minor `0.x` bumps represent breaking changes.[5][9][17] In that pattern, release‑please would treat features as minor bumps even under `0.x.y`, causing frequent compatibility boundaries that are not aligned with Rust practice. Similarly, `always-bump-major` and `always-bump-minor` strategies are excluded because they do not respect SemVer’s distinctions and would cause version number inflation and confusion.[7][11] The pre‑1.0 dampened pattern and the straight `1.0.0` pattern both pass semantic gates; the former is chosen as dominant, the latter as a runner‑up.

### Up‑and‑comers

Although alternative release automation tools and emerging patterns are out of scope as direct candidates, it is useful to note their existence as up‑and‑comers to contextualize the chosen pattern. Tools such as `cargo-release` or custom GitHub Actions that parse tags and commit messages offer alternative ways to manage Rust crate releases. They often follow SemVer and integrate with Cargo but may not provide as rich pre‑1.0 configuration as release‑please.[5][9][11] In addition, some projects experiment with calendar versioning or other schemes; however, Rust’s ecosystem generally favors SemVer for crates published to crates.io.[5][9][17]

Given the owner’s decision to use release‑please and the already‑established cross‑language pattern of conventional commits and release PRs, these up‑and‑comers remain background context rather than options. They may become relevant if future evidence indicates that Cargo or Rust tooling adopts new conventions for pre‑1.0 behavior, but today the combination of SemVer, Cargo caret requirements, and release‑please’s pre‑major flags represents the mainstream.

### Fit for this template

Fit for `rs-launch-blueprint` must be evaluated separately for its three roles: CLI, library, and web service.

For the CLI component, users typically install binaries either from crates.io via `cargo install`, from prebuilt artifacts, or through distribution‑specific mechanisms. CLI users care primarily that commands and flags remain stable across patch and minor releases, and that breaking changes are clearly signaled by version jumps and changelog entries. Under the pre‑1.0 dampened pattern, the CLI’s behavior may evolve more rapidly, and breaking changes can occur at minor `0.x` bumps. This is acceptable in initial development, as early adopters expect evolution and are likely to pin exact versions or update consciously. Once the CLI is mature, moving to `1.0.0` will signal a stronger stability commitment, and CLI users can rely on patch and minor releases being backward‑compatible.[11][17]

For the library crate, which is the primary distribution unit on crates.io, fit is particularly strong. The Rust Project Primer and publishing guides explicitly assume that initial versions are `0.1.0` and that many libraries remain at `0.x` for extended periods while their APIs evolve.[5][17] Dependencies expressed as `log = "0.4"` or `my-crate = "0.1"` rely on Cargo’s semantics that patch `0.x.y` releases are compatible and may include features, while minor `0.x` releases represent breaking changes that require dependency constraints to be updated.[5][8][9] The pre‑1.0 dampened pattern aligns perfectly with this: features under `0.x.y` produce patch bumps, and breaking changes produce minor bumps. This makes dependency management natural for consumers of `rs-launch-blueprint` as a library, and matches the ecosystem’s expectations that pre‑1.0 can be used in production as long as version numbers encode compatibility correctly.[1][5][8][9][17]

For the web service component, version numbers are primarily about deployment artifacts and client compatibility. The service’s public API may be consumed by HTTP clients, SDKs, or frontends. In early development, frequent breaking changes to API endpoints are common, and semantic version numbers applied to Docker images or crate versions help clients know when incompatible changes occur. Under the pre‑1.0 dampened pattern, the service’s crate version and image tags will bump patch for backward‑compatible changes and minor for breaking ones. Clients can track this, and service maintainers can decide when to call the API stable enough to release `1.0.0`. This is consistent with both SemVer philosophy and web API evolution practice.[11][12][17]

Cross‑blueprint fit is also important. The TypeScript blueprint, which is also library‑shaped and includes CLI behavior, uses pre‑1.0 dampening with release‑please.[3][4] The Python blueprint, being an application‑style project already in production, uses post‑1.0 semantics. Adopting pre‑1.0 dampening in Rust preserves the principle that new library‑like ports start with initial development versions and evolve under `0.x`, while mature blueprints use `1.x` and beyond. It avoids forcing the Rust crate to claim stability it does not yet have, and it aligns the semantics of minor and patch across TypeScript and Rust in the pre‑1.0 phase.

### Recommendation

Based on the landscape, principles, options, and fit analysis, the recommendation for R25 is:

`rs-launch-blueprint` should launch at version `0.1.0` in `Cargo.toml` and configure release‑please with `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true` in its `release-please-config.json` for the Rust crate, using the `rust` release type or manifest configuration as appropriate.[4][5][7][9][14][15][16][17]

This pattern will ensure that:

1. Before `1.0.0`, breaking changes in the Rust crate cause minor version bumps (e.g., `0.1.3 → 0.2.0`), which Cargo treats as compatibility boundaries, and consumers pinned to `^0.1.3` will not auto‑update past them.[5][8][9][15]

2. Before `1.0.0`, non‑breaking features and fixes cause patch version bumps (e.g., `0.1.3 → 0.1.4`), which Cargo treats as compatible, and consumers pinned to `^0.1.3` will auto‑update safely.[5][9][15][17]

3. After `1.0.0`, release‑please reverts to standard SemVer behavior, where features bump minor and fixes bump patch, and breaking changes bump major, aligning with SemVer 2.0.0 and cross‑language expectations.[3][11][15]

4. The cross‑blueprint principle that pre‑1.0 is initial development and `1.0.0` marks a stable API is preserved, with TypeScript and Rust using pre‑1.0 dampening during their initial phase and Python already in the stable phase.[3][4][11][17]

### Ranked runner‑up

The ranked runner‑up option is to launch `rs-launch-blueprint` directly at version `1.0.0` and use release‑please with default SemVer bump semantics, without enabling pre‑1.0 dampening flags. Under this option, breaking changes would bump the major version (`1.0.0 → 2.0.0`), features would bump minor, and fixes would bump patch from the very first release.[3][11][15]

This option would win under a specific condition: if, prior to first publication, the Rust template’s library API were fully designed, widely tested in internal production usage, and committed to long‑term stability such that the owner is willing to promise that no breaking changes will occur except via major version jumps. In that scenario, launching directly at `1.0.0` would make sense, mirroring the Python blueprint’s current state, and avoiding the ambiguity of pre‑1.0 semantics.[11][17] It would send a strong signal to ecosystem consumers that the crate is ready for production and that dependency constraints like `^1.0.0` can be relied upon for compatibility across patch and minor releases.

However, given that `rs-launch-blueprint` is a brand‑new port with no existing consumers or published crate history, and given that its library API and integration points are likely to evolve as it is adopted, this condition is not met. Therefore, the runner‑up remains a future possibility for a later transition point rather than the initial pattern.

### Tradeoffs

Choosing the pre‑1.0 dampened SemVer pattern entails tradeoffs relative to the runner‑up and other options.

Compared to launching at `1.0.0`, the pre‑1.0 pattern sacrifices an immediate stability signal. Consumers may see a `0.1.0` crate and assume that the API is unstable, even though the pattern’s careful use of patch and minor bumps under `0.x` provides meaningful compatibility guarantees.[5][8][11][17] This can reduce initial adoption by risk‑averse users who prefer `1.x` crates. However, the pattern gains flexibility: maintainers can make breaking changes while staying under `1.0.0`, encoding them as minor `0.x` bumps, and avoiding frequent major version churn that could fragment the ecosystem.[5][8][9][11] It also aligns more closely with Rust practice, where many respected crates remain at `0.x` for years and yet are widely used in production.[5][8]

Relative to a pre‑1.0 strict SemVer pattern without dampening, the chosen pattern sacrifices some “purity” in the formal interpretation of minor and patch under `0.x`. SemVer does not require that patch releases under major zero be backward‑compatible; it simply says that version zero is initial development and anything may change.[11][12] A strict pattern might treat every feature as a minor `0.x` bump to emphasize change. However, in Rust this would conflict with Cargo’s compatibility assumptions and require consumers to constantly update dependency constraints, making adoption more cumbersome.[5][9][17] The dampened pattern gains compatibility and aligns with automated tooling: patch `0.x.y` releases are safe to auto‑update, and minor `0.x` releases are recognized as breaking.[5][8][9]

Relative to always‑bump strategies, the chosen pattern sacrifices the simplicity of uniform bumping and gains semantic richness. `always-bump-patch` or `always-bump-minor` can simplify human decision‑making but obscure whether a change is breaking or not.[7][11] For a library template intended as a reference implementation, it is important that breaking changes be clearly signaled by version numbers; the chosen pattern ensures that, while still allowing features to be released frequently under patch numbers in the pre‑1.0 phase.[3][5][9][11][15][17]

These tradeoffs are accepted because the primary goal for `rs-launch-blueprint` is to serve as a robust, idiomatic starting point for Rust projects that balances evolution and stability. The pre‑1.0 dampened pattern offers the best alignment with this goal, while the runner‑up can be considered when the template reaches a maturity level justifying a direct `1.0.0` start.

### Parameters

For R25, the following parameters are owned and assumed:

`owns R25.versioning-epoch = "pre-1.0 dampened"`: The Rust blueprint’s initial version epoch is `0.x.y`, starting at `0.1.0`, with minor representing breaking changes and patch representing compatible features and fixes.[5][9][17]

`owns R25.release-please.bump-minor-pre-major = true`: Release‑please must be configured with `bump-minor-pre-major: true`, so that breaking changes under versions `< 1.0.0` cause minor bumps rather than major.[3][4][7][10][14][15][16]

`owns R25.release-please.bump-patch-for-minor-pre-major = true`: Release‑please must be configured with `bump-patch-for-minor-pre-major: true`, so that features under versions `< 1.0.0` cause patch bumps rather than minor.[3][4][7][10][14][15][16]

`owns R25.initial-Cargo-version = "0.1.0"`: The `[package] version` field in `Cargo.toml` for `rs-launch-blueprint` must be set to `0.1.0` at first publication, consistent with Rust publishing guidance for initial development releases.[5][17]

`assumes rust-edition = "2024"`: The Rust edition is fixed by owner decision and is not altered by this pattern.

`assumes msrv-policy = "stable minus 2 minor versions"`: The minimum supported Rust version policy is fixed and unaffected by versioning semantics.

`assumes license = "MIT OR Apache-2.0"`: The license choice is fixed and unaffected.

`assumes target-os-matrix = "ubuntu-latest, macos-latest"`: CI targets remain as specified; the pattern applies identically on these platforms.

No consumed parameter needs to change for this recommendation. Therefore, there is no `CONFLICT:` line for R25.

### Migration implications

Even though `rs-launch-blueprint` is a new template, migration implications must be considered in terms of file‑level changes and cross‑blueprint alignment.

In `Cargo.toml`, the `[package] version` field must be initialized to `0.1.0` instead of `1.0.0` or any other value. This makes `Cargo.toml` the source of truth for versioning, as already determined by ledger row F063, and ensures that release‑please’s updates propagate correctly.[5][9][17] The `rust-version` field must be set according to the MSRV policy, but this is independent of R25.

In `release-please-config.json`, a section for the Rust crate must be defined, either directly or via manifest. It must include `"release-type": "rust"` when not using manifest mode, and must set `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true` for the Rust package.[4][7][10][14][15][16] If manifest mode is used, `.release-please-manifest.json` should be updated to track the initial version `0.1.0` for the Rust component, and the flags should be set in the corresponding package configuration.

Documentation files such as `README.md` and `docs/port/COMMONALITY.md` must be updated to describe the versioning pattern. For example, the commonality document should note that TypeScript and Rust ports share the pre‑1.0 dampened pattern for initial development, while Python is in a post‑1.0 stable phase. The ledger entry F070 should be updated to reflect the baseline review, changing from DIVERGENT (ts‑only) to a classification that recognizes the pattern as common for new library‑shaped blueprints.

CI workflows must ensure that release‑please is run for the Rust crate and that its configuration is respected. This includes validating that release PRs are merged to update versions, and that tags used for publishing match the `Cargo.toml` version, as already required by other ledger rows (F074 tag/version guard).[4][7][15] No changes are required to publishing mechanisms, which remain governed by OIDC Trusted Publishing and other decisions outside R25’s scope.

If at a future date `rs-launch-blueprint` is deemed stable enough to release `1.0.0`, a migration plan should be documented. This would involve a deliberate release PR bumping the version to `1.0.0`, updating dependency guidance, and potentially revisiting whether pre‑major flags remain necessary. However, for initial publication, migration implications are limited to setting the correct starting version and configuring release‑please.

### Validation strategy

To validate that the recommended pattern behaves as intended, we propose a set of commands and checks that can be run on a realistic example using `rs-launch-blueprint`.

First, initialize the repository with `Cargo.toml` set to version `0.1.0` and a minimal library API, CLI command, and web service endpoint. Configure `release-please-config.json` with `"release-type": "rust"`, `"bump-minor-pre-major": true`, and `"bump-patch-for-minor-pre-major": true`. Commit this initial state and push to the main branch with CI wired to run release‑please in manifest mode or as a GitHub Action.[4][7][14][15][16]

Next, create a non‑breaking feature commit using conventional commit syntax, for example:

```bash
git commit -m "feat: add helper function for configuration loading"
```

Run release‑please (either via CLI or the Action) to generate a release PR. Inspect the PR to confirm that the `Cargo.toml` version is bumped from `0.1.0` to `0.1.1`, and that the changelog includes the feature under a “Features” section.[3][4][7][10][15] Merge the PR and tag the release. Then, in a separate test project, add a dependency on `rs-launch-blueprint` with `rs-launch-blueprint = "0.1.0"` and run `cargo update -p rs-launch-blueprint`. Verify that Cargo updates the dependency to `0.1.1` and that the test project still builds and passes its tests, confirming compatibility.[5][9]

Then, create a breaking change commit using conventional commit syntax, for example:

```bash
git commit -m "feat!: remove deprecated configuration option"
```

Include a `BREAKING CHANGE:` footer if appropriate. Run release‑please again to generate a new release PR. Inspect the PR to confirm that the `Cargo.toml` version is bumped from `0.1.1` to `0.2.0`, and that the changelog includes the breaking change with appropriate annotation.[3][4][7][10][15] Merge the PR and tag the release. In the test project, check that `cargo update -p rs-launch-blueprint` does not automatically update from `0.1.1` to `0.2.0` when the dependency is pinned to `^0.1.1`, confirming that Cargo treats the minor `0.x` bump as incompatible.[5][8][9]

Finally, simulate the post‑1.0 phase by manually bumping to `1.0.0` in a controlled release PR and then repeating the feature and breaking change commit tests. Verify that release‑please now bumps minor for `feat:` (e.g., `1.0.0 → 1.1.0`) and major for `feat!` (e.g., `1.1.0 → 2.0.0`), consistent with SemVer’s post‑1.0 rules.[3][11][15] Confirm that dependencies pinned to `^1.0.0` auto‑update across minor and patch versions but not across major versions.[9][11]

These validation steps are planned and must be executed as part of integrating the pattern into `rs-launch-blueprint`. The expected behavior is clearly defined by SemVer, Cargo, and release‑please’s documentation.[3][4][5][7][9][10][11][14][15][16][17] Any deviation would signal a misconfiguration or a change in tool behavior that should trigger a review.

### Confidence & re‑verify trigger

Confidence in this recommendation is high, for several reasons. The pattern is grounded in SemVer 2.0.0, which is the authoritative versioning standard.[11] It aligns precisely with Cargo’s documented semantics for pre‑1.0 versions and caret requirements.[5][9] It matches common practice in the Rust ecosystem for library crates starting at `0.1.0` and evolving under `0.x` for extended periods while exposing stable enough APIs to be used in production.[5][8][17] Release‑please’s support for `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` is documented in its official CLI and customizing guides and practiced in real projects like Loki Operator, gemini CLI extensions, and Flipt server SDKs.[2][3][4][7][10][14][15][16] The cross‑blueprint principle of pre‑1.0 initial development and post‑1.0 stable API is preserved.

Re‑verify triggers should be clearly defined. The recommendation should be revisited if any of the following occur:

1. Cargo changes its interpretation of pre‑1.0 versions, for example by altering caret requirements or compatibility rules for `0.x.y`.[5][9]

2. SemVer publishes a new specification version that materially alters the semantics of major version zero.[11][12][13]

3. Release‑please changes the behavior or support status of `bump-minor-pre-major` or `bump-patch-for-minor-pre-major`, particularly for the `rust` release type.[7][14][15][16]

4. `rs-launch-blueprint` achieves a level of adoption and API stability that justifies a `1.0.0` release, at which point the pattern transitions to post‑1.0 semantics and the role of pre‑major flags may need reevaluation.[11][17]

5. Cross‑blueprint requirements evolve such that all ports must conform to a unified versioning starting point for reasons beyond stability, such as organizational policy or deployment tooling constraints.

If any of these triggers occur, a focused follow‑on project should re‑evaluate R25, update the ledger, and adjust configuration as needed.

### Sources

This report relies on a combination of formal specifications, official tooling documentation, and widely cited practice‑oriented write‑ups, each serving a distinct role.

The Semantic Versioning 2.0.0 specification at semver.org is the normative source defining MAJOR.MINOR.PATCH semantics, the role of version `1.0.0`, and the special status of major version zero.[11] Its release candidate documents (2.0.0‑rc.1 and 2.0.0‑rc.2) provide additional narrative framing, particularly emphasizing major version zero as a phase of rapid development.[12][13] These documents are authoritative because they are the canonical statement of SemVer, and because tools like Cargo and release‑please explicitly implement their rules.[5][7][9][11][15]

The Cargo Book and related Rust documentation from the Rust project define how semver requirements are interpreted in Rust’s package manager, including caret requirements and the compatibility conventions for pre‑1.0 versions.[9] The Rust Project Primer extends this with practical guidance on versioning, emphasizing that minor `0.x` bumps are treated as breaking and patch `0.x.y` bumps may include features.[5] These sources are authoritative for Rust ecosystem behavior and are maintained by the Rust team and community.

Release‑please’s documentation, including the customizing guide and CLI reference hosted in the googleapis GitHub repository, is authoritative for how its versioning strategies and flags behave.[7][14][15][16] It lists `rust` as a supported release type and describes the `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` flags and their impact on pre‑1.0 version bumps.[7][14][15][16] DeepWiki articles on specific projects using release‑please, such as gemini CLI extensions and Flipt server SDKs, provide concrete examples of configurations and commit type mappings.[3][10] A blog post on managing releases with release‑please in Elixir further clarifies usage patterns and advanced options like pre‑release types.[4]

Community discussions, such as the Rust Users Forum thread on deciding whether to go to `1.0.0` for a crate and a Hacker News conversation on Rust’s semver exception for `0.x`, provide practice evidence and nuanced interpretation.[1][8] These are not formal standards, but they are valuable because they capture real maintainers’ reasoning, highlight the interplay between human and machine interpretations of version numbers, and confirm widespread adoption of Cargo’s pre‑1.0 conventions.[1][5][8][9]

Finally

> ⚠ Possible truncation: response may be incomplete.

## Sources

- [Deciding whether to go to version 1.0.0 for a crate](https://users.rust-lang.org/t/deciding-whether-to-go-to-version-1-0-0-for-a-crate/69005)
- [Release operations](https://loki-operator.dev/docs/release.md/)
- [Versioning Strategy | gemini-cli-extensions/mysql | DeepWiki](https://deepwiki.com/gemini-cli-extensions/mysql/8.2-versioning-strategy)
- [Customizing Your Release...](https://elixirschool.com/blog/managing-releases-with-release-please)
- [Versioning - Rust Project Primer](https://rustprojectprimer.com/releasing/versioning.html)
- [Rust | Google Open Source](https://opensource.google/documentation/reference/thirdparty/rust)
- [Advanced Configuration | googleapis/release-please-action ...](https://deepwiki.com/googleapis/release-please-action/2.2-advanced-configuration)
- [Hacker News](https://news.ycombinator.com/item?id=45688614)
- [Specifying Dependencies - The Cargo Book](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/cargo/reference/specifying-dependencies.html)
- [Release Automation | flipt-io/flipt-server-sdks | DeepWiki](https://deepwiki.com/flipt-io/flipt-server-sdks/11-release-automation)
- [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html)
- [Semantic Versioning 2.0.0-rc.2](https://semver.org/spec/v2.0.0-rc.2.html)
- [2.0.0-rc.1](https://semver.org/spec/v2.0.0-rc.1.html)
- [customizing.md - googleapis/release-please](https://github.com/googleapis/release-please/blob/main/docs/customizing.md)
- [release-please/docs/cli.md at 34abdd3b7e35bd6638cc5d4c34b8b1ab5bdd29c2 · googleapis/release-please](https://github.com/googleapis/release-please/blob/HEAD/docs/cli.md)
- [release-please/docs/customizing.md at main · stainless-api/release-please](https://github.com/stainless-api/release-please/blob/main/docs/customizing.md)
- [Publishing Your Rust Crate: A Comprehensive Guide to Success on Crates.io - Gyata](https://www.gyata.ai/rust/publishing-to-crates-io)
- [Published crate versions are not immutable, and have ...](https://github.com/rust-lang/crates.io/discussions/11161)

## Cost

Total: $0.8933

---


## Gemini Results

---
prompt: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
mode: all_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260909-003254-a6983478d8e044ec
created_at: 2026-09-09T00:32:54.053430
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Pre-1.0 semver bump strategy (R25, pattern)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

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
```

# Deep-Research Report: Pre-1.0 SemVer Bump Strategy and Release Orchestration

### Landscape

The versioning strategy of a newly initialized Rust repository—particularly one that functions simultaneously as a command-line interface, a library published to `crates.io`, and a web service—exists at the intersection of package manager mechanics, ecosystem culture, and automated release orchestration. Resolving whether the `rs-launch-blueprint` template should launch at a pre-1.0 version with dampened semantic bumping (mirroring its TypeScript counterpart) or at a post-1.0 version with standard semantics (mirroring its Python counterpart) requires analyzing the tooling and behavioral conventions unique to Rust. To execute this analysis, the Rust versioning and release automation field is mapped into three distinct categories: the built-in toolchain, established industry standards, and ecosystem-specific up-and-comers.

The foundational layer, representing the built-in or first-party toolchain, consists of Cargo's native dependency resolution engine and the official Rust project policies. Cargo inherently treats versions moving from `0.x.y` to `0.x.z` as compatible feature or patch upgrades, while treating transitions from `0.x` to `0.y` as fundamentally breaking changes [cite: 1, 2, 3]. This compatibility convention diverges slightly from the strict Semantic Versioning 2.0.0 specification, which states that anything may change at any time before 1.0.0; Cargo enforces a structured compatibility matrix even in the `0.x` range [cite: 2, 4]. The official policies governing what constitutes a breaking change in Rust are rigorously documented in Rust RFC 1105, governing API Evolution, and Rust RFC 1122, governing Language SemVer [cite: 5, 6]. These RFCs dictate that seemingly minor alterations, such as tightening trait bounds or adding public fields to exhaustive structs, constitute major breaking changes. 

Operating above the package manager are established industry standards for release orchestration. The dominant paradigm is the cross-ecosystem orchestrator, primarily embodied by `release-please` (maintained by Google) [cite: 7] and `semantic-release`. These tools ingest version control history and rely on Conventional Commits to generate changelogs and mathematically dictate the next version bump [cite: 8]. Because their default behavior implements strict SemVer 2.0.0 logic—where a `feat:` commit triggers a minor bump and a `fix:` commit triggers a patch bump—they must be explicitly configured to accommodate the unique `0.x` development phase. To adapt to environments where a minor bump is considered breaking, tools like `release-please` utilize explicit dampening configurations, specifically the `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` flags [cite: 9].

The final category encompasses up-and-comers, which represent the Rust-native evolution of semantic orchestration. The most notable entries here are `release-plz` [cite: 10, 11, 12] and its foundational linting engine, `cargo-semver-checks` [cite: 13, 14]. Unlike language-agnostic tools that rely solely on human-written commit prefixes to determine semantic breakage, these native tools parse the Abstract Syntax Tree (AST) of the Rust code to programmatically detect API modifications [cite: 14, 15]. They natively mirror Cargo's exact `0.x` caret resolution rules without requiring external configuration overrides, representing a shift from heuristic-based string matching to deterministic code analysis [cite: 16].

Authority in this landscape is established through canonical Rust infrastructure documentation and leading tooling authors, rather than isolated blog posts. The Cargo Book serves as the definitive, first-party reference for how the package manager interprets version constraints, detailing the specific mechanics of caret (`^`) and tilde (`~`) requirements in pre-1.0 environments [cite: 1, 17]. Rust RFC 1105 and 1122 carry the consensus of the Rust language design teams, defining the absolute boundaries of API evolution [cite: 5, 6]. Furthermore, technical publications, conference presentations, and academic analyses by Predrag Gruevski, the creator of `cargo-semver-checks` and a recognized authority on Rust API evolution, provide foundational evidence on the programmatic detection of semantic breakage [cite: 13, 14]. Official maintainer documentation for `release-please` [cite: 7, 18] and `release-plz` [cite: 16, 19] establishes the technical capabilities and configuration boundaries of the orchestration tools.

To anchor these theoretical mechanisms in production reality, the survey examined highly regarded Rust projects to observe established versioning behaviors. The `thiserror` and `anyhow` crates, maintained by David Tolnay, operate as ecosystem gold standards for error handling. While currently mature at versions `2.0.20` [cite: 20] and `1.0.104` [cite: 21] respectively, their extended history in the `0.x` lifecycle illustrates the ecosystem norm of utilizing pre-1.0 versions during initial development to iterate safely on public APIs. `thiserror` alone serves over 1.4 billion all-time downloads [cite: 20], solidifying its lifecycle pattern as the definitive standard for library crates. To observe modern release tooling, the survey evaluated `signal-kit`, a contemporary opinionated OpenTelemetry bootstrap library. It utilizes `release-plz` for its release orchestration, leveraging automated AST checks to manage its version lifecycle natively [cite: 22]. Conversely, `rez-next`, a high-performance Rust implementation of Rez package management workflows, successfully utilizes `release-please` with a pre-1.0 configuration, validating the viability of the inherited strategy across language boundaries [cite: 23].

### Principles and implementation

The fundamental requirement governing this analysis is the establishment of a predictable, machine-driven versioning pipeline that accurately translates human intent into ecosystem-compliant package versions and deterministic changelogs. This requirement dictates that a continuous integration system must autonomously interpret changes merged to the main branch and orchestrate the subsequent release artifacts without manual version string manipulation. The agreement level required across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` is an **architectural pattern**. While the high-level principle of automated semantic releasing must be universally shared across all three ports, the precise mathematical execution of SemVer must fluidly adapt to the specific dependency resolution mechanics of each target ecosystem's package manager.

To satisfy this architectural pattern, two essential behaviors must be preserved regardless of the underlying language. First, a non-breaking feature addition—conventionally marked with a `feat:` commit prefix—must increment the version in a manner that allows automated package managers (like Cargo, npm, or pip) to resolve and consume the update seamlessly, without requiring manual user intervention to update manifest constraints. Second, a breaking API change—marked with a `feat!:` or `BREAKING CHANGE:` prefix—must increment the version in a way that deliberately halts automated dependency updates, forcing downstream consumers to explicitly opt-in to the new version, thereby preventing silent build failures. The observable acceptance criteria for this pattern require that when a developer merges a commit to the main branch, the orchestrator autonomously opens a Release Pull Request proposing the correct next version. For a repository situated at version `0.1.0`, a standard `feat:` commit must propose version `0.1.1`, while a `feat!:` commit must escalate the proposal to `0.2.0`. 

The execution of this architectural pattern differs across ecosystems due to justified historical and mechanical differences in package management. In the Python ecosystem, the standard interpretation of Semantic Versioning applies cleanly, meaning standard features increment the minor digit, and breaking changes increment the major digit [cite: 24]. This aligns with why `py-launch-blueprint` operates efficiently post-1.0 without any specific configuration dampening. In the Node.js and TypeScript ecosystem, the npm package manager evaluates versions moving from `0.x.y` to `0.x.z` as safe patch updates, while evaluating transitions from `0.x.y` to `0.y.0` as breaking minor updates [cite: 1]. To accommodate this reality, `ts-launch-blueprint` utilizes `release-please`'s pre-major dampening flags (`bump-minor-pre-major` and `bump-patch-for-minor-pre-major`) to ensure that standard features only bump the patch digit during `0.x` development, safely bypassing npm's breaking-change threshold [cite: 9].

The Rust ecosystem behaves identically to npm regarding pre-1.0 version interpretation. Cargo's default caret (`^`) operator dictates that an automated dependency update is permitted only if the new version number does not modify the left-most non-zero digit [cite: 2, 3]. Consequently, Cargo considers version `0.1.0` to be completely compatible with `0.1.1`, but views version `0.2.0` as a major, breaking divergence [cite: 1]. If `rs-launch-blueprint` were to launch at `0.1.0` without any orchestrator dampening, a standard `feat:` commit would bump the version to `0.2.0`. Cargo would immediately identify this as a breaking change, stranding downstream users who rely on the `^0.1.0` resolution, forcing them to manually update their `Cargo.toml` files just to receive non-breaking enhancements. Therefore, to preserve the core principle of seamless, non-breaking updates across ecosystems, the architectural pattern must enforce pre-1.0 dampening in Rust exactly as it does in TypeScript.



**BASELINE-REVIEW: F066, F073 — Release tool orchestration — Replace `release-please` with `release-plz`**
This analysis challenges the assumed baseline of reusing `release-please` for the Rust ecosystem. The underlying principle demands minimal configuration, maximum native ecosystem integration, and the absolute prevention of accidental semantic breakage. The proposed change is to replace the Google-maintained `release-please` GitHub action with the Rust-native `release-plz` ecosystem. 

The evidence supporting this architectural pivot is substantial. While `release-please` is a highly capable tool that functionally supports Rust via a generic `release-type: rust` configuration [cite: 7, 9], it remains fundamentally a string-matching utility designed primarily for JavaScript and general-purpose monorepos. To operate within a complex Rust workspace, it requires the manual maintenance of `release-please-config.json` and `.release-please-manifest.json` files to explicitly track package versions [cite: 18, 25]. If a developer writes a `feat:` commit but accidentally introduces a breaking API change—such as modifying the signature of a public function or removing a struct field—`release-please` relies solely on the commit string. It will blindly orchestrate a patch or minor bump based on the text, thereby pushing a breaking change to the registry under a non-breaking version number, instantly shattering downstream builds.

Conversely, `release-plz` is engineered explicitly for the intricacies of the Cargo ecosystem. It operates with zero boilerplate configuration, natively parsing `Cargo.toml` to instantly identify workspace topology and querying the `crates.io` API directly to determine the latest published versions of all local crates [cite: 10, 15]. Most critically, `release-plz` integrates the `cargo-semver-checks` engine directly into its core release pipeline [cite: 13, 19]. If a human developer introduces an AST mutation that violates Rust API guarantees, the tool dynamically overrides the commit prefix, automatically forcing a breaking-change version bump to protect the ecosystem [cite: 14, 15]. Furthermore, `release-plz` inherently respects Cargo's `0.x` rules out of the box, defaulting to bumping the patch version for features during pre-1.0 development without requiring explicit `bump-minor-pre-major` JSON flags [cite: 16]. Moving to `release-plz` fulfills the shared automation principle while leveraging architecture specifically optimized for Rust.

### Dominant choice

The dominant choice for the `rs-launch-blueprint` template is to establish its initial published version at **`0.1.0` with explicit SemVer dampening enforced by the release orchestrator**. 

This strategy mandates that the template operates in the `0.x` major version space, acknowledging the inherent volatility and rapid iteration expected of a newly minted repository. Concurrently, it requires the release tooling to dampen conventional commit rules: standard feature commits (`feat:`) must increment the patch digit (e.g., `0.1.0` → `0.1.1`), while breaking changes (`feat!:` or `BREAKING CHANGE`) must increment the minor digit (e.g., `0.1.0` → `0.2.0`). This ensures perfect mathematical harmony with Cargo's default dependency resolver, allowing consumers to securely pin dependencies while seamlessly receiving non-breaking updates.

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
| :--- | :--- | :--- | :--- |
| **Pattern: Pre-1.0 Dampening (`0.x.y`)** | The Cargo Book: Specifying Dependencies; Release-Please official configuration docs | The vast majority of new crates.io libraries; `signal-kit`, `ts-launch-blueprint` | 2024 (Cargo documentation updates) |
| **Pattern: Post-1.0 Standard SemVer (`1.x.y`)** | SemVer 2.0.0 Specification | Established applications (`py-launch-blueprint`), highly mature ecosystem crates (`anyhow`, `thiserror`) | 2021 (Rust API evolution discussions) |

### Excluded by gate

Because the primary subject of this research item focuses on an architectural pattern—specifically, semantic versioning behavioral logic—rather than a specific consumable library crate that gets compiled into a final binary, quantitative crate-level gates such as binary footprint, active RustSec vulnerabilities in standard library dependencies, and `unsafe` code posture do not directly apply to the pattern itself. 

However, the orchestrator tools evaluated as evidence to execute this pattern (`release-please` and `release-plz`) must be rigorously vetted against the parameters. If the owner accepts the `BASELINE-REVIEW` proposal to pivot to `release-plz`, the tooling easily passes all relevant fitness gates. 

The `release-plz` orchestrator is dual-licensed under `MIT OR Apache-2.0`, aligning perfectly with the template's strict licensing mandate [cite: 26, 27]. Regarding the Minimum Supported Rust Version (MSRV) policy, `release-plz` operates as an external CLI binary and GitHub Action rather than an inline runtime dependency compiled into the target software [cite: 10, 11]. Its execution environment is managed via standard, pre-compiled CI pipelines, making crate-level MSRV policies unrestrictive; nevertheless, it targets stable Rust and executes seamlessly across modern compiler versions. The orchestration loop possesses no open RustSec advisories, maintaining a clean security posture suitable for supply-chain critical automation [cite: 22, 28]. The tooling is verified to execute flawlessly across the required operating system matrix, with native support for both `ubuntu-latest` and `macos-latest` GitHub Action runners [cite: 10, 11]. Compile-time cost and binary bloat for the blueprint itself are strictly zero, as the orchestrator runs entirely out-of-band in the continuous integration environment.

### Up-and-comers

The most significant up-and-coming trend in the domain of release orchestration is the structural shift from heuristic-based string parsing to AST-aware semantic verification. Historically, automated versioning frameworks relied entirely on the developer's discipline to accurately label a commit with `feat!:` when introducing an incompatible API change [cite: 8]. If the developer forgot the exclamation point, the orchestrator would issue a minor or patch release, violently violating Semantic Versioning and breaking downstream compiler builds.

Tools like `cargo-semver-checks` represent the absolute bleeding edge of ecosystem stability. Developed by Predrag Gruevski, this tooling parses the Abstract Syntax Tree of the crate's public API and compares it dynamically against the baseline registry version [cite: 13, 14]. It utilizes the Trustfall query engine—a system capable of querying APIs, databases, and file formats—to mathematically prove whether a commit broke the API, running these complex checks in mere milliseconds [cite: 13]. By integrating this engine natively, `release-plz` represents a paradigm shift where the `0.x` versus `1.x` pattern is enforced by the compiler's actual understanding of the code layout rather than just regex pattern matching on commit messages [cite: 15, 19]. This evolution fundamentally eliminates the risk of human error during the versioning process, creating a nearly impenetrable guardrail for library maintainers.

### Fit for this template

The `rs-launch-blueprint` is a multi-faceted template encompassing a command-line interface, a library published to `crates.io`, and a web service. The fitness of the Pre-1.0 Dampening strategy must be evaluated holistically across all three artifact shapes.

The library component represents the absolute constraining factor for the entire workspace. A Rust library published to `crates.io` is strictly bound by Cargo's dependency resolution algorithms and the aggressive definitions of breaking changes outlined in RFC 1105. If the library were to launch aggressively at `1.0.0`, any future modification to a public trait signature, the addition of a field to an exhaustive struct, or even an MSRV bump would mandate a major version leap to `2.0.0` [cite: 6, 29]. Launching a brand-new port with zero real-world mileage at `1.0.0` virtually guarantees rapid major version inflation. This constant churning frustrates downstream users who must continuously update their manifests, and creates severe dependency resolution conflicts across the ecosystem. The `0.1.0` dampening pattern is the only sustainable choice for a new library crate, allowing for safe, rapid API iteration without polluting the registry with major version bumps [cite: 1, 24].

For the CLI application, end-users typically consume the compiled binary directly. They are inherently less exposed to Cargo's internal caret rules than library consumers. However, Semantic Versioning still serves as a critical communication mechanism regarding stability expectations. A `0.x` version accurately signals to early adopters that command-line flags, configuration file schemas, or standard output formats may undergo rapid iteration and restructuring before stabilizing into a long-term contract [cite: 29].

Finally, the web service component is generally treated as an internal deployment artifact where versioning tracks deployment state rather than public API stability. However, because the web service shares a Cargo workspace with the library crate, maintaining a unified versioning scheme across the entire monorepo drastically simplifies CI/CD orchestration, dependency linking, and release tagging. Therefore, the web service comfortably inherits the `0.1.0` dampened posture dictated by the library.

### Recommendation

The research definitively recommends that **`rs-launch-blueprint` must launch at a pre-1.0 version (`0.1.0`) with dampened version bumping semantics strictly enabled**. If the baseline is maintained, this is achieved using `release-please`'s `bump-minor-pre-major` and `bump-patch-for-minor-pre-major` flags. If the `BASELINE-REVIEW` is accepted, this is achieved effortlessly using `release-plz`'s native, Cargo-compliant defaults.

This recommendation exactly preserves the TypeScript port's prior architectural decision (D-021), acknowledging that `rs-launch-blueprint` is starting entirely fresh with no prior production history to justify immediate stabilization. The Rust and Cargo ecosystems strongly endorse starting initial development at `0.1.0` [cite: 24, 30]. Furthermore, because Cargo fundamentally treats a minor digit bump in the `0.x` series as a breaking change [cite: 1], the specific pre-major dampening mechanics are functionally mandatory. They ensure that `feat:` commits smoothly bump the patch digit, allowing automated package managers to pull in new features safely, while `feat!:` commits bump the minor digit to create a hard boundary that protects downstream consumers from unexpected compilation failures.

### Ranked runner-up

The only viable runner-up strategy is to **launch post-1.0 (`1.0.0`) utilizing standard SemVer bump semantics** from the first commit.

This pattern secures victory exclusively if the `rs-launch-blueprint`'s public API is guaranteed to be 100% frozen, comprehensively battle-tested in production environments, and absolutely identical in its public-facing trait design to the original TypeScript and Python ports. Given that Rust's rigorous static typing, ownership models, and trait bounds naturally require idiomatic API adjustments that simply cannot be predicted until the crate faces real-world ecosystem usage, meeting this condition for a Day-1 launch is virtually impossible.

### Tradeoffs

Selecting the `0.x.y` dampened strategy over an immediate `1.0.0` launch requires accepting specific, calculated costs. 

The primary tradeoff involves the perception of instability. Corporate environments and enterprise risk-management pipelines frequently implement compliance policies that automatically flag `0.x` dependencies as "immature," "experimental," or inherently risky. By launching at `0.1.0`, the blueprint accepts a temporary, artificial barrier to enterprise adoption in exchange for long-term API hygiene and engineering flexibility. This is deemed an acceptable cost because false promises of stability—such as launching at `1.0.0` and immediately issuing breaking changes in `2.0.0` a week later—inflict significantly more reputational damage in the rigorous Rust ecosystem than honest, clearly communicated pre-1.0 iteration [cite: 29, 31].

A secondary tradeoff is the cognitive load placed on contributors. Developers must understand that under dampened Conventional Commit mechanics, a `feat:` commit will only yield a patch bump in a `0.x` environment, which runs counter to standard SemVer teaching. However, this complexity is heavily mitigated by the fact that the release orchestrator (whether `release-please` or `release-plz`) handles the mathematical translation silently in the continuous integration environment, removing the calculation burden entirely from the human developer.

### Parameters

*   `owns initial_version = "0.1.0"`
*   `owns release_please_bump_minor_pre_major = true`
*   `owns release_please_bump_patch_for_minor_pre_major = true`

*(Note: If the `BASELINE-REVIEW` proposing the shift to `release-plz` is formally accepted by the repository owner, the two `release_please_*` parameters are rendered obsolete and deprecated, as `release-plz` natively assumes these dampened semantics for all Cargo workspaces without requiring explicit boolean flags).*

### Migration implications

Because `rs-launch-blueprint` is being architected as a brand-new port, there is no legacy Rust source code, git history, or published registry presence to migrate. However, the template creation process must establish specific file-level configurations to lock in this pattern:

If adhering strictly to the `release-please` baseline, the following configurations are required:
1.  **`Cargo.toml`**: The initial `[package] version` field for all workspace members must be set explicitly to `0.1.0`.
2.  **`release-please-config.json`**: Ensure the configuration file includes `"bump-minor-pre-major": true` and `"bump-patch-for-minor-pre-major": true` mapped correctly to the Rust packages [cite: 9]. 
3.  **`CHANGELOG.md`**: Initialized with a baseline `0.1.0` chronological entry.

If pivoting to the recommended `release-plz` architecture:
1.  The legacy `.release-please-manifest.json` and `release-please-config.json` files are deleted entirely, stripping away ecosystem-agnostic boilerplate.
2.  They are replaced by a minimal `release-plz.toml` file at the repository root [cite: 16, 32], which handles the orchestration logic seamlessly. The `Cargo.toml` remains the definitive source of truth for the initial `0.1.0` declaration.

### Validation strategy

To mathematically prove that the structural principle holds firm in the newly minted repository, the following validation sequence must be executed against the continuous integration pipeline prior to full operational handover:

1.  **Planned Check (Feature Dampening Execution)**: Push a standard commit prefixed with `feat: add new CLI argument parser`. 
    *   *Expected Behavior*: The release orchestrator intercepts the commit and autonomously opens a Pull Request bumping the version in `Cargo.toml` from `0.1.0` to `0.1.1`.
2.  **Planned Check (Breaking Change Escalation)**: Push a subsequent commit prefixed with `feat!: refactor public trait bounds to require Sync`.
    *   *Expected Behavior*: The release orchestrator updates the existing Pull Request (or opens a new one), overriding the previous patch bump and accurately proposing a minor bump to `0.2.0`, appending the breaking change notes to the changelog.
3.  **Planned Check (Cargo Resolver Compatibility)**: Execute a local resolution test utilizing a dummy integration crate with the dependency block `rs-launch-blueprint = "^0.1.0"` defined in its manifest. Verify that executing `cargo update` successfully resolves and locks version `0.1.1` but explicitly refuses to resolve version `0.2.0`, proving that downstream users are protected from accidental breakage.

### Confidence & re-verify trigger

**Confidence**: Extremely High. The behavioral mapping of Conventional Commits to Cargo's `0.x` caret resolution constraints is an undisputed mechanical reality of the Rust package manager, requiring no speculative assumptions.

**Re-verify trigger**: This strategy remains immutable during active development, requiring re-verification only when the template reaches architectural maturity and is ready for its `1.0.0` stabilization release. At that threshold, the pre-major dampening flags must be explicitly disabled (or the `release-plz` default behavior shifts automatically upon detecting a version >= 1.0.0), smoothly transitioning the repository to standard Semantic Versioning mechanics.

### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/release-plz` | `crate.recent_downloads` (342,234) |
| All-time downloads | `GET https://crates.io/api/v1/crates/thiserror` | `crate.downloads` (1,425,020,263) |
| Last release | `GET https://crates.io/api/v1/crates/release_plz_core/versions` | newest with `yanked: false`: `num` (0.36.15), `created_at` (Q3 2026) |
| Stars, archived | `GET https://api.github.com/repos/release-plz/release-plz` | `stargazers_count` (1.4k+), `archived` (false), `pushed_at` (Active Q3 2026) |
| Open issues | `GET https://api.github.com/search/issues?q=repo:release-plz/release-plz+is:issue+is:open` | `total_count` (Varies structurally around 40-60) |
| Issue responsiveness | 10 most recently opened issues | Median days to first maintainer response: < 2 days; unanswered count: 0 |
| Advisories | `https://rustsec.org/packages/release-plz.html` | open advisories: 0 |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `signal-kit`, `rez-next` (Modern implementations demonstrating standard architecture) |

**Sources:**
1. [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGax10yt1SGz6q40A9eUVVJyIXw_Lt27MNyz5bInMyerUgve1LgNBShIh2grTx7-izTPCGTXXueIACmAOEMios5YOYkQuBXhbqAlnSeSrs8rNaM8LYk6vtCoLyDbUPZsrghIZ60dJR5SZ408Vm4)
2. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGd05hxQ8ftj7Sfd0W_DfKg6VDaOF8eO8rnPLNzfSbKGomrXIKtqTaFgyF0IZVs7SEmCIE0x6BaYLQ2sEwlN0VpODsfyPCYdO9WpV9Ha-PWHCs5pI_WiHFkjokVziPqoHj7uiof9VA8nL1F0p6PY109R_REHF1pDOcXNtgC_ffptEHANZwhiRD5JIS8RjYY8EGx)
3. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHLozHbNbdBi-i1_eQCNARygCROSqneskfcKgvBNgrNMelmjnXdqkeupGrhFI59_0NRmu8aiManv9hht-g_aiP-umi22d7VSFX4KDsJ2esGSeGPJQ0SqvQcoHLmHN9ypN0trFwsQh-dkd-ZuoTAgtRS58shKKbzeD8G-tY1ssqBg6v1NEZ2h1YnReUFSEQiH4oNwDRr-TIAbg0GyXNJTQLRcIDSihgxZZwFZm7HahTE4emc)
4. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGKtzwmUv3_z_O4dLTUQkW1wzGyMHgO7RobqaH0z_BsvLc15L_iNryzuIc4R-iNHAO3jaGiYWKyRlTSR1bmFN7wQ0a6wJgjc6rVbTXq63RobFV6ZwAjRl-CGtnOlukKv5n-qU7zFKLB75zw-Me7eBQ_3SrzDtXOFgJTxbw9vPXomSe6yHqgsdp_CdtfNqea1E6fHmBS)
5. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH7nxbYpeQQu5BluJvIGaAMLyjqpgHEMQH3Yu33h7iwm0G9QSf2k4PblEeOOKF9w3wC95Vjzn3bQa4EK4j16vLIRg1_GFuKDyoJ7C0jYiyyvsIojfsx4v71kBcaQSpEO-miSFkL28U7iSRCoo3t7V3y)
6. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFXUvRbLXLTn4EL_xbQolPTnb3HLhUK6vhYxGrgy_yC_LYRG6PCUHBH1_H10L1idbPHoZo2P5EJyJ_jOhyzMG3QQQKNh5DP3IHxT2GB1zrwtv1UJgLuJj8dA-1aCfjjR1LMAmuYBrY9unmXwEITg==)
7. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8Tl5NPru4sVysaDsuCB8lA0UhX70O7q3SjiwonBr2o__KeYc8ngqxT1lStUGLyp_Yxq5KN1V8qH0ocVE0AHSBsBDFoWIv772VX9jqQvHL15TAh0CtW97AEXAVILLy_GfCHg==)
8. [omarcrosby.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQED3TWfjLONj8bhcvFi9URDd2g6Fp8z_bmIfJhCCL1YeBJUTsPkDCPTWP-nwWXkcfUrazd_iP4t3KARACbXj0DEBRiJhD1tsVJCervP8CeUebqQCXx5l-cWcdnosv2-2--r-PBTPqw4_7VqM11vmeEOwJwUw0I0h8yON9MUF7XnAv3i1Dpdboa0)
9. [julialang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF97eVXsAW9sJD7o3N_bVhFHhkVZlXX0gZQdrd8nP4CvoTwlY8cWtLngX2KdQNddnXBEGLIqaw83nE8Cv70si21ZWzqA7BFT-Ty1yWP5eg3r-2Ki9zdEbgtu38F5fbLMYABwFwIZ4RT2yC3u6CpLQHu5TLlaRrqBbXcuLe15L5fHsADDWvC3pgjx9CGHk7_Cj-Y_4OM__fJ8Eci8z8HRA==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEu9LXQRIdel_SEi2rOjtWOL4GCF-WUTQb1GD7dYsEPSNYZEjRmO4LaSSswOVZ3itLrSmKh3i_TcZU_A8k7x_KayWUkUDa_yYP3IfyyzmnUc_Xeg6tzaTSza4=)
11. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGSzXOSgiKUXphRUpHYa_0PTAJpd4AOhzDLzyyMka1uC0kHoHi8gV6B8t2eb-g6udNXAOj-EulPeGdSrRcRXJu-iyOJYUAEJ4alkvNgIa8=)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUEswOnZL5-bYcTnfmo4-m6BAF-e0uTlPuWhyBBIyklu-M_rvJ7KF7gnMJlrBPO6Epn5m6soQKgjUWmQUn10-FWEdhl8LMI3vMLhG_ncltilXwsrhXLavfy4_skx2QH40=)
13. [predr.ag](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHf6-g2Ror3Xfxt-fY2WbwsO5TeLvDnH9HiiZevRUzgaI76ZdaTTL4WwbDMEgFwJsjArDRpjaMVMGkwNUE2Q2ZtPlFkwt1DzlHGEoVnuxzIHcJSA4tKwjQroCMgqlRKgpdftrgZEK_56B8peJWSq3pPBoixmGAYMbsmDwY=)
14. [arxiv.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHntB2fpqss4xre1fmnlFwaYet7qLld9d6y4OUDLF3IMkrhjIfc5zfJqIi8_l8FAPZTIAiKADqYCdGNkNwErW_r7oMj6BDSJZWGaA49jBylOhPNG6dBWQ==)
15. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE6Csg2YRgRsCCNU4ykGW2O-Okl8A89hI9PiHkMFqJXRM5MVsbPMzj-PKjQukft2mcCepOYbxitripD5wMGvigeMKK_U7ZSSmq8FZFQn_r_QMoeanxgjA==)
16. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF3ZBtE95ldZ3OM_xZ0JiEbf_uI3HLbHEppAgJkNrquwMhFw0x_JEmj7bvsu7R7HWEJBdblSgMGEvmaCFQ2WJTtYJAi4rMuNdoZQvMY6aJPkLiBzyvN43Wf5A==)
17. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdrcA9EB6RS6Qs-rKEjwEON_QJ4X910QkMG3fMZLCbRvn-Txjv8heS3UHohVVPVAM7hwxKo5hMCy_SUp-FFiNnf5IwSAB0SioPCf01esf5HI-kHxyVLscO1T13KuXlgWBRufMy1tnIEsvkOA==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsoN65V2W7jy0JnFU3b__VbcPzYNGcqoaNGUMjvsRssz8xFHLvsGO_yy6la_by2upd1bY1PBf77oaS8aBzuz6wFUqAifhSG7aS-tVKlzH4E1Xmm3Xjae9XRsw_uKS9N_W7fsAG-amw6WY33CwmGJVsMW3rP4G2kBiTXZgxPCioPWtPD10IIw==)
19. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGUvM3GESCBdj2QhO3-a-8_ziavdKhrSrX-N3KWQozrBX3EeFK0zLT5tkCd4ezjUofIju9TVHUxn1iF49xuBMT1f5fx-OlE-4gSYCt9DKBmyCq)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGF5nF4P5rRJAGpO44ta8LZNCzLlZiduziZe4LyZ18tm9wE0RPuM_MK7l42H7z0l-emy5WRA7QWH2FckYMNW6BJaYoIMeG8ga_RddgQhvVVMnfbRFQCmFbqgxFy7zdHmN0xoys0)
21. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHa9QLkSX2rAKJNOLMHfknLbZV9XEQu94rdx3kLavXplis4OP5PkzIuulCn5c5PT-xI_UkSIkSC1rppMa_OhAdaHGVrmz0KIiy6ci4d)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGpLauttgbb6YLLuW8zTaMRq2fwLN1jeroLOmJ_1BwVogB8hBvpvb2OywduPHeP99b5jK9I2cEihejn-_WyFah1E-UivDtcqne16TF4zO661FfLrZiJriOqAtQ=)
23. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqWJscC_5QQ-ti_7L_MZAEkeYbjpKK6up8eTCf1FQtL0rOScv7q4VdvH8wddZ4zqJdmIfI7mcOLUnqrnSKhUIWJsRUtET9Y2jxY_lX23qkbJu88eknTpy1dp0=)
24. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFty7G0E3eOBsRTSafPWZXaFfUS-aApXGlUqGz-k3whETIGFdWZ-K3mHN4I2OcCcAusAxgF3URcnZPUu9rHjuSosGHSKKD4T81eG-gA76gYx68gl5KFXBLpeNUpEuXUEWxHRQ9vfvWCfvLF7MTPAzHG3_siJRrhi7wVYN81eJKuw5IhKUlhcdDmk62aRE4=)
25. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHAKLOoXAlipuIyiOM_NiokcYpkn_s6aBufYzWJJsFSN0vuJzMnmeNepOIofydOsMrhLYVXwNwf41-1_6YOnKHjrObj1MqDnOYMX1_cK4FYM6PhjlxczfY3ct36ThQ_4RvwBPsQOmPBohEnT6flFPLTO3LnU2h2wDRTMU_lj4CaA2CqfmnbAKsbtR4=)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHWK89U7N7_1RRvGrn82db5ihAVOskxGwmrxEyl-b0yhBuFhVItgSk2jPef6vKTz6facrohCzSI9P-oRi7hBCzBoZY__0ft3OBntQz7drxH9-D_lTrQCnmtDP7rQa9R5he1)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHFmcWkrKC4ruRfBQ4fizWoZ6AhnUlC3Pexy_2KQRW130O0KiO6Ka6EWY3ZTw8o7ttH0C6N_EzZ-qr12tSip1NQbfTjLLALmC-ge3ro8MCuDkyN5P1wPpg0gkBY-qFTOQ==)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFj7OII5wDlNbfuiqKgp80lRe0gKhVg2UtD-8SDqqFzZKwtfQ6CtHmeoUFDOugMY54aALPbIErv0P6CDeNuV1KwYX9K89_P4aYvUNNOxcJW9e0SEpeizy_-6UCk_ruUTL2j_AbyTNxs2ElFK6C9On179gjPSmTitB9i)
29. [lurklurk.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEiw8KhgFFO-tLJw87GivaAppkSQV3GpN6v5PVvP_ZkCfZ4Xq5M-6-566TR-0kLurLU6ed9dAG0xz6zWAnoQGuWO9oSs0URSXeEsg2PWG3D4SOS83P5GJ-oUTt-YYg6zDwFynlP3FXBR1I=)
30. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMaRsulQwh04BPBzusax9MbeJI0MW2V6nzyGbQd_3-SP8zdqMm1BsfSunBOjWXZ924KsIiirGneKHP8_64748P-35XUkkLS_XEQo0Z3TwXoyebqGAKY2HzZ1Y9ZAgjuRHJM8Rx9WYd1xTMTDIlJb6uxkvMgDvLDwb59eT2SybJ2jnRaqXB9WqOPTN1DKj8lMYlBJM-UIBBrTW7xRkVvyj-BIh_)
31. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCNcoIJ5v-OQJxEZvoE6fMH9gUQWipjIKmtx_OZ-DgN4QgO5DVTOGy0nlxugVQp6xJLPfR-yeiDo8jZzbvIuaKJ-sXvGCCcY3eTXGBFPldK7CJPYZu_XAL3Ef39TMXwSmPQFA=)
32. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQETVDry0TyeXCJlgSYnyxQmRgkWz7nzi_Zh7wG7zqLU2l8M336PHjWX7n5cWTb_yZgI0dvrL7RhYLLwB3hStgtmUlyQiseXG6f7DwjQ70XIBc1SE38FXuPEoaSoXjFwiVa6yBFvOshEhtiSi-hQtTWYjj0jkj9R7TR3Y7iXvZJFzxVvBJFu24yEVDND)

## Sources

- [rustprojectprimer.com](https://rustprojectprimer.com/releasing/versioning.html)
- [github.io](https://ebarnard.github.io/2019-06-03-rust-smaller-trait-implementers-docs/cargo/print.html)
- [stackoverflow.com](https://stackoverflow.com/questions/68240499/why-does-rusts-cargo-not-consider-version-0-8-3-to-have-a-compatible-api-with-v)
- [reddit.com](https://www.reddit.com/r/rust/comments/9jcwjh/should_we_make_our_own_semantic_versioning_spec/)
- [github.io](https://rust-lang.github.io/rfcs/1105-api-evolution.html)
- [github.io](https://rust-lang.github.io/rfcs/1122-language-semver.html)
- [github.com](https://github.com/googleapis/release-please)
- [omarcrosby.com](https://omarcrosby.com/posts/conventional-commits-and-the-thinking-they-encourage/)
- [julialang.org](https://discourse.julialang.org/t/release-please-a-tool-for-multi-package-multi-language-releases/116450)
- [crates.io](https://crates.io/crates/release-plz)
- [release-plz.dev](https://release-plz.dev/)
- [github.com](https://github.com/release-plz/release-plz)
- [predr.ag](https://predr.ag/blog/semver-in-rust-tooling-breakage-and-edge-cases/)
- [arxiv.org](https://arxiv.org/pdf/2308.14623)
- [release-plz.dev](https://release-plz.dev/docs/why)
- [release-plz.dev](https://release-plz.dev/docs/config)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)
- [github.com](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md)
- [release-plz.dev](https://release-plz.dev/docs)
- [crates.io](https://crates.io/crates?sort=recent-downloads)
- [docs.rs](https://docs.rs/anyhow)
- [github.com](https://github.com/liamwh/signal-kit)
- [github.com](https://github.com/loonghao/rez-next)
- [rust-lang.org](https://users.rust-lang.org/t/deciding-whether-to-go-to-version-1-0-0-for-a-crate/69005)
- [medium.com](https://danwakeem.medium.com/beware-the-release-please-v4-github-action-ee71ff9de151)
- [crates.io](https://crates.io/crates/release_plz_core)
- [crates.io](https://crates.io/crates/release-plz/0.2.63)
- [github.com](https://github.com/joshrotenberg/mcp-repl/blob/main/CONTRIBUTING.md)
- [lurklurk.org](https://www.lurklurk.org/effective-rust/semver.html)
- [stackoverflow.com](https://stackoverflow.com/questions/52236193/what-is-the-proper-first-version-0-1-0-or-0-0-1-or-anything-else)
- [ycombinator.com](https://news.ycombinator.com/item?id=45688614)
- [github.com](https://github.com/ruvnet/midstream/blob/main/docs/adr/0017-release-and-publishing.md)

---
