# R66 — output-format-surface (bundle, deep) — Opus raw report

Retrieval date for every figure and claim in this report: **2026-09-10**, unless a
different date is stated on the line. Pinned source repositories are private and
return HTTP 404 from the network, so they are cited as `<repo>@<commit>:<path>:<line>`
read through `git show`, never by URL.

Pins used: `py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`
(short `b08bccfb`); `ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
(short `cb1cbcb2`). Two ancestor commits of the py pin are also cited, and are
labelled as ancestors every time they appear: `fda272d` ("feat(cli): add gh-style
pylb CLI with core library layer", 2026-06-09) and `f587e48` ("refactor: remove
legacy py-projects CLI and collapse command_name identity (#388)").

### Landscape

**The category this item decides.** Not "a table library". The category is the
**CLI result-output surface**: (a) the set of text serializations a command can
emit for one in-memory result value, (b) the two orthogonal flags that select
*which* serialization and *where* it goes, and (c) the rendering architecture that
makes adding a serialization cheap. Rust has no single crate for this category —
it is assembled from a data-model layer, one crate per non-trivial serialization,
and hand-written code for the trivial ones. Every candidate below was placed in a
bin before any figure was collected.

**Bin 1 — built-in or first-party toolchain.** Rust ships no output-format
framework. The first-party material is `std::fmt::Write` / `std::io::Write`,
`std::fs::File`, and `format!`/`write!`. This bin is a real competitor, not a
placeholder: a GitHub-Flavored-Markdown table is about 15 lines of `write!` over a
columns/rows contract, and `sharkdp/hyperfine` — 28,832 stars, not archived,
`GET https://api.github.com/repos/sharkdp/hyperfine` — ships exactly that,
hand-rolling Markdown, AsciiDoc and Org-mode behind one `MarkupExporter` trait
(`src/export/markdown.rs`, `src/export/markup.rs`,
https://raw.githubusercontent.com/sharkdp/hyperfine/master/src/export/markdown.rs)
while using crates only for JSON and CSV
(https://raw.githubusercontent.com/sharkdp/hyperfine/master/Cargo.toml — `csv = "1.3"`,
`serde`, `serde_json`, and no table or Markdown crate at all). Rust's own toolchain
follows the same split: `cargo --message-format json` is `serde_json`, and rustc's
diagnostics are hand-written renderers.

**Bin 2 — established industry standard.** `serde` + `serde_json` (JSON), `csv`
(BurntSushi, RFC 4180), `tabled` and `comfy-table` (aligned terminal tables),
`tempfile` (atomic file replacement). Also considered and binned here but not
shortlisted: `serde_yaml` (crates.io max stable `0.9.34+deprecated`, last release
2024-03-25 — the version string is the maintainer's own deprecation marker;
`GET https://crates.io/api/v1/crates/serde_yaml/versions`), and `prettytable-rs`
(last release `0.10.0`, 2022-12-27, `GET https://crates.io/api/v1/crates/prettytable-rs/versions`).

**Bin 3 — up-and-comer.** `sonic-rs` (0.5.8; 2,192,000 90-day downloads),
`simd-json` (0.18.1; 5,609,712), `cli-table` (0.5.0; 1,072,536), `nu-table`
(0.115.1; 77,186), `term-table` (1.4.0; 143,343), `csv-async` (1.3.1; 1,385,737) —
all from `GET https://crates.io/api/v1/crates/<name>`, `crate.recent_downloads` and
`crate.max_stable_version`. None is shortlisted: the SIMD JSON crates trade `unsafe`
and CPU-feature detection for throughput this workload does not need (see the
workload paragraph in `### Principles and implementation`), and the newer table
crates have neither the adoption nor the ANSI-width handling that R85's terminal
niceties will require.

**Authorities used, and why each is authoritative.**

| Source | Why it is an authority here | Retrieved |
|---|---|---|
| `cli-design-standard.md` v1.4.14, `/Users/stevemorin/c/cli-standards/cli-design-standard.md` | The owner's own normative CLI standard. Both source repos cite it by rule ID and are audited against it: ts's `D-016(2)`, `D-018(4)`, `D-033` and py's `docs/design/0001` derive from it. It is binding, not advisory. | 2026-09-10 |
| py `docs/design/0001-plbp-cli-conventions.md` and `docs/adr/0003-keep-markdown-output-mode.md` (`py@b08bccfb`) | The owner's recorded requirements and decision for this exact surface, written by the maintainer. Primary evidence of intent, not inference. | 2026-09-10 |
| Rust release blog, https://blog.rust-lang.org/ | Rust project publication; fixes the stable-version arithmetic the MSRV parameter depends on. 1.98.0 released 2026-08-20, 1.97.0 on 2026-07-09, 1.96.0 on 2026-05-28. | 2026-09-10 |
| `https://static.rust-lang.org/dist/channel-rust-stable.toml` | The toolchain's own release manifest: `version = "1.98.1 (48a229cea 2026-09-01)"`, `date = "2026-09-03"`. Authoritative for "current stable". | 2026-09-10 |
| RFC 4180 (IETF), https://www.rfc-editor.org/rfc/rfc4180 | The CSV interchange specification the `csv` crate and ts's hand-rolled quoting both target. | 2026-09-10 |
| GitHub Flavored Markdown Spec, tables extension, https://github.github.com/gfm/#tables-extension- | The concrete dialect py's Markdown mode targets ("GitHub-flavored table", ADR 0003). Defines that a literal `|` inside a cell must be backslash-escaped. | 2026-09-10 |
| clig.dev, https://clig.dev/ | Widely cited independent CLI guidance; py's `cli/output.py` module docstring cites it by name for the stdout/stderr split. | 2026-09-10 |
| Maintainer documentation: docs.rs/clap, tabled README, comfy-table README, csv/csv-core source | The maintainers' own statements about behavior, MSRV posture and defaults. | 2026-09-10 |
| 2025 State of Rust Survey Results, https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/ | Rust project's annual survey. Consulted; see the limitation recorded in `Method notes` under `### Sources`. | 2026-09-10 |

A single blog post was not used as an authority anywhere in this report.

**Practice evidence — well-regarded projects surveyed, with the evidence that they
are well regarded.** All star counts, `archived` and `pushed_at` from
`GET https://api.github.com/repos/<o>/<r>`, retrieved 2026-09-10.

| Project | Evidence it is well regarded | What it does for this category |
|---|---|---|
| `nushell/nushell` | 40,472 stars; not archived; `pushed_at` 2026-09-10 (same day) | Renders every table through `tabled`, configured `default-features = false, features = ["ansi"]` (https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-table/Cargo.toml line 24; workspace pin `tabled = { version = "0.21", default-features = false }`, root `Cargo.toml` line 266). A shell whose entire premise is structured output is the strongest possible reference for a terminal table renderer. |
| `sharkdp/hyperfine` | 28,832 stars; not archived; `pushed_at` 2026-04-30 | Decides the *same question this item decides*: which export formats a CLI offers. Ships JSON (`serde_json`), CSV (`csv` crate), and hand-rolled Markdown/AsciiDoc/Org-mode behind one exporter trait. |
| `BurntSushi/ripgrep` | 68,148 stars; not archived; `pushed_at` 2026-08-04 | The `csv` crate's maintainer is ripgrep's author; ripgrep's `--json` mode is `serde`-based. Establishes maintainer standing for `csv`. |
| `Nukesor/pueue` | 6,325 stars; not archived; `pushed_at` 2026-09-09 | Uses `comfy-table = "7"` (https://raw.githubusercontent.com/Nukesor/pueue/main/pueue/Cargo.toml line 32). Weighted down as adoption evidence: pueue and comfy-table share one author, so this is self-adoption, not independent uptake. |
| `cargo` (rust-lang) | The Rust toolchain's own build tool | `--message-format json` is `serde_json`; first-party precedent that machine output is a serde serialization, not a bespoke writer. |

**Fit, not abstract best.** The template is CLI + library + web service (spec §4 D7).
That shapes two constraints the "best table crate" question would miss. First, the
renderer must live in a crate the web tier does not have to link: JSON is shared with
the HTTP layer, but Markdown/CSV/aligned-text are CLI-only, so the format enum and
its renderers belong to the CLI crate and the `Serialize` derives belong to the
library crate. Second, R85 will later layer OSC-8 hyperlinks and relative timestamps
onto text-mode cells, which means the text renderer must measure display width with
ANSI escapes present — the single hardest requirement in this item, and the one that
eliminates hand-rolled column alignment.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

The shared principle is not "offer three formats". It is:

> **One result value, rendered through one format-selection surface, where the
> *format* and the *destination* are independent, explicitly-selected, and never
> inferred from the environment.**

Source and agreement level, in descending strength:

1. **Policy (must agree across all three repos, verbatim flag names).** The owner's
   `cli-design-standard.md` v1.4.14 makes this a MUST twice:
   - **R4.2 (MUST)** — "For commands that emit formatted result data, `-o`/`--output`
     **MUST** be the canonical output-format selector, with an extensible enum…
     `--json` **MUST** behave identically to `-o json`" (line 256).
   - **R3.2 (SHOULD-titled, MUST-bodied)** — "A destination-file option, if a command
     has one, **MUST** be a distinct flag — **`--output-file`, long form only** (no
     short flag, to avoid an `-o`/`-O` case collision) — **MUST NOT** reuse
     `--output`/`-o` (which selects *format*, R4.1), and **MUST** honor `-` as
     stdout" (line 194). Its ❌ example is `acme report build -o -`.
   Note an identifier collision that must not be conflated: py's *own* internal spec
   `docs/design/0001-plbp-cli-conventions.md` also numbers rules `R3.2`/`R4.2`, with
   different content. In this report, a bare `R#.#` means the org standard; py's are
   written `design 0001 R#.#`.
2. **Capability (must agree that it exists; the list may extend).** A stable machine
   format plus its ergonomic alias. F292 `--json` shorthand is already
   `COMMON → REUSE`, and R4.2 fixes what it must mean.
3. **Architectural pattern (shared, and it holds in Rust).** Both sources render every
   command's result through one renderer over one result contract. py:
   `CLIResult.table_title()/table_columns()/table_rows()/table_rows_rich()/human_note()`
   (`py@b08bccfb:src/py_launch_blueprint/core/models.py:47-72`) consumed by a single
   `Renderer` (`py@b08bccfb:src/py_launch_blueprint/cli/output.py:118`). ts: a pure
   `formatOutput(projects, format)` (`ts@cb1cbcb2:src/lib/format.ts:31`). py's ADR 0003
   states the pattern's payoff explicitly: "every command renders through one
   `Renderer` and one result model… which is what makes the third format free"
   (`py@b08bccfb:docs/adr/0003-keep-markdown-output-mode.md`).
4. **Stream policy (must agree).** Results to stdout, diagnostics to stderr, machine
   output uncontaminated — R7.1/R7.2, py's `output.py` module docstring citing
   clig.dev, py design 0001 R2.3.
5. **No TTY-driven format switching (must agree).** R7.3: "TTY state **MUST NOT**
   change the selected output *format*". py design 0001 R3.3 says the same.

**What may vary by ecosystem.** The rendering libraries; the exact glyphs of the
human table; whether the optional machine formats `yaml`/`jsonl`/`name` are offered;
the mechanism for atomic file replacement. These are implementation, not agreement.

**Essential behaviors and observable acceptance criteria.** Each is executable
against the built binary; none has been run (no Rust code exists — see
`### Validation strategy`).

| # | Behavior | Observable criterion |
|---|---|---|
| A1 | Format selector is `-o`/`--output` | `cmd -o json` and `cmd --output json` emit identical bytes |
| A2 | `--json` is exactly the alias | `cmd --json` byte-identical to `cmd -o json` |
| A3 | Alias conflict is a usage error | `cmd --json -o csv` → exit 2, message names both flags, stdout empty |
| A4 | Destination is orthogonal | `cmd -o json --output-file f` → `f` holds the same bytes stdout would have; stdout empty |
| A5 | `-` is stdout | `cmd -o csv --output-file -` writes CSV to stdout |
| A6 | Format is TTY-independent | `cmd -o text` under a pty and `cmd -o text \| cat` produce the same *format* (styling may differ) |
| A7 | Enum is closed | `cmd -o xml` → exit 2, error lists the valid values |
| A8 | Machine output is uncontaminated | `cmd -o json 2>/dev/null \| jq -e .` succeeds while a warning is being emitted |
| A9 | Separator safety | a cell containing `\|`, `,`, `"` and a newline round-trips: Markdown escapes `\|`; CSV quotes per RFC 4180; JSON escapes per JSON |
| A10 | Destination write is atomic and silent-overwrite | an existing target is replaced; a crash mid-render leaves the old file intact |

**Architectural alternatives, compared before any library was chosen.**

- **ALT-1 — Serde-only: every format is a `serde::Serializer`.** Elegant on paper:
  `serde_json`, `csv` (via `serde`), and a Markdown `Serializer`. Rejected. A serde
  `Serializer` is driven by the *type's* shape, but a Markdown or aligned-text table
  is driven by a *presentation* shape (column order, headers, human-formatted
  timestamps) that deliberately differs from the wire shape. py already encodes this
  split — `table_rows()` returns display strings while `model_dump_json()` returns the
  wire model — and `table_rows_rich()` adds a third, terminal-only shape
  (`py@b08bccfb:src/py_launch_blueprint/core/models.py:59`, ADR 0010). Forcing all
  three through one serde impl would collapse a distinction the sources found they
  needed.
- **ALT-2 — Presentation-crate-for-everything: one table crate renders text *and*
  Markdown.** Both shortlisted table crates offer it: `tabled`'s
  `Style::markdown()` (tabled 0.22.0 `src/settings/style/builder.rs:205-214`) and
  `comfy-table`'s `ASCII_MARKDOWN` preset
  (https://raw.githubusercontent.com/Nukesor/comfy-table/main/src/style/presets.rs:114).
  **Rejected on verified evidence.** I downloaded `tabled 0.22.0` from
  `GET https://crates.io/api/v1/crates/tabled/0.22.0/download` and grepped its whole
  `src/` for pipe escaping: `grep -rn 'replace("|"' tabled-0.22.0/src/` returns
  nothing. `Style::markdown()` emits a cell's `|` literally, which silently breaks the
  table for any consumer, violating A9. Beyond the bug, the coupling is wrong in kind:
  Markdown is an *interchange* serialization whose bytes downstream tooling depends on,
  while a table crate's output is explicitly presentation that may change — `tabled`'s
  own README says "We often do breaking changes on minor version bump… better to depend
  on constant version e.g. `=0.8.0`"
  (https://raw.githubusercontent.com/zhiburt/tabled/master/README.md, MSRV/semver
  section). Binding a stable output contract to that is a defect waiting to happen.
- **ALT-3 (recommended) — an exporter seam: one result contract, one renderer per
  format, crates only where the format is genuinely hard.** JSON → `serde_json`
  (escaping and number formatting are hard). CSV → `csv` (RFC 4180 quoting, embedded
  newlines, terminators are hard). Aligned text → `tabled` (Unicode width segmentation
  and ANSI-aware width are hard, and R85 will make them harder). Markdown → ~15 lines
  of `write!` with one `|` escape (genuinely easy, and pinning it to our own code makes
  its bytes ours). This is precisely hyperfine's shape, and it is what py converged on
  after its rewrite. It also satisfies ADR 0003's "third format is free" claim, because
  the marginal cost of a format is one `fn render(&self, result: &dyn CliResult, w: &mut dyn Write)`.

**The other half of the MEDIUM question: must `markdown` and `csv` stay strictly plain
once R85 decorates the text format?** Yes at the shared contract, and py has already run
this experiment. Its renderer feeds `table_rows()` — plain cells — to `_to_markdown`
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:242,253`), while `_render_text` feeds
`table_rows_rich()` — cells carrying markup — to the table
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:237`, ADR 0010). So the rich variant
is consumed by exactly one renderer, and the other formats read the plain rows. Rust
should keep that asymmetry: `rows_rich()` may carry ANSI and OSC-8, and `rows()` must
stay free of escape sequences, because an OSC-8 hyperlink inside a CSV field or a Markdown
cell is corruption in both formats. CSV is plain by nature — RFC 4180 has no markup layer.
Markdown *could* carry an equivalent (`[name](url)` where the text format emits OSC-8), and
that is a defensible future feature, but it is a **third** accessor (`rows_markdown()`),
not a change to `rows()`, and the call belongs to R85 rather than here: this item fixes
only that the Markdown renderer reads the plain rows today, so R85 can add a variant
without rewriting anything.

**Workload, and why performance does not select anything here.** The result set is
capped by `--limit`, default **200** rows in both sources
(`py@b08bccfb:src/py_launch_blueprint/cli/commands/projects.py:56-60`,
`default=200`; `ts@cb1cbcb2:src/lib/api.ts:23`, `export const DEFAULT_LIMIT = 200;`),
over 2 display columns. At 200 rows the serialization cost of every candidate is
microseconds and is dominated by one network round trip and by process startup.
**I ran no benchmark** and therefore assert no latency, throughput or allocation
figure for any candidate; the honest statement is that this workload cannot
discriminate between them, which is exactly why the SIMD JSON crates in bin 3 buy
nothing here. The resource cost that *does* matter is compile time and binary size,
addressed qualitatively per member under `Tradeoffs`, and measured in P03.

**The evidence that resolves the two HIGH questions — a version skew, not a design
disagreement.**

The ledger records F291/F293 as two repos independently choosing differently.
Reading the pinned repositories plus the py ancestor commits shows something else.
The legacy py CLI, at the ancestor commit `f587e48^` (the parent of "refactor: remove
legacy py-projects CLI…", an ancestor of the py pin), declared:

```
@click.option("--format", type=click.Choice(["text", "json", "csv"]), default="text", help="Output format")
@click.option("--copy", is_flag=True, help="Copy results to clipboard")
@click.option("--output", type=click.Path(), help="Write results to file")
```

(`py@f587e48^:src/py_launch_blueprint/projects.py:324-330`.) That is ts's surface
exactly — `--format` with `text|json|csv`, `--output` as the file sink, and `--copy`
beside it. ts's `src/lib/format.ts` names its source in its own header comment: "port
of format_output (projects.py:273-291)" (`ts@cb1cbcb2:src/lib/format.ts:1`). ts is a
faithful port of the *pre-rewrite* py CLI.

py then rewrote its CLI (ancestor `fda272d`, "feat(cli): add gh-style pylb CLI with
core library layer", 2026-06-09) and changed both things deliberately and on the
record:

- **The rename was directed, with a stated reason.** py's design spec, Appendix D
  ("Migration notes"), item 2: "Rename the format flag usage so `--output`/`-o` is the
  format and `--output-file` is the destination (current code uses `--format` for type
  and `--output` for a file path — **resolve before it spreads across tools**)"
  (`py@b08bccfb:docs/design/0001-plbp-cli-conventions.md:212-214`). The parenthetical
  describes ts's present shape, and the clause after the dash is the reason: stop it
  spreading to other tools. It then spread to ts anyway.
- **The third format has a recorded rationale.** ADR 0003, "Keep `markdown` as a third
  output format (spec deviation)", Accepted 2026-06-09, deciders "maintainer
  (interactive), implemented in PR #378": Markdown renders "any result model as a
  GitHub-flavored table — useful for pasting into issues/PRs and cheap to maintain
  because every command renders through one `Renderer` and one result model." Its
  rejected alternative is stated too: "Strict spec compliance (drop markdown) —
  rejected: removing a shipped, zero-marginal-cost format to satisfy a list the spec
  can simply note" (`py@b08bccfb:docs/adr/0003-keep-markdown-output-mode.md`).

Against that, ts's `D-033` never adjudicated the flag names. The naming appears as the
final sentence of the "Why" for a decision whose subject is prompt-cancellation exit
codes: "`--output` remains the file sink (source parity; documented divergence from
cli-standards' `-o` output-format enum, noted in EXAMPLECLI)"
(`ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:399`). Its Options list (line 397) offers
three prompt-cancellation options and no flag-naming option at all. So `D-033` is a
carried-forward parity note, not an adjudication — and the parity is with a py version
that had already been superseded when `D-033` was written.

**Therefore:** the divergence is stale-port drift of exactly the kind the ledger
already recognises at F265 ("ts ported an older, pre-refactor flat py CLI shape…a
stale-port gap"), not a genuine design disagreement, and the surviving design (py's)
is the one the org standard makes mandatory. This inverts the recommendation currently
recorded in `docs/port/DIVERGENCE-ANALYSIS.md:207` ("none — inherit ts's
already-adjudicated split"). Two baseline reviews follow.

BASELINE-REVIEW: F293 — format selection and destination are orthogonal, and their flag names are org policy (cli-design-standard v1.4.14 R4.2 MUST and R3.2 MUST) rather than per-repo preference — change the recorded target from "inherit ts's already-adjudicated split (`--format` selects, `--output` redirects)" to py's split (`-o`/`--output` selects format; `--output-file`, long-only, redirects; `-` means stdout), and reclassify ts's shape as stale-port drift (the F265 class) rather than a deliberate adjudicated divergence — evidence: `cli-design-standard.md` v1.4.14 R3.2 line 194 ("MUST NOT reuse `--output`/`-o`… MUST honor `-` as stdout") and R4.2 line 256; py `docs/design/0001-plbp-cli-conventions.md:212-214` directing the rename "before it spreads across tools"; the legacy py CLI at ancestor `f587e48^:src/py_launch_blueprint/projects.py:324-330` showing ts's surface is pre-rewrite py; `ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:397-399` showing D-033's Options list contains no flag-naming option. Affected items: R66 (F293, this item), R60 (declares the flags), R85 (reads the text row shape). Affected records: `docs/port/COMMONALITY.md:297`, `docs/port/DIVERGENCE-ANALYSIS.md:205,207`.

BASELINE-REVIEW: F291 — the third format is a recorded owner decision, not an unexplained pick — change "no recorded reason; each repo picked a different 3rd format for a different use case… — inferred" to cite py `docs/adr/0003-keep-markdown-output-mode.md` (Accepted 2026-06-09) for `markdown`, and record that ts's `csv` is the legacy py CLI's `csv` carried through the port rather than an independent choice — evidence: ADR 0003 verbatim ("useful for pasting into issues/PRs and cheap to maintain because every command renders through one Renderer and one result model"; rejected alternative "Strict spec compliance (drop markdown)"); legacy py `f587e48^:src/py_launch_blueprint/projects.py:325` (`click.Choice(["text","json","csv"])`); `ts@cb1cbcb2:src/lib/format.ts:1` naming `format_output (projects.py:273-291)` as its source. Affected items: R66 (F291, this item). Affected records: `docs/port/COMMONALITY.md:295`, `docs/port/DIVERGENCE-ANALYSIS.md:206`.

**A third divergence the ledger does not record at all.** F291 treats `text` as
common to both repos. It is not the same format. py's `text` is an aligned table with
headers and a title (`py@b08bccfb:src/py_launch_blueprint/cli/output.py:224-238`,
`rich.Table` with `add_column`/`add_row`). ts's `text` is bare identifiers, one per
line: `return projects.map((project) => project.id).join('\n');`
(`ts@cb1cbcb2:src/lib/format.ts:38`), with the reason in its own header comment: "text
-> newline-joined project IDs (not names — shell composability)"
(`ts@cb1cbcb2:src/lib/format.ts:8`). Under the org standard these are two different
things: py's is the human `table` format, which "MAY change between releases" (R7.2),
while ts's is the machine format `name` — "bare identifiers, one per line" (R4.2 line
257) — which MUST stay stable within a major version. I am not filing this as a third
BASELINE-REVIEW because it is inside this item's own scope to decide; it is handled in
`### Recommendation` and in the `Tradeoffs` of the `tabled` member.

**Where a different ecosystem needs a different design.** Only two places. (i) Python
gets `rich.Table` for free from a dependency it already has for color; Rust must pick
a table crate, and must pick one that measures ANSI-decorated width because R85 will
add OSC-8 hyperlinks — `nushell` demonstrates the exact configuration. (ii) Python's
`Path.open("w")` truncate-then-write is what py does
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:206`), and Node's
`writeFileSync(path, result)` is what ts does
(`ts@cb1cbcb2:src/commands/projects.ts:181-183`); both are non-atomic, and both leave a
truncated file if rendering fails midway. Rust should not copy that: the standard says
a destination-file option "**SHOULD** write atomically (temp + rename)"
(`cli-design-standard.md` line 226). This is a capability gap in both sources, not a
justified ecosystem difference.

**The low-priority question, answered from the standard rather than from either
source.** Neither source documents what happens when the target file exists; both
silently truncate (py `Path.open("w")`, line 206; ts `writeFileSync` with default
flags, which is `'w'`, line 181-183). The standard settles it, line 226: a destination
option "**SHOULD** write atomically (temp + rename) and **MAY** overwrite silently
(Unix `>` convention); offer `--no-clobber` to refuse an existing file." Recommendation:
silent overwrite (matching both sources' observed behavior and the shell convention),
performed atomically, with `--no-clobber` available and `--output-file -` meaning
stdout. Append is not offered: it produces a file containing two JSON documents or two
CSV headers, which violates A9's spirit and has no precedent in either source.

**The MEDIUM alias question.** `--json` stays, as F292 requires, and R4.2 fixes its
meaning to exactly `-o json`. What the framework must supply is (a) a closed enum-valued
option and (b) a boolean flag whose mutual exclusion is evaluated on *explicit presence*,
so that `--json` alone does not collide with `-o`'s default value. R60 owns the
framework choice; the capability exists in the obvious candidate: `clap`'s
`Arg::conflicts_with` documents "having both arguments present at runtime is an error"
(https://docs.rs/clap/latest/clap/builder/struct.Arg.html, `method.conflicts_with`),
which is presence-based, and `clap::ValueEnum` supplies the closed enum. On *which*
behavior to choose when both are given, the two sources disagree — ts errors
(`.conflicts('format')`, `ts@cb1cbcb2:src/commands/projects.ts:82`), py silently lets
`--json` win (`OutputMode.JSON if json_mode else OutputMode(output_mode or "text")`,
`py@b08bccfb:src/py_launch_blueprint/cli/options.py:126`). Recommend ts's behavior,
because the standard already fixes the pattern for a flag pair of this shape:
"`--paginate` and `--no-paginate` are mutually exclusive; using both **MUST** fail with
usage error `2`" (`cli-design-standard.md` line 553). Silent precedence hides a script
bug; exit 2 reports it.

**Minimal realistic example.** One `projects list` command over the same 200-row
result the sources use, exercising all four formats plus the file sink:

- `crates/lib`: `#[derive(Serialize)] struct Project { id: String, name: String }` and
  `#[derive(Serialize)] struct ProjectList { projects: Vec<Project> }` — the wire shape,
  reused by the web tier.
- `crates/cli`: `trait CliResult: erased_serde::Serialize` — or, avoiding a further
  crate, a `Render` enum wrapper — exposing `title()`, `columns() -> &[&str]`,
  `rows() -> Vec<Vec<String>>`, `rows_rich() -> Vec<Vec<String>>`, `note()`; plus
  `enum OutputFormat { Text, Json, Markdown, Csv }` deriving the framework's value-enum,
  and `struct Renderer { format: OutputFormat, dest: Destination, color: ColorChoice }`
  with `fn render(&self, r: &impl CliResult) -> io::Result<()>` dispatching to four
  private functions over a single `&mut dyn Write`.
- Destination is resolved once: `Stdout`, or `File(AtomicPath)` for `--output-file PATH`,
  or `Stdout` again for `--output-file -`.

The composition is deliberately one-way: the four renderers depend on the contract, the
contract depends on nothing, and no renderer knows the destination is a file. That is
what makes A4 true by construction rather than by a code path, and it is where py's
implementation is weakest — py duplicates its whole format `match` in `render()` and
again in `_render_to_file()` (`py@b08bccfb:src/py_launch_blueprint/cli/output.py:152-165`
and `:205-222`), two places that can drift.

**Executable acceptance check (proposed; not run).** See `### Validation strategy` for
the commands. Every check in the A1–A10 table is a `trycmd`/`assert_cmd` case except A10,
which needs a fault-injection test.

### Recommendation

**One stack.**

**Format enum — all four: `text` (default) · `json` · `markdown` · `csv`.** The answer
to "markdown, csv, both, or neither" is **both**. Neither format was ever rejected on
merit: py's `markdown` is an accepted ADR with a stated use case (paste into issues and
PRs), and ts's `csv` is the legacy py CLI's format, carried through a port, serving the
different use case of spreadsheet import. Dropping either deletes a shipped capability
from one of the two repos to no benefit, and ADR 0003's cost argument — one shared
columns/rows contract makes each additional format nearly free — is the same argument in
Rust, where it costs one `fn` plus one enum variant. R4.2 explicitly calls the enum
"extensible", so four members is conformant.

**Flag names — py's split, which is the org standard's mandated split.**
`-o`/`--output <text|json|markdown|csv>` selects the format (R4.2 MUST).
`--output-file <path>` — long form only, no short flag — selects the destination,
overwrites silently, writes atomically, honors `-` as stdout, and supports
`--no-clobber` (R3.2 MUST plus line 226 SHOULD). `--json` is exactly `-o json` (R4.2
MUST, F292), and `--json` given together with an explicit `-o <other>` exits 2 (the
`--paginate`/`--no-paginate` precedent, line 553). This is *not* "pick the source that
happens to match a standard": it is the shape the owner's spec directed py to adopt,
that py did adopt, and that ts diverged from by inheriting a superseded design.

**Crates.**

| Role | Crate | Version | Configuration |
|---|---|---|---|
| Data contract | `serde` | `1.0.229` | `features = ["derive"]`, in the library crate |
| `json` renderer | `serde_json` | `1.0.151` | default features |
| `csv` renderer | `csv` | `1.4.0` | default features; `WriterBuilder` defaults already match RFC 4180 minimal quoting |
| `text` renderer | `tabled` | `0.22.0`, pinned exactly | `default-features = false, features = ["ansi"]`, driven through `tabled::builder::Builder` |
| `--output-file` atomicity | `tempfile` | `3.27.0` | `NamedTempFile::persist` next to the target |
| `markdown` renderer | *(no crate)* | — | ~15 lines of `write!` over the columns/rows contract, escaping `\|` per GFM |

**What the recommendation deliberately does not do.** It does not add `yaml`, `jsonl`
or `wide`. It does not adopt a serde-`Serializer`-per-format architecture (ALT-1). It
does not let a table crate emit Markdown (ALT-2, rejected on a verified escaping
defect). It does not rename the default format from `text` to the standard's `table`:
`text` is the one spelling both sources already agree on, the R4.2 MUST is about the
*selector* and the enum is extensible, and a rename would break both repos' documented
invocations for a cosmetic gain. That deviation belongs in the template's conformance
note, with rule ID R4.2, this rationale, and the owner and date.

### Members

Figures in every member are from the endpoints named in the prompt's figure table,
retrieved **2026-09-10**: `GET https://crates.io/api/v1/crates/<name>`
(`crate.recent_downloads`, `crate.downloads`), `GET https://crates.io/api/v1/crates/<name>/versions`
(newest `yanked: false` — `num`, `created_at`, `rust_version`, `license`),
`GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`),
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`),
and `https://rustsec.org/packages/<name>.html`.

**How to read the advisory rows.** `https://rustsec.org/packages/<name>.html` returns
HTTP 404 for every one of the five recommended crates. I verified that 404 means "no
advisories" rather than "endpoint broken" by requesting two crates known to carry
advisories: `atty` returned HTTP 200 listing `RUSTSEC-2021-0145` and `RUSTSEC-2024-0375`,
and `time` returned HTTP 200 listing `RUSTSEC-2020-0071` and `RUSTSEC-2026-0009`. A 404
is therefore evidence of no recorded advisory.

**MSRV arithmetic used by gate 2, once, for all members.** Current stable is **1.98.1**,
released 2026-09-03 (`https://static.rust-lang.org/dist/channel-rust-stable.toml`:
`version = "1.98.1 (48a229cea 2026-09-01)"`, `date = "2026-09-03"`). The two preceding
minors are 1.97.0 (2026-07-09) and 1.96.0 (2026-05-28), per
https://blog.rust-lang.org/. "Stable minus 2 minor versions" therefore places the
template's MSRV floor at **1.96.0**. Edition 2024 independently requires ≥ 1.85.

#### serde

##### Landscape
Bin 2, established industry standard, and effectively unopposed: `serde` is the
data-model layer every other member in this stack talks to (`serde_json` and `csv` both
depend on `serde_core`). Bin 1 alternative — implementing `Display`/`ToString` by hand
per format and per type — was rejected because it puts the wire shape in the CLI crate
instead of the library crate, which the web tier also needs. Bin 3 has no contender: no
newer crate is trying to replace serde's derive-and-visitor model.

##### Principles and implementation
Realizes principle 3 (one result value, many renderings) at the type level: the library
crate derives `Serialize` on the domain types, giving the `json` renderer and the future
HTTP tier one shared wire shape, exactly as py's `CLIResult` subclasses are pydantic
`BaseModel`s serving both `model_dump_json()` and the web layer
(`py@b08bccfb:src/py_launch_blueprint/core/models.py:40`, and ADR 0013's thin-adapter
rule cited at `docs/port/DIVERGENCE-ANALYSIS.md` F018). Presentation shapes stay outside
serde, per ALT-1's rejection.

##### Dominant choice
`serde` — 299,833,252 downloads in 90 days; 1,375,514,004 all-time. Latest non-yanked
release `1.0.229`, 2026-07-18. Repository `serde-rs/serde`: 10,813 stars, `archived: false`,
`pushed_at` 2026-08-25. Open issues **319**
(`search/issues` `total_count`; the repo object's `open_issues_count` is 398 and was not
used, per the prompt's rule).
Maintenance: **active** — a release seven weeks before retrieval and a push two weeks
before it.

##### Qualified shortlist
None. There is no second crate at this layer that `serde_json` and `csv` can both consume.

##### Excluded by gate
None excluded. Recording the gate results explicitly:
1. **License** — `MIT OR Apache-2.0` (`versions[].license`). Pass, exactly matching the
   template parameter.
2. **MSRV** — declares `rust-version = 1.56`; its own tree (`serde_core 1.0.229`, also
   `rust-version = 1.56`) is within the 1.96.0 floor. Pass, declared, and CI tests
   `stable` and `beta` plus pinned older toolchains
   (https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml).
3. **Advisories** — none (rustsec 404, validated above). `unsafe` posture: **two** `unsafe`
   expressions in the published `serde-1.0.229/src`, both `str::from_utf8_unchecked` on
   bytes the crate itself just produced (`src/core/format.rs:16`,
   `src/core/ser/impls.rs:821`), verified by grepping the downloaded `.crate`. Not
   `#![forbid(unsafe_code)]`.
4. **OS matrix** — CI runs `ubuntu-latest` and `windows-latest`; **macOS is not in
   serde's CI matrix**. Judged pass on other evidence: both targets are rustc tier-1,
   the crate is `#![no_std]`-capable with no platform-specific code paths, and it is a
   transitive dependency of essentially every macOS Rust binary. Recorded as a caveat,
   not a hidden pass. Windows: covered.
5. **Default features / async coupling** — default features are `["std"]`; `derive` is
   opt-in and pulls the `serde_derive` proc-macro. No async runtime coupling of any kind.
6. **Binary size / compile time** — the `derive` feature adds a proc-macro to the build
   graph, which is the dominant compile-time cost in this stack; generated code is
   monomorphized per type and is small for two-field structs. No build was executed.

##### Up-and-comers
None applicable at this layer; `inapplicable` for the "newer challenger" question because
no crate is contesting it.

##### Fit for this template
Strong on all three surfaces. The CLI crate needs it for `-o json`; the library crate
needs it as the wire contract; the web tier needs the same derives for its response
bodies, which is exactly the "thin adapter over one contract" shape py's ADR 0013
records. This is also the member most likely to be *shared* rather than owned here — see
`Parameters`.

##### Recommendation
`serde = { version = "1.0.229", features = ["derive"] }` declared in the workspace root
and inherited, with the derives on the library crate's domain types, not on CLI
presentation types.

##### Ranked runner-up
None. If serde were unavailable, the fallback is bin 1: hand-written JSON emission, which
is a materially worse position (escaping, float formatting) and is not recommended at any
rank.

##### Tradeoffs
Cost: one proc-macro in the build graph and a monomorphization per type. Benefit: the
wire shape is written once and consumed by two renderers and the web tier. Risk: none
identified — the crate's compatibility record within `1.x` is the strongest in the
ecosystem. Responsiveness caveat: of the 10 most recently opened issues on
`serde-rs/serde` (numbers 3083–3100, opened 2026-07-15 to 2026-09-06), **zero** have a
comment from an OWNER/MEMBER/COLLABORATOR, so no median can be computed and the
unanswered count is 10/10. I record this as **not** an at-risk signal: this maintainer's
observed practice is to resolve by commit or close rather than by comment, and the
release and push dates contradict inattention. The metric measures comment behavior, not
maintenance.

##### Parameters
No parameter is registered to R66 (`owns:` is empty in `## Couplings`). The serde version
and feature set are a workspace-wide decision that R52 (`toml-crate`) and R53
(`config-schema-validation`) will also depend on; this item asserts only that the
`json` renderer requires `serde` with `derive`, and defers the pin to whichever item the
controller designates. No `CONFLICT:` line: no consumed parameter needs to change.

##### Migration implications
`crates/<name>-lib/src/models.rs` gains `#[derive(Serialize)]` on the result types. No
change to the CLI crate beyond consuming them.

##### Validation strategy
Proposed, not run: a snapshot test asserting the exact JSON bytes for a fixed two-row
`ProjectList`, so that a serde or field rename that changes the wire shape fails CI —
this is the R7.2 stability guarantee made testable.

##### Confidence & re-verify trigger
**High.** Re-verify if `serde` publishes a `2.0`, if `rust-version` rises above the
then-current floor, or if a RustSec advisory appears at
`https://rustsec.org/packages/serde.html`.

##### Sources
- `GET https://crates.io/api/v1/crates/serde` and `/versions` — 2026-09-10.
- `GET https://api.github.com/repos/serde-rs/serde`; `GET https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open` — 2026-09-10.
- https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml — 2026-09-10.
- `https://rustsec.org/packages/serde.html` → HTTP 404 — 2026-09-10.
- `serde-1.0.229.crate` from `GET https://crates.io/api/v1/crates/serde/1.0.229/download`, `unsafe` sites grepped locally — 2026-09-10.
- `py@b08bccfb:src/py_launch_blueprint/core/models.py:40` — 2026-09-10.

#### serde_json

##### Landscape
Bin 2, established industry standard, and the format-specific member with the strongest
first-party precedent: `cargo --message-format json` is `serde_json`. Bin 1 (hand-written
JSON) is rejected on escaping and float-formatting correctness. Bin 3 challengers
`sonic-rs` (0.5.8; 2,192,000 90-day downloads) and `simd-json` (0.18.1; 5,609,712) exist
and are real, but trade `unsafe` and runtime CPU-feature detection for throughput that a
200-row result cannot use.

##### Principles and implementation
Carries principle 2 (a stable machine format) and A8 (uncontaminated stdout). Both sources
already emit a structured error object on stderr in JSON mode — py builds
`{"error": {...}}` with `code`/`name`/`message` and append-only extras
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:277-293`), ts's `D-033` implements
`{"error":{code,message}}` — and the org standard requires it (R7.8). That envelope is
R67's contract; this member supplies the serializer both it and the result body use.

##### Dominant choice
`serde_json` — 303,746,516 downloads in 90 days; 1,279,419,710 all-time. Latest
non-yanked `1.0.151`, 2026-07-20. `serde-rs/json`: 5,636 stars, `archived: false`,
`pushed_at` 2026-08-08; open issues **190** (`search/issues` `total_count`). Maintenance:
**active**.

##### Qualified shortlist
`sonic-rs 0.5.8`, `simd-json 0.18.1` — both are maintained and would function, and both
are listed here rather than excluded because neither fails a gate outright. They lose on
fit, not on health.

##### Excluded by gate
None excluded. Gate results for `serde_json`:
1. **License** — `MIT OR Apache-2.0`. Pass.
2. **MSRV** — `rust-version = 1.71`, below the 1.96.0 floor; CI explicitly tests
   `1.71.0` and `1.85.0` alongside `stable`/`beta`
   (https://raw.githubusercontent.com/serde-rs/json/master/.github/workflows/ci.yml).
   Pass, declared and CI-tested.
3. **Advisories** — none (rustsec 404, validated). `unsafe`: 15 occurrences across
   `src/raw.rs`, `src/ser.rs`, `src/read.rs`, `src/value/mod.rs` in the published
   `serde_json-1.0.151`, grepped locally — a deliberate, reviewed performance surface,
   not incidental. Not `#![forbid(unsafe_code)]`.
4. **OS matrix** — CI runs `ubuntu` and `windows`; **macOS is not in the matrix**. Same
   judgment and same caveat as `serde`.
5. **Default features / async** — default `["std"]`; dependency tree is `serde_core`,
   `itoa`, `memchr`, `zmij` (float formatting), with `indexmap` optional for
   `preserve_order`. No async coupling.
6. **Binary size / compile time** — small tree, no proc-macro of its own, compiles fast.
   Not measured.

##### Up-and-comers
`sonic-rs`, `simd-json` (figures above). Both are legitimate up-and-comers for
high-throughput services; both are the wrong trade for a 200-row CLI result, and both
increase the `unsafe` surface that R06 (`unsafe-code-policy`, resolved) constrains.

##### Fit for this template
Strong. Shared with the web tier, which will serialize responses and R70's problem
envelope with the same crate.

##### Recommendation
`serde_json = "1.0.151"`, default features. Render with `to_writer_pretty` into the
resolved sink so the destination stays orthogonal (A4), and emit a trailing newline —
matching py, which writes `model_dump_json(indent=2)` via `click.echo` to stdout and
appends `"\n"` explicitly for the file path
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:158`, `:207`).

##### Ranked runner-up
1. `sonic-rs 0.5.8` — only if a future profile shows JSON serialization on a hot path.
2. `simd-json 0.18.1` — same condition, and it is primarily a parser rather than a writer.

##### Tradeoffs
Cost: nothing meaningful. Benefit: the ecosystem's reference implementation, shared
with the web tier. Responsiveness: of the 10 most recently opened issues on
`serde-rs/json` (1318–1336, 2026-03-13 to 2026-08-21), 2 received a maintainer comment
(median of those two: **5.66 days**), 8 unanswered. Same caveat as `serde` — this
maintainer resolves by commit, and the release cadence contradicts inattention.

##### Parameters
None owned. Shared with R69/R70's web tier; no `CONFLICT:`.

##### Migration implications
`crates/<name>-cli/src/output/json.rs` — one function, `to_writer_pretty` plus a newline.

##### Validation strategy
Proposed, not run: `cmd -o json | jq -e '.projects | length == 2'` in a CLI integration
test, plus the A2 byte-equality assertion against `cmd --json`.

##### Confidence & re-verify trigger
**High.** Re-verify on a `2.0`, on an MSRV rise past the floor, or on any advisory at
`https://rustsec.org/packages/serde_json.html`.

##### Sources
- `GET https://crates.io/api/v1/crates/serde_json` and `/versions` — 2026-09-10.
- `GET https://api.github.com/repos/serde-rs/json`; `.../search/issues?q=repo:serde-rs/json+is:issue+is:open` — 2026-09-10.
- https://raw.githubusercontent.com/serde-rs/json/master/.github/workflows/ci.yml — 2026-09-10.
- `https://rustsec.org/packages/serde_json.html` → HTTP 404 — 2026-09-10.
- `serde_json-1.0.151.crate`, `unsafe` sites and dependency list grepped locally — 2026-09-10.
- `py@b08bccfb:src/py_launch_blueprint/cli/output.py:158,207,277-293` — 2026-09-10.

#### csv

##### Landscape
Bin 2. The category "write RFC 4180 CSV" has one crate everyone uses and one credible
bin 1 alternative. Bin 1: hand-rolled quoting, which is what ts actually ships — a
six-line `csvField` applying "minimal RFC 4180 quoting" and a `join('\n')`
(`ts@cb1cbcb2:src/lib/format.ts:21-27,35-37`), explicitly described in its own header
as a "Deliberate divergence… the source's CSV was naive-by-design (no escaping,
projects.py:287-289)". Bin 3: `csv-async 1.3.1` (1,385,737 90-day downloads), which
solves a problem this template does not have.

##### Principles and implementation
Realizes A9 (separator safety) for the spreadsheet-import use case. The decisive detail
is that the crate's defaults already match ts's hand-rolled behavior, so adopting it is
not a behavior change: `csv-core`'s `WriterBuilder::new()` sets `delimiter: b','`,
`term: Terminator::Any(b'\n')`, `quote: b'"'`, `double_quote: true`, and
`style: QuoteStyle::default()`, whose documentation states "By default, this is set to
`QuoteStyle::Necessary`, which will only [quote when required]"
(https://raw.githubusercontent.com/BurntSushi/rust-csv/master/csv-core/src/writer.rs:19-32,
and the `quote_style` doc comment at line 90). LF terminator, minimal quoting — the same
bytes ts produces, except that the crate terminates the final record too.

##### Dominant choice
`csv` — 46,695,423 downloads in 90 days; 241,731,293 all-time; **3,303 reverse
dependencies** (`GET https://crates.io/api/v1/crates/csv/reverse_dependencies?per_page=1`,
`meta.total`). Latest non-yanked `1.4.0`, 2025-10-17. `BurntSushi/rust-csv`: 1,958 stars,
`archived: false`, `pushed_at` 2026-08-04; open issues **65**. Maintenance: **stable-quiet**
— the last release is 10.8 months before retrieval, which the rubric makes a trigger to
investigate, not a verdict. Investigated: the repository was pushed 5 weeks before
retrieval, the maintainer answered 4 of the 10 most recently opened issues with a median
first-response time of **0.01 days** (~15 minutes), and the crate's problem domain (a
2005 RFC) is genuinely finished. Not `at-risk`: no concrete adverse signal exists.

##### Qualified shortlist
Bin 1 hand-rolled RFC 4180 quoting (ts's actual implementation). It passes every gate
trivially — zero dependencies, no license, no MSRV, no advisory surface — and is a
legitimate choice. It loses on the edge cases a template should model correctly:
embedded CRLF inside a quoted field, a leading UTF-8 BOM for Excel, and the
`QuoteStyle` policy choice, all of which the crate has already made and tested.

##### Excluded by gate
None excluded. Gate results for `csv`:
1. **License** — `Unlicense/MIT` (`versions[].license`). Compatible with a
   `MIT OR Apache-2.0` distribution. Note for the license allow-list: this is
   MIT-or-public-domain, so it carries no Apache-2.0 patent grant; permissive and
   compatible, but a `cargo-deny` allow-list must name `Unlicense` explicitly.
2. **MSRV** — `rust-version = 1.73` on `1.4.0`, well below the 1.96.0 floor, and CI
   pins a `1.73.0` job named `pinned`
   (https://raw.githubusercontent.com/BurntSushi/rust-csv/master/.github/workflows/ci.yml:19-22).
   Pass, declared and CI-tested — the strongest MSRV posture of any member here.
3. **Advisories** — none (rustsec 404, validated). `unsafe`: **4** occurrences in
   `csv-1.4.0/src/string_record.rs` (lines 338, 561, 721, 742), all
   `str::from_utf8_unchecked` on bytes the crate has already UTF-8-validated. Not
   `#![forbid(unsafe_code)]`.
4. **OS matrix** — CI matrix includes `ubuntu-latest` (pinned 1.73, stable, beta,
   nightly), **`macos-latest`**, and both `windows-latest` MSVC and GNU targets
   (same CI file, lines 19-38). Full pass, the only member with macOS explicitly in CI.
5. **Default features / async** — dependencies are `csv-core`, `itoa`, `ryu`,
   `serde_core`; serde support is built in rather than feature-gated. No async coupling.
6. **Binary size / compile time** — four small dependencies, no proc-macro, negligible.
   Not measured.

##### Up-and-comers
`csv-async 1.3.1` (1,385,737 90-day downloads) — async CSV for streaming pipelines.
Inapplicable: this renderer writes a bounded in-memory result to a sync `Write`.

##### Fit for this template
Good, and narrow by design: CLI-only. The web tier has no CSV responsibility, so this
dependency belongs to the CLI crate and never reaches the library or web builds.

##### Recommendation
`csv = "1.4.0"`, default features, used through `WriterBuilder::new().from_writer(w)`
with the defaults unchanged, writing the same `columns()` header and `rows()` cells the
other renderers consume.

##### Ranked runner-up
1. Hand-rolled RFC 4180 quoting (bin 1) — choose this only if the template's dependency
   budget is a hard constraint; accept that BOM and CRLF handling become the template's
   own problem.
2. `csv-async` — only if streaming output is ever added.

##### Tradeoffs
Cost: four transitive crates and one more license (`Unlicense`) in the allow-list.
Benefit: RFC 4180 correctness the template does not have to own, from a maintainer whose
standing is established by `ripgrep` (68,148 stars). Risk: quiet release cadence, judged
above as finished rather than abandoned. Precedent: `hyperfine` depends on `csv = "1.3"`
for exactly this job (https://raw.githubusercontent.com/sharkdp/hyperfine/master/Cargo.toml).

##### Parameters
None owned. No `CONFLICT:`.

##### Migration implications
`crates/<name>-cli/src/output/csv.rs` — one function; `Cargo.toml` gains one dependency;
the license allow-list gains `Unlicense`.

##### Validation strategy
Proposed, not run: a test rendering a row whose name is `a,b"c` plus an embedded newline,
asserting the output re-parses to the same two fields with `csv::Reader`, and asserting
byte-equality against a committed fixture.

##### Confidence & re-verify trigger
**High.** Re-verify if no release appears by 2027-10-17 (24 months after 1.4.0's
2025-10-17 release) *and* open issues show unanswered correctness reports, or on any advisory at
`https://rustsec.org/packages/csv.html`.

##### Sources
- `GET https://crates.io/api/v1/crates/csv`, `/versions`, `/reverse_dependencies` — 2026-09-10.
- `GET https://api.github.com/repos/BurntSushi/rust-csv`; `.../search/issues?q=repo:BurntSushi/rust-csv+is:issue+is:open` — 2026-09-10.
- https://raw.githubusercontent.com/BurntSushi/rust-csv/master/.github/workflows/ci.yml — 2026-09-10.
- https://raw.githubusercontent.com/BurntSushi/rust-csv/master/csv-core/src/writer.rs — 2026-09-10.
- `https://rustsec.org/packages/csv.html` → HTTP 404 — 2026-09-10.
- `csv-1.4.0.crate`, `unsafe` sites and dependency list grepped locally — 2026-09-10.
- RFC 4180, https://www.rfc-editor.org/rfc/rfc4180 — 2026-09-10.
- `ts@cb1cbcb2:src/lib/format.ts:1-12,21-27,35-37` — 2026-09-10.

#### tabled

##### Landscape
Bin 2, and the only member where two crates genuinely compete. The category is
"render aligned columns to a terminal, correctly, with ANSI escapes present". Bin 1
(hand-rolled column widths with `format!("{:<width$}")`) fails on two counts that are
not cosmetic: Unicode display width (CJK, combining marks) and ANSI-decorated width,
which R85's OSC-8 hyperlinks will make mandatory. Bin 2 candidates: `tabled` and
`comfy-table`. Bin 3: `cli-table 0.5.0` (1,072,536 90-day downloads), `term-table 1.4.0`
(143,343), `nu-table 0.115.1` (77,186).

##### Principles and implementation
This member renders the default human format. Under R7.2 that output "MAY change between
releases", which is precisely why binding it to a fast-moving presentation crate is
acceptable here and unacceptable for Markdown or CSV. It also carries the shape R85 will
extend: py separates `table_rows()` (plain cells) from `table_rows_rich()` (cells with
markup), and lets the renderer strip styling for non-terminal destinations
(`py@b08bccfb:src/py_launch_blueprint/core/models.py:55,59` and
`src/py_launch_blueprint/cli/output.py:233-237`, ADR 0010). The Rust text renderer must
consume `rows_rich()` and must measure width with escapes present — which is exactly the
`ansi` feature.

##### Dominant choice
`tabled` — 8,665,708 downloads in 90 days; 38,341,382 all-time; 795 reverse dependencies.
Latest non-yanked `0.22.0`, **2026-09-05** (five days before retrieval).
`zhiburt/tabled`: 2,362 stars, `archived: false`, `pushed_at` 2026-09-05; open issues
**101**. Maintenance: **active** — a release and a push in the same week as retrieval,
and a maintainer first response on the most recent issue (#589) in 1.57 days.
Responsiveness: the recent window holds only 6 issues (#562–#589, 2025-11-23 to
2026-09-03); of those, 5 drew a maintainer reply with a **median of 1.57 days**, 1 is
unanswered, and one outlier (#567) waited 187.74 days.

The decisive evidence is not the download count but the reference adopter: **nushell**
(40,472 stars, pushed the day of retrieval) renders every table through `tabled`, and
does so in the exact configuration recommended below —
`tabled = { workspace = true, features = ["ansi"], default-features = false }`
(https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-table/Cargo.toml:24,
with the workspace pin `tabled = { version = "0.21", default-features = false }` at
https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml:266). A shell built
around structured output is the most demanding possible consumer of a table renderer.

##### Qualified shortlist
`comfy-table 8.0.0` — 17,898,556 downloads in 90 days (**more than `tabled`**);
97,436,789 all-time; 1,070 reverse dependencies; released 2026-08-05; `Nukesor/comfy-table`
1,391 stars, `archived: false`, `pushed_at` 2026-08-05; open issues **4**; responsiveness
median **2.29 days** with 1 of 8 unanswered — the cleanest issue tracker of any candidate.
It is a genuinely strong crate and loses on three specific points, not on quality:
(i) **neither crate declares a `rust-version`**, so the MSRV comparison is between two
stated policies rather than between a declaration and a gap — comfy-table's README commits
to tracking current stable ("Comfy-table is written for the current `stable` Rust version.
Older Rust versions may work but aren't officially supported",
https://raw.githubusercontent.com/Nukesor/comfy-table/main/README.md:52-53) while tabled's
commits to treating an MSRV raise as a breaking change; the former is in more direct
tension with a stable-minus-two parameter, but neither posture is satisfactory and both
need the same compensating CI job, so this is the weakest of the three points;
(ii) its default feature is `tty`, which pulls `crossterm 0.29` — a full terminal-control
library — into a build that only needs to measure widths
(https://raw.githubusercontent.com/Nukesor/comfy-table/main/Cargo.toml, `[features]`
and the per-target `crossterm` dependencies); and (iii) its most prominent adopter,
`pueue`, shares its author, so the adoption evidence is weaker than nushell's.

##### Excluded by gate
- **`prettytable-rs 0.10.0`** — gate 5/maintenance: last release **2022-12-27**, ~3.7
  years before retrieval (`GET https://crates.io/api/v1/crates/prettytable-rs/versions`).
  Rubric verdict **dormant** is not asserted without a concrete signal, so the accurate
  verdict is **at-risk on cadence**; either way it is excluded in favor of two actively
  released alternatives. Its `BSD-3-Clause` license is permissive and would pass gate 1;
  the exclusion rests on cadence, not license.
- **`markdown-table 0.2.0`** — last release 2023-06-29; **263** downloads in 90 days
  (`GET https://crates.io/api/v1/crates/markdown-table`). Excluded on adoption and
  cadence. Listed because it is the crate a search for "markdown table crate" surfaces;
  it is not a serious candidate, and the recommendation hand-rolls Markdown regardless.

Gate results for the recommended `tabled 0.22.0`:
1. **License** — `MIT` (crates.io `versions[].license`), as are `papergrid 0.18.0` and
   `tabled_derive 0.12.0`. Compatible with `MIT OR Apache-2.0` distribution, but MIT-only:
   **no Apache-2.0 patent grant**. This is the one substantive license note in the stack
   and belongs in the conformance/allow-list record.
2. **MSRV** — **declares no `rust-version`** (`versions[].rust_version` is `null` for
   `tabled`, `papergrid` and `tabled_derive`); the README's MSRV section says only
   "Breaking MSRV considered to be a breaking change" without naming a version. **Partial
   fail**: the crate's actual MSRV is almost certainly far below 1.96.0 (its edition is
   2018), so the *floor* is met, but the *declared and CI-tested* half of the parameter is
   not met by the dependency. Mitigation, required: the template's own CI MSRV job plus a
   committed `Cargo.lock` detects any drift on upgrade. This is the only gate any
   recommended member does not pass cleanly.
3. **Advisories** — none (rustsec 404, validated). `unsafe`: `grep -rn 'unsafe fn|unsafe {'`
   over the published `tabled-0.22.0/src` returns **nothing**; the single textual match for
   `unsafe` is a doc comment in `src/builder/table_builder.rs:82`. Effectively zero `unsafe`.
4. **OS matrix** — CI matrix is `[ubuntu-latest, windows-latest, macos-latest]` × `[stable, nightly]`
   (https://raw.githubusercontent.com/zhiburt/tabled/master/.github/workflows/ci.yml:17-19,32).
   Full pass.
5. **Default features / async** — defaults are `["derive", "macros", "assert"]`, and
   `assert` pulls `testing_table` into a normal (non-dev) build
   (https://raw.githubusercontent.com/zhiburt/tabled/master/tabled/Cargo.toml `[features]`).
   That is why the recommendation is `default-features = false`. No async coupling.
6. **Binary size / compile time** — with defaults, a proc-macro (`tabled_derive`) plus a
   test-support crate; with `default-features = false, features = ["ansi"]`, the tree is
   `papergrid` + `ansi-str` + `ansitok` and no proc-macro, which is materially cheaper.
   Not measured; P03 measures.

##### Up-and-comers
`cli-table 0.5.0`, `term-table 1.4.0`, `nu-table 0.115.1`. `nu-table` is interesting as
provenance — it is nushell's own layer *over* `tabled` — but it is nushell-internal, at
77,186 downloads in 90 days, and versioned with the shell. None is shortlisted.

##### Fit for this template
Good for the `text` format, with one caveat the template must handle in its own code:
`tabled` renders presentation, and the recommendation deliberately does **not** use it
for Markdown. `Style::markdown()` exists and does not escape `|` — verified by grepping
the whole published `tabled-0.22.0/src` for pipe escaping, which returns nothing — so a
project name containing `|` would emit a structurally broken GFM table (A9 failure). The
hand-rolled Markdown renderer avoids this and matches py, which escapes explicitly:
`cells = [cell.replace("|", "\\|") for cell in row]`
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:253`).

##### Recommendation
`tabled = { version = "=0.22.0", default-features = false, features = ["ansi"] }`,
driven through `tabled::builder::Builder` from `columns()` + `rows_rich()`. Pin exactly:
the maintainer's own README says "We often do breaking changes on minor version bump…
It's likely better to depend on constant version e.g. `=0.8.0`", and nushell is currently
one minor behind at `0.21`, which is consistent with that policy. Upgrades become a
deliberate, reviewed change rather than a lockfile refresh.

##### Ranked runner-up
1. **`comfy-table 8.0.0`** — take it if the owner prefers its cleaner tracker (4 open
   issues) and 8.x stability over `tabled`'s minor-breaking policy, and accepts the
   "current stable only" MSRV posture. Configure `default-features = false` to keep
   `crossterm` out, and add `custom_styling` only if R85 needs ANSI-aware widths.
2. Bin 1 hand-rolled alignment — acceptable only if R85 is dropped and non-ASCII width
   correctness is waived. Not recommended.

##### Tradeoffs
Cost: a pre-1.0 dependency with a stated minor-breaking policy and no declared MSRV,
under an exact pin. Benefit: correct Unicode and ANSI width handling, proven by the most
demanding adopter in the ecosystem, and a ready seam for R85. Risk and its mitigation:
the upgrade path is manual by design (exact pin), and CI must carry an MSRV job because
the dependency declares none. The alternative — accepting `comfy-table` — trades a
breaking-minor policy for a "current stable only" support policy; neither crate gives
both stability guarantees.

##### Parameters
None owned. This member's *output shape* — `columns()` + `rows_rich()` producing an
aligned table — is what R85 (`rich-terminal-row-niceties`, F359) starts from; R85 needs no
registered parameter from this item, per `## Couplings`. No `CONFLICT:`.

##### Migration implications
`crates/<name>-cli/src/output/text.rs`; `Cargo.toml` gains one exactly-pinned dependency;
CI gains an MSRV job (which the `msrv-policy` parameter already requires independently);
the license allow-list gains MIT-only entries for `tabled`, `papergrid`, `tabled_derive`.

##### Validation strategy
Proposed, not run: a snapshot test of the rendered table for a fixed two-row result, run
twice — once with color forced on and once off — asserting that column alignment is
identical, which is the property `ansi` exists to provide.

##### Confidence & re-verify trigger
**Medium-high.** The crate choice is well evidenced; the exact pin and the missing MSRV
declaration are the soft spots. Re-verify when `tabled` publishes `0.23`, if nushell
migrates away from it, if `tabled` declares a `rust-version` above the then-current floor,
or on any advisory at `https://rustsec.org/packages/tabled.html`.

##### Sources
- `GET https://crates.io/api/v1/crates/tabled`, `/versions`, `/reverse_dependencies`; same for `comfy-table`, `prettytable-rs`, `markdown-table`, `cli-table`, `term-table`, `nu-table` — 2026-09-10.
- `GET https://api.github.com/repos/zhiburt/tabled` and `.../Nukesor/comfy-table`; `search/issues` for both — 2026-09-10.
- https://raw.githubusercontent.com/zhiburt/tabled/master/.github/workflows/ci.yml; .../tabled/Cargo.toml; .../README.md — 2026-09-10.
- https://raw.githubusercontent.com/Nukesor/comfy-table/main/Cargo.toml; .../README.md; .../src/style/presets.rs — 2026-09-10.
- https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-table/Cargo.toml:24; .../Cargo.toml:266 — 2026-09-10.
- https://raw.githubusercontent.com/Nukesor/pueue/main/pueue/Cargo.toml:32 — 2026-09-10.
- `tabled-0.22.0.crate` from `GET https://crates.io/api/v1/crates/tabled/0.22.0/download`; `src/settings/style/builder.rs:205-214`; absence of pipe escaping and of `unsafe` blocks verified locally — 2026-09-10.
- `https://rustsec.org/packages/tabled.html` → HTTP 404 — 2026-09-10.
- `py@b08bccfb:src/py_launch_blueprint/cli/output.py:224-238,253` — 2026-09-10.
- GitHub Flavored Markdown Spec, tables extension, https://github.github.com/gfm/#tables-extension- — 2026-09-10.

#### tempfile

##### Landscape
Bin 2. The category is "replace a file's contents without leaving a half-written file".
Bin 1 alternative — `std::fs::File::create` then `write_all`, which is what both sources
do — is not atomic and is the behavior the standard says to improve on. Bin 3 has no
challenger worth naming.

##### Principles and implementation
This member exists only because of the org standard's destination-file rule: a
`--output-file` option "**SHOULD** write atomically (temp + rename)"
(`cli-design-standard.md` line 226). It also makes A10 achievable: a render that fails
partway (a broken pipe, a serialization error) must leave the previous file intact rather
than truncated. Both sources fail this today — py opens `"w"`
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:206`), ts calls `writeFileSync` with
default flags (`ts@cb1cbcb2:src/commands/projects.ts:181-183`) — so this is a shared
capability gap, and fixing it in Rust first supplies the rationale for the py/ts
follow-on.

##### Dominant choice
`tempfile` — 177,706,408 downloads in 90 days; 798,430,218 all-time. Latest non-yanked
`3.27.0`, 2026-03-11. `Stebalien/tempfile`: 1,460 stars, `archived: false`, `pushed_at`
2026-09-05; open issues **5**. Responsiveness: the recent window holds 4 issues
(#444–#452, 2026-08-18 to 2026-09-05); 2 answered with a median of **0.48 days**, 2
unanswered. Maintenance: **active** — a push five days before retrieval and a two-day
median response, despite the last release being six months earlier.

##### Qualified shortlist
`std::fs` + `std::fs::rename` written by hand. It works, but generating a collision-free
temporary name in the target directory, setting permissions, and cleaning up on failure
is exactly the surface `tempfile` exists to get right.

##### Excluded by gate
None excluded. Gate results:
1. **License** — crates.io reports `MIT OR Apache-2.0` (`versions[].license`). Note a
   metadata discrepancy: `GET https://api.github.com/repos/Stebalien/tempfile` reports
   `license.spdx_id: "Apache-2.0"`, which is GitHub's single-file detection; the crate
   manifest is authoritative and is dual. Pass.
2. **MSRV** — `rust-version = 1.63`, below the 1.96.0 floor. Pass, declared.
3. **Advisories** — none (`https://rustsec.org/packages/tempfile.html` → HTTP 404,
   validated). `unsafe` posture: the crate wraps platform file APIs and therefore contains
   `unsafe` FFI in its Unix/Windows backends; I did **not** download and grep this crate's
   source, so I state the posture as "contains platform FFI, count not verified" rather
   than asserting a number.
4. **OS matrix** — CI-verified. The `build_and_test` matrix crosses
   `[nightly, stable, "1.63"]` with `ubuntu-latest` (`x86_64-unknown-linux-gnu`),
   `windows-latest` (`x86_64-pc-windows-msvc`), `macos-latest` (`aarch64-apple-darwin`),
   plus Android and `wasm32-wasip1` targets; a separate `cargo-deny` job runs on
   `ubuntu-latest`
   (https://raw.githubusercontent.com/Stebalien/tempfile/master/.github/workflows/ci.yml:22-60,
   retrieved 2026-09-10). Full pass — and the same matrix CI-tests the declared MSRV
   `1.63`, closing gate 2's "tested in CI" half as well.
5. **Default features / async** — no async coupling; small dependency surface (`fastrand`
   plus platform bindings). Feature set not enumerated from the manifest.
6. **Binary size / compile time** — negligible; no proc-macro. Not measured.

##### Up-and-comers
None. `inapplicable` — the category is settled and the crate is 12 years old.

##### Fit for this template
Good, and its scope is precisely one code path: resolving `--output-file PATH` to a sink.
It is also the member most likely to be shared: R52 (`toml-crate`) faces the same atomic
write for py's "atomic 0600" config write, and R59 (`file-log-sink`) may too. Adopting one
crate for all three is the right outcome; this item does not claim ownership of that
decision.

##### Recommendation
`tempfile = "3.27.0"`. Write the rendered bytes to a `NamedTempFile` created **in the
target's parent directory** (a rename across filesystems is not atomic), then
`persist(path)`. `--output-file -` bypasses this entirely and writes to stdout;
`--no-clobber` checks existence before rendering and exits 5 (`Conflict / precondition
failed`, `cli-design-standard.md` line 361) when the target exists.

##### Ranked runner-up
1. `std::fs` write-then-`rename` by hand — same semantics, more code to get wrong.
2. Plain truncating `File::create` — matches both sources' current behavior; recommended
   only if the owner rejects the atomicity SHOULD, in which case record it as a
   conformance-note deviation against the standard's line 226.

##### Tradeoffs
Cost: one small dependency and a temp file briefly visible in the target directory.
Benefit: a failed render can no longer destroy an existing file, and the fix propagates
as rationale to py and ts. Risk: `persist` fails across filesystems, which the
"same parent directory" rule prevents.

##### Parameters
None owned. Overlaps with R52's config-write mechanism; recorded as a coordination note,
not a `CONFLICT:`, because no registered parameter needs to change.

##### Migration implications
`crates/<name>-cli/src/output/sink.rs` — destination resolution and atomic persist;
`Cargo.toml` gains one dependency.

##### Validation strategy
Proposed, not run: write to an existing file with a renderer injected to fail midway;
assert the original content is unchanged and the exit code is nonzero. This is the only
A1–A10 check that needs fault injection rather than a CLI invocation.

##### Confidence & re-verify trigger
**High** on the crate; **medium-high** on gate coverage — gate 4 and the CI half of gate 2
are answered from the upstream CI file, but gate 3's `unsafe` count is still stated from
the crate's purpose rather than from its source, which P03 should close. Re-verify on a `4.0`, on an MSRV rise, or on any advisory at
`https://rustsec.org/packages/tempfile.html`.

##### Sources
- `GET https://crates.io/api/v1/crates/tempfile` and `/versions` — 2026-09-10.
- `GET https://api.github.com/repos/Stebalien/tempfile`; `.../search/issues?q=repo:Stebalien/tempfile+is:issue+is:open` — 2026-09-10.
- https://raw.githubusercontent.com/Stebalien/tempfile/master/.github/workflows/ci.yml — 2026-09-10.
- `https://rustsec.org/packages/tempfile.html` → HTTP 404 — 2026-09-10.
- `cli-design-standard.md` v1.4.14 lines 226 and 361, `/Users/stevemorin/c/cli-standards/cli-design-standard.md` — 2026-09-10.
- `py@b08bccfb:src/py_launch_blueprint/cli/output.py:206`; `ts@cb1cbcb2:src/commands/projects.ts:179-185` — 2026-09-10.

### Compatibility

The five members are not merely compatible in principle — **one well-regarded project
declares all five together, at the recommended versions**. `nushell/nushell` (40,472
stars, `archived: false`, `pushed_at` 2026-09-10) lists in its workspace manifest
(https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml, retrieved 2026-09-10):

| Line | Declaration | This report recommends |
|---|---|---|
| 155 | `csv = "1.4"` | `csv = "1.4.0"` |
| 257 | `serde = { version = "1.0" }` | `serde 1.0.229` with `derive` |
| 258 | `serde_json = "1.0.149"` | `serde_json 1.0.151` |
| 266 | `tabled = { version = "0.21", default-features = false }` | `tabled =0.22.0`, `default-features = false, features = ["ansi"]` |
| 267 | `tempfile = "3.27"` | `tempfile 3.27.0` |

That is a shared adopter, a version matrix, and a maintained reference implementation in
one artifact: a shipping, heavily used binary that compiles this exact set on Linux, macOS
and Windows. The only deltas are `tabled` 0.21 vs 0.22 (nushell is one minor behind, which
is consistent with `tabled`'s minor-breaking policy and is an argument for the exact pin,
not against the crate) and `serde_json` 1.0.149 vs 1.0.151 (two patch releases).

A second, narrower cross-check covers the format-decision half of the stack:
`sharkdp/hyperfine` (28,832 stars) ships `csv`, `serde` and `serde_json` together for
precisely this job — exporting one result set as JSON, CSV and Markdown
(https://raw.githubusercontent.com/sharkdp/hyperfine/master/Cargo.toml, retrieved
2026-09-10).

No member constrains another's feature flags: `serde_json` and `csv` both depend on
`serde_core` from the same `1.0.x` line, `tabled` at `default-features = false, features = ["ansi"]`
depends only on `papergrid`/`ansi-str`/`ansitok`, and `tempfile` shares nothing with the
others. There is no async runtime in the stack at all, so no runtime-coupling matrix
applies — `inapplicable`, by absence of any async dependency.

### Parameters

**Owned.** None. `## Couplings` records `owns:` as empty for R66, so this answer registers
no parameter.

**Assumed (consumed as fixed owner parameters, `research/.../inputs/parameters.json`, all
`kind: fixed`, `owner: owner`):**

- `assumes rust-edition = 2024` — satisfied; no member requires a later edition, and
  `comfy-table` (runner-up) is itself edition 2024.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — resolves to a **1.96.0** floor on 2026-09-10. Satisfied by `serde` (1.56), `serde_json` (1.71), `csv` (1.73), `tempfile` (1.63). **Not fully satisfied by `tabled`**, which declares no `rust-version` at all, as do `papergrid` and `tabled_derive`; the floor is met in fact but not declared, and the template's own CI MSRV job is the required compensating control.
- `assumes license = MIT OR Apache-2.0` — satisfied. Two allow-list additions are required: `Unlicense` (from `csv`/`csv-core`/`memchr`) and MIT-only entries (`tabled`, `papergrid`, `tabled_derive`), the latter carrying no Apache-2.0 patent grant.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied for `csv` (macOS explicitly in CI) and `tabled` (macOS explicitly in CI). For `serde` and `serde_json`, **macOS is absent from the upstream CI matrices**; judged pass on tier-1 platform status and universal transitive use, recorded here as a caveat rather than a CI-verified pass. For `tempfile`, CI-verified: its `build_and_test` matrix includes `ubuntu-latest`, `macos-latest` and `windows-latest`.

**No `CONFLICT:` lines.** `consumes:` is empty in `## Couplings`, and nothing in this
recommendation requires a fixed owner parameter to change.

**Two coordination notes, deliberately not raised as conflicts** (no registered parameter
exists to conflict with): the `serde` version and feature set are workspace-wide and will
also be consumed by R52 and R53; the atomic-file-write mechanism (`tempfile`) is the same
one R52 needs for py's atomic config write and R59 may need for a log sink. Both should be
decided once at the workspace level rather than three times.

**One proposal for the controller, not a registration.** The flag contract decided here is
read by at least three other items — R60 declares the flags, R67 renders its error envelope
through the selected format (F296), R85 extends the text row shape (F359). If the registry
wants a named parameter for it, the value would be:
`output-format-surface = "-o|--output <text|json|markdown|csv>; --output-file <path|-> (long-only, silent overwrite, atomic, --no-clobber); --json ≡ -o json, both-given → exit 2"`.
Registering it is the controller's call, not this report's.

### Migration implications

The template does not exist yet, so these are the files P03 creates or touches, expressed
against the crate layout the target shape implies (CLI + library + web service, spec §4 D7).

| File | Change |
|---|---|
| `Cargo.toml` (workspace) | Add `serde` (with `derive`), `serde_json`, `csv`, `tabled` (`=0.22.0`, `default-features = false`, `features = ["ansi"]`), `tempfile` to `[workspace.dependencies]`. |
| `crates/<name>-lib/src/models.rs` | `#[derive(Serialize)]` on `Project`, `ProjectList` and every future result type — the wire shape, shared with the web tier. |
| `crates/<name>-cli/src/output/mod.rs` | New. `enum OutputFormat { Text, Json, Markdown, Csv }` (framework value-enum derive, default `Text`); `trait CliResult` with `title`/`columns`/`rows`/`rows_rich`/`note`; `struct Renderer` dispatching to the four renderers over one `&mut dyn Write`. Deliberately **one** dispatch site, unlike py, which duplicates its `match` in `render()` and `_render_to_file()` (`py@b08bccfb:src/py_launch_blueprint/cli/output.py:152-165` and `:205-222`). |
| `crates/<name>-cli/src/output/{text,json,markdown,csv}.rs` | New. One function each. `markdown.rs` escapes `\|` per GFM. |
| `crates/<name>-cli/src/output/sink.rs` | New. Destination resolution: stdout, `-` → stdout, or `tempfile::NamedTempFile` in the target's parent then `persist`. `--no-clobber` pre-check → exit 5. |
| `crates/<name>-cli/src/cli.rs` (R60 owns the framework) | Declare `-o`/`--output` (enum, default `text`, env-bound like py's `PLBP_OUTPUT`), `--json` (bool, conflicts with `--output`), `--output-file` (path, long-only), `--no-clobber` (bool). |
| `crates/<name>-cli/tests/` | The A1–A10 cases as CLI integration tests plus format snapshots. |
| `docs/` conformance note | Two recorded deviations from `cli-design-standard.md` v1.4.14: the default human format is spelled `text` rather than `table` (R4.2), and the enum extends the standard set with `markdown` and `csv` (permitted — R4.2 calls the enum "extensible" — recorded for completeness). |
| `deny.toml` / license allow-list | Add `Unlicense`; record the MIT-only members. |

**Consequential change for the two source repos** (a follow-on project, per the research
mandate; this answer supplies the rationale, it does not change py or ts):

- **ts** renames `--format` → `-o`/`--output` and `--output` → `--output-file`, per py's
  design 0001 Appendix D item 2 and the standard's R3.2/R4.2 MUSTs. This is a breaking CLI
  change and needs a major version and a deprecation window; `D-033`'s EXAMPLECLI
  divergence note is then withdrawn rather than carried forward.
- **ts** gains `markdown`; **py** gains `csv`. Each is one renderer over a contract both
  already have.
- **ts's current `text`** (bare identifiers, one per line — `ts@cb1cbcb2:src/lib/format.ts:38`)
  is not the same format as py's `text` (an aligned table). Under the recommended enum,
  ts's `text` consumers would silently receive a table. The mitigation, offered as an
  option rather than folded into the recommendation: add the standard's `name` format
  (R4.2, "bare identifiers, one per line" — `cli-design-standard.md` line 257), which is
  one line of code, preserves ts's shell-composability use case
  (`ts@cb1cbcb2:src/lib/format.ts:8`, "not names — shell composability"), and upgrades it
  from a human format that "MAY change between releases" to a machine format that must
  stay stable. **Owner decision**, deliberately left out of `### Recommendation` because
  the prompt's question asked about a third format, not a fifth.
- **Both** gain atomic destination writes, `--output-file -`, and `--no-clobber`.

### Validation strategy

Every command below is **proposed and has not been run**: no Rust code exists in
`rs-launch-blueprint` (P03 builds it), so nothing in this section is an executed result.
What *was* executed for this report is listed in `Method notes` under `### Sources`.

Realistic example: a `projects list` command returning the same 200-row-capped result both
sources use, with two display columns (`id`, `name`) and at least one adversarial row whose
name is `a|b,c"d` followed by an embedded newline.

```bash
# A1/A2 — the selector and the alias are the same thing
diff <(app projects list -o json) <(app projects list --output json)   # expect: no output
diff <(app projects list -o json) <(app projects list --json)          # expect: no output

# A3 — alias plus an explicit conflicting format is a usage error
app projects list --json -o csv; echo "exit=$?"                        # expect: exit=2, stdout empty

# A7 — the enum is closed
app projects list -o xml; echo "exit=$?"                               # expect: exit=2, message lists text|json|markdown|csv

# A4/A5 — destination is orthogonal to format
app projects list -o json --output-file out.json                       # expect: stdout empty
diff out.json <(app projects list -o json)                             # expect: no output
app projects list -o csv --output-file - | head -1                     # expect: id,name

# A6 — TTY does not change the format
diff <(script -q /dev/null app projects list -o text | sed 's/\x1b\[[0-9;]*m//g') \
     <(app projects list -o text)                                      # expect: no output

# A8 — machine output stays parseable while a warning is emitted
app projects list -o json 2>/dev/null | jq -e '.projects | length'     # expect: exit 0

# A9 — separator safety, all three serializations
app projects list -o csv    | python3 -c 'import csv,sys; print(len(list(csv.reader(sys.stdin))))'
app projects list -o markdown | grep -c '\\|'                          # expect: >=1 escaped pipe
app projects list -o json   | jq -e '.projects[] | select(.name|test("\\|"))'

# A10 — atomic destination write (needs the fault-injection test, not a shell command)
cargo test --package app-cli output::sink::render_failure_leaves_target_intact
```

Verification harness: `assert_cmd` + `predicates` for exit codes and stream separation,
`insta` for format snapshots (each of the four formats gets a committed snapshot, which is
what makes R7.2's "machine formats MUST stay stable within a major version" enforceable
rather than aspirational), and one fault-injection unit test for A10. The concrete choices
of test-harness and snapshot crates belong to R32 and R33, not to this item.

Two checks are deliberately *not* proposed here because another item owns them: paging of
long text output (R64, F284/F285) and per-cell terminal niceties (R85, F359).

### Confidence & re-verify trigger

**Overall confidence: high on the decision, medium-high on the crate set.**

The flag-naming answer is the strongest conclusion in this report, and its strength comes
from primary sources rather than from judgment: two MUSTs in the owner's own standard
(R4.2 line 256, R3.2 line 194), an explicit written instruction in py's design spec to make
exactly this rename "before it spreads across tools" (design 0001 Appendix D item 2), and
a legacy-commit reading showing that ts's shape is the superseded py shape rather than an
independent design. The one way this is wrong is if the owner has since superseded
`cli-design-standard.md` v1.4.14 or design 0001; both were read at the versions stated.

The format-set answer (both `markdown` and `csv`) is high confidence on evidence — ADR 0003
is an accepted, reasoned decision and ts's csv has a real use case — but it is ultimately an
owner scope call, and the prompt's own classification says so (class `F`, `docs/port/DIVERGENCE-ANALYSIS.md:206`).

The crate set is medium-high. `serde`, `serde_json` and `csv` are as close to
uncontestable as this ecosystem gets. `tabled` is the one genuine judgment call — a pre-1.0
crate with a stated minor-breaking policy and no declared MSRV, chosen over `comfy-table`
which has more 90-day downloads and a cleaner tracker but a "current stable only" MSRV
posture and a `crossterm`-pulling default feature. nushell's adoption is what tips it, and
that is adoption evidence rather than proof.

**Re-verify triggers, in priority order.**

1. **Immediately, if R60 selects a CLI framework that cannot express presence-based mutual
   exclusion or a closed value-enum.** The whole flag surface assumes both. Nothing in the
   current evidence suggests this, but R60 has not resolved.
2. **If the owner rejects either BASELINE-REVIEW.** Rejecting the F293 review reverts the
   recommendation to ts's `--format`/`--output` split and requires a standing waiver against
   two MUSTs.
3. **If `cli-design-standard.md` moves past v1.4.14** in a way that touches R3.2, R4.2, R7.2
   or R7.3.
4. **On `tabled 0.23`, or if nushell migrates off `tabled`** — the adopter evidence is what
   selected it.
5. **On any RustSec advisory** for `serde`, `serde_json`, `csv`, `tabled` or `tempfile`; all
   five pages returned HTTP 404 on 2026-09-10.
6. **On an MSRV rise** in any member above the then-current stable-minus-two floor —
   `tabled` is the exposure, because it declares nothing.
7. **If `csv` has no release by 2027-10-17** (24 months after 1.4.0's 2025-10-17
   release) *and* unanswered
   correctness issues accumulate. Cadence alone is not the trigger; the rubric requires a
   concrete signal.

### Sources

**Pinned source repositories** (private; HTTP 404 from the network; read via
`git show <commit>:<path>`; all read 2026-09-10):

- `py@b08bccfb:src/py_launch_blueprint/cli/output.py` — `class OutputMode(StrEnum)` with `TEXT`/`JSON`/`MARKDOWN` at :47-52; `Renderer` at :118; format dispatch at :152-165; `_render_to_file` ("R4: --output-file changes the destination, never the format") at :202-222; `_render_text` at :224-238; `_to_markdown` with `cell.replace("|", "\\|")` at :241-256; JSON error envelope at :277-293.
- `py@b08bccfb:src/py_launch_blueprint/cli/options.py:52-77` — `-o`/`--output` (`click.Choice`, `envvar="PLBP_OUTPUT"`), `--json` ("Shorthand for --output json."), `--output-file` ("Write results to a file instead of stdout (format set by --output)."); `:126` — `--json` silent precedence.
- `py@b08bccfb:src/py_launch_blueprint/core/models.py:40-72` — the `CLIResult` contract; `:96` — `ProjectList.table_rows()`.
- `py@b08bccfb:src/py_launch_blueprint/cli/commands/projects.py:56-60` — `--limit` default 200.
- `py@b08bccfb:docs/adr/0003-keep-markdown-output-mode.md` — the Markdown decision, Accepted 2026-06-09.
- `py@b08bccfb:docs/design/0001-plbp-cli-conventions.md` — deviations note :8-15; R3.1-R3.4 :49-53; R4.1-R4.3 :58-63; flag table :183-184; Appendix D item 2 :212-214.
- `py@f587e48^:src/py_launch_blueprint/projects.py:321-332` — the legacy CLI: `--format` (`text|json|csv`), `--copy`, `--output` as file path. **Ancestor of the py pin, not the pin.**
- `py` ancestor `fda272d` — "feat(cli): add gh-style pylb CLI with core library layer", 2026-06-09, the rewrite commit.
- `ts@cb1cbcb2:src/lib/format.ts` — header comment naming `format_output (projects.py:273-291)` as its source and "text -> newline-joined project IDs (not names — shell composability)" at :1-12; `OUTPUT_FORMATS = ['text','json','csv']` at :16; `csvField` at :21-27; `formatOutput` at :31-39.
- `ts@cb1cbcb2:src/commands/projects.ts:75-84` — `--format` with `.choices(OUTPUT_FORMATS).default('text')`, `--json` with `.conflicts('format')`, `--output <file>`; `:179-185` — `writeFileSync` file sink.
- `ts@cb1cbcb2:docs/port/TS_PORT_DECISIONS.md:395-399` — D-033 in full, including the flag-naming sentence and the Options list that omits it.
- `ts@cb1cbcb2:EXAMPLECLI.md:166-228` — the shipped CLI surface, including ":192-194" recording that "`-o/--output <table|json|...>` format enum is deliberately NOT adopted".

**Owner standard** (local, no public URL): `/Users/stevemorin/c/cli-standards/cli-design-standard.md`, **Version 1.4.14** (line 7). Cited lines: 194 (R3.2 destination-file MUSTs), 203 (R3.4 reserved short letters), 226 (atomic write SHOULD, `--no-clobber`), 238 (result-output options MUST), 255-259 (R4.2 in full, including the `table`/`wide`/`json`/`jsonl`/`yaml`/`name` classification), 361 (exit 5 = conflict), 381 (R7.1 streams), 385 (R7.2 machine-format stability), 391 (R7.3 TTY MUST NOT change format), 431 (R7.8), 492 (R9.3 interface as contract), 553 (mutually exclusive flags MUST exit 2), 641/647 (audit checklist). Read 2026-09-10.

**Repository ledger and analysis** (this repository, read 2026-09-10):
`docs/port/COMMONALITY.md:288-289,295-297,363` (F284/F285, F291/F292/F293, F359);
`docs/port/DIVERGENCE-ANALYSIS.md:69` (table header), `:205-207` (R66 item and sub-rows),
`:303` (the analyst's own note that R66/F291 is defensibly class F), `:56` (R66 listed under harmonize=partly).

**Endpoints queried** (all 2026-09-10): `https://crates.io/api/v1/crates/{serde,serde_json,csv,csv-core,tabled,comfy-table,prettytable-rs,tabwriter,markdown-table,tempfile,serde_yaml,serde_norway,papergrid,tabled_derive,serde_core,memchr,itoa,sonic-rs,simd-json,cli-table,term-table,ascii_table,serde_json_lenient,nu-table,csv-async,clap}` and their `/versions`; `/reverse_dependencies` for `csv`, `tabled`, `comfy-table`; `https://crates.io/api/v1/crates/{tabled/0.22.0,serde/1.0.229,serde_json/1.0.151,csv/1.4.0}/download`; `https://api.github.com/repos/{serde-rs/serde,serde-rs/json,BurntSushi/rust-csv,zhiburt/tabled,Nukesor/comfy-table,Stebalien/tempfile,nushell/nushell,sharkdp/hyperfine,Nukesor/pueue,BurntSushi/ripgrep}`; `https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the six crate repositories; `https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc` plus per-issue `/comments` for the responsiveness medians; `https://rustsec.org/packages/{serde,serde_json,csv,tabled,comfy-table,tempfile,atty,time}.html`; `https://static.rust-lang.org/dist/channel-rust-stable.toml`; `https://blog.rust-lang.org/`; `https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`; `https://docs.rs/clap/latest/clap/builder/struct.Arg.html`; raw.githubusercontent.com manifests, READMEs, CI workflows and source files for `zhiburt/tabled`, `Nukesor/comfy-table`, `BurntSushi/rust-csv`, `serde-rs/serde`, `serde-rs/json`, `nushell/nushell`, `Nukesor/pueue`, `sharkdp/hyperfine`.

**Method notes.** Every figure in this report came from the endpoints in the prompt's
figure table, queried on **2026-09-10** with a `User-Agent` header on crates.io and via the
`gh api` REST client for GitHub; GitHub search was used for `total_count` and the repo
object's `open_issues_count` was never substituted for it. Issue responsiveness was computed
by fetching each repository's 30 most recent issues-or-PRs, discarding pull requests, taking
the newest 10, and treating the first comment whose `author_association` is `OWNER`,
`MEMBER` or `COLLABORATOR` as the first maintainer response; `zhiburt/tabled` (6),
`Nukesor/comfy-table` (8) and `Stebalien/tempfile` (4) had fewer than 10 issues in that
window, and each count is stated in its member. RustSec 404s were validated as "no
advisory" by confirming that `atty` and `time` return HTTP 200 with advisory IDs. The
MSRV floor of 1.96.0 was derived from the toolchain's own stable manifest plus the Rust
release blog, not assumed. Pinned repositories were read exclusively through
`git show <commit>:<path>`; the two ancestor commits (`f587e48^`, `fda272d`) are labelled
as ancestors wherever they appear, per the instruction to label which commit each claim
comes from. The `tabled` Markdown-escaping defect and the `unsafe` counts for `serde`,
`serde_json`, `csv` and `tabled` were established by downloading the published `.crate`
files and grepping their sources locally, not from documentation.

**What I could not verify.** (1) **No benchmark and no build were run** — every
compile-time, binary-size and throughput statement in this report is qualitative and
derived from dependency-tree shape, and P03 must measure them; the prompt's performance
paragraph is therefore answered by explaining why the 200-row workload cannot discriminate
between candidates rather than by producing latency or throughput numbers. (2) The **2025
State of Rust Survey** results page was fetched successfully (HTTP 200) but its
domain-of-use figures are rendered as images, so I extracted **no CLI-adoption figure**
from it; it is listed as an authority consulted, and no number is attributed to it.
(3) For **`tempfile`**, I read its CI workflow (closing the OS-matrix gate and the
CI-tested half of the MSRV gate) but did **not** download and grep its source, so its
`unsafe` posture is stated as "contains platform FFI, count not verified" — a gap P03
should close.
(4) `zmij`, `ansi-str`, `ansitok`, `fastrand` and `unicode-segmentation` were **not**
individually gate-checked; only the direct members and the `tabled`/`csv`/`serde_json`
first-level trees were. (5) `github.com/search/code` returned HTTP 403, so no
code-search-based adopter sweep was possible; adopters were established by reading named
projects' manifests directly instead. (6) The org standard has **no public URL** — it is a
local file whose version line (1.4.14) is quoted; a reader without that checkout cannot
follow the citation.
