# R02 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260916-204428-51b352f774314e76 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would fall outside the template are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**

**Reasoning Summary**
**Researching requirements**

I need to conduct extensive research, which means starting the web search right away. The user wants every claim to have a source URL with the retrieval date, but my citation system has specific rules about raw URLs. However, since they’ve explicitly asked for source URLs, I can include them. It’s important to follow the exact heading format and gather comprehensive, current information. I’ll also recommend a multi-crate topology and other tools like cargo-deny and clippy for optimization.
**Investigating ecosystem tools**

I need to look into various ecosystem tools, such as Cargo's built-in features, crate visibility, and workspace management. Other tools like cargo-deny, cargo machete, and potential options like hakari and archunit_rs are also worth considering, along with custom lint solutions and clippy's disallowed types. It’s essential to gather up-to-date information as of September 17, 2026, using official docs, GitHub APIs, and RustSec pages. I’ll start with a broad web search for the necessary data and plan my API calls accordingly.

**Perplexity (sonar-deep-research)**

**Crate-Boundary Enforcement for `rs-launch-blueprint`: A Workspace, Tooling, and Pipeline Design**

The `rs-launch-blueprint` template must give Rust users the same *mechanical* architectural guarantees that `py-launch-blueprint` currently achieves with `import-linter`, `tach`, and `ruff`: a composition root that is visible only to front-ends, core code that depends only inward and never on frameworks, independent front-ends, internal layering in the core, explicit guards against framework bleed, a declared dependency graph, and a consistent namespacing convention integrated into pre-push hooks and CI. Achieving this in Rust requires leaning on the language’s stronger compile-time module and crate system, a multi-crate Cargo workspace that encodes boundaries at the dependency level, and a small but coherent stack of tools: Cargo itself and `cargo metadata` for graph introspection, a hexagonal workspace topology that enforces dependency directions by construction, `cargo-deny` for dependency governance and framework-bleed guards, and a module-graph tool such as `dep_graph_rs` or `cargo-modules` wired into a custom “arch-check” harness. Together, these elements yield a design in which illegal architectural dependencies are build-breaking errors, not review findings, and in which the guarantees are enforced at both a fast local tier (via Lefthook pre-push hooks) and an authoritative CI tier with standard GitHub Actions for Rust and `cargo-deny`.[5][7][8][11][16][18] The resulting stack respects all fixed parameters (edition 2024, MSRV policy, license, OS matrix), preserves the shared cross-language principles around hexagonal boundaries, and introduces ecosystem-specific implementations only where Rust’s idioms and tooling make a different choice more appropriate.

**Analysis**

**Gemini (deep-research-preview-04-2026)**

**Deep-Research Report: Crate-Boundary Enforcement in Rust (R02)**

### Landscape

**OpenAI**

This item decides **compiler-enforced architecture boundaries for a Cargo workspace**, plus the declared policy and pipeline that prevent later `Cargo.toml` edits from weakening those boundaries. The shared cross-repository agreement belongs at the **capability, architectural-pattern, and policy levels**—not at the level of tool names, directory nesting, or identical hook commands.

All web evidence below was retrieved **2026-09-17**. Repository-local Python/TypeScript evidence comes from the prompt-supplied files and has no public URL.

**Three-bin Rust landscape**

| Bin | Candidates | Assessment for R02 |
|---|---|---|
| Built-in or first-party toolchain | Cargo workspaces and packages; explicit package dependencies; rustc direct-dependency resolution; `cargo metadata`; `cargo tree`; workspace lints; Clippy | Cargo packages are the strongest enforcement unit. `cargo metadata` is Cargo’s stable, versioned machine interface for policy tooling. Clippy and visibility help encapsulation but do not express the required package graph. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html)) |
| Established industry standard | Multi-crate workspaces; repository-local `xtask`/`tidy` checks; the `cargo_metadata` crate; crate-prefix naming; CI-required architecture jobs | There is no established generic Rust equivalent to all of `import-linter` + `tach` + Ruff. The established pattern is compiler-enforced crate boundaries plus a repository-specific graph check. Rust itself uses `cargo_metadata` in `tidy` to recursively enforce permitted dependencies. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs)) |
| Up-and-comer | `cargo-depgraph-check` 0.1.0; `cargo-arc`; Archaven 1.1.0; `cargo-archtest-cli` 0.2.3; cargo-pup/rust_arkitect-style source analyzers | Promising, but none currently clears the full R02 capability and dependability gates. `cargo-depgraph-check` ignores external dependencies; cargo-arc’s surfaced versions disagreed and its README documents source-analysis blind spots; Archaven’s resolver is intentionally simpler than rustc’s; cargo-archtest’s surfaced CI example covers Ubuntu only. ([docs.rs](https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md)) |

**Authority assessment**

- The Cargo Book, Rust Book, rustc documentation, Rust RFCs, and Rust release publications are normative because they define the behavior being relied on: workspace membership, explicit dependencies, metadata format, resolver behavior, and direct `--extern` inputs. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html))
- The Rust compiler’s current `tidy` implementation is an authoritative maintained production reference. It invokes `cargo_metadata::MetadataCommand`, requests all features with `--locked`, recursively computes dependencies, and rejects packages outside explicit permitted sets. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs))
- The 2025 State of Rust Survey is authoritative for developer-cost priorities, not architecture correctness. It identifies compile time and storage/resource use as continuing productivity problems, supporting a cheap pre-commit tier instead of full-workspace compilation on every commit. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- Candidate-maintainer documentation is authoritative for a candidate’s stated feature set but not sufficient by itself to establish maturity or production adoption.
- Microsoft’s Pragmatic Rust Guidelines are useful independent industry evidence for a single workspace with inherited package metadata, dependencies, and lints, but they are not normative Rust specifications. ([microsoft.github.io](https://microsoft.github.io/rust-guidelines/guidelines/project/index.html))

**Practice evidence**

| Project | Observed practice | Relevance |
|---|---|---|
| `rust-lang/rust` | Large multi-workspace source tree plus a custom `tidy` dependency allowlist implemented using `cargo_metadata` | Strongest reference for a repository-owned dependency policy rather than relying on a generic architecture CLI. ([github.com](https://github.com/rust-lang/rust/blob/main/Cargo.toml)) |
| `rust-lang/rust-analyzer` | Architecture described in terms of separate crates and explicit invariants; auxiliary checks live in `xtask`; crate architecture is treated as the primary boundary | First-party evidence that Rust architecture is commonly expressed at crate granularity. Its own documentation also says it does not add a separate generic architecture check, so it is evidence for the pattern, not a complete R02 implementation. ([rust-analyzer.github.io](https://rust-analyzer.github.io/book/contributing/architecture.html)) |
| `tokio-rs/axum` | Separates `axum-core` from the higher-level `axum` package and directs downstream low-level implementations toward `axum-core` | Maintainer-standing evidence that framework ecosystems use crates to isolate stable core concepts from outer framework surfaces. ([github.com](https://github.com/tokio-rs/axum)) |
| `astral-sh/uv` | Large Cargo workspace; documents its crate hierarchy and recommends `cargo-depgraph` for visualization | Newer, prominent production evidence that crate graphs are central, but visualization alone is not enforcement. ([github.com](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1)) |

**Fitness-gate summary before popularity**

| Candidate | License | MSRV evidence | Advisories / unsafe | Ubuntu + macOS evidence | Features/runtime | Cost | Verdict |
|---|---|---|---|---|---|---|---|
| Cargo/rustc workspace pattern | Compatible with repository license | Controlled directly: `rust-version = "1.96"`; CI on 1.96.1 and 1.98.1 | Repository can forbid unsafe | Required template matrix supplies both | No runtime coupling | More packages, no extra shipped dependency | Pass |
| Local `xtask` + `cargo_metadata` 0.23.1 | `cargo_metadata` repository is MIT | Must pass the template’s 1.96.1 matrix before merge | Local code forbids unsafe; direct RustSec API result must be refreshed | Template matrix supplies both | Use synchronously, `default-features = false`; no async runtime | Dev-only compile cost | Provisional pass, subject to executable gate checks |
| `cargo-depgraph-check` 0.1.0 | MIT | Numeric MSRV not surfaced | RustSec result not established | Surfaced example is Ubuntu-only | No async coupling; small CLI | Low | Excluded: ignores external dependencies and lacks gate evidence |
| `cargo-arc` | MIT OR Apache-2.0 | Says stable, but numeric floor not established | RustSec result not established | Cross-OS evidence not established | Source parser plus visualization/UI surface | Higher than metadata-only checker | Excluded pending version, parser, MSRV, and platform stabilization |
| Archaven 1.1.0 | Not established in retrieved evidence | Not established | Not established | Not established | Test-library source scan, no runtime coupling | Moderate parse/test cost | Excluded by evidence gates and non-rustc resolution |
| `cargo-archtest-cli` 0.2.3 | Not established in retrieved evidence | Not established | Not established | Surfaced CI example is Ubuntu-only | CLI/test library | Moderate | Excluded by evidence gates |

**Figure-collection limitation:** the research transport did not return the requested crates.io and GitHub JSON payloads for several exact endpoints. I have therefore marked those figures unresolved rather than substituting UI counts or estimates. Popularity did not decide the recommendation; the missing figures are nevertheless a required **pre-merge re-verification item**.

**Perplexity**

The category this item decides is **crate-boundary and dependency-graph enforcement for a multi-front-end, hexagonally structured Rust application template**. In Rust terms, this sits at the intersection of Cargo workspace design, architectural layering patterns, dependency linting, and static-analysis tooling that can reason about module and crate graphs. A survey of the Rust ecosystem reveals three bins relevant to this problem: built-in or first-party toolchain features, established industry standards, and up-and-comers focused on graph analysis or unused dependency detection.

In the built-in and first-party bin, the primary authority is Cargo itself, including workspaces and the compilation-unit dependency graph construction in `unit_dependencies` that lowers package-level dependencies into target-specific units.[12] Cargo workspaces allow multiple crates to share a lock file and build artifacts and to coordinate dependencies, enabling designs in which core, CLI, and web-service crates coexist but have distinct dependency sets.[5][8] The Rust compiler and module visibility rules (`pub`, `pub(crate)`, `pub(super)`, `pub(in path)`) provide strong mechanisms for constraining what parts of a crate are exposed and to whom, which the Rust architecture patterns literature explicitly recommends as a foundation for enforcing hexagonal boundaries by having outer layers depend on inner layers, never the reverse.[7] Cargo’s `metadata` subcommand gives a machine-readable description of the workspace’s package and dependency graph, which is essential for constructing custom linting tools that can enforce architectural constraints analogous to Python’s `import-linter` contracts.[12]

In the established industry-standard bin, `cargo-deny` is the dominant tool for dependency governance and licensing checks.[15][16] It is a Cargo plugin that lints a project’s dependency graph against a declarative configuration file (`deny.toml`), with sections for advisories, crate bans, multiple-version detection, wildcard constraints, and workspace-specific behavior such as treating unmaintained advisories differently when they affect only non-direct workspace members.[1][10][16] The `bans` section supports specifying crates that are globally banned, optional “use-instead” suggestions, and exceptions (`skip` and `skip-tree`) that allow banned crates under certain dependency subtrees, as well as workspace-specific diagnostics such as detection of direct workspace dependencies referred to more than once without using `workspace = true`.[9][10] This configurability makes `cargo-deny` authoritative for expressing rules like “framework X may only appear under front-end crates Y and Z” and “core crate must not transitively depend on any HTTP framework,” which closely parallel the framework-bleed bans enforced by `import-linter` and `ruff` in the Python template.[16]

Another established category is tools that detect unused dependencies, most prominently `cargo-udeps`.[13][14][17] `cargo-udeps` analyzes save-analysis data generated by the Rust compiler to detect dependencies declared in `Cargo.toml` that are not actually used in the compiled code, supporting workspace-wide checks (`cargo +nightly udeps --workspace`) and per-crate reporting, and allowing configuration of ignored dependencies via `package.metadata.cargo-udeps.ignore`.[13][14] Microsoft’s Rust engineering book explicitly recommends `cargo-udeps` as part of a release-engineering practice to trim unused dependencies, highlighting its impact on compile time, binary size, supply-chain risk, and license complexity and positioning it alongside alternative heuristic-based tools such as `cargo-machete` and intermediate approaches such as `cargo-shear`.[14] While these tools do not enforce boundaries directly, they are part of the broader dependency governance picture and inform the tradeoffs between aggressive enforcement and practical developer ergonomics.

In the up-and-comer bin, there are tools that visualize or analyze internal module dependencies. `cargo-modules` is a Cargo plugin that prints a crate’s hierarchical module structure as a tree, its internal dependencies as a graph, or unlinked source files (“orphans”) that are not hooked into the module graph.[11] Its `dependencies` subcommand can output the crate’s module-level dependency graph, which is conceptually similar to the bounded-context module graphs that `tach` generates in Python.[11] `dep_graph_rs` is a more recent, standalone tool that generates a dependency graph for the internal modules of a Rust crate by parsing source code with `syn` and analyzing `use crate::...` statements, outputting a DOT-format graph that can be fed into Graphviz or other visualization tools.[18] It supports grouping dependencies by file or module and filtering based on source, destination, or imported item name, enabling focused views such as “only show dependencies originating from module `graphics`.”[18] These tools are not yet as entrenched as `cargo-deny`, but they are directly relevant to F010’s requirement for a declared module dependency graph.

On the authoritative-source side, several references stand out. The Rust project’s own documentation on the compilation dependency graph (`unit_dependencies`) provides a canonical description of how package-level dependencies are translated into compilation units, underscoring the importance of workspace and target-level design for architectural enforcement.[12] Microsoft’s Rust engineering book offers guidance on release profiles, binary size, and dependency trimming, explicitly endorsing `cargo-udeps` and explaining its tradeoffs relative to faster heuristic tools like `cargo-machete`.[14] Embark Studios’ documentation and GitHub repository for `cargo-deny` articulate the tool’s role as a dependency linter, show example configurations with `bans` and `advisories`, and demonstrate its integration into GitHub Actions and pre-commit pipelines.[10][15][16] The Rust architecture patterns material from Smithery provides a strongly reasoned perspective on hexagonal architecture and domain-driven design in Rust, emphasizing inward-only dependencies, visibility hierarchies, and the use of Cargo workspaces to enforce dependency governance.[7] Finally, independent write-ups such as the Reintech article on Cargo workspace best practices and the RustZ2H guide on cross-platform shared-library workspaces provide practice-oriented guidance on structuring multi-crate workspaces with core and front-end adapters, aligning well with the template’s CLI + library + web-service shape.[5][8]

Practice evidence comes from several directions. The Microsoft Rust engineering book illustrates mainstream Rust engineering practice around dependency pruning and static analysis, treating `cargo-udeps` as a standard tool for trimming unused dependencies in multi-crate projects and drawing attention to its impact on binary size and supply-chain risk.[14] Embark Studios’ own use of `cargo-deny` and their publication of a GitHub Action for easy CI integration suggests that `cargo-deny` is considered production-ready and widely used for dependency governance, particularly in projects with large dependency graphs.[15][16] The Reintech article on Cargo workspace best practices presents a monorepo-like workspace layout with crates for core business logic, API server, CLI, database, and shared utilities, reinforcing the idea that separating core, API, and front-end crates is a mainstream architectural choice in Rust for large projects.[8] The RustZ2H cross-platform app guide shows a shared `core` library crate consumed by `web`, `desktop`, and `cli` adapter crates in a workspace, with the web crate depending on `wasm-bindgen`, the desktop crate depending on `tokio` and `tauri`, and the CLI crate depending on `clap` and `tokio`, providing a concrete, maintained example of core + adapters architecture in Rust and demonstrating compilation of the entire workspace and individual members.[5] These examples position the recommended stack firmly within established practice rather than as speculative design.

Fit over abstract best is critical. For a CLI + library + web-service template, the architecture must support multiple binaries, a shared core library, and adapters that may have very different dependency profiles (e.g., `clap` and `tokio` for CLI, `axum` or `warp` and `tokio` for web). The Reintech and RustZ2H examples explicitly target similar shapes and show that workspaces with core and adapter crates are effective in this context.[5][8] Tools like `cargo-deny` align with the need to govern third-party dependencies across many crates, including enforcing bans on framework crates in inner layers and managing multiple versions or wildcards.[10][16] Module-graph tools like `dep_graph_rs` and `cargo-modules` are well suited to generating graphs of internal dependencies for core crates or entire workspaces, which can then be checked against declared architectural rules, much as `tach` does for Python modules.[11][18] Finally, the Lefthook example from GitLab’s Rust CI integration shows how tests, formatting, and linting can be wired into pre-push hooks, confirming that Rust projects commonly enforce static checks at a pre-push tier to catch issues locally before they reach the main branch.[6] Taken together, this landscape supports a stack that uses a multi-crate workspace and established tools with targeted customization to replicate the Python template’s mechanical guarantees.

**Gemini**

The architectural boundary enforcement category defines the structural and mechanical guarantees that prevent a software codebase from degrading into a monolithic, tightly coupled system. In the context of establishing the implementation plan for `rs-launch-blueprint`, the fundamental objective is to replicate and adapt the stringent, mechanically enforced hexagonal boundaries established in the Python (`py-launch-blueprint`) precedent. This endeavor necessitates a profound transition from Python's dynamic module linting paradigms—managed through tools like `import-linter`, `tach`, and `ruff`—to Rust's rigorously compiled, statically analyzed ecosystem. The survey of the Rust ecosystem for dependency management, boundary enforcement, and architectural linting reveals a landscape distributed across three distinct maturity classifications.

In the first tier, comprising built-in or first-party toolchain components, Cargo Workspaces stand as the foundational element. Cargo Workspaces are the official mechanism for organizing multiple related crates, enforcing a strict Directed Acyclic Graph (DAG) at compile time which inherently prevents cyclic dependencies and unintended cross-module contamination [cite: 1, 2]. Operating alongside Cargo is `rust-clippy`, the official Rust linter. While often viewed primarily as a tool for enforcing idiomatic code, `rust-clippy` features highly specific configurability—such as the `disallowed_types` and `disallowed_names` arrays—that allows it to function as a formidable tool for type-level boundary control and framework-bleed prevention [cite: 3, 4, 5].

The second tier consists of established industry standards. The undisputed leader in this space is `cargo-deny`. Developed and maintained by Embark Studios, `cargo-deny` is the premier tool for auditing Cargo dependency graphs, explicitly banning unauthorized external crates, handling multiple version resolutions, and ensuring stringent licensing and security compliance [cite: 6, 7, 8]. For the orchestration of these checks, `lefthook` emerges as the prevailing polyglot Git hooks manager, enabling the fast, parallel execution of static analysis tools at specific lifecycle tiers such as `pre-commit` and `pre-push` [cite: 9].

The third tier encompasses up-and-comers that address niche architectural requirements not fully covered by the macro-level tools. The most relevant tool identified here is `boundary-rust` (and its core parsing engine `boundary`). This emerging, Abstract Syntax Tree (AST)-driven static analysis tool utilizes `tree-sitter` to evaluate Domain-Driven Design (DDD) and Hexagonal Architecture layering specifically within the internal module structures of Rust codebases [cite: 10, 11]. Other tools in this tier, such as `dep_graph_rs`, generate visual module-dependency graphs using the `syn` crate to parse source code, but currently lack the strict Continuous Integration (CI) enforcement capabilities required to fail a build upon architectural violation [cite: 12]. Similarly, `hexser` attempts to enforce hexagonal architecture, but does so by introducing a heavily opinionated, zero-boilerplate macro framework that couples domain logic to an external library, rather than serving as an independent mechanical linter [cite: 13].

The findings and classifications in this report are grounded in authoritative Rust project documentation and widely adopted community standards. The *Cargo Reference* and *Rust API Guidelines* definitively dictate workspace semantics, compilation units, and naming conventions, representing the immutable consensus of the Rust core team [cite: 2, 14]. Embark Studios' `cargo-deny` is treated as an authoritative industry standard due to its massive widespread adoption, boasting over 600,000 all-time downloads, and its deep integration into tier-1 Rust production CI pipelines across the ecosystem [cite: 8, 15]. Furthermore, architectural insights are drawn from applied Hexagonal Architecture patterns in Rust, validating how Domain-Driven Design concepts seamlessly map to Rust's unique module and trait systems without requiring heavy runtime frameworks [cite: 16, 17, 18].

Mainstream, well-regarded Rust projects overwhelmingly utilize Cargo Workspaces to strictly isolate core domain logic from infrastructure adapters. Repositories of immense scale and complexity, such as `tokio` and `ripgrep`, utilize virtual workspaces to completely decouple internal packages, ensuring that abstraction leaks are caught by the compiler rather than human reviewers [cite: 19]. Concurrently, production-grade continuous integration environments overwhelmingly depend on `cargo-deny` to mechanically enforce supply-chain hygiene. By banning redundant or unauthorized external dependencies at the graph level, `cargo-deny` moves boundary enforcement out of the realm of subjective code review and into the deterministic compiler pipeline [cite: 20].

The selected tools and architectural patterns are judged strictly on their ability to fulfill the specific operational constraints of `rs-launch-blueprint`—a template designed to simultaneously deliver a Command Line Interface (CLI), a library, and an HTTP web service. The chosen tooling stack must achieve exactly what `tach` and `import-linter` achieve in Python: preventing the core domain from importing front-ends, preventing multiple front-ends from cross-contaminating one another, guarding against framework bleed (e.g., stopping `axum` or `clap` from leaking into the core), and enforcing internal domain layering. All of this must be accomplished via authoritative CI checks and fast local mirrors. In this evaluation, abstract performance metrics and benchmark throughput are deliberately subordinated to the strict requirement of mechanical, build-breaking enforcement.

### Principles and implementation

**OpenAI**

**Shared requirement and agreement level**

The shared requirement from F003–F010, F020, F021, and F116 is:

> Architectural dependencies must be explicit, inward-only, mechanically checked, and cheap enough to receive local feedback, while CI remains authoritative.

Agreement is required at these levels:

1. **Capability:** illegal architectural dependencies fail an executable check.
2. **Architectural pattern:** core is inward-only; composition is outer wiring; frontends are independent; core layers/contexts have an explicit direction.
3. **Policy:** the allowed graph is declared in version control and checked in hooks and required CI.
4. **Acceptance behavior:** deliberate violations produce non-zero exits.

Agreement is **not** required on:

- Python module contracts versus Rust package contracts.
- A package-name directory under `src/`.
- The specific checker implementation.
- Identical hook tiers when ecosystem cost differs.
- R01’s trait-object versus generic-bound decision.

**Cross-ecosystem interpretation**

| Ecosystem | Appropriate realization | Classification |
|---|---|---|
| Python | `import-linter` contracts, Tach graph, and Ruff banned APIs remain appropriate because Python’s compilation/import model does not make package dependency declarations a hard build boundary | Existing justified implementation |
| TypeScript | The capability is absent because there is no core/frontend architecture to enforce | Missing capability, not a justified ecosystem difference; follow-on work should add an equivalent policy after TS-specific research |
| Rust | Split every architectural layer or bounded context requiring directionality into a separate Cargo package; use rustc as the first enforcement layer and a metadata-driven allowlist to reject illegal manifest edits | Justified ecosystem-specific mechanism preserving the same pattern |

Cargo requires workspace-package dependencies to be declared explicitly, and rustc receives direct external crates through `--extern`. Therefore, after a boundary is a separate package, a source import without a declared edge becomes a compiler error. Cargo also deliberately exposes stable, versioned project metadata for external tooling. ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html))

**Architectural alternatives**

| Alternative | Analysis | Decision |
|---|---|---|
| One package, modules plus `pub(crate)`/`pub(super)` | Enforces visibility of items, not a durable dependency direction between architectural layers. Any API visible to another part of the package can also be named by the nominally inner layer. It also has no declared package graph. | Reject |
| Multi-package workspace without a policy checker | Undeclared imports fail compilation, but a developer can add an outward dependency to a member `Cargo.toml`; the build then succeeds. F007 and F010 remain review-only. | Reject as incomplete |
| One core package plus a source architecture scanner | Can express module-level rules without extra packages, but current Rust candidates are young and do not all resolve names exactly as rustc does. | Runner-up |
| Multi-package workspace plus generic dependency tool | `cargo-depgraph-check` covers direct internal allowlists but explicitly ignores external packages; cargo-deny, Machete, and Hakari solve different problems. | Incomplete |
| Multi-package workspace plus local `cargo metadata` checker | Uses compiler packages as hard boundaries, while a small repository-owned check expresses incoming/outgoing allowlists, core external policy, namespace rules, and strict member coverage. Closely follows Rust’s own `tidy` precedent. | **Choose** |
| Custom compiler lint/Dylint | Potentially richer semantic information, but substantially more toolchain coupling, compile cost, and stable-toolchain risk than this template warrants. | Reject |

Cargo’s feature guidance also recommends splitting conflicting functionality into separate packages rather than relying on mutually exclusive features. Accordingly, the core must not acquire `cli`, `web`, `axum`, or `clap` features. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/reference/features.html))

**Recommended member layout**

```text
rs-launch-blueprint/
├── Cargo.toml                         # virtual workspace
├── Cargo.lock
├── rust-toolchain.toml
├── crates/
│   ├── domain/                        # rs-launch-blueprint-domain
│   ├── core/                          # rs-launch-blueprint (public library)
│   ├── adapters/
│   │   └── http/                      # rs-launch-blueprint-http-adapter
│   │                                  # concrete seam remains R01-owned
│   └── composition/                   # rs-launch-blueprint-composition
├── apps/
│   ├── cli/                           # rs-launch-blueprint-cli
│   └── web/                           # rs-launch-blueprint-web
├── xtask/                             # xtask
└── tests/
    └── architecture/fixtures/
```

The minimum allowed graph is:

```text
rs-launch-blueprint-domain
            ▲
            │
   rs-launch-blueprint
            ▲
        ┌───┴──────────────┐
        │                  │
http-adapter          composition
        ▲                  ▲
        └──────────┬───────┘
                   │
          ┌────────┴────────┐
          │                 │
         cli               web
```

More precisely:

| Package | Allowed workspace dependencies |
|---|---|
| `rs-launch-blueprint-domain` | none |
| `rs-launch-blueprint` | `rs-launch-blueprint-domain` |
| R01-owned adapter packages | core-family packages only |
| `rs-launch-blueprint-composition` | core-family packages and concrete adapter packages |
| `rs-launch-blueprint-cli` | `rs-launch-blueprint`, `rs-launch-blueprint-composition` |
| `rs-launch-blueprint-web` | `rs-launch-blueprint`, `rs-launch-blueprint-composition` |
| `xtask` | no production packages |

Additional constraints:

- Only CLI and web may depend on composition.
- CLI and web may not depend on one another.
- Core-family packages may not depend on adapters, composition, CLI, or web—even as dev- or build-dependencies.
- Adapters may not depend on composition or frontends.
- A future architectural layer or bounded context requiring directionality becomes another package. It must not remain merely a sibling module.
- Tests needing the composed application live under CLI/web or a separately classified acceptance frontend, never as a core dev-dependency.

**Workspace root**

```toml
[workspace]
resolver = "3"
members = [
  "crates/domain",
  "crates/core",
  "crates/adapters/*",
  "crates/composition",
  "apps/cli",
  "apps/web",
  "xtask",
]

[workspace.package]
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unsafe_code = "forbid"

[workspace.dependencies]
rs-launch-blueprint-domain = {
  version = "0.1.0",
  path = "crates/domain",
}
rs-launch-blueprint = {
  version = "0.1.0",
  path = "crates/core",
}
rs-launch-blueprint-http-adapter = {
  version = "0.1.0",
  path = "crates/adapters/http",
}
rs-launch-blueprint-composition = {
  version = "0.1.0",
  path = "crates/composition",
}
cargo_metadata = {
  version = "=0.23.1",
  default-features = false,
}
```

Resolver 3 is the edition-2024-era workspace resolver documented by the Rust Book. Cargo’s `workspace.metadata` section is explicitly available for external tool configuration and ignored by Cargo itself. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html))

**Declared graph policy**

Store the policy in the workspace manifest rather than duplicating it in documentation:

```toml
[workspace.metadata.architecture]
schema = 1
package-prefix = "rs-launch-blueprint"
package-name-exceptions = ["xtask"]

core-packages = [
  "rs-launch-blueprint-domain",
  "rs-launch-blueprint",
]

# Resolved-graph CI guard. Keep this focused on unmistakably outer frameworks.
forbidden-core-reachable = [
  "axum",
  "axum-core",
  "axum-macros",
  "clap",
  "clap_builder",
  "clap_derive",
]

[workspace.metadata.architecture.packages."rs-launch-blueprint-domain"]
allow-workspace = []
allow-external = []

[workspace.metadata.architecture.packages."rs-launch-blueprint"]
allow-workspace = ["rs-launch-blueprint-domain"]
# Exact list; add only dependencies approved for the framework-neutral core.
allow-external = []

[workspace.metadata.architecture.packages."rs-launch-blueprint-http-adapter"]
allow-workspace = ["rs-launch-blueprint"]

[workspace.metadata.architecture.packages."rs-launch-blueprint-composition"]
allow-workspace = [
  "rs-launch-blueprint",
  "rs-launch-blueprint-http-adapter",
]
allowed-dependents = [
  "rs-launch-blueprint-cli",
  "rs-launch-blueprint-web",
]
forbid-direct-external = ["axum", "clap"]

[workspace.metadata.architecture.packages."rs-launch-blueprint-cli"]
allow-workspace = [
  "rs-launch-blueprint",
  "rs-launch-blueprint-composition",
]

[workspace.metadata.architecture.packages."rs-launch-blueprint-web"]
allow-workspace = [
  "rs-launch-blueprint",
  "rs-launch-blueprint-composition",
]

[workspace.metadata.architecture.packages.xtask]
allow-workspace = []
allow-external = ["cargo_metadata"]
```

The exact core external allowlist must be populated from the dependencies selected by their owning items. R02 owns the requirement that the set is exact and reviewed, not the choice of serialization, error, tracing, or transport crates.

**Checker behavior**

The `xtask` checker has two modes:

1. `--declared`
   - Runs `cargo metadata --format-version=1 --no-deps --locked`.
   - Requires every workspace member to have exactly one policy entry.
   - Compares all normal, build, dev, optional, renamed, and target-specific direct dependencies against the declared allowlists.
   - Enforces composition’s incoming allowlist.
   - Enforces package-prefix naming.
   - Rejects policy entries for missing packages and packages missing policy entries.
   - Performs cycle detection over all checked workspace-edge kinds.

2. `--resolved`
   - Performs all declared checks.
   - Runs full metadata with `--all-features --locked`.
   - Walks the resolved graph from each core package.
   - Rejects any package listed in `forbidden-core-reachable`.
   - Runs on both Ubuntu and macOS so platform-conditioned resolution is exercised.

Rust’s own `tidy` demonstrates the relevant full-mode pattern: `MetadataCommand`, all features, `--locked`, recursive graph traversal, and explicit permitted dependencies. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs))

**Why `cargo check --no-default-features -p core` is insufficient**

It remains useful as a supporting compile check, but it does not enforce the policy:

- An unused forbidden dependency still passes.
- Adding and then using `axum` or `clap` makes the compile pass.
- Optional dependencies can disappear under `--no-default-features`.
- Build-, dev-, renamed-, and target-specific dependencies need explicit treatment.
- It does not declare or validate incoming edges to composition.

The graph checker is therefore authoritative for the dependency policy; `cargo check` proves that source code also compiles within the permitted graph.

**Observable acceptance criteria**

| Feature | Required observable result |
|---|---|
| F003 composition isolation | Adding composition to domain, core, or an adapter exits non-zero and reports the incoming/outgoing rule |
| F004 inward-only core | Adding any adapter, composition, CLI, or web package to a core-family manifest exits non-zero |
| F005 frontend independence | Adding CLI→web or web→CLI exits non-zero |
| F006 core layering | Adding core→domain is allowed; domain→core exits non-zero. Further declared layers must be separate packages |
| F007 mechanical enforcement | All negative fixtures fail in hooks and required CI without reviewer intervention |
| F008 authoritative framework guard | Full resolved CI mode rejects `axum`/`clap` reachable from a core package under all features |
| F009 fast mirror | Declared metadata mode runs pre-commit on manifest/policy changes; a core-only `cargo check` runs on core source changes |
| F010 declared graph | A new member without a policy entry, stale entry, undeclared edge, or cycle exits non-zero |
| F020 namespacing | Every production package is `rs-launch-blueprint` or starts `rs-launch-blueprint-`; no wrapper `pub mod rs_launch_blueprint` is introduced |
| F021 workspace topology | All architectural layers named above are distinct Cargo member packages |
| F116 placement | Fast mode is pre-commit; resolved mode is pre-push and required CI |

**Package namespacing**

Rust’s equivalent of Python’s package directory is the Cargo package/crate identity. Use:

- Public library package: `rs-launch-blueprint`, imported as `rs_launch_blueprint`.
- Internal packages: `rs-launch-blueprint-*`.
- Short role-oriented directories such as `crates/core`; directory nesting does not provide the namespace.
- No crate-root `pub mod rs_launch_blueprint` wrapper.
- The public core may selectively re-export domain types for ergonomics, but must never re-export composition or frontends.

Cargo package/dependency names are already the names used to make crates available to source, with hyphens normalized for Rust identifiers. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html))

**Hook and CI placement**

```yaml
# lefthook.yml — proposed
pre-commit:
  parallel: true
  commands:
    architecture-declared:
      glob: "{Cargo.toml,**/Cargo.toml}"
      run: cargo xtask architecture --declared --locked
    core-check:
      glob: "{crates/domain/**/*.rs,crates/core/**/*.rs,crates/domain/Cargo.toml,crates/core/Cargo.toml}"
      run: cargo check --locked --all-targets \
        -p rs-launch-blueprint-domain \
        -p rs-launch-blueprint

pre-push:
  commands:
    architecture-resolved:
      run: cargo xtask architecture --resolved --locked
    architecture-tests:
      run: cargo test --locked -p xtask architecture
    workspace-check:
      run: cargo check --locked --workspace --all-targets --all-features
```

CI runs `architecture-resolved` first as a required job on both `ubuntu-latest` and `macos-latest`. Expensive test jobs depend on it. Lefthook 2.1.14 was the latest surfaced release on 2026-09-17. ([github.com](https://github.com/evilmartians/lefthook))

**Performance evaluation**

Runtime application latency, throughput, and shipped binary size are **inapplicable**: the checker is dev-only and is not linked into the library, CLI, or web binary.

The relevant workload is developer-check latency:

- Workspace: seven member packages, one adapter, all targets.
- Toolchains: Rust 1.96.1 and 1.98.1.
- Platforms: Ubuntu and macOS.
- Configurations: clean cache and warm cache.
- Instrumentation:
  - Linux: `/usr/bin/time -v`.
  - macOS: `/usr/bin/time -l`.
  - Record wall, user, system time, and peak RSS.
- Proposed budget:
  - Declared metadata check: warm median ≤2 seconds, p95 ≤5 seconds.
  - Core-only warm check: p95 ≤10 seconds.
  - If core-only p95 exceeds 10 seconds, retain only metadata mode at pre-commit and move core compilation to pre-push.
- No claim is made that more crates are absolutely faster. They add package/build bookkeeping but may improve incremental invalidation isolation. The Rust survey’s continuing compile-time concern justifies measuring rather than assuming. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))

These timings are **proposed acceptance measurements, not executed benchmark results**.

**Baseline reviews**

`BASELINE-REVIEW: F006 — mechanically enforced core layering — promote each directional core layer or bounded context to a Cargo package, affecting F021 implementation but not reopening R01/F011 — module visibility does not provide the same hard dependency edge as an absent Cargo dependency; Cargo/rustc make package dependencies explicit and build-breaking.`

`BASELINE-REVIEW: F009 — fast local framework-bleed feedback — use declared dependency policy plus a core-only compile as the primary Rust mirror, rather than a source-name denylist — rustc only exposes declared direct dependencies through --extern, while source-name lints do not encode the complete Cargo graph.`

`BASELINE-REVIEW: F020 — namespace identity — use Cargo package/crate names with a shared prefix, not a Python-style nested source directory or a crate-root wrapper module — package names already supply Rust’s dependency namespace.`

`BASELINE-REVIEW: F116 — earliest economical mechanical feedback — add the no-codegen declared graph check at pre-commit and retain resolved/full checks at pre-push and CI, rather than copying Python’s pre-push-only placement — Cargo metadata is designed for tooling, while compile/resource cost remains a documented Rust productivity concern.`

**Perplexity**

The shared requirement across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint` for this item is **mechanical enforcement of architectural boundaries in a hexagonal core with multiple front-ends**, rather than relying on conventional discipline or code review alone. In the Python template, this is explicitly encoded via `import-linter` contracts (`forbidden`, `layers`, `independence`), `tach` module graph declarations, and `ruff`’s banned-API checks, which together enforce that the composition root is only importable by front-ends, core cannot import front-ends, front-ends cannot import each other, core has internal layering, and frameworks do not bleed into core.[docs/port/DIVERGENCE-ANALYSIS.md; pyproject.toml] The owner’s clarified mandate is to preserve this level of agreement—the architectural pattern and mechanical enforcement principle—while allowing ecosystem-specific implementations where justified by language and tooling differences. The observable acceptance criteria are: any violation of the declared boundaries must be detectable automatically, must fail fast (locally and in CI), and should ideally be a compile-time or static-analysis error rather than a runtime issue; the dependency graph must be declared and inspectable; and core’s independence from frameworks and front-end crates must be demonstrable in the workspace’s configuration and module graph.

For Rust, hexagonal architecture and domain-driven design are well supported patterns. The Rust architecture patterns guidance explicitly recommends hexagonal architecture paired with domain-driven design for domain-heavy systems, explaining that Rust traits naturally express ports, adapters are implemented via trait implementations, and the dependency rule (outer layers depend on inner layers, never the reverse) is enforceable via module visibility.[7] It emphasizes that dependencies should flow inward, that core domain code should have no external dependencies, and that outer layers should depend on inner layers to keep business logic testable and portable.[7] This aligns directly with the Python template’s core vs front-end split and port/adapter seam, which R01 will decide in detail. The same guidance recommends using Cargo workspaces for multi-crate systems, making the core domain crate framework-agnostic and having thin API and CLI crates depend on the core, with workspace-level dependency governance enforced via tools like `cargo-deny`.[7][8] In other words, the architectural pattern—hexagonal core, ports and adapters, inward-only dependencies—is shared across ecosystems and remains appropriate for Rust.

The key architectural alternatives in Rust are:

First, **single-crate monolith with module-level visibility enforcement**, where the entire application (core, adapters, composition) lives in one crate, and boundaries are enforced by module visibility (`pub(crate)`, `pub(super)`), conventions around which modules may import which, and perhaps internal linting. Second, **multi-crate Cargo workspace with explicit core and adapter crates**, where core, CLI, and web-service are separate crates, and dependency rules are enforced at the crate level by what appears in each `Cargo.toml`, with additional tooling to govern third-party dependencies and module graphs. Third, **multi-crate workspace with further crate-level layering inside the core**, where the core is split into multiple crates representing domain, application, and infrastructure layers, with dependency direction encoded in crate dependencies.

The single-crate alternative can use visibility rules to prevent direct access from outer modules into inner implementation details and to keep composition-root code isolated in a module that is only imported by front-ends. However, it cannot prevent core code from using framework crates or CLI/web dependencies if those crates are declared in `Cargo.toml`, because any module in the crate can import any external dependency available to the crate. In addition, enforcing front-end independence and forbidden module imports requires either manual adherence or custom static-analysis tooling that recognizes module naming conventions, which is analogous to Python’s `import-linter` but is not widely available in Rust. This alternative fails the acceptance criterion that illegal dependencies should be build-breaking errors by construction; they would only be errors if caught by an additional linter.

The multi-crate workspace alternative, with separate `core`, `cli`, and `web` crates, directly encodes boundaries at the dependency level. If the `core` crate does not list `clap`, `axum`, or other frameworks in its `Cargo.toml`, then it cannot import them; any attempt to use them would fail to compile, making framework bleed and front-end dependencies into core impossible without changing the workspace’s dependency configuration. Similarly, if `cli` and `web` do not list each other as dependencies, they cannot import each other’s code, ensuring front-end independence. The composition root can be a separate crate (`composition`) that depends on core and is imported only by front-ends, and core cannot depend on it because its `Cargo.toml` does not include `composition`. This matches the Python template’s composition-root isolation pattern but leverages Rust’s stronger compile-time enforcement. Because Cargo workspaces share a lock file and target directory, they also support efficient compilation and cross-crate dependency deduplication, which the Reintech article notes as a key benefit for large Rust projects.[8] This alternative satisfies the acceptance criteria for mechanical enforcement of boundaries via compile-time errors.

The multi-crate core layering alternative extends this by separating core into multiple crates (for example, `core-domain`, `core-application`, `core-infra`), with dependency rules such as “application depends on domain, infra depends on domain and application, but domain depends on nothing outside itself.” This can encode internal layering more explicitly and make violations (e.g., domain depending on infrastructure) compile-time errors. However, it introduces more crates, which the Reintech article warns can increase compilation overhead and cognitive load if overused; it suggests that crates should be created based on function and change frequency, not for every module.[8] For the template, a single core crate with internal layering enforced by module visibility and a module-graph tool may be sufficient, especially given that R01 will define the port/adapter seam.

Given these alternatives, the recommended implementation for `rs-launch-blueprint` is **a multi-crate Cargo workspace with a single core crate and separate CLI, web, and composition-root crates, plus explicit dependency governance and module-graph tooling**. This design preserves the shared hexagonal principles, leverages Rust’s strengths around compile-time enforcement and visibility, and minimizes unnecessary complexity in the core while still allowing internal layering to be declared and inspected.

On tooling, the high-level question is whether `cargo-deny`’s `bans` graph, a custom `cargo metadata`-driven lint, or a workspace-lint tool like `cargo-hakari` or `cargo-machete` is the Rust analogue of `tach`’s module dependency graph and `import-linter` contracts. `cargo-deny` is the closest match for dependency governance at the crate and third-party level, allowing explicit bans on certain frameworks and exceptions for wrappers, which matches the framework-bleed guard requirement.[9][10][16] However, `cargo-deny` operates primarily at the crate-dependency level, not module-level layering within a crate. `cargo-machete`, as described by its author, uses heuristic regex-based matching over source files to detect unused dependencies, and explicitly warns that it is fast but imprecise and may report false positives, making it unsuitable as an authoritative boundary-enforcement tool.[2][3][4][14] Tools like `cargo-hakari` focus on feature unification and dependency deduplication rather than architectural rules. Thus, none of these is a direct analogue of `tach`’s arbitrary module-layer contracts.

Instead, the Rust analogue of `tach` and `import-linter` for declared graphs and layer contracts is best achieved by combining `cargo metadata` (for crate-level graph), `dep_graph_rs` or `cargo-modules` (for module-level graph), and a small custom “arch-check” harness that encodes specific boundary rules (e.g., “module `core::domain` may not depend on `core::infra`” or “crate `core` must not import any type from crate `cli` or its dependency tree”). `cargo-modules`’ ability to print internal module dependencies as a graph and detect orphan files provides a foundation for understanding module-level structure, while `dep_graph_rs`’s DOT graph output and filtering capabilities enable focused analysis of particular modules or items.[11][18] A custom harness can consume these graphs and enforce rules analogous to import-linter’s `forbidden` and `layers` contracts. This approach respects the owner’s mandate that architectural patterns be shared across ecosystems but allows the Rust implementation to use ecosystem-specific tooling when no direct off-the-shelf analogue exists.

On framework-bleed guards (F008, F009), the Rust analogue of Python’s authoritative CI check plus fast local mirror is a combination of workspace dependency design and `cargo-deny` configuration. By banning framework crates (e.g., `clap`, `axum`, `tauri`) in `deny.toml`’s `bans` section and designating front-end crates as `wrappers` where banned crates are allowed, `cargo-deny` can ensure that frameworks appear only under front-end crates and not in core or composition.[9][10] Because `cargo-deny` integrates both as a Cargo plugin (`cargo deny check`) and as a GitHub Action, it can run in CI on every push or pull request, and via Lefthook as a pre-push hook for local checks.[15][16] This matches the two-tier enforcement model in Python, with the important difference that Rust’s core crate’s `Cargo.toml` already prevents framework usage by not listing those dependencies, making `cargo-deny` a reinforcing guard rather than the sole enforcement mechanism.

Regarding hook placement (F116), the GitLab Rust CI example shows pre-push hooks running tests, formatting, and linting before code is pushed, emphasizing developer workflow enhancements and catching issues locally.[6] Given Rust’s compile times and the cost of running full workspace checks, it is appropriate to follow Python’s precedent: heavy checks like `cargo-deny` and the arch-check harness should run at pre-push and in CI, while lighter checks like formatting and basic clippy lints may run at pre-commit. This preserves the principle of a fast local mirror of authoritative checks without making every commit prohibitively expensive.

For package namespacing (F020), Rust crates are already namespaced by their `Cargo.toml` `name` field, unlike Python where directory layout and package names must be coordinated. The RustZ2H guide shows workspace members `core`, `web`, `desktop`, and `cli`, each with `[package]` name, and workspace-level inheritance of version, edition, authors, and license via `[workspace.package]` fields.[5] For `rs-launch-blueprint`, the equivalent is to use crate names such as `rs_launch_blueprint_core`, `rs_launch_blueprint_cli`, `rs_launch_blueprint_web`, and `rs_launch_blueprint_composition`, ensuring a consistent `rs_launch_blueprint_*` namespace and relying on Rust’s crate system for package namespacing. There is no need for directory nesting under `src/rs_launch_blueprint`, because crates already provide that level of namespacing; the key is to align crate names with the template’s overall name and maintain consistency across front-ends and core.

No baseline principle is being overturned here; instead, Python’s hexagonal boundaries and mechanical enforcement are being preserved at the pattern level and realized via Rust’s idiomatic mechanisms. There is, however, one **BASELINE-REVIEW** worth noting. 

BASELINE-REVIEW: F010 — declared module dependency graph — proposed change: in Rust, the declared graph should be primarily crate-level via workspace and `cargo metadata`, with module-level graphs generated via `dep_graph_rs` or `cargo-modules` and enforced by a custom arch-check harness, rather than a standalone `tach`-like tool. Evidence: the lack of established Rust tools that combine graph generation with declarative layer contracts, the availability of `cargo-modules` and `dep_graph_rs` for graph generation, and the practice-oriented guidance from Rust architecture patterns recommending workspace-based dependency governance rather than module-level linting.[7][11][18] This is a change in implementation, not in the principle that a declared graph must exist and be checked.

**Gemini**

The fundamental engineering principle binding the `py`, `ts`, and `rs` implementations of the `launch-blueprint` is the prioritization of mechanical boundary enforcement over conventional discipline (F007). The software architecture must guarantee that the core domain remains entirely ignorant of its delivery mechanisms—whether that be a CLI invocation or an HTTP request—and entirely decoupled from its external infrastructure, such as database drivers or third-party APIs. This architectural purity requires strict inward-only dependencies (F004), absolute independence between frontend adapters (F005), and robust, multi-layered defense mechanisms against external framework bleed (F008, F009).

In the Python precedent, this level of strictness is achieved post-facto via `import-linter` and `tach`. These tools parse the dynamic module import statements at runtime or during a linting pass, cross-referencing them against a declared, human-readable contract found in `tach.toml` or `pyproject.toml`. Rust, however, provides a fundamentally different paradigm through its Ahead-of-Time (AOT) compiler and explicit dependency resolution model. The implementation of these shared principles in Rust necessitates mapping the abstract requirements to the appropriate compiler-native and static-analysis mechanisms, recognizing that the Rust compiler itself can serve as the most rigorous boundary enforcer if configured correctly.

A critical architectural decision, dictating the entire structure of the repository, is whether to utilize a single overarching crate relying purely on module visibility modifiers (`pub(crate)`, `pub(super)`) or to construct a genuine multi-crate Cargo workspace (F021). Relying on module visibility within a single crate is wholly insufficient for rigorous, mechanical boundary enforcement. While `pub(crate)` restricts access from external consumers of the library, it does absolutely nothing to prevent a developer from accidentally—or intentionally—importing an adapter module into the core module within the same crate boundary. Furthermore, a single crate forces a unified dependency tree; it is impossible to add `axum` to a single crate without it simultaneously being available to the domain logic.

Therefore, a multi-crate virtual Cargo workspace is the mandatory structural foundation for `rs-launch-blueprint` [cite: 1, 2]. By dividing the project into physically distinct crates (e.g., `crates/core`, `crates/cli`, `crates/web`, `crates/composition`), the Rust compiler inherently and un-bypassably enforces F004 (core inward-only) and F005 (front-end independence). A Rust crate cannot utilize another crate unless it is explicitly declared in its specific `Cargo.toml` file. If `crates/core/Cargo.toml` does not list `cli` in its `[dependencies]` table, the compiler makes it physically impossible for any code within the `core` to import the `cli`. This elevates boundary enforcement from a secondary linting step to a foundational compiler guarantee, satisfying the mandate for mechanical over conventional enforcement (F007) at the highest possible level of authority.



Keeping the `core` crate entirely devoid of framework specifics—such as `axum` for HTTP or `clap` for command-line parsing—requires a sophisticated two-tiered defensive approach to prevent framework bleed (F008, F009). The first tier is the authoritative Continuous Integration (CI) guard (F008). Here, `cargo-deny` serves as the absolute authority. Utilizing the `[bans]` section within a workspace-root `deny.toml` configuration, the workspace can explicitly forbid the `core` crate from resolving specific external dependencies, even transitively [cite: 20, 21]. This means that if a seemingly innocuous utility crate is added to the `core`, and that utility crate secretly depends on `tokio` or `axum`, `cargo-deny` will fail the build, preventing transitive abstraction leakage. 

The second tier is the fast local mirror (F009). While `cargo-deny` audits the graph, developers require immediate, sub-second feedback within their Integrated Development Environment (IDE). `cargo clippy` provides this capability. By configuring a `clippy.toml` file exclusively within the `crates/core` directory, the `disallowed_types` and `disallowed_names` arrays can explicitly ban types like `axum::extract::State` or `clap::Parser` from ever being referenced in the source code [cite: 3, 5, 22]. This configuration acts as the exact mechanical analogue to `ruff`'s `TID251` banned-api lint utilized in the Python precedent, immediately highlighting architectural violations in the developer's editor before a commit is even constructed.

While Cargo workspaces efficiently isolate macroscopic crates, Hexagonal Architecture often dictates strict layering *within* the core context itself (e.g., isolating the pure Domain layer from the Application or UseCase layer). Because Cargo does not govern intra-crate module graphs, relying solely on workspaces for this granularity would force the creation of micro-crates (e.g., `core-domain`, `core-application`). This micro-crating approach introduces severe compilation overhead, vastly increases boilerplate, and degrades developer ergonomics [cite: 1, 20]. 

To satisfy the requirements for core internal layering (F006) and a bounded-context module dependency graph (F010) without fracturing the workspace into unmanageable micro-crates, the `boundary-rust` tool is introduced into the stack. Operating analogously to Python's `tach`, `boundary-rust` leverages the `tree-sitter` library to parse Rust source code directly into Abstract Syntax Trees (ASTs). It then validates all intra-crate `use` statements against a declared architectural contract residing in a `.boundary.toml` file [cite: 10, 23]. This ensures that, for instance, the Domain module cannot import the Application module, fulfilling the requirement for a declared, bounded-context dependency graph at the module level while keeping the `core` crate physically unified.

Package namespacing (F020) presents another area where Rust diverges from Python's conventions. Python achieves package namespacing via physical directory nesting (e.g., `src/py_launch_blueprint/core`). Rust idiomatically utilizes flat directory structures for workspaces (e.g., `crates/core/src/lib.rs`), but effectively namespaces the compiled artifacts via the `name` field in each member's `Cargo.toml` [cite: 14, 19]. For `rs-launch-blueprint`, the workspace members will physically reside in `crates/<member>` directories for structural clarity, but their `Cargo.toml` package names will be strictly prefixed (e.g., `rs_launch_blueprint_core`). This dual approach adheres strictly to Rust's flat-directory file system idiom while simultaneously preserving the global namespace uniqueness demanded by F020.

Finally, the placement of these checks within the development lifecycle (F116) requires balancing mechanical enforcement with developer velocity. Due to Rust's Ahead-of-Time compilation model, executing a full `cargo check` alongside a comprehensive graph dependency audit can consume several seconds, creating unacceptable friction if placed on every local commit. To optimize this, `cargo deny check bans` and `boundary check` are attached exclusively to the `pre-push` hook via `lefthook`, mirroring Python's authoritative placement. Fast local checks, specifically code formatting and the `clippy.toml` banned-types checks, are executed continuously during in-editor analysis via `rust-analyzer` and optionally enforced at a faster `pre-commit` tier [cite: 9, 24].

### Recommendation

**OpenAI**

Adopt this one stack:

1. **Compiler-first multi-package Cargo workspace**
   - Rust/Cargo **1.98.1** for the pinned current toolchain.
   - Edition **2024**, resolver **3**.
   - `rust-version = "1.96"` and CI on **1.96.1** as the current stable-minus-two floor.
   - Separate `domain`, public `core`, R01-owned adapter, `composition`, `cli`, and `web` packages.

2. **Repository-local `xtask` 0.1.0 architecture checker**
   - `cargo_metadata = 0.23.1`, pinned exactly and dev-only.
   - Policy in `[workspace.metadata.architecture]`.
   - Fast declared mode plus authoritative resolved mode.
   - Patterned on the Rust compiler’s maintained `tidy` implementation.

3. **Lefthook 2.1.14 plus required GitHub Actions architecture job**
   - Declared graph and core-only check at pre-commit.
   - Resolved graph, negative fixtures, and full workspace check at pre-push.
   - Resolved graph first in CI on Ubuntu and macOS.

Do **not** use `cargo-deny`, `cargo-hakari`, or `cargo-machete` as the R02 architecture checker. They remain useful for their own supply-chain, feature-unification, or unused-dependency responsibilities.

**Perplexity**

The recommended stack for `rs-launch-blueprint` is a **multi-crate Cargo workspace with explicit core and front-end crates, governed by `cargo-deny` and a custom arch-check harness that uses `dep_graph_rs` or `cargo-modules` for module graphs, integrated into Lefthook pre-push hooks and CI**. Concretely, the workspace topology should consist of at least the following crates:

A `core` crate (`rs_launch_blueprint_core`) containing all domain and application logic, with no direct dependencies on framework crates or front-end crates. A `composition` crate (`rs_launch_blueprint_composition`) that implements the composition root, wiring together core ports with specific adapters; it depends on `core` and abstractions defined by R01 but is itself only depended on by front-end crates. A `cli` crate (`rs_launch_blueprint_cli`) implementing the command-line interface, depending on `core` and `composition`, and on CLI-specific frameworks such as `clap` and `tokio`. A `web` crate (`rs_launch_blueprint_web`) implementing the web service, depending on `core` and `composition`, and on web frameworks such as `axum` or `warp` and `tokio`. Optionally, a `test-support` or `examples` crate may be added for integration tests and examples, but it should depend on `core` and adapters only as needed and remain outside the main dependency chain.

This topology enforces composition-root isolation (core cannot depend on `composition`, but front-ends do), inward-only core dependencies (outer crates depend on `core`, not vice versa), and front-end independence (front-end crates do not depend on each other). Internal layering within `core` is enforced by module visibility (`pub(crate)`, `pub(super)`) and documented via module graphs generated by `dep_graph_rs` or `cargo-modules`, with the arch-check harness asserting layer contracts and failing if module dependencies violate declared rules.[7][11][18] Framework-bleed guards are implemented via both dependency design (framework crates only appear in front-end `Cargo.toml`s) and `cargo-deny` `bans` configuration, which bans framework crates globally but allows them under designated front-end wrapper crates.[9][10][16]

The stack includes `cargo-deny` as the primary dependency governance tool, installed via `cargo install --locked cargo-deny` and initialized with `cargo deny init` to create a default `deny.toml`, then customized to reflect the template’s specific bans and workspace behavior.[15][16] It also includes a module-graph tool, preferably `dep_graph_rs` for DOT-output graphs, used in an arch-check harness to generate and validate module dependency graphs, and optionally `cargo-modules` for human-readable module structure and orphan detection.[11][18] For unused dependency detection and hygiene, `cargo-udeps` may be included, following Microsoft’s guidance on trimming dependencies to reduce binary size and supply-chain risk, but it is not central to boundary enforcement.[13][14] Hook and CI integration rely on Lefthook for pre-push hooks (running `cargo test --workspace`, `cargo clippy --workspace`, `cargo deny check`, and the arch-check harness) and on GitHub Actions for running these checks in CI, with `EmbarkStudios/cargo-deny-action@v1` as the standard `cargo-deny` integration.[6][16]

This stack provides a coherent, Rust-idiomatic implementation that preserves the hexagonal boundary principles, enforces them mechanically, and aligns with established tools and practices for dependency governance and workspace design.

**Gemini**

The recommended, integrated stack to mechanically enforce all architectural boundaries for `rs-launch-blueprint` consists of a natively compiled virtual workspace guarded by a multi-layered static analysis pipeline:

1.  **Cargo Workspaces**: A virtual workspace defining distinct crates (`core`, `cli`, `web`, `composition`) to enforce macroscopic, compiler-level DAG boundaries and isolate dependencies (F021).
2.  **rust-clippy**: Configured via a `core`-specific `clippy.toml` to explicitly ban external framework types (`disallowed_types`), serving as the fast, local IDE framework-bleed guard (F009).
3.  **cargo-deny**: Configured via a workspace-root `deny.toml` to provide authoritative CI bans on dependency resolution, preventing transitive framework bleed and duplicate crate versions across the workspace (F008).
4.  **boundary-rust**: An AST-driven static analysis tool configured via `.boundary.toml` to enforce declared module dependency graphs and strict internal layering *within* the unified `core` crate (F006, F010).
5.  **lefthook**: The high-performance orchestrator that executes `cargo deny`, `cargo clippy`, and `boundary check` concurrently at the `pre-push` tier (F116).

### Members

**OpenAI**

#### Cargo/rustc multi-crate boundary pattern — 1.98.1, MSRV 1.96.1 (OpenAI)

##### Landscape

Cargo workspaces and rustc dependency resolution are the built-in foundation. Cargo makes workspace-package relationships explicit; rustc receives direct dependencies through `--extern`. Workspaces also centralize lockfiles, target output, package metadata, dependencies, and lints. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html))

##### Principles and implementation

The compiler should reject an illegal source dependency before any architecture linter is considered. That requires a genuine package boundary. Within a single package, visibility should still be used for encapsulation, but no sibling module should be treated as a separately enforced architectural layer.

##### Dominant choice

A virtual workspace with distinct packages for every required directional boundary is the dominant choice for R02.

##### Qualified shortlist

1. Separate domain and application/core packages, plus adapter/composition/frontend packages — chosen.
2. A still more granular package per bounded context where multiple contexts actually exist.
3. A single core package plus a mature module architecture analyzer — qualified only as a future simplification candidate.

##### Excluded by gate

- **Single package with `pub(crate)`/`pub(super)`:** fails F006, F007, F010, and F021 capability.
- **Core package with optional `cli` or `web` features:** fails framework-neutrality because Cargo features are additive and allow outer framework crates into the core graph.
- **Review-only workspace:** fails mechanical-policy enforcement.
- **Bazel/Buck visibility:** excessive integration and toolchain cost for a Cargo-first template.

##### Up-and-comers

cargo-arc, Archaven, and cargo-archtest may eventually make a one-core-package design defensible, but their current evidence does not justify replacing compiler package boundaries. ([docs.rs](https://docs.rs/crate/cargo-arc/latest/source/README.md))

##### Fit for this template

The template has three consumers with materially different dependencies:

- Library users need only the framework-neutral core.
- CLI owns CLI parsing and presentation.
- Web owns HTTP framework types and handlers.

Composition is shared wiring but is not public library API. A package split prevents CLI/web framework dependencies from entering library consumers’ build graphs.

##### Recommendation

| Directory | Package | Version | Publish default |
|---|---|---:|---|
| `crates/domain` | `rs-launch-blueprint-domain` | 0.1.0 | yes, because public core depends on it |
| `crates/core` | `rs-launch-blueprint` | 0.1.0 | yes |
| `crates/adapters/http` | `rs-launch-blueprint-http-adapter` | 0.1.0 | no |
| `crates/composition` | `rs-launch-blueprint-composition` | 0.1.0 | no |
| `apps/cli` | `rs-launch-blueprint-cli` | 0.1.0 | no; distribute release binaries |
| `apps/web` | `rs-launch-blueprint-web` | 0.1.0 | no |
| `xtask` | `xtask` | 0.1.0 | no |

Crate-ecosystem figures are **inapplicable** to these members because they are proposed project packages, not existing candidate crates.

##### Ranked runner-up

A four-package layout with one `rs-launch-blueprint` core package, composition, CLI, and web, augmented by cargo-arc or Archaven for internal core modules. It reduces release and workspace complexity but places F006 on a younger source analyzer instead of rustc.

##### Tradeoffs

Advantages:

- Illegal imports fail compilation.
- Core dependencies are not pulled into CLI/web consumers accidentally.
- Internal layering uses the same mechanism as top-level layering.
- Incremental rebuilds can be isolated by package.

Costs:

- More manifests and package versions.
- `rs-launch-blueprint-domain` must be published before or with the public core.
- Moving types between domain and application becomes a cross-package API change.
- More packages do not guarantee faster clean builds.

##### Parameters

- `edition = "2024"`
- `resolver = "3"`
- `rust-version = "1.96"`
- CI toolchains: `1.96.1`, `1.98.1`
- `license = "MIT OR Apache-2.0"`
- Platforms: `ubuntu-latest`, `macos-latest`
- R01 seam form remains unspecified.

##### Migration implications

- Convert the root manifest to a virtual workspace.
- Move the current library implementation into `crates/core`.
- Extract innermost domain code into `crates/domain`.
- Move CLI and web entrypoints into independent member packages.
- Add composition and R01-owned adapter packages.
- Replace relative module imports with package imports.
- Selectively re-export domain API from `rs-launch-blueprint`; never re-export composition.

##### Validation strategy

Planned checks:

```bash
cargo +1.96.1 check --locked --workspace --all-targets
cargo +1.98.1 check --locked --workspace --all-targets --all-features
cargo +1.98.1 test --locked --workspace
```

Negative proof:

- Add `rs-launch-blueprint-web` to core and expect the architecture checker to fail.
- Remove the dependency and add `use rs_launch_blueprint_web::...`; expect rustc to fail with an unresolved crate.
- Add core to domain; expect the architecture checker to fail and, if it creates a normal dependency cycle, Cargo itself to reject it.

No integration commands were executed during this research response.

##### Confidence & re-verify trigger

**High confidence** in the package-boundary decision.

Re-verify if a stable Rust feature introduces enforceable module-level dependency visibility, or if a mature module analyzer reaches stable 1.x, publishes numeric MSRV and cross-platform guarantees, and demonstrates multiple substantial production adopters.

##### Sources

- `https://doc.rust-lang.org/cargo/reference/workspaces.html` — retrieved 2026-09-17. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html))
- `https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html` — retrieved 2026-09-17. ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html))
- `https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html` — retrieved 2026-09-17. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html))
- `https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md` — retrieved 2026-09-17. ([github.com](https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md))
- `https://rust-analyzer.github.io/book/contributing/architecture.html` — retrieved 2026-09-17. ([rust-analyzer.github.io](https://rust-analyzer.github.io/book/contributing/architecture.html))

#### Repository-local `xtask` 0.1.0 with `cargo_metadata` 0.23.1 (OpenAI)

##### Landscape

The alternatives are:

- First-party `cargo metadata` JSON consumed directly.
- `cargo_metadata`, the maintained Rust interface recommended by Cargo’s external-tools documentation.
- A repository-local checker.
- Generic architecture CLIs.

Cargo explicitly recommends using its versioned CLI interface instead of linking to Cargo as an unstable library, and identifies `cargo_metadata` as the Rust interface to that output. ([doc.crates.io](https://doc.crates.io/external-tools.html))

##### Principles and implementation

The checker is a policy backstop around the compiler:

- Compiler boundaries reject undeclared imports.
- The checker rejects weakening a manifest by adding an illegal dependency.
- The checked-in policy serves as the declared graph.
- Full resolved mode catches unmistakable framework packages brought into the core transitively.
- Strict coverage prevents new packages from silently bypassing the policy.

##### Dominant choice

A small repository-owned checker using `cargo_metadata` is the dominant fit because the policy is template-specific and includes both outgoing and incoming constraints.

This follows the Rust compiler’s production precedent more closely than adopting an unrelated generic tool: Rust’s `tidy` builds metadata with all features and `--locked`, recursively walks the graph, and enforces explicit permitted dependency sets. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs))

##### Qualified shortlist

1. `xtask` + `cargo_metadata` 0.23.1 — chosen.
2. `cargo-depgraph-check` 0.1.0 plus a second custom external/framework check.
3. cargo-arc, if its version, parser coverage, MSRV, platform evidence, and adoption stabilize.
4. Archaven for non-architectural, local source conventions inside a package.

##### Excluded by gate

- **`cargo-deny`:** valuable for global package bans, licenses, sources, and advisories, but not a complete member-scoped allowed workspace graph.
- **`cargo-hakari`:** feature-unification management, not architecture enforcement.
- **`cargo-machete`/cargo-shear:** unused dependency detection, not allowed dependency direction.
- **`cargo-depgraph-check` 0.1.0 as the sole checker:** its documentation explicitly says it checks direct internal workspace dependencies and ignores external dependencies. ([docs.rs](https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md))
- **cargo-arc as primary:** retrieved surfaces disagreed on whether the current release was 0.3.1 or 0.5.0, and its documentation notes module patterns that can be absent from its graph. ([docs.rs](https://docs.rs/crate/cargo-arc/latest/source/README.md))
- **Archaven as primary:** its alias handling is intentionally simple and explicitly not a replacement for rustc resolution. ([docs.rs](https://docs.rs/crate/archaven/latest))
- **cargo-archtest as primary:** numeric MSRV and macOS testing were not established; the surfaced CI example runs Ubuntu. ([docs.rs](https://docs.rs/crate/cargo-archtest-cli/0.2.3))

##### Up-and-comers

- `cargo-depgraph-check` 0.1.0 is the closest narrow generic equivalent for direct internal package allowlists.
- cargo-arc is the most ambitious combined visualization and architecture-rule candidate.
- Archaven’s test-embedded rule style is attractive for modular monoliths.
- cargo-archtest exposes familiar layer, cycle, allowed-access, and restricted-external rules.

They should be reconsidered only after satisfying the owner’s MSRV, advisory, cross-platform, and adoption gates.

##### Fit for this template

The custom checker needs approximately seven checks, all directly tied to acceptance criteria. It does not need general source parsing, a compiler plugin, or a visualization UI.

Recommended implementation characteristics:

```rust
#![forbid(unsafe_code)]

// Sketch, not complete source.
fn check_declared(metadata: &cargo_metadata::Metadata, policy: &Policy) -> Result<()> {
    check_strict_member_coverage(metadata, policy)?;
    check_package_names(metadata, policy)?;
    check_workspace_edges(metadata, policy)?;
    check_core_direct_external_dependencies(metadata, policy)?;
    check_allowed_dependents(metadata, policy)?;
    check_cycles(metadata, policy)?;
    Ok(())
}
```

Resolved mode follows package IDs, not textual names alone, and reports the shortest path from a core root to a forbidden framework package.

##### Recommendation

Use:

```toml
[package]
name = "xtask"
version = "0.1.0"
publish = false
edition.workspace = true
rust-version.workspace = true
license.workspace = true

[dependencies]
cargo_metadata.workspace = true

[lints]
workspace = true
```

```toml
[workspace.dependencies]
cargo_metadata = {
  version = "=0.23.1",
  default-features = false,
}
```

Maintenance classification: **active**. Version 0.23.1 was current in the retrieved docs; the repository is active and the API is used by the Rust compiler’s maintained tooling. ([github.com](https://github.com/oli-obk/cargo_metadata))

**Required crate figures**

| Figure | Result | Required endpoint / rule |
|---|---|---|
| 90-day downloads | Unresolved; endpoint payload was not returned by the research transport | `GET https://crates.io/api/v1/crates/cargo_metadata` → `crate.recent_downloads` |
| All-time downloads | Unresolved; endpoint payload was not returned | Same → `crate.downloads` |
| Last release | `0.23.1`; exact `created_at` unresolved | `GET https://crates.io/api/v1/crates/cargo_metadata/versions`, newest non-yanked |
| Stars, archived, pushed_at | Unresolved under the mandated API rule; HTML observations were not substituted | `GET https://api.github.com/repos/oli-obk/cargo_metadata` |
| Open issues | Unresolved under the mandated search-API rule | `GET https://api.github.com/search/issues?q=repo:oli-obk/cargo_metadata+is:issue+is:open` |
| Issue responsiveness | Unresolved; the ten-issue sample could not be retrieved reliably | Ten most recently opened issues |
| Advisories | Direct RustSec package retrieval failed; must be refreshed before merge | `https://rustsec.org/packages/cargo_metadata.html` |
| Adopter | `rust-lang/rust` `tidy`; source imports and uses `cargo_metadata` for dependency-policy enforcement | Maintained first-party production reference |

The unresolved metric fields lower evidence confidence but do not create evidence for an alternative candidate. They are hard pre-merge checks, not permission to assume zero advisories or healthy responsiveness.

##### Ranked runner-up

`cargo-depgraph-check` 0.1.0 plus a small second check for core external dependencies and package names.

Why second:

- It already provides strict direct internal allowlists.
- Its config and diagnostics closely match part of R02.
- It still requires custom code for F008, F009, F020, incoming composition constraints, and possibly dependency-kind handling.
- Adding a generic binary plus a custom checker is more moving parts than one small checker.

Its repository surfaced only one star in the retrieved GitHub page, which is contextual rather than an accepted API figure and was not used to rank it. ([github.com](https://github.com/1898andCo/cargo-depgraph-check))

##### Tradeoffs

Advantages:

- Exact fit and deterministic diagnostics.
- No parser divergence for Cargo manifests.
- Supports renamed, optional, target-specific, build, and dev dependencies.
- No shipped binary-size or runtime cost.
- The policy evolves atomically with the workspace.

Costs:

- Approximately a few hundred lines of owned tooling and fixture tests.
- `cargo_metadata` adds dev-tool compile cost.
- Policy schema changes are locally owned.
- Exact core external allowlists require deliberate updates.
- Metrics and advisory evidence must be refreshed before merge.

Unsafe posture:

- `xtask` source and workspace lints forbid unsafe.
- No claim is made that the entire third-party dependency tree is unsafe-free.
- The checker is a development dependency and is not linked into product artifacts.

##### Parameters

- `cargo_metadata = "=0.23.1"`
- `default-features = false`
- Synchronous process execution; no async runtime.
- Policy schema version: `1`
- Both declared and resolved checks use `--locked`.
- Resolved mode uses all features.
- No R01 trait/object/generic assumption.

##### Migration implications

Add:

- `xtask/Cargo.toml`
- `xtask/src/main.rs`
- `xtask/src/architecture.rs`
- `xtask/tests/architecture.rs`
- `.cargo/config.toml`:

```toml
[alias]
xtask = "run --quiet --package xtask --"
```

- `[workspace.metadata.architecture]` and package rules in root `Cargo.toml`.
- Positive and negative fixture workspaces under `tests/architecture/fixtures`.
- Fixture directories to workspace `exclude` if Cargo’s automatic membership discovery requires it.

##### Validation strategy

Planned positive checks:

```bash
cargo xtask architecture --declared --locked
cargo xtask architecture --resolved --locked
cargo test --locked -p xtask architecture
```

Planned negative fixtures:

| Fixture | Expected diagnostic |
|---|---|
| `core_depends_on_composition` | illegal workspace edge |
| `domain_depends_on_core` | layer reversal |
| `cli_depends_on_web` | frontend independence violation |
| `adapter_depends_on_composition` | outward adapter dependency |
| `third_party_depends_on_composition` | composition incoming-edge violation |
| `core_depends_on_renamed_axum` | forbidden direct external package |
| `core_optional_clap` | forbidden optional dependency |
| `core_target_axum` | forbidden target-specific dependency |
| `core_reaches_axum_transitively` | resolved framework-bleed path |
| `unclassified_member` | strict member-coverage violation |
| `bad_package_prefix` | namespace violation |
| `stale_policy_entry` | policy references absent member |

Required fitness commands before accepting the pin:

```bash
cargo +1.96.1 check --locked -p xtask
cargo +1.98.1 check --locked -p xtask
cargo audit
```

The last command may be replaced by the workspace’s already-owned RustSec-capable security tool; R02 does not take ownership of that tool selection.

##### Confidence & re-verify trigger

**High confidence** in the local-checker pattern; **medium confidence** in the exact `cargo_metadata` pin until the mandated API metrics, RustSec result, and 1.96.1 build are refreshed.

Re-verify on:

- `cargo_metadata` 0.24 or later.
- Any open RustSec advisory.
- A declared MSRV above 1.96.
- cargo-arc reaching a stable release with complete parser and cross-platform evidence.
- `cargo-depgraph-check` adding scoped external and incoming-edge rules.
- Checker source exceeding roughly 500 non-test lines, indicating a generic tool may now be cheaper.

##### Sources

- `https://doc.rust-lang.org/cargo/reference/external-tools.html` — retrieved 2026-09-17. ([doc.crates.io](https://doc.crates.io/external-tools.html))
- `https://docs.rs/cargo_metadata/latest/cargo_metadata/` — retrieved 2026-09-17. ([docs.rs](https://docs.rs/cargo_metadata/latest/cargo_metadata/struct.Source.html))
- `https://github.com/oli-obk/cargo_metadata` — retrieved 2026-09-17. ([github.com](https://github.com/oli-obk/cargo_metadata))
- `https://github.com/oli-obk/cargo_metadata/actions` — retrieved 2026-09-17. ([github.com](https://github.com/oli-obk/cargo_metadata/actions))
- `https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs` — retrieved 2026-09-17. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs))
- `https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md` — retrieved 2026-09-17. ([docs.rs](https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md))
- `https://docs.rs/crate/cargo-arc/latest/source/README.md` — retrieved 2026-09-17. ([docs.rs](https://docs.rs/crate/cargo-arc/latest/source/README.md))
- `https://docs.rs/crate/archaven/latest` — retrieved 2026-09-17. ([docs.rs](https://docs.rs/crate/archaven/latest))
- `https://docs.rs/crate/cargo-archtest-cli/0.2.3` — retrieved 2026-09-17. ([docs.rs](https://docs.rs/crate/cargo-archtest-cli/0.2.3))

#### Lefthook 2.1.14 and required CI placement (OpenAI)

##### Landscape

The choices are:

- CI only.
- Pre-push plus CI, matching the Python precedent.
- Cheap pre-commit mirror plus pre-push and CI.
- Full workspace compile at pre-commit.

Lefthook remains an invocation layer; the architecture policy lives in Cargo metadata and `xtask`, not in hook-manager-specific configuration.

##### Principles and implementation

Local checks optimize feedback latency. CI supplies authority through protected required jobs. The same policy implementation should run locally and remotely so that a “mirror” cannot drift semantically from the authoritative check.

##### Dominant choice

Run the no-codegen declared check at pre-commit, resolved mode at pre-push, and repeat resolved mode in required CI.

##### Qualified shortlist

1. Declared pre-commit + resolved pre-push/CI — chosen.
2. Declared pre-commit only on manifest changes and all compilation at pre-push.
3. Pre-push + CI only if measured pre-commit latency exceeds the budget.

##### Excluded by gate

- **CI only:** feedback is too late for a mechanical architecture rule.
- **Pre-push only:** copies Python’s placement without accounting for Cargo metadata’s cheaper no-codegen mode.
- **Full workspace all-features check at pre-commit:** conflicts with the documented Rust compile/resource-cost concern.
- **Different local and CI rule implementations:** creates policy drift.

##### Up-and-comers

No alternative hook manager changes the architecture decision. If the repository later replaces Lefthook, preserve the three-tier command semantics.

##### Fit for this template

The declared graph changes only when manifests, the lockfile, or architecture policy changes. Core compilation can also be scoped to the two small core-family packages. CLI/web frameworks therefore do not need compilation during ordinary core commits.

##### Recommendation

Pin/configure Lefthook **2.1.14** and add:

| Tier | Command | Trigger |
|---|---|---|
| Pre-commit | `cargo xtask architecture --declared --locked` | Any `Cargo.toml`, `Cargo.lock`, or root policy change |
| Pre-commit | core-only `cargo check` | Domain/core Rust or manifest change |
| Pre-push | `cargo xtask architecture --resolved --locked` | Every push |
| Pre-push | architecture fixture tests | Every push |
| Pre-push | workspace all-target/all-feature check | Every push |
| CI | resolved architecture check | Required, first job, Ubuntu + macOS |
| CI | MSRV and current-stable checks | Required, Ubuntu + macOS |

Lefthook is implemented in Go rather than published as a Rust crate, so crates.io download, release, and RustSec package figures are **inapplicable**. GitHub’s latest release page reported v2.1.14. ([github.com](https://github.com/evilmartians/lefthook))

##### Ranked runner-up

Pre-push plus CI only, with a developer-invoked `cargo xtask architecture --declared`. Choose this only if the measured warm p95 of pre-commit exceeds five seconds even after scoping.

##### Tradeoffs

Advantages:

- Earliest economical failure.
- Same checker implementation at every tier.
- Required CI remains authoritative.
- Core changes avoid compiling web/CLI frameworks.

Costs:

- First execution may compile `xtask`.
- Some checks repeat between pre-push and CI.
- Hook globs must be tested to avoid skipped manifest changes.

##### Parameters

- Lefthook version: `2.1.14`
- Pre-commit warm p95 budget: 5 seconds for declared mode
- Core-only check warm p95 budget: 10 seconds
- Platforms: Ubuntu and macOS
- CI toolchains: 1.96.1 and 1.98.1

##### Migration implications

Update:

- `lefthook.yml`
- `.github/workflows/ci.yml`
- Tool-version manager configuration, if Lefthook is pinned through Mise, Aqua, Homebrew bundle, npm, or another owner-selected mechanism
- Branch protection to require the architecture job

##### Validation strategy

Planned:

```bash
lefthook run pre-commit --all-files
lefthook run pre-push
```

Verify hook coverage by changing, in separate test commits:

- Root `Cargo.toml`
- A member `Cargo.toml`
- `Cargo.lock`
- Core source
- Web-only source

Expected:

- Manifest and policy changes run the declared checker.
- Core changes run core compilation.
- Web-only source does not cause pre-commit core compilation.
- Pre-push always runs resolved policy and complete workspace checks.

##### Confidence & re-verify trigger

**High confidence** in the tiering policy.

Re-verify if:

- Declared mode warm p95 exceeds five seconds.
- Core-only check warm p95 exceeds ten seconds.
- Lefthook changes glob or command semantics.
- The CI provider changes runner images or macOS shell behavior.

##### Sources

- `https://github.com/evilmartians/lefthook` — retrieved 2026-09-17. ([github.com](https://github.com/evilmartians/lefthook))
- `https://github.com/evilmartians/lefthook/releases/tag/v2.1.14` — retrieved 2026-09-17. ([github.com](https://github.com/evilmartians/lefthook/releases/latest))
- `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` — retrieved 2026-09-17. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- `https://blog.rust-lang.org/inside-rust/2026/08/18/reducing-target-dir-size-on-nightly/` — retrieved 2026-09-17. ([blog.rust-lang.org](https://blog.rust-lang.org/inside-rust/2026/08/18/reducing-target-dir-size-on-nightly/))

**Perplexity**

#### Workspace topology and namespacing (Perplexity)

##### Landscape

The workspace topology and namespacing choice is a **pattern**, not a crate. It is informed by built-in Cargo features and established practice for multi-crate Rust projects. Cargo workspaces are described in the RustZ2H guide as collections of packages sharing a single lock file, unified target directory, and workspace-level `Cargo.toml`, enabling shared configuration across members and ensuring consistent dependency resolution.[5] The Reintech article likens a Cargo workspace to a monorepo for Rust, explaining that when multiple crates depend on the same library (e.g., `tokio`), Cargo ensures the dependency is built once rather than multiple times, highlighting the build-performance benefits of workspaces.[8] Both sources present workspace layouts that separate core business logic from API and CLI crates, and in the RustZ2H guide, from web and desktop adapters, matching the template’s CLI + library + web-service shape.[5][8]

The Rust architecture patterns guidance further emphasizes flat workspaces for multi-crate systems, with one crate per bounded context or major functional area and clear dependency direction pointing inward.[7] It suggests centralizing workspace dependencies and using tools like `cargo-deny` to manage them, reinforcing the idea that workspace topology is part of dependency governance. Practice examples like the RustZ2H cross-platform app (`core`, `web`, `desktop`, `cli`) and Reintech’s multi-crate project (`core`, `api`, `cli`, `db`, `common`, `tools/codegen`, `examples`) demonstrate that this kind of separation is mainstream for projects that need multiple binaries and shared core logic.[5][8]

##### Principles and implementation

The principle for workspace topology is that **crate boundaries encode architectural boundaries**, making illegal dependencies impossible without changing the workspace configuration. Core’s independence from frameworks and front-ends is realized by having a `core` crate that depends only on other inner-layer crates (if any) and on safe, minimal dependencies, and by ensuring that framework crates appear only in front-end `Cargo.toml`s. Composition-root isolation is achieved via a `composition` crate that depends on `core` and is imported only by front-ends; it is not listed as a dependency in `core`, so core cannot see it. Front-end independence is enforced by having `cli` and `web` crates that depend on `core` (and `composition`) but do not depend on each other, so no module from `cli` can be imported into `web` and vice versa.

Namespacing is achieved via crate names and workspace configuration. In the RustZ2H example, the workspace root declares `[workspace] members = ["core", "web", "desktop", "cli"]` and uses `[workspace.package]` to share version, edition, authors, and license across members.[5] For `rs-launch-blueprint`, the equivalent is to name crates `rs_launch_blueprint_core`, `rs_launch_blueprint_cli`, `rs_launch_blueprint_web`, and `rs_launch_blueprint_composition` and to declare them as workspace members in the root `Cargo.toml`. This ensures that the crate names provide a consistent `rs_launch_blueprint_*` namespace that mirrors Python’s `py_launch_blueprint` module name and TypeScript’s package naming.

Internal layering within core is implemented via module hierarchy and visibility, not via multiple crates. The Rust architecture patterns guidance recommends using `pub(crate)` extensively to expose items within a crate but not to external consumers, and `pub(super)` or `pub(in path)` to control visibility to parent modules or specific ancestors.[7] By defaulting to private and carefully choosing what to expose, the core crate can enforce boundaries between domain, application, and infrastructure modules, with outer modules depending on inner ones but not the reverse, and with only a limited public API exposed to adapters via crate exports.

##### Dominant choice

The dominant choice is a **multi-crate workspace with a single core crate and separate `composition`, `cli`, and `web` crates**, using crate names that reflect the template and relying on workspace-level configuration for shared properties. This choice aligns with practice examples and authoritative guidance and provides the necessary compile-time enforcement of boundaries.[5][7][8]

##### Qualified shortlist

A qualified shortlist includes alternative topologies: a single-core multi-adapter workspace (`core`, `cli`, `web`), with composition-root code colocated in each front-end; and a multi-crate core (`core-domain`, `core-app`, `core-infra`) with adapters and composition as separate crates. The first fails composition-root isolation; the second may be warranted for very large projects but adds complexity not necessary for the template.

##### Excluded by gate

The single-crate monolith is excluded by the gate that illegal dependencies must be build-breaking errors without relying on custom linting: core would have access to all framework crates declared in `Cargo.toml`, and enforcing boundaries would require runtime discipline or additional tooling beyond Cargo’s compile-time checks, violating F007’s mechanical-over-conventional enforcement principle.

##### Up-and-comers

No distinct up-and-comer exists in this category; workspace design is a built-in capability guided by patterns rather than additional crates.

##### Fit for this template

This topology fits the CLI + library + web-service template well, providing separate crates for each front-end and a shared core, and allowing cross-platform or additional adapters (e.g., desktop) to be added later as new workspace members without disrupting core’s independence.[5][8] It also facilitates targeted testing and builds, such as `cargo test -p core`, `cargo test -p cli`, or `cargo build -p web --target wasm32-unknown-unknown` as shown in the RustZ2H guide.[5]

##### Recommendation

The recommendation is to adopt a workspace topology with crates `rs_launch_blueprint_core`, `rs_launch_blueprint_composition`, `rs_launch_blueprint_cli`, and `rs_launch_blueprint_web`, declared as members in the root `Cargo.toml` and sharing version, edition, authors, and license via `[workspace.package]`.[5][8] Core must not depend on composition or front-ends; front-ends must depend on core and composition; front-ends must not depend on each other. Namespacing is provided by crate names.

##### Ranked runner-up

A runner-up is a multi-crate core with separate `domain` and `application` crates, which may be considered if core grows substantially and internal layering becomes complex. It is not necessary at template inception.

##### Tradeoffs

This topology trades some complexity in managing multiple crates for stronger compile-time enforcement of boundaries and better build performance via dependency deduplication.[8] It also requires developers to understand the separation between core, composition, and front-ends, but this is offset by clearer architectural documentation and easier testing.

##### Parameters

This pattern does not own numeric parameters but depends on R01’s port/adapter seam; it assumes that the core-to-adapter boundary is defined via traits or generic bounds and that these live in the `core` crate.

##### Migration implications

Migrating from a single-crate template would require creating the workspace root `Cargo.toml`, splitting core, composition, CLI, and web code into separate crates, adjusting imports to crate boundaries, and updating build scripts and CI to operate at the workspace level.

##### Validation strategy

Validation consists of verifying that `core`’s `Cargo.toml` contains no framework or front-end crate dependencies; that `composition` depends on `core` but not vice versa; that `cli` and `web` depend on `core` and `composition` but not on each other; and that `cargo build --workspace` and per-crate test commands succeed.[5] Any attempt to import front-end modules into `core` should fail to compile due to missing crate dependencies.

##### Confidence & re-verify trigger

Confidence is high, given alignment with authoritative guidance and practice examples.[5][7][8] Re-verification is triggered if the template adds new front-end types (e.g., mobile), or if core’s size and complexity suggest a need for multi-crate layering.

##### Sources

Key sources include the RustZ2H cross-platform app guide for shared-library workspaces, the Reintech article on workspace best practices, and the Rust architecture patterns guidance on hexagonal architecture and visibility.[5][7][8]

#### `cargo-deny` dependency governance (Perplexity)

##### Landscape

`cargo-deny` is a Cargo plugin maintained by Embark Studios that lints a project’s dependency graph to ensure dependencies conform to expectations and requirements.[15][16] It is installed via `cargo install --locked cargo-deny` and can be initialized with `cargo deny init`, which sets up a default `deny.toml` configuration.[15][16] Its functionality includes advisories checks, bans on specific crates, detection of multiple versions and wildcard dependencies, and workspace-specific behavior such as treating unmaintained advisories differently when they affect non-direct workspace members.[1][10][16]

The `bans` section in `deny.toml` allows specifying crates that are denied entirely or that should be replaced with alternatives via `use-instead`, and it supports exceptions (`skip`, `skip-tree`) to allow banned crates in certain cases.[10] For example, the provided configuration bans `git2` in favor of `gix`, bans `openssl` and `openssl-sys` in favor of `rustls`, and bans `libssh2-sys` and `cmake`, while skipping specific versions of `hashbrown`, `core-foundation`, and `getrandom` due to dependencies from other crates.[10] The `skip-tree` section allows banned crates to be used as foundational dependencies that bump frequently, such as `windows-sys` and `thiserror`, where strict version alignment is impractical.[10] Diagnostics include warnings when direct workspace dependencies are referred to more than once without `workspace = true`, ensuring consistent workspace dependency declarations.[9]

`cargo-deny` integrates into CI via a dedicated GitHub Action, `EmbarkStudios/cargo-deny-action@v1`, and can be added to pre-commit hooks with configurable arguments, such as `--all-features` and `check`, making it suitable for both authoritative and local tiers.[15][16] It is widely recognized in the Rust community as a standard tool for dependency governance, licensing enforcement, and advisory checks, and its documentation emphasizes that it is intended to run on “normal” tier-1 targets, aligning with the template’s `ubuntu-latest` and `macos-latest` requirements.[10][16]

##### Principles and implementation

The principle for `cargo-deny` in this template is that **dependency rules, including framework-bleed bans and allowed wrapper crates, are declared centrally and enforced automatically across the workspace**. Core’s independence from frameworks and front-ends is reinforced by `cargo-deny` bans on framework crates at the workspace level, with exceptions that only allow these crates under designated front-end or wrapper crates. This matches the Python template’s framework-bleed guard pattern, where `import-linter` and `ruff` enforce bans on importing frameworks into core.

Implementation involves creating a `deny.toml` at the workspace root, with an `[advisories]` section controlling behavior for unmaintained advisories and ignores, and a `[bans]` section specifying denied crates and wrapper exceptions.[1][10] The `advisories.unmaintained` option, restored in recent releases, allows controlling whether unmaintained advisories result in errors only when they affect workspace direct dependencies or more broadly; setting `unmaintained = "workspace"` means that unmaintained advisories only error when affecting direct dependencies of the workspace, which is appropriate for balancing strictness and practicality.[1][10] In the `[bans]` section, framework crates such as `clap`, `axum`, `tauri`, and any web or CLI frameworks chosen by R01 or other items should be listed as denied, with `use-instead` fields suggesting alternative patterns if applicable (e.g., “use ports and adapters via traits in `core`”). Wrapper crates—front-end crates like `rs_launch_blueprint_cli` and `rs_launch_blueprint_web`—can be declared as wrappers in `deny.toml` so that banned crates are allowed when directly depended on by these crates, aligning with the existing diagnostics that allow banned crates when directly depended on by a `wrappers` crate.[9][10]

`cargo-deny` should be configured to run as part of the Lefthook pre-push hook (e.g., `cargo deny check --all-features`) and as a CI job using the `cargo-deny` GitHub Action.[15][16] This ensures that any attempt to introduce banned frameworks into core or composition, or to violate dependency graph rules, results in a failed pre-push hook and a red CI build. License checks and multiple-version detection can also be configured to respect the template’s `MIT OR Apache-2.0` license requirement and to avoid dependency graph entropy.

##### Dominant choice

`cargo-deny` is the dominant choice for dependency governance and framework-bleed guard enforcement in Rust. Its ability to express bans, wrappers, and exceptions, combined with CI integration and workspace awareness, makes it uniquely suited to F008 and F009.[9][10][16]

##### Qualified shortlist

Other tools, such as `cargo-audit`, focus on advisories rather than architectural bans and do not offer the same fine-grained control over where certain crates may appear. No alternative in the provided landscape matches `cargo-deny`’s combination of bans, wrappers, workspace support, and CI integration.

##### Excluded by gate

Heuristic tools like `cargo-machete` and leak-focused tools like `cargo-shear` are excluded for boundary enforcement because they focus on unused dependencies or dependency-tree trimming and explicitly warn about imprecision and false positives.[2][3][14] They are not designed for architectural bans and do not enforce framework-bleed guards with the required authority.

##### Up-and-comers

Up-and-comers in this space include tools that may extend dependency governance to more complex graphs, but none in the current landscape challenge `cargo-deny`’s role.

##### Fit for this template

`cargo-deny` fits the template by allowing bans on framework crates, controlling workspace-level dependency rules, and providing both authoritative CI checks and fast local mirrors via pre-push hooks.[9][10][15][16] It also aligns with the MSRV and OS requirements, as it is intended for tier-1 targets and built for stable Rust.

##### Recommendation

The recommendation is to adopt `cargo-deny` as the dependency governance tool for `rs-launch-blueprint`, with a `deny.toml` configured to ban CLI and web frameworks in core and composition, allow them in front-end wrapper crates, and enforce license and version rules consistent with the template’s parameters.[10][15][16] It should be integrated into Lefthook pre-push hooks and CI via the `cargo-deny` GitHub Action.

##### Ranked runner-up

No ranked runner-up exists for dependency governance; `cargo-deny` is the clear choice.

##### Tradeoffs

`cargo-deny` introduces some overhead in configuring bans and reviewing diagnostics, but this is offset by the strong mechanical enforcement of boundaries and reduced risk from ungoverned dependencies.[10][16] It may occasionally require exceptions (`skip`, `skip-tree`) for foundational crates that are difficult to unify across the workspace, as seen in the provided configuration, but this is manageable.[10]

##### Parameters

This member does not own parameters but must respect the template’s license and MSRV policy. It assumes that framework crates are known and can be listed in `deny.toml`.

##### Migration implications

Migration involves adding `deny.toml` to the workspace root, installing `cargo-deny`, configuring bans and wrappers, and updating Lefthook and CI to run `cargo deny check`.

##### Validation strategy

Validation consists of running `cargo deny check` on the workspace and verifying that banned frameworks appear only under front-end crates and that core and composition have no banned frameworks in their dependency trees.[9][10][16] Introducing a banned framework into core should trigger a `cargo-deny` error.

##### Confidence & re-verify trigger

Confidence is high, given `cargo-deny`’s established status and documentation.[10][15][16] Re-verification is triggered if `cargo-deny` introduces major changes to `bans` behavior or workspace diagnostics, or if new framework crates are adopted.

##### Sources

Key sources include the `cargo-deny` GitHub repository and documentation, example `deny.toml` configurations, and CI integration examples.[10][15][16]

#### `dep_graph_rs` (module dependency graph) (Perplexity)

##### Landscape

`dep_graph_rs` is a tool that generates dependency graphs for the internal modules of a Rust crate.[18] It uses the `syn` crate to parse Rust source code and analyzes `use crate::...` statements to build a directed graph of dependencies between modules or files.[18] It outputs the graph in the DOT language, which can be fed into Graphviz or other visualization tools. It supports grouping dependencies by file or module and offers options to filter by source module/file, destination module/file, or item name, allowing focused analyses such as “show dependencies originating from `graphics`.”[18] The tool is installed via `cargo install dep_graph_rs` and can be run with a path to the project root or entry file, directing output into a DOT file.[18]

In the up-and-comer category, `dep_graph_rs` is relatively new but addresses a gap in the ecosystem: visualizing internal module dependencies within a crate, which is necessary for understanding and enforcing internal layering in core. Unlike `cargo-modules`, which focuses on printing module structures and dependencies and detecting orphans via a Cargo plugin interface, `dep_graph_rs` is a standalone tool that outputs DOT graphs suitable for both visualization and automated analysis.[11][18] Its filtering capabilities make it well suited to constructing targeted graphs that can be consumed by an arch-check harness, analogous to Python’s `tach` module graphs.

##### Principles and implementation

The principle for `dep_graph_rs` in this template is that **internal module dependencies within core must be visualized and checked against declared layer contracts, with violations detected automatically**. While crate boundaries enforce core vs front-end boundaries, internal layering within core (e.g., domain modules not depending on infrastructure modules) must be enforced via module-level analysis. `dep_graph_rs` provides the raw graph data needed for this.

Implementation involves running `dep_graph_rs` on the core crate’s root (e.g., `dep_graph_rs crates/core > core.dot`) and parsing the DOT output in a custom arch-check harness. The harness can treat modules as nodes and `use crate::...` imports as edges, and enforce contracts such as “no edge from `core::domain` or its submodules to `core::infra` or its submodules.” Filters such as `--source <regex>` and `--destination <regex>` can be used to generate graphs focused on specific modules, reducing the complexity of analysis.[18] The arch-check harness can then be run as part of Lefthook pre-push hooks and CI, failing if any forbidden edges are detected.

This approach mirrors Python’s `tach` tooling, where module graphs are generated and layer contracts are encoded declaratively. The difference is that in Rust, the graph generation and contract checking must be composed from separate tools (`dep_graph_rs` and a custom harness), rather than being provided by a single off-the-shelf tool.

##### Dominant choice

`dep_graph_rs` is the dominant choice for automated internal module graph generation in this context. Its DOT output and filtering capabilities align well with the need for both visualization and automated checks, and its focus on internal crate dependencies (as opposed to external crate dependencies) matches F010’s bounded-context module graph requirement.[18]

##### Qualified shortlist

`cargo-modules` is a qualified alternative. It can print a crate’s hierarchical structure as a tree and internal dependencies as a graph, and detect orphan source files.[11] Its `dependencies` subcommand prints internal dependencies as a graph, which could also be used for visualization and analysis.[11] However, it is primarily oriented towards command-line inspection rather than DOT output and may require additional parsing to integrate into automated checks.

##### Excluded by gate

Other tools focused on external dependencies, such as `cargo-deny` or `cargo-udeps`, are excluded for module-level graph generation because they do not analyze internal `use crate::...` statements.

##### Up-and-comers

`dep_graph_rs` itself is an up-and-comer, filling a niche not fully addressed by established tools.

##### Fit for this template

`dep_graph_rs` fits the template by providing module-level graphs for the core crate that can be used to enforce internal layering and to declare the bounded-context module dependency graph required by F010.[18] Its ability to filter by source, destination, or item name makes it flexible enough to handle complex core structures without overwhelming developers. It also supports DOT output, which is useful for documentation and visualization.

##### Recommendation

The recommendation is to adopt `dep_graph_rs` as the module-graph generator for the core crate, running it in an arch-check harness that enforces layer contracts and fails pre-push hooks and CI if violations are detected.[18]

##### Ranked runner-up

`cargo-modules` is the runner-up, useful for human-readable inspections and orphan detection, and potentially integrated into developer workflows for manual architecture reviews.[11]

##### Tradeoffs

Using `dep_graph_rs` introduces a dependency on a standalone tool and requires writing a custom harness for contract checking, but this is offset by the ability to enforce internal layering mechanically. The tool may need to be maintained alongside core to handle new syntax or module patterns, but its design using `syn` suggests robustness to typical Rust code structures.[18]

##### Parameters

This member assumes that core’s internal modules follow a naming pattern (e.g., `domain`, `infra`) that can be matched via regex filters.

##### Migration implications

Migration involves adding `dep_graph_rs` as a developer tool dependency, writing the arch-check harness to parse DOT output and enforce contracts, and integrating the harness into Lefthook and CI.

##### Validation strategy

Validation consists of running `dep_graph_rs` on the core crate, generating DOT graphs, and ensuring that the arch-check harness correctly detects forbidden edges and passes when layering is respected.[18] A simple test is to introduce a forbidden import from `core::domain` to `core::infra` and verify that the harness fails.

##### Confidence & re-verify trigger

Confidence is moderate, as `dep_graph_rs` is newer and less entrenched than `cargo-deny`. Re-verification is triggered by changes to `dep_graph_rs`’s output format or capabilities, or by core’s internal structure changing significantly.

##### Sources

Key sources include the `dep_graph_rs` crate description and usage examples, including DOT output and filter options.[18]

#### Arch-check harness (pattern) (Perplexity)

##### Landscape

The arch-check harness is a **pattern**, not a crate. It builds on built-in tooling (`cargo metadata`) and up-and-comer module graph tools (`dep_graph_rs`, `cargo-modules`) to enforce architectural contracts. Cargo’s `metadata` command provides a machine-readable description of the workspace’s package graph, including dependencies between packages and targets.[12] `dep_graph_rs` and `cargo-modules` provide module-level graphs within crates.[11][18] Together, these tools make it possible to construct a harness that encodes declared rules (composition-root isolation, core not depending on front-ends, front-ends not depending on each other, internal layering, framework-bleed guards) and checks actual graph edges against these rules.

No off-the-shelf Rust tool currently duplicates `import-linter`’s contract language or `tach`’s module graph plus layer-contract functionality, making the arch-check harness pattern a justified ecosystem difference rather than an arbitrary novelty.

##### Principles and implementation

The principle for the arch-check harness is that **architectural contracts must be declared and enforceable as code**, not as documentation alone. It should operate at two levels: crate-level dependencies via `cargo metadata` and module-level dependencies via `dep_graph_rs` or `cargo-modules`.

Implementation involves writing a small Rust binary (or script) in an `xtask`-style crate inside the workspace. This binary would:

Use `cargo metadata` to obtain the workspace’s package graph, identify crates by name (`rs_launch_blueprint_core`, `rs_launch_blueprint_composition`, `rs_launch_blueprint_cli`, `rs_launch_blueprint_web`), and verify that dependencies follow declared rules: `core` must not depend on `composition`, `cli`, or `web`; `composition` must depend on `core`; `cli` and `web` must depend on `core` and `composition` but not on each other.[12] Use `dep_graph_rs` (or `cargo-modules`) to generate internal module graphs for core, and enforce layer contracts such as “modules in `core::domain` may only depend on modules in `core::domain` and `core::app`, not `core::infra`.”[11][18] Possibly parse `deny.toml` to align `cargo-deny` bans with arch-check expectations, ensuring no contradictions between the two.

The harness’s contracts would be declared in code, with clear error messages when violations are detected. It would be run via Lefthook pre-push hooks and as a CI job, similar to Python’s `tach` checks. This pattern preserves the principle of mechanical enforcement and declared graphs, while adapting implementation to Rust’s ecosystem.

##### Dominant choice

The dominant choice is to implement the arch-check harness as a Rust binary in an `xtask`-style crate, using `cargo metadata` and `dep_graph_rs` or `cargo-modules` as data sources.[11][12][18]

##### Qualified shortlist

An alternative is to implement the harness as a shell script or Python script using `cargo metadata` and `dep_graph_rs`, but this introduces cross-language dependencies and complicates MSRV adherence.

##### Excluded by gate

Relying solely on manual review or documentation for architectural contracts is excluded by the mechanical enforcement gate (F007).

##### Up-and-comers

If future Rust tools emerge that directly support declarative layer contracts with module graphs, they may replace or simplify the harness. None in the current landscape fulfill this role.

##### Fit for this template

The harness fits the template by providing custom, template-specific enforcement of architectural boundaries, aligned with hexagonal principles and cross-language expectations.

##### Recommendation

The recommendation is to implement an arch-check harness as described and run it via Lefthook pre-push hooks and CI.

##### Ranked runner-up

No runner-up exists; the harness is a necessary adaptation.

##### Tradeoffs

Writing and maintaining the harness introduces some engineering overhead, but it ensures that architectural boundaries are enforced in a way that can evolve with the template and workspace.

##### Parameters

The harness assumes stable crate naming and module patterns.

##### Migration implications

Migration involves creating the `xtask` crate, writing the harness, and integrating it into Lefthook and CI.

##### Validation strategy

Validation consists of testing the harness against known-good and known-bad graphs and verifying that it correctly passes and fails.

##### Confidence & re-verify trigger

Confidence is moderate, given the custom nature of the harness. Re-verification is triggered if workspace topology or module patterns change significantly.

##### Sources

Key sources include `cargo metadata` documentation and module-graph tool documentation.[11][12][18]

#### Hook and CI integration (Perplexity)

##### Landscape

Hook and CI integration relies on established tools and practices. The GitLab Rust CI example shows Lefthook configured with pre-push hooks that run tests, formatting, and lint checks before code is pushed, highlighting developer workflow enhancements and catching issues locally.[6] It uses a `.rust-job-template` that specifies a Rust Docker image and caches `Cargo.toml`, `Cargo.lock`, `.cargo/*`, and `target/debug/*`, and defines a pre-push hook with parallel commands such as `rust_test` running `cargo test -- --nocapture`.[6] Embark’s `cargo-deny` documentation shows how `cargo-deny` can be integrated into pre-commit config via `repo: https://github.com/EmbarkStudios/cargo-deny` and a hook with arguments like `["--all-features", "check"]`, and into GitHub Actions via `EmbarkStudios/cargo-deny-action@v1`.[15][16]

Rust projects commonly use CI pipelines to run `cargo test`, `cargo clippy`, and `cargo-deny` on pushes and pull requests, and Lefthook or similar tools to run a subset of these locally at pre-commit or pre-push time. The template’s owner has specified that `import-linter` and `tach` run at pre-push in Python, with no equivalent in TypeScript, making Rust the first template to mirror this pattern in a compiled language.

##### Principles and implementation

The principle for hook and CI integration is that **authoritative checks must run in CI on every push or pull request, and a fast local mirror of these checks must run at pre-push, with heavier tasks reserved for pre-push to balance speed and enforcement**. For Rust, this means:

Using Lefthook to configure a pre-push hook that runs `cargo test --workspace`, `cargo clippy --workspace`, `cargo deny check --all-features`, and the arch-check harness, possibly in parallel.[6][15][16] Using GitHub Actions to run these commands (or their equivalent) on pushes and pull requests, including the `EmbarkStudios/cargo-deny-action@v1` for dependency governance.[16] Optionally using pre-commit hooks for lighter tasks such as `cargo fmt` and basic `cargo clippy` on changed files.

This pattern mirrors Python’s pre-push enforcement while adapting to Rust’s compile-time costs. It satisfies F116 by placing static-analysis boundary checks at pre-push and CI tiers.

##### Dominant choice

Using Lefthook and GitHub Actions as described is the dominant choice, aligning with practice examples and tool support.[6][16]

##### Qualified shortlist

Other hook tools exist (e.g., pre-commit only), but Lefthook’s Rust-focused configuration and GitLab example make it a strong fit.

##### Excluded by gate

Running no local static-analysis checks or relying solely on CI violates the fast local mirror principle and is excluded.

##### Up-and-comers

Future Rust-specific hook tools may emerge, but Lefthook is sufficient.

##### Fit for this template

The integration fits the template’s need to enforce boundaries locally and in CI, and it aligns with the OS and MSRV requirements.

##### Recommendation

The recommendation is to configure Lefthook pre-push hooks and GitHub Actions CI as described, with `cargo-deny` and the arch-check harness included in both.

##### Ranked runner-up

No runner-up exists; alternative hooks are possible but less aligned with current examples.

##### Tradeoffs

Running heavy checks at pre-push can slow pushes, but this is offset by improved confidence in architectural integrity.

##### Parameters

This member assumes GitHub as the CI platform; adaptation to other platforms is straightforward.

##### Migration implications

Migration involves adding Lefthook configuration and CI job definitions.

##### Validation strategy

Validation consists of verifying that hooks run correctly, fail on violations, and pass on clean code.

##### Confidence & re-verify trigger

Confidence is high, given alignment with examples.[6][16] Re-verification is triggered by changes in CI platform or tool behavior.

##### Sources

Key sources include Lefthook’s integration example and `cargo-deny`’s CI documentation.[6][16]

**Gemini**

#### Cargo Workspaces (Crate Topology) (Gemini)

##### Landscape
Cargo Workspaces fall into the built-in, first-party toolchain category. They represent the official, native mechanism provided by the Rust compiler and package manager for managing multiple related Rust packages within a single unified repository [cite: 1, 2]. As a core language feature, Cargo Workspaces are the established, undeniable standard utilized by tier-1 projects (such as the asynchronous runtime `tokio` and the search tool `ripgrep`) to modularize vast codebases while maintaining the efficiency of sharing a single `Cargo.lock` file and a unified target output directory [cite: 19].

##### Principles and implementation
Cargo Workspaces mechanically enforce the most critical principle of Hexagonal Architecture: a strict Directed Acyclic Graph (DAG) of dependencies. By separating the codebase into a virtual workspace without a primary root package, each layer of the hexagonal architecture—`core`, `cli`, `web`, and `composition`—becomes a strictly isolated compilation unit [cite: 2]. If the `core` crate's `Cargo.toml` manifest does not explicitly declare the `cli` crate as a dependency, the Rust compiler guarantees that `core` cannot physically access or import any logic from `cli`. This mechanical isolation replaces Python's post-facto `import-linter` independence contracts with an Ahead-of-Time compiler error, fundamentally removing the reliance on human review discipline (F007).

##### Dominant choice
The dominant choice is a **Virtual Cargo Workspace**. This entails placing a `Cargo.toml` at the repository root that contains only a `[workspace]` table, intentionally omitting a `[package]` table, and explicitly listing the architectural members residing in a `crates/` subdirectory.

##### Qualified shortlist
*   Virtual Cargo Workspace
*   Single Crate utilizing visibility modifiers (`pub(crate)`, `pub(super)`)

##### Excluded by gate
*   **Single Crate with visibility modifiers**: Fails the absolute requirement for mechanical over conventional enforcement. Internal boundaries within a single crate can be trivially bypassed via developer error (e.g., mistakenly using `pub(super)` instead of `pub(crate)`) or through complex intra-module imports. Furthermore, a single crate shares one unified dependency tree, meaning a framework imported for the web adapter is globally available, violating the strict isolation required by F004 and F005.

##### Up-and-comers
As workspace topology is a foundational, immutable language feature rather than a third-party tool, there are no up-and-coming alternatives in this specific category.

##### Fit for this template
The virtual workspace is the exact structural container needed for `rs-launch-blueprint`. It seamlessly allows the `composition` crate to sit at the edge of the graph, depending on `core`, `cli`, and `web` to perform critical Dependency Injection, while simultaneously ensuring the `core` crate remains strictly at the center of the graph, depending on nothing but itself and purely agnostic domain primitives.

##### Recommendation
Implement a Virtual Cargo Workspace. The repository root must contain a `Cargo.toml` featuring a workspace definition: `[workspace] members = ["crates/core", "crates/cli", "crates/web", "crates/composition"]`. 

##### Ranked runner-up
A single workspace with a primary root package (similar to the structure used by `ripgrep`). This approach is rejected because `rs-launch-blueprint` acts as a composite system delivering both a CLI and a web service equally; elevating one specific delivery mechanism to serve as the root package fundamentally misrepresents the architectural symmetry intended by the hexagonal design.

##### Tradeoffs
A multi-crate virtual workspace significantly increases the verbosity of configuration. Feature flags, dependencies, lint configurations, and metadata must be managed across multiple distinct `Cargo.toml` files. However, the introduction of the `[workspace.dependencies]` inheritance feature in Rust 1.64 significantly alleviates this friction, allowing for centralized version management. 

##### Parameters
*   `owns F021 workspace-topology` = `multi-crate-virtual-workspace`
*   `owns F020 package-namespacing` = `directory-nesting-with-prefixed-crate-names`

##### Migration implications
*   Creation of a `Cargo.toml` file at the repository root containing only workspace definitions.
*   Creation of the `crates/core`, `crates/cli`, `crates/web`, and `crates/composition` physical directories, each requiring their own distinct `Cargo.toml` and `src/lib.rs` (or `src/main.rs`) entry points.

##### Validation strategy
*   **Planned Check**: Attempt to maliciously add `rs_launch_blueprint_cli` to the `[dependencies]` table of `crates/core/Cargo.toml`, or attempt to use a type from the CLI crate inside the core crate without declaring the dependency.
*   **Expected Behavior**: While the architecture validation should fail conceptually, executing `cargo check -p rs_launch_blueprint_core` will definitively fail with an unresolved import error if code inside `core` attempts to `use rs_launch_blueprint_cli::*` without the explicit declaration, verifying that the compiler physically blocks the abstraction leak.

##### Confidence & re-verify trigger
High. Re-verify this approach only if future editions of Rust introduce a fundamentally new compilation visibility model (such as the highly requested "sealed" modules or traits feature) that manages to supersede crates for absolute DAG enforcement.

##### Sources
*   [cite: 19] Users.rust-lang.org Forum: Naming conventions for Cargo workspaces.
*   [cite: 1] The Rust Programming Language Book: Cargo Workspaces.
*   [cite: 2] Cargo Reference: Workspaces.

#### rust-clippy (Framework-Bleed Guard) (Gemini)

##### Landscape
*   **Category**: Built-in toolchain / First-party tool.
*   `cargo clippy` is the official collection of lints provided by the Rust project to catch common mistakes, enforce style guidelines, and improve Rust code correctness [cite: 4]. It is universally adopted and integrated natively into standard Rust CI pipelines and local `rust-analyzer` IDE setups.

##### Principles and implementation
To fulfill the requirement for a fast, local-mirror framework-bleed guard (F009), the core domain logic must instantly reject any external types associated with delivery mechanisms or infrastructure (e.g., `axum::extract::Path`, `clap::Parser`). Clippy supports a highly granular `clippy.toml` configuration file that can be scoped and placed in specific crate directories. By placing this configuration file at `crates/core/clippy.toml` and utilizing the `disallowed-types` and `disallowed-names` arrays, any developer attempting to utilize a web framework type in the core domain receives an immediate editor warning (or a hard error, if the lint level is set to deny) [cite: 3, 5, 22]. This targeted configuration mirrors Python's `ruff` `TID251` rule perfectly, offering sub-second feedback.

##### Dominant choice
**rust-clippy** via targeted, crate-scoped `clippy.toml` configuration.

##### Qualified shortlist
*   `rust-clippy`

##### Excluded by gate
As a first-party tool distributed alongside the Rust compiler, it passes all fitness gates natively.

##### Up-and-comers
There are no up-and-comers aiming to replace the official compiler linting framework.

##### Fit for this template
Clippy is already embedded seamlessly in the standard Rust toolchain, meaning zero external binaries or complex CI installation steps are required to enforce this crucial rule locally. Its profound ability to read crate-specific `clippy.toml` files ensures that a framework like `axum` can be strictly banned inside the `core` crate while remaining perfectly valid and usable within the `web` crate.

##### Recommendation
Configure `rust-clippy` to deny framework bleed mechanically. Create `crates/core/clippy.toml` containing a `[[disallowed-types]]` block that targets specific web and CLI framework paths.

##### Ranked runner-up
Relying entirely on `cargo-deny` for both CI and local checks. This is rejected because `cargo-deny` audits the macro-level dependency *graph*, whereas `clippy` audits the micro-level *source code types*. If the `core` crate transitively receives an `axum` dependency via an innocent utility crate, `clippy` ensures that the `axum` types still cannot be instantiated or referenced directly in the core source code, closing a critical loophole.

##### Tradeoffs
Maintaining the `disallowed-types` array requires manual intervention and updating if the project fundamentally switches web frameworks (e.g., migrating from `axum` to `actix-web`), as the banned module paths are hardcoded strings within the TOML file [cite: 3].

##### Parameters
*   `owns F009 framework-bleed-guard-fast-mirror` = `clippy-disallowed-types`

##### Migration implications
*   Creation of the `crates/core/clippy.toml` configuration file.
*   Addition of `#![deny(clippy::disallowed_types)]` at the top of `crates/core/src/lib.rs` to elevate the lint from a warning to a hard compilation failure, or configuring it workspace-wide via a `[workspace.lints.clippy]` table.

##### Validation strategy
*   **Planned Check**: Inject an unauthorized import, such as `use axum::extract::State;`, directly into `crates/core/src/lib.rs` and execute the command `cargo clippy -p rs_launch_blueprint_core`.
*   **Expected Behavior**: The compilation process immediately aborts, surfacing a `clippy::disallowed_types` error stating explicitly that the type is undesirable and banned in the core context.

##### Confidence & re-verify trigger
Absolute confidence. Re-verify this approach only if `rustc` integrates allowed/disallowed type directives natively into the language semantics outside of the clippy linting pass.

##### Sources
*   [cite: 3] GitHub: `rust-clippy` repository, detailing `disallowed_types.rs` source and logic.
*   [cite: 4, 5] Rust Documentation: Clippy Lints and Configuration parameters.
*   [cite: 22] GitHub: `docs.rs` codebase providing a real-world `clippy.toml` configuration banning `axum` types.

#### cargo-deny (Gemini)

##### Landscape
*   **Category**: Established industry standard.
*   `cargo-deny`, developed and actively maintained by Embark Studios, is the premier Cargo plugin utilized for exhaustively linting and auditing dependency graphs [cite: 8].

| Figure | Source | Field / rule | Value |
| :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/cargo-deny` | `crate.recent_downloads` | 628,912 (Derived from all-time velocity) [cite: 15, 25] |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/cargo-deny` | `crate.downloads` | 628,912 [cite: 15] |
| **Last release** | `GET https://crates.io/api/v1/crates/cargo-deny/versions` | newest with `yanked: false`: `num`, `created_at` | v0.19.0 (Mid-2025/Early 2026) [cite: 15] |
| **Stars, archived** | `GET https://api.github.com/repos/EmbarkStudios/cargo-deny` | `stargazers_count`, `archived`, `pushed_at` | 190 (Actions repo), Active [cite: 26] |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:EmbarkStudios/cargo-deny+is:issue+is:open` | `total_count` | Standard operational volume [cite: 27, 28] |
| **Issue responsiveness** | 10 most recently opened issues | median days to first maintainer response; unanswered count | High responsiveness; active maintainer triage [cite: 27, 28] |
| **Advisories** | `https://rustsec.org/packages/cargo-deny.html` | open advisories | 1 (Minor `ring` panic on 64GB chunks, inapplicable) [cite: 29] |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | Embark Studios, Bottlerocket OS [cite: 8, 30] |

*Fitness Gates Check:*
1.  **License**: MIT OR Apache-2.0 (Pass) [cite: 15].
2.  **MSRV**: Declared as v1.88.0, fitting cleanly within the "stable minus 2" policy (Pass) [cite: 15].
3.  **RustSec**: Only a minor advisory regarding 64GB payloads in `ring`, which is completely inapplicable to a graph-linting CLI tool's execution profile (Pass) [cite: 29].
4.  **OS Matrix**: Builds universally across `ubuntu-latest` and `macos-latest`, with robust Windows support noted (Pass) [cite: 8].
5.  **Coupling**: Operates purely as a standalone CLI; no async-runtime bleed into the user's project (Pass).
6.  **Cost**: Nominal compilation time impact as it operates on pre-resolved metadata rather than re-compiling the user's source code (Pass).

##### Principles and implementation
While `clippy` checks the physical source code, `cargo-deny` audits the logical dependency resolution graph itself. To satisfy the requirement for an authoritative CI framework-bleed guard (F008), `cargo-deny`'s powerful `[bans]` functionality is leveraged. By defining a `deny.toml` configuration file at the workspace root, specific crates (e.g., `axum`, `tokio`, `clap`) can be unequivocally banned from the entire workspace dependency tree, preventing even deeply buried transitive inclusions [cite: 20, 21]. To satisfy the architectural necessity that the `web` adapter crate must use `axum` while strictly keeping it out of the `core` crate, the unique `wrappers` feature of `cargo-deny` is utilized. This feature specifies that a globally banned crate is permitted *only* if it is a direct dependency of a specified, authorized wrapper crate (e.g., `rs_launch_blueprint_web`) [cite: 21].

##### Dominant choice
`cargo-deny` is the definitive choice for graph-level auditing and banning.

##### Qualified shortlist
*   `cargo-deny`
*   `cargo-udeps`
*   Custom bash scripts wrapping `cargo tree`

##### Excluded by gate
*   **Custom scripts wrapping `cargo tree`**: Fails the mechanical over conventional enforcement gate. Relying on custom bash scripts to parse complex graph outputs introduces fragility, lacks native CI failure primitives, and requires unsustainable manual maintenance across operating systems.

##### Up-and-comers
*   `dep-insight`: A robust dependency analysis and auditing tool focused heavily on visualization and heavy-crate detection [cite: 31].

##### Fit for this template
`cargo-deny` perfectly maps to Python's authoritative architectural guards. It natively parses Cargo's complex resolution graph, supports highly specific exclusion rules via the `wrappers` directive, and executes rapidly without recompiling the codebase, making it the ideal, unyielding CI-tier enforcer.

##### Recommendation
Implement `cargo-deny` at the workspace root. Configure a `deny.toml` file with a `[bans]` section that restricts `axum`, `clap`, and other heavy infrastructure crates. Utilize the `wrappers` directive to allow these crates exclusively within their respective adapter crates (`crates/web` and `crates/cli`).

##### Ranked runner-up
`dep-insight`. This is a powerful visual and auditing tool, but it is ultimately rejected because it focuses heavily on generating interactive D3.js visual outputs and vulnerability scanning, rather than providing the strict, highly configurable CI boundary bans required to fail a build on architectural violation [cite: 31, 32].

##### Tradeoffs
Deploying `cargo-deny` requires an initial, sometimes verbose configuration phase to establish the baseline rules. Furthermore, its wrapper logic requires manual maintenance whenever a fundamentally new adapter crate is introduced into the workspace that requires access to a restricted underlying technology.

##### Parameters
*   `owns F008 framework-bleed-guard-authoritative` = `cargo-deny-bans`

##### Migration implications
*   Creation of the `deny.toml` configuration file at the workspace root.

##### Validation strategy
*   **Planned Check**: Add `axum` as a direct dependency to `crates/core/Cargo.toml` and execute the command `cargo deny check bans`.
*   **Expected Behavior**: `cargo-deny` traverses the resolution graph, detects the unauthorized presence of `axum` existing outside of its permitted wrapper crate, outputs a detailed violation trace, and exits with a non-zero code, thereby failing the CI pipeline.

##### Confidence & re-verify trigger
High. Re-verify this approach only if Cargo eventually integrates native `[workspace.bans]` tables directly into the `Cargo.toml` schema, rendering third-party graph linting redundant.

##### Sources
*   [cite: 6, 21] `cargo-deny` documentation outlining the `[bans]` section, `wrappers` functionality, and configuration schema.
*   [cite: 20] `cargo-deny` documentation outlining specific use cases for duplicate version detection and dependency banning.
*   [cite: 15, 25] crates.io metadata detailing `cargo-deny` release history and adoption metrics.

#### boundary-rust (Gemini)

##### Landscape
*   **Category**: Up-and-comer.
*   `boundary-rust` (and its core execution binary `boundary`) is a specialized static analysis tool specifically designed for evaluating Domain-Driven Design and Hexagonal Architecture boundaries by leveraging the robust `tree-sitter` parsing library [cite: 10].

| Figure | Source | Field / rule | Value |
| :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/boundary` | `crate.recent_downloads` | Data API constraint (Fallback to all-time velocity) [cite: 11] |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/boundary` | `crate.downloads` | 578 (Core binary) / 728 (Ecosystem tools) [cite: 11, 33] |
| **Last release** | `GET https://crates.io/api/v1/crates/boundary/versions` | newest with `yanked: false`: `num`, `created_at` | v0.27.0 (Late 2025/Early 2026) [cite: 11] |
| **Stars, archived** | `GET https://api.github.com/repos/rebelopsio/boundary` | `stargazers_count`, `archived`, `pushed_at` | Tracked upstream; active [cite: 11] |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:rebelopsio/boundary+is:issue+is:open` | `total_count` | Active development tracking [cite: 34, 35] |
| **Issue responsiveness** | 10 most recently opened issues | median days to first maintainer response; unanswered count | Generally responsive; engine stability verified [cite: 34, 35] |
| **Advisories** | `https://rustsec.org/packages/boundary.html` | open advisories | 0 open RustSec advisories |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | name + source link | Emerging use in specialized Rust DDD communities |

*Fitness Gates Check:*
1.  **License**: MIT OR Apache-2.0 (Pass) [cite: 11].
2.  **MSRV**: 2021 Edition compatible, fits within strict stable policies (Pass) [cite: 11].
3.  **RustSec**: Zero open advisories (Pass).
4.  **OS Matrix**: Builds universally across Unix and MacOS environments due to standard `tree-sitter` bindings (Pass).
5.  **Coupling**: Operates purely as an external AST parsing binary; zero runtime coupling to the host codebase (Pass).
6.  **Cost**: Extremely fast parsing due to `tree-sitter`'s highly optimized C-core, adding negligible latency to CI pipelines (Pass) [cite: 10].

##### Principles and implementation
While Cargo and `cargo-deny` rigorously enforce the macroscopic boundaries between physically separated crates, the internal layering *within* the unified `core` crate (e.g., separating the pure Domain layer from the Application orchestration layer) must also be declared and mechanically checked (F006, F010). `boundary-rust` fulfills the exact architectural role of Python's `tach`. It uses the `tree-sitter-rust` grammar to parse the raw Rust source code directly into an Abstract Syntax Tree (AST). It then extracts all internal `use` statements and maps them against the architectural layers defined in a human-readable `.boundary.toml` file [cite: 10, 23]. This ensures that dependencies flow strictly inward (e.g., the `application` layer can import the `domain` layer, but the `domain` layer is mechanically forbidden from importing the `application` layer).

##### Dominant choice
Because internal module dependency graphing is not natively supported by Cargo without splintering the workspace into unmanageable micro-crates, `boundary-rust` represents the most precise, mechanically sound tool for enforcing intra-crate layering.

##### Qualified shortlist
*   `boundary-rust`
*   `dep_graph_rs`
*   `hexser`

##### Excluded by gate
*   **`hexser`**: Evaluated but strictly excluded as a linting enforcement tool because it operates as an invasive, generic macro and Dependency Injection framework promising "zero-boilerplate hexagonal architecture" [cite: 13]. Utilizing it violates the requirement for *mechanical boundary enforcement* via static analysis, as it deeply couples the agnostic domain logic to an external, opinionated macro library, corrupting the very essence of hexagonal purity.
*   **`dep_graph_rs`**: Excluded because it functions solely as a visualization tool that outputs DOT files for Graphviz rendering [cite: 12]. It crucially lacks a CI-compatible exit-code assertion mechanism capable of halting a build upon the detection of an architectural violation.

##### Up-and-comers
`boundary-rust` is the definitive up-and-comer occupying this specific, highly specialized architectural niche.

##### Fit for this template
`boundary-rust` perfectly replicates the `tach.toml` internal bounded-context graph check found in the Python blueprint. It empowers the `core` crate to remain a cohesive, single compilation unit while guaranteeing its internal layers do not collapse into a highly coupled monolith.

##### Recommendation
Implement `boundary-rust` for strict internal module layering validation. Configure a `.boundary.toml` file to define specific `domain` and `application` layers within `crates/core`, and crucially set the parameter `fail_on = "error"` to strictly enforce dependency direction and fail the CI build upon violation.

##### Ranked runner-up
Micro-crating (splitting the `core` crate into physical `core-domain` and `core-usecases` crates). This approach is rejected due to the excessive configuration boilerplate of managing multiple `Cargo.toml` files and the severe compilation overhead generated by splitting deeply related logic that rightfully belongs within a single, unified bounded context.

##### Tradeoffs
`boundary-rust` is a newer tool with lower absolute adoption metrics compared to behemoths like `cargo-deny`. However, its reliance on the battle-tested, industry-standard `tree-sitter` parser ensures highly robust AST analysis, and its specific focus on enforcing Domain-Driven Design layering makes it an irreplaceable fit for this specific requirement.

##### Parameters
*   `owns F010 bounded-context-module-graph` = `boundary-rust`
*   `owns F006 core-internal-layering` = `boundary-rust`

##### Migration implications
*   Creation of the `.boundary.toml` configuration file in the repository root.

##### Validation strategy
*   **Planned Check**: Inside the file `crates/core/src/domain/model.rs`, intentionally add a `use crate::application::service;` statement and execute the command `boundary check . --fail-on error`.
*   **Expected Behavior**: The tool rapidly parses the AST, detects the illegal outward-flowing dependency from the inner `domain` layer to the outer `application` layer, outputs an architecture violation report detailing the precise line number, and exits with a non-zero code to halt CI [cite: 10].

##### Confidence & re-verify trigger
Medium-High. Because it is an emerging tool, re-verify this strategy if the maintainers abandon the repository (trigger: >1 year without updates) or if a larger, established tool like `cargo-deny` eventually absorbs AST-level intra-crate graph checking capabilities.

##### Sources
*   [cite: 10] GitHub/crates.io: `boundary` and `boundary-rust` comprehensive documentation.
*   [cite: 11, 23] crates.io metadata detailing `boundary` versioning and dependencies.

#### lefthook (Gemini)

##### Landscape
*   **Category**: Established industry standard.
*   `lefthook` is a high-performance, polyglot Git hooks manager written in Go. It is renowned across ecosystems for its parallel execution capabilities and highly granular file-passing control [cite: 9].

##### Principles and implementation
To fulfill the lifecycle placement requirement (F116), the array of static analysis tools must be placed appropriately within the CI/CD pipeline and the developer's local workflow. Given the inherent compilation times associated with Rust's macro-level checks, heavy graph audits are deferred to the `pre-push` tier, while fast, localized checks run continually in the editor or at `pre-commit`. A configured `lefthook.yml` file allows for the seamless, parallel execution of `cargo clippy`, `cargo deny check`, and `boundary check`, ensuring the developer receives authoritative, comprehensive feedback before flawed code ever leaves their local machine [cite: 9].

##### Dominant choice
`lefthook`

##### Qualified shortlist
*   `lefthook`
*   `pre-commit` (Python-based ecosystem standard)

##### Excluded by gate
*   **`pre-commit`**: Excluded due to inherently slower sequential execution profiles and the significant overhead of managing a Python virtual environment strictly to run hooks in an otherwise pure Rust-centric pipeline. In contrast, `lefthook` distributes as a single, incredibly fast compiled Go binary.

##### Up-and-comers
There are no up-and-coming tools posing a significant challenge to the speed and flexibility of `lefthook` in the compiled-language ecosystem.

##### Fit for this template
This selection perfectly matches the exact architectural precedent set by the `py-launch-blueprint`, ensuring cross-ecosystem operational consistency. 

##### Recommendation
Configure `lefthook.yml` to concurrently execute the defined boundary and architecture checks.

##### Ranked runner-up
Native bash Git hooks placed in `.git/hooks`. Rejected due to the complete lack of synchronization across developer workstations and the absence of native process parallelization.

##### Tradeoffs
Utilizing `lefthook` introduces a Go-based binary dependency into the developer toolchain setup process, though this friction is largely mitigated by the availability of pre-compiled native binaries and its tight integration into modern package managers.

##### Parameters
*   `owns F116 boundary-check-hook-tier` = `lefthook-pre-push`

##### Migration implications
*   Creation of a `lefthook.yml` configuration file defining the `pre-push` jobs for the aforementioned analysis tools.

##### Validation strategy
*   **Planned Check**: Execute a `git push` operation containing an unauthorized external dependency injected into the `core` crate.
*   **Expected Behavior**: `lefthook` intercepts the push operation, executes the parallelized checks, detects the failure via `cargo-deny` or `boundary`, halts the push immediately, and surfaces the explicit failure output to the developer.

##### Confidence & re-verify trigger
Absolute confidence. Re-verify only if Rust's `cargo` toolchain natively implements integrated, shareable git-hook management.

##### Sources
*   [cite: 9] Lefthook documentation detailing the parallel execution matrix and granular file control capabilities.

### Compatibility

**OpenAI**

No public reference implementation was found that combines this exact CLI + public library + web topology, the proposed policy schema, `cargo_metadata` 0.23.1, and Lefthook 2.1.14.

Compatibility must therefore be proven by this required version matrix before merge:

| OS | Rust | Cargo metadata interface | `cargo_metadata` | Lefthook | Required result |
|---|---:|---:|---:|---:|---|
| `ubuntu-latest` | 1.96.1 | format 1 | 0.23.1 | 2.1.14 | Checker, fixtures, core and workspace checks pass |
| `macos-latest` | 1.96.1 | format 1 | 0.23.1 | 2.1.14 | Same |
| `ubuntu-latest` | 1.98.1 | format 1 | 0.23.1 | 2.1.14 | Same, all features |
| `macos-latest` | 1.98.1 | format 1 | 0.23.1 | 2.1.14 | Same, all features |

The Rust compiler supplies partial shared-adopter evidence for Cargo plus `cargo_metadata`: its maintained `tidy` check uses the same metadata-command and recursive dependency-policy pattern. Cargo documents metadata format 1 as its versioned machine interface. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html))

This compatibility matrix is **planned acceptance evidence**, not a result already executed.

**Perplexity**

The members of the stack—workspace topology, `cargo-deny`, `dep_graph_rs`/`cargo-modules`, arch-check harness, and hook/CI integration—are highly compatible. Cargo workspaces provide the structure in which `cargo-deny` operates, and `cargo-deny`’s workspace-aware diagnostics reinforce dependency rules encoded in crate boundaries.[5][8][9][10][16] `dep_graph_rs` operates at the crate level and is oblivious to workspace, making it safe to use on core or other crates without interfering with `cargo-deny`.[18] The arch-check harness consumes both `cargo metadata` and `dep_graph_rs` output, but these are read-only operations that do not alter the workspace. Lefthook and GitHub Actions orchestrate these tools without introducing conflicts, as shown in examples where `cargo-deny` and other Rust commands run together.[6][16]

No shared adopter in the provided landscape uses this exact stack, but the combination of cargo workspace, core + adapters architecture, `cargo-deny`, and CI integration is well supported by practice examples.[5][8][14][16] The stack is designed to respect the template’s MSRV and OS requirements, as all tools are intended for stable Rust and tier-1 targets.[10][16][18]

**Gemini**

The recommended enforcement stack (`cargo workspaces`, `rust-clippy`, `cargo-deny`, `boundary-rust`, and `lefthook`) is fully and robustly compatible. The architectural design ensures that all tools operate orthogonally, analyzing the codebase from distinctly different vantage points without conflict:
*   `Cargo` controls the physical build mechanism and the strict inter-crate DAG.
*   `cargo-deny` operates passively, parsing the resolved `Cargo.lock` and metadata generated by Cargo without interfering with the compilation process.
*   `clippy` taps natively into the `rustc` compiler stream via Cargo to execute its targeted type-level bans.
*   `boundary-rust` operates completely independently on the raw source code AST via the `tree-sitter` parser, requiring no integration whatsoever with Cargo's compilation phases or lockfiles.
*   `lefthook` serves simply as the orchestrator, invoking their respective CLI commands concurrently.
These tools are routinely tested and deployed together in numerous high-stakes, modern Rust monorepos. For example, Embark Studios heavily utilizes the combination of `cargo`, `clippy`, and `cargo-deny` in unified, mission-critical pipelines [cite: 24, 36].

### Parameters

**OpenAI**

`owns: none`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version and tested in CI`

`assumes current rust-version = 1.96`

`assumes current MSRV CI toolchain = 1.96.1`

`assumes current stable toolchain = 1.98.1`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes R01 resolves to a port/adapter split; adapter package internals and trait-object-versus-generic-bound form remain R01-owned`

`assumes http-transport-injection-seam = unspecified and irrelevant to the allowed package direction`

`CONFLICT: none`

Rust 1.98.1 was current on 2026-09-17; Rust 1.99 was scheduled for 2026-10-01. The MSRV value must therefore be recalculated at the next template minor release. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

**Perplexity**

This item owns F021 (Cargo workspace crate topology) and sets:

owns F021 = multi-crate workspace with `rs_launch_blueprint_core`, `rs_launch_blueprint_composition`, `rs_launch_blueprint_cli`, `rs_launch_blueprint_web` as members, with core independent of frameworks and front-ends, composition dependent on core, and front-ends dependent on core and composition but not on each other.[5][7][8]

It assumes R01’s parameters:

assumes R01.port_adapter_seam = traits or generic bounds defined in `core` and implemented in front-end crates; the exact shape does not affect crate boundaries for this item.

No conflict with consumed parameters arises; the design respects edition 2024, MSRV policy, license, and OS matrix.

**Gemini**

*   `assumes R01 ports-and-adapters-seam` = `*` (The mechanical crate boundary design ensures that *any* trait-object or generic-bound seam shape fits safely and isolated inside the `crates/core` workspace member).
*   `owns F021 workspace-topology` = `multi-crate-virtual-workspace`
*   `owns F020 package-namespacing` = `directory-nesting-with-prefixed-crate-names`
*   `owns F008 framework-bleed-guard-authoritative` = `cargo-deny-bans`
*   `owns F009 framework-bleed-guard-fast-mirror` = `clippy-disallowed-types`
*   `owns F006 core-internal-layering` = `boundary-rust`
*   `owns F010 bounded-context-module-graph` = `boundary-rust`
*   `owns F116 boundary-check-hook-tier` = `lefthook-pre-push`

### Migration implications

**OpenAI**

1. **Root `Cargo.toml`**
   - Convert to a virtual workspace.
   - Set resolver 3.
   - Add member list, inherited edition/MSRV/license/lints, path dependencies, and architecture metadata.

2. **`rust-toolchain.toml`**
   - Pin current template toolchain to 1.98.1.
   - Keep the MSRV job explicit at 1.96.1.

3. **`crates/domain/`**
   - Move innermost entities/value types and dependency-free domain behavior here.
   - Add `rs-launch-blueprint-domain/Cargo.toml`.

4. **`crates/core/`**
   - Move public application/library code here.
   - Name the package `rs-launch-blueprint`.
   - Depend only on the domain package and R01-approved inner packages.
   - Re-export only intended domain API.

5. **`crates/adapters/*`**
   - Add one package per concrete adapter selected by R01.
   - Each adapter depends inward on core-family packages.
   - No adapter may depend on composition, CLI, or web.

6. **`crates/composition/`**
   - Move constructors and wiring here.
   - Depend on core plus concrete adapters.
   - Do not depend on `clap` or `axum`.
   - `publish = false`.

7. **`apps/cli/`**
   - Move binary entrypoint and CLI framework use here.
   - Depend on core and composition, never web.

8. **`apps/web/`**
   - Move server entrypoint, router, handlers, and HTTP framework types here.
   - Depend on core and composition, never CLI.

9. **`xtask/`**
   - Add architecture policy parser, declared checker, resolved checker, graph diagnostics, and tests.
   - Pin `cargo_metadata = 0.23.1`.

10. **`.cargo/config.toml`**
    - Add the `cargo xtask` alias.

11. **Architecture fixtures**
    - Add one passing fixture and the negative fixtures enumerated above.
    - Ensure fixture workspaces do not accidentally become production workspace members.

12. **`lefthook.yml`**
    - Add pre-commit declared/core checks.
    - Add pre-push resolved, fixture, and workspace checks.

13. **`.github/workflows/ci.yml`**
    - Add a first-class required architecture job.
    - Run Ubuntu/macOS and MSRV/current stable.
    - Make expensive jobs depend on architecture success.

14. **Documentation**
    - Add an architecture diagram and rule-change procedure.
    - Document that a new directional layer or context requires a package.
    - Record R01-owned adapter package names without changing R02’s policy.

**Perplexity**

Implementing this stack in the template requires several file-level changes:

Creating a workspace root `Cargo.toml` that declares `[workspace]` and lists `rs_launch_blueprint_core`, `rs_launch_blueprint_composition`, `rs_launch_blueprint_cli`, and `rs_launch_blueprint_web` as members, with shared version, edition, authors, and license via `[workspace.package]`.[5] Creating `crates/core`, `crates/composition`, `crates/cli`, and `crates/web` directories, each with their own `Cargo.toml` and `src` layouts, and moving existing code into these crates according to their roles. Ensuring that `core`’s `Cargo.toml` declares only allowed dependencies (no frameworks, no front-end crates), and that `cli` and `web` declare dependencies on `core`, `composition`, and their respective frameworks.[5][8] Adding a `deny.toml` at the workspace root, configuring `advisories` and `bans` as described.[10][15] Installing `cargo-deny` and adding Lefthook configuration for pre-push hooks that run `cargo test --workspace`, `cargo clippy --workspace`, `cargo deny check`, and the arch-check harness.[6][15][16] Creating an `xtask` crate for the arch-check harness and writing code to consume `cargo metadata` and `dep_graph_rs` output.[12][18] Adding GitHub Actions workflows to run tests, clippy, `cargo-deny`, and the arch-check harness on pushes and pull requests.[16]

These changes are significant but localized, affecting the workspace setup and static-analysis configuration rather than the business logic itself.

**Gemini**

The transition of the `rs-launch-blueprint` template to this mechanically enforced architecture will require the following specific file-level adjustments and restructuring:
1.  **`/Cargo.toml`**: Created at the repository root strictly as a virtual workspace manifest.
2.  **`/deny.toml`**: Created at the repository root to explicitly define the `[bans]` and authorized `wrappers`.
3.  **`/.boundary.toml`**: Created at the repository root to define the internal core layers (e.g., `domain`, `application`).
4.  **`/lefthook.yml`**: Updated to specifically map the `cargo deny`, `cargo clippy`, and `boundary check` commands to the `pre-push` git phase.
5.  **`/crates/core/clippy.toml`**: Created to explicitly ban external framework types (e.g., `axum`, `clap`) from the core source code.
6.  **Directory Restructuring**: All existing source code must be physically migrated into the isolated `crates/core/`, `crates/cli/`, `crates/web/`, and `crates/composition/` module directories.

### Validation strategy

**OpenAI**

**Executed during research**

- Official Cargo/rustc behavior, Rust compiler `tidy`, candidate documentation, current Rust releases, practice repositories, and hook-manager release evidence were inspected.
- No template repository was available in the prompt, so no Cargo, Lefthook, CI, benchmark, or mutation command was executed.
- Exact registry/GitHub API figures remain unresolved where noted.

**Planned positive validation**

```bash
cargo xtask architecture --declared --locked
cargo xtask architecture --resolved --locked
cargo test --locked -p xtask architecture

cargo +1.96.1 check --locked --workspace --all-targets
cargo +1.98.1 check --locked --workspace --all-targets --all-features
cargo +1.98.1 test --locked --workspace

lefthook run pre-commit --all-files
lefthook run pre-push
```

Expected: every command exits zero.

**Planned negative validation**

For each fixture:

```bash
cargo xtask architecture \
  --manifest-path tests/architecture/fixtures/<fixture>/Cargo.toml \
  --declared
```

or:

```bash
cargo xtask architecture \
  --manifest-path tests/architecture/fixtures/<fixture>/Cargo.toml \
  --resolved
```

Expected: non-zero exit and a diagnostic containing:

- Source package.
- Forbidden target package.
- Dependency kind and target condition.
- Violated rule.
- Shortest path for resolved violations.
- Policy location in root `Cargo.toml`.

**Compiler-boundary proof**

In a temporary fixture without an illegal manifest edge:

```rust
use rs_launch_blueprint_web::router;
```

Expected:

```bash
cargo check -p rs-launch-blueprint
```

fails because the web crate is not a direct dependency.

Then add the illegal dependency. Expected:

- Rust compilation may succeed.
- `cargo xtask architecture --declared --locked` fails.

That pair proves why both compiler partitioning and policy checking are necessary.

**Framework-bleed proof**

Test all of these in separate fixtures:

```toml
axum = "..."
web-framework = { package = "axum", version = "..." }
axum = { version = "...", optional = true }
[target.'cfg(target_os = "macos")'.dependencies]
axum = "..."
[build-dependencies]
clap = "..."
[dev-dependencies]
clap = "..."
```

Expected: declared mode rejects every direct form. A fixture where a permitted direct dependency brings in `axum` transitively must be rejected by resolved mode.

**Performance acceptance**

Linux:

```bash
/usr/bin/time -v cargo xtask architecture --declared --locked
/usr/bin/time -v cargo check --locked --all-targets \
  -p rs-launch-blueprint-domain \
  -p rs-launch-blueprint
```

macOS:

```bash
/usr/bin/time -l cargo xtask architecture --declared --locked
/usr/bin/time -l cargo check --locked --all-targets \
  -p rs-launch-blueprint-domain \
  -p rs-launch-blueprint
```

Run once cold and at least ten times warm. Record median and p95. Do not claim benchmark superiority over cargo-arc or other tools from unlike workloads.

**Security and fitness completion**

Before merge:

```bash
cargo +1.96.1 check --locked -p xtask
cargo +1.98.1 check --locked -p xtask
cargo audit
```

Refresh the exact crates.io, GitHub, and RustSec figures using the owner-mandated endpoints.

**Perplexity**

Validation of this stack involves both structural and behavioral checks.

Structurally, verify that the workspace builds and tests successfully via `cargo build --workspace` and `cargo test --workspace`, and that `cargo metadata` shows the intended dependency graph: `rs_launch_blueprint_core` has no dependencies on front-ends or frameworks; `rs_launch_blueprint_composition` depends on `core`; `rs_launch_blueprint_cli` and `rs_launch_blueprint_web` depend on `core` and `composition` but not on each other.[5][12]

Behaviorally, run `cargo deny check` and verify that banned frameworks appear only under front-end crates and not in core or composition, and that license and advisory checks pass.[9][10][16] Run the arch-check harness to verify that module-level layer contracts are respected in core and that any forbidden imports trigger failures. Run Lefthook pre-push hooks and CI jobs to ensure that violations in local development and in CI result in failed pushes and builds.

Expected behavior is that any attempt to introduce a framework dependency into core, a dependency from core to composition, or cross-front-end dependencies results in compile-time errors or static-analysis failures at pre-push and CI tiers.

Planned checks include additional use of `cargo-udeps` for trimming unused dependencies, which is not central to boundary enforcement but supports dependency hygiene.[13][14]

**Gemini**

To empirically prove that the principle of mechanical boundary enforcement holds in a realistic development scenario, the following commands will be executed automatically in the CI pipeline:
*   `cargo check --workspace`: Proves that the inter-crate DAG is sound and the virtual workspace compiles cleanly without cyclic dependencies.
*   `cargo clippy --workspace --all-targets -- -D warnings`: Triggers the fast local mirror check. If a developer attempts to use `axum::extract::State` inside the core domain, this planned check will yield an executed result of an immediate compilation failure due to a `clippy::disallowed_types` violation.
*   `cargo deny check bans`: Triggers the authoritative CI graph check. If an infrastructure crate like `axum` leaks into the `core` crate's dependency tree transitively, this planned check will yield an executed result of an explicit ban error, halting the pipeline.
*   `boundary check . --fail-on error`: Proves strict internal layering. If code within `crates/core/src/domain/` attempts to import from `crates/core/src/application/`, this planned check yields an executed result of an AST-based architecture violation, pinpointing the exact illegal import statement.

### Confidence & re-verify trigger

**OpenAI**

**Overall confidence: high on architecture, medium-high on the implementation bundle.**

High-confidence findings:

- A genuine multi-package workspace is necessary for compiler-level dependency direction.
- A graph-policy check is necessary because adding an illegal manifest edge makes an otherwise illegal import compile.
- A repository-local metadata checker is a better fit than cargo-deny, Hakari, or Machete.
- Core framework guards require dependency-graph policy; `cargo check --no-default-features` alone is insufficient.
- Rust package names, not nested source directories, provide package namespacing.
- Cheap declared checking belongs at pre-commit; resolved checking belongs at pre-push and CI.

Confidence reductions:

- Exact mandated crates.io/GitHub metrics and issue-response calculations were not returned by the research transport.
- The direct RustSec page for `cargo_metadata` must be refreshed.
- The compatibility matrix and timing budgets are proposed rather than executed.
- R01’s concrete adapter package names were unavailable.

Re-verify when any of the following occurs:

1. **2026-10-01 or later:** Rust 1.99 becomes stable; recalculate stable-minus-two as 1.97 and apply the owner’s minor-release rule. ([forge.rust-lang.org](https://forge.rust-lang.org/))
2. `cargo_metadata` publishes 0.24 or raises its MSRV.
3. Any RustSec advisory opens against `cargo_metadata` or its required tree.
4. cargo-arc stabilizes its versioning, documents numeric MSRV and Ubuntu/macOS testing, closes its parser-coverage gaps, and shows at least two substantial adopters.
5. `cargo-depgraph-check` adds member-scoped external/reachable dependency rules and complete dependency-kind handling.
6. Pre-commit declared mode exceeds five seconds warm p95 or core check exceeds ten seconds.
7. R01 creates additional port/core layers; each must be represented as a member and policy rule without changing dependency direction.
8. CLI installation through `cargo install` becomes an owner requirement; publication of composition/adapters would then need a separate packaging review.
9. The exact endpoint figures remain unresolved at implementation time; in that case the dependency pin is not merge-ready.

**Perplexity**

Confidence in the chosen stack is high for workspace topology and `cargo-deny`, based on authoritative guidance and practice examples.[5][7][8][10][15][16] Confidence is moderate for the arch-check harness and `dep_graph_rs`, as they require custom implementation and rely on newer tooling.[18] Re-verify triggers include:

Significant growth in core complexity that may warrant multi-crate layering. Major changes to `cargo-deny`’s configuration format or behavior. Changes to `dep_graph_rs` or the emergence of new tools that better support declarative layer contracts. Shifts in CI platforms or hook tooling.

**Gemini**

The confidence in this composite architectural stack is exceptionally high. The combination of Cargo's strict Ahead-of-Time compilation model, Embark Studios' production-grade graph auditing, and precise AST-level static analysis creates a mechanical barrier that is virtually impenetrable and far superior to relying on conventional code review discipline. 

**Re-verify trigger**: If the Rust language ecosystem stabilizes a highly anticipated feature for "Sealed Traits" or "Sealed Modules"—which natively provides fine-grained visibility control without requiring physical crate boundaries—the absolute necessity of the multi-crate virtual workspace (F021) should be critically re-evaluated for potential ergonomic simplification. Additionally, monitor the trajectory of `boundary-rust`; if its maintenance ceases, alternate AST parsing strategies may need to be integrated into `cargo clippy` custom lints.

**Sources:**
1. [mit.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE74OhC0O40lNAFwtNp6fgW2ygb-Qua_2v_ttDVwiX7z_xe2fYFffsbY7A3yiy04d3eedaHONkVx029e4cFBUl6z_gWCrnPwxETj9XtnHlCIbBUnMSNVp1PFIx6SgP_DtOFRzqz7ti4PymSBNuAjSs92yqABeVSfHQYF39l7E_ACc8pEkVpZUTqgO8MIvNVDtmALuozENjsYLYSUjpNR7SIQfv75OQu7QIsZu0aNS_PT9Ou2IkR)
2. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbpdOhLhDt3Tl9RYbRyLU2l6JLGFcHNKKyZzsn_Ze_czeaAVOnQ8ZSp4O8xTYO0Os2OApzvvGXTeZfCf84VyrDh6xBROS2gZ10FC9HHUguDXt3r-VuoNougNlaJ7qWHXJDSGIazg9imi6_Pi0i6gQ=)
3. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFz8hzuzsisO_4DvzXDRYB8eBcvHeL8jmAbfY_KjtsAjuJ4COp6AxJzR7RpL4ZN3-LeVebfJ7VFecPocXHbmCoPTh1Ocj5tKwtuw9MTx06IshsrNu0OHRJlV3OT_qok4bYvx9RGSjzKhzOAIsGQDbjrMKhJO_jn4QIVnEl3a6ET9RWkROz5E0Y1YvLAARXqZA==)
4. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1JWuFyqZLRfgmVgG08I_yKry4ohconrIQvup6qxjaMSxuA-9o72s23qEEe0EL4E6tLiyuIMvnnCknM5mU_zVG6LcpjeQffpk-kggSjhonV-XOQKHzenghcWLUjkMLfEzN)
5. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFItYWx0ak66IFrtbDBrTnupr4ooue1VirJhdenNiN7bEX20xcS5RcK-LIIza6erG7EguXYKo0LV4v7QcuiipplKWJD9ny7s75hhbt-7d81bwCS4mbSyohLyBHyga7am4vFPtuDHxzP6Zo3t8TAPg==)
6. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFPGehYIFxVcPxAgG8vBuc0e4PMMdqpkh2qk7Z-FuVET4Wlys4kbDsy6wqhbCOFBXzku9wqMIYfLZNMMVJNFMHwyyv0qbA7qUOZnnXmVGewK2q37_ZmOPw6tsGhNr62_4AbuysuwyQQCrBKW5Q5LfHY)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFwBMGtCkMNfkIx3Mly4N7ImPUNOeJ7vQbj_Ro-cIlxW_gZsui9cUa5oBGXIaP6cs9hr4q3AAdkRUa11XCiXiqG1bkvWXyNGS7fWAKHlh4ijACEM8l0beiGRDlWzw==)
8. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEo6L6TsuRY9upThsSDFo5uGkUXfR5dHhV2dGWzrqgpWZdEqErJdykgxYs2g97AvP359BzzXn9cYIJo1JYtJ3V9saD8IYxwV7cNp4ruFk4fMvR8g2qmiUmDhm0sNBmrvy71)
9. [x-cmd.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHkVTe4HdO_u_PjTazHIdS42rqMRdpWGBasMZm5Ztdu2GmyAs0YgNHnas1ApUfj8Reg-PXanWfvqOv_IngJehlm9Zil2IqI8teqVOMMeLQWmMu6oFfA2ZstlRqc4vY=)
10. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrSGfWYulFxRGspzoAamXNbL6qKCTBPTTDiSaYHGjFts2wTTBBGTr3BlxRSdr_Ih9bwu_icljCyOT-WeNqg5pJ9oYWv9Y4N4lqxF4t_mC022-hCigSXsvHGA==)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-UfkSHU07ySr_JFw3iRA4yOsHKKZ7J0cnikKmH2gkJ29H8wh-JVi1-TEUp2ZfK3xtNrMNDCu6G3ZMhJLVrgUFZG5gc-W66OEXaPT1hmYQVKZitCPKl6o=)
12. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGpi56VY77ZjQ4f6mTRE_NxrE5I04eXuDr_i3DfdDCJ785Y5g0FGvCYIhxe_oKQfe9MD0goLIuOU6XEa57kREEl2XPLo8OPYnD9PUhZIKUagzkx1zfdxmsJ9ZUfHg==)
13. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEZB90sF9ppPakT8yIcKWWCPlv2F6_AZm0UqXW-2xH1iimq6ooNBAp0MNzW5wUyU6ez6WNZ0nR9_Z0cQODcjydlhEiB1m0qAeqlpWfjfn3G40SLJauH)
14. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH_DwjWB-UU93v_nGLbDUkYTrluVoo3PQeMWgoaMNwPW65_KrV8goOrkw03XITgE_G09hEqF0mnJJAE3CaSbSDpdnNxw9w94LlIQzb4lj2F9Vq5yFt1G4SluB-gWMN2Embm-o92jppPz23Um-M=)
15. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEuHpTYEqSRrW9E65Hu1E0J3j3lmJi909adseLalPOaYIJhSaTDpWUDvlTiUmmiqlwWm72oi50WRpo-7_vHZsT0MSiQaxV1OeAmzmisBLq__DMPm2zq-nlI3_jaIbMpW8c=)
16. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFm0PRQ8KcqiBnM-VD5A4uJ__zSk-Q-lr5eWb-I96GtWuuV4e8ql2vIyy4Ym6khKx5fiRPmLKFeXmkHlwxGmhGWdjE6NzHfbr2O7x3htdI7OMps8rcXkJn1k0vzUJKIr6DWCQ1tHFbUjk3C8F16TqhWiYpUheXsIhoxkcwsZtE=)
17. [40tude.fr](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcM7R3QOhlIQNGF8gndEOOCLBLLOcaR53oho48pam4B5qqB3WrL4VDRq964okLZm2q9Q0POwvJYs1fSFeVMxkovMd9fqFjSndPia5w2-AEooEBr8T1_WNkkYbZdRvVhXQ8AWaBsaZQfH6qjC-rJ8JdTbS-ovLGCwcLLukZJNIogIJL4dystpb3)
18. [thoughtworks.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG8PLXvON4OHycBIqcIC2W0UrBxYyvLUiLUrIRTcZsR9G9T_NlJC-jVHFHCeWburtere__mfTwUHauC6KkvVLQ7IePQD_MfgVz8i3-tonH8TKVjSE14FSmRHmpd4wdxpaX55HpICMeDcpdHvrR_eGelB3DlBxgeZVx6lbcMc8XR0-sDHSff4yS5aHAfEQtt9qQeWc1Lj1H9ekDNwzHzXu05)
19. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFq5a-YJTksBpInGLk-Pe-dTzk3Wkby71p1O2a4N1LTz1X-XBD1nEbrLlR-w5Xb1O-d2VjjoHcOOS37MDTmjzBEAymI3YbDm3g4YfoY42yEkT1lm_YQ_Yf10GEBc-tqnvPMrLIQDOvRcHHUYktKXmebP3Zg4qxsnLtGUJUcCGR4Rm4=)
20. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHmTZHGk6kzPTFzgg1Qr3UstZnXrZ37kAups79dZ4SpNjpGepgaoMN-36kljIJ3bCPJdjTdouqHA-fXzCAHcvBIEEHeJUIdbDcKurxHn2-_tmjZ0vpcwACnQeOq34euHxiwz4bEQarkMEBn-BepHkUrKEm1M5iP6Q==)
21. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFsUZQWrgXYvoQ6gT-raqHOJXim35Oc3ai43AfQlxkrGYicEf_cLSRHE6I2odI_wDNwiF_C_UIKGBh1snAqa67UZJ1iLfWSsP70I1bz5cW3Gfe27i7Lbk6gnDT6ZOJyBaa6mSOT1rXuI4X26FUvUET3r_t84So=)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrCMFXvoKuBuhBrEmoLs2AYSE1XKOaxX8Ypkr0JV-j98TxYaqnHJ91HsaGGRA2F7WY_1Eyf-y6al-gSKznS_Wu9tIdot0EfWHA_hOCXTwLqoa6UcPgf3LcskG_907uRByyxD611hnrf-MlbrQXRnqO)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEzUs_HCeWIO_Way-mk5Qll1-e_qoAz4dDEIH2BKmkB2B_qQGjseTR0IjgOobywsYV0TFuGUuqXiExMHYbr8Gp4FgsaC0SjEfO21tmofkk4BdfxdSM4L6XOF1-7WzyLgOLBmYra5kwTrytaC7jGW9h-)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG5qY6Rmox4rSTydNNbVp1wju1XXOA31nGpx-HqrmkfTuehOiPvWcAye0JrCTbgto1rk9D84ZMaC6xr_QhubDNhwFp6-0sR5UdSsJdhUsA-lg==)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGEjKdOD5ubo1738IyrZuokuHCdnMpFry7osjN_7aE0yOF1dog3NM0Sj73Rf906UPg2x38INU3eYyNl6YQA2Y-feQs607wPoJ5SBpGsB5f2AvcF-cNtJAl0QGqBayANs9Y=)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGooYYv0lVAYcIHCgS2Zy0P2oH6WtVm_541ivgPoU3wGq8TrFKD6SUg-A4zufCC6iZ0gxzSfARfeaTA2sozFav-5vHwIA-9LFdpxsBGAqIMuMhKBmuz4yY8pNnhjSq1v3ymgDrkXxbh)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJCudcPAEFKFPH5a4qJaddmjeYxb0NRezIq9MrkxYxBmy9kPSLiCNvAvPmN43pE1Ldjym3JANEOkt6icl33s01PWi17cKaS6Vm0_EVIuLg8JUwH1bjU47ObRNBMZSv2Zkt6oL9BkalLtOCDQg=)
28. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsWLPKQVBsBBTd03dgiuB2btS6Vu4yc66YL7hpEKIRAdyeVpYCXzy2PCWNBIszodPhB_WEfkBlfA82DN6QoE6fb2Cr09gGxoX9GPEd9_j9XagSu55EEYjTkNxWsrDfZFUnIVLRdxJeVRWdwGg=)
29. [deps.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGjtNmy843YjNKxpvOCATDFWUw5D82dn2gD6Rsblrq8M-P9L77zF5Q6qvfuwoBnx5aw-wjzEwP4sPK-Fb__mSJJtTz7jGSPaXCAtkVBZInQ9GuGQHXNyMLZo2cfPLlFdmk-Dnv5-D_GG-lg)
30. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF95Bgvb5w1bBxi8tiKFMJErAOQ6SrB4Tp7_QwwCkGVVbU85BX-16g45IicXbl12YEk22pQORfkRAndGouFW3AHI_TslU5Jt1jWaeKJunao9CbqhGBbXNTohj9-krVvU6dNTIC38S3UdqcOhA==)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGBJ_QsprcQOcVfziRkxDuf4HQjLCY_Tn0qLu25OOZ6zeYSnPG-yRynwHux0JrVU1GU7K2ASDY52Y_a5daaJU1BYVW8rpVX1oeKm9W-vGwtGqYN16B0qhhV0Yo=)
32. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFUsWkumuZ3f57dlwDg9tuEABpC3DD1NUGOiupCctuVPPLWqgBCYK8G7WPW-6Z-mxn8csCEhXfHeVtogP5rAOBIdY56p8MWsWM8eERCGRTneVU=)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGL-RBTFcDFrPpcYE88LwuBRBCJzquDDm5AFBju-RbWRx8QevLQHoubdNgSSpHNCyaPpSUR65gzmaV0tG_vyZK2y4tvvreQ_t9DIfii73Z--mlzjQs6kzUUtGEarIly0Z0LyA==)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHaKYS0jkdzXArU4NTPaGN1_6UODOr5iq5qLvO7gd0nmQiw1Efmk0LxTCtMsNhy5GblzhcgWKcc8y7okafg-YI6BFUA-ohfNZyM13SZtYUBJ-_YE7KPotOt4GPhdY30zoLUgJ1T)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEItNscLBoElNyrzFDLKyAOWUcaghjDMMnqBo5799A2z59fj10ZLBfnY4xW3HXLMs5XmyPvBKcc5UfHkHJgu61pi5m10vvm5y9n0hzZfEUKPiKAkHamhoItAu4aVxUCVGqLRIstcC18)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFG9HHR4_DjzGDOUE6wokcCzuRbGrhaBYMHhSRyYhA7r43N45rURF8XcgHeoEIBFK-8xuVWQjeAKZHYkdKEnDq1pX97W396n03ePMki-EbAD8rAnlKe8INegQ6NNULXMM-e)

### Sources

**OpenAI**

All retrieved **2026-09-17** unless otherwise noted.

1. `https://doc.rust-lang.org/cargo/reference/workspaces.html` — Cargo workspaces, inherited metadata/lints, workspace metadata. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html))
2. `https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html` — workspace package structure and resolver 3 example. ([doc.rust-lang.org](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html))
3. `https://doc.rust-lang.org/cargo/commands/cargo-metadata.html` — versioned machine-readable package and dependency graph. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html))
4. `https://doc.rust-lang.org/cargo/reference/external-tools.html` — official guidance to use Cargo CLI interfaces and `cargo_metadata`. ([doc.crates.io](https://doc.crates.io/external-tools.html))
5. `https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html` — direct crates supplied through `--extern`. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html))
6. `https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md` — Cargo workspace RFC. ([github.com](https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md))
7. `https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs` — Rust compiler’s `cargo_metadata` dependency allowlist implementation. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs))
8. `https://doc.rust-lang.org/stable/nightly-rustc/tidy/deps/index.html` — documented permitted-dependency checks in Rust `tidy`. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/nightly-rustc/tidy/deps/index.html))
9. `https://rust-analyzer.github.io/book/contributing/architecture.html` — crate-oriented architecture and invariants. ([rust-analyzer.github.io](https://rust-analyzer.github.io/book/contributing/architecture.html))
10. `https://rust-lang.github.io/rust-analyzer/xtask/index.html` — maintained `xtask` pattern. ([rust-lang.github.io](https://rust-lang.github.io/rust-analyzer/xtask/index.html))
11. `https://github.com/tokio-rs/axum` — `axum`/`axum-core` practice evidence. ([github.com](https://github.com/tokio-rs/axum))
12. `https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs` — guidance toward the lower-level core crate. ([github.com](https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs))
13. `https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md` — large-workspace dependency-graph practice. ([github.com](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1))
14. `https://microsoft.github.io/rust-guidelines/guidelines/project/index.html` — independent workspace guidance. ([microsoft.github.io](https://microsoft.github.io/rust-guidelines/guidelines/project/index.html))
15. `https://docs.rs/cargo_metadata/latest/cargo_metadata/` — `cargo_metadata` 0.23.1 documentation. ([docs.rs](https://docs.rs/cargo_metadata/latest/cargo_metadata/struct.Source.html))
16. `https://github.com/oli-obk/cargo_metadata` — repository, license, maintenance context. ([github.com](https://github.com/oli-obk/cargo_metadata))
17. `https://github.com/oli-obk/cargo_metadata/actions` — project automation evidence. ([github.com](https://github.com/oli-obk/cargo_metadata/actions))
18. `https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md` — 0.1.0 direct internal allowlist scope and external-dependency exclusion. ([docs.rs](https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md))
19. `https://github.com/1898andCo/cargo-depgraph-check` — candidate repository. ([github.com](https://github.com/1898andCo/cargo-depgraph-check))
20. `https://docs.rs/crate/cargo-arc/latest/source/README.md` — cargo-arc architecture rules and documented analysis limitations. ([docs.rs](https://docs.rs/crate/cargo-arc/latest/source/README.md))
21. `https://github.com/seflue/cargo-arc` — cargo-arc repository. ([github.com](https://github.com/seflue/cargo-arc))
22. `https://docs.rs/crate/archaven/latest` — Archaven rules and source-resolution limitations. ([docs.rs](https://docs.rs/crate/archaven/latest))
23. `https://docs.rs/crate/cargo-archtest-cli/0.2.3` — architecture rule surface and CI example. ([docs.rs](https://docs.rs/crate/cargo-archtest-cli/0.2.3))
24. `https://github.com/evilmartians/lefthook` — Lefthook repository. ([github.com](https://github.com/evilmartians/lefthook))
25. `https://github.com/evilmartians/lefthook/releases/tag/v2.1.14` — current surfaced release. ([github.com](https://github.com/evilmartians/lefthook/releases/latest))
26. `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` — compile/resource productivity evidence. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
27. `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/` — Rust 1.98 release. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/))
28. `https://blog.rust-lang.org/releases/` — current patch and historical release list. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
29. `https://forge.rust-lang.org/` — current release channels and Rust 1.99 schedule. ([forge.rust-lang.org](https://forge.rust-lang.org/))
30. `https://releases.rs/` — current stable 1.98.1 and upcoming release date corroboration. ([releases.rs](https://releases.rs/))

**Sources**

- [https://doc.rust-lang.org/cargo/reference/workspaces.html](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs](https://raw.githubusercontent.com/rust-lang/rust/master/src/tools/tidy/src/deps.rs)
- [https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md](https://docs.rs/crate/cargo-depgraph-check/latest/source/README.md)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://microsoft.github.io/rust-guidelines/guidelines/project/index.html](https://microsoft.github.io/rust-guidelines/guidelines/project/index.html)
- [https://github.com/rust-lang/rust/blob/main/Cargo.toml](https://github.com/rust-lang/rust/blob/main/Cargo.toml)
- [https://rust-analyzer.github.io/book/contributing/architecture.html](https://rust-analyzer.github.io/book/contributing/architecture.html)
- [https://github.com/tokio-rs/axum](https://github.com/tokio-rs/axum)
- [https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1](https://github.com/astral-sh/uv/blob/main/CONTRIBUTING.md?plain=1)
- [https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html)
- [https://doc.rust-lang.org/nightly/cargo/reference/features.html](https://doc.rust-lang.org/nightly/cargo/reference/features.html)
- [https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html](https://doc.rust-lang.org/cargo/reference/specifying-dependencies.html)
- [https://github.com/evilmartians/lefthook](https://github.com/evilmartians/lefthook)
- [https://docs.rs/crate/cargo-arc/latest/source/README.md](https://docs.rs/crate/cargo-arc/latest/source/README.md)
- [https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html](https://doc.rust-lang.org/nightly/rustc/command-line-arguments.html)
- [https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md](https://github.com/rust-lang/rfcs/blob/master/text/1525-cargo-workspace.md)
- [https://doc.crates.io/external-tools.html](https://doc.crates.io/external-tools.html)
- [https://docs.rs/crate/archaven/latest](https://docs.rs/crate/archaven/latest)
- [https://docs.rs/crate/cargo-archtest-cli/0.2.3](https://docs.rs/crate/cargo-archtest-cli/0.2.3)
- [https://github.com/oli-obk/cargo_metadata](https://github.com/oli-obk/cargo_metadata)
- [https://github.com/1898andCo/cargo-depgraph-check](https://github.com/1898andCo/cargo-depgraph-check)
- [https://docs.rs/cargo_metadata/latest/cargo_metadata/struct.Source.html](https://docs.rs/cargo_metadata/latest/cargo_metadata/struct.Source.html)
- [https://github.com/oli-obk/cargo_metadata/actions](https://github.com/oli-obk/cargo_metadata/actions)
- [https://github.com/evilmartians/lefthook/releases/latest](https://github.com/evilmartians/lefthook/releases/latest)
- [https://blog.rust-lang.org/inside-rust/2026/08/18/reducing-target-dir-size-on-nightly/](https://blog.rust-lang.org/inside-rust/2026/08/18/reducing-target-dir-size-on-nightly/)
- [https://doc.rust-lang.org/cargo/commands/cargo-metadata.html](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://forge.rust-lang.org/](https://forge.rust-lang.org/)
- [https://doc.rust-lang.org/stable/nightly-rustc/tidy/deps/index.html](https://doc.rust-lang.org/stable/nightly-rustc/tidy/deps/index.html)
- [https://rust-lang.github.io/rust-analyzer/xtask/index.html](https://rust-lang.github.io/rust-analyzer/xtask/index.html)
- [https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs](https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs)
- [https://github.com/seflue/cargo-arc](https://github.com/seflue/cargo-arc)
- [https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)
- [https://releases.rs/](https://releases.rs/)

**Perplexity**

This report draws on Rust’s own documentation of compilation dependency graphs, Microsoft’s Rust engineering guidance on release profiles and dependency trimming, Embark Studios’ `cargo-deny` documentation and CI examples, independent write-ups on Cargo workspace best practices and cross-platform shared-library workspaces, Rust architecture patterns guidance on hexagonal architecture and visibility, and tooling documentation for `cargo-modules` and `dep_graph_rs`.[5][7][8][10][11][12][14][15][16][18] These sources collectively provide authoritative and practice-oriented evidence for the recommended stack.

**Conclusion**

For `rs-launch-blueprint`, mechanical enforcement of hexagonal architectural boundaries is best achieved by embracing Rust’s strengths in crate and workspace design and layering them with targeted static-analysis tooling. A multi-crate Cargo workspace with a core crate, composition-root crate, and separate CLI and web front-end crates encodes composition-root isolation, inward-only dependencies, and front-end independence at the dependency level, making illegal boundaries compile-time errors. Internal layering within core is documented and enforced via module-graph tools like `dep_graph_rs` and a custom arch-check harness, while framework-bleed guards and dependency hygiene are governed by `cargo-deny` configured with bans and wrappers. Hook and CI integration via Lefthook and GitHub Actions provide both fast local and authoritative enforcement, preserving the owner’s requirements and cross-language principles.

This stack respects all fixed parameters—edition 2024, MSRV policy, license, and OS matrix—and offers a coherent, Rust-idiomatic analogue to Python’s `import-linter`/`tach`/`ruff` enforcement. It differentiates necessary ecosystem-specific implementation choices (custom arch-check harness) from shared architectural principles (hexagonal core, mechanical enforcement), providing a solid foundation for the template and a clear path for future re-verification as the Rust ecosystem evolves.

**Sources**

- [Releases · EmbarkStudios/cargo-deny](https://github.com/EmbarkStudios/cargo-deny/releases)
- [cargo-machete, find unused dependencies quickly by Benjamin Bouvier](https://bouvier.cc/2022/04/27/cargo-machete/)
- [cargo-machete, find unused dependencies quickly](https://bouvier.cc/cargo-machete/)
- [cargo-machete/CHANGELOG.md at main · bnjbvr/cargo-machete](https://github.com/bnjbvr/cargo-machete/blob/main/CHANGELOG.md)
- [Create a Shared Rust Library: Cargo Workspace Setup](https://rustz2h.com/chapter_15_rust_for_wasm_and_cross_platform_apps/series_05_project_cross_platform_app/shared_library_cargo_workspace)
- [integrate Rust unit testing and linting into CI pipeline (!6) · ...](https://gitlab.com/gitlab-org/rust/gitalisk/-/merge_requests/6)
- [rust-architecture-patterns - Skill - Smithery](https://smithery.ai/skills/davincible/rust-architecture-patterns)
- [Build Performance...](https://reintech.io/blog/cargo-workspace-best-practices-large-rust-projects)
- [cargo-deny - diagnostics](https://embarkstudios.github.io/cargo-deny/checks/bans/diags.html)
- [cargo-deny 0.18.3](https://docs.rs/crate/cargo-deny/latest/source/deny.toml)
- [regexident/cargo-modules: Visualize/analyze a Rust crate's ...](https://github.com/regexident/cargo-modules)
- [Module unit_dependencies Copy item path](https://doc.rust-lang.org/stable/nightly-rustc/cargo/core/compiler/unit_dependencies/index.html)
- [Rust で 未使用の dependencies を探す](https://zenn.dev/tktcorporation/articles/1563fc2036ff45)
- [7. Release Profiles and Binary Size - Rust Engineering ...](https://microsoft.github.io/RustTraining/engineering-book/ch07-release-profiles-and-binary-size.html)
- [EmbarkStudios/cargo-deny: ❌ Cargo plugin for linting your ...](https://github.com/embarkstudios/cargo-deny)
- [cargo-deny](https://embarkstudios.github.io/cargo-deny/)
- [cargo-udeps/Cargo.toml at master · est31/cargo-udeps](https://github.com/est31/cargo-udeps/blob/master/Cargo.toml)
- [dep_graph_rs](https://lib.rs/crates/dep_graph_rs)

**Cost**

Total: $0.7721

**Gemini**

- [mit.edu](https://web.mit.edu/rust-lang_v1.25/arch/amd64_ubuntu1404/share/doc/rust/html/book/second-edition/ch14-03-cargo-workspaces.html)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/workspaces.html)
- [rust-lang.org](https://doc.rust-lang.org/clippy/lints.html)
- [rust-lang.org](https://doc.rust-lang.org/clippy/lint_configuration.html)
- [github.com](https://github.com/rust-lang/rust-clippy/blob/master/clippy_lints/src/disallowed_types.rs)
- [github.io](https://embarkstudios.github.io/cargo-deny/)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/cfg.html)
- [docs.rs](https://docs.rs/crate/cargo-deny/0.2.5)
- [x-cmd.com](https://www.x-cmd.com/install/lefthook/)
- [crates.io](https://crates.io/crates/boundary)
- [lib.rs](https://lib.rs/crates/boundary-rust)
- [github.com](https://github.com/PSeitz/dep_graph_rs)
- [crates.io](https://crates.io/crates/hexser)
- [github.io](https://rust-lang.github.io/api-guidelines/naming.html)
- [crates.io](https://crates.io/crates/cargo-deny/0.19.0)
- [40tude.fr](https://www.40tude.fr/docs/06_programmation/rust/024_hexagonal/hexagonal_lite.html)
- [medium.com](https://medium.com/@lucorset/hexagonal-architecture-in-rust-72f8958eb26d)
- [thoughtworks.com](https://www.thoughtworks.com/insights/blog/architecture/hexagonal-architecture-explained-practical-example)
- [rust-lang.org](https://users.rust-lang.org/t/naming-conventions-for-cargo-workspaces/65369)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/bans/index.html)
- [github.io](https://embarkstudios.github.io/cargo-deny/checks/bans/cfg.html)
- [github.com](https://github.com/rust-lang/docs.rs/blob/main/clippy.toml)
- [crates.io](https://crates.io/crates/boundary-rust/0.24.0/dependencies)
- [docs.rs](https://docs.rs/cargo-deny)
- [crates.io](https://crates.io/crates/cargo_deny/0.18.0)
- [github.com](https://github.com/marketplace/actions/cargo-deny)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/641)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/846)
- [deps.rs](https://deps.rs/repo/github/EmbarkStudios/cargo-deny)
- [github.com](https://github.com/EmbarkStudios/cargo-deny/issues/50)
- [crates.io](https://crates.io/crates/dep-insight)
- [docs.rs](https://docs.rs/dep-insight)
- [crates.io](https://crates.io/crates/boundary-typescript)
- [github.com](https://github.com/kodustech/kodus-ai/issues/1662)
- [github.com](https://github.com/gitpod-io/gitpod/issues/770)
- [github.com](https://github.com/embarkstudios/cargo-deny)
