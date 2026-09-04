# Deep-research prompt — Runtime version accessor (R22, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern (with a reference implementation) for: how `rs-launch-blueprint`'s code reads its own package version at `--version`/diagnostics/health-check call sites — py's runtime lookup of installed package metadata versus ts's build-time inlining of the manifest's version field. Item kind: `pattern`. Value test: if this answer is wrong, every call site that prints or reports the crate's version (CLI `--version`, diagnostics output, web health/status endpoint) and however that value gets into the binary all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py and ts resolve their own version at different times — py at runtime, ts at build time. Evidence: py `src/py_launch_blueprint/__init__.py:24` — `importlib.metadata.version()` reads installed package metadata at runtime; ts `src/version.ts:6` — imports `package.json`'s `version` field, which the bundler inlines into the build artifact. Ledger row F064 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the version's single source of truth is `Cargo.toml`'s `[package] version` field — ledger row F063 (`version source of truth`) is verdict `COMMON → REUSE`, not a research item: both py's `pyproject.toml [project] version` and ts's `package.json` `version` are release-please-managed literal manifest fields, and Cargo.toml's `[package] version` is the direct, uncontested Rust analogue with no alternative to research. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-021(2) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Hand-written `src/version.ts` importing `package.json` with `with { type: "json" }`, inlined by the bundler; no generated file tracked; test asserts `VERSION == package.json` version", chosen because "contributors-please's shipped single-source pattern has zero drift surface and fixes both the source's tracked-despite-header `_version.py` inconsistency and agent2linear's documented hardcoded-version drift bug."
- Owner direction (2026-09-04, recorded in `docs/port/OWNER-REVIEW.md`): We want to use the same principle. The principle is that all versions have a single source of truth.

## Out of scope
- Whether the CLI's `--version` output also prints extended build metadata (target triple, `rustc` version); R60 (`cli-parsing-framework`) owns F267, the CLI's extended-version-output surface — this item decides only where the base version number itself comes from, which F267's answer would then print.
- The build tool's output-artifact naming and layout (what the binary/library targets are called, where `cargo build` places them); R49 (`build-target-declaration`) owns `build-tool-output-shape` — assume its answer as a consumed parameter, do not re-decide it here.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R22
- owns:
- consumes: R49: build-tool-output-shape
- related (not a registry dependency): R60 (`cli-parsing-framework`, F267 extended CLI version output) prints whatever version-metadata source this item selects; no registered parameter connects them — treat R60's direction as open, do not block on it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: whether `rs-launch-blueprint`'s runtime version accessor resolves the crate's version at compile time (embedding it into the binary, ts's shape) or at runtime (reading installed package metadata, py's shape), and what Rust-native mechanism implements the chosen approach.
- HIGH: Does Rust's `env!("CARGO_PKG_VERSION")` compile-time macro (ts-like, build-time, zero runtime cost, works identically for a statically linked CLI binary) fully substitute for py's `importlib.metadata.version()` runtime lookup, or does py's runtime-lookup approach solve a problem `env!` cannot — e.g. reporting the version of a dynamically loaded plugin, or the version actually installed on disk versus the version compiled in?
- HIGH: For the web-service target specifically, does a compile-time-embedded version create any staleness or multi-binary-deployment risk that a runtime lookup would avoid, given the template may ship the web surface as an optional Cargo feature?
- MEDIUM: What is the idiomatic Rust crate or macro (if any is needed beyond `env!`) for exposing the version as a typed constant reused across the CLI, library, and web crates without duplicating a string literal at each call site?
- MEDIUM: How does the version-consistency test suite (ledger row, unlabeled — `tests/meta/test_version_consistency.py:56` in py, `tests/version.test.ts:11` in ts) get its Rust analogue, asserting `Cargo.toml`'s version matches the value the accessor returns?
- LOW: Does `git describe`-style build metadata (commit SHA, dirty-tree flag) belong in this same accessor, or is that entirely R60's extended-version-output concern?

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
