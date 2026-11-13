# R58 — logging-pipeline-architecture (bundle, Deep) — Opus raw research report

Engine: Claude Opus 5. Run `research/runs/R58/2026-09-18T215915Z-184041b91674/`.
No Rust source exists in this repository; every behavioural claim below that is
labelled **executed** was produced by a throwaway Cargo probe built under
`$TMPDIR` on macOS `aarch64-apple-darwin`, `cargo 1.98.0 (797e8a9bc 2026-08-05)`
/ `rustc 1.98.0 (88d9e12ae 2026-08-18)` (Homebrew), on 2026-09-18, and deleted
after the run. Everything else is labelled **proposed**.

### Landscape

**The category this item decides.** Not "which logging library" but *which
diagnostic-emission architecture the template adopts*: how a diagnostic event is
produced by library code that does not know where it will be rendered, how it is
filtered, how it is formatted into two different profiles, how a key-based
secret rule is applied to it, and who is allowed to install the process-global
machinery that does the rendering. The crate selection follows from that; it does
not precede it.

**The three-bin map of the Rust field (retrieved 2026-09-18).**

| Bin | Members found | Note |
|---|---|---|
| Built-in / first-party toolchain | **none for emission**; `std::io::IsTerminal` (stable 1.70.0) for TTY detection; `eprintln!` | The Rust standard library ships no logging facade and no subscriber. The nearest thing to a first-party position is that the Rust *project's own tools* pick from the ecosystem — `rust-lang/cargo`, `rust-lang/rustup` and `rust-lang/rust-analyzer` all depend on `tracing` + `tracing-subscriber` (manifests quoted under *Practice evidence*). That is first-party **practice**, not a first-party API. |
| Established industry standard | **facades:** `log` 0.4.34 (30,655 reverse dependencies), `tracing` 0.1.44 (**42,556** reverse dependencies) · **renderers over `log`:** `env_logger` 0.11.11, `fern` 0.7.1, `log4rs` 1.4.0 · **subscriber over `tracing`:** `tracing-subscriber` 0.3.23 (18,766 reverse dependencies) · **structured-first alternative:** `slog` 2.8.2 (416 reverse dependencies) · **formatter add-ons:** `tracing-bunyan-formatter` 0.3.10, `tracing-tree` 0.4.1, `tracing-stackdriver` 0.10.0 · **OTel bridge:** `tracing-opentelemetry` 0.33.0 | Reverse-dependency totals from `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1` field `meta.total`, retrieved 2026-09-18. `tracing` now outranks `log` on that measure. |
| Up-and-comers | `fastrace` 0.7.19 (1,134 stars, Apache-2.0, `rust-version` 1.91.0), `logforth` 0.30.1 (238 stars, Apache-2.0, `rust-version` 1.89.0), `tracing-forest` 0.3.1 | Both `fast/*` crates are maintained, recently pushed and deliberately positioned as lighter alternatives to `tracing`/`tracing-subscriber`. Neither is shortlisted; reasons under each member's *Excluded by gate* / *Up-and-comers*. |

There are exactly **three architectures** in that map, and the item turns on
choosing between them, not on choosing between crates:

1. **Record-and-render (the `log` architecture).** A call site produces one
   already-formatted `log::Record` with a level, a target and a `fmt::Arguments`
   message. A single process-global `log::Log` implementation renders it. Key/value
   pairs exist since `log` 0.4.7 but are an unstable, opt-in side channel; the
   primary payload is a formatted string. `env_logger`, `fern` and `log4rs` are
   renderers for this architecture.
2. **Event-and-span instrumentation (the `tracing` architecture).** A call site
   produces a `tracing::Event` carrying *typed, named fields* and an implicit
   parent span; a process-global `Subscriber` — in practice
   `tracing_subscriber::Registry` composed with `Layer`s — decides interest,
   collects span state and formats. Fields are the primary payload and the
   formatted line is derived. Spans give a causal parent chain that a `log`
   record has no place to carry.
3. **Structured-record with an explicit drain (the `slog` architecture).** Typed
   key/value records, an explicitly threaded `Logger` value rather than a global,
   and composable `Drain`s. Architecturally the closest thing in Rust to
   structlog's processor chain.

**Authoritative sources used, and why each counts.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| `tokio-rs/tracing` source at the published crate versions in `~/.cargo/registry`, and https://github.com/tokio-rs/tracing | The maintainers' own implementation, read at exactly the versions recommended. Behaviour claims here are read out of `tracing-subscriber-0.3.23/src/...`, not out of prose. | 2026-09-18 |
| `rust-lang/cargo` `Cargo.toml` (https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml) | The Rust project's own build tool; a first-party publication of what the project itself depends on. | 2026-09-18 |
| `rust-lang/rustup` `Cargo.toml` and `src/cli/log.rs` (https://raw.githubusercontent.com/rust-lang/rustup/master/src/cli/log.rs) | The Rust project's own toolchain installer, and the closest maintained *CLI* reference implementation of the exact architecture recommended here — custom `FormatEvent`, `reload::Handle<EnvFilter, Registry>`, stderr writer, optional `otel` Cargo feature. | 2026-09-18 |
| RustSec Advisory Database (https://rustsec.org/packages/tracing-subscriber.html, https://rustsec.org/advisories/RUSTSEC-2025-0055.html, https://rustsec.org/advisories/RUSTSEC-2023-0078.html) | The Rust Secure Code Working Group's advisory database; the authority fitness gate 3 names. | 2026-09-18 |
| The org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `/Users/stevemorin/c/cli-standards` | Org-binding for this template per owner decision 9 (`docs/planning/p02/owner-decisions.md:269`), "DECIDED. The standard BINDS." | 2026-09-18 |
| crates.io API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) | The registry of record for versions, release dates, declared `rust_version`, licence strings and download counts. | 2026-09-18 |
| GitHub REST API (`repos/<o>/<r>`, `search/issues`) | Stars, archived state, push recency and open-issue counts, per the prompt's figure table. | 2026-09-18 |
| The owner's reference architecture, `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md` | Standing input per owner decision 11; its C10 rows are reconciled row by row below. | 2026-09-18 |

A single blog post is not treated as an authority anywhere in this report; no blog
post is cited as a ground for any recommendation.

**Practice evidence — mainstream, well-regarded Rust projects, weighted toward
recent and popular ones.** Each is well regarded on stated grounds, not assertion.

| Project | Why it is a relevant, well-regarded reference | What its manifest shows (retrieved 2026-09-18) |
|---|---|---|
| `rust-lang/cargo` | The Rust project's official build tool; every Rust developer runs it. | `tracing = { version = "0.1.44", default-features = false, features = ["std"] }` at workspace level with the comment "be compatible with rustc_log", `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`, and the binary adds `tracing = { workspace = true, features = ["attributes"] }` (`Cargo.toml:118-120,226-228`). **This is the exact core-versus-composition-root feature split recommended below, in the ecosystem's most-run binary.** |
| `rust-lang/rustup` | The Rust project's official toolchain installer; a CLI with a library core, i.e. this template's shape. | `tracing = "0.1"`, `tracing-log = "0.2"`, `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`, `tracing-opentelemetry = { version = "0.33", optional = true }` (`Cargo.toml:98-101`) behind `otel = ["dep:opentelemetry-otlp", "dep:tracing-opentelemetry", "dep:opentelemetry", "dep:opentelemetry_sdk"]` (`Cargo.toml:29-34`). |
| `rust-lang/rust-analyzer` | The official Rust language server; the default Rust IDE experience in VS Code. | `tracing = { version = "0.1.41", default-features = false, features = ["std"] }`, `tracing-subscriber = { version = "0.3.20", default-features = false, features = ["registry","fmt","local-time","std","time","tracing-log"] }`, `tracing-tree = "0.4.0"` (`Cargo.toml:148-157`). |
| `astral-sh/uv` | The Python package manager this programme's own `AGENTS.md` workflow runs; a large, new, heavily adopted Rust CLI. | `tracing = { version = "0.1.40", default-features = false, features = ["attributes","std"] }`, `tracing-subscriber = { version = "0.3.18", default-features = false, features = ["ansi","fmt","smallvec","std","tracing-log"] }`, `tracing-tree`, `tracing-durations-export` (`Cargo.toml:326-336`). |
| `astral-sh/ruff` | The most-adopted new Rust developer tool of the last three years. | `tracing`, `tracing-log`, `tracing-subscriber = { default-features = false, features = ["env-filter","fmt","ansi","smallvec"] }`, and — notably — **also** `log` 0.4.17 and `fern` 0.7.0 for a separate user-facing message channel (`Cargo.toml:108,150,230-239`). The one surveyed project that still runs a `log`-architecture renderer alongside `tracing`. |

Not one surveyed project uses `slog`, `log4rs`, or a bare `log` + `env_logger`
stack as its primary diagnostic architecture. `env_logger` remains widely used
(11,935 reverse dependencies) but predominantly in examples, tests and small
tools, not in the layered CLI + library + service shape this template has.

**Fit test applied before any ranking.** The template is one library crate, one
CLI binary and one optional web service that must share a pipeline (F263), must
protect secrets by key (F252), must correlate with OpenTelemetry behind an
optional Cargo feature (F253, F304), must not steal a host's logging (F262), and
must not drag an async runtime into the default dependency tree (R05 r2). Three
of those five are properties the `log` architecture structurally cannot supply
(no field model → nothing to redact by key; no spans → nothing to correlate), which
is why the architecture question is settled before the crate question.

### Principles and implementation

**The shared requirement, and its agreement level.**

| # | Requirement | Source | Agreement level | May vary |
|---|---|---|---|---|
| P1 | Diagnostics are **structured events with named fields**, not pre-formatted strings, so that every sink inherits field-level policy | F251; py `core/logging.py:154` `_shared_processors()`; ts has none (`src/lib/logger.ts:47`) | **architectural pattern** — all three ecosystems need a field model, none needs the same one | the composition mechanism (processor chain vs. layered subscriber vs. drain) |
| P2 | The console render mode **auto-selects** machine-readable vs. human from the diagnostic stream's TTY-ness | F250; py `core/logging.py:120` `_resolve_format` on `sys.stderr.isatty()` | **capability** | the format's exact bytes; whether a flag/env can force it |
| P3 | **Key-based** secret redaction happens inside the pipeline, so call sites cannot forget | F252; py `core/logging.py:93` `SENSITIVE_KEY_PARTS`, applied by `_redact_sensitive` (`:143`) as the **last** shared processor | **policy** — org-locked by CLI Design Standard R5.6 **(MUST)**: "Secret values (tokens, passwords, keys) **MUST** be masked in all output — `config view`, `--debug`/request logs, progress, and error messages" (`cli-design-standard.md:332`) | the key vocabulary, the mask string, and where in the pipeline it is enforced |
| P4 | Trace/span correlation is available but **optional**, gated behind an optional dependency set | F253, F304; py `core/logging.py:106` soft-imports `opentelemetry.trace`; py `pyproject.toml:55-69` separate `otel` extra | **architectural pattern** | the gating mechanism (Python extra vs. Cargo feature) |
| P5 | An **explicit level** control exists ahead of the relative verbosity ladder | F254, F274; py `cli/options.py:85` `"--log-level", ... envvar="PLBP_LOG_LEVEL"`; py `cli/context.py:197` `_resolve_console_level` | **standard** — CLI Design Standard R4.4 **(MUST)** "These three controls **MUST NOT** overlap ambiguously — define one ladder" (`:266`) | the level names, the default, and the ladder's exact order |
| P6 | Re-initialisation is **idempotent and host-safe**: the pipeline never tears down machinery it does not own | F262; py `core/logging.py:226` `for handler in root.handlers[:]: if getattr(handler, _OWNED_FLAG, False)` | **policy** | the mechanism, which is ecosystem-specific and *very* different in Rust |
| P7 | **One engine, two policy profiles** — the CLI and the web service share the pipeline and differ only in policy | F263; py `web/logging.py:20` "Same engine as the CLI (`core/logging.py`), different policy" | **architectural pattern** | whether the second profile exists at all (R69's `web-extra-surface`) |
| P8 | Diagnostics go to **stderr**; the result stream stays clean | CLI Design Standard R7.1 **(MUST)**: "fd 1 (stdout) carries the command's *requested result*; fd 2 (stderr) carries everything else: diagnostics, progress, prompts, warnings, and errors" (`:381`) | **standard, org-locked** | nothing |

What must agree across py, ts and rs: P1–P8 as *capabilities and policies*. What
may vary: every mechanism. This report differs from py on exactly three
mechanisms — **(i)** the redaction insertion point (format time, not event time);
**(ii)** the reconfiguration model, of which the format's init-time fixity is the
one user-visible consequence; and **(iii)** the addition of a `--log-format`
flag and `RSLBP_LOG_FORMAT` on the CLI, which py has only for its file sink — and
it gives measured or quoted ground for each.

**Architectural comparison, before any library is chosen.**

| | Record-and-render (`log` + `env_logger`/`fern`/`log4rs`) | Event-and-span (`tracing` + `tracing-subscriber`) | Structured-record with drains (`slog`) |
|---|---|---|---|
| P1 field model | Message is a formatted string; key/values are an unstable opt-in side channel | **Native**: fields are typed and named on `Event` and `Span` | **Native**: typed key/value records |
| P2 TTY auto-format | Possible in any renderer | Possible; the profile is chosen when the subscriber is built | Possible |
| P3 key-based redaction | **No key to match on** in the primary payload | Possible, but *only at format time* — `Event` is immutable (see below) | **Natural**: a `Drain` wrapper can rewrite key/values, closest to structlog |
| P4 OTel correlation | No span context to correlate | **First-class**: `tracing-opentelemetry` 0.33.0, maintained in the `tokio-rs` org | Third-party, thin |
| P6 host safety | `log::set_logger` once per process; `set_boxed_logger` returns `SetLoggerError` | `set_global_default` once per process, returns an error thereafter; plus a scoped `set_default` guard | **No global at all** — `Logger` values are threaded explicitly, which is the most host-safe and the most invasive |
| P7 two profiles | Two renderer configurations | Two layer configurations over one builder | Two drain stacks |
| Ecosystem pull | 30,655 reverse deps, but the surveyed projects use it only as a *bridge* | 42,556 reverse deps; every surveyed project's primary | 416 reverse deps; no surveyed project |

**The choice is `tracing`, and the reason is P3 and P4 together, not popularity.**
`log`'s architecture cannot express P3 at all: there is no key to match on, so
"redact by key name" has nothing to bind to, and R5.6's **MUST** would have to be
discharged at every call site, which is exactly the failure mode P3 exists to
prevent. `slog` expresses P3 most naturally of the three but fails P4 (no
maintained first-class OTel bridge) and would make the library crate's public API
carry a `Logger` value, which contradicts R01's already-accepted port shape and
R02's crate-edge rule. `tracing` expresses P1, P2, P4, P6, P7 natively and P3
with a template-owned formatter — and that last point is where this report
departs from a naive port of py's design, on **executed** evidence.

**Where the target ecosystem needs a different design — the one finding that
changes the answer.**

structlog's redaction is a *processor*: `_redact_sensitive` sits last in
`_shared_processors()` and rewrites the mutable `event_dict` before any renderer
sees it, so every sink inherits it for free. `tracing` has no analogue. A
`tracing::Event` is immutable and is *visited*, not transformed; a `Layer` can
observe an event and can decide interest, but it cannot hand a modified event to
the next layer. Redaction therefore has to happen **where fields are turned into
bytes**, and `tracing-subscriber` offers exactly two seams for that: the
`FormatFields` trait (span fields, and event fields *in some formatters*) and the
`FormatEvent` trait (the whole line).

Those two seams are **not symmetric between the human and the JSON formatter**,
and the asymmetry is load-bearing. Read at `tracing-subscriber-0.3.23`:

- `impl<S, N, T> FormatEvent<S, N> for Format<Json, T>` serialises event fields
  itself — `let mut visitor = tracing_serde::SerdeMapVisitor::new(serializer); event.record(&mut visitor);`
  (`src/fmt/format/json.rs:268-270`). The `N: FormatFields` parameter is reduced
  to `let format_field_marker: std::marker::PhantomData<N> = std::marker::PhantomData;`
  (`:252`) and is used **only** to look up `FormattedFields<N>` for *span* fields.
- Worse, the JSON formatter requires the span field string to be parseable JSON:
  `match serde_json::from_str::<serde_json::Value>(data)` (`:175`), and on failure
  `panic!("span '{}' had malformed fields! this is a bug. …")` in debug builds
  (`:186-190`, `:199-205`), degrading to a `field_error` key in release.

**Executed (probe `json2 spanonly`).** A redacting `FormatFields` installed with
`.json().fmt_fields(...)` redacted the *span* field and left the *event* fields
in clear:

```
{"timestamp":"2026-09-18T22:13:38.624983Z","level":"INFO","message":"processing request","user":"alice","token":"sk_live_EVENTSECRET","password":"hunter2","target":"json2","span":{"api_key":"[REDACTED]","request_id":"abc-123","name":"request"}}
```

**Executed (probe `r58probe json-fmtfields`).** The naive port — a non-JSON
redacting `FormatFields` under `.json()` — did not silently under-redact; it
**panicked at runtime**:

```
thread 'main' panicked at tracing-subscriber-0.3.23/src/fmt/format/json.rs:199:49:
span 'request' had malformed fields! this is a bug.
  error: expected value at line 1 column 1
  fields: FormattedFields { fields: "request_id=\"abc-123\" api_key=\"[REDACTED]\"", … }
```

**Executed (compile-time evidence).** `tracing-subscriber` even refuses the
builder order: `.json().fmt_fields(Redacting).flatten_event(true)` fails to
compile with `error[E0599]: no method named 'flatten_event' found for struct
'tracing_subscriber::fmt::Layer<_, Redacting, Format<Json>>' … method
'flatten_event' is available on 'tracing_subscriber::fmt::Layer<_, JsonFields,
Format<Json>>'`. The JSON profile's builder surface is typed against
`JsonFields` specifically.

**Executed (the working design, probe `json2 custom`).** A **template-owned**
`FormatEvent` plus a **template-owned** JSON `FormatFields` redacts both, and
stdout stays byte-clean:

```
stdout: RESULT-ON-STDOUT
stderr: {"level":"INFO","target":"json2","message":"processing request","user":"alice","token":"[REDACTED]","password":"[REDACTED]","span":{"api_key":"[REDACTED]","request_id":"abc-123"}}
```

Two further mechanisms were ruled out before settling on the owned formatter, so
that "write it yourself" is a conclusion rather than a preference:

- **Wrapping `JsonFields`.** `JsonFields` does not implement `MakeVisitor`
  (`error[E0599]: the method 'make_visitor' exists for struct 'JsonFields', but its
  trait bounds were not satisfied … 'JsonFields: MakeVisitor<_>'`), so its visitor
  cannot be decorated.
- **Interposing on the field stream.** `RecordFields` is a **sealed trait**
  (`error[E0277] … 'RecordFields' is a "sealed trait", because to implement it you
  also need to implement 'tracing_subscriber::sealed::Sealed', which is not
  accessible`), so a `Redacted<R>(R)` adapter cannot exist.

The *human* profile is different and does not need an owned event formatter:
`DefaultFields` **does** implement `MakeVisitor`, so a thin wrapper works, and
rustup's own `EventFormatter` shows the same delegation
(`ctx.field_format().format_fields(writer.by_ref(), event)?`,
`rust-lang/rustup:src/cli/log.rs:95`). **Executed (probe `r58probe
human-redact`)**, one wrapper redacted both span and event fields on the human
profile:

```
2026-09-18T22:10:44.946590Z  INFO request{request_id="abc-123" api_key="[REDACTED]"}: r58probe: processing request user="alice" token="[REDACTED]" password="[REDACTED]"
```

**Consequence for the `json` Cargo feature.** Because the structured profile is
template-owned, `tracing-subscriber`'s `json` feature (which pulls `tracing-serde`,
`serde` and `serde_json`) is **not needed**; the owned formatter writes through
`serde_json`, which R66's accepted stack already puts in the tree.

**P6 — "only tears down handlers it owns", in Rust's global-subscriber model.**
Rust cannot express py's mechanism, and should not try to. The three facts:

1. The global dispatcher can be set **once**. **Executed (probe `r58probe host`)**:
   a second `try_init()` after a successful one gives `SECOND-INIT-IS-ERR=true`.
   The Rust equivalent of "only tear down what you own" is therefore stronger and
   simpler: **never install anything you do not own** — call `try_init()` (never
   `init()`, which is `try_init().expect(...)`, `src/util.rs:92-95`), and treat
   `Err` as *"a host already owns diagnostics"*, returning a `HostOwned` outcome
   rather than panicking, replacing, or tearing down.
2. `try_init()` also installs the `log` bridge, and can half-succeed. Source:
   `try_init` calls `dispatcher::set_global_default(...)` then, under the default
   `tracing-log` feature, `tracing_log::LogTracer::builder().with_max_level(...).init()`
   (`src/util.rs:62-77`). **Executed (probe `hostlog`)**, with a host that already
   owns the `log` logger: `TRY_INIT_IS_ERR=true`, yet the tracing subscriber *was*
   installed and rendered `TRACING-EVENT-AFTER-ERR`, while `log::info!` kept going
   to `HOST-LOGGER`. That is the correct host-safe outcome — the host's `log`
   logger was not stolen — but the `Err` must be classified, not treated as
   "nothing happened".
3. Embedders and tests use the **scoped** path: `SubscriberInitExt::set_default`
   returns a `dispatcher::DefaultGuard` and only does `let _ = tracing_log::LogTracer::init();`
   — error ignored (`src/util.rs:41-45`). Each `#[test]` gets its own.

**Reconfiguration within one process** is therefore not "replace the subscriber"
but "swap a layer behind a `reload::Handle`". **Executed (probe `r58probe
reload`)**: installed with `EnvFilter::new("warn")`, an `info!` before the swap
produced nothing; after `handle.modify(|f| *f = EnvFilter::new("debug"))`, both
the `info!` and a `debug!` rendered. rustup does exactly this, returning
`reload::Handle<EnvFilter, Registry>` from its `tracing_subscriber(...)`
constructor (`src/cli/log.rs:19-22`).

This solves the template's real two-phase problem: **logging must exist before
the configuration file is read** (so that a config parse failure can be logged at
all — R55's territory), but F274's ladder has a config-file tier. The composition
root installs early from flags and environment, then swaps the filter once the
config layer is resolved.

**Migration risk to record.** py's `configure_logging` can change the *format* on
reconfiguration; this design cannot. The writer and the event formatter are fixed
at `try_init` time, because putting the `fmt` layer behind `reload::Layer` costs
an `RwLock` read on **every event** for a capability no requirement asks for. The
console-vs-JSON decision is therefore an init-time decision in Rust and a
runtime-mutable one in Python. Nothing in F250–F263 needs the Python behaviour,
but a P03 implementer porting tests one-for-one will hit it.

**P2 and the standard — why TTY auto-selection here is conformant.** R7.3
**(MUST)** says "TTY state **MUST NOT** change the selected output *format*: `-o`
(default `table`) determines the format regardless of whether output is a terminal
or a pipe — a pipe only suppresses the niceties" (`cli-design-standard.md:389`).
That rule governs the **result stream** and the `-o` selector R66 owns. The log
stream is diagnostics on fd 2, which R7.1 places outside the result stream
entirely (`:381`). Auto-selecting the *diagnostic* render mode from
`std::io::stderr().is_terminal()` therefore does not touch R7.3's subject. This is
stated explicitly because it is the one place where F250 and the standard look
like they collide and do not.

**P5 — the resolution ladder (F274), which this item owns.** R4.4 requires one
unambiguous ladder (`:266`). The proposed total order, highest first:

| # | Input | Effect | Ground |
|---|---|---|---|
| 1 | `--debug` | `TRACE` **plus** internal detail (target, file, line, thread name) | R4.4 **(MUST)**: "`--debug` is equivalent to the maximum level plus internal detail"; "an explicit `--debug`, however, **MUST** override `--quiet`, since it is a deliberate request for diagnostics" (`:266`). Placing it above `--log-level` as well is **this template's choice**, extended from that sentence's reason: a bug-report switch that an inherited `RSLBP_LOG_LEVEL=error` could silence would not be one. py has no `--debug` at all, so py's ladder cannot answer this. |
| 2 | `--log-level <level>` | exact level | R4.4 **(MAY)**: "`--log-level <level>` **MAY** be offered as an explicit alternative" (`:266`). F254. |
| 3 | `RSLBP_LOG_LEVEL` | exact level | R5.4 **(MUST)** deterministic mapping `--log-level` → `RSLBP_LOG_LEVEL`, and its own ❌ example forbids inventing a different name (`:322,324`). The `RSLBP_` prefix is the one R56 r2 already uses for `RSLBP_TOKEN`. Bound by `clap`'s `env` feature, which R60's published decision has already selected. |
| 4 | `--quiet` / `-q` | `ERROR` | R4.4: "`--quiet`/`-q` suppresses progress and informational diagnostics on stderr only; it **MUST NOT** suppress the requested result on stdout" (`:266`). See the note below on why this is `ERROR` and not `WARN`. |
| 5 | `-v` × n | `INFO`, `DEBUG`, `TRACE` for n = 1, 2, ≥3 | R4.4 **(MUST)** repeatable; F273 `COMMON → REUSE`. |
| 6 | config file `[logging].level` | exact level | F274's config tier; the key's home is R59/R54's to confirm. |
| 7 | default | `WARN` | py's default (`core/logging.py:170` `level: int = logging.WARNING`). A CLI whose result is on stdout should say nothing on stderr when nothing is wrong. |

Two deliberate departures, both with ground:

- **`-q` → `ERROR`, not `WARN`.** ts maps `--quiet` to `'warn'`
  (`src/lib/logger.ts:36`); py maps it to `logging.ERROR` (`cli/context.py:203`).
  Because rung 7 is already `WARN`, ts's mapping would make `-q` a **no-op** at
  the default. py's mapping keeps the ladder monotonic, which is what R4.4's
  "define one ladder" requires. Agreeing with py here.
- **`--log-format <auto|console|json>` and `RSLBP_LOG_FORMAT` exist.** py's CLI has
  no such flag (it has `PLBP_LOG_FORMAT` for the *file* sink only, `cli/context.py:231`).
  R5.4's curated env subset explicitly includes "output format" (`:322`), and
  `--log-format` → `RSLBP_LOG_FORMAT` is the deterministic mapping. `auto` resolves
  to `console` when `std::io::stderr().is_terminal()`, else `json`. The rejected
  alternative — also forcing `json` whenever R66's machine result format is active —
  is recorded and not adopted: R67's error envelope is already JSON on stderr under
  machine mode regardless of this setting, so a developer piping stdout to `jq`
  from a terminal keeps readable diagnostics without losing a parseable envelope.

**P7 — one engine, two profiles (F263), and it holds either way R69 lands.** The
answer is neither "two layer configurations sharing one dispatcher" nor "two
independently initialised subscribers" as the question frames it, because **one
process runs one binary**: R69's accepted value gives the web surface its own
`[[bin]] name = "<app>-serve"` with `required-features = ["web"]`. So there is one
subscriber per process, built from one shared builder in the root package, with a
`Profile` value selecting policy.

**On the two binary names.** `rslbp` is settled: R49's published
`build-tool-output-shape` fixes `[[bin]] … name = rslbp`. The serve binary's name
is **not** R58's to settle — R69's accepted value writes it as
`[[bin]] name = "<app>-serve"`, and `rslbp-serve` below is that template filled in
with R49's `<app>`, written out for readability rather than decided here. If R69
or R49 spells it differently, only the string changes; nothing in this design
depends on it.

| | `rslbp` (CLI profile) | `<app>-serve`, i.e. `rslbp-serve` (service profile) |
|---|---|---|
| Format | `auto` → console on a TTY stderr, JSON otherwise | JSON always; no TTY sniff (structured output is the contract, per py `web/logging.py:20-26`) |
| Level source | the seven-rung ladder above | environment only, 12-factor; **the variable names are R77's** |
| Default level | `WARN` | `INFO` |
| Colour | R65's resolved `anstream::ColorChoice`, passed to `.with_ansi(..)` | never |
| Extra layers | none | axum/`tower-http` request spans (R75's), OTel layer under `otel` (R78's) |
| File sink | R59's | none |

If R69 had landed "no web surface", the CLI profile is the whole answer and
nothing above changes. The design does not assume a web surface exists.

**R02's crate edges (accepted revision 1, unpublished).** Proposed placement:

| Package | May depend on | Must not |
|---|---|---|
| `rs-launch-blueprint` (root, composition root, `[[bin]] rslbp`, `[[bin]] rslbp-serve`) | `tracing` (defaults: `std`, `attributes`), **`tracing-subscriber`** — the only package that may name it — `serde_json` | — |
| `rs-launch-blueprint-core` (`crates/core/`) | `tracing` `default-features = false, features = ["std"]` | any subscriber, any formatter, any writer |
| `rs-launch-blueprint-cli` (`crates/cli/`) | `tracing` (facade only) | `tracing-subscriber` |
| `rs-launch-blueprint-web` (`crates/web/`) | `tracing` (facade only; axum's default `tracing` feature already emits spans into it, per R69's accepted value) | `tracing-subscriber` |

This is enforceable with the mechanisms R02 already chose: `cargo deny --all-features check bans`
with `[bans] deny[].wrappers`, and `crates/core`'s external-dependency allow-list
in `tests/workspace_edges.rs`.

**Note on R69's paths.** The registry row for `web-extra-surface` quoted verbatim
under `### Parameters` is revision 9's text and still says `src/web/`. R69
**revision 10** (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`,
owner-accepted, unpublished) moves that tree to the optional member `crates/web`,
with `web = ["dep:rs-launch-blueprint-web"]` and later layers in `crates/web/src/`.
This design uses revision 10's paths throughout, and R69's republication of the
registry row is named as a re-verify trigger. No `CONFLICT:` is raised, because
nothing in this recommendation needs R69's value to be different.

**Executed — measured cost of the crate-edge split.** `cargo tree -e normal`,
deduplicated, 2026-09-18:

| Manifest | Crates in the normal dependency graph (excluding the package itself) | Clean debug build |
|---|---|---|
| `tracing` `default-features = false, features = ["std"]` (the `crates/core` line) | **4** | — |
| `tracing` default features (`std` + `attributes`) | **9** (5 of them build-time proc-macro: `proc-macro2`, `quote`, `syn`, `unicode-ident`, `tracing-attributes`) | 9.00 s |
| `tracing` + `tracing-subscriber` (defaults + `env-filter` + `json`) + `serde_json` (the root-package line as probed) | **28** | 16.16 s |
| the same without `env-filter` and without `json` | **22** | — |

So a subscriber costs the *composition root* about 19 crates and the *core
library* zero. This is the concrete reason the edge rule matters, and it matches
cargo's own manifest exactly.

**R05 r2 (accepted, unpublished) — no runtime in the default tree.** The 28-crate
root tree above contains no `tokio`, no `async-std`, no executor of any kind;
`tracing` and `tracing-subscriber` have no async-runtime coupling in the feature
set selected. Verified by the same `cargo tree` output.

**R56 r2 (accepted, unpublished) — defence in depth for P3.** Key-based redaction
is the *last* line, not the first. **Executed (probe `r58probe secrecy`)**, a
`secrecy::SecretString` cannot be printed even when a call site deliberately
formats it:

```
2026-09-18T22:10:45.027466Z  INFO r58probe: secrecy debug secret_value=SecretBox<str>([REDACTED]) plain="sk_live_TOPSECRET"
```

The proposed policy is therefore three-layered: (1) a secret's *type* refuses to
render (R56's `secrecy` 0.10.3); (2) the formatter masks by key name for anything
that is not so typed (F252's vocabulary); (3) a regression test asserts both.
R61 r1's `IsTerminal` gating and R62 r2's "post-result failure on stderr" are
consistent with this design and need nothing from it: the pipeline uses the same
`std::io::IsTerminal` primitive R61 and R65 already use, and R62's failure notice
is an ordinary `tracing::warn!` on the same stderr stream.

**ANSI safety, and why the version floor is what it is.** RUSTSEC-2025-0055
(`tracing-subscriber`, CVE-2025-58160, "Logging user input may result in poisoning
logs with ANSI escape sequences", **Patched >=0.3.20**, issued 2025-09-02) is the
reason the recommended floor is not simply "0.3". **Executed (probe `r58probe
ansi`)**, 0.3.23 escapes control bytes in field values on the human profile —
the rendered field was `untrusted="\u{1b}[31mRED\u{1b}[0m\u{7}"`, with the escape
and bell bytes printed in Rust escape notation rather than emitted raw;
**executed (probe `r58probe ansi-redact`)**, the redacting wrapper preserves that
escaping; and **executed (probe `json2 custom-ansi`)**, the owned JSON formatter
inherits JSON's own control-character escaping, emitting
`"untrusted":"\u001b[31mRED\u001b[0m\u0007"` (the six-character JSON escape
`\u001b`, not a raw byte). The owned formatter therefore does
not reopen the advisory's hole.

**Reference-architecture reconciliation (owner decision 11, STANDING INPUT).**
Rows this item touches, from `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md`:

| Row | The document says | This item |
|---|---|---|
| C10 Logs/traces (`:68`) | "**tracing + tracing-subscriber (JSON)** (+ tracing-stackdriver) 0.1 / 0.3" | **Agree** on `tracing` + `tracing-subscriber`, at exact pins 0.1.44 / 0.3.23 rather than the document's minor-level `0.1`/`0.3`. |
| Reference `Cargo.toml` (`:178`) | `tracing = "0.1"` | **Agree.** |
| Reference `Cargo.toml` (`:179`) | `tracing-subscriber = { version = "0.3", features = ["env-filter","json"] }` | **Agree on `env-filter`; differ on `json`.** Measured ground: the `json` feature's event formatter cannot redact event fields (`src/fmt/format/json.rs:252,268-270`, executed probe `json2 spanonly`), so the template owns the structured formatter and the feature adds `tracing-serde` for nothing. |
| C10 stream (`:111`) | "Emit **JSON logs to stdout** with `tracing-subscriber`'s JSON formatter" | **Differ, on org-locked ground.** R7.1 **(MUST)**: stdout "carries the command's *requested result*"; stderr "carries everything else: diagnostics …" (`cli-design-standard.md:381`). R67's accepted envelope also requires "stdout stays byte-empty on the error path". Cost of differing: none — Cloud Run and every container runtime capture both file descriptors. |
| C10 GCP shaping (`:111`, `:180`) | `tracing-stackdriver = "0.10"`, severity mapping, `logging.googleapis.com/trace` from `X-Cloud-Trace-Context` | **Not adopted; recorded as a layer slot.** `tracing-stackdriver` 0.10.0 last published 2024-03-11 and declares no `rust-version`; and the template is not GCP-specific. The owned `FormatEvent` is the exact seam where a deployment could add severity mapping, so nothing is foreclosed. Trace-header correlation is R78's. |
| C10 error reporting (`:69`) | `sentry` + `sentry-tower` | **Hand-off, not decided.** No P02 item owns error reporting; recorded for owner scoping, per decision 11's "Rows with no P02 item … are NOT decided". |
| Layout (`:236`, `:241`, `:324`) | `main.rs` bootstraps tracing; `telemetry.rs` holds "JSON logs + trace correlation"; `telemetry::init()` first in `main` | **Agree.** The module is `src/telemetry.rs` in the root package — which is where R02's composition root already is — and it is called before anything that can log, as py does (`web/logging.py:35` "Called at the top of `create_app()` so logging is configured before any code that can log runs"). |

Tally over the seven rows: **5 agree, 2 differ** (the `json` feature; the stdout
stream), with one further row — Sentry error reporting — recorded as a hand-off
rather than an agree/differ, because no P02 item owns it.

**Minimal realistic example (proposed).** `src/telemetry.rs` in the root package:
a `Profile` enum (`Cli { format, level, ansi }`, `Service { level }`), one
`pub fn init(profile: Profile) -> Init` returning
`enum Init { Installed(Handles), HostOwned }` where
`Handles { level: reload::Handle<EnvFilter, Registry> }`; a `redact` module with
`const SENSITIVE: [&str; 8]`, `const REDACTED: &str`, `fn is_sensitive(&str) -> bool`,
`struct HumanFields(DefaultFields)` for the human profile and
`struct JsonFields` / `struct JsonEvent` for the structured one, with an explicit
`// R78: trace_id / span_id are serialised here` slot in `JsonEvent::format_event`
and a `// R59: an additional Layer with its own writer and filter attaches here`
slot in `init`. `crates/core`, `crates/cli` and `crates/web` contain no part of
this; they call `tracing::info!` and `#[tracing::instrument]` only.

**Executable acceptance check** — see `### Validation strategy` for the commands;
the probe results quoted above are the executed subset.

No `BASELINE-REVIEW:` finding is raised by this item. F304's reclassification was
already made on 2026-09-04 (`docs/port/BASELINE-REVIEW.md:330`) and this decision
implements it rather than challenging it.

### Recommendation

Adopt **`tracing` 0.1.44 as the sole diagnostic facade in every package, with
`tracing-subscriber` 0.3.23 (`features = ["env-filter"]` over its default
`smallvec, fmt, ansi, tracing-log, std`) declared only on the root package
`rs-launch-blueprint`, `tracing-log` 0.2.0 reached through that default feature
rather than declared directly, and a template-owned `src/telemetry.rs` supplying
the redacting `FormatFields` for the human profile and the redacting
`FormatEvent` + `FormatFields` pair for the structured profile** — one
`telemetry::init(Profile)` in the composition root that calls `try_init()`, never
`init()`, returns a `reload::Handle<EnvFilter, Registry>` for the config-file
tier of the level ladder, writes every byte to stderr, and leaves an explicit
layer slot for R78's OTel layer and a sink slot for R59's file sink.

### Members

#### tracing

##### Landscape

The facade bin of the *established industry standard* row: the call-site API that
every package in the workspace names, and the only logging crate the library core
is permitted to depend on. Its competitor in that bin is `log` 0.4.34; its
competitor in the structured-record bin is `slog` 2.8.2. `tracing` is the more
depended-upon of the two facades: **42,556** reverse dependencies against `log`'s
**30,655** (`GET https://crates.io/api/v1/crates/tracing/reverse_dependencies?per_page=1`
and the same for `log`, field `meta.total`, retrieved 2026-09-18).

##### Principles and implementation

`tracing` supplies P1 (typed named fields on `Event` and `Span`), the span parent
chain P4 needs, and the `Dispatch` indirection P6 needs. It supplies **no**
rendering, no filtering beyond compile-time `max_level_*` features, and no
process-global installation beyond `tracing::subscriber::set_global_default`. That
separation is what makes it safe in a library crate: `crates/core` gains the
ability to emit and gains no opinion about where the bytes go.

The feature line matters. `default = ["std", "attributes"]`
(`tracing-0.1.44/Cargo.toml:67-70`). `attributes` pulls the `tracing-attributes`
proc-macro and, with it, `proc-macro2`, `quote`, `syn` and `unicode-ident`.
**Executed**: `default-features = false, features = ["std"]` resolves to **4**
dependency crates; the default set resolves to **9**. `rust-lang/cargo` draws the
same line for the same reason, taking `default-features = false, features = ["std"]`
at workspace level and adding `attributes` only on the binary
(`rust-lang/cargo:Cargo.toml:118,226`).

##### Dominant choice

`tracing` 0.1.44, published 2025-12-18
(`GET https://crates.io/api/v1/crates/tracing/versions`, newest with `yanked: false`:
`num` `0.1.44`, `created_at` `2025-12-18T14:26:12.360139Z`, retrieved 2026-09-18).
Note that `0.1.42` is **yanked**; a naive "latest" pin would land on a yanked
version's number.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence | 90-day downloads | All-time |
|---|---|---|---|---|---|
| `tracing` 0.1.44 | 2025-12-18 | 1.65.0 | MIT | 193,980,357 | 856,568,644 |
| `log` 0.4.34 | 2026-08-22 | 1.71.0 | MIT OR Apache-2.0 | 284,763,482 | 1,260,780,310 |
| `slog` 2.8.2 | 2025-10-11 | 1.61 | MPL-2.0 OR MIT OR Apache-2.0 | 8,276,414 | 76,905,496 |

All from `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `/versions`, retrieved 2026-09-18.

`log` passes every gate and is not excluded — it is **kept, in a different role**:
it stays in the tree as the *source* of records from dependencies (R05 r2's `ureq`
and anything else), bridged by `tracing-log`. It is rejected only as the
template's own call-site API, on P3 and P4, because a `log::Record`'s payload is a
formatted string with no keys to redact and no span to correlate.

`slog` is rejected on P4 and on R02's crate edge: its `Logger` is a value threaded
through call sites, which would put a logging type in `crates/core`'s public API
and make R01's `ProjectsPort` signature carry it.

##### Excluded by gate

- **`fastrace` 0.7.19** — declared `rust-version` **1.91.0** against a floor of
  **1.96**: it passes gate 2 today, and it is recorded as the one candidate whose
  floor sits within three minors of the policy's moving target. Its real exclusion
  is **fit**: it is a tracing-only library with no console/JSON logging profile, no
  redaction seam and no `log` bridge, so it answers a different question.
  (`GET https://crates.io/api/v1/crates/fastrace/versions`, retrieved 2026-09-18.)
- **`logforth` 0.30.1** — not excluded by a gate (Apache-2.0; `rust-version`
  1.89.0; no advisory). Excluded on **fit and maturity**: 238 stars, 270,383
  90-day downloads, and it is a *`log`-architecture* appender framework, so it
  inherits `log`'s P3/P4 failure.
- Nothing is excluded on **gate 1 (licence)**: `inapplicable — owner ruling
  2026-09-12 (Q7.B)`. Every crate recommended here nonetheless carries MIT or a
  dual expression, recorded as observed fact from the registry.

##### Up-and-comers

`fastrace` (1,134 stars, pushed 2026-07-31, 11 open issues) and `logforth` (238
stars, pushed 2026-08-26, 4 open issues), both from the `fast` org, both
Apache-2.0, both actively maintained
(`GET https://api.github.com/repos/fast/fastrace`, `GET https://api.github.com/repos/fast/logforth`,
`GET https://api.github.com/search/issues?q=repo:fast/fastrace+is:issue+is:open`,
retrieved 2026-09-18). Worth re-checking at the next re-verify: `fastrace`'s pitch
is lower overhead than `tracing` for span-heavy workloads, which is not this
template's workload.

##### Fit for this template

Exact fit, and for a reason specific to this template's three-surface shape: the
facade is the *only* thing the library core needs, and `tracing` is designed so
that a library takes it and nothing else. Both source repositories' precedent
points the same way at the principle level — py's structlog call sites also emit
key/value events, not strings — and `tracing` is the Rust expression of that
principle. The 4-crate `["std"]` footprint is small enough that putting the facade
in `crates/core` costs nothing an auditor would object to.

##### Recommendation

`tracing = { version = "0.1.44", default-features = false, features = ["std"] }`
in `crates/core/Cargo.toml` and `crates/web/Cargo.toml`;
`tracing = "0.1.44"` (defaults, i.e. `std` + `attributes`) in the root package and
`crates/cli`. Pin at the patch level and let Cargo's caret range float within
0.1.x, matching `rust-lang/cargo`'s own `"0.1.44"`.

##### Ranked runner-up

`log` 0.4.34 as the call-site API, with `env_logger` 0.11.11 as the renderer.
Ranked second because it is the only alternative that every Rust developer already
knows and that costs about five crates in total. It loses on P3 (nothing to redact
by key), P4 (no span context for OTel), and P1. If the owner ever struck P3 and P4
from the requirement set, this is the stack that would win on cost.

##### Tradeoffs

Gained: a field model, spans, a maintained OTel bridge, and a `log` bridge that
brings dependencies' diagnostics into the same pipeline. Paid: 4 crates in
`crates/core`; a `0.1.x` version line that has never reached 1.0 (mitigated by
856,568,644 all-time downloads and the Tokio project's stewardship — a breaking
0.2 would be an ecosystem event, not a quiet bump); and a mental model
(spans/events/subscribers) that a contributor coming from `log` must learn.

##### Parameters

Contributes the facade half of `logging-pipeline-contract`. Consumes
`rust-edition = 2024` (the probe manifest declared `edition = "2024"` and
`rust-version = "1.96"` and resolved), `msrv-policy` (declared `rust_version`
1.65.0, far under the 1.96 floor that stable 1.98.0 minus two minors yields),
`target-os-matrix` (see gate 4 below), `license` (`inapplicable` per Q7.B).

##### Migration implications

py's `structlog.get_logger(__name__)` becomes `tracing::info!(field = value, "message")`
at the call site, with no logger object to obtain and nothing to inject. py's
`_shared_processors()` has **no** call-site analogue — everything it did moves into
the subscriber. ts has nothing to migrate: `createLogger`'s injected-writer shape
(`ts:src/lib/logger.ts:56`) disappears entirely, because the writer is now the
subscriber's, chosen once at the composition root.

##### Validation strategy

Proposed: `cargo tree -e normal -p rs-launch-blueprint-core` must show `tracing`,
`tracing-core`, `once_cell`, `pin-project-lite` and **not** `tracing-subscriber`,
`tracing-attributes`, `syn`, `serde` or `serde_json` — the assertion already
carried by R02's `tests/workspace_edges.rs` allow-list. **Executed** in the probe
for the equivalent manifest: the `["std"]` graph is exactly 4 crates.

##### Confidence & re-verify trigger

**High.** Re-verify when `tracing` publishes 0.2 or any 0.1.x that raises
`rust_version` above the then-current floor; when RustSec publishes any advisory
against `tracing` or `tracing-core`; when `rust-lang/cargo` moves off `tracing`;
or by 2027-03-18.

##### Sources

`GET https://crates.io/api/v1/crates/tracing` and `/versions` (retrieved 2026-09-18);
`GET https://crates.io/api/v1/crates/tracing/reverse_dependencies?per_page=1` (retrieved 2026-09-18);
`GET https://api.github.com/repos/tokio-rs/tracing` (retrieved 2026-09-18);
`GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+is:open` (retrieved 2026-09-18);
https://rustsec.org/packages/tracing.html and https://rustsec.org/advisories/RUSTSEC-2023-0078.html (retrieved 2026-09-18);
`tracing-0.1.44/Cargo.toml:64-86` in the local registry (read 2026-09-18);
https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml (retrieved 2026-09-18).

**Gates.** (1) licence `inapplicable — owner ruling 2026-09-12 (Q7.B)`; observed
value MIT. (2) MSRV: declared `rust_version` 1.65.0 ≤ floor 1.96 (stable 1.98.0
minus two minors); no dependency in the `["std"]` graph declares a higher floor —
the probe resolved and built under `rust-version = "1.96"`. (3) Advisories:
`https://rustsec.org/packages/tracing.html` lists exactly one, RUSTSEC-2023-0078
(type **INFO**, unsound, "Patched >=0.1.40", affected `>=0.1.38 <0.1.40`) —
**no open advisory** against 0.1.44. `unsafe` posture: 7 `unsafe` block/impl/fn
occurrences in `tracing-0.1.44/src`; the crate does **not** carry
`forbid(unsafe_code)`; `tracing-core-0.1.36` carries 30 such occurrences.
**Maintenance state: `at-risk`**, on the concrete signal measured under
`### Confidence & re-verify trigger` — 10 of the 10 most recently opened issues
carry no maintainer response and `pushed_at` is 2026-05-30. Not `dormant`: no
unpatched advisory, no maintainer notice, and it builds on current stable
(executed). The consequence for the recommendation is argued there, not assumed.
(4) CI: `tokio-rs/tracing` `.github/workflows/CI.yml:221-235` runs `cargo test` on
`ubuntu-latest` (stable, beta, nightly) plus `windows-latest` and `macos-latest` on
stable — both required runners covered, Windows also covered. (5) Default features
`["std","attributes"]`; **no async-runtime coupling** in any feature used here.
(6) Binary/compile cost: 9 crates and 9.00 s clean debug build for the default set,
4 crates for `["std"]` — **executed**.

#### tracing-subscriber

##### Landscape

The subscriber/renderer bin's dominant member: the crate that supplies
`Registry`, the `Layer` composition model, `EnvFilter`, `reload::Layer`, and the
`fmt` layer with its `FormatEvent`/`FormatFields` seams. Its competitors are the
`log`-architecture renderers (`env_logger` 0.11.11, `fern` 0.7.1, `log4rs` 1.4.0)
and the `slog` drain stack; none of them can subscribe to `tracing` events at all,
so the comparison is between architectures, already settled above.

##### Principles and implementation

This crate is where P2, P3, P5, P6 and P7 are all realised:

- **P2** — the `fmt` layer's formatter is chosen when the layer is built, so the
  console-vs-JSON decision is one `match` on the resolved format.
- **P3** — the `FormatFields`/`FormatEvent` seams; asymmetric between the human
  and JSON formatters, as established above with executed evidence.
- **P5** — `EnvFilter` turns a level (or a directive string) into per-target
  interest; `reload::Layer<EnvFilter, Registry>` makes the level swappable after
  the config file is read.
- **P6** — `SubscriberInitExt::try_init` (`src/util.rs:62-77`) and
  `set_default` (`:41-45`) are the two installation paths, one global and one
  scoped.
- **P7** — one builder, two `Profile` branches.

Feature selection, read from `tracing-subscriber-0.3.23/Cargo.toml:58-88`:
`default = ["smallvec", "fmt", "ansi", "tracing-log", "std"]`. Adding
`env-filter` pulls `matchers`, `once_cell`, `thread_local` and `regex-automata`.
**`json` is deliberately not enabled** (it pulls `tracing-serde`, `serde`,
`serde_json` for a formatter the template replaces). **`local-time` is
deliberately never enabled**: the crate's own documentation says of `LocalTime`
that it "determines the offset every time it formats a message, **which may be
unsound or fail**" (`src/fmt/time/time_crate.rs`, doc comment on `OffsetTime`).
The template stamps UTC, which is also what py does
(`core/logging.py:161` `TimeStamper(fmt="iso", utc=True)`).

##### Dominant choice

`tracing-subscriber` 0.3.23, published 2026-03-13
(`GET https://crates.io/api/v1/crates/tracing-subscriber/versions`, newest with
`yanked: false`: `num` `0.3.23`, `created_at` `2026-03-13T10:04:15.571048Z`,
retrieved 2026-09-18). `0.3.21` is **yanked**.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence | 90-day downloads | All-time | Reverse deps |
|---|---|---|---|---|---|---|
| `tracing-subscriber` 0.3.23 | 2026-03-13 | 1.65.0 | MIT | 144,384,705 | 612,303,204 | 18,766 |
| `env_logger` 0.11.11 | 2026-06-25 | 1.71 | MIT OR Apache-2.0 | 78,311,204 | 560,618,701 | 11,935 |
| `fern` 0.7.1 | 2024-12-15 | 1.60 | MIT | 7,884,583 | 47,726,795 | 469 |
| `log4rs` 1.4.0 | 2025-09-05 | 1.75 | MIT OR Apache-2.0 | 1,860,017 | 23,075,569 | 398 |

All from `GET https://crates.io/api/v1/crates/<name>` and `/versions`, retrieved
2026-09-18; reverse-dependency totals from `/reverse_dependencies?per_page=1`
field `meta.total`, same date.

##### Excluded by gate

None of the four is excluded by a fitness gate. Licence gate 1 is `inapplicable`
(Q7.B). All four MSRVs are under the 1.96 floor. None carries an open advisory
(`https://rustsec.org/packages/env_logger.html`, `.../fern.html` and
`.../log4rs.html` all return the RustSec site's "Page not found", i.e. **no
advisories filed**, retrieved 2026-09-18). All four build on Linux and macOS.

They are excluded on **architecture and fit**, which is a stronger reason and is
stated as such rather than dressed as a gate: `env_logger`, `fern` and `log4rs`
are `log::Log` implementations. They cannot receive a `tracing::Event`, cannot see
a field key, and cannot see a span — so under any of them P3 becomes a call-site
discipline and P4 becomes impossible. `fern` additionally last shipped 2024-12-15
and was last pushed the same day (`GET https://api.github.com/repos/daboross/fern`,
`pushed_at` `2024-12-15`, retrieved 2026-09-18): **stable-quiet**, not at-risk —
no advisory, no broken build, no maintainer notice — but 21 months without a
push is a signal worth recording.

##### Up-and-comers

`tracing-bunyan-formatter` 0.3.10 (112 stars, last published 2024-11-26, last
pushed 2024-11-26, **stable-quiet**) and `tracing-tree` 0.4.1 (156 stars, pushed
2026-07-21, **active**) are the maintained third-party formatter layers. Both are
*alternatives to writing a formatter*, and both were considered for the
structured profile and rejected: neither redacts by key, so adopting either would
leave P3 unsolved and still require the owned `FormatEvent`. `tracing-tree` is
adopted by `rust-analyzer` and `uv` for developer-facing hierarchical output —
worth re-checking if a `--log-format tree` is ever asked for.

##### Fit for this template

Exact, with the one qualification this whole report turns on: the *stock JSON
formatter* does not fit, and the crate's `FormatEvent`/`FormatFields` traits are
the sanctioned way to replace it. That is not a workaround — it is the extension
point the maintainers document, and `rust-lang/rustup` uses it in production for
the same reason (a custom human format), `src/cli/log.rs:78-97`.

##### Recommendation

`tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }` on the
root package `rs-launch-blueprint` **only**, keeping default features
(`smallvec`, `fmt`, `ansi`, `tracing-log`, `std`). `ansi` is kept because R65's
published `anstream::ColorChoice` resolution is passed into `.with_ansi(bool)`
rather than left to the formatter's own guess. `json` off; `local-time` off.
Floor the version at **0.3.20** in prose (RUSTSEC-2025-0055's patched floor) and
pin at 0.3.23.

##### Ranked runner-up

`tracing-bunyan-formatter` 0.3.10 as the structured formatter, with
`tracing-subscriber` still supplying `Registry`, `EnvFilter` and the human layer.
Ranked second because it removes roughly 120 lines of template-owned formatter
code and gives a documented JSON schema (bunyan). Rejected because it still cannot
redact by key, so the owned `FormatEvent` would have to exist anyway, and because
at 112 stars, 961,731 90-day downloads and no release since 2024-11-26 it is a
thinner dependency than the code it would replace.

##### Tradeoffs

Gained: `Registry` span storage, `EnvFilter`'s directive language, hot-swappable
filtering, the `log` bridge, and a formatter seam. Paid: **19 crates** and about
**7 seconds** of clean debug build at the composition root (measured: 28-crate,
16.16 s root tree against the 9-crate, 9.00 s facade-only tree); `env-filter`'s
`regex-automata` is the single largest compile-time line item in that delta; and
the template now owns roughly 120 lines of formatter code it must test, which is
the honest cost of P3.

##### Parameters

Contributes the subscriber half of `logging-pipeline-contract`. Consumes
`msrv-policy` (declared 1.65.0; the 28-crate probe tree resolved under
`rust-version = "1.96"` and built), `rust-edition = 2024`, `target-os-matrix`,
`license` (`inapplicable`, Q7.B), and `web-extra-surface` — the service profile is
only reachable through R69's `web` feature and its `[[bin]] name = "<app>-serve"`.

##### Migration implications

py's `structlog.configure(...)` plus `logging.StreamHandler(sys.stderr)` plus
`ProcessorFormatter` collapse into one `Registry::default().with(filter).with(fmt_layer)`
expression in `src/telemetry.rs`. py's `foreign_pre_chain` — which exists so that
records from *other* libraries get the shared processors — has a direct analogue:
`tracing-log`'s `LogTracer`, which is installed automatically (see the next
member). ts has nothing to migrate.

##### Validation strategy

Proposed: `cargo tree -e normal -p rs-launch-blueprint` asserted against a pinned
crate count; `cargo deny --all-features check bans` with a `wrappers` rule proving
no other member names `tracing-subscriber`. Executed here:
`.json().fmt_fields(..)` under-redacts (probe `json2 spanonly`) and panics on
non-JSON span fields (probe `r58probe json-fmtfields`); a template-owned
`FormatEvent` + `FormatFields` redacts both (probe `json2 custom`); `reload`
swaps the filter after init (probe `r58probe reload`); a second `try_init` is
`Err` (probe `r58probe host`).

##### Confidence & re-verify trigger

**High** on the crate; **high, executed** on the formatter asymmetry. Re-verify
when `tracing-subscriber` publishes 0.4 or changes `Format<Json>`'s handling of
`N: FormatFields` (the asymmetry this design routes around); when a new RustSec
advisory is filed against it; when `rust-lang/rustup` moves off the custom
`FormatEvent` pattern; at the next `msrv-policy` floor advance past 1.96; or by
2027-03-18.

##### Sources

`GET https://crates.io/api/v1/crates/tracing-subscriber` and `/versions` (retrieved 2026-09-18);
`/reverse_dependencies?per_page=1` (retrieved 2026-09-18);
`GET https://api.github.com/repos/tokio-rs/tracing` — `stargazers_count` 6877,
`archived` false, `pushed_at` `2026-05-30` (retrieved 2026-09-18);
`GET https://api.github.com/search/issues?q=repo:tokio-rs/tracing+is:issue+is:open`
— `total_count` **628** (retrieved 2026-09-18);
https://rustsec.org/packages/tracing-subscriber.html and
https://rustsec.org/advisories/RUSTSEC-2025-0055.html (retrieved 2026-09-18);
`tracing-subscriber-0.3.23/src/fmt/format/json.rs:175-205,252,268-270`,
`src/util.rs:41-95`, `src/fmt/time/time_crate.rs`, `Cargo.toml:58-88` in the local
registry (read 2026-09-18);
https://raw.githubusercontent.com/rust-lang/rustup/master/src/cli/log.rs (retrieved 2026-09-18);
`tokio-rs/tracing` `.github/workflows/CI.yml` (retrieved 2026-09-18).

**Gates.** (1) `inapplicable — owner ruling 2026-09-12 (Q7.B)`; observed MIT.
(2) MSRV 1.65.0 ≤ 1.96; the full 28-crate probe tree resolved and built under a
declared `rust-version = "1.96"` on rustc 1.98.0. (3) **One advisory exists and is
closed for this version**: RUSTSEC-2025-0055 / CVE-2025-58160, format-injection,
issued 2025-09-02, "Patched >=0.3.20" — 0.3.23 is clear, and the escaping was
verified executed. `unsafe` posture: 25 `unsafe` block/impl/fn occurrences in
`tracing-subscriber-0.3.23/src`; no `forbid(unsafe_code)`.
**Maintenance state: `at-risk`**, same repository and same measured signal as
`tracing`'s, plus 6.2 months since 0.3.23 — the rubric's "no release in 6 months"
investigation trigger, investigated and reported rather than waved through.
(4) CI covers
`ubuntu-latest`, `macos-latest` and `windows-latest` (`CI.yml:221-235`).
(5) Default features `smallvec, fmt, ansi, tracing-log, std`; **no async-runtime
coupling** — nothing in the selected feature set pulls `tokio`. (6) Compile cost:
+19 crates, +7.2 s clean debug over the facade-only tree — **executed**.

#### tracing-log

##### Landscape

The bridge bin — one crate, no competitor. It converts `log::Record`s emitted by
*dependencies* into `tracing` events, so that a pipeline built on `tracing` does
not go blind to the large part of the ecosystem that still emits through `log`
(30,655 reverse dependencies). The alternative to using it is not another crate;
it is accepting that dependency diagnostics are invisible.

##### Principles and implementation

This is the Rust analogue of py's `foreign_pre_chain` — the mechanism by which
records that did not originate in the template's own call sites still get the
shared pipeline's treatment (`py:core/logging.py:213` `foreign_pre_chain=shared`).

The load-bearing and easily-missed fact: **it is installed for you**, and trying
to install it yourself breaks the process at start. `SubscriberInitExt::try_init`
does `dispatcher::set_global_default(...)` and then, under the default
`tracing-log` feature, `tracing_log::LogTracer::builder().with_max_level(tracing_core::LevelFilter::current().as_log()).init()`
(`tracing-subscriber-0.3.23/src/util.rs:62-77`). **Executed (probe
`r58probe logbridge-off`)**: with no explicit bridge call at all, a `log::info!`
rendered through the `fmt` layer —

```
2026-09-18T22:10:45.007395Z  INFO r58probe: LOG-CRATE-RECORD
2026-09-18T22:10:45.007444Z  INFO r58probe: TRACING-RECORD
```

**Executed (probe `r58probe logbridge-on`)**: calling `tracing_log::LogTracer::init()`
first and then `.init()` **panicked** — `failed to set global default subscriber:
SetLoggerError(())` at `src/util.rs:94`. The template must therefore *not* call
`LogTracer::init()` and must use `try_init()` rather than `init()`.

Why this matters concretely here: R05 r2's accepted HTTP client is `ureq` 3.4.2,
and the `log` facade is how crates of that kind report retries, redirects and TLS
detail. Without the bridge, `-vv` on a network command would show nothing from the
transport.

##### Dominant choice

`tracing-log` 0.2.0, published 2023-10-25
(`GET https://crates.io/api/v1/crates/tracing-log/versions`, newest with
`yanked: false`, retrieved 2026-09-18). Reached as
`tracing-subscriber`'s default `tracing-log` feature
(`tracing-subscriber-0.3.23/Cargo.toml:64-70`), **not** declared directly in any
template manifest.

##### Qualified shortlist

| Crate | Newest non-yanked | `rust_version` | Licence | 90-day downloads | All-time |
|---|---|---|---|---|---|
| `tracing-log` 0.2.0 | 2023-10-25 | 1.56.0 | MIT | 125,228,387 | 553,140,372 |

There is no second candidate: the shortlist is one crate because the job — adapt
`log::Log` to `tracing::Dispatch` — is done by exactly one maintained crate, in
the same repository as the subscriber that depends on it. The *alternative* is
architectural (do not bridge), and it is rejected: it would make `ureq`'s and every
other dependency's diagnostics unreachable.

##### Excluded by gate

None. The one thing that looks like a gate failure and is not: **no release since
2023-10-25**, which the prompt's rubric calls "a trigger to investigate, never the
verdict". Investigated: the crate lives in `tokio-rs/tracing`, whose repository was
pushed `2026-05-30`; its `Cargo.toml` declares `[badges.maintenance] status = "actively-maintained"`
(`tracing-log-0.2.0/Cargo.toml:82-83`); it has no open advisory; it builds on
current stable (**executed** — it is in the probe's 28-crate tree); and its API
surface is a stable adapter with nothing to change. Verdict **stable-quiet**, not
dormant: the rubric's `dormant` requires an unpatched advisory, a broken build on
current stable, or a maintainer's own notice, and none of the three is present.

##### Up-and-comers

None. No newer crate competes for this job; `logforth` and `fastrace` solve
adjacent problems in the other direction (they consume `log`, they do not bridge
it into `tracing`).

##### Fit for this template

Exact, and its fit is *conditional on R05's accepted execution model*: because the
default tree is synchronous and reaches the network through `ureq`, the `log`
facade is the only channel the transport has. If the template were async on
`tokio`, the same argument would hold through `hyper` and `rustls`.

##### Recommendation

Do **not** add `tracing-log` to any `Cargo.toml`. Keep `tracing-subscriber`'s
default `tracing-log` feature on, call `SubscriberInitExt::try_init()`, and never
call `LogTracer::init()` from template code. Document the reason next to the call,
because the failure mode is a panic at process start and the cause is invisible.

##### Ranked runner-up

Declaring `tracing-log = "0.2.0"` directly and calling
`LogTracer::builder().with_max_level(..).init()` explicitly before building the
subscriber, as `rust-lang/rustup` does (`Cargo.toml:99`). Ranked second because it
makes the bridge visible in the manifest — a real readability gain — at the cost
of a second place where the double-init panic can be reintroduced. If P03 finds it
needs the max-level hint set differently, this is the shape to move to.

##### Tradeoffs

Gained: dependency diagnostics, with the shared pipeline's level, format and
redaction applied to them. Paid: 2 crates (`tracing-log`, `log`) already in the
default tree; a per-record conversion cost on `log` records only (the max-level
hint set by `try_init` means disabled records are rejected by `log`'s own static
max-level check before conversion); and the double-init hazard above.

##### Parameters

Contributes the foreign-record clause of `logging-pipeline-contract`. Consumes
`msrv-policy` (declared 1.56.0), `rust-edition`, `target-os-matrix`, `license`
(`inapplicable`).

##### Migration implications

Direct analogue of py's `foreign_pre_chain=shared` (`core/logging.py:213`) and of
py's uvicorn adoption (`web/logging.py:60-67`, which clears uvicorn's handlers and
sets `propagate = True`). In Rust the web-side analogue is different in kind: axum
emits `tracing` spans natively via its default `tracing` feature — already in
R69's accepted value — so there is nothing to re-parent. F327 (R75's row) covers
the access-log side.

##### Validation strategy

Proposed: an integration test that sets `RSLBP_LOG_LEVEL=debug`, runs a command
which performs an HTTP call against a local fixture, and asserts that at least one
stderr line carries the transport crate's target. Executed here: `log::info!`
rendered through the `fmt` layer with no explicit bridge call (probe
`logbridge-off`), and an explicit `LogTracer::init()` followed by `.init()`
panicked (probe `logbridge-on`).

##### Confidence & re-verify trigger

**High.** Re-verify when `tracing-subscriber` changes its `tracing-log` default
feature or the `try_init` sequence in `src/util.rs`; when `tracing-log` publishes
0.3; when R05 republishes with a different HTTP client or an async model; or by
2027-03-18.

##### Sources

`GET https://crates.io/api/v1/crates/tracing-log` and `/versions` (retrieved 2026-09-18);
`tracing-log-0.2.0/Cargo.toml:70-83` and `tracing-subscriber-0.3.23/src/util.rs:41-95`,
`Cargo.toml:64-70` in the local registry (read 2026-09-18);
`GET https://api.github.com/repos/tokio-rs/tracing` (retrieved 2026-09-18);
https://rustsec.org/packages/tracing-log.html — RustSec returns "Page not found",
i.e. no advisories filed (retrieved 2026-09-18);
https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml (retrieved 2026-09-18).

**Gates.** (1) `inapplicable — owner ruling 2026-09-12 (Q7.B)`; observed MIT.
(2) MSRV 1.56.0 ≤ 1.96. (3) No advisory; `unsafe` posture: **1** occurrence in
`tracing-log-0.2.0/src`; no `forbid(unsafe_code)`. **Maintenance state:
`stable-quiet`** — it shares `tokio-rs/tracing`'s `at-risk` responsiveness signal,
but its own API is a finished adapter with a maintainer-declared
`[badges.maintenance] status = "actively-maintained"`, so the stricter verdict
would over-read a crate that has nothing left to change. (4) Same CI as
`tracing-subscriber` — `ubuntu-latest`, `macos-latest`, `windows-latest`.
(5) Default features `log-tracer`, `std`; no async-runtime coupling; the
`interest-cache` feature (which would pull `lru` and `ahash`) is **off**.
(6) Compile cost: it and `log` are 2 of the root tree's 28 crates; no measurable
separate build time — **executed** as part of the 16.16 s root build.

#### Template-owned telemetry module (redaction and the two profile formatters)

##### Landscape

This member is a **pattern, not a crate**, so the crate figure table is
`inapplicable`: there is no crates.io entry, no GitHub repository, no download
count and no advisory page for code that lives in this template's own `src/`. The
prompt's figure table is answered with the pattern fields instead, and the reason
crate figures do not apply is stated at each one below.

The landscape it sits in is the set of ways a `tracing` pipeline can apply a
field-level policy: (a) a custom `FormatFields`; (b) a custom `FormatEvent`;
(c) a third-party formatter crate (`tracing-bunyan-formatter`, `tracing-tree`,
`tracing-stackdriver`); (d) redaction at the value's *type*
(`secrecy::SecretString`); (e) post-hoc filtering in the writer. Rust offers no
sixth option, because `Event` is immutable and `RecordFields` is sealed — both
established by compiler errors quoted above.

##### Principles and implementation

The module realises P3 in full and supplies the seam for P4. Its shape:

- `src/telemetry.rs` in the root package: `pub enum Profile { Cli { format, level, ansi }, Service { level } }`;
  `pub enum Init { Installed(Handles), HostOwned }`;
  `pub struct Handles { pub level: reload::Handle<EnvFilter, Registry> }`;
  `pub fn init(profile: Profile) -> Init`.
- a `redact` submodule: `const SENSITIVE: [&str; 8]` holding F252's vocabulary
  verbatim — `token`, `password`, `secret`, `authorization`, `api_key`, `apikey`,
  `credential`, `cookie`; `const REDACTED: &str = "[REDACTED]"`;
  `fn is_sensitive(name: &str) -> bool` doing an ASCII-lowercased substring match;
  `struct HumanFields(DefaultFields)` implementing `FormatFields` for the human
  profile; `struct JsonFields` implementing `FormatFields` for span fields; and
  `struct JsonEvent` implementing `FormatEvent` for the whole structured line.

`HumanFields` wraps `DefaultFields`'s visitor (`DefaultFields` implements
`MakeVisitor`, so this is roughly 25 lines). `JsonFields` and `JsonEvent` are
template-owned end to end (roughly 95 lines together) because, as established,
`JsonFields` cannot be wrapped and the stock `Format<Json>` bypasses
`N: FormatFields` for event fields.

`JsonEvent::format_event` is also the declared hook point for two not-yet-researched
items, left as slots rather than decisions:

- **R78 (OpenTelemetry).** A `// trace_id / span_id are serialised here` slot,
  immediately after `level` and `target`. Under the `otel` feature, values come
  from the OTel context; with the feature off, the keys are simply absent. py does
  the same thing with a soft import (`core/logging.py:106,131-134`), and rustup does
  the Rust equivalent with `#[cfg(feature = "otel")] fn telemetry<S>(..)`
  composing `tracing_opentelemetry::layer()` into the same `Registry`
  (`rust-lang/rustup:src/cli/log.rs:112-128`), behind
  `otel = ["dep:opentelemetry-otlp", "dep:tracing-opentelemetry", "dep:opentelemetry", "dep:opentelemetry_sdk"]`
  (`Cargo.toml:29-34`). The template's equivalent nests on R69's `web`, as R69's
  accepted value already anticipates: `otel = ["web", ...]`.
- **R59 (file sink).** A slot in `init` where a second `Layer` with its own
  `MakeWriter` and its own `Filter` attaches to the same `Registry`. Per-layer
  filters are how `tracing-subscriber` gives a sink an independent level, which is
  exactly what F256/F260 will need. Nothing about the file sink is decided here.

##### Dominant choice

`inapplicable — this is a template-owned pattern, not a crate`, so there is no
crates.io "dominant" entry to name. The dominant *pattern* in the surveyed field
is (b) + (a): a custom `FormatEvent` delegating field formatting to
`N: FormatFields`, which is what `rust-lang/rustup` ships in production
(`src/cli/log.rs:78-97`) and what `tracing-subscriber`'s own `FormatEvent`
documentation gives as its worked example — rustup's comment cites it verbatim:
"Adapted from https://docs.rs/tracing-subscriber/latest/tracing_subscriber/fmt/trait.FormatEvent.html#examples".

##### Qualified shortlist

| Option | What it costs | What it leaves unsolved |
|---|---|---|
| **(a)+(b) owned `FormatFields` (human) + owned `FormatEvent`/`FormatFields` (JSON)** — recommended | roughly 120 lines and their tests | nothing |
| (a) alone, on both profiles | roughly 25 lines | **Event fields leak on the JSON profile** — executed, probe `json2 spanonly`; and a non-JSON field format **panics** — executed, probe `r58probe json-fmtfields` |
| (c) a third-party formatter crate | 1 dependency | no redaction at all; the owned `FormatEvent` would still be required |
| (d) `secrecy` alone | 0 extra lines (R56 r2 already selected it) | only protects values that were *typed* as secrets; R5.6 **(MUST)** reaches "all output", including a header map a call site logs by `Debug` |
| (e) filter the serialized bytes in the `MakeWriter` | roughly 30 lines | a substring search over rendered output, which cannot distinguish a key from a value and would corrupt legitimate text; rejected on correctness |

##### Excluded by gate

Gate 1 (licence) is `inapplicable` twice over — the owner ruling of 2026-09-12
(Q7.B) and the fact that the code is the template's own, under the repository's
`MIT OR Apache-2.0`. Gate 2 (MSRV) is `inapplicable` as a *declared* figure: the
module has no `rust-version` of its own and compiles on whatever the workspace
declares; **executed**, it compiled under `rust-version = "1.96"` on rustc 1.98.0.
Gate 3's advisory half is `inapplicable` — there is no published package to file
an advisory against — but its **`unsafe` posture half is not, and is answered**:
the module contains **no `unsafe`**, and R06's published `unsafe-code-policy` is
the authority on where the `forbid(unsafe_code)` attribute is placed. Gate 4
**applies and is answered**: the module uses only `std`, `serde_json` and
`tracing-subscriber` APIs that are identical on `ubuntu-latest` and
`macos-latest`; **executed** on `aarch64-apple-darwin`, with no OS-conditional
code path. Gate 5: no async-runtime coupling. Gate 6: no dependency added beyond
`serde_json`, which R66's published decision already puts in the CLI crate.

Option (e) is the one thing genuinely **excluded**, on correctness rather than on
a gate.

##### Up-and-comers

`tracing-stackdriver` 0.10.0 is the closest thing to an emerging alternative that
would replace part of this module — it does GCP severity mapping and
`logging.googleapis.com/trace` injection in a `FormatEvent` of its own, which is
precisely the owner reference's C10 suggestion (`:111`). Not adopted: last
published **2024-03-11**, 281,187 90-day downloads, no declared `rust_version`,
and it binds the template to one cloud. Recorded as the deployment-specific layer
a consumer could substitute at the same seam.

##### Fit for this template

This is the only member whose existence is *caused* by this template's
requirements rather than by the ecosystem. It exists because R5.6 **(MUST)** and
F252 demand key-based masking, and because the ecosystem's JSON formatter has no
seam for it. Both source repositories argue for it: py puts redaction in the
shared processor chain precisely so "call sites never have to remember"
(`core/logging.py:91-92`), and ts's **absence** of any redaction step is exactly
the defect the template must not inherit.

##### Recommendation

Ship `src/telemetry.rs` in the root package with the shape above: `HumanFields`
wrapping `DefaultFields`, template-owned `JsonFields` and `JsonEvent`, one
`is_sensitive` function shared by all three, the F252 key vocabulary as a
`const` array, an explicit R78 slot and an explicit R59 slot, and
`secrecy::SecretString` (R56 r2's, already in the tree) as the first line of
defence at the type level.

##### Ranked runner-up

`tracing-bunyan-formatter` 0.3.10 for the structured profile plus a
`secrecy`-only redaction policy. Ranked second because it is the smallest thing
that produces schema'd JSON. Rejected because it discharges R5.6 only for values
a call site remembered to type as secrets — the exact discipline F252 exists to
remove.

##### Tradeoffs

Gained: P3 satisfied for both profiles with executed proof; a single place where
R78 injects trace ids; no third-party formatter dependency; and control over the
JSON key set, which R7.8's envelope consumers benefit from. Paid: roughly 120
lines of template code with its own test burden; a maintenance coupling to
`tracing-subscriber`'s `FormatEvent`/`FormatFields` traits (the re-verify trigger
names it); and the risk that a future `Visit` method the module does not override
lets a typed value through un-redacted — which is why the acceptance test asserts
on a value recorded through `Debug`, the widest path.

##### Parameters

Contributes the redaction and profile clauses of `logging-pipeline-contract`.
Consumes `license` (the module inherits the repository's `MIT OR Apache-2.0`),
`rust-edition = 2024`, `msrv-policy`, `target-os-matrix`, and
`web-extra-surface` (the `Profile::Service` branch is only constructed by the
`rslbp-serve` binary that R69's `web` feature gates).

##### Migration implications

Replaces py's `_redact_sensitive` (`core/logging.py:143`) and
`SENSITIVE_KEY_PARTS` (`:93`) — same vocabulary, different insertion point:
**format time, not event time**. The observable difference is that a redacted
field cannot be un-redacted by a later processor, because there is no later
processor; and that a `Layer` other than `fmt` — R78's OTel layer, for instance —
sees the **unredacted** field, since it reads the `Event` directly. That is a real
and important consequence: **redaction is a property of the rendered output, not
of the event**, so any *exporter* added later must apply the same policy itself.
This is called out here because R78 will need to know it. ts has nothing to
migrate; it has no redaction.

##### Validation strategy

Proposed for P03, as a `#[test]` per assertion in
`tests/telemetry_redaction.rs` using `tracing::subscriber::set_default` (the
scoped guard, so tests do not fight over the global) and a shared
`Arc<Mutex<Vec<u8>>>` writer:

1. human profile, event field `token` → the line contains `[REDACTED]` and
   contains neither `sk_live_` nor `hunter2`;
2. human profile, **span** field `api_key` → same;
3. structured profile, event field `token` → the line parses as JSON and
   `["token"] == "[REDACTED]"`;
4. structured profile, span field `api_key` → `["span"]["api_key"] == "[REDACTED]"`;
5. a `secrecy::SecretString` recorded with `?` → rendered `SecretBox<str>([REDACTED])`;
6. a field value containing an ESC byte → the byte does not appear raw in the output;
7. every line goes to the test writer and **stdout receives zero bytes**.

Executed here, on the probe rather than on the template: 1, 2 (probe
`r58probe human-redact`), 3, 4 (probe `json2 custom`), 5 (probe `r58probe
secrecy`), 6 (probes `r58probe ansi`, `r58probe ansi-redact`, `json2
custom-ansi`), 7 (probes `r58probe human`, `json2 custom` — stdout carried exactly
`RESULT-ON-STDOUT`).

##### Confidence & re-verify trigger

**High**, and unusually well evidenced for a pattern member: five of the seven
acceptance assertions were executed against real `tracing-subscriber` 0.3.23.
Re-verify when `tracing-subscriber` changes `FormatEvent`, `FormatFields`, or
`Format<Json>`'s treatment of `N`; when R56 republishes with a different secret
type; when R78 publishes and fills the trace-id slot; when R59 publishes and fills
the sink slot; when F252's key vocabulary is extended; or by 2027-03-18.

##### Sources

`tracing-subscriber-0.3.23/src/fmt/format/json.rs:175-205,252,268-270`,
`src/fmt/format/mod.rs`, `src/field/mod.rs:88` (the `RecordFields` seal),
`src/util.rs:41-95` in the local registry (read 2026-09-18);
compiler diagnostics `E0599` (`flatten_event` bound to `JsonFields`), `E0599`
(`JsonFields: MakeVisitor` unsatisfied) and `E0277` (`RecordFields` sealed),
emitted by rustc 1.98.0 on 2026-09-18;
https://raw.githubusercontent.com/rust-lang/rustup/master/src/cli/log.rs (lines 78-128, retrieved 2026-09-18);
`py:src/py_launch_blueprint/core/logging.py:91-93,143,154-166` at pin `b08bccfb` (read 2026-09-18);
`ts:src/lib/logger.ts:29-80` at pin `cb1cbcb2` (read 2026-09-18);
the org CLI Design Standard v1.4.14 `:332` (R5.6) and `:381` (R7.1), blob `f9de0437`;
`GET https://crates.io/api/v1/crates/tracing-stackdriver` and `/versions` (retrieved 2026-09-18).

### Compatibility

The three crate members are **published from one repository, `tokio-rs/tracing`,
and released together**: `tracing` 0.1.44 and `tracing-core` 0.1.36 were both
published 2025-12-18, and `tracing-subscriber` 0.3.22/0.3.23 follow the same
release trains (`GET https://crates.io/api/v1/crates/<name>/versions`, retrieved
2026-09-18). `tracing-subscriber` names `tracing-log` in its own default feature
set (`tracing-subscriber-0.3.23/Cargo.toml:64-70`), so the version matrix is not a
matter of independent compatibility at all — Cargo resolves it.

Three independent proofs that the exact combination works:

1. **Executed resolution and build.** A probe manifest declaring
   `edition = "2024"`, `rust-version = "1.96"`, `tracing = "0.1.44"`,
   `tracing-subscriber = { version = "0.3.23", features = ["env-filter", "json"] }`,
   `tracing-log = "0.2.0"`, `log = "0.4.34"`, `secrecy = "0.10.3"`,
   `serde = { version = "1", features = ["derive"] }` and `serde_json = "1"`
   resolved to a 28-crate normal graph and built clean on rustc 1.98.0 in 16.16 s,
   then ran eleven behavioural scenarios. The probe's `secrecy` 0.10.3 is **R56 r2's
   accepted crate**, so the two items' stacks were resolved together, not
   separately. (The probe enabled `json` in order to *test* the stock JSON
   formatter's behaviour; the recommendation leaves it off.)
2. **A shared adopter at these versions.** `rust-lang/rustup` declares
   `tracing = "0.1"`, `tracing-log = "0.2"`, `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`
   and `tracing-opentelemetry = { version = "0.33", optional = true }` in one
   manifest (`Cargo.toml:98-101`, retrieved 2026-09-18) — the same three members
   plus the R78 hook, in a shipped CLI. `rust-lang/cargo` declares
   `tracing = "0.1.44"` and `tracing-subscriber = "0.3.23"` — **the same two exact
   patch versions recommended here** (`Cargo.toml:118-120`, retrieved 2026-09-18).
3. **A shared adopter for the axum side.** R69's accepted value turns on axum
   0.8.9 with its default `tracing` feature, which emits into whatever subscriber
   is installed, and `tower-log`, which routes tower's `log` records into the same
   place through `tracing-log`. No version conflict is possible: axum depends on
   `tracing` 0.1, the same line, and `tower-http`'s `TraceLayer` — R75's row — is
   built on it.

The one combination that is **not** compatible is recorded rather than hidden: the
stock `.json()` event formatter and a non-`JsonFields` field formatter cannot be
composed — it fails to compile if the builder order is one way and panics at
runtime if it is the other. That combination is not in the recommended stack.

### Parameters

- owns logging-pipeline-contract = `logging-pipeline/v1`: **Stack** — `tracing` 0.1.44 is the only diagnostic facade any package may name, taken `default-features = false, features = ["std"]` by `rs-launch-blueprint-core` and `rs-launch-blueprint-web` and with its defaults (`std`, `attributes`) by the root package `rs-launch-blueprint` and `rs-launch-blueprint-cli`; `tracing-subscriber` 0.3.23 `features = ["env-filter"]` over its default set (`smallvec`, `fmt`, `ansi`, `tracing-log`, `std`) is declared on the root package **only**, with the `json` feature **off** (the template owns the structured formatter, so `tracing-serde` buys nothing) and `local-time` **never** enabled (its own documentation says the offset lookup "may be unsound or fail"; timestamps are UTC ISO-8601, as py's are); `tracing-log` 0.2.0 enters through `tracing-subscriber`'s default `tracing-log` feature and is never declared directly; no other logging crate is added, and `crates/core`, `crates/cli` and `crates/web` must not name `tracing-subscriber`, enforced by R02's `cargo deny --all-features check bans` `[bans] deny[].wrappers` rule and its `crates/core` allow-list test. **Initialisation** — exactly one `telemetry::init(Profile) -> Init` in the root package's `src/telemetry.rs`, called first in each binary's `main` before anything that can log; it builds `Registry::default()` with a `reload::Layer<EnvFilter>` and one `fmt` layer whose writer is **stderr**, and installs it with `SubscriberInitExt::try_init()` — **never** `init()`, which is `try_init().expect(..)` — returning `Init::Installed(Handles { level: reload::Handle<EnvFilter, Registry> })` on success and `Init::HostOwned` on `Err`, never panicking, never replacing and never tearing down anything, because the global dispatcher can be set once per process and an `Err` means a host already owns diagnostics; template code never calls `tracing_log::LogTracer::init()`, because `try_init` already installs the bridge with the subscriber's max-level hint and a second installation fails with `SetLoggerError`; tests and embedders use the scoped `set_default` guard instead of the global path. **Reconfiguration** — the level is swappable after the config file is read, through the returned `reload::Handle` (this is how F274's config tier is reached without logging being absent while the config file is parsed); the **format and the writer are fixed at init** and are not reloadable, a deliberate departure from py's handler-replacement model recorded as a migration risk. **Structured-field and redaction contract** — key-based masking is applied at **format time**, not event time, because a `tracing::Event` is immutable, `RecordFields` is a sealed trait and no `Layer` can rewrite an event; the key vocabulary is F252's verbatim (`token`, `password`, `secret`, `authorization`, `api_key`, `apikey`, `credential`, `cookie`, ASCII-lowercased substring match) and the mask is `[REDACTED]`; the human profile uses a template-owned `FormatFields` wrapping `DefaultFields`, and the structured profile uses a **template-owned `FormatEvent` plus a template-owned JSON `FormatFields`**, because `tracing-subscriber`'s stock `Format<Json>` serialises event fields itself through `tracing_serde::SerdeMapVisitor` and uses its `N: FormatFields` parameter only for span fields, so a redacting field formatter under `.json()` leaks every event field and panics if its output is not valid JSON; `secrecy::SecretString` (R56 revision 2) is the first line of defence at the type level and the key match is the second; redaction is a property of rendered output, so any later exporter layer (R78's) must apply the policy itself. **Profiles (one engine, two policies; one subscriber per process, since each front end is its own binary)** — `Profile::Cli` for `rslbp`: format `auto|console|json` where `auto` resolves to console when `std::io::stderr().is_terminal()` and to JSON otherwise, colour from R65's resolved `anstream::ColorChoice` passed to `.with_ansi(bool)`, default level `WARN`; `Profile::Service` for `rslbp-serve`: JSON always with no TTY test, default level `INFO`, no file sink, level and format read from environment variables **named by R77**, plus R75's request-span layer. **Level ladder (F274), one total order, highest first** — `--debug` (`TRACE` plus internal detail: target, file, line, thread) > `--log-level <off|error|warn|info|debug|trace>` > `RSLBP_LOG_LEVEL` > `--quiet`/`-q` (`ERROR`) > `-v`/`-vv`/`-vvv` (`INFO`/`DEBUG`/`TRACE`) > config-file `[logging].level` > default `WARN`; `--log-format <auto|console|json>` with `RSLBP_LOG_FORMAT` selects the render mode by the same deterministic flag-to-environment mapping. **Streams** — every diagnostic byte goes to stderr and stdout is never written by the pipeline, per CLI Design Standard R7.1 and R67's "stdout stays byte-empty on the error path"; the pipeline never emits R67's error envelope, which the error boundary owns. **Extension interface** — two declared slots and nothing decided in them: a **layer slot** in `telemetry::init` where R78's `tracing-opentelemetry` layer attaches under an `otel = ["web", ...]` feature that nests on R69's `web`, with a matching `trace_id`/`span_id` serialisation point in the owned `FormatEvent`; and a **sink slot** where R59's file sink attaches as a second `Layer` with its own `MakeWriter` and its own per-layer `Filter`, which is how a sink gets a level independent of the console.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

The `web-extra-surface` line above is the **live registry row**, byte-identical to
`docs/port/PARAMETERS.md`, and it is revision 9's text. R69 **revision 10** is
owner-accepted and unpublished
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`): it
declares the feature on the root package as `web = ["dep:rs-launch-blueprint-web"]`,
moves the module tree to `crates/web/src/`, declares axum and tokio
non-optionally inside `crates/web/Cargo.toml`, drops the file-level
`#![cfg(feature = "web")]` because the whole member is optional, and keys
path-based skip-gating on `crates/web/**`. **This design uses revision 10's
paths**: `crates/web` is the package that takes the `tracing` facade and never
`tracing-subscriber`, and the `rslbp-serve` binary in the root package is where
`Profile::Service` is constructed. R69's republication of the registry row is
named as a re-verify trigger below.

**No `CONFLICT:` line is raised.** Every consumed value is usable as written: R69's
feature boundary is exactly where the `otel` nesting belongs, R67's envelope is
emitted by the error boundary rather than by this pipeline and the two never
contend for stdout, R49's `rslbp` binary name is what the CLI profile attaches to,
and the four fixed parameters are satisfied by every recommended crate.

### Migration implications

File-level changes in the template, all **proposed** (P03 builds them):

| File | Change |
|---|---|
| `Cargo.toml` (root package `rs-launch-blueprint`) | add `tracing = "0.1.44"` and `tracing-subscriber = { version = "0.3.23", features = ["env-filter"] }`; do **not** add `tracing-log`, `tracing-serde` or the `json` feature |
| `crates/core/Cargo.toml` | add `tracing = { version = "0.1.44", default-features = false, features = ["std"] }` — 4 crates, no proc-macro, no subscriber |
| `crates/cli/Cargo.toml` | add `tracing = "0.1.44"` (defaults) |
| `crates/web/Cargo.toml` | add `tracing = { version = "0.1.44", default-features = false, features = ["std"] }`; axum's default `tracing` and `tower-log` features already emit into it |
| `src/telemetry.rs` (new, root package) | `Profile`, `Init`, `Handles`, `init()`, and the `redact` submodule with `SENSITIVE`, `REDACTED`, `is_sensitive`, `HumanFields`, `JsonFields`, `JsonEvent` |
| `src/main.rs` (the `rslbp` binary) | first statement of `main`: resolve the ladder from parsed flags and environment, call `telemetry::init(Profile::Cli { .. })`, keep the returned `Handles`, and pass the level handle to the config-loading step |
| the `rslbp-serve` binary source | first statement of `main`: `telemetry::init(Profile::Service { .. })` with level and format from R77's environment names |
| `deny.toml` | a `[bans] deny[].wrappers` entry naming `tracing-subscriber` with the root package as its only permitted wrapper |
| `tests/workspace_edges.rs` (R02's) | add `tracing` to `crates/core`'s external-dependency allow-list; assert `tracing-subscriber` appears on no member but the root package |
| `tests/telemetry_redaction.rs` (new) | the seven assertions listed under the pattern member's *Validation strategy* |
| `crates/cli` global-args module (R60's) | `--log-level` with `env = "RSLBP_LOG_LEVEL"`, `--log-format` with `env = "RSLBP_LOG_FORMAT"`; `-v`, `-q` and `--debug` already exist as R4.1's required global core |
| `README.md` / docs | one table documenting the ladder and the two format values, because R7.12 and R5.4 make the flag and environment names part of the public interface |

What is **not** changed here and is left to its owner: `[logging]` config-file keys
beyond `level` (R59/R54), the file sink itself (R59), the state directory (R57),
the OTel layer's contents (R78), the `/metrics` route (R79), the request-span
layer and access logging (R75), and the serve binary's environment names (R77).

### Validation strategy

**Executed** — eleven scenarios across two probe binaries under `$TMPDIR`, on
rustc 1.98.0 / cargo 1.98.0, macOS `aarch64-apple-darwin`, 2026-09-18, against
`tracing` 0.1.44, `tracing-subscriber` 0.3.23, `tracing-log` 0.2.0, `log` 0.4.34
and `secrecy` 0.10.3:

| # | Scenario | Command | Result |
|---|---|---|---|
| E1 | human profile writes diagnostics to stderr only | `./r58probe human 1>out 2>err` | `out` = `RESULT-ON-STDOUT`; the event line is in `err` |
| E2 | human profile redacts event **and** span fields | `./r58probe human-redact` | `api_key="[REDACTED]" … token="[REDACTED]" password="[REDACTED]"` |
| E3 | stock `.json()` leaks event fields | `./json2 spanonly` | `"token":"sk_live_EVENTSECRET"` present; span `api_key` redacted |
| E4 | a non-JSON `FormatFields` under `.json()` panics | `./r58probe json-fmtfields` | exit 101, `span 'request' had malformed fields! this is a bug.` |
| E5 | owned `FormatEvent` + owned `FormatFields` redacts both, stdout clean | `./json2 custom 1>out 2>err` | `out` = `RESULT-ON-STDOUT`; `err` line has `"token":"[REDACTED]"` and `"span":{"api_key":"[REDACTED]"…}` |
| E6 | the level is swappable after init | `./r58probe reload` | pre-swap `info!` absent; post-swap `info!` and `debug!` present |
| E7 | a second global install is refused, not forced | `./r58probe host` | `SECOND-INIT-IS-ERR=true` |
| E8 | a host owning the `log` logger is not robbed | `./hostlog` | `TRY_INIT_IS_ERR=true`; tracing event rendered by us; `log` record rendered by `HOST-LOGGER` |
| E9 | the `log` bridge is automatic; installing it twice fails | `./r58probe logbridge-off` / `logbridge-on` | `LOG-CRATE-RECORD` rendered with no bridge call; explicit `LogTracer::init()` then `.init()` → `SetLoggerError` |
| E10 | a `secrecy::SecretString` never renders | `./r58probe secrecy` | `secret_value=SecretBox<str>([REDACTED])` beside `plain="sk_live_TOPSECRET"` |
| E11 | ESC and BEL bytes in a field value are escaped on both profiles | `./r58probe ansi`, `ansi-redact`, `./json2 custom-ansi` | Rust escape notation (`\u{1b}`, `\u{7}`) on the human profile; JSON escapes (`\u001b`, `\u0007`) on the structured one |

Plus three **executed** dependency measurements: `cargo tree -e normal` over four
manifests (4 / 9 / 22 / 28 crates), and two clean-build timings (9.00 s facade,
16.16 s composition root).

**Proposed** for P03, against the real template:

```
cargo test -p rs-launch-blueprint --test telemetry_redaction
cargo tree -e normal -p rs-launch-blueprint-core        # asserts no tracing-subscriber
cargo deny --all-features check bans                    # [bans] wrappers on tracing-subscriber
cargo run --bin rslbp -- projects list --json 1>/tmp/out 2>/tmp/err
  # expect: /tmp/out parses as JSON; /tmp/err carries zero result bytes
RSLBP_LOG_LEVEL=debug cargo run --bin rslbp -- projects list 2>&1 >/dev/null | head
  # expect: DEBUG lines, none containing a token value
RSLBP_LOG_FORMAT=json cargo run --bin rslbp -- projects list 2>/tmp/err >/dev/null
  # expect: every line of /tmp/err parses as a JSON object
cargo run --features web --bin rslbp-serve 2>/tmp/err &
  # expect: JSON lines on stderr from the first line, no TTY-dependent variation
```

Expected behaviour for each is stated beside it. None of the seven proposed
commands has been run, because the template does not exist; the eleven executed
scenarios above are the substitute, and they exercise the same library behaviour
the commands would.

### Confidence & re-verify trigger

**Confidence: high on the architecture and on the crate stack; high and executed
on the redaction finding, which is the part most likely to be disbelieved;
medium on the exact rungs of the level ladder, which are a design choice this
decision makes rather than a fact it discovered, and which R60's and R54's
published surfaces could refine.**

**The maintenance figure a reviewer should look at first, because it is the one
that argues against this recommendation.** Per the prompt's rubric, issue
responsiveness was measured over the **10 most recently opened issues** of
`tokio-rs/tracing` — #3613, #3612, #3611, #3607, #3601, #3599, #3597, #3595,
#3593 and #3587, opened between **2026-07-31 and 2026-09-16**, taken from
`GET https://api.github.com/repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60`
with pull requests filtered out, and each one's
`GET .../issues/<n>/comments?per_page=30` read for the first comment whose
`author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author is
not the issue's author (retrieved 2026-09-18):

| Figure | Value |
|---|---|
| Sample | 10 issues, opened 2026-07-31 to 2026-09-16 |
| Median days to first maintainer response | **undefined — no issue in the sample has one** |
| Unanswered | **10 of 10**; nine of the ten have **zero** comments of any kind |
| Last push to the repository | `pushed_at` 2026-05-30 (3.6 months before retrieval) |
| Open issues | 628 (`search/issues` `total_count`) |
| Last releases | `tracing-subscriber` 0.3.23 on 2026-03-13 (6.2 months); `tracing` 0.1.44 on 2025-12-18 (9.0 months) |

**Verdict: `at-risk`, not `stable-quiet`, and the report says so rather than
rounding up.** The rubric's `at-risk` "needs a concrete signal"; ten consecutive
unanswered issues over seven weeks, combined with 3.6 months without a push, is
one. It is *not* `dormant`: there is no unpatched advisory, no maintainer notice,
and the crates build clean on current stable (**executed** — the 28-crate probe
tree built on rustc 1.98.0 in 16.16 s).

**Why the recommendation does not move, stated explicitly so the reader can
disagree with the reasoning rather than guess at it.** (1) No alternative in the
landscape satisfies P3 and P4 — the `log`-architecture renderers structurally
cannot, and `slog` has no maintained OTel bridge — so "pick a livelier crate"
names no crate. (2) The APIs this design depends on (`Layer`, `FormatEvent`,
`FormatFields`, `EnvFilter`, `reload`, `try_init`) are mature and have been stable
across the 0.3.x line; a quiet repository is a smaller risk for a stable API than
for a moving one. (3) The Rust project's own `cargo` and `rustup` depend on these
exact versions, so a genuine break would be an ecosystem event with many hands on
it. (4) The design's largest bet — the redaction formatters — is **template-owned
code**, which is precisely the part upstream quiet cannot break. What it does
change is cadence: the maintenance question is re-verified at **2026-12-18**,
three months out, not at the 2027-03-18 date the rest of this report uses.
**This signal travels to one other item.** `tracing-opentelemetry` 0.33.0 is
published from `tokio-rs/tracing-opentelemetry`, a sibling repository in the same
org (407 stars, `pushed_at` 2026-07-08, 18 open issues, retrieved 2026-09-18).
**R78 should inherit this finding and re-measure responsiveness for its own
repository rather than assuming the org is uniformly healthy**; nothing here
measures `tracing-opentelemetry`'s issue responsiveness, and this report does not
claim it. The two `pushed_at` figures are internally consistent with the release
dates: `pushed_at` is the last push to *any* branch, so 2026-05-30 sitting after
the 0.3.23 release of 2026-03-13 is what one expects, not a contradiction.

One thing this report could **not** verify and does not claim:

- **Any performance number.** No benchmark was run and none is cited. The
  performance-relevant claims made are structural and stated as such: `reload`
  costs a lock acquisition per event on the layer it wraps (which is why only the
  filter is behind one); `tracing`'s disabled-callsite path is a level comparison;
  `tracing-log`'s conversion cost applies only to `log` records, and the
  max-level hint `try_init` sets means disabled ones are rejected by `log`'s own
  static check first. Turning any of these into a figure would need a stated
  workload, and this item has none. **Evidence gap, declared.**

**Re-verify triggers.** Whichever comes first: `tracing-subscriber` publishing 0.4,
or any 0.3.x that changes `Format<Json>`'s treatment of `N: FormatFields`, the
`RecordFields` seal, the `tracing-log` default feature, or the `try_init` sequence
in `src/util.rs` — each of which is load-bearing above; `tracing` publishing 0.2;
any new RustSec advisory against `tracing`, `tracing-core`, `tracing-subscriber`
or `tracing-log`; **R69 republishing `web-extra-surface` with revision 10's
`crates/web` paths**, which this design already assumes and which would make the
registry row and this decision agree; R02, R05 and R56 publishing (each is
owner-accepted but unpublished, and this design is written against all three);
R77 publishing the serve binary's environment-variable names; R66 or R60
republishing in a way that moves `serde_json`'s home or the global-flag surface;
R59 or R78 publishing and filling the two declared slots; the org CLI Design
Standard revising R4.4, R5.4, R5.6, R7.1 or R7.3 past v1.4.14; the `msrv-policy`
floor advancing past 1.96; or **2027-03-18**.

### Sources

Registry and repository endpoints, all retrieved **2026-09-18**:
`GET https://crates.io/api/v1/crates/<name>` and `/versions` for `tracing`,
`tracing-core`, `tracing-subscriber`, `tracing-log`, `tracing-serde`, `log`,
`env_logger`, `fern`, `slog`, `log4rs`, `tracing-opentelemetry`,
`tracing-bunyan-formatter`, `tracing-tree`, `tracing-forest`,
`tracing-stackdriver`, `fastrace`, `logforth`, `tracing-appender` and `secrecy`;
`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=1`
(field `meta.total`) for `tracing`, `tracing-subscriber`, `log`, `env_logger`,
`slog`, `fern`, `log4rs`;
`GET https://api.github.com/repos/<o>/<r>` for `tokio-rs/tracing`, `rust-lang/log`,
`rust-cli/env_logger`, `daboross/fern`, `slog-rs/slog`, `estk/log4rs`,
`tokio-rs/tracing-opentelemetry`, `LukeMathWalker/tracing-bunyan-formatter`,
`fast/fastrace`, `fast/logforth`, `davidbarsky/tracing-tree`;
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(field `total_count`) for the same eleven repositories;
`GET https://api.github.com/repos/tokio-rs/tracing/issues` and
`/issues/<n>/comments` for the responsiveness sample.

Advisories: https://rustsec.org/packages/tracing.html,
https://rustsec.org/packages/tracing-subscriber.html,
https://rustsec.org/advisories/RUSTSEC-2023-0078.html,
https://rustsec.org/advisories/RUSTSEC-2025-0055.html, and the "Page not found"
responses for `tracing-core`, `tracing-log`, `log`, `env_logger`, `slog`,
`log4rs` and `fern` (retrieved 2026-09-18).

Source read at the exact published versions in
`~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f` (read 2026-09-18):
`tracing-0.1.44/Cargo.toml`; `tracing-core-0.1.36/Cargo.toml`;
`tracing-log-0.2.0/Cargo.toml`; `tracing-subscriber-0.3.23/Cargo.toml`,
`/src/util.rs`, `/src/fmt/format/json.rs`, `/src/fmt/time/time_crate.rs`,
`/src/field/mod.rs`.

Upstream manifests and implementations (retrieved 2026-09-18):
https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml;
https://raw.githubusercontent.com/rust-lang/rustup/master/Cargo.toml;
https://raw.githubusercontent.com/rust-lang/rustup/master/src/cli/log.rs;
https://raw.githubusercontent.com/rust-lang/rust-analyzer/master/Cargo.toml;
https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml;
https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml;
https://raw.githubusercontent.com/tokio-rs/tracing/master/.github/workflows/CI.yml.

Source repositories at their programme pins (read 2026-09-18):
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/logging.py`
(lines 85-240), `:src/py_launch_blueprint/web/logging.py` (lines 1-70),
`:src/py_launch_blueprint/cli/options.py` (lines 75-100),
`:src/py_launch_blueprint/cli/context.py` (lines 190-235);
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/logger.ts` (lines 20-80).
Every py citation is at `b08bccfb`; every ts citation is at `cb1cbcb2`.

This repository (read 2026-09-18): `docs/port/COMMONALITY.md:253-259,266-267,277-278,308,331`;
`docs/port/BASELINE-REVIEW.md:116,124,147,254,266,330,421,448,477`;
`docs/port/PARAMETERS.md` (the four fixed rows and the `web-extra-surface`,
`error-taxonomy-exit-codes` and `build-tool-output-shape` rows quoted verbatim);
`docs/planning/p02/owner-decisions.md:157-214` (the licence ruling),
`:269-303` (the standard binds), `:401-432` (the reference architecture as
standing input); `docs/planning/p02/owner-reference-axum-companion-stack-2026-09-16.md:68,69,111,178-181,236,241,324`;
`research/topics/60-cli-parsing-framework/DECISION.md`;
`research/topics/65-color-enablement-chain/DECISION.md`;
`research/topics/66-output-format-surface/DECISION.md`;
`research/topics/67-error-and-exit-code-contract/DECISION.md`;
and the owner-accepted, unpublished runs
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md`,
`research/runs/R05/2026-09-17T033527Z-bfacc9e801a5/review/DECISION.md`,
`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md`,
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (notably
`:1791` and `:1840`).

The org CLI Design Standard v1.4.14 at blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `/Users/stevemorin/c/cli-standards`,
read 2026-09-18 via `git cat-file blob`. Rules quoted at their lines: R4.1
(`:237-255`), R4.2 (`:256-259`), R4.4 (`:266-268`), R5.4 (`:322-324`), R5.5
(`:326-329`), R5.6 (`:331-333`), R7.1 (`:380-383`), R7.2 (`:385-387`), R7.3
(`:389-392`), R7.4 (`:394-395`), R7.6 (`:421-424`), R7.7 (`:426-429`), R7.8
(`:431-433`).

**Method notes.** Figures were taken from exactly the endpoints the prompt's table
names: crates.io `/api/v1/crates/<name>` for `crate.recent_downloads` and
`crate.downloads`, `/versions` for the newest entry with `yanked: false` (which
caught two yanked versions, `tracing` 0.1.42 and `tracing-subscriber` 0.3.21, that
a "latest version" shortcut would have mis-reported), `/reverse_dependencies` for
adoption breadth, GitHub `repos/<o>/<r>` for `stargazers_count`, `archived` and
`pushed_at`, and `search/issues` for `total_count` — never
`open_issues_count`, which in every case differed from the search total because it
counts pull requests (for `tokio-rs/tracing`, 890 against 628). GitHub calls were
paced at one per 21 seconds. RustSec pages were fetched over HTTPS and the "no
advisories" results are the site's own 404 page, reported as such rather than as a
positive clean bill. Issue responsiveness was measured over a
10-issue sample built by filtering pull requests out of
`repos/tokio-rs/tracing/issues?state=all&sort=created&direction=desc&per_page=60`
and reading each issue's comments; the result — 10 of 10 unanswered, median
undefined — is reported in full under `### Confidence & re-verify trigger`.
**Could not verify:** (1) any performance figure, since
no benchmark was run and no workload is defined for this item; (2) that the
recommended stack behaves as designed *in this template*, since the template does
not exist — the eleven executed probe scenarios stand in for that and are labelled
as probe results throughout, never as template results. The probe workspace was
created under a subdirectory of `$TMPDIR` and removed after the run; no file was
written outside this run directory; no personal email address or credential
appears anywhere in this report.
