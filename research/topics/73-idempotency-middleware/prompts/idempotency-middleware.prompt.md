# Deep-research prompt — Idempotency middleware (R73, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts an idempotency-key replay middleware for unsafe-method (POST/PUT/PATCH) requests, caching only successful (2xx) outcomes in an in-memory, single-instance-by-design store documented as a future distributed-store swap point. Item kind: `bundle`. Value test: if this answer is wrong, the middleware layer that intercepts unsafe-method requests, the cache-key derivation, the 2xx-only store-write condition, and the in-memory store type all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py replays a cached response for unsafe-method requests carrying an `Idempotency-Key` header, stores only successful (2xx) outcomes so genuine errors are retried rather than replayed, and backs the cache with an in-memory, single-instance-by-design store explicitly documented as a future swap point rather than built out. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/idempotency.py:43` — `IDEMPOTENCY_HEADER = "idempotency-key"` on POST/PUT/PATCH (WEB-05; replayed responses carry `Idempotency-Replayed: true`); ts: none. Ledger rows: F313, F314, F315 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F314 cache stores only successful (2xx) outcomes — py `src/py_launch_blueprint/web/idempotency.py:141` — `if 200 <= response.status_code < 300:` (Stripe semantics: errors are meant to be retried for real, not replayed); ts: none. F315 cache store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/idempotency.py:91` — `self._store: OrderedDict[_CacheKey, _Entry] = OrderedDict()` (documented as a Redis-swap point before scaling to multiple instances; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no decision addressing web-service scope; ts never built a web service, so there is no idempotency shape to reconcile with.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We should do the research for both the equivalency and best practice for TypeScript and Rust using the same principles as the PyLaunch template.

## Out of scope
- Which web framework hosts this middleware; R69 (`web-framework-stack`) owns F303 and the `web-extra-surface` parameter — assume R69 resolves to some framework and design the middleware to fit whichever framework's middleware/service-layer model wins.
- Where this middleware sits relative to the request-id/security-header/access-log ordering contract; R75 (`http-middleware-stack`) owns F317 — this item decides the idempotency-cache behavior itself, not where it sits in the overall middleware stack.
- Rate limiting's own in-memory store and env-var gate; R74 (`rate-limiting-middleware`) owns F316/F323 — a separate cache with separate semantics, not this item's concern despite the shared "in-memory, single-instance by design" phrasing.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R73
- owns:
- consumes:
- related (not a registry dependency): R69 (`web-framework-stack`) decides which framework/middleware-layer model this idempotency middleware must integrate with — treat R69's choice as open. R75 (`http-middleware-stack`) owns the overall middleware ordering contract (F317) this middleware must be placed within — this item does not decide that ordering.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint` adopts an idempotency-key replay middleware for unsafe-method requests, caching only successful (2xx) outcomes in an in-memory, single-instance-by-design store documented as a future swap point.
- HIGH: Does a published Rust middleware crate already implement `Idempotency-Key` request replay for a leading async web framework, or does this need a hand-rolled middleware layer wrapping a generic key-value store trait — so a future distributed-store swap is a store-implementation change, not a middleware rewrite?
- HIGH: What Rust idiom expresses "only cache successful outcomes" (F314) — inspecting the response status inside the middleware's response-side logic before insert — and does the crate/pattern make the 2xx-only rule an explicit, testable condition rather than an incidental default?
- MEDIUM: What in-memory store type mirrors py's ordered, evictable cache (F315) — a `HashMap` behind a mutex, a crate-provided LRU/TTL cache, or a bespoke bounded structure — and what is the idiomatic concurrency-safe wrapper for a request-handling context?
- MEDIUM: How does the cache key get derived and scoped (mirroring py's `_CacheKey`) — the raw header value alone, or a composite of header value plus request method/path/body-hash, to prevent cross-endpoint replay collisions?
- LOW: Do any published Rust web-service templates document Stripe-style idempotency-key replay as a named pattern, and where?

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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
