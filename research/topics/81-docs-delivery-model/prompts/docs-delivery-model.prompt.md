# Deep-research prompt — Docs delivery model (R81, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `rs-launch-blueprint` ships a generated, hosted documentation site (mdBook-style, the Rust-ecosystem analogue of py's Sphinx-on-Read-the-Docs shape) or a README-centric plain-markdown tree (ts's shape), and — whichever is chosen — what markdown dialect, section-navigation mechanism, root-README-vs-landing-page duplication policy, README "documentation" pointer, local preview server, and scaffold/init recipe result. Item kind: `bundle`. Value test: if this answer is wrong, the `docs/` directory layout, the doc-build/CI tooling, the README's documentation pointer, and — if a hosted site is dropped in favor of the generator's theme/hosting config — the whole site-generator setup all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): the two repos diverge on docs delivery. py generates a Sphinx HTML site (MyST markdown, `{toctree}` navigation, a separate landing page duplicating the README, a hosted Read the Docs URL, `sphinx-autobuild` hot-reload preview, `sphinx-quickstart` scaffolding) published to Read the Docs. ts drops the generator entirely: a README-centric front door plus a plain CommonMark/GFM `docs/` tree rendered by GitHub, with landing content merged into the README (no separate landing page), a plain bullet-list navigation index instead of `{toctree}`, no preview server, and no scaffold recipe. Evidence: py `.readthedocs.yaml:44` — `configuration: docs/source/conf.py`, Sphinx site hosted on Read the Docs; ts `docs/docs.md:1` — README-centric front door + plain CommonMark/GFM `docs/` tree rendered by GitHub. Ledger rows: F341, F343, F344, F345, F346, F351, F352 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F343 markdown dialect — py `docs/source/conf.py:32` (MyST via `myst_parser`: colon fences, deflist, heading anchors); ts `docs/docs.md:3` (plain CommonMark/GFM, no MyST). F344 section navigation — py `docs/source/reference/index.md:4` (Sphinx `{toctree}` directive); ts `docs/reference/index.md:5` (plain bullet list of relative links). F345 root-README vs. landing-page duplication — py `docs/source/index.md:1` (separate landing page duplicating README content); ts `README.md:137` (landing content merged into README, no separate `index.md`). F346 README "documentation" pointer — py `README.md:20` (links out to the hosted Read the Docs URL); ts `README.md:139` (links to the in-repo `docs/docs.md` tree with a bullet index of every section). F351 local preview server — py `Justfile:450` (`docs-dev` runs `sphinx-autobuild`); ts: none (ts's authoring guide directs writers to an editor preview or a pushed branch instead, `docs/docs.md:11`). F352 docs scaffold/init recipe — py `Justfile:434` (`init-docs` runs `sphinx-quickstart`); ts: none (no scaffolding step exists for a system with no generator to initialize).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the Diátaxis information architecture (tutorials/tasks/reference/about/tools/contributing categories) is preserved verbatim regardless of this item's delivery-model pick (F342, `COMMON → REUSE`, `rust-ok: yes`) — do not re-derive the category set, only decide how it is delivered; a contributor-facing "how to add a doc page" authoring guide is likewise already decided to exist, only its content mechanics (toctree/labels vs. relative links) are downstream of this item's pick (F347, `COMMON → REUSE`); the API-reference doc generator (rustdoc/`cargo doc` CI gating) moved to R82 at the Task 10 reconciliation and is not this item's decision (F353); `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-023(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — dropped the Sphinx docs-site generator and Read the Docs hosting entirely, in favor of a README-centric front door plus a plain CommonMark/GFM `docs/` tree, reasoning "org practice is unanimously README-centric (5/5 recent repos)... the template's value lives in the Diátaxis content, not the Sphinx machinery"; D-023(3) — normalized MyST to CommonMark/GFM, converted `{toctree}` blocks to plain bullet-list link indexes, and merged the landing page into the README to eliminate duplication, on the finding the source corpus was "~90% generator-agnostic CommonMark already"; D-023(5) — the full rationale for omitting Sphinx's machinery (conf.py, theme, `.readthedocs.yaml`, pdf/epub/htmlzip outputs) as having "no role in a README-centric model."

## Out of scope
- The doc content correctness gate — link checking (internal and external) and rustdoc/API-reference-doc-generator CI gating; R82 (`docs-correctness-gate`) owns F348/F349/F350/F353 — this item decides what docs tree/site exists, R82 decides how its correctness is checked in CI.
- Whether the template ships an optional web/API surface at all; R69 (`web-framework-stack`) owns `web-extra-surface` — this item's docs-delivery pick does not depend on that surface's contents.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R81
- owns:
- consumes:
- related (not a registry dependency): R82 (`docs-correctness-gate`) decides the CI-facing correctness gate (link checking, rustdoc gating) built atop whatever docs tree or site this item produces; assume R82 resolves separately and design this item's tree/site to be checkable by either an mdBook-style build or a plain-markdown link walk.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: does `rs-launch-blueprint` ship a generated, hosted docs site (mdBook-style) or a README-centric plain-markdown tree, and — whichever is chosen — what markdown dialect, section-navigation mechanism, landing-page-duplication policy, README pointer, local preview server, and scaffold recipe result.
- HIGH: Is `mdBook` the Rust ecosystem's dominant "generated hosted docs site" analogue (used across the Rust project's own book-style documentation), or is there a stronger current alternative worth surveying for a from-scratch Rust template (e.g. `zola`, a Docusaurus/Starlight-equivalent via a Rust toolchain)?
- HIGH: Given the owner already departs from Read the Docs' Sphinx-specific hosting model, does GitHub Pages (via an mdBook-build CI action, or plain markdown rendering with no generator at all) become the natural hosting choice, and how does that shift the delivery-model trade-off relative to ts's plain-README approach?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale.
- MEDIUM: If mdBook is adopted, what is its markdown-dialect surface (F343) relative to plain CommonMark/GFM — does it introduce extended syntax (admonitions, `{{#include}}`) that risks rendering-fidelity loss if a reader views the raw source file on GitHub instead of the built site, the same tension py's MyST syntax created?
- MEDIUM: If mdBook is adopted, does its local preview/hot-reload (`mdbook serve`, F351) and scaffold/init recipe (`mdbook init`, F352) match py's `sphinx-autobuild`/`sphinx-quickstart` UX closely enough to be a fair drop-in, or does the Justfile recipe surface need materially different wiring?
- LOW: How do comparable Rust CLI/library templates (e.g. widely used `cargo-generate` templates) handle docs delivery — hosted book vs. README-tree — for empirical precedent on which shape is the Rust-ecosystem default?

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
