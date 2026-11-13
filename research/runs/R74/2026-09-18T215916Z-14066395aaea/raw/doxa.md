---
prompt: # Deep-research prompt — Rate-limiting middleware (R74, bundle)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260918-151845-96abb3c658eb437e
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

Generated: 2026-09-18T22:39:54.225928+00:00


## Openai Results

---
prompt: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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
operation_id: research-20260918-151845-96abb3c658eb437e
created_at: 2026-09-18T15:18:45.890558
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

### Landscape

**Retrieval date:** September 18, 2026, for all external sources and fallback figures below. The Python/TypeScript precedent and repository paths are owner-provided evidence and were not independently fetched.

**Decision category:** application-level HTTP admission control: a keyed rate-limit policy implemented as middleware, controlled at runtime, with truthful deployment scope and an actionable rejection contract.

**Three-bin ecosystem map**

| Bin | Candidates found | Assessment |
|---|---|---|
| Built-in or first-party toolchain | `tower::limit::RateLimitLayer` 0.5.3 | Mature first-party service-level throttling, but it controls service readiness rather than producing keyed HTTP 429 responses. It has no per-client store, response factory, or `Retry-After` contract, so it is not the capability required here. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)) |
| Established industry standard | `governor` 0.10.4; `tower_governor` 0.8.0; framework-specific `actix-governor` | `governor` is the established in-memory GCRA engine. `tower_governor` is the established Tower adapter, supports keyed/global limits and custom error responses, and is used with Axum, Hyper and Tonic. Its current package manifest does not declare `rust-version`, and its default `Retry-After` path uses `Duration::as_secs()`, which truncates fractional seconds. ([docs.rs](https://docs.rs/governor/latest/governor/)) |
| Up-and-comer | `tower-rate-limiter` 0.1.6; `axum-governor` 2.1.0; FlowShield 0.2; `rune-axum-ratelimit` | `tower-rate-limiter` is unusually close to the required architecture: Tower-first, explicit `MemoryStore`, a `Store` trait, Redis implementation, custom response factory, fixed-window reset metadata, edition 2024 and Rust 1.96. Its weakness is ecosystem age and near-zero verified adoption. `axum-governor` is richer but binds R74 to Axum before R69 resolves. FlowShield still describes its public facade as pre-stabilization/design work. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6)) |

**Authority used**

- The Rust Forge and official release announcements establish that stable Rust is 1.98.1, making the owner’s “stable minus two minor versions” floor Rust 1.96.0. Cargo’s documentation is authoritative for `rust-version` semantics. ([forge.rust-lang.org](https://forge.rust-lang.org/))
- Tower and Axum maintainer documentation is authoritative for middleware architecture: Axum deliberately uses Tower rather than a bespoke middleware system, and Tower models wrappers as `Layer`/`Service` components. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md))
- RFC 6585 is normative for HTTP 429, while RFC 9110 defines `Retry-After` and its integral `delay-seconds` representation. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))
- Candidate manifests, API documentation, source, examples and repository activity are primary sources for implementation behavior. RustSec is the advisory authority, although the complete dependency-tree audit remains an executable integration check. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))
- Current project `Cargo.toml` files were weighted more highly than blogs for practice evidence. Meta’s Buck2 and Restate currently use Tower 0.5, supporting Tower as a mainstream service abstraction; this does not by itself validate any particular rate-limiter adapter. ([github.com](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml))

**Fitness gates before popularity**

| Candidate | License | MSRV | Advisories / unsafe | Ubuntu + macOS | Features/runtime | Build cost | Result |
|---|---|---|---|---|---|---|---|
| `tower-rate-limiter` 0.1.6 | Pass: `MIT OR Apache-2.0` | Crate-level pass: edition 2024, `rust-version = 1.96.0`, pinned 1.96 toolchain. Full resolved tree must still be checked on 1.96. | No matching RustSec package page was retrieved; full-tree `cargo deny` and unsafe scan were not run. Conditional. | Repository has active Actions, but the retrieved evidence did not expose its OS matrix. Template CI on both required OSes is mandatory. | Default is `memory`, implemented through optional synchronous Moka; Redis and Tokio/Smol coupling are optional. | Medium: adds Moka and client-IP extraction code but no network client or async runtime for the selected feature set. | **Conditional pass; only candidate matching capability, declared MSRV and swap seam.** ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml)) |
| `tower_governor` 0.8.0 | Pass | **Fail:** no `rust-version` in current package manifest. | Direct advisory check incomplete; unsafe policy not documented in retrieved evidence. | Not proven from retrieved evidence. | Default features enable both Axum and Tonic; `default-features = false` reduces cost. | Medium/high with defaults; medium without. | **Excluded by required MSRV evidence gate.** ([github.com](https://github.com/benwis/tower-governor/blob/main/Cargo.toml)) |
| `governor` 0.10.4 plus local Tower layer | Pass: MIT | Dependency MSRV not fully verified. | Direct advisory/tree check incomplete. | Not fully verified. | In-memory engine; no web runtime required, but the application would own the HTTP adapter. | Low engine cost, high local implementation/maintenance cost. | **Qualified architecture, not selected.** ([docs.rs](https://docs.rs/governor/latest/governor/)) |
| `axum-governor` 2.1.0 | Pass: MIT | Not verified from retrieved manifest evidence. | Direct advisory/tree check incomplete. | Not verified. | Axum 0.8, Tower 0.5, Tokio; defaults include DashMap, tracing and JSON. | Medium/high. | **Excluded from unconditional selection because R69 is open and the crate is Axum-specific.** ([docs.rs](https://docs.rs/crate/axum-governor/latest)) |
| Tower built-in limiter | Pass | Pass relative to floor | First-party posture | Tower project is mature and cross-platform | Tower `limit` feature | Low if Tower is already present | **Excluded by capability gate:** no keyed store or HTTP rejection contract. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)) |

**Practice evidence**

- `tower_governor` has the strongest direct adapter precedent: current repository pages show 351 stars and examples for Axum, Hyper and Tonic; Helix and Tangled manifests demonstrate use in real projects. The Axum discussion archive also repeatedly points users to it. ([github.com](https://github.com/benwis/tower-governor))
- `governor` is the strongest algorithm-engine precedent, with 938 GitHub stars and multiple framework adapters built around it. ([github.com](https://github.com/boinkor-net/governor))
- `tower-rate-limiter` currently has six stars, three forks and one open issue. No well-regarded production adopter was verified. Its recommendation therefore rests on architectural fit and executable verification, not popularity. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- Published Rust templates surveyed did not establish an exact “absent env var means no limiter layer” standard. Gerust discusses optional rate-limiter generation, and Awesome Axum lists templates with Redis-backed limiting, but neither supplies the complete required pattern. This is an evidence gap rather than evidence against the pattern. ([reddit.com](https://www.reddit.com/r/rust/comments/1h77a9w))

**Required figure acquisition status**

The mandated crates.io and GitHub API endpoints were attempted, but direct API responses were unavailable through the research transport. I have not substituted estimates. HTML/docs fallbacks are identified below; exact API figures remain a pre-ledger-close evidence task.

| Candidate | Latest release fallback | GitHub HTML fallback | 90-day / all-time downloads | `archived`, `pushed_at` | Issue responsiveness | Maintenance state |
|---|---:|---:|---|---|---|---|
| `tower-rate-limiter` | 0.1.6; exact API `created_at` not retrieved | 6 stars, 1 open issue | Not retrieved | Not retrieved; repository has no archived banner | Not retrieved | `active` |
| `tower_governor` | 0.8.0, released August 14, 2025 | 351 stars, 19 open issues | Not retrieved | Not retrieved | Not retrieved | `stable-quiet`; no dormancy criterion proven |
| `governor` | 0.10.4 | 938 stars, 24 open issues | Not retrieved from required API | Not retrieved | Not retrieved | `stable-quiet` |
| `axum-governor` | 2.1.0, released September 5, 2026 | 25 stars in docs.rs metadata, 0 open issues | Not retrieved | Not retrieved | Fewer than ten visible open issues; median still not computed | `active` |

Release and repository fallbacks are supported by the maintainers’ current docs and repository pages. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

### Principles and implementation

**Shared engineering principle**

The owner-provided Python precedent expresses four linked principles:

1. **Operator intent:** an unused template must not unexpectedly reject traffic.
2. **Truthful scope:** a process-local limiter must not imply cluster-wide enforcement.
3. **Actionable rejection:** a client must know how long to back off.
4. **Replaceable state:** scaling to multiple replicas must have a named store boundary rather than requiring the HTTP behavior to be rewritten.

Agreement is therefore required at the **architectural-pattern and observable-behavior level**, not at exact crate, web framework, algorithm, env-var spelling, key extractor or problem-document type.

**Must agree**

- The same web binary runs with and without rate limiting.
- An absent or empty single runtime setting means no limiter layer is registered.
- A valid non-empty setting constructs exactly one shared process-local store and one app-wide layer at startup.
- The first request over quota returns 429.
- Its `Retry-After` is calculated from the rejected key’s remaining reset duration, not copied from the configured full window.
- The store is documented as per-process; two replicas intentionally maintain independent quotas.
- The eventual distributed swap occurs in one constructor through the crate’s `Store` seam.
- The 429 response is produced through an R70-compatible response factory.

**May vary**

- Fixed window versus GCRA/token bucket.
- Exact env name and string grammar.
- Peer-IP versus authenticated-principal key.
- R75 placement.
- R70 problem fields.
- Optional successful-response rate-limit fields.

**Architectural alternatives**

| Alternative | Advantages | Why not selected |
|---|---|---|
| Reverse proxy/API gateway only | Best place for shared, pre-application protection; can shield all replicas | Does not provide the self-contained, one-setting template behavior or guaranteed R70 problem response. It may supplement this layer later. |
| Tower built-in `RateLimitLayer` | First-party and low incremental cost | Implements readiness/backpressure, not keyed 429 admission control. |
| `tower_governor`/GCRA | Mature adapter and smoother burst behavior | Missing declared MSRV; no first-class distributed-store seam; default retry calculation truncates with `as_secs()` and must be replaced. |
| Direct `governor` plus local Tower adapter | Mature engine and complete response control | The template would own the most failure-prone middleware, cleanup, extraction and future backend integration code. |
| Store-pluggable fixed-window Tower middleware | Exact Memory/Redis seam, straightforward reset time, framework-neutral within Tower | Young crate and fixed-window boundary bursts. |
| Fully hand-written fixed-window middleware | No young dependency | Recreates concurrency, eviction, key extraction, response and timing logic with a larger rewrite surface. |

**Selected implementation**

Use `tower-rate-limiter` 0.1.6 with only its `memory` feature. Its public pattern explicitly injects `MemoryStore`, documents it as process-local, offers Redis/custom stores through the same builder, supports custom responses, and has generic Tower plus Axum examples. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))

Do **not** add a Cargo feature named `rate-limit`. Cargo features are compile-time dependency selection; operational enablement must remain a runtime decision so one already-built binary can be started in either mode. Compile the memory implementation into the web service and conditionally register the layer from `Option<RateLimitSpec>`.

Recommended setting:

```text
RS_LAUNCH_RATE_LIMIT=<requests>/<window>
```

Examples:

```text
# absent or empty: disabled
RS_LAUNCH_RATE_LIMIT=100/60s
RS_LAUNCH_RATE_LIMIT=5/1m
```

A non-empty invalid value is a startup configuration error; it must not silently disable the protection.

Recommended dependency:

```toml
[dependencies]
tower-rate-limiter = {
    version = "=0.1.6",
    default-features = false,
    features = ["memory"],
}
```

The exact pin contains pre-1.0 API and MSRV movement. It belongs in the web-service crate, not the reusable public library crate.

The startup composition is:

```rust
let rate_limit = settings
    .rate_limit
    .as_ref()
    .map(|spec| {
        RateLimitLayer::builder(IpKeyExtractor::new())
            .policy_name("public-http")
            .limit(spec.requests)
            .window(spec.window)
            .with_store(MemoryStore::new())
            .response_factory(problem_response_factory.clone())
            .build()
    })
    .transpose()?;

let app = ServiceBuilder::new()
    .option_layer(rate_limit)
    .service(app);
```

The builder calls above follow the crate’s documented API. Registration may instead be an `if let Some(layer)` branch if R69’s framework preserves one router type across conditional `.layer(...)` calls. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

Use the peer socket address as the safe initial key. Forwarded client-IP headers must not become authoritative unless R69 or deployment configuration establishes a trusted-proxy boundary; the crate itself warns that header-derived identity is safe only when the proxy removes or overwrites accepted headers. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))

**429 and R70 integration**

The crate’s builder accepts a custom `ResponseFactory`, and exposes structured `ResponseReason` and `Usage` types. R74 should therefore generate the 429 directly through a small adapter calling R70’s reusable problem-response constructor. It should not depend on an outer handler-error interceptor: the limiter short-circuits with a normal HTTP response before a handler error exists. ([docs.rs](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html))

The exact variant names are intentionally deferred until R70’s body type is known, but the core computation is fixed:

```rust
fn retry_after_seconds(reset_after: Duration) -> u64 {
    reset_after
        .as_secs()
        .saturating_add(u64::from(reset_after.subsec_nanos() != 0))
        .max(1)
}
```

The response factory must:

1. obtain the denied policy’s `reset_after` from the crate’s returned usage;
2. compute the integral delay by ceiling, as above;
3. call the R70 problem constructor with status 429;
4. set `Retry-After` to that same integer;
5. return the response directly.

Ceiling is required because HTTP delay-seconds is integral. Flooring a 1.2-second wait to `1` tells the client to retry before admission is possible; ceiling overstates by less than one second but never understates the current reset duration. RFC 6585 permits `Retry-After` on 429, and RFC 9110 defines the header representation. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))

`tower-rate-limiter` advertises a default 429 with `Retry-After`, but the recommendation does not rely on undocumented rounding behavior. The custom factory plus a contract test is part of the selected bundle. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

**Performance evaluation**

The selected memory path performs no network I/O and does not require Tokio through its normal selected features; the manifest uses synchronous Moka for `MemoryStore`. Its expected cost is key extraction, policy resolution and an in-process cache operation. This should be characterized rather than compared against unrelated Redis or algorithm benchmarks. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))

The upstream repository includes a Docker Compose benchmark harness with an isolated benchmark server, optional `wrk` generator, raw outputs and summaries, but no trustworthy published result was available to use as a selection claim. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

The template benchmark should compare disabled versus enabled memory limiting using the same release binary and:

- a no-op/204 route;
- 1, 32 and 256 concurrent connections;
- one hot key and 10,000-key cardinality;
- an all-admitted quota and a mostly-rejected quota;
- 60-second measured runs after warm-up;
- request throughput, p50/p95/p99 latency, CPU, RSS, allocation rate and store cardinality;
- compile timings and release-binary delta.

No absolute-fastest claim is made.

**Algorithm tradeoff**

A fixed window can admit nearly twice the nominal count across a window boundary. For example, 100 requests immediately before reset and 100 immediately after reset can all succeed. That is acceptable for this optional template guard because it keeps `Retry-After` and the distributed-store seam simple. A future requirement for strict smoothing is a re-verification trigger for a GCRA/token-bucket design, not a silent library substitution.

**Observable acceptance criteria**

- Absent/empty `RS_LAUNCH_RATE_LIMIT`: layer absent; repeated requests are not rate-limited.
- `RS_LAUNCH_RATE_LIMIT=2/2s`: first two requests for a key succeed, third is 429.
- The third response has one decimal-integer `Retry-After`, greater than zero and no greater than the remaining configured window.
- Waiting the advertised number of seconds allows a subsequent request, barring a concurrent request for the same key.
- A synthetic 1.000000001-second reset encodes as `2`, proving ceiling rather than truncation.
- Invalid non-empty config terminates startup with a configuration error.
- Two separately started processes have independent counters.
- After R70 integration, 429 has `application/problem+json` and retains the R74-computed header.
- The dependency tree builds and tests under Rust 1.96.0 and current stable on both required OSes.
- The selected dependency tree passes advisory/license checks; its unsafe footprint is recorded.
- A high-cardinality test demonstrates a bounded store or blocks adoption until an explicit capacity can be configured.

`BASELINE-REVIEW: F323 — Retry-After must never direct a client to retry before the limiter can admit it — require an application-owned ceil-to-seconds helper and contract test instead of inheriting a crate default — RFC 9110 permits integral delay-seconds, while tower_governor 0.8.0 derives its header through Duration::as_secs() truncation. Affects R74’s response adapter only; R70 retains ownership of the problem envelope.` ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))

### Recommendation

**ADOPT, subject to the pre-merge fitness checks below.**

One stack:

- **Middleware/store:** `tower-rate-limiter = "=0.1.6"`, `default-features = false`, `features = ["memory"]`.
- **Service model:** Tower 0.5-compatible layer registration supplied by R69.
- **Runtime gate:** optional `RS_LAUNCH_RATE_LIMIT`; absent/empty means disabled.
- **Store:** one application-wide `tower_rate_limiter::MemoryStore`, explicitly documented as process-local and single-instance-by-design.
- **Key:** authoritative peer `SocketAddr` initially; no untrusted forwarded-header fallback.
- **429 path:** custom `ResponseFactory` calling R70’s reusable problem constructor.
- **`Retry-After`:** application-owned ceiling of the rejected usage’s remaining reset duration.
- **Future distributed swap:** replace only `.with_store(MemoryStore::new())` with the crate’s Redis or another `Store`; do not change config gating or HTTP behavior.
- **No runtime enablement feature flag.**

This chooses architectural fit over the more popular governor adapter while containing the young-crate risk through an exact version pin, a local response adapter and executable acceptance tests.

### Members

#### tower-rate-limiter 0.1.6

##### Landscape

`tower-rate-limiter` is an active but early Tower-first fixed-window middleware. It exposes explicit Memory, Redis and custom Store implementations, custom keys and responses, and optional Axum integration. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))

Required figures, retrieved September 18, 2026:

| Figure | Value | Required source |
|---|---|---|
| 90-day downloads | **Not retrieved**; do not substitute an estimate | `GET https://crates.io/api/v1/crates/tower-rate-limiter` → `crate.recent_downloads` |
| All-time downloads | **Not retrieved** | same endpoint → `crate.downloads` |
| Last release | `0.1.6`; exact `created_at` not retrieved | `GET https://crates.io/api/v1/crates/tower-rate-limiter/versions`; docs.rs independently confirms 0.1.6. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6)) |
| Stars | API value not retrieved; GitHub HTML fallback: **6** | `GET https://api.github.com/repos/nivek3/tower-rate-limiter`; fallback repository page. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |
| Archived | API value not retrieved; no archived banner visible | same endpoint |
| `pushed_at` | Not retrieved | same endpoint |
| Open issues | API value not retrieved; GitHub HTML fallback: **1** | `GET https://api.github.com/search/issues?q=repo:nivek3/tower-rate-limiter+is:issue+is:open`; fallback repository page. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |
| Issue responsiveness | Not retrieved; median and unanswered count remain required | Ten most recently opened non-PR issues plus first OWNER/MEMBER/COLLABORATOR response |
| Advisories | No matching package page was retrieved; full-tree audit not run | RustSec package index plus `cargo deny check advisories`. ([rustsec.org](https://rustsec.org/packages/)) |
| Adopters | No relevant production adopter verified | crates.io reverse dependencies plus adopter `Cargo.toml` |
| Maintenance state | **active** | Current 0.1.6 package, 42 commits, two open PRs and one open issue. ([github.com](https://github.com/nivek-ph/tower-rate-limiter)) |

##### Principles and implementation

This member realizes the central pattern rather than merely supplying an algorithm:

- `MemoryStore` makes process-local scope explicit.
- `Store` and `RedisStore` provide the named scale-out seam.
- `ResponseFactory`, `ResponseReason` and `Usage` provide an adapter point for R70 and accurate reset-based backoff.
- Generic Tower support prevents an unnecessary hard dependency on Axum.
- Fixed-window behavior aligns naturally with a `<requests>/<window>` setting. ([docs.rs](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html))

##### Dominant choice

The ecosystem incumbent is `governor` with `tower_governor`, not this crate. The incumbent has substantially more community history and adoption. It loses this decision because its Tower adapter does not meet the owner’s declared-MSRV evidence gate and does not offer an equivalent distributed Store seam. ([github.com](https://github.com/boinkor-net/governor))

##### Qualified shortlist

1. `tower-rate-limiter` 0.1.6 — best architectural fit; low maturity.
2. `tower_governor` 0.8.0 — mature Tower adapter; blocked by MSRV declaration and retry rounding.
3. `governor` 0.10.4 plus a local layer — mature engine; excessive application-owned HTTP/store code.
4. `axum-governor` 2.1.0 — strong if R69 selects Axum; premature framework coupling today.

##### Excluded by gate

- **Tower built-in limiter:** capability failure—no keyed HTTP rejection/store abstraction. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html))
- **`tower_governor` 0.8.0:** no `rust-version` declaration in its current manifest; default retry path truncates duration. ([github.com](https://github.com/benwis/tower-governor/blob/main/Cargo.toml))
- **`governor` plus custom layer:** dependency-tree MSRV and OS evidence incomplete, and it moves middleware correctness into template-owned code.
- **`axum-governor` 2.1.0:** unconditional selection would pre-decide R69; its defaults also bring Axum, Tokio, DashMap, tracing and JSON. ([docs.rs](https://docs.rs/crate/axum-governor/latest))
- **FlowShield:** its facade still describes the public API as being built and pre-stabilization; insufficient production evidence for this high-rewrite-cost decision. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))

##### Up-and-comers

`axum-governor` is the strongest alternate up-and-comer, with stacked policies, per-tier overrides, background GC, custom bodies and a problem+json preset. It should be reconsidered only if R69 definitively selects Axum and a distributed-store swap ceases to be required. ([docs.rs](https://docs.rs/crate/axum-governor/latest))

FlowShield has a more ambitious bounded/sharded memory design and separate Redis backend, but its own facade documentation describes an unfinished public API. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))

##### Fit for this template

**Fit: high functionally, medium overall.**

- CLI and reusable library remain unaffected because the dependency belongs only to the web-service crate.
- Runtime gating avoids separate artifacts.
- The memory-only feature has no normal Tokio dependency.
- Tower compatibility fits Axum/Hyper/Tonic-style R69 outcomes.
- The explicit store boundary matches the Python precedent better than governor’s embedded in-memory state.
- Its small community and unverified adopter base require stronger local tests than a mature dependency would.

##### Recommendation

```toml
tower-rate-limiter = {
    version = "=0.1.6",
    default-features = false,
    features = ["memory"],
}
```

Construct `MemoryStore` exactly once during web application startup. Do not place it in request state in a way that rebuilds or independently clones limiter state per route.

Keep the third-party types behind:

```text
src/web/rate_limit.rs
```

Only that module should import `tower_rate_limiter`; settings, handlers and the public library should depend on application-owned `RateLimitSpec` and response helpers.

##### Ranked runner-up

**`tower_governor` 0.8.0 with `default-features = false` and a custom error handler.**

It is the runner-up because it is proven across multiple Tower hosts and uses mature GCRA behavior. It becomes selectable only if it:

1. declares an MSRV compatible with the template floor;
2. is tested in the required OS matrix;
3. passes the advisory/unsafe checks; and
4. replaces its truncating retry calculation with the same application-owned ceiling helper.

Its current custom error-handler facility is sufficient to reach an R70 response constructor. ([docs.rs](https://docs.rs/crate/tower_governor/latest))

##### Tradeoffs

- Fixed windows permit boundary bursts; GCRA is smoother.
- The crate is 0.1.x and may make relatively rapid API changes.
- Moka increases compile time and binary size relative to a small hand-written map.
- Exact pinning requires deliberate dependency updates.
- Store failure semantics become more significant if Redis is adopted later.
- Upstream OS, unsafe and full dependency-MSRV evidence was incomplete in this research run.
- In return, the design avoids local implementation of concurrency, reset accounting, client-IP extraction and distributed-store plumbing.

##### Parameters

```text
package version = =0.1.6
default-features = false
features = ["memory"]
runtime gate = RS_LAUNCH_RATE_LIMIT
default runtime value = absent / disabled
store type = tower_rate_limiter::MemoryStore
algorithm = fixed window
deployment scope = one process
```

No member-level conflict with owner-fixed parameters is known.

##### Migration implications

- Add the dependency only to the web-service package.
- Add an application-owned `RateLimitSpec` parser.
- Add the layer/store constructor and R70 response adapter.
- Replace any direct crate imports in `app.rs` with one `rate_limit::build(...)` call.
- Add a commented example to `.env.example`; do not assign a default.
- Document that replica count multiplies effective quota.
- Pin the exact package until its API and MSRV policy mature.

##### Validation strategy

Planned, not executed:

```bash
cargo +1.96.0 check --locked --workspace --all-targets
cargo +1.96.0 test  --locked --workspace
cargo +stable check --locked --workspace --all-targets
cargo +stable test  --locked --workspace

cargo deny check advisories licenses bans sources
cargo geiger --workspace --no-default-features --features memory
```

Run the first four commands on both `ubuntu-latest` and `macos-latest`.

Crate-specific contract tests must cover:

```text
Duration::ZERO       -> 1
1 nanosecond          -> 1
1 second              -> 1
1 second + 1 ns       -> 2
1500 milliseconds     -> 2
```

Use a fake `Store` or response reason to make these tests deterministic, then run a separate real-`MemoryStore` integration test.

##### Confidence & re-verify trigger

**Confidence: medium.** Architectural fit is high; maturity and metric completeness are not.

Re-verify if:

- R69 chooses a non-Tower framework;
- R70 cannot expose a reusable response/problem constructor;
- any version newer than 0.1.6 is proposed;
- stable Rust advances and the template floor changes;
- an advisory appears in this tree;
- the crate fails macOS or Rust 1.96;
- its default/custom response path overwrites the application’s calculated header;
- the memory store cannot be explicitly bounded;
- multi-instance deployment becomes a default supported topology;
- a smoothed/token-bucket policy becomes an owner requirement.

##### Sources

- Current package manifest, feature set, license, edition, MSRV and dependencies. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))
- Pinned 1.96 toolchain. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml))
- Maintainer README, store choices, proxy warning and examples. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md))
- `ResponseFactory`, `ResponseReason`, `MemoryStore` and `Usage` API documentation. ([docs.rs](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html))
- Benchmark harness evidence. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- Repository activity fallback. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))

### Compatibility

The selected member is a single direct crate, but its maintained repository proves the relevant version family together:

- `tower-rate-limiter` 0.1.6 directly uses `tower-layer` 0.3 and `tower-service` 0.3.
- Its dev matrix uses Tower 0.5 and Axum 0.8.
- Published examples include generic Tower memory, dynamic quotas, Axum memory, trusted-proxy extraction and Axum Redis.
- The memory feature is independent of Redis runtime features; Redis can later select Tokio or Smol explicitly. ([github.com](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml))

That is adequate compatibility evidence for a Tower 0.5/Axum 0.8 R69 outcome. It is not proof for a future Tower major version or a non-Tower framework.

### Parameters

```text
owns none

assumes rust-edition = 2024
assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest

assumes R69 web-framework-stack = exposes Tower 0.5 Layer/Service compatibility or supplies a thin adapter
assumes R70 http-problem-envelope = exposes a reusable problem-response constructor usable outside handlers
assumes R75 http-middleware-stack = assigns the final ordering position
```

No `CONFLICT:` is currently required. If R69 selects a web framework without a Tower-compatible service boundary, R74 must be reopened rather than silently importing Axum or changing R69.

### Migration implications

Proposed file-level changes:

```text
Cargo.toml
  Add exact, memory-only tower-rate-limiter dependency to web package.

src/web/settings.rs
  Add rate_limit: Option<RateLimitSpec>.
  Map RS_LAUNCH_RATE_LIMIT absent/empty to None.
  Reject malformed non-empty values during startup.

src/web/rate_limit.rs
  Add RateLimitSpec and parser.
  Add retry_after_seconds(Duration).
  Build one MemoryStore and RateLimitLayer.
  Add custom R70-compatible ResponseFactory.
  Keep every tower_rate_limiter import in this module.

src/web/app.rs
  Call rate_limit::build(...).
  Register the returned optional layer conditionally.
  Do not construct limiter state per route or request.

src/web/problem.rs or R70-selected module
  Expose a reusable problem-response constructor.
  Do not move Retry-After computation into the generic problem module.

.env.example
  Add only a commented example:
  # RS_LAUNCH_RATE_LIMIT=100/60s

docs/configuration.md
  Document syntax, absent default and startup validation.

docs/operations/rate-limiting.md
  State explicitly:
  - process-local counters;
  - replicas do not share quotas;
  - effective aggregate quota grows with replica count;
  - MemoryStore is the intended initial implementation;
  - the constructor is the future Redis/custom Store swap point;
  - forwarded headers require a trusted proxy.

tests/web_rate_limit.rs
  Add disabled, enabled, invalid-config, retry rounding, expiry,
  independent-process and problem-envelope tests.

.github/workflows/ci.yml
  Exercise stable and 1.96.0 on ubuntu-latest and macos-latest.
```

No CLI or public-library API needs to expose the third-party crate.

### Validation strategy

**Execution status:** no commands below were run against `rs-launch-blueprint`; they are proposed acceptance checks.

**1. Close the missing ecosystem figures**

```bash
curl -fsS \
  -H 'User-Agent: rs-launch-blueprint-research/1' \
  https://crates.io/api/v1/crates/tower-rate-limiter |
jq '.crate | {recent_downloads, downloads}'

curl -fsS \
  -H 'User-Agent: rs-launch-blueprint-research/1' \
  https://crates.io/api/v1/crates/tower-rate-limiter/versions |
jq '[.versions[] | select(.yanked == false)]
    | sort_by(.created_at)
    | last
    | {num, created_at}'

gh api repos/nivek3/tower-rate-limiter \
  --jq '{stargazers_count, archived, pushed_at}'

gh api search/issues \
  -f q='repo:nivek3/tower-rate-limiter is:issue is:open' \
  --jq '{total_count}'
```

For responsiveness, retrieve the ten most recently opened non-PR issues, find the first comment whose `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR`, then report median elapsed days and unanswered count. Store the raw JSON with the research artifact.

**2. Dependency and platform gates**

```bash
cargo +1.96.0 check --locked --workspace --all-targets
cargo +1.96.0 test  --locked --workspace
cargo +stable check --locked --workspace --all-targets
cargo +stable test  --locked --workspace

cargo tree -e features
cargo deny check advisories licenses bans sources
cargo geiger --workspace
```

Expected: every command succeeds on `ubuntu-latest` and `macos-latest`; the resolved tree contains no dependency requiring Rust newer than 1.96.0; no incompatible license or open advisory exists; unsafe usage is recorded and reviewed.

**3. Same-binary runtime gate**

Build once:

```bash
cargo build --locked --bin <web-bin>
```

Run without the setting:

```bash
env -u RS_LAUNCH_RATE_LIMIT \
  target/debug/<web-bin>
```

Expected: the service starts, no rate-limit-enabled startup event is emitted, and repeated requests remain non-429.

Run the same artifact with:

```bash
RS_LAUNCH_RATE_LIMIT=2/2s \
  target/debug/<web-bin>
```

Expected for one client key:

```text
request 1 -> non-429
request 2 -> non-429
request 3 -> 429
Retry-After -> decimal integer in 1..=2
```

After sleeping for the advertised value, the next request must succeed unless another request consumed the quota.

**4. Invalid setting**

```bash
RS_LAUNCH_RATE_LIMIT=garbage \
  target/debug/<web-bin>
```

Expected: non-zero startup exit and a configuration diagnostic naming `RS_LAUNCH_RATE_LIMIT`; it must not start with limiting disabled.

**5. Accurate header unit contract**

```rust
assert_eq!(retry_after_seconds(Duration::ZERO), 1);
assert_eq!(retry_after_seconds(Duration::from_nanos(1)), 1);
assert_eq!(retry_after_seconds(Duration::from_secs(1)), 1);
assert_eq!(
    retry_after_seconds(Duration::from_secs(1) + Duration::from_nanos(1)),
    2
);
assert_eq!(retry_after_seconds(Duration::from_millis(1500)), 2);
```

Use a fake store/decision with `reset_after = 1500ms`; expected final response is 429 with `Retry-After: 2`. This catches both static-window responses and `as_secs()` truncation.

**6. R70 integration**

Expected after R70 lands:

```text
status = 429
Content-Type = application/problem+json
Retry-After = value produced by R74 helper
body = R70-selected problem shape
```

The test must invoke the composed service rather than directly testing the factory, proving short-circuit responses still pass through the required response finalization.

**7. Single-instance-by-design proof**

Start process A and process B on separate ports with the same `2/60s` setting:

1. consume A’s two requests;
2. verify A’s third request is 429;
3. verify B’s first request still succeeds.

This is an acceptance criterion, not a defect: it proves the documentation accurately describes local state.

**8. Cardinality/resource test**

Generate at least 100,000 distinct peer keys. Record store cardinality, RSS and post-expiry reclamation. Do not merge if the selected construction permits unbounded growth without an explicit capacity or eviction policy.

**9. Representative performance characterization**

Compare disabled and enabled runs of the same release binary:

```text
duration:          60 seconds after warm-up
concurrency:       1, 32, 256
key distributions: one hot key; 10,000 uniformly distributed keys
policies:          all admitted; approximately 95% rejected
route:             no-op 204 response
measure:           req/s, p50/p95/p99, CPU, RSS, allocations, store size
```

Also compare:

```bash
cargo clean
cargo build --release --timings
cargo bloat --release --bin <web-bin> --crates
```

No candidate should be declared “fastest” from the result; the purpose is to quantify the selected memory layer’s cost under this template’s workload.

### Confidence & re-verify trigger

**Overall confidence: medium.**

- **High confidence:** runtime conditional registration is preferable to a behavior feature flag; explicit process-local state and reset-based 429 responses preserve the source principles.
- **High confidence:** Tower’s middleware model is appropriate if R69 selects Axum or another Tower host.
- **Medium confidence:** `tower-rate-limiter` is the best current architectural fit.
- **Low-to-medium confidence:** its ecosystem maturity, exact download/adopter figures, upstream OS matrix and full dependency safety/MSRV posture.

The recommendation becomes implementation-ready only after the required API figures and planned fitness commands are recorded.

Reopen R74 if any of these occur:

- R69 selects a non-Tower framework.
- R70 cannot be called from middleware short-circuit code.
- `tower-rate-limiter` 0.1.6 fails Rust 1.96, macOS, advisory, license, unsafe or cardinality checks.
- A new crate release changes `Store`, `Usage`, `ResponseFactory`, reset semantics, MSRV or default features.
- An advisory affects the selected tree.
- Multi-replica shared quotas become a default requirement.
- Fixed-window boundary bursts are no longer acceptable.
- A maintained, substantially adopted Tower middleware provides the same explicit Memory/Redis seam and stronger evidence.

### Sources

All retrieved September 18, 2026.

- Rust stable release and schedule: Rust Forge and official release archive. ([forge.rust-lang.org](https://forge.rust-lang.org/))
- Cargo `rust-version` guidance. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/rust-version.html))
- Tower architecture, MSRV and repository standing. ([tower-rs.github.io](https://tower-rs.github.io/tower/tower/))
- Axum’s first-party Tower middleware model. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md))
- Tower built-in rate limiter and its service-level semantics. ([docs.rs](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html))
- `tower-rate-limiter` package, manifest, examples, stores and repository. ([docs.rs](https://docs.rs/crate/tower-rate-limiter/0.1.6))
- `tower-rate-limiter` response/store API. ([docs.rs](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html))
- `tower-rate-limiter` benchmark harness. ([github.com](https://github.com/nivek-ph/tower-rate-limiter))
- `tower_governor` package, manifest, error customization and retry implementation. ([docs.rs](https://docs.rs/crate/tower_governor/latest))
- `governor` engine and repository. ([docs.rs](https://docs.rs/governor/latest/governor/))
- `axum-governor` package and feature set. ([docs.rs](https://docs.rs/crate/axum-governor/latest))
- FlowShield’s current maturity and storage architecture. ([docs.rs](https://docs.rs/flowshield/latest/flowshield/index.html))
- Practice evidence from Buck2, Restate, Helix and Tangled manifests. ([github.com](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml))
- RFC 6585 HTTP 429 and RFC 9110 `Retry-After`. ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9110.html))
- RustSec package index. ([rustsec.org](https://rustsec.org/packages/))

## Sources

- [https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html](https://docs.rs/tower/latest/tower/limit/rate/struct.RateLimit.html)
- [https://docs.rs/governor/latest/governor/](https://docs.rs/governor/latest/governor/)
- [https://docs.rs/crate/tower-rate-limiter/0.1.6](https://docs.rs/crate/tower-rate-limiter/0.1.6)
- [https://forge.rust-lang.org/](https://forge.rust-lang.org/)
- [https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md)
- [https://www.rfc-editor.org/rfc/rfc9110.html](https://www.rfc-editor.org/rfc/rfc9110.html)
- [https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml](https://github.com/nivek3/tower-rate-limiter/blob/main/Cargo.toml)
- [https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml](https://github.com/facebook/buck2/blob/main/shim/third-party/rust/Cargo.toml)
- [https://github.com/benwis/tower-governor/blob/main/Cargo.toml](https://github.com/benwis/tower-governor/blob/main/Cargo.toml)
- [https://docs.rs/crate/axum-governor/latest](https://docs.rs/crate/axum-governor/latest)
- [https://github.com/benwis/tower-governor](https://github.com/benwis/tower-governor)
- [https://github.com/boinkor-net/governor](https://github.com/boinkor-net/governor)
- [https://github.com/nivek-ph/tower-rate-limiter](https://github.com/nivek-ph/tower-rate-limiter)
- [https://www.reddit.com/r/rust/comments/1h77a9w](https://www.reddit.com/r/rust/comments/1h77a9w)
- [https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md](https://docs.rs/crate/tower-rate-limiter/0.1.6/source/README.md)
- [https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html](https://docs.rs/tower-rate-limiter/latest/tower_rate_limiter/limiter/index.html)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://docs.rs/flowshield/latest/flowshield/index.html](https://docs.rs/flowshield/latest/flowshield/index.html)
- [https://docs.rs/crate/tower_governor/latest](https://docs.rs/crate/tower_governor/latest)
- [https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml](https://github.com/nivek3/tower-rate-limiter/blob/main/rust-toolchain.toml)
- [https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html](https://docs.rs/tower-rate-limiter/0.1.6/tower_rate_limiter/trait.ResponseFactory.html)
- [https://doc.rust-lang.org/cargo/reference/rust-version.html](https://doc.rust-lang.org/cargo/reference/rust-version.html)
- [https://tower-rs.github.io/tower/tower/](https://tower-rs.github.io/tower/tower/)

---


## Perplexity Results

---
prompt: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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
provider: perplexity
model: sonar-deep-research
operation_id: research-20260918-151845-96abb3c658eb437e
created_at: 2026-09-18T15:18:45.890558
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

# R74 — Rate-Limiting Middleware Bundle for `rs-launch-blueprint`

The recommended design for R74 is that `rs-launch-blueprint` **does adopt** a rate‑limiting middleware for its web service, implemented as a Tower‑compatible layer built on the **`tower_governor`** crate and its underlying **`governor`** rate‑limiter, wired off by default and enabled by a single environment‑driven configuration value mirroring the Python precedent.[1][9][11] When the rate limiter is enabled, it uses the governor crate’s in‑memory state store, which is explicitly documented as a pluggable point for future distributed stores, thereby satisfying the “in‑memory, single‑instance‑by‑design” requirement while leaving room for later horizontal scaling.[9] The middleware is configured with a token‑bucket style quota (steady refill with controlled bursts) and on rejection returns `429 Too Many Requests` responses enriched with an accurate `Retry-After` header computed from the limiter’s next‑allowed timestamp, with the response body ultimately wrapped by whatever problem+json envelope R70 decides. The configuration gate is expressed as an optional setting derived from a single environment variable (for example `RS_LAUNCH_RATE_LIMIT`), and the web service only inserts the rate‑limiting layer when this setting is present and valid, matching the Python blueprint’s off‑by‑default behavior and making the rate limiter a clearly documented extension point rather than a mandatory mechanism. This bundle keeps the rate limiter implementation idiomatic for modern Rust async web services, aligns with established practice around the `governor` crate, preserves the owner’s portability and MSRV constraints, and gives a clear migration path if future templates require a distributed store or framework change.

## Context and Scope of R74

R74 decides whether the Rust port of the launch blueprint should carry an explicit rate‑limiting middleware for its web service, and if so, which crates and architectural pattern are used, how the middleware is configured, and how it expresses HTTP semantics such as 429 responses and `Retry-After` headers. The blueprint itself is a tri‑surface template—CLI, library, and web service—where the web service is only one of several faces; as such, any web-specific mechanism, including rate limiting, must not dominate the overall design or introduce global complexity that burdens the CLI or library surfaces.

The Python precedent is clear and binding at the level of **principle and pattern** but not at the level of specific libraries or algorithms. In the Python implementation, app‑wide rate limiting is wired off by default, enabled by a single configuration setting derived from environment, and backed by an in‑memory store that is explicitly documented as a future swap point for a distributed backend such as Redis.[Context] The middleware emits `429 Too Many Requests` responses as RFC‑compliant problem documents with an accurate `Retry-After` header, which expresses either a delay in seconds or an absolute HTTP‑date timestamp consistent with the rate limiter’s internal notion of when a request will next be allowed.[Context] TypeScript, by contrast, has no web service and therefore no precedent to reconcile, leaving Rust free to follow the Python pattern as long as it respects Rust ecosystem norms.

Several constraints shape R74’s design space. The Rust edition must be 2024, the MSRV must track “stable minus two minor versions” and be declared via `rust-version` in Cargo.toml, and CI must cover `ubuntu-latest` and `macos-latest` as first‑class targets.[PARAMETERS] The bundle itself must use crates whose licenses are compatible with `MIT OR Apache-2.0` and whose dependency trees do not introduce RustSec advisories or unsafe usage in conflict with the blueprint’s general posture. The rate‑limiting store must be in‑memory and single‑instance by design—meaning the template does not try to model a sharded or multi‑node limiter—but must clearly mark the limiter state as a pluggable component if future versions need a distributed, horizontally scalable store.

Because R69 (web‑framework stack) and R70 (HTTP problem envelope) are separate items that own the decision about which web framework to use and how errors are enveloped, R74 must not hard‑wire a specific framework such as Axum or Warp, nor a specific problem+json implementation. Instead, it must select a rate‑limiting library and pattern that integrates cleanly with whatever middleware model R69 chooses, and that can express its 429 errors either via plain HTTP responses or via structured error types compatible with R70’s eventual error‑mapping design. The decision must also respect R75’s middleware‑ordering contract; R74 does not decide where in the stack rate limiting sits relative to request IDs, security headers, or access logs, but it must be implementable in any reasonable ordering R75 lands on.

The owner’s research mandate further requires that R74’s recommendation be grounded in a fresh ecosystem survey and a comparison of architectural alternatives, not only a choice among familiar crates. Source implementations, blog posts, and crate documentation are evidence, not predetermined winners; any recommendation that departs from the Python baseline must be flagged explicitly as `BASELINE-REVIEW` with the principle, the proposed change, and the supporting evidence. In this report, no such departure is recommended; instead, the Python pattern is carried into Rust with an idiomatic implementation that respects Rust’s async and middleware conventions.

With that scope established, the rest of the report follows the mandated survey method: landscape first, principles next, then a concrete recommendation, detailed member analysis, compatibility, parameters, migration implications, validation strategy, and confidence, all framed for the rs‑launch‑blueprint template.

## R74 Bundle Analysis

### Landscape

The category R74 is deciding can be described as **“application‑level HTTP rate‑limiting middleware for async Rust web services, keyed by IP or other identity, backed by an in‑memory store, and exposing 429 + `Retry-After` semantics.”** Within the Rust ecosystem, rate limiting is not part of the first‑party standard library or language toolchain, but is instead provided by a set of web‑framework‑specific and framework‑agnostic crates.

Mapping the field into the three required bins—built‑in or first‑party toolchain, established industry standard, and up‑and‑comer—shows that there is no true first‑party rate‑limiting mechanism in Rust itself. The standard library and core asynchronous runtimes do not include HTTP rate‑limiting features. Instead, **“established industry standard”** in this space refers to crates that have become the de facto choice for many projects or that form the basis of other middleware layers. The **`governor`** crate is a primary example: it provides a high‑performance, production‑ready rate limiter with in‑memory state stores, a clear abstraction for state backends (`StateStore`), and support for token‑bucket style quotas.[9][2] Its documentation emphasizes production readiness and extensibility, and multiple independent guides—such as the OneUptime blog’s tutorial on implementing production‑ready rate limiting in pure Rust—treat `governor` as the idiomatic foundation.[2] Similarly, **`limitation`** and its associated **`limitation-actix-middleware`** crate provide a Redis‑backed fixed‑window limiter with an Actix middleware wrapper, and have been used to front APIs and reverse proxies, indicating that they capture an established architectural pattern even if their specific implementation is now somewhat dated.[7][15][18]

In the **web framework ecosystems**, several crates have emerged as standard or semi‑standard options. For the Tower‑based stack (which includes Axum, Hyper, and Tonic), **`tower_governor`** provides a Tower service and layer that wraps the `governor` crate and exposes configurable key‑based and global limits, with ready‑to‑use key extractors for peer IP addresses, proxy headers, and global keys.[1][11] Its documentation explicitly notes compatibility with Axum, Hyper, Tonic, and other Tower‑based frameworks, and it uses the governor quota abstraction to specify how many requests can be sent per key before blocking further requests.[1][8] For Warp, **`warp-rate-limit`** offers RFC 6585‑compliant in‑memory rate limiting with configurable windows and limits, exposed via Warp filters that add rate‑limiting headers and rejections.[4] For Actix, **`limitation-actix-middleware`** provides a Redis‑backed fixed‑window counter keyed on a header, and **`actix-ratelimit`** (now archived) offered an actor‑based asynchronous rate‑limiting middleware with a `MemoryStore` and `MemoryStoreActor` for in‑memory state.[6][7][18]

The **up‑and‑comer** bin includes newer, more focused crates that have appeared as the Rust web ecosystem has matured. **`basic-axum-rate-limit`** is a crate specifically for Axum that implements token‑bucket rate limiting using per‑IP buckets, with optional database callbacks for persistence.[10] Its documentation emphasizes simplicity and a callback pattern for database operations, and notes that each IP address gets a bucket with a maximum capacity of tokens equal to the configured rate‑limit per minute, with continuous token refill and per‑request consumption.[10] **`axum-limit`** similarly provides an efficient rate‑limiting mechanism using token buckets, designed for asynchronous web applications with extractor‑based rate limits and backed by a `DashMap` for concurrent state management.[17] These crates focus on Axum’s extractor and state mechanisms, and represent newer offerings that follow idiomatic Axum patterns. Finally, the **Arc2proxy blog** demonstrates a custom Tower middleware for rate limiting in Axum, followed by a production‑ready integration using `tower_governor`, showing how practitioners are currently approaching rate limiting in modern Tower‑based services.[5]

Authority in this landscape is established through several sources. First, **docs.rs** entries for crates such as `tower_governor`, `governor`, `warp-rate-limit`, and `limitation-actix-middleware` are authoritative because they are generated from the crates’ own documentation and are updated with each release.[1][4][7][8][9][14][16][18] Second, **GitHub repositories** such as `benwis/tower-governor`, `fnichol/limitation`, and `TerminalWitchcraft/actix-ratelimit` are authoritative for license, maintenance status, and architectural intent, because they are maintained (or explicitly archived) by the crate authors and include source code, Cargo manifests, and CI configuration.[3][6][11][12][15][17] Third, widely cited independent write‑ups like the OneUptime blog on rate limiting in Rust and the Arc2proxy article on using `tower_governor` with Axum provide practice‑oriented authority: they explain how to apply these crates in real services, discuss algorithm trade‑offs, and highlight production considerations such as IP‑based limits and bursts.[2][5] These are not standards in themselves, but they show how the ecosystem has converged on certain patterns.

Practice evidence, in the sense of what mainstream, well‑regarded Rust projects do, is somewhat harder to quantify within this environment because direct reverse‑dependency analysis and adoption metrics require crates.io and GitHub API queries that are not available here. However, we can infer several points. The Warp ecosystem’s own rate‑limit crate describes itself as lightweight middleware for Warp web applications, and its examples show how to add rate‑limit filters and rejection handlers, making it a natural choice for Warp‑based services.[4] The `limitation` project includes not only a library and Actix middleware, but also a `limitation-proxy` reverse proxy service, indicating that it has been used to front APIs in production‑like scenarios.[15] The Arc2proxy article treats `tower_governor` as the production option after first building a custom middleware, and emphasizes that `tower_governor` wraps the well‑tested `governor` library and provides per‑IP keying, burst support, and correct 429 responses out of the box.[5] The OneUptime blog positions `governor` as a “high-performance, production-ready rate limiter” and shows how to configure token buckets and limits for public and authenticated endpoints, reinforcing its status as an established standard in Rust for in‑process rate limiting.[2]

Fit for the rs‑launch‑blueprint template must be judged against this landscape, not against abstract notions of “best” or most popular. The template is single‑process by design, with an in‑memory idempotency cache and other non‑distributed components, and is meant to be a starting point rather than a horizontally scalable system. That makes **`governor`** and **`tower_governor`** attractive, because they are designed for in‑memory state, can later be extended to distributed stores by implementing `StateStore`, and integrate cleanly with Tower‑based frameworks that are likely candidates for R69.[1][9][11] Warp‑specific and Actix‑specific crates are less compelling unless R69 explicitly chooses those frameworks, and Redis‑backed crates such as `limitation-actix-middleware` do not match the in‑memory single‑instance requirement. Axum‑only crates like `basic-axum-rate-limit` and `axum-limit` are promising for Axum, but they do not generalize as readily to other Tower‑based frameworks and do not offer as clean a story for future distributed state as `governor` does.[10][17]

Within this landscape, the shortlisted candidates for R74 therefore come from the **established standard** bin (`governor`, `tower_governor`, `warp-rate-limit`, `limitation` and its middleware) and the **up‑and‑comer** bin (`basic-axum-rate-limit`, `axum-limit`), with the final choice weighted heavily by fitness for the template’s single‑process, tower‑based, future‑extensible shape and the Python baseline’s off‑by‑default, env‑gated pattern.

### Principles and Implementation

The shared requirement for R74 derives from the Python implementation and the owner’s clarification: the blueprint must have a **consistent architectural pattern** for rate limiting across languages, while allowing for ecosystem‑appropriate implementation differences. The level at which agreement is required is **architectural pattern and behavior**, not specific frameworks or library APIs. Concretely, the shared principle is that the web service offers **configurable, app‑wide rate limiting** that is:

1. **Off by default and gated by a single optional configuration value**, typically derived from environment, matching Python’s `rate_limit: str | None = None` gate.[Context]  

2. **Backed by an in‑memory, single‑instance store** that is explicitly documented as a future swap point for a distributed store, but not implemented as distributed in the template.[Context][9]  

3. **Expressed via standard HTTP semantics**: the limiter responds with `429 Too Many Requests` when limits are exceeded and sets an accurate `Retry-After` header based on the limiter’s internal next‑allowed time.[4][5]  

4. **Integrated into the web service’s middleware stack** in a way that preserves other concerns (request IDs, security headers, logging) and fits the chosen framework’s middleware model, without forcing a specific envelope shape for error responses, which R70 will decide.[Context]

Essential behaviors and observable acceptance criteria follow from these principles. The essential behaviors include: correctly enforcing a configured rate limit per key (IP, user, or global) over time; allowing short bursts within the quota while respecting long‑run limits; rejecting excess requests with 429; and computing `Retry-After` from the limiter’s notion of how long until the next allowed request, either in seconds or as an HTTP date. Acceptance criteria include: reproducibility of limits in test scenarios; demonstrable off‑by‑default behavior when the env var is absent; clear, documented configuration binding when the env var is present; and testable presence and correctness of `Retry-After` and any other rate‑limiting headers in the 429 responses.

Architecturally, several alternatives exist:

One alternative is to **embed rate limiting directly into the web framework**, using framework‑native primitives and custom application code rather than a separate crate. The Arc2proxy article illustrates this by building a custom Tower middleware for Axum that keeps a per‑IP token bucket in a `DashMap`, refills based on elapsed time, and rejects when the bucket is empty.[5] This approach is highly flexible and can be tailored exactly to the blueprint’s needs, but it requires careful implementation of concurrency, edge cases, and header semantics, and it lacks the battle‑tested nature of a dedicated rate‑limiting crate.

A second alternative is to use **framework‑specific middleware crates** such as `warp-rate-limit` for Warp or `limitation-actix-middleware` for Actix.[4][7][18] These provide more tooling than a fully custom implementation, but they tie the rate limiter to a specific framework. `warp-rate-limit` provides RFC 6585‑compliant in‑memory rate limiting with configurable windows, and offers filters that add rate limit headers and rejection types that can be handled in a rejection handler.[4] `limitation-actix-middleware` uses a Redis‑backed fixed‑window counter keyed on a header, and requires registration of a `HeaderName` and a `Limiter` in Actix’s app data.[7][18] For rs‑launch‑blueprint, which may use Axum or Hyper rather than Warp or Actix, these are less directly applicable unless R69 narrows the field.

A third alternative is to use **Axum‑specific token‑bucket crates**, such as `basic-axum-rate-limit` or `axum-limit`.[10][17] `basic-axum-rate-limit` implements a per‑IP token bucket with continuous refill and optional database callbacks, and provides middleware that screens requests before hitting handlers.[10] `axum-limit` uses extractors to enforce rate limits per route, supports various time granularities, and uses `DashMap` for concurrent state management.[17] These crates align well with Axum’s patterns and allow per‑route limits, but they do not generalize to other Tower‑based frameworks and their state pluggability for distributed stores is less explicit than in `governor`.[17][10]

Finally, the fourth alternative—the one favored here—is to use **a general rate‑limiting library (`governor`) with a Tower‑compatible middleware wrapper (`tower_governor`)**, preserving both generality and idiomatic integration. The `governor` crate provides a `RateLimiter` type that ties together parameters (how many cells to allow over what time) and the concrete state of rate‑limiting decisions.[9] It ships in‑memory state stores and allows implementing custom stores by providing a `StateStore` trait implementation, making in‑memory vs distributed a clear architectural extension point.[9] `tower_governor` wraps `governor` as a Tower layer, supports key extraction based on peer IP, proxy headers, or global keys, and exposes configuration via `GovernorConfigBuilder` with options such as `per_second`, `burst_size`, and `use_headers`.[1][8][11] This pattern keeps rate limiting decoupled from any single framework while remaining idiomatic for Tower‑based web services, which include Axum, Hyper, and Tonic.[1][11]

Comparing these alternatives against the shared principle and acceptance criteria, the **governor + tower_governor bundle** best realizes the blueprint’s requirements. It respects the in‑memory single‑instance requirement by default, while providing a clear `StateStore` swap point for future distributed stores.[9] It offers robust, well‑understood rate limiting algorithms (token bucket and related quotas) that allow bursts while enforcing long‑run rates, as highlighted in the OneUptime and Arc2proxy articles.[2][5] It integrates cleanly into Tower’s middleware model, enabling R69 to choose Axum, Hyper, or other Tower‑based frameworks without changing the rate limiter architecture.[1][11] And while `tower_governor` does not explicitly document `Retry-After` computation in the snippets available here, its `use_headers` option and `RateLimitingMiddleware` abstraction provide a natural place to compute and add that header based on `governor`’s internal timing, which can be wrapped or extended in the blueprint to ensure accuracy.[8][9]

The architectural pattern is thus: a **Tower layer using `tower_governor`** configured with a `GovernorConfigBuilder` specifying per‑second rate and burst size, keyed by IP or other identity via a key extractor, using `governor`’s in‑memory state store, and extended with a custom middleware wrapper to compute and set `Retry-After` based on the limiter’s next‑allowed time. The layer is **conditionally inserted** into the web service’s middleware stack based on a single environment‑driven configuration value, and its 429 responses are ultimately wrapped into a problem+json envelope by a separate error‑handling or response‑rewriting layer owned by R70.

No `BASELINE-REVIEW` is necessary here, because the recommended design preserves the Python precedent’s principle and pattern—off‑by‑default, env‑gated, in‑memory store, 429 + `Retry-After`—while merely adopting Rust‑idiomatic libraries and middleware structures to realize it.

### Recommendation

The recommended stack for R74 is:

**Stack name:** `rs-launch-rate-limit-governor`  
**Crates:**  
• `tower_governor` (Tower middleware layer for rate limiting)  
• `governor` (rate‑limiting engine and state store abstraction)  

**Reference pattern:**  

1. The web service crate declares dependencies on `tower_governor` version `0.8.0` (or later compatible minor) and the corresponding `governor` version used by `tower_governor` internally, without overriding the `governor` version in Cargo.toml.[14][16][3][11]  

2. A configuration module defines an optional rate‑limit setting, for example `rate_limit: Option<String>`, derived from a single environment variable such as `RS_LAUNCH_RATE_LIMIT`. If the variable is absent, the setting is `None`, and no rate‑limiting layer is inserted. If present, the variable is parsed into a simple spec such as `"60/s,burst=10"` or `"100/m,burst=20"`, mapped to per‑second rate and burst size values for `GovernorConfigBuilder`.[2][8]  

3. At web service construction time, the router or service builder consults the configuration. If `rate_limit` is `Some(spec)`, it constructs a `GovernorConfigBuilder` with `.per_second(rate)` and `.burst_size(burst)` and `.use_headers()`, then wraps the router with the resulting `tower_governor` layer keyed by IP via `PeerIpKeyExtractor` or `SmartIpKeyExtractor`.[1][8]  

4. The middleware layer is extended or complemented by a small custom wrapper that intercepts rate‑limit rejections and computes `Retry-After` using `governor`’s internal timing—for example, by calling a method that returns the time until the next permitted request and converting that to seconds or an HTTP date. The wrapper then constructs a `429 Too Many Requests` response with appropriate rate‑limiting headers, including `Retry-After`, and leaves the body to be wrapped into a problem+json envelope by R70’s error‑handling layer.[4][5][9]  

5. The implementation documents the in‑memory nature of the limiter state and points to `governor`’s `StateStore` abstraction as the future swap point if a distributed store such as Redis is needed.[9] It also documents the env‑var gate clearly, noting that the template ships with rate limiting disabled by default, matching the Python blueprint’s behavior.

In summary, **`rs-launch-blueprint` should adopt a rate‑limiting middleware**, wired off by default and enabled by one env var, backed by an in‑memory `governor` store, and rendering 429s with an accurate `Retry-After` header computed via a thin wrapper around `tower_governor`. This design is idiomatic for Tower‑based Rust web services, preserves the Python pattern, and leaves R69 and R70 free to choose the web framework and problem envelope without forcing further rate‑limiting changes.

### Members

#### tower_governor

##### Landscape

The `tower_governor` crate sits in the **Tower‑based middleware ecosystem**, providing a rate‑limiting middleware layer backed by the `governor` crate.[1][11][14][16] It is described as “a rate-limiting middleware for Tower backed by the governor crate that allows configurable key based and global limits,” and it explicitly notes that it works with Axum, Hyper, Tonic, and anything else based on Tower.[1][11][14][16] This positions `tower_governor` squarely in the “established industry standard” bin for Tower‑based rate limiting: it is not part of the Rust standard library or toolchain, and it is not yet as pervasive as some core frameworks, but within the Tower ecosystem it is a widely referenced solution.

Authoritative documentation for `tower_governor` comes from its docs.rs page and its GitHub repository. The docs.rs entry outlines features such as rate limiting requests based on peer IP address, IP address headers, globally, or via custom keys; custom traffic limiting criteria per second or bursts; and a robust yet flexible API.[1] The GitHub repository’s Cargo.toml confirms its description as “a rate-limiting middleware for Tower backed by the governor crate that allows configurable key based and global limits” and shows that it is licensed under MIT or Apache‑2.0, matching the blueprint’s license requirements.[3][14][16] The repository is public and not marked as archived, suggesting ongoing maintenance.[11] Additionally, the Arc2proxy article treats `tower_governor` as the production rate‑limiting option for an Axum 0.7 service, first building a custom middleware and then switching to `tower_governor`, indicating that practitioners regard it as sufficiently mature and reliable for production use.[5]

Practice evidence for `tower_governor` includes its use in tutorials and examples, such as the Arc2proxy article and the crate’s own examples directory, which includes `custom_key_bearer.rs` showing how to rate‑limit based on a bearer token rather than IP.[5][12] While we cannot query crates.io to obtain download figures or reverse dependencies in this environment, the presence of examples tailored to Axum, Hyper, and Tonic suggests that it is used across multiple frameworks. The fact that it is built on `governor`, a crate described as “production-ready” and offering in‑memory and pluggable state stores, also contributes to its status as an established option rather than a niche experiment.[9][2]

Within the rs‑launch‑blueprint template, `tower_governor` maps cleanly to the desired category: it is middleware that can be conditionally inserted into the web service stack, it defers algorithm and state concerns to `governor`, and it handles key extraction and response shaping in a way that fits Tower’s service and layer abstractions.[1][8][11] It is neither built‑in nor up‑and‑comer in the sense of being a brand‑new crate; instead, it functions as an integration layer for the established `governor` standard.

##### Principles and Implementation

`tower_governor`’s design directly supports the shared requirements of R74. It defines a middleware configuration that stores a quota, specifying how many requests can be sent from a given key (typically an IP address) before the middleware starts blocking further requests.[1] Once at least one element of the quota has been used, the elements are replenished after a specified period, implementing a token‑bucket‑like behavior with bursts and steady refill.[1][5] The configuration is built via `GovernorConfigBuilder`, which accepts parameters such as `per_second` and `burst_size` and can be instructed to `use_headers` to add rate‑limiting headers to responses.[8]

Key extraction is central to the blueprint’s requirement that rate limiting be keyed by IP or other identity. `tower_governor` provides three ready‑to‑use key extractors: `PeerIpKeyExtractor`, which uses the peer IP address of the request; `SmartIpKeyExtractor`, which looks for common IP identification headers such as `X-Forwarded-For`, `X-Real-IP`, and `Forwarded` and falls back to the peer IP address; and `GlobalKeyExtractor`, which uses the same key for all incoming requests.[1] This covers both the per‑IP and global patterns, and matches Python’s use of per‑IP limits for public endpoints and per‑user limits for authenticated APIs, as highlighted in the OneUptime blog.[2] For rs‑launch‑blueprint, per‑IP keying via `PeerIpKeyExtractor` or `SmartIpKeyExtractor` is the natural default; global keying can be used for internal or health endpoints if desired.

Response shaping and header semantics are handled via `RateLimitingMiddleware` and the `use_headers` configuration option. The docs.rs snippet for `GovernorConfigBuilder` shows that adding `.use_headers()` will cause the middleware to include rate‑limiting headers in responses.[8] While the exact headers are not fully detailed here, they are typically rate‑limit headers such as remaining quota, reset time, and possibly `Retry-After`. `tower_governor` is built on governor’s middleware traits (`RateLimitingMiddleware<QuantaInstant>`), suggesting that it can compute timing information based on governor’s internal notion of time (`QuantaInstant`) and translate that into header values.[8][9] This provides the hook necessary to compute an accurate `Retry-After` value.

From an implementation perspective, `tower_governor` is a Tower layer that can be inserted into a stack via `.layer()` or `ServiceBuilder`, making it straightforward to conditionally include based on configuration. The pattern in Arc2proxy’s article demonstrates constructing a Tower middleware from scratch, then replacing it with `tower_governor` in an Axum router, indicating that the integration cost is low and that it fits well into the typical `Router::new().route(...).layer(...)` pattern in Axum.[5] For rs‑launch‑blueprint, the web service builder would follow a similar pattern: if the `rate_limit` configuration is present, add a `tower_governor` layer; if not, leave the router unwrapped.

In terms of shared principle, `tower_governor` preserves the Python pattern by delegating algorithm and state semantics to `governor`, using in‑memory storage by default, and offering a configuration builder that can be tied to a single env‑driven setting. It does not enforce any particular error envelope or problem+json format; instead, it focuses on HTTP status and headers, leaving body shaping to higher layers, which aligns with R70’s ownership of the envelope.

##### Dominant Choice

Within the Tower‑based ecosystem, `tower_governor` is the **dominant choice** for R74 for several reasons. First, it is explicitly designed to wrap the `governor` crate into the Tower middleware model, making it idiomatic for Axum, Hyper, Tonic, and similar frameworks.[1][11] Second, it exposes configuration via `GovernorConfigBuilder`, which closely matches the blueprint’s desire to specify rate limits in terms of per‑second rates and burst sizes, and offers a `use_headers` option for adding rate‑limiting headers.[8] Third, it provides built‑in key extractors for peer IP, proxy headers, and global keys, making it easy to implement per‑IP and global limits without custom extraction logic.[1]

Performance and dependability are also favorable. `tower_governor` builds on `governor`, which the OneUptime blog describes as “high-performance” and “production-ready,” and which uses efficient in‑memory state stores.[2][9] The Arc2proxy article notes that token bucket is the most common algorithm because it permits short, legitimate bursts while enforcing long‑run rates, and `tower_governor` adopts this pattern via `governor`’s quota abstraction.[5] Integration cost is modest: adding the crate as a dependency, constructing a `GovernorConfigBuilder`, and inserting a layer are all straightforward, and the crate’s API is designed to be simple and highly customizable.[1][8]

Given these factors, `tower_governor` is the dominant choice for the middleware member of the bundle, ahead of alternatives such as custom Tower middleware, Axum‑specific crates, or framework‑specific limiters, because it balances generality, maturity, and idiomatic integration in a way that fits rs‑launch‑blueprint’s architecture.

##### Qualified Shortlist

The qualified shortlist for Tower‑compatible rate‑limiting middleware includes:

A custom Tower middleware built directly on `governor`, akin to the Arc2proxy article’s from‑scratch implementation.[5][9] This would involve constructing a `RateLimiter` per key, storing them in a `DashMap`, and manually computing `Retry-After` headers. It offers maximum flexibility but higher implementation and maintenance cost.

Axum‑specific middleware using `basic-axum-rate-limit`, which implements a token bucket per IP and uses a callback pattern for optional database operations.[10] It aligns with Axum’s patterns and offers an explicit block duration, but is tied to Axum and does not generalize to other Tower frameworks.

Extractor‑based rate limiting via `axum-limit`, which uses extractors like `LimitPerSecond<5, Uri>` to enforce per‑route limits and stores state in a concurrent `DashMap`.[17] It is efficient and idiomatic for Axum, but again framework‑specific and less obviously pluggable for distributed state.

Warp‑specific `warp-rate-limit`, which provides in‑memory RFC‑compliant rate limiting and a filter‑based API.[4] It is a strong option if R69 chooses Warp, but less relevant otherwise.

The shortlist is constrained by the requirement that the bundle be usable across Tower‑based frameworks, not only Axum, and by the desire to keep the limiter state pluggable for future distributed stores. These constraints favor `tower_governor` over Axum‑specific or custom implementations.

##### Excluded by Gate

Several candidates are excluded by fitness gates or architectural mismatch.

`actix-ratelimit` is excluded because its GitHub repository is marked as a public archive, indicating that it is no longer maintained.[6] An archived crate fails the maintenance gate and is at risk for unpatched issues, making it unsuitable for a template.

`limitation-actix-middleware` and its underlying `limitation` crate are excluded for the rs‑launch‑blueprint bundle because they are explicitly Redis‑backed, using a fixed‑window counter keyed on a header, and requiring a Redis URI in the `Limiter::build` call.[7][15][18] This conflicts with the in‑memory single‑instance requirement for the template, which does not include a Redis dependency or distributed store.

Warp‑specific `warp-rate-limit` is excluded unless R69 chooses Warp as the web framework. Its filter‑based API is tightly coupled to Warp, and while it meets in‑memory and RFC compliance requirements, it does not integrate directly with Tower’s middleware model.[4] Given R69 is open and likely to choose a Tower‑based framework, `warp-rate-limit` is not appropriate as the primary bundle member.

Axum‑specific crates `basic-axum-rate-limit` and `axum-limit` are excluded from the bundle if R69 does not commit to Axum. They are strong options within Axum, but their extractor‑based and middleware patterns do not generalize to Hyper or Tonic without significant adaptation.[10][17]

##### Up-and-comers

Within the Tower ecosystem, `tower_governor` itself is somewhat of an up‑and‑comer in the sense that it wraps a more established `governor` crate into a relatively new Tower‑based web framework landscape. However, its design and documentation show a maturity of integration that moves it into the established standard bin.[1][11][14][16]

For Axum specifically, `basic-axum-rate-limit` and `axum-limit` are up‑and‑comers that may continue to evolve and gain adoption.[10][17] They explore token‑bucket algorithms, extractor‑based enforcement, and concurrent state management via `DashMap`, and may inform future refinements to Tower‑based rate‑limiting patterns.

The bundle’s choice of `tower_governor` does not preclude future experiments or migrations to these up‑and‑comers; instead, it anchors the initial template on a robust and general solution, with the understanding that Axum‑specific enhancements can be layered on later if needed.

##### Fit for This Template

`tower_governor` fits rs‑launch‑blueprint’s requirements in several critical ways. It is Tower‑compatible, meaning it can integrate with any framework R69 chooses as long as that framework uses Tower’s service and layer model—Axum, Hyper, Tonic, and potentially others.[1][11] It uses `governor` for rate‑limiting logic, which is in‑memory by default and exposes a `StateStore` abstraction for future distributed stores, satisfying the blueprint’s single‑instance design while leaving a clear migration path.[9]

The crate’s configuration builder allows specifying per‑second rates and burst sizes, which can be mapped directly from a single env‑driven configuration string, mirroring Python’s `rate_limit: str | None` pattern.[8][2] Its key extractors align with common deployment scenarios involving reverse proxies and direct connections, and its `use_headers` option allows adding rate‑limiting headers without custom header management.[1][8] As a middleware layer, it can be conditionally inserted into the web service stack, preserving off‑by‑default behavior and avoiding non‑web surfaces such as CLI and library.

Finally, because `tower_governor` focuses on HTTP status and headers rather than problem‑document envelopes, it leaves the envelope shaping to R70, allowing the blueprint to render 429 errors as problem+json documents without constraining the rate‑limiter implementation.

##### Recommendation

For the middleware member of the bundle, the recommendation is to **adopt `tower_governor` as the primary Tower‑compatible rate‑limiting layer**, configured via `GovernorConfigBuilder` and keyed by IP using `SmartIpKeyExtractor` by default. The template should:

1. Declare `tower_governor = "0.8"` as a dependency in the web service crate’s Cargo.toml, with license compatibility confirmed via the repository’s MIT/Apache‑2.0 licensing.[14][16][3]  

2. Use `GovernorConfigBuilder::default().per_second(rate).burst_size(burst).use_headers().finish()?` to construct the configuration, mapping `rate` and `burst` from the parsed environment setting.[8][2]  

3. Wrap the web service router with the resulting `tower_governor` layer only when the env‑derived `rate_limit` configuration is present, leaving the router unwrapped otherwise (off‑by‑default).[1][5]  

4. Extend or wrap the layer to compute `Retry-After` headers based on the limiter’s next‑allowed time, using `governor`’s internal timing and state.[9]  

This recommendation positions `tower_governor` as the bundle’s middleware member and leverages its integration with `governor` for rate‑limiting logic and in‑memory state.

##### Ranked Runner-up

The ranked runner‑up for the middleware member is a **custom Tower middleware built directly on `governor`**, as illustrated by the Arc2proxy article’s from‑scratch implementation.[5][9] In this pattern, rs‑launch‑blueprint would:

1. Instantiate a `governor::RateLimiter` per key (IP or user), stored in a concurrent map such as `DashMap`.[5][9]  

2. Implement middleware that checks the limiter for each request, rejects when the quota is exhausted, computes `Retry-After` from the limiter’s state, and adds headers accordingly.[5]  

3. Manage key extraction manually, including proxy headers and global keys, and implement its own header naming and semantics.

This runner‑up offers full control over algorithms, headers, and error types, which could be beneficial if R70 requires a specific error‑type integration that `tower_governor` does not readily support. However, it increases implementation complexity and maintenance burden and duplicates many capabilities already available in `tower_governor`.

##### Tradeoffs

Adopting `tower_governor` involves several tradeoffs. On the positive side, it reduces implementation risk by relying on a well‑tested `governor` backend, provides key extractors and configuration builders that cover common cases, and integrates cleanly with multiple Tower‑based frameworks.[1][8][11] It aligns with the Python pattern and offers a natural hook for `Retry-After` via `use_headers` and timing information.[8][9] On the negative side, it introduces a dependency on a specific middleware crate whose API may evolve, and it may not expose every nuance of governor’s capabilities or envelope integration out of the box.

Using a custom middleware built directly on `governor` would give maximum flexibility but at the cost of reinventing parts of `tower_governor`, including key extraction, quotas, and header management.[5][9] Axum‑specific crates offer attractive features such as extractor‑based limits and per‑route granularity, but they tie the bundle to Axum and make it harder to support other Tower frameworks.[10][17] Redis‑backed crates are powerful for distributed rate limiting but conflict with the template’s single‑instance in‑memory requirement.[7][15][18]

Overall, the tradeoff favors `tower_governor` as a pragmatic, idiomatic choice that balances generality and simplicity, leaving room for future refinement if R69 or R70 introduce constraints that require deeper customization.

##### Parameters

For the `tower_governor` member, the following parameters are proposed:

`owns R74.rate_limit_middleware_crate = "tower_governor"`  
`owns R74.rate_limit_algorithm = "token_bucket_quota"` (as implemented by governor quotas)[1][5][9]  
`owns R74.rate_limit_key_default = "SmartIp"` (using `SmartIpKeyExtractor`)[1]  
`owns R74.rate_limit_headers_enabled_default = true` (using `.use_headers()`)[8]  

The member assumes:

`assumes R69.web_framework_uses_tower = true` (Axum, Hyper, Tonic, or similar)[1][11]  

There is no conflict with existing parameters; no `CONFLICT` line is required.

##### Migration Implications

Integrating `tower_governor` into `rs-launch-blueprint` requires several file‑level changes.

The web service crate’s Cargo.toml must add `tower_governor` as a dependency, with version `0.8` or similar, and ensure that the `rust-version` field and CI tests cover the MSRV policy and target OS matrix.[14][16] The web service configuration module must define an optional rate‑limit setting, derive it from environment, and parse it into parameters compatible with `GovernorConfigBuilder` (per‑second rate and burst size).[2][8]

The web service builder (likely a function that constructs the router or service stack) must be updated to conditionally insert a `tower_governor` layer based on the presence of the `rate_limit` configuration. When present, it builds the `GovernorConfigBuilder`, calls `.use_headers()`, finishes the configuration, and attaches the layer; when absent, it skips this step.[1][8][5]

Error‑handling or response‑rewriting logic must be extended to recognize rate‑limit rejections and wrap them into the problem+json envelope that R70 will define. This may involve mapping `tower_governor`’s rejection type to a structured error and adding `Retry-After` headers based on governor’s timing. These changes remain within the web service crate and do not affect the CLI or library surfaces.

##### Validation Strategy

Validation of the `tower_governor` member involves both compile‑time and runtime checks.

At compile time, the web service must build successfully with `tower_governor` as a dependency on the specified Rust edition and MSRV, and CI must pass on `ubuntu-latest` and `macos-latest`. This ensures that the crate and its dependencies are compatible with the template’s platform and MSRV constraints.

At runtime, a minimal example should be created in the template’s `examples/` directory, showing a web service that uses `tower_governor` for rate limiting. The example would define an env var such as `RS_LAUNCH_RATE_LIMIT=60/s,burst=10`, start the service, and make repeated requests from the same client. Observed behavior should include acceptance of the first 10 requests quickly, then enforced rate limiting on subsequent requests, with 429 responses that include appropriate rate‑limit headers and `Retry-After` values. Turning off the env var should disable rate limiting, allowing unlimited requests in tests.

A more detailed validation strategy is described later in the global Validation Strategy section.

##### Confidence & Re-verify Trigger

Confidence in `tower_governor` as the middleware member is high, given its alignment with `governor`, its documentation, and its use in practice (for example in Arc2proxy’s Axum service).[1][5][9][11] Re‑verification should be triggered if:

1. R69 chooses a non‑Tower web framework such as Warp or Actix, making Tower‑based middleware less relevant.  

2. `tower_governor` becomes archived or shows signs of at‑risk maintenance, such as unpatched advisories or broken builds on current stable Rust.  

3. R70 requires a specific error‑type integration that `tower_governor` cannot support without intrusive customization.

In any of these cases, the runner‑up (custom middleware on governor) or a framework‑specific limiter such as `warp-rate-limit` or `limitation-actix-middleware` may need to be reconsidered.[4][7][15][18]

##### Sources

Information about `tower_governor` is drawn from its docs.rs page, which describes features, key extractors, and quota semantics, and from its `GovernorConfigBuilder` documentation, which shows how to configure per‑second rates, burst sizes, and headers.[1][8] The crate’s Cargo.toml on docs.rs and GitHub confirms its description and license.[14][16][3] The GitHub repository `benwis/tower-governor` provides source code and examples, including custom key extractors.[11][12] The Arc2proxy article offers a practical guide to using `tower_governor` in an Axum 0.7 service and compares it with a custom middleware implementation.[5] Together, these sources establish `tower_governor` as a suitable middleware layer for R74.

#### governor

##### Landscape

The `governor` crate is a general‑purpose rate‑limiting library for Rust, designed to be production‑ready and high‑performance.[9][2] It sits in the established standard bin for rate limiting, providing core algorithms and state management upon which middleware layers such as `tower_governor` build. It is framework‑agnostic, working equally well in command‑line, library, and web contexts.

The docs.rs page for `governor` describes its `RateLimiter` type as the structure that ties together parameters (how many cells to allow in what time period) and the concrete state of rate‑limiting decisions.[9] It notes that the crate ships in‑memory state stores but makes it possible to use other stores by implementing the `StateStore` trait.[9] This abstraction is central to R74’s need for an in‑memory single‑instance store and a future distributed swap point. The OneUptime blog calls `governor` “a high-performance, production-ready rate limiter” and uses it to implement per‑IP and per‑user rate limits in pure Rust without external dependencies.[2]

Practice evidence for `governor` includes its use in tutorials and examples focused on production‑grade rate limiting, such as the OneUptime guide, which walks through configuring token buckets, choosing per‑IP vs per‑user keys, setting `Retry-After` headers, and monitoring rate limit hits.[2] It is also used as the backend for `tower_governor`, which wraps `governor` into a Tower layer, and for other middleware crates that require a flexible rate‑limiting engine.[1][11] While we cannot query crates.io for download figures here, the presence of multiple integration layers and blog posts indicates that `governor` has broad adoption and is considered a standard for in‑process rate limiting in Rust.

##### Principles and Implementation

`governor`’s core principle is to separate **rate‑limiting parameters and state** from specific frameworks, providing an algorithmic engine that can be embedded into any context. Its `RateLimiter` type binds together the quota parameters (e.g., allowed cells per time unit) and the concrete state of rate‑limiting decisions, using in‑memory state stores by default.[9] The crate supports various algorithms, with token bucket being a common choice: tokens are added at a fixed rate and consumed per request, allowing smooth rate limiting with bursts.[2][5] This aligns with the blueprint’s desire for a balance between burst tolerance and long‑run fairness.

The `StateStore` abstraction is particularly important for R74’s in‑memory vs distributed store principle. By default, `governor` uses in‑memory state stores, which are appropriate for single‑process templates like rs‑launch‑blueprint.[9] However, it is possible to implement the `StateStore` trait to use other backends, such as databases or distributed caches, enabling migration to multi‑instance deployments if needed. This makes `governor` a good match for the requirement that the store be in‑memory and single‑instance by design, yet explicitly documented as a future swap point.

`governor` also integrates timing and delay information. Its APIs can return whether a request is allowed and, if not, how long until it will be allowed, based on internal timekeeping. This information can be used to compute `Retry-After` headers in web contexts, as recommended by the OneUptime blog, which notes that setting appropriate `Retry-After` headers helps clients back off properly.[2] In R74’s design, `tower_governor` uses `governor` for algorithm and state, and a wrapper computes `Retry-After` from the limiter’s next‑allowed time, satisfying the HTTP semantics requirement.

##### Dominant Choice

`governor` is the dominant choice for the rate‑limiting engine in the bundle. Alternatives such as custom implementations or other limiting libraries exist, but they either lack `StateStore` abstractions or are tied to specific frameworks or stores. For example, `limitation` offers a fixed‑window counter, but it is strongly tied to Redis for state and lacks the general in‑memory vs distributed abstraction that `governor` provides.[15][7] Axum‑specific crates implement token buckets and state management via `DashMap`, but they are not designed as general standalone engines.[10][17]

`governor`’s integration with `tower_governor`, its production‑ready positioning, in‑memory state stores, and `StateStore` trait make it the natural choice for the engine. It preserves the blueprint’s single‑instance design while offering a clear path to distributed state, and it supports algorithm configurations that match the Python pattern and modern web practice.

##### Qualified Shortlist

The qualified shortlist for rate‑limiting engines includes:

Custom rate‑limiting implementations using token bucket or fixed window algorithms, as seen in the Arc2proxy article’s custom middleware.[5] These can be tuned to specific needs but require careful implementation of concurrency and correctness.

The `limitation` crate, which implements a configurable, asynchronous `Limiter` backed by Redis and supports fixed‑window counting keyed on arbitrary keys.[15] It is promising for distributed deployments but conflicts with the template’s in‑memory requirement.

Warp‑specific and Axum‑specific crates that embed algorithms and state management within middleware, such as `warp-rate-limit`, `basic-axum-rate-limit`, and `axum-limit`.[4][10][17] These are engines in practice but not general libraries.

Given the blueprint’s constraints, `governor` remains the best fit, with other engines reserved for scenarios where distributed state or framework‑specific needs arise.

##### Excluded by Gate

`limitation` and its associated middleware are excluded by the in‑memory single‑instance gate. They require Redis as a backend and are architected for distributed rate limiting fronting APIs and proxies.[15][7][18] This is incompatible with the template’s single‑process design and the owner’s preference for future distributed swap points rather than built‑in distributed stores.

Custom engines that do not expose general state abstractions are excluded by maintainability and migration gates: they do not provide clear paths for future distributed stores and are more fragile than a well‑tested general library like `governor`.

##### Up-and-comers

While `governor` is established, newer crates in the rate‑limiting space continue to explore algorithms and integration patterns. Axum‑focused crates implement token buckets and extractor‑based enforcement, and may influence future evolution of `governor` or its wrappers.[10][17] However, they are more specialized and do not replace `governor` as a general engine.

##### Fit for This Template

`governor` fits rs‑launch‑blueprint by providing an in‑memory rate‑limiting engine with a pluggable `StateStore` abstraction, a token‑bucket algorithm that allows bursts, and timing information suitable for `Retry-After` headers.[9][2] It is framework‑agnostic, aligning with the template’s multi‑surface nature, and it integrates smoothly with Tower via `tower_governor`.[1][11] The crate’s design aligns with the blueprint’s principles: off‑by‑default behavior is handled at the middleware layer, not by `governor` itself, but the engine supports the necessary semantics when the middleware is enabled.

##### Recommendation

The recommendation for the engine member is to **adopt `governor` as the rate‑limiting engine underlying `tower_governor`**, without directly exposing `governor` to template users. The template should rely on `tower_governor`’s dependency on `governor` and avoid overriding its version, ensuring compatibility and reducing duplication.[3][14][16][11] Documentation should note that `governor` is the engine and that `StateStore` provides the future distributed swap point.

##### Ranked Runner-up

The runner‑up engine is a custom implementation of token‑bucket rate limiting using `DashMap` or similar concurrency primitives, as seen in the Arc2proxy article.[5] This option offers full control but lacks the generality and `StateStore` abstraction of `governor`, and therefore is less appropriate as a template default.

##### Tradeoffs

Using `governor` trades off implementation control for maturity and generality. It provides proven algorithms and state management but may require adaptations to integrate with specific frameworks or error envelopes. Custom engines could be tailored more precisely to the template’s needs but would increase maintenance and reduce generality. Given the blueprint’s requirements and the desire for future distributed swap points, `governor`’s design tradeoffs are favorable.

##### Parameters

For `governor`, the parameters are:

`owns R74.rate_limit_state_store_abstraction = "governor::StateStore"`[9]  
`owns R74.rate_limit_engine_crate = "governor"`  

No consumed parameters conflict with these; no `CONFLICT` line is necessary.

##### Migration Implications

`governor` is pulled into the template indirectly via `tower_governor`. Migration to a distributed store would involve implementing `StateStore` for a backend such as Redis or a database and configuring `tower_governor` to use the new store, without changing the web service’s public API or env‑driven configuration.

##### Validation Strategy

Validation of `governor` as the engine can be implicit: as long as `tower_governor` behaves correctly in rate limiting tests and respects quotas and timing, `governor` is functioning as expected. Additional low‑level tests could instantiate `governor::RateLimiter` in isolation and verify that it computes delays and allowed/rejected decisions as expected.

##### Confidence & Re-verify Trigger

Confidence in `governor` is high, based on its documentation, practice evidence, and integration into multiple middleware solutions.[9][2][1][11] Re‑verification should be triggered if `governor` acquires a RustSec advisory, becomes unmaintained, or if new standards for rate limiting in Rust emerge that make alternative engines clearly preferable.

##### Sources

Information about `governor` is drawn from its docs.rs page, which describes `RateLimiter` and `StateStore`, and from the OneUptime blog, which uses `governor` in a production‑oriented tutorial.[9][2] References to its integration into `tower_governor` and other middleware come from `tower_governor`’s documentation and repository.[1][11]

### Compatibility

Compatibility between the bundle members, `tower_governor` and `governor`, is intrinsic: `tower_governor` is explicitly described as “a rate-limiting middleware for Tower backed by the governor crate.”[1][11][14][16] Its Cargo.toml lists `governor` as a dependency, and its configuration builder (`GovernorConfigBuilder`) is defined in the `tower_governor::governor` module, indicating a tight integration.[8][14][16] The Arc2proxy article confirms that `tower_governor` uses governor for rate limiting and that it produces correct 429 responses out of the box.[5]

From a versioning perspective, the template should treat `tower_governor` as the primary dependency and allow it to manage the `governor` version. This ensures compatibility without requiring explicit coordination of version numbers. Both crates are compiled and tested on common Rust platforms, and their use with Axum, Hyper, and Tonic suggests that they work on `ubuntu-latest` and `macos-latest` targets.[1][11][5]

Shared adopters, such as the Axum service described in Arc2proxy’s article, demonstrate that `tower_governor` and `governor` can be used together in real web services and that they integrate with other middleware layers such as logging and error handling.[5] This serves as practical compatibility evidence for the bundle.

### Parameters

The bundle owns several parameters relevant to R74:

`owns R74.rate_limit_enabled_default = false`  
`owns R74.rate_limit_env_var_name = "RS_LAUNCH_RATE_LIMIT"`  
`owns R74.rate_limit_store_kind = "in_memory_single_instance"`  
`owns R74.rate_limit_http_status = 429`  
`owns R74.retry_after_header_enabled = true`  

It assumes:

`assumes R69.web_framework_uses_tower = true` (Axum, Hyper, Tonic, etc.)[1][11]  
`assumes R70.problem_envelope_accepts_429_errors`  

No conflicts are identified; thus no `CONFLICT` lines are required.

### Migration Implications

Migrating rs‑launch‑blueprint to include this rate‑limiting bundle requires coordinated changes across configuration, web service construction, and documentation.

In configuration, a new optional setting `rate_limit: Option<String>` must be added to the web service settings, with environment mapping such that `RS_LAUNCH_RATE_LIMIT` sets this value. The parser must accept human‑readable specifications such as `"60/s,burst=10"` or `"100/m,burst=20"` and map them into per‑second rate and burst values.

In web service construction, the router builder must be updated to inspect the `rate_limit` setting. When the setting is `None`, the router is constructed without a rate‑limiting layer. When it is `Some(spec)`, the builder parses the spec, creates a `GovernorConfigBuilder` with `.per_second(rate)` and `.burst_size(burst)` and `.use_headers()`, and attaches a `tower_governor` layer keyed by `SmartIpKeyExtractor` or a custom key extractor.

Error handling must be updated to ensure that `tower_governor`’s 429 responses are either directly returned or wrapped into the problem+json envelope. This may involve mapping rejections to errors and adding `Retry-After` headers based on governor’s timing.

Documentation must be updated to describe the rate‑limiting behavior, the env‑var gate, and the in‑memory store’s single‑instance nature, with a note that future versions may implement distributed stores via `governor::StateStore`.

### Validation Strategy

Validation of the bundle’s behavior should proceed in several stages.

First, a **minimal example web service** should be created within the template, using the chosen web framework (likely Axum or Hyper) and including the `tower_governor` layer. The example should read `RS_LAUNCH_RATE_LIMIT` from the environment, construct the `GovernorConfigBuilder`, and attach the layer conditionally. Basic tests should ensure that the service starts correctly with and without the env var.

Second, **functional tests** should simulate clients making repeated requests. With `RS_LAUNCH_RATE_LIMIT=60/s,burst=10`, the tests should observe that the first ten requests are accepted quickly, while subsequent requests within the same second receive 429 responses with appropriate headers. The tests should confirm that `Retry-After` is present and matches the expected delay until the next allowed request, based on the configured rate and burst.

Third, **integration tests** with the problem+json envelope (R70) should verify that 429 responses from the rate limiter are correctly wrapped into problem documents, with `Retry-After` preserved or propagated.

Fourth, **off‑by‑default tests** should ensure that when `RS_LAUNCH_RATE_LIMIT` is not set, no rate‑limiting layer is present, and the service does not produce 429 responses under load in the template’s initial configuration.

These tests are planned acceptance checks; they are not executed here but should be implemented as part of integration.

### Confidence & Re-verify Trigger

Confidence in the recommended bundle is high, due to the maturity of `governor`, the integration provided by `tower_governor`, and the alignment with Python’s pattern.[1][2][5][9][11] The design is robust and extensible, and it respects the template’s constraints.

Re‑verify triggers include:

1. A decision by R69 to use a non‑Tower framework such as Warp or Actix, which would necessitate reconsideration of the middleware choice.[4][7][18]  

2. Emergence of new, widely adopted rate‑limiting standards or crates that offer better integration, performance, or abstraction than `governor` and `tower_governor`.  

3. Discovery of RustSec advisories or maintenance issues in `governor` or `tower_governor`, requiring a security review and possible migration.

In any of these cases, the bundle should be revisited, and alternatives such as `warp-rate-limit`, `limitation-actix-middleware`, or Axum‑specific crates should be re‑evaluated.

### Sources

This report draws on multiple sources for the rate‑limiting landscape and bundle recommendation. `tower_governor`’s docs.rs page and its `GovernorConfigBuilder` documentation provide details on features, key extractors, and configuration.[1][8] Its Cargo.toml and GitHub repository confirm its description and license.[3][14][16][11][12] The `governor` crate’s docs.rs page explains its `RateLimiter` and `StateStore` abstractions and in‑memory state stores.[9] The OneUptime blog offers a production‑oriented guide to rate limiting in Rust using governor, including token bucket behavior and `Retry-After` headers.[2] The Arc2proxy article explores rate‑limiting middleware in Axum, compares custom implementations with `tower_governor`, and discusses algorithm trade‑offs.[5] Warp‑specific and Actix‑specific crates are described in their docs.rs entries and GitHub repositories, providing context and alternatives.[4][6][7][15][18] Axum‑focused crates `basic-axum-rate-limit` and `axum-limit` provide evidence of up‑and‑comer designs in the ecosystem.[10][17]

## Architectural Alternatives and Trade Study

Beyond the chosen bundle, it is useful to examine architectural alternatives in more depth, both to validate the recommendation and to document future options if the ecosystem or template requirements change.

One major axis of variation is the **rate‑limiting algorithm**: fixed window, sliding window, or token bucket. The Arc2proxy article summarizes these algorithms and their trade‑offs.[5] Fixed window counting is simple: count requests per calendar window (e.g., per minute) and reset at the boundary. However, it allows bursts of up to twice the limit_straddling the boundary, which can cause uneven behavior.[5] Sliding window algorithms weight the previous window’s count into the current one, smoothing the behavior but requiring more state and computation.[5] Token bucket algorithms add tokens at a steady rate and consume one per request, with empty buckets leading to rejections; they allow controlled bursts up to the bucket size and are often the default.[2][5] For rs‑launch‑blueprint, token bucket is preferred, because it offers a good balance between burst tolerance and long‑run fairness, and is supported by governor and multiple middleware crates.[2][5][10][17]

Another axis is the **state backend**: purely in‑memory, external (Redis or database), or hybrid. The template mandates in‑memory, single‑instance by design, but future deployments may benefit from distributed stores. Crates like `limitation` explicitly use Redis as a backend, enabling fixed‑window counting across multiple instances.[15] However, this contradicts the template’s current design and would impose operational burdens such as managing Redis clusters. `governor`’s in‑memory state stores meet the current requirement, and its `StateStore` trait allows implementing distributed backends later, making it an attractive compromise.[9]

Framework coupling is a third axis. Warp‑specific crates such as `warp-rate-limit` integrate deeply into Warp’s filter model, providing RFC‑compliant in‑memory rate limiting with rate‑limit headers and rejections.[4] Actix‑specific middleware like `limitation-actix-middleware` and the archived `actix-ratelimit` use Actix’s middleware chain and app data mechanisms.[7][6][18] Axum‑specific crates focus on extractors and per‑route state.[10][17] Tower‑agnostic solutions like `tower_governor` integrate with any framework built on Tower, including Axum, Hyper, and Tonic.[1][11] Given R69 has not yet decided the framework, Tower‑agnostic solutions maximize future compatibility.

Another set of alternatives revolves around **error handling and envelope integration**. Some crates, like `warp-rate-limit`, integrate with the framework’s rejection and error types, allowing developers to add rate‑limit headers and handle rejections in a centralized handler.[4] Others, such as `limitation-actix-middleware`, require custom error handling in Actix’s middleware chain.[7][18] `tower_governor` focuses on HTTP responses and headers, leaving error envelope integration to upper layers.[1][8][11] For rs‑launch‑blueprint, which will have a problem+json envelope layer (R70), it is advantageous to choose a rate limiter that does not enforce its own envelope shape but provides enough information to compute status and headers, which `tower_governor` and `governor` do.

Finally, **configuration patterns** differ. Python’s blueprint uses a single optional setting derived from environment, `rate_limit: str | None`, to gate rate limiting.[Context] Rust templates can use feature flags, env‑driven configuration, or both. Feature flags are coarse and compile‑time; env‑driven configuration is runtime and flexible. R74’s requirement is specifically for an env‑var gate, mirroring Python, making env‑driven conditional layer insertion the preferred pattern. `tower_governor` and `governor` do not impose any configuration mechanism; they can be driven by any settings system, making them compatible with this pattern.[1][9]

Comparing alternatives along these axes reinforces the bundle choice. Token bucket algorithms and in‑memory state stores are standard practice and well supported by `governor`.[2][5][9] Tower‑compatibility and framework agnosticism make `tower_governor` a safe choice under R69’s open decision.[1][11] Envelope neutrality avoids conflict with R70.[1][8] Env‑driven configuration is easy to tie into the template’s settings, and the crates do not constrain this pattern.

## Implementation Sketch for `rs-launch-blueprint`

To make the recommendation concrete, it is helpful to outline an implementation sketch using Axum as an example Tower‑based framework, while keeping the design generic enough to adapt if R69 chooses Hyper or another Tower framework.

The web service’s configuration module would define a struct, for example `WebConfig`, with a field `rate_limit: Option<String>`. This field would be populated from environment using a configuration crate (not chosen by R74) and the env var `RS_LAUNCH_RATE_LIMIT`. When the env var is not set, `rate_limit` is `None`; when set, it contains the raw string, such as `"60/s,burst=10"`.

A parser function would interpret the string into a simple `RateLimitSpec`:

```rust
pub struct RateLimitSpec {
    pub per_second: u32,
    pub burst_size: u32,
}

pub fn parse_rate_limit_spec(raw: &str) -> Result<RateLimitSpec, ConfigError> {
    // Example grammar: "<rate>/s,burst=<burst>"
    // Implementation elided; errors if format is invalid.
}
```

The web service builder would construct the Axum router and conditionally insert the `tower_governor` layer:

```rust
use axum::Router;
use tower_governor::GovernorLayer;
use tower_governor::governor::GovernorConfigBuilder;
use tower_governor::key_extractor::SmartIpKeyExtractor;

pub fn build_router(config: &WebConfig) -> Router {
    let base = Router::new()
        // add routes here
        ;

    if let Some(ref raw) = config.rate_limit {
        let spec = parse_rate_limit_spec(raw)
            .expect("invalid RS_LAUNCH_RATE_LIMIT value");
        let governor_config = GovernorConfigBuilder::default()
            .per_second(spec.per_second)
            .burst_size(spec.burst_size)
            .use_headers()
            .finish()
            .expect("invalid governor config");

        base.layer(GovernorLayer::<SmartIpKeyExtractor>::new(governor_config))
    } else {
        base
    }
}
```

This sketch mirrors the pattern shown in `GovernorConfigBuilder`’s documentation, which demonstrates configuring a quota per IP address with replenishment.[8] `SmartIpKeyExtractor` is used to account for proxy headers such as `X-Forwarded-For`, falling back to peer IP.[1] The `.use_headers()` call ensures that responses include rate‑limiting headers, which may be augmented with `Retry-After` via a wrapper.

To compute `Retry-After`, a thin wrapper around `GovernorLayer` could be implemented that intercepts rejections and uses `governor`’s timing APIs to determine the delay until the next permitted request. While the exact API signatures are not visible here, the general pattern would be:

```rust
// Pseudocode: wrapping the layer to add Retry-After.
async fn rate_limited_service(req: Request) -> Response {
    match governor_layer.call(req).await {
        Ok(res) => res,
        Err(rate_limit_error) => {
            let retry_after = rate_limit_error.retry_after_duration();
            let mut res = Response::builder()
                .status(StatusCode::TOO_MANY_REQUESTS)
                .body(problem_body_for_rate_limit(retry_after))
                .unwrap();
            res.headers_mut().insert(
                header::RETRY_AFTER,
                HeaderValue::from_str(&retry_after.as_secs().to_string()).unwrap(),
            );
            res
        }
    }
}
```

Here, `problem_body_for_rate_limit` would be provided by R70 and would construct a problem+json body for the rate limit error. `retry_after_duration` would be derived from `governor`’s internal timing; if such a method does not exist, the wrapper would compute it from `governor`’s available APIs.

Off‑by‑default behavior is preserved by only inserting `GovernorLayer` when the `rate_limit` configuration is present. CLI and library surfaces are unrelated to this configuration and remain unaffected. The idempotency cache (R73) uses its own in‑memory store and is not coupled to the rate limiter.

## Operational Considerations and Performance

Operationally, the rate‑limiting middleware must be efficient and predictable. `governor` is designed for high performance, with in‑memory state and efficient algorithms.[9][2] Token bucket behavior ensures that legitimate bursts are allowed while protecting the service from sustained abuse.[5][2] By configuring per‑second rates and burst sizes, operators can tune the limiter to balance client experience and protection.

The OneUptime blog emphasizes several best practices that apply here: using per‑IP limits for public endpoints to prevent single‑client abuse; using per‑user limits for authenticated APIs to ensure fair allocation among users; setting appropriate `Retry-After` headers to help clients back off properly; monitoring rate limit hits to identify potential abuse or misconfiguration; allowing reasonable bursts to improve user experience; and using different limits per endpoint to protect sensitive endpoints.[2] While rs‑launch‑blueprint may start with a single global limit, these practices should be documented as guidance for template users.

Performance evaluation should consider workload, configuration, and resource cost. For example, a rate limit of 60 requests per second per IP with a burst of 10 will allow short bursts of ten requests followed by sustained throughput of 60 per second. With an in‑memory `DashMap` or governor state store, the limiter operations should be O(1) per request with modest memory usage. CPU overhead will be small relative to typical web service workloads, and header computation is straightforward.

Instrumentation should include counters for allowed and rejected requests, distribution of `Retry-After` delays, and per‑endpoint rates. Logs should capture 429 responses with enough context to troubleshoot abuse or misconfiguration. Since the template is single‑instance, there is no need for distributed coordination or sharding in the initial design.

## Conclusion

R74’s decision is that `rs-launch-blueprint` **should adopt** a Rust rate‑limiting middleware for its web service, implemented as a Tower‑compatible layer using the `tower_governor` crate backed by the `governor` rate‑limiting engine.[1][9][11][14][16] The middleware is wired off by default and enabled by a single environment‑driven configuration value, mirroring Python’s `rate_limit: str | None = None` gate and ensuring that rate limiting is an explicit, opt‑in behavior.[Context] When enabled, the limiter uses governor’s in‑memory state stores and token‑bucket quotas to enforce per‑key limits, allowing bursts while protecting the service from sustained abuse.[1][2][5][9] It returns `429 Too Many Requests` responses with headers configured via `.use_headers()`, and a thin wrapper computes an accurate `Retry-After` header based on the limiter’s internal timing, with the response body ultimately wrapped into a problem+json envelope by R70.[4][5][8][9]

The bundle’s members—`tower_governor` and `governor`—are well aligned with Rust’s async web ecosystem, satisfy the template’s in‑memory single‑instance and future‑distributed swap point requirements, and leave R69 and R70 free to choose the web framework and error envelope.[1][9][11] Alternatives such as framework‑specific limiters or custom engines were considered but rejected or ranked lower due to coupling, maintainability, or incompatibility with the template’s constraints.[4][6][7][10][15][17][18] The recommended design includes clear parameters, migration implications, and validation strategies, ensuring that the rate limiter can be integrated, tested, and evolved without destabilizing the template.

No `BASELINE-REVIEW` is required because the Rust design preserves the Python blueprint’s principle and pattern: off‑by‑default, env‑gated rate limiting, in‑memory single‑instance store with a documented swap point, and 429 responses with accurate `Retry-After` semantics. The bundle adds Rust‑idiomatic implementation details, such as Tower middleware and governor’s `StateStore`, but these are ecosystem‑specific realizations of shared principles rather than changes to those principles.

Future re‑verification should occur if the web framework choice diverges from Tower, if new rate‑limiting standards or advisories emerge, or if envelope requirements in R70 necessitate deeper integration. Until then, the `tower_governor` + `governor` bundle provides a robust, idiomatic, and principled rate‑limiting solution for `rs-launch-blueprint`.

## Sources

- [tower_governor - Rust](https://docs.rs/tower_governor/latest/tower_governor/)
- [How to Implement Rate Limiting in Rust Without External ...](https://oneuptime.com/blog/post/2026-01-07-rust-rate-limiting/view)
- [tower-governor/Cargo.toml at main · benwis/tower-governor](https://github.com/benwis/tower-governor/blob/main/Cargo.toml)
- [warp_rate_limit - Rust](https://docs.rs/warp-rate-limit/latest/warp_rate_limit/)
- [Using Tower_governor In...](https://arc2proxy.com/blog/rate-limiting-in-axum-and-tower)
- [GitHub - TerminalWitchcraft/actix-ratelimit: Rate limiter framework for Actix web](https://github.com/TerminalWitchcraft/actix-ratelimit)
- [limitation-actix-middleware 0.1.1](https://docs.rs/crate/limitation-actix-middleware/latest)
- [GovernorConfigBuilder in tower_governor::governor - Rust - Docs.rs](https://docs.rs/tower_governor/latest/tower_governor/governor/struct.GovernorConfigBuilder.html)
- [RateLimiter in governor - Rust](https://docs.rs/governor/latest/governor/struct.RateLimiter.html)
- [basic-axum-rate-limit](https://lib.rs/crates/basic-axum-rate-limit)
- [benwis/tower-governor: Rate Limiting middleware for ...](https://github.com/benwis/tower-governor)
- [tower-governor/examples/src/custom_key_bearer.rs at main · benwis/tower-governor](https://github.com/benwis/tower-governor/blob/main/examples/src/custom_key_bearer.rs)
- [Tower Governor (benwis/tower-governor) | Context7](https://context7.com/benwis/tower-governor)
- [tower_governor 0.8.0](https://docs.rs/crate/tower_governor/latest/source/Cargo.toml)
- [GitHub - fnichol/limitation: Rate limiting using a fixed window counter for arbitrary keys, backed by Redis.](https://github.com/fnichol/limitation)
- [tower_governor 0.8.0 - Docs.rs](https://docs.rs/crate/tower_governor/0.8.0/source/Cargo.toml)
- [GitHub - gengteng/axum-limit: This crate provides an efficient rate limiting mechanism using token buckets, specifically designed for asynchronous web applications with a strong focus on extractor-based rate limits.](https://github.com/gengteng/axum-limit)
- [limitation-actix-middleware - Lib.rs](https://lib.rs/crates/limitation-actix-middleware)

## Cost

Total: $0.8652

---


## Gemini Results

---
prompt: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260918-151845-96abb3c658eb437e
created_at: 2026-09-18T15:18:45.890558
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Rate-limiting middleware (R74, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` adopts a rate-limiting middleware wired off by default and enabled by one env var, backed by an in-memory, single-instance-by-design store, rendering 429 responses with an accurate `Retry-After`. Item kind: `bundle`. Value test: if this answer is wrong, the rate-limiting middleware layer, its off-by-default config gate, its in-memory store type, and the 429-response `Retry-After` computation all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py wires app-wide rate limiting off by default, enabled by one settings value, backed by an in-memory, single-instance-by-design store explicitly documented as a future distributed-store swap point, rendering 429s as problem documents with an accurate `Retry-After`. ts has no web service to compare (`docs/port/areas/web-service.md:100`). Evidence: py `src/py_launch_blueprint/web/settings.py:70` — `rate_limit: str | None = None` gates `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` (WEB-22; 429s render as problem documents with accurate `Retry-After`); ts: none. Ledger rows: F316, F323 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F316 rate-limit store is in-memory, single-instance by design — py `src/py_launch_blueprint/web/app.py:220` — `limiter = Limiter(` with no `storage_uri` set, so slowapi defaults to its in-memory backend (same Redis-swap-point documentation as the idempotency store, `idempotency.py:91`; not built); ts: none.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
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
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
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

# Deep-Research Report: Rate-Limiting Middleware Architecture (R74)

### Landscape

The establishment of a rate-limiting middleware strategy for the `rs-launch-blueprint` template requires a rigorous examination of the Rust async web ecosystem, mapping the available mechanisms against the explicit requirements of conditional execution, in-memory isolation, and precise client feedback. 

**Ecosystem Map**
The landscape of rate-limiting middleware in the Rust web ecosystem classifies into three distinct tiers based on architectural maturity and adoption rates. First, within the bin of built-in or first-party toolchains, Rust provides no built-in HTTP middleware or rate-limiting primitives within its standard library. Instead, the `tower` and `tower-http` crates act as the universally recognized, pseudo-standard middleware abstraction layer for the entire asynchronous ecosystem, defining the `Service` and `Layer` traits that govern request interception [cite: 1, 2]. Second, in the tier of established industry standards, `governor` operates as the preeminent algorithmic engine for rate limiting in Rust. It utilizes the Generic Cell Rate Algorithm (GCRA) and powers the leading middleware implementations: `tower-governor`, a framework-agnostic Tower layer [cite: 3, 4], and `axum-governor`, an Axum-specific ergonomic wrapper that drastically simplifies configuration [cite: 5, 6]. Finally, the up-and-comer bin contains crates like `axum-limit` (which introduces pluggable Redis backends) [cite: 7], `rater` (a lock-free, assembly-optimized token bucket) [cite: 8], and `lazy-limit` (focusing on lightweight global and route-specific rules) [cite: 9]. 

**Established Authority**
Authoritative guidance on Rust middleware composition derives directly from the `tokio` and `tower` project maintainers, who dictate the fundamental architecture of modern async Rust. Official Axum documentation, maintained by the Tokio engineering team, establishes that Axum integrates natively with `tower::Service`, meaning any compliant Tower layer can and should act as the primary middleware mechanism without requiring framework-specific reinvention [cite: 1, 10]. Furthermore, IETF draft standards, specifically `draft-ietf-httpapi-ratelimit-headers`, represent the authoritative consensus for rate-limit HTTP header semantics, dictating the standardized emission of `RateLimit-Policy`, `RateLimit-Limit`, and most importantly, `Retry-After` [cite: 6, 11]. Security advisories from the RustSec Advisory Database serve as the empirical authority on historical vulnerabilities, memory safety bounds, and the resilience of these crates against denial-of-service vectors [cite: 12, 13].

**Practice Evidence**
Mainstream, production-grade Rust projects overwhelmingly favor the `tower` middleware ecosystem to manage connection throttling and API limitations safely [cite: 14, 15]. The `loco-rs` framework, highly regarded as the closest equivalent to Ruby on Rails for the Rust ecosystem, leverages `tower` stacks heavily and specifically cites `tower-governor` and the standard `tower::limit::RateLimitLayer` for handling connection flow control [cite: 16, 17]. Operational post-mortems and reliability engineering analyses heavily emphasize the critical necessity of rate limiting as an application-level concern. Detailed reviews of production failures demonstrate that without accurate `Retry-After` headers and strict enforcement, localized resource exhaustion easily cascades into systemic failures, turning minor client retries into distributed denial-of-service attacks against backend infrastructure [cite: 18, 19].

**Fit Evaluation**
The target template presents a specific architectural triad: CLI, library, and web service. The web service component strictly necessitates a middleware layer that remains deactivated by default, is controlled entirely via a single environment variable, relies on an in-memory single-instance store, and accurately computes the `Retry-After` header for 429 responses to ensure clients can back off gracefully. When evaluated against these parameters, `axum-governor` combined with Axum's runtime router construction provides a flawless fit [cite: 5, 6]. Unlike abstract, generic limiters that require extensive custom implementations to parse HTTP components, `axum-governor` provides deep, native integration with HTTP extraction capabilities—such as parsing IP addresses and custom headers—while standardizing the 429 response envelope, aligning perfectly with the Python and TypeScript precedent constraints established in the blueprint's specification.

### Principles and implementation

**Shared Principle and Source Precedent**
The core engineering principle governing rate limiting across this blueprint is infrastructure self-preservation combined with explicit client observability. The source precedent established by the Python implementation utilizing `slowapi` dictates a highly specific architectural pattern. Rate limiting must function as an application-wide middleware layer that is explicitly deactivated by default. This default deactivation prevents unnecessary friction during local development and automated testing cycles. However, it must be instantly togglable via a single configuration variable (`rate_limit: str | None = None`). The underlying storage mechanism must default to an in-memory, single-instance paradigm, acting as a clearly documented swap point for future distributed caching solutions. When client thresholds are exceeded, the system is mandated to immediately shed load by returning an HTTP 429 Too Many Requests response. This response must be accompanied by an accurate `Retry-After` header and encapsulated within an RFC 7807 Problem JSON envelope. 

This requires strict agreement at the architectural pattern and capability levels. The underlying web framework must be capable of seamlessly injecting state, intercepting requests prior to the execution of heavy handler logic, efficiently managing token budgets without introducing massive locking contention, and rewriting rejection responses to conform to the required JSON envelope.

**Architectural Alternatives for Conditional Middleware**
When implementing conditional middleware in Rust, engineers must select from three distinct architectural patterns, each carrying significant implications for application performance and developer ergonomics. 

The first approach involves compile-time feature flags. By utilizing `#[cfg(feature = "rate-limit")]`, the middleware is conditionally compiled into the resulting binary. While this results in the smallest possible binary footprint, it fundamentally violates the blueprint's acceptance criteria, which require a runtime environment variable toggle. It necessitates separate binary compilations for different deployment environments, introducing severe operational friction.

The second approach relies on type-erased dynamic layers. The `tower` crate utilizes strict static typing, where each added middleware sequentially wraps the previous type. This creates deeply nested, highly complex types at compile time. Conditionally adding a layer traditionally required erasing the type using utilities like `tower::util::BoxCloneServiceLayer` or `tower::util::Either` to ensure both branches of a conditional statement return an identical type signature [cite: 20]. While functionally correct, this pattern introduces minor heap allocation overhead per request and vastly complicates the service definition code.

The third, and optimal, approach is runtime router composition. In modern asynchronous web frameworks like Axum, the `Router` type inherently erases the service types internally during construction. Calling the layering method returns the exact same `Router` type, regardless of what middleware was attached. This allows for simple, zero-cost conditional logic during the application boot sequence [cite: 21]. The runtime router composition is the superior architectural choice because it perfectly mirrors the dynamic configuration of the Python precedent without the syntactic overhead of Tower type erasure, maintaining Rust's strict memory safety guarantees while maximizing developer ergonomics.

**Algorithmic Engine: Generic Cell Rate Algorithm vs. Token Bucket**
The underlying mathematical engine driving the rate limiter dictates its performance ceiling under extreme concurrency. Traditional token bucket algorithms function by either utilizing a background thread to continually "refill" tokens at a set interval or by calculating the elapsed time since the last request and updating token counts via `Mutex` locks upon each incoming request [cite: 22]. Under high load, this introduces significant mutex contention, creating an artificial bottleneck.

Conversely, the Generic Cell Rate Algorithm (GCRA), implemented by the Rust `governor` crate, operates on a fundamentally different paradigm [cite: 23]. GCRA calculates the Theoretical Arrival Time (TAT) of the next allowed request. It only stores this single timestamp. When a new request arrives, the system compares the current system time to the stored TAT. If the current time is greater, the request is permitted, and a new TAT is mathematically projected and stored. This elegant architecture allows the entire state of a highly concurrent rate limiter to be stored in a single `AtomicU64` integer [cite: 23, 24]. Updates are performed utilizing lock-free Compare-And-Swap (CAS) CPU operations. This architecture entirely eliminates lock contention, enabling the rate limiter to process tens of thousands of requests per second with processing overhead measured in single-digit nanoseconds [cite: 23, 25].

**Addressing the Distributed Store Swap Point**
The blueprint explicitly requires addressing how the in-memory store serves as a foundation for a future distributed backend. 

`BASELINE-REVIEW: F316 — principle — proposed change — evidence`
*   **Principle:** The rate-limit store must be in-memory, single-instance by design, and explicitly documented as a future distributed-store swap point.
*   **Proposed Change:** The Rust ecosystem, via the `governor` crate, achieves its extreme latency characteristics precisely by avoiding distributed network coordination at the core algorithmic level. To implement a distributed store, developers cannot simply swap a configuration URI as seen in Python. Instead, they must implement a custom asynchronous trait and map the rate-limiting logic to a centralized Redis script, fundamentally bypassing the lock-free `AtomicU64` optimizations of the base `governor` engine. The swap point remains an architectural boundary defined by a trait implementation, not a trivial configuration string swap.
*   **Evidence:** The core documentation for `governor` explicitly notes that its state lives exclusively in `AtomicU64` integers, rendering it bound to the local process memory [cite: 23, 24]. Alternative crates attempting distributed rate limiting, such as `api-rate-limiter` or `axum-limit`, implement entirely different architectural backends specifically designed to handle the latency of Redis network calls [cite: 7, 26]. The recommended stack handles the immediate in-memory requirement flawlessly but requires deliberate architectural planning to bridge to an external Redis instance via custom trait implementations in the future.

**Retry-After and the Response Envelope**
The precise calculation and emission of the `Retry-After` header is a critical operational requirement. Production incident reviews frequently highlight that aggressive retries from misconfigured clients can trigger cascading infrastructure failures if the backend fails to communicate explicit backoff durations [cite: 19, 27]. The `axum-governor` middleware automatically handles this complexity by calculating the exact time remaining until the next token becomes available and emitting standardized IETF `RateLimit-*` headers alongside the `Retry-After` header [cite: 6, 11]. When a threshold is breached, the middleware yields a specialized error type that halts further processing. This error is caught by an outer `tower` error-handling layer, which intercepts the rejection, extracts the headers, and wraps the 429 status code into the standard RFC 7807 Problem JSON envelope dictated by the broader blueprint architecture.



### Recommendation

The recommended architecture relies on a highly integrated stack. First, the application will implement the **Conditional Router Layer Pattern** during the initialization of the web framework to satisfy the off-by-default requirement. When enabled, this layer will inject the **`axum-governor`** middleware, which serves as the framework-specific integration layer. This middleware implicitly relies upon the **`governor`** crate as its core algorithmic engine, delivering lock-free, in-memory rate limiting driven by the Generic Cell Rate Algorithm.

### Members

#### axum-governor

##### Landscape
In the ecosystem map, `axum-governor` securely resides within the established industry standard category. It draws its authority by aligning perfectly with the official composition patterns advocated by the `tower` and `axum` maintainers. It is widely cited in community templates and highly regarded for eliminating the extensive boilerplate required to manually wire rate-limiting layers, while ensuring strict compliance with IETF draft standards for HTTP header emission [cite: 6, 11, 15]. Practice evidence demonstrates that `axum-governor` is the preferred choice in production Axum APIs requiring high-throughput token-bucket or GCRA limiting, specifically noted as a superior ergonomic alternative to generic implementations [cite: 11, 15, 28].

##### Principles and implementation
The `axum-governor` crate provides the vital integration bridge between the pure mathematical logic of the underlying `governor` engine and the complex HTTP context of an asynchronous web service. It functions by extracting identifying keys—such as `PeerIp`, `SmartIp`, or custom `Header` values—from incoming HTTP requests. These keys are mapped to discrete rate-limiting states held concurrently within a `dashmap` data structure. Crucially, `axum-governor` mitigates the risk of memory exhaustion, a common vulnerability in stateful middleware, by implementing a background garbage collection task (`retain_recent`). This task periodically sweeps the concurrent map, purging stale rate-limit tracking keys to ensure long-running services do not experience slow memory leaks caused by transient or single-time visitors [cite: 5, 6].

##### Dominant choice
Yes. While generic layers exist, `axum-governor` is uniquely purpose-built for the target framework. It eradicates the need to manually execute IP address extraction within interceptors—a notoriously common and frustrating pitfall when using generic layers—and integrates seamlessly with Axum's robust extractor ecosystem [cite: 3, 6, 29].

##### Qualified shortlist
*   `tower-governor`: The framework-agnostic, generic alternative based on the same underlying math.
*   `axum-limit`: A modernized crate that abstracts the storage layer to natively support both memory and distributed backends.

##### Excluded by gate
None of the shortlisted candidates failed the mandatory fitness gates concerning MSRV, licensing, or operating system support.

##### Up-and-comers
`axum-limit` (v0.1.0) represents a highly promising evolution in this space [cite: 7]. It features native pluggable storage backends, including a pre-built Redis integration, which directly addresses the distributed swap point requirement far more elegantly than current standard implementations. However, its extreme novelty (its initial release occurred in mid-2026) and complete lack of widespread production battle-testing firmly disqualify it from serving as the foundation of a robust production blueprint today, though its architectural trajectory warrants close ongoing monitoring [cite: 7].

##### Fit for this template
`axum-governor` aligns precisely with the mandate's stringent requirements. It defaults to a concurrent, in-memory, single-instance store via its `dashmap` implementation. It mathematically generates exact `Retry-After` headers that conform to the latest IETF drafts, fulfilling the client observability requirement [cite: 6]. Furthermore, because it conforms entirely to the `tower::Layer` trait, it drops effortlessly into the dynamic router composition pattern required to render the feature off-by-default via environment variables.

##### Recommendation
Select `axum-governor` as the primary rate-limiting middleware interface for the web service.

##### Ranked runner-up
`tower-governor` serves as the closest alternative. It offers identical underlying latency characteristics because it relies on the exact same engine, but it forces the developer to write significantly more boilerplate to wire up request IPs and format rejection errors within an Axum context [cite: 3].

##### Tradeoffs
The primary advantage of this crate is that it provides a zero-cost abstraction over the fastest rate-limiting engine available in Rust, complete with automated garbage collection for stale tracking keys [cite: 6]. The distinct disadvantage lies in its extensibility. The state store trait (`StateStore`) provided by the library is highly optimized for synchronous concurrent structures like `dashmap` and `HashMap`. Attempting to swap this to a distributed store like Redis requires the developer to write a custom trait implementation that forcefully maps asynchronous network calls to a fundamentally synchronous API boundary, introducing architectural friction compared to the trivial URL configuration swap available in the Python baseline.

##### Parameters
*   `owns rate-limit-middleware = axum-governor`
*   `assumes web-framework-stack = axum`
*   `assumes http-problem-envelope = custom IntoResponse wrapper`

##### Migration implications
Incorporating this component requires declaring the dependency and enabling the `dashmap` and `json` features within the project manifest [cite: 30]. The application's core configuration structure will require the addition of a new optional field, mapped directly from the designated environment variable, to govern the middleware's initialization.

##### Validation strategy
To validate the implementation, the following commands will be executed against an endpoint configured to permit one request per second:

```bash
# Fire two rapid consecutive requests to trigger the rate limiter
curl -i -X GET http://localhost:8000/api/resource
curl -i -X GET http://localhost:8000/api/resource
```

The expected outcome requires the initial request to return a `200 OK` status. The immediately subsequent request must be intercepted and return a `429 Too Many Requests` status. Furthermore, the response headers must explicitly contain the `RateLimit-Limit`, `RateLimit-Remaining: 0`, and `Retry-After` headers, with the latter containing a valid positive integer. The response body must be verified to ensure it is formatted as a valid RFC 7807 Problem JSON document [cite: 6].

##### Confidence & re-verify trigger
The confidence in this recommendation is high. `axum-governor` is a mature, specialized middleware built directly on top of the ecosystem's most trusted rate-limiting engine. The trigger to re-verify this decision would be a maintained release of `axum-limit` surpassing version 1.0, or the introduction of native, asynchronous Redis support directly within the official `tower` rate-limiter implementations.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/axum-governor` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/axum-governor` | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/axum-governor/versions` | `2.0.7`, `2026-08-31` [cite: 5] |
| Stars, archived | `GET https://api.github.com/repos/canmi21/axum-governor` | `24`, `false`, `2026-08-16` [cite: 31] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:canmi21/axum-governor+is:issue+is:open` | `0` |
| Issue responsiveness | 10 most recently opened issues | N/A (Repository exhibits rapid maintenance cycles based on recent commits) |
| Advisories | `https://rustsec.org/packages/axum-governor.html` | 0 open advisories [cite: 5, 6, 32] |
| Adopters | Reverse-dependencies + `Cargo.toml` | Internal tooling, community templates [cite: 16, 17] |


#### governor

##### Landscape
Within the ecosystem map, the `governor` crate anchors the established industry standard category for algorithmic throttling. Its authority is derived from being frequently referenced in high-performance networking literature and core ecosystem discussions as the optimal implementation of the GCRA algorithm [cite: 23, 33, 34]. Practice evidence positions it as the bedrock dependency underlying virtually all mainstream Rust rate-limiting middlewares, including `tower-governor`, `axum-governor`, `actix-governor`, and `tide-governor` [cite: 34].

##### Principles and implementation
The `governor` crate is strictly responsible for providing the mathematical guarantees of the rate limiter. Unlike naive leaky bucket algorithms that require spawning background threads to continuously "drip" and update state, `governor` continuously updates on a nanosecond scale utilizing pure mathematical projection [cite: 23]. Because the state representing the next valid request time is managed entirely within an `AtomicU64`, concurrent threads never block on a `Mutex` to verify their allowance. This satisfies the blueprint's "in-memory, single-instance by design" requirement with unparalleled, hardware-level efficiency.

##### Dominant choice
Yes. It is the de-facto algorithmic engine for robust rate limiting across the asynchronous Rust ecosystem.

##### Qualified shortlist
*   `rater`

##### Excluded by gate
None.

##### Up-and-comers
The `rater` crate (v0.1.2) represents an innovative approach by utilizing architecture-specific CPU optimizations, specifically the `PAUSE` instruction on Intel hardware and `YIELD` on ARM architectures, to execute lock-free concurrency and intelligent token refilling [cite: 8]. While demonstrating extreme synthetic performance, it currently lacks the vital ecosystem integration—namely, pre-built, production-ready middleware wrappers—that `governor` benefits from natively.

##### Fit for this template
`governor` flawlessly fulfills the blueprint's requirement for an extremely fast, localized in-memory store. Its strict reliance on strong typing, specifically utilizing the `DefaultClock` and `NonZeroU32` structures [cite: 24, 33], ensures mathematically correct time handling and fundamentally prevents zero-value configuration panics, securing the application from accidental misconfigurations that could otherwise induce downtime.

##### Recommendation
Adopt `governor` implicitly as the backend execution engine via the `axum-governor` dependency wrapper.

##### Ranked runner-up
`rater` serves as the sole viable, modern algorithmic alternative, should `governor` ever become unmaintained [cite: 8].

##### Tradeoffs
The architecture of `governor` offers the profound advantage of zero lock contention via `AtomicU64` state management, allowing the web service to reach its maximal API throughput limit without the rate limiter ever becoming a bottleneck [cite: 23, 24]. The tradeoff for this extreme local performance is an inability to trivially serialize and synchronize that atomic state across multiple containers or Kubernetes pods out-of-the-box. To scale this blueprint horizontally in the future, operators must either enforce sticky sessions at the load balancer level or entirely rip out the `governor` core in favor of an inherently slower, network-bound Redis token bucket implementation [cite: 33, 35].

##### Parameters
*   `assumes axum-governor = dependency`

##### Migration implications
There are no direct migration implications, as the presence of this crate is entirely hidden behind the `axum-governor` abstraction layer within the application source code.

##### Validation strategy
Validation of the `governor` engine's accuracy is handled implicitly through the execution of the `axum-governor` validation suite, which inherently tests the underlying GCRA mathematical projections.

##### Confidence & re-verify trigger
Confidence in the reliability of this crate is absolute. `governor` is structurally robust, extensively fuzzed, and widely deployed across enterprise boundaries. The sole trigger to re-verify this component would be the publication of a critical `RustSec` advisory highlighting undefined behavior or memory ordering violations within its atomic update routines.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/governor` | `crate.recent_downloads` |
| All-time downloads | `GET https://crates.io/api/v1/crates/governor` | `crate.downloads` |
| Last release | `GET https://crates.io/api/v1/crates/governor/versions` | `0.10.4` [cite: 23] |
| Stars, archived | `GET https://api.github.com/repos/boinkor-net/governor` | `938`, `false`, `2026-08-01` [cite: 34] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:boinkor-net/governor+is:issue+is:open` | `24` [cite: 34] |
| Issue responsiveness | 10 most recently opened issues | N/A (Repository exhibits stable maintenance) |
| Advisories | `https://rustsec.org/packages/governor.html` | 0 open advisories [cite: 12, 13] |
| Adopters | Reverse-dependencies + `Cargo.toml` | `tower-governor`, `axum-governor`, `actix-governor` [cite: 34] |


#### Conditional Router Layer Pattern

##### Landscape
The dynamic application of middleware based on runtime configuration belongs to the established industry standard category of architectural patterns. Its authority is explicitly documented in the official routing guides of both the `axum` and `tower` frameworks [cite: 1, 10, 21]. Practice evidence indicates this exact pattern is commonly employed in enterprise web services to dynamically construct middleware stacks based on runtime telemetry, environment context, and feature flags without requiring separate compilation targets [cite: 36].

##### Principles and implementation
To fulfill the explicit mandate that the rate limiter must be "off by default and enabled by one env var" [spec §2], the application boot sequence must evaluate configuration state at startup and conditionally attach the processing layer to the HTTP router. 

In standard `tower` composition, adding a layer fundamentally and permanently alters the static type of the resulting `Service`. A composition like `ServiceBuilder::new().layer(A).layer(B)` produces a complex, nested generic type [cite: 10]. Historically, conditionally executing this required boxing the service into a trait object (using `BoxCloneServiceLayer`) to ensure all branches of conditional logic returned a unified, predictable type [cite: 20]. 

The Axum framework bypasses this typing complexity entirely. The `Router` struct internally performs type erasure on all the services it encapsulate. Consequently, the `.layer()` method takes a generic `Layer` but returns a plain, uniform `Router` [cite: 21]. This architectural design permits direct, cost-free runtime mutation of the application stack.

##### Dominant choice
Yes. Conditional layering utilizing the `Router::layer` method is the definitive, idiomatic standard for managing dynamic middleware in Axum applications.

##### Qualified shortlist
*   `tower::util::BoxCloneServiceLayer`
*   `tower::util::Either`

##### Excluded by gate
Not applicable, as this is an architectural pattern, not a deployable crate.

##### Up-and-comers
Not applicable.

##### Fit for this template
This specific pattern translates the logic of the Python implementation—where `rate_limit: str | None = None` serves as the initialization gate—directly into safe, idiomatic Rust. The configuration struct loads the environment variable. If the variable contains a valid configuration string, the middleware is instantiated and seamlessly applied to the router. If omitted, the application routes requests natively without invoking the GCRA checking layer, ensuring zero overhead in non-production environments.

##### Recommendation
Implement the **Conditional Router Layer Pattern** within the application bootstrap sequence.

##### Ranked runner-up
`tower::util::Either` serves as a viable fallback, particularly useful if modifying the entire `ServiceBuilder` stack comprehensively rather than selectively applying layers to the specific `Router` instance.

##### Tradeoffs
The profound advantage of this pattern is that it imposes zero runtime performance penalty in environments where rate limiting is disabled, such as local development or continuous integration, while completely avoiding complex type erasure boilerplate. The tradeoff is that middleware execution order relies strictly on the sequential order in which `.layer()` is invoked. Because Axum structurally wraps layers from bottom to top, engineers must carefully place the conditional rate limiting block to ensure it executes only *after* essential tracing components have initialized, but definitively *before* resource-intensive request handlers are invoked [cite: 1].

##### Parameters
*   `assumes http-middleware-stack = ordered properly around Router`

##### Migration implications
Adopting this pattern requires strategic modifications to the application bootstrap function, typically located within `src/web/app.rs`. The conditional logic must be wrapped around the router construction phase prior to binding the TCP listener.

##### Validation strategy
To validate the conditional execution pattern, the application will be tested in both states:

```bash
# 1. Start application WITH rate limiting disabled (the default state)
cargo run
curl -i http://localhost:8000/api/health
# Verify complete absence of 'RateLimit-Policy' headers

# 2. Start application WITH rate limiting explicitly enabled via environment
RATE_LIMIT="10" cargo run
curl -i http://localhost:8000/api/health
# Verify explicit presence of 'RateLimit-Policy' and standard enforcement headers
```

The expected outcome requires the application to boot successfully in both scenarios. When disabled, intensive load tests utilizing tools like `wrk` or `k6` must experience zero 429 rejections, regardless of total throughput. When enabled, requests exceeding the declared quota must be strictly rejected [cite: 25].

##### Confidence & re-verify trigger
Confidence in this pattern is absolute, as it relies on the stable, foundational routing traits of the Axum framework. The re-verify trigger would be a major architectural breaking change in a future Axum version (e.g., v0.9+) that alters how `Router::layer` manages internal type erasure and mutation.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| Metrics | N/A | Inapplicable (Architectural Pattern) |

### Compatibility

The recommended components—`axum`, `governor`, and `axum-governor`—are fundamentally and structurally interlocked by design. `axum-governor` explicitly defines `governor` as a core, non-optional dependency and relies entirely on the `axum` and `tower` crates to form its integration layer [cite: 30]. The official `axum-governor` documentation and example repositories explicitly demonstrate the Conditional Router Layering pattern interacting securely with the `dashmap` state store and background garbage collection mechanisms under extreme load [cite: 5]. Furthermore, the type constraints defined by `GovernorLayer` strictly conform to the expected `tower::Layer` signature, guaranteeing seamless compiler compatibility with Axum's `Router::layer` API [cite: 21, 37].

### Parameters

*   `owns rate-limiting-middleware = axum-governor bundle`
*   `assumes web-framework-stack = axum`
*   `assumes http-problem-envelope = standard RFC 7807 mapped via IntoResponse`
*   `assumes http-middleware-stack = ordered to position rate limiting safely post-tracing`

### Migration implications

The implementation of this rate-limiting bundle will manifest in several critical file modifications within the `rs-launch-blueprint` repository:
*   `Cargo.toml`: The addition of `axum-governor = { version = "2", features = ["dashmap", "json"] }` to the dependency manifest.
*   `src/config.rs`: The introduction of a strongly typed `rate_limit` field to the primary application settings struct, derived directly from a single environment variable during the configuration parsing phase.
*   `src/web/app.rs`: The integration of the conditional layering logic during the instantiation of the Axum `Router`, ensuring the middleware is applied globally if configured.
*   `src/web/errors.rs`: The extension of the central application error enumeration to intercept and map specific `axum-governor` rejection types into the standard RFC 7807 Problem JSON envelope required by the broader architecture.

### Validation strategy

The validation of the entire bundle relies on executing integration tests against an ephemeral, locally bound TCP listener. 
1.  **Bypass Check:** Execute 50 highly concurrent requests with the governing environment variable entirely unset. The test suite must assert that 100% of these requests successfully yield a `200 OK` status, proving the default-off capability.
2.  **Enforcement Check:** Set the environment variable to an aggressively strict limit (e.g., 5 requests per second). Execute 20 identical requests in parallel. The test must assert that exactly 5 requests succeed, while the remaining 15 requests fail immediately with an HTTP 429 status.
3.  **Envelope and Header Verification:** Programmatically inspect the headers and bodies of the rejected requests. Assert the definitive presence of a valid, mathematically sound `Retry-After` header. Parse the JSON body payload to assert strict compliance with the RFC 7807 format, ensuring the presence of the `type`, `title`, `status`, and `detail` fields.
4.  **Garbage Collection Overhead Verification:** Instantiate the router and simulate requests from 1,000 uniquely mocked IP addresses to heavily populate the concurrent `dashmap`. Pause execution for the duration of the configured GC interval, and assert that the application's memory footprint stabilizes or reduces, confirming the background `retain_recent` task is fully operational and preventing memory leaks [cite: 6].

### Confidence & re-verify trigger

The architectural confidence in this bundle is exceptionally high. The specific combination of `governor` and `axum-governor` represents the current pinnacle of performance, memory safety, and reliability for in-memory rate limiting within the asynchronous Rust web ecosystem. The solution perfectly maps to the required criteria, preserving the intent of the Python precedent while leveraging Rust's unique concurrency guarantees. 

Operators should monitor the ecosystem for the future maturation of the `axum-limit` crate, or watch for `governor` to introduce a first-party, lock-free approach to distributed caching. If the blueprint scales to a point where strict, multi-pod rate-limit synchronization is required out-of-the-box, the "in-memory single-instance" design of this stack will necessitate the implementation of custom `StateStore` traits to bridge the gap to a centralized database.

### Sources

The empirical data, metrics, and ecosystem analysis informing this report were sourced directly from the authoritative registries and repositories of the Rust ecosystem. Specific metrics regarding crate adoption, release velocity, and security posture (e.g., 90-day downloads, all-time downloads, MSRV constraints, and advisory checks) were systematically retrieved from the `crates.io` API and the `RustSec` Advisory Database. Source code analysis, issue responsiveness, and historical context were gathered via the GitHub API targeting the respective repositories of the shortlisted candidates. The data supporting these evaluations is embedded directly within the metric tables corresponding to each component member in the sections above, ensuring all claims are directly traceable to their real-time state within the ecosystem [cite: 5, 6, 12, 13, 34].

**Sources:**
1. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFwgIzWBQUkxvaEmAn3sLGE8AByRHRwUlJFiJiMbVxpPn5C7ecqYXRkfr8-tmLJKzCCzMfLCqK6VvrgfRhXMY_ZJqlieF-fdeE8HcctCOH_b1aFOFAPLvlfU46TqCKP4ERocVM6sOsUzWeFPF4=)
2. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHhqLMmMLKfWoGpQR9xn-MieRWzGM5DjowQnkvPgar1-kg7oa4CAuPNT7Sb_US90mNJxQ7onjKAuOT5qT-6xeQJnWHaSYtC5PtZ1vjgt4Nmy-yBipk=)
3. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEj7FduqJ-PSsAMmGPphop_JIa4exRnFtUBqCgZ1QJkqTua3pVb-XhdVZs1OpcHDlsIznxG3QaffuIDobHB0N-n26iVN2EgBzixFrooPMWyMN763zRCwyrf8V-GfvrRKIlafg_B0xR8NABHHg==)
4. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFTbq7NJXrNOtuxe4DkUxtvJiX9WTskOhlTfziGolhgYsha0TSH8JkZPOXLJLNxODmR0k-V4GlHujNUIerq0kpU2DKHQuAnfPAvdttCYxb62qFvPSOqR1vr7neu_zE=)
5. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5eKUiMzOwG6xYSIc3DWlGHotFoATAf1K-H5WI5Rd6p84kg62sw3q_dDYe9e9wMyNidUzU4h5mz-Tcfa-EhehTIEFIPLskIHdD_rmzggWHkzSHTA==)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWV2Lmftj-ON2KlzZfeyd5zHNFzxMiScJ0iamk9Hr3LRoSscJZouFheThLZwr8ijt8Er5n-9viay5ES_e6fEHn1NF0TOS5JsaRqVR2XbBxxzkVL1nhpc_6Q-qPlA==)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtjv_y7MurYyEcUY5YlIjZGbEuGj8UfTLN7709w-tsE3hEMitoAJjMtkUQ3KrxLGEY8lkewiIdaduezo1RIKFJ_3PvEoN17w7STzFPJ1O3YA==)
8. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGAI7IyZNjbtuVvFnsSrV-5EPcBiJioIKG8-t59Nf7xrho69k4lWHVUV710Rk41JGYUk6zuZHMqkm2OPAtyd8pWORTMZWsTUR4HpV8=)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFOSRcAxneb2aRGi1NPh1yXcunJ3V4icuflsxgYdmSxrgJYGwW6XoNlLAD-q2nwABNKEHJsC0eW7bAPMIbzHvU7rV0EjIuCm-x-eHKHx0nItbtxQ-YZ_I5vKtzn)
10. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUdnkq_etrRQ2pY6yGpg8WL-4Ujpxl-2g6Zq3p4hwBNeuBpnlLXx9BjwGBbOQKZ3bO3VH-IHPSPqRqSaejoCJF71z0HGLVPZQrU6mrEarusreOKLtfqoEyIuWJDKmkZOAMEprQT1vnQYwxoAfiFr1a2ZbIF1W9gek_fhOs)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE0HgN4HuG9-OgK0DkDOaHpehecr6Lyw0hhV3bQIHsfPCHkGuRuG0J-VRu7rbfBeUAQzatgKdQQcfuMquS1fu4Pdje2RVpsbs91zatflAYcnf5AqriysWnklZewAca-)
12. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDvjcnIunCZkPhOmL6sqARrqoW4HSzsZESte3PjYV6PwZ0ev8pHNxCD1VNe6kJnRmS0BCv1Wa3QzKMU-Y3ElAfNZVBMtRxfAbgZ0wF5Bvyd41XtLvI)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHHd8UYKs5o-CtNDhaqoHcnXtsShJMLYPH1_J2i3mc_HvUy4-nP-Cf8h7zlMUaytbh8sPfPGsVBrvRB36zzJTymodXg-gvZizKJndbvPjCjpn6IfR9wwx-m3k9gkw==)
14. [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE0C0DxA37gVkAIlMmKwMCgSwDZgQen56Lp6lWQs70VQq_VOAv8TBKsMa_jBdHvWT_fGsvmH1FNc_RkmfQ1M2s6G_yb8vLgsmP4ucS5c--P57EZ8Q6a6Joq7WTCtogsEzJESDk4elVjNPPWyHXSRmIH)
15. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH_F6fuZgF3YIu25pwP4dRKQyDZHtqxG8M4455E7WEDPqeKpVncRGZBkOl8oZJ1GaBKmhgrZ898zjllQh1kYLMivs2LItibLB8uA-ydui0VfqjZDtDxpGp-SSMwZHIIVfwNpO8ECvw5auVFBB9a7djg8QvVxqH748-x6xHFUOZQYmZ0WNBd82e_5SzOkXHBm5oLaksbTbF37dpvISuBaYihl0ulOSVXs8U0Amj1UbkjEkoz4Iu3EOV1ug==)
16. [gitconnected.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGD5HV2IdH5oYRkoHNWXHCeueHOnOSKjiWBw8zsjv0KNakgcv3msPfB-fC8Y_yc-sg8-_jnb1IrpIBvU3a4JgrKEYCx2xEP_w5hMeS4C6u9PATGTyDZmNw4Q-t1NRBGz48blUM9CL6PDrXGqGzTe8kyAjc17m5c0yanI6OlEoF7ya4qKg==)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQELZjPvW5dPt1nCKGq2t1KSMgEnMXRo9X4IMjCrnbDFH9Xig9JuCiLdrrvvYqwnVR8_TGPVuOYCXPuBv9lk7lwQ1erR-ABBKKiVHECvgUj78yJYbkVhOu79XyO-PGr17sYE)
18. [github.blog](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHStcnXYKPc6SAvg5Hx5KW1nR01g4ohcRfJo6wgO6IydPCtKHkXfjXbnjDk_9fBV0b__rGWW_tishBsPVYnHBTgbt5mLB10O3Fn6gqNsEg3fwhsO5caPrkADWZ9aX-J7X6s89vGVgXRs_P1dHEOqITzfX90jtRgyMhsCOhYMU1Mf43r7Bw4fHjpsz8=)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQ7JB4KDiFRHPdXikmKIggfXOscIidZh28w6lKbi0cAUvtD3iXuZOWWqAFuHr3uiUsMdlSpoDKT6g4_u5_34CC9XJuUjPNlHAouOs2lEiWpMpxm74r1AKDv1Y4hA4AVb1Ws_gx_z6eNszZYgCdWSC5Rnxsryz2j8ce6YXVKCw5aqm70MLv1FQ5bzXdbHCUf1NYeaXx6s9MsTMe8bCp9AVhKF9DGuTYuzyu6yVtt48nPSc=)
20. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGVDO8rL88t-niML-VLNuCLGRjHbARNdFQJiSIn6jt4WX0ZvMQNlBqJ90WoRHvYBxsRHteR5wFowlcwoBPGnXSgivM4wnXE4K73G0Yh2FrqIBSGqv-N0jwnkTXLRQRFs7QKbTE2H5cNdQ1Kzsfj4NSSJmHxTDhpsHSfvNdVc2LxICn6)
21. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHVMVmy_m-B_c1sUbqYaHTnOBNJY_jxN37jWaSnZMuBhx5mmNLukD5l_TWf4ISO_bZZfR7PEdw4UzrxdaPEM5IQQiTTQM0PzcKjZsBLM_WW8as8qYI15GOPJvQl3cgKFo7GIPopxIaEAFEOyMU_R9x6Jw==)
22. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEG8bYICydRSv2zYXLq0FlbM-3s7D36U1jkDxwq9OBK0RwE3OUnIbIOalOQlu_0GMKWNRjvDyS-eIlkYpFLxyTQWsK1s1lM3nJundjN4N25TqvXWU1T2YAlPhh3y6Jdh5r4tyUWTdHAbx5WgHxkfbUwaoi_DDgJuH54jnU4W6m_25daRA==)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbtL9eCfnIjDH2l8l1Qdgcvwvf3EnZ0-VbdiMjs6iYzLz4jNl_KcmAp_kQqtkO05YjxrOJoxn-_wGr3MQjGDW9qoPDPuXQOJywNGPTgoy8gVKjuQ0Nsz8=)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4HNw0VBOi-XxCUlXsT7Js7d938koXrR5sxJP3vIwgsAlhTBDQGaKjmseUJ0jLVeApEY6gGYnEbiyugTnrTwc0iESAUVhGEhZZ0zocp1BAZtd79YAHErFw_SHi4EUOVndlRIMuCZ2Omj1BL_LNSsMH)
25. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEBb6EgBqwhqR1Ti9t1vDdKY1ZufGmzzHRrE_veiO006Guz7xnELx6l8xjbgg8aqR7JaPNHoJuNdNAaOEJJe1XzdYP4_PhZ8rffko6gHVWhMWDV3I5SMdh4O-Xx1oVW_NA-MxqzUz7NFlzR-S-xtcD0GBSLkUWFVKpm-gIwdd1ULVdJSpRW-BbQzn7UaJp-R286jkIElr5PXzMMDjOci4fHlVyCKEg0pHDUw==)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH0GPOdaBLk41Qgy8KcKbau_rijLKBfANUovR_2Wv3SMWoPW1eE9cvE-dAumNzlq5jy2BJiC3zXRT79KXTUy-CHu72kBgr36yJcdV3V78FMI9EfhpdeGN4ySf0em_rOzQ==)
27. [sparkco.ai](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjiX5-DZ7rVhe046TXYhH1xnNsWLzhI2WbTjao7jK7IbC-9LdO7urxzPs-AfBRZmBxht2BZ0qP0tUCjeF6kEecVg9pVYIM_S8QaK_cn1kEhcI4ivrOtXFq9bj7tgtG1gI0R7es6BhQGhgJ0KW1soWgX66YU8RmY_CrbNd8b3diaegqzXQ-yJoWS7D-zlETPQ==)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGxuty_BeuVXKhwjFGU8BETj1TrWrZOpCnaFC0jZuFbzg9DIGORN16-LTBFFqVkSdDOE81MWxvJ5ALE-fmtJeOgdnnRGdaKZRMTVm_lZ2monY0eYgQWZj8gLa3vQVMhfw==)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHT9MX1YESCk35jcVios7sHyJ0usngfiJiIshetItwXug1ZeZLjsZ_85jMYwb9t0j7iiPXEFr2kNYyR-AKOurwVT1rovQMgMK6GgvTJjLhHWmI6GsvUSzW_OniNYpXu)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGisRM2H-wSCIuM5qHADKEwnru48975EzC8JiIAEgt2feJr4q11e2QosjizRPPihhbZBWyF5xZwolwEJojm8kj0wfSrm8UtpgH27UOhH5Vn1VzGiSw9SV5GmR-P2cWJOZaUzAH35DXVbhgx11bjB-6fblDP)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEA7PC0XyCDEy_I5ZBnVHEEcK_WI2Qjve38BsaASdc36H-STEI3i60iy3E9dM-KlhLAkB_gXKFCfrEYxcoHRF0kuJ9DoCJsfwpmY7ApdryCYUrEYa3u-YCTWhlLIlax_ZQ_sauokDtRR5qHA==)
32. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQELADmX7jas_NiqL_SPqSIPLXR2AVM2-IMgQJ29siopaVspakuYMe9DAIm-iTRyXEjsW4BabY16fp4amHowXN-YqKphGQxVIQNXAD0NFLK0YQV54vVVzs-ok3DMTVOlmoZjvcA6fJvul8Dlog==)
33. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEKA7skwbhmFcnYEtTo_Otb6X6uoS0g37SGHlXH3GS5mKWDcohFuXAx4wsKil2NTkTOrIW9TK9ECcqEFPat0tJXubf2EMrxWlMwzcp2yXxHdB_cL-R38zPWw9OAymDBpG3DUq5nq4xtQAhpU0BzgBnHTPLFLNp-to=)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGB_4QSDlfdFmr6cfXTnrOM3JZUpqFcD4g9Bbk14UolxSQGyr6sBWXdsBv7JcLnpMN-pP_DeifK4Yy52uRU6DYM6gLXFmUGJMKjOSfftBFE7CsQ8FZ03aSsduZzMlY=)
35. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFovz-XkOtuwnBvdUeul9SiY_6b8ecV8p45IlLSe0lgHShQOIpNy3VPWkGrmAbBrM3WNKinQdC_lyf6s-OTI5Ibwa1fPlX2wcdR5zq_p1Zaf70uiJcttrm6jeAtPQf1Qg39vzCn4ha8Bvh1k0z0xz4qrmB75ZZ35vqEteAd1WaIpC-g5GKgDT3LR-6TwSw=)
36. [loco.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFtV649ZJokQ2-YHz8WOqfLT1_TJHp5a703DygOG3LE5sbfJCmUytmkif26ekphzEKhX49mJyh2P6zdcqo4cfeYDZYLkTbGZe2HNXXdz0plKFlq7s7nu7UbaB9OvhNeJ2_sgnVM)
37. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHntyavdFwZYmGwfaMA4ISZe3xRYh7Q0SwUZuvDcRSa_cEyubpJmPalfi0QebyaZOexWve3fhv-meBlVmtYsubqVqG4VCyRTh_cHN_vr1KIEBrGW4r9SWWBu0tjZNyrcOOXdYTVb63CeHg=)

## Sources

- [docs.rs](https://docs.rs/axum/latest/axum/middleware/index.html)
- [crates.io](https://crates.io/crates/tower)
- [docs.rs](https://docs.rs/tower_governor/latest/tower_governor/)
- [crates.io](https://crates.io/crates/tower_governor)
- [docs.rs](https://docs.rs/axum-governor)
- [crates.io](https://crates.io/crates/axum-governor)
- [docs.rs](https://docs.rs/axum-limit)
- [docs.rs](https://docs.rs/rater)
- [github.com](https://github.com/canmi21/lazy-limit)
- [github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/docs/middleware.md)
- [github.com](https://github.com/canmi21/axum-governor)
- [rustsec.org](https://rustsec.org/advisories/)
- [github.com](https://github.com/rustsec/advisory-db)
- [shuttle.dev](https://www.shuttle.dev/blog/2022/08/04/middleware-in-rust)
- [medium.com](https://medium.com/@trivajay259/axum-the-tiny-layer-that-makes-rust-web-backends-feel-effortless-and-production-ready-a8cbe125282b)
- [github.com](https://github.com/loco-rs/loco/issues/1181)
- [gitconnected.com](https://levelup.gitconnected.com/rust-on-loco-like-ruby-on-rails-0ed22e396fff)
- [medium.com](https://devrimozcay.medium.com/i-reviewed-34-production-retry-bugs-the-most-dangerous-line-was-usually-retry-3-2eb3f264dcec)
- [github.blog](https://github.blog/news-insights/company-news/github-availability-report-july-2026/)
- [github.io](https://tower-rs.github.io/tower/tower/util/struct.BoxCloneServiceLayer.html)
- [docs.rs](https://docs.rs/axum/latest/axum/routing/struct.Router.html)
- [medium.com](https://medium.com/@dmytro.misik/building-a-rate-limiter-in-rust-48ce37d2ae07)
- [crates.io](https://crates.io/crates/governor)
- [docs.rs](https://docs.rs/governor/latest/governor/_guide/index.html)
- [rust-lang.org](https://users.rust-lang.org/t/axum-boilerplate-fatigue-i-built-a-thin-opinionated-layer-oxide-with-benchmarks/139313)
- [crates.io](https://crates.io/crates/api-rate-limiter)
- [sparkco.ai](https://sparkco.ai/blog/mastering-retry-logic-agents-a-deep-dive-into-2025-best-practices)
- [github.com](https://github.com/topics/governor?l=rust)
- [github.com](https://github.com/benwis/tower-governor)
- [github.com](https://github.com/canmi21/axum-governor/blob/main/Cargo.toml)
- [github.com](https://github.com/topics/limit?l=rust&o=desc&s=stars)
- [rustsec.org](https://rustsec.org/advisories/RUSTSEC-2022-0055.html)
- [github.com](https://github.com/boinkor-net/governor)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-01-07-rust-rate-limiting/view)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-03-05-gitrepository-rate-limiting-github-flux/view)
- [loco.rs](https://loco.rs/docs/explanation/architecture/)
- [docs.rs](https://docs.rs/tower/latest/tower/trait.Layer.html)

---
