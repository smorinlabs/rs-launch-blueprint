# Deep-research prompt — Port absence-vs-failure contract (R03, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: how the driven-I/O seam signals "the requested resource does not exist" (an expected, non-exceptional outcome) as distinct from "the transport broke" (an unexpected I/O failure), and where the absence-to-domain-error translation happens. Item kind: `pattern`. Value test: if this answer is wrong, the seam's return-type contract (`Option<T>` vs. `Result<T, E>` at the port/adapter or injected-function boundary) and the call-site translation of absence into a domain error get rewritten across every I/O call in the template.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on where "is it there" is split from "is absence an error." py separates the two: the adapter returns `None` for absence, and a separate service layer turns `None` into a typed exception. ts does both in one function: the same call that performs the HTTP request also decides absence is an error and throws inline. Evidence: py `src/py_launch_blueprint/core/ports.py:47` — `get_project`/`resolve_workspace_gid` return `... | None`; `src/py_launch_blueprint/core/services/projects.py:56` — the service turns `None` into `ProjectNotFoundError`; ts `src/lib/api.ts:182` — `createApiClient`'s `getProjects` resolves the workspace and throws `NotFoundError` inline, in the same function that does the HTTP call. Ledger row: F012 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). This item's answer must work whether or not the I/O boundary is expressed as a formal port trait (R01 has not yet decided F001); design the absence/failure split so it fits a trait method, a generic bound, or a directly injected function value equally.
- Prior decisions of the TypeScript port that explain the current shape: none — `TS_PORT_DECISIONS.md` records no dedicated decision splitting absence from failure; ts's single-function shape (`api.ts:182`) was never treated as a separate design choice from the HTTP-call implementation itself.
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): This is a hex pattern that we've used before in the other repo. It would make sense to have a similar best practice pattern across all three.

## Out of scope
- Whether `rs-launch-blueprint` adopts a port/adapter split at all, or injects functions directly; R01 (`ports-and-adapters-seam`) owns F001 — this item's pattern must apply to either shape R01 lands on.
- The stable error-code catalog and its process exit-code mapping; R67 (`error-and-exit-code-contract`) owns `error-taxonomy-exit-codes` — this item decides the seam-level absence/failure signal and where it becomes a domain error, not the eventual exit code that domain error produces.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R03
- owns:
- consumes: R67: error-taxonomy-exit-codes
- related (not a registry dependency): R01 (`ports-and-adapters-seam`) decides whether a formal port trait exists for the driven-I/O seam (F001). This item's absence-vs-failure pattern must work whether that boundary is a trait method, a generic-bound function, or a directly injected closure — treat R01's shape as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how does `rs-launch-blueprint`'s driven-I/O boundary distinguish "resource not found" from "transport/I/O failure," and where does that distinction become a domain-level error type that feeds R67's exit-code mapping.
- HIGH: Should absence be encoded as `Option<T>` returned by the seam function, with a separate call site converting `None` into a domain error (py's two-layer split), or should the seam itself return a `Result<T, DomainError>` that already distinguishes not-found from transport failure (folding what py splits into one step, closer to ts's shape)?
- HIGH: What Rust idiom cleanly expresses "this outcome (not-found) is expected and non-exceptional" versus "this outcome (I/O failure) is unexpected" — a dedicated error enum variant, `thiserror`-derived error types with distinct variants per cause, or two separate return channels (`Option` for absence, `Result` for failure, composed via `Option<Result<T, E>>` or similar)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. The owner requested this cross-repo comparison even though the earlier divergence analysis marked it `harmonize: no`; that label does not predetermine the answer.
- MEDIUM: Does propagating an absence/failure distinction through `?` (via `From`/`Into` conversions, or combinators like `ok_or_else`/`map_err`) cost ergonomics compared to py's "return `None`, then the service raises" two-step, and is there a standard, testable idiom that keeps the conversion explicit at the seam boundary rather than buried in a generic error type?
- MEDIUM: How should this pattern's error type plug into R67's eventual error taxonomy — does the absence variant need to be a stable, named catalog member decided now, or can this item define the pattern generically and let R67 assign the final variant name/code later?
- LOW: Do any published Rust CLI/library templates or style guides document this same split (a fallible transport call, narrowed to a domain "not found" case) as a named pattern, and where?

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
### Dominant choice
### Options
name · where documented · adopters that practice it · date of the most recent authoritative write-up — no download columns.
### Excluded by gate
### Up-and-comers
### Fit for this template
Argues per target shape — CLI · library · web, separately.
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
Commands that prove the principle holds in a realistic example using the recommended libraries; state expected behavior and distinguish planned checks from executed results.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Survey method (`## Required evidence`): landscape first, established authority, practice evidence, fit — reported under `### Landscape`.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
