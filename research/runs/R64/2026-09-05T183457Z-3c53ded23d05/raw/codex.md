### Landscape

**Category.** This is terminal-output delivery, specifically whether a CLI should offer a user-controlled external pager for long, interactive text. It is not web pagination and it does not decide text, JSON, or CSV output formats.

| Field bin | Candidate | Fit finding before popularity |
|---|---|---|
| Built-in / first-party | `std::process::Command`, `Stdio`, and `std::io::Write` | The standard library supplies the required child-process stdin pipe and literal argv execution. It deliberately does not parse a shell-style command string, so it needs a narrow parser for `PAGER` values containing arguments. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05) |
| Established practice | external `less` selected by an app override, then `PAGER`, then a fixed `less -FRX` fallback; `shlex` 2.0.1 parses that value | This preserves the user's pager rather than embedding a terminal UI. `shlex` documents POSIX-shell word splitting, while `Command` executes the resulting argv without a shell. [shlex documentation](https://docs.rs/shlex/2.0.1/shlex/) (retrieved 2026-09-05); [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05) |
| Established alternative | `pager` 0.16.1 | It pipes stdout to a pager, but its released source uses Unix `fork`/`exec` and `split_whitespace`; quoted pager arguments are therefore not preserved. It cannot meet the proposed command contract safely. [pager documentation](https://docs.rs/pager/0.16.1/pager/) (retrieved 2026-09-05); [pager 0.16.1 source](https://docs.rs/crate/pager/0.16.1/source/src/utils.rs) (retrieved 2026-09-05) |
| Established alternative | `minus` 5.7.2 | This is an in-process terminal pager with its own key bindings, buffer, terminal abstraction, and optional async modes. It is appropriate when the application owns the pager UI, not when it must honor the user's external pager command. [minus documentation](https://docs.rs/minus/5.7.2/minus/) (retrieved 2026-09-05) |
| Up-and-comer / qualified alternate parser | `shell-words` 1.1.1 | It has a close POSIX-style splitter and is used by `bat`, but its released manifest has no declared `rust-version`; the required dependency MSRV gate is not auditable from its metadata. [shell-words 1.1.1 manifest](https://docs.rs/crate/shell-words/1.1.1/source/Cargo.toml) (retrieved 2026-09-05); [bat manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05) |

**Authorities.** Rust's standard-library documentation is authoritative for the process boundary: arguments are literal and shell expansion does not occur. The `shlex` maintainer documentation and release source are authoritative for the parser's behavior, declared MSRV, and CI configuration. RustSec is authoritative for Rust advisory applicability. The `bat` project is relevant production practice because its published CLI has automatic paging, detects non-interactive output, supports user pager configuration, and its manifest directly declares its `shell-words` and `minus` dependencies. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05); [shlex source](https://docs.rs/crate/shlex/2.0.1/source/src/lib.rs) (retrieved 2026-09-05); [RustSec shlex advisory](https://rustsec.org/advisories/RUSTSEC-2024-0006.html) (retrieved 2026-09-05); [bat README](https://github.com/sharkdp/bat#automatic-paging) (retrieved 2026-09-05); [bat manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05).

**Practice evidence.** `bat` is a maintained Rust CLI reference: crates.io reports 775,924 recent downloads and 4,521,315 total downloads for `bat`, and its repository documentation specifies automatic paging for interactive output and direct output when it is redirected. Its manifest enables `shell-words` and `minus` behind the `paging` feature, showing a real Rust CLI's need to parse a configurable pager command, but its richer paging stack is not a mandate for this template. [bat crate endpoint](https://crates.io/api/v1/crates/bat) (retrieved 2026-09-05, fields `crate.recent_downloads` and `crate.downloads`); [bat README](https://github.com/sharkdp/bat#automatic-paging) (retrieved 2026-09-05); [bat manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05).

### Principles and implementation

The shared principle is **readable, user-controlled interactive text output**. Its agreement level is capability and policy, not a shared crate: py already pages terminal text through a user-selected pager; the TypeScript absence has no recorded rejection and its CLI has no comparable long-form text mode. The divergence record classifies R64 as one-sided, language-neutral, and `harmonize = partly`; the owner direction asks for a similar pager pattern in TypeScript and Rust while explicitly not requiring the same library. [R64 divergence record](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05); [owner direction](../../../../docs/port/OWNER-REVIEW.md) (retrieved 2026-09-05).

`BASELINE-REVIEW: F284/F285 — readable user-controlled long text — adopt the external-pager capability but replace py's renderer-specific pager mechanism with a Rust render-buffer plus literal-argv subprocess pattern — py is one-sided precedent; bat demonstrates TTY-conditioned automatic paging in a maintained Rust CLI, and Rust Command requires explicit argv rather than shell execution. [R64/F284/F285 evidence](../../../../docs/port/areas/cli-framework-ux.md) (retrieved 2026-09-05); [bat automatic paging](https://github.com/sharkdp/bat#automatic-paging) (retrieved 2026-09-05); [Rust Command](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).`

Adopt paging, because a template intentionally demonstrates long text help, reports, or rendered tables and otherwise makes a terminal user scroll or redirect manually. Do not page JSON, CSV, redirected output, or output sent to another process. The paging decision must use the **same primary-output-stream terminal predicate selected by R65**; R64 does not choose an additional TTY API. ANSI bytes must be rendered once and passed unchanged to the pager's stdin. `less -R` displays raw control sequences; `-F` exits for one screen and `-X` avoids terminal-init/deinit behavior. [less manual](https://man7.org/linux/man-pages/man1/less.1.html) (retrieved 2026-09-05); [R65 boundary](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

Compare the architectures before library choice:

1. **No pager.** Lowest code and dependency cost, but it fails the cross-repo capability that the owner asked Rust to preserve.
2. **Embed a pager (`minus`).** It avoids depending on an installed `less` and can provide its own search and scrolling UI, but adds terminal UI semantics, a multi-crate dependency graph, and an optional async model to a CLI + library + web-service template. It also does not implement the requested user command precedence. [minus documentation](https://docs.rs/minus/5.7.2/minus/) (retrieved 2026-09-05); [minus manifest](https://docs.rs/crate/minus/5.7.2/source/Cargo.toml) (retrieved 2026-09-05).
3. **A pager wrapper crate (`pager`).** Its API appears compact, but the released source is Unix-only `libc` process control, contains unsafe blocks, and tokenizes a command with whitespace rather than POSIX quoting. It also has no declared `rust-version` in the release manifest. It is excluded before popularity. [pager source](https://docs.rs/crate/pager/0.16.1/source/src/utils.rs) (retrieved 2026-09-05); [pager manifest](https://docs.rs/crate/pager/0.16.1/source/Cargo.toml) (retrieved 2026-09-05).
4. **Render-buffer + `Command` + `shlex`.** It keeps the CLI's rendering ownership, makes pager startup failure recoverable before bytes are lost, honors the specified precedence, preserves ANSI bytes, and has one small parsing dependency. This is the selected architecture. `Command` avoids shell injection because it receives a program plus parsed arguments rather than executing a command string. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05); [shlex `split`](https://docs.rs/shlex/2.0.1/shlex/fn.split.html) (retrieved 2026-09-05).

Minimal realistic example: the text renderer creates `Vec<u8>` before it chooses a sink. If paging is enabled and R65's stdout predicate is true, it resolves the first non-empty value of `RS_LAUNCH_BLUEPRINT_PAGER`, then `PAGER`, else the literal `less -FRX`; `shlex::split` must yield a non-empty argv. It launches `Command::new(argv[0]).args(&argv[1..]).stdin(Stdio::piped())`, writes the buffered bytes to stdin, and waits. A malformed value, a missing executable (including missing `less`), a spawn failure, or a write failure before any bytes are accepted falls back to direct stdout with a concise diagnostic on stderr. It must never invoke `sh -c`, and it must not use `shlex` quoting APIs. The first two environment values are user configuration, not a security boundary; literal argv nevertheless avoids adding a second shell interpretation. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05); [shlex source](https://docs.rs/crate/shlex/2.0.1/source/src/lib.rs) (retrieved 2026-09-05); [RustSec advisory scope](https://rustsec.org/advisories/RUSTSEC-2024-0006.html) (retrieved 2026-09-05).

Observable acceptance criteria are: (a) a terminal text render with `RS_LAUNCH_BLUEPRINT_PAGER='fake pager --flag'` reaches that argv, even when `PAGER` differs; (b) without the app variable it uses `PAGER`; (c) with neither it requests `less -FRX`; (d) non-terminal text output never starts a child; (e) the pager sees the original ANSI byte sequence; and (f) unavailable or invalid pager configuration produces exactly one direct output copy, not an error exit or data loss. These are proposed integration checks, not checks run in the not-yet-created template.

### Recommendation

Adopt one stack: **`shlex` 2.0.1 + `std::process::{Command, Stdio}` + a render-buffer external-pager adapter**. The adapter resolves `RS_LAUNCH_BLUEPRINT_PAGER` > `PAGER` > `less -FRX`, ignores empty values, parses only into argv with `shlex::split`, and writes direct output if parsing or pager launch is unavailable. It is supported on the fixed Ubuntu and macOS CI targets; Windows is not conditionally compiled out, but external paging is best-effort and direct output is the defined fallback if the selected program is unavailable. [shlex crate endpoint](https://crates.io/api/v1/crates/shlex) (retrieved 2026-09-05); [shlex versions endpoint](https://crates.io/api/v1/crates/shlex/versions) (retrieved 2026-09-05); [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).

### Members

#### shlex 2.0.1 with `std::process::Command`

##### Landscape

`shlex` is the selected parser for a pager environment value that can contain quoted arguments. `Command` is the built-in process executor; it has no crate figures because it is part of Rust's standard library. The immediate alternatives surveyed were `shell-words` 1.1.1, `pager` 0.16.1, and the in-process `minus` 5.7.2. [shlex documentation](https://docs.rs/shlex/2.0.1/shlex/) (retrieved 2026-09-05); [shell-words documentation](https://docs.rs/shell-words/1.1.1/shell_words/) (retrieved 2026-09-05); [pager documentation](https://docs.rs/pager/0.16.1/pager/) (retrieved 2026-09-05); [minus documentation](https://docs.rs/minus/5.7.2/minus/) (retrieved 2026-09-05).

##### Principles and implementation

The member exists only to convert a user configuration string into a program and literal argv; the subsequent spawn is standard-library code. `shlex::split` follows POSIX-shell word syntax for splitting, while `Command` does not apply shell syntax after it receives argv. That division supports quoted paths without shell expansion. [shlex source](https://docs.rs/crate/shlex/2.0.1/source/src/lib.rs) (retrieved 2026-09-05); [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).

##### Dominant choice

The dominant Rust design for a configurable subprocess is `Command` with separate arguments; it is built in, maintained with Rust itself, has no async-runtime coupling, and avoids a subprocess wrapper dependency. It requires a parser only because `PAGER` conventionally contains both executable and flags. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).

##### Qualified shortlist

`shlex` 2.0.1 qualifies: its release manifest declares `MIT OR Apache-2.0`, `rust-version = 1.46.0`, default feature `std`, and no dependencies. Its checked-in workflow tests stable, beta, no-default-features, and MSRV 1.46 on Ubuntu; this research also executed its 7 unit tests and 1 doctest successfully on macOS with Rust 1.98.0. The release's 1.46 MSRV is below the template's stable-minus-two target, and no dependency tree needs separate MSRV review. [shlex 2.0.1 manifest](https://docs.rs/crate/shlex/2.0.1/source/Cargo.toml) (retrieved 2026-09-05); [shlex CI workflow](https://raw.githubusercontent.com/comex/rust-shlex/master/.github/workflows/test.yml) (retrieved 2026-09-05).

##### Excluded by gate

`pager` 0.16.1 is excluded: it declares neither a Rust MSRV nor current Ubuntu/macOS test coverage in its released manifest, is built on Unix `libc` calls and unsafe blocks, and its `split_whitespace` parser fails the quoted-command acceptance criterion. [pager manifest](https://docs.rs/crate/pager/0.16.1/source/Cargo.toml) (retrieved 2026-09-05); [pager source](https://docs.rs/crate/pager/0.16.1/source/src/utils.rs) (retrieved 2026-09-05).

`minus` 5.7.2 is excluded for architecture fit before popularity: it owns an in-process pager and pulls terminal UI dependencies (`crossterm`, channels, locking, text wrapping, optional regex/arboard) instead of invoking the selected user command. Its registry version record does not provide a `rust_version`, so its current transitive MSRV cannot be established from the required endpoint. [minus manifest](https://docs.rs/crate/minus/5.7.2/source/Cargo.toml) (retrieved 2026-09-05); [minus versions endpoint](https://crates.io/api/v1/crates/minus/versions) (retrieved 2026-09-05).

`shell-words` 1.1.1 is not selected because its released manifest likewise omits `rust-version` and no released CI matrix established the required policy. It is a plausible future replacement only after that gate is demonstrated. [shell-words manifest](https://docs.rs/crate/shell-words/1.1.1/source/Cargo.toml) (retrieved 2026-09-05).

##### Up-and-comers

No up-and-comer is recommended. `minus` is actively released but changes the product from external-pager integration to an owned pager UI; `shell-words` is the qualified alternate parser, not an adoption candidate until its MSRV evidence is supplied. [minus crate endpoint](https://crates.io/api/v1/crates/minus) (retrieved 2026-09-05); [shell-words crate endpoint](https://crates.io/api/v1/crates/shell-words) (retrieved 2026-09-05).

##### Fit for this template

The template needs a small synchronous CLI adapter while its library and web-service layers remain unaware of terminals and processes. `shlex` adds parsing only; `Command` owns the pipe. The default `std` feature is required, there is no async runtime, and the qualitative binary/compile cost is one small dependency with no dependencies of its own, versus an embedded terminal UI's multi-crate graph. [shlex 2.0.1 manifest](https://docs.rs/crate/shlex/2.0.1/source/Cargo.toml) (retrieved 2026-09-05); [minus 5.7.2 manifest](https://docs.rs/crate/minus/5.7.2/source/Cargo.toml) (retrieved 2026-09-05).

##### Recommendation

Pin `shlex = "2.0.1"` under the CLI package's normal dependency policy and call only `shlex::split`. Pair it with standard-library `Command`, `Stdio::piped`, and `Write`; do not enable or call `shlex` quoting APIs. The selected `split` API is safe; the crate contains internally justified unsafe conversion code, so its advisory and future releases remain re-verification points. [shlex `split` documentation](https://docs.rs/shlex/2.0.1/shlex/fn.split.html) (retrieved 2026-09-05); [shlex source](https://docs.rs/crate/shlex/2.0.1/source/src/lib.rs) (retrieved 2026-09-05).

##### Ranked runner-up

`shell-words` 1.1.1 is the runner-up because it forbids unsafe code and documents POSIX-style splitting without expansion. It is used by `bat`'s paging feature, but the missing released MSRV declaration prevents it from passing this template's evidence gate today. [shell-words source](https://docs.rs/crate/shell-words/1.1.1/source/src/lib.rs) (retrieved 2026-09-05); [bat manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05).

##### Tradeoffs

The external process adds a startup cost proportional to one pager spawn and buffers the rendered text once, so it is appropriate for bounded command reports rather than unbounded streams. This report found no comparable latency or throughput benchmark with the same workload, configuration, instrumentation, and resource conditions; it makes no fastest claim. `minus` can stream dynamic data but pays for owned terminal UI behavior that R64 does not need. [minus documentation](https://docs.rs/minus/5.7.2/minus/) (retrieved 2026-09-05).

##### Parameters

`owns: none` — R64 records no owned registry parameter. `assumes: none` — R65 supplies no formal parameter, but this adapter must call its selected primary-stdout TTY seam. The proposed public setting name is `RS_LAUNCH_BLUEPRINT_PAGER`; it is an implementation name, not a new parameter registration. [R64 coupling record](../../../../research/EXECUTION.json) (retrieved 2026-09-05); [R65 boundary](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

##### Migration implications

Add `shlex` only to the CLI package. Put command resolution and child-pipe code behind an output-sink adapter, keeping it out of the library and web-service packages. Render text before selecting direct stdout or pager stdin, and inject the R65 TTY predicate and environment reader into tests. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).

##### Validation strategy

Proposed template checks: unit-test precedence and malformed/empty command handling with injected environment; use a test helper executable that records argv and stdin bytes; assert ANSI bytes survive; test a nonexistent pager causes one direct output copy; run the helper on Ubuntu and macOS; and run `cargo test` under the declared stable-minus-two toolchain. Executed candidate evidence: `cargo test --all-features` in the downloaded `shlex` 2.0.1 release completed 7 unit tests and 1 doctest successfully on macOS with Rust 1.98.0; it did not test the future template adapter. [shlex CI workflow](https://raw.githubusercontent.com/comex/rust-shlex/master/.github/workflows/test.yml) (retrieved 2026-09-05).

##### Confidence & re-verify trigger

Confidence is medium-high for `shlex` parsing and `Command` execution, but medium for the final adapter until its two-OS helper tests exist. Re-verify before implementation if `shlex` releases a security fix or breaking major, if the template MSRV exceeds its tested range, if R65 selects a different stdout seam, or if the output-format design makes text output unbounded. [shlex versions endpoint](https://crates.io/api/v1/crates/shlex/versions) (retrieved 2026-09-05); [RustSec advisory](https://rustsec.org/advisories/RUSTSEC-2024-0006.html) (retrieved 2026-09-05).

##### Sources

Figures for `shlex` 2.0.1, retrieved 2026-09-05: 231,608,081 90-day downloads and 794,431,275 all-time downloads from `crate.recent_downloads` and `crate.downloads`; newest non-yanked release 2.0.1, created 2026-05-17T18:56:12.775983Z, from the versions endpoint. The GitHub issue search returned 4 open issues from `total_count`; the repository metadata endpoint and the endpoint needed to inspect the ten most recently opened issues returned GitHub rate-limit responses, so stars, archived state, `pushed_at`, and the requested median first-maintainer-response/unanswered count are **unverified**, not zero. RustSec lists RUSTSEC-2024-0006, but its patched range is `>=1.3.0`; selected 2.0.1 is outside that affected range, and the adapter does not use the advisory's quoting APIs. [shlex crate endpoint](https://crates.io/api/v1/crates/shlex) (retrieved 2026-09-05); [shlex versions endpoint](https://crates.io/api/v1/crates/shlex/versions) (retrieved 2026-09-05); [open issue search](https://api.github.com/search/issues?q=repo:comex/rust-shlex+is:issue+is:open) (retrieved 2026-09-05); [repository endpoint](https://api.github.com/repos/comex/rust-shlex) (retrieved 2026-09-05, rate-limited); [recent-issues endpoint](https://api.github.com/repos/comex/rust-shlex/issues?state=open&sort=created&direction=desc&per_page=10) (retrieved 2026-09-05, rate-limited); [RustSec advisory](https://rustsec.org/advisories/RUSTSEC-2024-0006.html) (retrieved 2026-09-05).

### Compatibility

The members compose through the standard `Vec<String>` argv boundary: `shlex::split` produces argv, and `Command::new` plus `.args` receives it without a shell. `bat` is a shared production reference for the surrounding pattern: its manifest declares `shell-words` with a paging feature and its documentation describes TTY-conditioned automatic paging, while this recommendation substitutes `shlex` because it supplies a declared MSRV and MSRV CI. Compatibility must still be proven in the template with the planned fake-pager tests; no template version matrix exists because no Rust code exists yet. [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05); [bat manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05); [bat automatic paging](https://github.com/sharkdp/bat#automatic-paging) (retrieved 2026-09-05).

### Parameters

`owns: none.`

`assumes: none.` R65's selected terminal check is a related implementation seam rather than a registered consumed parameter. The implementation must test the same primary output stream that receives text; it must not infer terminal status from stderr. [R64/R65 records](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).

No `CONFLICT:` line is emitted: the proposed design neither changes an owned/consumed parameter nor requests one. `RS_LAUNCH_BLUEPRINT_PAGER` is the proposed app-specific public environment name, followed by `PAGER`, then `less -FRX`; register that name later only if the parameter registry gains a configuration-name owner. [R64 source precedent](../../../../docs/port/areas/cli-framework-ux.md) (retrieved 2026-09-05).

### Migration implications

The future template should add a CLI-only pager adapter (for example, `crates/<cli>/src/output/pager.rs`), a direct-or-pager sink selection in the text renderer, `shlex = "2.0.1"` in that CLI package's `Cargo.toml`, and unit/integration helper tests. The adapter receives rendered bytes, a paging-enabled setting, R65's injected primary-stdout TTY predicate, and an environment view. It returns a recoverable direct-output path when no pager can start. No library API or web-service handler should import `shlex` or spawn a pager. These are proposed file-level changes; no Rust template files currently exist. [repository status](../../../../README.md) (retrieved 2026-09-05); [Rust `Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).

### Validation strategy

Planned, not executed against a template:

```text
cargo test -p rs-launch-blueprint-cli pager::tests
rustup run <declared-stable-minus-two> cargo test -p rs-launch-blueprint-cli pager::tests
```

The test helper must be selected through `RS_LAUNCH_BLUEPRINT_PAGER` and record `argv` plus stdin. Test the full precedence chain, ignored empty values, quoted program paths/arguments, malformed quotes, absent fallback executable, non-TTY bypass, and exact ANSI bytes. Run the integration helper in the Ubuntu and macOS CI matrix. Expected results are one pager invocation only for terminal text output, or exactly one direct output copy with a diagnostic when invocation is unavailable.

Executed evidence is limited to the candidate release: on macOS, `cargo test --all-features` for downloaded `shlex` 2.0.1 passed 7 unit tests and 1 doctest under Rust 1.98.0. That validates the parser release locally; it is not evidence that the unimplemented adapter meets these acceptance checks. [shlex source](https://docs.rs/crate/shlex/2.0.1/source/src/lib.rs) (retrieved 2026-09-05); [shlex CI workflow](https://raw.githubusercontent.com/comex/rust-shlex/master/.github/workflows/test.yml) (retrieved 2026-09-05).

### Confidence & re-verify trigger

**Decision confidence: medium-high.** The capability is supported by the owner direction and a maintained Rust CLI reference; the selected parser has a declared and CI-tested MSRV far below the template target, and standard-library process semantics exactly fit literal argv execution. Confidence is not absolute because GitHub maintenance-response figures were rate-limited and because the real adapter has not yet run on both target OSs. [owner direction](../../../../docs/port/OWNER-REVIEW.md) (retrieved 2026-09-05); [shlex manifest](https://docs.rs/crate/shlex/2.0.1/source/Cargo.toml) (retrieved 2026-09-05); [shlex CI workflow](https://raw.githubusercontent.com/comex/rust-shlex/master/.github/workflows/test.yml) (retrieved 2026-09-05).

Re-open R64 before implementation if R65 changes the primary-output TTY seam, if R66 removes long text mode, if `shlex` has a new applicable RustSec advisory or a major release, if the project chooses streaming rather than buffered text rendering, or if Windows becomes a required CI target. [R64/R65/R66 boundaries](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05); [RustSec shlex advisory page](https://rustsec.org/packages/shlex.html) (retrieved 2026-09-05).

### Sources

- [R64 prompt source precedent and scope](../../../../docs/port/areas/cli-framework-ux.md) (retrieved 2026-09-05).
- [R64 divergence analysis and harmonization level](../../../../docs/port/DIVERGENCE-ANALYSIS.md) (retrieved 2026-09-05).
- [Owner direction for R64](../../../../docs/port/OWNER-REVIEW.md) (retrieved 2026-09-05).
- [Rust `std::process::Command` documentation](https://doc.rust-lang.org/stable/std/process/struct.Command.html) (retrieved 2026-09-05).
- [shlex crate endpoint](https://crates.io/api/v1/crates/shlex) and [versions endpoint](https://crates.io/api/v1/crates/shlex/versions) (retrieved 2026-09-05).
- [shlex 2.0.1 documentation and source](https://docs.rs/shlex/2.0.1/shlex/) (retrieved 2026-09-05); [CI workflow](https://raw.githubusercontent.com/comex/rust-shlex/master/.github/workflows/test.yml) (retrieved 2026-09-05).
- [RustSec RUSTSEC-2024-0006](https://rustsec.org/advisories/RUSTSEC-2024-0006.html) (retrieved 2026-09-05).
- [bat automatic-paging reference](https://github.com/sharkdp/bat#automatic-paging) and [manifest](https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml) (retrieved 2026-09-05).
- [pager 0.16.1 documentation](https://docs.rs/pager/0.16.1/pager/) and [source](https://docs.rs/crate/pager/0.16.1/source/src/utils.rs) (retrieved 2026-09-05).
- [minus 5.7.2 documentation](https://docs.rs/minus/5.7.2/minus/) and [manifest](https://docs.rs/crate/minus/5.7.2/source/Cargo.toml) (retrieved 2026-09-05).
- [less manual](https://man7.org/linux/man-pages/man1/less.1.html) (retrieved 2026-09-05).

Method notes: queried `GET https://crates.io/api/v1/crates/{shlex,pager,minus,shell-words,bat}` and each corresponding `/versions` endpoint with a User-Agent; queried `GET https://api.github.com/search/issues?q=repo:comex/rust-shlex+is:issue+is:open`; queried the GitHub repository and recent-issues endpoints; queried `https://rustsec.org/packages/shlex.html` and the linked advisory; and read docs.rs, Rust standard-library docs, and maintained project sources. GitHub rate limiting prevented repository stars/archived/push fields and the ten-issue responsiveness calculation; those figures are explicitly unverified. RustSec package URLs for `pager`, `minus`, and `shell-words` returned 404 pages, so no advisory conclusion is asserted for those excluded alternatives. The future template pager tests were not runnable because this research repository intentionally contains no Rust implementation.
