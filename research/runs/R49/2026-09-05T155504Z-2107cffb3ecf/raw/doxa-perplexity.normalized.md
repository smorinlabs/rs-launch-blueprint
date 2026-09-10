# Build-Target Declaration for `rs-launch-blueprint`: Cargo Manifest Design for CLI · Library · Web Service

The recommended design for `rs-launch-blueprint` is a single Cargo package that uses Cargo’s native target system as its “build backend,” declaring one library target and one primary CLI binary, with an optional second binary entry point for the web service gated behind a feature flag. Cargo’s built-in `[lib]` and `[[bin]]` target tables fully replace the specialized build backends used in the Python and TypeScript ports, so no separate bundler or backend crate is required for the baseline template, though repository-local automation tools such as the `xtask` pattern can be layered on top for more complex release orchestration if future requirements demand it.[1][2][3][12][16] The manifest should declare the library explicitly with `[lib]` and the CLI with a `[[bin]]` whose `name` matches the crate name to avoid any distribution-name-vs-binary-name divergence, while any web-service entry point is exposed as a second `[[bin]]` that uses `required-features = ["web-service"]` so that it is only built when the web feature is enabled.[1][7] For packaging scope, the template should consciously rely on Cargo’s default behavior—publishing all non–version-control-ignored files in the crate directory—rather than adding an `include` or `exclude` whitelist, because the template is source-only and does not ship large assets or auxiliary tooling; this choice must be documented as deliberate, echoing the “forest before trees” principle rather than being an accident of omission.[8][14][11] This alignment preserves the shared architectural principle from the Python and TypeScript implementations—explicit build entries and a controlled packaging surface—using idiomatic Rust patterns, while keeping the manifest simple enough that if this answer proves wrong, rewriting `[package]`, `[lib]`, `[[bin]]`, and any `include`/`exclude` keys remains straightforward and localized.

## Context

### Landscape

The category this item decides is the **build-target declaration and packaging shape for a Rust crate that serves as a CLI, reusable library, and optional web service**. In Rust, this category spans the manifest-level definition of build outputs, entry points, and packaging scope, as well as any auxiliary build orchestration patterns that sit alongside Cargo’s native behavior. At a high level, the Rust ecosystem provides a clear stratification of tools and patterns for this category: Cargo’s built-in target system and manifest format, first-party and near-first-party patterns like `xtask` and `cargo bench` for automation and performance testing, and third-party release orchestration tools such as `cargo-dist` and task runners like `cargo-make` that build on top of Cargo rather than replacing it.[1][2][3][9][12][16][17][18]

In the **built-in or first-party toolchain** bin, the central authority is Cargo itself. Cargo defines the concept of a package and its targets, where each target corresponds to a source file compiled into a crate.[1] The official Cargo book and manifest reference specify that packages can have library, binary, example, test, and benchmark targets, all declared via manifest tables such as `[lib]` and `[[bin]]`.[1][2][3] These tables describe how each target should be built, including its name, source path, test and bench flags, documentation behavior, and required features.[1][2][3][7] Cargo is also the native build and package manager, and for Rust this means there is no analogue to Python’s PEP 517 “build backend” or TypeScript’s bundler at the level of basic crate compilation; Cargo is both build system and package generator. The RFC introducing `cargo install` reinforces Cargo’s role as the manager of locally installed binary crates, highlighting that only packages with `[[bin]]` targets are installable and that Cargo handles building and installing them into the user’s `$HOME/.cargo/bin` directory or the configured `CARGO_HOME`.[4][5][6]

The **established industry standard** bin gathers patterns and tools that are widely used but still subordinate to Cargo. The `cargo-xtask` pattern is one such pattern: instead of using shell scripts or Makefiles, a repository declares an `xtask` crate and a Cargo alias so that `cargo xtask <cmd>` runs automation tasks as ordinary Rust programs.[12] This pattern keeps build automation and release chores inside the Rust ecosystem, with pure logic separated from orchestration, and is increasingly common in well-maintained Rust repositories.[12][16] The official Cargo commands for testing and benchmarking, such as `cargo bench`, also exemplify established practice: benchmarks are compiled as special executables linked against Rust’s `libtest`, and Cargo controls which targets are benchmarked via the manifest `bench` flags and target selection options.[13] On the release side, `cargo-dist` (now branded simply as `dist`) is an established tool for packaging and distributing binaries built from Cargo projects, integrating with GitHub Releases and performing artifact attestation and SBOM generation.[9][18] It orchestrates builds across multiple target platforms using configuration in `dist-workspace.toml`, but consumes Cargo targets as inputs rather than altering how they are declared.[9]

The **up-and-comer** bin includes newer tools and patterns for crate distribution and build orchestration. The rebranding of `cargo-dist` to `dist` and its evolution into a more comprehensive packaging system is one example; its documentation emphasizes shippable application packaging, splitting functionality into planning, building, hosting, and publishing.[18] Another example is `crates-io-proxy`, which implements transparent caching for the crates.io sparse index and crate downloads and uses Cargo’s source replacement feature to redirect registry traffic to a mirror, again operating around Cargo rather than within its manifest logic.[19] These tools are relevant to the broader release and distribution picture but do not change the basic manifest-level declaration of targets and packaging scope.

Regarding **authoritative sources**, several stand out and have been used as anchors for this analysis. The official Cargo documentation—the Cargo book and reference—is authoritative because it is maintained by the Rust project and defines the canonical semantics of Cargo’s behavior.[1][2][3][6][13] The RFC 1200 document introducing `cargo install` is authoritative on the design and intent of binary installation because it reflects consensus among Rust’s developers and has been implemented in stable Cargo.[4] The Debian Rust Team’s guidance on disabling tests and benchmarks in `Cargo.toml` is authoritative for downstream packaging practice and shows how Cargo options are used in large-scale distribution systems; it is maintained by a group responsible for integrating Rust into a major Linux distribution.[15] Documentation of ecosystem patterns like `xtask` and `cargo-dist` is authoritative for those tools because it is maintained by their authors and widely cited in discussions of Rust build automation and binary distribution.[9][12][16][18] Finally, community discussions about what to include when publishing crates, such as the Rust users forum thread on include/exclude decisions, provide practice evidence and are considered as a form of peer-reviewed operational guidance.[11]

The **practice evidence** for this category is somewhat indirect in the sources provided, because we do not have direct manifest samples from named flagship projects in this prompt. However, the broader Rust ecosystem exhibits clear norms. The Cargo documentation itself describes how library targets default to `src/lib.rs` and binary targets default to `src/main.rs` and `src/bin/*.rs`, and the existence of these defaults reflects common practice: most crates rely on these conventions without needing specialized build backends.[1][7] The manifest reference’s emphasis that only one `[lib]` may be specified per package, while many `[[bin]]` tables are allowed, indicates that the idiomatic pattern for a library-plus-CLI crate is a single library with multiple binaries.[1][2][3] The Debian Rust Team’s need to sometimes disable benchmarks, doctests, and auto-tests for packaging further suggests that many crates include tests, examples, and benches in their published packages by default, and that this is considered normal unless resource constraints force a change.[15] The documentation for task runners like `cargo-make` shows that more complex build flows are usually declared externally in separate configuration files rather than in `Cargo.toml`, reinforcing that manifest-level target declaration is kept focused on compile outputs and not general automation.[17]

In terms of fit, these patterns align well with `rs-launch-blueprint`’s requirements. The template must support three surfaces—CLI, library, and optional web service—while keeping the manifest comprehensible and modifiable if this answer fails the value test. Cargo’s native targets provide exactly the hooks needed: `[lib]` for the reusable library, one or more `[[bin]]` entries for executable entry points, and optional `[[example]]`, `[[test]]`, and `[[bench]]` entries if the template later grows special-purpose examples or performance harnesses.[1][2][3][7] Release and cross-compilation concerns can be addressed via tools like `cargo-dist` and repository-local `xtask` without impacting the manifest-level question R49 owns.[9][12][16][18] That separation of concerns mirrors the Python and TypeScript ports: the template’s manifest declares build targets and packaging scope, while other items decide how binaries are cross-compiled, tested, and distributed.

## Design principles

### Principles and implementation

The shared requirement behind R49 can be stated as follows: **the template must declare, in its native build system, an explicit set of build outputs and entry points that correspond to a CLI executable, a reusable library, and an optional web service, while defining the packaging scope of the distributable unit and documenting any divergence between distribution name and entry-point names.** This requirement emerges from the owner’s mandate to identify the shared engineering principle across the Python and TypeScript implementations and apply it in the Rust ecosystem, with a clear distinction between capability-level agreement and ecosystem-specific variations.

In the Python port, the shared principle manifests as an explicit build backend and entry-point declaration in `pyproject.toml`. The project uses `uv_build` as a PEP 517 backend, which is the tool responsible for turning source into wheels and sdists.[Context] The build unit is the module package rooted at `module-root`, and the CLI entry point is declared via `[project.scripts]` as a callable reference, `plbp = "py_launch_blueprint.cli.main:cli"`, giving a specific function in a specific module.[Context] The packaging scope of the wheel is implicitly bounded by the package root and the build-backend’s configuration; the template does not need to enumerate files explicitly. The distribution-name-vs-entry-point-name divergence appears as `uvx --from py-launch-blueprint plbp`, where the distribution (project) name differs from the script name, requiring an install-time selector.[Context]

In the TypeScript port, the same principle is realized differently. The build backend is the `tsdown` bundler (a successor to tsup), configured via a `tsdown.config.ts` file that declares explicit `entry` points for `src/cli.ts` and `src/lib.ts`, producing separate bundles.[Context] The console script is declared in `package.json` via the `bin` field, mapping a command name, `"ts-projects"`, to a built file path, `"dist/cli.js"`.[Context] The packaging scope is explicitly controlled by a `files: ["dist"]` array, which whitelists the `dist` directory as the only content included in the published npm package.[Context] Distribution name and bin name diverge: the package is called `ts-launch-blueprint`, while the installed executable is `ts-projects`, but npm’s `bin` mapping resolves this without any special flag at install time.[Context]

The Rust analogue must honor the same principle: **explicit build entry points and a consciously defined packaging surface**, while respecting Rust’s ecosystem-specific architecture. Here, the architectural locus is Cargo. Cargo packages consist of targets that correspond to source files compiled into crates, and a package may have library, binary, example, test, and benchmark targets under the same `Cargo.toml`.[1] The library target is declared with `[lib]` and defines a library that can be used and linked by other libraries and executables; its filename defaults to `src/lib.rs`, and its name defaults to the package name with dashes replaced by underscores.[1][2][3] Binary targets are executable programs declared via `[[bin]]`, with default source locations `src/main.rs` or `src/bin/*.rs`, and their default binary names follow the package name unless overridden.[1][2][3] Binaries are linked against the package’s library and dependencies, and each `[[bin]]` table can customize settings such as name, path, test/bench flags, and `required-features`.[1][2][3][7]

The first design question is whether Cargo’s native target system fully replaces Python’s build backend and TypeScript’s bundler in this template. The answer is yes for the core compile and package step. Cargo is both build system and packager: running `cargo build` compiles the library and binaries, and `cargo publish` generates and uploads a `.crate` file to crates.io, which clients download and build locally.[1][6][19] There is no need for a separate “build backend” crate to produce the distributable package; Cargo is the backend, and this is reinforced by the manifest reference and RFCs.[1][2][3][4][6] This does not preclude auxiliary tools, but they are not part of R49’s decision. Tools like `cargo-dist` sit on top of Cargo to create platform-specific artifacts, installers, and checksums, using the existing crate as input.[9][18] The `xtask` pattern likewise orchestrates repo-local build tasks via a dedicated `xtask` crate and Cargo aliases, but it does not redefine how targets are declared in `Cargo.toml`; it calls `cargo build`, `cargo test`, and other commands as subprocesses.[12][16]

Given that Cargo itself is the build backend, the Rust analogue of TypeScript’s explicit `entry` list is the manifest’s explicit `[lib]` and `[[bin]]` tables. A minimal adaptation of the principle would declare a library target with a known path (typically `src/lib.rs`) and a binary target with a known path (typically `src/main.rs` or `src/bin/cli.rs`), each with an explicit `name` so that entry-point names are controlled rather than implicit.[1][2][3][7] The optional web service surface can either be integrated into the CLI binary (for example, via a `serve` subcommand) or exposed as a separate `[[bin]]` entry, such as `rs-launch-blueprint-web`, whose `required-features` field ensures that it is only built and installed when the `web-service` feature is enabled.[1][7] This makes the manifest’s entry points explicit and composable in the same spirit as TypeScript’s multiple `entry` bundles.

For console-script semantics, Rust does not require a separate “entry point” abstraction similar to Python’s `module:function` mapping. The `[[bin]]` `name` and `path` fields specify an executable compiled from Rust code; the `main` function in that source file is the program’s entry point, and Cargo passes control to it at runtime.[1] The `cargo install` command treats all executable `[[bin]]` targets as installable binaries, copying them into the installation root’s `bin` directory and making them available in the user’s PATH.[4][5][6] If a crate has multiple binaries, the `--bin` argument can selectively install only one, mirroring Python’s need to specify a script name in some contexts.[4][5][6] However, for the template’s primary CLI, the idiomatic choice is to have a single `[[bin]]` whose `name` matches the crate name, making `cargo install rs-launch-blueprint` followed by invoking `rs-launch-blueprint` directly behave naturally without any indirection. The path field, such as `src/bin/cli.rs`, is the Rust analogue of `entry: 'src/cli.ts'` or `main: './dist/cli.js'` in the other ecosystems.

Packaging scope is the final core principle. Cargo’s default behavior when publishing a crate is to include all files under the package directory except those ignored by version control, and the manifest’s `exclude` and `include` keys allow further control over which globs are packaged and considered for rebuilds.[8][14] The `exclude` field lists globs of files that are not included when a package is published and are ignored for rebuild detection; conversely, the `include` field lists files explicitly included, and if `include` is set it overrides `exclude`.[8][14] Community guidance suggests that many crate authors rely on this default, publishing tests, examples, benches, and CI configurations unless they are particularly large or irrelevant, though some prefer to exclude heavy test data or benchmark directories.[8][11][14] For this template, which is source-only and does not include large binary assets, the simplest and most maintainable choice is to rely on Cargo’s default packaging behavior and document that choice as deliberate. This approach maintains consistency with the Python and TypeScript ports’ principle of controlling package content but recognizes that Rust’s source distribution model and crates.io’s expectations make an explicit whitelist less necessary for a small template crate.

The observable acceptance criteria for R49 can be articulated as follows. First, **build-target clarity**: the manifest must declare a library and at least one binary entry point, with explicit `name` and `path` such that their roles are obvious to maintainers and template consumers. Second, **Cargo-native behavior**: invoking `cargo build`, `cargo test`, and `cargo install` on the template must succeed without any nonstandard build backend, using only Cargo’s default semantics for targets and packaging.[1][6] Third, **entry-point usability**: after `cargo install rs-launch-blueprint`, the primary CLI binary must be invocable directly via its name without extra flags or wrappers, and if the web-service binary is installed, its name and feature gating must be clear. Fourth, **packaging scope transparency**: the set of files included in the `.crate` generated by `cargo publish` must be predictable and documented, with any deviations from Cargo’s default declared via `include` or `exclude` and justified. Fifth, **rewritability**: because the owner has mandated that incorrect answers trigger a manifest rewrite, the recommended design must keep `[package]`, `[lib]`, `[[bin]]`, and packaging keys locally editable and not entangled with external tooling.

Within this framework, Python’s and TypeScript’s architectural pattern—explicit build entries, controlled package content, and recognized distribution-vs-entry-name semantics—remains appropriate in Rust, but its realization is via Cargo’s manifest and features rather than external build backends or bundlers. No additional backend is required at the crate level; repo-level orchestration tools are optional extensions that other rows (such as R68 and R50) may consider independently.

## Choices

### Dominant choice

Given the landscape and principles, the dominant architectural choice for `rs-launch-blueprint` is to treat **Cargo’s manifest as the sole build-target declaration and packaging surface**, with the following key elements:

The crate is a single Cargo package whose `[package]` section declares the crate metadata, edition, MSRV via `rust-version`, and license as `MIT OR Apache-2.0`, in line with the owner’s fixed parameters.[2] A `[lib]` target is explicitly declared, even though Cargo would infer `src/lib.rs` by default, to lock in the library’s name and path and make it clear that the library is the central reusable surface.[1][2][3][7] The library’s `name` is the underscore version of the crate name, for example `rs_launch_blueprint`, which matches Cargo’s default convention and keeps public API imports predictable.[1][2][3]

The primary CLI is exposed via a `[[bin]]` target whose `name` matches the crate’s name, such as `rs-launch-blueprint`, and whose `path` is `src/bin/cli.rs` (or `src/main.rs` if a single-binary layout is preferred).[1][2][3][7] This explicit `[[bin]]` declaration is the Rust analogue of TypeScript’s explicit CLI entry in the bundler configuration and Python’s `[project.scripts]` mapping: it names the executable that Cargo will build and install and points to the source file where its `main` function resides.[1][4][5][6] Because the `name` equals the crate name, users can install and run the CLI without any additional information: `cargo install rs-launch-blueprint` builds and installs the binary, and `rs-launch-blueprint` runs it.[4][5][6]

The optional web service is represented as a second `[[bin]]` target, such as `rs-launch-blueprint-web`, whose `path` is `src/bin/web.rs` and whose `required-features` contains a single feature, `"web-service"`. This configuration uses Cargo’s support for `required-features` on targets, which ensures that the web-service binary is built only when the specified feature is enabled, either via `cargo build --features web-service` or `cargo install --features web-service`.[1][7] This is the Rust analogue of a separate bundle entry for a web surface, guarded by a build-time flag. It keeps web-specific dependencies (e.g., HTTP server libraries) off the default build path and respects the template’s optional “web extra surface” nature.

The manifest does not declare an explicit `include` or `exclude` field for packaging. Instead, it relies on Cargo’s default behavior, in which Cargo ignores files listed in version control ignore files and otherwise includes source files and manifest in the published crate.[8][14] This choice is justified by the template’s small size and absence of large assets. It is documented in the template’s port documentation as the deliberate Rust analogue of Python’s implicit package-root bounding and TypeScript’s `files: ["dist"]`, noting that Rust’s source distribution model and local build semantics reduce the need for an explicit whitelist.[8][11][14]

No external build backend crate is used. Cargo itself is the backend, and compile-time automation beyond standard commands is reserved for repository-local tools such as `xtask` or external release automation like `cargo-dist`, which are outside R49’s scope.[1][4][6][9][12][16][18] This keeps the manifest self-contained and allows other items (R68, R50) to choose more sophisticated release and smoke-test strategies.

This dominant choice preserves the pattern of explicit entry points and packaging surface control while minimizing external dependencies and keeping the manifest clear. It also aligns tightly with the owner’s acceptance criteria: it uses stable Rust with edition 2024, declares MSRV in `Cargo.toml`, and works on both `ubuntu-latest` and `macos-latest` because it relies only on core Cargo behavior.[2][6][13]

### Qualified shortlist

Even though the dominant choice is clear, it is useful to articulate a shortlist of alternatives that passed the basic fitness gates and could be adopted under different circumstances. Because R49 concerns an architectural pattern rather than a specific external crate dependency, the candidates are patterns built on Cargo’s manifest system. For each, metrics such as downloads or GitHub stars are inapplicable or unavailable within this environment, and this is noted explicitly.

The table below summarizes the qualified shortlist:

| Candidate | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| Single package with explicit `[lib]` and `[[bin]]` targets (dominant choice) | Declare library + CLI + optional web bin in one manifest | Inapplicable (pattern, not crate) | Inapplicable | Inapplicable | Inapplicable | Active (pattern widely used) | Inferred: most library+CLI crates on crates.io | Simple, idiomatic, keeps all surfaces in one crate and uses Cargo as backend. |
| Workspace split: library crate + CLI crate + optional web crate | Separate concerns into multiple packages under one workspace | Inapplicable (pattern) | Inapplicable | Inapplicable | Inapplicable | Active where modularity is needed | Inferred: larger projects like server frameworks | Cleaner modularity, but more complex manifest layout and cross-crate dependency management. |
| Single package with implicit default targets (no `[lib]` or `[[bin]]` tables, relying on `src/lib.rs` and `src/main.rs`) | Use Cargo’s default target detection | Inapplicable (pattern) | Inapplicable | Inapplicable | Inapplicable | Stable-quiet | Many small crates | Minimal manifest, but less explicit and harder to refactor when adding multiple binaries or optional features. |
| Single package plus `xtask` crate for orchestration | Use manifest targets as above but add an `xtask` crate and alias for repo automation | Inapplicable (pattern) | Inapplicable | Inapplicable | Inapplicable | Active in automation-heavy repos | Documented in `xtask` pattern write-ups | Adds structured automation without changing manifest semantics; increases complexity. |
| Single package plus `cargo-dist` configuration | Use manifest targets but configure `dist-workspace.toml` for cross-platform releases | Inapplicable (pattern) | Inapplicable | Inapplicable | Inapplicable | Active among binary-distributing projects | Documented in `cargo-dist` docs | Enhances release packaging and attestation but adds another configuration surface. |

Because these candidates are patterns rather than specific crates, fitness gates like license compatibility, MSRV, RustSec advisories, and OS support are inapplicable or satisfied trivially: they inherit the template’s own constraints and rely on Cargo, which is part of the Rust toolchain and has no separate license or MSRV beyond what the Rust project declares.[1][2][3] The default features and async-runtime coupling are likewise a matter of which library dependencies the template chooses; R49 does not introduce any such crates, so binary-size and compile-time costs are determined by the template’s code and library choices (to be decided in other items such as R69).

Within this shortlist, the dominant choice—the single manifest with explicit `[lib]` and `[[bin]]` targets—remains preferable for the template’s scope. The workspace split is reserved as a runner-up for scenarios where modularity or independent versioning becomes more important than keeping everything in one crate, and the implicit-default-target option is excluded by gate below because it undermines explicitness and rewritability.

### Excluded by gate

Some alternatives fail the fitness gates or the owner’s acceptance criteria and are excluded. The most notable exclusion is the pattern of relying purely on implicit targets—having `src/lib.rs` and `src/main.rs` without declaring `[lib]` or `[[bin]]` tables in `Cargo.toml`.[1][7] While this pattern is supported by Cargo and widely used for simple crates, it fails R49’s explicitness and rewritability gates: it does not make entry-point names or paths visible at the manifest level, and extending it to multiple binaries or feature-gated targets requires introducing new manifest entries, which complicates future rewrites.

Another exclusion is treating a task runner like `cargo-make` as a required build backend rather than an optional automation tool.[17] `cargo-make` allows defining task flows in a separate TOML configuration and can orchestrate builds, tests, documentation, benches, and security validations via a single command.[17] However, making it a required part of the build would violate the principle that Cargo is the native backend and would add an external dependency that R49 does not own. It remains an optional tool for sophisticated pipelines but is excluded as a candidate for manifest-level build-target declaration.

Similarly, using `cargo-dist` as a primary build backend rather than as a release orchestrator is excluded. Its own documentation emphasizes that it “distributes your binaries” and splits responsibilities into building and distributing, using Cargo to build binaries and installers and then hosting artifacts and announcing releases.[9][18] Treating `dist` as the place where targets or entry points are declared would invert this layering and fail the gate that R49 must decide manifest-level behavior, not external packaging semantics.

Finally, any candidate that depends on non-stable Rust features or requires a nonstandard toolchain is excluded by the owner’s constraint of stable Rust only and an edition of 2024.[2] No such candidates arose directly in the sources provided, but this gate remains active.

### Up-and-comers

Among up-and-comers, the most relevant tools to R49’s category are those that shape how crates are distributed or mirrored rather than how they declare targets. The `dist` tool (formerly `cargo-dist`) is evolving into a more comprehensive system for shippable application packaging, integrating planning, building, hosting, and publishing of releases.[18] It is considered an up-and-comer because it is relatively new, still iterating rapidly, and rebranding, but it is already used in production workflows that require artifact attestation and SBOM generation.[9] For this template, `dist` is a promising candidate for R68 (release-binary-artifacts) but does not affect R49’s manifest-level design.

Another up-and-comer is `crates-io-proxy`, which implements transparent caching for the crates.io registry and crate downloads, providing HTTP proxy endpoints that Cargo can use via the source replacement feature.[19] This tool is instrumental in environments that need local mirrors or off-line caching, such as enterprise deployments, but it does not alter how the manifest declares targets or packaging scope. It operates under the hood by serving `.crate` files and index data.[19]

These tools are noted here only to show the broader forest: Rust’s ecosystem is rich with distribution and orchestration tools, but the manifest-level target declaration remains firmly in Cargo’s domain, and R49’s design should lean on that stable core.

## Fit and recommendation

### Fit for this template

It is useful to examine the fit of the dominant choice separately for each of the template’s three surfaces: CLI, library, and web service.

For the **CLI**, Cargo’s `[[bin]]` target system is designed precisely for this purpose. Binary targets are executable programs that can be run after compilation, and they are linked with the package’s library and its dependencies as declared in `[dependencies]`.[1] The template’s primary CLI can thus be declared as a `[[bin]]` with explicit `name` and `path`, and its `main` function becomes the command-line entry point. The manifest may include fields like `test = false` and `bench = false` if the CLI binary should not be treated as a test or benchmark target by default, although Cargo’s defaults suffice unless the template wants to change test harness behavior.[1][3][7] Using the crate name as the binary name ensures ergonomic installation and invocation via `cargo install`.[4][5][6]

For the **library**, `[lib]` is the idiomatic mechanism to define the crate’s reusable API. The library target’s filename defaults to `src/lib.rs`, and its name defaults to the package name with dashes replaced by underscores.[1][2][3] Declaring `[lib]` explicitly makes these choices visible and allows the template to adjust settings like `crate-type` if needed (for example, to generate `cdylib` or `rlib` variants), although a pure Rust library will typically leave `crate-type` as the default `["lib"]`.[3][7] The library is automatically usable by the binaries via `use rs_launch_blueprint::...` imports, reflecting the same pattern as TypeScript’s separate `src/lib.ts` bundle, but with compile-time linking instead of runtime module loading.

For the **web service**, Rust offers at least two idiomatic patterns that can be mapped onto Cargo’s targets. One pattern is to integrate the web service entry point into the CLI binary, making the CLI responsible for starting the web server when invoked with a particular subcommand or flag. In this case, no separate `[[bin]]` is needed, and the web service is purely a library-level surface that the CLI orchestrates. Another pattern is to expose a dedicated `[[bin]]` for the web server, such as `rs-launch-blueprint-web`, whose sole responsibility is to start and manage the HTTP server. This second pattern better mirrors the TypeScript port’s separation of CLI and library entries and gives operational clarity: running the web service is distinct from running the CLI.

In either pattern, feature gating is an important fit consideration. The template’s “web extra surface” is optional, and not all users need the web service or its dependencies. Cargo’s `required-features` field on targets allows the template to declare that the web-service binary requires a feature like `"web-service"`, and Cargo will only build and install that binary when the feature is enabled.[1][7] This aligns with the owner’s desire to keep optional surfaces behind explicit enablement and matches the Python and TypeScript ports’ approach of treating web functionality as an extra layer rather than a core requirement.

From a packaging standpoint, the template’s choice not to set `include` or `exclude` explicitly is a good fit because the crate is a small, source-only project that is unlikely to carry large assets or unusual files.[8][11][14] Cargo will include the source files, manifest, and any tests, examples, and benches in the `.crate` generated by `cargo publish`, excluding only files ignored by version control.[8][14] This ensures that users who download the crate have access to tests and examples if they wish to run them, as is common practice, and it keeps the manifest simple.[11] If the template later grows large test data or bench directories, R49 can be revisited with a `BASELINE-REVIEW` to add `exclude` entries that cut packaging weight.[8][14]

Finally, for **distribution-name-vs-binary-name divergence**, Rust behaves similarly to TypeScript rather than Python. Cargo `install` is keyed by crate name, while the installed binaries are keyed by `[[bin]]` `name`.[4][5][6] Divergence is allowed—many crates have binary names that differ from the crate name—but it does not require a special flag analogous to `uvx --from` unless multiple crates install binaries with the same name, in which case Cargo suggests selecting a binary via `--bin`.[4][5][6] For the template, the current requirements do not justify a deliberate divergence: matching crate name and primary binary name keeps the mental model simple and aligns with the Python and TypeScript ports’ principle that distribution and CLI names should be easily discoverable. Divergence can be considered later if a compelling user-facing alias is needed.

### Recommendation

Putting the above analysis into a concrete implementation, the recommended crate for R49 is:

**Kind:** crate  
**Name:** `rs-launch-blueprint`  
**Role:** single Cargo package providing a library, CLI binary, and optional feature-gated web-service binary  
**Build backend:** Cargo (no separate backend crate; optional orchestration via `xtask` or `dist` is out of scope)  

At the manifest level, the template should declare the following in `Cargo.toml`:

```toml
[package]
name = "rs-launch-blueprint"
version = "0.1.0"
edition = "2024"
rust-version = "1.xx"        # set per MSRV policy in a minor release
license = "MIT OR Apache-2.0"
# other metadata: authors, repository, description, keywords, categories

[lib]
name = "rs_launch_blueprint"
path = "src/lib.rs"

[[bin]]
name = "rs-launch-blueprint"
path = "src/bin/cli.rs"
test = false
bench = false

[[bin]]
name = "rs-launch-blueprint-web"
path = "src/bin/web.rs"
required-features = ["web-service"]
test = false
bench = false

[features]
default = ["cli"]
cli = []
web-service = []
```

This example illustrates the pattern rather than prescribing exact version or feature names. The `[package]` section sets the crate name, edition, MSRV via `rust-version`, and dual license as required.[2] The `[lib]` section explicitly names the library and its path, matching Cargo’s defaults but making them visible.[1][2][3][7] The primary CLI is declared as a `[[bin]]` named `rs-launch-blueprint`, which points to `src/bin/cli.rs` where the `main` function lives. The optional web-service binary is declared as `rs-launch-blueprint-web` with a `required-features` field ensuring it is built only when the `web-service` feature is enabled.[1][7] The `test` and `bench` flags are set to `false` to avoid the CLI and web-service binaries being treated as test or bench targets by default, although this is optional and may be omitted if the template wants them to be testable via `cargo test` or benchmarkable via `cargo bench`.[3][7][13]

The `[features]` section defines `cli` and `web-service` features, with `cli` included in the default feature set so that the CLI is built and installed by default, while `web-service` is opt-in.[1][7] This arrangement respects the template’s optional web-surface nature and allows users to build or install only the CLI when they do not need the web server.

Importantly, no `include` or `exclude` keys are set in `[package]`. The template relies on Cargo’s default packaging semantics: files under the crate directory are included unless ignored by version control, and `exclude`/`include` are only added if future large assets or non-source directories must be pruned.[8][14] This choice must be documented as part of the template’s port documentation, noting that it is the Rust analogue of Python’s package-root bounding and TypeScript’s `files` whitelist, adapted to Rust’s source distribution model.[8][11][14]

With this manifest, the template uses Cargo as its build backend and target declaration mechanism, satisfying the owner’s requirements and the R49 acceptance criteria. If future evidence shows that this shape is wrong—for example, if the web-service target must be in a separate crate or packaging must exclude tests and benches—the localized nature of `[lib]`, `[[bin]]`, and packaging keys makes rewriting feasible without impacting other rows.

### Ranked runner-up

The ranked runner-up is the **workspace split pattern**: a Cargo workspace containing separate crates for the library, CLI, and web service. In this pattern, the root `Cargo.toml` declares a `[workspace]` with members such as `rs-launch-blueprint-lib`, `rs-launch-blueprint-cli`, and `rs-launch-blueprint-web`. Each member crate has its own `[package]`, `[lib]`, and `[[bin]]` targets as needed. The library crate exposes the reusable API, and the CLI and web-service crates depend on it via `[dependencies]`.

This runner-up wins under conditions where modularity or independent versioning is required. For example, if the web service must evolve faster than the CLI or library, or if the owner needs to publish the library separately from the CLI binary for reuse in other contexts, a workspace split allows different version numbers and dependencies. It also makes it easier to enforce different MSRV policies per crate if that ever becomes necessary.

However, this pattern is more complex: it introduces cross-crate dependency management, multiple manifests, and potentially more complicated CI and release flows. For the current template, where all surfaces are part of a single conceptual unit and share the same MSRV and license constraints, the single-crate pattern is a better fit.

### Tradeoffs

The recommended single-crate pattern trades off modularity and some potential flexibility in favor of simplicity, explicitness, and alignment with the owner’s rewritability requirement. Compared to the workspace split runner-up, it sacrifices the ability to version the library independently or to publish the CLI and web-service binaries as separate crates, but it gains a single manifest and a straightforward build story: `cargo build` and `cargo install` work out-of-the-box without workspace-specific commands.[1][6]

Compared to the implicit-target pattern, the recommended design adds manifest boilerplate in the form of `[lib]` and `[[bin]]` tables, but this is accepted because it surfaces target names and paths explicitly, making future refactoring and rewrites easier. It also allows the use of `required-features` on the web-service binary, which is not possible without explicit `[[bin]]` entries.[1][7]

Compared to patterns that treat `cargo-make` or `dist` as primary build backends, the recommended design retains Cargo as the sole backend and treats those tools as optional layers for orchestration and release, respecting the owner’s constraints and R49’s scope.[4][6][9][17][18] This means the template does not gain the extra features these tools provide (such as single-command pipelines or GitHub Release automation) directly under R49, but this is acceptable because R68 and other rows will decide those concerns.

Finally, by choosing to match crate name and primary binary name, the template gives up the possibility of a concise or branded CLI name that differs from the crate—for example, `rs-projects`—but this cost is modest and can be reintroduced later if evidence shows that users prefer a shorter command. For now, the simplicity of `cargo install rs-launch-blueprint` followed by `rs-launch-blueprint` is prioritized.

### Parameters

R49 owns the parameter `build-tool-output-shape`, which should be set to:

`owns build-tool-output-shape = "single Cargo package named rs-launch-blueprint with explicit [lib] and [[bin]] targets; primary CLI binary name matches crate name; optional web-service binary gated via required-features; no explicit include/exclude packaging whitelist; Cargo is the sole build backend"`

This parameter encodes the core design decisions for how build outputs and entry points are declared. It assumes the following consumed parameters:

`assumes rust-edition = 2024`  
`assumes msrv-policy = "stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI"`  
`assumes license = "MIT OR Apache-2.0"`  
`assumes target-os-matrix = "ubuntu-latest, macos-latest"`

No conflicts with these parameters arise from the recommended design, so no `CONFLICT:` lines are required. The design is fully compatible with stable Rust, edition 2024, dual licensing under MIT or Apache-2.0, and CI running on Ubuntu and macOS.[2][6][13]

## Execution

### Migration implications

Implementing this recommendation in the template has clear, localized file-level implications. The main change is to `Cargo.toml`, which must be structured to include `[package]`, `[lib]`, `[[bin]]`, and `[features]` sections as described. If the template currently relies on Cargo’s implicit detection of `src/lib.rs` and `src/main.rs`, adding `[lib]` and `[[bin]]` tables will make these targets explicit and may require moving or renaming source files to match the declared paths.[1][7]

Specifically, the library source should be placed in `src/lib.rs`, and its public API organized under the `rs_launch_blueprint` crate root. The CLI source should be placed in `src/bin/cli.rs` (or `src/main.rs` if the template prefers the default main path), and the `main` function should delegate to library functions to keep logic reusable and testable. The optional web-service source should be placed in `src/bin/web.rs`, with its `main` function starting the HTTP server and likewise delegating to library logic.[1][2][3][7]

If the template currently has a different structure—for example, a monolithic `src/main.rs` that contains both CLI and web server logic—migration will involve extracting web-specific code into a new `src/bin/web.rs` and introducing the `web-service` feature. Conditional compilation attributes such as `#[cfg(feature = "web-service")]` may also be needed in the library to avoid compiling web-specific code when the feature is disabled.[1][7]

For packaging, if the template currently uses `include` or `exclude` keys in `[package]`, migration to the recommended design would remove those keys and rely on Cargo’s defaults.[8][14] This may increase the set of files included in the published `.crate`, so any previously excluded large assets or test data must be reviewed. If such assets exist, R49 should be updated with a `BASELINE-REVIEW` entry and a new decision to reintroduce `exclude` entries for those paths.[8][14][15]

In the repository-level tooling, if an `xtask` crate or `cargo-make` configuration already exists, migration does not require removing them. They can continue to orchestrate builds and tests by calling Cargo commands like `cargo build`, `cargo test`, and `cargo bench`.[12][13][16][17] However, if any such tooling currently assumes implicit targets, it must be updated to refer to the explicit `[[bin]]` names, e.g., `cargo run --bin rs-launch-blueprint` instead of `cargo run`.[1][6]

### Validation strategy

To validate that the recommended design satisfies the shared principles and acceptance criteria, a concrete set of commands should be run on a realistic example of `rs-launch-blueprint` configured according to this manifest. These commands, along with expected behavior, form the validation strategy. They are described as planned checks; actual execution results are not available in this environment and must be gathered by implementers.

First, **basic build and test** should be validated:

Running `cargo build` at the crate root must succeed, compiling the library and the default binary targets according to the manifest.[1][6] Because the web-service binary requires the `web-service` feature, it will not be built unless that feature is enabled.[1][7] Running `cargo test` must succeed, executing any unit tests or integration tests defined in the library and binaries, with the default test harness behavior unless the manifest sets `harness = false` or `test = false` for specific targets.[3][7][13]

Second, **CLI behavior and installation** must be validated:

Running `cargo run --bin rs-launch-blueprint -- --help` should display the CLI’s help message and confirm that the CLI binary is correctly wired to the library logic. After building and publishing the crate to a local or test registry, running `cargo install rs-launch-blueprint` should build and install the primary CLI binary into the installation root’s `bin` folder, with its name matching the crate name.[4][5][6] Invoking `rs-launch-blueprint` from the shell should then execute the CLI, confirming that distribution-name-vs-binary-name divergence is absent for the primary binary.

Third, **web-service feature gating** must be validated:

Running `cargo build --features web-service` should compile the library and both binaries, including `rs-launch-blueprint-web`, because the feature required by the web-service binary is enabled.[1][7] Running `cargo run --bin rs-launch-blueprint-web --features web-service` should start the web server and allow interactions via HTTP, confirming that feature gating works and that web-specific dependencies are properly scoped. Running `cargo build` without features should not compile the web-service binary, verifying that `required-features` is honored.[1][7]

Fourth, **packaging scope** should be validated:

Running `cargo package` generates a local `.crate` file without publishing it. Inspecting this archive should confirm that it includes source files, `Cargo.toml`, and any tests, examples, and benches, but excludes files ignored by version control and any large assets that were intentionally omitted.[8][14] If any unwanted files are included, the manifest can be adjusted with `exclude` entries for those globs, and the `cargo package` command re-run to confirm the change.[8][14]

Fifth, **benchmarks and optional targets** can be validated if the template includes them:

Running `cargo bench` will execute benchmarks associated with targets that have `bench = true` in the manifest, using Rust’s `libtest` harness.[13] If the template declares examples or tests with specific `[[example]]` or `[[test]]` entries, commands like `cargo run --example foo` or `cargo test --test bar` can be used to validate that those targets are wired correctly and that any `bench`, `test`, or `doc` flags behave as expected.[3][7][13][15]

Lastly, **CI integration** must be validated:

CI workflows on `ubuntu-latest` and `macos-latest` should be configured to run `cargo build`, `cargo test`, and optionally `cargo bench` and `cargo package` for the template.[6][13][15] Their success will confirm that the manifest and target declarations are portable across the supported OS matrix and compatible with stable Rust.[2][6][13]

These validation steps collectively verify that Cargo is serving as the build backend, that the manifest’s targets and features behave as intended, and that the packaging scope is predictable. They also provide a baseline for smoke tests in R50 and release artifact decisions in R68.

### Confidence & re-verify trigger

The confidence in this recommendation is **high**, based on the alignment with official Cargo documentation, the clear mapping of Python and TypeScript port principles onto Cargo’s target system, and the absence of any requirement in the prompt that would necessitate a separate build backend or bundler at the crate level.[1][2][3][4][6][8][9][11][12][13][14][16][18] The design is conservative and idiomatic, relying on default Cargo behavior where appropriate and only adding explicit manifest entries where the owner’s explicitness and rewritability requirements demand them.

However, several re-verify triggers should be defined. First, if the template grows a significantly more complex web service surface, especially one that needs to be deployed separately or packaged with different dependencies, the workspace split runner-up should be reconsidered, and R49 revisited with a `BASELINE-REVIEW` entry describing the changing principle and evidence.[Context] Second, if the template starts including large assets, generated code, or other heavy directories, packagers may experience pain, and a re-verify should consider adding `exclude` or `include` keys to narrow the packaging scope.[8][11][14] Third, if ecosystem norms shift—for example, if Cargo introduces a new manifest-level abstraction for entry points analogous to Python’s `[project.scripts]`—R49 should be updated to take advantage of that abstraction.

Finally, if implementers find that users strongly desire a short CLI name that differs from the crate name, and that this improves usability, a re-verify may recommend a deliberate distribution-name-vs-binary-name divergence. This would entail documenting the mapping and any implications for `cargo install` and `cargo-binstall` behavior, and possibly introducing aliases at the shell level.

### Sources

This report has relied primarily on authoritative documentation from the Rust project and ecosystem to ground the analysis of Cargo’s manifest and target system. The Cargo book’s sections on targets and manifest format define how `[lib]`, `[[bin]]`, `[[example]]`, `[[test]]`, and `[[bench]]` tables configure build targets, including default names, paths, and flags.[1][2][3][7] The RFC describing `cargo install` clarifies how binary crates are built and installed, emphasizing that only packages with `[[bin]]` targets are installable and that multiple binaries can be selectively installed via command-line flags.[4][5][6] Documentation on publishing to crates.io and the use of `exclude` and `include` keys explains Cargo’s default packaging behavior and how to override it with globs.[8][14]

Community discussions and downstream packaging guidance, such as the Rust users forum thread on what to include when publishing and the Debian Rust Team’s recommendations on disabling tests, examples, and benchmarks, provide evidence of practice norms and the realities of packaging in large distributions.[11][15] They show that including tests and examples in published crates is common, and that explicit disabling or exclusion is reserved for resource-constrained environments.

Patterns for repository-local automation and build orchestration have been informed by documentation of the `xtask` pattern and its use in projects that prefer Rust-based automation over shell scripts or Makefiles.[12][16] The `cargo-make` documentation illustrates how task runners can orchestrate complex build flows, but also reinforces that they sit outside the manifest and treat Cargo as a subprocess.[17] Release automation and binary packaging patterns have been drawn from `cargo-dist` documentation and CI workflows that use it to build, attest, and publish platform-specific artifacts.[9][18]

Finally, registry-level tooling such as `crates-io-proxy` highlights the broader ecosystem context in which crates are distributed and mirrored, though it does not change manifest semantics.[19] These sources collectively support the conclusion that Cargo’s native manifest and target system is the correct place to declare build output shape, entry points, and packaging scope for `rs-launch-blueprint`, and that no separate build backend or bundler crate is needed for R49.

## Sources

- [Cargo Targets - The Cargo Book - Rust Documentation](https://doc.rust-lang.org/cargo/reference/cargo-targets.html)
- [The Manifest Format](https://doc.rust-lang.org/cargo/reference/manifest.html)
- [The Manifest Format - The Cargo Book](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/cargo/reference/manifest.html)
- [1200-cargo-install - The Rust RFC Book](https://rust-lang.github.io/rfcs/1200-cargo-install.html)
- [Keyboard shortcuts](https://doc.rust-lang.org/nightly/cargo/commands/cargo-install.html)
- [cargo install - The Cargo Book](https://doc.rust-lang.org/cargo/commands/cargo-install.html)
- [zenn-content/articles/cargo-targets.md at main · termoshtt/zenn-content](https://github.com/termoshtt/zenn-content/blob/main/articles/cargo-targets.md)
- [Publishing on crates.io - The Cargo Book](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/cargo/reference/publishing.html)
- [CI/CD Pipeline and Release Workflow - Dosu](https://app.dosu.dev/821cc1ce-e828-457b-858b-bfa2c1e26036/documents/5d24a5f5-7f7c-4424-b824-33437c76fc1f)
- [Feature flags of axum crate // Lib.rs](https://lib.rs/crates/axum/features)
- [What to include when publishing a crate?](https://users.rust-lang.org/t/what-to-include-when-publishing-a-crate/51992)
- [Build Automation (xtask) - Yerd](https://yerd.app/developer/xtask)
- [cargo bench - The Cargo Book](https://rustwiki.org/en/cargo/commands/cargo-bench.html)
- [The Cargo Book](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/cargo/print.html)
- [General tips - The Debian Rust Team Book](https://rust-team.pages.debian.net/book/tips.html?highlight=ITP)
- [Build Automation with xtask | rust-embedded/cortex-m | DeepWiki](https://deepwiki.com/rust-embedded/cortex-m/5.2-build-automation-with-xtask)
- [§installation](https://sagiegurari.github.io/cargo-make/api/cargo_make/)
- [GitHub - axodotdev/cargo-dist: 📦 shippable application packaging](https://github.com/axodotdev/cargo-dist)
- [crates-io-proxy 0.2.4](https://docs.rs/crate/crates-io-proxy/latest)

## Cost

Total: $0.9812
