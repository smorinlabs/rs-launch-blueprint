# Deep-research prompt — Linter and editor tooling (R28, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: the Rust linter tool, its rule-selection mechanism, its default autofix behavior, its per-context relaxation for test files, its built-in security-rule coverage, and the recommended VS Code extension set covering lint/format, the type checker, and the debugger. Item kind: `bundle`. Value test: if this answer is wrong, `Cargo.toml`'s `[lints.clippy]` table (or a `clippy.toml`), the Justfile's `lint` recipe, `.vscode/extensions.json`, and `.vscode/settings.json` all get rewritten.

## Context
- Research mandate (owner clarification 2026-09-04, spec §2/A5): identify the shared engineering principle, the level at which agreement is required (capability, standard, architectural pattern or policy), and observable acceptance criteria; then research the architectures and libraries that best realize them in this ecosystem. Source implementations and ledger classifications are evidence, not predetermined winners. Agreement, familiarity, or maximum benchmark throughput alone cannot select a design. This mandate supersedes inherited-mechanism wording below; explicit owner requirements, fixed parameters, and dependency ownership remain binding. Report a challenged baseline as `BASELINE-REVIEW: F### — principle — proposed change — evidence` in the answer; do not silently change another item or the ledger.
- Source precedent (spec §2): both repos run one dedicated linter tool through the same three surfaces (Justfile recipe, lefthook hook, CI job) — py's `ruff check`, ts's `oxlint`. Evidence: py `Justfile:228` — `ruff check` lints Python via `uv run`; ts `Justfile:123` — `oxlint` lints TS/JS via `pnpm exec`. Ledger rows: F085, F086, F093, F094, F096, F101 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; plus F109 (`docs/port/areas/static-analysis.md`), also `DIVERGENT`; plus F195 (`docs/port/areas/dev-experience-repo-hygiene.md`), verdict `COMMON → SUBSTITUTE`, parent F194; and F196 (same area file), verdict `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F086 rule-selection mechanism — py `pyproject.toml:150` (`lint.select` lists rule-category codes); ts `.oxlintrc.json:15` (`categories` plus explicit `plugins`/`rules` lists). F093 default autofix behavior — py `pyproject.toml:177` (`fix = true` makes autofix the default); ts `Justfile:130` (`--fix` flag needed; `lint` runs check-only). F094 per-context lint relaxation for test files — py `pyproject.toml:195` (`per-file-ignores` for `"tests/*"`); ts `.oxlintrc.json:52` (`overrides` files globs for `tests/**`). F096 security-rule coverage via the linter — py `pyproject.toml:161` (`"S"` selects the flake8-bandit rule set); ts `.oxlintrc.json:35` (built-in rules like `no-eval`, no bandit analog; coverage layered with a separate CodeQL workflow). F101 editor extension for lint/format — py `.vscode/extensions.json:5` (`charliermarsh.ruff`); ts `.vscode/extensions.json:3` (`oxc.oxc-vscode`). F109 type-checker editor-extension recommendation — py `.vscode/extensions.json:4` (`ms-python.vscode-pylance`, driving the IDE-only pyright checker); ts: none (TypeScript's language service ships built into VS Code, no extension needed). F195 VS Code debugger tool/extension — py `.vscode/launch.json:6`, `:8` (`"type": "python"`, `program` set to `src/py_launch_blueprint/cli/main.py`); ts `.vscode/launch.json:6`, `:8` (`"type": "node"`, `runtimeExecutable: "tsx"` against `src/cli.ts`). F196 committed `.vscode/settings.json` pinning the editor's language-service version — py: none; ts `.vscode/settings.json:2` (`"typescript.tsdk": "node_modules/typescript/lib"`).
- Presumption of reuse (spec §2): F195 is `COMMON → SUBSTITUTE` with parent F194 (`COMMON → REUSE`, not owned by any item) — F194 settles that a committed `.vscode/launch.json` debug config is inherited as-is; do not reconsider whether to ship one. F195 asks only for the Rust-native debugger tool/extension that plugs into that pattern, not a redesign of the pattern itself.
- Recorded baseline and owner-fixed parameters (apply the research mandate above): `clippy` is near-certain as the linter tool itself (bundled with rustup, unlike py/ts's real tool choice) — the ledger's own note on F085 frames the research question as clippy's *config surface*, not tool selection; confirm this in your answer but do not spend significant budget surveying alternatives. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — Oxlint (1.x, stable, caret-pinned) chosen as linter; D-014(4) — per-file-ignores ported as Oxlint's `overrides` array with files globs; D-014(5) — security coverage layered as oxlint built-ins plus a CI CodeQL workflow, explicitly recording that neither Oxlint nor Biome offers a bandit-equivalent; D-024(3) — the VS Code debugger config uses the built-in `vscode-js-debug`, no extension install needed; D-024(4) — `.vscode/extensions.json` drops py's four Python-specific recommendations, keeps 8 cross-platform ones, adds only the lint/format extension; D-032 — the one-key `.vscode/settings.json` pinning `typescript.tsdk` is a narrow, deliberate exception to the source's no-`settings.json` principle. F093 carries no ts-decision record (`—`).

## Out of scope
- `rustfmt`'s own config surface (line width, line endings, trailing commas, import ordering, exclude-list scope, composite-recipe placement, version pinning, hook mode); R27 (`formatter-config-surface`) owns F084/F087/F089/F091/F092/F100/F102/F103/F104/F162.
- Non-Rust-source-code formatting; R29 (`non-code-file-formatting`) owns F097/F098/F099.
- The type-checker engine and its CI/hook-tier/strictness/suppression/scope configuration; R30 (`type-check-gate`) owns F105/F106/F107/F108/F110/F111/F112/F113 — this item owns only the type-checker's editor-extension recommendation (F109), decided together with the lint/format extension (F101).
- Whether a standalone AST-based security scanner beyond the linter's built-in rules is adopted; R31 (`standalone-security-analyzer`) owns F114/F115 — this item decides only clippy's own built-in security-adjacent lint coverage (F096).
- The shape of the CI job(s) that run the linter; R11 (`ci-workflow-job-structure`) owns `ci-job-structure`.
- The Justfile/lefthook invocation syntax; R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation`.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R28
- owns:
- consumes: R11: ci-job-structure; R42: package-manager-invocation
- related (not a registry dependency): R30 (`type-check-gate`) owns the type-checker engine and its CI/hook/strictness configuration (F105-F108, F110-F113). This item only picks that checker's editor-extension recommendation (F109) alongside the lint/format extension (F101) — assume R30 has picked a checker (likely `rust-analyzer`'s built-in diagnostics or a `cargo check`-based gate) and recommend the matching editor extension, without re-deciding which checker runs in CI.
- related (not a registry dependency): R27 (`formatter-config-surface`) decides `rustfmt`'s config surface in the same bundle-decided-together spirit; F100's exclude-list scope question depends on this item's clippy config shape — coordinate the answer's exclude-scope recommendation with R27's, but do not decide R27's formatter config here.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what linter tool, rule-selection mechanism, autofix default, test-file lint relaxation, linter-level security-rule coverage, and editor-extension set (lint/format, type-check, debugger, plus any version-pin settings file) does `rs-launch-blueprint` use.
- HIGH: Confirm `clippy` is the Rust ecosystem's near-universal linter (bundled with rustup, unlike py/ts's real tool choice) — is there a credible alternative worth even naming, or is clippy uncontested?
- HIGH: What is Rust/clippy's idiomatic analogue of ts's `categories` plus `plugins`/`rules` rule-selection model (F086) — clippy's lint groups (`clippy::all`, `clippy::pedantic`, `clippy::nursery`, `clippy::cargo`) selected via a `[lints.clippy]` table in `Cargo.toml`, a `clippy.toml` config file for threshold-style lints, or both together?
- HIGH: Is `cargo clippy --fix` a safe default-on autofix (matching py's `fix = true`) or does clippy's fix suite carry enough risk (ambiguous or semantically-changing fixes) that it should stay opt-in behind an explicit flag, like ts's `--fix` (F093)?
- HIGH (owner clarification 2026-09-04): Which engineering principles and agreement levels must this item preserve across py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint, and which architectures, libraries or conventions best realize them in each ecosystem? Use the existing implementations and their research as evidence, without assuming any repo is the winner. Distinguish missing capability or accidental drift from justified ecosystem differences. Preserve agreement at the declared level. Recommend a shared low-level value only when it is an explicit owner requirement or evidence supports the same tradeoff in all affected ecosystems; otherwise explain each justified difference and how it preserves the principle. Changes to py and ts remain a follow-on project; this answer supplies their rationale. Scope the cross-repo comparison to the shared principle identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; research the Rust implementation in full.
- MEDIUM: What is the idiomatic per-module lint relaxation mechanism for test code (F094) — `#[allow(...)]` attributes on `#[cfg(test)]` modules or functions, or a `[lints]` override scoped by path — and does it need per-file glob support the way py's `per-file-ignores` and ts's `overrides` array do, or does Rust's module system make that unnecessary?
- MEDIUM: Beyond clippy's built-in security-adjacent lints, does the answer note that a CI-level SAST workflow (CodeQL or similar) covers the same gap `bandit` filled for py (F096) — while explicitly deferring whether a *standalone* AST security scanner is separately adopted to R31?
- MEDIUM: What is the current dominant VS Code extension for Rust covering lint, format, and type-check together (F101, F109) — does the official `rust-analyzer` extension alone replace the three separate extensions (`ruff`, `pylance`, `oxc`) the source repos needed, or is a separate clippy-specific extension still recommended?
- MEDIUM: What is the Rust-native debugger extension (F195 — presumption of reuse; the committed `launch.json` pattern itself is settled by F194, only the tool changes) that plugs into a committed `.vscode/launch.json` — `vadimcn.vscode-lldb` (CodeLLDB), the official `rust-lang.rust-analyzer` extension's own bundled debug support, or a platform-specific choice, given this repo's `target-os-matrix` is `ubuntu-latest, macos-latest` only (no Windows-specific debugger needed)?
- LOW: Does a `.vscode/settings.json` pin need to exist for `rust-analyzer` the way ts pins `typescript.tsdk` (F196), given `rust-analyzer` resolves the Rust toolchain via `rust-toolchain.toml` rather than a `node_modules`-style local package version — or does F196 collapse to "no equivalent pin needed" for Rust?

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
