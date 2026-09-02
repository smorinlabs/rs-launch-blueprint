# Deep-research prompt — API pagination (R72, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-router. Item kind: `bundle`. Value test: if this answer is wrong, every collection-returning route's response type, the pagination-parameter extraction, and the app-wide registration call in the composition root all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py returns collections through a page/size query-param pagination extractor and an items/total response envelope, with the collection items staying plain core-model objects — only the wrapper is web-specific — and registers the pagination machinery once, app-wide, rather than per-router. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/routers/projects.py:30` — `from fastapi_pagination import Page, paginate` (WEB-03; items stay `core.models` objects, only the collection wrapper is web-specific); ts: none. Ledger rows: F310, F311 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F311 pagination wired app-wide via one factory call — py `src/py_launch_blueprint/web/app.py:204` — `add_pagination(app)` (registers the pagination response models/params globally instead of per-router); ts: none.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no pagination shape to reconcile with.

## Out of scope
- Which web framework hosts this pagination extractor; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the pagination wiring to fit whichever framework's extractor model wins.
- The envelope any pagination validation failure (e.g. an out-of-range page) renders through; R70 (`http-problem-envelope`) owns F305/F306 — this item decides the pagination contract itself, not how its errors are rendered.
- Keeping the generated OpenAPI schema's pagination response components correct; R71 (`openapi-generation-pipeline`) owns F307/F312/F332/F333 — this item decides the pagination mechanism, not how it is documented in the OpenAPI spec.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R72
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework this pagination extractor must integrate with — treat R69's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a Rust pagination crate/extractor giving page/size query-param pagination and an items/total response envelope, registered once app-wide rather than per-route.
- HIGH: Does a Rust crate exist that provides `fastapi-pagination`-equivalent page/size extraction plus a generic items/total envelope type, integrated with a leading async web framework's extractor mechanism?
- HIGH: Can that crate be registered once, app-wide (mirroring py's `add_pagination(app)`), or does Rust's typed-extractor model require per-route wiring — and what is the idiomatic minimal-boilerplate way to apply it uniformly to every collection route?
- MEDIUM: Does the crate keep collection items as the caller's own domain type (mirroring py's items staying `core.models` objects, only the wrapper being web-specific), or does it require converting items into a crate-specific wrapper type first?
- MEDIUM: How does the crate integrate with OpenAPI-schema generation (R71, not yet decided) — does it emit its own schema components automatically, or does it need manual per-route annotation?
- LOW: Do any published Rust API templates document a page/size-plus-items/total pagination convention as a named pattern, and where?

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
