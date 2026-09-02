# Deep-research prompt — Build-target declaration (R49, crate)

## Objective
Consumer: the implementation plan for `rs-launch-blueprint`, a Rust template shaped as CLI + library + web service. Deliver a named crate with a version range for: how `rs-launch-blueprint`'s Cargo manifest declares its build backend/output, entry points (CLI binary and library), console-script/bin entry, packaged-file whitelist, and any distribution-name-vs-entry-point-name divergence — the Rust analogue of py's `uv_build` PEP 517 backend plus `[project.scripts]`/layout settings and ts's `tsdown` bundler plus explicit `entry`/`bin`/`files` fields. Item kind: `crate`. Value test: if this answer is wrong, `Cargo.toml`'s `[package]`, `[[bin]]`, `[lib]`, and `include`/`exclude` fields, and any build-backend dependency, all get rewritten.

## Context
- Inherited pattern (spec §2, presumption of reuse): both repos have a build backend/bundler that produces the distributable package from source (the pattern), but the specific tool is language-bound in both — py's PEP 517 `uv_build` backend and ts's `tsdown` (rolldown) bundler. Evidence: py `pyproject.toml:133` — `build-backend = "uv_build"` (PEP 517); ts `tsdown.config.ts:8` — `defineConfig({...})` bundler config. Ledger row: F212 (`docs/port/COMMONALITY.md`), verdict `COMMON → SUBSTITUTE`, parent F211 (the tool-free pattern row, `COMMON → REUSE`).
- Per-row evidence for the rest of this bundle: F213 build entry-point declaration — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` point at one package root, py's whole package is one build unit); ts `tsdown.config.ts:9` (`entry: ['src/cli.ts', 'src/lib.ts']` lists two explicit entries; ts bundles CLI and library as separate entries). F216 console-script/bin entry declaration — py `pyproject.toml:120` (`plbp = "py_launch_blueprint.cli.main:cli"`, a module:function reference); ts `package.json:18` (`"ts-projects": "dist/cli.js"`, a built file path). F218 packaged-file whitelist mechanism — py `pyproject.toml:139`, `pyproject.toml:141` (`module-name`/`module-root` implicitly bounds wheel content); ts `package.json:20`, `package.json:22` (explicit `"files": ["dist"]` array). F219 distribution-name vs. entry-point-name divergence — py `README.md:45` (`uvx --from py-launch-blueprint plbp`, needed since the distribution name differs from the script name); ts `package.json:2`, `package.json:18` (package name `ts-launch-blueprint` differs from bin `ts-projects`, no special install-time flag needed).
- Already decided, do not re-open: `rust-edition` = `2024`, `msrv-policy` = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI", `license` = `MIT OR Apache-2.0`, `target-os-matrix` = `ubuntu-latest, macos-latest` (`docs/port/PARAMETERS.md`, fixed, owner-decided 2026-09-02).
- Prior decisions of the TypeScript port that explain the current shape: D-012(1) (`ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md`) — chose `tsdown` (pinned 0.22.x) with two entries (`src/cli.ts` + `src/lib.ts`), dts, sourcemaps, shebang, as tsup's officially designated successor, preserving agent2linear's bundle-with-dts intent; and D-012(3) — hand-authored the `package.json` packaging surface (root-only exports map, `bin -> ./dist/cli.js`, `files: ["dist"]`) rather than using tsdown's exports auto-generation, treating these fields as the npm analogue of wheel/sdist content lists.

## Out of scope
- Which release binary artifacts (beyond the single `.crate` file `cargo publish` produces) this template ships — crates.io-only vs. `cargo-dist` cross-compiled GitHub Release binaries vs. `cargo-binstall` metadata; R68 (`release-binary-artifacts`) owns F214, this item's SUBSTITUTE parent's sibling row — this item decides the manifest-level build/entry-point declaration, not the distribution-artifact-type question.
- CI-wired install smoke-testing cadence and mechanism; R50 (`install-smoke-test`) owns F221/F222 — this item declares the build targets, it does not decide how they are smoke-tested.
- Prior art in the owner's other Rust repositories — do not look for or cite it.

## Couplings
- id: R49
- owns: build-tool-output-shape
- consumes:
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
Commands that prove the choice landed.
### Confidence & re-verify trigger
### Sources

## Constraints
- Fresh ecosystem survey; no prior-art baseline.
- Stable Rust only; edition `2024`; MSRV policy `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`; license `MIT OR Apache-2.0`.
- CI on `ubuntu-latest, macos-latest` — every recommendation must work on all of them.
- Every claim carries a source URL and retrieval date; every number carries its endpoint.
