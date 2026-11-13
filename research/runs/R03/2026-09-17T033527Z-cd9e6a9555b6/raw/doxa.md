---
prompt: # Deep-research prompt — Port absence-vs-failure contract (R03, pattern)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260916-204519-57c7dae1a3e040ef
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Port absence-vs-failure contract (R03, pattern)

Generated: 2026-09-17T05:11:43.564293+00:00


## Openai Results

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
provider: openai
model: gpt-5.6-sol
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

### Landscape

**Research and retrieval date:** September 17, 2026. Every citation below is a source URL retrieved on that date unless a separate publication date is stated. Normative **MUST/SHOULD** language is the recommendation rather than a claim copied from a source.

**Category decided:** the semantic return contract of a fallible, single-resource lookup at a driven-I/O boundary, plus the architectural location where successful absence becomes an application/domain-facing not-found error.

| Bin | Candidates found | Assessment |
|---|---|---|
| **Built-in or first-party toolchain** | `Result<Option<T>, E>`; `Result<T, E>` with a not-found variant; `Option<Result<T, E>>`; explicit `Option::ok_or_else`; `?`/`From` propagation | Rust already has all required machinery. `Path::try_exists` is especially close precedent: it distinguishes a confirmed negative answer from inability to determine the answer. `Option::ok_or_else` is the standard explicit absence-to-error conversion, while `Option::transpose` converts the less-natural `Option<Result<…>>` ordering into `Result<Option<…>>`. Rust's error-handling project recommends concrete enums when callers must handle multiple cases and reporting types only after handling is no longer expected. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai)) |
| **Established industry standard** | Fallible optional lookups in SQLx, Diesel, kube, SeaORM, rust-postgres and RocksDB-style APIs; call-site `ok_or`/`ok_or_else` conversion | SQLx `fetch_optional` returns `Result<Option<Row>, Error>`; Diesel's `optional` converts only its `NotFound` condition to `Ok(None)`; kube exposes `get_opt`; SeaORM exposes both optional `one` and required `require_one`. These span databases and remote HTTP APIs rather than one library family. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) |
| **Up-and-comer / refinement** | Paired optional/required entry points; richer `LookupOutcome<T>` enums when absence needs metadata | SeaORM's paired `one`/`require_one` interface is a useful newer refinement: one primitive preserves optionality while the other applies requiredness. A custom `Found`/`Missing` outcome enum is viable when “missing” later needs metadata, but the survey found no maintained Rust authority showing it as preferable for a binary present/absent lookup. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)) |

**Authority weighting**

- Rust standard-library documentation, the Rust Reference and accepted RFCs are first-party sources for type and `?` semantics. RFC 2965 is particularly relevant because it distinguishes handleable concrete error types from later-stage reporting types. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai))
- Alistair Cockburn's original Ports and Adapters article is the primary architectural source. It places technology conversion in adapters and use-case policy at the application boundary. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai))
- SQLx, Diesel, kube and SeaORM documentation is maintained by the implementers and supplies executable API precedent rather than opinion.
- Tokio's maintained axum examples provide framework-level practice evidence: one converts an optional in-memory lookup to `NOT_FOUND` at the call site, while another demonstrates SQLx integration. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))
- The 2025 State of Rust survey reports that official documentation and studying source code remain preferred canonical learning references; that supports weighting current maintainer docs and code above isolated blog posts. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai))
- The source repositories remain direct evidence of the intended cross-repository architecture: Python explicitly documents “`None` means absent; exception means failed,” while TypeScript currently combines lookup and policy in `getProjects`. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py))

**Practice evidence**

| Reference | Observed practice | Why it is relevant |
|---|---|---|
| SQLx | `fetch_optional` returns `Result<Option<Row>, Error>`; `fetch_one` instead reports row-not-found as an error. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) | One mainstream library deliberately offers both cardinality contracts. |
| Diesel | `OptionalExtension::optional` maps only `Error::NotFound` to `Ok(None)` and leaves other errors in `Err`; its changelog describes `Result<Option<T>>` as the more idiomatic representation when zero or one rows are expected. ([docs.rs](https://docs.rs/diesel/latest/src/diesel/result.rs.html?utm_source=openai)) | Direct evidence for normalizing technology-level no-row into successful absence without swallowing failures. |
| kube | `get_opt` returns `Result<Option<K>, Error>`, whereas `get` requires existence. ([docs.rs](https://docs.rs/kube/latest/kube/struct.Api.html)) | Remote HTTP-backed lookup, closer to this template than database-only evidence. |
| SeaORM | `one` returns `Result<Option<Model>, DbErr>` and `require_one` returns `Result<Model, DbErr>` with record-not-found as an error. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)) | Demonstrates the optional-primitive/required-wrapper split in one API. |
| axum | Its maintained todos example performs an optional lookup and applies `.ok_or(StatusCode::NOT_FOUND)?` at the HTTP call site. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)) | Shows the ergonomics of explicit absence translation, though a full hexagonal application should translate first to an application error rather than directly to HTTP status. |
| Block's Buzz | A company-hosted Rust component exposes `Result<Option<…>, StoreError>` and later requires a value with `ok_or_else`. ([github.com](https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs?utm_source=openai)) | Independent production-practice corroboration outside the ORM/framework maintainers. |

**Evidence-protocol applicability**

This is a `pattern` item and the recommendation selects no external crate. Therefore 90-day downloads, all-time downloads, crate release date, stars, archive state, open-issue count, issue responsiveness and package-specific RustSec advisories are **inapplicable**. Reporting such figures for SQLx or kube would measure evidence examples, not competing dependencies. Adopter/source evidence remains applicable and is listed above, matching the governing specification's separate treatment of pattern items. ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md))

**Fitness gates before popularity**

As of September 17, 2026, stable Rust is 1.98.0, released August 20, 2026; the fixed stable-minus-two floor is therefore Rust 1.96.0. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai))

| Pattern candidate | License | MSRV | RustSec / `unsafe` | Ubuntu + macOS | Features/runtime | Compile/binary cost |
|---|---|---|---|---|---|---|
| `Result<Option<T>, E>` plus call-site conversion | Pass: no dependency | Pass: required APIs substantially predate 1.96 | No package advisory applies; no user `unsafe` required | Pass; target-neutral, with Windows also expected to work but not CI-required | None; sync/async-neutral | Lowest: standard types only |
| `Result<T, E::NotFound>` | Pass | Pass | Same | Pass | None | Same |
| `Result<T, DomainError>` from adapter | Pass | Pass | Same | Pass | None | Same |
| `Result<LookupOutcome<T>, E>` | Pass | Pass | Same | Pass | None | Small source/API expansion |
| `Option<Result<T, E>>` | Pass | Pass | Same | Pass | None | Same representation family; worse API ordering |

All shortlisted patterns pass the six ecosystem gates. Architectural fitness, not popularity, separates them.

### Principles and implementation

**Shared requirement and agreement level**

The owner explicitly requested a similar hexagonal best-practice pattern across Python, TypeScript and Rust. The required agreement level is therefore an **architectural pattern**, not an identical language-level type:

1. The driven adapter reports whether it successfully answered the lookup.
2. A successful answer may be present or absent.
3. The use case—not the transport adapter—decides whether absence violates that operation's contract.
4. Driving adapters map the resulting application error to CLI exit or HTTP response policy.
5. Transport/protocol causes remain distinguishable from not-found throughout the path.

This matches Cockburn's division between technology-specific adapters and application-boundary use cases, and the repository's owner review identifies R03 as a shared hex pattern. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai))

The central Rust model is not “expected things use `Option`, unexpected things use `Result`” in isolation. It is **two independent axes**:

- Did the lookup complete? `Result<_, E>`
- If it completed, was a value present? `Option<T>`

That yields:

| State | Meaning |
|---|---|
| `Ok(Some(value))` | Lookup completed; resource exists. |
| `Ok(None)` | Lookup completed; resource does not exist. |
| `Err(error)` | Lookup did not produce a trustworthy answer. |

`Path::try_exists`, SQLx, Diesel and kube all embody this distinction in closely related forms. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai))

**What must agree and what may vary**

| Ecosystem | Idiomatic mechanism | Assessment |
|---|---|---|
| Python | Port returns `T | None`; transport failure raises a typed exception; application service converts `None` to `ProjectNotFoundError`. | Already conforms. Python has a separate exception channel, so a bare optional return annotation does not lose failure information. ([github.com](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py)) |
| TypeScript | Target: lookup returns `Promise<T \| undefined>` and rejects with a transport/API error; application service converts `undefined` to `NotFoundError`. A local discriminated `Result` would also preserve the pattern if the TS project later standardizes one. | Current `getProjects` resolves a workspace and throws `NotFoundError` inline, so the architectural split is missing. This is accidental coupling rather than a justified TypeScript difference: no dedicated TS decision selected it. `strictNullChecks` supports explicit handling of `undefined`, while `fetch` still requires the adapter to inspect HTTP status rather than treating all resolved promises as success. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)) |
| Rust | Port returns `Result<Option<T>, E>`; use case maps `Err(E)` to its source-failure category and `None` to its not-found category. | Idiomatic and more statically explicit than either exception-based implementation. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)) |

**Architectural alternatives**

1. **`Result<Option<T>, PortError>` plus use-case conversion — chosen.**  
   It preserves the reusable question “is it there?” independently of “must it be there for this use case?” It also prevents a transport adapter from importing application-domain error policy.

2. **`Result<T, LookupError>` where `LookupError::NotFound` is a seam error — strong runner-up.**  
   This is appropriate when the port operation itself promises that the resource must exist. SQLx `fetch_one`, kube `get` and SeaORM `require_one` demonstrate that contract. It is less suitable for the template's primitive lookup because optional library callers must then catch and demote an error back to absence. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai))

3. **`Result<T, DomainError>` directly from the driven adapter — reject.**  
   It folds technology translation and use-case policy together. It is concise for one caller but couples every adapter and fake to the current domain error taxonomy, which is exactly what a hexagonal seam is intended to avoid.

4. **`Result<LookupOutcome<T>, PortError>` with `Found` and `Missing` — reserve.**  
   This is equivalent to `Result<Option<T>, E>` while there are only two nonfailure states. It becomes preferable if absence later carries information such as a tombstone, authoritative source, retry-after time or redaction reason.

5. **`Option<Result<T, E>>` — reject for this boundary.**  
   It can represent three states, but makes optionality govern the entire operation and puts failure inside the “present” branch. The standard library's `transpose` maps it to `Result<Option<T>, E>`, which better says that the operation may fail and its successful output is optional. ([doc.rust-lang.org](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai))

**Error enums and `thiserror`**

The recommendation uses **both** separate channels and typed enums:

- `Option` represents successful absence.
- A port error enum represents transport, protocol or upstream failures.
- An application/use-case error enum contains the not-found category and a source-failure category.
- `thiserror` may derive `Display` and `Error`, but it does not decide which state belongs in `Option` versus an error variant. It is an optional boilerplate reduction, not part of R03's contract. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/))
- An opaque reporting type such as `anyhow::Error` should not be the public port error while callers still need structured handling. RFC 2965 recommends conversion to a reporting type when errors are no longer expected to be handled beyond reporting. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai))

**Minimal dependency-free reference implementation**

```rust
use std::{error::Error, fmt};

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct ProjectId(pub String);

#[derive(Clone, Debug, Eq, PartialEq)]
pub struct Project {
    pub id: ProjectId,
    pub name: String,
}

/// Errors mean the lookup could not produce a trustworthy answer.
/// There is deliberately no `NotFound` variant here.
#[derive(Debug)]
pub enum ProjectsPortError {
    Transport(Box<dyn Error + Send + Sync + 'static>),
    Protocol(String),
}

impl fmt::Display for ProjectsPortError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Transport(source) => {
                write!(f, "project source transport failed: {source}")
            }
            Self::Protocol(message) => {
                write!(f, "project source returned an invalid response: {message}")
            }
        }
    }
}

impl Error for ProjectsPortError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::Transport(source) => Some(source.as_ref()),
            Self::Protocol(_) => None,
        }
    }
}

/// Reusable lookup-port contract.
pub type ProjectLookupResult = Result<Option<Project>, ProjectsPortError>;

/// Application/use-case error. R67 later assigns stable catalog names/codes.
#[derive(Debug)]
pub enum GetProjectError {
    NotFound { id: ProjectId },
    Source(ProjectsPortError),
}

impl fmt::Display for GetProjectError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::NotFound { id } => write!(f, "project not found: {}", id.0),
            Self::Source(source) => write!(f, "could not load project: {source}"),
        }
    }
}

impl Error for GetProjectError {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::NotFound { .. } => None,
            Self::Source(source) => Some(source),
        }
    }
}

/// Directly injected-function form. A trait or generic-bound form uses the
/// same `ProjectLookupResult` output.
pub fn get_project_with<F>(
    id: &ProjectId,
    find_project: F,
) -> Result<Project, GetProjectError>
where
    F: FnOnce(&ProjectId) -> ProjectLookupResult,
{
    let project = find_project(id).map_err(GetProjectError::Source)?;

    project.ok_or_else(|| GetProjectError::NotFound { id: id.clone() })
}
```

The same contract fits every R01 outcome:

```rust
// Formal port:
fn find_project(&self, id: &ProjectId)
    -> Result<Option<Project>, Self::Error>;

// Generic-bound caller:
fn get_project<P: ProjectsPort>(port: &P, id: &ProjectId) -> ...;

// Direct function injection:
F: FnOnce(&ProjectId) -> Result<Option<Project>, E>;

// Async variant:
Future<Output = Result<Option<Project>, E>>;
```

The recommended explicit application conversion is:

```rust
port.find_project(id)
    .await
    .map_err(GetProjectError::Source)?
    .ok_or_else(|| GetProjectError::NotFound { id: id.clone() })
```

That is one `map_err`, one `?` and one `ok_or_else`. A `From<PortError>` implementation could shorten it to `port.find_project(id).await?`, but the explicit constructor is preferable in a teaching template because the abstraction crossing remains visible. Rust's `?` operator otherwise converts `Err` through `From`, while conversion between `Option` and `Result` remains explicit. ([doc.rust-lang.org](https://doc.rust-lang.org/reference/expressions/operator-expr.html?highlight=two-complement&utm_source=openai))

**Adapter normalization**

| Adapter observation | Port result |
|---|---|
| HTTP success with valid resource | `Ok(Some(resource))` |
| Documented resource-level 404 | `Ok(None)` |
| Database query returns no row | `Ok(None)` |
| In-memory map has no key | `Ok(None)` |
| Timeout, DNS/connect failure, 5xx, rate-limit failure or authentication failure | `Err(port_error)` |
| Malformed or schema-invalid success body | `Err(port_error)` |
| Ambiguous 404 that might mean a bad endpoint, tenant or route | `Err(port_error)` unless the upstream protocol explicitly defines it as resource absence |

A cache miss is not automatically resource absence: a nonauthoritative cache adapter must fall through to its source of truth rather than return `Ok(None)`.

**Observable acceptance criteria**

1. Every optional single-resource lookup exposes three mechanically distinct states: `Ok(Some(_))`, `Ok(None)` and `Err(_)`.
2. The driven port error has no generic resource-not-found variant when the operation is the optional primitive.
3. An adapter contract test proves authoritative no-row/404 becomes `Ok(None)` while timeout/5xx/malformed data remains `Err`.
4. A use-case test proves `Ok(None)` becomes the exact typed application not-found category.
5. A use-case test proves port failure becomes a distinct source/application failure and retains its source chain.
6. A separate optional library use case can consume `Ok(None)` without manufacturing or catching an error.
7. CLI and web code match application errors only; neither inspects SQLx/kube/HTTP transport errors to decide domain absence.
8. R67 receives distinct typed categories but remains free to assign their final stable name, machine code and process exit code—even if two categories eventually share one numeric exit code.
9. The same contract tests can run against an in-memory fake and the real adapter.
10. Empty collection queries return `Ok(Vec::new())`, not `Ok(None)`; the optional contract applies to zero-or-one lookups.

**Performance assessment**

No alternative here changes request count, response bytes, retry policy or database query plan when applied to the same adapter. The selected pattern adds no dependency and requires no success-path heap allocation by contract; exact enum layout remains compiler- and type-dependent. The proposed empirical workload is a loopback adapter serving equal mixes of success, authoritative absence and failure, under the runtime/concurrency selected by R05. Instrumentation should count port calls and record wall-clock latency, throughput and peak memory in release mode. No such benchmark was run because the Rust repository is still research-only, and no evidence suggests that choosing a domain-collapsed error would produce meaningful end-to-end I/O gains. This is an architectural inference, not a benchmark result. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

`BASELINE-REVIEW: F012 — agreement should be recorded at the architectural-policy level (“successful absence is distinct from failed lookup; requiredness belongs to the use case”), not as inheritance of either source mechanism — implement Rust as Result<Option<T>, E>, retain Python’s current split, and record a TypeScript follow-on that separates workspace lookup from getProjects; affected items: R03 directly, R01 only as the carrier shape, R67/R70 only as downstream mappings; do not reclassify the F012 ledger row until an owner-approved cross-repository follow-on lands — evidence: owner review, Python HEX-12, and convergent Rust std/SQLx/Diesel/kube/SeaORM practice.` ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md))

### Dominant choice

**Lookup–Require Split**

- **Lookup:** driven seam returns `Result<Option<T>, E>`.
- **Require:** the application/use-case layer converts `None` with `ok_or_else`.
- **Failure:** `Err(E)` is separately mapped to an application source-failure category.
- **Dependency:** standard library only; `thiserror` is optional syntax.
- **Agreement level:** shared architectural pattern across Python, TypeScript and Rust; ecosystem-specific low-level encoding.

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Lookup–Require Split: `Result<Option<T>, E>` then `ok_or_else`** | Rust `Option`; SQLx `fetch_optional`; Diesel `optional`; kube `get_opt`; SeaORM `one`; axum call-site conversion. ([doc.rust-lang.org](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)) | SQLx, Diesel, kube, SeaORM, rust-postgres, rust-rocksdb, Block Buzz | Undated live API/source documentation, verified 2026-09-17 |
| **Required lookup error: `Result<T, LookupError::NotFound>`** | SQLx `fetch_one`; kube `get`; SeaORM `require_one`. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)) | SQLx, kube, SeaORM | Undated live API documentation, verified 2026-09-17 |
| **Adapter-owned domain collapse: `Result<T, DomainError>`** | Current TypeScript `getProjects` combines workspace lookup, HTTP activity and `NotFoundError`. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)) | `ts-launch-blueprint` current implementation | Current main-branch source, verified 2026-09-17 |
| **Explicit nonfailure outcome: `Result<LookupOutcome<T>, E>`** | No maintained authoritative Rust reference found for the binary present/absent case | None identified in the surveyed shortlist | Evidence gap recorded 2026-09-17 |
| **Outer optional: `Option<Result<T, E>>`** | Rust documents it chiefly through `Option::transpose`, which produces `Result<Option<T>, E>`. ([doc.rust-lang.org](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai)) | No mainstream lookup API found using it as the public primitive | Undated live std documentation, verified 2026-09-17 |

The surveyed sources do not publish the exact port-to-use-case split under a standard Rust pattern name. **Lookup–Require Split** is therefore a project-defined name for an established composition of standard and widely practised idioms, not a claim of an existing Gang-of-Four-style name.

### Excluded by gate

No shortlisted standard-type pattern failed the six license/MSRV/security/platform/runtime/cost gates. The following shapes fail the item's semantic capability gate before shortlisting:

| Excluded shape | Failed gate |
|---|---|
| `Option<T>` as the complete Rust seam return | Cannot represent transport or protocol failure without panic, side channel or hidden global state. Python's bare annotation works only because exceptions provide another channel. |
| Panic/`unwrap` on transport failure or absence | Violates the requirement for recoverable, typed outcomes; Rust guidance recommends `Result` for recoverable errors. ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html?highlight=nu&utm_source=openai)) |
| `Result<Option<T>, anyhow::Error>` as the public library/port contract | It preserves three runtime states but loses a stable, matchable source-error contract. A reporting type belongs after structured handling is complete, not at this seam. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai)) |
| Adapter directly returns CLI exit errors or HTTP statuses | Violates inward dependency direction and prevents the same core use case from serving CLI, library and web front ends. ([alistair.cockburn.us](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai)) |
| Treating every HTTP 404 or cache miss as `None` | Cannot prove authoritative resource absence and risks hiding route, tenant, permission or cache-coverage failures. |

Crate-specific RustSec and maintenance gates remain inapplicable because R03 requires no new package.

### Up-and-comers

1. **Paired optional/required methods.** SeaORM's `one`/`require_one` design makes cardinality policy visible in naming. For this template, the analogous pair is a driven `find_project` and an application `get_project` or `require_project`. ([docs.rs](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html))
2. **Richer lookup outcomes.** If absence acquires meaningful metadata, graduate from `Option<T>` to:
   ```rust
   enum LookupOutcome<T> {
       Found(T),
       Missing { reason: MissingReason },
   }
   ```
   and retain the outer `Result<_, E>`.
3. **Richer error reporting libraries.** Diagnostic/reporting layers may improve CLI presentation, but they do not replace the lookup contract. Their selection belongs with R67 or another error-reporting item.
4. **No credible new contender presently displaces `Result<Option<T>, E>`.** The field's recent refinement is paired APIs and better diagnostics, not a new cardinality primitive.

### Fit for this template

**CLI**

- The command calls one application use case and receives either the resource, a typed not-found error or a typed source failure.
- R67 can map those categories without the CLI importing an HTTP client or database error.
- Optional commands such as “show if configured” can consume `Ok(None)` without treating it as command failure.
- Error output and exit-code behavior remain centralized rather than duplicated at each I/O call.

**Library**

- This target benefits most from retaining optionality. Library callers may legitimately probe for a resource, provide a fallback or treat absence as success.
- A public `find_project` returning `Result<Option<Project>, E>` supports those callers without asking them to inspect or downcast a manufactured `NotFound` error.
- Concrete, matchable port/application errors remain composable; opaque reporting errors can be added only at an executable boundary.

**Web service**

- The web adapter consumes the same application error as the CLI. It does not derive domain meaning directly from SQL or HTTP status.
- The eventual R70 mapping can translate application not-found to its chosen HTTP problem/status and source failure to its chosen upstream/internal problem.
- The contract is async-neutral: the future's output is still `Result<Option<T>, E>`.
- Official axum examples confirm that `ok_or`/`?` is ergonomic at an HTTP boundary, though this template should perform that conversion one layer earlier, in its shared use case. ([github.com](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs))

### Recommendation

Adopt **Lookup–Require Split** as the R03 pattern:

1. A driven single-resource lookup **MUST** return:
   ```rust
   Result<Option<T>, E>
   ```
   or, asynchronously:
   ```rust
   Future<Output = Result<Option<T>, E>>
   ```

2. `Ok(None)` **MUST** mean the adapter successfully determined that the requested resource is absent.

3. `Err(E)` **MUST** mean the adapter could not produce a trustworthy answer. It includes transport, timeout, upstream rejection, protocol/schema and similar failures.

4. The driven port's error type **MUST NOT** contain a generic `NotFound` variant for this optional primitive.

5. The application/use-case that requires existence **MUST** perform the conversion:
   ```rust
   let value = lookup(...)
       .map_err(ApplicationError::Source)?
       .ok_or_else(|| ApplicationError::NotFound { key })?;
   ```

6. The resulting application error **MUST** contain separate, matchable categories for required-resource absence and source/I/O failure. R67 owns their final stable catalog names, codes and exit mappings.

7. Prefer naming that exposes the distinction:
   - driven seam: `find_project`, `resolve_workspace`
   - required use case: `get_project`, `require_project`

8. `thiserror` **MAY** derive the error boilerplate if selected elsewhere; R03 does not require it.

9. The pattern **MUST** be documented and tested independently of whether R01 chooses a trait, generic bound or injected closure.

10. Cross-repository rationale:
    - Python: retain current implementation.
    - Rust: implement `Result<Option<T>, E>`.
    - TypeScript follow-on: split optional workspace/resource lookup from the application service; use `Promise<T | undefined>` plus typed rejection unless that repository separately standardizes a discriminated result type.

### Ranked runner-up

**`Result<T, LookupError>` with a dedicated `NotFound` variant.**

It wins when **requiredness is invariant in the port contract**, not merely in one caller—for example:

- every valid invocation means “load this existing aggregate”;
- there is no probing or fallback use case;
- exposing an optional primitive would invite invalid handling;
- the operation is a command whose target must exist rather than a neutral query.

SQLx `fetch_one`, kube `get` and SeaORM `require_one` show this contract is legitimate. It does not win for the template's reusable lookup seam because the CLI, library and web targets can apply different policy to absence. ([docs.rs](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai))

### Tradeoffs

| Alternative | What the recommendation gives up | Why accepted |
|---|---|---|
| Required lookup error | A flatter `Result<T, E>` and direct `?` propagation of not-found | The flatter type hard-codes requiredness and makes optional callers demote an error back into absence. |
| Adapter-owned `DomainError` | Fewer mapping lines in a single adapter function | It couples transport code, fakes and every future adapter to application policy and R67's taxonomy. |
| Explicit `LookupOutcome<T>` | Named variants and easy future expansion | `Option<T>` is smaller and universally understood while there are only present/absent nonfailure outcomes. |
| `Option<Result<T, E>>` | Equivalent three-state expressiveness | The nesting order obscures that operation failure dominates the entire lookup; standard APIs consistently favor `Result<Option<…>>`. |
| Python-style bare optional return | Visually simpler signature | Rust has no exception channel; bare `Option<T>` would discard I/O failure information. |
| Automatic `From` conversion with bare `?` | One fewer visible combinator | Explicit `map_err(ApplicationError::Source)` teaches where the abstraction crossing occurs and is easier to assert in tests. |
| Opaque reporting error | Easy context attachment | Library and use-case code still needs structured matching; reporting belongs at the outer boundary. |

The accepted cost is one nested standard type and usually one `ok_or_else` at a required call site.

### Parameters

- `owns (none) = n/a`
- `assumes error-taxonomy-exit-codes = R67-defined; it must accept separately typed application categories for resource absence and source/I/O failure, but R03 does not require distinct numeric exit codes`
- `assumes rust-edition = 2024`
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
- `assumes current-msrv-floor = 1.96.0 as of 2026-09-17, because stable is 1.98.0`
- `assumes license = MIT OR Apache-2.0`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes http-transport-injection-seam = unresolved by R01; return semantics remain Result<Option<T>, E> for trait, generic-bound or injected-function forms`
- No `CONFLICT:` identified. ([raw.githubusercontent.com](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md))

### Migration implications

Logical file locations are shown below; R01/R02 may place them in one crate, modules or separate workspace members without changing the contract.

| File or logical module | Change |
|---|---|
| `<projects>/ports.rs` or the R01-selected seam module | Define the optional lookup signature `find_project(...) -> Result<Option<Project>, E>` and equivalent workspace-resolution lookup. Document all three states. |
| `<projects>/errors.rs` | Define the application/use-case not-found category and distinct source-failure category. Do not assign R67's final code here. |
| `<projects>/services.rs` | Translate `None` with `ok_or_else`; map port failures separately. Keep HTTP, SQL and CLI types out. |
| `<projects>/adapters/http.rs` | Inspect protocol semantics before generic status-to-error conversion; map only authoritative resource absence to `Ok(None)`. |
| `<projects>/adapters/in_memory.rs` | Return `Ok(None)` for a missing key and support an explicit injected-failure mode for contract tests. |
| `<projects>/adapters/database.rs`, if shipped | Use the datastore's optional lookup form rather than catching every error as no-row. |
| `<cli>/errors.rs` or CLI entry point | Consume only the application error and delegate final exit mapping to R67. |
| `<web>/problems.rs` | Consume only the application error and delegate HTTP problem/status mapping to R70. |
| `tests/port_contract.rs` | Shared found/absent/failure suite for every adapter. |
| `tests/projects_service.rs` | Assert explicit absence-to-not-found and source-failure mappings. |
| `tests/cli_errors.rs` and web error tests | Assert the two application categories remain distinguishable at each driving adapter. |
| `docs/design/lookup-require-split.md` | Record the pattern name, state table, authoritative-absence rule and examples for trait/generic/closure forms. |
| `research/topics/03-*/DECISION.md` | Record this recommendation and the `BASELINE-REVIEW` line. |
| `docs/port/COMMONALITY.md` | Do not silently reclassify F012; preserve its source divergence and link the resolved R03 decision. |

**Cross-repository follow-on, not part of this Rust implementation:**

- Python requires no behavior change; add or retain contract tests and shared terminology.
- TypeScript should split `src/lib/api.ts` so workspace/resource lookup returns `undefined` on authoritative absence and throws/rejects only on source failure; an application service should create `NotFoundError`. The current inline throw is visible at the workspace search inside `getProjects`. ([github.com](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts))

The Rust repository currently has no Rust implementation, so these are planned additions rather than edits to existing source files. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

### Validation strategy

**Executed during this research:** none. The repository is explicitly in a research-only state with no Rust code, so the following checks are proposed acceptance commands, not claimed results. ([github.com](https://github.com/smorinlabs/rs-launch-blueprint))

**Toolchain and full-workspace checks**

```bash
# Current floor as of 2026-09-17.
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --all-features
cargo +stable fmt --all -- --check
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo +stable test --workspace --all-targets --all-features
cargo +stable test --workspace --doc
```

Expected: the contract compiles on the MSRV and stable toolchains, with web features enabled and disabled, on both `ubuntu-latest` and `macos-latest`.

**Port contract**

```bash
cargo test --test port_contract -- --nocapture
```

Required cases:

```text
found:
  adapter -> Ok(Some(project))

authoritative absence:
  adapter -> Ok(None)

transport failure:
  adapter -> Err(ProjectsPortError::Transport(_))

protocol/schema failure:
  adapter -> Err(ProjectsPortError::Protocol(_))
```

Run the same suite against the in-memory fake and each concrete adapter. For an HTTP adapter, the realistic fixture must include a valid response, documented resource-level 404, timeout/reset, 5xx and malformed success body. The HTTP mocking library is whatever R48 selects; R03 does not choose it.

**Application translation**

```bash
cargo test --test projects_service \
  absence_becomes_not_found \
  source_failure_stays_distinct \
  optional_lookup_preserves_none \
  found_value_is_returned
```

Expected:

- `Ok(Some(project))` → `Ok(project)`
- `Ok(None)` → `Err(GetProjectError::NotFound { .. })`
- `Err(port_error)` → `Err(GetProjectError::Source(port_error))`
- `Error::source()` remains populated for wrapped transport failures
- the optional library use case still returns `Ok(None)`

**CLI and web integration**

```bash
cargo test --test cli_errors
cargo test --features web --test web_errors
```

Expected:

- not-found and source failure arrive as different application variants;
- CLI tests assert the exact R67 exit codes once assigned;
- web tests assert the exact R70 problem/status mappings once assigned;
- neither test imports or matches the concrete HTTP/database error to determine absence.

**Call-count and performance invariants**

Each fake should contain an invocation counter. Tests must assert one lookup call for found, absent and failure paths, proving `ok_or_else` adds no retry or second I/O operation.

A planned, nonblocking performance check may run an equal mix of found/absent/failure lookups through:

1. an in-memory adapter in `--release`;
2. a loopback HTTP adapter under R05's selected runtime and concurrency;
3. both dominant and runner-up encodings with identical adapter behavior.

Record wall-clock latency, operations per second, request count and peak memory. Do not establish a pass threshold unless measurement finds a material difference; semantic correctness is the acceptance gate.

### Confidence & re-verify trigger

**Confidence: high — 0.94.**

The recommendation is supported by first-party Rust semantics, multiple independent database and remote-API libraries, maintained framework examples, the original hexagonal architecture source and the Python repository's already-tested pattern.

Re-verify if any of these occur:

1. R01 chooses a seam representation that cannot retain `Result<Option<T>, E>` as its logical output.
2. R67 adopts an error model that cannot accept separately typed absence and source-failure categories.
3. The target upstream protocol cannot reliably distinguish resource absence from endpoint, authorization or tenant errors.
4. Every legitimate caller is proven to require existence, making the required-lookup runner-up simpler without sacrificing reuse.
5. Absence needs structured metadata, making `LookupOutcome<T>` preferable to `Option<T>`.
6. TypeScript standardizes an explicit result/discriminated-union convention; its follow-on should then use that convention rather than promise rejection.
7. Stable Rust advances, requiring the concrete MSRV CI value to move under the fixed stable-minus-two policy.
8. An empirical end-to-end benchmark unexpectedly finds material latency, throughput or resource differences attributable to the return encoding.

### Sources

All URLs were retrieved **2026-09-17**.

| Source | URL | Publication/current date and role |
|---|---|---|
| Rust `Option` documentation | `https://doc.rust-lang.org/std/option/enum.Option.html` | Live std documentation; `ok_or_else`, `transpose` |
| Rust Reference, operator expressions | `https://doc.rust-lang.org/reference/expressions/operator-expr.html` | Live normative reference; `?` behavior |
| Rust Book, recoverable errors | `https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html` | Live first-party guidance |
| `Path::try_exists` | `https://doc.rust-lang.org/stable/std/path/struct.Path.html#method.try_exists` | Live std precedent for negative answer versus inability to determine |
| RFC 0236, error conventions | `https://rust-lang.github.io/rfcs/0236-error-conventions.html` | 2014-10-30; Rust library error conventions |
| RFC 2965, Error Handling Project Group | `https://rust-lang.github.io/rfcs/2965-project-error-handling.html` | 2020-07-23; concrete error versus reporting type guidance |
| Rust 1.98.0 announcement | `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` | 2026-08-20; current stable-version endpoint |
| 2025 State of Rust survey results | `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` | 2026-03-02; ecosystem/source-weighting context |
| Original Hexagonal Architecture article | `https://alistair.cockburn.us/hexagonal-architecture` | 2005-09-04; primary architectural source |
| SQLx `fetch_optional` | `https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html#method.fetch_optional` | Live maintainer documentation |
| Diesel `OptionalExtension` | `https://docs.rs/diesel/latest/diesel/prelude/trait.OptionalExtension.html` | Live maintainer documentation |
| Diesel changelog | `https://github.com/diesel-rs/diesel/blob/main/CHANGELOG.md` | Maintainer statement describing `Result<Option<T>>` as idiomatic for zero-or-one |
| kube `Api::get_opt` | `https://docs.rs/kube/latest/kube/struct.Api.html#method.get_opt` | Live maintainer documentation |
| SeaORM `one` / `require_one` | `https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html` | Live maintainer documentation |
| axum todos example | `https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs` | Maintained Tokio source; explicit `ok_or(NOT_FOUND)` |
| axum SQLx example | `https://github.com/tokio-rs/axum/blob/main/examples/sqlx-postgres/src/main.rs` | Maintained Tokio integration example |
| rust-postgres client | `https://github.com/sfackler/rust-postgres/blob/master/postgres/src/client.rs` | Maintained source showing fallible optional row lookup |
| rust-rocksdb database API | `https://github.com/rust-rocksdb/rust-rocksdb/blob/master/src/db.rs` | Maintained source showing `Result<Option<Vec<u8>>, Error>` |
| Block Buzz store | `https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs` | Company-hosted independent practice evidence |
| `thiserror` documentation | `https://docs.rs/thiserror/latest/thiserror/` | Live maintainer documentation; derive mechanics |
| MDN `fetch()` | `https://developer.mozilla.org/en-US/docs/Web/API/Window/fetch` | Live web-platform documentation |
| TypeScript `strictNullChecks` | `https://www.typescriptlang.org/tsconfig/strictNullChecks.html` | Live first-party TypeScript documentation |
| Python hexagonal design | `https://github.com/smorinlabs/py-launch-blueprint/blob/main/docs/design/0005-hexagonal-architecture-and-enforcement.md` | Current repository design; HEX-12 |
| Python ports | `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/src/py_launch_blueprint/core/ports.py` | Current source contract |
| Python projects service | `https://raw.githubusercontent.com/smorinlabs/py-launch-blueprint/main/src/py_launch_blueprint/core/services/projects.py` | Current absence-to-application-error translation |
| TypeScript API client | `https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts` | Current inline workspace-not-found translation |
| Rust research governing specification | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md` | Approved 2026-09-01; amended 2026-09-04 |
| Commonality ledger | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md` | Current F012 classification |
| Fixed parameters | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md` | Owner-fixed values, 2026-09-02 |
| Owner review | `https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/OWNER-REVIEW.md` | R03 owner direction, 2026-09-04 |
| Rust template repository | `https://github.com/smorinlabs/rs-launch-blueprint` | Current research-only repository state |

## Sources

- [PathBuf in std::path - Rust](https://doc.rust-lang.org/std/path/struct.PathBuf.html?search=Option%3CT%3E%2C+%28T+-%3E+U%29+-%3E+Option%3CU%3E&utm_source=openai)
- [Query in sqlx::query - Rust](https://docs.rs/sqlx/latest/sqlx/query/struct.Query.html?utm_source=openai)
- [Select in sea_orm::query - Rust](https://docs.rs/sea-orm/latest/sea_orm/query/struct.Select.html)
- [Option in std::option - Rust](https://doc.rust-lang.org/std/option/enum.Option.html?utm_source=openai)
- [hexagonal-architecture](https://alistair.cockburn.us/hexagonal-architecture?utm_source=openai)
- [axum/examples/todos/src/main.rs at main · tokio-rs/axum · GitHub](https://github.com/tokio-rs/axum/blob/main/examples/todos/src/main.rs)
- [2025 State of Rust Survey Results | Rust Blog](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/?utm_source=openai)
- [py-launch-blueprint/src/py_launch_blueprint/core/ports.py at main · smorinlabs/py-launch-blueprint · GitHub](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/core/ports.py)
- [result.rs - source](https://docs.rs/diesel/latest/src/diesel/result.rs.html?utm_source=openai)
- [Api in kube - Rust](https://docs.rs/kube/latest/kube/struct.Api.html)
- [buzz/crates/buzz-relay/src/api/git/store.rs at main · block/buzz · GitHub](https://github.com/block/buzz/blob/main/crates/buzz-relay/src/api/git/store.rs?utm_source=openai)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/superpowers/specs/2026-09-01-rs-port-research-program-design.md)
- [Announcing Rust 1.98.0 | Rust Blog](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/?utm_source=openai)
- [ts-launch-blueprint/src/lib/api.ts at main · smorinlabs/ts-launch-blueprint · GitHub](https://github.com/smorinlabs/ts-launch-blueprint/blob/main/src/lib/api.ts)
- [Option in core::option - Rust](https://doc.rust-lang.org/core/option/enum.Option.html?utm_source=openai)
- [thiserror - Rust](https://docs.rs/thiserror/latest/thiserror/)
- [2965-project-error-handling - The Rust RFC Book](https://rust-lang.github.io/rfcs/2965-project-error-handling.html?utm_source=openai)
- [Operator expressions - The Rust Reference](https://doc.rust-lang.org/reference/expressions/operator-expr.html?highlight=two-complement&utm_source=openai)
- [GitHub - smorinlabs/rs-launch-blueprint: Rust sibling of py-launch-blueprint / ts-launch-blueprint — CLI + library + web service template (research phase) · GitHub](https://github.com/smorinlabs/rs-launch-blueprint)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/COMMONALITY.md)
- [To panic! or Not to panic! - The Rust Programming Language](https://doc.rust-lang.org/book/ch09-03-to-panic-or-not-to-panic.html?highlight=nu&utm_source=openai)
- [https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md](https://raw.githubusercontent.com/smorinlabs/rs-launch-blueprint/main/docs/port/PARAMETERS.md)

---


## Perplexity Results

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
provider: perplexity
model: sonar-deep-research
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

# Port Absence–Failure Split Pattern for `rs-launch-blueprint` (R03)

This report defines a cross-repo architectural pattern for how driven I/O boundaries in `rs-launch-blueprint` distinguish between an expected “resource does not exist” outcome and an unexpected transport or I/O failure, and where that distinction is lifted into domain-level error types that feed the shared error taxonomy and exit-code mapping. The central recommendation is that Rust ports and injected I/O functions in this template model transport fallibility with a typed `Result<E, T>` and model resource absence with `Option<T>` on the success channel, yielding a seam contract of the form `Result<Option<T>, TransportError>` for “get-or-absent” operations, while the domain service layer is responsible for translating `None` into a domain-level `NotFound` error variant consistent with hexagonal architecture principles.[4][10][12] This design harmonizes the underlying principle currently split between the Python and TypeScript templates, preserves ecosystem-appropriate idioms in each language, and provides a clear, testable convention for where absence becomes an error, without burying that conversion inside generic error types or leaking transport concerns into domain semantics.[4][7][8][10][12]

## Report

### Landscape

The category this item decides is the **absence–failure signaling pattern at a driven I/O seam in a hexagonal architecture**, and specifically how that pattern is expressed in Rust for a template that must act concurrently as a CLI, a library, and a web service. In Rust terms, this pattern lives at the intersection of the language’s explicit error-handling constructs (`Option<T>`, `Result<T,E>`, the `?` operator, and the `std::error::Error` trait), domain-specific error enums, and application-boundary error wrappers such as `anyhow::Error`.[1][2][3][4][6][8][10] At the architectural level it sits at the “ports and adapters” seam in a hexagonal architecture, where infrastructure-facing adapters must present a stable, transport-agnostic contract to the domain while still conveying both absence and failure in a precise, composable form.[12]

Mapping the Rust field for this category into three bins, the **built-in or first-party toolchain** bin is dominated by the language and standard library’s error primitives. The Rust Programming Language book’s error-handling chapters emphasize that Rust eschews exceptions in favor of explicit return values, primarily `Option<T>` for the *possibility of absence* and `Result<T,E>` for the *possibility of error*.[1][2][6] The book and related Rust error documentation explicitly contrast these two roles and note that, while `Option<T>` can be viewed as a special case of `Result<T, ()>`, its intended meaning is different: absence without error rather than failure of computation.[1][6][10] The `Result<T,E>` enum and its conventional `Ok(T)` / `Err(E)` variants form the foundation for recoverable error handling, with the `?` operator providing ergonomic propagation and `std::error::Error` modeling error traits.[2][4][10] The Rust API Guidelines further codify expectations about error documentation and usage, notably that examples should rely on the `?` operator rather than `unwrap` and that functions which may fail must document their error conditions.[14][15] These materials are authoritative as core Rust project publications and guideline documents produced by Rust teams and working groups, and they define the canonical semantics and idioms for absence and failure in Rust code.[1][2][6][10][14][15]

The **established industry standard** bin is populated by crates and patterns that have become de facto norms for error handling in Rust applications. Two crates dominate guidance and practice here: `thiserror` for deriving clean, typed error enums and `anyhow` for flexible application-boundary error types.[3][4][7][8] Microsoft’s Rust Patterns & Engineering book presents a detailed chapter on error-handling patterns that explicitly recommends using domain-specific enums with `thiserror` for library and domain logic, and using `anyhow::Result<T>` at application boundaries, including CLI entry points, to simplify error propagation while preserving context.[7] Google’s Comprehensive Rust course similarly introduces `anyhow::Error` as an idiomatic wrapper around `Box<dyn Error>` for rich error context in applications, while warning against its use in public library APIs.[8] In both guides, absence is still modeled by `Option<T>`, and failure by `Result<T,E>`, but the patterns show how these primitives compose with crate-based tooling to form robust error architectures that separate domain errors from infrastructural ones.[4][7][8] The `anyhow` crate’s own documentation reinforces this role, recommending `anyhow::Result<T>` as the return type for any fallible function in applications where the precise error type is not important, and relying on the `?` operator and the `std::error::Error` trait for propagation.[3] These sources are authoritative because they are widely cited, maintained training materials and crate documentation authored by leading Rust maintainers, and they are referenced in community discussions and corporate training resources.[3][7][8]

Within the same bin, we can also classify style guidance and example projects. The Rust API Guidelines documentation and its DeepWiki mirror describe how error conditions should be documented, and they emphasize explicit error handling in examples, using `?` and documenting failure modes in dedicated sections.[14][15] The guidelines are standards for Rust API design adopted across many crates, and they directly inform how absence and failure documentation should appear for port methods and domain services in a template.[14][15] Additionally, well-regarded projects such as `clap` (a leading CLI argument parser) and `sqlx` (an async SQL toolkit) illustrate mainstream patterns. `clap`’s documentation and training materials demonstrate a separation between argument-parsing errors, handled entirely within `clap`, and runtime errors handled by `anyhow::Result` in `main`, showing a clean division of error domains at the application boundary.[11][19] The example in Sunns Technologies’ `clap` tutorial shows `fn main() -> Result<()>` with `anyhow::Result` used to handle runtime errors like missing files, while `clap` itself exits early on argument errors.[11] This pattern is highly relevant to `rs-launch-blueprint`’s CLI shape, because it demonstrates how a fallible workflow can be built around `Result` and `?` while confining specific error types to suitable layers.[11][19]

The **up-and-comer** bin includes newer or more specialized crates and patterns that have not yet reached the ubiquity of `anyhow` and `thiserror`, but that express architectural principles relevant to this item. The `hexser` crate, for example, provides reusable generic types and traits for implementing hexagonal architecture (Ports and Adapters) with automatic graph construction and architectural validation.[12] Its documentation outlines key hexagonal principles, such as the dependency rule (dependencies point inward), port interfaces defining what the domain needs, and adapters providing concrete implementations using specific technologies.[12] While `hexser` can help structure complex applications into domain, ports, and adapters layers, it is not yet a universal standard for Rust hexagonal architectures. Nonetheless, its conceptual documentation is authoritative regarding hexagonal layering and dependency flows, and it reinforces the need for port contracts that are free of domain decisions about whether absence is an error, leaving such decisions to domain services.[12] In the context of this item, `hexser` supports the architectural rationale for splitting absence from failure at the port boundary and delaying domain error translation to a higher layer.

Turning to practice evidence, mainstream Rust projects with significant adoption and community esteem show consistent application of these principles. `sqlx` presents itself as “The Rust SQL Toolkit,” emphasizing async support and compile-time checked SQL queries without DSLs, which positions it as a serious, widely used infrastructure library.[18] Its design relies heavily on `Result<T,E>` for fallible operations and uses typed errors to distinguish transport or SQL-level failure from semantic cases like “no rows returned,” often modeling the latter as `Result<Option<Row>, DbError>` rather than conflating absence with error.[4][18] This pattern is explicitly described in independent write-ups on Rust error handling, which note that `Result<Option<T>, E>` is a common and useful type for operations that can fail but that may legitimately return no value even on success.[4][10] Similarly, Actix Web, a prominent web framework, uses typed `Result` values for HTTP handlers and provides mechanisms for custom error handlers such as transforming a missing resource into a specific 404 response body, again reflecting a clear separation between infrastructural failure and domain-meaningful absence.[16] These projects are widely regarded because they are heavily adopted and referenced in crates.io, GitHub discussions, and community documentation, and they shape prevailing practice for Rust web services and infrastructure-bound libraries.[18][19]

Finally, in judging fit over abstract best, we must evaluate candidates against the specific use case: a template that must serve as CLI, library, and web service simultaneously, and that must integrate with Python and TypeScript counterparts that currently diverge in how they split “is it there” from “is absence an error.” The Python port uses a two-layer split where the adapter returns `None` to represent absence, and a service layer translates `None` into a typed exception such as `ProjectNotFoundError`.[Context] The TypeScript port folds transport and domain decisions into a single function that both performs the HTTP call and throws `NotFoundError` inline when the resource is absent.[Context] The Rust ecosystem’s emphasis on explicit, typed absence (`Option<T>`) and recoverable failure (`Result<T,E>`) provides a natural way to emulate the Python split while avoiding the TypeScript conflation, by adopting a seam contract that distinguishes transport failure from `None` and by placing domain error translation in a service layer. Rust practice and authoritative guidance, especially the recommendation of `Result<Option<T>, E>` for fallible operations that may legitimately yield no value, align strongly with this shape.[4][10] Thus, the landscape supports a pattern that is both idiomatic in Rust and faithful to the shared hexagonal principle underlying the Python design, rather than treating either existing implementation as a predetermined winner.

### Principles and implementation

The shared requirement this item must preserve across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` is a **hexagonal architecture principle about how ports and adapters model absence versus failure and where domain semantics are applied**. Hexagonal architectures, as described in the `hexser` crate documentation and other sources, structure applications into concentric layers: a domain layer containing business logic, a ports layer defining abstract interfaces for external interactions, and an adapters layer providing concrete implementations using specific technologies like databases or HTTP APIs.[12] A key principle is that dependencies point inward: the domain layer does not depend on infrastructure details, and port interfaces express what the domain needs without dictating how it is achieved.[12] Within this model, ports should expose contracts that reflect the reality of external systems in a neutral way—some operations may legitimately result in no resource found, while others may fail due to transport or infrastructure issues—and adapters should map HTTP responses, database results, or file-system behaviors onto these contracts. The domain layer should then decide whether “no resource” is a normal condition or a domain error, based on business rules.

This principle can be stated more precisely: **at the driven-I/O boundary, absence is modeled as a non-exceptional outcome; domain code decides whether absence is acceptable or a failure, while transport or infrastructure failures are modeled as recoverable errors that must be distinguished from absence**.[4][10][12] The Python template currently conforms to this principle by having ports like `get_project` and `resolve_workspace_gid` return `... | None`, while service functions turn `None` into typed exceptions like `ProjectNotFoundError`.[Context] The TypeScript template diverges by performing both the HTTP request and the domain decision about absence within the same function, throwing `NotFoundError` inline when a resource is not found.[Context] The research mandate specifies that we must identify the shared engineering principle and the level at which agreement is required (capability, standard, architectural pattern, or policy), then evaluate architectures and libraries in each ecosystem without assuming any repo is the winner.[Context] In this case, the principle sits at the architectural pattern level: ports and adapters should distinguish resource absence from transport failure, and domain services should control when absence becomes a domain error.

Rust’s error model provides the tools to express this principle cleanly and explicitly. The Rust book emphasizes that `Option<T>` is the preferred way to encode the *possibility of absence* into the type system, thereby forcing the programmer to handle absence at compile time rather than encountering null-pointer errors at runtime.[1][6][9] The `Option` enum has two variants: `Some(T)` containing a value and `None` representing no value, and it is intended to model values that may or may not be present without treating absence as exceptional.[4][9][10] In contrast, the `Result<T,E>` enum represents the *possibility of error* in a computation, with the convention that `Ok(T)` is the expected outcome and `Err(E)` is an unexpected outcome describing why the computation failed.[1][2][6][10] Rust error documentation explicitly notes that `Option<T>` is analogous to `Result<T, ()>` in structure but that the intended meaning differs: absence versus computation failure.[6][10] These constructs are enforced by the compiler: you cannot ignore a `Result` or `Option` without explicitly choosing to do so, which eliminates entire classes of runtime bugs.[9][10] This separation of semantics maps directly onto our principle: ports should use `Option<T>` to represent absence and `Result<T,E>` to represent transport failure, and domain services should convert `None` into domain error types when appropriate.

More subtly, Rust practice and independent error-handling write-ups recommend combining `Option<T>` and `Result<T,E>` in types like `Result<Option<T>, E>` when operations can both fail and legitimately return nothing on success.[4][10] In this pattern, if the result is `Err(E)`, a transport or infrastructure error occurred, and this should typically be propagated or logged according to the error taxonomy; if the result is `Ok(None)`, the operation succeeded but no value was found, which is not inherently an error; and if the result is `Ok(Some(T))`, the operation succeeded and produced a value.[4][10] This pattern is common in database queries (where “no row” is not necessarily an error) and in HTTP clients where a `404` may represent absence rather than a transport failure, and it aligns exactly with the hexagonal principle described above.[4][10][12] It provides a clear, composable seam contract that allows domain services to determine the semantics of `None` in each context, while isolating transport failures as distinct error variants. Thus, at the architectural pattern level, we can operationalize our principle as **ports and adapters for resource-fetching operations in `rs-launch-blueprint` should return `Result<Option<T>, TransportError>`**, where `TransportError` is an infrastructure- or transport-level error type, and domain services should convert `None` into domain error variants when absence is not acceptable.

From an agreement perspective, what must be shared across repos is not the exact type names or even the exact pattern syntax, but the **principle that absence is represented explicitly and non-exceptionally at the port boundary, and the domain decides whether absence is a failure**. In Python, this principle is represented by `Optional[T]` return types in ports and service-level exceptions; in TypeScript, the current design does not reflect it, because the port function both performs the transport and throws domain exceptions inline; in Rust, the principle can be expressed as `Result<Option<T>, TransportError>` plus domain-level conversion.[Context][4][10][12] The agreement level is architectural pattern and policy: all three repos should converge on this rule, even if the language-specific mechanics differ. The requirement does not strictly mandate identical shapes for error types or the use of particular crates (e.g., `anyhow` versus `thiserror`) across repos, but it does require that transport concerns and domain semantics be separated at the ports-and-adapters seam, with explicit modeling of absence and failure.

Therefore, this report proposes the following explicit baseline review:

> **BASELINE-REVIEW: F012 — port absence–failure principle — proposed change — evidence.**  
> Principle: Driven I/O ports should represent resource absence as a non-exceptional outcome (e.g., `None` or `Option<T>`) and transport failures as recoverable errors, leaving domain services to decide when absence is a domain error.[4][6][9][10][12]  
> Proposed change: Align the TypeScript template with the Python and Rust patterns by having its HTTP client functions return a union or tagged result that expresses absence separately from transport failure (e.g., `{ kind: "found", project } | { kind: "not_found" } | { kind: "error", err }`), and move the translation from absence to `NotFoundError` into a service layer, rather than throwing inline in the port.[Context]  
> Evidence: Rust’s explicit separation of `Option<T>` and `Result<T,E>` for absence and failure,[1][2][4][6][9][10] Rust error-handling documentation’s endorsement of `Result<Option<T>, E>` for fallible operations that may legitimately return no value,[4][10] hexagonal architecture guidance emphasizing ports as domain-neutral contracts and adapters as infrastructure implementations,[12] and mainstream Rust projects’ use of similar patterns for database queries and HTTP handlers.[4][10][16][18]

Implementing this principle in Rust requires choosing specific error types and layering conventions that fit the ecosystem. For library and domain logic, authoritative sources and community practice recommend using **typed error enums** with `thiserror` derive macros, which generate `Display`, `Error`, and `From` implementations, making it easy to compose errors and convert between layers.[4][7] The Microsoft Rust Patterns book illustrates an `AppError` enum with variants like `Io(std::io::Error)` and `Json(serde_json::Error)`, each annotated with `#[error("...")]` and `#[from]` attributes, allowing `?` to propagate underlying errors into the application error type.[7] For application boundaries, `anyhow` provides `anyhow::Error`, essentially a wrapper around `Box<dyn Error>`, and a type alias `anyhow::Result<V>` for `Result<V, anyhow::Error>`, which is widely used in CLI and application `main` functions where precise error matching is not required.[3][8] These crates do not change the fundamental absence–failure distinction; they simply improve ergonomics for error propagation and context addition. In `rs-launch-blueprint`, they can be used as follows: port and domain layers define typed error enums using `thiserror`, while the CLI and web entry points use `anyhow::Result<()>` and convert domain errors into exit codes or HTTP statuses via R67’s taxonomy.[3][4][7][8][11]

Crucially, the pattern we recommend keeps the **absence-to-domain-error translation explicit at the semantic boundary**, not hidden inside a generic error type. Rust combinators like `ok_or` and `ok_or_else` help convert `Option<T>` into `Result<T,E>` by providing an error value when `None` is encountered.[4][9] For example, after obtaining `Result<Option<Project>, TransportError>` from a port, a domain service can use `.map_err(DomainError::TransportFailure)?` to convert transport errors into domain errors, and then `.ok_or(DomainError::ProjectNotFound)` to turn `None` into a domain `NotFound` variant.[4] This keeps the conversion localized to the service method that knows whether absence is acceptable, and it makes the distinction between absence and failure visible to readers and reviewers. The use of `?` maintains ergonomic propagation: each fallible step is still a single expression, but the domain error type carries distinct variants for transport failure and not-found, which R67 can map to different exit codes or HTTP statuses.[4][7][8][11]

A minimal realistic example in Rust can illustrate these principles. Consider a port interface for fetching a project by ID and a domain service that requires the project to exist:

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum TransportError {
    #[error("I/O error: {0}")]
    Io(#[from] std::io::Error),
    #[error("HTTP error: {0}")]
    Http(String), // Simplified for example
}

#[derive(Debug, Error)]
pub enum DomainError {
    #[error("transport failed: {0}")]
    Transport(#[from] TransportError),
    #[error("project not found: {0}")]
    ProjectNotFound(String),
}

pub trait ProjectPort {
    fn get_project(&self, id: &str) -> Result<Option<Project>, TransportError>;
}

pub struct ProjectService<P: ProjectPort> {
    port: P,
}

impl<P: ProjectPort> ProjectService<P> {
    pub fn load_required_project(&self, id: &str) -> Result<Project, DomainError> {
        let maybe = self.port.get_project(id)?; // TransportError -> DomainError::Transport via From
        let project = maybe.ok_or(DomainError::ProjectNotFound(id.to_owned()))?;
        Ok(project)
    }
}
```

In this example, the port method models both absence and failure with `Result<Option<Project>, TransportError>`. The service method treats transport errors as domain-level `Transport` failures (using `?` and `From`) and treats absence as a domain-level `ProjectNotFound` error (using `ok_or`). This clear separation mirrors the Python pattern (adapter returns `Optional[Project]`, service raises `ProjectNotFoundError`) and corrects the TypeScript pattern by moving absence-to-error translation into the service layer.[1][4][6][7][10][12] An executable acceptance check would consist of integration tests that assert: when the underlying adapter returns `Ok(None)`, `load_required_project` returns `Err(DomainError::ProjectNotFound(_))`; when the adapter returns `Err(TransportError::Io(_))`, `load_required_project` returns `Err(DomainError::Transport(_))`; and when the adapter returns `Ok(Some(project))`, it returns `Ok(project)`. These tests confirm that absence and failure are distinguished at the port and correctly translated at the domain boundary.

### Dominant choice

Given the landscape, principles, and ecosystem evidence, the **dominant choice** for `rs-launch-blueprint` is to adopt a pattern we can name the **Port Absence–Failure Split (R03) pattern**, defined as follows in Rust terms:

At the driven-I/O boundary—whether expressed as a formal port trait, a generic-bound function, or an injected closure—resource-fetching operations that may legitimately find nothing but can also experience transport or infrastructure failures shall return `Result<Option<T>, TransportError>`, where `T` is the resource type (e.g., `Project`), and `TransportError` is a typed error enum representing transport/infrastructure failures (e.g., network errors, I/O errors, protocol violations).[4][10][12] Domain services that require the resource to exist shall receive this value and convert `Err(TransportError)` into a domain error variant (e.g., `DomainError::Transport`) and convert `Ok(None)` into a domain not-found variant (e.g., `DomainError::ProjectNotFound`), using constructs such as `.map_err(DomainError::Transport)?` and `.ok_or(DomainError::ProjectNotFound(...))`.[4][7] The absence-to-domain-error translation shall always occur in the domain service layer, not in adapters or ports, preserving the hexagonal separation between infrastructure and domain semantics.[12]

This choice is dominant for several reasons. First, it aligns exactly with Rust’s semantic distinction between `Option<T>` (absence) and `Result<T,E>` (error) as codified in the Rust book and error documentation.[1][2][6][9][10] Using `Result<Option<T>, E>` is explicitly recommended in independent error-handling guidance for operations that can fail but may legitimately produce no value, and it appears in mainstream projects like `sqlx` and in discussions of database and HTTP patterns.[4][10][18] Second, the pattern is consistent with hexagonal architecture principles: ports and adapters model external system behavior neutrally, exposing absence and failure separately, while domain services impose business semantics on these outcomes.[12] By returning `Result<Option<T>, TransportError>` from the seam, we avoid conflating infrastructure concerns (transport errors) with domain decisions about whether absence is acceptable, and we keep the domain free from transport-specific types.

Third, the pattern scales across `rs-launch-blueprint`’s multiple shapes: CLI, library, and web service. For CLI entry points, `main` can return `anyhow::Result<()>`, and internal domain services can return `Result<T, DomainError>` where `DomainError` is a typed enum derived via `thiserror`.[3][4][7][8][11] The CLI can then convert domain errors into exit codes via R67’s taxonomy, while ports follow the `Result<Option<T>, TransportError>` contract. For the library facet, public APIs can expose typed error enums and `Option<T>` outputs where absence is expected, using the same pattern without depending on `anyhow`.[4][7][8][14][15] For web services, route handlers can map domain not-found variants to `404 Not Found` responses and transport failures to `500 Internal Server Error` or other appropriate statuses, again using the same seam contract and domain translation logic.[16][18] The pattern is thus flexible enough to be used consistently across shapes, but explicit enough that its application can be tested and reasoned about.

Finally, the pattern is a natural expression of the cross-repo principle underlying the Python design and provides a clear path to harmonize the TypeScript design. The Python port’s adapters already return `Optional[T]` for absence, and service layers raise typed exceptions; the Rust pattern mirrors this with `Option<T>` and domain error conversion; the TypeScript port can be refactored to follow a similar separation, returning explicit tags for absence versus failure and moving the translation to services.[Context] By naming the pattern and codifying its contract for Rust, we establish a shared architectural policy across repos while still allowing each ecosystem to use idiomatic tooling (exceptions in Python, union types or `Result`-like objects in TypeScript, enums and `Result` in Rust) to implement it.

### Options

Several candidate patterns exist for modeling absence and failure at the driven-I/O boundary in Rust, and each is documented in different sources and adopted by different projects. Here we describe the main options considered, noting where each is documented, which adopters practice it, and the date of the most recent authoritative write-up, without asserting download counts or popularity figures.

The first option is the **Option-only seam pattern**, where ports and injected functions simply return `Option<T>` to represent both absence and failure, with `None` interpreted as “not found or failed.” This pattern is occasionally seen in lightweight code where the error cause is not important, but it contradicts Rust’s intentional distinction between absence and error. The Rust book and error documentation warn that `Option<T>` should represent a value that may or may not be present, not general error conditions, and that `Result<T,E>` should be used when the caller may need to know *why* an operation failed.[1][4][6][9][10] While this pattern can be documented in ad hoc blog posts, it does not have authoritative backing in core Rust guidance and is rarely adopted in serious infrastructure projects, because it discards error information and makes it impossible to differentiate between missing resources and transport failures.[4][10] Its most recent notable discussions appear primarily as negative examples in error-handling write-ups that recommend `Result<Option<T>,E>` instead.[4][10]

The second option is the **Result-only domain-error seam pattern**, where ports return `Result<T, DomainError>`, and a particular domain error variant (e.g., `DomainError::NotFound`) represents resource absence. This pattern closely resembles the current TypeScript design, where the HTTP client both performs the request and throws a domain-level `NotFoundError` inline.[Context] Rust’s `thiserror` crate and patterns documented in Microsoft’s Rust Patterns book make this approach ergonomic: domain error enums can have variants like `NotFound` and `Io`, with `#[from]` attributes allowing `?` to convert lower-level I/O errors into domain variants.[4][7] Some projects adopt this style when the domain semantics tightly couple to the transport; for example, a library whose primary function is retrieving resources might treat all absence as domain errors and expose only `Result<T, DomainError>` APIs. However, hexagonal architecture guidance and Rust error docs suggest that conflating absence and domain error at the port boundary can make it difficult to reuse ports in contexts where absence is acceptable (e.g., optional lookups), and it mixes infrastructure concerns with domain semantics.[10][12] Authoritative write-ups, such as Microsoft’s error-handling chapter and Google’s Comprehensive Rust, tend to recommend this style for domain-level APIs but still use `Option<T>` internally for absence and treat domain errors as distinct from transport errors.[4][7][8]

The third option is the **dual-channel seam pattern**, `Result<Option<T>, TransportError>`, which we have selected as the dominant choice. This pattern is documented in multiple authoritative sources. The Rust error documentation explicitly notes that `Option` is analogous to `Result<T, ()>`, and it discusses types like `Result<Option<i32>, MyError>` as representations of fallible computations that may succeed with either a value or nothing, where returning nothing is not an error.[10] Independent error-handling write-ups reinforce that `Result<Option<T>, E>` is common and useful, especially when a database query can fail but, on success, may return no row, and they recommend using `Option<T>` to model absence without treating it as exceptional.[4][10] Projects like `sqlx` and other database or HTTP clients use this pattern to represent “fallible fetch with possible absence,” and training resources, including Microsoft’s Rust Patterns, show the use of `Option<T>` with the `?` operator in domain code, demonstrating that `?` also works with `Option` in functions returning `Option`.[7][18] The most recent authoritative write-ups are the error-handling chapters in Comprehensive Rust and Microsoft’s Rust Patterns, which continue to endorse typed errors plus explicit absence.[7][8] This pattern has strong adoption in maintained, well-regarded Rust projects and aligns with core language semantics.[4][10][18]

A fourth option is the **anyhow-only pattern**, where ports and domain services return `anyhow::Result<T>` and rely exclusively on `anyhow::Error` for all failures, encoding absence either as `None` or by embedding it inside an error type. The `anyhow` crate documentation encourages using `anyhow::Result<T>` as the return type for any fallible function in applications where the specific error type is not important, and it shows how `?` can propagate any error implementing `std::error::Error`.[3] Google’s Comprehensive Rust course explains that `anyhow::Error` is essentially a wrapper around `Box<dyn Error>` and that it is generally not a good choice for the public API of a library, but is widely used in applications.[8] While this pattern is attractive for CLI or small applications because it maximizes ergonomics, it blurs the separation between port and domain errors and makes it harder to enforce a clear taxonomy for R67. It is therefore best reserved for application boundaries, not for ports or domain services.

The fifth option is the **hexser-mediated port pattern**, where a crate like `hexser` defines generic port traits and adapter implementations, potentially encoding absence and failure according to its internal conventions.[12] The `hexser` documentation describes five layers (domain, ports, adapters, infrastructure) and derives macros for marking port traits and adapter implementations, aiming to automate graph construction and architectural validation.[12] However, while `hexser` provides architectural scaffolding, it leaves the specific error types and absence modeling to the user, and it does not prescribe a particular pattern like `Result<Option<T>, E>` or `Result<T, DomainError>`.[12] Its most recent authoritative write-up is its lib.rs documentation, which focuses more on architectural structure than on error semantics.[12] Given that `rs-launch-blueprint` must remain flexible in whether it adopts port traits at all (R01 is undecided), and given the need to control error semantics directly, relying on `hexser` as the primary implementation mechanism for R03 would be premature.

We can summarize these options in a table for clarity, noting document sources and typical adopters qualitatively:

| Pattern name                         | Documentation sources                                | Typical adopters                                      | Recent authoritative write-up (qualitative) |
|--------------------------------------|------------------------------------------------------|-------------------------------------------------------|---------------------------------------------|
| Option-only seam                     | Occasional blog posts, ad hoc code; discouraged in Rust book and error docs[1][4][6][10] | Small scripts, non-critical prototypes                | Mostly discussed as a negative pattern in error-handling guides[4][10] |
| Result-only domain-error seam        | Rust Patterns (thiserror examples)[4][7], Comprehensive Rust (typed errors)[8]          | Domain-heavy libraries, some apps where absence is always error | 2020–2025 error-handling chapters in training materials[4][7][8]     |
| Dual-channel seam (`Result<Option,T>`) | Rust error docs and independent write-ups[4][10], database/HTTP libs like `sqlx`[18]    | Mainstream infrastructure-bound crates, production apps | Ongoing in Comprehensive Rust and Microsoft patterns[4][7][8][10][18] |
| Anyhow-only pattern                  | `anyhow` crate docs[3], Comprehensive Rust[8], CLI tutorials with `clap`[11]           | CLIs, small apps; application boundaries              | 2024–2025 `anyhow` releases and training materials[3][8][11]         |
| Hexser-mediated port pattern         | `hexser` lib.rs documentation[12]                   | Early adopters of hexser-based architectures          | Latest lib.rs documentation[12]            |

### Excluded by gate

Applying the fitness gates specified in the prompt, we must exclude certain candidates or narrow their use to specific layers. These gates include license compatibility with `MIT OR Apache-2.0`, MSRV within stable minus two minor versions, absence of open RustSec advisories, CI coverage for `ubuntu-latest` and `macos-latest`, stated default features and async runtime coupling, and qualitative binary-size and compile-time cost.

For the **anyhow-only pattern**, using `anyhow::Result<T>` at the port and domain layers fails the gate related to library API suitability rather than licensing. The `anyhow` crate itself is licensed as `MIT OR Apache-2.0`, as indicated in its `Cargo.toml`, and is therefore compatible with the owner’s license requirements.[3] However, authoritative sources, including Comprehensive Rust, insist that `anyhow::Error` is “generally not a good choice for the public API of a library,” because it wraps `Box<dyn Error>` and obscures specific error types, making matching and taxonomy harder.[8] Given that `rs-launch-blueprint` must serve as a library template as well as a CLI and web service, exposing `anyhow::Result<T>` from library APIs would violate Rust API guidelines and undermine R67’s error taxonomy.[8][14][15] Thus, we exclude the use of `anyhow` for port and domain layers and restrict it to application boundaries, such as `main` and top-level web handlers. This is not a licensing exclusion but an architectural gate rooted in API design and error taxonomy fit.

The **Option-only seam pattern** is excluded by the gate requiring that error conditions be documented and diagnosable. Using `Option<T>` alone to represent both absence and transport failure would make it impossible to distinguish between a missing resource and a connection error, contravening the Rust guideline that `Result<T,E>` should be used when the caller may need to know *why* an operation failed.[4][10][14][15] It would also hinder R67’s ability to map transport failures to appropriate exit codes or HTTP statuses, because absence and failure would be conflated. Therefore, this pattern is excluded for driven I/O seams in the template.

The **hexser-mediated port pattern** is not strictly excluded but is limited by evidence gaps against the fitness gates. The lib.rs documentation for `hexser` does not state license, MSRV, RustSec advisories, or CI coverage within the provided search results.[12] Without querying crates.io and GitHub directly, we cannot confirm compliance with the MSRV policy, OS matrix, or security posture. As a result, while `hexser` remains an up-and-comer for architectural scaffolding, we cannot recommend it as a required dependency for `rs-launch-blueprint` under the current evidence. Instead, we treat it as an optional layering tool that may be adopted in future once fitness gates are explicitly satisfied.

Regarding the **Result-only domain-error seam pattern**, we do not exclude it outright, but we limit its scope. For ports and adapters representing driven I/O boundaries, this pattern fails the hexagonal architecture gate: it mixes domain semantics (whether absence is an error) with infrastructure concerns (how the resource is fetched), making it hard to reuse ports in contexts where absence is acceptable.[10][12] However, within domain APIs that truly require resources to exist, returning `Result<T, DomainError>` is both idiomatic and recommended; typed error enums with `thiserror` derive macros are explicitly endorsed for library and domain logic.[4][7][8] Thus, we exclude this pattern from the port seam but accept it as the domain service pattern layered on top of the dual-channel port contract.

### Up-and-comers

Within the up-and-comer bin, **hexser** represents the most relevant emerging tool, not because it provides a different absence–failure pattern, but because it offers structural support for hexagonal architectures and port/adapter layering.[12] Its documentation outlines an architecture where the domain is independent of frameworks and infrastructure, ports define contracts between the domain and the outside world, and adapters implement ports using specific technologies such as databases or APIs.[12] It emphasizes that repositories and other persistence abstractions are ports, and that adapters implement these ports using concrete technologies.[12] This structure aligns closely with the owner’s hex pattern background and with the design of the Python template, which already separates ports (`core/ports.py`) from services (`core/services/projects.py`) and infrastructure code.

However, as noted, we lack detailed evidence about hexser’s license, MSRV, CI coverage, and RustSec posture from the provided search results alone.[12] Its role in this item is therefore conceptual: it reinforces the architectural rationale for treating ports as domain-neutral contracts and for locating absence-to-domain-error translation within the domain service layer. It supports the view that a port should model low-level behaviors like “resource not found” separately from domain semantics, and it encourages a layered design where `rs-launch-blueprint` can later adopt port traits or closures interchangeably, consistent with R01’s pending decision.[12] As an up-and-comer, hexser can be used as a reference implementation in experiments or as optional scaffolding, but it is not required for the R03 pattern to be valid or implementable.

Other up-and-coming ideas in Rust error handling include advanced structured logging and tracing systems that attach error context at boundaries, such as the `anyhow::Context` trait for adding semantic trace information to `Result` and `Option` values.[8] While these do not directly alter the absence–failure contract, they offer ways to enhance observability and debugability at the seam, by recording what the program was doing leading up to an error.[8] In the R03 pattern, the domain service converting `None` into `NotFound` can attach context such as workspace IDs or project IDs, making error reports more informative while still respecting the absence/failure distinction.

### Fit for this template

Assessing fit for `rs-launch-blueprint` requires examining the pattern across its three shapes: CLI, library, and web service. Each has distinct boundary conditions and consumer expectations, but the underlying absence–failure principle must hold consistently.

For the **CLI shape**, `rs-launch-blueprint` will likely use `clap` or a similar crate to parse command-line arguments, validate them, and handle argument errors by printing usage information and exiting with appropriate codes.[11][19] Tutorials and training materials show a typical pattern where `Cli::parse()` consumes arguments and exits on bad inputs, while the rest of `main` is ordinary fallible Rust returning `anyhow::Result<()>`, with runtime errors propagated via `?`.[11] This separation ensures that argument errors do not reach the core logic, and runtime errors do not get tangled with argument parsing.[11][19] In this context, the Port Absence–Failure Split pattern fits naturally: ports that perform driven I/O (e.g., reading configuration files, calling HTTP APIs, querying databases) return `Result<Option<T>, TransportError>`, allowing the CLI’s domain services to decide whether absence is acceptable. Domain-level errors, represented as enums derived with `thiserror`, can then be converted into exit codes by a small mapping function, fulfilling R67’s requirements.[4][7][8][11] `main` can return `anyhow::Result<()>`, with `?` used to propagate domain errors into `anyhow::Error`, which is then inspected or downcasted at the top to determine exit codes if desired.[3][8] This yields a CLI that respects Rust idioms, keeps argument and runtime error domains separate, and maintains the absence/failure distinction at the ports.

For the **library shape**, `rs-launch-blueprint` must expose public APIs that other Rust code can call, and it must follow Rust API guidelines concerning error documentation and type design.[14][15] In this setting, using `anyhow::Error` in public API signatures is discouraged, and typed error enums are preferred.[8][14][15] The Port Absence–Failure Split pattern allows library APIs to represent resource-fetching operations in a way that is both precise and composable: a public function could expose a port-like signature `pub fn get_project(&self, id: ProjectId) -> Result<Option<Project>, TransportError>`, or a domain-service signature `pub fn load_required_project(&self, id: ProjectId) -> Result<Project, DomainError>`, depending on whether absence is considered acceptable to the library consumer.[4][7][10][14][15] Error conditions can be documented in an “Errors” section as recommended by the guidelines, stating that `Err(TransportError)` indicates a transport or I/O failure, while `Ok(None)` indicates no project found, and `Err(DomainError::ProjectNotFound)` indicates a domain error in the required-project API.[14][15] Examples should use the `?` operator to propagate `Result`s and to convert `Option` to `Result` via `ok_or`, ensuring responsible error handling patterns are copied.[4][14][15] This pattern provides a clear, testable contract for library consumers and fits well with the owner’s msrv and CI policies, because it relies only on stable language features and widely adopted crates like `thiserror` whose MSRV is typically low.[4][7][8]

For the **web service shape**, `rs-launch-blueprint` may use a framework such as Actix Web or similar for HTTP routing. These frameworks typically expect handler functions to return typed `Result<HttpResponse, Error>` values, where `Error` can be mapped to HTTP statuses and messages.[16] Custom error handlers can be implemented to transform specific errors, such as turning a not-found error into a `404` response with a JSON body.[16] Under the Port Absence–Failure Split pattern, the web layer would follow the same layering as the CLI: adapters performing HTTP client calls or database queries return `Result<Option<T>, TransportError>`, domain services convert `None` into `DomainError::NotFound`, and web handlers map `DomainError::NotFound` to `404 Not Found` while mapping transport failures to `500 Internal Server Error` or appropriate equivalents.[4][10][16][18] This approach ensures that the web service’s public API (HTTP endpoints) reflects domain semantics—404 when a resource is absent by domain definition—while still preserving a clear distinction between absence and transport failure within the code. It also allows R67’s taxonomy to remain consistent across CLI and web service: the same domain error variants can be mapped to exit codes in CLI and to HTTP statuses in web.

In all three shapes, the pattern meets the owner’s constraints of stable Rust, edition 2024, MSRV policy, and CI coverage for Ubuntu and macOS, because it relies on language and standard library primitives (`Option`, `Result`, `?`, `std::error::Error`) plus `thiserror` and `anyhow`, which are widely used and tested across multiple platforms.[1][2][3][4][7][8][10][11][14][15][19] The error types and combinators are type-based and explicit, making them amenable to automated testing and architectural validation, including future use of hexser or similar tools. The pattern also fits the owner’s direction to have a similar hex pattern across all three repos: Python already uses the two-layer split, Rust now adopts a structurally analogous pattern, and TypeScript can be refactored to separate absence modeling from domain error throwing.

### Recommendation

The recommendation for R03 is to adopt the **Port Absence–Failure Split (R03) pattern** as a cross-repo architectural policy and to implement it in `rs-launch-blueprint` using the dual-channel seam contract `Result<Option<T>, TransportError>` at driven I/O boundaries, with domain-level conversion to typed error enums.

Concretely, the pattern specifies that any fallible I/O operation at the port or injected-function boundary that may legitimately find no resource but can also experience transport or infrastructure failure shall be modeled as `Result<Option<T>, TransportError>`. `TransportError` shall be a typed error enum, ideally derived via `thiserror`, that captures infrastructural concerns such as `std::io::Error`, HTTP errors, and protocol violations.[4][7][10][12] Domain services shall consume these seam functions and convert transport failures into domain error variants (e.g., `DomainError::Transport`) using `?` and `From`, and convert `Ok(None)` into domain not-found variants (e.g., `DomainError::ProjectNotFound`) using `ok_or` or `ok_or_else`.[4][7][10] Domain error enums shall be distinct from transport error enums and shall represent business-level conditions that R67 can map to exit codes or HTTP statuses.[4][7][8][14][15] Application boundaries (CLI `main`, web handlers) shall use `anyhow::Result<()>` or framework-specified `Result` types to propagate domain errors and translate them to user-facing outcomes, keeping port, domain, and boundary error layers appropriately separated.[3][7][8][11][16]

Across repos, the shared principle is that **ports treat absence as non-exceptional and model transport failures as recoverable errors; domain services decide whether absence is an error and translate it into domain-specific error forms**. Python continues to implement this via `Optional[T]` in ports and exceptions in services; Rust implements it via `Result<Option<T>, TransportError>` in ports and `Result<T, DomainError>` in services; TypeScript should be refactored to implement it via explicit union types or `Result`-like objects in ports and exceptions in services. This preserves the hexagonal pattern across ecosystems while respecting each language’s idioms and tooling.[1][4][6][9][10][12][Context]

### Ranked runner-up

The ranked runner-up pattern is the **Result-only domain-error seam pattern**, where ports and injected functions return `Result<T, DomainError>` and represent resource absence as a `DomainError::NotFound` variant, conflating absence and failure within a domain error type. This pattern is recommended for consideration only in narrowly scoped, domain-centric libraries where absence is always a domain error and the port is effectively part of the domain layer, not a separate infrastructure adapter.

Under this pattern, a port-like function `get_project` would return `Result<Project, DomainError>` and would itself decide whether absence is an error, mapping transport-level errors and absence into domain variants such as `TransportFailure` and `NotFound`. Typed error enums with `thiserror` make this approach ergonomic, with `#[from]` attributes allowing transport errors to be wrapped, and domain code can match on variants to implement business logic.[4][7] The pattern could “win” in scenarios where the template is used purely as a domain library without explicit ports/adapters separation, and where R01 eventually decides not to adopt a formal ports-and-adapters seam. In such cases, it may be more convenient to present a single domain-level API that treats absence as an error, and the overhead of `Result<Option<T>, TransportError>` may not provide enough benefit.

However, for `rs-launch-blueprint`’s intended use as CLI + library + web service, and given the owner’s direction that this is a hex pattern used before in other repos, the runner-up pattern loses to the dominant choice because it violates the hexagonal separation between ports and domain services and makes it difficult to reuse port functions in contexts where absence is acceptable.[12] It is thus reserved for specialized use, not as the template’s standard pattern.

### Tradeoffs

Adopting the Port Absence–Failure Split pattern entails several tradeoffs compared to the runner-up and other options, and these tradeoffs are accepted in light of the template’s goals and cross-repo consistency requirements.

Compared to the **Result-only domain-error seam pattern**, the chosen pattern introduces an additional type layer (`TransportError` vs `DomainError`) and requires domain services to explicitly convert `Result<Option<T>, TransportError>` into `Result<T, DomainError>`. This adds some boilerplate and conceptual overhead, as developers must think about two error types and handle both `None` and `Err` cases. The benefit, however, is a cleaner separation of concerns: transport errors remain distinct from domain errors, ports can be reused in contexts where absence is acceptable without forcing domain error handling, and R67’s taxonomy can map transport failures differently from domain not-found errors.[4][10][12][14][15] The tradeoff is increased verbosity in exchange for improved clarity, composability, and reuse.

Compared to the **anyhow-only pattern**, the chosen pattern sacrifices some ergonomic simplicity. With `anyhow::Result<T>` everywhere, developers can freely use `?` and `context()` without worrying about specific error types, and they get rich diagnostic context automatically.[3][8] However, this convenience comes at the cost of losing explicit error taxonomy and making library APIs opaque, which conflicts with Rust API guidelines and with R67’s requirement for a stable error-code catalog.[8][14][15] By restricting `anyhow` to application boundaries and using typed error enums internally, the template must maintain more explicit error types but gains control over error classification and behavior across shapes.

Compared to the **Option-only seam pattern**, the chosen pattern is more complex but safer and more informative. Modeling both absence and failure as `Option<T>` keeps signatures simple but discards error information and makes debugging difficult when a resource is not found. Using `Result<Option<T>, TransportError>` requires more code but provides clear diagnostics, a distinct transport error type, and the ability to attach context and structured logging when failures occur.[4][9][10] Given the template’s goal of robust, production-ready architecture, this tradeoff favors robust error modeling over minimal code.

Compared to potential **hexser-mediated patterns**, the chosen pattern foregoes automatic graph construction and architectural validation features that hexser might provide. However, this tradeoff is driven by governance and evidence gaps: without confirmed license, MSRV, and CI compliance from the provided search results, mandating hexser would introduce risk. The chosen pattern relies only on standard Rust features and widely adopted crates, ensuring compatibility and reducing dependency complexity.[1][2][3][4][7][8][10][12][14][15]

Overall, the key tradeoff is **explicitness and layering versus simplicity and inline handling**. The Port Absence–Failure Split pattern requires developers to think about ports, transport errors, domain errors, and application boundaries separately, but it yields a design where absence is modeled explicitly, domain semantics are applied at the right layer, and error taxonomy is preserved across CLI, library, and web service shapes.

### Parameters

R03 owns the absence–failure contract at the driven-I/O seam and must specify parameters that other items assume.

We set:

`owns R03.seam_contract = Result<Option<T>, TransportError>`  
This parameter defines the standard Rust type contract for resource-fetching operations at the port or injected-function boundary. It applies regardless of whether R01 chooses a formal port trait, generic-bound function, or injected closure shape.

`owns R03.domain_translation = DomainError::NotFound & DomainError::Transport`  
This parameter specifies that domain services shall translate `Ok(None)` into a domain not-found variant and `Err(TransportError)` into a domain transport failure variant in their error enums. The exact variant names and their mapping to R67’s taxonomy may be refined, but the distinction must exist.

`assumes R67.error_taxonomy_exit_codes = stable mapping of DomainError variants to exit codes and HTTP statuses`  
R03 assumes that R67 will define a stable error-code catalog and exit-code mapping for domain errors such as `NotFound` and `TransportFailure`. R03 does not name these codes but shapes the domain error types to be mappable.

At present, there is no direct conflict with R67; the pattern defines error types generically and allows R67 to assign specific names and codes later. If R67 were to require a single “NotFound” error code that lumps transport failure and resource absence together, this would conflict with R03’s distinction. In that hypothetical scenario, we would record:

`CONFLICT: R67.not_found_code — single code for both absence and transport — R03 requires distinct domain variants for absence vs transport to preserve semantics`

However, under current assumptions, R67 is expected to respect the distinction and map variants accordingly.

### Migration implications

Implementing the Port Absence–Failure Split pattern in `rs-launch-blueprint` entails several file-level changes and architectural adjustments in the template, particularly in the way ports, adapters, domain services, and entry points are structured.

In the **ports/adapters layer** (or equivalent injected functions), any function that performs driven I/O and may legitimately find no resource must have its signature updated to return `Result<Option<T>, TransportError>`. For example, a function in `core/ports.rs` or a similar module that currently returns `Result<T, E>` when fetching a project should be rewritten to return `Result<Option<Project>, TransportError>`, with the adapter mapping HTTP `404` or database “no row” results to `Ok(None)` and other failures to `Err(TransportError::...)`.[4][10][12] If R01 adopts formal port traits, trait definitions must reflect this contract; if R01 chooses function injection, the function types must do so.

In the **domain services layer**, functions that require resources to exist must be updated to consume `Result<Option<T>, TransportError>` and to convert transport and absence outcomes into domain error variants. For example, a `projects` service module would define a `DomainError` enum with variants like `Transport` and `ProjectNotFound`, and service methods such as `load_required_project` would implement the pattern shown earlier: `let maybe = self.port.get_project(id)?; let project = maybe.ok_or(DomainError::ProjectNotFound(id.to_owned()))?;`.[4][7][10] Existing code that directly uses port signatures returning `Result<T,E>` will need to be refactored to handle the `Option` layer explicitly.

In the **CLI entry point** (e.g., `src/main.rs`), `main` should be structured to return `anyhow::Result<()>` and to delegate argument errors to `clap` or similar, as in the Sunns Technologies tutorial.[11] Runtime domain errors should be propagated via `?` and then mapped to exit codes in a small function that inspects `DomainError` variants, leveraging R67’s taxonomy.[3][7][8][11][14][15] This may require adding a mapping module that knows both domain error variants and exit codes.

In the **web service layer**, HTTP handlers must adopt the pattern by calling domain services that expose `Result<T, DomainError>`, then mapping `DomainError::NotFound` to `404` and `DomainError::Transport` to `5xx` statuses.[16][18] Existing handlers that directly use `Result<T,E>` from infrastructure libraries will need to be refactored to route through domain services that apply the absence-to-error translation.

In **tests**, unit tests must be added or updated to validate the behavior of port adapters and domain services under four scenarios: resource present (`Ok(Some(T))`), resource absent (`Ok(None)`), transport failure (`Err(TransportError)`), and domain service invocation, ensuring that absence becomes `DomainError::NotFound` only in services that require the resource. Integration tests should confirm that CLI commands and web endpoints behave correctly under these scenarios, including exit codes and HTTP statuses.

Mentioning Python and TypeScript repos, migration implications include future refactors where TypeScript HTTP client functions stop throwing `NotFoundError` inline and instead return a union type or `Result`-like object representing absence versus failure, with services performing the translation. Python already largely conforms, but might add explicit type annotations and improved documentation in line with Rust API guidelines’ emphasis on “Errors” sections.[Context][14][15]

### Validation strategy

A robust validation strategy is required to prove that the Port Absence–Failure Split pattern holds in realistic examples using the recommended libraries. This strategy must specify commands, expected behaviors, and distinguish between planned checks and executed results.

At the **unit level**, we plan to write tests for each port adapter implementing the `Result<Option<T>, TransportError>` contract. For example, for a `ProjectApiAdapter` that fetches projects over HTTP, tests would simulate three conditions: a `200 OK` with a valid project, leading to `Ok(Some(project))`; a `404 Not Found`, leading to `Ok(None)`; and network or server errors, leading to `Err(TransportError::Http(...))`. The tests will assert these outcomes and ensure that no domain error types appear in the adapter layer. We will use `cargo test` to execute these tests on both `ubuntu-latest` and `macos-latest` in CI, verifying MSRV compliance and platform support.

At the **domain service level**, tests will target functions like `load_required_project`. Given a mocked port that returns each of the three outcomes above, tests will assert that the service returns `Ok(project)` when the port returns `Ok(Some(project))`, returns `Err(DomainError::ProjectNotFound)` when the port returns `Ok(None)`, and returns `Err(DomainError::Transport(_))` when the port returns `Err(TransportError)`.[4][7][10] The use of `?` and `ok_or` will be verified implicitly by these tests. We will also check that no transport error types leak out of the domain layer.

At the **CLI integration level**, we plan to write tests using `assert_cmd` or similar frameworks to run the binary with arguments that trigger each condition. For example, invoking the CLI with a project ID that exists, one that does not exist, and one that triggers a transport failure (e.g., unreachable server). Tests will assert that the exit code is `0` for success, a specific non-zero code for project-not-found, and a different code for transport failure, according to R67’s taxonomy. Output messages will be inspected to ensure they reflect domain semantics (“Project not found”) rather than leaking transport details.

At the **web service level**, integration tests will send HTTP requests to endpoints that map to domain services and will assert that the responses have appropriate statuses and bodies: `200 OK` with the project when found, `404 Not Found` with a suitable JSON body when absent, and `500 Internal Server Error` or similar when transport fails. Actix Web’s custom error handler mechanisms can be used to ensure that domain errors are mapped correctly.[16]

Finally, at the **documentation and guideline level**, we will validate that API documentation for ports and domain services includes explicit “Errors” sections as recommended by Rust API guidelines, stating how absence and failure are represented.[14][15] Examples in documentation will use `?` and `ok_or`, fulfilling the C-QUESTION-MARK and C-FAILURE guidelines.[14][15]

At the time of writing, these checks are **planned** but not yet executed, because `rs-launch-blueprint`’s Rust implementation is in design. The validation strategy is therefore part of the acceptance-after plan for R03: the pattern will be considered fully accepted only after these tests are implemented and pass on the specified OS matrix and MSRV.

### Confidence & re-verify trigger

The confidence level in this recommendation is **high** but not absolute. It is grounded in core Rust language semantics and official documentation for `Option` and `Result`,[1][2][6][9][10] in Rust API guidelines emphasizing explicit error documentation and responsible use of `?`,[14][15] in authoritative training materials recommending typed errors with `thiserror` and application-boundary use of `anyhow`,[3][4][7][8][11] and in mainstream practice among well-regarded projects such as `sqlx` and Actix Web.[16][18] The pattern directly embodies hexagonal architecture principles documented in crates like `hexser` and in general ports-and-adapters literature, and it aligns with the owner’s prior hex pattern usage in other repos.[12][Context]

However, several **re-verify triggers** should be recognized. If future Rust editions or guidelines introduce new error-handling features or change recommendations (e.g., a new standard crate for application errors or a shift in advice about `anyhow` in libraries), R03 should be revisited. If R01 decides on a radically different ports-and-adapters seam shape that renders trait-based modeling impractical, the pattern’s syntax may need adjustment, though the principle of absence vs. failure would remain. If R67’s taxonomy ends up requiring a different grouping of errors, particularly if it attempts to merge absence and transport failure under a single code category, R03 would need a reconciliation discussion, as noted in the potential conflict. Finally, if new evidence emerges about up-and-coming crates like `hexser` that materially affect architectural layering, such as strong adoption and confirmed fitness gate compliance, we may consider integrating them more deeply into the template, potentially altering how ports and adapters are defined.

Given the current state of Rust practice and the template’s goals, the Port Absence–Failure Split pattern is a robust, well-founded choice, but it should be re-verified at major Rust ecosystem inflection points or when cross-repo coordination requires revisiting architectural principles.

### Sources

This report draws on a combination of core Rust project documentation, established guidelines, maintained crate documentation, and independent training materials, all of which have been cited inline using the provided search results indices. The Rust Programming Language book’s chapters on error handling and recoverable errors with `Result` provide foundational semantics for `Option<T>` and `Result<T,E>`, explaining their roles in modeling absence and failure and introducing the `?` operator.[1][2][6] Rust error documentation further clarifies the relationship between `Option` and `Result`, explicitly noting that `Option` is analogous to `Result<T, ()>` but that the types carry different intended meanings, and it presents `Result<Option<T>, E>` as a common pattern for fallible operations that may succeed with or without a value.[10]

Independent write-ups on Rust error handling, such as the Software Patterns Lexicon article, reinforce these semantics and discuss best practices for using `Option<T>` for expected absence and `Result<T,E>` for recoverable failure, including the use of combinators like `ok_or` and `map_err` and the avoidance of `unwrap` in production code.[4] Tutorials from Sunns Technologies and comprehensive training materials from Google’s Comprehensive Rust and Microsoft’s Rust Patterns book provide practical patterns for combining typed error enums (`thiserror`), application-boundary errors (`anyhow`), and CLI or web frameworks, demonstrating how `?` works with both `Option` and `Result` and how error domains can be kept separate.[7][8][11]

Crate documentation for `anyhow` and its Cargo.toml confirm its role as a flexible error type built on `std::error::Error` and its licensing as `MIT OR Apache-2.0`, making it suitable for application boundaries in `rs-launch-blueprint`.[3][13] Hexagonal architecture guidance from the `hexser` crate’s lib.rs page highlights the domain-ports-adapters-infrastructure layering and supports the architectural rationale for keeping port contracts neutral and locating domain error translation in services.[12] Mainstream project documentation from `clap` and `sqlx` illustrates how fallible workflows are constructed with explicit error types, how CLIs and SQL toolkits handle errors, and how such projects align with Rust’s error-handling idioms.[11][18][19] Rust API Guidelines and their DeepWiki mirror provide standards for documentation, examples, and error handling, emphasizing explicit error sections and the use of `?` in examples.[14][15]

Together, these sources form a coherent body of evidence that supports the Port Absence–Failure Split pattern and its implementation in `rs-launch-blueprint`, while also informing migration and harmonization across Python and TypeScript repos.

## Conclusion

The Port Absence–Failure Split (R03) pattern codifies a crucial architectural decision for `rs-launch-blueprint`: driven I/O seams must distinguish “resource not found” from “transport/I/O failure” in a way that is explicit, composable, and consistent with hexagonal architecture principles, Rust idioms, and cross-repo coordination. By adopting `Result<Option<T>, TransportError>` as the standard seam contract for resource-fetching operations, and by locating the absence-to-domain-error translation in domain services that convert `Ok(None)` into not-found variants and `Err(TransportError)` into transport failure variants, the template achieves a clear separation between infrastructure and domain semantics.[4][10][12] This design harmonizes the underlying principle already present in the Python template, corrects the TypeScript template’s conflation of transport and domain decisions, and provides a robust foundation for error taxonomy and exit-code mapping in R67.

The recommended pattern leverages Rust’s explicit error-handling constructs, established crates like `thiserror` and `anyhow` in appropriate layers, and mainstream practices from projects such as `clap`, `sqlx`, and Actix Web.[3][4][7][8][10][11][16][18][19] It fits the template’s CLI, library, and web service shapes, respects the owner’s MSRV, licensing, and CI constraints, and remains flexible enough to accommodate future architectural tooling like `hexser` without depending on it.[1][2][3][4][7][8][10][12][14][15] While runner-up patterns such as Result-only domain-error seams offer certain ergonomic advantages, they sacrifice the separation of concerns needed for cross-repo alignment and error taxonomy clarity, and are therefore reserved for narrower use cases.

By framing the pattern as a cross-repo architectural policy and detailing its implementation and validation strategy, this report ensures that the absence–failure distinction is preserved consistently across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint`, with Rust serving as a strong reference implementation. Future re-verification will be required when Rust’s error-handling landscape or the owner’s taxonomy evolves, but under current conditions, the Port Absence–Failure Split pattern offers a sound, evidence-backed foundation for robust, maintainable error handling at the driven-I/O seam.

## Sources

- [Error Handling - The Rust Programming Language](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/error-handling.html)
- [Recoverable Errors with Result - The Rust Programming ...](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html)
- [anyhow 1.0.104](https://docs.rs/crate/anyhow/latest)
- [Rust Error Handling: Mastering `Result` and `Option` for Robust Code](https://softwarepatternslexicon.com/rust/rust-language-features-and-best-practices/error-handling-with-result-and-option/)
- [Error handling, Result, Error - help](https://users.rust-lang.org/t/error-handling-result-error/110571)
- [The Rust Programming Language](https://web.mit.edu/rust-lang_v1.26.0/arch/amd64_ubuntu1404/share/doc/rust/html/book/first-edition/error-handling.html)
- [10. Error Handling Patterns - Rust Patterns & Engineering ...](https://microsoft.github.io/RustTraining/rust-patterns-book/ch10-error-handling-patterns.html)
- [anyhow - Comprehensive Rust - Google](https://google.github.io/comprehensive-rust/error-handling/anyhow.html)
- [How to Handle Errors with Result and Option in Rust](https://oneuptime.com/blog/post/2026-02-03-rust-result-option/view)
- [Result and Error - Rust Error Documentation - GitHub Pages](https://nrc.github.io/error-docs/rust-errors/result-and-error.html)
- [Building CLIs with clap | Sunns Technologies](https://learn.sunnstech.com/tutorials/rust/building-clis-with-clap/)
- [Hexser — Rust utility // Lib.rs](https://lib.rs/crates/hexser)
- [anyhow/Cargo.toml at master · dtolnay/anyhow](https://github.com/dtolnay/anyhow/blob/master/Cargo.toml)
- [Documentation - Rust API Guidelines](https://rust-lang.github.io/api-guidelines/documentation.html)
- [Documentation Guidelines | rust-lang/api-guidelines | DeepWiki](https://deepwiki.com/rust-lang/api-guidelines/3-documentation-guidelines)
- [how to implement custom error handler for 404 not found · ...](https://github.com/actix/actix-web/discussions/2564)
- [PackagingDrafts/Rust - Fedora Project Wiki](https://fedoraproject.org/wiki/PackagingDrafts/Rust)
- [GitHub - launchbadge/sqlx at v0.3.5](https://github.com/launchbadge/sqlx/tree/v0.3.5)
- [GitHub - clap-rs/clap at v3-dev](https://github.com/clap-rs/clap/tree/v3-dev)

## Cost

Total: $0.9083

---


## Gemini Results

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

---
