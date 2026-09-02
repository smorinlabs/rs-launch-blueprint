# Deep-research prompt — Health probe endpoints (R80, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: how `rs-launch-blueprint`'s web service implements its liveness (`/healthz`) endpoint reporting version and runtime info, and its readiness (`/readyz`) endpoint running the same diagnostics as the CLI's `doctor` command. Item kind: `bundle`. Value test: if this answer is wrong, the `/healthz` and `/readyz` route handlers, their response shape, and the diagnostics-sharing code path between the CLI and web front-ends all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py's web layer exposes two ops probes — a liveness endpoint that reports version and runtime info (the web analog of `--version`), and a readiness endpoint that reruns the same diagnostics as the CLI's `doctor` command, returning an RFC 9457 problem document with a 503 status on failure; ts has neither (no web service exists, F303). Evidence: py `src/py_launch_blueprint/web/app.py:153` — `@app.get("/healthz", tags=["ops"])` (F328); py `src/py_launch_blueprint/web/app.py:184` — `async def readyz(` returns 503 problem doc on failure, reusing `core/diagnostics.py`'s `run_diagnostics`, "one source of truth with the CLI" (F329); ts: none. Ledger rows: F328, F329 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Already decided, do not re-open: target shape is CLI + library + web service (spec §4 D7); ops endpoints (`/healthz`, `/readyz`, `/metrics`) are unversioned by convention while business routes are version-prefixed (F308, `ADOPT` — a trivial URL-prefix convention, do not re-derive it, just apply it to the two endpoints this item designs); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — ts never built a web service, so `TS_PORT_DECISIONS.md` has no entry addressing health-probe endpoints.

## Out of scope
- Whether the template adopts a web framework at all, and which one; R69 (`web-framework-stack`) owns `web-extra-surface` — this item does not pick a framework, it decides the two probe endpoints' behavior and describes how they attach to any candidate framework's router.
- The single RFC 9457 problem-document error envelope's shape and the domain-error-to-HTTP-status mapping used by `/readyz`'s 503 response; R70 (`http-problem-envelope`) owns F305/F306 — this item assumes that envelope exists and reuses it, it does not design it.
- Excluding `/healthz`/`/readyz` from access-log volume; R75 (`http-middleware-stack`) owns F320 — this item only designs the probe endpoints themselves, not the access-log middleware that excludes them.
- The container image's own `HEALTHCHECK` directive that probes `/healthz`; R51 (`container-image`) owns F336/F337 — this item decides what `/healthz` returns, not how the container invokes it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R80
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) owns `web-extra-surface` and picks the framework these endpoints are routed through; treat the framework choice as open.
- related (not a registry dependency): R70 (`http-problem-envelope`) decides the problem-document envelope this item's `/readyz` 503 response reuses; assume some RFC 9457 envelope exists and design against it generically.
- related (not a registry dependency): R51 (`container-image`) consumes this item's `/healthz` shape for its container `HEALTHCHECK` directive (F337); do not redesign the container probe here, only note what `/healthz` returns for it to probe.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint` implement its liveness endpoint (version + runtime info) and its readiness endpoint (reruns the CLI's diagnostics, 503 problem document on failure), and what crates/patterns are needed to share the diagnostics logic between the CLI and web front-ends.
- HIGH: What is the idiomatic Rust shape for a shared "diagnostics" function/type — analogous to py's `core/diagnostics.py`'s `run_diagnostics` — that both a CLI `doctor` command and a web `/readyz` handler call as one source of truth, given the port/adapter seam this shared logic sits behind is still open (R01)?
- HIGH: What version and runtime info does the liveness endpoint report (binary version, build metadata, uptime, Rust/toolchain version), and what crate(s) (if any) provide that info at compile time or runtime (candidates: `built`, `vergen`, `std::env!("CARGO_PKG_VERSION")` alone)?
- MEDIUM: Does readiness-check failure need any crate beyond what R70's problem-envelope and R69's framework already provide, or is `/readyz` purely a composition of existing pieces (diagnostics function + envelope + 503 status)?
- MEDIUM: Should liveness/readiness reporting use structured types (`serde`-derived response bodies) matching the OpenAPI-schema conventions the rest of the web service uses (owned by R71), or is a minimal, schema-agnostic response acceptable for ops-only endpoints?
- LOW: Do comparable Rust web-service templates or frameworks ship a first-class liveness/readiness pattern (e.g. a crate or framework extension specifically for Kubernetes-style probes) worth surveying for precedent?

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
