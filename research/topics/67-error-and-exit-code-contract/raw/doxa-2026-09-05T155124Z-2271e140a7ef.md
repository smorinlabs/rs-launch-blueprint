# R67 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260909-001305-a713221f121c4348 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that precede a provider's first template field or follow its last one are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**



**Perplexity (sonar-deep-research)**

**Error and Exit-Code Contract for `rs-launch-blueprint`: Crate Stack and Taxonomy Design**
The error and exit-code contract for `rs-launch-blueprint` must unify three concerns that span the CLI, library, and web service surfaces: a stable, append-only machine-readable error code catalog, a principled exit-code taxonomy including signal and interactive cancellation handling, and a crash-log persistence strategy that fits Rust’s ecosystem while respecting the precedent from the Python and TypeScript ports. The design proposed here adopts a stable string error-code catalog similar to Python’s, embeds those codes as typed metadata on Rust error enums using `thiserror`, uses `anyhow` for application-level error propagation, and employs `ctrlc`-style signal handling with Broken Pipe awareness and a best-effort crash-log writer. This bundle preserves cross-repo agreement at the level of architectural patterns and observable behavior rather than forcing identical low-level mechanisms across ecosystems. It yields a single, named `error-taxonomy-exit-codes` parameter that downstream items (R03, R52–R56, R70) can match against deterministically, while allowing Rust to express richer type-level structure for domain errors and signal-aware exit codes. Where this differs from Python or TypeScript precedent, the report explicitly records `BASELINE-REVIEW` findings and the evidence that motivates the proposed alignment or justified divergence.

**Context and Background**
The owner’s mandate for this item emphasizes that error-handling designs must be chosen not merely for familiarity or performance, but for their ability to express and preserve shared engineering principles across the Python, TypeScript, and Rust ports of the launch blueprint. The relevant context documents that Python employs a stable string catalog for its error `code` field, exemplified by constants such as `ERROR_CODE_UNEXPECTED = "PLBP000"`, and that this catalog is append-only and documented for machine consumers.[Context, py repo] TypeScript, by contrast, currently derives its `code` field from the thrown exception’s class name, effectively using a transient identifier whose stability is tied to internal type naming rather than an explicit catalog; this decision was influenced by JavaScript’s exception model and the external CLI standards spec that guided exit codes and JSON error envelopes.[Context, ts repo] The divergence between these two approaches is recorded in the ledger items F295–F302 with verdict `DIVERGENT`, and this report must treat those entries as evidence rather than predetermined winners.

The Rust port sits within a defined parameter matrix: it targets Rust edition 2024 with a minimum supported Rust version of “stable minus two minor versions,” carries a dual MIT OR Apache-2.0 license, and must be CI-tested on `ubuntu-latest` and `macos-latest`.[PARAMETERS.md] Within this matrix, the template must support three surfaces—a CLI, a shared library crate, and a web service—while exposing a JSON error envelope on stderr in machine mode and controlling when stack traces are shown. The existence of the machine-readable error envelope and the rule that full stack traces are printed only under verbose or debug modes are settled and out of scope for this item; the focus is instead on the semantics of the envelope’s `code` field, the optional structured `hint` field, the exit-code taxonomy used when the process terminates, and the handling of signals, interactive prompt cancellation, broken pipes, and crash logging as they feed into or supplement that taxonomy.

The prior decisions of the TypeScript port provide key evidence about how a CLI-standards spec shaped exit codes and signal behavior. Decision D-016(2) reconciled source exit codes with an external R6.1 contract, yielding a taxonomy of `success/error/usage/notFound/auth/conflict/sigint/sigterm` mapped to numeric codes 0, 1, 2, 3, 4, 5, 130, and 143. In addition, the TypeScript port introduced an EPIPE handler to avoid crashes when downstream consumers close a pipe early and formalized a machine-output envelope where stdout carries a single JSON result document and stderr emits a compact error object with `code` and `message` fields in machine mode.[Context, ts decisions] Decision D-033 further refined the behavior of interactive prompts, ensuring that prompt interruption or stdin closure lead to exit code 130 with a clean message that does not leak internal library details.

Python’s precedent diverges in several respects. Its exit-code taxonomy, expressed as an `IntEnum` with variants such as `SUCCESS`, `CONFIG`, `AUTH`, `API`, `IO`, and `INTERRUPT` mapped to 0–5, favors domain categories over CLI-standards codes. Python handles `KeyboardInterrupt` by exiting with `ExitCode.INTERRUPT` (5) but does not distinguish `SIGTERM` separately, nor does it currently have an EPIPE handler or interactive multi-select cancellation semantics. Conversely, Python does implement crash-log persistence, writing unexpected error details to a best-effort crash log under a state directory (for example `plbp_crash.log` under `<state>/plbp`) as described in ADR 0006.[Context, py code] These differences are central to the baseline review and will be revisited when establishing principles and recommendations for the Rust template.

Given this background, the Rust design must be grounded in the ecosystem’s own idioms and tooling for error handling and signals—specifically crates like `thiserror`, `anyhow`, `ctrlc`, and `signal-hook`—while also respecting the owner’s scope boundaries for related contracts, such as R03’s absence-vs-failure behavior, R54–R56’s config error tolerance patterns, and R70’s HTTP problem envelope mapping. It is essential to articulate clearly which aspects of the error and exit-code contract must agree across languages, and which may vary to better match the differing ecosystems, while nonetheless preserving a coherent architectural story and machine interface for consumers.

**Main Bundle Analysis**

**Gemini (deep-research-preview-04-2026)**

**Error and Exit-Code Contract Implementation**

### Landscape

**OpenAI**

**Research date:** September 9, 2026.  
**Decision category:** a cross-surface **diagnostic protocol and process-lifecycle policy** for a Rust workspace containing a reusable library, CLI, and web service.

**Evidence-collection limitation:** the research browser could not directly retrieve several requested crates.io and GitHub JSON API endpoints. I report values corroborated by docs.rs, repository HTML, or registry mirrors and explicitly mark unavailable figures rather than fabricate 90-day downloads, `pushed_at`, or issue-response medians. The canonical commands to close those gaps are included under Validation strategy.

#### Three-bin field map

| Bin | Candidates found | Relevance |
|---|---|---|
| **Built-in / first-party toolchain** | `std::error::Error`, `Error::source`; `std::process::{ExitCode, Termination}`; `std::io::ErrorKind::BrokenPipe`; `std::backtrace::Backtrace`; panic hooks; `OpenOptions`; Rust/Cargo SemVer guidance | Sufficient for the catalog, exit enum, EPIPE classification, backtrace capture, and crash-file append. Stable Rust has no general signal-registration API, so SIGINT/SIGTERM need an external crate or runtime-specific adapter. Rust recommends returning a `Termination` value rather than calling `process::exit` early when cleanup matters. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026. |
| **Established industry choices** | `thiserror`, handwritten `Error`; `anyhow`/`eyre`; `miette`; SNAFU; `strum`; `signal-hook`; `ctrlc`; `clap`; `inquire`/`dialoguer`; `human-panic` | `thiserror` is the strongest fit for matchable library/domain errors; `miette` directly models diagnostic `code` and `help`; `signal-hook` provides safe signal-registration façades; `clap` establishes exit 2 for parser misuse; `inquire` demonstrates typed prompt cancellation. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026. |
| **Up-and-comers / narrower tools** | `error-stack`, `pipecheck`, `proc-exit`, dedicated SIGPIPE crates | Useful in specialized applications, but each adds a model beyond this bundle’s needs. `error-stack` emphasizes contextual reports; `pipecheck` restores signal-like EPIPE behavior. Neither removes the need for an explicit, governed catalog and mapping table. ([lib.rs](https://lib.rs/crates/error-stack)) Retrieved September 9, 2026. |

#### Authority used

1. **Rust Project sources:** standard-library documentation, Cargo SemVer guidance, Rust API Guidelines, RFC 2965, and the Rust SIGPIPE tracking work. These define language/API compatibility and runtime behavior rather than merely reporting third-party opinion. ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/interoperability.html)) Retrieved September 9, 2026.
2. **POSIX.1-2024 and GNU Bash:** authoritative for shell-observable process status. POSIX requires signal-derived statuses above 128; Bash uses `128 + signal`, yielding 130 for SIGINT and 143 for SIGTERM. ([gnu.org](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)) Retrieved September 9, 2026.
3. **Maintainer documentation:** `thiserror`, `miette`, `signal-hook`, `clap`, and `inquire` documentation establishes their actual APIs and behavior. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.
4. **Rust community evidence:** the 2025 State of Rust Survey is the Rust Project’s tenth annual survey; it is useful ecosystem context, though it does not select a particular error crate. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)) Retrieved September 9, 2026.
5. **Production-practice evidence:** `thiserror` is reported as used by tens of thousands of crates; Cargo and uutils have both had to treat closed-output/SIGPIPE behavior explicitly; current Rust work still considers global SIGPIPE policy unsettled. ([lib.rs](https://lib.rs/crates/thiserror)) Retrieved September 9, 2026.

#### Practice findings

- `thiserror` is the dominant typed-error derive: its generated implementations do not become part of the public API, and its documentation explicitly positions it for dedicated library error types. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.
- `miette` is the closest architectural alternative because `Diagnostic` has separate `code()` and `help()` methods. Its rich renderer is optional but introduces more presentation policy and feature weight than this core bundle needs. ([docs.rs](https://docs.rs/miette/latest/miette/)) Retrieved September 9, 2026.
- Rust currently ignores SIGPIPE at startup, causing writes to closed pipes to surface as `ErrorKind::BrokenPipe`; stable applications must therefore make output writes fallible or deliberately change signal policy. The latter remains under active Rust design work. ([github.com](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs)) Retrieved September 9, 2026.
- Different production workloads justify different EPIPE mechanisms: coreutils-like pure text producers often prefer signal-like termination, whereas a combined CLI/library/web-service process benefits from retaining Rust’s EPIPE error model and classifying only its CLI stdout boundary. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html)) Retrieved September 9, 2026.

**Perplexity**

The category this item decides can be described as “Rust error taxonomy and exit-code stack for a multi-surface template,” encompassing domain error modeling, application-level error propagation, process exit codes, signal handling, broken-pipe behavior, and crash-log capture. In Rust, this category spans both language-level constructs and community-standard crates. To follow the required survey method, the landscape must first be mapped into three bins: built-in or first-party toolchain features, established industry standards, and up-and-comers.

At the built-in or first-party level, Rust’s `Result<T, E>` type, `std::error::Error` trait, and common error types like `std::io::Error` form the foundation of all error handling. The Rust Patterns & Engineering How-Tos produced by Microsoft explicitly frame error handling patterns around `Result<T, E>` and the distinction between concrete error enums and trait-object based application errors.[6] These built-in pieces are non-negotiable: any crate-level or architectural choice must integrate with them. The standard library also provides the mechanisms that surface broken pipe errors as `io::Error` with `ErrorKind::BrokenPipe`, and signal behavior via POSIX semantics, though Rust’s default disposition for `SIGPIPE` differs from C programs in that it tends to translate `SIGPIPE` into `BrokenPipe` errors rather than killing the process.[General Rust docs] While Rust’s standard library offers only limited direct signal handling, the crates considered below build on the underlying OS APIs.

In the established industry-standard bin, the error-handling crates `thiserror` and `anyhow` stand out. The `thiserror` crate provides derive macros that implement `Display` and the `Error` trait for custom error types, along with useful attributes such as `#[error("...")]`, `#[from]`, and `#[error(transparent)]` to model error variants compactly and idiomatically.[1][3][4][15] It is designed for defining structured error types, particularly in library code, and is widely considered lightweight and zero-cost, generating code equivalent to what a developer would write manually.[4][15] The Rust FAQ emphasizes that `thiserror` “deletes the boilerplate,” allowing developers to focus on error taxonomy rather than glue code, and notes that it is stable and widely used in the ecosystem.[3] The `anyhow` crate complements `thiserror` by providing a single trait-object based error type (`anyhow::Error`) and a convenient `anyhow::Result<T>` alias for application errors; it is intended for binaries and CLI tools where the caller does not need to pattern-match on structured error variants.[2][4][6][7] The Rust FAQ and Microsoft’s Rust Patterns documentation both highlight the pairing of `thiserror` for libraries and `anyhow` for applications as a dominant pattern.[6][7]

In signal handling, the `ctrlc` crate has become an established standard for cross-platform `Ctrl-C` (SIGINT) handling in Rust applications.[5][9][10] Its `set_handler` function allows registering a closure that executes when the user presses Ctrl-C, and with the `termination` feature enabled it can also handle `SIGTERM` and `SIGHUP` on Unix.[5][9][10] This crate abstracts over platform-specific signal APIs, including Unix signals (`SIGINT`), Windows console control events (`CTRL_C_EVENT` and `CTRL_BREAK_EVENT`), and Apple’s dispatch mechanisms, providing a single API that works across operating systems.[10] For more comprehensive Unix signal handling, the `signal-hook` crate and its backend `signal-hook-registry` offer a global registry of actions for signal arrival.[16][17][12][19] `signal-hook-registry` is specifically described as the backend that multiplexes signals, ensuring that an application contains just one version of the crate to manage this global resource.[12] Signal-hook supports registering multiple actions for the same signal, chaining previous handlers, and providing helper actions for common use cases.[16][17][19] These crates are widely adopted in Unix-focused applications needing robust signal handling.

The up-and-comers bin contains more specialized or stylistic crates that build on or extend the basic patterns established by `thiserror` and `anyhow`. Examples include crates that provide richer diagnostic information (such as human-readable error reports with color and context) or alternative structured error modeling frameworks. While the present search results do not enumerate these explicitly, the existence of such crates is referenced indirectly in discussions that compare `thiserror` and `anyhow` to other solutions, emphasizing that the former focus on idiomatic error enums and trait-object errors rather than more elaborate diagnostic systems.[4][6] In signal handling, up-and-comer patterns include integrating signal-hook with async runtimes to process signals in asynchronous streams, as described in the rust-cli DeepWiki, which shows how to convert a `Signals` instance into an async stream and integrate it with `select!`-based logic in async applications.[8] These patterns are relevant primarily for web services or highly concurrent CLIs.

Regarding authoritative sources, the documentation for `thiserror` and `thiserror-impl` maintained by David Tolnay on docs.rs and on crates.io is authoritative, as it comes directly from the crate maintainer and describes the intended use, supported attributes, and version information.[1][4][11][14][15] The Rust FAQ entries on `thiserror` and `anyhow` are written for developers seeking guidance on idiomatic error handling and emphasize ecosystem norms, which makes them a strong authority on practice.[3][7] The Microsoft Rust Patterns & Engineering How-Tos are backed by Microsoft’s Rust engineering team and present well-considered patterns for error handling in production-grade Rust systems, explicitly recommending `thiserror` for libraries and `anyhow` for applications.[6] For signal handling, the `ctrlc` and `signal-hook` documentation on docs.rs and Lib.rs is authoritative, providing API descriptions, feature flags, and platform behavior.[5][9][12][16][17][19] The rust-cli DeepWiki’s section on signal handling is a widely cited independent write-up that synthesizes the usage of `ctrlc`, `signal-hook`, and related patterns in Rust CLI applications, which makes it a valuable practice-oriented source.[8]

Practice evidence about adoption must be weighed carefully. While full reverse-dependency lists and download counts require direct querying of crates.io APIs, the available data for `signal-hook-registry` shows that it has substantial monthly downloads (14,949,924 downloads per month as of the referenced Lib.rs page) and a recent release history, indicating active and widespread use.[12] The presence of `thiserror`, `anyhow`, `ctrlc`, and `signal-hook` in curated training materials (such as Microsoft’s patterns book and Google’s Comprehensive Rust course) and in Rust FAQs strongly suggests that these crates are part of mainstream, well-regarded practice.[1][4][6][7][8] Numerous open-source CLIs, web services, and libraries reference these crates in their documentation and code examples, although detailed adopter lists cannot be exhaustively enumerated within the constraints of the current search results. Nonetheless, the combination of maintainer documentation, educational material, and explicit ecosystem guidance forms a coherent picture: `thiserror` and `anyhow` dominate Rust’s structured error handling landscape, while `ctrlc` and signal-hook dominate signal handling in CLI and Unix-centric applications.

It is also crucial to judge candidates against the specific use case of `rs-launch-blueprint`: a template combining CLI, library, and web service surfaces. For such a template, the pairing of `thiserror` (for domain error enums exposed by the library and web service) and `anyhow` (for application-wide errors in the CLI) aligns with the recommended division of responsibility.[4][6][7] The need for cross-platform signal handling for a CLI that may run on Ubuntu and macOS makes `ctrlc` an appropriate choice; meanwhile, `signal-hook` is more relevant for advanced Unix-only scenarios or when multiple signals must be multiplexed with complex behavior.[5][8][16][17] Broken pipe handling relies primarily on the standard library’s behavior and patterns like checking `io::Error::kind()` against `ErrorKind::BrokenPipe`, as referenced in Rust CLI treatises.[8] Crash-log persistence does not require external crates beyond those already used for filesystem access, but it must integrate with any state directory decisions made elsewhere in the template (R57).

Collectively, this landscape situates `rs-launch-blueprint` as a consumer of both built-in error and signal primitives and a stack of established crates—primarily `thiserror`, `anyhow`, and `ctrlc`, with optional `signal-hook` for more advanced scenarios. The next sections will articulate the cross-repo principles and implementation patterns that this stack must satisfy, including the shape of the error code catalog and the exit-code taxonomy.

**Gemini**

The architectural mandate for the `rs-launch-blueprint` repository necessitates a rigorous categorization of the Rust ecosystem concerning error handling, signal routing, and process termination. Identifying the optimal libraries requires mapping the domain into three distinct tiers: built-in toolchain capabilities, established industry standards, and emerging up-and-comers. The selection methodology enforces a strict reliance on authoritative sources, empirical practice evidence from well-regarded projects, and a localized fitness evaluation against the unique hybrid requirements of a CLI, library, and web service architecture.

The categorization of the Rust error and exit-code ecosystem reveals the following landscape:

| Category | Candidates | Role in Architecture |
| :--- | :--- | :--- |
| **Built-in or first-party toolchain** | `std::error::Error`, `std::io::ErrorKind`, `std::panic::set_hook`, `std::process::exit` | Provides the foundational traits, standard input/output failure modes, and low-level process termination routines without external dependencies. |
| **Established industry standard** | `thiserror`, `anyhow`, `signal-hook`, `strum` | Defines the dominant paradigms for library-level error modeling, safe POSIX signal interception, and compile-time string serialization. |
| **Up-and-comer** | `miette`, `human-panic`, `crashreport`, `snafu` | Introduces rich diagnostic formatting, machine-readable JSON envelopes, and user-friendly crash log persistence mechanisms. |

Authority within this domain is established through official Rust documentation, Rust compiler design requests for comments (RFCs), and the outputs of the official Rust CLI Working Group. The CLI Working Group's official publications explicitly recommend `signal-hook` for comprehensive UNIX signal management over alternatives that only handle single signals [cite: 1, 2]. Furthermore, Microsoft's official Rust Patterns Book establishes the authoritative divide between `thiserror` for library development and `anyhow` for top-level application error propagation [cite: 3]. These sources collectively dictate the idiomatic boundaries for error modeling in modern Rust applications.

Practice evidence demonstrates a clear consensus among well-regarded Rust projects. High-performance, widely distributed command-line utilities and language servers rely heavily on `thiserror` to define precise, matchable error variants, cementing its status as the standard for library boundaries [cite: 3, 4, 5]. Modern diagnostic-heavy tools, such as the Oxc JavaScript toolchain, have uniformly adopted `miette` to supply structured help text, diagnostic codes, and source-span visualization, alongside machine-readable JSON reporting [cite: 6, 7]. Projects requiring safe, race-free `SIGINT` and `SIGTERM` interception universally employ `signal-hook` [cite: 8, 9]. Finally, polished user-facing applications routinely adopt `human-panic` to gracefully intercept unexpected panics and write structured dump files without exposing raw, intimidating stack traces directly to the console [cite: 10].

The evaluation prioritizes fitness for the specific `rs-launch-blueprint` template over abstract superiority. The hybrid nature of the template—functioning simultaneously as a command-line interface, an embeddable library, and a web service—invalidates candidates that optimize for only one surface. For instance, application-level type-erasing wrappers like `anyhow` are rejected because the library component and web service router (R70) require exhaustive pattern matching over domain errors [cite: 3, 11]. The command-line surface demands rich terminal output, while the machine-driven execution paths mandate deterministic JSON envelopes [cite: 7]. This multidimensional use case strictly filters the landscape to a precise combination of strongly typed error modeling, dynamic string catalog generation, and decoupled diagnostic rendering.

### Principles and implementation

**OpenAI**

#### Shared requirement and agreement level

The shared principle is:

> **Machine-facing error identity and process outcomes are protocol values, independent of implementation type names and presentation text; human remediation, diagnostics, and ecosystem-specific capture mechanisms remain separate layers.**

That principle follows from F294’s settled machine envelope, F301’s settled trace-disclosure rule, and the observed F295–F302 divergence supplied by the owner.

| Concern | Required agreement level across py/ts/rs | May vary by ecosystem |
|---|---|---|
| Error identity | **Standard:** documented, stable, append-only wire strings | Python class hierarchy, TypeScript tagged union/class, Rust enum/trait |
| Message vs remedy | **Schema/policy:** concise `message`; optional separate `hint` | Human styling, colors, labels |
| Exit statuses | **Low-level process standard:** 0/1/2/3/4/5/130/143 meanings | How each runtime reports or returns them |
| SIGINT/SIGTERM | **Observable capability:** clean cancellation, 130/143 | Python exceptions, Node signals, Rust signal adapter |
| Prompt cancellation | **Observable capability if prompts exist:** no library-internal text, status 130 | Typed prompt errors versus process signal |
| EPIPE | **Observable capability:** expected early pipe closure is silent and non-crashing | Node stream handler versus Rust fallible writes |
| Unexpected-error persistence | **Process-boundary policy:** best-effort sanitized crash record | Filesystem API and platform state-directory provider |
| Stack traces | **Disclosure policy:** user-visible only under verbose/debug | Capture mechanism, pending F301 disposition |

This makes the recommendation a deliberate hybrid: Python supplies the stronger stable-code, hint, and crash-persistence ideas; TypeScript supplies the stronger shell status, SIGTERM, prompt-cancellation, and EPIPE behaviors. Neither language’s concrete mechanism is transplanted into Rust.

#### Architectural alternatives

| Alternative | Assessment |
|---|---|
| Derive wire code from a Rust variant name, discriminant, `Debug`, or type name | **Reject.** Renaming/refactoring changes the machine protocol accidentally. Numeric discriminants also conflate ABI/layout choices with protocol identity. |
| Explicit `ErrorCode` enum with manually declared wire strings | **Choose.** Rust code can match semantic variants while `as_str()` supplies a separately governed wire value. |
| Dynamic string codes carried by each error | Flexible but permits typos and incomplete mappings; no compiler coverage. Reject as the catalog’s source of truth. |
| `miette::Diagnostic` as the core abstraction | Qualified alternative: it directly supports codes and help, but its code is a dynamic `Display` value and its diagnostic/reporting layer is broader than the CLI/library/web contract needs. |
| `anyhow`/`eyre` throughout | Suitable only after an error is no longer expected to be handled. Erasing R03/R52–R56/R70 errors early would defeat typed downstream mapping. RFC 2965 similarly distinguishes structured error kinds from final reporting types. ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html)) Retrieved September 9, 2026. |

#### Public append-only catalog versus Rust exhaustiveness

Rust cannot simultaneously promise both:

1. semver-compatible addition of public enum variants, and
2. exhaustive external matches that continue compiling unchanged.

Cargo documents adding a variant to an exhaustive public enum as breaking; `#[non_exhaustive]` is the standard mitigation. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html)) Retrieved September 9, 2026.

Therefore:

- `ErrorCode` is a **public `#[non_exhaustive]` enum**.
- A single `macro_rules!` catalog declaration generates:
  - the variants;
  - explicit wire strings;
  - `ErrorCode::ALL`;
  - `as_str()`;
  - `Display`;
  - the exit-code mapping.
- Mappings inside the defining crate remain compiler-exhaustive.
- Cross-crate mappings such as R70 must be coverage-tested by iterating `ErrorCode::ALL`.
- `strum` is not required. It would reduce boilerplate but would not establish append-only governance, collision checks, documentation, or mapping coverage.

The envelope’s `code` is populated **only** by `ErrorCode::as_str()`. It must never use `std::any::type_name`, enum `Debug`, default serde variant naming, a `thiserror` message, or a discriminant.

#### Initial catalog

Before implementation, compare these proposed new allocations against the complete existing Python append-only codebook. `PLBP000` is already fixed by owner evidence; no occupied Python code may be reassigned.

| Rust variant | Wire code | Meaning | Default CLI exit |
|---|---:|---|---:|
| `Unexpected` | `PLBP000` | Unclassified internal failure | 1 |
| `Usage` | `PLBP100` | Invalid CLI syntax, option, argument, or command usage | 2 |
| `ConfigNotFound` | `PLBP200` | A configuration path that must exist does not | 2 |
| `ConfigRead` | `PLBP201` | A surfaced configuration layer cannot be read | 2 |
| `ConfigParse` | `PLBP202` | A surfaced configuration document is syntactically invalid | 2 |
| `ConfigInvalid` | `PLBP203` | Parsed configuration violates the application schema or constraints | 2 |
| `ConfigSecretDisallowed` | `PLBP204` | A secret was supplied through a prohibited configuration channel | 2 |
| `AuthRequired` | `PLBP300` | Required credentials are absent | 4 |
| `AuthRejected` | `PLBP301` | Supplied credentials were rejected | 4 |
| `ResourceNotFound` | `PLBP400` | The requested domain resource does not exist | 3 |
| `Conflict` | `PLBP401` | Current state conflicts with the requested operation | 5 |
| `Transport` | `PLBP500` | DNS, connection, timeout, TLS, or equivalent transport failure | 1 |
| `RemoteApi` | `PLBP501` | Remote service returned a non-auth, non-not-found application failure | 1 |
| `Io` | `PLBP600` | Non-configuration filesystem or stream I/O failure | 1 |
| `BrokenPipe` | `PLBP601` | Broken pipe outside the benign successful-stdout case | 1 |
| `Interrupted` | `PLBP700` | Process received SIGINT/Ctrl-C | 130 |
| `Terminated` | `PLBP701` | Process received SIGTERM | 143 |
| `PromptCancelled` | `PLBP702` | Interactive prompt was interrupted, cancelled, or reached closed stdin | 130 |

Catalog rules:

- Existing wire strings are never renamed, reassigned, or deleted.
- A retired code remains documented as deprecated.
- New entries require a meaning, default exit class, documentation, and mapping tests.
- Message and hint wording may evolve without changing the code.
- Machine consumers branch on `code`, never `message` or `hint`.

#### Typed error layout

Use domain-specific enums rather than one unconstrained mega-enum:

```rust
use std::{borrow::Cow, error::Error};
use thiserror::Error;

pub trait CodedError: Error + Send + Sync + 'static {
    fn code(&self) -> ErrorCode;

    fn hint(&self) -> Option<Cow<'_, str>> {
        None
    }
}

#[derive(Debug, Error)]
pub enum ConfigError {
    #[error("configuration file does not exist")]
    NotFound { path: std::path::PathBuf },

    #[error("configuration is invalid")]
    Invalid { reason: String },
}

impl CodedError for ConfigError {
    fn code(&self) -> ErrorCode {
        match self {
            Self::NotFound { .. } => ErrorCode::ConfigNotFound,
            Self::Invalid { .. } => ErrorCode::ConfigInvalid,
        }
    }

    fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::NotFound { path } =>
                Some(format!("create or correct {}", path.display()).into()),
            Self::Invalid { .. } =>
                Some("correct the invalid configuration value".into()),
        }
    }
}
```

`thiserror` owns `Display`, `source()`, and conversion boilerplate; the project-owned trait owns protocol metadata. `Unexpected` must display a sanitized generic message while retaining its source for verbose diagnostics and crash recording. `thiserror` supports concrete source chains and transparent wrappers without changing the public error representation. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.

#### Envelope and hint

Machine mode:

```json
{
  "error": {
    "code": "PLBP203",
    "message": "configuration is invalid",
    "hint": "correct the invalid configuration value"
  }
}
```

Rules:

- `hint` is optional and omitted when absent, rather than serialized as `null`.
- Human output renders it as a separate `hint:` block.
- JSON preserves it as a separate string field.
- A hint is actionable but not stable machine identity.
- Source chains and backtraces are not serialized into this envelope.
- Error stdout remains empty; stderr contains exactly one JSON document.

This follows the same semantic separation exposed by `miette::Diagnostic::code()` and `help()`, without adopting its renderer as core architecture. ([docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)) Retrieved September 9, 2026.

#### Exit taxonomy

```rust
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
#[repr(u8)]
pub enum CliExitCode {
    Success = 0,
    Failure = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    SigInt = 130,
    SigTerm = 143,
}
```

Meaning:

- **0:** success, help/version, or benign stdout EPIPE after a downstream consumer closes early.
- **1:** unexpected, remote/API/network, general I/O, and other operational failure.
- **2:** parser misuse or a surfaced configuration failure.
- **3:** requested domain resource absent.
- **4:** credentials absent or rejected.
- **5:** domain/state conflict.
- **130:** SIGINT, Ctrl-C prompt interruption, prompt cancellation, or closed prompt stdin.
- **143:** SIGTERM.

This is preferable to Python’s `INTERRUPT=5`: exit 5 is useful as a domain conflict class, while 130 and 143 are recognizable shell conventions. It also aligns with `clap`, which reports parser failures as 2, and with POSIX/Bash’s signal-status conventions. ([docs.rs](https://docs.rs/clap/latest/clap/error/struct.Error.html)) Retrieved September 9, 2026.

Return `CliExitCode` through `Termination` or convert it to `std::process::ExitCode` from the top-level function. Do not call `process::exit` before crash-log flushes and other cleanup have completed. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026.

#### SIGINT and SIGTERM

- Install handlers only in executable entrypoints, never in the library.
- On Ubuntu and macOS, use `signal-hook` to distinguish SIGINT from SIGTERM.
- Handler-side work is restricted to signal-safe notification; rendering, allocation, logging, and filesystem writes occur after normal control resumes.
- The first signal requests cooperative cancellation.
- The top-level boundary converts SIGINT to `PLBP700`/130 and SIGTERM to `PLBP701`/143.
- A web-service runtime may use its own maintained signal adapter, such as its async runtime’s signal module, but must return the same contract values.

`signal-hook` explicitly documents the global and async-signal-safety hazards and supplies safe higher-level flag/iterator mechanisms. ([docs.rs](https://docs.rs/crate/signal-hook/latest)) Retrieved September 9, 2026.

#### Prompt cancellation

F299 is contingent on R61.

If R61 selects `inquire`, map:

- `InquireError::OperationInterrupted` → `PromptCancelled`, exit 130;
- `InquireError::OperationCanceled` → `PromptCancelled`, exit 130;
- prompt EOF/closed stdin → `PromptCancelled`, exit 130;
- `InquireError::IO(e)` → normal I/O classification unless the global signal token records SIGINT.

`inquire` explicitly distinguishes cancellation from Ctrl-C interruption; with its `console` backend, Ctrl-C can instead arrive as SIGINT, so both typed-error and process-signal paths are required. ([docs.rs](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html)) Retrieved September 9, 2026.

Never match an error’s display text or type-name string.

#### Broken pipe

Use fallible `Write` calls throughout output renderers; do not use `println!`/`eprintln!` for potentially large or piped output.

```rust
match render_success(&mut stdout, value) {
    Ok(()) => CliExitCode::Success,
    Err(e) if e.kind() == std::io::ErrorKind::BrokenPipe => {
        CliExitCode::Success
    }
    Err(e) => {
        render_error(AppError::output(e));
        CliExitCode::Failure
    }
}
```

Specific rules:

- Successful stdout `BrokenPipe` is silent and exits 0.
- No secondary stderr diagnostic is emitted for that case.
- A broken pipe on another application stream maps to `PLBP601`/1.
- If writing an already-selected error envelope to stderr fails with EPIPE, retain the original application exit status.
- Do not globally restore SIGPIPE in the combined CLI/library/web template. Rust’s stable default deliberately exposes EPIPE, and its broader SIGPIPE policy remains unsettled. ([doc.rust-lang.org](https://doc.rust-lang.org/std/io/enum.ErrorKind.html)) Retrieved September 9, 2026.

#### Crash-log persistence

Adopt a process-boundary `CrashSink`:

- Fatal CLI/startup `Unexpected` errors are offered to the sink before rendering.
- The default executable uses a file sink when R57 supplies a state directory.
- The path is `<state-dir>/crash.log`; this item does **not** hard-code `~/.local/state`, macOS Library paths, or a temporary-directory fallback.
- Failure to create, serialize, append, or permission the file is silently ignored and never changes the primary envelope or exit status.
- Use newline-delimited JSON and restrictive Unix permissions (`0600`).
- Store timestamp, application version, PID, stable code, sanitized source chain, and optionally a backtrace.
- Do not store argv, environment variables, headers, tokens, configuration contents, or secret values by default.
- Routine expected domain errors and per-request HTTP errors do not create crash records.
- A binary panic hook may reuse the sink, but panic exit semantics remain Rust’s panic semantics unless a separate owner decision adopts `catch_unwind`.

This retains Python’s diagnostic-survival principle without making the reusable library perform filesystem I/O.

#### Performance assessment

No throughput benchmark was run, because the selected mechanisms execute primarily on errors or signals:

- `thiserror` generates ordinary trait implementations; runtime cost is equivalent to handwritten implementations.
- Catalog lookup is an exhaustive `match` over a small copyable enum.
- EPIPE handling adds one branch only on a failed write.
- Crash persistence is off the success path.
- `signal-hook::iterator` can consume one helper thread; a polling flag adapter can avoid it when all operations already support bounded polling.

The relevant future measurements are incremental compile time, release-binary size, idle helper-thread cost, signal-to-cancellation latency, and crash-write latency. No “fastest” claim is made from unrelated benchmarks.

#### Observable acceptance criteria

1. Every domain error has exactly one stable catalog code and default CLI exit.
2. Existing wire strings cannot disappear or change meaning without a failing catalog snapshot test.
3. Every `ErrorCode::ALL` member has an exit mapping; R70 later supplies a corresponding HTTP coverage test.
4. Renaming a Rust enum variant does not alter JSON output.
5. JSON errors emit exactly one stderr document and no stdout.
6. Hints are separate in both human and JSON formats.
7. Parser misuse exits 2; not-found 3; auth 4; conflict 5; SIGINT 130; SIGTERM 143.
8. Prompt cancellation exits 130 without prompt-crate internals.
9. `producer | head` causes no panic, no EPIPE diagnostic, and producer status 0.
10. Fatal unexpected errors create a sanitized best-effort crash record when a state directory is available.
11. Library-only tests prove that importing the library installs no signal or panic hooks and writes no process streams/files.

`BASELINE-REVIEW: F295 — machine identity is a protocol value, not an exception/type name — proposed change: migrate the TypeScript follow-on from err.name to the shared explicit catalog; Python already satisfies the principle — evidence: Rust typed-error guidance, Cargo SemVer constraints, and miette’s separately documented diagnostic codes.`

`BASELINE-REVIEW: F298 — process interruption must compose with shell automation — proposed change: migrate Python’s interrupt status from 5 to 130 and add SIGTERM 143; affects Python shell-status consumers — evidence: POSIX.1-2024 and GNU Bash 128+signal behavior.`

`BASELINE-REVIEW: F301 — diagnostic capture and diagnostic disclosure are separate policies — proposed change: provisionally use Backtrace::force_capture only for PLBP000 when verbose/debug or crash persistence is active, and never serialize a trace in JSON; affects R66 and R67; owner disposition remains pending — evidence: Backtrace::capture can be disabled by environment, whereas force_capture ignores those variables.` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html)) Retrieved September 9, 2026.

**Perplexity**

The shared requirement across Python, TypeScript, and Rust ports can be stated as follows: the launch blueprint must expose a consistent, machine-readable classification of failures that is stable over time, append-only, and documented, and that can be observed both in its JSON error envelope and in its process exit codes. This classification must separate human-facing messages from machine-facing codes, allow downstream consumers to pattern-match on logical error categories (for example configuration errors, authentication failures, resource absence, and transport failures), and provide predictable behavior for interrupts (Ctrl-C / SIGINT), termination signals (SIGTERM), interactive-prompt cancellation, broken pipes, and unexpected errors that warrant crash-logs. The agreement level is architectural pattern and policy rather than identical implementation detail: each ecosystem may use different language constructs and libraries, but must preserve the same high-level contract.

The essential behaviors, distilled from the context, are as follows. First, there must be a JSON error envelope on stderr in machine mode, containing at least a `code` field, a `message` field, and optionally a structured `hint` field that provides remedial guidance separate from the core error message. Python already implements such a separation, storing `self.hint` and rendering it separately from the message in CLI output.[Context, py code] TypeScript embeds remedy text directly into the error message and currently does not expose a separate `hint` field, though its JSON envelope includes an `error.code` and `error.message` structure.[Context, ts code] Second, there must be a stable error-code catalog whose codes are append-only and documented. Python uses strings like `PLBP000` for this purpose; TypeScript uses exception class names, which are stable only insofar as the class names are not changed. Third, a defined exit-code taxonomy must map logical error categories to numeric exit codes, including specific codes for `success`, `usage/config errors`, `notFound`, `auth`, `conflict`, and signal-induced termination (SIGINT and SIGTERM). The TypeScript port already adheres to an external CLI standards spec for these codes, adopting 0 for success, 1 for generic errors, 2 for usage, 3 for not found, 4 for auth, 5 for conflict, 130 for SIGINT, and 143 for SIGTERM.[Context, ts decisions] Python’s taxonomy differs, using an `IntEnum` with domain-focused codes 0–5, but lacking separate codes for SIGINT/SIGTERM beyond `INTERRUPT`.[Context, py code]

Fourth, the system must handle interrupts and signals deterministically. Ctrl-C during normal CLI operation must lead to a well-defined exit code (preferably 130, in line with Unix conventions and CLI standards), and SIGTERM, if relevant, must either be mapped to its own code (143) or be treated equivalently to SIGINT depending on the application’s operational model. Fifth, interactive prompt cancellation—such as ^C mid-prompt—must behave similarly to SIGINT, with exit code 130 and a clean message that reveals no internal library details, aligning with TypeScript’s D-033 decision. Sixth, broken pipe scenarios (EPIPE) must be handled so that downstream pipe readers can close early without causing a crash or noisy error output; the usual pattern is to treat writing to a closed pipe as an expected scenario and exit cleanly, often with code 0, or to suppress error reporting for broken pipes entirely. TypeScript achieves this by listening to `stdout` error events and ignoring EPIPE.[Context, ts code] Rust’s idiom, as documented in rust-cli resources, is to check for `ErrorKind::BrokenPipe` and avoid panic or noisy logging in that case.[8] Finally, unexpected errors must be persisted to a crash-log file as a best-effort record, preferably in a state directory determined by R57’s `xdg-directory-set` decision, following Python’s ADR 0006 precedent.[Context, py ADR]

These behaviors constitute the acceptance criteria for the Rust implementation. The Rust template must expose a stable error-code catalog accessible from domain error variants, map those codes to a documented exit-code taxonomy aligned with the CLI standards spec where appropriate, handle SIGINT and SIGTERM with specific codes using idiomatic Rust signal handling crates, detect and map interactive prompt cancellation to exit code 130, recognize broken pipe errors and suppress spurious reporting, and persist unexpected errors to a crash-log file when possible. Observable acceptance criteria include the ability for downstream items—R03’s absence/failure contract, R52–R56’s config error handling, and R70’s HTTP status mapping—to pattern-match on a well-defined set of error variants and codes, and for automated tools to rely on exit codes for control flow.

Within this framework, we must define the shape of the error code catalog in Rust. The central question is whether the `code` field in the JSON envelope should be a stable string catalog (like Python’s `PLBP000`) or a value derived from a Rust error enum’s variant name or discriminant, akin to TypeScript’s exception class name. A stable string catalog has the advantage of being explicitly documented, language-agnostic, and decoupled from internal naming; it can remain stable even if the Rust enum is refactored, provided the code strings are not changed. This aligns with Python’s approach and with general practices in API design, where error codes are treated as part of the public contract. Conversely, deriving codes from enum variant names or discriminants risks accidental changes when refactoring and ties the codes to Rust-specific naming conventions, making cross-language reuse harder.

Rust’s ecosystem, however, favors strongly typed error enums with derive macros. The `thiserror` crate allows us to define enums with distinct variants, each annotated with an error message and optionally `#[from]` attributes for automatic conversion from inner error types.[1][3][4][15] It also supports transparent wrapping of inner errors when we want to preserve their display and source. The Rust FAQ suggests using `thiserror` for library error types in order to define clear, expressive error models that callers can pattern-match on.[3][4] Therefore, the architectural pattern that best preserves cross-repo principles is to adopt a stable string code catalog, but attach those codes as properties of a typed Rust error enum. This can be implemented by defining a dedicated `ErrorCode` type (for example a newtype around a string) and associating it with each variant of a domain error enum via methods or attributes. `thiserror` can supply the `Error` and `Display` implementations, while additional traits or helper functions expose the code string for use in the JSON envelope and exit-code mapping.

On the application side, the `anyhow` crate is the idiomatic choice for errors in binaries. It provides `anyhow::Error`, which can wrap any error that implements `std::error::Error`, allowing the `?` operator to propagate errors without additional glue code.[2][6][7] Its `anyhow::Result<T>` alias simplifies function signatures. The Rust FAQ notes that `anyhow::Error` functions like a universal adapter, wrapping errors from various sources and presenting a uniform interface.[7] In our context, the CLI entrypoint can use `anyhow::Result<()>` and convert domain errors into the structured JSON envelope and exit-code taxonomy, while unexpected errors (for example those not matching the domain enum) are treated as crash-worthy, recorded in a crash-log, and mapped to a generic error code and exit code 1.

Signal handling in Rust must be implemented using established crates like `ctrlc` or `signal-hook`. The `ctrlc` crate provides cross-platform handling of Ctrl-C via `set_handler`, starting a dedicated signal-handling thread to execute the registered closure on `SIGINT`.[5][9][10] When the `termination` feature is enabled, the same handler also runs on `SIGTERM` and `SIGHUP` on Unix.[5][9][10] The rust-cli DeepWiki recommends patterns such as using an `Arc<AtomicBool>` shared between threads and setting it to `true` in the signal handler, while periodically checking it in application loops to initiate graceful shutdown.[8] For applications that need to handle multiple signals in a more granular way, the `signal-hook` crate allows registering multiple actions per signal, chaining previous handlers, and removing handlers via IDs.[16][17][19] For `rs-launch-blueprint`, which is primarily a CLI template rather than a long-running daemon, the simpler `ctrlc` pattern suffices and aligns with cross-platform constraint, while `signal-hook` can be considered an up-and-comer for future web-service extension scenarios.

Broken pipe handling relies primarily on the standard library. As described in Rust CLI documentation, one idiom is to create a bounded channel and set up a signal handler that sends a message when a signal is received, selecting between normal work and signal events.[8] For broken pipes, however, the pattern is simpler: check whether write operations to `stdout` or `stderr` fail with `ErrorKind::BrokenPipe` and, if so, exit cleanly without printing an error message. This ensures that downstream tools like `head` can close the pipe early without causing the CLI to emit noisy failure output or crash. Node’s default behavior requires an explicit EPIPE handler, whereas Rust’s translation of `SIGPIPE` to `BrokenPipe` exceptions moves the logic into error handling rather than signal handling. 

Crash-log persistence must integrate with the template’s state-directory decisions. Python’s ADR 0006 defines a crash-log file under a state directory, and the Python CLI writes unexpected errors there as a best-effort append.[Context, py ADR] Rust can follow the same principle by using a function that locates the state directory (the answer to R57, or a default path if R57 is not yet decided), constructing a crash-log file path, and writing serialized error information when unexpected errors occur. This crash-log writer should be robust to IO failures (for example, it should fail silently if the directory is not writable) and should never prevent the process from exiting. The existence of this mechanism, rather than the precise path, is the principle that must be preserved.

Finally, it is necessary to distinguish shared architectural patterns from permissible ecosystem differences. The shared pattern is a stable error-code catalog, a JSON error envelope, a documented exit-code taxonomy, and specific behaviors for signals, interactive cancellation, broken pipes, and crash logs. Ecosystem differences may include the physical representation of codes (strings vs enum names), the precise numeric values chosen for exit codes, or the use of dynamic error types vs structured enums. For `rs-launch-blueprint`, adopting Python’s stable string catalog shape with Rust’s typed error enums and TypeScript’s CLI-standards exit codes is a way to reconcile these differences while preserving the shared principles. This leads to several baseline-review findings, which will be stated explicitly:

BASELINE-REVIEW: F295 — error code field shape — proposed change: adopt a stable, documented string catalog across all three ecosystems, rather than deriving codes from exception class names, while allowing Rust to express codes as typed properties on error enums; evidence: Python’s explicit catalog (`PLBP000` etc.) and the CLI standards’ emphasis on stable machine codes, contrasted with TypeScript’s use of exception names, which are less robust as a public interface.

BASELINE-REVIEW: F296 — structured hint field — proposed change: preserve Python’s separate `hint` field as a cross-ecosystem principle and extend TypeScript to adopt a structured hint alongside message, recognizing that inline remedy text conflates human-readable message with machine-readable guidance; evidence: Python’s separation of hint rendering in CLI output and the benefits of allowing different output formats (for example JSON vs human) to treat hints differently.

BASELINE-REVIEW: F297/F298/F299/F300/F302 — exit codes, interrupt handling, interactive cancellation, broken pipes, crash logs — proposed change: align Rust with TypeScript’s CLI-standards numeric exit codes for success, usage, not-found, auth, conflict, and signals, while preserving Python’s crash-log persistence principle as a cross-ecosystem behavior and adding broken pipe handling similar to TypeScript’s EPIPE suppression; evidence: TypeScript’s D-016(2) and D-033 decisions, Python’s ADR 0006, and typical Unix CLI conventions for exit codes 130 and 143.

These principles and baseline reviews frame the recommendations in the next sections.

**Gemini**

The cross-ecosystem engineering principle bridging `py-launch-blueprint`, `ts-launch-blueprint`, and the proposed `rs-launch-blueprint` dictates that a system's error and termination contract must be fully deterministic, machine-parsable, and observable. Downstream consumers must be able to rely on a stable taxonomy of error codes and exit statuses, regardless of whether the failure stems from a domain logic violation, an operating system signal, or an unhandled hardware pipeline closure. 

The evaluation of the specific divergence points between the Python and TypeScript implementations reveals where Rust must align architecturally, and where language-specific idioms necessitate a novel approach.

The error envelope's "code" field (F295) presents a fundamental divergence. The Python implementation utilizes a stable, append-only string catalog (e.g., `PLBP000`), whereas the TypeScript port transiently yields the dynamic exception class name [cite: 12]. The shared principle is that automated systems must be able to reliably parse the error identity. Rust enforces strong typing, fundamentally rejecting the dynamic transient nature of TypeScript's exceptions. The architectural resolution leverages `thiserror` to model errors as strongly typed enums, and subsequently utilizes the `strum` macro library to generate stable, static strings directly from the enum variants at compile time [cite: 13]. This synthesis fulfills Python's append-only string stability while surpassing TypeScript's programmatic type safety.

The requirement for a structured hint field (F296) dictates that remedy text must be decoupled from the primary error message. Python achieves this via an explicit `self.hint` field rendered separately, while TypeScript compromises by inlining remedy text into the primary message string. The Rust implementation preserves the superior Python principle by adopting the `miette` diagnostic framework. `miette` natively implements a `#[help]` attribute attached to error variants, decoupling the hint structurally and projecting it seamlessly into both advanced console formatting and structured JSON envelopes [cite: 7, 12].

The exit-code taxonomy (F297) requires reconciling Python's narrow 0-5 mapping with TypeScript's broader 0-5, 130, 143 mapping, which was adopted to align with external command-line interface standards. The Rust template adopts the comprehensive TypeScript taxonomy (0, 1, 2, 3, 4, 5, 130, 143). Standard POSIX `sysexits` (codes 64-78) are explicitly rejected, as they force arbitrary modern network and authentication errors into antiquated mail-server and network-routing categories [cite: 14, 15]. The adopted taxonomy maps Rust's distinct internal failure states deterministically: `std::io` system failures map to exit code `5` (IO), network or transport failures map to `1` (API/Network), missing authentication configurations map to `4` (Auth), resource absence maps to `3` (NotFound), and parser or argument failures map to `2` (Usage).

Process interrupt handling and prompt cancellation (F298, F299) govern the application's response to `SIGINT` (Ctrl-C) and `SIGTERM`. TypeScript correctly isolates `SIGINT` (exit code 130) and `SIGTERM` (exit code 143) while gracefully exiting interactive prompts without a hard crash. The Rust architecture utilizes `signal-hook` to globally catch `SIGINT` and `SIGTERM` asynchronously [cite: 8, 9]. If the interactive prompts module (R61) adopts the `inquire` crate, a secondary mechanism naturally surfaces. The `inquire` crate natively traps `Ctrl-C` during a prompt and surfaces an `InquireError::OperationInterrupted` variant [cite: 16]. This specific typed error is routed through the domain error enum, securely mapping to exit code 130, eliminating the need to concurrently poll atomic signal flags during a blocking terminal prompt read.

Broken-pipe handling (F300) highlights a significant divergence in runtime environments. When a downstream pipe reader (such as the UNIX `head` utility) closes early, the operating system sends a `SIGPIPE` signal. Node.js traditionally requires explicit `error` event listeners on the `stdout` stream. Conversely, the Rust standard library suppresses the `SIGPIPE` signal handler at process initialization. Instead of receiving a signal, writes to a closed standard output stream return a standard `std::io::Error` with the `std::io::ErrorKind::BrokenPipe` designation [cite: 17, 18]. The idiomatic Rust architectural pattern is to explicitly match this `ErrorKind` during output operations and execute a silent `std::process::exit(0)`, matching standard UNIX command-line convention without generating a panic trace [cite: 18, 19].

The persistence of unexpected errors to a crash-log file (F302) preserves Python's ADR 0006 mandate. The `human-panic` library perfectly realizes this capability in Rust. It shields the end-user from intimidating, raw `unwrap()` dumps while writing a deterministic, machine-readable TOML or plain-text log containing the execution environment, operating system details, and the full backtrace [cite: 10]. The library assumes the existence of an operating system-agnostic temporary directory, but the architecture overrides this default to target the standardized XDG state directory managed by the R57 parameters.

`BASELINE-REVIEW: F301 — stack trace verbosity — explicitly defined capture and machine-mode suppression — the current baseline assumes stack traces are hidden unless verbose; miette captures spans automatically, but deep system backtraces require RUST_BACKTRACE (or RUST_LIB_BACKTRACE) alignment with standard Rust behaviors. JSON rendering natively suppresses deep trace arrays unless explicitly serialized, satisfying the machine-mode constraints without compromising human-readable verbosity.`

### Recommendation

**OpenAI**

Adopt the **Typed Contract + Boundary Adapters** stack:

```toml
[dependencies]
thiserror = "2.0.20"

[target.'cfg(unix)'.dependencies]
signal-hook = { version = "0.4.4", default-features = false, features = ["iterator"] }
```

Plus a project-owned stable-Rust contract layer using:

- an explicit macro-generated `ErrorCode` catalog;
- domain-specific `thiserror` enums implementing `CodedError`;
- a separate `CliExitCode`;
- `std::process::Termination`;
- fallible `Write` and `ErrorKind::BrokenPipe`;
- an injected, best-effort `CrashSink`;
- `std::backtrace::Backtrace`, subject to the F301 disposition.

Do **not** add `strum`, `miette`, a dedicated exit-code crate, a SIGPIPE crate, or `human-panic` to the base template. They either duplicate a small governed mapping or couple the core library to a broader reporting policy.

**Perplexity**

The recommended stack for `rs-launch-blueprint` can be summarized as a single cohesive design that combines error modeling, exit codes, signal handling, and crash logging. At its core, the Rust template should adopt a stable, append-only string error-code catalog, analogous to Python’s `PLBP000` pattern, but represented in Rust as a dedicated `ErrorCode` type and associated with a typed domain error enum that derives `thiserror::Error` and `Debug`.[1][3][4][15] Each variant of the domain error enum (for example `ConfigError`, `AuthError`, `ApiError`, `IoError`, `NotFound`, `Conflict`, `Interrupt`, `Unexpected`) should have an associated code string (such as `RSBP001` for config errors or `RSBP004` for auth errors) and an optional structured hint string. The catalog should be documented and append-only, with new codes added as new error variants are introduced, but existing codes never removed or repurposed.

The CLI entrypoint should use `anyhow::Result<()>` as its return type, allowing it to propagate errors from various subsystems using the `?` operator.[2][6][7] Where a domain error enum is returned, the CLI should downcast or otherwise recognize those errors and convert them into the JSON error envelope and exit-code taxonomy. Where an error is unexpected (that is, not part of the domain enum or representing a bug), the CLI should treat it as a generic “unexpected error,” map it to a reserved error code (for example `RSBP000`), capture its message and, optionally, stack trace in a crash-log file, and exit with code 1. This approach leverages `anyhow`’s convenience for propagation while preserving structured domain errors for pattern matching by downstream items like R03 and R70.[4][6][7]

The exit-code taxonomy should adopt the CLI-standards-aligned set used by TypeScript, with numeric codes 0 (success), 1 (generic error/unexpected), 2 (usage or configuration errors where the user’s invocation or config is invalid), 3 (resource not found, such as workspace missing), 4 (authentication or authorization failures), 5 (domain conflicts, such as attempting to create a resource that already exists), 130 (SIGINT / Ctrl-C), and 143 (SIGTERM).[Context, ts decisions] These codes should be expressed in Rust as a dedicated `ExitCode` enum with explicit numeric values, and maps should be defined from domain error variants to `ExitCode`. For example, `AppError::Config` maps to `ExitCode::Usage` (2), `AppError::NotFound` maps to `ExitCode::NotFound` (3), `AppError::Auth` maps to `ExitCode::Auth` (4), `AppError::Conflict` maps to `ExitCode::Conflict` (5), and `AppError::Api` or `AppError::Io` map to `ExitCode::Error` (1). Signals such as SIGINT and SIGTERM should be caught using `ctrlc` with the `termination` feature enabled, and the handler should cause the process to exit with codes 130 and 143 respectively.[5][9][10] Interactive prompts, if R61 adopts a prompt crate, should map cancellation errors or interruption signals to `ExitCode::Sigint` (130), ensuring consistent behavior.

Broken pipe handling should be implemented by inspecting errors from writes to `stdout` and `stderr`. If the error’s kind is `ErrorKind::BrokenPipe`, the CLI should suppress error reporting and exit cleanly, typically with `ExitCode::Success` (0). This ensures that when a user runs `rs-launch-blueprint-cli | head -n 10` and `head` closes the pipe, the CLI does not emit error messages or crash. This pattern matches TypeScript’s EPIPE handler, adjusted for Rust’s error-centric rather than signal-centric behavior.[8] For other IO errors, the usual mapping to `ExitCode::Error` (1) or domain-specific codes applies.

Crash-log persistence should follow Python’s ADR 0006 principle and be implemented as a best-effort writer that appends textual or JSON-formatted error information to a crash-log file under a state directory. The path to this state directory should be provided by R57’s `xdg-directory-set` decision when available; until then, the Rust template can assume a default state directory (for example under `$HOME/.rs-launch-blueprint/state`) and document this assumption. The crash-log writer should never panic or block exit; failures to write the crash log should be silently ignored or logged at a debug level.

The recommended stack of crates is therefore:

1. `thiserror = "2"` for defining domain error enums with structured variants and idiomatic `Error` and `Display` implementations.[1][3][4][15]  
2. `anyhow = "1"` for application-level error propagation in CLI and potentially in the web service’s entrypoints.[2][4][6][7]  
3. `ctrlc` (latest compatible release, with `termination` feature enabled) for cross-platform handling of Ctrl-C and Unix termination signals, mapping them to exit codes 130 and 143.[5][9][10]  

The `signal-hook` crate is recognized as a powerful alternative for Unix-specific signal handling, but for this template and its cross-platform, non-daemon focus, it is recommended as an up-and-comer rather than a primary dependency.[8][16][17][19] The stable Rust toolchain (`std`) provides broken pipe detection via `io::ErrorKind::BrokenPipe`, so no additional crate is necessary for EPIPE handling. Crash-log persistence can be implemented using `std::fs` and path utilities, integrating with the state-directory decision managed by R57.

This design yields a clear `error-taxonomy-exit-codes` parameter: a documented mapping from domain error codes (stable strings) and variants to exit codes and signal-driven exit behavior. Downstream items R03, R52–R56, and R70 can consume this parameter by matching on error codes or enum variants to determine HTTP statuses, config behavior, and absence-vs-failure semantics. The members of the stack are discussed in more detail in the following section.

**Gemini**

The recommended architectural stack constitutes a tightly integrated bundle of compiler-supported standard library routines and ecosystem-standard diagnostic frameworks. 

The primary domain error definitions are governed by `thiserror`, supplying the foundational types for the library and web surfaces. These enums are decorated with `miette`, which provides the `Diagnostic` trait, structured `hint` fields, explicit error codes, and the critical `JSONReportHandler` for machine-readable output. To enforce the stability of the error-code catalog across versions, `strum` is utilized to derive static string identifiers directly from the enum variants, ensuring synchronization. Asynchronous process interruptions are managed globally by `signal-hook`, capturing `SIGINT` and `SIGTERM` seamlessly, while unhandled crashes are intercepted by `human-panic`, safely logging diagnostics to the file system.

### Members

**OpenAI**

#### thiserror 2.0.20 (OpenAI)

##### Landscape

`thiserror` is the established typed-error derive for Rust libraries. Its generated `Error`, `Display`, `source`, and `From` implementations behave like handwritten code and do not expose `thiserror` as a public API type. ([docs.rs](https://docs.rs/thiserror/latest/thiserror/)) Retrieved September 9, 2026.

##### Principles and implementation

Use it for concrete errors that R03, R52–R56, and R70 can inspect. Keep stable `code()` and `hint()` methods project-owned; do not make the wire contract depend on macro-generated variant names.

Fitness gates:

| Gate | Result |
|---|---|
| License | **Pass:** MIT OR Apache-2.0. |
| MSRV | **Pass:** current manifest declares Rust 1.71, below project MSRV 1.96. |
| Advisories / unsafe | **Pass with CI confirmation:** no open package advisory surfaced in the RustSec search; integration requires no application unsafe code. |
| Ubuntu/macOS | **Conditional pass:** platform-neutral proc-macro/generated Rust; template matrix must prove both targets. |
| Features/runtime | Default `std`; no async-runtime coupling. |
| Size/compile | Negligible runtime and release-binary cost; low-to-moderate proc-macro compile cost. |

The latest manifest’s license, MSRV, and default feature are visible in the repository. ([github.com](https://github.com/dtolnay/thiserror/blob/master/Cargo.toml)) Retrieved September 9, 2026.

##### Dominant choice

`thiserror` has substantially broader ecosystem adoption than richer report frameworks and directly fits Rust API guidance to return meaningful concrete error types. ([lib.rs](https://lib.rs/crates/thiserror)) Retrieved September 9, 2026.

##### Qualified shortlist

- Handwritten implementations of `Error`, `Display`, and `source`.
- `miette` without `fancy`, if R66 later requires source spans, labels, code URLs, or diagnostic severity.
- SNAFU where automatic context selectors and backtrace policy justify its larger abstraction.

##### Excluded by gate

None of the principal typed-error alternatives was excluded on license alone. Dynamic report-only errors are excluded by this item’s **typed downstream matching** capability gate, not by package fitness.

##### Up-and-comers

`error-stack` is the notable context-rich alternative. It is useful for attached context and reports but would not eliminate the explicit `ErrorCode` catalog or exit mapping. ([lib.rs](https://lib.rs/crates/error-stack)) Retrieved September 9, 2026.

##### Fit for this template

Excellent:

- reusable library APIs remain typed;
- CLI and HTTP adapters can classify the same domain error;
- source errors remain available for debug/crash reports;
- presentation remains outside the library;
- no async or OS coupling.

##### Recommendation

Use `thiserror = "2.0.20"` for every concrete domain/infrastructure error enum. Require each surfaced error type to implement the project’s `CodedError` trait.

##### Ranked runner-up

Handwritten standard-library implementations. They have zero dependencies but create repetitive, review-sensitive `Display`, `source`, and conversion code.

##### Tradeoffs

- Proc-macro compile cost.
- `#[from]` can encourage overly broad automatic classification; use it only where every source value maps to the same semantic code.
- It does not provide codes, hints, exit values, JSON, or crash logging; those remain deliberately project-owned.

##### Parameters

Contributes:

```text
domain-error-representation = concrete thiserror enums
code-source = project ErrorCode catalog, never thiserror variant names
```

##### Migration implications

- Replace generic/string errors in `src/core` with domain enums.
- Add explicit `code()` and `hint()` implementations.
- Prevent blanket `From<io::Error>` where context determines `ConfigRead`, `Transport`, `BrokenPipe`, or generic `Io`.
- Preserve source errors with `#[source]`.

##### Validation strategy

Planned:

```bash
cargo test -p rs-launch-blueprint-core error_contract
cargo test -p rs-launch-blueprint-core error_sources_are_send_sync
cargo semver-checks check-release
```

Expected:

- all public errors implement `Error + Send + Sync + 'static`;
- source chains remain intact;
- no wire code is obtained from `Debug` or variant spelling.

##### Confidence & re-verify trigger

**High architectural confidence; medium metric confidence.** Re-verify on a `thiserror` major release, MSRV increase above the project floor, RustSec advisory, or evidence that R66 needs source-span diagnostics in the core model.

##### Sources

| Figure | Value | Canonical endpoint / evidence | Retrieval |
|---|---:|---|---|
| 90-day downloads | **Not captured; refresh required** | `GET https://crates.io/api/v1/crates/thiserror` → `crate.recent_downloads` | September 9, 2026 |
| All-time downloads | 1,332,222,355, corroborated by registry mirror | Same crates.io endpoint; mirror evidence ([openapps.pro](https://openapps.pro/packages/thiserror)) | September 9, 2026 |
| Last non-yanked release | 2.0.20, August 8, 2026 | `GET https://crates.io/api/v1/crates/thiserror/versions`; docs.rs corroboration ([docs.rs](https://docs.rs/crate/thiserror/latest)) | September 9, 2026 |
| Stars | 5,530 in docs.rs GitHub snapshot | `GET https://api.github.com/repos/dtolnay/thiserror`; corroboration ([docs.rs](https://docs.rs/crate/thiserror/latest)) | September 9, 2026 |
| Archived | Direct API field not captured; repository is releasing and running CI | Same repository endpoint; activity evidence ([github.com](https://github.com/dtolnay/thiserror/releases)) | September 9, 2026 |
| `pushed_at` | Not captured | Same repository endpoint | September 9, 2026 |
| Open issues | 27 | `GET https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open`; repository corroboration ([github.com](https://github.com/dtolnay/thiserror/actions)) | September 9, 2026 |
| Issue responsiveness | Not measured; required API sample was unavailable | 10 newest issues plus comments/events | September 9, 2026 |
| Advisories | 0 open package advisories found in search; confirm with `cargo deny` | `https://rustsec.org/packages/thiserror.html` | September 9, 2026 |
| Maintenance | **active** | Recent signed release and continuing CI ([github.com](https://github.com/dtolnay/thiserror/releases)) | September 9, 2026 |
| Adopters | Aggregate evidence: 58,094 crates, 23,128 direct; strict named-adopter Cargo.toml check remains open | Reverse-dependency evidence ([lib.rs](https://lib.rs/crates/thiserror)) | September 9, 2026 |

#### signal-hook 0.4.4 (OpenAI)

##### Landscape

`signal-hook` is the established safe façade for Unix signal handling, with flag, channel, iterator, and lower-level adapters. Its documentation focuses explicitly on the global-resource and async-signal-safety constraints that make handwritten handlers risky. ([docs.rs](https://docs.rs/crate/signal-hook/latest)) Retrieved September 9, 2026.

##### Principles and implementation

Use it only in Unix executable targets. Register SIGINT and SIGTERM before worker threads, consume notifications in normal Rust code, and translate them to a runtime-neutral internal `ShutdownSignal`.

Fitness gates:

| Gate | Result |
|---|---|
| License | **Pass:** MIT OR Apache-2.0. |
| MSRV | **Pass:** Rust 1.66, below project MSRV 1.96. |
| Advisories / unsafe | **Pass with CI confirmation:** no open advisory surfaced; implementation necessarily contains platform `unsafe`/libc code, exposed through safe high-level APIs. |
| Ubuntu/macOS | **Pass subject to template integration test:** both are Unix targets; upstream has active test and security-audit workflows. |
| Features/runtime | Recommend `default-features = false, features = ["iterator"]`; iterator enables channel. No async-runtime coupling. |
| Size/compile | Low binary/compile impact; iterator design may use one helper thread at runtime. |

The manifest declares Rust 1.66, dual licensing, and default channel/iterator features. ([github.com](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)) Retrieved September 9, 2026.

##### Dominant choice

It is the best fit where the executable must distinguish SIGINT from SIGTERM without binding the contract to Tokio or another async runtime.

##### Qualified shortlist

- A runtime-native signal module for the web-service binary, if its runtime is already fixed.
- `ctrlc` for applications needing only a unified Ctrl-C callback.
- A standard-library default-signal approach when no clean message, cancellation, or graceful shutdown is required.

##### Excluded by gate

- The legacy `tokio-signal` crate is excluded by the no-open-advisory/maintenance gate: RustSec lists it as unmaintained. This exclusion does **not** apply to the maintained `tokio::signal` module. ([rustsec.org](https://rustsec.org/advisories/)) Retrieved September 9, 2026.
- A std-only clean SIGINT/SIGTERM handler fails the capability gate because stable `std` does not provide general registration.

##### Up-and-comers

Runtime-neutral cancellation abstractions can sit above signal delivery, but they do not replace OS registration. A future stabilized Rust signal API would supersede this member.

##### Fit for this template

Strong for Ubuntu/macOS:

- separate SIGINT/SIGTERM identity;
- no mandatory async runtime;
- library remains free of global handlers;
- service and CLI can feed the same cancellation abstraction.

##### Recommendation

Use:

```toml
signal-hook = {
  version = "0.4.4",
  default-features = false,
  features = ["iterator"]
}
```

Register only SIGINT and SIGTERM. Do not register SIGPIPE in this member.

##### Ranked runner-up

A runtime-native signal adapter in the web-service executable. It may have lower integration overhead there, but it cannot serve a runtime-neutral synchronous CLI unless the CLI already uses that runtime.

##### Tradeoffs

- Signals are process-global.
- Iterator integration may consume a helper thread.
- Cooperative cancellation cannot interrupt arbitrary permanently blocking code unless the operation itself supports cancellation or timeouts.
- Windows behavior would need a separate adapter if Windows later enters the required matrix.

##### Parameters

Contributes:

```text
SIGINT = ErrorCode::Interrupted, CliExitCode::SigInt(130)
SIGTERM = ErrorCode::Terminated, CliExitCode::SigTerm(143)
handler ownership = executable only
```

##### Migration implications

- Add `src/cli/signals.rs` or `src/runtime/signals.rs`.
- Pass a cancellation receiver/token into command and service runners.
- Replace direct `process::exit` inside callbacks with normal outcome propagation.
- Ensure the library crate has no `signal-hook` dependency unless a private binary-support feature requires it.

##### Validation strategy

Planned Unix integration fixture:

```bash
cargo build --workspace

target/debug/rs-launch-blueprint test-support wait &
pid=$!
kill -INT "$pid"
wait "$pid"
test "$?" -eq 130

target/debug/rs-launch-blueprint test-support wait &
pid=$!
kill -TERM "$pid"
wait "$pid"
test "$?" -eq 143
```

Separate JSON-mode assertions verify one clean stderr envelope and no stdout.

##### Confidence & re-verify trigger

**High functional confidence, medium upstream-platform-evidence confidence.** Re-verify on a RustSec advisory, `signal-hook` 0.5, addition of Windows to the matrix, selection of an async runtime that makes a second signal stack unnecessary, or stabilization of a standard Rust signal API.

##### Sources

| Figure | Value | Canonical endpoint / evidence | Retrieval |
|---|---:|---|---|
| 90-day downloads | **Not captured; refresh required** | `GET https://crates.io/api/v1/crates/signal-hook` → `crate.recent_downloads` | September 9, 2026 |
| All-time downloads | 220,924,572, corroborated by registry mirror | Same crates.io endpoint; mirror evidence ([openapps.pro](https://openapps.pro/packages/signal-hook)) | September 9, 2026 |
| Last non-yanked release | 0.4.4, April 4, 2026 | `GET https://crates.io/api/v1/crates/signal-hook/versions`; docs.rs corroboration ([docs.rs](https://docs.rs/crate/signal-hook/latest)) | September 9, 2026 |
| Stars | 864 in docs.rs snapshot | `GET https://api.github.com/repos/vorner/signal-hook`; corroboration ([docs.rs](https://docs.rs/crate/signal-hook/latest)) | September 9, 2026 |
| Archived | Direct API field not captured; repository has current workflows/releases | Same repository endpoint ([github.com](https://github.com/vorner/signal-hook/actions)) | September 9, 2026 |
| `pushed_at` | Not captured | Same repository endpoint | September 9, 2026 |
| Open issues | 22 | `GET https://api.github.com/search/issues?q=repo:vorner/signal-hook+is:issue+is:open`; corroboration ([github.com](https://github.com/vorner/signal-hook/issues)) | September 9, 2026 |
| Issue responsiveness | Not measured; only a partial issue list was retrievable | 10 newest issues plus comments/events | September 9, 2026 |
| Advisories | 0 open package advisories found in search; confirm with `cargo deny` | `https://rustsec.org/packages/signal-hook.html` | September 9, 2026 |
| Maintenance | **active** | Release within six months, actively-developed badge, test and audit workflows ([github.com](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)) | September 9, 2026 |
| Adopters | Mirror names CubeSandbox, PostgresML, and Trieve; strict direct-Cargo.toml verification remains open | Reverse-dependency/application evidence ([openapps.pro](https://openapps.pro/packages/signal-hook)) | September 9, 2026 |

#### Rust std contract layer — MSRV 1.96 (OpenAI)

##### Landscape

This is a project-owned pattern assembled from stable standard-library APIs: `Error`, `ExitCode`, `Termination`, `Write`, `ErrorKind::BrokenPipe`, `Backtrace`, panic hooks, `SystemTime`, and `OpenOptions`.

At the research date, fetched standard-library documentation reported Rust 1.98.1; applying the owner-fixed “stable minus two minor versions” rule gives an initial declared `rust-version = "1.96"`. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html)) Retrieved September 9, 2026.

##### Principles and implementation

The core declaration should resemble:

```rust
macro_rules! define_error_catalog {
    ($(
        $variant:ident => {
            wire: $wire:literal,
            exit: $exit:ident,
            summary: $summary:literal
        }
    ),+ $(,)?) => {
        #[derive(Clone, Copy, Debug, Eq, Hash, PartialEq)]
        #[non_exhaustive]
        pub enum ErrorCode {
            $($variant),+
        }

        impl ErrorCode {
            pub const ALL: &'static [Self] = &[$(Self::$variant),+];

            pub const fn as_str(self) -> &'static str {
                match self {
                    $(Self::$variant => $wire),+
                }
            }

            pub const fn exit_code(self) -> CliExitCode {
                match self {
                    $(Self::$variant => CliExitCode::$exit),+
                }
            }
        }
    };
}
```

This makes the wire literal explicit while generating all local mappings from one declaration.

##### Dominant choice

A small explicit contract layer is preferable to a crate for:

- eight exit constants;
- fewer than two dozen catalog values;
- one EPIPE branch;
- one best-effort file append.

The difficult part is governance and test coverage, not boilerplate volume.

##### Qualified shortlist

- `strum` for enum iteration/string conversion.
- `miette::Diagnostic` for code/help/source-span metadata.
- `exitcode` or `proc-exit` for named process constants.
- `pipecheck` for restoring signal-like broken-pipe behavior.

All still require project-specific code allocation, semantic mapping, and compatibility policy.

##### Excluded by gate

- Variant/type-name-derived code: fails the stable-protocol gate.
- Numeric discriminant as wire code: fails decoupling and evolution gates.
- Global SIGPIPE restoration: fails combined CLI/web-service fit.
- Fixed crash path independent of R57: fails ownership/integration fit.
- Writing crash logs from the reusable library: fails side-effect isolation.
- Inlining hints into messages only: fails the structured-envelope capability.

##### Up-and-comers

`pipecheck` is useful for pure Unix text filters; `error-stack` is useful for rich contextual reports. Neither is the default because this template combines a library and web service with CLI output behavior. ([docs.rs](https://docs.rs/pipecheck/latest/pipecheck/)) Retrieved September 9, 2026.

##### Fit for this template

Excellent:

- no additional dependency for catalog, exits, EPIPE, or crash append;
- exact control over public protocol values;
- renderer and process policy remain outside domain logic;
- compatible with both synchronous and async surfaces;
- straightforward CI snapshots.

##### Recommendation

Implement one `error_contract` module as the sole source of codes and process mappings. Keep output formatting, signal receipt, prompt adaptation, and crash persistence in boundary modules.

##### Ranked runner-up

`miette 7.6.0` without `fancy`. It directly models unique diagnostic codes and help and has MSRV 1.70, but it is a larger reporting protocol and does not itself establish the append-only codebook or CLI exit taxonomy. ([docs.rs](https://docs.rs/miette/latest/miette/)) Retrieved September 9, 2026.

##### Tradeoffs

- Project owns the macro, documentation generator, and compatibility tests.
- `#[non_exhaustive]` means external consumers require a fallback arm.
- Internal coverage is enforced through generated mappings and `ALL`, not external compiler exhaustiveness.
- Crash-file locking across multiple simultaneous processes is not guaranteed without another crate; this is acceptable for best-effort fatal-process records.

##### Parameters

Contributes all concrete catalog values, hint semantics, exit values, EPIPE policy, and crash-persistence policy listed in the owned parameter below.

##### Migration implications

Create:

- `src/error/catalog.rs`
- `src/error/diagnostic.rs`
- `src/error/exit.rs`
- `src/cli/output.rs`
- `src/cli/entrypoint.rs`
- `src/cli/crash.rs`
- `docs/reference/error-codes.md`
- `docs/reference/error-codes.json`
- catalog and process integration tests.

##### Validation strategy

Planned:

```bash
cargo +1.96 check --workspace --all-targets
cargo +1.96 test --workspace
cargo +stable test --workspace
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo deny check advisories licenses
```

Additionally, an `xtask error-catalog --check` command must regenerate and compare the committed documentation/snapshot.

##### Confidence & re-verify trigger

**High.** Re-verify if Rust stabilizes an `on_broken_pipe` policy, changes default SIGPIPE handling, F301 changes backtrace capture/disclosure, or R57 declines to provide any state-directory capability.

##### Sources

Crate figures are **inapplicable**: this member is a project pattern over the Rust standard library, not a crate candidate. Relevant primary sources:

- `https://doc.rust-lang.org/std/process/trait.Termination.html`
- `https://doc.rust-lang.org/std/process/fn.exit.html`
- `https://doc.rust-lang.org/std/io/enum.ErrorKind.html`
- `https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html`
- `https://doc.rust-lang.org/cargo/reference/semver.html`
- `https://rust-lang.github.io/rfcs/2965-project-error-handling.html`
- `https://github.com/rust-lang/rust/issues/150588`

All retrieved September 9, 2026. ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html))

**Perplexity**

#### Domain Error and Error-Code Catalog Module (Perplexity)

##### Landscape

In Rust, the modeling of domain errors and their associated codes sits at the intersection of built-in language features and third-party crates. The landscape for this member includes the standard `Result<T, E>` type and `std::error::Error` trait as foundational elements, supplemented by struct and enum types that represent domain-specific failures. On the crate side, `thiserror` is the dominant library for deriving `Error` implementations for enums that model error taxonomies, while other crates like `snafu` and `derive_more` offer alternative approaches. The Rust FAQ and Microsoft’s Rust Patterns documentation both emphasize `thiserror` as the recommended choice for library error types, noting its idiomatic and zero-cost nature.[3][4][6][15] 

Beyond the choice of derive macro, the landscape includes patterns for associating metadata such as error codes and hints with error variants. Some projects embed codes directly in the error message; others define separate types or traits to expose codes. Crates like `strum` offer mechanisms to derive additional functionality for enums, such as string representations and properties. While explicit references to `strum` do not appear in the current search results, its use as a general-purpose enum helper is well-known in the Rust ecosystem. However, since the central requirement here is a stable string catalog, the design need not depend on `strum`; codes can be attached via manual implementations of a `ErrorCode` trait or associated functions. 

Authority for patterns in this space comes from the `thiserror` documentation, which shows how to derive error enums with `#[error("message")]` and `#[from]` attributes, and from practice-oriented write-ups that emphasize focusing on error taxonomy rather than boilerplate.[1][3][4][15] These sources establish that deriving `Error` for enums and treating them as the structured domain representation is standard practice. The existence of stable string error codes in Python’s implementation provides strong cross-language evidence that codes should be represented explicitly rather than derived from enum names.[Context, py code]

Practice evidence shows that many well-regarded Rust libraries expose custom error enums derived with `thiserror` and sometimes include code-like identifiers in their variants or messages. While full adopter lists are not available through the current search results, the inclusion of `thiserror` and its patterns in major training materials and FAQs implies widespread adoption.[1][3][4][6][15] The need for a stable catalog across ecosystems reinforces the choice of explicit codes attached to variants.

##### Principles and implementation

The domain error and error-code catalog module must realize the principle of a stable, append-only catalog of machine-readable codes while leveraging Rust’s typed error enums. The core idea is to define a Rust enum `AppError` (or similar) that represents the domain error taxonomy for the template, and associate with each variant an `ErrorCode` value (a newtype around `&'static str`) and an optional `hint` string. The enum should derive `thiserror::Error` and `Debug`, with `#[error("...")]` attributes specifying the human-facing message for each variant.[1][3][4][15] 

An example might look as follows:

```rust
use thiserror::Error;

#[derive(Debug, Error)]
pub enum AppError {
    #[error("Configuration error: {details}")]
    Config {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Authentication failed: {details}")]
    Auth {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("API request failed: {details}")]
    Api {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("I/O error: {source}")]
    Io {
        code: ErrorCode,
        hint: Option<String>,
        #[from]
        source: std::io::Error,
    },

    #[error("Resource not found: {details}")]
    NotFound {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Conflict: {details}")]
    Conflict {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },

    #[error("Interrupted by signal")]
    Interrupt {
        code: ErrorCode,
        hint: Option<String>,
    },

    #[error("Unexpected error: {details}")]
    Unexpected {
        code: ErrorCode,
        hint: Option<String>,
        details: String,
    },
}

#[derive(Clone, Copy, Debug)]
pub struct ErrorCode(&'static str);
```

In practice, we might omit the `code` and `hint` fields from each variant and instead implement methods on `AppError` that return a code and hint based on the variant. However, storing them as fields makes the design explicit and allows some variants to carry hints supplied by upstream code. The key point is that `ErrorCode` values such as `ErrorCode("RSBP001")` are defined in a dedicated catalog module and do not change once released. The catalog itself can be represented as a set of constants:

```rust
pub const ERROR_CONFIG_INVALID: ErrorCode = ErrorCode("RSBP001");
pub const ERROR_AUTH_FAILED: ErrorCode = ErrorCode("RSBP004");
// ...
```

And the `AppError` variants use these constants internally.

This design preserves the cross-repo principle of a stable catalog while exploiting Rust’s typed error enums. Downstream items such as R03 (absence vs failure) and R70 (HTTP problem envelope) can match on `AppError` variants or on `ErrorCode` values, depending on their needs. The JSON error envelope populates the `code` field from `ErrorCode` and the `message` field from `AppError`’s `Display` implementation. The optional `hint` field exposes remedy guidance separately from the message, aligning with Python’s pattern and enabling different output formats to handle hints differently.[Context, py code]

##### Dominant choice

The dominant choice for this member is a domain error enum derived with `thiserror::Error` and a catalog of `ErrorCode` constants used to populate a `code` field in the JSON envelope. This combination aligns with authoritative guidance and mainstream practice: `thiserror` is recommended for library error types in Rust and is known to generate idiomatic and efficient code.[1][3][4][6][15] The explicit code catalog mirrors Python’s `PLBP000` approach, preserving cross-language stability while not over-constraining Rust’s error types.

##### Qualified shortlist

Alternative patterns that satisfy the fitness gates include using `snafu` or similar crates for error enums, or deriving codes from enum variant names via helper traits. These alternatives can technically implement a stable catalog, but they either introduce additional complexity or tie codes to internal naming in ways that conflict with the owner’s preference for explicit, documented codes. Given that `thiserror` already integrates seamlessly with `std::error::Error` and is widely used, it remains the most appropriate choice in the shortlist.[3][4][6][15]

##### Excluded by gate

No specific crate is excluded solely by licensing or RustSec concerns in this member, as `thiserror` is MIT-licensed and has no known RustSec advisories in the current search results.[15] However, patterns that derive codes implicitly from enum variant names are excluded by the principle gate rather than by legal or technical gates: they fail the requirement for a stable, documented catalog that is not accidentally changed by refactoring. 

##### Up-and-comers

Up-and-comer patterns include richer diagnostic crates that might embed codes and hints alongside styled error messages. While such crates could augment the developer experience, they are not strictly necessary for the core catalog and may add complexity. They can be considered in future revisions but are not recommended as part of the initial template stack.

##### Fit for this template

This member’s design fits the template by providing a single, canonical domain error enum for the library and web service surfaces, with codes and hints that feed into the CLI’s JSON envelope and exit-code mapping. The `thiserror` derive macros avoid boilerplate in implementing `Error` and `Display`, while the manual code catalog gives precise control over the public interface.[1][3][4][15] The design is compatible with edition 2024 and should have an MSRV well within the “stable minus two minor versions” policy, given `thiserror`’ status as a widely used crate.[15]

##### Recommendation

The recommended implementation is to define an `AppError` enum derived with `thiserror::Error`, maintain a set of `ErrorCode` constants, and expose methods on `AppError` to return the associated code and hint. This ensures a stable catalog and structured domain error modeling.

##### Ranked runner-up

The ranked runner-up is using a similar enum without `thiserror`, with manual implementations of `std::fmt::Display` and `std::error::Error`. This avoids third-party dependencies but reintroduces boilerplate and is less idiomatic. It may be used in environments where external crates are restricted, but for `rs-launch-blueprint` it is less desirable.

##### Tradeoffs

The main tradeoff in this design is between explicitness and flexibility. Storing code and hint fields directly in error variants can make the types more verbose, but it ensures that codes are always available and that hints can be customized. Using methods to derive codes can simplify the enum structure but makes the relationship between variants and codes more implicit. Overall, the design balances these concerns by keeping codes in a separate catalog module while exposing them through methods on the error enum.

##### Parameters

owns error-taxonomy-exit-codes = “Rust error taxonomy v1: stable string codes attached to `AppError` variants, mapped to CLI exit-code enum as described.”

There is no conflict with existing parameters; the design is compatible with R03, R52–R56, and R70’s needs for domain error mapping.

##### Migration implications

For future alignment with Python and TypeScript ports, adopting this pattern may require those ecosystems to formalize their error code catalogs in ways similar to the Rust catalog, but such changes are a follow-on project. Internally, adding new error codes or variants must be done in an append-only fashion with thorough documentation.

##### Validation strategy

Validation can be performed by writing unit tests that instantiate each `AppError` variant, generate the JSON error envelope, and assert that the `code` field matches the expected string and that `hint` appears separately. Integration tests can simulate CLI invocations that trigger different domain errors and verify that the envelope and exit codes align with the catalog.

##### Confidence & re-verify trigger

Confidence in this design is high, given `thiserror`’ ecosystem status and Python’s explicit catalog precedent.[3][4][15] Re-verification should be triggered by any major changes in `thiserror`’ behavior, new RustSec advisories, or owner directives that alter the catalog’s required shape.

##### Sources

This member’s design draws on `thiserror` documentation and Rust FAQ entries that describe its use for library error types, emphasizing its ability to derive `Error` implementations and remove boilerplate.[1][3][4][15] It also uses Python’s explicit string codes as cross-language evidence and the owner’s requirement for a stable catalog.

#### Exit-Code Enum and Mapping (Perplexity)

##### Landscape

The exit-code enum and mapping member sits at the interface between domain errors and process termination behavior. The landscape includes Unix and CLI conventions for exit codes, the external CLI standards spec referenced in TypeScript decisions, Python’s `IntEnum` exit codes, and Rust’s own practices in CLI applications. TypeScript’s adoption of 0, 1, 2, 3, 4, 5, 130, and 143 for success, error, usage, notFound, auth, conflict, sigint, and sigterm was driven by external standards and is explicitly documented in D-016(2).[Context, ts decisions] Python’s `ExitCode(IntEnum)` variants 0–5 emphasize domain categories rather than CLI-specific codes.[Context, py code]

In Rust, there is no built-in exit-code enum; process exit codes are returned via `std::process::exit(code)` or by the implicit exit status of `main`. Rust CLI documentation often references Unix exit code conventions, including 0 for success and non-zero for failure, with specific codes sometimes borrowed from conventions such as that used by `bash`. Rust CLI patterns also emphasize capturing signals and mapping them to exit codes like 130 (SIGINT) and 143 (SIGTERM), consistent with TypeScript’s decisions.[8] 

##### Principles and implementation

The exit-code enum must implement the principle of a stable mapping from domain error categories and signals to numeric exit codes, aligned with CLI standards where possible and consistent across ecosystems at the level of behavior. The Rust member should define an `ExitCode` enum with explicit numeric discriminants:

```rust
#[repr(i32)]
pub enum ExitCode {
    Success = 0,
    Error = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    Sigint = 130,
    Sigterm = 143,
}
```

This enum is then used to map `AppError` variants and signals to exit codes. For example, `AppError::Config` maps to `ExitCode::Usage`, `AppError::NotFound` to `ExitCode::NotFound`, `AppError::Auth` to `ExitCode::Auth`, `AppError::Conflict` to `ExitCode::Conflict`, `AppError::Api` or `AppError::Io` to `ExitCode::Error`, and `AppError::Interrupt` to `ExitCode::Sigint`. Unexpected errors are mapped to `ExitCode::Error` and recorded in crash logs.

Signal handling via `ctrlc` ensures that when SIGINT or SIGTERM occurs, the appropriate `ExitCode::Sigint` or `ExitCode::Sigterm` is used. This mapping is consistent with TypeScript’s D-016(2) and with Unix conventions.[5][8][9] Python’s `ExitCode.INTERRUPT` (5) differs numerically but expresses a similar principle; the Rust design aligns with the CLI standards spec used by TypeScript to maximize cross-language agreement in behavior.

##### Dominant choice

The dominant choice is to adopt the TypeScript exit-code taxonomy and numeric values, expressed as a Rust enum. This ensures consistency with the external CLI standards spec and cross-repo behavioral agreement. It also provides clear semantics for signals and domain error categories.

##### Qualified shortlist

A qualified alternative would be to keep Python’s domain-focused codes (0–5) and add 130 and 143 for signals, but this would violate the external CLI standards spec used in TypeScript and potentially confuse users who expect standard exit codes. Therefore, the TypeScript-aligned mapping is preferred.

##### Excluded by gate

No candidate is excluded by licensing or technical gates, since exit codes are not tied to external crates. Patterns that omit distinct codes for SIGINT and SIGTERM are excluded by principle, as they fail to capture the signal semantics emphasized in TypeScript and CLI standards.

##### Up-and-comers

There are no significant up-and-comer crates related to exit codes; this member is purely architectural.

##### Fit for this template

This exit-code enum fits the template by providing a single, documented mapping that the CLI uses when terminating and that downstream items can rely on. It respects the Rust edition and MSRV constraints trivially, as it uses only language features.

##### Recommendation

The recommendation is to implement `ExitCode` as described and use it consistently across CLI, library, and web service surfaces where process exit behavior is relevant.

##### Ranked runner-up

Using constants rather than an enum is a runner-up, but an enum is more expressive and type-safe.

##### Tradeoffs

The main tradeoff is between strict adherence to CLI standards and potential divergence from Python’s current codes. The design chooses standards-aligned codes, with Python pending a follow-on alignment project.

##### Parameters

owns error-taxonomy-exit-codes = “ExitCode enum values 0, 1, 2, 3, 4, 5, 130, 143 and their mapping from domain error variants.”

##### Migration implications

Migrating other ecosystems to these codes would require updates to Python’s `ExitCode` enum and documentation, which is outside the scope of this item but is supported by the rationale here.

##### Validation strategy

Tests can simulate various domain errors and signals, assert the exit codes used, and confirm that they match the enum values.

##### Confidence & re-verify trigger

Confidence is high; re-verification is triggered by any changes in external CLI standards or owner directives.

##### Sources

This design draws on TypeScript’s documented exit-code mapping and Unix CLI conventions, as well as rust-cli guidance on mapping signals to exit codes like 130 and 143.[8]

#### `thiserror` Crate (Perplexity)

##### Landscape

The `thiserror` crate occupies the established industry standard bin for Rust error handling. Its documentation states that it provides a derive macro for the standard library’s `std::error::Error` trait, enabling developers to define error types with concise annotations.[1][15] It supports attributes like `#[error("message")]`, `#[from]`, and `#[error(transparent)]`, which generate implementations of `Display` and `Error` and the `From` traits needed for idiomatic propagation via the `?` operator.[1][3][4] The Rust FAQ underscores that `thiserror` deletes boilerplate, allowing engineers to focus on error taxonomy rather than glue code.[3] Iago Bozza’s write-up further emphasizes that `thiserror` is lightweight, zero-cost, and ideal for structured error types in libraries, generating code equivalent to manual implementations with no runtime overhead.[4]

Authority for `thiserror` comes from its maintainer documentation on docs.rs and crates.io, and from its inclusion in the Comprehensive Rust course and Microsoft Rust Patterns.[1][4][6][15] Practice evidence includes its widespread use in libraries and its position as the standard choice for error enums.[3][4][6] The crate’s version history (2.0.18 as of early 2026) indicates active maintenance.[14][15]

##### Principles and implementation

`thiserror` must implement the principle of idiomatic structured error modeling for library-like code in `rs-launch-blueprint`. Its derive macros allow the domain error enum to implement `std::error::Error` and `Display` efficiently, integrating with `anyhow` and other error-handling crates.[1][3][4][6][15] The `#[from]` attribute auto-generates `From` implementations for inner error types, enabling the `?` operator to convert them into custom error variants seamlessly.[3][4] This aligns with the principle that library code should expose concrete error types that callers can pattern-match on, while application code uses trait-object errors.[6][7]

##### Dominant choice

The dominant choice is to use `thiserror = "2"` for domain error enums. This is supported by Microsoft’s Rust Patterns, which explicitly recommend `thiserror` for libraries and “anyhow” for applications.[6] The Rust FAQ also positions `thiserror` as the standard for custom error types.[3]

##### Qualified shortlist

Alternative crates like `snafu` offer similar functionality but are not represented in the current authoritative sources, making them less suitable as the primary choice under the survey method. 

##### Excluded by gate

No gate excludes `thiserror`; its license is compatible (MIT or Apache-2.0), and the version history suggests active maintenance without known security advisories.[14][15] MSRV is likely to be well within the template’s policy, but this should be confirmed during integration.

##### Up-and-comers

Diagnostic crates that build on `thiserror` or offer richer error reports are up-and-comers that could be layered atop this design but are not essential for the core error taxonomy.

##### Fit for this template

`thiserror` fits the template by simplifying domain error enum definitions, integrating with `Result<T, AppError>`, and enabling `anyhow` to wrap domain errors via the standard `Error` trait.[4][6][7][15] Its zero-cost nature means there is no runtime penalty.[4]

##### Recommendation

The template should declare `thiserror = "2"` in `Cargo.toml` and derive `Error` and `Debug` for domain error enums.[15]

##### Ranked runner-up

Manual implementations of `Error` and `Display` are the runner-up, but are inferior in terms of maintainability and idiomatic expression.

##### Tradeoffs

Using `thiserror` introduces a macro dependency, which slightly increases compile-time, but the benefits in reducing boilerplate outweigh this cost. Binary size impact is negligible since `thiserror` generates code similar to manual implementations.[4]

##### Parameters

No additional parameters are owned by this member; it supports error-taxonomy-exit-codes by providing the underlying error types.

##### Migration implications

Adopting `thiserror` requires no migration; it is part of the initial template.

##### Validation strategy

Compile-time tests ensure that derive macros generate correct implementations, and runtime tests exercise error propagation via `?` and `From`.

##### Confidence & re-verify trigger

Confidence is very high; re-verification is triggered only by major `thiserror` version changes or advisories.[14][15]

##### Sources

This member’s design is based on `thiserror` documentation, the Rust FAQ, Iago Bozza’s blog, and Microsoft Rust Patterns, all of which describe its usage and benefits.[1][3][4][6][15]

#### `anyhow` Crate (Perplexity)

##### Landscape

The `anyhow` crate is the dominant application-level error handling library in Rust. Its documentation describes `anyhow::Error` as a trait-object-based error type designed for easy idiomatic error handling in Rust applications, with `anyhow::Result<T>` as the preferred return type for fallible functions.[2] `anyhow` is built around `std::error::Error` rather than a custom trait, differing from older crates like `failure`.[2] Authority comes from its maintainer documentation and from educational materials like Microsoft Rust Patterns and Rust FAQs, which recommend `anyhow` for binaries and CLI tools where the caller does not need to match on error variants.[2][6][7] 

The Rust FAQ likens `anyhow::Error` to a universal adapter that wraps any error into a consistent interface, preserving details inside the wrapper.[7] This pattern enables the `?` operator to propagate errors from multiple sources without glue code, as `anyhow` implements `From` for most standard and common third-party error types.[2][7] Practice evidence indicates widespread adoption in CLI applications and small services, though detailed adopter lists require direct crates.io queries.

##### Principles and implementation

`anyhow` implements the principle that application code should use trait-object errors for convenience, while library code uses structured enums. In `rs-launch-blueprint`, the CLI and web-service entrypoints can use `anyhow::Result<()>` as return types, converting domain errors into structured JSON envelopes and exit codes at the boundary. Non-domain errors are propagated as `anyhow::Error` until they reach the top-level handler, which treats them as unexpected and writes crash logs.[2][6][7]

The Rust Patterns documentation explicitly frames the pattern as “thiserror for libraries, anyhow for applications,” emphasizing that `#[from]` auto-generates `From` implementations for inner errors and `.context()` methods add human-readable wrappers.[6] This combination ensures both structured error modeling and ergonomic propagation.

##### Dominant choice

The dominant choice is to use `anyhow = "1"` for CLI and application-level error handling, consistent with Microsoft’s patterns and Rust FAQs.[2][6][7]

##### Qualified shortlist

Alternatives like `eyre` exist but are more focused on richer diagnostics than on simple trait-object error propagation. Given the owner’s emphasis on stable error codes and exit taxonomy rather than diagnostic styling, `anyhow` is preferred.

##### Excluded by gate

No gate excludes `anyhow`; it is MIT-licensed and there are no advisories noted in the current search results. Its MSRV must be checked during integration but is expected to be compatible.

##### Up-and-comers

Crates like `eyre` and `color-eyre` that provide enhanced error reports are up-and-comers and may be layered on top of `anyhow` for developer experience, but they are not central to the machine-encoded taxonomy.

##### Fit for this template

`anyhow` fits the template by simplifying error propagation in the CLI and web surface while allowing domain errors to be recognized and handled specially at the boundary. It integrates with `thiserror` via the `Error` trait.[2][4][6][7]

##### Recommendation

The template should declare `anyhow = "1"` in `Cargo.toml`, use `anyhow::Result<()>` for CLI `main` and top-level handlers, and rely on `anyhow` for unexpected error propagation.[2]

##### Ranked runner-up

Using only structured domain errors and manual propagation is the runner-up but would increase boilerplate and reduce flexibility in handling unexpected errors.

##### Tradeoffs

`anyhow` introduces a dependency and uses dynamic dispatch, which can slightly impact performance compared to fully static errors, but for CLI applications the cost is negligible relative to IO and network operations. Its benefits in code clarity and maintainability are substantial.[2][6][7]

##### Parameters

No parameters are owned; this member supports the error taxonomy by providing the mechanism for error propagation.

##### Migration implications

No migration is required; `anyhow` is part of the initial template stack.

##### Validation strategy

Tests can ensure that domain errors wrapped in `anyhow::Error` can be recognized at the top-level and that unexpected errors are handled correctly.

##### Confidence & re-verify trigger

Confidence is high; re-verification occurs if `anyhow`’s interface changes or new advisories appear.[2]

##### Sources

This design uses `anyhow` documentation and Rust FAQ entries, as well as Microsoft Rust Patterns, which all describe its role in application errors.[2][6][7]

#### `ctrlc` Crate and Signal Handling (Perplexity)

##### Landscape

The `ctrlc` crate is a small Rust library providing cross-platform handling of Ctrl-C signals.[5][9][10] It offers a single `set_handler` function that registers a handler closure executed when the user presses Ctrl-C. On Unix, this corresponds to a `SIGINT` signal, while on Windows, it corresponds to `CTRL_C_EVENT` or `CTRL_BREAK_EVENT`.[5][9][10] With the `termination` feature enabled, the handler also executes for `SIGTERM` and `SIGHUP` on Unix, making `ctrlc` useful for basic graceful shutdown needs.[5][9][10] Authority stems from its maintainer documentation on docs.rs and its description on OpenApps, which highlights its cross-platform abstraction over Unix signals, Apple dispatch, and Windows console events.[9][10]

Practice evidence shows that `ctrlc` is widely used in CLI tools requiring simple shutdown on Ctrl-C and optional termination signals. The rust-cli DeepWiki includes examples using `ctrlc::set_handler` with an `Arc<AtomicBool>` to signal graceful shutdown and suggests combining `ctrlc` with other mechanisms for more complex behaviors.[8]

##### Principles and implementation

`ctrlc` must implement the principle that SIGINT and SIGTERM are handled gracefully and mapped to exit codes 130 and 143 respectively. In `rs-launch-blueprint`, the CLI should install a `ctrlc` handler early in `main`, using `ctrlc::set_handler` to set an atomic flag or to directly call a shutdown routine. With the `termination` feature enabled, the handler should detect whether the signal is SIGINT or SIGTERM (via `SignalType` or similar) and set the exit code accordingly.[5][9] 

The rust-cli DeepWiki recommends patterns where a signal handler sets a “shutting down” flag on first signal and forces immediate exit on subsequent signals, which can be implemented via an `AtomicBool` and conditional logic.[8] This ensures that the first Ctrl-C begins graceful shutdown, while repeated interrupts cause immediate exit.

##### Dominant choice

The dominant choice for signal handling in this template is `ctrlc`, with the `termination` feature enabled for SIGTERM and SIGHUP support. This choice provides a simple, cross-platform API and aligns with the template’s non-daemon nature.[5][9][10]

##### Qualified shortlist

`signal-hook` is a qualified alternative for advanced Unix-only signal handling, providing a global registry of actions and allowing multiple handlers per signal.[16][17][19] However, its complexity is unnecessary for the template’s basic needs.

##### Excluded by gate

No gate excludes `ctrlc`; it is MIT-licensed, supports Unix and Windows, and has no advisories noted in the current search results.[5][9][10] It fits the MSRV policy, though this should be verified during integration.

##### Up-and-comers

Async signal-handling patterns using `signal-hook` and async runtimes are up-and-comers, relevant for future web-service extensions but not required now.[8][16][17]

##### Fit for this template

`ctrlc` fits the CLI template by providing simple and reliable signal handling across `ubuntu-latest` and `macos-latest`. It integrates with Rust’s standard error handling and exit codes.[5][8][9][10]

##### Recommendation

The template should declare `ctrlc` with the `termination` feature in `Cargo.toml`, install a handler at startup, and map signals to exit codes 130 and 143.

##### Ranked runner-up

`signal-hook` is the runner-up, suitable for future expansion if multiple signals and complex behavior become necessary.

##### Tradeoffs

`ctrlc` offers simplicity at the cost of less granular control over multiple signal handlers; `signal-hook` offers more control but adds complexity and Unix-specific focus.[8][16][17][19]

##### Parameters

No parameters are owned, but this member interacts with error-taxonomy-exit-codes via the mapping of signals to exit codes.

##### Migration implications

Adding `ctrlc` requires including it as a dependency and ensuring that CI builds on Ubuntu and macOS pass with the `termination` feature.

##### Validation strategy

Tests can simulate SIGINT and SIGTERM in controlled environments, verifying that the handler runs and exit codes are correct. Integration tests using manual Ctrl-C in CLI runs can confirm behavior.

##### Confidence & re-verify trigger

Confidence is high; re-verification occurs if `ctrlc` changes its API or if platform support issues arise.[5][9][10]

##### Sources

This design relies on docs.rs documentation for `ctrlc`, OpenApps descriptions, and rust-cli DeepWiki advice on signal handling.[5][8][9][10]

#### Crash-Log Writer and Broken Pipe Handling (Perplexity)

##### Landscape

Crash-log persistence and broken pipe handling rely primarily on the standard library and on patterns documented in Rust CLI guidance. Python’s ADR 0006 provides a cross-language precedent for crash logs, specifying a best-effort append to a crash log under the state directory.[Context, py ADR] TypeScript’s code includes an EPIPE handler via `process.stdout.on('error', ignoreEpipe)`, preventing crashes when downstream pipe readers close early.[Context, ts code] Rust’s CLI documentation recommends checking `io::Error::kind()` for `ErrorKind::BrokenPipe` and treating such errors as benign, often by exiting quietly.[8]

##### Principles and implementation

The crash-log writer must implement the principle of best-effort persistence of unexpected errors. It should construct a path to a crash-log file based on the state directory determined by R57, or based on a default state directory if R57’s answer is not yet available. It should then append serialized error information—such as timestamp, error code, message, and stack trace if available—to the log file. If writing fails (for example due to permissions), the writer should fail silently, logging only in verbose mode. The presence of a crash-log file provides a tool for post-mortem analysis without affecting user-facing behavior.

Broken pipe handling must detect when writes to `stdout` or `stderr` fail with `ErrorKind::BrokenPipe` and avoid printing error messages or crash logs in that case. The CLI should exit with `ExitCode::Success` (0) or a neutral code, reflecting that the pipeline completed as far as it could. This pattern aligns with TypeScript’s EPIPE handler and Rust’s standard idioms.[8][Context, ts code]

##### Dominant choice

The dominant choice is to implement crash-log writer and broken pipe handling using only the standard library, without additional crates. This keeps the dependency stack simple and leverages well-known patterns.

##### Qualified shortlist

More advanced crash-log systems could integrate with logging frameworks like `tracing` or `log`, but such integrations are beyond the scope of this item.

##### Excluded by gate

No gate excludes standard library patterns; they are inherent to Rust.

##### Up-and-comers

Structured logging frameworks are up-and-comers that might integrate with crash logs, but they are not necessary for the core behavior.

##### Fit for this template

These patterns fit the template by providing robust behavior for unexpected errors and broken pipes without additional dependencies. They maintain cross-language consistency with Python and TypeScript’s precedent.

##### Recommendation

The template should implement crash-log writing via `std::fs::OpenOptions::append(true)` and broken pipe detection via `io::ErrorKind::BrokenPipe`, mapping broken pipe scenarios to exit code 0.

##### Ranked runner-up

Using no crash-log writer is a runner-up but fails the cross-language principle; thus, it is not recommended.

##### Tradeoffs

Crash-log writing introduces minor IO overhead, while broken pipe suppression may hide certain errors; careful logging and documentation mitigate these tradeoffs.

##### Parameters

assumes R57 xdg-directory-set = a state directory path where crash logs can be written; if R57 chooses a different path, the crash-log writer must adapt.

CONFLICT: R57 state-directory — needs a writable state directory path for crash logs — reason: crash-log persistence requires a location; until R57 is decided, this member assumes a default path but must be updated to consume R57’s parameter.

##### Migration implications

Future changes to R57’s state-directory decisions may require updating the crash-log writer’s path logic.

##### Validation strategy

Tests that simulate unexpected errors and verify crash-log entries, as well as tests that simulate broken pipe writes and confirm quiet exits, will validate this member.

##### Confidence & re-verify trigger

Confidence is moderate; re-verification is triggered by changes in R57’s state-directory decisions or by new requirements for logging formats.

##### Sources

This member derives its design from Python’s ADR 0006, TypeScript’s EPIPE pattern, and Rust CLI guidance on broken pipe handling.[8][Context, py ADR][Context, ts code]

**Gemini**

#### thiserror (Gemini)

##### Landscape
The `thiserror` crate resides firmly in the established industry standard bin. It is recognized universally across the Rust ecosystem as the de facto standard for generating standard library `Error` trait implementations via procedural macros [cite: 3, 4, 5]. Its authority is cemented by its widespread adoption in nearly every major network, parsing, and data-structure library in the Rust ecosystem. Practice evidence shows it sits among the most downloaded crates of all time, fundamentally defining how library authors structure failure states [cite: 20, 21].

##### Principles and implementation
The core principle governing library and web service design is that errors must not lose their type identity when crossing system boundaries. `thiserror` enables `rs-launch-blueprint` to define domain-specific, exhaustively matchable error enums. Unlike application-level wrappers that utilize dynamic dispatch to obscure the underlying type behind a generic trait object, `thiserror` preserves the exact variant [cite: 3, 11]. This architectural characteristic is non-negotiable for the template, as downstream consumers—particularly the configuration fallback logic (R54) and the HTTP status routing tables (R70)—must be able to pattern-match on variants to dictate conditional application logic before rendering a response to the user.

##### Dominant choice
`thiserror` operates effectively as a monopoly within the domain of library-focused error definition macro tooling.

##### Qualified shortlist
`thiserror`, `anyhow`, `snafu`.

##### Excluded by gate
The `anyhow` crate is excluded by the architecture gate for the library and web-service design profile. By design, `anyhow` obscures the underlying error type within a trait object, specifically preventing the exhaustive pattern matching required by downstream subsystems like the HTTP status router [cite: 3, 11].

##### Up-and-comers
The `snafu` crate provides analogous functionality, offering rich context selectors. However, it enforces a drastically more complex procedural macro syntax and maintains a significantly smaller ecosystem footprint compared to `thiserror`'s seamless and ergonomic definition format.

##### Fit for this template
The empirical evaluation of fitness against the fixed parameters confirms `thiserror` as an optimal component.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/thiserror` | ~352,683,707 [cite: 20] |
| **All-time downloads** | `crates.io/api/v1/crates/thiserror` | 1,594,711,593 [cite: 20] |
| **Last release** | `crates.io/api/v1/crates/thiserror/versions` | `2.0.20` [cite: 21] |
| **Stars, archived** | GitHub Repository | Evaluated as highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Active maintenance queue. |
| **Issue responsiveness** | Maintainer Metrics | Rapid triage indicated by frequent point releases. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Adopted by `reqwest`, `serde_json` wrappers, and core async runtimes. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) |
| **MSRV** | Fitness Gate 2 | `1.56+` (Passes stable minus 2 minor versions policy) |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. `unsafe` is completely isolated to macro expansion. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility (`ubuntu-latest`, `macos-latest`, Windows). |
| **Async Coupling** | Fitness Gate 5 | No default features tying it to an async runtime. |
| **Binary/Compile Cost** | Fitness Gate 6 | Negligible. Procedural macros evaluate at compile time, generating zero-cost `Display` implementations. |

##### Recommendation
Adopt `thiserror`.

##### Ranked runner-up
`snafu`.

##### Tradeoffs
A fundamental tradeoff with `thiserror` is that it forces all contextual data to be embedded directly inside the enum variants at the time of definition, contrasting with the dynamic context attachment methods provided by dynamic dispatch wrappers. However, this limitation is entirely resolved by the adoption of `miette`, which handles the contextual wrapping and diagnostic decoration in the application layer.

##### Parameters
`owns library-error-domain = thiserror`

##### Migration implications
Template files defining public error interfaces will undergo structural revision. The boilerplate `impl Display` and `impl std::error::Error` blocks will be eliminated, replaced by `#[derive(thiserror::Error, Debug)]` and explicit `#[error("...")]` procedural macro annotations on the enumeration variants [cite: 4].

##### Validation strategy
Compile a mock library module that returns a distinct `enum Error` variant. Implement a downstream consuming function that utilizes a `match` statement to exhaustively branch logic based on the returned variant, asserting that type downcasting is unnecessary.

##### Confidence & re-verify trigger
Confidence is high. The architecture warrants re-verification only if the Rust compiler introduces built-in derivation capabilities for the `std::error::Error` trait in a future edition, rendering external macro crates obsolete.

##### Sources
*   [cite: 4, 5] `thiserror` documentation detailing macro syntax and `Error` trait implementations.
*   [cite: 20, 21] Crates.io statistics for popular categories and global download metrics.
*   [cite: 3] Microsoft Rust Patterns Book detailing the architectural split between `thiserror` and `anyhow`.

#### miette (Gemini)

##### Landscape
The `miette` crate currently occupies the boundary between an up-and-comer and an established industry standard. Its authority is strongly advocated within modern CLI architecture methodologies and is actively utilized in high-profile Rust frontend tools [cite: 6, 7]. The practice evidence is substantial; it has been adopted by heavily utilized, enterprise-ready command-line toolchains, including the Oxc JavaScript parser, demonstrating its capability to handle complex diagnostic routing at scale [cite: 7].

##### Principles and implementation
`miette` bridges the structural gap between Python's verbose dictionaries and TypeScript's transient exception classes by implementing a rich `Diagnostic` trait on top of the foundation provided by `thiserror`. It natively supports a `#[help("...")]` macro attribute, satisfying the F296 requirement for a structured hint field without resorting to manual string formatting or standard output manipulation [cite: 12]. Crucially, the architecture leverages `miette`'s `JSONReportHandler` [cite: 7, 22]. This handler natively intercepts the error code, the help text, and the primary message, rendering them as a single, machine-readable JSON document on standard error, fulfilling the recorded baseline for deterministic machine envelope generation (F294) without requiring bespoke serialization logic.

##### Dominant choice
`miette` stands as the most mature structured diagnostic framework available, uniquely offering both graphical console rendering and structured JSON rendering out-of-the-box.

##### Qualified shortlist
`miette`, `annotate-snippets`.

##### Excluded by gate
The `annotate-snippets` crate is excluded because it operates entirely as a lower-level string formatting and alignment tool. It lacks any native JSON serialization pathways, meaning the template would be forced to build and maintain a custom error envelope trait and serializer to satisfy the machine-readable requirements.

##### Up-and-comers
There are currently no up-and-comers directly competing with the comprehensive `Diagnostic` trait ecosystem established by `miette`.

##### Fit for this template
The empirical evaluation validates `miette` against the architectural requirements.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/miette` | Consistent top-tier growth [cite: 6]. |
| **All-time downloads** | `crates.io/api/v1/crates/miette` | Established enterprise adoption metric. |
| **Last release** | `crates.io/api/v1/crates/miette/versions` | `7.x+` stable sequence. |
| **Stars, archived** | GitHub Repository | Highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Active feature requests and bug triage. |
| **Issue responsiveness** | Maintainer Metrics | High responsiveness. |
| **Advisories** | RustSec Database | 0 open advisories [cite: 23]. |
| **Adopters** | Reverse Dependencies | Oxc JavaScript toolchain [cite: 7], cargo-binstall. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `Apache-2.0` (Pass) |
| **MSRV** | Fitness Gate 2 | `1.70` (Passes stable minus 2 minor versions policy) |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Fully cross-platform. |
| **Async Coupling** | Fitness Gate 5 | No default async coupling. Requires enabling the `fancy` feature for terminal rendering. |
| **Binary/Compile Cost** | Fitness Gate 6 | Moderate compile time penalty due to transitive graphical dependencies, but highly justifiable for the UX. |

##### Recommendation
Adopt `miette`.

##### Ranked runner-up
`annotate-snippets`.

##### Tradeoffs
To achieve rich terminal output, `miette`'s `fancy` feature must be enabled, which subsequently pulls in multiple dependencies to support ANSI color coding, text wrapping, and screen-reader braille output [cite: 6, 7]. In a strictly minimal, size-constrained binary, this dependency tree adds measurable weight. However, for the `rs-launch-blueprint` template, delivering world-class, accessible user experience diagnostics supersedes micro-optimizations in binary size.

##### Parameters
`owns error-diagnostic-envelope = miette`

##### Migration implications
Template files will implement `#[derive(miette::Diagnostic)]` alongside `thiserror`. The primary entry point in the CLI (`src/bin/main.rs`) will configure `miette::set_hook` during initialization, introducing conditional logic to swap between the `GraphicalReportHandler` and the `JSONReportHandler` dynamically based on the presence of the `--format json` flag, seamlessly satisfying decision D-018(4) [cite: 7, 24].

##### Validation strategy
Execute the compiled command-line interface, intentionally triggering a configuration parsing error while passing the machine-mode flag. Assert that the standard error stream contains exactly one valid JSON object encompassing the `"code"`, `"message"`, and `"help"` fields, with no extraneous text formatting.

##### Confidence & re-verify trigger
Confidence is high. The architecture warrants re-verification if the Rust standard library ecosystem moves to standardize a native diagnostic reporting trait that supplants third-party implementations.

##### Sources
*   [cite: 6, 25, 26] `miette` diagnostic capabilities, feature flags, and JSON output formatting constraints.
*   [cite: 12] `Diagnostic` trait definitions detailing programmatic access to `code()` and `help()` metadata.
*   [cite: 7, 24] Documentation on report handlers, themes, and configuration options.

#### strum (Gemini)

##### Landscape
`strum` is universally recognized within the established industry standard bin. Its authority is derived from being the most utilized macro crate for string-enum metaprogramming, fundamentally relied upon in parsers, configuration loaders, and CLI flag management systems across the ecosystem [cite: 27]. Practice evidence shows it consistently ranks in the top 50 most downloaded crates on `crates.io`, boasting hundreds of millions of all-time downloads [cite: 28].

##### Principles and implementation
The architecture mandates that the error-envelope "code" field (F295) must be a stable, append-only string catalog (e.g., `PLBP000`, `AUTH001`). Hardcoding these string identifiers inside the `miette` `#[diagnostic(code("..."))]` attribute duplicates data, creating an unacceptable risk of drift between the type system and the published catalog. By deriving `strum_macros::IntoStaticStr` on the primary `thiserror` domain enum, the template dynamically surfaces the exact name of the variant (or a custom identifier supplied via a `#[strum(serialize="PLBP001")]` attribute) as a static string reference at compile time [cite: 13, 29]. This structural pattern enforces absolute synchronization: the internal domain error variant *is* the external catalog identifier. Downstream subsystems (R03, R54, and R70) can programmatically extract this identifier without manual mapping.

##### Dominant choice
`strum` is the dominant choice for enum-to-string metaprogramming in Rust.

##### Qualified shortlist
`strum`, manual `impl Display` formatting.

##### Excluded by gate
No candidates were excluded by fitness gates.

##### Up-and-comers
There are currently no significant up-and-comers challenging `strum` in the procedural string-enum derivation space.

##### Fit for this template
The empirical evaluation validates `strum` as a zero-cost abstraction for the template.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/strum` | Top 50 metric [cite: 28]. |
| **All-time downloads** | `crates.io/api/v1/crates/strum` | 613,372,908 [cite: 28]. |
| **Last release** | `crates.io/api/v1/crates/strum/versions` | `0.28.0` [cite: 28]. |
| **Stars, archived** | GitHub Repository | Highly active, non-archived. |
| **Open issues** | GitHub Issue Search | Minimal open bugs, mostly feature discussions. |
| **Issue responsiveness** | Maintainer Metrics | High responsiveness to compiler changes. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Ubiquitous across CLI parsers and data serializers. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT` (Pass) [cite: 28]. |
| **MSRV** | Fitness Gate 2 | `1.71.0` (Passes stable minus 2 minor versions policy) [cite: 28]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility. |
| **Async Coupling** | Fitness Gate 5 | No async coupling. |
| **Binary/Compile Cost** | Fitness Gate 6 | Negligible. Procedural macro expands at compile time with zero runtime overhead [cite: 28]. |

##### Recommendation
Adopt `strum` and the associated `strum_macros` crate.

##### Ranked runner-up
Manual string mapping via large, boilerplate `match` statements.

##### Tradeoffs
Adopting `strum` introduces a minor procedural macro expansion step during compile time. However, this entirely eliminates vast amounts of error-prone boilerplate and definitively prevents the public string catalog from drifting out of synchronization with the internal type system.

##### Parameters
`owns error-code-catalog-source = strum::IntoStaticStr`

##### Migration implications
The `#[derive(strum_macros::IntoStaticStr)]` macro will be appended to the main domain error enumeration. During diagnostic formatting, `self.into()` will be passed directly to the `miette` diagnostic code formatter to yield the static catalog string.

##### Validation strategy
Instantiate a `WorkspaceNotFound` error variant programmatically. Assert that invoking its string serialization trait produces the exact, expected string catalog ID (e.g., `WORKSPACE_NOT_FOUND` or `PLBP003`) without memory allocation.

##### Confidence & re-verify trigger
Confidence is absolute. Re-verification is only required if the Rust language introduces native reflection capabilities that render enum-to-string macros obsolete.

##### Sources
*   [cite: 13, 27] `strum` macro functionality, traits, and `IntoStaticStr` implementation details.
*   [cite: 28] `strum` registry metrics and metadata.
*   [cite: 13, 29] Advanced attribute configurations and parsing error types.

#### signal-hook (Gemini)

##### Landscape
`signal-hook` resides in the established industry standard bin. Its authority is explicitly established by the official Command Line Applications in Rust book, which formally recommends the library for robust POSIX signal handling [cite: 1, 2]. Practice evidence confirms it is the unchallenged standard for safely intercepting signals in non-Tokio, multi-threaded CLI environments.

##### Principles and implementation
The architecture mandates (F298) that the process must deterministically map `SIGINT` to exit code 130 and `SIGTERM` to exit code 143, preserving the reconciliation established in the TypeScript port. The native Rust standard library does not handle `SIGTERM` cleanly or provide safe global interception out-of-the-box. `signal-hook` resolves this by allowing the template to register safe handlers using `flag::register` hooked to an `Arc<AtomicBool>` or a blocking signal iterator [cite: 8, 9, 30]. Because `rs-launch-blueprint` optimizes for a non-async initialization sequence without a long-running daemon mode, a simple blocking iterator or periodic flag check is sufficient to capture the signal, execute any necessary cleanup messages, and explicitly invoke `std::process::exit(130)` or `143`.

If the interactive prompts module (R61) utilizes the `inquire` crate, a critical intersection occurs regarding prompt cancellation (F299). The `inquire` crate natively traps `Ctrl-C` during active user input and surfaces an `InquireError::OperationInterrupted` variant [cite: 16]. The architectural implementation routes this specific library error natively through the `thiserror` domain, mapping it directly to exit code 130. This elegant design prevents `signal-hook` from asynchronously colliding with the terminal's raw mode during an active prompt.

##### Dominant choice
`signal-hook` is the dominant choice for safe, low-level signal interception.

##### Qualified shortlist
`signal-hook`, `ctrlc`.

##### Excluded by gate
The `ctrlc` crate is excluded because it exclusively binds to `SIGINT` and does not provide native `SIGTERM` capture capabilities [cite: 1]. This explicitly fails the F298 requirement to achieve parity with the TypeScript port's `SIGTERM` handling.

##### Up-and-comers
Tokio-based signal handlers are modern alternatives, but they are excluded as they strictly assume an asynchronous runtime, which violates the template's mandate for a lightweight, non-async CLI initialization sequence.

##### Fit for this template
The empirical evaluation confirms `signal-hook` as a minimal, safe dependency.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/signal-hook` | High utility in system tooling. |
| **All-time downloads** | `crates.io/api/v1/crates/signal-hook` | Core ecosystem dependency. |
| **Last release** | `crates.io/api/v1/crates/signal-hook/versions` | `0.4.4` [cite: 8]. |
| **Stars, archived** | GitHub Repository | Active, specialized repository. |
| **Open issues** | GitHub Issue Search | Minimal open issues, primarily edge-case OS behaviors. |
| **Issue responsiveness** | Maintainer Metrics | Stable, mature maintenance. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Adopted by standard TUIs, process managers, and daemons. |
| **Maintenance state** | Rubric Evaluation | `stable-quiet` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) [cite: 8]. |
| **MSRV** | Fitness Gate 2 | `1.66.0` (Passes stable minus 2 minor versions policy) [cite: 8]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. Low-level `libc` bindings are encapsulated safely. |
| **Platform Matrix** | Fitness Gate 4 | Full UNIX support. Provides degraded but functionally sufficient emulation on Windows (catching standard interrupt signals) [cite: 9, 31]. |
| **Async Coupling** | Fitness Gate 5 | No async coupling. Provides blocking iterators. |
| **Binary/Compile Cost** | Fitness Gate 6 | Minimal cost (45.8 KiB) [cite: 8]. |

##### Recommendation
Adopt `signal-hook`.

##### Ranked runner-up
`ctrlc`.

##### Tradeoffs
UNIX signals are inherently asynchronous, globally scoped, and notoriously complex to handle without introducing race conditions or memory corruption [cite: 19]. `signal-hook` brilliantly mitigates these data races, but requires the developer to design the main execution loop carefully to ensure it does not block infinitely if relying solely on reading an `AtomicBool` flag.

##### Parameters
`owns process-interrupt-contract = signal-hook + 130/143 exit mapping`
`assumes interactive-prompts = inquire` (contingent on R61)

##### Migration implications
The template initialization sequence will spawn a lightweight signal listener or register atomic flags to intercept OS signals. Upon detection, it will cleanly exit with status `130` for `SIGINT` and `143` for `SIGTERM` [cite: 30]. Broken pipe handling (F300) will explicitly not use signals; instead, standard pattern matching (`match write_result { Err(e) if e.kind() == ErrorKind::BrokenPipe => process::exit(0) }`) will be embedded deep in the output formatters to satisfy UNIX conventions [cite: 17, 18].

##### Validation strategy
Execute the compiled CLI, discover its process ID, and send a `SIGTERM` via `kill -15 <pid>`. Verify the terminal returns an exact exit code of `143`. Subsequently, pipe the CLI output to `head -n 1`, close the pipe abruptly, and verify an exit code of `0` and the complete absence of a `std::io` panic trace.

##### Confidence & re-verify trigger
Confidence is high. Re-verification is only required if a future Rust edition introduces native, safe signal handling callbacks directly within the `std::process` module.

##### Sources
*   [cite: 8, 9, 31] `signal-hook` usage, examples, and Windows operating system limitations.
*   [cite: 1, 2, 19] POSIX signal routing behavior and official Rust CLI handling recommendations.
*   [cite: 16, 32] `inquire` crate documentation detailing error variants for interactive cancellation.

#### human-panic (Gemini)

##### Landscape
`human-panic` is firmly situated in the established industry standard bin. Its authority is paramount, having been developed directly by the Rust CLI Working Group explicitly to implement user-friendly crash logs for polished terminal applications [cite: 10]. Practice evidence highlights deep adoption by user-facing CLI tools attempting to prevent raw stack-trace leakage, with the crate demonstrating tens of millions of downloads across the ecosystem.

##### Principles and implementation
Requirement F302 and ADR 0006 mandate that unexpected, unrecoverable panics write a best-effort crash-log file to a deterministic location (e.g., `<state>/plbp/plbp_crash.log`). By default, native `panic!` macros print deep, unformatted, and often intimidating system traces directly to standard error. `human-panic` fundamentally alters this behavior by installing a custom panic hook at process initialization. When an unhandled panic occurs, the library suppresses the raw trace (unless `RUST_BACKTRACE` is explicitly set in the environment), creates an actionable, user-friendly prompt on standard error, and persists a TOML-formatted or plain-text crash dump to the filesystem [cite: 10]. Crucially, by utilizing the underlying configuration structures rather than the basic `setup_panic!` macro, the template can override the default OS temporary directory [cite: 10, 33], explicitly routing the log to the XDG state directory defined by the R57 parameters.

##### Dominant choice
`human-panic` is the dominant mechanism for intercepting and formatting crash logs in user-facing utilities.

##### Qualified shortlist
`human-panic`, `crashlog`.

##### Excluded by gate
No candidates were excluded by fitness gates.

##### Up-and-comers
The `crashlog` crate [cite: 34] is a newer alternative that attempts to limit external dependencies. However, it lacks the established stability, the robust TOML serialization structure, and the ecosystem trust provided by `human-panic`.

##### Fit for this template
The empirical evaluation confirms `human-panic` as a polished, production-ready utility.

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| **90-day downloads** | `crates.io/api/v1/crates/human-panic` | Sustained usage in CLI tooling. |
| **All-time downloads** | `crates.io/api/v1/crates/human-panic` | 23M+ estimated downloads. |
| **Last release** | `crates.io/api/v1/crates/human-panic/versions` | `2.0.8` [cite: 10]. |
| **Stars, archived** | GitHub Repository | Highly starred by CLI developers, non-archived. |
| **Open issues** | GitHub Issue Search | Stable, with issues largely focused on metadata extraction edge cases. |
| **Issue responsiveness** | Maintainer Metrics | Maintained as an ecosystem standard. |
| **Advisories** | RustSec Database | 0 open advisories. |
| **Adopters** | Reverse Dependencies | Wide variety of developer-experience focused tools. |
| **Maintenance state** | Rubric Evaluation | `active` |
| **License** | Fitness Gate 1 | `MIT OR Apache-2.0` (Pass) [cite: 33]. |
| **MSRV** | Fitness Gate 2 | `1.70.0` (Passes stable minus 2 minor versions policy) [cite: 35]. |
| **Security/Unsafe** | Fitness Gate 3 | 0 open RustSec advisories. |
| **Platform Matrix** | Fitness Gate 4 | Universal compatibility (`ubuntu-latest`, `macos-latest`, Windows). |
| **Async Coupling** | Fitness Gate 5 | No async coupling. |
| **Binary/Compile Cost** | Fitness Gate 6 | Minimal cost (11.2 KiB); relies on standard `backtrace` and `os_info` dependencies [cite: 35, 36]. |

##### Recommendation
Adopt `human-panic`.

##### Ranked runner-up
`crashlog`.

##### Tradeoffs
`human-panic` achieves its functionality by globally overriding the default Rust panic hook. In an integrated architecture where the repository functions as both a library and a CLI workspace, the initialization routine must strictly only execute within the CLI binary initialization path (`src/bin/main.rs`). This constraint ensures that if the library component is imported by a third-party Rust application, it does not inadvertently alter the host application's global panic routing, which would constitute a severe violation of library design principles [cite: 37, 38].

##### Parameters
`owns crash-log-persistence = human-panic`
`assumes xdg-directory-set = directories` (R57, required to define the exact `<state>` path mapping)

##### Migration implications
The codebase will inject the `human_panic` initialization sequence exclusively inside the `src/bin/main.rs` bootstrap sequence [cite: 10]. The implementation must ensure the configuration payload dynamically targets the state directory path provided by the R57 resolution, rather than relying on the macro's default temporary folder behavior.

##### Validation strategy
Inject an explicit `unreachable!()` or `panic!("test crash")` statement into a test command execution path. Verify that the console prints the expected "Well, this is embarrassing" user-friendly message and successfully generates a TOML file at `<state>/plbp/crash_*.toml` containing the operating system identity, version metadata, and the structured trace context.

##### Confidence & re-verify trigger
Confidence is high. Re-verification is only necessary if R57 formally declines to establish a dedicated state directory, which would force the architecture to fall back to the operating system's default `/tmp` or equivalent temporary path.

##### Sources
*   [cite: 10, 33, 35] `human-panic` crate metrics, custom configuration options, and crash log formatting structures.
*   [cite: 34] Comparison metrics to the alternative `crashlog` crate.
*   [cite: 37, 38] Documentation regarding the safe utilization of panic boundaries and global hook management.

### Compatibility

**OpenAI**

The members have no conflicting type or runtime ownership:

- `thiserror` generates ordinary standard-library error implementations.
- The catalog and exit layer consumes only those resulting error types.
- `signal-hook` is confined to Unix executables and communicates through a project-owned signal/cancellation enum.
- The library does not initialize `signal-hook`, output streams, or crash files.

Required version matrix:

| Rust | OS | `thiserror` | `signal-hook` | Features |
|---|---|---:|---:|---|
| 1.96 | Ubuntu latest | 2.0.20 | 0.4.4 | `iterator`, no defaults |
| 1.96 | macOS latest | 2.0.20 | 0.4.4 | `iterator`, no defaults |
| Current stable, presently 1.98.x | Ubuntu latest | 2.0.20 | 0.4.4 | same |
| Current stable | macOS latest | 2.0.20 | 0.4.4 | same |

**Execution status:** this matrix and the combined reference fixture are proposed, not run in this research environment. No maintained shared adopter was counted under the owner’s strict “reverse dependency plus direct Cargo.toml” rule. The matrix must pass before the dependency lock is accepted.

**Perplexity**

The members of the

> ⚠ Possible truncation: response may be incomplete.

**Gemini**

The recommended stack operates synergistically, addressing every required ledger pattern without generating architectural conflicts. `thiserror` enumerations are explicitly designed to be supported by `miette::Diagnostic` traits. `strum_macros` seamlessly attaches to those same `thiserror` enums to dynamically surface the static catalog identifiers required by F295. If interactive prompts are utilized, `inquire`'s prompt interruptions (`InquireError::OperationInterrupted`) naturally integrate into the `thiserror` domain, mapping cleanly into the `miette` renderer as Exit Code 130 without interfering with the `signal-hook` global POSIX listeners. Finally, `human-panic` operates strictly at the `panic!` boundary, ensuring that expected domain errors routed through `miette` never trigger crash logs, fulfilling the vital distinction between controlled application exits (Exit Codes 0-5) and unhandled system crashes.

### Parameters

**OpenAI**

```text
owns error-taxonomy-exit-codes = error-contract/v1 {
  stack = [
    "thiserror@2.0.20",
    "signal-hook@0.4.4[target=unix,default-features=false,features=iterator]",
    "rust-std@msrv-1.96"
  ]

  code_source = "explicit project-owned ErrorCode catalog; wire code is ErrorCode::as_str(); never type/variant/discriminant derived"

  codes = {
    Unexpected = "PLBP000",
    Usage = "PLBP100",
    ConfigNotFound = "PLBP200",
    ConfigRead = "PLBP201",
    ConfigParse = "PLBP202",
    ConfigInvalid = "PLBP203",
    ConfigSecretDisallowed = "PLBP204",
    AuthRequired = "PLBP300",
    AuthRejected = "PLBP301",
    ResourceNotFound = "PLBP400",
    Conflict = "PLBP401",
    Transport = "PLBP500",
    RemoteApi = "PLBP501",
    Io = "PLBP600",
    BrokenPipe = "PLBP601",
    Interrupted = "PLBP700",
    Terminated = "PLBP701",
    PromptCancelled = "PLBP702"
  }

  envelope = {
    stderr_json = {"error":{"code":"<stable string>","message":"<concise string>","hint":"<optional actionable string>"}},
    hint_when_absent = "omit",
    stack_trace_in_json = false,
    stdout_on_error = "empty"
  }

  exits = {
    Success = 0,
    Failure = 1,
    Usage = 2,
    NotFound = 3,
    Auth = 4,
    Conflict = 5,
    SigInt = 130,
    SigTerm = 143
  }

  mappings = {
    Unexpected = Failure,
    Usage = Usage,
    ConfigNotFound = Usage,
    ConfigRead = Usage,
    ConfigParse = Usage,
    ConfigInvalid = Usage,
    ConfigSecretDisallowed = Usage,
    AuthRequired = Auth,
    AuthRejected = Auth,
    ResourceNotFound = NotFound,
    Conflict = Conflict,
    Transport = Failure,
    RemoteApi = Failure,
    Io = Failure,
    BrokenPipe = Failure,
    Interrupted = SigInt,
    Terminated = SigTerm,
    PromptCancelled = SigInt
  }

  signals = {
    SIGINT = {"code":"PLBP700","exit":130},
    SIGTERM = {"code":"PLBP701","exit":143},
    ownership = "executable boundary only"
  }

  prompt_cancel = {
    enabled_if = "R61 adopts interactive prompts",
    code = "PLBP702",
    exit = 130,
    detection = "typed prompt cancellation/interruption or recorded SIGINT; never string matching"
  }

  broken_pipe = {
    successful_stdout_epipe = {"diagnostic":"none","exit":0},
    other_epipe = {"code":"PLBP601","exit":1},
    mechanism = "fallible std::io::Write and ErrorKind::BrokenPipe; no global SIGPIPE handler"
  }

  crash_log = {
    enabled_for = "fatal process-boundary Unexpected errors and optional panic-hook records",
    behavior = "best-effort; failure never replaces primary error",
    path = "<R57 state-dir>/crash.log",
    fallback_path = "none",
    format = "sanitized NDJSON",
    unix_mode = "0600"
  }
}
```

```text
assumes R57/state-directory = "an optional per-application state-directory provider; this item does not select the platform path"
assumes R61/interactive-prompts = "if present, exposes a typed cancellation adapter; otherwise PromptCancelled remains reserved and unused"
CONFLICT: none
```

**Allocation guard:** before committing `PLBP100+`, compare against the full existing Python append-only catalog. Existing occupied codes win; they must not be renumbered or reassigned.

**Perplexity**

_No `Parameters` section in this provider's report (see doxa/normalization.json)._

**Gemini**

*   `owns error-taxonomy-exit-codes = bundle(thiserror, miette, strum, signal-hook, human-panic)`
*   `owns error-code-catalog-source = strum::IntoStaticStr`
*   `owns error-diagnostic-envelope = miette`
*   `owns process-interrupt-contract = signal-hook + 130/143 exit mapping`
*   `owns crash-log-persistence = human-panic`
*   `assumes interactive-prompts = inquire`
*   `assumes xdg-directory-set = directories` (assumes R57 provides a determinable mechanism to derive the state directory for crash-log persistence).

### Migration implications

**OpenAI**

| File/module | Change |
|---|---|
| `Cargo.toml` | Add `thiserror 2.0.20`; add Unix-only `signal-hook 0.4.4`; declare `rust-version = "1.96"`. |
| `src/error/catalog.rs` | Define the macro-generated catalog, `ErrorCode::ALL`, wire strings, lifecycle metadata, and exit mapping. |
| `src/error/exit.rs` | Define `CliExitCode` and `Termination` conversion. |
| `src/error/diagnostic.rs` | Define `CodedError`, `ErrorEnvelope`, hint semantics, and sanitized unexpected-error wrapper. |
| `src/error/config.rs` | Add codes needed by R52–R56 without deciding their degrade/fail behavior. |
| `src/error/domain.rs` | Add `ResourceNotFound` and `Conflict`; R03 decides when they arise. |
| `src/error/transport.rs` | Separate transport, remote API, generic I/O, and broken-pipe classifications. |
| `src/cli/entrypoint.rs` | Centralize rendering, crash persistence, cleanup, and final exit return. |
| `src/cli/signals.rs` | Translate SIGINT/SIGTERM into cooperative cancellation and final statuses. |
| `src/cli/output.rs` | Make every write fallible; render optional hint separately; classify stdout EPIPE. |
| `src/cli/crash.rs` | Add injected `CrashSink`, `NoopCrashSink`, and R57-backed `FileCrashSink`. |
| `src/cli/prompts.rs` | If R61 adopts prompts, translate typed cancellation to `PLBP702`/130. |
| `src/web/error.rs` | Expose `ErrorCode` to R70; do not put CLI exit numbers in HTTP responses. |
| `docs/reference/error-codes.md` | Document meaning, remediation, exit class, status, and introduction version. |
| `docs/reference/error-codes.json` | Machine-checkable append-only catalog snapshot. |
| `.github/workflows/ci.yml` | Test Rust 1.96 and stable on Ubuntu/macOS; add advisory/license and integration jobs. |

Downstream effects:

- **R03:** uses `ResourceNotFound`/3 versus `Transport`/1.
- **R52–R56:** use the five configuration codes, normally exit 2 when surfaced.
- **R70:** maps semantic `ErrorCode` variants to HTTP statuses independently of CLI exit values.
- **R66:** renders the same `code`/`message`/optional `hint`; JSON never includes a stack trace under the provisional F301 assumption.

**Perplexity**

_No `Migration implications` section in this provider's report (see doxa/normalization.json)._

**Gemini**

The implementation of this contract requires specific, file-level modifications across the template architecture:
*   **`src/error.rs`**: Rewrite all transient and existing error implementations to utilize `#[derive(thiserror::Error, miette::Diagnostic, strum_macros::IntoStaticStr)]`. Add explicit `#[diagnostic(code(..), help(..))]` decorators corresponding to the structured hint requirements of F296.
*   **`src/cli/mod.rs`**: Add a central `map_exit_code()` resolver function responsible for translating the root domain error into the precise integers 0, 1, 2, 3, 4, 5, 130, or 143 according to the F297 taxonomy.
*   **`src/bin/main.rs`**: Register the `human-panic` hook utilizing custom path logic derived from R57 configurations. Register the `signal-hook` listeners to trap and map signals to 130/143. Instantiate `miette::set_hook` conditionally based on the parsed `--format json` CLI parameter.
*   **`src/cli/output.rs`**: Implement standard `if err.kind() == std::io::ErrorKind::BrokenPipe { process::exit(0); }` wrappers for all buffered standard output writers to natively resolve F300 without crashing.

### Validation strategy

**OpenAI**

All commands below are **planned**, not executed in this research run.

#### Dependency and MSRV proof

```bash
cargo +1.96 check --workspace --all-targets --all-features
cargo +1.96 test --workspace --all-features
cargo +stable test --workspace --all-features
cargo clippy --workspace --all-targets --all-features -- -D warnings
cargo deny check advisories licenses
```

Expected: all pass on both `ubuntu-latest` and `macos-latest`.

#### Catalog invariants

```bash
cargo test -p rs-launch-blueprint-core error_catalog
cargo run -p xtask -- error-catalog --check
```

Tests must prove:

- every code matches `^PLBP[0-9]{3}$`;
- wire strings are unique;
- all variants occur in `ErrorCode::ALL`;
- every code has an exit mapping;
- committed prior entries are unchanged;
- generated Markdown and JSON are current;
- an enum-variant rename test fixture retains the same wire string.

#### Error-envelope matrix

```bash
cargo test -p rs-launch-blueprint-cli --test error_contract
```

Expected fixture matrix:

| Scenario | Code | Exit | Stdout | Stderr |
|---|---:|---:|---|---|
| Unknown CLI flag | `PLBP100` | 2 | empty | one envelope |
| Explicit config missing | `PLBP200` | 2 | empty | one envelope |
| Invalid config | `PLBP203` | 2 | empty | one envelope with optional hint |
| Missing credential | `PLBP300` | 4 | empty | one envelope |
| Resource absent | `PLBP400` | 3 | empty | one envelope |
| Conflict | `PLBP401` | 5 | empty | one envelope |
| Transport failure | `PLBP500` | 1 | empty | one envelope |
| Unexpected error | `PLBP000` | 1 | empty | one envelope |

#### Signal checks

```bash
bash tests/scripts/sigint.sh target/debug/rs-launch-blueprint
bash tests/scripts/sigterm.sh target/debug/rs-launch-blueprint
```

Expected:

- SIGINT: status 130, `PLBP700`, no raw signal-library text.
- SIGTERM: status 143, `PLBP701`, graceful cleanup attempted.
- JSON mode: exactly one stderr JSON document.

#### Prompt checks, contingent on R61

Unit-test the adapter directly:

```rust
assert_eq!(
    classify_prompt_error(InquireError::OperationInterrupted),
    (ErrorCode::PromptCancelled, CliExitCode::SigInt)
);
```

Also test cancellation, EOF, and the console-backend SIGINT path.

#### Broken-pipe check

```bash
set +e
target/debug/rs-launch-blueprint test-support emit-many 2>epipe.err \
  | head -n 1 >/dev/null
statuses=("${PIPESTATUS[@]}")

test "${statuses[0]}" -eq 0
test "${statuses[1]}" -eq 0
test ! -s epipe.err
```

Expected: no panic text, no “broken pipe” diagnostic, producer status 0.

#### Crash persistence

```bash
tmp="$(mktemp -d)"
RS_LAUNCH_BLUEPRINT_TEST_STATE="$tmp" \
  target/debug/rs-launch-blueprint test-support unexpected \
  --format json 2>error.json
status=$?

test "$status" -eq 1
test -s "$tmp/crash.log"
test "$(stat -c '%a' "$tmp/crash.log" 2>/dev/null || stat -f '%Lp' "$tmp/crash.log")" = 600
jq -e 'select(.code == "PLBP000")' "$tmp/crash.log"
jq -e '.error.code == "PLBP000" and (.error | has("backtrace") | not)' error.json
```

Additional cases:

- an expected error creates no crash record;
- an unwritable state directory leaves the original code and exit unchanged;
- crash content contains no fixture token, environment secret, or configuration value;
- normal and JSON modes suppress traces;
- verbose human mode trace behavior follows the final F301 disposition.

#### Performance and integration measurements

```bash
cargo build --release
cargo tree --edges normal
cargo llvm-lines --release        # if installed
cargo bloat --release -n 30       # if installed
hyperfine \
  'target/release/rs-launch-blueprint test-support success' \
  'target/release/rs-launch-blueprint test-support classified-error'
```

Record:

- clean versus stack-enabled release-binary size;
- clean incremental compile time;
- idle signal-helper thread/resource usage;
- median SIGINT-to-process-exit latency;
- unexpected-error crash-write latency.

No throughput acceptance threshold should be set until these measurements are run on the same host and configuration.

#### Canonical ecosystem-metric refresh

```bash
for crate in thiserror signal-hook; do
  curl -fsSL \
    -H 'User-Agent: rs-launch-blueprint-research/1.0 (maintainer-contact)' \
    "https://crates.io/api/v1/crates/$crate" \
    > "$crate.crate.json"

  curl -fsSL \
    -H 'User-Agent: rs-launch-blueprint-research/1.0 (maintainer-contact)' \
    "https://crates.io/api/v1/crates/$crate/versions" \
    > "$crate.versions.json"
done

gh api repos/dtolnay/thiserror
gh api 'search/issues?q=repo:dtolnay/thiserror+is:issue+is:open'
gh api repos/vorner/signal-hook
gh api 'search/issues?q=repo:vorner/signal-hook+is:issue+is:open'
```

A small script must then inspect the ten most recently opened issues, find the first response by a maintainer/owner/member/collaborator, and report median days plus unanswered count.

**Perplexity**

_No `Validation strategy` section in this provider's report (see doxa/normalization.json)._

**Gemini**

The empirical validation of this architectural bundle requires executing specific commands to prove the principles hold under realistic operational stress:
1.  **JSON Envelope Test:** Execute `plbp --format json <invalid-command>`. Assert that the standard error stream contains exactly one valid JSON object encapsulating `{"code": "...", "message": "...", "help": "..."}` and no other textual formatting.
2.  **EPIPE Suppression Test:** Execute `plbp <command-generating-heavy-output> | head -n 1`. Assert that the process exits with code 0 and the standard output closes silently without an operating system panic trace.
3.  **Signal Propagation Test:** Boot the process into a simulated long-running task. Send `kill -15 <pid>`. Assert the process traps the `SIGTERM` signal and explicitly returns exit code 143 to the operating system.
4.  **Prompt Cancellation Test:** Initiate an interactive `inquire` text prompt. Send a `Ctrl-C` key sequence. Assert the process intercepts the keystroke, aborts the prompt, and exits gracefully with exit code 130.

### Confidence & re-verify trigger

**OpenAI**

**Recommendation confidence: high for architecture and observable behavior; medium-high overall.**

Strongest findings:

1. Stable machine codes must be explicit and independent of Rust type names.
2. Fine-grained `ErrorCode` and coarse `CliExitCode` should be separate.
3. The 0/1/2/3/4/5/130/143 taxonomy is more shell-composable than Python’s 0–5 interruption model.
4. `thiserror` plus a project-owned catalog is a better library/web fit than adopting a rich diagnostic renderer as the core model.
5. EPIPE should be classified at fallible stdout writes, not by a global signal policy.
6. Signal and crash-file side effects belong only at executable boundaries.

Re-verify before implementation if any of these occurs:

- the complete Python codebook collides with proposed `PLBP100+` allocations;
- F301’s owner disposition changes trace capture or JSON suppression;
- R57 provides no state-directory capability;
- R61 chooses a prompt crate without typed cancellation;
- Rust stabilizes `on_broken_pipe` or changes default SIGPIPE handling;
- Windows enters the required target matrix;
- `thiserror` or `signal-hook` publishes a major release, raises MSRV above 1.96, or receives a RustSec advisory;
- exact crates.io/GitHub metrics or the required adopter checks materially contradict the current maintenance assessment.

**Perplexity**

_No `Confidence & re-verify trigger` section in this provider's report (see doxa/normalization.json)._

**Gemini**

Confidence in this architectural bundle is absolute. The chosen combination represents the pinnacle of stable, battle-tested Rust crates tailored specifically to fulfill deep-diagnostic, POSIX-compliant CLI and library requirements. Re-verification is only warranted under extreme ecosystem shifts, such as the `std` library standardizing `std::error::Error` derivation, introducing native signal captures in Edition 2027, or if the R57 parameter entirely declines the establishment of a state directory configuration.

**Sources:**
1. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFfRJxr7Yd6r3ACWBeMlZ0yTJ6PoEZY2jI2vRYItDNBoz0srU4MOuYWQyT5hrUtKXb5r7IiI7u0F7c9Fz_4CuvC6iecohpjHBCpFmR3CN2lYcBu1E4V5rNw9dJeNmAHTJzeio_u37bG8oC-Q==)
2. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbvPmcWHhI2wBB7-jWpI9wr2tWh4-mftvgoHaqEdalSkpy7R5RSJC_qa48iWZjmIlYQrFLWgRWmyta2UKGVdPqJo__KQ-oy9CBkgClCL_SXQcsmKzT09jjyaxTW3QRc5eyazJveyzz9D06U5PD-KzonMcAoxpJNiO0PzcESPIi)
3. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEP2TNBX-dg2lWHnD18VtltCJf63zq6m90nw5lpPJGuYNKCaca-bQHRzkbK7ak4n2y54JDAZiu1Wj37vw0PREpjg7NJKwk9Q_RVisuSJV5PiWV4FdspHOnPztJrUgoOfQVep-8VOGUer0622-mjqrM_nu-gXDA5jENauITnB0nbzo7F_hlPAFvi-pEKEyWLvC80Kco=)
4. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGQYQeYvunAK9qv1O-rfOfN5ur5zHcn6gwxODkIH-vMi6YmFYgStO4eO-Z-vyPaR4FjY4eEDqwiokl4CFOi4YtnS_a-sj9BBw00HJWiuaKqHNsLcdnOcZ6RF2i9TLGQ0w==)
5. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEqWsLAuKMWZ4BDSt0KUhi_nA_kL1AIvWEnkFM9Ni80cjUEVZvS-ZiWRSA8QtW1d705uVPYPkU9AAUFDmCX7wLJoGcjDsfUirUR8J2GhmsCS2JHB0YmNFiU)
6. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFtqO2FsBB97jLrYvMWF9D2eKLGB0E8h36W5wtkNqtaXcFkBML97rbYLD227YZohXHHEZnFzcum8gE99UEBAfyJXaImx4pSy0L5PMk16HWMFkHWoSiM)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGZpt_6ltrLSM4WiH6vuZrFxu6JWb3iJUyRojxcwoqlqd60nrUP7Aa1IzeX6FcLKMRFS86VHUfSq4jA_XOLvLpyUabwBmp3Eremli_dI8JSig==)
8. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE_liT5fvp-ZPcr5fHjZ3GuuOBgG56Yp4rjrRet0czjjPtLddtTo05YcqduPTDQ89XDi_qvZowDyjie9flk9FwMsyjTT6fptUUWUox5ZkXl58u0oFbY0jT6u7A=)
9. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEkaCKPXSGu_Q0quSK_qcrwqv1wxrAB81gdVkuE7Ayjvl3sYQKgAn5vhuj0-Mb9PIaSKJ_CvCSGNv0VMKTN_pCTv1Bws5WzqdzLa1k3EpBW1nk=)
10. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEjXahPjaNn3Na4Y93DmkRsE_vfJLbm3HLiRxo8aWySxnsKz3j__MlZkzRD_JMyLDXDmoW0vMPOMGKrD3NONwpOuuB95hMpo7AmHeymXdabDvns6c7sZAloavM=)
11. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFSe5w02UOVKCV-lkry_HtptovN-EIb1U4XNb0eY1KZDr4iHHSXGrz7sxJYVUatoyBqDq2BBtY8-OsQZ1s1OIn7dco4xBdci_KNVSUqmLFPIIhgsCmN)
12. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHozukyAPzSIK-n2XcVb32XoOMKbrK8Ks4bYZbVwgjWycOFCeAeMhTdwYt4suMZRaY4OwWeEVso-KQD4ffOVrcYhxN29CFbZnlEc0_8s2KCGP3hmGzWbZ-Ln5V9H3O_-kK5HOwXwMaUaS_R4jbfN_-p)
13. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFnouNl5KTLgEb-jrXsEWkCyKQwMlPGPsSFqLOx1oQihGCCsaJHkUnfMRexAwJ9YL_WShIQXUiKJTFilaXiak033mKE9b1qEhRVjA3wM98z8F4thiBlxQbB94Rs)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQErpcdFbwVatjlXvUNv5f6H3TZj37reD22SRc5k2ZuzheNKTiW8FVXIXjx_KCILHs1E-Tf07aBDjvba20WpnPzG5IFjmLiEoaapfq8yECr9KEG-tNarPkWiSqQ=)
15. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHXzevZlIwebZ9DNwIQGkwf8c4H67WXgdS6WMR6Ga6zsPwFqP0eE1NCyCycxMLH-Ojnnwer_p6OmbkRKeLENYZvKO0NAH-w2a96fot4pbp85wdCtHK5bug=)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFgnqBOlIHEUgDfzEYqYSNHCtfmxlxe7rxw2OF8nLXFzGXaqaLTBV2Hns0lMneYevbDzPOHDzXKAMhrRCBSITMUH10CGvw2vP-8soO44Z2AKGp7WusT-SBkb_TllGQpDreWPJFHKrmX88YVCyyepSuCkSrtkhFUEAD7MES3Pd30)
17. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGwjqQJ_kwNxN_aGqjxO21vQeNAUr2DGkzqtef5cZUSL_TDvy_xNlhnmoT4QkVqc9i3TaVbjhRW7n47DWU7XJcGDTRA39ynQu8FogKjsuG3mhxCgx75YxMJgE8RxNkfBZXoaNZtYUNzJFI_7WgYeqfP_BxtQUD8GdUp_eVfNuCz-JH4Ut6a4A==)
18. [stackoverflow.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHry1sojPN9vD4Fi94A0m7SLwsGTJIc_N8MPRB6oGplhXpDuXR-5bRdiwvkfAM0cqNdHkZoJ1rM-__9I32UZmJoN8oECiCXerWWM7mGRC-E86p3CjTJeerynh-8bHpj6tzhQ-uIL6gC_QTkBtsOwgAqKhqbihXxowJFfvU5IH-tY4SXMXgWjbrjJocLQ-I-PxZmENebgJrc4VfXWm0ur1nz6Zb_e649B7G09p8BfYUQgZLnhQ==)
19. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFJmdU-L8X8ERXskNfoEn6puAzBdcB6ZihsvKyENIZmdEio8Ps5zX8A7bS91Ns8RJds_99FvLN5oNmO2c4aMhFA7JSO26tJX3juAPRN54obiM9802dpanog8LuPRN5ez8U0cn5z_EQz2khJCooPR1EfKX1jwMpI63bugw4NEhg=)
20. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQENL5CpaeVHOusfOAdavXbwSywE04u6tEQ--qBQp5PKZz8JBSCkDF8nJq2jM1A-MLoZX_cIoGzDEQCBX84lf5WQDCYo8ltzTYY=)
21. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGVQipKppvvTribihZV7XXGz1Qm7KO6oEgKpPH6yXtjPff7O0_KngFgg9JTOtxJdp_xInEuSSFJXXfyg9faXuzCjqrMJ4cQLAmWACamj3tC)
22. [Link](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFOBjWEVH961vN5wzjPBJw2MRNB0lLix3Up4edz9-3RuPHZPdJ35AB929s_TfsUE_KtVSE4THrnVObdqRO_URghxUshjGi_v0Xd63QDkw1p2hrRK_f2qPnCW13HH69W7dKn8Tj0J8jtiHVr1MUZMYZFm_wEh6Zu5Wo=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEG7nIRz0hC6nF9relQi8Xuy_7tesI_WCHnJPk-_KmggrcS8Sh0mJEUazuYB9kIAJdbI3wUtGkbKXkifgCD0LhAUrSnOwU603KVrn6o1e0yZVkTI-bNx-2HWSZ87Shn)
24. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEuK3QW9gUIdM4XIMZs0tnw3SWVZEy4oOteLbuTaQyz4SAZJx3lvodbenFmYIXs27fK8YV_DB6EW3xGHS99p7w4INT2_1aDcNTldZbgImKQC8YXAiPGlxpLIvUPeGUZqIRo6M4xwQVA2Fn6C15GPul1MNlvXAcR5rA=)
25. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFu8-9lw1sKAFsyRh6IxCSIM-yn3pXT_qpG7C2gu80E0MbYLf8BSAM_Fr6z4_TahxjPB0lgwUucigxLi0mjVO862ahQsSFDvcl_NWrxNyOH1Rqygv926m9zhBO-)
26. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHYr08N7vgAOZpdilw1ZZUyUJroIeb3uAJ2Bjt6_IQHXwYP5C3ayuAyUxZQzkVVGBTIrcKbMGgvC2VUIYbDEpNcVRu8lc0qu8liDeyHVSVtvdObkh4m8DX4fm8=)
27. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFkTy-qzlD0Bb4UFnHy3DQX2CEDAW0Z0mKKWw3O_4PmCcA-rXFXBdknKHYmcsf8C5WyJ35uwLQMlu5Nes2RzeA0cPYINzAyNN1kzcqmm9B9Jm1UWlMdP5-xOR1I)
28. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH1tN5QR_Bj4vI-EkM-L7xadBTdMfSuIMnndHpCoLEopZ5In0C1LNUYkozjVJVEXCcC0UuLmOhx-yUX2LmBlae25vfajNPCgFZyLCKnq9CZWiBimROQ)
29. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEl-xmFgvJf8Hy0nnx9ZIcJQOyhdwFoIDzst9Vt7nIDaGAf7HTVtqp7eCJroejnTf6RcDaluJ8PTiJYq40aLqwDHg2wUZELFDvKdqtYbWhJgcc1ZdKL5ii4HhkzuphFcyoxyYpVmoq1GCCj70vIY1w=)
30. [dev.to](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEGN9AVzJbIiz8D7vWgBPuo1s_MZQ11em7_kZAHBSCHi6SDrC72Ri313B7ema-Ic7Vl6osZirb7xnm9Z06ua7stGd85xdXy4p4VpEzbgaFvGcOTeMCpeywjMERkd3jFBdrxrazU4le0QaCzyYrSpoPo7AWA4A==)
31. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG71319kf3n2nCsWE8ZolqdqGrhvY8Fym1sZVOy4sKaTInb7zfvXBzYwhbYHYjmC5prcULCsIwtiJFA_xyOhtr4PZId6-GeAwuBjRckJcGd8DoeJyZKlD9qL6-fmoU2p9J3XpZFBm8PM9ol0bbuzA==)
32. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQE1pjS8FoOcOMzbFDegqDYhP9H6akauxxrh21_bR1roAFm7UOW-L_lZkxcA7cr4nd6bG8rdS6AiTrEu8CoZLf_byOvYrFUI2Nc-T_qOlV0FvahRXgOgZPNPGSsOuQ==)
33. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHO69ZAhgyhRgFT-EICw5zIdmEv81oGvYbzncA0VTqbfOWReqAVxhD4-aMUeiBWz1u93NlV-CsfPIY-0esTZjgFx98FAwTbm2NzxlD3c0FdomDqcDMyOSIgmf-leGo4OZRnc-j70w==)
34. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFlBup400jHQBQHgojiyeF4HAdouP2DIi6Ity6eod7ZLWhbyy-1QbxScfS7DhU3POs1FZayxrQjA_EcEv7mTuujhjVCXvqWH8_F7LBWhKPm5iRqb8hgwk9jqw==)
35. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG85pr9CyTPZnbhvO-oZqTsU9nCYgOoeq1w3ev64g6bpy0RQ7GmPc23N3dCWybmHLJ_wZlmi-yUkpL3g7pYm3JEdP9bVltwqN1WX0ccYwyDSw2HhhVqIMi_w1bdD1E1YlA=)
36. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEu2qirIvYMwdawzHHDT5Cm-I2-uVpPhkFtuARS2KpRYgxmq7lznGKzfqUTmjR9J_wywU79uRgMo3BlQwuy5F9Ic0DyM4YE8dzv4Sg6Rk0gWVNG4sucyFcHMURDwb8qAQcWYW_Fwc_7UxBQV-nO)
37. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFbeTiqe6Sa3vNQ5kPv5XkFT7kc0oBKgpMa7KjUO-UYTozMrjgK2erP81-KjSJrGnxOMfeKfa2aOiEDj6qZsHRawOLptsI4AxxL6ITVQfubOZOCsXq6v_15wsD3TsKw_AvG7t7O7_qXo9Z8PqOThQ8Ari-nIIn7AIgEwACCttkgXmMewnG-E-lRLJk=)
38. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGli_rF6itHFlecJWT9ZF73irFWiPIzQU4Vgc56Ii6rF9qTEeHlhE3pHFQx22V6cXUJNMlNFgAqH8YP27MGat8dPBxCw8phscxKxkW7H_wf-TzA_tcGLvDGYE0LJzmh8TMT_PcgTWY8IzE9Pje2XN7xb17elgpOwml44cR1iJ30GpupXcdo6MkKeJQ=)

### Sources

**OpenAI**

All retrieved September 9, 2026 unless noted.

- Rust `Termination`: `https://doc.rust-lang.org/std/process/trait.Termination.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/trait.Termination.html))
- Rust `process::exit`: `https://doc.rust-lang.org/std/process/fn.exit.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/process/fn.exit.html))
- Rust `ErrorKind`: `https://doc.rust-lang.org/std/io/enum.ErrorKind.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/io/enum.ErrorKind.html))
- Rust `Backtrace`: `https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html))
- Cargo SemVer compatibility: `https://doc.rust-lang.org/cargo/reference/semver.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/semver.html))
- Rust RFC 2965: `https://rust-lang.github.io/rfcs/2965-project-error-handling.html` ([rust-lang.github.io](https://rust-lang.github.io/rfcs/2965-project-error-handling.html))
- Rust API Guidelines, errors: `https://rust-lang.github.io/api-guidelines/interoperability.html` ([rust-lang.github.io](https://rust-lang.github.io/api-guidelines/interoperability.html))
- Rust SIGPIPE tracking: `https://github.com/rust-lang/rust/issues/150588` ([github.com](https://github.com/rust-lang/rust/issues/150588))
- Rust runtime SIGPIPE source: `https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs` ([github.com](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs))
- POSIX.1-2024 shell exit statuses: `https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html` ([pubs.opengroup.org](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html))
- GNU Bash exit status: `https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html` ([gnu.org](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html))
- `thiserror` documentation: `https://docs.rs/thiserror/2.0.20/thiserror/` ([docs.rs](https://docs.rs/thiserror/latest/thiserror/))
- `thiserror` repository: `https://github.com/dtolnay/thiserror` ([github.com](https://github.com/dtolnay/thiserror))
- `signal-hook` documentation: `https://docs.rs/signal-hook/0.4.4/signal_hook/` ([docs.rs](https://docs.rs/crate/signal-hook/latest))
- `signal-hook` repository: `https://github.com/vorner/signal-hook` ([github.com](https://github.com/vorner/signal-hook))
- `miette::Diagnostic`: `https://docs.rs/miette/7.6.0/miette/trait.Diagnostic.html` ([docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html))
- `clap::Error::exit_code`: `https://docs.rs/clap/latest/clap/error/struct.Error.html` ([docs.rs](https://docs.rs/clap/latest/clap/error/struct.Error.html))
- `inquire::InquireError`: `https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html` ([docs.rs](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html))
- RFC 9457 extension members: `https://www.rfc-editor.org/rfc/rfc9457.html` ([rfc-editor.org](https://www.rfc-editor.org/rfc/rfc9457.html))
- 2025 State of Rust Survey: `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- RustSec advisory index: `https://rustsec.org/advisories/` ([rustsec.org](https://rustsec.org/advisories/))

**Sources**
- [https://doc.rust-lang.org/std/process/trait.Termination.html](https://doc.rust-lang.org/std/process/trait.Termination.html)
- [https://docs.rs/thiserror/latest/thiserror/](https://docs.rs/thiserror/latest/thiserror/)
- [https://lib.rs/crates/error-stack](https://lib.rs/crates/error-stack)
- [https://rust-lang.github.io/api-guidelines/interoperability.html](https://rust-lang.github.io/api-guidelines/interoperability.html)
- [https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://lib.rs/crates/thiserror](https://lib.rs/crates/thiserror)
- [https://docs.rs/miette/latest/miette/](https://docs.rs/miette/latest/miette/)
- [https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs](https://github.com/rust-lang/rust/blob/main/library/std/src/rt.rs)
- [https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html)
- [https://rust-lang.github.io/rfcs/2965-project-error-handling.html](https://rust-lang.github.io/rfcs/2965-project-error-handling.html)
- [https://doc.rust-lang.org/cargo/reference/semver.html](https://doc.rust-lang.org/cargo/reference/semver.html)
- [https://docs.rs/miette/latest/miette/trait.Diagnostic.html](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)
- [https://docs.rs/clap/latest/clap/error/struct.Error.html](https://docs.rs/clap/latest/clap/error/struct.Error.html)
- [https://docs.rs/crate/signal-hook/latest](https://docs.rs/crate/signal-hook/latest)
- [https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html](https://docs.rs/inquire/latest/inquire/error/enum.InquireError.html)
- [https://doc.rust-lang.org/std/io/enum.ErrorKind.html](https://doc.rust-lang.org/std/io/enum.ErrorKind.html)
- [https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html)
- [https://github.com/dtolnay/thiserror/blob/master/Cargo.toml](https://github.com/dtolnay/thiserror/blob/master/Cargo.toml)
- [https://openapps.pro/packages/thiserror](https://openapps.pro/packages/thiserror)
- [https://docs.rs/crate/thiserror/latest](https://docs.rs/crate/thiserror/latest)
- [https://github.com/dtolnay/thiserror/releases](https://github.com/dtolnay/thiserror/releases)
- [https://github.com/dtolnay/thiserror/actions](https://github.com/dtolnay/thiserror/actions)
- [https://github.com/vorner/signal-hook/blob/master/Cargo.toml](https://github.com/vorner/signal-hook/blob/master/Cargo.toml)
- [https://rustsec.org/advisories/](https://rustsec.org/advisories/)
- [https://openapps.pro/packages/signal-hook](https://openapps.pro/packages/signal-hook)
- [https://github.com/vorner/signal-hook/actions](https://github.com/vorner/signal-hook/actions)
- [https://github.com/vorner/signal-hook/issues](https://github.com/vorner/signal-hook/issues)
- [https://docs.rs/pipecheck/latest/pipecheck/](https://docs.rs/pipecheck/latest/pipecheck/)
- [https://doc.rust-lang.org/std/process/fn.exit.html](https://doc.rust-lang.org/std/process/fn.exit.html)
- [https://github.com/rust-lang/rust/issues/150588](https://github.com/rust-lang/rust/issues/150588)
- [https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/V3_chap02.html)
- [https://github.com/dtolnay/thiserror](https://github.com/dtolnay/thiserror)
- [https://github.com/vorner/signal-hook](https://github.com/vorner/signal-hook)
- [https://www.rfc-editor.org/rfc/rfc9457.html](https://www.rfc-editor.org/rfc/rfc9457.html)

**Perplexity**

- [thiserror - Comprehensive Rust - Google](https://google.github.io/comprehensive-rust/error-handling/thiserror.html)
- [anyhow 1.0.104](https://docs.rs/crate/anyhow/latest)
- [How to use thiserror crate — Rust FAQ](https://www.rustfaq.org/en/how-to-use-thiserror-crate/)
- [Error Handling in Rust with thiserror | Iago Bozza](https://iagobozza.com/blog/error-handling-in-rust-with-thiserror/)
- [ctrlc - Rust](https://docs.rs/ctrlc)
- [10. Error Handling Patterns - Rust Patterns & Engineering How-Tos](https://microsoft.github.io/RustTraining/rust-patterns-book/ch10-error-handling-patterns.html)
- [How to Use the anyhow Crate for Application Errors — Rust FAQ](https://www.rustfaq.org/en/how-to-use-the-anyhow-crate-for-application-errors/)
- [Signal Handling | rust-cli/book | DeepWiki](https://deepwiki.com/rust-cli/book/4.3-signal-handling)
- [ctrlc - Rust](https://docs.rs/ctrlc/latest/ctrlc/)
- [ctrlc: Simple Cross-Platform Ctrl-C Handler for Rust](https://openapps.pro/packages/ctrlc)
- [Information for rust:thiserror-impl](https://repology.org/project/rust:thiserror-impl/information)
- [Signal-hook-registry — Rust API for Unix // Lib.rs](https://lib.rs/crates/signal-hook-registry)
- [python3-maturin-1.8.6-r0 do_unpack](https://errors.yoctoproject.org/Errors/Details/861340/)
- [thiserror-impl 2.0.18 - Docs.rs](https://docs.rs/crate/thiserror-impl/latest)
- [thiserror 2.0.18 - Docs.rs](https://docs.rs/crate/thiserror/latest)
- [Signal-hook - Unix APIs](https://lib.rs/crates/signal-hook)
- [signal-hook - Rust Crate - Cargo Run](https://cargo-run.news/crates/signal-hook)
- [Information for rav1e](https://repology.org/project/rav1e/information)
- [Function signal_hook::register](https://teaclave.apache.org/api-docs/crates-app/signal_hook/fn.register.html)

**Cost**
Total: $0.6202

**Gemini**

- [stackoverflow.com](https://stackoverflow.com/questions/26280859/how-to-catch-signals-in-rust)
- [github.io](https://rust-cli.github.io/book/in-depth/signals.html)
- [github.io](https://microsoft.github.io/RustTraining/rust-patterns-book/ch10-error-handling-patterns.html)
- [crates.io](https://crates.io/crates/thiserror)
- [crates.io](https://crates.io/crates/thiserror/1.0.24)
- [crates.io](https://crates.io/crates/miette)
- [docs.rs](https://docs.rs/oxc-miette)
- [crates.io](https://crates.io/crates/signal-hook)
- [docs.rs](https://docs.rs/signal-hook)
- [crates.io](https://crates.io/crates/human-panic)
- [crates.io](https://crates.io/crates/anyhow)
- [docs.rs](https://docs.rs/miette/latest/miette/trait.Diagnostic.html)
- [crates.io](https://crates.io/crates/strum/0.15.0)
- [crates.io](https://crates.io/users/emmatebibyte)
- [crates.io](https://crates.io/users/andreastt)
- [docs.rs](https://docs.rs/inquire-clack/latest/inquire/error/enum.InquireError.html)
- [rust-lang.org](https://users.rust-lang.org/t/broken-pipe-when-attempt-to-write-to-stdout/111186)
- [stackoverflow.com](https://stackoverflow.com/questions/65755853/simple-word-count-rust-program-outputs-valid-stdout-but-panicks-when-piped-to-he)
- [medium.com](https://sigridjin.medium.com/handling-posix-signals-in-rust-fac42c33e5b6)
- [crates.io](https://crates.io/)
- [crates.io](https://crates.io/crates/)
- [Link](https://docs.rs/miette/latest/miette/struct.JSONReportHandler.html)
- [crates.io](https://crates.io/crates/miette/security)
- [docs.rs](https://docs.rs/miette/latest/miette/struct.MietteHandlerOpts.html)
- [crates.io](https://crates.io/crates/miette/3.0.1)
- [crates.io](https://crates.io/crates/miette/code)
- [crates.io](https://crates.io/crates/strum/0.27.2)
- [crates.io](https://crates.io/crates/strum/)
- [docs.rs](https://docs.rs/strum/latest/strum/derive.EnumString.html)
- [dev.to](https://dev.to/talzvon/handling-unix-kill-signals-in-rust-55g6)
- [crates.io](https://crates.io/crates/signal-hook-registry/1.4.1/code)
- [crates.io](https://crates.io/crates/inquire/0.0.6)
- [crates.io](https://crates.io/crates/human-panic/2.0.4/code)
- [github.com](https://github.com/kdkasad/crashlog)
- [crates.io](https://crates.io/crates/human-panic/1.2.1)
- [crates.io](https://crates.io/crates/human-panic/1.1.2/dependencies)
- [reddit.com](https://www.reddit.com/r/rust/comments/1305ihw/rusts_philosophy_of_panic_recovering/)
- [rust-lang.org](https://internals.rust-lang.org/t/configure-the-crates-required-panic-strategy/22271)
