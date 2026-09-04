# Deep-research prompt — OpenAPI contract fuzzing (R83, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `schemathesis` exists for OpenAPI-schema-driven contract fuzzing — generating test cases for every documented operation and checking for server errors, excluded from the default fast test run. Item kind: `crate`. Value test: if this answer is wrong, the fuzz-test crate/module, its test-tier exclusion marker, and its schema-discovery mechanism all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py's web test suite fuzzes every documented OpenAPI operation via `schemathesis`, deriving request cases from the schema itself and asserting no server error, marked `slow` so the default `pytest` run skips it; ts has no web service or OpenAPI schema to fuzz against. Evidence: py `tests/web/test_contract.py:30` — `case.call_and_validate(checks=(not_a_server_error,))`; ts: none (no web service exists in ts; F303). Ledger rows: F334 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F334 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because contract fuzzing is its own tool-ecosystem survey, independent of the schema-generation and snapshot-diff picks; it also absorbed testing-coverage's now-deleted duplicate fuzz-tool row (ex-F140).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item fuzzes against is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document exists (F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing contract fuzzing.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Should take the principles and architectural pattern from PyLaunch Blueprint, the Python version, and see what the equivalents would be for TypeScript and Rust.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only fuzzes against an already-produced schema, it does not generate one.
- Typed client generation from the same committed schema; R84 (`openapi-typed-client-generation`) owns F335 — a sibling item split from the same R71 reconciliation, do not conflate client generation with fuzzing.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the fuzzing crate and describes how it targets any candidate framework's running service.
- The general test-tiering/exclusion mechanism (how a test is marked "slow" and excluded from the default fast run); R32 (`test-harness-and-execution`) owns that — this item states that contract fuzzing must be excluded from the default run, it does not design the tiering mechanism itself.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R83
- owns:
- consumes: R69: web-extra-surface
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item fuzzes against (F332); assume R71 resolves to *some* committed schema and design the fuzzer to consume it generically, without picking the generator.
- related (not a registry dependency): R84 (`openapi-typed-client-generation`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides typed-client generation from the same schema, a separate concern from fuzzing.
- related (not a registry dependency): R32 (`test-harness-and-execution`) decides the general test-tiering mechanism (marking a test "slow"/excluded from default runs) that this item's fuzz suite plugs into.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `schemathesis` exist for OpenAPI-schema-driven contract fuzzing — generating test cases for every documented operation from the schema itself and checking for server errors — and if so what crate/pattern implements it, excluded from the default fast test run.
- HIGH: What Rust crates perform property-based/generative fuzzing driven directly by an OpenAPI/JSON-Schema document against a live HTTP service (candidates to investigate: any dedicated OpenAPI-fuzzing crate, or a hand-assembled combination of `proptest`/`quickcheck` plus an OpenAPI-schema-to-strategy crate)?
- HIGH: Does any candidate implement `schemathesis`'s core behavior — deriving both valid and boundary-invalid request payloads per operation directly from the schema, with no hand-written test data — or would a Rust port require assembling that capability from lower-level pieces, and if so what is the assembly cost?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: What checks does the candidate perform out of the box (matching py's `not_a_server_error` check, i.e. asserting no 5xx response) — is a not-a-server-error assertion the default, or does the crate also check response-schema conformance, and is that a wanted or unwanted addition?
- MEDIUM: How does the candidate discover the schema to fuzz against — does it fetch the served OpenAPI JSON from the running service at test time (matching py's `schemathesis.openapi.from_asgi`), or does it read the committed snapshot file (F332) directly, and which is the better fit for a CI-run fuzz suite?
- LOW: What is each candidate's maturity/adoption level, given OpenAPI-schema-driven fuzzing is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
