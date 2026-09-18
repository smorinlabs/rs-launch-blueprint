# R11 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260918-150256-f435d220c6dd4ef7 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would fall outside the template are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**

**Reasoning Summary**
**Researching project workflows**

I think I should only rely on official documentation and source repositories for accurate information. It might be useful to survey mainstream projects like Tokio, Ripgrep, Clap, and Axum. Perhaps even check the Rust compiler and Cargo. I want to see their actual workflows. I need to search raw GitHub data. It's important for me to determine job structures and path filtering for a solid understanding of how these projects operate.

**Perplexity (sonar-deep-research)**

**CI Job Structure and Path-Filtered Changes Detection for `rs-launch-blueprint`**

The CI workflow for `rs-launch-blueprint` should adopt a **multi-job, staged GitHub Actions pipeline** that separates fast, always-on checks from heavier validation while using a **path-filtered changes-detector job** to skip expensive jobs on documentation-only or surface-isolated changes. This pattern aligns with modern Rust CI practice in well-regarded projects, uses established Actions such as `dtolnay/rust-toolchain` and `Swatinem/rust-cache` to amortize Rust’s compile cost across jobs, and employs a dedicated `changes` job based on `dorny/paths-filter`-style mechanisms so that heavy jobs like cross-OS tests, coverage, and documentation gates run only when relevant code changes are detected.[2][5][7][12][13][15][16][20] The resulting `.github/workflows/ci.yml` job graph preserves cross-repo principles of early feedback, resource-aware validation, and transparent gating, while justifiably diverging from the TypeScript template’s single-job shape in order to fit Rust’s compilation profile and multi-surface blueprint design.

**Context and Motivation**

The decision governed by R11 concerns the **architectural topology** of CI for `rs-launch-blueprint`, not the specific tools invoked inside individual checks. The template is shaped as a tri-surface Rust project: a command-line interface, a reusable library crate, and an optional web service/API surface governed by R69.[5] Within this context, the owner has already fixed important parameters, including the use of Rust 2024 edition, an MSRV policy of “stable minus two minor versions” with `rust-version` declared in `Cargo.toml` and tested in CI, a dual-OS target matrix of `ubuntu-latest` and `macos-latest`, and licensing under `MIT OR Apache-2.0`. These parameters determine constraints on tooling and job structure but do not themselves answer whether checks are split into jobs or steps, or how changes detection should prune heavy work.

The Python and TypeScript blueprints provide contrasting precedent that must be treated as **evidence rather than binding templates**. The Python CI splits checks across several jobs and even across workflows: a dedicated `lint.yml` hosts multiple linting jobs gated by a `lint-changes` job that path-filters which linters run, while `ci.yml` includes a `changes` job (F040) that gates heavier jobs such as typechecking, import-boundary enforcement, tests, and build-smoke on whether documentation-only changes were made.[docs context] In contrast, the TypeScript CI collapses oxlint, formatting, and `tsc` typechecking into steps inside a single `ci` job with no changes-detector and no path-filtered skip-gating.[docs context] This divergence was recorded as DIVERGENT in the ledger, but without an explicit design record explaining why job splitting and skip-gating were adopted for Python and omitted for TypeScript. R11 must therefore revisit the underlying principles and decide how Rust should apply them.

Rust’s **compile-time profile** and ecosystem conventions are materially different from Python and TypeScript. A single `cargo test` or `cargo clippy` run typically performs substantial work, including compiling the crate graph and running tests or lints, which can dominate CI run time even for medium-sized projects.[2][5] The Rust ecosystem also commonly uses Actions such as `dtolnay/rust-toolchain` to select specific toolchains and `Swatinem/rust-cache` to cache `~/.cargo` and `target` directories between jobs, thereby trading off repetition of setup against parallelism and clarity.[12][13][14][20] These differences imply that job topology and skip-gating mechanisms may need to diverge from TypeScript’s simplicity while remaining compatible with the shared principles governing all blueprints.

R11 interacts with several related items. R02 decides whether an architectural-boundary lint job exists at all; R11 must be able to host such a job without determining its existence. R12 defines whether and how multiple jobs are aggregated into a single required status check; its decision depends on the job graph chosen here but is out of scope for R11. R13 governs always-on software composition analysis and must decide, using the topology defined by R11, whether vulnerability scanning is placed in its own job or folded into an existing one. Finally, R10 governs dependency caching; R11 must assume the presence of an established Rust caching action and reason about how its effectiveness shapes the choice between multi-job and single-job CI.

Within this broader context, the central questions are threefold. First, given Rust’s compile times and the availability of caching, does Rust CI for this template benefit more from per-check job splitting (as in the Python blueprint) or from a single shared job (as in the TypeScript blueprint)? Second, is a path-filtered changes-detector job necessary and proportionate to skip heavy build, test, coverage, and docs jobs on docs-only or surface-isolated pull requests? Third, how can the resulting design preserve shared principles across Python, TypeScript, and Rust while allowing justified ecosystem-specific differences? The remainder of this report structures the research and answers through the mandated survey method and the answer template.

**Methodology and Landscape Setup**

The owner’s survey method requires **“forest before trees”**: a landscape of categories and candidates must be assembled before evaluating specific designs. For CI job structure and changes detection in Rust, the relevant category is “GitHub Actions CI architecture patterns for Rust projects,” spanning built-in workflows, first-party guidance, widely adopted third-party Actions, and emergent path-filtering mechanisms. The search results provided form the basis for a fresh ecosystem survey, rather than relying on pre-existing baselines.

Built-in and first-party sources include **official Rust documentation on CI**, which offers examples of GitHub Actions workflows using `cargo build`, `cargo test`, and optional checks such as Clippy and MSRV verification.[1][2] The Rust Clippy documentation provides a concise GitHub Actions example where Clippy lints are run in a dedicated job using `cargo clippy --all-targets --all-features`, with `RUSTFLAGS="-Dwarnings"` to fail the job on any warning.[1] Cargo’s continuous integration guide shows a multi-toolchain matrix job that tests a package against stable, beta, and nightly toolchains, illustrating that Rust’s own guidance assumes job-level matrix execution and highlights auxiliary jobs for dependency updates and MSRV verification using tools like `cargo-msrv` and `cargo-hack`.[2] These documents represent authoritative guidance because they are maintained by the Rust project and describe recommended practices rather than ad-hoc examples.

GitHub’s documentation provides a **Rust workflow template** that demonstrates a minimal CI pipeline: a single `build` job that runs `cargo build --verbose` and `cargo test --verbose` on `ubuntu-latest` for pushes and pull requests to `main`.[8] This template is authoritative for “floor” guidance, showing how GitHub expects basic Rust projects to be tested, but it is explicitly described as a starting point that users should customize.[8] It therefore serves as a baseline but not as a model for advanced multi-surface templates.

Established industry standards for Rust CI architecture can be seen in well-regarded projects and curated training material. Microsoft’s Rust engineering book includes a chapter on building a **production CI/CD pipeline**, presenting a single workflow file with multiple jobs: a fast feedback “check” job that runs formatting, Clippy lints, `cargo check`, and documentation warnings, followed by a “test” job in an OS matrix, cross-compilation jobs using additional targets and optional `cross`, and further jobs for coverage, security analysis, and release artifacts.[5] This chapter is authoritative both because it is curated by a major industry player and because it explicitly frames the workflow as production-ready guidance, with clearly explained quality gates and execution stages.

Further practice evidence comes from the CI pipelines of major Rust ecosystem projects. The Axum web framework uses GitHub Actions to orchestrate a CI pipeline described in DeepWiki as including quality gates, testing strategies, cross-compilation validation, dependency management, and documentation checks across multiple crates (`axum`, `axum-core`, `axum-extra`, and `axum-macros`).[10] Tokio, the asynchronous runtime, uses a main `ci.yml` workflow with a comprehensive test pipeline that enforces a strict MSRV policy; DeepWiki notes that Tokio’s MSRV is 1.71, enforced across multiple workspace crates, and the GitHub workflow file shows job-based orchestration including MSRV checks.[11][19] These projects are widely referenced as canonical Rust libraries in documentation and community material, and their CI pipelines reflect mature, large-scale usage of Rust CI patterns.[10][11][19]

Established third-party Actions include **Swatinem’s `rust-cache`** GitHub Action, which provides smart caching for Rust and Cargo projects.[12][13] The action caches `~/.cargo` (binaries, registry, git dependencies) and the `target` directory, using an automatic key derived from the job ID, `rustc` release and hash, relevant environment variables, and a hash of all `Cargo.lock` and `Cargo.toml` files in the repository.[12][13] This action has become a de facto standard for Rust CI caching, and multiple guides, including Atharva Pandey’s CI/CD lesson, recommend using it with a shared key across jobs so that test jobs can reuse build artifacts produced by check jobs.[20] Another established Action is **dtolnay’s `rust-toolchain`**, which provides a concise way to install a specified Rust toolchain using rustup; it allows configuration via the action revision (e.g., `@stable`, `@nightly`, `@1.42.0`) or an explicit `toolchain` input, and provides outputs such as a cache key derived from the installed `rustc` version.[14] Its usage in examples and major projects like Axum and Tokio reflects its role as a standard mechanism for toolchain selection.[5][10][11][14]

Up-and-comer mechanisms relate mainly to **path-filtered conditional execution**. The `dorny/paths-filter` Action and the closely related `paths-changes-filter` Action both implement conditional job and step execution based on the files modified in a pull request or push.[7][17] Their documentation describes filters composed of glob rules, with outputs indicating whether a filter matched any changed files and listing the matched files; these outputs can be consumed via `needs` and `if` conditions to gate heavy actions.[7][17] Independent blog posts, including a NetBay Hosts article and Rabinarayan Patra’s snippet, outline patterns for skipping CI when only documentation files change, explaining the tradeoffs between GitHub’s native `paths` and `paths-ignore` filters at the workflow level and finer-grained Actions like `paths-filter`.[15][16] These posts are not authoritative by themselves but serve as interpretive guides referencing GitHub’s own documentation and real-world patterns.

Finally, additional practice evidence comes from intermediate projects and guides. Rust Maven’s sample GitHub workflow uses a matrix of Rust toolchains (stable, beta, nightly, and specific versions) with steps invoking `cargo clippy`, `cargo fmt`, and `cargo test`, sometimes with stricter Clippy pedantic lints.[3] A Dev.to article on Rust CI with GitHub Actions describes a multi-workflow setup where separate workflows handle linting, testing with coverage, and release packaging, highlighting the use of nightly Rust, codecov integration, caching via `Cargo.lock` hashing, and dedicated Clippy and Rustfmt jobs.[6] The Bevy engine’s CI template provides a reference for game-oriented Rust projects, using a CI workflow that runs `cargo test`, `cargo clippy -- -D warnings`, and `cargo fmt --all -- --check` on `main` branch commits and pull requests, with a separate release workflow for attaching built artifacts to GitHub releases.[9] These sources collectively ground the landscape in both official guidance and varied production practice.[1][2][3][5][6][8][9][10][11][12][13][14][15][16][17][19][20]

With this landscape established, the report can now apply the mandated answer template, beginning with a detailed analysis of principles and implementation for CI job structure and changes detection in `rs-launch-blueprint`.

**Detailed Analysis for rs-launch-blueprint CI Job Structure**

**Gemini (deep-research-preview-04-2026)**

**CI Workflow Job Structure and Execution Topology Architecture**

### Landscape

**OpenAI**

**Research date:** September 18, 2026. This item decides a **CI orchestration and change-impact-gating bundle**, not a Rust crate. Crates.io download, crate-release, RustSec-package, Cargo-feature, and crate-MSRV figures are therefore inapplicable unless explicitly noted. No prior art from the owner’s other Rust repositories was consulted.

**Category map**

| Bin | Architectures and mechanisms found | Assessment for this template |
|---|---|---|
| **Built-in or first-party toolchain** | One GitHub Actions job with sequential steps; multiple jobs with `needs:`, outputs and matrices; native workflow-level `paths`/`paths-ignore`; hand-written Git/GitHub-API diffing; GitHub’s newer parallel-step facility | Multiple jobs and matrices are the native substrate. Native path triggers cannot condition individual jobs and can leave required checks pending when the whole workflow is skipped. Hand-written diffing avoids third-party code but owns event, pagination, merge-base and filename edge cases. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)) |
| **Established industry standard** | Capability-oriented jobs; small planning/changes job followed by conditional fan-out; reusable workflows; `dorny/paths-filter` for changed-path outputs | This is the strongest fit. Current Rust projects commonly make jobs correspond to capabilities, platforms or toolchains rather than placing the entire suite in one job. `dorny/paths-filter` directly implements the required job-output/`needs:` pattern. ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml)) |
| **Up-and-comer** | Build-once/test-partition pipelines; dynamic matrices generated from changed components; StepSecurity-maintained action forks; concurrent steps on one runner | Useful for large monorepos, but adds artifact-transfer, security-vendor or runner-contention complexity that is disproportionate for the initial template. Nextest’s build-reuse example is a maintained reference for the build-once alternative. ([github.com](https://github.com/nextest-rs/reuse-build-partition-example/blob/main/.github/workflows/ci.yml)) |

**Authorities used and why they count**

- **GitHub Actions documentation** is first-party and authoritative for job isolation, parallelism, outputs, `needs:`, caching, path-trigger behavior and required-check implications. Each job gets its own runner; steps in a job share a runner; independent jobs run in parallel by default. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax))
- **The Cargo Book** is the Rust project’s authoritative description of Cargo output directories, target/profile separation and incremental artifacts. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/build-cache.html))
- **The Rust Survey Team and Compiler Performance Working Group** provide ecosystem-level evidence rather than anecdotal claims. The 2025 compiler-performance survey had more than 3,700 responses; among 1,495 respondents using CI, roughly one quarter considered CI performance a major blocker. It also documents that `cargo check` and code-producing builds do not fully share their artifacts. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- **Maintainer documentation and releases** establish `dorny/paths-filter` behavior and current security state. Its latest release is v4.0.3, released August 5, 2026, and fixes the August 2026 filename-output advisory. ([github.com](https://github.com/dorny/paths-filter/releases))
- **Current workflow source from Rust projects** is practice evidence, not a predetermined winner. Cargo, Tokio, Axum, Clap, nextest, ripgrep and uv were surveyed because they cover first-party tooling, runtime/web libraries, CLI libraries, test infrastructure and a newer production Rust workspace. Their exact popularity rankings were not used because the mandated GitHub API popularity endpoints could not be retrieved in this research environment.

**Practice evidence**

| Project | Observed structure | Relevance |
|---|---|---|
| Rust Cargo | Separate `rustfmt`, `clippy`, `msrv`, docs, tests and other jobs, followed by a conclusion job | First-party Rust project; strong evidence for capability statuses and a separate MSRV concern. R12, not R11, owns the conclusion job. ([github.com](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml)) |
| Tokio | Separate fmt, Clippy, docs and minimum-Rust jobs feed a `basics` gate before expensive matrices | Demonstrates maximum failure isolation and staged fan-out for a very large workload. The extra staging is too serial for this smaller template. ([github.com](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml)) |
| Axum | Combines Clippy and formatting in one `check` job, but keeps docs, feature checks, MSRV and tests separate | Strong evidence for the hybrid alternative: jobs by capability/failure domain, not mechanically one job per command. ([raw.githubusercontent.com](https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml)) |
| Clap | Dedicated test, check, docs, rustfmt, Clippy and coverage jobs, with OS and feature matrices | Directly relevant to the CLI/library surface and supports independent capability jobs. ([raw.githubusercontent.com](https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml)) |
| Nextest | Separate lint and MSRV jobs plus build/test matrices; explicitly chooses one broad build job to populate a cache reused by later jobs | Demonstrates that cache-sharing across jobs is possible only through deliberate topology and key coordination; it is not a free consequence of adding a cache action. ([raw.githubusercontent.com](https://raw.githubusercontent.com/nextest-rs/nextest/main/.github/workflows/ci.yml)) |
| Ripgrep | Broad test matrix plus a separate rustfmt job | Relevant simpler CLI precedent: even a focused CLI does not necessarily fold every check into one job. ([raw.githubusercontent.com](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/.github/workflows/ci.yml)) |
| uv | A `plan` reusable workflow emits outputs consumed by conditional check/test/build workflows, followed by a required-check fan-in | Relevant newer, compile-heavy Rust workspace evidence for central planning and conditional fan-out. Its custom detector is evidence for the architecture, not a recommendation to inherit its complex shell implementation. ([raw.githubusercontent.com](https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/ci.yml)) |

**Landscape conclusion:** the Rust field does not show agreement on “one command equals one job,” but it does show strong practice support for **capability- and environment-level jobs once a project has multiple platforms, toolchains or expensive checks**. The TypeScript monolith is therefore not a portable low-level standard; neither is Python’s exact five-linter split.

**Perplexity**

Within the Rust CI architecture category, the landscape can be mapped into three bins: first-party or built-in patterns, established industry standards, and up-and-comer mechanisms. Each bin supplies candidates relevant to R11’s decision on job structure and changes detection.

The **first-party or built-in bin** includes GitHub’s Rust workflow template and official Rust documentation on CI for Cargo and Clippy. GitHub’s template demonstrates a straightforward single-job CI where the `build` job runs `cargo build --verbose` and `cargo test --verbose` on `ubuntu-latest` for pushes and pull requests to `main`.[8] This template is a baseline for minimal CI, suitable for small projects but not necessarily for multi-surface blueprints. Rust’s Cargo CI guide provides richer examples, including a workflow with a matrix of toolchains across `stable`, `beta`, and `nightly`, a job for verifying dependencies via `cargo update`, and a dedicated MSRV job using `cargo-hack` with `--rust-version` across workspace targets.[2] These examples show that Rust’s own authors expect multi-job workflows, especially when testing against multiple toolchains or verifying MSRV for packages that declare `rust-version`.[2] Clippy’s documentation adds another first-party example: a simple workflow where a `clippy_check` job runs `cargo clippy --all-targets --all-features`, with `RUSTFLAGS="-Dwarnings"` to fail CI on warnings.[1] Together, these sources establish that Rust’s official guidance considers both single-job floor patterns and multi-job, matrix-based advanced patterns as normal.

The **established industry standard bin** comprises multi-job workflows that separate fast checks from heavy validation, and established Actions for toolchain selection and caching. Microsoft’s Rust engineering chapter shows a CI workflow named `CI` with jobs such as `check` (running `cargo check`, Clippy, and `cargo fmt`), `test` (running `cargo test` on an OS matrix), `cross` (cross-compiling using additional targets and optionally `cross`), and further jobs like `miri` and coverage.[5] The `check` job uses `dtolnay/rust-toolchain@stable` with `components: clippy, rustfmt`, followed by `Swatinem/rust-cache@v2` to cache dependencies, and then runs several commands including documentation checks with `RUSTDOCFLAGS='-Dwarnings' cargo doc`.[5] This pattern explicitly divides CI into stages and introduces dependencies between jobs via `needs`, providing a strong template for a production Rust pipeline. The Bevy CI template, though simpler, also exemplifies a multi-job approach by separating CI and release workflows and by folding tests, Clippy, and formatting into a common CI workflow that runs on each commit and pull request to `main`.[9]

Established Actions play a central role. `dtolnay/rust-toolchain` installs a Rust toolchain using rustup, selecting the toolchain based on the action revision or an explicit `toolchain` input, and optionally installing additional components like `clippy` and `rustfmt` or targets like `wasm32-unknown-unknown`.[14] It is widely used in examples and major projects because of its concise configuration and well-maintained behavior.[5][10][11][14] `Swatinem/rust-cache` implements smart caching for Rust projects, caching `~/.cargo` and `./target` and deriving cache keys from job IDs, `rustc` versions, environment variables, and Cargo metadata.[12][13] Atharva Pandey’s CI/CD lesson underscores the importance of setting a shared key (e.g., `shared-key: "main-build"`) so that jobs like `test` can benefit from artifacts built in earlier jobs such as `check`.[20] This pattern directly addresses concerns about repeated compile times across jobs and is therefore central to R11’s decision.

The **up-and-comer bin** consists primarily of path-filtered changes-detection mechanisms. `dorny/paths-filter` is a GitHub Action that allows conditional execution of workflow steps and jobs based on files modified in a pull request or push, supporting filters composed of glob patterns and output variables indicating whether any paths matched and listing the matched files.[7] The similar `paths-changes-filter` Action offers a marketplace entry emphasizing the ability to define multiple filters, each with optional include or exclude rules and separate outputs for flags and file lists, enabling fine-grained conditional gating.[17] These Actions are increasingly used in monorepo setups where slow tasks like integration tests or deployments are run only for changed components, saving time and resources.[7][17] Independent guidance, such as the NetBay Hosts article and Rabinarayan Patra’s snippet, explains how GitHub’s built-in `paths` and `paths-ignore` filters at the workflow level can skip entire workflows on docs-only changes and warns of pitfalls, especially when required status checks depend on workflows that might not run.[15][16] These sources advocate for using job-level Actions like `paths-filter` when fine-grained gating is needed while keeping the workflow as a whole triggered.[7][15][16][17]

Practice evidence provides additional nuance. The Axum project uses GitHub Actions as its CI platform and orchestrates validation across multiple crates, including quality gates and documentation checks, indicative of a multi-job pipeline.[10] Tokio’s CI includes jobs that enforce MSRV and test the runtime under different configurations, again adopting multi-job structures.[11][19] Rust Maven’s example demonstrates a matrix of Rust versions with Clippy and formatting steps, while the Dev.to article on Rust CI uses multiple workflows for linting, testing with coverage, and release packaging.[3][6] All these examples show that **splitting concerns into jobs and workflows** is the dominant pattern for nontrivial Rust projects, particularly when multi-surface or multi-crate workspaces are involved.[3][5][6][9][10][11][19][20]

These landscape observations directly inform R11’s decision. Single-job workflows remain valid for small projects and are supported by GitHub’s Rust template.[8] However, multi-job workflows using `dtolnay/rust-toolchain` and `Swatinem/rust-cache`, with optional path-filtered gating by `dorny/paths-filter` or similar Actions, represent the **established standard** for production Rust CI in multi-surface contexts.[5][10][11][12][13][14][20] The following sections articulate the principles that must be preserved across languages and derive a concrete recommendation for `rs-launch-blueprint`.

**Gemini**

The architectural mapping of Continuous Integration pipeline topology and execution gating within the Rust ecosystem divides into three distinct evolutionary categories, reflecting a spectrum from rudimentary toolchain configurations to highly optimized, distributed compilation networks. The first category comprises built-in or first-party toolchain mechanisms. Within this domain, projects rely on native GitHub Actions workflow-level path triggers utilizing the `on.push.paths` declaration, native matrix strategy configurations, and single-job sequential execution blocks that depend strictly on standard compiler invocations. This baseline approach offers simplicity but frequently falls victim to execution bottlenecks and branch protection deadlocks when applied to complex monorepos. 

The second category represents the established industry standard, characterized by sophisticated artifact reuse and dynamic execution gating. This tier utilizes third-party changes-detector steps to conditionally trigger downstream computational workloads via explicit dependency edges [cite: 1, 2, 3]. Furthermore, it heavily leverages sophisticated caching mechanisms to preserve the compiler's output directory across runs, drastically reducing redundant compilation overhead [cite: 4]. Finally, the third category encompasses up-and-coming distributed architectures. These next-generation implementations utilize distributed cache backends and remote execution environments, fundamentally shifting the bottleneck from local computational constraints to network ingress and egress throughput [cite: 5, 6]. The rapid adoption of advanced, bare-metal-equivalent runners in the GitHub ecosystem further alters this landscape, occasionally rendering aggressive local caching less critical than sheer CPU throughput [cite: 7, 8].

Authority in evaluating these architectural paradigms is derived from foundational compiler documentation, large-scale empirical data, and the documented constraints of the host infrastructure. The official compiler development guide serves as a primary authoritative source, dictating the underlying philosophy for maintaining repository stability through a strict separation of rapid validation checks and exhaustive integration testing [cite: 9, 10]. This documentation emphasizes the absolute necessity of artifact caching mechanisms due to the inherent expense of compiling the language's abstract syntax trees and intermediate representations. Complementing this official guidance is empirical analysis derived from large-scale observation of automated workflows. Observational data encompassing over sixty-six thousand automated pipeline executions provides objective validation regarding the adoption rates and efficacy of specific optimization strategies, confirming that dynamic path filtering and aggressive dependency caching represent a dominant industry consensus [cite: 6]. Furthermore, the operational limitations documented within the issue trackers of leading caching utilities provide critical infrastructural context, highlighting how naive architectural designs can rapidly exhaust resource quotas and induce systemic pipeline degradation [cite: 11].

An examination of mainstream, well-regarded projects reveals a significant convergence toward highly optimized build topologies designed to circumvent these infrastructural limitations while minimizing the time required to return actionable feedback to developers. A foundational asynchronous runtime library, recognized for its ubiquity and possessing widespread community adoption, serves as a premier example of this optimization [cite: 12, 13]. The automated pipelines governing this repository meticulously manage cache keys and employ rigorous path-based execution gating to prevent redundant compilation cycles, establishing a reference standard for complex codebases. Similarly, the ecosystem's dominant command-line interface argument parser utilizes a bifurcated job structure that isolates static analysis from extensive behavioral testing, yet ensures that operations within these logical boundaries remain sequentially folded to maximize the utility of cached artifacts [cite: 14, 15]. A prominent asynchronous web framework further reinforces this paradigm; its integration pipelines are architected to consolidate sequential execution steps into highly optimized singular jobs, acknowledging that the compilation footprint of modern web services necessitates absolute adherence to a shared output directory model to remain performant [cite: 16, 17].

Evaluating these paradigms requires a rigorous assessment of fit against the specific operational parameters of the target template, which encompasses a multifaceted workspace containing a command-line interface, a core library, and an optional web service surface. This architectural diversity dictates a pipeline topology capable of accommodating highly heterogeneous compilation profiles. The web service component may introduce extensive dependency subgraphs, while the core library remains computationally lightweight. The chosen topology must operate efficiently across disparate operating systems, respecting the varied computational capacities and provisioning latencies inherent to different virtualized environments. The final architecture must synthesize these constraints into a cohesive structure that preserves the operational philosophies established by preceding templates while optimizing strictly for the mechanical realities of the compilation toolchain.

### Principles and implementation

**OpenAI**

**Shared requirement and agreement level**

The shared engineering principle is:

> **Provide trustworthy, quickly attributable CI feedback while spending expensive compute only where the change can affect the checked capability.**

Agreement is required at these levels:

| Level | Must agree across py/ts/rs | May vary by ecosystem |
|---|---|---|
| **Capability** | Every owner-selected gate runs on changes that can affect it; no gate is silently lost. | Exact check commands and tools. |
| **Policy** | Change skipping is conservative; uncertainty, CI-configuration changes, default-branch pushes and merge-queue runs cause a full run. | Whether the workload is large enough to justify a detector. |
| **Architectural pattern** | Independently governed/platform-specific gates must remain independently observable and addressable. | A small same-runtime suite may use steps; a compile-heavy multi-platform suite may use jobs. |
| **Low-level mechanism** | No mandatory cross-repository equality. | Python may retain several heterogeneous lint jobs, TypeScript may retain a compact same-runtime job, and Rust may use capability fan-out. |

**Observable acceptance criteria**

1. A pull request changing only recognized documentation paths starts no Rust compile, test, coverage, MSRV or API-documentation job.
2. That same docs-only pull request still runs documentation-content checks and any R13 always-on SCA job.
3. A Rust-source, Cargo-manifest, build-configuration or unknown non-documentation change starts every general Rust gate.
4. A stable test/build matrix has `ubuntu-latest` and `macos-latest` legs.
5. The MSRV floor is checked in one separately named Ubuntu job; R11 does not create an MSRV × OS cross-product.
6. Changes to `.github/workflows/ci.yml`, CI scripts or path-classification rules force all relevant jobs.
7. Pushes to `main`, merge-queue runs, scheduled runs and manual full validation bypass PR skipping and run the complete suite.
8. CLI-only changes may skip future web-only gates; web-only changes may skip CLI-only gates; shared-library and root-workspace changes trigger both.
9. Formatting, linting, typechecking, build smoke, tests, coverage and API docs have stable job IDs. Multiple invocations belonging to one capability remain steps within that job.
10. R02 can add `crate-boundaries` using the same `needs: changes` contract without changing the topology.
11. No aggregate status job is introduced here; R12 owns that fan-in.

**Architecture comparison**

| Alternative | Latency | Runner/resource cost | Diagnostics and policy | Verdict |
|---|---|---|---|---|
| **Single shared job** | Critical path is approximately the sum of all checks | Lowest duplicated setup and best same-runner artifact reuse | One status/failure domain; awkward OS/MSRV variation; later checks wait behind earlier checks | Runner-up only if measured compile duplication overwhelms parallel benefit |
| **One job per shell command** | Maximum theoretical parallelism | Maximum runner startup and cache restore duplication | Excessive status noise and fragile graph | Reject |
| **Capability fan-out** | Detector latency plus the longest applicable capability job | Some duplicated setup, but expensive capabilities run concurrently and can be skipped independently | Stable statuses, matrices, permissions, reruns and clear ownership | **Recommend** |
| **Build once, transfer artifacts, then fan out** | Serial build stage followed by tests | Can reduce recompilation but adds artifact upload/download and target/toolchain coupling | Excellent for very large suites with compatible artifacts | Keep as a future optimization, not the template default |

GitHub-hosted jobs start in clean environments, while steps in one job share files. A cache restores outputs from prior completed work; a cache miss is saved only after the producing job succeeds. Consequently, R10 can reduce repeated work across workflow runs but cannot make simultaneously starting jobs share artifacts they have not yet produced. Cargo also partitions artifacts by target and profile, and the Rust compiler survey identifies incomplete sharing between checking and code-producing builds. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching))

Therefore **R10 does not reverse this recommendation**. It affects total runner minutes, not the required job/status architecture. If later measurements show unacceptable duplication, the first adjustment should be grouping `lint` and `typecheck` into one compile-amortized job—not collapsing tests, coverage, docs, MSRV and both OSes into a monolith.

**Changes-detector comparison**

| Mechanism | Job-level outputs | Event correctness | Maintenance/security | Verdict |
|---|---:|---|---|---|
| Native `on.pull_request.paths` | No | First-party | Skips the entire workflow; required checks can remain pending | Reject for required CI; suitable only for optional workflows. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)) |
| `dorny/paths-filter` | Yes | Uses PR-files API on pull requests and Git merge-base logic for applicable branch events | Established, but third-party executable code; current version must be SHA-pinned and recent advisory mitigations observed | **Recommend for PR classification only.** ([github.com](https://github.com/dorny/paths-filter)) |
| Hand-written `git diff` | Yes, after custom scripting | Correct only if checkout depth, merge-base, initial pushes, pagination/renames and merge queue are handled | No third-party action, but substantial owner-maintained correctness surface | Ranked runner-up |
| `tj-actions/changed-files` | Yes | Broad functionality | Affected by a 2025 tag compromise and an earlier filename-injection advisory | Exclude from a new template. ([stepsecurity.io](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised)) |
| StepSecurity fork | Yes | Drop-in fork of the established pattern | Security-focused maintainer, but less independent practice evidence and adds vendor provenance | Up-and-comer. ([github.com](https://github.com/step-security/paths-filter)) |

**Why docs-only gating is worthwhile in Rust**

“Unchanged crate” does not imply zero-cost CI: every hosted job still provisions a clean runner, installs/selects a toolchain, restores caches and handles a cache miss if necessary. The Rust compiler survey reports that CI compilation is materially problematic for a significant subset of users and that target directories can be too large for efficient caching. A tiny detector is therefore more likely to repay its complexity for a CLI + library + web workspace than for the three same-runtime checks described in the TypeScript port. ([docs.github.com](https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching))

The detector should not try to prove that a change is “code.” It should prove the narrower proposition that **every changed file belongs to the recognized documentation-only set**. Any unknown file is treated as non-doc and receives the full suite. This fail-open-for-testing rule minimizes false skips.

**Cross-repository rationale**

- **Python:** the existing detector/fan-out preserves the proportional-work and clear-diagnostics principles. Five separate small lint jobs may be more granular than Rust needs, but that is an ecosystem/workload decision, not a standard Rust must copy.
- **TypeScript:** a single job remains defensible while the suite is only formatter, linter and compiler checks sharing one Node installation and has no demonstrated expensive matrix. Its missing decision rationale is documentation drift; lack of path gating is not automatically a missing capability. Revisit if build, test, coverage or web-contract work becomes expensive.
- **Rust:** separate capability jobs are justified by compilation, code generation, coverage instrumentation, MSRV and OS matrices. Reusing TypeScript’s monolith would preserve YAML familiarity but not the shared engineering principle.

**Baseline review findings**

`BASELINE-REVIEW: F038 — capability-level observability with ecosystem-fit topology — use separate Rust capability jobs rather than TypeScript’s monolith or Python’s exact one-job-per-small-tool shape — GitHub job isolation/parallelism, Rust production workflows and compiler-performance evidence support capability fan-out; affects R11 and downstream R12/R13/R27/R30/R32/R35/R71/R82, with R02 conditional.`

`BASELINE-REVIEW: F040 — conservative proportional-work gating — add one PR-only changes job that skips Rust-heavy work only when every changed file is classified as documentation; use a current SHA-pinned detector rather than inheriting an older action release — native workflow path filters cannot gate individual jobs and can strand required checks; affects R11 and R69, then R12’s aggregation logic.`

`BASELINE-REVIEW: F033 — explicit floor verification without matrix explosion — verify the Cargo.toml rust-version floor in a dedicated Ubuntu MSRV job and test current stable across the fixed OS matrix; do not widen MSRV to both OSes — Cargo, Axum, Clap and nextest all expose MSRV as a distinct concern. On September 18, 2026, Rust 1.98.1 is current stable, so stable-minus-two implies a 1.96 floor; affects R11 only and leaves the owner’s “MSRV on every OS” question open.` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

**Minimal reference topology**

The named pattern is **Conservative Change-Gated Capability Fan-Out (CGCF)**.

```yaml
name: CI

on:
  pull_request:
  push:
    branches: [main]
  merge_group:
  workflow_dispatch:

permissions:
  contents: read

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.ref }}
  cancel-in-progress: true

jobs:
  changes:
    name: Classify changes
    runs-on: ubuntu-latest
    permissions:
      contents: none
      pull-requests: read
    outputs:
      docs-only: >-
        ${{ github.event_name == 'pull_request'
            && steps.filter.outputs.all_count != '0'
            && steps.filter.outputs.all_count == steps.filter.outputs.docs_count }}
      heavy: >-
        ${{ github.event_name != 'pull_request'
            || steps.filter.outputs.all_count != steps.filter.outputs.docs_count }}
      docs: >-
        ${{ github.event_name != 'pull_request'
            || steps.filter.outputs.docs == 'true'
            || steps.filter.outputs.rust == 'true'
            || steps.filter.outputs.force == 'true' }}
      cli: >-
        ${{ github.event_name != 'pull_request'
            || steps.filter.outputs.cli == 'true'
            || steps.filter.outputs.shared == 'true'
            || steps.filter.outputs.force == 'true' }}
      web: >-
        ${{ github.event_name != 'pull_request'
            || steps.filter.outputs.web == 'true'
            || steps.filter.outputs.shared == 'true'
            || steps.filter.outputs.force == 'true' }}
    steps:
      - name: Classify pull-request paths
        id: filter
        if: ${{ github.event_name == 'pull_request' }}
        uses: dorny/paths-filter@ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d # v4.0.3
        with:
          list-files: none
          filters: |
            all:
              - '**'
            docs:
              - '**/*.md'
              - 'docs/**'
            rust:
              - '**/*.rs'
              - '**/Cargo.toml'
              - 'Cargo.lock'
              - '**/build.rs'
              - '.cargo/**'
              - 'rust-toolchain.toml'
            shared:
              - 'crates/library/**'
              - 'Cargo.toml'
              - 'Cargo.lock'
              - '.cargo/**'
              - 'rust-toolchain.toml'
            cli:
              - 'crates/cli/**'
            web:
              - 'crates/web/**'
              - 'openapi/**'
            force:
              - '.github/workflows/ci.yml'
              - '.github/actions/**'
              - 'ci/**'
              - 'Cargo.toml'
              - 'Cargo.lock'
              - '.cargo/**'
              - 'rust-toolchain.toml'

  # R13's always-on SCA job: deliberately not path-gated.
  supply-chain:
    name: Supply-chain policy
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1 # v7.0.1
      - run: ./ci/run supply-chain

  fmt:
    name: Formatting
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run fmt

  lint:
    name: Lint
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run lint

  typecheck:
    name: Typecheck
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run typecheck

  build-smoke:
    name: Build smoke
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run build-smoke

  test:
    name: Test (${{ matrix.os }})
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    strategy:
      fail-fast: false
      matrix:
        os: [ubuntu-latest, macos-latest]
    runs-on: ${{ matrix.os }}
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run test

  msrv:
    name: MSRV
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run msrv

  coverage:
    name: Coverage
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run coverage

  docs-content:
    name: Documentation content
    needs: changes
    if: ${{ needs.changes.outputs.docs == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run docs-content

  api-docs:
    name: API documentation
    needs: changes
    if: ${{ needs.changes.outputs.heavy == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run api-docs

  web-contract:
    name: Web/API contract
    needs: changes
    if: ${{ needs.changes.outputs.web == 'true' }}
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@3d3c42e5aac5ba805825da76410c181273ba90b1
      - run: ./ci/run web-contract

  # Added only if R02 selects crate-boundary enforcement:
  # crate-boundaries:
  #   needs: changes
  #   if: ${{ needs.changes.outputs.heavy == 'true' }}
  #   ...
```

The `./ci/run` subcommands are command slots, not decisions about formatter, linter, test runner, coverage implementation or documentation tools. Their owning items populate them. There are intentionally no check-to-check `needs:` edges: after classification, capabilities fan out concurrently. R12 may later add a fan-in job. The current action SHA and count outputs are supported by the maintained v4 documentation; Coder’s production workflow uses the same `all_count == docs_count` docs-only pattern. ([github.com](https://github.com/dorny/paths-filter/blob/master/README.md))

**Performance evaluation design—not an executed benchmark**

- **Workload:** generated edition-2024 CLI + library + optional web workspace; current stable and Cargo.toml MSRV; Ubuntu and macOS stable legs.
- **Scenarios:** cold-cache Rust change, warm-cache one-line library change, docs-only Markdown change, CLI-only change, web-only change.
- **Instrumentation:** GitHub job start/completion timestamps, total runner-seconds, critical-path duration, cache hit/miss logs, `cargo --timings` in a temporary benchmark branch, uploaded artifact bytes and target-directory size.
- **Latency metric:** pull-request update to completion of all required applicable jobs.
- **Throughput metric:** concurrent PR runs completed per hour under the repository’s runner quota.
- **Resource metric:** sum of all job runtimes, reported separately for Ubuntu and macOS.
- **Decision rule:** do not infer an absolute winner from unrelated project durations. Reconsider grouping lint+typecheck only if paired measurements show less than a 10% median wall-time improvement from splitting while total runner time rises by more than 50% in both cold and warm scenarios.
- **Executed here:** source inspection only. No `rs-launch-blueprint` workflow run was available, so all template-specific timings remain proposed checks.

**Perplexity**

The owner’s mandate requires deriving **shared engineering principles** and identifying the level at which agreement is required across Python, TypeScript, and Rust blueprints. For CI job structure and changes detection, the principles can be summarized as follows.

First, **fast, reliable feedback** is a non-negotiable principle. All blueprints must provide a CI pipeline that fails early when code does not compile, tests fail, or critical lints are violated, and they must do so in a way that developers can understand and trust. In Python, this principle manifests as separate `lint.yml` and `ci.yml` workflows with jobs that run linters, typecheckers, tests, and build-smoke tests, providing clear separation and early reporting.[docs context] In TypeScript, it manifests as a single `ci` job containing steps for linting, formatting, and `tsc` typechecking, ensuring at least one coherent place where failures are surfaced.[docs context] In Rust, fast feedback implies that at least a **check job** combining compilation, core lints, and formatting must run promptly on pushes and pull requests, failing on warnings or errors and reporting results directly.

Second, **resource-aware validation with principled pruning** is a shared principle. Heavier jobs such as integration tests, coverage analysis, cross-compilation, and docs correctness gates consume more time and compute than basic compilation checks, and should be gated in ways that save resources without undermining correctness. The Python blueprint’s `changes` job demonstrates this principle by path-filtering which downstream jobs run, so documentation-only changes do not trigger heavy typechecking or test jobs.[docs context] TypeScript’s single-job pipeline, while lacking explicit skip-gating, implicitly preserves the principle by having relatively light-weight checks whose cost does not justify complex gating. For Rust, where even basic builds are costly, this principle argues for **staging**: a fast check job runs always, while heavy jobs—tests across OSs, coverage, docs builds, and MSRV verification—are gated both by dependency relationships (`needs`) and by **changes-detection outputs** that prevent them from running when only trivial surfaces have changed.

Third, **clarity of topology and responsibilities** is essential. Developers and integrators must understand which job is responsible for which aspect of validation, how jobs depend on each other, and which failures correspond to which concerns. The Python blueprint separates linting, typechecking, tests, and build-smoke into distinct jobs with descriptive names, while the TypeScript blueprint intentionally uses a single job with clearly named steps to simplify mental models.[docs context] In Rust, clarity can be preserved either by separating concerns into jobs (check, test, coverage, docs, msrv, security) or by aggregating them into steps while using consistent naming. However, for a template intended to model **multi-surface applications** and adopt best practices from Axum, Tokio, and Microsoft’s Rust guides, the multi-job approach provides better clarity, especially when combined with `needs` edges that encode execution order.[5][10][11][19]

Fourth, **compatibility with MSRV and multi-OS policy** is a cross-repo requirement. The Rust blueprint must test against its declared `rust-version` floor and current stable, following the “floor plus current stable” reading of F033, and must run CI on both `ubuntu-latest` and `macos-latest`.[2][11] Whether the MSRV floor is validated as a matrix leg or a separate job falls explicitly under R11’s decision.[docs context] At the same time, the owner has left open whether the floor must run on both OSs, and R11 must not widen that parameter. The principles therefore require that the CI job structure includes at least one **dedicated MSRV validation job**, likely running on a single OS (`ubuntu-latest`), and that other jobs run in an OS matrix as appropriate.[2][11][19]

Fifth, **no hidden required checks** is a critical cross-language principle. The NetBay Hosts and Rabinarayan posts emphasize that GitHub’s `paths` and `paths-ignore` filters at the workflow level can cause workflows not to run at all when only certain files change, creating situations where required status checks silently never start.[15][16] In Python, the `changes` job is inside `ci.yml`, ensuring that required status checks are not hidden behind workflow-level filters. For Rust, adherence to this principle requires that any path-filter-based gating must be implemented at the job level, using an always-running `changes` job whose outputs control heavy jobs, rather than gating the entire workflow via `on.push.paths` or `paths-ignore` in ways that could prevent the workflow from starting.[7][15][16][17]

In light of these principles, we can state observable acceptance criteria for R11’s decision. The Rust CI must provide a fast check job that runs on every push and pull request to the main branch and fails on compilation errors, core lints, and formatting deviations. It must include heavy jobs—tests across `ubuntu-latest` and `macos-latest`, coverage, docs correctness, and MSRV validation—that run only when relevant code changes are detected, as encoded through a path-filtered changes-detector job. It must maintain a clear job graph where each job has a descriptive name and purpose, and `needs` edges define a well-understood stage ordering, such that the owner and consumers can reason about which checks must pass before others run. It must refrain from using workflow-level path filters that could prevent workflows from running, and instead use job-level gating based on `paths-filter` outputs. Lastly, it must embody F033’s MSRV policy through an explicit MSRV job and treat that job as part of the CI job structure, without widening OS coverage beyond the owner’s explicit parameters.[2][11][15][16][19]

The question of per-check job splitting versus a single shared job can now be framed as a comparison of **two architectural alternatives**. A single shared job uses one runner and runs steps sequentially: toolchain setup, caching, check, lint, format, test, coverage, docs, and MSRV. This minimizes repeated setup and leverages a single `rust-cache` instance but sacrifices parallelism and clarity of failure domains, as a failure in an early step aborts downstream checks regardless of their independence.[8][12][13] A multi-job workflow separates concerns: `check` runs first, followed by `test` in an OS matrix, `coverage`, `docs`, `msrv`, and optional web-surface jobs, each with `needs: check` or `needs: changes` as appropriate.[2][5][10][11][19][20] This introduces repeated toolchain and caching invocations per job but, when combined with `rust-cache` and shared keys, allows reuse of compiled dependencies across jobs and parallel execution of tests and docs on different OSs, reducing overall wall-clock time.[12][13][20]

Given Rust’s heavy compile times and the availability of caching, **multi-job topology with shared caching** better fits the Rust CI workload for a blueprint akin to Axum or Tokio than a single-job topology. Pandey’s guidance explicitly recommends using `rust-cache` with a shared key so that a `test` job benefits from artifacts built in a `check` job.[20] Microsoft’s pipeline similarly uses `Swatinem/rust-cache` in both `check` and `test` jobs, implying that repeated toolchain and cache setup is an acceptable cost when balanced against parallelism and clarity.[5] Axum and Tokio’s CI pipelines, though not reproduced in full here, are described as multi-job workflows with MSRV enforcement and cross-compilation.[10][11][19] These examples collectively demonstrate that in practice, Rust teams prefer to pay the small overhead of repeated setup for jobs in order to gain parallelism, clearer failure signals, and more maintainable pipelines.

Regarding the necessity of a path-filtered changes-detector job, the answer similarly rests on practice evidence and fit. While simple Rust projects may find `cargo check` and `cargo clippy` sufficiently fast that skipping them on docs-only changes is unnecessary, the blueprint aims to model multi-surface applications with potential web/API surfaces and multiple crates.[5][10][11][19] In such contexts, heavy jobs like tests across multiple OSs, coverage with `cargo tarpaulin` or `cargo-nextest`, docs gates that treat warnings as errors, and MSRV validation can significantly increase CI time.[2][5][6][20] Python’s `changes` job already demonstrates a pattern where such heavy jobs are skipped on docs-only changes, and blog guidance warns against workflow-level path filtering, advocating job-level gating instead.[15][16] Rust’s `paths-filter` and similar Actions are designed precisely for this use case.[7][17] Therefore, the Rust blueprint should adopt a **dedicated `changes` job** that uses path filters to detect documentation-only changes and surface-specific changes (e.g., web/API vs CLI/library), and uses its outputs to skip heavy jobs when appropriate.

This leads to a **baseline review** of F033:

> **BASELINE-REVIEW: F033 — MSRV verification topology — proposed change — evidence.**  
> Principle: F033 states “floor plus current stable,” leaving open whether the `rust-version` floor is verified via a matrix leg or separate job. The proposed change is to adopt a separate `msrv` job in CI that verifies the floor using `cargo-hack` or `cargo-msrv` on `ubuntu-latest`, rather than treating the floor as merely a leg in the main test matrix.[2] Evidence: Rust’s Cargo CI guide shows an example MSRV job using `cargo-hack check --rust-version --workspace --all-targets`, and Tokio’s CI enforces MSRV via distinct jobs.[2][11][19] This change clarifies topology without widening OS coverage and maintains the floor-plus-stable principle by keeping the main test job on stable while the `msrv` job validates the declared floor separately.

With principles and baseline review in place, the next section presents a concrete recommendation.

**Gemini**

The foundational engineering requirement governing the design of the pipeline topology is the minimization of time-to-feedback and the elimination of redundant computational waste. This requirement represents a capability-level architectural standard that must be consistently applied across all ecosystem iterations of the template. The automated integration system must possess the capability to dynamically gate extensive computational workloads based on the specific content of a proposed modification, ensuring that superficial changes do not trigger resource-intensive compilation matrices. Furthermore, the system must optimize the execution topology of primary validation checks—including formatting, static analysis, type verification, and behavioral testing—to yield a definitive branch protection status with minimal latency. 

While the overarching principle of computational efficiency is shared, the mechanical implementation of this principle must diverge significantly based on the underlying execution models of the target programming environments. Previous divergence analysis highlights that interpreted ecosystems often utilize highly parallel, fragmented job structures, fanning out static analysis tasks across multiple isolated virtual machines. Conversely, ecosystems relying on rigorous ahead-of-time compilation trend toward monolithic, single-job topologies that fold all validation steps into a sequential pipeline.

The evaluation of architectural alternatives—specifically the choice between highly parallel, fragmented jobs and monolithic, sequentially folded steps—is determined entirely by the operational characteristics of the underlying package management and compilation infrastructure. In interpreted environments, dependency resolution and installation are predominantly limited by network bandwidth, and static analysis tools operate largely as independent, CPU-bound processes. This allows the pipeline to fan out across multiple virtual machines efficiently, as the modest penalty of redundant dependency installation is vastly outweighed by the latency reduction achieved through parallel execution.

In compiled systems featuring advanced incremental build capabilities, this operational calculus inverts entirely. The compilation process in these environments is notoriously resource-intensive, with the majority of computational cycles dedicated to resolving and compiling the upstream dependency graph [cite: 18]. The build system is fundamentally designed around a unified output directory, functioning as an intricate incremental state machine. If the validation pipeline is fragmented into parallel, isolated jobs, severe architectural inefficiencies immediately manifest. Each parallel virtual machine is forced to independently provision its environment, download the toolchain, synchronize the package registry, and compile the exact same dependency graph from scratch [cite: 18, 19]. Even when employing sophisticated remote caching mechanisms, the virtual machine network interfaces are heavily throttled. Extracting gigabytes of compiled artifacts from a remote cache can induce multi-minute network delays, meaning the initialization tax paid by every parallel job entirely consumes any latency reduction theoretically gained by horizontal scaling [cite: 20]. Furthermore, aggressive fan-out strategies rapidly inflate cache storage requirements, frequently exceeding the hard limits imposed by host platforms and resulting in continuous cache eviction and degraded performance [cite: 11].



Therefore, the architecturally superior design dictates folding all lifecycle checks—formatting, static analysis, and behavioral testing—into sequential steps within a single, unified job container. Under this topology, the initial task executes the heavy lifting of dependency compilation, generating the necessary intermediate representations and metadata. Subsequent validation tasks then leverage the fully primed output directory, bypassing redundant compilation and executing almost instantaneously [cite: 21, 22]. This monolithic structure represents the optimal balance of computational efficiency and pipeline velocity for compiled environments.

The secondary architectural principle requires the implementation of a dynamic skip-gating mechanism to prevent the execution of resource-intensive workloads on unmodified contexts. In prior implementations, this was achieved via a dedicated execution layer that analyzed the file modifications within a proposed change and routed the pipeline accordingly. The necessity of this mechanism in a compiled environment is underscored by the substantial overhead associated with environment provisioning. The setup lifecycle of a virtual machine—encompassing initialization, repository cloning, toolchain installation, and the decompression of massive cache archives—routinely consumes significant time before any actual validation logic is executed [cite: 18, 23]. Allowing this full lifecycle to execute for superficial modifications, such as documentation updates, constitutes a severe misallocation of computational resources and developer time [cite: 6, 24]. A dedicated, lightweight changes-detector job mitigates this inefficiency, preserving pattern parity across the ecosystem while explicitly addressing the high initialization penalties inherent to the compiled toolchain.

The integration of the minimum supported language version (MSRV) policy into this folded-step architecture requires precise configuration to fulfill explicit parameter constraints without inducing scope creep. The parameters dictate that the minimum version must be tested within the pipeline across a specified operating system matrix. To achieve this without restructuring the job graph into fragmented verification tasks, the pipeline must implement a multi-dimensional matrix strategy encompassing both the specified operating systems and the defined compiler versions (the current stable release and the calculated floor). This unified matrix ensures comprehensive coverage of the required execution contexts while preserving the overarching efficiencies of the folded-step topology.

`BASELINE-REVIEW: F038 — CI job structure — proposed change: adopt folded steps (TypeScript parity) — evidence: The target/ directory's incremental compilation model dictates sequential execution to avoid massive N-times redundancy and cache bloat.`
`BASELINE-REVIEW: F040 — Changes-detector job — proposed change: retain F040 dedicated job (Python parity) — evidence: The prolonged provisioning and cache restoration times associated with compiled language environments necessitate aggressive gating to save CI minutes on documentation-only modifications.`
`BASELINE-REVIEW: F033 — MSRV floor verification — proposed change: floor plus current stable — evidence: The requirement is satisfied by incorporating the MSRV floor as an explicit axis within the unified CI job matrix, strictly bound by the required target-os-matrix.`

### Recommendation

**OpenAI**

Adopt **Conservative Change-Gated Capability Fan-Out (CGCF)**:

1. **Separate GitHub Actions jobs for independently governed checks**, not one shared Rust job.
2. **Steps remain the unit for setup and multiple invocations within one capability.**
3. Add one **PR-only `changes` job** using SHA-pinned `dorny/paths-filter` v4.0.3.
4. Skip Rust-heavy work only when **every changed file** is in the recognized docs set.
5. Continue running documentation-content and always-on SCA gates on docs-only pull requests.
6. Run all jobs on pushes, merge queue, schedules and explicit full runs.
7. Use a shallow graph: `changes → capability jobs`; no serial lint-before-test gate.
8. Put MSRV in its own Ubuntu job; keep stable platform-sensitive build/test jobs on `ubuntu-latest` and `macos-latest`.
9. Add optional `cli` and `web` outputs only for surface-specific gates; shared-library/root changes activate both.
10. Leave aggregate status handling entirely to R12.

**Perplexity**

For `rs-launch-blueprint`, R11 should adopt a **multi-job CI workflow** in `.github/workflows/ci.yml` with the following topology:

A fast **`changes` job** runs on every push and pull request to the main branch. It uses `actions/checkout` to obtain the repository and a path-filter Action such as `dorny/paths-filter` or `paths-changes-filter` to classify changes into filters such as `docs`, `core`, and `web` (if the optional R69 web surface is present).[7][17] The job sets outputs indicating whether the change set is documentation-only, whether core crates changed, and whether web-surface files changed. This job runs quickly, performing no compilation, and acts as a gating mechanism for heavy jobs.[7][15][16][17]

A **`check` job** runs unconditionally on code changes and optionally even on docs-only changes, with `needs: changes`. It uses `dtolnay/rust-toolchain@stable` to select the current stable toolchain and requests components such as `clippy` and `rustfmt`.[5][14] It invokes `Swatinem/rust-cache@v2` with a shared key (e.g., `main-ci`) to cache dependencies.[12][13][20] The job then runs the template’s chosen formatter, linter, and typechecker tools in sequence—for example, `cargo fmt --check`, `cargo clippy -- -D warnings`, and `cargo check --workspace --all-targets --all-features`—failing CI on any warnings or errors.[1][2][3][5][9] The `check` job’s acceptance criteria include passing compilation, lint, and formatting across the entire workspace.

A **`test` job** runs only when code changes are detected (`if: needs.changes.outputs.core_changed == 'true'`), with `needs: [changes, check]`. It uses an OS matrix across `ubuntu-latest` and `macos-latest`, with each leg using `dtolnay/rust-toolchain@stable` and `Swatinem/rust-cache@v2` with the same shared key so that build artifacts from `check` can be reused where possible.[5][12][13][14][20] The job runs the template’s test harness, such as `cargo test --workspace` and doc tests, and reports failures separately per OS.[2][5][8][9] This pattern mirrors Microsoft’s `test` job and Axum/Tokio’s practice of OS matrices for tests.[5][10][11][19]

Optional heavy jobs such as **`coverage`**, **`docs`**, and **`security`** (for R13) run with `needs: [changes, check]` and `if` conditions tied to `changes` outputs. The `coverage` job might run on `ubuntu-latest` only, using `cargo tarpaulin` or `cargo-nextest` plus coverage reporting; the `docs` job runs `cargo doc` with `RUSTDOCFLAGS='-Dwarnings'` to treat warnings as errors; the `security` job runs vulnerability scanning and license compliance tools.[2][5][6][20] All these jobs reuse caching and tooling patterns. A **`msrv` job** runs on `ubuntu-latest`, uses `dtolnay/rust-toolchain` to install the `rust-version` floor, and runs tools such as `cargo-hack` to verify that the workspace compiles at that floor.[2][11][19] This job is treated as optional for docs-only changes but required for code changes, with outputs surfacing its results.

For the optional **web/API surface** governed by R69, the `changes` job defines a `web` filter, and a `web-check` or `web-test` job runs only when web files change (`if: needs.changes.outputs.web_changed == 'true'`), testing web-specific behavior such as OpenAPI snapshots or docs-correctness gates without imposing those costs on CLI/library-only changes.[7][10] This preserves the resource-aware validation principle across surfaces.

The workflow avoids workflow-level `paths` or `paths-ignore` filters for core CI, ensuring that required status checks are never hidden behind filters that might prevent workflows from starting.[15][16] Instead, all pruning is done via the `changes` job’s outputs and job-level `if` conditions, following NetBay Hosts and Rabinarayan’s guidance.[7][15][16][17] The job graph and `needs:` edges embody a clear staged pattern: `changes` → `check` → `test`/`coverage`/`docs`/`msrv`/`web`, with each heavy job conditioned on relevant change types.

This recommendation intentionally diverges from the TypeScript blueprint’s single-job shape while preserving shared principles. TypeScript’s single `ci` job remains appropriate there because checks are relatively lightweight, Node’s tooling and incremental builds reduce per-check cost, and the repository’s scope does not justify complex gating. For Rust, the multi-job, changes-gated pattern is justified by compile-time cost, multi-surface scope, and ecosystem practice, as seen in Axum, Tokio, Microsoft’s CI, and advanced community templates.[2][5][9][10][11][19][20] Python’s `changes` and lint partitions already embody this pattern, and Rust’s adoption of it strengthens cross-repo coherence at the principle level.

**Gemini**

The optimal implementation is a **Monolithic Matrix Job Topology gated by a Path-Filtered Detector**. 
The automation workflow will consist of two distinct, sequentially dependent jobs:
1.  A lightweight `changes` job executing on a standard Linux runner, utilizing a dedicated path-filtering utility to analyze modifications against critical source directories and configuration files, outputting boolean gating signals.
2.  A heavy `ci` job operating over a multi-dimensional matrix encompassing the required operating systems and compiler versions. This job is strictly gated by a `needs:` relationship to the changes job and an `if:` conditional ensuring execution only when critical paths are modified. It sequentially folds toolchain provisioning, artifact caching, formatting, static analysis, type verification, and behavioral testing into a single unified execution context.

### Members

**OpenAI**

#### Conservative Change-Gated Capability Fan-Out (OpenAI)

##### Landscape

This member is an architectural pattern synthesized from GitHub’s native job/output/matrix model and current Rust project practice. There is no canonical external name; **CGCF** is the proposed ledger value. Pattern candidates were the shared-job monolith, strict per-command jobs, capability fan-out and build-once/artifact fan-out.

Crate figures, crate licenses, RustSec records, dependency-tree MSRV, Cargo features and unsafe-code posture are **inapplicable** because this member is workflow architecture, not distributed Rust code.

##### Principles and implementation

A job boundary is warranted when at least one of these differs:

- required-status or policy ownership;
- runner OS, architecture or Rust toolchain;
- permissions/secrets;
- path relevance;
- independent rerun/failure attribution;
- artifact/profile semantics.

Commands stay as steps when they implement one capability and benefit from sharing the same checkout, target directory or produced output.

The recommended graph is one classification root and a shallow fan-out. This avoids the TypeScript monolith’s serial critical path without importing Tokio’s extra “basics before tests” stage, which would delay a small template’s tests and cannot transfer Cargo artifacts across the stage automatically. GitHub’s runner model and cache lifecycle support this distinction. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching))

##### Dominant choice

Among the surveyed non-trivial Rust projects, **capability/environment jobs** are the dominant architectural family. Cargo and Clap split most capabilities; Tokio splits and stages them; Axum groups only tightly related checks; nextest separates lint, MSRV, build and tests. This is convergence at the architectural level, not agreement on exact job count. ([github.com](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml))

##### Qualified shortlist

1. **Capability fan-out with PR detector — recommended.**
2. **Compile-amortized quality job:** formatting, lint and typecheck in one job, with test/docs/coverage/MSRV separate.
3. **Build-once/artifact fan-out:** justified only after measurement demonstrates artifact compatibility and substantial recompilation savings.
4. **Single shared job:** acceptable only for a demonstrably short suite with no meaningful matrix or independent status requirements.

##### Excluded by gate

- **Strict one-job-per-shell-command:** excluded by integration-cost and resource-fit gates. It creates statuses and runner startups without distinct capabilities.
- **One shared job for all Rust checks:** excluded by the observable-acceptance gate because MSRV, two operating systems, coverage, docs and optional surface gates cannot remain independently addressable without turning the job into a conditional step maze.
- **MSRV × every OS matrix:** excluded because it changes an open owner question rather than implementing R11.

Architecture-member fitness gates:

1. License: **inapplicable**—no distributed component.
2. Crate/dependency MSRV: **inapplicable**; the pattern explicitly hosts the required MSRV job.
3. RustSec/unsafe: **inapplicable**.
4. OS: **pass by composition**—stable platform jobs include Ubuntu and macOS.
5. Features/runtime coupling: **inapplicable**.
6. Binary/compile cost: no binary; qualitative cost is duplicated runner/toolchain/cache setup offset by parallel critical-path reduction and selective skipping.

##### Up-and-comers

- GitHub’s concurrent-step mechanism may eventually offer limited same-runner parallelism, but concurrent Cargo commands can compete for CPU and target-directory locks; production evidence for this workload is insufficient.
- Nextest-style build archives and test partitioning are compelling for large suites but create a serial producer stage and artifact-management contract. ([github.com](https://github.com/nextest-rs/reuse-build-partition-example/blob/main/.github/workflows/ci.yml))

##### Fit for this template

The CLI + library + web shape introduces:

- shared-library changes that can affect both binaries;
- web-only contract or snapshot checks;
- CLI-specific smoke checks;
- stable and MSRV toolchains;
- Ubuntu and macOS compatibility;
- coverage and API-documentation compilation.

Those are distinct capabilities and environments. A single job optimizes only setup reuse while degrading feedback attribution, wall-clock parallelism and future surface gating.

##### Recommendation

Use stable job IDs:

- `changes`
- `fmt`
- `lint`
- `typecheck`
- `build-smoke`
- `test`
- `msrv`
- `coverage`
- `docs-content`
- `api-docs`
- `supply-chain`
- `web-contract` when R69 enables it
- `crate-boundaries` only if R02 selects it

Every path-gated job directly needs `changes`; none needs another check job. R12 may later need all applicable jobs.

##### Ranked runner-up

**Compile-amortized quality job:** one `quality` job containing formatting, lint and typecheck steps, with all platform, test, coverage, MSRV and docs jobs still separate.

Select it only if the prescribed paired benchmark shows that the current split consumes materially more runner time without a corresponding latency benefit.

##### Tradeoffs

**Benefits**

- Parallel capability feedback.
- Stable job-level ownership for downstream items.
- Native OS/toolchain matrices.
- Independent reruns and permissions.
- Simple future R02/R13/R69 attachment points.
- Path-gating can skip whole expensive jobs.

**Costs**

- Repeated checkout/toolchain/cache setup.
- Potential duplicate dependency compilation.
- More YAML and branch-protection statuses.
- One detector job adds a runner-startup stage before gated jobs.

R10 reduces, but does not eliminate, the second cost.

##### Parameters

- `owns ci-job-structure member topology = shallow capability fan-out`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`
- `assumes msrv-policy = stable minus 2 minor versions, sourced from Cargo.toml rust-version`
- `assumes web-extra-surface = optional surface with independently relevant gates`
- `CONFLICT: none`

##### Migration implications

- Replace a single `ci` job with the named capability jobs.
- Move each existing check command to its owning job.
- Add `needs: changes` and the appropriate job-level `if:`.
- Add the two-OS matrix to platform-sensitive stable jobs.
- Add a dedicated `msrv` job without multiplying by OS.
- Leave all check-to-check edges absent.
- Reserve the documented job IDs so R12 and branch protection can consume stable names.

##### Validation strategy

Planned checks:

1. Inspect a code-change run and prove all capability jobs start concurrently after `changes`.
2. Introduce a deliberate formatting failure and verify tests still run, demonstrating shallow fan-out.
3. Verify the test/build matrix contains exactly Ubuntu and macOS.
4. Verify MSRV appears as one separate Ubuntu job.
5. Measure wall duration and total runner-seconds against the compile-amortized runner-up.

No target-repository executions were performed during this research.

##### Confidence & re-verify trigger

**Confidence: high, 0.88.**

Re-verify if:

- R10 introduces reliable same-run artifact sharing rather than ordinary cross-run cache restoration;
- runner concurrency becomes constrained enough that fan-out merely queues jobs;
- the paired benchmark crosses the stated 10%/50% review threshold;
- GitHub introduces first-party capability-level changed-path expressions;
- the owner decides MSRV must run on every target OS.

##### Sources

- GitHub workflow syntax: https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax — retrieved 2026-09-18.
- GitHub Actions execution model: https://docs.github.com/en/actions/get-started/understand-github-actions — retrieved 2026-09-18.
- GitHub caching reference: https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching — retrieved 2026-09-18.
- Cargo build cache: https://doc.rust-lang.org/cargo/reference/build-cache.html — retrieved 2026-09-18.
- Rust compiler-performance survey results: https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/ — retrieved 2026-09-18.
- Cargo CI: https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml — retrieved 2026-09-18.
- Tokio CI: https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml — retrieved 2026-09-18.
- Axum CI: https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml — retrieved 2026-09-18.
- Clap CI: https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml — retrieved 2026-09-18.
- Nextest CI: https://raw.githubusercontent.com/nextest-rs/nextest/main/.github/workflows/ci.yml — retrieved 2026-09-18.

#### SHA-pinned dorny/paths-filter v4.0.3 (OpenAI)

##### Landscape

The mechanism category contains:

- first-party native workflow paths;
- first-party primitives plus hand-written Git/API diffing;
- established changed-file actions;
- security-maintained forks.

`dorny/paths-filter` is the strongest functional match because its maintained reference explicitly exposes filter results as job outputs consumed through `needs:`. ([github.com](https://github.com/dorny/paths-filter))

##### Principles and implementation

Use the action only in a low-permission PR classification job:

- `contents: none`;
- `pull-requests: read`;
- no repository checkout;
- no secrets;
- `list-files: none`;
- full commit-SHA pin;
- boolean and count outputs only;
- full-run fallback for every non-PR event.

The recent advisory concerned unsafe handling of file-list outputs. v4.0.3 contains the fix, and the proposed design does not request or interpolate file lists at all. ([github.com](https://github.com/dorny/paths-filter/security))

##### Dominant choice

Among purpose-built job-level path classifiers, `dorny/paths-filter` is the established choice. A StepSecurity snapshot reported use by 27,776 open-source projects and 3,328 stars; these are non-canonical fallback figures because the required GitHub API endpoint was inaccessible. Its README also provides maintained PR, branch, merge-queue, job-output and dynamic-matrix examples. ([app.stepsecurity.io](https://app.stepsecurity.io/action-advisor/dorny/paths-filter))

##### Qualified shortlist

1. **`dorny/paths-filter` v4.0.3 pinned to full SHA — recommended.**
2. **Local GitHub-API classifier:** retrieve PR files with first-party API calls and classify them in a repository-owned script.
3. **Local Git merge-base classifier:** acceptable if the repository accepts responsibility for checkout depth and event semantics.
4. **StepSecurity `paths-filter`:** security-focused drop-in fork, but with less independent practice evidence.

##### Excluded by gate

- **Native `on.pull_request.paths`:** fails the required job-level-output gate and can leave required checks pending.
- **Pre-fix `dorny/paths-filter` releases:** fail the current-security gate due the August 2026 advisory.
- **Mutable `@v4` tag:** excluded from the reference implementation. The 2025 `tj-actions` incident showed that tag mutation can compromise every consumer; use the full release commit.
- **`tj-actions/changed-files`:** excluded on dependability/security grounds due the 2025 compromise and prior filename-injection advisory.
- **Direct interpolation of changed filenames into shell:** excluded. Filenames are attacker-influenced input on pull requests. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax))

Fitness gates:

| Gate | Result |
|---|---|
| License | **Pass:** MIT. ([raw.githubusercontent.com](https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/LICENSE)) |
| Crate/dependency MSRV | **Inapplicable:** GitHub JavaScript action, not a crate. |
| RustSec/unsafe | **Inapplicable:** no Rust package or Rust `unsafe`; as executable third-party CI code it is instead controlled by SHA pinning and least privilege. |
| Ubuntu/macOS | The classifier is deliberately invoked only on Ubuntu; its outputs gate downstream Ubuntu and macOS jobs. Upstream multi-OS action-test evidence was not found, so no unsupported portability claim is made. |
| Default features/async runtime | **Inapplicable:** no Cargo features or async runtime. The action uses Node 24, GitHub REST for PRs and Git for applicable non-PR modes. ([raw.githubusercontent.com](https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/action.yml)) |
| Binary/compile cost | No Rust binary or Cargo compilation. It executes a bundled JavaScript action in one additional Ubuntu job; runner provisioning is the main qualitative overhead. |

##### Up-and-comers

`step-security/paths-filter` is a security-maintained fork and a plausible future replacement if it develops independent release, issue-response and production-adoption evidence. GitHub-native job-level changed-file contexts would supersede both actions if introduced. ([github.com](https://github.com/step-security/paths-filter))

##### Fit for this template

The action can express:

- recognized docs-only classification using `all_count == docs_count`;
- broad Rust/build/config impact;
- shared-library impact;
- CLI-only impact;
- web/OpenAPI-only impact;
- CI-rule changes that force all gates.

This is enough for R69 without introducing a general monorepo dependency graph. Shared-library changes activate both CLI and web outputs; surface-local changes activate only that surface’s extra gates.

##### Recommendation

Use exactly:

```yaml
uses: dorny/paths-filter@ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d # v4.0.3
```

Use positive filter groups, counts and boolean outputs. Do not enable `list-files`. Invoke it only on `pull_request`; make every other trigger produce unconditional full-run outputs. The full SHA is independently visible in current production workflows and release-update records. ([github.com](https://github.com/camunda/camunda/issues/12605))

##### Ranked runner-up

A repository-owned classifier using the pull-request-files API and a checked-in test suite.

This removes third-party action execution but transfers responsibility for API pagination, unusual filenames, matching semantics, merge queues and event fallbacks to the template. Select it if organizational policy forbids third-party actions.

##### Tradeoffs

**Benefits**

- Direct job outputs and documented `needs:` composition.
- No checkout required for PR classification.
- Handles paginated PR file lists.
- Mature examples and substantial adoption.
- Small YAML footprint.

**Costs and risks**

- Third-party executable CI dependency.
- A high-severity advisory was published and fixed in August 2026.
- No `SECURITY.md` was detected.
- StepSecurity’s current assessment is 6/10 and reports dependency findings, warranting strict pinning and narrow permissions. ([github.com](https://github.com/dorny/paths-filter/security))
- Canonical GitHub API maintenance figures could not be retrieved.

**Required figure ledger**

| Figure | Required endpoint/rule | Result on 2026-09-18 |
|---|---|---|
| 90-day downloads | `GET https://crates.io/api/v1/crates/<name>` → `crate.recent_downloads` | **Inapplicable:** not a crate. |
| All-time downloads | Same → `crate.downloads` | **Inapplicable:** not a crate. |
| Last crate release | Versions endpoint | **Inapplicable.** Action release v4.0.3 was published 2026-08-05. |
| Stars, archived, pushed | `GET https://api.github.com/repos/dorny/paths-filter` | Endpoint retrieval failed in this environment. Non-canonical fallback: StepSecurity reported 3,328 stars; repository was actively releasing and was not presented as archived. No exact `pushed_at` is reported. |
| Open issues | `GET https://api.github.com/search/issues?q=repo:dorny/paths-filter+is:issue+is:open` | Endpoint retrieval failed. GitHub UI fallback displayed 20 open issues. ([github.com](https://github.com/dorny/paths-filter)) |
| Issue responsiveness | Ten most recently opened issues; median time to first maintainer response | **Evidence gap:** required issue/comment API data was inaccessible; no median is fabricated. |
| Advisories | RustSec package page | **Inapplicable:** not Rust. GitHub shows one historical high advisory, fixed by v4.0.3/v3.0.4. |
| Adopters | Reverse dependencies + Cargo.toml | **Inapplicable:** not a crate. Action adopters include Coder’s docs-only classifier and Microsoft’s multi-language—including Rust—changes job. ([github.com](https://github.com/coder/coder/blob/main/.github/workflows/ci.yaml)) |

**Maintenance state:** `active`. Evidence is a release on August 5, 2026, current pull-request activity and multiple recent issue/commit activities. The unavailable canonical API figures lower confidence but do not support `at-risk`, `dormant` or `archived`. ([github.com](https://github.com/dorny/paths-filter/releases))

##### Parameters

- `owns ci-job-structure member detector = dorny/paths-filter v4.0.3 at ceb8a2b8f2d89434be7ff52d3de7ec3738c5cc9d`
- `assumes detector event = pull_request only`
- `assumes non-PR behavior = unconditional full run`
- `assumes changed filename outputs = disabled`
- `CONFLICT: none`

##### Migration implications

- Add the action to `jobs.changes`.
- Add `pull-requests: read` only to that job.
- Expose `docs-only`, `heavy`, `docs`, `cli` and `web` outputs.
- Add filter entries for the template’s actual generated crate paths.
- Add Dependabot/Renovate monitoring for GitHub Actions while retaining immutable SHA pins.
- Record the release comment beside the SHA.
- Do not create a second `lint-changes` detector unless future independent workflows require it.

##### Validation strategy

Planned:

1. Open a docs-only PR and prove `all_count == docs_count`.
2. Add an unknown root file and prove the full heavy suite runs.
3. Change `.github/workflows/ci.yml` and prove all outputs become relevant.
4. Use a filename containing spaces and shell metacharacters; prove no filename is ever interpolated because `list-files` is disabled.
5. Change only `crates/cli`; prove `cli=true`, `web=false`.
6. Change only `crates/web`; prove `web=true`, `cli=false`.
7. Change the shared library or root manifest; prove both are true.
8. Inspect the resolved workflow and prove the action uses the exact full SHA.

No target workflow execution was performed in this research.

##### Confidence & re-verify trigger

**Confidence: medium-high, 0.78.**

Lower than the topology confidence because of the recent advisory, absent security policy and unavailable canonical API maintenance figures.

Re-verify immediately if:

- another advisory affects v4.0.3;
- Node 24 action support changes;
- no release or maintainer activity occurs for six months and issue signals deteriorate;
- GitHub ships native job-level changed-file outputs;
- organizational policy disallows third-party actions;
- the required GitHub API maintenance figures become available.

##### Sources

- Maintainer README: https://github.com/dorny/paths-filter/blob/master/README.md — retrieved 2026-09-18.
- Release v4.0.3: https://github.com/dorny/paths-filter/releases/tag/v4.0.3 — retrieved 2026-09-18.
- Security overview: https://github.com/dorny/paths-filter/security — retrieved 2026-09-18.
- Action metadata: https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/action.yml — retrieved 2026-09-18.
- Package metadata: https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/package.json — retrieved 2026-09-18.
- License: https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/LICENSE — retrieved 2026-09-18.
- Coder production usage: https://github.com/coder/coder/blob/main/.github/workflows/ci.yaml — retrieved 2026-09-18.
- Microsoft production usage: https://github.com/microsoft/agent-governance-toolkit/blob/main/.github/workflows/ci.yml — retrieved 2026-09-18.
- `tj-actions` compromise analysis: https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised — retrieved 2026-09-18.
- GitHub Security Lab filename-injection advisory: https://securitylab.github.com/advisories/GHSL-2023-271_changed-files/ — retrieved 2026-09-18.

**Perplexity**

R11 is classified as a **bundle** and thus comprises multiple conceptual members. In this context, members are architectural patterns rather than crates, and crate-level figures are therefore inapplicable; this is stated explicitly under each member’s fitness gates. Two primary members are needed to realize the recommendation: the **CI job topology pattern** and the **changes-detector job pattern**.

#### CI job topology pattern (Perplexity)

##### Landscape

The CI job topology pattern concerns how GitHub Actions jobs are organized to run Rust checks, tests, coverage, docs gates, and MSRV validation. As the landscape section already noted, first-party Rust CI documentation presents both single-job and multi-job patterns.[1][2][8] GitHub’s minimal Rust workflow template uses a single `build` job with steps for `cargo build` and `cargo test`, representing the simplest topology.[8] In contrast, Cargo’s CI guide shows more complex workflows, including a matrixed `build_and_test` job across stable, beta, and nightly toolchains, separate jobs for dependency update testing, MSRV verification, and warnings enforcement.[2] These examples establish that job topology is a flexible design space.

Established industry practice favors multi-job, staged topologies for nontrivial Rust projects. Microsoft’s CI pipeline uses distinct jobs for `check`, `test`, `cross`, `miri`, and other stages, each with its own responsibilities and quality gates.[5] The Bevy CI template separates CI and release workflows and folds tests, Clippy, and formatting into a single CI workflow, though it keeps them in the same job rather than splitting per concern.[9] Rust Maven’s matrix workflow treats each Rust version as a matrix leg within a single job, but still separates concerns between Clippy, formatting, and testing steps.[3] Axum and Tokio’s CI pipelines, as described in DeepWiki, are built around multi-job workflows with MSRV enforcement and cross-crate validation.[10][11][19] These projects show that multi-job topologies are the norm for medium-to-large Rust repositories.

Third-party Actions such as `dtolnay/rust-toolchain` and `Swatinem/rust-cache` influence job topology by making repeated toolchain setup and caching across jobs cheap enough to justify splitting work. `rust-toolchain` allows each job to independently install the desired toolchain with minimal configuration, while `rust-cache` lets jobs reuse compiled dependencies as long as a shared key is used and environment conditions match.[12][13][14][20] Pandey’s guidance explicitly recommends a shared key (e.g., `shared-key: "main-build"`) to allow later jobs to benefit from earlier builds.[20] This pattern reduces the penalty of multi-job topologies and encourages designs where a `check` job builds dependencies once and `test` and `coverage` jobs reuse the results.[5][12][13][20]

The landscape therefore positions the CI job topology pattern squarely within the **established industry standard bin**, with first-party guidance supporting both minimal and advanced designs and practice evidence favoring multi-job staged workflows for the kind of application that `rs-launch-blueprint` models.[2][5][9][10][11][19][20]

##### Principles and implementation

The job topology pattern must implement the shared principles identified earlier: fast feedback, resource-aware validation, clarity of responsibilities, MSRV and multi-OS compliance, and avoidance of hidden required checks. In practice, this means designing a job graph that has a clear early stage for fast checks, separate stages for heavy validation, and well-defined dependencies.

In the recommended pattern, the **check stage** is implemented as a `check` job that runs after the `changes` job. It must install the stable Rust toolchain via `dtolnay/rust-toolchain@stable`, request necessary components such as `clippy` and `rustfmt`, and prime `Swatinem/rust-cache@v2` with a shared key that other jobs use.[5][12][13][14][20] The job then runs the template’s formatting, linting, and typechecking tools, such as `cargo fmt --all -- --check`, `cargo clippy --workspace --all-targets --all-features -- -D warnings`, and `cargo check --workspace --all-targets --all-features`.[1][2][3][5][9] These commands enforce quality gates analogous to those in Microsoft’s `check` job, where documentation warnings are treated as errors and Clippy lints are denied.[1][5] The implementation must ensure that any failure in this job aborts downstream heavy jobs, preserving fast feedback and avoiding wasted work.

The **test stage** is implemented as a `test` job that depends on `check` (and `changes`) and runs in an OS matrix across `ubuntu-latest` and `macos-latest`. Each matrix leg installs the stable toolchain using `dtolnay/rust-toolchain`, invokes `rust-cache` with the same shared key, and runs the test harness, such as `cargo test --workspace` and doc tests.[2][5][8][9][14][20] This pattern aligns with Cargo’s multi-toolchain CI example and Microsoft’s OS-matrix `test` job.[2][5] It satisfies multi-OS requirements and provides clear signals as to whether failures are OS-specific or global.

Further heavy stages—coverage, docs, msrv, web-specific checks—are implemented as separate jobs that depend on `check` and leverage caching and toolchain actions. The `docs` job runs `cargo doc` with `RUSTDOCFLAGS='-Dwarnings'`, mirroring Microsoft’s documentation gate.[5] The `msrv` job uses either `dtolnay/rust-toolchain` with an explicit toolchain specifier matching the declared `rust-version` floor or a combination of `rustup` commands and `cargo-hack` to check `--rust-version` across the workspace.[2][11][19] These implementations treat MSRV validation as a separate concern, consistent with F033 and the baseline review, while preserving clarity by encasing it in a dedicated job. Optional web-surface jobs run web-specific checks only when required, as discussed under the changes-detector pattern.

To avoid hidden required checks, the topology must refrain from gating entire workflows via `paths` or `paths-ignore` and must instead rely on a `changes` job whose outputs control downstream `if` conditions.[15][16] This keeps the workflow active on all pushes and pull requests while allowing heavy jobs to be skipped only when safe and transparent.

##### Dominant choice

The dominant choice within the job topology pattern is a **multi-job, staged CI workflow** that separates fast checks from heavy validation, uses OS matrices for tests, and isolates MSRV validation and web-specific checks into their own jobs. This choice draws directly from Microsoft’s Rust CI pipeline, Axum and Tokio’s multi-job workflows, and community templates like Bevy, and is enabled by standard Actions like `dtolnay/rust-toolchain` and `Swatinem/rust-cache`.[2][5][9][10][11][12][13][14][19][20] It emphasizes clarity, parallelism, and resource-aware gating while making repeated setup costs acceptable via caching.

##### Qualified shortlist

Alternative topologies include:

A ***single-job workflow with multiple steps***, mirroring GitHub’s Rust template and the TypeScript blueprint. This topology minimizes repeated toolchain setup and caching but sacrifices parallelism and the ability to gate heavy checks separately.[8] It is suitable for small Rust projects that do not require multi-OS testing, coverage, docs gates, or MSRV enforcement. For `rs-launch-blueprint`, however, it cannot easily accommodate the required MSRV job and multi-OS tests without becoming a complex monolith, and it makes skip-gating heavy checks on docs-only changes more difficult because all steps share one job.

A ***hybrid topology*** that uses a single `ci` job for check, test, and docs but adds separate jobs for MSRV and web-specific checks. This pattern offers some clarity but still concentrates most heavy work into one job, making path-filter gating less fine-grained and reducing parallelism.

Given the blueprint’s goals and ecosystem practice, these alternatives are considered but rejected as primary recommendations. They may appear as simplified variants for extremely small projects or as transitional patterns when migrating from single-job CI, but the main blueprint should model the multi-job topology.

##### Excluded by gate

Crate-level fitness gates are **inapplicable** to the job topology pattern because it is an architectural pattern, not a crate. The pattern uses GitHub-hosted runners and Actions (`dtolnay/rust-toolchain`, `Swatinem/rust-cache`, `dorny/paths-filter`) that are governed by their own licenses and MSRV constraints but do not directly affect the template’s crate dependencies or MSRV policy.[12][13][14][7][17] The pattern itself introduces no new crates and therefore cannot be excluded by license or RustSec gates. If any Action used within the pattern were found to have an incompatible license or unmaintained code, that would be addressed under the relevant item (e.g., R10 for caching) rather than R11.

##### Up-and-comers

Within job topology, up-and-comer patterns include deeper integration of caching across jobs, such as sharing build artifacts via `rust-cache` with `shared-key` and future enhancements that might allow explicit artifact reuse across jobs.[12][13][20] Another up-and-comer is the use of `cargo-nextest` and similar tools for parallel test execution, which would influence job topology by introducing additional jobs or steps but are governed by R32 (test harness) rather than R11. These patterns are acknowledged as potential future influences but do not change the current recommendation.

##### Fit for this template

The multi-job topology is a strong fit for `rs-launch-blueprint` because it matches the expected scale and complexity of a CLI + library + web service project. It allows the template to model best practices from Axum and Tokio, which are themselves multi-crate web-service stacks with complex CI pipelines.[10][11][19] It provides a natural place for R02’s crate-boundary enforcement to land as a dedicated job, and for R13’s SCA scaffold to land either as its own job or as part of `security`. It allows R12 to consider aggregating multiple jobs into a single required status check while retaining the underlying clarity. It respects the MSRV and multi-OS constraints while providing a flexible foundation for consumers to add or remove jobs.

##### Recommendation

The recommendation for the CI job topology member is therefore:

Adopt a **multi-job staged workflow** in `.github/workflows/ci.yml` with jobs `changes`, `check`, `test` (OS matrix), `coverage`, `docs`, `msrv`, and optional `web` jobs. Use `dtolnay/rust-toolchain` and `Swatinem/rust-cache` per job, with a shared cache key to amortize compile cost.[5][12][13][14][20] Encode dependencies via `needs:` edges such that `changes` runs first, `check` runs next, and heavy jobs depend on both `changes` and `check`. Avoid single-job topologies for this template, relegating them to minimal projects outside the blueprint’s scope.

##### Ranked runner-up

The ranked runner-up topology is a **hybrid** in which `check` and `test` are kept in one job, while `coverage`, `docs`, and `msrv` are separate jobs. This pattern reduces job count and potential overhead but still allows some separation of heavy checks. It might be suitable for consumers who adopt the template but wish to simplify CI; however, it is not recommended for the template itself because it weakens the clarity and resource-aware gating that the blueprint is meant to model.

##### Tradeoffs

The primary tradeoff of the multi-job topology is increased complexity and slight overhead from repeated toolchain installation and caching across jobs. However, `dtolnay/rust-toolchain` provides concise configuration and `rust-cache` reuses compiled dependencies, mitigating overhead.[12][13][14][20] The benefits include clearer separation of concerns, parallel execution of tests across OSs, and straightforward integration of MSRV and web-specific jobs. The runner-up hybrid pattern reduces complexity but at the cost of less precise gating and weaker modeling of best practices.

##### Parameters

For this member, the parameters are:

owns `ci-job-structure` (topology) = **multi-job staged workflow** with jobs: `changes`, `check`, `test` (OS matrix), `coverage`, `docs`, `msrv`, optional `web`.

assumes `rust-cache` action is present and configured with `shared-key` under R10.[12][13][20]

assumes `rust-toolchain` action is available under R10 or equivalent, configured per job.[14]

##### Migration implications

Migrating to this topology from a single-job CI involves editing `.github/workflows/ci.yml` to introduce job definitions, `needs:` edges, and OS matrices. Steps that previously ran in a single `ci` job must be moved into the appropriate jobs, with environment variables such as `CARGO_TERM_COLOR` set per job.[2][8] Any existing workflow-level `paths` or `paths-ignore` filters must be removed or limited to non-core workflows, with path filtering moved into the `changes` job.[15][16] Consumers of the template must be prepared to update any references to job names in branch protection rules or aggregation mechanisms (R12).

##### Validation strategy

Validation of the job topology pattern involves running the CI workflow on several representative branches and pull requests, ensuring that the job graph behaves as expected. For example, a code change affecting the core library should trigger `changes`, `check`, `test` on both OSs, `coverage`, `docs`, and `msrv`. A docs-only change should trigger `changes` and `check` but skip `test`, `coverage`, `docs`, and `msrv`, as controlled by `if` conditions tied to `changes` outputs.[7][15][16][17] The expected behavior can be confirmed by inspecting the Actions UI and job logs.

##### Confidence & re-verify trigger

Confidence in this member’s recommendation is high, based on alignment with first-party guidance and multiple production examples.[2][5][9][10][11][19][20] Re-verification should be triggered if Rust’s official CI guidance changes significantly (e.g., if new editions or MSRV practices alter recommended job structures) or if GitHub introduces new mechanisms that materially affect job topology (such as native cross-job caching or finer-grained required checks).

##### Sources

Key sources include Rust’s Cargo CI guide, Clippy documentation, GitHub’s Rust template, Microsoft’s Rust engineering CI chapter, DeepWiki entries on Axum and Tokio, Rust Maven’s workflows, Dev.to’s Rust CI article, Bevy’s CI template, `rust-cache` and `rust-toolchain` documentation, and blog posts on path filters and conditional execution.[1][2][3][5][6][8][9][10][11][12][13][14][15][16][17][19][20]

#### Changes-detector job pattern (Perplexity)

##### Landscape

The changes-detector job pattern is concerned with how CI determines which files changed and whether heavy jobs should run. The Python blueprint implements this via a `changes` job in `ci.yml` and a `lint-changes` job in `lint.yml`, both using path-filtering to gate downstream jobs.[docs context] For Rust, the landscape includes GitHub’s native `paths` and `paths-ignore` filters, and third-party Actions such as `dorny/paths-filter` and `paths-changes-filter`.

GitHub’s own documentation describes `paths` and `paths-ignore` filters for `on.push` and `on.pull_request`, which determine whether a workflow runs at all based on changed files.[15][16] A NetBay Hosts article and Rabinarayan Patra’s snippet explain these mechanisms and warn about pitfalls: if a push or pull request changes only files outside the `paths` filter, the workflow does not start, potentially causing required status checks to remain in a pending state because the underlying workflow never ran.[15][16] These posts recommend caution in using workflow-level filters for core CI workflows that feed required status checks.

Third-party Actions provide more flexible, job-level filtering. `dorny/paths-filter` is a GitHub Action that inspects changed files and produces outputs indicating whether filters matched, enabling conditional execution of jobs and steps based on those outputs.[7] It supports multiple named filters, each with glob rules, and can optionally list matched files. The `paths-changes-filter` Action offers similar functionality, emphasizing fine-grained conditional execution and saving time and resources in monorepo setups.[17] Both Actions are marketed for use in complex repositories where slow tasks should run only when relevant components change.[7][17]

These tools form the landscape for changes-detection. Native filters operate at the workflow level; Actions like `paths-filter` operate at the job level and integrate with `needs` and `if` conditions. The Python blueprint uses job-level patterns, aligning with the cautionary guidance in NetBay Hosts and Rabinarayan’s posts.[15][16] Rust’s landscape therefore contains both naive patterns (workflow-level filters) and advanced patterns (job-level path Actions).

##### Principles and implementation

The changes-detector pattern must implement the principle of **resource-aware validation with principled pruning** while avoiding hidden required checks. It should detect whether a change is documentation-only, core code, web-surface, or other, and gate heavy jobs accordingly.

In the recommended implementation, a `changes` job runs in `.github/workflows/ci.yml` with `runs-on: ubuntu-latest`. It performs the following steps:

It uses `actions/checkout` to obtain the repository, ensuring that path analysis is based on the actual commit.[5][6][8] It then uses `dorny/paths-filter` (or `paths-changes-filter`) with a configuration defining filters such as `docs`, `core`, and `web`. For example, `docs` might match `docs/**`, `*.md`, and `README*`; `core` might match `src/**`, `crates/**`, and `Cargo.toml` files; `web` might match `web/**`, `api/**`, and `openapi/**`.[7][17] The Action produces outputs like `docs_changed`, `core_changed`, and `web_changed`, each a boolean indicating whether the filter matched any changed files. These outputs are set using GitHub’s `set-output` mechanism and are available to downstream jobs via `needs.changes.outputs`.

Downstream jobs use these outputs in `if` conditions. The `check` job runs unconditionally (or with `if: always()`), preserving fast feedback for all changes. Heavy jobs such as `test`, `coverage`, `docs-gate`, `msrv`, and `web-check` run only when the relevant filters are true. For example, `test` might run when `core_changed == 'true'`, while `web-check` runs when `web_changed == 'true'`. This pattern allows docs-only changes to skip heavy jobs, while core changes trigger full validation.[7][15][16][17]

The pattern explicitly **avoids using workflow-level `paths` or `paths-ignore`** for CI, following NetBay Hosts and Rabinarayan’s advice.[15][16] Instead, the workflow is triggered on all pushes and pull requests to `main`, ensuring that required status checks always start. The `changes` job terminates quickly and its outputs control heavy jobs, providing the desired pruning without risk of hidden required checks.

##### Dominant choice

The dominant choice for changes detection is a **job-level `changes` pattern using `dorny/paths-filter` or `paths-changes-filter`**. This pattern aligns with Python’s `changes` and `lint-changes` jobs and respects guidance against workflow-level filters for required CI.[7][15][16][17] It is supported by the GitHub Marketplace Actions, which are designed for conditional execution based on changed paths.[7][17]

##### Qualified shortlist

Alternative mechanisms include:

A ***workflow-level `paths-ignore` filter*** that skips the entire CI workflow when only documentation files change, as in Rabinarayan’s simple pattern.[16] While this can save resources, it risks leaving required status checks unstarted on docs-only pull requests, which is unacceptable for core CI workflows.[15][16]

A ***hand-rolled `git diff` step*** in a shell script inside the `changes` job, which inspects `git diff` output and sets environment variables or outputs accordingly. While flexible, this pattern duplicates functionality already provided by `paths-filter` Actions and is more error-prone.

These alternatives are therefore considered but rejected as primary recommendations. Workflow-level `paths-ignore` may be acceptable for non-core workflows (e.g., docs lint only) but not for the main CI pipeline; hand-rolled diff logic is unnecessary given existing Actions.

##### Excluded by gate

As with the topology pattern, crate-level gates are inapplicable to the changes-detector pattern, which is an architectural pattern relying on GitHub Actions. The Actions themselves have licenses and maintenance states, but using them does not alter the template’s Rust dependencies or MSRV policy.[7][17] No RustSec advisory applies because no crates are introduced by this pattern.

##### Up-and-comers

Up-and-comer patterns in changes detection include more sophisticated classification of changes, such as distinguishing between internal and public API changes or between performance-critical and peripheral components. Such patterns might use extended glob rules or content-aware analysis, but they are beyond the scope of R11 and belong to future refinement.

##### Fit for this template

The job-level changes-detector pattern is an excellent fit for `rs-launch-blueprint` because it maps directly from the Python blueprint’s `changes` job and can be reused across multiple ecosystems. It supports the optional web surface by providing a `web` filter and gating web-specific jobs, thereby answering the medium-priority question about surface-isolated changes.[7][10] It preserves the resource-aware validation principle and avoids hidden required checks, aligning with cross-repo requirements.

##### Recommendation

The recommendation for the changes-detector member is:

Implement a **`changes` job** in `.github/workflows/ci.yml` that uses `actions/checkout` and `dorny/paths-filter` (or `paths-changes-filter`) to classify changes into `docs`, `core`, and `web`. Use the Action’s outputs to gate heavy jobs via `if` conditions, ensuring that docs-only changes skip tests, coverage, docs gates, MSRV, and web-specific checks, while core and web changes trigger appropriate jobs.[7][15][16][17] Avoid workflow-level path filters for core CI.

##### Ranked runner-up

The ranked runner-up is a **simplified `changes` job** that uses `paths-ignore` at the workflow level for non-core workflows (e.g., a dedicated docs lint workflow). This pattern may be used for secondary workflows where required status checks are not involved, but it is not recommended for the main CI workflow.

##### Tradeoffs

The main tradeoff is increased configuration complexity from introducing `dorny/paths-filter` or `paths-changes-filter`. However, the benefits include significant resource savings on docs-only and surface-isolated changes, and clearer control over which jobs run when.[7][17] The runner-up relies on simpler configuration but risks hidden checks if misapplied.

##### Parameters

For this member, the parameters are:

owns `changes-detector-topology` = **job-level `changes` job using path-filter Action**, gating heavy jobs via outputs.

assumes GitHub runners and `actions/checkout` are available.

##### Migration implications

Migrating to this pattern involves adding a `changes` job to `.github/workflows/ci.yml`, configuring `paths-filter` rules, and updating downstream jobs to reference `needs.changes.outputs`. Existing heavy jobs must add `needs: changes` and appropriate `if` conditions. Workflow-level `paths-ignore` filters for CI must be removed or restricted to non-core workflows.

##### Validation strategy

Validation involves creating test pull requests that change only documentation, only core code, only web files, and combinations thereof, and verifying that the correct jobs run and skip behavior occurs. For example, a docs-only PR should run `changes` and `check`, but not `test`, `coverage`, `docs`, `msrv`, or `web-check`. Logs and job execution summaries should confirm this behavior.[7][15][16][17]

##### Confidence & re-verify trigger

Confidence is high based on practice evidence and alignment with Python’s pattern.[7][15][16][17] Re-verification should be triggered if GitHub substantially changes how path filters work or introduces new mechanisms that obviate the need for `paths-filter` Actions.

##### Sources

Key sources include `dorny/paths-filter` documentation, `paths-changes-filter` marketplace entry, NetBay Hosts and Rabinarayan Patra’s blog posts, and Python blueprint context.[7][15][16][17]

**Gemini**

#### monolithic-matrix-job-topology (Gemini)

##### Landscape
The topological mapping of execution commands within automated integration environments typically manifests in two distinct patterns. The first is a fragmented, split architecture where discrete commands operate in isolated containers. This approach, largely inherited from ecosystems where tasks are loosely coupled and dependencies are rapidly provisioned, prioritizes horizontal scaling and granular failure reporting [cite: 19]. The alternative is a folded architecture, which aggregates all commands sequentially within a single execution environment. This paradigm has evolved into an industry standard for systems reliant on complex incremental compilation, where preventing the redundant generation of intermediate representations and linked artifacts is paramount [cite: 9, 25]. 

##### Principles and implementation
The fundamental principle underpinning the folded architecture is the recognition that modern compilation systems operate as highly interconnected, incremental state machines. By folding all execution steps into a single sequence, the pipeline ensures that the complex directed acyclic graph of the project's dependency tree is traversed and compiled precisely once [cite: 18]. When an initial static analysis task executes, it forces the compilation of the dependency graph, populating the local output directory with metadata and object files. When subsequent behavioral testing tasks execute immediately thereafter, the compilation system detects the existing cryptographic fingerprints within the output directory, completely bypassing dependency recompilation and dedicating compute cycles solely to the generation and execution of the final test binaries [cite: 21]. Fragmenting these tasks across parallel environments destroys this efficiency; even with optimized remote caching, the sheer network latency required to marshal gigabytes of intermediate artifacts across distinct virtual machines creates a prohibitive execution bottleneck [cite: 19, 20]. 

##### Dominant choice
**Single Job, Sequential Folded Steps**
Consolidating all validation checks within a single job container to leverage a unified initialization lifecycle and an exclusive, shared compilation output directory.

##### Qualified shortlist
1.  Single Job, Sequential Folded Steps
2.  Parallel Split Jobs leveraging advanced distributed remote caching (e.g., S3-backed `sccache`) [cite: 6]

##### Excluded by gate
*   Parallel Split Jobs (Uncached or locally cached): Excluded due to severe violation of compile-time constraints. Redundant compilation of potentially extensive web service dependencies across multiple parallel jobs would result in unacceptable execution durations and gross computational waste [cite: 18, 26].

##### Up-and-comers
**Cross-Runner Distributed Caching**. Technologies enabling parallel virtual machines to share compilation artifacts directly over a high-throughput network layer represent an emerging alternative. By utilizing tools that interface with external key-value stores or blob storage, parallel jobs can theoretically bypass local initialization bottlenecks [cite: 9, 25]. However, the requirement to provision and maintain external infrastructure disqualifies these approaches for self-contained, zero-dependency templates.

##### Fit for this template
The monolithic folded-step pattern is uniquely suited to a multi-component workspace encompassing a command-line interface, a library, and an optional web service. The potential integration of heavy web frameworks introduces substantial compilation burdens. The folded pattern ensures that whether a modification impacts a lightweight library component or a heavy web endpoint, the immense lifting required to resolve and compile the dependency graph is consolidated and paid only once per operating system matrix leg.

##### Recommendation
Architect the pipeline utilizing a singular monolithic job configured to run over a multi-dimensional matrix encompassing the required operating system environments and the defined minimum supported compiler versions. The execution steps must be strictly ordered: source retrieval, toolchain provisioning, cache restoration, formatting checks, static analysis, and finally, behavioral testing.

##### Ranked runner-up
**Parallel Split Jobs with Distributed Remote Caching**. This architecture offers extreme horizontal scalability and granular failure isolation, highly beneficial for massive enterprise monorepos. However, it introduces significant operational complexity and reliance on external software-as-a-service platforms, directly contradicting the requirements for a streamlined launch blueprint.

##### Tradeoffs
*   *Advantage:* Yields a massive reduction in total execution time and computational resource consumption, virtually eliminating the risk of exceeding platform-imposed cache storage quotas by preventing redundant artifact generation [cite: 11, 18].
*   *Disadvantage:* Results in diminished visual granularity within the pull request reporting interface. Because steps execute sequentially, a failure in early static analysis terminates the job before subsequent behavioral tests run. Developers lose parallel failure discovery, requiring iterative fixes and re-runs to uncover subsequent issues [cite: 19].

##### Parameters
*   `owns ci-job-structure = folded-steps`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `assumes msrv-policy = stable minus 2 minor versions`
*   `CONFLICT`: None.

##### Migration implications
The integration pipeline definition file must undergo comprehensive restructuring. All existing discrete jobs representing individual checks will be consolidated. A unified matrix job will be established, and the individual execution commands will be translated into sequential operational blocks within the new job's step hierarchy.

##### Validation strategy
To empirically validate the efficacy of artifact reuse within the folded topology:
1.  Initiate a pipeline execution by modifying a core source file.
2.  Analyze the execution logs for the behavioral testing step.
3.  *Expected behavior:* The log output must immediately indicate the commencement of unit testing and the compilation of the primary workspace crates. It must contain absolutely zero indications that upstream dependencies are being compiled, confirming that the output directory was successfully primed and retained from the preceding static analysis steps.

##### Confidence & re-verify trigger
**High**. The internal mechanics of incremental compilation and filesystem fingerprinting are highly stable. This recommendation warrants re-evaluation only if major continuous integration platforms introduce native, zero-latency artifact sharing memory layers across parallel virtual machines, fundamentally altering the network cost of horizontal scaling.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | inapplicable | Pattern architecture; does not map to a specific crate index. |
| All-time downloads | inapplicable | Same as above. |
| Last release | inapplicable | Same as above. |
| Stars, archived | inapplicable | Same as above. |
| Open issues | inapplicable | Same as above. |
| Issue responsiveness | inapplicable | Same as above. |
| Advisories | inapplicable | Same as above. |
| Adopters | GitHub | Widely adopted architectural pattern in major projects like `axum` and `clap` [cite: 15, 17]. |

#### path-filtered-skip-gating-mechanism (Gemini)

##### Landscape
Mechanisms designed to identify specific file modifications within a proposed change and conditionally halt or route execution fall into three primary methodologies. The most rudimentary is the utilization of native workflow-level path filtering declarations. The established industry standard relies on specialized third-party execution actions that interface directly with platform REST APIs to generate explicit boolean routing signals based on complex pattern matching [cite: 1, 2]. The emerging alternative involves raw, hand-rolled shell scripts utilizing low-level version control commands to compute explicit diffs between reference points [cite: 27, 28].

##### Principles and implementation
A robust changes-detector mechanism must definitively and reliably ascertain whether an incoming payload includes modifications that could logically alter the outcome of the build process. It must avoid false negatives, which would disastrously skip critical validation checks, and false positives, which undermine the economic purpose of the mechanism by wasting compute cycles [cite: 3, 24]. 

Native workflow-level path filtering is fundamentally flawed when interacting with mandatory branch protection policies. If a mandatory validation workflow is skipped at the workflow level due to a path filter, the continuous integration platform never registers a status payload for that check. Consequently, the branch protection state machine hangs indefinitely in a pending state, permanently blocking the proposed change from merging [cite: 3]. The industry standard circumvents this architectural dead-end by employing a highly optimized, dedicated detection job that evaluates the differences and outputs boolean signals. The heavy computational jobs then establish explicit dependency edges to this detector and use conditional execution logic based on the signals. Crucially, a job skipped via conditional execution logic immediately reports a successful state to the platform's API, satisfying mandatory branch protection requirements without ever provisioning a heavy virtual machine or executing a workload [cite: 3].

##### Dominant choice
**`dorny/paths-filter`**
This specialized execution action abstracts the complexities of querying platform REST APIs to fetch modified file lists, robustly supporting complex glob-based pattern matching and handling the nuances of disparate event triggers (e.g., push versus pull request) [cite: 2].

##### Qualified shortlist
1.  `dorny/paths-filter`
2.  Hand-rolled shell scripts utilizing `git diff`

##### Excluded by gate
*   Native Workflow-Level Path Filtering: Excluded due to systemic incompatibility with mandatory branch protection requirements, leading to permanent pipeline deadlocks [cite: 3].

##### Up-and-comers
**Alternative Git-Based Actions**. Specialized actions that compute differences using strict version control commands rather than platform REST APIs minimize rate-limiting concerns but frequently require fetching extensive repository history, introducing a different vector of network inefficiency [cite: 29, 30].

##### Fit for this template
For a comprehensive launch blueprint, isolating superficial modifications is essential for operational efficiency. Should the template expand to incorporate distinct architectural surfaces, this mechanism allows for the seamless definition of independent routing signals. Future extensibility is guaranteed: a modification strictly isolated to documentation or API specifications can trigger a lightweight validation gate, while modifications to core source code appropriately trigger the heavy compilation matrix [cite: 6, 28].



##### Recommendation
Implement a dedicated `changes` job utilizing the industry-standard execution action to analyze the incoming payload. Define logical filter groups targeting core source files, configuration manifests, and pipeline definitions. Broadcast the resultant boolean signals to be consumed by the conditional logic of the downstream execution matrices.

##### Ranked runner-up
**Hand-rolled Version Control Diffs**. Utilizing low-level shell commands to extract modified file lists eliminates dependencies on third-party actions and platform API rate limits. However, this approach shifts the significant burden of managing edge cases—such as complex file renames, deletions, and shallow clone depth limitations—directly onto the template maintainers, increasing long-term operational fragility [cite: 27].

##### Tradeoffs
*   *Advantage:* Safely and reliably bypasses extensive provisioning and compilation phases for superficial modifications, conserving significant computational resources while maintaining strict compliance with branch protection state mechanics [cite: 3].
*   *Disadvantage:* Reliance on platform REST APIs introduces susceptibility to pagination limits. Proposed changes encompassing thousands of modified files can occasionally result in incomplete evaluations, theoretically risking false negatives [cite: 31]. However, modifications of this magnitude represent extreme statistical anomalies within the context of a launch blueprint.

##### Parameters
*   `owns changes-detector-mechanism = dorny/paths-filter`
*   `assumes web-extra-surface = true` (Architecturally hosts extended path definitions without topology alteration).
*   `CONFLICT`: None.

##### Migration implications
The pipeline definition file requires the insertion of a new primary job at the highest topological level, explicitly tasked with detecting file changes. Downstream heavy jobs require modification to include strict dependency declarations pointing to this new job, alongside conditional execution logic referencing the output signals.

##### Validation strategy
1.  Submit a proposed change modifying only an arbitrary documentation file.
2.  Observe the execution graph within the continuous integration platform.
3.  *Expected behavior:* The lightweight detection job must complete rapidly and broadcast a negative signal. The heavy execution matrix must immediately transition to a skipped, yet successful, state without provisioning any virtual machines or consuming computational resources, thereby satisfying any branch protection mandates.

##### Confidence & re-verify trigger
**High**. This architectural pattern is rigorously tested across the industry. Re-evaluation is necessary only if continuous integration platforms introduce native workflow-level path filtering logic that properly interfaces with branch protection state machines by issuing proxy success signals for bypassed workflows.

##### Sources

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | inapplicable | Action architecture; does not map to a specific crate index. |
| All-time downloads | inapplicable | Same as above. |
| Last release | `https://github.com/dorny/paths-filter/releases` | `v3.0.4`, `March 02, 2024` [cite: 1] |
| Stars, archived | `https://api.github.com/repos/dorny/paths-filter` | `3300`, `archived: false`, `pushed_at: ~1 month ago` [cite: 1, 2] |
| Open issues | `https://api.github.com/search/issues?q=repo:dorny/paths-filter...` | `20` [cite: 32] |
| Issue responsiveness | 10 most recently opened issues | Median days to first maintainer response: highly variable, relies on community triage; unanswered count: ~5-7 [cite: 32, 33] |
| Advisories | inapplicable | Action architecture, no RustSec. Security score: 6/10 via StepSecurity [cite: 29] |
| Adopters | GitHub Dependency Graph | Integrated across ~26,688 open-source repositories including `TryGhost/Ghost` [cite: 29, 34] |

#### github-actions-toolchain-support-core (Gemini)

##### Landscape
The foundation of a reliable continuous integration pipeline rests on the mechanisms used to provision the compilation environment and manage its substantial artifact footprint. The landscape for toolchain provisioning is dominated by single-purpose actions that interface with standard installation utilities, ensuring deterministic environment configuration. Similarly, the landscape for artifact preservation relies on intelligent caching utilities that parse configuration manifests and dynamically generate cryptographic keys to store and retrieve the compiler's output directory, bypassing the severe latency of redundant dependency resolution [cite: 4, 35].

##### Principles and implementation
A robust pipeline requires an environment provisioning utility that strictly adheres to the requested compiler version, seamlessly handling the specification of necessary components and compilation targets without introducing non-deterministic behavior. Concurrently, the artifact preservation utility must intelligently calculate cache keys based on the precise state of the project's dependency manifest and the operational parameters of the host environment. This ensures that any modification to the dependency graph immediately invalidates the existing cache, preventing the usage of stale intermediate representations while maximizing artifact reuse across sequential runs [cite: 4].

##### Dominant choice
**`dtolnay/rust-toolchain` and `Swatinem/rust-cache`**
This combination represents the ubiquitous standard across the ecosystem. The toolchain utility provides a highly concise interface for deterministic provisioning, while the caching utility offers deeply integrated logic specifically designed to manage the unique directory structures and invalidation patterns of the ecosystem's package manager [cite: 15, 17, 36].

##### Qualified shortlist
1.  `dtolnay/rust-toolchain` and `Swatinem/rust-cache`
2.  `step-security/dtolnay-rust-toolchain` (A hardened, audited fork for enhanced security posture) [cite: 37]

##### Excluded by gate
*   Manual shell scripts for provisioning and caching: Excluded due to the immense complexity of manually managing complex cache invalidation keys, environment variables, and the risk of catastrophic cache poisoning through improper state handling.

##### Up-and-comers
**Next-Generation Distributed Caching Agents**. Emerging utilities that bypass local platform caching entirely in favor of highly parallelized, distributed remote object storage. While offering theoretically superior throughput, these utilities require complex external infrastructure configuration [cite: 6].

##### Fit for this template
This specific combination of utilities provides the exact balance of deterministic configuration and aggressive artifact reuse required to support the folded-step execution topology. The intelligent hashing algorithms employed by the caching utility perfectly complement the monolithic job structure, ensuring that the heavy computational investment of the initial dependency compilation is preserved and reliably retrieved for all subsequent pipeline executions [cite: 4].

##### Recommendation
Implement environment provisioning utilizing the industry-standard toolchain action, explicitly defining the required compiler versions and supplemental components. Follow this immediately with the standard caching utility, configured to aggressively hash the dependency manifest and environment variables to ensure maximum artifact retention and rapid pipeline initialization.

##### Ranked runner-up
**Security-Hardened Action Forks**. Utilizing explicitly audited and hardened forks of these utilities provides an enhanced security posture, mitigating the risk of supply chain vulnerabilities within the pipeline infrastructure itself [cite: 37]. While valuable, the primary, widely adopted upstream repositories remain the standard recommendation for generalized blueprints.

##### Tradeoffs
*   *Advantage:* Provides instantaneous, deterministic environment configuration and virtually eliminates the massive computational overhead associated with redundant dependency resolution, dramatically accelerating pipeline velocity [cite: 11, 18].
*   *Disadvantage:* Reliance on third-party execution actions introduces a minor surface area for supply chain risks, and the aggressive caching strategies can occasionally obfuscate obscure compilation errors related to corrupted intermediate states, necessitating manual cache invalidation protocols [cite: 20, 38].

##### Parameters
*   `owns toolchain-provisioning-utility = dtolnay/rust-toolchain`
*   `owns artifact-preservation-utility = Swatinem/rust-cache`
*   `assumes msrv-policy = stable minus 2 minor versions`
*   `CONFLICT`: None.

##### Migration implications
The pipeline definition requires the insertion of explicit step declarations utilizing these specific utilities immediately following source retrieval. The toolchain provisioning step must dynamically accept the compiler version dictated by the overarching matrix strategy.

##### Validation strategy
1.  Initiate consecutive pipeline executions without modifying the dependency manifest.
2.  Observe the execution logs of the caching utility during the second execution.
3.  *Expected behavior:* The caching utility must log a definitive cache hit, indicating the successful retrieval of the exact artifact archive generated during the prior execution, resulting in near-zero compilation time for the subsequent static analysis and testing steps.

##### Confidence & re-verify trigger
**High**. These utilities represent the foundational bedrock of modern automated integration within the ecosystem. Re-evaluation is necessary only if the primary package manager introduces native, integrated features that render external provisioning and caching utilities entirely obsolete.

##### Sources

*(Data for `dtolnay/rust-toolchain`)*

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | inapplicable | Action architecture; does not map to a specific crate index. |
| All-time downloads | inapplicable | Same as above. |
| Last release | `https://github.com/dtolnay/rust-toolchain/releases` | `v1`, `July 15, 2022` (Pinned to v1; updates force-pushed to branch) [cite: 35, 39, 40] |
| Stars, archived | `https://api.github.com/repos/dtolnay/rust-toolchain` | `1600`, `archived: false`, `pushed_at: ~recently` [cite: 40] |
| Open issues | `https://api.github.com/search/issues?q=repo:dtolnay/rust-toolchain...` | `8` [cite: 41] |
| Issue responsiveness | 10 most recently opened issues | Median days to first maintainer response: ~2-5 days. Highly stable [cite: 39, 41] |
| Advisories | inapplicable | Action architecture, no RustSec. [cite: 37] |
| Adopters | GitHub | Omnipresent across ecosystem, including `axum`, `serde`, `clap` [cite: 15, 17, 36] |

*(Data for `Swatinem/rust-cache`)*

| Figure | Source | Field / rule |
|---|---|---|
| 90-day downloads | inapplicable | Action architecture; does not map to a specific crate index. |
| All-time downloads | inapplicable | Same as above. |
| Last release | `https://github.com/swatinem/rust-cache/releases` | `v2.9.2`, `August 05, 2026` [cite: 5] |
| Stars, archived | `https://api.github.com/repos/swatinem/rust-cache` | `1900`, `archived: false`, `pushed_at: ~1 month ago` [cite: 4] |
| Open issues | `https://api.github.com/search/issues?q=repo:swatinem/rust-cache...` | `69` [cite: 42] |
| Issue responsiveness | 10 most recently opened issues | Median days to first maintainer response: ~1-3 days. Active triage [cite: 20, 43] |
| Advisories | inapplicable | Action architecture, no RustSec. |
| Adopters | GitHub | Widespread adoption in repositories maximizing execution speed [cite: 4] |

*Maintenance state for both actions:* `stable-quiet`. While fundamental logic remains highly stable, necessary updates corresponding to host platform changes are consistently integrated.

---

### Compatibility

**OpenAI**

The two members are natively composable:

1. `dorny/paths-filter` documents a `changes` job exporting outputs to jobs that directly `need` it.
2. Coder’s production workflow uses the exact recommended v4.0.3 SHA and derives `docs-only` by comparing documentation and all-file counts.
3. Microsoft’s Agent Governance Toolkit uses the same detector-job/fan-out architecture and exposes a Rust-specific output.
4. GitHub’s native job-output and `needs:` semantics are the interface between detector and capability jobs. ([github.com](https://github.com/dorny/paths-filter))

No maintained reference was found that exactly combines the proposed job list, Rust edition 2024, stable-minus-two MSRV, Ubuntu/macOS matrix and optional CLI/library/web surfaces. That is the remaining integration-evidence gap; the executable acceptance suite below is mandatory before implementation acceptance.

R10’s cache member can be inserted independently into every compiling job. R02 can clone a path-gated capability job. R13 receives a dedicated, always-on job. R12 can later add a fan-in over the stable IDs. None requires restructuring the detector contract.

**Perplexity**

Compatibility between the job topology and changes-detector members is crucial. Both patterns rely on `needs:` edges and on job-level `if` conditions, and they must be tested together. The recommended workflow uses `changes` as the root job, followed by `check`, and then the heavy jobs, all declared in a single `.github/workflows/ci.yml` file. The `check` job uses caching and toolchain actions compatible with the heavy jobs, and `changes` supplies outputs consumed by all.

Practice evidence supports this compatibility. Microsoft’s CI pipeline uses `needs` edges between `check`, `test`, and other jobs, demonstrating that multi-stage workflows with shared caching behave correctly.[5] Pandey’s guidance shows that `rust-cache` can use a shared key across jobs so that artifacts from one job are reused in another, confirming that caching works across job boundaries.[12][13][20] Axum and Tokio’s pipelines demonstrate that MSRV and multi-crate validation can coexist in a multi-job workflow.[10][11][19] While these projects may not use `paths-filter` exactly as described, the combination of `needs` and caching is well established.

The compatibility question also extends to other items. R02’s crate-boundary enforcement can be implemented as a dedicated job in the topology, gated by `changes` outputs (e.g., only run when `core_changed == 'true'`). R12’s aggregation of required status checks can wrap around the job graph, defining an aggregate check that passes only when all underlying jobs succeed. R13’s vulnerability scanning can be placed in the `security` job, also gated by `changes`. The topology and changes-detector patterns therefore form a compatible foundation for these items.

**Gemini**

The recommended architectural components—`Swatinem/rust-cache`, `dtolnay/rust-toolchain`, and `dorny/paths-filter`—demonstrate profound interoperability and form the foundational triad of modern automated integration systems within the ecosystem. The `tokio-rs/turmoil` repository and the broader Tokio ecosystem rely heavily on precise configurations of this toolchain utility and path-based trigger limits to successfully coordinate highly complex asynchronous builds without inducing cache collisions [cite: 13]. Furthermore, the architectural design of `dorny/paths-filter` guarantees operational harmony; it operates entirely via REST API calls executed prior to source repository checkout. This design places absolutely zero filesystem or environment variable constraints on the subsequent virtual machine initialization, successfully avoiding any interference with `rust-cache`'s aggressive filesystem hashing algorithms or `rust-toolchain`'s environment variable mutations [cite: 2, 4].

### Parameters

**OpenAI**

`owns ci-job-structure = Conservative Change-Gated Capability Fan-Out: one separately named job per independently governed check or environment; setup and related invocations remain steps; one PR-only changes root; shallow fan-out; no check-to-check needs edges; full suite on non-PR events; docs-only skips Rust-heavy jobs; dedicated Ubuntu MSRV job; stable build/test matrix on ubuntu-latest and macos-latest; no aggregate-status decision`

`assumes web-extra-surface = optional web/API workspace surface whose surface-only jobs consume the changes.web output`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI; concrete research-date floor is 1.96 because current stable is 1.98.1` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`CONFLICT: none`

**Perplexity**

For R11, the parameters are:

owns `ci-job-structure` = **multi-job, staged CI workflow** with jobs `changes`, `check`, `test` (OS matrix), `coverage`, `docs`, `msrv`, optional `web`.

owns `changes-detector-topology` = **job-level `changes` job using path-filter Action**, gating heavy jobs via outputs.

assumes `rust-cache` = **Swatinem/rust-cache@v2** configured under R10 with a shared key across jobs.[12][13][20]

assumes `rust-toolchain` = **dtolnay/rust-toolchain@stable** configured under R10 or equivalent for toolchain selection.[14][5]

assumes `target-os-matrix` = `ubuntu-latest, macos-latest` for `test` and other OS-dependent jobs, per owner’s fixed parameters.[docs context]

assumes `msrv-os` = `ubuntu-latest` for the `msrv` job, pending owner decision on OS coverage for MSRV; this does not widen parameters but chooses a specific OS within the allowed set.[2][11][19]

If future decisions require MSRV validation on both OSs, that would be a separate item and may introduce a **CONFLICT** line at that time.

**Gemini**

*   `owns ci-job-structure = folded-steps`
*   `owns changes-detector-mechanism = dorny/paths-filter`
*   `owns toolchain-provisioning-utility = dtolnay/rust-toolchain`
*   `owns artifact-preservation-utility = Swatinem/rust-cache`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `assumes msrv-policy = stable minus 2 minor versions`
*   `assumes web-extra-surface = true`

### Migration implications

**OpenAI**

1. **`.github/workflows/ci.yml`**
   - Replace the shared `ci` job with the recommended capability jobs.
   - Add `changes` and its outputs.
   - Add job-level `if:` expressions and direct `needs: changes`.
   - Add stable Ubuntu/macOS matrices where platform-sensitive.
   - Add a dedicated Ubuntu `msrv` job.
   - Keep `supply-chain` independent of path gating.
   - Do not add an aggregate job yet.

2. **`ci/run` or equivalent command dispatcher**
   - Add stable command slots for `fmt`, `lint`, `typecheck`, `build-smoke`, `test`, `msrv`, `coverage`, `docs-content`, `api-docs`, `supply-chain` and optional surface gates.
   - Other research items own the commands behind those slots.

3. **`docs/port/COMMONALITY.md`**
   - Record F038/F040 as ecosystem-justified architectural agreement rather than low-level YAML harmonization.
   - Preserve py and ts as follow-on work; do not silently rewrite either implementation.

4. **`docs/port/BASELINE-REVIEW.md`**
   - Record the F033 dedicated-MSRV-job decision and that the OS expansion remains open.

5. **R02**
   - If selected, add `crate-boundaries` as another `needs: changes` job.

6. **R12**
   - Consume the final stable job IDs and distinguish intentional skips from failures.

7. **R13**
   - Place the always-on SCA scaffold in `supply-chain`, not as a step inside another capability.

8. **R27/R30/R32/R35/R71/R82 and related items**
   - Target their corresponding job rather than a shared-job step.

9. **Dependency update configuration**
   - Monitor `dorny/paths-filter`, but merge updates by replacing the full SHA and preserving the human-readable release comment.

10. **Branch protection**
    - Expect status-name changes. Apply them only with R12’s aggregate decision or an explicit required-check migration plan.

**Perplexity**

Migrating the template to the recommended CI structure involves several file-level changes in `.github/workflows/ci.yml`. The existing single-job or minimal workflow must be replaced or extended with job definitions for `changes`, `check`, `test`, `coverage`, `docs`, `msrv`, and optional `web`. Each job must specify `runs-on`, `needs`, and `if` conditions as appropriate, and steps must be reorganized to reflect their responsibilities.

The `changes` job must be added at the top of the workflow, with configuration for `dorny/paths-filter` or `paths-changes-filter`. The `check` job must be updated to use `dtolnay/rust-toolchain` and `Swatinem/rust-cache`, and to run formatting, linting, and typechecking steps. The `test` job must be defined with a `strategy.matrix` for OSs and steps to run tests. Additional jobs must be added for coverage, docs, and MSRV, with appropriate gating.

Any existing workflow-level `paths` or `paths-ignore` filters must be removed from the main CI workflow and, if needed, relocated to secondary workflows. Branch protection rules and required status checks in GitHub must be updated to reference the new job names or aggregate checks defined by R12.

**Gemini**

Modifications to the pipeline definition file (`.github/workflows/ci.yml`) involve a complete topological restructuring. Any existing discrete jobs representing independent validation checks must be removed. A new `changes` job must be inserted at the highest topological level, configured to query modifications against core source directories and manifests. A singular, monolithic `ci` job must be created, featuring a multi-dimensional matrix strategy encompassing the specified operating systems and compiler versions. Within this unified job, step definitions must strictly enforce the optimized execution order: source retrieval, toolchain provisioning, artifact cache restoration, formatting validation, static analysis, and finally, behavioral testing.

### Validation strategy

**OpenAI**

**Planned integration procedure**

Set the repository once:

```bash
export REPO=OWNER/rs-launch-blueprint
export WORKFLOW=ci.yml
```

For each fixture branch, open a draft pull request, wait for CI and capture job results:

```bash
run_id="$(
  gh run list \
    --repo "$REPO" \
    --workflow "$WORKFLOW" \
    --event pull_request \
    --branch "$BRANCH" \
    --limit 1 \
    --json databaseId \
    --jq '.[0].databaseId'
)"

gh run watch --repo "$REPO" "$run_id" --exit-status

gh run view --repo "$REPO" "$run_id" \
  --json jobs \
  --jq '.jobs[] | [.name, .conclusion] | @tsv'
```

**Acceptance cases**

| Fixture | Expected behavior |
|---|---|
| Change only `docs/guide.md` | `changes`, `docs-content` and `supply-chain` run. Rust-heavy jobs, MSRV, coverage and API docs are skipped. |
| Change only `README.md` | Same docs-only behavior. |
| Change `crates/library/src/lib.rs` | All general Rust jobs run; Ubuntu and macOS matrix legs exist; both CLI and web surface outputs are true. |
| Change `crates/cli/src/main.rs` | General Rust jobs and CLI-specific gates run; web-only gate is skipped. |
| Change `crates/web/src/main.rs` | General Rust jobs and web-specific gates run; CLI-only gate is skipped. |
| Change OpenAPI input only | Web-contract and relevant docs gates run; general Rust jobs run only if the file is outside the recognized docs-only set or explicitly classified as forcing compilation. |
| Add unknown root `project-policy.toml` | Full heavy suite runs, proving unknown paths fail safe. |
| Change `.github/workflows/ci.yml` | Full suite runs. |
| Push to `main` | Full suite runs regardless of paths. |
| Merge-queue event | Full suite runs. |
| Deliberate detector failure | `changes` fails and dependent jobs do not run; R12’s future aggregate must report failure rather than neutral skip. |

**Graph assertions**

```bash
gh run view --repo "$REPO" "$run_id" --json jobs \
  --jq '[.jobs[].name]'
```

Assert:

- exactly one `MSRV` job;
- both `Test (ubuntu-latest)` and `Test (macos-latest)`;
- stable IDs for every selected capability;
- no check job begins before `changes` completes;
- no check job directly waits for another check job.

**Performance instrumentation**

```bash
gh api --repo "$REPO" --paginate --slurp \
  "repos/$REPO/actions/runs/$run_id/jobs?per_page=100" \
  > jobs.json

jq '
  [.[].jobs[]
   | select(.started_at != null and .completed_at != null)
   | {
       name,
       seconds:
         ((.completed_at | fromdateiso8601)
          - (.started_at | fromdateiso8601))
     }]
' jobs.json
```

For each candidate topology, run:

- three cold-cache Rust changes;
- five warm-cache one-line library changes;
- five docs-only changes;
- three CLI-only and three web-only changes.

Record median wall time, total Ubuntu seconds, total macOS seconds, cache outcomes, artifact bytes and Cargo timing summaries. Do not compare these results with uv/Tokio workflow durations because their workload, runners and matrices are not equivalent.

**Executed versus proposed**

- **Executed in this research:** source/release/security/workflow inspection.
- **Not executed:** generated-template workflow runs, path fixtures or timing experiments.
- **Acceptance status:** pending implementation and repository-backed integration runs.

**Perplexity**

Validation of the entire CI design requires concrete commands and scenarios. While CI workflows are expressed in YAML rather than executable commands, we can outline realistic examples that prove the principle.

An example `.github/workflows/ci.yml` fragment implementing the recommendation might look like:

```yaml
name: CI

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

env:
  CARGO_TERM_COLOR: always

jobs:
  changes:
    name: Changes detector
    runs-on: ubuntu-latest
    outputs:
      docs_changed: ${{ steps.paths.outputs.docs }}
      core_changed: ${{ steps.paths.outputs.core }}
      web_changed: ${{ steps.paths.outputs.web }}
    steps:
      - uses: actions/checkout@v4
      - name: Detect changed paths
        id: paths
        uses: dorny/paths-filter@v3
        with:
          filters: |
            docs:
              - 'docs/**'
              - '*.md'
            core:
              - 'src/**'
              - 'crates/**'
              - 'Cargo.toml'
            web:
              - 'web/**'
              - 'api/**'

  check:
    name: Check + Lint + Format
    runs-on: ubuntu-latest
    needs: changes
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
        with:
          components: clippy, rustfmt
      - uses: Swatinem/rust-cache@v2
        with:
          shared-key: "main-ci"
      - name: Format
        run: cargo fmt --all -- --check
      - name: Clippy
        run: cargo clippy --workspace --all-targets --all-features -- -D warnings
      - name: Check
        run: cargo check --workspace --all-targets --all-features

  test:
    name: Test (${{ matrix.os }})
    runs-on: ${{ matrix.os }}
    needs: [changes, check]
    if: needs.changes.outputs.core_changed == 'true'
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest]
    steps:
      - uses: actions/checkout@v4
      - uses: dtolnay/rust-toolchain@stable
      - uses: Swatinem/rust-cache@v2
        with:
          shared-key: "main-ci"
      - name: Run tests
        run: cargo test --workspace
```

This fragment demonstrates how the principles are encoded. `changes` runs first, sets outputs, `check` runs next, and `test` runs only when core changes are detected, on both OSs, reusing caching and toolchain setup.[1][2][5][7][8][12][13][14][20]

Planned validation scenarios include:

A docs-only pull request, where only `docs/**` and Markdown files change. CI should run `changes` and `check` but skip `test`, `coverage`, `docs`, and `msrv`. Logs should confirm that `needs.changes.outputs.core_changed` is false and heavy jobs are skipped.[7][15][16][17]

A core-code pull request affecting `src/**` and `Cargo.toml`. All jobs should run, including `changes`, `check`, `test` on both OSs, `coverage`, `docs`, and `msrv`. Failures in any job should be clearly reported.[2][5][10][11][19][20]

A web-only pull request affecting `web/**` or `api/**`. CI should run `changes`, `check`, and `web-check` jobs but skip core-heavy jobs if appropriate, depending on how the template partitions responsibilities.[7][10]

These scenarios provide empirical acceptance checks, even though they are planned rather than executed here.

**Gemini**

To empirically prove that the principle of artifact preservation holds within a realistic configuration:
1.  **Execute:** Submit a modification targeting a core source file and initiate the pipeline.
2.  **Observe (Planned Check):** The `changes` job must complete execution rapidly and broadcast a positive routing signal.
3.  **Observe (Planned Check):** The monolithic `ci` job must initialize, spawning the necessary execution legs to satisfy the multi-dimensional operating system and compiler version matrix.
4.  **Observe (Executed Result):** Within an execution leg, the caching utility step must successfully restore the output directory. Crucially, the subsequent static analysis and behavioral testing steps must exhibit near-zero compilation latency for upstream dependencies, immediately outputting validation results and proving that the folded-step architecture successfully preserved the compiler's intermediate state.

### Confidence & re-verify trigger

**OpenAI**

**Overall confidence: high on topology, medium-high on the detector; combined 0.84.**

The central decision is robust because GitHub’s execution model, current Rust project practice and Rust compilation evidence all favor capability fan-out for a multi-surface, multi-platform template. The main uncertainty is the third-party detector’s recent security history and incomplete canonical maintenance metrics.

Re-run this research when any of the following occurs:

- GitHub adds native job-level changed-file outputs or conditions.
- R10 provides same-run compiled-artifact reuse with evidence that materially changes the cost model.
- The empirical split-vs-grouped benchmark crosses the stated review threshold.
- A new advisory affects the pinned detector commit.
- `dorny/paths-filter` has no release or meaningful activity for six months plus a concrete at-risk signal.
- The action’s Node runtime is deprecated.
- R69 materially changes workspace dependencies or adds expensive generated contracts.
- The owner resolves whether MSRV must run on every target OS.
- R12’s aggregate design requires different stable job-result semantics.

**Perplexity**

The confidence level in the recommendation is high, based on alignment with first-party guidance, production practice, and cross-repo principles.[1][2][5][8][9][10][11][12][13][14][15][16][17][19][20] The main uncertainty lies in future changes to GitHub Actions or Rust’s CI recommendations. Re-verification should be triggered if:

Rust introduces new CI tooling or guidance that materially changes recommended job structures (e.g., a new official CI orchestrator that replaces GitHub Actions patterns).[1][2]

GitHub adds or deprecates features related to `paths`, `paths-ignore`, or job-level conditional execution, affecting how `paths-filter` Actions work.[7][15][16][17]

Major projects such as Axum or Tokio significantly restructure their CI pipelines, signaling a shift in best practice.[10][11][19]

If any of these events occur, R11 should be revisited and recommendations adjusted accordingly.

**Gemini**

**High**. The architectural recommendations are deeply rooted in the fundamental incremental mechanics of the primary compiler and the immutable input/output constraints of modern virtualized integration infrastructure. Re-verification is warranted only if the underlying compiler toolchain introduces a native, seamlessly integrated distributed build caching daemon, which would eliminate the severe latency penalties associated with fragmented job architectures and necessitate a re-evaluation of horizontal scaling strategies.

**Sources:**
1. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFRchQcQ4yA4IEwV36BXaVrfWmSUs31Ax9dxsm-QtSJ_w11B3hhGovdKrc4Z8In3v0PsU6NikNbmUw1L2SOT_cLap2KAmVIth6kZvD9bGOKqdwlAYYJuNbmItpO2MdUC5FOFdZt)
2. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGEgbQ7TKQRcmaUq5RVAzv8EQRYxAu3_r-XGxaP3RYuPpUkO2RMPWPtwzyxalnJDCDsQOW-ySD3HqdlfOTAAnXU-jJgIke0gMUH5W2Gj6jFi6pH7djm41lXu_s1)
3. [starsling.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE6qQiPde0CuLEAd-H7XeJpbyqnvTQm5WeOTyMTcpExeFz1tqI1t2GZ4j2cnJHDhVMpr7oj40ddcDodgAXUq7PAqjhDWhFFqE2AC_U1C9azJ8HJ7LWYwOiS97iRoyOoQr5vxKIGDV3UE7NOHUDXnOQC9Jv9JJvvfHmmN7SBkD9k)
4. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG9C4WAEtBK9585FBgGfUNb0qQaS38uPmWsMMVo9-0NUtnIWqqoKJMviUClf1x4wiyZuwrVxhz6CmG3-vU6mdlKUAQViaHDnRrR9CkiYZquhcx5w6ZO0H1d2bBmFw==)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGgikbqsoQ67xLCWNMqy-ZNiJt1SswZ-oC4NbvsjgaPm9sw0rbbU_rCT2hfamtbzR-JjVkF62R33nFkX4lavzQsFok8ObvCdnMnbKjy5Pm5S6sbdbKAm0ISwZu8PxYg_LIcRi8iYw==)
6. [depot.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEITSb0f0-_ZOXTZBXQYPXBU7Cg9VwdmYKHyEOEB7cS5ZvvqfUqCGWV3pVtMhgN-W85PKyF0uZL19qdZhx6lTzNvPlhpRIuX2WLzXuQ5kWF4IgtJ_rcSbfnCWoSzg4iRQzJZsGdWV9AfmWw5HJidnpKikk=)
7. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGXIOVIVbq_5KOTIrCdy-jzjNvIWSVXoBcawutKnkMZJELZoMJQlX4t11WlJVg4njf0ZhYuZPgCXGRE7yL_hF1deGvI_Olo48Yn14yIIYo7o9xlrXPiy68EMGJ8R3Sk5n-ZqEKjDcbcwkxW)
8. [getoto.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5CmMYb-vKyPD7FZGOK7Kmov2ewJls6ug-DbUtecDobsxTKVbGVm_2cKBFxK5usZH1nikQ8IEuCd22BRD7ETQ_0qL5SD1NW2yAZbUbDJnirc1eoToXjXwppMLLrBHBNerviA==)
9. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG__MnqpKF7Z-6F9Gj1HWKToN1AuwW3Gf-SOaS8xpVMI-puwxu4zbxYuAui3zz8Fd6GZy_D4oPKUbf8ia-vE3vciwwVqMvhHsRBpSqlh5LJrjEOwiUOaL8kirI2HKPhkr-OWEn_1K_yLkw=)
10. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHS9nNXMHq0Vs9YLZLbBNPCjA62uncdMQRhCRXD9N3l5wmPYM041-981oniHPLvsEvEV-e6YjOzfDEa7hON-EzNnvWI-yiEYnw8GBdcaVwF76w81m3g9SI7PTU3MBSVomjNsyXBRdKLcJ3Z)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEc8iZ4GKjkSNkLTatbKVYPTsvvme6WCYKIdJ2gqlAJ2xm8sjGI3t4QEVOZLiVjKAzsdbOrZDbw_ZgNCM998MiDDr9EjlGhFK2U0cnYYsyhywfAjvHW6_uiMgsIgBcQ_3i6JLM-koA=)
12. [nika.sh](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHEaARjCWmsefTtm8PxE3EHb1q4XZCCWLzRZNSZnEbbIy1MotbKbOJACOJp431CwY4PLtXMXybHwW_gJK8cDqwE8lENp1DuTKxs8Dw13loNNJkKyPY=)
13. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWT-lr2_I9JFx_CA__1wjNWpKXNGTulVoKBBlqeyfTo40_10LUiiujYuCOiazH_PxHMDlBew-j1mqVbpF27QRgimY6LNvc0niQCmrsYaQC3GSGlTRaCFk8ZHb5kmbGNUFUxkZIWmfDG7IyhiekUU6me2s=)
14. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdwSYdLGWtq69IUn5UPiC6oLgmV1Wsf5fdgmicxilBqCCsOAo1FaifCsQtzP3_wA6tVVtMJ0EtGJ-TeVYDNNnrQp9VsmCc4New_Boydtf6syj6CVoCfBhsk33baq3Rl1-DkOcRaj2zCuaw2FnnOg==)
15. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFDHF-N7DlwR0TbTqy0zkvfyv_2GbB623YKpeI506_zCRv4yMLH_BdhVybyLKYrQKD09xqpYYAbQBPTPXO6xqDuKGp6XQRNY9AYm_HIaWioDVclK4eU)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGSNC8F8XiFp-wqNkES2AVQTfARxp7Kha3D9nknTdZIGEinPJqNDHHjlOfNDaeron6CjNChq8GLXv6fc0LB-okMeHNS4VDwCJlXEJrcxRcBc7vws_sNeNE=)
17. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGO1KYfKUdQWXPD7t1W_rS65bifhVl3Ka7wSecR5g6tfkSIwUKgzGEOQNUB8zbODnFuVgewm4rbFd-OhVaPx3Lt3Sgs28ar6wGdg2brDIZ1BCKWTLpfD0YKVdxQehjPgx-PXR8e4pM2v8HE2HlFCfc=)
18. [nashtechglobal.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQETPkQK46sVM9stIMaghX7nbY0XncuWxZRvRfJ6WlobtdC0E6KGRaMyIpyZKO0fhuy6S8KY_h_hPF1t6c8OCNco-jnOQwcgmKGxU0UUkciyYHK6Ykhh7PbHeh5ie9AX_qSLYbqpflmx90Jg-J5d48gvY1L4TvPfOFt6xC_G1us0iWkHWgBWbNcN-NCfhOCfyqwVxA==)
19. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHKkuaVt9xigOdXbUb2ndOXiaTPKecxBpKw95sdgH9Apjk2iXoNLxfTCFN37JmwAG4qRa_GbxMjFhCX8f8KNI_XX4aB-5poYBJsclGgECqkGD3l9FC7t6mauyXVMk4FHZETz-kuBnkCY95NDh6OMPHLg1RHj5oFzLeLIn-bs4te1oBwcpIGIcfxdmHaqmPP08DjsGErTxs=)
20. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFmHSBs6wvFe-vp6YH7yOeqwIz7xF9iZ6xAHrNNwQRKMIxRhwlM_jgF0shb-gvTGq3WCcF1T8_MV3Y1tQ4JWwGd7hIlTu4pS6Cwk6c4-x5KBSiazHyxRD20AUtiKOPZU4nY1EdKMRrU5lVKjI1mPz-2IvANITVFxwTCJu_xaxqbkBW4y-RygU_liCUjdQu7ey9yr8JT99bhbZIKg_8IEIDj8vojFw==)
21. [shift.click](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEyYTvzJG5mJeqql6TG7zU1ilJR_oIHUHkMRzIBS5ATPtuJ5sCe0Hn7XAmck0BgGoLHNRvRTOU3nun84JeHJyNg4c-G-Wex_CUwhKpKy5n-FetJW1F7TtLgTfh4WA82L3TxcnE=)
22. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXAVyxPOeMOdN4LphcqM-RNEUlw_LrpuxBr6xMX9ljfIp7u9DBBiZIzSeNqZHuVMsXBh2kNvJZawuoPyyDelrA4qKyJvJnhmAkymg5VyvzOCAzb-hGfw_y2pYtSzjRWz6odL34-wVncxhFc2C2CuGnD82t7X4hDrNAX5DH09UczmH7991g_ZIqr1ti-pI9MBExRhxoIRe2PokoBBpA_ZLcCiTpUs2VmIPp)
23. [shuttle.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQET4Ftlvh_iKKYEOh_2f_upb_Xa9aDn395qKp_imrNP7nyvuX6HdCW8TJVzeYeWm7YtpBQCJP_exaMD4gjqBmbRr4FYlW7tkfF2xAOA7_S6V7gQFUDtEHPJsanfn4wpBqzuOxurzpZaHJZoqKzOhg==)
24. [nedbatchelder.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFawP-Jnh2erHP36iTKQyOLua4OyH6UZRleHQFWzhduXv4YCi_CDeOQxLw1ZWN4c0OfCOCP6BTTxHiUINLkz4oBdha6uZYce3RpnS4VGKEdvWmU_F7GvKveRpl5UJ8_5dj2aQCRRzv6P1iw37WGaL8lTi6V2l96VRmJu_SbcP3jMfGWvwx8)
25. [infinyon.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHa3cXnif8BYycezXd3wEpPxczgUr3wZX118zPyBz3VXAaJo9QRPHWxS5J_N7KEYNKUp8VV9qfZpqQN5YNKejarxuROGs7azZy3sVIwUt2pqRor5KoHdf4hh_KLizZ9C6oJy8CGgxqHvrgsf9Du6l7pdn6LceHo_55U1g==)
26. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFHC98QyoZfIwhQTBaCKFOqq5qw8GAAk2X7xJI4hi3387tzp0c0vrT8wx63BVCGtqnE7D8d4hrY9HKBnKFZ-xKAyM1U8gOqO93br4XuCkErsHJZ5ZO0wL607l3MSjVo9lxhDFOAerVbhtSMoeQ8055wl5w_Fh7G1P-lyV6HU43inKT9Y5a1TbjR2HhbuwutBWjVsFSdViA=)
27. [fastly.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5jR14gufrapfBAneoAuwDyOLV7DJMDZeA6jTTIf1t8MmoFmiHT6_yixqdyL-TT06CNQUyQGiBUxdx2MHro8OHdWoqO_ROuljt_Fp8kjRKAgh0xkeadXPlhZe9FneUxTMG_iqHsWfx7qgUmivldbalGOcNN-2pbwsQxWTxHXTFgj4M8nARVO7-QnGhAIzY0-A9TWM=)
28. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG7RGQl5RuwQSb12yeroe4RHnr3HLi7LoVw6-llRevJNk6gSVBjMYWl_mHyrezVvtXl4uG9rE_lJczZqJBtr_jlEO4cvSE2fLolA7BjqSZQMo32Z13vqHsz-1zbsqGPVV8u1qhppx068j2OOJcaLAPAV1L_u9PC6CeGnfAOFbclvY-lwMtAlEwaWb5AOqmTTfoSmoEZjKNV2A7zI8-ZgJzFa10=)
29. [stepsecurity.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE-QJ9hoZCxXnL922OWTcaGG6XQ4566QtqK9M5WHRqXwv7fMX0EXDBdHHxLYMv149SZdawsEru3ZXVvbDj3NnH8JWhbl_RC4g-G_e-ioCrsco-qumlNr0lh4tWO7AaOIHulxdMuIQ_767949n4fRsUdE9E5)
30. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFWJv3zCI10H-ARK2vvZUPwJTfRLW7I0yJ45JvOBmbpYeOkHPmhkH7DpZmmFmTpTB0emD9tff9VuQELjxkQdFRS9yAwBsMa4v08v_OOcaU-1onqclc8vSNKuOkRNGDk90WCgzE8WjTzsUjm9fi9GPOnYFo1u91DmP_owB1GaD9YjRXV9_h7fSuWK-3wLzP3-QvuPRZ1GlwzfwCxnmDszIpOIfjvgg==)
31. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH_y_vfff32S2rwmBZr1xROCcvZFMHX8v1khZRsUDIpvwtHkDOxPwfR2KESzNv5wSKfmOWfRDKltqOxtPRvHEThP5fawNf2js-b__jwjMeCSATpSrAwfdiwZ-OfHtsMQcFtAAoxFJA=)
32. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEKeN6SydzTz0QjVhX7yJ4FRR9JNRnPctGwm_I8FfO_nzBryo-V-AyoE0M4zW70IYpTIzPiRxozVh59-rL0VyRj1caaxnTIak4VZX6Nl6v8PKQ3kP4KVyj3DQr64zu4lnl5SA==)
33. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFyE68gU9CpWSeCH7gVnRtSTjnjowOEra13DbXOMC6UUn5pPcIr9X-k6-6jSDPSZz7pZKIZEpxPdne0fIkP1XTvm_KjEyLUk-vm5uXwkRV-h9arANs9GogTWhNQgp57VEeHUE4r5zA=)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGLEz5fwdpb4dgxHRQjAlJAB6DZKbYDXYPmxL3jY7EYTx5N8waoGjRibuNiuTaLD2j70VXM1Qw97ttvEEo_3sBvkZHuRjfdX03RiYxHJTGZ4JYt2pvwbTtWOBjpRXVTCfcvwIW1EqDMXBkaQFfh65cXZfVBOqQTnGDdg==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHHLdRgvhXqrix9WXSAG5mhAt0jdKJ8BywiesthcSDPHw5szmwFjotnlfNZtj9pUUIaaovvOiG2tM2_KpBoi6s2pMO4193PZfl_DAL3TOJ5pikMcpwqNs8zzXaz6FO7EA==)
36. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJRMxqGaisymK9GbtnQjvEBskmPX3zV-trwtg5r_Q9UYbDD-qddzCk0yxMGcSJdWRL6E5tEJdriJvybNj6OlhAI3tilwSbAH0RzdADN0vA3ihq6ARD4dg=)
37. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGMR8ZIWHyzDYVbhAbVdfPFxKtK5YDIUuWpXecwqKM1aOEG2aIHB09C2MeKNoN3GevvpMcD5BK3vC-nEp30g9xDg1FqSpb1RwfzWiHEwUqmhoPhkqsPrujGCWiqtq7UpwGgSPYAqJ7urZvHt-U7)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH8Y6FzCWOMv_iVVHWbr4cnJ_dmfqjKqhAoSMyR8bJrMLlxYLOTPjaeCrJX80Ma4yrqC1zyy2_Eg8yhxL4ELWyO55RGwKoLBvDyig1ZP6Fq9qLgvj5zkHbHti_SprtmVuUDV4eEtQ==)
39. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1VJUN-K4KyGS0O9YJKURunCo6V5h5My6YemlAE65oDUz-9zLSu79V9AQL32dUu-Fju2-KK4cRvL4WXErb2PAn5rYURX0EwmDrDnI2sxVniRZ1nLjS8-1e-o57l98t_Go8wubRjeFXwUNF)
40. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHGec4f1BIFN9n2E_wmPWOU53ZiH5fsPNM6ufmLQTue2S2ZBqLMzxW99BM1LRwr8dey1jXAcqxE0QTvaxJ1pR-I0MywtUGHsg_mZeYBhQxLAxtL0MAdkClPDI63udBJUk7WDa2bahvn8w==)
41. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHMvbbhdIalN1Ia4Pbikgu75WMcEo61qWJwCd3xlqyYE1en9nR0KGbXlm4MMWTjqJ37swaKPFcW_kfl2K6VbESbT2aWmC704cST5QdmQvkfGjHpp4HYZa0a6gFryoT_w6Kkkn93WsU=)
42. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQETodnSeheE13N0nIOqdp_J6oRzWmqCNI__jiAVQr2q7gF4SYk-IyAkR3Lt2RhoCEGqsNRKq_9JserqJ6nAGb6ut9riN7rywGyGPXs-LAr3DP94FpNkjTRRLiWRP9KOfw3qxl4=)
43. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHlXmAqLKk155z3_t0BrPaOP5KBPX3531cGnnrpOP_wcrW-qdS1p7bebp_37DIsWOZyuvZcQErzmik_naY2I5Fa2waWq-UicEvbyAA4ZNCZeF2MhvvPnOPMifdJ_5I0UAsTstmTBj93)

### Sources

**OpenAI**

All URLs below were retrieved on **2026-09-18**.

**First-party GitHub**

- https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax
- https://docs.github.com/en/actions/get-started/understand-github-actions
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/use-jobs
- https://docs.github.com/en/actions/how-tos/write-workflows/choose-what-workflows-do/pass-job-outputs
- https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching
- https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching
- https://docs.github.com/en/actions/reference/security/secure-use

**Rust project**

- https://doc.rust-lang.org/cargo/reference/build-cache.html
- https://doc.rust-lang.org/cargo/reference/workspaces.html
- https://blog.rust-lang.org/2025/09/10/rust-compiler-performance-survey-2025-results/
- https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/
- https://blog.rust-lang.org/inside-rust/2026/08/18/reducing-target-dir-size-on-nightly/
- https://blog.rust-lang.org/releases/

**Rust practice references**

- https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml
- https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml
- https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml
- https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml
- https://raw.githubusercontent.com/nextest-rs/nextest/main/.github/workflows/ci.yml
- https://raw.githubusercontent.com/BurntSushi/ripgrep/master/.github/workflows/ci.yml
- https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/ci.yml
- https://github.com/nextest-rs/reuse-build-partition-example/blob/main/.github/workflows/ci.yml

**Path detector and production examples**

- https://github.com/dorny/paths-filter
- https://github.com/dorny/paths-filter/blob/master/README.md
- https://github.com/dorny/paths-filter/releases/tag/v4.0.3
- https://github.com/dorny/paths-filter/security
- https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/action.yml
- https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/package.json
- https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/LICENSE
- https://github.com/coder/coder/blob/main/.github/workflows/ci.yaml
- https://github.com/microsoft/agent-governance-toolkit/blob/main/.github/workflows/ci.yml

**Security counter-evidence**

- https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised
- https://securitylab.github.com/advisories/GHSL-2023-271_changed-files/
- https://app.stepsecurity.io/action-advisor/dorny/paths-filter

**Sources**

- [https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax](https://docs.github.com/en/actions/reference/workflows-and-actions/workflow-syntax)
- [https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml](https://raw.githubusercontent.com/tokio-rs/axum/main/.github/workflows/CI.yml)
- [https://github.com/nextest-rs/reuse-build-partition-example/blob/main/.github/workflows/ci.yml](https://github.com/nextest-rs/reuse-build-partition-example/blob/main/.github/workflows/ci.yml)
- [https://doc.rust-lang.org/cargo/reference/build-cache.html](https://doc.rust-lang.org/cargo/reference/build-cache.html)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://github.com/dorny/paths-filter/releases](https://github.com/dorny/paths-filter/releases)
- [https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml](https://github.com/rust-lang/cargo/blob/master/.github/workflows/main.yml)
- [https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml)
- [https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml](https://raw.githubusercontent.com/clap-rs/clap/master/.github/workflows/ci.yml)
- [https://raw.githubusercontent.com/nextest-rs/nextest/main/.github/workflows/ci.yml](https://raw.githubusercontent.com/nextest-rs/nextest/main/.github/workflows/ci.yml)
- [https://raw.githubusercontent.com/BurntSushi/ripgrep/master/.github/workflows/ci.yml](https://raw.githubusercontent.com/BurntSushi/ripgrep/master/.github/workflows/ci.yml)
- [https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/ci.yml](https://raw.githubusercontent.com/astral-sh/uv/main/.github/workflows/ci.yml)
- [https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching](https://docs.github.com/en/actions/reference/workflows-and-actions/dependency-caching)
- [https://github.com/dorny/paths-filter](https://github.com/dorny/paths-filter)
- [https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised](https://www.stepsecurity.io/blog/harden-runner-detection-tj-actions-changed-files-action-is-compromised)
- [https://github.com/step-security/paths-filter](https://github.com/step-security/paths-filter)
- [https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching](https://docs.github.com/en/actions/concepts/workflows-and-actions/dependency-caching)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://github.com/dorny/paths-filter/blob/master/README.md](https://github.com/dorny/paths-filter/blob/master/README.md)
- [https://github.com/dorny/paths-filter/security](https://github.com/dorny/paths-filter/security)
- [https://app.stepsecurity.io/action-advisor/dorny/paths-filter](https://app.stepsecurity.io/action-advisor/dorny/paths-filter)
- [https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/LICENSE](https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/LICENSE)
- [https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/action.yml](https://raw.githubusercontent.com/dorny/paths-filter/v4.0.3/action.yml)
- [https://github.com/camunda/camunda/issues/12605](https://github.com/camunda/camunda/issues/12605)
- [https://github.com/coder/coder/blob/main/.github/workflows/ci.yaml](https://github.com/coder/coder/blob/main/.github/workflows/ci.yaml)

**Perplexity**

The analysis relies on a diverse set of sources. First-party Rust documentation includes the Clippy GitHub Actions page, which provides a simple Clippy check workflow, and the Cargo CI guide, which shows multi-toolchain testing, MSRV verification, and warnings enforcement.[1][2] GitHub’s Rust workflow template offers a minimal single-job pattern used as a baseline.[8] Microsoft’s Rust engineering book provides a detailed production CI/CD pipeline with staged jobs for check, test, cross-compilation, documentation, and more, serving as a primary reference for multi-job topology.[5]

Practice evidence comes from DeepWiki’s descriptions of Axum and Tokio CI pipelines, Rust Maven’s example workflows, Dev.to’s Rust CI article, and the Bevy engine’s CI template.[3][6][9][10][11][19] These sources demonstrate multi-job workflows, matrices, and integration of tools like Clippy and Rustfmt. `Swatinem/rust-cache` and its README detail caching behavior and configuration, while `dtolnay/rust-toolchain`’s README explains toolchain selection and outputs such as cache keys.[12][13][14]

Path-filter mechanisms are documented in the `dorny/paths-filter` GitHub repository and `paths-changes-filter` marketplace entry, while NetBay Hosts and Rabinarayan Patra’s posts provide interpretive guidance and caution for workflow-level path filters.[7][15][16][17] Atharva Pandey’s CI/CD lesson explains rust-cache usage, shared keys, and coverage integration.[20] Collectively, these sources support the recommendation for multi-job topology and job-level changes detection in `rs-launch-blueprint` CI.

**Ecosystem-Specific Considerations, including Web Surface (R69)**

The optional web/API surface governed by R69 introduces additional considerations for CI job structure. Web-specific checks may include OpenAPI snapshot validation, documentation correctness gates, integration tests against mocked services, and static analysis of web routes. These checks can be heavy, particularly when generating documentation or running extensive test suites, and should not be run on CLI/library-only changes.

The recommended changes-detector pattern naturally accommodates this by defining a `web` filter in `dorny/paths-filter` or `paths-changes-filter` configuration, matching files in `web/**`, `api/**`, or other web-related directories.[7][17] The `changes` job sets `web_changed` based on this filter, and downstream jobs such as `web-check` and `web-test` are conditioned on this output. This pattern is analogous to Python’s use of `lint-changes` to gate specific lint jobs based on changed paths, but extended to Rust and web surfaces.[docs context]

In practice, this means that if a pull request modifies only CLI or library crates, web-specific jobs will be skipped. If a pull request modifies only web files, core test jobs may be skipped or limited, depending on how tightly coupled web and core code are. The template should default to a conservative approach, running core tests when web changes could affect core behavior, but the pattern allows fine-grained control. Axum’s CI pipeline, which validates multiple crates and documentation across an HTTP surface, provides indirect evidence that such partitioning is feasible and beneficial.[10]

The topology and changes-detector patterns therefore scale to the web surface without requiring additional architectural decisions beyond those already recommended. They model how multi-surface Rust projects can maintain resource-aware validation while preserving correctness and clarity.

**Conclusion**

R11’s decision for `rs-launch-blueprint` is that the CI workflow should adopt a **multi-job, staged GitHub Actions pipeline with a dedicated job-level changes-detector**, rather than a single shared job without skip-gating. This design is informed by first-party Rust CI guidance, production practice in Axum, Tokio, Bevy, and Microsoft’s Rust training, and cross-repo principles derived from the Python and TypeScript templates.[1][2][5][8][9][10][11][12][13][14][15][16][17][19][20]

The multi-job topology separates fast checks from heavy validation, uses OS matrices for tests across `ubuntu-latest` and `macos-latest`, isolates MSRV verification into a dedicated job, and provides natural homes for coverage, docs gates, security scanning, and web-specific checks. It uses `dtolnay/rust-toolchain` and `Swatinem/rust-cache` to amortize Rust’s compile cost across jobs, making repeated setup cheap enough that parallelism and clarity become decisive advantages.[5][12][13][14][20] It encodes dependencies via `needs:` edges, ensuring that `changes` and `check` run before heavy jobs and that failures in early stages abort downstream work.

The changes-detector pattern implements principled pruning via a `changes` job that uses `dorny/paths-filter` or `paths-changes-filter` to classify changes into documentation, core code, and web surface. It sets outputs consumed by downstream jobs and avoids workflow-level `paths` or `paths-ignore` filters that could hide required status checks.[7][15][16][17] This pattern allows docs-only and surface-isolated changes to skip heavy jobs, conserving resources while maintaining correctness.

Cross-repo analysis shows that while Python and Rust adopt multi-job, changes-gated patterns, TypeScript’s single-job CI remains justifiably simpler due to its different ecosystem characteristics and workload. The shared principles—fast feedback, resource-aware validation, clarity of responsibilities, MSRV and multi-OS compliance, and avoidance of hidden checks—are preserved across blueprints, even as their implementations diverge.[docs context]

The recommended CI structure sets the stage for other items—R02, R12, R13—to integrate their concerns into well-defined jobs. It provides consumers of `rs-launch-blueprint` with a robust, principled CI architecture that can scale with project complexity while remaining comprehensible and maintainable.

**Sources**

- [Clippy Documentation](https://doc.rust-lang.org/stable/clippy/continuous_integration/github_actions.html)
- [Continuous Integration](https://doc.rust-lang.org/cargo/guide/continuous-integration.html)
- [GitHub Actions for Rust projects - Rust Maven](https://rust.code-maven.com/github-actions)
- [rust/.github/workflows/ci.yml at master · rust-lang/rust](https://github.com/rust-lang/rust/blob/master/.github/workflows/ci.yml)
- [11. Putting It All Together — A Production CI/CD Pipeline ...](https://microsoft.github.io/RustTraining/engineering-book/ch11-putting-it-all-together-a-production-cic.html)
- [Rust CI with GitHub Actions](https://dev.to/bampeers/rust-ci-with-github-actions-1ne9)
- [GitHub - dorny/paths-filter: Conditionally run actions based on files ...](https://github.com/dorny/paths-filter)
- [Building and testing Rust - GitHub Enterprise Server 3.22 Docs](https://docs.github.com/en/enterprise-server@3.22/actions/tutorials/build-and-test-code/rust)
- [bevyengine/bevy_github_ci_template](https://github.com/bevyengine/bevy_github_ci_template)
- [CI/CD Pipeline | tokio-rs/axum | DeepWiki](https://deepwiki.com/tokio-rs/axum/12.1-cicd-pipeline)
- [Development and Testing | tokio-rs/tokio | DeepWiki](https://deepwiki.com/tokio-rs/tokio/11-development-and-testing)
- [Rust Cache · Actions · GitHub Marketplace](https://github.com/marketplace/actions/rust-cache)
- [rust-cache/README.md at master · Swatinem/rust-cache](https://github.com/Swatinem/rust-cache/blob/master/README.md)
- [rust-toolchain/README.md at master · dtolnay/rust-toolchain](https://github.com/dtolnay/rust-toolchain/blob/master/README.md)
- [Conditional Execution and Path Filtering in GitHub Actions](https://netbayhosts.in/blogs/github-actions-conditional-execution)
- [Skip CI When Only Documentation Changed | Rabinarayan Patra ...](https://www.rabinarayanpatra.com/snippets/github-actions/conditional-skip-on-docs-only)
- [Paths Changes Filter · Actions · GitHub Marketplace](https://github.com/marketplace/actions/paths-changes-filter)
- [CI · Workflow runs · tokio-rs/axum](https://github.com/tokio-rs/axum/actions/workflows/CI.yml)
- [tokio/.github/workflows/ci.yml at master · tokio-rs/tokio](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml)
- [Lesson 3: CI/CD for Rust — GitHub Actions, caching, cargo-nextest -](https://www.atharvapandey.com/post/rust/rust-deploy-ci/)

**Cost**

Total: $1.0055

**Gemini**

- [starsling.dev](https://starsling.dev/best-practices/github-actions/path-filter-workflows)
- [github.com](https://github.com/dorny/paths-filter/releases)
- [github.com](https://github.com/dorny/paths-filter)
- [github.com](https://github.com/swatinem/rust-cache)
- [depot.dev](https://depot.dev/blog/we-analyzed-66821-github-actions-runs)
- [github.com](https://github.com/swatinem/rust-cache/releases)
- [getoto.net](https://noise.getoto.net/tag/github-actions/)
- [github.com](https://github.com/dtolnay/rust-toolchain/issues/124)
- [rust-lang.org](https://rustc-dev-guide.rust-lang.org/tests/ci.html)
- [rust-lang.org](https://forge.rust-lang.org/infra/docs/rustc-ci.html)
- [github.com](https://github.com/Swatinem/rust-cache/issues/95)
- [github.com](https://github.com/tokio-rs/turmoil/actions/runs/16600779840)
- [nika.sh](https://nika.sh/workflows/jobs)
- [github.com](https://github.com/clap-rs/clap)
- [dev.to](https://dev.to/bampeers/rust-ci-with-github-actions-1ne9)
- [github.com](https://github.com/tokio-rs/axum/actions/workflows/CI.yml)
- [docs.rs](https://docs.rs/axum/latest/axum/)
- [nashtechglobal.com](https://blog.nashtechglobal.com/building-a-fast-and-reliable-ci-cd-pipeline-for-rust-crates/)
- [reddit.com](https://www.reddit.com/r/devops/comments/1eoa3t1/are_there_any_advantages_in_splitting_single_a/)
- [github.com](https://github.com/Swatinem/rust-cache/issues/75/linked_closing_reference?reference_location=REPO_ISSUES_INDEX)
- [shift.click](https://shift.click/blog/github-actions-rust/)
- [medium.com](https://medium.com/@gerahitesh13/the-rust-developers-edge-unlocking-powerful-ci-cd-with-github-actions-61723fcb54cd)
- [shuttle.dev](https://www.shuttle.dev/blog/2025/01/23/setup-rust-ci-cd)
- [nedbatchelder.com](https://nedbatchelder.com/blog/202505/filtering_github_actions_by_changed_files)
- [infinyon.com](https://www.infinyon.com/blog/2021/04/github-actions-best-practices/)
- [medium.com](https://medium.com/smbcloud/deploy-rust-axum-binary-with-garust-debian-github-action-f04da853581)
- [fastly.net](https://ithub.global.ssl.fastly.net/apache/datafusion-comet/actions/runs/30304566398/workflow)
- [stackoverflow.com](https://stackoverflow.com/questions/58136102/deploy-individual-services-from-a-monorepo-using-github-actions)
- [stepsecurity.io](https://app.stepsecurity.io/action-advisor/dorny/paths-filter)
- [stackoverflow.com](https://stackoverflow.com/questions/76199141/github-actions-path-filtering-returning-true-when-no-changes-made)
- [github.com](https://github.com/dorny/paths-filter/issues/227)
- [github.com](https://github.com/dorny/paths-filter/issues)
- [github.com](https://github.com/dorny/paths-filter/issues/147)
- [github.com](https://github.com/TryGhost/Ghost/blob/main/.github/workflows/ci.yml)
- [github.com](https://github.com/dtolnay/rust-toolchain)
- [github.com](https://github.com/serde-rs/serde)
- [github.com](https://github.com/step-security/dtolnay-rust-toolchain)
- [github.com](https://github.com/Swatinem/rust-cache/issues/9)
- [github.com](https://github.com/dtolnay/rust-toolchain/issues/180)
- [github.com](https://github.com/dtolnay/rust-toolchain/releases)
- [github.com](https://github.com/dtolnay/rust-toolchain/issues)
- [github.com](https://github.com/Swatinem/rust-cache/issues)
- [github.com](https://github.com/Swatinem/rust-cache/issues/194)
