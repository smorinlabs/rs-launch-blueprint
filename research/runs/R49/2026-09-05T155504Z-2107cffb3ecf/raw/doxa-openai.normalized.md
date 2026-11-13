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
