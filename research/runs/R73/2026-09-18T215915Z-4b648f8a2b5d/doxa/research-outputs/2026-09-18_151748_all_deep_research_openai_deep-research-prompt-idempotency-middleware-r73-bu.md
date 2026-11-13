---
prompt: # Deep-research prompt — Idempotency middleware (R73, bundle)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
mode: all_deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260918-151748-c3450952b9d24d59
created_at: 2026-09-18T15:17:48.557633
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Idempotency middleware (R73, bundle)

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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

Tier execution guidance (approved 2026-09-04; the mirrored research/EXECUTION.json policy is authoritative):
- Light runs Codex for the raw answer and a fresh Terra evidence check; Focused runs Codex and Opus; Deep runs Codex, Opus, and Doxa. R38 is Focused with all three engines as the pilot exception.
- This item's effort tier changes execution breadth only. It does not remove any prompt section, approved question, owner requirement, shared principle, acceptance criterion, or applicable fitness gate.
- Apply every fitness gate above. If a metric is inapplicable to this item kind, state `inapplicable` and the reason in the answer; do not omit it silently. Crate candidates require the crate figures; pattern candidates use the pattern fields and explain why crate figures do not apply; bundle members require the crate figures for each crate member.
- The item-specific empirical acceptance check remains mandatory. `acceptance-after` records a post-research integration prerequisite and does not replace research evidence or acceptance.

## Answer template
Use exactly these field names as H3 headings, in this order.

### Landscape
The survey-method output (`## Required evidence`): the three-bin map with the candidates found in each, the authoritative sources used and why each counts, and the well-regarded projects surveyed with the evidence that they are well regarded.
### Principles and implementation
State the shared requirement, its source and agreement level, the essential behaviors, and observable acceptance criteria. Distinguish what must agree from what may vary. If an architectural pattern is shared, verify that it remains appropriate in the target ecosystem. Compare architectural alternatives before choosing libraries; explain how the recommended design preserves each principle and where a different ecosystem needs a different design. Cite production usage and maintained reference examples, compare maturity, dependability, representative performance and integration cost, and explain the tradeoffs. Specify a minimal realistic example and an executable acceptance check; distinguish proposed checks from checks actually run. Include any `BASELINE-REVIEW:` finding with its feature ID, affected items and evidence.
### Recommendation
One stack.
### Members
For each member, use a `#### <member name>` heading. Under it, use these `#####` headings in this exact order: `Landscape`, `Principles and implementation`, `Dominant choice`, `Qualified shortlist`, `Excluded by gate`, `Up-and-comers`, `Fit for this template`, `Recommendation`, `Ranked runner-up`, `Tradeoffs`, `Parameters`, `Migration implications`, `Validation strategy`, `Confidence & re-verify trigger`, `Sources`. Fill every field with member-specific evidence.
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
```

## Reasoning Summary
**Researching candidates**

I need to find out the exact versions, MSRV, licenses, dependencies, CI OS, advisories, downloads, and GitHub stats for various crates. The candidates could include something like the idempotent crate or axum-idempotent. I should search for them. The project, R69, is open, and I want to ensure it’s framework agnostic. I’m considering the possibility of an idempotent middleware crate, so I need to explore that right away.

### Landscape

**Category decided:** application-level HTTP idempotency and response replay for mutating requests. This is distinct from ordinary RFC-style HTTP response caching: it must coordinate first execution, detect conflicting key reuse, and replay an operation’s prior result without re-running side effects. The IETF HTTPAPI working-group draft describes this state machine, although revision 07 expired on **April 18, 2026** and is not an RFC. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/))

**Retrieval date:** September 18, 2026. The mandated crates.io and GitHub JSON metric endpoints were attempted, but most returned access errors in this research environment. Their figures are reported as unavailable rather than replaced with nonconforming estimates. Popularity was therefore excluded from the decision.

#### Three-bin map

| Bin | Candidates found | Assessment |
|---|---|---|
| Built-in or first-party toolchain | Rust `std::{collections::{HashMap, VecDeque}, sync::{Arc, Mutex}, time::Instant}`; R69 framework-native middleware adapter; Tower `Service`/`Layer` when R69 is Tower-compatible | No built-in idempotency implementation, but all primitives needed for a small bounded store and middleware state machine exist. Tower is explicitly intended as a reusable middleware integration point. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/)) |
| Established industry pattern | Client-provided `Idempotency-Key`; operation-scoped lookup key; separate request fingerprint; atomic in-flight reservation; replay of the completed result; published expiry policy | This is the dominant architectural pattern. There is not yet a final IETF standard, and status-persistence policies differ between implementations. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07)) |
| Up-and-comers | `axum-idempotent` 0.3.0; `cratestack-axum` 0.12.0; the `idempotency-rs` sample repository; `http-cache-tower-server` 0.2.4 as adjacent prior art | Published implementations now exist, but none meets this bundle’s complete framework-neutral, bounded-memory, atomic-store, swap-ready and policy requirements without substantial adaptation. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest)) |

`moka` 0.12.16 is the established general-purpose concurrent-cache candidate. It supports bounded capacity, TTL and atomic per-key insertion, and its maintainers explicitly compare it with simpler caches and acknowledge it can be overkill. Its current documentation says macOS is expected to work but is **not tested in upstream CI**, so it fails this item’s literal OS evidence gate today. ([docs.rs](https://docs.rs/crate/moka/latest))

#### Authority used

| Source | Why authoritative | Limitation |
|---|---|---|
| RFC 9110 and IETF HTTPAPI draft 07 | Standards-body definition of HTTP method and proposed `Idempotency-Key` semantics | The idempotency document is an expired Internet-Draft, not a standard. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)) |
| Stripe API documentation | Primary documentation for a large production idempotency implementation | Vendor policy, not a universal standard. ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=)) |
| Tower, Axum and Tokio documentation/source | Maintainer-owned definitions of Rust middleware and synchronization idioms | They supply mechanisms, not an idempotency policy. ([docs.rs](https://docs.rs/axum/latest/axum/middleware/)) |
| Maintainers’ crate docs/source | Primary evidence for versions, features, defaults and integration requirements | Some crates lack the maintenance and platform evidence required by this prompt. |
| Well-regarded project manifests | Direct adoption evidence rather than popularity inference | Adoption proves interoperability, not suitability for this template. |

#### Practice evidence

- **Axum** uses Tower’s middleware model rather than inventing a separate one; **Tonic** also integrates Tower. Both are maintained by major Tokio/Hyper ecosystem teams. ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- The official **AWS SDK for Rust** SigV4 implementation currently depends on `sha2 = "0.11"`, supporting SHA-256 as a maintained ecosystem choice for request fingerprints. ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))
- `cratestack-axum` provides the strongest maintained Rust reference found for an idempotency-specific store interface: principal scoping, payload fingerprints, atomic `reserve_or_fetch`, replay and conflict handling. It is, however, part of a much larger schema-first framework and currently supplies SQL/Redis stores rather than the required small in-memory profile. ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- `axum-idempotent` 0.3.0 provides a real published Axum layer, direct header-key mode, response replay and configurable ignored status codes. It is coupled to `ruts` sessions and cookie/session layer ordering, and its direct mode uses the header value as the key rather than providing the operation/principal/fingerprint contract required here. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))
- No mainstream, widely adopted Rust web-service template was found documenting this complete pattern. The available evidence consists mainly of young middleware crates, sample repositories and recent tutorials. That is an evidence gap, not evidence that the capability is inappropriate.

### Principles and implementation

#### Shared requirement and agreement level

| Level | Required agreement |
|---|---|
| Capability | Requests using `Idempotency-Key` on configured mutating methods can be retried without re-running a previously completed operation. |
| Architectural pattern | A thin HTTP adapter delegates to an idempotency-specific store interface; the initial implementation is bounded, in-memory and explicitly single-instance; a distributed implementation replaces the store, not the HTTP algorithm. |
| Policy | Key scope, payload-conflict behavior, in-flight behavior, retention, replay marker, cacheable response contract and failure behavior must be explicit and tested. |
| Ecosystem-specific variation | The concrete middleware trait—Tower `Layer`, Axum function middleware, Actix `Transform`, or another R69-native mechanism—may vary. |
| Out of scope here | Overall middleware ordering remains R75’s decision, but R75 must provide an operation boundary at which authentication scope and “handler execution began” are observable. |

The common principle is **not merely “cache 2xx responses.”** It is: *bind retries for one logical operation to one execution and one recorded outcome, while rejecting ambiguous key reuse*. The IETF draft separately identifies completed retries, conflicting payloads and concurrent in-flight retries. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

#### Baseline review

**BASELINE-REVIEW: F314 — at-most-once effect after operation execution begins — proposed change: replace unconditional “store only 2xx” with “store every completed handler outcome, success or error; do not store failures rejected before handler execution”; retain `SuccessOnly` only as an explicit compatibility policy for handlers that guarantee every non-2xx outcome is side-effect-free — affected: R73/F314 only; F313 and F315 remain unchanged — evidence: Stripe stores and replays the first completed result including 500 responses, while the IETF draft says a completed retry should receive the previous success or error.** ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

The supplied baseline’s description of 2xx-only behavior as “Stripe semantics” is factually incorrect as of September 18, 2026. Stripe says that validation failures and concurrent conflicts are retryable because execution has not begun, but once execution begins it saves the resulting status and body even for `500`. ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))

There is a legitimate competing policy: `axum-idempotent` defaults to excluding a set of transient or request-envelope errors, including common 5xx statuses. That enables a real retry, but it is safe only if those responses prove the protected operation committed no side effect. HTTP status alone cannot establish that invariant. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))

If the owner declines the baseline review and retains F314, the Rust condition should be direct and named—not an incidental library default:

```rust
pub enum PersistencePolicy {
    CompletedOutcome,
    SuccessOnly,
}

impl PersistencePolicy {
    fn should_store(&self, execution_started: bool, status: StatusCode) -> bool {
        execution_started
            && match self {
                Self::CompletedOutcome => true,
                Self::SuccessOnly => status.is_success(), // exactly 200..=299
            }
    }
}
```

#### Architectural alternatives

| Alternative | Advantages | Failure or cost | Verdict |
|---|---|---|---|
| Adopt `axum-idempotent` directly | Published; replay header; configurable status list; request hashing mode | Axum- and session-layer-coupled; R69 unresolved; direct-key scope does not provide the required operation/principal/fingerprint model; MSRV and macOS gate evidence incomplete | Exclude |
| Adopt `cratestack-axum` directly | Strong atomic store semantics and distributed implementations | Pulls in a schema-first framework and numerous unrelated crates; lacks the desired small in-memory profile | Exclude |
| Wrap a generic `get`/`put` key-value trait | Superficially simple distributed swap | Check-then-insert races allow two concurrent requests to execute; distributed backends need atomic reservation semantics that generic KV does not express | Reject |
| Internal idempotency state machine over an `IdempotencyStore` trait | Exact policy, framework-neutral core, atomic contract, minimal store, future backend swap | Approximately 150–250 lines plus tests; project owns correctness | **Choose** |
| Domain transaction/outbox/unique constraint only | Strongest guarantee when the side effect and idempotency record commit atomically | Operation-specific, cannot generically replay arbitrary HTTP responses, outside this middleware bundle | Complementary future hardening |

The store abstraction should therefore be idempotency-specific, with atomic operations such as `begin`, `complete` and `abort`, rather than a generic key-value interface. `cratestack`’s `reserve_or_fetch` design is useful reference evidence for this principle. ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))

#### Request participation

- Intercept only `POST`, `PUT` and `PATCH` requests carrying exactly one non-empty `Idempotency-Key`.
- Requests without the header pass through unchanged.
- Other methods bypass the engine.
- Keep `PUT` for Python-port equivalence even though HTTP already defines its intended effect as idempotent.
- Reject malformed, duplicate or oversized keys before reserving an entry. A 255-byte limit is compatible with Stripe’s documented limit, but should be explicit configuration rather than an accidental parser limit. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

#### Cache key and fingerprint

Do **not** put the body hash into the lookup key. If the body hash were part of the key, reusing one idempotency key with a different payload would become a cache miss and execute a second operation.

Use:

```text
CacheKey =
    service namespace
  + authenticated principal/tenant scope when available
  + HTTP method
  + effective operation target
  + raw Idempotency-Key value
```

Use a separately stored fingerprint:

```text
FingerprintV1 =
    SHA-256(
        length-prefixed content-type
      + length-prefixed content-encoding
      + length-prefixed body bytes
      + any operation-declared material headers
    )
```

The effective target should include the actual normalized path and query, or an R69-provided stable operation identifier plus material path/query parameters. A route template alone is insufficient because `/orders/1` and `/orders/2` would collide. The IETF draft expressly permits a checksum of all or selected request payload fields as the fingerprint and recommends rejecting reuse with a different payload. ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))

A principal scope must use a stable internal tenant/user identifier, not raw credentials. If no authenticated principal is available, use a service-wide namespace and document that keys must then be globally unique within the instance.

#### In-memory store

Use:

```rust
Arc<std::sync::Mutex<MemoryState>>
```

with:

```rust
struct MemoryState {
    entries: HashMap<CacheKey, Entry>,
    recency: VecDeque<RecencyToken>,
    resident_bytes: usize,
    next_generation: u64,
}

enum Entry {
    InFlight {
        fingerprint: Fingerprint,
        lease: LeaseId,
        expires_at: Instant,
        generation: u64,
    },
    Completed {
        fingerprint: Fingerprint,
        response: Arc<CachedResponse>,
        expires_at: Instant,
        weight: usize,
        generation: u64,
    },
}
```

A generation-tagged `VecDeque` permits amortized O(1) lazy LRU maintenance: stale queue records are skipped when popped. Capacity must be bounded by both entry count and resident bytes; request fingerprint, response body and headers count toward the weight.

`std::sync::Mutex` is appropriate because the lock protects short, non-awaiting in-memory mutations only. Tokio’s documentation says the ordinary blocking mutex is often preferred in async code when the guard is not held across `.await`; the async mutex is more expensive and is principally for shared I/O resources. ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))

Store behavior:

1. Purge expired records.
2. On absent key, atomically insert `InFlight` and return a lease.
3. On matching `Completed`, return the stored response.
4. On a different fingerprint, return `422 Unprocessable Content`.
5. On matching `InFlight`, return `409 Conflict`.
6. On capacity exhaustion with no safe eviction candidate, reject before invoking the handler.
7. Never hold the mutex while awaiting the handler or reading/writing an HTTP body.

This mirrors Python’s ordered, evictable store while adding explicit concurrency semantics.

#### Response completion and replay

A completed snapshot should contain:

- status code;
- bounded body bytes;
- stable end-to-end response headers;
- completion time and expiry;
- the original request fingerprint.

Exclude or regenerate hop-by-hop and per-attempt headers such as connection framing and the current request ID. On replay, add:

```http
Idempotency-Replayed: true
```

Application errors that should be replayed must be normalized into HTTP responses inside the protected operation boundary. A raw service error with no replayable HTTP result should call `abort`, unless the adapter can produce a deterministic response.

Streaming or unbounded responses are not eligible. If an operation can commit a side effect and then exceed the response snapshot limit, preserve an `UnreplayableCompleted` tombstone and reject later retries rather than re-executing the operation.

#### Minimal reference flow

```rust
async fn handle<S, F>(
    store: &S,
    policy: PersistencePolicy,
    request: Request,
    next: F,
) -> Response
where
    S: IdempotencyStore,
    F: OperationService,
{
    if !matches!(request.method(), POST | PUT | PATCH) {
        return next.call(request).await;
    }

    let Some(header_key) = parse_idempotency_key(request.headers()) else {
        return next.call(request).await;
    };

    let (parts, body) = collect_request_with_limit(request).await?;
    let key = derive_scoped_key(&parts, header_key)?;
    let fingerprint = fingerprint_v1(&parts, &body);

    match store.begin(&key, &fingerprint).await? {
        Begin::Replay(snapshot) => return snapshot.replay_with_header(),
        Begin::FingerprintConflict => return problem_422(),
        Begin::InFlight => return problem_409(),
        Begin::Leader(lease) => {
            let request = rebuild_request(parts, body);
            let result = next.call_operation(request).await;

            match result {
                Ok(response) => {
                    let execution_started = true;
                    let (response, snapshot) =
                        snapshot_response_with_limit(response).await?;

                    if policy.should_store(execution_started, snapshot.status) {
                        store.complete(lease, snapshot).await?;
                    } else {
                        store.abort(lease).await?;
                    }

                    response
                }
                Err(error) => {
                    store.abort(lease).await?;
                    map_service_error(error)
                }
            }
        }
    }
}
```

#### Observable acceptance criteria

| Case | Expected result |
|---|---|
| No header | Handler executes on every request; no replay header |
| GET/DELETE with header | Bypassed |
| Same scope, method, target, key and fingerprint after completion | Original status/body/stable headers replayed; `Idempotency-Replayed: true`; handler count remains one |
| Same raw key on another path, method or principal | Independent operation |
| Same scoped key with different body | `422`; handler is not called |
| Concurrent matching requests | One handler execution; other request receives `409` |
| Completed handler returns `500`, recommended policy | Second request replays the same `500`; handler count remains one |
| Pre-handler validation returns `400` | Not persisted; corrected request with the same key may execute |
| TTL expiry or completed-entry eviction | Request may execute again; limitation documented |
| Process restart | Entry is lost; single-instance/non-durable limitation documented |
| Store reaches capacity with only in-flight entries | Reject before handler execution |
| Future distributed store | Same adapter and contract tests pass against another `IdempotencyStore` implementation |

#### Representative performance evaluation

No benchmark was executed during this research, and no absolute-fastest claim is made.

The acceptance benchmark should cover:

- 1 KiB and 64 KiB JSON bodies;
- 1 KiB responses;
- 0%, 50% and 99% replay-hit workloads;
- concurrency 1, 32 and 256;
- handlers taking 0 ms, 10 ms and 100 ms;
- sequential duplicates and same-key concurrent bursts;
- capacity and expiry churn.

Measure:

- p50/p95/p99 latency;
- handler execution count;
- mutex acquisition wait;
- fingerprint time;
- cache hit/miss/conflict/eviction counts;
- resident bytes and peak RSS;
- incremental clean-build time and release binary size.

Moka is the appropriate comparison implementation if the bespoke lock becomes measurable. Its richer concurrency and eviction machinery should not be presumed faster for this workload without a like-for-like benchmark. ([docs.rs](https://docs.rs/crate/moka/latest))

### Recommendation

**Do not adopt the bundle exactly as currently worded. Adopt F313 and F315, and send F314 through the stated baseline-review process.**

One stack:

1. **Internal framework-neutral `IdempotencyEngine` and `IdempotencyStore` contract, versioned as an application-internal pattern.**
2. **In-memory store:** `Arc<std::sync::Mutex<MemoryState>>` containing a bounded `HashMap` plus generation-tagged `VecDeque`.
3. **Fingerprint:** `sha2` **0.11.0**, SHA-256, with an explicit `FingerprintV1` wire/storage format.
4. **HTTP adapter:** the R69-native middleware model. The maintained reference profile is `tower` **0.5.3** with default features disabled if R69 selects a Tower-compatible framework.
5. **Default persistence policy:** `CompletedOutcome`, not `SuccessOnly`.
6. **Compatibility policy:** retain a named `SuccessOnly` option whose only store condition is `response.status().is_success()`.
7. **Future swap point:** implement Redis/SQL using the same atomic `IdempotencyStore` operations; do not expose a generic KV interface.

### Members

#### Internal `IdempotencyEngine` + bounded memory store

##### Landscape

This is an architectural-pattern member; crate download, release, repository and advisory figures are **inapplicable** because it is template-owned source rather than a published crate.

Maintenance state: **active**, owned and tested with the template.

##### Principles and implementation

The engine owns the idempotency state machine, while the R69 adapter owns HTTP body conversion and middleware trait plumbing. The memory store implements the same atomic contract expected of a future distributed store.

The core should have no dependency on Axum, Actix or another framework. HTTP-specific request extraction belongs in the adapter; key, fingerprint, reservation and response-snapshot types belong in the core.

##### Dominant choice

A small internal state machine is the dominant fit because no surveyed crate simultaneously provides:

- framework independence;
- POST/PUT/PATCH participation;
- principal and operation scoping;
- separate fingerprint conflict handling;
- atomic in-flight reservation;
- an ordered bounded memory store;
- explicit response-persistence policy;
- a future distributed-store interface.

##### Qualified shortlist

Only the internal state-machine pattern passed the complete semantic fit check.

`Moka` passed the functionality check for bounded TTL storage, but not the required upstream macOS test-evidence gate. ([docs.rs](https://docs.rs/crate/moka/latest))

##### Excluded by gate

| Candidate | Gate/result |
|---|---|
| `axum-idempotent` 0.3.0 | Excluded: Axum/session/cookie coupling; direct-key scope mismatch; no verified `rust-version` or macOS CI evidence; response policy differs. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest)) |
| `cratestack-axum` 0.12.0 | Excluded: substantial unrelated framework surface and no required memory backend; package-level MSRV/OS evidence not completed. ([docs.rs](https://docs.rs/crate/cratestack-axum/latest)) |
| `moka` 0.12.16 | Excluded by gate 4: current docs state macOS is not tested in upstream CI. Also qualitatively heavier than the required store. ([docs.rs](https://docs.rs/crate/moka/latest)) |
| `idempotency-rs` | Excluded: repository describes itself as a sample; the advertised publication/version could not be independently verified through the mandated registry endpoint. ([github.com](https://github.com/bhatti/idempotency-rs)) |
| `http-cache-tower-server` | Excluded by category: implements ordinary HTTP response-cache semantics, not atomic operation idempotency. ([docs.rs](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/)) |

##### Up-and-comers

`axum-idempotent` and `cratestack-axum` should be re-evaluated if they split out a small framework-neutral core with an atomic memory store and declared MSRV/platform matrix.

##### Fit for this template

The internal pattern keeps the CLI and library surfaces independent of the web framework. It adds no cache runtime, allocator or synchronization dependency and makes the single-instance limitation visible in application-owned documentation.

##### Recommendation

Implement:

- `IdempotencyStore` with atomic `begin`, `complete`, `abort`;
- `MemoryIdempotencyStore`;
- `PersistencePolicy::{CompletedOutcome, SuccessOnly}`;
- `KeyScope` and `OperationTarget` extractor interfaces;
- versioned fingerprint encoding;
- bounded response snapshots;
- metrics and replay header.

Place `#![forbid(unsafe_code)]` on the owning module or crate.

##### Ranked runner-up

`moka::future::Cache` 0.12.16, after downstream ubuntu/macOS CI evidence is obtained and only if benchmarks show the single mutex is material. Moka supports TTL, weighted capacity and atomic per-key insertion, but its richer eviction machinery is unnecessary for the initial template. ([docs.rs](https://docs.rs/crate/moka/latest))

##### Tradeoffs

Advantages:

- minimum dependency and compile cost;
- exact policy;
- straightforward deterministic tests;
- mirrors Python’s ordered store;
- future backend contract designed correctly from the start.

Costs:

- project owns eviction and expiration correctness;
- coarse lock can become a bottleneck at unusually high key cardinality;
- in-memory retention is neither durable nor cross-instance;
- bounded eviction means the published idempotency window is best-effort.

##### Parameters

Required constructor parameters; do not hide them in incidental defaults:

- methods: `POST`, `PUT`, `PATCH`;
- header: `Idempotency-Key`;
- replay header: `Idempotency-Replayed`;
- completed-entry TTL;
- in-flight timeout;
- maximum entries;
- maximum resident bytes;
- maximum request and replayable-response bytes;
- key length limit;
- persistence policy;
- principal/tenant scope extractor;
- material-header allowlist.

No registry-owned R73 parameter currently exists for these values.

##### Migration implications

Add:

- `src/web/idempotency/mod.rs`
- `src/web/idempotency/engine.rs`
- `src/web/idempotency/store.rs`
- `src/web/idempotency/memory.rs`
- `src/web/idempotency/fingerprint.rs`
- `src/web/idempotency/policy.rs`
- `src/web/idempotency/adapter_<r69>.rs`
- `tests/idempotency_http.rs`
- `docs/architecture/idempotency.md`

Record the F314 review in `docs/port/OWNER-REVIEW.md`; do not edit the commonality verdict silently.

##### Validation strategy

Planned:

- unit tests for every store transition;
- model/property tests over randomized begin/complete/expire/evict sequences;
- concurrent same-key integration test;
- process-restart test;
- capacity-exhaustion test;
- shared contract suite reusable by a future Redis/SQL store.

No implementation tests were executed during this research.

##### Confidence & re-verify trigger

**Confidence: high** for the architectural pattern; **medium-high** for the recommended persistence-policy change.

Re-verify if:

- R69 selects a framework without a usable route-level middleware boundary;
- R75 cannot distinguish pre-operation rejection from operation execution;
- a mature framework-neutral crate appears;
- multi-instance deployment becomes a supported template mode.

##### Sources

Retrieved September 18, 2026:

- IETF draft: `https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))
- Stripe semantics: `https://docs.stripe.com/api/idempotent_requests?query=` ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))
- Tokio mutex guidance: `https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))
- Cratestack reference: `https://rust-doc.cratestack.dev/cratestack/idempotency/index.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- Moka comparison: `https://docs.rs/crate/moka/latest` ([docs.rs](https://docs.rs/crate/moka/latest))

#### `tower` 0.5.3 reference adapter

##### Landscape

Tower is the established middleware abstraction for Axum and several other Tokio/Hyper ecosystem projects. Tower’s `Service` and `Layer` traits are deliberately stable integration points, and Axum directly adopts them. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

Maintenance state: **stable-quiet**. Version 0.5.3 was published on January 12, 2026; the greater-than-six-month release interval triggers investigation but is not an at-risk signal for a stable core abstraction. ([docs.rs](https://docs.rs/crate/tower/latest))

Required figures:

| Figure | Required source | Result on 2026-09-18 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/tower` → `crate.recent_downloads` | Unavailable: endpoint fetch failed |
| All-time downloads | same → `crate.downloads` | Unavailable |
| Last release | `GET https://crates.io/api/v1/crates/tower/versions` | Mandated endpoint unavailable; docs.rs fallback: 0.5.3, January 12, 2026 |
| Stars, archived, pushed | `GET https://api.github.com/repos/tower-rs/tower` | Unavailable |
| Open issues | GitHub issue-search endpoint | Unavailable |
| Issue responsiveness | 10 most recently opened issues | Not computable because API issue data was unavailable |
| Advisories | `https://rustsec.org/packages/tower.html` | Endpoint unavailable; `cargo audit` is a merge gate |
| Adopters | Reverse dependencies plus manifests | Axum and Tonic directly demonstrate Tower integration. ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml)) |

No missing metric was replaced with a scraped approximation.

##### Principles and implementation

The adapter should be thin:

- parse participation data;
- buffer/rebuild bounded bodies using R69’s body API;
- derive operation scope;
- call the framework-neutral engine;
- turn replay/conflict states into responses;
- snapshot the completed response.

It must not contain store-specific logic.

##### Dominant choice

If R69 selects Axum or another Tower-compatible framework, implement a concrete `Layer` and `Service`. Tower explicitly supports application-specific middleware wrapping an inner service. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

##### Qualified shortlist

- `tower` 0.5.3, default features disabled;
- direct `tower-layer`/`tower-service` traits if R69 already exposes them and the full `tower` crate adds no utility needed.

##### Excluded by gate

- A direct unconditional R73 dependency is excluded until R69 chooses its framework.
- An Axum-only `middleware::from_fn` implementation is excluded from the core because it would force an R69 decision in R73.
- Final release remains gated on `cargo audit` and the mandated ubuntu/macOS matrix because the required API evidence could not be retrieved.

##### Up-and-comers

Framework-specific macro/function middleware can reduce boilerplate, but it does not improve the underlying store contract and would increase coupling.

##### Fit for this template

Tower provides the right compositional boundary for a CLI + library + web-service workspace: only the web member depends on the adapter; the library and CLI do not.

##### Recommendation

Reference profile:

```toml
[dependencies]
tower = { version = "0.5.3", default-features = false }

[dev-dependencies]
tower = { version = "0.5.3", default-features = false, features = ["util"] }
```

If R69 selects a non-Tower framework, replace only `adapter_<r69>.rs`; retain the engine, store, keys, fingerprints, policy and contract tests.

##### Ranked runner-up

Depend directly on:

```toml
tower-layer = "0.3.3"
tower-service = "0.3.3"
```

This reduces surface area but loses `ServiceExt::oneshot` and other test ergonomics unless those are added separately.

##### Tradeoffs

Tower’s type-heavy middleware composition can produce longer compile errors and some monomorphization. It otherwise has low incremental runtime cost, no default optional middleware features, and its crate root forbids unsafe code. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))

##### Parameters

- version: 0.5.3;
- production features: none;
- test feature: `util`;
- MSRV declared upstream: Rust 1.64.0, comfortably below this template’s current 1.96 floor;
- license: MIT;
- runtime coupling: none in the core traits; concrete R69 server supplies the runtime. ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))

##### Migration implications

- Add Tower only to the web-service crate.
- Implement `IdempotencyLayer<S>` and `IdempotencyService<Inner, S>`.
- Keep `MemoryIdempotencyStore` in a framework-neutral module.
- Add `oneshot` integration tests without binding sockets where possible.

##### Validation strategy

Planned:

```bash
cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 test --workspace
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo tree -e features -i tower
cargo audit
```

Run the first three commands on both `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

**Confidence: high** that Tower is the correct adapter abstraction if R69 is Tower-compatible; **conditional** on R69.

Re-verify on:

- R69 completion;
- Tower 0.6;
- an MSRV change;
- any RustSec advisory;
- failure of the downstream macOS matrix.

##### Sources

Retrieved September 18, 2026:

- `https://docs.rs/crate/tower/0.5.3` ([docs.rs](https://docs.rs/crate/tower/latest))
- `https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig` ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))
- `https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs))
- `https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md` ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md))
- `https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml))
- `https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml))

#### `sha2` 0.11.0

##### Landscape

SHA-256 is an established standardized digest, while `sha2` is the RustCrypto implementation. Version 0.11.0 was released on March 25, 2026. ([docs.rs](https://docs.rs/crate/sha2/latest))

Maintenance state: **active**.

Required figures:

| Figure | Required source | Result on 2026-09-18 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/sha2` | Unavailable: endpoint fetch failed |
| All-time downloads | same | Unavailable |
| Last release | `GET https://crates.io/api/v1/crates/sha2/versions` | Mandated endpoint unavailable; docs.rs fallback: 0.11.0, March 25, 2026 |
| Stars, archived, pushed | `GET https://api.github.com/repos/RustCrypto/hashes` | Unavailable |
| Open issues | GitHub issue-search endpoint | Unavailable |
| Issue responsiveness | 10 recent issues | Not computable |
| Advisories | `https://rustsec.org/packages/sha2.html` | RustSec lists historical RUSTSEC-2021-0100 concerning an old AVX2 backend; locked 0.11.0 must still pass `cargo audit`. ([rustsec.org](https://rustsec.org/packages/sha2.html)) |
| Adopters | Reverse dependencies plus manifest | AWS SDK for Rust’s SigV4 implementation uses `sha2 = "0.11"`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml)) |

##### Principles and implementation

The digest exists to detect a client reusing one scoped idempotency key with different request material. It is not part of the cache lookup key.

The input format must be versioned and length-prefixed so that future canonicalization changes cannot silently reinterpret old entries.

##### Dominant choice

`Sha256` from `sha2` 0.11.0:

- standardized output;
- deterministic across processes;
- suitable for a future distributed store;
- direct maintained production adoption;
- hashing cost expected to be dominated by HTTP body buffering for normal JSON requests.

##### Qualified shortlist

- `sha2` 0.11.0 — chosen;
- `blake3` 1.8.7 — faster-oriented alternative with excellent one-shot ergonomics;
- storing exact request bytes — collision-free but retains sensitive data and increases memory/storage cost.

##### Excluded by gate

- `DefaultHasher`: excluded by architectural fit because its output algorithm is not a stable persistence contract and is too short for a cross-instance fingerprint.
- SHA-1/MD5: excluded as obsolete choices for a new fingerprint contract.
- JSON reserialization/canonicalization: excluded from the generic middleware because it changes semantics by media type and adds parsing cost.

##### Up-and-comers

BLAKE3 remains the strongest alternative if profiling proves SHA-256 material. No such evidence exists for this workload. `axum-idempotent` itself uses BLAKE3 in its hashing mode, demonstrating ecosystem feasibility but not a reason to prefer it here. ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))

##### Fit for this template

SHA-256 produces a portable fingerprint suitable for both the initial memory store and a future Redis or SQL implementation. The fingerprint format can remain unchanged when the store changes.

##### Recommendation

```toml
sha2 = { version = "0.11.0", default-features = false }
```

Use `Sha256::digest` over `FingerprintV1` material. Persist the 32-byte digest directly; do not hex-encode it internally.

##### Ranked runner-up

`blake3` 1.8.7. Select it only after a representative benchmark and after its advisory, MSRV, unsafe and ubuntu/macOS gates are independently completed.

##### Tradeoffs

SHA-256 is slower than BLAKE3 for large bodies, but idempotency-protected JSON operations should already have explicit request-size limits. No hashing benchmark was run, so the expected impact must be measured rather than inferred.

The crate root does not globally forbid unsafe code; optimized backend posture must be checked with dependency inspection. The public digest API used here is safe Rust. ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))

##### Parameters

- crate: `sha2` 0.11.0;
- algorithm: SHA-256;
- digest: 32 bytes;
- fingerprint schema: `FingerprintV1`;
- default features: disabled;
- license: MIT OR Apache-2.0;
- runtime coupling: none.

The crate and dependency tree must pass Rust 1.96 before merge; fetched metadata did not independently expose the complete dependency-tree MSRV.

##### Migration implications

Changing fingerprint algorithms after deployment requires:

- incrementing the fingerprint version;
- either retaining old verification support until existing records expire or flushing the store;
- coordinating all instances before a distributed-store rollout.

##### Validation strategy

Planned:

```bash
cargo +1.96.0 check --workspace --all-targets
cargo test fingerprint
cargo tree -e features -i sha2
cargo audit
cargo geiger --all-features
```

Tests must include:

- standard SHA-256 vectors;
- unambiguous length-prefix encoding;
- same body → same fingerprint;
- one-byte body change → conflict;
- content-type/material-header change → conflict;
- method/path change affects the scoped key rather than creating a misleading fingerprint miss.

##### Confidence & re-verify trigger

**Confidence: medium-high.** The algorithmic choice is strong; mandatory API metrics, complete MSRV metadata and current issue responsiveness remain evidence gaps.

Re-verify on:

- `sha2` 0.12;
- any RustSec advisory;
- distributed-store implementation;
- evidence that fingerprinting contributes materially to request latency.

##### Sources

Retrieved September 18, 2026:

- `https://docs.rs/crate/sha2/0.11.0` ([docs.rs](https://docs.rs/crate/sha2/latest))
- `https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))
- `https://rustsec.org/packages/sha2.html` ([rustsec.org](https://rustsec.org/packages/sha2.html))
- `https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))
- Runner-up: `https://docs.rs/crate/blake3/latest` ([docs.rs](https://docs.rs/crate/blake3/latest))

### Compatibility

`cratestack-axum` 0.12.0 resolves and documents `tower ^0.5` and `sha2 ^0.11` in the same built crate, providing a maintained compatibility witness for the two external members. ([docs.rs](https://docs.rs/crate/cratestack-axum/latest))

| Component | Version/contract | Compatibility status |
|---|---|---|
| Rust edition | 2024 | Owner-fixed |
| Effective MSRV on 2026-09-18 | Rust 1.96 | Stable is 1.98.1; stable-minus-two is 1.96. ([doc.rust-lang.org](https://doc.rust-lang.org/releases.html)) |
| Internal engine/store | Template-owned | Framework-neutral |
| Tower reference adapter | 0.5.3 | Shared compatibility evidence with `sha2` exists |
| SHA-256 implementation | `sha2` 0.11.0 | Shared compatibility evidence exists |
| Concrete R69 framework | Unresolved | Must be integrated and tested after R69 |
| Overall middleware ordering | Unresolved | R75 acceptance prerequisite |

This is compatibility evidence, not proof that the proposed full example has run. The full example remains unexecuted.

### Parameters

owns none

assumes rust-edition = `2024`

assumes msrv-policy = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

assumes rust-version = `1.96` as of September 18, 2026; re-evaluate at implementation and each template minor release

assumes license = `MIT OR Apache-2.0`

assumes target-os-matrix = `ubuntu-latest, macos-latest`

assumes R69 supplies the concrete request/response body adapter and route/operation identity

assumes R75 supplies an operation boundary at which principal scope and whether operation execution began are observable; R73 does not select overall middleware order

No `CONFLICT:` line is required.

### Migration implications

1. **Cargo**
   - Set workspace `rust-version = "1.96"`.
   - Add `sha2 = { version = "0.11.0", default-features = false }` to the web-service member.
   - Add Tower 0.5.3 only if R69 is Tower-compatible.
   - Commit the binary workspace’s `Cargo.lock`.

2. **Library/core**
   - Add the idempotency state machine, types and store contract.
   - Keep framework and runtime types out of public library APIs unless the library explicitly exposes web integration.

3. **Web service**
   - Build one `MemoryIdempotencyStore` during startup and clone its handle into middleware.
   - Attach the R69 adapter only to eligible mutating routes or the mutating router subtree.
   - Export hit, miss, replay, in-flight conflict, fingerprint conflict, eviction, capacity rejection and resident-byte metrics.

4. **Configuration**
   - Require explicit TTL, in-flight timeout, entry/byte limits and body limits.
   - Document that eviction or restart may shorten the effective idempotency window.
   - State that multiple instances do not share keys.

5. **Documentation**
   - Add the client contract: key syntax, uniqueness scope, fingerprint rules, expiry and conflict statuses.
   - Document the future `IdempotencyStore` distributed implementation point.
   - Record the F314 baseline review before changing the ledger.

6. **Future scaling**
   - Implement Redis/SQL `begin` atomically using conditional insertion/transaction or script.
   - Reuse the same key, fingerprint, response snapshot and contract-test types.
   - Do not attempt a transparent multi-instance deployment with independent memory stores.

### Validation strategy

**Executed during this research:** documentation and source inspection only. No repository build, test, audit, benchmark or integration command was run.

**Mandatory planned checks:**

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --all-features
cargo +1.96.0 test --workspace --all-features

cargo +stable fmt --all -- --check
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings

cargo tree -e features
cargo audit
cargo deny check licenses advisories bans sources
```

Run the check, test and Clippy commands in this matrix:

```yaml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest]
```

#### Executable HTTP acceptance suite

```bash
cargo test -p rs-launch-blueprint-web --test idempotency_http -- --nocapture
```

The test service should expose a handler-execution counter and deterministic routes.

Expected assertions:

1. First keyed request returns the handler response without `Idempotency-Replayed`.
2. Identical retry returns the same status/body with `Idempotency-Replayed: true`.
3. Handler counter is one.
4. Same key on another method/path/principal is independent.
5. Same scoped key with a changed body returns `422`; counter remains one.
6. A simultaneous duplicate returns `409`; counter remains one.
7. A completed `500` is replayed under `CompletedOutcome`.
8. A pre-operation validation `400` is not stored.
9. Under the non-recommended `SuccessOnly` compatibility policy, the test explicitly proves that a non-2xx result is not stored and the handler runs again.
10. TTL, eviction, restart and full-capacity behavior match the documented limitations.

#### Store contract suite

```bash
cargo test -p rs-launch-blueprint-web idempotency_store_contract
```

The same suite must later run against:

```text
MemoryIdempotencyStore
RedisIdempotencyStore
SqlIdempotencyStore
```

#### Performance and cost

```bash
cargo bench -p rs-launch-blueprint-web --bench idempotency
cargo build --release -p rs-launch-blueprint-web
cargo bloat --release -p rs-launch-blueprint-web --crates
```

Do not merge a Moka substitution merely because its standalone cache benchmarks are faster. Require the representative HTTP workload, identical capacity/TTL configuration, matching instrumentation and measured latency, throughput, RSS and build impact.

### Confidence & re-verify trigger

**Overall confidence: medium-high.**

- **High:** adopt the capability; use a scoped key plus separate fingerprint; provide an atomic idempotency-specific store boundary; start with a bounded single-instance memory store.
- **High:** a simple `HashMap`/`VecDeque` under a short-held standard mutex is idiomatic for the initial store.
- **Medium-high:** challenge F314. Stripe and the IETF draft strongly support replaying completed errors, but the owner must approve changing the recorded Python-equivalence policy.
- **Medium:** exact dependency due diligence because the mandated crates.io/GitHub metrics, issue-response calculations and some CI/advisory endpoints could not be retrieved.
- **Conditional:** Tower adapter pending R69 and operation-boundary placement pending R75.

Re-verify when any of these occurs:

1. R69 or R75 is decided.
2. The IETF draft is revived, replaced or published as an RFC.
3. A framework-neutral Rust idempotency crate reaches mature adoption and supplies atomic memory plus distributed stores.
4. Tower or SHA2 makes a major release.
5. Rust stable advances and the template raises its stable-minus-two floor.
6. A RustSec advisory appears.
7. The template supports multiple web-service instances.
8. Before implementation merge, rerun all mandated API metrics and the two-OS acceptance suite.

### Sources

All retrieved September 18, 2026.

#### Standards and production semantics

- `https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/))
- `https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07` ([datatracker.ietf.org](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07))
- `https://docs.stripe.com/api/idempotent_requests?query=` ([docs.stripe.com](https://docs.stripe.com/api/idempotent_requests?...=))

#### Rust middleware and synchronization

- `https://tower-rs.github.io/tower/tower/` ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))
- `https://docs.rs/crate/tower/0.5.3` ([docs.rs](https://docs.rs/crate/tower/latest))
- `https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig` ([docs.rs](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig))
- `https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs))
- `https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md` ([github.com](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md))
- `https://docs.rs/axum/latest/axum/middleware/` ([docs.rs](https://docs.rs/axum/latest/axum/middleware/))
- `https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html` ([docs.rs](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html))
- `https://tokio.rs/tokio/tutorial/shared-state` ([tokio.rs](https://tokio.rs/tokio/tutorial/shared-state))

#### Candidate implementations

- `https://docs.rs/crate/axum-idempotent/0.3.0` ([docs.rs](https://docs.rs/crate/axum-idempotent/latest))
- `https://rust-doc.cratestack.dev/cratestack/idempotency/index.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html))
- `https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html` ([rust-doc.cratestack.dev](https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html))
- `https://docs.rs/crate/cratestack-axum/0.12.0` ([docs.rs](https://docs.rs/crate/cratestack-axum/latest))
- `https://github.com/bhatti/idempotency-rs` ([github.com](https://github.com/bhatti/idempotency-rs))
- `https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/` ([docs.rs](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/))
- `https://docs.rs/crate/moka/0.12.16` ([docs.rs](https://docs.rs/crate/moka/latest))

#### Fingerprinting

- `https://docs.rs/crate/sha2/0.11.0` ([docs.rs](https://docs.rs/crate/sha2/latest))
- `https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs` ([raw.githubusercontent.com](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs))
- `https://rustsec.org/packages/sha2.html` ([rustsec.org](https://rustsec.org/packages/sha2.html))
- `https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml` ([raw.githubusercontent.com](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml))

#### Mandated metric endpoints to rerun before merge

```text
GET https://crates.io/api/v1/crates/tower
GET https://crates.io/api/v1/crates/tower/versions
GET https://api.github.com/repos/tower-rs/tower
GET https://api.github.com/search/issues?q=repo:tower-rs/tower+is:issue+is:open

GET https://crates.io/api/v1/crates/sha2
GET https://crates.io/api/v1/crates/sha2/versions
GET https://api.github.com/repos/RustCrypto/hashes
GET https://api.github.com/search/issues?q=repo:RustCrypto/hashes+is:issue+is:open
```

The unavailable API figures and issue-response medians are an explicit evidence gap and were not used to select the architecture.

## Sources

- [https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/](https://datatracker.ietf.org/doc/draft-ietf-httpapi-idempotency-key-header/)
- [https://tower-rs.github.io/tower/tower/](https://tower-rs.github.io/tower/tower/)
- [https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header-07)
- [https://docs.rs/crate/axum-idempotent/latest](https://docs.rs/crate/axum-idempotent/latest)
- [https://docs.rs/crate/moka/latest](https://docs.rs/crate/moka/latest)
- [https://docs.stripe.com/api/idempotent_requests?...=](https://docs.stripe.com/api/idempotent_requests?...=)
- [https://docs.rs/axum/latest/axum/middleware/](https://docs.rs/axum/latest/axum/middleware/)
- [https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml](https://raw.githubusercontent.com/awslabs/aws-sdk-rust/main/sdk/aws-sigv4/Cargo.toml)
- [https://rust-doc.cratestack.dev/cratestack/idempotency/index.html](https://rust-doc.cratestack.dev/cratestack/idempotency/index.html)
- [https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html](https://docs.rs/tokio/latest/tokio/sync/struct.Mutex.html)
- [https://docs.rs/crate/cratestack-axum/latest](https://docs.rs/crate/cratestack-axum/latest)
- [https://github.com/bhatti/idempotency-rs](https://github.com/bhatti/idempotency-rs)
- [https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/](https://docs.rs/http-cache-tower-server/latest/http_cache_tower_server/)
- [https://docs.rs/crate/tower/latest](https://docs.rs/crate/tower/latest)
- [https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml)
- [https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig](https://docs.rs/crate/tower/0.5.3/source/Cargo.toml.orig)
- [https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs](https://raw.githubusercontent.com/tower-rs/tower/master/tower/src/lib.rs)
- [https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md](https://github.com/tower-rs/tower/blob/master/guides/building-a-middleware-from-scratch.md)
- [https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml](https://raw.githubusercontent.com/hyperium/tonic/master/tonic/Cargo.toml)
- [https://docs.rs/crate/sha2/latest](https://docs.rs/crate/sha2/latest)
- [https://rustsec.org/packages/sha2.html](https://rustsec.org/packages/sha2.html)
- [https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs](https://raw.githubusercontent.com/RustCrypto/hashes/master/sha2/src/lib.rs)
- [https://docs.rs/crate/blake3/latest](https://docs.rs/crate/blake3/latest)
- [https://doc.rust-lang.org/releases.html](https://doc.rust-lang.org/releases.html)
- [https://tokio.rs/tokio/tutorial/shared-state](https://tokio.rs/tokio/tutorial/shared-state)
- [https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html](https://rust-doc.cratestack.dev/cratestack/idempotency/trait.IdempotencyStore.html)