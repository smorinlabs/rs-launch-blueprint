# Deep-research prompt — Public API surface enforcement (R04, pattern)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named pattern with a reference implementation for: whether `rs-launch-blueprint`'s curated public library surface is enforced mechanically — the way ts's `package.json` `exports` map makes any non-listed import path unresolvable — or left convention-only, the way py's `__all__` documents but does not block a deep import. Item kind: `pattern`. Value test: if this answer is wrong, the crate's `lib.rs` re-export structure, its module visibility (`pub`/`pub(crate)`) declarations, and any surface-snapshot CI check all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos curate one file as the sole sanctioned import surface for consumers — py's `core/__init__.py` `__all__` list, ts's `lib.ts` root barrel re-exporting from `lib/api.ts`, `lib/config.ts`, `lib/errors.ts`, `lib/format.ts`. Evidence: py `src/py_launch_blueprint/core/__init__.py:61` — `__all__` lists the package's public names; ts `src/lib.ts:5` — root barrel file re-exports the stable public surface, cited "the only stable API surface" in `lib.ts:1-3`. Ledger row: F014 (`docs/port/COMMONALITY.md`), verdict `COMMON → REUSE`, `rust-ok: yes` — the curated single-surface pattern itself is settled and out of scope for this item; do not re-decide whether a curated surface exists, only how it is enforced.
- The enforcement mechanism, not the surface's existence, is the open question. Evidence: py `docs/design/0005-hexagonal-architecture-and-enforcement.md:298` — `__all__` "documents, it does not enforce" (HEX-34); nothing blocks a deep import of an internal module; ts `package.json:24` — `exports` map declares `.` as the only importable path (`types`+`default` to `dist/lib.js`); Node's module resolution refuses any other subpath. Ledger row: F015 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-012(3) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — "Hand-authored root-only exports map ('.' with types+default, plus ./package.json)... do NOT use tsdown's exports auto-generation"; ts deliberately hand-authors a single-entry `exports` map rather than letting the build tool generate a wider one, keeping the enforced surface exactly as narrow as `lib.ts`'s barrel.

## Out of scope
- Cargo workspace crate topology (single crate vs. multi-crate members); R02 (`crate-boundary-enforcement`) owns F021 — this item decides the visibility/enforcement mechanism for the public surface, not which crate holds which module.
- The ports-and-adapters seam shape itself; R01 (`ports-and-adapters-seam`) owns F001 — this item is about the crate's public API surface, independent of whether internal I/O uses a port trait, a generic bound, or direct injection.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R04
- owns:
- consumes:
- related (not a registry dependency): R02 (`crate-boundary-enforcement`) decides the Cargo workspace crate topology (F021). Whether this item's enforcement mechanism is single-crate `pub`/`pub(crate)` visibility or a multi-crate boundary (an internal crate simply not published/re-exported) depends on R02's answer — assume either shape is possible and state which mechanism applies to each, do not pick R02's topology for it.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what Rust mechanism gives `rs-launch-blueprint`'s public library API the same non-bypassable guarantee ts's `package.json` `exports` map gives it, replacing py's convention-only `__all__`.
- HIGH: Does Rust's own visibility system (`pub`, `pub(crate)`, `pub(super)`, private-by-default) already give a non-bypassable guarantee equivalent to ts's `exports` map — i.e., is there any way for an external crate to reach an item not re-exported from the crate root, absent `pub` on the containing module path and the item itself?
- HIGH: If Rust's own visibility system already suffices at compile time, does anything else need to be added — a lint, a doc test, a `cargo public-api`/`cargo-semver-checks`-style CI check — to keep the curated re-export list from drifting silently as the crate grows, the way py's `tach`/`ruff` catch drift for its import contracts even though `__all__` itself does not?
- MEDIUM: Should the curated surface be expressed as one `pub use` block at the crate root (`lib.rs`), mirroring ts's single barrel file, or as module-level `pub(crate)` defaults with selective `pub use` re-exports scattered per module — what do idiomatic Rust library templates and the Rust API Guidelines recommend?
- MEDIUM: Is there a CI-checkable tool (`cargo public-api`, `cargo-semver-checks`, or similar) that snapshots the public surface and fails CI on an unreviewed addition or removal, giving this template a mechanical drift-detector beyond bare visibility rules?
- LOW: In a multi-crate workspace, does an internal-only crate need anything beyond staying unpublished and unreferenced from the public crate's `Cargo.toml` `[dependencies]` re-export path, or does it need an explicit marker (e.g. `publish = false`) to keep template consumers from depending on it directly?

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
