### Landscape

**Decision category.** R49 decides the manifest-native declaration of a Rust package's distributable source, library target, and executable target. It does not decide release-binary production (R68) or install-smoke cadence (R50). The three-bin map is: **built-in or first-party toolchain:** Cargo manifest target tables, `cargo package`, and Cargo features; **established industry standard:** explicit target declarations in `Cargo.toml`, exemplified by `ripgrep`; **up-and-comer or supplemental tooling:** `cargo-dist` and `cargo-make`. Cargo is the dominant choice because it is the Rust project's package manager and owns the manifest format; the other two tools add release orchestration or task automation rather than define a Cargo package's targets. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html) and [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05; [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md) and [cargo-make README](https://github.com/sagiegurari/cargo-make/blob/master/README.md), retrieved 2026-09-05.

**Authorities and practice.** The Rust project's Cargo Book is authoritative for target discovery, target-table semantics, feature gating, and package assembly because Cargo implements these interfaces. crates.io is authoritative for registry download and release figures. Each candidate's maintained repository is authoritative for its own stated scope and declared metadata. `ripgrep` is a relevant production CLI-plus-library-shaped package: its manifest explicitly maps the `ripgrep` distribution to the `rg` binary; its crates.io endpoint reported 120,951 downloads in the preceding 90 days and 1,554,665 all-time downloads, evidence of substantial current use rather than an assertion of quality. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), [ripgrep manifest](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.toml), and [ripgrep crates.io endpoint](https://crates.io/api/v1/crates/ripgrep), retrieved 2026-09-05.

**Gate-first survey.** Cargo is a toolchain capability, not a `Cargo.toml` dependency; crate download, release, RustSec, dependency-tree MSRV, and `unsafe`-code metrics are therefore **inapplicable** to it. Its proposed use adds no runtime dependency, binary payload, or crate compilation cost beyond the template itself. `cargo-dist` and `cargo-make` were measured before popularity was considered. Neither qualifies for R49: `cargo-dist` is release-artifact orchestration owned by R68, while `cargo-make` lacks a declared `rust-version` and both candidates' RustSec package endpoints returned HTTP 404, so an open-advisory result could not be verified. GitHub comment requests then reached the unauthenticated core rate limit, so the required ten-issue maintainer-response median is unverified for both tools. [cargo-dist crates.io endpoint](https://crates.io/api/v1/crates/cargo-dist), [cargo-make crates.io endpoint](https://crates.io/api/v1/crates/cargo-make), [cargo-dist RustSec endpoint](https://rustsec.org/packages/cargo-dist.html), [cargo-make RustSec endpoint](https://rustsec.org/packages/cargo-make.html), and [GitHub rate-limit documentation](https://docs.github.com/rest/using-the-rest-api/rate-limits-for-the-rest-api), retrieved 2026-09-05.

| Candidate | License and MSRV gate | RustSec and `unsafe` gate | Ubuntu/macOS and feature coupling | Size and compile cost | Result before popularity |
|---|---|---|---|---|---|
| Cargo manifest plus `cargo package` | Toolchain capability; compatible with the owner-fixed license and MSRV policy when the package declares `license` and `rust-version`. | Inapplicable: no added crate. | Cargo targets and features are the native mechanism; planned CI must prove both fixed operating systems. | No added dependency or artifact. | Passes as the native architecture. |
| `cargo-dist` 0.32.0 | `MIT OR Apache-2.0`; declared Rust 1.74, which does not conflict with a newer template floor. | RustSec endpoint HTTP 404; `unsafe` posture not reviewed. | OS evidence not collected; its README says it plans/builds/distributes releases, which is R68 scope. | Additional release-tool install and generated CI. | Excluded from R49 scope; gate evidence incomplete. |
| `cargo-make` 0.37.24 | Apache-2.0; no `rust-version` in its manifest, so it fails the declared-MSRV gate. | RustSec endpoint HTTP 404; `unsafe` posture not reviewed. | README describes a task runner with default `tls-rustls`; OS support was not verified from CI. | Additional task-runner dependency and feature-selected TLS build. | Excluded by MSRV gate. |

The candidate versions and figures above came from the required endpoints: `cargo-dist` reported 19,772 90-day and 174,408 all-time downloads; its newest non-yanked release was 0.32.0 on 2026-05-22. `cargo-make` reported 249,640 90-day and 3,654,926 all-time downloads; its newest non-yanked release was 0.37.24 on 2025-01-18. GitHub reported `cargo-dist` at 2,106 stars, not archived, last pushed 2026-09-05, with 296 open issues; it reported `cargo-make` at 2,950 stars, not archived, last pushed 2026-02-05, with 64 open issues. [cargo-dist crate endpoint](https://crates.io/api/v1/crates/cargo-dist), [cargo-dist versions endpoint](https://crates.io/api/v1/crates/cargo-dist/versions), [cargo-make crate endpoint](https://crates.io/api/v1/crates/cargo-make), [cargo-make versions endpoint](https://crates.io/api/v1/crates/cargo-make/versions), [cargo-dist repository endpoint](https://api.github.com/repos/axodotdev/cargo-dist), [cargo-dist issue-search endpoint](https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open), [cargo-make repository endpoint](https://api.github.com/repos/sagiegurari/cargo-make), and [cargo-make issue-search endpoint](https://api.github.com/search/issues?q=repo:sagiegurari/cargo-make+is:issue+is:open), retrieved 2026-09-05.

### Principles and implementation

**Shared requirement and agreement level.** F211 is the shared architectural pattern: source becomes a distributable package. F212 is only the language-bound tool implementing that pattern, so agreement is required at the capability level, not at the Python PEP 517 or TypeScript bundler mechanism. Cargo's `cargo package` creates a compressed `.crate`, applies package-content rules, extracts it, and builds the extraction unless verification is disabled. That realizes the required behavior without a backend or bundler dependency. [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05.

**Architecture comparison.** Native Cargo declares one library in `[lib]` and one or more executables in `[[bin]]`; an executable can use its package library. A `build.rs` build script is for native-code compilation or linking, not an entry-point or package-layout declaration. `cargo-make` is a task runner that invokes Cargo. `cargo-dist` plans and builds release artifacts and generates release CI. Therefore neither supplemental tool replaces target declarations; adding either to solve R49 would increase integration surface while leaving the actual manifest decision unchanged. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [Cargo build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html), [cargo-make README](https://github.com/sagiegurari/cargo-make/blob/master/README.md), and [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md), retrieved 2026-09-05.

**Essential behavior and acceptance criteria.** The package must build `src/lib.rs` as the reusable `rs_launch_blueprint` library and `src/main.rs` as the installable `rs-launch-blueprint` executable. The manifest must explicitly disable automatic binary discovery so that an accidental `src/bin/*` file cannot become a second shipped command. It must include only the intended source and publication documents in the `.crate`. The optional web surface remains an R69 decision: a Cargo feature can conditionally compile an optional dependency, but R49 must not predeclare a web binary or its feature. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html) and [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-05.

**Minimal realistic example and status.** The proposed manifest below is an unexecuted acceptance fixture, not a result from this run. It preserves the CLI, library, and future optional-web composition without a build-orchestration crate.

```toml
[package]
name = "rs-launch-blueprint"
edition = "2024"
rust-version = "<owner-fixed stable-minus-two floor>"
license = "MIT OR Apache-2.0"
autobins = false
include = ["/src/**", "/README.md", "/CHANGELOG.md", "/LICENSE-APACHE", "/LICENSE-MIT"]

[lib]
name = "rs_launch_blueprint"
path = "src/lib.rs"

[[bin]]
name = "rs-launch-blueprint"
path = "src/main.rs"
```

The important reading is that Cargo's `name` and `path` fields declare each target directly; no callable-reference or built-file-path abstraction is missing. The hyphen-to-underscore library-name normalization is Cargo's normal library rule, not a distribution/command divergence. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), retrieved 2026-09-05.

BASELINE-REVIEW: F218 — deliberate package-content boundary — replace the recorded “default: git-tracked files only” premise with an explicit `[package].include` whitelist and `cargo package --list` verification — Cargo's documented default is all root files except stated exclusions and VCS-ignore rules, not tracked files only; global Git ignore rules can affect it. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.

### Dominant choice

**Cargo target declarations, with no build-backend dependency or version range.** Cargo is supplied by the selected Rust toolchain rather than declared under `[dependencies]`, so the correct dependency value is absent, not a fabricated crate name and version. Use the owner-fixed `rust-version` as Cargo's compatibility contract. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.

### Qualified shortlist

Only one architecture qualifies: **Cargo manifest targets** — role: native package, library, executable, feature, and `.crate` declaration; 90-day downloads, all-time downloads, stars, and registry release: **inapplicable** because Cargo is a toolchain component rather than a crates.io dependency; maintenance: active Rust-project toolchain; adopters: `ripgrep` demonstrates an explicit `[[bin]]` target in a widely downloaded package; trade-off: the manifest remains declarative, so release-artifact orchestration belongs in R68 rather than here. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [ripgrep manifest](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.toml), and [ripgrep crates.io endpoint](https://crates.io/api/v1/crates/ripgrep), retrieved 2026-09-05.

### Excluded by gate

- **`cargo-make` 0.37.24:** excluded because its published manifest does not set `rust-version`; the owner-fixed policy requires a declared and CI-tested floor. Its default feature is `tls-rustls`, so it also adds feature and compile-time surface unrelated to declaring package targets. [cargo-make manifest](https://github.com/sagiegurari/cargo-make/blob/master/Cargo.toml) and [cargo-make versions endpoint](https://crates.io/api/v1/crates/cargo-make/versions), retrieved 2026-09-05.

- **`cargo-dist` 0.32.0:** excluded from this item's decision because its maintained scope is release planning, binary/installer construction, hosting, publishing, and release CI. Those artifact choices are explicitly R68's scope. Its incomplete RustSec and target-OS evidence is recorded in `Landscape`; it is not promoted on popularity alone. [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md), [cargo-dist manifest](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml), and [cargo-dist RustSec endpoint](https://rustsec.org/packages/cargo-dist.html), retrieved 2026-09-05.

### Up-and-comers

`cargo-dist` 0.32.0 is the relevant emerging release-automation tool, not an R49 implementation candidate. It may become an R68 runner-up if that item chooses cross-platform release binaries; R49 should only expose stable target inputs for it to consume. `cargo-make` is an established task-runner alternative, not a build-output declaration mechanism. [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md) and [cargo-make README](https://github.com/sagiegurari/cargo-make/blob/master/README.md), retrieved 2026-09-05.

### Fit for this template

**CLI.** `[[bin]] name = "rs-launch-blueprint" path = "src/main.rs"` gives Cargo a direct executable target, and `cargo install rs-launch-blueprint` installs the package's binary without a separate entry-point declaration. Matching package and binary names avoids the `cargo install --bin <name>` disambiguation that a divergent name would require. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html) and [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html), retrieved 2026-09-05.

**Library.** `[lib] name = "rs_launch_blueprint" path = "src/lib.rs"` gives dependents the Rust-normalized import crate name while retaining the hyphenated distribution and command name. The library's API remains owned by the public-surface work, not by this target declaration. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), retrieved 2026-09-05.

**Web.** Do not add a web `[[bin]]` now. Cargo features express conditional compilation and optional dependencies, but R69 alone chooses whether the web service exists, its feature name, and whether it is a subcommand, server API, or separate executable. The recommendation is therefore compatible with each R69 outcome without deciding it. [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-05.

### Recommendation

Set `build-tool-output-shape` to **Cargo-native explicit targets and explicit package whitelist; no third-party build backend**. Declare the package and command as `rs-launch-blueprint`, the library as `rs_launch_blueprint`, exactly one explicit `[[bin]]` at `src/main.rs`, one `[lib]` at `src/lib.rs`, and `autobins = false`. Use the proposed `include` list, then review it whenever a required published file is added. `cargo package --list` is the readable package-content oracle, and `cargo package` rebuilds the assembled `.crate` by default. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), and [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05.

### Ranked runner-up

**Runner-up: Cargo automatic target discovery.** It wins only if the implementation intentionally adopts Cargo's conventional `src/main.rs` and `src/lib.rs` layout, forbids `src/bin/`, and accepts automatic discovery as the package boundary. The explicit form wins now because R49's value test is a stable, auditable target contract and `autobins = false` prevents an unreviewed additional executable. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), retrieved 2026-09-05.

### Tradeoffs

Compared with automatic discovery, explicit target tables add several manifest lines and require a target-path edit if the layout changes; the accepted cost is an auditable one-binary contract. Compared with the default package set, an explicit `include` list requires updating when adding a required published document; the accepted cost is deterministic, reviewable `.crate` content independent of ignored-file behavior. Compared with `cargo-dist`, this choice does not produce release binaries or installers; that omission is intentional because R68 owns artifact types. Compared with `cargo-make`, it does not collapse arbitrary development tasks into one runner; that omission preserves Cargo's native target model and avoids an undeclared-MSRV tool. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md), and [cargo-make manifest](https://github.com/sagiegurari/cargo-make/blob/master/Cargo.toml), retrieved 2026-09-05.

### Parameters

owns build-tool-output-shape = `cargo-native-explicit-targets; package=rs-launch-blueprint; lib=rs_launch_blueprint@src/lib.rs; bin=rs-launch-blueprint@src/main.rs; autobins=false; package-content=explicit-include; build-backend-dependency=none`.

assumes rust-edition = `2024`; assumes msrv-policy = `stable minus 2 minor versions, declared as rust-version and tested in CI`; assumes license = `MIT OR Apache-2.0`; assumes target-os-matrix = `ubuntu-latest, macos-latest`; assumes web-extra-surface = `R69 unresolved and must not be predeclared as a target`. The fixed parameter values are recorded in the repository's parameter registry; Cargo supplies the fields that express them. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html) and [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-05.

### Migration implications

Create the root `Cargo.toml` with the proposed `[package]`, `[lib]`, and `[[bin]]` declarations. Create `src/lib.rs`, the library API root, and `src/main.rs`, the CLI composition root. Add `README.md`, `CHANGELOG.md`, `LICENSE-APACHE`, and `LICENSE-MIT` to the whitelist only if they exist and are intended to ship; Cargo always includes its manifest and an explicitly declared license file, but keeping the list explicit makes the intended package reviewable. Do not add `build.rs`, `cargo-make`, or `cargo-dist` for this item. R69 may later add a feature and optional dependency; R68 may later add release tooling without changing these targets. [Cargo manifest](https://doc.rust-lang.org/cargo/reference/manifest.html), [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), and [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05.

### Validation strategy

**Planned checks; none were executed in this raw-research run.** From the future repository root, run the following commands after the named files exist:

```sh
cargo check --all-targets
cargo test --all-targets
cargo build --bin rs-launch-blueprint
cargo package --list
cargo package
```

Expected behavior: the first two commands compile and test both `src/lib.rs` and `src/main.rs`; the binary build emits only `rs-launch-blueprint`; `cargo package --list` contains only the whitelist plus Cargo-required files; and `cargo package` creates then rebuilds a pristine `.crate`. On both fixed CI operating systems, add `cargo run --bin rs-launch-blueprint -- --help` after R60 supplies the command surface. If R69 introduces a `web` feature, add `cargo check --all-targets --features web`; whether that feature adds a binary remains R69's decision. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), and [Cargo features](https://doc.rust-lang.org/cargo/reference/features.html), retrieved 2026-09-05.

### Confidence & re-verify trigger

**Confidence: high for the native target and package-content mechanics; medium for the final public command name.** Re-verify before implementation if R69 chooses a separate server executable, if R68 requires target metadata beyond Cargo's base `.crate`, if the owner changes the MSRV/OS policy, or if a required published file changes. Re-query `cargo-dist` only when R68 evaluates release artifacts. Re-query GitHub issue responsiveness and RustSec only if either third-party tool is reconsidered, because those metrics were not fully verifiable in this run. [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [Cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), and [GitHub rate-limit documentation](https://docs.github.com/rest/using-the-rest-api/rate-limits-for-the-rest-api), retrieved 2026-09-05.

### Sources

- Rust Project: [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html), [manifest format](https://doc.rust-lang.org/cargo/reference/manifest.html), [features](https://doc.rust-lang.org/cargo/reference/features.html), [build scripts](https://doc.rust-lang.org/cargo/reference/build-scripts.html), [cargo package](https://doc.rust-lang.org/cargo/commands/cargo-package.html), and [cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html), retrieved 2026-09-05.
- Registry figures: [cargo-dist](https://crates.io/api/v1/crates/cargo-dist), [cargo-dist versions](https://crates.io/api/v1/crates/cargo-dist/versions), [cargo-make](https://crates.io/api/v1/crates/cargo-make), [cargo-make versions](https://crates.io/api/v1/crates/cargo-make/versions), [ripgrep](https://crates.io/api/v1/crates/ripgrep), and [ripgrep versions](https://crates.io/api/v1/crates/ripgrep/versions), retrieved 2026-09-05.
- Maintainer and practice sources: [ripgrep `Cargo.toml`](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.toml), [cargo-dist README](https://github.com/axodotdev/cargo-dist/blob/main/README.md), [cargo-dist `Cargo.toml`](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml), [cargo-make README](https://github.com/sagiegurari/cargo-make/blob/master/README.md), and [cargo-make `Cargo.toml`](https://github.com/sagiegurari/cargo-make/blob/master/Cargo.toml), retrieved 2026-09-05.
- Maintenance endpoints: [cargo-dist repository](https://api.github.com/repos/axodotdev/cargo-dist), [cargo-dist open-issue search](https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open), [cargo-make repository](https://api.github.com/repos/sagiegurari/cargo-make), [cargo-make open-issue search](https://api.github.com/search/issues?q=repo:sagiegurari/cargo-make+is:issue+is:open), [cargo-dist RustSec page](https://rustsec.org/packages/cargo-dist.html), and [cargo-make RustSec page](https://rustsec.org/packages/cargo-make.html), retrieved 2026-09-05.

Method notes: Queried the required crates.io crate and versions endpoints for `cargo-dist`, `cargo-make`, and the production-practice reference `ripgrep`; queried the required GitHub repository and open-issue search endpoints for `cargo-dist` and `cargo-make`; queried both specified RustSec package endpoints; and read the Rust Project Cargo documentation plus maintained upstream manifests. The RustSec endpoints returned HTTP 404, so no advisory conclusion was invented. The unauthenticated GitHub core limit was exhausted after the repository/search measurements, so comments for the required ten newest issues could not be inspected and the responsiveness median/unanswered count remains unverified. No test fixture or Cargo command was run because this run was constrained to writing this raw report.
