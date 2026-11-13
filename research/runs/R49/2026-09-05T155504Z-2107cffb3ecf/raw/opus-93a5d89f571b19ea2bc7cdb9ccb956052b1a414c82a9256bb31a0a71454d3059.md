# R49 — build-target-declaration (kind: crate, tier: deep) — Opus raw report

Retrieval date for every figure and claim below unless stated otherwise: **2026-09-10**.
Source repositories were read through their programme pins:
`py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
(`git -C <repo> show <pin>:<path>`, 2026-09-10). No claim below is taken from either repo's HEAD.

### Landscape

**The category this item decides.** *Build-target declaration*: the manifest fields that tell the
build system (a) which compiled artifacts a package produces and what they are named, (b) where each
artifact's entry-point source lives, (c) which files are copied into the distributable archive, and
(d) whether the distribution name and the executable name are the same string. In Python this
category is split across a PEP 517 build **backend** (`build-backend = "uv_build"`, py
`pyproject.toml:133` at pin `b08bccfb`, retrieved 2026-09-10) plus `[project.scripts]` and
`[tool.uv.build-backend]`. In TypeScript it is split across a **bundler** (`tsdown`,
ts `tsdown.config.ts:5-17` at pin `cb1cbcb2`) plus hand-authored `package.json` `bin`, `files` and
`exports` fields (ts `package.json:17-28` at pin `cb1cbcb2`). The load-bearing structural fact for
Rust is that **this category has no pluggable layer**: Cargo is simultaneously the build system, the
target declarer, the packager and the publisher, and its declaration surface is `Cargo.toml` itself.

**Three-bin map of the Rust field.**

| Bin | Candidates found | What each actually declares |
|---|---|---|
| Built-in / first-party toolchain | **Cargo manifest targets** — `[lib]`, `[[bin]]`, `[[example]]`, `[[test]]`, `[[bench]]`, with `name`, `path`, `required-features`, `doc`, `test`, `crate-type`; `[package]` `include`/`exclude`, `default-run`, `rust-version`, `publish`, `autobins`/`autolib`. **`cargo package` / `cargo publish`** (produces the single `.crate` archive). **`build.rs` build scripts** (first-party codegen hook). **Cargo features** (`[features]`) as the conditional-compilation gate | The entire category. Nothing else in Rust declares a build target |
| Established industry standard (third-party, orchestrates *around* Cargo) | `cargo-dist` (the tool is now named **`dist`**), `cross`, `cargo-zigbuild`, `cargo-binstall` (via `[package.metadata.binstall]`), `cbindgen`, `maturin`, `wasm-pack`, the **`cargo-xtask` pattern** | Release-artifact fan-out, cross-compilation, alternate-ecosystem outputs. None of them replaces `[[bin]]`/`[lib]`; every one of them *reads* those declarations |
| Up-and-comer | `dist` under its new name (`axodotdev/cargo-dist`, configured in a separate `dist-workspace.toml`), `cargo-packager`, `bazelbuild/rules_rust` / Buck2 as whole-build-system replacements | Installer/bundle generation and non-Cargo build graphs. `rules_rust` (840 stars, `GET https://api.github.com/repos/bazelbuild/rules_rust`, 2026-09-10) replaces the *builder* but not `Cargo.toml`'s `[package]` metadata, which crates.io publishing still requires |

**Authoritative sources used, and why each is authoritative.**

1. **The Cargo Book**, published by the Cargo team under rust-lang: the normative specification of
   every field this item decides. Pages used: *Cargo Targets*
   (<https://doc.rust-lang.org/cargo/reference/cargo-targets.html>), *The Manifest Format*
   (<https://doc.rust-lang.org/cargo/reference/manifest.html>), *cargo-package*
   (<https://doc.rust-lang.org/cargo/commands/cargo-package.html>), *cargo-install*
   (<https://doc.rust-lang.org/cargo/commands/cargo-install.html>), *Publishing on crates.io*
   (<https://doc.rust-lang.org/cargo/reference/publishing.html>), *Environment Variables*
   (<https://doc.rust-lang.org/cargo/reference/environment-variables.html>), *Build Cache*
   (<https://doc.rust-lang.org/cargo/reference/build-cache.html>), *Package Layout*
   (<https://doc.rust-lang.org/cargo/guide/project-layout.html>). All retrieved 2026-09-10.
2. **The Rust Edition Guide, 2024 chapter** (<https://doc.rust-lang.org/edition-guide/print.html>,
   retrieved 2026-09-10): rust-lang's normative statement of what `edition = "2024"` changes in
   `Cargo.toml`. Authoritative because the owner has fixed `rust-edition = 2024`
   (`docs/port/PARAMETERS.md:8`) and the edition silently changes manifest semantics.
3. **The annual State of Rust survey** (2025 edition results,
   <https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/>, retrieved 2026-09-10,
   7156 responses): the Rust project's own community-scale instrument. Used here only as weak
   corroboration that Cargo is the universal build front end; it publishes no figure specific to
   target declaration, so I do **not** cite a number from it.
4. **Maintainers' own documentation** for each third-party candidate (`dist` README at
   <https://raw.githubusercontent.com/axodotdev/cargo-dist/main/README.md>, `cargo-xtask` README at
   <https://raw.githubusercontent.com/matklad/cargo-xtask/master/README.md>), retrieved 2026-09-10.
   Authoritative for what the tool claims to do, not for whether it should be adopted.
5. **Primary manifests of well-regarded projects** (below). Authoritative as *practice* evidence
   because they are the shipped configuration, not a description of one.

A single blog post was not used as an authority anywhere in this report.

**Practice evidence — well-regarded Rust projects surveyed, with the evidence that they are well
regarded.** Star counts and repository state from `GET https://api.github.com/repos/<o>/<r>`,
2026-09-10; manifests from `https://raw.githubusercontent.com/<o>/<r>/<default-branch>/Cargo.toml`,
2026-09-10.

| Project | Why well regarded | Target declaration observed | Packaged-file mechanism |
|---|---|---|---|
| `BurntSushi/ripgrep` | 68148 stars; the reference Rust CLI, packaged by every major distro | `[[bin]] path = "crates/core/main.rs"`, `name = "rg"`; package `ripgrep` — **names diverge** | `exclude = [...]` |
| `sharkdp/bat` | 60399 stars | package and bin both `bat`; targets auto-discovered (no `[[bin]]` block) | `exclude = ["assets/syntaxes/*", "assets/themes/*"]` |
| `casey/just` | 35726 stars; the command runner this template's own charter uses | `[lib] doctest = false` **plus** `[[bin]] path = "src/main.rs" name = "just" test = false` — the exact CLI+library shape | `exclude = ["/book", "/etc", "!/etc/completion-registration-script.bash", "/www"]` |
| `atuinsh/atuin` | 31579 stars; CLI + sync **server** in one product | workspace; bin package `atuin` auto-discovers its bin; the HTTP server is a **separate library crate** `atuin-server`; optional surfaces are Cargo features | `exclude = ["vendor/bash-preexec/.github", ...]` |
| `rust-lang/mdBook` | 22127 stars; a rust-lang project | `[[bin]] name = "mdbook" doc = false`; one binary; the **web server is a default-on Cargo feature** `serve = ["dep:futures-util", "dep:tokio", "dep:axum", "dep:tower-http"]` | `exclude = ["/guide/*"]` |
| `rust-lang/cargo` | 15462 stars; the tool itself | `[package] name = "cargo"` with `[[bin]] name = "cargo"` **and** a library target in the same package | workspace-level `exclude = [...]` |
| `bytecodealliance/wasmtime` | 18616 stars; Bytecode Alliance flagship | package `wasmtime-cli`, `[lib] doctest = false`, `[[bin]] name = "wasmtime" path = "src/bin/wasmtime.rs" doc = false`, `default-run = "wasmtime"` — **names diverge**, plus `[package.metadata.binstall]` | `exclude = [...]` |
| `crate-ci/typos` | 4125 stars; widely used in CI | workspace `default-members = ["crates/typos-cli"]`; package `typos-cli`, bin `typos` — **names diverge** | `include = ["build.rs","src/**/*","Cargo.toml","Cargo.lock","LICENSE*","README.md","examples/**/*"]` |

Two things fall straight out of that table (eight projects). **First**, **seven of the eight** use
`exclude` (deny-list) — ripgrep, bat, just, atuin, mdBook, wasmtime, and cargo at the workspace level
— and only `typos` uses `include` (allow-list); the ecosystem's default posture is "ship the
git-tracked tree minus named directories". **Second**, **three of the eight** deliberately diverge the
distribution name from the binary name (`ripgrep`/`rg`, `wasmtime-cli`/`wasmtime`,
`typos-cli`/`typos`); the other five match because the product name is already short. None of the
three needs an install-time lookup flag to do it.

**Fit framing.** Every candidate below is judged against this template's actual shape — one CLI, one
consumable library, one optional web service (`web-extra-surface`, R69, still unresolved) — and
against the py and ts precedent quoted in the prompt's `## Context`, not against "best build tool in
general".

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

F211 (`docs/port/COMMONALITY.md:215`, verdict `COMMON → REUSE`) states the tool-free pattern: *the
project's build system turns source into a distributable package whose contents are declared, not
incidental*. F212 (line 216, `COMMON → SUBSTITUTE`, owned by R49) is the tool row under it. Reading
both source repos at their pins, the principle decomposes into four behaviors that must agree across
ecosystems, and one that may vary:

| # | Behavior that must agree | py evidence (pin `b08bccfb`) | ts evidence (pin `cb1cbcb2`) | Level |
|---|---|---|---|---|
| B1 | Exactly one manifest declares every produced artifact; there is no second, out-of-band build description | `pyproject.toml:130-141` — `[build-system]` + `[tool.uv.build-backend]` | `package.json` + `tsdown.config.ts` — *two* files, a known cost of the JS ecosystem | capability |
| B2 | The consumable library and the executable are declared as **separate, named** outputs | `pyproject.toml:139/141` `module-name`/`module-root` (one package root; py's whole package is one unit) | `tsdown.config.ts:9` `entry: ['src/cli.ts', 'src/lib.ts']` | architectural pattern |
| B3 | The executable's name is declared explicitly, independently of the distribution name | `pyproject.toml:120` `plbp = "py_launch_blueprint.cli.main:cli"` | `package.json:18` `"ts-projects": "dist/cli.js"` | policy |
| B4 | The set of files that reaches the consumer is bounded by a declaration, not by whatever is in the working tree | `pyproject.toml:139/141` bounds wheel content implicitly | `package.json:20-22` `files: ["dist"]` | policy |
| — | **May vary**: whether the boundary is expressed as an allow-list or a deny-list; whether the entry point is a callable reference or a file path; whether one process or two implement CLI and server | py: callable ref + implicit allow-list; ts: file path + explicit allow-list | | — |

**Does the pattern remain appropriate in Rust?** B1, B2 and B4 do, unchanged. B3 changes meaning and
is the one place where a different ecosystem needs a different design. In py, `[project.scripts]`
exists because a wheel contains no executable — the backend must *generate a wrapper script* from a
`module:function` reference at install time (that is F217, correctly `OMIT` at
`docs/port/COMMONALITY.md:221`). In ts, `bin` exists because npm must *symlink* a file and the
shebang must survive bundling. In Rust, `cargo build` emits a native executable directly; the
`[[bin]]` `name` field *is* the artifact's filename, with no indirection, no wrapper and no shebang.
So B3 survives, but its *mechanism* collapses from "a reference that a build backend resolves" to
"the literal output filename".

**Comparing architectural alternatives before comparing libraries.** Four structurally different
designs can satisfy B1–B4 in Rust:

- **A1 — Cargo-native, single package, one binary, web behind a feature.** `[lib]` at `src/lib.rs`,
  one `[[bin]]`, `[features] web = [...]`. Reference implementation: **mdBook** — a CLI, a consumable
  library and an axum-based HTTP server (`mdbook serve`) in one package, the server gated by the
  `serve` feature (`rust-lang/mdBook/Cargo.toml` lines 108-133, retrieved 2026-09-10).
- **A2 — Cargo-native, single package, two binaries.** A second `[[bin]]` carrying
  `required-features = ["web"]`, plus `default-run` to keep `cargo run` unambiguous. Reference
  implementation for the mechanism: **wasmtime** uses `default-run = "wasmtime"`
  (`bytecodealliance/wasmtime/Cargo.toml:12`); the Cargo Book documents
  `required-features` on `[[bin]]` verbatim: *"If any of the required features are not enabled, the
  target will be skipped."* (<https://doc.rust-lang.org/cargo/reference/cargo-targets.html>,
  2026-09-10).
- **A3 — Workspace split.** Separate `-core`, `-cli`, `-server` packages. Reference implementation:
  **atuin** (`crates/atuin` bin package + `crates/atuin-server` library, root `Cargo.toml` lines
  1-27) and **typos** (`default-members = ["crates/typos-cli"]`).
- **A4 — Cargo plus an orchestration layer.** A `[workspace.metadata.dist]` table (the `dist` tool)
  or a `cargo-xtask` binary that drives multi-artifact builds. Reference implementation for xtask:
  Cargo itself (`cargo-xtask` README, 2026-09-10: *"Notably, Cargo itself uses xtasks"*).

A2's cost is concrete and documented, not speculative: the Cargo Book's environment-variable
reference states that `CARGO_BIN_EXE_<name>` is set for integration tests, and *"Binaries are
automatically built when the test is built, **unless the binary has required features that are not
enabled**"* (<https://doc.rust-lang.org/cargo/reference/environment-variables.html>, 2026-09-10).
A second `required-features` binary therefore silently disappears from the default `cargo test`
build — the exact failure mode R32's built-binary test tier would have to work around. A3's cost is
that it multiplies the manifest surface this item is meant to settle and pre-empts R02
(`crate-boundary-enforcement`), which owns the workspace-shape question. A4's cost is a maintained
third-party dependency for a decision (F214) that belongs to R68.

**Maturity, dependability, performance and integration cost.** Cargo's target declaration is part of
the toolchain: it ships with every `rustup` stable, has no separate release cadence, no advisory
surface, no MSRV of its own, no default features, no async-runtime coupling, and contributes zero
bytes to the binary and zero seconds to compile time. Every third-party candidate is a *separately
installed binary* that runs beside the build; none of them link into the artifact, so the
performance question for this item is not throughput but wall-clock CI cost and one more tool to
provision. `cargo package`'s own cost is a full rebuild from a pristine extraction — the Cargo Book
lists it as step 3, *"Extract the `.crate` file and build it to verify it can build… The
`--no-verify` flag can be used to skip this step"* — which is roughly one clean release build per
invocation and is the reason it belongs in a release job, not in the default check loop. I did not
measure it: no Rust code exists in this repository yet, so **any latency or throughput number here
would be invented**. I state that as an evidence gap rather than a figure.

**Observable acceptance criteria.** The principle holds when all of the following are true of the
finished template, and each is machine-checkable:

- AC1 — `cargo metadata --no-deps --format-version 1` reports exactly one target with
  `"kind": ["lib"]` and exactly one with `"kind": ["bin"]`, and the bin's `name` equals the value
  recorded in `build-tool-output-shape`.
- AC2 — `cargo build --release` produces `target/release/<bin-name>` (Cargo Book, *Build Cache*,
  2026-09-10: *"By default, both directories point to a directory named `target` in the root of your
  workspace"*, with `target/debug/` for the `dev` profile and `target/release/` for `release`).
- AC3 — `cargo package --list` prints a file list that contains `Cargo.toml`, `Cargo.lock`,
  `LICENSE*`, `README.md` and `src/**`, and contains no path under the excluded directories.
- AC4 — `cargo publish --dry-run` exits 0, which runs the verification build of step 3.
- AC5 — with the web feature off, `cargo build` still succeeds and the produced binary set is
  unchanged in *count* (one binary), so R68's artifact list does not change shape with the feature
  flag.
- AC6 — an integration test can resolve the binary through `env!("CARGO_BIN_EXE_<bin-name>")`
  without enabling any non-default feature.

AC1–AC6 are **proposed** checks. None has been executed: there is no Rust source tree in
`rs-launch-blueprint` yet, and this is a research programme, not an implementation.

**Minimal realistic example.** One package. `src/lib.rs` exports the domain plus the ports/adapters
seam that R01 already fixed (`http-transport-injection-seam`, `docs/port/PARAMETERS.md:11`).
`src/main.rs` is the CLI: it parses arguments, builds the composition root, and returns `ExitCode`
per R67's resolved `error-taxonomy-exit-codes` (which already presumes a library-crate/binary-crate
split — *"`thiserror` in the library crate, `anyhow` … in binary crates only"*). The optional web
service lives in `src/web/` inside the **library**, compiled only when the `web` feature is on, and
is reached through a `serve` subcommand on the same binary — mdBook's exact composition. `Cargo.toml`
declares `[lib]`, one `[[bin]]`, `[features]`, and an `exclude` list.

**BASELINE-REVIEW finding.**

BASELINE-REVIEW: F212 — principle: the build backend/bundler is a *selectable third-party tool*, which is what makes R49 an item of kind `crate` in `research/CLAUDE.md` and makes the prompt's crate figure table (90-day downloads, last release, advisories, adopters) the required evidence — proposed change: reclassify R49's item kind from `crate` to `pattern`, or to an explicit `crate (first-party toolchain, zero added dependencies)` sub-kind, and record F212's substitute as "the Cargo toolchain, no crates.io dependency", so downstream items and the `check-research-tree.sh` gate do not expect a version range for a crate that does not exist — evidence: (a) the Cargo Book documents `[lib]`/`[[bin]]`/`include`/`exclude` as manifest fields of the toolchain itself, with no pluggable backend interface analogous to PEP 517 (<https://doc.rust-lang.org/cargo/reference/cargo-targets.html> and <https://doc.rust-lang.org/cargo/reference/manifest.html>, 2026-09-10); (b) the ledger row already anticipates it — "Cargo is Rust's native build system with no separate backend/bundler crate needed" (`docs/port/COMMONALITY.md:216`); (c) every crate figure this prompt requires is `inapplicable` to the recommended answer, as recorded in `### Qualified shortlist`; affected items: R49 (this item), and informationally R68 and R50, whose prompts describe R49 as declaring build targets — neither statement changes.

I have not edited the ledger or the research index.

### Dominant choice

**Cargo's native manifest target declaration — `[package]` + `[lib]` + `[[bin]]` +
`include`/`exclude`, with no build-backend or bundler dependency added.** Version range:
**the Cargo shipped with the MSRV-policy toolchain floor**, i.e. no separate version pin; the
constraint is expressed as `edition = "2024"` plus `rust-version = "<stable minus 2 minors>"` in
`[package]`, per the owner-fixed `rust-edition` and `msrv-policy` parameters
(`docs/port/PARAMETERS.md:7-8`). `edition = "2024"` is itself load-bearing on Cargo behavior: the
Rust Edition Guide states *"`edition = "2024"` implies `resolver = "3"` in Cargo.toml which enables a
Rust-version aware dependency resolver"*, and that resolver *"is a global setting for a workspace …
only honored for the top-level package"* (<https://doc.rust-lang.org/edition-guide/print.html>,
2026-09-10). That single implication does more for the MSRV policy than any third-party tool in this
category could.

This is a dominant choice in the strict sense: it is the only candidate that *declares* build
targets at all. Every other candidate surveyed consumes those declarations to produce something else.

### Qualified shortlist

Only **one** candidate is in the category and passes every gate. That is itself the finding the
prompt asks me to state: the Rust field has no competing build-target declarers, because the
declaration surface is owned by the toolchain. The three entries below it are orchestration layers
that passed their gates and are listed because the prompt's HIGH question 1 asks whether one of them
is nonetheless warranted.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| **Cargo manifest targets** (`[lib]`, `[[bin]]`, `include`/`exclude`) | declares the build targets and the packaged-file scope | `inapplicable` — not a crates.io crate; ships in the toolchain, so `crate.recent_downloads` has no meaning | `inapplicable` — same reason | 15462 (`rust-lang/cargo`, `GET https://api.github.com/repos/rust-lang/cargo`, 2026-09-10) | `inapplicable` as a crates.io release; tracks the six-week stable train | `active` — `pushed_at` 2026-09-08T15:46:17Z, `archived: false` (same endpoint) | every project in the practice table above | zero flexibility: what Cargo does not model (multi-artifact release fan-out) must be modelled outside the manifest |
| `cargo-dist` (tool renamed **`dist`**) | release-artifact orchestration; reads `[[bin]]`, writes installers and CI | 19922 (`GET https://crates.io/api/v1/crates/cargo-dist` → `crate.recent_downloads`, 2026-09-10) | 175385 (same endpoint, `crate.downloads`) | 2112 (`GET https://api.github.com/repos/axodotdev/cargo-dist`, 2026-09-10) | 0.32.0, 2026-05-22T05:58:59Z (`GET https://crates.io/api/v1/crates/cargo-dist/versions`, newest non-yanked, 2026-09-10) | **`active`** — see the responsiveness measurement and its correction immediately below | `atuinsh/atuin` and `astral-sh/uv` each carry a `dist-workspace.toml` at their repository root (`GET https://api.github.com/repos/<o>/<r>/contents/dist-workspace.toml`, 2026-09-10; atuin's pins `cargo-dist-version = "0.31.0"`) | buys multi-platform installer generation this item does not need, and moves part of the build declaration out of `Cargo.toml` into a second file |
| `cargo-xtask` (**pattern**, not a crate) | in-repo build orchestration written in Rust, bootstrapped from `cargo` alone | `inapplicable` — a repository convention, not a published crate (the crates.io name `xtask` is an unrelated package: 953 all-time downloads, `GET https://crates.io/api/v1/crates/xtask`, 2026-09-10) | `inapplicable` | 1319 (`GET https://api.github.com/repos/matklad/cargo-xtask`, 2026-09-10) | `inapplicable` — spec repository, `pushed_at` 2025-10-28T14:42:08Z | `stable-quiet` — a frozen specification; quiet is the expected state for a spec repo, and its own README calls it *"not an officially recommended workflow"* | `rust-lang/cargo` itself | zero dependencies, but every orchestration step becomes code this template must maintain and test |
| `build.rs` build scripts | first-party codegen/asset hook run before compilation | `inapplicable` — a Cargo feature | `inapplicable` | `inapplicable` | `inapplicable` | `active` (part of Cargo) | ubiquitous | adds a compile-time step and a rebuild-trigger surface; unnecessary unless something must be generated |

**Issue responsiveness for `cargo-dist`, and a correction to my own first measurement.** My initial
pass filtered comments by GitHub's `author_association` field over the 10 most recently opened issues
(#2504, #2492, #2489, #2457, #2456, #2446, #2444, #2443, #2442, #2437) and found **zero** from a
`MEMBER`, `OWNER` or `COLLABORATOR`, which would have supported an `at-risk` verdict. **That figure
was a filter artifact and I withdraw it.** The project's active maintainer, `mistydemeo` — who
authored a commit to `main` on 2026-09-04T19:47:56Z
(`GET https://api.github.com/repos/axodotdev/cargo-dist/commits`, 2026-09-10) — comments with
`author_association: CONTRIBUTOR`, so the filter excluded exactly the person it was meant to find.
Re-measuring by login across the same ten issues
(`GET https://api.github.com/repos/axodotdev/cargo-dist/issues/<n>/comments`, 2026-09-10):

| Issue | Opened | First maintainer comment | Days to first response |
|---|---|---|---|
| #2504 | 2026-09-08T21:38:56Z | `mistydemeo` 2026-09-09T01:42:34Z | 0.17 |
| #2492 | 2026-08-27T16:53:13Z | `mistydemeo` 2026-08-27T17:02:01Z | 0.006 |
| #2489 | 2026-08-21T13:22:02Z | `mistydemeo` 2026-08-28T06:04:48Z | 6.70 |
| #2457 | 2026-08-07T06:44:41Z | `mistydemeo` 2026-08-07T18:46:16Z | 0.50 |
| #2456 | 2026-08-05T17:15:03Z | `mistydemeo` 2026-08-05T17:22:21Z | 0.005 |
| #2446 | 2026-07-01T16:14:51Z | none | — |
| #2444 | 2026-06-29T11:37:57Z | `mistydemeo` 2026-06-29T16:41:29Z | 0.21 |
| #2443 | 2026-06-29T10:32:26Z | none | — |
| #2442 | 2026-06-29T05:47:43Z | none | — |
| #2437 | 2026-06-22T05:16:41Z | none | — |

**Median days to first maintainer response: 0.19** (about 4.6 hours) over the 6 answered issues.
**Unanswered count: 4 of 10.** Combined with 297 open issues
(`GET https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open` →
`total_count`, 2026-09-10), a maintainer commit six days before retrieval, `archived: false`, no
RustSec record, and a last release 2026-05-22 (3.5 months, below the rubric's 6-month
investigate-trigger), the rubric verdict is **`active`**, not `at-risk`. One adjacent observation,
recorded as a fact and not as a verdict: the documentation domain `opensource.axo.dev` that the
project's own book links point at returns **NXDOMAIN** (`host opensource.axo.dev`, 2026-09-10), while
the GitHub Pages mirror `axodotdev.github.io/cargo-dist/book/` serves normally. That is a hosting
signal about the sponsoring company, not a code-side signal about maintenance, and the rubric
requires a concrete code-side signal for `at-risk`, which I do not have.

**Gates for the three non-dominant shortlist rows** (stated rather than omitted, per the prompt):

- **`cargo-dist` 0.32.0.** Gate 1 — pass: `license = "MIT OR Apache-2.0"`
  (`GET https://crates.io/api/v1/crates/cargo-dist/versions`, 2026-09-10). Gate 2 — pass and mostly
  `inapplicable`: `rust_version = "1.74"` on 0.32.0, far below any plausible policy floor, and it is
  installed as a standalone binary so its dependency tree never merges with the template's. Gate 3 —
  pass: `https://rustsec.org/packages/cargo-dist.html` returns HTTP 404 (no advisory record);
  `unsafe` posture `inapplicable` to the template, since no `cargo-dist` code is compiled into the
  template's artifacts. Gate 4 — pass: it exists to build for many targets and its own repository
  runs a Rust CI workflow badge on `main`
  (<https://raw.githubusercontent.com/axodotdev/cargo-dist/main/README.md>, 2026-09-10); it is
  invoked identically on `ubuntu-latest` and `macos-latest`. Gate 5 — `inapplicable`: a separately
  installed binary contributes no Cargo features and no async runtime to the template. Gate 6 —
  `inapplicable` for binary size (nothing is linked); compile-time cost is the CI wall-clock of the
  release job it generates, which is R68's to measure, not this item's.
- **`cargo-xtask` (pattern).** Gates 1, 2, 3, 5 and 6 are all `inapplicable`: it is a repository
  convention with no published artifact, no license of its own that the template consumes, no
  dependency tree, no features and no linked code — the `xtask` binary the template would write is
  the template's own code, governed by the template's own gates. Gate 4 — pass by construction: an
  xtask is a Rust binary built by the same toolchain on both matrix legs, which is the stated reason
  the pattern exists (*"Unlike bash, it can more easily be cross platform, as it doesn't use the
  shell."*, <https://raw.githubusercontent.com/matklad/cargo-xtask/master/README.md>, 2026-09-10).
- **`build.rs` build scripts.** Gates 1, 2, 3 and 5 are `inapplicable`: a build script is a first-party
  Cargo mechanism, not a dependency; it has no license, no MSRV, no advisory surface and no features
  of its own. Gate 4 — pass: build scripts run on every host Cargo supports. Gate 6 — the only gate
  with real content: a build script adds a compile-time step to **every** build and a rebuild-trigger
  surface, and contributes no binary size unless it generates code that is then compiled. That cost is
  why the recommendation below declines it absent a concrete need.

**Gate results for the dominant choice** (answered before any popularity figure was weighed):

1. **License compatible with `MIT OR Apache-2.0`** — pass. Cargo itself is `Apache-2.0` per
   `GET https://api.github.com/repos/rust-lang/cargo` (2026-09-10, `license.spdx_id`) and is dual
   MIT/Apache-2.0 in-tree (`license = "MIT OR Apache-2.0"`,
   `https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml:16`, 2026-09-10). More to the
   point, no dependency is added, so nothing enters the dependency tree's license set.
2. **MSRV within `stable minus 2 minor versions…`** — pass, and *inapplicable as a dependency
   constraint*: Cargo is the toolchain, not a dependency, so it has no `rust-version` to check
   against the policy. The manifest fields recommended here (`[lib]`, `[[bin]]`, `required-features`,
   `include`/`exclude`, `default-run`) have been stable Cargo features for many years and impose no
   floor above `edition = "2024"`, which requires Rust 1.85.0 or newer — the 1.85.0 release
   announcement states *"We are excited to announce that the Rust 2024 Edition is now stable!"* and
   *"This stabilizes the 2024 edition as well."*
   (<https://blog.rust-lang.org/2025/02/20/Rust-1.85.0/>, 2026-09-10).
3. **No open RustSec advisory; `unsafe` posture** — pass. `https://rustsec.org/packages/cargo.html`
   is not applicable (Cargo is not consumed as a crates.io dependency here); each third-party
   candidate was checked individually and every page returned **HTTP 404**, i.e. no advisory record:
   `cargo-dist`, `cargo-binstall`, `cross`, `cargo-zigbuild`, `cbindgen`, `cargo-packager`
   (all `https://rustsec.org/packages/<name>.html`, 2026-09-10). `unsafe` posture of the recommended
   answer: **none added** — declaring targets introduces no code at all, so the template's `unsafe`
   posture is entirely R06's (`unsafe-code-policy`, resolved) to set.
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — pass. Cargo is a Tier-1 component of
   the stable toolchain on both `x86_64-unknown-linux-gnu` and `aarch64-apple-darwin`; `cargo build`,
   `cargo package` and `cargo publish --dry-run` are the same commands on both. Windows: supported,
   with the one difference that the produced binary is `<name>.exe` — noted, not required.
5. **Default features and async-runtime coupling** — `inapplicable`: manifest fields have no Cargo
   features and no runtime. The *template's own* `[features]` table is a separate matter, and the
   async-runtime coupling of the web feature belongs to R69 (`web-extra-surface`) and R05
   (`sync-async-execution-model`), not here.
6. **Binary-size and compile-time cost** — zero added bytes and zero added compile time; the
   declaration is metadata. The only cost this item introduces is the `cargo package` verification
   rebuild (Cargo Book step 3, 2026-09-10), which is one clean build, and belongs to a release job.

### Excluded by gate

**Failed a fitness gate.**

- **`cross` 0.2.5** — fails **gate 4** (must work on every OS in `ubuntu-latest, macos-latest`).
  `cross` executes the build inside a container: its own README lists under **Dependencies** *"[Docker].
  … Requires version 20.10 (API 1.40) or later."* and *"[Podman]. Requires version 3.4.0 or later."*,
  and states *"but relies on Docker or Podman. For Docker, you'll have to start the daemon before you
  can use it."* (<https://raw.githubusercontent.com/cross-rs/cross/main/README.md>, 2026-09-10). The
  GitHub-hosted macOS runner ships neither: the `macos-15` image manifest contains **no occurrence of
  `docker`, `podman` or `colima`**, while the Ubuntu 24.04 image manifest lists *"Docker Client
  28.0.4"* and *"Docker Server 28.0.4"*
  (`GET https://api.github.com/repos/actions/runner-images/contents/images/macos/macos-15-Readme.md`
  and `.../images/ubuntu/Ubuntu2404-Readme.md`, both 2026-09-10). So the same `cross` invocation
  cannot run on both matrix legs without provisioning a container engine on macOS. Independently a maintenance trigger to investigate: last
  non-yanked release **0.2.5, 2023-02-04T17:28:19Z**
  (`GET https://crates.io/api/v1/crates/cross/versions`, 2026-09-10) — over three years — with
  307766 90-day downloads and 6269217 all-time (`GET https://crates.io/api/v1/crates/cross`,
  2026-09-10), 8313 stars and `pushed_at` 2026-08-19T12:01:59Z
  (`GET https://api.github.com/repos/cross-rs/cross`, 2026-09-10), 228 open issues
  (`GET https://api.github.com/search/issues?q=repo:cross-rs/cross+is:issue+is:open`, 2026-09-10).
  Investigating the trigger: the repository is being pushed to, so this is `stable-quiet` on the
  release axis, **not** `dormant` — no unpatched advisory (RustSec HTTP 404), no maintainer notice
  found. It is excluded on gate 4, not on cadence.
- **`cargo-binstall` 1.23.0** — fails **gate 1** *as a dependency*: license `GPL-3.0-only`
  (`GET https://crates.io/api/v1/crates/cargo-binstall/versions`, newest non-yanked 1.23.0,
  2026-09-05T16:59:01Z, `license` field, retrieved 2026-09-10), which is not compatible with
  `MIT OR Apache-2.0` for anything linked. It passes as a *separately invoked binary* that never
  enters the dependency tree, and it is otherwise healthy (125820 90-day / 3483662 all-time
  downloads, `GET https://crates.io/api/v1/crates/cargo-binstall`, 2026-09-10; 2864 stars,
  `pushed_at` 2026-09-10T01:22:53Z, 93 open issues). It is excluded here regardless because the
  `[package.metadata.binstall]` table it reads is an artifact-distribution decision that
  **R68 owns (F214)**, explicitly out of scope for this item. Recorded so R68 does not have to
  re-derive the license position.

**Excluded by scope, not by a gate** (recorded so the exclusion is auditable rather than silent):

- **`cargo-zigbuild` 0.23.4** (MIT; 1547057 90-day / 7034852 all-time downloads,
  `GET https://crates.io/api/v1/crates/cargo-zigbuild` and `/versions`, released 2026-09-02T13:50:57Z,
  `rust_version` 1.88; 2647 stars, 3 open issues,
  `GET https://api.github.com/repos/rust-cross/cargo-zigbuild`, 2026-09-10; maintenance **active**) —
  it is a *linker* selection for cross-compilation, i.e. R68's territory, and it requires a Zig
  toolchain that is not part of this template's provisioning (R42).
- **`cbindgen` 0.29.4** (MPL-2.0; 13646147 90-day / 101705742 all-time downloads; 2947 stars;
  released 2026-06-09T19:03:00Z; 225 open issues; maintenance **active**, `pushed_at`
  2026-08-22T18:46:24Z) — the closest thing Rust has to ts's `dts: true` declaration emission, but it
  emits **C headers for an FFI surface**. This template exposes a Rust library to Rust consumers, and
  the type information ts must synthesize into `.d.ts` files is already carried in the `.rlib`
  metadata and rendered by `cargo doc`. **The `dts`-equivalent question therefore has no candidate in
  Rust**, which is the direct answer to the "dts-equivalent generation" clause of HIGH question 1.
- **`maturin` 1.15.0** (83693 / 1067668 downloads, released 2026-08-27T08:45:20Z) and
  **`wasm-pack` 0.15.0** (1314325 / 6041069 downloads, released 2026-05-15T08:25:44Z) — both are
  build backends, but for *other ecosystems*' artifacts (a Python wheel containing a compiled
  extension; a wasm/npm package). Neither produces the `.crate`/native-binary pair this template
  ships. Figures from `GET https://crates.io/api/v1/crates/<name>` and `/versions`, 2026-09-10.
- **`cargo-packager` 0.11.8** (Apache-2.0 OR MIT; 47349 90-day / 178600 all-time downloads; 477
  stars; released 2025-11-27T12:39:29Z; 35 open issues; `pushed_at` 2026-09-09T14:14:09Z) — desktop
  application bundler (dmg/msi/deb/AppImage). Overlaps R68 entirely and targets GUI apps.
  Maintenance: last release over nine months ago is a **trigger to investigate**, not a verdict; the
  repository is actively pushed and has no advisory (RustSec HTTP 404), so `stable-quiet`.
- **`bazelbuild/rules_rust` / Buck2** (840 stars, `pushed_at` 2026-09-07T14:58:21Z,
  `GET https://api.github.com/repos/bazelbuild/rules_rust`, 2026-09-10) — replacing Cargo as the
  builder does not remove `Cargo.toml`: crates.io publishing still requires `[package]` metadata, so
  this bin's candidates *add* a second declaration surface rather than substituting for one. Wrong
  fit for a template whose whole point is to be the minimum idiomatic starting shape.

### Up-and-comers

- **`dist`** (crate `cargo-dist`) — genuinely the emerging convention for declaring release artifacts
  and generating the release workflow from that declaration. Its own README (2026-09-10) opens
  *"`dist` (formerly known as `cargo-dist`)"*, confirming the rename while the crates.io name stays
  `cargo-dist`. Note the direction of travel: the in-`Cargo.toml` `[workspace.metadata.dist]` form is
  *"deprecated in 0.23.0"* in favor of a separate `dist-workspace.toml`
  (<https://axodotdev.github.io/cargo-dist/book/workspaces/structure.html>, 2026-09-10), so `dist` is
  moving **away** from being a manifest-level declaration and toward being a second build description
  alongside `Cargo.toml`. Watch item for R68, not an adoption for this item.
- **`cargo-packager`** — the CrabNebula alternative to `dist` for bundled/desktop artifacts. Younger
  (477 stars) and further from this template's shape.
- **`[package.metadata.binstall]` as a de-facto standard.** Both `wasmtime` and `atuin` now carry it
  in-manifest (`bytecodealliance/wasmtime/Cargo.toml:30-46`, `atuinsh/atuin/crates/atuin/Cargo.toml`,
  2026-09-10). It is the one *manifest-level* trend adjacent to this item, and it is precisely where
  a distribution-name/binary-name divergence costs something. **R68 owns whether to adopt it**; this
  item only records that a divergence makes the templating non-trivial (`{ bin }` rather than
  `{ name }` in `bin-dir`).

### Fit for this template

**CLI.** `[[bin]]` is a complete answer. The Cargo Book: *"A binary's source can be `src/main.rs`
and/or stored in the `src/bin/` directory. For `src/main.rs`, the default binary name is the package
name."* (cargo-targets, 2026-09-10). Declaring the block explicitly rather than relying on
auto-discovery buys three things this template needs: the binary name can differ from the package
name; `test = false` can suppress an empty test target on the thin `main.rs` (as `just` does); and
the declaration is *readable* — a template's manifest is documentation for the person who forked it.
The name chosen here propagates: it is the filename under `target/release/`, the token in
`CARGO_BIN_EXE_<name>` that R32's built-binary tier will use, and the string R68's release matrix
uploads.

**Library.** `[lib]` with the default path `src/lib.rs` and the default name (package name with
dashes replaced by underscores → `rs_launch_blueprint`). The Cargo Book: *"The filename defaults to
`src/lib.rs`, and the name of the library defaults to the name of the package, with any dashes
replaced with underscores. A package can have only one library."* Declaring `[lib]` explicitly is
worth it for one field: `doctest = false` or `doctest = true` is a real choice, and both `just` and
`wasmtime` write `[lib] doctest = false` for exactly this reason. This item does **not** decide that
value — R82 (`docs-correctness-gate`) does, and a template that wants doctests as executable
documentation will want `true`. What this item fixes is that `[lib]` exists as a named target, which
is what makes the R01 seam and R67's *"`thiserror` in the library crate"* layering expressible at all.

**Web.** The evidence favors **one binary with the web surface behind a Cargo feature**, not a second
`[[bin]]`. mdBook is the maintained reference implementation of exactly this composition: one
`[[bin]] name = "mdbook"`, a `serve` feature that pulls `axum`, `tokio` and `tower-http` as optional
dependencies, and a `serve` subcommand on the same executable
(`rust-lang/mdBook/Cargo.toml:108-133`, 2026-09-10). The alternative — a second binary with
`required-features = ["web"]` — is legitimate Rust and is what `[[bin]] required-features` exists
for, but it carries the documented footgun quoted above: the binary is silently skipped when the
feature is off, including in integration-test builds, so R32 would need feature-aware test wiring and
R68's artifact matrix would gain a conditional row. **This is a genuine coupling with R69, which is
unresolved.** The recommendation below is written to be robust either way: the manifest shape changes
by exactly one added `[[bin]]` block plus a `default-run` line if R69 later chooses a separate server
process, and nothing else in this item's decision moves.

### Recommendation

Declare build targets **entirely in `Cargo.toml`, adding no build-backend, bundler, or
build-orchestration dependency**. Concretely:

1. **`[package]`** — `name = "rs-launch-blueprint"`, `edition = "2024"`,
   `rust-version = "<stable minus 2 minors>"`, `license = "MIT OR Apache-2.0"`, plus the crates.io
   required metadata (`description`, `homepage`, `repository`, `readme`) that the Cargo Book lists as
   mandatory before publishing (<https://doc.rust-lang.org/cargo/reference/publishing.html>,
   2026-09-10).
2. **`[lib]`** — declared explicitly, default `path = "src/lib.rs"`, default name
   `rs_launch_blueprint`. This is the crate downstream users depend on and the crate R01's port trait
   and R67's `thiserror` error catalog live in.
3. **`[[bin]]`** — exactly one, declared explicitly with `path = "src/main.rs"` and a **short
   `name`**, e.g. `rslbp` (see point 5). One binary; the web surface is a `[features] web = [...]`
   gate reached through a subcommand, following mdBook.
4. **`include`/`exclude`** — set **`exclude`** explicitly (deny-list) rather than `include`, and
   document the choice in a manifest comment. Rationale, in order of weight: (a) Rust's default is
   already bounded — the Cargo Book states that with neither field set, *"If the package is in a git
   repository, any files that are ignored by the gitignore rules of the repository and global git
   configuration will be skipped"*, and that `target/` and any sub-package directory are *"always
   excluded"* while `Cargo.toml`, a minimized `Cargo.lock` and any `license-file` are *"always
   included"* (manifest reference, 2026-09-10), so an allow-list is not needed to make the boundary
   deterministic the way it is in npm; (b) 7 of the 8 well-regarded projects surveyed use `exclude`
   and only `typos` uses `include`; (c) a **template** is forked and extended, and an `include`
   allow-list silently omits any directory a downstream user adds, which is the worst failure mode
   for this repository's purpose. Exclude at minimum `/.github/*`, `/docs/*`, `/research/*` and any
   large fixture directory.
5. **Distribution name vs. binary name** — **diverge deliberately, and document it in one README
   line.** Unlike py, the divergence costs no install-time flag: the Cargo Book states that
   `cargo install` *"install[s] all binaries. This is the default behavior"*, and `--bin` exists only
   to install a *subset* (cargo-install, 2026-09-10). So `cargo install rs-launch-blueprint` then
   `rslbp` works with no analogue of `uvx --from`. Divergence is idiomatic — `ripgrep`/`rg`,
   `wasmtime-cli`/`wasmtime`, `typos-cli`/`typos` — and it preserves the intent both source repos
   encoded (a descriptive distribution name, a short typeable command). **The specific string is an
   owner naming call, not a research finding**: `rslbp` is proposed as the direct analogue of py's
   `plbp` (py `pyproject.toml:120` at pin `b08bccfb`). The two residual costs are one README sentence
   and, if R68 adopts `cargo-binstall`, a `bin-dir` template that must interpolate `{ bin }` rather
   than `{ name }`.
6. **Do not set `default-run`** while there is one binary; add it in the same commit as any second
   `[[bin]]`, never before — `cargo run` is unambiguous with one target and `default-run` would be
   dead metadata.
7. **Do not add `build.rs`** unless something must actually be generated. It adds a compile-time step
   and a rebuild-trigger surface for no benefit here.

**Direct answers to the prompt's questions.**

- *HIGH 1 — does `Cargo.toml` fully replace py's backend and ts's bundler?* **Yes, completely, for
  this template.** Cross-compilation is R68's, and the only thing `tsdown` does that has no Cargo
  equivalent is `dts: true` — which is a JS-only problem: Rust's `.rlib` already carries type
  metadata and `cargo doc` renders it, so there is nothing to generate. No build-orchestration crate
  is warranted.
- *HIGH 2 — the analogue of `entry: ['src/cli.ts','src/lib.ts']`?* `[[bin]]` + `[lib]` is the exact
  analogue and it suffices. The optional web target should be a **Cargo feature**, not a third entry:
  ts needs two entries because a bundler must be told every root it must trace; Cargo derives the
  graph from `mod`/`use`, so a feature flag is the more precise instrument.
- *MEDIUM 1 — the analogue of `plbp = "module:function"` vs `"dist/cli.js"`?* The `[[bin]]` `name`
  field alone. Rust has **no entry-point abstraction** because there is nothing to resolve at install
  time: `fn main()` in the declared `path` is the entry point and `name` is the output filename. F217
  (`OMIT`, `docs/port/COMMONALITY.md:221`) is confirmed correct by this reading.
- *MEDIUM 2 — must `include`/`exclude` be set?* Cargo's default is sufficient for **correctness** —
  the archive will build and the verification step proves it. It is not sufficient for **intent**:
  the default ships `docs/`, `.github/` and `research/` to every crates.io consumer. Set `exclude`
  explicitly and document it as the deliberate choice, per point 4.
- *LOW — is a name divergence needed?* Not *needed*, but recommended, per point 5. Nothing about
  `cargo install` forces the names to match, and nothing about diverging them costs a flag.

**Coupling boundaries respected.** This item declares `[[bin]]`/`[lib]`/`include`/`exclude`. It does
**not** decide which distributable artifact types ship beyond the `.crate` (R68/F214), how the built
artifact is install-and-run smoke tested (R50/F221/F222), or whether CI asserts the packaged file
list (R26/F039/F078). Where my recommendation touches those, I have said so and stopped.

### Ranked runner-up

**`cargo-dist` (the `dist` tool), 0.32.x, as a manifest-level orchestration layer above the same
`[lib]`/`[[bin]]` declarations.**

**The condition under which it wins:** if **R68 resolves F214 to "cross-compiled binaries attached to
GitHub Releases, with generated installer scripts"**, then a second declaration surface becomes the
place where the shipped output shape is actually described, and part of F212 legitimately moves
there. In that world, adopting `dist` at R68 and having R49's answer be "the manifest targets `dist`
reads" is coherent, and the alternative — hand-writing a release matrix that duplicates the target
list — is worse. It does **not** win if R68 chooses crates.io-only distribution, and it does not win
merely because it is popular.

**One correction to how I first framed this runner-up.** I initially described `dist`'s configuration
as *manifest-level*, on the assumption that `[workspace.metadata.dist]` in `Cargo.toml` is its
current home. It is not. `dist`'s own book states the workspace file may be `dist-workspace.toml`, or
*"(deprecated in 0.23.0) `Cargo.toml` (Rust users only, goes in `[workspace.metadata.dist]`)"*
(<https://axodotdev.github.io/cargo-dist/book/workspaces/structure.html>, 2026-09-10). The
in-manifest form is **deprecated as of 0.23.0**, and both adopters I verified confirm the current
shape empirically: `atuinsh/atuin` and `astral-sh/uv` each carry a root `dist-workspace.toml`
(`GET https://api.github.com/repos/<o>/<r>/contents/dist-workspace.toml`, 2026-09-10), with atuin's
containing `[workspace] members = ["cargo:."]` and a `[dist]` table pinning
`cargo-dist-version = "0.31.0"`
(<https://raw.githubusercontent.com/atuinsh/atuin/main/dist-workspace.toml>, 2026-09-10).

That materially **weakens** the runner-up on this item's own terms. Behavior **B1** in
`### Principles and implementation` is *"exactly one manifest declares every produced artifact; there
is no second, out-of-band build description"*, and py satisfies it with one `pyproject.toml` while ts
already pays a two-file cost (`package.json` + `tsdown.config.ts`). Adopting `dist` reproduces
exactly that two-file cost in Rust — `Cargo.toml` plus `dist-workspace.toml` — which is the one
structural regression Rust otherwise avoids for free. It does not disqualify `dist` for R68's
question, where a second file may well be the right price for cross-compiled release artifacts. It
does mean the runner-up should not be sold as "a single readable statement of what we ship".

Two things must be re-checked before anyone acts on the winning condition: whether the
`[workspace.metadata.dist]` deprecation has become a removal at the version R68 would adopt, and
whether `dist`'s MSRV (`rust_version = "1.74"` on 0.32.0,
`GET https://crates.io/api/v1/crates/cargo-dist/versions`, 2026-09-10 — comfortably below any
plausible policy floor) still holds there.

**Second runner-up: the `cargo-xtask` pattern.** It wins only if the template accumulates
orchestration that is genuinely repository-specific and cross-platform-hostile in shell. Its own
README is honest that it is *"not an officially recommended workflow"* (2026-09-10), and this
repository already has `just` as its command runner (R42's resolved `package-manager-invocation`), so
a second orchestration mechanism would need a specific job that `just` cannot do.

### Tradeoffs

**Versus `dist`.** Gives up: generated cross-platform installer scripts, a generated release
workflow, and checksum and attestation plumbing. Why the cost is accepted: all of it is F214, which
**R68 owns and this item is explicitly forbidden to decide**; adopting `dist` here would pre-empt
that decision with a dependency. The maintenance signal does **not** support this tradeoff — `dist`
is `active`, with a 0.19-day median first maintainer response over the ten most recent issues — and I
say so rather than reaching for a health argument I measured my way out of. What does support it is
structural: `dist`'s configuration now lives in a separate `dist-workspace.toml`, the in-manifest
form being deprecated in 0.23.0, so adopting it here would trade Rust's one-file declaration for the
same two-file split ts already pays.

**Versus `cargo-xtask`.** Gives up: build orchestration expressed in Rust rather than in `just`
recipes, and the ability to bootstrap from `cargo` alone. Why accepted: the template already has a
command runner, and R42's resolved `package-manager-invocation` fixes how recipes invoke tools; a
second orchestration layer would contradict that decision's spirit for no gained capability.

**Versus a second `[[bin]]` with `required-features` (A2).** Gives up: a clean process boundary
between "CLI" and "server", separate binary sizes, and the ability to ship a server-only artifact.
Why accepted: the documented skip-when-feature-off behavior of `required-features` binaries silently
removes the target from default test builds (Cargo Book environment-variables reference, 2026-09-10),
which lands directly on R32's built-binary tier; and mdBook demonstrates a maintained CLI + library +
HTTP-server product that does not need the split. **This is the tradeoff most likely to be revisited**
— it is contingent on R69 and reversible for the price of one manifest block.

**Versus a workspace split (A3).** Gives up: enforced crate boundaries between core, CLI and server,
and independent versioning. Why accepted: R02 (`crate-boundary-enforcement`) owns the workspace-shape
question and is still `open`; deciding it here would be this item overreaching. Note the recommended
answer is **shape-neutral**: if R02 chooses a workspace, the `[lib]`/`[[bin]]`/`exclude` decisions
above move to the member packages unchanged, exactly as `typos` and `atuin` do it.

**Versus `include` instead of `exclude` (B4 fidelity).** Gives up: strict allow-list parity with py's
implicit layout bound and ts's `files: ["dist"]`, i.e. the strictest reading of the shared principle.
Why accepted: an allow-list in a *template* fails closed on the downstream user's new directories,
and R26 (`packed-artifact-content-guard`, F039/F078) can restore the allow-list guarantee at CI time
by asserting `cargo package --list` output — which is the better place for it, because a guard fails
loudly in CI whereas a wrong `include` fails silently for runtime assets.

### Parameters

`owns build-tool-output-shape = ` **target directory**: Cargo's default workspace-root `target/`,
with `target/debug/` for the `dev` profile and `target/release/` for `release`, overridable by
`CARGO_TARGET_DIR`, `build.target-dir` or `--target-dir`, and gaining a `target/<triple>/<profile>/`
level whenever `--target <triple>` is passed (Cargo Book, *Build Cache*, 2026-09-10).
**Library target**: exactly one, declared as `[lib]`, path `src/lib.rs`, crate name
`rs_launch_blueprint` (package name with `-`→`_`), producing `target/<profile>/librs_launch_blueprint.rlib`.
**Binary target**: exactly one, declared explicitly as `[[bin]]` with `path = "src/main.rs"` and a
short name that differs from the package name — **proposed** `rslbp`, subject to owner naming
confirmation — producing `target/<profile>/rslbp` (`rslbp.exe` on Windows) and exposing
`CARGO_BIN_EXE_rslbp` to integration tests.
**Packaged-file scope**: Cargo default (git-tracked, gitignore-respecting) **narrowed by an explicit
`exclude` deny-list**; no `include` allow-list; `Cargo.toml`, a minimized `Cargo.lock` and any
`license-file` are always included by Cargo regardless.
**Build backend/bundler dependency**: none. **`default-run`**: unset while there is one binary.

`assumes rust-edition = 2024` (fixed, `docs/port/PARAMETERS.md:8`) — load-bearing, because it implies
`resolver = "3"`.
`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as
rust-version in Cargo.toml and tested in CI` (fixed, `docs/port/PARAMETERS.md:7`) — the `rust-version`
field this item places in `[package]` is where that policy is declared.
`assumes license = MIT OR Apache-2.0` (fixed, `docs/port/PARAMETERS.md:10`) — becomes the `[package]
license` field.
`assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, `docs/port/PARAMETERS.md:9`).

**No `CONFLICT:` lines.** This item's `consumes:` list in the prompt's `## Couplings` is empty and my
recommendation requires no consumed parameter to change. Two *non-registry* assumptions are recorded
here for auditability rather than as dependencies, because the prompt lists both items as `related
(not a registry dependency)` or as owners of adjacent rows:

- If **R69** (`web-extra-surface`) resolves to a separate long-running server **process** rather than
  a subcommand, the binary-target count in `build-tool-output-shape` becomes 2 and a `default-run`
  line is added. Nothing else in this answer changes. I have not changed R69's parameter.
- If **R02** (`crate-boundary-enforcement`) resolves to a multi-crate workspace, these same fields
  move to the member manifests unchanged, and `build-tool-output-shape`'s target directory stays the
  single workspace-root `target/` (Cargo Book, *Build Cache*, 2026-09-10).

### Migration implications

There is nothing to migrate — no Rust source exists in `rs-launch-blueprint` yet. These are the
file-level changes P03 makes when it builds the template.

| File | Change |
|---|---|
| `Cargo.toml` (new) | `[package]` with `name`, `version`, `edition = "2024"`, `rust-version`, `license = "MIT OR Apache-2.0"`, `description`, `repository`, `homepage`, `readme`, and an explicit `exclude = [...]`; `[lib]` block; one `[[bin]]` block with `name` and `path`; `[features]` with the web gate (values owned by R69) |
| `src/lib.rs` (new) | the library target's root; hosts the R01 port trait, the R67 error catalog, and (feature-gated) the web module |
| `src/main.rs` (new) | the binary target's root; argument parsing, composition root, `fn main() -> ExitCode` |
| `README.md` (new) | one sentence recording the distribution-name/binary-name divergence and the install command — note the *content* of the install line follows F220, which tracks R68's artifact decision (`docs/port/COMMONALITY.md:224`) |
| `.gitignore` (new) | `target/` — Cargo already excludes it from the package, but keeping it out of git keeps the default packaged set correct for anyone who later drops `exclude` |
| `justfile` | gains `package` / `publish-dry-run` recipes invoking `cargo package --list` and `cargo publish --dry-run`, written per R42's resolved `package-manager-invocation` (built-in Cargo subcommands written as-is, no runner prefix) |
| CI workflow | **not changed by this item.** Whether `cargo package --list` output is asserted belongs to R26 (F039/F078); whether an installed binary is smoke-tested belongs to R50 (F221/F222) |

Two follow-on consumers of `build-tool-output-shape` get concrete values from the table above: R22
(`runtime-version-accessor`) can read `env!("CARGO_PKG_VERSION")` — *"The full version of your
package"*, set when crates are compiled (Cargo Book environment-variables reference, 2026-09-10) —
and R32's built-binary tier can resolve the executable through `env!("CARGO_BIN_EXE_rslbp")` without
hardcoding a path or a profile.

### Validation strategy

All of the following are **proposed** checks against the template P03 will build. **None has been
executed**, because no Rust source tree exists in this repository; running them today would produce
no output to report, and I have not fabricated any.

```
# AC1 — exactly one lib target and one bin target, with the recorded names
cargo metadata --no-deps --format-version 1 \
  | jq -e '[.packages[0].targets[] | select(.kind[0]=="lib")] | length == 1'
cargo metadata --no-deps --format-version 1 \
  | jq -e '[.packages[0].targets[] | select(.kind[0]=="bin")] | length == 1'
cargo metadata --no-deps --format-version 1 \
  | jq -r '.packages[0].targets[] | select(.kind[0]=="bin") | .name'   # expect: rslbp

# AC2 — the release binary lands where build-tool-output-shape says it does
cargo build --release && test -x target/release/rslbp

# AC3 — the packaged file list matches intent (allow-list asserted at CI time, not in the manifest)
cargo package --list --allow-dirty            # expect: Cargo.toml, Cargo.lock, src/**, LICENSE*, README.md
cargo package --list --allow-dirty | grep -E '^(\.github|docs|research)/' && exit 1   # expect: no match

# AC4 — the archive builds from a pristine extraction (cargo package step 3)
cargo publish --dry-run

# AC5 — the binary count does not change with the web feature
cargo build --no-default-features && ls target/debug/rslbp
cargo build --features web         && ls target/debug/rslbp

# AC6 — an integration test resolves the binary with no non-default feature enabled
#   tests/cli.rs:  let exe = env!("CARGO_BIN_EXE_rslbp");
cargo test --test cli
```

**Expected behavior and what each proves.** AC1 proves B2 (library and executable are separately
named outputs) and pins the value R32 and R68 consume. AC2 proves the `build-tool-output-shape`
target-directory claim against the Cargo Book's documented layout. AC3 proves B4 — that the packaged
set is bounded by declaration; it is written as two assertions because a positive-only check passes
trivially. AC4 is Cargo's own verification build, documented as step 3 of `cargo package`
(<https://doc.rust-lang.org/cargo/commands/cargo-package.html>, 2026-09-10), and is the strongest
single check available: it fails if `exclude` removed anything the build needs. AC5 proves the
feature gate does not change the artifact *shape*, which is the property R68's release matrix depends
on. AC6 proves the `required-features` footgun was avoided — it is the check that would fail under
architectural alternative A2. Both AC3 assertions and AC4 should run in the release lane rather than
the default check loop, because AC4 is a full clean rebuild; **where exactly they are wired is R26's
and R11's decision, not this item's.**

A useful negative check, also proposed: temporarily adding `required-features = ["web"]` to the
`[[bin]]` block must make AC6 fail with an unset `CARGO_BIN_EXE_rslbp`. That is the executable form
of the tradeoff argued above, and it is worth running once in P03 to confirm the reasoning holds on
the toolchain of the day rather than only in the documentation.

### Confidence & re-verify trigger

**High confidence** in the core recommendation (Cargo-native declaration, no added dependency; one
`[[bin]]` + one `[lib]`; explicit `exclude`; name divergence acceptable). It rests on normative
rust-lang documentation rather than on opinion, and on seven well-regarded projects' shipped
manifests that agree with each other. The structural claim — that Rust has no pluggable build backend
to substitute for `uv_build` — is not a judgement call.

**Medium confidence** in two sub-decisions:

1. **Web behind a feature rather than a second binary.** Contingent on R69, which is unresolved. The
   evidence (mdBook + the documented `required-features` skip behavior) is good but the requirement
   is not yet known.
2. **`exclude` rather than `include`.** A 7:1 practice split and a template-specific failure-mode
   argument, against a strict-principle-fidelity argument for `include`. Reasonable people land
   either way; the R26 CI guard makes the choice low-stakes.

**Low confidence / explicit gap.** The proposed binary name `rslbp` is a naming proposal derived by
analogy from py's `plbp`, not a research finding. It needs an owner decision.

**Re-verify triggers.**

- **R69 resolves.** If the web surface becomes a separate process, revisit `### Fit for this
  template` (web) and add a second `[[bin]]` plus `default-run` to `build-tool-output-shape`.
- **R68 resolves F214 to cross-compiled release binaries.** Re-run the `dist` figures and check
  whether the `[workspace.metadata.dist]` deprecation (0.23.0) has become a removal; the
  responsiveness measurement recorded here covers roughly three months of issue history and will have
  moved. Measure maintainer responsiveness **by login, not by `author_association`** — the active
  maintainer comments as `CONTRIBUTOR`, and the association filter produces a false `at-risk` reading,
  as it did on my first pass.
- **R02 resolves to a workspace.** Re-read `### Parameters` — the fields move to member manifests and
  `[workspace.package]` inheritance (as `mdBook`, `ripgrep`, `typos` and `atuin` all do) becomes the
  right expression.
- **A Rust edition beyond 2024 is adopted.** Edition changes have twice altered `Cargo.toml`
  semantics (the 2024 edition removed `[project]`, `default_features`, `crate_type`, `proc_macro`,
  `dev_dependencies` and `build_dependencies` per the Edition Guide, 2026-09-10); any future edition
  bump requires re-reading the manifest reference.
- **Routine staleness.** Re-verify every crates.io and GitHub figure in this report if it is more than
  90 days old, since `crate.recent_downloads` is itself a 90-day window.

### Sources

Repository and ledger (read 2026-09-10):
- `docs/port/COMMONALITY.md:214-226` — F210–F220 rows, verdicts and ownership.
- `docs/port/areas/packaging-distribution.md:7-17` — per-row py/ts evidence for F211–F219.
- `docs/port/PARAMETERS.md:5-17` — owner-fixed parameters and the `build-tool-output-shape`,
  `web-extra-surface`, `http-transport-injection-seam`, `error-taxonomy-exit-codes` and
  `package-manager-invocation` rows.
- `docs/port/BASELINE-REVIEW.md:102` — F211 retained, `cargo package` cited as the pattern's Rust
  realization.
- `research/CLAUDE.md` — R49 row (kind `crate`, verdict `COMMON → SUBSTITUTE`, owns
  `build-tool-output-shape`), R02, R26, R50, R68, R69 rows.

Pinned source repositories (read through their pins, 2026-09-10):
- py `pyproject.toml:120,130-141` via `git -C ~/c/py-launch-blueprint show b08bccfb:pyproject.toml` —
  `[project.scripts] plbp = "py_launch_blueprint.cli.main:cli"`, `requires = ["uv_build>=0.5,<1.0"]`,
  `build-backend = "uv_build"`, `[tool.uv.build-backend] module-name = "py_launch_blueprint"`,
  `module-root = "src"`.
- py `README.md:45` via the same pin — `uvx --from py-launch-blueprint plbp` with the parenthetical
  *"(uvx needs `--from` because the distribution name differs from the console-script name)"*.
- ts `package.json:1-28` and `tsdown.config.ts:1-19` via
  `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` — `"bin": {"ts-projects": "dist/cli.js"}`,
  `"files": ["dist"]`, root-only `exports` map, and
  `defineConfig({ entry: ['src/cli.ts','src/lib.ts'], format: 'esm', fixedExtension: false, dts: true, sourcemap: true, clean: true })`.

Normative documentation (all retrieved 2026-09-10):
- <https://doc.rust-lang.org/cargo/reference/cargo-targets.html> — target auto-discovery, `name`/
  `path` defaults, `required-features`, `crate-type`, `doc`/`test`, `[[bin]]` as array-of-tables.
- <https://doc.rust-lang.org/cargo/reference/manifest.html> — `include`/`exclude` semantics and
  defaults, always-included and always-excluded files, `default-run`, `rust-version`, `publish`.
- <https://doc.rust-lang.org/cargo/commands/cargo-package.html> — the four packaging steps,
  `.cargo_vcs_info.json`, always-included `Cargo.lock`, `--list`, `--no-verify`.
- <https://doc.rust-lang.org/cargo/commands/cargo-install.html> — `--bins` is the default, `--bin`
  installs a subset, install root resolution, *"Libraries cannot be installed with `cargo install`."*
- <https://doc.rust-lang.org/cargo/reference/publishing.html> — required metadata fields, the 10MB
  `.crate` size limit, `cargo package --list` / `cargo publish --dry-run`, publish permanence.
- <https://doc.rust-lang.org/cargo/reference/environment-variables.html> — `CARGO_BIN_EXE_<name>` and
  its `required-features` caveat, `CARGO_PKG_VERSION`, `CARGO_PKG_NAME`, `CARGO_CRATE_NAME`,
  `CARGO_TARGET_DIR`, `CARGO_MANIFEST_DIR`.
- <https://doc.rust-lang.org/cargo/reference/build-cache.html> — `target/`, `target/debug/`,
  `target/release/`, `target/<triple>/<profile>/`, and the three override mechanisms.
- <https://doc.rust-lang.org/cargo/guide/project-layout.html> — the recommended package layout tree.
- <https://doc.rust-lang.org/edition-guide/print.html> — 2024-edition Cargo changes: `resolver = "3"`
  implication, table/key-name removals, inherited `default-features` rejection.
- <https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/> — 2025 State of Rust
  survey results (7156 responses); cited as an authority for community scale only, no figure taken.

Endpoints queried for figures (all 2026-09-10 unless the value itself carries a date):
- `GET https://crates.io/api/v1/crates/<name>` for `crate.recent_downloads` and `crate.downloads`:
  `cargo-dist` (19922 / 175385), `cargo-binstall` (125820 / 3483662), `cross` (307766 / 6269217),
  `cargo-zigbuild` (1547057 / 7034852), `cbindgen` (13646147 / 101705742),
  `cargo-packager` (47349 / 178600), `wasm-pack` (1314325 / 6041069), `maturin` (83693 / 1067668),
  `dist` (58 / 3150 — an unrelated 2016 placeholder, `max_stable_version` 0.0.0), `xtask` (953 / 953).
- `GET https://crates.io/api/v1/crates/<name>/versions`, newest non-yanked `num`/`created_at`/
  `license`/`rust_version`: `cargo-dist` 0.32.0 2026-05-22T05:58:59Z MIT OR Apache-2.0 rv 1.74;
  `cargo-binstall` 1.23.0 2026-09-05T16:59:01Z GPL-3.0-only rv 1.79.0; `cross` 0.2.5
  2023-02-04T17:28:19Z MIT OR Apache-2.0; `cargo-zigbuild` 0.23.4 2026-09-02T13:50:57Z MIT rv 1.88;
  `cbindgen` 0.29.4 2026-06-09T19:03:00Z MPL-2.0 rv 1.74; `cargo-packager` 0.11.8
  2025-11-27T12:39:29Z Apache-2.0 OR MIT.
- `GET https://api.github.com/repos/<o>/<r>` for `stargazers_count`/`archived`/`pushed_at`/`license`:
  `rust-lang/cargo` 15462 / false / 2026-09-08T15:46:17Z; `axodotdev/cargo-dist` 2112 / false /
  2026-09-08T10:07:06Z; `cargo-bins/cargo-binstall` 2864 / false / 2026-09-10T01:22:53Z;
  `cross-rs/cross` 8313 / false / 2026-08-19T12:01:59Z; `rust-cross/cargo-zigbuild` 2647 / false /
  2026-09-09T12:21:42Z; `mozilla/cbindgen` 2947 / false / 2026-08-22T18:46:24Z;
  `crabnebula-dev/cargo-packager` 477 / false / 2026-09-09T14:14:09Z; `matklad/cargo-xtask` 1319 /
  false / 2025-10-28T14:42:08Z; `BurntSushi/ripgrep` 68148; `rust-lang/mdBook` 22127;
  `casey/just` 35726; `sharkdp/bat` 60399; `crate-ci/typos` 4125; `atuinsh/atuin` 31579;
  `bytecodealliance/wasmtime` 18616 / false / 2026-09-09T21:26:59Z;
  `bazelbuild/rules_rust` 840.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → `total_count`:
  `axodotdev/cargo-dist` 297; `cargo-bins/cargo-binstall` 93; `cross-rs/cross` 228;
  `rust-cross/cargo-zigbuild` 3; `mozilla/cbindgen` 225; `crabnebula-dev/cargo-packager` 35.
- `GET https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue&sort=created&order=desc&per_page=10`
  plus `GET https://api.github.com/repos/axodotdev/cargo-dist/issues/<n>/comments` for each — issues
  #2504, #2492, #2489, #2457, #2456, #2446, #2444, #2443, #2442, #2437. Measured **by login**:
  `mistydemeo` answered 6 of the 10, median 0.19 days to first response, 4 unanswered (per-issue
  timestamps in `### Qualified shortlist`). Measured by `author_association` the same ten return zero
  MEMBER/OWNER/COLLABORATOR comments — a filter artifact, since `mistydemeo` comments as
  `CONTRIBUTOR`; the by-login figure is the one this report relies on.
- `https://raw.githubusercontent.com/cross-rs/cross/main/README.md` — `cross`'s Dependencies section
  (Docker 20.10+ or Podman 3.4.0+, daemon must be started before use).
- `GET https://api.github.com/repos/actions/runner-images/contents/images/macos/macos-15-Readme.md`
  and `.../images/ubuntu/Ubuntu2404-Readme.md` — no `docker`/`podman`/`colima` entry in the macOS
  image manifest; "Docker Client 28.0.4" and "Docker Server 28.0.4" in the Ubuntu 24.04 manifest.
- <https://blog.rust-lang.org/2025/02/20/Rust-1.85.0/> — Rust 1.85.0 stabilizes the 2024 edition.
- <https://axodotdev.github.io/cargo-dist/book/workspaces/structure.html> — `dist`'s workspace
  configuration file is `dist-workspace.toml`, with `Cargo.toml`'s `[workspace.metadata.dist]`
  "deprecated in 0.23.0". The `opensource.axo.dev` host that the project's book links point at
  returns NXDOMAIN (`host opensource.axo.dev`, 2026-09-10); the GitHub Pages copy above serves.
- `GET https://api.github.com/repos/atuinsh/atuin/contents/dist-workspace.toml` and
  `GET https://api.github.com/repos/astral-sh/uv/contents/dist-workspace.toml` — both present;
  `https://raw.githubusercontent.com/atuinsh/atuin/main/dist-workspace.toml` shows
  `[workspace] members = ["cargo:."]` and `[dist] cargo-dist-version = "0.31.0"`.
- `GET https://api.github.com/repos/axodotdev/cargo-dist/commits` and `/releases` — maintainer commit
  by `mistydemeo` 2026-09-04T19:47:56Z; releases v0.32.0 2026-05-22 and v0.31.0 2026-02-23.
- `https://rustsec.org/packages/<name>.html` — **HTTP 404** (no advisory record) for `cargo-dist`,
  `cargo-binstall`, `cross`, `cargo-zigbuild`, `cbindgen`, `cargo-packager`.
- `https://raw.githubusercontent.com/<o>/<r>/<branch>/Cargo.toml` for the manifests quoted in the
  practice table: `rust-lang/mdBook`, `rust-lang/cargo`, `BurntSushi/ripgrep`,
  `bytecodealliance/wasmtime`, `sharkdp/bat`, `casey/just`, `crate-ci/typos`, `atuinsh/atuin`
  (root and `crates/atuin/Cargo.toml`).
- `https://raw.githubusercontent.com/axodotdev/cargo-dist/main/README.md` and
  `https://raw.githubusercontent.com/matklad/cargo-xtask/master/README.md`.

**Method notes.** I queried crates.io (`/api/v1/crates/<name>` and `/versions`, with a User-Agent
header), the GitHub REST API (`/repos/<o>/<r>`, `/search/issues`, `/issues/<n>/comments`, `/commits`,
`/releases` — authenticated through the local `gh` CLI after the unauthenticated endpoint returned
`API rate limit exceeded`), `rustsec.org/packages/<name>.html`, `doc.rust-lang.org` (the Cargo Book
and the Edition Guide), `blog.rust-lang.org`, and `raw.githubusercontent.com` for reference
manifests. **What I could not verify:** (1) any latency, throughput, binary-size
or compile-time **measurement** — no Rust source exists in `rs-launch-blueprint`, so every
performance statement in this report is qualitative and labelled as such, and no benchmark was run;
(2) whether `mistydemeo` holds a formal maintainer role — GitHub reports
`author_association: CONTRIBUTOR`, so I infer maintainer standing from direct commits to `main` plus
consistent issue triage rather than from a declared role, and I flag that inference rather than
asserting the role; (3) whether the four unanswered `cargo-dist` issues reflect a triage policy or a
backlog — I found no maintainer notice either way and report the measurement, not a cause; (4) the
`rust-lang/mdBook` and `rust-lang/cargo` release cadences on crates.io, which I did not need and did
not query; (5) `median days to first maintainer response` for candidates other than `cargo-dist` —
not measured, because every other candidate was excluded by gate or by scope before popularity or
responsiveness would have been weighed. **One figure in this report was measured, written into an
earlier draft, and then withdrawn**: the "0 of 10 issues answered by a maintainer" reading of
`cargo-dist`, an `author_association` filter artifact. The corrected by-login measurement (6 of 10
answered, median 0.19 days) is in `### Qualified shortlist`, the maintenance verdict was changed from
`at-risk` to `active`, and every argument that had rested on the withdrawn figure was rewritten rather
than left standing. Every figure above names the endpoint that produced it, and none was carried over
from memory.
