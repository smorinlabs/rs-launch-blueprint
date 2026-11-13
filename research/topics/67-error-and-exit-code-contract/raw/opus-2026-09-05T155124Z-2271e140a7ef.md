# R67 — Error and exit-code contract (bundle)

Actor: `research-opus-2026-09-05T155124Z-2271e140a7ef`. Model ID quoted from this
worker's own system prompt: `claude-opus-5[1m]`. All figures retrieved 2026-09-05.
Toolchain used for every executed check: `rustc 1.98.0 (88d9e12ae 2026-08-18)`,
`cargo 1.98.0`. Current Rust stable at retrieval is `1.98.1`, published
2026-09-03 (`https://api.github.com/repos/rust-lang/rust/releases/latest`,
retrieved 2026-09-05), so the MSRV policy floor `stable minus 2 minor versions`
resolves to **1.96** for this run. Every gate-2 verdict below compares a crate's
declared `rust_version` against 1.96.

### Landscape

**The category this item decides.** Not "an error crate". This item decides a
*contract*: a stable, append-only catalog of error codes, the process exit codes
those codes map to, and the process-level handlers (signal, broken pipe, crash
log) that produce exit codes no domain error ever reaches. Rust splits that
contract across two ecosystem layers that are conventionally kept separate — a
library-side *typed enumeration* of failure modes, and a binary-side *opaque
error carrier* that adds context and terminates the process. Because the target
shape is CLI + library + web service (spec §4 D7), both layers exist here and the
split is load-bearing, not stylistic.

**Three-bin map of the Rust field.** Every shortlisted candidate below comes from
this map.

*Bin 1 — built-in or first-party toolchain (no dependency).*

| Mechanism | What it decides here |
|---|---|
| `std::process::ExitCode` + the `Termination` trait | the exit-code carrier returned from `main`; stable since Rust 1.61 |
| `std::process::exit` | the alternative exit path — terminates without running destructors |
| `#[repr(u8)]` enum + `const fn` match | a hand-written, rename-proof code catalog with no proc-macro |
| `std::io::ErrorKind::BrokenPipe` | the only *stable* way to detect EPIPE (see the `-Zon-broken-pipe` finding below) |
| `std::backtrace::Backtrace` | trace capture, env-gated — the F301 mechanism |
| `std::fs::OpenOptions::append` | the crash-log writer |
| `-Zon-broken-pipe` / `#![feature(unix_sigpipe)]` | **nightly only** — excluded by the stable-Rust constraint |

*Bin 2 — established industry standard.*

| Crate | Slot | 90-day downloads |
|---|---|---:|
| `thiserror` | derive `Display`/`Error` on a typed domain enum | 349,580,121 |
| `anyhow` | opaque application-boundary error with context chain | 206,370,924 |
| `strum` | derive string conversions from enum variants | 134,420,790 |
| `signal-hook` | signal handling that reports *which* signal fired | 52,827,824 |
| `ctrlc` | Ctrl-C handling (the CLI-WG book's named crate) | 21,098,753 |
| `snafu` | context-selector alternative to `thiserror` | 16,745,357 |
| `miette` | diagnostic-rendering error reporter | 16,595,728 |
| `dialoguer` | interactive prompts (F299 surface) | 16,282,063 |
| `etcetera` | XDG/state directory resolution (crash-log path) | 31,585,774 |
| `directories` | XDG directory resolution — **archived** | 12,201,032 |
| `eyre` / `color-eyre` | `anyhow` fork with a pluggable report handler | 19,803,808 / 12,814,782 |
| `exitcode` | BSD `sysexits.h` constants — named by the CLI-WG book | 824,414 |

*Bin 3 — up-and-comer.*

| Crate | Slot | 90-day downloads | Signal |
|---|---|---:|---|
| `inquire` | interactive prompts with **typed** cancellation errors | 5,319,781 | 2,623 stars; the only prompt crate surveyed with a typed Ctrl-C variant |
| `sysexits` | typed BSD exit codes, edition 2024, `rust_version = 1.87.0` | 208,587 | 33 stars — modern packaging, negligible adoption |
| `human-panic` | friendly panic hook that persists a crash report | 2,783,578 | under the `rust-cli` org; covers panics, *not* returned errors |
| `sigpipe` | one-call restore of the default `SIGPIPE` disposition | 146,505 | last release 2022-02-02; `unsafe` `libc::signal` wrapper |

All crates.io figures: `GET https://crates.io/api/v1/crates/<name>` field
`crate.recent_downloads`, retrieved 2026-09-05.

**Authorities used, and why each is authoritative.**

1. **The Rust CLI Working Group book, *Command Line Applications in Rust***
   (`https://rust-cli.github.io/book/in-depth/exit-code.html` and
   `.../in-depth/signals.html`, both retrieved 2026-09-05). Authoritative because
   it is the CLI working group's own publication — a Rust project team output,
   not a personal blog. It is the closest thing the ecosystem has to normative
   CLI guidance. It names `exitcode` for exit codes and `ctrlc` for Ctrl-C, and
   states plainly: "Currently, Rust sets an exit code of 101 when the process
   panicked", and that if an application "does not need to gracefully shutdown,
   the default handling is fine". I treat its two crate recommendations as leads
   and test them; both turn out to need qualification (below).
2. **The Rust compiler team's own tracking issues**, `rust-lang/rust#97889`
   ("Tracking Issue for `unix_sigpipe`", state `open`, labels
   `C-tracking-issue,T-libs`, updated 2026-08-12) and `rust-lang/rust#62569`
   ("Should Rust still ignore SIGPIPE by default?", state `open`) — retrieved via
   `https://api.github.com/repos/rust-lang/rust/issues/97889` and `/62569`,
   2026-09-05. Authoritative as the libs team's own record of the language
   decision and its stabilization status.
3. **The RustSec Advisory Database** (`https://rustsec.org/packages/<name>.html`
   and `/advisories/<id>.html`, retrieved 2026-09-05) — the Rust Secure Code
   working group's database, the ecosystem's normative advisory source and the
   backing data for `cargo audit`/`cargo deny`.
4. **Maintainers' own published source**, read directly rather than paraphrased:
   `ctrlc`'s `src/lib.rs`, `inquire`'s `inquire/src/error.rs`, `dialoguer`'s
   `src/error.rs`, `human-panic`'s `src/report.rs` (all
   `raw.githubusercontent.com`, retrieved 2026-09-05). Authoritative for API
   shape because it is the shipped code, not documentation about it.
5. **A maintained reference implementation read in full**: ripgrep's
   `crates/core/main.rs`
   (`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/main.rs`,
   retrieved 2026-09-05). Authoritative as production practice at scale, and it
   is the canonical Rust EPIPE reference — its comment states the mechanism
   explicitly.

A single blog post is a lead, not an authority; none is cited as one here.

**Well-regarded projects surveyed, with the evidence that they are well
regarded.** Each `Cargo.toml` was fetched from `raw.githubusercontent.com` on
2026-09-05; the "well regarded" evidence is adoption and maintainer standing, not
assertion.

| Project | Evidence it is well regarded | `rust-version` | Relevant dependencies |
|---|---|---|---|
| ripgrep (`BurntSushi/ripgrep`) | the de-facto Rust CLI reference; maintained by a Rust libs contributor; ships in most distributions | `1.96` | `anyhow = "1.0.75"`; no `thiserror` in the binary crate |
| Cargo (`rust-lang/cargo`) | the Rust project's own build tool | `1.95` | `anyhow = "1.0.102"`, `thiserror = "2.0.18"` |
| Ruff (`astral-sh/ruff`) | Astral's Python linter, one of the fastest-growing Rust CLIs | `1.96` | `anyhow = "1.0.80"`, `thiserror = "2.0.0"`, `strum = "0.28.0"`, `etcetera = "0.11.0"` |
| Nushell (`nushell/nushell`) | a widely adopted Rust shell | `1.96.1` | `anyhow = "1.0.104"`, `thiserror = "2.0.20"`, `ctrlc = "3.5.2"`, `miette = "7.6"`, `strum = "0.28.0"` |
| cargo-nextest (`nextest-rs/nextest`) | the standard third-party Rust test runner | `1.91` | `color-eyre = "0.6.5"`, `thiserror = "2.0.20"`, `miette = "7.6.0"`, `etcetera = "0.11.0"`, `dialoguer = "0.12.0"` |
| bat (`sharkdp/bat`) | one of the most-installed Rust CLI tools | `1.88` | `anyhow = "1.0.97"`, `thiserror = "2.0"`, `etcetera = "0.11.0"` |
| fd (`sharkdp/fd`) | ditto, same maintainer | `1.90.0` | `anyhow = "1.0"`, `ctrlc = "3.5"`, `etcetera = "0.11"` |

Two facts fall straight out of this table and drive the recommendation. First,
the `thiserror` (library, typed) + `anyhow` (binary, opaque) split is not a
matter of taste — it is what Cargo, Ruff, Nushell and bat all do, and ripgrep
uses `anyhow` alone because it has no library consumers to hand typed variants
to. Second, `etcetera` has displaced `directories` in newer well-regarded
projects (bat, fd, nextest, Ruff all use `etcetera`; none of the seven uses
`directories`), which matters for the crash-log path.

**Fit over abstract best.** Every candidate below is judged against this
template's three surfaces (CLI, library, web service) and against the py/ts
precedent in the prompt's `## Context` — not against "best error crate in
general". The two decisive fit findings are that this template *is* a library
(so an opaque-only carrier like `anyhow` cannot be the whole answer, unlike
ripgrep) and that it *does* ship a web service (so the SIGTERM question is real,
not hypothetical — see `### Principles and implementation`).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** `docs/port/DIVERGENCE-ANALYSIS.md:208-215` splits this item into four
cause classes, and the agreement level differs per class. Stating them separately
is the whole point — treating R67 as one "harmonize" decision is what produces
the wrong answer.

| Principle | Source | Agreement level | Class / harmonize |
|---|---|---|---|
| **P1 — A failure's public identity is a stable, documented token that survives refactoring** | py `src/py_launch_blueprint/core/errors.py:51` (`ERROR_CODE_UNEXPECTED = "PLBP000"`); ts has no equivalent (`src/router.ts:211` reflects the class name) | **standard** — all three repos must publish a stable catalog; the *token format* is per-repo | F295, class C, harmonize no (mechanism) over a shared standard |
| **P2 — Process exit codes come from one org-normative taxonomy** | cli-standards R6.1 via D-016(2), already adopted by ts `src/lib/errors.ts:13` | **standard, one value for all three repos** | F297/F298, class A ("setting drift"), harmonize **yes** |
| **P3 — A failure carries a separately addressable remedy** | py `src/py_launch_blueprint/core/errors.py:76` (`self.hint`), rendered at `cli/output.py:298`; ts inlines remedy text | **capability** — the remedy must be machine-addressable; its rendering may vary | F296, class F, harmonize partly |
| **P4 — Termination is predictable when the OS or a downstream reader intervenes** | ts `src/cli.ts:21` (SIGINT/SIGTERM), ts `src/cli.ts:17` (EPIPE); py has neither | **capability + the P2 exit integers**; the *mechanism* is language-bound | F298/F300, class A and C |
| **P5 — An unexpected failure is persisted for post-hoc diagnosis** | py `src/py_launch_blueprint/cli/options.py:143` (ADR 0006); ts absent | **capability**, harmonize **yes** — adopt in all three or drop in all three | F302, class D |

**What must agree, and what may vary.** Must agree across py, ts and rs: the exit
integers (0/1/2/3/4/5/130/143), the fact that the envelope `code` is stable and
append-only, the JSON envelope shape on stderr (F294, settled), and the existence
of a machine-addressable hint. May vary: the catalog's *token format* (py's
`PLBP000` prefix is a repo identifier, so rs uses its own — `RSLB###` below); the
*mechanism* of signal and EPIPE handling, which is genuinely language-bound; and
whether a backtrace is captured at all, which Rust gates on an environment
variable that has no Python or Node analogue.

**Is the shared architectural pattern still appropriate in Rust?** Partly, and
the departure is the substantive finding of this item. py and ts both use *one*
error type that carries both the stable code and the arbitrary failure. Rust
conventionally splits that in two, and this template must, because it is a
library as well as a binary. Comparing the architectural alternatives *before*
choosing libraries:

| Alternative | What it is | Why it is or is not chosen |
|---|---|---|
| **A1 — one opaque carrier everywhere** | `anyhow::Error` in library and binary; codes attached as context strings | This is ripgrep's shape (`anyhow` only, no `thiserror`) and works because ripgrep has no library consumers. **Rejected here**: R03, R52-R56 and R70 must *pattern-match* on variants — R70 needs an exhaustive domain-error-to-HTTP-status table. An opaque carrier makes that a string comparison. |
| **A2 — one typed enum everywhere** | a single `thiserror` enum, no opaque carrier | **Rejected**: every incidental `io::Error` from an unrelated call site must be given a domain variant, or be flattened into a catch-all that loses its cause chain. It also forces the library to own error variants that only the binary can produce. |
| **A3 — two layers: typed enum in the library, opaque carrier at the binary boundary** | `CoreError` (typed, exhaustive, carries the code) returned by library APIs; `anyhow::Error` accumulates context in the binary; the boundary `downcast_ref::<CoreError>()`s and falls back to an UNEXPECTED code | **Chosen.** Preserves P1 (the enum *is* the catalog), gives R03/R70 exhaustive matching, and gives the binary a context chain without polluting the library. Matches Cargo, Ruff, Nushell and bat. |
| **A4 — derive the code from the variant identifier** | `strum::EnumString`/`AsRefStr` or `std::any::type_name` | **Rejected**, and this is the direct answer to the HIGH question. Deriving the code from the variant *name* reproduces exactly ts's defect: `src/router.ts:211` uses `err.name`, so the wire code is whatever the class is currently called. In Rust a variant rename is a safe, compiler-checked refactor — which is precisely why a derived code is dangerous: the refactor is silent at compile time and breaking on the wire. An explicit `const fn code(&self) -> &'static str` match makes the token an independent, reviewable fact. |
| **A5 — `dyn DomainError` trait object with a `code()` method** | ports return `Box<dyn DomainError>` | **Rejected**: loses exhaustive `match`, which is the property R70's status table depends on; and adds dynamic dispatch to a seam R01 has not decided. |

**Recommended design, and how it preserves each principle.** The library crate
declares one `#[non_exhaustive]` `thiserror` enum. Three `const fn` methods on it
— `code()`, `hint()`, `exit()` — are total functions over the variants, so adding
a variant without assigning a code is a compile error. A `CATALOG` constant lists
every `(code, exit)` pair in registration order, and a unit test pins it: existing
rows must compare equal, and rows may only be appended. That test is what makes
"append-only" (P1) an enforced property rather than a documented intention — py's
`errors.py` catalog has no such test, and it is the one place where this design
is stronger than both sources.

The binary crate returns `std::process::ExitCode` from `main` (not
`std::process::exit`, which skips destructors) and resolves the exit code in a
fixed precedence: signal, then broken pipe, then domain error, then unexpected.
That ordering is not cosmetic — a `SIGINT` delivered while a write is failing
must report 130, not the write's exit code.

**Observable acceptance criteria.** Every row below was executed against a
working two-crate workspace built with the recommended stack; results are in
`### Validation strategy`. These are *executed results*, not proposals.

| # | Observable criterion | Measured result |
|---|---|---|
| AC1 | A domain error in human mode prints `error[<CODE>]: <message>` plus a separate `hint:` line and exits with the mapped code | `error[RSLB301]: no project named \`demo\`` / `  hint: run \`rslb list\`…`, exit **3** |
| AC2 | `--json` puts one `{"error":{"code","message","hint"}}` object on **stderr** and leaves stdout byte-empty | stderr envelope emitted; `stdout_bytes=0`; exit **4** for auth |
| AC3 | Each catalog block maps to its taxonomy code | config→**2**, notFound→**3**, auth→**4**, conflict→**5**, prompt-cancel→**130** |
| AC4 | An unexpected (non-domain) error uses the UNEXPECTED code and exit 1 | `{"error":{"code":"RSLB000","message":"loading the project index: No such file or directory (os error 2)"}}`, exit **1** |
| AC5 | Piping into a reader that closes early terminates cleanly | `rslb emit-lines \| head -2` → own exit **0**, empty stderr, no panic |
| AC6 | `SIGINT` yields 130 and `SIGTERM` yields 143, with destructors run | exit **130** / **143**, `cleanup-ran` printed by a `Drop` guard in both |
| AC7 | An unexpected error appends to a crash log, and a crash-log write failure does not change the exit code | log written with the full `Caused by:` chain; with an unwritable state dir the exit code stayed **1** |
| AC8 | The catalog is append-only and total | 3 unit tests pass: pinned rows unchanged, every variant registered, codes unique |

**Where a different ecosystem needs a different design.** Three places, each with
measured evidence rather than assertion.

1. **Broken pipe.** Node needs `process.stdout.on('error', ignoreEpipe)` (ts
   `src/cli.ts:17`); Python's default `SIGPIPE` disposition means py needs
   nothing, which is why F300 is `ts-only`. Rust needs *more* than either,
   because the Rust runtime sets `SIGPIPE` to `SIG_IGN` before `main`
   (`rust-lang/rust#62569`, referencing PR #13158, retrieved 2026-09-05), so the
   write returns an `io::Error` instead of killing the process — and the
   `println!` macro *panics* on that error. Measured: `println!` in a loop piped
   to `head -2` exits **101** with `failed printing to stdout: Broken pipe (os
   error 32)`; the identical loop using `writeln!` on a locked handle with a
   `BrokenPipe` check exits **0**. The stable-Rust constraint bites here: the
   language-level fix (`#[unix_sigpipe]`, since moved to the `-Zon-broken-pipe`
   compiler flag, `rust-lang/rust#97889`) is still an **open, unstabilized**
   tracking issue, so it is unavailable to this template. The template must
   therefore forbid `println!`/`print!` on the result path — a lint-enforceable
   rule, not a library choice.
2. **Signal handling.** ts registers two separate handlers and gets two exit
   codes for free. In Rust the CLI-WG book names `ctrlc`, but reading
   `ctrlc`'s own source shows `pub fn set_handler<F>` where `F: FnMut() +
   'static + Send` — the callback receives **no signal argument**, and its
   `termination` feature routes `SIGINT`, `SIGTERM` *and* `SIGHUP` to that same
   handler. `ctrlc` therefore cannot produce ts's distinct 130/143 split.
   `signal-hook` can, because its handler is registered per signal number.
3. **Backtrace.** Neither py nor ts has an analogue: both capture a traceback
   unconditionally and only gate its *display*. Rust gates *capture* on an
   environment variable, so display gating alone is not implementable.

**Answer to the MEDIUM SIGTERM question, whose premise needs correcting.** The
question asks whether py's SIGINT-only handling suffices "for a CLI template with
no long-running daemon mode". That premise does not hold for this template: the
target shape is CLI + library + **web service** (spec §4 D7, `web-extra-surface`
owned by R69), and a container runtime stops a web process by sending `SIGTERM`
and only escalates to `SIGKILL` after a grace period. A template whose web
surface ignores `SIGTERM` cannot drain connections. Recommend handling both, with
ts's codes (130/143). Note the mechanism split this implies: `signal-hook`
covers the synchronous CLI path; the web surface will want `tokio::signal` inside
its runtime rather than a second `signal-hook` registration. I do not pick that
here — R05 owns the sync/async execution model — but the exit *codes* are the
same on both paths, which is the part P2 requires to agree.

**What an installed handler buys, given the default already yields 130.** Under
the default disposition a `SIGINT`-killed process is terminated *by the signal*,
and the shell reports that as 128+signal = 130. Measured directly, avoiding the
shell's own job-control semantics: a `sleep 30` child spawned with `SIGINT`
explicitly restored to `SIG_DFL` and then signalled had a wait-status of **-2** —
killed by signal 2 — which is exactly what a shell renders as 130. (An earlier
attempt to measure this with `sleep 30 & kill -INT` returned 0 and is **not**
cited as evidence: POSIX has a non-interactive shell's asynchronous list inherit
`SIG_IGN` for `SIGINT`, so that `sleep` ignored the signal and ran to completion.
That confound is recorded rather than dropped because it is the same mechanism as
the tradeoff noted in this member's `Tradeoffs`.) The handler is therefore not
there to produce the number. It buys three things this template needs:
destructors run (measured — the `Drop` guard printed `cleanup-ran` on both
signals, which a `process::exit(130)` would have skipped), the code is
deterministic for integration tests rather than shell-dependent, and a terminal
left in raw mode by an interactive prompt (R61) or a spinner (R63) gets restored.
The design is a **cooperative cancel flag**, not `process::exit` inside the
handler: the handler stores the signal number in an `AtomicI32` and the work loop
observes it, so unwinding is normal.

**BASELINE-REVIEW finding.**

BASELINE-REVIEW: F301 — an unexpected error's stack trace reaches the user only when they asked for diagnostics — keep the row's *existence* settled but assign its acceptance criteria to R67, namely (a) the capture mechanism and (b) whether machine (JSON) mode suppresses the trace — evidence: display gating is not implementable alone in Rust because capture is environment-gated, measured on this run with the recommended stack: with `RUST_BACKTRACE` unset the persisted report was 5 lines and contained no backtrace, and with `RUST_BACKTRACE=1` the same code path produced a 15-line report containing `Stack backtrace` (`anyhow` 1.0.104, `rustc` 1.98.0, 2026-09-05), consistent with `https://doc.rust-lang.org/std/backtrace/index.html` (retrieved 2026-09-05); and the two sources disagree on (b), py `src/py_launch_blueprint/cli/options.py:227-228` printing the traceback with no mode check while ts `src/router.ts:210-218` returns before the trace gate at `:223`.

This restates the proposal already recorded at `docs/port/BASELINE-REVIEW.md:154`
and its owner question at `:194`; I add the measured capture evidence. Because
that disposition is the owner's and is still open, F301 is treated below as a
**stated assumption**, not a recommendation: the recommended design captures no
backtrace unless `RUST_BACKTRACE`/`RUST_LIB_BACKTRACE` is set, and does not
suppress the trace in machine mode because the trace never reaches the envelope —
it goes only to the crash log. If the owner accepts the amendment, R67 should
publish those two rules; if not, they remain implementation choices.

**Maturity, dependability and integration cost, compared.** Figures per member in
`### Members`. Summarized: `thiserror` and `anyhow` are the same maintainer
(dtolnay) with 349.6M and 206.4M 90-day downloads respectively, both `MIT OR
Apache-2.0`, both with declared MSRVs far under the 1.96 floor (1.71 and 1.68).
The one dependability finding worth flagging is **RUSTSEC-2026-0190**, an
unsoundness in `anyhow::Error::downcast_mut()` (type `INFO`/`Unsound`, category
`memory-corruption`), **patched in >= 1.0.103**; the current release is 1.0.104,
and the recommended design calls `downcast_ref`, never the affected
`downcast_mut`. The gate is therefore passed twice over — by version and by
non-use — but the template must pin `anyhow >= 1.0.103` explicitly rather than
`1.0`.

**Performance.** Stated with workload and instrumentation, as required, and
deliberately *not* used to rank candidates: the workload is process startup and a
single terminal failure per run, so throughput is not a meaningful axis. What is
measurable and does matter is build cost, which every contributor pays on every
clean CI run. Measured on this host (Apple Silicon, macOS 25.4, `cargo 1.98.0`,
`--release`, from `cargo clean`): the full two-crate workspace with `thiserror`
2.0.20 + `anyhow` 1.0.104 + `signal-hook` 0.4.4 + `ctrlc` 3.5.2 + `serde_json`
1.0.151 built in **4.40 s wall / 12.60 s user**, producing a **596,400-byte**
stripped-by-default release binary over **31** unique normal dependencies.
Per-crate subtree cost, from `cargo tree -e normal -p <crate>`: `anyhow` **1**
crate (itself, zero dependencies), `signal-hook` **4**, `serde_json` **5**,
`thiserror` **8** (its proc-macro chain), `ctrlc` **10** (it pulls `nix`). That
last number is a decision input: `ctrlc` costs more than `signal-hook` *and*
cannot distinguish signals.

**Minimal realistic example.** A two-crate workspace — `rslb-core` (library, owns
the enum and catalog) and `rslb-cli` (binary, owns the boundary) — was written
and built for this run; its full text and the commands run against it are in
`### Validation strategy`. It is minimal in surface but realistic in shape: it
exercises the library/binary split, the JSON envelope, both signals, EPIPE, the
crash log and the append-only catalog test.

### Recommendation

One stack, seven slots. The versions below are **minimum** versions: a Cargo
requirement such as `"1.0.104"` is a caret floor (`>=1.0.104, <2.0.0`), not a
pin, which is what the `anyhow` advisory floor below needs.

```toml
# library crate (rslb-core) — no dependency on the application-error crate
[dependencies]
thiserror = "2.0.20"

# binary crate (rslb-cli)
[dependencies]
anyhow      = "1.0.104"   # >= 1.0.103 required: RUSTSEC-2026-0190
signal-hook = "0.4.4"     # unix; the web surface uses tokio::signal (R05)
serde_json  = "1.0.151"   # the F294 envelope, already settled
etcetera    = "0.11.0"    # crash-log directory — assumption, see R57
```

Everything else in the contract is **std**, deliberately: the exit-code taxonomy
is a `#[repr(u8)]` enum returned as `std::process::ExitCode`, broken-pipe handling
is an `io::ErrorKind::BrokenPipe` check, and the crash log is a best-effort
`std::fs` append. Three crates that a reader would expect to see here —
`strum`, `exitcode`/`sysexits`, and `human-panic` — are each excluded for a
specific measured reason given in their member sections.

The contract this stack publishes:

- **Codes**: `RSLB###`, stable and append-only, pinned by a unit test. `RSLB000`
  is UNEXPECTED (py's `PLBP000` analogue). Blocks: `RSLB1xx` runtime (I/O, API),
  `RSLB2xx` usage and config input, `RSLB3xx` not found, `RSLB4xx` auth,
  `RSLB5xx` conflict, `RSLB9xx` cancellation. The block digit equals the exit
  code for `RSLB1xx`-`RSLB5xx` (`RSLB000` is the UNEXPECTED sentinel and maps to
  exit 1), which is a mnemonic, not the mechanism — the
  mechanism is the `exit()` match, and the `CATALOG` test is what enforces it.
- **Exit codes**: `0` success, `1` error, `2` usage, `3` not found, `4` auth,
  `5` conflict, `130` SIGINT, `143` SIGTERM — ts's cli-standards R6.1 taxonomy
  (D-016(2)) adopted unchanged.
- **Hint**: a structured `const fn hint() -> Option<&'static str>`, rendered as a
  separate `hint` key in JSON and a separate line in human output.

### Members

Seven members: two crates for the error layers, one crate for signals, one crate
for the prompt-cancellation surface, and three patterns whose recommendation is
`std` and which therefore state crate figures as `inapplicable` with the reason.

#### thiserror

##### Landscape

Category: the **domain error carrier** — the type the library crate returns, and
therefore the thing that physically holds the stable code catalog (F295) and the
structured hint (F296). Bin 1 (built-in) holds hand-written `impl std::error::Error`
plus `impl Display`, which needs no crate at all. Bin 2 (established) holds
`thiserror` and `snafu`; `miette` also derives an error type but is really a
*reporter*. Bin 3 (up-and-comer) holds nothing credible in this slot — the
derive-macro approach settled years ago and the field has consolidated rather
than churned.

##### Principles and implementation

Serves P1 (stable identity) and P3 (addressable remedy). The crate itself supplies
only `#[derive(Error)]` — `Display` from an `#[error("…")]` attribute and
`source()` from `#[source]`/`#[from]`. It deliberately supplies **nothing** for
the code catalog, which is the correct division: the catalog is `const fn code()`,
`const fn hint()` and `const fn exit()` written by hand on the same enum, each a
total match so the compiler rejects a new variant that was not assigned a code.
`#[non_exhaustive]` on the enum keeps adding a variant a non-breaking change for
downstream crates, which is what "append-only" means at the Rust API level as
opposed to the wire level. The wire-level guarantee is the `CATALOG` pin test.

##### Dominant choice

`thiserror` 2.0.20. 90-day downloads **349,580,121**; all-time **1,414,954,204**
(`GET https://crates.io/api/v1/crates/thiserror`, `crate.recent_downloads` /
`crate.downloads`, 2026-09-05). Last release **2.0.20**, `created_at`
**2026-08-08T06:22:23.795550Z** (newest `yanked: false` from
`GET https://crates.io/api/v1/crates/thiserror/versions`, 2026-09-05). Stars
**5,534**, `archived: false`, `pushed_at` **2026-09-05T05:32:25Z**
(`GET https://api.github.com/repos/dtolnay/thiserror`, 2026-09-05). Open issues
**27** (`GET https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open`,
`total_count`, 2026-09-05). Issue responsiveness over the 10 most recently opened
issues: median **0.2 days** to first maintainer response, **7** with no maintainer
comment — that unanswered count overstates neglect for this maintainer, who
commonly closes an issue by referencing it from a fix commit rather than
commenting; `pushed_at` the same day as retrieval is the stronger liveness signal.
Advisories: **none** (`https://rustsec.org/packages/thiserror.html` returns HTTP
404, 2026-09-05; see the 404 rule in `### Sources`). Maintenance: **active** —
released within the last month and pushed the day of retrieval.

Adopters, each verified by reading the project's own `Cargo.toml` on 2026-09-05:
Cargo `thiserror = "2.0.18"`
(`https://raw.githubusercontent.com/rust-lang/cargo/master/Cargo.toml`) — relevant
because it is the Rust project's own tool; Ruff `thiserror = "2.0.0"`
(`https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml`) — a
large, fast-growing Rust CLI with a published library surface, the closest analogue
to this template's shape; Nushell `thiserror = "2.0.20"`; cargo-nextest
`thiserror = "2.0.20"`; bat `thiserror = "2.0"`.

##### Qualified shortlist

`snafu` 0.9.2 (16,745,357 90-day; 107,018,028 all-time; released 2026-07-21;
`MIT OR Apache-2.0`; `rust_version` 1.65; 1,897 stars, `archived: false`,
`pushed_at` 2026-07-21; 82 open issues; no advisory — 404; responsiveness over the
10 most recently opened issues, of which only **4** were issues rather than PRs:
median **0.4 days**, 2 unanswered — a small sample, stated as such). Gates: 1 pass, 2 pass
(1.65 ≤ 1.96), 3 pass, 4 pass, 5 default features include `std`/`rust_1_65`, 6
heavier than `thiserror` (context-selector types are generated per variant).
Qualified but not chosen: its context-selector model is a genuinely different
ergonomic bet that adds a generated type per variant, and it has ~5% of
`thiserror`'s adoption with no compensating capability for a *catalog*, which is
hand-written either way.

Hand-written `impl Error + Display` with no crate (bin 1). Gates: all
`inapplicable` — no dependency. Qualified: it produces an identical public API and
removes 8 crates from the tree. Not chosen because the `#[error("…")]` attribute
keeps each variant's message adjacent to its `code()` and `hint()` rows, which is
exactly the review property this catalog needs; hand-writing `Display` for ~10
variants is 60 lines of boilerplate that hides that adjacency.

##### Excluded by gate

**None.** No candidate in this slot fails any of the six gates. Two crates a
reviewer would expect to see here are recorded below with the actual reason they
are not chosen, which is fitness rather than a gate.

`miette` 7.6.0 — **passes every gate**, including gate 1. `license = "Apache-2.0"`
(crates.io `/versions`, 2026-09-05; `spdx_id: Apache-2.0` on GitHub) is compatible
with an `MIT OR Apache-2.0` project: a dependency's license governs that
dependency, not this repository's own licensing, and `docs/port/PARAMETERS.md`
states that "every MIT-compatible crate is also compatible with the dual license".
An earlier draft of this member excluded it on gate 1; that was wrong and is
corrected here. It is not chosen on **fit**: `miette` is a diagnostic *reporter*,
not a domain-error carrier, so it answers a different question than this slot
asks — which is why cargo-nextest and Nushell use it *alongside* `thiserror`
rather than instead of it. Figures: 16,595,728 90-day; 71,673,425 all-time; 7.6.0
released 2025-04-27; `rust_version` 1.70.0; 2,601 stars, `archived: false`,
`pushed_at` 2026-06-25; 91 open issues; no advisory (404). Responsiveness over
the 10 most recently opened issues: **no maintainer response on any of the 10**,
so the median is `inapplicable` for want of a single data point — the weakest
responsiveness figure measured anywhere in this bundle, and an independent reason
not to place it on the library crate's critical path.

`strum` 0.28.0 — **not a gate failure; excluded on fitness**, recorded here
because the prompt names it. Gates: 1 `license = "MIT"` (compatible), 2 pass
(`rust_version` 1.71), 3 no advisory (404), 4 pass, 5 no async coupling, 6 a
proc-macro chain comparable to `thiserror`'s. Figures: 134,420,790 90-day;
612,038,740 all-time; 0.28.0 released 2026-02-22; 2,434 stars, `archived: false`;
`pushed_at` 2026-03-07; 59 open issues; responsiveness over the 10 most recently
opened issues (8 were issues rather than PRs) median **2.5 days**, 6 unanswered. Excluded because using it for this slot means deriving
the code from the **variant identifier**, which makes a compiler-checked rename a
silent wire-breaking change — the precise defect this item exists to fix in ts
(`src/router.ts:211`). `strum` remains a fine choice elsewhere in the template for
non-contractual enum-to-string conversion; it must not carry the catalog.

##### Up-and-comers

None in this slot. This is a finding, not an omission: the derive-error field
consolidated on `thiserror` and `snafu`, and the recent movement in Rust error
handling has been in *reporting* (`miette`, `color-eyre`), which is a different
slot. Nothing surveyed in bin 3 competes for the domain-carrier role.

##### Fit for this template

Fits all three surfaces from one definition. The **library** crate exports the
enum, so a library consumer matches variants directly. The **CLI** downcasts to
it at the boundary. The **web service** (R69/R70) needs an exhaustive match to
build its status table — R70's `ERROR_STATUS` analogue — and an exhaustive `match`
over a `thiserror` enum is exactly that, checked by the compiler rather than by a
dictionary lookup that can silently miss a variant (which is what py's
`ERROR_STATUS: dict[type[PyError], int]` risks). `#[non_exhaustive]` requires
downstream matches to carry a wildcard arm, which is the correct trade for an
append-only catalog.

##### Recommendation

`thiserror = "2.0.20"` in the **library** crate only. Define one
`#[non_exhaustive] enum CoreError` with `const fn code() -> &'static str`,
`const fn hint() -> Option<&'static str>` and `const fn exit() -> Exit`, plus a
`pub const CATALOG: &[(&str, Exit)]` and the three pin tests. The library crate
must not depend on `anyhow`.

##### Ranked runner-up

1. Hand-written `impl Error`/`impl Display`, no crate — identical public API,
   8 fewer crates, more boilerplate. Reach for it only if R02 concludes the
   library crate should be dependency-free.
2. `snafu` 0.9.2 — viable, differently ergonomic, far less adopted.

##### Tradeoffs

Costs a proc-macro subtree: `cargo tree -e normal -p thiserror` reports **8**
unique crates (measured 2026-09-05 on the built workspace), which is compile time
paid on every clean build. Gains a single place where message, code, hint and exit
code sit together per variant. `unsafe` posture: **zero** occurrences of `unsafe`
in `thiserror` 2.0.20's `src/` (measured by grep over the vendored source at
`~/.cargo/registry/.../thiserror-2.0.20/src`, 2026-09-05); the crate declares no
`#![forbid(unsafe_code)]`, so this is an observed property, not a guaranteed one.
Default features `default = ["std"]`, `std = []` — no async-runtime coupling
whatsoever.

##### Parameters

Owns no repo-wide parameter. Contributes the `code` catalog and the `hint` field
to `error-taxonomy-exit-codes`. No `CONFLICT:`.

##### Migration implications

New file `crates/core/src/error.rs` defining `CoreError`, `Exit`, `CATALOG`,
`CODE_UNEXPECTED`, and the three catalog tests. `crates/core/Cargo.toml` gains
`thiserror = "2.0.20"`. A new documentation page listing the catalog, generated
from or checked against `CATALOG`.

##### Validation strategy

Executed on this run: 3 unit tests over the catalog — pinned rows unchanged,
every constructible variant registered with a matching exit code, codes unique —
`cargo test -p rslb-core` → **3 passed; 0 failed**. Planned for the template:
extend the pin test to assert against a checked-in `catalog.json` so a reviewer
sees the wire contract change in the diff.

##### Confidence & re-verify trigger

**High.** Re-verify if `thiserror` 3.x ships (a major bump could change derive
semantics), if a RustSec advisory is filed against it, or if R02 rules the library
crate must have zero dependencies — which would promote the hand-written runner-up
without changing any observable behavior.

##### Sources

`https://crates.io/api/v1/crates/thiserror` and `/versions` (2026-09-05);
`https://api.github.com/repos/dtolnay/thiserror` (2026-09-05);
`https://api.github.com/search/issues?q=repo:dtolnay/thiserror+is:issue+is:open`
(2026-09-05); `https://rustsec.org/packages/thiserror.html` → HTTP 404
(2026-09-05); `https://docs.rs/thiserror/2.0.20/thiserror/` (2026-09-05);
adopter manifests `rust-lang/cargo`, `astral-sh/ruff`, `nushell/nushell`,
`nextest-rs/nextest`, `sharkdp/bat` via `raw.githubusercontent.com` (2026-09-05);
vendored source at `~/.cargo/registry/src/index.crates.io-*/thiserror-2.0.20/`
(2026-09-05); `docs/port/COMMONALITY.md:299-300` (F295, F296);
`docs/port/DIVERGENCE-ANALYSIS.md:209-210`.

#### anyhow

##### Landscape

Category: the **application-boundary error carrier** — the type `main` and the
command layer return, which accumulates human context across call sites and is
downcast at the boundary. Bin 1 holds `Box<dyn std::error::Error + Send + Sync>`,
which works and needs no crate. Bin 2 holds `anyhow` and its fork `eyre` with the
reporter `color-eyre`. Bin 3 holds nothing new; `miette` overlaps as a reporter.

##### Principles and implementation

Serves P1's *fallback* half: the code catalog covers modelled failures, and
everything else must still get a code, which is `CODE_UNEXPECTED` (`RSLB000`,
py's `PLBP000` analogue). `anyhow` supplies the context chain (`.context("…")`)
whose rendering — `{err:#}` for one line, `{err:?}` for the multi-line
`Caused by:` block — decides what the envelope's `message` says and what the crash
log stores. Measured on this run: `{err}` alone yields `"loading the project
index"`, losing the cause; `{err:#}` yields `"loading the project index: No such
file or directory (os error 2)"`. **The envelope must use `{err:#}`** — with
`{err}` the machine-readable envelope silently drops the actual failure, which
would defeat F294's purpose. This is a concrete design rule that only surfaced
because the example was actually run.

##### Dominant choice

`anyhow` 1.0.104. 90-day downloads **206,370,924**; all-time **930,960,089**
(`GET https://crates.io/api/v1/crates/anyhow`, 2026-09-05). Last release
**1.0.104**, `created_at` **2026-07-18T20:59:37.656167Z** (newest
`yanked: false`, `/versions`, 2026-09-05). Stars **6,646**, `archived: false`,
`pushed_at` **2026-08-22T02:43:42Z**
(`GET https://api.github.com/repos/dtolnay/anyhow`, 2026-09-05). Open issues
**37** (`search/issues?q=repo:dtolnay/anyhow+is:issue+is:open`, `total_count`,
2026-09-05). Responsiveness over the 10 most recent issues (8 were issues rather
than PRs): median **0.2 days**, **4** without a maintainer comment — same
close-by-commit caveat as `thiserror`. Maintenance: **active**.

**Advisory — the one dependability finding in this bundle.**
`https://rustsec.org/packages/anyhow.html` (HTTP 200, 2026-09-05) lists
**RUSTSEC-2026-0190**, "Unsoundness in `Error::downcast_mut()`", reported
2026-06-25, issued 2026-06-29, type `INFO`, categories `memory-corruption`,
keyword `#unsound`, **patched `>=1.0.103`**, affected function
`anyhow::Error::downcast_mut` below 1.0.103
(`https://rustsec.org/advisories/RUSTSEC-2026-0190.html`, 2026-09-05). Gate 3 is
passed on two independent grounds: the pinned version 1.0.104 is above the patch
floor, and the recommended design calls `downcast_ref`, never `downcast_mut`. The
actionable consequence is that the manifest must pin `anyhow = "1.0.104"` (or at
minimum `>=1.0.103`), not `"1.0"`, and `cargo deny`/`cargo audit` (R13) must run
in CI to catch the next one.

Adopters verified from their own `Cargo.toml` (2026-09-05): ripgrep
`anyhow = "1.0.75"`, Cargo `anyhow = "1.0.102"`, Nushell `anyhow = "1.0.104"`,
Ruff `anyhow = "1.0.80"`, bat `anyhow = "1.0.97"`, fd `anyhow = "1.0"`. Six of the
seven surveyed projects, including the Rust project's own build tool.

##### Qualified shortlist

`eyre` 0.6.14 + `color-eyre` 0.6.5. Figures: `eyre` 19,803,808 90-day /
111,411,968 all-time, 0.6.14 released 2026-08-11, `MIT OR Apache-2.0`,
`rust_version` 1.65.0, 1,778 stars, `archived: false`, `pushed_at` 2026-08-11,
39 open issues, responsiveness median **5.4 days** with **7 of 8** recent issues
unanswered — the weakest figure among the qualified error-carrier candidates; `color-eyre` 12,814,782 90-day / 66,888,135 all-time, 0.6.5
released 2025-05-30, `MIT OR Apache-2.0`, `rust_version` 1.65.0. Advisory:
`https://rustsec.org/packages/eyre.html` (HTTP 200, 2026-09-05) lists
**RUSTSEC-2024-0021**, "Parts of Report are dropped as the wrong type during
downcast", type `Vulnerability`, patched `>=0.6.12`, unaffected `<0.6.9` — clean
at 0.6.14. Gates: all pass. Qualified and genuinely attractive: `eyre`'s pluggable
report handler is the cleanest way to make the trace/report format a policy the
template owns. Not chosen because `color-eyre`'s crate payload is **636,255
bytes** versus `anyhow`'s **48,819** (`crate_size` from `/versions`, 2026-09-05),
it is a heavier tree for a feature this item does not need yet, and `anyhow` is
what six of the seven surveyed reference projects use. cargo-nextest's use of
`color-eyre = "0.6.5"` is the counter-example and the reason it stays qualified.

`Box<dyn std::error::Error + Send + Sync>` (bin 1). Gates all `inapplicable`.
Qualified: zero dependencies, and `downcast_ref` works. Not chosen because it has
no context chain, so every call site would hand-format its own message and the
crash log would lose the `Caused by:` structure measured above.

##### Excluded by gate

None. No candidate in this slot fails a gate — `miette`'s Apache-2.0-only license
is not disqualifying for a *binary*-crate dependency, so it is not excluded here;
it simply loses on fit, being a reporter rather than a carrier.

##### Up-and-comers

None credible. This slot has been stable for years; the movement has been in
report *rendering*, which the template does not need until R66 decides the output
surface.

##### Fit for this template

Correct for the **CLI** binary, where it is the return type of the command layer.
Correct for the **web service** binary for startup and configuration failures.
**Explicitly wrong for the library crate**, and this is the load-bearing rule: if
`rslb-core` returned `anyhow::Error`, R70 could not build its status table and R03
could not distinguish absence from transport failure without string matching. The
library returns `Result<T, CoreError>`; only the binaries see `anyhow`.

##### Recommendation

`anyhow = "1.0.104"` in the **binary** crates only, pinned at or above 1.0.103.
Render the envelope message with `{err:#}` and the crash log with `{err:?}`.
Resolve the exit code in this precedence: signal → broken pipe → `downcast_ref::<CoreError>()`
→ `CODE_UNEXPECTED`.

##### Ranked runner-up

1. `eyre` 0.6.14 + `color-eyre` 0.6.5 — adopt if the template later wants an
   owned report format; costs ~13x the crate payload.
2. `Box<dyn Error + Send + Sync>` — adopt only under a zero-dependency mandate.

##### Tradeoffs

Cheapest possible tree: `cargo tree -e normal -p anyhow` reports **1** crate —
itself, with zero dependencies (measured 2026-09-05). Default features
`default = ["std"]`, plus a `backtrace` feature; **no async-runtime coupling**.
`unsafe` posture: **103** occurrences of `unsafe` in `anyhow` 1.0.104's `src/`
(measured by grep over the vendored source, 2026-09-05), concentrated in the
type-erasure code in `src/ptr.rs` — this is inherent to its single-pointer-width
representation and is exactly where RUSTSEC-2026-0190 was found. That is the
honest cost of the crate: a hand-rolled `Box<dyn Error>` has none. The mitigation
is version pinning plus `cargo audit` in CI, not avoidance.

##### Parameters

Owns no repo-wide parameter. Contributes `CODE_UNEXPECTED` and the boundary
precedence rule to `error-taxonomy-exit-codes`. No `CONFLICT:`.

##### Migration implications

`crates/cli/Cargo.toml` and `crates/web/Cargo.toml` gain `anyhow = "1.0.104"`.
New `crates/cli/src/main.rs` returning `std::process::ExitCode` with the
four-step `report()` function. A deny-list entry (R28/R13) forbidding `anyhow` in
`crates/core/Cargo.toml` so the layering cannot regress silently.

##### Validation strategy

Executed: an unexpected `io::Error` raised through `?` with `.context("loading
the project index")` produced
`{"error":{"code":"RSLB000","message":"loading the project index: No such file or
directory (os error 2)"}}` on stderr with exit **1** and a crash log containing
the `Caused by:` chain. Also executed: `{err}` vs `{err:#}` rendering compared
directly, which is what established the `{err:#}` rule. Planned: a CI check that
`crates/core` has no `anyhow` dependency.

##### Confidence & re-verify trigger

**High**, with one standing watch. Re-verify on any new RustSec advisory for
`anyhow` (this run found one), on a 2.x release, or if R05 selects an async model
that makes `eyre`'s report handler valuable for span capture.

##### Sources

`https://crates.io/api/v1/crates/anyhow` and `/versions` (2026-09-05);
`https://api.github.com/repos/dtolnay/anyhow` (2026-09-05);
`https://api.github.com/search/issues?q=repo:dtolnay/anyhow+is:issue+is:open`
(2026-09-05); `https://rustsec.org/packages/anyhow.html` and
`https://rustsec.org/advisories/RUSTSEC-2026-0190.html` (2026-09-05);
`https://rustsec.org/packages/eyre.html` and
`https://rustsec.org/advisories/RUSTSEC-2024-0021.html` (2026-09-05);
`https://crates.io/api/v1/crates/eyre|color-eyre` and `/versions` (2026-09-05);
adopter manifests for ripgrep, Cargo, Nushell, Ruff, bat, fd (2026-09-05);
vendored source `~/.cargo/registry/src/index.crates.io-*/anyhow-1.0.104/`
(2026-09-05).

#### Exit-code taxonomy (pattern: `#[repr(u8)]` enum returned as `std::process::ExitCode`)

##### Landscape

Category: the **exit-code taxonomy and its carrier** (F297). Two questions, often
conflated. *Which integers* is a taxonomy question with three candidate answers:
py's `SUCCESS/CONFIG/AUTH/API/IO/INTERRUPT` (0-5), ts's cli-standards R6.1 set
(0,1,2,3,4,5,130,143), or the BSD `sysexits.h` set (64-78). *How the integer
reaches the OS* is a mechanism question: bin 1 has `std::process::ExitCode` +
`Termination` (stable since Rust 1.61) and `std::process::exit`; bin 2 has
`exitcode`, the crate the CLI-WG book names; bin 3 has `sysexits`, a modern typed
re-do of the same BSD table.

##### Principles and implementation

This member carries P2, the one principle whose agreement level is "one value for
all three repos" (`DIVERGENCE-ANALYSIS.md:211-212`, class **A** setting drift,
harmonize **yes**, Rust question recorded as "none — inherit the cli-standards
taxonomy ts already adopted"). Under owner amendment A5 a recorded "none" is a
baseline claim to assess, not an exemption, so it is assessed here rather than
inherited: does the cli-standards taxonomy actually fit Rust, or does the Rust
ecosystem pull toward BSD `sysexits`?

**It fits, and the evidence is the CLI parser.** Measured on this run with
`clap` 4.6.6 (the framework R60 is most likely to select): a missing required
argument exits **2**, an unknown flag exits **2**, and `--help` exits **0**.
cli-standards R6.1 assigns usage → 2. They already agree. The BSD table does not:
measured in the same session, `sysexits::ExitCode::Usage as u8` is **64** and
`exitcode::CONFIG` is **78**. Adopting BSD would mean either overriding clap's
built-in behavior on every usage error or shipping a CLI whose usage errors exit
2 while its documented taxonomy says 64. That is a decisive fit argument for
cli-standards that is independent of the org mandate — the two happen to agree,
and the agreement is worth recording because it means P2 costs nothing in Rust.

For the *carrier*, `main() -> ExitCode` is preferred over `std::process::exit`
because `process::exit` terminates without unwinding, so destructors do not run.
Measured: the recommended design printed `cleanup-ran` from a `Drop` guard on
both the SIGINT and SIGTERM paths; a `process::exit` inside the signal handler
would not have. This matters directly for R61 (restoring terminal state) and R63
(clearing a spinner). ripgrep's `fn main() -> ExitCode` is the reference.

##### Dominant choice

The pattern: a `#[repr(u8)]` enum `Exit { Success=0, Error=1, Usage=2,
NotFound=3, Auth=4, Conflict=5, Sigint=130, Sigterm=143 }` with
`impl From<Exit> for std::process::ExitCode`, returned from `main`. **No crate.**

Crate figures: **inapplicable** — the recommendation is a `std` pattern with no
dependency, so `recent_downloads`, `downloads`, last release, stars, open issues
and reverse dependencies have no subject. The gates resolve as: 1 license
`inapplicable` (no third-party code); 2 MSRV — `ExitCode` and `Termination` are
stable since Rust **1.61**, far below the 1.96 floor, so pass; 3 advisories
`inapplicable` (nothing to advise on), `unsafe` posture **none used**; 4 platform
— `ExitCode::from(u8)` is stable on both `ubuntu-latest` and `macos-latest` and
on Windows; 5 no features, no async coupling; 6 zero binary-size and zero
compile-time cost.

Practice evidence for the pattern rather than downloads: ripgrep's
`crates/core/main.rs` is `fn main() -> ExitCode` returning `ExitCode::from(0)`
and `ExitCode::from(2)`
(`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/main.rs`,
read 2026-09-05).

##### Qualified shortlist

`sysexits` 0.13.0 — 208,587 90-day / 1,524,626 all-time; released 2026-02-28;
`license = "Apache-2.0 OR MIT"`; `rust_version` **1.87.0**; `edition = "2024"`;
33 stars, `archived: false`, `pushed_at` 2026-08-30; **0** open issues; no
advisory (404). Gates 1-6 all pass (1.87.0 ≤ 1.96); it builds and runs on this
host's stable 1.98 (executed). Maintenance: **active** by the rubric — recently
released and pushed — though 33 stars and 0 issues mean the responsiveness metric
is `inapplicable` for want of data. Qualified, and technically the best-packaged
crate in this slot. Not chosen because it encodes the *wrong table* for this
template, per the clap measurement above.

`exitcode` 1.1.2 — 824,414 90-day / 8,983,053 all-time; released
**2017-06-18T18:21:36.405587Z**; `license = "Apache-2.0"`; no declared
`rust_version`; 79 stars, `archived: false`, `pushed_at` **2022-09-06**; **0**
open issues; no advisory (404). Maintenance: **stable-quiet**. The rubric says no
release in 6 months is a trigger to investigate, never the verdict, so:
investigated. The crate is a frozen table of `pub const` integers; it has no
open issues, no advisory, and it **compiles and runs correctly on stable 1.98.0
inside an edition-2024 workspace** (executed this run — `exitcode::OK` printed 0
and `exitcode::CONFIG` printed 78). None of the `dormant` triggers is present, so
`stable-quiet` is the verdict despite a nine-year-old release. Same disposition as
`sysexits`: right maintenance state, wrong table.

##### Excluded by gate

None. Both crate candidates pass every gate; they lose on fit, and recording them
as gate failures would misstate the reason.

##### Up-and-comers

`sysexits` (bin 3) is the only up-and-comer, covered above. Its edition-2024,
`rust_version`-declaring packaging is the modern shape this template's own crates
should imitate — a useful observation even though the crate is not adopted.

##### Fit for this template

The taxonomy must serve all three surfaces. **CLI**: 0-5 plus 130/143 are what a
shell and a test harness observe. **Library**: `Exit` is exported so a library
consumer embedding the tool can reuse the mapping without re-deriving it, and
because R70 needs `CoreError::exit()` to be a public total function. **Web
service**: the process-level codes apply to startup failure and shutdown; the
per-request mapping is R70's, and R70 consumes the *variants*, not these
integers. Assigning `Usage = 2` to config-input errors (`RSLB2xx`) is the one
judgment call the sources leave open — py mapped config to 1, ts's D-016(2) record
assigns usage → 2 without naming config. Config-file content is user-supplied
input, so it belongs with usage; R55 may refine which config failures are
tolerated, but the code they map to when they do fail is fixed here.

##### Recommendation

Adopt ts's cli-standards R6.1 taxonomy unchanged — `0` success, `1` error, `2`
usage, `3` not found, `4` auth, `5` conflict, `130` SIGINT, `143` SIGTERM — as a
`#[repr(u8)]` enum in the library crate, converted via
`impl From<Exit> for std::process::ExitCode` and returned from `main`. Add **no
crate**. Adopt **no** BSD `sysexits` codes. Reject py's 0-5 mapping: it is not
wrong in itself, but it is the repo that has *not* been reconciled against the
org-normative spec, and P2's agreement level is "one value for all three repos".

##### Ranked runner-up

1. `sysexits` 0.13.0 with the cli-standards values ignored — only if the owner
   reverses D-016(2) toward BSD semantics.
2. `exitcode` 1.1.2 — same, with an older packaging story.

##### Tradeoffs

Zero dependency cost, zero compile cost, zero `unsafe`. The cost is that the
integers are hand-maintained rather than imported, which is precisely why the
`CATALOG` pin test exists. Second trade: returning `ExitCode` from `main` means
the exit code must be *plumbed* back rather than shouted from anywhere in the
program via `process::exit` — more discipline, and it is what makes destructors
run.

##### Parameters

This member supplies the exit-code half of `owns error-taxonomy-exit-codes`. No
`CONFLICT:` — the taxonomy is inherited from an owner-normative spec, not from a
consumed parameter.

##### Migration implications

`crates/core/src/error.rs` gains the `Exit` enum and the `From<Exit> for
ExitCode` impl. `crates/cli/src/main.rs` is `fn main() -> ExitCode`. Any
`std::process::exit` call is forbidden by lint (R28). The catalog documentation
page gains the exit-code column.

##### Validation strategy

Executed: five exit codes observed end-to-end from the built binary — config **2**,
not-found **3**, auth **4**, conflict **5**, unexpected **1** — plus clap 4.6.6
measured at **2** for both a missing required argument and an unknown flag, and
`sysexits`/`exitcode` measured at **64**/**78** for the same conditions. Planned
for the template: a table-driven integration test asserting one exit code per
catalog row, so `CATALOG` and the binary cannot drift.

##### Confidence & re-verify trigger

**High.** Re-verify if R60 selects a CLI parser that does *not* exit 2 on usage
errors (the clap measurement is the fit argument, and it would no longer hold), or
if the owner revisits D-016(2).

##### Sources

`https://rust-cli.github.io/book/in-depth/exit-code.html` (2026-09-05);
`https://doc.rust-lang.org/std/process/struct.ExitCode.html` (2026-09-05);
`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/main.rs`
(2026-09-05); `https://crates.io/api/v1/crates/sysexits`, `/exitcode` and their
`/versions` (2026-09-05); `https://api.github.com/repos/sorairolake/sysexits-rs`,
`.../repos/benwilber/exitcode` (2026-09-05);
`https://rustsec.org/packages/sysexits.html`, `.../exitcode.html` → HTTP 404
(2026-09-05); executed clap/sysexits/exitcode measurements, this run, `rustc`
1.98.0; `docs/port/DIVERGENCE-ANALYSIS.md:211-212`; `docs/port/COMMONALITY.md:301`.

#### signal-hook

##### Landscape

Category: **process-signal handling** (F298) — receiving `SIGINT` and `SIGTERM`
and turning each into its own exit code. Bin 1 holds the default disposition (no
code at all) and raw `libc::signal`/`sigaction` behind `unsafe`. Bin 2 holds
`ctrlc`, which the Rust CLI-WG book names, and `signal-hook`. Bin 3 holds
nothing; for the async web surface `tokio::signal` is the in-runtime equivalent,
which R05 governs.

##### Principles and implementation

Serves P4 (predictable termination) with P2's integers. The CLI-WG book is
explicit that if an application "does not need to gracefully shutdown, the
default handling is fine". This template does need it — R61's prompts and R63's
spinner put the terminal in a modified state, and the web surface must drain on
`SIGTERM` — so a handler is warranted, and the book's own criterion is what
warrants it rather than a preference.

The implementation is a **cooperative cancel flag**: the handler stores the
signal number into an `AtomicI32` and returns; the work loop observes it and
returns an error, so unwinding is normal and destructors run. Async-signal-safety
requires this — a handler may call only async-signal-safe functions, so
formatting output or running arbitrary cleanup inside it is unsound.

##### Dominant choice

`signal-hook` 0.4.4. 90-day downloads **52,827,824**; all-time **232,694,095**
(`GET https://crates.io/api/v1/crates/signal-hook`, 2026-09-05). Last release
**0.4.4**, `created_at` **2026-04-04T08:08:58.259635Z** (`/versions`,
2026-09-05). `license = "MIT OR Apache-2.0"`, `rust_version` **1.66**. Stars
**866**, `archived: false`, `pushed_at` **2026-04-04T08:10:09Z**
(`https://api.github.com/repos/vorner/signal-hook`, 2026-09-05). Open issues
**22** (`search/issues?…`, `total_count`, 2026-09-05). Responsiveness over the 10
most recently opened issues: median **2.7 days**, only **2** unanswered — the best
answered-ratio of any crate measured in this bundle. Advisories: **none**
(`https://rustsec.org/packages/signal-hook.html` → HTTP 404, 2026-09-05).
Maintenance: **stable-quiet** — five months since the last release triggers
investigation, and the investigation finds an actively answered issue tracker, no
advisory, and a crate that builds and runs correctly on stable 1.98.0 (executed
this run). None of the `dormant` triggers is present and no concrete `at-risk`
signal exists, so `stable-quiet` is the verdict; it is a mature crate against a
stable POSIX API, where quiet is the expected state.

Gates: 1 pass (`MIT OR Apache-2.0`); 2 pass (1.66 ≤ 1.96); 3 pass, `unsafe`
posture **44** occurrences in `src/` (measured over the vendored source,
2026-09-05) — irreducible for this slot, since registering a handler is `unsafe`
by definition in Rust, and the `low_level::register` API is correctly marked
`unsafe` rather than hiding it; 4 pass — Unix (Linux and macOS) is its target, and
this run exercised it on macOS 25.4 while ripgrep-class projects exercise it on
Linux; **Windows: not supported by this crate** — noted, not required
(`target-os-matrix` is `ubuntu-latest, macos-latest`); 5 `default = ["channel",
"iterator"]`, both droppable with `default-features = false`, **no async-runtime
coupling**; 6 `cargo tree -e normal -p signal-hook` → **4** unique crates.

##### Qualified shortlist

`ctrlc` 3.5.2 — 21,098,753 90-day / 121,490,112 all-time; released 2026-02-10;
`license = "MIT/Apache-2.0"` in its own `Cargo.toml` (GitHub reports
`NOASSERTION` only because it cannot parse the deprecated slash form — verified by
reading the manifest, 2026-09-05, so gate 1 **passes**); `rust_version` 1.69.0;
667 stars, `archived: false`, `pushed_at` 2026-07-22; 11 open issues; median
**0.6 days** to first maintainer response with 7 of 10 uncommented; no advisory
(404). Maintenance: **active**. `unsafe`: **15** occurrences. Every gate passes.

Qualified, and it is what the CLI-WG book recommends — but it **cannot implement
this template's contract**, and the reason is in its own source:
`pub fn set_handler<F>(user_handler: F) -> Result<(), Error> where F: FnMut() +
'static + Send` — the callback takes **no signal argument**, and its docs state
that with the `termination` feature "the handler specified by `set_handler()`
will be executed for `SIGINT`, `SIGTERM` and `SIGHUP`"
(`https://raw.githubusercontent.com/Detegr/rust-ctrlc/master/src/lib.rs:44-46,93-95`,
read 2026-09-05). One handler for three signals with no way to ask which fired
means ts's distinct 130/143 split is unreachable. It also costs **10** unique
crates (it pulls `nix`) against `signal-hook`'s 4 — more cost for less capability.
It stays on the shortlist only for the narrower contract where SIGINT alone
matters.

Raw `libc`/`sigaction` (bin 1). Gates: `unsafe` throughout, everything else
`inapplicable`. Qualified as the zero-dependency floor. Not chosen: it would
re-implement `signal-hook`'s async-signal-safe registration and its
self-pipe/atomic plumbing, in `unsafe`, for no saving that matters against a
4-crate tree.

##### Excluded by gate

None. Every candidate passes every gate; `ctrlc` loses on an API capability, which
is a fitness finding, not a gate failure, and is recorded as such.

##### Up-and-comers

None in this slot. `tokio::signal` is the async-runtime-internal equivalent and is
not a competitor here — it is the *other half* of the answer once R05 and R69
settle the web surface, and it uses the same exit integers.

##### Fit for this template

**CLI**: `signal-hook` on the synchronous path, cooperative flag, exit 130/143.
**Library**: no signal handling at all — a library must never install a
process-global handler, so `rslb-core` gets none of this and only exports the
`Exit` values. **Web service**: `tokio::signal::unix::signal(SignalKind::terminate())`
inside the runtime rather than a second `signal-hook` registration, because two
mechanisms competing for the same signal is a defect. The **codes** agree across
both paths, which is what P2 requires; the **mechanism** differs, which is the
justified ecosystem difference. This is the one place where I make a
recommendation that reaches into R05/R69 territory, so it is stated as a
constraint on them, not a decision for them: whatever async model R05 picks must
produce 130 and 143.

##### Recommendation

`signal-hook = "0.4.4"` (Unix, CLI path), registered per signal number, storing
the number in an `AtomicI32` observed cooperatively by the work loop. Exit 130 for
`SIGINT`, 143 for `SIGTERM`. Do not call `process::exit` from the handler. Handle
**both** signals — correcting the prompt's premise that this template has "no
long-running daemon mode", since spec §4 D7 gives it a web service.

##### Ranked runner-up

1. `ctrlc = "3.5.2"` with the `termination` feature — only if the owner decides a
   single "terminated" code (130) is acceptable for both signals, collapsing ts's
   143.
2. Default disposition, no handler — only if R61 and R63 both conclude the
   template never modifies terminal state, which the spinner alone makes unlikely.

##### Tradeoffs

`unsafe` is unavoidable here and `signal-hook` surfaces it honestly at
`low_level::register`. 4 crates and negligible compile time. The cooperative-flag
design costs a polling site in every long-running loop — the price of running
destructors.

One behavioural tradeoff that is easy to miss and was found by reading the
source: `signal-hook-registry` 1.4.8 registers **unconditionally**. Its
`libc::sigaction(signal, &new, &mut old)` call captures the previous action into
`prev` so it can be restored on unregister, but it does **not** skip installation
when the inherited disposition is `SIG_IGN`
(`~/.cargo/registry/.../signal-hook-registry-1.4.8/src/lib.rs:197-203`, read
2026-09-05). Conventional Unix tools check the inherited action first and leave
`SIGINT` alone if it arrived ignored — which is why a `sleep` started as an
asynchronous list in a non-interactive shell does not die on Ctrl-C. `rslb` will
therefore respond to `SIGINT` in contexts where a traditional tool would not.
For a foreground CLI that is the behaviour users expect; for `rslb` invoked from
a script's background job it is a deliberate difference, and the template should
document it. Restoring the classic behaviour would mean querying the old action
with `sigaction(sig, NULL, &old)` and skipping registration when it is `SIG_IGN`
— not offered by `signal-hook`'s safe API, so it would need `libc` directly. Windows is unsupported, which is inside the owner's
`target-os-matrix`; if Windows were ever added, `ctrlc` (which supports Console
Handlers) would return as the cross-platform layer.

##### Parameters

Supplies the `130`/`143` half of `error-taxonomy-exit-codes`. States an assumption
on R05 (`sync-async-execution-model`): the web surface uses the runtime's own
signal source with the same codes. No `CONFLICT:` — R05 registers no parameter
this item consumes, and nothing R05 can decide requires these integers to change.

##### Migration implications

`crates/cli/Cargo.toml` gains `signal-hook = "0.4.4"` under
`[target.'cfg(unix)'.dependencies]`. `crates/cli/src/main.rs` gains the
registration block and the `AtomicI32`. Long-running loops gain a cancellation
check. The web crate gains a `tokio::signal` shutdown path (R69's file), not a
second `signal-hook` registration.

##### Validation strategy

Executed on this run: the built binary was backgrounded, sent `SIGINT`, and
`wait` reported **130**; the same binary sent `SIGTERM` reported **143**. In both
cases a `Drop` guard printed `cleanup-ran` to stderr before exit, proving the
cooperative design unwound normally rather than terminating abruptly. Planned for
the template: the same two assertions as integration tests, plus a web-surface
test that `SIGTERM` drains in-flight requests before exiting 143.

##### Confidence & re-verify trigger

**High** for the mechanism and codes; **medium** for the web half, which depends
on R05/R69 and was not executed here. Re-verify when R05 selects the async model,
if `signal-hook` 0.5 changes the registration API, or if Windows enters
`target-os-matrix`.

##### Sources

`https://crates.io/api/v1/crates/signal-hook` and `/versions` (2026-09-05);
`https://api.github.com/repos/vorner/signal-hook` (2026-09-05);
`https://api.github.com/search/issues?q=repo:vorner/signal-hook+is:issue+is:open`
(2026-09-05); `https://rustsec.org/packages/signal-hook.html` → 404 (2026-09-05);
`https://crates.io/api/v1/crates/ctrlc` and `/versions` (2026-09-05);
`https://api.github.com/repos/Detegr/rust-ctrlc` (2026-09-05);
`https://raw.githubusercontent.com/Detegr/rust-ctrlc/master/src/lib.rs` and
`/Cargo.toml` (2026-09-05);
`https://rust-cli.github.io/book/in-depth/signals.html` (2026-09-05); vendored
sources for `signal-hook-0.4.4` and `ctrlc-3.5.2` (2026-09-05);
`docs/port/COMMONALITY.md:302`; `docs/port/DIVERGENCE-ANALYSIS.md:212`.

#### Broken-pipe handling (pattern: `io::ErrorKind::BrokenPipe` on locked writers)

##### Landscape

Category: **EPIPE tolerance** (F300) — letting `rslb … | head` terminate the
producer cleanly instead of crashing. Bin 1 holds the `std` answer: check
`io::Error::kind() == ErrorKind::BrokenPipe` on every write, plus the **nightly**
`-Zon-broken-pipe` compiler flag (formerly `#[unix_sigpipe]`) that restores the C
default disposition. Bin 2 holds no established crate — this is a pattern, not a
market. Bin 3 holds `sigpipe`, a thin `unsafe` wrapper that calls
`libc::signal(SIGPIPE, SIG_DFL)`.

##### Principles and implementation

Serves P4. The mechanism is genuinely language-bound (class **C**,
`DIVERGENCE-ANALYSIS.md:214`), and Rust's position differs from *both* sources.
The Rust runtime sets `SIGPIPE` to `SIG_IGN` before `main` — a decision dating to
PR #13158 in 2014 and still open for review at `rust-lang/rust#62569`, "Should
Rust still ignore SIGPIPE by default?" (retrieved 2026-09-05). Consequently a
write to a closed pipe returns `Err(BrokenPipe)` rather than killing the process,
and — the part that bites — **`println!` panics on that error**. The tracking
issue `rust-lang/rust#97889` demonstrates it verbatim: `./main | head -n 1` →
`thread 'main' panicked at 'failed printing to stdout: Broken pipe (os error
32)'`. That issue is **open and unstabilized**, and its UI has moved from an
attribute to the `-Zon-broken-pipe` compiler flag (PR #124480), so under this
item's `Stable Rust only` constraint the language-level fix is **unavailable**.

Reproduced independently on this run rather than taken from the issue: a loop of
200,000 `println!` calls piped to `head -2` exited **101** (Rust's panic exit
code, as the CLI-WG book states) with that exact message on stderr; the identical
loop written with `writeln!` on `io::stdout().lock()` and a `BrokenPipe` check at
the boundary exited **0** with empty stderr.

##### Dominant choice

The pattern, in two halves. (1) All result output goes through `writeln!` on a
locked handle, never `println!`/`print!` — those macros panic. (2) At the `main`
boundary, walk `err.chain()`, `downcast_ref::<io::Error>()`, and on
`ErrorKind::BrokenPipe` return `ExitCode::from(0)`.

Crate figures: **inapplicable** — the recommendation is a `std` pattern with no
dependency. Gates: 1 `inapplicable`; 2 `ErrorKind::BrokenPipe` has been stable
since Rust 1.0, so pass; 3 `inapplicable`, `unsafe` **none used** — this is the
pattern's main advantage over `sigpipe`; 4 the check is portable and compiles on
Windows too, though EPIPE is a Unix condition; 5 no features, no async coupling;
6 zero cost.

Practice evidence: this is exactly ripgrep's implementation, with its rationale in
the source comment — "Look for a broken pipe error. In this case, we generally
want to exit 'gracefully' with a success exit code. This matches existing Unix
convention. We need to handle this explicitly since the Rust runtime doesn't ask
for PIPE signals, and thus we get an I/O error instead."
(`crates/core/main.rs:46-61`, read 2026-09-05). ripgrep is the most-cited Rust CLI
and is what a reviewer will compare this template against.

**Exit 0 or 141?** Decided explicitly, as it must be. A C program killed by
`SIGPIPE` is reported by the shell as 141 (128+13). ripgrep returns **0**, on the
stated ground that it "matches existing Unix convention" from the *consumer's*
point of view — `rg foo | head` is not a failed command. This template returns
**0** as well, for the same reason and for a second one: the cli-standards
taxonomy has no 141, and inventing one would break P2's "one taxonomy" agreement.

##### Qualified shortlist

`sigpipe` 0.1.3 — 146,505 90-day / 625,212 all-time
(`https://crates.io/api/v1/crates/sigpipe`, 2026-09-05); last release **0.1.3**,
`created_at` **2022-02-02T02:26:15.786617Z** (`/versions`, 2026-09-05);
`license = "MIT"`; no declared `rust_version`; repository
`https://www.github.com/kurtbuilds/sigpipe` — **6** stars, `archived: false`,
`pushed_at` **2022-02-02T02:26:12Z**, **0** open issues, responsiveness
`inapplicable` (the tracker has never had an issue, so the 10-issue sample is
empty) (`https://api.github.com/repos/kurtbuilds/sigpipe`, 2026-09-05); no
advisory (`https://rustsec.org/packages/sigpipe.html` → 404, 2026-09-05). Maintenance:
**at-risk** — the concrete signals are a repository last pushed **2022-02-02**
with zero issues ever filed (so no responsiveness evidence exists in either
direction), combined with the fact that the crate's entire purpose is a one-line
`unsafe` call to
`libc::signal(SIGPIPE, SIG_DFL)` whose *sanctioned* replacement
(`-Zon-broken-pipe`) is an open, moving compiler feature, leaving the crate
tracking an unstable target with no releases since. Gates: 1 pass (MIT is
compatible); 2 unverifiable from metadata — no `rust_version` declared; 3 no
advisory but the `unsafe` posture is the whole crate; 4 Unix only; 5 no async
coupling; 6 negligible. Qualified because it does work and it fixes `println!` too
(the process dies from the signal before the macro can panic). **Not chosen**: it
restores a *process-wide* disposition that also affects any library in the tree
that was relying on Rust's `SIG_IGN` assumption, it makes the failure a signal
death (141) rather than a controlled exit, and it trades a zero-`unsafe` pattern
for an `unsafe` dependency to avoid a discipline rule the template wants anyway.

Nightly `-Zon-broken-pipe=sig_dfl` — **excluded by constraint**, not by gate: the
tracking issue is open, so the flag is nightly-only and the item mandates stable
Rust. Recorded because it is the direction the language is moving, and it is the
re-verify trigger for this member.

##### Excluded by gate

None by the six fitness gates. One candidate (`-Zon-broken-pipe`) is excluded by
the item's own `Stable Rust only` constraint, which is recorded above rather than
silently dropped.

##### Up-and-comers

`sigpipe` is the only bin-3 entrant and is covered above. The genuine "up and
comer" here is the language feature itself; when `-Zon-broken-pipe` stabilizes,
this member becomes a one-line build setting and the `println!` prohibition can be
relaxed.

##### Fit for this template

**CLI**: essential — a template whose `--format json` output cannot be piped into
`head` or `jq` without a panic is broken in a way users hit immediately.
**Library**: nothing to do; the library returns values, and a `BrokenPipe`
`io::Error` from an injected writer surfaces as `CoreError::Io` for the binary to
classify. **Web service**: not applicable — a dropped HTTP connection is the
framework's concern, and a `BrokenPipe` there must **not** exit the process. That
asymmetry is why the check belongs at the CLI `main` boundary and not in shared
code.

##### Recommendation

Adopt the pattern; add **no crate**. Two rules the template enforces: all result
output uses `writeln!`/`write!` on an explicitly locked handle, and `main`'s error
path returns `ExitCode::from(0)` when any link in the `anyhow` chain is an
`io::Error` of kind `BrokenPipe`. Enforce the first with a clippy/lint deny on
`print_stdout` and `print_stderr` in the CLI crate (R28 owns the lint wiring;
this item supplies the requirement).

##### Ranked runner-up

1. `sigpipe = "0.1.3"` — only if the template later finds it cannot control every
   write site (for example a third-party crate that prints internally).
2. `-Zon-broken-pipe=sig_dfl` — the correct answer once it stabilizes.

##### Tradeoffs

Zero dependencies, zero `unsafe`, zero compile cost. The cost is a discipline rule
that must be lint-enforced, because `println!` is the first thing anyone reaches
for and its failure mode is a panic in production rather than a compile error. The
second cost is that a `BrokenPipe` originating somewhere that is *not* stdout —
a killed subprocess, say — would also exit 0; ripgrep accepts the same imprecision,
and narrowing it would mean tagging the writer identity through the error chain.

##### Parameters

Supplies the broken-pipe rule to `error-taxonomy-exit-codes`: EPIPE on the result
stream exits **0** and emits no envelope. No `CONFLICT:`. States a requirement on
R28 (lint configuration) and R66 (the output-format surface must write through the
locked-handle helper).

##### Migration implications

`crates/cli/src/main.rs` gains the chain walk in `report()`. `crates/cli/src/output.rs`
(R66's file) exposes a locked-writer helper and is the only place allowed to write
to stdout. `Cargo.toml`/`clippy.toml` gains `print_stdout` / `print_stderr` denials
for the CLI crate. No dependency is added.

##### Validation strategy

Executed: `rslb emit-lines | head -2` → producer's own exit code **0**, stderr
empty, no panic; `rslb emit-lines-println | head -2` → producer's own exit code
**101** with `failed printing to stdout: Broken pipe (os error 32)`. The
side-by-side is the evidence that the pattern is load-bearing rather than
decorative. Planned: the same pair as an integration test, so a future
`println!` regression fails CI rather than a user's pipeline.

##### Confidence & re-verify trigger

**High** — this is measured behavior, not inference. Re-verify when
`rust-lang/rust#97889` closes or `-Zon-broken-pipe` stabilizes, at which point
the recommendation changes to a build flag.

##### Sources

`https://api.github.com/repos/rust-lang/rust/issues/97889` (2026-09-05);
`https://api.github.com/repos/rust-lang/rust/issues/62569` (2026-09-05);
`https://doc.rust-lang.org/std/io/enum.ErrorKind.html` (2026-09-05);
`https://rust-cli.github.io/book/in-depth/exit-code.html` (2026-09-05, for the
panic-exits-101 statement);
`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/main.rs`
(2026-09-05); `https://crates.io/api/v1/crates/sigpipe` and `/versions`
(2026-09-05); `https://rustsec.org/packages/sigpipe.html` → 404 (2026-09-05);
executed measurements this run; `docs/port/COMMONALITY.md:304`;
`docs/port/DIVERGENCE-ANALYSIS.md:214`.

#### Crash-log persistence (pattern: best-effort `std::fs` append)

##### Landscape

Category: **persisting an unexpected failure for post-hoc diagnosis** (F302).
Bin 1 holds `std::fs::OpenOptions::new().create(true).append(true)` — a dozen
lines. Bin 2 holds no established crate for *returned-error* logging; the
adjacent options are the tracing/logging stack (R58/R59), which writes an
operational log rather than a crash record. Bin 3 holds `human-panic`, under the
`rust-cli` organisation. Path resolution is a separate sub-slot: `etcetera` versus
the archived `directories`.

##### Principles and implementation

Serves P5, whose agreement level is `capability` and whose class is **D**
(one-sided, language-neutral, harmonize **yes** —
`DIVERGENCE-ANALYSIS.md:215`): adopt in all three repos or drop in all three.
py has it (ADR 0006, `cli/options.py:143`, appending to
`<state>/plbp/plbp_crash.log`); ts simply never ported it, with no recorded
reason. Nothing about it is language-specific, so the recommendation is **adopt**,
and this answer supplies ts's rationale for the follow-on project.

Two invariants make it correct rather than merely present. It is **best-effort**:
a failure to write the crash log must never change the exit code or emit a second
error — otherwise a read-only home directory turns every error into a different
error. And it stores the **full cause chain** (`{err:?}`), which is what makes it
worth having over the envelope's one-line message.

##### Dominant choice

The pattern: append `{err:?}` to `<state-dir>/rslb_crash.log`, ignoring every
error from the attempt, on the `CODE_UNEXPECTED` path only — never for a modelled
domain error, which by definition is understood and needs no forensics.

Crate figures: **inapplicable** for the writer itself — it is `std::fs` with no
dependency. Gates for the writer: 1 `inapplicable`; 2 stable since Rust 1.0, pass;
3 `inapplicable`, `unsafe` **none**; 4 portable across the matrix; 5 no features,
no async coupling; 6 zero cost.

For the **path** sub-slot the recommendation is `etcetera` 0.11.0, and the crate
figures do apply: 90-day downloads **31,585,774**; all-time **103,241,722**
(`https://crates.io/api/v1/crates/etcetera`, 2026-09-05); last release **0.11.0**,
`created_at` **2025-10-28T13:28:11.765603Z** (`/versions`, 2026-09-05);
`license = "MIT OR Apache-2.0"`; `rust_version` **1.87.0**; `edition = "2024"`.
Stars **149**, `archived: false`, `pushed_at` **2026-08-04T20:53:17Z**
(`https://api.github.com/repos/lunacookies/etcetera`, 2026-09-05). Open issues
**2** (`search/issues?…`, `total_count`, 2026-09-05). Responsiveness: median
**1.8 days**, 3 of 10 unanswered. Advisories: **none** (404, 2026-09-05).
Maintenance: **active**. Gates: 1 pass; 2 pass (1.87.0 ≤ 1.96); 3 pass; 4 pass; 5
no default features of consequence, no async coupling; 6 negligible.

Adoption evidence — and this is why `etcetera` rather than the better-known
`directories`: bat `etcetera = { version = "0.11.0", optional = true }`, fd
`etcetera = "0.11"`, cargo-nextest `etcetera = "0.11.0"`, Ruff
`etcetera = { version = "0.11.0" }` — four of the seven surveyed projects, all
verified from their own manifests on 2026-09-05.

##### Qualified shortlist

`human-panic` 2.0.8 — 2,783,578 90-day / 13,091,272 all-time; released
2026-04-02; `license = "MIT OR Apache-2.0"`; `rust_version` **1.88**;
`edition = "2024"`; 1,852 stars, `archived: false`, `pushed_at` **2026-09-02**; 9
open issues; no advisory (404); responsiveness `inapplicable` — the 25 most recent
tracker items were all pull requests, so the "10 most recently opened issues"
sample is empty. Maintenance: **active**, and it carries the `rust-cli`
organisation's standing. Every gate passes.

Qualified but **not a substitute**, and the distinction is the point: reading
`human-panic`'s own `src/lib.rs` and `src/report.rs` (2026-09-05) shows it
installs a **panic hook** and persists a TOML report built from the `backtrace`
crate to a **temporary directory** — its own docs show
`"/var/folders/…/report-8351cad6-….toml"`. F302 is about *returned* unexpected
errors, which in Rust travel the `Err` path and never reach a panic hook. So
`human-panic` covers a different failure class (panics), writes to a different
place (temp, not state), and answers a different question. It is **complementary**
and worth adopting alongside — but it does not implement F302, and recording it as
the answer would be wrong.

`directories` 6.0.0 for the path sub-slot — 12,201,032 90-day / 68,614,214
all-time; released **2025-01-12**; `license = "MIT OR Apache-2.0"`; no declared
`rust_version`. **Excluded by gate 3's spirit and by the maintenance rubric**:
both GitHub homes are **archived** — `soc/directories-rs` (`archived: true`,
`pushed_at` 2025-01-12T19:35:58Z) and `dirs-dev/directories-rs` (`archived: true`,
same date), retrieved 2026-09-05. Its RustSec entry **RUSTSEC-2020-0054**
("directories is unmaintained") is marked **withdrawn** and must be ignored, so
strictly there is no *open* advisory — but the rubric's `archived` verdict is
reached directly from the repository state, without needing the advisory.
Maintenance: **archived**. Not chosen.

The R58/R59 logging stack as the crash-log sink. Gates deferred to R58.
Qualified in principle — a file log sink could receive the record. Not chosen
because a crash log must survive the logging pipeline itself failing to
initialize, which is a common cause of the very errors it should capture.

##### Excluded by gate

`directories` 6.0.0 — **archived** at both repository homes (evidence above),
which the maintenance rubric treats as terminal. Recorded here rather than in the
shortlist because "the well-known crate for this" is exactly what a reviewer would
expect to see chosen.

##### Up-and-comers

`etcetera` is the up-and-comer that has already won this slot on adoption
(four of seven surveyed projects) despite only 149 stars — a case where download
and adopter evidence contradicts the star count, and the adopter evidence is the
one that matters. `human-panic` is the other bin-3 entrant, covered above.

##### Fit for this template

**CLI**: the crash log belongs here, written once at the `main` boundary.
**Library**: must not write files as a side effect — `rslb-core` produces errors
and the binary decides whether to persist them. **Web service**: **disabled**. A
long-running service must send unexpected errors to the tracing pipeline (R58),
not append to a file that grows unbounded; the crash log is a
one-invocation-per-run CLI affordance. Making that surface distinction explicit is
part of this member's answer.

##### Recommendation

Adopt a best-effort crash log for the **CLI surface only**, on the
`CODE_UNEXPECTED` path only, appending `{err:?}` with a timestamp to
`<state-dir>/rslb_crash.log`. Add **no crate** for the writer. Use
`etcetera = "0.11.0"` for the directory, honoring an `RSLB_STATE_DIR` override.
Adopt `human-panic` **in addition** for the panic class, not instead. Answering
the LOW question directly: the path **does not need to block on R57** — the
recommendation is a fixed default with an env override, so R57 can later replace
the resolver without changing this item's contract.

##### Ranked runner-up

1. A fixed `~/.local/state/rslb/` (or `$XDG_STATE_HOME`) computed by hand, no
   crate — if R57 concludes the template needs no directory crate at all.
2. Route to R59's file log sink — if R58 guarantees the sink initializes before
   any fallible work.

##### Tradeoffs

Zero dependency for the writer; `etcetera` adds a small, actively maintained tree
for the path. The design cost is an unbounded file: the template should truncate
or rotate, which this member does not solve and R59 may. The privacy cost is
real — an error chain can contain a file path or a URL — so the crash log must
never contain secrets, which is R56's concern and is stated here as a requirement
on it.

##### Parameters

Supplies the crash-log rule to `error-taxonomy-exit-codes`: written on
`CODE_UNEXPECTED` only, CLI surface only, best-effort. States an assumption on R57
(`xdg-directory-set`): a state directory exists or `RSLB_STATE_DIR` is honored.
No `CONFLICT:` — R57 registers no parameter this item consumes, and the assumption
is satisfiable either way.

##### Migration implications

`crates/cli/src/crash.rs` — a ~15-line best-effort writer. `crates/cli/Cargo.toml`
gains `etcetera = "0.11.0"` and optionally `human-panic = "2.0.8"`.
`crates/web` gains none of this. A `.gitignore` entry and a documentation note
telling users where the file lives and that it may contain paths.

##### Validation strategy

Executed: an unexpected error produced `<state>/rslb_crash.log` containing the
full `anyhow` chain — `---` / `loading the project index` / `Caused by:` /
`No such file or directory (os error 2)` — while the envelope on stderr carried
only the one-line `{err:#}` form. Also executed, the best-effort invariant:
pointing the state directory at an unwritable path left the exit code at **1** and
produced no additional error output. Also executed, the F301 evidence: with
`RUST_BACKTRACE` unset the report was 5 lines and contained no backtrace; with
`RUST_BACKTRACE=1` the identical path produced 15 lines containing
`Stack backtrace`. Planned: a rotation or size cap, and a redaction pass once R56
defines the secret policy.

##### Confidence & re-verify trigger

**Medium-high.** The mechanism and its invariants are measured; what is *not*
settled is the directory, which is R57's, and the retention policy, which nobody
owns yet. Re-verify when R57 answers, when R56 defines redaction, or if
`etcetera` is superseded.

##### Sources

`https://crates.io/api/v1/crates/etcetera`, `/directories`, `/human-panic` and
their `/versions` (2026-09-05);
`https://api.github.com/repos/lunacookies/etcetera`,
`.../repos/soc/directories-rs`, `.../repos/dirs-dev/directories-rs`,
`.../repos/rust-cli/human-panic` (2026-09-05);
`https://api.github.com/search/issues?q=repo:lunacookies/etcetera+is:issue+is:open`
(2026-09-05); `https://rustsec.org/packages/etcetera.html`, `/human-panic.html`
→ 404 and `https://rustsec.org/advisories/RUSTSEC-2020-0054.html` (withdrawn),
all 2026-09-05;
`https://raw.githubusercontent.com/rust-cli/human-panic/master/src/lib.rs` and
`/src/report.rs` (2026-09-05); adopter manifests for bat, fd, cargo-nextest, Ruff
(2026-09-05); `https://doc.rust-lang.org/std/backtrace/index.html` (2026-09-05);
`docs/port/COMMONALITY.md:253,306`; `docs/port/DIVERGENCE-ANALYSIS.md:193,215`.

#### inquire (prompt-cancellation surface — conditional on R61)

##### Landscape

Category: **detecting that the user cancelled an interactive prompt** (F299) and
mapping it to a distinct exit code, mirroring ts's `ExitPromptError` check at
`src/router.ts:200`. This member is **contingent**: R61 (`interactive-prompts`)
owns whether the template has an interactive prompt at all, and if R61 declines,
this member is dropped and `RSLB900` is never emitted. What is researched here is
narrower and is the part R67 must know: *do the candidate prompt crates surface a
typed cancellation error the catalog can map, or must the template catch a signal
directly?* Bin 1 holds "catch `SIGINT` and hope the prompt unwinds", which is the
fallback if no crate types the condition. Bin 2 holds `dialoguer`. Bin 3 holds
`inquire`.

##### Principles and implementation

Serves P4 with P2's integers. The question the prompt poses — "does the candidate
prompt crate surface a typed cancellation error, or does the template need to
catch a signal directly?" — is answered by reading the two crates' error
definitions rather than their READMEs, and the two answers differ sharply.

`inquire` types it. `inquire/src/error.rs` defines `InquireError::OperationCanceled`
("Operation was canceled by the user", the Esc case) and
`InquireError::OperationInterrupted` — documented in the source as "The operation
was interrupted by the user after they pressed Ctrl+C" (read 2026-09-05). That is
a direct, typed analogue of ts's `ExitPromptError`, and it distinguishes Esc from
Ctrl-C, which ts does not.

`dialoguer` does not. Its entire `src/error.rs` is
`pub enum Error { IO(IoError) }` with a single variant (read 2026-09-05), so a
Ctrl-C during a prompt arrives as an `io::Error` and the template would have to
sniff `ErrorKind::Interrupted` — a weaker, less precise mapping that could
collide with a genuine interrupted syscall.

##### Dominant choice

`inquire` 0.9.4 — dominant *for the cancellation contract*, which is the only
axis this member ranks on; R61 ranks the prompt crates overall. 90-day downloads
**5,319,781**; all-time **19,985,236**
(`https://crates.io/api/v1/crates/inquire`, 2026-09-05). Last release **0.9.4**,
`created_at` **2026-02-24T17:21:33.418470Z** (`/versions`, 2026-09-05).
`license = "MIT"`; `rust_version` **1.80.0**. Stars **2,623**,
`archived: false`, `pushed_at` **2026-03-02T14:42:29Z**
(`https://api.github.com/repos/mikaelmello/inquire`, 2026-09-05). Open issues
**59** (`search/issues?…`, `total_count`, 2026-09-05). Responsiveness over the 10
most recently opened issues (6 were issues): median **0.0 days** to first
maintainer response, **5** unanswered. Advisories: **none** (404, 2026-09-05).
Maintenance: **stable-quiet** — six months since the last release triggers
investigation; the investigation finds same-day responses on the issues that were
answered, no advisory, and no broken build, so no `at-risk` signal is present and
none of the `dormant` triggers applies.

Gates: 1 `MIT` — compatible with an `MIT OR Apache-2.0` project, though it is a
single-license dependency and so is noted for the binary crate rather than the
library; 2 pass (1.80.0 ≤ 1.96); 3 pass, `unsafe` posture — not measured on this
run (the crate was not vendored), **recorded as unverified**; 4 Unix and Windows
via `crossterm`, so the matrix is covered; 5 default features pull a terminal
backend — R61 owns that assessment; 6 crate payload 101,235 bytes, a heavier tree
than any other member here, which is R61's cost to weigh, not this item's.

##### Qualified shortlist

`dialoguer` 0.12.0 — 16,282,063 90-day / 79,837,506 all-time; released
**2025-08-23**; `license = "MIT"`; `rust_version` 1.66; 1,610 stars,
`archived: false`, `pushed_at` 2026-07-08; 71 open issues; no advisory (404).
Responsiveness over the 10 most recently opened issues (6 were issues): median
**0.2 days** with **0 unanswered** — the best answered-ratio measured in this
bundle, and a point in `dialoguer`'s favour that R61 should weigh against the
cancellation-typing point below. Maintenance: **stable-quiet**. Three times `inquire`'s downloads and adopted by
cargo-nextest (`dialoguer = "0.12.0"`, verified 2026-09-05), so it is a serious
candidate for R61 on every axis except this one. Qualified with a **degraded
contract**: cancellation must be inferred from `io::ErrorKind::Interrupted`
rather than matched on a typed variant.

Signal-only fallback (bin 1): rely on the `signal-hook` handler already installed
and let `SIGINT` during a prompt take the normal 130 path. Gates `inapplicable`.
Qualified as the answer if R61 declines a crate entirely — and note it yields the
*same* exit code, so the observable contract survives; what is lost is the ability
to distinguish Esc-cancel from Ctrl-C.

##### Excluded by gate

None. Both prompt crates pass every applicable gate; the difference is API
capability, recorded as a fitness finding.

##### Up-and-comers

`inquire` is itself the bin-3 up-and-comer, and it is the one whose API is a
better fit than the established incumbent's — the one slot in this bundle where
the newer crate is recommended over the more-downloaded one, and only because a
typed variant beats sniffing an `io::ErrorKind`.

##### Fit for this template

**CLI** only. A **library** must never prompt, so `rslb-core` gets no prompt
dependency; it only owns the `CoreError::PromptCancelled` variant and its code, so
that the catalog stays complete whether or not a prompt crate is ever added. The
**web service** never prompts. This is what makes the contingency cheap: the
catalog entry `RSLB900 → 130` can exist today and simply never be constructed if
R61 declines.

##### Recommendation

**Conditional, and R61 decides the crate.** R67's contract is: prompt
cancellation maps to `CoreError::PromptCancelled`, code `RSLB900`, exit **130** —
matching ts's D-033 outcome. The recommendation *to R61* is `inquire = "0.9.4"`
if the cancellation contract is weighted, because it is the only surveyed crate
with typed cancellation. If R61 selects `dialoguer`, the contract still holds via
an `ErrorKind::Interrupted` check, with a stated loss of precision. If R61
declines interactive prompts entirely, drop `PromptCancelled` from the enum before
the first release — removing a catalog row is only free before it is published.

##### Ranked runner-up

1. `dialoguer` 0.12.0 — more adopted, weaker cancellation typing.
2. Signal-only fallback — same exit code, no Esc/Ctrl-C distinction.

##### Tradeoffs

Choosing `inquire` for the cancellation property means accepting a less-adopted
crate and an `MIT`-only dependency in the binary. Choosing `dialoguer` means a
cancellation check that cannot distinguish a user's Ctrl-C from an interrupted
syscall. Deferring entirely means `RSLB900` sits unused, which costs nothing but a
documented row.

##### Parameters

Supplies the conditional `RSLB900 → 130` row to `error-taxonomy-exit-codes`.
States an assumption on R61 (`interactive-prompts`): a prompt crate may or may not
be adopted; the catalog row is defined either way. No `CONFLICT:` — R61 registers
no parameter this item consumes, and no R61 outcome requires this item's value to
change.

##### Migration implications

`crates/core/src/error.rs` gains the `PromptCancelled` variant and its `RSLB900`
catalog row (today, unconditionally). `crates/cli` gains a `From<InquireError>`
conversion **only if** R61 adopts `inquire`. No dependency is added by this item.

##### Validation strategy

Executed: the `PromptCancelled` variant end-to-end through the built binary —
`{"error":{"code":"RSLB900","message":"cancelled at the prompt"}}` on stderr with
exit **130**, proving the catalog row and the mapping work independently of any
prompt crate. **Not executed**: `inquire`'s actual `OperationInterrupted` under a
real Ctrl-C, which needs a TTY this run did not have; the typed variant's
existence is verified by reading the crate's source, not by triggering it. Planned
for R61: a PTY-driven test that sends `^C` to a live prompt and asserts 130.

##### Confidence & re-verify trigger

**Medium.** High confidence that the *contract* (`RSLB900` → 130) is right and
that `inquire` types cancellation while `dialoguer` does not — both read from
source. Lower confidence on the crate recommendation itself, because R61 owns it
and weighs axes this member does not. Re-verify when R61 answers, or if
`dialoguer` adds a typed cancellation variant, which would erase the distinction.

##### Sources

`https://crates.io/api/v1/crates/inquire`, `/dialoguer` and their `/versions`
(2026-09-05); `https://api.github.com/repos/mikaelmello/inquire`,
`.../repos/console-rs/dialoguer` (2026-09-05);
`https://api.github.com/search/issues?q=repo:mikaelmello/inquire+is:issue+is:open`
(2026-09-05); `https://rustsec.org/packages/inquire.html`, `/dialoguer.html` →
404 (2026-09-05);
`https://raw.githubusercontent.com/mikaelmello/inquire/main/inquire/src/error.rs`
lines 25-33 and 83-87 (2026-09-05);
`https://raw.githubusercontent.com/console-rs/dialoguer/main/src/error.rs`
(2026-09-05); cargo-nextest manifest (2026-09-05);
`docs/port/COMMONALITY.md:303`; `docs/port/DIVERGENCE-ANALYSIS.md:213`.

### Compatibility

Proof that the seven members are tested together, in three independent forms.

**1. A version matrix built and executed on this run.** This is the strongest
evidence because it is this exact set, not a proxy. All members were compiled into
one Cargo workspace and every acceptance check in `### Validation strategy` was
run against the resulting binary.

| Member | Version resolved | Where |
|---|---|---|
| `thiserror` | 2.0.20 | `rslb-core` (library) |
| `anyhow` | 1.0.104 | `rslb-cli` (binary) |
| `signal-hook` | 0.4.4 | `rslb-cli` |
| `serde_json` | 1.0.151 | `rslb-cli` (F294 envelope, settled) |
| `ctrlc` | 3.5.2 | `rslb-cli`, compiled alongside to prove coexistence |
| Exit taxonomy | `std` (`ExitCode`, stable 1.61) | `rslb-core` |
| Broken pipe | `std` (`ErrorKind::BrokenPipe`) | `rslb-cli` |
| Crash log | `std::fs` | `rslb-cli` |
| Toolchain | `rustc`/`cargo` 1.98.0, edition 2024, `resolver = "3"` | workspace |

Result: clean `--release` build in **4.40 s** wall over **31** unique normal
dependencies, producing a **596,400-byte** binary, with **zero** version conflicts
and **zero** duplicate-crate resolutions. `ctrlc` and `signal-hook` were built
into the same binary deliberately, to confirm that adopting `signal-hook` does not
conflict with a crate the CLI-WG book recommends and that R61/R63 might pull in
transitively — they coexist.

**2. Shared adopters.** Two of the surveyed well-regarded projects use
overlapping subsets of this exact stack in production, verified from their own
manifests on 2026-09-05: **Nushell** ships `thiserror = "2.0.20"` +
`anyhow = "1.0.104"` + `ctrlc = "3.5.2"` — the same two error layers at the same
versions this stack pins; **fd** ships `anyhow = "1.0"` + `ctrlc = "3.5"` +
`etcetera = "0.11"`, combining the boundary carrier, a signal handler and the
path crate. **Ruff** covers `thiserror = "2.0.0"` + `anyhow = "1.0.80"` +
`etcetera = "0.11.0"` at `rust-version = "1.96"`, which is this run's MSRV floor
exactly.

**3. Shared maintainer and no async coupling.** `thiserror` and `anyhow` are
maintained by the same author with a deliberately compatible design —
`anyhow::Error` accepts any `std::error::Error + Send + Sync + 'static`, which is
what `thiserror`'s derive produces, so the boundary `downcast_ref::<CoreError>()`
is a supported path rather than a coincidence. **No member declares an async
runtime dependency** (`thiserror` `default = ["std"]`, `anyhow`
`default = ["std"]`, `signal-hook` `default = ["channel","iterator"]`, all
verified from vendored manifests, 2026-09-05), so nothing in this stack constrains
R05's sync/async decision or R69's framework choice.

**Gap, stated rather than papered over.** The **web-service** half of the stack
was not built: `tokio::signal` for `SIGTERM` draining is asserted from the
taxonomy, not executed, because R05 and R69 have not selected a runtime or
framework. Its compatibility risk is low (the exit integers are the only shared
artifact) but it is unverified on this run.

### Parameters

`owns error-taxonomy-exit-codes` = the following contract.

- **Catalog format**: `RSLB` + three digits, stable and append-only, pinned by a
  unit test over a `CATALOG` constant. `RSLB000` = UNEXPECTED (py `PLBP000`
  analogue). Blocks: `1xx` runtime (I/O, API), `2xx` usage and config input,
  `3xx` not found, `4xx` auth, `5xx` conflict, `9xx` cancellation.
- **Code source**: an explicit `const fn code(&self) -> &'static str` match on a
  `#[non_exhaustive]` `thiserror` enum in the library crate — **not** derived from
  the variant identifier, so a rename cannot change the wire code.
- **Exit-code taxonomy** (cli-standards R6.1, per D-016(2), unchanged from ts):
  `0` success, `1` error, `2` usage, `3` not found, `4` auth, `5` conflict,
  `130` SIGINT, `143` SIGTERM.
- **Initial catalog rows**: `RSLB000`→1, `RSLB101` I/O→1, `RSLB102` API→1,
  `RSLB201` config-parse→2, `RSLB202` config-value→2, `RSLB301` not-found→3,
  `RSLB401` auth→4, `RSLB501` conflict→5, `RSLB900` prompt-cancelled→130.
- **Hint**: `const fn hint(&self) -> Option<&'static str>`, emitted as a separate
  `hint` key in the JSON envelope and a separate line in human output.
- **Envelope**: `{"error":{"code","message","hint"?}}` on stderr; stdout stays
  byte-empty on the error path; `message` uses `{err:#}` (full chain, one line).
- **Broken pipe**: EPIPE on the result stream exits **0** with no envelope.
- **Crash log**: CLI surface only, `CODE_UNEXPECTED` path only, best-effort append
  of `{err:?}`; a write failure never changes the exit code.
- **Boundary precedence**: signal → broken pipe → domain downcast → unexpected.

`assumes` — the four fixed owner parameters, unchanged
(`docs/port/PARAMETERS.md`, owner-decided 2026-09-02):

- `assumes rust-edition = 2024` — the acceptance workspace was built on edition
  2024 with `resolver = "3"`; every member compiled.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — floor
  **1.96** at retrieval (stable 1.98.1, 2026-09-03). Every recommended crate's
  declared `rust_version` is below it: `thiserror` 1.71, `anyhow` 1.68,
  `signal-hook` 1.66, `etcetera` 1.87.0, `inquire` 1.80.0.
- `assumes license = MIT OR Apache-2.0` — every recommended crate is
  `MIT OR Apache-2.0` except `inquire` (`MIT`, binary crate only, compatible).
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — executed on macOS
  (Darwin 25.4) this run; Linux asserted from the crates' Unix support and from
  ripgrep/fd/Nushell practice, **not executed on Linux this run**.

Non-registry assumptions, stated as the `## Couplings` `related` note requires,
none of which blocks this answer:

- `assumes R57 (xdg-directory-set)`: a state directory exists, or `RSLB_STATE_DIR`
  overrides it. The crash-log path defaults to `etcetera`'s state directory and is
  replaceable without changing this contract.
- `assumes R61 (interactive-prompts)`: a prompt crate may or may not be adopted.
  `RSLB900 → 130` is defined either way and simply goes unused if R61 declines.
- `assumes R05 (sync-async-execution-model)`: the web surface uses the runtime's
  own signal source (`tokio::signal`) and produces the same 130/143 codes.
- `assumes R66 (output-format-surface)`: renders the `hint` as a separate field in
  every machine format and a separate line in human output, and writes through a
  locked-handle helper rather than `println!`.
- `assumes F301 disposition (open owner question, `docs/port/BASELINE-REVIEW.md:194`)`:
  no backtrace is captured unless `RUST_BACKTRACE`/`RUST_LIB_BACKTRACE` is set,
  and the trace goes to the crash log rather than the envelope, so machine-mode
  suppression is automatic. Stated as an assumption, not a recommendation, pending
  the owner's disposition.

**`CONFLICT:` lines: none.** This item's `## Couplings` lists `consumes:` as
empty, so there is no consumed parameter whose value the recommendation needs
changed. Every cross-item dependency above is an assumption satisfiable in either
direction, which is why none is escalated.

### Migration implications

File-level changes in the template. No Rust code exists yet, so these are the
files this item creates or constrains.

| File | Change |
|---|---|
| `crates/core/src/error.rs` | **New.** `#[non_exhaustive] enum CoreError` (`thiserror`), `#[repr(u8)] enum Exit`, `impl From<Exit> for std::process::ExitCode`, `const fn code/hint/exit`, `pub const CATALOG`, `pub const CODE_UNEXPECTED`, and the three catalog tests. |
| `crates/core/src/lib.rs` | Re-export `CoreError`, `Exit`, `CATALOG`, `CODE_UNEXPECTED` from the crate root — they are public API that R03, R52-R56 and R70 consume. |
| `crates/core/Cargo.toml` | `thiserror = "2.0.20"`. **Must not** gain `anyhow`. |
| `crates/cli/src/main.rs` | **New.** `fn main() -> ExitCode`; signal registration; `report()` implementing the four-step precedence. |
| `crates/cli/src/output.rs` | Owned by R66; constrained here — locked-handle writer, the `{"error":{…}}` envelope on stderr, `hint` as its own field/line, `{err:#}` for `message`. |
| `crates/cli/src/crash.rs` | **New.** ~15-line best-effort append; never propagates its own failure. |
| `crates/cli/Cargo.toml` | `anyhow = "1.0.104"` (>= 1.0.103 for RUSTSEC-2026-0190), `serde_json`, `etcetera = "0.11.0"`, `[target.'cfg(unix)'.dependencies] signal-hook = "0.4.4"`, optionally `human-panic = "2.0.8"`. |
| `crates/web/src/shutdown.rs` | Owned by R69; constrained here — `SIGTERM` drains then exits **143**, `SIGINT` exits **130**; no crash log on this surface. |
| `clippy.toml` / crate lint attributes | Deny `print_stdout` and `print_stderr` in `crates/cli` so `println!` cannot reintroduce the EPIPE panic. Wiring owned by R28. |
| `deny.toml` | Owned by R13; constrained here — `cargo audit`/`cargo deny` must run in CI, since this item's stack carries a crate with a live advisory history. |
| `docs/error-codes.md` | **New.** The published catalog: code, meaning, exit code, hint. Checked against `CATALOG` in CI so documentation cannot drift from the enum. |
| `tests/cli_exit_codes.rs` | **New.** Table-driven integration test: one assertion per catalog row, plus the EPIPE, SIGINT, SIGTERM and crash-log cases. |

Two structural constraints this item imposes on other items, stated so they are
not discovered late: the library crate must never depend on the
application-error crate (enforceable by a `deny.toml` rule), and no code outside
`crates/cli/src/output.rs` may write to stdout.

### Validation strategy

**What was actually built and run.** A two-crate Cargo workspace (`rslb-core`
library + `rslb-cli` binary) using the recommended stack at the pinned versions,
built with `rustc 1.98.0`, edition 2024, `resolver = "3"`, on macOS (Darwin
25.4, Apple Silicon). Every row below marked *executed* was run against that
binary during this research run; rows marked *planned* were not run and are
proposals for the template.

The core of the boundary function, which is what the checks exercise:

```rust
fn report(err: anyhow::Error, json: bool, sig: &AtomicI32) -> ExitCode {
    match sig.load(Ordering::SeqCst) {                       // 1. signal wins
        s if s == signal_hook::consts::SIGINT  => return ExitCode::from(Exit::Sigint as u8),
        s if s == signal_hook::consts::SIGTERM => return ExitCode::from(Exit::Sigterm as u8),
        _ => {}
    }
    for cause in err.chain() {                               // 2. broken pipe
        if let Some(io_err) = cause.downcast_ref::<io::Error>() {
            if io_err.kind() == io::ErrorKind::BrokenPipe {
                return ExitCode::from(Exit::Success as u8);
            }
        }
    }
    if let Some(core) = err.downcast_ref::<CoreError>() {    // 3. domain error
        emit(json, core.code(), &core.to_string(), core.hint());
        return ExitCode::from(core.exit() as u8);
    }
    emit(json, CODE_UNEXPECTED, &format!("{err:#}"), None);  // 4. unexpected
    crash_log(&err);
    ExitCode::from(Exit::Error as u8)
}
```

**Executed checks and their results.**

| # | Command | Expected | Observed | Verdict |
|---|---|---|---|---|
| V1 | `cargo test -p rslb-core` | catalog pinned, total, unique | `3 passed; 0 failed` | **pass** |
| V2 | `rslb fail-domain notfound` | `error[RSLB301]` + hint line, exit 3 | `error[RSLB301]: no project named \`demo\`` / `  hint: run \`rslb list\`…`, exit **3** | **pass** |
| V3 | `rslb fail-domain auth --json` | envelope on stderr, stdout empty, exit 4 | `{"error":{"code":"RSLB401","hint":"set RSLB_TOKEN…","message":"credentials are missing or rejected"}}`, `stdout_bytes=0`, exit **4** | **pass** |
| V4 | `rslb fail-domain config\|conflict\|prompt --json` | 2 / 5 / 130 | **2** / **5** / **130** | **pass** |
| V5 | `rslb fail-unexpected --json` | `RSLB000`, exit 1, crash log | `{"error":{"code":"RSLB000","message":"loading the project index: No such file or directory (os error 2)"}}`, exit **1**, log written | **pass** |
| V6 | `rslb emit-lines \| head -2` | no panic, producer exit 0 | producer exit **0**, stderr empty | **pass** |
| V7 | `rslb emit-lines-println \| head -2` | (control) panic | producer exit **101**, `failed printing to stdout: Broken pipe (os error 32)` | **pass** (control confirms the rule is load-bearing) |
| V8 | `rslb sleep &` then `kill -INT` | exit 130, destructors run | exit **130**, `cleanup-ran` printed | **pass** |
| V9 | `rslb sleep &` then `kill -TERM` | exit 143, destructors run | exit **143**, `cleanup-ran` printed | **pass** |
| V10 | `RSLB_STATE_DIR=<unwritable> rslb fail-unexpected` | exit unchanged | exit **1**, no extra output | **pass** |
| V11 | `RUST_BACKTRACE` unset vs `=1` | capture is env-gated | 5-line report, no backtrace vs 15-line report containing `Stack backtrace` | **pass** (F301 evidence) |
| V12 | `clapchk` (clap 4.6.6) missing arg / bad flag / `--help` | usage → 2 | **2** / **2** / **0** | **pass** (taxonomy fit) |
| V13 | `exitcode::CONFIG`, `sysexits::ExitCode::Usage` on stable 1.98 | BSD values | **78** / **64**; both crates compiled and ran | **pass** (taxonomy contrast) |
| V14 | `cargo clean && cargo build --release` | build cost | **4.40 s** wall / 12.60 s user, **596,400** bytes, **31** crates | **measured** |

**Planned checks for the template** (proposed, not run):

1. `cargo test --test cli_exit_codes` — a table-driven test asserting one exit
   code per `CATALOG` row, so the enum and the binary cannot drift.
2. A CI step asserting `docs/error-codes.md` matches `CATALOG`, so the published
   catalog cannot drift from the code.
3. A `deny.toml` rule asserting `crates/core` has no `anyhow` dependency.
4. On the web surface once R69 lands: `SIGTERM` drains in-flight requests, then
   exits 143.
5. A PTY-driven prompt-cancellation test (R61) sending real `^C` and asserting 130.
6. `cargo audit` in CI — non-optional given RUSTSEC-2026-0190's history on `anyhow`.
7. The Linux half of `target-os-matrix`: every executed check above re-run on
   `ubuntu-latest`. **This run executed on macOS only.**

### Confidence & re-verify trigger

**Overall: high**, with the scope limits below stated explicitly rather than
averaged away.

| Area | Confidence | Basis |
|---|---|---|
| Code catalog shape and the rename-stability argument | **High** | Executed pin tests; the defect being avoided is quoted from ts `src/router.ts:211` |
| Exit-code taxonomy (cli-standards R6.1) | **High** | Owner-normative via D-016(2) *and* independently corroborated by clap's measured exit 2 |
| Broken-pipe rule | **High** | Measured both ways (0 vs 101) plus ripgrep as reference |
| SIGINT/SIGTERM on the CLI path | **High** | Measured 130/143 with destructors observed |
| `anyhow`/`thiserror` layering | **High** | Six of seven surveyed reference projects; executed |
| Crash log | **Medium-high** | Mechanism measured; directory depends on R57; retention unowned |
| Prompt cancellation | **Medium** | Contract sound and executed; crate choice is R61's; typed variant read from source but not triggered |
| Web-surface signals | **Medium** | Codes asserted, `tokio::signal` not built — R05/R69 pending |
| Linux behavior | **Medium** | Not executed; asserted from crate support and adopter practice |

**Re-verify triggers.** (1) `rust-lang/rust#97889` closes or `-Zon-broken-pipe`
stabilizes — the EPIPE member becomes a build flag and the `println!` ban can
relax. (2) A new RustSec advisory against `anyhow` or `thiserror`; this run
already found one (RUSTSEC-2026-0190). (3) R60 selects a CLI parser that does not
exit 2 on usage errors — the taxonomy's independent fit argument would lapse.
(4) R05/R69 select the async model — the web signal path needs building and
measuring. (5) R61 answers — `RSLB900` is either wired to a typed variant or
dropped before first release. (6) R57 answers — the crash-log path is finalized.
(7) The owner dispositions the F301 amendment — the backtrace rules become part of
this item's published contract or stay implementation detail. (8) Rust stable
advances two minors past 1.98, moving the MSRV floor above any recommended crate's
declared `rust_version` (none is close; `etcetera`'s 1.87.0 is the highest).

### Sources

**Ledger, spec and prior decisions (repository, read unmodified).**
`docs/port/COMMONALITY.md:253,298-306` (F249, F294-F302);
`docs/port/PARAMETERS.md` (the four fixed owner parameters, owner-decided
2026-09-02, and the `error-taxonomy-exit-codes` row);
`docs/port/DIVERGENCE-ANALYSIS.md:193,208-215,304` (cause classes and the shared
principle per sub-row); `docs/port/BASELINE-REVIEW.md:122-123,154,181,194,262,329,375-377,429-430,455`
(F294/F301 baseline review and the open owner question); `research/CLAUDE.md`
(item registry); `research/RUNBOOK.md` §1-2 (A5, fixed parameters, tier policy);
`research/runs/R67/2026-09-05T155124Z-2271e140a7ef/inputs/prompt.md` (binding
prompt, including py/ts source citations and D-016(2), D-018(4), D-033).

**Rust project and working-group publications** (all retrieved 2026-09-05).
`https://rust-cli.github.io/book/in-depth/exit-code.html`;
`https://rust-cli.github.io/book/in-depth/signals.html`;
`https://api.github.com/repos/rust-lang/rust/issues/97889` (`unix_sigpipe` /
`-Zon-broken-pipe` tracking issue, state `open`);
`https://api.github.com/repos/rust-lang/rust/issues/62569` ("Should Rust still
ignore SIGPIPE by default?", state `open`);
`https://api.github.com/repos/rust-lang/rust/releases/latest` (stable 1.98.1,
published 2026-09-03) and `.../releases?per_page=6` (for the 1.96 floor);
`https://doc.rust-lang.org/std/process/struct.ExitCode.html`;
`https://doc.rust-lang.org/std/io/enum.ErrorKind.html`;
`https://doc.rust-lang.org/std/backtrace/index.html`.

**Registry and advisory endpoints** (all retrieved 2026-09-05).
`https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `https://crates.io/api/v1/crates/<name>/versions` (newest
`yanked: false` → `num`, `created_at`, `license`, `rust_version`, `crate_size`)
for: `thiserror`, `anyhow`, `eyre`, `color-eyre`, `miette`, `snafu`, `strum`,
`ctrlc`, `signal-hook`, `sysexits`, `exitcode`, `human-panic`, `inquire`,
`dialoguer`, `etcetera`, `directories`, `sigpipe`.
`https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`,
`pushed_at`, `license.spdx_id`) and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`, never `open_issues_count`) for: `dtolnay/thiserror`,
`dtolnay/anyhow`, `eyre-rs/eyre`, `zkat/miette`, `shepmaster/snafu`,
`Peternator7/strum`, `Detegr/rust-ctrlc`, `vorner/signal-hook`,
`sorairolake/sysexits-rs`, `benwilber/exitcode`, `rust-cli/human-panic`,
`mikaelmello/inquire`, `console-rs/dialoguer`, `lunacookies/etcetera`,
`soc/directories-rs`, `dirs-dev/directories-rs`. Responsiveness from
`https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc`
plus each issue's `/comments`, first comment whose `author_association` is
`OWNER`/`MEMBER`/`COLLABORATOR` and whose author is not the issue opener.
`https://rustsec.org/packages/<name>.html` for all seventeen crates, plus
`https://rustsec.org/advisories/RUSTSEC-2026-0190.html`,
`.../RUSTSEC-2024-0021.html`, `.../RUSTSEC-2020-0054.html`, and
`https://rustsec.org/packages/atty.html` as a positive control.

**Maintainers' own source, read directly** (`raw.githubusercontent.com`, all
retrieved 2026-09-05). `BurntSushi/ripgrep` `crates/core/main.rs` and
`Cargo.toml`; `Detegr/rust-ctrlc` `src/lib.rs` and `Cargo.toml`;
`mikaelmello/inquire` `inquire/src/error.rs`; `console-rs/dialoguer`
`src/error.rs`; `rust-cli/human-panic` `src/lib.rs` and `src/report.rs`. Adopter
manifests: `sharkdp/bat`, `sharkdp/fd`, `nushell/nushell`, `nextest-rs/nextest`,
`astral-sh/ruff`, `rust-lang/cargo`, `starship/starship`. Vendored crate sources
at `~/.cargo/registry/src/index.crates.io-*/` for `thiserror-2.0.20`,
`anyhow-1.0.104`, `signal-hook-0.4.4`, `ctrlc-3.5.2` (`unsafe` counts and
`[features]` blocks).

**Method notes.** Figures came only from the endpoints the prompt's evidence table
names, queried on **2026-09-05**: `https://crates.io/api/v1/crates/<name>` and
`/versions` via `curl -sS` with a `User-Agent` header
(`rs-launch-blueprint-research/1.0 (steve@conceptm.com)`);
`https://api.github.com/repos/<o>/<r>`,
`https://api.github.com/search/issues?q=…` and `.../issues?state=all&…` via the
GitHub REST API; `https://rustsec.org/packages/<name>.html` and
`/advisories/<id>.html` via `curl -sS`. **Authentication note:** unauthenticated
`api.github.com` returned **HTTP 403** (rate limit) on the first probe, so all
GitHub REST calls were made authenticated through `gh api`, which requests the
same REST endpoints listed above. **The RustSec 404 rule was established
empirically, not assumed:** `https://rustsec.org/packages/atty.html` was fetched
as a positive control and returned HTTP 200 listing RUSTSEC-2021-0145 and
RUSTSEC-2024-0375, while clean crates return HTTP 404 with no advisory page; a
404 is therefore read as "no advisories", and the three 200s found
(`anyhow`, `eyre`, `directories`) were each opened and assessed individually.
**MSRV floor** was derived from
`https://api.github.com/repos/rust-lang/rust/releases/latest` (1.98.1) rather than
from the local toolchain, giving a floor of 1.96.

*Corrections made during review, recorded rather than silently applied:*
(a) An earlier draft cited `sleep 30 & kill -INT` returning 0 as evidence about
the default `SIGINT` disposition. That measurement was confounded — POSIX has a
non-interactive shell's asynchronous list inherit `SIG_IGN` for `SIGINT`, so the
child ignored the signal. It was replaced with a controlled measurement (a child
spawned with `SIGINT` restored to `SIG_DFL`, wait-status **-2**), and the
confound itself turned out to be a genuine tradeoff, now recorded in the
`signal-hook` member. (b) An earlier draft excluded `miette` under gate 1 for
being Apache-2.0-only; that was wrong — a dependency's license does not relicense
this repository, and `docs/port/PARAMETERS.md` says every MIT-compatible crate is
compatible with the dual license. `miette` is recorded as passing every gate and
not chosen on fit. (c) Issue-responsiveness figures for the non-recommended
candidates (`snafu`, `eyre`, `miette`, `strum`, `dialoguer`, `sigpipe`) were
absent from an earlier draft and have been measured and added, using the same
method as the recommended crates.

*Could not verify / not executed, stated rather than inferred:*
(1) **Linux execution** — every acceptance check ran on macOS (Darwin 25.4) only;
`ubuntu-latest` behavior is asserted from the crates' Unix support and from
ripgrep/fd/Nushell practice, not measured. (2) **The web-surface signal path** —
`tokio::signal` `SIGTERM` draining was not built, because R05 and R69 have not
selected a runtime or framework. (3) **`inquire`'s cancellation in practice** —
`InquireError::OperationInterrupted` was verified by reading the crate's
`error.rs`, not by triggering it, which needs a TTY this run did not have.
(4) **`inquire`'s `unsafe` posture** — not measured, as the crate was not vendored
into the acceptance workspace; every other recommended crate's `unsafe` count was
measured by grep over vendored source. (5) **Issue-responsiveness for
`human-panic` and `sysexits`** — recorded `inapplicable`: the 25 most recent
tracker items for `human-panic` were all pull requests and `sysexits` has zero
open issues, so the "10 most recently opened issues" sample was empty in both
cases. (6) **`exitcode` and `directories` MSRV (gate 2)** — neither declares
`rust_version` in its manifest, so the gate could not be verified from metadata;
`exitcode` was instead *compiled and run* on stable 1.98.0 in an edition-2024
workspace as a direct substitute check, and `directories` was excluded on archival
before the gate mattered. (7) **The `unanswered` counts for `thiserror` and
`anyhow`** (7 and 4 of 10) are reported as measured but are known to overstate
neglect for this maintainer, who commonly closes issues by referencing them from
fix commits rather than commenting; no attempt was made to correct the figure, and
the caveat is recorded instead of a silent adjustment. (8) **No other engine's
output for R67 was read**, per the role contract; `raw/codex.md` exists in this
run directory and was deliberately not opened.
