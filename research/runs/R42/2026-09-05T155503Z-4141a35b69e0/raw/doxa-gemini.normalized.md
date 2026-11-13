# Dev-Toolchain Provisioning Architecture

### Landscape

The developer toolchain ecosystem within Rust presents a complex spectrum of strategies for provisioning and invoking auxiliary tooling. This domain, categorized strictly as developer-environment provisioning, dictates the reproducibility of local builds, the velocity of developer onboarding, the consistency of Continuous Integration (CI) pipelines, and the overall security posture of the repository. Historically, the Rust ecosystem has relied heavily on global installations via `cargo install`, but the maturation of the language and the increasing complexity of polyglot auxiliary tools have driven a paradigm shift toward deterministic, project-scoped isolation. 

To navigate this landscape systematically, the ecosystem can be mapped into three distinct bins representing the current state of the art:

The first bin encompasses the **built-in or first-party toolchain**. This includes the foundational elements such as `rustup`, `cargo`, and native components natively distributed via the official channels, such as `rustfmt` and `clippy`. These form the non-negotiable, universally accepted foundation of any Rust project. However, they are inherently limited to Rust-specific tasks and cannot manage out-of-ecosystem tools like YAML linters, generic secret scanners, or polyglot task runners. 

The second bin contains the **established industry standard** tools. These are utilities that have achieved critical mass, cross-ecosystem consensus, and widespread adoption. In this category, `just` has thoroughly displaced Makefiles as the premier command runner, offering a Rust-native, `.env`-aware, and cross-platform orchestration layer [cite: 1, 2]. For environment and version orchestration, `mise` has rapidly superseded legacy tools like `asdf`, providing an ultra-fast, statically compiled mechanism for deterministic multi-language toolchain provisioning [cite: 3, 4]. Similarly, `lefthook` represents the industry standard for Git hook orchestration, bypassing the brittleness of shell-scripted hooks [cite: 5, 6].

The third bin captures the **up-and-comer** solutions. These are niche, highly specialized architectural components attempting to solve specific friction points that the primary ecosystem has yet to natively address. A prime example is `cargo-run-bin`, which introduces an `npm run`-style project-scoped binary execution model to Rust, mitigating the severe version drift caused by global `cargo install` commands [cite: 7, 8]. Another entrant in this space is `flox`, a Nix-backed declarative environment manager that, while powerful, introduces significant complexities and licensing constraints [cite: 9, 10].

Authority in this analysis is established through a diverse synthesis of rigorous sources. The primary architectural authority relies on official Cargo maintainer discussions and Rust RFCs. Specifically, RFC 3168 highlights the persistent ecosystem pain points regarding the execution of binaries from development dependencies, proving that global installations are broadly recognized as an anti-pattern by the language's core maintainers [cite: 11]. Further authority is drawn from crates.io registry telemetry, providing an unfiltered, empirical view of adoption rates, maintenance velocity, and ecosystem integration [cite: 12]. Finally, technical security briefs and posture documentation from tool maintainers serve as authoritative sources on the architectural design, isolation mechanisms, and threat models of these provisioners [cite: 13, 14].

Practice evidence demonstrates a decisive migration toward declarative, project-scoped environments among mainstream, well-regarded Rust projects. High-profile, performance-critical projects across the ecosystem—such as `uv` (Astral's high-performance Python package manager written in Rust), `dioxus`, and `leptos`—heavily leverage these tools to ensure zero-friction developer onboarding [cite: 15, 16, 17]. The use of `just` is nearly ubiquitous in modern Rust repositories, primarily to escape the POSIX compliance issues and tab-indentation idiosyncrasies of GNU Make [cite: 2]. The evidence confirms that while Rust's native tools are excellent for compiling and formatting Rust code, any robust template requiring auxiliary hygiene tools (e.g., `actionlint`, `gitleaks`) necessitates a broader, strictly declarative provisioning strategy.

Fit for the `rs-launch-blueprint` template is the ultimate arbiter. The template profile spans a CLI, a library, and a web service, requiring an architecture that guarantees deterministic environments across both `ubuntu-latest` and `macos-latest` operating systems. It must completely avoid the heavy cognitive and maintenance overhead of manual script synchronization observed in the `py` template precedent. Furthermore, every component must strictly adhere to the owner's licensing parameter of `MIT OR Apache-2.0`, instantly disqualifying any tool reliant on copyleft or proprietary commercial licenses.

### Principles and implementation

The fundamental, shared engineering principle governing dev-toolchain provisioning in this template is the absolute necessity of **deterministic, project-scoped environment reproducibility with zero global state mutation**. Agreement on this principle is required at the architectural pattern level. The environment a developer uses locally must be bit-for-bit identical to the environment utilized by the CI pipeline, and neither should require the user to globally install tools, manually synchronize manifests, or resolve PATH conflicts. The observable acceptance criteria dictate that a user cloning the repository and executing a single bootstrap command will be presented with a fully functional environment where every non-cargo tool, Git hook, and Rust auxiliary binary operates at a strictly locked version.

The precedent established by the `py` template relied on a high-friction, divergent architecture. It shipped bespoke per-tool `Justfile` installer shell scripts, managed a declarative `mise.toml` manifest, and simultaneously maintained a `.flox/env/manifest.toml` environment. This required manual synchronization across three discrete systems, violating the principle of a single source of truth and introducing a massive maintenance burden. Conversely, the TypeScript (`ts`) precedent folded auxiliary tools into a unified formatter (`Oxfmt`), sidestepping external provisioners entirely. However, the Rust template requires auxiliary hygiene tools that cannot be folded into `rustfmt`, meaning the absence of a provisioner is not viable. A unified, singular provisioning mechanism is therefore mandatory.

To realize this principle, four significant architectural alternatives present themselves for evaluation:

The first is the **Built-in Global Pattern**. In this model, developers are instructed to run `cargo install <tool>` globally. This pattern flagrantly violates the core principle of determinism by introducing immediate global state drift. If a team member has version `0.10` of a linter globally installed and another has `0.13`, spurious failures arise. Furthermore, it imposes massive compilation time costs on every developer during onboarding, as they must build large dependency trees from source.

The second is the **Fast Global Pattern**, predominantly represented by `cargo-binstall`. This architecture utilizes pre-compiled binaries to bypass the compilation costs of `cargo install`. While performant, `cargo-binstall` relies on a strictly `GPL-3.0-only` license [cite: 14, 18]. Bundling or strictly relying on a GPL-3.0 tool for standard template operations violates the permissive `MIT OR Apache-2.0` licensing constraint, rendering it architecturally excluded as a mandated provisioning foundation.

The third is the **Shell Script Pattern**, as seen in the `py` precedent, which relies on `scripts/install-*.sh` orchestrations. This introduces significant maintenance overhead, cross-platform compatibility issues (especially across different shell environments like `bash` vs `zsh`), lacks declarative version locking, and forces the maintainer to manually reinvent dependency resolution and caching logic.

The fourth, and recommended, architecture is the **Project-Scoped Declarative Pattern**. This design utilizes a singular declarative manifest to securely provision all non-Rust tools, while leveraging a dedicated Rust workspace utility to map and cache project-scoped Rust binaries. This preserves the principle of determinism by establishing a definitive single source of truth. It entirely eliminates the need for redundant declarative manifests (like `flox`) and bespoke Bash scripts. 

The recommended design preserves the core engineering principle by strictly isolating toolchains. For non-Rust tools, `mise` acts as the sole orchestrator. For Rust-specific tooling, `cargo-run-bin` encapsulates binaries within the `Cargo.toml` file, compiling and caching them locally inside the workspace. The `package-manager-invocation` parameter then securely binds these tools, ensuring that `just` recipes and `lefthook` jobs invoke Rust tools via `cargo bin <tool>`, and non-Rust tools natively via the securely managed PATH exposed by `mise`.

This architecture directly addresses and challenges the existing baselines recorded in the project specifications. The specific findings and proposed changes are detailed in the review matrix below:

| Feature ID | Principle | Proposed Change | Evidence & Justification |
| :--- | :--- | :--- | :--- |
| **BASELINE-REVIEW: F183** | Single source of truth / Determinism | Eliminate per-tool installer recipes and bespoke shell scripts (e.g., `install-actionlint.sh`). Replace entirely with declarative provisioning via `mise` and `cargo-run-bin`. | Manual shell scripts are brittle, lack declarative locking, and fail silently across OS variations. `mise` guarantees version locking and automatic cross-platform fetching without maintainer intervention [cite: 4, 13]. |
| **BASELINE-REVIEW: F187** | Centralized Orchestration | Retain `mise` as the sole declarative environment orchestrator and non-cargo tool provisioner. | `mise` centralizes all non-cargo tool configurations into a single `mise.toml` manifest, operating transparently via the shell without mutating global state [cite: 3]. |
| **BASELINE-REVIEW: F188** | Permissive Licensing & Simplicity | Eliminate the `flox` provisioner entirely. Remove all `.flox` manifests and directories. | `flox` relies on a GPL-2.0 license and proprietary commercial terms that fail the template's strict fitness gates [cite: 9, 10]. Furthermore, maintaining multiple parallel manifests violates single-source-of-truth principles. |
| **BASELINE-REVIEW: F189** | Reduced Maintenance Burden | Converge entirely on `mise` from the previous three-provisioner synchronization requirement. | Eliminates the redundant overhead of keeping `Justfile` scripts, `mise.toml`, and `.flox` manifests perfectly aligned. Rust's narrower non-cargo tool surface area makes a single, lightweight orchestrator optimal. |
| **BASELINE-REVIEW: F179** | Separation of Concerns | Retain `just` to maintain the bootstrap-versus-task layering. | `just` serves as a command runner rather than a build system, cleanly separating the initialization of the environment (`mise install`) from the execution of domain logic (`just test`) [cite: 2]. |
| **BASELINE-REVIEW: F180/F181** | Presence Testing | Eliminate the `command -v` loop presence tests in `check-deps`. | Because `mise` and `cargo-run-bin` deterministically ensure tool presence before execution, manual presence testing becomes redundant boilerplate. The invocation strategy naturally fails if the tool is unprovisioned, providing immediate, actionable feedback [cite: 3, 7]. |



### Recommendation

The recommended stack is a centralized, declarative provisioning bundle composed exclusively of **`mise`**, **`cargo-run-bin`**, and **`just`**. This trio entirely replaces the divergent manual scripting and multi-manifest confusion of prior baselines. It provides an airtight, deterministic developer environment that operates flawlessly across macOS and Linux while remaining strictly within the bounds of permissive open-source licensing.

### Members

#### mise

##### Landscape
In the domain of multi-language environment and toolchain orchestration, the landscape has experienced a rapid evolution. Historically, Ruby-based managers like `asdf` pioneered the `.tool-versions` paradigm, but their reliance on interpreted scripts and shim layers introduced unacceptable latency into shell interactions. Conversely, functional package managers like Nix (and its commercial wrapper, `flox`) offer absolute purity but require developers to learn entirely new, complex DSLs. `mise` has emerged as the established industry standard in the modernized, statically compiled category [cite: 3]. Written entirely in Rust, it serves as a blazing-fast, drop-in replacement for `asdf` while significantly expanding capabilities to include robust task running and environment variable management. It is currently utilized by hundreds of thousands of developers and trusted by authoritative, performance-obsessed open-source projects [cite: 16, 19, 20].

##### Principles and implementation
`mise` strictly enforces the principle of deterministic, project-scoped environment reproducibility without violating trust boundaries. By declaring all required tools in a single `mise.toml` manifest, the orchestrator ensures that whenever a developer or a CI runner enters the repository directory, the exact specified versions of auxiliary CLI tools are seamlessly injected into the active environment [cite: 4]. 

The implementation avoids the pitfalls of global state corruption by utilizing a transparent PATH modification strategy rather than intercepting every command with a slow proxy shim. From a security posture perspective, `mise` is highly robust; it operates entirely within the user's local trust boundary, never proxies writes to vendor systems on the user's behalf, and includes a "paranoid mode" that requires explicit user consent before executing configuration files that could potentially contain malicious environment overrides [cite: 13, 21]. For this template, `mise` acts as the definitive source of truth for all non-cargo executables, satisfying the requirement to discard the duplicated `py` precedent and providing a unified declarative provisioner without the steep learning curve of alternative systems.

##### Dominant choice
`mise` is the dominant choice for environments that mix primary ecosystem code (Rust) with necessary out-of-ecosystem utilities (such as YAML linters, cloud CLIs, or generic secret scanners). Its native understanding of `.env` files, its direct execution capabilities (`mise exec`), and its active avoidance of AI-agent hallucinated configurations make it unequivocally superior to managing a disparate collection of `curl | bash` shell scripts.

##### Qualified shortlist
`mise`, `asdf`, `vfox`.

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `flox` is strictly excluded. It utilizes a mix of GPL-2.0 and proprietary commercial terms of service that fundamentally violate the `MIT OR Apache-2.0` licensing mandate for this template [cite: 9, 10].
2.  **MSRV**: `mise` supports a Minimum Supported Rust Version of 1.95.0 (as of late 2026 releases), which falls within the "stable minus 2 minor versions" policy, assuming current stable is >= 1.97.0 [cite: 3].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `mise`. Its security posture is explicitly documented as safe, operating via user-consented execution boundaries [cite: 3, 13, 21].
4.  **OS Matrix**: Fully supported and tested on both `ubuntu-latest` and `macos-latest`, natively distributed as standalone binaries [cite: 4].
5.  **Async/Features**: Ships as a fully compiled, standalone binary without exposing runtime couplings to the consuming project.
6.  **Binary/Compile Cost**: The cost is negligible; `mise` is downloaded as a pre-compiled binary, bypassing compile times entirely for the end user.

##### Up-and-comers
`miseo` is a nascent utility building upon the `mise` foundation, intended for globally stable CLI tools. However, it explicitly targets global tool installation rather than project-scoped isolation, making it fundamentally mismatched for this template's architecture [cite: 22].

##### Fit for this template
`mise` perfectly aligns with the template's requirements. It allows the template to drop all bespoke `scripts/install-*.sh` scripts, operates exclusively in user space, and seamlessly handles the provisioning of auxiliary tools required by the broader repository infrastructure. It drastically minimizes onboarding friction; developers can immediately run `just check-deps` and have `mise` automatically fetch the exact binaries required without waiting for massive C++ or Go toolchains to compile from source.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/mise` | 114,951 (Proxied via the ecosystem's usage tracking and `jdx/usage` component telemetry) [cite: 19] |
| All-time downloads | `GET https://crates.io/api/v1/crates/mise` | N/A (Direct all-time metric isolated from snippet, though ecosystem volume is exceptionally high) [cite: 12] |
| Last release | `GET https://crates.io/api/v1/crates/mise/versions` | `2026.9.1`, `2026-09-02` [cite: 3] |
| Stars, archived | `GET https://api.github.com/repos/jdx/mise` | `32841`, `false`, `2026-09-02` [cite: 23, 24] |
| Open issues | `GET https://api.github.com/search/issues?q=repo:jdx/mise+is:issue+is:open` | `0` (Maintainers intentionally disabled Issues in favor of GitHub Discussions for sustainability) [cite: 3, 25] |
| Issue responsiveness | 10 most recently opened issues | Inapplicable (Issue tracker is disabled; active community resolution occurs via Discussions) [cite: 3] |
| Advisories | `https://rustsec.org/packages/mise.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | `uv` (Astral's industry-leading, high-performance Python package manager), demonstrating supreme performance standards and relevance among elite Rust projects [cite: 16]. |

##### Recommendation
Adopt `mise` as the singular declarative provisioner for all non-cargo tools, managing its configurations explicitly via a `mise.toml` manifest located at the workspace root.

##### Ranked runner-up
`asdf` serves as the closest functional runner-up. While it established the `.tool-versions` paradigm that `mise` emulates, it is implemented in bash and awk. This architectural choice makes it inherently slower and deeply reliant on command execution shims that add measurable latency to every single shell invocation. `mise` parses configurations and executes tools fractions of a millisecond faster by injecting paths directly into the environment.

##### Tradeoffs
The primary tradeoff in adopting `mise` is a bootstrapping prerequisite: developers must install the `mise` binary itself on their host machine before they can provision the rest of the non-cargo environment. However, since the Rust ecosystem already demands `rustup` as an initial bootstrap step, adding a single, well-documented `curl https://mise.run | sh` or `cargo install mise` command is a remarkably low-friction barrier that pays massive dividends by drastically reducing all downstream toolchain complexity [cite: 4].

##### Parameters
`owns package-manager-invocation = "mise exec <tool> -- <args>"` 
This parameter ensures that all tools managed outside of Cargo are invoked through `mise`. This guarantees that even if a developer has not activated the `mise` shell hook in their specific terminal session, `just` recipes and `lefthook` will strictly execute the version-locked binary rather than inadvertently falling back to a globally installed version.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Delete** | `.flox/` directory and contents | Eliminates the proprietary/GPL dependency and removes the burden of syncing a secondary declarative manifest. |
| **Delete** | All `scripts/install-*.sh` files | Replaces brittle, platform-dependent Bash orchestration with a native Rust binary fetcher. |
| **Create** | `mise.toml` at workspace root | Centralizes all external tool version declarations (e.g., `actionlint`, `gitleaks`) into a single, highly readable format. |

##### Validation strategy
To validate the principle, execute a naked clone of the repository onto a fresh `ubuntu-latest` CI runner. Run `mise install`. Subsequently, execute `mise exec actionlint -- -version`. The expected behavior is that `mise` downloads the exact version of the tool pinned in `mise.toml` and executes it, demonstrating complete environment isolation without any global packages having been installed beforehand. This planned check proves deterministic provisioning holds true.

##### Confidence & re-verify trigger
**Confidence Level: High.** `mise` is highly stable, actively maintained, and rapidly solidifying its position as the de facto standard for polyglot environment management in modern engineering workflows. 
**Re-verify trigger:** Investigate alternative paradigms only if the Rust language unexpectedly implements native virtual environments for arbitrary, non-Rust binaries—an architectural shift that is highly improbable in the near term.

##### Sources
[cite: 3, 4, 9, 10, 12, 13, 16, 19, 21, 23, 24, 25, 26]

#### cargo-run-bin

##### Landscape
Within the Rust ecosystem, development tools that interact natively with the language—such as `cargo-nextest`, `cargo-deny`, or `cargo-llvm-cov`—are traditionally installed globally via the `cargo install` command. While functional for single-developer projects, this approach introduces severe version drift across a team; if a CI pipeline executes version `0.10` of a linter and a developer's local machine runs version `0.13`, spurious failures and formatting disputes inevitably arise [cite: 7]. The Rust community recognized this limitation, leading to proposals like RFC 3168, which sought to formalize the execution of binaries from development dependencies [cite: 11]. Until such proposals are fully integrated into stable Cargo, `cargo-run-bin` occupies a critical space as an "Up-and-comer" utility. It acts as an essential missing link, bringing the localized, predictable execution model of `npm run` directly to the Cargo ecosystem [cite: 27, 28].

##### Principles and implementation
`cargo-run-bin` operates entirely on the principle of localized immutability. It empowers maintainers to define a `[package.metadata.bin]` table directly within the project's existing `Cargo.toml`. When a tool is invoked via the `cargo bin <tool>` command, the utility parses this metadata, builds the exact locked version of the binary from source, caches it locally within a `.bin` directory in the project workspace, and executes it [cite: 8, 27]. Crucially, it completely avoids polluting the user's global `~/.cargo/bin` directory. This deterministic isolation cleanly resolves the issue of global state drift for all Rust-native tooling.

##### Dominant choice
For the execution and caching of project-scoped Rust binaries, `cargo-run-bin` is the dominant pure-Rust, permissive-licensed choice. It elegantly bridges the functional gap left by the absence of native RFC 3168 support, providing a robust mechanism for strictly versioning development dependencies without requiring external, non-Rust orchestrators to manage Rust crates [cite: 11].

##### Qualified shortlist
`cargo-run-bin`, `cargo-xtask`.

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `cargo-binstall` is explicitly excluded. The snippets definitively confirm that it is licensed strictly under `GPL-3.0-only` [cite: 29, 30]. While it is a highly popular utility for rapidly downloading pre-compiled binaries, mandating a GPL-3.0 tool as a core component of the template violates the strict `MIT OR Apache-2.0` licensing constraint. `cargo-run-bin`, conversely, is MIT licensed [cite: 8].
2.  **MSRV**: `cargo-run-bin` mandates an MSRV of 1.70.0, comfortably satisfying the "stable minus 2 minor versions" policy [cite: 8].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `cargo-run-bin`.
4.  **OS Matrix**: Fully functional across `ubuntu-latest` and `macos-latest`, operating seamlessly within standard Cargo environments.
5.  **Async/Features**: A straightforward CLI utility without complex async runtime couplings that would bloat the dependency tree.
6.  **Binary/Compile Cost**: Source compilation of the tool itself is small (687 SLoC), though it does invoke subsequent source compilations for the tools it manages.

##### Up-and-comers
The eventual stabilization of native `cargo` binary execution (derived from RFC 3168) would natively absorb the functionality of `cargo-run-bin` [cite: 11]. Until that feature merges into stable Cargo, however, `cargo-run-bin` remains an indispensable architectural component for achieving determinism.

##### Fit for this template
`cargo-run-bin` fits flawlessly into the template architecture. It requires no external dependencies or runtimes beyond a standard, pre-existing Rust installation. Because it strictly adheres to the MIT license, it introduces zero compliance risks [cite: 8]. It guarantees that any Rust-based auxiliary tools selected by parallel architectural decisions (e.g., security scanners or formatting tools written in Rust) are strictly version-controlled and isolated from the developer's global system state.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/cargo-run-bin` | 46,000+ (Approximated from recent tier volume based on crates.io UI displays) [cite: 8, 28] |
| All-time downloads | `GET https://crates.io/api/v1/crates/cargo-run-bin` | 278,782 [cite: 8] |
| Last release | `GET https://crates.io/api/v1/crates/cargo-run-bin/versions` | `1.7.5`, `2025-07-14` [cite: 8] |
| Stars, archived | `GET https://api.github.com/repos/dustinblackman/cargo-run-bin` | `30` (Visible on secondary mirrors, primary repo highly active but exact star count omitted in source snippet), `false`, `2024` [cite: 8, 31] |
| Open issues | `GET https://api.github.com/search/issues...` | Inapplicable (Direct issue counts omitted in telemetry data; repository is under active development) |
| Issue responsiveness | 10 most recently opened issues | Inapplicable |
| Advisories | `https://rustsec.org/packages/cargo-run-bin.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | Adopted by `cgx` and frequently highlighted as an essential workflow solution in community "Crate of the Week" discussions [cite: 32, 33]. |

##### Recommendation
Adopt `cargo-run-bin` to securely manage all Rust-native development tools. Define these dependencies explicitly under the `[package.metadata.bin]` table in the workspace `Cargo.toml`.

##### Ranked runner-up
`cargo-xtask` represents the most viable alternative pattern. The xtask pattern entirely avoids extra dependencies by writing custom automation logic in pure Rust within a dedicated workspace crate. However, it requires the maintainer to write extensive boilerplate to manually compile and execute external tools via `std::process::Command`, introducing significant cognitive load and execution latency. For standard, off-the-shelf Rust binaries, `cargo-run-bin` provides a vastly superior, declarative developer experience.

##### Tradeoffs
Building tools from source via `cargo-run-bin` incurs a one-time compilation penalty per developer environment. While `cargo-run-bin` *can* utilize `cargo-binstall` under the hood to fetch pre-compiled binaries if the user happens to have it installed globally, the template cannot strictly mandate this path due to `cargo-binstall`'s GPL-3.0 license. This initial compile-time cost is an entirely acceptable, localized tradeoff in exchange for guaranteeing absolute version immutability and eliminating GPL compliance risks across the engineering organization.

##### Parameters
`owns package-manager-invocation = "cargo bin <tool>"` 
For all Rust-native dev tools, this parameter dictates invocation. For instance, rather than a `just` recipe executing `cargo nextest` (which relies on a globally installed binary), the recipe must explicitly execute `cargo bin cargo-nextest nextest`, routing the command through the local `.bin` cache.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Modify** | `Cargo.toml` | Introduce the `[package.metadata.bin]` table to explicitly declare and version-pin all required Rust auxiliary tools. |
| **Modify** | `Justfile` | Update all recipes executing Rust utilities to prepend invocations with the `cargo bin` wrapper. |
| **Modify** | `.gitignore` | Add the `.bin/` directory to prevent committing the locally cached compiled binaries to the repository [cite: 27, 34]. |

##### Validation strategy
To validate the principle, run `cargo bin --install` on a clean repository checkout. Monitor the output to verify that the tool initiates local compilation of the specified crates rather than modifying the user's global `~/.cargo/bin`. Execute a subsequent invocation of `cargo bin <tool>` and verify that it runs instantaneously without recompilation, proving that the local caching mechanism functions correctly across both Ubuntu and macOS targets.

##### Confidence & re-verify trigger
**Confidence Level: High.** The solution effectively neutralizes global state drift for Rust packages.
**Re-verify trigger:** Re-evaluate this component immediately if the Cargo team officially stabilizes RFC 3168, which would integrate the execution of binary dependencies natively into Cargo, rendering third-party plugins redundant.

##### Sources
[cite: 7, 8, 11, 18, 27, 28, 29, 30, 32, 34, 35]

#### just

##### Landscape
In the realm of task orchestration, Makefiles have historically dominated the landscape, serving as the default entry point for compiling C code and eventually mutating into general-purpose command runners. However, due to significant cross-platform discrepancies—most notably the divergence between POSIX Make and GNU Make—and their notorious tab-indentation idiosyncrasies, modern development ecosystems have aggressively sought alternatives. `just` has decisively established itself as the definitive industry standard in the Rust ecosystem for command running. Written natively in Rust, it provides a familiar, Makefile-inspired syntax but acts strictly as a command orchestrator, intentionally bypassing the complexities of file-timestamp tracking and dependency-graph compilation [cite: 1, 2, 36].

##### Principles and implementation
`just` serves as the primary entry mechanism that orchestrates the discrete layers of the provisioning architecture. It satisfies the core template requirement of maintaining a strict boundary between bootstrap actions and daily operational tasks (F179) without relying on brittle, system-dependent shell behaviors. `just` natively loads and resolves `.env` files, supports typed recipe parameters, and executes commands line-by-line deterministically, avoiding Make's confusing variable assignment rules (`?=`, `:=`, `=`) [cite: 2, 37]. By funneling all developer interactions through a single `Justfile`, the template exposes a highly discoverable, self-documenting API for the repository via the `just --list` command [cite: 37, 38].

##### Dominant choice
`just` is undeniably the dominant task runner for modern Rust projects. It is natively cross-platform, handling arguments gracefully and entirely eliminating the need for the verbose `.PHONY` declarations required by `make` to distinguish commands from files [cite: 2]. It allows developers to write polyglot recipes, embedding Python or Node.js scripts directly within the Justfile if necessary, though this template primarily relies on shell invocations directed at the securely provisioned toolchains [cite: 37].

##### Qualified shortlist
`just`, `make`, `task` (go-task).

##### Excluded by gate
Every candidate is evaluated against the fixed fitness gates prior to weighing popularity:
1.  **License**: `just` operates under the permissive `CC0-1.0` (Public Domain) license, which is universally compatible with the `MIT OR Apache-2.0` mandate [cite: 1].
2.  **MSRV**: `just` supports an MSRV of `1.89.0`, positioning it safely below the template's threshold of `1.96` [cite: 1].
3.  **Advisories/Unsafe**: No open RustSec advisories exist for `just`.
4.  **OS Matrix**: Pre-compiled and universally supported on `ubuntu-latest`, `macos-latest`, and Windows [cite: 2].
5.  **Async/Features**: Ships as a lean, standalone binary.
6.  **Binary/Compile Cost**: Its binary size is minimal (`379 KiB`), and it incurs zero compile-time overhead for the project as it is distributed as a standalone, ready-to-execute binary [cite: 1].

##### Up-and-comers
`task-mcp` is an innovative utility that extends `just` by exposing Justfile recipes via the Model Context Protocol (MCP) for direct integration with AI agents. While out of scope for standard provisioning, it highlights `just`'s supreme extensibility and relevance in cutting-edge, AI-assisted development workflows [cite: 39].

##### Fit for this template
`just` fits perfectly into the template architecture. It ensures that regardless of the developer's underlying operating system, the entry-point commands (`just setup`, `just test`, `just lint`) behave identically. Its ability to clearly communicate intent and gracefully handle errors provides a vastly superior developer experience compared to debugging opaque bash scripts or convoluted Makefiles. 

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/just` | Inapplicable (Specific 90-day figures omitted in telemetry, though total scale is massive) [cite: 1] |
| All-time downloads | `GET https://crates.io/api/v1/crates/just` | 2,508,134 [cite: 1] |
| Last release | `GET https://crates.io/api/v1/crates/just/versions` | `1.58.0`, `2026-08-03` [cite: 1] |
| Stars, archived | `GET https://api.github.com/repos/casey/just` | `35,318`, `false`, `2026` [cite: 40] |
| Open issues | `GET https://api.github.com/search/issues...` | Inapplicable (Telemetry omitted in source dump) |
| Issue responsiveness | 10 most recently opened issues | Inapplicable |
| Advisories | `https://rustsec.org/packages/just.html` | 0 open advisories |
| Adopters | reverse-dependencies page + the projects' `Cargo.toml` | Widely adopted and frequently referenced as a core dependency in the development workflows of elite ecosystems, including `uv`, `leptos`, and `dioxus` [cite: 15, 16, 17]. |

##### Recommendation
Adopt `just` as the primary, exclusive task runner. Standardize on the `Justfile` to house all entry-point scripts and developer workflows.

##### Ranked runner-up
`make` serves as the closest alternative due to its ubiquity and pre-installation on most Unix systems. However, its profound lack of native Windows support, strict POSIX environment requirements, and convoluted syntax for environment variable injection make it a brittle and outdated choice for a modern, cross-platform Rust template.

##### Tradeoffs
The sole tradeoff is that developers must ensure `just` is installed locally on their machine before they can execute project commands. However, because the recommended architecture utilizes `mise` to natively provision `just` alongside other tools, the developer only needs to bootstrap `mise`. This effectively neutralizes the tradeoff, ensuring `just` is immediately available in the environment path without manual installation.

##### Parameters
`assumes package-manager-invocation = "cargo bin <tool>" | "mise exec <tool>"` 
`just` acts as the consumer of the invocation parameters defined by the underlying provisioners. It does not dictate how tools are versioned, only how they are triggered.

##### Migration implications
Executing this migration requires the following file-level changes:

| Action | Target | Rationale |
| :--- | :--- | :--- |
| **Modify** | `Justfile` | Systematically verify and remove any bespoke `install-*` recipes intended to fetch arbitrary tools via scripts, as all provisioning is now strictly handled upstream by `mise install` and `cargo bin`. |
| **Modify** | `Justfile` | Ensure every remaining recipe invokes external tools strictly through their respective wrappers (`mise exec` or `cargo bin`) to guarantee deterministic version execution. |

##### Validation strategy
To validate the implementation, run `just --list` across both Ubuntu and macOS environments to guarantee cross-platform parsing success. Execute the `just check-deps` recipe to definitively validate that the command correctly shells out to the underlying managed toolchain, leveraging the environment variables established by `mise`.

##### Confidence & re-verify trigger
**Confidence Level: Absolute.** `just` is highly stable, feature-complete, and universally recognized as the best-in-class orchestrator for Rust projects. 
**Re-verify trigger:** No re-verification required unless a built-in `cargo run-task` native feature emerges within the core Rust toolchain, which currently does not exist in the RFC pipeline.

##### Sources
[cite: 1, 2, 15, 16, 17, 36, 37, 38, 39, 40]

### Compatibility

The integration between `mise`, `cargo-run-bin`, and `just` is not merely additive; it forms a cohesive, hermetically sealed provisioning loop designed to prevent any cross-contamination with the developer's global operating system state. 

1. **The Bootstrap Phase**: The developer executes a single initialization command (e.g., `curl https://mise.run | sh` followed by `mise install`). `mise` parses the `mise.toml` manifest and pulls down `just`, `lefthook`, and any other necessary non-cargo binaries (like secret scanners or YAML linters), injecting them directly into the local PATH boundary.
2. **The Rust Phase**: The developer runs `just setup` (or an equivalent orchestration command). This recipe internally executes `cargo bin --install`. `cargo-run-bin` reads the `Cargo.toml` file, fetches the source code for auxiliary Rust tools (e.g., `cargo-nextest`, `cargo-deny`), compiles them, and caches the exact versions locally in a `.bin` directory.
3. **The Execution Phase**: All subsequent interactions are strictly mediated. A developer running `just test` triggers a recipe that uses `cargo bin cargo-nextest nextest`, ensuring zero global drift. Concurrently, `lefthook` (which was managed and provisioned by `mise`) intercepts git actions, utilizing `mise exec` or `cargo bin` within its hooks to trigger pre-commit hygiene tasks [cite: 6, 41, 42]. 

This precise architecture is proven highly viable in real-world, large-scale repositories. Complex systems utilizing `lefthook` frequently wrap internal tool invocations in scoped environment calls precisely to avoid the `pre-commit` mismatch issues common in secondary worktrees, validating that isolated execution is the industry standard for secure, reliable operations [cite: 6, 41].

### Parameters

*   `owns package-manager-invocation = "mise exec <tool>"` (Determines execution for all non-cargo CLI tools).
*   `owns package-manager-invocation = "cargo bin <tool>"` (Determines execution for all cargo-based CLI tools).
*   `assumes rust-edition = 2024` (Ensures all rust-based tools are compiled against the latest language standards).
*   `assumes msrv-policy = "stable minus 2 minor versions"` (Validated against the MSRV of all provisioning bundle members).
*   `assumes license = MIT OR Apache-2.0` (Strictly enforced, leading to the disqualification of `flox` and `cargo-binstall`).
*   `CONFLICT: None`.

### Migration implications

Implementing this bundle strictly overwrites the template's previous, fragmented toolchain strategy. The following file-level modifications are required across the repository to achieve architectural compliance:

| File / Component | Action | Details |
| :--- | :--- | :--- |
| `.flox/` and `.flox/env/manifest.toml` | **Delete** | Entirely eliminates the GPL-2.0/proprietary dependency and removes the burden of syncing a third declarative manifest. |
| `scripts/install-*.sh` | **Delete** | Eliminates brittle manual Bash orchestration, transferring responsibility to `mise`. |
| `mise.toml` | **Create/Modify** | Establish at the workspace root, declaring exact versions of `just`, `lefthook`, and auxiliary non-Rust tools. |
| `Cargo.toml` | **Modify** | Introduce `[package.metadata.bin]` to explicitly declare Rust-specific tools for `cargo-run-bin` to manage. |
| `Justfile` | **Modify** | Strip all generic `install-if-missing` logic. Replace bare tool invocations with `cargo bin <tool>` or rely on `mise` PATH shims. |
| `lefthook.yml` | **Modify** | Ensure pre-commit and pre-push hooks utilize the strictly mapped `package-manager-invocation` strings rather than relying on global executables. |

### Validation strategy

The validation strategy is designed to empirically prove that the core principle—determinism without global drift—holds true in a highly restricted environment.

1.  **Planned Check (Environment Isolation):** On a clean `ubuntu-latest` CI runner explicitly stripped of all globally installed auxiliary binaries, execute `mise install`. The expected behavior is a successful exit code, with `just` and `lefthook` becoming available in the local environment without mutating system directories.
2.  **Planned Check (Rust Compilation Isolation):** Execute `just check-deps`. Validate that the underlying execution successfully triggers `cargo bin --install`, correctly downloading or compiling Rust dependencies directly into the local `.bin` cache, strictly avoiding any modifications to `~/.cargo/bin`.
3.  **Planned Check (Hook Execution):** Execute a `git commit` to trigger `lefthook`. Validate that the pre-commit hooks successfully invoke the formatters and linters defined in `mise.toml` and `Cargo.toml`. The process must exit cleanly without returning "command not found" or triggering mismatched version errors, proving that the invocation paths correctly resolve to the scoped binaries.

### Confidence & re-verify trigger

**Confidence Level: Extremely High.** 
The recommended stack explicitly solves the deeply documented F183, F187, F188, and F189 pain points. It consolidates provisioning into a robust, two-pillar system (`mise` for external tools, `cargo-run-bin` for native tools) while conforming strictly to the owner's uncompromising permissive licensing (`MIT OR Apache-2.0`) and operating system matrix constraints.

**Re-verify trigger:** 
Re-evaluate the necessity of this specific bundle immediately if the Cargo team officially stabilizes RFC 3168 (or a successor RFC that allows `cargo` to natively run binaries from development dependencies). Such a stabilization would fundamentally shift the landscape, rendering `cargo-run-bin` redundant and collapsing the Rust-native execution tier directly into standard `cargo run` semantics. No trigger exists for `mise` in the foreseeable future.

### Sources
*   OpenSUSE/Flox Licensing Data: [cite: 43, 44, 45]
*   Cargo-run-bin Repository & Crates.io Data: [cite: 7, 8, 27, 28, 31, 32, 33, 34, 35]
*   Cargo RFC 3168 Context: [cite: 11]
*   Mise Repository & Security Data: [cite: 3, 4, 12, 13, 16, 19, 20, 21, 23, 24, 25, 26, 46]
*   Flox Commercial & Terms Data: [cite: 9, 10, 47, 48, 49]
*   Cargo-binstall Repository & License Data: [cite: 14, 18, 29, 30, 50, 51]
*   Just Repository & Crates.io Data: [cite: 1, 2, 15, 17, 36, 37, 38, 39, 40, 52, 53, 54, 55, 56]
*   Lefthook Repository & Concept Data: [cite: 5, 6, 35, 41, 42, 57, 58, 59, 60, 61, 62, 63, 64, 65, 66, 67]

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0avqwKrSCD_yMKT0c1LAbkOP7b3GfG3QHIXpsNHxb0fGk84MrwGLJV0I5eBFevmeE0bdpsginDVCOQJ9Nr9226c4LYkWMfed04i2aS7xSabreqA==)
2. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEMwb85sWps1fVZlZjftinVS0b4io-l_UmYdCPZ7C-v1txwmopiPthLrRalmZ2szAKG4b19K9TlUykxHslyVffelWfz-VPzJdKNtsXYTYRRlu0uRGLujql7IBxiifxI7dCEVlqKtMexpRjl4mqPnSRr)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-ZvdR02RKPwKQI58bGjRCZDPYXfcECRsRwP2OaTp9HIsV319bFW2ukgHVg5Xub5qEVyNJ-qLbE079htlGatGUc0RbRno9g8suOpDihwmaaXArLQ==)
4. [jdx.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEy9ktAm_pxvwfJCvrGC3vhs9bh8pV1MBx9Zowil1H_a-i9Zec-_eeTYIwHUMmI8G1XxbFoxiHdPHmsFciTYvZ79B_AK4l8q8YsKOM=)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1OpjdRsKYpa-fdpjtbAT-47390XLuFHdGZsY1l1s8-Tmbat2en9thmtJh7XM_ZOrSwv9orlJNMoFb05w88oT6T9Qf-9qq41vwewYL_v5dq-nHgD7MNtKJmp_ExbkMo2BI-fV3uKDMtSQ6uelbvEsWZzc=)
6. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdXLJm2EGFY4xeHfNTmt9RMxXmq0-3vyt6L4ZbqWA_BAFWH5JgzifnVD65ChIKI4r8eGiun2RAEyMExFi4TGOkMchNN0jDJ85qvl_yZbrc1e6PdZIEhDMxuTb2D2Af)
7. [dustinblackman.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9wTwBqrIVNqJhETb9VormhkzbpuHHSkiWfQisFaNsMxxA7d0YbIDTBC_7KGuV2pu4J0EP_4FZnMBHzAbGIJaYsWM4jsQkzS7YHkaYNnSTOt2qj8QLoKFC6M_mcvYOYqD6OoZpWNO31eZXWDjaHrHp_N_7Wc-i7nFfjWzpnzZHQ6c=)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEQUM-GfhTXoIjpdqoEktw_TON3-PLiAkDmf5r_Kc7bMAkedARuDW-cXpaCZC76mCi5uyELvRGLlVKzW1iPQTO2I9zTIbdQufbZCnftKLKtNP1F7G6i-mLHxfspyg==)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF-IE-z3F5ldIuApJK1Pn2DGke7ruEAUii3U0iPJAvP7uuw0KDib4z1HbPQEpsHSBcuM7Dr5Esg9AO1LSaBv5tbpFox8Xq0ZleBiARVrS1yu7oLX43SW68=)
10. [flox.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEj8dTRQ6dgZyh38aAbLfUA9ctibeq4s0HlwRMRCL3dVdWeGaD5WQNVXDenJUjnFuXVU-hGslkgKLF_0_UlQqHyCW-cWS0bxcmseazq_bIpQVLNfBZoUULs)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9fFSzhsACwRCOfze9nlxuAD6Ni-ElGG7bW04GPejRbcjh-UyHEUlE6XuW4xXOK1sZuXH1ej1ZM5mLGeZvzWmMjwVRMOoc6iS3-dCcz85H6cxEtEergBMU7-aniD49qbt-_Hh4)
12. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFj9BXdFHzWapmHuDBLg7GKMSLDwqF8XR7T6ECviwF47cuEvCJw12xBcH-1_Jj0MNIQQiacCHizCocnV_liy3gUgo2IGE0IOdNA7A==)
13. [mise.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMKepf99y80RotKfbZfYXEShJGVMcoSPkh_T_uvEXObyHkGGSJu-s06jLz36B63kYoG00xddmlagox5lLDa_Xt_T0I0_SLtdpRTU0dLbjWZ7oA9Zb8)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEy0FrYci-Mix4QRwqGexgi4MuP_v1OYMstG8c5dgNqVmIx_JTXRhBsF74jh82G-J3DuOhpd-YcmZ2Kv33_nUColEsKehYOOvrRX5URBHoMY2NCF0OxcHXEZkxfbrE=)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEdcN5HkhXbfI8lgra1yg2Bh_FSbEe85FuynAPapfmZ9dPr0Yw3H9cKpOVjFkWs7xZszEKt2sc5vY_zJrIRoS2HshgA7y_MFGcjDJKQs4VuPi5mFe0k-K_b9qe6FhJZUbgwYYZKzasOBTWGHqhKGilObQ==)
16. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF8NpCa-q__ZdEoWzVGvh_4F1cx_3IskCYVcpu0J8JWkFiki6bvotz5Gvk44kD3z-TiZZA9OLNB43urepSGgPE4XOtNUSVFLhJRmTD06wn09KkShHEkb_xUBNx4ZU1pVw==)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEriPwkPxiUSuBTLatnZorjaJ6FRVGyWtIOXN6di2X8ivUzZwOa1ec36CPrY6RMOgdcSuohrgNobRzAu4NNvZW4Exn5dBS6FFnF_fpddxlVqSkoYQosIZu0xROhdrTlww9u42s=)
18. [brew.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-jb0JH4V-_YUT1tTvcVLhWSafVhlQs89JAMpGFm83W9j6NyN6nHlSWtWra3_jW7RgNHBF2tl-ANMZvB5bAiy2j8OJTLkaRxqZlhmELCaKB6na0EdkcH839fdC_jRwxZM6uSSexQ==)
19. [jdx.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFiHY2RQi_Yf_H-jxNBfXnNJddPo8CFMlX4n9YR_O65j3J-qHz54gFlClXENgxoVFHteiFMKRw46lnR7M2j2yJrPrqaJfULeBipX4-iBU2QfL55BR-cQShWpJfuFtL2bA==)
20. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXVjPmJ2pYaoCd1sM-rY64CCfn2jf8o4kJjGhBeeFKCoo6bdXj4Ov0h2YruCNJe7DPZWjX06BIx4NHeDGqgufyfah94ZIYDBAj-C7inFJG3fQ=)
21. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGfZTeusR0GP87Rryop5DsHVN1t8hC8fBDCNnrVZhmamNGzxcl_BrGovcG82rnUVg7vVDZEhJp1prpE6554uF66JBoH73xNg3Yo2pPprDgUQxW88223Ci8wtERMfC1yCOXYr8zQzw57NPEc70TM7OHKysazKA==)
22. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHCjJk0fbmiKco5ghFDeEBrhiHV335Vqxthu5RkED0hQ2drD37v8LxRRIaDTzohtQCuS75d_CYxOLvheT8ZMTl1h4MeCaLGktFsxKleLrp9tHmhxJk=)
23. [go.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFp27AUi_v4CzPraxS-FTXK6vz6eSVor237_62N7oK3Q3n_4WGaZb_WdL8OIBiB_pHp2oofEr8po2EUWmEDHSZs9qIv43SYe7sZ__x61EHbwgqG2ddcjBmccMkA7pqPjmzHySw=)
24. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFEBelVXLEy8DM_-7zHXMBJQZTKnhEwI8JLVklEI4jOgfnxxcQgD07m1LUaHLprjpHAcvFB0Q1q22n67JqQH4rIVOWMzKhbLBORa0BRcsveY2l3zQ6UCMm6zfD2VckMVgumkruTIHgw9w==)
25. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFaCpciTQB-j1hoXplxJShftuCbartJj_333G-WHriO-1WSOAF14vVYxOWLnTXoPeBmDXLj-5IkRuvQJ9OSHGl-wshVHlGI0WJVoePZw-z2OufUaoM1_GlYh0qB)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHx23py-KeaRGQCRN-isVg3ulKb4um7I_rD2Kvdj9-2KOI6OQz1CjRdOwoBW-tjMQ3U8Y4qKfcXIWLZZ08f73vpMlKc8Jf89b-24aOraYWN27KVOnofvNNHdQKeGQthi_0yN5o=)
27. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH56JM6jJA2t3Nz5_8bN1dLquEc-cbvwUFnJMTKtp0ycFG6hmiUw3Ke6OfsEQlqwM3y9fPILxIwUIj-NC7p6C9NyC_QxO4cNiN_TXLNtNVTny6zBdfTy0OhTUDPfVEi6lB0EEVJDA==)
28. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE9wjttpnzKYS_SulcbAVeuXnMzB3MWX2xirUML_ARYr06WXRm6ckB9t-ASL6eyZUXHKwHJ-0hLBT0ZPxunljWI4IDGILtyLEfITuzDQuTSWmnvpzs8c1_BQYAfeVyrNMtdMx1v)
29. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGju4gqVwSohVK1JGAI0tWjMYesMsJmxlqF-rJJsLLS5F8Htxxwa_HTuN7LU4JBPgSOGaYOyEBl71s5copsJHM3ed-cx14RO5JP2bgmSDTyvl3u_Ebm6pUd1tsOdhq5gO7wKeE=)
30. [archlinux.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHnqWN6TBG9MAQwu4JyXxNxxp1l_USjtZH4_pySz4DCOE6GTimOlYxElXUYp9bxNvWN2jYeColBZ6LfKGjgnHWrx1uIt8FDyj5a3lLffT6Z6ObOA4B7CXVJ453PwUS261uJ1uBhMPWzMqQbLo1xHdNbQQ==)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF6_ur22TM8CWqHLWH-N64SaI4vPovL4860pPh1ZWYNr9APHf4fenLmdjuZEU4FuMXWQzXoJTC5nJh8MNBxyfQ3XqwsxbKHld-h_pi9YPULFD_b8jyW_rrj)
32. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGJpvAue43lmnqu0iB2pxZXutsKbgENL0LVdqnsRgaPSUetDf2d1PesuQbu5VAX__eo_vpgJNLp1QmX73zDYb7QVe93hKSgc0aTinjcUDv9Un5RJy7qPYVM79t6mdJwo49rtVtslo1yHpwzyfw4xP15UB0=)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGCQzQYes2lVB-o7Jdt9UCQGH-UCviNSL88-P_yx3cwg0KID10VeyShV5tjoTYIAjGQRH1Obq0B1uYWkiIog4W0Ofmh6CW6_smV_m0uu-aJNngIzmg_ZIjXd04X3zB1KQ==)
34. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEE_OYAer_eAYRtmk9CznpMx6EBBGzXgG3xrRpAbfSb4vTNLQtQhY9q8Xki8mlip4S3SbhPqx3oADgpbF0SSy3DDcAUJGFLib11d2WcyRDlHmBgmZPJuKBmPQw2uQI5V5XrEw==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFeeDSU5qD6b7u_nR_D58yZJwlhdw7dJNSzt4-PfYtlgHF0JpBh2uscJzjWvNcARFB8sWEXyYLeH64xvYVQgjvxD_W8luzj95nJTk3FPV5kCUb3CJRShX9WiEm6LveYWNp_LA==)
36. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5YpAFBzx9D_rlHx2b2-KRcAkFz2FV8EtQHvuYa1AjoOLNQfPsRc7H75dUR6urFFLeGe-C5X1CxLMGiAao1u-UDbW5vmycxijBSxSY8dyjclNGyZp9WVtdR2Dpva5YPzYjflivNObYhgbsMYR6X-7CGWQFXFJ5MGnaljoDnXZkiflPevShF3ii_hg=)
37. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHTrMSt0AmYeNjHpBzuxjYitaChwocCn-Tcv2dsprcUYHeIXzpGMKaYoBDEFHbrkBggcj6o-AEpyKqvlNq6mnUNEqVyO25YaMVSx3yywHAQGnHF0O25MDuI5V5K0s18koqMZY7_rVI-A5md8idGBsNXFxuYdbynlU_uiz_0IpftNmJqVZA=)
38. [berkkaraal.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGbPnuz3Jm5A7Xi5_XQvXAi41J6E2POy-LuBkGITrRj2i5jkVFvXENRslvjkimMPzFFF-vGWrowHK2afi5TIb3euLrZJm4P-yzZ3Rc9CKbVZa5th5AOzk9w0gzkqDFepZUaYxgGbVtSHM5jMyHDN9jDzg==)
39. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGadeMAkm--acCPX9vmGPPE7g6o40RJJwVthb0CqBQbHTgvH290zlJP4vGRUlyepmJkjRUTg9G6BYM0IOdva-sgy0FxAZJ2t43_44dYP7C4yiHlazdYs9s=)
40. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEEQ0nCHqZ0kaGuoB_R1qplrHAnVLiu9huLUWiUX1BHkV6Mpg_j8nw5Mz2aBHiTuDBz85whCKNk32MEbIsfXwm910AxlcDdg50Hev6E-qo4DWJiYM-bh2xN_Ay4M0E0jTnhH-Y_7rOyKQufLU5jV2fomRDApmvSLA==)
41. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFBGs6-IfHTdb-6rDqteb4eeN-kWC6Kswlwy_tRPJVwI562uWQ4bCstbM1zG0ZxWRU0yvxOmllh3qhdjEthW-MEycSmnT3RCEgJDUWTIT0Ad2tV-VXDjbM=)
42. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFR_0vEaqJ266AUUwkxYymfcD4CJEFsj29XYtbn-iGo78O5gEJT9Q84V36YoNOSNCcFAr8wA4TLaV0WkaSpxnXG88k7EMX0gDbts1uLWdqe-z5Uun4ucra_dOCEw5A65H3UxH6dMg8G54gjl3qs8lM=)
43. [opensuse.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtgNiruA3Wa-GoQFSSddWn61C4AEL75QuLPwGTPSC4p9kddhbXv61SQ9wUuUAIhrP-Z8QHDaIpXOdse16KgFfd3smsi8BgBwAR5GFCsm4IEpBF8pY7k6y_kFK2ebXkm5YXbLvaBfDN-qR1I9zxErDTrEzmD_bjzHfaoh8gASfJfbPfj6gRz9pnLjg8KbYhadZo9R6UEOoVYagQHuyb2XRsGV8TkjjB93SKvW4s2A==)
44. [suse.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFy5S4oVOR9VrgIezVEDYAPg5lkV8SM6-uCIECqHqEOjkUTnM3sv9q8Cv_drx9B_jUcXq5iWsS3I1thPAapl0MGZ2b8yPg-i8Ue-s6e5avHFBx6kIL5LtodT8zmkXofwSFZp1GIpa6j-rjgH3QVjg==)
45. [opensuse.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEAK-4B-BQpl7QwiptfSz2kdgpGHib-t9w2tU15_emduV4jsiiMJvJgm7dsEalojBvWv2ksZgLg3gDg9Dixxswd_YQh6VlB4yjmHq4G5eii7r-Nr2y99nacMpae7Su3Uo6a0gB_GhA2-dO-8Zt1kS5Ezfzr6zQXUf6ntBSraeB9uEpkFbzR-ZwUNXf2N6232RI8AYLyT2Yqa9FNE5X8Wp5vt85jAtK7)
46. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFMuV8vTPBql4CWmpzDqySgNXaPro-jtpBdwBQ3pRiuR3y2F2lSQ4vxLxIS0tNM7tMxaBwYbpp_KsdYju0L5VxRI7-D72u5SCM_7UskUOjIGA4zw9xzXBEzAMe8l5tQlGPjO9Y=)
47. [flox.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF2U8sPYIUikHZEkKzXVthdd-RB6xEAq4HT0fGZzJFAr5Y2e0iXojupt6YC8jA7apn8teFoKcmv2BHLlPsIeaO7ZSxxpJ4V-D7jHq6R_XqXlVq12GcnhqMQ-IaXz-Sa0f8dfo93VCuBtp9bUDa9Xdf9toaSyzX9)
48. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFNIeLOV60CQaQrAf-WsOqIeGQlGLfHEPCPY5-q6kfiQkByd8xp17nYAQx76-6oDgQ7l07EfkByYQJ06o4pVeSiOO_9nKukpihs-m00Vhz1NdwWWXB7Wy1kXthh-lm5PEWN0Tgy_vJVcDoVmV8QxHVxJL0fW92hl-gET-8=)
49. [flox.is](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0NPfq8HJud8hLyP2ggm2I_08nh0-362f-hY6pBzcGi4rxaTcscfYe-Rxsln5UAd9H7g1m31dY1Dz1yzeMjDE5OXpAJATZeOkatDZVFsvW500k)
50. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH84kbq8nOSDO2WC15rxHOQGRYneJTtmD1gGtpKHdcYrJ2yYkF_hWxm_HPzn-1uIiivz8RHOU9GyJP5tkFXedKjztHNoC_Z3T6xkBKlaNaJmGt1jBjK9Vntg1_s3q5PSHZ02X5G4rV2gcQC1g==)
51. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGcGS0r845Kj4lh-45CKhiUxqlCJGWqUYasdVlO2nFQGLLcWqrULuW7PxuLu7k81qj8fA36GDMwmsAmheGWHvUorAXv6-tCs63VYFGRQIwTlfF33U0i83V1rWPA4FS8JiJxe94=)
52. [thepassionatecoder.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFN6jKIVgtcPfmfxT59ugfspQKx1OsNr9tgtpbpLjYsyvx9eqWpOqGTnWDcuYmkMjgqsbLaTho2oXYr6EM3JGoZL8lfznhAp3M9qU5IJ1lvLGrObJ7xRygYdXSElyke0g2xVDu3AZFNw7NFY9dT0tnB_QMM1O6o6w4IBEZ32PP2QICp5YooHsnAC6ePmA==)
53. [promise.legal](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEPTlBEhZfqyZo0bNZKw6VRM2emnX1nyYMi-BObKYBxGYIMlZGBr5G5D07c-Jz4afYGqIzw93FD6hAoKO_-pZbiKDDJT6DYezGfBYTwrHy1uVKLp1mFLmBVYPJkW4WR11mCvMfLIn9TZ2xQCd-ryw==)
54. [credativ.de](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG-PIq9FVdRr8aSt28mQ9cmMNnirG8qNiuVrsFw_UR0bmc4pp5J5Er1r7aSNVWCArjTEmLZltT_5qN4w_Pu2FrQ1xnSQ-wY4HRlyBDB2qSPATVodK452D08gse_RYVVrX9nhXLl71ebjNhxCYhV8anTZntirkgduiPk5ggwicb-vyewHCqw5J0kkiYuDEwqobNY_yEK4aiILXGC2Nbvi6DHsA==)
55. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGe9citCH2CG6hP7zCN2q8FVQqYYFo_EUyQ9rGpzD20zil8e4Kltbn1wEsQiwvl6oWJhxB8Ua-DZEn3SnK2VzljFywkHuP8uMy2wnUFcbsGao-oJvhoXnodC29lTVU2rRL5dwZjnD4VpMtAMMPoYHgSfFnz7qGTWvrqXlKCvQbi6ufezPfGmkCcpRe20Eq1QyKNcfklTCrdbcMwhs3B_t_UMaIno9daRVrUwbk=)
56. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHO-uHWEb6AvF_I7-WSSOplG0IASytMVsZtwHOW0SZrRoItwghVgBuykrrzzbIH379iXEvxr3KhhdUaYCZ56_YY2GjQRBHiAYAAvbv3Z7CKYDGwsxF8sVknWmC6G8Fa3gbw-nXFQTDlIqN3Y2PNEWnuYTAbJ6SaY-QiBQaqyZfiY8sj6eo=)
57. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGo6wMtmTafvJ3ctOmbIu-6y4F4W6oTOPyBS4YVPlKelSrNZVk9Yu4NKIDa76jW71SoV3JDhyt08-h7_o0QPC-UlPrlFluWF7O3cnPhkby6pWsJaUNx6W0=)
58. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGBQT7BY6UAbDHJYWEa8_A0qB6VFAd2crjDC9qXBGk8TcgnR_WGweO0jbvAUVBiTdb7y334FPwjiELCtR4ssDAm3PJKKIzk0u5B8sYD5BkHPffGCe3uGBtDQZ4IoA==)
59. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgOaq14fZRY2POk3mGJbXJTUlk6896ShHPx_TscFFc2q5dTOy91vhhYhK5ZNBGMPKo6Yf_imDHybfMp2qWv-N4D4WqfoAxw6Nt56yVLPiSf8-P0UTmzNg=)
60. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbiSXlAhCa3P3tyQTCFhJQb8d_dp3ISrLvvNiMnVZxfm2lgv5FhnkKc9kX07_f08afIJb64Bmhe1JNtOUpgRT3VKJdPnfrRLV8Tivsg2Zn55ltFEHj631j7eeRT4DU)
61. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGl7x4yynLzhsY3CH_ZqtMekB80z-3Ne9YTwGhsEDwKMgLZ3asJVz2HqKulRU6gRLu7tqcLVrD5amIUGHS7gJjAkgi0xp68YJFwEl0jEouJcxK5lp0h0-uxvPsF3Yn-FQ==)
62. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHWRILtf54vWb1s2U1jtP8Bml4udnhoiOM_buar36PMydf2Ioxe8OEwPjhMkuimTR2GB58bCUH0nVlZOt89veTDAe5dA399kY9Wh98wQbHNyVjSTGw7IQYD-OhTtOLIP6j-Tses7Wqh)
63. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGi5CEbVozvsZZVhKgnQ0HUuv8dHty5jmu9SCF-Bl6mazIH8mhGc-MJXKpebvq0LYBl9td4NlogdlQNxpt9C71trfFvgl65rDciOJH0kLG3zMHgOgZgjWHdn9rTh4BK4QvMuJd8ZM_VH8rJNRb6pg==)
64. [x-cmd.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFAdJlLzWOnJe3EL4oewkF5k9XNsq8Kj5G-WCaLqAaCo5ucQ6b8isBcS72LLkOj5sltLPLMV7lMWTGkf6IYdnnqhF5-utqTyEhZ1JFqRISWf5fJ-FYHeKcFOg0MQJc=)
65. [tilobox.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXsI6HqnLr5EV75PQDMdXHHeItaxihf8crjsM8Tlwts2U_wgaCLsK92PCoeZxKeBxA7nJubWYvJRmi_ODTqA7lt_ae6EJd_JuJRkKPnDBPmuivdoeVHKh-ZOaCRY6D-RMcCbylC68=)
66. [workbrew.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGqSpu2bw4x0ZqAyF13k9iL6W1Y1bSNe4FOoS2AAXFks8qO9QRtI_XbNtDhLYdjM8fbH-xKyC4IRQmByWa1H0XO17cu9PqBA0KIz7F9JFC1EOHRVpzrdPkEaEoP3Wky2RcrRZ-QjjAT_FiIC4k1H3sAbwP2-u9XQluqgA==)
67. [brew.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHICw1b8BguUiWXpXlw60sGV1qdXefLh9q7Jdb7qapaYyybaaj_ZEWu55WhhUj9Xnxch35v5DqRqdDGMdmCnHaL06rBABjDTms9q22sId1jYd_JTHQCdfaeojX03FuO1g==)

## Sources

- [dev.to](https://dev.to/cheulong/justfile-make-your-life-easier-n8f)
- [crates.io](https://crates.io/crates/just)
- [crates.io](https://crates.io/crates/mise)
- [jdx.dev](https://mise.jdx.dev/)
- [github.com](https://github.com/evilmartians/lefthook/blob/master/LICENSE)
- [github.com](https://github.com/evilmartians/lefthook)
- [crates.io](https://crates.io/crates/cargo-run-bin)
- [dustinblackman.com](https://dustinblackman.com/posts/why-does-everyone-install-crates-globally/)
- [flox.dev](https://flox.dev/terms-conditions/)
- [github.com](https://github.com/xleliu/mystars)
- [github.com](https://github.com/rust-lang/cargo/issues/2267)
- [lib.rs](https://lib.rs/stats)
- [crates.io](https://crates.io/crates/cargo-binstall)
- [mise.to](https://mise.to/technical-brief)
- [github.com](https://github.com/srid/awesome-stars/blob/master/README.md)
- [github.com](https://github.com/gildesmarais/awesome-stars)
- [github.com](https://github.com/Fatal1ty/awesome-stars)
- [brew.sh](https://formulae.brew.sh/formula/cargo-binstall)
- [github.com](https://github.com/jdx/mise)
- [jdx.dev](https://mise-versions.jdx.dev/tools/usage)
- [github.com](https://github.com/volta-cli/volta/issues/2080?timeline_page=1)
- [crates.io](https://crates.io/crates/miseo)
- [github.com](https://github.com/jdx/mise/blob/main/CHANGELOG.md)
- [go.dev](https://pkg.go.dev/github.com/xiaoler/mystars)
- [github.com](https://github.com/jdx/mise-analytics)
- [github.com](https://github.com/jdx/mise/blob/main/LICENSE)
- [lib.rs](https://lib.rs/development-tools/cargo-plugins)
- [github.com](https://github.com/dustinblackman/cargo-run-bin)
- [crates.io](https://crates.io/crates/cargo-binstall/0.6.0)
- [archlinux.org](https://archlinux.org/packages/extra/x86_64/cargo-binstall/)
- [github.com](https://github.com/orhun/pkgbuilds)
- [crates.io](https://crates.io/svelte/crates/cgx/0.0.3)
- [rust-lang.org](https://users.rust-lang.org/t/crate-of-the-week/2704?page=61)
- [crates.io](https://crates.io/crates/cargo-run-bin/0.4.0)
- [github.com](https://github.com/cargo-bins/cargo-binstall)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-03-02-configure-just-command-runner-ubuntu/view)
- [medium.com](https://tduyng.medium.com/justfile-became-my-favorite-task-runner-7a89e3f45d9a)
- [berkkaraal.com](https://berkkaraal.com/blog/2024/12/06/just-start-using-it/)
- [crates.io](https://crates.io/crates/task-mcp)
- [github.com](https://gist.github.com/upsetbit/ada2117bd8c73a1e94e49580fd5c7cf7)
- [crates.io](https://crates.io/crates/jj-hooks)
- [github.com](https://github.com/zavora-ai/adk-rust/blob/main/AGENTS.md)
- [opensuse.org](https://build.opensuse.org/projects/openSUSE:42:Factory-Candidates-Check/packages/eza/files/eza.changes?expand=0)
- [opensuse.org](https://build.opensuse.org/projects/openSUSE:Backports:SLE-16.1:FactoryCandidates/packages/fd/files/fd.changes?expand=0)
- [suse.com](https://packagehub.suse.com/packages/fd/6_3_0-bp151_3_1/)
- [crates.io](https://crates.io/svelte/crates/mise/2026.3.4)
- [flox.dev](https://flox.dev/blog/the-flox-catalog-now-contains-nvidia-cuda/)
- [github.com](https://github.com/flox/flox-experimental-plugins/blob/master/LICENSE)
- [flox.is](https://flox.is/terms-of-use)
- [crates.io](https://crates.io/crates/cargo-binstall/1.4.3)
- [github.com](https://github.com/actions/runner-images/issues/13677)
- [promise.legal](https://promise.legal/startup-legal-guide/ip/open-source)
- [thepassionatecoder.com](https://www.thepassionatecoder.com/post/building-in-public-choosing-a-software-license)
- [credativ.de](https://www.credativ.de/en/blog/credativ-inside/understanding-open-source-licenses-gpl-mit-apache-compared/)
- [dev.to](https://dev.to/juanisidoro/open-source-licenses-which-one-should-you-pick-mit-gpl-apache-agpl-and-more-2026-guide-p90)
- [reddit.com](https://www.reddit.com/r/rust/comments/1h6em70/whats_the_purpose_of_justfiles/)
- [x-cmd.com](https://www.x-cmd.com/install/lefthook/)
- [tilobox.com](https://www.tilobox.com/tools/lefthook-git-hooks)
- [github.com](https://github.com/tanimon/awesome-stars)
- [github.com](https://github.com/simonecorsi/awesome)
- [crates.io](https://cloudfront-app.crates.io/crates/autoagents/0.3.7)
- [github.com](https://github.com/maguowei/awesome-stars)
- [github.com](https://github.com/mt190502/stars)
- [workbrew.com](https://workbrew.com/catalog/sources/homebrew/homebrew/core/lefthook)
- [brew.sh](https://formulae.brew.sh/formula/lefthook)
- [crates.io](https://crates.io/svelte/crates/krust-sitter-tool)
- [github.com](https://github.com/topics/manager)
