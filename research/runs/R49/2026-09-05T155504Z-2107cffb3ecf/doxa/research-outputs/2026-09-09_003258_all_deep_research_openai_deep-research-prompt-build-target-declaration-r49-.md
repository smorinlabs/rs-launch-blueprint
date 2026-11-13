---
prompt: # Deep-research prompt — Build-target declaration (R49, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s Cargo manifest declares its build backend/output, entry points (CLI binary and library), console-script/bin entry, packaged-file whitelist, and any distribution-name-vs-entry-point-name divergence — the Rust analogue of py's `uv_build` PEP 517 backend plus `[project.scripts]`/layout settings and ts's `tsdown` bundler plus explicit `entry`/`bin`/`files` fields. Item kind: `crate`. Value test: if this answer is wrong, `Cargo.toml`'s `[package]`, `[[bin]]`, `[lib]`, and `include`/`exclude` fields, and any build-backend dependency, all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos have a build backend/bundler that produces the distributable package from source (the pattern), but the specific tool is language-bound in both — py's PEP 517 `uv_build` backend and ts's `tsdown` (rolldown) bundler. Evidence: py `pyproject.toml:133` — `build-backend = "uv_build"` (PEP 517); ts `tsdown.config.ts:8` — `defineConfig({...})` bundler config. Ledger row: F212 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE`, parent F211 (the tool-free pattern row, `COMMON → REUSE`).
- Per-row evidence for the rest of this bundle: F213 build entry-point declaration — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` point at one package root, py's whole package is one build unit); ts `tsdown.config.ts:9` (`entry: ['src/cli.ts', 'src/lib.ts']` lists two explicit entries; ts bundles CLI and library as separate entries). F216 console-script/bin entry declaration — py `pyproject.toml:120` (`plbp = "py_launch_blueprint.cli.main:cli"`, a module:function reference); ts `package.json:18` (`"ts-projects": "dist/cli.js"`, a built file path). F218 packaged-file whitelist mechanism — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` implicitly bounds wheel content); ts `package.json:20`, `package.json:22` (explicit `"files": ["dist"]` array). F219 distribution-name vs. entry-point-name divergence — py `README.md:45` (`uvx --from py-launch-blueprint plbp`, needed since the distribution name differs from the script name); ts `package.json:2`, `package.json:18` (package name `ts-launch-blueprint` differs from bin `ts-projects`, no special install-time flag needed).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-012(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — chose `tsdown` (pinned 0.22.x) with two entries (`src/cli.ts` + `src/lib.ts`), dts, sourcemaps, shebang, as tsup's officially designated successor, preserving agent2linear's bundle-with-dts intent; and D-012(3) — hand-authored the `package.json` packaging surface (root-only exports map, `bin -> ./dist/cli.js`, `files: ["dist"]`) rather than using tsdown's exports auto-generation, treating these fields as the npm analogue of wheel/sdist content lists.

## Out of scope
- Which release binary artifacts (beyond the single `.crate` file `cargo publish` produces) this template ships — crates.io-only vs. `cargo-dist` cross-compiled GitHub Release binaries vs. `cargo-binstall` metadata; R68 (`release-binary-artifacts`) owns F214, this item's SUBSTITUTE parent's sibling row — this item decides the manifest-level build/entry-point declaration, not the distribution-artifact-type question.
- CI-wired install smoke-testing cadence and mechanism; R50 (`install-smoke-test`) owns F221/F222 — this item declares the build targets, it does not decide how they are smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R49
- owns: build-tool-output-shape
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R68 (`release-binary-artifacts`) decides which distributable artifact types beyond the base `.crate` file this template ships (F214); this item's `[[bin]]`/`[lib]` declarations are the input R68's binary-artifact packaging builds on top of, but this item does not decide the artifact-type question itself.
- related (not a registry dependency): R50 (`install-smoke-test`) decides how the built artifact is install-and-run tested; this item only declares what gets built.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how `rs-launch-blueprint`'s `Cargo.toml` declares its build output (binary target name, library target, entry-point path), its packaged-file scope, and whether any distribution-name-vs-binary-name divergence needs documenting — given Cargo is the native build system with no separate backend/bundler crate needed, unlike py's `uv_build` or ts's `tsdown`.
- HIGH: Does a single `Cargo.toml` with `[[bin]]` (CLI) and `[lib]` (library) targets fully replace py's/ts's separate build-backend/bundler tooling, or does a CLI+library+web crate still benefit from a build-orchestration crate (e.g. for cross-compilation, dts-equivalent generation, or web-feature-gated builds)?
- HIGH: What is the idiomatic Rust analogue of ts's explicit `entry: ['src/cli.ts', 'src/lib.ts']` two-entry declaration (F213) — does `[[bin]] name = "..." path = "src/main.rs"` plus `[lib] path = "src/lib.rs"` suffice, or does the optional web-service target (`web-extra-surface`, R69) need its own `[[bin]]` entry or feature-gated conditional compilation?
- MEDIUM: What is the Cargo analogue of py's callable-reference console-script (`plbp = "py_launch_blueprint.cli.main:cli"`, F216) versus ts's built-file-path `bin` field — is the `[[bin]]` `name` field alone sufficient, with no separate "entry point" abstraction needed since Cargo compiles a binary directly?
- MEDIUM: What is the Cargo analogue of py's implicit layout-bounded wheel content and ts's explicit `files: ["dist"]` array (F218) — do `[package] include`/`exclude` fields need to be set explicitly, or is Cargo's default (git-tracked files only) sufficient and should be documented as the deliberate choice?
- LOW: Does this template need a distribution-name-vs-binary-name divergence at all (F219, py's `uvx --from py-launch-blueprint plbp` pattern) — should the crate name and the `[[bin]]` name match to avoid needing any `cargo install --bin`/`cargo binstall`-equivalent name-lookup flag, or is there a reason to diverge?

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
mode: all_deep_research
provider: openai
model: gpt-5.6-sol
operation_id: research-20260909-003258-aed6ba69b51942b3
created_at: 2026-09-09T00:32:58.367422
---

### Prompt

```
System: Conduct comprehensive research with citations and multiple perspectives. Organize findings clearly and highlight key insights.

User: # Deep-research prompt — Build-target declaration (R49, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s Cargo manifest declares its build backend/output, entry points (CLI binary and library), console-script/bin entry, packaged-file whitelist, and any distribution-name-vs-entry-point-name divergence — the Rust analogue of py's `uv_build` PEP 517 backend plus `[project.scripts]`/layout settings and ts's `tsdown` bundler plus explicit `entry`/`bin`/`files` fields. Item kind: `crate`. Value test: if this answer is wrong, `Cargo.toml`'s `[package]`, `[[bin]]`, `[lib]`, and `include`/`exclude` fields, and any build-backend dependency, all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos have a build backend/bundler that produces the distributable package from source (the pattern), but the specific tool is language-bound in both — py's PEP 517 `uv_build` backend and ts's `tsdown` (rolldown) bundler. Evidence: py `pyproject.toml:133` — `build-backend = "uv_build"` (PEP 517); ts `tsdown.config.ts:8` — `defineConfig({...})` bundler config. Ledger row: F212 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE`, parent F211 (the tool-free pattern row, `COMMON → REUSE`).
- Per-row evidence for the rest of this bundle: F213 build entry-point declaration — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` point at one package root, py's whole package is one build unit); ts `tsdown.config.ts:9` (`entry: ['src/cli.ts', 'src/lib.ts']` lists two explicit entries; ts bundles CLI and library as separate entries). F216 console-script/bin entry declaration — py `pyproject.toml:120` (`plbp = "py_launch_blueprint.cli.main:cli"`, a module:function reference); ts `package.json:18` (`"ts-projects": "dist/cli.js"`, a built file path). F218 packaged-file whitelist mechanism — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` implicitly bounds wheel content); ts `package.json:20`, `package.json:22` (explicit `"files": ["dist"]` array). F219 distribution-name vs. entry-point-name divergence — py `README.md:45` (`uvx --from py-launch-blueprint plbp`, needed since the distribution name differs from the script name); ts `package.json:2`, `package.json:18` (package name `ts-launch-blueprint` differs from bin `ts-projects`, no special install-time flag needed).
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-012(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — chose `tsdown` (pinned 0.22.x) with two entries (`src/cli.ts` + `src/lib.ts`), dts, sourcemaps, shebang, as tsup's officially designated successor, preserving agent2linear's bundle-with-dts intent; and D-012(3) — hand-authored the `package.json` packaging surface (root-only exports map, `bin -> ./dist/cli.js`, `files: ["dist"]`) rather than using tsdown's exports auto-generation, treating these fields as the npm analogue of wheel/sdist content lists.

## Out of scope
- Which release binary artifacts (beyond the single `.crate` file `cargo publish` produces) this template ships — crates.io-only vs. `cargo-dist` cross-compiled GitHub Release binaries vs. `cargo-binstall` metadata; R68 (`release-binary-artifacts`) owns F214, this item's SUBSTITUTE parent's sibling row — this item decides the manifest-level build/entry-point declaration, not the distribution-artifact-type question.
- CI-wired install smoke-testing cadence and mechanism; R50 (`install-smoke-test`) owns F221/F222 — this item declares the build targets, it does not decide how they are smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R49
- owns: build-tool-output-shape
- consumes:
- effort: deep
- engines: codex, opus, doxa
- evidence-checks:
- acceptance-after:
- related (not a registry dependency): R68 (`release-binary-artifacts`) decides which distributable artifact types beyond the base `.crate` file this template ships (F214); this item's `[[bin]]`/`[lib]` declarations are the input R68's binary-artifact packaging builds on top of, but this item does not decide the artifact-type question itself.
- related (not a registry dependency): R50 (`install-smoke-test`) decides how the built artifact is install-and-run tested; this item only declares what gets built.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: how `rs-launch-blueprint`'s `Cargo.toml` declares its build output (binary target name, library target, entry-point path), its packaged-file scope, and whether any distribution-name-vs-binary-name divergence needs documenting — given Cargo is the native build system with no separate backend/bundler crate needed, unlike py's `uv_build` or ts's `tsdown`.
- HIGH: Does a single `Cargo.toml` with `[[bin]]` (CLI) and `[lib]` (library) targets fully replace py's/ts's separate build-backend/bundler tooling, or does a CLI+library+web crate still benefit from a build-orchestration crate (e.g. for cross-compilation, dts-equivalent generation, or web-feature-gated builds)?
- HIGH: What is the idiomatic Rust analogue of ts's explicit `entry: ['src/cli.ts', 'src/lib.ts']` two-entry declaration (F213) — does `[[bin]] name = "..." path = "src/main.rs"` plus `[lib] path = "src/lib.rs"` suffice, or does the optional web-service target (`web-extra-surface`, R69) need its own `[[bin]]` entry or feature-gated conditional compilation?
- MEDIUM: What is the Cargo analogue of py's callable-reference console-script (`plbp = "py_launch_blueprint.cli.main:cli"`, F216) versus ts's built-file-path `bin` field — is the `[[bin]]` `name` field alone sufficient, with no separate "entry point" abstraction needed since Cargo compiles a binary directly?
- MEDIUM: What is the Cargo analogue of py's implicit layout-bounded wheel content and ts's explicit `files: ["dist"]` array (F218) — do `[package] include`/`exclude` fields need to be set explicitly, or is Cargo's default (git-tracked files only) sufficient and should be documented as the deliberate choice?
- LOW: Does this template need a distribution-name-vs-binary-name divergence at all (F219, py's `uvx --from py-launch-blueprint plbp` pattern) — should the crate name and the `[[bin]]` name match to avoid needing any `cargo install --bin`/`cargo binstall`-equivalent name-lookup flag, or is there a reason to diverge?

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
### Dominant choice
### Qualified shortlist
Up to five that passed every gate (fewer is a finding): name · role · 90-day downloads · all-time downloads · stars · last release · maintenance state · notable adopters · one-line trade-off.
### Excluded by gate
### Up-and-comers
### Fit for this template
CLI · library · web, separately.
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
```

### Landscape

**Research date:** September 9, 2026. All linked web sources were retrieved on that date. The Python and TypeScript precedents are treated as owner-supplied primary evidence.

**Category decided:** declarative **Cargo target and source-package-surface declaration** for one published Rust package containing a reusable library and one or more executable entry points.

| Ecosystem bin | Candidates found | Finding for R49 |
|---|---|---|
| **Built-in / first-party toolchain** | Cargo `[package]`, `[lib]`, `[[bin]]`, target `required-features`, `[package].include`, workspaces, and the optional `build.rs` extension point | This is the native standard and the only candidate that directly declares all R49-owned behavior. Cargo packages may contain one library and multiple binaries, with explicit names and source paths. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test)) |
| **Established industry patterns/tools** | Project-local `xtask`; `cargo-make`; `cross`; `wasm-pack`; release tools such as `cargo-dist` | These wrap or invoke Cargo for automation, cross-compilation, browser-Wasm packaging, or releases. They do not replace Cargo’s target tables or `.crate` content rules. The `xtask` specification expressly says it is optional and cannot intercept normal `cargo build`; `cross` intentionally exposes Cargo’s CLI through containers; `wasm-pack` generates Wasm/JavaScript/npm output. ([github.com](https://github.com/matklad/cargo-xtask)) |
| **Up-and-comer / experimental** | Cargo `metabuild`, multiple build scripts, `cargo-zigbuild`, evolving Cargo build-layout and workflow work | `metabuild` and multiple build scripts remain nightly-only and fail the stable-Rust gate. `cargo-zigbuild` is relevant to release cross-compilation, as demonstrated by nextest, but not to manifest entry-point declaration. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/unstable.html)) |

**Authority used and why it counts**

- The **Cargo Book, Rust Book, Rust Reference, Edition Guide, and rustc platform-support documentation** are first-party specifications maintained by the Rust project and define the actual manifest, installation, packaging, MSRV, feature, and platform behavior. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack))
- The **Rust Release Team and Security Response Team** establish the current stable version and fixed Cargo security floors. As of September 9, 2026, current stable is Rust 1.98.1; Rust 1.96 fixed the two 2026 Cargo vulnerabilities affecting older versions and third-party registries. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/))
- The **Rust compiler-performance survey** is relevant because it reports Cargo as the usual Rust build system and identifies dependency count and enabled features as major build-cost variables. It supports avoiding an unnecessary orchestration dependency, but it is not treated as a benchmark proving an absolute fastest design. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/))
- The `xtask`, `cross`, `cargo-make`, and `wasm-pack` materials are their maintainers’ documentation. They are authoritative for those tools’ intended scope, but not for Cargo semantics. ([github.com](https://github.com/matklad/cargo-xtask))

**Production-practice survey**

| Project | Standing and relevant evidence | Observed practice |
|---|---|---|
| **rust-analyzer** | Official `rust-lang` IDE frontend; its workspace includes an `xtask` package and currently declares edition 2024 and an MSRV. ([github.com](https://github.com/rust-lang/rust-analyzer/blob/master/Cargo.toml)) | Cargo owns normal targets; `xtask` is reserved for auxiliary operations not expressible through ordinary Cargo commands. |
| **uv** | Modern production package manager from the source-precedent organization. Its `uv` package has a library target, an inferred primary binary, and an extra feature-gated `uvw` binary. ([raw.githubusercontent.com](https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/Cargo.toml)) | A single Cargo package can compose library and executable surfaces; extra executables use `[[bin]]` plus `required-features`, not a bundler entry array. |
| **ripgrep** | Long-lived cross-platform CLI with a multi-crate internal workspace. ([raw.githubusercontent.com](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml)) | Explicit `[[bin]] path = "crates/core/main.rs"` and `name = "rg"`; package `ripgrep` deliberately diverges from command `rg`; packaging uses `exclude`. |
| **fd** | Maintained cross-platform CLI. ([raw.githubusercontent.com](https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml)) | Package `fd-find` explicitly declares binary `fd`, showing Cargo handles distribution/bin divergence without a Python-style `--from` abstraction. |
| **Typst** | Maintained compiler/application workspace with native and web-related behavior. ([raw.githubusercontent.com](https://raw.githubusercontent.com/typst/typst/main/crates/typst-cli/Cargo.toml)) | Separate `typst-cli` package with binary `typst`; an HTTP-server capability is a Cargo feature, not a separate bundler backend. |
| **Helix** | Maintained Rust editor workspace. ([raw.githubusercontent.com](https://raw.githubusercontent.com/helix-editor/helix/master/helix-term/Cargo.toml)) | Explicit package `include` whitelist and explicit `[[bin]] name/path`, directly supporting the recommended package-surface policy. |

The surveyed projects intentionally show multiple legitimate architectures: a single package, a large workspace, command/package-name divergence, feature-gated behavior, explicit `include`, and auxiliary `xtask`. The choice below is based on fit for a launch template, not on copying any one project.

### Principles and implementation

**Shared requirement and agreement level**

The reusable principle behind the Python and TypeScript precedents is:

> A distributable must have a declarative, reviewable mapping from source roots to public entry points, installable command names, and packaged files.

Agreement is required at the **architectural-policy/capability level**, not at the level of sharing a backend library. The implementations may vary because Cargo integrates compilation, target discovery, dependency resolution, source packaging, installation, and publishing in one first-party tool.

The following behaviors must agree across ports:

1. The reusable API root is unambiguous.
2. Every executable entry point has a stable public name and source root.
3. Optional executable surfaces cannot appear accidentally.
4. The published package contains only intentional build/runtime inputs.
5. A clean package build proves the declared files are sufficient.
6. Installation documentation distinguishes the distribution name from executable names where they differ.

The following may vary by ecosystem:

- Whether the builder is a dependency or first-party tool.
- Whether publication contains prebuilt code or buildable source.
- Whether an installed command refers to a callable, generated file, or compiled target.
- Whether type declarations are generated separately.

Cargo’s model remains appropriate because a Cargo package directly contains binary and library crates, and `cargo package` creates a `.crate` source archive and then extracts and builds it from scratch for verification. Unlike the TypeScript `dist` directory, the crates.io artifact is normally source plus manifest metadata, not a prebundled executable. Release binaries beyond that archive remain R68’s concern. ([rust-lang.github.io](https://rust-lang.github.io/book/ch07-01-packages-and-crates.html))

**Architectural alternatives**

| Architecture | Assessment |
|---|---|
| **One Cargo package: library plus CLI binary** | **Chosen baseline.** The Rust Book recommends putting substantive behavior in the library and keeping the binary thin, so the executable consumes the public API like an external client. ([rust-lang.github.io](https://rust-lang.github.io/book/ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html)) |
| **One package plus a feature-gated web binary** | Correct if R69 decides the web service is a separately launched process. Declare a second `[[bin]]` with `required-features = ["web"]`; do not rely only on `#[cfg]` inside an always-visible binary root. Cargo explicitly supports feature-required binary targets. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/cargo/reference/features.html)) |
| **One binary with a `serve` subcommand** | Correct if R69 decides web serving is part of the CLI process. In that case the web module and optional dependencies are feature-gated in the library, but no second `[[bin]]` exists. |
| **Cargo workspace with core, CLI, and web packages** | Qualified runner-up. It provides harder dependency and release boundaries, but adds manifests, package selection, version coordination, and potentially multiple published `.crate` files. Cargo workspaces are intended to manage such package collections. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html?highlight=workspace)) |
| **Custom `build.rs` or build-helper crate** | Rejected for the baseline. Cargo documents build scripts for native compilation, external-library discovery, generated Rust, and platform setup. None is required merely to expose a CLI, library, or HTTP-server binary. Build dependencies also add compilation, licensing, maintenance, and cross-compilation concerns. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **`xtask` or `cargo-make`** | Useful only for later multi-command developer/release workflows. `xtask` explicitly does not integrate with Cargo’s normal lifecycle and says not to use it when `cargo build` and `cargo test` suffice. `cargo-make` is a task runner rather than a target declaration mechanism. ([github.com](https://github.com/matklad/cargo-xtask)) |
| **`cross` or `cargo-zigbuild`** | Useful for R68’s cross-compiled release artifacts, not R49. `cross` intentionally invokes Cargo in Docker/Podman environments and retains Cargo’s target model. ([github.com](https://github.com/cross-rs/cross)) |
| **`wasm-pack` or a browser-web bundler** | Only appropriate if “web” changes from an HTTP service into a browser/Wasm deliverable. `wasm-pack build` creates Wasm, JavaScript wrappers, and npm metadata, which is a different output contract. ([docs.rs](https://docs.rs/wasm-pack/latest/wasm_pack/build/index.html)) |

**Essential implementation decisions**

- Use explicit `[lib]` and `[[bin]]` tables even though Cargo could infer `src/lib.rs` and `src/main.rs`. Explicit paths are the closest analogue to TypeScript’s explicit entry list. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))
- Set `autobins = false`. Since editions after 2018 leave binary auto-discovery enabled even when manual targets exist, this prevents an added `src/bin/*.rs` file from silently becoming a published executable. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))
- Set `build = false` to make “no package-local build script/backend” explicit and prevent an accidentally added root `build.rs` from being auto-detected. This does not block build scripts belonging to dependencies. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html))
- Use an explicit `[package].include` whitelist. Cargo’s default is **not “git-tracked files only”**: it generally includes all package-root files except ignored files and fixed exclusions. An explicit `include` list overrides ignore rules and supplies the auditable whitelist corresponding to the source precedent. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack))
- Match the package and primary binary names: `rs-launch-blueprint`. The library crate identifier is necessarily `rs_launch_blueprint`, because Rust library names use identifier-compatible underscores. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))
- Do not add a `[build-dependencies]` section merely for orchestration, declaration generation, cross-compilation, or web feature selection.

**Observable acceptance criteria**

1. `cargo metadata` reports one library named `rs_launch_blueprint`, one primary binary named `rs-launch-blueprint`, no root `custom-build` target, and—only if selected by R69—one web binary requiring `web`.
2. `cargo build --locked --lib --bin rs-launch-blueprint` succeeds on Rust 1.96 and current stable.
3. `cargo package --list` contains only `src/**`, README/license files, and Cargo-generated mandatory metadata.
4. `cargo package --locked` succeeds, proving the archive builds from a pristine extracted copy.
5. Installing the extracted package produces `bin/rs-launch-blueprint`.
6. A separately executable web target fails when explicitly selected without `--features web` and succeeds with it.
7. No build-backend crate or package-local build script appears in root metadata.

**Evidence gap:** I did not find a maintained project using the exact combination of `build = false`, `autobins = false`, explicit `[lib]`/`[[bin]]`, and a strict `include` whitelist. Each mechanism is independently documented by Cargo and appears in closely related production arrangements, but the complete composition therefore requires the executable acceptance test below.

`BASELINE-REVIEW: F212 — build-backend/bundler substitution — proposed change: record “Cargo first-party toolchain, no registry dependency” as the Rust SUBSTITUTE rather than requiring a build-backend crate — affected item: R49 only; R68 and R50 remain unchanged — evidence: Cargo directly owns target declaration and .crate assembly, while build scripts are extension points for native/code-generation prerequisites rather than ordinary Rust target compilation.`

`BASELINE-REVIEW: F218 — packaged-file bounding — proposed change: use explicit [package].include rather than documenting Cargo defaults as “git-tracked files only” — affected item: R49 package surface — evidence: Cargo’s default is based on ignored/non-ignored files, while include is an explicit override and cargo package --list verifies the result.`

### Dominant choice

**Cargo-native manifest declarations, using Cargo shipped with Rust `>=1.96`; no crates.io build-backend crate and no `[build-dependencies]` entry.**

- Concrete current support floor: `rust-version = "1.96"`.
- Current stable used at the research date: Rust 1.98.1, released September 3, 2026.
- Tested version range to establish in CI: Rust 1.96.x through current stable; the manifest expresses only the lower bound.
- Template package series: `rs-launch-blueprint` initially `0.1.x`.
- Output contract: one `.crate` source package, one library target, one primary CLI target, and an optional feature-required web binary if R69 selects a separate process. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html))

### Qualified shortlist

Fewer than five is a finding: **only the Cargo-native pattern directly satisfies the item.** No third-party crate survived the capability gate.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Open issues / responsiveness | Advisories | Notable adopters | Trade-off |
|---|---|---:|---:|---:|---|---|---|---|---|---|
| **Cargo-native manifest target pattern; Cargo shipped with Rust `>=1.96`** | Build, target, install-entry, and source-package declaration | **inapplicable** — first-party toolchain pattern, not a selected crates.io dependency | **inapplicable** | **inapplicable** — implementation-repository popularity is not a dependency-selection metric | Rust 1.98.1 toolchain, September 3, 2026 | **active** | **inapplicable to a pattern candidate**; current release cadence and Cargo-team documentation establish maintenance instead | No open advisory identified in the supported window; Rust 1.96 fixed the 2026 Cargo issues affecting older versions | rust-analyzer, uv, ripgrep, fd, Typst, Helix | No general task graph or non-Rust bundling; those remain separate concerns |

The prompt permits pattern candidates to use pattern fields where crate figures do not apply. Depending on the crates.io package named `cargo` would be categorically wrong: the selected Cargo is the build tool shipped with the Rust toolchain, not an application dependency. The Rust Reference states that `rustc`, Cargo, and their documentation are released with Rust. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/reference/?source=post_page---------------------------))

**Fitness gates for the dominant choice**

1. **License:** pass. No dependency is added; the template remains `MIT OR Apache-2.0`, matching Rust ecosystem guidance. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/necessities.html))
2. **MSRV:** pass. Current stable minor is 1.98, so stable minus two is 1.96; declare `rust-version = "1.96"` and test it. Rust 2024 also implies resolver 3. ([forge.rust-lang.org](https://forge.rust-lang.org/))
3. **Advisories and unsafe:** pass. The supported floor includes Cargo’s 2026 fixes. No unsafe code or linked runtime code is introduced by the manifest pattern. `build = false` removes only the root package’s automatic build-script hook; dependencies may still contain build scripts or unsafe code and remain subject to normal auditing. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/05/25/cve-2026-5222/))
4. **OS:** pass. Linux host targets and Apple Silicon macOS have first-party host tooling; x86_64 macOS remains supported with host tools at a lower tier. Windows is supported by Cargo but is not required by the owner matrix. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/rustc/platform-support/apple-darwin.html))
5. **Features/runtime:** pass. Cargo itself adds no crate features or async-runtime coupling. R69-owned web dependencies should be optional and reachable only through `web`.
6. **Binary size/compile time:** pass. Target tables and `include` are metadata-only. No backend crate is compiled. A disabled default web feature prevents the web stack from increasing default build time or the CLI/library dependency closure. Cargo’s performance survey supports minimizing dependency and feature count, while advising measurement against the actual workflow. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/))

### Excluded by gate

| Lead | Gate result | Reason |
|---|---|---|
| **Custom `build.rs` or a build-helper crate** | **Excluded by capability/necessity gate** | There is no native library, generated parser/schema, generated Rust module, or platform probe requiring a pre-build program. It would add host compilation and build-time execution without declaring anything Cargo cannot already express. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html)) |
| **`xtask` / `xshell` pattern** | **Excluded as the build backend** | Useful for repository-local automation but cannot intercept ordinary Cargo lifecycle commands. Its own specification recommends omitting it when normal Cargo commands suffice. It can be added later without changing `[lib]`, `[[bin]]`, or `include`. ([github.com](https://github.com/matklad/cargo-xtask)) |
| **`cargo-make`** | **Excluded by role-fit gate** | It is a task runner for multi-step workflows, not the authority for Cargo target names, crate roots, installation names, or `.crate` contents. ([docs.rs](https://docs.rs/crate/cargo-make/latest/source/docs/index.md)) |
| **`cross`** | **Excluded by ownership and role-fit gates** | It wraps Cargo with Docker/Podman environments for cross-compilation and testing. It neither replaces target declarations nor belongs in R49; R68 owns release binary artifacts. Its documented MSRV is 1.85, so MSRV is not the reason for exclusion. ([github.com](https://github.com/cross-rs/cross)) |
| **`wasm-pack`** | **Excluded by output-fit gate** | It emits Wasm, JavaScript wrappers, and npm packaging for browser/JS consumers. An HTTP service compiled to a native executable does not need that output. ([docs.rs](https://docs.rs/wasm-pack/latest/wasm_pack/build/index.html)) |
| **Cargo `metabuild` / multiple build scripts** | **Excluded by stable-Rust gate** | Both remain unstable Cargo features requiring nightly declarations. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/unstable.html)) |
| **`cargo-dist` and binary-installer metadata** | **Excluded by item ownership** | These choose and describe release artifacts beyond the `.crate` package and are explicitly owned by R68. Production manifests such as nextest and Typst demonstrate that this metadata composes on top of ordinary `[[bin]]` targets rather than replacing them. ([raw.githubusercontent.com](https://raw.githubusercontent.com/nextest-rs/nextest/main/cargo-nextest/Cargo.toml)) |

Because these leads fail capability, stable-Rust, output-fit, or ownership gates, popularity cannot promote them into R49’s dependency set. Their crate-download and issue-response figures are therefore not used to rank the decision.

### Up-and-comers

- **Cargo `metabuild` and multiple build scripts** are first-party experiments toward more declarative build-script composition. They remain nightly-only and still address custom pre-build work, not ordinary library/binary target declaration. Re-evaluate only if one stabilizes and R49 later acquires actual code-generation or native-build prerequisites. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/unstable.html))
- **`cargo-zigbuild`** is increasingly visible in portable release construction; nextest uses it for selected Linux release binaries. It is evidence for R68, not a reason to change R49’s manifest architecture. ([github.com](https://github.com/nextest-rs/nextest/blob/main/.github/workflows/release.yml))
- **Cargo build-layout and build-analysis work** may improve diagnostics and resource use, but does not alter `[lib]`, `[[bin]]`, `required-features`, or `include`. ([goals.rust-lang.org](https://goals.rust-lang.org/2025h2/cargo-build-analysis.html))

No up-and-comer presently offers a better stable-Rust realization of this item than Cargo’s built-in target model.

### Fit for this template

**CLI**

- Declare the executable directly:

  ```toml
  [[bin]]
  name = "rs-launch-blueprint"
  path = "src/main.rs"
  ```

- `name` is both the Cargo target/artifact name and installed command name. There is no separate callable-reference or `bin -> built-file` abstraction.
- Keep `src/main.rs` thin: argument parsing and process-exit adaptation should invoke the public library API.
- Set `default-run = "rs-launch-blueprint"` so `cargo run` remains unambiguous if a web binary is later added.
- Set `autobins = false` so only manifest-listed executables exist. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))

**Library**

- Declare the reusable target directly:

  ```toml
  [lib]
  name = "rs_launch_blueprint"
  path = "src/lib.rs"
  ```

- Omit `crate-type`; Cargo’s normal `"lib"` default is correct.
- No `.d.ts` equivalent is needed for Rust consumers: Cargo and rustc compile against Rust library metadata, while rustdoc generates API documentation. Separate declaration generation becomes relevant only for a foreign-language ABI, which is not part of this item. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))

**Web**

- If R69 chooses a **separate server process**, use both an independent target and a feature requirement:

  ```toml
  [features]
  default = []
  web = []

  [[bin]]
  name = "rs-launch-blueprint-web"
  path = "src/bin/web.rs"
  required-features = ["web"]
  ```

  R69 must populate `web` with its optional framework/runtime dependencies.

- If R69 chooses `rs-launch-blueprint serve`, keep one binary and feature-gate the library’s web module and dependencies instead.
- Do not default-enable `web` unless the owner explicitly wants every library and CLI build to compile the async/web stack.
- If the target is separately executable, `required-features` is preferable to only putting `#[cfg(feature = "web")]` around code because Cargo then understands at the target level when the binary is buildable. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/cargo/reference/features.html))

### Recommendation

Use this baseline `Cargo.toml` surface:

```toml
[package]
name = "rs-launch-blueprint"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

description = "A Rust launch blueprint with CLI, library, and optional web surfaces."
readme = "README.md"
repository = "https://example.invalid/owner/rs-launch-blueprint"

default-run = "rs-launch-blueprint"
build = false
autobins = false

include = [
    "/src/**",
    "/README.md",
    "/LICENSE-APACHE",
    "/LICENSE-MIT",
]

[lib]
name = "rs_launch_blueprint"
path = "src/lib.rs"

[[bin]]
name = "rs-launch-blueprint"
path = "src/main.rs"

[dependencies]
```

Cargo always supplies the packaged manifest and a minimized `Cargo.lock`; they do not need to appear in `include`. Any migrations, templates, schemas, certificates, or files referenced by `include_bytes!`/`include_str!` must be added explicitly rather than widening the whitelist. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack))

**Build-backend decision:** do not add `cargo`, `cargo-make`, `xshell`, `cross`, `wasm-pack`, or another orchestration package to `[build-dependencies]`. Cargo itself is the backend.

**Entry-point decision:** `[lib].path` and `[[bin]].path` are the two-entry analogue of TypeScript’s explicit source entries; `[[bin]].name` is the console command declaration.

**Package-file decision:** use `include`, not Cargo’s implicit ignore-based default. Verify it with `cargo package --list`.

**Naming decision:** package and primary command both use `rs-launch-blueprint`. The underscore-only library identifier `rs_launch_blueprint` is an implementation-language requirement, not an install-name divergence.

Cargo can support deliberate package/bin divergence—`fd-find` installs `fd`, while `ripgrep` installs `rg`—without a Python-style `uvx --from` option. `cargo install` takes the package name and installs its eligible binaries; `--bin` is for selecting among multiple binaries, not resolving distribution-name divergence. Nevertheless, R49 has no reason to introduce that extra distinction. ([raw.githubusercontent.com](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml))

### Ranked runner-up

**Cargo workspace split:**

```text
Cargo.toml
crates/
  core/    # package rs-launch-blueprint-core, library
  cli/     # package rs-launch-blueprint, binary
  web/     # package rs-launch-blueprint-web, binary
```

It wins if any of these become true:

- CLI and web need independent versions or publishing.
- The web dependency graph materially harms normal library/CLI build time.
- The web service has a different MSRV or platform policy.
- Separate teams or deployment pipelines need hard ownership boundaries.
- Feature unification within one package becomes undesirable.
- R69 requires a browser/Wasm package rather than an optional native server.

Until then, one package better fits a launch template: one version, one `.crate`, one documentation location, one install command, and less manifest/workspace coordination. Cargo workspaces remain a native migration path requiring no backend replacement. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html?highlight=workspace))

### Tradeoffs

- **Versus a workspace:** the recommendation gives up hard package-level isolation. All surfaces share a version, package metadata, and feature namespace. This is accepted because the template’s purpose is a coherent CLI/library/service starting point rather than three independently released products.
- **Versus inferred Cargo layout:** explicit tables plus `autobins = false` add several manifest lines and require a manifest edit for every new executable. This is accepted because accidental executable discovery would violate the explicit-entry principle.
- **Versus Cargo’s default package selection:** `include` requires maintenance whenever a compile-time or runtime asset is added. This is accepted because the source precedents deliberately bound their distribution surfaces, and Cargo’s default is not a true tracked-file whitelist.
- **Versus `build.rs`:** `build = false` prevents simply dropping in a build script; a future native/code-generation requirement must first change the manifest. This is intentional review friction.
- **Versus `xtask` or `cargo-make`:** there is no single custom command for elaborate generation, release, or deployment flows. This is accepted until a concrete workflow requires one; adding such a tool later does not rewrite target declarations.
- **Versus `cross`/`cargo-zigbuild`:** R49 provides no cross-release environment. That cost is accepted because R68 owns binary artifact production.
- **Versus `wasm-pack`:** no JS wrapper, npm package, or browser-Wasm bundle is produced. That is accepted because the stated web surface is a service, not a browser library.
- **Versus a shorter command such as `rslb`:** matching the package and command names is less terse but avoids installation/documentation divergence. A short alias can be reconsidered only with demonstrated user value.

### Parameters

`owns build-tool-output-shape = Cargo-native single package using Cargo shipped with Rust >=1.96; build = false; autobins = false; [lib] rs_launch_blueprint at src/lib.rs; [[bin]] rs-launch-blueprint at src/main.rs; explicit [package].include whitelist; no build-backend crate`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`

`assumes concrete rust-version = 1.96 as of September 9, 2026, because current stable minor is 1.98`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes web-extra-surface = R69 decides separate web binary versus CLI serve subcommand; if separate, R49’s mechanism is [[bin]] plus required-features = ["web"]`

`CONFLICT: none`

### Migration implications

- **`Cargo.toml`**
  - Add the exact `[package]`, `[lib]`, and primary `[[bin]]` declarations above.
  - Set `edition = "2024"` and `rust-version = "1.96"`.
  - Set `build = false` and `autobins = false`.
  - Add the explicit `include` whitelist.
  - Do not add a build-backend dependency or empty `[build-dependencies]` section.
  - Add a second web `[[bin]]` only if R69 chooses a separate process.

- **`src/lib.rs`**
  - Become the authoritative module tree and reusable API.
  - Hold application/service logic that should be shared by the CLI, tests, and optional web adapter.

- **`src/main.rs`**
  - Remain a thin executable adapter.
  - Parse CLI input, call `rs_launch_blueprint` APIs, render errors/output, and set process status.

- **`src/bin/web.rs`**
  - Create only for R69’s separate-server topology.
  - Require `web` at the manifest target level.

- **`README.md`**
  - Document `cargo install rs-launch-blueprint`.
  - Document invoking `rs-launch-blueprint`.
  - If applicable, separately document `cargo install rs-launch-blueprint --features web` and the `rs-launch-blueprint-web` executable.
  - No `--from`, callable reference, or generated-file path is needed.

- **License files**
  - Ensure root `LICENSE-MIT` and `LICENSE-APACHE` files exist because they are explicitly packaged.

- **Packaged assets**
  - Add explicit `include` entries for any future migrations, templates, schemas, or embedded/static web assets.
  - Keep CI configuration, porting ledgers, local tooling, benchmarks, and large fixtures outside the `.crate` unless they become build inputs.

- **Build scripts/configuration**
  - Delete any placeholder `build.rs`.
  - Remove any proposed tsdown/PEP-517-equivalent configuration.
  - R68 may later add release-tool metadata without changing these target declarations.
  - R50 may later wire the install checks below into CI without changing the decision.

### Validation strategy

**Execution status:** planned, not executed. No repository snapshot or implementation was supplied with the research prompt.

**1. MSRV and current-stable builds**

```bash
rustup toolchain install 1.96.0 --profile minimal
rustup update stable

cargo +1.96.0 check --locked --lib --bin rs-launch-blueprint
cargo +1.96.0 test --locked --lib
cargo +stable check --locked --all-targets
cargo +stable test --locked --all-targets
```

Expected: all commands succeed on `ubuntu-latest` and `macos-latest`. If R69 adds optional web dependencies, also run:

```bash
cargo +1.96.0 check --locked --all-targets --all-features
cargo +stable check --locked --all-targets --all-features
```

**2. Assert the target contract through Cargo metadata**

```bash
python3 - <<'PY'
import json
import pathlib
import subprocess

metadata = json.loads(subprocess.check_output([
    "cargo", "metadata", "--no-deps", "--format-version", "1"
]))

package = next(
    package
    for package in metadata["packages"]
    if package["name"] == "rs-launch-blueprint"
)

targets = package["targets"]

assert not any("custom-build" in target["kind"] for target in targets), targets

lib = next(target for target in targets if target["kind"] == ["lib"])
assert lib["name"] == "rs_launch_blueprint"
assert pathlib.Path(lib["src_path"]).as_posix().endswith("/src/lib.rs")

cli = next(
    target
    for target in targets
    if target["kind"] == ["bin"]
    and target["name"] == "rs-launch-blueprint"
)
assert pathlib.Path(cli["src_path"]).as_posix().endswith("/src/main.rs")
assert cli.get("required-features", []) == []

allowed_names = {"rs_launch_blueprint", "rs-launch-blueprint"}

# Add rs-launch-blueprint-web here only if R69 selects a separate server.
unexpected = [
    target["name"]
    for target in targets
    if any(kind in {"lib", "bin", "custom-build"} for kind in target["kind"])
    and target["name"] not in allowed_names
]
assert not unexpected, unexpected
PY
```

Expected: exact library/CLI targets and no package-local build script.

**3. Verify the packaged-file whitelist**

```bash
cargo package --locked --allow-dirty --list | tee /tmp/rs-launch-blueprint.files

grep -qx 'src/lib.rs' /tmp/rs-launch-blueprint.files
grep -qx 'src/main.rs' /tmp/rs-launch-blueprint.files
grep -qx 'README.md' /tmp/rs-launch-blueprint.files
grep -qx 'LICENSE-MIT' /tmp/rs-launch-blueprint.files
grep -qx 'LICENSE-APACHE' /tmp/rs-launch-blueprint.files

if grep -E '(^|/)(target|\.github|docs/port|benches|large-fixtures)(/|$)' \
    /tmp/rs-launch-blueprint.files
then
    echo "unexpected packaged file" >&2
    exit 1
fi
```

Expected: source, README, licenses, and Cargo-generated package metadata only. Cargo recommends `cargo package --list` for this verification, and `cargo package` subsequently extracts and rebuilds the archive. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack))

**4. Build the pristine `.crate` package**

```bash
cargo package --locked --allow-dirty

test -f target/package/rs-launch-blueprint-0.1.0.crate
test -d target/package/rs-launch-blueprint-0.1.0
```

Expected: success without `--no-verify`. The resulting `.crate` must remain below crates.io’s current 10 MB archive limit. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/publishing.html))

**5. Prove the installed command name**

```bash
install_root="$(mktemp -d)"

cargo install \
    --locked \
    --root "$install_root" \
    --path target/package/rs-launch-blueprint-0.1.0

test -x "$install_root/bin/rs-launch-blueprint"
"$install_root/bin/rs-launch-blueprint" --help
```

Expected: one installed executable named `rs-launch-blueprint` with successful `--help` output. This is an R49 acceptance check; R50 decides its eventual CI cadence and mechanism.

**6. Separate-web-target check, only if selected by R69**

```bash
if cargo build --locked --bin rs-launch-blueprint-web \
    > /tmp/web-without-feature.log 2>&1
then
    echo "web target unexpectedly built without feature" >&2
    exit 1
fi

grep -q 'required features.*web' /tmp/web-without-feature.log

cargo build \
    --locked \
    --features web \
    --bin rs-launch-blueprint-web
```

Expected: explicit selection without the feature is rejected; feature-enabled build succeeds. A normal default build skips the web target and its optional dependency closure.

**7. Representative build-cost measurement**

No runtime latency or throughput difference is expected from target-table syntax itself, so runtime benchmarking is inapplicable to R49. Measure build latency and resource cost instead:

- **Workloads:** clean release build, no-op rebuild, and all-features release build if web exists.
- **Configuration:** Rust 1.96.0 and stable 1.98.1; locked dependencies; GitHub `ubuntu-latest` and `macos-latest`; restored registry/dependency cache; three measured runs after one warm-up.
- **Instrumentation:** `cargo build --release --timings`; `/usr/bin/time -v` on Ubuntu; `/usr/bin/time -l` on macOS; artifact and `.crate` byte counts.
- **Recorded metrics:** median wall-clock build latency, maximum RSS, `target` growth, CLI bytes, optional web-binary bytes, and `.crate` bytes.
- **Throughput:** inapplicable—this decision builds one package rather than processing requests or records.
- **Acceptance:** no root `custom-build` unit; default build does not compile web-only dependencies; archive remains under the registry limit; any future orchestration tool must show a measured benefit against this baseline.

The Cargo build-performance guidance specifically recommends measuring the workflows actually important to the project rather than assuming a universally faster configuration. ([dev-doc.rust-lang.org](https://dev-doc.rust-lang.org/stable/cargo/guide/build-performance.html))

### Confidence & re-verify trigger

**Confidence: high (0.93)** for Cargo target, installation, packaging, feature, and naming semantics; **medium-high (0.84)** for making `build = false` and `include` mandatory template policy because the exact combined arrangement lacks a single maintained reference implementation.

Re-verify when any of the following occurs:

- The current stable Rust minor advances so that “stable minus two” is later than 1.96; raise `rust-version` only in a minor release as required.
- R69 selects a browser/Wasm application, independent web deployment, or a different web MSRV/platform policy.
- The project introduces generated Rust, native libraries, schema compilation, or platform probing that may justify `build.rs`.
- Runtime assets, migrations, templates, or embedded files are introduced and must be added to `include`.
- The CLI and web service need independent package versions or release cadences, making the workspace runner-up preferable.
- R68 selects a cross-release mechanism whose metadata requires target-specific additions.
- Stable Cargo gains a first-party workflow/metabuild facility that directly replaces a concrete project need.
- Cargo changes package-content or target-auto-discovery semantics.
- The `rs-launch-blueprint` crates.io name is unavailable at publication time; if the distribution name changes, preserve the desired binary name explicitly and document the install/run pair.

### Sources

All retrieved September 9, 2026.

- Cargo Book — Cargo Targets: https://doc.rust-lang.org/cargo/reference/cargo-targets.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test))
- Cargo Book — Manifest Format, including `include`, `exclude`, and `build`: https://doc.rust-lang.org/cargo/reference/manifest.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack))
- Cargo Book — `cargo package`: https://doc.rust-lang.org/cargo/commands/cargo-package.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-package.html))
- Cargo Book — Publishing on crates.io: https://doc.rust-lang.org/cargo/reference/publishing.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/publishing.html))
- Cargo Book — `cargo install`: https://doc.rust-lang.org/cargo/commands/cargo-install.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-install.html))
- Cargo Book — Rust version: https://doc.rust-lang.org/stable/cargo/reference/rust-version.html ([doc.rust-lang.org](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html))
- Cargo Book — Features and `required-features`: https://doc.rust-lang.org/stable/cargo/reference/features.html ([doc.rust-lang.org](https://doc.rust-lang.org/stable/cargo/reference/features.html))
- Cargo Book — Workspaces: https://doc.rust-lang.org/cargo/reference/workspaces.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html?highlight=workspace))
- Cargo Book — Build scripts: https://doc.rust-lang.org/cargo/reference/build-scripts.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-scripts.html))
- Cargo Book — Unstable features: https://doc.rust-lang.org/cargo/reference/unstable.html ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/unstable.html))
- Cargo Book — Optimizing build performance: https://dev-doc.rust-lang.org/stable/cargo/guide/build-performance.html ([dev-doc.rust-lang.org](https://dev-doc.rust-lang.org/stable/cargo/guide/build-performance.html))
- Rust Book — Packages and crates: https://rust-lang.github.io/book/ch07-01-packages-and-crates.html ([rust-lang.github.io](https://rust-lang.github.io/book/ch07-01-packages-and-crates.html))
- Rust Book — Binary-plus-library best practice: https://rust-lang.github.io/book/ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html ([rust-lang.github.io](https://rust-lang.github.io/book/ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html))
- Rust Edition Guide — Rust-version-aware resolver: https://doc.rust-lang.org/stable/edition-guide/rust-2024/cargo-resolver.html ([doc.rust-lang.org](https://doc.rust-lang.org/stable/edition-guide/rust-2024/cargo-resolver.html))
- Rust Forge — current release versions: https://forge.rust-lang.org/ ([forge.rust-lang.org](https://forge.rust-lang.org/))
- Rust Release Team — Rust 1.98.1: https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/ ([blog.rust-lang.org](https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/))
- Rust Security Response Team — CVE-2026-5222: https://blog.rust-lang.org/2026/05/25/cve-2026-5222/ ([blog.rust-lang.org](https://blog.rust-lang.org/2026/05/25/cve-2026-5222/))
- Rust Security Response Team — CVE-2026-5223: https://blog.rust-lang.org/2026/05/25/cve-2026-5223/ ([blog.rust-lang.org](https://blog.rust-lang.org/2026/05/25/cve-2026-5223/))
- Rust Release Team — Rust 1.96 fixes: https://blog.rust-lang.org/2026/05/28/Rust-1.96.0/ ([blog.rust-lang.org](https://blog.rust-lang.org/2026/05/28/Rust-1.96.0/))
- RustSec — Cargo advisories: https://rustsec.org/packages/cargo.html ([rustsec.org](https://rustsec.org/packages/cargo.html))
- rustc platform support — Apple Darwin: https://doc.rust-lang.org/nightly/rustc/platform-support/apple-darwin.html ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/rustc/platform-support/apple-darwin.html))
- rustc platform support index: https://doc.rust-lang.org/nightly/rustc/platform-support.html ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/rustc/platform-support.html?highlight=sparc64-unknown-linux))
- Rust compiler-performance survey 2025 results: https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ ([blog.rust-lang.org](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/))
- `xtask` pattern: https://github.com/matklad/cargo-xtask ([github.com](https://github.com/matklad/cargo-xtask))
- `cargo-make` documentation: https://docs.rs/crate/cargo-make/latest/source/docs/index.md ([docs.rs](https://docs.rs/crate/cargo-make/latest/source/docs/index.md))
- `cross` documentation/repository: https://github.com/cross-rs/cross ([github.com](https://github.com/cross-rs/cross))
- `wasm-pack build`: https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html ([wasm-bindgen.github.io](https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html))
- rust-analyzer root manifest: https://github.com/rust-lang/rust-analyzer/blob/master/Cargo.toml ([github.com](https://github.com/rust-lang/rust-analyzer/blob/master/Cargo.toml))
- uv package manifest: https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/Cargo.toml ([raw.githubusercontent.com](https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/Cargo.toml))
- ripgrep manifest: https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml ([raw.githubusercontent.com](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml))
- fd manifest: https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml ([raw.githubusercontent.com](https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml))
- Typst CLI manifest: https://raw.githubusercontent.com/typst/typst/main/crates/typst-cli/Cargo.toml ([raw.githubusercontent.com](https://raw.githubusercontent.com/typst/typst/main/crates/typst-cli/Cargo.toml))
- Helix terminal manifest: https://raw.githubusercontent.com/helix-editor/helix/master/helix-term/Cargo.toml ([raw.githubusercontent.com](https://raw.githubusercontent.com/helix-editor/helix/master/helix-term/Cargo.toml))
- nextest release workflow: https://github.com/nextest-rs/nextest/blob/main/.github/workflows/release.yml ([github.com](https://github.com/nextest-rs/nextest/blob/main/.github/workflows/release.yml))

## Sources

- [https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test](https://doc.rust-lang.org/cargo/reference/cargo-targets.html?highlight=test)
- [https://github.com/matklad/cargo-xtask](https://github.com/matklad/cargo-xtask)
- [https://doc.rust-lang.org/cargo/reference/unstable.html](https://doc.rust-lang.org/cargo/reference/unstable.html)
- [https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack](https://doc.rust-lang.org/cargo/reference/manifest.html?highlight=pack)
- [https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/](https://blog.rust-lang.org/2026/09/03/Rust-1.98.1/)
- [https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/](https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/)
- [https://github.com/rust-lang/rust-analyzer/blob/master/Cargo.toml](https://github.com/rust-lang/rust-analyzer/blob/master/Cargo.toml)
- [https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/Cargo.toml](https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/Cargo.toml)
- [https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/Cargo.toml)
- [https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml](https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml)
- [https://raw.githubusercontent.com/typst/typst/main/crates/typst-cli/Cargo.toml](https://raw.githubusercontent.com/typst/typst/main/crates/typst-cli/Cargo.toml)
- [https://raw.githubusercontent.com/helix-editor/helix/master/helix-term/Cargo.toml](https://raw.githubusercontent.com/helix-editor/helix/master/helix-term/Cargo.toml)
- [https://rust-lang.github.io/book/ch07-01-packages-and-crates.html](https://rust-lang.github.io/book/ch07-01-packages-and-crates.html)
- [https://rust-lang.github.io/book/ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html](https://rust-lang.github.io/book/ch07-03-paths-for-referring-to-an-item-in-the-module-tree.html)
- [https://doc.rust-lang.org/stable/cargo/reference/features.html](https://doc.rust-lang.org/stable/cargo/reference/features.html)
- [https://doc.rust-lang.org/cargo/reference/workspaces.html?highlight=workspace](https://doc.rust-lang.org/cargo/reference/workspaces.html?highlight=workspace)
- [https://doc.rust-lang.org/cargo/reference/build-scripts.html](https://doc.rust-lang.org/cargo/reference/build-scripts.html)
- [https://github.com/cross-rs/cross](https://github.com/cross-rs/cross)
- [https://docs.rs/wasm-pack/latest/wasm_pack/build/index.html](https://docs.rs/wasm-pack/latest/wasm_pack/build/index.html)
- [https://doc.rust-lang.org/stable/cargo/reference/rust-version.html](https://doc.rust-lang.org/stable/cargo/reference/rust-version.html)
- [https://doc.rust-lang.org/stable/reference/?source=post_page---------------------------](https://doc.rust-lang.org/stable/reference/?source=post_page---------------------------)
- [https://rust-lang.github.io/api-guidelines/necessities.html](https://rust-lang.github.io/api-guidelines/necessities.html)
- [https://forge.rust-lang.org/](https://forge.rust-lang.org/)
- [https://blog.rust-lang.org/2026/05/25/cve-2026-5222/](https://blog.rust-lang.org/2026/05/25/cve-2026-5222/)
- [https://doc.rust-lang.org/nightly/rustc/platform-support/apple-darwin.html](https://doc.rust-lang.org/nightly/rustc/platform-support/apple-darwin.html)
- [https://docs.rs/crate/cargo-make/latest/source/docs/index.md](https://docs.rs/crate/cargo-make/latest/source/docs/index.md)
- [https://raw.githubusercontent.com/nextest-rs/nextest/main/cargo-nextest/Cargo.toml](https://raw.githubusercontent.com/nextest-rs/nextest/main/cargo-nextest/Cargo.toml)
- [https://github.com/nextest-rs/nextest/blob/main/.github/workflows/release.yml](https://github.com/nextest-rs/nextest/blob/main/.github/workflows/release.yml)
- [https://goals.rust-lang.org/2025h2/cargo-build-analysis.html](https://goals.rust-lang.org/2025h2/cargo-build-analysis.html)
- [https://doc.rust-lang.org/cargo/reference/publishing.html](https://doc.rust-lang.org/cargo/reference/publishing.html)
- [https://dev-doc.rust-lang.org/stable/cargo/guide/build-performance.html](https://dev-doc.rust-lang.org/stable/cargo/guide/build-performance.html)
- [https://doc.rust-lang.org/cargo/commands/cargo-package.html](https://doc.rust-lang.org/cargo/commands/cargo-package.html)
- [https://doc.rust-lang.org/cargo/commands/cargo-install.html](https://doc.rust-lang.org/cargo/commands/cargo-install.html)
- [https://doc.rust-lang.org/stable/edition-guide/rust-2024/cargo-resolver.html](https://doc.rust-lang.org/stable/edition-guide/rust-2024/cargo-resolver.html)
- [https://blog.rust-lang.org/2026/05/25/cve-2026-5223/](https://blog.rust-lang.org/2026/05/25/cve-2026-5223/)
- [https://blog.rust-lang.org/2026/05/28/Rust-1.96.0/](https://blog.rust-lang.org/2026/05/28/Rust-1.96.0/)
- [https://rustsec.org/packages/cargo.html](https://rustsec.org/packages/cargo.html)
- [https://doc.rust-lang.org/nightly/rustc/platform-support.html?highlight=sparc64-unknown-linux](https://doc.rust-lang.org/nightly/rustc/platform-support.html?highlight=sparc64-unknown-linux)
- [https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html](https://wasm-bindgen.github.io/wasm-pack/book/commands/build.html)