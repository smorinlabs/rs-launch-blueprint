# R85 — rich-terminal-row-niceties (pattern) — Opus raw report

Retrieval date for every endpoint figure below: **2026-09-10** unless a line states
otherwise. Source repositories were read through their programme pins:
Python `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (`git -C ~/c/py-launch-blueprint show
b08bccfb:<path>`), TypeScript `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`.

### Landscape

**Category this item decides.** Not "a table library" and not "a color gate". It decides
a *presentation-variant seam*: how one row of result data acquires terminal-only
decoration (an OSC-8 hyperlink; a humanised timestamp) for exactly one output format,
while every other format keeps the undecorated data. Three separable sub-decisions fall
out of it: (1) where the variant lives and how a model opts in; (2) how OSC-8 escape
codes are produced and suppressed; (3) how a relative-time string is produced. Terms
used throughout: **OSC 8** is the terminal escape sequence `ESC ] 8 ; params ; URI ST`
… `ESC ] 8 ; ; ST` that makes a run of text a clickable link (`ST` = string terminator,
`ESC \`); **SGR** is the separate `ESC [ … m` family that carries color and bold;
**null object** is a value whose rendering is empty, so a call site can keep one code
path for the decorated and undecorated case.

**Three-bin map of the Rust field.**

*Built-in or first-party toolchain.*
- `std::io::IsTerminal` (stable since Rust 1.70) — TTY detection in the standard
  library; no crate needed (https://doc.rust-lang.org/std/io/trait.IsTerminal.html,
  2026-09-10).
- Trait with a *provided* (default-bodied) method — the language mechanism that is the
  literal analogue of py's `table_rows_rich()` defaulting to `table_rows()`
  (https://doc.rust-lang.org/book/ch10-02-traits.html#default-implementations,
  2026-09-10).
- `enum` + exhaustive `match` — the language mechanism behind the structured-cell
  alternative; the compiler, not a reviewer, enforces that every renderer handles every
  cell kind (https://doc.rust-lang.org/book/ch06-02-match.html#matches-are-exhaustive,
  2026-09-10).
- **`anstyle-hyperlink`** — OSC-8 formatter published by the **rust-cli working group**
  in the `rust-cli/anstyle` workspace, and **consumed by Cargo itself**:
  `rust-lang/cargo` `Cargo.toml:23` declares `anstyle-hyperlink = "1.0.2"` and `:108`
  declares `supports-hyperlinks = "3.2.0"`
  (https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml, 2026-09-10).
- **`termcolor`** — BurntSushi's writer abstraction; `WriteColor::set_hyperlink` and
  `WriteColor::supports_hyperlinks` are part of the trait, so OSC-8 is emitted or
  silently dropped by the *writer*
  (https://raw.githubusercontent.com/BurntSushi/termcolor/master/src/lib.rs lines
  172-200, 1547-1552, 1686-1700, 2269-2282, 2026-09-10).

*Established industry standard.*
- **`supports-hyperlinks`** — the de-facto capability probe; `supports_hyperlinks()`
  reads `FORCE_HYPERLINK`, `DOMTERM`, `VTE_VERSION`, `TERM_PROGRAM`, `TERM`,
  `COLORTERM`, `WT_SESSION`, `KONSOLE_VERSION`, and `on(Stream)` additionally requires
  the stream be a TTY
  (https://raw.githubusercontent.com/zkat/supports-hyperlinks/main/src/lib.rs:11-70,
  2026-09-10).
- **`anstream` / `anstyle`** — the rust-cli working group's ANSI stream adapters;
  `AutoStream` "always accepts ANSI escape codes, adapting to the user's terminal's
  capabilities" and "will correctly handle piping to a file"
  (https://raw.githubusercontent.com/rust-cli/anstyle/main/crates/anstream/src/lib.rs:1-32,
  2026-09-10). This is the closest Rust analogue of Rich's automatic stripping, but it
  operates on the *stream*, not inside a table crate.
- **`timeago`** — the established "N days ago" formatter; `Formatter::convert` /
  `convert_chrono` (https://raw.githubusercontent.com/vi/timeago/master/src/lib.rs,
  2026-09-10).
- **`chrono-humanize`** — the `arrow.humanize`-style formatter, bidirectional
  (`Tense::Past => "{} ago"`, `Tense::Future => "in {}"`, `Tense::Present => "now"`,
  https://gitlab.com/imp/chrono-humanize-rs/-/raw/master/src/humantime.rs:155-157,
  2026-09-10).
- Hand-rolled OSC-8 with percent-encoded URIs, as practised by **eza** and **ripgrep**
  (cited below).

*Up-and-comer.*
- **`anstyle-hyperlink` 1.0.0** first published **2026-03-13**, `1.0.2` on
  **2026-03-18** (`GET https://crates.io/api/v1/crates/anstyle-hyperlink/versions`,
  2026-09-10) — six months old, already in the Cargo tree.
- **`osc8` 0.1.0** (2024-08-09, MIT, Codeberg-hosted,
  `GET https://crates.io/api/v1/crates/osc8/versions`, 2026-09-10) — a parser/generator
  with no notable adopters.
- **`jiff`** (BurntSushi) as the date-time substrate a hand-rolled relative-time helper
  would sit on: 62,726,919 recent downloads, newest unyanked `0.2.35` released
  2026-07-25, MSRV 1.70 (`GET https://crates.io/api/v1/crates/jiff` and `/versions`,
  2026-09-10).

**Authoritative sources used, and why each counts.**

| Source | Why authoritative |
|---|---|
| `rust-lang/cargo` `Cargo.toml` and `crates/cargo-util-terminal/src/shell.rs` | Cargo is the Rust project's own CLI; its terminal layer is first-party toolchain code, not a third-party opinion. |
| `rust-cli/anstyle` (crates `anstream`, `anstyle-hyperlink`) | Publications of the Rust CLI working group; `anstyle` is the styling vocabulary clap and Cargo build on. |
| Rust Book / std docs (provided trait methods, exhaustive `match`, `IsTerminal`) | Rust project publications defining the language mechanisms compared here. |
| OSC-8 specification gist by Egmont Koblinger, "Hyperlinks in terminal emulators" | The de-facto protocol reference; cited *by* `anstyle-hyperlink`'s own module docs and by the `OSC8-Adoption` list termcolor links (https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda, 2026-09-10). |
| RustSec advisory database | The Rust Secure Code WG's advisory source; used for gate 3. |
| crates.io and GitHub REST | The figure endpoints the prompt fixes in `## Required evidence`. |

A single blog post was not used as an authority anywhere in this report.

**Well-regarded projects surveyed, with the evidence that they are well regarded, and
what each actually does.**

| Project | Evidence it is well regarded (`GET https://api.github.com/repos/<o>/<r>`, 2026-09-10) | What it does for this item |
|---|---|---|
| **Cargo** (`rust-lang/cargo`) | The Rust project's official build tool; ships with every toolchain. | `Shell::out_hyperlink` returns `Hyperlink::with_url(url)` only when `stdout.current_choice() == anstream::ColorChoice::AlwaysAnsi && hyperlinks`, else `Hyperlink::default()` — a null object that renders to the empty string. `out_file_hyperlink` routes paths through `anstyle_hyperlink::path_to_url`. `supports_hyperlinks()` wraps the crate and hard-disables iTerm2 ("unknown incompatibility") (`crates/cargo-util-terminal/src/shell.rs:13,56,328-363,616-627`, 2026-09-10). |
| **ripgrep** (`BurntSushi/ripgrep`) | 68,148 stars; not archived; `pushed_at` 2026-08-04. | `Interpolator::begin` writes a hyperlink only `if !(format.is_empty() \|\| !wtr.supports_hyperlinks() \|\| !wtr.supports_color())`, returns an `InterpolatorStatus` recording whether it opened one, and `finish` closes only an actually-opened link. Escape bytes are never written in the printer; `termcolor` writes them (`crates/printer/src/hyperlink/mod.rs:626-707`, 2026-09-10). |
| **eza** (`eza-community/eza`) | 23,210 stars; not archived; `pushed_at` 2026-08-06. Depends on `timeago = { version = "0.6.0", default-features = false }` (`Cargo.toml:107`). | Tri-state `EmbedHyperlinks::{Never, Automatic, Always}` resolved against `is_a_tty` before emission; hand-rolls `HYPERLINK_OPENING_START = "\x1B]8;;"` … `HYPERLINK_OPENING_END = "\x1B\x5C"`, percent-encodes the URI with `CONTROLS.add(b' ')`, and **control-escapes the label separately** (`escape()` passes bytes `>= 0x20` and `!= 0x7f` through, escaping the rest) (`src/output/escape.rs`, `src/output/file_name.rs:489-545`, 2026-09-10). |
| **miette** (`zkat/miette`) | 2,602 stars; not archived; `pushed_at` 2026-06-25. | `supports-hyperlinks = { version = "3.0.0", optional = true }` behind the `fancy` feature (`Cargo.toml:22,61`, 2026-09-10) — capability detection is an *optional* dependency, off by default. |
| **delta** (`dandavison/delta`) | 32,138 stars; not archived; `pushed_at` 2026-09-02. | `chrono-humanize = "0.2.2"` and `anstyle-parse = "0.2.3"` (`Cargo.toml:20,31`, 2026-09-10) — the only mainstream adopter I found for `chrono-humanize`. |
| **cargo-nextest, mise, ruff_db, xh, komac** | Appear in `supports-hyperlinks` reverse dependencies (`GET https://crates.io/api/v1/crates/supports-hyperlinks/reverse_dependencies`, total 39, 2026-09-10). | Corroborate `supports-hyperlinks` as the standard probe. |

**The convergent practice finding.** All three OSC-8 adopters (Cargo, ripgrep, eza)
decide *before emitting* whether the escape codes are produced at all, and emit nothing
when the answer is no. **None of them relies on a downstream stripper to remove
hyperlink markup.** That is the single most important delta from the Python precedent,
whose hook is argument-free precisely because Rich strips for it.

### Principles and implementation

**Shared requirement, its source, and agreement level.**

- **Principle (P1) — terminal decoration is additive and format-scoped.** Presentation
  niceties that only a terminal can render decorate the *text* format's rows and never
  reach the machine formats; JSON keeps raw fields and ISO-8601 UTC, and the third
  format keeps plain cells. Source: ADR 0010 "Terminal niceties via a rich-only row
  variant on result models", Status Accepted, Date 2026-06-12 (py
  `docs/adr/0010-rich-row-variant-on-result-models.md` at pin `b08bccfb`), restated to
  users in py `EXAMPLECLI.md:54-57`. **Agreement level: architectural pattern.**
- **Principle (P2) — opting in is per-model and defaulted.** A result type that has
  nothing to decorate inherits the plain rows with no code. Source: py
  `core/models.py:59-67` — `def table_rows_rich(self) -> list[list[str]]:` … `return
  self.table_rows()`. **Agreement level: architectural pattern.**
- **Principle (P3) — decoration is emitted only where it renders.** Source: ADR 0010
  Consequences — "Rich strips the styling itself for non-terminal destinations, so the
  hook needs no TTY awareness in models"; py `cli/output.py:236-238` carries the same
  note at the consumption point. **Agreement level: capability/standard** — *that*
  decoration disappears off-terminal must agree; *how* it disappears is a
  policy/mechanism free to differ per ecosystem, and it must differ (see below).
- **Principle (P4) — data must not be able to forge markup.** Source: ADR 0010 Decision
  — `rich_link()` escapes the link text "so data containing `[` renders literally
  instead of parsing as markup — a review finding"; pinned by py
  `tests/core/test_format.py:59-61`. **Agreement level: capability/standard** — the
  guarantee that a data-derived cell cannot alter the rendering must agree; the
  concrete escape set is ecosystem-specific.

**What must agree; what may vary.** P1, P2 and the *guarantees* in P3/P4 must agree
across py, ts and rs. What may vary: the suppression mechanism (Rich's stripper vs.
Rust's construction-time gate), the escape set (Rich markup metacharacters vs. C0
control bytes plus URI percent-encoding), and the module the hook lives in.

**Is the shared pattern still appropriate in Rust? Yes, with two amendments the Python
repository's own documents already point at.**

*Amendment 1 — the hook cannot be argument-free.* P3's Python realization delegates to
Rich. Rust has no equivalent inside a table crate. `comfy-table` needs its
`custom_styling` feature (`custom_styling = ["dep:ansi-str", "dep:console", "tty"]`,
https://raw.githubusercontent.com/Nukesor/comfy-table/main/Cargo.toml, 2026-09-10) even
to *measure* a cell that contains escape codes, and those dependencies are SGR-oriented;
whether they discount a zero-width OSC-8 sequence when computing column width is
**unverified** (see `### Validation strategy`). `anstream::AutoStream` does strip on the
way out, but a stream-level stripper runs *after* the table crate has already computed
column widths from the decorated strings — so relying on it would produce correct bytes
and wrong alignment. Cargo, ripgrep and eza all resolve this the same way: gate at
construction. The Rust hook therefore takes the terminal capability as a parameter.

*Amendment 2 — the hook belongs in the CLI crate, not the core crate.* ADR 0010 places
the hook on `core` result models and defends it as "an extension of the existing
compromise, not a new leak". py's own later design document withdraws that defence:
`docs/design/0005-hexagonal-architecture-and-enforcement.md:190-195` — "**HEX-15 — view
models are a CLI concern.** `ProjectList`/`CLIResult` with
`table_columns()`/`table_rows_rich()`/OSC-8 links move to
`interfaces/cli/view_models.py`. The pure `Project` stays in the domain." Rust makes
this cheap and enforceable: the view trait lives in the CLI crate, so the library crate
and the web crate cannot call it, and no test is needed to prove the web service never
emits escape codes — it cannot name the method.

**Architectural alternatives compared (before libraries).**

| | A1 — provided trait method, capability-parameterised (**recommended**) | A2 — renderer-side wrapper/newtype | A3 — structured cell enum lowered per renderer |
|---|---|---|---|
| Shape | `trait TableView { fn rows(&self) -> Vec<Vec<String>>; fn rows_rich(&self, caps: TermCaps) -> Vec<Vec<String>> { self.rows() } }` | CLI wraps opted-in models in `Rich<'a, T>` implementing the view trait | `fn cells(&self) -> Vec<Vec<Cell>>` with `enum Cell { Text(String), Link { label: String, url: String }, Moment(Timestamp) }`; each renderer lowers `Cell` |
| Preserves P2 (defaulted opt-in) | Yes — the default body *is* the fallback | No — the CLI must know which concrete types to wrap; this is the `isinstance` ladder ADR 0010 rejected, transliterated to `match` on type | Yes, but every model must be rewritten onto `Cell` even when it decorates nothing |
| Preserves P1 structurally | By construction plus placement: only the text renderer can call `rows_rich`, and only the CLI crate can see the trait | Yes | Strongest — markup does not exist until lowering |
| Enforcement | Compile-time for *reachability*, review-time for *usage* | Compile-time | Compile-time and exhaustive: adding `Cell::Link` breaks every renderer that has not handled it |
| Cost | One extra provided method; carriers do the work | Wrapper type per decorated model; renderer coupled to the model set | New data model, a lowering function per format, and churn in every model |
| Migration cost from py's shape | Lowest — a one-for-one translation | Medium | Highest |
| Verdict | Chosen | Rejected — reintroduces the coupling ADR 0010 explicitly rejected | Ranked runner-up (see `### Ranked runner-up`) |

**Recommended design, and how it preserves each principle.**

The pattern, named: **capability-gated rich row variant with null-object carriers.**

```rust
// cli crate — view.rs
#[derive(Clone, Copy, Default)]
pub struct TermCaps { pub hyperlinks: bool }   // resolved once, from R65's gate

pub trait TableView {
    fn columns(&self) -> Vec<&'static str>;
    fn rows(&self) -> Vec<Vec<String>>;                       // plain: every format
    fn rows_rich(&self, _caps: TermCaps) -> Vec<Vec<String>> { // text format only
        self.rows()
    }
}

// cli crate — fmt.rs
pub fn link(caps: TermCaps, label: &str, url: &str) -> String {
    let h = if caps.hyperlinks { Hyperlink::with_url(url) } else { Hyperlink::default() };
    format!("{h}{}{h:#}", sanitize_label(label))
}
```

- **P1** — `rows()` is what the JSON, CSV/Markdown and web paths read; `rows_rich` is
  named only by the text renderer, in a crate the library and web crates do not depend
  on.
- **P2** — the provided body is the fallback, exactly as in Python.
- **P3** — `caps.hyperlinks == false` yields `Hyperlink::default()`, whose `Display`
  writes nothing (`crates/anstyle-hyperlink/src/hyperlink.rs:52-62`: `let Some(url) =
  self.url.as_ref() else { return Ok(()) };`). The *same* call site produces a plain
  cell, so column widths are computed from the string that will actually be printed.
  This is Cargo's mechanism verbatim.
- **P4** — two guards, because Rust has no markup language to escape against. The URI is
  percent-encoded (`anstyle_hyperlink::path_to_url` for paths, which applies the WHATWG
  path percent-encode set; `percent_encoding` with `CONTROLS.add(b' ')` for other URLs,
  as eza does). The label is control-escaped so a value containing `ESC`, `BEL` or a
  newline cannot terminate the OSC-8 string early or inject a further escape sequence —
  eza's `escape()` is the reference. Note that `anstyle_hyperlink::Hyperlink` does
  **not** sanitize a URL handed to `with_url`; it writes `"\x1B]8;;{url}\x1B\\"`
  unmodified, so sanitizing is the template's obligation.

**Relative time.** No surveyed crate reproduces py's documented contract
(`core/format.py:46-70`): bidirectional, `"just now"` under 60 s, singular/plural, and
coarse 30-day-month / 365-day-year buckets.
- `timeago::Formatter::convert` takes an unsigned `std::time::Duration`, so it has **no
  future direction** — "in 3 hours" is unreachable without a caller-side sign branch
  (`src/lib.rs:447`, and `TimeUnit` at `:135-146` does carry `Months`/`Years`).
- `chrono-humanize` is bidirectional but phrases differently: `Tense::Past => format!("{}
  ago", text)`, `Future => format!("in {}", text)`, `Present => "now"`, and the default
  `Accuracy::Rough` renders "in a month" rather than "in 1 month" (README Quick Start,
  https://gitlab.com/imp/chrono-humanize-rs/-/raw/master/README.md, 2026-09-10).
The recommendation is a ~30-line helper in the CLI crate over the template's date-time
type, with the bucket table transliterated from py `core/format.py:36-43` and the same
seven test cases transliterated from py `tests/core/test_format.py:11-33`. This is
recommended *because the acceptance criterion is string parity with a documented bucket
list*, which is a test-pinned contract rather than a capability, and because both
candidate crates would need more configuration and a sign branch than the helper
contains. `timeago` is the ranked alternative if the owner accepts its phrasing.

**Observable acceptance criteria.**
1. `cmd --format json` output for a model that overrides `rows_rich` contains no byte
   `0x1B` and no `file://` URL in a field whose plain value is a path.
2. The same command with the third format (Markdown or CSV, per R66) is byte-identical
   whether or not the terminal supports hyperlinks.
3. `cmd` with `caps.hyperlinks == true` emits `ESC ] 8 ; ; <url> ESC \ <label> ESC ] 8 ;
   ; ESC \` around the decorated cell.
4. The same command piped to a file emits the plain cell — not a stripped one — and the
   table's column widths are identical to the undecorated run.
5. A model value containing `ESC`, `BEL`, `[`, a newline or a space renders literally;
   the emitted URI contains no raw control byte and no raw space.
6. `relative_time` returns `"just now"`, `"1 minute ago"`, `"5 minutes ago"`, `"3 hours
   ago"`, `"2 days ago"`, `"2 months ago"`, `"2 years ago"`, `"in 2 days"` for the
   inputs py's tests use.
7. The library crate and the web crate do not link `anstyle-hyperlink`
   (`cargo tree -p <lib> -i anstyle-hyperlink` finds nothing).

**Figures (endpoints exactly as fixed in `## Required evidence`; retrieved 2026-09-10).**

| Crate | 90-day dl (`crate.recent_downloads`) | All-time (`crate.downloads`) | Last release (newest unyanked `num`, `created_at`) | Declared `rust_version` | License | Stars / archived / `pushed_at` | Open issues (`search/issues` `total_count`) | RustSec |
|---|---|---|---|---|---|---|---|---|
| `anstyle-hyperlink` | 301,048 | 462,993 | 1.0.2, 2026-03-18T14:39:47Z | 1.66.0 | MIT OR Apache-2.0 | `rust-cli/anstyle`: 170 / false / 2026-09-07T23:13:32Z | 15 (repo-wide) | no page (404) |
| `supports-hyperlinks` | 9,527,350 | 40,277,189 | 3.2.0, 2025-12-17T03:39:03Z | 1.70.0 | **Apache-2.0 only** | `zkat/supports-hyperlinks`: 32 / false / 2025-12-17T03:39:06Z | 1 | no page (404) |
| `anstream` | 175,572,974 | 670,994,993 | 1.0.0, 2026-02-11T13:23:11Z | 1.66.0 | MIT OR Apache-2.0 | (same repo as above) | (same) | **RUSTSEC-2024-0404**, INFO/unsound, *patched >= 0.6.8* |
| `termcolor` | 75,490,014 | 508,531,957 | 1.4.1, 2024-01-10T12:40:32Z | none declared | Unlicense OR MIT | `BurntSushi/termcolor`: 491 / false / 2024-12-31T13:59:34Z | not queried | no page (404) |
| `timeago` | 218,365 | 1,699,089 | 0.6.1, 2026-07-02T11:29:33Z | 1.63 | MIT OR Apache-2.0 | `vi/timeago`: 76 / false / 2026-07-02T11:29:16Z | 4 | no page (404) |
| `chrono-humanize` (gate 2: **marginal pass** — no `rust-version`, but delta master builds it) | 1,568,698 | 10,104,407 | 0.2.3, 2023-07-22T21:23:36Z | none declared | `MIT/Apache-2.0` (legacy, non-SPDX expression) | GitLab-hosted — GitHub figures **inapplicable** | inapplicable | no page (404) |
| `jiff` | 62,726,919 | 184,759,346 | 0.2.35, 2026-07-25T23:45:35Z | 1.70 | Unlicense OR MIT | `BurntSushi/jiff`: 2,919 / false / 2026-08-07T18:00:58Z | not queried | no page (404) |
| `terminal-link` | 265,314 | 1,255,643 | 0.1.0, 2021-03-12T00:29:38Z | none declared | Apache-2.0 OR MIT | `SirWindfield/terminal-link-rs`: 12 / false / 2023-09-05T00:09:56Z | search returns HTTP 422 (repo not indexed) | no page (404) |
| `osc8` | 88,694 | 169,452 | 0.1.0, 2024-08-09T20:42:40Z | none declared | MIT | Codeberg-hosted — GitHub figures **inapplicable** | inapplicable | no page (404) |

**Issue responsiveness** (10 most recently opened issues, `GET
https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc`
then first comment by a maintainer, 2026-09-10):
- `rust-cli/anstyle` — **median 0.109 days (~2.6 h)** across the 8 answered of the 10
  most recent issues; 2 unanswered (#291, #241). All first responses are from `epage`.
  Slowest answered: #300, 38.8 days; #339, 22.0 days.
- `zkat/supports-hyperlinks` — only **3 issues in the repository's lifetime**; the
  single recent one (#7, 2025-07-10) drew an OWNER reply in **0.243 days**. Median over
  n=3 is not meaningful; reported as-is.
- `vi/timeago` — **median 0.124 days** over the 4 issues with maintainer replies
  (#40 0.156 d, #33 0.042 d, #30 0.092 d, #29 8.99 d).

**Maintenance state by the rubric.**
- `anstyle-hyperlink` / `anstream` / `anstyle` — **active**. Repository `pushed_at`
  2026-09-07 (3 days before retrieval); `anstyle-hyperlink` gained a feature release
  five days after its first (`1.0.1` → `1.0.2`, editor-specific links, PR #308);
  maintainer median first response ~2.6 h.
- `supports-hyperlinks` — **stable-quiet**. Last release 2025-12-17, which is 8.8 months
  before the 2026-09-10 retrieval date and therefore trips the rubric's "no release in 6
  months → investigate" trigger. Investigation: the repository has three issues total, the open one was answered by the
  owner the same day, the crate is 40 lines of environment probing whose churn is new
  terminal names, and Cargo pins the current version. No `at-risk` signal — the crate is
  finished, not abandoned. Verdict **stable-quiet**.
- `termcolor` — **stable-quiet**. Last release 2024-01-10, repo `pushed_at` 2024-12-31.
  Same investigation outcome: BurntSushi's own current projects still depend on it, and
  ripgrep master uses its hyperlink API. No concrete at-risk signal.
- `timeago` — **active**. Released 0.6.1 on 2026-07-02; maintainer answers in hours.
- `chrono-humanize` — **stable-quiet, trending at-risk**. Last release 2023-07-22 (over
  3 years). Investigation: README still advertises Travis CI badges, a service retired
  for open source; the crate declares no `rust-version`; it is GitLab-hosted so the
  prompt's GitHub responsiveness figures are inapplicable. I found **no** unpatched
  advisory, **no** maintainer notice and **no** evidence of a broken build on current
  stable, so `dormant` is not warranted by the rubric. Recorded as **stable-quiet** with
  the staleness noted, not as `at-risk`, because the rubric requires a concrete signal
  and I have none.
- `terminal-link` — **stable-quiet by the letter of the rubric, unusable in practice**:
  one release ever, 2021-03-12; `has_issues` is true but the repository is not indexed
  by the issue search API. No advisory, no maintainer notice — so not `dormant`.

**Fitness gates, applied per candidate before popularity.**

| Gate | `anstyle-hyperlink` 1.0.2 | `supports-hyperlinks` 3.2.0 | `termcolor` 1.4.1 | `timeago` 0.6.1 | hand-rolled relative time |
|---|---|---|---|---|---|
| 1 — license compatible with `MIT OR Apache-2.0` | **Pass** — MIT OR Apache-2.0 | **Pass with a caveat** — Apache-2.0 **only**. The template's own dual license is unaffected, but a downstream consumer can no longer take the MIT arm for the whole binary. Cargo (itself MIT OR Apache-2.0) accepts the same constraint, which is the precedent. A `cargo-deny` license allowlist must include `Apache-2.0`. | **Pass** — Unlicense OR MIT | **Pass** — MIT OR Apache-2.0 | **Pass** — no dependency |
| 2 — MSRV within `stable minus 2 minor versions`, declared as `rust-version`, tested in CI | **Pass** — declares `rust-version = "1.66.0"`, far below any stable-minus-2 floor; deps are `libc` (feature `file`) and `percent-encoding` (feature `file`), both long-standing low-MSRV crates | **Pass** — declares `1.70.0`; no dependencies | **Marginal pass** — declares no `rust-version`, so MSRV cannot be read from the manifest; it is nonetheless demonstrably buildable on current stable because ripgrep master compiles against it (`crates/printer/src/hyperlink/mod.rs`, 2026-09-10). See the gate-2 rule stated under `### Excluded by gate`. | **Pass** — declares `1.63`; optional deps `chrono`, `isolang` | **Pass** — governed by the template's own date-time choice |
| 3 — no open RustSec advisory; `unsafe` posture | **Pass** — no advisory page. `unsafe` posture: the crate is `no_std`-capable and the core `Hyperlink` type has none; the **optional `file` feature** pulls `libc` and calls `unsafe { libc::sysconf(...) }` / `unsafe { libc::gethostname(...) }` in `hostname.rs:35,53` to build `file://<host>/...` URLs. Two `unsafe` FFI calls, both in the hostname probe, avoidable by not enabling `file`. | **Pass** — no advisory page; pure `std::env` reads plus `IsTerminal`; no `unsafe` in `src/lib.rs` | **Pass** — no advisory page. `unsafe` posture, verified: `grep -c unsafe` over `src/lib.rs` at HEAD returns **0** (2026-09-10). Windows console support arrives through a Windows-only optional dependency that I did not audit; it is not compiled on the fixed OS matrix | **Pass** — no advisory page; no `unsafe` found in `src/lib.rs` | **Pass** |
| 4 — builds/tested on `ubuntu-latest, macos-latest` | **Pass** — Cargo's own CI builds it on Linux and macOS; the crate is pure Rust with a `cfg(windows)` branch only for URL prefixes. Windows: supported (the `file` feature has an explicit `cfg!(windows)` hostname skip). | **Pass** — `std::env` + `IsTerminal` only; Windows branch reads `WT_SESSION`/`KONSOLE_VERSION` | **Pass** — Windows is its most exercised platform | **Pass** — platform-independent arithmetic | **Pass** |
| 5 — default features and async-runtime coupling | `default = ["std"]`; `file = ["std", "dep:percent-encoding", "dep:libc"]`. **The `file` feature is off by default** and must be enabled to get `path_to_url`/`Editor`. **No async runtime.** | No features. **No async runtime.** | Default `[]` on Unix. **No async runtime.** | `default = ["translations", "isolang", "chrono"]` — **the default pulls `chrono` and `isolang`**; eza sets `default-features = false`. **No async runtime.** | none |
| 6 — binary-size and compile-time cost (qualitative) | Negligible: two small source files plus `percent-encoding` and `libc` only under `file`. `Hyperlink` is a `Display` newtype; no allocation beyond the URL. | Negligible: one dependency-free file of environment lookups. | Small, but larger than needed here — brings a full color abstraction the template only wants a link from. | Small with `default-features = false`; **material** with defaults, since `chrono` and `isolang` (an ISO-639 table) are both non-trivial. | Zero. |

**Baseline review.** No `BASELINE-REVIEW:` line is emitted. F359 is this item's own
ledger row and its verdict is `DIVERGENT`, so nothing is inherited to challenge; and
`grep -n -i -E 'result model|table_rows|table_columns|single source of truth'
docs/port/COMMONALITY.md` returns no rows (2026-09-10), so no retained baseline asserts
that core result models own tabulation. Amendment 2 above is therefore a recommendation
inside R85's own scope, not a challenge to another item — though it is a finding R01
(`ports-and-adapters-seam`, resolved) and R02 (`crate-boundary-enforcement`) should see,
since it says the view trait must sit in the CLI crate.

### Dominant choice

There is no single dominant *pattern* — the field has not converged on where a
presentation variant lives, because most Rust CLIs print rows imperatively rather than
returning a row model at all. There **is** a dominant *mechanism* for the OSC-8 half,
and it is unambiguous: **construct a null-object link carrier from a resolved terminal
capability, and format the label between its normal and alternate `Display` forms.**
Cargo does it with `anstyle_hyperlink::Hyperlink` (`Hyperlink::default()` when
unsupported); ripgrep does it with `termcolor`'s `WriteColor::set_hyperlink` plus an
`InterpolatorStatus` that records whether a link was opened; eza does it with a tri-state
enum resolved against `is_a_tty` before writing the start tag. Three independent,
heavily-used codebases, one shape: **decide, then emit or emit nothing.** The
`anstyle-hyperlink` + `supports-hyperlinks` pairing is the first-party expression of that
shape, and Cargo's adoption of both (2026-03 onward) makes it the default answer for new
code.

For the relative-time half there is no dominant choice: `timeago` (eza) and
`chrono-humanize` (delta) each have one flagship adopter and incompatible contracts.

### Options

*Hook architecture (pattern candidates — crate download figures do not apply; the
reason is given under the Excluded-by-gate field below).*

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| Provided trait method defaulting to the plain method (A1) | Rust Book ch. 10.2, "Default Implementations" (https://doc.rust-lang.org/book/ch10-02-traits.html#default-implementations) | py `core/models.py:59` is the precedent being ported; in Rust the shape is ubiquitous (`Iterator`'s provided methods) | Rust Book, current edition, retrieved 2026-09-10 |
| Renderer-side wrapper/newtype (A2) | Rust API Guidelines newtype guidance (https://rust-lang.github.io/api-guidelines/) | none found for row presentation | — |
| Structured cell enum lowered per renderer (A3) | Rust Book ch. 6.2, exhaustive `match` | ripgrep's `Values`/`HyperlinkPath` are a partial instance (`crates/printer/src/hyperlink/mod.rs:581,710`) | ripgrep master, retrieved 2026-09-10 |

*OSC-8 emission and suppression (crate candidates — figures below).*

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| `anstyle-hyperlink` + `supports-hyperlinks` | https://docs.rs/anstyle-hyperlink; module docs cite the Egmont Koblinger OSC-8 gist and name `supports-hyperlinks` as the detector | **Cargo** (`rust-lang/cargo` `Cargo.toml:23,108`; `crates/cargo-util-terminal/src/shell.rs:13,328-363,616-627`); `cargo-util-terminal`, `cli-battery-pack`, `cargo-bloat-show` (reverse deps) | `anstyle-hyperlink` 1.0.2, 2026-03-18 |
| `termcolor` `WriteColor::set_hyperlink` | https://docs.rs/termcolor — `set_hyperlink` doc: "first call it with a `HyperlinkSpec::open` to write the actual URI to a tty that supports OSC-8 … This defaults to doing nothing"; `supports_hyperlinks` "defaults to `false`" | **ripgrep** (`crates/printer/src/hyperlink/mod.rs:626-707`) | termcolor 1.4.1, 2024-01-10 |
| Hand-rolled bytes + `percent-encoding` | Egmont Koblinger OSC-8 gist | **eza** (`src/output/escape.rs:48-62`) | eza master, `pushed_at` 2026-08-06 |
| `osc8` crate | https://docs.rs/osc8 | none found | 0.1.0, 2024-08-09 |
| `terminal-link` crate | https://docs.rs/terminal-link | none found | 0.1.0, 2021-03-12 |

*Relative time (crate candidates — figures below).*

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| Hand-rolled bucket helper over the template's date-time type | py `core/format.py:36-70` is the specification being ported | py itself | pin `b08bccfb` |
| `timeago` | https://docs.rs/timeago | **eza** (`Cargo.toml:107`, `default-features = false`) | 0.6.1, 2026-07-02 |
| `chrono-humanize` | https://docs.rs/chrono-humanize | **delta** (`Cargo.toml:31`) | 0.2.3, 2023-07-22 |
| `humantime` | https://docs.rs/humantime | very widely used, but formats `Duration`/`SystemTime` literally ("2days 3h"), with no "ago"/"in" direction | 2.4.0, 2026-07-02 |

### Excluded by gate

**The gate-2 rule applied uniformly.** Four candidates declare no `rust-version`
(`termcolor`, `chrono-humanize`, `terminal-link`, `osc8`), so gate 2 cannot be settled
from the manifest for any of them. The rule used throughout this report: an undeclared
MSRV is a **marginal pass** when a currently-maintained adopter demonstrably builds the
crate on current stable, and a **fail** when no such adopter exists, because then nothing
substitutes for the missing declaration. `termcolor` passes marginally (ripgrep master
depends on it); `chrono-humanize` passes marginally (delta master depends on it);
`terminal-link` and `osc8` fail, as below.

- **`terminal-link` 0.1.0** — **fails gate 2**: no `rust-version` declared and **no
  adopter found** among the surveyed projects or in its reverse dependencies, so its
  build on current stable is unevidenced. The single release is 2021-03-12, three
  editions before the fixed `rust-edition = 2024` (`GET
  https://crates.io/api/v1/crates/terminal-link/versions`, 2026-09-10). Corroborating,
  not deciding: 12 stars, `pushed_at` 2023-09-05, and its function is now covered by a
  first-party crate Cargo consumes.
- **`osc8` 0.1.0** — **fails gate 2** on the same rule: no `rust-version` declared and no
  adopter found (`GET https://crates.io/api/v1/crates/osc8/versions`, 2026-09-10).
  Corroborating: hosted on Codeberg, so the prompt's GitHub figures are inapplicable and
  adoption cannot be evidenced through the reverse-dependency route.
- **`humantime`** — not excluded by a gate; **excluded on fit**. It formats a `Duration`
  or `SystemTime` literally and has no past/future direction, so it cannot express
  either half of the contract ("2 days ago" / "in 3 hours"). Recorded here because its
  download figures (60,952,932 recent) would otherwise dominate a popularity-first read.
- **Architectural option A2 (renderer-side wrapper)** — no fitness gate applies (it is a
  pattern, not a crate; gates 1-6 are **inapplicable** for that reason). Rejected on the
  principle test: it recreates the model-to-renderer coupling ADR 0010 rejected by name.

Fitness gates 1-6 are **inapplicable to the three hook-architecture options as such** —
they are language constructs with no crate, license, MSRV, advisory, feature set or
binary-size footprint of their own. The gates were applied instead to every crate each
option would pull in, which is where the risk actually lives, and each option is judged
on the pattern criteria in the `### Principles and implementation` table.

### Up-and-comers

- **`anstyle-hyperlink`** (1.0.0 on 2026-03-13; 1.0.2 on 2026-03-18) — six months old
  and already the mechanism inside Cargo's `Shell`. Its `Editor` enum (`Cursor`, `Grepp`,
  `Kitty`, `MacVim`, `TextMate`, `VSCode`, `VSCodeInsiders`, `VSCodium` —
  `crates/anstyle-hyperlink/src/file.rs`, 2026-09-10) generates editor-specific `file`
  URLs, added by PR #308 "feat(hyperlink): Add editor-specific links" (2026-03-18) — a
  capability no other surveyed crate has, and a plausible future want for a template
  whose `config path` row points at a file the user will open. Only 4 crates.io reverse
  dependencies (2026-09-10), but 301,048 recent downloads, which the Cargo dependency
  explains. Risk: a 1.0 crate six months old inside an actively-evolving workspace;
  mitigated by `anstyle`'s stability discipline (the workspace's whole purpose is
  semver-stable styling vocabulary) and by the fact that the API surface used here is
  two constructors and a `Display` impl.
- **`jiff`** — if the template picks `jiff` as its date-time crate, the hand-rolled
  relative-time helper is ~10 lines shorter (`Timestamp::until` returns a signed `Span`,
  giving the sign branch for free). Not a candidate for this item; noted because the
  helper's shape depends on a choice no surveyed research item appears to own.

### Fit for this template

**CLI.** This is the only shape the decision applies to. The fit is direct: the CLI crate
owns the `TableView` trait, the text renderer is the sole caller of `rows_rich(caps)`,
and `caps` is derived once from whatever gate R65 selects. Cargo is the reference: a CLI
of the same class, resolving hyperlink support from the same two inputs (a color-choice
enum and a capability probe) and passing a null-object carrier to `format!`. One
template-specific fit note: py's working example is `ConfigPath`, whose cell is a
filesystem path — `anstyle_hyperlink::path_to_url` (feature `file`) is exactly that case,
including the `file://<hostname>/...` form whose documented purpose is "to avoid issues
with opening a link scoped to the computer you've SSH'ed into"
(`crates/anstyle-hyperlink/src/file.rs:17-30`, 2026-09-10). Enabling the `file` feature
is therefore recommended and brings the two `unsafe` `libc` calls noted under gate 3.

**Library.** The library crate must be **unaffected**, and under the recommended design
it is: the `TableView` trait and the `link`/`relative_time` helpers live in the CLI
crate, so the library exposes plain domain types and no consumer of the library links
`anstyle-hyperlink`, `supports-hyperlinks` or `percent-encoding` on this item's account.
This is a strict improvement over the Python arrangement, where `core/format.py` imports
`rich.markup.escape` and `core/models.py` imports `rich_link` — a Rich dependency in the
layer documented as "no printing", which py's own HEX-15 finding says should move. Under
A1-with-CLI-placement, the equivalent leak cannot compile.

**Web service.** Also **unaffected, structurally**. The web crate serialises domain types
through `serde`; it never sees `TableView`. There is no risk of an OSC-8 escape reaching
an HTTP response body, and unlike Python no test is needed to prove it — the method is
not in scope. If the web surface later wants links, it wants `<a href>`, which is a
different lowering and the argument for the A3 runner-up (below).

### Recommendation

Adopt the **capability-gated rich row variant with null-object carriers**, in the CLI
crate:

1. **Hook (A1).** A `TableView` trait in the CLI crate with `columns()`, `rows()` and a
   **provided** `rows_rich(&self, caps: TermCaps) -> Vec<Vec<String>>` whose default body
   is `self.rows()`. Only the text renderer calls `rows_rich`; JSON, the third format
   (per R66) and the web path use `rows()` or serialise the domain type directly.
   Placement in the CLI crate, not the core/library crate, per py's own HEX-15 finding.
2. **Hyperlinks.** `anstyle-hyperlink` **1.0.2** with the `file` feature, gated by
   `supports-hyperlinks` **3.2.0**, combined with R65's resolved color choice — Cargo's
   exact composition (`shell.rs:328-340`): emit `Hyperlink::with_url(url)` only when the
   stream's choice is "always ANSI" *and* the capability probe says yes; otherwise
   `Hyperlink::default()`, which renders to nothing. Cell text is built as
   `format!("{link}{label}{link:#}")`.
3. **Escaping (P4).** Percent-encode every URI — `anstyle_hyperlink::path_to_url` for
   paths, `percent_encoding` with at least `CONTROLS.add(b' ')` for other URLs (eza's
   set) — and control-escape every label before it enters the cell, so no data-derived
   byte can terminate or extend the escape sequence. `percent-encoding` carries no
   figures row of its own above because it is not a separate adoption decision: it
   arrives transitively with `anstyle-hyperlink`'s `file` feature
   (`crates/anstyle-hyperlink/Cargo.toml`: `file = ["std", "dep:percent-encoding",
   "dep:libc"]`, 2026-09-10), and its RustSec page returns 404 (no advisory), so it adds
   no dependency the recommendation has not already accepted.
4. **Relative time.** A ~30-line helper in the CLI crate transliterating py
   `core/format.py:36-70` (buckets `365d/30d/1d/1h/1min`, `"just now"` under 60 s, `"in
   …"` for future), with py's test cases transliterated as the acceptance pin.

Why this and not the alternatives: it is the only option that preserves P2 exactly (a
defaulted opt-in, no renderer-side type switching), it realizes P3 with the mechanism
three independent flagship Rust CLIs converged on rather than a Python mechanism Rust
lacks, it moves the hook to the layer py's own design document says it belongs in, and it
adds two small, first-party-adopted crates whose combined footprint is a `Display`
newtype and forty lines of environment probing.

### Ranked runner-up

**A3 — structured cell enum lowered per renderer** (`enum Cell { Text(String), Link {
label, url }, Moment(Timestamp) }`, with each renderer lowering `Cell` to its own
representation).

It wins under any one of these conditions:

- **The chosen table crate mis-measures OSC-8-bearing cells.** If validation step V4
  below shows `comfy-table` (even with `custom_styling`) or `tabled` counting the
  zero-width OSC-8 bytes toward column width, A1's premise — that the decorated string
  can be handed to the table crate as a cell — fails, and the renderer must know which
  part of the cell is decoration. A3 gives it that knowledge. This is the most likely
  trigger and it is currently **unverified**.
- **A fourth consumer of the same rows appears.** If the web service grows an HTML view,
  or the third format becomes one that has its own link syntax (Markdown's
  `[label](url)` — note py's `_to_markdown` today emits *plain* cells and forgoes
  Markdown links entirely), then one `Cell` lowered three ways beats three parallel
  `rows_*` methods.
- **The escaping obligation proves error-prone in review.** A3 makes it impossible to
  forget: the label is sanitized inside the single `Cell::Link` lowering, not at every
  model that builds a decorated string.

Cost of taking A3 now instead: every result type is rewritten onto `Cell` even though
only one (py's `ConfigPath` analogue) decorates anything, which is the "heavier machinery
than the template needs" ADR 0010 identified — an argument that still holds while there
is exactly one decorated cell. ADR 0010's own escape hatch applies to Rust too: `rows()`
stays the stable interface, so A1 can grow into A3 without breaking the plain-row
callers.

Second runner-up, for the hyperlink mechanism only: **`termcolor`'s
`WriteColor::set_hyperlink`** (ripgrep's choice). It wins if R65 selects `termcolor` as
the template's color writer, because then the hyperlink capability arrives free on a
trait already in the dependency tree and the "emit nothing when unsupported" behavior is
the writer's default (`set_hyperlink` "defaults to doing nothing"; `supports_hyperlinks`
"defaults to `false`"). It loses here because it is a *streaming* API: `set_hyperlink`
writes to a writer, whereas a table cell is a `String`. Bridging that needs an `Ansi<Vec<u8>>`
scratch buffer per decorated cell — more machinery than `format!("{h}{label}{h:#}")`.

### Tradeoffs

**Versus A3 (structured cells).** The pick gives up compile-time enforcement that every
renderer handles every decoration kind, and gives up the guarantee that a future format
cannot silently inherit text-format markup. Accepted because there is exactly one
decorated cell in the template today, because placement in the CLI crate already makes
the library and web paths structurally unable to call the hook, and because the migration
A1 → A3 is additive on the trait rather than a rewrite of `rows()`.

**Versus A2 (renderer-side wrapper).** The pick gives up nothing of value; A2's only
advantage — a plain trait with no presentation method on it — is bought by coupling the
renderer to the concrete model set, which is the coupling ADR 0010 rejected.

**Versus `termcolor` for hyperlinks.** The pick gives up reuse of a writer trait the
template may already depend on, and gives up `termcolor`'s Windows-console handling.
Accepted because cells are strings, not writers, and because Windows is explicitly "noted,
not required" under gate 4 while the fixed matrix is `ubuntu-latest, macos-latest`.

**Versus `timeago` for relative time.** The pick gives up a maintained dependency,
translations into ~30 languages, and eza's adoption evidence. Accepted because `timeago`
cannot express a future instant at all (`convert` takes an unsigned
`std::time::Duration`), so contract parity with py would still require caller-side sign
handling plus `too_low`/`max_unit`/`num_items` configuration — more code than the helper
it would replace — and because its default feature set pulls `chrono` and `isolang` into
a template that has not chosen a date-time crate through this item.

**Versus `chrono-humanize`.** The pick gives up bidirectionality that comes for free and
delta's adoption evidence. Accepted because its phrasing differs from the pinned contract
("in a month" vs "in 1 month"; "now" vs "just now"), it declares no `rust-version`, and
its last release is over three years old.

**Cost the pick accepts outright.** `supports-hyperlinks` is **Apache-2.0 only**, so the
CLI binary's effective terms include Apache-2.0 even though the template stays `MIT OR
Apache-2.0`. Accepted because Cargo — itself `MIT OR Apache-2.0` — takes the same
dependency, and because the alternative (hand-rolling the terminal-capability table, as
eza does) means maintaining a list of terminal names forever.

**Performance.** Stated with its workload, because the prompt requires it and because the
honest answer is that it does not matter: the hot path is `format!` over a handful of
cells for a table a human reads, on the order of 10-100 rows. No crate here allocates
beyond the URL string; `Hyperlink`'s `Display` writes 6 + `url.len()` bytes for the open
tag and 6 for the close. I ran **no** benchmark and I did not find a published one for
any candidate, so no latency, throughput or resource figure is asserted. Compile-time and
binary-size costs are the qualitative statements in the gate-6 row.

### Parameters

- `owns` — **none.** R85's `owns:` field in `## Couplings` is empty; this item registers
  no parameter.
- `assumes rust-edition = 2024` (fixed, owner-decided 2026-09-02, `docs/port/PARAMETERS.md:8`).
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version in Cargo.toml and tested in CI` (fixed, `PARAMETERS.md:7`).
  Every recommended crate declares a `rust-version` at or below 1.70.0, so none of them
  constrains the floor.
- `assumes license = MIT OR Apache-2.0` (fixed, `PARAMETERS.md:10`). Noted above:
  `supports-hyperlinks` is Apache-2.0 only; the repository license is unchanged, and a
  `cargo-deny` allowlist must accept `Apache-2.0`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed, `PARAMETERS.md:9`).
- Non-registry assumption on **R65** — that the color gate resolves to a value the CLI
  can read as "this stream will accept ANSI escape codes", the way Cargo reads
  `anstream::ColorChoice::AlwaysAnsi`. If R65 selects `anstream`, `TermCaps` is one line.
  If R65 selects a gate that exposes only a boolean "color on/off", `TermCaps` still
  works; the hyperlink capability is then `color_enabled && supports_hyperlinks::on(Stdout)`.
  Either shape satisfies this item. R65 additionally acquires one input it may not have
  scoped: **`FORCE_HYPERLINK`**, which `supports-hyperlinks` honors independently of
  `NO_COLOR`/`FORCE_COLOR` (`src/lib.rs:13-16,68-70`).
- Non-registry assumption on **R66** — that the text format's rows are a sequence of
  string cells per row, **and that the table-rendering crate R66 selects has no inline
  markup syntax of its own**. If R66's answer makes cells a richer type, this item's
  `rows()` / `rows_rich()` signatures follow R66's cell type unchanged in shape. If R66
  instead selects a Rich-style crate that parses markup inside cell text — `rich_rust`,
  "A Rust port of Python's Rich library", 57,751 recent downloads (`GET
  https://crates.io/api/v1/crates?q=osc8`, 2026-09-10), is the one such crate this survey
  surfaced — then P4's escape set reverts to that crate's markup metacharacters, exactly
  as in py, **in addition to** the control-byte and percent-encoding guards. That would
  change this item's escaping answer, not its hook or suppression answer.
- **No `CONFLICT:` line is emitted.** `consumes:` is empty in `## Couplings`, and nothing
  recommended here requires a fixed parameter to change.

### Migration implications

File-level changes in the template (paths follow the CLI + library + web workspace shape;
adjust to whatever R01/R02 fix as crate names):

| File | Change |
|---|---|
| `crates/cli/Cargo.toml` | Add `anstyle-hyperlink = { version = "1.0.2", features = ["file"] }` and `supports-hyperlinks = "3.2.0"`. Both in the **CLI crate only** — not the workspace-wide `[workspace.dependencies]` unless other members need them. |
| `crates/cli/src/view.rs` (new) | `trait TableView` with `columns()`, `rows()`, provided `rows_rich(&self, caps: TermCaps)`; `struct TermCaps { hyperlinks: bool }`. The Rust counterpart of py `core/models.py:40-71`, relocated per HEX-15. |
| `crates/cli/src/view_models.rs` (new) | The view types implementing `TableView` (`ConfigPathView` etc.), wrapping domain types from the library crate. Only the path/URL-bearing view overrides `rows_rich`. Counterpart of py `core/models.py:82-224`. |
| `crates/cli/src/fmt.rs` (new) | `pub fn link(caps, label, url) -> String`, `pub fn sanitize_label(&str) -> Cow<str>`, `pub fn relative_time(moment, now) -> String`. Counterpart of py `core/format.py`. |
| `crates/cli/src/output.rs` | The text renderer calls `result.rows_rich(caps)`; the JSON and third-format renderers call `result.rows()` or serialise directly. Counterpart of py `cli/output.py:224-241`. |
| `crates/cli/src/context.rs` | Resolve `TermCaps` once, next to R65's color resolution, from `color_choice` + `supports_hyperlinks::on(Stream::Stdout)`. |
| `crates/lib/**`, `crates/web/**` | **No change** — and that is the deliverable. Neither crate gains a dependency on `anstyle-hyperlink`, `supports-hyperlinks` or `percent-encoding` from this item. |
| `crates/cli/tests/` | The seven acceptance checks in `### Validation strategy`. |
| `deny.toml` (if R13/R31 introduce `cargo-deny`) | License allowlist must include `Apache-2.0` for `supports-hyperlinks`. |
| `docs/adr/` | An ADR recording this decision, including the two amendments to ADR 0010's shape (capability parameter; CLI-crate placement). |

Not changed by this item: which formats exist and how rows are produced (R66), and the
color/TTY gate (R65).

### Validation strategy

Every command below is **proposed, not executed**. No Rust code was written or run for
this report — the template does not exist and P03 builds it. What *was* executed is the
evidence gathering: crates.io and GitHub REST queries, RustSec page fetches, and reads of
Cargo's, ripgrep's, eza's, miette's, delta's, `termcolor`'s, `anstyle-hyperlink`'s,
`supports-hyperlinks`' and `timeago`'s sources, plus the pinned py and ts trees.

```bash
# V1 — machine formats carry no escape codes and no synthesized URL (P1)
cargo run -p cli -- config path --format json  | rg -q $'\x1b'  && exit 1
cargo run -p cli -- config path --format json  | rg -q 'file://' && exit 1

# V2 — the third format is invariant under terminal capability (P1)
FORCE_HYPERLINK=1 cargo run -p cli -- config path --format markdown > /tmp/a
FORCE_HYPERLINK=0 cargo run -p cli -- config path --format markdown > /tmp/b
cmp /tmp/a /tmp/b

# V3 — decoration is emitted when, and only when, capability says so (P3)
FORCE_HYPERLINK=1 CLICOLOR_FORCE=1 cargo run -p cli -- config path \
  | rg -q $'\x1b\\]8;;file://'
cargo run -p cli -- config path > /tmp/piped        # not a TTY
rg -q $'\x1b' /tmp/piped && exit 1

# V4 — DECIDING CHECK: column widths are identical decorated vs plain.
#      This is the check that can overturn the recommendation in favour of A3.
FORCE_HYPERLINK=1 CLICOLOR_FORCE=1 cargo run -p cli -- config path \
  | perl -pe 's/\e\]8;;[^\e]*\e\\//g' > /tmp/stripped
cargo run -p cli -- config path --color never > /tmp/plain
cmp /tmp/stripped /tmp/plain     # any diff = the table crate mis-measured OSC-8

# V5 — no data-derived byte can forge or escape the sequence (P4)
cargo test -p cli --test escaping   # cases: label with ESC, BEL, '[', '\n', ' ';
                                    # path with a space -> %20 in the URI

# V6 — relative-time string parity with the pinned Python contract
cargo test -p cli --test relative_time   # the 8 assertions from
                                         # py tests/core/test_format.py:11-33

# V7 — the decoration crates never reach the library or the web crate
cargo tree -p lib -i anstyle-hyperlink   2>&1 | rg -q 'not found|nothing to print'
cargo tree -p web -i supports-hyperlinks 2>&1 | rg -q 'not found|nothing to print'
```

**Expected behavior.** V1, V2, V5, V6, V7 pass under the recommended design by
construction. V3 passes because `Hyperlink::default()` renders empty. **V4 is the one I
cannot predict**: `comfy-table`'s ANSI awareness comes from `ansi-str` and `console`
behind the `custom_styling` feature, and I found no documentation stating that either
discounts a non-SGR OSC sequence when measuring. Run V4 first in P03, against whichever
table crate R66 selects. If V4 fails, the fix is either a table crate whose width
function takes a caller-supplied measurement, or the A3 runner-up, where the renderer
knows the label independently of the escape bytes.

**Minimal realistic example** (what P03 should build to run the above): one command,
`config path`, returning a view over `{ path: PathBuf, exists: bool }`, with columns
`["Config path", "Exists"]`; `rows()` returns the raw path string; `rows_rich(caps)`
returns `[[link(caps, &path, &path_to_url(&path)?), yes_no]]` and falls back to `rows()`
when the path has no `file://` form — the exact structure of py `ConfigPath` and its
relative-path fallback (`core/models.py:137-142`, pinned by
`tests/core/test_format.py:49-51`). Add a second view carrying a timestamp so V6 exercises
`relative_time` through a real row — something py itself never did (see below).

### Confidence & re-verify trigger

**High confidence** on the hyperlink half. Three independent flagship Rust CLIs converge
on one mechanism, one of them is Cargo, and the recommended crates are the ones Cargo
declares. The evidence is primary source read at HEAD, not secondary description.

**Medium-high confidence** on the hook architecture. A1 is the faithful port and A2 is
clearly wrong, but A1-versus-A3 rests on a judgement about how many decorated cells the
template will have, and on V4, which is unverified. If P03's V4 fails, switch to A3
without re-opening the item.

**Medium confidence** on the relative-time recommendation. Recommending a hand-rolled
helper over two maintained crates is the kind of call the research mandate is right to be
suspicious of. It rests on two verified facts — `timeago` has no future direction,
`chrono-humanize` phrases differently and is three years stale — and one judgement, that
exact string parity with py's bucket list is worth more than a dependency. If the owner
does not require string parity, `timeago` with `default-features = false` (eza's
configuration) is the better answer and this reverses.

**Re-verify triggers.**
1. **R65 resolves.** Re-check that its gate exposes something equivalent to
   `anstream::ColorChoice::AlwaysAnsi`, and that `FORCE_HYPERLINK` is placed in its
   precedence chain.
2. **R66 resolves.** If the text-mode cell type is not `String`, re-derive the
   `rows_rich` signature.
3. **V4 fails in P03.** Switch to A3.
4. **`anstyle-hyperlink` before 1.1.** It is six months old; re-check `crates.io` for a
   yanked 1.0.2 or a breaking 2.0 before P03 pins it.
5. **`supports-hyperlinks` relicenses or stalls past ~2026-12** (a year without a
   release, on a crate whose only churn is new terminal names). The fallback is Cargo's
   own wrapper shape plus a local table, or eza's approach.
6. **Cargo drops `anstyle-hyperlink`.** The strongest single reason to adopt it is that
   Cargo declares it; if `rust-lang/cargo`'s `Cargo.toml` stops declaring it, revisit.

**LOW question — other rich-only presentation methods on py's result models.** Answered
by a complete read of `core/models.py` at pin `b08bccfb` (all `class`/`def` lines
enumerated) and a repository-wide `git grep` at the pin. Findings:

- **`table_rows_rich` is the only rich-only method.** The other four hooks —
  `table_title()`, `table_columns()`, `table_rows()`, `human_note()` — are shared by the
  text and Markdown renderers, and `table_rows()` additionally backs the rich default.
  No second presentation-variant method exists.
- **`ConfigPath.table_rows_rich` (`core/models.py:137-142`) is the only override in the
  entire repository.** `ProjectList`, `ConfigValue`, `DoctorReport` and
  `DiagnosticsBundle` all inherit the plain default.
- **`relative_time()` is defined, documented and unit-tested, but never wired into a
  model.** `git grep -n 'relative_time' b08bccfb` returns only `core/format.py:46`
  (definition), `tests/core/test_format.py` (7 assertions), and prose in ADR 0010 and
  `core/models.py`'s docstring. No result model at the pin carries a timestamp column, so
  no row has ever rendered a relative time in py. **Consequence for this item:** the
  relative-time half of the requirement is specified and tested but not
  production-exercised in the source repository, which lowers the evidential weight of
  py's exact bucket list as a *requirement* and correspondingly raises the value of
  asking the owner whether string parity matters (see `### Confidence & re-verify
  trigger`). It also means P03's V6 exercises a path py never did.
- **The Rich coupling reaches into `core`.** `core/format.py:34` imports
  `from rich.markup import escape`, and `core/models.py:37` imports `rich_link` — so the
  layer documented as "no printing" imports the terminal-rendering library. This is the
  concrete form of the leak py's HEX-15 finding targets, and the concrete thing the Rust
  design avoids by placing the trait in the CLI crate.
- **TypeScript has no counterpart, confirmed at the pin.** `git grep -n -i -E
  'osc|hyperlink|relative_?time|timeAgo|relativeTime' cb1cbcb2` returns only three
  `pnpm-lock.yaml` lines for a transitive `supports-hyperlinks@3.2.0` (`:2025`, `:3584`,
  `:3870`) — a dependency of a dependency, not a feature. `TS_PORT_DECISIONS.md` records
  no decision here, as `## Context` states. So the ts repository has the *capability* in
  its tree and uses none of it: this is a **missing capability in ts**, not a justified
  ecosystem difference, and the follow-on project should treat it as such.

### Sources

Pinned source repositories (read via `git show <pin>:<path>`, 2026-09-10):
- py `b08bccfb`: `src/py_launch_blueprint/core/models.py` (:37 rich import, :40-71
  `CLIResult` hooks, :59-67 `table_rows_rich`, :122-142 `ConfigPath`);
  `src/py_launch_blueprint/core/format.py` (:22-30 per-mode contract docstring, :34 rich
  import, :36-43 unit table, :46-70 `relative_time`, :73-85 `rich_link`);
  `src/py_launch_blueprint/cli/output.py` (:224-241 `_render_text` and the
  `table_rows_rich` consumption point, :243-259 `_to_markdown` using plain rows);
  `tests/core/test_format.py` (all 8 tests); `docs/adr/0010-rich-row-variant-on-result-models.md`;
  `docs/design/0005-hexagonal-architecture-and-enforcement.md:190-195` (HEX-15);
  `EXAMPLECLI.md:54-57`.
- ts `cb1cbcb2`: repository-wide grep for OSC/hyperlink/relative-time terms (only
  `pnpm-lock.yaml:2025,3584,3870`).

Programme documents (working tree, 2026-09-10): `docs/port/COMMONALITY.md:363` (F359);
`docs/port/PARAMETERS.md:7-10`; `docs/port/BASELINE-REVIEW.md`;
`research/topics/65-color-enablement-chain/prompts/color-enablement-chain.prompt.md`;
`research/topics/66-output-format-surface/prompts/output-format-surface.prompt.md`.

crates.io API (`User-Agent` header sent on every request, 2026-09-10):
`GET /api/v1/crates/{anstyle-hyperlink,supports-hyperlinks,anstream,termcolor,timeago,chrono-humanize,humantime,jiff,terminal-link,osc8,comfy-table,tabled,ansi-width}`;
`GET /api/v1/crates/<name>/versions` for each; `GET /api/v1/crates/anstyle-hyperlink/reverse_dependencies`;
`GET /api/v1/crates/supports-hyperlinks/reverse_dependencies`; `GET /api/v1/crates?q=...&sort=downloads`
for `hyperlink`, `osc8`, `time ago human`.

GitHub REST (2026-09-10): `GET https://api.github.com/repos/<o>/<r>` for
`zkat/supports-hyperlinks`, `SirWindfield/terminal-link-rs`, `vi/timeago`,
`rust-cli/anstyle`, `BurntSushi/jiff`, `BurntSushi/ripgrep`, `zkat/miette`,
`eza-community/eza`, `dandavison/delta`, `chronotope/humantime`, `BurntSushi/termcolor`;
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for
`total_count`; `GET .../search/issues?q=repo:<o>/<r>+is:issue&sort=created&order=desc&per_page=10`
plus `.../issues/<n>/comments` for responsiveness.

RustSec (2026-09-10): `https://rustsec.org/packages/<name>.html` for
`anstyle-hyperlink`, `supports-hyperlinks`, `timeago`, `chrono-humanize`, `termcolor`,
`anstream`, `percent-encoding`, `jiff`, `terminal-link`;
`https://rustsec.org/advisories/RUSTSEC-2024-0404.html`.

Upstream sources read at HEAD (2026-09-10):
`https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml`;
`.../rust-lang/cargo/master/crates/cargo-util-terminal/src/shell.rs`;
`https://raw.githubusercontent.com/rust-cli/anstyle/main/crates/anstyle-hyperlink/{src/lib.rs,src/hyperlink.rs,src/file.rs,src/hostname.rs,Cargo.toml}`;
`.../rust-cli/anstyle/main/crates/anstream/src/{lib.rs,adapter/strip.rs}`;
`https://raw.githubusercontent.com/zkat/supports-hyperlinks/main/{src/lib.rs,Cargo.toml}`;
`https://raw.githubusercontent.com/BurntSushi/termcolor/master/src/lib.rs`;
`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/printer/src/hyperlink/mod.rs`;
`https://raw.githubusercontent.com/eza-community/eza/main/{Cargo.toml,src/output/escape.rs,src/output/file_name.rs}`;
`https://raw.githubusercontent.com/zkat/miette/main/Cargo.toml`;
`https://raw.githubusercontent.com/dandavison/delta/main/Cargo.toml`;
`https://raw.githubusercontent.com/vi/timeago/master/{src/lib.rs,Cargo.toml}`;
`https://raw.githubusercontent.com/Nukesor/comfy-table/main/Cargo.toml`;
`https://gitlab.com/imp/chrono-humanize-rs/-/raw/master/{README.md,src/humantime.rs}`.

Rust project documentation (2026-09-10): the Rust Book ch. 6.2 (exhaustive `match`) and
ch. 10.2 (default trait implementations); `std::io::IsTerminal`. Protocol reference:
Egmont Koblinger, "Hyperlinks (a.k.a. HTML-like anchors) in terminal emulators"
(https://gist.github.com/egmontkob/eb114294efbcd5adb1944c9f3cb5feda), cited by
`anstyle-hyperlink`'s own module documentation.

**Method notes.** Endpoints queried: crates.io `/api/v1/crates/<name>`,
`/api/v1/crates/<name>/versions`, `/api/v1/crates/<name>/reverse_dependencies` and
`/api/v1/crates?q=` (User-Agent header sent); GitHub REST `/repos/<o>/<r>`,
`/search/issues`, `/repos/<o>/<r>/issues/<n>/comments`, `/repos/<o>/<r>/contents/<dir>`;
`rustsec.org/packages/<name>.html` and `/advisories/<id>.html`;
`raw.githubusercontent.com` and `gitlab.com/-/raw` for source files;
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>` and `git -C ~/c/ts-launch-blueprint
grep cb1cbcb2` for the pinned trees. Retrieval date for all of the above: 2026-09-10.
**Could not verify:** (a) whether `comfy-table` with `custom_styling`, or `tabled` with
its `ansi` feature, discounts a zero-width OSC-8 sequence when computing column width — I
found no documentation either way, and this is validation step V4, the check that can
overturn the recommendation; (b) open-issue `total_count` for
`SirWindfield/terminal-link-rs` — `GET /search/issues?q=repo:SirWindfield/terminal-link-rs+is:issue+is:open`
returns HTTP 422 "cannot be searched", although `/repos/...` reports `has_issues: true`
and `archived: false`; (c) GitHub star, archive, `pushed_at` and issue figures for
`chrono-humanize` (GitLab-hosted) and `osc8` (Codeberg-hosted) — recorded as
**inapplicable** with the reason, not estimated; (d) issue-responsiveness medians for
`termcolor` and `BurntSushi/jiff`, not queried, since neither is the recommended crate for
its half; (e) any published benchmark for the candidates — none found, so no latency,
throughput or resource figure is asserted anywhere in this report; one unauthenticated
`api.github.com/search/code` call was rate-limited (HTTP 403) and its result was obtained
instead by reading the files directly. No Rust code was compiled or executed: every
command in `### Validation strategy` is proposed for P03, not run.
