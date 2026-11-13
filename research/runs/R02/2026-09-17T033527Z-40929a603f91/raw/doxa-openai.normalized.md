## Reasoning Summary
**Researching requirements**

I need to conduct extensive research, which means starting the web search right away. The user wants every claim to have a source URL with the retrieval date, but my citation system has specific rules about raw URLs. However, since they’ve explicitly asked for source URLs, I can include them. It’s important to follow the exact heading format and gather comprehensive, current information. I’ll also recommend a multi-crate topology and other tools like cargo-deny and clippy for optimization.
**Investigating ecosystem tools**

I need to look into various ecosystem tools, such as Cargo's built-in features, crate visibility, and workspace management. Other tools like cargo-deny, cargo machete, and potential options like hakari and archunit_rs are also worth considering, along with custom lint solutions and clippy's disallowed types. It’s essential to gather up-to-date information as of September 17, 2026, using official docs, GitHub APIs, and RustSec pages. I’ll start with a broad web search for the necessary data and plan my API calls accordingly.

### Landscape

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

### Principles and implementation

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

### Recommendation

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

### Members

#### Cargo/rustc multi-crate boundary pattern — 1.98.1, MSRV 1.96.1

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

#### Repository-local `xtask` 0.1.0 with `cargo_metadata` 0.23.1

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

#### Lefthook 2.1.14 and required CI placement

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

### Compatibility

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

### Parameters

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

### Migration implications

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

### Validation strategy

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

### Confidence & re-verify trigger

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

### Sources

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

## Sources

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
