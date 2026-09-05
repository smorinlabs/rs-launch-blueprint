### Landscape

Category: authored-Rust safety-boundary policy. The field separates into: **built-in/first-party toolchain** — rustc's `unsafe_code` lint at `deny` or `forbid`, Cargo workspace lint inheritance, Rust 2024's explicit unsafe-block rule, and Clippy's `undocumented_unsafe_blocks`; **established industry standard** — keep unsafe operations small and state the invariant immediately before the block with `// SAFETY:`; **up-and-comer** — dependency-tree reporting such as `cargo-geiger`. The last is not an enforcement mechanism for authored code and is outside R06's dependency-audit scope. Rustc documents that `unsafe_code` covers unsafe code and related unsound constructs, and Cargo documents the workspace lint table and uses `unsafe_code = "forbid"` as its own example. [rustc lint listing](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code), [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-05).

Authorities are deliberately diverse. The Rust Project's rustc and Cargo references are normative for lint semantics and manifest inheritance; the Rust API Guidelines are community-maintained guidance for public Rust APIs; and the Clippy documentation is the maintained specification for its lint's exact comment recognition. [Rust API Guidelines: unsafety](https://rust-lang.github.io/api-guidelines/unsafety.html), [Clippy `undocumented_unsafe_blocks`](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks) (retrieved 2026-09-05).

Practice evidence is directional, not a claim of a statistical majority. `clap_builder`, the library behind the widely used CLI framework, declares `#![forbid(unsafe_code)]` at its crate root; GitHub reported 16,685 stars, Apache-2.0 licensing, `archived: false`, and a 2026-09-02 push. `axum`, a prominent web framework, reported 27,025 stars, MIT licensing, `archived: false`, and a 2026-09-04 push; its public crate root has no `unsafe_code` crate attribute, illustrating that a framework with low-level scope need not make the same choice as this safe-by-construction template. [clap source](https://github.com/clap-rs/clap/blob/master/clap_builder/src/lib.rs), [clap GitHub endpoint](https://api.github.com/repos/clap-rs/clap), [axum source](https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs), [axum GitHub endpoint](https://api.github.com/repos/tokio-rs/axum) (retrieved 2026-09-05). The Rust CLI Working Group's book remains an authoritative CLI-design reference but does not prescribe an unsafe-policy attribute, so it is not evidence for either policy. [Command Line Applications in Rust](https://rust-cli.github.io/book/) (retrieved 2026-09-05).

Crate figures — 90-day and all-time downloads, release date, RustSec advisories, reverse dependencies, and issue responsiveness — are **inapplicable**: the candidates are compiler/linter policy patterns bundled with the Rust toolchain, not independently versioned crate dependencies. The required crates.io, RustSec, and GitHub issue-search endpoints therefore cannot truthfully supply candidate figures.

### Principles and implementation

The shared requirement is a Rust-only safety boundary: authored template code must make any escape from Rust's static memory-safety rules both intentional and reviewable. Its agreement level is a **repo-wide policy**, not a cross-language mechanism: F023 is `RUST-ONLY`, and the prompt records no Python or TypeScript analogue. The principle remains appropriate because Rust's `unsafe` construct transfers proof obligations to the author; Rust 2024 additionally requires explicit unsafe blocks inside `unsafe fn`, which narrows review to the actual operation. [Rust Reference: unsafe functions](https://doc.rust-lang.org/reference/unsafe-functions.html), [RFC 2585](https://rust-lang.github.io/rfcs/2585-unsafe-block-in-unsafe-fn.html) (retrieved 2026-09-05).

Compare two architectures before selecting a mechanism. A hard boundary uses inherited `unsafe_code = "forbid"`: it rejects every authored unsafe operation and cannot be lowered by a nested `allow`. A governed exception boundary uses `unsafe_code = "deny"`, permits a deliberate local `allow`, and pairs that with Clippy's `undocumented_unsafe_blocks = "deny"`; Clippy requires a directly preceding `// SAFETY:` explanation for unsafe blocks and unsafe impls. Rustc specifies the non-overridable property of `forbid`; Clippy specifies the comment placement and the lint's restriction-group default of `allow`. [rustc lint levels](https://doc.rust-lang.org/rustc/lints/levels.html#forbid), [Clippy lint documentation](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks) (retrieved 2026-09-05).

Choose the hard boundary for the generated baseline. The proposed root manifest has `[workspace.lints.rust] unsafe_code = "forbid"`; every future member opts in with `[lints] workspace = true`. This is uniform across core/library, CLI, and web crates, while leaving R02 free to decide their topology. Cargo's reference both documents the inheritance mechanism and shows this exact lint setting. [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-05).

Essential observable behavior: a committed `unsafe { ... }`, `unsafe fn`, unsafe impl, or unsafe linkage attribute in an opted-in member makes `cargo check --workspace` fail; no dependency's internal unsafe code is diagnosed because lint attributes apply while compiling the current crate, not source inside already-selected dependency crates. The first behavior is documented by rustc's `unsafe_code` lint; the dependency distinction is an inference from Cargo compiling package targets separately and must be confirmed by the acceptance fixture below. [rustc `unsafe_code`](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code), [Cargo targets](https://doc.rust-lang.org/cargo/reference/cargo-targets.html) (retrieved 2026-09-05).

Minimal realistic example (proposed, not executed): a workspace with library `blueprint-core`, binary `blueprint-cli`, and web binary `blueprint-web`; all three inherit the root lint. A test-only unsafe block in `blueprint-core` must fail compilation. Replacing it with a safe standard-library operation must pass check, test, and clippy on Ubuntu and macOS. There is no performance-sensitive runtime path, async-runtime coupling, extra binary-size cost, or measurable compile-time cost beyond ordinary rustc/Clippy lint evaluation.

### Dominant choice

**Forbidden authored unsafe code, enforced through inherited Cargo workspace lint configuration:** `[workspace.lints.rust] unsafe_code = "forbid"`, with `[lints] workspace = true` in every workspace member. `forbid` is selected over `deny` because the template itself has no identified unsafe requirement; a later adopter must consciously change the policy rather than hiding an exception in a module. [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table), [rustc lint levels](https://doc.rust-lang.org/rustc/lints/levels.html#forbid) (retrieved 2026-09-05).

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
|---|---|---|---|
| Hard ban: `unsafe_code = "forbid"` | [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table); [rustc levels](https://doc.rust-lang.org/rustc/lints/levels.html#forbid) | `clap_builder` uses `#![forbid(unsafe_code)]`; it is a maintained CLI-library reference (16,685 GitHub stars; unarchived). [source](https://github.com/clap-rs/clap/blob/master/clap_builder/src/lib.rs), [endpoint](https://api.github.com/repos/clap-rs/clap) | Cargo reference retrieved 2026-09-05 |
| Governed exception: `unsafe_code = "deny"` plus `clippy::undocumented_unsafe_blocks = "deny"` | [rustc `unsafe_code`](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code); [Clippy lint](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks) | Clippy's own documentation demonstrates the `// SAFETY:` form; no maintained CLI/library/web template reference with this complete workspace policy was verified in this run. | Clippy documentation retrieved 2026-09-05 |
| Per-crate manual crate-root attributes | [rustc attribute/lint levels](https://doc.rust-lang.org/rustc/lints/levels.html) | `clap_builder` demonstrates the crate-root form. [source](https://github.com/clap-rs/clap/blob/master/clap_builder/src/lib.rs) | rustc reference retrieved 2026-09-05 |

### Excluded by gate

No policy pattern is excluded by a license, advisory, download, release, or dependency-tree gate: those are **inapplicable** to first-party rustc/Cargo/Clippy configuration rather than a crate dependency. Both viable configurations require Cargo workspace lint inheritance (Cargo documents MSRV 1.64) and the selected declared MSRV must therefore remain at least 1.64; this is compatible in principle with the owner-fixed moving `stable minus 2 minor versions` policy, but the exact minimum toolchain was not executed in this run. [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-05).

Their unsafe posture is explicit: `forbid` rejects unsafe code, while `deny` permits an explicitly allowed exception. Neither has default features, async-runtime coupling, binary-size cost, or material compile-time cost beyond native linting; all are **inapplicable** because they are toolchain policy rather than linkable libraries. The mechanisms are expected to operate under `ubuntu-latest` and `macos-latest` wherever the selected stable Rust toolchain runs, but that OS claim remains unverified until R28 wires and executes the two CI lanes.

`cargo-geiger`-style dependency inspection is excluded by scope, not a failed fitness gate: it answers whether dependencies contain unsafe code, whereas R06 governs authored template code. The prompt assigns dependency-tree audit tooling to R13.

### Up-and-comers

`cargo-geiger` and similar unsafe-usage reporting tools are up-and-comers for supply-chain visibility, not replacements for a crate-local compiler lint. Their value is a separate dependency review; they cannot make a local `unsafe` operation fail compilation or require an invariant explanation. The recommended policy therefore does not depend on them. [cargo-geiger repository](https://github.com/geiger-rs/cargo-geiger) (retrieved 2026-09-05).

### Fit for this template

**CLI:** command parsing, file I/O, formatting, and HTTP clients can be expressed in safe Rust, so a ban keeps the generated executable's safety claim simple. `clap_builder` is relevant production evidence for this posture. [clap source](https://github.com/clap-rs/clap/blob/master/clap_builder/src/lib.rs) (retrieved 2026-09-05).

**Library:** the library is the most important boundary to keep safe for downstream callers. A future FFI, zero-copy, or platform integration need is a policy-change event and should arrive with a narrowly scoped design and tests, rather than a local lint suppression. Rust's `forbid` semantics make that event impossible to hide in a child module. [rustc lint levels](https://doc.rust-lang.org/rustc/lints/levels.html#forbid) (retrieved 2026-09-05).

**Web:** the template can use a safe application layer; `axum` is a maintained ecosystem reference for that layer, although it does not itself prove a hard-ban policy. The workspace policy regulates only code generated and maintained by this template, not dependencies chosen by its web front end. [axum source](https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs), [axum endpoint](https://api.github.com/repos/tokio-rs/axum) (retrieved 2026-09-05).

### Recommendation

Adopt the named pattern **safe-authoring hard boundary**: forbid unsafe code uniformly in every authored workspace crate with the root Cargo lint table. Do not add a `// SAFETY:` convention or `clippy::undocumented_unsafe_blocks` to the baseline because a correctly inherited `forbid` makes those constructs unreachable; adding a documentation rule for forbidden code creates a misleading implied exception path. If an adopter later demonstrates a necessary unsafe integration, change the policy in a reviewed change to the runner-up and require per-block `// SAFETY:` explanations plus public `unsafe fn` `# Safety` documentation. [Clippy `undocumented_unsafe_blocks`](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks), [Clippy `missing_safety_doc`](https://rust-lang.github.io/rust-clippy/master/index.html#missing_safety_doc) (retrieved 2026-09-05).

### Ranked runner-up

**Governed exception boundary:** set `unsafe_code = "deny"`, `clippy::undocumented_unsafe_blocks = "deny"`, and `clippy::missing_safety_doc = "deny"`; every exception needs a directly preceding `// SAFETY:` comment, and every public `unsafe fn` needs a `# Safety` documentation section. It wins only when the template deliberately owns a demonstrated unsafe capability (for example, FFI or a platform primitive) that cannot be expressed safely and must remain part of the supported baseline. [Clippy `undocumented_unsafe_blocks`](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks), [Clippy `missing_safety_doc`](https://rust-lang.github.io/rust-clippy/master/index.html#missing_safety_doc) (retrieved 2026-09-05).

### Tradeoffs

The hard boundary gives up a local escape hatch. That cost is accepted because it forces a fork or template-policy change to be reviewed at the correct scope, rather than letting a single module normalize unsafe code. Compared with the governed-exception runner-up, it also gives up the ability to carry a justified FFI optimization without reconfiguration; that is acceptable because no such capability belongs to the initial CLI/library/web-service template. Compared with per-crate manual attributes, workspace inheritance gives up a little per-crate freedom in exchange for preventing topology-dependent policy drift. [rustc lint levels](https://doc.rust-lang.org/rustc/lints/levels.html#forbid), [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-05).

### Parameters

owns unsafe-code-policy = `forbid-authored-unsafe-workspace-wide`.

assumes rust-edition = `2024`.

assumes msrv-policy = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`.

assumes license = `MIT OR Apache-2.0`.

assumes target-os-matrix = `ubuntu-latest, macos-latest`.

No `CONFLICT:` line: no consumed parameter needs a changed value. R02 owns workspace topology; R28 owns how the named Cargo/Clippy checks reach hooks and CI.

### Migration implications

When implementation begins, add the root `Cargo.toml` `[workspace.lints.rust]` table with `unsafe_code = "forbid"`. In each generated member manifest — exact paths depend on R02 — add `[lints] workspace = true`. Add a short `CONTRIBUTING.md` policy paragraph: authored unsafe code is forbidden; a capability that would need it requires a reviewed policy change. Do not put duplicate `#![forbid(unsafe_code)]` crate attributes in generated sources unless R02 intentionally declines workspace lint inheritance; the manifest mechanism is the single source of truth. [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table) (retrieved 2026-09-05).

### Validation strategy

Planned acceptance fixture after R02 creates members and R28 wires lint execution:

```sh
# expected: clean build of all safe template crates
cargo check --workspace
cargo test --workspace
cargo clippy --workspace --all-targets -- -D warnings

# expected: compilation failure attributed to unsafe_code
printf '\nunsafe { std::hint::unreachable_unchecked() };\n' >> crates/blueprint-core/src/lib.rs
cargo check -p blueprint-core
```

Run the first three commands and the negative control in the `ubuntu-latest` and `macos-latest` lanes. The negative control must fail even if the fixture adds `#[allow(unsafe_code)]` inside the crate; the inverse safe fixture must pass. Restore the fixture only through the test harness, not a manual post-check edit. These checks are proposed and were not executed because this repository intentionally contains no Rust code yet. Rustc documents the failing lint behavior, and Rust 2024 documents the explicit-block safety model. [rustc `unsafe_code`](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code), [RFC 2585](https://rust-lang.github.io/rfcs/2585-unsafe-block-in-unsafe-fn.html) (retrieved 2026-09-05).

### Confidence & re-verify trigger

Confidence: high for the hard-boundary semantics and Cargo configuration; medium for the long-term default because no generated Rust workspace exists yet and the comparable-template survey did not establish a numerical majority. Re-verify when R02 chooses a topology, when R28 selects its minimum toolchain and CI command line, or before adding FFI, raw OS bindings, SIMD/intrinsics, custom allocation, or another capability that demonstrably requires unsafe code. Re-verify Clippy lint availability at the declared MSRV before adopting the runner-up. [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table), [Clippy lint documentation](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks) (retrieved 2026-09-05).

### Sources

- Rust Project: [rustc lint levels](https://doc.rust-lang.org/rustc/lints/levels.html), [rustc `unsafe_code` lint](https://doc.rust-lang.org/rustc/lints/listing/allowed-by-default.html#unsafe-code), [Cargo workspace lints](https://doc.rust-lang.org/cargo/reference/workspaces.html#the-lints-table), [Rust Reference unsafe functions](https://doc.rust-lang.org/reference/unsafe-functions.html), and [RFC 2585](https://rust-lang.github.io/rfcs/2585-unsafe-block-in-unsafe-fn.html), retrieved 2026-09-05.
- Rust community guidance: [Rust API Guidelines unsafety](https://rust-lang.github.io/api-guidelines/unsafety.html), [Clippy `undocumented_unsafe_blocks`](https://rust-lang.github.io/rust-clippy/master/index.html#undocumented_unsafe_blocks), and [Clippy `missing_safety_doc`](https://rust-lang.github.io/rust-clippy/master/index.html#missing_safety_doc), retrieved 2026-09-05.
- Practice references: [clap source](https://github.com/clap-rs/clap/blob/master/clap_builder/src/lib.rs) and [GitHub endpoint](https://api.github.com/repos/clap-rs/clap); [axum source](https://github.com/tokio-rs/axum/blob/main/axum/src/lib.rs) and [GitHub endpoint](https://api.github.com/repos/tokio-rs/axum); [Rust CLI book](https://rust-cli.github.io/book/); [cargo-geiger repository](https://github.com/geiger-rs/cargo-geiger), retrieved 2026-09-05.

Method notes: queried the Rust Project documentation endpoints above, the Clippy and API-Guidelines documentation endpoints, raw GitHub source URLs, and GitHub REST `GET https://api.github.com/repos/clap-rs/clap` and `GET https://api.github.com/repos/tokio-rs/axum` on 2026-09-05. Crate figures and RustSec endpoints were not queried because no crate is selected; GitHub's required issue-search endpoint was not used for the same pattern-level reason. No Rust workspace, OS-lane check, or MSRV check exists yet, so those acceptance results remain unverified.
