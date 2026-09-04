# Deep-research prompt — Formatter config surface (R27, bundle)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named stack of crates and reference pattern (with versions) for: the Rust source-code formatter tool, its config surface (line width, line-ending normalization, trailing-comma style, import ordering), its exclude-list scope, its version-pinning strategy, its pre-commit hook mode (check-and-block vs. write-and-restage), and whether the composite `check`/`all` recipe includes a format-check step. Item kind: `bundle`. Value test: if this answer is wrong, `rustfmt.toml`, the Justfile's `format`/`check` recipes, `lefthook.yml`'s formatter job, and the CI job that runs it all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos run one dedicated formatter tool through the same three surfaces (Justfile recipe, lefthook hook, CI job) — py's `ruff format`, ts's `oxfmt`. Evidence: py `Justfile:203` — `ruff format` formats Python via `uv run`; ts `Justfile:105` — `oxfmt` formats TS/JS via `pnpm exec`. Ledger rows: F084, F087, F089, F091, F092, F100, F102, F103, F104 (`docs/port/COMMONALITY.md`), verdict `DIVERGENT`; plus F162 (`docs/port/areas/git-hooks-commit-hygiene.md`), also `DIVERGENT`.
- Per-row evidence for the rest of this bundle: F087 max line width — py `pyproject.toml:148` (`line-length = 88`); ts `.oxfmtrc.json:6` (`printWidth: 100`). F089 line-ending normalization — py `pyproject.toml:209` (`line-ending = "auto"`, detects existing); ts `.oxfmtrc.json:10` (`endOfLine: "lf"`, fixed). F091 trailing-comma style — py: none (ruff's formatter has no such option); ts `.oxfmtrc.json:9` (`trailingComma: "es5"`). F092 import-sorting ownership — py `pyproject.toml:153` (`"I"` isort selected as a lint rule); ts `.oxfmtrc.json:13` (`sortImports: true`, a formatter option). F100 exclude-list configuration scope — py `pyproject.toml:180` (one `[tool.ruff] exclude` shared by lint+format); ts `.oxlintrc.json:69` and `.oxfmtrc.json:17` (separate `ignorePatterns` per tool config file). F102 composite recipe including a format-check step — py `Justfile:277` (`check` composite: lint, no format-check); ts `Justfile:178` (`all` composite: format-check + lint + typecheck + test). F103 version-pinning strategy — py `pyproject.toml:78` (`ruff>=0.1.0` floating range, pinned via `uv.lock`); ts `package.json:55` (`oxfmt` exact-pinned given its beta status, `oxlint` caret-ranged, both via `pnpm-lock.yaml`). F104 pre-commit hook mode — py `lefthook.yml:114` (`ruff format --check` blocks the commit, no rewrite); ts `lefthook.yml:32` (`oxfmt` writes fixes, `stage_fixed: true` re-stages them). F162 hook exclude-list drift guard — ts `tests/repo-hygiene.test.ts:81` (asserts the format/lint job's `exclude` set equals `.oxfmtrc.json`/`.oxlintrc.json` `ignorePatterns`); py: none.
- Already decided, do not re-open: `rustfmt` is near-certain as the tool itself (unlike py/ts's real formatter choice, Rust has one dominant, rustup-bundled formatter) — the ledger's own note on F084 frames the research question as rustfmt's *config surface*, not tool selection; confirm this in your answer but do not spend significant budget surveying alternatives. `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-014(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — Oxfmt (0.58.0-0.59.0 beta, exact-pinned) chosen as formatter, Biome documented as the stability-first fallback; D-014(2) — formatter style options (`printWidth: 100`, `endOfLine: "lf"`, `trailingComma: "es5"`) reused from org Prettier/Biome precedent rather than py's Python-norm values; D-014(3) — Oxfmt's `sortImports` enabled as the import-sorting mechanism; D-024(1) — the `all` composite recipe includes format-check as part of a near-1:1 Justfile port; D-020(6) — lefthook's pre-commit tier runs formatter with `stage_fixed` (write mode). F100 and F162 carry no ts-decision record (`—` in the area tables).

## Out of scope
- The linter (clippy) tool and its own config surface (rule selection, autofix default, test-file relaxation, security-rule coverage, editor extension); R28 (`linter-and-editor-tooling`) owns F085/F086/F093/F094/F096/F101/F109/F195/F196.
- Non-Rust-source-code formatting (TOML, YAML, JSON, Markdown); R29 (`non-code-file-formatting`) owns F097/F098/F099 — this item covers only `rustfmt`'s scan scope (Rust source files).
- The shape of the CI job(s) that run the formatter check; R11 (`ci-workflow-job-structure`) owns `ci-job-structure` — this item decides what to run, not the job/step topology it runs inside.
- The Justfile/lefthook invocation syntax (a bare `cargo fmt` vs. a provisioned binary on `PATH`); R42 (`dev-toolchain-provisioning`) owns `package-manager-invocation` — this item decides the tool and its config, not how the recipe phrases the call.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R27
- owns:
- consumes: R11: ci-job-structure; R42: package-manager-invocation
- related (not a registry dependency): R28 (`linter-and-editor-tooling`) decides clippy's config surface in the same bundle-decided-together spirit; F100's exclude-list scope question ("does Rust share one exclude list across rustfmt/clippy or keep them per-tool") depends on R28's clippy config shape — assume R28's answer is open and state the exclude-list recommendation for both outcomes if they diverge.
If your recommendation needs a consumed parameter to change, do not change it: write `CONFLICT: R## <param> — <needed value> — <reason>` in the `Parameters` field of your answer.

## Questions
Decision: what formatter tool, config surface, exclude-list scope, composite-recipe placement, version-pinning strategy, and pre-commit hook mode does `rs-launch-blueprint` use for Rust source-code formatting.
- HIGH: Confirm `rustfmt` is the Rust ecosystem's dominant, near-universal source formatter (bundled with rustup, unlike py/ts's real tool choice) — is there any credible alternative (a dprint/Biome-style formatter targeting Rust) worth even naming, or is rustfmt uncontested?
- HIGH: What `rustfmt.toml` config values are the Rust-idiomatic settings closest to the two sources' `max_width` (py 88 / ts 100), `newline_style` (py auto-detect / ts fixed LF), `trailing_comma` (ts `es5`-equivalent), and import-ordering (`reorder_imports`/`imports_granularity`, matching ts's `sortImports: true`) — and which of these require rustfmt's `unstable_features`/a nightly toolchain, versus being available on stable Rust (this repo's fixed constraint)?
- MEDIUM: Should `rustfmt.toml`'s `ignore` list and clippy's exclude configuration (owned by R28) share one exclude scope (py's shape), or does Rust idiom keep them in separate per-tool config files (ts's shape) — and if separate, what test (mirroring ts's F162 `repo-hygiene.test.ts` consistency check) keeps the two exclude lists from drifting apart?
- MEDIUM: Does the composite `just check`/`just all` recipe include a `cargo fmt --check` step (ts's shape) or omit it (py's shape), and is rustfmt fast enough that this choice is low-stakes either way?
- LOW: Given rustfmt ships as a rustup component (not a Cargo/crates.io dependency), is there a meaningful "version-pinning strategy" beyond the MSRV policy already fixed for this repo (a `rust-toolchain.toml` component pin), or does F103 collapse to "no separate decision needed" for Rust?
- LOW: Should the pre-commit hook run `cargo fmt` in write mode (matching ts's `stage_fixed` re-stage) or `cargo fmt --check` in blocking mode (matching py's fail-on-unformatted) — what do popular Rust project templates default to?
- HIGH (owner review 2026-09-04): Recommend one value or convention for py-launch-blueprint, ts-launch-blueprint and rs-launch-blueprint together. Take the principle from the more mature implementation (py-launch-blueprint unless the evidence says otherwise), not its library or code pattern, and name the language-native equivalent for ts and rs. Where py and ts differ, whether from maturity or arbitrary drift, name the single value all three should adopt. Propagating that value into py and ts is a follow-on project; this answer is its input (owner direction, `docs/port/OWNER-REVIEW.md`). Scope this to the shared, language-neutral part identified for this item in `docs/port/DIVERGENCE-ANALYSIS.md`; the Rust-specific part is still answered for Rust alone.

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
