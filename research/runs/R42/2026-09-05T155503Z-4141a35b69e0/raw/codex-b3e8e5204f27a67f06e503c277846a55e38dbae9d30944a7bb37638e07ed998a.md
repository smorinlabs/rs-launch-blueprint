### Landscape

**Category.** R42 chooses the provisioning and invocation boundary for development
tools in a template that contains a command-line application, a library, and a
web service. The required capability is reproducible, explainable developer and
CI tooling on Ubuntu and macOS; it is an architectural pattern, not a requirement
that all three ports use one package manager. Retrieved 2026-09-05.

| Bin | Candidates found | Evidence and fit |
|---|---|---|
| Built-in or first-party toolchain | `rustup`, `rust-toolchain.toml`, `rustfmt`, `clippy`, and Cargo subcommands `cargo fmt` / `cargo clippy` | Rustup is an official Rust Project and the recommended Rust installer; its documented default profile includes `rustfmt` and `clippy`, and `rust-toolchain.toml` can add components. This directly covers the Rust-specific formatter and linter without an extra package manager. [rustup FAQ](https://rust-lang.github.io/rustup/faq.html), [profiles](https://rust-lang.github.io/rustup/concepts/profiles.html), and [overrides](https://rust-lang.github.io/rustup/overrides.html), retrieved 2026-09-05. |
| Established industry standard | Cargo-installed subcommands, explicit `Justfile` recipes for a non-Cargo binary, and declarative environment managers `mise` and Flox | Cargo documents `cargo install` as the command that manages locally installed Rust binaries. `mise` documents a `[tools]` configuration that can install many backends; Flox documents a reproducible declarative `manifest.toml`. These are alternatives, not complementary requirements. [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html), [mise configuration](https://mise.jdx.dev/configuration.html), and [Flox README](https://github.com/flox/flox), retrieved 2026-09-05. |
| Up-and-comer / convenience layer | `cargo-binstall`, which downloads a released Rust binary before falling back to `cargo install` | It can reduce compile time, but its current crate release is GPL-3.0-only, so it fails this template's `MIT OR Apache-2.0` license gate. It cannot supply non-Rust tools such as an action-workflow linter or a Go secret scanner. [cargo-binstall README](https://github.com/cargo-bins/cargo-binstall), [crates.io API](https://crates.io/api/v1/crates/cargo-binstall), retrieved 2026-09-05. |

**Authorities and practice.** The Rust Project's rustup and Cargo books are
first-party standards for the toolchain and command surface. The official mise and
Flox documentation is authoritative for the products' manifests, not evidence that
they are required by Rust projects. The rustup project documents its own
`cargo clippy` invocation, and Tokio's CI installs Rust separately and installs
`cargo-nextest` as a separate executable; this is representative practice from
well-regarded projects, respectively maintained by the Rust Project and a widely
used async-runtime team. Tokio's repository had 31,731 GitHub stars when queried
at `GET https://api.github.com/repos/tokio-rs/tokio` on 2026-09-05; rustup had
7,032 at `GET https://api.github.com/repos/rust-lang/rustup` on the same date.
[rustup linting guide](https://rust-lang.github.io/rustup/dev-guide/linting.html),
[Tokio CI](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml),
and [Tokio repository API](https://api.github.com/repos/tokio-rs/tokio), retrieved
2026-09-05.

The target is intentionally narrower than py's Python, Node, and standalone-CLI
mix: rustfmt and Clippy are toolchain components, while R27--R29, R32, R37, R39,
and R40 may later select a small number of external commands. The fact that those
future commands are not yet selected makes a general all-tools manifest premature,
not a reason to pretend they are Cargo packages. `actionlint`, for example,
documents released-binary, Homebrew, and `go install` distribution routes, proving
that Cargo alone cannot provision every plausible selected tool.
[actionlint README](https://github.com/rhysd/actionlint), retrieved 2026-09-05.

### Principles and implementation

**Shared requirement and agreement level.** The py and ts sources agree on a
two-level setup experience: a bootstrap layer makes dependencies available and a
Justfile runs development work. That is an architectural pattern. They do not agree
on which non-primary-package-manager binaries to install, so tool choice and
distribution mechanism may vary. The Rust-native essential behavior is: (1) the
repository selects its Rust toolchain and required components deterministically,
(2) recipes invoke first-party tools through Cargo so the selected toolchain is
used, (3) an external tool is present on `PATH` before a hook or recipe invokes it,
and (4) a missing external tool gives an exact remediation command. Rustup's
directory override format supports the first behavior and Cargo documents the
second command family. [rustup overrides](https://rust-lang.github.io/rustup/overrides.html),
[cargo fmt](https://doc.rust-lang.org/cargo/commands/cargo-fmt.html), and
[cargo clippy](https://doc.rust-lang.org/cargo/commands/cargo-clippy.html),
retrieved 2026-09-05.

**Architecture comparison.** Rustup/Cargo alone is the lowest-integration-cost
answer for Rustfmt and Clippy, but it fails the capability gate once an R39/R40
tool is a non-Rust binary. A single `mise.toml` would give one declarative tool
list and cross-platform shims, but makes mise itself mandatory and duplicates the
already native `rust-toolchain.toml`/Cargo channels. Flox adds a manifest and lock
with stronger whole-environment reproducibility, but its Nix environment model is
more machinery than this two-OS template needs. Keeping both adds three sources of
truth, exactly the manual-sync risk observed in py. Explicit installer recipes are
the smallest interoperable layer because they exist only for tools whose official
distribution cannot be represented by rustup or Cargo. [mise README](https://github.com/jdx/mise),
[Flox README](https://github.com/flox/flox), and [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html),
retrieved 2026-09-05.

**Recommended composition.** Commit `rust-toolchain.toml` with R27's eventual
channel and `components = ["rustfmt", "clippy"]`. `make check` verifies `rustup`,
`cargo`, the active toolchain, and those components. The `Justfile` uses `cargo
fmt --check` and `cargo clippy ...`; it never calls `rustfmt` or `clippy-driver`
bare. For each selected external command, add `install-<tool>` and
`install-<tool>-force` recipes. Each recipe owns that tool's pinned version,
official release URL, SHA-256 verification, and macOS/Ubuntu artifact mapping,
while a shared POSIX-shell helper only provides common `command -v`, download, and
checksum mechanics. `just check-deps` checks only the selected external commands
and prints the matching installer recipe. Lefthook calls each external command by
its documented binary name on `PATH`; this is required because they are not Cargo
subcommands. This example is proposed, not executed: the repository has no Rust
template code yet.

The observable acceptance check is a small CLI/library/web workspace with the
committed toolchain file. On clean Ubuntu and macOS runners, `rustup show`,
`cargo fmt --check`, and `cargo clippy --workspace --all-targets --all-features --
-D warnings` must succeed without mise or Flox. Removing a selected external
binary must make only its hook/check-deps remediation fail; running its
`install-<tool>` must restore it, and a deliberately wrong SHA-256 must fail before
the binary is installed. This checks correctness, provenance, OS routing, and
failure behavior rather than claiming benchmark performance. Rustup documents that
components are toolchain-specific and can vary by toolchain, which is why CI must
exercise the committed channel. [rustup components](https://rust-lang.github.io/rustup/concepts/components.html),
retrieved 2026-09-05.

BASELINE-REVIEW: F181 — capability: full-toolchain readiness with actionable
remediation — retain `just check-deps` only for the small selected external PATH
tool set; keep rustup/Cargo/component verification in F180's bootstrap check —
evidence: rustup distributes rustfmt/Clippy as components, whereas actionlint
documents non-Cargo distribution; affected F180, F181, F183, F186.

BASELINE-REVIEW: F187/F188/F189 — policy: multiple declarative provisioners —
omit `mise.toml`, `.flox/env/manifest.toml`, and manual three-way synchronization;
use the native Rust toolchain plus conditional explicit external installers —
evidence: mise and Flox are optional competing environment products, and the
target's known first-party surface is already represented by `rust-toolchain.toml`;
affected F183, F187, F188, F189.

### Recommendation

Adopt one **native, origin-routed stack**: `rust-toolchain.toml` plus rustup for
the Rust toolchain and components; Cargo subcommands for Rust development checks;
the existing Make/Just layering for bootstrap/tasks; and a conditional, per-tool
Justfile installer only for a later-selected non-Cargo command. Do not add mise or
Flox. Do not add `cargo-binstall`: its current GPL-3.0-only release fails the
fixed license gate. Pin every external installer to the vendor release and
checksum; invoke its installed binary on `PATH`. This is similar to py where an
extra tool truly needs native installation, while avoiding py's duplicated
provisioner manifests and preserving Rust's first-party path. Sources and
retrieval dates are recorded in the member fields below.

### Members

#### rustup + rust-toolchain.toml + Cargo subcommands

##### Landscape

Built-in/first-party candidate and dominant Rust choice: rustup owns toolchains
and components; Cargo exposes the `fmt` and `clippy` commands. The Rust Project
is the authoritative maintainer. [rustup components](https://rust-lang.github.io/rustup/concepts/components.html)
and [Cargo command reference](https://doc.rust-lang.org/cargo/commands/index.html),
retrieved 2026-09-05.

##### Principles and implementation

Keep formatter/linter versions coupled to the Rust channel, rather than installing
unrelated bare binaries. `rust-toolchain.toml` supplies additive components, and
`cargo fmt`/`cargo clippy` use that selected Cargo/toolchain path. [rustup overrides](https://rust-lang.github.io/rustup/overrides.html)
and [rustup proxies](https://rust-lang.github.io/rustup/concepts/proxies.html),
retrieved 2026-09-05.

##### Dominant choice

`rust-toolchain.toml` with `rustfmt` and `clippy`; `cargo fmt` and `cargo clippy`.
It is first-party, MIT/Apache-compatible in the Rust Project, stable-toolchain
native, and available on Ubuntu and macOS. [rustup FAQ](https://rust-lang.github.io/rustup/faq.html),
retrieved 2026-09-05.

##### Qualified shortlist

Rustup default profile or explicit `components` are both valid. Explicit
components are preferred because they make the template's requirement observable,
independent of a developer's selected default profile. [rustup profiles](https://rust-lang.github.io/rustup/concepts/profiles.html),
retrieved 2026-09-05.

##### Excluded by gate

Bare `rustfmt`/`clippy-driver` invocation is excluded: it makes the selected
toolchain less explicit and bypasses Cargo's documented subcommand surface. No
crate candidate exists, so crates.io figures, dependency-tree MSRV, RustSec, and
unsafe posture are inapplicable.

##### Up-and-comers

None needed. `llvm-tools` is available through rustup but is explicitly not
stabilized and is out of scope until a later item needs it. [rustup components](https://rust-lang.github.io/rustup/concepts/components.html),
retrieved 2026-09-05.

##### Fit for this template

No async runtime coupling; default component behavior is documented by rustup.
Compile-time and binary-size cost are inapplicable because these are external
development tools, not application dependencies. Component availability must be
checked on both required runner OSes; Windows is noted but not required. [rustup components](https://rust-lang.github.io/rustup/concepts/components.html),
retrieved 2026-09-05.

##### Recommendation

Adopt it. R27 supplies the exact channel and lint/format configuration; R42
supplies the installer/invocation boundary.

##### Ranked runner-up

No runner-up for Rustfmt/Clippy: a general provisioner can install Rust but
duplicates rustup's toolchain semantics.

##### Tradeoffs

Rustup components follow a toolchain, so changing the channel can change tool
availability; explicit components and CI make that visible. [rustup components](https://rust-lang.github.io/rustup/concepts/components.html),
retrieved 2026-09-05.

##### Parameters

Assumes fixed `rust-edition = 2024`, `msrv-policy`, and `target-os-matrix =
ubuntu-latest, macos-latest`. No conflict.

##### Migration implications

Add `rust-toolchain.toml`; add Cargo-subcommand lines to `Justfile` and
`lefthook.yml`; add bootstrap validation to `Makefile`.

##### Validation strategy

Planned on Ubuntu and macOS: `rustup show active-toolchain`, `rustup component
list --installed`, `cargo fmt --check`, and `cargo clippy --workspace
--all-targets --all-features -- -D warnings`. Expected: both components appear and
the Cargo commands succeed. No command was executed because no Rust template
exists.

##### Confidence & re-verify trigger

High. Re-verify when R27 selects a channel or when rustup reports either component
unavailable for that channel/OS.

##### Sources

[Rustup components](https://rust-lang.github.io/rustup/concepts/components.html),
[rustup overrides](https://rust-lang.github.io/rustup/overrides.html), and
[Cargo fmt](https://doc.rust-lang.org/cargo/commands/cargo-fmt.html), retrieved
2026-09-05. Pattern member: crates.io figures are inapplicable.

#### Conditional explicit external-tool Justfile recipes

##### Landscape

Established pattern for commands outside the primary ecosystem package manager.
It remains necessary if later owners select a Go, Node, or vendor-released tool;
actionlint is a concrete non-Cargo example. [actionlint README](https://github.com/rhysd/actionlint),
retrieved 2026-09-05.

##### Principles and implementation

One recipe per external tool is the provenance boundary: it can name its official
URL, version, SHA-256, binary name, and supported OS artifacts. A shared helper
may remove duplicated shell mechanics but may not hide per-tool source or checksum
data.

##### Dominant choice

Conditional `install-<tool>` / `install-<tool>-force` recipes plus a common POSIX
helper. This preserves actionable remediation while avoiding an installer for
Rustup-managed components.

##### Qualified shortlist

Vendor release archives with checksums; a vendor-supported native package manager;
or `cargo install --locked` when the selected tool is a compatible Rust crate.
Cargo documents `cargo install` as local Rust-binary management. [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html),
retrieved 2026-09-05.

##### Excluded by gate

A universal unpinned "curl latest" helper is excluded: it cannot establish a
version or integrity check. An all-Cargo-only design is excluded because it cannot
install a selected non-Rust CLI. Crate figures and RustSec are inapplicable to this
pattern, not silently omitted.

##### Up-and-comers

`cargo-binstall` is evaluated separately below. It does not replace an external
tool installer.

##### Fit for this template

No runtime, application dependency, unsafe code, compile-time, or binary-size
impact. The installer must map Ubuntu and macOS artifacts and be exercised on
both; Windows support is not required.

##### Recommendation

Adopt conditionally, only after the consuming item selects a non-Cargo tool.

##### Ranked runner-up

One `mise.toml` manifest; it is less suitable now because it makes an additional
tool manager a prerequisite for every contributor.

##### Tradeoffs

Per-tool recipes add source-specific maintenance, but make security provenance and
failure remediation local and reviewable. A generic helper reduces mechanical
duplication, not configuration ownership.

##### Parameters

Uses the owned invocation rule: external tools are invoked as provisioned
bare binaries on `PATH`. No conflict.

##### Migration implications

Add only selected `install-*` recipes, a shared installer helper, and matching
`check-deps` remediation lines. Do not add an installer before a tool is selected.

##### Validation strategy

Planned: on each required OS, remove the test binary, assert `just check-deps`
fails with its named recipe, install it, run `command -v <tool>`, and force an
incorrect SHA-256 to prove installation aborts. No command executed.

##### Confidence & re-verify trigger

Medium-high. Re-verify when R39/R40/R29 selects an external command or a vendor
changes release archive/checksum publication.

##### Sources

[actionlint installation routes](https://github.com/rhysd/actionlint),
[Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html),
retrieved 2026-09-05. Pattern member: crate figures are inapplicable.

#### mise declarative provisioner

##### Landscape

Established cross-language environment manager with a `[tools]` configuration,
multiple install backends, task support, and a lockfile mode. Its own documentation
is authoritative for these capabilities. [mise configuration](https://mise.jdx.dev/configuration.html),
retrieved 2026-09-05.

##### Principles and implementation

Mise could centralize pins and put shims on `PATH`, including Cargo and GitHub
release backends. It does not remove rustup's toolchain-file semantics; choosing it
would add a second provisioning control plane.

##### Dominant choice

Not selected for this template.

##### Qualified shortlist

Use only if a future template deliberately standardizes a broad multi-language
toolchain and accepts mise as its required bootstrap dependency.

##### Excluded by gate

Excluded by integration-fit gate, not license or maintenance: the Rust-first tool
surface is known and small, while selected non-Rust tools are presently unknown.
Crate figures, dependency-tree MSRV, RustSec, unsafe posture, application feature
flags, compile time, and binary size are inapplicable because R42 evaluates mise
as a provisioning pattern, not a Rust application dependency.

##### Up-and-comers

Mise is actively developed; its documentation advertises registry, lockfile, and
backend features. That capability does not outweigh the extra mandatory manager.
[mise configuration](https://mise.jdx.dev/configuration.html), retrieved 2026-09-05.

##### Fit for this template

It supports macOS and Linux, but changes the first-clone path and duplicates
`rust-toolchain.toml` for first-party Rust tooling. No async coupling.

##### Recommendation

Do not commit `mise.toml`.

##### Ranked runner-up

Flox offers stronger whole-environment reproducibility but a larger operational
model.

##### Tradeoffs

Mise improves centralized declarations when many ecosystems are mandatory; here it
adds a bootstrap and an avoidable second place to update versions.

##### Parameters

No parameter value owned by R42 requires mise. No conflict.

##### Migration implications

Do not add `mise.toml`, mise bootstrap documentation, or mise invocations to
Justfile/lefthook.

##### Validation strategy

Not adopted. If reconsidered, a planned clean-runner test would compare `mise
install` with native bootstrap and prove all selected tool versions on both OSes.

##### Confidence & re-verify trigger

Medium. Reconsider only if later items select a sufficiently broad, permanently
multi-ecosystem tool set that individual verified installers become burdensome.

##### Sources

[mise README](https://github.com/jdx/mise) and [mise configuration](https://mise.jdx.dev/configuration.html),
retrieved 2026-09-05. Pattern member: crate figures are inapplicable.

#### Flox declarative provisioner

##### Landscape

Flox is a declarative environment platform built around a manifest and lockfile;
its repository documents reproducible, content-hashed package inputs and macOS/
Linux installation. [Flox README](https://github.com/flox/flox), retrieved
2026-09-05.

##### Principles and implementation

Flox provides stronger complete-environment reproducibility than an installer
recipe, but asks contributors and CI to operate a Nix-derived environment in
addition to rustup/Cargo.

##### Dominant choice

Not selected.

##### Qualified shortlist

Use only for an organization that explicitly requires a locked, multi-language
developer environment as a product constraint.

##### Excluded by gate

Excluded by integration-fit gate: whole-environment reproducibility is useful but
not required by the stated Rust CLI/library/web-service template, and its added
bootstrap surface violates the minimal-origin-routed design. Crate figures,
dependency-tree MSRV, RustSec, unsafe posture, application features, compile time,
and binary size are inapplicable to this pattern member.

##### Up-and-comers

Flox's lockfile-based environment product is a credible alternative, not a Rust
ecosystem standard. [Flox README](https://github.com/flox/flox), retrieved
2026-09-05.

##### Fit for this template

The documented macOS/Linux support meets the target OS matrix, but the narrower
tool surface does not justify its operational cost. No async coupling.

##### Recommendation

Do not add `.flox/env/manifest.toml`.

##### Ranked runner-up

Mise is the lighter declarative alternative, but is also not adopted.

##### Tradeoffs

Flox has the best environment-locking story of the alternatives, at the cost of
another ecosystem and installation model for every contributor.

##### Parameters

No parameter value owned by R42 requires Flox. No conflict.

##### Migration implications

Do not add `.flox/`, Flox lockfiles, bootstrap documentation, or Flox calls.

##### Validation strategy

Not adopted. If reconsidered, prove identical locked tool versions on fresh
Ubuntu/macOS runners and compare the setup failure diagnostics with the native
path.

##### Confidence & re-verify trigger

Medium. Reconsider only on an explicit owner requirement for locked whole
developer environments.

##### Sources

[Flox README](https://github.com/flox/flox), retrieved 2026-09-05. Pattern member:
crate figures are inapplicable.

#### cargo-binstall

##### Landscape

Convenience candidate for installing released Rust CLI binaries instead of
compiling them. Its maintainer describes a release-artifact search followed by a
Cargo fallback. [cargo-binstall README](https://github.com/cargo-bins/cargo-binstall),
retrieved 2026-09-05.

##### Principles and implementation

It can reduce setup latency for Cargo-distributed tools, but is neither rustup nor
a general external-tool manager. Its artifacts introduce a release-discovery and
fallback chain that is less explicit than a selected tool's own verified installer.

##### Dominant choice

Excluded.

##### Qualified shortlist

Only reconsider for a separately selected Cargo CLI if its license becomes
compatible, its release MSRV meets the fixed policy, and a source-build fallback
is acceptable.

##### Excluded by gate

**License gate failed:** latest non-yanked `cargo-binstall` version `1.22.0` is
`GPL-3.0-only`, incompatible with `MIT OR Apache-2.0`. Registry endpoint
`GET https://crates.io/api/v1/crates/cargo-binstall/versions`, retrieved
2026-09-05. The RustSec package page
`https://rustsec.org/packages/cargo-binstall.html` returned HTTP 404 on
2026-09-05, so no "no advisories" claim is made. Because the license gate fails,
it is not eligible for popularity weighting.

##### Up-and-comers

It is active: GitHub reported 2,857 stars, `archived: false`, and
`pushed_at: 2026-09-05T14:30:08Z` at
`GET https://api.github.com/repos/cargo-bins/cargo-binstall`, retrieved
2026-09-05. This does not cure the license failure.

##### Fit for this template

Cargo-package member. `GET https://crates.io/api/v1/crates/cargo-binstall`
reported 124,426 90-day downloads and 3,474,273 all-time downloads on
2026-09-05; `GET https://crates.io/api/v1/crates/cargo-binstall/versions`
reported latest non-yanked `1.22.0`, created
`2026-08-22T15:24:08.343732Z`, `rust_version: 1.79.0`, and
`license: GPL-3.0-only`. `GET https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open`
reported 94 open issues. Issue responsiveness could not be measured because the
GitHub API returned HTTP 403 during the ten-issue query; that is recorded rather
than inferred. Default features, async coupling, unsafe posture, binary-size, and
compile-time cost were not evaluated further after the mandatory license failure.

##### Recommendation

Do not adopt.

##### Ranked runner-up

`cargo install --locked <selected-tool>` is the compatible first fallback for a
Rust CLI, subject to that selected tool's own gates. [Cargo install](https://doc.rust-lang.org/cargo/commands/cargo-install.html),
retrieved 2026-09-05.

##### Tradeoffs

Fast binary download is attractive, but the artifact-selection fallback chain and
incompatible license add risk without covering non-Rust tools.

##### Parameters

No change to `package-manager-invocation`; it is excluded. No conflict.

##### Migration implications

Do not add `cargo binstall` to Makefile, Justfile, CI, or documentation.

##### Validation strategy

Not adopted. If a future compatible release is considered, planned checks are
license/MSRV/RustSec review plus clean Ubuntu/macOS install and fallback behavior.

##### Confidence & re-verify trigger

High for exclusion while the latest release remains GPL-3.0-only. Re-verify on a
license change or before any adoption proposal.

##### Sources

[crate API](https://crates.io/api/v1/crates/cargo-binstall),
[versions API](https://crates.io/api/v1/crates/cargo-binstall/versions),
[GitHub repository API](https://api.github.com/repos/cargo-bins/cargo-binstall),
[open-issues API](https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open),
[RustSec package page](https://rustsec.org/packages/cargo-binstall.html), and
[maintainer README](https://github.com/cargo-bins/cargo-binstall), retrieved
2026-09-05.

### Compatibility

The chosen members compose without a version matrix: rustup selects the compiler
and components through `rust-toolchain.toml`; Cargo invokes those components;
external recipes install only commands absent from that toolchain and leave them on
`PATH` for Lefthook. Tokio provides a maintained reference composition in which CI
installs Rust separately and installs `cargo-nextest` as a separate command.
[Tokio CI](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml),
retrieved 2026-09-05. The proposed acceptance matrix is the actual compatibility
proof: clean `ubuntu-latest` and `macos-latest` jobs run native Cargo checks, then
the selected external hook command. No shared adopter of rustup, a future external
tool, and this nonexistent template can yet be asserted.

### Parameters

owns package-manager-invocation = `origin-routed: rustup components through Cargo
subcommands; every selected externally provisioned tool through its documented
bare binary on PATH`.

assumes rust-edition = `2024`.

assumes msrv-policy = `stable minus 2 minor versions, raised only in a minor
release, declared as rust-version in Cargo.toml and tested in CI`.

assumes target-os-matrix = `ubuntu-latest, macos-latest`.

assumes license = `MIT OR Apache-2.0`.

No `CONFLICT:` line: R42 does not set R27's toolchain channel or select any
external tool.

### Migration implications

1. Add `rust-toolchain.toml` with R27's channel plus `rustfmt` and `clippy`
components; do not derive that channel from `rust-version`.
2. Update `Makefile` F180 bootstrap validation for `rustup`, `cargo`, active
toolchain, and components; retain the bootstrap/task split but do not claim Make
is Rust's only possible bootstrap entry point.
3. Update `Justfile`: Rust checks use `cargo fmt`/`cargo clippy`; `check-deps`
audits only external commands; add each `install-<tool>` only when its owner has
selected it, with a matching `-force` recipe and shared verified-download helper.
4. Update `lefthook.yml`: Cargo-managed checks use Cargo subcommands; external
checks use their binary names on `PATH` after the readiness check.
5. Do not create `mise.toml`, `.flox/env/manifest.toml`, a Flox lockfile, or a
`cargo-binstall` bootstrap path.

### Validation strategy

**Planned, not executed.** Create the realistic CLI + library + web-service
workspace with the committed `rust-toolchain.toml`, then run the following on clean
`ubuntu-latest` and `macos-latest` CI runners:

```sh
rustup show active-toolchain
rustup component list --installed
cargo fmt --check
cargo clippy --workspace --all-targets --all-features -- -D warnings
just check-deps
lefthook run pre-commit
```

Expected behavior: the active channel is the repository channel; both components
are installed; Cargo commands are the invocations observed in the recipe/hook;
and `check-deps` reports no missing selected external binary. In an inverse
control, remove one selected external binary and expect its dependent hook and
`check-deps` to fail with exactly one `install-<tool>` remediation. Re-run its
installer and expect success. Replace its expected SHA-256 with a wrong value and
expect a failure before installation. These checks measure setup outcome, command
routing, OS artifacts, and integrity behavior; they do not claim a performance
benchmark.

### Confidence & re-verify trigger

High confidence in rustup/Cargo routing and in omitting dual declarative
provisioners for the current narrow Rust tool surface. Medium confidence in the
future external-installer details because R27--R29, R32, R37, R39, and R40 have
not selected the commands. Re-verify this report when any of those items selects
a non-Rust tool, when R27 selects the toolchain channel/components, when an
external vendor changes a release/checksum mechanism, or if an owner requires a
locked whole-environment manager. The proposed commands have not been run because
the repository intentionally has no Rust code yet.

### Sources

All URLs in this report were retrieved 2026-09-05. Primary sources: [Rustup
book](https://rust-lang.github.io/rustup/), [Cargo command
reference](https://doc.rust-lang.org/cargo/commands/index.html), [Tokio
CI](https://github.com/tokio-rs/tokio/blob/master/.github/workflows/ci.yml),
[actionlint README](https://github.com/rhysd/actionlint), [mise
documentation](https://mise.jdx.dev/configuration.html), [Flox
documentation](https://github.com/flox/flox), and [cargo-binstall
maintainer README](https://github.com/cargo-bins/cargo-binstall). **Method notes:**
queried `GET https://crates.io/api/v1/crates/cargo-binstall`,
`GET https://crates.io/api/v1/crates/cargo-binstall/versions`,
`GET https://api.github.com/repos/cargo-bins/cargo-binstall`, and
`GET https://api.github.com/search/issues?q=repo:cargo-bins/cargo-binstall+is:issue+is:open`
on 2026-09-05. The ten-most-recent-issues responsiveness request was blocked by
GitHub HTTP 403; the RustSec package URL returned HTTP 404. Neither endpoint
failure was converted into a favorable safety or responsiveness claim.
