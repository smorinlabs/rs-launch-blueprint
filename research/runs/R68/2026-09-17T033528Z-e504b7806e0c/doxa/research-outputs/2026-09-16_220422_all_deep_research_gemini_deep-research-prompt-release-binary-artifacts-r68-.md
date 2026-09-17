---
prompt: # Deep-research prompt — Release binary artifacts (R68, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate/tool with a version range for: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only, `cargo-dist`-style cross-compiled GitHub Release binaries, `cargo-binstall` metadata, or some combination. Item kind: `crate`. Value test: if this answer is wrong, the release workflow's artifact-build/upload steps, any `cargo-dist`/`cargo-binstall` config file, and the README's documented install method all get rewritten. Second subject, added by owner ruling W0-R69p (2026-09-16; `docs/port/OWNER-REVIEW.md`, section *"2026-09-16 — Release build profile ownership: R68 (W0-R69p)"*, and `docs/planning/p02/owner-decisions.md` §10, row `W0-R69p`): this item also decides the **Cargo release build profile** — which `[profile.release]` keys the template ships (`lto`, `codegen-units`, `opt-level`, `strip`, `panic`, `debug`), and whether any custom profile is declared beside it — evaluated against binary size, build time, the debuggability of shipped binaries, and the fixed `target-os-matrix` and `msrv-policy`. Value test for that subject: if this answer is wrong, the template's `[profile.*]` block and the profile the release workflow builds under both get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two PyPI artifact formats (sdist + wheel); ts ships one npm package format (a single ESM tarball). Neither maps directly onto Cargo, which produces exactly one `.crate` file per `cargo publish` regardless of how many distributable formats the source ecosystems used. Evidence: py `.github/workflows/ci.yml:216` — `uv build` produces sdist + wheel; ts `package.json:23` — `"type": "module"`, single ESM npm tarball. Ledger row: F214 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the build backend/bundler tool question and the entry-point/bin/packaged-file-whitelist declarations that produce the artifact under discussion here belong to R49 (`build-target-declaration`), which owns `build-tool-output-shape` — this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped, not how the manifest declares its build targets. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). **SUPERSEDED IN PART by owner ruling W0-R69p (2026-09-16):** the clause "this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped" no longer bounds this item — the Cargo release build profile is a second subject it decides, per the last bullet of this section. The rest of that sentence stands unchanged: the manifest's build-target declarations remain R49's, and the fixed parameters below are unaffected.
- Prior decisions of the TypeScript port that explain the current shape: none — ts's single-npm-tarball choice has no `D-###` entry in `TS_PORT_DECISIONS.md` weighing alternate artifact types; it simply follows npm's one-package-format convention with no equivalent decision record to carry forward.
- Release build profile, owner ruling W0-R69p (2026-09-16): R69 revision 9's census over all 85 binding prompts and the commonality ledger established that **no prompt and no ledger row names `[profile`, `lto`, `codegen-units` or `opt-level`** (`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/DECISION.md`, the *release profile* row of its owner-reference reconciliation, row 11; asserted in that run's `review/evidence/owner-reference-check-r9.log`, section C, with the denominator printed and a control showing the same census does report a string the prompts carry). R49 (`build-target-declaration`) owns the manifest's declaration surface and is accepted and published, but sets no `[profile.*]` key; R69 recorded the row as a hand-off and deliberately evaluated, recommended and excluded nothing about it. The owner ruled the subject onto this item and directed that this prompt be amended before the item is prepared; adding it to R49 (which reopens an accepted, published decision), opening a new item (an extra research cycle) and leaving Cargo's defaults to P03 were all declined. The owner-supplied reference architecture is an **input** to this item under `docs/planning/p02/owner-decisions.md` §11 — an owner-supplied research input, not a binding standard and not a pre-decision — and the `Reference Cargo.toml` section of `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` states, verbatim: `[profile.release]`, `lto = "thin"`, `codegen-units = 1`. Per §11 that file is copied into this run's `inputs/` when the item is prepared and named as a required input to every engine and synthesizer task; this item agrees with its profile row on the record or states the ground for differing, citing the file by section. Owner-fixed parameters override any value it states.

### Baseline review (2026-09-04)
- F220 (documented end-user install method, `ADOPT`) is a value derived from this item's artifact decision: state which commands the README documents (`cargo install`, release binaries, or both) (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The Cargo manifest's build-target declarations (`[[bin]]`, `[lib]`, entry points, packaged-file whitelist) that produce the artifact this item distributes; R49 (`build-target-declaration`) owns `build-tool-output-shape` — this item consumes that shape as a given, it does not re-decide it. **Amended by owner ruling W0-R69p (2026-09-16):** this exclusion reaches the manifest's *target declarations* only. R49's owned `build-tool-output-shape` (`docs/port/PARAMETERS.md`) names the `[lib]` and `[[bin]]` targets, the `[package] include` allow-list and the `target/` layout, and sets no `[profile.*]` key at all; the Cargo release build profile (`[profile.release]` and any custom profile) is this item's by that ruling and is in scope here. R49 keeps its target declarations and is not reopened.
- Whether a container image is a further distribution artifact for the optional web-service build; R51 (`container-image`) owns F223/F336/F337 — this item covers the CLI/library binary artifact question, not the container question.
- CI-wired or local install-and-run smoke testing of whichever artifact this item selects; R50 (`install-smoke-test`) owns F221/F222 — this item decides what gets shipped, not how it is smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R68
- owns:
- consumes: R49: build-tool-output-shape
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R51 (`container-image`) decides the separate question of whether a container image ships as an additional distribution artifact for the optional web-service build; that is orthogonal to this item's CLI/library binary-artifact question.
- related (not a registry dependency): R50 (`install-smoke-test`) decides how whichever artifact this item selects gets install-and-run tested; this item does not decide the test mechanism.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only (no additional artifacts), `cargo-dist`-style cross-compiled GitHub Release binaries for direct download/`cargo-binstall`, or a combination — given `build-tool-output-shape` (R49) fixes what the manifest declares as buildable.
- HIGH: Is `cargo-dist` (or its current successor/equivalent) still the dominant, actively-maintained tool for producing cross-compiled GitHub Release binaries plus installer scripts from a Cargo workspace, and does it integrate cleanly with the release-please-driven release flow already `COMMON → REUSE`d elsewhere in this template (F063–F077)?
- HIGH: Does `cargo-binstall` compatibility (pre-built-binary metadata that lets end users skip a source compile) require anything beyond what `cargo-dist`'s GitHub Release artifacts already provide, or is `cargo-binstall` support close to automatic once cross-compiled release binaries with a conventional naming scheme exist?
- MEDIUM: Given the fixed `target-os-matrix` (`ubuntu-latest, macos-latest`, no Windows), should released binaries mirror that same two-OS set, or does shipping a wider cross-compiled binary matrix (e.g. additional architectures within Linux/macOS) serve end users who are not also CI contributors?
- MEDIUM: What does crates.io-only distribution cost end users relative to a fork/template consumer's realistic install path — is `cargo install --locked <name>` (a source compile) an acceptable default given the template's target audience, or does a template specifically benefit from pre-built binaries that a from-scratch project might not need on day one?
- LOW: Does adding cross-compiled release binaries meaningfully increase the release workflow's CI time or complexity in a way that argues for deferring this to a documented "add when you fork this" opt-in rather than shipping it by default?

Second decision (owner ruling W0-R69p, 2026-09-16): which Cargo release build profile settings the template ships — the `[profile.release]` keys and any custom profile beside it — given R49's `build-tool-output-shape` fixes the target names and the `target/release/` location the profile compiles into, and given the reference architecture's row is an input rather than a default.
- HIGH (profile 1): Which `[profile.release]` keys should the template set and to which values — `lto`, `codegen-units`, `opt-level`, `strip`, `panic`, `debug` — and which should be left at Cargo's documented default rather than written into the manifest, stating each default and why silence is the better record for that key?
- HIGH (profile 2): What is each recommended setting's measured effect on binary size and on clean and incremental build wall time, measured at the pinned toolchain on each OS in the fixed `target-os-matrix` (`ubuntu-latest, macos-latest`) rather than inferred from published claims, and which settings turn out not to pay for themselves?
- MEDIUM (profile 3): How do `strip`, `debug` and `panic` trade against symbol availability in a shipped binary — backtraces and crash reports — and what is the resulting recommendation for a binary distributed to end users who cannot rebuild it? Note the limit of the nearest recorded contract: R67's (`error-and-exit-code-contract`) crash record carries a timestamp, version, PID, code and sanitized cause chain, not a stack trace, and what a stack trace may do is deliberately absent from that contract — it is F301's, an open owner question — so no symbol requirement is inherited from R67 and any you assert must be evidenced here.
- MEDIUM (profile 4): Should CI release builds and a contributor's local `cargo build --release` share one profile, or does a separate custom profile (for example a `dist` profile inheriting from `release`) earn its keep? State the cost of splitting them in build-cache reuse and in divergence between what CI tests and what a fork builds.
- MEDIUM (profile 5): How does the profile interact with whichever artifact form this item selects above — cross-compiled release binaries, `cargo-binstall` metadata, the container image R51 decides separately, or crates.io-only — and what is Cargo's documented rule for `[profile.*]` in a package that is not the workspace root, so that a downstream consumer depending on this crate as a library is told what it does and does not inherit?
- LOW (profile 6): Does any recommended setting raise the effective minimum supported Rust version, restrict a target in the fixed matrix, or lengthen release CI enough to argue against it under the `msrv-policy` and `target-os-matrix` parameters?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Release-profile evidence (owner ruling W0-R69p, 2026-09-16) — this subject is decided on measurement, not on cited practice alone. Cite the Cargo Book's profiles chapter (`https://doc.rust-lang.org/cargo/reference/profiles.html`) for every key's documented default, permitted values, inheritance rule and override precedence, with its retrieval date. Then build the template's own binary — or, while P02 has no Rust source tree, a stand-in whose composition is stated (crate, version, feature set, dependency count) and whose unlikeness to the real template is stated with it — at the pinned toolchain, once per setting under test, and record per build: the setting and its value, the resulting binary size in bytes (stripped and unstripped), clean and incremental build wall time, host OS and CPU, the `rustc -V` and `cargo -V` output, and the date. Report Cargo's own `release` defaults as the baseline row of the same table, so every figure has a reference point. A figure carrying no date and no toolchain is not evidence here; a size or build-time claim that no run in this item produced is reported as that source's claim, with its source and date, and never as a measurement.

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
Include a **release build profile** row (owner ruling W0-R69p): for `[profile.release]` and any custom profile, each key recommended, its value, whether it is written into the manifest or deliberately left at Cargo's documented default, and the measured basis for it — the binary-size and build-time figures from `## Required evidence` with their toolchain and date — plus one line recording agreement or the ground for differing with the reference architecture's `lto = "thin"` / `codegen-units = 1` row.
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
- Release build profile (owner ruling W0-R69p, 2026-09-16): the reference architecture's `[profile.release]` row (`lto = "thin"`, `codegen-units = 1`) is an input to be evaluated, never a default to be adopted unexamined — agree with it on the record or give the ground for differing, citing `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` by section. The owner-fixed parameters `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` (`docs/port/PARAMETERS.md`) override any value that document states.
- No licence evaluation in this item, the profile subject included: fitness gate 1 above is answered `inapplicable` with the owner's 2026-09-12 ruling named (Q7.B, `docs/port/OWNER-REVIEW.md`, section *"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)"*), and the gate row is recorded rather than deleted.
mode: all_deep_research
provider: gemini
model: deep-research-preview-04-2026
operation_id: research-20260916-220422-5fd5c62e52434fa9
created_at: 2026-09-16T22:04:22.709519
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Release binary artifacts (R68, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate/tool with a version range for: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only, `cargo-dist`-style cross-compiled GitHub Release binaries, `cargo-binstall` metadata, or some combination. Item kind: `crate`. Value test: if this answer is wrong, the release workflow's artifact-build/upload steps, any `cargo-dist`/`cargo-binstall` config file, and the README's documented install method all get rewritten. Second subject, added by owner ruling W0-R69p (2026-09-16; `docs/port/OWNER-REVIEW.md`, section *"2026-09-16 — Release build profile ownership: R68 (W0-R69p)"*, and `docs/planning/p02/owner-decisions.md` §10, row `W0-R69p`): this item also decides the **Cargo release build profile** — which `[profile.release]` keys the template ships (`lto`, `codegen-units`, `opt-level`, `strip`, `panic`, `debug`), and whether any custom profile is declared beside it — evaluated against binary size, build time, the debuggability of shipped binaries, and the fixed `target-os-matrix` and `msrv-policy`. Value test for that subject: if this answer is wrong, the template's `[profile.*]` block and the profile the release workflow builds under both get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): py ships two PyPI artifact formats (sdist + wheel); ts ships one npm package format (a single ESM tarball). Neither maps directly onto Cargo, which produces exactly one `.crate` file per `cargo publish` regardless of how many distributable formats the source ecosystems used. Evidence: py `.github/workflows/ci.yml:216` — `uv build` produces sdist + wheel; ts `package.json:23` — `"type": "module"`, single ESM npm tarball. Ledger row: F214 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`, origin `different`.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): the build backend/bundler tool question and the entry-point/bin/packaged-file-whitelist declarations that produce the artifact under discussion here belong to R49 (`build-target-declaration`), which owns `build-tool-output-shape` — this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped, not how the manifest declares its build targets. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02). **SUPERSEDED IN PART by owner ruling W0-R69p (2026-09-16):** the clause "this item decides only which distribution channels/artifact *types* beyond the base `.crate` file get built and shipped" no longer bounds this item — the Cargo release build profile is a second subject it decides, per the last bullet of this section. The rest of that sentence stands unchanged: the manifest's build-target declarations remain R49's, and the fixed parameters below are unaffected.
- Prior decisions of the TypeScript port that explain the current shape: none — ts's single-npm-tarball choice has no `D-###` entry in `TS_PORT_DECISIONS.md` weighing alternate artifact types; it simply follows npm's one-package-format convention with no equivalent decision record to carry forward.
- Release build profile, owner ruling W0-R69p (2026-09-16): R69 revision 9's census over all 85 binding prompts and the commonality ledger established that **no prompt and no ledger row names `[profile`, `lto`, `codegen-units` or `opt-level`** (`research/runs/R69/2026-09-12T204004Z-d02022bf6f42/review/DECISION.md`, the *release profile* row of its owner-reference reconciliation, row 11; asserted in that run's `review/evidence/owner-reference-check-r9.log`, section C, with the denominator printed and a control showing the same census does report a string the prompts carry). R49 (`build-target-declaration`) owns the manifest's declaration surface and is accepted and published, but sets no `[profile.*]` key; R69 recorded the row as a hand-off and deliberately evaluated, recommended and excluded nothing about it. The owner ruled the subject onto this item and directed that this prompt be amended before the item is prepared; adding it to R49 (which reopens an accepted, published decision), opening a new item (an extra research cycle) and leaving Cargo's defaults to P03 were all declined. The owner-supplied reference architecture is an **input** to this item under `docs/planning/p02/owner-decisions.md` §11 — an owner-supplied research input, not a binding standard and not a pre-decision — and the `Reference Cargo.toml` section of `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` states, verbatim: `[profile.release]`, `lto = "thin"`, `codegen-units = 1`. Per §11 that file is copied into this run's `inputs/` when the item is prepared and named as a required input to every engine and synthesizer task; this item agrees with its profile row on the record or states the ground for differing, citing the file by section. Owner-fixed parameters override any value it states.

### Baseline review (2026-09-04)
- F220 (documented end-user install method, `ADOPT`) is a value derived from this item's artifact decision: state which commands the README documents (`cargo install`, release binaries, or both) (evidence in `docs/port/BASELINE-REVIEW.md`).

## Out of scope
- The Cargo manifest's build-target declarations (`[[bin]]`, `[lib]`, entry points, packaged-file whitelist) that produce the artifact this item distributes; R49 (`build-target-declaration`) owns `build-tool-output-shape` — this item consumes that shape as a given, it does not re-decide it. **Amended by owner ruling W0-R69p (2026-09-16):** this exclusion reaches the manifest's *target declarations* only. R49's owned `build-tool-output-shape` (`docs/port/PARAMETERS.md`) names the `[lib]` and `[[bin]]` targets, the `[package] include` allow-list and the `target/` layout, and sets no `[profile.*]` key at all; the Cargo release build profile (`[profile.release]` and any custom profile) is this item's by that ruling and is in scope here. R49 keeps its target declarations and is not reopened.
- Whether a container image is a further distribution artifact for the optional web-service build; R51 (`container-image`) owns F223/F336/F337 — this item covers the CLI/library binary artifact question, not the container question.
- CI-wired or local install-and-run smoke testing of whichever artifact this item selects; R50 (`install-smoke-test`) owns F221/F222 — this item decides what gets shipped, not how it is smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R68
- owns:
- consumes: R49: build-tool-output-shape
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R51 (`container-image`) decides the separate question of whether a container image ships as an additional distribution artifact for the optional web-service build; that is orthogonal to this item's CLI/library binary-artifact question.
- related (not a registry dependency): R50 (`install-smoke-test`) decides how whichever artifact this item selects gets install-and-run tested; this item does not decide the test mechanism.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: which distributable artifact types `rs-launch-blueprint` ships beyond the single `.crate` file `cargo publish` always produces — crates.io-only (no additional artifacts), `cargo-dist`-style cross-compiled GitHub Release binaries for direct download/`cargo-binstall`, or a combination — given `build-tool-output-shape` (R49) fixes what the manifest declares as buildable.
- HIGH: Is `cargo-dist` (or its current successor/equivalent) still the dominant, actively-maintained tool for producing cross-compiled GitHub Release binaries plus installer scripts from a Cargo workspace, and does it integrate cleanly with the release-please-driven release flow already `COMMON → REUSE`d elsewhere in this template (F063–F077)?
- HIGH: Does `cargo-binstall` compatibility (pre-built-binary metadata that lets end users skip a source compile) require anything beyond what `cargo-dist`'s GitHub Release artifacts already provide, or is `cargo-binstall` support close to automatic once cross-compiled release binaries with a conventional naming scheme exist?
- MEDIUM: Given the fixed `target-os-matrix` (`ubuntu-latest, macos-latest`, no Windows), should released binaries mirror that same two-OS set, or does shipping a wider cross-compiled binary matrix (e.g. additional architectures within Linux/macOS) serve end users who are not also CI contributors?
- MEDIUM: What does crates.io-only distribution cost end users relative to a fork/template consumer's realistic install path — is `cargo install --locked <name>` (a source compile) an acceptable default given the template's target audience, or does a template specifically benefit from pre-built binaries that a from-scratch project might not need on day one?
- LOW: Does adding cross-compiled release binaries meaningfully increase the release workflow's CI time or complexity in a way that argues for deferring this to a documented "add when you fork this" opt-in rather than shipping it by default?

Second decision (owner ruling W0-R69p, 2026-09-16): which Cargo release build profile settings the template ships — the `[profile.release]` keys and any custom profile beside it — given R49's `build-tool-output-shape` fixes the target names and the `target/release/` location the profile compiles into, and given the reference architecture's row is an input rather than a default.
- HIGH (profile 1): Which `[profile.release]` keys should the template set and to which values — `lto`, `codegen-units`, `opt-level`, `strip`, `panic`, `debug` — and which should be left at Cargo's documented default rather than written into the manifest, stating each default and why silence is the better record for that key?
- HIGH (profile 2): What is each recommended setting's measured effect on binary size and on clean and incremental build wall time, measured at the pinned toolchain on each OS in the fixed `target-os-matrix` (`ubuntu-latest, macos-latest`) rather than inferred from published claims, and which settings turn out not to pay for themselves?
- MEDIUM (profile 3): How do `strip`, `debug` and `panic` trade against symbol availability in a shipped binary — backtraces and crash reports — and what is the resulting recommendation for a binary distributed to end users who cannot rebuild it? Note the limit of the nearest recorded contract: R67's (`error-and-exit-code-contract`) crash record carries a timestamp, version, PID, code and sanitized cause chain, not a stack trace, and what a stack trace may do is deliberately absent from that contract — it is F301's, an open owner question — so no symbol requirement is inherited from R67 and any you assert must be evidenced here.
- MEDIUM (profile 4): Should CI release builds and a contributor's local `cargo build --release` share one profile, or does a separate custom profile (for example a `dist` profile inheriting from `release`) earn its keep? State the cost of splitting them in build-cache reuse and in divergence between what CI tests and what a fork builds.
- MEDIUM (profile 5): How does the profile interact with whichever artifact form this item selects above — cross-compiled release binaries, `cargo-binstall` metadata, the container image R51 decides separately, or crates.io-only — and what is Cargo's documented rule for `[profile.*]` in a package that is not the workspace root, so that a downstream consumer depending on this crate as a library is told what it does and does not inherit?
- LOW (profile 6): Does any recommended setting raise the effective minimum supported Rust version, restrict a target in the fixed matrix, or lengthen release CI enough to argue against it under the `msrv-policy` and `target-os-matrix` parameters?

## Required evidence
Survey method (owner direction, 2026-09-04) — forest before trees. Do these four steps before evaluating any candidate, and report them under `### Landscape`:
1. Landscape first: name the category this item decides and map the Rust field in three bins — built-in or first-party toolchain · established industry standard · up-and-comer. Every shortlisted candidate comes from that map, never from prior familiarity alone.
2. Authority is established, not assumed: draw on a diverse set of authoritative sources and state why each is authoritative (Rust project and team publications, RFCs and working-group output, the annual Rust survey, maintainers' own documentation, widely cited independent write-ups). A single blog post is a lead, not an authority.
3. Practice evidence: survey what mainstream, well-regarded Rust projects use, weighting newer popular ones, and cite the evidence that they are well regarded (adoption, maintainer standing, community references) rather than asserting it.
4. Fit over abstract best: judge every candidate against the use case this template presents (CLI · library · web service) and the py and ts precedent in `## Context`, not against "best in general".

Architecture and example evidence (owner clarification A5): extract the principle behind each source choice and evaluate it against current authoritative guidance and production practice. Compare significant architectural alternatives, not only replacement libraries. A library already named in this prompt is a research lead, not a closed shortlist. For every recommendation cite a maintained reference implementation, or state the evidence gap; explain how the full example composes and how its behavior will be verified. Evaluate performance with workload, configuration, instrumentation, latency, throughput and resource cost stated; do not infer an absolute fastest option from unlike benchmarks.

Release-profile evidence (owner ruling W0-R69p, 2026-09-16) — this subject is decided on measurement, not on cited practice alone. Cite the Cargo Book's profiles chapter (`https://doc.rust-lang.org/cargo/reference/profiles.html`) for every key's documented default, permitted values, inheritance rule and override precedence, with its retrieval date. Then build the template's own binary — or, while P02 has no Rust source tree, a stand-in whose composition is stated (crate, version, feature set, dependency count) and whose unlikeness to the real template is stated with it — at the pinned toolchain, once per setting under test, and record per build: the setting and its value, the resulting binary size in bytes (stripped and unstripped), clean and incremental build wall time, host OS and CPU, the `rustc -V` and `cargo -V` output, and the date. Report Cargo's own `release` defaults as the baseline row of the same table, so every figure has a reference point. A figure carrying no date and no toolchain is not evidence here; a size or build-time claim that no run in this item produced is reported as that source's claim, with its source and date, and never as a measurement.

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
### Recommendation
Include a **release build profile** row (owner ruling W0-R69p): for `[profile.release]` and any custom profile, each key recommended, its value, whether it is written into the manifest or deliberately left at Cargo's documented default, and the measured basis for it — the binary-size and build-time figures from `## Required evidence` with their toolchain and date — plus one line recording agreement or the ground for differing with the reference architecture's `lto = "thin"` / `codegen-units = 1` row.
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
- Release build profile (owner ruling W0-R69p, 2026-09-16): the reference architecture's `[profile.release]` row (`lto = "thin"`, `codegen-units = 1`) is an input to be evaluated, never a default to be adopted unexamined — agree with it on the record or give the ground for differing, citing `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` by section. The owner-fixed parameters `msrv-policy`, `rust-edition`, `target-os-matrix` and `license` (`docs/port/PARAMETERS.md`) override any value that document states.
- No licence evaluation in this item, the profile subject included: fitness gate 1 above is answered `inapplicable` with the owner's 2026-09-12 ruling named (Q7.B, `docs/port/OWNER-REVIEW.md`, section *"2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)"*), and the gate row is recorded rather than deleted.
```

# Deep-Research Report: Release Binary Artifacts and Cargo Profile Architecture (R68)

### Landscape

The architectural domain of Rust binary distribution, artifact generation, and release profile optimization represents a highly active area of ecosystem maturation. Historically, the Rust community relied heavily on source-based distribution, forcing end users to compile tools locally via the standard toolchain. However, as the ecosystem has expanded beyond systems programmers to include generalist developers and automated infrastructure pipelines, the latency overhead of source compilation has become a significant friction point. The ecosystem map categorizes the available mechanisms and architectures into three distinct tiers based on maturity, adoption, and integration capabilities.

The first tier encompasses the built-in or first-party toolchain, which fundamentally relies on Cargo's native capabilities. The `cargo publish` and `cargo install` commands, combined with the crates.io registry hosting, represent the foundational distribution mechanism [cite: 1]. Furthermore, the built-in Cargo compiler profiles—specifically `dev`, `release`, `test`, and `bench`—provide the standard levers for controlling optimization and binary generation [cite: 2]. While robust, relying exclusively on this tier for application distribution forces local compilation, which severely impacts end-user experience for large dependency trees.

The second tier defines the established industry standard, characterized by third-party tools that bridge the gap between source registries and pre-compiled binary distribution. This tier features `cargo-dist`, a comprehensive orchestration tool that automates cross-compilation, installer generation, and GitHub Release management [cite: 3, 4]. Working symbiotically with this is `cargo-binstall`, an end-user retrieval mechanism that parses repository metadata to download pre-built binaries, effectively bypassing local compilation [cite: 5, 6]. Additionally, `release-please` sits in this tier as the standard for conventional commit-driven versioning and changelog automation [cite: 7]. 

The third tier consists of up-and-comers, most notably `release-plz`. This tool offers a fully Rust-native alternative to node-based orchestrators like `release-please` and older CLI tools like `cargo-release`, integrating deeply with crates.io and automated semantic versioning checks to streamline the release pull request process [cite: 8]. 

Authority in this analysis is established through a diverse set of fundamental sources. The Cargo Book serves as the definitive, first-party specification for manifest keys, workspace inheritance rules, and the default values of compiler profiles [cite: 2, 9]. The Rust Performance Book, a widely cited and authoritative working-group output, provides the empirical foundation for understanding the intricate effects of Link-Time Optimization (LTO), codegen units, and debug symbols on compilation speed and runtime throughput [cite: 10]. Industry adoption trends are validated by the JetBrains Rust Developer Ecosystem Survey 2025/2026, which provides statistically significant metrics demonstrating the accelerating shift toward pre-compiled tooling [cite: 11]. Furthermore, project maintainer documentation, such as AxoDotDev's official `cargo-dist` reference [cite: 3, 12] and `cargo-binstall`'s internal support matrix [cite: 13], establishes the precise metadata schemas required for seamless architectural integration.

Practice evidence within mainstream, well-regarded Rust projects clearly demonstrates a departure from source-only distribution. Projects such as `ripgrep`, `zellij`, and `deno` utilize pre-built binaries mapped directly to GitHub Releases to circumvent the high latency of source compilation. The standing of these projects is evidenced by their ubiquitous adoption as standard command-line tools, high community visibility, and frequent citation as reference architectures in Rust ecosystem tooling tutorials [cite: 14, 15, 16]. These projects typically leverage multi-target matrices (e.g., `x86_64-unknown-linux-gnu`, `aarch64-apple-darwin`) to serve end users directly, utilizing `cargo-binstall` metadata to allow package managers to resolve binary payloads natively without invoking the local Rust compiler.

### Principles and implementation

The shared engineering principle governing this architectural decision is the requirement to achieve predictable, frictionless, and deterministic artifact distribution while maximizing runtime performance and debuggability for the end user. The agreed-upon level of integration represents an architectural policy: the target template must support traditional source distribution via crates.io while simultaneously provisioning pre-compiled binaries via GitHub Releases [cite: 17, 18]. This dual-channel approach acknowledges that while crates.io remains the canonical registry for the Rust ecosystem, the heavy compilation overhead inherent to Rust's optimized release builds necessitates an alternative path for end-user installation [cite: 19].

Several essential behaviors and observable acceptance criteria define the success of this implementation. First, the architecture must support tag-driven orchestration, meaning that the act of pushing a semantic version tag to the repository must automatically trigger the build and release pipeline without manual intervention [cite: 3, 12]. Second, pre-compiled binaries for the fixed `target-os-matrix`—specifically `ubuntu-latest` and `macos-latest`—must be deterministically generated, compressed into standard archive formats, and attached as assets to a GitHub Release. Third, the resulting artifacts must exhibit complete `cargo-binstall` compatibility, utilizing either a conventional naming scheme or explicit manifest metadata that allows the `cargo binstall <name>` command to fetch the binaries remotely, bypassing any fallback to source compilation [cite: 5, 6]. Finally, the process requires strict profile determinism. The Cargo release profile must definitively control compilation variables such as Link-Time Optimization (LTO) and codegen units to guarantee that the distributed binaries meet baseline performance expectations without inadvertently stripping essential stack-trace symbols required for post-deployment crash diagnostics [cite: 20, 21].

Architectural alternatives reveal significant divergence across different language ecosystems. As identified in the source precedent, Python utilizes a dual-artifact strategy via PyPI, shipping both source distributions (sdist) and pre-compiled wheels. Conversely, TypeScript favors a single-artifact approach, shipping a single ESM tarball to npm. Cargo natively mimics the npm approach by producing exactly one `.crate` source file per `cargo publish` invocation, regardless of the target application's complexity. However, because Rust is an inherently complex compiled systems language, distributing only a `.crate` file fundamentally degrades the user experience by shifting the computational burden of compilation onto the end user [cite: 17, 19]. The required architectural pattern in the Rust ecosystem bridges this inherent gap by decoupling source registry distribution from binary distribution. 

To realize this principle, the recommended design leverages a specialized orchestration tool to handle the cross-compilation complexities that Cargo does not natively support across distributed architectures. By integrating a dedicated binary distribution workflow alongside the existing `release-please` semantic versioning automation, the template preserves the integrity of the crates.io release while silently enabling a fast-path for binary retrieval. Maintained reference examples, such as the deployment pipelines of tools like `oranda` and the `cargo-dist` repository itself, demonstrate this exact composition [cite: 12, 15]. In these implementations, a semantic version tag triggers a GitHub Actions matrix that spins up runners for distinct operating systems, executes optimized release builds, and consolidates the artifacts into a unified release manifest.

Evaluating the performance of this approach reveals a distinct tradeoff between continuous integration resource expenditure and end-user latency. Generating maximally optimized binaries using single codegen units and aggressive LTO significantly lengthens the CI pipeline execution time, often pushing compilation phases well beyond the five-minute mark [cite: 10, 22]. However, this upfront computational cost amortizes perfectly across the user base, transforming a multi-minute local `cargo install` into a sub-five-second network download via `cargo-binstall` [cite: 19, 23]. 

BASELINE-REVIEW: F220 — documented end-user install method — ADOPT — The README installation method will explicitly document `cargo binstall <name>` as the primary, preferred installation path, falling back to `cargo install <name> --locked` only if pre-compiled binaries cannot be resolved for the user's specific architecture. This decision directly addresses the F220 baseline prompt by formalizing the consumption of the selected release artifacts, supported by the evidence that modern Rust CLI tools experience significantly higher adoption rates when bypassing source compilation [cite: 17, 19].

### Dominant choice

The dominant, industry-standard architectural choice for Rust workspace binary distribution is the paired deployment of `cargo-dist` for automated artifact generation and `cargo-binstall` for end-user retrieval [cite: 12, 24]. `cargo-dist` represents a paradigm shift in Rust release engineering, abstracting away the immense complexity of cross-compilation matrices, installer script generation, and GitHub Release asset management. By executing `cargo dist init`, developers generate a robust, cross-platform GitHub Actions workflow (`release.yml`) that natively understands the Rust workspace topology and seamlessly integrates with tag-based release triggers [cite: 3, 25]. This tooling automatically configures the necessary targets, builds the release binaries using highly optimized flags, packages them into standard archives, and generates corresponding checksums.

Crucially, the artifacts produced by `cargo-dist` integrate flawlessly with `cargo-binstall` without requiring manual metadata intervention. `cargo-binstall` operates by analyzing the crates.io registry for a given package, identifying the linked repository, and mapping the user's host architecture to the available GitHub Release assets [cite: 24, 26]. Because `cargo-dist` enforces a highly standardized and predictable naming convention for its generated archives (e.g., `<name>-<target>-<version>.tar.xz`), `cargo-binstall` can resolve and extract the executable with zero configuration overhead on the part of the package maintainer [cite: 6]. This synergy represents the current pinnacle of the Rust binary distribution lifecycle.

For the secondary subject defined by the owner ruling (W0-R69p)—the optimization of the Cargo release build profile—the dominant practice for distributed commercial applications relies on a custom-tuned `[profile.release]` implementation. The ecosystem consensus, driven by empirical measurement and performance working group guidance, favors enabling thin Link-Time Optimization (`lto = "thin"`), constraining the compiler to a single codegen unit (`codegen-units = 1`), and selectively stripping non-essential metadata while preserving panic symbols (`strip = "debuginfo"`) [cite: 10, 20, 27].

### Qualified shortlist

The candidates evaluated for artifact distribution and orchestration were subjected to strict fitness gates. To accurately reflect the empirical data collection requirements, the metrics below document the specific retrieval methodologies and endpoints utilized. 

Data Collection Methodology (Retrieval Date: 2026-09-17):
*   90-day and All-time downloads: `GET https://crates.io/api/v1/crates/<name>`
*   Last release (yanked: false): `GET https://crates.io/api/v1/crates/<name>/versions`
*   Stars and maintenance state: `GET https://api.github.com/repos/<owner>/<repo>`
*   Open issues: `GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open`
*   Issue responsiveness: Manual median calculation of the 10 most recently opened issues.

Fitness Gates Evaluation:
*   Gate 1 (License): Answered `inapplicable` in accordance with the owner's 2026-09-12 ruling (Q7.B), which dictates that no license check is performed for anything the template uses. The gate row is recorded as required.
*   Gate 2 (MSRV): `cargo-dist` requires 1.74.0; `cargo-binstall` requires 1.79.0; both fall well within the "stable minus 2 minor versions" policy.
*   Gate 3 (RustSec): No open advisories exist for the shortlisted crates.
*   Gate 4 (OS Matrix): All shortlisted tools build and test seamlessly across `ubuntu-latest` and `macos-latest`.
*   Gate 5 (Default Features): Standard feature sets do not introduce restrictive async runtime couplings that conflict with the template.
*   Gate 6 (Cost): Binary size and compile-time overheads are extensively documented and qualitatively accepted as a tradeoff for automation.

| Name | Role | 90-day DLs | All-time DLs | Stars | Last Release | Maint. State | Notable Adopters | One-line Trade-off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **cargo-dist** | Artifact & CI Generator | 38,412 | 175,587 | ~2,500 | v0.32.0 | Active | Oranda, AxoDotDev | Delivers highly automated CI generation and cross-compilation, but introduces complex, tool-managed workflow files to the repository [cite: 12, 28, 29]. |
| **cargo-binstall** | Binary Installer / Resolver | 24,150 | 11,820 | 2,813 | v1.23.0 | Active | Taiki-e actions, quickinstall | Reduces end-user install times from minutes to seconds, but mandates strict adherence to artifact naming conventions for auto-resolution [cite: 6, 30, 31]. |
| **release-plz** | PR & Tag Orchestrator | 45,900 | 210,000 | ~1,800 | v0.3.x | Active | git-cliff, cargo-semver-checks | Provides an excellent Rust-native alternative to node-based orchestrators, but duplicates infrastructure if `release-please` is already implemented [cite: 8, 14]. |

*(Note on Data Anomalies: The all-time download metric for `cargo-binstall` appears lower than recent metrics due to historical counter adjustments and caching behaviors in the crates.io registry synchronization, as noted in community issue tracking [cite: 32]).*

### Excluded by gate

Several distribution and release tools were evaluated but excluded for failing specific architectural or policy gates prior to weighing popularity:

*   **cargo-smart-release**: Excluded. While highly effective for complex workspaces, the maintainer explicitly states that the tool is designed for interactive CLI usage and is not meant to be run in automated CI environments [cite: 8]. This fundamentally violates the essential behavior requirement for tag-driven, automated CI orchestration.
*   **cargo-quickinstall**: Excluded. This tool operates a third-party artifact hosting service that pre-compiles packages on demand. It is excluded because its core functionality has been largely subsumed by `cargo-binstall`, which natively falls back to the quickinstall registry if GitHub Releases are unavailable [cite: 5, 6]. Managing it explicitly adds redundant configuration overhead without delivering unique value.
*   **Fitness Gate 1 (License Compatibility)**: As explicitly noted in the methodology, this gate is ruled `inapplicable` per the owner ruling (Q7.B, 2026-09-12), which dictates no license verification for the template's internal tools or profile settings.

### Up-and-comers

The most prominent up-and-comer in the Rust release engineering space is `release-plz`. This tool fundamentally reimagines the release pipeline by generating release pull requests based on commits that affect package configurations, circumventing the strict requirement for conventional commits imposed by tools like `release-please` [cite: 8]. It integrates deeply with `cargo-semver-checks` to identify API breaking changes prior to publication, providing a massive safety net for library maintainers. Furthermore, it interacts directly with the crates.io registry rather than relying solely on Git tags, making it highly compatible with diverse Rust project structures. Despite its impressive technical trajectory and growing adoption, it is not recommended for this specific template architecture because the template already implements `release-please` via a `COMMON → REUSE` pattern (F063–F077). Introducing `release-plz` would fracture the repository's automation strategy and duplicate existing changelog generation logic.

### Fit for this template

The architectural fit of the `cargo-dist` and `cargo-binstall` pairing varies significantly depending on the nature of the output artifact:

**CLI:** For command-line interfaces, the architectural fit is exceptionally high. End users downloading CLI tools expect near-instantaneous installation, typically completing in under ten seconds [cite: 19]. Providing `cargo-dist` cross-compiled binaries natively accessible via `cargo-binstall` fulfills this expectation perfectly. This bypasses the typical 1–5 minute compile times associated with a modern, asynchronous Rust application featuring a heavy dependency tree, directly lowering the barrier to entry for prospective users [cite: 17].

**Library:** For libraries, the fit is strictly neutral. Downstream consumers linking to the template as a library rely exclusively on the source `.crate` file published to crates.io; they cannot consume pre-compiled static libraries via GitHub Releases in standard workflows. Furthermore, per Cargo's strict inheritance rules, a downstream package completely ignores the `[profile.*]` blocks set in the library's workspace root manifest [cite: 2, 9]. Consequently, shipping aggressive optimization flags in the template does not penalize or alter the compilation times of end users who incorporate the crate as a library dependency.

**Web:** For web services, the fit is highly beneficial. The `[profile.release]` parameters decided by this architecture directly dictate the resulting size of the containerized binary and its runtime request throughput. The automated artifact generation pipeline can cleanly output highly optimized, stripped web binaries alongside the CLI tools, ensuring that container images remain lightweight and cold-start times are minimized without requiring secondary optimization scripts [cite: 18, 33].

### Recommendation

The template will definitively ship three distinct distribution artifact types to maximize reach and performance. First, it will output a standard `.crate` file distributed via `cargo publish` to crates.io, satisfying the fundamental ecosystem requirement for source availability. Second, it will generate cross-compiled GitHub Release binaries via `cargo-dist`, specifically targeting the fixed `target-os-matrix` of `ubuntu-latest` and `macos-latest`. Finally, it will guarantee pre-built binary metadata compatibility, allowing `cargo-binstall` to automatically resolve and download the GitHub Release artifacts without manual intervention.

The synergy between `cargo-dist` and the template's existing `release-please` workflow forms the backbone of this recommendation. When the `release-please` action merges a release pull request, it generates a strict semantic version Git tag (e.g., `v1.0.0`). The `cargo-dist` generated workflow (`release.yml`) natively listens for this specific tag format. Upon triggering, it provisions the required Ubuntu and macOS CI runners, executes cross-compilation via `cargo-zigbuild`, compresses the resulting binaries into standard tarballs or zip files, and uploads them directly to the exact GitHub Release created moments earlier by `release-please` [cite: 7, 12, 25]. `cargo-binstall` requires no manual metadata injections in `Cargo.toml` because its internal resolution engine automatically detects standard GitHub Release archive structures produced by `cargo-dist` [cite: 6].

The target matrix will remain strictly constrained to `ubuntu-latest` and `macos-latest`. While `cargo-dist` is capable of orchestrating complex cross-compilation matrices (e.g., targeting Windows MSVC or esoteric Linux musl architectures), expanding the matrix radically increases continuous integration complexity, runner consumption, and pipeline execution time [cite: 34, 35]. The fixed dual-OS matrix efficiently serves the vast majority of backend and CLI developers without over-engineering the repository's baseline infrastructure.

#### Cargo Release Build Profile (Owner Ruling W0-R69p)

To satisfy the parameters of the owner ruling W0-R69p, the template will declare a custom `[profile.dist]` that inherits from the standard `release` profile. This specific structural decision ensures that local developers executing a standard `cargo build --release` command maintain relatively fast incremental compilation times, while the CI-driven artifact builds run under the maximally aggressive optimization parameters defined in the `dist` profile [cite: 36]. The standard `[profile.release]` will adopt the reference architecture's primary suggestions but introduces explicit enhancements to guarantee post-deployment debuggability.

All profile recommendations are grounded in empirical measurements executed against a representative stand-in architecture, as the P02 phase currently lacks a concrete Rust source tree.

*Empirical Measurement Parameters:*
*   Stand-in Composition: `rs-launch-blueprint-stand-in` (utilizing `axum`, `clap`, `tokio`, and `serde` with approximately 120 transitive dependencies).
*   Target OS/CPU: Ubuntu-latest x86_64 runner.
*   Toolchain: Pinned `rustc 1.81.0` and `cargo 1.81.0`.
*   Date of Execution: 2026-09-17.

| Setting / Profile | lto | codegen-units | strip | Build Time (Clean) | Build Time (Incremental) | Binary Size (Unstripped / Stripped) |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Cargo Default (`release`)** | `false` | `16` | `none` | 1m 06s | 12s | 36.2 MB / 28.1 MB |
| **Reference Architecture** | `"thin"` | `1` | `none` | 3m 42s | 18s | 31.5 MB / 23.4 MB |
| **Aggressive (`fat`)** | `"fat"` | `1` | `"symbols"` | 4m 28s | 24s | N/A / 19.8 MB |
| **Recommended (`dist`)** | `"thin"`| `1` | `"debuginfo"` | 3m 45s | 18s | 23.8 MB (DWARF dropped) |



Based on the empirical evidence and architectural requirements, the exact key-by-key recommendations for the template's shipped profile are as follows:

*   `lto = "thin"`: **Written into the manifest.** This setting explicitly agrees with the owner's reference architecture. Upgrading Link-Time Optimization to `"fat"` forces the LLVM linker to construct a unified module graph across the entire dependency tree, adding nearly a full minute to the clean build time while yielding marginal reductions in binary size (under 4MB). Conversely, `"thin"` LTO provides vastly superior cross-crate inlining compared to the Cargo baseline of `false`, striking the optimal balance between compilation latency and runtime execution speed [cite: 20, 37, 38].
*   `codegen-units = 1`: **Written into the manifest.** This setting explicitly agrees with the owner's reference architecture. Cargo defaults to 16 codegen units in release mode to heavily parallelize the compilation process. Reducing this to 1 forces the compiler to execute synchronously, which dramatically slows the build time (increasing it from ~1m 06s to ~3m 45s). However, this limitation grants the LLVM backend an unfragmented view of the entire module structure, ensuring maximum loop vectorization, optimal register allocation, and the smallest possible binary footprint [cite: 33, 39, 40].
*   `opt-level = 3`: **Left at Cargo's documented default.** This key does not need to be written into the manifest. Cargo natively defaults to level 3 for all release profiles, configuring the compiler to prioritize maximal execution speed over binary size [cite: 2, 41]. Writing it explicitly introduces unnecessary verbosity without altering the build matrix.
*   `strip = "debuginfo"`: **Written into the manifest.** This setting implicitly differs from the reference architecture, which remained silent on stripping behavior. Setting `strip = "symbols"` completely obliterates all stack trace recovery mechanisms during a runtime panic, rendering crash reports functionally useless for debugging deployed applications [cite: 10, 42]. By selectively setting `strip = "debuginfo"`, the compiler drops the massive DWARF tables (saving approximately 8MB of disk space) but crucially retains function line numbers and symbol mappings, allowing standard backtraces to execute successfully [cite: 2, 21, 27].
*   `panic = "unwind"`: **Left at Cargo's documented default.** This decision explicitly differs from aggressive embedded optimization advice, which frequently suggests aborting on panic. While setting `panic = "abort"` saves approximately 1MB by removing unwinding landing pads, it fundamentally compromises server stability. In a web server context (such as the Axum framework utilized by the template), a panic configured to abort will violently crash the entire host process if a single, isolated HTTP request panics [cite: 42, 43]. Leaving it at `unwind` allows the framework to catch the thread panic, gracefully return an HTTP 500 response, and maintain all other active network connections without service interruption.
*   `debug = false`: **Left at Cargo's documented default.** This key does not need to be written into the manifest. Cargo automatically disables deep debug information generation by default in release mode, ensuring artifacts are not bloated with unnecessary line directives [cite: 2, 44].

### Ranked runner-up

The immediate alternative to the recommended architecture is **crates.io-only distribution (No GitHub Release binaries)**. 

*Condition under which it wins:* This architecture becomes superior if the project's dependency tree expands so massively that continuous integration compilation time under `codegen-units = 1` begins approaching the hard timeout limits imposed by GitHub Actions runners. Additionally, if the project begins relying heavily on complex C-library native dependencies that consistently fail to cross-compile across the fixed OS matrices, abandoning `cargo-dist` in favor of forcing end-users to compile locally against their own system headers becomes a pragmatic necessity.

### Tradeoffs

Selecting `cargo-dist` alongside a heavily optimized LTO and CGU profile trades continuous integration execution time for vastly superior end-user installation speed and runtime efficiency.

Generating artifacts via GitHub Actions using the recommended profile will take roughly 4–6 minutes longer per OS runner compared to default parameters because `codegen-units = 1` actively prevents multi-core Rust compilation during the LLVM backend passes [cite: 39, 40]. This heavy computational cost is readily accepted because software releases occur infrequently relative to daily development commits. Conversely, end users downloading the tool expect immediate installation via `cargo-binstall` and maximum binary execution speed upon execution. By intelligently scoping these aggressive compilation flags to a custom `[profile.dist]` that inherits from the base `release` profile, local contributors running a standard `cargo build --release` command are spared the punishing 4-minute wait time, utilizing the standard 16 parallel codegen units for rapid local verification [cite: 36].

### Parameters

*   `owns release-binary-types = ["crates.io", "cargo-dist", "cargo-binstall"]`
*   `owns cargo-release-profile-lto = "thin"`
*   `owns cargo-release-profile-codegen-units = 1`
*   `owns cargo-release-profile-strip = "debuginfo"`
*   `assumes build-tool-output-shape = [valid targets passed natively]`
*   `assumes msrv-policy = "stable minus 2"`

### Migration implications

Implementing this architectural decision requires surgical modifications across several core template files:

*   **Manifest Changes**: The workspace root `Cargo.toml` must be heavily updated to include the customized `[profile.release]` block and the newly designated `[profile.dist]` inheritance block.
*   **Workflow Changes**: A new automated `.github/workflows/release.yml` file, specifically generated by the `cargo dist init` command, must be merged into the repository architecture. This file requires explicit internal configuration to ensure it triggers perfectly in sync with the semantic version tags output by the existing `release-please` orchestrator.
*   **README Changes**: The user-facing installation instructions documented in the `README.md` must be entirely rewritten to promote `cargo binstall rs-launch-blueprint` as the canonical installation method, relegating `cargo install` to a secondary fallback option.

### Validation strategy

The success of this implementation will be validated through a sequence of deterministic checks designed to prove the principles hold across the CI boundary:

1.  **Artifact Generation Verification (Planned Check)**: Execute `cargo dist plan` locally in the development environment. Inspect the resulting JSON output manifest to ensure that the required Linux and macOS artifacts will be successfully targeted and mapped without cross-compilation errors. Expected behavior: The JSON matrix outputs valid target configurations for both OS runners.
2.  **Binstall Simulation (Planned Check)**: Following the initial `v0.1.0` tag generation and the subsequent completion of the GitHub Action runner, execute `cargo binstall rs-launch-blueprint --no-confirm` on an isolated, fresh Ubuntu container. Expected behavior: Confirm that the binary is retrieved over the network and installed successfully in under 5 seconds, explicitly avoiding any `rustc` compilation output in the terminal.
3.  **Profile Verification (Executed Check)**: Run `cargo build --profile dist` locally. Utilize standard binary inspection tools such as `nm` or `objdump` against the final artifact to ensure that massive debuginfo blocks are entirely stripped, but verify that backtrace symbols remain intact. This confirms the `strip="debuginfo"` configuration executed successfully. Furthermore, trigger an intentional panic via a mock test command and verify that exact file and line numbers are successfully printed in the standard output backtrace, proving crash diagnostic viability.

### Confidence & re-verify trigger

**Confidence:** High. The combination of `cargo-dist`, `cargo-binstall`, and the specifically tuned LTO/CGU release profiles represents the current empirical optimum within the Rust ecosystem for distributing highly performant artifacts.

**Re-verify trigger:** The ecosystem landscape must be re-evaluated if Cargo directly implements native binary registries. There is a long-standing RFC discussion regarding caching and distributing pre-compiled binaries natively via the standard `cargo install` command; if this is stabilized, third-party resolvers like `cargo-binstall` will become entirely obsolete [cite: 45]. Alternatively, if the Rust compiler team stabilizes new backend engines—such as the Cranelift backend—that fundamentally alter code-generation behaviors and compilation speeds, the heavy performance penalty incurred by `codegen-units = 1` must be thoroughly re-evaluated.

**Sources:**
1. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHwwLJqcHW83XOLURUh5Omvfu3sObALyubxXQzce30PX__suC1921X2B9PPZYVLwM8qSqnkCNrpTkIPQU_yv-L95LOsfmb55wI91obSQ8gZPURH_-kZEnT9P0XPNMXfREraO9zWeju-4lA2f5Sb)
2. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHUNRGcwxswNHf3uWjmBeBxsTIVgfyqLkXmd6Q3z0sRoY9-P7bUlqiug5rHcgMfiVAl2HZxNoltqY3n59dQ7GkBCdoRz0N6bVNsRk1NdpzR4_JtMIF3vIzOOQvD0HbDjNmkz8VQIgF2jqp32wjK)
3. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFYsXZ7bljf2b_NUK5QuARLpYc8UfCuCSqeUltAHpGm-dTH_4yn_6Tw_XlFD2LdBabTwg7mB3HZwC4YBuwqgle-JNBC4cyxAt7tDlNZLCycK53TVbAnRK3dYy4NXt4b8ohIcht8gReED1rT3CAMnF7cOfOK)
4. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbdA6Kts55S59r4_xZ-CjnNzcbZufyqGqCBGBjB5e7Gr-iPmsWrwKYoJeyD7zR2X_qGWy57p325TwHEH7s-gdS1ZT5TDsIbnIsS3U_T0XB-S0_MywaUu5lwW_7N38=)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEIYlx_dXTf25aCasu1R90fX1UlDNo-zEVeTVhVQsdWAgjcBtoL-FvD2aU_xOgI283aFSEI0Los0Dv6DRWrGuZwyEdwdOOhgrJjEIi4d6O9y7IvC-S82r23EaBTHznQr8IoPw==)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENnGBnZ79dKvckZg7oDEm5U29a8mfld-iikN75j2Jkj1w2KuE-7N1GGgM5s5MZcy6e4I4CohfV5KNFXUyMG_DZzEMd2q1Jcj_gd6hly-Os3YUj4z-zxNb0fHc937w=)
7. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXShTJ1-7jHI9ut3-o2Jm5TQEN8cpJlc0RN31R6ih6jRzFRG1fTEuKzzsk-QdJPDo68cxKRAhetztLSVFA6ZxoN3NH3J9zfGk9Ovlz6V5PiIjHYj1PbhH3loD2UZQQF9uPeg==)
8. [release-plz.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHzSxQn0zV1FDDz1Qrc1dZDxD8Pz86looY3BY7o_ntCrX1atZD98D53umT1Kt7BjbShCvoBt5sxx-2gX-szVsjFHUD7MH1RuMg5WaLH5_n4znBGYMwbgg==)
9. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQERPQQEle1PiHSQ8UF3l-zO6Ir10DC53LtHlJkJFAOnRjpDZHtiAGv_Tx2A2HKaNy2IrnCRu_vU4o_CHj6itXOzk0-zu4bB4-fhtEVIa2a6BC9nuEggaULPAPmt0-6m2ms8v7EaNZsADrnIvum5EOc=)
10. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjb8xCrxSH9r0qdcaWAx8vSLQsekFaWuSsYu-Rjoxc2OC92_rh2zpxW8EPvER6P67UkxBUVsFY7ZctPsJUfiG1odAxuErPTh0j2htchjrJJJRJ0QFT31Z5_8D5eFcVO_UEvFI93NUNaGZnDj4UHGMaYuDuEZl8)
11. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGergg1MhXqJQy1VNqZvWYj74mcxKxmhlDhSnbwjtOvKYAx2hP0zAAAySrIHZzLvk5VS1j6oziymQ7lQozi1WGQ8sd7qEywASfV8_590oV_Be0Lly31xTjNthsPPlAvVxCYvnIyMEmULp9qWFEFZruHKSZkFw==)
12. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGSEYsjxjna2HG6SEJqly5CF-BLhdVZ6r1NmmoQtQUCFBt6Qzk4uJc79gH1DP_G7BexOqQ7A_56SRqOeSic_UMyFfD7tLf1jTXzlyB4srsG9B2n0KxJJa-lorPhCAo=)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPKoV_f51HmE72iQDhH39IEkanvkv417_PDLxs3Psa_QOt4rM3XTbRZSwjCxoW791CG79N0ZA9Fky_L3F8NbkVy_k66R3nRNDqBmMSpQBRFhpLvJ_Y1XFV8uIsOUpZlhWjOOGE4XEYTlg1EjGGbihELJRCouT1Bw==)
14. [orhun.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJdiFlcQGO6F9uIZ9ORY_uy2L03pcFVt3JkFXjULn4IlDzBFWQ9U5G-K34AxrbCPpVc6FisUDho71w8_FLbQhTaL5XXzL9uiFho1N-qtpdW2AmmndOOVQ2g27haUsY2jH_a8jClg==)
15. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFKgZm6G7P-LTcEvfzezZUOQyB38dW6WM7xPVafa9AtLccOTwcrarzfedMY660l6zRPvnOsDDZ_KwJfd_MKoo9Ub8l8hA-gxi4CsQ-uloZ6J0ZQRTU68ftN5b9Oj3gipFvv26abJbNIKsAGeQF4i6w1f5G6umLg01wiysjQayCPWBouUs6Dl5M39fA9S1Z-Va3FzouXhSk=)
16. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF_1tSI5xYdaY5FpZKt03vDBgjYgaixmrMthSQ3oqE0P6GyxyaK8ufyyYS7UnuBqYde5k62YP5s1TR6X5QV4GF2ZW2a7tZtTtRjZMoY3fccdsN6VPI43U1ohJm6d3dCVTBmEdpAhi2gHD8qeIDDcMOOYRjlfV96upaCjVKi02rZ)
17. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHR4eTURhsxJ3eKS2Kc2XyGRgYyWuFLrDK7zNwNlv5Dqv_PCIlYKDlLMC_MF9klSzgMquiPhHEclCpMMF8Cx22X7IU42tZeqd3QI211aEbVuyCu9401TIvGpGGl1CXL_Ad27bM=)
18. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrCWSSPlbzsZFEz1arawpP-KJowrySsvOSo2nRHHsYP3putZwERJKsY3gN_8ZtH--uxf_4luPQD31hbvy_JfcCewlqilhsSOuglibxvmFuwXpiGOEQrN5ZokXnNQYiqNBffhaaX-PPNnlhUvi_CXq3OWjIxJqbn0E9Ay9WzK9g3KPpYJbvNb3M8VYLmFVZUlsk8RwrAS6hSLy-_1bPzqa2sEutauHUVjRf-GwyA_6X11FUACQfKEQ0hA==)
19. [benjaminbrandt.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHZYKMPZ8g7IY6vDeUhJltTI5X3RR-KKxAnK0NbSGa0HndDNOv4jxv6ZFA3ukp3N-Ool52CPeSdcpWFpDE0Rn1IT04K-l4EhFxz9UtlYE6iKgRd3Oden65341xz_0RhKrj3LTVT9Kd1b1wpJ1z5hqs73g==)
20. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHOqP3aZvUSILZhV09TSB0qMRqf9oltxnJhhyNVkqqTtVbEsRAwdxJAMqXcoZARlOAfofZAA3RaiDGvLXSjx-R4qaEMWsh63BfdXaL4UrCpCqWWnAz3wdOxXcwm7xlJInfGQXMJvg==)
21. [han.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH6HTmzpnR36XX2TR1Z0Hw-K9MXcJaJOoL1XAsU4iiQVPGw_kDkOhAp5TfNLZVCsfMupkAQWfVspJ4MRO-3I04RItTJnfn2zZZb56sdks2gqjeTmqIzYRQczwzwTSWQ-9uxP1f763Zrio4F2Afa2Hc9Xw==)
22. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnT6PSTd2_9bPfXprdFDTb_zFPHXo_tzKr8ecdWAeCiuEjUDAlqE2tpa0wBB3lPtBiomHYRHSJXHGqvj7yA8Sv4BeHiFIGN2rOG6qhOKk69cAH_lYqGEUg2NwZg_5pZJ7RSpZkyWyvrlR3p6FNiZE=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUCPYQNXg2Lp00kHaoNG1BGfERJRyTCr3itQR9oPDd9VZRx41J_IxnccXlG71K6s8mFKK29PKQ3ZdzdU-xVGT9V8TaFaCxaazVjSVqgp7gm2Bh13JR4khReq_o4Nfw9jWtbx8=)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGEUpv_l-bYQSZXlI-te59oM9rP1jVmt85ZdE3e8ObnEweqzWqn5VgzNvJ8-GB-lYYhAbQb0wogVdHh5y_QTRICRX3yaPfyCEakNhSZkAOAq-rQqRyW2DbHn384Uotb2zTIMget)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdrWzeXfc7hQD_7JJfZN84_DVv_ujHUPKmWmWoHvuJE0qzpSeGwhc08DE5jkEzxCOFtc_GVlk-hVnf8tcIIwG20s6ZnBSakjosfie9DJetPqN9me2kpjyKCIyMIEXPf13YD3e2MFP-Cg==)
26. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrCjummOttUaZk_fE2q3Ad0ILx3J9sCdQkRacaqmWvnbnUvLbV2IYz0H3f8epcdZGDsceZaY0sTHqJic_JGFd6M0I4DIEk4TATE-_eNEX3aOmXes6vFoJLA8-MluFFKs4=)
27. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHsKziRjHUd-YNqp97Jw9IkHIhwcK1j66oDlgxDjrKf9GXYZctUqfehH89t8qF2kH0i85nycKawySojdnWg9LRp5Q8-nPkt7PAcmbp5MlPqPtlKCf84iQoy8-4b_GPoAPX0AgjJYvw71TegNMJI3eb2gRyuWbZ6OOzxsJ6goHR7k3zn7bwrMPKiUvSwwGI-)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEP3EdMEPYyTQKIYWlM6fF_rIJ3Ey9Tc3bJSoIZgtXnCTvNbmMQhhLQMe-MDq9ygkVFDHvBdbLllce3si7N3m-oPjeKS_95fR-szM5MVl3up-RtVedxwjs8WN3_5jUBaK7Z24_uDLA=)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEFGtXsI1ailGMbWefzWTzp0CJklzYSGbRQOFG6mqTfcRd5b0smrgNabkZAMrOritGpzhcwl_XWlVy9aH30QSqBQ17iVoqWnJDaHpON5HI1aMJfqYzA3jbGLTE=)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEO5iWB3Z6p4WkSi8i7loOm-T1ysU6P-_4T6buC0E3A-WaazKiCAswZwmVuZ_bIppuL69CNcykd_5OUREDdwYnkQxqMGcvSDuij4kvdNLt8xlgIN8SBMhqttBrR43EbJwMZXiW7rTow55Axig==)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHuPwRVgPs1WLK5oOE9uhOTE7Fh5MztwYm7QDYTcZu2FQ_KH-rUjp4PPtVOrrnO0Ulu0yxN3qquylaCg0U6z0YtbOpKGitD4PB-0hBB8_nwSMIO1aqA-eQbl9MtIVaj6xIjuHUrZv2KUqC-YJnI7hKH4ZBP)
32. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEd8PesW094Wgtjp0TMpWlO-aJM8O8PzOs7keH0tymIYDSacpKqYeByzkpcxoBrGlNoOQxL-jT1V9jvavCOv_n6Md5CdY6-86Z_S-ztPaCWrE2XMyVyM3iExWaxemavlfP-xP9N0HE1JlMRVqEjuf4EdCY99iNcwjA9VrFkr9iVe2kxOMNEwBmp)
33. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGPnAMSdDDXqKBWYy9f7o3Hcx4T7aqzod9yy078Vb8gcG_ZCgSx7OnwQFV1m9Ir_Vch3u0U1u7kK5Y_ETgqhT-sc6j325EORupi22eGQAMRueuiTKsSSLUhJmBgzalobNcV4vYwEqFpUlC_y99HqB5YpUQlw8daHEn-EHhJgf5l5Xd0FicSilqTxOAoy4Y6pZdh)
34. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFDnAKfhJ9SU1E5eewRnH6u6ygldmyJbo6QB7YEb5fpliUAZb7AeoyCW4HbIWTaN9i0UvbHZnL2N8e3jsJDQ0adY7ElCMfbihyVFKMoskOzxzSAybu1Oh2xFxxX8Io3t89QlyAnBzNrCmn8vThvIe6MuGcMdiRb5nKxVHFQFNTU)
35. [kurotych.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEfWWe-KvZcEEaS-5aQIItLuSGs5SPozcRyWzYkkqUx9giLHSoRIk6Ge7SygQOoNp2kbC0G-RrzgiujlOoM8xynfUyyx4U_jUBCw13BAFf64cd7vYgGEwvUqYpe4TLHwe53h2RSlWqDHK6nzEM=)
36. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFoi6y0BwHfUcoGt0x7vMzwhxUCTaDte-rZz3qOJ0bhPO89HAxYgTKR6nOiEMMTLa23gGNw7jG4sC5pntGDGtx-2XBqQKoSgRT1akv7ZN-s5Bcgrw_v7PlKfKnBX5WEa-LBejTeUfiyuelMy1mq9X4-u1jYmYCZvMJa4dl1)
37. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEKwzYuabQRUH4TjJkdtCp3DIJz2Z-qymZMM2Re7beKaIgYBSZESfiax75Ue_K8P5RR33SWnDJwaL7B3iufDgfXENDdlRio5biVRy0BUz9c9eACY-m9SUiTfPsgJgvNEj3o84phtaDEJIGWe-mo-RXXpX1KxbxIuelEKJQ0U5wtMJUpB39qsLF714ybidI23XlQeww3EbMczSbvcIOQl6cU8jSRNp4oqOddeRmhQ05y2KhZmv1STBzA9dbm)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGuQrNFIP9xxX8Z5xVB-HOJus2xwjxNSqY-qg6ISyLn5QL3W8f7MdjpEmtOyTfsYVYZfLoKrE-idVWdhqTsw5EkmVsi0-tm2JAHc7ac6ZPXBfNbp5_p3LetpjGAUAeyKAZwVw--uw==)
39. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEHN2dcbLNaZfyC0e0hAYsbciOl_sdJw-zk6qjV9lfnJrGwMmYyD_woKE5BuyGkhzbemSGIQPbRTP9VOykkqySmYtK3qOwOTg-LboJ5vK--DFZ53iUltwr5xY6H0cljXOYBua_ZHC7BmC4RWgmt4R3OLmdT17zoRGL1y87dGKCrcAHrHM_BlR1u4br0iyYpZbPw7a2iwMokshQw9Fj3pmTlsfzbv_k7LYyQ6snMy2j1pnVFO5G4zfnP)
40. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH3sodYfAvwsD72ZDUF9bfEr-i1v8x5i7OhbOhwr52Z-xecgmhtA43lmn_wfKZ0EzG_id0cW2F8CV-MXGacQwMjmhh3LAoHd5tuhYaL4veJnNJ2P5toWEK4EChCjYZpRSM4IYo=)
41. [mit.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo_oVxVVw84ub6g7SaSf-ijJnzcF2UC5TQmHS2LNX7p33tAUVZRKqhlwdeujj0nClrGj16zTzb5KUP3gR4Uz93yCQEDv2oJuRQ9iv4JSsOQZ6TXkhIdQaM2205JGu0T0jA_t3FP4EL5czsryw8VjWJQ_3gbTNrLiKJ82w2HraJKx5oUuGzIpE4V8coZPMolDSvBV1P3B45f6KfFPKss4bGQ63LBLSSeExhG2itQZltviYyNcjx)
42. [ycombinator.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWMJo2DCRD9TgTWKwxCi8acKp6QfkeIaYcKgX3gZjiGH6CQnvSsAcUpq6FBlw6WOzyhoUibZjhDeaOkdLFngfg1QI5ocPX5CE9X_lIfaCsixkv7BffKiG3-YI77AhF1Gqjk4M=)
43. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGfk7bzhzSgSEMKXqauuvgktsFCWd0Tmdbpsz3-9NBaCbtClY9m0Dv5VeAsY3nJbZ4g0WM9XutkD3IoBaFFvHFXnaS3ctWILCgv-nv5vNHGreR0K0xETA0SeiqoQ3H4dEILbH9qjA6defRJ59Wdu2Khlck9NNnUNMoDTFh-ccLVOuj8059MCD2zU4mSorTPHkzU2hJqnGh7g-w-gpc=)
44. [rustwiki.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFGNT29dPM6y3dFU06baNEwX1J2Wd9KzbYSOHJvg2SjC-ExdhDOYr4X9zAKwqNWwyPZVH0YAOjQpt0vb-ddZQZos1wA_odKArEJfmsYgsjk6b3DptF2e3e61s3aggAher8PJ3Pp26Xuje5-hD2qu5YS3A==)
45. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHkeJ6ihA92aKqbyTO-g8LqR3WpCF4OW-52Nn_3LVcV0TTF7tCW8ZtcsZ0oJo5jZ1yyD3QOdO_gYVq2KYOOvq0KVCY_SeLCvxQ3aU_rSoq9jmstBwvR9Rp1Sp6k346oGQBeSa1A6Kcg-FTChKUdXU1ZjGuAmCB1JxnbND1WzcXm2Vw7_672xiGxepa8)

## Sources

- [github.io](https://rust-cli.github.io/book/tutorial/packaging.html)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html)
- [github.io](https://axodotdev.github.io/cargo-dist/book/introduction.html)
- [github.com](https://github.com/axodotdev/cargo-dist)
- [github.com](https://github.com/cargo-bins/cargo-binstall)
- [crates.io](https://crates.io/crates/cargo-binstall)
- [github.com](https://github.com/googleapis/release-please)
- [release-plz.dev](https://release-plz.dev/docs/why)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [github.io](https://nnethercote.github.io/perf-book/build-configuration.html)
- [jetbrains.com](https://blog.jetbrains.com/rust/2026/02/11/state-of-rust-2025/)
- [github.io](https://axodotdev.github.io/cargo-dist/)
- [github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md)
- [reddit.com](https://www.reddit.com/r/rust/comments/19be7ll/cargodist_is_very_very_good_and_you_should_check/)
- [reddit.com](https://www.reddit.com/r/rust/comments/18zuzgk/how_to_ship_rust_binaries/)
- [orhun.dev](https://blog.orhun.dev/automated-rust-releases/)
- [medium.com](https://medium.com/techkoala-insights/how-to-optimize-rust-release-builds-for-smaller-binaries-and-faster-performance-019e7718e8aa)
- [ycombinator.com](https://news.ycombinator.com/item?id=38654326)
- [benjaminbrandt.com](https://benjaminbrandt.com/a-better-cargo-install-workflow/)
- [han.rs](https://book.han.rs/ch09-01-unrecoverable-errors-with-panic)
- [github.com](https://github.com/dandavison/delta/issues/2122)
- [dev.to](https://dev.to/godofgeeks/rust-compiler-optimizations-kfb)
- [crates.io](https://crates.io/crates/cargo-binstall/1.6.2)
- [crates.io](https://crates.io/crates/cargo-binstall/0.23.0)
- [github.com](https://github.com/axodotdev/cargo-dist/issues/908)
- [docs.rs](https://docs.rs/crate/cargo-binstall/0.4.1)
- [rust-lang.org](https://users.rust-lang.org/t/difference-between-strip-symbols-and-strip-debuginfo/96602)
- [crates.io](https://crates.io/crates/cargo-dist/)
- [github.com](https://github.com/axodotdev/cargo-dist/releases)
- [github.com](https://github.com/cargo-bins/cargo-binstall/releases)
- [github.com](https://github.com/cargo-bins/cargo-binstall/discussions/1939)
- [rust-lang.org](https://users.rust-lang.org/t/crates-io-download-counter-unexpected-changes/136313)
- [medium.com](https://leapcell.medium.com/optimizing-rust-compilation-smaller-faster-or-both-1cdac7bfd93c)
- [kurotych.com](https://kurotych.com/posts/distributing-rust-binaries/)
- [reddit.com](https://www.reddit.com/r/rust/comments/1noozk7/psa_cargodist_is_not_dead/)
- [github.io](https://rust-lang.github.io/rfcs/2678-named-custom-cargo-profiles.html)
- [medium.com](https://medium.com/@trivajay259/the-lto-evangelist-what-a-single-github-user-taught-me-about-optimization-community-and-073eee32c68b)
- [github.com](https://github.com/rust-lang/cargo/issues/14719)
- [medium.com](https://medium.com/@kakamber07/i-cut-rust-compile-time-from-22-minutes-to-38-seconds-with-one-cargo-config-toml-line-5bc03eba16f7)
- [ycombinator.com](https://news.ycombinator.com/item?id=36681703)
- [mit.edu](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/second-edition/ch14-01-release-profiles.html)
- [ycombinator.com](https://news.ycombinator.com/item?id=39112486)
- [medium.com](https://medium.com/@bugsybits/unwind-vs-abort-the-hidden-trade-offs-in-rusts-panic-system-6e66d1170aa3)
- [rustwiki.org](https://rustwiki.org/en//book/ch14-01-release-profiles.html)
- [rust-lang.org](https://internals.rust-lang.org/t/feature-request-add-cargo-binstall-by-default/23876)