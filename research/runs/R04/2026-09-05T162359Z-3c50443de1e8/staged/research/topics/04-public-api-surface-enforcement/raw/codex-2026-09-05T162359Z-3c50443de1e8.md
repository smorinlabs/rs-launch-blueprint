# R04 — Public API surface enforcement

### Landscape

**Category.** This item is an API-boundary policy: how a Rust library makes its
documented, curated root API the only API an external crate can name. The
landscape is:

| Bin | Candidate | What it enforces | Evidence |
|---|---|---|---|
| Built-in / first-party | Private root modules plus root-level `pub use`; `pub(crate)` for crate-only names; `#![deny(unreachable_pub)]` | The compiler rejects a downstream path whose module ancestry is not public; the lint rejects accidentally-public but unreachable implementation items. | [Rust Reference: visibility](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05; [rustc `unreachable_pub` lint](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#unreachable-pub), retrieved 2026-09-05 |
| Built-in / first-party | Public `pub mod` hierarchy plus a root barrel | Documents a preferred root path but does **not** prevent consumers from naming the public module path. | [Rust Reference: public items require public ancestors](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05 |
| Established industry standard | A downstream compile-fail fixture that imports a deliberately private module | Tests the externally observable property on the same compiler and target platform used by consumers. | [Cargo integration-test guidance](https://doc.rust-lang.org/book/ch11-03-test-organization.html#integration-tests), retrieved 2026-09-05; [Rust Reference: visibility](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05 |
| Established industry standard | `cargo-semver-checks` on release-boundary changes | Detects supported SemVer-breaking changes against a prior published or revision baseline; it is not an allow-list for additive exports. | [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md), retrieved 2026-09-05; [Cargo SemVer compatibility](https://doc.rust-lang.org/cargo/reference/semver.html), retrieved 2026-09-05 |
| Up-and-comer | `cargo-public-api` snapshot/diff | Lists and diffs rustdoc-derived public API, including an assertion/snapshot workflow, but its current documented operation requires a nightly toolchain. | [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md), retrieved 2026-09-05 |

The Rust Reference is the controlling language authority because it specifies
privacy and public re-exports. Cargo's SemVer reference is the first-party
authority for what constitutes a public compatibility commitment. The two tool
READMEs are authoritative only for their respective tools, not for the
language rule. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
[Cargo SemVer reference](https://doc.rust-lang.org/cargo/reference/semver.html),
and [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md),
all retrieved 2026-09-05.

Practice evidence supports the language-level design. `rustls` keeps many
implementation modules private and makes selected root re-exports in its
maintained `lib.rs`; it is a relevant security-sensitive library, with
194,242,193 recent downloads and 7,596 GitHub stars at the queried endpoints.
[rustls `lib.rs`](https://github.com/rustls/rustls/blob/main/rustls/src/lib.rs),
[crates.io API](https://crates.io/api/v1/crates/rustls), and
[GitHub repository API](https://api.github.com/repos/rustls/rustls), retrieved
2026-09-05. This is evidence that the constituent pattern is production-used,
not evidence that `rustls` promises a root-only namespace.

Crate-download, release, RustSec, issue-response, and repository-health figures
are **inapplicable to the dominant boundary mechanism** because it adds no
crate. They are not silently treated as zero. The optional tools are evaluated
only where their capabilities matter below; their popularity does not select
the architecture.

### Principles and implementation

The shared requirement is the **architectural pattern** in F014: consumers get
one deliberate, stable library surface. F014 is retained as a curated `lib.rs`
re-export list; R04 decides the separate F015 enforcement mechanism. [R04
prompt](../inputs/prompt.md) and [Rust `pub use` reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

Rust can make this property non-bypassable at compile time. An external crate
can name a public item only when every ancestor module is accessible; a private
root module blocks that path. A public re-export at `crate::Name` is the
intentional exception that grants access without publishing the implementation
module path. [Rust Reference: visibility and re-exports](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05. Therefore the reference shape is:

```rust
// src/lib.rs
#![deny(unreachable_pub)]

mod config;
mod errors;
mod service;

pub use config::Config;
pub use errors::Error;
pub use service::run;
```

Items selected for re-export must be `pub`, even inside a private module;
`pub(crate)` cannot be widened into a public re-export. Use `pub(crate)` for
cross-module implementation names, and leave single-module helpers private.
This gives one root declaration point while preserving ordinary internal module
organization. [Rust Reference: restricted visibility](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

The essential acceptance behaviors are: `use rs_launch_blueprint::Config`
compiles; `use rs_launch_blueprint::config::Config` fails in a distinct
downstream crate; an otherwise unreachable `pub` item fails due to
`unreachable_pub`; and a reviewed root `pub use` is the only route that adds a
consumer-visible name. The first three are compiler-enforced; review of a
deliberate root re-export remains a human policy decision. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

This differs appropriately from TypeScript's resolver-level exports map. Rust
does not need a packaging metadata analogue when the compiler's visibility graph
already makes inaccessible paths ill-formed. A root barrel combined with public
submodules would reproduce Python's convention-only outcome, so it is not
equivalent. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

`cargo public-api` can make a full public-API snapshot, but its maintained
README currently requires nightly rustdoc JSON. `cargo-semver-checks` supports
stable operation and is valuable once a release baseline exists, but additions
are normally SemVer-compatible and it is not a root-export allow-list. [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md)
and [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md),
retrieved 2026-09-05.

The minimal realistic example is a library used by both a CLI binary and an
optional web adapter: both import only `rs_launch_blueprint::{Config, Error,
run}`, while private modules contain their implementation. A maintained
reference for private implementation modules and selected root re-exports is
`rustls`. [rustls `lib.rs`](https://github.com/rustls/rustls/blob/main/rustls/src/lib.rs),
retrieved 2026-09-05. Proposed acceptance is the downstream fixture in
`Validation strategy`; it was not run because this research repository has no
Rust template crate.

BASELINE-REVIEW: F014 — one curated public library surface — retain the settled `lib.rs` root re-export pattern; Rust visibility supplies mechanical enforcement for F015 — [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05.

### Dominant choice

**Root-only visibility facade:** declare implementation modules with private
`mod` in `src/lib.rs`, expose only selected `pub use` names at that root, use
`pub(crate)` for crate-internal sharing, deny `unreachable_pub`, and retain a
downstream negative-compilation fixture. This is compiler enforcement, not a
convention or a third-party snapshot. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
and [rustc lint documentation](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#unreachable-pub),
retrieved 2026-09-05.

### Options

| Name | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| Root-only visibility facade | [Rust visibility reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html) | [rustls](https://github.com/rustls/rustls/blob/main/rustls/src/lib.rs) uses private modules and selected root re-exports; its queried adoption figures are reported in `Landscape`. | Rust Reference, retrieved 2026-09-05 |
| `cargo-semver-checks` release gate | [maintainer README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md) | The project uses its maintained GitHub Action in its own CI; this is a tool-maintainer reference, not independent adoption evidence. | README, retrieved 2026-09-05 |
| `cargo-public-api` snapshot/diff | [maintainer README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md) | The README provides a maintained snapshot assertion example; independent adoption was not verified. | README, retrieved 2026-09-05 |

### Excluded by gate

`cargo-public-api` is excluded as a required gate: its current documentation
requires nightly rustdoc JSON, which conflicts with this prompt's stable-Rust
constraint. Its crates.io endpoint reported version `0.52.0` released
2026-05-25; its GitHub endpoint reported 573 stars, not archived, and pushed
2026-09-04. Those figures support current maintenance only and do not cure the
nightly gate failure. [README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md),
[crates.io versions API](https://crates.io/api/v1/crates/cargo-public-api/versions),
and [GitHub repository API](https://api.github.com/repos/cargo-public-api/cargo-public-api),
retrieved 2026-09-05.

A public `pub mod implementation;` plus a root barrel is excluded because an
external consumer can name any public descendant through that module path; it
does not meet the non-bypassable criterion. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

### Up-and-comers

`cargo-public-api` is the relevant future option if the project later permits a
pinned nightly auxiliary toolchain. It can diff and snapshot the public API,
including intentional additive changes, which is more complete drift reporting
than a compile-fail fixture. Its current nightly dependency makes it unsuitable
as R04's required stable gate. [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md),
retrieved 2026-09-05.

### Fit for this template

**CLI.** The binary is in the same workspace and may use internal
`pub(crate)` composition helpers without exporting them to library consumers;
its public library use should exercise the root facade. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

**Library.** This is the primary fit: private ancestor modules make every
unreexported implementation path unnameable downstream, while a root `pub use`
is explicit and reviewable. The zero-runtime-cost language rule has no
additional binary-size, compile-time, default-feature, async-runtime, or
platform coupling. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

**Web.** The optional web adapter can depend on the library's root API and
keep framework-specific modules private or feature-gated; R04 does not choose
the web crate or topology. Cargo optional dependencies are disabled until their
feature is enabled. [Cargo features reference](https://doc.rust-lang.org/cargo/reference/features.html#optional-dependencies),
retrieved 2026-09-05.

For either R02 topology, a single public crate uses the facade above. A
workspace-internal crate should set `publish = false` to prevent accidental
publication, but that is a distribution safeguard, not the API boundary: a
published public crate still controls its own external names through visibility
and re-exports. [Cargo manifest `publish`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-publish-field)
and [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

### Recommendation

Adopt the **root-only visibility facade** as R04's named pattern. Require
private root modules, explicit root `pub use` exports, `pub(crate)` for
cross-module internals, `#![deny(unreachable_pub)]`, and one downstream
deep-import rejection fixture in CI on Ubuntu and macOS. This meets the
non-bypassable requirement with stable Rust and no added dependency. [Rust
Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html) and
[rustc lint documentation](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#unreachable-pub),
retrieved 2026-09-05.

Do not require `cargo-public-api`. Add `cargo-semver-checks` only to the
release process after a published baseline exists, as a complementary breaking-
change detector rather than an export allow-list. [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md),
retrieved 2026-09-05.

### Ranked runner-up

`cargo-semver-checks` is the runner-up **only after the first public release**
and only as a release gate. It wins if the objective becomes preventing
unintentional SemVer-breaking changes between published versions, rather than
preventing deep imports or rejecting all additions. Its queried crates.io
endpoint reported version `0.50.0` released 2026-08-01; the GitHub endpoint
reported 1,675 stars, not archived, and pushed 2026-08-29. [README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md),
[crates.io versions API](https://crates.io/api/v1/crates/cargo-semver-checks/versions),
and [GitHub repository API](https://api.github.com/repos/obi1kenobi/cargo-semver-checks),
retrieved 2026-09-05.

### Tradeoffs

The dominant choice does not automatically reject an intentional new root
`pub use`; that remains visible code review plus normal diff review. A nightly
`cargo-public-api` snapshot would report every API delta, but the stable-only
constraint outweighs that additional reporting. [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md),
retrieved 2026-09-05.

`cargo-semver-checks` adds release compatibility coverage, but it neither
proves a private path is inaccessible nor treats every additive API change as a
failure. The fixture and language visibility rule cover the first property;
review owns the second. [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md)
and [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

### Parameters

No owned or consumed registered parameter applies. No `CONFLICT:` line is
emitted: the recommendation preserves edition 2024, the declared MSRV policy,
the dual license, and Ubuntu/macOS CI without adding a crate or toolchain.
[R04 prompt](../inputs/prompt.md), retrieved 2026-09-05.

### Migration implications

When implementation begins, create `src/lib.rs` as the only public facade;
declare implementation files such as `src/config.rs`, `src/errors.rs`, and
`src/service.rs` with private `mod` declarations there; write only approved
`pub use` lines in `src/lib.rs`; and add `#![deny(unreachable_pub)]` at the
crate root. Add `tests/fixtures/deep-import/Cargo.toml` and
`tests/fixtures/deep-import/src/main.rs` for the negative downstream consumer,
plus a CI script or test that expects its `cargo check` to fail. These are
proposed template changes, not changes made in this research run. [Rust
Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

If R02 selects a separate internal crate, set that package's `publish = false`
and do not re-export its implementation namespace from the public crate. This
does not decide R02's topology. [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-publish-field),
retrieved 2026-09-05.

### Validation strategy

The following are **planned checks**, not executed results; the template crate
does not exist in this research repository.

```sh
# Repository root, on Ubuntu and macOS CI.
cargo check --workspace --all-targets
cargo test --workspace

# A fixture whose src/main.rs contains:
# use rs_launch_blueprint::config::Config;
# This must fail; success means a private implementation path leaked.
if cargo check --manifest-path tests/fixtures/deep-import/Cargo.toml; then
  echo 'deep import unexpectedly compiled' >&2
  exit 1
fi
```

Expected result: the workspace checks pass, the ordinary integration test can
import root names, and the fixture fails with a privacy/module-access error.
The compiler applies the same public-ancestor rule on both required CI OSes;
there is no runtime workload, latency, throughput, resource, binary-size, or
async-runtime cost to benchmark for this language feature. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html),
retrieved 2026-09-05.

After the first release, additionally run `cargo semver-checks` against the
previous release or explicit baseline on release candidates. It should fail for
detected breaking public API changes, but it must not be presented as a complete
snapshot or as the deep-import test. [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md),
retrieved 2026-09-05.

### Confidence & re-verify trigger

Confidence is high for the language-level guarantee because it follows the Rust
Reference's explicit public-ancestor and re-export rules. Confidence is medium
for the future release-gate choice because `cargo-semver-checks` and rustdoc JSON
compatibility evolve. Re-verify if R02 chooses a multi-crate topology, if the
project permits a pinned nightly CI toolchain, if the public crate gains
target-specific exports, or before adding a release gate. [Rust Reference](https://doc.rust-lang.org/reference/visibility-and-privacy.html)
and [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md),
retrieved 2026-09-05.

### Sources

- [Rust Reference — Visibility and privacy](https://doc.rust-lang.org/reference/visibility-and-privacy.html), retrieved 2026-09-05.
- [rustc lint listing — `unreachable_pub`](https://doc.rust-lang.org/rustc/lints/listing/warn-by-default.html#unreachable-pub), retrieved 2026-09-05.
- [Cargo manifest reference — `publish`](https://doc.rust-lang.org/cargo/reference/manifest.html#the-publish-field), retrieved 2026-09-05.
- [Cargo features reference](https://doc.rust-lang.org/cargo/reference/features.html#optional-dependencies), retrieved 2026-09-05.
- [Cargo SemVer compatibility reference](https://doc.rust-lang.org/cargo/reference/semver.html), retrieved 2026-09-05.
- [rustls root library source](https://github.com/rustls/rustls/blob/main/rustls/src/lib.rs), retrieved 2026-09-05.
- [cargo-public-api README](https://github.com/cargo-public-api/cargo-public-api/blob/main/README.md), retrieved 2026-09-05.
- [cargo-semver-checks README](https://github.com/obi1kenobi/cargo-semver-checks/blob/main/README.md), retrieved 2026-09-05.
- [R04 binding prompt](../inputs/prompt.md), retrieved 2026-09-05.

Method notes: queried `GET https://crates.io/api/v1/crates/{cargo-public-api,cargo-semver-checks,rustls}` and each selected tool's `/versions` endpoint, plus `GET https://api.github.com/repos/{cargo-public-api/cargo-public-api,obi1kenobi/cargo-semver-checks,rustls/rustls}` on 2026-09-05. The unauthenticated GitHub search endpoint rate-limited before a reliable `cargo-semver-checks` open-issue count or either tool's ten-issue response median could be collected; RustSec's requested package URLs returned GitHub Pages “Page not found,” so open-advisory status was not verified. These unverified tool figures do not affect the no-dependency dominant choice; `cargo-public-api` is excluded by its documented nightly requirement.
