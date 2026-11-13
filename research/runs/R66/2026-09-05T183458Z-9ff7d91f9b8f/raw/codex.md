### Landscape

**Category.** R66 decides a result-output contract: one human-readable representation, one stable machine representation, an optional interchange representation, and unambiguous selection and redirection flags. The source disagreement is real: Python exposes `text|json|markdown` while TypeScript exposes `text|json|csv`; the ledger also records the `--output` name collision. [Source: rs-launch-blueprint F291/F293](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/COMMONALITY.md#L295-L297), retrieved 2026-09-05.

| Field bin | Candidates found | Fit before popularity |
|---|---|---|
| Built-in / first-party | `std::io::Write` for the human table and a deliberately small Markdown-table renderer; `std::fs` for the destination-file contract | No serialization dependency is needed for a fixed, flat Markdown row. This keeps terminal-only formatting out of non-terminal output. [Rust standard library `Write`](https://doc.rust-lang.org/std/io/trait.Write.html), retrieved 2026-09-05; [GFM tables](https://github.github.com/gfm/#tables-extension-), retrieved 2026-09-05. |
| Established industry standard | `serde` 1.0.229 plus `serde_json` 1.0.151 for the JSON branch; `csv` 1.4.0 for a CSV alternative | Serde supplies the Rust serialization abstraction and Cargo itself uses both Serde crates. CSV is a sound RFC-oriented tabular interchange tool, but spreadsheet import is not a core acceptance use case for this template. [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05; [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05; [csv `Writer` docs](https://docs.rs/csv/1.4.0/csv/struct.Writer.html), retrieved 2026-09-05. |
| Up-and-comer | No additional format crate is shortlisted | A Markdown-table crate would add a dependency only to format fixed scalar cells, and a second machine format would create a second public schema. Neither solves an unsatisfied target requirement. [GFM tables](https://github.github.com/gfm/#tables-extension-), retrieved 2026-09-05. |

**Authority and practice survey.** Cargo's manifest reference makes `rust-version` a declared compatibility contract, the Rust CLI Book is maintained by the Rust CLI Working Group, the Serde and csv documentation are maintained crate documentation, GFM is the maintained rendering specification for the proposed paste-into-PR use case, and the organization CLI Design Standard is the applicable normative interface authority. [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-rust-version-field), retrieved 2026-09-05; [Rust CLI Book](https://rust-cli.github.io/book/), retrieved 2026-09-05; [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05; [csv docs](https://docs.rs/csv/1.4.0/csv/), retrieved 2026-09-05; [GFM tables](https://github.github.com/gfm/#tables-extension-), retrieved 2026-09-05; [CLI Design Standard v1.4.14](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05.

Cargo is a relevant production reference because it is the Rust package manager, has 15,453 GitHub stars, is not archived, and its current workspace manifest directly depends on `serde` and `serde_json`. [Cargo repository endpoint](https://api.github.com/repos/rust-lang/cargo), retrieved 2026-09-05; [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05. Xsv is a relevant CSV reference because its manifest uses `csv = "1"` and it is explicitly a Rust CSV command-line toolkit, but its repository is archived; it is evidence of API use, not a reason to choose CSV. [xsv repository endpoint](https://api.github.com/repos/BurntSushi/xsv), retrieved 2026-09-05; [xsv manifest](https://raw.githubusercontent.com/BurntSushi/xsv/master/Cargo.toml), retrieved 2026-09-05.

The candidate figures, collected before popularity was weighed, are below. The RustSec package-page URL required by the prompt returned HTTP 404 for all three packages, so **no-open-advisory is unverified**, not assumed. The direct-crate MSRVs meet the stated policy; the resolved dependency-tree MSRV and advisory state still require a locked, target-specific integration check.

| Candidate | Fitness gates and maintenance | Figures and endpoint (retrieved 2026-09-05) |
|---|---|---|
| `serde` 1.0.229 | License `MIT OR Apache-2.0`; direct MSRV 1.56; default feature `std`, with `derive` opt-in; no async-runtime coupling; direct source contains `unsafe` blocks, so an unsafe/dependency audit remains required; upstream CI evidence covers Ubuntu and Windows but not macOS, so the target macOS gate is unverified. State: **active** from a 2026-07-18 release and 2026-08-25 push. | 294,313,379 recent and 1,356,876,028 all-time downloads; release 1.0.229 at 2026-07-18T23:05:13Z; 10,801 stars, not archived, 318 open issues. The ten most recently opened open issues had no comment from an `OWNER`, `MEMBER`, or `COLLABORATOR`; median first-maintainer response is therefore not calculable and 10/10 were unanswered under that reproducible rule. [crate](https://crates.io/api/v1/crates/serde), [versions](https://crates.io/api/v1/crates/serde/versions), [repository](https://api.github.com/repos/serde-rs/serde), [open-issue search](https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open), [recent-ten query](https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open&sort=created&order=desc&per_page=10), retrieved 2026-09-05. |
| `serde_json` 1.0.151 | License `MIT OR Apache-2.0`; direct MSRV 1.71; default feature `std`; optional features are off by default; no async-runtime coupling; direct source contains `unsafe` blocks, so an unsafe/dependency audit remains required; upstream CI evidence covers Ubuntu and Windows but not macOS, so the target macOS gate is unverified. State: **active** from a 2026-07-20 release and 2026-08-08 push. | 298,334,232 recent and 1,260,985,047 all-time downloads; release 1.0.151 at 2026-07-20T05:54:44Z; 5,635 stars, not archived, 190 open issues. The ten most recently opened open issues had no qualifying maintainer comment; median is not calculable and 10/10 were unanswered under the stated rule. [crate](https://crates.io/api/v1/crates/serde_json), [versions](https://crates.io/api/v1/crates/serde_json/versions), [repository](https://api.github.com/repos/serde-rs/json), [open-issue search](https://api.github.com/search/issues?q=repo:serde-rs/json+is:issue+is:open), [recent-ten query](https://api.github.com/search/issues?q=repo:serde-rs/json+is:issue+is:open&sort=created&order=desc&per_page=10), retrieved 2026-09-05. |
| `csv` 1.4.0 — evaluated alternative, not selected | License `Unlicense/MIT`, compatible with the project dual license; direct MSRV 1.73; no declared feature set; no async-runtime coupling; direct source contains `unsafe` blocks; upstream CI includes Ubuntu, macOS, and Windows. The last release is older than six months but the repository was pushed on 2026-08-04, so the rubric result is **stable-quiet**, not dormant. Its RustSec package page also returned 404, so advisory status is unverified. | 46,083,854 recent and 238,847,297 all-time downloads; release 1.4.0 at 2025-10-17T13:56:07Z; 1,957 stars, not archived, 65 open issues. Of the ten newest open issues, two received qualifying responses in less than one day and eight had none; the response median among answered issues is 0 days, with 8/10 unanswered. [crate](https://crates.io/api/v1/crates/csv), [versions](https://crates.io/api/v1/crates/csv/versions), [repository](https://api.github.com/repos/BurntSushi/rust-csv), [open-issue search](https://api.github.com/search/issues?q=repo:BurntSushi/rust-csv+is:issue+is:open), [recent-ten query](https://api.github.com/search/issues?q=repo:BurntSushi/rust-csv+is:issue+is:open&sort=created&order=desc&per_page=10), retrieved 2026-09-05. |

The public reverse-dependency endpoints report 120,184 dependents for `serde`, 98,761 for `serde_json`, and 3,281 for `csv`; those counts are context only and did not determine the recommendation. [Serde reverse dependencies](https://crates.io/api/v1/crates/serde/reverse_dependencies?per_page=10), [serde_json reverse dependencies](https://crates.io/api/v1/crates/serde_json/reverse_dependencies?per_page=10), [csv reverse dependencies](https://crates.io/api/v1/crates/csv/reverse_dependencies?per_page=10), retrieved 2026-09-05.

### Principles and implementation

**Shared requirement and agreement level.** The cross-repository agreement is at the **capability and policy** level: formatted results must offer a human form, a stable JSON form, a terse `--json` selector, and a non-colliding way to write results to a file. It is not agreement on Python's or TypeScript's literal format string or their conflicting `--output` meaning. The divergence analysis explicitly marks F293 as already harmonized at `--format`/`--output` only because of TypeScript D-033, while F291 remains a user-use-case decision; the owner mandate allows Rust to replace an inherited mechanism when current evidence supports the same principle better. [R66 divergence analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/DIVERGENCE-ANALYSIS.md#L205-L207), retrieved 2026-09-05; [research mandate and F291/F293](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/COMMONALITY.md#L295-L297), retrieved 2026-09-05.

The required observable behavior is: a result command defaults to a human plain-text table; `-o json`, `--output json`, and `--json` write the same JSON bytes to stdout; `-o markdown` writes a GFM-compatible plain table; diagnostics remain on stderr; `--output-file PATH` changes only the destination; `--output-file -` remains stdout; and `--json` together with either spelling of `--output` is a usage error rather than precedence guessing. The organization standard makes `-o`/`--output` the required extensible format selector, makes `--json` identical to `-o json`, and reserves long-only `--output-file` for a destination. [CLI Design Standard R3.2 and R4.2](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05.

`BASELINE-REVIEW: F291 — human-readable result capability — use enum value \`table\` for the existing text/table behavior and add \`markdown\`, not \`csv\` — CLI Design Standard v1.4.14 requires the table default; GFM provides the stated PR-paste use case, whereas CSV's spreadsheet-import use case is not required by this template.`

`BASELINE-REVIEW: F293 — one unambiguous format selector and one destination flag — replace the TypeScript D-033 \`--format\`/\`--output <file>\` split with \`-o\`/\`--output <format>\` plus long-only \`--output-file <path>\` — CLI Design Standard R3.2 and R4.2 make this an applicable MUST and prevent a file/format collision.`

**Alternatives compared.** Text plus JSON only has the lowest surface cost but fails the requested human paste-into-PR capability. CSV plus the `csv` crate is technically qualified, including robust delimiter and quote handling, but requires a documented flat column schema, cannot express nested result data naturally, and serves spreadsheet import rather than the template's review/documentation workflow. Both Markdown and CSV would create two additional versioned output contracts without evidence of two core user groups. A hand-written Markdown table is appropriate only for the fixed flat result view: it must escape `|`, backslash, and cell newlines, use UTF-8, and never reuse terminal-only R85 escapes. GFM documents the table grammar; JSON remains the library/web-service interchange surface via Serde. [csv `Writer`](https://docs.rs/csv/1.4.0/csv/struct.Writer.html), retrieved 2026-09-05; [GFM tables](https://github.github.com/gfm/#tables-extension-), retrieved 2026-09-05; [serde_json `to_writer`](https://docs.rs/serde_json/1.0.151/serde_json/fn.to_writer.html), retrieved 2026-09-05.

The reference composition is a library-owned `ProjectRow` (or equivalent stable result DTO) derived with Serde. The CLI maps it once to a presentation-neutral row, sends it to `serde_json::to_writer` for JSON, a bounded internal table function for `table` and `markdown`, and writes the selected bytes to stdout or the opened destination. This keeps transport/web serialization and CLI formatting separate. Cargo's own use of Serde and serde_json is a maintained reference for the pair; the specific three-branch CLI composition is proposed, not found as a single maintained reference implementation. [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05; [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05.

No benchmark decides this choice. For a representative `project list` of 100 flat rows, measure wall time and peak resident memory for `table`, `json`, and `markdown` with output directed to a sink and with the actual selected feature set; record platform, compiler, row width, and warm/cold conditions. JSON throughput is delegated to serde_json's maintained implementation, but no absolute performance claim is made from unrelated benchmarks. [serde_json docs](https://docs.rs/serde_json/1.0.151/serde_json/), retrieved 2026-09-05.

### Recommendation

Adopt **`serde` 1.0.229 with `derive` + `serde_json` 1.0.151 + an internal, fixed-row GFM Markdown renderer**. Expose the format enum as **`table | json | markdown`**, where `table` is the required human text/table output. Use **`-o <format>` / `--output <format>`** as the selector, **`--json`** as an alias that conflicts with an explicit selector, and **`--output-file <path>`** as the long-only destination. Do not support CSV in v1; do not introduce a Markdown or CSV crate. This is provisional until the advisory, full dependency MSRV, and Ubuntu/macOS target-build gates below pass. [CLI Design Standard R3.2/R4.2](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05; [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05; [serde_json docs](https://docs.rs/serde_json/1.0.151/serde_json/), retrieved 2026-09-05; [GFM tables](https://github.github.com/gfm/#tables-extension-), retrieved 2026-09-05.

### Members

#### serde

##### Landscape

`serde` is the established Rust serialization abstraction rather than a CLI-only formatter. Its direct MSRV is 1.56, its license is compatible, and its default is `std`; `derive` is explicitly enabled for the DTOs used by this template. [crate versions endpoint](https://crates.io/api/v1/crates/serde/versions), retrieved 2026-09-05.

##### Principles and implementation

Use Serde derives on library-owned result DTOs so the JSON encoder does not depend on CLI structs. Cargo's maintained manifest is direct practice evidence for Serde use in a major Rust tool. [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05; [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05.

##### Dominant choice

`serde` 1.0.229 is the dominant qualifying serialization abstraction: 294,313,379 recent downloads and 1,356,876,028 total downloads are reported by the crate endpoint, although fitness—not those figures—selected it. [crate endpoint](https://crates.io/api/v1/crates/serde), retrieved 2026-09-05.

##### Qualified shortlist

`serde` is qualified provisionally: compatible license, direct MSRV 1.56, no runtime coupling, current release and push activity; full-tree MSRV, advisory, and target macOS CI evidence remain integration gates. [versions endpoint](https://crates.io/api/v1/crates/serde/versions), [repository endpoint](https://api.github.com/repos/serde-rs/serde), retrieved 2026-09-05.

##### Excluded by gate

No alternative serialization abstraction is selected. `serde` itself is not finally gate-cleared because the required RustSec page returned 404 and upstream CI does not demonstrate macOS; that is an explicit re-verification condition, not a claim that it has an advisory or fails on macOS. [RustSec package URL](https://rustsec.org/packages/serde.html), [Serde CI](https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml), retrieved 2026-09-05.

##### Up-and-comers

None are proposed: replacing the ecosystem serialization boundary would expand scope without an R66 use-case benefit. [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05.

##### Fit for this template

Serde lets the CLI, library, and web service share one explicit data model while keeping CLI renderers separate; enabling `derive` adds a proc-macro compile cost but no runtime or async framework coupling. [Serde feature metadata](https://crates.io/api/v1/crates/serde/versions), retrieved 2026-09-05.

##### Recommendation

Pin the compatible 1.x requirement at `serde = { version = "1.0.229", features = ["derive"] }` when the implementation lockfile is created. [release endpoint](https://crates.io/api/v1/crates/serde/versions), retrieved 2026-09-05.

##### Ranked runner-up

Inapplicable: this member supplies the shared Rust serialization abstraction, and no alternative is needed to decide the Markdown-versus-CSV surface. [R66 scope](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/DIVERGENCE-ANALYSIS.md#L205-L207), retrieved 2026-09-05.

##### Tradeoffs

The derive macro increases compile work, and direct source inspection found `unsafe` blocks; the full dependency tree must be audited rather than described as unsafe-free. [serde 1.0.229 package download](https://crates.io/api/v1/crates/serde/1.0.229/download), retrieved 2026-09-05.

##### Parameters

No R66-owned or consumed registry parameter applies to this crate. The fixed edition, MSRV policy, license, and OS matrix are assumed as stated in the R66 prompt. [project parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/PARAMETERS.md), retrieved 2026-09-05.

##### Migration implications

Add the dependency and derive `Serialize` on the DTO that backs JSON output; do not derive on the terminal presentation type. This is a proposed file-level change because no Rust source exists yet. [Serde docs](https://docs.rs/serde/1.0.229/serde/), retrieved 2026-09-05.

##### Validation strategy

Planned: build the locked graph at the declared MSRV on Ubuntu and macOS, run `cargo audit`, and serialize the same DTO through the JSON branch. No member validation command was executed during this research run. [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-rust-version-field), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Medium confidence. Re-verify on a Serde release, a change to the declared MSRV, RustSec endpoint recovery, or the first locked dependency graph. [Serde crate endpoint](https://crates.io/api/v1/crates/serde), retrieved 2026-09-05.

##### Sources

Figures: [crate](https://crates.io/api/v1/crates/serde), [versions](https://crates.io/api/v1/crates/serde/versions), [repository](https://api.github.com/repos/serde-rs/serde), [open issues](https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open), retrieved 2026-09-05. The RustSec URL returned 404, so it did not supply advisory evidence. [RustSec package URL](https://rustsec.org/packages/serde.html), retrieved 2026-09-05.

#### serde_json

##### Landscape

`serde_json` is the established JSON implementation paired with Serde; its direct MSRV is 1.71 and default feature is `std`. [crate versions endpoint](https://crates.io/api/v1/crates/serde_json/versions), retrieved 2026-09-05.

##### Principles and implementation

Use `serde_json::to_writer` for JSON directed to stdout or the destination writer, preserving one DTO representation and avoiding hand-built JSON. [serde_json `to_writer`](https://docs.rs/serde_json/1.0.151/serde_json/fn.to_writer.html), retrieved 2026-09-05.

##### Dominant choice

`serde_json` 1.0.151 reports 298,334,232 recent downloads and 1,260,985,047 total downloads; Cargo directly uses it, which is maintained production practice. [crate endpoint](https://crates.io/api/v1/crates/serde_json), [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05.

##### Qualified shortlist

It is provisionally qualified by `MIT OR Apache-2.0`, direct MSRV 1.71, default `std`, no async coupling, 2026-07-20 release, and 2026-08-08 repository push; resolved-tree MSRV, advisory, and macOS CI evidence are still unverified. [versions endpoint](https://crates.io/api/v1/crates/serde_json/versions), [repository endpoint](https://api.github.com/repos/serde-rs/json), retrieved 2026-09-05.

##### Excluded by gate

No JSON replacement is selected. The package cannot be marked fully gate-cleared because its required RustSec page returns 404 and the upstream CI matrix does not show macOS. [RustSec package URL](https://rustsec.org/packages/serde_json.html), [serde_json CI](https://raw.githubusercontent.com/serde-rs/json/master/.github/workflows/ci.yml), retrieved 2026-09-05.

##### Up-and-comers

None are proposed because a separate JSON implementation would not improve the R66 CLI/library/web-service composition. [serde_json docs](https://docs.rs/serde_json/1.0.151/serde_json/), retrieved 2026-09-05.

##### Fit for this template

The writer API maps exactly to stdout and file destinations; default `std` is sufficient and optional features such as `preserve_order` remain off, containing compile and dependency cost. [serde_json feature metadata](https://crates.io/api/v1/crates/serde_json/versions), [writer docs](https://docs.rs/serde_json/1.0.151/serde_json/fn.to_writer.html), retrieved 2026-09-05.

##### Recommendation

Pin the compatible 1.x requirement at `serde_json = "1.0.151"`; serialize JSON only through the result DTO, not the human table. [release endpoint](https://crates.io/api/v1/crates/serde_json/versions), retrieved 2026-09-05.

##### Ranked runner-up

Inapplicable: JSON is the already-required machine contract, and R66 did not identify a competing Rust JSON library with a distinct benefit. [R66 prompt context](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/COMMONALITY.md#L295-L297), retrieved 2026-09-05.

##### Tradeoffs

This adds parser/serializer and transitive compile cost; direct source inspection found `unsafe` blocks, so the selected graph needs an audit before implementation is accepted. [serde_json 1.0.151 package download](https://crates.io/api/v1/crates/serde_json/1.0.151/download), retrieved 2026-09-05.

##### Parameters

No R66-owned or consumed registry parameter applies. The fixed Rust edition, MSRV policy, license, and OS matrix remain assumptions from the binding prompt. [project parameters](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/PARAMETERS.md), retrieved 2026-09-05.

##### Migration implications

Add the dependency and route the JSON branch through `to_writer`; define the stable JSON schema beside the library DTO. This is proposed because the Rust template has no source files yet. [writer docs](https://docs.rs/serde_json/1.0.151/serde_json/fn.to_writer.html), retrieved 2026-09-05.

##### Validation strategy

Planned: serialize representative rows, parse stdout with `jq` in integration tests, compare `--json` to `-o json`, then execute the locked-graph MSRV, audit, Ubuntu, and macOS gates. No command was executed for this member. [CLI Design Standard R4.2](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05.

##### Confidence & re-verify trigger

Medium confidence. Re-verify on a serde_json release, a RustSec result, a declared-MSRV change, or when the first feature-resolved lockfile exists. [serde_json crate endpoint](https://crates.io/api/v1/crates/serde_json), retrieved 2026-09-05.

##### Sources

Figures: [crate](https://crates.io/api/v1/crates/serde_json), [versions](https://crates.io/api/v1/crates/serde_json/versions), [repository](https://api.github.com/repos/serde-rs/json), [open issues](https://api.github.com/search/issues?q=repo:serde-rs/json+is:issue+is:open), retrieved 2026-09-05. The RustSec URL returned 404, so it did not supply advisory evidence. [RustSec package URL](https://rustsec.org/packages/serde_json.html), retrieved 2026-09-05.

### Compatibility

`serde` and `serde_json` are version-compatible by design: serde_json 1.0.151 declares a dependency on `serde_core` and optional `serde`, while Rust's Cargo workspace currently resolves both Serde crates together. Compatibility must still be proved by the future locked manifest, not inferred from version strings. [serde_json manifest](https://raw.githubusercontent.com/serde-rs/json/master/Cargo.toml), [Cargo manifest](https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml), retrieved 2026-09-05. The proposed output branch matrix is: `table` and `markdown` consume the same flat presentation rows with no serialization crate; `json` consumes the Serde DTO through serde_json; all branches share the one selected writer and therefore keep file redirection independent of format. [Serde docs](https://docs.rs/serde/1.0.229/serde/), [serde_json writer docs](https://docs.rs/serde_json/1.0.151/serde_json/fn.to_writer.html), retrieved 2026-09-05.

### Parameters

No owned parameter exists and no registered parameter is consumed: `owns —`; `assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions`; `assumes license = MIT OR Apache-2.0`; `assumes target-os-matrix = ubuntu-latest, macos-latest`. [R66 binding context](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/PARAMETERS.md), retrieved 2026-09-05. No `CONFLICT:` line is emitted because the recommendation needs no owned or consumed value changed.

### Migration implications

The eventual template should add a library result DTO module with `Serialize`, an output module with `OutputFormat::{Table, Json, Markdown}`, a renderer dispatch module, and CLI flag declarations in the R60-selected parser adapter. Add integration fixtures for stdout/stderr, every format, `--json` conflict behavior, `--output-file`, `--output-file -`, replacement of an existing file, and `--no-clobber`; add the two dependencies to `Cargo.toml`. These are planned file-level changes, not executed changes, because the repository has no Rust implementation. [project status](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/README.md), retrieved 2026-09-05; [CLI Design Standard R3.2/R3.9/R4.2](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05.

### Validation strategy

These are **planned**, not executed, acceptance checks:

```sh
# default human result and explicit Markdown are plain stdout data
cargo run -- project list >actual.table
cargo run -- project list -o markdown >actual.md

# aliases produce identical JSON and an ambiguous selector is rejected
cargo run -- project list -o json >a.json
cargo run -- project list --json >b.json
cmp a.json b.json
cargo run -- project list --json -o table; test $? -eq 2

# destination is independent of selection; '-' remains stdout
cargo run -- project list -o markdown --output-file report.md
cargo run -- project list -o json --output-file - | jq .

# safe overwrite contract
cargo run -- project list --output-file existing.txt
cargo run -- project list --output-file existing.txt --no-clobber; test $? -eq 1

# target evidence gates, run in both named CI images at the declared MSRV
cargo +"$MSRV" check --locked --all-targets
cargo test --locked --all-targets
cargo audit
```

Expected result: the two JSON commands are byte-identical, mixed alias/selector invocation exits 2, diagnostics never contaminate redirected data, Markdown has no terminal escape sequences, `--output-file -` is stdout, ordinary `--output-file` overwrites atomically, and `--no-clobber` refuses an existing target. The interface rules for selector, alias, destination, stdout, and overwrite/no-clobber are normative; the exact parser declaration is R60's implementation responsibility. [CLI Design Standard R3.2/R3.9/R4.2/R7.1](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), retrieved 2026-09-05; [clap conflict API](https://docs.rs/clap/4.6.6/clap/struct.Arg.html#method.conflicts_with), retrieved 2026-09-05.

### Confidence & re-verify trigger

**Medium.** The format and flag recommendation is high-confidence on the binding organization standard, but the crate selection is only provisional because the required RustSec page queries failed, no locked transitive graph was evaluated, and upstream Serde CI does not by itself show macOS coverage. Re-verify before resolving R66, on every selected-crate release, when R60 chooses the actual parser, when the declared MSRV changes, and when a user asks for spreadsheet export as a first-class workflow. The latter is the trigger to reopen CSV, with a documented flat schema and `csv` 1.4.0 re-evaluated. [CLI Design Standard](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), [Serde repository](https://api.github.com/repos/serde-rs/serde), [serde_json repository](https://api.github.com/repos/serde-rs/json), [csv repository](https://api.github.com/repos/BurntSushi/rust-csv), retrieved 2026-09-05.

### Sources

Primary evidence retrieved 2026-09-05: [R66 precedent and ledger](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/COMMONALITY.md#L295-L297), [R66 divergence analysis](https://github.com/smorinlabs/rs-launch-blueprint/blob/1c1b0ec0e2fbbb18c0e6c3cfd3c23b91622a627f/docs/port/DIVERGENCE-ANALYSIS.md#L205-L207), [CLI Design Standard v1.4.14](https://raw.githubusercontent.com/smorinlabs/cli-standards/main/cli-design-standard.md), [Serde](https://docs.rs/serde/1.0.229/serde/), [serde_json](https://docs.rs/serde_json/1.0.151/serde_json/), [csv](https://docs.rs/csv/1.4.0/csv/), [GFM table specification](https://github.github.com/gfm/#tables-extension-), and [Cargo manifest reference](https://doc.rust-lang.org/cargo/reference/manifest.html#the-rust-version-field).

Method notes: queried the required crates.io crate and `/versions` endpoints for `serde`, `serde_json`, and `csv`; GitHub repository, open-issue search, recent-ten issue search, issue-comment, workflow, and adopter-manifest endpoints; docs.rs; raw maintained manifests; the GFM specification; the organization standard; and the required RustSec package URLs. The RustSec URLs `https://rustsec.org/packages/{serde,serde_json,csv}.html` returned HTTP 404, the crates.io reverse-dependency HTML page did not expose named adopters to this client, upstream Serde and serde_json workflows did not demonstrate macOS testing, and no resolved dependency tree, benchmark, or target build was run. Those omissions are reported as unverified rather than converted into positive evidence.
