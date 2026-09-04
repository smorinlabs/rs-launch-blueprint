# Deep-research prompt — Type-check gate (R30, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: whether `cargo check`/the Rust compiler itself is `rs-launch-blueprint`'s sufficient CI-authoritative type-check gate, or whether the template needs a wrapper or additional strictness layer, plus where that gate runs in the hook/CI pipeline, its suppression-comment discipline, its warning-vs-error severity tier, and whether its scope includes test code. Item kind: `bundle`. Value test: if this answer is wrong, the Justfile's `typecheck` recipe, `lefthook.yml`'s hook-tier placement for it, any `[lints.rust]`/`#![warn(...)]` strictness configuration, and the CI job that gates on it all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos run a dedicated type-checker distinct from the linter, gated in CI, with a deliberate hook-tier placement; py additionally runs a second, IDE-only checker (pyright) that ts collapses into one engine via a `tsdk`-pinned `.vscode/settings.json`. Evidence: py `Justfile:237` — `uv run --extra web ty check {{py_package_path}}/`; ts `Justfile:137` — `pnpm run typecheck`; `package.json:33` — `"typecheck": "tsc --noEmit"`. Ledger rows: F105, F106, F107, F108, F110, F111, F112, F113 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT` — the ledger's own note on F105 states the Rust baseline is `rustc`/`cargo check` (type-checking is inherent to compilation, unlike py/ts which each needed a separate tool), and whether a wrapper or stricter layer is adopted is the open question that decides F106-F108 and F110-F113.
- Per-row evidence for the rest of this bundle: F106 hook-tier placement — py `lefthook.yml:166`, `:167` (`ty` runs at pre-push only, full-tree scan judged too slow per-commit, ADR-0018); ts `lefthook.yml:60`, `:61` (`tsc --noEmit` runs at pre-commit, every commit). F107 single engine serving both CI and editor — ts-only: `tsconfig.json:30` (`noEmit: true`, one config typechecks CI and the editor language service); `.vscode/settings.json:2` (`typescript.tsdk` pins the editor to the workspace `typescript` package); py's structural counterpart is the second, IDE-only checker below, not a single-engine design. F108 dedicated IDE-only checker distinct from the CI-authoritative one — py-only: `pyproject.toml:214`, `:218` (`[tool.pyright]` `typeCheckingMode = "strict"`, drives the editor extension and ad-hoc runs, not invoked in CI). F110 opt-in strictness configuration — py `pyproject.toml:254`, `:258` (`[tool.ty.rules]` promotes named rules to `error`, rule-based); ts `tsconfig.json:11`, `:18` (`strict: true` plus an explicit flag union, flag-based). F111 suppression-comment discipline — py-only: `pyproject.toml:255-257` (`blanket-ignore-comment`/`invalid-ignore-comment`/`ignore-comment-unknown-rule` all `= "error"`: every `# ty: ignore` must name its rule); ts has no configured `@ts-expect-error`/`@ts-ignore` linting convention. F112 warning-vs-error severity tier — py-only: `pyproject.toml:263` (`[tool.ty.terminal]` `error-on-warning = false`: warnings inform without failing the gate); `tsc --noEmit` has no separate warning tier, every diagnostic fails the gate. F113 gate scope (tests included) — py `Justfile:237`, `lefthook.yml:167` (scoped to `src/` only, `tests/` excluded from the CI-authoritative gate; `tests/` coverage exists only in the non-gating pyright config); ts `tsconfig.json:32` (`"include"` lists `src/**/*.ts` and `tests/**/*.ts` together).
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-015(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — `tsc --noEmit`, pinned stable, as a dedicated step distinct from build/lint in CI, hooks, and composite gates, replacing py's mypy; D-015(2) — omit a second checker analogue to pyright's editor role; preserve the editor≡CI intent by committing `.vscode/settings.json` with the `tsdk` pin instead; D-015(4) — typecheck as a first-class `just` recipe (aliased `tc`), with test files included in the gate's `tsconfig` scope; D-020(6) — `tsc --noEmit` runs at the pre-commit hook tier; D-013(4) — frames test-file inclusion as fixing py's "under-checking of tests"; D-032 — the one-key `.vscode/settings.json` (`typescript.tsdk`) is a narrow, deliberate exception to the source's no-`settings.json` principle, closing the loop between D-015(2) and D-024(4).

## Out of scope
- `rustfmt`'s and clippy's own config surfaces; R27 (`formatter-config-surface`) and R28 (`linter-and-editor-tooling`) own those.
- The type-checker's editor-extension recommendation; R28 owns F109 (decided together with F101, the lint/format extension) — this item picks the checker engine and its CI/hook/strictness/suppression/scope configuration, not which VS Code extension surfaces it.
- Whether a standalone AST-based security scanner beyond the linter's built-in rules is adopted; R31 (`standalone-security-analyzer`) owns F114/F115.
- The shape of the CI job(s) that run the type-check gate; R11 (`ci-workflow-job-structure`) owns `ci-job-structure`.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R30
- owns:
- consumes: R11: ci-job-structure
- related (not a registry dependency): R28 (`linter-and-editor-tooling`) owns the type-checker's editor-extension recommendation (F109); assume this item's checker choice (`rust-analyzer`'s built-in diagnostics, a `cargo check`-based gate, or both) is what R28's editor-extension answer must match, without deciding R28's extension pick here.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: is `cargo check`/the Rust compiler itself sufficient as `rs-launch-blueprint`'s CI-authoritative type-check gate, or does the template need a wrapper or additional strictness layer — and where does it run in the hook/CI pipeline, with what suppression discipline and what scope (`src/` only vs. `src/` plus `tests/`).
- HIGH: Since Rust type-checks as part of compilation, is `cargo check` (or `cargo build`) itself "the type-checker" with no separate tool needed — unlike py (needed `ty`/mypy) and ts (needed `tsc`), which lack Rust's compile-time-checked-by-default property — or does the template still want a distinct, named `cargo check --workspace --all-targets` step as its own CI job/Justfile recipe, mirroring the "distinct step from build/lint" pattern ts's D-015(1) establishes?
- HIGH: Does Rust need py's second, IDE-only strict checker (F108, pyright) at all, given `rust-analyzer` — like ts's `tsc` — is a single engine that can serve both the editor and (when invoked as `cargo check`) CI, collapsing py's two-engine split into ts's one-engine design by default?
- HIGH: What is Rust's analogue of py's opt-in named-rule strictness (`[tool.ty.rules]`, F110) or ts's flag-based strictness union (`tsconfig.json` `strict` plus explicit flags) — `#![warn(...)]`/`#![deny(...)]` lint-level attributes at the crate root, a `[lints.rust]`/`[lints.clippy]` table in `Cargo.toml`, or is Rust's default strictness already maximal enough that nothing needs configuring for a type-check gate specifically (as opposed to a lint gate)?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.
- MEDIUM: Does Rust need a suppression-comment discipline (F111, py's "every `# ty: ignore` must name its rule") for its type-check gate specifically — is `#[allow(...)]` with a named lint already self-documenting for compiler warnings, and does this differ from clippy's suppression conventions (owned by R28)?
- MEDIUM: Does `cargo check` have a warning-vs-error severity tier (F112, py's `error-on-warning = false`) — are Rust compiler warnings ever expected to inform without failing CI, or does this repo's CI treat every `cargo check` warning as gate-failing by convention (e.g. `RUSTFLAGS="-D warnings"`)?
- MEDIUM: Should the gate scope (F113) include test code (`#[cfg(test)]` modules, an integration-test crate under `tests/`) — does `cargo check --all-targets` already cover this by default the way py's gate deliberately excludes `tests/` and ts's deliberately includes them?
- LOW: Given py deliberately keeps its checker out of pre-commit (full-tree scan too slow, F106) while ts puts it in every commit — is Rust's `cargo check` (incremental, cached via `target/`) fast enough for a pre-commit hook tier, or does it need to stay pre-push like py's `ty`?

## Required evidence
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
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | name + link; "well-known" = nameable without lookup |

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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
