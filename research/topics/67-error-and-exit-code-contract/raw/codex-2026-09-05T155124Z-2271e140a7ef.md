# R67 — Error and exit-code contract

Retrieved 2026-09-05 by `research-codex-2026-09-05T155124Z-2271e140a7ef`. This is a proposed Rust design, not an executed template implementation.

### Landscape

This bundle decides an application protocol, not merely an error crate: a stable error identifier for the already-settled stderr JSON envelope (F294), an intentionally coarse process-status mapping, and terminal I/O and signal behavior. The three-bin survey is below. Figures are retrieved 2026-09-05; each figure's source is the named endpoint.

| Bin | Candidate or authority | Fit result |
|---|---|---|
| Built-in / first-party | `std::error::Error`, `std::io::ErrorKind::BrokenPipe`, `std::backtrace::Backtrace`, `std::process::ExitCode` | The catalog, mapping, hint, and best-effort policy belong in ordinary Rust types. Rust's standard library exposes `BrokenPipe` and documents that its Unix runtime ignores `SIGPIPE` by default, so an explicit write-result branch is necessary; no signal crate is needed for this part. [ErrorKind](https://doc.rust-lang.org/stable/std/io/enum.ErrorKind.html), [SIGPIPE runtime source](https://doc.rust-lang.org/stable/src/std/sys/pal/unix/mod.rs.html) (retrieved 2026-09-05). |
| Established practice | [`thiserror` 2.0.20](https://docs.rs/thiserror/2.0.20/thiserror/) for typed, source-preserving domain errors; [`signal-hook` 0.4.4](https://docs.rs/signal-hook/0.4.4/signal_hook/) with default features disabled for distinct Unix `SIGINT` and `SIGTERM` notifications | `thiserror` is a derive-only implementation aid, not the public error-code protocol. `signal-hook::flag::register` is the established safe abstraction when the application must distinguish signals; its own documentation explains why signal handlers must do only signal-safe work. [signal-hook README](https://github.com/vorner/signal-hook#readme) (retrieved 2026-09-05). |
| Up-and-comer / alternate | [`ctrlc` 3.5.2](https://docs.rs/ctrlc/3.5.2/ctrlc/) for a one-signal callback; [`inquire` 0.9.4](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html) if R61 selects it; `strum` 0.28.0 for enum-string derives | `ctrlc` intentionally sends `SIGINT`, `SIGTERM`, and `SIGHUP` to one handler under its `termination` feature, so it cannot implement distinct 130/143 semantics. `inquire` has typed `OperationCanceled` and `OperationInterrupted` errors, but R61 owns whether it is adopted. `strum` would make an enum name look protocol-stable; that is precisely the unstable coupling this item must avoid. [ctrlc docs](https://docs.rs/ctrlc/3.5.2/ctrlc/#handling-sigterm-and-sighup), [inquire errors](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html) (retrieved 2026-09-05). |

Authorities were deliberately mixed. The Rust standard-library sources are the authority for runtime and `Backtrace` behavior; the signal-hook maintainers document the signal-safety abstraction; crates.io and GitHub REST provide release and maintenance figures; RustSec is the advisory authority. The source repos establish the cross-repo principle, not the Rust mechanism: py's append-only string catalog/hint/crash log and ts's 0/1/2/3/4/5/130/143, EPIPE, and prompt-cancellation behaviors are recorded in [the R67 divergence analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

Practice evidence: `thiserror` has 349,580,121 90-day and 1,414,954,204 all-time downloads from [its crates.io endpoint](https://crates.io/api/v1/crates/thiserror), and its repository has 5,534 stars, is not archived, and was pushed 2026-09-05 from [GitHub REST](https://api.github.com/repos/dtolnay/thiserror). `signal-hook` has 52,827,824 90-day and 232,694,095 all-time downloads from [its crates.io endpoint](https://crates.io/api/v1/crates/signal-hook), and its repository has 866 stars, is not archived, and was pushed 2026-04-04 from [GitHub REST](https://api.github.com/repos/vorner/signal-hook). These figures show broad use and active release activity, not correctness by popularity. The maintained upstream `signal-hook` example is the relevant reference implementation for registering an `AtomicBool` for `SIGTERM`; the `thiserror` documentation is the maintained reference for a typed source-chain error. [signal-hook README example](https://github.com/vorner/signal-hook#example), [thiserror docs](https://docs.rs/thiserror/2.0.20/thiserror/) (retrieved 2026-09-05).

### Principles and implementation

The shared requirement is a machine-readable failure contract whose error identity remains useful across a CLI, a library, and a future web service. F294 requires the stderr envelope; F295–F300 and F302 are divergent. Agreement is required at the **capability and policy** level: consumers must receive a documented, stable error identity; scripts must receive conventional process status; an interrupted or closed-output program must not emit a panic or a second malformed JSON document. Rust need not copy either source's type shape. [R67 rows](../../../../docs/port/COMMONALITY.md) and [R67 divergence analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

Choose a manually maintained public `ErrorCode` enum and one total `as_str()` match, not `Debug`, `Display`, `strum`, a discriminant, or `thiserror`'s variant name. Each string is an append-only protocol value. Recommended initial values are `PLBP000` (unexpected), `PLBP010` (usage), `PLBP100` (configuration), `PLBP200` (authentication), `PLBP300` (not found), `PLBP400` (conflict), `PLBP500` (remote/API), `PLBP600` (I/O), and `PLBP700` (interrupted). Add a code rather than rename or repurpose one; reserve ranges by subsystem. `AppError` is a typed enum derived with `thiserror::Error`; its `code()`, `exit_status()`, `message()`, and optional `hint()` are explicit matches. This preserves Rust exhaustiveness while keeping serialized names independent of refactors. `thiserror` is selected over `anyhow` at this boundary because the latter intentionally provides an opaque application error rather than an exhaustively mapped taxonomy. [thiserror documentation](https://docs.rs/thiserror/2.0.20/thiserror/) (retrieved 2026-09-05).

Use the following process taxonomy. It keeps process codes coarse and lets the catalog, rather than an overcrowded exit-code space, distinguish configuration, I/O, remote, and unexpected faults: `0` success; `1` operational failure (`PLBP000`, `PLBP100`, `PLBP500`, `PLBP600`); `2` usage (`PLBP010`, including `clap` parse/validation); `3` not found (`PLBP300`); `4` authentication (`PLBP200`); `5` conflict (`PLBP400`); `130` `SIGINT` or contingent prompt interruption (`PLBP700`); `143` `SIGTERM` (`PLBP700`). These preserve ts's documented conventional 0/1/2/3/4/5/130/143 values while correcting py's use of 5 for interruption. `clap` exposes a programmatic error kind and the exit status used by `.exit()`; R60 remains responsible for selecting/wiring the parser, but its usage error must map to 2. [clap Error API](https://docs.rs/clap/latest/clap/error/struct.Error.html), [R67 D-016/D-033 evidence](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

`hint` is an optional structured, public, non-secret remediation field. Human rendering places it separately after the concise message; JSON adds `error.hint` when present. The stable semantic field is independent of R66's eventual presentation choices. Do not duplicate a hint into `message`, and do not make a hint a replacement for a code. This preserves py's useful structure and avoids ts's parsing-hostile inline remedy text. [F296 evidence](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

Register separate `AtomicBool`s for `SIGINT` and `SIGTERM` with `signal-hook` on the Unix-only target matrix. At a controlled boundary, map the first observed flag to 130 or 143, stop work, render at most one terminal error, and return normally. The handler itself must not allocate, format, write, or call `process::exit`. This is more precise than `ctrlc`; its optional `termination` feature deliberately coalesces the signals into a single callback. [signal-hook flags](https://docs.rs/signal-hook/0.4.4/signal_hook/flag/fn.register.html), [ctrlc termination behavior](https://docs.rs/ctrlc/3.5.2/ctrlc/#handling-sigterm-and-sighup) (retrieved 2026-09-05).

For F299, do not install a second prompt-local signal handler. If R61 adopts `inquire`, translate `InquireError::OperationInterrupted` to `PLBP700`/130 at the prompt adapter; `OperationCanceled` is ESC, not Ctrl-C, and must be a separate product decision rather than silently treated as a signal. If R61 chooses another crate, it must expose an equivalent typed interruption or the adapter must return the same domain interruption without leaking the crate error. [inquire error variants](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html) (retrieved 2026-09-05).

For F300, all output paths must handle the result of `write!`, `writeln!`, serializer writes, and flush. If `error.kind() == ErrorKind::BrokenPipe`, stop successfully with 0 and emit nothing else; otherwise translate the I/O error to `PLBP600`/1. Do not add a SIGPIPE handler. Rust's Unix runtime normally ignores `SIGPIPE`, converting a failed write to `BrokenPipe`; `println!` panics on that error, so all pipeline-facing output must use fallible writes. [Rust unstable-book explanation of the stable default](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html), [ErrorKind::BrokenPipe](https://doc.rust-lang.org/stable/std/io/enum.ErrorKind.html) (retrieved 2026-09-05).

Do not ship an automatic crash-log file (F302). It can preserve secrets and is unusable without R57's state-directory policy; a hidden fixed location would violate that unresolved ownership. Unexpected errors retain `PLBP000`, with a backtrace only under the settled verbose/debug policy. R58/R59 may later provide an explicitly configured, redacted file sink, but it is not a crash dump. `Backtrace::capture()` is normally disabled without `RUST_BACKTRACE` or `RUST_LIB_BACKTRACE`; `force_capture()` changes that cost/privacy contract and is not selected. [Backtrace documentation](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html) (retrieved 2026-09-05).

BASELINE-REVIEW: F301 — stack trace only under verbose/debug — R67 should own capture and JSON-mode-suppression acceptance criteria, pending owner disposition — evidence: [BASELINE-REVIEW.md](../../../../docs/port/BASELINE-REVIEW.md) and [Rust Backtrace docs](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html), retrieved 2026-09-05. Proposed criterion only: machine JSON errors must contain exactly one stderr JSON object and never append a rendered backtrace; human verbose/debug errors may render the captured backtrace. This does not claim the owner has accepted the scope amendment.

The minimal realistic example is a `projects get` command with JSON and human modes: parse failure → `PLBP010`/2; missing project → `PLBP300`/3 plus a hint; invalid config → `PLBP100`/1; `SIGINT` during a wait → `PLBP700`/130; `SIGTERM` → `PLBP700`/143; `--format json | head -n0` → 0 without panic or extra stderr. This is proposed acceptance evidence; none of those tests was run because this repository has no Rust implementation yet.

### Recommendation

One stack: `thiserror = "2.0.20"` for internal typed errors; a hand-written, append-only `ErrorCode`/`ExitStatus` mapping as the public protocol; `signal-hook = { version = "0.4.4", default-features = false }` only in the CLI binary for separate Unix `SIGINT`/`SIGTERM` flags; and `std` for fallible output and backtrace policy. R61's prompt crate remains unselected and supplies only a typed-interruption adapter if adopted. No `strum`, no `anyhow` at the protocol boundary, no `ctrlc`, no SIGPIPE handler, and no automatic crash-log file.

### Members

#### `thiserror` 2.0.20 — typed internal error representation

##### Landscape

`thiserror` is the dominant derive-based typed-error candidate. Its 90-day downloads are 349,580,121 and all-time downloads are 1,414,954,204 from `crate.recent_downloads` and `crate.downloads` at [GET crates.io/api/v1/crates/thiserror](https://crates.io/api/v1/crates/thiserror), retrieved 2026-09-05. The newest non-yanked release is 2.0.20, published 2026-08-08, `rust_version` 1.71, license `MIT OR Apache-2.0`, from [GET crates.io/api/v1/crates/thiserror/versions](https://crates.io/api/v1/crates/thiserror/versions), retrieved 2026-09-05. GitHub reports 5,534 stars, `archived: false`, and `pushed_at: 2026-09-05T05:32:25Z` from [GET GitHub repository metadata](https://api.github.com/repos/dtolnay/thiserror), retrieved 2026-09-05; GitHub issue search reports 22 open issues from [GET GitHub issue search](https://api.github.com/search/issues?q=repo%3Adtolnay%2Fthiserror%2Bis%3Aissue%2Bis%3Aopen), retrieved 2026-09-05.

##### Principles and implementation

It supplies `std::error::Error`, `Display`, and source-chain derives while the application owns stable codes in a separate match. This enforces a key separation: a refactor of an error variant cannot rewrite the wire/API vocabulary. The maintainer's documentation is the authoritative implementation reference. [docs.rs](https://docs.rs/thiserror/2.0.20/thiserror/) (retrieved 2026-09-05).

##### Dominant choice

`thiserror` 2.0.20; maintenance state: active, based on the 2026-08-08 release and 2026-09-05 repository push from the endpoints above.

##### Qualified shortlist

`thiserror` qualifies conditionally: compatible license; direct declared MSRV 1.71; default feature is `std`; no application `unsafe` is required; and it is platform-neutral for Ubuntu and macOS. Full transitive-tree MSRV and advisory proof cannot be established until the template's `Cargo.lock` exists, so the acceptance check must enforce it before shipment. The package-specific RustSec URL required by the prompt, [rustsec.org/packages/thiserror.html](https://rustsec.org/packages/thiserror.html), returned HTTP 404 on 2026-09-05; the general [RustSec advisory index](https://rustsec.org/advisories/) was also queried and did not surface `thiserror`, but that is not a package-scoped zero-advisory proof.

##### Excluded by gate

`anyhow` is excluded for this boundary, not for quality: its opaque dynamic error design prevents an exhaustive domain-to-code mapping from being expressed by the type system. `strum` 0.28.0 is excluded because serializing enum names/derives turns a refactorable identifier into a wire protocol. `strum` had 134,420,790 90-day downloads and 612,038,740 all-time downloads from [its crates.io endpoint](https://crates.io/api/v1/crates/strum), retrieved 2026-09-05; popularity does not repair that contract mismatch.

##### Up-and-comers

No up-and-comer is needed: the selected behavior is a standard error trait plus a small project-owned enum.

##### Fit for this template

The crate has negligible runtime cost because it is a proc-macro derive; compilation adds a proc-macro dependency and code generation. It has no async-runtime coupling. It meets the CLI/library/web shared need because the same `AppError` can map to a CLI envelope and later be mapped by R70 without exposing a transport type.

##### Recommendation

Adopt `thiserror = "2.0.20"` for `AppError`; make `ErrorCode` a separate project-owned `Copy` enum with literal strings and a total mapping.

##### Ranked runner-up

Hand-written implementations of `std::error::Error` are the runner-up when the template wants zero proc macros; they retain the same catalog design but add repetitive source/display code.

##### Tradeoffs

`thiserror` reduces boilerplate but can tempt authors to serialize variant names. The required explicit `code()` match prevents that. Do not combine it with `anyhow` at the public conversion boundary.

##### Parameters

Contributes `error-taxonomy-exit-codes` but does not own a separately versioned parameter. Assumes the fixed 2024 edition, MSRV policy, dual license, and Ubuntu/macOS target matrix from [PARAMETERS.md](../../../../docs/port/PARAMETERS.md), retrieved 2026-09-05.

##### Migration implications

Create `crates/core/src/error.rs` for `ErrorCode`, `ExitStatus`, `AppError`, and envelope conversion; add `thiserror` to the core crate's `Cargo.toml`; prohibit direct `thiserror`-variant serialization in the CLI and web adapters.

##### Validation strategy

Planned: `cargo test -p rs-launch-blueprint-core error_code_catalog_is_unique_and_append_only`; compile an exhaustive `AppError -> ErrorCode -> ExitStatus` match; run `cargo tree -d`, `cargo msrv verify`, and `cargo audit` after the lockfile exists. Expected result: all mapped errors have literal code strings and no dependency violates the selected MSRV/advisory gate. These checks are not executed.

##### Confidence & re-verify trigger

High for the separation of code catalog and typed errors. Re-verify on a `thiserror` major release, an MSRV-policy change, a RustSec result, or any proposal to make error strings public API.

##### Sources

[crates.io metadata](https://crates.io/api/v1/crates/thiserror), [crates.io versions](https://crates.io/api/v1/crates/thiserror/versions), [docs.rs](https://docs.rs/thiserror/2.0.20/thiserror/), [GitHub metadata](https://api.github.com/repos/dtolnay/thiserror), [GitHub issue search](https://api.github.com/search/issues?q=repo%3Adtolnay%2Fthiserror%2Bis%3Aissue%2Bis%3Aopen), [RustSec advisory index](https://rustsec.org/advisories/) — retrieved 2026-09-05.

#### `signal-hook` 0.4.4 — separate Unix termination notifications

##### Landscape

`signal-hook` is the established signal-specific candidate. Its 90-day downloads are 52,827,824 and all-time downloads are 232,694,095 from `crate.recent_downloads` and `crate.downloads` at [GET crates.io/api/v1/crates/signal-hook](https://crates.io/api/v1/crates/signal-hook), retrieved 2026-09-05. The newest non-yanked release is 0.4.4, published 2026-04-04, `rust_version` 1.66, license `MIT OR Apache-2.0`, from [GET crates.io/api/v1/crates/signal-hook/versions](https://crates.io/api/v1/crates/signal-hook/versions), retrieved 2026-09-05. GitHub reports 866 stars, `archived: false`, and `pushed_at: 2026-04-04T08:10:09Z` from [repository metadata](https://api.github.com/repos/vorner/signal-hook), retrieved 2026-09-05; GitHub issue search reports 11 open issues from [issue search](https://api.github.com/search/issues?q=repo%3Avorner%2Fsignal-hook%2Bis%3Aissue%2Bis%3Aopen), retrieved 2026-09-05.

##### Principles and implementation

The crate's `flag::register` records each signal with an `AtomicBool`; application code observes the flags at safe points and performs cleanup/rendering outside the signal handler. This directly implements distinct 130/143 exits. The maintainer describes the crate as safe/correct Unix signal handling and warns that Unix signal handlers have stringent restrictions. [crate docs](https://docs.rs/signal-hook/0.4.4/signal_hook/), [README](https://github.com/vorner/signal-hook#readme) (retrieved 2026-09-05).

##### Dominant choice

`signal-hook = { version = "0.4.4", default-features = false }`; maintenance state: active, based on the 2026-04-04 release and push. The selected `flag` API needs neither the `channel` nor `iterator` default features.

##### Qualified shortlist

Conditional pass: compatible license; direct declared MSRV 1.66; default features are `channel` and `iterator`, both disabled; no async runtime is required; application code needs no `unsafe`; and the crate is explicitly Unix-focused, which matches only the owner-fixed Ubuntu/macOS matrix. The crate necessarily encapsulates platform/FFI `unsafe` to register signals, so it is not an `unsafe`-free implementation internally. Full dependency-tree MSRV and package-scoped RustSec status remain unverified: [rustsec.org/packages/signal-hook.html](https://rustsec.org/packages/signal-hook.html) returned HTTP 404 on 2026-09-05, and the general [RustSec index](https://rustsec.org/advisories/) is not a package query. This recommendation must not bypass `cargo audit` on the final lockfile.

##### Excluded by gate

`ctrlc` 3.5.2 is excluded by the functional gate, not popularity: its optional `termination` feature calls the same handler for `SIGINT`, `SIGTERM`, and `SIGHUP`, so distinct 130/143 outcomes are impossible. It has 21,098,753 90-day and 121,490,112 all-time downloads from [its crates.io endpoint](https://crates.io/api/v1/crates/ctrlc), and its newest non-yanked 3.5.2 release has MSRV 1.69.0 and MIT/Apache-2.0 license from [its versions endpoint](https://crates.io/api/v1/crates/ctrlc/versions), retrieved 2026-09-05.

##### Up-and-comers

`tokio::signal` is not selected because R67 must not impose an async runtime on the CLI/core contract. It remains a compatible integration adapter if R69 later creates a Tokio web binary; it must preserve this item's same `AppError`/exit mapping rather than redefine it.

##### Fit for this template

The cost is one small Unix-only dependency in the binary crate and two atomics; there is no runtime executor, no signal-handler allocation, and no library-surface leakage. The reference `SIGTERM` flag example matches the needed cancellation model. Windows support is intentionally inapplicable because Windows is not in the fixed target matrix.

##### Recommendation

Adopt `signal-hook` 0.4.4 with `default-features = false` in the CLI package only; register `SIGINT` and `SIGTERM` once at startup and convert observed flags at safe boundaries to 130 and 143.

##### Ranked runner-up

`ctrlc` 3.5.2 without its `termination` feature is the runner-up if the owner drops the separate SIGTERM contract and wants only Ctrl-C handling. It is simpler but cannot answer the current D-016-compatible requirement.

##### Tradeoffs

`signal-hook` is Unix-specific and signal registration is process-global, so the core library must never install it. A future async web server may use its runtime-native signal stream, but only behind the web feature and only after translating to the same cancellation outcome.

##### Parameters

Supports `owns error-taxonomy-exit-codes = stable PLBP catalog; exits 0,1,2,3,4,5,130,143; SIGINT=130; SIGTERM=143`. It assumes the fixed Ubuntu/macOS matrix and does not consume R57 or R61.

##### Migration implications

Add `signal-hook` only to `crates/cli/Cargo.toml`; add `crates/cli/src/signals.rs`; pass a cancellation token/flags into the command runner. Do not add this dependency to `crates/core` or the library's public API.

##### Validation strategy

Planned on Ubuntu and macOS: start a blocking fixture, send `SIGINT`, assert status 130 and exactly one error; repeat with `SIGTERM`, assert 143; repeat a second signal during teardown, assert bounded exit and no deadlock. Then run `cargo audit`, `cargo tree`, and the declared-MSRV CI lane. No signal test was executed.

##### Confidence & re-verify trigger

Medium-high: the API directly supports the required distinction, but final transitive advisory/MSRV status needs a locked tree. Re-verify on any RustSec result, a signal-hook 0.5 release, a Windows-matrix expansion, or selection of the R69 async runtime.

##### Sources

[crates.io metadata](https://crates.io/api/v1/crates/signal-hook), [crates.io versions](https://crates.io/api/v1/crates/signal-hook/versions), [docs.rs](https://docs.rs/signal-hook/0.4.4/signal_hook/), [flag registration](https://docs.rs/signal-hook/0.4.4/signal_hook/flag/fn.register.html), [GitHub metadata](https://api.github.com/repos/vorner/signal-hook), [GitHub issue search](https://api.github.com/search/issues?q=repo%3Avorner%2Fsignal-hook%2Bis%3Aissue%2Bis%3Aopen), [RustSec advisory index](https://rustsec.org/advisories/) — retrieved 2026-09-05.

#### `std` output and backtrace policy — EPIPE, hint rendering, no crash dump

##### Landscape

This member is first-party rather than a downloadable crate; download, release, GitHub-star, open-issue, and reverse-dependency figures are inapplicable. `std::io::ErrorKind::BrokenPipe` and `std::backtrace::Backtrace` are documented stable APIs. [ErrorKind](https://doc.rust-lang.org/stable/std/io/enum.ErrorKind.html), [Backtrace](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html) (retrieved 2026-09-05).

##### Principles and implementation

Fallible writing is the correct architecture because a broken pipe is a normal consumer action, not an application error to serialize. The runtime's ignored-SIGPIPE default becomes `BrokenPipe`; return success instead of invoking a signal handler. `Backtrace::capture` observes the environment-controlled policy, while `force_capture` is rejected because it silently changes the privacy/performance behavior. [Rust SIGPIPE documentation](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html), [Backtrace documentation](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html) (retrieved 2026-09-05).

##### Dominant choice

`std` only: fallible `Write`, `ErrorKind::BrokenPipe`, `Backtrace::capture`, and no crash-log writer.

##### Qualified shortlist

All crate-specific fitness figures are inapplicable because this is the Rust toolchain. It has no added dependency-tree MSRV, license, advisory, feature, runtime, binary-size, or compile-time cost. Its supported Ubuntu/macOS behavior is the project toolchain's responsibility.

##### Excluded by gate

A SIGPIPE handler is excluded because it duplicates and can conflict with Rust's runtime policy. A fixed crash-log location is excluded because F302 would then depend on R57's unresolved state-directory answer and would create an unreviewed secret-retention surface.

##### Up-and-comers

None; this is a policy and standard-library member.

##### Fit for this template

It works in CLI, library, and web-adjacent code without imposing a runtime. The CLI adapter owns the final 0 return for a broken output pipe; a library returns the `io::Error` to its caller.

##### Recommendation

Use explicit fallible output helpers and handle `BrokenPipe` at the executable boundary. Capture backtraces only under the environment/debug policy; never write automatic crash dumps.

##### Ranked runner-up

An explicitly enabled, redacted crash-report feature after R57 and R59 settle paths and logging is the runner-up. It is not safe to preselect now.

##### Tradeoffs

Replacing `println!`/`eprintln!` with fallible writers adds small helper code but prevents a closed pipe from panicking. No crash log reduces postmortem convenience but avoids hidden persistence and respects the unresolved state-directory contract.

##### Parameters

Assumes R57 is unresolved. No `CONFLICT:` is emitted because the recommendation intentionally needs no state directory. It contributes the `BrokenPipe -> successful quiet termination` rule to `error-taxonomy-exit-codes`.

##### Migration implications

Create `crates/cli/src/output.rs` with a fallible stdout/stderr boundary and JSON-envelope writer. Ensure serializers write through it; delete any direct `println!` on machine/pipeline paths. Do not create `crash.log` code or configuration.

##### Validation strategy

Planned: `set -o pipefail; cargo run -- projects list --format json | head -n0; test ${pipestatus[1]} -eq 0` on macOS and Ubuntu; assert no panic text and no second stderr record. Planned backtrace tests set/unset `RUST_BACKTRACE` and assert human debug-only rendering, with JSON output still one envelope. Not executed.

##### Confidence & re-verify trigger

High for standard-library APIs; re-verify if stable Rust changes its SIGPIPE default, if an output framework takes ownership of writing, or if the owner accepts the F301 scope amendment.

##### Sources

[ErrorKind](https://doc.rust-lang.org/stable/std/io/enum.ErrorKind.html), [stable Unix runtime source](https://doc.rust-lang.org/stable/src/std/sys/pal/unix/mod.rs.html), [on-broken-pipe documentation](https://doc.rust-lang.org/nightly/unstable-book/compiler-flags/on-broken-pipe.html), [Backtrace](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html) — retrieved 2026-09-05.

#### R61-contingent prompt-cancellation adapter — no selected crate

##### Landscape

This is a composition boundary, not a new prompt-crate selection. Crate figures are inapplicable because R61 alone chooses the prompt library. `inquire` 0.9.4 is evidence that a Rust prompt library can expose `OperationCanceled` and `OperationInterrupted`; it had 5,319,781 90-day and 19,985,236 all-time downloads from [its crates.io endpoint](https://crates.io/api/v1/crates/inquire), with newest non-yanked 0.9.4 published 2026-02-24, MSRV 1.80.0, MIT license from [its versions endpoint](https://crates.io/api/v1/crates/inquire/versions), retrieved 2026-09-05.

##### Principles and implementation

The adapter maps only a typed Ctrl-C interruption to the R67 interrupted catalog code and exit 130; it must not expose third-party error names. ESC cancellation is separately observable and must be settled by R61/product behavior. [inquire error API](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html) (retrieved 2026-09-05).

##### Dominant choice

No crate selected; require the R61-selected crate to surface typed interruption or an equivalent adapter result.

##### Qualified shortlist

Inapplicable until R61 makes the crate choice. `inquire` is not automatically qualified because its declared MSRV 1.80.0 and full dependency-tree/advisory state must be tested against the fixed policy at the selection time.

##### Excluded by gate

Installing a global prompt-specific Ctrl-C handler is excluded: it races with R67's single process-level signal contract and risks duplicate output.

##### Up-and-comers

The R61 research may identify a different maintained prompt crate; this item accepts it only through the typed-adapter contract.

##### Fit for this template

The conditional adapter keeps the library and non-interactive paths free of terminal UI dependencies, preserving R61's independence and allowing `--yes`/non-TTY paths to bypass prompting.

##### Recommendation

Add a small conversion in the interactive CLI adapter after R61 selects a crate; map typed Ctrl-C to `PLBP700`/130 and preserve other prompt errors as ordinary `AppError` values.

##### Ranked runner-up

If no typed interruption is available, return a project-owned `PromptInterrupted` from the prompt wrapper after observing the R67 cancellation flag; do not downcast a string error.

##### Tradeoffs

This delays a crate-specific convenience path but prevents R67 from silently deciding R61. It also makes prompt behavior testable without a live TTY.

##### Parameters

Assumes R61's decision. No consumed registered parameter exists, so no `CONFLICT:` applies.

##### Migration implications

Add a `PromptAdapter` trait or conversion function in `crates/cli/src/prompt.rs`; keep the selected prompt dependency confined to the CLI package.

##### Validation strategy

Planned after R61: simulate the crate's typed interrupt, assert code `PLBP700`, status 130, no library internals in stderr, and exactly one JSON error object in machine mode. Not executed.

##### Confidence & re-verify trigger

Medium because it depends on R61. Re-verify when R61 selects its crate or when the selected crate changes its cancellation error type.

##### Sources

[inquire errors](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html), [inquire crates.io metadata](https://crates.io/api/v1/crates/inquire), [R67 F299 analysis](../../../../docs/port/DIVERGENCE-ANALYSIS.md) — retrieved 2026-09-05.

### Compatibility

The compatibility matrix is deliberate rather than an unverified shared-adopter claim: `thiserror` 2.0.20 declares MSRV 1.71 and is platform-neutral; `signal-hook` 0.4.4 declares MSRV 1.66 and is Unix-only; the fixed target matrix is Ubuntu/macOS; therefore the direct-requirement floor is 1.71 and both supported OSes are Unix. Version and feature evidence come from [thiserror versions](https://crates.io/api/v1/crates/thiserror/versions) and [signal-hook versions](https://crates.io/api/v1/crates/signal-hook/versions), retrieved 2026-09-05. `signal-hook` is declared with `default-features = false`, so its default `channel`/`iterator` surface is absent. A real proof still requires a locked integration example and CI on both targets; no shared adopter or lockfile was verified in this raw research run.

### Parameters

owns error-taxonomy-exit-codes = append-only literal `PLBP` error catalog (`PLBP000`, `PLBP010`, `PLBP100`, `PLBP200`, `PLBP300`, `PLBP400`, `PLBP500`, `PLBP600`, `PLBP700`); optional structured `hint`; exit mapping 0 success, 1 operational, 2 usage, 3 not-found, 4 auth, 5 conflict, 130 SIGINT/prompt interruption, 143 SIGTERM; `BrokenPipe` ends quietly with 0; no automatic crash log.

assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI.

assumes rust-edition = 2024.

assumes target-os-matrix = ubuntu-latest, macos-latest.

assumes license = MIT OR Apache-2.0.

No `CONFLICT:`: the crash-log recommendation avoids consuming R57, and prompt behavior is explicitly contingent on R61 rather than altering it.

### Migration implications

The implementation plan should add `crates/core/src/error.rs` for the public catalog, typed application errors, error-to-exit mapping, and serializable envelope data; `crates/cli/src/output.rs` for one fallible human/JSON rendering path; `crates/cli/src/signals.rs` for process flags; and `crates/cli/src/prompt.rs` for the contingent R61 conversion. Add `thiserror` to the core package and `signal-hook` with defaults disabled to the CLI package only. R03, R52–R56, and R70 import `ErrorCode`/`AppError` variants and choose their own seam/config/HTTP behavior; they must not add new raw exit integers or serialize variant names. Do not create a crash-log path/file until a separately approved feature owns its privacy, retention, and R57 location semantics.

### Validation strategy

The following are planned acceptance checks, not executed results:

```sh
# From the future repository root: code catalog and mapping are exhaustive and stable.
cargo test -p rs-launch-blueprint-core error_contract

# From the future repository root: a parse error is usage (2), a missing resource is 3,
# auth is 4, conflict is 5, and config/I-O/remote/internal errors are 1.
cargo test -p rs-launch-blueprint-cli exit_status_contract

# From the future repository root on ubuntu-latest and macos-latest: a closed consumer
# is successful and quiet, not a panic or a second JSON object.
set -o pipefail
cargo run -p rs-launch-blueprint-cli -- projects list --format json | head -n0
test "${pipestatus[1]}" -eq 0

# From the future repository root on ubuntu-latest and macos-latest: signals map distinctly.
cargo test -p rs-launch-blueprint-cli --test signals -- --nocapture

# From the future repository root after dependencies are locked: enforce the two unverified gates.
cargo msrv verify
cargo audit
```

Expected behavior is one JSON error object on stderr in machine mode, no trace appended to it, no secret-bearing crash file, and the code/status pair described above. The signal test must send real `SIGINT` and `SIGTERM` to a bounded blocking fixture. The catalog test must assert every enum member has a unique literal code and that former strings are never repurposed; an append-only history fixture makes a deletion/rename fail review.

### Confidence & re-verify trigger

Confidence is medium-high in the architectural choice: it preserves the stable identity and conventional status principle while making Rust-specific mechanics explicit. The two material evidence gaps are package-scoped RustSec lookup (the required `/packages/<name>.html` endpoints returned 404) and final transitive MSRV/advisory status (no Rust lockfile exists). Re-verify before decision publication after a locked minimal example runs on Ubuntu/macOS; also re-verify on any selected-crate major release, RustSec advisory, R61 selection, R57 crash-log/state-path proposal, R69 runtime choice, or owner disposition on F301.

### Sources

Source implementation and ledger evidence: [COMMONALITY.md](../../../../docs/port/COMMONALITY.md), [DIVERGENCE-ANALYSIS.md](../../../../docs/port/DIVERGENCE-ANALYSIS.md), [BASELINE-REVIEW.md](../../../../docs/port/BASELINE-REVIEW.md), and [PARAMETERS.md](../../../../docs/port/PARAMETERS.md), retrieved 2026-09-05. Ecosystem authorities: [Rust `ErrorKind`](https://doc.rust-lang.org/stable/std/io/enum.ErrorKind.html), [Rust SIGPIPE runtime source](https://doc.rust-lang.org/stable/src/std/sys/pal/unix/mod.rs.html), [Rust Backtrace](https://doc.rust-lang.org/stable/std/backtrace/struct.Backtrace.html), [thiserror docs](https://docs.rs/thiserror/2.0.20/thiserror/), [signal-hook docs](https://docs.rs/signal-hook/0.4.4/signal_hook/), [inquire error docs](https://docs.rs/inquire/0.9.4/inquire/error/enum.InquireError.html), [crates.io](https://crates.io/api/v1/crates/thiserror), [GitHub REST](https://api.github.com/repos/dtolnay/thiserror), and [RustSec](https://rustsec.org/advisories/), all retrieved 2026-09-05.

Method notes: queried crates.io metadata and versions endpoints for `thiserror`, `signal-hook`, `ctrlc`, `inquire`, `dialoguer`, and `strum`; GitHub repository and issue-search endpoints for the selected and runner-up repositories; docs.rs/maintainer documentation; Rust standard-library documentation; and the RustSec advisory index. Crates.io reverse-dependency endpoints returned HTTP 403, GitHub issue-search intermittently returned HTTP 403/422 during collection, and both mandated package RustSec URLs returned HTTP 404; no figures or zero-advisory claim were invented from those failed endpoints. The report therefore labels transitive MSRV, package-scoped advisory status, and issue-response medians as unverified and makes their checks a publication gate.
