Actor: `research-codex-2026-09-05T160304Z-5cba7fe96ae4`
Item: `R46` (`per-file-license-header`)
Retrieved: 2026-09-05

### Landscape

Category decided: source-file licensing metadata for Rust source files. The
choice is a repository pattern, not a runtime crate. Crate download, release,
RustSec, issue-response, binary-size, and compile-time figures are therefore
inapplicable to the dominant pattern itself; the tool candidates below are
implementation evidence, not runtime dependencies of the template.

Three-bin survey:

| Bin | Candidates found | What the candidate means here |
|---|---|---|
| Built-in or first-party toolchain | Cargo package metadata plus root `LICENSE-APACHE` and `LICENSE-MIT`; ordinary Rust `//` and `//!` comments | Cargo records the package expression; Rust itself has no built-in per-file license-header policy or checker. |
| Established industry standard | SPDX short-form identifier; REUSE comment header and `reuse lint`; legacy full-text license block | SPDX supplies machine-readable file-level identification. REUSE adds copyright metadata, license files, and an auditable checker. Full-text blocks are a convention, not a standard required by Cargo. |
| Up-and-comer | `file_header`, `addlicense`, `licet`, and adjacent dependency-inventory tools such as `cargo-about` | These automate insertion, verification, or inventory, but they do not establish a Rust ecosystem requirement. `cargo-about` inventories dependency licenses; it does not decide the header on this repository's own files. |

Authority was established before practice was evaluated:

- The Rust API Guidelines are first-party ecosystem guidance for crate
  interoperability. Their C-PERMISSIVE guideline explicitly recommends
  `license = "MIT OR Apache-2.0"`, `LICENSE-APACHE`, and `LICENSE-MIT` in the
  repository root. ([Rust API Guidelines, C-PERMISSIVE](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved
  2026-09-05.)
- Cargo's maintained manifest reference is authoritative for what crates.io
  interprets. It says `license` is an SPDX 2.3 expression, gives
  `MIT OR Apache-2.0` as the example, and reserves singular `license-file` for
  a nonstandard license. ([Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved
  2026-09-05.)
- SPDX is the standards authority for identifiers and expressions. Its current
  handling guidance says a file can use one short-form line and that two or
  more applicable licenses use an expression; its copyright guidance keeps
  copyright notices conceptually separate from the license identifier.
  ([SPDX, Handling License Info](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [SPDX 2.3 expression
  syntax](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/), retrieved 2026-09-05.)
- REUSE is an industry compliance specification maintained by the Free
  Software Foundation Europe. It recommends comment headers, requires both a
  copyright notice and an SPDX expression for a covered commentable file, and
  provides `reuse annotate` and `reuse lint`. ([REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05; [REUSE
  tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05.)
- Rust's own repository is first-party practice evidence. Its `COPYRIGHT` says
  in-tree source licensing is tracked with REUSE and its committed
  `REUSE.toml`, while the repository uses path annotations for broad source
  trees rather than putting a visible header in every Rust file. ([Rust
  `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT), retrieved
  2026-09-05; [Rust `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml), retrieved 2026-09-05.)

Practice survey, weighted toward maintained, recognizable projects:

- Serde is an established Rust serialization framework with a public,
  maintained workspace, dual root license files, and `license = "MIT OR
  Apache-2.0"`; its representative `serde/src/lib.rs` begins with `//!`
  documentation and no license header. ([Serde repository](https://github.com/serde-rs/serde), retrieved 2026-09-05; [Serde
  manifest](https://raw.githubusercontent.com/serde-rs/serde/master/serde/Cargo.toml), retrieved 2026-09-05; [Serde
  `lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs), retrieved 2026-09-05.)
- Tokio is a maintained, foundational async Rust project with its own API
  documentation, guides, release policy, and supported-version policy. Its
  representative `tokio/src/lib.rs` begins with Rust attributes and no license
  header; the package manifest uses root license metadata rather than a
  per-file block. ([Tokio repository](https://github.com/tokio-rs/tokio), retrieved 2026-09-05; [Tokio
  `lib.rs`](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs), retrieved 2026-09-05; [Tokio
  manifest](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml), retrieved 2026-09-05.)
- Axum is maintained web-framework practice from the Tokio project. Its
  representative `axum/src/lib.rs` begins with `//!` documentation and no
  license header, while its manifest carries package license metadata.
  ([Axum repository](https://github.com/tokio-rs/axum), retrieved 2026-09-05; [Axum
  `lib.rs`](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs), retrieved 2026-09-05; [Axum
  manifest](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml), retrieved 2026-09-05.)
- Clap is maintained CLI practice and is explicitly dual licensed at the
  repository level, but its representative `clap_builder/src/lib.rs` retains
  a four-line MIT-only legacy header. That is evidence that full-text headers
  can drift from a later dual-license manifest; it is not a suitable template
  for the fixed dual expression. ([Clap repository](https://github.com/clap-rs/clap), retrieved 2026-09-05; [Clap
  manifest](https://raw.githubusercontent.com/clap-rs/clap/master/Cargo.toml), retrieved 2026-09-05; [Clap
  `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)
- OpenZeppelin's maintained Rust project template is directly relevant template
  evidence. Its setup checklist tells users to align `Cargo.toml` with the
  license files and its representative `src/lib.rs` begins with module docs,
  without a per-file license block. ([OpenZeppelin Rust project template](https://github.com/OpenZeppelin/rust-project-template), retrieved
  2026-09-05; [template README](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/README.md), retrieved
  2026-09-05; [template `src/lib.rs`](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/src/lib.rs), retrieved
  2026-09-05.)

The survey does not support the claim that Rust has converged on one universal
file-header rule. It does support a narrower conclusion: current Rust library,
web, CLI, and template examples commonly rely on Cargo metadata plus root
license files; the Rust Project uses REUSE for its larger compliance problem;
and full copied license text is a drift risk. The source-repository divergence
recorded for R46 therefore reflects a genuine policy choice, not a Rust
toolchain requirement. ([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05;
[Serde `lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs), retrieved 2026-09-05; [Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)

### Principles and implementation

Shared requirement: every distributable work must have unambiguous, discoverable
license metadata, and the declared license must match the license texts shipped
with the repository. This is a policy-level agreement across the three
blueprints. It is not agreement that every source file must carry identical
boilerplate. The py full-text block, the incomplete ts SPDX conversion, and the
Rust choice can vary at the mechanism level if they preserve the policy and
remain auditable. The fixed Rust parameter is `MIT OR Apache-2.0`, so no source
file may claim only MIT as the repository-wide license. ([Cargo manifest
reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05.)

Essential behaviors and acceptance criteria:

- The workspace manifest declares exactly `license = "MIT OR Apache-2.0"`.
- The root contains `LICENSE-MIT` and `LICENSE-APACHE`, each containing the
  corresponding complete license text.
- No `.rs` file is required to repeat a license text or SPDX marker. If a file
  has a different origin or license, that exception must be made explicit in a
  targeted metadata mechanism before it is shipped.
- A check must fail if the manifest expression changes, either root license
  file disappears, or a newly added repository-owned source file reintroduces
  the rejected legacy full-text/MIT-only header pattern.
- A crate-level `//!` module or crate documentation comment remains the first
  Rust documentation element in files that need it.

The main alternatives are materially different architectures:

1. Root-only Cargo metadata is a zero-dependency repository policy. Cargo and
   crates.io understand the expression; the two root files carry the legal
   text; source files stay focused on Rust documentation and code. It is the
   lowest-maintenance shape and matches the surveyed Rust practice. ([Cargo
   manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [OpenZeppelin template README](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/README.md), retrieved 2026-09-05.)
2. A plain SPDX header is a file-local metadata architecture. The correct line
   for the fixed choice is exactly:

   ```rust
   // SPDX-License-Identifier: MIT OR Apache-2.0
   ```

   SPDX says this short-form line is a valid way to identify the applicable
   expression. It is sufficient as an SPDX short-form declaration, but it is
   not sufficient for REUSE conformance by itself, because REUSE also requires
   one or more copyright notices. ([SPDX, Handling License Info](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05.)
3. A REUSE header is a full compliance architecture, not merely a shorter
   license block. For a project-owned Rust file, its minimal form is:

   ```rust
   // SPDX-FileCopyrightText: 2026 Steve Morin
   //
   // SPDX-License-Identifier: MIT OR Apache-2.0
   ```

   REUSE's `reuse annotate` can generate it and `reuse lint` can verify it, but
   adopting it also introduces REUSE's `LICENSES/` layout or equivalent
   metadata obligations and a Python-based development tool. ([REUSE tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05; [REUSE annotate documentation](https://reuse.readthedocs.io/en/stable/man/reuse-annotate.html), retrieved 2026-09-05.)
4. A full-text block maximizes standalone human context but duplicates legal
   text across every file, increases review noise, and can silently become
   stale when the repository changes from single MIT to a dual expression. The
   current clap source demonstrates the exact drift risk: a dual repository
   retains an MIT-only file header. ([Clap repository](https://github.com/clap-rs/clap), retrieved 2026-09-05; [Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)

The recommended design is root-only Cargo metadata with a deliberately explicit
negative rule: R46 does not add header-insertion automation. The example
composes the Rust CLI, library, and web-service crates under one workspace
license without putting license boilerplate before CLI help docs, library crate
docs, or web module docs. The behavior is verified by a manifest/root-files
check and a source-header policy check; neither check was run because this
checkout is a research tree and contains no Rust implementation. ([Repository
README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

`BASELINE-REVIEW: F206 — root license metadata must express the fixed dual license — retain F206 as COMMON → REUSE with LICENSE-APACHE, LICENSE-MIT, and Cargo license = "MIT OR Apache-2.0"; R46 must not replace it with a single root file — the Rust API Guidelines prescribe the two root files and Cargo documents the same SPDX expression, both retrieved 2026-09-05.`

### Dominant choice

Root-only Cargo metadata plus `LICENSE-APACHE` and `LICENSE-MIT`, with no
per-file header in repository-owned `.rs` files. This is the dominant choice for
the target because Cargo is the first-party distribution authority, the Rust API
Guidelines prescribe the root pair, and current Serde, Tokio, Axum, and the
OpenZeppelin template show the low-boilerplate source shape. ([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05; [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Serde `lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs), retrieved 2026-09-05; [Tokio `lib.rs`](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs), retrieved 2026-09-05.)

### Options

| Name | Where documented | Adopters that practice it | Date of most recent authoritative write-up |
|---|---|---|---|
| Root-only metadata | [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html); [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html) | Serde, Tokio, Axum, and OpenZeppelin's Rust project template use root metadata while representative Rust source begins with docs or attributes rather than a license block. ([Serde](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs); [Tokio](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs); [Axum](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs); [OpenZeppelin template](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/src/lib.rs), all retrieved 2026-09-05.) | 2026-09-05 retrieval |
| SPDX one-line header | [SPDX handling guidance](https://spdx.dev/learn/handling-license-info/); [SPDX expression specification](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/) | SPDX recommends the short-form mechanism; Linux documents and uses SPDX source tags, and many projects use the tag as a portable file-local declaration. ([Linux license rules](https://github.com/torvalds/linux/blob/master/Documentation/process/license-rules.rst), retrieved 2026-09-05.) | 2026-09-05 retrieval |
| REUSE header plus verifier | [REUSE Specification](https://reuse.software/spec-3.3/); [`reuse annotate`](https://reuse.readthedocs.io/en/stable/man/reuse-annotate.html) | The Rust Project tracks its in-tree source and third-party material with `REUSE.toml`, `reuse`, and generated license metadata; this is a compliance architecture rather than evidence that every Rust file needs a visible header. ([Rust `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT); [Rust `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml), retrieved 2026-09-05.) | 2026-09-05 retrieval |
| Full-text license block | No corresponding Cargo or SPDX requirement; source-project conventions | py-launch-blueprint's inherited full MIT block and clap's MIT-only block are direct precedents, but clap shows the mismatch risk after a dual-license manifest. ([py source precedent](https://github.com/smorinlabs/py-launch-blueprint/blob/main/src/py_launch_blueprint/__init__.py); [clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.) | 2026-09-05 retrieval |

### Excluded by gate

| Candidate | Gate result | Reason |
|---|---|---|
| Root-only Cargo metadata | Pass | License is the fixed SPDX expression; no crate or dependency tree, so MSRV, RustSec, async runtime, binary-size, and compile-time gates are inapplicable. Cargo and repository root files work on both required CI operating systems because they are platform-neutral text and Cargo metadata. ([Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.) |
| Plain SPDX header | Pass as a pattern; not selected | The expression is license-compatible and has no dependency, runtime, binary, or platform cost. It is not REUSE-compliant without a copyright companion. ([SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05.) |
| REUSE header and `reuse lint` | Excluded for this template's default path | The specification is license-compatible and the tool is cross-platform at the process level, but it adds an external Python tool, `LICENSES/`/metadata rules, copyright-owner maintenance, and a new required gate for every source and repository file. Those costs are not justified by the target's single uniform license. Rust Project practice demonstrates that REUSE is useful for a much larger mixed-origin tree, not that this template needs it. ([REUSE tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05; [Rust `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml), retrieved 2026-09-05.) |
| `file_header` | Excluded by gate: required platform/maintenance evidence unverified | The maintained-looking Rust library can add or check arbitrary headers and has an SPDX feature, but the surveyed documentation does not establish the required `ubuntu-latest` and `macos-latest` CI matrix or a composite dual-expression workflow. It is therefore not a justified default dependency. ([file_header docs](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [file_header source](https://github.com/google/file-header), retrieved 2026-09-05.) |
| `addlicense` | Excluded by gate: ecosystem-fit and toolchain evidence | It is a Go program with useful check-only and SPDX-only modes, but it introduces a Go toolchain for a Rust template and documents fixed license modes rather than the target's exact dual expression as the primary interface. Its source-header automation is unnecessary when the selected pattern has no headers. ([addlicense](https://github.com/google/addlicense), retrieved 2026-09-05.) |
| Full-text block | Excluded by fitness and drift risk | It is technically license-compatible only when the complete block states both licenses correctly. The observed clap block states MIT while its repository is dual licensed, so copied boilerplate fails the exact-expression acceptance criterion. ([Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.) |

For all pattern candidates, crate download, release, RustSec, open-issue,
responsiveness, default-feature, dependency-tree MSRV, and binary-size figures
are inapplicable unless a candidate is adopted as a crate dependency. No such
dependency is selected. The only tool candidate requiring a detailed crate
fitness audit, `file_header`, is excluded because the required platform and
integration evidence was not established. ([file_header docs](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05.)

### Up-and-comers

`licet` is the most relevant emerging tool found. Its documentation describes a
single-binary Rust CLI and library that manages SPDX/REUSE-compatible headers,
declarative metadata, drift classification, and reconciliation. That is a
promising future alternative if the repository later needs file-level licensing
for mixed-origin assets, but its recent, small ecosystem does not outweigh the
zero-dependency root-only design for R46. ([`licet` documentation](https://docs.rs/licet/latest/licet/), retrieved 2026-09-05; [`licet` crate metadata](https://docs.rs/crate/licet/latest/source/Cargo.toml), retrieved 2026-09-05.)

`file_header` remains useful as a library building block for a project that has
already decided on a uniform full or SPDX-derived header. It supports recursive
check/add/delete operations and an SPDX-oriented module, but its API is a
library surface rather than a repository policy, and the survey found no
evidence that it is the accepted Rust-project convention. ([`file_header` API](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [`file_header` README](https://raw.githubusercontent.com/google/file-header/master/README.md), retrieved 2026-09-05.)

`cargo-about` is an adjacent mature practice for generating a license listing
for all dependencies. It can complement root-only metadata when the web service
or binary later ships third-party notices, but it does not insert or verify
headers in the template's own `.rs` files. ([`cargo-about` README](https://raw.githubusercontent.com/EmbarkStudios/cargo-about/main/README.md), retrieved 2026-09-05.)

### Fit for this template

CLI: root-only metadata keeps `src/main.rs` and command modules free to put
crate/module docs, `clap` attributes, and help-oriented comments at the top. A
header adds no CLI behavior and creates a copy/synchronization obligation for a
template whose users will rename the package and copyright holder. A full block
is especially poor fit because the clap example shows how a legacy MIT block
can survive after the package becomes dual licensed. ([Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

Library: root-only metadata aligns with Cargo's package contract and with Serde's
source layout. A library consumer receives the crate manifest and packaged root
license files; a file copied independently would lose repository context under
any root-only scheme, but an SPDX line alone still does not carry either legal
text or copyright information. The benefit of adding a header is therefore
discoverability, not a replacement for the root pair. ([Cargo package metadata](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Serde `lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs), retrieved 2026-09-05; [SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05.)

Web service: root-only metadata is independent of whether the web adapter is
compiled behind an optional feature or uses an async runtime. It avoids putting
license comments before `//!` module documentation in the web crate and adds no
async-runtime, latency, throughput, memory, binary, or compile-time cost. Axum's
representative library follows this documentation-first shape. ([Axum `lib.rs`](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

Operational performance comparison: the selected pattern performs no file scan
at build or runtime. `reuse lint`, `file_header`, and `addlicense` are
repository-tree I/O workloads whose cost grows with files and bytes and whose
instrumentation would be wall-clock scan time, files inspected, and failures;
they do not affect request latency or service throughput when run only in CI.
No benchmark was run, so no absolute speed ranking is claimed. ([REUSE lint documentation](https://reuse.readthedocs.io/en/latest/readme.html), retrieved 2026-09-05; [`file_header` API](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [addlicense](https://github.com/google/addlicense), retrieved 2026-09-05.)

### Recommendation

Adopt root-only metadata and no per-file embedded license header for
repository-owned `.rs` files. Implement the fixed dual license as
`license = "MIT OR Apache-2.0"` in the Cargo manifest and ship
`LICENSE-APACHE` plus `LICENSE-MIT` at the repository root. Do not add
`reuse`, `file_header`, `addlicense`, or a custom header inserter for R46.

This preserves the shared policy-level principle while choosing the Rust-native
mechanism prescribed by Cargo guidance and demonstrated by current Rust
libraries and templates. It also prevents the exact source/manifest mismatch
seen in the full-header precedent. ([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05; [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)

### Ranked runner-up

REUSE-style SPDX header, ranked first among header-bearing choices and second
overall. It wins if a future scope change introduces mixed-origin source,
vendored code, independently redistributed file fragments, or a compliance
requirement for file-level copyright attribution. In that case use the exact
dual expression and a maintained copyright line:

```rust
// SPDX-FileCopyrightText: 2026 Steve Morin
//
// SPDX-License-Identifier: MIT OR Apache-2.0
```

Run `reuse lint` in CI and use `reuse annotate` only for intentional additions;
do not use a full license-text block. This condition follows REUSE's requirement
for both tags and its recommendation that comment headers be close to the top
of commentable files. ([REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05; [REUSE annotate documentation](https://reuse.readthedocs.io/en/stable/man/reuse-annotate.html), retrieved 2026-09-05.)

### Tradeoffs

Against the plain SPDX one-line runner-up, root-only metadata gives up file-local
license discoverability when a source file is copied out of its crate. It gains
zero source boilerplate, no copyright-year maintenance, and no risk that a
one-line file marker disagrees with the manifest. If file portability becomes a
requirement, choose the REUSE-style two-line form rather than a bare SPDX line,
because the latter does not supply REUSE's required copyright notice. ([SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05.)

Against REUSE, root-only metadata gives up standardized per-file attribution
and machine validation for mixed-origin files. It gains a smaller contributor
surface, no Python toolchain, no `LICENSES/` migration, and no extra gate on a
uniformly licensed template. The Rust Project's REUSE annotations remain a
credible escalation path if the repository later incorporates third-party
source. ([Rust `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT), retrieved 2026-09-05; [Rust `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml), retrieved 2026-09-05.)

Against the full-text block, root-only metadata gives up standalone human
context in a detached file. It gains a single source of legal text and avoids
the observed MIT-only/dual-license drift. ([Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05; [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.)

### Parameters

`owns` no parameter.

`assumes` no consumed parameter.

The fixed owner parameter remains `license = MIT OR Apache-2.0`; R46 does not
change it. The fixed `rust-edition = 2024`, MSRV policy, and
`target-os-matrix = ubuntu-latest, macos-latest` are not altered. ([Run
parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), retrieved 2026-09-05.)

### Migration implications

The implementation plan should:

- create or retain root `LICENSE-APACHE` with the Apache License 2.0 text;
- create or retain root `LICENSE-MIT` with the MIT text;
- set the workspace/package manifest's `license` field to exactly
  `"MIT OR Apache-2.0"`;
- do not prepend a full block, SPDX line, or REUSE header to generated
  `src/main.rs`, `src/lib.rs`, web modules, tests, examples, or benches;
- do not add a header inserter, header verifier, `REUSE.toml`, or `LICENSES/`
  directory for this item; and
- document the root license pair in the README's license section, following
  the Rust API Guidelines wording and links.

If a later feature adds vendored or differently licensed source, that feature
must introduce a scoped exception and reconsider the ranked runner-up. The
current source repositories establish the need to document this negative rule:
py stamps headers broadly, while ts's attempted conversion was incomplete.
([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05; [Rust repository `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT), retrieved 2026-09-05.)

### Validation strategy

Planned checks; not executed because this research checkout contains no Rust
implementation:

```sh
# From the implementation repository root.
set -eu

test -s LICENSE-MIT
test -s LICENSE-APACHE
grep -Fx 'license = "MIT OR Apache-2.0"' Cargo.toml
cargo metadata --no-deps --format-version 1 >/dev/null

# Repository-owned Rust files must not acquire the rejected header forms.
if find src tests examples benches -type f -name '*.rs' -print0 \
  | xargs -0 awk '
      FNR <= 20 && ($0 ~ /SPDX-License-Identifier:/ ||
                    $0 ~ /SPDX-FileCopyrightText:/ ||
                    $0 ~ /Licensed under the MIT license/ ||
                    $0 ~ /Permission is hereby granted/) {
        print FILENAME ":" FNR ":" $0; found = 1
      }
      END { exit found ? 1 : 0 }
    '; then
  echo 'unexpected per-file license header' >&2
  exit 1
fi

cargo fmt --all -- --check
cargo test --workspace --all-targets
cargo package --workspace --allow-dirty --no-verify
```

Expected behavior: the manifest and both root files pass; `cargo metadata`
reports the dual expression; the header-policy probe exits zero when all
repository-owned Rust files are header-free; formatting, tests, and packaging
pass; and the package contains the root license files. The inverse control is
to add the proposed legacy MIT block or SPDX marker to a fixture source file and
confirm the header-policy probe exits nonzero. A separate positive control is a
fixture containing `//!` documentation as its first Rust documentation element;
it should compile and remain untouched. ([Cargo package command](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

The checks prove the selected repository policy, not legal validity of a
copyright ownership claim. If the later implementation adopts REUSE instead,
replace the negative header probe with `reuse lint`, and verify both
`SPDX-FileCopyrightText` and `SPDX-License-Identifier` on every covered file.
([REUSE tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05.)

### Confidence & re-verify trigger

Confidence: high for the Rust implementation choice and medium for the claim
about ecosystem prevalence. The direct evidence includes the Rust Project,
Serde, Tokio, Axum, clap, and a maintained Rust template, but it is a
representative survey rather than a census. The exact SPDX expression and the
REUSE copyright distinction are high-confidence standards findings. ([SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05.)

Re-verify before implementation if any of these triggers occurs: the owner
changes the fixed `license` parameter; the repository begins shipping vendored
or mixed-license source; a downstream compliance requirement demands file-level
copyright attribution; Cargo changes its manifest license semantics; or the
Rust Project changes its root-license guidance. Also recheck the exact
copyright-holder line before adopting the REUSE runner-up. ([Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05.)

### Sources

Method notes: I surveyed the category before selecting candidates, then read
first-party Rust/Cargo guidance, SPDX and REUSE standards, current source files
and manifests from Serde, Tokio, Axum, clap, Rust, and OpenZeppelin's Rust
template, and tool documentation for `reuse`, `file_header`, `addlicense`,
`licet`, and `cargo-about`. I queried GitHub REST repository endpoints of the
form `GET https://api.github.com/repos/<owner>/<repo>` and open-issue endpoints
of the form `GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open`;
the unauthenticated API returned rate-limit responses, so no REST-derived
figures are reported. The crates.io endpoints
`GET https://crates.io/api/v1/crates/<name>` and
`GET https://crates.io/api/v1/crates/<name>/versions`, and RustSec package pages
of the form `https://rustsec.org/packages/<name>.html`, were not queried because
R46 is a pattern item and no crate is recommended or added; their figures are
inapplicable. I did not run the implementation acceptance commands because the
repository has no Rust code yet.

- [Rust API Guidelines — C-PERMISSIVE](https://rust-lang.github.io/api-guidelines/necessities.html) — retrieved 2026-09-05.
- [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html) — retrieved 2026-09-05.
- [Cargo package command](https://doc.rust-lang.org/cargo/commands/cargo-package.html) — retrieved 2026-09-05.
- [Rust Reference — comments](https://doc.rust-lang.org/reference/comments.html) — retrieved 2026-09-05.
- [SPDX — Handling License Info](https://spdx.dev/learn/handling-license-info/) — retrieved 2026-09-05.
- [SPDX 2.3 — License Expressions](https://spdx.github.io/spdx-spec/v2.3/SPDX-license-expressions/) — retrieved 2026-09-05.
- [REUSE Specification 3.3](https://reuse.software/spec-3.3/) — retrieved 2026-09-05.
- [REUSE tutorial](https://reuse.software/tutorial/) — retrieved 2026-09-05.
- [REUSE annotate](https://reuse.readthedocs.io/en/stable/man/reuse-annotate.html) — retrieved 2026-09-05.
- [Rust Project `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT) — retrieved 2026-09-05.
- [Rust Project `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml) — retrieved 2026-09-05.
- [Serde repository](https://github.com/serde-rs/serde) and [`serde/src/lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs) — retrieved 2026-09-05.
- [Tokio repository](https://github.com/tokio-rs/tokio) and [`tokio/src/lib.rs`](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs) — retrieved 2026-09-05.
- [Axum repository](https://github.com/tokio-rs/axum) and [`axum/src/lib.rs`](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs) — retrieved 2026-09-05.
- [Clap repository](https://github.com/clap-rs/clap) and [`clap_builder/src/lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs) — retrieved 2026-09-05.
- [OpenZeppelin Rust project template](https://github.com/OpenZeppelin/rust-project-template) and [`src/lib.rs`](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/src/lib.rs) — retrieved 2026-09-05.
- [`file_header` docs](https://docs.rs/file-header/latest/file_header/) and [source repository](https://github.com/google/file-header) — retrieved 2026-09-05.
- [`addlicense`](https://github.com/google/addlicense) — retrieved 2026-09-05.
- [`licet` docs](https://docs.rs/licet/latest/licet/) — retrieved 2026-09-05.
- [`cargo-about` README](https://raw.githubusercontent.com/EmbarkStudios/cargo-about/main/README.md) — retrieved 2026-09-05.
- [Linux license rules](https://github.com/torvalds/linux/blob/master/Documentation/process/license-rules.rst) — retrieved 2026-09-05.
