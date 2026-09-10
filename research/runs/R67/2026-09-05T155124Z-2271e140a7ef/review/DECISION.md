# R67 — Error and exit-code contract (bundle, Deep, keystone) — revision 3, 2026-09-10

Synthesized 2026-09-09 from three engines' raw reports (five provider bodies) plus
the verification runs recorded under `## Empirical check`. This is a research
decision for P03 to implement; no template code exists and none was written here.

## Decision

**Status.** This is a **proposal**, to be validated in the implementation phase
(P03) against the real template. Everything below rests on registry queries,
source reads at pinned versions, standards reads, and a dependency resolution and
audit — not on a working implementation, which does not exist yet. Where a
recommendation here does not survive contact with the built template, the
correction is made **against this recorded research** — its principles, its
compared alternatives, its verified mechanisms and its `## Engines` disagreement
resolutions — rather than by researching the item again from scratch. The owner
has not yet reviewed R67; no acceptance is claimed or implied.

Adopt a **two-layer error contract**: a project-owned, append-only `ErrorCode`
catalog and `Exit` taxonomy in the library crate, and an opaque context carrier at
the binary boundary. The named stack, with the exact version requirements that
resolved and audited clean on 2026-09-09:

| Slot | Selection | Where it goes |
|---|---|---|
| Typed domain errors | `thiserror = "2.0.20"` | library crate only |
| Boundary context carrier | `anyhow = "1.0.104"` (floor **`>= 1.0.103`**, RUSTSEC-2026-0190) | binary crates only; the library **must not** depend on it |
| Signals (SIGINT/SIGTERM) | `signal-hook = { version = "0.4.4", default-features = false }` under `[target.'cfg(unix)'.dependencies]` | CLI binary only |
| Error envelope serialization | `serde_json = "1.0.151"` (F294, already settled) | binary crates |
| Exit-code carrier | `std::process::ExitCode` + `Termination`, returned from `main` | library declares, binary returns |
| Broken pipe | `std::io::ErrorKind::BrokenPipe` on fallible writes | binary boundary |
| Backtrace | `std::backtrace::Backtrace::capture` (environment-gated) | binary boundary |
| Crash record | `std::fs` behind an injected sink; **location deferred to R57** | CLI binary only |
| Prompt cancellation | no crate selected — a typed-interruption adapter, contingent on R61 | CLI binary only |

Rejected, each for a stated reason rather than popularity: `strum`
(deriving the wire code from a variant identifier reproduces the exact ts defect
this item exists to fix), `ctrlc` (its `set_handler` callback takes no signal
argument, so 130 and 143 cannot be told apart — source read below), `miette`
(a diagnostic *renderer*; its `code` is a dynamic `Display` value, and R66 owns
rendering), `exitcode`/`sysexits` (BSD `sysexits.h`, which the owner's own CLI
Design Standard rejects by name), `human-panic` (covers panics, not returned
errors, and writes a crash file to a location this item may not choose),
`directories` (**archived** 2025-01-12), and a `SIGPIPE` handler or
`-Zon-broken-pipe` (nightly-only; tracking issue still open).

**Ledger rows settled.** `F295` (envelope `code` source), `F296` (structured
`hint`), `F297` (exit-code taxonomy), `F298` (Ctrl-C contract), `F299` (prompt
cancellation — contract defined, activation contingent on R61), `F300` (broken
pipe), `F302` (crash-log persistence — capability decided, location deferred to
R57). `F294` and `F301` stay settled elsewhere and are not re-decided here; the
`F301` baseline review below is carried, not adopted.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is
required.** A failure must present a *stable machine identity* and a
*conventional process status*, independently of the implementation type that
produced it. The source is the divergence between py's stable append-only string
catalog (`py src/py_launch_blueprint/core/errors.py:51` — `ERROR_CODE_UNEXPECTED
= "PLBP000"`) and ts's transient exception-class name (`ts src/router.ts:211` —
`const code = err instanceof Error ? err.name : 'Error';`), recorded as ledger
rows F295–F300 and F302 (`docs/port/COMMONALITY.md:299-305`, verdict `DIVERGENT`).

Agreement is required at five different levels, and conflating them is what
produces a wrong answer here:

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | A failure's public identity is a documented token that survives refactoring | **standard** | that the token is stable, append-only and documented | the token's *spelling* (each repo's prefix is its own repo identifier) |
| P2 | Process exit codes come from one org-normative taxonomy | **standard, one value for all three repos** | the integers `0/1/2/3/4/5/130/143` and their meanings | how each runtime returns them |
| P3 | A failure carries a separately addressable remedy | **capability** | that the remedy is a distinct machine-addressable field | how it is rendered |
| P4 | Termination is predictable when the OS or a downstream reader intervenes | **capability + P2's integers** | the observable outcome (130/143; a closed pipe is silent and successful) | the mechanism, which is genuinely language-bound |
| P5 | An unexpected failure can be persisted for post-hoc diagnosis | **capability** | that the capability exists and never changes the exit code | the location, the format, and whether it is on by default |

P2 is not an ecosystem judgement call: the "external cli-standards spec"
behind ts's D-016(2) is the owner's CLI Design Standard, whose **R6.1** is marked
`(MUST)` and `org-locked` (`/Users/stevemorin/c/cli-standards/cli-design-standard.md:351`,
with the org decision row at `:70`, read 2026-09-09). Read on 2026-09-09 it states the table verbatim —
`0` success, `1` generic runtime error, `2` usage/parse error, `3` not found,
`4` authentication or authorization required, `5` conflict/precondition failed,
`130` interrupted by `SIGINT`, `143` terminated by `SIGTERM` — adds "Unlisted
failures collapse to `1`", and rejects `sysexits.h` (64–78) by name as
"over-specified and unavailable on Windows" — a rejection independently sound
against the header itself
(`https://cgit.freebsd.org/src/plain/include/sysexits.h`, retrieved 2026-09-09:
`EX_USAGE 64`, `EX_CONFIG 78`, `EX__MAX 78`), whose mail-transport categories do
not describe this template's failures. `R9.6 (MUST)` separately requires a
clean `SIGINT`→130, a clean `SIGTERM`→143, and that `SIGPIPE`/EPIPE exit quietly
"without a broken-pipe stack trace". `R7.8 (MUST)` fixes the envelope as a single
stderr object `{"error":{"code":"<stable-string>","message":"<human-readable>"}}`
that **MAY** carry "other documented fields" — which is the authority that lets
`hint` be a peer field rather than inlined prose. `R7.7 (MUST)` requires flushing
all streams before exiting *on every path, including signal*.

**Essential behaviors.**

1. The envelope `code` is produced by one explicit `const fn` returning a literal
   string. It is never `Debug`, `Display`, `std::any::type_name`, a serde variant
   name, a discriminant, or a `strum` derive.
2. Every catalog entry has exactly one exit code, and the mapping is a total
   function proved total by test rather than by comment.
3. Codes are append-only: never renamed, never reassigned, never deleted; a
   retired code stays documented as deprecated.
4. `hint` is optional, structured, non-secret, and omitted (not `null`) when absent.
5. The binary returns `ExitCode` from `main`; it does not call `process::exit`
   on the normal error path.
6. Boundary precedence is fixed: **signal → broken pipe → domain error →
   unexpected**. A `SIGINT` delivered while a write is failing reports 130.
7. A benign broken pipe on the *result* stream ends the process at `0`, silently,
   with no envelope and no second stderr record.
8. Importing the library installs no signal handler, no panic hook, and writes to
   no process stream or file.

**Observable acceptance criteria** (proposals for P03 — none was executed here;
see `## Empirical check` for what was and was not run):

| # | Criterion |
|---|---|
| AC1 | Human mode prints `error[<CODE>]: <message>` and a separate `hint:` line; exit is the mapped code |
| AC2 | Machine mode puts exactly one `{"error":{…}}` object on stderr and leaves stdout byte-empty |
| AC3 | usage→2, not-found→3, auth→4, conflict→5, runtime/unexpected→1 |
| AC4 | `SIGINT`→130 and `SIGTERM`→143, with destructors run and streams flushed (R7.7, R9.6) |
| AC5 | `<binary> … \| head -1` exits 0 with empty stderr and no panic |
| AC6 | A catalog test fails if any pinned row changes and if any variant lacks a code or an exit |
| AC7 | A crash-record write failure leaves the exit code and the envelope unchanged |
| AC8 | A library-only test proves no handler, hook, stream write or file write on import |

**Architectural alternatives compared, before any library was chosen.**

| Alt | Shape | Verdict and the principle at stake |
|---|---|---|
| A1 | One opaque carrier everywhere (`anyhow` only; codes as context strings) | **Rejected.** It is ripgrep's shape and works there because ripgrep has no library consumers. Here R70 needs an exhaustive domain-error→HTTP-status table and R03/R52–R56 must pattern-match; an opaque carrier degrades that to string comparison, losing P1's reviewability. |
| A2 | One typed enum everywhere, no carrier | **Rejected.** Every incidental `io::Error` must either get a domain variant or be flattened into a catch-all that drops its cause chain, and the library ends up owning variants only the binary can produce. |
| A3 | **Two layers** — typed enum + catalog in the library; opaque carrier at the binary boundary that downcasts to the domain type and otherwise falls back to UNEXPECTED | **Chosen.** Preserves P1 (the catalog is an independent, reviewable fact), gives R03/R70 their match, and gives the binary a context chain without polluting the library. It is also what Cargo, Ruff, Nushell and bat do (manifests verified below). |
| A4 | Derive the code from the variant identifier (`strum`, `type_name`) | **Rejected, and this is the direct answer to the first HIGH question.** A variant rename is a compiler-checked, silent refactor in Rust — which is exactly why a derived code is dangerous: the refactor compiles and breaks the wire. This reproduces ts `src/router.ts:211`. |
| A5 | `Box<dyn DomainError>` with a `code()` method | **Rejected.** Loses exhaustive `match`, which is the property R70 depends on, and imposes dynamic dispatch on a seam R01 has not decided. |

**How the selected design preserves each principle.**

*P1.* The catalog lives in one place as an explicit `#[non_exhaustive] enum
ErrorCode` with a `const fn as_str(&self) -> &'static str` returning literals, a
`pub const ALL: &[ErrorCode]` listing every member in registration order, and a
test that pins existing `(code, exit)` rows and permits only appends. The
`#[non_exhaustive]` attribute is required rather than stylistic: the Cargo SemVer
reference (`https://doc.rust-lang.org/cargo/reference/semver.html`, retrieved
2026-09-09) states that "adding new enum variants (without `non_exhaustive`)" is
a **major** breaking change, and that adding variants **is** non-breaking when the
enum uses `#[non_exhaustive]` (read 2026-09-09). The cost is that a *different*
crate — R70's web crate — cannot match exhaustively and needs a `_ =>` arm. The
`ALL` constant is the compensation: R70's status table is coverage-tested by
iterating `ErrorCode::ALL` and asserting every member maps, so totality is
enforced by a failing test instead of by the compiler. This is the one place the
design is stronger than both sources: py's `errors.py` catalog has no such test.

*P2.* `#[repr(u8)] enum Exit` carries the R6.1 integers and converts through
`impl From<Exit> for std::process::ExitCode`. `ExitCode`, `Termination` and
`From<u8> for ExitCode` are all `#[stable(feature = "process_exitcode", since =
"1.61.0")]` / `"termination_trait_lib", since = "1.61.0"` in
`https://raw.githubusercontent.com/rust-lang/rust/1.96.0/library/std/src/process.rs`
(retrieved 2026-09-09) — read at tag `1.96.0`, the MSRV-policy floor — so nothing here is
newer than the floor allows.

*P3.* `hint()` is a peer of `code()`, serialized as a separate `hint` key and
rendered as a separate line. R7.8 permits the extra documented field; R66 owns
how it is presented. This keeps py's structure and avoids ts's parsing-hostile
inline remedy text. The contract term is only "an optional structured string,
omitted when absent"; the signature is P03's, and it must be able to *name the
offending input* as R7.6 requires — `error: project 'demo' not found` — so a
`&'static str` return would be too narrow and a borrowed-or-owned string
(OpenAI's `Option<Cow<'_, str>>`) is the shape to expect. Only the *code* is
literal: `as_str()` returns `&'static str` because codes never interpolate.

*P4.* Two mechanisms, one observable outcome. Signals use `signal-hook`'s
`flag::register(signal: c_int, flag: Arc<AtomicBool>)`
(`https://static.crates.io/crates/signal-hook/signal-hook-0.4.4.crate`, sha256
`b2a0c28ca5908dbdbcd52e6fdaa00358ab88637f8ab33e1f188dd510eb44b53d`, retrieved
2026-09-09) — one registration **per
signal number**, which is what makes 130 and 143 distinguishable. The handler
stores a flag and nothing else; cancellation is cooperative, so destructors run
and R7.7's flush requirement is satisfiable. Broken pipe is *not* a signal in
Rust: `https://raw.githubusercontent.com/rust-lang/rust/1.96.0/library/std/src/sys/pal/unix/mod.rs`
(retrieved 2026-09-09) sets `SIGPIPE` to `SIG_IGN` at runtime init with the comment "we set SIGPIPE to ignore when the program
starts up", so a failed write returns `io::Error` instead. That makes
`println!`/`print!` unusable on any pipeline-facing path: `print_to` in
`https://raw.githubusercontent.com/rust-lang/rust/1.96.0/library/std/src/io/stdio.rs`
(retrieved 2026-09-09) is documented "if the actual I/O causes
an error, this function does panic" and its body is
`if let Err(e) = global_s().write_fmt(args) { panic!("failed printing to {label}: {e}"); }`.
The rule is therefore a *lint*, not a library: deny `clippy::print_stdout` /
`print_stderr` in the binary crates (wiring owned by R28), and write through a
locked handle whose `BrokenPipe` result ends the process at 0.

*P5.* The crash record is a capability, not a fixed file. See the crash-log
paragraph below.

**Where a different ecosystem needs a different design.** Three places, each with
a verified mechanism rather than an assertion. (a) *Broken pipe*: Node needs an
`error` listener (`ts src/cli.ts:17`), Python needs nothing, Rust needs **more**
than either because its runtime converts EPIPE to an `io::Error` that `println!`
turns into a panic. The language-level fix is unavailable:
`https://github.com/rust-lang/rust/issues/97889` ("Tracking Issue for
`unix_sigpipe`") is **open** as of `updated_at` 2026-08-12, as is
`https://github.com/rust-lang/rust/issues/62569` ("Should Rust still ignore
SIGPIPE by default?") — both retrieved 2026-09-09, so `-Zon-broken-pipe` is nightly-only and excluded by the stable-Rust
constraint. (b) *Signals*: ts gets two handlers and two codes for free; Rust must
pick a crate that reports *which* signal fired. (c) *Backtrace*: py and ts both
capture unconditionally and gate only display; Rust gates **capture** on an
environment variable, so display-gating alone is not implementable — see the
F301 boundary below.

**Answering the MEDIUM SIGTERM question, whose premise needs correcting.** The
question asks whether SIGINT-only suffices "for a CLI template with no
long-running daemon mode". That premise does not hold: the target shape is CLI +
library + **web service** (spec §4 D7; `web-extra-surface` owned by R69), and a
container runtime stops a web process with `SIGTERM` before escalating to
`SIGKILL`. R9.6 makes `SIGTERM`→143 a `MUST` independently. Handle both. The
mechanism differs by surface — the synchronous CLI path uses `signal-hook`, and
an async web binary will want its runtime's own signal source — but the *codes*
are identical, which is the part P2 requires to agree. R05 owns the sync/async
model; this item does not choose it.

**`ctrlc` is excluded by a source read, not by preference.** The Rust CLI Working
Group book's signals chapter (`https://rust-cli.github.io/book/in-depth/signals.html`,
source `https://raw.githubusercontent.com/rust-cli/book/master/src/in-depth/signals.md`,
retrieved 2026-09-09; its exit-code chapter is
`https://rust-cli.github.io/book/in-depth/exit-code.html`) names `ctrlc`, so it is the
ecosystem's default lead and had to be tested rather than waved off. Reading the
published crate at the pinned version settles it — the published tarball is
`https://static.crates.io/crates/ctrlc/ctrlc-3.5.2.crate` (sha256
`e0b1fab2ae45819af2d0731d60f2afe17227ebb1a1538a236da84c93e9a60162`, retrieved
2026-09-09) — in `ctrlc-3.5.2/src/lib.rs:93`
the signature is `pub fn set_handler<F>(user_handler: F) -> Result<(), Error>
where F: FnMut() + 'static + Send` — **the callback receives no signal argument**
— and the crate's own docs at `:45-46` state that with the `termination` feature
"the handler specified by `set_handler()` will be executed for `SIGINT`,
`SIGTERM` and `SIGHUP`". `src/platform/unix/mod.rs:92-123` confirms all three are
routed to one `sigaction`. `ctrlc` therefore *cannot* produce distinct 130/143,
which R9.6 requires. It stays the ranked runner-up only if the owner drops the
SIGTERM contract, which R9.6 forbids.

**`anyhow`'s advisory is real, and the floor is load-bearing.**
`RUSTSEC-2026-0190` (`https://rustsec.org/advisories/RUSTSEC-2026-0190`; text read
from `https://raw.githubusercontent.com/rustsec/advisory-db/main/crates/anyhow/RUSTSEC-2026-0190.md`,
retrieved 2026-09-09) is filed against `anyhow` (`informational = "unsound"`,
`categories = ["memory-corruption"]`, `affected.functions
"anyhow::Error::downcast_mut" = ["< 1.0.103"]`, `patched = [">= 1.0.103"]`). The
recommended boundary calls `downcast_ref`, never `downcast_mut`, so the gate is
passed twice over — but the requirement is written `"1.0.104"` rather than
`"1.0"` because a stale lockfile can hold an affected version: pinning
`=1.0.102` in a manifest-only control made `cargo audit` report the advisory,
while the recommended set audited clean. That control is the evidence that
`cargo audit` in CI (R13's `deny.toml`) is non-optional for this stack.

**The exit code for a configuration failure — where the engines split, and what
the standard actually says.** codex maps all configuration faults to `1`; opus,
OpenAI and Perplexity map them all to `2`. Neither is right, and R6.1 plus R8.2
resolve it by splitting the case: R8.2 `(MUST)` assigns exit `2` when "required
non-auth input or consent is missing" and exit `1` for "runtime input failures
such as unreadable files". So a config document the user authored incorrectly
(unparsable, or a value violating the schema) is exit **2**, and a config file
that cannot be read (permissions, I/O) is exit **1**. Both get their own catalog
entries so R54–R56 can route to either without inventing a code. R55 and R56 own
whether a given condition is tolerated, warned about, or fatal; this item only
guarantees the entry and the code exist.

**Crash-log persistence (F302) — the capability is adopted, the location is
not.** codex recommends shipping no crash log at all, on two grounds: secret
retention, and that a fixed path would pre-empt R57. Both objections are sound
and neither requires dropping the capability. The contract is therefore: an
**injected sink** at the CLI process boundary, offered only the UNEXPECTED class,
writing newline-delimited JSON at mode `0600` containing timestamp, version, PID,
stable code and sanitized cause chain — and **never** argv, environment values,
headers, tokens or configuration contents. A create/serialize/append/permission
failure is swallowed and never changes the envelope or the exit code. No default
path is chosen here and no fallback (`/tmp`, `~/.local/state`, a macOS Library
path) is blessed: R57 owns the state directory, and until it answers the default
sink is a no-op. This preserves P5 as a *capability* — the level at which
agreement is required — without deciding another item's parameter, and it is why
no `CONFLICT:` line is raised.

**Prompt cancellation (F299) is defined and dormant.** `inquire` 0.9.4's `src/error.rs:12-33`
(`https://static.crates.io/crates/inquire/inquire-0.9.4.crate`, sha256
`6654738b8024300cf062d04a1c13c10c8e2cea598ec1c47dc9b6641159429756`, retrieved
2026-09-09) does expose two distinct typed variants,
`InquireError::OperationCanceled` ("Operation was canceled by the user", i.e.
ESC) and `InquireError::OperationInterrupted` (documented as "interrupted by the
user after they pressed Ctrl+C"), so a typed-adapter contract is achievable. But
R61 owns whether any prompt crate is adopted, and `inquire` would need its own
gate pass (MIT, `rust_version` 1.80.0, 59 open issues). This item therefore
defines `RSLB903 → 130` and requires that whichever crate R61 picks be adapted to
it without leaking the crate's own error text; ESC-cancellation versus Ctrl-C
interruption is a product question for R61, not a signal question for R67. No
prompt-local Ctrl-C handler may be installed — it would race the process-level
contract and can produce duplicate output.

**Reference implementations, and the evidence they are well regarded.** Every
manifest below was fetched from
`https://raw.githubusercontent.com/<org>/<repo>/<default-branch>/Cargo.toml` on
2026-09-09;
"well regarded" is adoption and maintainer standing, not assertion.

| Project | Why it counts | `rust-version` | Relevant declarations |
|---|---|---|---|
| Cargo (`rust-lang/cargo`) | the Rust project's own build tool | 1.95 (workspace) | `anyhow = "1.0.102"`, `thiserror = "2.0.18"` |
| Ruff (`astral-sh/ruff`) | Astral's Python linter, a fast-growing Rust CLI | **1.96** | `anyhow = "1.0.80"`, `thiserror = "2.0.0"`, `strum = "0.28.0"`, `etcetera = "0.11.0"` |
| Nushell (`nushell/nushell`) | a widely adopted Rust shell | 1.96.1 | `anyhow = "1.0.104"`, `thiserror = "2.0.20"`, `ctrlc = "3.5.2"`, `miette = "7.6"` |
| bat (`sharkdp/bat`) | among the most-installed Rust CLI tools | 1.88 | `anyhow = "1.0.97"`, `thiserror = "2.0"`, `etcetera = "0.11.0"` |
| ripgrep (`BurntSushi/ripgrep`) | the de-facto Rust CLI reference | 1.96 | `anyhow = "1.0.75"`; **no `thiserror`** — it has no library consumers |
| fd (`sharkdp/fd`) | same maintainer, same tier of adoption | 1.90.0 | `anyhow = "1.0"`, `ctrlc = "3.5"`, `etcetera = "0.11"` |
| cargo-nextest (`nextest-rs/nextest`) | the standard third-party Rust test runner | 1.91 | `color-eyre = "0.6.5"`, `thiserror = "2.0.20"`, `miette = "7.6.0"` |

Two things fall out. The `thiserror` (library, typed) + `anyhow` (binary, opaque)
split is not taste — four of the seven do exactly that, and the one that does not
is the one with no library surface. And `etcetera` has displaced `directories` in
newer projects; `directories` is **archived**
(`https://api.github.com/repos/dirs-dev/directories-rs` → `archived: true`, last
push 2025-01-12, retrieved 2026-09-09), which disqualifies Gemini's crash-log
path suggestion outright.

`https://raw.githubusercontent.com/BurntSushi/ripgrep/master/crates/core/main.rs`
(retrieved 2026-09-09) is the canonical reference for the boundary this
item specifies, and it is worth quoting because it is the same four steps:
`fn main() -> ExitCode` matches on `run(...)`, and on error walks `err.chain()`,
`downcast_ref::<std::io::Error>()`, and `if ioerr.kind() ==
std::io::ErrorKind::BrokenPipe { return ExitCode::from(0); }` — with the comment
"We need to handle this explicitly since the Rust runtime doesn't ask for PIPE
signals, and thus we get an I/O error instead."

**Maturity, dependability and integration cost.** `thiserror` (350,390,985
90-day downloads) and `anyhow` (206,068,310) share a maintainer and a deliberately
compatible design: `anyhow::Error` accepts any `std::error::Error + Send + Sync +
'static`, which is what `thiserror`'s derive produces, so the boundary
`downcast_ref::<CoreError>()` is a supported path and not a coincidence. Nothing
in the stack declares an async runtime, so R05 and R69 stay unconstrained.
Integration cost, measured by resolution rather than by build: resolved against
the two-crate manifest set at `review/empirical/rslb-contract`, the stack locks
**20 packages** with **zero duplicate versions** at "latest Rust 1.96 compatible
versions", and `cargo audit` scans **22 crate dependencies** with no findings. Performance is deliberately not a ranking axis: every mechanism here runs
once per process, on an error or a signal. The costs that do matter — compile
time, binary size, and any helper thread — are why `signal-hook` is taken with
`default-features = false` (its `flag` API needs neither the `channel` nor
`iterator` default, and `iterator` would introduce a helper thread) and why
`ctrlc` would be the more expensive choice even if it worked, since it pulls
`nix`.

**BASELINE-REVIEW carried, not adopted.**

BASELINE-REVIEW: F301 — an unexpected error's stack trace reaches the user only when they asked for diagnostics — proposed change: keep the row's existence settled but assign its acceptance criteria to R67, namely (a) the capture mechanism and (b) whether machine (JSON) mode suppresses the trace — evidence: display-gating alone is not implementable in Rust because capture itself is environment-gated: `https://raw.githubusercontent.com/rust-lang/rust/1.96.0/library/std/src/backtrace.rs`
(retrieved 2026-09-09) documents `Backtrace::capture` as "a noop if the `RUST_BACKTRACE` or `RUST_LIB_BACKTRACE` backtrace variables are both not set" and its body returns `Inner::Disabled` unless `Backtrace::enabled()`, while `force_capture` "ignores the values of the `RUST_BACKTRACE` and `RUST_LIB_BACKTRACE` environment variables"; and the two sources disagree on (b), py `src/py_launch_blueprint/cli/options.py:227-228` printing the traceback with no mode check while ts `src/router.ts:210-218` returns before the trace gate at `:223` (`docs/port/BASELINE-REVIEW.md:154`, owner question at `:194`).

The prompt's `- owns:` line lists **only** `error-taxonomy-exit-codes`, so this
item does **not** claim the backtrace capture rule, and — corrected in revision
3 — publishes no trace rule in its owned parameter either. Both criteria are
stated here as assumptions, not published contract: that no backtrace is captured
unless `RUST_BACKTRACE`/`RUST_LIB_BACKTRACE` is set (`capture`, never
`force_capture`), and that a captured trace reaches only human verbose mode and
the crash record. What the owned parameter *does* publish is narrower and is
squarely this item's own (F295/F296): the envelope has the three keys `code`,
`message` and optional `hint`, and this item defines no further field. A trace
therefore has no field to occupy — but that is a consequence of the field list,
not a disclosure rule, and this item asserts none. If the owner accepts the
amendment, R67 publishes the two criteria; if not, they stay P03 implementation
choices. OpenAI's proposal to use
`force_capture` for the UNEXPECTED code is explicitly **not** adopted: it would
change the cost and privacy contract the owner has not yet dispositioned.

re-verify: 2027-03-09, or earlier on any of — a RustSec advisory against `thiserror`, `anyhow` or `signal-hook`; `rust-lang/rust#97889` closing or `-Zon-broken-pipe` stabilizing (the `println!` ban could then relax); R57 answering (the crash-record path is finalized); R61 answering (`RSLB903` is wired to a typed variant or retired before first release); R05/R69 selecting the async model (the web `SIGTERM` drain path becomes buildable); R60 selecting a parser that does not exit 2 on usage errors; the owner dispositioning the F301 amendment; or Rust stable advancing far enough that the MSRV floor rises above a recommended crate's declared `rust-version` (the highest anywhere in the resolved tree is **1.71**, shared by eleven dependencies, so the current 1.96 floor has wide headroom and this trigger is remote).

## Parameters

- owns error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

One `CONFLICT:` line was raised by a raw report and is **recorded here without
being escalated**, because it does not meet the protocol's precondition. The
Perplexity provider body wrote, verbatim
(`raw/doxa-perplexity.normalized.md:571`):

> CONFLICT: R57 state-directory — needs a writable state directory path for crash logs — reason: crash-log persistence requires a location; until R57 is decided, this member assumes a default path but must be updated to consume R57's parameter.

The prompt reserves `CONFLICT:` for the case where a recommendation needs a
**consumed** parameter's value to change. This item's `## Couplings` records
`consumes:` as empty; `research/CLAUDE.md` shows R57 with `owns: —`, so no
parameter named `state-directory` exists to be in conflict with; and the prompt's
own `related` note directs this item to "treat the state-directory question as
open, state the assumption made, and do not block on R57's answer". The line's
substance is also answered rather than deferred: this decision assumes **no**
default path (Perplexity's "this member assumes a default path" is the premise
that creates its conflict), leaves the crash sink a no-op until R57 answers, and
therefore needs nothing from R57 to be implementable. **This decision raises no
`CONFLICT:` line of its own.**

The four cross-item dependencies are assumptions satisfiable in either direction and
are stated rather than escalated: R57 (`xdg-directory-set`) supplies the crash
record's location and the contract holds with the sink disabled until it does;
R61 (`interactive-prompts`) decides whether `RSLB903` is ever produced;
R05 (`sync-async-execution-model`) and R69 (`web-extra-surface`) decide the web
surface's signal source, which must return the same 130/143; R66
(`output-format-surface`) renders `hint` as a distinct field or line and owns the
locked-handle writer this contract's broken-pipe rule assumes.

## Empirical check

**Toolchain and host.** `rustc --version` → `rustc 1.98.0 (88d9e12ae 2026-08-18)
(Homebrew)`; `cargo --version` → `cargo 1.98.0 (797e8a9bc 2026-08-05)
(Homebrew)`; `cargo-audit` at `/Users/stevemorin/.cargo/bin/cargo-audit`. OS:
macOS 26.4 (`Darwin 25.4.0`, arm64). Current Rust stable at retrieval is
**1.98.1**, published 2026-09-03 (`gh api repos/rust-lang/rust/releases/latest`),
so the `msrv-policy` floor "stable minus 2 minor versions" resolves to **1.96**
for this run; every std source read below was taken at tag `1.96.0`, not at the
host's 1.98.0, so it proves availability *at the floor*.

**Working directories.** All API queries and source reads ran from
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. E13 and E14 were **rerun on
2026-09-10 for this revision** against the three manifests as they now stand at
`review/empirical/rslb-contract` (a workspace root plus `crates/rslb-core` and
`crates/rslb-cli`, and no Rust source at all). That fixture was **not mutated**:
because Cargo cannot load a package with no target, the three `Cargo.toml` files
were copied byte-identically — the copy's and the fixture's sha256 sums are both
recorded in the log — into a scratchpad directory and given two **empty** target
stubs (`crates/rslb-core/src/lib.rs`, `crates/rslb-cli/src/main.rs`) solely so
the manifests parse. The `anyhow = "=1.0.102"` control is the same workspace with
that one requirement changed. Nothing was built and no template code, seam,
harness or scaffold was written: the checks resolve, inspect and audit *version
requirements*, which is what the recommendation is. Every command's full output
is in `review/evidence/`.

An **earlier, narrower observation** is retained above the continuation header in
`review/evidence/dependency-resolution.log` and is not the source of any figure
below: a single-package manifest resolved on 2026-09-09 that additionally carried
`etcetera = "0.11.0"`. Its scope was "do the pinned requirements co-resolve at
all", and within that scope it answered; but `etcetera` is a crate **this
decision does not select** — the crash-log location is deferred to R57 — so its
22-package / 23-crate figures describe a graph wider than the recommendation and
are superseded here. The audit that caught the mismatch is recorded under
`## Engines`.

| # | Command (abbreviated; full text in the log) | Exit | What it verified | Log |
|---|---|---|---|---|
| E1 | `curl https://crates.io/api/v1/crates/<n>` and `/versions` for 12 crates | 0 (all HTTP 200) | 90-day and all-time downloads, newest non-yanked `num`/`created_at`/`rust_version`/`license`/default features | `crates-io.log` |
| E2 | `gh api repos/<o>/<r>` for 11 repositories | 0 | `stargazers_count`, `archived`, `pushed_at` | `github-api.log` |
| E3 | `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` ×5 | 0 | open **issue** counts (not `open_issues_count`) | `github-issue-search.log` |
| E4 | `curl -w '%{http_code}' https://rustsec.org/packages/<n>.html` ×5, then `gh api repos/rustsec/advisory-db/contents/crates/<n>` ×5 | 0 | advisory status per package. A 404 on the package page is zero-advisory evidence **only because of its two paired controls**, both run here: the same endpoint returns **200 for `anyhow`**, whose page is backed by RUSTSEC-2026-0190, and the advisory-db API agrees independently (404 for each absent `crates/<n>` directory, 200 listing `RUSTSEC-2026-0190.md` for `anyhow`). A bare 404, unpaired, would prove nothing | `rustsec.log` |
| E5 | `curl …/advisory-db/main/crates/anyhow/RUSTSEC-2026-0190.md` | 0 | the advisory's own text | `rustsec.log` |
| E6 | `curl https://static.crates.io/crates/ctrlc/ctrlc-3.5.2.crate` → `tar xzf` → `grep 'pub fn set_handler' -A14 src/lib.rs`, `grep termination -B3 -A8 src/lib.rs`, `grep SIG… src/platform/unix/mod.rs` | 0 | `ctrlc`'s handler takes no signal argument; `termination` fans SIGINT/SIGTERM/SIGHUP into one handler. **A source-interface finding only** — it settles what the crate's API can express, and demonstrates no signal, prompt, EPIPE, flushing or destructor behaviour | `ctrlc-source-3.5.2.log` |
| E7 | same for `signal-hook-0.4.4` and `inquire-0.9.4` | 0 | `flag::register(signal: c_int, flag: Arc<AtomicBool>)` is per-signal; defaults are `channel`+`iterator`; `InquireError::{OperationCanceled, OperationInterrupted}` exist as typed variants. **A source-interface finding only**, on the same terms as E6: no signal, prompt, EPIPE, flushing or destructor behaviour is demonstrated | `signal-hook-inquire-source.log` |
| E8 | `curl raw…/rust-lang/rust/1.96.0/library/std/src/{process.rs,io/stdio.rs,sys/pal/unix/mod.rs,backtrace.rs}` + targeted `grep` | 0 (HTTP 200) | `ExitCode`/`Termination`/`From<u8>` stable since 1.61.0; `process::exit` runs no destructors; `print_to` panics on a failed write; the runtime sets `SIGPIPE` to `SIG_IGN`; `capture` is env-gated and `force_capture` is not | `std-at-msrv-floor-1.96.0.log` |
| E9 | `gh api repos/rust-lang/rust/issues/{97889,62569}`; `curl doc.rust-lang.org/cargo/reference/semver.html`; `curl raw…/rust-cli/book/master/src/in-depth/{exit-code,signals}.md` | 0 | both SIGPIPE tracking issues **open**; adding an enum variant without `#[non_exhaustive]` is major; the CLI-WG book names `exitcode` and `ctrlc` | `ecosystem-authorities.log` |
| E10 | `sed -n '349,400p' /Users/stevemorin/c/cli-standards/cli-design-standard.md` and greps for R7.6–R7.8, R8.2, R9.6 | 0 | R6.1's exact table, "unlisted failures collapse to 1", the explicit `sysexits.h` rejection, R7.8's single-object schema with optional documented fields, R7.7's flush-on-every-path, R9.6's 130/143/EPIPE MUSTs, R8.2's 2/4/1 split | `cli-design-standard-R6-R7.log` |
| E11 | `curl https://cgit.freebsd.org/src/plain/include/sysexits.h` | 0 (HTTP 200) | `EX_USAGE 64`, `EX_CONFIG 78`, `EX__MAX 78` — the raws' BSD figures are correct | `sysexits-h.log` |
| E12 | `curl raw…/Cargo.toml` for 7 reference projects; `curl raw…/ripgrep/master/crates/core/main.rs` | 0 | the `thiserror`+`anyhow` split and the `etcetera`-over-`directories` shift; ripgrep's `fn main() -> ExitCode` + chain-walk + `BrokenPipe → ExitCode::from(0)` | `adopter-manifests.log`, `reference-implementations.log` |
| E13 | (rerun 2026-09-10 against `review/empirical/rslb-contract`) `cargo generate-lockfile` → `cargo tree -e normal` → `cargo tree -d` → `cargo metadata … \| jq` | 0 | **20 packages locked, "latest Rust 1.96 compatible versions", zero duplicate resolutions** (`cargo tree -d` prints nothing). Resolved normal tree: `anyhow`, `rslb-core → thiserror`, `serde_json`, and `signal-hook` under `cfg(unix)`, plus their transitives — **no `etcetera`**, which this decision does not select. Highest declared `rust-version` among dependencies is **1.71** (shared by `proc-macro2`, `quote`, `serde_derive`, `serde_json`, `syn`, `thiserror`, `thiserror-impl`, `unicode-ident`, `windows-link`, `windows-sys`, `zmij`); every license MIT/Apache-compatible | `dependency-resolution.log` |
| E14 | (rerun 2026-09-10, same workspace) `cargo audit` on that lockfile; then a control with `anyhow = "=1.0.102"` | 0 / 0 | recommended set: 1243 advisories loaded, **22 crate dependencies scanned, no findings**. Control: `RUSTSEC-2026-0190 … Warning: unsound … anyhow 1.0.102` — the `>= 1.0.103` advisory floor **remains load-bearing on the corrected figures** | `dependency-resolution.log` |

**Figures collected as `## Required evidence` specifies** (crates.io
`crate.recent_downloads` / `crate.downloads`; newest non-yanked version from
`/versions`; GitHub `stargazers_count` / `archived` / `pushed_at`; open issues
from the search endpoint; advisories from RustSec) — all retrieved 2026-09-09:

| Crate | 90-day | All-time | Newest non-yanked | `rust_version` | License | Stars / archived / last push | Open issues | Advisories | Maintenance |
|---|---:|---:|---|---|---|---|---:|---|---|
| `thiserror` | 350,390,985 | 1,436,032,398 | 2.0.20 (2026-08-08) | 1.71 | MIT OR Apache-2.0 | 5,539 / false / 2026-09-05 | 27 | none | active |
| `anyhow` | 206,068,310 | 942,920,266 | 1.0.104 (2026-07-18) | 1.68 | MIT OR Apache-2.0 | 6,649 / false / 2026-08-22 | 37 | **RUSTSEC-2026-0190** (unsound, patched ≥1.0.103) | active |
| `signal-hook` | 52,617,700 | 235,773,971 | 0.4.4 (2026-04-04) | 1.66 | MIT OR Apache-2.0 | 866 / false / 2026-04-04 | 22 | none | stable-quiet |
| `serde_json` | 301,631,570 | 1,277,306,669 | 1.0.151 (2026-07-20) | 1.71 | MIT OR Apache-2.0 | — | — | none | active |
| `ctrlc` (runner-up) | 20,977,033 | 122,696,775 | 3.5.2 (2026-02-10) | 1.69.0 | MIT/Apache-2.0 | 667 / false / 2026-07-22 | 11 | none | active |
| `strum` (excluded) | 133,569,704 | 619,448,770 | 0.28.0 (2026-02-22) | 1.71 | MIT | 2,440 / false / 2026-03-07 | — | — | active |
| `miette` (excluded) | 16,825,104 | 72,811,399 | 7.6.0 (2025-04-27) | 1.70.0 | Apache-2.0 | 2,602 / false / 2026-06-25 | — | — | stable-quiet |
| `inquire` (R61-contingent) | 5,097,514 | 20,203,144 | 0.9.4 (2026-02-24) | 1.80.0 | MIT | 2,623 / false / 2026-03-02 | 59 | none | stable-quiet |
| `human-panic` (excluded) | 2,750,696 | 13,220,540 | 2.0.8 (2026-04-02) | 1.88 | MIT OR Apache-2.0 | 1,852 / false / 2026-09-02 | — | — | active |
| `etcetera` (R57's, not selected here) | 31,683,342 | 105,128,197 | 0.11.0 (2025-10-28) | 1.87.0 | MIT OR Apache-2.0 | 150 / false / 2026-08-04 | — | — | stable-quiet |
| `sysexits` (excluded) | 211,934 | 1,536,178 | 0.13.0 (2026-02-28) | 1.87.0 | Apache-2.0 OR MIT | 33 / false / 2026-09-08 | — | — | active |
| `exitcode` (excluded) | 830,039 | 9,036,319 | 1.1.2 (**2017-06-18**) | none declared | Apache-2.0 | 79 / false / 2022-09-06 | — | — | dormant (no release in 9 years; the CLI-WG book still names it) |

Fitness gates, answered per selected crate **before** popularity was weighed.
Gate 1 (license): pass — every package in the resolved tree is MIT/Apache-compatible
(`memchr` is `Unlicense OR MIT`, `unicode-ident` is `(MIT OR Apache-2.0) AND
Unicode-3.0`, `zmij` is MIT). Gate 2 (crate **and dependency-tree** MSRV): pass
and, unlike in either raw, **executed** — E13's 2026-09-10 rerun shows the
highest declared `rust-version` anywhere in the resolved tree is **1.71**, shared
by eleven dependencies, and Cargo itself reported "Locking 20 packages to latest
Rust 1.96 compatible versions". The gate passes with more headroom than the
superseded figures suggested, not less. Gate 3 (advisories
and `unsafe` posture): pass — `cargo audit` clean on the recommended lock;
`anyhow`'s single advisory is avoided by version *and* by never calling
`downcast_mut`; `signal-hook` necessarily encapsulates FFI `unsafe` to install
handlers, so the *application* writes none but the dependency is not
`unsafe`-free, and `thiserror` is a proc-macro derive with no runtime `unsafe`
requirement. Gate 4 (OS matrix): the selected crates are Unix-portable and
`signal-hook` is Unix-only, which is exactly the fixed matrix; Windows is
**not** supported by this contract and is not required. Gate 5 (default features
and async coupling): stated — `thiserror` `default = ["std"]`, `anyhow`
`default = ["std"]`, `serde_json` `default = ["std"]`, `signal-hook`
`default = ["channel","iterator"]` and is taken with `default-features = false`;
no member declares an async runtime, so R05 and R69 stay free. Gate 6
(binary-size and compile cost, qualitative): small — 20 packages total, of which
`thiserror`'s proc-macro chain (`syn`/`quote`/`proc-macro2`) is the only
build-time cost of note and is almost always already in a Rust workspace's graph;
`anyhow` resolves with **zero** dependencies; `signal-hook` adds `libc` and
`signal-hook-registry`. `ctrlc` would have been more expensive (it pulls `nix`)
*and* cannot satisfy R9.6.

**What was deliberately not run.** No template, crate, binary, service, fixture
or acceptance harness was created; nothing was compiled. Every runtime claim in
this decision is therefore recorded under `## Engines` as opus-measured or as
unproven, with what would prove it, and left to P03.

## Engines

- codex `raw/codex.md` — engine codex, gpt-5.6-terra. Carries one BASELINE-REVIEW line (F301).
- opus `raw/opus.md` — engine opus, claude-opus-5[1m]. Carries one BASELINE-REVIEW line (F301).
- doxa `raw/doxa-openai.normalized.md` — engine doxa, provider OpenAI, gpt-5.6-sol (regrouped view: `raw/doxa.normalized.md`; heading repairs: `doxa/normalization.json`).
- doxa `raw/doxa-perplexity.normalized.md` — engine doxa, provider Perplexity, sonar-deep-research. Its body carries only `Landscape`, `Principles and implementation`, `Recommendation`, `Members`, `Compatibility` and `Sources`: the four top-level fields `Parameters`, `Migration implications`, `Validation strategy` and `Confidence & re-verify trigger` are **absent**, so it contributed no parameter value and no re-verify trigger and was weighed on its prose only.
- doxa `raw/doxa-gemini.normalized.md` — engine doxa, provider Gemini, deep-research-preview-04-2026.

**Disagreement 1 — what populates the envelope's `code` (F295).** codex, opus,
OpenAI and Perplexity all recommend an explicit, project-owned catalog with
hand-written literal strings. Gemini alone recommends deriving the code from the
variant identifier with `strum::IntoStaticStr`, arguing it "surpasses
TypeScript's programmatic type safety". **Settled against Gemini** by the Cargo
SemVer reference plus the row's own evidence: a Rust variant rename is a
compiler-checked refactor that would silently change the wire value, which is
precisely the `err.name` defect at ts `src/router.ts:211` that F295 records as
the divergence. Popularity does not repair the mismatch — `strum` has 133.6M
90-day downloads and Ruff and Nushell both use it, but for enum↔string
conversions that are not a wire protocol.

**Disagreement 2 — signal crate (F298).** codex, opus, OpenAI and Gemini choose
`signal-hook`; Perplexity chooses `ctrlc` with the `termination` feature,
reasoning that the template is "primarily a CLI template rather than a
long-running daemon". **Settled by reading `ctrlc` 3.5.2's own published
source** (E6): `set_handler<F> where F: FnMut() + 'static + Send` passes the
callback no signal argument, and `termination` routes SIGINT, SIGTERM and SIGHUP
to that same callback, so distinct 130/143 outcomes are impossible. Perplexity's
premise also fails independently: the target shape includes a web service (spec
§4 D7) and R9.6 makes SIGTERM→143 a `MUST` regardless of daemon-ness. Note that
the Rust CLI Working Group book — a genuine ecosystem authority, the CLI WG's own
publication — names `ctrlc` in its signals chapter; the authority is real and the
recommendation still does not fit this template's requirement. That is a
fit-over-abstract-best finding, not a dismissal of the source.

**Disagreement 3 — `anyhow` at the binary boundary.** opus and Perplexity adopt
it; OpenAI omits it from the stack; codex lists it under *Excluded by gate*.
Reading codex's own text, the exclusion is narrower than it looks — it excludes
`anyhow` **at the protocol boundary**, because an opaque carrier cannot express
an exhaustive domain-to-code mapping, which is a claim this decision agrees with
and preserves by putting the catalog in the library. There is therefore no real
conflict about *layering*, only about whether a context carrier is worth its
keep at the binary. **Settled by practice evidence** (E12): Cargo, Ruff, Nushell
and bat all ship `thiserror` + `anyhow`; ripgrep ships `anyhow` alone precisely
because it has no library consumers. Adopted, binary-only, with the `>= 1.0.103`
floor that E14's control shows is load-bearing.

**Disagreement 4 — the exit code for a configuration failure.** codex maps all
config faults to `1`; opus, OpenAI and Perplexity map them all to `2`; Gemini's
own table is internally inconsistent (it assigns `std::io` failures to `5`, which
its same paragraph assigns to conflict) and was not weighed. **Partly settled by the authority all four
were paraphrasing, and partly a labelled choice — the two are separated here
because R52–R56 and R70 consume this row.** Revision 3 corrects an over-reading in
revisions 1 and 2, which paraphrased R8.2 as exit `2` for input "missing **or
invalid**". R8.2 `(MUST)` says no such thing; verbatim, from this run's own
evidence log, it is: "Use exit `2` when required non-auth input or consent is
**missing** because prompting is disabled/unavailable, use exit `4` when
authentication or authorization input is missing, and use exit `1` for runtime
input failures such as unreadable files." Nothing there covers an *invalid*
value, and R6.1's `2` is "Usage / parse error (bad flags, missing args)" with the
stated default that "Unlisted failures collapse to `1`". Splitting the four
assignments by what actually supports each:

| Row | Exit | Basis |
|---|---|---|
| `RSLB104` config layer unreadable | 1 | **Standard-derived.** R8.2's "runtime input failures such as unreadable files", verbatim. |
| `RSLB202` config document unparsable | 2 | **Standard-derived**, on R6.1's *parse error* limb. The parenthetical "(bad flags, missing args)" narrows the example, not the class; a malformed document is a parse failure of user-supplied input. |
| `RSLB205` required input missing because prompting is disabled or unavailable | 2 | **Standard-derived.** R8.2's first clause, verbatim, including the "prompting is disabled/unavailable" condition — which is why revision 3 widened this row beyond `--no-input` to cover a missing TTY and a closed stdin. |
| `RSLB203` config value invalid | 2 | **This template's choice.** Neither rule covers it, and R6.1's own default for an unlisted failure is `1`. |
| `RSLB204` secret supplied through a prohibited channel | 2 | **This template's choice.** R5.5 and R5.6 govern secrets and assign no exit code at all; R6.1's default would again be `1`. |

The reasoning for both choices, stated so R52–R56 can overturn it rather than
inherit it silently: `RSLB202` is already `2`, and "the document parsed but a
value is out of range" is the same user-facing failure with the same remedy —
edit your configuration. Routing it to `1` would split one condition across two
codes, so a script repairing its own config would have to test both, and it would
put "your input is wrong" in the same bucket as "the network failed", which is
the signal R6.1's structured-but-small scheme exists to preserve. `RSLB204` is
the same shape: a rejection of user-supplied configuration input. The cost if the
choice is wrong is one catalog row and one arm of the `exit()` match; a
conformance audit reading R6.1 strictly could call `2` over-broad here, and
R55/R56 are the items positioned to raise it.

**The same defect, found by sweeping the rest of the taxonomy, and fixed.**
Revisions 1 and 2 mapped "prompt stdin closed" to `RSLB903`/130 alongside a
Ctrl-C interruption. That is not an unlabelled choice but a **contradiction of an
org-locked MUST**: a closed prompt stdin is precisely "required non-auth input …
missing because prompting is disabled/unavailable", which R8.2 assigns `2`. It is
also not `SIGINT`, so R6.1's `130` — "Interrupted by `SIGINT` (Ctrl-C)" — does not
reach it. Revision 3 therefore narrows `RSLB903` to a real Ctrl-C interruption and
routes a closed prompt stdin to `RSLB205`/2. This **departs from ts D-033**, which
exits 130 on "prompt interrupt/stdin-close" alike; the departure is recorded
rather than hidden, and its ground is that D-016(2) reconciled ts to this same
org-locked standard in the first place, so an R8.2 `MUST` outranks a later port
decision that did not consider it. ESC-cancellation is still assigned no code
here — it is R61's product question, as `## Decision` states. No engine proposed
any of these distinctions; all five reports mapped configuration wholesale to
either `1` or `2`.

**Disagreement 5 — the catalog's token format.** codex and OpenAI reuse py's
`PLBP` prefix, opus chooses `RSLB`, Perplexity chooses `RSBP`. **Not
evidence-settleable, and recorded as this template's choice.** OpenAI's stated
basis — "`PLBP000` is already fixed by owner evidence; no occupied Python code
may be reassigned" — misreads the prompt, which cites py's `PLBP000` as evidence
of the *shape* (a stable, append-only, documented string catalog), not as a
literal this template inherits. The discriminator is what `PLBP` actually is:
py's own repo identifier (`py-launch-blueprint`). Reusing it would make an
`rs-launch-blueprint` error indistinguishable from a `py-launch-blueprint` error
in any shared log, tracker or support channel, which defeats the very identity
P1 exists to give. Applying py's own rule to this repo yields `RSLB`
(`rs-launch-blueprint`) — opus's choice, and the one adopted; Perplexity's
`RSBP` is a third spelling with no stated rule behind it. The block numbering is
a separate, likewise-labelled choice: OpenAI's per-subsystem blocks give R52–R56
and R70 the distinct entries they need, opus's "hundreds digit equals the exit
code" mnemonic is worth keeping, and the adopted catalog merges the two.

**Disagreement 6 — crash log (F302).** codex recommends shipping none; opus
adopts one with an `etcetera`-derived state directory; OpenAI adopts an injected
`CrashSink` gated on R57; Perplexity proposes a `$HOME/.rs-launch-blueprint/state`
default; Gemini proposes `human-panic`. **Partly settled by evidence, partly a
labelled choice.** Settled: no fixed path may be recommended — R57 is `open` in
`research/CLAUDE.md`, and Perplexity's `$HOME/…` default and Gemini's
`human-panic` temp-directory default would both pre-empt it; `human-panic`
additionally covers *panics*, not returned errors, so it does not implement F302
as written; and Gemini's companion suggestion of `directories` for the path is
disqualified because that repository is **archived**. A choice, labelled as such:
this decision adopts OpenAI's injected-sink shape, keeps codex's secret-retention
objection as hard rules (sanitized fields, `0600`, never argv/env/config), and
leaves the sink a no-op until R57 answers. codex's stronger position — drop the
capability entirely — was not taken because P5's agreement level is *capability*,
and dropping it would silently decide a harmonize-or-drop question for py as well.

**Disagreement 7 — catalog exhaustiveness versus semver.** opus specifies
`#[non_exhaustive]` **and** promises R70 an exhaustive match; those cannot both
hold across a crate boundary. OpenAI is the only engine that names the conflict
and resolves it (a `macro_rules!`-generated catalog plus `ErrorCode::ALL` and a
coverage test). **Settled by the Cargo SemVer reference** (E9): adding a variant
without `#[non_exhaustive]` is a major break, and with it is not. This decision
takes OpenAI's resolution — `#[non_exhaustive]` plus `ALL` plus a coverage test —
and drops the `macro_rules!` generator, which is a P03 implementation choice, not
a contract term.

**Disagreement 8 — backtrace capture.** codex and opus both keep
`Backtrace::capture` and reject `force_capture`; OpenAI proposes `force_capture`
for the UNEXPECTED code whenever verbose/debug or crash persistence is active;
Gemini asserts that "JSON rendering natively suppresses deep trace arrays", which
is a property of `miette`'s reporter and not of the design here. **Not settled by
this item**, because the prompt's `- owns:` line does not include the F301
capture rule. The mechanism *is* verified (E8): `capture` is env-gated and
`force_capture` is not. Both codex's and OpenAI's positions are therefore
recorded as competing proposals under the open owner question, and this decision
states the conservative one as an assumption without publishing it.

**The one `CONFLICT:` line the raws raised.** codex and opus each state
explicitly that they raise none. Perplexity raised one against "R57
state-directory"; it is quoted in full under `## Parameters` and is not
escalated, because `consumes:` is empty, R57 registers no parameter, and this
decision's crash-sink design removes the dependency the line describes.

**A shape error in the doxa bodies, recorded rather than propagated.** OpenAI and
Perplexity each emit `BASELINE-REVIEW:` lines for F295, F296, F297, F298, F299,
F300 and F302. Those are **not** baseline rows — the prompt's `## Context`
records them as this item's own `DIVERGENT` rows, and `docs/port/COMMONALITY.md:
299-305` confirms it. A baseline review challenges a settled `COMMON → REUSE`
row; the only such rows in scope are F294 and F301, and only F301 has an open
proposal. Those lines are therefore *the answers themselves*, misfiled under a
review label, and are not carried forward. Gemini separately claims to own five
parameters (`error-code-catalog-source`, `error-diagnostic-envelope`,
`process-interrupt-contract`, `crash-log-persistence`, and an `assumes
interactive-prompts = inquire`) that no registry row assigns to R67
(`docs/port/PARAMETERS.md` gives this item exactly one: `error-taxonomy-exit-codes`);
its parameter block was read for content and disregarded for scope.

**Audit of revision 1, and what revision 2 changed.** The revision-1 draft
(sha256 `4c7ea6e604bd899a47cf75a3a9e05ef752fd694f6ed9c4446ccc1b391346f97d`) was
**rejected** by `audit-codex-2026-09-05T155124Z-2271e140a7ef` (gpt-5.6-terra;
report at `review/audit-codex.r1.md`, rerun log at
`review/evidence/audit-error-and-exit-code-contract.log`) on exactly one
substantive finding: the E13/E14 figures were not reproducible from the reviewed
fixture. They had been taken from a one-package manifest that additionally
carried `etcetera = "0.11.0"` — a crate this decision does not select — rather
than from the three manifests at `review/empirical/rslb-contract`. The auditor
independently reran the checks on a Linux VM and obtained 20 locked packages, no
`etcetera` in the resolved tree, and 22 scanned crate dependencies. Revision 2
reran E13 and E14 here against those same three manifests and reproduces the
auditor's figures exactly; every affected number and crate name in `## Decision`
and `## Empirical check` is corrected to the rerun, the superseded observation is
retained in the evidence log under a dated continuation header with its narrower
scope labelled rather than deleted, and the `anyhow = "=1.0.102"` control was
rerun in the same workspace shape and still reports RUSTSEC-2026-0190 — so the
`>= 1.0.103` advisory floor stays load-bearing, and the MSRV gate passes with
*more* headroom than before (highest dependency `rust-version` 1.71, not 1.87.0).
The auditor's other three findings were endorsements, and two are now stated
plainly where the claims are made: the `rustsec.org/packages/<name>.html` 404
counts as zero-advisory evidence **only** with its paired 200-for-`anyhow` and
advisory-db controls (E4), and E6/E7 are source-interface findings that
demonstrate no runtime behaviour (E6, E7 — the unproven list already covered
this). Nothing else changed: the owned parameter value, the other twelve
verification rows, the eight disagreement resolutions, the BASELINE-REVIEW F301
handling, the recorded-not-escalated Perplexity `CONFLICT:`, the status paragraph
and the unproven list are unchanged from revision 1.

**Audits of revision 2, and what revision 3 changed.** Revision 2 (sha256
`530fe209e3f5d052e4cd754711936b22778a8831bf2c2f3795e1811fc0e0a4f3`) was
**approved** by `audit-codex-2026-09-05T155124Z-2271e140a7ef-r2`
(`review/audit-codex.r2.md`) and **rejected** by
`audit-fable-2026-09-05T155124Z-2271e140a7ef-r2` (claude-opus-5,
`review/audit-fable.r2.md`) on two findings, both repaired here. **F1** — the
decision paraphrased the org-locked R8.2 as exit `2` for input "missing **or
invalid**"; the rule, and this run's own evidence log, say only "missing", and
`RSLB203` (config value invalid → 2) was presented as standard-derived when
neither R6.1 nor R8.2 covers it. **F2** — the exclusion of a stack trace from the
JSON envelope was called an assumption and "not published contract" in
`## Decision`, yet was published in the owned parameter, the artifact consumers
actually read.

Revision 3 makes exactly these changes and no others. (i) The R8.2 paraphrase in
Disagreement 4 is replaced by the rule verbatim, and every configuration and
input assignment is re-sorted into a table separating standard-derived rows
(`RSLB104`→1, `RSLB202`→2, `RSLB205`→2) from this template's choices
(`RSLB203`→2, `RSLB204`→2, both kept at 2 with their reasoning and their cost if
wrong stated). (ii) `RSLB203` and `RSLB204` are marked as choices **in the owned
parameter itself**, so a consumer reading only that line cannot mistake them for
requirements. (iii) The F2 contradiction is resolved by **removing the trace rule
from the owned parameter**, because the prompt's `- owns:` line is the authority
and does not include F301's criteria; what remains published is the envelope's
three-key field list, which F295/F296 do own, and the `## Decision` paragraph now
says so instead of claiming a suppression rule it does not assert. (iv) The
sweep the auditor asked for found one further instance and it was a contradiction
rather than a mislabel: `RSLB903` covered "prompt stdin closed", which R8.2
assigns `2`; `RSLB903` is narrowed to a Ctrl-C interruption, the closed-stdin case
moves to `RSLB205`, and `RSLB205` is widened from `--no-input` to R8.2's full
"prompting is disabled/unavailable" condition. That is a change to two rows of
the owned parameter, stated plainly rather than described as editorial. The
recommendation, the stack, the exit integers, the other twelve verification rows,
the other seven disagreement resolutions, the BASELINE-REVIEW F301 line, the
recorded-not-escalated Perplexity `CONFLICT:`, the status paragraph, the
`re-verify:` line and the unproven list are unchanged from revision 2. Two
accounting points the auditor checked and confirmed are also unchanged because
they were already right: this decision has **seven** formal consumers (R03,
R52–R56, R70) alongside five coupled items, and the rejected signal crate was
proposed by **one** report (Perplexity), as Disagreement 2 records.

**Where the evidence is incomplete, stated as uncertainty rather than averaged
away.** Everything under `## Empirical check` is a registry query, a source read
at a pinned version, a standard read, or a resolution/audit of version
requirements. **No runtime behavior was executed by this synthesis on any
platform**, and the two resolution checks ran on macOS only, so the Linux half of
`target-os-matrix` is unexercised even for resolution. The opus raw *did* build a
two-crate workspace on macOS and reported measured results — exit 3/4/2/5/130 per
catalog block, `SIGINT`→130 and `SIGTERM`→143 with a `Drop` guard observed,
`writeln!` on a locked handle piped to `head -2` exiting **0** against a
`println!` control exiting **101** with "failed printing to stdout: Broken pipe
(os error 32)", a crash-log write to an unwritable directory leaving the exit
code at 1, `RUST_BACKTRACE` unset producing a 5-line report versus 15 lines
containing "Stack backtrace" when set, `clap` 4.6.6 exiting 2 on a missing
argument, and a 4.40 s release build of 31 crates producing a 596,400-byte
binary. Those numbers are consistent with every mechanism verified here from
first-party sources, and they are the strongest runtime evidence in this run —
but they were produced by a fixture this synthesizer is directed not to
reproduce, and are recorded as **opus-measured, not independently re-executed**.

**Unproven, with what would prove it, left for P03.** The eight items below are
this decision's validation set: they are exactly what the implementation phase
must validate against the real template before this proposal can be treated as
settled.

1. *Every runtime acceptance criterion (AC1–AC8).* Proof: the table-driven
   integration test named in the migration plan, run on **both**
   `ubuntu-latest` and `macos-latest`, asserting one exit code per catalog row
   plus the EPIPE, SIGINT, SIGTERM and crash-record cases.
2. *That destructors run and streams flush on a signal path* (R7.7's `MUST`).
   Proof: a `Drop` guard and a buffered final write observed under real `SIGINT`
   and `SIGTERM` delivery to a bounded fixture.
3. *That the CLI parser R60 selects exits 2 on a usage error.* Proof: R60's own
   acceptance check, or a `--no-such-flag` invocation against the chosen parser.
   opus measured 2 for `clap` 4.6.6; R60 owns the selection.
4. *That `RSLB903` is reachable.* Proof: a PTY-driven test sending a real `^C`
   mid-prompt, once R61 has selected a crate. `inquire`'s typed variants were
   read from source but never triggered.
5. *The web surface's `SIGTERM` drain to 143.* Proof: an integration test against
   the runtime R05/R69 select; only the exit integer is shared, so the risk is
   low but the path is unbuilt.
6. *The crash record's location, permissions and rotation.* Proof: R57's
   `xdg-directory-set` answer, then a test asserting `0600` and that an
   unwritable directory changes neither the envelope nor the exit code.
7. *That the append-only property is enforced rather than documented.* Proof: the
   pinned-row catalog test plus a CI step diffing `docs/error-codes.md` against
   `ErrorCode::ALL`, so neither the enum nor the published catalog can drift.
8. *Compile time and binary size for the real template.* Proof: a measured
   `cargo clean && cargo build --release` in CI. Only the dependency *count*
   (20 packages, no duplicates) was established here.
