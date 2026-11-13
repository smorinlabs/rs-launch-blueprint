# R30 — type-check-gate (bundle, Focused) — Opus raw report

Engine: opus (`claude-opus-5-5`), CLI seat, run `2026-09-26T190200Z-c5c1105074c1`.
Item R30, kind `bundle`, ledger rows F105, F106, F107, F108, F110, F111, F112, F113
(`docs/port/COMMONALITY.md:111-119`), all `DIVERGENT`. All retrieval dates in this report
are **2026-09-26**. Every figure names the endpoint that produced it. This leg is
independent: no other engine's report for this run was opened.

Toolchains used for the executed checks, named exactly, because they differ:

| Name in this report | Binary | Version |
|---|---|---|
| current stable | Homebrew `cargo` / `rustc` first on `PATH` | cargo 1.98.1 (797e8a9bc 2026-08-05), rustc 1.98.1 (48a229cea 2026-09-01) |
| MSRV floor | `rustup run 1.96.0 cargo` | 1.96.0 — the floor that `msrv-policy` ("stable minus 2") gives while stable is 1.98 |
| first release with `build.warnings` | `rustup run 1.97.1 cargo` | cargo 1.97.1 (c980f4866 2026-06-30) |
| not used as "stable" | rustup's `stable` alias and the installed `rust-analyzer` binary | both 1.94.0 — stale locally, never cited as current |

Host for every executed check: macOS (Darwin 25.4.0), Apple M4 Pro, 14 cores, crates
served offline from the local `~/.cargo/registry` cache. Scratch projects lived under
`/tmp/r30probe.keS6/` (outside the repository). No ubuntu-latest measurement was made.

### Landscape

**Category decided.** The CI-authoritative *static type-check gate* for a Rust
workspace: which engine decides "this code type-checks", how the gate is invoked
(recipe, hook tier, CI step), what makes a diagnostic gate-failing, how suppressions are
written, and which targets are in scope. It is distinct from the lint gate (clippy,
R28) and the formatter (R27), although in Rust the lint engine embeds the type-check
engine (clippy-driver is rustc plus extra lint passes).

**Three-bin map.**

| Bin | Candidate | Role it could play here |
|---|---|---|
| Built-in / first-party toolchain | `rustc` invoked through `cargo check` | The type checker itself; emits metadata only, no codegen |
| Built-in / first-party toolchain | `cargo build` / `cargo test --no-run` | Also type-checks, but pays codegen and linking |
| Built-in / first-party toolchain | `cargo clippy` (rustup component) | Runs the full rustc front end plus clippy lints; a superset of `cargo check` |
| Built-in / first-party toolchain | `rust-analyzer` flycheck | Editor runs `cargo check` on save (default `check.command = "check"`) |
| Built-in / first-party toolchain | Cargo `build.warnings` config (stable since Cargo 1.97) | Severity switch: deny lint warnings from local packages without changing fingerprints |
| Built-in / first-party toolchain | Cargo `[lints]` / `[workspace.lints]` table (stable since Cargo 1.74) | Strictness surface for rustc lint levels |
| Built-in / first-party toolchain | `#[expect(lint, reason = "...")]` (stable since Rust 1.81) | Suppression that fails when it stops suppressing anything |
| Established industry standard | `RUSTFLAGS="-D warnings"` (env) or `cargo clippy -- -D warnings` | Pre-1.97 way to make warnings fail CI; still dominant in surveyed CI files |
| Established industry standard | `cargo-hack` (`cargo hack check --each-feature / --feature-powerset`) | Wrapper that type-checks feature combinations |
| Established industry standard | `cargo-watch` | Re-runs `cargo check` on file change (repository archived) |
| Up-and-comer | `bacon` | Background checker/watcher TUI around `cargo check` |
| Up-and-comer | `cargo-all-features` | Feature-combination wrapper, narrower than `cargo-hack` |
| Up-and-comer | rust-analyzer native diagnostics (experimental set default off) | Its own type inference, a second engine that is not rustc |

No Rust tool exists that is "a type checker other than rustc" in the way `ty`, mypy or
pyright are separate from CPython: rustc's type checker is the only authoritative
engine. Every candidate above is either rustc invoked a different way, a severity or
strictness switch, or a wrapper that re-invokes `cargo check`.

**Authoritative sources used and why each counts.**

| Source | Why it is authoritative |
|---|---|
| The Cargo Book, *Continuous Integration* guide, section "Checking for warnings" (`doc/book/src/guide/continuous-integration.md:207-232` in rust-lang/cargo) | Written and maintained by the Cargo team; it is the official recommendation for CI warning policy |
| The Cargo Book, config reference `build.warnings` (`doc/book/src/reference/config.md:471-484`) | The normative definition of the config key |
| The Cargo Book, manifest reference, "The `[lints]` section" (`doc/book/src/reference/manifest.md:532-557`) | Normative definition of the lint table and its `priority` semantics |
| Cargo changelog (`doc/book/src/CHANGELOG.md`, line 399 under "Cargo 1.97 (2026-07-09)"; line 4156 under "Cargo 1.74 (2023-11-16)") | Release record of the Cargo team; dates stabilizations |
| rustc book, *Lint levels* (`src/doc/rustc/src/lints/levels.md` in rust-lang/rust) | Normative definition of allow / expect / warn / force-warn / deny / forbid and `reason` |
| Rust `RELEASES.md` ("Version 1.81.0 (2024-09-05)": stabilize `#[expect]`, RFC 2383) | Release team's record |
| rust-analyzer `crates/rust-analyzer/src/config.rs` (blob `1e7c8257d15b`) | The source of truth for rust-analyzer's defaults; its doc comments generate the user manual |
| Rust project blog, *Rust compiler performance survey 2025 results* (2025-09-10) | Survey run by the Rust compiler performance working group; evidence on how developers type-check (`cargo check`, editor) |
| Rust project blog, *2025 State of Rust Survey Results* (2026-03-02) | The annual community survey run by the Rust Survey team |
| rust-unofficial/patterns, anti-pattern `#![deny(warnings)]` | Widely cited community pattern catalog; used as a lead, confirmed by the Cargo guide's own caveat about new-toolchain warnings |
| Local toolchain output (`rustc -W help`, `cargo clippy --explain`, `cargo help check`) for 1.98.1 | Primary evidence of the shipped behavior |

All rust-lang documents were retrieved as source files through `api.github.com`
(`GET /repos/<o>/<r>/contents/<path>`), one of the prompt's named endpoints; the
rendered pages are listed under `### Sources` for reference.

**Practice evidence: what well-regarded Rust projects do.** Stars are
`stargazers_count` from `GET https://api.github.com/repos/<o>/<r>`; files were read at
the listed blob SHAs through the contents endpoint.

| Project (stars, archived) | Why it is a relevant, well-regarded reference | Type-check gate as practiced | Evidence |
|---|---|---|---|
| rust-lang/cargo (15521, false) | Cargo itself; the team that owns `build.warnings` | No separate check step; `CARGO_BUILD_WARNINGS: deny` at job level with `cargo clippy --workspace --all-targets --no-deps --keep-going`; `cargo hack check --all-targets --rust-version` for the MSRV floor | `.github/workflows/main.yml:79,84,312,331-332` (blob `8ebd281b6008`); `Cargo.toml:130-131` `[workspace.lints.rust] rust_2018_idioms = "warn"` (blob `6d8001085cb9`) |
| astral-sh/uv (90201, false) | Most-starred new-generation Rust CLI; CLI shape matches this template | Gate is clippy: `cargo clippy --workspace --all-targets --all-features --locked -- -D warnings` on Linux and Windows | `.github/workflows/check-lint.yml:127,157`; `Cargo.toml:413-415` `[workspace.lints.rust] unsafe_code = "warn"`, `unreachable_pub = "warn"` (blob `b891425af59f`) |
| astral-sh/ruff (49804, false) | Large, fast-moving Rust CLI + library workspace | Same clippy form with `-D warnings`; `RUSTDOCFLAGS: "-D warnings"` for docs | `.github/workflows/ci.yaml:338,435` (blob `b240f331c039`); `Cargo.toml:262-265` (blob `8d89233e414b`) |
| tokio-rs/axum (27259, false) | The web framework R69 selected; reference for the web member | Clippy with `-- -D warnings --all-targets --all-features`; a separate `cargo hack check --each-feature` job under `RUSTFLAGS: "-D warnings"` | `.github/workflows/CI.yml:30,51-64` (blob `eb64995749fe`); `Cargo.toml:8-14` `rust_2018_idioms = { level = "warn", priority = -1 }` (blob `e7579bfa7fbe`) |
| tokio-rs/tokio (33246, false) | The async runtime R69 selected | Workflow-level `RUSTFLAGS: -Dwarnings`; explicit `cargo check --workspace --tests` steps; `cargo hack` for features | `.github/workflows/ci.yml:14,187-209,240` (blob `4223db720445`) |
| bevyengine/bevy (48401, false) | Large multi-crate workspace | Workflow-level `RUSTFLAGS: "-C debuginfo=0 -D warnings"`; `cargo check` steps for no_std/wasm targets | `.github/workflows/ci.yml:20,186,281` (blob `b4b325e41806`); `Cargo.toml:84-89` (blob `283e36ddb4d5`) |
| BurntSushi/ripgrep (68628, false) | Canonical small Rust CLI | `cargo check` step for an extra target; `RUSTDOCFLAGS: -D warnings` for docs | `.github/workflows/ci.yml:245,270` (blob `4b88a75b9b9d`) |

**Findings from the survey (facts, not yet recommendations).**

1. None of the seven projects runs a job or step named "typecheck". Where warnings are
   gated, the type check happens inside clippy or inside a warnings-denying `cargo check`
   step for an extra target or feature set.
2. Warning denial is done three ways: `-- -D warnings` on clippy (uv, ruff, axum),
   `RUSTFLAGS=-Dwarnings` at workflow level (tokio, bevy), and `CARGO_BUILD_WARNINGS:
   deny` (cargo itself, which the Cargo 1.97 changelog calls "dogfood `build.warnings`",
   line 240). Only the third is what the Cargo guide now recommends.
3. All five manifests read (cargo, uv, ruff, axum, bevy) configure `[workspace.lints.rust]`;
   tokio's and ripgrep's manifests were not read. None of the five uses crate-root
   `#![deny(warnings)]`.
4. `cargo-hack` appears in three of seven (cargo, axum, tokio) for feature or MSRV
   coverage.
5. The compiler performance survey reports `cargo check` as "the most commonly used
   command performed after each code change", and that about 87% of respondents read
   compiler errors mainly from editor inline annotations (blog post lines 142, 157).

**Fit lens.** The template is CLI + library + an off-by-default `web` feature (R69:
`web = ["dep:axum", "dep:tokio"]`, with `otel` and `metrics` nesting on top). The
feature is off by default, so a gate that checks only default features never
type-checks the web tree. That single fact drives the scope and editor-parity choices
below.

### Principles and implementation

**Shared principle** (source: `docs/port/DIVERGENCE-ANALYSIS.md:127-130`, class C for
F105/F107/F108/F110/F112, class A for F106/F113, class D for F111; spec §2, owner
amendment A5): *every change is gated by one CI-authoritative static type check. The
check runs as one named command that is the same locally, in the hook and in CI. The
editor surfaces the same engine's verdicts. Suppressions are named and auditable. The
gate's severity and scope are explicit, not implicit.*

**Agreement level.** Capability plus policy. The three repositories must agree that a
named `typecheck` recipe exists, that it is CI-authoritative, that it covers test code,
that suppressions name their rule, and that the severity rule is written down. The
engine, flags and file layout may differ by ecosystem.

**Essential behaviors and what may vary.**

| Row | Must agree across py / ts / rs | May vary | Rust realization proposed here |
|---|---|---|---|
| F105 engine | One CI-authoritative engine, invoked by a named recipe | Which binary | rustc via `cargo check`; no wrapper |
| F106 hook tier | Tier chosen deliberately, from measured cost | Which tier | pre-commit, justified by measurement below |
| F107 editor ≡ CI | Editor diagnostics come from the gate's engine and scope | Mechanism | rust-analyzer flycheck already runs `cargo check --all-targets`; feature scope must match (coupling to R28) |
| F108 second IDE-only checker | No unexplained second engine | Whether one exists | None; rust-analyzer's native diagnostics are advisory only |
| F110 strictness | Strictness is declared in one committed file | Rule-based vs flag-based | `[workspace.lints.rust]` in root `Cargo.toml`; rustc's type rules need no opt-in |
| F111 suppression | Every suppression names its rule; unknown rule names fail | Syntax | `#[expect(lint, reason = "...")]`; `unknown_lints` and `unfulfilled_lint_expectations` fail the gate |
| F112 severity | The warn-vs-fail rule is explicit and deterministic | Single tier vs two | Single tier in the gate: lint warnings from local packages fail via `build.warnings = "deny"`; editors stay lax |
| F113 scope | Test code is type-checked by the gate | Mechanism | `--all-targets` (lib, bins, `#[cfg(test)]`, `tests/`, examples, benches); doctests excluded — handed to R32 |

**Is the shared pattern still appropriate in Rust?** Partly. py and ts needed a *separate
tool* because their runtimes do not type-check. Rust cannot run code that fails type
checking, so every `cargo build`, `cargo test` and `cargo clippy` already gates on
types. What survives the port is not "add a type checker" but three smaller duties:
(1) give the type check a *named, cheap, attributable* invocation; (2) decide how
*warnings* (the only configurable part of rustc's verdict) are treated; (3) make the
scope explicit so that `#[cfg(test)]`, `tests/` and the off-by-default `web` feature
are included.

**Architectural alternatives compared.**

| Option | What the gate is | Consequence |
|---|---|---|
| A. Named `cargo check` step (recommended) | Justfile `typecheck` = `cargo check --workspace --all-targets --all-features --locked --keep-going` under `CARGO_BUILD_WARNINGS=deny`; the same command runs at pre-commit and as the first ordered step of R11's `check` job | A type error is attributed to a step named `typecheck`; the recipe does not depend on R28's clippy configuration; measured extra cost is one re-check of the three workspace crates (0.58-0.68 s warm on the probe), dependencies shared |
| B. No distinct step; clippy is the gate | `typecheck` recipe exists locally only; CI relies on R11's clippy steps | Matches the surveyed projects (uv, ruff, axum, cargo); one fewer step; but the type-check verdict is coupled to R28's lint policy and a type error is reported under "clippy" |
| C. Wrapper: `cargo hack check --feature-powerset` | Gate type-checks every feature combination | Covers combinations R11 does not; with one additive feature plus two nested ones (`otel`, `metrics` require `web`), R11's feature-off and feature-on steps already cover the realistic combinations; adds a third-party binary |
| D. Build-based gate: `cargo build` / `cargo test --no-run` | Type check as a side effect of codegen | Slower (codegen and link); nothing a check step would miss except monomorphization-time errors, which R11's test and build steps already catch |

Option A is preferred over B on principle-preservation and cost, not on popularity:
the survey shows B is more common. The decisive facts are (a) R11's rule already admits
it ("a check that compiles what check already compiles is an ordered step of check"),
(b) the measured cost is under a second warm, and (c) the named step keeps F105's
"distinct from lint" property that D-015(1) established for ts, without re-inventing a
separate engine. B is the ranked runner-up.

**How the design preserves each principle, and where Rust differs.**

- *One engine for CI and editor (F107, F108).* rust-analyzer's defaults are
  `checkOnSave = true`, `check.command = "check"`, `cargo.allTargets = true`,
  `check.workspace = true` (`config.rs:787,884,891,962`). So the editor already runs the
  gate's engine on the gate's targets. The one gap is features: `cargo.features`
  defaults to the package's default features (`config.rs:847`), and `web` is off by
  default. The editor therefore does not type-check `src/web/` unless
  `rust-analyzer.cargo.features` is `"all"`. This is the Rust analogue of ts's
  `typescript.tsdk` pin (D-032): a one-key editor setting that makes editor ≡ CI hold.
  Whether to commit it is R28's decision (DIVERGENCE-ANALYSIS R28 row: "whether a
  settings.json pin is needed for rust-analyzer"); this report supplies the requirement.
  Toolchain parity (editor and CI using the same rustc) depends on a toolchain pin,
  which R42's area owns; no toolchain-pin parameter is registered in this run's inputs.
- *No second checker (F108).* rust-analyzer's native diagnostics (`diagnostics.enable =
  true`, experimental set off, `config.rs:719,723`) come from its own inference engine,
  not rustc. They are advisory; the gate never runs them. py's pyright role therefore
  dissolves, as it did for ts.
- *Strictness (F110).* rustc's type rules have no opt-in strict mode: there is no `any`,
  no implicit numeric conversion, no unchecked index type. The only configurable part is
  lint levels, declared in `[workspace.lints.rust]`. This report proposes one entry
  (`rust_2018_idioms` at `warn`, `priority = -1`, used by cargo and axum). It makes
  hidden lifetime parameters in types visible, which is type-surface clarity. Other
  entries belong to their owners: `unsafe_code` (R06), `unreachable_pub` and
  `missing_docs` (R04 and the docs items).
- *Severity (F112).* Cargo's guide: "Customarily, projects want to be 'warnings clean' on
  official branches while being lax for local development. `build.warnings = "deny"` can
  be used to fail a CI job if warnings are present" (`continuous-integration.md:209-210`).
  Measured: switching `CARGO_BUILD_WARNINGS=deny` on and off recompiled nothing and
  replayed cached warnings as a failure. Switching `RUSTFLAGS=-Dwarnings` on recompiled
  every dependency once (both crates in the probe), after which both artifact sets
  coexisted (no thrash) at the cost of duplicate artifacts. py's reason for a
  non-failing warning tier ("a dependency `deprecated` warning must not fail every
  fork's CI", `pyproject.toml:244-246`) does not transfer. With `--locked`, a
  dependency can change only through a pull request that edits `Cargo.lock`, so a new
  deprecation fails exactly that pull request and no other. The remaining spontaneous-failure
  source is a new stable toolchain adding warnings. Cargo's guide names it and
  recommends pinning the toolchain (`continuous-integration.md:227-228`); that is R42's
  lane.
- *Suppression (F111).* Rust's attribute syntax already forces a named lint: bare
  `#[allow]` is a hard error ("malformed `allow` attribute input"), and `#[allow()]`
  warns "unused attribute". A misspelled lint name warns `unknown_lints`, and an
  `#[expect]` that no longer suppresses anything warns `unfulfilled_lint_expectations`.
  Under `build.warnings = "deny"` both fail the gate, reproducing ty's
  `ignore-comment-unknown-rule` and exceeding it (ty has no unfulfilled-ignore check in
  the cited config). The gap: `#![allow(warnings)]` names the `warnings` group and
  silences everything; it passed the denying gate silently in the probe. rustc has no lint
  against it. The clippy lints `allow_attributes` and `allow_attributes_without_reason`
  exist in clippy 0.1.98 (`cargo clippy --explain`), but enabling them is R28's call.
- *Scope (F113).* `cargo check` without flags checks lib and bins only; `--all-targets`
  adds `#[cfg(test)]` units, `tests/`, examples and benches. Probe: an `E0308` in
  `tests/it.rs` and one in a `#[cfg(test)]` module were both invisible to plain `cargo
  check` and both reported under `--all-targets`. Doctests are outside every `cargo
  check` form: a doctest containing `let s: u32 = "doctest type error";` was not reported by
  `cargo check` (plain run: exit 0; denying run: only the unused-variable warning). They are type-checked only by `cargo test --doc` (R32's lane, and
  R11's test steps run it).
- *Hook tier (F106).* Measured on the probe workspace (76 packages locked: clap, axum,
  tokio, serde): cold `cargo check --workspace --all-targets --all-features --locked`
  8.72 s and 11.46 s (two runs); warm no-op 0.13-0.17 s; after editing the leaf library
  crate 0.18-0.39 s; after editing the web crate 0.27-0.34 s. py's reason for
  pre-push ("full-tree check, too slow per commit", `lefthook.yml:168-173` at py
  `b55b8c2`) does not hold for warm incremental `cargo check`. One Rust-specific cost
  applies: rust-analyzer and a hook `cargo check` share `target/` and its build lock
  (`cargo.targetDir` defaults to shared, `config.rs:878`; the survey post links the
  rust-analyzer FAQ entry "rust-analyzer and cargo compete over the build lock"), so
  a commit can wait for an in-flight editor check.

**Minimal realistic example (proposed integration, not yet executed in the template).**

Root `Cargo.toml` (strictness surface, shared with R28's `[workspace.lints.clippy]`):

```toml
[workspace.lints.rust]
rust_2018_idioms = { level = "warn", priority = -1 }
```

Each member `Cargo.toml`:

```toml
[lints]
workspace = true
```

`Justfile` (recipe name and alias mirror ts `Justfile:135-142`):

```just
# Run type checker (cargo check; lint warnings from local packages fail)
[group('dev')]
typecheck:
    CARGO_BUILD_WARNINGS=deny cargo check --workspace --all-targets --all-features --locked --keep-going

alias tc := typecheck
```

`lefthook.yml` (R42 forbids a runner prefix in lefthook jobs, so the job repeats the
cargo command rather than calling `just`):

```yaml
pre-commit:
  jobs:
    - name: typecheck
      env:
        CARGO_BUILD_WARNINGS: deny
      run: cargo check --workspace --all-targets --all-features --locked --keep-going
```

R11 `check` job, first ordered step (step-level env so that this item does not decide
the severity of clippy, test or doc steps, which other items own):

```yaml
      - name: typecheck
        if: ${{ !cancelled() }}
        env:
          CARGO_BUILD_WARNINGS: deny
        run: cargo check --workspace --all-targets --all-features --locked --keep-going
```

**Executed checks (this leg, on the host and toolchains named at the top).**

| # | Check | Command (abridged) | Observed |
|---|---|---|---|
| E1 | `--all-targets` scope | `cargo check` vs `cargo check --all-targets` on a crate with an `E0308` in `#[cfg(test)]` and in `tests/it.rs` | plain: finished with 1 warning; `--all-targets`: 2 × `error[E0308]`, "could not compile `demo` (test "it")" and "(lib test)" |
| E2 | Doctest excluded | `cargo check` and `CARGO_BUILD_WARNINGS=deny cargo check` with a type error inside a `///` code block | plain: exit 0; denying: fails only on the unused-variable warning; doctest error reported by neither |
| E3 | `build.warnings` availability | `CARGO_BUILD_WARNINGS=deny` per toolchain | 1.96.0: exit 0, key silently ignored (cargo 1.96 lists it as `-Z warnings`); 1.97.1: exit 101 "warnings are denied by `build.warnings` configuration"; 1.98.1: exit 101 |
| E4 | Config-file form on the floor | `.cargo/config.toml` `[build] warnings = "deny"` under 1.96.0 | exit 0, no diagnostic about the key; under 1.97.1 denied |
| E5 | Cache effect | plain → `CARGO_BUILD_WARNINGS=deny` → `RUSTFLAGS=-Dwarnings` → plain → `RUSTFLAGS` | build.warnings: nothing re-checked, failure replayed; RUSTFLAGS first time: `Checking itoa`, `Checking memchr`, `Checking demo`; plain again: no rebuild; RUSTFLAGS again: only `demo` |
| E6 | Suppression behavior | `#[allow(unused_variabels)]`, `#[expect(dead_code, reason = "probe")]` on an exported `pub fn`, fulfilled `#[expect(unused_variables)]` | "unknown lint", "this lint expectation is unfulfilled", gate failed; the fulfilled expect was silent |
| E7 | Malformed suppressions | `#[allow]`, `#[allow()]` | `error: malformed \`allow\` attribute input`; `warning: unused attribute` |
| E8 | Blanket suppression | `#![allow(warnings)]` + unused variable, gate on | `Finished`, exit 0 — gap confirmed |
| E9 | Timing | probe workspace `bcore` + `cli` (clap 4) + `web` (axum 0.8, tokio 1 full, serde), 76 packages, `--workspace --all-targets --all-features --locked` | cold 8.72 s / 11.46 s; no-op 0.13 / 0.17 s; leaf edit 0.18 / 0.39 s; web edit 0.27 / 0.34 s; 72 crates checked cold (69 dependencies); `target/` 75 MB |
| E10 | check-then-clippy reuse | `cargo clippy` after `cargo check`, same flags | 0.58 / 0.68 s, re-checked 3 workspace crates, 0 dependencies |
| E11 | clippy catches type errors | `fn _bad() -> u32 { "x" }` in `cli`, `cargo clippy` | `error[E0308]: mismatched types` |
| E12 | Floor compatibility | same probe workspace under `rustup run 1.96.0 cargo check` | cold `Finished` in 12.56 s |
| E13 | Proposed lints table | `rust_2018_idioms = { level = "warn", priority = -1 }` + `fn mk(s: &str) -> Wrap` | 1.98.1 gate: "hidden lifetime parameters in types are deprecated", exit 101; 1.96.0: same warnings, exit 0 (not denied); fixed to `Wrap<'_>`: exit 0 |

**Proposed checks (not executed in the template, which does not yet exist):** listed
under `### Validation strategy`.

**BASELINE-REVIEW:** none. The ledger classifications for F105-F113 hold. One
citation-maintenance note, which does not change any classification: the prompt's line
numbers have drifted at the source repos' current heads. py at `b55b8c2` (2026-09-22):
the `ty check` recipe line is `Justfile:244`, not 237, and the hook `run:` line is
`lefthook.yml:173`, not 166-167; `pyproject.toml` rules are at `:252-262`. ts at
`e5100b4` (2026-09-15): the typecheck hook is `lefthook.yml:66-67`, not 60-61; ts
`Justfile:137` is unchanged.

### Recommendation

One stack, all first-party toolchain features, no third-party crate or binary:

1. **Engine:** rustc via `cargo check` — no wrapper, no second checker.
2. **Invocation and scope:** `cargo check --workspace --all-targets --all-features
   --locked --keep-going`, as Justfile recipe `typecheck` (alias `tc`), as the
   first ordered step of R11's `check` job, and as a lefthook pre-commit job.
   Doctests stay with R32's `cargo test`.
3. **Severity:** a single failing tier in the gate through Cargo's `build.warnings =
   "deny"`, set as `CARGO_BUILD_WARNINGS=deny` on the recipe, the hook job and the CI
   step. It is never set in a committed `.cargo/config.toml` or as `#![deny(warnings)]`,
   so editor and ad-hoc builds stay lax. It needs Cargo ≥ 1.97; on the 1.96 floor it is
   silently inert, which is acceptable because the floor job proves compilation, not
   warning-cleanliness.
4. **Strictness surface:** `[workspace.lints.rust]` in the root `Cargo.toml`, inherited by
   every member via `[lints] workspace = true`. This item contributes
   `rust_2018_idioms = { level = "warn", priority = -1 }`.
5. **Suppression discipline:** `#[expect(<lint>, reason = "...")]` is the house form;
   `#[allow]` is reserved for lints that fire conditionally (for example, per-feature
   or per-target). Unknown names and unfulfilled expectations fail through step 3.
   `#![allow(warnings)]` is forbidden by review convention; mechanical enforcement is
   handed to R28 (clippy `allow_attributes_without_reason`).
6. **Hook tier:** pre-commit, as ts does. The job is the same command as CI.

### Members

#### Type-check engine (rustc via `cargo check`)

##### Landscape

Candidates: `cargo check` (metadata-only rustc), `cargo build`, `cargo clippy`
(rustc + lints), rust-analyzer flycheck (runs `cargo check`), rust-analyzer native
diagnostics (a separate inference engine), and wrappers that re-invoke `cargo check`
(`cargo-hack`, `cargo-all-features`, `bacon`, `cargo-watch`). Only rustc is an
authoritative type checker; everything else is rustc invoked differently or advisory.

##### Principles and implementation

Principle served: one CI-authoritative engine, the same in editor, hook and CI (F105,
F107, F108). `cargo check` runs the full front end (name resolution, trait solving,
borrow checking, lints) and stops before codegen, so it is the cheapest complete
verdict. rust-analyzer calls the same command on save by default
(`check.command = "check"`), which gives ts's single-engine property (F107) without a
second checker (F108). Crate figures: **inapplicable** — rustc and Cargo ship with the
toolchain through rustup, not crates.io, so the downloads, release, advisory and
adopter rows of the figure table do not exist for them. GitHub figures instead:
rust-lang/cargo 15521 stars, not archived; rust-lang/rust-analyzer 16877 stars, not
archived, pushed 2026-09-26, 1696 open issues; rust-lang/rust-clippy 13536 stars,
2506 open issues (`GET https://api.github.com/repos/<o>/<r>`,
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`).

##### Dominant choice

`cargo check`. The compiler performance survey reports it as the most commonly used
command after each code change (blog lines 142-155); rust-analyzer defaults to it.

##### Qualified shortlist

1. `cargo check` — passes every gate: toolchain license (MIT OR Apache-2.0), available
   on every toolchain including the 1.96 floor (E12), no RustSec advisory surface,
   ubuntu-latest and macos-latest are Tier 1 hosts, no features or runtime coupling,
   no codegen so the lowest compile cost.
2. `cargo clippy` — same engine plus lints; passes the same gates; owned by R28.

##### Excluded by gate

- rust-analyzer native diagnostics as a gate: it is a different inference engine with
  experimental diagnostics off by default (`config.rs:719-723`). It fails the implicit
  gate "is the authoritative engine"; it stays an editor aid.
- `cargo build` as the *type-check* gate: passes the six gates. It is excluded on fit,
  not by a gate: codegen and linking add cost that type-checking does not need, and R11
  already has a build step.

##### Up-and-comers

rust-analyzer's integration of the new trait solver (survey post, line 159) will narrow
the gap between its native diagnostics and rustc; it does not change which engine is
authoritative.

##### Fit for this template

CLI, library and web service are all ordinary Cargo targets, so one `cargo check`
invocation covers all three shapes. Nothing in the template needs a non-Cargo build.

##### Recommendation

rustc via `cargo check`, invoked by the Justfile recipe `typecheck`, with no wrapper
and no second checker.

##### Ranked runner-up

`cargo clippy` as the only gate (Option B in `### Principles and implementation`):
the surveyed majority (uv, ruff, axum, cargo) type-check only through clippy. It loses
here because it couples the type verdict to R28's lint policy and attributes type
errors to a lint step.

##### Tradeoffs

A distinct check step re-checks the workspace crates once more when clippy follows
(E10: 0.58-0.68 s warm, dependencies shared). In exchange, attribution is clearer and
the recipe is independent of clippy configuration. Monomorphization-time errors are
found only by codegen, and R11's test and build steps cover them.

##### Parameters

assumes `rust-edition = 2024`; assumes `msrv-policy` (floor 1.96 while stable is 1.98);
owns nothing.

##### Migration implications

Add the `typecheck` recipe and `tc` alias to `Justfile`. py drops nothing. ts drops
nothing. py's pyright IDE-only role has no Rust counterpart to create.

##### Validation strategy

Proposed: insert `fn _bad() -> u32 { "x" }` into each workspace member in turn and
confirm `just typecheck` exits non-zero with `E0308`. Executed analogue: E1 and E11.

##### Confidence & re-verify trigger

High. Re-verify if Cargo unifies the `check` and `build` caches (survey post line
155 names the open issue), which could change the cost trade-off against Option D.

##### Sources

- rust-analyzer `crates/rust-analyzer/src/config.rs` lines 719-723, 787, 847, 878, 884-891, 962 (blob `1e7c8257d15b`), via `GET https://api.github.com/repos/rust-lang/rust-analyzer/contents/crates/rust-analyzer/src/config.rs`, 2026-09-26.
- *Rust compiler performance survey 2025 results*, https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ (source `content/rust-compiler-performance-survey-2025-results/index.md`), 2026-09-26.
- `cargo help check` (1.98.1): "Check all targets, including unit tests: cargo check --all-targets --profile=test", local, 2026-09-26.
- Executed checks E1, E11, E12 (this report).

#### Gate invocation and scope (`--workspace --all-targets --all-features --locked --keep-going`)

##### Landscape

Scope selectors: plain `cargo check` (lib + bins), `--all-targets`, `--tests`,
`--workspace`, `--all-features` or `--features web`, `--no-default-features`, and
wrappers that enumerate feature sets (`cargo-hack`, `cargo-all-features`). Doctests
are reachable only through `cargo test --doc`.

##### Principles and implementation

Principle served: test code is inside the gate (F113, ts D-013(4), which fixed py's
"under-checking of tests"). `--all-targets` adds `#[cfg(test)]` units, `tests/`,
examples and benches (E1). `--all-features` is required because R69 makes `web`
off-by-default: without it, `src/web/` and the web integration tests (file-level
`#![cfg(feature = "web")]`) are never type-checked. `--locked` matches R11 ("every cargo
command carrying `--locked`"). `--keep-going` reports every failing crate rather than
stopping at the first, as the Cargo guide's example does. Crate figures for the
built-in selectors: **inapplicable** (Cargo flags). Wrapper figures below.

| Figure (endpoint, 2026-09-26) | cargo-hack | cargo-all-features |
|---|---|---|
| 90-day downloads (`GET https://crates.io/api/v1/crates/<name>`, `crate.recent_downloads`) | 218323 | 57261 |
| All-time downloads (same, `crate.downloads`) | 1910484 | 716473 |
| Last release (`GET https://crates.io/api/v1/crates/<name>/versions`, newest non-yanked by `created_at`) | 0.6.45, 2026-05-30 | 1.12.0, 2025-11-27 |
| Declared `rust_version` | 1.85 | none declared |
| License (crates.io) | Apache-2.0 OR MIT | MIT/Apache-2.0 |
| Stars, archived, pushed (`GET https://api.github.com/repos/<o>/<r>`) | 863, false, 2026-09-02 | 188, false, 2025-11-27 |
| Open issues (`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, `total_count`) | 36 | 27 |
| Issue responsiveness (10 most recently opened issues) | 1 of 10 opened by the maintainer, excluded; of 9 others, 6 answered by `taiki-e`, median 0.11 days to first response (0.01, 0.04, 0.04, 0.18, 0.21, 4.1 days); 3 unanswered (#288, #286, #282) | not sampled (gap) |
| Advisories (`https://rustsec.org/packages/<name>.html`) | HTTP 404: no advisory page, so no advisories | HTTP 404: none |
| Adopters | rust-lang/cargo `main.yml:331-332`; tokio-rs/axum `CI.yml:62-64`; tokio-rs/tokio `ci.yml:187-199` | none found in the seven surveyed projects |
| Maintenance state | active | stable-quiet (10 months since release; no concrete at-risk signal) |

##### Dominant choice

`cargo check --workspace --all-targets --all-features`. It is the flag set every
surveyed clippy gate uses (uv `check-lint.yml:127`, ruff `ci.yaml:338`, axum
`CI.yml:30`), with `check` instead of `clippy`.

##### Qualified shortlist

1. `--workspace --all-targets --all-features --locked --keep-going` — passes all gates;
   no third-party code.
2. `cargo-hack` `check --feature-powerset --all-targets` — gates: license ✓, tool MSRV
   1.85 ≤ 1.96 ✓, no advisory ✓, `unsafe` posture not inspected in this leg (gap),
   OS support not verified in this leg beyond adopters running it on ubuntu (gap),
   binary tool so no default-features or runtime coupling, installed as a prebuilt
   binary via `taiki-e/install-action` in all three adopters.

##### Excluded by gate

- `cargo-all-features`: no gate failure established, but it is dominated by `cargo-hack`
  (fewer adopters, smaller feature set) and its responsiveness was not sampled. Not
  shortlisted.
- Plain `cargo check` / `--lib`-only scope: fails the F113 acceptance criterion (E1).

##### Up-and-comers

None found that change the scope question. Cargo's unstable `-Z hint-msrv` (listed in
`cargo -Zhelp` on 1.98.1) passes `rust-version` to rustc for lints; it does not affect
scope.

##### Fit for this template

With one additive feature (`web`) and two features that require it (`otel`, `metrics`),
the realistic combinations are "none" and "all". R11 already type-checks "none" (clippy
feature off, no-default-features facade check). `--all-features` covers "all". A
powerset wrapper adds no realistic combination here.

##### Recommendation

`cargo check --workspace --all-targets --all-features --locked --keep-going`. Doctests
are explicitly out of this gate and in R32's `cargo test`.

##### Ranked runner-up

`cargo hack check --feature-powerset --all-targets --locked`, to adopt if a second
independent top-level feature appears, because then "none" and "all" no longer cover
pairwise combinations.

##### Tradeoffs

`--all-features` checks `otel` and `metrics` code in the same pass, so a type error in
those trees fails `typecheck` even if R11's clippy "feature on" step uses only
`--features web`. That is intended. It also means the editor (default features) and
the gate differ unless rust-analyzer is configured with `cargo.features = "all"` — see
the engine member and R28.

##### Parameters

assumes `web-extra-surface` (R69: `web` off by default, `otel`/`metrics` require `web`);
assumes `ci-job-structure` (R11: `--locked` on every cargo command).

##### Migration implications

The recipe body above. ts's `tsconfig.json:32` `include` of `tests/**/*.ts` is the
recorded analogue; py's `src/`-only scope (`Justfile:244`) is the divergence ts
already fixed. Follow-on for py (not changed here): widen `ty check` to `tests/`.

##### Validation strategy

Proposed, in the template: plant `E0308` in (a) `#[cfg(test)]` in the library crate,
(b) a file under `tests/`, (c) `src/web/` behind `web`, (d) an example; each must fail
`just typecheck`. Executed analogue: E1 for (a) and (b); (c) and (d) not executed.

##### Confidence & re-verify trigger

High for `--all-targets`; medium for `--all-features` (depends on R69's feature set
staying additive). Re-verify when a feature is added that does not require `web`.

##### Sources

- `cargo help check` (1.98.1), local, 2026-09-26.
- crates.io and GitHub endpoints as named in the figure table, 2026-09-26.
- `https://rustsec.org/packages/cargo-hack.html`, `https://rustsec.org/packages/cargo-all-features.html` (HTTP 404), 2026-09-26.
- `taiki-e/cargo-hack` issues #309, #297, #296, #290, #288, #287, #286, #285, #284, #282 via `GET https://api.github.com/repos/taiki-e/cargo-hack/issues?state=all&sort=created&direction=desc` and `.../issues/<n>/comments`, 2026-09-26.
- Adopter files: rust-lang/cargo `.github/workflows/main.yml` (blob `8ebd281b6008`), tokio-rs/axum `.github/workflows/CI.yml` (blob `eb64995749fe`), tokio-rs/tokio `.github/workflows/ci.yml` (blob `4223db720445`), 2026-09-26.
- `research/runs/R30/2026-09-26T190200Z-c5c1105074c1/inputs/PARAMETERS.md` (R69 `web-extra-surface`).

#### Warning severity tier (`build.warnings = "deny"`)

##### Landscape

Mechanisms that make rustc lint warnings fail a gate: `CARGO_BUILD_WARNINGS=deny` /
`build.warnings` (Cargo ≥ 1.97); `RUSTFLAGS="-D warnings"`; `cargo clippy -- -D
warnings`; crate-root `#![deny(warnings)]`; `[lints.rust] warnings = "deny"` in the
manifest. Informational tiers: `warn` (default), `--force-warn`.

##### Principles and implementation

Principle served: the warn-versus-fail rule is explicit and deterministic (F112). The
Cargo team's guide recommends `build.warnings = "deny"` in CI and lax local builds.
The changelog describes it as "replacing `-Dwarnings`" (Cargo 1.97, line 399).
Measured advantages over `RUSTFLAGS` (E5): no fingerprint change, so no dependency
re-check and no duplicate artifacts; it affects only local packages, not dependencies.
Crate figures: **inapplicable** — a Cargo configuration key.

##### Dominant choice

By current usage, `-D warnings` (clippy argument or `RUSTFLAGS`): five of seven
surveyed projects. By current authoritative guidance, `build.warnings = "deny"`: the
Cargo guide and cargo's own CI.

##### Qualified shortlist

1. `CARGO_BUILD_WARNINGS=deny` scoped to the recipe, hook job and CI step — gates: part
   of Cargo (license ✓), **stable only from 1.97**: silently inert on the 1.96 floor
   (E3, E4) — see Tradeoffs; no advisory surface; both OSes; no features; zero extra
   compile cost (E5).
2. `RUSTFLAGS="-D warnings"` on the same three places — works on every toolchain; costs
   one full dependency re-check on first use and keeps a second artifact set (E5); it
   also overrides any `build.rustflags` a contributor sets.

##### Excluded by gate

- `#![deny(warnings)]` in source and `[lints.rust] warnings = "deny"` in the manifest:
  both deny for every consumer and every local build, so a new toolchain's lint breaks
  downstream builds and local iteration. This is the documented anti-pattern
  (rust-unofficial/patterns, `deny-warnings.md`) and contradicts the Cargo guide's
  "lax for local development".
- A committed `.cargo/config.toml` with `[build] warnings = "deny"`: loads for every
  local build and every rust-analyzer check, removing the lax local tier. It does not
  break the 1.96 floor (E4: silently ignored), but it fails fit.

##### Up-and-comers

`[lints.cargo]` (`-Z cargo-lints`, unstable on 1.98.1) will put Cargo's own lints under
`build.warnings` too (changelog line 293).

##### Fit for this template

A template is forked by users who will not track toolchain releases, so the gate must
not fail spontaneously. `--locked` confines dependency-driven warnings, such as a new
`deprecated`, to the pull request that changes `Cargo.lock`. The residual spontaneous
source is a new stable rustc; the Cargo guide's answer is a pinned toolchain with an
automated bump pull request, which is R42's decision.

##### Recommendation

Single failing tier in the gate via `CARGO_BUILD_WARNINGS=deny` on the `typecheck`
recipe, the pre-commit job and the CI `typecheck` step. Lax (`warn`) everywhere else.

##### Ranked runner-up

`RUSTFLAGS="-D warnings"` on the same three places, if a gate must deny warnings on a
pre-1.97 toolchain.

##### Tradeoffs

- On the 1.96 floor the variable has no effect, and there is no diagnostic. This does
  not weaken the gate: the gate runs on current stable in R11's `check` job, and
  R11's `msrv-floor` job's purpose is to prove the declared floor compiles, not that it
  is warning-clean. A contributor running `just typecheck` on a 1.96 toolchain would
  get a lax result without notice. This disappears when the declared `rust-version`
  reaches 1.97.
- No per-lint informational tier: with `deny`, every lint warning fails. py's
  `error-on-warning = false` has no counterpart in this stack by design; a lint that
  must only inform is set to `allow` in `[workspace.lints.rust]` instead. Whether
  `--force-warn` escapes `build.warnings` was not tested (gap).
- Whether `build.warnings` applies to rustdoc lints was not tested (gap); it matters
  only if another item puts the variable on R11's doc step.

##### Parameters

assumes `msrv-policy` (floor 1.96 today; the key needs 1.97); no `CONFLICT:` — the
policy need not change.

##### Migration implications

Three `CARGO_BUILD_WARNINGS=deny` placements (recipe, hook job env, CI step env). py's
`[tool.ty.terminal] error-on-warning = false` (`pyproject.toml:261-262`) and ts's
implicit single tier stay; the follow-on rationale for py: its lockfile plays the same
role as `--locked` here, so a single tier may be viable there as well.

##### Validation strategy

Executed: E3, E4, E5, E13. Proposed: in the template, add an unused variable in each
member and confirm `just typecheck` exits 101 with "warnings are denied by
`build.warnings` configuration", and plain `cargo check` exits 0.

##### Confidence & re-verify trigger

High on 1.97+. Re-verify when the declared `rust-version` rises to ≥ 1.97 (then the
floor also denies) and if R42 leaves the CI toolchain floating (spontaneous new-lint
failures become possible).

##### Sources

- The Cargo Book, *Continuous Integration*, "Checking for warnings", https://doc.rust-lang.org/cargo/guide/continuous-integration.html#checking-for-warnings (source `doc/book/src/guide/continuous-integration.md:207-232`), 2026-09-26.
- The Cargo Book, config `build.warnings`, https://doc.rust-lang.org/cargo/reference/config.html#buildwarnings (source `doc/book/src/reference/config.md:471-484`), 2026-09-26.
- Cargo changelog, Cargo 1.97 (2026-07-09) "Stabilize `build.warnings` config", https://doc.rust-lang.org/cargo/CHANGELOG.html (source `doc/book/src/CHANGELOG.md:394-402`), 2026-09-26.
- rust-unofficial/patterns, `src/anti_patterns/deny-warnings.md`, via `api.github.com`, 2026-09-26.
- py `pyproject.toml:244-262` at `b55b8c2`.
- Executed checks E3, E4, E5, E13.

#### Strictness surface (`[workspace.lints.rust]`)

##### Landscape

Places to declare rustc lint levels: `[workspace.lints.rust]` + `[lints] workspace =
true` (Cargo ≥ 1.74); per-package `[lints.rust]`; crate-root `#![warn(...)]` /
`#![deny(...)]` attributes; `RUSTFLAGS` / `build.rustflags`. The lints in question are
rustc's allow-by-default set (for example `rust_2018_idioms`, `unused_qualifications`,
`missing_debug_implementations`, `unreachable_pub`, `unsafe_code`; levels from `rustc
-W help` on 1.98.1).

##### Principles and implementation

Principle served: strictness is declared in one committed file (F110). rustc's type
rules are not configurable, so "type-check strictness" in Rust is only lint levels. The
workspace table is inherited by every member, applies to every target, and is not
applied to dependencies. Cargo's `priority` field orders groups below individual lints
(`manifest.md:553-557`). Crate figures: **inapplicable** — Cargo manifest feature.

##### Dominant choice

`[workspace.lints.rust]`: all five surveyed manifests (cargo `Cargo.toml:130`, uv
`:413`, ruff `:262`, axum `:8`, bevy `:84`); none uses crate-root deny attributes.

##### Qualified shortlist

1. `[workspace.lints.rust]` — stable since 1.74, far below the 1.96 floor; E13 shows
   identical warnings on 1.96 and 1.98.1.
2. Crate-root attributes — work, but must be repeated per crate root and per
   integration-test crate (each `tests/*.rs` is its own crate), so they drift.

##### Excluded by gate

- `RUSTFLAGS` / `build.rustflags` for lint levels: applies to dependencies too, where
  `--cap-lints` then hides it, and it changes fingerprints (E5). Excluded on fit.
- Lints owned elsewhere, excluded from *this item's* entries: `unsafe_code` (R06),
  `unreachable_pub` / `missing_docs` (R04 and the documentation items), every
  `clippy::` lint (R28).

##### Up-and-comers

`[lints.cargo]` (unstable). `rust-analyzer.toml` project config (not assessed here) may
later give a non-`.vscode` place for the editor feature setting.

##### Fit for this template

Three crates (library, CLI, web) share one policy; the workspace table states it once.

##### Recommendation

Root `Cargo.toml`: `[workspace.lints.rust]` with
`rust_2018_idioms = { level = "warn", priority = -1 }`; every member `[lints] workspace =
true`. Other items append their own entries to the same table.

##### Ranked runner-up

An empty `[workspace.lints.rust]` table (only the inheritance wiring). This is
defensible because edition 2024 defaults are already strict; `rust_2018_idioms` adds
only `elided_lifetimes_in_paths`, `explicit_outlives_requirements` and
`unused_extern_crates` beyond defaults.

##### Tradeoffs

`elided_lifetimes_in_paths` asks for `Wrap<'_>` instead of `Wrap` in signatures (E13),
which is a small amount of churn in exchange for borrowed types being visible at the
type level. `priority = -1` is required so that a later individual lint can override
the group.

##### Parameters

assumes `rust-edition = 2024`; owns nothing.

##### Migration implications

Root `Cargo.toml` table plus one `[lints]` block per member. ts's `tsconfig.json:11-18`
flag union and py's `[tool.ty.rules]` (`pyproject.toml:252-259`) are the counterparts.

##### Validation strategy

Executed: E13 on 1.96.0 and 1.98.1. Proposed: `cargo metadata --format-version 1 --no-deps`
and assert every member reports inherited lints — or simpler, plant `fn f(s: &str) ->
Wrap` in each member and confirm `just typecheck` fails.

##### Confidence & re-verify trigger

High for the mechanism; medium for the single entry (it is a taste call with cargo and
axum as precedent). Re-verify when a new edition changes lint defaults.

##### Sources

- The Cargo Book, "The `[lints]` section", https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section (source `doc/book/src/reference/manifest.md:532-557`), 2026-09-26.
- Cargo changelog, Cargo 1.74 (2023-11-16), "The `[lints]` table has been stabilized" (source `CHANGELOG.md:4156`), 2026-09-26.
- `rustc -W help` (1.98.1), local, 2026-09-26.
- Adopter manifests: cargo (blob `6d8001085cb9`), uv (blob `b891425af59f`), ruff (blob `8d89233e414b`), axum (blob `e7579bfa7fbe`), bevy (blob `283e36ddb4d5`), 2026-09-26.

#### Suppression discipline (`#[expect(lint, reason = "...")]`)

##### Landscape

rustc suppression forms: `#[allow(lint)]`, `#[expect(lint)]` (Rust ≥ 1.81), both with
optional `reason = "..."`; group forms such as `#[allow(unused)]` and
`#![allow(warnings)]`. Enforcement lints: rustc `unknown_lints` and
`unfulfilled_lint_expectations` (both warn by default); clippy `allow_attributes`,
`allow_attributes_without_reason` (restriction group, R28's surface).

##### Principles and implementation

Principle served: every suppression names its rule; unknown names fail (F111, py
`pyproject.toml:254-256`). Rust gets most of this from syntax and default lints (E6,
E7): bare `#[allow]` is an error, a misspelled name warns `unknown_lints`, and an
`#[expect]` that suppresses nothing warns `unfulfilled_lint_expectations`. With the
severity member's `deny`, both warnings fail the gate. The one gap is group-level
blanket suppression: `#![allow(warnings)]` passed the gate (E8). Crate figures:
**inapplicable** — language attributes.

##### Dominant choice

`#[allow(lint)]` by volume (older than `#[expect]`); `#[expect(lint, reason)]` is the form
the rustc book presents as the checkable one (`levels.md:37-69`).

##### Qualified shortlist

1. `#[expect(lint, reason = "...")]` — stable since 1.81 (below the 1.96 floor).
2. `#[allow(lint, reason = "...")]` — needed where a lint fires only under some features
   or targets, where `#[expect]` would be unfulfilled in the other configurations.

##### Excluded by gate

`#![allow(warnings)]` and other whole-crate group allows: they defeat the gate
silently (E8).

##### Up-and-comers

None beyond clippy's two restriction lints, which already exist.

##### Fit for this template

The template's feature split makes `#[allow]` necessary in a few places (code under
`#[cfg(feature = "web")]` that is only used when the feature is on), so a rule of
"`#[expect]` only" would be wrong here; "`#[expect]` by default, `#[allow]` for
conditional lints, `reason` always" fits.

##### Recommendation

House rule: `#[expect(<lint>, reason = "...")]`; `#[allow(<lint>, reason = "...")]` only
where the lint is configuration-dependent; never `allow(warnings)`. Mechanical
enforcement of `reason` and of `expect`-over-`allow` is a clippy configuration choice
handed to R28 (`clippy::allow_attributes_without_reason`). Not a `CONFLICT:` — R28's
value is not registered.

##### Ranked runner-up

No written rule, relying on syntax (named lints) plus `unknown_lints` and
`unfulfilled_lint_expectations` alone. This covers most of py's discipline without
any configuration.

##### Tradeoffs

`reason` strings cost a few words per suppression and make review easier. The
blanket-`allow(warnings)` gap has no rustc-level fix; closing it needs review
convention or a text check in hygiene (R40's area).

##### Parameters

None owned or assumed beyond the fixed parameters.

##### Migration implications

A short "Suppressing a lint" paragraph in `CONTRIBUTING.md`. For ts (follow-on, not
changed here): the recorded gap is that it has no `@ts-expect-error` convention; the Rust
design supports adopting "expect-style, reason required" there too.

##### Validation strategy

Executed: E6, E7, E8. Proposed: in the template, a deliberately misspelled
`#[expect(unused_variabels)]` must fail `just typecheck`.

##### Confidence & re-verify trigger

High. Re-verify if rustc adds a lint against `allow(warnings)` or if R28 declines the
clippy enforcement lints.

##### Sources

- rustc book, *Lint levels*, https://doc.rust-lang.org/rustc/lints/levels.html (source `src/doc/rustc/src/lints/levels.md`, `expect` at 37-69, `reason` at 278), 2026-09-26.
- Rust `RELEASES.md`, Version 1.81.0 (2024-09-05): "Stabilize `#[expect]` for lints (RFC 2383)", 2026-09-26.
- `cargo clippy --explain allow_attributes` and `allow_attributes_without_reason` (clippy 0.1.98), local, 2026-09-26.
- Executed checks E6, E7, E8.

#### Hook-tier placement (lefthook pre-commit)

##### Landscape

Tiers available: pre-commit (every commit), pre-push, CI only. A background
alternative is continuous checking in the editor (rust-analyzer flycheck) or in a
watcher (`bacon`; `cargo-watch`, archived). Hook manager choice is R37's.

| Figure (endpoint, 2026-09-26) | bacon | cargo-watch |
|---|---|---|
| 90-day downloads (`crate.recent_downloads`) | 22743 | 183438 |
| All-time downloads (`crate.downloads`) | 332276 | 2004578 |
| Last release (newest non-yanked by `created_at`) | 3.26.0, 2026-09-26 | 8.5.3, 2024-10-02 |
| License | AGPL-3.0 | CC0-1.0 |
| Stars, archived, pushed | 3425, false, 2026-09-26 | 2860, **true**, 2025-01-14 |
| Open issues (`total_count`) | 32 | 28 |
| Issue responsiveness | not sampled (gap) | not sampled (archived) |
| Advisories (rustsec.org) | HTTP 404: none | HTTP 404: none |
| Maintenance state | active | archived |

##### Principles and implementation

Principle served: the tier is chosen deliberately from measured cost (F106). py placed
`ty` at pre-push because a full-tree check was judged too slow per commit (py
`lefthook.yml:168-173`, ADR 0018); ts put `tsc --noEmit` at pre-commit (ts
`lefthook.yml:64-67`, D-020(6)). Measured here (E9): warm incremental `cargo check` of
the full scope is 0.13-0.39 s; the cold first run is 9-12 s on this host. Because
`build.warnings` does not change fingerprints (E5), the hook's denying run reuses the
editor's and the recipe's artifacts for the same feature set. Crate figures for the
tier itself: **inapplicable**.

##### Dominant choice

No ecosystem-wide dominant tier was found; the surveyed projects do not publish hook
configurations in the files read. ts's recorded choice (pre-commit) is the nearest
precedent.

##### Qualified shortlist

1. pre-commit — measured sub-second warm.
2. pre-push — py's tier; defers type errors to push time.

##### Excluded by gate

- `cargo-watch` as the mechanism: archived repository (maintenance state `archived`).
- `bacon` as the *gate*: it is a watcher, not a gate, and its AGPL-3.0 license fails
  gate 1 for anything the template would vendor or link. It is not excluded as a
  contributor tool: R69's parameter already names "the contributor-installed bacon 3.25.0
  dev watcher, which is not a Cargo dependency", and nothing here changes that.

##### Up-and-comers

rust-analyzer's caching work (survey post line 159) lowers editor latency, which reduces
how often the hook finds something the editor has not already shown.

##### Fit for this template

A template's first-time contributor pays the cold cost once (dependency check), which
happens anyway on their first `cargo build`. After that, pre-commit is cheaper than the
format and lint hooks R27/R28 are likely to add.

##### Recommendation

pre-commit, running the same command as the recipe and CI, with
`CARGO_BUILD_WARNINGS: deny` in the job's `env`.

##### Ranked runner-up

pre-push, if R37 or R28 puts clippy at pre-commit with the same flags. In that case,
clippy's own run already type-checks, and a second pre-commit job only adds the
0.6-0.7 s re-check measured in E10.

##### Tradeoffs

- The hook type-checks the working tree, not the staged snapshot, so unstaged edits can
  hide or cause errors. ts's `tsc --noEmit` has the same property.
- The hook and rust-analyzer share `target/` and Cargo's build lock
  (`cargo.targetDir` default shared); a commit can wait for an in-flight editor check.
  Setting `rust-analyzer.cargo.targetDir = true` removes the wait at the cost of
  duplicate artifacts; that is R28's editor-settings call.
- `--locked` at pre-commit fails a commit whose `Cargo.toml` edit needs a lockfile update
  that was not made; that is consistent with CI and with R41's lockfile checks.

##### Parameters

assumes `package-manager-invocation` (R42: bare `cargo check`, no runner prefix in
lefthook jobs); owns nothing.

##### Migration implications

One `pre-commit` job in `lefthook.yml` (R37 owns the file's overall shape). py's
pre-push placement stays; the follow-on rationale for py is that the cost argument
is tool-specific, since `ty` is not incremental in the same way.

##### Validation strategy

Executed: E9 timings (macOS only). Proposed: on ubuntu-latest, run the recipe cold and
then after a one-line edit, and record both; commit a file with a type error and
confirm `lefthook run pre-commit` exits non-zero.

##### Confidence & re-verify trigger

Medium. The measurement is from a 76-package probe on an M4 Pro, not the finished
template on typical contributor hardware. Re-verify when the template's dependency
count roughly doubles (R78 `otel`, R79 `metrics`) or if warm incremental check exceeds
about 2 s on ubuntu-latest.

##### Sources

- py `lefthook.yml:168-173` at `b55b8c2`; ts `lefthook.yml:64-67` at `e5100b4`; ts `docs/port/TS_PORT_DECISIONS.md` D-020 (line 231).
- crates.io and GitHub endpoints as named in the figure table; `https://rustsec.org/packages/bacon.html`, `https://rustsec.org/packages/cargo-watch.html`, 2026-09-26.
- rust-analyzer `config.rs:878` (blob `1e7c8257d15b`); rust-analyzer FAQ "rust-analyzer and cargo compete over the build lock", https://rust-analyzer.github.io/book/faq.html#rust-analyzer-and-cargo-compete-over-the-build-lock (cited from the survey post, not fetched).
- Executed checks E5, E9, E10.

### Compatibility

All members are features of one toolchain, so compatibility is a version matrix rather
than a shared adopter:

| Member | Needs | Works on 1.96 floor | Works on 1.98.1 |
|---|---|---|---|
| `cargo check --workspace --all-targets --all-features --locked --keep-going` | any Cargo | yes (E12) | yes (E9) |
| `build.warnings = "deny"` | Cargo ≥ 1.97 | inert, silently (E3, E4) | yes (E3) |
| `[workspace.lints.rust]` with `priority` | Cargo ≥ 1.74 | yes (E13) | yes (E13) |
| `#[expect(..., reason)]` | Rust ≥ 1.81 | yes (by version; E6 run on 1.98.1 only) | yes (E6) |

Shared adopter for the combination "`CARGO_BUILD_WARNINGS: deny` + `--all-targets` +
`--keep-going` + `[workspace.lints.rust]`": rust-lang/cargo (`main.yml:79,84`,
`Cargo.toml:130-131`). The combination "`--workspace --all-targets --all-features
--locked` + `[workspace.lints.rust]`" is used by uv and ruff (with clippy and
`-D warnings` as the severity mechanism). The whole stack ran together in the probe
workspace (E13, then the fixed variant exiting 0).

### Parameters

- owns: none (the prompt's `owns:` list is empty).
- assumes `rust-edition = 2024`
- assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (floor 1.96 while stable is 1.98; `build.warnings` is inert on it — no change requested)
- assumes `license = MIT OR Apache-2.0`
- assumes `target-os-matrix = ubuntu-latest, macos-latest`
- assumes `ci-job-structure = <R11 value in this run's inputs, acceptance 774f7649…>` — used only for: the `check` job hosts compiling checks as ordered steps, every cargo command carries `--locked`, and each cargo step runs under `!cancelled()`. The `typecheck` step is added under R11's own rule ("a check that compiles what check already compiles is an ordered step of check"); no new job, no `CONFLICT:`.
- assumes `web-extra-surface = <R69 value>` — `web` off by default; `otel`/`metrics` require `web`.
- assumes `package-manager-invocation = <R42 value>` — bare `cargo check`; no runner prefix in lefthook jobs.
- No `CONFLICT:` lines.

### Migration implications

| File | Change |
|---|---|
| `Cargo.toml` (root) | Add `[workspace.lints.rust]` with `rust_2018_idioms = { level = "warn", priority = -1 }` (other items append) |
| each member `Cargo.toml` | Add `[lints] workspace = true` |
| `Justfile` | Add `typecheck` recipe (body in `### Principles and implementation`) and `alias tc := typecheck`; include it in the aggregate recipes R37 defines |
| `lefthook.yml` | Add pre-commit job `typecheck` with `env: CARGO_BUILD_WARNINGS: deny` |
| `.github/workflows/ci.yml` | In R11's `check` job, add a first ordered step `typecheck` with step-level `CARGO_BUILD_WARNINGS: deny` and `if: ${{ !cancelled() }}` |
| `CONTRIBUTING.md` | Suppression rule: `#[expect(lint, reason)]`, `#[allow(lint, reason)]` only for configuration-dependent lints, never `allow(warnings)` |
| Handed to R28 (not changed here) | `rust-analyzer.cargo.features = "all"` for editor ≡ gate on the `web` tree; optionally `rust-analyzer.cargo.targetDir`; clippy `allow_attributes_without_reason` |
| Handed to R32 (not changed here) | Doctests are type-checked only by `cargo test --doc` |
| Handed to R42 (not changed here) | Toolchain pin, so that new-stable lints do not fail forks' CI spontaneously (Cargo guide, `continuous-integration.md:227-228`) |
| py / ts (follow-on project, not changed here) | py: widen `ty` scope to `tests/`; consider a single tier given the lockfile. ts: adopt a named-suppression convention |

### Validation strategy

**Executed** (this leg; macOS, Apple M4 Pro, offline; toolchains as named at the top):
E1-E13 in `### Principles and implementation`. Summary: `--all-targets` is required for
test code (E1); doctests are outside the gate (E2); `build.warnings` denies on 1.97.1 and
1.98.1 and is inert on 1.96.0 (E3, E4); it does not change fingerprints, while
`RUSTFLAGS` does (E5); suppressions behave as the discipline assumes, with the
`allow(warnings)` gap (E6-E8); warm incremental check is sub-second (E9); clippy after
check re-checks only workspace crates (E10); clippy reports type errors (E11); the stack
works end to end, including on the floor (E12, E13).

**Planned** (in the template once it exists; ubuntu-latest and macos-latest):

```bash
just typecheck                                   # expect exit 0 on a clean tree
printf 'fn _bad() -> u32 { "x" }\n' >> <member>/src/lib.rs
just typecheck                                   # expect exit 101, error[E0308]
git checkout -- <member>/src/lib.rs
printf '#[cfg(test)] mod t { fn _b() -> u32 { "x" } }\n' >> <member>/src/lib.rs
just typecheck                                   # expect exit 101 (test scope)
printf 'fn _u() { let x = 1; }\n' >> <web member>/src/web/mod.rs
just typecheck                                   # expect exit 101, "warnings are denied by `build.warnings` configuration"
cargo check --workspace                          # expect exit 0 (lax locally, default features)
printf '#[expect(unused_variabels, reason = "typo")]\nfn _v() {}\n' >> <member>/src/lib.rs
just typecheck                                   # expect exit 101 (unknown_lints + unfulfilled expectation)
lefthook run pre-commit                          # expect the typecheck job to fail the same way
diff <(grep -o 'cargo check .*' Justfile) <(grep -o 'cargo check .*' lefthook.yml)   # expect no difference
```

The CI proof is the `typecheck` step going red on a pull request that plants
`E0308`, while the `hygiene` job still reports (R11's no-`needs` design).

### Confidence & re-verify trigger

- Engine (no wrapper, no second checker): **high**.
- Scope `--all-targets --all-features`: **high** / **medium** (depends on R69's features staying additive).
- Severity via `build.warnings`: **high** on 1.97+; the floor gap is known and harmless.
- Distinct named CI step (Option A over B): **medium** — the surveyed majority uses B;
  A is chosen for principle preservation at a measured sub-second cost.
- Hook tier pre-commit: **medium** — macOS-only probe timings, not the finished template.

Re-verify triggers: declared `rust-version` reaches 1.97; R42 leaves the CI toolchain
floating; R28 places clippy at pre-commit with the same flags (then consider dropping
the pre-commit `typecheck` job); a non-additive or independent feature is added (then
consider `cargo-hack`); Cargo unifies `check` and `build` caches; warm incremental
check exceeds about 2 s on ubuntu-latest.

**Gaps recorded.**

1. Issue responsiveness sampled only for `cargo-hack`; `bacon`, `cargo-watch` (archived)
   and `cargo-all-features` not sampled.
2. `cargo-hack`'s `unsafe` posture and its CI OS matrix were not inspected.
3. All timings are macOS / Apple M4 Pro, on a 76-package probe rather than the template;
   no ubuntu-latest measurement.
4. Not tested: whether `--force-warn` escapes `build.warnings`; whether `build.warnings`
   covers rustdoc lints.
5. `#![allow(warnings)]` passes the gate; no rustc-level mechanism closes it.
6. Doctests are outside every `cargo check` form; handed to R32.
7. The seven-project survey read CI and manifest files only; hook configurations of
   those projects were not surveyed, so there is no practice evidence for the hook tier.
8. rust-analyzer FAQ on build-lock contention cited from the survey post, not fetched
   (host not among the named endpoints).
9. Prompt line citations have drifted in the source repos (see `BASELINE-REVIEW:`
   paragraph); classifications unaffected.

### Sources

All retrieved 2026-09-26.

Rust project and team publications (retrieved as source through `GET https://api.github.com/repos/<o>/<r>/contents/<path>`):
- The Cargo Book, *Continuous Integration* — https://doc.rust-lang.org/cargo/guide/continuous-integration.html (rust-lang/cargo `doc/book/src/guide/continuous-integration.md:202-237`)
- The Cargo Book, configuration, `build.warnings` — https://doc.rust-lang.org/cargo/reference/config.html#buildwarnings (`doc/book/src/reference/config.md:471-484`)
- The Cargo Book, manifest, `[lints]` — https://doc.rust-lang.org/cargo/reference/manifest.html#the-lints-section (`doc/book/src/reference/manifest.md:532-557`)
- Cargo changelog — https://doc.rust-lang.org/cargo/CHANGELOG.html (`doc/book/src/CHANGELOG.md`: 240, 293, 394-402, 4156)
- rustc book, *Lint levels* — https://doc.rust-lang.org/rustc/lints/levels.html (rust-lang/rust `src/doc/rustc/src/lints/levels.md`)
- Rust `RELEASES.md`, Version 1.81.0 — https://github.com/rust-lang/rust/blob/main/RELEASES.md
- RFC 2383 (lint reasons) — https://rust-lang.github.io/rfcs/2383-lint-reasons.html (cited via `cargo clippy --explain allow_attributes`)
- rust-analyzer configuration source — https://github.com/rust-lang/rust-analyzer/blob/master/crates/rust-analyzer/src/config.rs (blob `1e7c8257d15b`)
- *Rust compiler performance survey 2025 results* — https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ (rust-lang/blog.rust-lang.org `content/rust-compiler-performance-survey-2025-results/index.md`)
- *2025 State of Rust Survey Results* — https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/ (`content/2025-state-of-rust-survey-results/index.md`, line 200: editor preferences)

Community reference:
- rust-unofficial/patterns, `#![deny(warnings)]` anti-pattern — https://rust-unofficial.github.io/patterns/anti_patterns/deny-warnings.html (`src/anti_patterns/deny-warnings.md`)

Registry, repository and advisory figures (endpoints as named in the member tables):
- `GET https://crates.io/api/v1/crates/{cargo-hack,bacon,cargo-watch,cargo-all-features}` and `/versions?per_page=100`
- `GET https://api.github.com/repos/{taiki-e/cargo-hack,Canop/bacon,watchexec/cargo-watch,frewsxcv/cargo-all-features,rust-lang/rust-analyzer,rust-lang/rust-clippy,rust-lang/cargo,astral-sh/uv,astral-sh/ruff,tokio-rs/axum,tokio-rs/tokio,bevyengine/bevy,BurntSushi/ripgrep}`
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
- `https://rustsec.org/packages/{cargo-hack,bacon,cargo-watch,cargo-all-features}.html` (all HTTP 404, meaning no advisories filed)

Practice evidence files (contents endpoint, blob SHAs):
- rust-lang/cargo `.github/workflows/main.yml` `8ebd281b6008`, `Cargo.toml` `6d8001085cb9`
- astral-sh/uv `.github/workflows/check-lint.yml`, `Cargo.toml` `b891425af59f`
- astral-sh/ruff `.github/workflows/ci.yaml` `b240f331c039`, `Cargo.toml` `8d89233e414b`
- tokio-rs/axum `.github/workflows/CI.yml` `eb64995749fe`, `Cargo.toml` `e7579bfa7fbe`
- tokio-rs/tokio `.github/workflows/ci.yml` `4223db720445`
- bevyengine/bevy `.github/workflows/ci.yml` `b4b325e41806`, `Cargo.toml` `283e36ddb4d5`
- BurntSushi/ripgrep `.github/workflows/ci.yml` `4b88a75b9b9d`

Source-repo evidence (local checkouts):
- py-launch-blueprint at `b55b8c2` (2026-09-22): `Justfile:244`; `lefthook.yml:168-173`; `.github/workflows/ci.yml:127-128`; `pyproject.toml:210-262`; `docs/adr/0018-hook-ci-parity-and-boundary-gate.md`
- ts-launch-blueprint at `e5100b4` (2026-09-15): `Justfile:135-142,181,188,220`; `package.json:33`; `lefthook.yml:64-67`; `.github/workflows/ci.yml:100`; `tsconfig.json`; `.vscode/settings.json`; `docs/port/TS_PORT_DECISIONS.md` D-015 (line 143), D-020 (line 231), D-032 (line 389)
- rs-launch-blueprint: `docs/port/COMMONALITY.md:111-119`; `docs/port/DIVERGENCE-ANALYSIS.md:117,120,127-130,245-248`; `research/runs/R30/2026-09-26T190200Z-c5c1105074c1/inputs/PARAMETERS.md`

Local toolchain evidence: `rustc -W help`, `cargo -Zhelp`, `cargo help check`, `cargo clippy --explain <lint>` on 1.98.1; `rustup run 1.96.0|1.97.1 cargo …`; executed checks E1-E13.
