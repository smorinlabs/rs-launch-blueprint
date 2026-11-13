### Landscape

R55 decides a configuration *failure-policy pattern*, not a TOML parser, schema crate, discovery-tier count, or logging implementation. The first-party bin is `std::fs`/`std::io::ErrorKind` plus `Result`; the Rust Book treats `Result` as the representation for recoverable failure. The established bin is a provenance-carrying layer result over `toml::Value` 1.1.6+spec-1.1.0, `serde` 1.0.229, and deferred emission through `tracing` 0.1.44. The up-and-comer bin contains no candidate that improves this policy: `serde_path_to_error` improves an all-or-nothing error location, not recovery of later fields. The recommendation therefore adds no R55-specific crate. [Rust Book](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html), [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html), [Serde Deserialize](https://docs.rs/serde/1.0.229/serde/de/trait.Deserialize.html), [tracing warn](https://docs.rs/tracing/0.1.44/tracing/macro.warn.html) (all retrieved 2026-09-16).

Authorities are the Rust Project's Rust Book for recoverable errors, the `toml`, Serde, and tracing maintainers' versioned API documentation for their APIs, and RustSec for advisories; these are respectively the language authority, package maintainers, and Rust's advisory database. Practice is not inferred from downloads: Cargo's own manifest declares `serde = "1.0.228"` and `toml = "1.1.5"`; the well-regarded Rust Project package had 15,484 GitHub stars and a 2026-09-16 push when retrieved. Axum's `axum-core` declares optional `tracing = "0.1.37"`; Axum had 27,156 stars and a 2026-09-15 push when retrieved. These show the three interfaces compose in mainstream maintained Rust projects, but do not decide R55's failure policy. [Cargo manifest](https://api.github.com/repos/rust-lang/cargo/contents/Cargo.toml), [Cargo repository](https://api.github.com/repos/rust-lang/cargo), [Axum core manifest](https://api.github.com/repos/tokio-rs/axum/contents/axum-core/Cargo.toml), [Axum repository](https://api.github.com/repos/tokio-rs/axum) (all retrieved 2026-09-16).

The pinned precedent is mixed, not a winner: Python makes a missing explicit file an empty writable layer, skips an unreadable discovered layer with a warning, then removes an invalid key; TypeScript rejects an explicit absent path and a whole invalid file. The ledger classifies R55 as partly harmonized: the user-facing distinction between expected absence and integrity failure is shared, while Rust's field-recovery mechanism is native. [Python config pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/config.py#L96-L139), [Python settings pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/settings.py#L145-L176), [TypeScript config pin](https://github.com/smorinlabs/ts-launch-blueprint/blob/cb1cbcb2e88b898e8c081b0abbfabc1630079c00/src/lib/config.ts#L102-L166), [divergence analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md) (all retrieved 2026-09-16).

### Principles and implementation

The shared requirement is an intent-sensitive configuration boundary: absence that is normal for the selected lifecycle must not stop a command, while a document the user explicitly selected must never be silently misrepresented as applied. Agreement level: capability/policy for F235 and F236, and architectural pattern for F238; the Rust implementation may differ. Essential outcomes are: (1) missing explicit `--config` is an empty layer and a valid future `config set` target; (2) an unreadable or syntactically invalid discovered layer is skipped with a path-bearing warning if R54 supplies such a tier; (3) an unreadable or syntactically invalid existing explicit file is fatal; and (4) one malformed declared value is omitted with a path-bearing warning while independent valid settings continue. [Python config pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/config.py#L96-L121), [baseline review F237](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/BASELINE-REVIEW.md#L108) (retrieved 2026-09-16).

Choose a small provenance pattern: each candidate path is `ConfigLayer { origin: Explicit | Discovered, path }`; loading yields `Parsed(toml::Value)`, `Absent`, a structured nonfatal `ConfigWarning`, or a fatal error. Parse first into `toml::Value`, validate each declared leaf independently through the R53-selected Serde schema or field validator, omit only the failing leaf, and merge the remaining validated fragments in R54 precedence order. `toml::Value` provides tables, `get`, and `try_into`, so typed conversion can be attempted at a leaf rather than requiring the whole settings struct to deserialize. A direct `Settings: Deserialize` alternative is excluded for the tolerant branch because one deserialization error terminates that operation; a custom deserializer is technically possible but couples recovery policy to each field and is less auditable than the value boundary. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html), [Serde field attributes](https://serde.rs/field-attrs.html) (retrieved 2026-09-16).

Validate each layer before merging. That lets a bad high-precedence `output.color` disappear and exposes a valid lower-precedence `output.color` rather than accidentally deleting it. This corrects a weakness in Python's merge-then-pop mechanism without changing its intended key-local resilience. `ConfigWarning` should contain `kind`, `origin`, `path`, optional dotted `key`, and a safe error summary. The library returns `LoadedConfig { settings, warnings }`; the CLI or web composition root emits each warning through the logging contract R58, eventually `tracing::warn!`, so library code owns neither global subscriber initialization nor process output. `warn!` constructs a warn-level event; R67 also requires library code not to write streams. [Python settings pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/settings.py#L145-L176), [tracing warn](https://docs.rs/tracing/0.1.44/tracing/macro.warn.html), [R67 parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (all retrieved 2026-09-16).

Observable acceptance criteria: a nonexistent explicit path returns defaults and its exact path as the write target; a corrupt explicit file returns the R67 fatal document error; a corrupt discovered path yields one warning naming that path and leaves other layers active; a single invalid leaf yields one warning naming that dotted key, preserves sibling keys, and falls back to the next valid lower-precedence value or default; a cross-field invariant failure follows R53's yet-unselected policy and is not mislabeled as a recoverable leaf. Planned checks, not executed, appear below. `BASELINE-REVIEW: F238 — local recoverability must preserve a valid lower-precedence value — validate each layer's leaves before precedence merge rather than Python's merge-then-pop — pinned Python code merges before removing the invalid key, while toml::Value supplies the required leaf boundary; affected R53, R54, R55, R58, R67.` [Python settings pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/settings.py#L145-L176), [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html) (retrieved 2026-09-16).

### Recommendation

One stack: R55 adds the `ConfigLayer`/`LoadedConfig`/`ConfigWarning` policy pattern and no crate; consume `toml` 1.1.6+spec-1.1.0 from R52 to form `toml::Value`, `serde` 1.0.229 from R53 for leaf conversion, and `tracing` 0.1.44 from R58 only at the composition boundary. Use empty explicit absence; warn-and-skip discovered parse or I/O failure; fail existing explicit parse or I/O failure; warn-and-drop an individually invalid declared leaf before merge. This is stable-Rust, edition-2024 compatible by the observed `rust_version` floors, has no async-runtime coupling, and imposes one retained TOML tree plus small warning vectors per load. [crates.io toml](https://crates.io/api/v1/crates/toml), [toml versions](https://crates.io/api/v1/crates/toml/versions), [crates.io serde](https://crates.io/api/v1/crates/serde), [serde versions](https://crates.io/api/v1/crates/serde/versions), [crates.io tracing](https://crates.io/api/v1/crates/tracing), [tracing versions](https://crates.io/api/v1/crates/tracing/versions) (all retrieved 2026-09-16).

### Members

#### Provenance-carrying tolerant-load pattern

##### Landscape

This member is a pattern, so crate download, release, stars, issues, advisory, and adopter figures are inapplicable; it adds no package. Its direct alternatives are direct whole-struct deserialization, per-field custom Serde deserializers, and untyped-value-plus-leaf validation. [Serde Deserialize](https://docs.rs/serde/1.0.229/serde/de/trait.Deserialize.html), [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html) (retrieved 2026-09-16).

##### Principles and implementation

The pattern separates absence, degraded observations, and fatal failures before settings construction; this reuses R03's absence-versus-failure distinction rather than creating another error taxonomy. [Rust Book](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html), [R67 parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

##### Dominant choice

`ConfigLayer` provenance plus `toml::Value` parsing, leaf validation, pre-merge omission, and returned structured warnings is the dominant choice because it makes every tolerant branch explicit and testable. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html) (retrieved 2026-09-16).

##### Qualified shortlist

Whole-struct `Deserialize` is qualified only for strict explicit files; field-local custom deserializers are qualified only if R53 proves they preserve dotted-key diagnostics and lower-layer fallback. [Serde field attributes](https://serde.rs/field-attrs.html) (retrieved 2026-09-16).

##### Excluded by gate

No crate is excluded: this is a no-new-dependency pattern. Direct whole-struct deserialization is excluded from the tolerant F238 branch because its failed `Deserialize` operation cannot return a completed settings value. [Serde Deserialize](https://docs.rs/serde/1.0.229/serde/de/trait.Deserialize.html) (retrieved 2026-09-16).

##### Up-and-comers

`serde_path_to_error` is not selected: richer error paths do not supply continued field recovery, and adding it would not meet the value test. [serde_path_to_error documentation](https://docs.rs/serde_path_to_error/latest/serde_path_to_error/) (retrieved 2026-09-16).

##### Fit for this template

The pattern is synchronous, platform-neutral, has no `unsafe` code introduced by R55, no default features, no async runtime, and negligible binary/compile cost beyond its consumed dependencies; it fits one CLI/library/web configuration core. [Rust Book](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html) (retrieved 2026-09-16).

##### Recommendation

Adopt the pattern, condition discovered-layer degradation on R54, and return warnings to R58 rather than logging inside the loader. [divergence analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-16).

##### Ranked runner-up

Use `#[serde(deserialize_with)]` per field, ranked second, only if R53 demonstrates equivalent recoverability, diagnostics, and layer-local omission without an untyped tree. [Serde field attributes](https://serde.rs/field-attrs.html) (retrieved 2026-09-16).

##### Tradeoffs

Retaining `toml::Value` until validation costs an allocation and a little code, but avoids a global failure and preserves provenance; whole-struct parsing is smaller but cannot implement F238's intended behavior. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html), [Python settings pin](https://github.com/smorinlabs/py-launch-blueprint/blob/b08bccfb55d05f15e46a83b52c5660b1881d19f5/src/py_launch_blueprint/core/settings.py#L145-L176) (retrieved 2026-09-16).

##### Parameters

No parameter is owned. Assumes R52 supplies a TOML value tree, R53 supplies leaf and cross-field validation rules, R54 defines discovered origins and precedence, R58 emits returned warnings, and R67 maps only fatal errors. [research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md), [parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

##### Migration implications

P03 will add a config-loader module, a layer-origin type, a structured warning type, and table/leaf normalization; it will not add a standalone R55 dependency. [project README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md) (retrieved 2026-09-16).

##### Validation strategy

Planned fixture tests cover absent explicit, corrupt explicit, corrupt discovered, invalid high-precedence leaf with lower fallback, invalid leaf with default fallback, and a cross-field failure. No test was run because the Rust template does not exist. [project README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md) (retrieved 2026-09-16).

##### Confidence & re-verify trigger

High for the control-flow pattern; re-verify if R52 cannot expose a value tree, R53 selects aggregate-only validation, R54 omits discovery, or R67 retains `RSLB203` for every bad config leaf. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html), [parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

##### Sources

Maintainer API and pinned-precedent sources are cited in the fields above; pattern package figures are inapplicable because this member introduces no crate. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html) (retrieved 2026-09-16).

#### Consumed compatibility stack: toml, serde, tracing

##### Landscape

These are established dependencies selected by R52, R53, and R58 respectively; R55 records the current compatible versions, not ownership of their selection. Cargo demonstrates the `toml` and Serde pairing, and Axum demonstrates tracing use. [Cargo manifest](https://api.github.com/repos/rust-lang/cargo/contents/Cargo.toml), [Axum core manifest](https://api.github.com/repos/tokio-rs/axum/contents/axum-core/Cargo.toml) (retrieved 2026-09-16).

##### Principles and implementation

`toml::Value` gives the untyped boundary, Serde supplies leaf conversions, and tracing emits deferred structured warnings. This split preserves R55's policy while leaving parser, schema, and logging selection with their designated items. [toml Value](https://docs.rs/toml/1.1.6/toml/enum.Value.html), [Serde Deserialize](https://docs.rs/serde/1.0.229/serde/de/trait.Deserialize.html), [tracing warn](https://docs.rs/tracing/0.1.44/tracing/macro.warn.html) (retrieved 2026-09-16).

##### Dominant choice

Use `toml` 1.1.6+spec-1.1.0, `serde` 1.0.229, and `tracing` 0.1.44 as the current compatibility target, subject to their owners' final decisions. [toml versions](https://crates.io/api/v1/crates/toml/versions), [serde versions](https://crates.io/api/v1/crates/serde/versions), [tracing versions](https://crates.io/api/v1/crates/tracing/versions) (retrieved 2026-09-16).

##### Qualified shortlist

`basic-toml` and a direct whole-struct Serde schema are plausible R52/R53 alternatives, but neither is selected here because they must prove the value-tree and leaf-recovery requirements. [R52 divergence entry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md), [R53 divergence entry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-16).

##### Excluded by gate

No consumed member fails license, MSRV, advisory, OS, feature, runtime, or qualitative build-size gates: `toml` and Serde are `MIT OR Apache-2.0`; tracing is MIT; observed `rust_version` values are 1.85, 1.56, and 1.65.0, respectively; all support Rust's target platforms through portable Rust. Tracing's RustSec advisory RUSTSEC-2023-0078 is patched at `>=0.1.40`, so 0.1.44 has no open applicable advisory. Unsafe posture is not independently source-audited in this run and must be locked-file reviewed by the owning dependency items. [toml versions](https://crates.io/api/v1/crates/toml/versions), [serde versions](https://crates.io/api/v1/crates/serde/versions), [tracing versions](https://crates.io/api/v1/crates/tracing/versions), [RUSTSEC-2023-0078](https://rustsec.org/advisories/RUSTSEC-2023-0078.html) (retrieved 2026-09-16).

##### Up-and-comers

No up-and-comer is needed; the architecture, not a newer package, closes the recovery gap. [Rust Book](https://doc.rust-lang.org/book/ch09-02-recoverable-errors-with-result.html) (retrieved 2026-09-16).

##### Fit for this template

All three have default-feature and coupling details to be finalized by their owners: `toml` is synchronous, Serde has no async-runtime coupling, and tracing emits events without imposing an async runtime. Their qualitative cost is established dependency compile time plus an in-memory value tree; no throughput claim is made because R55 has no measured workload. [toml crate metadata](https://crates.io/api/v1/crates/toml), [serde crate metadata](https://crates.io/api/v1/crates/serde), [tracing crate metadata](https://crates.io/api/v1/crates/tracing) (retrieved 2026-09-16).

##### Recommendation

Treat these versions as a compatibility matrix for the R55 example, not a dependency lock selected by R55. [research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md) (retrieved 2026-09-16).

##### Ranked runner-up

The runner-up is whatever R52/R53/R58 select that preserves `Value`-level isolation and caller-owned warning emission; no distinct stack is recommended without that evidence. [research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md) (retrieved 2026-09-16).

##### Tradeoffs

The compatibility stack is mature and well adopted, but it makes the loader depend on cross-item version choices. A bespoke R55 crate would reduce no risk and increase binary and compile cost. [Cargo manifest](https://api.github.com/repos/rust-lang/cargo/contents/Cargo.toml), [Axum core manifest](https://api.github.com/repos/tokio-rs/axum/contents/axum-core/Cargo.toml) (retrieved 2026-09-16).

##### Parameters

Assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`; these are owner-fixed. [parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

##### Migration implications

P03 must place the parser/schema/logging dependencies in the package selected by their owners and keep the loader's warning-return interface independent of tracing initialization. [tracing warn](https://docs.rs/tracing/0.1.44/tracing/macro.warn.html) (retrieved 2026-09-16).

##### Validation strategy

Planned `cargo test --locked` on Ubuntu and macOS exercises the policy fixtures with the chosen matrix; `cargo tree -i toml`, `cargo tree -i serde`, and `cargo tree -i tracing` prove the resolved versions. These commands were not run because no Rust package exists. [Cargo tree](https://doc.rust-lang.org/cargo/commands/cargo-tree.html) (retrieved 2026-09-16).

##### Confidence & re-verify trigger

Medium: re-verify after R52/R53/R58 decide versions, on any MSRV lift or RustSec advisory, and before lockfile publication. [crates.io toml](https://crates.io/api/v1/crates/toml), [crates.io serde](https://crates.io/api/v1/crates/serde), [crates.io tracing](https://crates.io/api/v1/crates/tracing) (retrieved 2026-09-16).

##### Sources

Figures, all retrieved 2026-09-16: `toml` recent/all-time downloads 217,379,722/912,211,500 and newest non-yanked 1.1.6+spec-1.1.0 (2026-09-10) from [crate](https://crates.io/api/v1/crates/toml) and [versions](https://crates.io/api/v1/crates/toml/versions); repository stars/archived/pushed 1,074/false/2026-09-15 from [repo](https://api.github.com/repos/toml-rs/toml); open issues 57 from [search](https://api.github.com/search/issues?q=repo%3Atoml-rs%2Ftoml%20is%3Aissue%20is%3Aopen); among the ten latest open issues, first maintainer response median 0.34 days and unanswered 5, from [issues](https://api.github.com/repos/toml-rs/toml/issues?state=open&sort=created&direction=desc&per_page=10) and their comment endpoints. `serde`: 308,308,063/1,402,408,950, 1.0.229 (2026-07-18), 10,826/false/2026-08-25, 319 open, and 0 answered/10 unanswered; endpoints [crate](https://crates.io/api/v1/crates/serde), [versions](https://crates.io/api/v1/crates/serde/versions), [repo](https://api.github.com/repos/serde-rs/serde), [search](https://api.github.com/search/issues?q=repo%3Aserde-rs%2Fserde%20is%3Aissue%20is%3Aopen), [issues](https://api.github.com/repos/serde-rs/serde/issues?state=open&sort=created&direction=desc&per_page=10). `tracing`: 190,403,982/851,763,179, 0.1.44 (2025-12-18), 6,877/false/2026-05-30, 628 open, and 0 answered/10 unanswered; endpoints [crate](https://crates.io/api/v1/crates/tracing), [versions](https://crates.io/api/v1/crates/tracing/versions), [repo](https://api.github.com/repos/tokio-rs/tracing), [search](https://api.github.com/search/issues?q=repo%3Atokio-rs%2Ftracing%20is%3Aissue%20is%3Aopen), [issues](https://api.github.com/repos/tokio-rs/tracing/issues?state=open&sort=created&direction=desc&per_page=10). RustSec package pages for serde and toml were unavailable (HTTP 404); tracing's package page lists RUSTSEC-2023-0078, whose advisory states it is patched at `>=0.1.40`. [tracing RustSec package](https://rustsec.org/packages/tracing.html), [RUSTSEC-2023-0078](https://rustsec.org/advisories/RUSTSEC-2023-0078.html) (retrieved 2026-09-16).

### Compatibility

Cargo's current manifest composes `serde` 1.0.228 with `toml` 1.1.5, and Axum's `axum-core` declares optional tracing 0.1.37; the proposed versions retain the same compatible major/minor APIs and each meets its observed MSRV floor. The integration proof to execute in P03 is one fixture crate that parses a `toml::Value`, converts leaf values with Serde, returns `ConfigWarning`, and lets a test subscriber observe the boundary warning. This is planned, not executed. [Cargo manifest](https://api.github.com/repos/rust-lang/cargo/contents/Cargo.toml), [Axum core manifest](https://api.github.com/repos/tokio-rs/axum/contents/axum-core/Cargo.toml), [toml versions](https://crates.io/api/v1/crates/toml/versions), [serde versions](https://crates.io/api/v1/crates/serde/versions), [tracing versions](https://crates.io/api/v1/crates/tracing/versions) (all retrieved 2026-09-16).

### Parameters

assumes R52 parser representation = a TOML value tree that permits table/leaf access; assumes R53 validation = independently callable declared-field validation plus a separately classified cross-field invariant result; assumes R54 discovered-layer origins and precedence = open; assumes R58 logging-pipeline-contract = caller emits structured warnings; assumes R67 error-taxonomy-exit-codes = fatal existing explicit parse is `RSLB202`/exit 2 and explicit I/O is `RSLB104`/exit 1. `CONFLICT: R67 error-taxonomy-exit-codes — `RSLB203 config value invalid` cannot mean every invalid file leaf — R55 requires an individually invalid declared config value to warn-and-drop, reserving `RSLB203` for a fatal nonrecoverable validation outcome such as R53's cross-field invariant.` [parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md), [R55 prompt context](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/topics/55-config-error-tolerance/prompts/config-error-tolerance.prompt.md) (retrieved 2026-09-16).

### Migration implications

P03 should create `src/config/load.rs` for layer read/parse classification, `src/config/warnings.rs` for `ConfigWarning`, and `src/config/normalize.rs` for table/leaf validation before the R54 precedence merge; wire emission only in the CLI and web composition roots. The exact module names are a proposal, not an existing file claim. Do not scaffold this during research. [project README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md), [tracing warn](https://docs.rs/tracing/0.1.44/tracing/macro.warn.html) (retrieved 2026-09-16).

### Validation strategy

Planned P03 acceptance commands: `cargo test --locked config::tests::explicit_missing_is_empty_and_writable`, `cargo test --locked config::tests::explicit_corrupt_is_fatal`, `cargo test --locked config::tests::discovered_corrupt_warns_and_skips`, and `cargo test --locked config::tests::invalid_leaf_warns_preserves_siblings_and_falls_back`. Run the same suite on `ubuntu-latest` and `macos-latest`. Expected results are respectively empty/write target, RSLB202 error, one provenance warning with other layers active, and one dotted-key warning with valid sibling/lower value intact. These are proposed checks; none were run because the Rust template has no code. [project README](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/README.md), [Cargo test](https://doc.rust-lang.org/cargo/commands/cargo-test.html) (retrieved 2026-09-16).

### Confidence & re-verify trigger

Confidence is high for the failure-policy separation and medium for the exact dependency matrix because R52, R53, R54, and R58 are open. Re-verify at their decisions, before P03's lockfile, if the MSRV changes, if RustSec changes, or if R67 rejects the required narrowing of RSLB203. The absent owner-supplied companion-stack input required no row-by-row reconciliation. [research index](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/research/CLAUDE.md), [parameter registry](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/PARAMETERS.md) (retrieved 2026-09-16).

### Sources

Method notes: retrieved 2026-09-16. Queried crates.io `GET https://crates.io/api/v1/crates/{serde,toml,tracing}` and `/versions`; GitHub REST through the mandated local proxy while recording the real `https://api.github.com/repos/{owner}/{repo}`, `/search/issues`, issue-list, content, and comment endpoints cited above; RustSec, versioned docs.rs, Serde, and Rust Project documentation. Pinned py and ts evidence was read only with `git show` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, then cited by immutable URL. No owner companion-stack file existed. Unverified: serde/toml RustSec package-page URLs returned HTTP 404; direct `unsafe` source audits and the proposed Rust tests remain unrun; R52/R53/R54/R58 outcomes are open.
