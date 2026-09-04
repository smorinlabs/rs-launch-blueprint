# Deep-research prompt — Web framework stack (R69, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: which Rust async web framework and server fill the already-decided optional web feature, how already-loaded config threads into request handlers with a lazy-load fallback, how the production entrypoint runs the server with graceful shutdown, and how the dev-server recipe runs with auto-reload and readable console logs. Item kind: `bundle`. Value test: if this answer is wrong, the web crate's framework dependency, its Cargo feature-gate shape, the config-injection mechanism, `main`'s entrypoint, and the dev-serve Justfile recipe all get rewritten — and every consumer of the `web-extra-surface` parameter (R11's CI job structure, R32's test tiers, R37's hook wiring for the OpenAPI snapshot check, R51's container image, R58's logging pipeline profiles, and R71/R82/R83/R84's OpenAPI and docs gates) inherits a wrong assumption about what the web surface contains.

## Context
- Inherited pattern (spec §2, presumption of reuse): py ships a FastAPI web service under an optional install extra, composed by an app-factory function, with config threaded into handlers via FastAPI's dependency-injection mechanism and a lazy-load fallback for callers that bypass the lifespan, a production entrypoint that runs uvicorn with settings-driven graceful shutdown, and a dev-server Justfile recipe with auto-reload and human-readable console logs. ts has no web service at all. Evidence: py `src/py_launch_blueprint/web/app.py:102` — a FastAPI service under an optional install extra, `create_app()` wires settings, handlers, middleware, routers in one function; ts: none — no web/HTTP-server code, dependency, or test exists anywhere in the ts repo (`tests/api.test.ts` is an outbound API client, not a server). Ledger rows: F303, F330, F338, F339 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F330 config loads once at startup, with a lazy-load fallback — py `src/py_launch_blueprint/web/deps.py:37` (`def get_config(request: Request) -> Config:`, falls back to loading lazily for raw-ASGI callers such as schemathesis that bypass the lifespan); ts: none. F338 production entrypoint runs the ASGI server with settings-driven graceful shutdown — py `src/py_launch_blueprint/web/__main__.py:37` (`uvicorn.run(`) and `:42` (`timeout_graceful_shutdown=settings.graceful_shutdown_seconds,`; `python -m py_launch_blueprint.web`, no CLI flags, every knob is an env var); ts: none. F339 dev server recipe runs with auto-reload and pretty console logs — py `Justfile:291` (`serve host="127.0.0.1" port="8000":`; defaults `_LOG_FORMAT` to `console`, prod default is JSON — a dev/prod logging-profile split); ts: none.
- Already decided, do not re-open: whether the web service ships as an optional, separately built Cargo feature at all — `docs/port/COMMONALITY.md` row F017, area `workspace-architecture`, verdict `ADOPT`, no research item, "direct Cargo-optional-feature analogue of py's optional-dependencies extra; nothing to choose." This item decides only which framework and runtime fill that already-decided feature, and what its `web-extra-surface` contents are. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no web-service decision; ts never built a web/HTTP-server capability, so there is no ts shape to reconcile with.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We should look at Hono because that's what we've settled upon, and tRPC as the equivalent for the TypeScript repo should be added. We should copy the same architectural principles and patterns, and have equivalents for a base there. We need to find the equivalent for Rust as a specific research item.

## Out of scope
- The specific features layered on top of the chosen framework once it exists — the error envelope (R70 owns F305/F306), OpenAPI generation (R71 owns F307/F312/F332/F333), pagination (R72 owns F310/F311), idempotency replay (R73 owns F313-F315), rate limiting (R74 owns F316/F323), middleware ordering/request-id/access-log/security headers (R75 owns F317-F321/F327), CORS (R76 owns F322), typed env settings (R77 owns F324), OpenTelemetry (R78 owns F325), Prometheus metrics (R79 owns F326), health probe endpoints (R80 owns F328/F329), and the production container image (R51) — this item decides only the framework/server crate stack, the Cargo feature-gate shape, the config-injection mechanism, and the process entrypoint they all sit inside.
- Whether the web service ships as an optional Cargo feature at all; ledger row F017 (area `workspace-architecture`) already answered `ADOPT` with no research item — this item decides which framework fills that feature, not whether the feature exists.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R69
- owns: web-extra-surface
- consumes: R01: http-transport-injection-seam
- related (not a registry dependency): `web-extra-surface`'s value (this item's `owns` parameter) is consumed by R11 (`ci-workflow-job-structure`, CI job and skip-gating structure), R32 (`test-harness-and-execution`, test tiers), R37 (`hook-manager-distribution`, hook wiring for the OpenAPI snapshot check), R51 (`container-image`), R58 (`logging-pipeline-architecture`, shared logging pipeline profiles), and R71/R82/R83/R84 (the OpenAPI and docs gates) — the Parameters field of this item's answer must state a value precise enough for all of them to consume directly: whether the surface exists as a named Cargo feature, that feature's name, and what crates/capabilities it gates. R01 (`ports-and-adapters-seam`) decides the driven-I/O seam's shape (F001, `http-transport-injection-seam`); this item's web adapter must wire through whichever shape R01 lands on — treat R01's choice as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which Rust async web framework and server fill `rs-launch-blueprint`'s already-decided optional web feature, how that framework threads already-loaded config into handlers with a lazy-load fallback, how the production entrypoint runs the server with graceful shutdown, how the dev-server recipe provides auto-reload with readable console logs, and precisely what the `web-extra-surface` parameter's value is for its nine downstream consumers.
- HIGH: Which Rust async web framework (`axum`, `actix-web`, `warp`, `poem`, etc.) best fits a CLI + library + web template that must later host OpenAPI generation (R71), typed settings (R77), tracing (R78), and metrics (R79) as separately decided layers — and what is that framework's idiomatic extractor/dependency-injection mechanism for threading already-loaded config into a handler, with a lazy-load fallback for callers that bypass application startup (F330)?
- HIGH: What is the Cargo feature-flag shape for the web surface — a single `web` feature mirroring py's install extra, or a nested set of features — and precisely what crates, modules, and binary/library targets does that feature gate? State this as the literal value the nine downstream consumers of `web-extra-surface` need.
- HIGH: What is the idiomatic production entrypoint (F338) — a `main` gated behind the `web` feature, calling the framework's own serve function with a graceful-shutdown signal handler (mirroring py's `timeout_graceful_shutdown`) — and does graceful shutdown need a crate beyond the framework/server itself (e.g. for OS signal handling)?
- MEDIUM: What is the idiomatic dev-server recipe (F339) — a `cargo-watch`/`bacon`-driven auto-rebuild-and-restart loop wired into a Justfile recipe, defaulting to human-readable console logging distinct from the production JSON profile?
- LOW: Does the framework choice constrain, or get constrained by, the driven-I/O seam's transport-injection shape (R01, `http-transport-injection-seam`, not yet decided) — does the web adapter need a specific seam shape (trait object vs. generic bound) to wire cleanly into the framework's handler signatures?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

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
