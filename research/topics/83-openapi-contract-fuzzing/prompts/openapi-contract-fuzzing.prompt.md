# Deep-research prompt — OpenAPI contract fuzzing (R83, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `schemathesis` exists for OpenAPI-schema-driven contract fuzzing — generating test cases for every documented operation and checking for server errors, excluded from the default fast test run. Item kind: `crate`. Value test: if this answer is wrong, the fuzz-test crate/module, its test-tier exclusion marker, and its schema-discovery mechanism all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's web test suite fuzzes every documented OpenAPI operation via `schemathesis`, deriving request cases from the schema itself and asserting no server error, marked `slow` so the default `pytest` run skips it; ts has no web service or OpenAPI schema to fuzz against. Evidence: py `tests/web/test_contract.py:29` — `case.call_and_validate(checks=(not_a_server_error,))`; ts: none (no web service exists in ts; F303). Ledger rows: F334 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F334 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because contract fuzzing is its own tool-ecosystem survey, independent of the schema-generation and snapshot-diff picks; it also absorbed testing-coverage's now-deleted duplicate fuzz-tool row (ex-F140).
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item fuzzes against is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document exists (F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing contract fuzzing.

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
- MEDIUM: What checks does the candidate perform out of the box (matching py's `not_a_server_error` check, i.e. asserting no 5xx response) — is a not-a-server-error assertion the default, or does the crate also check response-schema conformance, and is that a wanted or unwanted addition?
- MEDIUM: How does the candidate discover the schema to fuzz against — does it fetch the served OpenAPI JSON from the running service at test time (matching py's `schemathesis.openapi.from_asgi`), or does it read the committed snapshot file (F332) directly, and which is the better fit for a CI-run fuzz suite?
- LOW: What is each candidate's maturity/adoption level, given OpenAPI-schema-driven fuzzing is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
