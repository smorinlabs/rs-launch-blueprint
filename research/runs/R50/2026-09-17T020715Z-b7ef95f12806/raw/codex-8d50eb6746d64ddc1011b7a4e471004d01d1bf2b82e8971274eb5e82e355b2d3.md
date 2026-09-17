### Landscape

Category: an install-and-run release-proximity check for a Cargo binary. The built-in/first-party bin contains `cargo install --path . --root <temporary-root> --locked` (the install candidate), `cargo run --locked` (a local-execution alternative), and `cargo package` (a package-content alternative owned by R26, not a candidate here). The established-practice bin contains a named `just install-smoke` recipe invoked by a GitHub Actions job. The up-and-comer bin contains `cargo-binstall` and `cargo-dist`; neither is shortlisted because both exercise downloaded release artifacts rather than a just-built local source installation, so R68 owns their distribution question. Cargo is the Rust Project's package manager, and its maintained integration suite tests installation semantics; that is stronger authority for this operation than a third-party blog. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [Cargo install test suite](https://github.com/rust-lang/cargo/blob/495c385d0875c4ba51eb72ea0448a2d4c018b8d4/tests/testsuite/install.rs) (retrieved 2026-09-16); [Cargo repository API](https://api.github.com/repos/rust-lang/cargo) (retrieved 2026-09-16).

The authoritative set is the Cargo Book for command semantics, the Cargo CI guide for a normal PR build-and-test baseline, and GitHub's workflow syntax for path-filter behavior; each is maintained by the project that defines the relevant interface. Practice evidence is Cargo's own install suite, while the pinned py blueprint is the direct same-purpose reference: its `build-smoke` job builds artifacts and invokes the installed CLI on code changes. The pinned ts blueprint instead keeps `pack-check` local and does not invoke it from CI; its recipe combines package-content checks and a scratch npm install, so it is evidence of a local workflow, not evidence against R50's distinct installed-artifact capability. [Cargo CI guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-16); [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16); [py CI at pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/ci.yml#L204-L226) (retrieved 2026-09-16); [ts Justfile at pin](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/Justfile#L276-L319) (retrieved 2026-09-16); [ts CI at pin](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/.github/workflows/ci.yml) (retrieved 2026-09-16).

### Principles and implementation

The shared requirement is release-proximity confidence: a code change must prove that a fresh, isolated installation exposes a runnable CLI before merge. Its agreement level is a capability/standard, not a requirement to reuse `uvx`, npm, or a particular CI topology. F221 records the cadence disagreement and F222 records py's ephemeral install-and-run mechanism; R26 separately owns packed-file assertions, so neither `cargo package --list` nor an archive-content assertion belongs in this answer. Acceptance is observable when a code-touching PR fails if an isolated installation cannot place and execute the selected binary with `--version`, and docs-only changes do not spend the compile cost. [F221/F222 ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L225-L226) (retrieved 2026-09-16); [R50 prompt, binding run input](../../inputs/prompt.md) (retrieved 2026-09-16).

`cargo install --path . --root <temporary-root> --locked` is the closest Rust-native analogue. Cargo documents that `install` builds and installs executable targets into the chosen root's `bin` directory; `--path` selects local source, always builds and installs, `--root` prevents mutation of the user's normal install root, and `--locked` makes resolution fail rather than change the lockfile. It therefore tests the missing question that `cargo run --locked` cannot: `cargo run` runs a binary of the current checkout and never exercises the installed path. It intentionally does not prove the archive file list; that is R26's complementary question. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [Cargo run manual](https://doc.rust-lang.org/cargo/commands/cargo-run.html) (retrieved 2026-09-16); [Cargo package manual](https://doc.rust-lang.org/cargo/commands/cargo-package.html) (retrieved 2026-09-16).

The alternatives are: local-only `just install-smoke`, which leaves a merge-time packaging regression undiscovered; `cargo run --locked`, which is cheaper but is not an install check; and a published-registry or release-binary test, which adds network/release coupling and belongs with R68. A dedicated CI `install-smoke` job on every code-touching PR best preserves the capability because it runs in a clean runner and supplies an independent required result. Rust compilation makes the added job materially more expensive than py's interpreted `uvx` invocation; no transferable timing figure exists before P03 creates the dependency graph, so the cost must be measured rather than guessed. The recommended matrix is the owner-fixed `ubuntu-latest` and `macos-latest`, with the existing changes-detector contract deciding whether a PR is code-touching. [Cargo CI guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-16); [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16); [fixed target OS parameter](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

No `BASELINE-REVIEW:` finding is emitted: F221 is already `DIVERGENT`, and the proposal preserves its required capability while selecting a Rust-native mechanism with direct toolchain evidence. [verdict vocabulary](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/README.md#verdict-vocabulary-closed-set--enforced-by-scriptscheck-research-treesh) (retrieved 2026-09-16).

### Recommendation

Adopt one stack: stable Cargo's `cargo install --path . --root <mktemp-root> --locked`, followed by the installed R49-selected binary's `--version`; expose it as grouped Justfile recipe `install-smoke`; run that recipe in a required `install-smoke` GitHub Actions matrix job on `ubuntu-latest` and `macos-latest` for every code-touching PR. Keep `cargo package --list` and publish/dry-run checks out of the recipe because R26 owns them. Use no new Rust crate or GitHub Action. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [F176-F178 retained Just convention](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L180-L182) (retrieved 2026-09-16); [F221/F222 ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L225-L226) (retrieved 2026-09-16).

### Members

#### Cargo isolated installation pattern

##### Landscape

This is a first-party Cargo command pattern, not a third-party crate. `cargo install --path` is the only shortlisted mechanism that both builds from the local source and puts executables under an explicit installation root; `cargo run` is the local-execution comparator. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [Cargo run manual](https://doc.rust-lang.org/cargo/commands/cargo-run.html) (retrieved 2026-09-16).

##### Principles and implementation

The principle is an isolated consumer-style executable path. The recipe creates one temporary directory, passes its child directory to `--root`, installs from `--path .` with `--locked`, and invokes `<R49-selected-bin> --version` from that root's `bin` directory. The binary name is supplied by R49's accepted target declaration; R50 does not choose it. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [R49/R50 relationship](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md#L179-L182) (retrieved 2026-09-16).

##### Dominant choice

`cargo install --path . --root <temporary-root> --locked` is the dominant choice because Cargo specifies its executable-install and isolated-root behavior. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16).

##### Qualified shortlist

The qualified shortlist is first-party Cargo only: the dominant install pattern and `cargo run --locked`. `cargo run` qualifies as a useful build-and-run check but not as a satisfactory install-and-run replacement. [Cargo run manual](https://doc.rust-lang.org/cargo/commands/cargo-run.html) (retrieved 2026-09-16).

##### Excluded by gate

`cargo package --list` is excluded by scope, not fitness: it assesses package contents and R26 owns F039/F078. `cargo-binstall` and `cargo-dist` are excluded by fit because they require release-distribution artifacts rather than validating the local source install path; R68 owns that artifact decision. [R26/R50 separation](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L225-L226) (retrieved 2026-09-16); [R68 index entry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md) (retrieved 2026-09-16).

##### Up-and-comers

No up-and-comer is recommended. `cargo-binstall` and `cargo-dist` remain a re-verification lead if R68 changes the chosen distribution artifact, not a substitute for the source-install check. [R68 index entry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md) (retrieved 2026-09-16).

##### Fit for this template

License, crates.io downloads, release recency, GitHub stars/issues/responsiveness, RustSec advisories, dependency-tree MSRV, and `unsafe` posture are inapplicable because this member adds no crate or dependency. Cargo is the installed stable toolchain selected by the fixed MSRV policy; the proposed command must be run on both required hosts with that policy's floor and stable toolchains. Default features are exercised because no feature flag is passed; async-runtime coupling is none. The compile-time cost is one additional Cargo compilation per OS job, and binary-size cost is none because no shipping dependency is added. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [Cargo `rust-version` reference](https://doc.rust-lang.org/cargo/reference/rust-version.html) (retrieved 2026-09-16); [fixed parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

##### Recommendation

Use `cargo install --path . --root "$scratch/root" --locked`, then execute `"$scratch/root/bin/<R49-selected-bin>" --version`; this is proposed, not executed, because P03 has not created the template. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [R50 objective](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Ranked runner-up

Runner-up: `cargo run --locked -- --version`. It proves that the checkout can build and launch its selected binary, but Cargo defines it as running the current package, so it does not check installation-root placement or invocation after installation. [Cargo run manual](https://doc.rust-lang.org/cargo/commands/cargo-run.html) (retrieved 2026-09-16).

##### Tradeoffs

The dominant pattern recompiles and is slower than `cargo run` or a shell-only assertion, but it catches install-target, executable-placement, and install-resolution failures those alternatives omit. `--locked` favors reproducibility over receiving newer dependency fixes during the check; that aligns the test with the committed lockfile and makes an attempted lockfile change fail. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16).

##### Parameters

assumes `rust-edition = 2024`; assumes `msrv-policy = stable minus 2 minor versions, declared in Cargo.toml and tested in CI`; assumes `license = MIT OR Apache-2.0`; assumes `target-os-matrix = ubuntu-latest, macos-latest`. No consumed registry parameter is changed and no `CONFLICT:` exists. [R50 fixed parameters](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Migration implications

P03 adds the command to `Justfile` and invokes it from `.github/workflows/ci.yml`; it does not add a Cargo dependency, alter `Cargo.toml` targets, or implement package-content validation. [R50 scope boundaries](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Validation strategy

Planned check, once P03 supplies R49's binary name: create a `mktemp -d` scratch directory, install with `--root` and `--locked`, invoke the installed binary's `--version`, and delete the scratch directory. Expected result: exit status zero and a version string; a missing executable, install error, or nonzero invocation fails the recipe. The same recipe runs on both owner-required OS runners. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16).

##### Confidence & re-verify trigger

High confidence in command semantics because Cargo documents them and tests installation itself. Re-verify if R49 changes from an installable `[[bin]]` target, if R68 replaces source installation with release artifacts, or if Cargo changes `install --path`/`--root`/`--locked` semantics. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16).

##### Sources

Primary sources: [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html), [Cargo run](https://doc.rust-lang.org/cargo/commands/cargo-run.html), and [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), all retrieved 2026-09-16. Pattern-member figure fields are inapplicable; no crate is selected.

#### CI cadence and Justfile interface pattern

##### Landscape

This is an established CI and task-runner pattern, not a crate selection. The candidates are a local-only recipe, an unconditional PR job, and a code-path-filtered PR job. The pinned py implementation is the direct practice reference for the last option; the pinned ts implementation is the direct local-only counterexample. [py CI at pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/ci.yml#L204-L226) (retrieved 2026-09-16); [ts Justfile at pin](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/Justfile#L276-L319) (retrieved 2026-09-16).

##### Principles and implementation

The requirement is that a code PR cannot merge without the isolated-install result, while changes outside the code path avoid unnecessary compilation. GitHub supports workflow path filters, and py's pinned `changes` job shows the safer template-local shape: leave the workflow present and condition the smoke job on a code-change output. The Justfile provides the same command locally and in CI, preserving one command surface without making Just a new R50 dependency choice. [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16); [py CI at pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/ci.yml#L204-L226) (retrieved 2026-09-16); [F176-F178](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L180-L182) (retrieved 2026-09-16).

##### Dominant choice

Use a required `install-smoke` job, matrixed over `ubuntu-latest` and `macos-latest`, conditional on the existing code-change result, and run `just install-smoke`. This makes the proof merge-gating for every code-touching PR without scheduling it for documentation-only work. [py CI at pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/ci.yml#L204-L226) (retrieved 2026-09-16); [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16).

##### Qualified shortlist

The qualified shortlist is local-only Justfile recipe, unconditional CI job, and path-filtered CI job. All can execute Cargo on both required hosts; only the path-filtered CI job satisfies the release-proximity capability while controlling obviously irrelevant PR cost. [Cargo CI guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-16); [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16).

##### Excluded by gate

The local-only option fails the merge-gate acceptance criterion. The unconditional option is excluded by fit because it compiles Rust on documentation-only PRs despite GitHub providing a path-selection mechanism; it remains a viable fallback only if R11 does not provide a reliable changes-detector interface. [R50 questions](../../inputs/prompt.md) (retrieved 2026-09-16); [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16).

##### Up-and-comers

No new CI framework or action is recommended. The job consumes the repository's selected checkout, Rust-toolchain, cache, and change-detection arrangements; their selection belongs to their respective items rather than R50. [research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md) (retrieved 2026-09-16).

##### Fit for this template

License, crate downloads/releases, GitHub issue responsiveness, RustSec advisories, dependency-tree MSRV, and `unsafe` posture are inapplicable because this member introduces no crate. The job uses stable Cargo, has no async-runtime coupling, and exercises default features. It adds one compile/install attempt per OS job; measure wall-clock duration, cache state, runner OS, Rust version, and workflow queue/execution time before deciding whether cache or job-layout changes are justified. [Cargo CI guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html) (retrieved 2026-09-16); [R50 performance requirement](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Recommendation

Name the recipe `install-smoke`, place it in the existing `build` and `releases` Just groups, and do not give it a short alias because it is destructive neither in the repository nor frequently typed enough to justify one. `just` supports multiple recipe groups and aliases, while F176-F178 require the shared command surface rather than a specific new alias. [Just groups](https://just.systems/man/en/groups.html) (retrieved 2026-09-16); [Just aliases](https://just.systems/man/en/aliases.html) (retrieved 2026-09-16); [F176-F178](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/COMMONALITY.md#L180-L182) (retrieved 2026-09-16).

##### Ranked runner-up

Runner-up: retain `just install-smoke` local-only, as ts retained `pack-check`. It gives contributors a reproducible check but cannot prevent an unrun check from merging, so it loses the capability required by this item. [ts Justfile at pin](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/Justfile#L276-L319) (retrieved 2026-09-16); [R50 objective](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Tradeoffs

Two OS runs improve confidence in the fixed support matrix but double this job's cold compile exposure relative to a single runner. Path filtering avoids irrelevant runs but requires the R11 job-structure result to preserve skipped-job handling in the aggregate status design. Do not claim an absolute duration until the P03 artifact and its dependency graph exist. [fixed OS parameter](../../inputs/prompt.md) (retrieved 2026-09-16); [R11/R50 analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md#L90-L92) (retrieved 2026-09-16).

##### Parameters

assumes `target-os-matrix = ubuntu-latest, macos-latest`; assumes R11 supplies a code-change signal compatible with a conditional job; assumes R49 supplies an installable binary target. No R50-owned parameter changes and no `CONFLICT:` exists. [R50 couplings](../../inputs/prompt.md) (retrieved 2026-09-16); [R11/R49/R50 analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md#L90-L92) (retrieved 2026-09-16).

##### Migration implications

P03 adds `install-smoke` in `Justfile`, adds an `install-smoke` matrix job in `.github/workflows/ci.yml`, and makes the job conditional on the selected changes detector. It must not modify R26's package-content recipe or add a web-service lifecycle test. [R50 scope](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Validation strategy

Planned CI check: submit one source-code change and observe the two matrix executions succeed; submit one docs-only change and observe the job skip according to the changes contract; intentionally break the binary's startup or installation and observe the job fail. Record per-run wall time, cache hit/miss state, OS, Rust version, and queue time. No such check was executed because the Rust template does not yet exist. [GitHub path filters](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions#onpushpull_requestpull_request_targetpathspaths-ignore) (retrieved 2026-09-16); [R50 objective](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Confidence & re-verify trigger

Medium confidence in cadence: the semantic need and command behavior are verified, but actual incremental cost is unmeasured until P03. Re-verify after the first cold and warm matrix runs, if R11 changes skip/aggregate semantics, or if R69 changes the accepted web executable surface. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [R50 questions](../../inputs/prompt.md) (retrieved 2026-09-16).

##### Sources

Primary sources: [GitHub workflow syntax](https://docs.github.com/actions/writing-workflows/workflow-syntax-for-github-actions), [Cargo CI guide](https://doc.rust-lang.org/cargo/guide/continuous-integration.html), [Just groups](https://just.systems/man/en/groups.html), and [Just aliases](https://just.systems/man/en/aliases.html), all retrieved 2026-09-16. Pattern-member figure fields are inapplicable; no crate or action is selected.

### Compatibility

The members compose without a version matrix: the Justfile invokes stable Cargo, and the CI matrix invokes that same recipe. Cargo documents `--root` as the installation-root selector and `bin` as the executable location, while Just documents grouped recipe discovery; neither adds an incompatible crate dependency. Cargo's own maintained install tests provide the shared reference implementation for the installed-executable half. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [Cargo install test suite](https://github.com/rust-lang/cargo/blob/495c385d0875c4ba51eb72ea0448a2d4c018b8d4/tests/testsuite/install.rs) (retrieved 2026-09-16); [Just groups](https://just.systems/man/en/groups.html) (retrieved 2026-09-16).

### Parameters

owns none. Assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`; the R50 prompt fixes all four. Assumes R49 supplies an installable binary and R11 supplies code-change classification; those are coordination assumptions, not a request to change either owner’s parameter. No `CONFLICT:` exists. [R50 prompt](../../inputs/prompt.md) (retrieved 2026-09-16).

### Migration implications

P03 should add `Justfile` recipe `install-smoke` and `.github/workflows/ci.yml` job `install-smoke`; the recipe creates a temporary root, installs with Cargo, invokes the installed R49-selected binary, and cleans up. The workflow runs it on both fixed OS runners for code-touching PRs. Do not edit `Cargo.toml` target declarations (R49), add package file-list assertions (R26), or add web-service lifecycle checks (R69). [R50 out-of-scope and couplings](../../inputs/prompt.md) (retrieved 2026-09-16).

### Validation strategy

Planned local recipe body, after P03 substitutes R49's actual binary name, is:

```sh
scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT
cargo install --path . --root "$scratch/root" --locked
"$scratch/root/bin/<R49-selected-bin>" --version
```

Expected result is exit status zero, version output, no installation outside the temporary root, and cleanup on success or failure. Planned CI validation runs this exact recipe on `ubuntu-latest` and `macos-latest`; it records cold/warm elapsed time plus cache and toolchain state, then injects an entry-point failure to prove the job blocks. These checks are proposed and unexecuted because no Rust template exists. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [R50 objective](../../inputs/prompt.md) (retrieved 2026-09-16).

### Confidence & re-verify trigger

High confidence that Cargo's install pattern answers F222, based on Cargo's specification and maintained install tests. Medium confidence that two-OS PR gating is an acceptable cost because the required workload does not exist yet; re-verify after the first measured cold and warm runs. Reopen if R49 removes the binary target, R11 changes conditional-job semantics, R26 alters the boundary between package and install validation, R68 changes distribution strategy, or R69 requires a separately installed web executable. [Cargo install manual](https://doc.rust-lang.org/cargo/commands/cargo-install.html) (retrieved 2026-09-16); [R50 prompt](../../inputs/prompt.md) (retrieved 2026-09-16).

### Sources

Method notes: queried the official Cargo command/reference/CI pages, official Just manual pages, official GitHub Actions workflow documentation, and GitHub REST through the required local proxy; the real figure endpoint queried was `GET https://api.github.com/repos/rust-lang/cargo` on 2026-09-16. No crates.io, GitHub issue-responsiveness, or RustSec figure is applicable because the recommendation selects no new crate; the retained `just` tool is F176's already accepted dependency, not an R50 member. Pinned precedent was read with `git show` at py `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and ts `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`. The optional owner-reference input was absent at `inputs/owner-reference-axum-companion-stack-2026-09-16.md`, so no row-by-row reconciliation applied. Current CI wall-time cost and the final R49 binary name are unverified until P03.
