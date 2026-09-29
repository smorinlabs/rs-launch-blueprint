# 2026-09-27 — R59 — file-log-sink (bundle, Focused) — decision (revision 2)

**Revision note, revision 2.** Revision 1 (sha256
`15211fc070b2a29943b7a4cda6de6bdfae6b58a684dfca78a4c4c5f62c966d79`, preserved byte-identical as
`review/R59-r1-snapshot.md`) was rejected by one judgment audit with three findings. This revision
repairs all three. **The recommendation does not move.** Nothing has been published for R59, and
this revision reverses nothing, so there is no Supersedes section.

| Finding | What revision 1 said | Repair in revision 2 |
|---|---|---|
| JF-4 | One workload (4,096-byte limit, 78-byte records) was stated for all of W01–W29. The directory-removed rows then claimed `Err(NotFound)` "on every write" and a self-heal contrast without saying they ran at a 64-byte limit, where rotation comes on the first or second write | The limit is stated per row group, with its `src/main.rs` line. The directory rows, the "why the owned writer wins" list, member 2's `log_internal_errors` item, AC8, D1 and D10 are narrowed: at the recommended 10 MiB, a write after the directory is removed returns `Ok` into the unlinked file for **both** writers until the next rotation, and nothing is reported on stderr until then. A sentence states why D1 still holds. Gap 12 records that this 10 MiB behavior is argued from source, not probed |
| JF-8 | Member 2 gate 6: "17 packages" | "15 packages, `tracing-subscriber` itself included": 17 `cargo tree` lines, two of them `(*)` repeats. This is the same counting as `file-rotate`'s 11. D8 records Opus's "18" |
| JF-2 | Member 2 had no crate figures and no maintenance state | Crate figures from `r59-live-figures.log:13, 28`, a rubric maintenance state (`stable-quiet`) with its reasoning, and the missing tokio-rs/tracing responsiveness sample recorded as gap 11 |

No evidence script or log changed in revision 2, and no check was rerun: every line revision 1
cited is where it was. The rejecting audit's observations were not findings and are not acted on
here.

**Revision 1's note, unchanged in substance.** Revision 1 was the first decision for R59. It is a
fresh synthesis of the two raw reports in this run. The synthesizer wrote neither report and ran
neither report's checks. Every behavioral claim that decides the recommendation was re-derived here
from code the synthesizer wrote and ran (`review/evidence/`), not carried from either raw.

**Status: conditional, and not acceptable until R58 lands.** R59 consumes R58's
`logging-pipeline-contract` (`inputs/prompt.md:21`). That parameter's registered value is `—`
(`inputs/PARAMETERS.md:18`), and the run's prerequisite snapshot records R58 as
`"decision": "missing"` (`inputs/prerequisites.json:2-4`). This decision is therefore written
against a stated assumption about R58 (`## Parameters`), with a named fallback branch. The
controller must re-check that assumption against R58's accepted decision before accepting this one.

Actor `synth-opus-2026-09-26T190256Z-4c0fef2a9f93`, model `claude-opus-5-5`, item kind `bundle`,
effort tier `focused` (two engines, no Doxa).

**Inputs synthesized.**

| Leg | File | sha256 | Shape check (`scripts/check-answer-shape.sh <file> bundle`) |
|---|---|---|---|
| Muse (Meta) | `raw/muse.md` (214 lines) | `45adfc0f0d7c6b4bfcc3ec218f0d967ac22dc992d04a11a048649e61062d2cba` | `OK: validation passed` |
| Claude Opus (`claude-opus-5-5`) | `raw/opus.md` (814 lines) | `fe6ad358b5bad84ae6737acaacad4eaa0adfee9b356075e30fe55137e2bbb1d2` | `OK: validation passed` |

**Retrieval dates.** Both raws date their figures **2026-09-26**. Every check this synthesis ran
executed between 02:48 and 02:49 UTC on **2026-09-27** (the `run (UTC)` line of each log), which
is still 2026-09-26 on the owner's Pacific calendar. Live figures below carry the 2026-09-27 UTC
date of `review/evidence/r59-live-figures.log:5`.

**Fitness gate 1 (licence) is reported as metadata only.** R53's published decision records an
owner ruling of 2026-09-12 (Q7.B) that makes the licence gate inapplicable for anything the
template uses (`research/topics/53-config-schema-validation/DECISION.md:45-49`). The ruling's
primary record, `docs/port/OWNER-REVIEW.md`, is outside this synthesis's read set. No candidate
below is excluded on licence. Opus's qualified gate-1 note on `logforth-append-file`
(`raw/opus.md:367-371`) is therefore not an exclusion ground; that candidate stays excluded on
gate 5 alone.

**Read set.** This synthesis read `research/RUNBOOK.md`, the item prompt, this run's `inputs/`,
`manifest.json` and both raws in full. It read R53's and R64's published decisions only for
their shape. It also read the published crate sources that `cargo` fetched for the probe. It did
**not** read py or ts source, R57's decision, the org CLI Design Standard, or R58's prompt. Opus
read all four (`raw/opus.md:16-21`). Every claim that rests on them is marked **carried** below
and cited to the raw line, never to the unread file.

## Decision

**This decision is a proposal validated in the implementation phase.** It records what the
research found and what it recommends. P03 builds the template, and its CI proves or overturns the
recommendation. No Rust source exists in this repository. The only Rust this synthesis compiled is
the probe crate under `review/evidence/r59-check/`. It is evidence, not template code.

> **Yes: ship an optional rotating file log sink. It is off by default and exists on the CLI
> binary only.** The stack has three members:
>
> 1. **Rotating writer — a template-owned `RotatingFile`, std only (61 lines of code in the
>    probe's `src/lib.rs`, excluding comments, blank lines and tests).** Size-triggered rotation before a write that would reach
>    `ROTATE_MAX_BYTES = 10 * 1024 * 1024`, with `ROTATE_BACKUP_COUNT = 5` backups and `.1` as the
>    newest. Writes are unbuffered. Every I/O failure is returned as `io::Result`, never a panic.
>    The parent directory is created with mode `0o700` on Unix. No new crate dependency.
> 2. **Second sink layer — `tracing-subscriber` `=0.3.23`, a second `fmt::Layer`.** It carries a
>    per-layer `LevelFilter` from the file level (default `debug`), `.with_ansi(false)`,
>    **`.log_internal_errors(true)`**, text by default or `.json()` on request, and the writer
>    `Mutex<RotatingFile>`. It is **blocking**: no `tracing_appender::non_blocking` wrapper.
>    It enters the subscriber as an `Option` inside a `Vec<Box<dyn Layer<Registry> + Send + Sync>>`
>    beside R58's console layer.
> 3. **Enablement — a pure resolver `resolve_log_file(flag, env, config, default_path)`.** The
>    precedence is flag > env > config > off. `--log-file` takes an optional value; a bare flag, or
>    an env value that is present but empty, selects the default path. The config keys are
>    `[logging] file`, `file-level` and `file-format`. The subscriber is built **once, after
>    configuration is fully resolved**.
>
> **Ranked runner-up for member 1:** `file-rotate` `=0.8.0` with
> `ContentLimit::BytesSurpassed(ROTATE_MAX_BYTES)` and `AppendCount::new(5)`. It is only
> acceptable behind a constructor that pre-creates the directory and probes the open. Even then it
> keeps two runtime panics that no wrapper can fence without `catch_unwind` (member 1, below).
> **Fallback if R58 selects a `log`-facade pipeline instead of `tracing`:** members 1 and 2 are
> replaced by `flexi_logger` `0.31.10` (`Criterion::Size` plus `Cleanup::KeepLogFiles(5)`), whose
> rotation was tested by neither leg nor this synthesis. Member 3 is unchanged.

**The prompt's questions, answered.**

| Prompt question (`inputs/prompt.md`) | Answer | Evidence |
|---|---|---|
| Decision (`:31`): ship a file sink at all? | Yes, opt-in, CLI binary only | Both legs say yes (`raw/muse.md:41`, `raw/opus.md:98-102`); surface settled in `## Engines` D2 |
| HIGH (`:32`): does R58's crate already rotate by size? | If R58 selects `tracing`, **no**: `tracing-appender` 0.2.5 rotates by time only. A separate component is needed | `Rotation` has exactly five kinds, `MINUTELY` to `NEVER` (S15), and no size identifier (S16). tokio-rs/tracing#1940 and #858, the size-rotation requests, are open (L13, L14) |
| HIGH (`:33`): size + backup-count candidates | Surveyed below under `### Landscape` and the member-1 tables | S, W, L checks |
| HIGH (`:34`): principles and agreement levels across py, ts, rs | Under `### Principles and implementation` | — |
| MEDIUM (`:35`): initialization order | One subscriber construction, after config resolution; pre-initialization failures go to stderr through R67's error path | `## Engines` D4 |
| MEDIUM (`:36`): shape of py's `min(level, file_level)` floor | Automatic with per-layer filters; **no computation**. Requires R58's console level to be a per-layer filter too | A01–A09 |
| LOW (`:37`): Rust default for 10 MiB × 5? | No Rust crate imposes one; keep py's 10 MiB × 5 as template constants | `## Engines` D9 |

**Settled ledger rows** (all origin `py-only`, verdict `DIVERGENT`, item R59, per
`inputs/prompt.md:8`):

| Row | py behavior (per the prompt) | rs disposition |
|---|---|---|
| F255 | `LoggingSettings` has `level`, `file`, `file_level`, `format` | `[logging]` gains `file`, `file-level`, `file-format`. `level` and `format` stay R58's. **Key naming is subject to BASELINE-REVIEW F260**, forwarded below |
| F256 | `RotatingFileHandler(maxBytes, backupCount)` | Member 1, `RotatingFile`: same pre-write trigger and the same `.N` naming |
| F257 | 10 MiB, 5 backups | Same numbers, as constants, not settings |
| F258 | `--log-file` flag and env | `--log-file[=PATH]` plus an env var. The env prefix is unregistered; see `## Parameters` |
| F259 | flag/env > config `logging.file` > off | `resolve_log_file`, 8 executed cases (G02) |
| F260 | Independently settable file format, overridable by env | Member 2 builds its own formatter. BASELINE-REVIEW F260 (Opus) is forwarded unadjudicated |
| F261 | `root.setLevel(min(level, file_level))` | Structural: per-layer filters make the global maximum the most verbose sink level (A01, A05) |

### Landscape

The category is a size-bounded, backup-count-capped file destination for diagnostic events. It is
attached as a second sink to the process's structured logging pipeline. The Rust field, merged
from both legs and checked where marked:

| Bin | Candidate | Size + count? | Status here |
|---|---|---|---|
| First-party / built-in | `std::fs` | Building blocks only | The owned writer uses only `std` (P05) |
| First-party | `tracing-appender` 0.2.5 (tokio-rs) | **No**: time-only (S15, S16) | Fails the requirement, not a gate |
| First-party | `tracing-subscriber` 0.3.23 per-layer-filtered `fmt::Layer` | Not a rotator: the composition mechanism | Member 2 |
| Established | `file-rotate` 0.8.0 | Yes (`BytesSurpassed` + `AppendCount`) | Runner-up; defects W12–W25 |
| Established | `rolling-file` 0.2.0 | Yes | Excluded, gate 4 (L08) |
| Established | `flexi_logger` 0.31.10, `log4rs` 1.4.0 | Yes, inside a whole `log` backend | `flexi_logger` = `log`-facade fallback; `log4rs` excluded, gate 4 (L09) |
| Established | `fern` 0.7.1, `simplelog` 0.12.2 | No | Fail the requirement (carried from both legs) |
| Up-and-comer | `logroller` 0.1.12 | Yes, pre-write trigger | Watch item (carried defect, see member 1) |
| Up-and-comer | `tracing-rolling-file` 0.1.3 | Yes | Shortlisted third. It is a fork of `rolling-file`: its README says "based on [rolling-file]" (L12) |
| Up-and-comer | `logforth-append-file` 0.4.0, `spdlog-rs` 0.5.3 | Yes | `log`-facade or own framework; R58-level choices (carried from `raw/opus.md:60-61, 367-371, 383-385`) |

**Authorities.** Maintainers' published source at the pinned versions (the S check prints every
matched line). The crates.io API and GitHub REST for adoption and maintenance (L). The RustSec
Advisory Database, maintained by the Rust Secure Code Working Group (L-rs, L16). The tokio-rs
tracker for the first-party gap (L13, L14).

**Practice evidence (carried, not re-derived; the repositories are outside this synthesis's
read set).** Opus pins these adopters at commits (`raw/opus.md:83-88`):

- rust-analyzer offers an opt-in `--log-file`.
- Helix defaults to a log file with no rotation.
- Zed hand-rolls size rotation: 1 MiB, one backup.
- czkawka uses `file-rotate`, under the `log` facade.
- The Dragonfly client composes a size-rotating writer under a `tracing-subscriber` `fmt` layer
  with `.with_ansi(false)`. This is the same layer shape as member 2.

Muse cites czkawka, oura, zellij (`log4rs`) and qsv (`flexi_logger`) (`raw/muse.md:15`). **What
the survey supports:** opt-in log files are normal in well-regarded Rust CLI and editor tools.
Size rotation is split between hand-rolled code and `file-rotate`/`rolling-file`. No surveyed
project uses `tracing-appender` for size rotation, because it cannot rotate by size.

### Members

#### Member 1 — rotating writer (F256, F257): template-owned `RotatingFile`

**Contract it must meet.** It must meet B4, B8 and B9 from `### Principles and implementation`:

- **B4** — bounded disk use and whole records.
- **B8** — never panic; a failure is reported.
- **B9** — records are on disk at exit.

**Tested against the contract** (`r59-writer-contract.log`, checks W01–W29, plus C01–C04). Every
probe keeps 5 backups. **The size limit differs by row group** (probe `src/main.rs`):

| Rows | Probe mode | Limit | Writes | Source line |
|---|---|---|---|---|
| W01–W10 | `rotate` | 4,096 B | 400 fixed-length 78-byte records | `src/main.rs:123` |
| W11–W13 | `ctor-fail` | 4,096 B | none: construction only | `src/main.rs:214, 219` |
| W14–W16 | `unopenable` | 4,096 B | owned: open only; `file-rotate`: one 10-byte write | `src/main.rs:226, 230` |
| W17–W21 | `dirgone` | **64 B** | a 9-byte write, directory removed, then three 80-byte writes | `src/main.rs:240` |
| W22–W25 | `shared` | **400 B** | 60 records, alternating between two writers | `src/main.rs:275-276` |
| W26–W29 | `report` | **64 B** | one event, directory removed, then two events | `src/main.rs:260` |
| C01–C04 | `exit` | 10 MiB | 1,000 records | `src/main.rs:190, 198` |

At 64 B, the owned writer reaches its rotation path on every write after the directory is removed
(9 + 80 ≥ 64). `file-rotate` `BytesSurpassed` does not rotate on write[0] (a count of 9 is not
above 64); it rotates on write[1] and write[2]. The W17–W21 and W26–W29 results therefore show
behavior **at rotation time**, not on every write at every limit. The paragraph after the table
says what happens at the recommended 10 MiB.

| Property | Owned `RotatingFile` | `file-rotate` `Bytes` | `file-rotate` `BytesSurpassed` |
|---|---|---|---|
| Layout: base + `.1`…`.5`, no `.6` | yes (W01) | yes | yes (W07) |
| Whole records only | yes, 0 partial (W02) | **no: records torn across files** (W06) | yes (W08) |
| Every file ≤ limit | yes, 4,056 B (W03) | yes | over by at most one record, 4,134 B (W09) |
| `.1` newest | yes (W04, W05) | — | yes (W10) |
| Parent directory cannot be created | `Err(NotADirectory)` (W11) | — | **panics** at `src/lib.rs:425` `expect("create dir")` (W12, W13, S01) |
| Log path unopenable | `Err(IsADirectory)` (W14) | — | **`write` returns `Ok(10)` and writes nothing** (W15, W16; S03, S07) |
| Directory removed mid-run, recreatable (64 B limit, so at rotation time) | from the first rotation attempt, `Err(NotFound)` on every write until restart; no panic (W17) | — | **self-heals at rotation**: 3 × `Ok(80)` (W19). write[0] went into the unlinked file before any rotation; write[1] and write[2] followed the rotation that recreated the directory |
| Directory replaced by a file mid-run (64 B limit, so at rotation time) | `Err(NotADirectory)`, no panic (W18) | — | **panics at rotation** at `src/lib.rs:553` `assert!(old_path.exists())` (W20, W21, S04) |
| Two writers share one path (two concurrent CLI runs; 400 B limit) | no panic, no error, no torn record (W22, W23) | — | **panics at rotation** at `src/lib.rs:554` `assert!(!new_path.exists())` (W24, W25, S05) |
| 1,000 records, then `process::exit(0)` | 1000/1000 × 3 runs (C01) | — | 1000/1000 × 3 runs (C02) |
| Added packages | 0 (P05) | 10 beyond itself (P02); 9 of them are not already in `tracing-subscriber`'s set, `flate2` among them and always compiled (P03, P04) | same |
| `unsafe` | 0 (S22) | 0 (S08) | same |

**What the directory rows mean at the recommended 10 MiB.** The W17–W21 probes wrote 80 bytes
into a 64-byte limit, so each write after the directory was removed triggered a rotation. At a
realistic limit, most writes do not:

- **Owned writer.** A write rotates only when `size + len >= max_bytes` (probe `src/lib.rs:63`).
  Below that, the write goes to the still-open descriptor of the unlinked file and returns `Ok`.
  At the next rotation, `rotate` first drops the descriptor (`src/lib.rs:46`), and the base
  rename then fails with `NotFound` (`src/lib.rs:53`). `size` is not reset on that path, so every
  later write retries the rotation and returns `Err(NotFound)` until the process restarts.
- **`file-rotate` `BytesSurpassed`.** A write rotates only once the byte count exceeds the limit
  (`src/lib.rs:707`, S06, `r59-source-reads.log:17`). Below that, it also writes into the unlinked
  file and returns `Ok`. This is observed, not only read: in both `file-rotate` `dirgone` runs,
  write[0] came before any rotation and returned `Ok(80)` (`r59-writer-contract.log:90`, `:96`).
  At rotation, `ensure_log_directory_exists` recreates the directory
  (`src/lib.rs:446`, S02, `r59-source-reads.log:9`). That call is the self-heal W19 shows. When a
  file blocks the directory instead, the directory check passes on the file, and the rename step's
  `assert!(old_path.exists())` panics (`src/lib.rs:553`, S04, W20, W21).

So the two writers behave the same between the removal and the next rotation: records are written
into an unlinked file, and are lost without an error. They diverge only at rotation. No probe ran
at 10 MiB. The pre-rotation `Ok` is observed for `file-rotate` (at 64 B) and read from source for
the owned writer, whose probe reached rotation on its first write (gap 12).

**Why the owned writer wins.** It is the only tested writer that meets B4, B8 and B9 together in
every probed row.
`file-rotate` breaks B8 in four ways, each reproduced in this synthesis:

- a constructor panic (at open, whatever the limit);
- a silent `Ok` for bytes it dropped (at open, whatever the limit);
- a panic at rotation when the log directory has become uncreatable mid-run;
- a panic at rotation when two writers share one file.

The last case is the ordinary situation of two overlapping CLI invocations. It was modeled
in-process with two independent `FileRotate` instances. Each instance keeps its own suffix set,
exactly as two processes would. It was not run as two OS processes. A constructor wrapper fences
only the first two defects.

**Why D1 survives the narrower directory rows.** W12 and W15 happen at open, so they do not depend
on the limit. W20 and W24 happen at rotation, and a sink that is bounded by size rotates at any
limit; a larger limit only makes the panic later. None of the three rests on the 64-byte workload's
"every write" framing.

The owned writer's one weakness found here is the opposite of `file-rotate`'s one strength. After a
directory removal, at its next rotation it starts returning `Err(NotFound)` and keeps doing so until
the process restarts. At the same point, `file-rotate` recreates the directory (W17 versus W19). For
a short-lived CLI, the next invocation recreates the directory at `open`. The same limitation is
carried, not checked, for py's handler (`raw/opus.md:415-417` records py's multi-process
limitation; py's directory behavior was not read here).

**Shortlist and gates.**

| Candidate | Gate 2 (MSRV) | Gate 3 (advisories; `unsafe`) | Gate 4 (ubuntu + macOS CI) | Gate 5 (features; async) | Gate 6 (cost) | Maintenance |
|---|---|---|---|---|---|---|
| Owned `RotatingFile` | std only; built and tested on 1.96.0 (H02, H03) | n/a; 0 `unsafe` (S22) | the template's own CI (planned) | none; none | 0 packages | owned by the template |
| `file-rotate` 0.8.0 (MIT) | no `rust-version` declared (S09); builds on 1.96.0 (H02) | none, RustSec 404 (L-rs); 0 `unsafe` (S08) | `rust.yml` covers macOS, ubuntu, windows (L07) | no features table; no async coupling | 11 packages incl. itself; `flate2` always compiled (P02, P03) | `stable-quiet`: last release 0.8.0 on 2025-02-27; 41 stars; 9 open issues; 7 of the 10 newest issues answered, median 1.9 days, 3 unanswered (`r59-live-figures.log:65`) |
| `tracing-rolling-file` 0.1.3 (MIT/Apache-2.0) | no `rust-version` declared (L) | none (L-rs) | macOS included (L10) | optional `non-blocking` | carried: 5 unique normal deps (`raw/opus.md:171`) | `stable-quiet`: 0.1.3 on 2025-08-16; 0 open issues; 12 stars |
| `logroller` 0.1.12 (MIT) | `rust_version=1.71` (L) | none (L-rs) | macOS job present (L11) | optional `tracing` feature | carried: 38 with `tracing` (`raw/opus.md:172`) | `active`: 0.1.12 on 2026-07-01 |

**Excluded by gate.**

- `rolling-file` 0.2.0 fails **gate 4**. Its only workflow runs `ubuntu-18.04, windows-latest`
  (L08). macOS is never tested, and `ubuntu-18.04` is a retired runner image. The last push was
  2023-02-24 (L). Muse did not survey this crate. Opus did (`raw/opus.md:358-366`).
- `log4rs` 1.4.0 fails **gate 4**. `main.yml` runs `ubuntu-latest, windows-latest` only (L09).
  Both legs agree (`raw/muse.md:67`, `raw/opus.md:808`).
- `logforth-append-file` 0.4.0 fails **gate 5**. It is coupled to the `log` facade through
  `logforth-core` (carried, `raw/opus.md:367-371`).
- `tracing-appender` 0.2.5, `fern` 0.7.1 and `simplelog` 0.12.2 fail the **requirement**, not a
  gate: they cannot rotate by size (S15, S16; carried for `fern`/`simplelog`).

**Up-and-comers.** `logroller` is the most promising: it is active, it declares an MSRV, and it
uses py's pre-write trigger. Opus observed that its size-based archive shift runs on a background
thread. An immediate `exit` then leaves a `.6` backup and orphan `.pending.N` files that
accumulate across runs (`raw/opus.md:172-173`). **That observation is carried, not re-derived
here.** It is the promotion trigger: `logroller` becomes viable once the shift is synchronous or
startup reconciles `.pending.N` files.

**Ranked runner-up.** `file-rotate` 0.8.0 with `BytesSurpassed`, never `Bytes` (W06). The
template must wrap construction: create the directory with `0o700`, then probe
`OpenOptions::new().append(true).create(true).open(path)`. That removes W12 and W15. W20 and W24
remain. Third: `tracing-rolling-file` 0.1.3 plus a flush-on-drop `MakeWriter`. Its lack of a
buffer-capacity option is carried from `raw/opus.md:171, 352`.

**Tradeoffs.** The owned writer lacks compression and time-based rotation; neither is required.
The template owns about 60 lines of code plus their tests. It adds nothing to the dependency tree for a feature
that is off by default. Performance does not discriminate: see D8 in `## Engines`.

**Confidence.** High that the behavior is correct: every row above was observed, at the limit its
row group states. The 10 MiB behavior of the directory rows is read from source, not observed
(gap 12). Medium that owned
code is preferable to a dependency. That is a judgment the owner may reverse by choosing the
runner-up with its two residual panics documented.

#### Member 2 — second sink layer (F260, F261): `tracing-subscriber` 0.3.23 `fmt::Layer`

**Landscape.** Under `tracing`, the native way to add a destination is another `Layer` on the
`Registry`. The alternative is a single layer with a tee writer (`MakeWriterExt::and`). It passes
every gate but loses the independent level and format (carried, `raw/opus.md:464-466, 501`).

**Crate figures** (`r59-live-figures.log:13, 28`, retrieved 2026-09-27 UTC):

- crates.io: 146,641,301 recent (90-day) downloads; 627,181,762 all-time; newest release 0.3.23 on
  2026-03-13; licence MIT; `rust_version` 1.65.0.
- Repository `tokio-rs/tracing`: 6,891 stars, not archived, last push 2026-05-30, 628 open issues.
- Opus's 90-day figure, 147,886,240 (`raw/opus.md:486`), is an earlier retrieval of the same
  counter; the stars, open issues, release and all-time figures agree (`raw/opus.md:486-489`).
- Issue responsiveness: **not sampled**. `r59-live-figures.log` samples only `file-rotate`, and
  neither leg gives a tokio-rs/tracing sample. Recorded as gap 11.

**Maintenance state: `stable-quiet`.** The rubric (`inputs/prompt.md:60`) treats "no release in 6
months" as a trigger to investigate, never as the verdict. The trigger fires: 0.3.23 is 198 days old
at retrieval. The investigation found:

- the same repository released `tracing-appender` 0.2.5 on 2026-04-17 (`r59-live-figures.log:12`);
- the repository was last pushed 120 days before retrieval, and it is not archived (`:28`);
- RUSTSEC-2025-0055, the advisory gate 3 cites, is patched from 0.3.20, below the pin (L16).

That is quiet but maintained, with no concrete signal for `at-risk`. `active` is not claimed,
because nothing here shows recent work on `tracing-subscriber` itself, and no responsiveness sample
exists. The state does not affect the recommendation: R58 selects the pipeline crate, and member 2
only adds a second layer of it.

**Gates.**

- Gate 2: `rust-version` 1.65.0 (S14). The probe builds on 1.96.0 (H02).
- Gate 3: RUSTSEC-2025-0055 (ANSI escape injection) is patched from 0.3.20 (L16). 0.3.23 is the
  newest release (L02). User-supplied escape bytes are written as escaped text (E03).
- `unsafe`: 26 lines containing `unsafe`, 28 tokens, in 6 files — `reload.rs`, `fmt/mod.rs`,
  `fmt/fmt_layer.rs`, `layer/layered.rs`, `layer/mod.rs`, `filter/layer_filters/mod.rs`
  (S18–S20). Opus's "26 `unsafe` tokens" (`raw/opus.md:496`) is 26 lines; some lines hold two.
- Gate 4: tokio-rs CI (carried from both legs).
- Gate 5: this member needs the features `fmt`, `std`, `registry` and `json`, plus `ansi` for the
  console. There is no async coupling.
- Gate 6: 15 packages with those features, `tracing-subscriber` itself included, a cost R58 pays in
  any case. `r59-deps.log:20-36` lists 17 lines, but two are `cargo tree` `(*)` repeats of packages
  already listed (`serde` at `:27`, `tracing-core` at `:33`). This counts unique packages, as
  `file-rotate`'s 11 does (P02).

**Three settings the file layer must carry, each observed:**

1. **Per-layer `LevelFilter`** (A01–A05). With the console at `warn` and the file at `debug`:
   - `LevelFilter::current()` is `debug`;
   - the file receives both events, and the console receives only `warn`;
   - without the file layer, `current` is `warn`, so the cost of a disabled event is unchanged.
2. **`.with_ansi(false)`.** A default `fmt::layer()` wrote **12 escape bytes** into the file,
   because the `ansi` feature is on and `NO_COLOR` was unset (E01, S13). `.with_ansi(false)`
   wrote **0** (E02).
3. **`.log_internal_errors(true)` — new in this synthesis; neither leg found it.** In 0.3.23,
   `fmt::Layer::default()` sets `log_internal_errors: false` (`fmt_layer.rs:752`, S10). The
   setter's doc comment nonetheless says "Defaults to true" (`:362`, S11). A writer error is
   printed only when the flag is set (`:1051`, S12). Observed: with the default, a failing file
   writer loses events **silently** (W26, W27). With `.log_internal_errors(true)`, each lost
   event prints `[tracing-subscriber] Unable to write an event to the Writer for this Subscriber!
   Error: …` to stderr, and the program exits 0 (W28, W29). Opus's claim that the `fmt` layer
   reports writer errors on stderr (`raw/opus.md:329-331`) is **false at the default**. B8's
   "reported on stderr" holds only with this setting.
   **Scope of W26–W29.** They ran at a 64-byte limit (`src/main.rs:260`), so each event after the
   directory removal forced a rotation, and the writer returned `Err`. The setting reports a
   writer's `Err`; it cannot report a write that succeeds. At 10 MiB, events after a directory
   removal return `Ok` into the unlinked file until the next rotation (member 1), so nothing is
   printed until that rotation fails. From then on, each lost event is reported.

**Blocking, not `non_blocking`.** With `tracing_appender::non_blocking` (`lossy(false)`) and the
`WorkerGuard` alive at `process::exit(0)`, the file held **48, 0 and 182** of 1,000 records in
three runs (C03). When `main` dropped the guard and returned, all 1,000 records survived (C04).
R67's accepted contract says `main` returns `ExitCode` without `process::exit` on the error path.
It also requires "all streams are flushed before exit on every path including signal"
(`inputs/PARAMETERS.md:16`). The unbuffered blocking writer meets that requirement structurally,
with no guard to thread through R67's signal paths (C01).

**Ranked runner-up.** None within `tracing`. `flexi_logger` applies only if R58 goes `log`-facade.

**Tradeoffs.** When both sinks are enabled, two `fmt` layers format each event twice. That is the
price of independent formats.

#### Member 3 — enablement and precedence (F255, F258, F259): a pattern, not a crate

Crate figures are inapplicable: no crate is chosen. The argument parser is R60's, and the config
loader is R54's.

**The resolver**, executed as 8 unit tests on 1.98.1 (G01–G03) and 1.96.0 (H03). The source is
`review/evidence/r59-check/src/lib.rs`, `resolve_log_file`, written by this synthesis. The rules
are those of `raw/opus.md:599-608`:

| Input | Result | Test |
|---|---|---|
| nothing | off | P1 |
| config `file = "/c.log"` | `/c.log` | P2 |
| config `file = ""` | off | P3 |
| env `/e.log` + config `/c.log` | `/e.log` | P4 |
| env set but empty + config | default path | P5 |
| flag `/f.log` + env | `/f.log` | P6 |
| bare flag + env | default path | P7 |
| bare flag, no State directory resolvable | off | P8 |

The env var is read by the resolver itself rather than through the parser's env binding. That
keeps the "present but empty selects the default" rule explicit and testable
(`raw/opus.md:610-611`). The rule itself is carried from py via `raw/opus.md:605`; py was not read
here.

**Default path.** Opus reports R57's accepted default as `state_dir().join("rslbp.log")`
(`raw/opus.md:34-36`). **That is carried, not verified**: R57 is outside this synthesis's read set,
and the prompt tells this item to treat R57 as open (`inputs/prompt.md:15, 27`). The fallback holds
either way. `default_path` returns `None` when no State directory is resolvable. A bare flag is
then off with a stderr warning, and an explicit path still works (P8).

**An explicitly requested path that cannot be opened at startup.** The binary prints a stderr
warning and runs the command without the file sink, with its exit status unchanged. An *invalid value*
remains a config error, never a silent fallback: for example, an unknown `file-format` string.
This is adjudicated in `## Engines`, D6.

**Shortlist.** The runner-up is letting R54 map the env var into `logging.file` inside its env
tier. That is equivalent, but it cannot express "bare flag" or "empty env selects the default"
without special cases in R54 (`raw/opus.md:626-628`).

### Principles and implementation

**Shared requirement.** A CLI user can opt in to a persistent, bounded, independently leveled
diagnostic record of invocations, stored in the per-user State location. It must not change the
stdout/stderr contract, and it must not contain what redaction removes from the console.

**Agreement levels.**

- **Capability + policy** (py F255–F261, `inputs/prompt.md:8`): the sink exists, it is opt-in,
  its enablement precedence is fixed, and its disk use is bounded.
- **Policy** (owner direction 2026-09-04, `inputs/prompt.md:11`): best-in-class logging practice
  is applied across py, ts and rs.
- The org CLI Design Standard rules R5.3 (logs under State), R3.8 (flag/env/config name parity)
  and R5.6 (secrets masked in logs) are **carried** from `raw/opus.md:111-117`. The standard was
  not read here.

**Must agree across the three repositories** (B1–B9, after `raw/opus.md:121-131`):

- B1: the sink is opt-in and off by default.
- B2: the precedence is flag > env > config > off.
- B3: a bare flag selects the State default.
- B4: size-triggered rotation with a fixed backup count, `.1` newest.
- B5: an independent level; no sink filters out an event another sink wants.
- B6: an independent format, with no terminal escape bytes in the file.
- B7: the same redaction as the console.
- B8: a logging failure never crashes the program and is reported on stderr.
- B9: records emitted before exit are on disk after exit.

**May vary:** the default size and count, the env prefix, an overshoot of one record, the
mechanism, and surfaces other than the CLI.

**Acceptance criteria and their status here.**

| AC | Criterion | Status |
|---|---|---|
| AC1 | No flag, env or config ⇒ no file is created | Resolver P1 plus A06 (no file when the layer is absent). **Planned:** a binary-level test |
| AC2 | The precedence table holds | Executed, G02 and H03 |
| AC3 | A bare flag writes `<state>/rslbp/rslbp.log` | **Planned** (needs R57's path and the binary) |
| AC4 | Overflow yields base + `.1`…`.5`, no `.6`, `.1` newest, whole records | Executed, W01–W05 |
| AC5 | Console `warn` + file `debug`: `debug` lands in the file only; `current` is `debug`, or `warn` without the file | Executed, A01–A05 |
| AC6 | Zero `0x1b` bytes in the file; `json` yields one object per line | Executed, E02 and A10 |
| AC7 | A masked field is masked in the file | **Not executable until R58 defines redaction** |
| AC8 | An unusable path yields a stderr diagnostic, no panic, exit status unchanged | Writer level executed: W11 and W14 at open; W17, W18 and W26–W29 at rotation time (64-byte limit). A directory removed mid-run is diagnosed only from the next rotation (member 1). **Planned:** the binary-level warn-and-continue branch |
| AC9 | 1,000 records then `exit` ⇒ 1,000 lines on disk | Executed, C01 |

**Architectural alternatives, compared before libraries** (both legs agree on the verdicts):

| Alternative | Verdict | Reason |
|---|---|---|
| No file sink (ts); users redirect `2>>file` | Rejected | Loses B3–B6. A debug-level file would force debug on the console. ts's omission is a **missing capability**, not a justified ecosystem difference (`raw/muse.md:23`, `raw/opus.md:154`) |
| Opt-in CLI file sink (py) | **Recommended** | Preserves B1–B9 |
| File sink on the web surface too | Rejected for R59 | See D2. R69's accepted contract leaves no place for a `--log-file` flag on the serve binary |
| File sink always on | Rejected | A CLI in a CI container may have a read-only home, and writing on every run without consent is surprising (`raw/opus.md:157`) |
| Second full `log` backend beside the `tracing` pipeline | Rejected | It duplicates configuration and filtering and splits ownership with R58 (`raw/muse.md:25`) |
| `tracing-appender` time rotation | Rejected | It cannot express the size-and-count bound (S15, S16) |

**The composition, in the template's form.** The `Vec<Box<dyn Layer<Registry> + Send + Sync>>`
form with an `Option` file layer was executed (A01–A05, `src/main.rs` `floor per-layer`). The
`.json()` branch was executed separately (A10), and `.log_internal_errors(true)` was executed on a
non-optional layer (W28, W29). The combined form below is **proposed**, not executed as one piece:

```rust
// Binary crate only; the library crate never installs a subscriber and writes no file
// (R67 layering, inputs/PARAMETERS.md:16).
let file: Option<Box<dyn Layer<Registry> + Send + Sync>> = match log_file_path {
    None => None,
    Some(p) => match RotatingFile::open(&p, ROTATE_MAX_BYTES, ROTATE_BACKUP_COUNT) {
        Err(e) => { eprintln!("warning: log file {}: {e}", p.display()); None } // D6: RSLB101 exception
        Ok(w) => {
            let l = fmt::layer().with_writer(Mutex::new(w)).with_ansi(false).log_internal_errors(true);
            Some(match file_format {
                FileFormat::Text => l.with_filter(file_level).boxed(),
                FileFormat::Json => l.json().with_filter(file_level).boxed(),
            })
        }
    },
};
let layers: Vec<Box<dyn Layer<Registry> + Send + Sync>> =
    std::iter::once(console_layer).chain(file).collect();         // console_layer: R58's, per-layer filtered
// try_init fails only if a global subscriber is already set: a programming error, not a user path.
Registry::default().with(layers).try_init().expect("subscriber installed once, in main");
```

**The floor is a rule, not a computation.** With per-layer filters, `tracing-subscriber` sets the
global maximum to the most verbose layer filter (A01, A05). A registry-level
`LevelFilter::WARN` added beside them still reports `current=debug`, but the file **loses** the
debug event (A07–A09). The idiomatic Rust shape of py's `min(level, file_level)` is therefore that
every level control, R58's console level included, is a per-layer filter. This is recorded as a
constraint on R58 under `## Parameters`. **Carried, not checked:** `tracing`'s compile-time
`max_level_*` / `release_max_level_*` features cap every sink, so the template must not enable one
below `debug` (`raw/opus.md:221-223`).

**Initialization order.** The steps run in this order:

1. Parse the arguments.
2. R54 discovers and merges the config.
3. Resolve the console level (R58) and the file path (member 3).
4. Build one subscriber and call `try_init()` once.

Config-discovery problems cannot reach the file; they print to stderr through R67's error path.
A `tracing_subscriber::reload` handle, which would allow console-first then file-later
initialization, is the ranked alternative. It should be taken only if R58 needs logging before
config discovery. Neither leg nor this synthesis evaluated it.

**Representative performance** (`r59-bench.log:8-19`). The workload is 100,000 `info!` events with
two fields, text format, one file layer, a release build and a 10 MiB limit, on an Apple M4 Pro
with APFS, 3 runs each:

| Writer | Emit ms per 100,000 events (3 runs) | Total ms |
|---|---|---|
| Owned `RotatingFile`, blocking | 195 / 198 / 322 | same |
| `file-rotate` `BytesSurpassed`, blocking | 200 / 192 / 193 | same |
| Owned + `non_blocking` (`lossy(false)`) | 46 / 46 / 46 | 152 / 149 / 149 |

That is about 2 µs per event, blocking, for either writer. It is irrelevant for an opt-in CLI sink
and does not discriminate between the writers. The figures come from one machine and are
indicative only.

**Baseline review, forwarded, not adjudicated here.**

`BASELINE-REVIEW: F260 — a setting's name must say what it controls, and flag/env/config names must correspond (R3.8, MUST) — name the file sink's format setting file-format ([logging] file-format ↔ <PREFIX>_LOG_FILE_FORMAT), not py's format / PLBP_LOG_FORMAT, and leave [logging] format to R58's console format — evidence: raw/opus.md:268 (py context.py:106,109,233-234; settings.py:54-57 at b55b8c26)`

*Status.* This line is Opus's (`raw/opus.md:268`); Muse raised no baseline review. Its evidence is
py source that this synthesis may not read, so it is **not re-derived**. The prompt's own F260 row
is consistent with it: it describes "an independently overridable file-sink format via env"
(`inputs/prompt.md:8`). This decision uses the `file-format` key because member 2 needs a name
that cannot collide with R58's console `format`. The ledger row and any py rename are the
controller's to adjudicate. The affected items are R59, R58 (which owns `format`), R54 (the config
schema) and the py follow-on.

re-verify: on the earliest of — R58's accepted decision (mandatory: it confirms `tracing` versus a
`log` facade, per-layer versus registry-level console filtering, redaction placement for AC7, and
whether `format` is the console's key); R54's accepted decision (what "resolved config" contains
and its key-naming convention); R57's decision being read by the controller against the carried
`state_dir().join("rslbp.log")`; the registration of an application env-var prefix; tokio-rs/tracing#1940
shipping size rotation in `tracing-appender`; `file-rotate` removing the `expect`/`assert`/`.ok()`
paths at `src/lib.rs:425, 446, 485, 553-554`; `logroller` making its size-based shift synchronous;
`tracing-subscriber` 0.4, or a 0.3.x release that changes the `log_internal_errors` default; the
first template CI run on `ubuntu-latest`; otherwise 2027-03-26.

## Parameters

- owns: nothing (the prompt's `- owns:` is empty, `inputs/prompt.md:20`)
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes logging-pipeline-contract = —

**The registered value of `logging-pipeline-contract` is `—`** (`inputs/PARAMETERS.md:18`). R58
has not decided it. The `assumes` line above records that exact value, so the checker can detect
when it changes. This decision's **working assumption** about R58, which the controller must check
against R58's accepted decision, has five parts:

1. The stack is `tracing` 0.1 + `tracing-subscriber` 0.3 on a `Registry`.
2. **The console level is a per-layer filter; no registry-level filter narrower than every sink
   exists** (A07–A09 show what breaks otherwise).
3. Only the binary installs the subscriber, once, after config resolution; the library never
   installs one.
4. R58's redaction can be applied by a second `fmt` layer: through the same `FormatFields` or a
   wrapping layer that the file layer sits behind.
5. `[logging] level` and `[logging] format` belong to the console.

**Fallback branch.** If R58 selects a `log`-facade pipeline, members 1 and 2 become `flexi_logger`
0.31.10 (`Criterion::Size(10 MiB)` + `Cleanup::KeepLogFiles(5)`), re-gated at that time. Member 3
is unchanged. **No `CONFLICT:` line.** The per-layer-filter requirement is a constraint on a design
R58 has not yet made; it does not change a registered value.

**Other upstream answers relied on (not registered parameters):**

- R57 — default path `state_dir().join("rslbp.log")`, **carried** from `raw/opus.md:34-36`, with
  the explicit-path-only fallback (P8).
- R54 — assumed to deliver a fully merged config before logging initialization.
- R67's accepted `error-taxonomy-exit-codes` (`inputs/PARAMETERS.md:16`), from which this decision
  uses two clauses: every stream is flushed on every exit path including signal, and the library
  crate writes to no process stream or file.
- R69's accepted `web-extra-surface` (`inputs/PARAMETERS.md:17`), from which this decision uses two
  clauses: the serve binary carries the R4.1 global core "and nothing beyond it", and every service
  knob is an environment variable named by R77.

**Template constants, not parameters:**

- `ROTATE_MAX_BYTES = 10 * 1024 * 1024`
- `ROTATE_BACKUP_COUNT = 5`
- file level default `debug` and file format default `text` (py's defaults, **carried** from
  `raw/opus.md:547-548`)
- directory mode `0o700` on Unix
- file mode left to the process umask (carried from `raw/opus.md:424-426`; not asserted here)

**Env-var names are not decided here.** No parameter registers an application env prefix. Opus
proposes `RSLBP_` from R57's namespace (`raw/opus.md:612-616`), while R64's published decision uses
`RSLB_PAGER` (`research/topics/64-pager-integration/DECISION.md:21`). This decision writes
`<PREFIX>_LOG_FILE`, `<PREFIX>_LOG_FILE_LEVEL` and `<PREFIX>_LOG_FILE_FORMAT`. The controller
should register one prefix; the inconsistency is recorded under `## Engines`.

## Empirical check

**Toolchain and host** (`r59-toolchain.log`):

- `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and `cargo 1.98.1 (797e8a9bc 2026-08-05)`.
- `rustc 1.96.0 (ac68faa20 2026-05-25)` via rustup, for the floor build.
- macOS 26.4 (25E246), `Darwin 25.4.0 arm64`, Apple M4 Pro.
- GNU bash 5.3.20, `shellcheck` 0.11.0, `jq-1.8.2`, and `gh` for GitHub REST.
- `/usr/bin/grep` by absolute path in every script.

**No check ran on `ubuntu-latest`.**

**Why the floor is 1.96 without fetching the stable manifest.** Opus took "current stable 1.98.1"
from `static.rust-lang.org` (`raw/opus.md:8-11`). That endpoint is outside this topic's named
endpoints (S1 flag). This synthesis did not fetch it. A released `rustc 1.98.1` is installed on this
host (T01), so current stable is **at least** 1.98, and the stable-minus-2 floor is **at least**
1.96 (T02). A build and test on 1.96.0 (H02, H03) therefore covers the floor, whatever the exact
current stable is. The probe declares `rust-version = "1.96"` and `edition = "2024"` (H04).

**Working directory and commands.** Run from the repository root. Each check builds the committed
probe crate (`review/evidence/r59-check/`: `Cargo.toml` pins `tracing =0.1.44`,
`tracing-subscriber =0.3.23`, `tracing-appender =0.2.5` and `file-rotate =0.8.0`, plus the
committed `Cargo.lock`) with `--locked` into a target directory **outside** the repository. It
writes scratch files only under `mktemp -d`, removed by an `EXIT` trap. `r59-common.sh` is the
shared helper: it builds the probe, counts assertions and sets the exit status to the number of
failures. It is not a check.

```bash
cd /Users/stevemorin/c/rs-launch-blueprint-p02-plan
E=research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/review/evidence
shellcheck -x "$E"/*.sh                                   # exit 0, no finding
for c in toolchain source-reads deps writer-contract floor ansi exit-durability \
         precedence msrv bench live-figures; do
  "$E/r59-$c.sh" > "$E/r59-$c.log" 2>&1
done
```

**Observed output.** Every script exited 0. `shellcheck -x` over all 12 scripts, including the
helper, exited 0 with no finding. **11 checks, 110 assertions, 0 failed, 0 skipped.**

| Check | Log | What it establishes | Assertions |
|---|---|---|---|
| T | `r59-toolchain.log` | Toolchains and host; the floor argument above | 4/4 |
| S | `r59-source-reads.log` | Published source lines at the pinned versions, each printed: `file-rotate` panic and `.ok()` sites, `tracing-subscriber`'s `log_internal_errors` default, `tracing-appender`'s time-only `Rotation`, the `unsafe` census | 22/22 |
| P | `r59-deps.log` | `file-rotate`: 2 direct normal deps (`chrono`, `flate2`), 11 packages including itself, `flate2` always compiled; 10 packages, `file-rotate` itself included, not in `tracing-subscriber`'s set; the owned writer adds none | 5/5 |
| W | `r59-writer-contract.log` | The member-1 table: rotation layout, torn records, every failure mode, B8 end to end | 29/29 |
| A | `r59-floor.log` | The floor: per-layer, no file, registry-level filter, JSON | 11/11 |
| E | `r59-ansi.log` | 12 escape bytes by default, 0 with `.with_ansi(false)`, user escape bytes escaped | 3/3 |
| C | `r59-exit-durability.log` | 1,000 records then `process::exit(0)`: owned 1000×3, `file-rotate` 1000×3, `non_blocking` 48/0/182, `non_blocking` with the guard dropped 1000×3 | 4/4 |
| G | `r59-precedence.log` | 8 resolver tests pass on 1.98.1 | 3/3 |
| H | `r59-msrv.log` | Build and 8 tests pass on 1.96.0 | 4/4 |
| D | `r59-bench.log` | Indicative throughput (only completion is asserted) | 3/3 |
| L | `r59-live-figures.log` | crates.io, GitHub REST and RustSec figures; the CI OS matrices behind the gate-4 exclusions; the README lineage; tracker states; `file-rotate` responsiveness | 22/22 |

**Reproducibility.** Checks T, S, P, W, A, E, G and H are deterministic on this host. The rerun
differences are timestamps in A and E, the CARGO paths, and the `run (UTC)` line. C's
`non_blocking` counts vary by run; only "fewer than 1,000 in every run" is asserted. D's timings
vary; only completion is asserted. L prints live counters without asserting them, so a rerun
differs there by upstream drift, not by defect. Its assertions cover only facts expected to stay
stable for this decision's life.

**Not proven here:**

- anything on `ubuntu-latest`;
- a binary-level test through `clap` (AC1, AC3, and AC8's warn-and-continue branch);
- AC7 redaction;
- two real OS processes rotating one file (modeled in-process, W22–W25);
- the carried `logroller` exit defect;
- `flexi_logger`'s rotation behavior;
- the `0o700` directory mode, which is set by the probe but not asserted;
- the directory-removed and directory-blocked cases at 10 MiB (probed only at 64 B; gap 12).

## Engines

**The two legs.**

- **Muse (Meta)** — `raw/muse.md`. It recommends `file-rotate` 0.8
  (`BytesSurpassed(10 MiB)`, `AppendCount::new(5)`), wrapped in `non_blocking`, as a second
  per-layer `fmt` layer (`raw/muse.md:41`). It applies the sink to CLI runs and the long-lived web
  service alike (`raw/muse.md:17`). Its runner-up is `flexi_logger` (`raw/muse.md:86`). It raises
  no BASELINE-REVIEW and no `CONFLICT:`. It executed no code (`raw/muse.md:37, 202`).
- **Claude Opus (`claude-opus-5-5`)** — `raw/opus.md`. It recommends a template-owned std
  `RotatingFile` in a blocking second `fmt` layer, CLI only (`raw/opus.md:272-281`). Its runner-up
  is `file-rotate` 0.8.0 (`raw/opus.md:283-286`). It raises BASELINE-REVIEW F260
  (`raw/opus.md:268`) and no `CONFLICT:`. It executed a check crate under `/tmp/r59-opus`, outside
  this synthesis's read set; none of its outputs were reused here.

**Engine seat: authorized, but this run's policy snapshot is stale.** The current runbook records
two owner decisions. Q9.B "retired Codex from P02 (legs Muse, synthesis/judgment/empirical
Claude)". Q17.A, dated 2026-09-27, extends the Muse-for-Codex substitution to a research wave that
names R59, with legs "muse+opus" (`research/RUNBOOK.md:71-75`). The Muse leg is therefore the
authorized second leg. This run's inputs pre-date Q17.A:

- the policy snapshot still assigns R59 `codex, opus` (`inputs/EXECUTION.json:635-640`) and has no
  R59 entry in `engine_overrides`;
- `manifest.json:27-30` requires `codex, opus`.

Q17.A's text was not in `research/RUNBOOK.md` when this synthesis first read it; it appeared on a
re-read during the synthesis, so a concurrent session edited the file mid-run. The controller
should refresh the run's policy snapshot, or record Q17.A against it, before acceptance, because
the checker compares recorded input hashes.

**S1 context flag, verified.** Opus fetched `https://static.rust-lang.org/dist/channel-rust-stable.toml`
beyond the named endpoints, and disclosed it (`raw/opus.md:24-28, 811`). The only claim that rests
on it is "current stable 1.98.1, so the floor is 1.96" (`raw/opus.md:8-11`). That claim was
re-derived without the endpoint (`## Empirical check`, T01–T02, H01–H04). No other claim in this
decision depends on the fetch. Opus also read files outside the run: py, ts, R57's decision, R58's
prompt and the org standard (`raw/opus.md:16-21`). Every claim resting on them is marked carried.

**D1 — rotation component: `file-rotate` (Muse) or owned code (Opus)? Settled for owned code, by
re-derivation.** Muse concedes the `expect` and `assert` paths and proposes a validation wrapper
(`raw/muse.md:78`). Opus measured two panics and a silent drop (`raw/opus.md:164-174`). This
synthesis reproduced all three: W12–W13, W20–W21 and W15–W16. It also found a fourth defect that
neither leg tested: a panic when two writers share one path (W24, W25, `src/lib.rs:554`). A
constructor wrapper cannot fence the runtime panics. The owned writer met every tested row (W01–W05,
W11, W14, W17, W18, W22, W23, C01). One fact favors Muse's pick and is recorded, not hidden: at
rotation time, `file-rotate` recreates a deleted directory, and the owned writer instead returns
`Err` until restart (W19 versus W17). Those rows ran at a 64-byte limit. At 10 MiB, both writers
return `Ok` into the unlinked file until the next rotation (member 1). D1 does not rest on the
directory rows: W12 and W15 happen at open, and W20 and W24 happen at rotation, at any limit.

**D2 — surface: CLI and web (Muse, `raw/muse.md:17`) or CLI only (Opus, `raw/opus.md:98-102`)?
Settled for CLI only, from an accepted registered value.** R69's accepted `web-extra-surface` says
the serve binary carries the R4.1 global core "and nothing beyond it". It also says every service
knob "such as host, port, log format and drain deadline stays an environment variable named by R77"
(`inputs/PARAMETERS.md:17`). A `--log-file` flag on the serve binary would violate that contract.
A web file sink configured by env would be R77's decision, not R59's. Opus's py evidence — py's web
profile configures no file path (`raw/opus.md:99-102`) — corroborates this. It is carried, because
py is outside this synthesis's read set. If a web file sink is ever wanted, Opus's extension path
applies: `non_blocking`, with the guard held in `main` until graceful shutdown
(`raw/opus.md:539-542`).

**D3 — `non_blocking` wrapper (Muse, `raw/muse.md:41, 82, 125`) or blocking (Opus,
`raw/opus.md:517-520`)? Settled for blocking.** Re-derived: `non_blocking` with a live guard lost
most records at `process::exit` (48, 0 and 182 of 1,000 in C03). A dropped guard lost none (C04).
The unbuffered writer lost none (C01). R67 requires every stream to be flushed on every exit path,
including signals (`inputs/PARAMETERS.md:16`). The blocking writer meets that with no guard to
thread through the signal paths. Its cost, about 2 µs per event (D), does not matter for an opt-in
CLI sink.

**D4 — initialization: "second pass" (Muse, `raw/muse.md:31`) or "one pass after config
resolution" (Opus, `raw/opus.md:225-233`)? Not a disagreement.** Both describe one subscriber
construction after config merge, with pre-initialization failures on stderr. Muse's "second pass"
is relative to config loading. Both name `reload` as the alternative only if R58 needs earlier
logging (`raw/muse.md:134`, `raw/opus.md:654-655`).

**D5 — the floor. Agreement, sharpened.** Both say that per-layer filters make the floor automatic
(`raw/muse.md:33`, `raw/opus.md:208-223`). Opus showed, and this synthesis re-derived, that a
registry-level filter silently loses the file's debug events while `current` still reads `debug`
(A07–A09). Muse's condition — "if R58 sets a single global `max_level` … the global must be the most
verbose of the two levels" (`raw/muse.md:33`) — is therefore insufficient if it is read as permitting
a registry-level `LevelFilter`. The constraint is recorded under `## Parameters`.

**D6 — an unopenable path at startup: config error (Muse, `raw/muse.md:78, 125`) or stderr warning
and continue (Opus AC8, `raw/opus.md:146`)? Settled for warn-and-continue, as a judgment.** Opus's
own sketch contradicts its AC8: `.transpose()?` (`raw/opus.md:200`) propagates the error out of
`main`. No leg executed either branch at binary level. The reasoning has three parts:

- B8 makes the file sink subordinate to the command.
- R67 maps an invalid config value to `RSLB203` (exit 2) and an I/O failure to `RSLB101` (exit 1)
  (`inputs/PARAMETERS.md:16`). This decision keeps the first mapping: an unparsable `file-format`
  is a config error. **The second is a deliberate exception.** An unopenable log path is the one
  I/O failure that does not produce `RSLB101`/1: it is a stderr warning and the exit status is
  unchanged. B8 justifies the exception, because the failing resource is the diagnostics sink,
  not the command's work. R67 does not support this choice; it supplies the alternative.
- The user asked for diagnostics, not for the command to fail. The stderr warning tells them the
  file was not written.

This is the most reversible choice in the decision. If the owner rejects the exception, the branch
returns `RSLB101`/1 under R67's default mapping, and nothing else changes. **Planned:** a binary-level test of the
chosen branch.

**D7 — survey breadth. Resolved for Opus.**

- Muse omitted `rolling-file`, `logroller`, `logforth-append-file` and `spdlog-rs`.
- Muse called `tracing-rolling-file` "purpose-built" (`raw/muse.md:11`). Its README says it is
  "based on rolling-file" (L12), as Opus stated (`raw/opus.md:59`).
- The gate-4 exclusion of `rolling-file` rests on its CI matrix, `ubuntu-18.04, windows-latest` (L08).

**D8 — figures.**

- *`file-rotate` dependencies*, "2" (`raw/muse.md:90`) versus "11" (`raw/opus.md:167`). Both are
  correct: 2 direct normal deps, 11 packages including itself (P01, P02).
- *`file-rotate` responsiveness.* Muse's "5 of the last 7 issues, median 6.8 days"
  (`raw/muse.md:61`) does not follow the prompt's rule of the 10 most recently opened issues
  (`inputs/prompt.md:56`). Opus's "7 answered, 3 unanswered, median 2.6 days" (`raw/opus.md:351`)
  used the right sample. The recount matches Opus's answered and unanswered counts but gives a
  **median of 1.9 days** (`r59-live-figures.log:65`). The per-issue days are printed on the lines
  above that one, for a reader to check.
- *Performance.* Opus measured `file-rotate` `BytesSurpassed` at 420–576 ms per 100,000 events
  against 209–239 ms for owned code (`raw/opus.md:241-243`). **That did not reproduce:** 192–200 ms
  against 195–322 ms (D). Performance is not a discriminator, and D1 does not rest on it.
- *`tracing-subscriber` `unsafe`.* 26 lines and 28 tokens in 6 files (S18–S20), against Opus's
  "26 tokens" (`raw/opus.md:496`).
- *`tracing-subscriber` package count.* Opus's "18 unique normal dependencies"
  (`raw/opus.md:499-500`) against 15 unique packages, `tracing-subscriber` itself included, in
  `r59-deps.log:20-36`. The log's count is used. The feature sets are the same (`fmt`, `std`,
  `registry`, `json`, `ansi`), so features do not explain the difference; Opus's tree was not
  available to this synthesis.

**D9 — default numbers. Agreement.** Both keep py's 10 MiB × 5 (`raw/muse.md:35`,
`raw/opus.md:256-264`). No surveyed Rust crate imposes a default: `file-rotate` takes both numbers
as arguments. Muse's `BytesSurpassed` preference is subsumed: the owned writer uses py's pre-write
rule, which never exceeds the limit and never tears a record (W02, W03).

**D10 — the B8 mechanism. Neither leg found it; new evidence.** Both legs assumed that a writer
error surfaces on stderr through the `fmt` layer. Opus states it outright (`raw/opus.md:329-331`),
and Muse's design relies on it implicitly. In `tracing-subscriber` 0.3.23 it does not by default
(S10–S12, W26–W29). Member 2 therefore adds `.log_internal_errors(true)`. Under the default,
`file-rotate`'s silent `Ok` and the owned writer's `Err` would look identical to the user, because
both lose the event without a word. The setting reports only a writer's `Err`. Records written into
an unlinked file after a directory removal return `Ok` for both writers until the next rotation,
and no setting reports them (member 1; W26–W29 ran at a 64-byte limit).

**Agreements carried without dispute.** Both legs agree on these points:

- the sink exists, opt-in;
- ts's absence is a missing capability;
- `tracing-appender` rotates by time only;
- `log4rs` is excluded on gate 4;
- `flexi_logger` is the `log`-facade fallback;
- the resolver is a pure function built after config resolution;
- no `CONFLICT:`.

**Carried, not verified by this synthesis** (each cited to its raw line above):

- py's behavior beyond the prompt's F-row pins (`raw/opus.md:99-102, 146, 268, 547-548, 605`);
- R57's default path (`raw/opus.md:34-36`);
- the org CLI Design Standard rules (`raw/opus.md:111-117`);
- the adopters and their pinned commits (`raw/opus.md:83-88`, `raw/muse.md:15`);
- the `logroller` exit defect (`raw/opus.md:172-173`);
- `tracing-rolling-file`'s buffering (`raw/opus.md:171`);
- the `max_level_*` compile-time cap (`raw/opus.md:221-223`).

**Gaps recorded:**

1. R58 has no decision, so this decision is conditional and cannot be accepted until R58 lands.
2. No run on `ubuntu-latest`.
3. No binary-level test (AC1, AC3, AC8).
4. AC7 redaction cannot be tested until R58 defines redaction.
5. Real two-process rotation was not run.
6. py, ts, R57 and the org standard were not read (read-set constraint); the claims resting on them
   are carried.
7. Current stable was not fetched; the floor is argued from the installed toolchain.
8. The env prefix is unregistered, and R64 (`RSLB_`) and Opus (`RSLBP_`) disagree.
9. This run's policy snapshot and manifest pre-date owner decision Q17.A, which authorizes the Muse leg.
10. `flexi_logger`'s rotation is untested by anyone.
11. No issue-responsiveness sample for `tokio-rs/tracing` (member 2); its maintenance state rests on
    release, push and advisory evidence only.
12. The directory-removed and directory-blocked cases were probed only at a 64-byte limit (W17–W21,
    W26–W29). At 10 MiB their behavior is argued, not observed. For `file-rotate`, a pre-rotation
    write returning `Ok` into the unlinked file was observed at 64 B (`r59-writer-contract.log:90`,
    `:96`); the rest rests on S02, S04 and S06. For the owned writer, it rests on probe
    `src/lib.rs:46, 53, 63`. Revision 2 deliberately reran no probe, to keep the approved evidence
    stable.

**What P03 must validate:**

1. Port W01–W05, W11, W14, W17, W18, W22 and W23 as `#[test]`s using `tempfile`, and run them on
   `ubuntu-latest` and `macos-latest`. Include the boundary case of a record that exactly reaches
   the limit. Add the directory-removed case with no rotation pending (expect `Ok` until a forced
   rotation, then `Err` until restart), which closes gap 12.
2. The A01–A09 floor tests, run against R58's actual console layer.
3. Binary-level tests: AC1 (no file without enablement), AC3 (a bare flag under
   `XDG_STATE_HOME=<tmp>` writes the default path) and AC8 (an unopenable path produces a stderr
   warning and an unchanged exit status).
4. AC7: `info!(token = "s3cr3t")` must not appear in the file once R58's redaction exists.
5. A test that the file layer carries `.log_internal_errors(true)` (W28, W29).
6. A two-process rotation test with two concurrent invocations of the binary.
