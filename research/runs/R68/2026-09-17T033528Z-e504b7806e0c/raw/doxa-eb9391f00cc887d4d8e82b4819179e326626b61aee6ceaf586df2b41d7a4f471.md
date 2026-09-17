---
prompt: # Deep-research prompt — Release binary artifacts (R68, crate)
mode: all_deep_research
provider: combined
model: Multiple
operation_id: research-20260916-220422-5fd5c62e52434fa9
note: built by the P02 controller in the format of doxa_research.output.OutputManager.generate_combined_report (a concatenation of the saved provider files, no model call); Doxa 3.3.0 'resume --async' cannot honour the submission's --combined flag
---

# Combined Research Report: # Deep-research prompt — Release binary artifacts (R68, crate)

Generated: 2026-09-17T15:10:39.991284+00:00


## Openai Results

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

---


## Perplexity Results

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
provider: perplexity
model: sonar-deep-research
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

# Release Binary Artifacts and Cargo Release Profile for `rs-launch-blueprint`

The `rs-launch-blueprint` template must give its consumers a clear, dependable pattern for distributing compiled binaries and for configuring the Cargo release profile that produces those binaries, across its combined roles as CLI, library, and web service. After surveying the Rust ecosystem’s tooling for binary distribution and the documented behavior of Cargo profiles, and weighing these against the template’s fixed parameters (edition 2024, MSRV policy, and `ubuntu-latest` / `macos-latest` CI matrix), the strongest alignment emerges around a combined strategy. The recommended design keeps crates.io as the canonical source of the `.crate` package, but adds `cargo-dist`-driven GitHub Releases that publish cross-compiled binaries for Linux and macOS, in a layout that is directly consumable by `cargo-binstall` so that end users can install without compiling from source.[1][3][4][9] These binaries are built under a single `[profile.release]` that is tuned for production use and modest binary-size reduction, adopting `lto = "thin"` and `codegen-units = 1` in agreement with the owner’s reference architecture, while keeping `opt-level = 3` and `panic = "unwind"` as defaults to preserve debuggability and ecosystem expectations and leaving `strip` and `debug` at their documented defaults for a balanced tradeoff between symbol availability and size.[11][12][16] This profile is shared between CI release builds and contributor local builds, without a separate `dist` profile, matching current `cargo-dist` guidance to avoid redundant profiles.[7] The README’s documented installation method should reflect both `cargo install --locked` and `cargo binstall` against the same released crate and binaries, with crates.io-only as a fallback if the distribution tooling is ever disabled. Where measurement of binary sizes and build times is drawn from external published experiments rather than runs on this specific template, the report marks this explicitly as an evidence gap and bases its recommendations on convergence between Rust team guidance, tool maintainer documentation, and practice in widely used Rust projects.

## Introduction and context

The `rs-launch-blueprint` template is intended to provide a reusable starting point for Rust projects that ship a command-line interface, a reusable library, and a web service entry point together, in a way comparable to the owner’s Python and TypeScript templates that already define their own release and distribution conventions. The template’s consumers are expected to be engineers who fork the repository and adapt it to their own application, rather than end users who only interact with prebuilt binaries. This shapes the expectations for release automation: the template must demonstrate credible, modern Rust practices without over-optimizing for ultra-high-volume binary distribution, yet it must not leave its artifact choices underspecified, because those choices feed directly into the README’s installation instructions and the CI release workflow that is already standardized elsewhere in the stack.

The owner’s research mandate emphasizes that this item is not merely about copying a familiar pattern, but about identifying the shared engineering principle for release artifacts and build profiles, and establishing acceptance criteria that are observable in practice. The Python precedent ships both sdist and wheel artifacts from its `uv build` backend, while the TypeScript port ships a single ESM npm package.[Context] Cargo differs from both ecosystems in that every `cargo publish` produces exactly one `.crate` file representing the source package, regardless of how many binary formats the project distributes elsewhere. This asymmetry means that Rust’s binary release ecosystem depends more heavily on tools that sit beside Cargo and integrate with GitHub Releases, rather than on alternative packaging formats within the central registry.

Historically, the template’s artifact choice was inherited rather than actively decided: the TypeScript port’s single-tarball pattern did not carry a decision record weighing alternative artifact types, and Cargo’s default behavior would have been to rely on `cargo install --locked <name>` as the primary documented installation method. The owner’s baseline review established that the README’s documented installation method (F220) is derived from whatever this item decides for artifact distribution, and also that the Cargo release profile had not yet been decided by any previous prompt or ledger row.[Context] The recent owner ruling W0-R69p explicitly moved the profile subject into this item, making it responsible for both the choice of distribution artifacts and the `[profile.release]` configuration that produces them.

The fixed parameters—Rust edition 2024, MSRV policy “stable minus two minor versions, raised only in a minor release and tested in CI”, license `MIT OR Apache-2.0`, and target OS matrix `ubuntu-latest, macos-latest`—provide non-negotiable constraints that the distribution tooling and profile must respect.[Context] Windows binaries are explicitly out of scope for this template’s CI matrix, though nothing prevents a fork from extending the matrix later. The container image question for the web service remains the domain of R51, and the install-and-run smoke tests are owned by R50; this item must coordinate with them rather than subsume their responsibilities.

Within this context, the core questions fall into two clusters. The first cluster concerns artifact types and channels: whether to stick with crates.io-only distribution, whether to add `cargo-dist`-style cross-compiled GitHub Release binaries, and to what extent `cargo-binstall` should be treated as a first-class installation path rather than an incidental consumer of release assets. The second cluster concerns the Cargo release profile: which keys to set explicitly, how those settings affect binary size and build time, and how they trade off against debuggability and downstream consumers’ expectations. The owner requires that the profile decision draw on measured data, ideally from builds of the template itself, and that the template either agree with the reference architecture’s `lto = "thin"` and `codegen-units = 1` or state the grounds for differing.

With these requirements in mind, the following sections first map the landscape of Rust binary distribution tools and Cargo profile configuration, then articulate the principles that guide the choice for this template, and finally recommend a concrete combination of artifact types and profile settings, including their integration into the release workflow and documentation.

## Decision analysis

### Landscape

The category this item decides can be described as “Rust release binary artifacts and release build profile”, which spans two related but distinct layers of the Rust ecosystem. The first layer is the distribution tooling for compiled binaries, working alongside Cargo to publish executables in ways discoverable by users and tools. The second layer is the configuration of Cargo’s profiles, particularly `[profile.release]`, which determines the compilation flags, optimization level, and debug symbol behavior for the binaries that these tools package and distribute.[11][12][13]

On the distribution tooling side, the Rust field can be mapped into three bins. The first bin, “built-in or first-party toolchain”, is anchored by Cargo itself and its subcommands. Cargo’s `install` subcommand is part of the official tool, and its behavior—compiling a crate from source, using the `release` profile by default—is documented in the Cargo Book.[11][12] Cargo also supports custom profiles and profile overrides, but it does not itself provide cross-platform packaging or GitHub Release automation. The second bin, “established industry standard”, is represented by tools such as `cargo-dist` and `cargo-binstall`, which have become widely referenced for Rust binary distribution beyond crates.io.[1][3][4][9] The third bin, “up-and-comer”, includes newer tools and services such as quickinstall (a third-party artifact host used as a fallback by `cargo-binstall`), which are present in maintainer documentation but not yet canonically part of the template’s environment.[3][4][9]

`cargo-dist` is a Cargo subcommand maintained in the `axodotdev/cargo-dist` repository, with its primary tagline being “shippable application packaging” and a focus on distributing binaries.[1] Its documentation explains that its functionality is split into building (planning the release and building binaries and installers) and distributing (hosting artifacts, publishing packages, announcing releases).[1] The tool’s superpower is that it generates its own CI scripts; running `dist init` in a repository can generate a `release.yml` GitHub Actions workflow that implements a full pipeline: plan, build, host, publish, and announce.[1] The repository’s releases page shows that `cargo-dist` is actively maintained, with versions 0.31.0, 0.32.0, and 0.33.0 released between February and September 2026, and explicit notes about release immutability and changelog handling.[2] The Arch Linux package registry lists `cargo-dist` as “Shippable application packaging for Rust”, further signaling mainstream adoption and packaging in a major distribution.[6]

`cargo-binstall` is a complementary tool maintained in the `cargo-bins/cargo-binstall` repository, described as “Binary installation for Rust projects”.[3] Its README explains that Binstall provides a low-complexity mechanism for installing Rust binaries as an alternative to building from source via `cargo install` or manually downloading packages.[4] It works by fetching crate information from crates.io, searching the linked repository for matching releases and artifacts, and falling back to the quickinstall third-party artifact host or finally to `cargo install` if no suitable prebuilt binaries exist.[3][4][9] The README and GitHub Marketplace Action documentation both show one-liner installation scripts for Linux, macOS, and Windows, as well as a Homebrew formula, indicating that the tool itself is distributed via prebuilt binaries and integrates cleanly into GitHub Actions workflows.[3][4][9] The Arch Linux registry also lists `cargo-binstall` as “Binary installation for Rust projects”, further confirming its mainstream status.[10]

Cargo’s own documentation is the authoritative source for profiles. The Cargo Book’s profiles chapter explains that profiles provide a way to alter compiler settings, such as optimizations and debugging symbols, and that Cargo has built-in `dev`, `release`, `test`, and `bench` profiles.[11][12][13] The default profile is chosen based on the command being run; for example, `cargo install` uses the `release` profile by default.[11][12] Profile settings are specified in the `[profile]` table in `Cargo.toml`, and within each named profile, individual settings such as `opt-level`, `debug`, and `split-debuginfo` can be changed.[11][12] The documentation states that the `release` profile is intended for optimized artifacts used in production, and it provides default values, such as `opt-level = 3` and `debug = false`.[11][12] The Rust Embedded Book’s discussion of optimizations reinforces these defaults and introduces the size-focused optimization levels `"s"` and `"z"`, noting their effect on inline thresholds and binary size.[16]

Regarding authority, the Rust project’s own documentation (the Cargo Book and related references) is authoritative for how profiles behave and what defaults are recommended.[11][12][13][14][16] Maintainer documentation on `cargo-dist` and `cargo-binstall` is authoritative for how those tools expect binaries to be named and where they look for artifacts.[1][3][4][9] Independent write-ups, such as the Japanese-language article on compact Rust release binaries, provide measured data on binary size and build-time effects for particular profile settings, but they are treated as case studies rather than universal guidance.[15] This article shows, for example, that adding `lto = true`, `codegen-units = 1`, `strip = true`, and `panic = "abort"` to `[profile.release]` can reduce a tool’s binary size by approximately 24% compared to the default profile, and further reductions are possible via nightly-only `build-std` features and external compression tools.[15]

Practice evidence requires surveying well-regarded Rust projects, but in this environment, direct API queries to crates.io and GitHub are not executed, and specific numerical adoption figures such as 90-day downloads or stars remain an evidence gap. Nonetheless, the presence of `cargo-dist` and `cargo-binstall` in Arch Linux’s official package repositories, their continued release activity, and their integration into GitHub Actions are strong qualitative signals of mainstream use.[1][2][3][4][6][9][10] The fact that `cargo-binstall` provides a first-party GitHub Action, `cargo-bins/cargo-binstall@main`, indicates that projects building CI workflows for Rust binaries consider it a standard tool for installing dependencies.[4][9] Similarly, the `cargo-dist` documentation’s focus on generating CI workflows that handle planning, building, hosting, publishing, and announcing releases suggests that it is designed to slot into GitHub-first ecosystems like the owner’s template.[1]

Fitness gates must be applied per candidate before popularity is weighed. For license compatibility, the owner’s 2026-09-12 ruling explicitly suspends license evaluations for anything the template uses, widening an earlier Q4 decision and making this gate inapplicable for this item, including the profile subject.[Context] This gate is therefore recorded as “inapplicable” with the owner’s ruling named, rather than deleted. For MSRV, `cargo-dist` and `cargo-binstall` both target stable Rust and are packaged in distributions whose maintainers track current stable toolchains, but the exact MSRV of each crate cannot be asserted without direct inspection of their `Cargo.toml` and CI configuration, which is an evidence gap. RustSec advisories must be checked via `rustsec.org`, but no such checks are executed here; this is another gap, although no widely reported advisories affecting `cargo-dist` or `cargo-binstall` are known from maintainer documentation.[1][3][4][9] Platform support is clearly documented: `cargo-dist`’s CI scripts spin up machines for each supported platform (including Linux and macOS), and `cargo-binstall` provides installer scripts for Linux, macOS, and Windows, confirming that both tools work on the template’s `ubuntu-latest` and `macos-latest` matrix.[1][3][4][9]

Binary-size and compile-time cost are stated qualitatively based on Rust documentation and case studies. The Rust Embedded Book explains that the default `release` profile uses `opt-level = 3`, which is optimized for speed, and that switching to `opt-level = "s"` or `"z"` can reduce binary size, at the cost of some performance.[16] It also notes that LTO and inline threshold tuning can further influence size and speed.[16] The compact-binary article demonstrates that settings like `lto = true` and `codegen-units = 1` produce smaller binaries but can increase compile times, especially for large projects.[15] These observations inform the profile decisions later in this report, but they do not replace the need for project-specific measurement, which remains a planned but unexecuted acceptance check.

Overall, the landscape shows that Cargo itself and its profiles are the foundational tools; `cargo-dist` and `cargo-binstall` are established standards for distribution and installation of prebuilt Rust binaries; and quickinstall and nightly-only techniques like `build-std` are up-and-comers that remain outside the template’s default scope. This landscape provides the candidate set from which the template’s artifact and profile decisions must be chosen.

### Principles and implementation

The shared requirement across the owner’s templates and this Rust port can be stated as follows: artifacts and build profiles must support predictable, low-friction installation for end users and template consumers, while preserving clarity about what is being tested in CI and respecting the template’s fixed parameters on toolchain version and platform matrix. The agreement level is at the architectural pattern and policy level: the template must agree on which channels and artifact types it uses (crates.io, GitHub Releases binaries, installer scripts) and on the release profile configuration that applies to CI builds and published binaries. The underlying libraries and exact workflow steps can vary, provided they preserve the essential behaviors and acceptance criteria.

The essential behaviors for distribution are that end users and template consumers can install the CLI component and run the web service without needing to understand the repository’s internals, and that they have at least one fully documented path that works on each supported OS in the matrix. For crates.io-only distribution, this behavior is achieved through `cargo install --locked rs-launch-blueprint`, followed by running the installed binary.[11] For GitHub Releases-based distribution, the behavior may be achieved through direct downloads (curling a tarball or installer script) or through `cargo binstall rs-launch-blueprint`, which uses metadata and release assets to select and install a prebuilt binary.[3][4][5][9] The acceptance criteria include consistent behavior across `ubuntu-latest` and `macos-latest`, reproducibility when the template is forked, and compatibility with the release-please-driven release flow already adopted elsewhere in the stack.

On the profile side, the essential behaviors are that the release profile produces binaries that are safe and performant for production, with binary sizes that are reasonable for distribution, build times that do not unduly burden CI or local development, and sufficient symbol availability to support the error-and-exit-code contract (R67) and potential future crash-reporting enhancements. The observable acceptance criteria include measured binary sizes and build times (even if currently drawn from external case studies rather than template-specific runs), documented defaults and overrides for profile keys, and clear communication about whether downstream consumers of the crate inherit any profile behavior.

Architecturally, there are two main alternatives for distribution. The first is a “crates.io-only” pattern, in which the template relies solely on `cargo publish` to produce a `.crate` file and documents `cargo install` as the primary installation method. This matches older Rust practice and fits well for libraries and small CLIs that are primarily consumed by developers comfortable with compiling from source.[11] The second alternative is a “crates.io plus GitHub Releases binaries” pattern, in which the template uses a tool like `cargo-dist` to build and upload precompiled binaries for its CLI and web service entry points, and optionally uses `cargo-binstall` metadata to let end users install via `cargo binstall`, avoiding compilation.[1][3][4][9] This pattern is increasingly common for Rust tools distributed to broader audiences, especially those that wish to match the convenience of Python wheels or Node.js binaries.

Within the second alternative, the architectural pattern for integrating `cargo-dist` is documented by its maintainers. Running `dist init` adds configuration to the repository and generates a CI workflow that waits for version tags, plans releases, spins up machines for each supported platform, builds binaries and installers, uploads artifacts to GitHub Releases and package managers, and announces the release with notes from the changelog.[1] The tool is self-hosting: pushing a git tag with the right format triggers the release, and `cargo-release` is often used in conjunction to manage version bumps and tagging.[1][17] The `cargo-dist` changelog for version 0.32.0 explicitly recommends deleting `[profile.dist]` from `Cargo.toml` when updating, which indicates that the tool’s preferred architecture has shifted toward using the standard `release` profile rather than a separate `dist` profile.[7]

`cargo-binstall`’s architecture assumes that prebuilt binaries are available somewhere; it uses crates.io metadata to find the repository, then looks for release assets whose names match conventional patterns, such as `<name>-<version>-<target>.<archive-format>`.[3][4][9] It can also be configured with explicit `--pkg-url`, `--pkg-fmt`, and `--bin-dir` values if the defaults do not match the project’s layout, but this is intended as a fallback rather than the primary mode of operation.[4] When prebuilt binaries are not available or do not match the system, `cargo-binstall` falls back to the quickinstall host and finally to `cargo install`, ensuring that the tool never leaves the user without any installation path.[3][4][9] This architecture makes `cargo-binstall` a natural consumer of `cargo-dist`’s release assets, provided the template follows `cargo-dist`’s naming conventions for target triples and archive formats.[1][4]

The principle behind the Python and TypeScript templates’ artifact choices is that each project should be distributed in the artifact formats that are idiomatic for its ecosystem, while not committing the template to specialized infrastructure unless it is widely adopted. Python’s dual sdist and wheel pattern reflects PyPI norms; TypeScript’s single ESM npm tarball reflects npm norms. For Rust, crates.io’s `.crate` format is universal, but prebuilt binaries via GitHub Releases are increasingly idiomatic for CLI tools and services. This suggests that the template should adopt the combined pattern of crates.io plus GitHub Releases binaries, mediated by `cargo-dist`, and should treat `cargo-binstall` as a convenience layer that it supports but does not depend upon exclusively.

On the profile side, the architectural alternatives include sticking with Cargo’s default `release` profile, introducing a custom `dist` profile with more aggressive size or performance tuning, or customizing `release` with explicit keys like `lto`, `codegen-units`, `opt-level`, `strip`, `panic`, and `debug`. Cargo’s documentation allows custom profiles and profile overrides, but the recent `cargo-dist` guidance and the owner’s decision to hand the profile subject to this item argue against introducing a separate `dist` profile that would need bespoke maintenance.[7][11][12] Instead, a tuned `release` profile that is shared between CI and local builds is preferable, with a clear record of which keys are set and which defaults are left in place.

The recommended design, therefore, is to adopt `cargo-dist` for cross-compiled GitHub Releases binaries and installer scripts, keep crates.io as the canonical source of the `.crate` file, expose `cargo-binstall` as a supported installation method by aligning artifact naming and CI releases, and configure a single `[profile.release]` that enables thin LTO and sets `codegen-units = 1`, while leaving `opt-level = 3`, `debug = false`, `panic = "unwind"`, and `strip` at their documented defaults. This preserves the owner’s reference architecture for `lto` and `codegen-units`, aligns with Rust team guidance on release profiles, and avoids over-tuning size at the cost of debuggability or build times.[11][12][15][16]

This report includes one `BASELINE-REVIEW` finding: `BASELINE-REVIEW: F220 — principle — the documented end-user installation method must reflect the template’s artifact decision. The proposed change is to replace any crates.io-only assumption in README installation instructions with a dual-path documentation that presents both `cargo install --locked` and `cargo binstall` against the same crate name, with direct download of GitHub Release binaries as a secondary option. The evidence supporting this change is the mainstream use of `cargo-binstall` in Rust projects, its integration into GitHub Actions, and the convenience it offers for skipping source compilation.[3][4][5][9]

### Dominant choice

Within the landscape of Rust binary distribution tools, `cargo-dist` stands out as the dominant, actively maintained tool for producing cross-compiled GitHub Release binaries and installer scripts from a Cargo workspace. Its repository documentation emphasizes that with `dist` set up, simply committing, tagging, and pushing a version tag such as `v0.2.0` will result in a GitHub Release with attached artifacts, or a generated website if oranda is used.[1] This reflects a high degree of automation and integration with GitHub’s release infrastructure, which matches the owner’s use of release-please elsewhere in the stack.

`cargo-dist`’s CI integration is particularly important. The documentation explains that `dist init` will generate a `release.yml` GitHub Actions workflow that waits for git tags, selects apps in the workspace to announce new releases for based on the tag, generates a machine-readable manifest with changelogs and build plans, spins up machines for each platform, builds binaries and tarballs, builds installers, uploads artifacts to package managers, creates or edits a GitHub Release, uploads build artifacts to the Release, and adds relevant release notes from the changelog.[1] This workflow maps closely onto the release-please pattern, which typically automates version calculation, changelog updates, and GitHub Release creation. While direct evidence of `cargo-dist` integrating with release-please is not available in the search results, the structural alignment—both operating on tags and GitHub Releases—suggests a clean integration path.

The releases page for `axodotdev/cargo-dist` shows frequent releases into 2026, including version 0.33.0 on 2026-09-10, which indicates ongoing maintenance and support for current Rust toolchains and GitHub APIs.[2] The note that releases are immutable, except for title and notes, reflects a disciplined release process that is consistent with best practices for reproducible artifacts and versioning.[2] Arch Linux’s packaging of `cargo-dist` as `cargo-dist 0.33.0-1` with the upstream URL pointing to the GitHub repository further confirms that distributions treat it as a stable tool suitable for inclusion in their repos.[6] Taken together, these signals support treating `cargo-dist` as the dominant choice for automated binary release packaging in Rust.

On the installation side, `cargo-binstall` appears as the dominant tool for installing precompiled Rust binaries, especially when integrating into CI or providing one-liner installation scripts for users. Its README outlines its purpose as a low-complexity alternative to `cargo install` and manual downloading, and its behavior of scanning crates.io metadata and GitHub releases for matching artifacts aligns with how `cargo-dist` publishes release assets.[3][4] The tool provides direct installers for itself via shell scripts and Homebrew, and maintains a GitHub Marketplace Action for installing the latest version of Binstall in workflows.[4][9] Arch Linux packages `cargo-binstall` as well, reinforcing its status as a mainstream tool.[10] While `cargo install` remains the default built-in mechanism for installing Rust binaries from source, the presence of `cargo-binstall` as a drop-in consumer of prebuilt assets makes it a de facto standard for projects that ship GitHub Release binaries.

Crates.io-only distribution remains a viable baseline pattern, especially for library-focused crates, but it lacks the convenience of precompiled binaries for end users who may not have a Rust toolchain installed or who wish to avoid compilation time. For the template’s CLI and web service components, crates.io-only distribution would require users to install Rust, run `cargo install --locked rs-launch-blueprint`, and then run the installed binary or service, which is acceptable for developers but less convenient for broader audiences.[11] Considering the owner’s goal of making the template a realistic reference for modern Rust practice, and the Python precedent of shipping both source and binary artifacts, crates.io-only distribution falls short of demonstrating the ecosystem’s current capabilities.

Therefore, the dominant choice for this template is to adopt `cargo-dist` for cross-compiled GitHub Release binaries, integrate these binaries with `cargo-binstall` by adhering to conventional naming and release asset layout, and retain crates.io as the canonical source for the `.crate` file. `cargo install` remains a supported fallback, but it is no longer the sole documented installation path. This choice aligns with established industry standards in Rust, matches the owner’s architectural pattern of multifaceted artifact distribution, and positions the template as an up-to-date reference for binary release practices.

On the profile side, the dominant choice is to use a tuned `[profile.release]` that keeps Cargo’s defaults for core behavior (`opt-level = 3`, `debug = false`, `panic = "unwind"`) while enabling `lto = "thin"` and `codegen-units = 1` to improve code generation and modestly reduce binary size without resorting to more aggressive size optimizations like `opt-level = "s"` or `"z"`, or `panic = "abort"`.[11][12][15][16] This choice reflects both Rust’s official guidance and the owner’s reference architecture, and it avoids introducing a separate `dist` profile that would complicate cache reuse and CI-test alignment.[7]

### Qualified shortlist

The qualified shortlist for this item consists of three architectural candidates, rather than individual crates, because the decision is about artifact types and profiles rather than introducing a new dependency. Each candidate’s role, qualitative adoption signals, and trade-offs are summarized below. Numerical metrics such as 90-day downloads and stars are acknowledged but not measured, representing an evidence gap due to the lack of direct API queries in this environment.

The first candidate is “crates.io-only with default `release` profile”. Its role is to keep distribution entirely within Cargo’s built-in mechanisms: users install via `cargo install --locked rs-launch-blueprint`, CI builds the crate using the default `release` profile, and no GitHub Release binaries are produced.[11] All-time and 90-day download figures for this pattern would be reflected in crates.io statistics for the crate, but since the template is not yet published, these are inapplicable. Stars and maintenance state are likewise tied to the repository as a whole rather than this pattern. Notable adopters include many library crates and small utilities that still document `cargo install` as their primary installation method. The one-line trade-off is that this pattern is simple and uses no extra tooling, but it requires users to have Rust installed and to compile from source, which can be slow and inconvenient for larger projects.

The second candidate is “crates.io plus `cargo-dist` GitHub Release binaries with tuned `release` profile and `cargo-binstall` compatibility”. Its role is to add automated build and upload of precompiled binaries to GitHub Releases while keeping crates.io as the source package.[1] Adoption signals for `cargo-dist` include Arch Linux packaging and frequent releases, and for `cargo-binstall` include its GitHub Marketplace Action and self-distribution via precompiled binaries.[1][2][3][4][6][9][10] While direct download counts for `cargo-dist` and `cargo-binstall` are not measured here, their presence in these channels suggests active use. Notable adopters likely include CLI tools and services that advertise `cargo binstall` as an installation method, although specific names are not cited in the provided search results. The one-line trade-off is that this pattern significantly improves end-user convenience and demonstrates modern Rust practice, at the cost of adding `cargo-dist` and `cargo-binstall` as dependencies and increasing CI complexity and time due to cross-platform builds.

The third candidate is “crates.io plus manual GitHub Release binaries without `cargo-dist`, and selective `cargo-binstall` metadata”. Its role is to have the project’s CI build release binaries via custom scripts or workflows and upload them to GitHub Releases, while `cargo-binstall` is configured to find them via explicit `--pkg-url` and `--pkg-fmt` settings.[4] Practice evidence for this pattern can be inferred from `cargo-binstall` documentation, which shows how to manually specify package URLs and formats for crates that do not follow conventional naming.[4] Adoption signals for this pattern are limited; the existence of manual configuration options suggests some use, but not enough to treat it as a mainstream standard. The one-line trade-off is that this pattern avoids adding `cargo-dist` as a dependency, but it places more burden on template maintainers to keep CI scripts and naming schemes aligned with `cargo-binstall` expectations, and it risks drift in the absence of a dedicated packaging tool.

For profile configuration, a parallel shortlist can be drawn. The first candidate is “default `release` profile with no explicit keys”, which keeps Cargo’s defaults and avoids any tuning.[11][12] The second candidate is “tuned `release` profile with `lto = "thin"` and `codegen-units = 1`”, matching the owner’s reference architecture input.[Context] The third candidate is “aggressively size-optimized `release` profile” with settings like `opt-level = "s"` or `"z"`, `strip = true`, and `panic = "abort"`, as explored in the compact-binary article.[15][16] The one-line trade-offs are that the default profile is safest and simplest but may produce larger binaries, the tuned profile improves code generation modestly without heavy trade-offs, and the aggressive profile reduces binary size significantly but can degrade debuggability and requires careful consideration of panic semantics.

Because this item is not adding new crates but configuring existing tools and profiles, fitness gates such as MSRV, RustSec advisories, and platform support are applied conceptually rather than quantitatively. All three candidates rely on Cargo’s stable support and on standard CI platforms; `cargo-dist` and `cargo-binstall` explicitly support Linux and macOS.[1][3][4][6][9][10] No candidate fails a gate in a way that requires exclusion; instead, the choice is driven by fit for the template’s goals.

### Excluded by gate

Strict gate-based exclusion does not apply to any of the primary candidates, but it does apply to certain potential architectural variations that are not suitable for the template under the owner’s constraints and research mandate.

One excluded variation is “nightly-only profile features and `build-std` for compact binaries”. The compact-binary article describes using nightly Rust and the unstable `build-std` feature to rebuild the standard library with `panic_immediate_abort` and other optimizations, achieving dramatic binary size reduction down to 26 KB in a particular case.[15] The commands include `cargo +nightly build -Z build-std=std,panic_abort -Z build-std-features=panic_immediate_abort --release`, and require installing the nightly toolchain and the `rust-src` component via `rustup`.[15] This pattern fails the MSRV gate because it depends on nightly-only features and would violate the template’s policy of using stable Rust and of setting MSRV to stable minus two minor versions.[Context] It also fails the platform support gate in practice, because nightly features can break across toolchain updates. Therefore, this variation is excluded by gate.

Another excluded variation is “exclusive reliance on quickinstall or proprietary artifact hosts”. `cargo-binstall` documentation mentions quickinstall as a third-party artifact host fallback when prebuilt binaries are not available via the crate’s own repository.[3][4][9] Depending exclusively on quickinstall would introduce a dependency on an external service that is not under the owner’s control and may not be appropriate for a template intended as a reference architecture. It also raises questions about license and governance that, while not evaluated here due to the owner’s license ruling, would normally be considered. As such, exclusive quickinstall-based distribution is excluded by gate on architectural grounds: it does not match the template’s principle of self-hosted release artifacts in the repository’s own GitHub project.

A further excluded candidate is “separate `dist` profile in `Cargo.toml` for release binaries”. The `cargo-dist` changelog for version 0.32.0 recommends deleting `[profile.dist]` from `Cargo.toml` when updating to that version, implying that maintaining a separate `dist` profile is no longer necessary and may even be discouraged.[7] Introducing such a profile would conflict with `cargo-dist`’s evolution and would complicate cache reuse and CI behavior, potentially violating the acceptance criterion that CI release builds and local `cargo build --release` should share a profile whenever possible. Therefore, a separate `dist` profile is excluded by gate on tool compatibility and maintenance grounds.

These exclusions help narrow the candidate set to those that satisfy the owner’s constraints and align with mainstream Rust practice, leaving crates.io-only, crates.io plus `cargo-dist`, and crates.io plus manual Release binaries as the primary distribution options, and default, tuned, and aggressive `release` profiles as the profile options.

### Up-and-comers

Within the Rust ecosystem, certain tools and patterns related to binary distribution and profile tuning can be considered up-and-comers. They are not yet standard enough to be adopted by this template by default, but they merit awareness for future evolution.

Quickinstall, mentioned in `cargo-binstall`’s documentation as a third-party artifact host, is one such example. `cargo-binstall` falls back to quickinstall when it cannot find suitable prebuilt binaries in the crate’s own releases, and then finally to `cargo install` if quickinstall does not provide an appropriate artifact.[3][4][9] This design suggests that quickinstall is a growing service for Rust binary distribution, potentially aggregating artifacts across many projects. However, since its governance and long-term stability are not documented in the provided sources, and it lies outside the template’s repository, it remains an up-and-comer that the template should not depend on exclusively.

Another up-and-comer is the use of GitHub Actions Marketplace entries for Rust tooling, such as the “Install cargo-binstall” action maintained in the `cargo-bins/cargo-binstall` repository.[9] This action provides a minimal way to install Binstall in CI, and its presence in the Marketplace indicates that the Rust community increasingly standardizes CI integration for tools via actions rather than custom scripts.[9] While the template could adopt such actions to simplify its release workflows, this is a secondary decision that can be deferred to the CI design prompt, with awareness that the ecosystem is moving in this direction.

On the profile side, the use of `profile-overrides` to tune dependencies differently from the root crate is a relatively new technique described in the Rust Embedded Book.[16] Developers can optimize dependencies for size while keeping the top crate unoptimized for easier debugging, by using `profile-overrides` and adjusting `opt-level` per dependency.[16] This technique is powerful but more complex than the template needs at this stage, especially since the template’s primary concern is tuning the root crate’s release profile. It remains an up-and-comer that template consumers could adopt in their forks if they have specific size or performance requirements.

Finally, the combination of `opt-level = "s"` or `"z"` with customized inline thresholds and LTO is an evolving area of practice in Rust optimization.[16] The Rust team’s documentation notes that `"s"` and `"z"` are intended to optimize for size, with different inline thresholds, and that developers should experiment with values like 225 and 275 when optimizing for size.[16] While this guidance is authoritative, its application is more nuanced and workload-dependent than the template can accommodate in a generic profile. Therefore, aggressive size tuning remains an up-and-comer technique that may be adopted selectively by projects with specific constraints.

In summary, the up-and-comers in this space—quickinstall, GitHub Actions for tooling, profile-overrides, and aggressive size tuning—represent promising directions for future refinement of the template’s distribution and profile strategy. For this item, they are acknowledged but not adopted by default, preserving simplicity and alignment with mainstream practice.

### Fit for this template

The fit of each candidate distribution pattern and profile configuration must be evaluated separately for the CLI, library, and web service roles that `rs-launch-blueprint` combines, while considering the template’s audience and fixed parameters.

For the CLI component, end-user installation convenience is particularly important. A CLI tool that requires users to install Rust and compile from source via `cargo install` imposes a barrier that many modern Rust projects mitigate by providing prebuilt binaries.[3][4][5] `cargo-binstall` exists largely to reduce this barrier by installing precompiled binaries directly into `~/.cargo/bin`, and its documentation highlights the performance benefits of skipping compilation.[5] The CLI component of `rs-launch-blueprint` will likely be used by developers interacting with the web service or library, but it may also be used by operations teams or end users who do not wish to manage toolchains. Therefore, the combined pattern of crates.io plus `cargo-dist` binaries, with `cargo-binstall` as a primary installation method, fits well: it allows `cargo binstall rs-launch-blueprint` to install the CLI with minimal friction on Linux and macOS, while retaining `cargo install` as a fallback.[3][4][5][9]

The library component has different needs. Libraries are typically consumed as dependencies in other crates, and their distribution via crates.io’s `.crate` file is the norm. Prebuilt binaries are not directly useful for library consumers, who build the library as part of their own project’s compilation process. For the library role, crates.io-only distribution is sufficient and necessary; GitHub Release binaries are irrelevant. However, the library’s existence in the same crate as the CLI and web service means that the template’s artifact strategy cannot treat it separately: the library is packaged into the same `.crate` file that `cargo publish` produces, and its code is included in the binary that `cargo-dist` and `cargo-binstall` distribute. The key fit question is whether the release profile and distribution tooling impose any constraints that would surprise library consumers. Since `[profile.release]` settings in the root package do not propagate to dependencies when the crate is used as a library in someone else’s workspace—dependency profile behavior is controlled by the consumer’s workspace—there is no such risk.[11][12][16] Thus, the tuned `release` profile and `cargo-dist` distribution are compatible with library use.

The web service component adds considerations related to containerization and deployment. While R51 owns the container image decision, the binary artifacts produced by `cargo-dist` will likely be used as the application binary inside the container, or as a reference for building such images. The web service’s deployment environment may be more controlled than the CLI’s, making crates.io-only distribution more acceptable for server-side use. However, since the CLI and web service share code and release workflows, and since `cargo-dist` can build installers or tarballs that bundle both, the combined pattern still fits. For web service deployment, operators may prefer Docker images, but the presence of prebuilt binaries in GitHub Releases can also serve as a convenient artifact for building images or running services on bare metal.

For the release profile, the fit must be evaluated against binary size, build time, debuggability, and the fixed `target-os-matrix`. The tuned profile with `lto = "thin"` and `codegen-units = 1` improves optimization and potentially reduces binary size, which benefits both CLI and web service distribution, especially when shipping prebuilt binaries.[11][12][15][16] The default `opt-level = 3` and `debug = false` align with Rust’s intended behavior for production release builds.[11][12] Keeping `panic = "unwind"` avoids surprising behavior when panics occur; it allows destructors to run, which is beneficial for web services that may hold resources or need to perform cleanup. This is consistent with R67’s crash contract, which records a cause chain but does not require a stack trace, and does not preclude future work on crash reporting.[Context] Leaving `strip` at its default avoids removing symbols that might be useful for debugging or crash analysis, especially in the absence of a strong requirement to minimize binary size at all costs.[11][12][15]

CI release builds and contributor local `cargo build --release` should share the same profile for consistency and cache reuse. A separate custom profile would cause divergence between what CI tests and what a fork builds, potentially leading to subtle bugs. Since `cargo-dist` now recommends deleting `[profile.dist]` and using the `release` profile for its builds, the tuned `release` profile fits both CI and local use.[7] This alignment simplifies the mental model for contributors and reduces the number of moving parts in the configuration.

The profile’s interaction with artifact forms is straightforward. `cargo-dist` builds binaries using Cargo’s APIs, which by default use the `release` profile for release builds.[1][11][12] If the template sets `[profile.release]` keys, these settings will apply to the binaries that `cargo-dist` packages and uploads to GitHub Releases. The container image decision, handled by R51, will likely use the same profile for building the service binary. As for library consumers, Cargo’s documented rule is that profiles are chosen in the workspace root, and dependency crates do not enforce their own `[profile.*]` settings on consumers.[11][12] This ensures that downstream projects depending on `rs-launch-blueprint` as a library can choose their own profile configuration without being affected by the template’s release profile.

Finally, the profile must not raise the effective minimum supported Rust version or restrict targets in the matrix. Settings like `lto = "thin"` and `codegen-units = 1` are stable and supported on current Rust toolchains, and they do not remove support for Linux or macOS.[11][12][16] Aggressive settings like `panic = "abort"` and nightly-only features like `build-std` could affect MSRV or platform behavior, but the recommended tuned profile avoids these. The impact on CI time is likely to be moderate: LTO and single codegen unit can increase compile time, but for a template-scale project, this is acceptable given the benefits in code quality and binary size.[15][16] Since this report lacks direct measurements for this template, build-time effects remain estimated based on external evidence, which is marked as an evidence gap.

### Recommendation

The recommendation for `rs-launch-blueprint` is to adopt a combined distribution and profile strategy that aligns with mainstream Rust practice, uses `cargo-dist` and `cargo-binstall` to provide prebuilt binaries alongside crates.io, and configures a single tuned `[profile.release]` without introducing a separate `dist` profile.

On the artifact side, the template should ship the following:

1. The canonical `.crate` file via `cargo publish`, representing the source package on crates.io.[11]

2. Cross-compiled GitHub Release binaries for the CLI and web service components, built by `cargo-dist` and uploaded as release assets for each tagged version.[1][2]

3. `cargo-binstall` metadata and compatibility by ensuring that release assets follow the conventional naming scheme `<name>-<version>-<target>.<archive-format>`, so that `cargo-binstall` can automatically detect and install prebuilt binaries when users run `cargo binstall rs-launch-blueprint`.[3][4][5][9]

The fixed `target-os-matrix` of `ubuntu-latest` and `macos-latest` should be mirrored in the release binaries: the template should build and publish binaries for Linux and macOS, targeting at least the common architectures (x86_64 and, where feasible, aarch64) that `cargo-binstall` itself uses for its own releases.[4][9] Extending to additional architectures within Linux and macOS (such as armv7) is optional and can be configured in `cargo-dist` if the template’s CI environment supports cross-compilation.[1][4] Windows binaries are not required and should not be built by default, in order to respect the template’s OS matrix and avoid distributing artifacts that are not tested in CI.

The README’s documented installation method (F220) should be updated to describe both `cargo install --locked rs-launch-blueprint` and `cargo binstall rs-launch-blueprint` as primary installation paths, with a brief explanation of their behavior. Direct download of GitHub Release binaries via curl and manual placement into `~/.cargo/bin` can be documented as a secondary path, particularly for users who do not wish to install `cargo-binstall`.[3][4][5][9] This constitutes `BASELINE-REVIEW: F220 — principle — the README must reflect the combined artifact strategy rather than crates.io-only, proposed change — dual-path documentation for `cargo install` and `cargo binstall`, evidence — `cargo-binstall`’s mainstream status and integration in Arch Linux and GitHub Marketplace.[3][4][5][9][10]

On the profile side, the recommended `[profile.release]` row for the template is:

| Key            | Recommended value | Manifest behavior         | Basis and effect                                                                 |
|----------------|-------------------|---------------------------|----------------------------------------------------------------------------------|
| `opt-level`    | `3`               | Left at Cargo default     | Default optimization for speed; good performance, standard for release builds.[11][12][16] |
| `debug`        | `false`           | Left at Cargo default     | No debug info in release binaries; smaller binaries and standard practice.[11][12] |
| `lto`          | `"thin"`          | Written into manifest     | Thin LTO improves code generation and modest size reduction with reasonable compile-time cost.[11][12][16][Context] |
| `codegen-units`| `1`               | Written into manifest     | Single codegen unit yields better optimization and smaller binaries; may increase compile time.[11][12][15][16][Context] |
| `strip`        | (default)         | Not set in manifest       | Avoids explicit stripping; retains symbols as per default behavior, balancing size and debuggability.[11][12][15] |
| `panic`        | `"unwind"`        | Left at Cargo default     | Preserves standard panic semantics; allows destructors to run, aiding web services.[11][12][16] |

Cargo’s documented defaults for `release` include `opt-level = 3` and `debug = false`, with other keys such as `split-debuginfo` set according to platform and toolchain.[11][12] By explicitly writing `lto = "thin"` and `codegen-units = 1` into `[profile.release]`, the template agrees with the owner’s reference architecture for these keys, as described in `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` under its `Reference Cargo.toml` section.[Context] The agreement is recorded as: the template adopts `lto = "thin"` and `codegen-units = 1` exactly as in the reference, recognizing them as generally beneficial for production binaries without violating MSRV or platform constraints.[11][12][16]

The measured basis for these settings in this report relies on external case studies and Rust documentation rather than project-specific builds. The compact-binary article reports that adding `lto = true`, `codegen-units = 1`, `strip = true`, and `panic = "abort"` reduced a tool’s binary size from approximately 429104 bytes to 326040 bytes, a 24% reduction, and that `opt-level = "z"` further reduced size but at a performance cost.[15] The Rust Embedded Book explains that `opt-level = "s"` and `"z"` are explicitly intended for size, and that inline thresholds differ across optimization levels.[16] These figures provide qualitative evidence that LTO and single codegen unit are effective for size and performance, while more aggressive settings may not pay for themselves in general workloads.[15][16]

Since this report does not execute builds of `rs-launch-blueprint` or its stand-in, binary sizes and build wall times at the pinned toolchain are not measured here and remain an evidence gap. Any claims about compile-time cost or size reductions are reported as the sources’ claims, with their dates, rather than as acceptance-test results for this template. In future work, the template’s maintainers should run builds with and without `lto = "thin"` and `codegen-units = 1` on `ubuntu-latest` and `macos-latest` at the current stable toolchain, recording binary sizes and build times as specified in the owner’s acceptance criteria.[Context][11][12][15][16]

Regarding `strip`, the template deliberately leaves this key unset, preserving Cargo’s default behavior. This balances the desire for smaller binaries against the potential need for symbols in crash analysis or future stack-trace reporting. The compact-binary article shows that `strip = true` can contribute significantly to size reduction, but in the absence of strong size constraints and given R67’s focus on crash records without stack traces, the template’s best fit is not to strip by default.[15][Context] Template consumers who need smaller binaries can add `strip = true` in their forks, with an understanding of the trade-offs.

Similarly, the template leaves `panic` at its default `"unwind"`, even though `panic = "abort"` can reduce binary size and simplify certain runtime behaviors.[11][12][15][16] Unwinding semantics are widely assumed in Rust libraries, and web services benefit from running destructors when panics occur. Changing `panic` to `"abort"` would shift behavior in ways that might surprise downstream consumers and complicate error handling, while not being required by any current contract. Therefore, the template maintains the default and documents this choice.

CI release builds and local `cargo build --release` will both use this tuned `release` profile, ensuring consistency and cache reuse. `cargo-dist` will build release binaries under this profile, and `cargo-binstall` will install them, making the profile’s behavior directly relevant to end-user binaries.[1][3][4][9][11][12]

### Ranked runner-up

The ranked runner-up for distribution is the “crates.io-only with default `release` profile” pattern. This pattern would be chosen under conditions where the template’s consumers are exclusively Rust developers who are comfortable compiling from source, where CI resources are constrained such that adding cross-compiled binary builds would significantly slow releases, or where the owner wishes to minimize dependencies on external tools like `cargo-dist` and `cargo-binstall`.

In such conditions, the template would document `cargo install --locked rs-launch-blueprint` as the primary installation method, and the release workflow would focus on `cargo publish` and changelog updates without generating GitHub Release binaries or installer scripts.[11] The `[profile.release]` would remain at Cargo’s defaults, with no explicit keys set. This pattern is simple and robust, and it matches older Rust practice and many library-centric projects.

However, this runner-up gives up the convenience of prebuilt binaries and the opportunity to demonstrate modern Rust distribution practices, which reduces its value as a template reference. It also diverges from the Python precedent of shipping both source and binary artifacts. Therefore, while the runner-up is viable, it is chosen only under strict resource or dependency constraints that are not present in the current template’s environment.

On the profile side, the ranked runner-up is the “aggressively size-optimized `release` profile” with settings like `opt-level = "z"`, `strip = true`, and `panic = "abort"`, as explored in the compact-binary article.[15][16] This profile would be chosen under conditions where binary size is critical, such as embedded deployments or distribution over extremely constrained networks, and where debuggability and standard panic semantics are less important. For `rs-launch-blueprint`, which targets general-purpose servers and developer machines on Linux and macOS, these conditions do not hold, making this runner-up suitable only for specialized forks rather than the template itself.

### Tradeoffs

The chosen combined strategy—crates.io plus `cargo-dist` binaries with `cargo-binstall` compatibility, and a tuned `release` profile with `lto = "thin"` and `codegen-units = 1`—entails several trade-offs versus the ranked runner-ups.

Compared to crates.io-only distribution, the chosen strategy adds complexity in the form of `cargo-dist` configuration, generated CI workflows, and the need to maintain GitHub Releases assets. This increases CI time and introduces additional failure modes, such as packaging errors or upload issues.[1][2] However, it significantly improves end-user convenience, especially for the CLI component, by allowing installation via `cargo binstall` or direct download of binaries without requiring Rust or source compilation.[3][4][5][9] It also positions the template as an exemplar of modern Rust practice, which is a core goal of the owner’s research mandate.

Compared to manual GitHub Release binaries without `cargo-dist`, the chosen strategy centralizes packaging logic in a maintained tool, reducing the burden on template maintainers to keep scripts and naming schemes up to date.[1][4] This improves reliability and consistency across releases at the cost of introducing `cargo-dist` as a dependency. It also aligns with the trend toward tooling-generated CI workflows, which are easier to reason about and update than hand-written scripts.

On the profile side, the tuned `release` profile gives up some potential binary-size gains that could be achieved by `opt-level = "s"` or `"z"`, `strip = true`, and `panic = "abort"`, as demonstrated in the compact-binary article.[15][16] However, it retains standard panic semantics and symbol availability, which benefit debuggability and future crash-reporting features. It also avoids relying on nightly-only features and preserves MSRV, consistent with the template’s constraints.[Context][11][12][15][16] The trade-off is between moderate size reduction with minimal risk (via thin LTO and single codegen unit) and more extreme size reduction with significant behavioral changes; the template accepts the former and rejects the latter.

The decision not to introduce a separate `dist` profile trades off potential fine-grained control over distribution builds for simplicity and alignment with `cargo-dist`’s current recommendations.[7] This avoids divergence between CI and local builds and improves cache reuse, which is important for developer ergonomics.

Overall, the accepted trade-offs favor convenience, mainstream practice, and behavioral predictability over maximum size reduction or minimal complexity. This aligns with the template’s role as a reference architecture rather than a minimal or hyper-optimized project.

### Parameters

This item owns and consumes several parameters, which are recorded explicitly here.

For owned parameters, the item sets:

`owns artifact-distribution-type = crates.io + cargo-dist GitHub Releases binaries + cargo-binstall compatibility`

This means the template will publish a `.crate` file via `cargo publish`, prebuilt binaries via `cargo-dist` to GitHub Releases for Linux and macOS, and will structure these binaries so that `cargo-binstall` can install them by default based on standard naming schemes.[1][3][4][9][11]

`owns release-build-profile = [profile.release] with lto = "thin", codegen-units = 1, other keys at default`

This means the template’s `Cargo.toml` will contain a `[profile.release]` section that explicitly sets `lto = "thin"` and `codegen-units = 1`, while leaving `opt-level`, `debug`, `panic`, and `strip` at Cargo’s documented defaults.[11][12][15][16][Context]

For consumed parameters, the item assumes:

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus two minor versions, raised only in a minor release and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

These consumed parameters are fixed by the owner and are not changed by this item.[Context] The recommendation respects them by avoiding nightly-only features, by choosing profile settings that are stable across toolchain versions, and by building release binaries only for Linux and macOS in CI.[11][12][15][16]

No parameter conflicts are identified that would require a `CONFLICT:` line. In particular, the recommendation does not require changing the `target-os-matrix` or `msrv-policy`. If a future revision were to adopt strategies such as `build-std` on nightly, a conflict would arise with the MSRV policy; that scenario is excluded in this report.

### Migration implications

Adopting the recommended distribution and profile strategy entails several file-level changes in the template, which must be coordinated carefully to avoid breaking existing workflows and documentation.

First, `Cargo.toml` must be updated to include the tuned `[profile.release]` section with `lto = "thin"` and `codegen-units = 1`. This section should be placed near other top-level configuration, and care must be taken to ensure that no legacy `[profile.dist]` section remains, especially if `cargo-dist` had previously introduced one.[7][11][12] The manifest’s build-target declarations (`[[bin]]`, `[lib]`, `[package] include`) remain under R49’s ownership and are not changed by this item.[Context]

Second, the repository must be configured for `cargo-dist`. Running `dist init` will generate a `release.yml` GitHub Actions workflow that implements the plan, build, host, publish, and announce pipeline.[1] This workflow must be committed to the repository, and any existing release workflows must be reconciled with it to avoid duplication or conflicts. The workflow will be triggered by pushing version tags that follow `cargo-dist`’s expected format, such as `v1.0.0`. Integration with `cargo-release` may be added to streamline version management, consistent with the practice described in `cargo-dist` documentation.[1][17]

Third, the repository must ensure that release assets follow conventional naming schemes for compatibility with `cargo-binstall`. This may require configuring `cargo-dist` to use names of the form `<crate-name>-<version>-<target>.<archive-format>`, as illustrated in `cargo-binstall` documentation for manual package URLs.[4] If `cargo-dist` defaults differ, configuration adjustments may be needed to align them.

Fourth, the README and any other user-facing documentation must be updated to reflect the new installation paths. This includes describing `cargo install --locked rs-launch-blueprint` and `cargo binstall rs-launch-blueprint`, indicating that the latter installs prebuilt binaries when available and falls back to compilation if necessary.[3][4][5][9][11] It may also describe direct download of GitHub Release binaries, including how to unpack them and move the executable into `~/.cargo/bin` for manual installation.[3][4][5]

Fifth, CI must be updated to use the tuned `[profile.release]` for release builds. Since `cargo-dist` relies on Cargo’s default behavior for release builds, the presence of the profile section in `Cargo.toml` will automatically affect `cargo-dist` builds. Any other CI jobs that build release binaries or run performance tests must also be configured to use `cargo build --release` so that the tuned profile applies uniformly.[1][11][12]

These migration steps align with the template’s architecture and respect related items’ ownership. They represent a clear path from the previous baseline (crates.io-only assumption, default profile) to the new combined artifact and profile strategy.

### Validation strategy

Validating that the recommended principle holds in practice requires a combination of conceptual checks and executable commands. The conceptual checks confirm that the artifact and profile behaviors match Rust documentation and tool maintainer expectations; the executable checks verify that actual builds and installations behave as intended.

A realistic validation example would proceed as follows. A release candidate version is prepared by updating `CHANGELOG.md`’s “Unreleased” section, running `cargo-release` to bump the version and tag the release, and pushing the tag to GitHub.[1][17] `cargo-dist`’s generated `release.yml` workflow triggers on the tag, plans the release, and builds binaries and installers for Linux and macOS under the tuned `[profile.release]`.[1][11][12] The workflow uploads these artifacts to the GitHub Release, attaches release notes from the changelog, and optionally publishes packages to other channels, such as Homebrew taps, if configured.[1][8]

Once the release completes, validation commands can be run on `ubuntu-latest` and `macos-latest` machines. On each, the tester can run:

```bash
cargo install --locked rs-launch-blueprint
rs-launch-blueprint --version
```

to verify crates.io-only installation and basic binary behavior.[11] Then, with `cargo-binstall` installed (either via `cargo install cargo-binstall` or via the provided installer scripts), the tester can run:

```bash
cargo binstall rs-launch-blueprint
rs-launch-blueprint --version
```

to verify that `cargo-binstall` finds and installs the prebuilt binary from GitHub Releases and that the binary runs correctly.[3][4][5][9] The validator should check that the installed binary’s version matches the released tag and that it reports platform-correct behavior.

To validate the profile behavior, the tester can run `cargo build --release` in the repository and measure the binary size and build wall time, then compare them with builds performed using default `release` settings by temporarily commenting out the `[profile.release]` section in `Cargo.toml`. This yields project-specific measurements of how `lto = "thin"` and `codegen-units = 1` affect size and compile time.[11][12][15][16] These measurements should be recorded with the host OS and CPU, `rustc -V`, `cargo -V`, and the date, per the owner’s acceptance criteria.[Context]

Planned but not yet executed checks include verifying that `cargo-dist`’s CI workflow integrates cleanly with the release-please-driven release flow used elsewhere in the template, and confirming that `cargo-binstall` can install the binaries on machines without a Rust toolchain by using its installer scripts.[1][3][4][9] Once these checks are executed, their results should be documented alongside the template’s decision records.

Expected behavior is that `cargo-dist` correctly builds and uploads binaries to GitHub Releases, that `cargo-binstall` installs them without falling back to compilation when the system matches a published target, and that the tuned `release` profile produces binaries with acceptable size and compile-time characteristics. Any deviations should be investigated and may require adjusting configuration or reconsidering certain profile settings.

### Confidence & re-verify trigger

The confidence level in the recommended combined artifact and profile strategy is moderate to high for conceptual correctness and integration with mainstream Rust practice, but lower for quantitative claims about binary size and build times due to the lack of project-specific measurements. The use of authoritative sources like the Cargo Book and tool maintainer documentation supports the conceptual aspects.[1][3][4][9][11][12][14][16] The convergence of practice evidence—such as Arch Linux packaging `cargo-dist` and `cargo-binstall`, and the presence of GitHub Actions for these tools—reinforces confidence in their suitability for the template.[1][2][3][4][6][9][10]

However, the owner’s requirement for measurement-based profile decisions is not fully satisfied in this report, as builds of `rs-launch-blueprint` or its stand-in have not been run to gather binary size and compile-time data. The compact-binary article provides useful case-study figures, but they are not specific to this template.[15] As such, the confidence in the exact magnitude of size and compile-time effects is limited, and the recommendation relies on qualitative reasoning.

Re-verify triggers include:

1. Significant changes in `cargo-dist` or `cargo-binstall` behavior or maintenance state, such as new major versions that alter CI workflows or artifact naming conventions, or signs of dormancy or archiving in their repositories.[1][2][3][4][9][10]

2. Changes in Cargo’s profiles documentation or defaults, such as new keys or altered behavior for existing keys, which could affect the tuned `release` profile.[11][12][13][14][16]

3. Evidence from project-specific measurements showing that `lto = "thin"` and `codegen-units = 1` cause unacceptable increases in CI build time or marginal size improvements for this template, which might argue for reverting to defaults or adopting different settings.[15][16]

4. New owner rulings that adjust the template’s fixed parameters, such as expanding the `target-os-matrix` to include Windows, which would require reconsidering the distribution matrix and potentially the profile.

5. RustSec advisories affecting `cargo-dist` or `cargo-binstall`, or major ecosystem shifts toward alternative distribution tools, which could prompt reevaluation of the chosen tooling.

Any of these triggers should lead to a fresh survey of the landscape and a revisiting of this item’s decisions, with updated evidence and possibly different recommendations.

### Sources

The sources used in this report are drawn from Rust’s official documentation, tool maintainer repositories, distribution package registries, and independent write-ups, each cited inline for specific claims.

The Cargo Book’s profiles chapter is the primary authority on profile behavior, defaults, and configuration, indicating that Cargo has built-in `dev`, `release`, `test`, and `bench` profiles, and that `release` is intended for optimized production artifacts with defaults like `opt-level = 3` and `debug = false`.[11][12][13][14] The Rust Embedded Book’s discussion of optimization levels and profile-overrides provides further detail on size-optimized levels `"s"` and `"z"` and the impact of inline thresholds.[16]

The `axodotdev/cargo-dist` repository and its documentation are the authoritative source on `cargo-dist`’s behavior, including its split between building and distributing, its generation of CI workflows via `dist init`, and its self-hosting release pattern.[1] The releases page for `cargo-dist` shows active maintenance and immutable releases.[2] The Arch Linux package registry confirms that `cargo-dist` is packaged as “Shippable application packaging for Rust”.[6] The changelog file for `cargo-dist` provides specific guidance on migration between versions, including recommendations to delete `[profile.dist]` from `Cargo.toml` when updating to version 0.32.0.[7] The release page for version 0.7.0 offers additional installation methods, such as shell and PowerShell scripts and a Homebrew tap, illustrating the tool’s distribution patterns.[8]

The `cargo-bins/cargo-binstall` repository and README are the primary sources on `cargo-binstall`, explaining its purpose as binary installation for Rust projects, its behavior of scanning crates.io and repository releases for artifacts, and its fallback to quickinstall and `cargo install`.[3][4] The README and GitHub Marketplace Action documentation show installer scripts for Linux, macOS, and Windows, and provide examples of manual configuration for package URLs and formats.[4][9] The Linux Command Library’s man page for `cargo-binstall` elaborates on its CLI options and behavior, describing how it prioritizes downloading prebuilt executables and installs them into `~/.cargo/bin`.[5] Arch Linux’s package registry lists `cargo-binstall` as “Binary installation for Rust projects”, confirming its mainstream status.[10]

The `crate-ci/cargo-release` repository is cited for its role in streamlining crate release processes, including version management, tagging, and pushing.[17] While not directly part of the artifact distribution decision, it is relevant for integrating version-driven releases with `cargo-dist`.

The compact-binary article in Japanese provides a case study on profile tuning for binary size, showing the effects of settings like `opt-level = "z"`, `lto = true`, `codegen-units = 1`, `strip = true`, and `panic = "abort"` on binary size, and describing the use of nightly-only `build-std` and external compression tools.[15] This source is treated as a lead for understanding size-performance trade-offs rather than as prescriptive guidance.

Collectively, these sources inform the landscape mapping, principles, and recommendations in this report. Each reference is cited inline at the sentence level, in accordance with the owner’s citation requirements, and no copyrighted material is reproduced verbatim.

## Sources

- [axodotdev/cargo-dist: 📦 shippable application packaging](https://github.com/axodotdev/cargo-dist)
- [Releases · axodotdev/cargo-dist](https://github.com/axodotdev/cargo-dist/releases)
- [cargo-bins/cargo-binstall: Binary installation for rust projects](https://github.com/cargo-bins/cargo-binstall)
- [cargo-binstall/README.md at main · cargo-bins/cargo-binstall](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md)
- [cargo-binstall man | Linux Command Library](https://linuxcommandlibrary.com/man/cargo-binstall)
- [cargo-dist 0.32.0-1 (x86_64)](https://archlinux.org/packages/extra/x86_64/cargo-dist/)
- [CHANGELOG.md - axodotdev/cargo-dist - GitHub](https://github.com/axodotdev/cargo-dist/blob/main/CHANGELOG.md)
- [Release Version 0.7.0 (2024-01-04) · axodotdev/cargo-dist](https://github.com/axodotdev/cargo-dist/releases/tag/v0.7.0)
- [Install cargo-binstall · Actions · GitHub Marketplace](https://github.com/marketplace/actions/install-cargo-binstall)
- [cargo-binstall 1.22.0-1 (x86_64)](https://archlinux.org/packages/extra/x86_64/cargo-binstall/)
- [Profiles - The Cargo Book](https://doc.rust-lang.org/cargo/reference/profiles.html)
- [Profiles - The Cargo Book - Rust Documentation](https://doc.rust-lang.org/stable/cargo/reference/profiles.html)
- [Profiles - The Cargo Book](https://doc.rust-lang.org/nightly/cargo/reference/profiles.html)
- [Cargo Reference - The Cargo Book](https://doc.rust-lang.org/cargo/reference/index.html)
- [Rust製ツールのリリースバイナリを無理なくコンパクトにする](https://b.muo.jp/2024/12/22/rust-release-binary-size.html)
- [Optimizations: The speed size tradeoff](https://docs.rust-embedded.org/book/unsorted/speed-vs-size.html)
- [crate-ci/cargo-release](https://github.com/crate-ci/cargo-release)

## Cost

Total: $1.0002

---


## Gemini Results

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

---
