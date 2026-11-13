# 2026-09-28 — R59 — file-log-sink (bundle, Focused) — decision (revision 4)

**Revision note, revision 4.** Revision 3 (sha256
`2e425d799a7ff66ac495edcd7c9066fce94a764bc768359b83216355d6fcd089`) is preserved byte-identical as
`review/R59-r3-snapshot.md`. That snapshot already existed; `cmp` against revision 3 reported no
difference, and it was not rewritten. This revision is the directed repair of the S77 stop under
the Q23 scope box (`research/RUNBOOK.md` §7). It applies only the enumerated fixes below.

**Why revision 4 exists.** R58's revision 2 decided `logging-pipeline-contract`. Revision 3 was
written against the registered value `—` and five working assumptions. Two of those assumptions
break against R58's revision 2:

- Revision 3 built the subscriber once, after configuration. R58's revision 2 installs it first,
  before configuration discovery.
- Revision 3's JSON branch used the stock `.json()` formatter. That formatter leaks every event
  field past redaction, and R58's revision 2 keeps the `json` feature off.

**The two S1 rulings on the S77 stop, recorded from the ledger.**

1. The installation-order break resolves inside R59's own design. Revision 3 already named the
   reload slot at `:553-556` for exactly this case: R58 needs logging before configuration
   discovery. This revision adopts that slot.
2. Member 2 proceeds on a per-layer console filter. R58's promise at `R58-r2:654-657` gives a sink
   "a level independent of the console". That promise governs over R58's illustration at
   `R58-r2:1005`, which shows one registry-level `filter`. A re-verify trigger fires on R58's
   revision 4, which will align the illustration.

**Source of the adopted value.** The source is the pinned R58 revision 2 snapshot,
`research/runs/R58/2026-09-18T215915Z-184041b91674/review/R58-r2-snapshot.md`, sha256
`8dc8ce955c58abd508d45bd74a6b2c3f9eb96bde5c43ae20538f2439c8867aae`. Its `- owns` line is at
`:1485`. R58's live `DECISION.md` is its revision 3; it was not read, and nothing was taken from it.
`inputs/PARAMETERS.md:18` still registers `—`. The `assumes` line therefore differs from the frozen
registry row **by design**. The S1 adoption pins the value at the revision-2 sha. Under the
point-in-time and no-repin rule (§7.7), that difference triggers no re-pin.

**Re-pointed addresses.** Line numbers are revision 3's.

| Fix | What revision 3 said | Repair in revision 4 |
|---|---|---|
| 1 | `:601` `- assumes logging-pipeline-contract = —` | The line is `- assumes logging-pipeline-contract = ` followed by `R58-r2:1485`'s owned text, byte for byte. It was built by script, and check J re-derives it from the snapshot and compares it with `cmp` (J05). The `## Parameters` prose, the status block and gap 1 now describe the adopted value |
| 2 | `:546-552`, `:611-612`: parse, merge config, then build one subscriber and call `try_init()` once. `:553-556`: `reload` is the ranked alternative, not evaluated | Install first: R58's `telemetry::init` installs the console layer and an empty R59 sink slot. After configuration resolves, the file sink fills the slot through two reload handles: a body handle, and a per-layer filter handle that starts at `OFF`. The slot now covers `[logging] file`, `file-level` and `file-format`. **Executed**: check K (K01–K11). Also re-pointed: recommendation members 2 and 3, the prompt-question row for `:35`, the composition sketch and initialization order in `### Principles and implementation`, D4, working assumption 3, and the R54 bullet in `## Parameters` |
| 3 | `:526` `FileFormat::Json => l.json()…` | The JSON branch uses R58's `JsonEvent` + `JsonFields`. The text branch uses R58's `HumanFields`, because AC7 cannot hold if either branch is unredacted; R58's contract names `HumanFields` for the human profile. **This text-branch change is this worker's reading of fix 3's goal, "so AC7 holds"; the controller may reject it.** Consequences: the recommendation's member 2, gate 5 (`json` no longer needed), and the AC6 and AC7 rows |
| 4 | `:533-534` `try_init().expect("subscriber installed once, in main")` | Removed. `telemetry::init` installs the subscriber, and init never panics (`R58-r2:1485`, INITIALISATION) |
| 5 | Member 2, setting 1: per-layer `LevelFilter`, with no R58 citation. Working assumption 5: "`[logging] level` and `[logging] format` belong to the console" | Setting 1 cites R58's promise, records the S1 ruling, and adds the re-verify trigger on R58's revision 4. The format-key home follows `R58-r2:1538-1539`: `[logging]` keys beyond `level` are R54's and R59's, so R59 owns `file-format`. The same repair lands in F255, in the F260 status paragraph and in working assumption 5. **"Member 5" in the scope is read as working assumption 5**, because no member 5 exists; the controller may correct that reading |
| 6 | Evidence: 11 checks, 110 assertions | 13 checks, 137 assertions, 0 failed (see `## Empirical check`); `shellcheck -x` covers all 14 scripts |

**The recommendation moves only where the scope authorizes it.** Member 1 does not move. Member 2
moves in two places: its formatters, and where it enters the subscriber. Member 3's installation
order moves. The `log`-facade fallback is moot, because the adopted value selects `tracing`. It is
kept for the record and marked as not taken.

**Evidence in revision 4.** Sixteen evidence files changed or were added. One probe source
changed, two check scripts and their two logs are new, and eleven paired logs were rewritten:

- The probe `src/main.rs` gained one scenario, `slot`, appended at the end of the `match`. Every
  `src/main.rs` line that revision 3 cites is unchanged. `Cargo.toml` and `Cargo.lock` are
  unchanged. The lock's sha256 is `0f421eeb…55328` in every log that builds the probe, which is
  the same value revision 1's logs printed.
- `r59-reload-slot.sh` and `r59-contract-adopt.sh` are new checks.
- All 13 checks were rerun **into their paired logs**. That overwrote the revision-1 log bytes of
  the 11 original checks, including the four checks whose inputs did not change: T, S, P and L.
  No assertion outcome moved. Several dynamic values the prose cites did move, and none of those
  prose figures was edited. The revision-4 replay note under `## Empirical check` lists the moved
  values.

The observations at the end of this note were found during the repair and are **not** fixed here.

**Observations (not fixed; for controller triage).**

- Gate 6's "15 packages" was measured with the probe's feature set, which has `json` on. R58 keeps
  `json` off, and R58 measures its own crate count. The figure overstates what member 2 costs.
- A10 and K10 execute the stock `.json()` formatter as a stand-in. R58's `JsonEvent` + `JsonFields`
  are executed only in R58's own evidence (S2 there), not here.
- The probe enables `tracing-subscriber` features `fmt, std, registry, ansi, json`. R58 enables
  `env-filter` over the default set, with `json` off.
- R58's revision 2 `Handles` carries only the console level handle and `log_bridge_refused`. It
  has no field for the sink slot's two handles. Revision 4 proposes that R59 fills the slot this
  way; R58's revision 4 must confirm it (re-verify trigger; gap 13).
- Events emitted before the slot fills reach the console only (K07). A file sink enabled by flag
  or environment variable could attach before configuration discovery. This revision does not
  decide that.
- D8 says Opus's performance gap "did not reproduce". In the revision-4 log, `file-rotate`
  `BytesSurpassed` took 233–424 ms against 210–233 ms for owned code. That leans toward Opus's
  direction. The revision-1 run (192–200 against 195–322) and the revision-1 audit's run (214–253
  against 208–372) did not. Only completion is asserted, and D1 does not rest on performance. The
  observation is for the controller; D8 is not edited.
- `r59-reload-slot.sh` needed one repair before its first green run. A `grep` pattern that begins
  with `-` was read as an option, and `-e` fixed it. Only the green run's log is kept.

**Revision note, revision 3.** Revision 2 (sha256
`2ad574f88a1d5d20927a3225d0168ef1ee18c73480adf0734d5aa994d90863d1`, preserved byte-identical as
`review/R59-r2-snapshot.md`) was approved by both audits, `review/audit-fable.r2.md` and
`review/audit-codex.r2.md`, each with MECHANICAL findings only. This revision is a directed repair
of exactly those five findings. **The recommendation does not move.** Nothing is reversed, so
there is still no Supersedes section.

| Finding | What revision 2 said | Repair in revision 3 |
|---|---|---|
| fable 1 (JF-3) | D1: "This synthesis reproduced all three" of Opus's two panics and silent drop; "Muse concedes the `expect` and `assert` paths"; member 1's third `file-rotate` defect was "the log directory has become uncreatable mid-run" | D1 now says W12–W13 and W15–W16 reproduce Opus's constructor panic and silent drop; Opus's directory-removed panic was **not** reproduced as stated (W19 self-heals); W20–W21 is the file-blocks-the-path proxy and panics at `src/lib.rs:553`, not in `ensure_log_directory_exists`; the setup difference is unresolved. Muse's concession is narrowed to the constructor `expect` and the zero-limit `assert`. Member 1's bullet names W20 |
| fable 2 (JF-7 / JF-1) | D6: an unopenable log path is "a deliberate exception" to `RSLB101`/1, which "R67 does not support"; sketch comment `// D6: RSLB101 exception` | D6 now cites R67's own crash-record clause ("a write failure never changes the envelope or the exit code", `inputs/PARAMETERS.md:16`) as the precedent this decision follows. The sketch comment is `// D6: best-effort sink, as R67's crash record`. The reversibility sentence keeps its content; its referent "the exception" became "this choice", because the exception framing is gone |
| fable 3 (JF-2) | Member 2: tokio-rs/tracing issue responsiveness "not sampled"; gap 11 | Sampled: 10 issues, 0 answered, 10 unanswered, no median (details and method in member 2). Gap 11 is narrowed to the residual causes. The maintenance state and the recommendation are unchanged |
| codex 1 | Reproducibility: "Checks T, S, P, W, A, E, G and H are deterministic on this host" | The **assertion outcomes** are deterministic, not the log bytes. A dated replay note records the empirical audit's rerun: 11/11 byte comparisons differ, 110/110 assertion outcomes match, and the dynamic values that changed |
| codex 2 | Member 1 table: owned writer "Every file ≤ limit: yes, 4,056 B (W03)"; D9: the pre-write rule "never exceeds the limit" | The cell and D9 are bounded to the tested 78-byte records: one record larger than the limit is written whole into an empty file and exceeds it. P03 item 1 adds an oversized-record case. D9 is aligned as the same claim |

**Evidence in revision 3.** No file under `review/evidence/` changed, and no committed check was
rerun. The one new figure, the tokio-rs/tracing responsiveness sample, came from a copy of check
L's responsiveness block run from `/tmp`; it is not in `r59-live-figures.log`. Its method is stated
in member 2. The replay figures under `## Empirical check` are the empirical audit's, cited to
`review/audit-codex.r2.md`.

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

**Status: conditional on R58's acceptance.** R59 consumes R58's
`logging-pipeline-contract` (`inputs/prompt.md:21`). At freeze, that parameter's registered value
was `—` (`inputs/PARAMETERS.md:18`), and the run's prerequisite snapshot recorded R58 as
`"decision": "missing"` (`inputs/prerequisites.json:2-4`). Revision 4 adopts R58's revision-2
owned value verbatim, from the pinned snapshot, under the S1 ruling (see `## Parameters`). The
controller must re-check the adopted value against R58's accepted decision before accepting this
one.

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
date of `review/evidence/r59-live-figures.log:5`. **Revision 4:** every paired log was rerun on
2026-09-28 UTC and now carries that date. The revision-1 log bytes were overwritten. The prose
figures stay those of the 2026-09-27 retrieval; the values that changed are listed in the
revision-4 replay note under `## Empirical check`.

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
>    **`.log_internal_errors(true)`**, and the writer `Mutex<RotatingFile>`. Its formatters are
>    R58's redacting pair: `HumanFields` for text (the default), and `JsonEvent` + `JsonFields`
>    for JSON. It never uses the stock `.json()`. It is **blocking**: no
>    `tracing_appender::non_blocking` wrapper. It fills R58's sink slot in `telemetry::init`
>    (`R58-r2:654-657`) as a **reload slot**. The slot is installed empty, beside R58's console
>    layer. After configuration resolves, it is filled through two reload handles: one for the
>    layer body, and one for its per-layer filter, which starts at `OFF` (K01–K11).
> 3. **Enablement — a pure resolver `resolve_log_file(flag, env, config, default_path)`.** The
>    precedence is flag > env > config > off. `--log-file` takes an optional value; a bare flag, or
>    an env value that is present but empty, selects the default path. The config keys are
>    `[logging] file`, `file-level` and `file-format`. The subscriber is installed **first**, by
>    R58's `telemetry::init`. The file sink attaches through the reload slot **once
>    configuration is fully resolved**.
>
> **Ranked runner-up for member 1:** `file-rotate` `=0.8.0` with
> `ContentLimit::BytesSurpassed(ROTATE_MAX_BYTES)` and `AppendCount::new(5)`. It is only
> acceptable behind a constructor that pre-creates the directory and probes the open. Even then it
> keeps two runtime panics that no wrapper can fence without `catch_unwind` (member 1, below).
> **Fallback if R58 selects a `log`-facade pipeline instead of `tracing`:** members 1 and 2 are
> replaced by `flexi_logger` `0.31.10` (`Criterion::Size` plus `Cleanup::KeepLogFiles(5)`), whose
> rotation was tested by neither leg nor this synthesis. Member 3 is unchanged. **Not taken in
> revision 4:** the adopted R58 revision-2 value selects `tracing` (`R58-r2:1485`, STACK). The
> fallback is kept for the record.

**The prompt's questions, answered.**

| Prompt question (`inputs/prompt.md`) | Answer | Evidence |
|---|---|---|
| Decision (`:31`): ship a file sink at all? | Yes, opt-in, CLI binary only | Both legs say yes (`raw/muse.md:41`, `raw/opus.md:98-102`); surface settled in `## Engines` D2 |
| HIGH (`:32`): does R58's crate already rotate by size? | If R58 selects `tracing`, **no**: `tracing-appender` 0.2.5 rotates by time only. A separate component is needed | `Rotation` has exactly five kinds, `MINUTELY` to `NEVER` (S15), and no size identifier (S16). tokio-rs/tracing#1940 and #858, the size-rotation requests, are open (L13, L14) |
| HIGH (`:33`): size + backup-count candidates | Surveyed below under `### Landscape` and the member-1 tables | S, W, L checks |
| HIGH (`:34`): principles and agreement levels across py, ts, rs | Under `### Principles and implementation` | — |
| MEDIUM (`:35`): initialization order | Install first: R58's `telemetry::init` runs before config discovery, with an empty R59 sink slot. The file sink fills the slot after config resolution (revision 4, S1 ruling) | K01–K11; `## Engines` D4 |
| MEDIUM (`:36`): shape of py's `min(level, file_level)` floor | Automatic with per-layer filters; **no computation**. Requires R58's console level to be a per-layer filter too | A01–A09 |
| LOW (`:37`): Rust default for 10 MiB × 5? | No Rust crate imposes one; keep py's 10 MiB × 5 as template constants | `## Engines` D9 |

**Settled ledger rows** (all origin `py-only`, verdict `DIVERGENT`, item R59, per
`inputs/prompt.md:8`):

| Row | py behavior (per the prompt) | rs disposition |
|---|---|---|
| F255 | `LoggingSettings` has `level`, `file`, `file_level`, `format` | `[logging]` gains `file`, `file-level`, `file-format`. `level` is R58's config rung (`R58-r2:506`). R58 leaves `[logging]` keys beyond `level` to R54 and R59 (`R58-r2:1538-1539`), so the file keys, `file-format` included, are R59's. **Key naming is subject to BASELINE-REVIEW F260**, forwarded below |
| F256 | `RotatingFileHandler(maxBytes, backupCount)` | Member 1, `RotatingFile`: same pre-write trigger and the same `.N` naming |
| F257 | 10 MiB, 5 backups | Same numbers, as constants, not settings |
| F258 | `--log-file` flag and env | `--log-file[=PATH]` plus an env var. The env prefix is unregistered; see `## Parameters` |
| F259 | flag/env > config `logging.file` > off | `resolve_log_file`, 8 executed cases (G02) |
| F260 | Independently settable file format, overridable by env | Member 2 is its own `fmt` layer, using R58's redacting formatters. BASELINE-REVIEW F260 (Opus) is forwarded unadjudicated |
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
| Every file ≤ limit | ≤ 4,096 bytes for the tested 78-byte records, 4,056 B maximum (W03); one record larger than the limit can exceed it | yes | over by at most one record, 4,134 B (W09) |
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
- a panic at rotation when a file blocks the log directory (W20);
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
(gap 12). The owned writer's per-file size bound is conditional on record size: it holds for the
tested 78-byte records (W03). The probe skips rotation while the file is empty (`self.size > 0`,
probe `src/lib.rs:63`) and writes the whole buffer, so one record larger than the limit is written
whole and exceeds it (`review/audit-codex.r2.md:10`). That is the one-record overshoot that
"May vary" already allows. Medium that owned
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
- Issue responsiveness (revision 3): of the 10 most recently opened issues, PRs excluded
  (#3587–#3613, opened 2026-07-31 to 2026-09-16), **0 answered and 10 unanswered; no median**,
  because no issue has a maintainer reply. Retrieved 2026-09-27T18:37Z UTC. The sampler is a
  `/tmp` copy of check L's `file-rotate` responsiveness block (`r59-live-figures.sh`), retargeted
  at `tokio-rs/tracing`, with one change: `per_page=100` instead of `40`, because the repository
  is PR-heavy and 40 items may hold fewer than 10 issues. The figure is **not** in
  `r59-live-figures.log`. The sampler counts a reply as a maintainer's only when its
  `author_association` is `OWNER`, `MEMBER` or `COLLABORATOR`. Four of the ten issues have
  comments; the one on #3613 has association `CONTRIBUTOR`, so the rule does not count it. See
  gap 11.

**Maintenance state: `stable-quiet`.** The rubric (`inputs/prompt.md:60`) treats "no release in 6
months" as a trigger to investigate, never as the verdict. The trigger fires: 0.3.23 is 198 days old
at retrieval. The investigation found:

- the same repository released `tracing-appender` 0.2.5 on 2026-04-17 (`r59-live-figures.log:12`);
- the repository was last pushed 120 days before retrieval, and it is not archived (`:28`);
- RUSTSEC-2025-0055, the advisory gate 3 cites, is patched from 0.3.20, below the pin (L16).

That is quiet but maintained. `active` is not claimed, because nothing here shows recent work on
`tracing-subscriber` itself. The responsiveness sample above counts no maintainer reply on the 10
newest issues under the sampler's association rule. This revision does not re-judge the state on
that figure; whether it is the rubric's concrete signal for `at-risk` is left to the controller.
The state does not affect the recommendation: R58 selects the pipeline crate, and member 2 only
adds a second layer of it.

**Gates.**

- Gate 2: `rust-version` 1.65.0 (S14). The probe builds on 1.96.0 (H02).
- Gate 3: RUSTSEC-2025-0055 (ANSI escape injection) is patched from 0.3.20 (L16). 0.3.23 is the
  newest release (L02). User-supplied escape bytes are written as escaped text (E03).
- `unsafe`: 26 lines containing `unsafe`, 28 tokens, in 6 files — `reload.rs`, `fmt/mod.rs`,
  `fmt/fmt_layer.rs`, `layer/layered.rs`, `layer/mod.rs`, `filter/layer_filters/mod.rs`
  (S18–S20). Opus's "26 `unsafe` tokens" (`raw/opus.md:496`) is 26 lines; some lines hold two.
- Gate 4: tokio-rs CI (carried from both legs).
- Gate 5: this member needs the features `fmt`, `std` and `registry`, plus `ansi` for the
  console. All four are in R58's set. Revision 4: it does **not** need `json`. The JSON branch
  uses R58's template-owned `JsonEvent` + `JsonFields`, and R58 keeps `json` off
  (`R58-r2:1485`). The probe still enables `json`, only for the stand-ins in A10 and K10. There is
  no async coupling.
- Gate 6: 15 packages with those features, `tracing-subscriber` itself included, a cost R58 pays in
  any case. `r59-deps.log:20-36` lists 17 lines, but two are `cargo tree` `(*)` repeats of packages
  already listed (`serde` at `:27`, `tracing-core` at `:33`). This counts unique packages, as
  `file-rotate`'s 11 does (P02).

**Three settings the file layer must carry, each observed:**

1. **Per-layer `LevelFilter`** (A01–A05; in the reload slot, K03–K08). With the console at
   `warn` and the file at `debug`:
   - `LevelFilter::current()` is `debug`;
   - the file receives both events, and the console receives only `warn`;
   - without the file layer, `current` is `warn`, so the cost of a disabled event is unchanged.

   **R58's side of this, revision 4.** R58 promises that the sink slot takes "its own per-layer
   `Filter`", and that per-layer filters give a sink "a level independent of the console"
   (`R58-r2:654-657`). R58's illustration at `R58-r2:1005` shows one registry-level `filter`
   instead, which A07–A09 show would lose the file's debug events. Per the S1 ruling, the promise
   governs, and member 2 proceeds on a per-layer console filter. **Re-verify trigger:** R58's
   revision 4, which will align the illustration. If R58's revision 4 keeps a registry-level
   console filter narrower than the file level, this member breaks.
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
| AC6 | Zero `0x1b` bytes in the file; `json` yields one object per line | Executed, E02. The JSON line shape was executed with the stock `.json()` as a stand-in (A10, K10). R58's `JsonEvent` + `JsonFields`, which the design uses, are executed only in R58's evidence |
| AC7 | A masked field is masked in the file | Holds by construction under the adopted contract: text uses `HumanFields`, and JSON uses `JsonEvent` + `JsonFields` (`R58-r2:1485`, redaction clause). **Planned** here: P03 item 4 |
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

**The composition, in the template's form (revision 4).** Three parts were executed separately:

- The reload slot was executed with a stand-in console layer, both text and JSON bodies, and
  `try_init` (K01–K11, `src/main.rs` `slot`).
- The per-layer floor was executed in a `Vec<Box<dyn Layer<Registry> + Send + Sync>>` (A01–A05).
- `.log_internal_errors(true)` was executed on a non-optional layer (W28, W29).

R58's `HumanFields`, `JsonEvent` and `JsonFields` are R58's code, and they were not built here.
The combined form below is **proposed**, not executed as one piece. Two design points shape it:

- **Install first.** The slot lives in R58's `telemetry::init`, the one install point. That call
  uses `try_init()` and never panics (`R58-r2:1485`, INITIALISATION).
- **Two handles.** The per-layer filter sits **outside** the reloadable body.
  `Handle::reload` cannot replace a `Filtered` layer (`tracing-subscriber` `reload.rs:289-297`,
  K01; tokio-rs/tracing#1629). The body and the filter are therefore reloaded through separate
  handles.

```rust
// Binary crate only; the library crate never installs a subscriber and writes no file
// (R67 layering, inputs/PARAMETERS.md:16).

// (a) Inside R58's telemetry::init, which runs first in main: the R59 sink slot, installed empty
//     beside R58's per-layer-filtered console layer. init returns the two handles with its own.
type FileBody = Option<Box<dyn Layer<Registry> + Send + Sync>>;
let (file_filter, file_filter_handle) = reload::Layer::<LevelFilter, Registry>::new(LevelFilter::OFF);
let (file_body, file_body_handle) = reload::Layer::<FileBody, Registry>::new(None);
let sink_slot = file_body.with_filter(file_filter).boxed();

// (b) In main, after R54 has resolved the configuration and member 3 has resolved the path, the
//     level and the format (flag > env > config > off):
if let Some(p) = log_file_path {
    match RotatingFile::open(&p, ROTATE_MAX_BYTES, ROTATE_BACKUP_COUNT) {
        Err(e) => eprintln!("warning: log file {}: {e}", p.display()), // D6: best-effort sink, as R67's crash record
        Ok(w) => {
            let l = fmt::layer().with_writer(Mutex::new(w)).with_ansi(false);
            let body: Box<dyn Layer<Registry> + Send + Sync> = match file_format {
                // R58's redacting formatters (telemetry::redact); never the stock .json().
                FileFormat::Text => l.fmt_fields(HumanFields(DefaultFields::new())).log_internal_errors(true).boxed(),
                FileFormat::Json => l.event_format(JsonEvent).fmt_fields(JsonFields).log_internal_errors(true).boxed(),
            };
            let _ = file_body_handle.reload(Some(body)); // body first, then the filter (K05)
            let _ = file_filter_handle.modify(|f| *f = file_level);
        }
    }
}
```

`JsonEvent` and `JsonFields` are written as unit values here. Their constructors are R58's to
define. A failed `reload` or `modify` returns `Err` only when the subscriber is gone or a lock is
poisoned. The sketch ignores it, so the file sink stays best-effort, as D6 requires.

**The floor is a rule, not a computation.** With per-layer filters, `tracing-subscriber` sets the
global maximum to the most verbose layer filter (A01, A05). A registry-level
`LevelFilter::WARN` added beside them still reports `current=debug`, but the file **loses** the
debug event (A07–A09). The idiomatic Rust shape of py's `min(level, file_level)` is therefore that
every level control, R58's console level included, is a per-layer filter. This is recorded as a
constraint on R58 under `## Parameters`. **Carried, not checked:** `tracing`'s compile-time
`max_level_*` / `release_max_level_*` features cap every sink, so the template must not enable one
below `debug` (`raw/opus.md:221-223`).

**Initialization order (revision 4: install first).** The steps run in this order:

1. Parse the arguments, and resolve R58's console ladder from the flags and the environment.
2. Call `telemetry::init(Profile::Cli { .. })` first, before anything that can log. It installs
   the console layer and the empty R59 sink slot, and it never panics (`R58-r2:1485`,
   INITIALISATION).
3. R54 discovers and merges the config. A config-discovery problem can now be logged to the
   console. It still ends the command through R67's error path.
4. R58 swaps the console level from the config through its level handle (`R58-r2:1485`,
   RECONFIGURATION). Member 3 resolves the file path, `file-level` and `file-format`.
5. If a path resolves, open `RotatingFile`, then fill the slot: reload the body first, then modify
   the filter.

Revision 3 named this reload handle at `:553-556` as the ranked alternative, "only if R58 needs
logging before config discovery". R58 does (`R58-r2:474-477`), so the S1 ruling adopts it.
Check K executes it:

- With the slot empty, `current` is the console level, and no file exists (K03, K04).
- After the slot fills, `current` is the file level (K06, K09).
- Events emitted before step 5 reach the console only (K07).

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
that cannot collide with the console's format setting. **Key home (revision 4).** R58's
revision 2 leaves `[logging]` keys beyond `level` to R54 and R59 (`R58-r2:1538-1539`). R58 selects
the console format through `--log-format` and `RSLBP_LOG_FORMAT`, and no config-file tier appears
in its contract (`R58-r2:1485`, LEVEL LADDER). R59 therefore owns the `file-format` key, jointly
with R54's schema. The ledger row and any py rename are the controller's to adjudicate. The affected
items are R59, R58 (which owns the console's `--log-format`), R54 (the config schema) and the py
follow-on. Opus's line above, which says "leave [logging] format to R58's console format", is
quoted verbatim and not edited.

re-verify: on the earliest of — R58's revision 4 (mandatory: it aligns the `R58-r2:1005` illustration with the per-layer promise at `R58-r2:654-657` that member 2 relies on, and must keep the sink slot, its per-layer filter, the install-first `telemetry::init` that never panics, and the `HumanFields`/`JsonEvent`/`JsonFields` formatters adopted here; it must also say how `init` hands out the sink slot's two reload handles); R58's accepted decision (it confirms the adopted revision-2 value byte for byte, check J); R54's accepted decision (what "resolved config" contains
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
- assumes logging-pipeline-contract = logging-pipeline/v1: STACK - tracing 0.1.44 is the only diagnostic facade any package may name, taken default-features = false, features = ["std"] by rs-launch-blueprint-core and rs-launch-blueprint-web and with its defaults (std, attributes) by the root package rs-launch-blueprint and rs-launch-blueprint-cli; tracing-subscriber 0.3.23 with features = ["env-filter"] over its default set (smallvec, fmt, ansi, tracing-log, std) is declared on the root package only, with the json feature OFF because the template owns the structured formatter and the feature adds exactly two crates (serde, tracing-serde) for a formatter it replaces, and with local-time NEVER enabled because the crate's own documentation says the local-offset lookup may be unsound or fail; timestamps are UTC ISO-8601; tracing-log 0.2.0 enters through tracing-subscriber's default tracing-log feature and is never declared directly; no other logging crate is added; crates/core, crates/cli and crates/web must not name tracing-subscriber, enforced by R02's cargo deny --all-features check bans [bans] deny[].wrappers rule and its crates/core allow-list test; the version floor is 0.3.20, RUSTSEC-2025-0055's patched floor. INITIALISATION - exactly one telemetry::init(Profile) -> Init in the root package's src/telemetry.rs, called first in each binary's main before anything that can log; it builds Registry::default() with a reload::Layer<EnvFilter> and one fmt layer whose writer is stderr, and first checks tracing::dispatcher::has_been_set(): if a dispatcher is already set, a host owns diagnostics, nothing is installed and init returns Init::HostOwned; otherwise it installs with SubscriberInitExt::try_init() and NEVER init(), which is try_init().expect(..), returning Init::Installed(Handles { level: reload::Handle<EnvFilter, Registry>, log_bridge_refused: false }) on Ok and Init::Installed(Handles { level, log_bridge_refused: true }) on Err, because try_init sets the global dispatcher before it installs the log bridge, so an Err after a clear check means only that a host already owns the log logger while the template's dispatcher is live; init never panics, never replaces and never tears down anything; template code never calls tracing_log::LogTracer::init(), because try_init already installs the bridge with the subscriber's max-level hint and a second installation fails with SetLoggerError; tests and embedders use the scoped set_default guard instead of the global path. RECONFIGURATION - the level is swappable after the configuration file is read, through the returned reload::Handle, which is how F274's config tier is reached without logging being absent while the configuration file is parsed; the format and the writer are fixed at init and are not reloadable, a deliberate departure from py's handler-replacement model recorded as a migration risk. STRUCTURED-FIELD AND REDACTION CONTRACT - key-based masking is applied at format time, not event time, because a tracing::Event is immutable, RecordFields is a sealed trait and no Layer can rewrite an event; the key vocabulary is F252's verbatim (token, password, secret, authorization, api_key, apikey, credential, cookie, matched as an ASCII-lowercased substring) and the mask is [REDACTED]; the human profile uses a template-owned FormatFields wrapping DefaultFields, and the structured profile uses a template-owned FormatEvent plus a template-owned JSON FormatFields, because tracing-subscriber's stock Format<Json> serialises event fields itself through tracing_serde in both its flattened and non-flattened branches and uses its N: FormatFields parameter only for span fields, so a redacting field formatter under .json() leaks every event field and panics if its output is not valid JSON; secrecy::SecretString (R56 revision 2) is the type-level first line of defence and the key match is the second; the structured line's key order is level, target, the R78 trace-correlation slot, the event's own fields, then span; the HTTP correlation field is named request_id, matching CLI Design Standard R7.8's spelling, while the wire header stays request-id per REST API Design Standard R11.7 and section 1.10; redaction is a property of rendered output, so any later exporter layer must apply the policy itself; and the residual gap - a secret carried inside a non-sensitive field's value is not masked - is recorded as OVERRIDE (OV-09) against CLI Design Standard R5.6. PROFILES (one engine, two policies; one subscriber per process, since each front end is its own binary) - Profile::Cli for the CLI binary R49 names: format auto, console or json, where auto resolves to console when std::io::stderr().is_terminal() and to json otherwise, colour from R65's resolved anstream::ColorChoice passed to .with_ansi(bool), default level WARN; Profile::Service { level, format } for the serve binary R69 gates: format from RSLBP_WEB_LOG_FORMAT, whose value set is json (the default) or console with no auto and no TTY test, any other value rejected by the FromStr R77's WebSettings::from_env() calls as R67's RSLB203 before init runs; default level INFO; no file sink; level and format are the values R77's WebSettings::from_env() parsed from RSLBP_WEB_LOG_LEVEL and RSLBP_WEB_LOG_FORMAT and passes in, and telemetry reads no environment variable itself; plus R75's request-span layer. LEVEL LADDER (F274), one total order, highest first, with every command-line flag above the environment variable as CLI Design Standard R5.1 requires - --debug (TRACE plus internal detail: target, file, line, thread) > --log-level with the values off, error, warn, info, debug and trace > --quiet/-q (ERROR) > -v/-vv/-vvv (INFO/DEBUG/TRACE) > RSLBP_LOG_LEVEL > config-file [logging].level > default WARN; --log-format with the values auto, console and json, plus RSLBP_LOG_FORMAT, selects the render mode by the same deterministic flag-to-environment mapping. STREAMS - every diagnostic byte goes to stderr and stdout is never written by the pipeline, per CLI Design Standard R7.1 and R67's requirement that stdout stays byte-empty on the error path; the pipeline never emits R67's error envelope, which the error boundary owns. EXTENSION INTERFACE - two declared slots with nothing decided in them: a layer slot in telemetry::init where R78's tracing-opentelemetry layer attaches under an otel = ["web", ...] feature nesting on R69's web, with a matching trace_id/span_id serialisation point in the owned FormatEvent, and with W3C traceparent propagation deliberately NOT gated by that feature because REST API Design Standard R11.8 requires it unconditionally on the HTTP surface; and a sink slot where R59's file sink attaches as a second Layer with its own MakeWriter and its own per-layer Filter, which is how a sink gets a level independent of the console.

**The adopted value (revision 4).** The `logging-pipeline-contract` line above is R58's
revision-2 owned value, adopted verbatim under the S1 ruling. Its prefix `- owns` was swapped for
`- assumes`, and every byte after `= ` is `R58-r2:1485`'s (check J, J01–J05). The run's frozen
registry row still reads `—` (`inputs/PARAMETERS.md:18`). That is point-in-time input, and under
§7.7 the difference is disclosed, not re-pinned. The five-part working assumption of revision 3
now resolves against the adopted value as follows:

1. **Stack:** `tracing` 0.1.44 + `tracing-subscriber` 0.3.23 on a `Registry`, with `json` off.
   Settled by the STACK clause.
2. **The console level is a per-layer filter, and no registry-level filter narrower than every
   sink exists** (A07–A09 show what breaks otherwise). R58 promises this at `R58-r2:654-657`, and
   its illustration at `R58-r2:1005` does not match. Per the S1 ruling the promise governs, with a
   re-verify trigger on R58's revision 4 (member 2).
3. **Only the binary installs the subscriber**, through `telemetry::init`, first in `main`, and
   `init` never panics. The file sink fills R58's sink slot after config resolution, through a
   reload slot. This replaces revision 3's "once, after config resolution" (INITIALISATION,
   RECONFIGURATION and EXTENSION INTERFACE clauses; K01–K11).
4. **Redaction:** the file layer uses R58's formatters, `HumanFields` for text and `JsonEvent` +
   `JsonFields` for JSON. It never uses the stock `.json()`, which leaks event fields (redaction
   clause).
5. **Key homes:** `[logging] level` is R58's config rung (`R58-r2:506`). `[logging]` keys beyond
   `level` are R54's and R59's (`R58-r2:1538-1539`). R59 owns `file`, `file-level` and
   `file-format`.

**Fallback branch — not taken.** If R58 had selected a `log`-facade pipeline, members 1 and 2
would become `flexi_logger` 0.31.10 (`Criterion::Size(10 MiB)` + `Cleanup::KeepLogFiles(5)`),
re-gated at that time. The adopted value selects `tracing`. **No `CONFLICT:` line.** Every adopted
clause is usable as written. The per-layer console filter is R58's own promise; the only mismatch
is R58's illustration, which is left to R58's revision 4.

**Other upstream answers relied on (not registered parameters):**

- R57 — default path `state_dir().join("rslbp.log")`, **carried** from `raw/opus.md:34-36`, with
  the explicit-path-only fallback (P8).
- R54 — assumed to deliver a fully merged config before the file sink attaches. Revision 4:
  logging itself is installed before config discovery.
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
         precedence msrv bench live-figures reload-slot contract-adopt; do
  "$E/r59-$c.sh" > "$E/r59-$c.log" 2>&1
done
```

**Observed output (revision 4, run 2026-09-28 UTC).** Every script exited 0. `shellcheck -x`
over all 14 scripts, including the helper, exited 0 with no finding. **13 checks, 137 assertions,
0 failed, 0 skipped.** Checks K and J are new in revision 4. Check J reads only and builds
nothing, and it must run after `review/DECISION.md` is final, because it compares that file's
`assumes` line.

| Check | Log | What it establishes | Assertions |
|---|---|---|---|
| T | `r59-toolchain.log` | Toolchains and host; the floor argument above | 4/4 |
| S | `r59-source-reads.log` | Published source lines at the pinned versions, each printed: `file-rotate` panic and `.ok()` sites, `tracing-subscriber`'s `log_internal_errors` default, `tracing-appender`'s time-only `Rotation`, the `unsafe` census | 22/22 |
| P | `r59-deps.log` | `file-rotate`: 2 direct normal deps (`chrono`, `flate2`), 11 packages including itself, `flate2` always compiled; 10 packages, `file-rotate` itself included, not in `tracing-subscriber`'s set; the owned writer adds none | 5/5 |
| W | `r59-writer-contract.log` | The member-1 table: rotation layout, torn records, every failure mode, B8 end to end | 29/29 |
| A | `r59-floor.log` | The floor: per-layer, no file, registry-level filter, JSON | 11/11 |
| E | `r59-ansi.log` | 12 escape bytes by default, 0 with `.with_ansi(false)`, user escape bytes escaped | 3/3 |
| C | `r59-exit-durability.log` | 1,000 records then `process::exit(0)`: owned 1000×3, `file-rotate` 1000×3, `non_blocking` 48/0/182 (105/0/87 in the revision-4 log), `non_blocking` with the guard dropped 1000×3 | 4/4 |
| G | `r59-precedence.log` | 8 resolver tests pass on 1.98.1 | 3/3 |
| H | `r59-msrv.log` | Build and 8 tests pass on 1.96.0 | 4/4 |
| D | `r59-bench.log` | Indicative throughput (only completion is asserted) | 3/3 |
| L | `r59-live-figures.log` | crates.io, GitHub REST and RustSec figures; the CI OS matrices behind the gate-4 exclusions; the README lineage; tracker states; `file-rotate` responsiveness | 22/22 |
| K | `r59-reload-slot.log` | Revision 4. The reload sink slot: `reload.rs:289` says a `Filtered` layer cannot be reloaded; installing with the slot empty gives `current=warn` and no file; body reload plus filter modify return `Ok`; after that, `current=debug`, the file holds only post-attach events, and the console holds no debug. Text and JSON bodies | 11/11 |
| J | `r59-contract-adopt.log` | Revision 4. The R58 revision-2 snapshot sha is the pinned value; the `assumes` line equals prefix-swapped `R58-r2:1485` byte for byte (`cmp`, 6,835 bytes); the owned text says `json` OFF, install first, never panics, format and writer fixed at init, `JsonEvent`/`JsonFields`, and an R59 sink slot with a per-layer filter; the cited R58 lines `:633`, `:654-657`, `:1005` and `:1538-1539` hold what revision 4 says; exactly one `re-verify:` line | 16/16 |

**Reproducibility.** The **assertion outcomes** of checks T, S, P, W, A, E, G, H, K and J are
deterministic on this host; the complete log bytes are not. The rerun differences in those checks
are the `run (UTC)` line, Cargo and scratch paths, event timestamps in A and E, test print order in
G, compile duration in H, and process IDs in W. C's
`non_blocking` counts vary by run; only "fewer than 1,000 in every run" is asserted. D's timings
vary; only completion is asserted. L prints live counters without asserting them, so a rerun
differs there by upstream drift, not by defect. Its assertions cover only facts expected to stay
stable for this decision's life.

**Replay note, 2026-09-27 (revision 3; from `review/audit-codex.r2.md:27-65`).** The empirical
audit reran all 11 checks between 17:47 and 17:48 UTC on 2026-09-27, with fresh logs under `/tmp`.
The paired evidence logs here are unchanged.

- Byte comparison: `cmp` reported a difference for **11 of 11** paired logs. The first differing
  line in every pair is `run (UTC)`.
- Assertion outcomes: **110 of 110** passed, 0 failed, 0 skipped. The `PASS`, `FAIL` and `SUMMARY`
  line streams were byte-identical in all 11 pairs.
- Dynamic values that changed: C's live-guard `non_blocking` counts, `48 0 182` → `164 180 187`
  (still below 1,000 in every run); D's timings, and its `cpu:` label, `Apple M4 Pro` → `arm64`
  through the script's `uname -m` fallback; L's `tracing-subscriber` recent/all-time downloads,
  `146641301/627181762` → `147308191/627848048`. L's newest versions, repository fields, CI
  matrices, `file-rotate` issue sample and advisory statuses were unchanged.

**Replay note, 2026-09-28 (revision 4).** This worker reran all 11 original checks **into their
paired logs**. The revision-1 log bytes were overwritten, and no copy survives in the repository.
The logs now hold the 2026-09-28 run, and `R59-r3-snapshot.md` preserves the prose that cites the
revision-1 values. Four checks were rerun without any input change: T, S, P and L. Rerunning them
was not necessary.

- Assertion outcomes: **110 of 110** passed, 0 failed, 0 skipped. The `PASS`, `FAIL` and `SUMMARY`
  line streams are byte-identical, **11 of 11**, to the revision-1 empirical audit's rerun logs,
  which survive under `/tmp/r59-audit-claude/` (`review/audit-claude.md`). The probe change
  therefore altered no existing assertion.
- Line positions: every log line this decision cites by number still holds the same field:
  `r59-live-figures.log:12, 13, 28, 65`, `r59-writer-contract.log:90, 96`, `r59-deps.log:20-36`,
  `r59-bench.log:8-19` and `r59-source-reads.log:9, 17`.
- Dynamic values that changed (revision 1 → revision 4):
  - C's live-guard `non_blocking` counts, `48 0 182` → `105 0 87`. They are still below 1,000 in
    every run.
  - D's emit timings, in ms per 100,000 events. Owned blocking: `195/198/322` → `233/210/212`.
    `file-rotate` `BytesSurpassed` blocking: `200/192/193` → `293/233/424`. Owned plus
    `non_blocking`: `46/46/46` (totals `152/149/149`) → `46/47/48` (totals `164/164/233`).
  - L's `tracing-subscriber` recent and all-time downloads, `146641301/627181762` →
    `148039380/630176174`. `tokio-rs/tracing` stars `6,891` → `6,893`, and open issues `628` →
    `630`. The retrieval date on `:5` is now 2026-09-28.
  - The newest versions, CI matrices, README lineage, `file-rotate` issue sample (median 1.9 days)
    and advisory statuses are unchanged.
- The prose figures above are **not** updated to these values. They remain the 2026-09-27
  retrieval that revision 1 cited. The revision-4 note's observations cover what this means for
  D8.

**Not proven here:**

- anything on `ubuntu-latest`;
- a binary-level test through `clap` (AC1, AC3, and AC8's warn-and-continue branch);
- AC7 redaction;
- the reload slot inside R58's actual `telemetry::init`, with R58's `EnvFilter` console layer and
  R58's `HumanFields`/`JsonEvent`/`JsonFields` (K used a per-layer `LevelFilter` stand-in console
  and the stock formatters);
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
re-derivation.** Muse concedes the constructor `expect` and the zero-limit `assert` and proposes a
validation wrapper (`raw/muse.md:78`). Opus measured two panics and a silent drop
(`raw/opus.md:164-174`). This synthesis reproduced two of the three as stated: W12–W13 reproduce
Opus's constructor panic, and W15–W16 its silent drop. Opus's second panic, "if the log directory
is deleted mid-run and cannot be recreated, `rotate()` panics in `ensure_log_directory_exists`"
(`raw/opus.md:409`, `:167`, `:768`), was **not** reproduced as stated: with the directory removed
but recreatable, `file-rotate` self-heals (W19). W20–W21 is the proxy used here for "cannot be
recreated": a file blocks the path, and the panic fires at `src/lib.rs:553`
`assert!(old_path.exists())`, not at Opus's locus `ensure_log_directory_exists` (`:446`). Opus's
probe under `/tmp/r59-opus` was not read, so the setup difference is unresolved. This synthesis also found a fourth defect that
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
logging (`raw/muse.md:134`, `raw/opus.md:654-655`). **Revision 4, re-pointed by the S1 ruling:**
R58 does need earlier logging. Its revision 2 installs first, in `telemetry::init`
(`R58-r2:474-477`, `:1485` INITIALISATION). The condition both legs named is therefore met, and
the reload alternative is taken. It is executed as the sink slot in check K (K01–K11).

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
  is a config error. R67 maps an I/O failure to `RSLB101`/1 when that failure ends the command.
  For a best-effort diagnostic sink, R67's own crash-record clause ("a write failure never
  changes the envelope or the exit code", `inputs/PARAMETERS.md:16`) sets the precedent this
  decision follows: an unopenable log path is a stderr warning, and the exit status is unchanged.
- The user asked for diagnostics, not for the command to fail. The stderr warning tells them the
  file was not written.

This is the most reversible choice in the decision. If the owner rejects this choice, the branch
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
rule, which never tears a record (W02) and stays within the limit for the tested 78-byte records
(W03); one record larger than the limit can exceed it (member 1).

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

1. R58 is not accepted. Revision 4 adopts R58's revision-2 owned value from the pinned snapshot
   (check J), so this decision stays conditional on R58's acceptance and on R58's revision 4
   (member 2's re-verify trigger).
2. No run on `ubuntu-latest`.
3. No binary-level test (AC1, AC3, AC8).
4. AC7 is designed in: the adopted contract defines the redacting formatters. It is not tested
   here, because R58's formatters are R58's code.
5. Real two-process rotation was not run.
6. py, ts, R57 and the org standard were not read (read-set constraint); the claims resting on them
   are carried.
7. Current stable was not fetched; the floor is argued from the installed toolchain.
8. The env prefix is unregistered, and R64 (`RSLB_`) and Opus (`RSLBP_`) disagree.
9. This run's policy snapshot and manifest pre-date owner decision Q17.A, which authorizes the Muse leg.
10. `flexi_logger`'s rotation is untested by anyone.
11. The `tokio-rs/tracing` issue-responsiveness sample (member 2; revision 3) was taken from a
    `/tmp` copy of check L's sampler and is not in a committed evidence log. Its association rule
    (`OWNER`, `MEMBER`, `COLLABORATOR`) may undercount maintainers whose organization membership
    is not visible to the API; one reply on #3613 carries `CONTRIBUTOR` and is not counted.
12. The directory-removed and directory-blocked cases were probed only at a 64-byte limit (W17–W21,
    W26–W29). At 10 MiB their behavior is argued, not observed. For `file-rotate`, a pre-rotation
    write returning `Ok` into the unlinked file was observed at 64 B (`r59-writer-contract.log:90`,
    `:96`); the rest rests on S02, S04 and S06. For the owned writer, it rests on probe
    `src/lib.rs:46, 53, 63`. Revision 2 deliberately reran no probe, to keep the approved evidence
    stable.
13. Revision 4. R58's revision-2 `Handles` has no field for the sink slot's two reload handles,
    so how `telemetry::init` hands them to `main` is unspecified. Revision 4 proposes the slot
    shape, and R58's revision 4 must confirm it (re-verify trigger).

**What P03 must validate:**

1. Port W01–W05, W11, W14, W17, W18, W22 and W23 as `#[test]`s using `tempfile`, and run them on
   `ubuntu-latest` and `macos-latest`. Include the boundary case of a record that exactly reaches
   the limit. Add the directory-removed case with no rotation pending (expect `Ok` until a forced
   rotation, then `Err` until restart), which closes gap 12. Add an oversized-record case: one
   record larger than the limit, written to an empty file, is written whole and exceeds the limit
   (expected behavior; the bound is conditional on record size).
2. The A01–A09 floor tests and the K02–K11 reload-slot tests, run against R58's actual console
   layer and `telemetry::init`.
3. Binary-level tests: AC1 (no file without enablement), AC3 (a bare flag under
   `XDG_STATE_HOME=<tmp>` writes the default path) and AC8 (an unopenable path produces a stderr
   warning and an unchanged exit status).
4. AC7: `info!(token = "s3cr3t")` must not appear in the file, in either the text format
   (`HumanFields`) or the JSON format (`JsonEvent` + `JsonFields`).
5. A test that the file layer carries `.log_internal_errors(true)` (W28, W29).
6. A two-process rotation test with two concurrent invocations of the binary.
