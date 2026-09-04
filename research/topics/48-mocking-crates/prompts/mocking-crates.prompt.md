# Deep-research prompt — Mocking crates (R48, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates (with versions) for: `rs-launch-blueprint`'s mock/test-double library and its HTTP-transport-mocking mechanism in tests. Item kind: `bundle`. Value test: if this answer is wrong, the `Cargo.toml` dev-dependencies for test doubles and any HTTP-interception test helper all get added, removed, or rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos both use test doubles, framework-native rather than a dedicated mocking library, but diverge on HTTP-transport mocking specifically because their driven-I/O seams differ. py uses stdlib `unittest.mock` for general test doubles and additionally needs a real HTTP-interception library because its adapter makes literal outbound HTTP calls that must be intercepted. ts uses Vitest's built-in `vi.fn`/`vi.mock` for test doubles and needs no HTTP-interception library at all, because its transport is dependency-injected as a plain fake function — there is no real HTTP call for a library to intercept. Evidence: py `tests/cli/test_pylb.py:6` — stdlib `unittest.mock` (`Mock`, `patch`); ts `tests/cli.test.ts:12` — Vitest built-in `vi.fn`/`vi.mock`. Ledger rows: F119, F120 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence: F119 mock/test-double library — py `tests/cli/test_pylb.py:6` (stdlib `unittest.mock`, no third-party mocking crate); ts `tests/cli.test.ts:12` (Vitest's built-in `vi.fn`/`vi.mock`, no separate library either — same DI-and-spy pattern, framework-native tool differs). F120 HTTP transport mocking mechanism — py `tests/core/test_py_api_repository.py:104` (`@responses.activate` intercepts real HTTP calls made by the adapter); ts `tests/api.test.ts:27` (`fetchImpl` passed as a plain fake function — no interception library needed because the transport itself is injected). The area file's own cross-area note: "ts needs no HTTP-mock library because the transport is DI-injected; see cross-area `http-transport-injection-seam`, owned by R01 (F001)."
- Recorded baseline and owner-fixed parameters (apply the research mandate above): target shape is CLI + library + web service (spec §4 D7); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). The parameter this item consumes is still open (no `DECISION.md` yet): `http-transport-injection-seam` (R01) — R01 has not yet decided whether `rs-launch-blueprint`'s driven-I/O seam is a port/adapter split (needing an HTTP-interception crate the way py does) or direct function-value injection (needing none, the way ts does). Answer this item for **both** branches: recommend the mock/test-double crate unconditionally, and recommend the HTTP-transport-mocking crate conditionally on R01 choosing a port/adapter split with a real outbound HTTP call to intercept.
- Prior decisions of the TypeScript port that explain the current shape: D-019(5) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — DI-first mocking (fakes/`vi.fn` spies passed through the deps object; injected `fetchImpl` as the only HTTP transport seam), `vi.mock` reserved as a last resort; this is the same seam R01 (`ports-and-adapters-seam`) decided to keep for ts and is the reason ts needs no interception library.

## Out of scope
- The shape of the driven-I/O seam itself (port/adapter split vs. direct function injection) and whether it needs an HTTP-interception crate at all; R01 (`ports-and-adapters-seam`) owns `http-transport-injection-seam` — this item picks the mocking/interception crates conditional on R01's answer, it does not re-decide the seam shape.
- The base test runner and its execution-behavior configuration; R32 (`test-harness-and-execution`) owns F117/F118/F124/F125/F128-F132/F173 — this item's mock crates must run under whatever runner R32 picks, but does not pick it.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R48
- owns:
- consumes: R01: http-transport-injection-seam
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.
- related (not a registry dependency): R32 (`test-harness-and-execution`) decides the base test runner and tiers this item's mock crates run under; this item does not re-decide the runner.

## Questions
Decision: which Rust mock/test-double crate (if any, beyond the language's own closures/trait objects) and which HTTP-transport-mocking mechanism give `rs-launch-blueprint` parity with py's `unittest.mock` + `responses` pair and ts's `vi.fn`/`vi.mock` + DI-injected-fake pair.
- HIGH: Does Rust's trait system plus hand-written fake implementations (the idiomatic default) cover test-double needs without a dedicated crate, or does reaching parity with py's `unittest.mock`/`Mock`/`patch` ergonomics (F119) need a mocking crate such as `mockall`? What are `mockall`'s ergonomics and compile-time cost for a CLI + library + web workspace?
- HIGH: If R01 resolves to a port/adapter split with a real outbound HTTP call needing interception (py's `responses`-equivalent case, F120), is `wiremock` (an HTTP server-level mock) or `mockito` (a Rust HTTP mocking crate, unrelated to the same-named Python tool) the dominant choice — what are their API shapes, async/sync support, and maintenance-state differences?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: If R01 instead resolves to direct function/closure injection (ts's case), does this item still recommend a general-purpose mocking crate (`mockall`) for the CLI-level test doubles that py's `unittest.mock` provides, or is a hand-written fake sufficient given F119's own framework-native precedent in both source repos?
- MEDIUM: Do the candidate HTTP-mocking crates support the async or sync execution model equally, and does that create a hidden coupling to R05 (`sync-async-execution-model`) worth flagging even though this item does not decide it?
- LOW: What is the idiomatic Rust equivalent of py's `@responses.activate` decorator ergonomics (declarative, scoped-to-test-function activation) versus a builder/server-lifecycle API, for contributor readability?

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
