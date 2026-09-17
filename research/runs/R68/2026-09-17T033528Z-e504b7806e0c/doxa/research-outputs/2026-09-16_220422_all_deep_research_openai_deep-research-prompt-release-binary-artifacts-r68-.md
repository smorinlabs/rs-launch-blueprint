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
provider: openai
model: gpt-5.6-sol
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

## Reasoning Summary
**Planning extensive research**

I need to tackle a huge research prompt, so I'll start with an immediate web call before using any other tools. I might need to inspect specific local documents, but I think the user’s references may not be publicly accessible. I’ll need to document any evidence from owner-provided content in the prompt, ensuring to note retrieval dates and URLs. It seems leveraging public benchmark results might help, but ultimately, I need to be transparent about any gaps in evidence.
**Gathering API information**

I need to gather as much information as possible, considering that I might access web URLs and GitHub API endpoints. I’ll collect figures from relevant APIs, such as crates.io and GitHub. I should identify suitable candidates for artifact distribution alternatives like Cargo’s built-in methods or cargo-dist, which may have been renamed to "dist" by Axo. I’ll verify this as of September 17, 2026, and check for updated information with an immediate web search.

### Landscape

**Research cutoff:** September 17, 2026. All web sources below were retrieved on that date. Repository-local owner files were not independently accessible; I treated the excerpts supplied in the prompt as binding inputs.

**Evidence limitation:** this research interface did not provide a Rust build runner. Consequently, the owner-required Ubuntu/macOS profile benchmark was **not executed**, and the required crates.io/GitHub JSON metric census was not successfully captured. I report those fields as evidence gaps rather than inventing figures. The artifact recommendation is actionable; the profile recommendation is conditional on the benchmark in `### Validation strategy`.

#### Category map

| Bin | Candidates found | Assessment |
|---|---|---|
| **Built-in or first-party toolchain** | `cargo publish`/crates.io, `cargo install --locked`, Cargo release profiles, `rustup target add`, GitHub Releases/Actions | Canonical source distribution and lowest-complexity baseline. Cargo installs binaries using the release profile but compiles them on the consumer’s machine. Cargo profiles are workspace-root policy and are ignored when this crate is a downstream dependency. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai)) |
| **Established industry standard** | **`dist`**, distributed as `cargo-dist`; `cargo-binstall`; composable GitHub release actions backed by `cross` or `cargo-zigbuild` | `dist` is the only surveyed maintained tool that combines target planning, builds, archives, checksums, installers, a machine-readable manifest, generated CI, and GitHub Release hosting. `cargo-binstall` is the established consumer-side binary installer, not an artifact producer. ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai)) |
| **Up-and-comer / modular alternatives** | Release orchestration plus `upload-rust-binary-action`; release-plz binary-release recipes; generic/non-Rust release tooling | These favor composability and integrate naturally into an existing release workflow, but require the template to own more target, archive, checksum, installer, and upload policy itself. Release-plz’s own documentation delegates binary building to either an upload action or cargo-dist. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai)) |

#### Authority

- **Cargo Book:** normative for profile defaults, permitted values, profile selection, custom-profile inheritance, override precedence, and the rule that dependency manifests’ profile settings are ignored. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))
- **GitHub documentation:** normative for workflow triggering. Events caused by the repository `GITHUB_TOKEN` do not normally start another workflow; `workflow_dispatch` and `repository_dispatch` are exceptions. This matters directly to release-please → dist wiring. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai))
- **Maintainer documentation:** authoritative for `dist`, `cargo-binstall`, and release-please behavior and configuration. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))
- **Maintained reference implementations:** `dist` self-hosts its release process; `cargo-binstall` publishes and installs its own target-specific binaries; release-plz explicitly documents cargo-dist and upload actions as the binary-release layer. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai))

#### Practice evidence

`dist` released version **0.33.0 on September 10, 2026**, has current documentation, is packaged by Homebrew, and self-hosts its generated workflow. That is strong maintenance and implementation evidence, though not evidence of formal Rust-project endorsement. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

The retrieved evidence did **not** provide file-level, independent adopter verification for ten mainstream Rust projects. Therefore, adoption is not used as the deciding signal. The recommendation rests on capability coverage, current maintenance, ecosystem conventions, and fit—not stars or familiarity.

### Principles and implementation

#### Shared requirement and agreement level

The shared engineering principle is:

> **Publish one canonical source package for Rust consumers, while making the user-facing CLI available without requiring a local Rust toolchain or a full dependency compile. Keep all artifacts tied to one version/tag, use standard Rust target triples, preserve a source-build fallback, and make the release profile an explicit workspace-root policy.**

Agreement is required at four levels:

1. **Capability:** crates.io source distribution plus supported native CLI artifacts.
2. **Policy:** one release version, a declared target set, integrity metadata, and documented fallback behavior.
3. **Architectural pattern:** release/version orchestration and artifact production have one clearly defined interface and exactly one owner for GitHub Release creation.
4. **Profile policy:** local release and distributed binaries use equivalent optimization, panic, and symbol policies; downstream library users inherit none of them.

The exact workflow generator may change after a fork, but these observable behaviors should not.

#### Architectural alternatives

**1. Crates.io only**

This is the Cargo-native baseline: publish the `.crate`, document `cargo install --locked`, and let every user compile. It is simple and supports every target on which the dependency graph compiles. Its cost is user time, installation of a Rust toolchain, local native dependencies, and repeated compilation in developer workstations and CI environments. `cargo install` selects Cargo’s release profile by default. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

**2. Integrated release application: `dist`**

`dist` discovers Cargo targets, plans target builds, creates archives and installers, generates `dist-manifest.json`, and emits a GitHub Actions release pipeline. It supports x86-64 and ARM64 Linux and macOS targets, among others. Its shell installer detects the host platform and downloads the corresponding archive. ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai))

This best realizes the template’s “batteries included, but replaceable” purpose: a fork starts with a complete binary-release path rather than a README telling maintainers to design one later.

**3. Composable GitHub Actions**

An upload action plus `cross` or `cargo-zigbuild` can build and upload target binaries directly into a release-please-created GitHub Release. This avoids a generated multi-phase workflow and may integrate more directly with release-please, but the template must define archive layouts, checksums, manifests, installer scripts, target fallback, and cargo-binstall compatibility itself. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))

That is appropriate for a project with bespoke release engineering, but not the best default for a reusable launch template.

#### Release-please boundary

`dist` and release-please both know how to create GitHub Releases. They must not both use their defaults.

The recommended ownership is:

- **release-please:** version bump, changelog, tag, and initial GitHub Release;
- **dist:** target builds, archives, checksums, installer, manifest, and asset upload, configured with `create-release = false`.

The integration must not assume that a tag created with the default `GITHUB_TOKEN` starts the generated dist workflow. GitHub explicitly suppresses most such recursive events. Use the credential mechanism already owned by the release-please decision—preferably a narrowly scoped GitHub App token—or an explicit dispatch/call path. `dist` documents `workflow_dispatch` support, but its generated mode and `create-release=false` behavior must be tested against the exact release-please flow before acceptance. ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai))

#### cargo-binstall

`cargo-binstall` already searches crates.io metadata and the crate’s repository for matching release assets, and its maintainers advise trying automatic discovery before adding metadata. Explicit `[package.metadata.binstall]` remains preferable in a template because it converts a heuristic into a checked contract. It does not require another artifact-hosting service: it points at the same GitHub Release archives. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

Do **not** disable its compile fallback. Supported targets receive binaries; unsupported targets can still fall through to `cargo install`.

#### Target policy

Ship four native targets:

- `x86_64-unknown-linux-gnu`
- `aarch64-unknown-linux-gnu`
- `x86_64-apple-darwin`
- `aarch64-apple-darwin`

This preserves the fixed Linux/macOS OS boundary while covering both major architectures. The artifact matrix need not equal the contributor runner architecture: Apple Silicon Macs and ARM64 Linux servers are end-user platforms even when contributors use x86-64 runners. All four are explicitly supported by `dist`. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

Do not ship Windows, MSI, PowerShell, musl, Homebrew, or npm artifacts by default. Windows is outside the fixed matrix; musl introduces another libc compatibility dimension and two additional builds without an inherited acceptance test.

#### Profile architecture

Cargo reads profiles only from the workspace root; downstream library consumers ignore profiles from the published crate. A selected profile applies to library and binary targets in the current build. Custom profiles require `inherits` and use a separate target subdirectory. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

The implementation should place the actual policy in `[profile.release]` and declare a settings-free `[profile.dist]` adapter that inherits it. Current `dist` guidance expects that custom profile and generally refuses to run without it. This creates a separate Cargo cache/output directory, but avoids semantic divergence because it contains no overrides. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai))

#### Observable acceptance criteria

1. One version/tag produces one crates.io `.crate` and one GitHub Release.
2. The GitHub Release contains exactly four native archives, their checksums, one Unix shell installer, and `dist-manifest.json`.
3. No Windows, musl, npm, Homebrew, MSI, or redundant dist-generated source tarball is present.
4. `cargo binstall rs-launch-blueprint` downloads a project-owned binary on all four targets.
5. Unsupported cargo-binstall targets retain source-compile fallback.
6. `cargo install --locked rs-launch-blueprint` remains documented and functional.
7. A library consumer receives no profile settings from this crate.
8. `cargo build --release` and `cargo build --profile dist` have equivalent effective profile values.
9. release-please and dist do not create duplicate tags/releases.
10. The required Ubuntu/macOS benchmark is attached before the profile block is accepted.

**BASELINE-REVIEW: F220 — installation documentation must reflect the selected channels rather than copy Python or npm precedent — proposed change: document `cargo binstall`/release binaries as the preferred CLI path and `cargo install --locked` as the portable source fallback, while library consumers use the crates.io dependency — evidence: Cargo’s install profile and cargo-binstall’s repository-artifact discovery model.** ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

### Dominant choice

**`dist`—the current command name for the package still distributed as `cargo-dist`—version range `>=0.33.0,<0.34.0`, with an exact checked-in pin of `0.33.0`.**

`dist` is the dominant **integrated** choice in this survey, not an official Rust standard. It is the only current candidate found that covers target planning, cross-target builds, archives, hashes, installer generation, machine-readable release metadata, CI generation, and GitHub Release upload as one maintained system. Version 0.33.0 was released on September 10, 2026. Its configuration requires an exact version rather than a version requirement, hence the exact pin inside the broader implementation-policy range. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

Use it in combination with:

- the unavoidable crates.io `.crate`;
- explicit cargo-binstall metadata targeting the GitHub Release archives;
- a shell installer for Linux/macOS;
- both source and prebuilt installation commands in the README.

The principal qualification is release-please integration: it is clean at the architectural boundary, but not zero-configuration because of GitHub event-suppression and duplicate-release ownership.

### Qualified shortlist

The required crates.io and GitHub API metric values were not captured. No download, star, open-issue, or issue-response numbers are asserted.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters/reference use | One-line trade-off |
|---|---|---:|---:|---:|---|---|---|---|
| **`dist`/`cargo-dist` `>=0.33,<0.34` + cargo-binstall metadata** | Integrated binary build, package, installer, manifest, and upload bundle | **Evidence gap:** required crates.io endpoint not captured | **Evidence gap** | **Evidence gap:** required GitHub API not captured | Tool release 0.33.0, September 10, 2026; crates.io version endpoint not captured | **active**, provisional because ten-issue response census is missing | Self-hosting `dist`; cargo-binstall-compatible distribution model; referenced by release-plz’s binary-release guide | Most complete behavior, but generated CI, profile adapter, and release-please ownership require validation. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai)) |
| **Cargo/crates.io only** | Built-in source package and source-compiled CLI | Inapplicable: architectural pattern | Inapplicable | Inapplicable | Follows Rust/Cargo releases | **active / first-party** | Universal Cargo baseline | Lowest maintenance; transfers build time and toolchain/native-dependency burden to every installer. ([doc.crates.io](https://doc.crates.io/?utm_source=openai)) |

Fewer than five qualified choices is a finding: `cargo-binstall` and release-plz are complementary consumers/orchestrators, while upload actions leave too many required behaviors to template-owned glue.

### Excluded by gate

#### Fitness-gate record for the dominant bundle

| Gate | Result |
|---|---|
| **1. Licence compatibility** | **Inapplicable**, per owner ruling Q7.B dated September 12, 2026 in `docs/port/OWNER-REVIEW.md`, section *“2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)”*. The row is retained as required. |
| **2. MSRV/dependency-tree MSRV** | **Pass for the selected deployment mode, with re-verification required.** `dist` and cargo-binstall are release/user tools installed as prebuilt executables and do not enter the template crate’s dependency graph. The retrieved cargo-dist manifest declared an older Rust floor than the template policy, but the exact 0.33 dependency-tree MSRV was not captured. Do not make source-building cargo-dist part of release CI. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)) |
| **3. RustSec and unsafe posture** | **Provisional pass.** No open advisory was found in the retrieved search results, but the direct RustSec package pages were not captured and must be queried before merge. The tools run out of process; no tool-internal `unsafe` is linked into `rs-launch-blueprint`. Internal unsafe counts were not audited. |
| **4. Ubuntu/macOS support** | **Pass.** Both target families and both x86-64/ARM64 architectures are supported in current dist configuration. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai)) |
| **5. Features/runtime coupling** | **Pass.** Cargo-dist and cargo-binstall have their own async/network stacks, but they are external executables and introduce no Tokio, TLS, or default-feature coupling into the template’s library or binary. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)) |
| **6. Size and compile-time cost** | **Pass with known cost.** No runtime dependency is added. Release CI performs four binary builds plus packaging jobs; the actual wall-time and profile cost remain unmeasured. |

#### Exclusions

- **`cargo-binstall` alone:** excluded by capability gate—it installs existing artifacts but does not build or publish them. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))
- **release-plz alone:** excluded by capability gate—its own binary-release documentation directs users to cargo-dist or an upload action. ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))
- **A bare upload action:** excluded by essential-behavior gate—it can compile/upload binaries but does not, by itself, define the installer, manifest, checksum, target-fallback, and archive-layout policy required here. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))
- **Hand-written `cross`/`cargo-zigbuild` matrix:** excluded by template-fit gate. It can realize the capability, but makes every fork own more bespoke workflow logic than the integrated choice.
- **Windows/MSI/PowerShell targets:** excluded by fixed `target-os-matrix`.
- **Linux musl targets:** excluded from the default matrix because they add a libc support dimension and release builds without a corresponding fixed CI or smoke-test requirement.
- **GoReleaser Rust support and newer installer-only tools:** excluded because this run did not capture sufficient current primary-source maturity, MSRV, advisory, and adopter evidence.

### Up-and-comers

1. **Composable release-please + upload action architecture.** This is the strongest challenger when an organization prefers one hand-maintained release workflow over generated CI. It can build with Cargo, `cross`, or cargo-zigbuild and attach directly to an existing GitHub Release. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))
2. **release-plz binary recipes.** Release-plz is strengthening Rust-native release orchestration but still delegates binary production. It is therefore a possible replacement for release-please, not yet a replacement for dist in this decision. ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))
3. **`dist` Config 1.0/generalized project support.** Current documentation says its configuration is migrating from Cargo metadata to `dist-workspace.toml`/`dist.toml`, and its scope is expanding beyond Rust. That evolution is promising but is also a re-verification trigger for the 0.34 line. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

### Fit for this template

#### CLI

This is where prebuilt artifacts pay off most. A template consumer can install and exercise the generated CLI without waiting for the Axum/Tokio/Clap dependency graph to compile or installing a Rust toolchain. `cargo binstall` provides the Cargo-shaped command; the shell installer and direct archives cover users without cargo-binstall. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))

#### Library

The crates.io `.crate` remains the only meaningful library artifact. GitHub binaries neither replace nor duplicate it. Cargo ignores profile definitions in dependency manifests, so downstream applications choose their own optimization, panic, and symbol policies. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

#### Web service

The released CLI binary may expose the R49-defined web-service command or mode, making prebuilt binaries useful for local demonstrations and direct self-hosting. The recommendation retains unwinding and symbols rather than minimizing size at any cost. Container publication remains entirely with R51.

### Recommendation

#### Artifact and channel decision

| Subject | Decision |
|---|---|
| **Release tool** | `dist` / package `cargo-dist`, policy range `>=0.33.0,<0.34.0`, exact checked-in version `0.33.0`. |
| **Source artifact** | Publish the normal crates.io `.crate`. |
| **Native artifacts** | Four GitHub Release archives: x86-64 and ARM64 for GNU/Linux and macOS. |
| **Supporting artifacts** | Checksums, `dist-manifest.json`, and one Unix shell installer. |
| **cargo-binstall** | Explicit metadata pointing to the same release archives; compatibility acceptance target `cargo-binstall >=1.23.0,<2`. No separate binstall artifact or service. |
| **Not shipped** | Windows, musl, npm, Homebrew, MSI, PowerShell installer, separate dist-generated source tarball, or container image. |
| **README** | Preferred CLI: `cargo binstall rs-launch-blueprint`; source fallback: `cargo install --locked rs-launch-blueprint`; direct archive/shell installer documented; library use documented separately. |
| **Release ownership** | release-please owns version/tag/GitHub Release; dist attaches assets with `create-release = false`. Triggering must use a GitHub App/PAT-backed event or explicit dispatch—not an assumed recursive `GITHUB_TOKEN` event. |

Recommended `dist-workspace.toml`:

```toml
[dist]
cargo-dist-version = "0.33.0"
ci = ["github"]

targets = [
  "x86_64-unknown-linux-gnu",
  "aarch64-unknown-linux-gnu",
  "x86_64-apple-darwin",
  "aarch64-apple-darwin",
]

installers = ["shell"]
source-tarball = false
create-release = false
pr-run-mode = "plan"
```

These are current documented configuration surfaces. The exact tool version is mandatory rather than a Cargo-style requirement. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

Recommended Cargo metadata, assuming the existing release tag is `v{version}` and dist 0.33’s versionless Unix archive naming:

```toml
[package.metadata.binstall]
pkg-url = "{ repo }/releases/download/v{ version }/{ name }-{ target }.tar.xz"
bin-dir = "{ bin }{ binary-ext }"
pkg-fmt = "txz"
```

Do not set `disabled-strategies`; cargo-binstall must retain its normal fallback behavior. The exact `pkg-url` and `bin-dir` must be proven against an actual prerelease asset because cargo-binstall explicitly permits metadata overrides when automatic discovery or archive layout differs. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

#### Release build profile

**Provisional implementation target:**

```toml
[profile.release]
lto = "thin"
codegen-units = 1
strip = "none"
panic = "unwind"

# Adapter required by current dist; no policy divergence.
[profile.dist]
inherits = "release"
```

| Key | Cargo release default | Decision | Manifest treatment | Basis |
|---|---|---|---|---|
| `lto` | `false` | `"thin"` | **Write** | Matches the owner reference architecture and dist’s maintained release-profile pattern. Intended to improve whole-program optimization with less cost than fat LTO. Must pass the project benchmark. |
| `codegen-units` | `16` for non-incremental release builds | `1` | **Write** | Matches the owner reference architecture and prioritizes shipped artifact quality over release-build parallelism. This is the setting most likely to be removed if the benchmark shows poor return. |
| `opt-level` | `3` | `3` | **Leave silent** | No evidence that `"s"` or `"z"` improves this application’s final archive enough to offset possible runtime regressions. Silence records “standard release optimization,” not a size-at-all-costs policy. |
| `strip` | `"none"` | `"none"` | **Write explicitly** | Deliberate support policy: retain linker-emitted symbols in end-user binaries. This does not promise file/line information because `debug` remains off. |
| `panic` | `"unwind"` | `"unwind"` | **Write explicitly** | Avoids changing panic semantics for the CLI/web-service build and preserves the possibility of panic hooks, unwinding, and task-level handling. |
| `debug` | `false`/`"none"` | default | **Leave silent** | R67 creates no stack-trace requirement and F301 remains open. Shipping line tables now would assert a diagnostic contract not yet owned. Revisit if F301 requires source locations or symbol bundles. |
| Custom profile | none | `[profile.dist] inherits = "release"` | **Write, with no overrides** | Current dist expects the profile. Keeping all settings in `release` gives local and CI builds the same policy, while acknowledging that Cargo still uses a separate output/cache directory. |

Cargo documents all defaults above, the permitted values, custom-profile inheritance, and workspace-root precedence. Configuration/environment overrides take precedence over `Cargo.toml`. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))

**Reference architecture record:** provisionally **agree** with `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, section *Reference Cargo.toml*, on `lto = "thin"` and `codegen-units = 1`. This recommendation adds explicit `strip = "none"` and `panic = "unwind"`, leaves `opt-level` and `debug` at Cargo defaults, and places a settings-free `dist` adapter beside `release`.

#### Required measurement status

The mandatory profile experiment was **not executed**. Therefore:

- no binary-size figure is claimed;
- no clean or post-edit build-time figure is claimed;
- no Ubuntu/macOS comparison is claimed;
- no setting is described as empirically faster or smaller;
- the profile portion of this recommendation is **not acceptance-ready under W0-R69p** until the planned run succeeds.

The measured table that must replace this gap is:

| Variant | Ubuntu size, unstripped/stripped | Ubuntu clean/post-edit wall time | macOS size, unstripped/stripped | macOS clean/post-edit wall time |
|---|---:|---:|---:|---:|
| Cargo release defaults | Not run | Not run | Not run | Not run |
| `lto="thin"` only | Not run | Not run | Not run | Not run |
| `codegen-units=1` only | Not run | Not run | Not run | Not run |
| `lto="thin"` + `codegen-units=1` | Not run | Not run | Not run | Not run |
| Final profile above | Not run | Not run | Not run | Not run |
| `opt-level="z"` challenger | Not run | Not run | Not run | Not run |
| `strip="symbols"` challenger | Not run | Not run | Not run | Not run |
| `panic="abort"` challenger | Not run | Not run | Not run | Not run |
| `debug="line-tables-only"` challenger | Not run | Not run | Not run | Not run |

### Ranked runner-up

**Crates.io-only distribution with Cargo’s standard release profile.**

It wins if any of these conditions holds:

- the existing release-please flow cannot provide one safe release owner without a new App/PAT or bespoke dispatch;
- organizational policy rejects cargo-dist’s generated bootstrap or generated workflow;
- the four-target release adds unacceptable CI cost;
- cargo-binstall metadata cannot be proven against the generated archive layout;
- the profile benchmark shows that thin LTO/codegen-units tuning does not justify its build-time cost;
- the template is intentionally repositioned as a library-first starter rather than a runnable CLI product.

### Tradeoffs

| Compared with | What the recommendation gains | What it gives up | Why accepted |
|---|---|---|---|
| **Crates.io only** | Fast end-user installs, no required Rust toolchain, architecture-native CLI, conventional GitHub assets | Four release builds, more workflow permissions and failure modes | A launch template benefits from demonstrating a production-ready binary-release path rather than deferring all release engineering to every fork. |
| **Composable upload action** | Installer, checksums, manifest, target planning, archive conventions, generated PR validation | Less transparent generated YAML and more release-owner coordination | The integrated behaviors are exactly what otherwise becomes bespoke template code. |
| **Wider matrix including musl** | Lower CI cost and smaller support surface | No Alpine/static Linux default and fewer fallback binaries | GNU/Linux plus source fallback covers the fixed matrix without silently promising another libc compatibility contract. |
| **Stripped/abort binaries** | Better post-release diagnostic potential and unchanged panic semantics | Larger binaries than aggressively stripped/abort builds | End users cannot rebuild the exact shipped binary; supportability is more important than minimum byte count absent measurements. |
| **Independent `[profile.dist]` tuning** | Local `--release` and CI have the same effective settings | Separate Cargo cache/output directory remains because of the profile name | Semantic divergence is avoided, and dist’s current integration requirement is satisfied. |
| **Cargo defaults only** | Potentially smaller/faster runtime from thin LTO and one codegen unit | Longer clean release builds | Release builds are infrequent and parallelized by target, but this cost must still be measured before acceptance. |

### Parameters

`owns release-binary-artifacts = crates.io .crate + four GitHub Release target archives + checksums + dist-manifest.json + Unix shell installer`

`owns release-tool = dist/cargo-dist >=0.33.0,<0.34.0; checked-in exact pin 0.33.0`

`owns cargo-binstall-support = explicit package metadata targeting project-owned GitHub Release archives; compatibility baseline >=1.23.0,<2`

`owns documented-install-method = cargo binstall and direct release binary as preferred CLI paths; cargo install --locked as source fallback; crates.io dependency for library consumers`

`owns cargo-release-build-profile = [profile.release] lto="thin", codegen-units=1, strip="none", panic="unwind"; opt-level/debug left at Cargo defaults; [profile.dist] inherits="release" with no overrides`

`assumes build-tool-output-shape = R49-defined [lib], [[bin]], package include allow-list, and target names; no target declaration is changed`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version and tested in CI`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes license = MIT OR Apache-2.0`

`CONFLICT: none`

### Migration implications

1. **`Cargo.toml`**
   - Add `[package.metadata.binstall]`.
   - Add the recommended `[profile.release]`.
   - Add the settings-free `[profile.dist]`.
   - Do not alter R49-owned `[lib]`, `[[bin]]`, package `include`, entry points, or target names.

2. **`dist-workspace.toml`**
   - Add the exact 0.33.0 tool pin.
   - Declare the four targets.
   - Enable only the shell installer.
   - Disable the redundant dist source tarball.
   - Set `create-release = false`.
   - Keep PR validation at `plan`.

3. **`.github/workflows/release.yml`**
   - Generate with `dist generate`.
   - Review and commit the generated file.
   - Ensure its trigger works with the existing release-please credential/event path.
   - Ensure it uploads to the release-please-created release rather than creating another.
   - Pin third-party actions to the repository’s established security policy; dist supports explicit action-commit pins. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai))

4. **Existing release-please workflow/config**
   - Expose the release tag to dist.
   - Use a GitHub App/PAT-backed tag event or an explicit dispatch path.
   - If dist’s `create-release=false` implementation requires a draft release, ensure release-please produces one or use a same-workflow upload integration.
   - Do not depend on a recursive event from the default `GITHUB_TOKEN`. ([docs.github.com](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai))

5. **`README.md`**
   - Add separate **Library**, **Prebuilt CLI**, **Source-built CLI**, and **Direct download** installation sections.
   - Make cargo-binstall the first CLI command on supported platforms.
   - State the four supported binary targets and source fallback for everything else.
   - Do not imply Windows, musl, or container availability.

6. **Release-maintenance documentation**
   - Explain that `cargo-dist-version` is an exact reproducibility pin.
   - Require `dist generate` and review when upgrading within `0.33.x`.
   - Require fresh research before `0.34.x` because configuration and generated workflow behavior may change.

7. **R50 hand-off**
   - R50 should smoke-test the shell installer, cargo-binstall path, direct archive, and `cargo install --locked`; R68 decides only what exists.

8. **R51 hand-off**
   - No container workflow or image reference is added here.

### Validation strategy

#### Executed in this research

- Current Cargo profile documentation was inspected.
- Current dist configuration, release, generated-workflow, and custom-profile documentation was inspected.
- Current cargo-binstall discovery and metadata documentation was inspected.
- GitHub’s recursive-workflow trigger rules were inspected.
- **No Rust builds, uploads, installs, profile benchmarks, API metric census, or release dry runs were executed.**

#### Planned artifact checks

```bash
dist --version
# Expected: dist/cargo-dist 0.33.0

dist generate
git diff --exit-code
# Expected: generated workflow is committed and reproducible.

dist plan --tag=v0.1.0
# Expected: exactly four target archives, checksums, one shell installer,
# and dist-manifest.json; no Windows, musl, npm, Homebrew, MSI, or source.tar.gz.

dist build --tag=v0.1.0
# Expected locally where supported: target/distrib contains the planned artifacts.
```

Create a prerelease and then verify:

```bash
gh release view v0.1.0
gh release download v0.1.0 --dir target/release-assets
```

Expected behavior:

- only one release exists for the tag;
- every planned artifact is attached;
- a failed target job prevents final announcement;
- archive checksums verify;
- the shell installer selects the appropriate one of the four targets.

#### Planned cargo-binstall checks

For each supported target, using cargo-binstall 1.23.x:

```bash
cargo binstall \
  --manifest-path Cargo.toml \
  --version 0.1.0 \
  --target x86_64-unknown-linux-gnu \
  --no-confirm \
  rs-launch-blueprint
```

Repeat for all four triples. Expected result: the log identifies the project’s GitHub Release as the binary source; no local Rust compilation occurs.

For an unsupported target, verify that cargo-binstall attempts its normal fallback rather than failing because strategies were disabled.

Source fallback:

```bash
cargo install --locked --version 0.1.0 rs-launch-blueprint
rs-launch-blueprint --version
```

#### Planned profile benchmark

Until the actual template source exists, use a declared stand-in:

- one edition-2024 package;
- one library plus one binary;
- CLI subcommands for `version` and `serve`;
- Axum/Tokio HTTP service;
- direct dependencies representing the likely composition: Axum, Tokio, Clap, Serde, serde_json, tracing, tracing-subscriber, and tower-http;
- exact versions and resolved dependency count taken from the committed lockfile at benchmark time.

This stand-in is unlike the eventual template because it lacks its final domain logic, optional features, native dependencies, generated code, and exact R49 target implementation. Its measurements may select obviously poor settings but must be rerun on the real source before P03 release.

On both `ubuntu-latest` and `macos-latest`, record:

```bash
rustc -Vv
cargo -Vv
uname -a

# Linux:
lscpu

# macOS:
sysctl -a | grep -E 'machdep.cpu|hw.model|hw.ncpu'
```

For every variant:

1. Set a unique `CARGO_TARGET_DIR`.
2. Delete it before the clean build.
3. Time `cargo build --locked --release`.
4. Record binary size with a portable Python `os.path.getsize`.
5. Copy and strip the binary with the host’s `strip`; record its version and resulting size.
6. Rebuild once to warm dependencies.
7. Touch one application source file without changing behavior.
8. Time the post-edit rebuild.
9. Repeat enough times to report median wall time, retaining raw logs.

At minimum test:

```text
Cargo defaults
lto=thin
codegen-units=1
lto=thin + codegen-units=1
opt-level=z
strip=symbols
panic=abort
debug=line-tables-only
final proposed profile
```

Proposed acceptance rules—not measurements:

- Keep `lto="thin"` only if it reduces the unstripped or stripped binary on **both** OSes without an operationally unacceptable clean-build increase.
- Keep `codegen-units=1` only if it produces an additional material size or runtime benefit over thin LTO alone.
- Do not adopt `opt-level="z"` solely because one host produces a smaller file; run the CLI and HTTP workload as well.
- Keep `strip="none"` and `panic="unwind"` unless a later owner decision explicitly accepts weaker diagnostics/changed panic semantics.
- Revisit `debug` when F301 defines the stack-trace contract.

#### Profile equivalence and downstream isolation

```bash
cargo clean
cargo build --release -vv 2> release.flags.log

cargo clean
cargo build --profile dist -vv 2> dist.flags.log
```

Normalize output paths and compare rustc profile flags. Expected: equivalent `lto`, codegen-unit, strip, panic, debug, and opt-level values.

Create a downstream fixture depending on the packaged crate:

```bash
cargo package
cargo new /tmp/profile-consumer
# Add the packaged crate as a dependency, then:
cargo build --manifest-path /tmp/profile-consumer/Cargo.toml -vv
```

Expected: the downstream root’s profiles control compilation; this crate’s `[profile.release]` and `[profile.dist]` are ignored, as Cargo documents. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

### Confidence & re-verify trigger

**Artifact recommendation: medium-high confidence.** The capability and fit evidence strongly favor the crates.io-plus-dist combination.

**Release-please integration: medium confidence.** The architectural boundary is clear, but the exact existing F063–F077 token, draft-release, and dispatch behavior was not available for an executable integration test.

**Profile recommendation: low-to-medium and explicitly conditional.** It agrees with the owner reference and current dist practice, but the owner-mandated measurements are absent. It should not be marked accepted until the benchmark table is populated.

Re-verify when:

- `cargo-dist` 0.34 or Config 1.0 is released;
- dist no longer requires `[profile.dist]` or gains a selectable Cargo profile;
- cargo-binstall 2.0 changes discovery, metadata, signatures, or archive conventions;
- release-please changes tag/release or token behavior;
- GitHub changes `GITHUB_TOKEN` recursion rules;
- cargo-dist issue #2420 or equivalent bootstrap-integrity behavior changes—the generated workflow currently has an open concern about checksum-verifying its own installer. ([github.com](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai))
- Windows or musl is added to the fixed matrix;
- R50 cannot smoke-test ARM64 artifacts;
- F301 defines a stack-trace or symbol-bundle requirement;
- the real template source replaces the stand-in;
- benchmark results show `codegen-units=1` or thin LTO does not pay for itself;
- the direct RustSec and dependency-tree MSRV checks fail;
- release CI exceeds the project’s eventual time or cost budget.

### Sources

All web sources retrieved **September 17, 2026**.

1. Cargo Book, **Profiles**:  
   `https://doc.rust-lang.org/cargo/reference/profiles.html`  
   Defaults, permitted values, workspace-root rule, inheritance, output directories, profile selection, and overrides. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))

2. dist documentation, **Introduction**:  
   `https://axodotdev.github.io/cargo-dist/book/introduction.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/introduction.html?utm_source=openai))

3. dist documentation, **Configuration**:  
   `https://axodotdev.github.io/cargo-dist/book/reference/config.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

4. dist documentation, **Simple application/custom dist profile**:  
   `https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai))

5. dist documentation, **Shell installer**:  
   `https://axodotdev.github.io/cargo-dist/book/installers/shell.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/installers/shell.html?utm_source=openai))

6. dist changelog, including 0.33.0:  
   `https://axodotdev.github.io/cargo-dist/changelog/` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

7. cargo-dist repository and generated workflow:  
   `https://github.com/axodotdev/cargo-dist`  
   `https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml` ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai))

8. cargo-dist bootstrap checksum issue:  
   `https://github.com/axodotdev/cargo-dist/issues/2420` ([github.com](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai))

9. cargo-binstall README:  
   `https://github.com/cargo-bins/cargo-binstall/blob/main/README.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))

10. cargo-binstall maintainer metadata guide:  
    `https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

11. cargo-binstall signing guide:  
    `https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md?utm_source=openai))

12. GitHub documentation, **Triggering a workflow**:  
    `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow` ([docs.github.com](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai))

13. GitHub documentation, **Events that trigger workflows**:  
    `https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows` ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai))

14. release-please action documentation:  
    `https://github.com/googleapis/release-please-action` ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai))

15. release-plz binary-release alternatives:  
    `https://release-plz.dev/docs/extra/releasing-binaries` ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))

16. Composable upload-action alternative:  
    `https://github.com/step-security/upload-rust-binary-action` ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))

17. Required metric endpoints whose JSON values were **not successfully captured and therefore were not reported**:

    `https://crates.io/api/v1/crates/cargo-dist`  
    `https://crates.io/api/v1/crates/cargo-dist/versions`  
    `https://api.github.com/repos/axodotdev/cargo-dist`  
    `https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open`  
    `https://crates.io/api/v1/crates/cargo-binstall`  
    `https://crates.io/api/v1/crates/cargo-binstall/versions`  
    `https://api.github.com/repos/cargo-bins/cargo-binstall`  
    `https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open`

18. Owner-supplied local inputs, received September 17, 2026 and not independently retrieved:
    - `docs/port/OWNER-REVIEW.md`
    - `docs/planning/p02/owner-decisions.md`
    - `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
    - `docs/port/PARAMETERS.md`
    - `docs/port/BASELINE-REVIEW.md`
    - R69 decision and evidence paths quoted in the prompt.

## Sources

- [Profiles - The Cargo Book](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai)
- [GitHub - axodotdev/cargo-dist: 📦 shippable application packaging · GitHub](https://github.com/axodotdev/cargo-dist?utm_source=openai)
- [GitHub - step-security/upload-rust-binary-action: GitHub Action for building and uploading Rust binary to GitHub Releases. Secure drop-in replacement for taiki-e/upload-rust-binary-action. · GitHub](https://github.com/step-security/upload-rust-binary-action?utm_source=openai)
- [Events that trigger workflows - GitHub Docs](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai)
- [Config - dist](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai)
- [cargo-dist/.github/workflows/release.yml at main · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai)
- [cargo-dist](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai)
- [Profiles - The Cargo Book](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto)
- [GitHub - googleapis/release-please-action: automated releases based on conventional commits · GitHub](https://github.com/googleapis/release-please-action?utm_source=openai)
- [cargo-binstall/SUPPORT.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai)
- [A Simple Application - dist](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai)
- [Introduction - The Cargo Book](https://doc.crates.io/?utm_source=openai)
- [cargo-dist/Cargo.toml at main · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)
- [cargo-binstall/README.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai)
- [Releasing binaries | Release-plz](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai)
- [Triggering a workflow - GitHub Docs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai)
- [\[Feature request\] Checksum-verify the cargo-dist self-install in generated CI · Issue #2420 · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai)
- [Introduction - dist](https://axodotdev.github.io/cargo-dist/book/introduction.html?utm_source=openai)
- [shell - dist](https://axodotdev.github.io/cargo-dist/book/installers/shell.html?utm_source=openai)
- [cargo-binstall/SIGNING.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md?utm_source=openai)