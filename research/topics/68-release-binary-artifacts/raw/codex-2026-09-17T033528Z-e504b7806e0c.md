### Landscape

This item decides a distribution policy, not how Cargo declares the library or
binary. The category is “ways a Rust project makes its one published crate
available as an executable”: source installation from crates.io; project-owned
release archives; and convenience clients that discover those archives. The
three-bin survey below was completed before selecting a candidate. All web
figures and source snapshots in this report were retrieved on 2026-09-21 UTC.

| Bin | Candidate | What it does | Evidence and current state |
| --- | --- | --- | --- |
| Built-in / first-party toolchain | Cargo publish plus cargo install | Cargo publishes one .crate; an end user compiles it locally with cargo install --locked. | Cargo is the Rust project’s toolchain. It has no additional artifact builder or hosted-release protocol. The Cargo Book profiles reference is the authority for release-profile behavior. |
| Established industry pattern | cargo-dist plus GitHub Releases | Builds target archives, checksums, installer material, and GitHub-release upload workflow from workspace metadata. | cargo-dist 0.32.0 was the newest non-yanked crates.io release on 2026-05-22; its repository had fresh commits on 2026-09-17. Its maintained book documents GitHub Releases, archive naming, cargo-binstall compatibility, targets, checksums, and the dist profile. |
| Established industry pattern | cargo-binstall | A client that downloads conventional GitHub-release archives instead of compiling a crate. It is not an artifact producer. | cargo-binstall 1.23.0 was released on 2026-09-05; its support document says it works with existing CI-built outputs and tries defaults before package metadata. |
| Established but lower-level pattern | hand-written GitHub Actions with cargo-zigbuild or cross | A project scripts its own target matrix and archive naming. | cargo-zigbuild 0.23.4 and cross 0.2.5 are maintained build helpers, but they leave archive layout, checksum publication, release attachment, and installer compatibility to local workflow code. |
| Up-and-comer / adjacent consumer tool | cargo-quickinstall | Downloads prebuilt binaries where it can, otherwise compiles. | It changes a contributor’s installation experience, not what this template publishes; it cannot substitute for an artifact producer. |

The authoritative sources are deliberately diverse. The Rust project’s Cargo
Book is authoritative for Cargo’s own manifest and profile semantics
(https://doc.rust-lang.org/cargo/reference/profiles.html, retrieved
2026-09-21). The cargo-dist book and pinned source are authoritative for
cargo-dist’s supported workflow and artifact protocol
(https://opensource.axo.dev/cargo-dist/, retrieved 2026-09-21; pinned
v0.32.0 source commit 6886366640dd4da83d33ba55cc04aa58423cbad2). The
cargo-binstall support document is authoritative for that client’s discovery
rules (https://github.com/cargo-bins/cargo-binstall/blob/b874e25ea559687bec77e281e9b271aa1367b624/SUPPORT.md,
retrieved 2026-09-21). crates.io and GitHub API responses are authoritative
for the dated registry and repository figures recorded below. The Rust 2025
State of Rust Survey is contextual authority rather than a selection
mechanism: it reports 7,156 responses and still identifies resource usage,
including slow compilation and storage, as a productivity concern
(https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/,
retrieved 2026-09-21). That supports avoiding an unnecessary source compile
for a person installing a released CLI; it does not prove one tool is best.

Practice evidence confirms the pattern rather than deciding it. Cedar Policy
uses cargo-dist 0.32.0 workspace metadata, a multi-target list, a GitHub CI
backend, and a dist profile inheriting release with thin LTO; the repository
had 1,738 GitHub stars when queried (Cargo.toml at
https://github.com/cedar-policy/cedar/blob/9502ae02564a23028c732f8c1f2311635394c34f/Cargo.toml,
retrieved 2026-09-21). Rust Bindgen, a broadly used FFI binding generator with
5,286 queried GitHub stars, likewise has a dist profile inheriting release
with thin LTO (Cargo.toml at
https://github.com/rust-lang/rust-bindgen/blob/d130628608c85276a7186d1a222784741ff14fae/Cargo.toml,
retrieved 2026-09-21). These projects are relevant maintained Rust CLI/library
references; their configurations are not binding for this template.

The two source blueprints are evidence of different package ecosystems, not
selection authority. The Python blueprint invokes uv build for its source and
wheel artifacts at .github/workflows/ci.yml line 216, pinned at
https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/.github/workflows/ci.yml
(retrieved 2026-09-21). The TypeScript blueprint publishes its compiled dist
surface and declares ESM in package.json lines 20–23, pinned at
https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/package.json
(retrieved 2026-09-21). Cargo has one publishable .crate, so preserving their
principle means making the supported consumer surface easy and reproducible,
not imitating their artifact counts.

### Principles and implementation

The shared engineering requirement is a reproducible, discoverable release
surface for a template that can become a command-line application, library,
and optional web service. Its agreement level is capability and policy:
every fork must be able to install the documented CLI version reproducibly;
the exact CI implementation and archive formats may vary if they preserve the
same protocol. F214 records that source ecosystems legitimately differ in
package format, while F220 derives the end-user install method from this
decision (docs/port/COMMONALITY.md lines 218 and 224, read 2026-09-21).

The essential behaviors are:

1. Cargo publish keeps the base .crate and its R49 allow-list unchanged.
2. A tagged release publishes checksummed, conventional GitHub-release
   archives for the fixed Ubuntu and macOS CI operating systems.
3. A client using cargo-binstall can discover those archives without a
   template dependency or hand-maintained metadata when the conventional
   layout works.
4. The artifact build uses a documented Cargo profile, and the profile can be
   reproduced locally.
5. A library consumer does not inherit the template’s profile: Cargo reads
   profile settings only from the workspace root, and dependency profile
   settings are ignored. This is Cargo’s documented rule, not a template
   convention (Cargo Book profiles reference, retrieved 2026-09-21).

The observable acceptance criteria are a release tag with one archive per
chosen target, SHA-256 checksums, a successful cargo-binstall install for the
R49 command name rslbp, and an executable rslbp --version on each released
target. The profile criteria are a manifest whose only nondefault release
choices are thin LTO, one codegen unit, and symbol stripping; a dist profile
that inherits release; and recorded measurements before the workflow adopts
the profile. R50 owns the eventual install-and-run smoke mechanism, so these
are artifact requirements and proposed checks rather than an R50 test design.

There are three materially different architectures:

| Architecture | Strength | Cost and why it does not win |
| --- | --- | --- |
| crates.io only | Lowest release-workflow complexity; cargo install --locked is transparent and works for Rust developers. | It makes every non-Rust end user compile a template-derived command, duplicates toolchain and native-build setup, and does not address the Rust survey’s compile-resource concern. It is a credible early-fork choice, but weak as the default template release surface. |
| cargo-dist in follower mode plus ordinary GitHub-release archives | One maintained configuration expresses targets, archives, checksums, artifact URLs, and a release workflow. cargo-binstall recognizes the URL schema. | Adds build jobs and a tool-version pin. It has an active but nontrivial issue backlog, so version and generated workflow need a release-time recheck. |
| bespoke cross/cargo-zigbuild workflow | Maximum control over target/compiler setup. | Reimplements release naming, packaging, checksum, upload, and binstall assumptions. It creates template code that has to track GitHub Actions, Cargo, and client discovery conventions independently. |

The selected architecture preserves the principle by keeping the canonical
release description near Cargo metadata and by making GitHub Releases an
interoperable artifact boundary. cargo-dist’s maintained reference shows that
archives are its primary output, one per application/platform; its artifact
URL reference uses GitHub’s releases/download/tag path and conventional target
archive names (pinned book sources
https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/artifacts/archives.md
and
https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/reference/artifact-url.md,
retrieved 2026-09-21). The same pinned book says cargo-dist always invokes
Cargo with profile dist and gives a simple workspace example with dist
inheriting release and thin LTO
(https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/workspaces/simple-guide.md,
retrieved 2026-09-21).

The minimal realistic empirical example actually run for the profile subject
was a temporary edition-2024 binary named r68-profile-probe. It used 12 direct
dependencies: anyhow 1, axum 0.8.9, clap 4.5 with derive, reqwest 0.12 with
rustls-tls and no default features, serde 1 with derive, serde_json 1,
thiserror 2, tokio 1.53 with macros and rt-multi-thread, tower-http 0.6 with
trace, tracing 0.1, tracing-subscriber 0.3 with fmt, and uuid 1.18 with v4 and
serde. Its Cargo.lock contained 162 packages. The program exercised a Clap
command, serializable event, Tokio runtime, Reqwest client construction, Axum
Router health route, and TraceLayer. It is not the future template: it lacks
the template’s real modules, feature topology, optional web feature, tests,
and workload. Therefore its size and compile measurements are decision
evidence for profile direction, not a performance promise for rslbp.

The actual acceptance check run was compilation of that stand-in under Cargo
release defaults and profile variants on an Apple M4 Pro macOS host. The
proposed acceptance checks for the real template, including Ubuntu, are in
Validation strategy. No latency, throughput, memory, or web-service workload
was measured: profile compilation and artifact size were the measured
workload, so no runtime-performance claim is made.

### Dominant choice

cargo-dist is the dominant artifact-production choice for this use case:
recommend the cargo-dist 0.32.x line, specifically the verified 0.32.0
configuration pin, to generate GitHub Release archives and checksums. It is
active rather than merely familiar: crates.io reported 19,173 recent and
177,384 all-time downloads, the repository had 2,119 stars, was not archived,
and had a 2026-09-17 push (API retrieval 2026-09-21; exact endpoints in
Sources).

Use it in follower mode with release-please: release-please creates the
release/tag, cargo-dist is configured with create-release = false to upload to
the existing draft and undraft it. cargo-dist documents that setting as
assuming a draft GitHub release for the current tag, uploading assets, and
undrafting it (pinned config reference in Sources). This is an integration
design, not an executed GitHub submission. cargo-binstall needs no template
dependency and no default metadata because its documented GitHub release URL
and archive-root fallbacks cover cargo-dist’s conventional layout.

The planning record’s W1-R68 summary names cargo-dist 0.33.0, but the live
crates.io versions endpoint returned 0.32.0 as newest non-yanked. This report
cannot substantiate 0.33.0; synthesis must reconcile that accepted-but-live
unpublished/incorrect version reference before implementation. That is not a
consumed-parameter conflict.

### Qualified shortlist

All rows apply the fitness gates before their popularity figures. License
evaluation is inapplicable for every row by owner ruling Q7.B, recorded in
docs/port/OWNER-REVIEW.md under “2026-09-12 — no licence check for anything
the template uses”; it is not silently omitted. RustSec package pages returned
HTTP 404 for each queried tool on 2026-09-21, which means no package-page
advisory record was available from that endpoint, not that a complete
dependency audit passed. “Unsafe posture” is therefore “not independently
audited in this item”; P03 must audit the selected generated workflow and
dependency/tool supply chain.

| Candidate | Role | 90-day / all-time downloads | GitHub stars; newest release | State, adopters, gates, trade-off |
| --- | --- | --- | --- | --- |
| cargo-dist 0.32.x | Produces checked release archives and GitHub workflow. | 19,173 / 177,384 | 2,119; 0.32.0, 2026-05-22, declared Rust 1.74 | active; Cedar Policy and Rust Bindgen are relevant adopters. Its documented target support covers x86_64 and aarch64 Linux/macOS, including the fixed CI OSes; default GitHub CI backend and no async-runtime coupling. Its tool MSRV is below the current policy floor, though it is a release tool rather than a template dependency. Trade-off: generated workflow/tool pin. |
| cargo-binstall 1.23.x | Client-compatible discovery protocol for the release artifacts. | 127,019 / 3,497,734 | 2,887; 1.23.0, 2026-09-05, declared Rust 1.79 | active; it consumes but does not build artifacts. It has no template dependency-tree or runtime coupling. Its platform support is a client concern; conventional GitHub archive discovery covers the selected release targets. Trade-off: client behavior is outside the template’s release control. |
| cargo-zigbuild 0.23.x | Lower-level cross-builder for a bespoke workflow. | 1,541,771 / 7,205,638 | 2,662; 0.23.4, 2026-09-02, declared Rust 1.88 | active; compatible tool MSRV relative to the current policy floor, no async runtime, but requires Zig and local release packaging code. Trade-off: high integration ownership. |
| cross 0.2.x | Containerized cross-compile helper. | 312,622 / 6,311,289 | 8,320; 0.2.5, 2023-02-04, no declared Rust version | stable-quiet, not at-risk on the observed evidence; it adds container-image dependence and leaves release packaging local. Trade-off: the old release needs deliberate current-stable verification. |

For cargo-dist’s responsiveness sample, the ten newest open issues yielded two
maintainer answers and eight unanswered items; the median answered first
response was 0.335 days. The repository nevertheless had current commits and
a current release line, so the rubric result is active with a backlog caveat,
not at-risk. For cargo-binstall, all ten sampled newest open issues had a
first maintainer response, median 0.376 days. Commands, issue identifiers, and
the response calculation are retained in Sources.

The gate record below makes the applicability and evidence limits explicit.
“No listed advisory” means the required RustSec package-page endpoint returned
404; it is not a substitute for a future lockfile audit.

| Fitness gate | cargo-dist | cargo-binstall | cargo-zigbuild | cross |
| --- | --- | --- | --- | --- |
| 1. License | Inapplicable under owner Q7.B; tool declares MIT OR Apache-2.0. | Inapplicable under owner Q7.B; tool declares GPL-3.0-only. | Inapplicable under owner Q7.B; tool declares MIT. | Inapplicable under owner Q7.B; tool declares MIT OR Apache-2.0. |
| 2. Tool MSRV / template dependency tree | Declares Rust 1.74; no runtime template dependency. | Declares Rust 1.79; consumer tool, not template dependency. | Declares Rust 1.88; release-tool alternative, not template dependency. | No rust-version declaration; fails proof for the default. |
| 3. Advisory and unsafe posture | No listed package-page advisory; HTTP 404; no independent unsafe/dependency audit. | Same evidence limit. | Same evidence limit. | Same evidence limit. |
| 4. Fixed OS matrix | Documentation supports Linux and macOS targets; generated GitHub CI is the supported backend; real P03 run pending. | Client discovers publisher artifacts; Linux/macOS real install pending. | Builds cross targets, but workflow proof pending. | Cross target support exists, but current-stable and matrix proof pending. |
| 5. Features / runtime coupling | CLI release tool; no template runtime or async coupling. | Client program; no template runtime or async coupling. | CLI build tool; no template runtime or async coupling. | CLI/container build tool; no template runtime, but Docker coupling. |
| 6. Size / compile cost | Adds artifact-build jobs; archive/profile cost is measured separately below. | No producer build cost; client behavior outside template. | Requires Zig plus bespoke packaging work. | Requires container image plus bespoke packaging work. |

### Excluded by gate

No candidate is excluded solely for license: that gate is inapplicable under
the owner ruling named above. The following alternatives fail a required
fitness or architectural gate for this default template choice:

| Candidate | Failed gate or exclusion ground | Result |
| --- | --- | --- |
| cargo-binstall metadata as the only mechanism | It cannot build or attach binaries; it is a client discovery layer, not an artifact producer. | Excluded as the primary architecture; retain automatic compatibility as an outcome of cargo-dist archives. |
| cargo-quickinstall | It is also a consumer-side installer and does not create a GitHub release artifact contract. Registry figures were 8,679 recent / 503,091 all-time downloads; latest 0.3.53 on 2026-07-12; 315 stars. | Excluded from the shipping architecture. |
| crates.io-only default | Does not fail Cargo compatibility, but fails the template fitness gate of providing a no-source-compile install path for release users across its chosen CI OSes. | Excluded as the default; remains the always-available fallback via cargo install --locked rs-launch-blueprint. |
| manual cross/cargo-zigbuild workflow | Fails the integration-cost gate relative to a maintained end-to-end release publisher; it would need to reimplement archive, checksum, release, and binstall conventions. | Excluded unless cargo-dist fails P03’s generated-workflow probe. |
| cross as default | The available 0.2.5 release is older than six months and declares no rust-version; no concrete breakage/advisory was found, so it is not called dormant, but its MSRV and current-stable behavior remain unproven. | Excluded from the default until such evidence exists. |

### Up-and-comers

cargo-quickinstall is the relevant adjacent up-and-comer: current repository
activity was visible on 2026-09-21, but it operates after a publisher has
already chosen an artifact protocol. cargo-zigbuild is the more mature
lower-level alternative and has substantially more downloads than cargo-dist,
but its popularity measures use as a build primitive, not completion of this
template’s release contract. Neither changes the recommendation because the
missing concern is integration ownership, not compiler reach.

The cargo-dist project’s current configuration migration documentation says
existing Rust users can place cargo-dist configuration in
workspace.metadata.dist, which is a useful up-to-date convention but must be
rechecked for each selected tool version
(https://opensource.axo.dev/cargo-dist/book/install/config.html, retrieved
2026-09-21). A config-format change is specifically a re-verify trigger, not
a reason to switch tools today.

### Fit for this template

#### CLI

The CLI is the main beneficiary. R49 fixes package name rs-launch-blueprint
and the sole shipped command rslbp, so a direct archive lets a user run rslbp
without installing Rust. cargo-dist archives are the preferred channel, while
cargo install --locked rs-launch-blueprint remains the source fallback.
cargo-binstall’s support rules attempt conventional archive roots and final
binary names, and cargo-dist explicitly documents its GitHub Release URL
schema as auto-detected by cargo-binstall. The package/binary name difference
is the one compatibility detail to prove in the R50 smoke: if a fallback
metadata record is ever required, R49 says bin-dir must use {bin}, not {name}.
Do not add that metadata preemptively.

#### Library

Publishing the .crate remains the library distribution path. GitHub release
binaries neither replace nor alter Cargo dependency resolution. Cargo’s
workspace-root-only profile rule means a downstream consumer does not inherit
thin LTO, codegen-units = 1, stripping, or the dist profile merely by depending
on rs-launch-blueprint. That cleanly separates template executable tuning from
a consumer’s library build policy.

#### Web

The optional web feature benefits indirectly because the same release binary
can expose the web command surface, but this item does not decide a container
image. R51 owns that separate artifact. Keeping artifact archives focused on
the CLI/library binary avoids coupling the release choice to a container
registry or to the web service’s runtime deployment. The selected profile
retains panic = unwind, which avoids making a new crash-behavior commitment
while F301 remains open; R67’s crash record has timestamp, version, PID, code,
and sanitized cause chain, but no inherited stack-trace contract
(research/topics/67-error-and-exit-code-contract/DECISION.md, retrieved
2026-09-21).

### Recommendation

Ship a combination: the normal crates.io .crate plus cargo-dist 0.32.x
GitHub Release binaries and checksums for a deliberately small launch matrix:
x86_64-unknown-linux-gnu, aarch64-unknown-linux-gnu,
x86_64-apple-darwin, and aarch64-apple-darwin. These four targets mirror the
fixed CI operating systems and add both mainstream architectures within each
OS. They serve users, not only CI contributors. Do not add Windows while the
fixed matrix omits Windows; state Windows support as deferred, not implied.

Use cargo-dist 0.32.0 as the initial exact config pin and treat the approved
tool line as >=0.32.0, <0.33.0 until a fresh survey validates a newer line.
Set its GitHub backend and follower-mode create-release = false so
release-please owns version PR/tag/draft creation, then cargo-dist attaches
archives, checksums, and undrafts. cargo-dist’s config reference documents
checksum default sha256, the GitHub CI backend, the target list, and this
existing-draft behavior (pinned source listed in Sources). This is a planned
integration: no repository setting, GitHub workflow, release, or upload was
changed or submitted in this research run.

Do not add cargo-binstall metadata by default. cargo-binstall 1.23.0’s support
guide says the client works with existing CI-built outputs and only needs
metadata when defaults fail; cargo-dist’s installer documentation says its
GitHub URL schema is auto-detected. The required real artifact smoke must
prove cargo binstall --no-confirm rs-launch-blueprint resolves rslbp. If it
does not, add only the documented fallback metadata with bin-dir = "{bin}",
because the binary is rslbp rather than the package name.

The recommended release profile is:

    [profile.release]
    lto = "thin"
    codegen-units = 1
    strip = "symbols"

    [profile.dist]
    inherits = "release"

| Key | Recommendation | Manifest record and reason | Measured basis on 2026-09-21 |
| --- | --- | --- | --- |
| lto | thin | Write lto = "thin". Cargo defaults release to false; thin reduces the stand-in from 4,452,240 to 4,378,048 bytes by itself and composes with one codegen unit. | Thin plus one unit: 3,642,912 bytes, clean 28.22 s, edit rebuild 7.35 s; fat plus one unit: 3,156,320 bytes, clean 47.39 s, edit 18.99 s. Thin is the size/time balance. |
| codegen-units | 1 | Write codegen-units = 1. Cargo’s nonincremental default is 16. It improves optimized artifact size, while accepting slower edit rebuilds. | Alone: 3,685,888 bytes, clean 26.32 s, edit 3.04 s; combined thin result above. |
| strip | symbols | Write strip = "symbols". Cargo defaults to "none". It has the largest direct shipped-byte reduction and leaves no meaningful additional reduction for external strip -x. | Thin + one unit + symbols: 2,923,344 bytes, clean 28.68 s, edit 7.42 s; copied external strip -x size 2,923,360 bytes, a filesystem-level 16-byte difference. |
| opt-level | Cargo default 3 | Deliberately omit. Release default 3 is already the desired optimized level; a redundant line would imply a measured policy choice that this item did not test. | Baseline Cargo release row uses the documented value 3: 4,452,240 bytes, clean 29.04 s, edit 1.15 s. |
| debug | Cargo default false | Deliberately omit. A line-tables-only experiment did not establish a distributable symbolization benefit or a usable dSYM in this probe. | Thin + one unit + line tables: 3,928,368 bytes, clean 29.52 s, edit 8.84 s; with strip symbols: 2,923,200 bytes, clean 30.46 s, edit 7.89 s. |
| panic | Cargo default unwind | Deliberately omit. Release default is unwind. Abort reduces some code in a non-combined trial but changes recoverability and is not justified while F301 is open and R67 has no stack-trace requirement. | Thin + one unit + abort: 3,053,040 bytes, clean 25.58 s, edit 7.08 s. It was not a full factorial comparison with strip symbols. |
| dist custom profile | inherits = "release" | Write it because cargo-dist always builds with profile dist. It prevents the artifact workflow from silently using different settings. | Cargo-dist’s pinned simple guide shows the same inheritance pattern. Cost: target/dist and target/release have separate build caches. |

The macOS host was Darwin 25.4.0 on Apple M4 Pro, 14 CPU cores, 48 GB memory;
rustc was 1.98.0 (88d9e12ae 2026-08-18) and cargo was 1.98.0
(797e8a9bc 2026-08-05). Each clean build used a fresh profile output directory,
and each edit rebuild touched src/main.rs with CARGO_INCREMENTAL=0; it is a
dependency-cached rebuild, not a compiler-incremental benchmark. One sample
per row and shared downloaded registry sources mean differences are
directional, not statistically significant. A policy-floor check with rustc
and cargo 1.96.0 successfully built both defaults and the selected profile;
selected size was 2,923,344 bytes, clean 27.14 s, edit 8.14 s. No Ubuntu run
was available, so no cross-OS speed or size equivalence is claimed.

This agrees with the owner-reference profile input in the “Reference
Cargo.toml” section of
research/runs/R68/2026-09-17T033528Z-e504b7806e0c/inputs/owner-reference-axum-companion-stack-2026-09-16.md:
thin LTO and one codegen unit are retained. It differs only by adding symbol
stripping and an explicit dist inheritance, because this item’s local
measurement and cargo-dist’s profile contract supply evidence for those
additional records.

### Ranked runner-up

Runner-up: crates.io only, documented as cargo install --locked
rs-launch-blueprint, with Cargo’s default release profile. It wins if P03
cannot demonstrate cargo-dist’s generated follower workflow and a real
install on Ubuntu and macOS at a cost acceptable to the fork, or if the
project explicitly chooses to support only Rust-capable developers. It has no
external release archive infrastructure, but it gives up a no-compile install
path.

### Tradeoffs

The pick gives up the simplicity of crates.io-only releases: every version
needs multi-target artifact builds, checksum upload, a pinned cargo-dist
version, and generated-workflow review. It gives up the smallest possible
artifact achieved by fat LTO plus one codegen unit: the measured stand-in was
486,592 bytes smaller before stripping than thin plus one codegen unit, but fat
increased clean time from 28.22 s to 47.39 s and edit rebuild from 7.35 s to
18.99 s. The exact arithmetic should not be treated as a benchmark claim
because only one sample was taken; the directional build-time cost is enough
for the policy choice.

It gives up release-default edit speed because codegen-units = 1 and thin LTO
make a touched-source rebuild slower. That cost is accepted for a shipped
artifact profile, while contributors can still use the unoptimized development
profile. The separate dist profile has a cache-separation cost: target/dist
and target/release do not reuse final artifacts. It earns its keep because
cargo-dist otherwise uses profile dist and could silently diverge from the
profile humans believe release means.

It gives up shipped symbols and potential packaged debug information by using
strip = "symbols" and leaving debug false. That is accepted because no R67
contract requires a stack trace, the line-table test did not yield a verified
distributed debugging artifact, and an external symbol-upload policy would be
a separate future decision. It does not choose panic = "abort"; retaining
unwind avoids an unnecessary semantic change until F301 is resolved.

### Parameters

- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

R68 owns no registered parameter. The recommendation does not require any
consumed value to change, so there is no CONFLICT line. R69 revision 10 is an
accepted-but-unpublished design input only; it is noted here as a re-verify
trigger and is intentionally not adopted into an assumes line.

### Migration implications

These are proposed implementation changes, not changes made by this research
run:

| Asset | Proposed change | Owner boundary |
| --- | --- | --- |
| Cargo.toml | Keep R49 target declarations intact. Add the selected profile.release settings, profile.dist inheritance, and cargo-dist workspace metadata with cargo-dist-version = "0.32.0", ci = ["github"], create-release = false, SHA-256 checksums, and the four target triples. | R68 owns profile and binary-artifact policy; it must not edit R49’s lib/bin/include declarations. |
| release-please configuration | Configure the existing release-please flow to create the draft/tag consumed by follower-mode cargo-dist, after P03 verifies the exact release-please action/schema version. | F063–F077 own the broader release/versioning contract; R68 only supplies the artifact handoff. |
| .github/workflows/publish.yml or the generated cargo-dist workflow | Add the reviewed cargo-dist artifact build/upload stage after the release tag/draft exists. Preserve existing provenance, token, environment, and action-pinning rules. | The exact workflow filename and job boundary must be reconciled with the release tooling implementation; no workflow is created by this report. |
| README.md | Document direct GitHub Release archive installation and cargo install --locked rs-launch-blueprint as the source fallback. Mention cargo-binstall only after the planned artifact smoke proves it. | F220 derives the end-user wording from this result; R50 owns the smoke procedure. |
| CI cache documentation | Explain that cargo build --release and cargo build --profile dist use different target subdirectories and do not reuse final profile artifacts. | R68 owns the profile divergence explanation, not generic CI cache policy. |

The release-please action supports draft and force-tag-creation controls in its
current documentation (https://github.com/googleapis/release-please-action,
retrieved 2026-09-21). P03 must validate their interaction with the pinned
action/version before placing them in the template, because this report did
not create a release and cannot prove that release-please’s current output
matches cargo-dist’s existing-draft assumption.

### Validation strategy

The following are proposed P03/R50 checks. They are not represented as
executed results unless the row says “executed in this run.”

| Check | Command or procedure | Expected behavior |
| --- | --- | --- |
| Validate cargo-dist configuration | cargo dist generate; cargo dist build --artifacts=local | Generates a reviewable GitHub workflow and produces exactly the selected target archives/checksums without publishing. Inspect generated config for the four intended triples, profile dist, and SHA-256. |
| Verify follower release integration | In a disposable GitHub repository, let release-please create its draft/tag; run the generated cargo-dist release job with create-release = false against that draft. | cargo-dist finds the current-tag draft, uploads archives/checksums, and undrafts it. Validate both success and a negative control with no draft, which must fail clearly rather than create an unintended release. |
| Install direct artifacts | On ubuntu-latest and macos-latest for each selected architecture where a runner is available, download the release archive, verify SHA-256, extract it, run rslbp --version and a harmless help command. | The archive contains the R49 command rslbp, executable permissions survive extraction, and output reports the tag version. |
| Prove cargo-binstall auto-discovery | cargo binstall --no-confirm rs-launch-blueprint followed by rslbp --version, in clean temporary homes on Linux and macOS. | It resolves the conventional GitHub release archive without metadata. If it fails, capture the requested URL/path and add only a minimal {bin} metadata fallback, then rerun both positive and wrong-name controls. |
| Preserve source fallback | cargo install --locked --path . followed by rslbp --version; separately cargo package --allow-dirty --no-verify in a disposable copy. | The R49 binary name remains rslbp and the package allow-list is unaffected by distribution metadata/profile additions. |
| Profile reproducibility | cargo build --release and cargo build --profile dist; inspect the executable byte sizes and rustc -vV invocation; run cargo test --profile dist if the project’s test policy permits. | dist inherits each selected release behavior, produces the intended artifact, and does not alter default dev/test profile behavior. |
| MSRV and matrix guard | Set rust-toolchain to the policy floor at release time; run the exact artifact build on ubuntu-latest and macos-latest. | All selected settings compile at the declared rust-version/floor and use no unsupported target feature. Record toolchain versions and binary bytes on both OSes. |

The command shape used for the executed stand-in profile measurement was:

    CARGO_HOME=/private/tmp/r68-profile.7m5bNq/cargo-home CARGO_TARGET_DIR=/private/tmp/r68-profile.7m5bNq/target CARGO_INCREMENTAL=0 cargo build --quiet --manifest-path /private/tmp/r68-profile.7m5bNq/Cargo.toml --profile <profile>
    touch /private/tmp/r68-profile.7m5bNq/src/main.rs
    CARGO_HOME=/private/tmp/r68-profile.7m5bNq/cargo-home CARGO_TARGET_DIR=/private/tmp/r68-profile.7m5bNq/target CARGO_INCREMENTAL=0 cargo build --quiet --manifest-path /private/tmp/r68-profile.7m5bNq/Cargo.toml --profile <profile>

The first invocation was timed with /usr/bin/time -p as a clean
profile-output build; the second was the touched-source, dependency-cached
rebuild. The build succeeded for every reported macOS row and for the selected
profile under Rust 1.96.0. The Ubuntu and actual generated-release checks above
remain unrun gaps, not implied successes.

### Confidence & re-verify trigger

Confidence is moderate. The channel recommendation rests on maintained
primary documentation, current registry/API data, mainstream practice, and a
clear architecture comparison. The release-profile direction has direct local
measurement at both current Rust 1.98.0 and the current policy-floor Rust
1.96.0, but only on macOS and with one non-statistical stand-in sample per
setting.

Re-verify before implementation if any of the following changes: cargo-dist
0.33.0 or another newer line becomes available; cargo-dist’s generated
workflow/config schema changes; release-please changes draft/tag behavior;
R49 changes package/binary naming; R69 revision 10 is republished; the fixed
OS matrix changes; F301 establishes a stack-trace/symbol requirement; or
P03’s Ubuntu / real-artifact smoke disagrees with the macOS stand-in evidence.
The live-versus-planning cargo-dist 0.33.0 mismatch is already an immediate
reconciliation trigger.

### Sources

#### Primary Cargo and tool documentation

1. Cargo Book, Profiles, https://doc.rust-lang.org/cargo/reference/profiles.html
   (retrieved 2026-09-21). It establishes these release defaults: opt-level 3,
   debug false, strip "none", lto false, panic "unwind", incremental false,
   and codegen-units 16 for nonincremental builds. It also documents custom
   profiles requiring inherits, root-workspace-only profile settings,
   dependency-profile ignorance, override precedence (package name, wildcard,
   build override, profile, default), allowed LTO/strip/debug/panic values,
   and that package overrides cannot set panic, lto, or rpath.
2. cargo-dist v0.32.0 pinned source commit
   6886366640dd4da83d33ba55cc04aa58423cbad2, retrieved 2026-09-21:
   https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/installers/other.md
   says cargo-binstall auto-detects the GitHub Release URL schema;
   https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/artifacts/archives.md
   says archives are primary output, one per app/platform, and dist always
   uses profile dist; and
   https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/workspaces/simple-guide.md
   shows profile.dist inheriting release with thin LTO.
3. cargo-dist v0.32.0 pinned configuration reference,
   https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/reference/config.md
   (retrieved 2026-09-21). It documents cargo-dist-version as an exact semver
   Version, ci = ["github"], create-release = false, SHA-256 default
   checksum, and its supported targets. Its artifact URL reference is
   https://github.com/axodotdev/cargo-dist/blob/6886366640dd4da83d33ba55cc04aa58423cbad2/book/src/reference/artifact-url.md
   (retrieved 2026-09-21).
4. cargo-binstall v1.23.0 pinned support document,
   https://github.com/cargo-bins/cargo-binstall/blob/b874e25ea559687bec77e281e9b271aa1367b624/SUPPORT.md
   (retrieved 2026-09-21). It documents existing-CI output support, default
   GitHub URL fallbacks, default archive roots, final binary name {bin} plus
   extension, and metadata only when defaults do not work.
5. release-please action documentation,
   https://github.com/googleapis/release-please-action (retrieved
   2026-09-21), for draft and force-tag-creation configuration semantics.

#### Registry, repository, maintenance, and advisory queries

All query commands below used User-Agent rs-launch-blueprint-research/1.0
after an unauthenticated no-user-agent crates.io request returned HTTP 403.
The recorded successful command form was:

    curl -A 'rs-launch-blueprint-research/1.0' -sS https://crates.io/api/v1/crates/<name>
    curl -A 'rs-launch-blueprint-research/1.0' -sS https://crates.io/api/v1/crates/<name>/versions
    curl -sS https://api.github.com/repos/<owner>/<repo>
    curl -sS 'https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open'
    curl -sS https://rustsec.org/packages/<name>.html

Successful parsed outputs, all retrieved 2026-09-21:

| Tool | crates.io output: recent / all-time; latest non-yanked | GitHub output: stars; archived; pushed; open issue total | RustSec package-page output |
| --- | --- | --- | --- |
| cargo-dist | 19,173 / 177,384; 0.32.0, 2026-05-22T05:58:59.298224Z; rust_version 1.74; license MIT OR Apache-2.0 | 2,119; false; 2026-09-17T10:06:25Z; 297 | HTTP 404 |
| cargo-binstall | 127,019 / 3,497,734; 1.23.0, 2026-09-05T16:59:01.959145Z; rust_version 1.79; license GPL-3.0-only | 2,887; false; 2026-09-21T01:23:01Z; 94 | HTTP 404 |
| cargo-zigbuild | 1,541,771 / 7,205,638; 0.23.4, 2026-09-02T13:50:57.574197Z; rust_version 1.88; license MIT | 2,662; false; 2026-09-14T00:00:00Z; 4 | HTTP 404 |
| cross | 312,622 / 6,311,289; 0.2.5, 2023-02-04; rust_version absent; license MIT OR Apache-2.0 | 8,320; false; 2026-08-19T00:00:00Z; 228 | HTTP 404 |
| cargo-quickinstall | 8,679 / 503,091; 0.3.53, 2026-07-12; rust_version absent; license MIT OR Apache-2.0 | 315; false; 2026-09-21T00:00:00Z; 70 | HTTP 404 |

The endpoint field rules are the prompt’s required ones: recent_downloads,
downloads, newest non-yanked versions[].num/created_at, GitHub
stargazers_count/archived/pushed_at, and search/issues total_count. The URLs
are, respectively, https://crates.io/api/v1/crates/<name>,
https://crates.io/api/v1/crates/<name>/versions,
https://api.github.com/repos/<owner>/<repo>, and
https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open.
HTTP 404 from a RustSec package page is recorded as absence of that page’s
result, not a claim of zero advisories.

For issue responsiveness, the command selected ten newest open issues:

    curl -sS 'https://api.github.com/search/issues?q=repo:axodotdev/cargo-dist+is:issue+is:open&sort=created&order=desc&per_page=10'
    curl -sS 'https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open&sort=created&order=desc&per_page=10'

For cargo-dist the sampled identifiers were 2506, 2504, 2457, 2446, 2443,
2442, 2437, 2436, 2432, and 2429. Non-bot maintainer responses occurred for
2504 at 0.169 days and 2457 at 0.501 days: 2 answered, 8 unanswered, median
0.335 days. A 100-recent-commit author sample named Gankra, OpenSauce,
blyedev, eegli, mistydemeo, ntBre, rafeelaudibert, and woodruffw as
non-bot contributors. For cargo-binstall, all ten sampled newest issues had
responses; delays were 0.434, 0.758, 5.116, 0.027, 0.155, 0.395, 0.343,
0.643, 0.190, and 0.358 days, for a 0.376-day median. These are maintenance
signals, not a reliability benchmark.

#### Practice and owner inputs

1. Cedar Policy Cargo.toml, pinned commit
   9502ae02564a23028c732f8c1f2311635394c34f,
   https://github.com/cedar-policy/cedar/blob/9502ae02564a23028c732f8c1f2311635394c34f/Cargo.toml
   (retrieved 2026-09-21): cargo-dist 0.32.0, GitHub CI, multi-targets, and
   profile.dist inherits release with thin LTO. GitHub repository query:
   https://api.github.com/repos/cedar-policy/cedar, 1,738 stars at retrieval.
2. Rust Bindgen Cargo.toml, pinned commit
   d130628608c85276a7186d1a222784741ff14fae,
   https://github.com/rust-lang/rust-bindgen/blob/d130628608c85276a7186d1a222784741ff14fae/Cargo.toml
   (retrieved 2026-09-21): profile.dist inherits release and uses thin LTO.
   GitHub repository query: https://api.github.com/repos/rust-lang/rust-bindgen,
   5,286 stars at retrieval.
3. Owner profile input, “Reference Cargo.toml” section:
   research/runs/R68/2026-09-17T033528Z-e504b7806e0c/inputs/owner-reference-axum-companion-stack-2026-09-16.md,
   read 2026-09-21. It supplies thin LTO plus codegen-units = 1 as an input,
   not a pre-decision.
4. R49 decision and live parameter registry:
   research/topics/49-build-target-declaration/DECISION.md and
   docs/port/PARAMETERS.md, read 2026-09-21. They establish the one rslbp
   binary, package-name difference, allow-list, and the exact consumed values
   copied in Parameters.
5. R67 decision:
   research/topics/67-error-and-exit-code-contract/DECISION.md, read
   2026-09-21. It establishes the crash-record fields and the absence of a
   stack-trace requirement; F301 remains open.

#### Executed profile measurement

The host and tool output, captured 2026-09-21 UTC:

    uname -a
    Darwin Steves-MacBook-Pro.local 25.4.0 Darwin Kernel Version 25.4.0: Thu Mar 19 19:33:25 PDT 2026; root:xnu-12377.101.15~1/RELEASE_ARM64_T6041 arm64
    system_profiler SPHardwareDataType
    Chip: Apple M4 Pro; Total Number of Cores: 14 (10 Performance and 4 Efficiency); Memory: 48 GB
    rustc -V
    rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
    cargo -V
    cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
    rustup run 1.96.0 rustc -V
    rustc 1.96.0 (ac68faa20 2026-05-25)
    rustup run 1.96.0 cargo -V
    cargo 1.96.0 (30a34c682 2026-05-25)

| Profile under Rust 1.98.0 | Executable bytes | Bytes after copied strip -x | Clean seconds | Touched-source seconds |
| --- | ---: | ---: | ---: | ---: |
| Cargo release defaults | 4,452,240 | 3,622,448 | 29.04 | 1.15 |
| thin LTO only | 4,378,048 | 3,548,384 | 23.44 | 5.68 |
| fat LTO only | 3,484,048 | 2,855,928 | 37.81 | 21.54 |
| one codegen unit only | 3,685,888 | 3,130,496 | 26.32 | 3.04 |
| thin LTO plus one unit | 3,642,912 | 3,086,176 | 28.22 | 7.35 |
| fat LTO plus one unit | 3,156,320 | 2,591,008 | 47.39 | 18.99 |
| thin plus one unit plus strip symbols | 2,923,344 | 2,923,360 | 28.68 | 7.42 |
| thin plus one unit plus line-tables-only debug | 3,928,368 | 3,086,160 | 29.52 | 8.84 |
| thin plus one unit plus strip symbols plus line tables | 2,923,200 | 2,923,224 | 30.46 | 7.89 |
| thin plus one unit plus panic abort | 3,053,040 | 2,617,888 | 25.58 | 7.08 |

The compiler verbose invocation for the strip/debug test included
-C opt-level=3, -C lto=thin, -C codegen-units=1,
-C debuginfo=line-tables-only, -C split-debuginfo=unpacked, and
-C strip=symbols. No usable .dSYM was found in the probe output, so the test
does not demonstrate a shippable symbolization workflow. With
CARGO_INCREMENTAL=1, the unshipped extra check measured defaults at 21.78 s
clean / 0.57 s touched and selected profile at 27.48 s clean / 7.01 s touched.
It does not change the recommended release setting; it illustrates why the
reported normal test uses CARGO_INCREMENTAL=0.

At Rust 1.96.0, the default stand-in built successfully at 4,452,240 bytes,
22.15 s clean, and 0.96 s touched. The selected thin/one-unit/strip-symbols
profile built successfully at 2,923,344 bytes, 27.14 s clean, and 8.14 s
touched. No rust target other than aarch64-apple-darwin was installed locally.
Docker reported a Linux arm64 server but no available Rust build image, so an
ubuntu-latest measurement was not manufactured from unlike infrastructure.
