# Raw research answer — R59 file-log-sink (Muse engine, 2026-09-26)

### Landscape

Category: an optional rotating file log sink attached to the template's console/structured logging pipeline (R58's pipeline), reproducing py's `[logging]`-driven size-plus-backup-count file handler as a native Rust design.

Three-bin map of the Rust field (all figures retrieved 2026-09-26):

- Built-in / first-party toolchain: no `std` rotation facility exists; the closest first-party piece is `tracing-appender` 0.2.5 (tokio-rs/tracing; 90-day downloads 33,200,763, total 118,847,955, MIT, rust-version 1.63.0, via `GET https://crates.io/api/v1/crates/tracing-appender`). Its `RollingFileAppender` rotates on time only — `Rotation::{MINUTELY, HOURLY, DAILY, WEEKLY, NEVER}` plus a count-based `max_files` retention prune — verified in `tracing-appender/src/rolling.rs` (no size trigger; the only `size`/`byte` tokens are `usize`/`&[u8]` plumbing). Its `non_blocking` writer is first-party async-safe plumbing reused by this item's recommendation, but its roller cannot satisfy the size-plus-backup-count policy.
- Established industry standard: `file-rotate` 0.8.0 (90-day 1,090,531, total 5,647,037, MIT, via crates.io API), a dedicated rotation writer with `ContentLimit::{Bytes, BytesSurpassed, Lines, Time, None}` plus `AppendCount::new(max_files)` and `Compression::{None, OnRotate}` (verified in `kstrafe/file-rotate` `src/lib.rs`, `src/suffix.rs`, `src/compression.rs`; zero `unsafe` in all three files) and an `impl Write` that plugs into any subscriber layer; `flexi_logger` 0.31.10 (90-day 3,472,842, total 24,316,996, MIT OR Apache-2.0, rust-version 1.87.0) with `Criterion::Size(u64)` rotation (verified in `src/parameters/criterion.rs`) but architected as a full `log`-facade backend; `log4rs` 1.4.0 (90-day 1,939,415, total 23,307,411, MIT OR Apache-2.0, rust-version 1.75) with `SizeTrigger` + `FixedWindowRoller` (verified in `src/append/rolling_file/policy/compound/`), likewise a full `log` backend; `fern` 0.7.1 (90-day 8,252,512, total 48,674,748, MIT) and `simplelog` 0.12.2 (90-day 3,033,457, total 26,983,323), both without size-plus-backup-count rotation.
- Up-and-comer: `tracing-rolling-file` 0.1.3 (90-day 637,787, total 1,716,609, MIT/Apache-2.0; repo `cavivie/tracing-rolling-file`, 12 stars, pushed 2025-08-16), a purpose-built size-based rolling appender (`RollingCondition` + `condition_max_file_size` + `max_filecount`, Debian-style `basename.N` retention, optional `non-blocking` feature wrapping `tracing_appender::non_blocking`; verified in `src/lib.rs`, zero `unsafe` there). No other size-based tracing-native candidate surfaced from the landscape.

Authorities and why each counts: (1) the tokio-rs/tracing monorepo source itself for what the first-party roller can and cannot do (maintainer-owned, definitive for capability); (2) crates.io API download/version/dependency records for adoption scale and dependency-tree facts (registry ground truth); (3) GitHub API repo/CI/issues records for maintenance state, OS coverage, and maintainer responsiveness (primary project telemetry); (4) rustsec.org package pages for advisory state (authoritative Rust advisory source; a GitHub-Pages 404 means no advisory page exists for the package); (5) adopter `Cargo.toml` files read via the GitHub API for production-use proof (primary adoption evidence).

Practice evidence (well-regarded = high-adoption or prominent-maintainer projects, adoption verified in their `Cargo.toml` or the crates.io reverse-dependency edge on 2026-09-26): czkawka (`qarmin/czkawka`, widely used file cleaner; `czkawka_core/Cargo.toml` pins `file-rotate = "0.8.0"`); oura (txpipe Cardano pipeline tool; root `Cargo.toml` uses `file-rotate 0.7.5`); Autonomi `sn_node`/`ant-logging` (top crates.io reverse-dependents of `file-rotate`); zellij (`zellij-org/zellij`, popular terminal workspace; `zellij-utils/Cargo.toml` uses log4rs with exactly `rolling_file_appender + compound_policy + fixed_window_roller + size_trigger`); qsv (popular CSV CLI; root `Cargo.toml` uses `flexi_logger 0.31`) and cargo-leptos (top reverse-dependent of `flexi_logger`); aws-sdk-s3 / lambda_runtime (top reverse-dependents of `tracing-appender`, evidencing the non-blocking writer's production standing). `tracing-rolling-file` has only 4 tiny reverse-dependents (`k8sql`, `wasmind_cli`, `genja-core`, `iotmq`), so its 1.7M total downloads reflect direct use, not ecosystem adoption — a stated weakness.

Fit framing: the template is CLI + library + web service; the file sink must attach to R58's pipeline as an optional second sink (py parity), stay off unless configured (ts simplicity preserved by default), bound disk usage by size and count (the py policy), and work identically for CLI runs and the long-lived web service. Judged against that use case — not "best logger in general" — a rotation *writer* composed under R58's subscriber beats a second full logging backend.

### Principles and implementation

Shared requirement (source: py F255–F261 plus owner direction 2026-09-04 "best-in-class logging … same principles … applied to TypeScript and Rust"; agreement level: **capability**): every blueprint flavor offers optional, bounded, independently-leveled durable log capture. Essential behaviors: (a) a `[logging]` config section carrying at least `file`/`file_level` (F255 subset owned here; `level`/`format` shared with R58); (b) a `--log-file` flag/env defaulting to an XDG state path (F258); (c) flag/env > config `logging.file` > off precedence (F259); (d) an independently settable file-sink format (F260); (e) a dual-sink level floor so neither sink starves the other (F261); (f) size-plus-backup-count rotation bounding disk (F256/F257). Observable acceptance criteria: with `logging.file` unset and no flag, no file is created; with either set, logs append to the resolved path; exceeding the size cap produces `basename.1..=N` and never more than N backups; console and file levels filter independently; config-file format and flag/env format can differ.

What must agree vs what may vary: the capability, the precedence chain, independent per-sink level/format, and bounded-disk rotation must agree across py/ts/rs. The rotation numbers SHOULD agree (10 MiB / 5 backups, see below) because the disk-budget tradeoff is identical in all three ecosystems — the evidence supports the same tradeoff, so a shared value is justified. The mechanism (crate) necessarily varies by ecosystem. ts's current absence of any file sink is a **missing capability**, not a justified ecosystem difference: nothing about Node.js makes durable opt-in logs inappropriate (the ts CLI already has workspace-scoped state and a config schema that could carry the section), and the owner's best-in-class direction explicitly asks for the principle to be applied to TypeScript. ts gains the capability as a follow-on project; this answer supplies the rationale and the agreed contract (precedence, floor, rotation bounds).

Architectural alternatives compared before choosing libraries: (A) **Second subscriber layer + rotating writer** (recommended): R58's subscriber gains an optional `fmt` layer writing through a size-rotating `io::Write` (non-blocking wrapped). One pipeline, per-sink filtering, minimal new dependency surface (one small crate). Production analogue: czkawka/oura compose `file-rotate` writers into their apps; zellij runs size+window file rotation in production. (B) Full `log`-backend file logger (flexi_logger/log4rs) alongside the pipeline: rejected — it would run a second backend next to R58's pipeline (dual configuration, dual filtering, fights R58 ownership); both candidates are kept as the conditional fallback if R58 selects a `log`-facade pipeline. (C) Time-based rotation via `tracing-appender` rolling: rejected — it cannot express the agreed size-plus-count disk bound (verified time-only above); switching policy to daily rotation changes the cross-repo contract without justification. (D) No file sink (match ts; defer to external logrotate/journald): rejected as the default — a template CLI needs self-contained diagnostics (support bundles, bug reports from user machines without logrotate) and the web service needs bounded local capture independent of platform plumbing; documented as the operator escape hatch (set rotation wide or disable the sink), and ts keeps stderr-only until its follow-on.

R58-conditional design (R58 `logging-pipeline-contract` is undecided; prerequisites record `missing`): this answer is designed against the expected `tracing-subscriber` `Layer` composition contract — the near-certain R58 shape given `tracing-subscriber` 0.3.23's standing (90-day downloads 147,886,240 via crates.io API) — where a file sink is a second `fmt` layer with its own writer and filter. If R58 instead selects a `log`-facade pipeline, member 1's recommendation switches to the ranked runner-up path (flexi_logger file writer or log4rs rolling appender, re-gated at that time); the member-2 wiring contract (precedence, floor semantics, rotation numbers) is unchanged. No `CONFLICT` is filed because there is no registered value to challenge.

R57-conditional default path (R57 related, not consumed): assume R57 provides a state directory and default `--log-file` to `<state-dir>/<app>.log`; fallback if R57 concludes no state directory exists: no default path — the sink is flag/config-only (explicit path required), preserving "off unless configured" without deciding R57's question.

MEDIUM — init order vs R54/R58: the file sink initializes in a **second pass after config resolution**. Single construction after the config is fully resolved is preferred (flag/env > config > off needs the merged config, which needs R54's discovery tiers); pre-config startup failures fall back to stderr (R58's bootstrap path owns that detail). A same-pass wiring is impossible in general because the console sink must exist before config errors can be reported. R58 owns final init-order; this item requires only that the file layer attach point be available post-resolution (constructor parameter or `reload`-style handle, R58's choice).

MEDIUM — dual-sink floor in a subscriber model: **automatic** with per-layer filters, no explicit `min()` computation. Each `fmt` layer carries its own `LevelFilter` (console `level`, file `file_level`); the subscriber dispatches each event to every layer, and each layer filters independently — the union semantics subsume py's `root.setLevel(min(level, file_level))`. An explicit floor computation appears only if R58 sets a single global `max_level`; in that case the global must be the most verbose of the two levels. Recommend per-layer filters so the floor is structural, with a test asserting a DEBUG file + WARN console pair delivers DEBUG records to the file only.

LOW — rotation numbers: match py exactly — 10 MiB per file (`ContentLimit::BytesSurpassed(10 * 1024 * 1024)`), 5 backups (`AppendCount::new(5)`), no compression by default. No surveyed Rust crate default contradicts this meaningfully (`file-rotate` takes both as constructor parameters with no opinionated default; `tracing-rolling-file` likewise parameterizes both), and identical numbers keep the cross-repo disk-budget contract literal. `BytesSurpassed` (rotate after completing the Source write past the cap) is preferred over `Bytes` (split mid-write) so no log line is ever torn across files.

Minimal realistic example (proposed, not executed — this leg ran no code): a CLI with `[logging] file = "app.log"` + `--log-file` override writing through the composed subscriber; acceptance check: emit 12 MiB of events, assert `app.log` + `app.log.1..=5` exist, total on-disk size is bounded near 60 MiB, no torn lines (every line parses as one record), and removing the flag leaves no file. No `BASELINE-REVIEW` findings: no recorded baseline is challenged; pipeline ownership stays with R58.

### Recommendation

Ship the optional rotating file sink (py parity, off by default): `file-rotate` 0.8 (`FileRotate<AppendCount>` + `ContentLimit::BytesSurpassed(10 MiB)` + `AppendCount::new(5)` + `Compression::None`) as the rotating writer, wrapped in R58's non-blocking writer and attached as a second per-layer-filtered `fmt` layer; `[logging] file`/`file_level` config keys; `--log-file` / `PLBP_LOG_FILE` with flag/env > config > off precedence and an XDG-state-path default (flag/config-only fallback if R57 provides no state dir); independently settable file format; structural per-layer level floor (explicit most-verbose global only if R58 uses a global max level).

### Members

#### rotating-file-writer (size+backup-count rotation crate)

##### Landscape

Sub-category: size-triggered file rotation with a bounded backup count, composable as a writer under an R58-owned subscriber. Bin map: first-party — none (`tracing-appender` rolling is time-only, verified above); established — `file-rotate` 0.8.0, `flexi_logger` 0.31.10 (`Criterion::Size`), `log4rs` 1.4.0 (`SizeTrigger`+`FixedWindowRoller`), `fern`/`simplelog` (no size rotation, surveyed and excluded); up-and-comer — `tracing-rolling-file` 0.1.3 (native tracing size-based roller). Every shortlisted candidate comes from this map. Authorities: crate sources via the GitHub API (capability ground truth), crates.io API (adoption/dependency facts), GitHub CI/issues (maintenance/OS telemetry), rustsec.org (advisories), adopter `Cargo.toml` files (production proof).

##### Principles and implementation

The writer must implement exactly the agreed disk-bound policy — rotate at a byte size without tearing records, retain at most N backups, create parent dirs or fail loudly, stay allocation-light on the write path — while remaining a passive `io::Write` the pipeline owns (filtering, formatting, and dispatch stay in R58's layers). `file-rotate` 0.8.0 matches py's `RotatingFileHandler(maxBytes, backupCount)` point for point: `BytesSurpassed` ≈ rotating after the cap (py rotates before a write that would exceed; both keep every file near the cap and never tear a record — a justified 1-line semantic difference preserving the principle), `AppendCount(max_files)` ≈ `backupCount`, `app.log.N` suffixing ≈ py's `.1` backup naming. `tracing-rolling-file` matches equally well functionally but is 0.x/immature. flexi_logger/log4rs match the policy but bundle a whole `log` backend, violating the passive-writer principle unless R58 itself is `log`-based.

##### Dominant choice

`file-rotate` 0.8.0 (MIT; `kstrafe/file-rotate`; 90-day downloads 1,090,531, total 5,647,037; newest non-yanked 0.8.0 released 2025-02-27; all via `GET https://crates.io/api/v1/crates/file-rotate` and `.../versions`, retrieved 2026-09-26). Dominant not by raw downloads (it is a specialist crate) but by exact-policy fit + production adoption + gate cleanliness: it is the only surveyed established crate that is simultaneously size-plus-count, backend-agnostic (`impl Write`), dependency-lean (chrono + flate2 only), `unsafe`-free in all surveyed source files, and CI-tested on ubuntu+macos+windows.

##### Qualified shortlist

- `file-rotate` 0.8.0 — see Dominant choice. Maintenance: `stable-quiet` (no release in 19 months is the trigger; investigation shows a feature-complete specialist: 9 open issues per `GET https://api.github.com/search/issues?q=repo:kstrafe/file-rotate+is:issue+is:open`, maintainer answered 5 of the last 7 issues with median 6.8 days to first response, no advisory, no abandonment notice, production adopters current).
- `flexi_logger` 0.31.10 — `active` (released 2026-08-07, pushed 2026-08-06; 394 stars; 5 open issues; median first response ~0.3 days over the last 5 issues with 1 unanswered; CI on ubuntu+windows+macos; 226 reverse-dependents incl. qsv and cargo-leptos). Size rotation verified. Shortlisted as the `log`-pipeline fallback and architectural runner-up, not the primary (full-backend mismatch).
- `tracing-rolling-file` 0.1.3 — `stable-quiet` per rubric (13 months without a release investigated: 0 open issues, CI matrix present, no advisory — no concrete at-risk signal), but explicitly 0.x-immature (12 stars, single maintainer, 4 tiny reverse-dependents). Shortlisted as the native-tracing alternative and re-verify watch item.

##### Excluded by gate

- `log4rs` 1.4.0 — fails fitness gate 4 as evidenced: CI matrix is ubuntu-latest + windows-latest only (`main.yml`; `coverage.yml`/`lint.yml`/`editor-check.yml` are ubuntu-only) and the README states no macOS platform support, so "tested on ubuntu-latest, macos-latest" is unsatisfied on the observed evidence. (Likely conservative — the crate is near-pure-Rust — but the gate requires evidence, and recent triage is also silent: the 5 most recent issues are all unanswered with 0 comments.) Independent fit note: full `log` backend, same architecture mismatch as flexi_logger.
- `tracing-appender` rolling (as the rotation solution; the crate itself is R58-domain infrastructure, not rejected) — fails the item capability gate: time-based rotation only (`MINUTELY/HOURLY/DAILY/WEEKLY/NEVER` verified in source), cannot express the size-plus-count disk bound.
- `fern` 0.7.1 — fails the capability gate (date-based file naming at most; no size trigger, no backup-count rotation) and gate 4 is partial (CI ubuntu+windows only). 90-day downloads 8,252,512 show popularity, which is weighed only after gates — and the gate fails first.
- `simplelog` 0.12.2 — fails the capability gate (no rotation facility at all).

##### Up-and-comers

`tracing-rolling-file` 0.1.3 is the one to watch: purpose-built size-based rolling for tracing (`RollingConditionBase`, `condition_max_file_size`, `max_filecount`, optional `non-blocking` feature), 3-OS CI, zero `unsafe` in `src/lib.rs`, no advisory, 1.7M total downloads of direct interest. Blockers to promotion today: 0.1.x API stability, single maintainer, no declared `rust-version`, thin production adoption (4 tiny reverse-dependents). Re-evaluate at 1.0 or on broadened adoption; if promoted it would displace `file-rotate` on native `NonBlocking` integration.

##### Fit for this template

CLI + library + web service need a small, sync-or-wrapped writer with no runtime coupling and no opinions about formatting or filtering. `file-rotate` has no features table (nothing to misconfigure), no async-runtime coupling (blocking `Write`; R58's non-blocking wrapper provides the async-safe path), and pulls only chrono (clock for timestamps) + flate2 (compiled but unused unless `Compression::OnRotate` is selected — see Tradeoffs). The library surface stays clean: rotation lives in the binary/service wiring, never in library code. Edge behaviors verified in source and carried into the wiring contract: `FileRotate::new` asserts on zero limits and `expect`s parent-dir creation — the template must validate `logging.file` (non-empty path, creatable parent) and convert failures into config errors, never a panic path.

##### Recommendation

`file-rotate` 0.8 (`FileRotate<AppendCount>`, `ContentLimit::BytesSurpassed(10 * 1024 * 1024)`, `AppendCount::new(5)`, `Compression::None`), wrapped in R58's non-blocking writer, attached as the file layer's writer.

##### Ranked runner-up

`flexi_logger` 0.31.10 (conditional on R58 selecting a `log`-facade pipeline, or as the file-writer half of a `log`-compat shim): best-maintained size-rotating alternative (`active`, 0.3-day median response, 3-OS CI, 24.3M total downloads, qsv/cargo-leptos adoption), `Criterion::Size` + `Naming` + `Cleanup` cover the policy. Loses the primary pick solely on architecture (a second backend next to a tracing pipeline), not on quality.

##### Tradeoffs

`file-rotate` vs runner-up: + exact py semantics as a passive writer; + smallest dependency surface (2 normal deps vs flexi_logger's 3 + 14 optional and log4rs's 8 + 16 optional); + zero `unsafe` observed; + 3-OS CI; − single maintainer, 41 stars, undeclared MSRV (mitigated: deps declare 1.62/1.67, far under any plausible floor); − always compiles flate2 (gzip backend compiled even with `Compression::None`; small compile-time/bloat cost, no runtime cost); − `expect`-on-mkdir and assert-on-zero need a validation wrapper. `tracing-rolling-file` vs `file-rotate`: + native `NonBlocking` integration and tracing-idiomatic builder; − 0.x immaturity and maintainer bus factor dominate. flexi_logger vs `file-rotate`: + far richer (rotation + cleanup + specfile + tracing `trc` bridge) and best-in-class responsiveness; − richness is the cost (backend duplication, default `colors`+`textfilter` deps) when R58 owns the pipeline.

##### Parameters

owns: none. assumes `rust-edition = 2024`, `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`, `license = MIT OR Apache-2.0`, `target-os-matrix = ubuntu-latest, macos-latest` (all fixed, owner-decided). assumes `logging-pipeline-contract = (undecided — file writer selected against the expected tracing-subscriber Layer contract; switches to the flexi_logger/log4rs fallback path if R58 selects a log-facade pipeline)`. No `CONFLICT` lines: no registered value is challenged.

##### Migration implications

`Cargo.toml`: add `file-rotate = "0.8"` (default features — there are none). New/changed wiring (member 2 implements it): logging-init module constructs `FileRotate` from the resolved `[logging] file` path; web-service binary and CLI share the constructor. No feature flags, no runtime selection, no platform `cfg` (3-OS CI covers the matrix; Windows support noted as present in CI, not required).

##### Validation strategy

Planned (none executed in this research leg): (1) `cargo build --locked` on ubuntu-latest and macos-latest proves gate-4 build evidence for the template's own matrix; (2) a rotation test writes 12 MiB through `FileRotate<AppendCount::new(5)>` + `BytesSurpassed(10 MiB)` and asserts exactly `app.log` + `.1..=.5` exist with total size bounded and every line intact (no torn records); (3) `cargo tree -p file-rotate -e normal` snapshot asserting the two-dep tree; (4) `cargo deny`/audit gate asserting no new advisory. Expected: all green; any advisory or MSRV-creep failure re-opens this member.

##### Confidence & re-verify trigger

Confidence: high in the crate pick conditional on R58 selecting a tracing-subscriber pipeline (the expected shape); medium-high unconditionally (fallback path identified but not re-gated). Re-verify on: R58's `logging-pipeline-contract` decision (mandatory — confirms or switches the member); any RustSec advisory for `file-rotate`/chrono/flate2; 12 more months of maintainer silence combined with a failing build on current stable; `tracing-rolling-file` 1.0 or 10+ substantial reverse-dependents (promotion candidate); MSRV floor rising past a newly declared `file-rotate` rust-version.

##### Sources

- `GET https://crates.io/api/v1/crates/file-rotate`, `.../tracing-appender`, `.../flexi_logger`, `.../log4rs`, `.../fern`, `.../simplelog`, `.../tracing-subscriber`, `.../tracing-rolling-file`, `.../chrono`, `.../flate2` + each `/versions` and the rotation candidates' `/{version}` + `/{version}/dependencies` — downloads, releases, rust-version, license, features, dependency trees (retrieved 2026-09-26).
- `GET https://api.github.com/repos/kstrafe/file-rotate`, `.../tokio-rs/tracing`, `.../emabee/flexi_logger`, `.../estk/log4rs`, `.../daboross/fern`, `.../Drakulix/simplelog.rs`, `.../cavivie/tracing-rolling-file` — stars, archived, pushed_at (retrieved 2026-09-26).
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` per repo — open-issue `total_count` (retrieved 2026-09-26); 10 most recent issues + per-issue comments for responsiveness medians (same date).
- Source via `GET https://api.github.com/repos/<o>/<r>/contents/<path>`: `tracing-appender/src/rolling.rs` (time-only rotation), `file-rotate` `src/{lib,suffix,compression}.rs` (policy API, zero `unsafe`), `tracing-rolling-file/src/lib.rs` (size conditions), `flexi_logger/src/parameters/{criterion,naming}.rs` + `src/{lib,writers/file_log_writer}.rs` (`Criterion::Size`, `unsafe` samples), `log4rs` `src/append/rolling_file/policy/compound/{trigger/size.rs,roll/fixed_window.rs}` + `src/lib.rs` (size policy, `unsafe` sample) (retrieved 2026-09-26).
- CI matrices via `.github/workflows` contents per repo (retrieved 2026-09-26); `https://rustsec.org/packages/<name>.html` per candidate + `RUSTSEC-2025-0055` detail (retrieved 2026-09-26).
- Adopters: `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies` + adopter `Cargo.toml` via GitHub contents (`qarmin/czkawka`, `txpipe/oura`, `zellij-org/zellij`, `jqnatividad/qsv`) (retrieved 2026-09-26).

#### file-sink-wiring-pattern ([logging] section, flag/env, precedence, floor)

##### Landscape

Sub-category: the reference wiring pattern binding config schema, CLI surface, init order, and per-sink filtering to the rotating writer. This is a pattern member, not a crate member: no registry crate is selected here, so crate figures (downloads, stars, issues, advisories) are inapplicable — the evidence is the py source precedent (F255–F261), the R58/R54/R57 contracts it composes with, and the subscriber semantics it relies on. Bins: first-party — R58's pipeline init + per-layer filters (expected `tracing-subscriber`, 90-day downloads 147,886,240, 0.3.23 released 2026-03-13); established — py's handler/floor pattern as the cross-repo contract source; up-and-comer — none (no new mechanism proposed).

##### Principles and implementation

The pattern preserves four py behaviors exactly: (1) `logging.file` + `logging.file_level` config keys with flag/env > config > off precedence (F255/F259); (2) independently settable file-sink format (F260) — the file layer builds its own formatter (JSON vs human) from `logging.format` plus a `PLBP_LOG_FILE_FORMAT`-style env override, never inheriting the console formatter by reference; (3) dual-sink floor as structural per-layer filtering (F261 without the `min()`); (4) rotation bounds 10 MiB / 5 backups (F256/F257). Init is two-phase: resolve config (R54 tiers), then construct the subscriber with the file layer iff a path resolved; pre-config failures go to stderr via R58's bootstrap. Validation precedes construction: empty path rejected, parent dir created-or-error (surfacing `file-rotate`'s `expect` as a config error), zero/negative limits rejected (surfacing the assert as a config error). Shutdown: the non-blocking guard is held for the process lifetime and flushed explicitly on shutdown paths the template owns (CLI exit, web-service graceful stop) — a dropped guard loses buffered records, so the guard must be stored, not `_`-discarded.

##### Dominant choice

Two-phase init + per-layer `LevelFilter` + independent file formatter + validated `FileRotate` construction, as specified above. Dominant because it is the only shape that simultaneously satisfies the precedence contract (needs resolved config), the floor contract (needs independent filters), and R58 ownership (no second backend, no global-level coupling).

##### Qualified shortlist

- Two-phase init with stored non-blocking guard (recommended shape).
- Reload-handle variant: build console-only subscriber first, attach the file layer later via a reload handle once config resolves. Qualified but not preferred: keeps early-console and late-file in one subscriber at the cost of interior-mutability machinery (`reload::Layer`) R58 may not otherwise need; viable if R58 already selects reload for reconfiguration (F274).

##### Excluded by gate

- Single-pass wiring (file sink constructed with the console sink before config resolution): excluded — cannot implement flag/env > config > off because the merged config does not exist yet; also strands config-load errors with nowhere structured to go.
- Global-`max_level`-only filtering with no per-layer filters: excluded — reintroduces the explicit floor computation and couples the two sinks' verbosity; kept only as the documented fallback if R58 mandates a global level (then global = most verbose of the two).
- Second-backend wiring (a `log`-crate file logger running beside the tracing pipeline): excluded under the expected R58 shape — dual configuration/filtering and split ownership; becomes the qualified path only if R58 selects a `log`-facade pipeline.

##### Up-and-comers

None: the wiring introduces no new crate or mechanism. The watch item belongs to member 1 (`tracing-rolling-file` promotion would swap the writer constructor only; this pattern is unchanged).

##### Fit for this template

The pattern is CLI/service-shared library code: one `resolve_file_sink(config, cli) -> Option<FileSinkSpec>` pure function (precedence + validation, unit-testable without I/O beyond tempdirs) plus one `attach_file_layer(subscriber_builder, spec) -> (builder, guard)` constructor. The library crate exposes the pure resolver; binaries own the guard lifetime. No async coupling (blocking writer behind the non-blocking boundary), no platform `cfg`, negligible binary/compile cost (no new crates beyond member 1).

##### Recommendation

Adopt the dominant choice: `resolve_file_sink` (flag/env > config > off, XDG-state default, explicit-path fallback) + validated construction + per-layer filter/format + stored guard, built in the post-config pass.

##### Ranked runner-up

Reload-handle variant (attach file layer post-resolution into a live subscriber). Ranked second because it adds `reload` machinery for no behavioral gain unless R58 independently needs runtime reconfiguration; promote it if R58's F274 answer selects reload handles.

##### Tradeoffs

Two-phase init vs reload-handle: two-phase is simpler (one construction site, no `reload` dependency, guard lifetime is plain ownership) but delays all structured logging until config resolves (mitigated: R58 bootstrap stderr covers pre-config failures); reload keeps early structured console but pays `reload::Layer` complexity and guard-handle bookkeeping. Per-layer filters vs global floor: per-layer is structural (no `min()` to get wrong, survives later addition of a third sink) at zero cost; global floor is one line simpler only when exactly one level knob exists, which this item forbids (two knobs by contract).

##### Parameters

owns: none. assumes the four fixed parameters (same values as member 1) plus `logging-pipeline-contract = (undecided — pattern written against per-layer filter + post-resolution construction; R58's init-order/f274 answers confirm the attach point)`. Informative dependency on R57's state-directory conclusion (default path vs explicit-path fallback), which is `related`, not consumed — no `assumes` line is fabricated for it. No `CONFLICT` lines.

##### Migration implications

Template files: config schema gains `[logging] file: Option<PathBuf>` + `file_level: Option<Level>` (keys only; `level`/`format` stay R58's); CLI gains `--log-file` + `PLBP_LOG_FILE` and a file-format env override; logging-init module gains `resolve_file_sink` + `attach_file_layer`; default path constant points at the R57 state dir (or is omitted under the fallback); docs gain a logging page section (precedence table, rotation bounds, guard-flush note); tests gain precedence-matrix, rotation-bound, per-sink-level, and no-file-when-off cases.

##### Validation strategy

Planned (none executed): (1) precedence matrix test over {flag, env, config} × {set, unset} asserting the resolved path/off decision (8 cases, tempdirs); (2) level-independence test (console WARN + file DEBUG delivers DEBUG only to the file; reversed pair mirrors); (3) format-independence test (console human + file JSON parses every file line as JSON); (4) rotation-bound test (member 1's 12 MiB check through the full wiring); (5) off-by-default test (no flag/config ⇒ no file created anywhere); (6) shutdown-flush test (graceful stop ⇒ trailing records present). Expected: all pass on ubuntu + macos CI.

##### Confidence & re-verify trigger

Confidence: high — the pattern is contract-preserving by construction and its only load-bearing external bet (per-layer filtering in R58's pipeline) is the idiomatic shape of the expected subscriber. Re-verify on: R58's pipeline/init-order decisions (mandatory — confirms the attach point and bootstrap story); R54's discovery-tiers answer (confirms what "resolved config" contains at wiring time); R57's state-directory conclusion (selects default path vs explicit-path fallback).

##### Sources

- Py precedent F255–F261 as cited in the prompt (`src/py_launch_blueprint/core/{settings.py:49,logging.py:82,241,259,262}`, `src/py_launch_blueprint/cli/{options.py:93,context.py:212,233}`) — contract source, not re-fetched (out of this leg's named endpoints; relied on via the prompt's evidence pins).
- `GET https://crates.io/api/v1/crates/tracing-subscriber` + `/versions` (0.3.23, 2026-03-13, rust-version 1.65, MIT; retrieved 2026-09-26) for the expected composition substrate; `https://rustsec.org/advisories/RUSTSEC-2025-0055.html` (ANSI-injection, patched ≥0.3.20 — the expected ≥0.3.23 pin is unaffected; retrieved 2026-09-26).
- `file-rotate` constructor edge behaviors verified in `src/lib.rs` via the GitHub contents API (retrieved 2026-09-26); R58/R57/R54 contract status from this run's `inputs/prerequisites.json` + `inputs/parameters.json` (`logging-pipeline-contract` undecided).

### Compatibility

Members compose as: `resolve_file_sink` (member 2) → `FileRotate<AppendCount>` (member 1) → R58 non-blocking writer → second `fmt` layer with independent filter+formatter (member 2). Version matrix: `file-rotate 0.8` × `tracing-appender 0.2.5` (non-blocking) × `tracing-subscriber 0.3.23` — req ranges are compatible (`tracing-rolling-file`'s manifest independently demonstrates the `tracing-appender ^0.2.3` + size-rotation composition, and its docs show the `NonBlocking`-wrap idiom this stack reuses). Production analogues: czkawka and oura ship `file-rotate` writers; zellij ships size+window file rotation; aws-sdk-s3/lambda_runtime ship `tracing-appender` non-blocking writers. Gap stated honestly: no single shared example repository combining `file-rotate` + `tracing-subscriber` layers was found through the named endpoints, so the template's own worked example (member 2's validation strategy) is the designated integration proof; the synthesizer should require it before acceptance.

### Parameters

assumes `rust-edition = 2024`
assumes `msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI`
assumes `license = MIT OR Apache-2.0`
assumes `target-os-matrix = ubuntu-latest, macos-latest`
assumes `logging-pipeline-contract = (undecided — designed against the expected tracing-subscriber Layer contract with a log-facade fallback path; see Principles and implementation)`

### Migration implications

`Cargo.toml` gains `file-rotate = "0.8"`. Config schema gains `[logging] file`/`file_level`. CLI gains `--log-file`/`PLBP_LOG_FILE` plus the file-format env override. The logging-init module gains the pure `resolve_file_sink` resolver and the `attach_file_layer` constructor holding the flush guard. Docs gain the logging page section (precedence, bounds, flush). Tests gain the six validation-strategy cases. No other template files change; no feature flags, no platform `cfg`, no async-runtime coupling.

### Validation strategy

Planned commands and checks (all proposed; this research leg executed none — no code was written or run): `cargo build --locked` and `cargo test` on ubuntu-latest + macos-latest (build + gate-4 evidence); the 12 MiB rotation-bound check (exactly `app.log` + `.1..=.5`, bounded total, intact lines); the 8-case precedence matrix; console/file level- and format-independence tests; the off-by-default no-file test; the graceful-shutdown flush test; `cargo tree`/`cargo deny` snapshots for the two-dep tree and advisory state. Expected behavior: every check green; the rotation test is the acceptance gate for the disk-bound principle, the precedence/level tests for the wiring principle.

### Confidence & re-verify trigger

Overall confidence: high conditional on R58 selecting a tracing-subscriber pipeline (expected); medium-high unconditional given the identified fallback. Mandatory re-verify triggers: R58's `logging-pipeline-contract` + init-order decisions, R54's discovery tiers, R57's state-directory conclusion. Standing triggers: RustSec advisory for `file-rotate`/chrono/flate2; `file-rotate` build failure on current stable or 12 further silent months; `tracing-rolling-file` 1.0 / broad adoption (promotion); MSRV floor rising past any newly declared dependency rust-version. Re-verify date: on R58 acceptance or 2027-03-26, whichever comes first.

### Sources

- crates.io API (`GET https://crates.io/api/v1/crates/<name>`, `/versions`, `/{version}`, `/{version}/dependencies`, `/reverse_dependencies`) for `file-rotate`, `tracing-appender`, `tracing-subscriber`, `tracing-rolling-file`, `flexi_logger`, `log4rs`, `fern`, `simplelog`, `chrono`, `flate2` — all figures and trees above; retrieved 2026-09-26.
- GitHub API (`GET https://api.github.com/repos/<o>/<r>`, `/search/issues`, `/issues`, `/contents/...`, `/git/trees/...`) for `tokio-rs/tracing`, `kstrafe/file-rotate`, `emabee/flexi_logger`, `estk/log4rs`, `daboross/fern`, `Drakulix/simplelog.rs`, `cavivie/tracing-rolling-file`, plus adopter repos `qarmin/czkawka`, `txpipe/oura`, `zellij-org/zellij`, `jqnatividad/qsv` — stars, CI matrices, issues/responsiveness, source verification, adopter `Cargo.toml` lines; retrieved 2026-09-26.
- rustsec.org (`https://rustsec.org/packages/<name>.html` per candidate; `https://rustsec.org/advisories/RUSTSEC-2025-0055.html`) — advisory state; retrieved 2026-09-26. A rustsec.org "Page not found" response for a package page means no advisory page exists for that package (no recorded advisories).
- Run inputs: `research/runs/R59/2026-09-26T190256Z-4c0fef2a9f93/inputs/{prompt.md,parameters.json,prerequisites.json}` (R58 `logging-pipeline-contract` undecided); local stable toolchain `rustc 1.98.1` as the MSRV-floor reference point (observed 2026-09-26).
- Not consulted (outside this leg's named endpoints; stated as limits, not silent gaps): docs.rs API pages (exact method signatures re-verified from GitHub source instead), py/ts source files (relied on via the prompt's F255–F261 evidence pins), external benchmarks (no throughput claim is made).
