# Deep-research prompt — Release binary artifacts (R68, crate)

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
- MEDIUM (profile 3): How do `strip`, `debug` and `panic` trade against symbol availability in a shipped binary — backtraces, crash reports, and specifically R67's (`error-and-exit-code-contract`) unexpected-error path and its sanitized crash record, which read whatever symbols survive — and what is the resulting recommendation for a binary distributed to end users who cannot rebuild it?
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
