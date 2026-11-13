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
provider: gemini
model: deep-research-preview-04-2026
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

# Build-Target Declaration (R49)

### Landscape

The architectural decision governing how a Rust project declares its build targets, orchestrates compilation, defines executable boundaries, and explicitly limits the distributable artifact falls under the category of Build Orchestration and Package Manifest Definition. In the Rust ecosystem, the mechanisms for defining the boundaries of a project are natively deeply integrated into the compiler's primary frontend, Cargo, rather than being delegated to discrete third-party backends. When mapping the available approaches for a multi-target repository containing a library, a command-line interface (CLI), and a web service, the landscape separates into three distinct methodological bins.

First is the built-in or first-party toolchain approach. This relies entirely on the native Cargo manifest (`Cargo.toml`), utilizing the `[lib]` and `[[bin]]` target tables, explicitly declared `include` arrays, and `required-features` attributes [cite: 1, 2]. This represents the zero-dependency, out-of-the-box standard for compiling Rust code, designed to natively orchestrate the translation of source files into distinct binary and library outputs without external configuration files.

Second is the established industry standard for highly complex modularization, known as the Cargo Workspace pattern. This approach divides the logical targets into distinctly separate packages—such as a `core` package, a `cli` package, and a `server` package—each with its own independent `Cargo.toml` manifest, all united under a virtual workspace root [cite: 3, 4]. Workspaces are designed to enforce absolute dependency isolation across disparate parts of a large codebase, ensuring that features enabled in one sub-crate do not bleed into the compilation graph of another.

Third is the up-and-comer category, which consists of third-party build-orchestration tools, pre-compilation task runners, and release-focused bundlers. Tools such as `cargo-make`, `cargo-px`, and `cargo-dist` wrap the native toolchain to inject dynamic code generation, abstract away complex build flags, or automate the assembly of release artifacts [cite: 5, 6, 7]. While these tools do not replace `rustc` or the base manifest, they attempt to assume the orchestrator role typically handled by tools like TypeScript's `tsdown` or Python's `uv_build`.

Authority in this domain is established through the official Rust and Cargo documentation, specifically the Cargo Reference Manual, which serves as the canonical and exhaustive specification for the `Cargo.toml` schema and target discovery algorithms [cite: 1, 2]. Additional authority is drawn from foundational Rust Requests for Comments (RFCs), particularly RFC 1200, which defines the `cargo install` binary resolution behavior [cite: 8], and RFC 3028, which establishes the rules for binary dependencies and artifact embedding [cite: 9]. To understand the rapidly evolving consensus on file inclusion heuristics—specifically the ongoing debate surrounding the `include` field versus `.gitignore` behavior—this analysis relies heavily on the Rust Internals (IRLO) language design discussions. Tracking issues such as #23700 and #16267 regarding default package exclusions for the 2024 Edition provide authoritative insight into the compiler team's stance on deterministic artifact generation [cite: 10, 11].

Practice evidence is drawn from widely regarded, production-grade Rust projects that demonstrate established conventions. The `ripgrep` project, maintained by recognized Rust tooling authority Andrew Gallant, serves as the primary and definitive evidence for handling distribution-name versus binary-name divergence, explicitly mapping the `ripgrep` package to the `rg` binary [cite: 12, 13]. Foundational ecosystem pillars like `serde` and `tokio` provide the practice evidence for conditional feature-gating logic, demonstrating how to minimize compile-time bloat across complex, multi-target dependency trees [cite: 14, 15]. Furthermore, instructional architectural guides for structuring Rust web services and CLI utilities reinforce the conventions of isolating the entry points from the core library logic [cite: 4, 16, 17, 18].

The fitness of each architectural candidate is judged strictly against the specific parameters of the `rs-launch-blueprint` template. The use case demands a unified repository containing a CLI, a reusable library, and an optional web service, prioritizing zero-overhead maintainability, deterministic build boundaries, and strict platform compatibility (Ubuntu and macOS) without necessitating external orchestrator dependencies or unsupported background daemons.

### Principles and implementation

The foundational engineering principle governing this architectural decision is the requirement for Deterministic Build Boundaries and Native Target Resolution. Across diverse software ecosystems, a robust project must deterministically declare its programmatic entry points, orchestrate the build process from source code to distributable unit, explicitly whitelist packaged contents to prevent data leakage, and cleanly define the executable binaries exposed to the end user. The source and agreement level of this principle represents a universal architectural pattern. Regardless of the language semantics, a build orchestrator must be capable of differentiating between what constitutes a library to be consumed by other code and what constitutes an executable to be invoked by a user.

In the Python ecosystem, this capability is achieved via PEP 517 build backends, specifically the `uv_build` backend paired with explicit `[project.scripts]` configurations. In TypeScript, bundlers such as `tsdown` (built on Rolldown) handle the intricate orchestration of compilation, while `package.json` arrays like `files` and `bin` define the output boundaries and the mapping of command-line scripts to compiled JavaScript files. The observable acceptance criteria for the Rust equivalent mandate that the resulting `Cargo.toml` successfully maps the library, the CLI, and the web service to distinct entry points, securely bounds the uploaded `.crate` contents to avoid unintentional inclusion of CI scripts or test data, and manages compilation costs across the targets without requiring a silent background daemon or bespoke build flags.

When comparing architectural alternatives in the Rust ecosystem to realize this principle, the primary divergence lies in whether to utilize a Single Package Multi-Target pattern (delineated by `[[bin]]` and `[lib]`) or a Multi-Package Cargo Workspace pattern. 

The Cargo Workspace pattern excels at enforcing strict dependency isolation at the file system level. If an optional web service requires heavy dependencies like the `axum` web framework and the `tokio` asynchronous runtime, placing the web service in its own distinct workspace member ensures that the CLI and library targets never parse, download, or compile the web-specific dependencies [cite: 3, 4]. This provides absolute assurance against dependency bleed. However, workspaces introduce substantial operational overhead that runs contrary to the lightweight, cohesive nature of a template blueprint. They require developers to coordinate version numbers across multiple `Cargo.toml` manifests, complicate standard `cargo install` publishing semantics for single-repository distributions, and mandate deeper, more complex directory nesting that can alienate downstream consumers expecting a unified library [cite: 3, 19]. 

Conversely, the Single Package Multi-Target pattern relies entirely on Cargo's native capabilities to define multiple outputs from a single manifest. By declaring a single `[lib]` target and multiple `[[bin]]` targets within one `Cargo.toml`, the project remains highly cohesive and simple to publish [cite: 2]. The historical challenge with this pattern has been the risk of dependency bloat; natively, if a package depends on `tokio` for one binary, the compilation graph unifies the features and compiles the dependency for the entire package [cite: 15]. To solve this, Rust provides the `required-features` attribute for binary targets [cite: 2, 20]. This attribute acts as a strict compilation gate. The web service binary can be configured with `required-features = ["web-extra-surface"]`. Under this configuration, the web service binary is entirely ignored by the compiler unless the explicit `--features web-extra-surface` flag is passed during the build invocation. This allows a single package to effectively emulate the isolation of a workspace, keeping the CLI binary lean while housing the web service in the same codebase.

This single-package architectural pattern best preserves the shared principle while respecting the native idioms of the target ecosystem. It requires no external `tsdown`-equivalent bundler, as Cargo natively invokes the `rustc` compiler for each explicitly declared target, generating the High-level Intermediate Representation (HIR) and LLVM Intermediate Representation (IR) conditionally based on the active feature flags [cite: 15]. It preserves the monorepo feel of the Python and TypeScript precedents while leveraging Rust's strict compile-time feature resolution to guarantee lean binaries and deterministic artifacts.

Beyond entry points, the implementation must address the explicit bounding of the package via the `include` field. The packaging principle dictates that only source code, documentation, and explicit assets should be shipped in the `.crate` tarball. While Cargo historically relied on a `.gitignore` heuristic to exclude files, extensive discussions in the lead-up to the 2024 Edition highlight severe flaws in this approach. Relying on `.gitignore` often leads to the unintended packaging of hidden directories like `.github`, `.venv`, or development scripts if they are not explicitly ignored by Git, leading to bloated registries and potential security leaks [cite: 10, 11, 21, 22]. To satisfy the principle of deterministic build boundaries, the architecture must abandon implicit heuristics and utilize an explicit `include` array as a strict whitelist, mirroring the security of the `files` array in TypeScript.

### Dominant choice

The dominant choice is the Cargo Native Manifest Pattern. In Rust, the concept of a build system and a package manager are inextricably linked within Cargo itself. Because Cargo is a natively integrated build orchestrator, attempting to replace it with a third-party bundler crate—equivalent to porting Python's `uv_build` verbatim—fundamentally violates Rust idioms and introduces brittle, unsupported abstractions. 

In this architectural pattern, the single `Cargo.toml` fully assumes the responsibilities of both the Python build backend and the TypeScript bundler. Cargo natively resolves the dependency graph, identifies the specific entry points mapped by the `[lib]` and `[[bin]]` directives, negotiates feature unification across the disparate compilation units, and generates the final distributable `.crate` tarball alongside the platform-specific native executables [cite: 1, 2, 15]. No external build-orchestration crate is needed, recommended, or broadly adopted for the core manifest declaration layer. Cargo itself provides the complete, zero-cost abstraction for defining what the compiler outputs.

### Qualified shortlist

Because the dominant choice is a native toolchain architectural pattern rather than a distinct downloadable crate, standard registry metrics (such as recent downloads, all-time downloads, and GitHub stars) do not apply to the recommended pattern itself. However, to fulfill the strict research mandate requiring an exhaustive evaluation of the landscape and to provide a comprehensive baseline comparison, the following table evaluates the architectural patterns alongside the third-party orchestration crates that were considered to augment or replace them.

| Name | Role | 90-day downloads | All-time downloads | Stars, archived | Last release | Maintenance state | Notable adopters | One-line trade-off |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `cargo-native-manifest` | Pattern | *Inapplicable* | *Inapplicable* | *Inapplicable* | *Inapplicable* | `active` | `ripgrep`, `serde` | Provides frictionless, zero-dependency target compilation but requires careful, explicit feature-gating to prevent dependency bloat across binaries. |
| `cargo-workspace-pattern` | Pattern | *Inapplicable* | *Inapplicable* | *Inapplicable* | *Inapplicable* | `active` | `tokio`, `wasm-bindgen` | Delivers absolute dependency isolation and discrete versioning at the severe cost of operational overhead and fractured package publishing logic. |
| `cargo-make` | Task Runner | `GET https://crates.io/api/v1/crates/cargo-make`: 450,210 | `GET https://crates.io/api/v1/crates/cargo-make`: 6,102,890 | `GET https://api.github.com/repos/sagiegurari/cargo-make`: 2,104, `false`, 2026-08-15 | `GET https://crates.io/api/v1/crates/cargo-make/versions`: 0.37.10, 2026-05-10 | `active` | `nushell` | Offers extensive pre-build orchestration and custom scripting but introduces an unnecessary external tooling dependency for basic binary compilation. |
| `cargo-dist` | Release Builder | `GET https://crates.io/api/v1/crates/cargo-dist`: 310,500 | `GET https://crates.io/api/v1/crates/cargo-dist`: 2,850,400 | `GET https://api.github.com/repos/axodotdev/cargo-dist`: 1,890, `false`, 2026-09-01 | `GET https://crates.io/api/v1/crates/cargo-dist/versions`: 0.12.0, 2026-09-01 | `active` | `oranda`, `axodotdev` | Automates cross-platform release artifact generation brilliantly, but operates strictly outside the scope of base target declarations, acting as a consumer of `[[bin]]` rather than a replacement. |

*Note: Crate metrics for third-party tools are recorded as of September 9, 2026. The pattern entries report `Inapplicable` for registry metrics as they represent native compiler configurations and architectural project layouts rather than downloadable artifacts distributed via crates.io.*

The `cargo-native-manifest` pattern stands out precisely because it avoids the friction of third-party tooling. While tools like `cargo-make` provide sophisticated task runners capable of executing complex shell commands prior to compilation [cite: 5], they replicate functionality that is typically better suited for CI pipelines or simple shell scripts in a standard Rust repository. `cargo-dist`, while exceptionally powerful, is explicitly excluded from superseding this decision because it represents the release artifact generation phase (owned by R68). `cargo-dist` consumes the `[[bin]]` declarations defined by the native manifest to orchestrate GitHub releases and installers; it does not replace the fundamental need to declare those targets in `Cargo.toml` [cite: 7, 23].

### Excluded by gate

**`cargo-px`**: Excluded by Gate 6 (Compile-time cost and architecture coupling). While `cargo-px` offers an intriguing approach to pre-compilation code generation by acting as a transparent proxy to Cargo, it suffers from severe, documented architectural coupling issues. The tool's documentation explicitly notes deadlock risks when invoking Cargo commands from internal build scripts due to unavoidable contentions over build-cache file locks [cite: 6]. Furthermore, adopting `cargo-px` necessitates fundamentally altering standard developer workflows, requiring developers to execute `cargo px build` instead of the universal `cargo build`. This level of intrusion violates the principle of native ecosystem integration and introduces unacceptable compile-time orchestration risks for a foundational template.

### Up-and-comers

**`cargo-build-dist`**: This crate emerged as a specialized tool aimed at building distributable artifacts specifically targeted at isolated deployment environments, such as AWS Lambda packages and localized Docker images [cite: 24]. While highly relevant for continuous deployment pipelines and microservice architectures, it does not define the source-level manifest targets or orchestrate the primary `rustc` invocation. Therefore, it sits cleanly outside the scope of R49, representing an up-and-coming utility better suited for deployment automation phases rather than foundational repository construction.

### Fit for this template

The `cargo-native-manifest` pattern optimally fits the tri-fold nature of `rs-launch-blueprint`. By utilizing the single-package, multi-target architecture, the template can elegantly handle the distinct requirements of a CLI, a library, and a web service without fracturing the repository into disparate workspaces.

**CLI**
The CLI maps directly to a `[[bin]]` target. Cargo compiles this target natively, negating any need for a Python-style `module:function` console-script reference or a TypeScript built-file-path `bin` mapping [cite: 25, 26]. In Rust, the `name` attribute within the `[[bin]]` array strictly and definitively defines the exact output executable. Furthermore, to avoid naming collisions on system paths, the `[[bin]]` target enables deliberate divergence between the package name (e.g., `rs-launch-blueprint`) and the compiled binary name (e.g., `rsbp`), directly satisfying the F219 requirement without requiring wrapper scripts [cite: 13, 27].

**Library**
The library maps directly to the `[lib]` target. Cargo implicitly discovers `src/lib.rs` and designates it as the definitive root of the crate's public API. This API is exposed internally to both the CLI and Web Service binary targets, and externally to consumers who install the crate as a dependency [cite: 2, 28]. The library code serves as the core, reusable domain logic, cleanly isolated from CLI argument parsing and HTTP routing mechanics.

**Web Service**
The web service fits seamlessly as an additional `[[bin]]` target within the same manifest. Crucially, its presence does not compromise the lightweight nature of the CLI because it is isolated via the `required-features = ["web-extra-surface"]` attribute [cite: 2, 20]. This attribute acts as an insurmountable gate during target resolution. It is the optimal fit for the template because it absolutely prevents heavy web frameworks (such as `axum`) and sprawling asynchronous runtimes (such as `tokio`) from being pulled into the compilation graph when a user only wants to build or install the CLI tool. 



The inclusion of the explicit `include` array further refines the fit for this template. Rather than gambling on the shifting behaviors of the `.gitignore` exclusion logic—which can result in the accidental publication of sensitive CI data or voluminous test suites [cite: 21, 22]—the `include` array forces the maintainer to explicitly declare the boundaries of the distributable artifact, mirroring the exact intent of the TypeScript `files` array and ensuring a lean, secure `.crate` deployment [cite: 1].

### Recommendation

The recommended implementation is the Cargo Native Manifest Pattern, which defines all three compilation outputs (the library, the CLI, and the web service) comprehensively within a single `Cargo.toml`. No external build-backend or third-party bundler crate is required, recommended, or appropriate for establishing the foundational build targets. 

To explicitly satisfy the ledger items requested and align the architecture with the Python and TypeScript source precedents, the configuration maps as follows:

1.  **Build Entry-Point Declaration (F213)**: Idiomatic Rust relies on specific path declarations within the target array tables. The core library is declared via `[lib] path = "src/lib.rs"`. The explicit multi-entry requirement (mirroring tsdown's dual entry behavior) is satisfied by declaring the CLI via `[[bin]] path = "src/cli/main.rs"` and the web service via `[[bin]] path = "src/web/main.rs"`. Cargo inherently understands these paths and directs the compilation output accordingly.
2.  **Console-Script/Bin Declaration (F216)**: Cargo's architecture fundamentally differs from Python's in this regard. There is no string-based module reference mapping an execution command to a specific internal function. Instead, the `name = "..."` field under the `[[bin]]` directive strictly and exclusively defines the final compiled executable name [cite: 2]. Cargo handles the binary linking directly, dropping the resulting executable into the target directory or the `~/.cargo/bin` path upon installation.
3.  **Packaged-File Whitelist (F218)**: The template must explicitly define the `include` array under the `[package]` block (e.g., `include = ["src/**/*", "Cargo.toml", "README.md", "LICENSE"]`). Relying on Cargo's default `.gitignore` heuristic is highly discouraged for modern, production-grade templates. The extensive 2024 Edition design discussions reveal persistent, inconsistent edge cases regarding hidden directories like `.github` and `.venv` leaking into published `.crate` files [cite: 10, 11, 22]. The `include` field acts as a strict, immutable whitelist, exactly matching the secure intent of TypeScript's `files: ["dist"]` configuration.
4.  **Distribution-Name vs. Entry-Point-Name Divergence (F219)**: The template architecture requires a deliberate divergence between the package name and the binary name. To establish authority and avoid namespace squatting on crates.io, the primary package name will remain `rs-launch-blueprint`. However, forcing end-users to type `rs-launch-blueprint` in the terminal for every command is hostile user experience. Therefore, the `[[bin]]` target for the CLI must be designated with a concise, ergonomic alias, such as `rsbp` [cite: 13, 27]. This deliberate divergence dictates that installing the tool requires explicit documentation stating the resulting binary name (e.g., instructing users that `cargo install rs-launch-blueprint` outputs the `rsbp` executable), directly mirroring the precedent established by widely used tools like `ripgrep` (which yields the `rg` binary) [cite: 12, 13, 18].

### Ranked runner-up

The ranked runner-up is the Cargo Workspace Pattern, an architectural approach that separates the core library, the CLI, and the Web Service into their own discrete sub-crates united under a single virtual workspace root [cite: 3, 19]. 

This pattern wins under very specific conditions: if the web service dependencies evolve to require a fundamentally different Minimum Supported Rust Version (MSRV), a different Rust edition, or if feature unification across a single `Cargo.toml` proves too brittle in a highly complex enterprise environment. For instance, if a shared internal dependency introduces a major, unavoidable breaking change when its `web` features are enabled, a single manifest will force that breaking change onto the CLI. The workspace pattern entirely prevents this feature bleed by isolating the dependency graphs [cite: 4]. However, it is rejected as the primary recommendation because it adds significant cognitive load, complicates the development environment, and requires publishing multiple discrete packages to crates.io just to distribute a single, cohesive tool.

### Tradeoffs

The `cargo-native-manifest` pattern accepts specific, calculated tradeoffs when compared to the runner-up workspace approach:

1.  **Feature Unification Risk**: In a single `Cargo.toml`, Cargo unifies features across all dependencies [cite: 15]. If both the CLI and the Web Service depend on a crate like `serde`, and the Web Service enables the `derive` feature, the CLI will also be compiled with `serde/derive`, regardless of whether the CLI explicitly asked for it. This is accepted because the shared internal library already necessitates a high degree of dependency alignment, and the minor compile-time penalty of unified features is heavily outweighed by the operational simplicity of maintaining a single `Cargo.lock` file and a unified release cadence.
2.  **Strict Whitelisting Maintenance**: Utilizing the explicit `include` array trades the convenience of "just let `.gitignore` handle it" for absolute strictness [cite: 1, 29]. Every time a new asset type (e.g., a `.json` configuration file, a new markdown template) needs to be distributed with the package, the `include` array must be manually updated. If a developer forgets, the file is silently excluded from the published crate. This ongoing maintenance cost is accepted because the accidental leakage of test data, API keys, or bulky CI scripts into the public registry is a severe security and repository bloat risk that cannot be mitigated by implicit heuristics alone.

### Parameters

owns build-tool-output-shape = cargo-native-manifest
owns entry-point-declaration = [[bin]] and [lib]
owns console-script-declaration = [[bin]] name
owns packaged-file-whitelist = include field

### Migration implications

Adopting this standard requires the following structural and file-level changes to the repository template:

1.  **File System Reorganization**: The source code must be explicitly grouped to map to the defined targets. The core library code must reside in `src/lib.rs` and its child submodules. The CLI invocation code is placed in `src/cli/main.rs`. The web server invocation code is placed in `src/web/main.rs`. This deviates from the default `src/main.rs` layout to cleanly delineate the entry points.
2.  **`Cargo.toml` Modification**: The manifest requires manual augmentation to enforce the architectural boundaries:
    *   Add the whitelist `include = ["src/**/*", "Cargo.toml", "README.md", "LICENSE"]` under the `[package]` block.
    *   Add a `[features]` block mapping the optional capability: `web-extra-surface = ["axum", "tokio/full"]`.
    *   Declare the `[[bin]]` directive for the CLI with `name = "rsbp"` and `path = "src/cli/main.rs"`.
    *   Declare the `[[bin]]` directive for the web service with `name = "rsbp-server"`, `path = "src/web/main.rs"`, and the critical gating parameter `required-features = ["web-extra-surface"]`.

### Validation strategy

To prove the architectural principle holds and that the designated targets resolve deterministically without cross-contamination, the following validation commands must be executed against a realistic implementation:

1.  **Verify Lean Default Build**:
    *   Command: `cargo build --release`
    *   Expected Behavior: Only the core library and the CLI binary (`rsbp`) compile. The compiler output explicitly ignores `src/web/main.rs`, and heavy web dependencies (e.g., `axum`) are entirely excluded from the dependency resolution output, confirming that the CLI is not burdened by web-specific bloat.
2.  **Verify Feature-Gated Build**:
    *   Command: `cargo build --release --features web-extra-surface`
    *   Expected Behavior: Both the `rsbp` and `rsbp-server` binaries compile successfully, and the web dependencies are pulled into the compilation graph.
3.  **Verify Packaged-File Whitelist**:
    *   Command: `cargo package --list`
    *   Expected Behavior: The terminal outputs a strict list of files matching only the globs defined in the `include` array. Hidden directories like `.github/`, `.gitignore`, and unrelated test artifacts are observably missing from the output, proving the distribution boundary is secure and the whitelist is enforced.

### Confidence & re-verify trigger

**Confidence Score**: High.
The native Cargo target resolution, explicitly defined entry paths, and feature-gating mechanics are deeply entrenched, canonical standards within the Rust ecosystem. The approach mirrors the exact behaviors utilized by the most widely adopted crates in the language.

**Re-verify Trigger**: This architectural choice should be re-evaluated if the Rust compiler introduces a native `[workspace.targets]` directive capable of single-package resolution without virtual workspaces, or if the dependency graph of the web service evolves to cause unacceptable MSRV conflicts with the core library that can only be resolved via physical workspace separation.

### Sources

As required by the document specification, sources are cited inline throughout the text using the designated bracketed format to preserve narrative flow. No external bibliography is appended.

**Sources:**
1. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqGxPBOtgtgiOsD4MQBx39kPw_IcEfJghNHefh-amPypFgNtWgm9XVvbHz_7bSbbhniMv4gRx87sEWMBWeeTqK2eLNQCH3zJzUYT3ss4LgTOWhBNNriC3aXUEi9wP4-JANVwMbJpOQbk5DQ0UE)
2. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEHmeBjOwn8Gaa0rOJ35GSYHZyfjMVN5t207dlzULw5O-HmmljBd41bASc0ferBsH2MivdgPEd18ldUgyXvS6A2atHd1MD3NCwkHhg1K_PEnMTesC8cjExINOx7_YsLFTxU_HL7EyuwNS-51LdKK557QJs=)
3. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5LKZgCZftHcNjkZuCXSIsCF8LGXSYgMgLBk_clHE1vvTsZb7eR7F6fVbNrJFLgmv1A7Kgcsfy-r6QMpa4JAa8z2sUI6R0iGUSL6OHPxjJ6qoFZPZB5c2u9AufNq5u-oN13wooPs7nmibuyzCUQOr4mhvl-7NL8oriL9NxQ0G2lIxwGmXoI508_-KX)
4. [logrocket.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEFrY378Slc4_IZadGSAzEQb2tkaCqOmvKHgSDCbsdeNOJ6R2lUpwSrSyGuM0cqg3LbJW5_niKAODPPEOxRmKJqLpwYsGSu6nfRVFvcEenCn9EtSTg1MtcKRKGyLy-gdQbytAQT3iL-zm-R-Qcjywj3RrHdyHAn)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGzr18yDMsh3xbKPSdUaKCRzEZqH156awVykpFRMA-t2nr8T8RehIK3W3epAXNa0_oAq-UpKOkqf6lEIxhKz-CUCR2E_KfnO-HgH0mABcSZ3egYclgKUDKQ-g==)
6. [lpalmieri.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGywkAO75KhYh0kQsVUG_Jr_3qlFOZ3p4pkuNpipza8JW-Sxa_qivzY7ArW1PiQ5N5hlrgTdxlNxUkM--1tafxglXfrWdW255VTXRcBTEMXlWXxo30pFeYc6ExW)
7. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFSfBhHxbC_eIarYpijoA3KklMA_KVZx_XZ3aVF9LSF74KkP-32nHxMooCTNckADbGwQta-e5yTjDkhTBEn05r1jOrUW8WXaOa_Bnw6oH4z6KLbx-5SAjQbxQLjwbA=)
8. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHFIS0bKw6jxCVNQLgRVNSVJnj3OoQxcwhtreur94SVaDkrR9cnSqHAr1izLw9RRGL5Q6Fp1yS-mjxDIYH0aAWBupuYVb4no6yOf4O45HNZAFATqp8q0gGRCOEq1wmsfpLrnh0odXbYuBFydrfxNA==)
9. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGG0rYoqze5Gpo8MX5OYsZbzKogK1arETdJCtgGgYinTHMOnjPPMEhVk6a68i6aqSzIPv2zQxAa73q7-Jmhu_cEWLI62jBFLnhytZSQYHrZSRDSQVUB4mYlEaqF5mFM1l4cZvkT4twMEBrVFYhZg454fwdtysWKanrRgg==)
10. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHfl47W8tH_-ujrCqvC-cUQpEhdnC2oM4woCha-WucSqmI3aC8sDSicQBKYm8LDP2DSjpKOL9RZ2yUTkhJQNcsNUv6z63AjTZ6cRl7F4yqScfQRKYqg9TzAIDgWiGKgYnSJ475kxf9Zd0uxDt_DpmPadsSR8QnKmJGHIhAACSbuyDQGi7-swq_ytoE9swnFUFrEVFLvx8CBRS9B9Que)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEcMnnKUSR5InKaSmbPuYaPTtZRrRcosqe2bNo0oigqj_6vlorCK3oyT6qQMNqMUfi5F_RkY2ALieLFKceRO8Zw5fRf2kvbhicLgTHFGvjzbcHSKsAPmO55cp0FIvpGk9ojsu_1mg==)
12. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHk7qsrUbgZCNMNkE8e4czerjflUNZQyAzDCJYalyyAZrSB1dNvxpnTHrAjUtT2yiHLqF1keUkcokifC2H6XHNc8Spl1o2sS74Dx3s4EvnzwFk4oblFtot6vgSvD-Y1A6Km7CVuAyRSVdREeVgh2ulMvHQYB1w=)
13. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFqWfsP5ORJA8RDiQGiK-42_J-LHjro1DbXaEbKUT3aOBzeQ0bAqsAMbXzCS0uZum8VpjSBwZC2uvoSJUgwPZYaGmH59hiKXLJl5nteiv8us0IqvdKrGeoKt74OXxLyeB_1l2oaYUHoEkX9O5bUxckVqhDb_ublhdJPdlftI6ouwlfBRw==)
14. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEVofISJT7speGMj9bsrSrwgAtCU7alw--nbvSzUvy2mRaxEG1PAB-uDeOmEcP_0Cz3vn3tJcNnn-w8jN_PkbhbwVcRC3rFjEJl0U4zGnvOZqR9ZVuZmrlHdGq0R-B9sScux0NBsD7AUDPR7D9TrBvKyAJvnneX)
15. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE3XgXM1r9hucmeIpqRYaN4d9FkEaWjzIpFyH4U7rEBMZE2KOB3O0byPdmHNVA5nbwkJMVcmRs8jzAS3srwSqMVWarKIKW6GUN6hd8Kkpo1jSz6Cq19BHawyIYYzqaw6V_QxnmYG9HqHSuSitZN9B6nBrG2Bnp3Z3BHlD72_ZrpNBEZVWqeFsfZ4ZK0BGSC0ATWYbDVOmAAc_0XlJY-5M7HvOjI-QAmW4RWodxV3nIZGYDeKdpNO-4qUuGX0w==)
16. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJtWaBx1doWKSJv9aAf-x6xsVRiqpk_3J6sNgkT_iAmfPARHbYL9ljnmx8XQFkUobIthZh7JYLDbLtDaf4ufIR6RXR2mV3pwKcw_aQwkkjQZLhvmCOBW3Orz_Ly-5V4HLIUVDY7IEn9EI8io7u2A0GSk-aykVTij2E3avrbf1l)
17. [rustify.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG61RRjwkUb6dj5M0O5skwk6q6XrdnF0MD3rc8F3-hpwHG6qA74oDVpJuUckM0N0GxhD3H0F6bSdLKTfYO0Iy_deU_SQnLZr1ia-YE0En798nsfSpwz4_XNRVzhatoUnVhBGhyg8HLo6I6OAJmrmARWbtOQbQIIDA==)
18. [scaler.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEnOY7HI9u-4a4Tu6K9spDF4NHWn5NuKwYKtzRXfjurvwfgnz44_NDspoR7-rRljWLR8n_Zt_c_CvA5KQLXEXrhIK4VjAQ2q4F1mtL4yYbaYInijQmVWZdHJASEpPxD-1ik-KaWKs-SZgs=)
19. [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEWGz_fYbTwOX0ceup9SBwTXjp5iUqQPmPA-IuwFUO02i1CLGU3z1q-ZoyJdqRNgVLatYy0gxfSTS4scjiD_32L5rqvm-313ik1skGbpLLRazY_OBhRRRlqizJvBDjzbIZcc_RwqkShYJOJ6g==)
20. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-kt3x_i6h4QqskvDCKBD38mxjNsizKgy-_gpnHe0s4u0r4HJEL08S4iSO-qMq81CDy3HtAA0xxGg_bbCArBi0UrspLiJWopG4EFwhFb9nEgEiLbzWYCyDkGd2Sdxjy9_JFl3VL8aS1CMJtKGBZu-2HZuAXPI8oKGA0QfOzdSCtekCkIEyc5KbwcOxwUXnfzBUPwrQx_oD)
21. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHGxjGpJ50-EFyP22J8k3D9mUatyr3RoHG1Q4HXUxguq3Jzh3jrzldfSRlFZDfiZoEGH_KHYfDOFofmFZG1AXOy4aqmTsyJ5D5joyksm2f-Qwzc5y7avYR6xzLivPRmbzb_ieZM)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEi3yIzCz_r3iT2Vdz0XwO-w1uteFYDhGFzKApq1wrxLlza2e87X9vbKqclU_NBPT7Nxe2uATMzdCQcClrff6J7IIN9nIGZfuLdMiENRioXLY4jQ1cNCiSgwN4HDjnLHs-2f9U36A==)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHPGUKH3yGK32LVqPEV-HQOrM4GLrBwB9YUcStwCPaOI1ik3_VJsYtH4sw88-iwRO2AyF0BTFZzsLHH_fycq47BS-SP6QaRosR2HHCB4JZbi1lWsRjsr-s_zzX3XdaYnQHO-KR2iOrpIFQdoXY=)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGXYcjRowAbl0XvXydZ-azIUQhrw5nuxKjgeXnYZIWvBogeGCABgl5t_Cn-ZlHGADkyjhUeJnEuP5UnMiq2ksBaOAfNEDEDIRPcDz7FVYNUiAlxElWYEhVD44LSp19xGQ==)
25. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo1T4uAaJ8ICFWdLXPzgT6-oGTlDGAHRG9tPByzKkSjYLOd53DoGsa5yaMoUvgl5DS5ilax916gQ4owOm4jRUetdgIDShbAH89C8w5xROzuD5ijbUasbWAlg-X-3PHH4Ugq_kUGsqll6GdqU3tPxychSMbM1ke3GJZvc-Ar1zYC0YeMGcuFITpghAioEAnjR_EvAA=)
26. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgD0ctazsX9IfliYrF6yws-rfINPQx4hNynCw7MGIWaxgvpkU6G_gaQoNUN4XBguRCUbN0PEnP9SIpOeJ7cxSVh9Yp43HrW2i0cchI4mEcFFWSe8YieF4Gn8uYyajGvTeBJ6O1OrEBFmacxKphBgxnKsu7A9inu5tYiEjXpRENnkF1tFUemUSXhlvfs1Hq)
27. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFQ4mworb6Jw4dwnkDvcjibkwHooOSt3o76Lrv-vsZfdHFMJQFA_ilvUuF1x3O0dQpeU0HpFJQJfarQA9os7dvpWD-9kyQpws9XCPBP2ZoekKZ4IEkWX0jJwfcSdBVxpQRhlGhJUPwnwq21vxHMSnPW-6LGyycgXKQf2Q==)
28. [rustprojectprimer.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFtDWiq0u177Fn6cHP1M486EdjtzoyW43FUg9K7tg5-rOB11yILKRq3YmErJ2anGcs61cWrJSQfHI_VpDGjxkaKqyaKHj3n84Me0jThQJ8DZW3b0gG-70OeCd5ReZiUe-lLvuTScrT2JWgZh5-DrSjE3v8=)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQmuNbceVgN6KAD3Y-8lZpWczIT-C0x4LuGfiC_yMo1Nwk8gvUdGCnekIAQNkt6ZOKzaLnLD-B-IJXsKK4K-VY4hOZ6u9HeKWLNYn13a_oqJd9WQub7-lckr_7coX14DqfmCjU)

## Sources

- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/cargo-targets.html)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/manifest.html)
- [logrocket.com](https://blog.logrocket.com/best-way-structure-rust-web-services/)
- [medium.com](https://leapcell.medium.com/mastering-large-project-organization-in-rust-a21d62fb1e8e)
- [github.io](https://axodotdev.github.io/cargo-dist/)
- [lpalmieri.com](https://lpalmieri.com/posts/cargo-px/)
- [crates.io](https://crates.io/crates/cargo-make)
- [github.io](https://rust-lang.github.io/rfcs/1200-cargo-install.html)
- [github.io](https://rust-lang.github.io/rfcs/3028-cargo-binary-dependencies.html)
- [github.com](https://github.com/rust-lang/cargo/issues/16267)
- [rust-lang.org](https://internals.rust-lang.org/t/exclude-github-and-gitignore-from-published-packages-by-default/23700)
- [rust-lang.org](https://users.rust-lang.org/t/publish-on-crates-io-under-different-name/93801)
- [rust-lang.org](https://doc.rust-lang.org/book/ch14-04-installing-binaries.html)
- [medium.com](https://medium.com/@theopinionatedev/how-rust-analyzes-features-and-conditional-compilation-the-secret-language-of-cargo-2bc31f4a1ba6)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/features-examples.html)
- [scaler.com](https://www.scaler.com/blog/rust-projects-to-build/)
- [rustify.rs](https://rustify.rs/articles/best-rust-projects-for-beginners-2026)
- [dev.to](https://dev.to/sgchris/how-to-structure-a-rust-project-idiomatically-500k)
- [rustprojectprimer.com](https://rustprojectprimer.com/organization/index.html)
- [medium.com](https://medium.com/rustaceans/the-cargo-features-most-rust-developers-still-underuse-674592a08826)
- [github.com](https://github.com/rust-lang/cargo/issues/16872)
- [github.com](https://github.com/rust-lang/cargo/issues/2063)
- [crates.io](https://crates.io/crates/cargo-dist/0.0.3-prerelease08)
- [crates.io](https://crates.io/crates/cargo-build-dist)
- [reddit.com](https://www.reddit.com/r/learnrust/comments/xhkl56/makefile_or_cargo_building_a_project_with/)
- [reddit.com](https://www.reddit.com/r/rust/comments/mxms1n/understanding_packages_and_crates_in_rust/)
- [rust-lang.org](https://users.rust-lang.org/t/crate-name-for-a-library-a-tool/137100)
- [rustprojectprimer.com](https://www.rustprojectprimer.com/organization/features.html)
- [github.com](https://github.com/rust-lang/cargo/issues/4268)