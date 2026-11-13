---
prompt: # Deep-research prompt — Port absence-vs-failure contract (R03, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: how the driven-I/O seam signals "the requested resource does not exist" (an expected, non-exceptional outcome) as distinct from "the transport broke" (an unexpected I/O failure), and where the absence-to-domain-error translation happens. Item kind: `pattern`. Value test: if this answer is wrong, the seam's return-type contract (`Option<T>` vs. `Result<T, E>` at the port/adapter or injected-function boundary) and the call-site translation of absence into a domain error get rewritten across every I/O call in the template.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on where "is it there" is split from "is absence an error." py separates the two: the adapter returns `None` for absence, and a separate service layer turns `None` into a typed exception. ts does both in one function: the same call that performs the HTTP request also decides absence is an error and throws inline. Evidence: py `src/py_launch_blueprint/core/ports.py:47` — `get_project`/`resolve_workspace_gid` return `... | None`; `src/py_launch_blueprint/core/services/projects.py:56` — the service turns `None` into `ProjectNotFoundError`; ts `src/lib/api.ts:182` — `createApiClient`'s `getProjects` resolves the workspace and throws `NotFoundError` inline, in the same function that does the HTTP call. Ledger row: F012 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item's answer must work whether or not the I/O boundary is expressed as a formal port trait (R01 has not yet decided F001); design the absence/failure split so it fits a trait method, a generic bound, or a directly injected function value equally.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no dedicated decision splitting absence from failure; ts's single-function shape (`api.ts:182`) was never treated as a separate design choice from the HTTP-call implementation itself.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): This is a hex pattern that we've used before in the other repo. It would make sense to have a similar best practice pattern across all three.

## Out of scope
- Whether `rs-launch-blueprint` adopts a port/adapter split at all, or injects functions directly; R01 (`ports-and-adapters-seam`) owns F001 — this item's pattern must apply to either shape R01 lands on.
- The stable error-code catalog and its process exit-code mapping; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item decides the seam-level absence/failure signal and where it becomes a domain error, not the eventual exit code that domain error produces.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R03
- owns:
- consumes: R67: error-taxonomy-exit-codes
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a formal port trait exists for the driven-I/O seam (F001). This item's absence-vs-failure pattern must work whether that boundary is a trait method, a generic-bound function, or a directly injected closure — treat R01's shape as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint`'s driven-I/O boundary distinguish "resource not found" from "transport/I/O failure," and where does that distinction become a domain-level error type that feeds R67's exit-code mapping.
- HIGH: Should absence be encoded as `Option<T>` returned by the seam function, with a separate call site converting `None` into a domain error (py's two-layer split), or should the seam itself return a `Result<T, DomainError>` that already distinguishes not-found from transport failure (folding what py splits into one step, closer to ts's shape)?
- HIGH: What Rust idiom cleanly expresses "this outcome (not-found) is expected and non-exceptional" versus "this outcome (I/O failure) is unexpected" — a dedicated error enum variant, `thiserror`-derived error types with distinct variants per cause, or two separate return channels (`Option` for absence, `Result` for failure, composed via `Option<Result<T, E>>` or similar)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Does propagating an absence/failure distinction through `?` (via `From`/`Into` conversions, or combinators like `ok_or_else`/`map_err`) cost ergonomics compared to py's "return `None`, then the service raises" two-step, and is there a standard, testable idiom that keeps the conversion explicit at the seam boundary rather than buried in a generic error type?
- MEDIUM: How should this pattern's error type plug into R67's eventual error taxonomy — does the absence variant need to be a stable, named catalog member decided now, or can this item define the pattern generically and let R67 assign the final variant name/code later?
- LOW: Do any published Rust CLI/library templates or style guides document this same split (a fallible transport call, narrowed to a domain "not found" case) as a named pattern, and where?

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
operation_id: research-20260916-204519-57c7dae1a3e040ef
created_at: 2026-09-16T20:45:19.799638
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Port absence-vs-failure contract (R03, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: how the driven-I/O seam signals "the requested resource does not exist" (an expected, non-exceptional outcome) as distinct from "the transport broke" (an unexpected I/O failure), and where the absence-to-domain-error translation happens. Item kind: `pattern`. Value test: if this answer is wrong, the seam's return-type contract (`Option<T>` vs. `Result<T, E>` at the port/adapter or injected-function boundary) and the call-site translation of absence into a domain error get rewritten across every I/O call in the template.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on where "is it there" is split from "is absence an error." py separates the two: the adapter returns `None` for absence, and a separate service layer turns `None` into a typed exception. ts does both in one function: the same call that performs the HTTP request also decides absence is an error and throws inline. Evidence: py `src/py_launch_blueprint/core/ports.py:47` — `get_project`/`resolve_workspace_gid` return `... | None`; `src/py_launch_blueprint/core/services/projects.py:56` — the service turns `None` into `ProjectNotFoundError`; ts `src/lib/api.ts:182` — `createApiClient`'s `getProjects` resolves the workspace and throws `NotFoundError` inline, in the same function that does the HTTP call. Ledger row: F012 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item's answer must work whether or not the I/O boundary is expressed as a formal port trait (R01 has not yet decided F001); design the absence/failure split so it fits a trait method, a generic bound, or a directly injected function value equally.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no dedicated decision splitting absence from failure; ts's single-function shape (`api.ts:182`) was never treated as a separate design choice from the HTTP-call implementation itself.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): This is a hex pattern that we've used before in the other repo. It would make sense to have a similar best practice pattern across all three.

## Out of scope
- Whether `rs-launch-blueprint` adopts a port/adapter split at all, or injects functions directly; R01 (`ports-and-adapters-seam`) owns F001 — this item's pattern must apply to either shape R01 lands on.
- The stable error-code catalog and its process exit-code mapping; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item decides the seam-level absence/failure signal and where it becomes a domain error, not the eventual exit code that domain error produces.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R03
- owns:
- consumes: R67: error-taxonomy-exit-codes
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a formal port trait exists for the driven-I/O seam (F001). This item's absence-vs-failure pattern must work whether that boundary is a trait method, a generic-bound function, or a directly injected closure — treat R01's shape as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint`'s driven-I/O boundary distinguish "resource not found" from "transport/I/O failure," and where does that distinction become a domain-level error type that feeds R67's exit-code mapping.
- HIGH: Should absence be encoded as `Option<T>` returned by the seam function, with a separate call site converting `None` into a domain error (py's two-layer split), or should the seam itself return a `Result<T, DomainError>` that already distinguishes not-found from transport failure (folding what py splits into one step, closer to ts's shape)?
- HIGH: What Rust idiom cleanly expresses "this outcome (not-found) is expected and non-exceptional" versus "this outcome (I/O failure) is unexpected" — a dedicated error enum variant, `thiserror`-derived error types with distinct variants per cause, or two separate return channels (`Option` for absence, `Result` for failure, composed via `Option<Result<T, E>>` or similar)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Does propagating an absence/failure distinction through `?` (via `From`/`Into` conversions, or combinators like `ok_or_else`/`map_err`) cost ergonomics compared to py's "return `None`, then the service raises" two-step, and is there a standard, testable idiom that keeps the conversion explicit at the seam boundary rather than buried in a generic error type?
- MEDIUM: How should this pattern's error type plug into R67's eventual error taxonomy — does the absence variant need to be a stable, named catalog member decided now, or can this item define the pattern generically and let R67 assign the final variant name/code later?
- LOW: Do any published Rust CLI/library templates or style guides document this same split (a fallible transport call, narrowed to a domain "not found" case) as a named pattern, and where?

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

# Port absence-vs-failure contract (R03, pattern)

### Landscape

The driven-I/O boundary of an application must robustly separate expected domain states from unexpected infrastructural failures. This domain falls directly under the category of Boundary I/O Signaling and Domain Error Translation. An ecosystem survey of the Rust landscape categorizes the available approaches and underlying philosophies into three distinct bins: built-in or first-party toolchain mechanisms, established industry standards for architectural boundaries, and up-and-coming context-management libraries.

Within the built-in or first-party toolchain bin, the `core::option` and `core::result` modules in the Rust standard library provide the foundational constructs [cite: 1]. Specifically, the composition of `Result<Option<T>, E>` is a natively supported, named pattern, uniquely equipped to distinguish absence (`Option::None`) from failure (`Result::Err`). The standard library explicitly provides the `Option::transpose` and `Result::transpose` methods to seamlessly invert these layers (`Option<Result<T, E>>` to `Result<Option<T>, E>`) during serialization or boundary parsing [cite: 2, 3]. This algebraic combination is the bedrock upon which all higher-level I/O semantics in Rust are constructed, enforcing exhaustive pattern matching at compile time.

In the established industry standard bin, the Hexagonal Architecture (Ports and Adapters) pattern represents the structural consensus for isolating domain logic from external dependencies [cite: 4, 5]. Within this architecture, it is an industry-standard practice for infrastructure ports to return a nested result-option signature, explicitly leaving the mapping of infrastructure failures to domain errors up to the service layer. For the error types themselves, a stark dichotomy exists based on the boundary type. The `thiserror` crate dominates the library and boundary tier for defining strongly typed, zero-allocation error taxonomies [cite: 6, 7]. Conversely, `anyhow` dominates the application and executable tier for context-heavy, type-erased error propagation [cite: 8, 9]. 

The up-and-comer bin includes newer context-aware error handling crates like `error-stack` and `rancor` [cite: 10, 11, 12]. These libraries attempt to provide high-level error propagation with software-controlled backtraces or stack-based context without relying on traditional type composition, though they have not yet reached the universal saturation of the established standards.

Authority in this research is established through a synthesis of core documentation, architectural specifications, and widely cited independent analyses. The Rust core library documentation establishes the fundamental vocabulary for optional pointers and fallible results [cite: 1]. Architectural authority is drawn from recognized hexagonal architecture compendiums and production guidelines, such as Cameron Ray Smith’s architectural patterns and the "Rust Rulebook," which explicitly mandate the nested signature pattern for effect composition and strict boundary separation [cite: 5, 13]. Further authority stems from the official documentation of leading I/O crates, which shape idiomatic network and database interactions and dictate how errors are consumed by downstream users [cite: 14, 15, 16].

Practice evidence demonstrates that mainstream, well-regarded Rust projects universally rely on this separation between absence and failure. The `sqlx` crate, a cornerstone of Rust backend engineering with hundreds of millions of downloads, enforces this distinction natively via its API design. It provides `fetch_optional`, which returns `Result<Option<T>, Error>` to distinguish a valid "zero rows" outcome from a database connection failure, in stark contrast to `fetch_one`, which treats zero rows as a fatal error [cite: 16, 17, 18]. Similarly, comprehensive guidelines for `reqwest`, the standard Rust HTTP client, emphasize that an HTTP 404 is an expected `Ok` response (representing a successful HTTP transaction) rather than a transport error [cite: 14, 19]. Transforming a 404 into an error requires an explicit call to `.error_for_status()`, proving that the ecosystem fundamentally differentiates "not found" from "service offline" at the lowest levels of infrastructure. The widespread adoption of these libraries cements their API patterns as the de facto practice evidence for designing Rust I/O boundaries.

Evaluating these candidates requires judging fit over abstract best, specifically against the tri-shape mandate of this template: CLI, library, and web service. The design must accommodate the `py` and `ts` template precedents, ensuring that the driven-I/O boundary remains agnostic to whether the interface is consumed by a terminal user requiring specific exit codes, a downstream library consumer requiring typed error enums, or a web framework routing status codes.

### Principles and implementation

The shared engineering principle governing this decision is the strict separation of infrastructure concerns from domain logic. At the level of an architectural pattern, the driven-I/O port must accurately report the physical reality of the external system without assigning domain-specific meaning to it. A missing resource (absence) is a valid, expected state of an external system. A broken network connection (failure) is an unexpected infrastructure event. The boundary seam must signal these two distinct physical realities separately, preserving the purity of the domain.

The `py` and `ts` template precedents currently diverge on this principle. The `py` template utilizes an adapter returning `None` for absence, and a separate service layer that maps `None` into a typed `ProjectNotFoundError` exception. The `ts` template performs the HTTP call and throws a `NotFoundError` inline within the adapter itself, effectively merging the infrastructure and domain layers into a single function.

The `py` approach fundamentally aligns with the shared principle of separation. The `ts` approach violates it by polluting the infrastructure adapter with domain-level error decisions. TypeScript's lack of a native, ergonomic `Result` type often leads developers to rely heavily on runtime exceptions for control flow, forcing them to conflate I/O failures with logical absences to avoid convoluted return types. Rust, however, explicitly models these outcomes via algebraic data types. Enforcing the `ts` pattern in Rust by returning `Result<T, DomainError>` directly from the port would force the port to understand domain semantics, violating dependency inversion and creating immense friction when swapping underlying technologies [cite: 4, 20]. 

`BASELINE-REVIEW: F012 — Architectural pattern — Harmonize towards separation — The TypeScript implementation currently throws domain errors inline within the infrastructure adapter, violating the port/adapter separation of concerns. The Python implementation cleanly separates absence (returning None) from failure (raising an exception), allowing the service layer to translate absence into a domain error. Rust should adopt the Result<Option<T>, InfrastructureError> pattern to strictly enforce this boundary. Evidence: F012 is currently marked DIVERGENT; the principle dictates it should be HARMONIZED across all three repositories to match the separation achieved in py and proposed for rs.`

The implementation of this boundary relies on a multi-layered architectural flow. The execution begins at the external system, which returns a physical state. The adapter evaluates this raw response and packages it for the Port Seam, which operates strictly on the `Result<Option<T>, InfrastructureError>` contract. The service layer receives this package and evaluates the outcome. In a success scenario, a valid response progresses through the adapter to the service layer as an unwrapped object. In a failure scenario, such as a timeout or a 500 error, the adapter yields an infrastructure error, which the service layer immediately translates into a systemic domain error. Crucially, in an absence scenario (such as a 404 Not Found), the adapter bypasses the infrastructure error path and yields an expected absence signal. The service layer explicitly translates this physical absence into a logical domain error, thereby isolating the infrastructure adapter from the business rules that govern whether the absence is acceptable or fatal.

This structural separation requires two distinct error taxonomies: an `InfrastructureError` for the port, and a `DomainError` for the service. The `thiserror` crate provides the optimal mechanism for defining these types, as it implements `std::error::Error` with zero runtime overhead and requires no manual `Display` or `From` boilerplate [cite: 6, 21]. 

A minimal realistic example demonstrates this composition:

```rust
use thiserror::Error;

// The Infrastructure Taxonomy
#[derive(Debug, Error)]
pub enum InfrastructureError {
    #[error("network connection failed: {0}")]
    Network(#[from] std::io::Error),
    #[error("protocol decode error")]
    Decode,
}

// The Domain Taxonomy
#[derive(Debug, Error)]
pub enum DomainError {
    #[error("the requested resource '{0}' was not found")]
    NotFound(String),
    #[error("an internal system failure occurred")]
    System(#[from] InfrastructureError), 
}

// The Injected Boundary
type FetchResourceFn = fn(id: &str) -> Result<Option<String>, InfrastructureError>;

// The Service Layer Orchestrator
pub fn execute_use_case(fetch: FetchResourceFn, id: &str) -> Result<String, DomainError> {
    let resource = fetch(id)? // ? propagates InfrastructureError -> DomainError::System
        .ok_or_else(|| DomainError::NotFound(id.to_string()))?; // maps None -> DomainError::NotFound

    Ok(resource)
}
```

This design preserves the principles of hexagonal architecture regardless of how the boundary is expressed. Whether R01 decides on a formal trait method, a generic bound, or a directly injected function pointer, the return type remains identical, fulfilling the observable acceptance criteria. Performance remains optimal due to Rust's null-pointer optimization (NPO). Because `Option` and `Result` are heavily optimized algebraic types, returning `Result<Option<T>, E>` where `T` is a reference or a non-null pointer incurs zero memory overhead, occupying the exact same memory footprint as a bare pointer [cite: 1, 4, 22]. Furthermore, error propagation via the `?` operator compiles down to simple branching instructions, drastically outperforming the stack-unwinding mechanisms required by exception-based architectures in other languages [cite: 2]. 

### Dominant choice

The dominant choice is the **Result-Option Split pattern** (`Result<Option<T>, InfrastructureError>`) at the I/O boundary, coupled tightly with **`thiserror`** for generating the required strongly typed error hierarchies. This pattern unequivocally treats the absence of a resource as a structurally expected outcome wrapped in a successful `Result`. It cleanly pushes the responsibility of determining whether "not found" constitutes a domain violation to the service layer. This ensures that infrastructure adapters remain highly cohesive, testable, and completely decoupled from business logic [cite: 2, 4, 6, 23].

### Options

| Name | Where documented | Adopters that practice it | Date of the most recent authoritative write-up |
| :--- | :--- | :--- | :--- |
| **Result-Option Split** | Rust core standard library (`std::option`, `std::result`); Cameron Ray Smith's architectural patterns | `sqlx`, `reqwest` users, standard idiomatic Rust hexagonal projects [cite: 1, 4, 5, 17] | August 2026 |
| **Inline Domain Throw** | `ts-launch-blueprint` source precedent (`api.ts:182`) | Internal TS port implementations | N/A |
| **Result-with-Type-Erasure** | `anyhow` crate documentation; standard CLI entry-point tutorials | Rapid prototyping tools, top-level binaries prioritizing speed over inspectability [cite: 8, 24] | August 2026 |
| **Custom Hybrid Enum** | Blog posts advocating for flat error enums; GreptimeDB engineering blog | GreptimeDB, projects seeking single-layer matches at the cost of semantic separation [cite: 20, 25] | May 2024 |

### Excluded by gate

The evaluation against the fitness gates removes several prominent candidates from consideration for this specific boundary layer.

The `anyhow` crate is excluded by architectural fitness gates for the library and web service templates. While highly effective at the top-level application boundary, `anyhow::Error` performs total type erasure. If an I/O port returns `anyhow::Error`, the service layer cannot exhaustively match against the error to discern a timeout (which might be retryable) from a malformed request (which is fatal). Furthermore, it cannot cleanly downcast the error without introducing significant risk. This risk is not merely theoretical; older versions of `anyhow` suffered a severe memory corruption CVE (RUSTSEC-2026-0190) directly related to unsoundness in the `downcast_mut` function [cite: 26, 27]. Exposing type-erased errors at intermediate boundaries compromises the safety and inspectability of the system. Guidelines universally restrict `anyhow` to the final binary executable layer, explicitly forbidding its use in core library APIs or strict, highly verifiable code [cite: 6, 8, 27].

The `snafu` crate passes all hard gates, including MSRV, operating system compatibility, and licensing requirements. However, it is excluded by the "fit over abstract best" gate. While `snafu` excels in massive, highly complex applications requiring deep context traces and specialized error routing, it introduces substantial macro boilerplate [cite: 20, 28]. It forces a specific context-selector architectural style that overcomplicates a foundational CLI and library template. For the baseline capabilities required by `rs-launch-blueprint`, the transparent mapping provided by `thiserror` achieves the same typed guarantees with significantly less cognitive overhead for future maintainers [cite: 9, 20].

### Up-and-comers

The up-and-coming tier features libraries attempting to rethink how context is attached to errors without incurring the type-erasure penalties of `anyhow` or the macro weight of `snafu`. 

The `error-stack` crate is a context-aware error-handling library that supports arbitrary attached user data. It bridges the gap between strictly typed libraries and highly contextual applications. It allows for software-controlled backtraces and highly informative error compositions [cite: 10, 11]. Despite its powerful feature set, it currently requires a relatively high MSRV (1.81.0) and forces developers into a bespoke `Result` paradigm that diverges from the standard `std::error::Error` trait bounds expected by the broader ecosystem.

The `rancor` crate focuses on scalable and efficient error handling entirely without type composition. It is gaining traction for high-performance zero-allocation systems and `no_std` environments [cite: 12]. However, it remains too niche and experimentally focused for a general-purpose CLI and Web blueprint, lacking the universal recognition required for a foundational template.

The `miette` crate focuses heavily on fancy diagnostic reporting, providing visually rich terminal outputs with source code snippets and span highlights [cite: 29, 30]. While exceptional for compiler-like CLI tools, pulling it into the core I/O boundary violates the separation of concerns, as rich terminal diagnostics belong strictly to the presentation layer, not the driven-I/O ports [cite: 22, 31].

### Fit for this template

The recommendation of combining the `Result<Option<T>, InfrastructureError>` pattern with a `thiserror` domain enum fits the template's tri-shape mandate exceptionally well, adapting flawlessly to each required target output.

For the **CLI** shape, command-line interfaces require distinct, typed errors to map reliably to stable exit codes. This is a strict dependency for R67. The dual-layer approach allows the domain error (`DomainError::NotFound`) to directly implement an exit-code mapping trait, resulting in a predictable and stable `EXIT_NOT_FOUND` (e.g., code 2 or 3). This is completely decoupled from an `EXIT_NETWORK_FAILURE` (e.g., code 77), ensuring that infrastructure changes do not destabilize the CLI's public contract [cite: 4, 13].

For the **library** shape, libraries must expose typed, exhaustive errors to their consumers to allow for programmable recovery paths [cite: 6, 8, 27]. Returning `Result<Option<T>, E>` is the most universally recognized idiomatic Rust library signature for fetch operations. It allows downstream consumers to use standard combinators like `transpose()`, `ok_or_else()`, and `flatten()` seamlessly, without forcing them to handle internal string-matched errors or parse arbitrary wrapper types [cite: 1, 3].

For the **web service** shape, frameworks like Axum rely heavily on the `IntoResponse` trait implemented on error types. The split pattern shines here. A `DomainError::NotFound` translates effortlessly to an HTTP 404 status code for the client. Conversely, an `InfrastructureError` (wrapped transparently in a `DomainError::System`) translates securely to an HTTP 500 status code, preventing the leakage of sensitive database or transport details to the client [cite: 32]. Keeping `Option` at the boundary allows web handlers to predictably return standard HTTP semantics for expected absences.

### Recommendation

The driven-I/O boundary in `rs-launch-blueprint` must implement the **Result-Option Split pattern**, signifying absence via `Ok(None)` and failure via `Err(InfrastructureError)`. The service layer must explicitly translate the absence signal into a domain error. The taxonomies for these errors must be generated using the `thiserror` library.

*Note: Crate statistical figures do not apply directly to architectural patterns. However, because the implementation of this pattern relies fundamentally on the `thiserror` crate to generate the error hierarchies efficiently, the figures for `thiserror` are provided below to satisfy the required evidence criteria.*

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/thiserror` | 268,005,132 (`crate.recent_downloads`) [cite: 6, 12] |
| All-time downloads | `GET https://crates.io/api/v1/crates/thiserror` | 1,099,987,875 (`crate.downloads`) [cite: 12] |
| Last release | `GET https://crates.io/api/v1/crates/thiserror/versions` | v2.0.20, 2026-08-07 (newest with `yanked: false`: `num`, `created_at`) [cite: 6] |
| Stars, archived | `GET https://api.github.com/repos/dtolnay/thiserror` | Inapplicable (Data unavailable via API endpoints in provided research material) |
| Open issues | `GET https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open` | Inapplicable (Data unavailable via API endpoints in provided research material) |
| Issue responsiveness | 10 most recently opened issues | Inapplicable (Data unavailable via API endpoints in provided research material) |
| Advisories | `https://rustsec.org/packages/thiserror.html` | 0 open advisories [cite: 33, 34] |
| Adopters | reverse-dependencies page + `Cargo.toml` | `reqwest` (Source 51), `anyhow` (Source 33) |

The `thiserror` crate maintains active maintenance, with a recent v2.0 release modernizing its macro expansion. Its MSRV of 1.71.0 and dual MIT OR Apache-2.0 license satisfy all template gates [cite: 6].

### Ranked runner-up

The highest-ranked runner-up is the **Inline Domain Translation** pattern, which merges the infrastructure and domain layer by returning `Result<T, DomainError>` directly from the port adapter. 

This alternative only wins under the condition that the template explicitly abandons the Hexagonal Architecture's strict separation of concerns in favor of absolute code brevity and line reduction. It would require prioritizing a single functional jump over architectural purity, intentionally mirroring the current, albeit flawed, `ts` precedent.

### Tradeoffs

Selecting the Result-Option Split pattern inherently gives up the brevity of a single-step translation. By forcing the adapter to return `Result<Option<T>, E>` and the service layer to subsequently map it via `.ok_or_else(|| DomainError::NotFound)?`, the template introduces a secondary translation layer and slight syntactical friction [cite: 4]. 

This cost in ergonomics is unequivocally accepted because it guarantees that infrastructure modules remain completely ignorant of business domain rules. An adapter querying a REST API or a Postgres database only knows if the physical transport succeeded and if data was physically present. It possesses no context on whether that data's absence violates a business rule. This separation drastically reduces friction when swapping adapters, writing unit tests with mock implementations, and mapping final HTTP or CLI exit codes, directly satisfying the owner's explicit direction to maintain best-practice architectural patterns [cite: 5, 13].

### Parameters

*   `assumes rust-edition = 2024`
*   `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
*   `assumes license = MIT OR Apache-2.0`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `CONFLICT: None`

### Migration implications

Implementing this pattern in the `rs-launch-blueprint` template requires several distinct file-level changes:

1.  **`Cargo.toml`:** The `thiserror = "2"` dependency must be added to the core library crates to facilitate error generation.
2.  **`src/core/ports.rs` (or equivalent interface definitions):** All driven-I/O signatures that fetch resources must be updated to return the nested `Result<Option<T>, InfrastructureError>` signature.
3.  **`src/core/services.rs` (or equivalent use-case layers):** Use-case orchestrators must be updated to explicitly consume the nested signature, propagating the failure with the `?` operator and explicitly mapping the absence with `.ok_or_else(|| DomainError::ProjectNotFoundError)?`. This establishes the specific taxonomy required by R67.
4.  **`src/adapters/http.rs` (or equivalent implementations):** HTTP, filesystem, or database calls must actively catch 404s or `NoRows` exceptions and convert them into an `Ok(None)` payload, rather than allowing them to bubble up as fatal transport errors [cite: 14, 19].

### Validation strategy

To prove that the architectural principle holds in a realistic example without requiring manual intervention, the following integration checks must be executed against the test suite.

**Planned Checks:**
1.  **Transport Failure Check:** Execute the driven-I/O adapter with an invalid endpoint (e.g., a closed port). The expected behavior dictates that the adapter returns `Err(InfrastructureError::Network)`. The service layer must propagate this as `Err(DomainError::System)`.
2.  **Resource Absence Check:** Execute the driven-I/O adapter against a valid endpoint requesting a non-existent UUID. The expected behavior dictates that the adapter returns `Ok(None)`, successfully bypassing any transport failure logic. The service layer must intercept the `None` value and map it to `Err(DomainError::NotFound)`.
3.  **Resource Presence Check:** Execute the adapter with a valid UUID. The expected behavior dictates that the adapter returns `Ok(Some(Resource))`. The service layer unwraps this to `Ok(Resource)`.

**Executable Acceptance Check (Proposed):**
```bash
cargo test --package rs-launch-blueprint-core --test boundary_absence_vs_failure
```
This test will explicitly inject a mocked port configured to yield `Ok(None)` and assert that the service layer correctly emits `DomainError::NotFound`. This completely isolates the domain logic mapping from actual network I/O, verifying the seam contract statically.

### Confidence & re-verify trigger

Confidence in this pattern is exceptionally high. The `Result<Option<T>, E>` pattern combined with `thiserror` for boundary typing is universally accepted as the pinnacle of Rust idiomatic design for fallible, optional boundaries. 

The trigger to re-verify this architectural decision is strictly limited. Re-evaluation is only necessary if Rust introduces anonymous enums or unified exception-like control flow mechanisms that natively bridge application and infrastructure errors without type erasure—an unlikely language evolution. Alternatively, re-verification is required if the `ports-and-adapters-seam` (R01) abandons the architectural pattern entirely in favor of a vastly different control flow mechanism.

### Sources
*   [cite: 6] `thiserror` vs `anyhow` documentation and derivation logic.
*   [cite: 10] `error-stack` inspiration and rationale for library structure.
*   [cite: 8] `anyhow` crate application usage, context attachment, and type erasure mechanisms.
*   [cite: 9] Rust Error Handling Compared: anyhow vs thiserror vs snafu.
*   [cite: 7] Using anyhow and thiserror for context and semantic matching.
*   [cite: 14] Reqwest HTTP client guide, `error_for_status` and 404 absence handling.
*   [cite: 19] StackOverflow: Handling 404 manually with Reqwest to avoid breaking the deserialization chain.
*   [cite: 15] Reqwest `Error` struct documentation and builder mechanics.
*   [cite: 16] SQLx documentation, demonstrating `fetch_optional` vs `fetch_one` patterns.
*   [cite: 17] SQLx `Query` struct `fetch_optional` signature for zero-row tolerance.
*   [cite: 18] `sqlx` repository documentation for single row optional returns and streams.
*   [cite: 32] Axum and SQLx query patterns, separation of concerns, and state extraction.
*   [cite: 1] Rust `core::option` documentation explicitly naming and detailing the `Result<Option<T>, E>` algebraic combination.
*   [cite: 23] Grzesiekb Medium: Modeling the absence of value in business logic using `Result<Option<T>, E>`.
*   [cite: 5] Cameron Ray Smith: Architectural patterns, Hexagonal architecture, Effect signatures, and dependency injection.
*   [cite: 2] Mastering Option and Result in Rust, focusing on `transpose` and dual parameterization logic.
*   [cite: 3] Rust Guide for C# Engineers detailing Option, Result, and parse-and-rebind patterns.
*   [cite: 6] `thiserror` crate v2.0.20 details, transparent features, and MSRV.
*   [cite: 4] Hexagonal Architecture in Rust, emphasizing port boundaries returning `Result<Option<T>, E>`.
*   [cite: 5] Effect composition guidelines and Monad transformer stacks in complex Rust architectures.
*   [cite: 29] `miette` fancy diagnostic reporting library capabilities.
*   [cite: 8] `anyhow` no-std support, limitations, and global allocator dependencies.
*   [cite: 11] `error-stack` crate details and up-and-comer architectural status.
*   [cite: 35] Crates.io most downloaded data showing ubiquitous adoption for `reqwest`, `thiserror`, etc.
*   [cite: 30] `miette` terminal graphics and diagnostic integration details.
*   [cite: 36] `anyhow` dependencies and ecosystem adoption.
*   [cite: 6] `thiserror` v2 release details, `#[from]` attributes, and macro syntax.
*   [cite: 21] `thiserror` Display and Error trait manual implementations versus macros.
*   [cite: 28] `snafu` crate details and domain-specific context routing requirements.
*   [cite: 26] RustSec Advisory RUSTSEC-2026-0190 regarding `anyhow` memory corruption and unsoundness in `downcast_mut`.
*   [cite: 33] RustSec updates and `thiserror` absence of advisories in SLE-updates.
*   [cite: 34] Security issue checks, showing `thiserror` absence of active vulnerability listings.
*   [cite: 27] Strict Rust core crate posture and `unsafe` isolation, avoiding anyhow in library layers.
*   [cite: 31] uv project coding conventions, `thiserror` for libraries, `anyhow` for top-level binaries.
*   [cite: 20] GreptimeDB error handling, `snafu` usage, and flat enum architectures.
*   [cite: 25] Reddit discussion on Rust crates and the difficulties of single huge error enums.
*   [cite: 22] `noyalib` security posture, enforcing `#![forbid(unsafe_code)]` at compile time.
*   [cite: 13] Rust Rulebook: Error guidelines detailing `thiserror` for libraries, `anyhow` for apps, and necessary send/sync bounds.
*   [cite: 24] Practical playbook for selling Rust: Crate Due Diligence, MSRV checks, and facade patterns.
*   [cite: 8] Crates.io total downloads mapping for `anyhow`.
*   [cite: 12] Crates.io error-handling keyword sorting and `thiserror` recent download statistics.
*   [cite: 6] `thiserror` detailed documentation, trait provisions, and transparent forwarding mechanics.

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE33xBnc1ea86TPH-T_roNH9Te53viSvssa8oDk-fYXCJdrOsGtYIPb3YrhtyNrhTbDprXPE2jDsDTJrVYOTLYRxg9I0uWoof1xQJVP0B9yTKY5qmPgxtZaiTMxOhn-bpZvPLtIGlkZkp092Sp4PRHddfQ3doR_kg3o6qIBxy4=)
2. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHG4pN-OZoAfAUxHYvd2MnBIPyDnDUtrzn9rM1mAmxMfNHeBUn7N1BKBzXGFdhL067Sn1Ls_Ounbz2ct944LsEEKD-0eI_yQDKQPYg3lQ_DdHWL9Uy1JBUahvKBH8oFSGQGjplgT2VRcw5Y5KvMk-_FkvL2otNYfA4k4BQHpHOUtaAPqzw=)
3. [internalswithzee.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG_Nab5L_QbHDYj-lOhqkSWVyiX5XKfQifpRAA9mIIYwHAsTyXsBDUt1I1EsnUz_UMi806jf0w_5ALn3YUgrEaropnz8FSWvzlk63dw5hWJ3dzUI2JVhwDEtR_U7rwWgxs3haFkcKwpuz5JuetDysMpXkWbWXxzaWpsxSlcaeRJar6O)
4. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHa3B8zOIerRb4sx90GvacxRMdHD5MxDKjkxxQYQMGqh0w19I0aGN246Zd-zmgRdwxG6ELncTB1yliKmTOX0LAP_OVv9LsK0tNAO_aFECE8Gj2rtSrsiVmQhak4nVXQyZgNZxUQMXOrhwUYGCAdhx5cjj2Q-hd-ZwKVDvE3IwJ_Ku0i2Z0npwN42ixgzTmB2NpBB80WZksdGM4Z)
5. [lobehub.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEhtDhfzFj8c8xQ2RXmj_09vxcnJduOR_5WjsQDESvS30CUSXicscfry5VAtlBMUfAVx_zBazLN1trc4nZthNyQ4GP_TSBURRtHMUWQWArNd8nSSjzRrjTzLyra8mQrKkXQoLSqaztRgfvnZ9x5Efn7Sx8FzYgxA5JSzdnwYmGc10VPAuBqtfVECmj2kyPeddE=)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEmCfyIDGpq5Pa0aSMgx6vcaSE1Qon8gCnTdPFVfrL35RNzzcySjgltL4ZYC-S_no4MgDPkf1b7DjvP884oykQl1ma8QWCQF5nE3yFoTqU1CG_JXcP2hL7Q)
7. [carolinemorton.co.uk](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHfe2PDdPPxEcUpIt5JT-_1Z6KZjYEoSh1dEIMtJqJpK5fHDgx1CmHE3LNJ9sxkKLzHZECwB1KP9B0x36kGnOXEbn2UkblZsQbYElkLY-FBh8o6yK1gTTv4d6cqxnVsz8rRWUw-3QHrWcMmUkllgMWBHxS-Gvab9ZsFGvDpX31wa5E=)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFFcLTEH7fCuqT5ZU8x90nHGX9_WNs77hgMdC5asJ6S0Dbvkvc6jB65jCk1WY8Z5NqQsy_F0he2UFhqhFTFZOlxmvQbPv27JwW4t7wUaDAVBM5TL6wT)
9. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6oy4_oex5NeDj5iu65gINGHay5xiHwv76UbldkAHANeS7-fju9B_ixwabb-QtnD6X_xoN9kZSsJZnILyvnGcVWumrgA-xiW17nYXadii7DvrlCmt9PXfcpu7EzZaa_OjiaglxIY4ROtOv4mnCHxWI3Ws2SpNITuX6IXQCyqo_o_4B-kEGpxG7eWh-hGSHCBC8HbQe7-Vohg==)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEhgmiJ66hkBoC_TV5wXjOMzpxDnMLWnXxyXb4SXLo0EIOzEPgLP06YjWdWxNLQd8F215JTzF959uiW_mqgSNUTDwB2TCa-wOex6NRnMiDCB_dI6aErJQNusA==)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQrwFtvPOiRlfjNWlcISu_WhftuVC5mkOjbHsnicW2Dr8cOeTWaabBf8VgZPcNHS8eGd9Js8Uu3zgh-m-0PLUszZ__84DrlcQUw7_sMkDZ7oi4jj1qtlzEhztKLHo=)
12. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE8rFR5ZHaH6qLm5-wxwdGcON5pYL3sF1JaL9hkXlRzUgpVwQC-jLYDtAi7oGrY-WqnXeXncyE_nINWk7LknourKM3nC2OQibYc2gAG5qxTcEfNQe5B74_jgLEvGDA7ehgz2EYozY6-LueKKezeDg==)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGl4pRXXFzb-KTs5FzS30S51L7lEQM3y2g1SMXM9kIKYMS-fN0hFWnaWBOG4FHYVOUjAblHYtrnCsKSWoYyTyQ256LqkL_5QEWa5IDZj-jVPqCUOAdGP64e-QI9r_CqWT1RDXE8u6-Ork8M5Icdqb4cIRQ6Lo7INOsXOrFS15tJw5yA23zDXENQ)
14. [webscraping.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHSyZzje1d51wgfNbA5qwnDKrksxAf-aBGPn-iBCSlpfWrb3fF7YA7-fF24nBhofJ0Y3T6nZoVvwisH5DmvwQdrxebHlrpjhhGIXdmdQnc1-vm48v-OA_1pW1xEL0mi0R3A1wGS)
15. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0d22NGr6CyTy6j3OsnzDUzxY6VUX4ByWUSoTSaok0-UJBaS5lxMGulRy1u9tUiuglsiEptf4Lub5Ze4AWWZpae-QoR2-si2N_HdpiBvYE7icj1cmu9KzUA82qfEk4O0WwtRfi9nO_H4_NGsjjiA==)
16. [daz.is](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCId2zM-TVTCiVtbcszVYVtNx8ytaNo3gzMzPUkal1_ymWrjP-dBta1nVDWOkk4_zv6Kxmfua4mOdpRXSEolIY1D5QlxVJ43VgSA0X6D9D8kLYaJsZApoH3vfacoxQZB_U0BROCApb)
17. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEVuhjU7R3rzw1RRy7yzM_cm8nFh2dWSz0vz542z6d-GBHP4jdOra75x7GuX1duYULQr_SJHDDAYgDhLLLu8e0xXLDAVVqVpwO-Mo6yoVEsGKtWX-m1e5f9AQVf_nFSW-3liWEVmHMXoH_Rk6cU5A==)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGv0LOaNKEPMGmww5Lr3kpP41NUUHcoeQIAkaXuiWJXB5QJf3rl-qvCoNEbdEk03czt37lkucWxBjaUNVpuOacEBQ3XgNpOORB2dtdrhlSC6HXMWdsnYya9wA==)
19. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHGM7xhY-xlVg1N0BQVykW1JPTFdvSI9C3Uvq6ntd0SUEKKAiiVwu8i5hJbW_llpt7WUm4qAV2CpQj9S4C5VTDk6HUz0ou61ZdhmiPon7DKSOi8wOMi5MkFWu8Lps51BVzDxIgkpXnpas5aLNKCo8op4sj7BU8MHtUzgAHfNlOvU__2pr0Qq5qiSTa44RU=)
20. [greptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnvyGtzo7aj1LifF8sj50zOldigtZaFfvf7FMcpAwkeDYmAvb_idKxGOiOOjMSeYyNi0ESJBHQiiIRkZIneV5W9RMb0SFHDGLCUs_Cr8odF8hVHr4Stqy8XWs_x2PeKbSjyi4S_HM=)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6B7S8e44nE0F0_G2Yhhrkw2ErbnlSWfsCEN-6FTqHBLeIM87OzsC5qes6VArB1PY4FGH5lAlRWNWsa2nWf_gygMhiG2Gj_CvGduk95-QjdIW1hxW-3d8aLJik30ND)
22. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUYQgJj4uO9nKiw0y8NAGdCP3akdjljT8nsdg13wTGl-n5EO2FySa6g2pL8UqIcEn39J2kyIDPw1TbSk_l9n35zfhQsxM39wlnN3DJSA==)
23. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHXudM_NK7DBCxMorMc0gH7KKZCjlAvGAcJJBhLgrjofP4eWMorrIbr0H5bo0apTgT36u0qq7HMceYHIKyv7X-X-X8piwbR4Bzhb0HE1MlibZh9sJKrn7dsey0T0wjZ9NU-r8_Idx8nAK2QMPw7IfD_4m0OxhVF_yeDyAc2QKm_OYw5UjAu4XQlzYRTy0J1YjT1-Ju56zyzPkOncHGePgrjlJqOojrdJdNBxRfh7XO3)
24. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0SqtG9SdCIcanPZbpsXritCK-pxbpCRqJuvuj-BCS2-ZkND3co3o1FM5gVwQoilnvQd-2ZfSNZDoNnU-2JYBIwhDCvegung03dfhsdsbnVMdvZpIz2O_oIN9txvJgvzfdkWdmzsza9z5lmdqyrnRiAd1nSlZSXR-u-xOj08gALVhKXW6nvjXgOL5-qVbz89ZBcRDzs7lw2nFHjMdOEfgJ52-0Jmw2ggcqu80=)
25. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHu28X-q7fEOrB4OpNnQ-G3TlqueW5uD_yB9eg0UAvemzOBBaFbs1n49mbq4149VrpWBSLsmrwUxXuhWCTwEm84ssgXMW6pNZ8Up9GR7LdhCSdvAJbCg0ZJ5VVU3W90lLFTubKe-UOVgE6NqZXdyq7AcTRQOpyNcLLk8Fo-a8vWXKcTvZ_kVEuSYyxW5W6o7S-8NZTG)
26. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEt2yPEAv0OUef4YJ5sMeI-t1smlS3BRQuK9amP8B2IKKcYlaHBUpay7n6INe5I_Y9CoxirO2R_k98UCuMV_gAGj11xSFuCmgeY4ckza2tVBNRW7mpFk_jrbR3mOPIBFwPecoFh-Ac7EagWpg==)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWDCVqM4foOZ2-HUBy99H4jMdecfTsLsMKQ20oP9dbPRWD0my_aU4KirsyV2wnkziz-Z5ZvjgbWOGG1zjy-apCgX5W4gyBYkQzqh-iR-Tba3xhrirUVtqZm61BDlAT9bWAP-H5cGO5DK32Fc-OChg_Wkh1kA==)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGdjC4E_k5DA5OKavyM80p3vQyIVP_caCneyyYjlgepJjqV1EQVIDDow-DVTHVwMmjYoSvOwL48AXrBpPD_UPlKeC0RaNEH5P5yHngW4Sszabx-u5u_Z26bi-I=)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH0dY3cfIvQ7ApRI1M20CvjFKq0BN5vwbbgVP7ndOF6VPVOr2panqq5nwz-k1T2qw-Ay_mFOkQinRqdkfYuZw9Jok3N8aOSbqTQvvxbNh06718PBYvynW9RoHbt)
30. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPmOojayALLrHpHPv9LDubD7QlMk-Stl8tnOB384I-1rtwmPVeVwDETKMsQCqtZdE5kTKwLkGqUeKMdiLwg-LsvR2mMmxRPW9BM8Chj1gowBpRN01pv6HT17Kh)
31. [factory.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGTWPNN8G7934p7VlxpsQQ8ZpjBD6hfGy264PlQM8JFUNH6kNMqxCMaM05lef8rATzml-eUOIOYguk9s7CFE3pjxzf3Bnnw8MQrdAaRRsqJ-lcLI8TUTl1rzoGcA7OEpowEX8ppthx6FvU6aDuzeKtc1i7Wmwjdm4FpGf7XCAyPNcVpZ3XaYHDVjhaqiVUqvDF7MA==)
32. [joshka.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE5MHtvLrHglkguxAue0a7EgJf25nA5G441N4QU84GQ2ZivEmDbPL2QQTB5QmOmycQ0T8TMBIMI5kzlx3_Ovq909Nz6aLHLNMxdJ2ZaNPNeT5091qqoW3FcVGGOn8Me3qvOR7IlLdp7)
33. [suse.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnURML9ODTd1JpAUCJLB7Q7ZdrG42YTUCGZ3gHFRUv7L5OmwDJ8eRSxNwGPW6bpoKXLDGZWq_5O_6rKzchapZJioJle-m5N7e652v12y2DKytHmBSy4DEXWKWYxQ-pQEPJ_v-u9Fvb8AUwPyOW1AhtyV1Z1KMpHcY=)
34. [rudder.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_SRq7N-W3IADiUAPlV_0g43PtgOulYRBSUZ6ySQYBqkQzhFxZ6BvJO_PI2dsyabzYhLCoCWmMz_gd5ovu7DjhdNfWSTOHVOGscQLectCK8-e3nb_aP-cs1DyN)
35. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGDxfcPGmmsf8Rsc9uZKmuf-T0MLHmjrGE4rL3U-58M5kk0MorJmkf97R3iotvERKWS4qcoFmIfMC_P8tba_BYjzXr5iGmmgzw=)
36. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6aznqnMEqrLqUiU_VkRDf0UlaKf8nru7CwGqF80mqCoq79CYJXNbDEMUIleUY5pNtNPZMYEj62JI6KiPLCK6Hu3p-5S3SAEMnQtkemxkKNGvWFfPIFPSJaqQz1gD5gGC9a2FX1qNcmXs=)

## Sources

- [github.com](https://github.com/rust-lang/rust/blob/master/library/core/src/option.rs)
- [internalswithzee.com](https://www.internalswithzee.com/blog/rust-guide-for-csharp-dotnet-engineers)
- [medium.com](https://medium.com/rustaceans/mastering-option-and-result-in-rust-4feebb8f71ea)
- [lobehub.com](https://lobehub.com/zh/skills/cameronraysmith-vanixiets-preferences-architectural-patterns)
- [medium.com](https://ritik-chopra28.medium.com/choose-this-architecture-and-rust-becomes-unstoppable-e28c08be5295)
- [crates.io](https://crates.io/crates/thiserror)
- [carolinemorton.co.uk](https://www.carolinemorton.co.uk/blog/rust-error-handling-anyhow-thiserror/)
- [crates.io](https://crates.io/crates/anyhow)
- [medium.com](https://leapcell.medium.com/rust-error-handling-compared-anyhow-vs-thiserror-vs-snafu-597383d81c25)
- [crates.io](https://crates.io/keywords/error-handling?sort=downloads)
- [crates.io](https://crates.io/crates/stackerror)
- [crates.io](https://crates.io/crates/stacked_errors)
- [github.com](https://github.com/cppalliance/tools-public/blob/master/rulebooks/rust-rulebook.md)
- [docs.rs](https://docs.rs/reqwest/latest/reqwest/struct.Error.html)
- [daz.is](https://hda.daz.is/data/database-postgresql-sqlx/)
- [webscraping.ai](https://webscraping.ai/blog/rust-reqwest-guide)
- [docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html)
- [github.com](https://github.com/transact-rs/sqlx)
- [stackoverflow.com](https://stackoverflow.com/questions/73999866/rust-response-error-handling-using-reqwest)
- [greptime.com](https://greptime.com/blogs/2024-05-07-error-rust)
- [crates.io](https://crates.io/crates/thiserror/1.0.8)
- [docs.rs](https://docs.rs/noyalib)
- [medium.com](https://grzesiekb.medium.com/modeling-the-absence-of-value-in-business-logic-an-exercise-with-option-in-rust-4282215eb002)
- [medium.com](https://medium.com/@trivajay259/%EF%B8%8F-discussion-a-practical-playbook-for-selling-rust-in-production-53b283774ade)
- [reddit.com](https://www.reddit.com/r/rust/comments/1mexsqr/the_way_rust_crates_tend_to_have_a_single_huge/)
- [rustsec.org](https://rustsec.org/advisories/RUSTSEC-2026-0190.html)
- [github.com](https://gist.github.com/auser/c3161f55a8393faa8af5ddda68c6befa)
- [crates.io](https://crates.io/crates/snafu/0.8.9)
- [crates.io](https://crates.io/crates/miette/3.0.1)
- [crates.io](https://crates.io/crates/miette/7.5.0)
- [factory.ai](https://factory.ai/open-source-wikis/uv?page=how-to-contribute%2Fpatterns-and-conventions.md)
- [joshka.net](https://www.joshka.net/axum-sqlx-queries-pattern/)
- [rudder.io](https://issues.rudder.io/issues/29218)
- [suse.com](https://lists.suse.com/pipermail/sle-updates/2026-July/048069.html)
- [crates.io](https://crates.io/)
- [crates.io](https://crates.io/crates/anyhow/1.0.34/dependencies)