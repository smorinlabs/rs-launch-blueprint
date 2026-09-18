# CI Job Structure and Path-Filtered Changes Detection for `rs-launch-blueprint`

The CI workflow for `rs-launch-blueprint` should adopt a **multi-job, staged GitHub Actions pipeline** that separates fast, always-on checks from heavier validation while using a **path-filtered changes-detector job** to skip expensive jobs on documentation-only or surface-isolated changes. This pattern aligns with modern Rust CI practice in well-regarded projects, uses established Actions such as `dtolnay/rust-toolchain` and `Swatinem/rust-cache` to amortize Rust’s compile cost across jobs, and employs a dedicated `changes` job based on `dorny/paths-filter`-style mechanisms so that heavy jobs like cross-OS tests, coverage, and documentation gates run only when relevant code changes are detected.[2][5][7][12][13][15][16][20] The resulting `.github/workflows/ci.yml` job graph preserves cross-repo principles of early feedback, resource-aware validation, and transparent gating, while justifiably diverging from the TypeScript template’s single-job shape in order to fit Rust’s compilation profile and multi-surface blueprint design.

## Context and Motivation

The decision governed by R11 concerns the **architectural topology** of CI for `rs-launch-blueprint`, not the specific tools invoked inside individual checks. The template is shaped as a tri-surface Rust project: a command-line interface, a reusable library crate, and an optional web service/API surface governed by R69.[5] Within this context, the owner has already fixed important parameters, including the use of Rust 2024 edition, an MSRV policy of “stable minus two minor versions” with `rust-version` declared in `Cargo.toml` and tested in CI, a dual-OS target matrix of `ubuntu-latest` and `macos-latest`, and licensing under `MIT OR Apache-2.0`. These parameters determine constraints on tooling and job structure but do not themselves answer whether checks are split into jobs or steps, or how changes detection should prune heavy work.

The Python and TypeScript blueprints provide contrasting precedent that must be treated as **evidence rather than binding templates**. The Python CI splits checks across several jobs and even across workflows: a dedicated `lint.yml` hosts multiple linting jobs gated by a `lint-changes` job that path-filters which linters run, while `ci.yml` includes a `changes` job (F040) that gates heavier jobs such as typechecking, import-boundary enforcement, tests, and build-smoke on whether documentation-only changes were made.[docs context] In contrast, the TypeScript CI collapses oxlint, formatting, and `tsc` typechecking into steps inside a single `ci` job with no changes-detector and no path-filtered skip-gating.[docs context] This divergence was recorded as DIVERGENT in the ledger, but without an explicit design record explaining why job splitting and skip-gating were adopted for Python and omitted for TypeScript. R11 must therefore revisit the underlying principles and decide how Rust should apply them.

Rust’s **compile-time profile** and ecosystem conventions are materially different from Python and TypeScript. A single `cargo test` or `cargo clippy` run typically performs substantial work, including compiling the crate graph and running tests or lints, which can dominate CI run time even for medium-sized projects.[2][5] The Rust ecosystem also commonly uses Actions such as `dtolnay/rust-toolchain` to select specific toolchains and `Swatinem/rust-cache` to cache `~/.cargo` and `target` directories between jobs, thereby trading off repetition of setup against parallelism and clarity.[12][13][14][20] These differences imply that job topology and skip-gating mechanisms may need to diverge from TypeScript’s simplicity while remaining compatible with the shared principles governing all blueprints.

R11 interacts with several related items. R02 decides whether an architectural-boundary lint job exists at all; R11 must be able to host such a job without determining its existence. R12 defines whether and how multiple jobs are aggregated into a single required status check; its decision depends on the job graph chosen here but is out of scope for R11. R13 governs always-on software composition analysis and must decide, using the topology defined by R11, whether vulnerability scanning is placed in its own job or folded into an existing one. Finally, R10 governs dependency caching; R11 must assume the presence of an established Rust caching action and reason about how its effectiveness shapes the choice between multi-job and single-job CI.

Within this broader context, the central questions are threefold. First, given Rust’s compile times and the availability of caching, does Rust CI for this template benefit more from per-check job splitting (as in the Python blueprint) or from a single shared job (as in the TypeScript blueprint)? Second, is a path-filtered changes-detector job necessary and proportionate to skip heavy build, test, coverage, and docs jobs on docs-only or surface-isolated pull requests? Third, how can the resulting design preserve shared principles across Python, TypeScript, and Rust while allowing justified ecosystem-specific differences? The remainder of this report structures the research and answers through the mandated survey method and the answer template.

## Methodology and Landscape Setup

The owner’s survey method requires **“forest before trees”**: a landscape of categories and candidates must be assembled before evaluating specific designs. For CI job structure and changes detection in Rust, the relevant category is “GitHub Actions CI architecture patterns for Rust projects,” spanning built-in workflows, first-party guidance, widely adopted third-party Actions, and emergent path-filtering mechanisms. The search results provided form the basis for a fresh ecosystem survey, rather than relying on pre-existing baselines.

Built-in and first-party sources include **official Rust documentation on CI**, which offers examples of GitHub Actions workflows using `cargo build`, `cargo test`, and optional checks such as Clippy and MSRV verification.[1][2] The Rust Clippy documentation provides a concise GitHub Actions example where Clippy lints are run in a dedicated job using `cargo clippy --all-targets --all-features`, with `RUSTFLAGS="-Dwarnings"` to fail the job on any warning.[1] Cargo’s continuous integration guide shows a multi-toolchain matrix job that tests a package against stable, beta, and nightly toolchains, illustrating that Rust’s own guidance assumes job-level matrix execution and highlights auxiliary jobs for dependency updates and MSRV verification using tools like `cargo-msrv` and `cargo-hack`.[2] These documents represent authoritative guidance because they are maintained by the Rust project and describe recommended practices rather than ad-hoc examples.

GitHub’s documentation provides a **Rust workflow template** that demonstrates a minimal CI pipeline: a single `build` job that runs `cargo build --verbose` and `cargo test --verbose` on `ubuntu-latest` for pushes and pull requests to `main`.[8] This template is authoritative for “floor” guidance, showing how GitHub expects basic Rust projects to be tested, but it is explicitly described as a starting point that users should customize.[8] It therefore serves as a baseline but not as a model for advanced multi-surface templates.

Established industry standards for Rust CI architecture can be seen in well-regarded projects and curated training material. Microsoft’s Rust engineering book includes a chapter on building a **production CI/CD pipeline**, presenting a single workflow file with multiple jobs: a fast feedback “check” job that runs formatting, Clippy lints, `cargo check`, and documentation warnings, followed by a “test” job in an OS matrix, cross-compilation jobs using additional targets and optional `cross`, and further jobs for coverage, security analysis, and release artifacts.[5] This chapter is authoritative both because it is curated by a major industry player and because it explicitly frames the workflow as production-ready guidance, with clearly explained quality gates and execution stages.

Further practice evidence comes from the CI pipelines of major Rust ecosystem projects. The Axum web framework uses GitHub Actions to orchestrate a CI pipeline described in DeepWiki as including quality gates, testing strategies, cross-compilation validation, dependency management, and documentation checks across multiple crates (`axum`, `axum-core`, `axum-extra`, and `axum-macros`).[10] Tokio, the asynchronous runtime, uses a main `ci.yml` workflow with a comprehensive test pipeline that enforces a strict MSRV policy; DeepWiki notes that Tokio’s MSRV is 1.71, enforced across multiple workspace crates, and the GitHub workflow file shows job-based orchestration including MSRV checks.[11][19] These projects are widely referenced as canonical Rust libraries in documentation and community material, and their CI pipelines reflect mature, large-scale usage of Rust CI patterns.[10][11][19]

Established third-party Actions include **Swatinem’s `rust-cache`** GitHub Action, which provides smart caching for Rust and Cargo projects.[12][13] The action caches `~/.cargo` (binaries, registry, git dependencies) and the `target` directory, using an automatic key derived from the job ID, `rustc` release and hash, relevant environment variables, and a hash of all `Cargo.lock` and `Cargo.toml` files in the repository.[12][13] This action has become a de facto standard for Rust CI caching, and multiple guides, including Atharva Pandey’s CI/CD lesson, recommend using it with a shared key across jobs so that test jobs can reuse build artifacts produced by check jobs.[20] Another established Action is **dtolnay’s `rust-toolchain`**, which provides a concise way to install a specified Rust toolchain using rustup; it allows configuration via the action revision (e.g., `@stable`, `@nightly`, `@1.42.0`) or an explicit `toolchain` input, and provides outputs such as a cache key derived from the installed `rustc` version.[14] Its usage in examples and major projects like Axum and Tokio reflects its role as a standard mechanism for toolchain selection.[5][10][11][14]

Up-and-comer mechanisms relate mainly to **path-filtered conditional execution**. The `dorny/paths-filter` Action and the closely related `paths-changes-filter` Action both implement conditional job and step execution based on the files modified in a pull request or push.[7][17] Their documentation describes filters composed of glob rules, with outputs indicating whether a filter matched any changed files and listing the matched files; these outputs can be consumed via `needs` and `if` conditions to gate heavy actions.[7][17] Independent blog posts, including a NetBay Hosts article and Rabinarayan Patra’s snippet, outline patterns for skipping CI when only documentation files change, explaining the tradeoffs between GitHub’s native `paths` and `paths-ignore` filters at the workflow level and finer-grained Actions like `paths-filter`.[15][16] These posts are not authoritative by themselves but serve as interpretive guides referencing GitHub’s own documentation and real-world patterns.

Finally, additional practice evidence comes from intermediate projects and guides. Rust Maven’s sample GitHub workflow uses a matrix of Rust toolchains (stable, beta, nightly, and specific versions) with steps invoking `cargo clippy`, `cargo fmt`, and `cargo test`, sometimes with stricter Clippy pedantic lints.[3] A Dev.to article on Rust CI with GitHub Actions describes a multi-workflow setup where separate workflows handle linting, testing with coverage, and release packaging, highlighting the use of nightly Rust, codecov integration, caching via `Cargo.lock` hashing, and dedicated Clippy and Rustfmt jobs.[6] The Bevy engine’s CI template provides a reference for game-oriented Rust projects, using a CI workflow that runs `cargo test`, `cargo clippy -- -D warnings`, and `cargo fmt --all -- --check` on `main` branch commits and pull requests, with a separate release workflow for attaching built artifacts to GitHub releases.[9] These sources collectively ground the landscape in both official guidance and varied production practice.[1][2][3][5][6][8][9][10][11][12][13][14][15][16][17][19][20]

With this landscape established, the report can now apply the mandated answer template, beginning with a detailed analysis of principles and implementation for CI job structure and changes detection in `rs-launch-blueprint`.

## Detailed Analysis for rs-launch-blueprint CI Job Structure

### Landscape

Within the Rust CI architecture category, the landscape can be mapped into three bins: first-party or built-in patterns, established industry standards, and up-and-comer mechanisms. Each bin supplies candidates relevant to R11’s decision on job structure and changes detection.

The **first-party or built-in bin** includes GitHub’s Rust workflow template and official Rust documentation on CI for Cargo and Clippy. GitHub’s template demonstrates a straightforward single-job CI where the `build` job runs `cargo build --verbose` and `cargo test --verbose` on `ubuntu-latest` for pushes and pull requests to `main`.[8] This template is a baseline for minimal CI, suitable for small projects but not necessarily for multi-surface blueprints. Rust’s Cargo CI guide provides richer examples, including a workflow with a matrix of toolchains across `stable`, `beta`, and `nightly`, a job for verifying dependencies via `cargo update`, and a dedicated MSRV job using `cargo-hack` with `--rust-version` across workspace targets.[2] These examples show that Rust’s own authors expect multi-job workflows, especially when testing against multiple toolchains or verifying MSRV for packages that declare `rust-version`.[2] Clippy’s documentation adds another first-party example: a simple workflow where a `clippy_check` job runs `cargo clippy --all-targets --all-features`, with `RUSTFLAGS="-Dwarnings"` to fail CI on warnings.[1] Together, these sources establish that Rust’s official guidance considers both single-job floor patterns and multi-job, matrix-based advanced patterns as normal.

The **established industry standard bin** comprises multi-job workflows that separate fast checks from heavy validation, and established Actions for toolchain selection and caching. Microsoft’s Rust engineering chapter shows a CI workflow named `CI` with jobs such as `check` (running `cargo check`, Clippy, and `cargo fmt`), `test` (running `cargo test` on an OS matrix), `cross` (cross-compiling using additional targets and optionally `cross`), and further jobs like `miri` and coverage.[5] The `check` job uses `dtolnay/rust-toolchain@stable` with `components: clippy, rustfmt`, followed by `Swatinem/rust-cache@v2` to cache dependencies, and then runs several commands including documentation checks with `RUSTDOCFLAGS='-Dwarnings' cargo doc`.[5] This pattern explicitly divides CI into stages and introduces dependencies between jobs via `needs`, providing a strong template for a production Rust pipeline. The Bevy CI template, though simpler, also exemplifies a multi-job approach by separating CI and release workflows and by folding tests, Clippy, and formatting into a common CI workflow that runs on each commit and pull request to `main`.[9]

Established Actions play a central role. `dtolnay/rust-toolchain` installs a Rust toolchain using rustup, selecting the toolchain based on the action revision or an explicit `toolchain` input, and optionally installing additional components like `clippy` and `rustfmt` or targets like `wasm32-unknown-unknown`.[14] It is widely used in examples and major projects because of its concise configuration and well-maintained behavior.[5][10][11][14] `Swatinem/rust-cache` implements smart caching for Rust projects, caching `~/.cargo` and `./target` and deriving cache keys from job IDs, `rustc` versions, environment variables, and Cargo metadata.[12][13] Atharva Pandey’s CI/CD lesson underscores the importance of setting a shared key (e.g., `shared-key: "main-build"`) so that jobs like `test` can benefit from artifacts built in earlier jobs such as `check`.[20] This pattern directly addresses concerns about repeated compile times across jobs and is therefore central to R11’s decision.

The **up-and-comer bin** consists primarily of path-filtered changes-detection mechanisms. `dorny/paths-filter` is a GitHub Action that allows conditional execution of workflow steps and jobs based on files modified in a pull request or push, supporting filters composed of glob patterns and output variables indicating whether any paths matched and listing the matched files.[7] The similar `paths-changes-filter` Action offers a marketplace entry emphasizing the ability to define multiple filters, each with optional include or exclude rules and separate outputs for flags and file lists, enabling fine-grained conditional gating.[17] These Actions are increasingly used in monorepo setups where slow tasks like integration tests or deployments are run only for changed components, saving time and resources.[7][17] Independent guidance, such as the NetBay Hosts article and Rabinarayan Patra’s snippet, explains how GitHub’s built-in `paths` and `paths-ignore` filters at the workflow level can skip entire workflows on docs-only changes and warns of pitfalls, especially when required status checks depend on workflows that might not run.[15][16] These sources advocate for using job-level Actions like `paths-filter` when fine-grained gating is needed while keeping the workflow as a whole triggered.[7][15][16][17]

Practice evidence provides additional nuance. The Axum project uses GitHub Actions as its CI platform and orchestrates validation across multiple crates, including quality gates and documentation checks, indicative of a multi-job pipeline.[10] Tokio’s CI includes jobs that enforce MSRV and test the runtime under different configurations, again adopting multi-job structures.[11][19] Rust Maven’s example demonstrates a matrix of Rust versions with Clippy and formatting steps, while the Dev.to article on Rust CI uses multiple workflows for linting, testing with coverage, and release packaging.[3][6] All these examples show that **splitting concerns into jobs and workflows** is the dominant pattern for nontrivial Rust projects, particularly when multi-surface or multi-crate workspaces are involved.[3][5][6][9][10][11][19][20]

These landscape observations directly inform R11’s decision. Single-job workflows remain valid for small projects and are supported by GitHub’s Rust template.[8] However, multi-job workflows using `dtolnay/rust-toolchain` and `Swatinem/rust-cache`, with optional path-filtered gating by `dorny/paths-filter` or similar Actions, represent the **established standard** for production Rust CI in multi-surface contexts.[5][10][11][12][13][14][20] The following sections articulate the principles that must be preserved across languages and derive a concrete recommendation for `rs-launch-blueprint`.

### Principles and implementation

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

### Recommendation

For `rs-launch-blueprint`, R11 should adopt a **multi-job CI workflow** in `.github/workflows/ci.yml` with the following topology:

A fast **`changes` job** runs on every push and pull request to the main branch. It uses `actions/checkout` to obtain the repository and a path-filter Action such as `dorny/paths-filter` or `paths-changes-filter` to classify changes into filters such as `docs`, `core`, and `web` (if the optional R69 web surface is present).[7][17] The job sets outputs indicating whether the change set is documentation-only, whether core crates changed, and whether web-surface files changed. This job runs quickly, performing no compilation, and acts as a gating mechanism for heavy jobs.[7][15][16][17]

A **`check` job** runs unconditionally on code changes and optionally even on docs-only changes, with `needs: changes`. It uses `dtolnay/rust-toolchain@stable` to select the current stable toolchain and requests components such as `clippy` and `rustfmt`.[5][14] It invokes `Swatinem/rust-cache@v2` with a shared key (e.g., `main-ci`) to cache dependencies.[12][13][20] The job then runs the template’s chosen formatter, linter, and typechecker tools in sequence—for example, `cargo fmt --check`, `cargo clippy -- -D warnings`, and `cargo check --workspace --all-targets --all-features`—failing CI on any warnings or errors.[1][2][3][5][9] The `check` job’s acceptance criteria include passing compilation, lint, and formatting across the entire workspace.

A **`test` job** runs only when code changes are detected (`if: needs.changes.outputs.core_changed == 'true'`), with `needs: [changes, check]`. It uses an OS matrix across `ubuntu-latest` and `macos-latest`, with each leg using `dtolnay/rust-toolchain@stable` and `Swatinem/rust-cache@v2` with the same shared key so that build artifacts from `check` can be reused where possible.[5][12][13][14][20] The job runs the template’s test harness, such as `cargo test --workspace` and doc tests, and reports failures separately per OS.[2][5][8][9] This pattern mirrors Microsoft’s `test` job and Axum/Tokio’s practice of OS matrices for tests.[5][10][11][19]

Optional heavy jobs such as **`coverage`**, **`docs`**, and **`security`** (for R13) run with `needs: [changes, check]` and `if` conditions tied to `changes` outputs. The `coverage` job might run on `ubuntu-latest` only, using `cargo tarpaulin` or `cargo-nextest` plus coverage reporting; the `docs` job runs `cargo doc` with `RUSTDOCFLAGS='-Dwarnings'` to treat warnings as errors; the `security` job runs vulnerability scanning and license compliance tools.[2][5][6][20] All these jobs reuse caching and tooling patterns. A **`msrv` job** runs on `ubuntu-latest`, uses `dtolnay/rust-toolchain` to install the `rust-version` floor, and runs tools such as `cargo-hack` to verify that the workspace compiles at that floor.[2][11][19] This job is treated as optional for docs-only changes but required for code changes, with outputs surfacing its results.

For the optional **web/API surface** governed by R69, the `changes` job defines a `web` filter, and a `web-check` or `web-test` job runs only when web files change (`if: needs.changes.outputs.web_changed == 'true'`), testing web-specific behavior such as OpenAPI snapshots or docs-correctness gates without imposing those costs on CLI/library-only changes.[7][10] This preserves the resource-aware validation principle across surfaces.

The workflow avoids workflow-level `paths` or `paths-ignore` filters for core CI, ensuring that required status checks are never hidden behind filters that might prevent workflows from starting.[15][16] Instead, all pruning is done via the `changes` job’s outputs and job-level `if` conditions, following NetBay Hosts and Rabinarayan’s guidance.[7][15][16][17] The job graph and `needs:` edges embody a clear staged pattern: `changes` → `check` → `test`/`coverage`/`docs`/`msrv`/`web`, with each heavy job conditioned on relevant change types.

This recommendation intentionally diverges from the TypeScript blueprint’s single-job shape while preserving shared principles. TypeScript’s single `ci` job remains appropriate there because checks are relatively lightweight, Node’s tooling and incremental builds reduce per-check cost, and the repository’s scope does not justify complex gating. For Rust, the multi-job, changes-gated pattern is justified by compile-time cost, multi-surface scope, and ecosystem practice, as seen in Axum, Tokio, Microsoft’s CI, and advanced community templates.[2][5][9][10][11][19][20] Python’s `changes` and lint partitions already embody this pattern, and Rust’s adoption of it strengthens cross-repo coherence at the principle level.

### Members

R11 is classified as a **bundle** and thus comprises multiple conceptual members. In this context, members are architectural patterns rather than crates, and crate-level figures are therefore inapplicable; this is stated explicitly under each member’s fitness gates. Two primary members are needed to realize the recommendation: the **CI job topology pattern** and the **changes-detector job pattern**.

#### CI job topology pattern

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

#### Changes-detector job pattern

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

### Compatibility

Compatibility between the job topology and changes-detector members is crucial. Both patterns rely on `needs:` edges and on job-level `if` conditions, and they must be tested together. The recommended workflow uses `changes` as the root job, followed by `check`, and then the heavy jobs, all declared in a single `.github/workflows/ci.yml` file. The `check` job uses caching and toolchain actions compatible with the heavy jobs, and `changes` supplies outputs consumed by all.

Practice evidence supports this compatibility. Microsoft’s CI pipeline uses `needs` edges between `check`, `test`, and other jobs, demonstrating that multi-stage workflows with shared caching behave correctly.[5] Pandey’s guidance shows that `rust-cache` can use a shared key across jobs so that artifacts from one job are reused in another, confirming that caching works across job boundaries.[12][13][20] Axum and Tokio’s pipelines demonstrate that MSRV and multi-crate validation can coexist in a multi-job workflow.[10][11][19] While these projects may not use `paths-filter` exactly as described, the combination of `needs` and caching is well established.

The compatibility question also extends to other items. R02’s crate-boundary enforcement can be implemented as a dedicated job in the topology, gated by `changes` outputs (e.g., only run when `core_changed == 'true'`). R12’s aggregation of required status checks can wrap around the job graph, defining an aggregate check that passes only when all underlying jobs succeed. R13’s vulnerability scanning can be placed in the `security` job, also gated by `changes`. The topology and changes-detector patterns therefore form a compatible foundation for these items.

### Parameters

For R11, the parameters are:

owns `ci-job-structure` = **multi-job, staged CI workflow** with jobs `changes`, `check`, `test` (OS matrix), `coverage`, `docs`, `msrv`, optional `web`.

owns `changes-detector-topology` = **job-level `changes` job using path-filter Action**, gating heavy jobs via outputs.

assumes `rust-cache` = **Swatinem/rust-cache@v2** configured under R10 with a shared key across jobs.[12][13][20]

assumes `rust-toolchain` = **dtolnay/rust-toolchain@stable** configured under R10 or equivalent for toolchain selection.[14][5]

assumes `target-os-matrix` = `ubuntu-latest, macos-latest` for `test` and other OS-dependent jobs, per owner’s fixed parameters.[docs context]

assumes `msrv-os` = `ubuntu-latest` for the `msrv` job, pending owner decision on OS coverage for MSRV; this does not widen parameters but chooses a specific OS within the allowed set.[2][11][19]

If future decisions require MSRV validation on both OSs, that would be a separate item and may introduce a **CONFLICT** line at that time.

### Migration implications

Migrating the template to the recommended CI structure involves several file-level changes in `.github/workflows/ci.yml`. The existing single-job or minimal workflow must be replaced or extended with job definitions for `changes`, `check`, `test`, `coverage`, `docs`, `msrv`, and optional `web`. Each job must specify `runs-on`, `needs`, and `if` conditions as appropriate, and steps must be reorganized to reflect their responsibilities.

The `changes` job must be added at the top of the workflow, with configuration for `dorny/paths-filter` or `paths-changes-filter`. The `check` job must be updated to use `dtolnay/rust-toolchain` and `Swatinem/rust-cache`, and to run formatting, linting, and typechecking steps. The `test` job must be defined with a `strategy.matrix` for OSs and steps to run tests. Additional jobs must be added for coverage, docs, and MSRV, with appropriate gating.

Any existing workflow-level `paths` or `paths-ignore` filters must be removed from the main CI workflow and, if needed, relocated to secondary workflows. Branch protection rules and required status checks in GitHub must be updated to reference the new job names or aggregate checks defined by R12.

### Validation strategy

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

### Confidence & re-verify trigger

The confidence level in the recommendation is high, based on alignment with first-party guidance, production practice, and cross-repo principles.[1][2][5][8][9][10][11][12][13][14][15][16][17][19][20] The main uncertainty lies in future changes to GitHub Actions or Rust’s CI recommendations. Re-verification should be triggered if:

Rust introduces new CI tooling or guidance that materially changes recommended job structures (e.g., a new official CI orchestrator that replaces GitHub Actions patterns).[1][2]

GitHub adds or deprecates features related to `paths`, `paths-ignore`, or job-level conditional execution, affecting how `paths-filter` Actions work.[7][15][16][17]

Major projects such as Axum or Tokio significantly restructure their CI pipelines, signaling a shift in best practice.[10][11][19]

If any of these events occur, R11 should be revisited and recommendations adjusted accordingly.

### Sources

The analysis relies on a diverse set of sources. First-party Rust documentation includes the Clippy GitHub Actions page, which provides a simple Clippy check workflow, and the Cargo CI guide, which shows multi-toolchain testing, MSRV verification, and warnings enforcement.[1][2] GitHub’s Rust workflow template offers a minimal single-job pattern used as a baseline.[8] Microsoft’s Rust engineering book provides a detailed production CI/CD pipeline with staged jobs for check, test, cross-compilation, documentation, and more, serving as a primary reference for multi-job topology.[5]

Practice evidence comes from DeepWiki’s descriptions of Axum and Tokio CI pipelines, Rust Maven’s example workflows, Dev.to’s Rust CI article, and the Bevy engine’s CI template.[3][6][9][10][11][19] These sources demonstrate multi-job workflows, matrices, and integration of tools like Clippy and Rustfmt. `Swatinem/rust-cache` and its README detail caching behavior and configuration, while `dtolnay/rust-toolchain`’s README explains toolchain selection and outputs such as cache keys.[12][13][14]

Path-filter mechanisms are documented in the `dorny/paths-filter` GitHub repository and `paths-changes-filter` marketplace entry, while NetBay Hosts and Rabinarayan Patra’s posts provide interpretive guidance and caution for workflow-level path filters.[7][15][16][17] Atharva Pandey’s CI/CD lesson explains rust-cache usage, shared keys, and coverage integration.[20] Collectively, these sources support the recommendation for multi-job topology and job-level changes detection in `rs-launch-blueprint` CI.

## Ecosystem-Specific Considerations, including Web Surface (R69)

The optional web/API surface governed by R69 introduces additional considerations for CI job structure. Web-specific checks may include OpenAPI snapshot validation, documentation correctness gates, integration tests against mocked services, and static analysis of web routes. These checks can be heavy, particularly when generating documentation or running extensive test suites, and should not be run on CLI/library-only changes.

The recommended changes-detector pattern naturally accommodates this by defining a `web` filter in `dorny/paths-filter` or `paths-changes-filter` configuration, matching files in `web/**`, `api/**`, or other web-related directories.[7][17] The `changes` job sets `web_changed` based on this filter, and downstream jobs such as `web-check` and `web-test` are conditioned on this output. This pattern is analogous to Python’s use of `lint-changes` to gate specific lint jobs based on changed paths, but extended to Rust and web surfaces.[docs context]

In practice, this means that if a pull request modifies only CLI or library crates, web-specific jobs will be skipped. If a pull request modifies only web files, core test jobs may be skipped or limited, depending on how tightly coupled web and core code are. The template should default to a conservative approach, running core tests when web changes could affect core behavior, but the pattern allows fine-grained control. Axum’s CI pipeline, which validates multiple crates and documentation across an HTTP surface, provides indirect evidence that such partitioning is feasible and beneficial.[10]

The topology and changes-detector patterns therefore scale to the web surface without requiring additional architectural decisions beyond those already recommended. They model how multi-surface Rust projects can maintain resource-aware validation while preserving correctness and clarity.

## Conclusion

R11’s decision for `rs-launch-blueprint` is that the CI workflow should adopt a **multi-job, staged GitHub Actions pipeline with a dedicated job-level changes-detector**, rather than a single shared job without skip-gating. This design is informed by first-party Rust CI guidance, production practice in Axum, Tokio, Bevy, and Microsoft’s Rust training, and cross-repo principles derived from the Python and TypeScript templates.[1][2][5][8][9][10][11][12][13][14][15][16][17][19][20]

The multi-job topology separates fast checks from heavy validation, uses OS matrices for tests across `ubuntu-latest` and `macos-latest`, isolates MSRV verification into a dedicated job, and provides natural homes for coverage, docs gates, security scanning, and web-specific checks. It uses `dtolnay/rust-toolchain` and `Swatinem/rust-cache` to amortize Rust’s compile cost across jobs, making repeated setup cheap enough that parallelism and clarity become decisive advantages.[5][12][13][14][20] It encodes dependencies via `needs:` edges, ensuring that `changes` and `check` run before heavy jobs and that failures in early stages abort downstream work.

The changes-detector pattern implements principled pruning via a `changes` job that uses `dorny/paths-filter` or `paths-changes-filter` to classify changes into documentation, core code, and web surface. It sets outputs consumed by downstream jobs and avoids workflow-level `paths` or `paths-ignore` filters that could hide required status checks.[7][15][16][17] This pattern allows docs-only and surface-isolated changes to skip heavy jobs, conserving resources while maintaining correctness.

Cross-repo analysis shows that while Python and Rust adopt multi-job, changes-gated patterns, TypeScript’s single-job CI remains justifiably simpler due to its different ecosystem characteristics and workload. The shared principles—fast feedback, resource-aware validation, clarity of responsibilities, MSRV and multi-OS compliance, and avoidance of hidden checks—are preserved across blueprints, even as their implementations diverge.[docs context]

The recommended CI structure sets the stage for other items—R02, R12, R13—to integrate their concerns into well-defined jobs. It provides consumers of `rs-launch-blueprint` with a robust, principled CI architecture that can scale with project complexity while remaining comprehensible and maintainable.

## Sources

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

## Cost

Total: $1.0055
