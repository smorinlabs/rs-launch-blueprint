Actor: `research-codex-2026-09-05T160304Z-5cba7fe96ae4`
Item: `R46` (`per-file-license-header`)
Retrieved: 2026-09-05

### Landscape

Category decided: source-file licensing metadata for Rust source files. The
choice is a repository pattern, not a runtime crate. Crate download, release,
RustSec, issue-response, binary-size, and compile-time figures are therefore
inapplicable to the dominant pattern itself; the tool candidates below are
implementation evidence, not runtime dependencies of the template. Repository
maintenance and execution on the required CI operating systems remain relevant
evidence; neither becomes inapplicable merely because the choice is a pattern.

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
- Cargo's official manifest reference is authoritative for what crates.io
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

Practice survey, selected for relevance to the target shapes. The source
observations below were retrieved on 2026-09-05; they establish file content,
not maintenance state. Maintenance evidence is recorded separately below.

- Serde is a Rust serialization framework with a public
  workspace, dual root license files, and `license = "MIT OR
  Apache-2.0"`; its representative `serde/src/lib.rs` begins with `//!`
  documentation and no license header. ([Serde repository](https://github.com/serde-rs/serde), retrieved 2026-09-05; [Serde
  manifest](https://raw.githubusercontent.com/serde-rs/serde/master/serde/Cargo.toml), retrieved 2026-09-05; [Serde
  `lib.rs`](https://raw.githubusercontent.com/serde-rs/serde/master/serde/src/lib.rs), retrieved 2026-09-05.)
- Tokio is an async Rust project with its own API
  documentation, guides, release policy, and supported-version policy. Its
  representative `tokio/src/lib.rs` begins with Rust attributes and no license
  header; the package manifest uses root license metadata rather than a
  per-file block. ([Tokio repository](https://github.com/tokio-rs/tokio), retrieved 2026-09-05; [Tokio
  `lib.rs`](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/src/lib.rs), retrieved 2026-09-05; [Tokio
  manifest](https://raw.githubusercontent.com/tokio-rs/tokio/master/tokio/Cargo.toml), retrieved 2026-09-05.)
- Axum supplies web-framework practice from the Tokio project. Its
  representative `axum/src/lib.rs` begins with `//!` documentation and no
  license header, while its manifest carries package license metadata.
  ([Axum repository](https://github.com/tokio-rs/axum), retrieved 2026-09-05; [Axum
  `lib.rs`](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/src/lib.rs), retrieved 2026-09-05; [Axum
  manifest](https://raw.githubusercontent.com/tokio-rs/axum/main/axum/Cargo.toml), retrieved 2026-09-05.)
- Clap supplies CLI practice and is explicitly dual licensed at the
  repository level, but its representative `clap_builder/src/lib.rs` retains
  a four-line MIT-only legacy header. That is evidence that full-text headers
  can drift from a later dual-license manifest; it is not a suitable template
  for the fixed dual expression. ([Clap repository](https://github.com/clap-rs/clap), retrieved 2026-09-05; [Clap
  manifest](https://raw.githubusercontent.com/clap-rs/clap/master/Cargo.toml), retrieved 2026-09-05; [Clap
  `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)
- OpenZeppelin's Rust project template is directly relevant template
  evidence. Its setup checklist tells users to align `Cargo.toml` with the
  license files and its representative `src/lib.rs` begins with module docs,
  without a per-file license block. ([OpenZeppelin Rust project template](https://github.com/OpenZeppelin/rust-project-template), retrieved
  2026-09-05; [template README](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/README.md), retrieved
  2026-09-05; [template `src/lib.rs`](https://raw.githubusercontent.com/OpenZeppelin/rust-project-template/master/src/lib.rs), retrieved
  2026-09-05.)

Maintenance refresh, queried on 2026-09-05 with `curl -sS` and
`User-Agent: rs-launch-blueprint-R46-evidence-recheck/1.0`:

| Reference or tool | Exact repository endpoint | Result and maintenance state |
|---|---|---|
| Cargo | [rust-lang/cargo](https://api.github.com/repos/rust-lang/cargo) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| Rust Project | [rust-lang/rust](https://api.github.com/repos/rust-lang/rust) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| Serde | [serde-rs/serde](https://api.github.com/repos/serde-rs/serde) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| Tokio | [tokio-rs/tokio](https://api.github.com/repos/tokio-rs/tokio) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| Axum | [tokio-rs/axum](https://api.github.com/repos/tokio-rs/axum) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| Clap | [clap-rs/clap](https://api.github.com/repos/clap-rs/clap) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| OpenZeppelin template | [OpenZeppelin/rust-project-template](https://api.github.com/repos/OpenZeppelin/rust-project-template) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| REUSE tool mirror | [fsfe/reuse-tool](https://api.github.com/repos/fsfe/reuse-tool) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| `file_header` | [google/file-header](https://api.github.com/repos/google/file-header) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| `addlicense` | [google/addlicense](https://api.github.com/repos/google/addlicense) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| `licet` | [knitli/licet](https://api.github.com/repos/knitli/licet) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |
| `cargo-about` | [EmbarkStudios/cargo-about](https://api.github.com/repos/EmbarkStudios/cargo-about) | HTTP 403, API rate limit exceeded; maintenance **unverified**. |

All endpoint results in this table were retrieved on 2026-09-05. Release pages
were not used as a fallback. No `active`, `stable-quiet`, `at-risk`, `dormant`,
or `archived` classification is assigned without supporting evidence;
`unverified` records an evidence gap, not a maintenance-rubric verdict. A live
source URL or documentation page is not a recent-push, release, or response
signal. The requested maintained-reference condition remains unverified.

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
docs, or web module docs. The proposed acceptance checks cover manifest/root
files and source-header policy. The corrected header-check control flow is
tested below with in-memory inputs; full Rust integration and execution on
`ubuntu-latest` and `macos-latest` remain unverified. ([Repository
README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

`BASELINE-REVIEW: F206 — root license metadata must express the fixed dual license — retain F206 as COMMON → REUSE with LICENSE-APACHE, LICENSE-MIT, and Cargo license = "MIT OR Apache-2.0"; R46 must not replace it with a single root file — the Rust API Guidelines prescribe the two root files and Cargo documents the same SPDX expression, both retrieved 2026-09-05.`

### Dominant choice

Root-only Cargo metadata plus `LICENSE-APACHE` and `LICENSE-MIT`, with no
per-file header in repository-owned `.rs` files, is the provisional preference.
It has not passed the required OS execution gate. This is the preferred choice for
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
| Root-only Cargo metadata | OS gate **unverified**; provisional preference | The fixed expression passes the license-expression requirement. No added crate or dependency tree: crate MSRV and RustSec gates are inapplicable; the text adds no `unsafe` code, Cargo features, or async-runtime coupling. Runtime binary/compile cost is inapplicable to metadata; the proposed shell check has repository-scan cost. Execution of this acceptance check on `ubuntu-latest` and `macos-latest` is **unverified**; a local shell-control probe is not either CI runner. Windows execution is also unverified and is not required. The syntax reference is not OS-test evidence. ([Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05.) |
| Plain SPDX header | OS gate **unverified**; not selected | The expression passes the license-expression requirement. Crate/dependency MSRV and RustSec gates are inapplicable to an ordinary comment; it introduces no `unsafe` code, features, or async-runtime coupling. It adds source bytes, with no runtime behavior or benchmarked compile-time effect. No execution of header placement, compilation, and checking on `ubuntu-latest` and `macos-latest` was verified. Windows execution is unverified and not required. Syntax validity does not establish platform testing; a bare SPDX line also does not establish REUSE conformance. ([SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05.) |
| REUSE header and `reuse lint` | OS gate **unverified**; conditional runner-up | The header can express the fixed dual license. The comment has no crate MSRV, RustSec advisory, `unsafe` code, features, or async-runtime coupling. The Python verifier is a separate development tool: Rust MSRV/features are inapplicable, and its dependency security/posture has not been audited. No execution of `reuse annotate`/`reuse lint` on both `ubuntu-latest` and `macos-latest` was verified; Windows execution is also unverified and not required. Neither the REUSE specification nor the tutorial proves that matrix. The tool adds installation and repository-scan cost, with no link-time dependency in the Rust application. Its metadata/copyright maintenance is a tradeoff, not a failed platform test. ([REUSE tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05; [Rust `REUSE.toml`](https://github.com/rust-lang/rust/blob/main/REUSE.toml), retrieved 2026-09-05.) |
| `file_header` | Not admitted: tool fitness and maintenance **unverified** | The Rust library documents arbitrary-header check/add operations and an SPDX feature. This report has not established a complete license/dependency-MSRV/RustSec/`unsafe`/default-feature audit, the exact composite-expression workflow, or execution on both required operating systems. Windows execution is unverified. A development-only use would add compile/setup cost without linking into the shipped application. It remains a lead, not a gate-passed dependency. ([file_header docs](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [file_header source](https://github.com/google/file-header), retrieved 2026-09-05.) |
| `addlicense` | Not admitted: tool fitness and maintenance **unverified** | It is an Apache-2.0 Go tool documenting check-only and SPDX-only modes. Rust MSRV, Cargo features, and RustSec package metrics are inapplicable; Go dependency security and unsafe posture were not audited. No exact dual-expression check or required OS execution matrix was verified; Windows is unverified and not required. Source installation adds a Go toolchain, and checking adds repository I/O. Those integration costs do not themselves constitute a license or OS-gate failure. ([addlicense](https://github.com/google/addlicense), retrieved 2026-09-05.) |
| Full-text block | Legacy MIT-only form fails the fixed-expression requirement; correct dual form is disfavored | Copying the observed MIT-only block does not implement the requested repository-wide dual declaration. A correctly authored dual block would avoid that defect, but its required OS execution gate is **unverified**. Crate MSRV, RustSec, features, and runtime coupling are inapplicable to comments; no `unsafe` code is introduced. Repeated legal text adds source and review cost; compile-time cost was not measured. Windows execution is unverified and not required. ([Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.) |

No pattern has a verified overall gate pass. The preference below is conditional
on completing the required OS checks. An unverified gate is an evidence gap,
not a demonstrated incompatibility. Pattern download/release/advisory figures
are inapplicable to metadata itself; a tool considered for installation still
needs its own fitness audit. Reference maintenance is explicitly unverified in
the Landscape table and is not waived by the absence of a runtime dependency.

### Up-and-comers

`licet` is the most relevant emerging tool found. Its documentation describes a
single-binary Rust CLI and library that manages SPDX/REUSE-compatible headers,
declarative metadata, drift classification, and reconciliation. That is a
promising future alternative if the repository later needs file-level licensing
for mixed-origin assets. Its maintenance, adoption, license/dependency-MSRV,
RustSec/`unsafe`, default-feature, required-OS, and build-cost gates were not
verified; it is a research lead rather than an installation recommendation.
No claim about its age or ecosystem size is made. ([`licet` documentation](https://docs.rs/licet/latest/licet/), retrieved 2026-09-05; [`licet` crate metadata](https://docs.rs/crate/licet/latest/source/Cargo.toml), retrieved 2026-09-05.)

`file_header` remains useful as a library building block for a project that has
already decided on a uniform full or SPDX-derived header. It supports recursive
check/add/delete operations and an SPDX-oriented module, but its API is a
library surface rather than a repository policy, and the survey found no
evidence that it is the accepted Rust-project convention. ([`file_header` API](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [`file_header` README](https://raw.githubusercontent.com/google/file-header/master/README.md), retrieved 2026-09-05.)

`cargo-about` is an adjacent tool for generating a license listing
for all dependencies. It can complement root-only metadata when the web service
or binary later ships third-party notices, but it does not insert or verify
headers in the template's own `.rs` files. Its maintenance is unverified after
the REST retry; it is not selected or gate-audited for installation here.
([`cargo-about` README](https://raw.githubusercontent.com/EmbarkStudios/cargo-about/main/README.md), retrieved 2026-09-05.)

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

These shape-specific arguments concern architecture. They do not establish
execution on `ubuntu-latest` or `macos-latest`; that gate is unverified for the
preferred pattern and both SPDX/REUSE alternatives.

Operational performance comparison: metadata performs no application-runtime
scan. The proposed acceptance probe does scan repository files. `reuse lint`,
`file_header`, and `addlicense` are
repository-tree I/O workloads whose cost grows with files and bytes and whose
instrumentation would be wall-clock scan time, files inspected, and failures;
they do not affect request latency or service throughput when run only in CI.
No benchmark was run, so no absolute speed ranking is claimed. ([REUSE lint documentation](https://reuse.readthedocs.io/en/latest/readme.html), retrieved 2026-09-05; [`file_header` API](https://docs.rs/file-header/latest/file_header/), retrieved 2026-09-05; [addlicense](https://github.com/google/addlicense), retrieved 2026-09-05.)

### Recommendation

Provisional recommendation: adopt root-only metadata and no per-file embedded license header for
repository-owned `.rs` files. Implement the fixed dual license as
`license = "MIT OR Apache-2.0"` in the Cargo manifest and ship
`LICENSE-APACHE` plus `LICENSE-MIT` at the repository root. Do not add
`reuse`, `file_header`, `addlicense`, or a custom header inserter for R46.

This is an architectural preference, not an implementation-ready gate pass.
Execution on `ubuntu-latest` and `macos-latest`, and current maintenance of the
reference implementations, remain **unverified**. Obtain that evidence before
calling the recommendation fully validated.

This preserves the shared policy-level principle while choosing the Rust-native
mechanism prescribed by Cargo guidance and demonstrated by current Rust
libraries and templates. It also prevents the exact source/manifest mismatch
seen in the full-header precedent. ([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05; [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html), retrieved 2026-09-05; [Clap `lib.rs`](https://raw.githubusercontent.com/clap-rs/clap/master/clap_builder/src/lib.rs), retrieved 2026-09-05.)

### Ranked runner-up

REUSE-style SPDX header, ranked first among header-bearing choices and second
overall. It wins if a future scope change introduces mixed-origin source,
vendored code, independently redistributed file fragments, or a compliance
requirement for file-level copyright attribution. In that case use the exact
dual expression and an accurate copyright line:

```rust
// SPDX-FileCopyrightText: 2026 Steve Morin
//
// SPDX-License-Identifier: MIT OR Apache-2.0
```

First establish the selected REUSE tool version's maintenance and execution on
both required CI operating systems; neither is verified here. Then run
`reuse lint` in CI and use `reuse annotate` only for intentional additions;
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
- do not add a header-stamping dependency, `REUSE.toml`, or `LICENSES/`
  directory for this item; the source-policy probe below is an acceptance
  check for this migration, not a new insertion tool; and
- document the root license pair in the README's license section, following
  the Rust API Guidelines wording and links.

If a later feature adds vendored or differently licensed source, that feature
must introduce a scoped exception and reconsider the ranked runner-up. The
current source repositories establish the need to document this negative rule:
py stamps headers broadly, while ts's attempted conversion was incomplete.
([Rust API Guidelines](https://rust-lang.github.io/api-guidelines/necessities.html), retrieved 2026-09-05; [Rust repository `COPYRIGHT`](https://github.com/rust-lang/rust/blob/main/COPYRIGHT), retrieved 2026-09-05.)

### Validation strategy

The corrected checker below has a direct exit-code contract: no prohibited
header returns `0`; a prohibited header returns `1`. An `awk` or `xargs`
execution error is also normalized to `1`. A nonzero result from file discovery
fails the caller through Bash's `pipefail`; it cannot silently count as a pass.
`awk` returns `0` when it finds no match and `1` for a match. `xargs` may map a
child failure to a different nonzero code, so the enclosing `if !` converts
every checker failure to `1` rather than depending on a particular `xargs`
implementation's status.

The following is a proposed implementation-repository acceptance sequence.
The extracted `r46_check_headers` function and the caller's no-source-roots
branch were exercised during this revision, with the controls described below.
Full discovery, manifest,
formatting, compilation, testing, and packaging remain unexecuted. Use Bash on
each required CI runner; no claim of execution on either runner is made here.

```bash
# Execute with Bash from the implementation repository root.
set -euo pipefail

test -s LICENSE-MIT
test -s LICENSE-APACHE
grep -Fx 'license = "MIT OR Apache-2.0"' Cargo.toml
cargo metadata --no-deps --format-version 1 >/dev/null

# Consume NUL-delimited source paths on stdin. Do not invert this contract.
#
# The detector's complete supported header set is explicit: within the first
# 40 lines of each repository-owned `.rs` file, reject either SPDX marker;
# the canonical MIT notice phrases `Licensed under the MIT license`,
# `Permission is hereby granted, free of charge, to any person obtaining a
# copy`, or `THE SOFTWARE IS PROVIDED "AS IS"`; or the canonical Apache notice
# phrases `Licensed under the Apache License, Version 2.0`, `you may not use
# this file except in compliance with the License`, or `Unless required by
# applicable law or agreed to in writing, software distributed under the
# License is distributed on an "AS IS" BASIS`. A source file with none of
# those exact signatures is outside this detector's prohibited-header set and
# is accepted. The limit is 40 lines so a header cannot hide after the earlier
# 20-line heuristic boundary.
r46_check_headers() {
  if ! xargs -0 awk '
      FNR <= 40 {
        signature = ""
        if ($0 ~ /SPDX-License-Identifier:/) {
          signature = "SPDX-License-Identifier:"
        } else if ($0 ~ /SPDX-FileCopyrightText:/) {
          signature = "SPDX-FileCopyrightText:"
        } else if ($0 ~ /Licensed under the MIT license/) {
          signature = "MIT license header"
        } else if ($0 ~ /Permission is hereby granted, free of charge, to any person obtaining a copy/) {
          signature = "MIT permission header"
        } else if ($0 ~ /THE SOFTWARE IS PROVIDED "AS IS"/) {
          signature = "MIT warranty header"
        } else if ($0 ~ /Licensed under the Apache License, Version 2\.0/) {
          signature = "Apache-2.0 license header"
        } else if ($0 ~ /you may not use this file except in compliance with the License/) {
          signature = "Apache-2.0 compliance header"
        } else if ($0 ~ /Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS/) {
          signature = "Apache-2.0 warranty header"
        }
        if (signature != "") {
          print FILENAME ":" FNR ":" signature
          found = 1
        }
      }
      END { exit found ? 1 : 0 }
    '; then
    echo 'unexpected per-file license header or header-check failure' >&2
    return 1
  fi
  return 0
}

# Scope to repository-owned source roots in the generated layout.
# Optional directories need not exist; add any other workspace source roots.
r46_roots=()
for r46_dir in src tests examples benches crates; do
  if [[ -d "$r46_dir" ]]; then
    r46_roots+=("$r46_dir")
  fi
done
if (( ${#r46_roots[@]} > 0 )); then
  find "${r46_roots[@]}" -type f -name '*.rs' -print0 | r46_check_headers
fi

cargo fmt --all -- --check
cargo test --workspace --all-targets
cargo package --workspace --allow-dirty --no-verify
```

Executed control-flow checks on the local Darwin host on 2026-09-05: extract
`r46_check_headers` verbatim from this report and execute it with `/bin/bash`,
the host `xargs`, and `/usr/bin/awk`. Feed each fixture through an inherited
file descriptor and give the checker its NUL-delimited path; no fixture files
are written. Expected/observed exit codes and diagnostics are recorded below.
These controls test the actual checker pipeline and conditional, not a rewrite
of the AWK predicate. They do not test `find` traversal or a Cargo workspace.

| Input control | Expected checker exit | Observed checker exit |
|---|---|---|
| Header-free Rust with leading `//!` docs | `0`, no failure diagnostic | `0`, no failure diagnostic |
| SPDX license identifier at the top | `1`, failure diagnostic | `1`, failure diagnostic |
| Legacy MIT-only header | `1`, failure diagnostic | `1`, failure diagnostic |
| Full-text MIT permission line | `1`, failure diagnostic | `1`, failure diagnostic |
| Full-text Apache-2.0 header | `1`, failure diagnostic | `1`, failure diagnostic |
| Copyright SPDX marker | `1`, failure diagnostic | `1`, failure diagnostic |
| Empty path list | `0`, no failure diagnostic | `0`, no failure diagnostic |
| Unreadable input path, `/dev/fd/99` | `1`, failure diagnostic | `1`, failure diagnostic |

The entire Bash block passed `/bin/bash -n`. Running the discovery/check portion
in this run directory, which has none of the listed source roots, returned `0`.
That verifies optional-directory handling, not traversal of an implemented
source tree. All local control results in this section were observed on
2026-09-05.

The integration caller also exits nonzero on a failed check because it uses
`set -euo pipefail`. The original unnegated `if` would instead fail the clean
control and accept a prohibited-header control. Executing that broken form as
an in-memory inverse control produced exactly `1` for clean input and `0` for
the SPDX-header input on 2026-09-05. This distinguishes the corrected behavior
from the original defect.

Planned integration result: the manifest and both root files satisfy the
prerequisites; `cargo metadata` shows each applicable package's dual expression;
formatting/tests/package creation succeed; an explicit package-content review
confirms that both license files are shipped. File existence and a discarded
`cargo metadata` response alone do not prove package contents or per-member
metadata. This sequence is not a legal-text validator. Run it against the final
workspace on `ubuntu-latest` and `macos-latest`, recording the selected stable
and MSRV toolchains, before marking the OS gate verified. Windows remains
unverified and is not required. Compilation and rustdoc checks of `//!` placement
are also still planned. ([Cargo package command](https://doc.rust-lang.org/cargo/commands/cargo-package.html), retrieved 2026-09-05; [Rust comments reference](https://doc.rust-lang.org/reference/comments.html), retrieved 2026-09-05.)

The MIT and Apache inverse controls were fixture-file tests. The command used
the exact checker function above and NUL-delimited paths:

```bash
cd /private/tmp/r46-license-controls
printf 'mit.rs\\0' | r46_check_headers
printf 'apache.rs\\0' | r46_check_headers
```

Observed output:

```text
mit.rs:1:MIT license header
apache.rs:1:Apache-2.0 license header
```

The first command returned `1`; the second command returned `1`. The clean
fixture and SPDX, MIT, full-text MIT, copyright-marker, empty-input, and
unreadable-input controls in the same table were also run with the stated
results on 2026-09-05. The executed controls prove only the checker's exit-code behavior, not legal validity of a
copyright ownership claim. If the later implementation adopts REUSE instead,
replace the negative header probe with `reuse lint`, and verify both
`SPDX-FileCopyrightText` and `SPDX-License-Identifier` on every covered file.
([REUSE tutorial](https://reuse.software/tutorial/), retrieved 2026-09-05.)

### Confidence & re-verify trigger

Confidence: moderate in the architectural preference and limited for claims
about prevalence among actively maintained projects. The surveyed sources
establish representative file layouts; the failed repository rechecks leave
their maintenance **unverified**. The required `ubuntu-latest` and
`macos-latest` execution gate is **unverified** for root-only metadata, plain
SPDX, and REUSE. The local checker controls cannot close that gate. The exact
SPDX expression and the REUSE copyright distinction remain high-confidence
standards findings. ([SPDX handling guidance](https://spdx.dev/learn/handling-license-info/), retrieved 2026-09-05; [REUSE Specification](https://reuse.software/spec-3.3/), retrieved 2026-09-05; repository recheck endpoints in Landscape, retrieved 2026-09-05.)

Before declaring this research fully validated, obtain both required OS runs
and current maintenance evidence through a successful REST query, a dated
release page, or a maintainer notice. This follow-up is required even without
any change to the recommendation. Re-evaluate the design if the owner
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
`licet`, and `cargo-about`. During this correction I read `raw/evidence-terra.md`
and re-queried every repository endpoint listed in Landscape, using
`curl -sS --max-time 30 -A 'rs-launch-blueprint-R46-evidence-recheck/1.0'`.
Each returned HTTP 403 with `API rate limit exceeded` on 2026-09-05. Release
pages were not consulted; maintenance is explicitly **unverified** for those
references and tools. No archive flag, push timestamp, star count, release age,
or issue responsiveness is inferred from those errors. The original run also
queried open-issue endpoints of the form
`GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open`;
some searches succeeded, but their counts were not used and they do not
establish maintenance. The crates.io endpoints
`GET https://crates.io/api/v1/crates/<name>` and
`GET https://crates.io/api/v1/crates/<name>/versions`, and RustSec package pages
of the form `https://rustsec.org/packages/<name>.html`, were not queried because
R46 is a pattern item and no crate is recommended or added; their figures are
inapplicable to the selected metadata pattern. Optional tool installation is
not approved by these metric omissions and would need a complete tool audit.
During this correction I executed the report's actual checker function with
in-memory clean/prohibited-header controls and reproduced the original
inversion as a broken control. The local host was Darwin; this is not evidence
of execution on `macos-latest` or `ubuntu-latest`. Full repository traversal,
Cargo compilation/tests/package checks, and REUSE execution on both required
CI operating systems remain **unverified**. Standards citations establish
syntax and conformance, not OS execution. The control results are local
observations recorded in Validation strategy, not external endpoint figures.

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
