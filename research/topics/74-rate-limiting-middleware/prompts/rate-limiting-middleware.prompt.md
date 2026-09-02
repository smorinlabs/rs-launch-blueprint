# Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no rate-limiting shape to reconcile with.

## Out of scope
- Which web framework hosts this middleware; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the middleware to fit whichever framework's middleware/service-layer model wins.
- The problem+json envelope the 429 response renders through; R70 (`http-problem-envelope`) owns F305/F306 — this item decides the rate-limit behavior and its env-var gate, not the envelope shape its errors render into.
- Where this middleware sits relative to the request-id/security-header/access-log ordering contract; R75 (`http-middleware-stack`) owns F317 — this item does not decide where in the stack rate limiting sits.
- The idempotency cache's own in-memory store; R73 (`idempotency-middleware`) owns F315 — a separate cache with separate semantics despite the shared "in-memory, single-instance by design" phrasing.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R74
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this rate-limiting middleware must integrate with, and R70 (`http-problem-envelope`) decides the envelope shape 429 responses render through — treat both as open, do not block on them. R75 (`http-middleware-stack`) owns the overall middleware ordering contract (F317) this middleware must be placed within.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts a Rust rate-limiting middleware, off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429s with an accurate `Retry-After`.
- HIGH: Which Rust rate-limiting crate (e.g. a `tower`-compatible governor-based layer, or another middleware-layer crate) is idiomatic for a leading async web framework, and does it default to (or easily support) an in-memory backend with a documented swap point for a distributed store?
- HIGH: What is the idiomatic way to make the middleware off-by-default and gated by one env var/config value (mirroring py's `rate_limit: str | None = None`) — a config-driven conditional layer registration, or a feature flag plus a runtime toggle?
- MEDIUM: Does the chosen crate compute an accurate `Retry-After` header value out of the box, or does the middleware need custom response-rewriting to add it?
- MEDIUM: How does a 429 from this middleware reach the eventual problem+json envelope (R70, not yet decided) — does the crate return a plain response the envelope layer must intercept, or does it need a custom error type implementing whatever error-to-response trait R70 lands on?
- LOW: Do any published Rust web-service templates document an off-by-default, env-var-gated rate limiter as a named pattern, and where?

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
