# R66 — output-format-surface — DECISION (revision 1, 2026-09-16)

Actor `synth-opus-2026-09-05T183458Z-9ff7d91f9b8f-r1`, model `claude-opus-5`, item kind
`bundle`, effort tier `deep`. This is the first revision of this decision; no revision has
been published, so there is no `## Supersedes`.

Every figure and quotation below carries the endpoint or the pinned path it came from. Where
a date is not stated on the line, the retrieval date is **2026-09-16 (UTC)** for anything this
decision checked itself, and the raw report's own date for anything carried from a raw:
**2026-09-05** (Codex), **2026-09-09** (Doxa/OpenAI), **2026-09-10** (Opus).

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. No Rust source exists in this repository, so
nothing here is an implemented result. The list of what P03 must validate is at the end of
`## Engines`. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

### The recommended stack

| Role | Crate | Version | Configuration | Crate home |
|---|---|---|---|---|
| Result data contract (wire shape) | `serde` | `1.0.229` | `features = ["derive"]` | library crate |
| `json` renderer | `serde_json` | `1.0.151` | default features | CLI crate |
| `table` renderer (aligned human table) | `tabled` | `=0.22.0` (exact pin) | `default-features = false, features = ["ansi"]`, driven through `tabled::builder::Builder` | CLI crate |
| `--output-file` atomic replacement | `tempfile` | `3.27.0` | `NamedTempFile::persist` into the target's own directory | CLI crate |
| `markdown` renderer | *no crate* | — | ~20 lines of `write!` over the columns/rows contract, escaping the GFM cell separator | CLI crate |
| `name` renderer | *no crate* | — | one `writeln!` per identifier | CLI crate |

`csv` **is not in the stack.** It is the ranked runner-up's fifth format and is named with its
version there.

### The format enum

`-o <table|json|markdown|name>`, default **`table`**.

| Value | Class under the standard | What it emits | Why it is here |
|---|---|---|---|
| `table` | human (R7.2: **MAY** change between releases) | aligned table with headers and an optional title | py's shipped human format (`py@b08bccfb:src/py_launch_blueprint/cli/output.py:224-238`, a `rich.Table` with `add_column`/`add_row`); `table` is the standard's own name for the default human format (R4.1, `cli-design-standard.md:246`) |
| `json` | machine (R7.2: **MUST** stay stable within a major version) | one JSON document of the library's wire DTO | both sources ship it; F292 requires the `--json` alias |
| `markdown` | human (R7.2), with one invariant held above that class — see below | GFM table, pipe-escaped, plain UTF-8, final `LF` | py's ADR 0003, **Accepted 2026-06-09**: "useful for pasting into issues/PRs and cheap to maintain because every command renders through one `Renderer` and one result model" (`py@b08bccfb:docs/adr/0003-keep-markdown-output-mode.md`) |
| `name` | machine (R7.2) | bare identifiers, one per line | this is what ts's `text` actually is — `return projects.map((project) => project.id).join('\n');` (`ts@cb1cbcb2:src/lib/format.ts:39`), documented in its own header as "not names — shell composability" (`:8`). `name` is the standard's own name for that format (R4.2, `:257`) |

**`markdown`'s one invariant.** Its class is human, so its column set and title may change
between releases like `table`'s. Its *escaping contract* may not: every cell that reaches a
Markdown renderer has `|` and `\` escaped, contains no `LF`, and contains no ANSI or OSC
byte. That is a correctness property, not presentation, and it is regression-tested on an
adversarial row. py already implements exactly this one escape —
`cells = [cell.replace("|", "\\|") for cell in row]`
(`py@b08bccfb:src/py_launch_blueprint/cli/output.py:253`) — while **both** maintained Rust
reference renderers do not: `tabled 0.22.0`'s whole `src/` contains zero `replace("|"` call
sites and zero backslash-pipe escapes, and `hyperfine`'s Markdown exporter joins cells with
`format!("| {} |\n", cells.join(" | "))` and performs no replacement at all (checks `A4b`,
`A4c`, `A4e`, `A4f`). The template must be stricter than its own reference implementation
here, and this decision says so rather than inheriting the defect.

**What the enum deliberately omits, and why that is conformant.** R4.2 also lists `jsonl`,
`yaml` and `wide`. None is offered. R4.2 calls the enum "extensible" and introduces its list
with "machine-readable output is requested by selecting a machine format **such as** `json`,
`jsonl`, `yaml`, or `name`" (`cli-design-standard.md:256`, check `C9d`) — an open list, not a
closed required set. `jsonl` has no streaming command to serve in a `list`-shaped template;
`yaml` would add a second machine schema and a parser dependency for no evidenced job;
`wide` needs a second column set that no source repo defines. Each is a one-variant addition
later, which is the point of the exporter seam below. **No `OVERRIDE` is declared by this
item: every applicable `MUST` in the standard is met, and no `SHOULD` is waived.**

### The flag contract

| Flag | Shape | Rule and its source |
|---|---|---|
| `-o` / `--output <format>` | enum, default `table` | **R4.2 (MUST)**: "For commands that emit formatted result data, `-o`/`--output` **MUST** be the canonical output-format selector, with an extensible enum" (`:256`) |
| `--json` | boolean, long-only | **R4.2 (MUST)**: "`--json` **MUST** behave identically to `-o json`" (`:256`). Ledger F292, `COMMON → REUSE` |
| `--output-file <path>` | path, **long form only, no short flag** | **R3.2 (MUST)**: a destination-file option "**MUST** be a distinct flag — **`--output-file`, long form only** … **MUST NOT** reuse `--output`/`-o` (which selects *format*, R4.1), and **MUST** honor `-` as stdout" (`:194`) |
| `--output-file -` | literal hyphen | stdout, per the same R3.2 `MUST` |
| `--no-clobber` | boolean | **R3.9 (SHOULD)**: `--output-file` "**SHOULD** write atomically (temp + rename) and **MAY** overwrite silently (Unix `>` convention); offer `--no-clobber` to refuse an existing file" (`:226`) |

**Resolution rules.**

1. **Alias.** `--json` resolves to `-o json`. `-o json` and `--json` emit byte-identical bytes.
2. **Conflict.** `--json` together with **any explicit** `-o <value>` — including `-o json` —
   is a usage error: exit `2`, code `RSLB201` (R67's catalog). The test is *explicit
   presence*, so a parser-injected default never collides; the parse-facing field is
   `Option<OutputFormat>` and the resolution is a total function over `(Option<OutputFormat>,
   bool)`, which is the shape the Doxa raw supplies and which keeps the rule independent of
   R60's framework. ts already implements presence-based conflict
   (`.addOption(new Option('--json', …).conflicts('format'))`,
   `ts@cb1cbcb2:src/commands/projects.ts:82`); py instead lets `--json` win silently
   (`mode = OutputMode.JSON if json_mode else OutputMode(output_mode or "text")`,
   `py@b08bccfb:src/py_launch_blueprint/cli/options.py:126`). **ts's behavior is adopted**,
   because the standard already fixes the pattern for a flag pair of this shape:
   "`--paginate` and `--no-paginate` are mutually exclusive; using both **MUST** fail with
   usage error `2`" (`:553`). Silent precedence hides a script bug; exit `2` reports it.
3. **Orthogonality.** The destination never changes the format and the format never changes
   the destination. `-o json --output-file f` puts in `f` exactly the bytes stdout would have
   carried, and leaves stdout byte-empty.
4. **Existing target.** Silent overwrite, performed atomically. **Append is not offered**: it
   produces a file holding two JSON documents or two Markdown headers. `--no-clobber` refuses
   an existing file with exit `5` (R67's conflict code). Both sources truncate non-atomically
   today — py `with self.output_file.open("w", encoding="utf-8") as handle:`
   (`py@b08bccfb:.../output.py:206`) and ts `writeFileSync(cmdOpts.output, result);`
   (`ts@cb1cbcb2:src/commands/projects.ts:183`) — so a failed render destroys the previous
   file in both. That is a capability gap in both sources, not an ecosystem difference.
5. **TTY.** TTY state never changes the selected format — **R7.3 (MUST)**: "TTY state **MUST
   NOT** change the selected output *format*" (`:391`). A pipe suppresses niceties only.
6. **Colour.** The org standard puts colour out of its own scope: "Color, theming, terminal
   styling … are governed by a separate standard and are deliberately omitted here" (`:32`).
   This item therefore decides only the byte-level rule that follows from format choice:
   **`json`, `markdown` and `name` carry no ANSI or OSC byte under any TTY, terminal or
   environment state.** Only the `table` renderer may receive colour, and whether it does is
   R65's (`color-enablement-chain`) answer, not this item's.
7. **Environment and config parity.** If a `<TOOL>_OUTPUT` environment variable or an
   `output` config key is offered — py offers `envvar="PLBP_OUTPUT"`
   (`py@b08bccfb:.../options.py:62`) — **R3.8 (MUST)** fixes its spelling by deterministic
   transform from `--output`. Whether the config layer carries it at all is R52/R53's
   question; this item fixes only the name it would have to use.

### Ledger rows settled

| Row | Verdict before | Settled as |
|---|---|---|
| **F291** — output-format choices (`DIVERGENT`) | py `markdown` vs ts `csv`, "no recorded reason" (`docs/port/DIVERGENCE-ANALYSIS.md:206`) | `table`, `json`, `markdown`, `name`. `markdown` on py's recorded ADR; `csv` deferred with its trigger and its crate named; `name` added because ts's `text` *is* that format |
| **F292** — `--json` shorthand (`COMMON → REUSE`, `retained` at `docs/port/BASELINE-REVIEW.md:121`) | retained; the row's affected item is R66 | honored unchanged: `--json` exists and aliases `-o json`. This item supplies the missing half — which flag it aliases to (`-o`/`--output`) and what happens when both are explicit (exit `2`) |
| **F293** — result-to-file redirection flag (`DIVERGENT`) | "inherit ts's already-adjudicated split" (`docs/port/DIVERGENCE-ANALYSIS.md:207`) | py's split, which is the standard's mandated split: `-o`/`--output` selects format, `--output-file` redirects. The recorded recommendation is inverted; the `BASELINE-REVIEW:` line below carries the evidence |

### BASELINE-REVIEW findings

BASELINE-REVIEW: F293 — format selection and destination are orthogonal, and their flag names are org policy rather than per-repo preference — change the recorded target from "none — inherit ts's already-adjudicated split (`--format` selects, `--output` redirects)" to py's split (`-o`/`--output` selects format; `--output-file`, long form only, redirects; `-` means stdout), and reclassify ts's shape as stale-port drift of the F265 class rather than a deliberate adjudicated divergence — evidence, each verified at the pin by `review/evidence/r66-sources.sh` and named by its check id: the org `cli-design-standard.md` v1.4.14 (blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, check `C0c`) makes both spellings a `MUST` at `:194` (`C9a`) and `:256` (`C9d`, `C9e`); py's own design spec directed the rename before ts was written — "Rename the format flag usage so `--output`/`-o` is the format and `--output-file` is the destination (current code uses `--format` for type and `--output` for a file path — resolve before it spreads across tools)" (`py@b08bccfb:docs/design/0001-plbp-cli-conventions.md`, checks `C3a`, `C3b`); the *legacy* py CLI at the ancestor commit `f587e48^` declared `"--format"` with `type=click.Choice(["text", "json", "csv"])` and `@click.option("--output", type=click.Path(), help="Write results to file")` (checks `C5a`, `C5b`, `C5c`) — ts's surface exactly, and `ts@cb1cbcb2:src/lib/format.ts:1` names `format_output (projects.py:273-291)` as its source (`C6a`); and ts's `D-033`, the decision cited as the adjudication, is headed "Interactive-prompt interrupt → exit 130; machine-mode error envelope" and its own `Options:` list offers three prompt-cancellation options and **no** flag-naming option at all (checks `C8a`, `C8c`, `C8d`, `C8e`), the flag sentence appearing only in its `Why` as a carried-forward parity note. Affected items: R66 (F293, this item), R60 (declares the flags), R85 (reads the text row shape). Affected records: `docs/port/COMMONALITY.md:297`, `docs/port/DIVERGENCE-ANALYSIS.md:205,207`.

BASELINE-REVIEW: F291 — the third format is a recorded owner decision on one side and a ported artifact on the other, not two independent picks — change "no recorded reason; each repo picked a different 3rd format for a different use case … — inferred" to cite py `docs/adr/0003-keep-markdown-output-mode.md` (Status Accepted, Date 2026-06-09) for `markdown`, and record that ts's `csv` is the legacy py CLI's `csv` carried through the port rather than an independent choice — evidence, verified at the pin: ADR 0003's own text, including its rejected alternative "**Strict spec compliance (drop markdown)** — rejected" (checks `C4a`, `C4b`, `C4c`, `C4d`, `C4e`); the legacy py CLI's `click.Choice(["text", "json", "csv"])` at `f587e48^:src/py_launch_blueprint/projects.py:325` with no markdown anywhere in that file (checks `C5b`, `C5e`); and `ts@cb1cbcb2:src/lib/format.ts:1` naming its source (`C6a`). Affected items: R66 (F291, this item). Affected records: `docs/port/COMMONALITY.md:295`, `docs/port/DIVERGENCE-ANALYSIS.md:206`.

**A third divergence, not filed as a `BASELINE-REVIEW`.** py's `text` and ts's `text` are not
the same format: py's is an aligned table (`.../output.py:224-238`), ts's is bare identifiers
one per line (`src/lib/format.ts:39`). No ledger row asserts they agree — F291 is already
`DIVERGENT` and names R66 — so there is nothing to challenge; the disagreement is inside this
item's own scope and is settled above by keeping **both** as `table` and `name`. It is
recorded here because an auditor reading F291's "markdown vs csv" framing would otherwise not
know a second, unnamed divergence was found and answered.

### Couplings satisfied

**R60 (`cli-parsing-framework`), owner ruling 2026-09-14, option (b).** R60 lists exactly
three things R66 must stay compatible with (`research/runs/R60/…/review/DECISION.md`, checks
`C10e`–`C10g`), and all three are satisfied:

1. *"A format-selection flag that accepts the value `json`."* — `-o json`, and `--json`.
2. *"That flag being declarable on the root command, so `<tool> --version <format-flag> json`
   parses."* — `-o`/`--output` is declared in R60's flattened `GlobalArgs` with
   `global = true`; this item requires no narrower scoping.
3. *"The spelling, which is the only part R60 cannot supply."* — `-o`/`--output`. R60's AC3
   therefore becomes **R4.6's own worked example verbatim**: `<tool> --version -o json`.

The one R66 outcome that would reopen F267 — "no format-selection flag accepted at the root
under any spelling" — has not occurred. **No `CONFLICT:` line is possible or raised**: R66
owns no registry parameter and consumes none (checks `C10h`, `C10i`, `C11a`, `C11b`).

**R67 (`error-and-exit-code-contract`), accepted 2026-09-14.** R67 assigns this item two
duties (`research/topics/67-error-and-exit-code-contract/DECISION.md`, check `C10b`): render
`hint` as a distinct field or line, and own the locked-handle writer its broken-pipe rule
assumes. Both are discharged:

- **`hint` rendering.** Under a **human** format (`table`, `markdown`) the error is
  `error[<CODE>]: <message>` followed by a separate `hint: <text>` line on stderr. Under a
  **machine** format (`json`, `name`) it is exactly one
  `{"error":{"code","message","hint"?}}` object on stderr with stdout byte-empty, `hint`
  omitted rather than `null` when absent. That split is not this item's invention: **R7.8
  (MUST)** says "Under any machine output format (`-o json`/`--json`, `-o jsonl`, `-o yaml`,
  or `-o name`), an ordinary command error **MUST** be emitted to stderr as a single JSON
  object" (`:431`, check `C9j`) — which is why `name`, a machine format, takes the envelope
  and `markdown`, a human format, does not.
- **The writer.** One `Destination` is resolved once, before any renderer runs, to either
  `io::stdout().lock()` or a `tempfile::NamedTempFile` opened in the target's directory. Every
  renderer writes through `&mut dyn Write` and knows nothing else. `println!`/`print!` are
  lint-denied in binary crates (R67, check `C10d`), so the locked handle is the only path to
  stdout and R67's broken-pipe rule — "a `BrokenPipe` result on the *result* stream ends the
  process at `0`, silently, with no envelope" (check `C10c`) — has a fallible `write` to
  observe on every byte. All streams are flushed before exit on every path, **R7.7 (MUST)**
  (`:429`, check `C9i`).
- **Render-then-write, in that order.** For `--output-file`, the full document is rendered to
  an in-memory buffer (or to the temp file) *before* the target is touched, and the atomic
  `persist` is the last step. A failed render therefore leaves the previous file intact — the
  property both sources lack.

### Principles and implementation

**The shared requirement, its source, and its agreement level.** The principle is not "offer
three formats". It is:

> One result value, rendered through one format-selection surface, where the **format** and
> the **destination** are independent, explicitly selected, and never inferred from the
> environment.

| Level | What must agree across py, ts and rs | Source |
|---|---|---|
| **Policy** (verbatim flag names) | `-o`/`--output` selects format; `--output-file` (long-only) redirects and honors `-`; `--json` ≡ `-o json` | `cli-design-standard.md` R3.2 `:194`, R4.1 `:246`, R4.2 `:256` — all `MUST`, and the standard is org-locked for this template by the owner's ruling of 2026-09-14 |
| **Capability** (must exist; the list may extend) | a human format, a stable machine format, the `--json` ergonomic alias, a separate destination | F292 `COMMON → REUSE`; R4.2's "extensible enum" |
| **Architectural pattern** (shared, and it holds in Rust) | every command's result renders through **one** renderer over **one** columns/rows contract | py `CLIResult.table_columns()/table_rows()/table_rows_rich()` consumed by a single `Renderer`; ts's pure `formatOutput(projects, format)` (`ts@cb1cbcb2:src/lib/format.ts:31`) |
| **Stream policy** | results to stdout, diagnostics to stderr, machine output uncontaminated | R7.1 `:381` (check `C9m`); py's `output.py` module docstring cites clig.dev for the same split |
| **No TTY-driven format switching** | selected format is independent of TTY | R7.3 `:391` (check `C9h`) |

**What may vary by ecosystem.** The rendering libraries; the exact glyphs of the human table;
which optional machine formats are offered; the mechanism for atomic file replacement. Those
are implementation, not agreement.

**Essential behaviors and observable acceptance criteria.** Each is executable against the
built binary. **None has been run — no Rust code exists.** They are the acceptance suite P03
inherits. They are numbered `AC1`–`AC16`; where this decision cites another item's criterion it
always writes that item's id first (`R60's AC3`, `R67's AC1`). Evidence-script check ids, which
live in `## Empirical check` and in the logs, are a separate namespace beginning `C` or `A`.

| # | Behavior | Observable criterion |
|---|---|---|
| AC1 | The selector is `-o`/`--output` | `cmd -o json` and `cmd --output json` emit identical bytes |
| AC2 | `--json` is exactly the alias | `cmd --json` is byte-identical to `cmd -o json` |
| AC3 | Alias conflict is a usage error | `cmd --json -o markdown` **and** `cmd --json -o json` each exit `2` with code `RSLB201`, name both flags, and leave stdout byte-empty |
| AC4 | A parser-injected default never collides | `cmd --json` alone exits `0`: the conflict tests explicit presence, not the resolved value |
| AC5 | Destination is orthogonal | `cmd -o json --output-file f` → `f` holds the bytes stdout would have carried; stdout is byte-empty |
| AC6 | `-` is stdout | `cmd -o markdown --output-file -` writes Markdown to stdout |
| AC7 | Format is TTY-independent | `cmd -o table` under a pty and `cmd -o table \| cat` select the same *format* |
| AC8 | The enum is closed | `cmd -o xml` exits `2` and the message lists the four valid values |
| AC9 | Machine output is uncontaminated | `cmd -o json 2>/dev/null \| jq -e .` succeeds while a warning is emitted to stderr |
| AC10 | Separator safety | a cell holding `\|`, `\`, `"`, `,` and an embedded newline round-trips: Markdown escapes `\|` and `\` and carries no `LF` inside a cell; JSON escapes per JSON; `name` emits identifiers only |
| AC11 | No terminal bytes outside `table` | the output of `-o json`, `-o markdown` and `-o name` contains byte `0x1b` zero times under every TTY and environment state |
| AC12 | Destination write is atomic, silent-overwrite | an existing target is replaced; a render failure injected mid-document leaves the **old** file byte-identical |
| AC13 | `--no-clobber` refuses | an existing target is left untouched and the exit is `5` |
| AC14 | The error envelope follows the format class | `-o json` and `-o name` put one `{"error":{…}}` object on stderr with stdout byte-empty; `-o table` and `-o markdown` print `error[<CODE>]: …` plus a separate `hint:` line |
| AC15 | Broken pipe on the result stream | `cmd -o json \| head -1` exits `0` with no envelope |
| AC16 | The library does not render | the renderer tests instantiate no CLI parser and no web server; the library crate declares no CLI dependency |

**Architectural alternatives, compared before any library was chosen.**

- **ALT-1 — Serde-only: every format is a `serde::Serializer`** (`serde_json`, `csv` via
  serde, a Markdown `Serializer`). **Rejected.** A serde `Serializer` is driven by the
  *type's* shape; a Markdown or aligned table is driven by a *presentation* shape — column
  order, headers, human-formatted timestamps — that deliberately differs from the wire shape.
  py already encodes the split, and this decision verified it at the pin: `_render_text`
  consumes `result.table_rows_rich()` (markup-carrying cells) while `_to_markdown` consumes
  `result.table_rows()` (plain cells), and `model_dump_json()` serializes a third, wire shape
  (checks `C1h`, `C1i`). Forcing all three through one serde impl collapses a distinction the
  sources found they needed.
- **ALT-2 — let the table crate emit Markdown.** Both shortlisted table crates offer it
  (`tabled`'s `Style::markdown()`, `comfy-table`'s `ASCII_MARKDOWN`). **Rejected on verified
  evidence**, and the verification is this decision's own, not a carried claim: the published
  `tabled 0.22.0` tarball was downloaded from
  `GET https://crates.io/api/v1/crates/tabled/0.22.0/download` and its whole `src/` searched.
  `pub const fn markdown()` is declared in exactly one file (check `A4a`, the positive
  control that proves the tree is the right one), and the same tree contains **zero**
  `replace("|"` call sites and **zero** backslash-pipe escapes (checks `A4b`, `A4c`). A cell
  containing `|` silently breaks the table for every downstream consumer, which is AC10.
  Beyond the defect, the coupling is wrong in kind: `tabled`'s own README says "We often do
  breaking changes on minor version bump… It's likely better to depend on constant version
  e.g. `=0.8.0`" (checks `A6d`, `A6e`). Binding an interchange serialization's bytes to a
  presentation crate's minor releases is a defect waiting to happen.
- **ALT-3 (recommended) — an exporter seam: one result contract, one renderer per format,
  crates only where the format is genuinely hard.** JSON → `serde_json` (escaping and number
  formatting are hard). Aligned text → `tabled` (Unicode display-width segmentation is hard).
  Markdown → ~20 lines of `write!` with two escapes (easy, and pinning it to our own code
  makes its bytes ours). `name` → one `writeln!` per row. The marginal cost of the fifth
  format is one `fn render(&self, r: &dyn CliResult, w: &mut dyn Write) -> io::Result<()>` and
  one enum variant, which is ADR 0003's "third format is free" argument restated in Rust.
  This is also the shape of the closest maintained reference implementation: `sharkdp/hyperfine`
  (28,868 stars, not archived) ships JSON and CSV through crates and hand-rolls
  Markdown/AsciiDoc/Org-mode behind one `MarkupExporter` trait, declaring `csv = "1.3"` and
  `serde_json = "1.0"` and **no** table or Markdown crate at all (checks `A5d`, `A5e`, `A5f`).

**Why the aligned table takes a crate when Markdown does not.** The in-scope reason is
Unicode display width: a column-aligned table must measure the *rendered* width of a cell,
which is not its byte length and not its `char` count for CJK, combining marks or emoji.
Getting that wrong is a visible defect on every non-ASCII row, and it is the one part of the
`table` renderer that is genuinely hard. `markdown` and `name` need no width measurement at
all — GFM's delimiter row does not have to align — which is precisely why they are
hand-rolled and `table` is not. A second, out-of-scope reason reinforces the same choice:
R85 (`rich-terminal-row-niceties`, F359) will later layer OSC-8 hyperlinks onto `table` cells,
and width measurement must then skip ANSI sequences; `tabled`'s `ansi` feature exists for
that, and the most demanding adopter in the ecosystem configures it exactly so —
`nushell/nushell` (40,514 stars, pushed 2026-09-16) declares
`tabled = { workspace = true, features = ["ansi"], default-features = false }` in
`crates/nu-table/Cargo.toml` (check `A5a`). R85 is out of this item's scope and is not the
justification; it is the corroboration.

**Why `tabled` and not `comfy-table` — gate 2 is the discriminator, and it is a maintainer's
own statement.** On the popularity figures `comfy-table` is ahead (18,104,035 versus
8,766,630 recent downloads; 4 versus 101 open issues;
`snapshots/crates-2026-09-16.json`), and on semver posture it is ahead too (8.0.0 is post-1.0;
`tabled` is 0.22.0 and breaks on minor bumps). Neither declares a `rust_version` at all
(checks `A1m-tabled`, `A1m-comfy-table`), so the declared-MSRV half of gate 2 is a tie — both
fail it. What breaks the tie is each maintainer's *stated support policy*, read from their own
READMEs:

- `comfy-table`: **"Comfy-table is written for the current `stable` Rust version. Older Rust
  versions may work but aren't officially supported."** (checks `A6a`, `A6b`.) That is a
  direct conflict with the fixed `msrv-policy` parameter, which requires support two minors
  behind current stable. The template would be depending on a crate whose maintainer declines
  the very guarantee the parameter demands.
- `tabled`: **"Breaking MSRV considered to be a breaking change"** (check `A6f`), combined
  with "We often do breaking changes on minor version bump" and the direction to pin an exact
  version (checks `A6d`, `A6e`). Under the mandated exact pin `=0.22.0`, the MSRV floor is
  *frozen by the pin*: it cannot move without an explicit, reviewed version change.

So the crate with the worse semver hygiene is the one that fits the MSRV parameter, because
its breakage is opt-in at a pin and its maintainer treats MSRV as part of that contract.
`comfy-table` is the ranked runner-up, and the condition under which it wins is stated below.

**Workload, and why performance selects nothing here.** The result set is capped by `--limit`,
default **200** rows in both sources, over two display columns. At 200 rows every candidate's
serialization cost is microseconds and is dominated by one network round trip and by process
startup. **No benchmark was run for this decision, and no latency, throughput or allocation
figure is asserted for any candidate.** The honest statement is that this workload cannot
discriminate between them — which is exactly why the SIMD JSON crates (`sonic-rs`,
`simd-json`) that appear in the up-and-comer bin buy nothing here and are not shortlisted. The
resource costs that do matter are compile time and binary size, addressed qualitatively per
member below and measured in P03. The proposed measurement, if one is ever wanted: 100,000
synthetic rows with escaping-hostile cells, `--release`, each format rendered to a sink, 3
warmups and 20 measured runs, reporting latency, rows/second, output bytes, peak RSS and final
binary size, with CPU, Rust version, target triple and lockfile recorded.

**Landscape — the three-bin map.**

| Bin | Candidates found | Disposition |
|---|---|---|
| Built-in / first-party toolchain | `std::io::Write`, `std::fmt::Write`, `std::fs`, `write!`/`format!`; Cargo's own `--message-format json` | **Selected** for `markdown` and `name`, and for the `&mut dyn Write` seam every renderer writes through. Rust ships no output-format framework, so this bin is a real competitor here, not a placeholder — `hyperfine` ships three hand-rolled markup exporters this way |
| Established industry standard | `serde` + `serde_json`; `csv` (BurntSushi, RFC 4180); `tabled`, `comfy-table`; `tempfile`; also binned and not shortlisted: `serde_yaml` (max stable `0.9.34+deprecated`, the maintainer's own deprecation marker), `prettytable-rs` (last release 0.10.0, 2022-12-27) | `serde`, `serde_json`, `tabled`, `tempfile` selected; `csv` deferred with a named trigger; `comfy-table` is the ranked runner-up for one member |
| Up-and-comer | `sonic-rs`, `simd-json`, `cli-table`, `nu-table`, `term-table`, `csv-async` | None shortlisted. The SIMD JSON crates trade `unsafe` and CPU-feature detection for throughput this 200-row workload cannot use; the newer table crates have neither the adoption nor the ANSI-aware width handling |

**Authorities used, and why each is authoritative.** The org `cli-design-standard.md` v1.4.14
is the owner's own normative CLI standard, made binding for this template by the ruling of
2026-09-14, and this decision reads it at the blob R60 pinned (`f9de0437…`, check `C0c`), so
every `:<line>` citation here and in R60 refers to the same bytes. py's
`docs/design/0001-plbp-cli-conventions.md` and `docs/adr/0003-keep-markdown-output-mode.md`
are the maintainer's recorded requirement and decision for this exact surface — primary
evidence of intent, not inference. The Rust release channel manifest
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`) is the toolchain's own
statement of current stable. The GitHub Flavored Markdown spec, tables extension
(`https://github.github.com/gfm/#tables-extension-`) defines the dialect py's Markdown mode
targets and the rule that a literal `|` inside a cell must be backslash-escaped. RFC 4180
(`https://www.rfc-editor.org/rfc/rfc4180`) is the CSV specification the deferred `csv` crate
targets. Maintainer documentation (`docs.rs`, the `tabled` and `comfy-table` READMEs) supplies
each maintainer's own statement of behavior, MSRV posture and defaults. clig.dev is widely
cited independent guidance that py's own `output.py` module docstring names for the
stdout/stderr split. No single blog post is used as an authority anywhere in this decision.

**Practice evidence — the projects surveyed, and why each counts.** `nushell/nushell` (40,514
stars, not archived, pushed 2026-09-16): a shell whose entire premise is structured output, and
therefore the strongest available reference for a terminal table renderer; it drives every
table through `tabled` with `features = ["ansi"], default-features = false`.
`sharkdp/hyperfine` (28,868 stars, not archived): decides *the same question this item decides*
— which export formats a CLI offers — and answers it with crates for JSON and CSV and
hand-rolled markup exporters. `BurntSushi/rust-csv` (1,959 stars): the `csv` crate, whose
maintainer also wrote ripgrep, which establishes maintainer standing for the deferred
member. `Nukesor/pueue` uses `comfy-table` but shares an author with it, so it is weighted
down as self-adoption rather than independent uptake. `cargo` itself emits
`--message-format json` through `serde_json`, which is first-party precedent that machine
output is a serde serialization rather than a bespoke writer. All star, `archived` and
`pushed_at` values from `GET https://api.github.com/repos/<o>/<r>`,
`snapshots/crates-2026-09-16.json`.

### Members

Figures are from the endpoints the binding prompt names. Stable fields (newest un-yanked
version, declared `rust_version`, declared `license`, feature keys, `archived`, RustSec state)
are **asserted** by `review/evidence/r66-figures.sh`; download and star counters are
**recorded, not asserted**, in `review/evidence/snapshots/crates-2026-09-16.json`
(`retrieved_utc` `2026-09-16T02:42:36Z`), because they move continuously.

**Gate 1, for every member, is recorded once and applies to all of them:**
`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`.
Each member's declared licence is still *recorded* below as a fact, carrying no verdict.

**Gate 2's arithmetic, once, for all members.** Current stable is **1.98.1**, released
**2026-09-03** (`https://static.rust-lang.org/dist/channel-rust-stable.toml`:
`version = "1.98.1 (48a229cea 2026-09-01)"`, `date = "2026-09-03"`, retrieved 2026-09-16). The
two preceding minors are 1.97 and 1.96, so `msrv-policy` places the template's floor at
**1.96.0**. Edition 2024 independently requires ≥ 1.85. This matches the floor R60's published
decision resolved and locked against ("Locking 28 packages to latest Rust 1.96 compatible
versions").

**Gate 3's reading, once, for all members.** `https://rustsec.org/packages/<name>.html`
returns HTTP **404** for every crate in this stack and for `csv` and `comfy-table`. A 404 means
"no advisory page" only if the endpoint works, so two crates with published advisories are
queried as positive controls in the same run: `atty` and `time` each return **200** and each
page names at least one `RUSTSEC-` identifier (checks `A3c-atty`, `A3d-atty`, `A3c-time`,
`A3d-time`). The 404s are therefore evidence of no recorded advisory, not an unreachable
endpoint. What this does **not** establish is the advisory state of the *resolved dependency
tree*, which needs `cargo audit` against a real lockfile — recorded as unproven in `## Engines`.

#### serde 1.0.229

- **Landscape.** Bin 2. The established Rust serialization abstraction — a data-model layer,
  not a formatter. Not a CLI concern by itself; it is what lets one DTO serve the CLI's `json`
  renderer and the web tier without either owning the other's types.
- **Principles and implementation.** `#[derive(Serialize)]` sits on library-owned result DTOs,
  so the JSON encoder never depends on a CLI struct and the web tier reuses the same shape
  rather than shelling out. Cargo's own manifest depends on `serde` and `serde_json`.
- **Dominant choice.** Yes: 306,342,347 recent and 1,397,723,614 all-time downloads
  (`GET https://crates.io/api/v1/crates/serde`, snapshot). Fitness, not those figures,
  selected it.
- **Qualified shortlist.** `serde` alone. No alternative serialization abstraction was
  shortlisted: replacing the ecosystem's serialization boundary would expand scope with no
  R66 benefit.
- **Excluded by gate.** None.
- **Up-and-comers.** None proposed.
- **Fit for this template.** One explicit data model shared by CLI, library and web service;
  `derive` is a proc-macro compile cost with no runtime or async-runtime coupling.
- **Recommendation.** `serde = { version = "1.0.229", features = ["derive"] }`, declared in
  the library crate. `derive` is a real feature key of this version (check `A1f-serde`:
  `alloc,default,derive,rc,std,unstable`).
- **Ranked runner-up.** Inapplicable: this member supplies the shared serialization
  abstraction and no competing crate changes the Markdown-versus-CSV or flag-naming answer.
- **Tradeoffs.** Proc-macro compile time; the source contains `unsafe`, so the resolved tree
  needs an audit rather than an unsafe-free claim.
- **Fitness gates.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (declared `MIT OR Apache-2.0`, recorded). 2: declared `rust_version = 1.56`, forty minors below the 1.96 floor; the *resolved tree's* MSRV is P03's check. 3: RustSec 404 with controls; `unsafe` present in the crate's own source. 4: **not demonstrated by upstream CI** — `serde-rs/serde`'s `ci.yml` names `ubuntu-latest` and `windows-latest` and **no** `macos-latest` (check `A7-serde-rs/serde/master`, with `A7u-serde-rs/serde/master` confirming the file really is a matrix). Judged a qualified pass on Apple platforms being Rust tier 1 and on `serde` being a transitive dependency of essentially every macOS Rust build; the template's own `macos-latest` leg is the verification, and this is recorded as a caveat, not converted into a positive. 5: default feature `std`; `derive` opted in; no async-runtime coupling. 6: compile cost is the proc-macro expansion, paid once per DTO; binary-size impact is small and dominated by `serde_json`.
- **Maintenance state.** `active` — release 1.0.229 on 2026-07-18 (raw, 2026-09-05), repository
  pushed 2026-08-25, not archived (check `A2a-serde-rs/serde`).
- **Migration implications.** Add the dependency; derive `Serialize` on the DTO that backs the
  `json` renderer; do **not** derive on the presentation row type.
- **Validation strategy.** Planned, not run: build the locked graph at 1.96 on both runners;
  `cargo audit`; serialize the same DTO through the `json` branch and through the web tier and
  compare.
- **Confidence & re-verify.** Medium-high. Re-verify on a `serde` release, a declared-MSRV
  change, a RustSec entry, or the first locked dependency graph.
- **Sources.** `https://crates.io/api/v1/crates/serde`, `/versions`,
  `https://api.github.com/repos/serde-rs/serde`,
  `https://raw.githubusercontent.com/serde-rs/serde/master/.github/workflows/ci.yml`,
  `https://rustsec.org/packages/serde.html` — all 2026-09-16.

#### serde_json 1.0.151

- **Landscape.** Bin 2. The established JSON implementation paired with `serde`.
- **Principles and implementation.** `serde_json::to_writer` writes the DTO straight to the
  resolved destination writer, so JSON is never hand-built and never re-buffered for the file
  case beyond the render-then-persist rule.
- **Dominant choice.** Yes: 310,040,505 recent and 1,301,202,618 all-time downloads (snapshot).
  Cargo depends on it directly.
- **Qualified shortlist.** `serde_json` alone.
- **Excluded by gate.** None. `sonic-rs` and `simd-json` were binned as up-and-comers and
  excluded on fit, not on a gate: this workload cannot use their throughput and they add
  `unsafe` and CPU-feature detection.
- **Up-and-comers.** See above; none proposed.
- **Fit for this template.** The writer API maps exactly onto both destinations; default `std`
  suffices and `preserve_order` stays off, containing compile and dependency cost.
- **Recommendation.** `serde_json = "1.0.151"`, default features. Pretty or compact output is a
  P03 choice with one constraint from this item: whichever is chosen, `-o json` and `--json`
  must be byte-identical (AC2) and the document must end with a single `LF`.
- **Ranked runner-up.** Inapplicable: JSON is the required machine contract and no competing
  Rust JSON library offers a benefit this item can use.
- **Tradeoffs.** Parser/serializer compile cost; `unsafe` present in its own source.
- **Fitness gates.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (declared `MIT OR Apache-2.0`, recorded). 2: declared `rust_version = 1.71`, below the 1.96 floor. 3: RustSec 404 with controls; `unsafe` present. 4: **not demonstrated by upstream CI** — `serde-rs/json`'s `ci.yml` names `ubuntu-latest` and no `macos-latest` (check `A7-serde-rs/json/master`); same qualified-pass reasoning and same caveat as `serde`. 5: default `std`; optional features off; no async coupling. 6: the largest single compile-time and binary-size contributor in this stack, still small in absolute terms for a CLI.
- **Maintenance state.** `active` — release 1.0.151 on 2026-07-20 (raw, 2026-09-05), pushed
  2026-08-08, not archived (check `A2a-serde-rs/json`).
- **Migration implications.** Route the `json` branch through `to_writer`; document the JSON
  schema beside the library DTO, since R7.2 makes it stable within a major version.
- **Validation strategy.** Planned, not run: AC1, AC2, AC9, AC11, AC14 from the acceptance table,
  with `jq -e` parsing stdout while a warning is emitted to stderr.
- **Confidence & re-verify.** Medium-high. Re-verify on a release, a RustSec entry, a
  declared-MSRV change, or the first lockfile.
- **Sources.** `https://crates.io/api/v1/crates/serde_json`, `/versions`,
  `https://api.github.com/repos/serde-rs/json`,
  `https://raw.githubusercontent.com/serde-rs/json/master/.github/workflows/ci.yml`,
  `https://rustsec.org/packages/serde_json.html` — all 2026-09-16.

#### tabled =0.22.0

- **Landscape.** Bin 2, alongside `comfy-table`. Both render aligned terminal tables; both can
  also emit Markdown, and neither escapes the cell separator when it does.
- **Principles and implementation.** Drive it through `tabled::builder::Builder` from the
  columns/rows contract rather than through the `Tabled` derive, so the renderer stays
  presentation-only and the contract stays the single source of row data. `default-features =
  false, features = ["ansi"]` — the configuration `nushell` uses (check `A5a`).
- **Dominant choice.** Not dominant on figures: 8,766,630 recent downloads against
  `comfy-table`'s 18,104,035 (snapshot). It is selected on gate fit and on the strongest
  single adopter, and this decision says so rather than claiming a popularity win it does not
  have.
- **Qualified shortlist.** `tabled 0.22.0` and `comfy-table 8.0.0`.
- **Excluded by gate.** `comfy-table 8.0.0` is excluded **by gate 2**, on its maintainer's own
  statement: "Comfy-table is written for the current `stable` Rust version. Older Rust versions
  may work but aren't officially supported." (checks `A6a`, `A6b`) — incompatible with a fixed
  `msrv-policy` of stable minus two minors. It is retained as the ranked runner-up because the
  exclusion turns on a parameter, not on a defect. `prettytable-rs` is excluded on maintenance
  (last release 0.10.0, 2022-12-27; raw, 2026-09-10). Bin-3 table crates are excluded on fit.
- **Up-and-comers.** `cli-table`, `nu-table`, `term-table` — none has the adoption or the
  ANSI-aware width handling, and `nu-table` is a nushell internal that itself wraps `tabled`.
- **Fit for this template.** Correct Unicode display-width segmentation for column alignment is
  the in-scope need and the one genuinely hard part of the human table; the `ansi` feature is
  the seam R85 will need later.
- **Recommendation.** `tabled = { version = "=0.22.0", default-features = false, features = ["ansi"] }`.
  The exact pin is **mandatory, not stylistic**: the maintainer directs it ("It's likely better
  to depend on constant version e.g. `=0.8.0`", check `A6e`), and it is what freezes the
  undeclared MSRV.
- **Ranked runner-up.** `comfy-table 8.0.0`, configured `default-features = false` to keep
  `crossterm` out, adding `custom_styling` only if ANSI-aware widths are needed. **It wins if
  the owner changes `msrv-policy` to "latest stable only"** — which removes the only ground on
  which it is excluded — or if `tabled`'s breaking-minor policy proves unmanageable in the
  template's renovation lane. On today's parameters it loses; on that parameter change it
  wins outright, since it is ahead on downloads (18,104,035 versus 8,766,630), on open-issue
  count (4 versus 101) and on semver meaning (8.0.0 versus 0.22.0).
- **Tradeoffs.** Cost: a pre-1.0 dependency with a stated breaking-minor policy and no declared
  `rust_version`, held by an exact pin, so upgrades are manual by design. Benefit: correct
  Unicode width handling, proven by the most demanding adopter in the ecosystem, and a ready
  ANSI seam. Risk, stated plainly: **the flagship adopter's pin is `0.21`, not `0.22`** —
  `nushell`'s root manifest declares `tabled = { version = "0.21", default-features = false }`
  (check `A5c`, whose value is printed as a note, not asserted) and `0.22.0` was published only
  on 2026-09-05. This decision recommends the current max stable rather than the
  adopter-proven minor, and records the gap as a P03 verification rather than hiding it.
- **Fitness gates.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (declared `MIT`, recorded — note it is MIT-only, so unlike the rest of the stack it carries no Apache-2.0 patent grant; recorded as a fact with no verdict). 2: **declares no `rust_version` at all** (check `A1m-tabled`: `null`), as do `papergrid 0.18.0` and `tabled_derive 0.12.0`. The floor is met in fact but **not declared**; the compensating controls are the exact pin (which freezes it) and the template's own CI MSRV job, which `msrv-policy` requires independently. This is a **qualified** pass, and it is the weakest gate result in the stack. 3: RustSec 404 with controls; exactly one `unsafe` occurrence in the crate's own `src/` (counted during the ALT-2 inspection). 4: **CI-verified** — `zhiburt/tabled`'s `ci.yml` names `macos-latest`, `ubuntu-latest` and `windows-latest` (check `A7-zhiburt/tabled/master`). 5: `default-features = false` disables `derive`, `macros` and `assert`; only `ansi` and `std` are on; no async coupling. 6: the largest *new* compile-time cost in the stack after `serde_json` — three crates (`tabled`, `papergrid`, `tabled_derive`), reduced by disabling the derive feature; binary-size impact modest.
- **Maintenance state.** `active` — 0.22.0 published 2026-09-05, repository pushed
  2026-09-05, not archived (check `A2a-zhiburt/tabled`). The 101 open issues are recorded and
  are the reason `comfy-table` remains the ranked runner-up.
- **Migration implications.** One CLI-crate module for the `table` renderer; `Cargo.toml` gains
  one exactly-pinned dependency; CI gains the MSRV job `msrv-policy` already requires.
- **Validation strategy.** Planned, not run: a snapshot test of a fixed two-row result rendered
  twice — colour forced on and off — asserting identical column alignment, which is the
  property `ansi` exists to provide; plus a CJK/emoji row asserting the rendered width.
- **Confidence & re-verify.** Medium. Re-verify when `tabled` publishes 0.23, if `nushell`
  migrates away from it, if it declares a `rust_version` above the then-current floor, on any
  entry at `https://rustsec.org/packages/tabled.html`, or if `msrv-policy` changes — that last
  one hands the member to the runner-up.
- **Sources.** `https://crates.io/api/v1/crates/tabled`, `/versions`, `/0.22.0/download`,
  `https://api.github.com/repos/zhiburt/tabled`,
  `https://raw.githubusercontent.com/zhiburt/tabled/master/README.md`, `.../.github/workflows/ci.yml`,
  `https://raw.githubusercontent.com/nushell/nushell/main/crates/nu-table/Cargo.toml`,
  `https://raw.githubusercontent.com/nushell/nushell/main/Cargo.toml`,
  `https://raw.githubusercontent.com/Nukesor/comfy-table/main/README.md`,
  `https://crates.io/api/v1/crates/comfy-table/versions`,
  `https://rustsec.org/packages/tabled.html` — all 2026-09-16.

#### tempfile 3.27.0

- **Landscape.** Bin 2. The established crate for temporary files and atomic replacement.
- **Principles and implementation.** `NamedTempFile::new_in(parent_of_target)` then `persist`,
  so the rename is same-filesystem and therefore atomic. Rendering completes before `persist`,
  which is what makes AC12 true by construction.
- **Dominant choice.** Yes for this job: 180,327,332 recent and 811,034,428 all-time downloads
  (snapshot).
- **Qualified shortlist.** `tempfile` and hand-written `std::fs` + `std::fs::rename`.
- **Excluded by gate.** None.
- **Up-and-comers.** None proposed.
- **Fit for this template.** It closes a capability gap both sources have — neither py nor ts
  writes atomically (checks `C1f`, `C7e`) — and the standard asks for it as a `SHOULD` (`:226`,
  check `C9b`).
- **Recommendation.** `tempfile = "3.27.0"`.
- **Ranked runner-up.** Hand-written `std::fs` write-then-`rename`. **It wins if the workspace
  ends up wanting zero additional dependencies for this**, and it is not recommended: the same
  semantics with more code to get wrong, chiefly collision-free temp naming and permission
  handling.
- **Tradeoffs.** One small dependency against a correctness property that is easy to get
  subtly wrong. Note the coordination point in `## Parameters`: R52 needs the same mechanism
  for py's atomic config write, and R59 may need it for a log sink.
- **Fitness gates.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (declared `MIT OR Apache-2.0`, recorded). 2: declared `rust_version = 1.63`, below the 1.96 floor (check `A1m-tempfile`). 3: RustSec 404 with controls. 4: **CI-verified** — `Stebalien/tempfile`'s `ci.yml` names `macos-latest`, `ubuntu-latest` and `windows-latest` (check `A7-Stebalien/tempfile/master`). 5: default features; no async coupling. 6: negligible compile and binary cost.
- **Maintenance state.** `active` — pushed 2026-09-11, not archived, 5 open issues
  (check `A2a-Stebalien/tempfile`, snapshot).
- **Migration implications.** One `Destination` module in the CLI crate.
- **Validation strategy.** Planned, not run: AC12 needs fault injection (a renderer that fails
  mid-document), which is a test harness rather than a shell command.
- **Confidence & re-verify.** High. Re-verify on a release or a RustSec entry.
- **Sources.** `https://crates.io/api/v1/crates/tempfile`, `/versions`,
  `https://api.github.com/repos/Stebalien/tempfile`, `.../.github/workflows/ci.yml`,
  `https://rustsec.org/packages/tempfile.html` — all 2026-09-16.

#### The `markdown` and `name` renderers — no crate

- **Landscape.** Bin 1. `std::io::Write` and `write!`.
- **Principles and implementation.** `markdown` emits an optional `## title`, a header row, a
  `---` delimiter row and one row per record, escaping `|` and `\` in every cell and rejecting
  or replacing an embedded `LF`. `name` emits one identifier per line. Both read the **plain**
  rows, never the markup-carrying ones — the asymmetry py already implements and this decision
  verified (checks `C1h`, `C1i`).
- **Dominant choice.** The dominant *practice* is to hand-roll: `hyperfine` does exactly this
  behind one `MarkupExporter` trait and declares no Markdown crate (checks `A5e`, `A5f`).
- **Qualified shortlist.** Hand-rolled; a Markdown-table crate; a table crate's Markdown style.
- **Excluded by gate.** A table crate's Markdown style is excluded on the verified escaping
  defect (ALT-2, checks `A4b`, `A4c`). A dedicated Markdown-table crate is excluded on fit: it
  would add a dependency and a second stability surface to format fixed scalar cells.
- **Up-and-comers.** None proposed.
- **Fit for this template.** These bytes are the template's own contract, so owning the ~20
  lines that produce them is cheaper and safer than tracking a crate's minor releases.
- **Recommendation.** Hand-rolled, in the CLI crate, behind the same
  `fn render(&self, r: &dyn CliResult, w: &mut dyn Write) -> io::Result<()>` seam as the other
  two. **Be stricter than the reference implementation**: `hyperfine`'s exporter performs no
  escaping at all (check `A4f`), and py's single `|` escape (check `C1j`) is the floor, not the
  ceiling — `\` and embedded newlines need handling too.
- **Ranked runner-up.** A Markdown-table crate. **It wins if the template ever needs to emit
  arbitrary Markdown** — nested lists, inline HTML, reference links — rather than one flat
  table. It does not today.
- **Tradeoffs.** ~20 lines this repository maintains and must test adversarially, against zero
  dependency, zero compile cost and bytes that cannot change under it.
- **Fitness gates.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (no third-party licence involved; the code is this repository's own, under its declared `MIT OR Apache-2.0`). 2: `std` only; no MSRV beyond the edition's 1.85 and the template's 1.96 floor. 3: no advisory surface; `#![forbid(unsafe_code)]` is expected in the CLI crate and costs nothing here. 4: `std::io` and `std::fmt` are portable across both runners; nothing platform-specific is used. 5: no features, no async coupling. 6: negligible on both compile time and binary size.
- **Maintenance state.** `inapplicable` — this member is template-owned code, not a third-party
  crate, so the maintenance rubric has no subject.
- **Migration implications.** Two small CLI-crate modules plus the shared columns/rows
  contract they read.
- **Validation strategy.** Planned, not run: AC10 and AC11 against an adversarial row whose cell
  is `a|b\c"d` followed by an embedded newline; a GFM-structure assertion that the header and
  delimiter rows have equal column counts and that a hostile cell cannot add a column.
- **Confidence & re-verify.** High. Re-verify if GFM's table grammar changes or if the
  template starts emitting non-table Markdown.
- **Sources.** `https://github.github.com/gfm/#tables-extension-`,
  `https://raw.githubusercontent.com/sharkdp/hyperfine/master/src/export/markdown.rs`,
  `https://raw.githubusercontent.com/sharkdp/hyperfine/master/Cargo.toml`,
  `py@b08bccfb:src/py_launch_blueprint/cli/output.py:241-256` — all 2026-09-16.

#### csv 1.4.0 — evaluated, deferred, not in the stack

- **Landscape.** Bin 2. BurntSushi's RFC 4180 implementation, and the correct answer *if* CSV
  ships.
- **Principles and implementation.** `WriterBuilder`'s defaults already implement RFC 4180
  minimal quoting, so a CSV renderer would be a thin pass over the plain rows. ts hand-rolls
  its quoting instead (`csvField`, `ts@cb1cbcb2:src/lib/format.ts:21-27`) and documents that as
  a deliberate improvement on the legacy py CLI's "naive-by-design" CSV.
- **Why it is deferred rather than shipped.** Three reasons, none of which is "ts is wrong".
  (i) **Provenance**: ts's `csv` is the legacy py CLI's `csv` carried through a faithful port
  (checks `C5b`, `C6a`), not an independently evidenced choice — the same stale-port mechanism
  that produced the flag collision. (ii) **Job coverage**: `json` already serves the general
  machine job and `name` serves the shell-composition job; CSV's distinct job is spreadsheet
  and data-frame import, for which this template has no recorded requirement. (iii) **Cost**:
  a second flat-schema contract, a fourth renderer, and a formula-injection policy for
  untrusted cells that no other format needs. Two of the three raws reach the same conclusion;
  the third argues for shipping it, and `## Engines` records that disagreement.
- **Fitness gates, answered anyway so the trigger needs no new research.** 1: `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool` (declared `Unlicense/MIT`, recorded). 2: declared `rust_version = 1.73`, below the 1.96 floor (check `A1m-csv`). 3: RustSec 404 with controls. 4: **CI-verified** — `BurntSushi/rust-csv`'s `ci.yml` names `macos-latest`, `ubuntu-latest` and `windows-latest` (check `A7-BurntSushi/rust-csv/master`). 5: no declared feature set; no async coupling. 6: small compile and binary cost.
- **Maintenance state.** `stable-quiet` — last release 1.4.0 on 2025-10-17 (raw, 2026-09-05),
  which is more than six months ago and so triggers investigation rather than a verdict; the
  repository was pushed 2026-08-04 and is not archived (check `A2a-BurntSushi/rust-csv`), and
  no concrete at-risk signal exists, so the rubric returns `stable-quiet`.
- **Trigger.** A recorded requirement for spreadsheet or data-frame import. On that trigger,
  add `csv = "1.4.0"` and a fifth enum member; do not hand-roll it.

### Compatibility of the members

`serde` and `serde_json` are version-compatible by construction and are resolved together in
Cargo's own workspace, which depends on both. `tabled` and `tempfile` share no types with
either and touch the seam only through `&mut dyn Write` and `std::fs`, so the composition is
structural rather than version-coupled: the four members meet at exactly two points — the
columns/rows contract (which the renderers read) and the destination writer (which they write
to). `hyperfine` is the shared-adopter proof for the *pattern* — it composes `serde`,
`serde_json` and a crate-free markup exporter behind one trait in a shipped binary
(checks `A5e`, `A5f`) — while `nushell` is the adopter proof for `tabled` in that role
(check `A5a`). **No single maintained repository composes all four of these exact crates**, and
that gap is recorded as unproven in `## Engines` rather than papered over; the resolved-together
proof is a `cargo generate-lockfile` plus `cargo tree -d` in P03, exactly as R60 and R67 ran
for their own stacks.

re-verify: 2027-03-16, or earlier on any of — the org CLI Design Standard moving off the pinned
blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, which check `C0c` detects and which would
invalidate every `:<line>` citation here; an amendment to R3.2, R3.9, R4.1, R4.2, R7.1, R7.2,
R7.3, R7.7, R7.8 or R10.3; `tabled` publishing 0.23 or declaring a `rust_version` above the
then-current floor, or `nushell` migrating away from it; a RustSec advisory opening against
`serde`, `serde_json`, `tabled`, `papergrid`, `tabled_derive` or `tempfile`; Rust stable
advancing far enough that the floor rises above 1.71, the highest declared `rust_version` in
the stack; `msrv-policy` changing to "latest stable only", which hands the table member to
`comfy-table`; a recorded requirement for spreadsheet import, which adds `csv 1.4.0` as a
fifth format; R85 resolving in a way that needs a row accessor this contract does not provide;
or R60 being reopened, which would happen only if this item had left no format-selection flag
acceptable at the root — it has not.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's `- owns:` and `- consumes:` lines in the prompt's `## Couplings` are both empty
(checks `C11a`, `C11b`), so it registers no parameter value and consumes none. F291, F292 and
F293 are ledger rows, not registry parameters; their answers are stated in `## Decision` rather
than registered. `docs/port/PARAMETERS.md` carries no output-format row (check `C10i`), which
is why R60 records its coupling to this item as `related (not a registry dependency)` and why
**no `CONFLICT:` line is raised or is even possible**: a `CONFLICT:` line names a *consumed*
parameter that must change, and this item consumes none. Nothing recommended here requires a
fixed owner parameter to change.

How the four fixed parameters bear on the decision. **`msrv-policy` is the only parameter that
changes an answer**, and it changes one: it excludes `comfy-table 8.0.0` by its maintainer's
stated current-stable-only support policy, and it is the reason `tabled`'s exact pin is
mandatory rather than stylistic. Resolved against the toolchain manifest on 2026-09-16 it puts
the floor at **1.96.0**; the highest declared `rust_version` in the recommended stack is
**1.71** (`serde_json`), so the stack has twenty-five minors of headroom, while `tabled`,
`papergrid` and `tabled_derive` declare none at all and are held by the pin plus the CI MSRV
job. **`license`** excludes nothing: it fixes this repository's own declared expression, and the
owner's ruling of 2026-09-12 (Q7.B) strikes licence compatibility as an evaluation criterion
for any dependency or tool. Each member's declared licence is recorded as a fact with no
verdict — `MIT OR Apache-2.0` for `serde`, `serde_json` and `tempfile`, `MIT` for `tabled`,
`Unlicense/MIT` for the deferred `csv`. **`target-os-matrix`** is satisfied by `tabled`,
`tempfile` and `csv` with macOS explicitly in their own CI, and is a *qualified* pass for
`serde` and `serde_json`, whose upstream matrices name no macOS leg; that caveat is recorded
per member and is not converted into a positive. **`rust-edition = 2024`** has no consequence
for this surface beyond requiring ≥ 1.85, which the 1.96 floor already exceeds; each member's
own edition constrains only its own source.

**Two coordination notes, deliberately not raised as conflicts** — no registered parameter
exists for either. First, the `serde` version and feature set are workspace-wide and will also
be consumed by R52 and R53; they should be decided once at the workspace level. Second,
`tempfile` is the same atomic-replacement mechanism R52 needs for the config write and R59 may
need for a log sink. **One observation for the controller, not a registration**: the flag
contract decided here is read by at least three other items (R60 declares the flags, R67
renders its envelope under the selected format, R85 extends the text row shape). If the
registry ever wants a named parameter for it, the value would be
`-o|--output <table|json|markdown|name>; --output-file <path|-> (long-only, silent overwrite, atomic, --no-clobber); --json ≡ -o json, both explicit → exit 2`.
Registering it is the controller's call, not this decision's.

## Empirical check

**Toolchain and host.** `Darwin 25.4.0 arm64`; `bash 3.2.57(1)-release`;
`git version 2.50.1 (Apple Git-155)`; `/usr/bin/grep` is `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`;
`curl 8.7.1`; `jq-1.8.2`. **No Rust toolchain was used and none is required**: this item
recommends an interface contract and four version pins, and the template it would be built
into does not exist. `rustc --version` and `cargo --version` are therefore reported as
**inapplicable to this item's checks** — no check compiles, resolves or links anything, and
`find` over this run directory returns no `.rs`, `Cargo.toml` or `Cargo.lock` file. The
recommendation was **not implemented**: no renderer, no seam, no scaffold and no fixture beyond
the one published `.crate` tarball an inspection needed as input.

**Working directory.** `/Users/stevemorin/c/rs-launch-blueprint-p02-plan`, branch
`research/p02-execution`. Both scripts derive their root from their own path
(`SCRIPT_DIR/../../../../../..`) and assert a sentinel, never `git rev-parse`, which fails
inside a `git archive` extraction.

| Script | Log | Command | Exit | Result |
|---|---|---|---|---|
| `review/evidence/r66-sources.sh` | `review/evidence/r66-sources.log` | `bash review/evidence/r66-sources.sh` | **0** | `CHECKS RUN: 89   FAILURES: 0` |
| `review/evidence/r66-figures.sh` | `review/evidence/r66-figures.log` | `bash review/evidence/r66-figures.sh` | **0** | `CHECKS RUN: 91   FAILURES: 0` |

Both scripts begin with `set -o pipefail`. Neither uses a pipeline whose exit status could mask
a failed producer: `git show` writes to a file and its status is tested separately, and every
`curl` reports its HTTP status through `-w '%{http_code}'`, which is asserted equal to the
expected code. Every check asserts on **content** — an exact line, an exact fixed string, a
counted absence, or an expected HTTP status — never on an exit code alone.

**What the source check establishes** (`r66-sources.sh`, 89 checks, offline and deterministic).
The pins resolve and the standard's blob is `f9de0437baece3383e73ca2c5f48b7ab399b51c7` with
version line `| **Version** | 1.4.14 |` (`C0a`–`C0d`); both py ancestors this decision cites
are genuinely ancestors of the py pin, and a foreign commit is correctly reported as not one
(`C0e`–`C0g`). py at the pin has `class OutputMode(StrEnum):` at `:47` with `TEXT`, `JSON`,
`MARKDOWN` and **no** `CSV`; declares `-o`/`--output` at `:57-58`, `--json` at `:66` documented
as "Shorthand for --output json.", and `--output-file` at `:72` documented as the destination;
has **no** `--format` flag; resolves `--json` by silent precedence; writes the destination file
by truncation; feeds `table_rows_rich()` to the text renderer and the plain `table_rows()` to
the Markdown renderer; and escapes a literal `|` in every Markdown cell (`C1`–`C2h`, `C1h`–`C1j`).
py's design 0001 Appendix D directs the rename and states its reason, and ADR 0003 is Accepted
2026-06-09 with its use case, its cost argument and its rejected alternative (`C3`–`C4e`). The
legacy py CLI at `f587e48^` declares `--format` with `["text","json","csv"]` and `--output` as
the file sink, with no `--output-file` and no markdown (`C5`–`C5e`). ts at the pin names
`format_output (projects.py:273-291)` as its source, documents `text` as bare IDs for shell
composability, declares `['text','json','csv']`, returns joined IDs, declares `--format`,
`--json` with `.conflicts('format')` and `--output <file>`, records the divergence in a source
comment, and writes non-atomically (`C6`–`C7e`). D-033's heading is about prompt interrupts and
its `Options:` list contains no flag-naming option (`C8`–`C8e`). Thirteen clauses of the
standard are asserted verbatim, plus one negative control that the standard does **not** make
`--format` the selector (`C9a`–`C9n`). R67's two assignments to this item, R60's three
compatibility requirements and the registry's silence on an output-format row are each asserted
(`C10`–`C10j`), as are the prompt's empty `- owns:` and `- consumes:` lines (`C11a`, `C11b`).

**What the figure check establishes** (`r66-figures.sh`, 91 checks, live endpoints). In this
paragraph only, a trailing `*` names a **family** of check ids rather than one id: `A1*` means
every check id printed with that prefix, each of which carries its own subject in full — for
example `A1m-tabled`. Everywhere else in this decision a check id is quoted in full and can be
grepped literally out of a log. For six
crates, the newest un-yanked version, its declared `rust_version`, its declared `license` and —
where the decision relies on them — its feature keys (`A1*`). For eight repositories, HTTP 200
and `archived = false` (`A2*`). RustSec returns 404 for all six candidate crates while the two
positive controls return 200 and name `RUSTSEC-` identifiers (`A3*`). The `tabled 0.22.0`
tarball extracts, declares `pub const fn markdown()` in exactly one file, and contains zero
pipe-escape sites; `hyperfine`'s Markdown exporter still carries the cell join this decision
quotes and performs no replacement (`A4*`). `nushell` still configures `tabled` with
`features = ["ansi"], default-features = false` and still declares a workspace pin, and
`hyperfine` still declares `csv` and `serde_json` and no table or Markdown crate (`A5*`). Both
table maintainers' MSRV and semver statements are asserted verbatim (`A6*`). Each crate's own
CI matrix is checked for `macos-latest`, with a `ubuntu-latest` control on the same file so a
zero macOS count cannot come from an empty or wrong file (`A7*`).

**Reproduction, actually re-run rather than asserted.** Both scripts were re-run after their
logs were written and diffed against them: `diff` reports **no differences** for either, so both
logs are reproducible **byte-for-byte** as of 2026-09-16. Both were then run again from a clean
`git archive HEAD` extraction in a temporary directory, with only the two scripts copied in:
each again exited `0` with the same check counts, and the **only** differing line in either log
is the printed `ROOT:` path, which is the extraction directory rather than the worktree. That
is the rule for comparing across environments: `ROOT:` is environment-dependent by design;
every other line is not.

**Volatility, and what is deliberately not asserted.** Download counters, star counts and
`pushed_at` move continuously, so `r66-figures.sh` never prints them and never asserts them.
The dated figures quoted in `### Members` come from
`review/evidence/snapshots/crates-2026-09-16.json`, written once by
`bash r66-figures.sh --record` with `retrieved_utc` `2026-09-16T02:42:36Z` and committed beside
the scripts. A default run does not touch that file; only `--record` rewrites it, so an
auditor's rerun cannot silently invalidate the snapshot it is checking against. One further
value is printed as a **note rather than an assertion**: `nushell`'s workspace `tabled` pin
(`A5c` asserts only that a pin exists), because that value is expected to move and this
decision's own text says it currently differs from the recommended version.

**Evidence that the harness can fail.** A check that cannot fail is not evidence, so this was
demonstrated three ways rather than claimed. (i) During authoring, `r66-figures.sh` **failed
twice** against expected values taken from the raw reports: `serde`'s feature keys were
asserted as `alloc,default,derive,rc,serde_derive,std,unstable` and the endpoint returned
`alloc,default,derive,rc,std,unstable`, and `csv`'s licence was asserted as `Unlicense OR MIT`
and the endpoint returned `Unlicense/MIT`. Both expectations were corrected to the observed
values; the committed script carries the corrected ones. (ii) A copy of `r66-sources.sh` with
one expected line mutated (`class OutputMode(StrEnum):` → `class OutputMode(Enum):`) was run in
place and reported exactly `FAIL C1a … expected [class OutputMode(Enum):] got [class
OutputMode(StrEnum):]` with `CHECKS RUN: 89   FAILURES: 1`; the copy was deleted and is not
committed. (iii) A copy with the standard's expected blob replaced by forty zeros failed `C0c`
with both hashes printed. The scripts as committed pass; they pass because the content is what
they say it is.

**No personal email address appears in any script, log, snapshot or header.** The `User-Agent`
sent to every endpoint is
`rs-launch-blueprint-research (https://github.com/smorinlabs/rs-launch-blueprint)`.

## Engines

- codex `raw/codex-8bb6524e4a46045461dc9034e4300bd35b2b891813f6e59af4c2343d28844939.md` (`raw/codex.md`), model `gpt-5.6-terra` via `codex-cli-0.153.2`, collected 2026-09-06, sha256 `8bb6524e…`.
- opus `raw/opus-cdc6388169cf9fcc5010aac3744b5f092c9faa3dafbe7b8a0b0cff66526817bf.md` (`raw/opus.md`), model `claude-opus-5`, collected 2026-09-10, sha256 `cdc63881…`.
- doxa `raw/doxa-openai.normalized.md`, model `openai gpt-5.6-sol` (reasoning_effort max, web_search, max_tool_calls 80), operation `research-20260909-003306-9390be364d324b9d`, collected 2026-09-09.

**Two of the three Doxa providers are missing, by the owner's ruling.** The Doxa operation
`research-20260909-003306-9390be364d324b9d` recovered **OpenAI only**. Perplexity
(`sonar-deep-research`) refused at submission with "perplexity API rate limit exceeded" —
four `sonar-deep-research` jobs were already in progress when this fifth submission was made
within 17 seconds of the first — and **no Perplexity job was ever created**, confirmed against
the async inventory; **Gemini (`deep-research-preview-04-2026`) was never attempted**. On
2026-09-15 the owner accepted a single paid provider for this item, so the missing subset is
not retried. The consequence is stated plainly: this item's Doxa input is one model's answer,
not a three-provider consensus, and nothing below claims agreement broader than the three
reports plus this decision's own source reading. The failure checkpoint is preserved at
`operations/doxa-checkpoint-at-failure.json`.

**Disagreement 1 — the flag split. Settled against Doxa, on the binding standard.** Codex and
Opus both recommend `-o`/`--output` for format and `--output-file` for the destination. Doxa
recommends the opposite: `--format` for representation with no short form, and `-o`/`--output`
as the file sink, citing the GNU coding standards' `-o`/`--output`-means-output-file convention
and ts's D-033. Doxa's reasoning is coherent and its GNU citation is real — but it is answering
a question the owner has since closed. The ruling of 2026-09-14 makes the org
`cli-design-standard.md` binding on this template, and that document's R4.2 is a `MUST` that
`-o`/`--output` be the format selector and R3.2 is a `MUST` that the destination flag be
`--output-file`, long-only, and **MUST NOT** reuse `--output`/`-o` (checks `C9a`, `C9d`). Doxa
also proposes "do not add `--output-file` to the new Rust CLI", which is the exact spelling the
standard mandates. Adopting Doxa would require an `OVERRIDE` against two `MUST`s with no
argument stronger than an external convention the owner's own standard already considered and
rejected — its R3.2 ❌ example is literally `acme report build -o -`. **Settled by:** the
standard at its pinned blob, plus the source history in Disagreement 2, which shows Doxa's
chosen split is itself the stale side of the port.

**Disagreement 2 — is ts's split an adjudicated decision or stale-port drift? Settled as
drift, on evidence none of the three raws is needed to believe.** The ledger and
`docs/port/DIVERGENCE-ANALYSIS.md:207` record ts's `--format`/`--output` as "already
adjudicated" by D-033, and Doxa treats it as precedent to preserve. Opus argues it is stale
drift. This decision **verified Opus's claim itself**, at the pins, rather than carrying it:
the legacy py CLI declared ts's exact surface (`C5a`–`C5c`); ts's own header names that file as
its source (`C6a`); py's design spec directed the rename *before* ts existed and said why —
"resolve before it spreads across tools" (`C3a`, `C3b`); and D-033's `Options:` list contains
three prompt-cancellation options and no flag-naming option at all (`C8c`–`C8e`), so the flag
sentence in its `Why` is a carried-forward parity note, not an adjudication. The two
`BASELINE-REVIEW:` lines above carry this to the controller. **Settled by:** four independent
pinned reads, each with a named check id.

**Disagreement 3 — `csv`: ship it, or defer it? Settled as deferred, with Opus dissenting.**
Codex recommends `table|json|markdown` and explicitly does not support CSV in v1. Doxa
recommends `text|json|markdown` and would add CSV only after "an observed spreadsheet
acceptance test", naming `csv 1.4.0` for that day. Opus recommends **all four**, arguing that
dropping `csv` deletes a shipped capability from ts to no benefit and that ADR 0003's
zero-marginal-cost argument applies equally to a fourth format. Opus's argument is the
strongest case for shipping it and is not dismissed: the marginal code cost genuinely is one
renderer. It loses on provenance and on contract count. ts's `csv` is the legacy py CLI's
`csv` carried through a faithful port (`C5b`, `C6a`) — the *same* stale-port mechanism this
decision rejects in Disagreement 2 — so treating it as an independently evidenced capability
would accept on one row what is rejected on the other. And a fifth format is not free at the
contract level even when it is nearly free at the code level: it adds a flat-schema commitment
and a formula-injection policy for untrusted cells. **Settled by:** 2 of 3 raws plus the
provenance evidence; the trigger and the crate are recorded so the reversal needs no new
research.

**Disagreement 4 — a crate for the aligned table, or hand-rolled? Settled for `tabled`,
against 2 of 3 raws.** Codex proposes "a bounded internal table function" and Doxa proposes
internal renderers over `std::io::Write`; only Opus surveys table crates at all. The majority
is **not** followed here, and the reason is specific rather than deferential: neither Codex nor
Doxa addresses Unicode display width, which is the one genuinely hard part of column alignment
and the part that is silently wrong on every CJK or emoji row if hand-rolled. py does not
hand-roll it either — it uses `rich.Table` (`.../output.py:230-238`), a library. Within the
crate choice, this decision then departs from Opus's framing as well: Opus left
`tabled`-versus-`comfy-table` to owner preference, and this decision resolves it on gate 2
using each maintainer's own stated support policy (checks `A6a`, `A6b`, `A6f`), which is
evidence rather than preference. **Settled by:** the in-scope width requirement, `nushell`'s
verified configuration, and a gate-2 tie-break from primary sources. **This is the decision's
most contestable member**, and its runner-up and reversal condition are stated in full.

**Disagreement 5 — `text` or `table` as the default's name? Settled as `table`, against
Opus.** Codex proposes renaming the default to `table`; Opus explicitly declines, arguing
`text` is the one spelling both sources already use and that R4.2's `MUST` concerns the
*selector* rather than the enum values, and it routes the deviation to a conformance note.
Doxa keeps `text` without discussing the point. `table` is adopted because R4.1's result-output
row names the enum members with the tier's `MUST` wording — "each with exactly these names and
meanings" — and gives `table` as the default human format (check `C9c`), and because R7.2 and
R7.8 are both written in terms of that vocabulary: `-o table` is named as the human default at
`:385` and `-o name` as a machine format at `:257`. Choosing `text` would require a conformance
note and an `OVERRIDE`; choosing `table` costs one string in documentation that does not yet
exist, since this template has no released invocations to break. **Settled by:** the standard's
own vocabulary, and the fact that the cost of conformance here is zero for a template that
has not shipped.

**Disagreement 6 — what does a RustSec 404 mean? Settled as "no advisory", against Codex.**
Codex records the 404s as leaving advisory state **unverified** and declines to treat them as
evidence, which is the correct default. Opus resolves it by querying two crates known to carry
advisories and observing HTTP 200. This decision re-ran that control in its own script rather
than carrying the result: `atty` and `time` each return 200 and each page names at least one
`RUSTSEC-` identifier (`A3c-atty`, `A3d-atty`, `A3c-time`, `A3d-time`). A 404 is therefore
evidence of no recorded advisory
for that package. **Settled by:** a positive control executed in the same run as the negatives.

**Disagreement 7 — must the destination write be atomic? Settled yes, against Doxa.** Doxa
recommends `std::fs::write` and states that "atomic replacement against disk or process failure
is not promised by this item". Opus recommends `tempfile` temp-plus-rename; Codex's acceptance
list expects "ordinary `--output-file` overwrites atomically". The standard asks for it as a
`SHOULD` — "**SHOULD** write atomically (temp + rename)" (`:226`, check `C9b`) — and declining
a `SHOULD` requires a recorded waiver, which Doxa does not supply. Doxa's render-first ordering
is nevertheless adopted, because it is the half that protects the previous file from a
*rendering* failure; `tempfile` adds protection against process and system failure on top.
**Settled by:** the standard's `SHOULD` plus the fact that both sources' non-atomic writes
(`C1f`, `C7e`) are a verified capability gap rather than an ecosystem difference.

**Where this decision goes beyond every raw, stated so it is not mistaken for a carried
finding.** Adding **`name`** to the enum is this decision's addition. Opus found the underlying
fact — ts's `text` is bare identifiers, not py's table — and deliberately left `name` out of
its own `### Recommendation`, offering it as an owner option on the ground that the prompt
asked about a *third* format rather than a fifth. Neither Codex nor Doxa mentions it. It is
adopted here because the fact is verified at the pin (`C6b`, `C6d`), because `name` is one of
R4.2's own enum members (`C9f`) and so costs nothing in conformance, because it is one
`writeln!` per row in code, and because without it ts's shell-composability consumers would
silently receive an aligned table where they expect identifiers. The classification of
`markdown` as a **human** format with one escaping invariant held above that class is likewise
this decision's, not any raw's.

**Unproven — what this decision could not verify, and what would prove it.**

| # | Claim not established | What would prove it |
|---|---|---|
| U1 | The **resolved dependency tree's** MSRV and advisory state. Only each crate's own declared `rust_version` was read; `tabled`, `papergrid` and `tabled_derive` declare none at all | `cargo generate-lockfile` at the 1.96 floor, then `cargo metadata --format-version 1 --all-features \| jq` for the highest declared `rust-version`, `cargo tree -d` for duplicate resolutions, and `cargo audit` — the same three commands R60 and R67 ran for their stacks. P03, in the real template |
| U2 | That `serde` and `serde_json` build and test on `macos-latest`. Their upstream CI matrices name no macOS leg (checks `A7-serde-rs/serde/master` and `A7-serde-rs/json/master`); the pass is judged on tier-1 platform status, not demonstrated | the template's own `macos-latest` CI leg, green, in P03 |
| U3 | That `tabled 0.22.0` compiles at the 1.96 floor. It declares no `rust_version`, so nothing states its floor, and `0.22.0` is ten days old | `cargo +1.96.0 check --locked` on both runners in P03; if it fails, either raise the pin or take the runner-up |
| U4 | That `=0.22.0` is the right minor. The flagship adopter `nushell` pins `0.21` (`A5c`, printed as a note) | P03 re-reads `nushell`'s pin and `tabled`'s release history at implementation time and pins whichever minor is both current and adopted |
| U5 | That the four members compose in one real binary. No single maintained repository was found using all four together; `hyperfine` proves the *pattern* and `nushell` proves `tabled` in this role | a building template with all four dependencies and the acceptance suite green — P03 |
| U6 | Every behavioral criterion AC1–AC16. **None was run**: there is no binary to run them against | the acceptance suite in P03, as `trycmd`/`assert_cmd` cases, except AC12 which needs a fault-injection test harness |
| U7 | Any performance figure. **No benchmark was run and none is asserted** | the measurement described in `### Principles and implementation`, if a figure is ever wanted; nothing in this decision turns on one |
| U8 | Issue-responsiveness medians. The prompt's figure table asks for a median days-to-first-maintainer-response over the ten newest issues; this decision records open-issue **counts** (snapshot) and did not compute the medians. Codex computed them for `serde`, `serde_json` and `csv` on 2026-09-05 and found no qualifying maintainer comment on 10/10 for the two Serde crates | re-running Codex's recent-ten issue-comment query for all six candidates. It is recorded as a gap rather than carried, because it did not affect any gate or any selection: no member was chosen or excluded on responsiveness |

**What P03 must validate.** U1 through U6, in that order; the AC1–AC16 acceptance suite as the
template's own integration tests; the `--json`/`-o` presence-based conflict against whatever
R60's framework declares; R60's AC3 (`<tool> --version -o json`) now that this item has named
the spelling; and R67's AC1/AC2 through this item's writer, including this item's own AC15
(the broken-pipe path) and AC14 (the error-envelope-by-format-class rule).
