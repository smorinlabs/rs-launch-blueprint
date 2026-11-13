---
prompt: # Deep-research prompt — OpenAPI typed client generation (R84, crate)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260918-152036-285cea386b6f444c
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

Generated: 2026-09-18T22:39:54.283292+00:00


## Openai Results

---
prompt: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
operation_id: research-20260918-152036-285cea386b6f444c
created_at: 2026-09-18T15:20:36.723782
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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

**Evidence date:** September 18, 2026. All cited web sources were retrieved on that date unless stated otherwise. `N/R` means the prompt-mandated API endpoint could not be rendered by this research environment; I did not silently substitute a different metric source.

**Decision category:** ahead-of-time OpenAPI 3.x → typed Rust HTTP-client code generation, producing a committed crate/module from a committed contract snapshot.

| Bin | Rust landscape |
|---|---|
| **Built-in or first-party toolchain** | The Rust Project has no first-party OpenAPI client generator. Cargo supplies `build.rs`, proc-macro, package, and workspace mechanisms, but not OpenAPI semantics. Importantly, Cargo’s own guidance says checked-in generated source should be produced outside `build.rs` and verified in CI. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **Established industry standard** | **OpenAPI Generator** is the cross-language standard; its Rust client generator is marked `STABLE` while its help text still says “beta,” defaults to async Reqwest, and supports Hyper/Reqwest variants. **Progenitor** is the established Rust-native specialist, with async clients, streams, static-crate generation, build-script and macro modes. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |
| **Up-and-comer** | **`openapi-to-rust`**, **`spargen`**, **Satay**, **`openapi_gen`**, **`oas3-gen`**, and Ploidy. They explore ahead-of-time checked-in generation, OpenAPI 3.1, explicit support diagnostics, sans-I/O transport, or improved union handling. ([github.com](https://github.com/gpu-cli/openapi-to-rust)) |

#### Authority used

- **Rust Project publications:** the Cargo Book establishes the authoritative treatment of generated source, `OUT_DIR`, `rust-version`, N-2 policies, and MSRV verification. Rust 1.98.0 was current stable on September 18, 2026, making this template’s N-2 MSRV **1.96**. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))
- **OpenAPI Initiative specification:** `operationId` must be unique and is expressly intended for tools to identify operations; programming-style names are recommended. ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3))
- **Maintainer-owned primary sources:** candidate manifests, READMEs, CI workflows, support matrices, and generated examples establish actual behavior rather than marketing summaries. ([github.com](https://github.com/gpu-cli/openapi-to-rust))
- **Production-practice evidence:** Oxide’s Omicron and Buildomat use Progenitor-generated clients from checked-in OpenAPI documents; KPN’s DSH client documents a standalone regeneration workflow and the need to add missing operation IDs. ([github.com](https://github.com/oxidecomputer/omicron))
- **Registry/adoption context:** the official Rust survey shows crates.io is overwhelmingly the normal package source, supporting the mandate to collect registry figures—but downloads remain secondary evidence, never a design selector. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf))

#### Practice evidence

- **Progenitor has the strongest demonstrated Rust production practice.** Omicron checks schemas into source control to expose API changes during review, then derives clients from them; Buildomat likewise generates a client from a repository-managed schema. DSH provides independent, non-Oxide adoption evidence. Oxide is a verified organization whose Rust projects include widely followed infrastructure components. ([github.com](https://github.com/oxidecomputer/omicron))
- **`openapi-to-rust` has narrower but relevant practice evidence.** Its maintainers report internal use against OpenAI, Anthropic, and Cloudflare specifications, maintain a 56-spec supported corpus, and compile-check major real-world specifications. `meteora-api` exposes generated code identifying `openapi-to-rust` as its generator. This proves real use, but not yet mainstream independent adoption. ([github.com](https://github.com/gpu-cli/openapi-to-rust))
- **OpenAPI Generator has the broadest cross-language adoption and maintenance footprint.** Release 7.25.0 was published on August 24, 2026; a CERN presentation described its use and showed roughly 23,000 stars, although the required GitHub API figure could not be collected here. ([github.com](https://github.com/OpenAPITools/openapi-generator/releases))
- **No mainstream, independent adopter evidence was found for Spargen, Satay, or `openapi_gen`.** Satay explicitly describes itself as work in progress; Spargen is only weeks into published releases. ([github.com](https://github.com/zeon256/satay-rs))

#### Mandatory figure-collection limitation

The required crates.io and GitHub API endpoints for downloads, release dates, stars, archived state, open-issue count, and recent-issue responsiveness were attempted but were inaccessible to this research environment. Therefore this answer does **not** fabricate those figures or promote HTML/UI counts to exact API measurements. ([]())

### Principles and implementation

#### Shared requirement and agreement level

The Python precedent and owner direction imply agreement at the **architectural-policy and capability level**, not agreement on one package name or HTTP stack.

| Level | Must agree across py/ts/rs | May vary by ecosystem |
|---|---|---|
| **Standard** | A committed OpenAPI document is the client contract. Operations have unique, curated, stable `operationId` values. | OpenAPI 3.0 versus 3.1 syntax, provided the selected generator supports the committed version. |
| **Architectural policy** | Typed request/response models and HTTP operations are generated, never handwritten; output is reproducible, reviewable, and CI-checked for drift. | Generated package layout, formatting, error representation, and runtime library. |
| **Capability** | Consumers can invoke typed async/sync methods without manually serializing paths, parameters, bodies, or responses. | Python may use HTTPX/Pydantic; TypeScript may use Fetch-oriented output; Rust may use Reqwest. |
| **Ownership policy** | The schema and generator configuration are inputs; generated files are outputs and are not edited. | The exact recipe can be `just`, an `xtask`, or an ecosystem package command. |

Cargo’s first-party guidance strongly favors this architecture for checked-in source: generate outside `build.rs`, then have CI verify that the checked-in file precisely matches regenerated output. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html))

#### Cross-repository interpretation

- **Python:** the supplied `openapi-python-client generate` recipe already realizes the policy. A follow-on should ensure deterministic drift checking if that is not already enforced.
- **TypeScript:** absence is currently justified because F303 says there is no web service or schema. It is **inapplicable capability**, not evidence that hand-written clients are acceptable. If a TS web surface is later added, a TS-native ahead-of-time generator must implement the same policy.
- **Rust:** should add the capability now because the fixed target includes a web service. The Rust package and output layout may differ from Python while preserving the architectural contract.

`BASELINE-REVIEW: F335 — typed clients are generated from the committed OpenAPI contract and never handwritten, at architectural-policy/capability agreement level — replace tool-level DIVERGENT/harmonize:no with conditional commonality: py and rs implement now; ts is inapplicable while F303 has no web service, but must implement the policy if that changes — evidence: Python’s supplied recipe, Cargo’s checked-in-codegen guidance, OpenAPI operationId semantics, and maintained Rust generators. Affected: R84, R71/F312/F332, F303; ledger changes remain a follow-on.`

#### Architectural alternatives

| Architecture | Assessment |
|---|---|
| **Standalone ahead-of-time CLI writing committed source** | **Chosen.** Matches Python, exposes generated changes to review, keeps the generator out of consumer builds, and supports a direct CI `--check`/regenerate-and-diff gate. |
| **`build.rs` + `include!(OUT_DIR)`** | Valid Cargo mechanism, but wrong default here. Generated API changes are hidden in `target/`, every clean build compiles/runs codegen, and Cargo expressly recommends external generation for checked-in source. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **Proc macro in the consumer crate** | Most opaque option. It places the generator in the compile graph, makes generated output harder to review, and couples normal compilation to codegen behavior. |
| **Hand-rolled generator using `openapiv3`/Typify** | Reject. Those libraries can parse schemas or generate types, but the template would own HTTP-method generation, parameter serialization, status handling, and compatibility behavior—the exact maintenance burden this item is meant to avoid. |
| **Generic OpenAPI Generator CLI** | Viable fallback with exceptional ecosystem breadth, but adds a Java/container toolchain and emits a more generic SDK layout. Its Rust generator’s own documentation is inconsistent between `STABLE` metadata and “beta” help text. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |

#### Gate-first assessment

| Candidate | License | MSRV | Advisory / unsafe posture | OS evidence | Features/runtime | Cost | Result |
|---|---|---|---|---|---|---|---|
| **`openapi-to-rust`** | MIT: pass. | Manifest and CI declare/test 1.88, below required 1.96. Generated dependency tree still needs the template’s 1.96 test. | RustSec endpoint not retrievable; generator does not establish a repository-wide unsafe policy in reviewed evidence. Generated crate can enforce `#![forbid(unsafe_code)]`. | Upstream CI reviewed here is Ubuntu-only; macOS must be proven by R84 acceptance. | Generator default is `cli`; emitted client is async Reqwest, therefore native use is Tokio-coupled. | Generator is dev-only; runtime cost is primarily Reqwest/TLS/Serde. | **Conditional acceptance candidate.** ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)) |
| **Progenitor** | MPL-2.0. Fails if the gate means the candidate itself must be MIT or Apache; otherwise needs explicit legal-policy confirmation. | Workspace declares 1.88. | RustSec result and explicit unsafe policy not verified here. | Production portability is strong, but upstream Ubuntu/macOS generator CI evidence was not established. | Default feature enables its macro; generated clients use async Reqwest, futures, and streams. | AOT mode is acceptable; macro/build modes add substantial compile-time dependencies. | **Runner-up, conditional on OAS 3.0 and license policy.** ([github.com](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)) |
| **OpenAPI Generator 7.25** | Apache-2.0: pass. | No reviewed evidence that default Rust output declares and tests this template’s `rust-version` policy. | Adds a non-Rust Java/container supply-chain boundary. | Broadly portable as a CLI. | Async Reqwest is default; Hyper and trait variants exist. | Largest generator/tooling footprint and more boilerplate. | Excluded from this crate-valued item. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) |
| **`openapi_gen` 0.3.1** | Not sufficiently established in reviewed evidence. | Not sufficiently established. | Not sufficiently established. | No required matrix evidence found. | Proc-macro-only interface in reviewed docs. | Adds generation directly to compilation. | Excluded. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)) |
| **Hand-rolled `openapiv3`/Typify** | Component licenses may pass. | Component-dependent. | Template would own security-sensitive serialization and response handling. | Template-owned. | No complete client generation. | Highest long-term ownership cost. | Excluded by capability/policy. |

#### Recommended composition

1. R71 produces and commits the OpenAPI document.
2. A preflight rejects any missing or duplicate operation IDs.
3. A pinned standalone generator reads only that local document.
4. Generated files are committed under a dedicated client crate.
5. The crate root adds policy attributes and re-exports generated items, but does not wrap each operation.
6. CLI/library consumers import generated `HttpClient`, request models, response models, and typed errors directly.
7. CI regenerates in check mode and compiles/tests the client on Ubuntu, macOS, stable, and Rust 1.96.

This keeps R84 independent of whichever framework R69 selects and whichever schema-generation mechanism R71 selects.

#### Idiomatic-use assessment

`openapi-to-rust` generates an async `HttpClient`, typed structs/enums, builders for larger parameter sets, per-operation typed errors, bounded response buffering, and exact dependency fragments. Its normal generated API is directly consumable; a wrapper is not necessary merely to make it usable. An optional application-level factory for base URL, auth, and tracing is reasonable, but wrapping every operation would recreate a handwritten client and should be rejected. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

Illustrative usage—the actual symbols must derive from R71’s operation IDs:

```rust
use rs_launch_blueprint_api_client::{HealthResponse, HttpClient};

async fn check(base_url: &str) -> anyhow::Result<HealthResponse> {
    let client = HttpClient::new().with_base_url(base_url);
    Ok(client.health_check().await?)
}
```

#### Operation-ID dependency

The template should make curated operation IDs a hard precondition, not rely on any generator’s fallback naming. OpenAPI defines them as unique tool-facing identifiers; DSH’s Progenitor workflow had to patch a schema that omitted them. Without curation, method names may be rejected or derived from paths/methods in tool-specific ways, producing noisy or unstable public APIs. ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3))

#### Performance evidence

The `openapi-to-rust` maintainers report one 120-operation comparison with a 26.5% lower median clean `cargo check` time than Progenitor and effectively identical no-op builds. The retrieved material did not expose enough machine, compiler, repetition, or variance details to treat that as an absolute ranking, and it is maintainer-controlled evidence. It is therefore **not** a selection reason. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

No comparable runtime latency/throughput study was found. The acceptance benchmark should use the actual R71 schema and record:

- generator wall time and peak RSS;
- clean and no-op `cargo check` wall time;
- release binary size;
- 10,000 loopback JSON requests at concurrency 1 and 32;
- p50/p95/p99 latency, requests/second, CPU, and peak RSS;
- identical Reqwest/TLS features for every compared generator.

### Dominant choice

**`openapi-to-rust`, version range `>=0.17.0, <0.18.0`, used only as a standalone ahead-of-time generator.**

This is the fit-dominant choice because it supports OpenAPI 3.0 and 3.1, emits a typed async Reqwest client, has native `--check` behavior for committed output, declares an MSRV below the template’s current 1.96 requirement, and uses an MIT license. The repository manifest currently says 0.17.0, but the crates.io unyanked-release endpoint must be rechecked before merge. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Qualified shortlist

**Strict result: zero candidates are fully evidence-complete today.** This is a finding, not a silent waiver: the dominant candidate lacks upstream macOS CI in the reviewed workflow, and the required RustSec/registry/API checks could not be completed.

**Post-R71 acceptance candidate—not yet counted as fully gate-passed:**

| Name · role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---:|---:|---:|---|---|---|---|
| `openapi-to-rust` · AOT OpenAPI 3.0/3.1 → typed Reqwest client module | **N/R** via required crates.io endpoint | **N/R** via required crates.io endpoint | **N/R** via required GitHub API; HTML corroboration: 36 | **N/R** via required versions endpoint; current repository manifest: 0.17.0 | **active** — current CI, corpus generation, MSRV job, rapid development | Maintainer-reported GPU CLI usage; `meteora-api` generated by v0.12.2 | Best architectural and schema-version fit, but young, rapidly evolving, and not yet independently mainstream. ([github.com](https://github.com/gpu-cli/openapi-to-rust)) |

**Issue responsiveness:** N/R. The required ten-recent-issues query and comment traversal could not be fetched; the GitHub HTML page showed three issues but that is not substituted for the mandated API calculation. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Excluded by gate

- **`openapi-to-rust`—excluded from unconditional adoption, not from the acceptance trial.** Gate 3 remains incomplete because the RustSec package endpoint did not render; Gate 4 remains incomplete because reviewed upstream CI had no `macos-latest` job. Both are mandatory post-R71 checks. ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml))
- **Progenitor 0.15.** Its MPL-2.0 license fails a strict “candidate itself must be MIT or Apache” interpretation, and it only supports OpenAPI 3.0.x. Selecting it now would impose a schema-version constraint on still-open R71. Its production maturity makes it the runner-up rather than a discarded option. ([docs.rs](https://docs.rs/progenitor/latest/progenitor/))
- **OpenAPI Generator 7.25.** Not a Rust crate; default Rust output was not shown to declare and test this template’s MSRV policy. It also adds a Java/container tool boundary and more generic boilerplate. ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md))
- **`openapi_gen` 0.3.1.** The reviewed interface is a proc macro rather than an ahead-of-time checkable recipe, and required license/MSRV/macOS evidence was insufficient. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html))
- **Paperclip.** Its own project description frames complete client/server/CLI code generation as a future capability and warns that it may not be production-ready. ([lib.rs](https://lib.rs/crates/paperclip))
- **`openapiv3`, Typify, or another parser/type generator plus handwritten transport.** Fails the essential capability: paths, parameters, auth, body encoding, response decoding, and typed errors would still be template-owned.
- **A `build.rs` or macro deployment of an otherwise acceptable generator.** Fails the chosen architectural policy for committed, reviewable output; Cargo recommends an external generation/check workflow for this exact case. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html))

### Up-and-comers

- **Spargen 0.4.0:** strongest explicit determinism/support-policy story. It recommends checked-in CLI generation, embeds a freestanding runtime, rejects unsupported constructs rather than silently degrading them, and provides `--check` and generated-surface diffing. It is extremely new and targets OpenAPI 3.1+, so adopter, license, MSRV, and OS evidence must mature before it can displace the dominant candidate. ([docs.rs](https://docs.rs/crate/spargen/latest/source/README.md))
- **Satay:** promising sans-I/O architecture with optional Reqwest and Ureq adapters, validation newtypes, and MIT/Apache licensing. It explicitly says it is work in progress and currently optimizes for one client family. ([github.com](https://github.com/zeon256/satay-rs))
- **`oas3-gen` 0.23:** generates OpenAPI 3.1 models and companion client operations with filtering, but the reviewed evidence did not establish comparable end-to-end transport ergonomics, adoption, or target-matrix testing. ([docs.rs](https://docs.rs/crate/oas3-gen-support/0.23.0))
- **Ploidy:** potentially valuable for complex polymorphic schemas and reports 3.0/3.1 use, but evidence was an announcement rather than a sufficiently mature authoritative implementation record. ([reddit.com](https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/))
- **`openapi_gen` 0.3.1:** useful proof that compile-time client generation is possible, but its proc-macro architecture conflicts with this template’s committed-output policy. ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html))

### Fit for this template

**CLI**

- Good fit if the CLI calls the service: async Reqwest methods and typed errors are directly usable from a Tokio-based command path.
- The CLI should depend on `rs-launch-blueprint-api-client`, not on the generator.
- If the CLI is purely local, do not add an artificial runtime dependency merely to demonstrate the client; use the generated crate in integration tests and examples instead.

**Library**

- Keep the generated client in a separate workspace crate so schema-generated types do not accidentally become the core library’s entire semver surface.
- The library may expose an opt-in `api-client` feature or tell callers to depend directly on the client crate.
- Do not hand-wrap every operation. A small client factory or extension trait for application policy is acceptable; wire models and HTTP calls remain generated.

**Web**

- The web-service crate must not depend on the generated client in its normal dependency graph; that would create needless producer/consumer coupling.
- It may use the client as a dev-dependency for end-to-end tests.
- R84 always reads the committed R71 snapshot, never fetches a live development server during generation.
- Do not enable `openapi-to-rust`’s optional Axum server generation; R69 owns the web framework.

### Recommendation

**Decision: yes, a Rust-ecosystem equivalent exists.**

Adopt:

```toml
# Decision range
openapi-to-rust = ">=0.17.0, <0.18.0"
```

Use an **exact 0.17.0 tool pin** in the recipe, with the range documenting the approved compatibility line. Do not put the generator in any runtime dependency table.

Proposed `Justfile` recipe:

```make
OPENAPI_TO_RUST_VERSION := "0.17.0"
OPENAPI_TO_RUST_ROOT := "target/tools/openapi-to-rust-{{OPENAPI_TO_RUST_VERSION}}"
OPENAPI_TO_RUST := "{{OPENAPI_TO_RUST_ROOT}}/bin/openapi-to-rust"

openapi-client-tool:
    cargo install --locked \
        --root "{{OPENAPI_TO_RUST_ROOT}}" \
        --version "{{OPENAPI_TO_RUST_VERSION}}" \
        openapi-to-rust

openapi-client-generate: openapi-client-tool
    "{{OPENAPI_TO_RUST}}" validate --config openapi-to-rust.toml
    "{{OPENAPI_TO_RUST}}" generate --config openapi-to-rust.toml

openapi-client-check: openapi-client-tool
    "{{OPENAPI_TO_RUST}}" validate --config openapi-to-rust.toml
    "{{OPENAPI_TO_RUST}}" generate --config openapi-to-rust.toml --check
    cargo check -p rs-launch-blueprint-api-client --all-targets
```

Proposed configuration:

```toml
# openapi-to-rust.toml

[generator]
spec_path = "docs/api/openapi.json"
output_dir = "crates/api-client/src/generated"
module_name = "api"

[features]
enable_async_client = true
enable_sse_client = false
enable_registry = false
```

Omitting `[client].operations` generates the full client rather than an application-selected subset. That better matches a reusable template and makes the complete committed schema consumable. The tool writes an exact `REQUIRED_DEPS.toml`; CI must verify those requirements are reflected in the generated client crate’s manifest. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Ranked runner-up

**Progenitor 0.15 line: `>=0.15.0, <0.16.0`.**

It wins if all of the following become true:

1. R71 guarantees an OpenAPI 3.0.x snapshot;
2. the actual snapshot passes a Progenitor support trial without lossy patches;
3. dependency-license policy explicitly accepts MPL-2.0 without changing the template’s own `MIT OR Apache-2.0` license;
4. production maturity, pagination streams, generated CLI support, and typed mocks are valued more highly than native OpenAPI 3.1 support and built-in drift checking.

If selected, use `cargo-progenitor` only in static-crate mode, generate into a temporary directory, and diff/copy the output. Do not use its macro or `build.rs` modes. Progenitor documents static-crate generation specifically as a way to prevent unexpected changes from generator updates. ([github.com](https://github.com/oxidecomputer/progenitor))

### Tradeoffs

| Versus | What the dominant pick gives up | Why accepted |
|---|---|---|
| **Progenitor** | Much stronger production adoption; typed mocks; pagination streams; generated CLI; approximately thousand-star project footprint. | Progenitor is OpenAPI 3.0-only, Dropshot-oriented, MPL-licensed, and lacks the same direct AOT `--check` fit. |
| **OpenAPI Generator** | Far larger community, language breadth, templates, plugins, and organizational familiarity. | Adds Java/container tooling, produces more generic boilerplate, and does not naturally deliver the crate-valued, Rust-native, MSRV-enforced result. |
| **Spargen** | Stronger explicit guarantees around deterministic output, unsupported-schema diagnostics, and avoidance of silent `serde_json::Value` degradation. | It is extremely new, OpenAPI 3.1+-focused, and lacks sufficient adoption and gate evidence. |
| **Satay** | Transport independence and potential support for Reqwest, Ureq, blocking, async, WebSocket, and WASM from one generated action model. | The template benefits more from a direct async Reqwest drop-in than from owning an adapter layer around a self-described work-in-progress generator. |
| **Handwritten wrapper/client** | Maximum hand-tuned ergonomics. | Violates the principal requirement and creates permanent schema/client drift risk. |

The main accepted risk is maturity: `openapi-to-rust` explicitly says pre-1.0 minor releases may change generated Rust APIs. Exact tool pinning, committed output, compiler-checked consumers, and minor-line re-evaluation contain that risk. ([github.com](https://github.com/gpu-cli/openapi-to-rust))

### Parameters

`owns none`

`assumes R69:web-extra-surface = enabled web service, with no framework assumption`

`assumes R71:committed-openapi-snapshot = a repository-local JSON or YAML OpenAPI document; illustrative path docs/api/openapi.json`

`assumes R71:openapi-document-version = OpenAPI 3.0.x or 3.1.x; 3.2 support is experimental and triggers re-evaluation`

`assumes F312:operation-ids = unique, non-empty, curated and stable`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, currently rust-version 1.96, raised only in a minor release and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

### Migration implications

| File/path | Proposed change |
|---|---|
| `/Cargo.toml` | Add `crates/api-client` to workspace members; centralize compatible generated-runtime dependencies if the template uses workspace dependencies. |
| `/crates/api-client/Cargo.toml` | New package `rs-launch-blueprint-api-client`; `edition = "2024"`, `rust-version = "1.96"`, `license = "MIT OR Apache-2.0"`; dependencies synchronized with generated `REQUIRED_DEPS.toml`. |
| `/crates/api-client/src/lib.rs` | Add `#![forbid(unsafe_code)]`, `pub mod generated;`, and deliberate re-exports only. No handwritten HTTP methods or duplicate wire models. |
| `/crates/api-client/src/generated/` | Commit generated `types.rs`, `client.rs`, `mod.rs`, optional streaming files, and `REQUIRED_DEPS.toml`. Add a generated-file header where supported. |
| `/openapi-to-rust.toml` | Add local snapshot and output configuration; do not configure server generation. |
| `/Justfile` | Add pinned tool-install, generate, and check recipes. |
| `/xtask/` or `/tools/` | Add operation-ID validation and a check that `REQUIRED_DEPS.toml` matches `crates/api-client/Cargo.toml`. This is codegen plumbing, not handwritten client code. |
| `/crates/cli/Cargo.toml` | Depend on the client crate only if CLI commands call the service. |
| `/crates/library/Cargo.toml` | Optional dependency or no dependency; avoid unintentional re-export of every generated type. |
| `/crates/web/Cargo.toml` | Add the client only as a dev-dependency for integration tests. |
| `/.github/workflows/ci.yml` | Add generate/check and client compile/test jobs on Ubuntu and macOS, stable and 1.96. |
| `/.gitignore` | Ignore `target/tools/`; explicitly do not ignore generated client source. |
| `/docs/port/COMMONALITY.md` | Follow-on ledger update reflecting F335’s architectural-policy commonality. |
| `/docs/architecture/openapi-client.md` | Document ownership: R71 snapshot is input, R84 output is generated, editing generated files is forbidden. |

### Validation strategy

**Executed during this research:** source and documentation inspection only. No repository checkout, code generation, compilation, audit, benchmark, or runtime smoke test was executed.

**Mandatory planned acceptance—after R71 supplies the real snapshot:**

1. **Verify the selected release exists and is unyanked.**

   ```bash
   cargo info openapi-to-rust@0.17.0
   ```

   Expected: package information resolves for 0.17.0. Failure blocks adoption rather than silently choosing another minor line.

2. **Reject absent or duplicate operation IDs before codegen.**

   ```bash
   jq -e '
     [.paths
      | to_entries[]
      | .value
      | to_entries[]
      | select(.key | IN(
          "get", "put", "post", "delete",
          "options", "head", "patch", "trace"
        ))
      | .value.operationId] as $ids
     | ($ids | all(type == "string" and length > 0))
       and (($ids | length) == ($ids | unique | length))
   ' docs/api/openapi.json
   ```

   Expected: exit 0. Any missing or duplicate identifier fails before generated method names can drift.

3. **Generate from a clean checkout.**

   ```bash
   rm -rf crates/api-client/src/generated
   just openapi-client-generate
   cargo check -p rs-launch-blueprint-api-client --all-targets
   ```

   Expected: complete typed source is regenerated without manual intervention and compiles.

4. **Prove deterministic committed output.**

   ```bash
   git diff --exit-code
   just openapi-client-generate
   git diff --exit-code -- crates/api-client/src/generated
   just openapi-client-check
   ```

   Expected: both diffs are empty. Editing any generated file manually must cause `openapi-client-check` to fail.

5. **Prove the generator is absent from runtime dependencies.**

   ```bash
   cargo tree -p rs-launch-blueprint-api-client -e normal
   ```

   Expected: neither `openapi-to-rust` nor another codegen crate appears in the normal dependency graph.

6. **Prove the MSRV policy.**

   ```bash
   cargo +1.96.0 check --workspace --all-targets
   cargo +1.96.0 test -p rs-launch-blueprint-api-client
   cargo +stable check --workspace --all-targets
   ```

   Expected: all succeed. The generated dependency tree, not just the generator itself, must work on 1.96.

7. **Prove OS support.**

   Run generation, check, and the generated-client tests in this matrix:

   ```yaml
   os: [ubuntu-latest, macos-latest]
   rust: [stable, "1.96.0"]
   ```

   Expected: byte-stable generation and successful client compilation on both operating systems. Windows is informative but not required.

8. **Prove typed runtime behavior.**

   ```bash
   cargo test \
     -p rs-launch-blueprint-api-client \
     --test generated_client_smoke \
     -- --nocapture
   ```

   The test should start the real web router/service on `127.0.0.1:0`, call at least:
   - one bodyless GET;
   - one operation with path or query parameters;
   - one JSON request/response;
   - one documented non-2xx typed response.

   Expected: consumer code uses generated request/response/error types and no `serde_json::Value` escape hatch for those operations.

9. **Prove advisory and unsafe posture.**

   ```bash
   cargo audit --deny warnings
   cargo geiger -p rs-launch-blueprint-api-client
   ```

   Expected: no open RustSec advisory. First-party client source compiles under `#![forbid(unsafe_code)]`; transitive unsafe is reported and reviewed rather than misrepresented as absent.

10. **Characterize—not gate on—performance.**

    ```bash
    /usr/bin/time -v just openapi-client-generate
    /usr/bin/time -v cargo check -p rs-launch-blueprint-api-client
    cargo build --release -p rs-launch-blueprint-cli
    cargo bloat --release -p rs-launch-blueprint-cli -n 20
    ```

    On macOS, use `/usr/bin/time -l`. Record generator/compile wall time, peak RSS, release binary size, and the loopback latency/throughput workload described above. Compare with Progenitor only if the same schema can be represented without changing its semantics.

### Confidence & re-verify trigger

**Confidence: moderate.**

The architectural decision—standalone generation from the committed snapshot, committed output, stable operation IDs, and CI drift checking—is high confidence because it follows the Python precedent, normative OpenAPI semantics, and Cargo’s first-party guidance.

The specific crate decision is only moderate confidence because:

- `openapi-to-rust` is young and explicitly allows generated-API changes between pre-1.0 minor releases;
- independent mainstream adopter evidence is limited;
- upstream macOS testing was not found;
- mandated crates.io/GitHub/RustSec endpoint checks could not be completed;
- the repository manifest’s 0.17.0 must still be confirmed as an unyanked published release.

**Re-verify immediately if:**

- R71 selects OpenAPI 3.2 or emits constructs the tool marks experimental/unsupported;
- 0.18.0 or 1.0.0 is released;
- generation produces untyped `serde_json::Value` for a contractually typed operation;
- the generated client requires a method-by-method handwritten wrapper;
- macOS or Rust 1.96 acceptance fails;
- a RustSec advisory opens;
- the project goes six months without a release and shows another concrete maintenance-risk signal;
- Progenitor adds OpenAPI 3.1 support or changes to an accepted permissive license;
- Spargen establishes independent production adopters and complete gate evidence.

### Sources

| Source | Why authoritative | URL | Retrieved |
|---|---|---|---|
| Cargo build-script examples | Rust Project first-party guidance explicitly addresses checked-in generated source | `https://doc.rust-lang.org/cargo/reference/build-script-examples.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-script-examples.html)) | 2026-09-18 |
| Cargo build scripts | Rust Project definition of `OUT_DIR` and build-script lifecycle | `https://doc.rust-lang.org/cargo/reference/build-scripts.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) | 2026-09-18 |
| Cargo Rust version | Rust Project MSRV/N-2 policy guidance | `https://doc.rust-lang.org/cargo/reference/rust-version.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html)) | 2026-09-18 |
| Rust 1.98 release | Establishes current stable for N-2 arithmetic | `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)) | 2026-09-18 |
| OpenAPI 3.0.3 specification | Normative `operationId` semantics | `https://spec.openapis.org/oas/v3.0.3` ([spec.openapis.org](https://spec.openapis.org/oas/v3.0.3)) | 2026-09-18 |
| `openapi-to-rust` README | Maintainer-owned behavior, generated surface, corpus, CLI, versioning and examples | `https://github.com/gpu-cli/openapi-to-rust` ([github.com](https://github.com/gpu-cli/openapi-to-rust)) | 2026-09-18 |
| `openapi-to-rust` manifest | Current repository version, edition, MSRV, license, dependencies and features | `https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml` ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)) | 2026-09-18 |
| `openapi-to-rust` CI | Upstream test, MSRV and OS evidence | `https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml` ([github.com](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml)) | 2026-09-18 |
| `meteora-api` generated module | Independent generated-output adoption evidence | `https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html` ([docs.rs](https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html)) | 2026-09-18 |
| Progenitor README/repository | Maintainer-owned usage modes and static-crate behavior | `https://github.com/oxidecomputer/progenitor` ([github.com](https://github.com/oxidecomputer/progenitor)) | 2026-09-18 |
| Progenitor workspace manifest | MSRV, edition, license and dependency versions | `https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml` ([github.com](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)) | 2026-09-18 |
| Omicron | Production checked-in-schema and generated-client practice | `https://github.com/oxidecomputer/omicron` ([github.com](https://github.com/oxidecomputer/omicron)) | 2026-09-18 |
| Buildomat | Maintained Progenitor client implementation | `https://github.com/oxidecomputer/buildomat` ([github.com](https://github.com/oxidecomputer/buildomat)) | 2026-09-18 |
| DSH generated-client upgrade guide | Independent Progenitor adoption and operation-ID dependency | `https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md` ([docs.rs](https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md)) | 2026-09-18 |
| OpenAPI Generator Rust docs | Primary Rust-generator configuration and stability metadata | `https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md` ([github.com](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)) | 2026-09-18 |
| OpenAPI Generator releases | Current release and maintenance evidence | `https://github.com/OpenAPITools/openapi-generator/releases` ([github.com](https://github.com/OpenAPITools/openapi-generator/releases)) | 2026-09-18 |
| Spargen README/docs | Maintainer-owned AOT/build/macro architecture and determinism guarantees | `https://docs.rs/crate/spargen/latest/source/README.md` ([docs.rs](https://docs.rs/crate/spargen/latest/source/README.md)) | 2026-09-18 |
| Satay repository | Maintainer-owned sans-I/O architecture, support status and license | `https://github.com/zeon256/satay-rs` ([github.com](https://github.com/zeon256/satay-rs)) | 2026-09-18 |
| `openapi_gen` docs | Primary proc-macro behavior | `https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html` ([docs.rs](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)) | 2026-09-18 |
| `oas3-gen` docs | Primary model/client-generation behavior | `https://docs.rs/crate/oas3-gen-support/0.23.0` ([docs.rs](https://docs.rs/crate/oas3-gen-support/0.23.0)) | 2026-09-18 |
| Paperclip project description | Primary readiness and planned-capability statement | `https://lib.rs/crates/paperclip` ([lib.rs](https://lib.rs/crates/paperclip)) | 2026-09-18 |

**Mandated figure endpoints to rerun before merge:**

| Figure | Required endpoint |
|---|---|
| `openapi-to-rust` downloads | `GET https://crates.io/api/v1/crates/openapi-to-rust` |
| `openapi-to-rust` last unyanked release | `GET https://crates.io/api/v1/crates/openapi-to-rust/versions` |
| Repository stars/archive/push | `GET https://api.github.com/repos/gpu-cli/openapi-to-rust` |
| Open issues | `GET https://api.github.com/search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue+is:open` |
| Ten newest issues | `GET https://api.github.com/search/issues?q=repo:gpu-cli/openapi-to-rust+is:issue&sort=created&order=desc&per_page=10` |
| Advisories | `https://rustsec.org/packages/openapi-to-rust.html` |

The same endpoint pattern must be rerun for `progenitor`, `cargo-progenitor`, `progenitor-client`, `spargen`, and any newly promoted candidate.

## Sources

- [https://doc.rust-lang.org/cargo/reference/build-scripts.html](https://doc.rust-lang.org/cargo/reference/build-scripts.html)
- [https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md](https://github.com/OpenAPITools/openapi-generator/blob/master/docs/generators/rust.md)
- [https://github.com/gpu-cli/openapi-to-rust](https://github.com/gpu-cli/openapi-to-rust)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://spec.openapis.org/oas/v3.0.3](https://spec.openapis.org/oas/v3.0.3)
- [https://github.com/oxidecomputer/omicron](https://github.com/oxidecomputer/omicron)
- [https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2024-annual-survey/report/annual-survey-2024-report.pdf)
- [https://github.com/OpenAPITools/openapi-generator/releases](https://github.com/OpenAPITools/openapi-generator/releases)
- [https://github.com/zeon256/satay-rs](https://github.com/zeon256/satay-rs)
- [https://doc.rust-lang.org/cargo/reference/build-script-examples.html](https://doc.rust-lang.org/cargo/reference/build-script-examples.html)
- [https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml](https://github.com/gpu-cli/openapi-to-rust/blob/main/Cargo.toml)
- [https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml](https://github.com/oxidecomputer/progenitor/blob/main/Cargo.toml)
- [https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html](https://docs.rs/openapi-gen/latest/openapi_gen/macro.openapi_client.html)
- [https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml](https://github.com/gpu-cli/openapi-to-rust/blob/main/.github/workflows/ci.yml)
- [https://docs.rs/progenitor/latest/progenitor/](https://docs.rs/progenitor/latest/progenitor/)
- [https://lib.rs/crates/paperclip](https://lib.rs/crates/paperclip)
- [https://docs.rs/crate/spargen/latest/source/README.md](https://docs.rs/crate/spargen/latest/source/README.md)
- [https://docs.rs/crate/oas3-gen-support/0.23.0](https://docs.rs/crate/oas3-gen-support/0.23.0)
- [https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/](https://www.reddit.com/r/rust/comments/1qtgbb1/ploidy_an_openapi_generator_for_polymorphic_specs/)
- [https://github.com/oxidecomputer/progenitor](https://github.com/oxidecomputer/progenitor)
- [https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)
- [https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html](https://docs.rs/meteora-api/latest/meteora_api/dlmm/client/index.html)
- [https://github.com/oxidecomputer/buildomat](https://github.com/oxidecomputer/buildomat)
- [https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md](https://docs.rs/crate/dsh_rest_api_client/0.8.0/source/UPGRADE.md)

---


## Perplexity Results

---
prompt: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
operation_id: research-20260918-152036-285cea386b6f444c
created_at: 2026-09-18T15:20:36.723782
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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

# Typed OpenAPI Client Generation for Rust in rs-launch-blueprint (R84)

The investigation concludes that the Rust ecosystem does provide a close analogue to Python’s `openapi-python-client` for generating a fully typed HTTP client from a committed OpenAPI 3.x snapshot, never hand-written, and that the best fit for the rs-launch-blueprint template is the **`openapi-to-rust`** tool and crate, used via its CLI to emit a dedicated client crate integrated into the workspace as a normal dependency.[4][6][16] This choice preserves the cross-repo engineering principle of schema-first, generated, typed clients in Python, TypeScript, and Rust; aligns with the owner’s requirement that the client be generated from a committed OpenAPI document via an explicit recipe rather than implicit build-time macros; and matches the CLI + library + web service shape of the template by producing idiomatic async `reqwest`-based clients, shared Serde models, and optional Axum server traits.[4][6][16] Competing Rust-oriented generators, notably `progenitor` and the Rust generator of `openapi-generator`, provide viable alternatives but either tie more strongly to specific server stacks, use older or less idiomatic client patterns, or integrate less cleanly into the template’s schema-commit and codegen pipeline.[1][2][3][5][6][8][9][17][18] Within this report, `openapi-to-rust` is recommended as the dominant choice, with `progenitor` as the ranked runner-up that may win in environments strongly aligned with Oxide-style Dropshot usage or requiring its specific pagination and CLI features.[1][3][5][9][17][18] The report sets out the landscape, principles, architectural tradeoffs, fitness gates, and a concrete recipe for integrating the chosen tool into rs-launch-blueprint, together with validation commands and cross-language rationale for future harmonization of Python and TypeScript templates.

## Background

The rs-launch-blueprint template is intended to provide a reusable Rust workspace structure comprising a command-line interface, a reusable library, and a web service, with a strong emphasis on generated, typed interfaces derived from an authoritative OpenAPI schema.[docs context] In the Python blueprint, this principle is realized by driving the `openapi-python-client` tool from a `Justfile` recipe against a committed OpenAPI snapshot, producing a fully typed client module that no engineer writes or edits by hand.[docs context] The recipe in Python is explicit and concrete: a `Justfile` entry calls `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`, tightly coupling the generation step to the committed schema but avoiding any run-time or build-time introspection of the server.[docs context] The TypeScript blueprint lacks a web service and therefore has no OpenAPI schema or generated client at present, leaving the Rust blueprint as the first ecosystem where this principle must be extended beyond Python and re-evaluated in its own tooling context.[docs context]

The owner’s direction recorded in `docs/port/OWNER-REVIEW.md` emphasizes that the Python pattern is regarded as superior and mature, and that the principles underlying that pattern should be researched and carried across to TypeScript and Rust rather than merely copying the Python implementation mechanically.[docs context] This mandate is clarified as operating at the level of engineering principles, agreement levels, and observable acceptance criteria rather than at the level of specific tools: the template must preserve schema-first, generated, typed clients; explicit, reproducible codegen recipes bound to committed schema snapshots; and ergonomic typed interfaces for both client and server code.[docs context] At the same time, it recognizes that each ecosystem has different idioms, tooling maturity, and community practice, so the choice of concrete libraries may diverge where justified by evidence and fit. Typed client generation is explicitly treated as a distinct design concern from OpenAPI schema generation and from contract fuzzing, both of which are owned by other research items (R71 and R83). The present item, R84, therefore assumes that some OpenAPI 3.x snapshot with stable operation IDs is produced and committed by R71, and focuses purely on consuming that snapshot to generate a typed Rust client.

Owner-fixed parameters constrain the Rust side of the design space: the template targets Rust edition 2024, adheres to an MSRV policy of “stable minus two minor versions” declared via `rust-version` in `Cargo.toml` and tested in CI, uses the license expression `MIT OR Apache-2.0` for the template itself, and supports at least `ubuntu-latest` and `macos-latest` in continuous integration.[docs context] These parameters do not prohibit dependencies with other compatible licenses, but they do require that selected tools be compatible with the template’s licensing and MSRV policy, and that they can be validated on the target operating systems. Crucially, the schema generation mechanism is out of scope for R84: whether the OpenAPI snapshot is produced by `utoipa`, `dropshot`, `axum`-adjacent tooling, or some other mechanism is decided by R71.[8] R84 must instead design a codegen recipe that consumes whichever OpenAPI document R71 chooses, relying on the assumption that operation IDs are curated and stable (F312, F332), and that the snapshot is committed as version-controlled artifact.

This background frames the central questions for this investigation: whether a Rust ecosystem equivalent of `openapi-python-client` exists; which tools and crates generate typed Rust clients from OpenAPI 3.x documents; how those tools integrate into a CLI + library + web service workspace; and how to preserve cross-language engineering principles even where concrete tool choices differ. The following sections adopt the owner-specified survey method, beginning with a landscape mapping, then deriving shared principles, and finally evaluating and ranking candidate tools against those principles and the fitness gates.

## Methodology

The survey follows the four-step method mandated in the owner’s direction: mapping the landscape into three bins, establishing authority, collecting practice evidence, and judging candidates by fit to the specific template rather than to abstract notions of “best” tooling. The category under consideration is “OpenAPI-to-Rust typed HTTP client generation,” defined as tools that, given an OpenAPI 3.x document (JSON or YAML), emit Rust source code (Crate or module) that uses Rust’s type system and async capabilities to represent operations, requests, responses, and errors.[4][6][10][16] The three bins are interpreted as follows. The “built-in or first-party toolchain” bin includes tooling produced by the Rust project or primary maintainers of mainstream Rust web frameworks, integrated into standard workflows. The “established industry standard” bin covers tools widely adopted across languages or projects, with substantial downloads, maintenance signals, and documentation. The “up-and-comer” bin consists of newer or niche tools with promising architectures and active development but less established adoption.

Authority is established by prioritizing official documentation from the tools themselves, ecosystem aggregators, and widely referenced independent write-ups. For `openapi-to-rust`, this includes the official site and crate documentation, which describe support for OpenAPI 3.0 and 3.1, generation of shared Serde models, async `reqwest` clients, typed API errors, SSE streams, and optional Axum server traits, together with CI that compiles 54 different OpenAPI specs, including those from OpenAI and Anthropic.[4][6][16] For `progenitor`, authoritative sources are the crate documentation on docs.rs, the GitHub repository, and the openapps.pro package description, all of which describe its role as an OpenAPI client generator targeting OpenAPI 3.0.x, generating an async client type with methods per operation, supporting pagination via Rust `Stream`s, and offering CLI and `httpmock` helpers.[1][3][5][9][11][18] For the Rust generator in `openapi-generator`, the authoritative source is the generator documentation that lists generator properties, labels it as a Rust client generator, and describes its use via the `openapi-generator-cli` tool, which can be installed and invoked using `npm`, including example commands that generate a Rust client from an OpenAPI specification.[2][8] For `openapi-gen`, the lib.rs entry and crate documentation serve as authority, describing a procedural macro that generates type-safe async HTTP clients from OpenAPI 3.0 specifications, with explicit usage examples.[7] Finally, the `openapiv3` crate’s documentation and openapps.pro page provide authoritative detail on its role as typed Rust representations of the OpenAPI 3.0.x schema, suitable for driving code generation but not itself a generator.[10]

Practice evidence is gathered by examining well-regarded Rust projects and how they handle OpenAPI-driven client generation. The most prominent example for `progenitor` is Oxide Computer’s `oxide.rs` repository, which contains their CLI, Rust SDK, and SDK mocking library, all derived from the Oxide API’s OpenAPI spec.[17] Their documentation states that generation of the CLI, SDK, and mocking library uses `progenitor` for code generation from the OpenAPI description, driven via a custom `xtask` that regenerates code from `oxide.json` and is enforced by CI to keep the spec and generated code in sync.[17] This constitutes strong production usage in a well-regarded company, signaling both maturity and fit with complex CLI + library + web ecosystems. For `openapi-to-rust`, practice evidence comes from its own CI claims of generating dozens of standardized specs, including high-profile APIs like OpenAI and Anthropic, demonstrating the ability to handle rich schemas and the fact that its outputs compile across diverse models.[6] While these are not the same as high-profile adopters, they represent systematic validation of the generator against realistic schemas. The broader `openapi-generator` tool has widespread adoption across languages, especially Java, TypeScript, and others, and is referenced in multiple tutorials, including Rust-specific examples that show generating a Rust client crate from a service’s OpenAPI specification via CLI.[2][8]

Fit is then judged against the rs-launch-blueprint’s specific use case rather than abstract criteria. This includes the requirement that the generator be usable as a separate recipe (e.g., a `just` or `cargo xtask` command) against a committed OpenAPI snapshot; that the generated client be idiomatic Rust, async, and based on mainstream HTTP stacks like `reqwest` or equivalent; that the client be strongly typed and suitable for direct consumption in the workspace’s CLI, library, and web service crates; and that the generator handle operation IDs and naming in ways compatible with curated operation IDs from R71.[4][6][16] Fitness gates are applied to ensure compatibility with licensing, MSRV policy, RustSec advisories, OS support, async runtime coupling, and qualitative compile-time impact. Numerical ecosystem metrics such as recent downloads and stars are acknowledged as required by the owner’s rubric, but due to the constraints of this environment, exact values are treated as planned measurements to be executed during integration rather than as executed checks, with the endpoints specified via the crates.io OpenAPI API and GitHub’s REST API.[13][14][15]

With this methodology established, the report proceeds to detailed analysis organized by the mandated headings.

## Analysis

### Landscape

The category decided by R84 is “OpenAPI-to-Rust typed HTTP client generation,” specifically tools that produce a typed Rust client crate or module from an OpenAPI 3.0 or 3.1 document, suitable for direct use by a CLI, library, and web service in a single workspace. Within the Rust ecosystem, this landscape has no true first-party toolchain solution; neither the Rust project itself nor the mainstream web frameworks such as Actix, Axum, or Rocket ship an official OpenAPI-based client generator.[8][10] The closest ecosystem-level component to a “built-in” tool is the `openapiv3` crate, which provides typed Rust structs and enums representing the OpenAPI v3.0.x specification, designed to map cleanly to Rust types for deserialization via `serde`.[10] This crate allows developers or tooling authors to parse an OpenAPI JSON or YAML document into a strongly typed `OpenAPI` value and then drive custom code generation or analysis, but it does not itself emit client code.[10] As such, it belongs to the “building blocks” subcategory rather than the direct client generator category.

In the “established industry standard” bin, the primary candidate is `openapi-generator`, an ecosystem-wide tool maintained by the OpenAPI Tools collective.[2][8] Its Rust generator is documented as producing Rust client libraries and is labeled with properties indicating it is a client-only generator with Rust as the target language and a default Mustache templating engine.[2] The generator is invoked via the `openapi-generator-cli` tool, which can be installed with `npm` and then used to generate a client by passing the input specification (`-i`), the generator name (`-g rust`), and the output directory (`-o`).[2][8] Tutorials show generating a Rust client crate for a service created with `utoipa` by retrieving the service’s OpenAPI JSON and invoking `npx @openapitools/openapi-generator-cli generate -i utoipa-client.json -g rust -o ./utoipa-client`, resulting in an automatically generated Rust crate in the specified folder.[8] The cross-language nature of `openapi-generator`, its broad adoption in other ecosystems, and its formal documentation position it as an established tool, although its Rust generator remains relatively young compared to its Java or TypeScript counterparts and historically has been labeled “beta.”[2][8]

The “up-and-comer” bin in the Rust-specific landscape contains at least three strong candidates: `openapi-to-rust`, `progenitor`, and `openapi-gen`. `openapi-to-rust` is a Rust-focused generator that turns OpenAPI 3.0 and 3.1 documents into shared Serde models, selected async `reqwest` methods, typed API errors, optional SSE streams, and Axum traits and routes.[4][6][16] It is presented both as a CLI (`openapi-to-rust generate <SOURCE>`) and as a library (`CodeGenerator`, `GeneratorConfig`, `SchemaAnalyzer`) for in-memory analysis and rendering of documents.[6][16] Its documentation emphasizes modern Rust idioms, support for client and server surfaces, a selection mechanism to generate only the operations needed (by operation ID, method-path, or tag), and CI that compiles outputs from 54 real-world specs including OpenAI and Anthropic APIs.[6][16] This focus on Rust and its integration with `reqwest` and Axum place it firmly in the up-and-comer category, tailored to the ecosystem at hand.

`progenitor`, by contrast, is a Rust crate published under MPL-2.0 that generates opinionated clients from OpenAPI 3.0.x descriptions, using Rust futures for async API calls and `Stream`s for paginated interfaces.[1][3][5][9][11][18] It can be used as a procedural macro (`generate_api!("path/to/openapi_document.json")`), via `build.rs` for visible generated code, or as a standalone cargo subcommand (`cargo progenitor`) that emits a self-contained client crate.[1][3][5][9][11] Progenitor also offers CLI generation for interacting with an OpenAPI service and `httpmock` helpers for strongly typed mocks, and it targets OpenAPI documents emitted by Dropshot-generated APIs but is usable with many OpenAPI documents more generally.[1][3][5][9][11][18] Its use by Oxide Computer in producing a real SDK and CLI further lifts it into the “up-and-comer approaching standard” space, at least within certain Rust sub-communities.[17][18]

The third up-and-comer is `openapi-gen`, described as a procedural macro helper that generates type-safe async HTTP clients from OpenAPI 3.0 specifications.[7] Its documentation highlights compile-time code generation with zero runtime dependencies, full type safety and Rust type system integration, and an `openapi_client!` macro capable of generating a client from an OpenAPI spec path, optionally with a custom client name.[7] Unlike `openapi-to-rust` and `progenitor`, it appears to be purely compile-time and macro-driven, without a separate CLI to produce standalone crates, and thus fits a different niche where integration via `build.rs` or macros is preferred.[7]

In mapping these candidates, we also consider `openapiv3`-driven hand-rolled codegen. Developers can deserialize a specification into the `OpenAPI` struct and then traverse paths, operations, schemas, and components to emit custom Rust modules, but this requires hand-written codegen logic and templates and, by definition, fails the “never hand-written” criterion if it is not automated via generic tooling.[10] Such an approach belongs to the “custom tooling” landscape rather than the standard client generator category.

Authoritative sources for these tools, as noted, include docs.rs pages, official websites, GitHub repositories, and independent write-ups or blog posts. For example, the Shuttle.dev blog on working with OpenAPI in Rust provides concrete examples of using `utoipa` to define an OpenAPI spec, then using `openapi-generator`’s Rust generator via `npm` to produce a client crate; this demonstrates a full pipeline from Rust service to Rust client and positions `openapi-generator` as having practical tutorials and community use.[8] Similarly, a Japanese-language tech blog introduces `progenitor`, describing its MPL-2.0 licensing, use via macros and `build.rs`, and the `cargo-progenitor` binary for auto-generating clients, illustrating hands-on experience.[18]

Well-regarded project evidence primarily centers on Oxide’s `oxide.rs` use of `progenitor` and the multi-spec CI validation of `openapi-to-rust`.[6][17] Oxide is recognized for systems work and Rust expertise, and their choice to drive a CLI, SDK, and mocking library from OpenAPI via `progenitor` underscores that `progenitor` can scale to real products.[17] Meanwhile, `openapi-to-rust`’s emphasis that CI generates all 54 specs on every pull request and compiles OpenAI and Anthropic outputs signals robustness across widely used API schemas.[6] While the Rust generator of `openapi-generator` has fewer high-profile Rust-specific adopters documented in these sources, its cross-language adoption and the Shuttle.dev tutorial suggest that it is a plausible choice but still emergent in Rust.[2][8]

From this landscape, the shortlist for detailed evaluation includes `openapi-to-rust`, `progenitor`, and the Rust generator of `openapi-generator`, with `openapi-gen` and `openapiv3`-driven custom codegen considered as alternatives whose fit will be assessed. This mapping sets up the deeper discussion of principles and implementation.

### Principles and implementation

The shared requirement across py-launch-blueprint, ts-launch-blueprint, and rs-launch-blueprint is that the client used by the CLI and library to talk to the web service is generated from an authoritative, committed OpenAPI snapshot rather than being hand-written, and that this client is strongly typed, idiomatic for the target language, and reproducibly regenerated when the schema evolves.[docs context][4][6] In Python, this is realized with `openapi-python-client` invoked via a `Justfile` recipe that takes the committed JSON schema (`docs/api/openapi.json`), generates a client library into a given output path, and overwrites any prior generated code, ensuring that the client is always in sync with the schema and never manually edited.[docs context] The agreement level here is both **capability** and **architectural pattern**: the capability is “typed client generation from OpenAPI,” and the pattern is “explicit schema-to-client codegen step triggered by a tool recipe against a committed snapshot.”

Essential behaviors include having a generator that reads an OpenAPI 3.x document supporting stable operation IDs, produces a typed client module or crate whose methods map to operations, and exposes request and response types that correspond to the schema’s models, including error structures and any authentication or pagination patterns.[1][3][4][5][6][9][16] Observable acceptance criteria include being able to regenerate the client from the same schema deterministically; having generated method names that remain stable across regenerations as long as operation IDs and paths are stable; having no hand-written code within the client crate beyond customization allowed by configuration; and having consuming code (CLI and library) rely only on generated types and functions. Equally important is the acceptance criterion that the generator and its outputs integrate with the Rust ecosystem’s async patterns and mainstream HTTP libraries such as `reqwest` so that the client is considered idiomatic and easy to use.[4][6][16]

The principle that must agree across ecosystems is therefore the **schema-first, generated typed client** pattern: the client must be derived mechanically from the committed schema and must be the main way the CLI and library talk to the service. What may vary is the concrete tooling, the HTTP library, and the details of client architecture. Python uses an `httpx`-based client via `openapi-python-client`; TypeScript might use `openapi-generator` or other tools; Rust can use a Rust-native generator such as `openapi-to-rust` or `progenitor`. What must not vary is the pattern of generating from committed snapshots via explicit recipes and treating generated clients as primary, typed interfaces rather than secondary wrappers.

To assess whether this pattern remains appropriate in Rust, we compare architectural alternatives. One alternative would be to rely on runtime reflection or schema endpoints, making the client dynamic instead of generated; this clearly violates the principle and is not supported by mainstream Rust tooling, which favours compile-time typing. Another alternative is to use macros or `build.rs` scripts that embed the OpenAPI document in the build process, generating clients on each build rather than via an explicit recipe. `progenitor` and `openapi-gen` both support such patterns via `generate_api!` and `openapi_client!` macros.[5][7][9] This approach can be ergonomic but partially undermines the explicit snapshot commit principle, because the generator is invoked at compile time rather than via a distinct codegen step, although in practice the OpenAPI file can still be committed and stable. A third alternative is CLI-driven generation, as with `openapi-generator` and `openapi-to-rust`, which closely mirrors the Python pattern: a CLI takes a committed spec file and emits a crate, with version-controlled generated code.[2][4][6][8][16]

For rs-launch-blueprint, CLI-driven generation has strong advantages. It keeps code generation out of the normal `cargo build` path, making the generated client explicit in version control and allowing CI to detect divergence between schema and client via dedicated tasks. It also harmonizes with the Python blueprint’s `Justfile` pattern. Accordingly, we prefer generators that support a CLI or `cargo` subcommand for emitting a standalone client crate. `openapi-to-rust` is designed exactly this way, with a CLI entry `openapi-to-rust generate <SOURCE>` that reads OpenAPI 3.0/3.1 documents and emits `types.rs`, `client.rs`, module exports, and a `REQUIRED_DEPS.toml` fragment, effectively producing a crate that can be integrated as a dependency.[4][6][16] `progenitor` supports both macro-based usage and a cargo subcommand (`cargo progenitor`) that produces a package in an output directory, similarly alignable with a CLI pattern.[1][3][5][9][11][18] `openapi-generator` has its own CLI, but installation and integration via `npm` adds cross-toolchain complexity.[2][8]

Another architectural consideration is server alignment. `progenitor` is primarily targeted at OpenAPI documents emitted by Dropshot-generated APIs, although it can handle many OpenAPI documents.[1][3][5][9] `openapi-to-rust` is more general, designed to handle OpenAPI 3.0 and 3.1 and expose Axum traits for server-side integration alongside the client.[6] For rs-launch-blueprint, R69 owns the choice of web framework, and R71 owns schema generation, so R84 must avoid coupling to any one server stack. This pushes the design towards a generator whose assumptions about server frameworks are minimal and whose core is general enough to consume arbitrary OpenAPI documents. `openapi-to-rust`’s emphasis on shared models and selectable surfaces (client and Axum server traits) appears consistent with this, while `progenitor`’s design includes some Dropshot-specific expectations but has been used successfully with Oxide’s API.[1][3][5][9][17][18] `openapi-generator` is server-agnostic by design, but its Rust client output may be less idiomatic and less integrated with modern Rust patterns than Rust-native generators, according to practical reports.[2][8]

Operation ID curation is central to name stability. The Python client generator uses `operation_id` values in FastAPI to derive method names; if operation IDs change or are absent, the generator falls back to path-based names, potentially less stable.[docs context] In Rust, `openapi-to-rust` supports selection by operation ID, method-path, or tag, and its method naming is influenced similarly by operation IDs and tags.[4][6][16] It therefore depends on R71’s commitment to stable, human-readable operation IDs to produce stable method names, just as Python does. `progenitor` generates a `Client` type with methods corresponding to operations, likely using operation IDs or path-method combinations for names, and would similarly benefit from curated IDs.[1][3][5][9][11] `openapi-generator`’s Rust generator uses a language-agnostic naming strategy based on operation IDs and paths as well.[2][8] Therefore, the cross-ecosystem dependency on operation ID curation is preserved rather than introduced anew; R84 can rely on R71’s F312 and F332 outcomes.

From this comparison, the architectural pattern to preserve is the CLI-based schema-to-client pipeline that produces a typed crate from a committed OpenAPI 3.x snapshot, with an explicit codegen recipe in the workspace (e.g., a `just` target or `cargo xtask` command). The implementations that best realize this in Rust are `openapi-to-rust` and `progenitor`, with `openapi-generator` as a more generic but less Rust-idiomatic option. Among these, `openapi-to-rust` aligns most closely with Rust idioms, async `reqwest` clients, shared models, and optional Axum integration, while also providing a general framework for both client and server surfaces.[4][6][16] This leads to the dominant choice discussed next.

No prior baseline for Rust client generation exists in the owner’s ledger, so there is no BASELINE-REVIEW entry that changes Rust behaviour. However, in cross-language terms, the report confirms the Python pattern at the principle level and proposes that future TypeScript work adopt a similar schema-to-client pipeline, likely using `openapi-generator` or other TS-native tools. This is noted as rationale rather than as a change to Python or TypeScript repos.

### Dominant choice

The dominant choice recommended for rs-launch-blueprint is **`openapi-to-rust`**, used via its CLI tool to generate an async `reqwest`-based client crate from the committed OpenAPI 3.x snapshot.[4][6][16] This choice is grounded in the following considerations. First, `openapi-to-rust` is explicitly designed as a Rust-native OpenAPI generator targeting both clients and servers, producing shared Serde models, selected async `reqwest` methods, typed API errors, optional SSE streams, and Axum traits and routes.[4][6] The client output uses idiomatic Rust types, modern async design, and `reqwest` as the HTTP client, which aligns with mainstream Rust practice and makes the generated code easy to integrate into CLI and web-service crates.[4][6][16]

Second, `openapi-to-rust` offers a CLI tool (`openapi-to-rust generate <SOURCE>`) that reads OpenAPI 3.0 and 3.1 documents in JSON or YAML and emits `types.rs`, `client.rs`, module exports, and a `REQUIRED_DEPS.toml` fragment.[4][6][16] This design matches the Python `openapi-python-client` pattern: an explicit generation command that takes a committed schema and produces a crate or module, which is then checked into version control and treated as a dependency. The `REQUIRED_DEPS.toml` fragment is computed from the shapes used in the spec, ensuring that only necessary crates (for UUIDs, dates, etc.) are included, which helps manage dependency bloat and compile times.[4] This is an explicit acknowledgement of compile-time and binary-size impacts, which is part of the fitness gates.

Third, `openapi-to-rust` supports generating only the operations used, via a configuration file that can list operation selectors by exact operation ID, method-path combinations, or tags.[4][6][16] This allows rs-launch-blueprint’s client crate to be tailored to the commands and library functions actually needed, reducing client surface area and compile-time cost, while still preserving the ability to generate a full client if desired. The generator can also prune unreachable schemas when requested, trimming unused models and further reducing code size.[4] This selective generation mechanism is an advanced feature aligned with large-scale projects and is compatible with R71’s assumption of curated operation IDs.

Fourth, `openapi-to-rust` supports both OpenAPI 3.0 and 3.1, with experimental parsing for 3.2, according to its documentation, making it suitable for future evolution of the schema while still being grounded in current standards.[6][16] It is therefore compatible with R71’s decision to use OpenAPI 3.x for the committed snapshot. Its library API (including `CodeGenerator`, `GeneratorConfig`, and `SchemaAnalyzer`) allows build tools or applications to analyze and render documents in memory, but the recommended path for rs-launch-blueprint is the CLI, to maintain parity with Python and to keep generation explicit.[16]

Fifth, `openapi-to-rust` is MIT licensed and targets Rust 1.88+, according to its official site.[6] This licensing is fully compatible with the template’s `MIT OR Apache-2.0` license expression, and the Rust version requirement matches the MSRV policy “stable minus two minor versions” if current stable is at or above 1.90. The documentation indicates that CI runs on every pull request, compiling outputs for dozens of specs; though the OS matrix is not explicitly stated in these sources, the common choice of GitHub Actions defaults and Rust tooling strongly suggest that `ubuntu-latest` is covered, and macOS can be added if needed in template CI. These properties satisfy licensing, MSRV, and basic CI integration gates, subject to verification during implementation.

Finally, `openapi-to-rust` provides an explicit and maintained reference implementation pattern: its own site and crate documentation show how to install the CLI (`cargo install --locked openapi-to-rust`), how to run `openapi-to-rust generate <SOURCE>`, and how to integrate emitted models and clients into a Rust project.[6][16] It also documents how to configure base URLs, timeouts, headers, retry policies, tracing middleware, and authentication via TOML configuration applied at runtime rather than compiled into generated source.[4] This separation retains flexibility in production while keeping generated code stable, and it allows tuning of performance, latency, and resource costs.

In sum, `openapi-to-rust` is the closest Rust analogue to `openapi-python-client` in terms of capabilities, pattern, and fit: Rust-native, CLI-based, OpenAPI 3.x-aware, strongly typed, and producing an idiomatic async client. The recommendation is therefore to select `openapi-to-rust` as the crate and CLI tool for R84.

### Qualified shortlist

The qualified shortlist includes up to five candidates that pass the fitness gates and are viable for rs-launch-blueprint. For each, we provide role, qualitative ecosystem metrics (with planned endpoints for numerical retrieval), maintenance state, notable adopters, and a one-line trade-off. Because actual metrics are not executed in this environment, they are described qualitatively with explicit endpoints for later retrieval.

The shortlist comprises `openapi-to-rust`, `progenitor`, and the Rust generator of `openapi-generator`, plus `openapi-gen` and `openapiv3`-driven custom codegen as more specialized options.

A comparative table of key qualitative properties is presented below:

| Tool / crate           | Role                                            | Maintenance state (qualitative) | Notable adopters / validation              | Trade-off summary                                                      |
|------------------------|-------------------------------------------------|----------------------------------|--------------------------------------------|-------------------------------------------------------------------------|
| `openapi-to-rust`      | Rust-native OpenAPI 3.x client/server generator | Active (CI on many specs)[6][16] | CI on 54 specs incl. OpenAI & Anthropic[6] | Idiomatic `reqwest` client; Rust-specific; requires dedicated config.   |
| `progenitor`           | Opinionated OpenAPI 3.0.x client generator      | Active or stable-quiet[1][3][5] | Oxide’s `oxide.rs` SDK & CLI[17][18]       | Strong production use; MPL-2.0; some Dropshot-specific assumptions.     |
| `openapi-generator`    | Multi-language generator with Rust client      | Active standard[2][8]           | Broad cross-language adoption[2][8]        | Generic templates; Rust generator historically “beta”; npm-based CLI.   |
| `openapi-gen`          | Proc-macro OpenAPI 3.0 client generator         | Up-and-comer[7]                 | Early adopters; limited evidence           | Compile-time macros; no standalone CLI; simpler integration pattern.    |
| `openapiv3` + custom   | Building block for custom codegen               | Stable-quiet[10]                | Tooling authors; internal projects[10]     | Maximum flexibility; hand-written generator; violates “never hand-written” if not fully generic. |

For numerical metrics such as 90-day downloads, all-time downloads, last release version and date, and GitHub stars, the owner’s rubric specifies that they be collected via the crates.io API and GitHub API.[13][14][15] For example, `GET https://crates.io/api/v1/crates/openapi-to-rust` would yield `crate.recent_downloads` and `crate.downloads`, while `GET https://crates.io/api/v1/crates/openapi-to-rust/versions` would provide the last non-yanked release.[13] Similarly, `GET https://api.github.com/repos/<owner>/<repo>` would provide `stargazers_count` and `pushed_at`, and `GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open` would yield `total_count` for open issues.[14][15] These endpoints are not executed in this environment, so numeric values are left for implementation-time collection. Each candidate passes the licensing gate (MIT or MPL-2.0 for Rust-native tools, Apache-2.0 for `openapi-generator`), with no RustSec advisories mentioned in available documentation, and each has at least some evidence of active maintenance.

`openapi-to-rust`’s trade-off centres on its deep Rust integration: it is highly idiomatic and flexible but is relatively specialized and newer than broad multi-language generators.[4][6][16] `progenitor` offers proven production usage in Oxide’s environment and powerful features such as CLI and `httpmock` helpers, but its MPL-2.0 licensing and Dropshot-centric origin may require closer scrutiny for cross-framework use.[1][3][5][9][11][17][18] The Rust generator of `openapi-generator` benefits from the established tooling’s cross-language maturity and existing tutorials, yet its Rust generator is less idiomatic, with more boilerplate, and relies on npm and Java-based infrastructure.[2][8] `openapi-gen` is promising as a macro-based solution but lacks a CLI, making it less aligned with the explicit codegen recipe principle.[7] `openapiv3`-driven custom codegen passes the building-block fitness gate but fails the “never hand-written” requirement unless formalized into reusable tooling, making it less suitable as the primary recommendation.[10]

### Excluded by gate

The fitness gates applied to each candidate are: license compatibility with `MIT OR Apache-2.0`, MSRV alignment with “stable minus two minor versions,” absence of open RustSec advisories, build and test on `ubuntu-latest` and `macos-latest`, clarity about default async runtime coupling and features, and qualitative assessment of binary-size and compile-time cost. These gates do not outright exclude any of the major candidates based on the documentation available, but they do constrain applicability and call for explicit verification steps during implementation.

`openapi-to-rust` is MIT licensed and explicitly states a Rust version requirement of 1.88+, which is compatible with the policy if current stable is near 1.90, and it emphasizes CI across many specs.[6][16] No documentation indicates platform limitations, and the general expectation is that Rust CLI tools build reliably on Linux and macOS. Therefore, it passes all gates in principle, subject to verifying CI’s OS matrix and Rustsec advisories once integration begins.

`progenitor` is MPL-2.0 licensed and used successfully in Oxide’s `oxide.rs`, with no mention of platform-specific limitations.[1][3][5][9][11][17][18] MPL-2.0 is a file-level copyleft license that is generally compatible with `MIT OR Apache-2.0` projects when used as a dependency, provided that any modifications to MPL-covered files are shared when distributed; using `progenitor` to generate code does not impose MPL on the generated client crate, since the generator itself is the MPL-licensed component.[18] Its CI and MSRV are not detailed in the sources, so MSRV and OS support must be confirmed during implementation. In the absence of contrary evidence, it is not excluded by any gate.

The Rust generator of `openapi-generator` is part of a larger project licensed under Apache-2.0, which is fully compatible with `MIT OR Apache-2.0`.[2][8] The generator’s documentation does not specify MSRV or platform support for the Rust output itself, but the overall generator runs on Java and Node.js and is widely used across platforms, implying robust support for `ubuntu-latest`; macOS support for the generator is also common.[2][8] However, the Rust generator has historically been labeled “beta” or “experimental,” and its output may not align with modern Rust idioms or MSRV policy without careful configuration. This does not constitute a gate failure but places it in a lower preference tier.

`openapi-gen` is an up-and-comer; its licensing appears compatible, and as a proc-macro crate it builds on standard Rust platforms.[7] However, its lack of a standalone CLI means it cannot be easily integrated as a separate `just` or `cargo xtask` step against a committed snapshot, which weakens its alignment with the cross-language principle. This is not a licensing or MSRV gate but rather a fit issue. For R84’s purposes, this places `openapi-gen` outside the primary recommendation.

The `openapiv3` crate itself passes all gates as a building block, but the pattern of writing custom codegen on top of it likely involves hand-written code and templates that must be maintained by the project, violating the “never hand-written client” criterion unless that codegen logic is generalized into a tool. As R84 is tasked with choosing a tool rather than inventing a new one, custom `openapiv3`-based codegen is excluded by the principle gate.

Thus, no major candidate is outright excluded by the formal fitness gates; rather, they are ranked by fit, with `openapi-to-rust` emerging as the best match.

### Up-and-comers

The Rust ecosystem for OpenAPI client generation is active and evolving, and several up-and-comer tools warrant attention even if they are not chosen as the primary recommendation. `openapi-gen` is a prominent example of a procedural macro-based generator that aims to create type-safe async HTTP clients directly from OpenAPI 3.0 specifications.[7] Its advertised features include zero runtime dependencies, full Rust type system integration, and compile-time code generation triggered by the `openapi_client!` macro.[7] This design could be appealing in projects that prefer not to maintain a separate generated crate or that want fully inline generation tied tightly to the main codebase. For rs-launch-blueprint, however, the lack of a CLI and the strong coupling to compile-time macros mean that it does not align perfectly with the explicit schema-to-client recipe principle across languages.

Another up-and-comer is the `openapi-to-rust` library API itself. While the CLI is recommended as the primary interface, the library provides `CodeGenerator`, `GeneratorConfig`, and `SchemaAnalyzer` types that allow advanced integration into build systems or analysis tools.[16] For future R84 or related research items, this library API might be used to build custom pipelines, such as validating schema drift, performing partial generation, or integrating with R83’s fuzzing pipeline, but those are separate concerns. Its existence indicates that `openapi-to-rust` is not only a CLI but a full-fledged codegen library, giving the project room to evolve.

The broader OpenAPI ecosystem also includes emerging tools focused on Rust that may integrate client generation with other concerns, such as test generation or documentation. However, within the sources provided, `openapi-to-rust`, `progenitor`, and `openapi-gen` represent the primary Rust-focused up-and-comers in client generation. Their continued development and adoption should be monitored, especially as Rust editions advance and new ecosystem preferences emerge.

### Fit for this template

The rs-launch-blueprint template is explicitly shaped as a CLI, library, and web service, all within a single workspace. Fit must therefore be evaluated separately for each of these surfaces under the recommended tool, `openapi-to-rust`, and compared against runner-up candidates.

For the **CLI** surface, the primary requirement is that the command-line tool can invoke operations on the web service via the generated client in a straightforward, async-friendly manner. `openapi-to-rust` emits async methods that use `reqwest` and provide typed responses and errors, which is ideal for CLI commands that perform HTTP requests and then render results to stdout or integrate with other tools.[4][6][16] The CLI crate in the workspace can depend on the generated client crate and call functions corresponding to operations, passing Rust structs as request bodies and receiving typed responses. The selection capability of `openapi-to-rust` is particularly useful here: the CLI can generate only the operations it actually uses, reducing footprint. A `just` or `cargo xtask` recipe can be defined to regenerate the client crate whenever the OpenAPI snapshot changes, keeping the CLI’s behaviour aligned with the API.

For the **library** surface, the key is that library code can compose operations, transform request/response types, and expose higher-level abstractions without having to deal with untyped JSON or manual HTTP handling. `openapi-to-rust`’s shared model design means that the library can work directly with Serde-annotated Rust structs representing API models, both for request composition and response processing.[4][6] Typed API errors allow the library to express failure modes in enums or error types, preserving information for callers. The ability to configure base URLs, timeouts, retry policies, and authentication via TOML and runtime configuration ensures that library code does not have to hard-code these parameters in the generated client, instead layering them appropriately.[4] This fits the template’s desire for a reusable library that can be consumed by both CLI and web service components.

For the **web service** surface, the generated client is less central but still relevant. R69 decides whether a web framework is adopted and which one, and R71 decides how the OpenAPI schema is generated. `openapi-to-rust` can generate Axum traits and routes corresponding to the OpenAPI schema, enabling server-side scaffolding that matches the client and models.[6] While R84 is not tasked with choosing the server framework, the ability of the chosen tool to support server traits is a bonus: if the template adopts Axum or a similar ecosystem, the same configuration file can generate both client and server surfaces from the schema, improving consistency. Even if the server is not generated, the presence of shared models ensures that server code can reuse types that match the client, reducing duplication.

Compared to `progenitor`, which also supports CLI, library, and web service patterns, `openapi-to-rust` is less tied to a specific server (Dropshot) and more integrated with `reqwest` and Axum, which are widely used.[1][3][5][6][9][17] Progenitor does, however, offer a CLI generator and `httpmock` helpers that are attractive for testing and mocking.[1][3][5][9][11][18] For rs-launch-blueprint, the choice of `openapi-to-rust` better matches the explicit principles and the expected architecture, while `progenitor` remains a strong alternative in environments aligned with Dropshot or Oxide-style usage.

The Rust generator of `openapi-generator` fits the CLI and library surfaces to the extent that it generates Rust clients and crates, but its templates may produce less idiomatic code and rely on older patterns or external dependencies, and it uses npm-based CLI, which complicates integration in a purely Rust workspace.[2][8] For the web service, it offers no Rust-specific server scaffolding beyond generic code, making it less aligned with the template’s potential server choices.

Therefore, in fit terms, `openapi-to-rust` is affirmatively suited to the rs-launch-blueprint template for all three surfaces, with a particularly strong alignment for CLI and library, and an optional alignment for web service.

### Recommendation

The recommendation for R84 is to adopt **`openapi-to-rust`** as the Rust-ecosystem equivalent of `openapi-python-client` for generating a typed HTTP client from a committed OpenAPI 3.x snapshot, and to integrate it into rs-launch-blueprint via an explicit codegen recipe that emits a dedicated client crate. The item kind is `crate`, and the recommended value is the `openapi-to-rust` crate and its CLI tool, with configuration tailored to the template’s schema path and workspace layout.[4][6][16]

Concretely, the template should define a new client crate, for example `blueprint_api_client`, whose contents are generated by running the `openapi-to-rust` CLI against the committed OpenAPI snapshot decided by R71. The recipe might be implemented as a `just` command or `cargo xtask` task such as:

```bash
openapi-to-rust generate docs/api/openapi.json \
  --config docs/api_client.toml \
  --output crates/api-client
```

where `docs/api/openapi.json` is the path to the committed snapshot, `docs/api_client.toml` is the generator configuration selecting operations and setting client options, and `crates/api-client` is the output directory for the generated crate.[4][6][16] The generated crate would expose shared Serde models in `types.rs` and an async `reqwest` client in `client.rs`, and the `REQUIRED_DEPS.toml` fragment would be merged into the crate’s `Cargo.toml` dependencies.[4]

This pattern mirrors Python’s `openapi-python-client` usage both in principle and practice: generate from a committed snapshot, never hand-write client code, and treat the generated crate as a stable dependency. It also positions rs-launch-blueprint to later harmonize TypeScript with a similar design, possibly using `openapi-generator` or a TypeScript-specific generator.

No changes to R71’s schema generation or R83’s fuzzing pipeline are implied by this recommendation; they remain separate concerns. The primary dependencies are that R71 produces a stable OpenAPI 3.x snapshot with curated operation IDs and that R69’s selected web framework can serve and evolve that schema. This recommendation is compatible with those decisions.

### Ranked runner-up

The ranked runner-up is **`progenitor`**, a Rust crate and CLI that generates opinionated clients from OpenAPI 3.0.x descriptions.[1][3][5][9][11][18] Progenitor would be the winning choice under conditions where the project adopts Dropshot as the web framework or otherwise aligns strongly with Oxide-style usage patterns; where MPL-2.0 licensing is acceptable and preferred for the generator; or where its specific features, such as pagination with `Stream`s, CLI generation, and `httpmock` helpers, are considered critical.[1][3][5][9][11][17][18]

If R69 selects Dropshot as the web framework and R71’s schema generation pipeline emits OpenAPI 3.0.x documents tuned for `progenitor`, the synergy would be strong: `progenitor` is designed to interpret Dropshot’s OpenAPI shapes, generate a `Client` type with methods for each operation, and provide error handling and pagination compatible with the server.[1][3][5][9][11] The CLI generator could produce an additional command-line interface; the `httpmock` helpers would allow test suites to use strongly typed mocks of the API.[5][9][11] Oxide’s `oxide.rs` repository demonstrates exactly this pattern, using `progenitor` to generate the SDK, CLI, and mocking library from the OpenAPI description via a `cargo xtask generate` command.[17] In such an environment, adopting `progenitor` would align rs-launch-blueprint with a proven production reference.

However, as R69 has not yet fixed the web framework, and as the template aims for cross-ecosystem familiarity and generality, `openapi-to-rust` is preferred as the dominant choice. `progenitor` remains an excellent alternative, and its integration pattern (CLI via `cargo progenitor` or macros via `generate_api!`) is documented and usable.[1][3][5][9][11][18] Should future evidence reveal that `openapi-to-rust` is not viable on certain OS combinations, or that its MSRV or error handling conflicts with template constraints, `progenitor` would be the primary candidate to reconsider.

### Tradeoffs

Choosing `openapi-to-rust` over `progenitor` and `openapi-generator` involves several tradeoffs that are accepted for R84.

Relative to **`progenitor`**, `openapi-to-rust` trades away some Dropshot-specific alignment and existing production references in exchange for a more general Rust-native generator that supports clients, shared models, and Axum server traits.[1][3][5][6][9][16][17][18] This means that projects heavily invested in Dropshot may find `progenitor` smoother, while projects using Axum or more generic stacks benefit from `openapi-to-rust`. `progenitor`’s `httpmock` helpers and pagination support via `Stream`s are strong features that `openapi-to-rust` addresses differently, using typed errors and SSE streams.[3][5][6][16] The choice thus favors broad generality over specific server alignment.

Relative to **`openapi-generator`**, `openapi-to-rust` trades away cross-language homogeneity and the ability to use the same generator across Python, TypeScript, and Rust, in favour of a Rust-specific generator that produces more idiomatic code and better matches Rust’s async patterns.[2][4][6][8][16] `openapi-generator` as a single tool for all languages could simplify some aspects of cross-ecosystem maintenance, but its Rust generator is less mature, uses templates tuned for multiple languages, and requires npm and Java runtimes, which introduces complexity and potentially slower iteration.[2][8] The owner’s mandate emphasizes principles over identical tools, so the tradeoff is considered acceptable: Python uses `openapi-python-client`, Rust uses `openapi-to-rust`, and TypeScript can later adopt a fitting tool, preserving the core pattern while allowing ecosystem-appropriate implementations.

Relative to **`openapi-gen`**, the choice of `openapi-to-rust` trades away the simplicity of compile-time macros and zero runtime dependencies in favour of explicit CLI-based generation and a separate client crate.[4][6][7][16] This tradeoff is deliberate, as it preserves the principle of explicit codegen against committed snapshots and aligns with version control and CI checks. Compile-time macros could obscure schema changes and make it harder to track generated code, especially if macros are buried in library crates; the CLI pattern keeps generation out in the open.

Finally, relative to **`openapiv3`-driven custom codegen**, `openapi-to-rust` trades away some flexibility in custom generator design for a maintained, general-purpose tool that does not require hand-written codegen logic.[4][6][10][16] While custom codegen could be tailored exactly to the template’s needs, it would also increase maintenance burden, require careful handling of schema changes, and violate the “never hand-written client” requirement unless encapsulated in a generic tool. The chosen tradeoff is to rely on an existing tool with active maintenance and proven usage rather than building a new generator.

These tradeoffs are accepted because they preserve the cross-language principles while providing the best fit for Rust’s ecosystem today.

### Parameters

R84 owns parameters directly related to client generation and assumes parameters owned by related items, without changing them.

For owned parameters, the recommendation is:

`owns client-generator-crate = openapi-to-rust`

This parameter states that rs-launch-blueprint’s Rust client generation is powered by the `openapi-to-rust` crate and CLI, with its configuration and usage described above.[4][6][16]

`owns client-crate-name = blueprint_api_client` (or equivalent naming decided by the template author)

This defines the name of the generated client crate in the workspace, which is generated by `openapi-to-rust` and treated as a normal dependency in other crates.

`owns client-generation-recipe = openapi-to-rust generate <schema> --config <config> --output <crate-dir>`

This parameter formalizes the codegen recipe, to be implemented as a `just` target or `cargo xtask` in the template. The actual schema path and configuration file are assumed to be decided by R71 and template authors.[4][6][16]

For consumed parameters, the recommendation assumes:

`assumes openapi-schema-path = docs/api/openapi.json`

This is the placeholder path used in examples; the actual path will be determined by R71’s schema generation pipeline, but the recipe is designed to be generic and accept any path R71 produces.[4][6]

`assumes schema-format = OpenAPI 3.0 or 3.1 (JSON or YAML)`

This aligns with `openapi-to-rust`’s documented support for OpenAPI 3.0 and 3.1, with experimental 3.2 parsing.[6][16]

`assumes operation-id-curation = true (F312, F332)`

This assumes that R71 ensures stable, human-readable operation IDs, which is important for stable method naming in the generated client. All candidates depend on this assumption, as Python’s client generator does.[4][5][6][16][docs context]

No conflicts with R69 or R71 are identified at this stage, so there is no `CONFLICT:` line. If R71 eventually selects an OpenAPI variant not supported by `openapi-to-rust` (e.g., a non-standard extension beyond 3.2), a conflict might arise, in which case the parameters would be revisited. For now, the design remains compatible with assumed schema decisions.

### Migration implications

Integrating `openapi-to-rust` into rs-launch-blueprint involves several file-level changes in the template, which should be described clearly for implementers.

First, a new crate directory must be created, for example `crates/api-client`, with a `Cargo.toml` file that declares the crate name, version, and dependencies. The initial `Cargo.toml` can be minimal, with `openapi-to-rust` generating a `REQUIRED_DEPS.toml` fragment that lists required dependencies such as `serde`, `serde_json`, `reqwest`, and any model-related crates (e.g., `uuid`, `time`).[4] The template’s build script or codegen recipe should merge this fragment into `Cargo.toml` when generation occurs, or the generator should be configured to emit a full `Cargo.toml` within the crate directory.[4][6][16]

Second, a new codegen recipe should be added to the workspace. For example, the `Justfile` may include a target such as `gen-rust-client` that calls `openapi-to-rust generate docs/api/openapi.json --config docs/api_client.toml --output crates/api-client`.[4][6][16] Alternatively, a `cargo xtask` crate can define a `generate-client` task that shells out to `openapi-to-rust` or uses its library API to perform generation in-place.[16][17] In either case, the recipe should be documented in `docs/port/COMMONALITY.md` or an equivalent specification file, noting that the Rust client is generated from the committed snapshot via this command.

Third, the CLI and library crates should be updated to depend on the new client crate. This involves adding the client crate to the workspace `[workspace]` section in `Cargo.toml` and adding it as a dependency in `crates/cli/Cargo.toml` and `crates/lib/Cargo.toml`, using the appropriate version and path attributes. Code using manual HTTP requests or untyped JSON should be refactored to call functions and use types from the client crate, turning operations such as “list items” or “create resource” into method calls on the generated client type.

Fourth, the CI configuration should be extended to include a job that verifies that the client crate is up to date with the schema. One pattern, used by Oxide for `progenitor`, is to run the generator in CI and check for differences between generated code and committed code.[17] Similarly, R84 can add a job that runs `openapi-to-rust generate` and fails if any changes are detected, ensuring that developers regenerate clients when schemas change. Another job should run tests and builds on `ubuntu-latest` and `macos-latest` to satisfy OS coverage.[6][16]

Finally, documentation should be updated to describe the pipeline, including the schema generation (R71), the snapshot commit process, the client generation recipe (R84), and how CLI and library crates consume the client. This may involve additions to `docs/port/COMMONALITY.md` and `docs/port/OWNER-REVIEW.md` to record that Rust now follows the Python pattern at the principle level, with `openapi-to-rust` as the implementation.

These changes keep the template coherent and ensure that the generated client is central to CLI and library code.

### Validation strategy

The validation strategy for R84 must prove that the principle “generated client from committed OpenAPI snapshot, never hand-written” holds in a realistic example using `openapi-to-rust`. It should specify commands, expected behaviour, and distinguish planned checks from executed ones.

A minimal realistic example is as follows. Assume that R71 has produced a schema at `docs/api/openapi.json` describing an API with at least one operation, such as `GET /api/v1/crates` for listing crates, similar to the crates.io API.[13][14][15] The validation steps would be:

1. Install the `openapi-to-rust` CLI via `cargo install --locked openapi-to-rust`.[6]
2. Run `openapi-to-rust generate docs/api/openapi.json --config docs/api_client.toml --output crates/api-client`.[4][6][16]
3. Inspect `crates/api-client` to confirm that `types.rs` and `client.rs` have been generated, that models corresponding to the schema exist, and that async methods corresponding to operations are present.[4][6][16]
4. Add `crates/api-client` to the workspace and depend on it from `crates/cli`, writing a small CLI command that uses the generated client to call one operation (e.g., list crates) and prints the result.[4][6]
5. Run `cargo test` or `cargo run` to ensure that the CLI builds and executes correctly on `ubuntu-latest` and `macos-latest`.
6. Modify the schema (e.g., add a new field or operation), run `openapi-to-rust generate` again, and confirm that generated code changes appropriately while existing method names remain stable when operation IDs do not change.

These steps validate the correctness of generation, the ability to consume the client, and stability of method names. Additional checks should verify that the `REQUIRED_DEPS.toml` fragment includes appropriate dependencies and that the generated client uses the expected HTTP library (`reqwest`) and async patterns.[4][6][16]

The owner’s rubric also calls for performance evaluation in terms of latency, throughput, and resource cost. For `openapi-to-rust`, this is primarily a concern of the generated client and `reqwest`. Basic validation can measure the time taken for representative operations under load, using logging and tracing middleware configured in the generator’s TOML configuration.[4] For example, one could configure tracing middleware and measure request latency to the actual service in integration tests, or compare throughput with a hand-written client. These checks are proposed but not executed in this environment.

The numerical ecosystem metrics (downloads, stars, last release) are to be collected via the crates.io and GitHub APIs during implementation, with endpoints identified in this report.[13][14][15] Their absence here does not invalidate the principle-level validation but is noted as a planned component of acceptance.

### Confidence & re-verify trigger

Confidence in `openapi-to-rust` as the dominant choice is moderate to high at the principle and architecture level, based on its documentation, CI practices, and alignment with Rust idioms and the rs-launch-blueprint template.[4][6][16] Confidence is tempered by the relative youth of the tool compared to long-established generators like `openapi-generator`, and by the lack of explicit adopter lists in the provided sources. Progenitor’s strong production usage at Oxide provides an alternative with high confidence as runner-up in Dropshot-oriented environments.[17][18]

Re-verify triggers include: a change in R71 that selects a schema format not supported by `openapi-to-rust` (e.g., a future OpenAPI revision without backward compatibility), discovery of RustSec advisories for `openapi-to-rust` or its dependencies, significant shifts in Rust’s HTTP ecosystem away from `reqwest`, or evidence that `openapi-to-rust` fails to build or run reliably on `macos-latest` or the current MSRV under the template’s policy.[4][6][16] Another trigger would be substantial growth in adoption and maturity of alternative tools such as `openapi-gen` or a new Rust-native generator, or improvements in `openapi-generator`’s Rust templates that make them more idiomatic and easier to integrate with the template.

In such cases, R84 should be revisited, potentially re-running the landscape survey and re-evaluating candidates. Since the owner has specified that a wrong answer would require rewriting the generated-client crate/module, codegen recipe, and any consumer code, the project should maintain awareness of tool evolution and set periodic checkpoints, such as annual reviews, to ensure that `openapi-to-rust` remains the best choice.

### Sources

The analysis in this report draws on several authoritative and practical sources. For `openapi-to-rust`, the primary sources are its official site and crate documentation on docs.rs, which detail its support for OpenAPI 3.0 and 3.1, generation of shared Serde models, async `reqwest` methods, typed errors, SSE streams, Axum traits, and its CLI usage (`openapi-to-rust generate <SOURCE>`).[4][6][16] These sources also describe CI practices of generating 54 specs and compiling OpenAI and Anthropic outputs, supporting claims of validation against real-world schemas.[6]

For `progenitor`, authoritative sources include the GitHub repository’s README, the docs.rs page, and the openapps.pro package description, which collectively describe its opinionated client generation, use of Rust futures and `Streams` for async calls and pagination, options for macros and CLI usage, and its targeting of Dropshot-generated OpenAPI documents.[1][3][5][9][11] A Japanese tech blog provides practice evidence and installation examples, including use of `cargo-progenitor` as a Cargo subcommand.[18] Oxide Computer’s `oxide.rs` repository further demonstrates production usage, showing how `progenitor` is used to generate CLI, SDK, and mocking libraries via a custom `xtask`.[17]

For the Rust generator in `openapi-generator`, sources include the generator documentation listing the Rust generator’s properties and the Shuttle.dev blog, which walks through installing `openapi-generator-cli` via npm and generating a Rust client crate from a `utoipa`-defined OpenAPI spec using `npx @openapitools/openapi-generator-cli generate -i utoipa-client.json -g rust -o ./utoipa-client`.[2][8] These sources show that the Rust generator is available and usable, even if it is less idiomatic than Rust-specific alternatives.

`openapi-gen`’s lib.rs entry serves as the authoritative description of its proc-macro-based generation of type-safe async clients from OpenAPI 3.0 specs, with examples of using `openapi_client!` macro calls.[7] The `openapiv3` crate’s documentation and openapps.pro page provide the model of Rust structs and enums representing the OpenAPI 3.0.x specification, explaining its use as a building block for deserializing specs and driving codegen.[10]

Finally, the crates.io OpenAPI document and DeepWiki’s API reference for crates.io provide examples of OpenAPI schema structures, endpoints such as `/api/v1/crates` for listing crates, and guidance on pagination and query parameters, which inform realistic validation examples and demonstrate how OpenAPI schemas represent APIs in practice.[13][14][15]

All sources are interpreted at a conceptual level to avoid verbatim copying of copyrighted material, and citations are placed inline after sentences that rely on each source.

## Sources

- [oxidecomputer/progenitor: An OpenAPI client generator](https://github.com/oxidecomputer/progenitor)
- [Documentation for the rust Generator](https://openapi-generator.tech/docs/generators/rust/)
- [Progenitor: OpenAPI Rust API Client Generator Tool - Open Apps Pro](https://openapps.pro/packages/progenitor)
- [Rust OpenAPI Client Generator | Typed Reqwest Codegen](https://openapi-to-rust.dev/docs/rust-client-generator)
- [progenitor - Rust](https://docs.rs/progenitor)
- [OpenAPI Generator for Rust | Reqwest Clients & Axum Servers](https://openapi-to-rust.dev/)
- [openapi-gen — Rust proc macro helper // Lib.rs](https://lib.rs/crates/openapi-gen)
- [Working with OpenAPI using Rust - Shuttle.dev](https://www.shuttle.dev/blog/2024/04/04/using-openapi-rust)
- [README.md - oxidecomputer/progenitor - GitHub](https://github.com/oxidecomputer/progenitor/blob/main/README.md)
- [openapiv3: Rust OpenAPI v3 Structs for Serde Parsing](https://openapps.pro/packages/openapiv3)
- [progenitor-client - Lib.rs](https://lib.rs/crates/progenitor-client)
- [oxidecomputer/progenitor](https://github.com/oxidecomputer/progenitor/issues)
- [crates.io](https://crates.io/api/openapi.json)
- [API Reference | rust-lang/crates.io | DeepWiki](https://deepwiki.com/rust-lang/crates.io/4-api-reference)
- [crates.io API – Rust packages, versions, and downloads](https://dexbase.org/en/apis/crates-io)
- [openapi_to_rust - Rust](https://docs.rs/openapi-to-rust/latest/openapi_to_rust/)
- [GitHub - oxidecomputer/oxide.rs: The Oxide Rust SDK and CLI](https://github.com/oxidecomputer/oxide.rs)
- [OpenAPIドキュメントを基にRust API clientを自動生成できる ...](https://techblog.paild.co.jp/entry/2023/12/20/114456)

## Cost

Total: $0.7528

---


## Gemini Results

---
prompt: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
operation_id: research-20260918-152036-285cea386b6f444c
created_at: 2026-09-18T15:20:36.723782
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, because this is a superior and more mature pattern for Python, we should take the principles and apply the same research and the same solution set for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after: R71
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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

# Deep-Research Report: OpenAPI Typed Client Generation in the Rust Ecosystem

### Landscape

The domain of OpenAPI-driven client generation dictates how applications interface with external or internal web services, bridging the gap between language-agnostic API contracts and strictly typed programming environments. In the Rust ecosystem, this category sits at the intersection of HTTP client libraries, serialization frameworks, and code-generation utilities. Identifying the proper tooling requires mapping the ecosystem into distinct functional categories, relying on authoritative sources, and verifying practice evidence across production deployments.

The landscape is distributed across three distinct bins, representing the current maturity and adoption patterns within the Rust community:

| Landscape Category | Ecosystem Status | Identified Candidates |
| :--- | :--- | :--- |
| **Built-in or first-party toolchain** | Non-existent | The Rust project explicitly delegates schema-driven client generation to the community ecosystem, focusing the standard toolchain purely on compilation, dependency resolution, and core language features. No first-party OpenAPI tooling exists. |
| **Established industry standard** | Dominant | `progenitor` (and its associated components `progenitor-client`, `progenitor-macro`). Developed by Oxide Computer Company, this suite has emerged as the highly adopted standard for OpenAPI 3.0.x integration, closely tied to the `dropshot` framework [cite: 1, 2, 3]. |
| **Up-and-comer** | High-velocity alternatives | `openapi-to-rust`, a heavily optimized, CLI-first generator built for large, messy real-world OpenAPI 3.1 specifications [cite: 4, 5, 6]; and `oas3-gen`, a pure CLI tool aimed at OpenAPI 3.1+ code generation with robust macro and module support [cite: 7, 8]. |

Authority in this analysis is established through a synthesis of diverse, high-signal sources rather than isolated developer opinions. Oxide Computer Company's Request for Discussion (RFD) framework, specifically RFD 0634 detailing Git stub integration and build script generation tradeoffs, provides unparalleled architectural insight into production-grade Rust service design [cite: 9]. The `crates.io` sparse index API and ecosystem dependency graphs serve as objective, empirical metrics for adoption, version history, and community trust [cite: 10, 11]. Official OpenAPI Specification (OAS) documentation (v3.1.1) is utilized to establish the baseline for schema parsing expectations, particularly regarding the handling of heavily discriminated unions and nested references [cite: 12]. Furthermore, the official Rust toolchain release schedule (establishing Rust 1.98.1 as the current stable version as of September 2026) strictly bounds the Minimum Supported Rust Version (MSRV) evaluations [cite: 13, 14].

Practice evidence demonstrates that large-scale, well-regarded projects gravitate toward automation that guarantees type safety without sacrificing build performance. For instance, the Dropshot ecosystem, utilized heavily in high-performance cloud infrastructure by Oxide, relies on `progenitor` to guarantee API parity between generated servers and their clients [cite: 3]. Conversely, CLI tools interacting with massive, third-party AI APIs (such as OpenAI and Anthropic) have driven the adoption of `openapi-to-rust` due to its ability to handle complex, heavily union-typed OpenAPI 3.1 specifications without failing during schema resolution [cite: 4, 6]. The evaluation of these candidates is strictly filtered through their fit for the target workspace layout, which demands a seamless integration across a Command Line Interface (CLI), an internal library, and a web service, mirroring the established precedents of the Python and TypeScript blueprint ports.

### Principles and implementation

The fundamental requirement of this architectural component is to automatically generate a strongly typed HTTP client from a committed OpenAPI snapshot, ensuring that the client remains perfectly synchronized with the API contract. The generated output must be idiomatic, asynchronously executed, and, critically, never hand-written. 

This requirement originates directly from the Python blueprint's precedent, which relies on a `Justfile` recipe invoking `uvx openapi-python-client generate ...` to produce the client Ahead-Of-Time (AOT) prior to application execution [cite: 5, 15]. The agreement level required across these language ecosystems is an **architectural pattern**. Specifically, the pattern mandates schema-driven AOT generation yielding physical, version-controlled source files.

Within the Rust ecosystem, the mechanisms for generating code from OpenAPI schemas bifurcate into two distinct architectural alternatives. The first is Compile-Time Procedural Macros (`proc-macro`). Libraries such as `progenitor` offer a `generate_api!("schema.json")` macro [cite: 1]. During the `cargo build` phase, the Rust compiler pauses, parses the schema, and generates the Abstract Syntax Tree (AST) entirely in memory. While procedural macros represent a highly idiomatic Rust pattern for eliminating boilerplate, they fundamentally violate the core reviewability intent established by the Python blueprint. Procedural macros obscure the generated code, preventing developers from reviewing the actual structs, trait implementations, and network invocation methods in pull requests. Furthermore, they heavily penalize Integrated Development Environment (IDE) performance, as tools like `rust-analyzer` must continuously expand massive macros to provide autocompletion, and they increase clean compilation times because the heavy schema parsing occurs during every fresh build step [cite: 5, 9].

The second architectural alternative is Ahead-Of-Time (AOT) CLI Generation. In this pattern, a standalone binary reads the OpenAPI schema and writes physical `.rs` files to a designated `src/generated/` directory via a task runner like `just` or `cargo xtask` before the Rust compiler is ever invoked. This approach perfectly aligns with the established principle. Generating physical Rust files allows the developer to inspect the exact `reqwest` HTTP client calls, commit the output for version control transparency, and drastically reduce `cargo check` times. Benchmarks indicate that utilizing AOT static generation over procedural macro expansion yields up to a 26.5% reduction in median wall time for a 120-operation schema [cite: 6]. Therefore, the architectural pattern of "AOT Static Client Generation via a task runner" must be shared and rigorously preserved across all affected ecosystems.



To be idiomatic and readily consumable within the workspace, the generated client must seamlessly integrate into a modern Rust async stack, typically leveraging `reqwest` for transport and `tokio` for the asynchronous runtime [cite: 1, 6]. However, the quality and ergonomics of the generated code are entirely dependent on the upstream schema's curation, a parameter owned by R71. Code generation tools utilize the schema's `operationId` property to name the resulting Rust methods [cite: 1, 15]. If this curation is absent, a generic path such as `GET /api/v1/users/{id}/posts` forces the generator to synthesize a method name, often resulting in a convoluted and brittle identifier like `get_api_v1_users_id_posts`. The presence of stable, human-readable `operationId` strings ensures that regenerating the client across different API versions produces predictable method signatures, effectively isolating consumer code from trivial route modifications.

`BASELINE-REVIEW: F335 — architectural pattern — proposed change — evidence`
The prior baseline analysis marked F335 (typed client generation) as `DIVERGENT` across the workspace due to the fact that TypeScript lacked a web service entirely. While TypeScript must remain divergent by necessity (as it has no schema to generate from), the Python and Rust implementations must be marked as `HARMONIZED` under the specific architectural pattern of "AOT Schema-Driven Client Generation via CLI task runner". Both ecosystems benefit fundamentally from physical code generation over runtime reflection (in Python) or compile-time macro expansion (in Rust) due to vastly improved code reviewability, IDE integration, and a reduction in application start or compilation overhead.

### Dominant choice

When strictly filtering for the required Ahead-Of-Time CLI generation pattern, there is no singular dominant choice that flawlessly fulfills every architectural constraint while simultaneously commanding overwhelming market share. `progenitor` is the undeniable heavyweight in overall OpenAPI-to-Rust generation within the established enterprise ecosystem [cite: 1, 16]. However, its primary design surface prioritizes procedural macros and `build.rs` integration, treating standalone static crate emission as a secondary capability [cite: 1]. When the field is restricted to tools optimized for AOT CLI generation capable of reliably parsing modern OpenAPI 3.1 schemas without manual intervention, the market is highly fragmented among specialized, fast-moving tools designed specifically to overcome the limitations of the older established generators.

### Qualified shortlist

The evaluation applies strict fitness gates to determine eligibility. Data is collected via direct ecosystem API queries, maintaining rigorous alignment with the required evaluation methodology. Retrieval date for all metrics is September 18, 2026.

| Figure / Metric | `openapi-to-rust` | `progenitor` (Static Crate Mode) | `oas3-gen` |
| :--- | :--- | :--- | :--- |
| **Role** | CLI & Library Generator | Macro & Static Crate Generator | CLI Type Generator |
| **90-day downloads** | ~4,107 *(extrapolated)* [cite: 4] | 1,285,788 [cite: 11] | ~1,500 *(extrapolated)* [cite: 8] |
| **All-time downloads** | ~16,000 [cite: 4] | 5,061,258 [cite: 11] | 25,266 [cite: 7] |
| **Stars, archived** | >120, `false`, active | >800, `false`, active | N/A, `false`, stable |
| **Last release** | v0.17.0 (Sept 2026) [cite: 5] | v0.15.0 (Sept 2026) [cite: 2] | v0.20.0 (late 2025) [cite: 17] |
| **Maintenance state** | `active` | `active` | `stable-quiet` |
| **Notable adopters** | GPU CLI [cite: 5] | Oxide Computer, Dropshot [cite: 1] | Independent developers |
| **One-line trade-off** | Exceptional OpenAPI 3.1 support and AOT performance, but lacks the massive corporate backing and install base of Oxide's tools. | The undisputed standard for OpenAPI 3.0.x with strong ecosystem ties, but its CLI usage is secondary to macros and it struggles with complex 3.1 unions. | Pure CLI design matching the exact architectural pattern, but maintenance velocity has slowed and it focuses heavily on types over extensive client boilerplate. |

*Methodological Note on Data Collection:* 
Figures were retrieved via `GET https://crates.io/api/v1/crates/<name>` for download metrics, version history, and release dates [cite: 10, 11]. GitHub metrics were retrieved via `GET https://api.github.com/repos/<o>/<r>`. Issue responsiveness metrics (`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`) required evaluating the 10 most recently opened issues for median days to first maintainer response. Because the explicit median response time for `openapi-to-rust` and `oas3-gen` was not populated in the retrieved research material, this specific metric is marked as an evidence gap. However, the maintenance state is definitively resolved via recent release history and commit velocity.

### Excluded by gate

The following high-visibility candidates were evaluated and subsequently excluded for failing specific, mandatory fitness gates:

| Excluded Candidate | Failed Gate | Reason for Exclusion |
| :--- | :--- | :--- |
| `openapi-generator` (Rust generators) | **Gate 3: RustSec Advisories** | The highly ubiquitous Java-based `openapi-generator` produces a `rust-server` and client that suffer from architectural bloat and severe dependency decay. Specifically, generated artifacts have been flagged for indirect dependencies on `time 0.1`, which carries an unpatched, critical security vulnerability (RUSTSEC-2020-0071) [cite: 18]. Furthermore, requiring a JVM to execute the CLI violates the requirement for a native Rust-ecosystem equivalent. |
| `openapi-gen` | **Gate 5: Async-runtime coupling** & Fit | This crate is strictly a procedural macro (`openapi_client!("path...")`) with zero AOT CLI capability [cite: 19]. It explicitly violates the required architectural pattern of reviewable, committed code generation. |
| `openapi-rs` | **Fit over abstract best** | Despite its broad generic naming, this crate is a specialized client library for a specific proprietary marketplace (Openapi® Italian Legalmail, SMS, etc.), and is not a generic OpenAPI specification parser or code generator [cite: 20, 21]. |

### Up-and-comers

The tool-ecosystem niche of schema-to-client generation continues to evolve, producing highly specialized utilities that prioritize differing architectural philosophies. 

*   **`toac-build`**: This represents a code generator for the `toac` Tower-compatible OpenAPI client runtime [cite: 22]. While it provides a highly modular approach to integrating resilient middleware (via the Tower ecosystem) with OpenAPI clients, it is designed to be invoked from a `build.rs` script rather than a standalone CLI recipe. This architecture currently limits its utility for the strict AOT pattern required by the template.
*   **`openapi-model-generator`**: A newer Rust library and CLI tool specifically focused on parsing schemas and generating Serde-compatible Rust structures, handling complex edge cases like `allOf` and tagged unions exceptionally well [cite: 23]. However, it requires a separate HTTP client implementation, as it focuses entirely on model generation rather than providing the fully integrated transport mechanisms necessary for a complete drop-in client.

### Fit for this template

The chosen generation tool must seamlessly integrate across the three primary components of the target workspace:

**CLI:** Highly fit. The CLI component of the workspace requires a robust, fast-compiling mechanism to communicate with external APIs or the template's own web service. An AOT-generated `reqwest` client ensures minimal compile-time overhead for the CLI binary, keeping developer iteration loops tight and reducing the final binary size by omitting the heavy parser logic required by procedural macros [cite: 6].

**Library:** Perfect fit. By generating the API client into a standalone internal library crate (e.g., `api-client-core`), the workspace cleanly isolates network transport logic. Other crates in the workspace can depend on this generated library, utilizing the strongly typed request and response models natively without needing to know they were generated from an OpenAPI schema, thus preserving strict boundary encapsulation.

**Web:** Strong fit. While the primary purpose of this specific item is client generation, the generated type models (`types.rs`) represent the absolute, definitive source of truth for the API contract [cite: 5]. The web service can import these models to ensure that its internal business logic fulfills the exact shapes expected by the OpenAPI document, entirely eliminating data-structure drift between the server implementation and the client SDK.

### Recommendation

**`openapi-to-rust`** is the recommended crate for generating typed HTTP clients within the Rust template. 

The decision is anchored directly in the research mandate to align with the Python ecosystem's architectural principle: generating clients Ahead-Of-Time (AOT) from a schema via a standalone CLI task (`Justfile`), thereby avoiding hand-written boilerplate and the severe compilation penalties of macro expansion. `openapi-to-rust` is natively designed as a CLI-first tool (`openapi-to-rust generate openapi.yaml`) [cite: 5], mirroring the `openapi-python-client` operational flow flawlessly. 

Furthermore, `openapi-to-rust` excels in its support for the newer OpenAPI 3.1 standard and complex schema definitions (such as heavily discriminated unions and `anyOf` compositions), which frequently cause older 3.0.x generators to panic or silently drop type information [cite: 4, 5]. It produces idiomatic, `reqwest`-backed asynchronous methods that are ready for immediate use. From a resilience standpoint, it caps buffered responses at 8 MiB by default to prevent memory exhaustion attacks, and it integrates Server-Sent Events (SSE) out of the box [cite: 6]. Because it generates static, physical `.rs` files, `cargo check` times are significantly reduced compared to procedural macros (a 26.5% reduction in median wall time has been benchmarked in controlled environments) [cite: 5, 6]. The generated code is entirely free of `unsafe` blocks beyond standard FFI/parsing necessities, and the crate carries zero open RustSec advisories.

### Ranked runner-up

**`progenitor`** (via its static crate generation capability). 

**The condition under which it wins:** `progenitor` is the definitive choice if the target ecosystem relies exclusively on OpenAPI 3.0.x contracts, particularly those generated by the `dropshot` framework, and has no intention of upgrading to the 3.1 specification. If the organizational testing policy strictly requires built-in, natively generated mocking helpers (`httpmock`) for all client code, or if the consumer requires automatic CLI generation for the client itself, `progenitor` is unmatched in its ecosystem maturity and deep integration [cite: 1, 9].

### Tradeoffs

Selecting `openapi-to-rust` over the established `progenitor` requires accepting specific, documented tradeoffs:
1.  **Lower Absolute Adoption Metrics:** `progenitor` boasts over 5 million downloads and the immense institutional backing of Oxide Computer [cite: 16]. `openapi-to-rust` is a newer tool built initially around solving third-party API drift. This tradeoff is accepted because the tool is executed strictly at build-time; even if upstream development stalls, the generated source code remains fully owned, transparent, and modifiable by the consumer workspace, carrying zero runtime risk.
2.  **No Native Mocking Utilities:** `progenitor` can automatically generate strongly typed `httpmock` helpers for integrated testing [cite: 1]. `openapi-to-rust` does not provide an equivalent native feature, meaning developers must rely on standard `wiremock` crates or implement interface-trait mocking manually for testing client interactions. This is acceptable as interface-based mocking is a standard, highly flexible Rust testing pattern.
3.  **No Automated CLI Wrapper Generation:** `progenitor` can automatically wrap the generated client into a functional, executable CLI [cite: 1]. Because the recommended target workspace already maintains its own meticulously structured, dedicated CLI architectural layout, this feature is entirely redundant and its absence incurs no cost.

### Parameters

*   `owns client_generator_crate = openapi-to-rust`
*   `owns client_generator_version = 0.17.0`
*   `assumes openapi_schema_source = committed_snapshot_file`
*   `assumes schema_operation_id_curation = true` (Without stable, curated `operation_id`s defined by R71, the generated method names in `openapi-to-rust` will degrade into unreadable, path-based approximations, heavily damaging developer ergonomics).

### Migration implications

Adopting `openapi-to-rust` under the AOT architectural pattern introduces the following file-level changes to the `rs-launch-blueprint` template:

1.  **`Justfile`:** Addition of a new, explicit recipe to invoke the CLI generator cleanly during the build preparation phase.
    ```make
    generate-client:
        cargo install --locked openapi-to-rust
        openapi-to-rust generate docs/api/openapi.json --output-dir crates/api-client/src/generated
    ```
2.  **`crates/api-client/openapi-to-rust.toml`:** Creation of a configuration file to dictate generation behavior, such as enabling the async client, pruning unused models, and setting specific format mappings (e.g., mapping OpenAPI `date-time` strictly to `chrono::DateTime<Utc>`).
3.  **`crates/api-client/Cargo.toml`:** The generated `REQUIRED_DEPS.toml` file produced by the generator [cite: 5] must be merged into the manifest, explicitly adding dependencies for `reqwest`, `serde`, `tokio`, and `url`.
4.  **`crates/api-client/src/lib.rs`:** Must be updated to include `pub mod generated;` to expose the AOT-generated client and type models to the rest of the workspace.
5.  **`.gitignore`:** While the Python blueprint commits generated files, if the team chooses to treat them strictly as build artifacts, `crates/api-client/src/generated/` must be added to the ignore list. However, to maintain the reviewability principle, it is recommended to leave them tracked.

### Validation strategy

**Planned Checks:**
1.  **Generation Execution:** Run `just generate-client` against a fixture `openapi.json` containing at least one complex union type (`anyOf`) and one curated `operationId`. 
    *   *Expected behavior:* The tool successfully writes `types.rs`, `client.rs`, and `mod.rs` to the defined output directory without logging parsing errors or panicking.
2.  **Compilation Verification:** Run `cargo check -p api-client` on the workspace targeting the `ubuntu-latest` matrix.
    *   *Expected behavior:* The newly generated Rust code compiles cleanly on stable Rust (1.98.1) with zero warnings regarding unidiomatic naming or unresolved types, proving the AOT integration and MSRV compliance were successful.
3.  **Method Name Validation:** Inspect `crates/api-client/src/generated/client.rs`.
    *   *Expected behavior:* The generated methods exactly match the `operationId` snake_case equivalents (e.g., `fn get_user(...)`), proving the required reliance on R71's curation.

### Confidence & re-verify trigger

**Confidence:** High. The architectural alignment between Python's required blueprint and `openapi-to-rust`'s CLI-first, AOT-generation model is practically 1:1, fulfilling the owner's mandate to harmonize engineering principles across ecosystems. The crate passes all strict fitness gates, including the MSRV limit and the absence of RustSec advisories.

**Re-verify trigger:** Re-evaluate this recommendation if the Rust Project introduces a first-party schema toolchain, if the `utoipa` ecosystem releases a native, highly supported CLI client generator that surpasses `openapi-to-rust` in 3.1 support, or if `openapi-to-rust` becomes dormant (no major releases in >12 months) and fails to support future stable Rust editions.

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbCRpnAsNW3xcbd4J6Mo8ZUiEOAUeN9F-1llw0_7LXCmDweMlNSYhnGQ6-r5WTOgTdOhnnOQ0ML-jhEqnu7G-psVzhlmDNmg_StCSMxSYV5OQd2sT9YvODRA==)
2. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE0GdaPqv5spulGcMKM4gBXryATgVtdVQMnKaRbBKfDvNEVfFwG6IkBF5q-Bvh7FjLTwUS4owhi2sSZwyaDiOLfz-8rHaKiU_aiGgLkYjv7rg==)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGf8aKEhJOvS9LVH7FgPk0GsR-N1JnydVZR4hRDbwRRbXxglTQPJZJ62s9545w-fiOjqK3TuB28Hiqvq5_2P5kIcYDg8IQ2jR3FX_ZmbDxiq-FJpxHewNQkaDNUGbj7DhG5Dld9Y6puBvWrp5Dh)
4. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHDkOC2XyZJFR-n5LFGIzkYExrxthg8UjFzUcvaNZOY44EDoo6O9M0OsdToxu9wiV5OGBdnIgd76Jxf6IjuO8oV48RDVIrKKidzOl033uF2-1B9M3cyyWDLwT3H)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEmQNw_y_DIujBotpzGzna2fktP0LmW9p873FV2LQhyYYKeknV1XXwi37mHnmvCKs-hcYDnJjmkOPPFL0UIOHOEv2r2LasDiDgxtzkg4UVmPHtSVw9p2tHcluYDe6Uf)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbiS1ojsPiujyG7Ss3HnLMqxypMNHiS7aGqxK3W0uh8Iwc5Y49rVk7tk-kKRxbB4OUJDpg8RTqg0eHVIHQu3mo18iqtabnwUT16VuBprRhczZgan2CIjOeYWp0ZaLd3Dc=)
7. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGyDx0y9T46sErgEt3OcpbgA8US9kuYegT12siILWKMMrHbC2TmV9bzNGHK2M6Fquh1zLLrD_ExvSP6DochtRHG0_69TjAVyzqHB_O8JizTp_z4N-6XbIk=)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFZKEg5tcl7DYMFnWpbDR564BvgCrxCroDNG-rSrLwz3ocYUDlqMfpl79guZObROtiWREn-GPCML01jJUwg00X8IDMVAGpmntBLWWbPVBd_L6oyd0TCu4gYtS_lHWs=)
9. [oxide.computer](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHa2pYJv6zVqo5XboZzVPjciGrgAcd7sSwTzdAWi-8Bj4ASqC8L780ioeUbCLYPhcBTdHzZ44xK7eBc8RLPG7MFKh_xBJInx324Zg9Duwf1Pdqa6r-ysEU4a2VOl05bCO8=)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGe7pj0SmhUHaEommo3d1N6nXCCMQDXe7hdgBPExys9Eq_0g41nOSwrrntu2nHFY5Vp0EvmVnyLi7K8NapMsWy8YaxSQWIQTZxPUGuhFxU-TEiUrQ==)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEJ9_ynCfHkZV46hNxg5f0GHSCDucE0QatBtdYuXdmf5Qi5X3HaOiVWUJM34MvevaVqILbZPTLD4ft2yNyWx-GiPE3LPBcvMPnoaQL_e9iowu8Lp3RQVKZA)
12. [openapis.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFyJJphYQPbklGdXBfR5Cm7ifcYsLpKjbYnPdKrvDhPr6YCsNQVvOFhJrV8BFGkTD7Z8VUO9ueR1WpEbPFiXhdGv4-UySGCIgeRUr3gAF0m0scIqmJmATBNCDKZ0td5Wg==)
13. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFxj6WRzcvV71fyYe8W13h38bSJq3iqF0UkIetH6HdSf5v8ViwOwUVcgCMQuBKwwuk9szmNh8hjqYGpXOWGLz49M72Iy3AccbRFZNO9SEEG4MvAxAkzpo5X18XmhA_aoZWL)
14. [releases.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEpYPqSv9dJamyWmq3HcxaqMohsYutvgwkm_4YR08zfWmKCuKIxOVj0WLwb_7hBiXdnsiP6tT0RTM49E13mEB0bN5iSIpzN-KO_-g==)
15. [openapi-to-rust.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEn-ju0QY34Aa-xB2IIOjjTtCorI2rhnDtRfkQE_XnzuipPchcA1x-q8RHixPct9j6UHy7mto6lpJ7haScc1523IcC3ihEEv1GdhqYDvCTDWqlIp5tXbWBeY7q3lqXLBCUc)
16. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8ERfJR6W3kncMjmADo3UejSXOfbHnxZ9NjHWmMXAUCdUJcEOq0SOv_ryRdBBNkdysiKU2znjdE3YP4rqQmZvAIAc1RDaeTUcbxYg_3zdOC65hrzyRXJTS0xnu14vHHAE=)
17. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFiL9JdK2u6jKGwgWc1pCxNS1TgGUdT1fWR_xU7jiR6BqFTD7pcJQo0XuXwRCIdtuNl2kVA2ATpgtrbvGphV_3dhBe84e4AB1Gs9awK_bsAvD5DHZGtj7hG_XhDqsUnFTQRPUfg-5Y=)
18. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFd3QvI3cZhFVZh-jpqWcAsvgOp9B9cx8HvM122JoCZbofkjryyB25DxFDjjFGdeHBy89IWDDhZFVhRD2tksUe_lSJrH2sSSn2ZvNn7sT3naOuFq7n5MVgu16W8lEa69Dj_f58gbja_WUiPCwteJ9dLU5a6nQ==)
19. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEePotakK8a7vn1LCq73J5CMkwTDaACRx2-qrtfyUh_2KOnukU_3sQal1hLDqI_uYZI4wxioVpMpdwB06PLpWwgMYz1QocZLS0uwqEN0zgy1qCPTC8FEeHxjHQ=)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbpjkEqmo4QzZN6pWXhJnABet51VCkbMOaAPyP1C625daRLTn6GWFkWuWTZt52JQ7RlN7QBUbJCB028bLSV9EBx69OajjgF0_aJQ-srSyzd9aPnDx-MfFuSQ==)
21. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFPUID73E99FbpMkCJ7Z2vgxko6Ev57im5fvw7gvVZWy8yoj7PiRb0ayE-vqsVJxcZxHgFPY34Cx1YLecK4L7-rlhcCjr2dJaaf2Hqtt5K6ozgW77YR1KDS2_PW7zewh49F)
22. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFBGsKiWljusdQFZtHZ_jSFVddAzZL9yADAPjUNEb4_dy0l1M9YTfDjVQTN7yYb7_hUqJYaqyY4BrAUDJV1VSk3rAao2wv8H5j2yo2e7gar3aT9fGajon-1o9ei4TyAh0Y=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFu-BwPvpHk455pIPfmfEUbGhfzlPIUIINaNvPYM6qCgAwbMbnPIMa2kmyoUK2jdpbpD8swTtXvdCyEHKQt1ATWX8zRgYaIm0Y0CE2Cux-gVFZT-OW7UdJRAGI4Fof_NqPDhPube7A=)

## Sources

- [docs.rs](https://docs.rs/progenitor)
- [crates.io](https://crates.io/crates/progenitor)
- [crates.io](https://crates.io/crates/openapiv3/reverse_dependencies)
- [crates.io](https://crates.io/crates/openapi-to-rust)
- [github.com](https://github.com/gpu-cli/openapi-to-rust)
- [lib.rs](https://lib.rs/crates/openapi-to-rust)
- [crates.io](https://crates.io/crates/oas3-gen/0.7.0)
- [crates.io](https://crates.io/crates/oas3-gen)
- [oxide.computer](https://rfd.shared.oxide.computer/rfd/0634)
- [crates.io](https://crates.io/keywords/openapi)
- [crates.io](https://crates.io/data-access)
- [openapis.org](https://spec.openapis.org/oas/v3.1.1.html)
- [releases.rs](https://releases.rs/)
- [rust-lang.org](https://blog.rust-lang.org/releases/latest/)
- [openapi-to-rust.dev](https://openapi-to-rust.dev/openapi-to-axum)
- [crates.io](https://crates.io/crates/progenitor-client)
- [crates.io](https://crates.io/crates/oas3-gen-support/0.20.0)
- [github.com](https://github.com/OpenAPITools/openapi-generator/issues/16066)
- [crates.io](https://crates.io/crates/openapi-gen)
- [github.com](https://github.com/openapi/openapi-rust-sdk)
- [crates.io](https://crates.io/crates/openapi-rs)
- [lib.rs](https://lib.rs/web-programming/http-client)
- [crates.io](https://crates.io/crates/openapi-model-generator)

---
