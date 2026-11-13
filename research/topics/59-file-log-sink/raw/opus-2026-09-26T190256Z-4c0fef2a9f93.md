# R59 — file log sink (bundle) — raw report

Actor: `research-opus-2026-09-26T190256Z-4c0fef2a9f93`. Model: `claude-opus-5-5`.
Item kind: `bundle`. Tier: focused. Run directory:
`research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93`. Retrieval date for every figure and
claim below: **2026-09-26**, unless a line states otherwise.

Toolchain facts this report is measured against, retrieved 2026-09-26: current Rust stable is
**1.98.1** (`version = "1.98.1 (48a229cea 2026-09-01)"`, `date = "2026-09-03"`,
`https://static.rust-lang.org/dist/channel-rust-stable.toml`). The owner-fixed `msrv-policy`
("stable minus 2 minor versions") therefore puts the template's declared floor at **1.96**.
Every executed check below ran on macOS 26.4, Apple M4 Pro (aarch64, `darwin 25.4.0`), with
rustc **1.98.1** (Homebrew) and rustc **1.96.0** (rustup). No check ran on Ubuntu; that gap is
restated under `### Validation strategy`.

**Independence and scope record.** This leg read the canonical prompt (identical to the run's
`inputs/prompt.md`; `diff` printed nothing), the run's `inputs/`, `research/RUNBOOK.md`, the
accepted R57 `DECISION.md`, the R58 *prompt* (not R58's raw reports, because R58 has no
decision), the py and ts source trees at their current checkouts, and the org CLI Design
Standard. It did not open any other engine's report for R59. The only repository write is this
file. Scratch work lives in `/tmp/r59-opus/` (outside the repository): downloaded `.crate`
sources, API responses, and the check crate `/tmp/r59-opus/check`.

**Network touched.** `crates.io/api/v1` (crate, versions, reverse-dependencies, and download
endpoints; downloads redirect to `static.crates.io`), `api.github.com` (repository, search,
issues, contents), `rustsec.org`, and `static.rust-lang.org` (the stable channel manifest,
which is not one of the prompt's named endpoints — disclosed rather than omitted). The check
crate's `cargo build` resolved its registry dependencies through `index.crates.io` and
`static.crates.io`. Candidate crates under test were built from the exact extracted sources
inspected, through `path` dependencies.

**Prerequisite state.** R58 (`logging-pipeline-contract`, a hard prerequisite) has
`decision: missing` and `acceptance: missing` (`inputs/prerequisites.json`). This report therefore
states its R58 assumption explicitly and gives the fallback branch (`### Parameters`). R57 is
accepted; its decision sets the default log path to `state_dir().join("rslbp.log")` under the
namespace `rslbp` (`research/topics/57-xdg-directory-set/DECISION.md`, "Affected items" paragraph).
R54 (`config-discovery-tiers`) has no decision (`research/topics/54-*/` contains only
`prompts/`), so its composition with this item is also stated as an assumption.

### Landscape

**Category decided.** The category is *a size-bounded, backup-count-capped file destination for
diagnostic events, attached as a second sink to the process's structured logging pipeline*. It
splits into two technical questions: (1) which component rotates the file by size and caps the
backup count, and (2) how a second sink attaches to R58's pipeline with its own level and format.

**Three-bin map (Rust).**

| Bin | Candidate | What it offers for this category | Found via |
|---|---|---|---|
| Built-in / first-party | `std::fs` | Building blocks only: `OpenOptions::append`, `rename`, `remove_file`, `DirBuilder`. No rotation primitive | Rust standard library |
| Built-in / first-party | `tracing-appender` 0.2.5 (tokio-rs, the `tracing` project's own appender crate) | Time-based rotation only (`Rotation::MINUTELY/HOURLY/DAILY/WEEKLY/NEVER`, `src/rolling.rs:501-509`) plus `max_log_files`; a `non_blocking` writer. **No size trigger** | crates.io; source read |
| Built-in / first-party | `tracing-subscriber` 0.3.23 `fmt` layer with per-layer filters | The composition mechanism: a second `fmt::Layer` with its own writer, format and `Filter` | crates.io; source |
| Established industry standard | `file-rotate` 0.8.0 | Standalone `io::Write` with `ContentLimit::Bytes/BytesSurpassed/Lines/Time` and `suffix::AppendCount` | crates.io; reverse dependencies |
| Established industry standard | `rolling-file` 0.2.0 | Standalone `io::Write`; `RollingConditionBasic::max_size` plus `max_files` | crates.io; reverse dependencies |
| Established industry standard | `flexi_logger` 0.31.10, `log4rs` 1.4.0 | Complete `log`-facade loggers with size+count rotation built in (`Criterion::Size` + `Cleanup::KeepLogFiles`; size trigger + fixed-window roller) | crates.io |
| Established industry standard | `fern` 0.7.1 | `log`-facade dispatcher; date-based file rotation only | crates.io |
| Up-and-comer | `logroller` 0.1.12 | Standalone writer; `Rotation::SizeBased` plus `max_keep_files`; optional `tracing` feature; background rotation worker | crates.io |
| Up-and-comer | `tracing-rolling-file` 0.1.3 | Fork of `rolling-file` ("based on rolling-file", README line 9) with an optional `non-blocking` feature | crates.io |
| Up-and-comer | `logforth-append-file` 0.4.0 (fast/logforth) | `rollover_size` plus `max_log_files` (`src/append.rs:126,138`); `log` facade | crates.io |
| Up-and-comer | `spdlog-rs` 0.5.3 | Own logging framework with a size-rotating sink | crates.io |

**Authoritative sources and why each counts.**

| Source | Why it is authoritative for this question |
|---|---|
| `tracing-appender` 0.2.5 source and `CHANGELOG.md` (extracted `.crate`) | The maintainers' shipped code is the ground truth for what the first-party appender can do |
| `tokio-rs/tracing` issue tracker: #1940 "Allow tracing-appender sized log and rotation" (open, opened 2022-02-18) and #858 "RotatingFileAppender" (open, opened 2020-07-28) | The maintainers' own record that size rotation is an acknowledged, unshipped request (`GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+appender+size+rotation`) |
| RustSec Advisory Database (`https://rustsec.org/packages/<name>.html`) | Maintained by the Rust Secure Code Working Group; the registry of record for Rust advisories |
| crates.io API | The registry of record for versions, licenses, declared `rust-version`, downloads, and reverse dependencies |
| Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`, commit `9da70eb3`) | Org-locked rules for this template: `R5.3` (logs live under State, MUST), `R3.8` (flag/env/config name parity, MUST), `R5.6` (secret masking in all output including logs, MUST), `R4.4` (verbosity ladder, MUST) |
| py precedent source (`py-launch-blueprint` @ `b55b8c26`) and ts source (`ts-launch-blueprint` @ `e5100b4f`) | The two sibling implementations whose behavior this item must preserve or justifiably differ from |
| R57 accepted decision | Binding upstream answer for the default path |

Python's `logging.handlers.RotatingFileHandler` documentation was **not retrieved** this session;
its semantics are taken from py's usage (`core/logging.py:241-246`) and are marked as such where
they matter.

**Well-regarded Rust projects surveyed (practice evidence).**

| Project | Evidence it is well regarded | What it does for a log file | Source (pinned) |
|---|---|---|---|
| Zed (`zed-industries/zed`) | 90,934 GitHub stars | **Hand-rolled** size rotation: `SINK_FILE_SIZE_BYTES_MAX: u64 = 1024 * 1024` (1 MiB), one backup (`Zed.log.old`), rotated both when the file is opened (`crates/zlog/src/sink.rs:35`, `:81-87`) and when a write crosses the limit (`:189-201`) | commit `bda9c0bd43a8d235d82adb01ea5bc875b861ecfc` |
| Helix (`helix-editor/helix`) | 46,349 stars | Default log file `cache_dir().join("helix.log")`; the `default_log_file()` function has no rotation (`helix-loader/src/lib.rs:163-164`) | commit `079a789e8cb08ead67f19e1971a1b7438b37354b` |
| rust-analyzer (`rust-lang/rust-analyzer`) | 16,877 stars; the Rust project's own language server | Opt-in `optional --log-file path: PathBuf` (`crates/rust-analyzer/src/cli/flags.rs:24`, field at `:208`) | commit `86493cee4d8902389c3217d8e95a3aae9368fd98` |
| czkawka (`qarmin/czkawka`) | 33,743 stars | `file-rotate` with `ContentLimit::BytesSurpassed(100 * 1024 * 1024)` and `AppendTimestamp::default(FileLimit::MaxFiles(3))`, under the `log` facade with `simplelog`, not `tracing` (`czkawka_core/src/common/logger.rs:43-47`) | commit `eb8b91dbb4d25dff416202674ee0de84ee4b5e5c` |
| Dragonfly client (`dragonflyoss/client`) | 73 stars on this repository; part of the Dragonfly project | The exact composition this item needs: `rolling-file` size rotation inside `tracing_appender::non_blocking`, under a `tracing-subscriber` `fmt` layer with `.with_ansi(false)` (`dragonfly-client/src/tracing/mod.rs:58-83`) | commit `ada717934e8676e5a9d016fc8ae2762a60bdd8b7` |
| solana-core | Largest reverse dependency of `rolling-file` (1,191,499 downloads on the depending version) | Uses `rolling-file` | `GET https://crates.io/api/v1/crates/rolling-file/reverse_dependencies` |

**What the survey shows.** Opt-in log files are common in well-regarded Rust command-line and
editor tools (rust-analyzer's `--log-file`, Helix's default file). Where these projects bound
the file by size, the two most prominent do it differently: Zed hand-rolls it, and czkawka uses
`file-rotate`. No surveyed project uses `tracing-appender` for size rotation, because it cannot
do size rotation.

### Principles and implementation

**Decision (yes/no).** Yes. `rs-launch-blueprint` ships an **optional rotating file log sink,
off by default, on the CLI surface only**. The web surface ships no file sink. This matches py
exactly: py's web profile calls `configure_logging(level=..., fmt=...)` with no `file_path`
(`src/py_launch_blueprint/web/logging.py:57-60`). Only the CLI passes
`file_path=_resolve_log_file(...)` (`src/py_launch_blueprint/cli/context.py:101-110`).

**Shared requirement.** A CLI user can opt in to a persistent, bounded, independently leveled
diagnostic record of invocations. The record is stored in the per-user State location. It must
not change the stdout/stderr contract, and it must never contain what redaction removes from the
console.

**Sources and agreement level.**

| # | Source | Agreement level | What it fixes |
|---|---|---|---|
| S1 | Ledger rows F255-F261, origin `py-only`, verdict `DIVERGENT` | **capability + policy** | That the capability exists, its enablement precedence, and its bounded-disk policy |
| S2 | Org standard `R5.3` (MUST, org-locked) | **standard** | Logs live under State: `$XDG_STATE_HOME/<tool>/` |
| S3 | Org standard `R3.8` (MUST) | **standard** | `--some-flag` ↔ `TOOL_SOME_FLAG` ↔ `some-flag` naming parity |
| S4 | Org standard `R5.6` (MUST) | **standard** | Secrets masked in all output, "`--debug`/request logs" included |
| S5 | Owner direction 2026-09-04 (`docs/port/OWNER-REVIEW.md`, quoted in the prompt) | **policy** | Best-in-class logging practice applied across py, ts and rs |

**Essential behaviors.** B1-B9 must agree across the three repositories; M1-M5 may vary.

| ID | Behavior | Must agree? |
|---|---|---|
| B1 | The file sink is opt-in and off by default | agree |
| B2 | It is enabled by a flag with an optional path, an env var, or a config key. Precedence is flag > env > config > off | agree |
| B3 | A bare flag (no path) selects `<state>/<tool>/<tool>.log` | agree (location rule is `R5.3`) |
| B4 | Disk use is bounded: size-triggered rotation with a fixed backup count; `.1` is the newest backup | agree on the *policy*; the numbers are M1 |
| B5 | The file has its own level. No sink ever filters out an event that another sink wants. With the file off, disabled-event cost is unchanged | agree |
| B6 | The file has its own format (`text`/`json`) and never contains terminal escape bytes | agree |
| B7 | The file receives exactly the redaction the console receives | agree (`R5.6`) |
| B8 | A logging failure never crashes the program; it is reported on stderr | agree |
| B9 | Records emitted before exit are on disk after exit | agree (py's `RotatingFileHandler` is a `StreamHandler` that flushes each record — Python-docs semantics, not re-fetched) |
| M1 | Default size and backup count | may vary; this report recommends py's numbers (below) |
| M2 | Env prefix (`PLBP_` / `RSLBP_`) | varies by tool name |
| M3 | Overshoot of the size limit by at most one record | may vary |
| M4 | Mechanism (handler, layer, stream) | varies by ecosystem |
| M5 | Default-on versus opt-in on non-CLI surfaces | not applicable: no surface ships a web file sink |

**Observable acceptance criteria.** AC1-AC9 map to B1-B9 and are the checks under
`### Validation strategy`. AC1: with no flag, env or config, no file is created. AC2: the
precedence table in member 3 holds (8 unit tests). AC3: bare `--log-file` writes
`$XDG_STATE_HOME/rslbp/rslbp.log`. AC4: after overflowing the limit, exactly `rslbp.log` and
`rslbp.log.1`…`.5` exist, no `.6`, and `.1` holds the newest records. AC5: with the console at
`warn` and the file at `debug`, a `debug!` appears in the file only, and
`LevelFilter::current()` is `debug`; without the file it is `warn`. AC6: the file has zero
`0x1b` bytes and `json` yields one JSON object per line. AC7: an event with a `token` field
shows the masked value in the file. AC8: an unusable path yields a stderr diagnostic and exit
status unchanged, never a panic. AC9: 1,000 events followed by `std::process::exit(0)` leave
1,000 lines on disk.

**Architectural alternatives (compared before libraries).**

| Alternative | Preserves | Loses | Verdict |
|---|---|---|---|
| A1 — no file sink (ts). Users redirect with `2>>file` | B1 trivially | B3, B4, B5 (debug in the file forces debug on the console), B6 (JSON file with a human console is impossible) | Rejected for the CLI. ts's omission is a **missing capability**, not a justified ecosystem difference: a Node CLI has the same user need |
| A2 — opt-in CLI file sink (py) | All of B1-B9 | nothing | **Recommended** |
| A3 — file sink on the web surface too | B1-B9 | Twelve-factor practice: a service writes its event stream to stdout/stderr and the platform routes it (reference not retrieved this session). It would also need a non-blocking writer on async workers | Rejected; py's web profile agrees. It remains an extension path (see member 2's tradeoffs) |
| A4 — file sink always on (Zed, Helix default a file) | B3-B9 | B1. An editor is a long-lived desktop app; a CLI in CI containers may have a read-only home, and writing on every invocation without consent is surprising | Rejected for a CLI template |

**Rotation-component alternatives, tested against the contract.** Every row below was executed
in `/tmp/r59-opus/check`. The workload: `tracing-subscriber` 0.3.23 `fmt` text layer, 84-byte
lines, a 4,096-byte limit, 5 backups, 400 events (check §B). For exit durability: 1,000 events
then `std::process::exit(0)`, three runs each (check §C).

| Writer | Whole records | Files ≤ limit | `.1`…`.5`, no `.6` | Lines on disk after `exit` | Construct on bad path | Log dir removed mid-run | CI on ubuntu+macOS | Unique normal deps |
|---|---|---|---|---|---|---|---|---|
| `file-rotate` `ContentLimit::Bytes` | **no** — `.1`…`.5` each end in a split record | yes (4,096) | yes | — | — | — | yes | 11 |
| `file-rotate` `BytesSurpassed` | yes | over by one record (4,116) | yes | 1000/1000 | **panics** (`expect("create dir")`, `src/lib.rs` `new`) | **panics** inside `write` | yes | 11 (`chrono`, `flate2` mandatory) |
| `file-rotate` path is unopenable | — | — | — | — | `write` returns **`Ok(10)` and drops the bytes** | — | — | — |
| `rolling-file` default `new` | yes | over by one record (4,116) | yes | **897/1000** (a `BufWriter`; the global subscriber is never dropped, so the same 897 appear after a normal `return` from `main`) | `Err(NotADirectory)` | not tested | **no** — CI is `ubuntu-18.04` + `windows-latest` | 5 |
| `rolling-file` `new_with_buffer_capacity(…, 0)` | yes | over by one record | yes | 1000/1000 | `Err` | not tested | no | 5 |
| `tracing-rolling-file` (+ a flush-on-drop `MakeWriter`, since it has no capacity option) | yes | over by one record | yes | not tested | `Err(AlreadyExists)` | not tested | yes | 5 |
| `logroller` `SizeBased` | yes | **yes (4,032)** — py's pre-write rule | yes, *if* the process lives 500 ms after rotating | — | `Err(CreateDirectoryFailed)` | not tested | yes | 38 with its `tracing` feature |
| `logroller` then immediate `exit` | — | — | **no** — `rslbp.log.6` plus orphan `rslbp.log.pending.N` files that accumulate across runs (after 3 runs: `.pending.8`, `.13`-`.16`, `.21`-`.24`) | — | — | — | — | — |
| **template-owned `RotatingFile`** (76 lines, std only) | yes | **yes (4,032)** | yes | **1000/1000** | `Err(AlreadyExists)` | **`Err(NotFound)`**, no panic | template CI (planned) | **0** |

**Why the template-owned writer wins.** It is the only design that satisfies B4, B8 and B9
together. `file-rotate` breaks B8: it panics in the constructor and inside `write`, and it
silently drops bytes. The `rolling-file` family breaks B9 by default and fails fitness gate 4 on
CI evidence. `logroller` breaks B4 for the short-lived processes a CLI is made of, because the
archive shift runs on a background thread that `exit` kills. The owned writer is 76 lines. Its
rotation loop follows `rolling-file`'s `rotate_files` (MIT OR Apache-2.0; credited in a
comment), and its trigger is py's rule: rotate *before* a write that would reach the limit.
Owning this much code has precedent: Zed, the most-starred project surveyed, hand-rolls its size
rotation (`crates/zlog/src/sink.rs`). It is also the closest Rust form of py's own design: py's
rotation comes from the Python standard library (`logging.handlers.RotatingFileHandler`), not a
third-party package. Rust's standard library has no equivalent, so a std-only writer keeps py's
zero-dependency property. That makes it a justified ecosystem difference in mechanism, not a
departure from the pattern.

**How the full example composes.** The sketch below is the template's form. It is equivalent to the `Registry::default().with(vec![console, file])` form executed in check §A; the `Option`/`transpose` wiring itself is proposed, not executed.

```rust
// Binary crate only; the library crate never installs a subscriber (R58's host-safety rule).
let console = fmt::layer().with_writer(io::stderr).with_filter(console_level);        // R58's layer
let file = log_file_path.map(|p| -> io::Result<_> {
    let w = RotatingFile::open(p, ROTATE_MAX_BYTES, ROTATE_BACKUP_COUNT)?;             // member 1
    let l = fmt::layer().with_writer(Mutex::new(w)).with_ansi(false);                   // member 2
    Ok(match file_format { Text => l.with_filter(file_level).boxed(),
                           Json => l.json().with_filter(file_level).boxed() })
}).transpose()?;                                                                        // member 3 resolved the path
Registry::default().with(vec![console.boxed()].into_iter().chain(file).collect::<Vec<_>>()).try_init()?;
```

`Vec<Box<dyn Layer<Registry>>>` implements `Layer`. It is the idiomatic way to add a
runtime-optional layer; stacking two separately boxed `Layer<Registry>` values fails to compile
(error `E0277`, observed while building the check).

**The dual-sink floor needs no computation** (answers the MEDIUM question). With *per-layer*
filters, `tracing-subscriber` computes the global maximum level as the most verbose of the
layers' filters. Observed in check §A:

| Scenario | `LevelFilter::current()` | Console (stderr) | File |
|---|---|---|---|
| Console `warn` + file `debug` | `debug` | `warn-event` only | `debug-event token_len=3` and `warn-event` |
| Console `warn`, no file | `warn` | — | — |
| Console `warn` + file `debug` + a registry-level `LevelFilter::WARN` | `debug` | `warn-event` | **`warn-event` only — the debug event is lost** |

The idiomatic Rust shape of py's `floor = min(level, file_level)` (`core/logging.py:259-262`) is
therefore a rule, not a computation. Every level control must be a per-layer filter
(`Layer::with_filter`), never a registry-level filter. That constrains R58's console level
(recorded under `### Parameters`). A related constraint: `tracing`'s compile-time
`max_level_*` / `release_max_level_*` features cap every sink, so the template must not enable
one below `debug` (file level `debug` would become unreachable).

**Initialization order** (answers the second MEDIUM question). Wire everything in **one pass,
after configuration is fully resolved**. The order: parse args → R54 discovers and merges config →
resolve the console level (R58's F274 ladder) and the file path (member 3) → build one
subscriber → `try_init()` once. py does the same. It renders config warnings through the
renderer before `configure_logging` runs (`cli/context.py:96-99`), then configures the console
and file together (`:101-110`). Failures before initialization go to stderr through R67's
error path, not through `tracing`. A `tracing_subscriber::reload` layer would allow
console-first, file-later initialization. It is not needed, because a CLI's configuration does
not change mid-process, and it was not evaluated here.

**Representative performance** (check §D). Workload: 100,000 `info!` events with two fields,
text format, one file layer, release build, 10 MiB limit, Apple M4 Pro, APFS, three runs each.
Emit time is measured on the calling thread; total time includes draining.

| Writer | Emit ms (3 runs) | Total ms | Per event (emit) |
|---|---|---|---|
| owned `RotatingFile`, blocking | 209 / 239 / 232 | same | ≈2.1-2.4 µs |
| `rolling-file` (capacity 0), blocking | 212 / 207 / 205 | same | ≈2.1 µs |
| `file-rotate` `BytesSurpassed`, blocking | 502 / 576 / 420 | same | ≈4-6 µs |
| `logroller`, blocking | 277 / 310 / 539 | same | ≈3-5 µs |
| owned + `tracing_appender::non_blocking` (`lossy(false)`) | 44 / 44 / 43 | 153 / 203 / 202 | ≈0.44 µs |

The blocking cost is one unbuffered `write(2)` per event. That is irrelevant for a CLI, whose
file level is `debug` only when the user asked. The figures come from one machine and are
indicative only; no absolute ranking follows from them.

**Checks: proposed versus executed.** Executed: §A floor, §B rotation, §C exit durability,
§E ANSI, §F constructor and runtime failure, §G precedence unit tests, §H MSRV build on 1.96.0.
Proposed but not executed: AC7 redaction (it needs R58's redaction component), the Ubuntu run,
and an end-to-end binary test through `clap`.

**Default numbers** (answers the LOW question). No idiomatic Rust default exists.
`tracing-appender` leaves `max_log_files` unset, so retention is unbounded by default.
`file-rotate` and `rolling-file` require both numbers as arguments. `logroller`'s documentation
examples use 100 MB. Zed uses 1 MiB with one backup, and czkawka uses 100 MiB with three. py's
policy of 10 MiB × 5 backups (`core/logging.py:82-83`) bounds disk use at 60 MiB (six files).
That fits a per-user State directory and keeps weeks of `debug` output from a CLI. **Recommend
matching py: 10 MiB, 5 backups, as constants.** Neither py nor this report exposes them as
settings. This is a template default, not a cross-repository requirement; the org standard has
no rotation rule (`grep -i rotat` on the standard matched nothing).

**Baseline review.**

BASELINE-REVIEW: F260 — a setting's name must say what it controls, and flag/env/config names must correspond (`R3.8`, MUST) — name the file sink's format setting `file-format` (`[logging] file-format` ↔ `RSLBP_LOG_FILE_FORMAT`), not py's `format` / `PLBP_LOG_FORMAT`, and leave `[logging] format` / `RSLBP_LOG_FORMAT` to R58's console format — evidence: py passes `file_format=_resolve_log_format(settings.logging.format)` to the file sink only (`src/py_launch_blueprint/cli/context.py:109`), while the console is fixed at `fmt=LogFormat.AUTO` (`:106`); `_resolve_log_format`'s docstring reads "File sink format: $PLBP_LOG_FORMAT > config ``logging.format``" (`:233-234`); `LoggingSettings.format` sits beside `level` with no file qualifier (`core/settings.py:54-57`). The name therefore reads as pipeline-wide and would collide with R58's console-format control (F250). The R59 prompt itself inherits the misreading ("`level`/`format` defaults belong to R58's console pipeline"). Affected items: R59 (this item), R58 (owns the `format` key), R54 (config schema), and the py follow-on rename.

### Recommendation

**One stack.** `tracing` 0.1.44 + `tracing-subscriber` 0.3.23 (both R58's, assumed). The file
sink adds a second `fmt::Layer` with a per-layer `LevelFilter` and `.with_ansi(false)`, in `text`
or `.json()` format. It writes through a **template-owned `RotatingFile`** (std only, about 76
lines): pre-write size trigger, `.1`-newest backup shift, unbuffered writes, and I/O errors
returned rather than panics. The policy is 10 MiB × 5 backups. The sink is enabled by
`--log-file[=PATH]` ↔ `RSLBP_LOG_FILE` ↔ `[logging] file`, with precedence flag > env > config >
off. A bare flag, or an empty env value, selects R57's `state_dir().join("rslbp.log")`. The file
level is `[logging] file-level` (default `debug`) and the format is `[logging] file-format`
(default `text`). The sink is CLI-only and initialized once, after config resolution. No new
crate dependency.

Ranked runner-up for the rotation component: `file-rotate` 0.8.0 with `BytesSurpassed` +
`AppendCount::new(5)`, behind a template constructor that creates the directory and probes the
open first. It is the choice if the owner prefers a dependency to 76 owned lines; its residual
runtime panic is documented under member 1.

### Members

#### Rotating file writer (F256, F257) — template-owned `RotatingFile`, std only

##### Landscape

The field is mapped under `### Landscape`. For this member: the first-party appender
(`tracing-appender`) cannot rotate by size. Tracker items #1940 (2022-02-18) and #858
(2020-07-28) are both still open. Four standalone size+count writers exist: `file-rotate`,
`rolling-file`, `tracing-rolling-file` and `logroller`. Two `log`-facade loggers ship size+count
rotation internally (`flexi_logger`, `log4rs`), and `logforth-append-file` adds one for `logforth`.
Practice is split: Zed hand-rolls size rotation, czkawka uses `file-rotate`, Dragonfly and
solana-core use `rolling-file`.

##### Principles and implementation

The member realizes B4, B8 and B9. The code was executed as `/tmp/r59-opus/check/src/rotating.rs`
(sha256 `2e5b7ff74cdc3961c40873fd448639c14cceaa7e38698a237d42c138e643b4e7`, 76 lines):

```rust
pub struct RotatingFile { path: PathBuf, max_bytes: u64, backups: usize, file: Option<File>, size: u64 }

impl RotatingFile {
    pub fn open(path: impl Into<PathBuf>, max_bytes: u64, backups: usize) -> io::Result<Self> {
        // create parent with DirBuilder { recursive, mode 0o700 on unix } — py uses mode=0o700 (core/logging.py:235)
        // open append+create; size = metadata().len()
    }
    fn rotate(&mut self) -> io::Result<()> {
        // close; remove .{backups} (NotFound ignored); rename .{n} -> .{n+1} for n = backups-1..1;
        // rename base -> .1; reopen; size = 0
    }
}
impl Write for RotatingFile {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        // py rule: rotate BEFORE a write that would reach max_bytes; either limit 0 disables rotation
        if self.max_bytes > 0 && self.backups > 0 && self.size > 0 && self.size + len >= self.max_bytes { self.rotate()?; }
        // reopen if a previous rotation failed; write_all; size += len
    }
}
```

The writer returns I/O errors instead of panicking. `tracing-subscriber`'s `fmt` layer reports
a writer error on stderr, which gives B8 the same outcome as py's `Handler.handleError`: the
record is lost, a diagnostic is printed, and the program continues. Writes are unbuffered
(`File`, not `BufWriter`), so B9 holds without any guard or flush hook. The template wraps the
writer in `Mutex`; `Mutex<W: Write>` implements `MakeWriter`. The `size > 0` guard stops an
oversized single record from rotating an empty file. One difference from py: py's rule has no
such guard, so py can rotate an empty file. The difference is harmless and falls under M3.

##### Dominant choice

There is none for size+count under `tracing`. By downloads, `file-rotate` (1,090,531 in 90 days)
and `rolling-file` (1,141,080) are level. Both are dwarfed by `tracing-appender` (33,200,763),
which does not meet the requirement. The most prominent single practice example, Zed, is
hand-rolled.

##### Qualified shortlist

These candidates pass all six gates; the requirement tests follow in the table under
`### Principles and implementation`.

| Candidate | Figures (crates.io, 2026-09-26) | GitHub (2026-09-26) | Responsiveness (10 most recent issues) | Advisories | Maintenance | Contract result |
|---|---|---|---|---|---|---|
| `file-rotate` 0.8.0, MIT, no `rust-version`; builds on 1.96.0 | 90-day 1,090,531; all-time 5,648,161; last `0.8.0` 2025-02-27 | `kstrafe/file-rotate` 41 stars, not archived, pushed 2025-08-30, 9 open issues | median 2.6 days; 7 answered, 3 unanswered (sample back to 2023-03-08) | none (`rustsec.org/packages/file-rotate.html` → 404, no page) | `stable-quiet` (19 months since release; responsive; builds on 1.98.1 with 2 deprecation warnings) | panics (2 paths); silent drop; overshoot one record |
| `tracing-rolling-file` 0.1.3, MIT/Apache-2.0 (LICENSE file dual) | 637,787; 1,717,026; `0.1.3` 2025-08-16 | `cavivie/tracing-rolling-file` 12 stars, pushed 2025-08-16, 0 open issues | no issues ever filed (n = 0) | none | `stable-quiet` | `BufWriter` with no capacity knob (needs a flush-on-drop `MakeWriter`); only 4 reverse dependencies |
| `logroller` 0.1.12, MIT, `rust-version = "1.71"` tested in CI | 163,169; 529,942; `0.1.12` 2026-07-01 | `alasdairpan/logroller` 21 stars, pushed 2026-07-01, 1 open issue | median 0.5 days; 8 answered, 1 unanswered (9 issues total) | none | `active` | exact py trigger, but orphaned `.pending.N` files and a `.6` backup on abrupt exit |
| template-owned `RotatingFile` | inapplicable: not a published crate; template code is covered by template CI | inapplicable | inapplicable | inapplicable | owned | passes every tested row |

##### Excluded by gate

- `rolling-file` 0.2.0 — **gate 4**. Its only CI workflow (`.github/workflows/test.yaml` @
  `39110315`) runs on `os: [ubuntu-18.04, windows-latest]`. macOS is never tested, and
  `ubuntu-18.04` is a retired runner image, so the workflow cannot run today. The code passes
  the other gates: MIT/Apache-2.0 per its dual LICENSE file (GitHub's `NOASSERTION` is a
  detection miss), builds on 1.96.0, no advisory, no `unsafe`. It passed the local macOS
  rotation test. Figures: 1,141,080 / 7,068,759; last release 2023-01-14; 19 stars; last push
  2023-02-24; 1 open issue. Maintenance: `at-risk` — concrete signal: its CI cannot execute and
  there has been no commit for 43 months. Its algorithm lives on in `tracing-rolling-file` and
  in the owned writer.
- `logforth-append-file` 0.4.0 — **gate 1 (qualified) and gate 5**. It is Apache-2.0 only.
  That combines with an `MIT OR Apache-2.0` project, but it removes the MIT-only option for
  downstream users of the built binary. It is coupled to the `log` facade through
  `logforth-core`, not `tracing` (gate 5, runtime coupling). Declared `rust-version = "1.89.0"`
  passes gate 2.
- `fern` 0.7.1 — not a gate failure, a **requirement** failure: date-based rotation only. It is
  listed here only so its absence from the shortlist is explained.
- `tracing-appender` 0.2.5 — passes all six gates (MIT; `rust-version = "1.63.0"`; no advisory;
  zero `unsafe` tokens in `src`; tokio-rs CI) but fails the **requirement**: no size trigger.
  It is rejected on requirement, not by gate.

##### Up-and-comers

`logroller` is the most promising: active, responsive, MSRV-tested, with an exact pre-write
trigger and a `file_mode` option. It becomes viable for a CLI once its size-based archive shift
runs synchronously, or once it reconciles `.pending.N` files at startup. That is a re-verify
trigger. `spdlog-rs` 0.5.3 (MIT OR Apache-2.0, `rust-version = "1.71"`, 70,727 / 246,631, 170
stars) is a separate logging framework, so adopting it would replace R58's pipeline; it was not
evaluated further.

##### Fit for this template

CLI: exact fit. The sink is synchronous, has no guard to hold across R67's exit path, and is
durable under `process::exit`. Library: not involved, because the library never installs sinks.
Web service: not used (A3 rejected). py precedent: same trigger, same `.N` naming, same
0o700 directory mode, same failure outcome. ts precedent: nothing to match. The cost is 76
lines of template-owned code plus unit tests. That is less than the 11-crate dependency tree
`file-rotate` brings for a feature that is off by default.

##### Recommendation

Ship `RotatingFile` in the CLI binary crate's logging module with
`ROTATE_MAX_BYTES = 10 * 1024 * 1024` and `ROTATE_BACKUP_COUNT = 5`. Credit `rolling-file`'s
`rotate_files` in a comment, under its MIT OR Apache-2.0 license.

##### Ranked runner-up

`file-rotate` 0.8.0 with `ContentLimit::BytesSurpassed(ROTATE_MAX_BYTES)` and
`suffix::AppendCount::new(5)`. Never use `ContentLimit::Bytes`: it splits records (check §B).
Wrap construction in a template function that creates the directory (0o700) and probes
`OpenOptions::new().append(true).create(true).open(path)` first. That removes the constructor
panic and the startup silent drop. **Residual risk, not fenceable without `catch_unwind` in the
writer:** if the log directory is deleted mid-run and cannot be recreated, `rotate()` panics in
`ensure_log_directory_exists` (check §F: `PANICKED`). Third choice: `tracing-rolling-file` 0.1.3
plus a flush-on-drop `MakeWriter`.

##### Tradeoffs

The owned writer lacks compression and time-based rotation; neither is required. The template
maintains the code and its tests. Like py's handler, it is not safe for several processes
rotating one file; two concurrent CLI invocations can interleave rotations. The size check
counts bytes written by this process plus the file's size at open, as py does. A dependency
would move maintenance off the template but import defects that break B8 (`file-rotate`) or B4
(`logroller`).

##### Parameters

`ROTATE_MAX_BYTES = 10 MiB` and `ROTATE_BACKUP_COUNT = 5` (template constants, not registered
parameters). Directory mode 0o700 on Unix. File mode: the process umask, as in py (unchanged;
a 0o600 file mode was considered and not tested).

##### Migration implications

New `crates/<cli>/src/logging/rotating.rs` with the writer and its unit tests. No `Cargo.toml`
change. Delete nothing.

##### Validation strategy

Executed (check §B, §C, §F): rotation layout and sizes, 1,000/1,000 lines after
`process::exit`, `Err` on a bad parent, and `Err(NotFound)` after the directory is removed.
Planned: port these as `#[test]`s using `tempfile`, run in template CI on `ubuntu-latest` and
`macos-latest`, including the rotation-boundary case (a record exactly reaching the limit).

##### Confidence & re-verify trigger

Confidence **medium-high** that the behavior is correct: every property was observed. Confidence
**medium** that owned code beats a dependency: that is a judgment which the owner may reverse.
Re-verify when tokio-rs/tracing#1940 ships size rotation in `tracing-appender`, when
`file-rotate` removes its `expect`/silent-drop paths, or when `logroller` makes size-based
shifting synchronous.

##### Sources

- `https://crates.io/api/v1/crates/{file-rotate,rolling-file,tracing-rolling-file,logroller,logforth-append-file,fern,spdlog-rs,tracing-appender}` and `/versions`, retrieved 2026-09-26.
- `https://api.github.com/repos/{kstrafe/file-rotate,Axcient/rolling-file-rs,cavivie/tracing-rolling-file,alasdairpan/logroller,fast/logforth,daboross/fern,SpriteOvO/spdlog-rs}` plus `search/issues` totals and `.github/workflows` contents, retrieved 2026-09-26.
- `https://rustsec.org/packages/<name>.html` for each candidate (HTTP 404 = no advisories), retrieved 2026-09-26.
- `https://github.com/tokio-rs/tracing/issues/1940`, `/858` (via the search API), retrieved 2026-09-26.
- Extracted sources: `file-rotate-0.8.0/src/lib.rs` (`new`, `ensure_log_directory_exists`, `open_file`, `Write`), `rolling-file-0.2.0/src/lib.rs:160-325`, `logroller-0.1.12/src/lib.rs:440-460,1508-1530`, `tracing-appender-0.2.5/src/rolling.rs:501-509`.
- Zed `crates/zlog/src/sink.rs` @ `bda9c0bd`; czkawka `czkawka_core/src/common/logger.rs` @ `eb8b91db`.
- py `src/py_launch_blueprint/core/logging.py:82-83,233-252` @ `b55b8c26`.

#### Second sink layer (F260, F261) — `tracing-subscriber` 0.3.23 per-layer-filtered `fmt` layer

##### Landscape

Under `tracing`, which R58 is assumed to select, the one native way to attach a second
destination is another `Layer` on the `Registry`. A per-layer `Filter` has been available since
`tracing-subscriber` 0.3. Alternatives: a single layer with a tee writer (`MakeWriterExt::and`),
which loses the independent level and format; or a `log`-facade logger, which replaces R58's
pipeline.

##### Principles and implementation

The member realizes B5, B6 and B7. Composition (check §A): `fmt::layer().with_writer(Mutex::new(
RotatingFile)).with_ansi(false)`, then `.json()` if `file-format = json`, then
`.with_filter(file_level)`, then `.boxed()`. The layer is added to a `Vec<Box<dyn Layer<Registry>>>`
alongside R58's console layer. The floor is automatic: `LevelFilter::current()` was `debug` with
the file layer and `warn` without it. That requires every level control, including R58's console
level, to be a per-layer filter; a registry-level filter lost the debug event (table under
`### Principles and implementation`). ANSI (check §E): a *default* `fmt::layer()` wrote **12
escape bytes** into the file, because the `ansi` feature defaults on. `.with_ansi(false)` wrote
**0**. In both cases 0.3.23 escaped escape bytes inside user-supplied field values
(`user_input="\u{1b}[31mred…"`), which is the RUSTSEC-2025-0055 fix. Redaction (B7) must reuse
R58's mechanism. If R58 redacts in a field formatter (`FormatFields`), the file layer must be
built with the same formatter; if R58 redacts in a wrapping layer, the file layer must sit
behind it.

##### Dominant choice

`tracing-subscriber`: 90-day downloads 147,886,240; all-time 627,181,762; last release `0.3.23`
2026-03-13 (`GET https://crates.io/api/v1/crates/tracing-subscriber/versions`); MIT;
`rust-version = "1.65.0"`. Repository `tokio-rs/tracing`: 6,891 stars, not archived, pushed
2026-05-30, 628 open issues (`search/issues` `total_count`).

##### Qualified shortlist

- `tracing-subscriber` 0.3.23 `fmt` layer (recommended). Gate 1: MIT. Gate 2: `rust-version =
  "1.65.0"`, builds on 1.96.0. Gate 3: RUSTSEC-2025-0055 (ANSI escape injection) is patched in
  `>=0.3.20` (`https://rustsec.org/advisories/RUSTSEC-2025-0055.html`), and 0.3.23 is in range;
  `tracing-subscriber` 0.3.23 has 26 `unsafe` tokens in 6 files (`reload.rs`, `fmt/mod.rs`,
  `fmt/fmt_layer.rs`, `layer/layered.rs`, `layer/mod.rs`, `filter/layer_filters/mod.rs`; the
  layer-downcast machinery) and no `forbid(unsafe_code)`; `tracing-appender` 0.2.5 has 0. Gate 4: tokio-rs CI. Gate 5: this member needs features `fmt`, `std`,
  `registry`, `json` (`ansi` stays on for the console); no async-runtime coupling. Gate 6: 18
  unique normal dependencies with those features, moderate compile cost, already paid by R58.
- A tee writer (`MakeWriterExt::and`) — passes the gates (same crate), fails B5/B6.

##### Excluded by gate

None. Every candidate for this member is `tracing-subscriber` itself; the alternatives fail on
requirement, not on a gate.

##### Up-and-comers

None relevant. `logforth` 0.30.1 (238 stars, pushed 2026-09-21) is a `log`-facade framework and
would be an R58-level choice.

##### Fit for this template

CLI: exact fit. The file layer is added only when member 3 resolves a path. Library: none. Web:
none. py precedent: same shared processors, a separate renderer, and an independent level; the
`min` floor becomes automatic. `tracing-appender`'s `non_blocking` is *not* part of the CLI
stack. With `process::exit`, as R67's exit path may use, a non-blocking writer lost **867-877 of
1,000** lines (check §C: 133, 123, 127 on disk). When its `WorkerGuard` was dropped before
returning, all 1,000 lines survived.

##### Recommendation

`tracing-subscriber` 0.3.23 second `fmt::Layer`: per-layer `LevelFilter` from `file-level`
(default `DEBUG`), `.with_ansi(false)`, `text` by default, `.json()` when `file-format = json`,
writer `Mutex<RotatingFile>`.

##### Ranked runner-up

None within `tracing`. If R58 selects a `log`-facade stack instead, the whole sink becomes
`flexi_logger` 0.31.10 (MIT OR Apache-2.0; `rust-version = "1.87.0"`; 3,472,842 / 24,320,546;
last release 2026-08-07; `emabee/flexi_logger` 394 stars, 5 open issues, median response 0.2
days; CI on `ubuntu-latest`, `windows-latest`, `macos-latest` with `stable` and `1.87.0`). It
would use `Criterion::Size` + `Cleanup::KeepLogFiles(5)` + `duplicate_to_stderr` for the console.
Its rotation behavior was not tested here.

##### Tradeoffs

Blocking writes cost about 2 µs per event (check §D), which is acceptable for an opt-in CLI
sink. A web file sink, if ever wanted, would add `tracing_appender::non_blocking` with the guard
held in `main` until graceful shutdown; `lossy(false)` preserves B9 at the price of back-pressure
when the 128,000-line queue fills. Two `fmt` layers format each event twice when both are
enabled; that cost is small, and it is the price of independent formats.

##### Parameters

`file-level` default `debug` (py `core/settings.py:56`). `file-format` default `text` (py
`:57`, under the BASELINE-REVIEW rename).

##### Migration implications

`crates/<cli>/src/logging/mod.rs` (R58's module) gains `file_layer(path, level, format) ->
io::Result<Box<dyn Layer<Registry> + Send + Sync>>`. `tracing-subscriber` must enable the `json`
feature, which R58 likely enables anyway for F250.

##### Validation strategy

Executed: §A floor (3 scenarios), §E ANSI (default: 12 escape bytes; off: 0), §C non-blocking
loss. Planned: AC7 redaction, i.e. `info!(token = "s3cr3t")` must not appear in the file, once
R58 lands; and a test that R58's console level is a per-layer filter (assert
`LevelFilter::current() == DEBUG` with the console at `warn` and the file at `debug`).

##### Confidence & re-verify trigger

**High** for the floor and ANSI behavior (observed). Re-verify if R58 chooses a registry-level
`EnvFilter` or a `log`-facade stack, or on a `tracing-subscriber` 0.4 release.

##### Sources

- `https://crates.io/api/v1/crates/tracing-subscriber` and `/versions`; `https://crates.io/api/v1/crates/tracing` (`max_stable_version` 0.1.44; 200,225,369 / 877,269,566), retrieved 2026-09-26.
- `https://api.github.com/repos/tokio-rs/tracing`; `search/issues?q=repo:tokio-rs/tracing+is:issue+is:open` (628), retrieved 2026-09-26.
- `https://rustsec.org/packages/tracing-subscriber.html`, `https://rustsec.org/advisories/RUSTSEC-2025-0055.html` ("Patched >=0.3.20"), retrieved 2026-09-26.
- Dragonfly `dragonfly-client/src/tracing/mod.rs:58-83` @ `ada71793` (the same layer shape with `.with_ansi(false)`).
- py `core/logging.py:233-262`, `web/logging.py:57-60` @ `b55b8c26`.

#### Enablement and precedence (F255, F258, F259) — `[logging]` table + `--log-file[=PATH]`, resolved in one pass

##### Landscape

This is a pattern member: crate figures are inapplicable because no crate is chosen. The
argument parser is R60's choice, and R60 is resolved on `clap = { version = "4.6.6", features = ["derive", "env", …] }` (`research/topics/60-cli-parsing-framework/DECISION.md:267`); `Option<Option<PathBuf>>` with `num_args = 0..=1` is how `clap` expresses a flag with an optional value. The config loader is R54's choice. The
path is R57's `etcetera`-based State directory. Practice: rust-analyzer exposes an optional
`--log-file path`, and Helix defaults to a file under its cache directory.

##### Principles and implementation

The member realizes B1-B3. The resolver is a pure function, executed with 8 unit tests passing
on 1.98.1 and 1.96.0 (check §G; `/tmp/r59-opus/check/src/lib.rs`, sha256
`7255b87b83907cfedb33a911111a9705752a94c3615eada68cd18c1c96bd9861`):

```rust
/// `--log-file` parsed as Option<Option<PathBuf>> (clap num_args = 0..=1):
/// None = absent, Some(None) = bare flag, Some(Some(p)) = explicit path.
pub fn resolve_log_file(flag: Option<Option<PathBuf>>, env: Option<OsString>,
                        config_file: Option<&Path>, default_path: impl FnOnce() -> Option<PathBuf>)
                        -> Option<PathBuf>
```

| Inputs | Result |
|---|---|
| nothing | off |
| config `file = "/c.log"` | `/c.log` |
| config `file = ""` | off |
| env `/e.log` + config `/c.log` | `/e.log` |
| env set but empty + config | default path (py's "presence enables", `cli/context.py:222`) |
| flag `/f.log` + env | `/f.log` |
| bare flag + env | default path |
| bare flag, no State directory resolvable | off (the R57 fallback: `default_path` returns `None`) |

The env var is read directly in the resolver rather than through the argument parser's env
binding, so that the empty-value rule is explicit and testable. The config schema adds
`[logging] file`, `file-level`, `file-format` beside R58's `level` and `format`. The transform
is deterministic: `logging.<key>` ↔ `--log-<key>` ↔ `RSLBP_LOG_<KEY>`, which satisfies `R3.8`.
Only `file` gets a flag (`--log-file`), as in py (`cli/options.py:93-99`). `file-level` and
`file-format` are env + config, and `R3.8` requires their env names to follow the same transform.
The `RSLBP_` prefix follows R57's `rslbp` namespace.

##### Dominant choice

The dominant choice is py's `_resolve_log_file` ladder (`cli/context.py:212-230`) in its Rust
shape. No competing Rust convention was found; rust-analyzer offers a flag only.

##### Qualified shortlist

- Resolver after full config merge (recommended).
- Letting R54 map `RSLBP_LOG_FILE` into `logging.file` as part of its env tier. That is equivalent
  if R54 has an env tier, but it cannot express "bare flag" or "empty env = default" without
  special cases in R54.

##### Excluded by gate

Inapplicable: a pattern member has no license, MSRV, advisory or platform gate of its own. The
resolver uses only `std` and passed on 1.96.0 (gate 2) and on macOS (gate 4, Ubuntu planned).

##### Up-and-comers

Inapplicable for a pattern member; no emerging alternative convention was found.

##### Fit for this template

CLI: this is the whole enablement surface. Library: none; paths and levels are passed in. Web:
none. py precedent: identical precedence and empty-env behavior; the one change is the key
rename under BASELINE-REVIEW F260. ts: no counterpart. Adding it is a follow-on.

##### Recommendation

Adopt the resolver, the three `[logging]` keys, `--log-file[=PATH]` ↔ `RSLBP_LOG_FILE`,
`RSLBP_LOG_FILE_LEVEL`, and `RSLBP_LOG_FILE_FORMAT` (validated like py's `PLBP_LOG_FORMAT`: an
invalid value is a config error, never a silent fallback, per `cli/context.py:240-244`). Keep
single-pass initialization after config merge.

##### Ranked runner-up

Initialize the console first, then add the file layer through `tracing_subscriber::reload`.
Choose this only if R58 requires logging before config discovery. It was not evaluated here.

##### Tradeoffs

Reading the env var in the resolver duplicates a little of what the argument parser could do,
but it keeps the empty-value rule explicit. Single-pass initialization means config-discovery
problems cannot be logged to the file, only printed to stderr, as in py.

##### Parameters

`default_path` = R57's `state_dir().join("rslbp.log")`. If R57's State directory cannot be
resolved (for example, no home directory), a bare flag yields "off" plus a stderr warning, while
an explicit path still works.

##### Migration implications

The CLI argument definitions gain `--log-file`. R54's config struct gains three fields with
serde `kebab-case`. The logging module gains `resolve_log_file`. The docs' config reference and
`--help` gain the enablement ladder.

##### Validation strategy

Executed: 8 unit tests (check §G). Planned: an integration test that runs the binary with
`XDG_STATE_HOME=<tmp>` and a bare `--log-file`, then asserts
`<tmp>/rslbp/rslbp.log` exists (AC3); and one with no flag, env or config asserting that no file
exists (AC1).

##### Confidence & re-verify trigger

**High** for the precedence (it is a pure function mirroring py). **Medium** for the key names,
which depend on R54's naming convention and on R58 keeping `format` for the console.
Re-verify on R54's or R58's decision.

##### Sources

- py `cli/options.py:93-99`, `cli/context.py:95-110,212-244`, `core/settings.py:49-58`, `core/paths.py:194-196` @ `b55b8c26`.
- ts `src/lib/config.ts` (schema has only `token`/`workspace`/`limit`), `src/lib/logger.ts:58-65` @ `e5100b4f`.
- Org CLI Design Standard v1.4.14 `R3.8`, `R5.3`, blob `f9de0437`.
- `research/topics/57-xdg-directory-set/DECISION.md` (accepted).
- rust-analyzer `crates/rust-analyzer/src/cli/flags.rs:24` @ `86493cee`; Helix `helix-loader/src/lib.rs:163-164` @ `079a789e`.

### Compatibility

All three members were compiled and executed **together** in one crate,
`/tmp/r59-opus/check`. Its `Cargo.toml` (sha256
`fd024bfc2e2775f77b21b857df1a1339a741207a904d9acda456240dc163b51f`) pins `tracing = "=0.1.44"`,
`tracing-subscriber = "=0.3.23"` (features `fmt`, `std`, `registry`, `ansi`, `json`), and
`tracing-appender = "=0.2.5"` (comparison only). It declares `edition = "2024"` and
`rust-version = "1.96"`. Builds: `cargo build --release` on rustc 1.98.1, and
`rustup run 1.96.0 cargo build --release` → `Finished`. `cargo test --lib` → `8 passed` on both.
Shared-adopter evidence for the layer shape: the Dragonfly client composes `tracing-subscriber`'s
`fmt` layer (`.with_ansi(false)`) with a size-rotating writer (`dragonfly-client/src/tracing/mod.rs`
@ `ada71793`). The owned writer has no adopter by construction; the check crate is its
compatibility evidence.

### Parameters

- owns: nothing (the prompt's `- owns:` is empty).
- assumes `logging-pipeline-contract` = "`tracing` 0.1 + `tracing-subscriber` 0.3 `Registry`; the
  console level is a **per-layer** filter (no registry-level filter); only the binary installs
  the subscriber, once, after config resolution; the library never installs one; redaction is
  reusable by a second `fmt` layer; `[logging] level` and `[logging] format` belong to the
  console". **Fallback branch:** if R58 selects a `log`-facade stack, member 2 becomes
  `flexi_logger` 0.31.10 with `Criterion::Size(10 MiB)` + `Cleanup::KeepLogFiles(5)`, and member
  1 is dropped.
- assumes `rust-edition` = `2024`.
- assumes `msrv-policy` = `stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (floor 1.96 on 2026-09-26).
- assumes `license` = `MIT OR Apache-2.0`.
- assumes `target-os-matrix` = `ubuntu-latest, macos-latest`.
- Unregistered upstream answers relied on: R57 accepted (`state_dir().join("rslbp.log")`); R54
  assumed to deliver a fully merged config before logging initialization.
- No `CONFLICT:` line. The per-layer-filter requirement is a constraint on R58's design, stated
  here for the controller; it does not change a registered value.

### Migration implications

| File | Change |
|---|---|
| `crates/<cli>/src/logging/rotating.rs` (new) | `RotatingFile` plus unit tests (member 1) |
| `crates/<cli>/src/logging/mod.rs` (R58's) | `file_layer(...)`; build a `Vec<Box<dyn Layer<Registry>>>` of console + optional file |
| `crates/<cli>/src/logging/resolve.rs` or R58's level-resolution module | `resolve_log_file(...)` plus 8 tests (member 3) |
| `crates/<cli>/src/cli.rs` (argument definitions) | `--log-file[=PATH]`, `num_args = 0..=1` |
| R54's config schema module | `[logging] file`, `file-level`, `file-format` (kebab-case) |
| R57's paths module | nothing new: `state_dir()` already exists; `log_file()` is `state_dir().join("rslbp.log")` |
| `Cargo.toml` | no new dependency; ensure `tracing-subscriber` feature `json` |
| docs (config reference, README logging section) | the ladder, the 10 MiB × 5 policy, the file locations |
| Library crate | none |
| Web crate | none |
| Follow-ons (not this repository) | py: rename `[logging] format` → `file-format` and `PLBP_LOG_FORMAT` → `PLBP_LOG_FILE_FORMAT` (BASELINE-REVIEW F260). ts: add an opt-in rotating file sink (A1 is a capability gap) |

### Validation strategy

**Executed** (macOS 26.4 aarch64, rustc 1.98.1 and 1.96.0, working directory
`/tmp/r59-opus/check`, binary `target/release/r59-check <scenario> <dir> [n]`; `src/main.rs`
sha256 `d63c4e25daf9a1ffe1d5b3bc48f672dbd3ba26eef9381efd4799dac8fe28ee7f`):

- §A `floor` → `current=debug`; stderr has only `WARN … warn-event`; the file has
  `DEBUG … debug-event token_len=3` and `WARN … warn-event`. `floor-json` → the file has
  `{"timestamp":…,"level":"DEBUG","fields":{"message":"debug-event","token_len":3},…}`.
  `floor-nofile` → `current=warn`. `global-filter` → `current=debug`, but the file has only
  `warn-event`.
- §B `rotate-*` → the per-file table under `### Principles and implementation`. The owned writer
  gives `rslbp.log` 1,176 B and `.1`-`.5` 4,032 B each, `partial_lines=0`, newest sequence in `.1`.
- §C `exit-*`, three runs each: `bufwriter` 897/897/897; `bufwriter-return` 897/897;
  `unbuffered` 1000×3; `file-rotate` 1000×3; `nonblocking` 133/123/127;
  `nonblocking-return` 1000×3; `owned` 1000×3.
- §D benchmarks: the table under `### Principles and implementation`.
- §E `ansi-default` → `esc_bytes=12`; `ansi-off` → `esc_bytes=0`.
- §F `ctor-fail` → `rolling-file: Err(Os { code: 20, kind: NotADirectory, … })`,
  `tracing-rolling-file: Err(Os { code: 17, kind: AlreadyExists, … })`,
  `logroller: Err(CreateDirectoryFailed(…))`, `file-rotate: panicked=true`,
  `owned RotatingFile: Err(Os { code: 17, kind: AlreadyExists, … })`,
  `file-rotate write to unopenable path: Ok(10)`. `dirgone-owned` →
  `write after dir removed: Err(NotFound)`; `dirgone-file-rotate` → `PANICKED`.
  `rotate-logroller-exit` over three runs → orphan `.pending.N` files and `rslbp.log.6`.
- §G `cargo test --lib` → `test result: ok. 8 passed`.
- §H `rustup run 1.96.0 cargo build --release --target-dir target-196` → `Finished`.

**Planned (not executed):** the same tests as template `#[test]`s in CI on `ubuntu-latest` and
`macos-latest`; AC7 redaction once R58's redaction exists; the binary-level AC1/AC3 tests with
`XDG_STATE_HOME` set; `cargo deny check licenses` (no new licenses are expected, since the stack
adds no crate).

### Confidence & re-verify trigger

Overall confidence: **medium-high**.
- The yes/no decision, CLI-only scope, precedence and floor are high: they are backed by source
  evidence and observed behavior.
- The owned-writer choice is medium: it is an evidence-backed judgment (every crate failed a
  tested contract property), and the owner could prefer the `file-rotate` runner-up.

Re-verify when any of these happens:
- R58's decision lands (especially a registry-level filter or a `log` facade).
- R54's config-key convention is decided.
- tokio-rs/tracing#1940 ships size rotation.
- `file-rotate` or `logroller` fixes the defects recorded here.
- The first template CI run on `ubuntu-latest` completes.

Otherwise re-verify on 2027-03-26.

Gaps recorded:
- No Ubuntu execution.
- Python's `RotatingFileHandler` docs and the Twelve-Factor reference were not retrieved.
- tokio-rs/tracing issue responsiveness could not be computed by `author_association`: 0 of 10
  recent issues had an `OWNER`/`MEMBER`/`COLLABORATOR` reply, while 4 of 10 had some reply. This
  is likely an artifact of private organization membership showing as `CONTRIBUTOR`.
- `rolling-file` responsiveness was not computed (1 open issue; no activity since 2023).

### Sources

All retrieved 2026-09-26 unless stated otherwise.

- crates.io: `https://crates.io/api/v1/crates/<name>` and `/versions` for `tracing`, `tracing-subscriber`, `tracing-appender`, `file-rotate`, `rolling-file`, `tracing-rolling-file`, `logroller`, `flexi_logger`, `log4rs`, `fern`, `spdlog-rs`, `logforth`, `logforth-append-file`, `etcetera`; `/reverse_dependencies` for `file-rotate` (32), `rolling-file` (16), `logroller` (4), `tracing-rolling-file` (4), `tracing-appender` (1,319); `/<version>/download` for the six inspected sources.
- Figures not repeated in the member tables: `log4rs` 1.4.0 (MIT OR Apache-2.0, `rust-version = "1.75"`, 1,939,415 / 23,310,983, last release 2025-09-05; `estk/log4rs` 1,134 stars, 33 open issues, median response 25.9 days with 5/10 unanswered, CI on `ubuntu-latest` + `windows-latest` only); `fern` 0.7.1 (MIT, 1.60, 8,252,512 / 48,696,181, 2024-12-15; 914 stars, 42 open); `spdlog-rs` (170 stars, 8 open, pushed 2026-08-29); `logforth` (238 stars, 4 open, pushed 2026-09-21; `logforth-append-file` 181,593 / 436,925).
- GitHub REST: `https://api.github.com/repos/<o>/<r>`, `search/issues?q=repo:<o>/<r>+is:issue+is:open`, `repos/<o>/<r>/issues?state=all&sort=created` plus per-issue `comments`, `repos/<o>/<r>/contents/...` for the pinned files named above.
- RustSec: `https://rustsec.org/packages/<name>.html` (404 for every candidate except `tracing-subscriber`); `https://rustsec.org/advisories/RUSTSEC-2025-0055.html`.
- Rust: `https://static.rust-lang.org/dist/channel-rust-stable.toml`.
- Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`: `R3.8`, `R4.4`, `R5.3`, `R5.6`.
- py-launch-blueprint @ `b55b8c26364cb0f42e56116e6780921976334751`; ts-launch-blueprint @ `e5100b4f7ec0ad4939f860673c901f3df59a6b18`.
- `research/topics/57-xdg-directory-set/DECISION.md`; `research/topics/58-logging-pipeline-architecture/prompts/logging-pipeline-architecture.prompt.md`; `research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/inputs/*`.
