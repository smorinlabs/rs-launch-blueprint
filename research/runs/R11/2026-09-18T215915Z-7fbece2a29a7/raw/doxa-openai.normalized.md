## Reasoning Summary
**Researching project workflows**

I think I should only rely on official documentation and source repositories for accurate information. It might be useful to survey mainstream projects like Tokio, Ripgrep, Clap, and Axum. Perhaps even check the Rust compiler and Cargo. I want to see their actual workflows. I need to search raw GitHub data. It's important for me to determine job structures and path filtering for a solid understanding of how these projects operate.

### Landscape

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

### Principles and implementation

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

### Recommendation

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

### Members

#### Conservative Change-Gated Capability Fan-Out

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

#### SHA-pinned dorny/paths-filter v4.0.3

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

### Compatibility

The two members are natively composable:

1. `dorny/paths-filter` documents a `changes` job exporting outputs to jobs that directly `need` it.
2. Coder’s production workflow uses the exact recommended v4.0.3 SHA and derives `docs-only` by comparing documentation and all-file counts.
3. Microsoft’s Agent Governance Toolkit uses the same detector-job/fan-out architecture and exposes a Rust-specific output.
4. GitHub’s native job-output and `needs:` semantics are the interface between detector and capability jobs. ([github.com](https://github.com/dorny/paths-filter))

No maintained reference was found that exactly combines the proposed job list, Rust edition 2024, stable-minus-two MSRV, Ubuntu/macOS matrix and optional CLI/library/web surfaces. That is the remaining integration-evidence gap; the executable acceptance suite below is mandatory before implementation acceptance.

R10’s cache member can be inserted independently into every compiling job. R02 can clone a path-gated capability job. R13 receives a dedicated, always-on job. R12 can later add a fan-in over the stable IDs. None requires restructuring the detector contract.

### Parameters

`owns ci-job-structure = Conservative Change-Gated Capability Fan-Out: one separately named job per independently governed check or environment; setup and related invocations remain steps; one PR-only changes root; shallow fan-out; no check-to-check needs edges; full suite on non-PR events; docs-only skips Rust-heavy jobs; dedicated Ubuntu MSRV job; stable build/test matrix on ubuntu-latest and macos-latest; no aggregate-status decision`

`assumes web-extra-surface = optional web/API workspace surface whose surface-only jobs consume the changes.web output`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI; concrete research-date floor is 1.96 because current stable is 1.98.1` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`CONFLICT: none`

### Migration implications

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

### Validation strategy

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

### Confidence & re-verify trigger

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

### Sources

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

## Sources

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
