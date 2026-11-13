# 2026-09-27 — R58 — logging-pipeline-architecture (bundle, Deep) — decision (revision 2)

**Revision 2 repairs revision 1 under route (b), per owner decision Q1.B (2026-09-28).**
Revision 1 (dated 2026-09-18, sha256
`d06a6961d5b4f583182ea3d90de3b6222c3a9bbf955144e6c896339657ba5ed9`) was rejected by both
round-1 audits: the empirical audit (`review/audit-claude.md`: EC-1, EC-2 and EC-3
blocking; DR-1, DR-2 and DR-3 non-blocking) and the judgment audit
(`review/audit-fable.md`: F1–F8). Its bytes are preserved unchanged as
`review/R58-r1-snapshot.md`, verified before this repair began with `cmp` (identical) and
`shasum -a 256` (the same hash). **The recommendation does not move**: `tracing` 0.1.44,
`tracing-subscriber` 0.3.23 with `env-filter` and `json` off, `tracing-log` through the
default feature, and the template-owned redacting formatters. Revision 2 applies only
the enumerated repairs below; anything else noticed is disclosed at the end of this note,
not fixed.

**Adopted baseline (route (b)).** Owner decision Q1.B adopts the evidence that was on disk
in `review/evidence/` when this repair began, including a prior session's refresh: new
snapshots, exact probe pins with a committed `probe/Cargo.lock`, the partial-host
scenario S4b, and the four R5.1 quotations in `r58-standards.sh`. Nothing was restored
from git and the snapshots were not refetched. The baseline record, taken before any
edit (sha256):

| File under `review/evidence/` | sha256 at the start of the repair |
|---|---|
| `r58-probe.sh` | `88ab068389d0e33d0f23d938995af8c30c165ebdfd512c355f0a28f4f3f05472` (edited by EC-2 to `d908a4d3032903504a46f47c701840e96a92046ecdf94dd70071e40fd5a58418`) |
| `r58-standards.sh` | `d39ceb48b60a56c2495b7736a18cb4b33d007567c0c88bde4556ec74df657836` (unchanged) |
| `r58-figures.sh` | `6de25b3d4bca3b866bc83694ae1c8c49dd2b6097a923ea6766ac1157f4df775d` (unchanged) |
| `r58-fetch-snapshots.sh` | `c82900cc51319f20d0082eb529b45b1c15182f7859e5dfcb291373b8be38957c` (unchanged) |
| `r58-assert-figures.py` | `2a5b18d7c77b528fe54646e0e53b978e895031769cedbcce8f46cb6fed858050` (unchanged) |
| `r58-gate1-wording.py` | `71bcbf7207187771ba175413a31aac67589d71fccebbfb2afa63f0147e0845ed` (unchanged) |
| `r58-param-lines.py` | `e06d7a657b1227ce3ee8f682d6a91536b4674ac830629b2befa6ab9ea3b8fdd3` (unchanged) |
| `r58-sample-issues.py` | `96e95587e36a4d3f43324c9e7f8f775ae45b4ed18b9849aa79ee3f09eb4766ac` (unchanged) |
| `probe/Cargo.toml.in`, `probe/Cargo.lock`, `probe/main.rs` | `874d1b09…`, `4ecba947…`, `1f3a3d88…` (all unchanged) |
| `snapshots/RETRIEVED-UTC.txt`, content `2026-09-27T05:48:12Z` | `cb2be4c78577e2005dade89cd97af67e8d773dad065f55efa8e9ad3d3c39df5a` (unchanged) |

**Recomputed totals.** Counted from the scripts as they stand and confirmed by the
re-recorded logs: **33** probe checks (the build, S1–S10, S4b's S4c and S4d, S11a–S11d)
+ **48** standards checks (14 CLI, 10 REST, 16 `tracing-subscriber` source, 4 parameter
lines, 4 revision rules) + **161** figure checks = **242**, all PASS. Revision 1 reported
31 + 40 + 161 = 232, while the evidence the audits reran held 31 + 44 + 161 = 236.

| Finding | Repair in revision 2 |
|---|---|
| **EC-1** (blocking) — the standards totals were misreported | `### Validation strategy` and `## Empirical check` report 48 standards checks and 242 in total, with the sum shown as its parts; the four revision-rule checks are described and `r58-gate1-wording.py` is named as an input; the named-skip text now says "fifteen" source assertions, agreeing with the table. The skip messages in `r58-standards.sh` were verified to be the true counts — thirteen CLI quotations, nine REST quotations, fifteen source assertions — so the script needed no edit; `r58-standards.log` is re-recorded |
| **EC-2** (blocking) — the probe failed silently under `CARGO_TARGET_DIR` | `export CARGO_TARGET_DIR="$WORK/target"` was already in the adopted script directly after `WORK` is created, and is kept. `run()` now records `bad "$1: binary did not run (exit $?)"`, so the summary line always prints; verified on a deliberately broken `/tmp` copy. `r58-probe.log` is re-recorded |
| **EC-3** (blocking) — fetch provenance did not match the script | Route (b): the adopted full re-record was verified rather than refreshed. One invocation wrote all 95 snapshot files from 05:41:34Z to 05:48:12Z on 2026-09-27, the two advisory pages inside it at 05:48:10Z and 05:48:11Z; its 46-line log matches the script, including both `rustsec advisory:` lines; `r58-figures.sh` reruns byte-identical to the recorded `r58-figures.log`; and every figure this decision cites was moved to that snapshot. The `tracing` member's sources now cite the advisory retrieval with its UTC time |
| **DR-1** (non-blocking) — registry drift | Disclosed. Version citations are date-qualified to the 2026-09-27T05:48:12Z snapshot, and the re-verify triggers now name a new `tracing-opentelemetry` minor after 0.34.0 and a new `redactable` publication after 0.14.0 |
| **DR-2** (non-blocking) — toolchain drift broke byte comparison | Disclosed. The comparison rule now reads: all lines except the `== toolchain ==` header, `repo root:`/`checkout shape:`, and the registry path. The `mktemp` sentence is corrected, since no log prints a `mktemp` path. The re-record ran on rustc 1.98.1 |
| **DR-3** (non-blocking) — the probe's version label was asserted, not checked | Disclosed. The adopted pins (`=0.1.44`, `=0.3.23`, `--locked` with `probe/Cargo.lock`) make the build line's label "tracing 0.1.44 + tracing-subscriber 0.3.23" true by construction; S11's `serde_json = "1"` still floats. Pin maintenance is recorded as P03 obligation 7 |
| **F1** — `## Engines` left out the Muse leg | Muse is listed with its sha256 and model, and its six positions are adjudicated in a new table (M1–M6). The "Codex absent" and "largest gap" statements are requalified to match the prompt's `- engines: muse, opus, doxa` |
| **F2** — the ladder let an environment variable beat explicit flags, against CLI R5.1 | Route (a), conform: `--debug` > `--log-level` > `-q` > `-v`×n > `RSLBP_LOG_LEVEL` > config > `WARN`, recorded as a departure from py F274 on R5.1's ground. The owned value, the ladder table, P03 validation item 4 and the README row are updated, and R5.1's four lines are quoted with the other CLI rules |
| **F3** — `try_init()` `Err` was read as "a host owns diagnostics" | The contract separates the two causes: a dispatcher already set (checked with `tracing::dispatcher::has_been_set()` before `try_init`) returns `HostOwned`; an `Err` after a clear check returns `Installed(Handles)` with `log_bridge_refused: true`. It cites S4b's results (S4c and S4d PASS). The partial-host case is added to P03 validation item 1 |
| **F4** — `#[tracing::instrument]` was prescribed where `attributes` is off | Route (a): removed for `crates/core` and `crates/web`, which keep events and `span!` only |
| **F5** — the service format was both fixed and configurable | `RSLBP_WEB_LOG_FORMAT` takes `json` (the default) or `console`, with no `auto` and no TTY test; any other value fails as R67's `RSLB203` in R77's `WebSettings::from_env()`. `Profile::Service` gains `format`, and the profile table, the module shape, the migration row and the owned value agree |
| **F6** — rules were attributed to R02 that R02 does not state | Both passages now credit R02 (revision 3, `d8c64f7c…`) with only the four-package workspace, the root-package composition root and the `deny[].wrappers` and allow-list mechanism, and state that this decision adds the `tracing`-only core edge, the `wrappers` row and the allow-list entry |
| **F7** — the check counts did not match the log | Covered by the EC-1 recompute above, including the skip narrative; the eight checks on this file (four parameter-line, four revision-rule) are described |
| **F8** — prerequisite and figure drift | R05 is cited as revision 3 (`3ca4b81a…`). The prerequisite sentence is recounted and now lists six. The recount goes beyond F8's named pair (R57, R62) because the files on disk also show R02, R05 and R56 published; this is disclosed, and only R61 remains unpublished. `tracing-opentelemetry` 0.34.0 and `redactable` 0.14.0 were confirmed against the refreshed snapshots and date-qualified to their stamp; `redactable` still declares `rust_version` 1.97, so the gate-2 exclusion stands |

**Edits that follow from the enumerated repairs.** Adopting S4b changes "ten behavioural
scenarios" to eleven and 31 probe checks to 33. Adding Muse changes "four model outputs"
to five. Moving `RSLBP_LOG_LEVEL` to rung 5 changes F254's row. Adopting the new
snapshot moves every cited counter and the stamp, and changes "3.6 months without a push"
to "almost four months". Re-recording on rustc 1.98.1 updates the toolchain block. The
F3 contract adds a re-verify trigger for the `#[doc(hidden)]` `has_been_set`.

**Disclosed, not repaired (outside the enumerated set).** "R02 revision 2" labels remain in
passages no finding named, for example the `slog` rejection and the reference-architecture
layout row. The re-verify line's clause "when R02, R05, R56 or R77 publishes" has fired for
R02, R05 and R56, and no re-derivation against their published texts was performed. The
`RSLBP_WEB_LOG_LEVEL` value set is not stated separately from the CLI's level names.

## Decision

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. What P03 must validate is listed under
`## Engines`. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

**The recommendation in one sentence.** Adopt `tracing` 0.1.44 as the only diagnostic
facade any package names, `tracing-subscriber` 0.3.23 with `features = ["env-filter"]`
over its default set and its `json` feature **off**, declared on the composition root
alone, `tracing-log` 0.2.0 reached only through `tracing-subscriber`'s default
`tracing-log` feature, and a template-owned `src/telemetry.rs` that supplies the
redacting field formatter for the human profile and the redacting event **and** field
formatter pair for the structured profile — installed once per process with
`try_init()`, writing every byte to stderr, holding a `reload::Handle<EnvFilter,
Registry>` so the configuration file can still reach the level ladder, and leaving two
named, undecided slots for R78's OpenTelemetry layer and R59's file sink.

**Ledger rows this settles.** Eight rows, all `DIVERGENT`, all `R58`
(`docs/port/COMMONALITY.md`):

| Row | Line | What it asks | How this decision settles it |
|---|---|---|---|
| F250 | `:254` | console format auto-selects JSON vs human from TTY-ness | kept, as a diagnostic-stream property: `auto` resolves by `std::io::stderr().is_terminal()`, and `--log-format`/`RSLBP_LOG_FORMAT` can force either value |
| F251 | `:255` | a structured key/value pipeline | kept natively: `tracing`'s typed named fields on `Event` and `Span` are the primary payload |
| F252 | `:256` | key-based secret redaction in log output | kept, with a **changed insertion point** — format time, not event time — and a residual gap recorded as `OVERRIDE (OV-09)` |
| F253 | `:257` | optional OpenTelemetry trace/span correlation | kept as an optional Cargo feature `otel` nesting on R69's `web`; the integration itself is R78's, and this decision fixes only the boundary and the two seams |
| F254 | `:258` | an explicit console log-level flag and environment variable | kept: `--log-level` with `RSLBP_LOG_LEVEL`, at rungs 2 and 5 of the ladder |
| F262 | `:266` | reconfiguration tears down only what it owns | kept as a **stronger** rule Rust can actually enforce: never install anything you do not own — a dispatcher that is already set means a host owns diagnostics and nothing is installed; a refused `log` bridge alone does not, and is recorded on the returned handles |
| F263 | `:267` | one pipeline, two per-front-end policy profiles | kept: one builder, one `Profile` value, one subscriber per process, because each front end is its own binary |
| F274 | `:278` | the verbosity-to-level resolution ladder's precedence | kept and reordered: a seven-rung total order with every flag rung above the environment rung, as CLI R5.1 **(MUST)** requires, and `--debug` above the explicit level because it is a bug-report switch |

**What is NOT decided here**, and who owns each: the file sink and its own level (R59,
F255–F261); the XDG state directory a sink may need (R57, F249); whether a web surface
exists at all (R69, `web-extra-surface`); the `-v` repeat-counting mechanics themselves
(F273, `COMMON → REUSE`, not a research item) and the parser that provides the flags
(R60, F264); the OpenTelemetry layer's contents (R78); the access log and its placement
(R75, F320, F327); the serve binary's environment-variable names (R77, which names
`RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT` and states plainly that R58 **values**
them); and Sentry-style error reporting, which no P02 item owns.

**Fitness gate 1 (licence).** `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`. The row is recorded rather
than deleted because the binding prompt still contains it and the prompt's own
instruction is to state `inapplicable` with the reason. Observed licence strings are
still reported per member as registry fact, never as a gate result.

### Landscape

**The category this item decides.** Not "which logging library" but **which
diagnostic-emission architecture the template adopts**: how library code that does not
know where its diagnostics will be rendered produces an event; how that event is
filtered; how it is rendered into two different profiles; where a key-based secret rule
can be applied to it; and who is permitted to install the process-global machinery that
does the rendering. Crate selection follows from that and does not precede it.

**The three-bin map of the Rust field.** Every figure below is asserted by
`review/evidence/r58-figures.sh` against a committed snapshot of the endpoint the
binding prompt's figure table names; the snapshots were retrieved at
**2026-09-27T05:48:12Z** by one invocation of `review/evidence/r58-fetch-snapshots.sh`
that ran from 05:41:34Z to 05:48:12Z (the fetch ran on the evening of 2026-09-26 Pacific,
after 00:00 UTC, so the UTC retrieval stamp reads 2026-09-27). Revision 1 cited an
earlier snapshot, retrieved 2026-09-19T01:23:11Z; every figure below is the
2026-09-27 snapshot's, and every version named as "newest" is newest as of that
snapshot.

| Bin | Members found | Note |
|---|---|---|
| Built-in / first-party toolchain | **none for emission**; `std::io::IsTerminal` for TTY detection; `eprintln!` | The standard library ships no logging facade and no subscriber. The nearest first-party position is that the Rust project's own tools choose from the ecosystem — `rust-lang/cargo`, `rust-lang/rustup` and `rust-lang/rust-analyzer` all depend on `tracing` and `tracing-subscriber`. That is first-party **practice**, not a first-party API. |
| Established industry standard | **facades:** `log` 0.4.34 (30,894 reverse dependencies), `tracing` 0.1.44 (**43,201**) · **renderers over `log`:** `env_logger` 0.11.11 (11,986), `fern` 0.7.1, `log4rs` 1.4.0 · **subscriber over `tracing`:** `tracing-subscriber` 0.3.23 (19,039) · **bridge:** `tracing-log` 0.2.0 (447) · **structured-first alternative:** `slog` 2.8.2 (417) · **formatter add-ons:** `tracing-bunyan-formatter` 0.3.10, `tracing-tree` 0.4.1, `tracing-stackdriver` 0.10.0 · **OTel bridge:** `tracing-opentelemetry` 0.34.0 | Reverse-dependency totals from `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1`, field `meta.total`. On that measure `tracing` now outranks `log`. |
| Up-and-comers | `fastrace` 0.7.19 (Apache-2.0, `rust_version` 1.91.0), `logforth` 0.30.1 (Apache-2.0, `rust_version` 1.89.0), `redactable` 0.14.0 (licence string `non-standard`, `rust_version` **1.97**) | All three are recently published and actively developed. None is shortlisted; `redactable` is the one candidate in this whole item that **fails a fitness gate**, and the reason is given under the telemetry member's *Excluded by gate*. |

There are exactly **three architectures** in that map, and this item turns on choosing
among them rather than among crates:

1. **Record-and-render (the `log` architecture).** A call site produces one
   already-formatted `log::Record` carrying a level, a target and a `fmt::Arguments`
   message. One process-global `log::Log` implementation renders it. Key/value pairs
   exist but are an opt-in side channel; the primary payload is a formatted string.
   `env_logger`, `fern` and `log4rs` are renderers for this architecture.
2. **Event-and-span instrumentation (the `tracing` architecture).** A call site
   produces a `tracing::Event` carrying **typed, named fields** and an implicit parent
   span; a process-global subscriber — in practice `tracing_subscriber::Registry`
   composed with `Layer`s — decides interest, holds span state and formats. Fields are
   the primary payload and the rendered line is derived from them.
3. **Structured-record with an explicit drain (the `slog` architecture).** Typed
   key/value records, an explicitly threaded `Logger` value rather than a global, and
   composable `Drain`s. Architecturally this is the closest thing in Rust to structlog's
   processor chain.

**Authoritative sources used, and why each counts.** A single blog post is treated as a
lead and never as a ground; no blog post supports any recommendation here.

| Source | Why it is authoritative | Read |
|---|---|---|
| `tracing-subscriber-0.3.23` source in the local Cargo registry, and https://github.com/tokio-rs/tracing | The maintainers' own implementation, read at exactly the version recommended. Every behavioural claim below is read out of the source or executed against it, never out of prose. Twelve line-anchored quotations are asserted by `review/evidence/r58-standards.sh`. | 2026-09-18 |
| `rust-lang/cargo`, `rust-lang/rustup`, `rust-lang/rust-analyzer` manifests | The Rust project's own build tool, toolchain installer and language server; first-party publications of what the project itself depends on. `rustup` is additionally the closest maintained **CLI** reference implementation of the exact pattern recommended here. | 2026-09-18 |
| RustSec Advisory Database (`https://rustsec.org/packages/<name>.html` and the two advisory detail pages) | The Rust Secure Code Working Group's database; the authority fitness gate 3 names. | 2026-09-27 (snapshot) |
| The org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `/Users/stevemorin/c/cli-standards` | Org-binding for this template by the owner ruling of 2026-09-14 and owner decision 9, "DECIDED. The standard BINDS." | 2026-09-18 |
| The org REST API Design Standard v2.0.0, blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` in `/Users/stevemorin/c/rest-standards`, commit `0850d43e45d919ef5e37f7174c4212b46013c49f` | Binding on the template's HTTP surface by **owner ruling W2-REST** (2026-09-18, `docs/port/OWNER-REVIEW.md:187`). Nine line-anchored quotations are asserted by `review/evidence/r58-standards.sh`. | 2026-09-18 |
| crates.io API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) | The registry of record for versions, release dates, declared `rust_version`, licence strings and download counts. | 2026-09-27 (snapshot) |
| GitHub REST API (`repos/<o>/<r>`, `search/issues`, `issues`, `issues/<n>/comments`) | Stars, archived state, push recency, open-issue counts and the responsiveness sample, per the prompt's figure table. Calls paced at one per 21 seconds. | 2026-09-27 (snapshot) |
| The owner's reference architecture, `inputs/owner-reference-axum-companion-stack-2026-09-16.md` (byte-identical to `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`) | Standing input by owner decision 11 (`docs/planning/p02/owner-decisions.md`, section 11). Its C10 rows are reconciled row by row below. | 2026-09-18 |

**Practice evidence — mainstream, well-regarded Rust projects.** Each is well regarded
on stated grounds rather than by assertion, and each manifest was read at its default
branch on 2026-09-18.

| Project | Why it is a relevant, well-regarded reference | What its manifest shows |
|---|---|---|
| `rust-lang/cargo` | The Rust project's official build tool; every Rust developer runs it. | `tracing = { version = "0.1.44", default-features = false, features = ["std"] }` at workspace level, `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`, and the binary alone adds `features = ["attributes"]`. **This is exactly the core-versus-composition-root split recommended below, at exactly the two patch versions recommended below, in the ecosystem's most-run binary.** |
| `rust-lang/rustup` | The Rust project's official toolchain installer: a CLI with a library core, which is this template's shape. | `tracing`, `tracing-log`, `tracing-subscriber` with `env-filter`, and `tracing-opentelemetry` **optional** behind an `otel` feature — the same three members plus the R78 hook, in a shipped CLI. Its `src/cli/log.rs` implements a custom `FormatEvent` and returns a `reload::Handle<EnvFilter, Registry>`. |
| `rust-lang/rust-analyzer` | The official Rust language server; the default Rust IDE experience. | `tracing` with `default-features = false, features = ["std"]`, `tracing-subscriber` with an explicit narrow feature list, plus `tracing-tree`. |
| `astral-sh/uv` | A large, new, heavily adopted Rust CLI — and the tool this programme's own `AGENTS.md` workflow runs. | `tracing` and `tracing-subscriber` with `default-features = false` and explicit feature lists, plus `tracing-tree`. |
| `astral-sh/ruff` | The most widely adopted new Rust developer tool of the last three years. | `tracing` and `tracing-subscriber`, and — notably — **also** `log` and `fern` for a separate user-facing message channel. The one surveyed project still running a `log`-architecture renderer alongside `tracing`. |

Not one surveyed project uses `slog`, `log4rs`, or a bare `log` + `env_logger` stack as
its primary diagnostic architecture. `env_logger` remains widely used — 11,986 reverse
dependencies — but predominantly in examples, tests and small single-binary tools, not
in the layered library + CLI + service shape this template has.

**Fit test, applied before any ranking.** The template is one library core, one CLI
binary and one optional web service that must share a pipeline (F263), must protect
secrets by key (F252), must correlate with OpenTelemetry behind an optional Cargo
feature (F253, F304), must not steal a host's logging (F262), and must not drag an async
runtime into the default dependency tree (R05 revision 3). Two of those five are
properties the `log` architecture structurally cannot supply, and that is settled below
on executed evidence rather than asserted.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

| # | Requirement | Source | Agreement level | What may vary |
|---|---|---|---|---|
| P1 | Diagnostics are **structured events with named fields**, not pre-formatted strings, so every sink inherits field-level policy | F251; py `core/logging.py:154` `_shared_processors()`; ts has no field model (`src/lib/logger.ts:47`) | **architectural pattern** — all three ecosystems need a field model; none needs the same one | the composition mechanism: processor chain, layered subscriber, or drain stack |
| P2 | The console render mode **auto-selects** machine-readable versus human from the diagnostic stream's TTY-ness | F250; py `core/logging.py:120` `_resolve_format` on `sys.stderr.isatty()` | **capability** | the exact bytes of each format; whether a flag or environment variable can force one |
| P3 | **Key-based** secret redaction happens inside the pipeline, so call sites cannot forget | F252; py `core/logging.py:93` `SENSITIVE_KEY_PARTS`, applied by `_redact_sensitive` (`:143`) as the **last** shared processor | **policy**, org-locked by CLI Design Standard R5.6 **(MUST)** | the key vocabulary, the mask string, and where in the pipeline it is enforced |
| P4 | Trace and span correlation is available but **optional**, gated behind an optional dependency set | F253, F304; py `core/logging.py:106` soft-imports `opentelemetry.trace`; py `pyproject.toml` declares a separate `otel` extra | **architectural pattern** | the gating mechanism: a Python extra versus a Cargo feature |
| P5 | An **explicit level** control exists ahead of the relative verbosity ladder | F254, F274; py `cli/options.py:85`; py `cli/context.py:197` `_resolve_console_level` | **standard**, org-locked by CLI Design Standard R4.4 **(MUST)** | the level names, the default, and the ladder's exact order |
| P6 | Re-initialisation is **idempotent and host-safe**: the pipeline never tears down machinery it does not own | F262; py `core/logging.py:226` iterates `root.handlers[:]` testing an owned-handler flag | **policy** | the mechanism, which is ecosystem-specific and very different in Rust |
| P7 | **One engine, two policy profiles** — the CLI and the web service share the pipeline and differ only in policy | F263; py `web/logging.py:20` "Same engine as the CLI (`core/logging.py`), different policy" | **architectural pattern** | whether the second profile exists at all, which is R69's `web-extra-surface` |
| P8 | Diagnostics go to **stderr**; the result stream stays clean | CLI Design Standard R7.1 **(MUST)** | **standard, org-locked** | nothing |

What must agree across py, ts and rs is P1–P8 **as capabilities and policies**. What may
vary is every mechanism. This decision differs from py on exactly four mechanisms, each
with measured or quoted ground: **(i)** the redaction insertion point moves from event
time to format time; **(ii)** the reconfiguration model changes, of which the fixity of
the *format* after initialisation is the one user-visible consequence; **(iii)** a
`--log-format` flag and `RSLBP_LOG_FORMAT` are added on the CLI, which py has only for
its file sink; and **(iv)** the ordering of `--debug` above the explicit level, which py
cannot answer because py has no `--debug`.

**The org standards, quoted at their lines.** Both blobs are pinned, and every quotation
below is re-asserted by `review/evidence/r58-standards.sh` against both the line number
and the text, so a rule that moves fails the check instead of passing quietly.

From the **CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`:

- **R4.1 (MUST)**, `:244` — `| Required global core | `--verbose` | `-v` | Increase diagnostic detail (repeatable; see R4.4). |`
- **R4.1 (MUST)**, `:245` — `| Required global core | `--quiet` | `-q` | Suppress non-essential output. |`
- **R4.4 (MUST)**, `:266` — "These three controls **MUST NOT** overlap ambiguously — define one ladder." and, in the same rule, "an explicit `--debug`, however, **MUST** override `--quiet`, since it is a deliberate request for diagnostics", and "`--log-level <level>` **MAY** be offered as an explicit alternative".
- **R5.1 (MUST)**, `:287`–`:291` — "**R5.1 — Precedence chain. (MUST)**" (`:287`); "Configuration **MUST** resolve in this order, highest priority first" (`:288`); "1. Command-line flags" (`:290`); "2. Environment variables (`TOOL_*`)" (`:291`). Every command-line flag outranks every `TOOL_*` environment variable, which is the ground of the ladder's order below.
- **R5.4 (MUST)**, `:322` — "Environment variables **MUST** use the uppercase `TOOL_*` prefix with a deterministic mapping (`--some-flag` → `TOOL_SOME_FLAG`…)". Its curated subset explicitly includes "output format".
- **R5.6 (MUST)**, `:332` — "Secret values (tokens, passwords, keys) **MUST** be masked in all output — `config view`, `--debug`/request logs, progress, and error messages — e.g. `sk_live_…****`."
- **R7.1 (MUST)**, `:381` — "fd 1 (stdout) carries the command's *requested result*; fd 2 (stderr) carries everything else: diagnostics, progress, prompts, warnings, and errors".
- **R7.3 (MUST)**, `:390` — "TTY state **MUST NOT** change the selected output *format*: `-o` (default `table`) determines the format regardless of whether output is a terminal or a pipe".
- **R7.8 (MUST)**, `:432` — the machine-readable error object "**MAY** carry `details`, `request_id`, or other documented fields".

From the **REST API Design Standard v2.0.0**, blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`,
binding on the HTTP surface by owner ruling W2-REST:

- **§1.9 R1.7**, `:271` — "**R1.7 — No silent deviation.** An API deviates from this standard only in writing… silent deviation from any rule strength is nonconformance regardless of the deviation's merits." This is the rule that makes `OVERRIDE (OV-09)` below mandatory rather than optional.
- **§1.10 reserved headers**, `:348` — "`request-id` | Response | Correlation ID, emitted on every response including errors. Lowercase name; RFC 6648 deprecates new `X-` prefixed fields, ruling out `X-Request-Id`".
- **R2.10 (MUST)**, `:533` — "Personally identifiable information MUST NOT appear in any URI — path or query string. URIs land in access logs, browser history, referrer headers, and URL-keyed caches by default."
- **R3.3**, `:599` — "**Exception:** logging and metrics side effects do not violate safety." The standard positively sanctions logging on safe methods; nothing in this pipeline needs an exemption from method discipline.
- **R8.2 (MUST)**, `:1323` — "Access tokens MUST NOT be accepted or emitted in URI query parameters."
- **§8.5 R8.12 (MUST)**, `:1422` — "Secrets, credentials, and PII MUST NOT appear in problem `detail`, in echoed request input, or in any other response content."
- **R8.12 provenance**, `:1427` — "Provenance: Apparatus — ratified at Gate D 2026-08-09 — gap review item **CLI-R5.6**."
- **R11.7 (MUST)**, `:1752` — "Every response, including errors, MUST carry the `request-id` correlation header (§1.10)."
- **R11.8 (MUST)**, `:1759` — "W3C Trace Context `traceparent` MUST be propagated; `tracestate` is accepted subject to a published size and entry cap."

**How the REST standard bears on a logging pipeline, read precisely.** R8.12 governs
**response content** — a problem document's `detail`, echoed request input, "any other
response content" — and its own provenance line names gap review item CLI-R5.6. So the
two standards are the two halves of one policy: the REST standard binds what a response
body may carry, and the CLI standard's R5.6 is the half that reaches **logs**. This
pipeline writes no response byte, so it cannot violate R8.12; its redaction obligation
comes from R5.6. Stating this explicitly matters, because reading R8.12 as the logging
rule would leave R5.6's stricter "all output" wording unapplied to the web profile.

Three REST rules do reach this decision, and each produces a constraint rather than a
departure:

1. **R11.7 and §1.10** fix the wire spelling of the correlation identifier as the
   lowercase header `request-id`. The **log field** is a different surface, and the CLI
   standard's R7.8 already spells the same concept `request_id` in machine output. This
   decision fixes the structured-log field name as **`request_id`** so that the template
   carries exactly two spellings, each mandated by the standard that governs its
   surface, rather than inventing a third. R75 emits the header; R58 fixes the field.
2. **R11.8 (MUST)** requires `traceparent` propagation on the HTTP surface
   unconditionally. This decision therefore constrains its own optional-feature
   boundary: the `otel` feature gates **export and log correlation, never propagation**.
   A default `--features web` build with `otel` off must still accept and forward
   `traceparent`, which needs no OpenTelemetry SDK. Were the boundary drawn any other
   way, a conformant default web build would be impossible. R78 and R75 inherit this as
   a fixed constraint, not as a suggestion.
3. **R2.10 and R8.2** keep PII and tokens out of URIs, and R2.10 gives the reason in the
   standard's own words: "URIs land in access logs". They reduce, but do not eliminate,
   the residual exposure recorded in `OVERRIDE (OV-09)`, because they bind the API this
   template serves and not the third-party URLs its client code may log.

**Architectural comparison, before any library is chosen.**

| | Record-and-render (`log` + `env_logger`/`fern`/`log4rs`) | Event-and-span (`tracing` + `tracing-subscriber`) | Structured-record with drains (`slog`) |
|---|---|---|---|
| P1 field model | the message is a formatted string; key/values are an opt-in side channel | **native**: fields are typed and named on `Event` and `Span` | **native**: typed key/value records |
| P2 TTY auto-format | possible in any renderer | possible; the profile is chosen when the subscriber is built | possible |
| P3 key-based redaction | **there is no key in the primary payload to match on** — executed, S9 | possible, but **only at format time**, because `Event` is immutable — executed, S1/S2 | **natural**: a `Drain` wrapper can rewrite key/values; the closest analogue to structlog |
| P4 OTel correlation | no span context to correlate | **first-class**: `tracing-opentelemetry` 0.34.0, published 2026-09-23 (newest as of the 2026-09-27T05:48:12Z snapshot; revision 1 cited 0.33.0 of 2026-05-18) from a sibling repository in the same org | third-party and thin |
| P6 host safety | `log::set_logger` succeeds once per process | `set_global_default` succeeds once, errors thereafter, plus a scoped `set_default` guard — executed, S4 | **no global at all**: `Logger` values are threaded explicitly, the most host-safe and the most invasive |
| P7 two profiles | two renderer configurations | two layer configurations from one builder | two drain stacks |
| Ecosystem pull | 30,894 reverse deps, but every surveyed project uses it only as a *bridge* | 43,201 reverse deps; the primary architecture of every project surveyed | 417 reverse deps; no surveyed project |

**The choice is `tracing`, and the deciding reasons are P3 and P4 — not popularity.**
The `log` architecture cannot express P3 at all, and that is not an inference. Probe
scenario **S9** put a secret in both places at once through the same redacting
formatter:

```
  INFO dep: connecting token=sk_live_LOGFACADE password=hunter2
  INFO r58probe: tracing side token="[REDACTED]"
```

The first line is a `log::Record` bridged into the pipeline: its payload is one
formatted string, there is no field named `token`, and the redacting formatter has
nothing to bind to, so the secret survives in clear. The second is a `tracing::Event`
carrying a field named `token`, and the same formatter masks it. Under a `log`-facade
core library, R5.6's **MUST** would have to be discharged at every call site — which is
precisely the failure mode P3 exists to prevent, and precisely what ts's complete
absence of a redaction step already demonstrates.

`slog` expresses P3 most naturally of the three, and it is rejected on two other
grounds: it has no maintained first-class OpenTelemetry bridge (P4), and its `Logger`
value is threaded through call sites, which would put a logging type into
`crates/core`'s public API and make R01's already-accepted port signatures carry it,
against R02 revision 2's crate-edge rule.

**Where the target ecosystem needs a different design — the finding that changes the
answer.** structlog's redaction is a *processor*: `_redact_sensitive` sits last in
`_shared_processors()` and rewrites a mutable `event_dict` before any renderer sees it,
so every sink inherits it for free. `tracing` has no analogue. A `tracing::Event` is
immutable and is **visited**, not transformed; a `Layer` can observe an event and can
decide interest, but it cannot hand a modified event to the next layer. Redaction must
therefore happen **where fields become bytes**, and `tracing-subscriber` offers exactly
two seams for that: the `FormatFields` trait and the `FormatEvent` trait.

Those two seams are **not symmetric between the human and the JSON formatter**, and the
asymmetry is load-bearing. Read in `tracing-subscriber-0.3.23` and asserted at their
lines by `review/evidence/r58-standards.sh`:

- `src/fmt/format/json.rs:253` — `let format_field_marker: std::marker::PhantomData<N> = std::marker::PhantomData;`. The `N: FormatFields` parameter is reduced to a marker and is used **only** to look up `FormattedFields<N>` for *span* fields.
- `src/fmt/format/json.rs:266` — the flattened branch serialises event fields itself: `let mut visitor = tracing_serde::SerdeMapVisitor::new(serializer);`.
- `src/fmt/format/json.rs:272` — the **non-flattened** branch bypasses `N` too: `serializer.serialize_entry("fields", &event.field_map())?;`.
- `src/fmt/format/json.rs:175` — span fields are re-parsed as JSON: `match serde_json::from_str::<serde_json::Value>(data) {`, and on failure `:200` panics with `span '{}' had malformed fields! this is a bug.` in debug builds.

**Executed (probe S1).** A redacting `FormatFields` installed with
`.json().fmt_fields(...)` redacted the *span* field and left every *event* field in
clear:

```
{"timestamp":"","level":"INFO","fields":{"message":"processing request","user":"alice","token":"sk_live_EVENTSECRET","password":"hunter2"},"target":"r58probe","span":{"api_key":"[REDACTED]","request_id":"abc-123","name":"request"},"spans":[{"api_key":"[REDACTED]","request_id":"abc-123","name":"request"}]}
```

That output is from the **default, non-flattened** branch, so the leak is a property of
the formatter and not of one builder option — both branches at `:266` and `:272` route
event fields through `tracing_serde` and never through `N`.

**Executed (probe S2) — the working design.** A **template-owned** `FormatEvent` plus a
**template-owned** JSON `FormatFields` redacts both, and stdout stays byte-clean:

```
S2-STDOUT:RESULT-ON-STDOUT
{"level":"INFO","target":"r58probe","message":"processing request","user":"alice","token":"[REDACTED]","password":"[REDACTED]","span":{"request_id":"abc-123","api_key":"[REDACTED]"}}
```

Two cheaper mechanisms were ruled out first, so that "write it yourself" is a conclusion
rather than a preference. Both are compiler facts, reproduced on rustc 1.98.0:

- **Wrapping `JsonFields`** is impossible: `error[E0277]: the trait bound 'JsonFields: MakeVisitor<Writer<'_>>' is not satisfied`, and the compiler's own help enumerates the types that do implement it — `Alt`, `DefaultFields`, `Delimited`, `FieldFn`, `Messages`, `PrettyFields`. Note that the crate's **own doc comment** at `src/fmt/format/json.rs:422` refers to "[`JsonFields`]'s [`MakeVisitor`] implementation": the documentation claims an implementation that does not exist, which is why this had to be settled against the compiler rather than the docs.
- **Interposing on the field stream** is impossible: `RecordFields` is sealed (`src/field/mod.rs:88`, `pub trait RecordFields: crate::sealed::Sealed<RecordFieldsMarker> {`), so a `Redacted<R>(R)` adapter cannot exist — `error[E0277] … 'RecordFields' is a "sealed trait"`.
- A third combination is not merely unhelpful but rejected by the type system: `.json().fmt_fields(DefaultFields::new()).flatten_event(true)` gives `error[E0599]: no method named 'flatten_event' found for struct 'tracing_subscriber::fmt::Layer<_, DefaultFields, Format<Json>>'`. The JSON profile's builder surface is typed against `JsonFields` specifically.

The **human** profile is different and needs no owned event formatter: `DefaultFields`
**does** implement `MakeVisitor` (`src/fmt/format/mod.rs:1228`), so a thin wrapper
works, and `rust-lang/rustup` ships the same delegation in production. **Executed (probe
S3)**, one wrapper redacted both span and event fields:

```
  INFO request{request_id="abc-123" api_key="[REDACTED]"}: r58probe: processing request user="alice" token="[REDACTED]" password="[REDACTED]"
```

**Consequence for the `json` Cargo feature.** Because the structured profile is
template-owned, `tracing-subscriber`'s `json` feature is **not needed**. Measured: it
adds exactly **two** crates, `serde` 1.0.229 and `tracing-serde` 0.2.0, for a formatter
the template replaces. The owned formatter writes through `serde_json`, which R66's
published decision already places in the tree.

**P3, stated completely, including what it does not reach.** The policy is three
layered defences: (1) a secret's *type* refuses to render — `secrecy::SecretString`,
R56 revision 2's accepted crate, **executed (probe S7)** rendering
`secret_value=SecretBox<str>([REDACTED])`; (2) the formatter masks by key name for
anything not so typed, using F252's vocabulary verbatim — `token`, `password`, `secret`,
`authorization`, `api_key`, `apikey`, `credential`, `cookie`, matched as an
ASCII-lowercased substring, masked to `[REDACTED]`; (3) a regression test asserts both.
What that does **not** reach is a secret carried inside a non-sensitive field's *value*,
and this decision records that rather than letting R5.6's "all output" stand unqualified.

**OVERRIDE (OV-09) — CLI Design Standard R5.6 (MUST) is discharged in part, not in
full.** Recorded in the shape of the REST standard's §1.9 deviation note, which owner
ruling W2-REST makes the required form, and numbered by the controller rather than by a
scoped search, because two syntheses collided on a self-allocated number.

> Rule: CLI Design Standard v1.4.14 R5.6 · strength **MUST** · what differs: secret
> values are masked when they appear under a field key matching F252's vocabulary, or
> when their Rust type is `secrecy::SecretString`; a secret embedded inside the *value*
> of a field whose key is not sensitive is **not** masked · why: below · approver:
> pending owner acceptance of this decision · date: 2026-09-18.

**Argument.** R5.6 says secrets "**MUST** be masked in all output". A key-based
mechanism cannot satisfy that literally, and asserting otherwise would be the kind of
sentence stated more absolutely than its evidence that this programme rejects. **Executed
(probe S10)**:

```
KEYED_SECRET_MASKED=true
IN_VALUE_SECRET_MASKED=false
  INFO r58probe: redaction gap url="https://api.example.com/v1/x?token=sk_live_INURL" token="[REDACTED]"
```

The same record masks the secret under the key `token` and prints the secret embedded in
the `url` value. The exposure is narrowed from three directions and closed from none:
CLI R5.5 **(MUST)** keeps secrets out of argv; REST R8.2 **(MUST)** keeps access tokens
out of the query strings of the API this template *serves*; REST R2.10 **(MUST)** keeps
PII out of its URIs. None of the three binds a third-party URL that this template's own
client code might log, which is exactly where the residue lives.

**Options.**

| Option | What it costs | What it buys | Disposition |
|---|---|---|---|
| **(a) Key-based masking plus `secrecy` typing, with the gap declared** | roughly 120 lines of template code and this override | the whole of py's F252 behaviour, plus a type-level defence py does not have, with the residue named so R75 and P03 can act on it | **adopted** |
| (b) Add a value-shaped scan — a regex for `sk_live_`-style tokens over rendered output | a pattern list that ages badly, plus a per-event scan cost, plus false positives that corrupt legitimate text | closes part of the residue for secrets whose *shape* is known | rejected: it cannot distinguish a key from a value, and the template has no shape vocabulary to scan for |
| (c) Type every secret, and mask nothing by key | zero formatter code | full compile-time safety, for values a call site remembered to type | rejected: R5.6 reaches a header map logged by `Debug`; this is the discipline F252 exists to remove |
| (d) Declare R5.6 satisfied and say nothing | nothing | nothing | rejected outright: R1.7's "silent deviation from any rule strength is nonconformance regardless of the deviation's merits" is the rule this programme is being held to |

**Resulting obligation, which is the point of recording it.** P03's acceptance test asserts
the gap's *boundary* rather than pretending it is closed; R75 must not log a raw request
URI on the access-log path without applying its own policy, and this decision names that
as R75's, since R75 owns F320; and R78 inherits the same rule for exporters, stated under
the telemetry member's *Migration implications*.

**P6 — "only tears down handlers it owns", in Rust's global-subscriber model.** Rust
cannot express py's mechanism and should not try. Four facts, each executed or quoted:

1. The global dispatcher is installed **once**. **Executed (probe S4)**:
   `FIRST_IS_OK=true`, `SECOND_IS_ERR=true`. The Rust equivalent of "tear down only what
   you own" is therefore stronger and simpler — **never install anything you do not
   own**: call `try_init()`, never `init()` (which is `try_init().expect(..)`,
   `src/util.rs:94`), and never panic, replace or tear down.
2. `try_init()` also installs the `log` bridge, in that order: `src/util.rs:62` sets the
   global dispatcher, then `:69` installs `tracing_log::LogTracer::builder()` with the
   subscriber's max-level hint. **Executed (probe S6)**, a `log::info!` rendered through
   the `fmt` layer with **no** bridge call in template code at all.
3. **An `Err` from `try_init()` has two causes, and only one of them means a host owns
   diagnostics.** Because `:62` runs before `:69`, a host that installed a `log` logger
   but no `tracing` dispatcher makes `try_init()` return `Err` **after** the template's
   dispatcher is already global, which cannot be undone. **Executed (probe S4b)**: with a
   `log::set_logger` host in place, `TRY_INIT_IS_ERR=true`, and an `info!` issued after
   the failed call still rendered through the template's layer
   (`S4B:  INFO r58probe: S4B:PARTIAL-HOST-EVENT`); checks S4c and S4d, both PASS in the
   re-recorded `r58-probe.log`. So `telemetry::init` checks
   `tracing::dispatcher::has_been_set()` (a re-export of
   `tracing-core-0.1.36/src/dispatcher.rs:340`, marked `#[doc(hidden)]`) **before**
   calling `try_init()`. A dispatcher already set means a host owns diagnostics:
   `init` installs nothing and returns `Init::HostOwned`. Otherwise it calls
   `try_init()`: `Ok` returns `Init::Installed(Handles { .., log_bridge_refused: false })`,
   and `Err` can then only mean the `log` bridge was refused, so it returns
   `Init::Installed(Handles { .., log_bridge_refused: true })` with the `reload::Handle`
   kept, because the template's dispatcher is live. The one gap is a host that installs
   a dispatcher on another thread between the check and the call; `init` runs first in
   `main`, before any thread the template starts, so the template does not create that
   race.
4. Embedders and tests use the **scoped** path: `SubscriberInitExt::set_default` returns
   a guard and deliberately ignores the bridge error — `src/util.rs:43`,
   `let _ = tracing_log::LogTracer::init();`. Every `#[test]` gets its own.

**Reconfiguration within one process** is therefore not "replace the subscriber" but
"swap a layer behind a `reload::Handle`". **Executed (probe S5)**: installed with
`EnvFilter::new("warn")`, an `info!` before the swap produced nothing; after
`handle.modify(|f| *f = EnvFilter::new("debug"))`, both the `info!` and a `debug!`
rendered. This solves the template's real two-phase problem: **logging must exist before
the configuration file is read**, so that a config parse failure can be logged at all,
yet F274's ladder has a config-file tier. The composition root installs early from flags
and environment, then swaps the filter once the configuration layer resolves.

**Migration risk to record.** py's `configure_logging` can change the *format* on
reconfiguration; this design cannot. The writer and the event formatter are fixed at
`try_init` time, because putting the `fmt` layer behind `reload::Layer` costs a lock
acquisition on **every event** for a capability no requirement asks for. The
console-versus-JSON decision is an initialisation-time decision in Rust and a
runtime-mutable one in Python. Nothing in F250–F263 needs the Python behaviour, but a
P03 implementer porting tests one-for-one will meet it.

**P2 and R7.3 — why TTY auto-selection here is conformant, and why it looks like it is
not.** R7.3 **(MUST)** at `:390` governs the **result stream** and the `-o` selector R66
owns. The log stream is diagnostics on fd 2, which R7.1 at `:381` places outside the
result stream entirely. Auto-selecting the *diagnostic* render mode from
`std::io::stderr().is_terminal()` therefore does not touch R7.3's subject. This is
stated explicitly because it is the one place where F250 and the standard appear to
collide and do not.

**P5 — the resolution ladder (F274), which this item owns.** R4.4 requires one
unambiguous ladder, and R5.1 **(MUST)** requires every command-line flag to outrank every
`TOOL_*` environment variable. The total order, highest priority first:

| # | Input | Effect | Ground |
|---|---|---|---|
| 1 | `--debug` | `TRACE` **plus** internal detail: target, file, line, thread name | R4.4 **(MUST)**: "`--debug` is equivalent to the maximum level plus internal detail" and "an explicit `--debug`, however, **MUST** override `--quiet`". Placing it above `--log-level` as well is **this template's choice**, extended from that sentence's reason: a bug-report switch that an explicit `--log-level error` could silence would not be one. py has no `--debug`, so py's ladder cannot answer this. |
| 2 | `--log-level <level>` | exact level | R4.4 **(MAY)**: "`--log-level <level>` **MAY** be offered as an explicit alternative". F254. |
| 3 | `--quiet` / `-q` | `ERROR` | R4.4: `-q` "suppresses progress and informational diagnostics on stderr only; it **MUST NOT** suppress the requested result on stdout". |
| 4 | `-v` × n | `INFO`, `DEBUG`, `TRACE` for n = 1, 2, ≥ 3 | R4.1 `:244` and R4.4 make `-v` repeatable; F273 is `COMMON → REUSE` and is not a research item. |
| 5 | `RSLBP_LOG_LEVEL` | exact level | R5.1 **(MUST)** `:290`–`:291`: environment variables rank below every command-line flag, so this rung sits under rungs 1–4. R5.4 **(MUST)** fixes its name as the deterministic mapping from `--log-level`, whose own ❌ example forbids inventing a different name; that governs the name, not the rank. The `RSLBP_` prefix is the one R56 revision 2 already uses. Bound through the parser's environment support, which R60's published decision has already selected. |
| 6 | config file `[logging].level` | exact level | F274's config tier, reached through the `reload::Handle`. R5.1 places configuration files below environment variables. The key's home is R54's and R59's to confirm. |
| 7 | default | `WARN` | py's default. A CLI whose result is on stdout should say nothing on stderr when nothing is wrong. |

So `RSLBP_LOG_LEVEL=debug rslbp -q …` resolves to `ERROR`: the explicit `-q` wins over the
inherited variable, because R5.1 lists command-line flags and `TOOL_*` environment
variables as separate tiers with flags first. The same order is owner-accepted R54 revision 3's (`docs/port/OWNER-ACCEPTANCES.md:78`,
"flags (clap, R60) > RSLBP_* environment > …").

Three deliberate departures from a source repository, each with ground:

- **`RSLBP_LOG_LEVEL` sits below `-q` and `-v`, not beside `--log-level`.** py's
  F274 ladder at `cli/context.py:197`–`:209` resolves "`--log-level` (or env) > `-q`/`-v` >
  config > WARNING", so an inherited environment level beats an explicit `-q` in py. This
  decision departs from py F274 on the ground of CLI R5.1 **(MUST)**, which binds this
  template (owner decision 9) and ranks every flag above every environment variable; py's
  order is a precedent, and a precedent does not waive a MUST.
- **`-q` maps to `ERROR`, not `WARN`.** ts maps `--quiet` to `'warn'`
  (`src/lib/logger.ts:36`); py maps it to `ERROR`. Because rung 7 is already `WARN`,
  ts's mapping would make `-q` a **no-op at the default level**, and R4.4's "define one
  ladder" is precisely a rule against rungs that do nothing. Agreeing with py.
- **`--log-format <auto|console|json>` and `RSLBP_LOG_FORMAT` exist**, which py's CLI
  does not have. R5.4's curated subset explicitly includes "output format", and
  `--log-format` → `RSLBP_LOG_FORMAT` is its deterministic mapping. `auto` resolves to
  `console` when `std::io::stderr().is_terminal()`, else to `json`. The rejected
  alternative — forcing `json` whenever R66's machine result format is active — is
  recorded and not adopted: R67's error envelope is already JSON on stderr under machine
  mode regardless of this setting, so a developer piping stdout to a JSON tool from a
  terminal keeps readable diagnostics without losing a parseable envelope.

**P7 — one engine, two profiles, and it holds either way R69 lands.** The answer is
neither of the two shapes the prompt's LOW question offers, because **one process runs
one binary**: R69's accepted value gives the web surface its own
`[[bin]] name = "<app>-serve"` with `required-features = ["web"]`. There is therefore one
subscriber per process, built from one shared builder in the composition root, with a
`Profile` value selecting policy.

| | the CLI binary (R49 fixes the name `rslbp`) | the serve binary (R69 writes it `<app>-serve`) |
|---|---|---|
| Format | `auto` → console on a TTY stderr, JSON otherwise | `RSLBP_WEB_LOG_FORMAT`, value set `json` or `console`, default `json`, with no `auto` and no TTY test: structured output is the production contract, and `console` exists for R69's dev-server recipe, which exports `<APP>_WEB_LOG_FORMAT=console`. Any other value is rejected by the `FromStr` that R77's `WebSettings::from_env()` calls, failing as R67's `RSLB203` before `telemetry::init` runs |
| Level source | the seven-rung ladder above | environment only, twelve-factor; the variable names are R77's `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`, parsed by R77's `WebSettings::from_env()` and passed into `Profile::Service { level, format }` |
| Default level | `WARN` | `INFO` |
| Colour | R65's resolved `anstream::ColorChoice`, passed to `.with_ansi(bool)` | never |
| Extra layers | none | R75's request-span layer; R78's OTel layer under `otel` |
| File sink | R59's | none |

If R69 had landed "no web surface", the CLI profile is the whole answer and nothing above
changes. The design does not assume a web surface exists. The serve binary's **name** is
not R58's to settle; only the string would change.

**Crate edges (R02 revision 3, published, sha256
`d8c64f7c36663f0c92dcc83cc444a56f203f6c4f52d3fff2a64de9f611cfd2e7`).** R02 fixes the
mechanism only: a four-package workspace, the composition root in the root package, and
a `cargo deny --all-features check bans` `[bans] deny[].wrappers` rule plus a
`crates/core` external-dependency allow-list in `tests/workspace_edges.rs`. R02 says
nothing about `tracing`, a subscriber or logging. **This decision adds** the
`tracing`-only edge for the core package, the `tracing-subscriber` `wrappers` row, and
the allow-list entry for `tracing`:

| Package | May depend on | Must not depend on |
|---|---|---|
| `rs-launch-blueprint` (root: composition root, both binary targets, `src/telemetry.rs`) | `tracing` with default features, **`tracing-subscriber`** — the only package that may name it — and `serde_json` | — |
| `rs-launch-blueprint-core` (`crates/core/`) | `tracing` with `default-features = false, features = ["std"]` | any subscriber, any formatter, any writer |
| `rs-launch-blueprint-cli` (`crates/cli/`) | `tracing`, the facade only | `tracing-subscriber` |
| `rs-launch-blueprint-web` (`crates/web/`) | `tracing`, the facade only; axum's default `tracing` feature already emits into it | `tracing-subscriber` |

**Executed — the measured cost of that edge rule** (`cargo tree -e normal`,
deduplicated, package itself excluded; asserted by `review/evidence/r58-probe.sh` S11):

| Manifest | Crates | Delta |
|---|---|---|
| `tracing` `default-features = false, features = ["std"]` — the `crates/core` line | **4** (`tracing`, `tracing-core`, `once_cell`, `pin-project-lite`) | baseline |
| `tracing` with default features (`std` + `attributes`) | **9** | +5, all of them the proc-macro chain: `proc-macro2`, `quote`, `syn`, `unicode-ident`, `tracing-attributes` |
| the recommended root line: `tracing` defaults + `tracing-subscriber` `env-filter` over defaults + `serde_json` | **26** | +17 over the facade |
| the same with `json` on | **28** | +2: `serde`, `tracing-serde` |

So a subscriber costs the **composition root** 17 crates and the **core library** zero.
That is the concrete reason the edge rule matters, and it matches `rust-lang/cargo`'s own
manifest exactly. The `env-filter` feature accounts for 3 of the 17 — `matchers`,
`regex-automata`, `regex-syntax`.

**R05 revision 3 (owner-accepted, sha256 `3ca4b81abf4df024d39698815da3820321f91532da52403f8bf7dc07060934ca`; an evidence-only re-bind of revision 2 with the same substance, ureq 3.4.2 and synchronous) — no runtime in the default tree.** The 26-crate
root tree contains no `tokio`, no `async-std` and no executor of any kind; neither
`tracing` nor `tracing-subscriber` has an async-runtime coupling in the feature set
selected. Verified by the same `cargo tree` output. The bridge matters here for a
concrete reason: R05's accepted HTTP client reaches the network synchronously, and the
`log` facade is how crates of that kind report retries, redirects and TLS detail, so
without the bridge a `-vv` network command would show nothing from the transport.

**ANSI safety, and why the version floor is what it is.** RUSTSEC-2025-0055 /
CVE-2025-58160 against `tracing-subscriber`, category `format-injection`, issued
2025-09-02, **Patched >= 0.3.20** — that is why the floor is not simply "0.3".
**Executed (probe S8)**, 0.3.23 emits no raw ESC (`0x1b`) and no raw BEL (`0x07`) byte,
rendering the field as `untrusted="\u{1b}[31mRED\u{1b}[0m\u{7}"`; the redacting wrapper
preserves that escaping, and the owned JSON formatter inherits JSON's own
control-character escaping. The owned formatter therefore does not reopen the advisory's
hole.

**Reference-architecture reconciliation (owner decision 11, STANDING INPUT).** Section 11
makes the document an owner-supplied research input that "binds process, not outcome",
directs overlapping items to reconcile row by row, records rows belonging to other items
as hand-offs, and states that owner-fixed parameters override any value the document
gives. Rows this item touches:

| Row | The document says | This item | Verdict |
|---|---|---|---|
| C10 Logs/traces, `:68` | "**tracing + tracing-subscriber (JSON)** (+ tracing-stackdriver) 0.1 / 0.3" | the same two crates, at exact pins 0.1.44 and 0.3.23 rather than minor-level `0.1`/`0.3` | **agree** |
| Reference `Cargo.toml`, `:178` | `tracing = "0.1"` | the same, pinned to 0.1.44 | **agree** |
| Reference `Cargo.toml`, `:179` | `tracing-subscriber = { version = "0.3", features = ["env-filter","json"] }` | `env-filter` yes; **`json` no** — measured ground: the stock JSON event formatter cannot redact event fields (probe S1), so the feature would add 2 crates for a formatter the template replaces | **differ** |
| C10 stream, `:111` | "Emit **JSON logs to stdout** with `tracing-subscriber`'s JSON formatter" | **stderr**, on org-locked ground: CLI R7.1 **(MUST)** at `:381` reserves stdout for the requested result, and R67's accepted envelope requires stdout to stay byte-empty on the error path. Cost of differing: none — every container runtime captures both descriptors | **differ** |
| C10 GCP shaping, `:111` and `:180` | `tracing-stackdriver = "0.10"`, severity mapping, `logging.googleapis.com/trace` from `X-Cloud-Trace-Context` | **not adopted**: last published 2024-03-11, no declared `rust_version`, 293,363 90-day downloads, and it binds the template to one cloud. The owned `FormatEvent` is the exact seam a deployment would use to add severity mapping, so nothing is foreclosed; trace-header correlation is R78's | **differ** |
| C10 error reporting, `:69` | `sentry` + `sentry-tower` | **not decided**: no P02 item owns error reporting, so section 11's "rows with no P02 item are NOT decided" applies | **hand-off** |
| Layout, `:236`, `:241`, `:324` | `main.rs` bootstraps tracing; `telemetry.rs` holds "JSON logs + trace correlation"; `telemetry::init()` runs first in `main` | the same, with the module at `src/telemetry.rs` in the root package, which is where R02 already puts the composition root, called before anything that can log | **agree** |

**Tally over those seven rows: 3 agree, 3 differ, 1 hand-off.** This is stated because
the Opus leg reported "5 agree, 2 differ" over the same seven rows, and that tally does
not reconcile with its own table: it counted the split `:179` row as an agreement and
left the `tracing-stackdriver` row out of both columns. Each row above is re-checked and
labelled individually, and the recount is the number this decision carries.

**Minimal realistic example (proposed; P03 builds it).** `src/telemetry.rs` in the root
package: a `Profile` enum (`Cli { format, level, ansi }`, `Service { level, format }`,
where the service `format` is `Json` or `Console`); one
`pub fn init(profile: Profile) -> Init` returning
`enum Init { Installed(Handles), HostOwned }` where
`Handles { level: reload::Handle<EnvFilter, Registry>, log_bridge_refused: bool }`; and a
`redact` submodule holding the F252 vocabulary as a `const` array, the `[REDACTED]` mask,
an `is_sensitive(&str) -> bool`, `HumanFields(DefaultFields)` for the human profile, and
`JsonFields` plus `JsonEvent` for the structured one. `crates/core`, `crates/cli` and
`crates/web` contain no part of this. `crates/core` and `crates/web` call `tracing`'s
event macros (`tracing::info!` and its siblings) and `tracing::span!` only: their
`features = ["std"]` line leaves out `attributes`, and `tracing-0.1.44/src/lib.rs:971`–`:974`
compiles the `instrument` re-export only under `#[cfg(feature = "attributes")]`, so
`#[tracing::instrument]` does not build there. `crates/cli`, which takes `tracing`'s
default features, may also use `#[tracing::instrument]`.

**The two extension slots, left open on purpose.** Neither is decided here, and each
names what its owner must decide:

- **R78, OpenTelemetry — a layer slot** in `telemetry::init` where
  `tracing_opentelemetry::layer()` composes into the same `Registry` under an
  `otel = ["web", ...]` feature nesting on R69's `web`, plus a matching
  `trace_id`/`span_id` serialisation point in the owned `FormatEvent`, immediately after
  `level` and `target`. With the feature off the keys are simply absent, which is what
  py's soft import does and what `rust-lang/rustup` does with a `#[cfg(feature = "otel")]`
  layer function. **Two constraints R78 inherits rather than chooses:** `traceparent`
  propagation is **not** gated by this feature, per REST R11.8 **(MUST)**; and redaction
  is a property of *rendered output*, so any exporter R78 adds sees unredacted fields and
  must apply the policy itself.
- **R59, the file sink — a sink slot** in `init` where a second `Layer` with its own
  `MakeWriter` and its own per-layer `Filter` attaches to the same `Registry`. Per-layer
  filters are how `tracing-subscriber` gives a sink a level independent of the console,
  which is what F256 and F260 will need. Nothing about the file sink is decided here.
- **R75, the access log — a placement, not a slot.** R75 owns F320 and F327: where the
  request-span layer sits in the middleware order, and what the access log records.
  What this decision fixes for it is the field name `request_id`, the `stderr`
  destination, and the OV-09 obligation not to log a raw request URI without its own
  policy.

**BASELINE-REVIEW.** No new `BASELINE-REVIEW:` finding is raised by this item. F304's
reclassification from `ADOPT` to `DIVERGENT` was made on 2026-09-04
(`docs/port/BASELINE-REVIEW.md:330`, affected items R58, R69, R78) and this decision
**implements** it — R58 sets the optional OTel boundary inside R69's `web` surface, R78
integrates, and the working OTel web example stays an owner requirement rather than an
optional outcome — rather than challenging it. The three challenged-baseline conditions
the prompt asks about are therefore all negative: no row's principle is disputed, no row
is proposed for reclassification, and no other item's ledger entry is changed.

### Recommendation

One stack, four members, three of them crates and one of them template-owned code.

Adopt **`tracing` 0.1.44 as the sole diagnostic facade in every package**, taken
`default-features = false, features = ["std"]` by `crates/core` and `crates/web` and with
its defaults by the root package and `crates/cli`; **`tracing-subscriber` 0.3.23 with
`features = ["env-filter"]` over its default set (`smallvec`, `fmt`, `ansi`,
`tracing-log`, `std`), declared on the root package only**, with `json` **off** and
`local-time` **never** enabled; **`tracing-log` 0.2.0 reached only through
`tracing-subscriber`'s default `tracing-log` feature** and never declared in a manifest;
and **a template-owned `src/telemetry.rs`** supplying the redacting `FormatFields` for
the human profile and the redacting `FormatEvent` plus `FormatFields` pair for the
structured profile. One `telemetry::init(Profile)` in the composition root calls
`try_init()` and never `init()`, returns a `reload::Handle<EnvFilter, Registry>` for the
configuration-file tier of the level ladder, writes every byte to stderr, and leaves the
R78 layer slot and the R59 sink slot explicitly marked.

### Members

#### tracing

##### Landscape

The facade bin of the *established industry standard* row: the call-site API every
package in the workspace names, and the only logging crate the library core is permitted
to depend on. Its competitor in that bin is `log` 0.4.34; its competitor in the
structured-record bin is `slog` 2.8.2. `tracing` is the more depended-upon of the two
facades — **43,201** reverse dependencies against `log`'s **30,894**
(`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1`, field
`meta.total`, snapshot retrieved 2026-09-27T05:48:12Z).

##### Principles and implementation

`tracing` supplies P1 (typed named fields on `Event` and `Span`), the span parent chain
P4 needs, and the `Dispatch` indirection P6 needs. It supplies **no** rendering, no
filtering beyond compile-time level features, and no process-global installation beyond
`set_global_default`. That separation is what makes it safe in a library crate:
`crates/core` gains the ability to emit and gains no opinion about where the bytes go.

The feature line matters and is measured, not assumed. **Executed**:
`default-features = false, features = ["std"]` resolves to **4** dependency crates; the
default set resolves to **9**, the extra five being the `attributes` proc-macro chain
(`proc-macro2`, `quote`, `syn`, `unicode-ident`, `tracing-attributes`). `rust-lang/cargo`
draws the same line for the same reason.

##### Dominant choice

`tracing` 0.1.44, published 2025-12-18 (`GET https://crates.io/api/v1/crates/tracing/versions`,
newest entry with `yanked: false`: `num` `0.1.44`, `created_at` `2025-12-18`). Note that
**0.1.42 is yanked** — asserted in `review/evidence/r58-figures.sh` — so a naive "latest
version" pin would land on a yanked version's number.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence (observed) | 90-day downloads | All-time |
|---|---|---|---|---|---|
| `tracing` 0.1.44 | 2025-12-18 | 1.65.0 | MIT | 198,651,206 | 877,269,566 |
| `log` 0.4.34 | 2026-08-22 | 1.71.0 | MIT OR Apache-2.0 | 292,355,635 | 1,291,450,844 |
| `slog` 2.8.2 | 2025-10-11 | 1.61 | MPL-2.0 OR MIT OR Apache-2.0 | 8,457,982 | 77,773,432 |

All from `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `/versions`, snapshot retrieved 2026-09-27T05:48:12Z.

`log` passes every gate and is **not excluded — it is kept, in a different role**: it
stays in the tree as the *source* of records from dependencies, bridged by `tracing-log`.
It is rejected only as the template's own call-site API, on P3 and P4, and on executed
evidence (probe S9) rather than on preference.

##### Excluded by gate

Nothing in this member's shortlist is excluded by a fitness gate.

Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`. The observed licence string
is recorded above as registry fact.

Gate 2 (MSRV): the floor today is **1.96**, being stable 1.98 minus two minor versions.
`tracing` declares `rust_version` 1.65.0, `log` 1.71.0 and `slog` 1.61 — all within it,
asserted in `review/evidence/r58-figures.sh`.

Gate 3: `https://rustsec.org/packages/tracing.html` returns HTTP 200 and lists exactly
one advisory, **RUSTSEC-2023-0078**, whose own page states `Type INFO Unsound`,
`Patched >=0.1.40` and `Unaffected <=0.1.37`. 0.1.44 is outside the affected range, so
there is **no open advisory**. `unsafe` posture: the crate does not carry
`forbid(unsafe_code)`; unsafe blocks exist in `tracing-core` beneath it, and R06's
published `unsafe-code-policy` is the authority on where the template places the
attribute.

Gate 4: `tokio-rs/tracing` CI runs `cargo test` on `ubuntu-latest` and `macos-latest` —
both required runners — and additionally on `windows-latest`, which is noted and not
required.

Gate 5: default features are `["std", "attributes"]`; **no async-runtime coupling** in
any feature used here, confirmed by the 26-crate root tree containing no executor.

Gate 6: **executed** — 4 crates for the `["std"]` line, 9 for the default set.

##### Up-and-comers

`fastrace` 0.7.19 (Apache-2.0, `rust_version` 1.91.0, published 2026-07-31) and
`logforth` 0.30.1 (Apache-2.0, `rust_version` 1.89.0, published 2026-06-03), both from
the `fast` organisation, both actively published. Neither is shortlisted. `fastrace` is a
tracing-only library with no console or JSON logging profile, no redaction seam and no
`log` bridge, so it answers a different question; its `rust_version` 1.91.0 also sits
closest of any candidate to the moving 1.96 floor, which is worth re-checking. `logforth`
is a *`log`-architecture* appender framework and therefore inherits `log`'s P3 and P4
failure demonstrated in probe S9.

##### Fit for this template

Exact, for a reason specific to this template's three-surface shape: the facade is the
*only* thing the library core needs, and `tracing` is designed so that a library takes it
and nothing else. Both source repositories point the same way at the principle level —
py's structlog call sites also emit key/value events rather than strings — and `tracing`
is the Rust expression of that principle. The four-crate `["std"]` footprint is small
enough that putting the facade in `crates/core` costs nothing an auditor would object to.

##### Recommendation

`tracing = { version = "0.1.44", default-features = false, features = ["std"] }` in
`crates/core/Cargo.toml` and `crates/web/Cargo.toml`; `tracing = "0.1.44"` with default
features in the root package and `crates/cli`. Pin at the patch level and let Cargo's
caret range float within 0.1.x, matching `rust-lang/cargo`'s own line.

##### Ranked runner-up

`log` 0.4.34 as the call-site API with `env_logger` 0.11.11 as the renderer. Ranked
second because it is the only alternative every Rust developer already knows and it costs
roughly five crates in total. It loses on P1, P3 and P4, and probe S9 is the executed
demonstration of the P3 loss. If the owner ever struck P3 and P4 from the requirement
set, this is the stack that would win on cost.

##### Tradeoffs

Gained: a field model, spans, a maintained OpenTelemetry bridge, and a `log` bridge that
brings dependencies' diagnostics into the same pipeline. Paid: 4 crates in `crates/core`;
a 0.1.x version line that has never reached 1.0, mitigated by 877,269,566 all-time
downloads and the Tokio project's stewardship, so that a breaking 0.2 would be an
ecosystem event rather than a quiet bump; and a mental model — spans, events, subscribers
— that a contributor arriving from `log` must learn.

##### Parameters

Contributes the facade clause of `logging-pipeline-contract`. It consumes
`rust-edition = 2024` and `msrv-policy` — the probe manifest declared `edition = "2024"`
and `rust-version = "1.96"` and resolved and built — `target-os-matrix`, answered under
gate 4, and `license`, which is `inapplicable` per the owner ruling of 2026-09-12.

##### Migration implications

py's `structlog.get_logger(__name__)` becomes `tracing::info!(field = value, "message")`
at the call site, with no logger object to obtain and nothing to inject. py's
`_shared_processors()` has **no** call-site analogue: everything it did moves into the
subscriber. ts has nothing to migrate — `createLogger`'s injected-writer shape
(`src/lib/logger.ts:56`) disappears entirely, because the writer is now the subscriber's,
chosen once at the composition root.

##### Validation strategy

Proposed for P03: `cargo tree -e normal -p rs-launch-blueprint-core` must show `tracing`,
`tracing-core`, `once_cell` and `pin-project-lite` and **not** `tracing-subscriber`,
`tracing-attributes`, `syn`, `serde` or `serde_json` — an assertion this decision adds
to the `crates/core` allow-list in R02's `tests/workspace_edges.rs`, whose mechanism R02
fixes and whose `tracing` entry R02 does not carry. **Executed here** for the
equivalent manifest: the `["std"]` graph is exactly 4 crates and the default graph is
exactly 9 (`review/evidence/r58-probe.sh`, S11a and S11b).

##### Confidence & re-verify trigger

**High.** Re-verify when `tracing` publishes 0.2, or any 0.1.x that raises `rust_version`
above the then-current floor; when RustSec publishes any advisory against `tracing` or
`tracing-core`; when `rust-lang/cargo` moves off `tracing`; or by 2027-03-18. The
repository-level maintenance signal shared with `tracing-subscriber` is measured and
argued under `### Confidence & re-verify trigger` below, and shortens that cadence to
2026-12-18 for the maintenance question alone.

##### Sources

`GET https://crates.io/api/v1/crates/tracing` and `/versions` and
`/reverse_dependencies?per_page=1`; `GET https://api.github.com/repos/tokio-rs/tracing`;
`GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+is:open`;
`https://rustsec.org/packages/tracing.html` and
`https://rustsec.org/advisories/RUSTSEC-2023-0078.html` — all snapshot-retrieved by the
single fetch invocation stamped 2026-09-27T05:48:12Z, in which the advisory page was
fetched at 2026-09-27T05:48:10Z (its `RUSTSEC-2025-0055` twin at 05:48:11Z) and logged
as `rustsec advisory:` lines in `review/evidence/r58-fetch-snapshots.log`, and asserted
by `review/evidence/r58-figures.sh`.
`https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml` and the `rustup`,
`rust-analyzer`, `uv` and `ruff` manifests, read 2026-09-18. Probe scenarios S9 and S11
in `review/evidence/r58-probe.sh`, log `review/evidence/r58-probe.log`.

#### tracing-subscriber

##### Landscape

The subscriber and renderer bin's dominant member: the crate supplying `Registry`, the
`Layer` composition model, `EnvFilter`, `reload::Layer`, and the `fmt` layer with its
`FormatEvent` and `FormatFields` seams — 19,039 reverse dependencies. Its competitors are
the `log`-architecture renderers `env_logger` 0.11.11, `fern` 0.7.1 and `log4rs` 1.4.0,
and the `slog` drain stack. None of them can subscribe to a `tracing::Event` at all, so
the comparison between them is the comparison between architectures, already settled.

##### Principles and implementation

This crate is where P2, P3, P5, P6 and P7 are realised:

- **P2** — the `fmt` layer's formatter is chosen when the layer is built, so the
  console-versus-JSON decision is one `match` on the resolved format.
- **P3** — the `FormatFields` and `FormatEvent` seams, asymmetric between the human and
  the JSON formatter, established above on executed evidence.
- **P5** — `EnvFilter` turns a level or a directive string into per-target interest, and
  `reload::Layer<EnvFilter, Registry>` makes it swappable after the configuration file is
  read (probe S5).
- **P6** — `SubscriberInitExt::try_init` (`src/util.rs:61`) and `set_default`
  (`src/util.rs:41`) are the two installation paths, one global and one scoped.
- **P7** — one builder, two `Profile` branches.

Feature selection, read from `tracing-subscriber-0.3.23/Cargo.toml`:
`default = ["smallvec", "fmt", "ansi", "tracing-log", "std"]`. Adding `env-filter` pulls
`matchers`, `regex-automata` and `regex-syntax` — measured, 3 crates. **`json` is
deliberately not enabled**: it pulls `tracing-serde` and `serde` (measured, exactly 2
crates) for a formatter the template replaces. **`local-time` is deliberately never
enabled**: the crate's own documentation says of the local-offset lookup that it happens
"every time it formats a message, which may be unsound or fail"
(`src/fmt/time/time_crate.rs:53`). The template stamps UTC, which is also what py does.

##### Dominant choice

`tracing-subscriber` 0.3.23, published 2026-03-13 (`GET https://crates.io/api/v1/crates/tracing-subscriber/versions`,
newest entry with `yanked: false`). **0.3.21 is yanked**, asserted in
`review/evidence/r58-figures.sh`.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence (observed) | 90-day downloads | All-time | Reverse deps |
|---|---|---|---|---|---|---|
| `tracing-subscriber` 0.3.23 | 2026-03-13 | 1.65.0 | MIT | 146,641,301 | 627,181,762 | 19,039 |
| `env_logger` 0.11.11 | 2026-06-25 | 1.71 | MIT OR Apache-2.0 | 79,902,863 | 569,103,899 | 11,986 |
| `fern` 0.7.1 | 2024-12-15 | 1.60 | MIT | 8,203,320 | 48,696,181 | 470 |
| `log4rs` 1.4.0 | 2025-09-05 | 1.75 | MIT OR Apache-2.0 | 1,924,992 | 23,310,983 | 401 |

All from `GET https://crates.io/api/v1/crates/<name>` and `/versions`, snapshot retrieved
2026-09-27T05:48:12Z.

##### Excluded by gate

**None of the four is excluded by a fitness gate**, and saying so plainly matters more
than dressing the real reason as one.

Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool`; observed licence strings are in the table.
Gate 2: all four declared MSRVs (1.65.0, 1.71, 1.60, 1.75) are within the 1.96 floor.
Gate 3: `https://rustsec.org/packages/tracing-subscriber.html` returns HTTP 200 for
**RUSTSEC-2025-0055**, whose own page states aliases `CVE-2025-58160`, category
`format-injection`, and `Patched >=0.3.20`; 0.3.23 is above that floor, so there is **no
open advisory**, and the escaping behaviour was verified executed (probe S8). The other
three packages' RustSec pages return **HTTP 404**, which is the site's "no advisories
filed" response and is reported as such rather than as a positive clean bill. `unsafe`
posture: `tracing-subscriber` does not carry `forbid(unsafe_code)`.
Gate 4: the same `tokio-rs/tracing` CI covers `ubuntu-latest`, `macos-latest` and
`windows-latest`.
Gate 5: default features are `smallvec, fmt, ansi, tracing-log, std`; **no async-runtime
coupling** — nothing in the selected feature set pulls `tokio`.
Gate 6: **executed** — +17 crates over the facade-only tree for the recommended feature
set, of which `env-filter` accounts for 3.

The three `log`-architecture renderers are excluded on **architecture and fit**: they are
`log::Log` implementations, they cannot receive a `tracing::Event`, they cannot see a
field key, and they cannot see a span, so under any of them P3 becomes call-site
discipline and P4 becomes impossible. `fern` additionally last published 2024-12-15:
**stable-quiet**, not at-risk — no advisory, no broken build, no maintainer notice — but
21 months without a release is a signal worth recording rather than passing over.

##### Up-and-comers

`tracing-bunyan-formatter` 0.3.10 (published 2024-11-26, no declared `rust_version`,
957,838 90-day downloads — **stable-quiet**) and `tracing-tree` 0.4.1 (published
2025-09-23, `rust_version` 1.70 — **active**) are the maintained third-party formatter
layers. Both are *alternatives to writing a formatter* and both were considered for the
structured profile and rejected: **neither redacts by key**, so adopting either would
leave P3 unsolved and still require the owned `FormatEvent`. `tracing-tree` is adopted by
`rust-analyzer` and `uv` for developer-facing hierarchical output and is worth
re-checking if a `--log-format tree` is ever asked for.

##### Fit for this template

Exact, with the single qualification this whole decision turns on: the **stock JSON
formatter does not fit**, and the crate's `FormatEvent` and `FormatFields` traits are the
sanctioned way to replace it. That is not a workaround — it is the extension point the
maintainers document, and `rust-lang/rustup` uses it in production for the same kind of
reason.

##### Recommendation

`tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }` on the root
package **only**, keeping default features. `ansi` is kept because R65's published
`anstream::ColorChoice` resolution is passed into `.with_ansi(bool)` rather than left to
the formatter's own guess. `json` off; `local-time` off. Floor the version at **0.3.20**
in prose, that being RUSTSEC-2025-0055's patched floor, and pin at 0.3.23.

##### Ranked runner-up

`tracing-bunyan-formatter` 0.3.10 as the structured formatter, with `tracing-subscriber`
still supplying `Registry`, `EnvFilter` and the human layer. Ranked second because it
removes roughly 95 lines of template-owned formatter code and gives a documented JSON
schema. Rejected because it still cannot redact by key, so the owned `FormatEvent` would
have to exist anyway, and because at 957,838 90-day downloads with no release since
2024-11-26 it is a thinner dependency than the code it would replace.

##### Tradeoffs

Gained: `Registry` span storage, `EnvFilter`'s directive language, hot-swappable
filtering, the `log` bridge, and a formatter seam. Paid: **17 crates** at the composition
root, measured; the template now owns roughly 120 lines of formatter code with its own
test burden, which is the honest cost of P3; and a maintenance coupling to two
`tracing-subscriber` traits, named in the re-verify trigger. One further cost is recorded
because it is easy to miss: the crate's own `Cargo.toml` declares
`[badges.maintenance] status = "experimental"`, which is the maintainers' own label on a
crate at 19,039 reverse dependencies.

##### Parameters

Contributes the subscriber clause of `logging-pipeline-contract`. It consumes
`msrv-policy` (declared 1.65.0; the probe tree resolved and built under a declared
`rust-version = "1.96"` on rustc 1.98.0), `rust-edition = 2024`, `target-os-matrix`,
`license` (`inapplicable` per Q7.B), and **`web-extra-surface`** — the service profile is
reachable only through R69's `web` feature and the serve binary that feature gates.

##### Migration implications

py's `structlog.configure(...)` plus a `StreamHandler(sys.stderr)` plus
`ProcessorFormatter` collapse into one `Registry::default().with(filter).with(fmt_layer)`
expression in `src/telemetry.rs`. py's `foreign_pre_chain` — which exists so records from
*other* libraries get the shared processors — has a direct analogue in `tracing-log`,
described in the next member. ts has nothing to migrate.

##### Validation strategy

Proposed for P03: `cargo tree -e normal -p rs-launch-blueprint` asserted against a pinned
crate count, and `cargo deny --all-features check bans` with a `[bans] deny[].wrappers`
rule proving no member but the root package names `tracing-subscriber`. **Executed here**:
the stock `.json()` formatter under-redacts (S1); a template-owned `FormatEvent` plus
`FormatFields` redacts both (S2); `reload` swaps the filter after installation (S5); a
second `try_init` is `Err` (S4); control bytes are escaped (S8); and the crate counts
above (S11c, S11d).

##### Confidence & re-verify trigger

**High** on the crate; **high and executed** on the formatter asymmetry, which is the
part of this decision most likely to be disbelieved. Re-verify when `tracing-subscriber`
publishes 0.4, or any 0.3.x that changes `Format<Json>`'s treatment of `N: FormatFields`,
the `RecordFields` seal, the `tracing-log` default feature, or the `try_init` sequence in
`src/util.rs` — each is load-bearing above; when a new RustSec advisory is filed against
it; when `rust-lang/rustup` moves off the custom `FormatEvent` pattern; at the next
`msrv-policy` floor advance past 1.96; or by 2027-03-18.

##### Sources

`GET https://crates.io/api/v1/crates/tracing-subscriber` and `/versions` and
`/reverse_dependencies?per_page=1`; `GET https://api.github.com/repos/tokio-rs/tracing`;
`https://rustsec.org/packages/tracing-subscriber.html` and
`https://rustsec.org/advisories/RUSTSEC-2025-0055.html` — snapshot-retrieved
2026-09-27T05:48:12Z, asserted by `review/evidence/r58-figures.sh`.
`tracing-subscriber-0.3.23/src/fmt/format/json.rs:175,200,253,266,272`, `/src/util.rs:43,62,69,94`,
`/src/field/mod.rs:88`, `/src/fmt/format/mod.rs:1228`, `/src/fmt/time/time_crate.rs:53`
and `/Cargo.toml`, read 2026-09-18 in the local Cargo registry and asserted by
`review/evidence/r58-standards.sh`. Compiler diagnostics `E0277` (`JsonFields: MakeVisitor`
unsatisfied), `E0277` (`RecordFields` sealed) and `E0599` (`flatten_event` bound to
`JsonFields`), emitted by rustc 1.98.0 on 2026-09-18.

#### tracing-log

##### Landscape

The bridge bin — one crate, no competitor. It converts `log::Record`s emitted by
*dependencies* into `tracing` events, so a pipeline built on `tracing` does not go blind
to the large part of the ecosystem that still emits through `log` (30,894 reverse
dependencies). Its own reverse-dependency count is 453, which understates its reach
because `tracing-subscriber` reaches it through a **default feature** rather than through
a declared dependency in each consumer. The alternative to using it is not another crate;
it is accepting that dependency diagnostics are invisible.

##### Principles and implementation

This is the Rust analogue of py's `foreign_pre_chain` — the mechanism by which records
that did not originate in the template's own call sites still get the shared pipeline's
level, format and redaction treatment.

The load-bearing and easily-missed fact is that **it is installed for you**, and
installing it yourself breaks the process at start. `SubscriberInitExt::try_init` calls
`dispatcher::set_global_default(...)` (`src/util.rs:62`) and then, under the default
`tracing-log` feature, `tracing_log::LogTracer::builder()` with the subscriber's
max-level hint (`src/util.rs:69`). **Executed (probe S6)**, with no explicit bridge call
anywhere in the probe, a `log::info!` rendered through the `fmt` layer:

```
  INFO r58probe: S6:LOG-CRATE-RECORD
  INFO r58probe: S6:TRACING-RECORD
```

The converse is the hazard: calling `tracing_log::LogTracer::init()` first and then
`.init()` fails, because the second installation of a `log` logger returns
`SetLoggerError` and `init()` is `try_init().expect(..)` (`src/util.rs:94`). Template
code must therefore not call `LogTracer::init()`, and must use `try_init()`.

##### Dominant choice

`tracing-log` 0.2.0, published 2023-10-25 (`GET https://crates.io/api/v1/crates/tracing-log/versions`,
newest entry with `yanked: false`), reached as `tracing-subscriber`'s default
`tracing-log` feature and **not** declared in any template manifest.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence (observed) | 90-day downloads | All-time | Reverse deps |
|---|---|---|---|---|---|---|
| `tracing-log` 0.2.0 | 2023-10-25 | 1.56.0 | MIT | 127,130,173 | 565,906,807 | 453 |

There is no second candidate: the shortlist is one crate because the job — adapt
`log::Log` to `tracing::Dispatch` — is done by exactly one maintained crate, in the same
repository as the subscriber that depends on it. The *alternative* is architectural, "do
not bridge", and it is rejected because it would make the HTTP client's and every other
dependency's diagnostics unreachable.

##### Excluded by gate

None.

Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not
evaluated for any dependency or tool`; the observed licence string is MIT.
Gate 2: declared `rust_version` 1.56.0, within the 1.96 floor.
Gate 3: `https://rustsec.org/packages/tracing-log.html` returns **HTTP 404**, the site's
"no advisories filed" response, reported as such. `unsafe` posture: no
`forbid(unsafe_code)`; the crate is a thin adapter and is in the executed 26-crate tree.
Gate 4: the same `tokio-rs/tracing` CI as the subscriber — `ubuntu-latest`,
`macos-latest`, `windows-latest`.
Gate 5: default features `log-tracer` and `std`; no async-runtime coupling; the
`interest-cache` feature is **off**.
Gate 6: it and `log` are 2 of the root tree's 26 crates.

The one thing that looks like a gate failure and is not: **no release since 2023-10-25**,
which the prompt's rubric calls "a trigger to investigate, never the verdict".
Investigated: the crate lives in `tokio-rs/tracing`, whose repository was pushed
2026-05-30; it has no advisory; it builds on current stable — executed, it is in the
probe tree; and its API surface is a finished adapter with nothing to change. Verdict
**stable-quiet**, not dormant: the rubric's `dormant` requires an unpatched advisory, a
broken build on current stable, or a maintainer's own notice, and none of the three is
present.

##### Up-and-comers

None. No newer crate competes for this job. `logforth` and `fastrace` solve adjacent
problems in the other direction — they consume `log`, they do not bridge it into
`tracing`.

##### Fit for this template

Exact, and its fit is *conditional on R05 revision 3's accepted execution model*: because
the default tree is synchronous and reaches the network through a client that reports
through the `log` facade, that facade is the only channel the transport has. If the
template were async on `tokio`, the same argument would hold through the async HTTP and
TLS stacks instead.

##### Recommendation

Do **not** add `tracing-log` to any `Cargo.toml`. Keep `tracing-subscriber`'s default
`tracing-log` feature on, call `SubscriberInitExt::try_init()`, and never call
`LogTracer::init()` from template code. Document the reason beside the call, because the
failure mode is a panic at process start and the cause is invisible at the call site.

##### Ranked runner-up

Declaring `tracing-log = "0.2.0"` directly and calling
`LogTracer::builder().with_max_level(..).init()` explicitly before building the
subscriber, as `rust-lang/rustup` does. Ranked second because it makes the bridge visible
in the manifest — a real readability gain — at the cost of a second place where the
double-initialisation failure can be reintroduced. If P03 finds it needs the max-level
hint set differently, this is the shape to move to.

##### Tradeoffs

Gained: dependency diagnostics, with the shared pipeline's level, format and redaction
applied to them. Paid: 2 crates already in the default tree; a per-record conversion cost
on `log` records only, mitigated because the max-level hint `try_init` sets means
disabled records are rejected by `log`'s own static check before conversion; and the
double-initialisation hazard above. One consequence belongs with `OVERRIDE (OV-09)` and
is stated here rather than left implicit: bridged `log` records carry **no field keys**
(probe S9), so key-based masking cannot reach a secret a dependency formats into its
message. The bridge widens what the pipeline can see; it does not widen what the
pipeline can mask.

##### Parameters

Contributes the foreign-record clause of `logging-pipeline-contract`. It consumes
`msrv-policy` (declared 1.56.0), `rust-edition = 2024`, `target-os-matrix` and `license`
(`inapplicable` per Q7.B).

##### Migration implications

Direct analogue of py's `foreign_pre_chain` and of py's folding of the ASGI server's own
loggers into the shared pipeline. In Rust the web-side analogue is different in kind:
axum emits `tracing` spans natively through its default `tracing` feature — already in
R69's accepted value — so there is nothing to re-parent. F327 is R75's row and covers the
access-log side.

##### Validation strategy

Proposed for P03: an integration test that sets `RSLBP_LOG_LEVEL=debug`, runs a command
performing an HTTP call against a local fixture, and asserts that at least one stderr
line carries the transport crate's target. **Executed here** (S6): a `log::info!`
rendered through the `fmt` layer with no explicit bridge call, alongside a
`tracing::info!` on the same layer.

##### Confidence & re-verify trigger

**High.** Re-verify when `tracing-subscriber` changes its `tracing-log` default feature
or the `try_init` sequence in `src/util.rs`; when `tracing-log` publishes 0.3; when R05
republishes with a different HTTP client or an async execution model; or by 2027-03-18.

##### Sources

`GET https://crates.io/api/v1/crates/tracing-log` and `/versions` and
`/reverse_dependencies?per_page=1`; `https://rustsec.org/packages/tracing-log.html`
(HTTP 404) — snapshot-retrieved 2026-09-27T05:48:12Z, asserted by
`review/evidence/r58-figures.sh`. `tracing-subscriber-0.3.23/src/util.rs:43,62,69,94` and
`/Cargo.toml`, read 2026-09-18 and asserted by `review/evidence/r58-standards.sh`.
`https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml`, read 2026-09-18.
Probe scenarios S6 and S9, `review/evidence/r58-probe.log`.

#### template-owned telemetry module

##### Landscape

This member is a **pattern, not a crate**, so the prompt's crate figure table is
`inapplicable` for it: there is no crates.io entry, no repository, no download count and
no advisory page for code that lives in this template's own `src/`. The pattern fields
are answered instead, and the reason the crate figures do not apply is stated at each
gate below.

The landscape it sits in is the set of ways a `tracing` pipeline can apply a field-level
policy: (a) a custom `FormatFields`; (b) a custom `FormatEvent`; (c) a third-party
formatter crate — `tracing-bunyan-formatter`, `tracing-tree`, `tracing-stackdriver`;
(d) redaction at the value's *type*, `secrecy::SecretString`; (e) a `Layer` that rewrites
the event; (f) a dedicated redaction crate, of which `redactable` 0.14.0 is the only
current candidate; (g) post-hoc filtering of the serialized bytes in the writer.
Option (e) **does not exist in Rust**: `Event` is immutable and `RecordFields` is sealed,
both established by compiler errors quoted above. That is the finding that forces this
member to exist.

##### Principles and implementation

The module realises P3 in full for keyed fields, records its own limit as
`OVERRIDE (OV-09)`, and supplies the seam for P4. Its shape:

- `src/telemetry.rs` in the root package: `pub enum Profile { Cli { format, level, ansi }, Service { level, format } }`,
  where the service `format` is `ServiceFormat::Json` (the default) or `ServiceFormat::Console`;
  `pub enum Init { Installed(Handles), HostOwned }`;
  `pub struct Handles { pub level: reload::Handle<EnvFilter, Registry>, pub log_bridge_refused: bool }`;
  `pub fn init(profile: Profile) -> Init`, which returns `HostOwned` only when
  `tracing::dispatcher::has_been_set()` is already true, and otherwise returns
  `Installed` with `log_bridge_refused` recording whether `try_init()` came back `Err`.
- a `redact` submodule: F252's vocabulary verbatim as a `const` array — `token`,
  `password`, `secret`, `authorization`, `api_key`, `apikey`, `credential`, `cookie`;
  `const REDACTED: &str = "[REDACTED]"`; `fn is_sensitive(name: &str) -> bool` doing an
  ASCII-lowercased substring match; `struct HumanFields(DefaultFields)` implementing
  `FormatFields` for the human profile; and `struct JsonFields` plus `struct JsonEvent`
  for the structured one.

`HumanFields` wraps `DefaultFields`'s visitor, which is possible because `DefaultFields`
implements `MakeVisitor` (`src/fmt/format/mod.rs:1228`), so it is roughly 25 lines.
`JsonFields` and `JsonEvent` are template-owned end to end — roughly 95 lines together —
because `JsonFields` cannot be wrapped and the stock `Format<Json>` bypasses
`N: FormatFields` for event fields in both of its branches.

The structured line's key order is fixed here so that R78 and R75 have a stable place to
add to: `level`, `target`, **the R78 trace-correlation slot**, the event's own fields,
then `span`. The correlation field for HTTP requests is named **`request_id`**, matching
CLI R7.8's spelling of the same concept in machine output while REST R11.7 and §1.10 keep
the wire header at `request-id`.

##### Dominant choice

`inapplicable — this member is a template-owned pattern, not a crate`, so there is no
crates.io "dominant" entry to name. The dominant *pattern* in the surveyed field is
(b) + (a): a custom `FormatEvent` delegating field formatting to `N: FormatFields`, which
is what `rust-lang/rustup` ships in production and what `tracing-subscriber`'s own
`FormatEvent` documentation gives as its worked example.

##### Qualified shortlist

| Option | What it costs | What it leaves unsolved |
|---|---|---|
| **(a)+(b) owned `FormatFields` (human) + owned `FormatEvent`/`FormatFields` (JSON)** — recommended | roughly 120 lines and their tests | only the value-embedded residue recorded as `OVERRIDE (OV-09)` |
| (a) alone, on both profiles | roughly 25 lines | **event fields leak on the JSON profile** — executed, S1 — and a non-JSON field format makes the stock formatter panic at `json.rs:200` |
| (c) a third-party formatter crate | 1 dependency | no redaction at all; the owned `FormatEvent` would still be required |
| (d) `secrecy` alone | 0 extra lines, since R56 revision 2 already selected it | protects only values a call site *typed* as secrets; R5.6 reaches a header map logged by `Debug` |
| (f) `redactable` 0.14.0 | 1 dependency plus per-type annotations | **fails fitness gate 2** — see below — and still leaves ad-hoc keyed fields to a custom formatter |
| (g) filter the serialized bytes in the `MakeWriter` | roughly 30 lines | a substring search over rendered output cannot distinguish a key from a value and would corrupt legitimate text |

##### Excluded by gate

**`redactable` 0.14.0 is excluded by fitness gate 2**, and it is the only candidate in
this entire item that fails a gate. Its newest non-yanked version as of the
2026-09-27T05:48:12Z snapshot, 0.14.0 (published 2026-09-23), declares
`rust_version` **1.97**, which is **above** the floor of **1.96** that `msrv-policy`
yields from stable 1.98 today. Revision 1 judged 0.13.0, the newest at its snapshot;
0.13.1 (2026-09-21) and 0.14.0 declare the same `rust_version` and licence string, so
the exclusion stands unchanged. The assertion is machine-checked in
`review/evidence/r58-figures.sh`, which fails if a later snapshot shows it within the
floor. Two further registry facts are recorded because a raw leg asserted the opposite:
its licence string is **`non-standard`**, not "likely MIT or Apache", and its
reverse-dependency total is **1**, against `tracing-subscriber`'s 19,039. Gate 1 would
have been `inapplicable` in any case under the owner ruling, so the licence string is
recorded as fact and is not the ground of exclusion; the MSRV is.

For the recommended template-owned module itself:

Gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B): licence
compatibility is not evaluated for any dependency or tool`, and doubly so because the
code is the template's own source under the repository's own declared expression, which
the ruling explicitly leaves standing.
Gate 2 is `inapplicable` as a *declared* figure — the module has no `rust-version` of its
own and compiles on whatever the workspace declares; **executed**, it compiled under a
declared `rust-version = "1.96"` on rustc 1.98.0.
Gate 3's advisory half is `inapplicable` — there is no published package to file an
advisory against — but its **`unsafe` posture half applies and is answered**: the module
contains no `unsafe`, and R06's published `unsafe-code-policy` is the authority on where
the `forbid(unsafe_code)` attribute is placed.
Gate 4 **applies and is answered**: the module uses only `std`, `serde_json` and
`tracing-subscriber` APIs that are identical on `ubuntu-latest` and `macos-latest`, with
no OS-conditional code path; **executed** on `aarch64-apple-darwin`.
Gate 5: no async-runtime coupling.
Gate 6: no dependency added beyond `serde_json`, which R66's published decision already
places in the tree.

Option (g) is the one design genuinely excluded on **correctness** rather than on a gate.

##### Up-and-comers

`tracing-stackdriver` 0.10.0 is the closest emerging alternative that would replace part
of this module — it performs GCP severity mapping and trace injection in a `FormatEvent`
of its own, which is precisely the owner reference's C10 suggestion. Not adopted: last
published **2024-03-11**, 293,363 90-day downloads, **no declared `rust_version`**, and it
binds the template to one cloud. It is recorded as the deployment-specific layer a
consumer could substitute at the same seam. `redactable` 0.14.0 is the other, and it is
excluded by gate 2 above; it is worth re-checking when the MSRV floor advances past 1.97,
at which point it becomes admissible on that gate and falls to be judged on adoption.

##### Fit for this template

This is the only member whose existence is *caused* by this template's requirements
rather than by the ecosystem. It exists because R5.6 **(MUST)** and F252 demand key-based
masking, and because the ecosystem's JSON formatter has no seam for it. Both source
repositories argue for it from opposite directions: py puts redaction in the shared
processor chain precisely so that call sites never have to remember, and ts's complete
**absence** of any redaction step is exactly the defect the template must not inherit.

##### Recommendation

Ship `src/telemetry.rs` in the root package with the shape above: `HumanFields` wrapping
`DefaultFields`, template-owned `JsonFields` and `JsonEvent`, one `is_sensitive` shared by
all three, F252's key vocabulary as a `const` array, the fixed structured key order with
an explicit R78 slot, an explicit R59 sink slot in `init`, and `secrecy::SecretString`
(R56 revision 2's, already in the tree) as the type-level first line of defence. Record
`OVERRIDE (OV-09)` in the template's own conformance note when P03 writes one.

##### Ranked runner-up

`tracing-bunyan-formatter` 0.3.10 for the structured profile plus a `secrecy`-only
redaction policy. Ranked second because it is the smallest thing that produces schema'd
JSON. Rejected because it discharges R5.6 only for values a call site remembered to type
as secrets — the exact discipline F252 exists to remove.

##### Tradeoffs

Gained: P3 satisfied for keyed fields on both profiles with executed proof; a single
place where R78 injects trace identifiers; no third-party formatter dependency; and
control over the JSON key set, which R7.8's envelope consumers benefit from. Paid:
roughly 120 lines of template code with its own test burden; a maintenance coupling to
`tracing-subscriber`'s `FormatEvent` and `FormatFields` traits, named in the re-verify
trigger; the risk that a future `Visit` method the module does not override lets a typed
value through un-redacted, which is why the acceptance test asserts on a value recorded
through `Debug`, the widest path; and the residue recorded as `OVERRIDE (OV-09)`.

##### Parameters

Contributes the redaction and profile clauses of `logging-pipeline-contract`. It consumes
`license` (the module is the repository's own source under its own declared expression),
`rust-edition = 2024`, `msrv-policy`, `target-os-matrix`, and **`web-extra-surface`** —
the `Profile::Service` branch is constructed only by the serve binary that R69's `web`
feature gates.

##### Migration implications

Replaces py's `_redact_sensitive` and `SENSITIVE_KEY_PARTS`: same vocabulary, different
insertion point — **format time, not event time**. Two observable consequences follow,
and both are consequences a later item needs to know rather than incidental detail.
First, a redacted field cannot be un-redacted by a later processor, because there is no
later processor. Second, and more important, **a `Layer` other than `fmt` sees the
unredacted field**, since it reads the `Event` directly: redaction is a property of the
rendered output, not of the event. Any exporter added later — R78's OTel layer above all
— must therefore apply the same policy itself, and R78 inherits that as a stated
obligation. ts has nothing to migrate; it has no redaction.

##### Validation strategy

Proposed for P03, as a `#[test]` per assertion in `tests/telemetry_redaction.rs`, using
`tracing::subscriber::set_default` — the scoped guard, so tests do not contend for the
global — and a shared in-memory writer:

1. human profile, event field `token` → the line contains `[REDACTED]` and contains
   neither the token prefix nor the password;
2. human profile, **span** field `api_key` → the same;
3. structured profile, event field `token` → the line parses as JSON and
   `["token"] == "[REDACTED]"`;
4. structured profile, span field `api_key` → `["span"]["api_key"] == "[REDACTED]"`;
5. a `secrecy::SecretString` recorded through `Debug` → renders `SecretBox<str>([REDACTED])`;
6. a control byte in an untrusted field value → no raw `0x1b` or `0x07` reaches the sink;
7. **the OV-09 boundary**, asserted as a boundary rather than as a fix: a secret inside a
   non-sensitive field's value is **expected** to appear, so that the day a value-shaped
   defence is added this test fails and forces the override to be revisited.

Seven of those seven behaviours were executed against real `tracing-subscriber` 0.3.23 in
`review/evidence/r58-probe.sh` as S2, S3, S7, S8 and S10; what is *proposed* is their form
as template tests, not the behaviours themselves.

##### Confidence & re-verify trigger

**High**, and unusually well evidenced for a pattern member, because every behaviour it
claims was executed rather than argued. Re-verify when `tracing-subscriber` changes
`FormatEvent`, `FormatFields`, or `Format<Json>`'s treatment of `N`; when R56 republishes
with a different secret type; when R78 publishes and fills the trace-identifier slot; when
R59 publishes and fills the sink slot; when F252's key vocabulary is extended; when the
`msrv-policy` floor advances past 1.97 and `redactable` becomes admissible on gate 2; or
by 2027-03-18.

##### Sources

`tracing-subscriber-0.3.23/src/fmt/format/json.rs:175,200,253,266,272,422`,
`/src/field/mod.rs:88`, `/src/fmt/format/mod.rs:1228`, `/src/util.rs:43,62,69,94`, read
2026-09-18 in the local Cargo registry and asserted by `review/evidence/r58-standards.sh`.
Compiler diagnostics `E0277` and `E0599` from rustc 1.98.0, 2026-09-18.
`GET https://crates.io/api/v1/crates/redactable` and `/versions` and
`/reverse_dependencies?per_page=1`, and the same endpoints for `tracing-stackdriver` and
`tracing-bunyan-formatter` — snapshot-retrieved 2026-09-27T05:48:12Z and asserted by
`review/evidence/r58-figures.sh`. The org CLI Design Standard v1.4.14 `:332` (R5.6) and
`:381` (R7.1), blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`; the org REST API Design
Standard v2.0.0 `:271`, `:348`, `:533`, `:1323`, `:1422`, `:1427`, `:1752`, `:1759`, blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9`. Probe scenarios S1, S2, S3, S7, S8, S9, S10,
`review/evidence/r58-probe.log`.

### Compatibility

Three independent proofs that the exact combination works together.

1. **Executed resolution and build.** A probe manifest declaring `edition = "2024"`,
   `rust-version = "1.96"`, `tracing = "=0.1.44"`,
   `tracing-subscriber = { version = "=0.3.23", features = ["env-filter", "json"] }`,
   `tracing-log = "0.2"`, `log = "0.4"`, `secrecy = "0.10.3"` and `serde_json = "1"`,
   built `--locked` against the committed `probe/Cargo.lock`, resolved and built clean on
   rustc 1.98.0 at revision 1 and on rustc 1.98.1 at the revision-2 re-record, then ran
   eleven behavioural scenarios, all asserted in `review/evidence/r58-probe.sh` (33
   checks, 0 failures). The probe's
   `secrecy` 0.10.3 is **R56 revision 2's accepted crate**, so the two items' stacks were
   resolved together rather than separately. The probe enabled `json` in order to *test*
   the stock JSON formatter; the recommendation leaves it off.
2. **Version matrix, resolved rather than asserted.** The three crate members are
   published from one repository, `tokio-rs/tracing`, and released together: `tracing`
   0.1.44 and `tracing-core` 0.1.36 were both published 2025-12-18.
   `tracing-subscriber` names `tracing-log` in its own default feature set, so their
   compatibility is not a matter of independent version selection at all — Cargo resolves
   it, and the executed 26-crate tree is the resolution.
3. **Shared adopters at these exact versions.** `rust-lang/cargo` declares
   `tracing = "0.1.44"` and `tracing-subscriber = "0.3.23"` — **the same two patch
   versions recommended here**, in the ecosystem's most-run binary. `rust-lang/rustup`
   declares `tracing`, `tracing-log`, `tracing-subscriber` with `env-filter`, and
   `tracing-opentelemetry` optional behind an `otel` feature — the same three crate
   members plus the R78 hook, in one shipped CLI manifest. On the axum side, R69's
   accepted value turns on axum 0.8.9 with its default `tracing` feature, which emits
   into whatever subscriber is installed, and `tower-log`, which routes tower's `log`
   records into the same place through `tracing-log`; axum depends on the `tracing` 0.1
   line, so no version conflict is possible.

The one combination that is **not** compatible is recorded rather than hidden: the stock
`.json()` event formatter and a non-`JsonFields` field formatter cannot be composed — it
fails to compile if the builder order is one way (`E0599`, `flatten_event` bound to
`JsonFields`) and panics at runtime if it is the other (`json.rs:200`). That combination
is not in the recommended stack, and probe S1 is the executed demonstration of why.

re-verify: when tracing-subscriber publishes 0.4 or changes Format<Json>'s handling of N, the RecordFields seal, the tracing-log default feature or the try_init sequence; when tracing publishes 0.2; on any new RustSec advisory against tracing, tracing-core, tracing-subscriber or tracing-log; when tracing-opentelemetry publishes a new minor after 0.34.0 or redactable publishes a version after 0.14.0 (both newest as of the 2026-09-27T05:48:12Z snapshot); when tracing-core changes or removes the doc-hidden dispatcher::has_been_set; when R69 republishes web-extra-surface with revision 10's crates/web paths; when R02, R05, R56 or R77 publishes; when R59 or R78 publishes and fills a declared slot; when either org standard moves off blob f9de0437baece3383e73ca2c5f48b7ab399b51c7 or blob 71bd813c1cf61286586b4ee41ed83ff065e5c8d9; when the msrv-policy floor advances past 1.96; at the 2026-12-18 maintenance re-check of tokio-rs/tracing; or 2027-03-18

## Parameters

This item owns one registry parameter, `logging-pipeline-contract`, which
`research/CLAUDE.md`'s R58 row and `docs/port/PARAMETERS.md:18` both name and which the
registry currently carries as the placeholder value. The owned value below is what
publication writes into that row.

### Parameters

The owned value is written bare below, with no backtick and no pipe character anywhere in
it, because the packaging validator reads everything after `= ` as the value. The five
`- assumes` lines are the four fixed parameters plus the one parameter this item's binding
prompt declares on its `- consumes:` line, `R69: web-extra-surface`; each was extracted
programmatically from the live `docs/port/PARAMETERS.md` row by
`review/evidence/r58-param-lines.py` and is re-compared byte-for-byte by
`review/evidence/r58-standards.sh`. No sixth `assumes` line is declared, because a
parameter the prompt does not consume is rejected by the validator.

Commentary on how these parameters bear on the decision is in prose after the list, never
on a parameter line.

- owns logging-pipeline-contract = logging-pipeline/v1: STACK - tracing 0.1.44 is the only diagnostic facade any package may name, taken default-features = false, features = ["std"] by rs-launch-blueprint-core and rs-launch-blueprint-web and with its defaults (std, attributes) by the root package rs-launch-blueprint and rs-launch-blueprint-cli; tracing-subscriber 0.3.23 with features = ["env-filter"] over its default set (smallvec, fmt, ansi, tracing-log, std) is declared on the root package only, with the json feature OFF because the template owns the structured formatter and the feature adds exactly two crates (serde, tracing-serde) for a formatter it replaces, and with local-time NEVER enabled because the crate's own documentation says the local-offset lookup may be unsound or fail; timestamps are UTC ISO-8601; tracing-log 0.2.0 enters through tracing-subscriber's default tracing-log feature and is never declared directly; no other logging crate is added; crates/core, crates/cli and crates/web must not name tracing-subscriber, enforced by R02's cargo deny --all-features check bans [bans] deny[].wrappers rule and its crates/core allow-list test; the version floor is 0.3.20, RUSTSEC-2025-0055's patched floor. INITIALISATION - exactly one telemetry::init(Profile) -> Init in the root package's src/telemetry.rs, called first in each binary's main before anything that can log; it builds Registry::default() with a reload::Layer<EnvFilter> and one fmt layer whose writer is stderr, and first checks tracing::dispatcher::has_been_set(): if a dispatcher is already set, a host owns diagnostics, nothing is installed and init returns Init::HostOwned; otherwise it installs with SubscriberInitExt::try_init() and NEVER init(), which is try_init().expect(..), returning Init::Installed(Handles { level: reload::Handle<EnvFilter, Registry>, log_bridge_refused: false }) on Ok and Init::Installed(Handles { level, log_bridge_refused: true }) on Err, because try_init sets the global dispatcher before it installs the log bridge, so an Err after a clear check means only that a host already owns the log logger while the template's dispatcher is live; init never panics, never replaces and never tears down anything; template code never calls tracing_log::LogTracer::init(), because try_init already installs the bridge with the subscriber's max-level hint and a second installation fails with SetLoggerError; tests and embedders use the scoped set_default guard instead of the global path. RECONFIGURATION - the level is swappable after the configuration file is read, through the returned reload::Handle, which is how F274's config tier is reached without logging being absent while the configuration file is parsed; the format and the writer are fixed at init and are not reloadable, a deliberate departure from py's handler-replacement model recorded as a migration risk. STRUCTURED-FIELD AND REDACTION CONTRACT - key-based masking is applied at format time, not event time, because a tracing::Event is immutable, RecordFields is a sealed trait and no Layer can rewrite an event; the key vocabulary is F252's verbatim (token, password, secret, authorization, api_key, apikey, credential, cookie, matched as an ASCII-lowercased substring) and the mask is [REDACTED]; the human profile uses a template-owned FormatFields wrapping DefaultFields, and the structured profile uses a template-owned FormatEvent plus a template-owned JSON FormatFields, because tracing-subscriber's stock Format<Json> serialises event fields itself through tracing_serde in both its flattened and non-flattened branches and uses its N: FormatFields parameter only for span fields, so a redacting field formatter under .json() leaks every event field and panics if its output is not valid JSON; secrecy::SecretString (R56 revision 2) is the type-level first line of defence and the key match is the second; the structured line's key order is level, target, the R78 trace-correlation slot, the event's own fields, then span; the HTTP correlation field is named request_id, matching CLI Design Standard R7.8's spelling, while the wire header stays request-id per REST API Design Standard R11.7 and section 1.10; redaction is a property of rendered output, so any later exporter layer must apply the policy itself; and the residual gap - a secret carried inside a non-sensitive field's value is not masked - is recorded as OVERRIDE (OV-09) against CLI Design Standard R5.6. PROFILES (one engine, two policies; one subscriber per process, since each front end is its own binary) - Profile::Cli for the CLI binary R49 names: format auto, console or json, where auto resolves to console when std::io::stderr().is_terminal() and to json otherwise, colour from R65's resolved anstream::ColorChoice passed to .with_ansi(bool), default level WARN; Profile::Service { level, format } for the serve binary R69 gates: format from RSLBP_WEB_LOG_FORMAT, whose value set is json (the default) or console with no auto and no TTY test, any other value rejected by the FromStr R77's WebSettings::from_env() calls as R67's RSLB203 before init runs; default level INFO; no file sink; level and format are the values R77's WebSettings::from_env() parsed from RSLBP_WEB_LOG_LEVEL and RSLBP_WEB_LOG_FORMAT and passes in, and telemetry reads no environment variable itself; plus R75's request-span layer. LEVEL LADDER (F274), one total order, highest first, with every command-line flag above the environment variable as CLI Design Standard R5.1 requires - --debug (TRACE plus internal detail: target, file, line, thread) > --log-level with the values off, error, warn, info, debug and trace > --quiet/-q (ERROR) > -v/-vv/-vvv (INFO/DEBUG/TRACE) > RSLBP_LOG_LEVEL > config-file [logging].level > default WARN; --log-format with the values auto, console and json, plus RSLBP_LOG_FORMAT, selects the render mode by the same deterministic flag-to-environment mapping. STREAMS - every diagnostic byte goes to stderr and stdout is never written by the pipeline, per CLI Design Standard R7.1 and R67's requirement that stdout stays byte-empty on the error path; the pipeline never emits R67's error envelope, which the error boundary owns. EXTENSION INTERFACE - two declared slots with nothing decided in them: a layer slot in telemetry::init where R78's tracing-opentelemetry layer attaches under an otel = ["web", ...] feature nesting on R69's web, with a matching trace_id/span_id serialisation point in the owned FormatEvent, and with W3C traceparent propagation deliberately NOT gated by that feature because REST API Design Standard R11.8 requires it unconditionally on the HTTP surface; and a sink slot where R59's file sink attaches as a second Layer with its own MakeWriter and its own per-layer Filter, which is how a sink gets a level independent of the console.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**No `CONFLICT:` line is raised.** Every consumed value is usable exactly as written.
R69's feature boundary is where the `otel` nesting belongs; R67's envelope is emitted by
the error boundary rather than by this pipeline, so the two never contend for stdout;
R49's binary name is what the CLI profile attaches to; R77 names the two service
environment variables and states that R58 values them, which this decision does; and the
four fixed parameters are satisfied by every recommended crate.

**On the `web-extra-surface` bytes above, and why they are revision 9's.** The
`- assumes web-extra-surface = ` line is byte-identical to the live
`docs/port/PARAMETERS.md` row, which is R69 **revision 9**'s text and still says
`src/web/` with `web = ["dep:axum", "dep:tokio"]`. R69 **revision 10** is owner-accepted
and unpublished (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`,
its `- owns` line at `:1791`): it declares the feature on the root package as
`web = ["dep:rs-launch-blueprint-web"]`, moves the module tree to `crates/web/src/`,
declares axum and tokio non-optionally inside `crates/web/Cargo.toml`, drops the
file-level feature gate because the whole member is optional, and keys path-based
skip-gating on `crates/web/**`. **This design is written against revision 10's shape** —
`crates/web` is the package that takes the `tracing` facade and never
`tracing-subscriber` — while the registry bytes above are carried unchanged, because the
registry is what publication compares against and revision 10 has not been published.
Nothing in this recommendation needs R69's value to be different, so **no `CONFLICT:` is
raised for it**; R69's republication of that row is named as a re-verify trigger instead.
Revision 10 also keeps the `otel = ["web", ...]` and `metrics = ["web", ...]` nesting
this decision relies on, so the two revisions agree on every point R58 actually consumes.

### Migration implications

File-level changes in the template, all **proposed** — P03 builds them, and nothing below
was built here:

| File | Change |
|---|---|
| `Cargo.toml` (root package) | add `tracing = "0.1.44"` and `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`; do **not** add `tracing-log`, `tracing-serde`, or the `json` feature |
| `crates/core/Cargo.toml` | add `tracing = { version = "0.1.44", default-features = false, features = ["std"] }` — 4 crates, no proc-macro, no subscriber |
| `crates/cli/Cargo.toml` | add `tracing = "0.1.44"` with default features |
| `crates/web/Cargo.toml` | add `tracing = { version = "0.1.44", default-features = false, features = ["std"] }`; axum's default `tracing` and `tower-log` features already emit into it |
| `src/telemetry.rs` (new, root package) | `Profile`, `Init`, `Handles`, `init()`, and the `redact` submodule with the F252 vocabulary, `REDACTED`, `is_sensitive`, `HumanFields`, `JsonFields`, `JsonEvent`, the fixed key order, the R78 slot and the R59 slot |
| `src/main.rs` (the CLI binary) | first statement of `main`: resolve the ladder from parsed flags and environment, call `telemetry::init(Profile::Cli { .. })`, keep the returned `Handles`, and pass the level handle to the configuration-loading step |
| the serve binary's source | start of `main`, in R77's order: `WebSettings::from_env()` first, which parses `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT` (`json` or `console`, default `json`; anything else fails as `RSLB203`), then `telemetry::init(Profile::Service { level, format })` with those two parsed values; telemetry reads no environment variable itself |
| `deny.toml` | a `[bans] deny[].wrappers` entry naming `tracing-subscriber` with the root package as its only permitted wrapper |
| `tests/workspace_edges.rs` (R02's) | add `tracing` to `crates/core`'s external-dependency allow-list; assert `tracing-subscriber` appears on no member but the root package |
| `tests/telemetry_redaction.rs` (new) | the seven assertions listed under the telemetry member's *Validation strategy*, including the OV-09 boundary assertion |
| the global-args module (R60's) | `--log-level` bound to `RSLBP_LOG_LEVEL` and `--log-format` bound to `RSLBP_LOG_FORMAT`; `-v`, `-q` and `--debug` already exist as R4.1's required global core |
| `README.md` / `docs/` | one table documenting the seven-rung ladder in its order `--debug` > `--log-level` > `-q` > `-v`×n > `RSLBP_LOG_LEVEL` > config > `WARN`, with every flag above the environment variable per R5.1, and the format values, because R5.4 and R7.12 make the flag and environment names part of the public interface |
| the template's conformance note, when P03 writes one | record `OVERRIDE (OV-09)` against CLI Design Standard R5.6, in the shape of the REST standard's §1.9 template |

What is **not** changed here and is left to its owner: `[logging]` configuration keys
beyond `level` (R54, R59); the file sink itself (R59); the state directory (R57); the
OpenTelemetry layer's contents (R78); the `/metrics` route (R79); the request-span layer
and access logging (R75); and the serve binary's full environment set (R77).

### Validation strategy

**Executed here.** Three scripts, rerun in place for revision 2 and, for the standards
script, also in a `/tmp` replica with no `.git` (see `## Empirical check`); their full
output is recorded beside them.

| Script | What it proves | Checks |
|---|---|---|
| `review/evidence/r58-probe.sh` → `r58-probe.log` | the build, the eleven behavioural scenarios S1–S10 plus S4b (the partial-host install), and the four dependency-graph counts S11a–S11d, against real `tracing` 0.1.44 and `tracing-subscriber` 0.3.23 | 33 PASS, 0 FAIL, 0 SKIP |
| `review/evidence/r58-standards.sh` → `r58-standards.log` | 14 CLI-standard checks (the blob resolves, plus thirteen rule quotations at their pinned lines, four of them R5.1's), 10 REST-standard checks (the blob resolves, plus nine quotations), 16 `tracing-subscriber` checks (the source is present, plus fifteen source assertions), four checks on this decision's own parameter lines, and four revision-rule checks: the H1 title, no `## Supersedes`, exactly one `re-verify:` line, and the gate-1 wording, counted by `review/evidence/r58-gate1-wording.py` | 48 PASS, 0 FAIL, 0 SKIP |
| `review/evidence/r58-figures.sh` → `r58-figures.log` | every registry, GitHub and RustSec figure this decision cites, asserted against the committed snapshots | 161 PASS, 0 FAIL, 0 SKIP |

`review/evidence/r58-fetch-snapshots.sh` is the provenance record for the snapshots
rather than a check: it hits crates.io, the GitHub API (paced at one call per 21 seconds)
and RustSec, and rewrites `review/evidence/snapshots/`. Because download counters and
star counts move hourly, asserting against the live endpoints would make the figure check
unreproducible by construction; the snapshots are committed and `r58-figures.sh` reads
only them, so it reproduces byte-for-byte on any machine, with or without a network.
`r58-probe.sh` and `r58-standards.sh` print the toolchain and the `grep` version they
ran with, and their logs were re-recorded for revision 2 by reruns performed after this
revision's text was written — the reproduction was performed, not asserted.

**Proposed for P03**, against the real template, none of it run here because the template
does not exist:

```
cargo test -p rs-launch-blueprint --test telemetry_redaction
cargo tree -e normal -p rs-launch-blueprint-core     # expect: no tracing-subscriber
cargo deny --all-features check bans                 # expect: the wrappers rule holds
cargo run --bin rslbp -- <a list command> --json 1>out 2>err
  # expect: out parses as JSON; err carries zero result bytes
RSLBP_LOG_LEVEL=debug cargo run --bin rslbp -- <a network command> 2>err >/dev/null
  # expect: DEBUG lines from the transport target, none containing a token value
RSLBP_LOG_FORMAT=json cargo run --bin rslbp -- <a list command> 2>err >/dev/null
  # expect: every line of err parses as a JSON object
RSLBP_WEB_LOG_FORMAT=json cargo run --features web --bin <app>-serve 2>err
  # expect: JSON lines on stderr from the first line, with no TTY-dependent variation
```

The expected behaviour is stated beside each command. None of the seven has been run; the
eleven executed probe scenarios stand in for them and exercise the same library behaviour
the commands would.

### Confidence & re-verify trigger

**Confidence: high on the architecture and on the crate stack; high and executed on the
redaction finding, which is the part most likely to be disbelieved; medium on the exact
rungs of the level ladder, which are a design choice this decision makes rather than a
fact it discovered, and which R60's and R54's published surfaces could refine.**

**The maintenance figure a reviewer should look at first, because it is the one that
argues against this recommendation.** Issue responsiveness was recomputed here from the
API rather than carried: the ten most recently opened issues of `tokio-rs/tracing` were
taken from
`GET https://api.github.com/repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60`
with pull requests filtered out, and each one's
`GET https://api.github.com/repos/tokio-rs/tracing/issues/<n>/comments?per_page=100` was
read for the first comment whose `author_association` is `OWNER`, `MEMBER` or
`COLLABORATOR` and whose author is not the issue's author. All of it is asserted in
`review/evidence/r58-figures.sh`.

| Figure | Value | Endpoint |
|---|---|---|
| Sample | issues #3613, #3612, #3611, #3607, #3601, #3599, #3597, #3595, #3593, #3587, opened 2026-07-31 to 2026-09-16 | `repos/tokio-rs/tracing/issues` |
| Median days to first maintainer response | **undefined — no issue in the sample has one** | `issues/<n>/comments` |
| Unanswered by a maintainer | **10 of 10** | same |
| Of those, with zero comments of any kind | **6 of 10** (the other four have one comment each, none from a maintainer) | same |
| Stars / archived / last push | 6,891 / `false` / `2026-05-30T06:42:00Z` | `repos/tokio-rs/tracing` |
| Open issues | **628** | `search/issues?q=repo:tokio-rs/tracing+is:issue+is:open`, field `total_count` |
| Open issues by the forbidden field | 894 | `repos/<o>/<r>`, `open_issues_count` — recorded only to show the two differ, because it counts pull requests |
| Last releases | `tracing-subscriber` 0.3.23 on 2026-03-13; `tracing` 0.1.44 on 2025-12-18 | `crates.io /versions` |
| Maintainers' own label | `[badges.maintenance] status = "experimental"` in `tracing-subscriber-0.3.23/Cargo.toml` | local registry source |

**Verdict: `at-risk`, not `stable-quiet`, and this decision says so rather than rounding
up.** The rubric requires `at-risk` to rest on a concrete signal; ten consecutive
unanswered issues over seven weeks, combined with almost four months without a push
(2026-05-30 to the 2026-09-27 snapshot) and the
maintainers' own `experimental` badge, is one. It is **not** `dormant`: there is no
unpatched advisory, no maintainer notice, and the crates build clean on current stable —
executed, the 26-crate tree built on rustc 1.98.0 and again on rustc 1.98.1 at the
revision-2 re-record. `tracing-log` is assessed separately as
**stable-quiet**, because it shares the repository signal but its own API is a finished
adapter with nothing left to change.

**Why the recommendation does not move, stated so a reader can disagree with the
reasoning rather than guess at it.** (1) No alternative in the landscape satisfies P3 and
P4 — the `log`-architecture renderers structurally cannot, demonstrated executed in S9,
and `slog` has no maintained OTel bridge — so "pick a livelier crate" names no crate.
(2) The APIs this design depends on — `Layer`, `FormatEvent`, `FormatFields`,
`EnvFilter`, `reload`, `try_init` — are mature and have been stable across the 0.3.x
line; a quiet repository is a smaller risk for a stable API than for a moving one.
(3) The Rust project's own `cargo` and `rustup` depend on these exact versions, so a
genuine break would be an ecosystem event with many hands on it. (4) The design's largest
bet, the redaction formatters, is **template-owned code**, which is precisely the part
upstream quiet cannot break. What the signal does change is cadence: **the maintenance
question is re-verified at 2026-12-18**, three months out, not at the 2027-03-18 date the
rest of this decision uses.

**This signal travels to one other item, and its limit is stated.**
`tracing-opentelemetry` 0.34.0 is published from `tokio-rs/tracing-opentelemetry`, a
sibling repository in the same organisation (409 stars, `pushed_at`
`2026-09-23T08:23:27Z`, the day 0.34.0 was published). **R78 should inherit this finding and re-measure responsiveness
for that repository rather than assuming the organisation is uniformly healthy.** Nothing
here measures `tracing-opentelemetry`'s issue responsiveness and this decision does not
claim to. The two `pushed_at` figures are internally consistent with the release dates:
`pushed_at` is the last push to *any* branch, so 2026-05-30 sitting after the 0.3.23
release of 2026-03-13 is what one expects, not a contradiction.

**What could not be verified, and is therefore claimed nowhere above.**

- **Any performance number.** No benchmark was run and none is cited. The
  performance-relevant statements made are structural and labelled as such: `reload`
  costs a lock acquisition per event on the layer it wraps, which is why only the filter
  sits behind one; `tracing`'s disabled-callsite path is a level comparison;
  `tracing-log`'s conversion cost applies only to `log` records, and the max-level hint
  `try_init` sets means disabled ones are rejected by `log`'s own static check first.
  Turning any of these into a figure would need a stated workload, and this item has
  none. **Evidence gap, declared.**
- **Clean-build wall-clock time.** Timings were taken (2.81 s for the 4-crate tree, and
  roughly 31–35 s for the 9-, 21-, 26- and 28-crate trees) but this machine was running
  ten concurrent agents, the figures did not separate the trees in a way that survives
  that load, and they did **not** reproduce the figures the Opus leg reported. They are
  therefore **not** carried into any gate-6 answer and are not asserted by any script.
  Gate 6 is answered with **crate counts**, which are deterministic and are asserted. In
  particular, this decision does **not** repeat the Opus leg's attribution of the
  compile-time cost to `env-filter`'s `regex-automata`: nothing executed here supports it.
- **That the recommended stack behaves as designed *in this template*,** since the
  template does not exist. The eleven executed probe scenarios stand in for that and are
  labelled probe results throughout, never as template results.

**Re-verify triggers**, whichever comes first: `tracing-subscriber` publishing 0.4, or any
0.3.x that changes `Format<Json>`'s treatment of `N: FormatFields`, the `RecordFields`
seal, the `tracing-log` default feature, or the `try_init` sequence in `src/util.rs`, each
of which is load-bearing above; `tracing` publishing 0.2; any new RustSec advisory against
`tracing`, `tracing-core`, `tracing-subscriber` or `tracing-log`; **R69 republishing
`web-extra-surface` with revision 10's `crates/web` paths**, which this design already
assumes and which would make the registry row and this decision agree; R02, R05 and R56
publishing, each being owner-accepted but unpublished and this design written against all
three; R77 publishing the serve binary's environment-variable names; R66 or R60
republishing in a way that moves `serde_json`'s home or the global-flag surface; R59 or
R78 publishing and filling the two declared slots; the org CLI Design Standard moving off
blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` or revising R4.1, R4.4, R5.1, R5.4, R5.6, R7.1,
R7.3 or R7.8; the org REST API Design Standard moving off blob
`71bd813c1cf61286586b4ee41ed83ff065e5c8d9` or revising R1.7, §1.10, R2.10, R3.3, R8.2,
R8.12, R11.7 or R11.8; the `msrv-policy` floor advancing past 1.96, or past 1.97 at which
point `redactable` becomes admissible on gate 2; `tracing-opentelemetry` publishing a new
minor after 0.34.0, or `redactable` publishing a version after 0.14.0, both being the
newest versions as of the 2026-09-27T05:48:12Z snapshot; `tracing-core` changing or
removing the `#[doc(hidden)]` `dispatcher::has_been_set` that `telemetry::init` checks;
the maintenance re-check at 2026-12-18; or 2027-03-18.

### Sources

**Registry and repository endpoints**, all snapshot-retrieved **2026-09-27T05:48:12Z**
into `review/evidence/snapshots/` and asserted by `review/evidence/r58-figures.sh`:
`GET https://crates.io/api/v1/crates/<name>` and `/versions?per_page=40` and
`/reverse_dependencies?per_page=1` for `tracing`, `tracing-core`, `tracing-subscriber`,
`tracing-log`, `tracing-serde`, `log`, `env_logger`, `fern`, `log4rs`, `slog`,
`tracing-opentelemetry`, `tracing-bunyan-formatter`, `tracing-tree`,
`tracing-stackdriver`, `fastrace`, `logforth`, `redactable`, `tracing-appender` and
`secrecy`; `GET https://api.github.com/repos/tokio-rs/tracing` and
`.../tracing-opentelemetry`;
`GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+is:open`;
`GET https://api.github.com/repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60`
and `GET https://api.github.com/repos/tokio-rs/tracing/issues/<n>/comments?per_page=100`
for the ten-issue responsiveness sample.

**Advisories**: `https://rustsec.org/packages/tracing.html` (HTTP 200),
`https://rustsec.org/packages/tracing-subscriber.html` (HTTP 200),
`https://rustsec.org/advisories/RUSTSEC-2023-0078.html`,
`https://rustsec.org/advisories/RUSTSEC-2025-0055.html`, and the HTTP 404 responses for
`tracing-core`, `tracing-log`, `log`, `env_logger`, `fern`, `log4rs`, `slog` and
`redactable`, reported as the site's "no advisories filed" response rather than as a
positive clean bill. Snapshot-retrieved 2026-09-27T05:48:12Z.

**Source read at the exact published version** in the local Cargo registry, 2026-09-18,
and asserted at its lines by `review/evidence/r58-standards.sh`:
`tracing-subscriber-0.3.23/src/fmt/format/json.rs:175,200,253,266,272,422`,
`/src/util.rs:43,62,69,94`, `/src/field/mod.rs:88`, `/src/fmt/format/mod.rs:1228`,
`/src/fmt/time/time_crate.rs:53`, `/Cargo.toml`.

**Upstream manifests and implementations**, read 2026-09-18:
`https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml`;
`https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml` and
`/src/cli/log.rs`; `https://raw.githubusercontent.com/rust-lang/rust-analyzer/master/Cargo.toml`;
`https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml`;
`https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml`;
`https://raw.githubusercontent.com/tokio-rs/tracing/master/.github/workflows/CI.yml`.

**Source repositories at their programme pins**, read 2026-09-18: py at `b08bccfb` —
`src/py_launch_blueprint/core/logging.py` (lines 85–240),
`src/py_launch_blueprint/web/logging.py`, `src/py_launch_blueprint/cli/options.py`,
`src/py_launch_blueprint/cli/context.py`; ts at `cb1cbcb2` — `src/lib/logger.ts`.

**This repository**, read 2026-09-18: `docs/port/COMMONALITY.md:254-258,266-267,278,331`;
`docs/port/BASELINE-REVIEW.md:124,254,330,421,448,477`; `docs/port/PARAMETERS.md` (the
four fixed rows and the `web-extra-surface` row, quoted byte-for-byte);
`docs/port/OWNER-REVIEW.md:187` (owner ruling W2-REST);
`docs/planning/p02/owner-decisions.md` sections 9, 11 and the licence ruling;
`inputs/owner-reference-axum-companion-stack-2026-09-16.md:68,69,111,178,179,180,236,241,324`,
verified byte-identical to the copy in `docs/planning/p02/`;
`research/topics/60-cli-parsing-framework/DECISION.md`;
`research/topics/65-color-enablement-chain/DECISION.md`;
`research/topics/66-output-format-surface/DECISION.md`;
`research/topics/67-error-and-exit-code-contract/DECISION.md`;
`research/topics/69-web-framework-stack/DECISION.md:1629-1630`; and the owner-accepted,
unpublished runs for R02, R05, R56, R57, R61, R62 and
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`. Parallel,
unpublished and read for coupling only:
`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/DECISION.md` (the two service
variable names) and `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/DECISION.md:429-431`
(the C10 hand-off).

**The two org standards**: the CLI Design Standard v1.4.14 at blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `/Users/stevemorin/c/cli-standards`, rules
quoted at `:244`, `:245`, `:266`, `:322`, `:332`, `:381`, `:390`, `:432`; the REST API
Design Standard v2.0.0 at blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9` in
`/Users/stevemorin/c/rest-standards`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, rules quoted at `:271`, `:348`, `:533`,
`:599`, `:1323`, `:1422`, `:1427`, `:1752`, `:1759`.

**Method note on figures.** Figures were taken from exactly the endpoints the prompt's
table names: crates.io `/api/v1/crates/<name>` for `crate.recent_downloads` and
`crate.downloads`, `/versions` for the newest entry with `yanked: false` — which caught
two yanked versions, `tracing` 0.1.42 and `tracing-subscriber` 0.3.21, that a "latest
version" shortcut would have mis-reported — `/reverse_dependencies` for adoption breadth,
GitHub `repos/<o>/<r>` for `stargazers_count`, `archived` and `pushed_at`, and
`search/issues` for `total_count`, never `open_issues_count`, which differs (628 against
894) because it counts pull requests. GitHub calls were paced at one per 21 seconds. No
personal email address appears in any script, User-Agent header, log or snapshot; the
User-Agent is the repository URL. The scratch Cargo probe was created under a directory
this run made inside `$TMPDIR` and deleted on exit, so no `target/` tree and no nested git
repository was written into this repository.


## Empirical check

**This section reports verification only.** This is a research programme: the template
does not exist yet and P03 builds it, so nothing here builds, wires or runs the
recommended pipeline. No `telemetry.rs`, no seam, no acceptance script and no template
scaffold was written. The Cargo probe contains one `main.rs` of scenario code that
exercises *library* behaviour and is not a draft of the recommendation; it lives in
`review/evidence/probe/` as committed input and is compiled in a scratch directory that
is deleted on exit.

**Toolchain and OS.** macOS `Darwin 25.4.0`, `aarch64-apple-darwin`.
Revision 2's re-record ran on
`rustc --version` → `rustc 1.98.1 (48a229cea 2026-09-01) (Homebrew)` and
`cargo --version` → `cargo 1.98.1 (797e8a9bc 2026-08-05) (Homebrew)`; revision 1's
logs were recorded on `rustc 1.98.0 (88d9e12ae 2026-08-18)` and `cargo 1.98.0`, and every
scenario line reproduced unchanged across the two toolchains.
`/usr/bin/grep --version` → `grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`.
`shellcheck --version` → 0.11.0, clean on all four scripts. `gh` authenticated from the
machine keyring as `smorin`; no token byte is read, echoed or written by any script
here. Under `msrv-policy` the floor today is **1.96**, being stable 1.98 minus two minor
versions.

**Working directory** for every command below:
`research/runs/R58/2026-09-18T215915Z-184041b91674/review/evidence/`.

**The commands, and their observed status.**

| Command | Purpose | Observed |
|---|---|---|
| `./r58-probe.sh` | the build, S1–S10 plus S4b behavioural scenarios, and S11 dependency-graph counts | `PASS=33 FAIL=0 SKIP=0 TOTAL=33`, exit 0 |
| `./r58-standards.sh` | the two org standards quoted at their pinned blob lines (14 CLI checks, 10 REST checks), 16 `tracing-subscriber` source checks, this decision's parameter lines against the live registry (4 checks), and the four revision-rule checks — the H1 title, no `## Supersedes`, exactly one `re-verify:` line, and the gate-1 wording counted by `r58-gate1-wording.py` | `PASS=48 FAIL=0 SKIP=0 TOTAL=48`, exit 0 |
| `./r58-figures.sh` | every registry, GitHub and RustSec figure cited, against the committed snapshots | `PASS=161 FAIL=0 SKIP=0 TOTAL=161`, exit 0 |
| `./r58-fetch-snapshots.sh` | provenance: fetches the snapshots the figure check reads | one invocation, 2026-09-27T05:41:34Z to 05:48:12Z: exit 0; 95 snapshot files written, the two RustSec advisory pages at 05:48:10Z and 05:48:11Z; its 46-line log carries both `rustsec advisory:` lines. Adopted as recorded (owner decision Q1.B); not rerun for revision 2 |

**Totals: 242 checks = 33 probe + 48 standards + 161 figures; 242 PASS, 0 FAIL, 0 SKIP.**
Full output is recorded as `r58-probe.log`, `r58-standards.log`, `r58-figures.log` and
`r58-fetch-snapshots.log`.

**What each script asserts, and why a check that cannot fail is not among them.** Every
assertion tests **content**, never an exit code alone. The standards script asserts both
the **line number and the text** of each quoted rule, so a rule that moves in a future
blob fails the check instead of passing quietly — and that is not hypothetical: five
line numbers taken from the raw reports were wrong by one or two lines and were caught
by exactly this mechanism before they reached this decision. The figures script asserts
exact integers and exact date strings, so a refetched snapshot that moves a counter
fails. The probe script asserts both that a secret **is** masked where it must be and
that no secret byte survives where it must not (`sk_live_` absent), which is the
assertion that would catch a formatter regression that merely relabels a field.

**`set -o pipefail` is set at the top of all three scripts**, and no assertion is taken
from the exit status of a pipeline. The one place a pipeline produces a value —
the `cargo tree` crate counts — pipes into `sort -u` and a counting `grep`, and the
value is then compared to an expected integer, so a failure of the upstream command
yields a wrong count and a FAIL rather than a passing zero. A scenario binary that cannot
run records `FAIL  <scenario>: binary did not run (exit <n>)` and the run continues, so
the `PASS=… TOTAL=…` summary line is always printed; and the probe exports
`CARGO_TARGET_DIR="$WORK/target"` directly after creating its scratch directory, so a
machine-wide `CARGO_TARGET_DIR` cannot move the binary away from the path the script
runs. Revision 1's probe had neither guard and exited 127 with no summary under a set
`CARGO_TARGET_DIR`. Revision 2's probe ran with `CARGO_TARGET_DIR` set in the calling
environment and passed 33/33; a `/tmp` copy whose binary path was deliberately broken
printed eleven `binary did not run (exit 127)` lines and the summary
`PASS=9 FAIL=35 SKIP=0 TOTAL=44`, exit 1.

**Versions the probe asserts, and how they are pinned.** `probe/Cargo.toml.in` declares
`tracing = "=0.1.44"` and `tracing-subscriber = { version = "=0.3.23", … }`, and the
probe builds with `cargo build --locked` against the committed `probe/Cargo.lock`, which
also fixes `log` 0.4.34, `tracing-log` 0.2.0 and `secrecy` 0.10.3. The build line's label
"tracing 0.1.44 + tracing-subscriber 0.3.23" is therefore true by construction rather
than asserted. The S11 counting manifests pin `tracing` and `tracing-subscriber` with
`=` but float `serde_json = "1"` with no lockfile, so a `serde_json` release that changes
its own dependency set could move S11c and S11d. Maintaining these pins when the
recommended versions move is a **P03 obligation**, listed below.

**Reproduction was performed, not asserted.** For revision 2, the probe and standards
scripts were rerun in place after this revision's text was written, and their logs are
the output of those runs; the figures script was rerun against the adopted snapshots and
its output was byte-identical to the recorded `r58-figures.log`. Revision 1's
`git archive HEAD` extraction rerun is not repeated: revision 2 is not committed, and no
git operation was part of this repair. In its place, the standards script was rerun in a
`/tmp` replica holding only `docs/port/PARAMETERS.md` and this run's `review/` tree, with
no `.git`: it printed `checkout shape: no .git present (git archive extraction)` and
`PASS=48 FAIL=0 SKIP=0 TOTAL=48`, differing from the in-place log only on its
`repo root:` and `checkout shape:` lines; `r58-figures.sh` in the same replica was
byte-identical to `r58-figures.log`. **The comparison rule across runs:** every line
is compared except three kinds that vary by construction — the `== toolchain ==` header
lines of `r58-probe.log` (`rustc`, `cargo`), the `repo root:` and `checkout shape:`
lines of `r58-standards.log`, and the local Cargo registry path printed in
`r58-standards.log`'s `tracing-subscriber` source line. No log contains a `mktemp` path:
both scripts create their scratch directory with `mktemp -d` but never print it.
`r58-figures.sh` is byte-for-byte identical across every run, because it reads only the
recorded snapshots and touches no network. The scripts locate the repository root by
walking up to `docs/port/PARAMETERS.md` rather than by asking git, and test `.git` with
`-e` only to report the checkout shape.

**A note for an auditor reading the snapshots.** Two snapshot files contain the string
`git@github.com:tokio-rs/…`, which is GitHub's `ssh_url` field and not a personal email
address; no personal email address appears anywhere in this run's `review/` tree.

**Named skips.** In the runs reported above there were **no skips**. Three skips are
*reachable* on a machine unlike this one, and each is named by the script rather than
passed over silently: `cargo` not installed, which skips every probe scenario; the
`cli-standards` or `rest-standards` clone absent, which skips that standard's thirteen or
nine quotations; and `tracing-subscriber-0.3.23` not vendored in the local Cargo
registry, which skips the fifteen source assertions. A fourth, "`review/DECISION.md` not
written yet", replaces the eight checks that read this file with one named skip; it was
observed in the `/tmp` replica with the decision removed (`PASS=40 FAIL=0 SKIP=1 TOTAL=41`) and is PASS
wherever the file exists.

**What was NOT verified**, restated here so the boundary is in one place: no performance
figure, because no workload is defined for this item; no clean-build wall-clock figure
carried into any answer, because this machine ran ten concurrent agents and the timings
did not reproduce the Opus leg's; and no claim that the stack behaves as designed *in
this template*, because the template does not exist. Each is listed under
`### Confidence & re-verify trigger` with what would prove it, and each is left for P03
to prove in the real template.

**What P03 must validate**, being the parts this research could not:

1. That `telemetry::init` composed as specified installs once, returns `HostOwned` rather
   than panicking under an embedding host that has already set a `tracing` dispatcher,
   returns `Installed` with `log_bridge_refused: true` — keeping the level handle live —
   under a **partial host** that installed only a `log` logger (the case probe S4b
   executes: `try_init()` is `Err` yet the template's dispatcher is installed), and leaves
   stdout byte-empty across the CLI's whole command surface.
2. That the seven `tests/telemetry_redaction.rs` assertions hold against the real
   formatter, including assertion 7, the OV-09 boundary, which is written to fail the day
   the override is closed.
3. That `cargo deny --all-features check bans` and R02's `tests/workspace_edges.rs`
   actually prevent `tracing-subscriber` from reaching `crates/core`, `crates/cli` and
   `crates/web`.
4. That the seven-rung ladder resolves in the stated order once R60's parser surface is
   real, with every flag rung above the environment rung as R5.1 requires: `--debug`
   beating an explicit `--log-level`, and an explicit `-q` or `-v` beating an inherited
   `RSLBP_LOG_LEVEL` (for example, `RSLBP_LOG_LEVEL=debug rslbp -q …` resolves to
   `ERROR`).
5. That the service profile emits JSON from its first line with no TTY-dependent
   variation, under R77's two environment variables.
6. That `traceparent` propagation works with the `otel` feature **off**, which is the
   REST R11.8 constraint this decision places on R78's boundary and the one requirement
   here that no probe could exercise without an HTTP surface.
7. That the version pins stay true: the template's manifests and lockfile pin the
   recommended `tracing` and `tracing-subscriber` versions, and whenever those move, the
   probe's `=` pins, its `Cargo.lock` and the S11 counting manifests are re-pinned and
   the counts re-asserted together — a pin-maintenance obligation this research hands to
   P03 rather than discharges.

## Engines

**Engine reports read for this decision.**

- opus `raw/opus.md` — Claude Opus 5, sha256 `bf2cfd6dd2b72b7d2e85e650ec30aae89f8bd6521fea1ce567bec1ff8e0e4cc1` (the run also carries the identical bytes as `raw/opus-bf2cfd6d….md`).
- doxa `raw/doxa.md` — the three-provider Doxa report, operation `research-20260918-150344-b74724d646f64958`, with its normalized twins `raw/doxa.normalized.md` (merged bundle twin), `raw/doxa-openai.normalized.md` (`gpt-5.6-sol`), `raw/doxa-perplexity.normalized.md` (`sonar-deep-research`) and `raw/doxa-gemini.normalized.md` (`deep-research-preview-04-2026`). `doxa/normalization.json` records `shape: "OK: validation passed"` for all three providers and for the regrouped twin, with `changes: []` and `content_lines_missing_from_regrouped: 0` for each.
- muse `raw/muse.md` — Muse (Meta), model `muse-spark`, sha256 `5105b7b124de5424bdc36ee073e519ba17fdb61f220b56c388ac3162abbbe238`, operation `operations/muse.json` request `8948ab48b81f493cb3094277bd88c281`; its live figures are dated 2026-09-25 and it executed no checks. This item's binding prompt reads `- engines: muse, opus, doxa` (`inputs/prompt.md:28`) and states at `:74`: "This item substitutes Muse (Meta) for Codex under the `engine_overrides` pilot; its mirrored `- engines:` line is authoritative." The Muse report arrived after revision 1 was written; revision 2 lists it and adjudicates its six contested positions below.
- codex — **not a prompt engine for this item.** Revision 1 recorded Codex as an absent leg deferred under owner ruling W1-CODEX3 (2026-09-18) and read the prompt as naming `engines: codex, opus, doxa`. The prompt's authoritative line now names Muse in Codex's place, so every engine the prompt names is represented: Opus, the three Doxa providers and Muse.

**Where the legs agreed.** All five model outputs — Opus, the three Doxa providers and
Muse — independently recommend `tracing` plus `tracing-subscriber` as the architecture and
the core of the stack, and all five keep the OpenTelemetry integration behind an optional
Cargo feature. That convergence is recorded as corroboration and is explicitly **not**
treated as the ground of the recommendation, per the research mandate: the ground is the
architectural argument from P3 and P4, and the executed evidence for it.

**Disagreement 1 — is the core library's facade `log` or `tracing`?** The Perplexity leg
recommends a split: "`log`: the logging facade used by the core library crate(s)" with
`tracing` for the CLI and web crates, bridged by `tracing-log`. Opus, OpenAI and Gemini
put `tracing` everywhere. **Settled against Perplexity on executed evidence.** Probe S9
emitted one secret through each path into the same redacting formatter:
`connecting token=sk_live_LOGFACADE password=hunter2` survived in clear from the
`log::Record`, while `token="[REDACTED]"` was masked on the `tracing::Event`. A
`log::Record`'s payload is one formatted string with no field keys, so key-based
redaction has nothing to bind to; a `log`-facade core would push CLI R5.6's **MUST** back
to every call site in exactly the crate that most needs it not to be there. Perplexity's
stated reason — that a `log` facade lets a host choose its backend — is real but is
already satisfied: `tracing` is equally backend-neutral in a library, and probe S4
demonstrates the host-ownership property directly.

**Disagreement 2 — is `tracing-subscriber`'s `json` feature on or off?** The Gemini leg
recommends `env-filter`, `json` and `reload`; the OpenAI leg says "with JSON enabled";
the owner reference's `Cargo.toml` at `:179` also enables it. **Settled against all three
on executed evidence.** Probe S1 shows the stock `Format<Json>` serialising event fields
through `tracing_serde` and leaking `"token":"sk_live_EVENTSECRET"` and
`"password":"hunter2"` while the same redacting `FormatFields` masks the span field —
and the source shows why, at `json.rs:253`, `:266` and `:272`. The feature is measured to
add exactly two crates for a formatter the template must replace anyway. Note that the
OpenAI leg is **half in agreement**: it also specifies a `SanitizingFields: FormatFields`
and a `DiagnosticEventFormat: FormatEvent`, which is this decision's design; its "JSON
enabled" is inconsistent with its own component list, and the inconsistency is resolved
here in favour of its component list.

**Disagreement 3 — can redaction be done in a `Layer`?** The Perplexity leg says "a
custom `Layer` inspects event and span fields and replaces values". **Settled against it
on compiler evidence.** A `tracing::Event` is immutable and `RecordFields` is sealed
(`src/field/mod.rs:88`), so no `Layer` can hand a modified event onward:
`error[E0277] … 'RecordFields' is a "sealed trait"`. Redaction must happen at format
time, which is the finding that makes the template-owned formatter necessary rather than
merely convenient.

**Disagreement 4 — should the `redactable` crate be adopted?** The Perplexity leg
recommends it as a stack member, asserting "No gate excludes `redactable`. License is
likely MIT or Apache". **Settled against it on registry evidence, and the leg's factual
claim is wrong on two counts.** Its newest non-yanked version — 0.13.0 at revision 1's
snapshot, 0.14.0 (published 2026-09-23) at the 2026-09-27T05:48:12Z snapshot — declares
`rust_version` **1.97**, which is **above** the 1.96 floor, so it **fails fitness gate
2** — the only gate failure in this item. Its licence string is **`non-standard`**, not
"likely MIT or Apache"; the word "likely" is itself the signal that the figure was
inferred rather than retrieved. Its reverse-dependency total is **1**. All three figures
are asserted in `review/evidence/r58-figures.sh`.

**Disagreement 5 — stdout or stderr for the service profile?** The owner reference at
`:111` says "Emit **JSON logs to stdout**", and no engine leg contradicted it. **Settled
against the reference document on org-locked ground**, which is the one place this
decision departs from a standing owner input: CLI Design Standard R7.1 **(MUST)** at
`:381` reserves fd 1 for the requested result, and R67's accepted envelope requires
stdout to stay byte-empty on the error path. Owner decision 11 makes the reference an
input that "binds process, not outcome", so a differ with a recorded ground is the
prescribed handling. The cost of differing is nil: every container runtime captures both
descriptors.

**Disagreement 6 — how many OpenTelemetry crates are members of this stack?** All three
Doxa providers name `tracing-opentelemetry` and the OTel SDK crates as stack members;
OpenAI adds a `RedactingSpanExporter<E>`. Opus leaves them out. **Settled in Opus's
favour on scope, not on merit**: R78 owns `opentelemetry-integration`, and this item's
prompt places the integration out of scope while giving R58 only the optional feature
*boundary* (F304). The MEDIUM question is nonetheless answered — `tracing-opentelemetry`
0.34.0, the newest version as of the 2026-09-27T05:48:12Z snapshot, was published
2026-09-23 from a sibling repository in the same organisation (revision 1 cited 0.33.0 of
2026-05-18, then the newest), and
it is gateable behind an optional Cargo feature, as `rust-lang/rustup` demonstrates in
production. OpenAI's `RedactingSpanExporter` is recorded as **corroboration of a finding
this decision reached independently**: an exporter reads the `Event` directly and
therefore sees unredacted fields, so it must apply the redaction policy itself. That is
written into the telemetry member's *Migration implications* as an obligation R78
inherits.

**The Muse leg's contested positions, adjudicated (revision 2).** Muse agrees with the
stack's core and with the optional OTel boundary. Six of its positions differ from this
decision or bear on a figure it carries; each is settled on evidence, not on engine
count.

| # | Muse position (`raw/muse.md`) | Settlement and evidence |
|---|---|---|
| M1 | Redaction by "a small template-owned redacting `Layer` (a `field::Visit` implementation comparing key names against the `SENSITIVE_KEY_PARTS` policy list) wraps the `fmt` layer, so redaction applies to every sink including OTel" (`:31`; again at `:140`) | **Settled against Muse, on compiler evidence — Disagreement 3 with a fourth dissenting leg.** A `Layer` can visit an event's fields but cannot hand a modified event to any other layer: `tracing::Event` is immutable and `RecordFields` is sealed (`src/field/mod.rs:88`, `error[E0277] … 'RecordFields' is a "sealed trait"`). Every layer, the OTel layer included, reads the `Event` directly, so a redacting layer beside `fmt` changes nothing another layer sees. Muse's claim that such a layer reaches the OTel sink is therefore the opposite of this decision's finding: redaction is a property of rendered output, and R78's exporter must apply the policy itself, as the telemetry member's *Migration implications* records. |
| M2 | `tracing-subscriber` with the `json` feature on (`:144`; the member pin at `:156`) | **Settled against Muse, on executed evidence — Disagreement 2 with a fourth dissenting leg.** Probe S1: the stock `Format<Json>` serialises event fields through `tracing_serde` and leaks `"token":"sk_live_EVENTSECRET"` while the same redacting `FormatFields` masks the span field (`json.rs:253`, `:266`, `:272`). The feature adds exactly two crates (S11d) for a formatter the template must replace. |
| M3 | `tracing-opentelemetry` 0.34 as a stack member (`:39`; the shortlist at `:195`) | **Membership settled against Muse on scope — Disagreement 6**: R78 owns `opentelemetry-integration`, and R58 fixes only the feature boundary. **Muse's version figure is right**, and revision 2 adopts it: the 2026-09-27T05:48:12Z snapshot's newest non-yanked `tracing-opentelemetry` is 0.34.0, created 2026-09-23, `rust_version` 1.75.0, licence MIT (`r58-figures.log`, the four `tracing-opentelemetry newest …` lines), where revision 1 cited 0.33.0 from its earlier snapshot. The MEDIUM question is now answered with 0.34.0. |
| M4 | The level ladder "flag/env > config > `-v`/`-q`" (`:31`; again at `:140`) | **Settled against Muse on two grounds.** First, CLI R5.1 **(MUST)** lists command-line flags (`:290`) and `TOOL_*` environment variables (`:291`) as separate tiers, flags first, so flag and environment cannot share a rung. Second, placing the config file above `-v`/`-q` lets a configuration value override an explicit flag, which is R5.1's own ❌ example, "a config file value silently overriding an explicit flag"; py's `cli/context.py:197`–`:209` also keeps `-q`/`-v` above config. Muse's own planned check at `:164`, "`--log-level error -vv` still errors-only (flag beats ladder)", holds under this decision's order, where rung 2 sits above rung 4. |
| M5 | `tracing-subscriber` maintenance `active` (`:116`), with "#3613 answered by a contributor in ~2d" | **The fact is right; the verdict does not follow.** The snapshot `snapshots/gh-issue-3613-comments.json` holds one comment, by `mladedav`, `author_association` `CONTRIBUTOR`, at 2026-09-18T07:29:15Z, about 1.6 days after the issue opened (2026-09-16T17:32:52Z). The prompt's responsiveness rule counts only `OWNER`, `MEMBER` or `COLLABORATOR`, so this is one of the four one-comment issues already counted, and 10 of 10 remain unanswered by a maintainer. Muse's own sample was four issues, two unanswered, with the 10-issue median "not computed" (`:116`). Its `active` rests on release recency and no advisory, which this decision also records and weighs against the unanswered sample and the maintainers' own `experimental` badge. **`at-risk` stands.** |
| M6 | `slog` excluded because its maintainer points new work to `tracing` (`:65`) | **Corroboration recorded; the ground of rejection is unchanged.** The judgment audit of revision 1 read the `slog` README as saying "You might consider using `tracing` instead" (`review/audit-fable.md`, F1). That supports rejecting `slog` for a new template. This decision still rejects `slog` on P4 and on its threaded `Logger` entering `crates/core`'s public API, not on the pointer, and does not treat it as a gate exclusion; Muse likewise says `slog` "passes license/MSRV/advisory gates". Muse's stronger wording, "feature-frozen" and "maintenance mode", was not verified here and is not carried. |

**Where a leg is wrong on a carried figure, said plainly.** The Opus leg is the most
thorough of the five and its architectural conclusions hold, but five of its figures did
not survive re-derivation and are corrected here rather than carried:

| Opus figure | Re-derived here | Consequence |
|---|---|---|
| "nine of the ten have **zero** comments of any kind" | **six** of ten; the other four have one comment each, none from a maintainer | none for the verdict — 10 of 10 unanswered is confirmed independently, and the sample is the same ten issue numbers — but the sub-figure was wrong |
| `json.rs:252` and `:268-270` | `:253`, `:266` and `:267`, plus `:272` for the non-flattened branch Opus did not cite | strengthens the finding: the leak holds in **both** branches, not only under `flatten_event` |
| "a subscriber costs the composition root about **19** crates" | **17** for the recommended feature set; 19 counts the `json` feature Opus itself recommends turning off | the honest gate-6 figure is 17 |
| "`env-filter`'s `regex-automata` is the single largest compile-time line item" | **not reproduced**; timings on this loaded machine do not separate the trees | dropped entirely; gate 6 is answered with crate counts, which are deterministic |
| C10 tally "5 agree, 2 differ" | **3 agree, 3 differ, 1 hand-off** over the same seven rows | the raw's tally does not reconcile with its own table; the corrected recount is carried |

Two further Opus details were confirmed rather than corrected, and are worth recording
because they were the load-bearing ones: `tracing` 0.1.42 and `tracing-subscriber` 0.3.21
are both **yanked**, so a "latest version" shortcut would mis-report the pin; and the
ten-issue responsiveness sample is the same ten issue numbers this synthesis drew
independently, with the same 10-of-10 result.

**One finding this synthesis adds that no leg reported.** `tracing-subscriber`'s own
documentation at `src/fmt/format/json.rs:422` refers to "[`JsonFields`]'s
[`MakeVisitor`] implementation", and no such implementation exists — the compiler says
`the trait bound 'JsonFields: MakeVisitor<Writer<'_>>' is not satisfied` and enumerates
the six types that do implement it. The design premise therefore had to be settled
against the compiler rather than against the documentation, and
`review/evidence/r58-standards.sh` asserts the **absence** of that impl so that a future
version adding it fails the check and reopens the question.

**Uncertainty, stated where the evidence is incomplete.**

- **The Muse leg is a fourth model family, and it executed nothing.** Revision 1 named an
  absent Codex leg as the largest gap in its evidence base. Under the `engine_overrides`
  pilot the prompt names Muse instead, and Muse's report is now adjudicated above, so
  that gap is closed as the prompt defines it. What remains is narrower: Muse's positions
  are reasoned from documentation and registry reads dated 2026-09-25, with no executed
  check, so where Muse dissents — the `json` feature, a redacting `Layer`, the ladder
  order — the settlement rests on this decision's executed probe and quoted source, not
  on a count of engines. This decision does not claim a five-engine consensus on those
  points.
- **The ladder's exact rungs** are a design choice, not a discovered fact. R4.4 fixes
  that there must be one unambiguous ladder and fixes `--debug` above `--quiet`, and R5.1
  fixes every flag rung above `RSLBP_LOG_LEVEL` (revision 2's reorder); neither fixes
  `--debug` above `--log-level`, and this decision extends the rule's stated
  reason to reach that. R60's and R54's published surfaces could refine it. Confidence
  medium, and labelled medium above.
- **The OV-09 residue's real-world size** is unmeasured. Probe S10 proves the gap exists;
  nothing here measures how often a secret actually reaches a non-sensitive field's value
  in practice, and no claim about its frequency is made.
- **R69 revision 10 is unpublished.** This design is written against its `crates/web`
  shape while carrying revision 9's registry bytes. If revision 10 is revised again
  before publication in a way that changes which package hosts the web module, the crate
  edge table in `### Principles and implementation` needs one line changed; nothing else
  in this decision depends on it.
- **Six prerequisite decisions were owner-accepted but unpublished when revision 1 was
  written** — R02, R05, R56, R57, R61 and R62 — and this design is written against all of
  them. At revision 2, five of the six are published under `research/topics/`: R57
  revision 2 (sha256 `44e945045f0e2c964520918801f5c8f3921a3cfefc4ef5c72b0bc497038139ba`)
  and R62 revision 2 (`fb0a58c9556fdd19052e165d2f5a1d53e2766a84961ab86f9f2401500140d3c2`),
  both at their accepted hashes; R02 revision 3
  (`d8c64f7c36663f0c92dcc83cc444a56f203f6c4f52d3fff2a64de9f611cfd2e7`); R56 revision 5
  (`7a4f06ca0cfc136e516da23e62374532e6d76a9c452119b0a2d1113a736873be`); and R05, whose
  topic decision is revision 6 (`3ae15853b0b613ff537ef647ff26be8260143a761328b8537e041a287c858b03`)
  while its owner-acceptance row names revision 3 (`3ca4b81a…`), the revision this decision
  cites. Only R61 remains unpublished. The publication of R02, R05 and R56 fires this
  decision's re-verify trigger for them; revision 2 records that it fired and does not
  re-derive against the published texts.
