### Landscape

Actor `research-codex-2026-09-05T160304Z-11020e4e7e38` surveyed R23 as a version-synchronization pattern: the release transaction must keep the manifest version, the release-please version record, and every committed Cargo lockfile entry for a released workspace member consistent.

The three-bin map is:

| Bin | Candidates | Why it belongs in the bin |
|---|---|---|
| Built-in or first-party toolchain | Cargo lockfile regeneration; `cargo update -p <workspace-member> --precise <version>`; `cargo build --locked` as the inverse guard | Cargo owns the lockfile and documents it as generated state; these commands are the native way to regenerate or reject stale state. [Cargo: Cargo.toml vs Cargo.lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html), retrieved 2026-09-05; [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05; [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html), retrieved 2026-09-05 |
| Established industry standard | release-please `release-type: rust` with its native `CargoLock` updater; release-please `cargo-workspace` for manifest-mode multi-crate workspaces; release-please generic TOML `extra-files` | These are maintained release-please mechanisms documented in its manifest schema, manifest guide, and Rust strategy implementation. [release-please manifest schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json), retrieved 2026-09-05; [manifest-releaser cargo-workspace](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05; [Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05 |
| Up-and-comer or alternative Rust release architecture | release-plz; cargo-release-style workflow; a bespoke CI commit step | These tools and workflow shapes are viable Rust-native alternatives, but switching away from the already-settled release-please mechanism is outside R23. [release-plz introduction](https://release-plz.dev/docs), retrieved 2026-09-05; [release-plz repository](https://github.com/release-plz/release-plz), retrieved 2026-09-05; [cargo-bins/release-pr](https://github.com/cargo-bins/release-pr), retrieved 2026-09-05 |

Authority was established before comparing popularity. The Cargo Book and Rust Book are authoritative for Cargo lockfile and workspace semantics because they are maintained by the Rust project and Cargo team. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05; [The Rust Programming Language: Cargo workspaces](https://doc.rust-lang.org/book/ch14-03-cargo-workspaces.html), retrieved 2026-09-05. Release-please's repository, schema, Rust strategy, updater, and release-please-action v5.0.0 bundle are authoritative for what the selected release mechanism actually implements. [release-please-action v5.0.0 package](https://github.com/googleapis/release-please-action/blob/v5.0.0/package.json), retrieved 2026-09-05; [release-please-action v5.0.0 bundled implementation](https://github.com/googleapis/release-please-action/blob/v5.0.0/dist/index.js), retrieved 2026-09-05. Release-plz's own documentation is authoritative for its own behavior, but is treated as alternative-tool evidence rather than as a reason to replace the inherited release-please decision. [release-plz configuration](https://release-plz.dev/docs/config), retrieved 2026-09-05.

Practice evidence shows that committed lockfiles are normal for serious Rust applications and workspaces. The Rust repository, Cargo repository, ripgrep, and rustls repositories each expose a root `Cargo.lock`; their project pages identify them respectively as the Rust compiler project, Cargo itself, a widely used cross-platform CLI, and a production-used TLS library. [rust `Cargo.lock`](https://github.com/rust-lang/rust/blob/main/Cargo.lock), retrieved 2026-09-05; [Cargo repository](https://github.com/rust-lang/cargo), retrieved 2026-09-05; [ripgrep `Cargo.lock`](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock), retrieved 2026-09-05; [rustls repository](https://github.com/rustls/rustls), retrieved 2026-09-05. The Rust project’s practice is not by itself proof of release-please adoption, but it confirms the target artifact shape that the release mechanism must preserve.

The source precedents were also checked at their recorded revisions. Py uses a TOML `extra-files` entry whose JSONPath targets the editable-root `uv.lock` package version. [py release config at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/release-please-config.json), retrieved 2026-09-05. Ts explicitly says its `pnpm-lock.yaml` has no root version field and therefore needs no sync. [ts release workflow at `cb1cbcb`](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb/.github/workflows/release-please.yml), retrieved 2026-09-05. Cargo is unlike ts: workspace members appear as `[[package]]` records with their own `name` and `version`, and a workspace has one root lockfile. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05; [Rust `Cargo.lock` example](https://github.com/rust-lang/rust/blob/main/Cargo.lock), retrieved 2026-09-05.

### Principles and implementation

The shared requirement is atomic release metadata synchronization: a release PR must not expose a new `Cargo.toml` package version while leaving the committed `Cargo.lock` workspace-member record at the old version. This is an architectural pattern with a policy-level acceptance rule, not a requirement to use the same updater syntax in py, ts, and Rust. Py realizes the pattern with TOML JSONPath because `uv.lock` is TOML; ts correctly omits it because its lockfile has no root package version; Rust should use its native release-please Rust updater because release-please already understands Cargo lockfiles. [py release config at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/release-please-config.json), retrieved 2026-09-05; [release-please generic TOML updater](https://github.com/googleapis/release-please/blob/main/src/updaters/generic-toml.ts), retrieved 2026-09-05; [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05.

The essential behaviors are:

- `Cargo.toml` remains the package version source of truth.
- The release-please Rust strategy includes a `Cargo.lock` update in the release PR. Its `Rust` strategy builds a package-name-to-new-version map, schedules a `Cargo.toml` updater, and then schedules a `CargoLock` updater for `Cargo.lock` with `createIfMissing: false`. [Rust strategy source](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05.
- The `CargoLock` updater parses the lockfile, matches each `[[package]]` record by package name, and replaces only the matching `version` values while preserving formatting and comments. [CargoLock updater source](https://github.com/googleapis/release-please/blob/main/src/updaters/rust/cargo-lock.ts), retrieved 2026-09-05.
- A committed lockfile is checked by CI with `cargo build --locked` or an equivalent locked workspace command. Cargo documents `--locked` as refusing to modify the lockfile when the manifest and lockfile disagree. [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05.
- A consistency test parses the release-managed files and asserts that each released workspace member’s `Cargo.lock` version equals its manifest version. The test should not assert a Rust runtime accessor against the manifest because `CARGO_PKG_VERSION` is supplied by Cargo at compile time and cannot independently drift in the same way. [Cargo environment variables](https://doc.rust-lang.org/cargo/reference/environment-variables.html), retrieved 2026-09-05; [baseline review F133](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/BASELINE-REVIEW.md), retrieved 2026-09-05.

Observable acceptance criteria are:

1. The release configuration selects `release-type: rust` for the released package and does not add a redundant `Cargo.lock` `extra-files` entry.
2. A release-please dry-run or release-PR update includes the changed `Cargo.toml` and the corresponding root `Cargo.lock` entry in one release PR.
3. `cargo build --locked --workspace` and `cargo metadata --locked --format-version 1` pass on `ubuntu-latest` and `macos-latest` after the release update.
4. A meta-test fails when the manifest is bumped but the lockfile entry is stale, and passes after the native release updater changes both.
5. No post-PR CI commit or second release commit is needed to repair `Cargo.lock`.

The generic TOML alternative is technically available. The release-please schema accepts `{ "type": "toml", "path": "Cargo.lock", "jsonpath": "..." }`, and the generic TOML updater parses TOML and applies JSONPath-selected replacements. [release-please config schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json), retrieved 2026-09-05; [generic TOML updater](https://github.com/googleapis/release-please/blob/main/src/updaters/generic-toml.ts), retrieved 2026-09-05. A path shaped like `$.package[?(@.name=="demo-app")].version` would be the natural candidate for a single package, but it duplicates the Rust strategy’s package-name mapping, needs per-workspace-member selection logic, and is not the mechanism tested by the release-please Rust strategy. It is therefore a fallback for a non-Rust release strategy, not the target design.

The architectural alternatives were compared before choosing:

| Alternative | Correctness | Integration cost | Decision |
|---|---|---|---|
| Native release-please Rust strategy | Knows Cargo manifests and lockfile package names; schedules the lock update in the same release PR | Lowest because release-please is already settled | Choose |
| Generic TOML `extra-files` | Can target a selected lockfile record, but correctness depends on a maintained JSONPath for every member and release shape | Moderate; redundant configuration and weaker workspace semantics | Runner-up only if the Rust strategy cannot be used |
| CI `cargo update` after the release PR is opened | Cargo itself produces the right lockfile | High; needs write permissions, pushes a second PR commit, and creates a race between release metadata and lockfile state | Exclude for the atomic-release requirement |
| Switch to release-plz or cargo-release | Rust-native release systems can update `Cargo.lock` and workspace versions | High; replaces the inherited release manager, workflow, tag, auth, and changelog integration | Out of scope for R23 |

`BASELINE-REVIEW: F133 — version-consistency guard must cover every release-managed version surface — retain the Cargo.toml-to-Cargo.lock assertion when R23 selects a committed lockfile and keep only a meaningful accessor/package-identity assertion rather than treating CARGO_PKG_VERSION as an independent source — Cargo’s workspace rule gives one root lockfile and the baseline review identifies the Rust compile-time accessor limitation while retaining a guard against wiring the accessor to the wrong package.` [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05; [baseline review F133](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/BASELINE-REVIEW.md), retrieved 2026-09-05.

### Dominant choice

The dominant choice is release-please’s native Rust strategy: configure the package with `release-type: rust`, commit the root `Cargo.lock`, and let the strategy’s `CargoLock` updater synchronize workspace-member entries. For a manifest-mode multi-crate workspace, add the documented `cargo-workspace` plugin so release-please builds the crate dependency graph and updates dependent package versions and the shared lockfile. [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05; [cargo-workspace plugin documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05.

The mechanism is not a JSONPath entry. The `extra-files` JSONPath mechanism is a generic TOML facility used by the Python precedent; the Rust release strategy directly schedules `CargoLock`. Adding both would create two writers for the same file and would make a release configuration depend on duplicate package-selection logic. [py release config at `b08bccf`](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/release-please-config.json), retrieved 2026-09-05; [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05.

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
|---|---|---|---|
| release-please `release-type: rust` with native `CargoLock` | [Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts); [CargoLock updater](https://github.com/googleapis/release-please/blob/main/src/updaters/rust/cargo-lock.ts) | release-please’s Rust strategy tests assert a `Cargo.lock` update for both a single crate and a workspace; release-please-action v5.0.0 bundles the implementation. [Rust strategy tests](https://github.com/googleapis/release-please/blob/main/test/strategies/rust.ts); [action v5.0.0](https://github.com/googleapis/release-please-action/tree/v5.0.0) | 2026-09-05 |
| release-please generic TOML `extra-files` | [Config schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json); [customizing arbitrary files](https://github.com/googleapis/release-please/blob/main/docs/customizing.md#updating-arbitrary-files) | py-launch-blueprint uses the same TOML updater shape for `uv.lock`; a direct Cargo.lock adopter was not verified. [py config](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/release-please-config.json) | 2026-09-05 |
| Cargo regeneration in a release workflow | [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html); [Cargo lockfile guidance](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html) | Rust applications and workspaces that commit `Cargo.lock`, including Cargo, ripgrep, and rustls, practice the underlying lockfile discipline; their release workflow was not treated as evidence of a specific CI updater. [Cargo](https://github.com/rust-lang/cargo/blob/master/Cargo.lock); [ripgrep](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock); [rustls](https://github.com/rustls/rustls/blob/main/Cargo.lock) | 2026-09-05 |
| release-plz or cargo-release-style Rust release PR | [release-plz introduction](https://release-plz.dev/docs); [release-plz configuration](https://release-plz.dev/docs/config) | release-plz practices the pattern in its own repository and publishes a list of public users; a cargo-release release-PR action exists but is marked soft deprecated in favor of release-plz. [release-plz repository](https://github.com/release-plz/release-plz); [cargo-bins/release-pr](https://github.com/cargo-bins/release-pr) | 2026-09-05 |

### Excluded by gate

The crate-specific fitness gates are `inapplicable` to this pattern item: no candidate crate or dependency tree is being selected, so license compatibility, RustSec advisories, unsafe-code posture, crate MSRV, default features, async-runtime coupling, binary size, compile time, and crate download figures do not describe the candidates. The pattern’s platform gate is applicable only to integration: the release action runs on its GitHub Actions runner, while the generated Cargo metadata must pass locked builds on `ubuntu-latest` and `macos-latest`. [release-please-action v5.0.0 action metadata](https://github.com/googleapis/release-please-action/blob/v5.0.0/action.yml), retrieved 2026-09-05; [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05.

Excluded by the atomic-release gate are:

- A post-release-PR CI step that runs `cargo update` and pushes a second commit. It can repair the file, but fails the acceptance condition that the release PR itself contain the synchronized metadata and adds an asynchronous writer.
- A generic annotation-only updater over a hand-edited `Cargo.lock`. Cargo says the lockfile is maintained by Cargo and should not be manually edited; a generated-file annotation is less stable than release-please’s package-aware updater. [Cargo.toml vs Cargo.lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html), retrieved 2026-09-05.
- `release-type: simple` plus an `extra-files` JSONPath as the primary Rust design. It discards release-please’s native Cargo workspace and lockfile behavior and therefore has a larger correctness surface than the selected Rust strategy. [release-please supported release types](https://github.com/googleapis/release-please/blob/main/README.md#release-types-supported), retrieved 2026-09-05.

### Up-and-comers

`release-plz` is the strongest alternative: it is Rust-specific, opens a release PR, and documents updates to `Cargo.toml`, `Cargo.lock`, and `CHANGELOG.md`; its configuration distinguishes updating workspace packages from updating all dependencies. [release-plz introduction](https://release-plz.dev/docs), retrieved 2026-09-05; [release-plz configuration](https://release-plz.dev/docs/config), retrieved 2026-09-05. It is not selected because R23 explicitly settles the release-please tool choice and asks only whether Cargo.lock is one of its synchronized files.

`cargo-release` and bespoke `cargo update` workflow steps remain useful when a repository intentionally owns a Rust-specific release pipeline. They are not selected because they would replace release-please’s release-PR lifecycle rather than answer the lockfile inclusion question. The cargo-bins release-PR action’s own repository marks that action soft deprecated and recommends release-plz, which is a concrete signal not to treat that action as the preferred new path. [cargo-bins/release-pr](https://github.com/cargo-bins/release-pr), retrieved 2026-09-05.

### Fit for this template

**CLI.** The CLI is an application artifact and should commit the workspace lockfile so a release build resolves the same dependency graph. A release-please Rust update keeps the CLI package’s manifest and lock entry synchronized before the release PR is reviewable. Cargo’s guidance recommends checking in `Cargo.lock` when in doubt and explicitly emphasizes deterministic builds. [Cargo FAQ: why have Cargo.lock in version control](https://doc.rust-lang.org/cargo/faq.html#why-have-cargolock-in-version-control), retrieved 2026-09-05.

**Library.** A publishable library may not need to ship its own lockfile, but in this template the library is part of a repository shaped as CLI plus library plus web service. If the library is a member of the same workspace, the root lockfile is shared by all members and must carry the updated member record when that member’s package version changes. If the final topology instead publishes an isolated library without an application workspace, the lockfile policy must be decided with that topology; R23 does not silently override R02. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05; [Cargo FAQ](https://doc.rust-lang.org/cargo/faq.html#why-have-cargolock-in-version-control), retrieved 2026-09-05.

**Web service.** The web service is also an application artifact. Its release, test, and deployment builds benefit from the same committed lockfile and should use `--locked` in CI. The native updater avoids a later workflow mutation and makes the release PR the complete versioned input to those builds. [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05.

For a single Cargo package containing library, CLI, and web-service targets, there is one package version and one matching `Cargo.lock` package record. For a multi-crate workspace, each released member has a distinct `[[package]]` record; the root lockfile remains shared, and the `cargo-workspace` plugin is needed in release-please manifest mode when dependent members must be version-bumped. [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05; [release-please cargo-workspace documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05.

### Recommendation

Add no `Cargo.lock` entry to `release-please-config.json`’s `extra-files`. Configure the released package with the native Rust strategy:

```json
{
  "$schema": "https://raw.githubusercontent.com/googleapis/release-please/main/schemas/config.json",
  "packages": {
    ".": {
      "release-type": "rust"
    }
  }
}
```

Commit the root `Cargo.lock`, run the first lockfile generation before enabling releases, and let release-please’s `CargoLock` updater include the member-version change in the same release PR. If the final design has multiple independently versioned Cargo members, use the documented `cargo-workspace` plugin in manifest mode and verify the resulting member/version map in the release PR. [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05; [release-please cargo-workspace documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05.

This answers the decision as **yes, Cargo.lock must change in the release PR when the released package’s version changes; no, it should not be added as a JSONPath `extra-files` entry when `release-type: rust` is used**. The value test therefore expects `release-please-config.json` to gain the Rust release type but not a Cargo.lock `extra-files` object, and expects the release-PR diff to include the relevant `Cargo.lock` version line.

### Ranked runner-up

**Runner-up: release-please generic TOML `extra-files` targeting `Cargo.lock`.** It wins only if the target repository cannot use release-please’s native Rust strategy, for example because a future release-please integration deliberately selects another release type while retaining release-please’s manifest lifecycle. The fallback must have a tested JSONPath for every released member and a meta-test proving that exactly the intended `[[package]]` records changed. [release-please config schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json), retrieved 2026-09-05; [release-please generic TOML updater](https://github.com/googleapis/release-please/blob/main/src/updaters/generic-toml.ts), retrieved 2026-09-05.

It does not win for the present template because the native Rust strategy already discovers package names from Cargo manifests and updates the lockfile in the same update set. A generic expression would be a second representation of the same selection rule and would increase drift risk for a workspace. [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05.

### Tradeoffs

Compared with generic TOML JSONPath, the native Rust strategy gives up the ability to target arbitrary non-Cargo version fields through one generic configuration surface. That cost is accepted because R23 targets Cargo’s package-aware version records, and the Rust strategy already carries the required semantics. [release-please generic TOML updater](https://github.com/googleapis/release-please/blob/main/src/updaters/generic-toml.ts), retrieved 2026-09-05; [CargoLock updater](https://github.com/googleapis/release-please/blob/main/src/updaters/rust/cargo-lock.ts), retrieved 2026-09-05.

Compared with a post-PR `cargo update` step, the native updater gives up Cargo’s full dependency-resolution operation during the release-please update itself. That cost is accepted because changing only the workspace member version is narrower and deterministic, while CI can run `cargo build --locked` to prove the resulting graph is valid. A later dependency refresh remains a separate maintenance action, not part of version synchronization. [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html), retrieved 2026-09-05; [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05.

Compared with release-plz or cargo-release, the chosen design gives up Rust-specific release features such as API-break detection or registry-aware release decisions. That cost is accepted because the repository has already selected release-please for its release PR, changelog, tag, and authentication flow; changing those decisions would exceed R23. [release-plz introduction](https://release-plz.dev/docs), retrieved 2026-09-05; [release-please manifest guide](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md), retrieved 2026-09-05.

### Parameters

`owns —` R23 owns no registered parameter.

`assumes rust-edition = 2024`.

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

`assumes license = MIT OR Apache-2.0`.

`assumes target-os-matrix = ubuntu-latest, macos-latest`.

No `CONFLICT:` line is emitted. The recommendation does not require changing a consumed parameter. [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.

### Migration implications

- `release-please-config.json`: set the package’s release type to `rust`; do not add a `Cargo.lock` object to `extra-files`.
- `Cargo.lock`: generate and commit the root lockfile. The target is an application-shaped template, and Cargo documents committed lockfiles as the deterministic-build choice for applications. [Cargo FAQ](https://doc.rust-lang.org/cargo/faq.html#why-have-cargolock-in-version-control), retrieved 2026-09-05.
- `.release-please-manifest.json`: keep the existing release-please package-version record; it remains a release manager state file and is not replaced by Cargo.lock. [release-please manifest guide](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md), retrieved 2026-09-05.
- The version-consistency meta-test from F133: parse each released member manifest and the root lockfile, assert equal versions, assert that the release configuration selects the native Rust strategy, and retain a meaningful accessor/package-identity check. Do not claim that compile-time `CARGO_PKG_VERSION` is an independently maintained copy of the manifest version. [baseline review F133](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/BASELINE-REVIEW.md), retrieved 2026-09-05.
- If R02 selects multiple independently versioned workspace members, add the `cargo-workspace` plugin and test the release PR’s complete member/version map. Do not assume all members should share one version merely because they share a lockfile. [release-please cargo-workspace documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05.

### Validation strategy

The following empirical check was executed in a temporary two-level Cargo workspace with a binary member named `demo-app`, edition `2024`, and no external dependencies. The commands exercised Cargo’s documented lockfile behavior. [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html), retrieved 2026-09-05; [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html), retrieved 2026-09-05.

```text
cargo generate-lockfile
# Cargo.lock contained demo-app version = "0.1.0".

# Cargo.toml was changed to version = "0.2.0".
cargo build --locked
# status 101: Cargo refused to update Cargo.lock because --locked was passed.

cargo update -p demo-app --precise 0.2.0
# status 0; Cargo.lock changed demo-app from 0.1.0 to 0.2.0.

cargo build --locked
# status 0; compiled demo-app v0.2.0.

# Cargo.lock was deliberately changed back to 0.1.0 while Cargo.toml stayed at 0.2.0.
cargo build --offline
# status 0; Cargo rewrote Cargo.lock to demo-app version 0.2.0.
```

This executed check proves both sides of the contract: an immutable release/CI build rejects a stale lockfile, while an ordinary Cargo update/build repairs it. It does not prove the GitHub release-please action’s end-to-end PR behavior because no authenticated GitHub release-PR run was executed. The release-please source and v5.0.0 bundled implementation were inspected instead; their Rust strategy schedules `CargoLock`, and the Rust strategy tests assert the update exists for single-crate and workspace fixtures. [release-please-action v5.0.0 bundled implementation](https://github.com/googleapis/release-please-action/blob/v5.0.0/dist/index.js), retrieved 2026-09-05; [Rust strategy tests](https://github.com/googleapis/release-please/blob/main/test/strategies/rust.ts), retrieved 2026-09-05.

Planned repository acceptance checks are:

```sh
cargo metadata --locked --format-version 1
cargo build --locked --workspace
cargo test --locked --workspace
```

The R23-specific meta-test should read the actual workspace package names and versions, then match each name/version pair against the root `Cargo.lock` and assert the release configuration contains `release-type: rust` without a duplicate Cargo.lock `extra-files` entry. For a multi-crate manifest-mode release, the check should also inspect the `cargo-workspace` plugin configuration and the release PR diff. These are planned checks, not executed in this research run. [Cargo metadata](https://doc.rust-lang.org/cargo/commands/cargo-metadata.html), retrieved 2026-09-05; [release-please manifest guide](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md), retrieved 2026-09-05.

### Confidence & re-verify trigger

Confidence is high for the single-package or shared-version workspace case because Cargo’s lockfile behavior was reproduced locally and the release-please Rust source directly schedules a package-aware lockfile updater. Confidence is medium for independently versioned multi-crate workspaces because release-please’s documented plugin is the correct architecture, but the final R02 topology and the exact member-release policy are not settled here. [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts), retrieved 2026-09-05; [cargo-workspace documentation](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace), retrieved 2026-09-05.

Re-verify before implementation if any of these change: the release-please action major version or bundled release-please dependency; the Rust strategy stops scheduling `CargoLock`; R02 chooses independently versioned members; Cargo changes the lockfile package representation; or the open release-please workspace issue changes the behavior of root Rust releases. [release-please-action v5.0.0 package](https://github.com/googleapis/release-please-action/blob/v5.0.0/package.json), retrieved 2026-09-05; [release-please workspace issue #2748](https://github.com/googleapis/release-please/issues/2748), retrieved 2026-09-05; [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html), retrieved 2026-09-05.

### Sources

Method notes: queried the Rust project documentation pages for Cargo.toml/Cargo.lock semantics, Cargo workspaces, Cargo build, Cargo update, Cargo metadata, the Cargo FAQ, and Cargo environment variables; queried the release-please schema, manifest guide, customizing guide, Rust strategy, `CargoLock` updater, generic TOML updater, Rust strategy tests, and release-please-action v5.0.0 `action.yml`, `package.json`, and bundled `dist/index.js`; queried the pinned py and ts source revisions for their release configuration and no-sync precedent; queried release-plz documentation and repository pages; and inspected root `Cargo.lock` files in Rust, Cargo, ripgrep, and rustls. The release-please GitHub API code-search endpoint was rate-limited, so no GitHub API search figures were used. No crates.io, RustSec, download, or issue-response figures were collected because R23 is a pattern item and those crate metrics are `inapplicable`. No authenticated release-please PR was run; the end-to-end action result remains unverified. All web sources were retrieved on 2026-09-05.

Source index: [Cargo.toml vs Cargo.lock](https://doc.rust-lang.org/cargo/guide/cargo-toml-vs-cargo-lock.html); [Cargo workspaces](https://doc.rust-lang.org/cargo/reference/workspaces.html); [Cargo build](https://doc.rust-lang.org/cargo/commands/cargo-build.html); [Cargo update](https://doc.rust-lang.org/cargo/commands/cargo-update.html); [release-please schema](https://github.com/googleapis/release-please/blob/main/schemas/config.json); [release-please Rust strategy](https://github.com/googleapis/release-please/blob/main/src/strategies/rust.ts); [CargoLock updater](https://github.com/googleapis/release-please/blob/main/src/updaters/rust/cargo-lock.ts); [generic TOML updater](https://github.com/googleapis/release-please/blob/main/src/updaters/generic-toml.ts); [cargo-workspace guide](https://github.com/googleapis/release-please/blob/main/docs/manifest-releaser.md#cargo-workspace); [release-please-action v5.0.0](https://github.com/googleapis/release-please-action/tree/v5.0.0); [py precedent](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccf/release-please-config.json); [ts precedent](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb/.github/workflows/release-please.yml); [release-plz](https://release-plz.dev/docs); [release-please issue #2748](https://github.com/googleapis/release-please/issues/2748).
