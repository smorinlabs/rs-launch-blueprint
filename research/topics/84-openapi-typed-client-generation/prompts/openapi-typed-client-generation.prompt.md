# Deep-research prompt — OpenAPI typed client generation (R84, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: whether a Rust-ecosystem equivalent of `openapi-python-client` exists for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written. Item kind: `crate`. Value test: if this answer is wrong, the generated-client crate/module, the codegen recipe invoking it, and any consumer code depending on its generated types all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py generates its typed API client from the committed OpenAPI snapshot via a `Justfile` recipe, never by hand; ts has no web service or OpenAPI schema to generate a client from. Evidence: py `Justfile:312` — `uvx openapi-python-client generate --path docs/api/openapi.json --output-path {{out}} --overwrite`; ts: none (no web service exists in ts; F303). Ledger rows: F335 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`. Note: F335 was split out of R71 (`openapi-generation-pipeline`) at the Task 10 reconciliation because typed client generation is its own tool-ecosystem survey, independent of the schema-generation, snapshot-diff, and fuzzing picks.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The OpenAPI schema/snapshot this item's client is generated from is decided by R71 (`openapi-generation-pipeline`), still open — assume some committed OpenAPI document with curated, stable operation ids exists (F312, F332) without picking its generator.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing typed client generation.

## Out of scope
- Which crate/pattern generates the OpenAPI schema itself, its operation-id curation, and its snapshot-diff/breaking-change detection; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item only generates a client from an already-produced schema, it does not generate the schema.
- OpenAPI-schema-driven contract fuzzing against the same schema; R83 (`openapi-contract-fuzzing`) owns F334 — a sibling item split from the same R71 reconciliation, do not conflate fuzzing with client generation.
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the client-generation tool and describes how it consumes any candidate framework's served schema.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R84
- owns:
- consumes: R69: web-extra-surface
- related (not a registry dependency): R71 (`openapi-generation-pipeline`) decides the OpenAPI schema/snapshot generator this item's client is generated from (F312, F332); assume R71 resolves to *some* committed schema with stable operation ids and design the codegen recipe to consume it generically, without picking the generator.
- related (not a registry dependency): R83 (`openapi-contract-fuzzing`) is the sibling item split from R71 at the same Task 10 reconciliation; it decides fuzzing against the same schema, a separate concern from client generation.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does a Rust-ecosystem equivalent of `openapi-python-client` exist for generating a typed HTTP client from the committed OpenAPI snapshot, never hand-written, and if so what crate/tool/recipe implements it.
- HIGH: What Rust codegen tools/crates generate a typed client crate/module from an OpenAPI 3.x document (candidates to investigate: `openapi-generator`'s Rust generators (reqwest-based), `progenitor`, hand-rolled codegen driven by `openapiv3`, or a `utoipa`-adjacent client-generation story if one exists)?
- HIGH: Does the leading candidate integrate as a standalone recipe (a `just`/`cargo xtask` step invoked against the committed snapshot file, matching py's `openapi-python-client generate` recipe), or does it require a `build.rs`/proc-macro approach compiled directly into a consuming crate — and which fits a CLI + library + web template's workspace layout better?
- MEDIUM: Is the generated client idiomatic enough for direct use in the workspace (async, `reqwest`-based or similar, typed request/response structs matching the schema) to be a fair drop-in, or does it produce boilerplate requiring a hand-written wrapper layer before other crates in the workspace can consume it?
- MEDIUM: Does the candidate depend on the schema's operation-id curation (F312, owned by R71) to produce stable, human-readable generated method names across regenerations, the same dependency py's `openapi-python-client` has on FastAPI's curated `operation_id`s — and what happens to generated names if that curation is absent?
- LOW: What is the maturity/adoption level of the leading candidate(s), given typed OpenAPI-to-Rust client generation is a narrower tool-ecosystem niche than general OpenAPI schema generation?

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
