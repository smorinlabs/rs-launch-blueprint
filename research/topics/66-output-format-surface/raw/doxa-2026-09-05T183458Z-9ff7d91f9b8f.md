### Landscape

**Retrieval date:** September 9, 2026. All web citations and URLs below were retrieved on that date unless a different snapshot date is stated.

**Decision category:** a **CLI representation-and-destination contract**: the supported serialized representations, the separation between representation and sink, and the stable behavior each representation exposes to people, scripts, files, and the web-service layer.

**Evidence limitation:** `docs/port/DIVERGENCE-ANALYSIS.md` was referenced but its contents were not supplied and it was not publicly discoverable. The shared principle below is therefore derived narrowly from owner clarification A5 and the supplied F291/F292/F293 evidence. It must be checked against that local file before updating the ledger.

| Landscape bin | Candidates found | Assessment for this template |
|---|---|---|
| **Built-in or first-party toolchain** | `std::io::Write`, `stdout().lock()`, `Vec<u8>`, `std::fs::write`; hand-written text and bounded GFM-table rendering; Cargo’s versioned JSON-output pattern | Strongest foundation. It keeps rendering testable and separates destination from representation without another framework dependency. The Rust CLI Working Group explicitly demonstrates rendering through `Write`, keeping actual output on stdout and diagnostics on stderr. Cargo demonstrates treating machine-readable JSON as a versioned compatibility surface. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html)) |
| **Established industry standard** | JSON/RFC 8259 with `serde` + `serde_json`; GFM tables; CSV/RFC 4180 with `csv`; GNU `-o`/`--output` file-sink convention | JSON is the clear machine format. GFM is the established target for GitHub PRs/issues and supports tables and links. CSV has a mature Rust writer but is flat, has dialect variance, and introduces spreadsheet-formula-injection policy. GNU guidance explicitly associates `-o`/`--output` with an output filename. ([rfc-editor.org](https://www.rfc-editor.org/info/rfc8259/)) |
| **Up-and-comer or specialized** | Specialized serializers such as `serde_csv_core`; generic table/format registries and performance-specialized JSON implementations | None has a better fit than the established choices. This is a correctness and compatibility problem, not an observed JSON-throughput bottleneck or an embedded/no-`std` workload. `serde_csv_core` remains a future specialist option, not a shortlist winner. ([docs.rs](https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html)) |

**Authority used and why it counts**

- The Rust CLI Working Group book is Rust-project domain guidance for end-to-end CLI design. It establishes the stdout/stderr distinction, machine-oriented output, buffering, and `std::io::Write` as the testability boundary. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html))
- Cargo documentation is first-party production precedent for JSON as a machine contract and for explicit format-version compatibility. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html))
- RFC 8259 is the IETF Internet Standard for JSON. RFC 4180 is the commonly cited informational CSV format and MIME registration; it also records that CSV implementations vary. ([rfc-editor.org](https://www.rfc-editor.org/info/rfc8259/))
- The GFM specification is GitHub’s formal definition of the Markdown dialect used in GitHub content. Its table extension defines delimiters, alignment, inline parsing, and pipe escaping. ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))
- GNU Coding Standards are authoritative convention evidence for Unix-style option spelling, specifically recommending `-o` or `--output` for an output filename. ([gnu.org](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces))
- Serde, `serde_json`, `csv`, and clap documentation are maintainer-owned implementation references. ([serde.rs](https://serde.rs/))
- The 2025 State of Rust Survey collected 7,156 completed responses and establishes the breadth of the current Rust community, but it does **not** decide this format question and was not treated as a crate popularity vote. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- OWASP is used for the format-level security consequence of spreadsheet-oriented CSV exports. It warns that there is no universally safe sanitization strategy for every spreadsheet and downstream consumer. ([owasp.org](https://owasp.org/www-community/attacks/CSV_Injection))

**Practice evidence**

- Cargo emits JSON for `cargo metadata` and explicitly versions that machine-facing contract. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html))
- Ripgrep’s maintainer describes `--json` as the stable, robust integration surface, and separately reports that VS Code consumes it. That supports retaining the inherited `--json` shorthand, but not using human text as an API. ([github.com](https://github.com/BurntSushi/ripgrep/discussions/3404))
- Hyperfine is a particularly relevant maintained Rust reference: it has roughly 28,000 GitHub stars, exports JSON, CSV, and Markdown, and structures exporters separately from output targets. Its current manifest uses `serde`, `serde_json`, and `csv`; its CSV implementation uses `csv::WriterBuilder`, while Markdown is a small purpose-built renderer. This demonstrates that both third formats can be legitimate when both jobs are present—not that every CLI should support their union. ([github.com](https://github.com/sharkdp/hyperfine))
- Hyperfine’s implementation should not be copied verbatim: its Markdown row code shown in the source simply joins cells with pipes, so the Rust template needs stronger escaping tests; its file-target management is also specific to incremental benchmark updates rather than this template’s final-document output. ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs))

**Required crate-figure audit**

The exact crates.io and GitHub API telemetry requirement could not be completed faithfully. Direct crates.io API requests were made, but their one-line JSON bodies were not exposed by the research transport; GitHub API and RustSec package-page retrievals likewise did not produce usable response bodies. Rounded mirrors are not substituted for the owner-required exact fields.

| Candidate | Canonical result | Corroborating evidence, not a substitute |
|---|---|---|
| `serde` | `recent_downloads`, exact all-time downloads, GitHub API fields, issue-response median, and RustSec package result remain **unverified** | A September 8, 2026 snapshot reported 295,654,560 downloads over 90 days; another source rounded all-time downloads to 1.36 billion and listed 1.0.229, released July 18, 2026. ([kopass.app](https://kopass.app/tool/crates/serde)) |
| `serde_json` | Download fields, GitHub API fields, issue-response median, and RustSec package result remain **unverified** | Docs.rs reports 1.0.151, released July 20, 2026, and shows its dependency on compatible Serde 1.x versions. ([docs.rs](https://docs.rs/crate/serde_json/latest)) |
| `csv`, runner-up only | Required figures remain **unverified** | Current maintained documentation is for 1.4.0. ([docs.rs](https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool)) |

These missing figures do not select the architecture or formats: popularity is downstream of the fitness gates, and the recommendation is based on standards fit, correctness, scope, and production architecture. They **do** create a mandatory pre-merge re-verification step before the dependency lock is accepted.

### Principles and implementation

**Shared principle:** keep **representation**, **destination**, and **terminal presentation** as separate dimensions, while offering an explicit human contract and an explicit machine contract.

The source of this principle is owner clarification A5 plus F291–F293:

- F291 shows agreement on text and JSON but divergence on the collaboration/export representation.
- F293 exposes the concrete design defect: the same word, `output`, denotes a format in Python and a pathname in TypeScript.
- F292 fixes the capability that `--json` exists.
- Rust CLI guidance independently reinforces separating actual output from diagnostics and rendering through a `Write` boundary. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html))

| Agreement level | What must agree across Python, TypeScript, and Rust | What may vary by ecosystem |
|---|---|---|
| **Capability** | Human-readable text, standards-based machine JSON, an explicit selector, a separate optional file sink, and the inherited `--json` shorthand | A third collaboration/export format may differ only when a documented user job justifies it |
| **Standard** | JSON must be valid RFC 8259 JSON; selected Markdown must target the documented GFM table subset; selected CSV must use a real CSV writer | Concrete enum/string-union implementation |
| **Architectural pattern** | Domain values must remain free of ANSI/OSC markup; each renderer consumes the same semantic result; sink selection happens after format selection | Rust enum dispatch, Python protocol/functions, or TypeScript discriminated unions |
| **Policy** | Format and pathname cannot share the same option spelling; structured output stays clean; diagnostics go to stderr; explicit conflicting selectors fail | Parser-specific conflict declaration |
| **Low-level exact value** | Evidence supports convergence on `--format` for representation and `-o`/`--output` for the file sink | No common low-level evidence requires Python’s Markdown renderer and TypeScript’s CSV renderer to be implemented identically |
| **Rust implementation** | `text`, `json`, `markdown`; `--format`; `-o`/`--output`; `--json` conflict semantics | Private helper types, error type, and table-layout internals |

#### Third-format alternatives

| Alternative | Unique user job | Cost and risk | Decision |
|---|---|---|---|
| **Markdown** | Paste a readable table into a GitHub PR, issue, review comment, or documentation page; can express native links | Small bounded GFM writer; must escape pipes, HTML-sensitive text, backslashes, and embedded line breaks | **Select** |
| **CSV** | Spreadsheet, data-frame, and flat-table import | Requires the `csv` crate for correct quoting; flattens nested data; creates a spreadsheet-formula-injection policy for untrusted cells | Do not ship without an observed spreadsheet acceptance test |
| **Both** | Serves both collaboration and spreadsheet workflows | Adds a fourth public enum variant, another dependency, more fixtures, and two distinct security/escaping policies | Add later only when both jobs are evidenced |
| **Neither** | Minimum code | Gives up the low-cost collaboration export already evidenced by the Python source and the prompt’s PR-paste use case | Reject |

CSV is not intrinsically a bad format. The `csv` crate correctly handles quoting, equal field counts, empty fields, buffering, and Serde records. Hyperfine demonstrates a sound production use. But JSON already supplies this template’s general machine and web-service representation, while Markdown adds a non-duplicative developer-collaboration capability. CSV should therefore be an additive future feature triggered by a real spreadsheet-import requirement. ([docs.rs](https://docs.rs/csv/latest/csv/struct.Writer.html))

Markdown does not need a general Markdown crate. The required output is a narrow GFM table, not arbitrary Markdown parsing or AST transformation. Hyperfine provides maintained precedent for a dedicated Markdown exporter, while the GFM specification provides the escaping contract. The template’s implementation should be stricter than Hyperfine’s short example by testing pipes, backslashes, `<`, `>`, `&`, control characters, links, and multiline cells. ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))

#### Flag contract

```text
--format <text|json|markdown>   Select representation; default is text
--json                         Semantic shorthand for --format json
-o, --output <PATH>            Write the selected representation to PATH
```

- `--format` has **no short spelling**. In particular, `-o` is not reused for format.
- `--output-file` is not part of the new Rust public surface.
- `--json` conflicts with an **explicit** `--format`, including `--format json`. Duplicate ways to state the same decision should not silently override one another.
- `--json` does **not** conflict with `-o`/`--output`; `--json -o report.json` is valid.
- If no `--output` is supplied, result bytes go to stdout.
- `--output -` may explicitly mean stdout.
- A file extension does not infer or override the format.
- Diagnostics remain on stderr.

This assigns the widely conventional `-o`/`--output` meaning to a filename and gives the representation the unambiguous name `--format`. GNU guidance directly recommends `-o`/`--output` for output files; TypeScript D-033 already follows this split. ([gnu.org](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces))

R60 still owns parser selection. If it selects clap, current clap 4.6.6 supports argument aliases and explicit `conflicts_with`/`conflicts_with_all` relationships. A framework without declarative conflicts can enforce the same invariant immediately after parsing. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

To distinguish an explicit `--format text` from the default, the parser-facing field should initially be optional:

```rust
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum OutputFormat {
    Text,
    Json,
    Markdown,
}

pub fn resolve_format(
    format: Option<OutputFormat>,
    json: bool,
) -> Result<OutputFormat, FormatSelectionError> {
    match (format, json) {
        (Some(_), true) => Err(FormatSelectionError::ConflictingSelectors),
        (None, true) => Ok(OutputFormat::Json),
        (Some(format), false) => Ok(format),
        (None, false) => Ok(OutputFormat::Text),
    }
}
```

This avoids accidentally treating a parser-injected default as an explicit conflict and remains independent of R60.

#### Renderer architecture

Use a **closed enum plus format-specific functions**, not a plugin registry or boxed-renderer framework:

```rust
pub fn render(
    format: OutputFormat,
    report: &ProjectReport,
    out: &mut dyn std::io::Write,
) -> Result<(), RenderError> {
    match format {
        OutputFormat::Text => text::render(report, out),
        OutputFormat::Json => json::render(report, out),
        OutputFormat::Markdown => markdown::render(report, out),
    }
}
```

Composition:

1. The domain/application library produces a typed `ProjectReport`.
2. The report and its records derive `serde::Serialize`; they contain semantic values and plain URLs, never ANSI or OSC sequences.
3. Text and Markdown share one row projection, so they cannot silently reorder or reinterpret fields.
4. JSON serializes the typed report directly with `serde_json::to_writer_pretty`, followed by one newline.
5. The CLI renders to `Vec<u8>` before opening the target file.
6. The CLI then writes those bytes to locked stdout or uses `std::fs::write` for the pathname.
7. The web service reuses the same serializable DTO rather than invoking the CLI or parsing its output.

The Rust CLI Working Group demonstrates `Write`-parameterized output for testability. Serde separates Rust data structures from format implementations, and `serde_json` is the established JSON implementation. Hyperfine independently demonstrates separate exporter modules and target management. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/testing.html))

#### Format-specific policy

- **Text:** human table/rows; plain when redirected or written to a file. R85 may later add generated terminal-only OSC-8 links or relative-time styling when stdout is a terminal.
- **JSON:** pretty RFC 8259 JSON with a final LF. No colors, OSC sequences, Markdown, or preformatted relative timestamps.
- **Markdown:** plain UTF-8 GFM table with a final LF. Native Markdown links are permitted when built from structured, validated URL fields. Arbitrary text is escaped before insertion.
- **Future CSV:** plain scalar values only; no terminal markup or Markdown. Use `csv`, never string concatenation.

Markdown may therefore carry an equivalent **semantic** link, but not terminal control sequences. JSON carries the underlying label and URL as separate fields. A future CSV renderer would carry the raw URL. This preserves the data while allowing each representation’s native presentation.

#### Existing-file behavior

`-o/--output` should **overwrite/truncate** an existing regular file after rendering succeeds. It must never append: appending can produce invalid JSON, duplicate Markdown headers, and ambiguous text documents. Rendering first prevents a serialization error from destroying the previous file; `std::fs::write` then supplies the simple whole-file replacement behavior. Atomic replacement against disk or process failure is not promised by this item. ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/fn.write.html))

#### Performance assessment

No performance benchmark was executed, and no “fastest” claim is made. The selection is correctness-led.

The proposed representative measurement is:

- 100,000 project rows;
- 32-byte names, status enum, description containing escaping characters, and one URL;
- `--release` build;
- text, pretty JSON, and Markdown rendered independently to `Vec<u8>`;
- 3 warmups and 20 measured runs;
- report latency, rows/second, output bytes, peak RSS, and final release-binary size;
- record CPU, Rust version, target triple, and exact lockfile.

Hyperfine is suitable instrumentation for this proposed measurement, but its published behavior is not treated as a benchmark of these renderers. Serde’s documentation describes low-overhead specialization, while the CSV writer documents buffering and allocation behavior; neither establishes an absolute winner for this workload. ([serde.rs](https://serde.rs/))

#### Observable acceptance criteria

1. Help lists exactly `text`, `json`, and `markdown`; default is `text`.
2. `--json` and `--format json` produce byte-identical output when used separately.
3. `--json --format json` and `--json --format text` both fail before command execution.
4. `--json -o result.json` succeeds.
5. `--format markdown -o result.md` writes no result bytes to stdout.
6. File bytes are identical to the same invocation captured from stdout.
7. A pre-existing target is replaced, not appended.
8. Invalid format names fail with the valid lower-case values.
9. JSON parses successfully and contains no escape byte `0x1b`.
10. Markdown has a valid GFM header and delimiter row; hostile cells cannot create extra columns or raw HTML.
11. Text and Markdown contain the same records in the same order.
12. R85 styling changes cannot affect JSON or Markdown snapshots.
13. The library renderer tests do not instantiate the CLI parser or web server.
14. CI succeeds on Rust 1.96 and stable on both `ubuntu-latest` and `macos-latest`.

`BASELINE-REVIEW: F291 — third-format selection must be justified by a distinct user job, not source union or familiarity — set R66 to text/json/markdown; keep TypeScript CSV unchanged pending a follow-on review that demonstrates a spreadsheet-import acceptance case — GFM supplies the collaboration standard, JSON already supplies the general machine contract, and CSV adds flatness and formula-injection policy.` ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))

`BASELINE-REVIEW: F293 — representation and destination are orthogonal and should have one unambiguous spelling each — use --format for representation and -o/--output for the file sink; review Python’s overloaded --output format flag only in a separately recorded migration — GNU convention, Rust CLI architecture, and TypeScript D-033 support the split.` ([gnu.org](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces))

### Recommendation

**Stack name: R66 role-separated output surface v1**

- **Formats:** `text`, `json`, `markdown`.
- **Default:** `text`.
- **Format selector:** `--format <text|json|markdown>`, no short form.
- **JSON shorthand:** `--json`, semantically equivalent to `--format json`.
- **Mutual exclusion:** explicit `--json` conflicts with explicit `--format`; neither conflicts with the file sink.
- **File sink:** `-o <PATH>` / `--output <PATH>`.
- **Legacy spelling:** do not add `--output-file` to the new Rust CLI.
- **Existing file:** render successfully, then overwrite/truncate; never append.
- **Crates:** `serde 1.0.229` with `derive`, and `serde_json 1.0.151`.
- **Text and Markdown:** internal renderers over `std::io::Write`; no Markdown-table crate.
- **Future CSV:** add only after an evidenced spreadsheet workflow; use `csv 1.4.0` rather than hand-rolling.
- **Presentation rule:** only the text renderer may receive R85’s terminal-only niceties; JSON and Markdown remain free of terminal control sequences.

JSON is the machine and web-service representation; Markdown is the complementary developer-collaboration representation. ([rfc-editor.org](https://www.rfc-editor.org/info/rfc8259/))

### Members

#### Output contract and std/GFM renderers

##### Landscape

This is a **pattern member**, so crates.io download, release, GitHub-issue, and RustSec figures are **inapplicable**. Its implementation inputs are stable `std` APIs and the GFM specification.

The mapped alternatives were direct printing, renderer-to-`Write`, renderer-to-bytes followed by sink selection, a trait-object exporter registry, and a closed enum dispatch. The Rust CLI Working Group’s testable `Write` pattern and Hyperfine’s separated exporter/target architecture are the strongest references. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/testing.html))

##### Principles and implementation

Use one semantic report, one shared tabular projection for text/Markdown, separate renderer modules, and destination handling outside the renderer.

The renderer API accepts `&mut dyn Write`; the CLI normally calls it with `Vec<u8>` so serialization succeeds before a pathname is truncated. Tests may pass a `Vec<u8>` directly, while stdout uses a locked handle. This gives library callers a streaming-capable API without coupling the renderer to files or terminals. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html))

##### Dominant choice

**Closed `OutputFormat` enum plus `match` dispatch, backed by `std::io::Write`.**

This is preferable to a format plugin registry because the public CLI surface is intentionally closed and small. Adding a format should require an explicit enum change, renderer, documentation, snapshots, and compatibility review.

##### Qualified shortlist

1. **Text + JSON + Markdown, enum dispatch:** selected.
2. **Text + JSON + Markdown + CSV:** qualified only after a spreadsheet-import requirement.
3. **Text + JSON + CSV:** technically sound with `csv`, but duplicates machine-export capability while removing the PR/documentation job.
4. **Text + JSON only:** smallest, but leaves a demonstrated collaboration job unmet.
5. **Trait-object exporter registry:** useful for third-party plugins, but no plugin requirement exists.

##### Excluded by gate

- **Hand-written CSV using joins or string interpolation:** excluded by the correctness gate. Correct CSV needs quoting, embedded-newline handling, empty-field handling, and consistent records; the maintained `csv` writer implements those details. ([docs.rs](https://docs.rs/csv/latest/csv/struct.Writer.html))
- **One preformatted/styled string reused by every renderer:** excluded by the plain-output and security gates because ANSI/OSC or terminal-relative values could leak into JSON and Markdown.
- **Opening/truncating the target before rendering:** excluded by the data-loss behavior gate.
- No named Markdown crate failed a license or advisory gate; a general Markdown dependency was rejected on fit and integration cost rather than popularity.

##### Up-and-comers

No format-framework up-and-comer is recommended. A specialized CSV serializer such as `serde_csv_core` may be relevant to an embedded or constrained target, but not to this `std`, CLI, library, and web-service template. ([docs.rs](https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html))

##### Fit for this template

The pattern lets:

- the library own typed result data;
- the CLI own flag parsing and sink selection;
- the web service serialize the same DTO;
- R85 modify only text-cell presentation;
- R64 page only final text output;
- JSON and Markdown remain deterministic and non-terminal.

That is a direct fit for the three-faced target architecture without making the web service depend on CLI concepts.

##### Recommendation

Implement:

```text
src/output/
  mod.rs
  model.rs
  text.rs
  json.rs
  markdown.rs
```

Keep CLI-only selection normalization in the CLI adapter:

```text
src/cli/output.rs
```

The Markdown renderer should implement only the emitted GFM subset:

- escape `&`, `<`, and `>` in arbitrary text;
- escape backslashes and pipes;
- normalize embedded CR/LF without creating another table row;
- construct links only from structured URL fields;
- emit one header, one delimiter row, zero or more data rows, and a final LF.

GFM tables are an extension rather than core CommonMark, so documentation must name **GitHub Flavored Markdown**, not an unspecified generic Markdown dialect. ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))

##### Ranked runner-up

Add `Csv` as a **fourth** format using `csv 1.4.0` if an acceptance case requires direct Excel, LibreOffice, pandas, R, or similar flat-table import.

If added:

- use `csv::WriterBuilder`;
- define a fixed scalar column schema;
- document LF versus CRLF terminator choice;
- decide whether output is raw interoperable CSV or spreadsheet-sanitized CSV;
- do not claim universal formula-injection safety.

The crate’s writer handles core CSV correctness, but spreadsheet formula interpretation is a separate application security concern. ([docs.rs](https://docs.rs/csv/latest/csv/struct.Writer.html))

##### Tradeoffs

- Buffer-before-file uses memory proportional to output size, but protects existing files from renderer failures. If reports become very large, replace it with temp-file-plus-rename rather than direct truncation.
- A hand-written GFM subset requires careful escaping tests but avoids a large parser/AST dependency.
- Markdown tables cannot naturally represent arbitrary nested data; JSON remains authoritative.
- Not shipping CSV means spreadsheet users need JSON conversion until a real product requirement justifies the extra surface.
- Overwrite is automation-friendly but destructive; append is deliberately unavailable.

##### Parameters

- `output-formats = [text, json, markdown]`
- `output-format-default = text`
- `output-format-flag = --format`
- `output-format-short = none`
- `output-file-flag = -o, --output`
- `output-file-legacy-alias = none`
- `output-file-existing = overwrite-after-successful-render`
- `json-shorthand-conflict = conflicts-with-explicit-format`
- `format-inference-from-extension = false`
- `non-text-terminal-controls = forbidden`

##### Migration implications

- Replace any direct `println!`-based result rendering with `render(..., &mut Write)`.
- Keep logging and diagnostics on stderr.
- Remove format decisions from file-opening code.
- Do not expose `--output-file` in generated help or completions.
- Python and TypeScript remain unchanged by this item; their follow-on migrations must be separately recorded.
- Preserve text row semantics so R85 can enhance cells without changing JSON or Markdown.

##### Validation strategy

Planned unit tests:

- default and explicit format resolution;
- every `--json`/`--format` combination;
- text/Markdown row parity;
- Markdown cells containing `|`, `\`, HTML tags, brackets, URLs, CR/LF, Unicode, and escape bytes;
- render failure leaves an existing file unchanged;
- successful write replaces a sentinel rather than appending;
- file output equals stdout output byte-for-byte.

Planned integration tests should use the parser selected by R60 and verify exit status, stdout, stderr, and file content.

##### Confidence & re-verify trigger

**Confidence: high, 0.90.**

Re-verify if:

- the local divergence analysis declares exact third-format parity rather than capability-level agreement;
- an owner requirement names spreadsheet import;
- outputs routinely exceed the memory budget for buffer-before-write;
- R85 requires semantic fields not present in the shared row projection;
- the selected R60 framework cannot distinguish explicit format selection from the default.

##### Sources

Retrieved September 9, 2026:

- Rust CLI output guidance: `https://rust-cli.github.io/book/tutorial/output.html` ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html))
- Rust CLI testing through `Write`: `https://rust-cli.github.io/book/tutorial/testing.html` ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/testing.html))
- GFM specification: `https://github.github.com/gfm/` ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))
- GNU CLI standards: `https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces` ([gnu.org](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces))
- Hyperfine exporter architecture: `https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs))
- Hyperfine Markdown renderer: `https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs))
- CSV writer: `https://docs.rs/csv/latest/csv/struct.Writer.html` ([docs.rs](https://docs.rs/csv/latest/csv/struct.Writer.html))
- OWASP CSV injection: `https://owasp.org/www-community/attacks/CSV_Injection` ([owasp.org](https://owasp.org/www-community/attacks/CSV_Injection))
- Whole-file write API: `https://doc.rust-lang.org/stable/std/fs/fn.write.html` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/fn.write.html))

#### Serde JSON stack — serde 1.0.229 + serde_json 1.0.151

##### Landscape

The JSON implementation landscape contains:

- manual JSON string generation;
- a typed serialization framework plus a JSON serializer;
- performance-specialized JSON implementations;
- handing the whole task to the CLI or web framework.

Manual generation fails the escaping and schema-maintenance fit test. Framework-owned serialization couples the library to whichever web or CLI framework is chosen. `serde` plus `serde_json` is the dominant ecosystem-neutral option and is directly reusable by the web-service layer. Serde’s documented role is mapping Rust types to format serializers; `serde_json` implements the JSON conventions. ([serde.rs](https://serde.rs/data-format.html))

##### Principles and implementation

The domain/application result type should derive `Serialize`; JSON rendering should serialize that type directly rather than serializing text-table cells.

Recommended manifest:

```toml
[package]
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[dependencies]
serde = { version = "1.0.229", features = ["derive"] }
serde_json = "1.0.151"
```

On September 9, 2026, Rust 1.98.1 is stable; the owner’s stable-minus-two policy therefore resolves to a current floor of Rust 1.96. ([releases.rs](https://releases.rs/))

Recommended renderer:

```rust
pub fn render(
    report: &ProjectReport,
    out: &mut dyn std::io::Write,
) -> Result<(), RenderError> {
    serde_json::to_writer_pretty(&mut *out, report)?;
    out.write_all(b"\n")?;
    Ok(())
}
```

Use a top-level object or envelope rather than concatenated independent JSON values. If the JSON schema becomes a documented external API, add an explicit schema version before making a breaking shape change, following Cargo’s compatibility precedent. ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html))

##### Dominant choice

**Serde derive plus `serde_json::to_writer_pretty`.**

Reasons:

- standards-conforming JSON;
- same DTO usable by CLI, library consumers, and web service;
- no async-runtime coupling;
- streaming writer API;
- maintained production adoption;
- no bespoke escaping logic.

Hyperfine’s current JSON exporter uses Serde and `serde_json::to_vec_pretty`, adds a trailing newline, and wraps results in a top-level summary. That is a close maintained reference. ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs))

##### Qualified shortlist

1. **`serde` derive + pretty `serde_json`:** selected.
2. **`serde` derive + compact `serde_json`:** qualified for very large machine-only output.
3. **Manual `Serialize` implementations + `serde_json`:** qualified only if proc-macro compile time becomes measured and material.
4. **A performance-specialized JSON crate:** reconsider only after a representative benchmark shows JSON serialization is a bottleneck.

##### Excluded by gate

- **Manual JSON concatenation:** excluded by standards correctness and untrusted-string escaping.
- **Serializing preformatted text or Markdown cells into JSON:** excluded by architecture and machine-contract gates.
- **A web-framework-only response type as the canonical model:** excluded because the library and CLI must remain framework-independent.
- No alternative crate was excluded merely for lower popularity.

##### Up-and-comers

None is promoted. A performance-oriented replacement would need to demonstrate:

- RFC 8259-equivalent output;
- Rust 1.96 compatibility;
- zero open RustSec advisories;
- acceptable unsafe posture;
- no requirement to mutate input buffers;
- lower end-to-end latency on the actual report fixture;
- acceptable compile and binary-size cost.

No such measured need is currently present.

##### Fit for this template

The stack fits all three target faces:

- **Library:** typed serializable reports without CLI dependencies.
- **CLI:** direct JSON output to any `Write`.
- **Web service:** the same DTO can be returned through the chosen web framework’s Serde integration.
- **Tests:** snapshots and structural deserialization.
- **OS:** no OS-specific output implementation.
- **Runtime:** no Tokio or other async dependency is introduced by serialization.

##### Recommendation

Use exact current manifest lower bounds:

- `serde = 1.0.229`, feature `derive`;
- `serde_json = 1.0.151`, default features.

Commit the application workspace’s `Cargo.lock`. Do not use `=` pins in library dependency declarations; let the lockfile provide application reproducibility while normal compatible-version resolution remains available to library users.

All JSON-visible types should:

- derive `Serialize`;
- use explicit field names when compatibility matters;
- avoid serializing terminal-formatted strings;
- preserve original timestamps and URLs;
- document whether adding fields is considered compatible.

##### Ranked runner-up

Retain `serde_json` but replace derives with manual `Serialize` implementations if a measured build-time investigation shows `serde_derive`’s proc-macro dependency is a significant template cost.

That keeps the JSON implementation and contract unchanged while removing derive-time dependencies. It is not recommended preemptively because manual serializers increase maintenance and schema-drift risk.

##### Tradeoffs

- `serde_derive` adds proc-macro compile work and its supporting macro dependency tree.
- Pretty JSON is larger and somewhat slower than compact JSON, but easier to inspect and aligns with the close Hyperfine reference. No benchmark was run for this template.
- Adding or renaming serialized fields can become a compatibility event even when Rust’s internal types still compile.
- `serde` and `serde_json` are third-party dependencies; `#![forbid(unsafe_code)]` in template crates does not constrain their internals.
- The latest-version and maintenance telemetry remains provisional until the required API audit is rerun.

##### Parameters

- `serde-version = 1.0.229`
- `serde-features = [derive]`
- `serde-json-version = 1.0.151`
- `json-layout = pretty-single-document`
- `json-final-newline = true`
- `json-model = typed-domain-report`
- `json-terminal-markup = forbidden`
- `async-runtime-coupling = none`
- `own-code-unsafe = forbidden`
- `rust-version-current-floor = 1.96`

##### Migration implications

- Add dependencies to workspace or package `Cargo.toml`.
- Add `Serialize` derives to output DTOs, not persistence/domain objects that should not automatically become public.
- Add `src/output/json.rs`.
- Make the web-service handler return or serialize the same DTO.
- Add JSON fixtures and structural tests.
- Document JSON compatibility expectations.
- Commit/update `Cargo.lock`.
- Add license, advisory, feature, and MSRV checks to CI.

##### Validation strategy

**Fitness gates**

| Gate | Assessment before popularity |
|---|---|
| License | Expected pass: both projects use the Rust ecosystem’s MIT/Apache-2.0 dual-license convention; final proof must come from locked `cargo metadata`/`cargo-deny` output |
| MSRV | Expected pass; final proof is `cargo +1.96 test --workspace --all-targets`. Hyperfine’s maintained manifest declares Rust 1.88 while depending on Serde and `serde_json`, providing supporting—not conclusive—compatibility evidence. ([github.com](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml)) |
| RustSec and unsafe | No advisory surfaced during the survey, but the required package-page result was not retrieved. Selection is conditional on `cargo audit`/`cargo deny check advisories`. Own renderer code uses `#![forbid(unsafe_code)]`; dependency unsafe usage should be recorded with `cargo geiger`. |
| OS | Template CI must run Ubuntu and macOS. The stack is also used by cross-platform Hyperfine; Windows remains supported but is not required by the fixed matrix. Rust identifies mainstream Linux, macOS, and Windows hosts among supported host targets. ([forge.rust-lang.org](https://forge.rust-lang.org/release/platform-support.html)) |
| Features/runtime | `serde` default `std` plus `derive`; `serde_json` defaults; no async runtime |
| Compile/binary cost | Qualitatively low-to-moderate: JSON serializer plus derive proc macros; no measured size result yet |

**Required crate figures**

| Figure | `serde` | `serde_json` |
|---|---|---|
| 90-day downloads | Exact API value not captured; noncanonical September 8 snapshot: 295,654,560 ([kopass.app](https://kopass.app/tool/crates/serde)) | Not captured |
| All-time downloads | Exact API value not captured; third-party rounded value: 1.36B ([releasealert.dev](https://releasealert.dev/cratesio/serde)) | Not captured |
| Last non-yanked release | 1.0.229, July 18, 2026, corroborated outside the required endpoint ([releasealert.dev](https://releasealert.dev/cratesio/serde)) | 1.0.151, July 20, 2026 ([docs.rs](https://docs.rs/crate/serde_json/latest)) |
| Stars/archived/pushed | Required GitHub API result not captured | Required API result not captured; Docs.rs displayed 5,633 stars as corroboration, not canonical API evidence ([docs.rs](https://docs.rs/crate/serde_json/latest)) |
| Open issues | Required search API total not captured | Required search API total not captured |
| Issue responsiveness | Not measured; 10-issue maintainer-response calculation remains mandatory | Not measured; same |
| Advisories | Required RustSec package endpoint not captured | Required endpoint not captured |
| Maintenance rubric | **active**, based on a release within two months of retrieval | **active**, based on a release within two months of retrieval |

**Adopter:** Hyperfine is the shared maintained reference. Its current manifest directly declares `serde`, `serde_json`, and `csv`; its repository has approximately 28,000 stars and implements separate JSON, CSV, and Markdown exporters. Its reverse-dependency listing was not retrieved, so this is source-confirmed adoption but not a complete owner-prescribed adopter check. ([github.com](https://github.com/sharkdp/hyperfine))

##### Confidence & re-verify trigger

**Confidence: medium-high, 0.82.**

The architecture and crate identities are high confidence. Exact version telemetry, API-derived maintenance figures, issue responsiveness, and direct RustSec package results are incomplete.

Re-verify:

- immediately before generating `Cargo.lock`;
- if implementation begins on or after October 1, 2026, when Rust 1.99 is scheduled and stable-minus-two would become Rust 1.97;
- on any new Serde or `serde_json` release;
- on any RustSec advisory;
- if a 100,000-row benchmark identifies JSON as a material bottleneck;
- if the web framework requires a conflicting DTO shape. ([releases.rs](https://releases.rs/))

##### Sources

Retrieved September 9, 2026:

- Serde overview: `https://serde.rs/` ([serde.rs](https://serde.rs/))
- Serde JSON conventions: `https://serde.rs/json.html` ([serde.rs](https://serde.rs/json.html))
- Serde format architecture: `https://serde.rs/data-format.html` ([serde.rs](https://serde.rs/data-format.html))
- `serde_json` package page: `https://docs.rs/crate/serde_json/latest` ([docs.rs](https://docs.rs/crate/serde_json/latest))
- Hyperfine manifest: `https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml))
- Hyperfine JSON renderer: `https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs))
- JSON standard: `https://www.rfc-editor.org/info/rfc8259/` ([rfc-editor.org](https://www.rfc-editor.org/info/rfc8259/))
- Rust release list: `https://blog.rust-lang.org/releases/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

Required endpoints attempted or requiring pre-merge retrieval:

```text
GET https://crates.io/api/v1/crates/serde
GET https://crates.io/api/v1/crates/serde/versions
GET https://crates.io/api/v1/crates/serde_json
GET https://crates.io/api/v1/crates/serde_json/versions

GET https://api.github.com/repos/serde-rs/serde
GET https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open
GET https://api.github.com/repos/serde-rs/json
GET https://api.github.com/search/issues?q=repo:serde-rs/json+is:issue+is:open

https://rustsec.org/packages/serde.html
https://rustsec.org/packages/serde_json.html
```

### Compatibility

**Shared adopter proof:** Hyperfine 1.20.0 composes `serde = "1.0"`, `serde_json = "1.0"`, and `csv = "1.3"` in one maintained cross-platform Rust CLI. Its exporter modules serialize JSON, write CSV using the `csv` crate, and generate Markdown separately. Its manifest declares Rust 1.88.0, below this template’s current Rust 1.96 floor. ([github.com](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml))

`serde_json` 1.0.151 documents a compatible Serde 1.x dependency, and `serde` 1.0.229 satisfies that range. ([docs.rs](https://docs.rs/crate/serde_json/latest))

| Matrix entry | Planned combination |
|---|---|
| Edition | 2024 |
| MSRV on September 9, 2026 | Rust 1.96 |
| Stable verification | Rust 1.98.1 |
| OS | `ubuntu-latest`, `macos-latest` |
| Serde | 1.0.229, `derive` |
| `serde_json` | 1.0.151 |
| Default features | Enabled |
| Async runtime | None |
| Renderer substrate | `std::io::Write` |
| Markdown dialect | GFM table subset |

This matrix is **source-compatible by dependency ranges and reference adoption**, but was not compiled in this research environment. The planned CI checks below are the authoritative integration proof.

### Parameters

```text
owns output-formats = [text, json, markdown]
owns output-format-default = text
owns output-format-selector = --format <text|json|markdown>
owns output-format-short = none
owns output-file-selector = -o, --output <PATH>
owns output-file-legacy-alias = none
owns json-shorthand-resolution = --json => json
owns selector-mutual-exclusion = --json conflicts with explicit --format
owns output-file-existing-policy = overwrite-after-successful-render
owns output-file-append = unsupported
owns output-format-extension-inference = disabled
owns markdown-dialect = GFM-table-subset
owns non-text-terminal-controls = forbidden

assumes json-shorthand-exists = true (F292, owner-fixed)
assumes rust-edition = 2024
assumes rust-version-policy = stable minus 2 minor versions
assumes current rust-version floor = 1.96 as of 2026-09-09
assumes license = MIT OR Apache-2.0
assumes target-os-matrix = ubuntu-latest, macos-latest
assumes R60 parser can declare enum values and conflicts, or permits immediate post-parse validation
```

No `CONFLICT:` line is required.

### Migration implications

**Rust template**

- `Cargo.toml`
  - set `edition = "2024"`;
  - set `rust-version = "1.96"` under the current policy;
  - add `serde 1.0.229` with `derive`;
  - add `serde_json 1.0.151`;
  - do not add `csv` or a Markdown-table runtime dependency.
- `src/lib.rs`
  - export typed report DTOs and format-specific renderer functions as appropriate;
  - do not expose CLI parser types from the domain layer.
- `src/output/model.rs`
  - define the serializable report/row DTO;
  - keep semantic URLs/timestamps separate from presentation.
- `src/output/text.rs`
  - plain row renderer and shared row projection;
  - leave R85-only terminal transformations behind an explicit text/TTY path.
- `src/output/json.rs`
  - pretty single-document JSON plus final LF.
- `src/output/markdown.rs`
  - bounded, escaped GFM table renderer;
  - native links only from structured URL fields.
- `src/cli/output.rs`
  - define `OutputFormat::{Text, Json, Markdown}`;
  - parse `--format` as optional;
  - normalize the inherited `--json`;
  - reject explicit selector conflicts.
- CLI entry point
  - render before opening a pathname;
  - use locked stdout or `std::fs::write`;
  - send diagnostics to stderr.
- Web-service handlers
  - reuse the DTO/Serde representation directly;
  - do not run the CLI renderer as a subprocess or parse CLI output.
- Tests
  - add unit tests, CLI integration tests, hostile-string fixtures, and snapshots.
- Documentation/completions
  - update help, README examples, generated completions, man pages, and examples to show `--format` and `-o/--output`.

**Cross-repository follow-on, not performed here**

- Python: evaluate a major-version or staged migration from `-o/--output` as format to `--format`; reserve `-o/--output` for the sink; keep `--output-file` as a temporary deprecated alias only if its migration policy allows it.
- TypeScript: retain its current flag naming. Treat CSV’s continued presence as justified only if spreadsheet use is documented; do not remove it silently.
- Ledger: record both `BASELINE-REVIEW` findings before changing F291 or F293 classifications.

### Validation strategy

**Execution status:** these commands and tests are proposed; none was run in this research environment.

**Toolchain and OS**

```bash
cargo +1.96 check --workspace --all-targets
cargo +1.96 test --workspace --all-targets
cargo +stable test --workspace --all-targets
cargo +stable clippy --workspace --all-targets --all-features -- -D warnings
cargo +stable fmt --all -- --check
```

Expected: all succeed on `ubuntu-latest` and `macos-latest`.

**Dependency policy**

```bash
cargo tree -e features
cargo metadata --format-version 1 > target/metadata.json
cargo deny check licenses advisories bans sources
cargo audit
```

Expected:

- only intended Serde features;
- licenses compatible with `MIT OR Apache-2.0`;
- zero open advisories;
- no unexpected async runtime;
- lockfile resolves versions compatible with Rust 1.96.

**CLI contract integration tests**

Suggested test names:

```bash
cargo test --test cli_output default_is_text
cargo test --test cli_output explicit_formats_are_accepted
cargo test --test cli_output json_shorthand_matches_format_json
cargo test --test cli_output json_conflicts_with_explicit_format
cargo test --test cli_output output_path_is_independent_of_format
cargo test --test cli_output existing_file_is_replaced_not_appended
cargo test --test cli_output file_bytes_equal_stdout_bytes
cargo test --test cli_output machine_formats_contain_no_terminal_controls
cargo test --test cli_output markdown_escapes_hostile_cells
cargo test --test cli_output text_and_markdown_preserve_row_order
```

Expected behaviors:

- conflict cases exit nonzero before business logic;
- result stdout is empty when a pathname sink is selected;
- diagnostics appear only on stderr;
- pre-existing sentinel content disappears;
- one valid JSON document remains;
- Markdown hostile values cannot create extra columns or raw HTML;
- `0x1b` is absent from JSON and Markdown.

**Illustrative shell acceptance**

```bash
cargo run --quiet -- projects --format json > target/by-format.json
cargo run --quiet -- projects --json > target/by-shorthand.json
cmp target/by-format.json target/by-shorthand.json

printf 'SENTINEL\n' > target/projects.md
cargo run --quiet -- projects --format markdown \
  --output target/projects.md \
  > target/unexpected-stdout.txt

test ! -s target/unexpected-stdout.txt
! grep -q SENTINEL target/projects.md

python3 - <<'PY'
import json
from pathlib import Path

raw = Path("target/by-format.json").read_bytes()
assert b"\x1b" not in raw
json.loads(raw)

md = Path("target/projects.md").read_bytes()
assert b"\x1b" not in md
assert b"|" in md
PY
```

**Conflict acceptance**

```bash
if cargo run --quiet -- projects --json --format json \
     >target/conflict.stdout 2>target/conflict.stderr
then
  echo "expected selector conflict" >&2
  exit 1
fi

test ! -s target/conflict.stdout
test -s target/conflict.stderr
```

**Performance characterization, informational**

Create a deterministic `render_fixture` example producing 100,000 rows, then measure each format:

```bash
cargo build --release --example render_fixture

hyperfine --warmup 3 --runs 20 \
  './target/release/examples/render_fixture --rows 100000 --format text' \
  './target/release/examples/render_fixture --rows 100000 --format json' \
  './target/release/examples/render_fixture --rows 100000 --format markdown'
```

Record CPU, OS, Rust version, lockfile hash, elapsed-time distribution, output size, and peak RSS. Do not establish a hard latency gate until an initial baseline exists.

**Mandatory telemetry recheck**

```bash
for crate in serde serde_json csv; do
  curl -fsS "https://crates.io/api/v1/crates/$crate" |
    jq '.crate | {id, recent_downloads, downloads}'

  curl -fsS "https://crates.io/api/v1/crates/$crate/versions" |
    jq '[.versions[] | select(.yanked == false)]
        | sort_by(.created_at) | last
        | {num, created_at, rust_version, license}'
done
```

For each repository, retrieve:

```text
GET https://api.github.com/repos/<owner>/<repo>
GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open
GET https://api.github.com/repos/<owner>/<repo>/issues?state=open&sort=created&direction=desc&per_page=10
```

For the ten latest issues, identify the first response whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`; report median elapsed days and unanswered count. This must be attached to the implementation record before dependency lock approval.

### Confidence & re-verify trigger

**Overall confidence: 0.87 on the design decision; 0.70 on exact dependency telemetry.**

High-confidence findings:

- representation and destination should be separate;
- `--format` plus `-o/--output` is clearer and better supported than overloading `--output`;
- `--json` should remain and conflict with explicit `--format`;
- Markdown is the best complementary third format for the stated developer-collaboration job;
- CSV should use the `csv` crate if later added;
- terminal presentation must not leak into JSON or Markdown;
- renderer-to-`Write` with sink handling outside renderers fits CLI + library + web service.

Mandatory re-verification triggers:

1. Inspect the local `docs/port/DIVERGENCE-ANALYSIS.md` before changing F291/F293.
2. Complete the exact crates.io, GitHub, issue-responsiveness, reverse-dependency, and RustSec figures before merging.
3. Recalculate `rust-version` if implementation begins on or after October 1, 2026; the stable-minus-two floor is then expected to move from 1.96 to 1.97. ([releases.rs](https://releases.rs/))
4. Re-run all gates on any selected-crate release or advisory.
5. Reopen the format decision if an owner-backed acceptance test requires direct spreadsheet import.
6. Reopen buffer-before-write if measured output sizes make its memory cost material.
7. Reopen pretty versus compact JSON only with representative workload measurements.

### Sources

All retrieved September 9, 2026 unless noted.

**Owner-supplied repository evidence**

```text
repo:docs/port/COMMONALITY.md#F291
repo:docs/port/COMMONALITY.md#F292
repo:docs/port/COMMONALITY.md#F293
repo:docs/port/PARAMETERS.md
repo:ts-launch-blueprint/docs/port/TS_PORT_DECISIONS.md#D-033
repo:docs/port/DIVERGENCE-ANALYSIS.md
```

The final path was referenced but its contents were unavailable in this research environment.

**Rust project and first-party guidance**

- `https://rust-cli.github.io/book/tutorial/output.html` ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/output.html))
- `https://rust-cli.github.io/book/tutorial/testing.html` ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/testing.html))
- `https://rust-cli.github.io/book/in-depth/machine-communication.html` ([rust-cli.github.io](https://rust-cli.github.io/book/in-depth/machine-communication.html))
- `https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html` ([doc.rust-lang.org](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html))
- `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/` ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))
- `https://blog.rust-lang.org/releases/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- `https://forge.rust-lang.org/release/platform-support.html` ([forge.rust-lang.org](https://forge.rust-lang.org/release/platform-support.html))
- `https://doc.rust-lang.org/stable/std/fs/fn.write.html` ([doc.rust-lang.org](https://doc.rust-lang.org/stable/std/fs/fn.write.html))

**Standards and security**

- `https://www.rfc-editor.org/info/rfc8259/` ([rfc-editor.org](https://www.rfc-editor.org/info/rfc8259/))
- `https://www.rfc-editor.org/info/rfc4180/` ([rfc-editor.org](https://www.rfc-editor.org/info/rfc4180/))
- `https://github.github.com/gfm/` ([github.github.com](https://github.github.com/gfm/?ref=scriptorium))
- `https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces` ([gnu.org](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces))
- `https://www.gnu.org/prep/standards/html_node/Option-Table.html` ([gnu.org](https://www.gnu.org/prep/standards/html_node/Option-Table.html))
- `https://owasp.org/www-community/attacks/CSV_Injection` ([owasp.org](https://owasp.org/www-community/attacks/CSV_Injection))

**Maintainer documentation**

- `https://serde.rs/` ([serde.rs](https://serde.rs/))
- `https://serde.rs/json.html` ([serde.rs](https://serde.rs/json.html))
- `https://serde.rs/data-format.html` ([serde.rs](https://serde.rs/data-format.html))
- `https://docs.rs/crate/serde_json/latest` ([docs.rs](https://docs.rs/crate/serde_json/latest))
- `https://docs.rs/csv/latest/csv/struct.Writer.html` ([docs.rs](https://docs.rs/csv/latest/csv/struct.Writer.html))
- `https://docs.rs/csv/latest/csv/struct.WriterBuilder.html` ([docs.rs](https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool))
- `https://docs.rs/clap/latest/clap/struct.Arg.html` ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

**Maintained production references**

- `https://github.com/sharkdp/hyperfine` ([github.com](https://github.com/sharkdp/hyperfine))
- `https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml))
- `https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs))
- `https://github.com/sharkdp/hyperfine/blob/master/src/export/csv.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/csv.rs))
- `https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs))
- `https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs` ([github.com](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs))
- `https://github.com/BurntSushi/ripgrep/discussions/3404` ([github.com](https://github.com/BurntSushi/ripgrep/discussions/3404))
- `https://github.com/BurntSushi/ripgrep/discussions/1592` ([github.com](https://github.com/BurntSushi/ripgrep/discussions/1592))

**Registry corroboration and required endpoints**

- `https://releasealert.dev/cratesio/serde` ([releasealert.dev](https://releasealert.dev/cratesio/serde))
- `https://kopass.app/tool/crates/serde` — metric snapshot dated September 8, 2026. ([kopass.app](https://kopass.app/tool/crates/serde))
- `https://crates.io/api/v1/crates/serde` ([crates.io](https://crates.io/api/v1/crates/serde))
- `https://crates.io/api/v1/crates/serde/versions`
- `https://crates.io/api/v1/crates/serde_json` ([crates.io](https://crates.io/api/v1/crates/serde_json))
- `https://crates.io/api/v1/crates/serde_json/versions`
- `https://crates.io/api/v1/crates/csv`
- `https://crates.io/api/v1/crates/csv/versions`

## Sources

- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://www.rfc-editor.org/info/rfc8259/](https://www.rfc-editor.org/info/rfc8259/)
- [https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html](https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html)
- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html)
- [https://www.rfc-editor.org/info/rfc8259/](https://www.rfc-editor.org/info/rfc8259/)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces)
- [https://serde.rs/](https://serde.rs/)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://owasp.org/www-community/attacks/CSV_Injection](https://owasp.org/www-community/attacks/CSV_Injection)
- [https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html)
- [https://github.com/BurntSushi/ripgrep/discussions/3404](https://github.com/BurntSushi/ripgrep/discussions/3404)
- [https://github.com/sharkdp/hyperfine](https://github.com/sharkdp/hyperfine)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs)
- [https://kopass.app/tool/crates/serde](https://kopass.app/tool/crates/serde)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool](https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool)
- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://docs.rs/csv/latest/csv/struct.Writer.html](https://docs.rs/csv/latest/csv/struct.Writer.html)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces)
- [https://docs.rs/clap/latest/clap/struct.Arg.html](https://docs.rs/clap/latest/clap/struct.Arg.html)
- [https://rust-cli.github.io/book/tutorial/testing.html](https://rust-cli.github.io/book/tutorial/testing.html)
- [https://doc.rust-lang.org/stable/std/fs/fn.write.html](https://doc.rust-lang.org/stable/std/fs/fn.write.html)
- [https://serde.rs/](https://serde.rs/)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces)
- [https://www.rfc-editor.org/info/rfc8259/](https://www.rfc-editor.org/info/rfc8259/)
- [https://rust-cli.github.io/book/tutorial/testing.html](https://rust-cli.github.io/book/tutorial/testing.html)
- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://docs.rs/csv/latest/csv/struct.Writer.html](https://docs.rs/csv/latest/csv/struct.Writer.html)
- [https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html](https://docs.rs/serde-csv-core/latest/serde_csv_core/struct.Writer.html)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://docs.rs/csv/latest/csv/struct.Writer.html](https://docs.rs/csv/latest/csv/struct.Writer.html)
- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://rust-cli.github.io/book/tutorial/testing.html](https://rust-cli.github.io/book/tutorial/testing.html)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs)
- [https://docs.rs/csv/latest/csv/struct.Writer.html](https://docs.rs/csv/latest/csv/struct.Writer.html)
- [https://owasp.org/www-community/attacks/CSV_Injection](https://owasp.org/www-community/attacks/CSV_Injection)
- [https://doc.rust-lang.org/stable/std/fs/fn.write.html](https://doc.rust-lang.org/stable/std/fs/fn.write.html)
- [https://serde.rs/data-format.html](https://serde.rs/data-format.html)
- [https://releases.rs/](https://releases.rs/)
- [https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs)
- [https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml)
- [https://forge.rust-lang.org/release/platform-support.html](https://forge.rust-lang.org/release/platform-support.html)
- [https://kopass.app/tool/crates/serde](https://kopass.app/tool/crates/serde)
- [https://releasealert.dev/cratesio/serde](https://releasealert.dev/cratesio/serde)
- [https://releasealert.dev/cratesio/serde](https://releasealert.dev/cratesio/serde)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://github.com/sharkdp/hyperfine](https://github.com/sharkdp/hyperfine)
- [https://releases.rs/](https://releases.rs/)
- [https://serde.rs/](https://serde.rs/)
- [https://serde.rs/json.html](https://serde.rs/json.html)
- [https://serde.rs/data-format.html](https://serde.rs/data-format.html)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs)
- [https://www.rfc-editor.org/info/rfc8259/](https://www.rfc-editor.org/info/rfc8259/)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://releases.rs/](https://releases.rs/)
- [https://rust-cli.github.io/book/tutorial/output.html](https://rust-cli.github.io/book/tutorial/output.html)
- [https://rust-cli.github.io/book/tutorial/testing.html](https://rust-cli.github.io/book/tutorial/testing.html)
- [https://rust-cli.github.io/book/in-depth/machine-communication.html](https://rust-cli.github.io/book/in-depth/machine-communication.html)
- [https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html](https://doc.rust-lang.org/nightly/cargo/commands/cargo-metadata.html)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://forge.rust-lang.org/release/platform-support.html](https://forge.rust-lang.org/release/platform-support.html)
- [https://doc.rust-lang.org/stable/std/fs/fn.write.html](https://doc.rust-lang.org/stable/std/fs/fn.write.html)
- [https://www.rfc-editor.org/info/rfc8259/](https://www.rfc-editor.org/info/rfc8259/)
- [https://www.rfc-editor.org/info/rfc4180/](https://www.rfc-editor.org/info/rfc4180/)
- [https://github.github.com/gfm/?ref=scriptorium](https://github.github.com/gfm/?ref=scriptorium)
- [https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces](https://www.gnu.org/prep/standards/html_node/Command_002dLine-Interfaces)
- [https://www.gnu.org/prep/standards/html_node/Option-Table.html](https://www.gnu.org/prep/standards/html_node/Option-Table.html)
- [https://owasp.org/www-community/attacks/CSV_Injection](https://owasp.org/www-community/attacks/CSV_Injection)
- [https://serde.rs/](https://serde.rs/)
- [https://serde.rs/json.html](https://serde.rs/json.html)
- [https://serde.rs/data-format.html](https://serde.rs/data-format.html)
- [https://docs.rs/crate/serde_json/latest](https://docs.rs/crate/serde_json/latest)
- [https://docs.rs/csv/latest/csv/struct.Writer.html](https://docs.rs/csv/latest/csv/struct.Writer.html)
- [https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool](https://docs.rs/csv/latest/csv/struct.WriterBuilder.html?search=u32+-%3E+bool)
- [https://docs.rs/clap/latest/clap/struct.Arg.html](https://docs.rs/clap/latest/clap/struct.Arg.html)
- [https://github.com/sharkdp/hyperfine](https://github.com/sharkdp/hyperfine)
- [https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml](https://github.com/sharkdp/hyperfine/blob/master/Cargo.toml)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/mod.rs)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/csv.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/csv.rs)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/markdown.rs)
- [https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs](https://github.com/sharkdp/hyperfine/blob/master/src/export/json.rs)
- [https://github.com/BurntSushi/ripgrep/discussions/3404](https://github.com/BurntSushi/ripgrep/discussions/3404)
- [https://github.com/BurntSushi/ripgrep/discussions/1592](https://github.com/BurntSushi/ripgrep/discussions/1592)
- [https://releasealert.dev/cratesio/serde](https://releasealert.dev/cratesio/serde)
- [https://kopass.app/tool/crates/serde](https://kopass.app/tool/crates/serde)
- [https://crates.io/api/v1/crates/serde](https://crates.io/api/v1/crates/serde)
- [https://crates.io/api/v1/crates/serde_json](https://crates.io/api/v1/crates/serde_json)
