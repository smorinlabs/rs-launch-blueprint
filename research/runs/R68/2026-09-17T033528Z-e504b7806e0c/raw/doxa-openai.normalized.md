## Reasoning Summary
**Planning extensive research**

I need to tackle a huge research prompt, so I'll start with an immediate web call before using any other tools. I might need to inspect specific local documents, but I think the user’s references may not be publicly accessible. I’ll need to document any evidence from owner-provided content in the prompt, ensuring to note retrieval dates and URLs. It seems leveraging public benchmark results might help, but ultimately, I need to be transparent about any gaps in evidence.
**Gathering API information**

I need to gather as much information as possible, considering that I might access web URLs and GitHub API endpoints. I’ll collect figures from relevant APIs, such as crates.io and GitHub. I should identify suitable candidates for artifact distribution alternatives like Cargo’s built-in methods or cargo-dist, which may have been renamed to "dist" by Axo. I’ll verify this as of September 17, 2026, and check for updated information with an immediate web search.

### Landscape

**Research cutoff:** September 17, 2026. All web sources below were retrieved on that date. Repository-local owner files were not independently accessible; I treated the excerpts supplied in the prompt as binding inputs.

**Evidence limitation:** this research interface did not provide a Rust build runner. Consequently, the owner-required Ubuntu/macOS profile benchmark was **not executed**, and the required crates.io/GitHub JSON metric census was not successfully captured. I report those fields as evidence gaps rather than inventing figures. The artifact recommendation is actionable; the profile recommendation is conditional on the benchmark in `### Validation strategy`.

#### Category map

| Bin | Candidates found | Assessment |
|---|---|---|
| **Built-in or first-party toolchain** | `cargo publish`/crates.io, `cargo install --locked`, Cargo release profiles, `rustup target add`, GitHub Releases/Actions | Canonical source distribution and lowest-complexity baseline. Cargo installs binaries using the release profile but compiles them on the consumer’s machine. Cargo profiles are workspace-root policy and are ignored when this crate is a downstream dependency. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai)) |
| **Established industry standard** | **`dist`**, distributed as `cargo-dist`; `cargo-binstall`; composable GitHub release actions backed by `cross` or `cargo-zigbuild` | `dist` is the only surveyed maintained tool that combines target planning, builds, archives, checksums, installers, a machine-readable manifest, generated CI, and GitHub Release hosting. `cargo-binstall` is the established consumer-side binary installer, not an artifact producer. ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai)) |
| **Up-and-comer / modular alternatives** | Release orchestration plus `upload-rust-binary-action`; release-plz binary-release recipes; generic/non-Rust release tooling | These favor composability and integrate naturally into an existing release workflow, but require the template to own more target, archive, checksum, installer, and upload policy itself. Release-plz’s own documentation delegates binary building to either an upload action or cargo-dist. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai)) |

#### Authority

- **Cargo Book:** normative for profile defaults, permitted values, profile selection, custom-profile inheritance, override precedence, and the rule that dependency manifests’ profile settings are ignored. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))
- **GitHub documentation:** normative for workflow triggering. Events caused by the repository `GITHUB_TOKEN` do not normally start another workflow; `workflow_dispatch` and `repository_dispatch` are exceptions. This matters directly to release-please → dist wiring. ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai))
- **Maintainer documentation:** authoritative for `dist`, `cargo-binstall`, and release-please behavior and configuration. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))
- **Maintained reference implementations:** `dist` self-hosts its release process; `cargo-binstall` publishes and installs its own target-specific binaries; release-plz explicitly documents cargo-dist and upload actions as the binary-release layer. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai))

#### Practice evidence

`dist` released version **0.33.0 on September 10, 2026**, has current documentation, is packaged by Homebrew, and self-hosts its generated workflow. That is strong maintenance and implementation evidence, though not evidence of formal Rust-project endorsement. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

The retrieved evidence did **not** provide file-level, independent adopter verification for ten mainstream Rust projects. Therefore, adoption is not used as the deciding signal. The recommendation rests on capability coverage, current maintenance, ecosystem conventions, and fit—not stars or familiarity.

### Principles and implementation

#### Shared requirement and agreement level

The shared engineering principle is:

> **Publish one canonical source package for Rust consumers, while making the user-facing CLI available without requiring a local Rust toolchain or a full dependency compile. Keep all artifacts tied to one version/tag, use standard Rust target triples, preserve a source-build fallback, and make the release profile an explicit workspace-root policy.**

Agreement is required at four levels:

1. **Capability:** crates.io source distribution plus supported native CLI artifacts.
2. **Policy:** one release version, a declared target set, integrity metadata, and documented fallback behavior.
3. **Architectural pattern:** release/version orchestration and artifact production have one clearly defined interface and exactly one owner for GitHub Release creation.
4. **Profile policy:** local release and distributed binaries use equivalent optimization, panic, and symbol policies; downstream library users inherit none of them.

The exact workflow generator may change after a fork, but these observable behaviors should not.

#### Architectural alternatives

**1. Crates.io only**

This is the Cargo-native baseline: publish the `.crate`, document `cargo install --locked`, and let every user compile. It is simple and supports every target on which the dependency graph compiles. Its cost is user time, installation of a Rust toolchain, local native dependencies, and repeated compilation in developer workstations and CI environments. `cargo install` selects Cargo’s release profile by default. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

**2. Integrated release application: `dist`**

`dist` discovers Cargo targets, plans target builds, creates archives and installers, generates `dist-manifest.json`, and emits a GitHub Actions release pipeline. It supports x86-64 and ARM64 Linux and macOS targets, among others. Its shell installer detects the host platform and downloads the corresponding archive. ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai))

This best realizes the template’s “batteries included, but replaceable” purpose: a fork starts with a complete binary-release path rather than a README telling maintainers to design one later.

**3. Composable GitHub Actions**

An upload action plus `cross` or `cargo-zigbuild` can build and upload target binaries directly into a release-please-created GitHub Release. This avoids a generated multi-phase workflow and may integrate more directly with release-please, but the template must define archive layouts, checksums, manifests, installer scripts, target fallback, and cargo-binstall compatibility itself. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))

That is appropriate for a project with bespoke release engineering, but not the best default for a reusable launch template.

#### Release-please boundary

`dist` and release-please both know how to create GitHub Releases. They must not both use their defaults.

The recommended ownership is:

- **release-please:** version bump, changelog, tag, and initial GitHub Release;
- **dist:** target builds, archives, checksums, installer, manifest, and asset upload, configured with `create-release = false`.

The integration must not assume that a tag created with the default `GITHUB_TOKEN` starts the generated dist workflow. GitHub explicitly suppresses most such recursive events. Use the credential mechanism already owned by the release-please decision—preferably a narrowly scoped GitHub App token—or an explicit dispatch/call path. `dist` documents `workflow_dispatch` support, but its generated mode and `create-release=false` behavior must be tested against the exact release-please flow before acceptance. ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai))

#### cargo-binstall

`cargo-binstall` already searches crates.io metadata and the crate’s repository for matching release assets, and its maintainers advise trying automatic discovery before adding metadata. Explicit `[package.metadata.binstall]` remains preferable in a template because it converts a heuristic into a checked contract. It does not require another artifact-hosting service: it points at the same GitHub Release archives. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

Do **not** disable its compile fallback. Supported targets receive binaries; unsupported targets can still fall through to `cargo install`.

#### Target policy

Ship four native targets:

- `x86_64-unknown-linux-gnu`
- `aarch64-unknown-linux-gnu`
- `x86_64-apple-darwin`
- `aarch64-apple-darwin`

This preserves the fixed Linux/macOS OS boundary while covering both major architectures. The artifact matrix need not equal the contributor runner architecture: Apple Silicon Macs and ARM64 Linux servers are end-user platforms even when contributors use x86-64 runners. All four are explicitly supported by `dist`. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

Do not ship Windows, MSI, PowerShell, musl, Homebrew, or npm artifacts by default. Windows is outside the fixed matrix; musl introduces another libc compatibility dimension and two additional builds without an inherited acceptance test.

#### Profile architecture

Cargo reads profiles only from the workspace root; downstream library consumers ignore profiles from the published crate. A selected profile applies to library and binary targets in the current build. Custom profiles require `inherits` and use a separate target subdirectory. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

The implementation should place the actual policy in `[profile.release]` and declare a settings-free `[profile.dist]` adapter that inherits it. Current `dist` guidance expects that custom profile and generally refuses to run without it. This creates a separate Cargo cache/output directory, but avoids semantic divergence because it contains no overrides. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai))

#### Observable acceptance criteria

1. One version/tag produces one crates.io `.crate` and one GitHub Release.
2. The GitHub Release contains exactly four native archives, their checksums, one Unix shell installer, and `dist-manifest.json`.
3. No Windows, musl, npm, Homebrew, MSI, or redundant dist-generated source tarball is present.
4. `cargo binstall rs-launch-blueprint` downloads a project-owned binary on all four targets.
5. Unsupported cargo-binstall targets retain source-compile fallback.
6. `cargo install --locked rs-launch-blueprint` remains documented and functional.
7. A library consumer receives no profile settings from this crate.
8. `cargo build --release` and `cargo build --profile dist` have equivalent effective profile values.
9. release-please and dist do not create duplicate tags/releases.
10. The required Ubuntu/macOS benchmark is attached before the profile block is accepted.

**BASELINE-REVIEW: F220 — installation documentation must reflect the selected channels rather than copy Python or npm precedent — proposed change: document `cargo binstall`/release binaries as the preferred CLI path and `cargo install --locked` as the portable source fallback, while library consumers use the crates.io dependency — evidence: Cargo’s install profile and cargo-binstall’s repository-artifact discovery model.** ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

### Dominant choice

**`dist`—the current command name for the package still distributed as `cargo-dist`—version range `>=0.33.0,<0.34.0`, with an exact checked-in pin of `0.33.0`.**

`dist` is the dominant **integrated** choice in this survey, not an official Rust standard. It is the only current candidate found that covers target planning, cross-target builds, archives, hashes, installer generation, machine-readable release metadata, CI generation, and GitHub Release upload as one maintained system. Version 0.33.0 was released on September 10, 2026. Its configuration requires an exact version rather than a version requirement, hence the exact pin inside the broader implementation-policy range. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

Use it in combination with:

- the unavoidable crates.io `.crate`;
- explicit cargo-binstall metadata targeting the GitHub Release archives;
- a shell installer for Linux/macOS;
- both source and prebuilt installation commands in the README.

The principal qualification is release-please integration: it is clean at the architectural boundary, but not zero-configuration because of GitHub event-suppression and duplicate-release ownership.

### Qualified shortlist

The required crates.io and GitHub API metric values were not captured. No download, star, open-issue, or issue-response numbers are asserted.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance state | Notable adopters/reference use | One-line trade-off |
|---|---|---:|---:|---:|---|---|---|---|
| **`dist`/`cargo-dist` `>=0.33,<0.34` + cargo-binstall metadata** | Integrated binary build, package, installer, manifest, and upload bundle | **Evidence gap:** required crates.io endpoint not captured | **Evidence gap** | **Evidence gap:** required GitHub API not captured | Tool release 0.33.0, September 10, 2026; crates.io version endpoint not captured | **active**, provisional because ten-issue response census is missing | Self-hosting `dist`; cargo-binstall-compatible distribution model; referenced by release-plz’s binary-release guide | Most complete behavior, but generated CI, profile adapter, and release-please ownership require validation. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai)) |
| **Cargo/crates.io only** | Built-in source package and source-compiled CLI | Inapplicable: architectural pattern | Inapplicable | Inapplicable | Follows Rust/Cargo releases | **active / first-party** | Universal Cargo baseline | Lowest maintenance; transfers build time and toolchain/native-dependency burden to every installer. ([doc.crates.io](https://doc.crates.io/?utm_source=openai)) |

Fewer than five qualified choices is a finding: `cargo-binstall` and release-plz are complementary consumers/orchestrators, while upload actions leave too many required behaviors to template-owned glue.

### Excluded by gate

#### Fitness-gate record for the dominant bundle

| Gate | Result |
|---|---|
| **1. Licence compatibility** | **Inapplicable**, per owner ruling Q7.B dated September 12, 2026 in `docs/port/OWNER-REVIEW.md`, section *“2026-09-12 — no licence check for anything the template uses (Q4, superseded and widened by Q7.B)”*. The row is retained as required. |
| **2. MSRV/dependency-tree MSRV** | **Pass for the selected deployment mode, with re-verification required.** `dist` and cargo-binstall are release/user tools installed as prebuilt executables and do not enter the template crate’s dependency graph. The retrieved cargo-dist manifest declared an older Rust floor than the template policy, but the exact 0.33 dependency-tree MSRV was not captured. Do not make source-building cargo-dist part of release CI. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)) |
| **3. RustSec and unsafe posture** | **Provisional pass.** No open advisory was found in the retrieved search results, but the direct RustSec package pages were not captured and must be queried before merge. The tools run out of process; no tool-internal `unsafe` is linked into `rs-launch-blueprint`. Internal unsafe counts were not audited. |
| **4. Ubuntu/macOS support** | **Pass.** Both target families and both x86-64/ARM64 architectures are supported in current dist configuration. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai)) |
| **5. Features/runtime coupling** | **Pass.** Cargo-dist and cargo-binstall have their own async/network stacks, but they are external executables and introduce no Tokio, TLS, or default-feature coupling into the template’s library or binary. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)) |
| **6. Size and compile-time cost** | **Pass with known cost.** No runtime dependency is added. Release CI performs four binary builds plus packaging jobs; the actual wall-time and profile cost remain unmeasured. |

#### Exclusions

- **`cargo-binstall` alone:** excluded by capability gate—it installs existing artifacts but does not build or publish them. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))
- **release-plz alone:** excluded by capability gate—its own binary-release documentation directs users to cargo-dist or an upload action. ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))
- **A bare upload action:** excluded by essential-behavior gate—it can compile/upload binaries but does not, by itself, define the installer, manifest, checksum, target-fallback, and archive-layout policy required here. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))
- **Hand-written `cross`/`cargo-zigbuild` matrix:** excluded by template-fit gate. It can realize the capability, but makes every fork own more bespoke workflow logic than the integrated choice.
- **Windows/MSI/PowerShell targets:** excluded by fixed `target-os-matrix`.
- **Linux musl targets:** excluded from the default matrix because they add a libc support dimension and release builds without a corresponding fixed CI or smoke-test requirement.
- **GoReleaser Rust support and newer installer-only tools:** excluded because this run did not capture sufficient current primary-source maturity, MSRV, advisory, and adopter evidence.

### Up-and-comers

1. **Composable release-please + upload action architecture.** This is the strongest challenger when an organization prefers one hand-maintained release workflow over generated CI. It can build with Cargo, `cross`, or cargo-zigbuild and attach directly to an existing GitHub Release. ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))
2. **release-plz binary recipes.** Release-plz is strengthening Rust-native release orchestration but still delegates binary production. It is therefore a possible replacement for release-please, not yet a replacement for dist in this decision. ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))
3. **`dist` Config 1.0/generalized project support.** Current documentation says its configuration is migrating from Cargo metadata to `dist-workspace.toml`/`dist.toml`, and its scope is expanding beyond Rust. That evolution is promising but is also a re-verification trigger for the 0.34 line. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

### Fit for this template

#### CLI

This is where prebuilt artifacts pay off most. A template consumer can install and exercise the generated CLI without waiting for the Axum/Tokio/Clap dependency graph to compile or installing a Rust toolchain. `cargo binstall` provides the Cargo-shaped command; the shell installer and direct archives cover users without cargo-binstall. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))

#### Library

The crates.io `.crate` remains the only meaningful library artifact. GitHub binaries neither replace nor duplicate it. Cargo ignores profile definitions in dependency manifests, so downstream applications choose their own optimization, panic, and symbol policies. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

#### Web service

The released CLI binary may expose the R49-defined web-service command or mode, making prebuilt binaries useful for local demonstrations and direct self-hosting. The recommendation retains unwinding and symbols rather than minimizing size at any cost. Container publication remains entirely with R51.

### Recommendation

#### Artifact and channel decision

| Subject | Decision |
|---|---|
| **Release tool** | `dist` / package `cargo-dist`, policy range `>=0.33.0,<0.34.0`, exact checked-in version `0.33.0`. |
| **Source artifact** | Publish the normal crates.io `.crate`. |
| **Native artifacts** | Four GitHub Release archives: x86-64 and ARM64 for GNU/Linux and macOS. |
| **Supporting artifacts** | Checksums, `dist-manifest.json`, and one Unix shell installer. |
| **cargo-binstall** | Explicit metadata pointing to the same release archives; compatibility acceptance target `cargo-binstall >=1.23.0,<2`. No separate binstall artifact or service. |
| **Not shipped** | Windows, musl, npm, Homebrew, MSI, PowerShell installer, separate dist-generated source tarball, or container image. |
| **README** | Preferred CLI: `cargo binstall rs-launch-blueprint`; source fallback: `cargo install --locked rs-launch-blueprint`; direct archive/shell installer documented; library use documented separately. |
| **Release ownership** | release-please owns version/tag/GitHub Release; dist attaches assets with `create-release = false`. Triggering must use a GitHub App/PAT-backed event or explicit dispatch—not an assumed recursive `GITHUB_TOKEN` event. |

Recommended `dist-workspace.toml`:

```toml
[dist]
cargo-dist-version = "0.33.0"
ci = ["github"]

targets = [
  "x86_64-unknown-linux-gnu",
  "aarch64-unknown-linux-gnu",
  "x86_64-apple-darwin",
  "aarch64-apple-darwin",
]

installers = ["shell"]
source-tarball = false
create-release = false
pr-run-mode = "plan"
```

These are current documented configuration surfaces. The exact tool version is mandatory rather than a Cargo-style requirement. ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

Recommended Cargo metadata, assuming the existing release tag is `v{version}` and dist 0.33’s versionless Unix archive naming:

```toml
[package.metadata.binstall]
pkg-url = "{ repo }/releases/download/v{ version }/{ name }-{ target }.tar.xz"
bin-dir = "{ bin }{ binary-ext }"
pkg-fmt = "txz"
```

Do not set `disabled-strategies`; cargo-binstall must retain its normal fallback behavior. The exact `pkg-url` and `bin-dir` must be proven against an actual prerelease asset because cargo-binstall explicitly permits metadata overrides when automatic discovery or archive layout differs. ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

#### Release build profile

**Provisional implementation target:**

```toml
[profile.release]
lto = "thin"
codegen-units = 1
strip = "none"
panic = "unwind"

# Adapter required by current dist; no policy divergence.
[profile.dist]
inherits = "release"
```

| Key | Cargo release default | Decision | Manifest treatment | Basis |
|---|---|---|---|---|
| `lto` | `false` | `"thin"` | **Write** | Matches the owner reference architecture and dist’s maintained release-profile pattern. Intended to improve whole-program optimization with less cost than fat LTO. Must pass the project benchmark. |
| `codegen-units` | `16` for non-incremental release builds | `1` | **Write** | Matches the owner reference architecture and prioritizes shipped artifact quality over release-build parallelism. This is the setting most likely to be removed if the benchmark shows poor return. |
| `opt-level` | `3` | `3` | **Leave silent** | No evidence that `"s"` or `"z"` improves this application’s final archive enough to offset possible runtime regressions. Silence records “standard release optimization,” not a size-at-all-costs policy. |
| `strip` | `"none"` | `"none"` | **Write explicitly** | Deliberate support policy: retain linker-emitted symbols in end-user binaries. This does not promise file/line information because `debug` remains off. |
| `panic` | `"unwind"` | `"unwind"` | **Write explicitly** | Avoids changing panic semantics for the CLI/web-service build and preserves the possibility of panic hooks, unwinding, and task-level handling. |
| `debug` | `false`/`"none"` | default | **Leave silent** | R67 creates no stack-trace requirement and F301 remains open. Shipping line tables now would assert a diagnostic contract not yet owned. Revisit if F301 requires source locations or symbol bundles. |
| Custom profile | none | `[profile.dist] inherits = "release"` | **Write, with no overrides** | Current dist expects the profile. Keeping all settings in `release` gives local and CI builds the same policy, while acknowledging that Cargo still uses a separate output/cache directory. |

Cargo documents all defaults above, the permitted values, custom-profile inheritance, and workspace-root precedence. Configuration/environment overrides take precedence over `Cargo.toml`. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))

**Reference architecture record:** provisionally **agree** with `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`, section *Reference Cargo.toml*, on `lto = "thin"` and `codegen-units = 1`. This recommendation adds explicit `strip = "none"` and `panic = "unwind"`, leaves `opt-level` and `debug` at Cargo defaults, and places a settings-free `dist` adapter beside `release`.

#### Required measurement status

The mandatory profile experiment was **not executed**. Therefore:

- no binary-size figure is claimed;
- no clean or post-edit build-time figure is claimed;
- no Ubuntu/macOS comparison is claimed;
- no setting is described as empirically faster or smaller;
- the profile portion of this recommendation is **not acceptance-ready under W0-R69p** until the planned run succeeds.

The measured table that must replace this gap is:

| Variant | Ubuntu size, unstripped/stripped | Ubuntu clean/post-edit wall time | macOS size, unstripped/stripped | macOS clean/post-edit wall time |
|---|---:|---:|---:|---:|
| Cargo release defaults | Not run | Not run | Not run | Not run |
| `lto="thin"` only | Not run | Not run | Not run | Not run |
| `codegen-units=1` only | Not run | Not run | Not run | Not run |
| `lto="thin"` + `codegen-units=1` | Not run | Not run | Not run | Not run |
| Final profile above | Not run | Not run | Not run | Not run |
| `opt-level="z"` challenger | Not run | Not run | Not run | Not run |
| `strip="symbols"` challenger | Not run | Not run | Not run | Not run |
| `panic="abort"` challenger | Not run | Not run | Not run | Not run |
| `debug="line-tables-only"` challenger | Not run | Not run | Not run | Not run |

### Ranked runner-up

**Crates.io-only distribution with Cargo’s standard release profile.**

It wins if any of these conditions holds:

- the existing release-please flow cannot provide one safe release owner without a new App/PAT or bespoke dispatch;
- organizational policy rejects cargo-dist’s generated bootstrap or generated workflow;
- the four-target release adds unacceptable CI cost;
- cargo-binstall metadata cannot be proven against the generated archive layout;
- the profile benchmark shows that thin LTO/codegen-units tuning does not justify its build-time cost;
- the template is intentionally repositioned as a library-first starter rather than a runnable CLI product.

### Tradeoffs

| Compared with | What the recommendation gains | What it gives up | Why accepted |
|---|---|---|---|
| **Crates.io only** | Fast end-user installs, no required Rust toolchain, architecture-native CLI, conventional GitHub assets | Four release builds, more workflow permissions and failure modes | A launch template benefits from demonstrating a production-ready binary-release path rather than deferring all release engineering to every fork. |
| **Composable upload action** | Installer, checksums, manifest, target planning, archive conventions, generated PR validation | Less transparent generated YAML and more release-owner coordination | The integrated behaviors are exactly what otherwise becomes bespoke template code. |
| **Wider matrix including musl** | Lower CI cost and smaller support surface | No Alpine/static Linux default and fewer fallback binaries | GNU/Linux plus source fallback covers the fixed matrix without silently promising another libc compatibility contract. |
| **Stripped/abort binaries** | Better post-release diagnostic potential and unchanged panic semantics | Larger binaries than aggressively stripped/abort builds | End users cannot rebuild the exact shipped binary; supportability is more important than minimum byte count absent measurements. |
| **Independent `[profile.dist]` tuning** | Local `--release` and CI have the same effective settings | Separate Cargo cache/output directory remains because of the profile name | Semantic divergence is avoided, and dist’s current integration requirement is satisfied. |
| **Cargo defaults only** | Potentially smaller/faster runtime from thin LTO and one codegen unit | Longer clean release builds | Release builds are infrequent and parallelized by target, but this cost must still be measured before acceptance. |

### Parameters

`owns release-binary-artifacts = crates.io .crate + four GitHub Release target archives + checksums + dist-manifest.json + Unix shell installer`

`owns release-tool = dist/cargo-dist >=0.33.0,<0.34.0; checked-in exact pin 0.33.0`

`owns cargo-binstall-support = explicit package metadata targeting project-owned GitHub Release archives; compatibility baseline >=1.23.0,<2`

`owns documented-install-method = cargo binstall and direct release binary as preferred CLI paths; cargo install --locked as source fallback; crates.io dependency for library consumers`

`owns cargo-release-build-profile = [profile.release] lto="thin", codegen-units=1, strip="none", panic="unwind"; opt-level/debug left at Cargo defaults; [profile.dist] inherits="release" with no overrides`

`assumes build-tool-output-shape = R49-defined [lib], [[bin]], package include allow-list, and target names; no target declaration is changed`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version and tested in CI`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

`assumes license = MIT OR Apache-2.0`

`CONFLICT: none`

### Migration implications

1. **`Cargo.toml`**
   - Add `[package.metadata.binstall]`.
   - Add the recommended `[profile.release]`.
   - Add the settings-free `[profile.dist]`.
   - Do not alter R49-owned `[lib]`, `[[bin]]`, package `include`, entry points, or target names.

2. **`dist-workspace.toml`**
   - Add the exact 0.33.0 tool pin.
   - Declare the four targets.
   - Enable only the shell installer.
   - Disable the redundant dist source tarball.
   - Set `create-release = false`.
   - Keep PR validation at `plan`.

3. **`.github/workflows/release.yml`**
   - Generate with `dist generate`.
   - Review and commit the generated file.
   - Ensure its trigger works with the existing release-please credential/event path.
   - Ensure it uploads to the release-please-created release rather than creating another.
   - Pin third-party actions to the repository’s established security policy; dist supports explicit action-commit pins. ([github.com](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai))

4. **Existing release-please workflow/config**
   - Expose the release tag to dist.
   - Use a GitHub App/PAT-backed tag event or an explicit dispatch path.
   - If dist’s `create-release=false` implementation requires a draft release, ensure release-please produces one or use a same-workflow upload integration.
   - Do not depend on a recursive event from the default `GITHUB_TOKEN`. ([docs.github.com](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai))

5. **`README.md`**
   - Add separate **Library**, **Prebuilt CLI**, **Source-built CLI**, and **Direct download** installation sections.
   - Make cargo-binstall the first CLI command on supported platforms.
   - State the four supported binary targets and source fallback for everything else.
   - Do not imply Windows, musl, or container availability.

6. **Release-maintenance documentation**
   - Explain that `cargo-dist-version` is an exact reproducibility pin.
   - Require `dist generate` and review when upgrading within `0.33.x`.
   - Require fresh research before `0.34.x` because configuration and generated workflow behavior may change.

7. **R50 hand-off**
   - R50 should smoke-test the shell installer, cargo-binstall path, direct archive, and `cargo install --locked`; R68 decides only what exists.

8. **R51 hand-off**
   - No container workflow or image reference is added here.

### Validation strategy

#### Executed in this research

- Current Cargo profile documentation was inspected.
- Current dist configuration, release, generated-workflow, and custom-profile documentation was inspected.
- Current cargo-binstall discovery and metadata documentation was inspected.
- GitHub’s recursive-workflow trigger rules were inspected.
- **No Rust builds, uploads, installs, profile benchmarks, API metric census, or release dry runs were executed.**

#### Planned artifact checks

```bash
dist --version
# Expected: dist/cargo-dist 0.33.0

dist generate
git diff --exit-code
# Expected: generated workflow is committed and reproducible.

dist plan --tag=v0.1.0
# Expected: exactly four target archives, checksums, one shell installer,
# and dist-manifest.json; no Windows, musl, npm, Homebrew, MSI, or source.tar.gz.

dist build --tag=v0.1.0
# Expected locally where supported: target/distrib contains the planned artifacts.
```

Create a prerelease and then verify:

```bash
gh release view v0.1.0
gh release download v0.1.0 --dir target/release-assets
```

Expected behavior:

- only one release exists for the tag;
- every planned artifact is attached;
- a failed target job prevents final announcement;
- archive checksums verify;
- the shell installer selects the appropriate one of the four targets.

#### Planned cargo-binstall checks

For each supported target, using cargo-binstall 1.23.x:

```bash
cargo binstall \
  --manifest-path Cargo.toml \
  --version 0.1.0 \
  --target x86_64-unknown-linux-gnu \
  --no-confirm \
  rs-launch-blueprint
```

Repeat for all four triples. Expected result: the log identifies the project’s GitHub Release as the binary source; no local Rust compilation occurs.

For an unsupported target, verify that cargo-binstall attempts its normal fallback rather than failing because strategies were disabled.

Source fallback:

```bash
cargo install --locked --version 0.1.0 rs-launch-blueprint
rs-launch-blueprint --version
```

#### Planned profile benchmark

Until the actual template source exists, use a declared stand-in:

- one edition-2024 package;
- one library plus one binary;
- CLI subcommands for `version` and `serve`;
- Axum/Tokio HTTP service;
- direct dependencies representing the likely composition: Axum, Tokio, Clap, Serde, serde_json, tracing, tracing-subscriber, and tower-http;
- exact versions and resolved dependency count taken from the committed lockfile at benchmark time.

This stand-in is unlike the eventual template because it lacks its final domain logic, optional features, native dependencies, generated code, and exact R49 target implementation. Its measurements may select obviously poor settings but must be rerun on the real source before P03 release.

On both `ubuntu-latest` and `macos-latest`, record:

```bash
rustc -Vv
cargo -Vv
uname -a

# Linux:
lscpu

# macOS:
sysctl -a | grep -E 'machdep.cpu|hw.model|hw.ncpu'
```

For every variant:

1. Set a unique `CARGO_TARGET_DIR`.
2. Delete it before the clean build.
3. Time `cargo build --locked --release`.
4. Record binary size with a portable Python `os.path.getsize`.
5. Copy and strip the binary with the host’s `strip`; record its version and resulting size.
6. Rebuild once to warm dependencies.
7. Touch one application source file without changing behavior.
8. Time the post-edit rebuild.
9. Repeat enough times to report median wall time, retaining raw logs.

At minimum test:

```text
Cargo defaults
lto=thin
codegen-units=1
lto=thin + codegen-units=1
opt-level=z
strip=symbols
panic=abort
debug=line-tables-only
final proposed profile
```

Proposed acceptance rules—not measurements:

- Keep `lto="thin"` only if it reduces the unstripped or stripped binary on **both** OSes without an operationally unacceptable clean-build increase.
- Keep `codegen-units=1` only if it produces an additional material size or runtime benefit over thin LTO alone.
- Do not adopt `opt-level="z"` solely because one host produces a smaller file; run the CLI and HTTP workload as well.
- Keep `strip="none"` and `panic="unwind"` unless a later owner decision explicitly accepts weaker diagnostics/changed panic semantics.
- Revisit `debug` when F301 defines the stack-trace contract.

#### Profile equivalence and downstream isolation

```bash
cargo clean
cargo build --release -vv 2> release.flags.log

cargo clean
cargo build --profile dist -vv 2> dist.flags.log
```

Normalize output paths and compare rustc profile flags. Expected: equivalent `lto`, codegen-unit, strip, panic, debug, and opt-level values.

Create a downstream fixture depending on the packaged crate:

```bash
cargo package
cargo new /tmp/profile-consumer
# Add the packaged crate as a dependency, then:
cargo build --manifest-path /tmp/profile-consumer/Cargo.toml -vv
```

Expected: the downstream root’s profiles control compilation; this crate’s `[profile.release]` and `[profile.dist]` are ignored, as Cargo documents. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto))

### Confidence & re-verify trigger

**Artifact recommendation: medium-high confidence.** The capability and fit evidence strongly favor the crates.io-plus-dist combination.

**Release-please integration: medium confidence.** The architectural boundary is clear, but the exact existing F063–F077 token, draft-release, and dispatch behavior was not available for an executable integration test.

**Profile recommendation: low-to-medium and explicitly conditional.** It agrees with the owner reference and current dist practice, but the owner-mandated measurements are absent. It should not be marked accepted until the benchmark table is populated.

Re-verify when:

- `cargo-dist` 0.34 or Config 1.0 is released;
- dist no longer requires `[profile.dist]` or gains a selectable Cargo profile;
- cargo-binstall 2.0 changes discovery, metadata, signatures, or archive conventions;
- release-please changes tag/release or token behavior;
- GitHub changes `GITHUB_TOKEN` recursion rules;
- cargo-dist issue #2420 or equivalent bootstrap-integrity behavior changes—the generated workflow currently has an open concern about checksum-verifying its own installer. ([github.com](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai))
- Windows or musl is added to the fixed matrix;
- R50 cannot smoke-test ARM64 artifacts;
- F301 defines a stack-trace or symbol-bundle requirement;
- the real template source replaces the stand-in;
- benchmark results show `codegen-units=1` or thin LTO does not pay for itself;
- the direct RustSec and dependency-tree MSRV checks fail;
- release CI exceeds the project’s eventual time or cost budget.

### Sources

All web sources retrieved **September 17, 2026**.

1. Cargo Book, **Profiles**:  
   `https://doc.rust-lang.org/cargo/reference/profiles.html`  
   Defaults, permitted values, workspace-root rule, inheritance, output directories, profile selection, and overrides. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai))

2. dist documentation, **Introduction**:  
   `https://axodotdev.github.io/cargo-dist/book/introduction.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/introduction.html?utm_source=openai))

3. dist documentation, **Configuration**:  
   `https://axodotdev.github.io/cargo-dist/book/reference/config.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai))

4. dist documentation, **Simple application/custom dist profile**:  
   `https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai))

5. dist documentation, **Shell installer**:  
   `https://axodotdev.github.io/cargo-dist/book/installers/shell.html` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/book/installers/shell.html?utm_source=openai))

6. dist changelog, including 0.33.0:  
   `https://axodotdev.github.io/cargo-dist/changelog/` ([axodotdev.github.io](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai))

7. cargo-dist repository and generated workflow:  
   `https://github.com/axodotdev/cargo-dist`  
   `https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml` ([github.com](https://github.com/axodotdev/cargo-dist?utm_source=openai))

8. cargo-dist bootstrap checksum issue:  
   `https://github.com/axodotdev/cargo-dist/issues/2420` ([github.com](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai))

9. cargo-binstall README:  
   `https://github.com/cargo-bins/cargo-binstall/blob/main/README.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai))

10. cargo-binstall maintainer metadata guide:  
    `https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai))

11. cargo-binstall signing guide:  
    `https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md` ([github.com](https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md?utm_source=openai))

12. GitHub documentation, **Triggering a workflow**:  
    `https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow` ([docs.github.com](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai))

13. GitHub documentation, **Events that trigger workflows**:  
    `https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows` ([docs.github.com](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai))

14. release-please action documentation:  
    `https://github.com/googleapis/release-please-action` ([github.com](https://github.com/googleapis/release-please-action?utm_source=openai))

15. release-plz binary-release alternatives:  
    `https://release-plz.dev/docs/extra/releasing-binaries` ([release-plz.dev](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai))

16. Composable upload-action alternative:  
    `https://github.com/step-security/upload-rust-binary-action` ([github.com](https://github.com/step-security/upload-rust-binary-action?utm_source=openai))

17. Required metric endpoints whose JSON values were **not successfully captured and therefore were not reported**:

    `https://crates.io/api/v1/crates/cargo-dist`  
    `https://crates.io/api/v1/crates/cargo-dist/versions`  
    `https://api.github.com/repos/axodotdev/cargo-dist`  
    `https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open`  
    `https://crates.io/api/v1/crates/cargo-binstall`  
    `https://crates.io/api/v1/crates/cargo-binstall/versions`  
    `https://api.github.com/repos/cargo-bins/cargo-binstall`  
    `https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open`

18. Owner-supplied local inputs, received September 17, 2026 and not independently retrieved:
    - `docs/port/OWNER-REVIEW.md`
    - `docs/planning/p02/owner-decisions.md`
    - `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`
    - `docs/port/PARAMETERS.md`
    - `docs/port/BASELINE-REVIEW.md`
    - R69 decision and evidence paths quoted in the prompt.

## Sources

- [Profiles - The Cargo Book](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto&utm_source=openai)
- [GitHub - axodotdev/cargo-dist: 📦 shippable application packaging · GitHub](https://github.com/axodotdev/cargo-dist?utm_source=openai)
- [GitHub - step-security/upload-rust-binary-action: GitHub Action for building and uploading Rust binary to GitHub Releases. Secure drop-in replacement for taiki-e/upload-rust-binary-action. · GitHub](https://github.com/step-security/upload-rust-binary-action?utm_source=openai)
- [Events that trigger workflows - GitHub Docs](https://docs.github.com/en/actions/reference/workflows-and-actions/events-that-trigger-workflows?utm_source=openai)
- [Config - dist](https://axodotdev.github.io/cargo-dist/book/reference/config.html?utm_source=openai)
- [cargo-dist/.github/workflows/release.yml at main · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/blob/main/.github/workflows/release.yml?utm_source=openai)
- [cargo-dist](https://axodotdev.github.io/cargo-dist/changelog/?utm_source=openai)
- [Profiles - The Cargo Book](https://doc.rust-lang.org/cargo/reference/profiles.html?highlight=lto)
- [GitHub - googleapis/release-please-action: automated releases based on conventional commits · GitHub](https://github.com/googleapis/release-please-action?utm_source=openai)
- [cargo-binstall/SUPPORT.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/SUPPORT.md?utm_source=openai)
- [A Simple Application - dist](https://axodotdev.github.io/cargo-dist/book/workspaces/simple-guide.html?utm_source=openai)
- [Introduction - The Cargo Book](https://doc.crates.io/?utm_source=openai)
- [cargo-dist/Cargo.toml at main · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/blob/main/Cargo.toml?utm_source=openai)
- [cargo-binstall/README.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/README.md?utm_source=openai)
- [Releasing binaries | Release-plz](https://release-plz.dev/docs/extra/releasing-binaries?utm_source=openai)
- [Triggering a workflow - GitHub Docs](https://docs.github.com/en/actions/how-tos/write-workflows/choose-when-workflows-run/trigger-a-workflow?utm_source=openai)
- [\[Feature request\] Checksum-verify the cargo-dist self-install in generated CI · Issue #2420 · axodotdev/cargo-dist · GitHub](https://github.com/axodotdev/cargo-dist/issues/2420?utm_source=openai)
- [Introduction - dist](https://axodotdev.github.io/cargo-dist/book/introduction.html?utm_source=openai)
- [shell - dist](https://axodotdev.github.io/cargo-dist/book/installers/shell.html?utm_source=openai)
- [cargo-binstall/SIGNING.md at main · cargo-bins/cargo-binstall · GitHub](https://github.com/cargo-bins/cargo-binstall/blob/main/SIGNING.md?utm_source=openai)
