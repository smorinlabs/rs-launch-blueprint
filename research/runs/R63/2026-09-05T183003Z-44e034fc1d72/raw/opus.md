# R63 — progress-spinner (crate) — Opus raw report

Item: R63 `progress-spinner`, kind `crate`, effort `focused`. All figures retrieved
**2026-09-10** unless a different date is stated on the line. Reference toolchain for
MSRV arithmetic: stable is **1.98.1**, manifest date `2026-09-03`
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, retrieved 2026-09-10),
so the policy floor `stable minus 2 minor versions` = **1.96**.

### Landscape

**The category this item decides.** A *transient, non-quantified activity indicator*
written to the diagnostic stream while a single blocking network call runs, plus the
policy that decides whether it renders at all. It is deliberately *not* the
determinate-progress category (byte counters, multi-bar downloads); the template has
exactly one fetch of unknown duration and no known total, so the decision is about a
spinner and its suppression gate, not about progress bars.

**Three-bin map of the Rust field.**

| Bin | Members found | Note |
|---|---|---|
| Built-in / first-party toolchain | **None for rendering.** `std` ships no spinner, no progress abstraction, and no terminal-size API. The only first-party pieces are the *gate inputs*: `std::io::IsTerminal` (stabilized **Rust 1.70.0**, 2023-06-01 — `https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md` line 3817, retrieved 2026-09-10) and `std::env::var_os` | Stating this explicitly is a finding: unlike `serde` or `clap`'s domains there is no toolchain default to defer to, so a crate choice is unavoidable for rendering, while the gate can be pure `std`. |
| Established industry standard | **`indicatif`** (console-rs) — 214,311,835 all-time downloads; **`console`** (its terminal layer, 343,168,320 all-time) ; **`spinners`** (FGRibreau) 7,123,963 all-time | `indicatif` is roughly 30× `spinners` on all-time volume and ~72× on 90-day volume; the field has one clear centre. |
| Up-and-comer | **`cliclack`** (fadeevab, Clack port, 3,340,001 all-time, 1,028,866/90d); **`spinoff`** (ad4mx); **`spinach`** (etienne-napoleone); **`throbber-widgets-tui`** (arkbig) | `cliclack` is the only one growing; `throbber-widgets-tui` is a ratatui widget requiring a full-screen alternate-screen app and is category-wrong for a one-shot CLI. |

Every shortlisted candidate below is drawn from this map; none was added from
familiarity. Endpoint for all download/version figures:
`GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `GET https://crates.io/api/v1/crates/<name>/versions`
(newest `yanked: false`), retrieved 2026-09-10.

**Authoritative sources used, and why each is authoritative.**

1. **`rust-lang/rustup` — the official Rust toolchain installer, maintained by the Rust
   project itself.** It declares `indicatif = "0.18"` at line 62 of its manifest
   (`https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml`, retrieved
   2026-09-10; repo 7,034 stars, pushed 2026-09-10, `GET
   https://api.github.com/repos/rust-lang/rustup`). This is first-party Rust project
   practice, not a third-party opinion — the strongest single authority available for
   this category, because the Rust project chose it for the binary every Rust user runs.
2. **The Rust standard library release notes** (`RELEASES.md` in `rust-lang/rust`) for
   the stabilization version of `IsTerminal`. Primary project publication.
3. **Maintainers' own source, read at the released tag, not at `main`.** For every
   behavioral claim below I read the exact file at the pinned tag
   (`raw.githubusercontent.com/console-rs/indicatif/0.18.6/...`,
   `.../console/0.16.6/...`), so the claims are verifiable against a published artifact
   rather than a moving branch.
4. **`astral-sh/uv`** (89,684 stars, pushed 2026-09-10, `GET
   https://api.github.com/repos/astral-sh/uv`) as a *maintained reference
   implementation* of the exact architecture this item needs — see
   `### Principles and implementation`. Authoritative as production practice at very
   large scale by a team whose CLI-UX decisions are widely copied, not as an opinion piece.
5. **crates.io and the GitHub REST API** as the figure endpoints mandated by the prompt.
6. **RustSec** (`https://rustsec.org/packages/<name>.html`) for advisories, with a
   control check (below) proving the 404-means-clean reading.

No single blog post is relied on anywhere in this report.

**Well-regarded projects surveyed, with the evidence that they are well regarded.**
`indicatif` reports **5,301 reverse dependencies**
(`GET https://crates.io/api/v1/crates/indicatif/reverse_dependencies?per_page=40`,
`meta.total`, retrieved 2026-09-10). Named adopters confirmed in their own manifests or
in that reverse-dependency listing, each with its star count from
`GET https://api.github.com/repos/<o>/<r>` (retrieved 2026-09-10) as the
well-regarded evidence:

| Project | Stars | Why it is a relevant reference | Evidence |
|---|---|---|---|
| `astral-sh/uv` | 89,684 | Highest-volume new Rust CLI; same shape (one CLI, JSON-capable stdout, progress on stderr) | `indicatif = { version = "0.18.0" }` line 170, `https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml` |
| `uutils/coreutils` | 24,060 | Rust reimplementation of GNU coreutils; stdout purity is existential there | `uu_mv`, `uu_cp` in indicatif reverse-deps |
| `rerun-io/rerun` | 11,425 | Large Rust product with CLI + library + service surfaces | `rerun`, `re_video`, `re_auth` in reverse-deps |
| `huggingface/tokenizers` | 11,027 | Library-first crate with a CLI/Python surface | `tokenizers` in reverse-deps |
| `rust-lang/rustup` | 7,034 | First-party Rust project | `indicatif = "0.18"` line 62 of its `Cargo.toml` |
| `flamegraph-rs/flamegraph` | 6,024 | Widely used cargo subcommand | `flamegraph` in reverse-deps |
| `nextest-rs/nextest` | 3,283 | The de-facto modern Rust test runner | `nextest-runner` in reverse-deps |
| `cargo-generate/cargo-generate` | 2,485 | The dominant Rust *template* tool — closest peer to this template's own domain | `cargo-generate` in reverse-deps |

Newer popular projects (`uv`, `rerun`, `nextest`) weight the same way as the older
ones: they all picked `indicatif`. I found no mainstream Rust CLI in this survey that
picked `spinners`, `spinoff` or `spinach` over it.

### Principles and implementation

**The shared requirement.** *A user-attended run of a command whose duration is
dominated by one network call must show that the program is alive; a
non-user-attended run must emit nothing extra, so that redirected or piped output is
byte-identical to a machine's expectation.*

**Source and agreement level.** The requirement is recorded as ledger row **F283**
(`docs/port/COMMONALITY.md:287`, verdict `DIVERGENT`, ts-only) and as
`docs/port/areas/cli-framework-ux.md:27`. Its agreement level is
**capability/standard**, and the standard has two halves that must agree across
py, ts and rs:

- **Stream placement is a standard and must agree**: progress is diagnostics, so it goes
  to stderr and never to stdout. The TypeScript decision record states this explicitly
  and names the wart it repairs — "Stderr-by-default satisfies cli-standards R7.1
  (progress=diagnostics) and fixes the source wart where progress text polluted stdout"
  (`git -C ~/c/ts-launch-blueprint show cb1cbcb2:docs/port/TS_PORT_DECISIONS.md`, line 174,
  retrieved 2026-09-10). D-016(5) line 205 records the same as an explicit
  omit-with-rationale: "Progress-on-stdout wart from the Python source → Omit (do not
  preserve)... JSON tests then assert stdout purity with no regex-stripping".
- **The suppression predicate is a standard and must agree**: render only when stderr is a
  TTY **and** `CI` is absent-or-empty. Verbatim at the pin,
  `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/commands/projects.ts` lines 127-129:
  `const ci = deps.env['CI'];` /
  `const spinnerEnabled = deps.stderrIsTTY && (ci === undefined || ci === '');` /
  `const spinner = spinnerEnabled ? deps.spinner('Fetching projects...') : undefined;`.
  Note the exact semantics: **presence of a non-empty `CI`, any value, suppresses.**

**What may vary.** The rendering crate, the frame set, the tick interval, and the
mechanism by which "disabled" is expressed are all ecosystem-local. Nothing in the
principle requires Rust to reproduce `yocto-spinner`'s API or its frames.

**One thing that must *not* be carried across, and why.** The shipped TypeScript
implementation adds a 0-column guard (D-033, `TS_PORT_DECISIONS.md` line 398:
"guards the spinner against 0-column TTYs") whose reason is stated in the adapter
itself (`git show cb1cbcb2:src/lib/adapters.ts`, lines 55-64): "yocto-spinner's
line-clear loop divides the rendered length by the stream width, so a TTY reporting 0
columns... makes `Math.ceil(len/0) = Infinity` and floods stderr with clear sequences."
That is a **defect workaround in one JavaScript library**, not a principle. Porting the
guard into Rust would be cargo-culting: `console` — `indicatif`'s terminal layer —
already refuses a zero width at the source. `terminal_size` returns `None` unless both
dimensions are positive (`if winsize.ws_row > 0 && winsize.ws_col > 0`,
`https://raw.githubusercontent.com/console-rs/console/0.16.6/src/unix_term.rs` line 66)
and `Term::size` then falls back to `self.size_checked().unwrap_or((24, DEFAULT_WIDTH))`
(`.../console/0.16.6/src/term.rs` line 417) with
`pub(crate) const DEFAULT_WIDTH: u16 = 80;` (`unix_term.rs` line 18). A 0-column TTY
therefore yields an 80-column assumption in Rust, never a division by zero. (Source
read at tag 0.16.6, retrieved 2026-09-10; **not** an executed test — see
`### Validation strategy`.)

**Python's position, stated for the follow-on project.** At the pin
`b08bccfb`, `git -C ~/c/py-launch-blueprint grep -il "spinner\|tqdm\|progressbar\|rich.progress\|Progress("` over
`*.py` and `*.toml` returns **no matches**, and `git show b08bccfb:pyproject.toml`
lists `rich>=13.0.0` for output rendering only. So py *has the capability available*
(`rich.Progress`, `Console.status`) and does not use it. This is a **missing
capability, not a justified ecosystem difference** — Python's `sys.stderr.isatty()`
and `os.environ.get("CI")` make the identical gate trivial. The rationale this answer
supplies to the follow-on project is: py should adopt `rich.Console(stderr=True).status()`
under the same two-clause gate, which brings all three repositories to the same
standard without changing any repository's library stack. I am not changing py here and
I am not challenging F283's `DIVERGENT` verdict, which correctly records today's state.

**Architectural alternatives, compared before any library is picked.**

- **A — No indicator at all.** Cost: zero dependencies, zero code. Rejected: it
  abandons the standard rather than realizing it, and reproduces py's gap in a third
  repository.
- **B — Hand-rolled spinner: a thread, a `&[&str]` frame array, `eprint!("\r{}", f)`,
  `stderr().flush()`.** Roughly 40 lines and no dependency. Rejected on three
  concrete grounds, each of which is a real defect this template would then own:
  (i) it must re-implement cursor hide/show and line clearing, and must restore the
  cursor on panic and on SIGINT or leave the user's terminal with an invisible cursor;
  (ii) it has no width knowledge, so a message longer than the terminal wraps and the
  `\r` clears only the last visual line, leaving debris; (iii) a template's job is to
  *demonstrate* idiomatic composition, and hand-rolling the one thing 5,301 crates
  delegate teaches the wrong lesson. The saving is one small dependency subtree
  (five crates, below), which is not worth those three defects.
- **C — Spinner crate, gating owned by the call site.** The crate renders; the
  application decides whether it renders at all, and expresses "no" as a first-class
  value the crate understands. This is the pattern `uv` uses and it is what I recommend.
- **D — Spinner crate, gating delegated to the crate's own TTY detection.** Rejected,
  and this is the load-bearing rejection for this item. `indicatif` performs its own
  TTY test: `ProgressDrawTarget::term` runs `if !term.is_term() || is_dumb() { return
  Self::hidden(); }` (`.../indicatif/0.18.6/src/draw_target.rs` line 80). If the
  template leaned on that, it would (a) hold a **second, divergent TTY check** beside
  whatever R65 lands for F290 — precisely what this item's `## Out of scope` forbids —
  and (b) still not cover `CI`, because `indicatif` never reads `CI` anywhere. Design C
  makes `indicatif`'s internal check *inert*: when the call site says no, the target is
  already `hidden()` and `term.is_term()` is never consulted; when the call site says
  yes, R65's check has already returned true, so `indicatif`'s agreement is redundant
  rather than authoritative. The two checks cannot disagree observably.

**The maintained reference implementation for design C.** `astral-sh/uv`,
`crates/uv/src/printer.rs` (retrieved 2026-09-10,
`https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv/src/printer.rs`):

    /// Return the [`ProgressDrawTarget`] for this printer.
    pub(crate) fn target(self) -> ProgressDrawTarget {
        if self.suppresses_progress() {
            ProgressDrawTarget::hidden()
        } else {
            ProgressDrawTarget::stderr()
        }
    }

`Printer::new(quiet, verbose, no_progress)` (same file, lines 20-31) folds every
suppression reason into one enum, and `suppresses_progress` (lines 34-43) maps it to a
boolean. This is the whole answer to the LOW question about `--quiet`: the gating lives
at the call site, one predicate, one place, and adding a new reason to suppress is a new
enum arm rather than a new conditional at the fetch. `uv` composes `--quiet`, `--verbose`
and `--no-progress` this way today; `rs-launch-blueprint` adds `stderr-is-a-tty` and
`CI-is-absent` as two more clauses of the same predicate.

**Maturity, dependability, performance and integration cost.** Maturity and
dependability are covered by the figures in `### Qualified shortlist` and the
responsiveness measurement there. On performance: the relevant workload is *one
blocking HTTPS fetch of a project list, wall-clock dominated by the network*, and the
spinner's own cost is a background thread waking at the configured tick interval — with
`ProgressBar::enable_steady_tick(Duration::from_millis(100))` that is 10 wakeups per
second, each writing well under 100 bytes to a buffered stderr. Against a fetch whose
latency is tens to hundreds of milliseconds, that cost is not measurable in the
end-to-end time, and I deliberately do **not** quote a benchmark number: no crate exists
yet to instrument, and there is no unlike-benchmark comparison that would honestly
separate these candidates on throughput. Integration cost is roughly ten lines at the
call site plus one `Cargo.toml` line — see `### Migration implications`.

**Observable acceptance criteria** (these are the criteria; the commands that check
them are in `### Validation strategy`, and every one of them is *planned*, not run):

1. With stdout redirected to a file and stderr to a terminal, stdout contains only the
   command's data payload — for `--format json`, `jq .` parses it with no stripping.
2. With `CI` set to any non-empty value and stderr a TTY, stderr carries no spinner
   frames and no ANSI cursor-control sequences.
3. With stderr not a TTY (piped), stderr carries no spinner frames.
4. With stderr a TTY and `CI` unset, stderr carries spinner frames, and after the
   command finishes no partial spinner line and no hidden cursor remain.
5. The predicate that decides 2-4 is a single function, and the TTY half of it is the
   one function R65 selects for F290 — grep finds exactly one TTY test in the crate.

No `BASELINE-REVIEW:` finding. F283's verdict, its agreement level and its stated gate
all survive scrutiny; the only thing I decline to inherit is the D-033 0-column guard,
which is an implementation workaround rather than part of the baseline.

### Dominant choice

**`indicatif`** — `console-rs/indicatif`, current release **0.18.6**, published
**2026-07-01T13:45:24Z** (`GET https://crates.io/api/v1/crates/indicatif/versions`,
newest with `yanked: false`, retrieved 2026-09-10).

It is dominant by a wide margin on every axis measured, and — decisively for this item —
it is dominant *on the two behaviors the prompt asks about*, not merely on downloads.

- **90-day downloads 47,129,967**; **all-time downloads 214,311,835**
  (`GET https://crates.io/api/v1/crates/indicatif`, `crate.recent_downloads` /
  `crate.downloads`, retrieved 2026-09-10).
- **5,212 stars**, `archived: false`, `pushed_at 2026-09-07T15:20:41Z`
  (`GET https://api.github.com/repos/console-rs/indicatif`, retrieved 2026-09-10).
- **80 open issues** (`GET https://api.github.com/search/issues?q=repo:console-rs/indicatif+is:issue+is:open`,
  `total_count`, retrieved 2026-09-10 — note this is the mandated figure and differs
  from the repo object's `open_issues_count` of 97, which counts pull requests too).
- **Stderr is the documented default, verified in source.** `ProgressBar::new_spinner()`
  is `Self::with_draw_target(None, ProgressDrawTarget::stderr())`
  (`.../indicatif/0.18.6/src/progress_bar.rs` lines 150-154, retrieved 2026-09-10), and
  the constructor's own doc comment reads "This spinner by default draws directly to
  stderr." `ProgressDrawTarget::stderr()`'s doc adds "This is the default draw target
  for progress bars" (`src/draw_target.rs` lines 41-47). **No configuration is required
  to keep stdout clean** — this directly answers the second HIGH question in the
  affirmative, from the maintainer's source at the released tag.
- **It exposes `ProgressDrawTarget::hidden()`** (`src/draw_target.rs` line 126) as a
  first-class "render nothing" value, which is what makes design C expressible without a
  wrapper type of our own.

**On the first HIGH question — does the progress-bar and multi-progress surface make it
a worse match than a spinner-only crate?** No, and the premise deserves correcting.
`indicatif`'s bar and `MultiProgress` surfaces are *additional types*, not additional
dependencies and not additional runtime cost: the dependency set is fixed by
`Cargo.toml`, not by which types you name, and unused generic-free types are dropped by
the linker. Its real footprint on `ubuntu-latest`/`macos-latest` with default features
is **five crates** — `console` (itself pulled with `default-features = false, features =
["ansi-parsing", "std"]`), `unit-prefix`, `portable-atomic`, `unicode-width`, and
`console`'s `libc` (`https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/Cargo.toml`
and `.../console/0.16.6/Cargo.toml`, retrieved 2026-09-10). `spinners`, the leading
spinner-only alternative, pulls `lazy_static`, `maplit` and `strum 0.24` with its derive
macro — and a proc-macro derive costs more compile time than the whole of `console`.
The "lighter, spinner-only crate" is not actually lighter. `yocto-spinner`'s minimal
footprint was the right call in npm, where the alternative `ora` dragged in a second
colour library (`TS_PORT_DECISIONS.md` line 174); the same reasoning applied honestly in
Rust points at `indicatif`, because there is no double-stack to avoid — `console` is the
terminal layer, and the template will already need terminal knowledge for R65.

### Qualified shortlist

Every candidate here passed all six gates (per-candidate gate answers precede the
figures below; popularity was not consulted to reach them). **Only two crates qualified,
and that is a finding**: three of the five surveyed spinner crates fail a gate outright,
which is unusually thin for a category this well-trafficked and is itself an argument
against treating the spinner-only bin as a real alternative.

**Gate answers — `indicatif` 0.18.6**
1. *License*: `MIT` (`crates.io/api/v1/crates/indicatif/versions`, `license`, and
   `Cargo.toml` line 10). **Pass** — MIT is a subset of the permissions `MIT OR
   Apache-2.0` grants, so an MIT dependency imposes no obligation the template's own
   dual licence does not already accept. Whole tree: `console` MIT, `unit-prefix` MIT,
   `portable-atomic` `Apache-2.0 OR MIT`, `unicode-width` `MIT OR Apache-2.0`, `libc`
   `MIT OR Apache-2.0`. No copyleft anywhere.
2. *MSRV*: crate declares `rust-version = "1.85"` (`Cargo.toml` line 5, and
   `rust_version` on versions 0.18.5/0.18.6 from the crates.io versions endpoint).
   Tree maxima: `console` 1.71, `unicode-width` 1.66, `portable-atomic` 1.34,
   `unit-prefix` 1.31.0. Tree maximum is **1.85**, comfortably under the **1.96** floor,
   and 1.85 is also the edition-2024 floor, so it costs the template nothing. **Pass.**
   Note the crate *raised* MSRV from 1.71 to 1.85 between 0.18.4 and 0.18.5 — worth
   watching, but the raise was to the edition-2024 floor the template already sits on.
3. *Advisories / unsafe*: `https://rustsec.org/packages/indicatif.html` returns **HTTP
   404** — no advisory page, i.e. no advisories. (Control: `time`, `openssl` and `atty`
   return HTTP 200 with 4, 20 and 4 `RUSTSEC-` mentions respectively, so 404 genuinely
   means clean rather than an endpoint failure. All retrieved 2026-09-10.) Same 404 for
   `console`, `libc`, `unit-prefix`-tree neighbours checked. *Unsafe posture*: zero
   `unsafe` in `indicatif`'s own `src` — `GET
   https://api.github.com/search/code?q=unsafe+repo:console-rs/indicatif+path:src`
   returns `total_count: 0`, corroborated by `grep -c unsafe` finding 0 in the two
   largest source files read at tag 0.18.6. `unsafe` in the tree is confined to `libc`'s
   FFI (`ioctl`/`termios`), which is unavoidable for any crate that asks the OS for a
   terminal size — including a hand-rolled one. **Pass.**
4. *OS coverage*: CI matrix is `os: [ubuntu-latest, macos-latest, windows-latest]`
   with `rust: [stable]` (`.../indicatif/0.18.6/.github/workflows/rust.yml` lines 16-18),
   plus cross-builds and a dedicated `toolchain: "1.85"` MSRV job (line 67). Both
   required OSes are tested; Windows is additionally covered though not required.
   **Pass.**
5. *Default features and async coupling*: `default = ["unicode-width", "wasmbind"]`.
   `tokio`, `futures-core` and `rayon` are all `optional = true` and off by default —
   **no async-runtime coupling** unless the template opts in, which matters because R05
   has not settled the sync/async execution model. `wasmbind` gates `web-time`, declared
   under `[target.'cfg(target_arch = "wasm32")'.dependencies]`, so it contributes
   nothing on `ubuntu-latest`/`macos-latest`. **Pass.**
6. *Binary size and compile time*: qualitatively small. Five crates, one of which
   (`unicode-width`) is table data, none with a proc-macro derive, no build script of
   consequence, no async runtime. This is at the low end of what a CLI dependency
   costs. **Pass** (stated qualitatively; no measured byte figure is quoted because no
   crate exists to build, and inventing one would violate the constraint).

**Gate answers — `cliclack` 0.5.6**
1. *License* `MIT` — **pass**. 2. *MSRV* — **no `rust-version` declared** on any
version (`crates.io/api/v1/crates/cliclack/versions`, `rust_version: None`), so its MSRV
is undeclared and untested; but its dependency floor is bounded by `indicatif` 1.85,
which it re-exports, so the effective floor is under 1.96 — **pass with a finding**
(undeclared MSRV means a patch release could silently raise it). 3. RustSec **404**,
no advisories; unsafe posture inherited from `console`/`libc` — **pass**. 4. Both
required OSes: it is a prompts library used cross-platform, and its dependency
`indicatif` is CI-tested on both — **pass**. 5. `default` features pull `console`,
`indicatif`, `once_cell`, `strsim`, `textwrap`, `zeroize` (+ `derive`); no async
runtime — **pass**. 6. Materially heavier than `indicatif` alone: six direct
dependencies including `zeroize`'s derive proc-macro — **pass, with the cost noted**.

| Name | Role | 90-day downloads | All-time downloads | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `indicatif` | General progress/spinner rendering on a `ProgressDrawTarget` | 47,129,967 | 214,311,835 | 5,212 | 0.18.6, 2026-07-01 | **active** | `rust-lang/rustup`, `astral-sh/uv`, `uutils/coreutils`, `nextest-rs/nextest`, `cargo-generate`, `huggingface/tokenizers`, `rerun-io/rerun`, `flamegraph-rs/flamegraph` | Carries bar/multi-progress types the template will not use; costs nothing at runtime, mild conceptual surface |
| `cliclack` | Opinionated prompt suite (Clack port) that *includes* a spinner, built on `indicatif` | 1,028,866 | 3,340,001 | 366 | 0.5.6, 2026-08-10 | **active** | Wraps `indicatif`, appears in its reverse-dependency list | Bundles the whole prompt/UX stack, so it silently pre-empts R61 (`interactive-prompts`) instead of deciding only this item |

*Maintenance rubric applied.* `indicatif` = **active**: released 2026-07-01 (2.3 months
before retrieval, inside the 6-month trigger window), `pushed_at 2026-09-07`, not
archived, and — the concrete signal — measured issue responsiveness below.
`cliclack` = **active**: released 2026-08-10, `pushed_at 2026-08-10`, not archived.

*Issue responsiveness — `indicatif`.* The 10 most recently opened issues
(`GET https://api.github.com/search/issues?q=repo:console-rs/indicatif+is:issue&sort=created&order=desc&per_page=10`,
then `GET /repos/console-rs/indicatif/issues/<n>/comments` for each, retrieved
2026-09-10), counting the first comment whose `author_association` is
`OWNER`/`MEMBER`/`COLLABORATOR`:

| Issue | Days to first maintainer response |
|---|---|
| #810 | 0.77 |
| #807 | 0.06 |
| #802 | 0.05 |
| #797 | 0.00 |
| #793 | 0.21 |
| #789 | 0.98 |
| #778 | 0.44 |
| #777 | 0.03 |
| #814 | unanswered (0 comments, closed) |
| #798 | unanswered (0 comments, closed) |

**Median days to first maintainer response: 0.13** (about 3 hours), across the 8
answered. **Unanswered: 2** — both were closed with zero comments, i.e. resolved or
dismissed by maintainer action rather than ignored. Every response came from the same
`MEMBER`, `djc`, which is the one dependability caveat worth naming: responsiveness is
excellent but concentrated in a single maintainer.

### Excluded by gate

- **`spinners` 4.2.0 — excluded on gate 2, with two further defects.**
  *Gate 2 (MSRV)*: no `rust-version` declared on **any** published version
  (`GET https://crates.io/api/v1/crates/spinners/versions`, `rust_version: None` for
  4.2.0, 4.1.1 and 4.1.0, retrieved 2026-09-10). The policy requires an MSRV "declared
  as `rust-version` in `Cargo.toml` and tested in CI"; a dependency that declares none
  can raise its floor in a patch release with no semver signal, which is exactly the
  failure the policy exists to prevent. **Fail.**
  Two further findings recorded because they would have decided it anyway: (i) its
  dependency set is `lazy_static 1.4`, `maplit 1.0.2` and `strum 0.24` with `derive`
  (`https://raw.githubusercontent.com/FGRibreau/spinners/master/Cargo.toml`, retrieved
  2026-09-10) — `strum 0.24` is several major versions behind current, and both
  `lazy_static` and `maplit` are legacy crates superseded by `std::sync::OnceLock`;
  (ii) its render loop is `stream.write(&frame, &message, start_time, stop_time)
  .expect("IO Error")` (`.../spinners/master/src/lib.rs` line 119), so an `EPIPE` on
  stderr **panics the process**. A template must not ship a background thread that
  aborts the program when stderr closes.
  For the record, it does get the two HIGH questions right — `Stream` derives `Default`
  with `#[default] Stderr` (`src/utils/stream.rs` lines 14-17) and it uses
  `std::io::IsTerminal` (line 95). Figures: 658,553/90d; 7,123,963 all-time; 602 stars;
  4.2.0 released 2026-03-04; `pushed_at 2026-05-02`; 5 open issues; RustSec 404.
- **`spinoff` 0.8.0 — excluded on gates 2 and (effectively) the item's stderr
  requirement; maintenance `at-risk`.**
  *Gate 2*: no `rust-version` on any version. **Fail.**
  *Stderr*: its own documentation says "This function outputs to the `stdout` stream. If
  you want to use a different stream, use the [`Spinner::new_with_stream`] function"
  (`https://raw.githubusercontent.com/ad4mx/spinoff/main/src/lib.rs` line 137, retrieved
  2026-09-10). **Defaulting to stdout is the exact failure mode the ts port was written
  to repair**, and a template that must keep JSON on stdout pure cannot adopt a crate
  whose happy path pollutes it.
  *Maintenance*: last release 0.8.0 on **2023-08-04** — over two years before retrieval —
  with `pushed_at 2025-01-16T13:44:39Z` and 2 open issues. Concrete signal for
  **at-risk**: a two-year release gap combined with an eight-month-old last push, on a
  crate whose transitive `console`-free rendering has had no compatibility maintenance
  across four Rust editions of churn. Not `dormant`: no unpatched advisory (RustSec
  404), no maintainer notice found, and no evidence of a broken build. Figures:
  100,724/90d; 737,459 all-time; 576 stars.
- **`spinach` 3.2.0 — excluded on gate 2, with a licence-history caution.**
  *Gate 2*: no `rust-version` declared. **Fail.**
  *Gate 1 note*: currently `MIT`, but version **3.0.0 was published as
  `GPL-3.0-or-later`** and only 3.1.0/3.2.0 are MIT
  (`GET https://crates.io/api/v1/crates/spinach/versions`, retrieved 2026-09-10). A
  dependency whose licence has flipped between copyleft and permissive inside one major
  version is a standing risk for a `MIT OR Apache-2.0` template. Figures: 1,539/90d
  (three orders of magnitude below `indicatif`); 46,010 all-time; 120 stars; 3.2.0
  released 2025-12-05; `pushed_at 2025-12-05`; 0 open issues. Maintenance
  **stable-quiet** — recent release, no signal of abandonment, simply very small.
- **`throbber-widgets-tui` 0.11.1 — excluded as category-wrong before gates.**
  It is "a ratatui widget that displays throbber"
  (`GET https://crates.io/api/v1/crates/throbber-widgets-tui`, `crate.description`,
  retrieved 2026-09-10). Using it requires a `ratatui` full-screen application with an
  alternate screen and a frame loop; this template runs one command and exits. Gates
  are not evaluated because no gate outcome could make it fit. Figures recorded for
  completeness: 204,074/90d; 886,095 all-time; 0.11.1 released 2026-06-19.
- **Hand-rolled spinner (no crate) — not gate-excluded; rejected on design grounds.**
  Gates 1, 3, 4, 5 are `inapplicable` (no third-party crate, no licence, no advisory
  surface, no upstream CI, no features); gate 2 is trivially satisfied; gate 6 is the
  only real win. Rejected under alternative **B** in `### Principles and implementation`.
- **`is_ci` 1.2.0 — considered for the `CI` half of the gate and rejected on semantics,
  not on a gate.** It is permissively licensed (ISC), advisory-free (RustSec 404) and
  widely pulled (11,828,364/90d, 53,229,641 all-time), but its predicate is
  `ci_var == Ok("true".into()) || ci_var == Ok("1".into()) || ci_var ==
  Ok("woodpecker".into()) || check("CI_NAME") || check("GITHUB_ACTION") || ...`
  (`https://raw.githubusercontent.com/zkat/is_ci/main/src/lib.rs` lines 26-40, retrieved
  2026-09-10). **It requires `CI` to equal a specific value**, whereas the ts baseline
  suppresses on *any non-empty* `CI`. Substituting it would silently change the recorded
  contract: `CI=yes` suppresses under the baseline and does **not** suppress under
  `is_ci`. It also has 15 stars, 1 open issue, and a last release of **2024-02-04** with
  `pushed_at 2024-02-04` (maintenance **stable-quiet** — small, finished-feeling, no
  distress signal). Rejected in favour of `std`.
- **`ci_info` 0.14.15 — same rejection, heavier.** Apache-2.0 (compatible), RustSec 404,
  760,129/90d, 6,343,793 all-time, 18 stars, released 2025-11-01, `pushed_at
  2026-02-23`, 0 open issues, **stable-quiet**. It detects *which* CI provider is
  running, which this item does not need, at the cost of a dependency whose predicate
  again differs from the baseline's.

### Up-and-comers

- **`cliclack`** (366 stars; 1,028,866/90d against 3,340,001 all-time — roughly 31% of
  its lifetime downloads in the last quarter, the steepest growth curve of anything
  surveyed; 0.5.6 released 2026-08-10). It is the genuine riser in this bin, and it is a
  Rust port of the same Clack/`@clack/prompts` lineage the TypeScript side already draws
  from, so it would be a defensible aesthetic match. Its spinner is `indicatif`
  underneath (`indicatif = "0.18"` in its `Cargo.toml`, retrieved 2026-09-10), so
  choosing it is choosing `indicatif` plus an opinionated prompt layer. **Watch it for
  R61 (`interactive-prompts`), not for R63**: adopting it here would decide R61 by side
  effect, which this item has no mandate to do. If R61 independently lands on
  `cliclack`, R63 should be revisited to drop the direct `indicatif` dependency in
  favour of `cliclack`'s re-export — that is the re-verify trigger below.
- **`spinoff`** was the previous up-and-comer in this bin and has stalled (last release
  2023-08-04). Recorded so the next reader does not re-discover it as fresh.
- Nothing new appeared in the reverse-dependency survey that is displacing `indicatif`;
  the field's shape is one incumbent plus one riser that is built on the incumbent.

### Fit for this template

**CLI.** Direct fit, and this is where the whole decision lives. The command wraps one
network fetch; `ProgressBar::new_spinner()` already targets stderr, and the call site
supplies `ProgressDrawTarget::hidden()` when the gate says no. One detail the template
must get right: a spinner attached to a *blocking* call will not animate unless a
background ticker is running, so `enable_steady_tick` is required — "a background
thread will regularly tick the progress bar in the given interval. This is useful to
advance progress bars that are very slow by themselves"
(`.../indicatif/0.18.6/src/progress_bar.rs` lines 173-180). Without it the spinner
renders one frame and freezes for the duration of the fetch, which is worse than no
spinner. `ProgressBar::is_hidden()` (line 252) lets tests assert the gate's outcome
without capturing a terminal.

**Library.** The library crate must depend on **none of this**. Progress rendering is a
presentation concern and belongs in the CLI crate only; a library that writes to stderr
on its caller's behalf is a defect, and R01's ports-and-adapters seam is the right place
for the boundary. The concrete shape: the library's fetch function is oblivious, and the
CLI wraps the call. If a caller ever needs progress from the library, the seam should
carry a small caller-supplied callback (`impl Fn(&str)`) rather than an `indicatif`
type, so `indicatif` never appears in the library's public API and never becomes a
semver obligation. **`indicatif` must not be in the library crate's `[dependencies]`.**

**Web service.** `inapplicable`, and worth stating rather than omitting. A spinner is a
terminal artifact; an HTTP handler has no controlling terminal, and long-running work
there is reported through the response, through structured logs (R58), or through
metrics (R79) — never through stderr escape sequences, which would corrupt a JSON log
stream. The web crate must not depend on `indicatif`. The one place the boundary could
leak is a shared "output" module used by both CLI and web; keeping the spinner in the
CLI crate prevents that by construction.

### Recommendation

**Adopt `indicatif` at `0.18` (Cargo requirement `indicatif = "0.18"`, resolving to
0.18.6 or later within 0.18.x), in the CLI crate only, with all gating owned by the call
site.**

Concretely:

- `Cargo.toml` of the **CLI crate only**: `indicatif = "0.18"` with default features.
  Do not enable `tokio`, `futures` or `rayon`; R05 has not settled the execution model
  and none of them is needed for a single blocking fetch.
- A single predicate function decides rendering. Its two clauses are (a) **stderr is a
  TTY**, evaluated by whatever check **R65** lands for F290 — this item does not choose
  it and must not introduce a second one; and (b) **`CI` is absent or empty**, evaluated
  with `std::env::var_os("CI").is_none_or(|v| v.is_empty())` (or the equivalent
  `matches!` form), which reproduces the ts semantics
  `ci === undefined || ci === ''` exactly, with no dependency.
- The predicate's result is expressed as a `ProgressDrawTarget`: `hidden()` when false,
  `stderr()` when true, following `uv`'s `Printer::target()`. Because the disabled path
  yields `hidden()`, `indicatif`'s internal `!term.is_term() || is_dumb()` check is
  never the deciding authority, so there is exactly one TTY check in the crate and
  R65's decision is not shadowed.
- `enable_steady_tick(Duration::from_millis(100))` before the fetch;
  `finish_and_clear()` in the equivalent of the ts `finally` block, so the line is
  removed on both the success and the error path (the ts code uses `spinner?.stop()`
  inside `finally`, `src/commands/projects.ts` lines 131-135 at pin `cb1cbcb2`).
- **Do not port the D-033 0-column guard.** `console` returns `None` for a zero
  `ws_col` and `Term::size` falls back to 80 columns, so the yocto-spinner division
  hazard does not exist here. Record this as a deliberate non-port with the source
  citation, so a future reader does not re-add it as "parity".
- Add `indicatif` a second time under the CLI crate's `[dev-dependencies]` with
  `features = ["in_memory"]`. That unlocks `InMemoryTerm`
  (`.../indicatif/0.18.6/src/in_memory.rs` line 14, with `pub fn contents(&self) ->
  String` at line 32 and `impl TermLike for InMemoryTerm` at line 105), which lets the
  acceptance test assert rendered spinner output **without a pty**, on both
  `ubuntu-latest` and `macos-latest`. This is a real advantage no spinner-only candidate
  offers and is the reason gate-6's small extra weight is worth paying.

**Answers to the prompt's questions, collected.** HIGH-1: `indicatif`, not a
spinner-only crate — the lighter alternatives are not actually lighter (proc-macro
derives, legacy deps) and three of them fail a gate. HIGH-2: it defaults to stderr, no
configuration needed, verified in source at tag 0.18.6. HIGH-3: answered in
`### Principles and implementation`. MEDIUM-1: `std::env::var_os("CI")` directly — the
crate conventions (`is_ci`, `ci_info`) exist but encode *different* semantics than the
recorded baseline. MEDIUM-2: yes, it degrades gracefully at 0 columns via `console`'s
80-column fallback; no wrapping needed. LOW: gating lives at the call site as a
`ProgressDrawTarget`, which composes cleanly with `--quiet`/`--no-input` — `uv`
demonstrates exactly this.

### Ranked runner-up

**`cliclack` 0.5.6.** It wins **only if R61 (`interactive-prompts`) independently
selects `cliclack` as the prompt library.** In that world the template already has
`cliclack` in its CLI dependency graph, its spinner is `indicatif` underneath, and
adding a *separate* direct `indicatif` dependency would mean two crates rendering to
stderr with two notions of the active line — a real interleaving hazard when the ts flow
shows a spinner and then a checkbox prompt on the same stream (`src/commands/projects.ts`
lines 129 and 145 at pin `cb1cbcb2`). Under that condition, take the spinner from
`cliclack` and drop the direct `indicatif` line.

It does **not** win otherwise. Adopting it for R63 alone would decide R61 by side effect,
add five dependencies the spinner does not need, and accept an undeclared MSRV — for a
spinner that is `indicatif`'s anyway.

Second runner-up, for completeness: the **hand-rolled spinner**, which wins only if a
zero-third-party-dependency constraint is later imposed on the CLI crate. No such
constraint exists in `PARAMETERS.md`.

### Tradeoffs

**Versus `cliclack`.** The pick gives up visual coherence with whatever R61 chooses and
accepts the risk of a later consolidation. Accepted because R63 must not pre-empt R61's
decision, and because the consolidation is cheap when it comes: both render through the
same `indicatif` primitives, so it is a dependency-line change plus a call-site rename,
not a re-architecture. The re-verify trigger below makes the check explicit rather than
leaving it to memory.

**Versus a spinner-only crate (`spinners`).** The pick gives up a notionally smaller
conceptual surface — `indicatif` exposes `ProgressBar`, `MultiProgress` and
`ProgressStyle` where the template uses one constructor. Accepted, because the surface
costs nothing at runtime or link time, and the concrete alternative costs more: a
`strum` proc-macro derive at compile time, two legacy dependencies, an undeclared MSRV,
and a render loop that panics on `EPIPE`. The trade is "slightly more API to ignore" for
"no gate failures and no panic path" — an easy trade.

**Versus `spinoff`.** The pick gives up nothing real; `spinoff` defaults to stdout and
has not shipped since 2023-08-04. Recorded only so the exclusion is legible.

**Versus a hand-rolled spinner.** The pick gives up the ability to claim zero
dependencies for this feature and accepts five crates. Accepted because those five carry
cursor management, panic-safe teardown, width awareness and — via the `in_memory`
feature — a test harness the template would otherwise have to build. A template's
dependency choices are pedagogy: 5,301 crates delegate this, and the template should
show why.

**Versus `is_ci`/`ci_info` for the CI half.** The pick gives up broader CI detection
(GitLab, Travis, CodeBuild and the rest that `is_ci` sniffs) in exchange for exactly
reproducing the recorded ts contract with zero dependencies. Accepted because F283's
gate is defined as the `CI` variable specifically, and because every CI system named in
`is_ci` sets `CI` anyway — GitHub Actions sets `CI=true`. If the owner later wants
provider sniffing, that is a new decision on F283, not a silent substitution here.

### Parameters

- `owns` — none. R63 registers no parameter (`## Couplings`: `owns:` is empty).
- `assumes rust-edition = 2024` (fixed, owner-decided 2026-09-02). `indicatif` 0.18.6 is
  itself `edition = "2021"`, which is irrelevant to the consumer: editions are per-crate,
  and a 2021-edition dependency links into a 2024-edition crate without friction. Its
  `rust-version = "1.85"` is exactly the edition-2024 floor, so the assumption costs
  nothing.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release,
  declared as rust-version in Cargo.toml and tested in CI` (fixed). Floor computed as
  **1.96** against stable 1.98.1; the recommended tree's maximum MSRV is **1.85**.
- `assumes license = MIT OR Apache-2.0` (fixed). Recommended tree is MIT / `MIT OR
  Apache-2.0` / `Apache-2.0 OR MIT` throughout; no copyleft.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). `indicatif` tests
  both, plus `windows-latest`.
- `assumes` (informal, not a registry dependency) — R65's F290 TTY-detection mechanism.
  The recommendation is written so that whatever R65 selects is called *once* and its
  result is converted into a `ProgressDrawTarget`; R63 introduces no TTY check of its own.

No `CONFLICT:` lines. Nothing in this recommendation requires a consumed parameter to change.

### Migration implications

There is no Rust code yet, so these are the file-level changes P03 will make when it
builds the template.

| File | Change |
|---|---|
| `crates/cli/Cargo.toml` (or the CLI member's manifest under whatever layout R02 lands) | Add `indicatif = "0.18"` under `[dependencies]`. Add `indicatif = { version = "0.18", features = ["in_memory"] }` under `[dev-dependencies]`. **No `indicatif` line in the library crate's or the web crate's manifest.** |
| `Cargo.lock` | Six new entries: `indicatif`, `console`, `unit-prefix`, `portable-atomic`, `unicode-width`, plus `vt100` in the dev graph. `libc` is almost certainly already present. |
| CLI progress module — new, e.g. `crates/cli/src/progress.rs` | Holds the single gate predicate and the `ProgressDrawTarget` factory, shaped after `uv`'s `Printer`: one enum or struct folding *all* suppression reasons (not-a-TTY, `CI` set, `--quiet`, and later `--no-progress`) into one `fn target(&self) -> ProgressDrawTarget`. This is the file that must contain the *only* consumer of R65's TTY check for progress purposes. |
| CLI command module wrapping the fetch (the `projects.ts:127-135` analogue) | Build the spinner from the factory, `enable_steady_tick(Duration::from_millis(100))`, run the fetch, `finish_and_clear()` on **both** the ok and err paths. In Rust the `finally` shape is either an explicit call on both arms of the `Result` match or a small guard type whose `Drop` clears — prefer the guard so a `?` early-return cannot leak a live spinner. |
| CLI arg definitions (R60's surface) | `--quiet` (and, if the owner wants parity with `uv`, `--no-progress`) feed the same predicate; they are new suppression reasons, not new conditionals at the fetch. |
| `crates/cli/tests/` | New integration tests for the four observable criteria; the `InMemoryTerm` test needs the `in_memory` dev-feature above. |
| Template documentation (README / docs, R81's surface) | One short subsection recording the two-clause gate, the stderr-only rule, and — explicitly — that the ts D-033 0-column guard is *not* ported and why, with the `console` source citation. Without this note a future reader will re-add it as parity. |
| `docs/port/COMMONALITY.md` row F283 | At resolution, records `indicatif` as the Rust realization. Not edited by this report. |

### Validation strategy

**Every check below is *planned*. None has been executed: no Rust crate exists in this
repository yet, and this item is research, not implementation.** The commands are
written against the template P03 will build so that they can be run unchanged then.

1. **Stdout purity under a piped stdout (criterion 1).**
   `cargo run -p rs-launch-blueprint-cli -- projects --format json 2>/dev/null | jq -e 'type == "array"'`
   *Expected*: exit 0, `jq` parses with no stripping. This is the check D-016(5) line 205
   describes as the point of the whole rule — "JSON tests then assert stdout purity with
   no regex-stripping".
2. **CI suppression with a real TTY on stderr (criterion 2).**
   `script -q /dev/null env CI=true cargo run -p rs-launch-blueprint-cli -- projects 2>&1 >/dev/null | cat -v`
   (on macOS; `script -qec '...' /dev/null` on Linux — the invocation differs between
   BSD and util-linux `script`, and the test harness must branch on the OS since the
   matrix is `ubuntu-latest, macos-latest`).
   *Expected*: no `^[` escape sequences and none of the spinner frame glyphs on stderr.
   Repeat with `CI=1`, `CI=yes` and `CI=""`; the first three must suppress and
   `CI=""` must **not** suppress — that quartet is what pins the ts semantics
   `ci === undefined || ci === ''` and is exactly where an `is_ci` substitution would
   diverge.
3. **Non-TTY stderr suppression (criterion 3).**
   `cargo run -p rs-launch-blueprint-cli -- projects 2>&1 >/dev/null | wc -c`
   with `CI` unset. *Expected*: only the command's own diagnostics, no frame bytes.
4. **Rendering when attended, and clean teardown (criterion 4).**
   A unit test in `crates/cli/src/progress.rs` (or `tests/`) building the bar against
   `ProgressDrawTarget::term_like(Box::new(InMemoryTerm::new(24, 80)))`, ticking it, then
   `finish_and_clear()`. *Expected*: `term.contents()` is non-empty mid-run and empty
   after teardown. This runs on both required OSes with no pty and no `script` branching,
   which is why the `in_memory` dev-feature is part of the recommendation.
5. **One TTY check, not two (criterion 5).**
   `rg -n 'is_terminal|IsTerminal|is_term\(' crates/ --type rust`
   *Expected*: exactly one hit outside `target/`, inside whatever module R65's decision
   places it in. A second hit is a regression against this item's `## Out of scope`.
6. **The library and web crates stay clean.**
   `cargo tree -p rs-launch-blueprint-core -i indicatif` and the same for the web crate.
   *Expected*: `cargo tree` reports that the package is not in the dependency graph
   (non-zero exit). This is the executable form of the boundary in
   `### Fit for this template`.
7. **Gate 2 held in CI.** The MSRV job the policy already requires
   (`cargo +1.96 check --all-targets`) covers `indicatif` transitively; no
   spinner-specific addition is needed, which is itself evidence the pick is
   policy-cheap.

Distinguishing what *was* run for this report: only read-only evidence collection —
`git show` against both pinned trees, `curl` against crates.io, `raw.githubusercontent.com`,
`static.rust-lang.org` and RustSec, and `gh api` against the GitHub REST API. No build,
no test, no crate scaffolded, and nothing written outside this file.

### Confidence & re-verify trigger

**Confidence: high** on the crate selection and on both HIGH questions, because the two
load-bearing behaviors were verified in the maintainer's own source at a released tag
rather than from documentation or memory: stderr-by-default at
`progress_bar.rs:150-154` and `draw_target.rs:41-47`, and the internal TTY auto-hide at
`draw_target.rs:80` that made design D unacceptable. The `uv` reference implementation
shows the recommended architecture running in production at scale.

**Confidence: high** on the MEDIUM 0-column answer, with one honest qualification: it
rests on reading `console`'s `unix_term.rs:66` and `term.rs:417` at tag 0.16.6, not on
an executed test against a 0-column pty. Check 4 above does not cover it; a future
implementer who wants certainty should add a `TermLike` fake reporting width 0.

**Confidence: medium** on the runner-up ordering, because it is contingent on R61, which
has not run.

Re-verify when any of these occurs:

1. **R61 (`interactive-prompts`) resolves.** If it selects `cliclack`, re-open R63 and
   drop the direct `indicatif` dependency in favour of `cliclack`'s. This is the single
   most likely trigger.
2. **R65 (`color-enablement-chain`) resolves F290.** Confirm the recommended predicate
   consumes R65's chosen TTY check and that check 5 above still finds exactly one hit.
3. **R05 (`sync-async-execution-model`) selects an async runtime.** Then re-evaluate
   whether to enable `indicatif`'s optional `tokio` feature for `wrap_stream`-style
   integration; today's recommendation deliberately leaves it off.
4. **`indicatif` publishes 0.19 or raises `rust-version` above the then-current floor.**
   It moved 1.71 → 1.85 between 0.18.4 and 0.18.5, so this is a live pattern, not a
   hypothetical. Re-check `rust_version` on the newest unyanked version against
   `stable minus 2`.
5. **Any RustSec advisory appears** for `indicatif`, `console`, or `libc`
   (re-run the four 404 checks; the `time`/`openssl`/`atty` control makes a false clean
   reading detectable).
6. **`console-rs` maintenance concentration changes.** All 8 measured maintainer
   responses came from one `MEMBER`; if that account goes quiet for a release cycle,
   re-run the responsiveness measurement before P03 relies on upstream fixes.

### Sources

Pinned source repositories, read through their pin (never the working tree):
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/commands/projects.ts` — lines 127-135, the gate and the `finally` teardown. Retrieved 2026-09-10.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/adapters.ts` — lines 28-70, `SpinnerFactory`, "The caller owns the TTY/CI gating", and the D-033 flood guard with its stated cause. Retrieved 2026-09-10.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:docs/port/TS_PORT_DECISIONS.md` — lines 165, 174, 205 (D-016(5)), 356, 398 (D-033). Retrieved 2026-09-10.
- `git -C ~/c/ts-launch-blueprint show cb1cbcb2:package.json` — `"yocto-spinner": "^1.2.2"`. Retrieved 2026-09-10.
- `git -C ~/c/py-launch-blueprint grep -il "spinner\|tqdm\|progressbar\|rich.progress\|Progress(" b08bccfb -- '*.py' '*.toml'` — **no matches**; and `git show b08bccfb:pyproject.toml` — `rich>=13.0.0` present, unused for progress. Retrieved 2026-09-10. Both claims are from commit `b08bccfb`, not HEAD.
- `docs/port/COMMONALITY.md:287` (F283) and `docs/port/areas/cli-framework-ux.md:27,56` — this repository, working tree, retrieved 2026-09-10.

crates.io (`GET https://crates.io/api/v1/crates/<name>` and `/versions`, User-Agent
`rs-launch-blueprint-research/R63`, all retrieved 2026-09-10): `indicatif`, `console`,
`spinners`, `spinoff`, `cliclack`, `spinach`, `throbber-widgets-tui`, `is_ci`,
`ci_info`, `supports-color`, `unit-prefix`, `portable-atomic`, `unicode-width`, `vt100`;
plus `GET https://crates.io/api/v1/crates/indicatif/reverse_dependencies?per_page=40`.

GitHub REST (`GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, all retrieved
2026-09-10): `console-rs/indicatif`, `console-rs/console`, `fgribreau/spinners`,
`ad4mx/spinoff`, `fadeevab/cliclack`, `etienne-napoleone/spinach`, `zkat/is_ci`,
`sagiegurari/ci_info`, `astral-sh/uv`, `rust-lang/rustup`, `uutils/coreutils`,
`huggingface/tokenizers`, `nextest-rs/nextest`, `cargo-generate/cargo-generate`,
`flamegraph-rs/flamegraph`, `rerun-io/rerun`. Responsiveness from
`GET .../search/issues?q=repo:console-rs/indicatif+is:issue&sort=created&order=desc&per_page=10`
then `GET /repos/console-rs/indicatif/issues/<n>/comments` for issues 814, 810, 807, 802,
798, 797, 793, 789, 778, 777. Unsafe posture from
`GET https://api.github.com/search/code?q=unsafe+repo:console-rs/indicatif+path:src`.

Source read at released tags (all retrieved 2026-09-10):
`https://raw.githubusercontent.com/console-rs/indicatif/0.18.6/` — `Cargo.toml`,
`src/draw_target.rs`, `src/progress_bar.rs`, `src/in_memory.rs`,
`.github/workflows/rust.yml`;
`https://raw.githubusercontent.com/console-rs/console/0.16.6/` — `Cargo.toml`,
`src/term.rs`, `src/unix_term.rs`;
`https://raw.githubusercontent.com/FGRibreau/spinners/master/` — `Cargo.toml`,
`src/lib.rs`, `src/utils/stream.rs`;
`https://raw.githubusercontent.com/ad4mx/spinoff/main/src/lib.rs`;
`https://raw.githubusercontent.com/fadeevab/cliclack/master/Cargo.toml`;
`https://raw.githubusercontent.com/zkat/is_ci/main/src/lib.rs`;
`https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml` and
`.../main/crates/uv/src/printer.rs`;
`https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml`;
`https://raw.githubusercontent.com/rust-lang/rust/master/RELEASES.md`;
`https://static.rust-lang.org/dist/channel-rust-stable.toml`.

RustSec (`https://rustsec.org/packages/<name>.html`, retrieved 2026-09-10): `indicatif`,
`console`, `spinners`, `spinoff`, `cliclack`, `spinach`, `is_ci`, `ci_info`,
`lazy_static`, `maplit`, `strum`, `libc`, `vt100` — all **HTTP 404**; `once_cell` —
HTTP 200. Control: `time`, `openssl`, `atty` — HTTP 200 with 4, 20 and 4 `RUSTSEC-`
mentions.

**Method notes.** I queried `https://crates.io/api/v1/crates/<name>` and `/versions`
(with a User-Agent header) for every download, release-date, licence and `rust_version`
figure; `https://api.github.com/repos/<o>/<r>` for stars, `archived` and `pushed_at`;
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the open-issue
counts (the mandated `total_count`, deliberately not `open_issues_count` — for
`indicatif` the two differ, 80 versus 97, because the repo object counts pull requests);
`https://api.github.com/repos/console-rs/indicatif/issues/<n>/comments` for the
responsiveness measurement; `https://api.github.com/search/code` for the `unsafe` count;
`https://rustsec.org/packages/<name>.html` for advisories;
`raw.githubusercontent.com` at pinned tags for every behavioral source claim;
`https://static.rust-lang.org/dist/channel-rust-stable.toml` for the current stable
version behind the MSRV arithmetic; and both pinned git trees through
`git show <pin>:<path>` as the role file requires.

Three limits on what I could verify, stated rather than papered over. **(1)** The initial
attempt at the responsiveness figure used
`GET /repos/console-rs/indicatif/issues?state=all&sort=created&direction=desc&per_page=20`,
which returned 20 items of which **all 20 were pull requests**; I switched to the
`search/issues` endpoint, which returns issues only, and the figures above come from
that. Worth recording because the naive endpoint would have produced a silently wrong
responsiveness number. **(2)** Every RustSec result for a candidate crate was HTTP 404.
Rather than assume 404 means clean, I ran a control against `time`, `openssl` and `atty`,
which returned HTTP 200 with advisory content — so the 404s are genuine "no advisory
page", not an endpoint outage. **(3)** No figure here is measured on built Rust code:
binary size and compile time are stated **qualitatively** (dependency count, absence of
proc-macro derives and of an async runtime) rather than as numbers, because no crate
exists in this repository to build and inventing a byte or second figure would breach
the prompt's constraint. Likewise the 0-column behavior is established by reading
`console`'s source, not by executing against a 0-column pty; that gap is named in
`### Confidence & re-verify trigger`. I did not scaffold a crate, run `cargo`, or write
any file other than this one, and I did not open, list or search for any other engine's
output.
