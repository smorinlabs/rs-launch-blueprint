# R85 — rich-terminal-row-niceties (pattern, Focused)

## Decision

**Yes**: `rs-launch-blueprint`'s text-mode table renderer adds terminal-only
presentation niceties — OSC-8 hyperlinks and relative timestamps — on top of the plain
row data, and it is the only renderer that may. The recommended pattern is the
**capability-gated rich row variant**, placed in the CLI crate:

1. **Hook.** A `TableView` trait in the CLI crate with `columns()`, `rows()` and a
   *provided* (default-bodied) `rows_rich(&self, caps: TermCaps) -> Vec<Vec<String>>`
   whose body is `self.rows()`. A view type that has nothing to decorate inherits the
   plain rows with no code. Only the text renderer names `rows_rich`; the JSON renderer,
   the third format (R66's choice) and the web crate use `rows()` or serialize the domain
   type directly. This is the Rust translation of py's `table_rows_rich()`
   (`core/models.py:59-67` at pin `b08bccfb`), with two amendments recorded below.
2. **Hyperlinks.** `anstyle-hyperlink` **1.0.2** with its non-default `file` feature,
   gated by `supports-hyperlinks` **3.2.0** combined with whatever color choice R65
   resolves. Build the cell as `format!("{h}{label}{h:#}")` where `h` is
   `Hyperlink::with_url(url)` when the capability is present and `Hyperlink::default()`
   when it is not; `Default` renders zero bytes, so the same call site produces a plain
   cell off-terminal. This is Cargo's own composition.
3. **Escaping.** Percent-encode every URI (`anstyle_hyperlink::path_to_url` for
   filesystem paths; a `percent_encoding` set that at minimum adds `CONTROLS` and space
   for other URLs) and control-escape every label before it enters a cell.
   `anstyle-hyperlink` does not sanitize a URL handed to `with_url` — it writes it
   verbatim — so both guards are the template's obligation, not the crate's.
4. **Relative time.** A small in-tree helper in the CLI crate transliterating py's bucket
   table and `"just now"` floor (`core/format.py:36-70`), pinned by py's own
   `relative_time` assertions (`tests/core/test_format.py:11-33`). `timeago` 0.6.1 with
   `default-features = false` is the ranked runner-up, and wins if the owner does not
   require string parity with py (see `## Engines`).
5. **A requirement on R66 that this item's empirical check produced.** The decorated cell
   is an ordinary `String` handed to the table crate, so the table crate must measure it
   without counting the escape bytes or the URL. At the versions read on 2026-09-10 this
   holds **only when the crate's ANSI-width feature is enabled**: `comfy-table` 8.0.0
   needs `custom_styling`, and `tabled` 0.22.0 needs `ansi`. Under default features both
   measure the raw string with `unicode-width` and count every printable character of the
   URL. The feature governs the width path through each crate's `measure_text_width` /
   `get_line_width`; it does **not** cover `comfy-table`'s `ContentArrangement::Dynamic`
   allocation heuristic, which measures cell content with `unicode-width` directly
   (`## Empirical check`, item 1). R66 selects the table crate; this item requires that
   whichever it selects be built with that feature on, and that P03 assert the property
   against the arrangement mode R66 also selects (`## Engines`, item 1).

**Ledger rows settled.** `F359` (`docs/port/COMMONALITY.md:363`), verdict `DIVERGENT` —
py ships a rich row variant, ts ships nothing comparable. The verdict is unchanged by
this decision; the decision supplies the Rust design that realizes the same capability
and the rationale a later py/ts follow-on project would use. No `BASELINE-REVIEW:` line
is emitted (see `## Engines`, Disagreement 3).

**Status of this decision.** It is a **proposal validated in the implementation phase**
(owner ruling, 2026-09-10). It records what the research found and what it recommends;
P03 builds the template and its CI proves the recommendation. `## Engines` lists what P03
must validate. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

### Principles and implementation

**Shared requirement, its source, and the level at which agreement is required.**

| # | Principle | Source (read at pin `b08bccfb`) | Agreement level |
|---|---|---|---|
| P1 | Terminal decoration is additive and format-scoped: it decorates the text format's rows and never reaches the machine formats or a web response. | ADR 0010 "Terminal niceties via a rich-only row variant on result models", Status **Accepted**, Date 2026-06-12; `cli/output.py:242-253` renders Markdown from the plain rows. | architectural pattern |
| P2 | Opting in is per-model and defaulted: a result type with nothing to decorate inherits the plain rows. | `core/models.py:59-67` — `def table_rows_rich(...)` … `return self.table_rows()`. | architectural pattern |
| P3 | Decoration is emitted only where it renders; off-terminal the row is plain. | ADR 0010 Consequences, "Rich strips the styling itself for non-terminal destinations"; the same note at the consumption point, `cli/output.py:235-237`. | capability/standard — *that* it disappears must agree; *how* may vary |
| P4 | Data must not be able to forge markup or an escape sequence. | ADR 0010 Decision, "with the link text **escaped**, so data containing `[` renders literally"; pinned by `tests/core/test_format.py:59-61`, `rich_link("a[b]", "https://e") == "[link=https://e]a\\[b][/link]"`. | capability/standard — the guarantee must agree; the escape set is ecosystem-specific |

**What must agree; what may vary.** P1, P2, and the *guarantees* in P3 and P4 must agree
across py, ts and rs. What may vary: the suppression mechanism, the escape set, and the
module the hook lives in. Two things must vary, and the evidence says why.

*Amendment 1 — the Rust hook cannot be argument-free.* py's `rich_link` returns Rich
**markup**, `[link=url]text[/link]` (`core/format.py:82`); Rich lowers that markup to
OSC-8 and strips it for non-terminal destinations, which is why py's hook takes no
arguments. Rust has no equivalent stripper inside a table crate. A stream-level stripper
(`anstream::AutoStream`) runs *after* the table crate has computed column widths, so
relying on one would give correct bytes and wrong alignment. Cargo, ripgrep and eza all
resolve this the same way — decide first, then emit or emit nothing — so the Rust hook
takes the resolved terminal capability as a parameter.

*Amendment 2 — the hook belongs in the CLI crate.* ADR 0010 puts the hook on `core`
result models. py's own later design document withdraws that placement:
`docs/design/0005-hexagonal-architecture-and-enforcement.md:190-195`, "**HEX-15 — view
models are a CLI concern.** `ProjectList`/`CLIResult` with
`table_columns()`/`table_rows_rich()`/OSC-8 links move to
`interfaces/cli/view_models.py`. The pure `Project` stays in the domain." In Rust the
placement is enforceable rather than documented: with the trait in the CLI crate, the
library crate and the web crate cannot name `rows_rich`, so no test is needed to prove an
OSC-8 escape never reaches an HTTP response body.

**Architecture alternatives compared, before libraries.**

| | A1 — provided trait method, capability-parameterised (**selected**) | A2 — renderer-side wrapper/newtype | A3 — structured cell enum lowered per renderer |
|---|---|---|---|
| Shape | `fn rows_rich(&self, caps: TermCaps) -> Vec<Vec<String>> { self.rows() }` | CLI wraps opted-in view types in `Rich<'a, T>` | `fn cells(&self) -> Vec<Vec<Cell>>`, `enum Cell { Text, Link{label,url}, Moment }`, each renderer lowers `Cell` |
| Preserves P2 | Yes — the default body *is* the fallback | No — the renderer must know which concrete types to wrap, which is the type-switching ADR 0010 rejected by name | Yes, but every view type is rewritten onto `Cell` even when it decorates nothing |
| Preserves P1 | By construction plus crate placement | Yes | Strongest — markup does not exist until lowering |
| Enforcement | Compile-time for reachability, review-time for usage | Compile-time | Compile-time and exhaustive |
| Depends on the table crate discounting OSC-8 | **Yes** | Yes | No — the renderer knows the label independently of the escape bytes |
| Verdict | Chosen | Rejected | Ranked runner-up |

A1's one structural weakness is the last row, and it is exactly the property the raw
reports left unmeasured. `## Empirical check` settled it by reading the crates' width
functions at pinned versions, and settled it conditionally: in the width path through
`measure_text_width` / `get_line_width`, at `comfy-table` 8.0.0 with `custom_styling` and
at `tabled` 0.22.0 / `papergrid` 0.18.0 with `ansi`, a well-formed OSC-8 sequence is not
counted toward the measured cell width; under either crate's default features it is; and
`comfy-table`'s `ContentArrangement::Dynamic` allocation heuristic bypasses that function
and was not settled. A1 is therefore selected **with the feature requirement and the
`Dynamic` caveat stated in `## Decision` item 5**, and A3 remains the documented fallback
if R66 selects a third table crate that lacks such a feature, if it selects `comfy-table`
in `Dynamic` mode and P03's assertion fails there, or if P03's assertion fails for any
other reason.

**Essential behaviors.**

- `rows()` is the single plain projection every format reads.
- `rows_rich(caps)` is named by the text renderer only, and returns `rows()` unless the
  view type overrides it.
- A decorated cell contains the label exactly as it will be displayed, wrapped in an
  opening and closing OSC-8 pair, or nothing when the capability is absent.
- Relative time is computed from a caller-supplied instant and a caller-supplied `now`,
  so the helper is pure and testable.

**Observable acceptance criteria** (all *proposed*; none was run, because the template
does not exist yet):

1. `--format json` output for a view type that overrides `rows_rich` contains no byte
   `0x1B` and no `file://` URL in a field whose plain value is a path.
2. The third format's bytes are identical whether or not the terminal supports
   hyperlinks.
3. With the capability true, a decorated cell carries exactly one
   `ESC ] 8 ; ; <url> ESC \` … `ESC ] 8 ; ; ESC \` pair around the label.
4. Piped to a file, the same command emits the plain cell — not a stripped one — and the
   rendered column widths are identical to the undecorated run. This is the check that
   proves item 5 of `## Decision` in the real template.
5. A label containing `ESC`, `BEL`, `[`, a newline or a space renders literally, and the
   emitted URI contains no raw control byte and no raw space.
6. `relative_time` returns `just now`, `1 minute ago`, `5 minutes ago`, `3 hours ago`,
   `2 days ago`, `2 months ago`, `2 years ago`, `in 2 days` for py's inputs.
7. `cargo tree -p <lib> -i anstyle-hyperlink` and `cargo tree -p <web> -i
   supports-hyperlinks` find nothing.

**Reference implementations, and the evidence that each is a relevant reference.**

- **Cargo** (`rust-lang/cargo`, read at commit `797e8a9bc` — the commit this machine's
  `cargo --version` reports, so it is the toolchain in use, not a moving branch). Its
  `Cargo.toml:23` declares `anstyle-hyperlink = "1.0.2"` and `:108`
  `supports-hyperlinks = "3.2.0"`, exactly the versions recommended here.
  `crates/cargo-util-terminal/src/shell.rs` returns `Hyperlink::with_url(url)` only when
  the stream's color choice is always-ANSI *and* the capability probe agrees, and
  `Hyperlink::default()` otherwise (Opus, read at HEAD 2026-09-10; the two dependency
  declarations were re-read at the pinned commit by this check, the `shell.rs` line
  numbers were not).
- **ripgrep** — writes a hyperlink only when the writer reports both color and hyperlink
  support, and closes only a link it actually opened (Opus, `crates/printer/src/hyperlink/mod.rs`
  at HEAD 2026-09-10; carried as a HEAD citation, not re-pinned here).
- **eza** — tri-state `EmbedHyperlinks::{Never, Automatic, Always}` resolved against TTY
  state before emission, with the label control-escaped separately from the
  percent-encoded URI (Opus, `src/output/escape.rs`, `src/output/file_name.rs` at HEAD
  2026-09-10; likewise a HEAD citation).

All three decide before emitting and emit nothing when the answer is no. That convergence,
not any download figure, is what selects the mechanism.

**Maturity, dependability and integration cost of the two recommended crates**
(figures from the raws, retrieved 2026-09-10; the stable fields were re-read from
crates.io by `## Empirical check`, which excludes download counters because they drift):

| | `anstyle-hyperlink` 1.0.2 | `supports-hyperlinks` 3.2.0 |
|---|---|---|
| Published | 2026-03-18 (1.0.0 on 2026-03-13) | 2025-12-17 |
| Declared `rust-version` | 1.66.0 | 1.70.0 |
| License | MIT OR Apache-2.0 | **Apache-2.0 only** |
| Default features | `default = ["std"]`; `file` is **off** and must be enabled for `path_to_url` | none |
| `unsafe` | none in the core type; two `libc` FFI calls in `src/hostname.rs:35,53`, reached only through `file` | none in `src/lib.rs` |
| Async runtime | none | none |
| Binary size / compile time | qualitative: two small source files, plus `percent-encoding` and `libc` only under `file` | qualitative: one dependency-free file of environment lookups |
| RustSec | no advisory directory in `rustsec/advisory-db` at pin `b50980a` | same |
| Maintenance | active — `rust-cli/anstyle` `pushed_at` 2026-09-07, maintainer median first issue response ~2.6 h over the 8 answered of the 10 most recent | stable-quiet — last release 8.8 months before retrieval, which trips the rubric's investigate trigger; investigated: three issues in the repository's lifetime, the recent one answered by the owner in 0.243 days, the crate is environment probing whose only churn is new terminal names, and Cargo pins the current version. No concrete `at-risk` signal |

**Performance.** No figure is asserted, in either direction. No published benchmark exists
for any candidate and none was run. Qualitatively — and this is a qualitative statement,
not a measurement — the work is `format!` over the cells of a table a human reads, and the
recommended carrier allocates nothing beyond the URL string: `Hyperlink`'s `Display`
writes `ESC ] 8 ; ;` (5 bytes) + the URL + `ESC \` (2 bytes) for the opening tag and 7
bytes for the closing tag.

**Where a different ecosystem needs a different design.** py keeps `rich_link` and
`relative_time` in `core/` and imports `rich.markup.escape` there, so the layer documented
as "no printing" imports the terminal-rendering library; HEX-15 is py's own finding that
this should move. ts has the *capability* in its tree — `supports-hyperlinks@3.2.0`
appears three times in `pnpm-lock.yaml` at pin `cb1cbcb2` — and uses none of it, and
`TS_PORT_DECISIONS.md` records no decision here. That is a **missing capability in ts**,
not a justified ecosystem difference, and the follow-on project should treat it as one.

**One finding that lowers the weight of py's exact wording as a requirement.** At pin
`b08bccfb`, `relative_time` is defined, documented and unit-tested but wired into no
result model: every mention is the definition (`core/format.py:46`), the docstring
reference (`core/models.py:64`), and the tests. No py result model carries a timestamp
column, so no py row has ever rendered a relative time. `ConfigPath.table_rows_rich`
(`core/models.py:136-142`) is the only override in the repository. String parity with py's
bucket list is therefore a test-pinned contract, not production-exercised behavior — which
is precisely why the relative-time half is recommended at medium confidence and
`timeago` is named as the runner-up the owner can choose instead.

The re-verify trigger below fires on whichever comes first: R66 publishing its
table-crate decision, or 2027-03-18, a year after `anstyle-hyperlink` 1.0.2.

re-verify: R66 publishes its table-crate decision, or 2027-03-18, whichever comes first

## Parameters

The prompt's `- owns:` line is empty: this item owns no parameter, so there are no `owns`
lines. Its `- consumes:` line is empty: there is no consumed parameter. No `CONFLICT:`
line — neither raw raised one, and nothing recommended here needs a registered value
changed.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

The four lines above were generated from `docs/port/PARAMETERS.md` by the awk extraction
in `review/evidence/r85-claims.sh` section 10 and diffed against this file; the diff is
empty and its exit status is recorded in the log.

How the four fixed parameters bear on the decision. **msrv-policy**: the recommended
crates declare `rust-version` 1.66.0 and 1.70.0, both far below any floor
stable-minus-two-minors produces against the current stable 1.98.0, so neither constrains
the MSRV. **rust-edition**: editions are per-crate and no recommended crate's own edition
affects a 2024-edition consumer; the parameter is otherwise inert here. **license**: the
template's own dual license is unchanged, but `supports-hyperlinks` is **Apache-2.0 only**,
so a downstream consumer of the CLI binary can no longer take the MIT arm for the whole
binary, and any `cargo-deny` allowlist must include `Apache-2.0`. Cargo — itself
`MIT OR Apache-2.0` — accepts the same constraint, which is the precedent for accepting
it here. **target-os-matrix**: both crates are pure Rust on the two required runners;
`anstyle-hyperlink`'s only platform branch is a `cfg(windows)` URL-prefix case and
`supports-hyperlinks` reads environment variables, so Windows — noted, not required — is
also covered.

Two non-registry assumptions this decision rests on, neither of which is a registered
parameter. **R65** must expose something the CLI can read as "this stream will accept
escape codes"; either an `anstream`-style color choice or a plain boolean satisfies this
item, and in the boolean case the hyperlink capability is
`color_enabled && supports_hyperlinks::on(Stdout)`. R65 additionally acquires an input it
may not have scoped: `FORCE_HYPERLINK`, which `supports-hyperlinks` honors independently
of `NO_COLOR`/`FORCE_COLOR` (`src/lib.rs:14,66`). **R66** must produce text-mode rows as
string cells and must select a table crate with an ANSI-aware width feature, enabled — see
`## Decision` item 5. If R66 instead selects a crate that parses markup inside cell text,
P4's escape set gains that crate's markup metacharacters *in addition to* the control-byte
and percent-encoding guards; that would change this item's escaping answer, not its hook
or suppression answer.

## Empirical check

**Toolchain.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4 on arm64; bash 3.2.57.
No Rust code was compiled or executed and nothing was scaffolded: the check reads
published crate sources at pinned versions, reads the two source repositories through
their programme pins, and queries crates.io, the GitHub API and the RustSec advisory
database.

**Command and working directory.**

```sh
cd research/runs/R85/2026-09-06T043455Z-beb2d764c756/review/evidence
bash r85-claims.sh > r85-claims.log 2>&1     # exit status 0
```

**Log.** `review/evidence/r85-claims.log`, the complete output of that command.
**The log is reproducible byte-for-byte, and this was confirmed by rerunning the script
and diffing it against the saved log immediately before this sentence was written**
(`bash r85-claims.sh | diff - r85-claims.log` → empty, exit 0). Three rules make it so,
and they are stated in the script's header: published `.crate` tarballs are immutable and
each one's sha256 is asserted against a constant, so every source extract is fixed;
repository reads go through fixed commit SHAs (py `b08bccfb…`, ts `cb1cbcb2…`, cargo
`797e8a9bc`, `rustsec/advisory-db` `b50980aa…`); and HTTP JSON that drifts — download
counters, `pushed_at`, reaction counts, the newest-version list — is snapshotted once into
`review/evidence/snap/` and read from the snapshot thereafter. No timestamp is printed.
Deleting `snap/` re-fetches the live sources, which is the intended way to re-verify.

**Sources and endpoints, with retrieval dates.** Crate sources:
`https://static.crates.io/crates/<name>/<name>-<version>.crate` for the nine pinned
crates listed in the log's section 1, downloaded 2026-09-10, each sha256 recorded there.
Registry fields: `GET https://crates.io/api/v1/crates/<name>/versions`, retrieved
2026-09-10. Cargo's manifest:
`https://raw.githubusercontent.com/rust-lang/cargo/797e8a9bc/Cargo.toml`, retrieved
2026-09-10. Advisories: `GET https://api.github.com/repos/rustsec/advisory-db/contents/crates/<name>?ref=b50980aad8b8f14f77e25a97b32dd94bf008b0af`,
retrieved 2026-09-10, plus the two `https://rustsec.org/packages/<name>.html` 404s the
raws recorded on 2026-09-05 and 2026-09-10. Upstream discussion:
`https://github.com/Nukesor/comfy-table/issues/137` and its comments, via
`GET https://api.github.com/repos/Nukesor/comfy-table/issues/137[/comments]`, retrieved
2026-09-10. Source repositories: `git -C ~/c/py-launch-blueprint show b08bccfb…:<path>`
and `git -C ~/c/ts-launch-blueprint grep … cb1cbcb2…`, read 2026-09-10. Every other URL
and date in this decision is carried from the raw report that retrieved it, as cited
in place.

**What the check established.**

*1. The deciding question — does the cell-width function discount a zero-width OSC-8
hyperlink? **Settled, by reading the crates' source at pinned versions**, for the two
table crates in play, and settled conditionally: the answer depends on a feature that is
off by default in both.*

- `comfy-table` 8.0.0 selects its width function by feature
  (`src/utils/formatting/content_split/mod.rs:5-13`). Under **default** features,
  `content_split/normal.rs:8-10` is `measure_text_width(s) = s.width()` — plain
  `unicode-width` over the raw cell, so every printable character of the URL is counted
  and the column is mis-measured. Under **`custom_styling`**,
  `content_split/custom_styling.rs:11-13` is `s.ansi_strip().width()`.
- That path resolves to `ansi-str` 0.9.0 `strip_ansi_sequences` (`src/lib.rs:960-1005`),
  which keeps **only** `ElementKind::Text` tokens from `ansitok`. `ansitok` 0.3.0 parses
  with `vte` 0.14.1 — Alacritty's VT state machine — and its own test
  `test_iterator_osc_hyperlinks_styled_non_ascii` (`src/parse/ansi_parser.rs:286-316`)
  pins the classification for a well-formed OSC-8 pair: the URL run is an `Osc` element,
  the `\` of the string terminator is a separate `Esc` element, and the only `Text`
  element is the label. Neither is measured.
- `tabled` 0.22.0 answers the same question in its grid layer and says so in a comment.
  `papergrid` 0.18.0 `get_line_width` (`src/util/string.rs:17-33`) is `get_string_width`
  (plain `unicode-width`) without the `ansi` feature, and with `ansi` it is
  `ansitok::parse_ansi(text).filter(|e| e.kind() == ElementKind::Text)…sum()` under the
  comment "we need to strip ansi because of terminal links".
- `comfy-table`'s `custom_styling` path also *splits and wraps* through
  `console::AnsiCodeIterator`. `console` 0.16.6 has an explicit OSC branch in
  `find_ansi_code_exclusive` (`src/ansi.rs:274-282`) and three tests that strip an OSC-8
  hyperlink terminated by ST, by BEL, and wrapped in tmux DCS passthrough
  (`src/ansi.rs:552-571`); `ansi-parsing` is a default feature. So the wrapping path
  treats OSC-8 as zero-width too.
- **Counter-signal, reported rather than explained away.** `comfy-table` carries a test
  named `measure_text_width_osc8_test` above the comment "TODO: Figure out why this fails
  with the custom_styling feature enabled". The test body is in `custom_styling.rs`, which
  `mod.rs` compiles only under `#[cfg(feature = "custom_styling")]`, while the test itself
  is `#[cfg(not(feature = "custom_styling"))]` — a contradiction, so it is compiled out in
  both feature configurations and has never run. Its input's closing sequence is also
  truncated (`ESC ] 8 ; ;` then a lone `ESC`, with no final `\`), which is not what a
  well-formed emitter produces. I did not prove that the truncation is the cause of the
  historical failure, and I do not claim it.
- **A second `comfy-table` width site, which the feature does *not* make ANSI-aware.** The
  primary measurement, `Row::max_content_widths` (`src/row.rs:61-75`), goes through the
  feature-selected `measure_text_width`. The `ContentArrangement::Dynamic` allocator does
  not: `longest_line_after_split` (`src/utils/arrangement/dynamic.rs:446-482`) calls
  `line.width()` and `part.width()` — `unicode_width::UnicodeWidthStr`, imported at
  `dynamic.rs:1` — directly on cell content, at `dynamic.rs:463,469,476,478`. Those are
  every raw `.width()` call on cell content in `src/utils/arrangement/`. So under
  `ContentArrangement::Dynamic`, a decorated cell reaches an allocation heuristic that
  counts the URL's characters even with `custom_styling` enabled. I did not trace whether
  that heuristic's result changes the final rendered layout in every case, and I do not
  claim it does; I record the path.
- **The same question asked of `tabled`, and answered negatively.** `papergrid` 0.18.0
  makes no direct use of `unicode_width` outside `src/util/string.rs`, and `tabled` 0.22.0
  makes none at all — all width goes through papergrid's helpers — so no analogous bypass
  was found there. `tabled`'s wrapping is branched explicitly on the `ansi` feature
  (`src/settings/width/wrap.rs:216,225,240,284,373,453`). This is a grep for direct
  `unicode-width` use, which is the mechanism of the `comfy-table` bypass; it is not a
  proof that no other path exists.
- **What the history says, in its actual sequence.** `comfy-table` issue #137 "Allow for
  OSC / Control Characters" (https://github.com/Nukesor/comfy-table/issues/137, opened
  2024-03-27, closed 2024-04-05, read 2026-09-10) is the same mis-measure, reported by a
  user. The order matters and the raws did not have it. (i) The maintainer points the
  reporter at the then-existing `custom_styling` feature, which at that time measured
  through `console`. (ii) Trying it, the reporter reports a *partial* result — "The cell
  the OSC-8 escape codes are in are properly sized, but the header cell is not" — with a
  `ContentArrangement::Dynamic` table. (iii) The maintainer names `measure_text_width` as
  the place and says the fix "might need to be added to the `console` library upstream".
  (iv) The reporter's closing comment is "`console` doesn't do the right thing … for now
  I'm using `ansi-str` which does the right thing", and that is the change `custom_styling`
  carries today. Two things follow. The `console`-era limitation is gone: `console` 0.16.6
  has the OSC tests cited above. The reporter's residual header symptom is *consistent
  with* the `Dynamic` bypass recorded in the bullet above — a Dynamic-mode table was what
  produced it — but I did not verify that it is the same defect, and I do not assert it.
- **Therefore**, stated to exactly what the reading establishes: the width path through
  `measure_text_width` — `comfy-table` 8.0.0 with `custom_styling`, `tabled` 0.22.0 /
  `papergrid` 0.18.0 with `ansi` — does not count a well-formed OSC-8 sequence
  (ST- or BEL-terminated) toward the measured cell width, and does count it under either
  crate's default features. A1's premise therefore holds for that path, with the feature
  on. It is **not** established for `comfy-table`'s `ContentArrangement::Dynamic`
  allocation heuristic, which bypasses that function, and this check says nothing about any
  other table crate. That is why `## Decision` item 5 states the feature as a requirement
  on R66 rather than an assumption, and why criterion 4 remains a P03 assertion run against
  the crate *and the arrangement mode* R66 actually selects.

*2. The recommended crates' behavior, at their pinned published versions.*
`anstyle-hyperlink` 1.0.2 `src/hyperlink.rs`: `Default` sets `url: None` and `Display`
returns `Ok(())` for it — zero bytes, the null object the design depends on; the populated
form writes `"\x1B]8;;{url}\x1B\\"` and the alternate form writes `"\x1B]8;;\x1B\\"`, with
**no** percent-encoding and no control-byte filtering of the URL, confirming that
sanitizing is the caller's obligation. `rust-version = "1.66.0"`; `file` is off by default
and pulls `percent-encoding` and `libc`; the only `unsafe` in the crate is two `libc` FFI
calls at `src/hostname.rs:35,53`, reachable only through `file`. `path_to_url` builds its
percent-encode sets from `percent_encoding::CONTROLS` (`src/file.rs:49-63,196-198`).
`supports-hyperlinks` 3.2.0 declares `license = "Apache-2.0"` (not the dual license) and
`rust-version = "1.70.0"`, contains no `unsafe` in `src/lib.rs`, and reads
`FORCE_HYPERLINK`, `DOMTERM`, `VTE_VERSION`, `TERM_PROGRAM`, `WT_SESSION`,
`KONSOLE_VERSION` plus `std::io::IsTerminal`. `timeago` 0.6.1 `convert(&self, d: Duration)`
takes an unsigned `std::time::Duration` (`src/lib.rs:447`), so it cannot express a future
instant without a caller-side sign branch, and its default features pull `chrono` and
`isolang`.

*3. Cargo declares both recommended crates, read at this machine's own cargo commit.*
`rust-lang/cargo` at `797e8a9bc` — the commit `cargo --version` prints here —
`Cargo.toml:23` `anstyle-hyperlink = "1.0.2"` and `:108`
`supports-hyperlinks = "3.2.0"`. Both are the versions recommended above.

*4. RustSec — the two raws disagreed and the disagreement is resolved.* Both raws
recorded `https://rustsec.org/packages/<name>.html` returning HTTP 404 for every
candidate; Codex read that as "advisory status unverified" and Opus as "pass". Querying
the advisory database itself at pin `b50980aa…` settles it: `anstream`, used as a positive
control, has `crates/anstream/RUSTSEC-2024-0404.md`, while `anstyle-hyperlink`,
`supports-hyperlinks`, `timeago`, `percent-encoding`, `comfy-table`, `tabled` and
`console` have no advisory directory at all. A 404 on the rendered site is the absence of
a package page, not an unqueryable advisory status. This is a point-in-time result at that
pin, not a claim about the future.

*5. Registry stable fields.* Newest non-yanked version, `created_at`, `rust_version` and
`license` for all ten crates named in this decision were re-read and match the raws.
Download counters were deliberately excluded from the log because they drift and no
conclusion here rests on them.

*6. py and ts precedent at the programme pins.* Every cited line was re-read: the hook and
its default body (`core/models.py:55-67`), the bucket table and both helpers
(`core/format.py:36-82`), the single consumption point (`cli/output.py:224-241`), the sole
override and its three tests (`core/models.py:136-142`, `tests/core/test_format.py:36-61`,
including `test_rich_link_escapes_markup_in_text` and `test_plain_rows_never_carry_markup`),
HEX-15 (`docs/design/0005-…:190-195`), ADR 0010's status line and its escaping and
stripping sentences, the complete `relative_time` grep showing no model wiring, and the ts
grep at `cb1cbcb2` returning only three `pnpm-lock.yaml` lines.

*7. Fixed-parameter byte comparison.* The four `assumes` lines were generated from
`docs/port/PARAMETERS.md` by awk and diffed against this file's `## Parameters` block:
`parameter-diff-exit=0`.

**What was not verified, and is left for P03.** No Rust code was compiled, so no rendered
table was measured end to end; the width finding is a source-reading result about the
crates' width functions, not an observation of a rendered table. The `shell.rs`,
`ripgrep` and `eza` line numbers carried from Opus were read at those repositories' HEAD
on 2026-09-10 and are not re-pinned here; only Cargo's two dependency declarations were
re-read at a fixed commit. Issue-responsiveness medians are carried from Opus as
retrieved 2026-09-10 and were not re-queried.

## Engines

- `codex raw/codex-0205f411555b9e25c84dffea87b4f25352ccd0f4a71c18548409ad35ea143b08.md`
  (gpt-5.6-terra, collected 2026-09-06).
- `opus raw/opus-36d69f50801bc4a444d02396ba9a2e0d6ac4eb87a26db5b8c278fb2c761c081f.md`
  (claude-opus-5, collected 2026-09-10).

**Where they agree.** Both answer the decision question yes; both name a trait method with
a default body as the Rust equivalent of py's hook; both put the emission decision before
the emission rather than relying on a downstream stripper; both keep JSON, the third
format and the web path on the plain rows; both reject a renderer-side wrapper that must
know the concrete model set; both decline `osc8` and `terminal-link`; both decline
`timeago` and `chrono-humanize` as the primary answer and prefer a small helper; both
report `owns`/`consumes` empty and emit no `CONFLICT:`; and both state that no performance
figure exists for any candidate. This decision asserts none either.

**Disagreement 1 — cell representation, and what settled it.** Codex recommends a
structured `TextCell { Plain, Link, RelativeTime }` enum with all escape emission after
table layout; Opus recommends a decorated `String` from a capability-parameterised hook,
and lists Codex's shape as its own ranked runner-up (A3). Codex's shape is safe under any
table crate; Opus's is simpler and preserves the defaulted opt-in without rewriting every
view type, but only if the table crate discounts OSC-8 when measuring. Opus named that
property as the one unmeasured thing that could overturn its recommendation.
`## Empirical check` settled it by reading both crates' width functions at pinned
versions: it holds for both in the path through `measure_text_width` / `get_line_width`
**with their ANSI-width feature enabled**, fails under their default features, and is
unsettled for `comfy-table`'s `ContentArrangement::Dynamic` allocation heuristic, which
bypasses that function. So the decision takes Opus's shape and converts the property into
an explicit requirement on R66 (`## Decision` item 5) plus a P03 assertion (criterion 4).
If R66 selects a table crate with no such feature, or the assertion fails in the
arrangement mode it selects, Codex's shape is the fallback and this decision is revised against
this record rather than re-researched.

**Disagreement 2 — crate landscape.** Codex's survey does not contain
`anstyle-hyperlink` at all; it evaluates `osc8`, `supports-hyperlinks`, `timeago` and
`jiff`, concludes that no crate is worth adopting, and recommends a hand-rolled OSC-8
encoder. Opus found the crate, and found that Cargo declares it. This check confirmed the
declaration at the exact cargo commit this machine runs. A first-party crate that the
Rust project's own CLI depends on is better evidence than a hand-rolled encoder's
smallness, so Opus's finding stands and Codex's landscape is recorded as incomplete on
this point rather than as a competing view. Codex's contribution that survives is its
insistence that the URI be validated at construction and that the label never carry
renderer markup — the same guard Opus reaches through percent-encoding plus
control-escaping, and the guard `anstyle-hyperlink`'s own source confirms is the caller's
job.

**Disagreement 3 — whether to emit a `BASELINE-REVIEW:` line.** Codex emits one against
`F359`; Opus emits none and gives the reason. Opus is right and no line is emitted here:
`F359` is this item's own ledger row, its verdict is `DIVERGENT`, and nothing about that
verdict is inherited from another item or challenged by this decision. Codex's line
proposes the design this decision already adopts; a `BASELINE-REVIEW:` line is for
challenging a *retained* baseline, which this is not.

**Disagreement 4 — RustSec.** Resolved in `## Empirical check` item 4 in Opus's favour,
by querying the advisory database rather than the rendered site.

**Uncertainty this decision carries, stated plainly.**

- The relative-time recommendation is the weakest part. It prefers a hand-rolled helper
  over two maintained crates on the strength of exact string parity with py — and py's own
  `relative_time` is wired into no model, so that parity pins a test, not shipped
  behavior. If the owner does not require parity, `timeago` 0.6.1 with
  `default-features = false` (eza's configuration) is the better answer and this reverses.
  This is an owner question, not a research gap; the prompt asks whether a maintained
  crate exists and does not mandate parity.
- `chrono-humanize` is hosted on GitLab and `osc8` on Codeberg, so the prompt's GitHub
  figures — stars, `archived`, `pushed_at`, open issues, issue responsiveness — are
  recorded **inapplicable with the reason**, not estimated. That is the correct answer for
  those rows and not a gap. Their crates.io figures and licenses were collected normally.
- `comfy-table` 8.0.0 is `MIT`-licensed and `tabled` 0.22.0 likewise; neither declares a
  `rust-version`. Both facts are inputs to R66's gate, not this item's, and are recorded
  here only because this item's check read them.

**What P03 must validate.**

1. **The width property, against the table crate R66 actually selects** — acceptance
   criterion 4. Render one decorated row with the capability forced on, strip the OSC-8
   pairs from the output, and compare byte-for-byte with the same row rendered plain. Run
   this first; it is the check that decides whether the hook keeps returning `String`.
   Confirm at the same time that the crate is built with its ANSI-width feature enabled
   (`comfy-table`'s `custom_styling`, `tabled`'s `ansi`, or the equivalent), because
   neither is on by default — and run the assertion in the arrangement mode the template
   actually uses. If that is `comfy-table` with `ContentArrangement::Dynamic`, this is the
   case the source reading could not settle: `longest_line_after_split`
   (`dynamic.rs:446-482`) measures cell content with `unicode-width` regardless of the
   feature.
2. **That the library crate and the web crate link neither decoration crate** —
   criterion 7. This is the structural claim Amendment 2 buys and it is cheap to assert.
3. **The escaping guards** — criterion 5, including a label carrying `ESC`, `BEL`, `[`,
   a newline and a space, and a path with a space percent-encoded in the URI.
4. **`FORCE_HYPERLINK` in R65's precedence chain.** `supports-hyperlinks` honors it
   independently of `NO_COLOR`/`FORCE_COLOR`; R65 may not have scoped it.
5. **The wrapping path, not only the width path.** A decorated cell that exceeds the
   column width is split by the table crate; this check read the splitters' OSC handling
   but did not exercise a split that lands inside an escape sequence. P03 should include
   one narrow-column case.
6. **The relative-time contract** — criterion 6 — and, before writing the helper, the
   owner question above.
