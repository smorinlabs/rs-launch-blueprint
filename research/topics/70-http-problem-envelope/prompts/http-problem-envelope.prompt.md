# Deep-research prompt — HTTP problem envelope (R70, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint`'s web service renders every non-2xx response as a single RFC 9457 `application/problem+json` envelope covering domain errors, framework-level errors, and validation errors alike, and the domain-error-to-HTTP-status mapping table that feeds it. Item kind: `bundle`. Value test: if this answer is wrong, the web crate's error-handling extension point, its response-envelope type, and the status-mapping table for every domain error variant all get rewritten, and every non-2xx response in the OpenAPI schema (R71) documents the wrong shape.

## Context
- Inherited pattern (spec §2, presumption of reuse): py wraps every non-2xx response — domain errors, bare framework exceptions, and its own validation errors alike — in one `application/problem+json` envelope, and maps domain error types to HTTP status codes through a typed lookup table. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/problems.py:52` — `PROBLEM_CONTENT_TYPE = "application/problem+json"` applied to all error handlers, covering domain errors, bare `HTTPException`s, and FastAPI's own 422s alike (WEB-01); py `src/py_launch_blueprint/web/problems.py:57` — `ERROR_STATUS: dict[type[PyError], int]`; ts: none. Ledger rows: F305, F306 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). F306's status-mapping table depends on `error-taxonomy-exit-codes` (the `PyError`/exit-code hierarchy decided in the CLI area), owned by R67, not yet decided — design the mapping mechanism generically against "any error type implementing a status-mapping trait or method," not against a specific enum shape.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no error-envelope shape to reconcile with.

## Out of scope
- The stable error-code catalog and its process exit-code mapping; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item maps whatever error types R67 defines onto HTTP statuses, it does not define the error taxonomy itself.
- Which web framework hosts these error handlers; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the envelope to fit whichever framework wins.
- Keeping the generated OpenAPI schema in sync with this envelope's shape; R71 (`openapi-generation-pipeline`) owns F307 — this item defines the envelope contract, not the schema post-processing step that documents it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R70
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework hosts this envelope's error-handling extension point (F303); this item's envelope pattern must work with whichever framework R69 picks — treat R69's choice as open, do not block on it. R71 (`openapi-generation-pipeline`) owns the OpenAPI schema post-processing that keeps the generated error shape in sync with this envelope (F307); this item defines the envelope contract that R71 must document, not the sync step itself.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` expresses every non-2xx HTTP response as a single RFC 9457 `application/problem+json` envelope covering domain errors, framework-level errors, and validation errors alike, and how domain error types map to HTTP status codes.
- HIGH: Does a Rust crate exist that generates and validates RFC 9457-conformant `application/problem+json` responses, integrated with a leading async web framework's error-handling extension point, that also lets framework-level errors (404, 405, validation 422) and domain errors share one envelope — or does the wrapping need to be hand-rolled at that extension point?
- HIGH: What is the idiomatic Rust mechanism for a domain-error-to-HTTP-status mapping table analogous to py's `ERROR_STATUS: dict[type[PyError], int]` — a `match` over an error enum, a trait method (e.g. `fn status_code(&self) -> StatusCode`) implemented per variant, or a crate-provided derive?
- MEDIUM: Does the chosen crate/pattern also need to intercept and reshape the framework's own validation-error responses (the Rust analogue of FastAPI's 422) into the same envelope, and what hook does that require?
- MEDIUM: Given this item consumes R67's `error-taxonomy-exit-codes` (not yet decided), can the mapping-table pattern be designed generically against "any error type implementing a status-mapping trait," to be wired to R67's concrete enum once R67 resolves, without redesign?
- LOW: Do any published Rust web-service templates or style guides document this "one envelope for every non-2xx response" pattern by name, and where?

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

### Recommendation
One stack.
### Members
The full `crate` field set for each member.
### Compatibility
Proof the members are tested together: a shared adopter, a shared example repository, or a version matrix.
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
