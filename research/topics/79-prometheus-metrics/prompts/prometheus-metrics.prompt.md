# Deep-research prompt — Prometheus metrics (R79, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s web service exposes RED (rate, errors, duration) metrics at `/metrics`, on by default. Item kind: `crate`. Value test: if this answer is wrong, the `/metrics` route wiring, the instrumentation calls threaded through request handling, and the exporter dependency all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's web layer exposes Prometheus RED metrics at `/metrics` unconditionally (on by default, no env gate), excluded from its own measurements and from the generated OpenAPI schema; ts has no web service to compare against. Evidence: py `src/py_launch_blueprint/web/telemetry.py:48` — `.expose(app, endpoint="/metrics", include_in_schema=False)`; ts: none (no web service exists in ts; F303). Ledger rows: F326 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item is on-by-default, unlike R78's OTel integration which sits behind an opt-in `otel` feature (F304) — do not gate this crate's inclusion behind an optional feature unless the evidence shows the Rust ecosystem norm requires it.
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing Prometheus metrics.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): Again, there's a good architecture in PyLaunch Blueprint. We should find that architecture and implement the same principles and the same versions for TypeScript and Rust.

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the metrics crate(s) and describes how they attach to any candidate framework's router.
- The request-id/access-log/security-header middleware stack and its ordering; R75 (`http-middleware-stack`) owns F317-F321/F327 — this item covers metrics collection and exposition only, not the general middleware layer, even though both may compose as `tower` layers.
- Excluding `/metrics` from access-log volume; R75 owns F320 — this item only needs to state that `/metrics` is excluded from its own measurements and from the OpenAPI schema (F326 itself), not from the access log.
- Which crate generates and post-processes the OpenAPI schema that `/metrics` must stay out of; R71 (`openapi-generation-pipeline`) owns that — state that the route must be excludable from the generated schema, do not design the exclusion mechanism.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R79
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework this item's metrics middleware/route attaches to; treat the framework choice as open.
- related (not a registry dependency): R75 (`http-middleware-stack`) decides the general `tower`-layer middleware stack (request-id, access-log, security headers) this item's metrics collection sits alongside; a shared middleware-composition story is a valid finding but not a requirement.
- related (not a registry dependency): R78 (`opentelemetry-integration`) is the sibling tracing decision for the same web service, decided separately since it is opt-in where this item is on by default.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust crate(s), wired on by default, provide RED (rate, errors, duration) metrics exposed at `/metrics`, excluded from their own measurement and from the generated OpenAPI schema.
- HIGH: What crate or crate combination provides RED-metrics instrumentation and Prometheus exposition for a Rust web service, analogous to `prometheus-fastapi-instrumentator` (candidates to investigate: framework-specific instrumentator middleware such as `axum-prometheus`, or the lower-level `metrics` crate composed with `metrics-exporter-prometheus`)?
- HIGH: Does the candidate exclude the `/metrics` route from its own measurement set out of the box (matching py's "excluded from its own measurements"), or does the template have to hand-wire that exclusion?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). The divergence analysis marked this item harmonize: no; the owner asked for the cross-repo answer anyway, so answer it in full.
- MEDIUM: Is the on-by-default posture (no env var gates metrics collection, unlike R78's opt-in OTel feature and unlike R74's opt-in rate limiting) achievable with a default-enabled dependency and unconditional route registration, or does the candidate itself default to opt-in and need explicit always-on wiring in the template?
- MEDIUM: How does the candidate keep `/metrics` out of the generated OpenAPI schema (`include_in_schema=False` in py) — is this automatic when the metrics route is registered outside the OpenAPI-generation crate's route-registration path (owned by R71), or does it need an explicit exclusion attribute/config?
- LOW: What is the binary-size, compile-time, and dependency-footprint cost of the candidate(s), given this crate ships on by default rather than behind an optional feature?

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
