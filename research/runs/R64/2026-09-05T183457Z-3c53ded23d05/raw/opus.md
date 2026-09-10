# R64 — pager-integration (bundle) — raw report (engine: opus, `claude-opus-5`)

Item `R64`, ledger rows `F284` (text-mode output paged through the user's pager) and `F285` (pager command resolution precedence), `docs/port/COMMONALITY.md:288-289`, verdict `DIVERGENT`, origin `py-only`. Tier `focused`. All retrievals dated **2026-09-10** unless a different date is stated on the line.

### Landscape

**The category this item decides.** *Terminal output pagination for a text-mode CLI result stream*: whether the program hands long human-readable output to an external pager process the user controls, and by what mechanism it discovers, launches and cleans up after that process. It is not a rendering-format decision (R66), not a TTY-detection decision (R65), and not a colour decision (R65). It is a **process-lifecycle and environment-resolution** decision.

**Step 1 — the three-bin map of the Rust field.**

| Bin | Candidate | What it is | Why it lands in this bin |
|---|---|---|---|
| Built-in / first-party toolchain | `std::process::Command` + `Stdio::piped()` (Rust standard library) | Spawn a child, own its stdin, write, `wait()` | Ships with the toolchain; `std::process` is stable since Rust 1.0 and `Stdio::piped` since 1.0. Requires no crate. Source: <https://doc.rust-lang.org/stable/std/process/struct.Command.html> (2026-09-10) |
| Built-in / first-party toolchain | `std::env::var` for the env chain | Read `RSLB_PAGER` / `PAGER` | Standard library. Source: <https://doc.rust-lang.org/stable/std/env/fn.var.html> (2026-09-10) |
| Established industry standard | `shell-words` 1.1.1 | POSIX word-splitting of a pager command *string* into argv | Used for exactly this purpose by the two most-cited Rust pager consumers, `bat` and `delta` (see Practice evidence). 36,835,500 downloads in the last 90 days (`GET https://crates.io/api/v1/crates/shell-words`, `crate.recent_downloads`, 2026-09-10) |
| Established industry standard | `shlex` 2.0.1 | The other POSIX-ish word splitter | 235,305,397 downloads in the last 90 days (`GET https://crates.io/api/v1/crates/shlex`, `crate.recent_downloads`, 2026-09-10); much of that reach is transitive through `cc` build scripts rather than command-string splitting |
| Established industry standard | `terminal_size` 0.4.4 | Terminal rows/columns, i.e. the input to a "is the output taller than the screen" gate | 37,832,505 downloads in the last 90 days (`GET https://crates.io/api/v1/crates/terminal_size`, `crate.recent_downloads`, 2026-09-10); a dependency of `clap_builder` 4.6.6 (`GET https://crates.io/api/v1/crates/terminal_size/reverse_dependencies`, 2026-09-10) |
| Established industry standard (in decline) | `pager` 0.16.1 | Self-redirect: `fork()`, `dup2()`, then `exec` the pager *in place of the parent* | The only crate on crates.io whose stated purpose is "Helps pipe your output through an external pager" (`GET https://crates.io/api/v1/crates/pager`, `crate.description`, 2026-09-10). Last release 2022-09-22 |
| Up-and-comer | `minus` 5.7.2 | In-process async terminal pager library (no subprocess) | 436,903 downloads in the last 90 days (`GET https://crates.io/api/v1/crates/minus`, 2026-09-10); shipped by `bat` behind `PAGER=builtin` |
| Up-and-comer | `sapling-streampager` 0.12.0 | In-process pager extracted from Meta's Sapling VCS | 1,126,040 downloads in the last 90 days (`GET https://crates.io/api/v1/crates/sapling-streampager`, 2026-09-10); it is `jj`'s `:builtin` pager |

**Completeness of the map.** Three `GET https://crates.io/api/v1/crates?q=…` searches (`pager`, `external+pager`, `paging+terminal`, `less+pipe+output`; `per_page=12..20`, 2026-09-10) return no other crate whose purpose is resolving or invoking an external pager. The field is genuinely this small: one abandoned subprocess-helper crate, two in-process pager libraries, and a hand-rolled `std::process` pattern that every large consumer uses.

**Step 2 — authorities used, and why each is authoritative.**

| Source | Why it is authoritative | Retrieved |
|---|---|---|
| `git` `pager.c` and `Makefile` at tag `v2.51.0` (<https://raw.githubusercontent.com/git/git/v2.51.0/pager.c>, `.../Makefile>`) | The reference implementation the whole convention descends from; every other tool in this table names git as its model. Primary source, read at a pinned tag | 2026-09-10 |
| Command Line Interface Guidelines, <https://clig.dev/> | The cross-ecosystem CLI design document py's own `output.py` module docstring cites ("Rules (per clig.dev)"); authored by Aanand Prasad, Ben Firshman, Carl Tashian and Eva Parish and widely referenced across CLI projects. It states a normative rule on paging | 2026-09-10 |
| `git(1)` environment-variable reference, <https://git-scm.com/docs/git> | Maintainer documentation for `GIT_PAGER`/`PAGER` precedence and the empty-value convention | 2026-09-10 |
| GitHub CLI manual, <https://cli.github.com/manual/gh_help_environment> | Maintainer documentation stating the two-tier chain verbatim: "GH_PAGER, PAGER (in order of precedence)" | 2026-09-10 |
| `bat` source at tag `v0.26.1` (`src/pager.rs`, `src/output.rs`, `Cargo.toml`) | Maintainers' own code for the most-installed Rust CLI that pages; 60,398 stars (`GET https://api.github.com/repos/sharkdp/bat`, `stargazers_count`, 2026-09-10) | 2026-09-10 |
| `delta` source at tag `0.19.2` (`src/env.rs`, `src/utils/bat/output.rs`, `Cargo.toml`) | Maintainers' own code; 32,138 stars (`GET https://api.github.com/repos/dandavison/delta`, 2026-09-10) | 2026-09-10 |
| `jj` source and docs at tag `v0.45.1` (`cli/src/ui.rs`, `cli/src/config/misc.toml`, `docs/config.md`) | Maintainers' own code for the newest widely-adopted Rust CLI in this class; 31,500 stars (`GET https://api.github.com/repos/jj-vcs/jj`, 2026-09-10). Weighted heavily per survey step 3 ("weighting newer popular ones") | 2026-09-10 |
| `less(1)` manual, `less` 668 as installed on this host (`man less`, `MANWIDTH=100`) | Primary documentation for the flag semantics the default command depends on | 2026-09-10 |
| RustSec advisory database, <https://rustsec.org/> | The Rust Security Response WG's own database; the gate-3 source named in the prompt | 2026-09-10 |
| `R06` DECISION (`research/topics/06-unsafe-code-policy/DECISION.md`) | This programme's own settled `unsafe` policy, needed to judge gate 3's `unsafe` posture correctly | 2026-09-10 |

**Evidence gap in the authorities.** The Rust Project's own CLI working-group book, *Command Line Applications in Rust* (<https://raw.githubusercontent.com/rust-cli/book/master/src/tutorial/output.md> and `src/in-depth/human-communication.md`, retrieved 2026-09-10), contains **no** guidance on paging — a grep for `pager` over both chapters returns no match. There is no RFC and no Rust survey question on the subject either. So there is no first-party Rust authority for this pattern: the normative authority is `clig.dev` and `git`, and the Rust-specific authority is the convergent practice of `bat`, `delta` and `jj`. This is stated rather than papered over.

**Step 3 — practice evidence: what well-regarded Rust projects actually do.**

| Project | Evidence it is well regarded | Pager resolution chain | Invocation mechanism |
|---|---|---|---|
| `bat` | 60,398 stars, not archived, `pushed_at` 2026-09-04 (`GET https://api.github.com/repos/sharkdp/bat`, 2026-09-10); 777,983 downloads in 90 days (`GET https://crates.io/api/v1/crates/bat`, 2026-09-10) | `--pager`/config → `BAT_PAGER` → `PAGER` → `less` (`src/pager.rs`, `get_pager`, v0.26.1) | `shell_words::split`, then `Command::new(..).stdin(Stdio::piped()).spawn()`, `unwrap_or_else(|_| OutputType::stdout())`, `child.wait()` in `Drop` (`src/output.rs`, v0.26.1) |
| `delta` | 32,138 stars, `pushed_at` 2026-09-02 (`GET https://api.github.com/repos/dandavison/delta`, 2026-09-10) | `DELTA_PAGER` → `bat::config::get_pager_executable` (i.e. `BAT_PAGER` → `PAGER`) → `less` (`src/env.rs:11,41-47`, tag 0.19.2) | `shell_words::split` (`src/utils/bat/output.rs:120`), `Command … .stdin(Stdio::piped()).spawn()` (`:146-147`), `command.wait()` in `Drop` (`:59`) |
| `jj` | 31,500 stars, `pushed_at` 2026-09-10 (`GET https://api.github.com/repos/jj-vcs/jj`, 2026-09-10) | `JJ_PAGER` → `ui.pager` config → `["less", "-FRXK"]`; **`PAGER` is deliberately ignored** (`docs/config.md:895-897`, v0.45.1) | `cmd.stdin(Stdio::piped()).spawn()` (`cli/src/ui.rs:77-78`), `child.wait()` (`:123`); optional in-process `streampager` behind `ui.pager = ":builtin"` |
| `git` | The reference tool for the convention | `GIT_PAGER` → `core.pager` → `PAGER` → `DEFAULT_PAGER` (`less`); empty or `"cat"` disables (`pager.c:85-106`, v2.51.0) | `fork`+`dup2` self-redirect, plus `LESS=FRX LV=-c` injected into the child environment only when unset (`Makefile:2288`; `pager.c:109-130`) |
| `gh` (Go, cross-ecosystem corroboration) | GitHub's own CLI | `GH_PAGER`, `PAGER` "in order of precedence" (<https://cli.github.com/manual/gh_help_environment>) | out of scope (Go) |
| `cargo-nextest`, `gix-diff`, `dialoguer`, `portable-pty` | All appear on `GET https://crates.io/api/v1/crates/shell-words/reverse_dependencies` (786 reverse dependencies total, 2026-09-10) | — | corroborate `shell-words` as the ecosystem's command-string splitter |

**What the practice evidence establishes.** Four of the five surveyed tools honour the generic `PAGER` after an app-specific variable; the fifth (`jj`) documents its refusal as a deliberate choice. All three Rust tools reach for the same two primitives — `shell_words::split` plus `std::process::Command` with a piped stdin — and **none** of them uses the `pager` crate, `minus` or `streampager` as the primary path. `bat` and `jj` ship an in-process pager only as an opt-in alternative (`PAGER=builtin`, `ui.pager=":builtin"`).

**Step 4 — fit against this template.** `rs-launch-blueprint` is CLI + library + web service (`docs/port/PARAMETERS.md`, spec §4 D7). Only the CLI surface can page; the library must not touch process streams (a constraint R67's decision already imposes: "the library crate … must write to no process stream or file", `docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes`), and the web service has no terminal. So the paging code belongs in the CLI binary crate alone, must be inert when linked as a library, and must add zero dependencies to the library crate. That immediately disqualifies any design in which paging is a global process-level side effect (the `pager` crate's `fork`/`exec` self-redirect) and favours a design where the CLI's output writer is chosen at the composition root.

### Principles and implementation

**The shared requirement, its source, and its agreement level.**

> **Principle P1 (capability).** When a command writes long human-readable results to an interactive terminal, the user must be able to scroll them, and the program must obey the pager the user has already configured for their other tools rather than imposing one.
> **Source.** `clig.dev`: "Use a pager (e.g. less) if you are outputting a lot of text. For example, git diff does this by default. … Use a pager only if stdin or stdout is an interactive terminal. A good sensible set of options to use for less is less -FIRX." (<https://clig.dev/>, retrieved 2026-09-10). py implements it (`src/py_launch_blueprint/cli/output.py:177`, pin `b08bccfb`) and cites clig.dev in the module docstring of that same file.
> **Agreement level: capability + policy.** All three repos should *have* the capability and should share the *resolution policy* (app-specific variable first, then `PAGER`, then a `less -FRX`-equivalent default, empty value disables). The *mechanism* (subprocess plumbing, tokenizer library, stream ownership) is ecosystem-local and may differ.

> **Principle P2 (policy).** Paging must never change what a non-interactive consumer sees. A piped run, a redirected run, a machine format, a `--no-input` script and a CI job all get byte-identical output to a program with no pager at all.
> **Source.** py ADR 0008 ("piped runs, `--output-file`, JSON/Markdown modes, and `--no-input` scripts must behave exactly as before", `docs/adr/0008-pager-for-long-text-output.md`, pin `b08bccfb`); `git`'s `if (!stdout_is_tty) return NULL;` (`pager.c:89`, v2.51.0); `clig.dev` as quoted above.
> **Agreement level: policy — must agree in all three repos.** This is the load-bearing half of the item; it is what makes paging safe to add at all.

> **Principle P3 (policy).** A pager failure must never lose the user's output, and must never change the program's exit status.
> **Source.** py ADR 0008 ("a missing pager binary must not lose output"); `bat` `src/output.rs`: `.spawn().map(OutputType::Pager).unwrap_or_else(|_| OutputType::stdout())` (v0.26.1); `delta` `src/utils/bat/output.rs:146-147`; `jj` `cli/src/ui.rs:402` (falls back with a warning).
> **Agreement level: policy — must agree.**

**Observable acceptance criteria** (each is a black-box behaviour of the built CLI, checkable without reading the source):

| # | Given | Then |
|---|---|---|
| A1 | stdout is not a terminal (`cmd \| cat`, `cmd > file`) | no pager process is created, and stdout bytes equal the same command run with paging disabled |
| A2 | output format is not the human text format (`--format json`) | no pager process is created |
| A3 | `--no-input` (or `--no-pager`) is passed | no pager process is created |
| A4 | `RSLB_PAGER` and `PAGER` both set, stdout is a terminal | the process launched is the one named by `RSLB_PAGER` |
| A5 | only `PAGER` set | the process launched is the one named by `PAGER` |
| A6 | neither set | the process launched is `less` with `-F`, `-R` and `-X` in effect |
| A7 | `RSLB_PAGER=""` (set but empty) | no pager process is created; output goes straight to stdout |
| A8 | `RSLB_PAGER=/nonexistent/binary` | exit status is unchanged, stderr carries at most a hint, and the full result appears on stdout |
| A9 | colour is active and a pager is used | ANSI SGR sequences reach the pager unmodified (the pager, not the program, decides how to display them) |
| A10 | the user quits the pager before all output is written | the process exits `0` with no error envelope (R67's `BrokenPipe`-on-result-stream rule) |
| A11 | the crate is used as a library | no pager code runs and no pager dependency is present in the library crate's dependency graph |

**Question 1 — is paging worth adopting at all?** **Yes, adopt.** Four independent reasons, in decreasing weight:

1. *Owner direction.* `docs/port/OWNER-REVIEW.md:105` records disposition `accept` for R64 with the owner's words: "Looking at architectural pattern, not the exact library. We'd like a similar pager pattern for TypeScript and Rust." The adopt/omit question is settled by the owner; what remains open is the pattern.
2. *The absence in ts is not evidence against.* `docs/port/DIVERGENCE-ANALYSIS.md:202` records for R64: ts state `absent`, "no recorded reason; prompt notes no ts decision record even considered paging". `TS_PORT_DECISIONS.md` contains no decision on the subject. An unconsidered omission is not a rejection, and `DIVERGENCE-ANALYSIS.md:303` itself flags R64's class-D assignment as resting on the inference that this is a scope gap.
3. *Cost is near zero and it is confined.* The design below adds exactly one crate (`shell-words`, zero transitive dependencies, `#![forbid(unsafe_code)]`) to the **binary** crate only, and roughly 60 lines of `std::process` code. Nothing enters the library crate or the web crate.
4. *The template's output length does justify it.* The template ships a list-shaped result surface (py's `CLIResult` renders rich tables, `output.py`), and a template's whole purpose is to be filled in with the adopter's data. Sizing the terminal contract to the demo payload would be a design error: `git log` is short in an empty repository too.

The honest counter-argument is that a pager is a *user-experience nicety* that a template could leave to the adopter. The rebuttal is that retrofitting it is exactly the kind of thing an adopter gets wrong (it is the one piece of CLI plumbing that `clig.dev` explicitly warns about: "Using a pager can be error-prone, so be careful with your implementation such that you don't make the experience worse for the user"). Shipping the correct gates once, in the template, is the point of a template.

**Question 2 — crate or hand-rolled `std::process`?** **Hand-rolled `std::process::Command`, with `shell-words` for tokenization only.** There is no maintained pager-invocation crate that fits, and the reason is architectural, not popularity:

| Architecture | Representative | How it works | Why it does or does not fit |
|---|---|---|---|
| **Spawn-and-pipe (recommended)** | `bat`, `delta`, `jj`, and this recommendation | Parent renders, child is spawned with `stdin(Stdio::piped())`, parent writes to `child.stdin`, drops it, then `child.wait()`s | The parent keeps its identity, its exit code and its error path. Paging is a *local* choice of writer, so the library crate is untouched (A11). Failure to spawn is recoverable (P3). Colour bytes pass through the pipe unaltered (A9). Works unchanged on Windows if a pager exists there |
| **Self-redirect (`fork`+`dup2`+`exec`)** | the `pager` crate; `git` itself (`pager.c`) | The *parent* becomes the pager; the original program continues as the child, with its stdout wired to the new parent's stdin | Fails this template on three counts. (a) It is a whole-process side effect, so it cannot live behind a CLI-only composition root (A11). (b) After the redirect there is nothing to fall back *to* (P3). (c) `git` can afford it because `git` owns its whole process; a template that is also a library cannot. The `pager` crate additionally cannot express a two-tier env chain — `Pager::with_env("MY_PAGER")` *replaces* the variable consulted rather than layering it above `PAGER` (crate docs, `src/lib.rs:20-30`, `pager` 0.16.1) |
| **In-process pager** | `minus`, `sapling-streampager` | The program links a pager and draws the screen itself | Contradicts P1 at the root: the user's configured pager is never consulted. It is a fine *fallback* on platforms with no `less` (which is exactly how `bat` and `jj` use it), but it is the wrong default. It also drags in a terminal-control stack (`minus` → `crossterm 0.29`, `textwrap`, `thiserror 2`, `crossbeam-channel`, `parking_lot`; `Cargo.toml`, `minus` 5.7.2, 2026-09-10) into a template that has not yet decided it wants one |

**Question 3 — the cross-repo principle, and where the ecosystems justifiably differ.**

*What must agree across py, ts and rs:* the capability (P1), the non-interactive invariance policy (P2), the never-lose-output policy (P3), the resolution order `<APP>_PAGER` → `PAGER` → `less -FRX`, and the "set but empty disables" convention. These are language-neutral: each one is a statement about observable behaviour, and each has a direct implementation in all three ecosystems.

*What may justifiably vary:* the tokenizer (`shlex` module in Python, `shell-words` in Rust, `child_process` with `shell: true` or a splitter in Node), the stream-ownership style (Python buffers into a `rich` capture; Rust and Node stream into the child's stdin), and the TTY-detection primitive (Python `isatty`, Rust per R65, Node `tty.isatty`). None of these changes an acceptance criterion.

*Accidental drift versus justified difference.* ts's absence of paging is **accidental drift**, not a justified ecosystem difference: nothing about Node prevents `child_process.spawn('less', ['-FRX'], {stdio: ['pipe','inherit','inherit']})`, and no ts decision record considered the question. The follow-on project should add paging to ts under the same P1–P3 principles. py's design is *substantively* right but has one defect this research found (below) and one mechanism this research proposes to drop (below).

BASELINE-REVIEW: F285 — the resolved pager command must carry raw-control-chars regardless of which layer supplied it — replace py's "bake `-FRX` into the default string only" with git's mechanism: default the command to `less -FRX` *and* inject `LESS=FRX` (and `LV=-c`) into the pager child's environment when those variables are unset — evidence: with py at pin `b08bccfb`, `PAGER=less` (a common setting, with no flags) makes `_resolve_pager_command()` return `"less"` (`src/py_launch_blueprint/cli/output.py:88`), so `subprocess.run(["less"], input=text)` runs `less` without `-R` and the user sees literal `ESC[31m` escape sequences instead of colour; py's own default flags are bypassed precisely when the user has expressed a preference. git avoids this by setting `PAGER_ENV = LESS=FRX LV=-c` (`Makefile:2288`, v2.51.0) and applying each pair only `if (!getenv(argv[i]))` (`pager.c:127`), so a bare `less` from any layer still gets `FRX`; `bat` avoids it differently, by rewriting the argument list to add `-R -F` when and only when the pager came from the generic `PAGER` variable (`src/output.rs:116-135`, v0.26.1). Affected items: R64 (this item) owns the fix for rs; the follow-on py/ts harmonization project should apply it to `output.py:56,88`.

BASELINE-REVIEW: F284 — the paging gate should be "is this an interactive text-mode result stream", not "…and is the rendered output taller than the terminal" — proposed change: drop py's explicit terminal-height measurement and its full-output capture buffer, and let `less -F` (`--quit-if-one-screen`) provide the one-screen behaviour, streaming into the pager instead of buffering — evidence: `less -F` "Causes less to automatically exit if the entire file can be displayed on the first screen" (`less(1)`, `less` 668, retrieved 2026-09-10), which is the behaviour py's height check re-implements; none of `git` (`pager.c`, v2.51.0), `bat` (`src/output.rs`, v0.26.1), `delta` (`src/utils/bat/output.rs`, 0.19.2) or `jj` (`cli/src/ui.rs`, v0.45.1) measures terminal height before paging — all four delegate it to the pager's `-F`; py's own ADR 0008 gives the reason for the check as "non-less pagers would page one-line results" (`docs/adr/0008-pager-for-long-text-output.md`, pin `b08bccfb`), which is a *deliberate user choice* when the pager came from the user's own `PAGER`, and is handled by the `LESS=FRX` injection above when it did not. Cost of the change: `terminal_size` is not needed, the whole result no longer has to be held in memory before display, and the user sees the first screen before the command finishes. Cost if wrong: a user whose `PAGER` is `more` sees one-line results paged — the same thing they already get from `git`. Affected items: R64 (this item) owns the rs design; the follow-on project may apply it to py `output.py:184-196`.

**Comparison of the two viable architectures, with maturity, dependability, performance and integration cost.**

| Dimension | Spawn-and-pipe (`std::process` + `shell-words`) | In-process (`minus` / `sapling-streampager`) |
|---|---|---|
| Maturity | `std::process::Command` stable since Rust 1.0; `shell-words` at 1.1.1 since 2025-12-10 with a stable two-function API | `minus` 5.7.2 (2026-07-15); `sapling-streampager` 0.12.0 (2026-01-15) — both pre-1.0 |
| Dependability | Failure modes are `spawn()` → `ErrorKind::NotFound` (recoverable) and `write` → `BrokenPipe` (defined by R67 as a normal exit-0 path). Proven in three tools with a combined 123,000+ GitHub stars | The pager runs on a thread inside the process; a panic in it is a panic in the CLI. `bat` wraps it in `spawn(move \|\| minus::dynamic_paging(pager))` and joins on drop (`src/output.rs:24-33`) |
| Representative performance | Cost is one `fork`/`exec` (single-digit milliseconds on Linux and macOS) plus a pipe write. Streaming means time-to-first-screen is independent of total output size. No measured benchmark was run for this item, and none is claimed | Zero process cost, but the whole terminal-control stack is initialized in-process and the data is buffered in the pager's own store. No measured benchmark was run for this item |
| Resource cost | One child process; the parent's peak memory is a write buffer, not the whole output | No child process; peak memory holds the paged content plus a `crossterm` terminal state |
| Integration cost | 1 direct dependency (`shell-words`, 0 transitive), CLI crate only | `minus` pulls `crossterm`, `textwrap`, `thiserror`, `crossbeam-channel`, `parking_lot` (`Cargo.toml`, 5.7.2) |
| Honours the user's configured pager (P1) | Yes — that is its entire mechanism | No |

**Minimal realistic example.** In the CLI binary crate only, three small pieces compose:

```rust
// crates/rslb-cli/src/pager.rs  (illustrative; P03 writes the real code)
use std::env;
use std::io::{self, Write};
use std::process::{Child, Command, Stdio};

const DEFAULT_PAGER: &str = "less -FRX";
const APP_PAGER_VAR: &str = "RSLB_PAGER";

/// `--no-pager` / `--no-input` → None. Otherwise RSLB_PAGER > PAGER > `less -FRX`;
/// a variable that is *set but empty* disables paging (git convention).
fn resolve_pager(paging_enabled: bool) -> Option<String> {
    if !paging_enabled {
        return None;
    }
    let cmd = match env::var(APP_PAGER_VAR).or_else(|_| env::var("PAGER")) {
        Ok(v) => v,
        Err(_) => DEFAULT_PAGER.to_owned(),
    };
    let cmd = cmd.trim().to_owned();
    (!cmd.is_empty() && cmd != "cat").then_some(cmd)
}

/// Spawn the pager, or return None so the caller writes to stdout instead.
fn spawn_pager(cmd: &str) -> Option<Child> {
    let argv = shell_words::split(cmd).ok()?;
    let (bin, args) = argv.split_first()?;
    let mut c = Command::new(bin);
    c.args(args).stdin(Stdio::piped());
    // git's mechanism: give a flag-less `less` sane defaults without overriding
    // a preference the user has already expressed (git Makefile PAGER_ENV).
    if env::var_os("LESS").is_none() {
        c.env("LESS", "FRX");
    }
    if env::var_os("LV").is_none() {
        c.env("LV", "-c");
    }
    c.spawn().ok()
}

/// The single seam the renderer uses. `is_tty` comes from whatever check R65 lands on.
pub fn result_writer(is_tty: bool, text_mode: bool, paging: bool) -> Box<dyn Write> {
    if is_tty && text_mode {
        if let Some(cmd) = resolve_pager(paging) {
            if let Some(child) = spawn_pager(&cmd) {
                return Box::new(PagerWriter(child));
            }
        }
    }
    Box::new(io::stdout())
}
```

`PagerWriter` owns the `Child`; its `Drop` takes `child.stdin` (closing the pipe, which is what tells `less` it has reached EOF) and then calls `child.wait()`, exactly as `bat` does (`src/output.rs`, `impl Drop for OutputType`, v0.26.1) and `delta` does (`src/utils/bat/output.rs:59`, 0.19.2). While a pager child is alive the CLI must not act on `SIGINT` itself; `git` handles this by pushing a signal handler that finishes the pager, pops itself and re-raises the signal (`pager.c:65-73`, v2.51.0), and `bat`/`jj` handle it by passing `less -K` so the pager exits on `^C` (`src/output.rs:135`, v0.26.1; `cli/src/config/misc.toml:39`, v0.45.1). The concrete signal mechanism belongs to R67 (which already owns `RSLB901` SIGINT → 130 and names `signal-hook`); this item states the requirement, not the mechanism.

**Executable acceptance check (proposed — nothing was executed against a Rust template, because none exists yet).** A1–A11 above map onto `assert_cmd` + `predicates` integration tests plus two shell probes; the exact commands are under `### Validation strategy`. What *was* executed for this report is listed there too, so the two are not confused.

### Recommendation

**Adopt paging, with a three-part stack, in the CLI binary crate only:**

> `shell-words` **1.1.1** for command-string tokenization + a **two-tier environment resolution policy** (`--no-pager`/`--no-input` → `RSLB_PAGER` → `PAGER` → `less -FRX`, a set-but-empty value disabling, and `LESS=FRX`/`LV=-c` injected into the child when unset) + **spawn-and-pipe invocation** through `std::process::Command` with `Stdio::piped()`, a `Drop` that closes the pipe and `wait()`s, and a fall-through to `io::stdout()` whenever resolution or spawning fails.

No terminal-height measurement and no `terminal_size` dependency: `less -F` provides quit-if-one-screen, and the output is streamed rather than buffered. Paging is gated on the *result stream* being a terminal, reusing whatever TTY check R65 selects, and on the active format being the human text format (R66). Windows is neither `#[cfg]`-excluded nor claimed: the code is portable `std::process`, and on a machine without `less` the `NotFound` fallback prints normally.

### Members

#### shell-words

##### Landscape

Bin: **established industry standard**. Category within this item: the *tokenizer* — the component that turns a pager command *string* (`"less -FRX"`, `"/usr/local/bin/my pager --flag"`) into an argv vector, applying UNIX shell word-splitting and quote-removal rules without invoking a shell. The alternatives found on the map are `shlex` 2.0.1 (the other general-purpose splitter) and "no crate at all" (split on whitespace, or pass the string to `sh -c`). Both are evaluated below.

##### Principles and implementation

This member serves P1 (honour the user's configured pager) in a specific, easily-missed way: the pager the user configured is a *command line*, not a program name. `PAGER="less -R"` and `PAGER="/opt/my tools/pager"` must both work, and neither survives a naive `split_whitespace()`. Passing the string to `sh -c` instead would work but hands arbitrary text to a shell and loses the ability to inspect the resolved binary name — a security posture no surveyed tool takes. `shell-words` implements exactly the POSIX splitting rules and returns `Result<Vec<String>, ParseError>` so an unbalanced quote is a *recoverable* error that routes into P3's fallback rather than a panic or a mangled argv. The library crate never links it: it is a CLI-crate dependency (A11).

##### Dominant choice

`shell-words` is the dominant choice **for this job specifically**, on direct precedent rather than on raw download count. `bat` declares `shell-words = { version = "1.1.0", optional = true }` and gates it behind its `paging` feature: `paging = [ "shell-words", "grep-cli", "minus" ]` (`Cargo.toml:36,54`, tag v0.26.1) — the crate is in `bat` *because of* paging and for no other reason. `delta` declares `shell-words = "1.0.0"` (`Cargo.toml:51`, tag 0.19.2) and calls `shell_words::split` on the resolved pager command at `src/utils/bat/output.rs:120`. `cargo-nextest` (`Cargo.toml:41`, `shell-words.workspace = true`, retrieved 2026-09-10), `gix-diff` 0.67.1, `dialoguer` 0.12.0 and `portable-pty` 0.9.0 all appear on the reverse-dependency list (`GET https://crates.io/api/v1/crates/shell-words/reverse_dependencies?per_page=20`, `meta.total` = 786, 2026-09-10).

**Figures** (all `GET https://crates.io/api/v1/crates/shell-words` and `…/versions`, and `GET https://api.github.com/repos/tmiasko/shell-words`, retrieved 2026-09-10):

| Figure | Value | Endpoint / field |
|---|---|---|
| 90-day downloads | 36,835,500 | `crate.recent_downloads` |
| All-time downloads | 143,814,152 | `crate.downloads` |
| Last release | `1.1.1`, `2025-12-10T20:48:28.942402Z` | `/versions`, newest with `yanked: false`: `num`, `created_at` |
| Stars | 86 | `stargazers_count` |
| Archived | `false` | `archived` |
| Last push | `2025-12-10T20:50:02Z` | `pushed_at` |
| Open issues | 3 | `GET https://api.github.com/search/issues?q=repo:tmiasko/shell-words+is:issue+is:open`, `total_count` |
| Issue responsiveness | median 46.91 days to first maintainer response over the 4 answered of the 8 issues returned; 4 unanswered | `GET .../issues?state=all&sort=created&direction=desc&per_page=30`, pull requests filtered out, first comment with `author_association` in OWNER/MEMBER/COLLABORATOR other than the opener. Per-issue: #18 115.09 d, #12 0.53 d, #8 0.68 d, #1 93.14 d; #17, #14, #5, #4 unanswered |
| Advisories | none — `https://rustsec.org/packages/shell-words.html` returns HTTP 404 (no advisory page). Control: `https://rustsec.org/packages/time.html` returns HTTP 200 and lists RUSTSEC-2020-0071, RUSTSEC-2026-0009, so 404 genuinely means "no advisories" | RustSec |
| Adopters | `bat` v0.26.1 `Cargo.toml:54`; `delta` 0.19.2 `Cargo.toml:51`; `cargo-nextest` `cargo-nextest/Cargo.toml:41`; `gix-diff` 0.67.1, `dialoguer` 0.12.0, `portable-pty` 0.9.0 via the reverse-dependencies page. `bat` and `delta` are relevant references because they are the two Rust CLIs whose paging implementations this whole item is modelled on, at 60,398 and 32,138 stars respectively | reverse-dependencies page + each project's `Cargo.toml` |

**Maintenance state: `stable-quiet`.** The rubric's six-month trigger fires (releases in 2020, 2022 and 2025) and was investigated: the repository contains 7 files and one 100-line source module; the last functional commit is "Use the correct tilde when escaping" (2024-12-13), shipped as 1.1.1 on 2025-12-10 (`GET https://api.github.com/repos/tmiasko/shell-words/commits?per_page=6`, 2026-09-10). Quietness reflects a finished specification — POSIX word splitting does not change — not neglect. It is **not** `at-risk`: there is no unpatched advisory, no broken build, and no maintainer notice. The concrete negatives are recorded honestly: 4 of 8 issues never received a maintainer reply, the median first response over answered issues is 46.91 days, and the repository has **no CI workflow at all** (`GET https://api.github.com/repos/tmiasko/shell-words/git/trees/master?recursive=1` lists only `.gitignore`, `Cargo.toml`, `LICENSE-APACHE`, `LICENSE-MIT`, `README.md`, `rustfmt.toml`, `src/lib.rs`; 2026-09-10).

##### Qualified shortlist

- **`shell-words` 1.1.1** — figures above. Passes every gate; direct precedent in both reference implementations.
- **`shlex` 2.0.1** — 235,305,397 downloads in 90 days and 808,753,085 all-time (`GET https://crates.io/api/v1/crates/shlex`, 2026-09-10); newest unyanked `2.0.1`, `2026-05-17T18:56:12.775983Z`, `rust_version: "1.46.0"`, `license: "MIT OR Apache-2.0"` (`…/versions`, 2026-09-10); 156 stars, not archived, `pushed_at` `2026-06-12T19:38:35Z` (`GET https://api.github.com/repos/comex/rust-shlex`, 2026-09-10). Advisory: `https://rustsec.org/packages/shlex.html` returns HTTP 200 listing **RUSTSEC-2024-0006** ("Multiple issues involving quote API", categories code-execution and file-disclosure, aliases CVE-2024-58266 / GHSA-r7qv-8r2h-pg27, "Patched >=1.3.0", affected functions `shlex::quote`, `shlex::join`, `shlex::bytes::quote`, `shlex::bytes::join`, all `<1.2.1`; <https://rustsec.org/advisories/RUSTSEC-2024-0006.html>, 2026-09-10). The recommended version 2.0.1 is **not** affected, and the affected functions are the quoting side, which this use case does not call — so gate 3 ("no *open* advisory") passes. Maintenance: `active`. It is a genuine near-tie and the ranked runner-up.
- **No crate (`sh -c "$PAGER"`)** — zero dependencies, and it is what `jj` recommends users write for themselves when they want shell semantics (`docs/config.md:990-995`, v0.45.1). Rejected as the default: it makes the pager command a shell script, so a malformed `PAGER` becomes a shell error rather than a recoverable `ParseError`, it adds a second process, and it prevents inspecting the resolved binary name.

##### Excluded by gate

None. Both shortlisted tokenizers pass all six gates for the versions recommended. The only exclusions in this item are architectural (the `pager` crate and the in-process pagers), and they are recorded under the two pattern members where the architecture is decided.

##### Up-and-comers

No new entrant. The category is settled: `shell-words` and `shlex` have both existed since 2018 and 2015 respectively, and the three crates.io searches described under `### Landscape` surface no newer competitor. Adjacent and worth naming so it is not mistaken for a gap: **`grep-cli` 0.1.12** (1,998,102 downloads in 90 days, `GET https://crates.io/api/v1/crates/grep-cli`, 2026-09-10; part of BurntSushi's `ripgrep` workspace) supplies `resolve_binary`, which both `bat` (`src/output.rs:105`) and `delta` (`src/utils/bat/output.rs:181`) call on the tokenized pager binary. It is **not** recommended here: `Command::new` already searches `PATH`, and its `spawn()` error is precisely the fallback trigger P3 needs, so `resolve_binary` would add a dependency to move an error one step earlier.

##### Fit for this template

Fits cleanly. It is a CLI-crate-only dependency, so the library crate's public dependency surface (R04's concern) and the web crate are untouched (A11). It has **zero** transitive dependencies (`Cargo.toml`, `shell-words` 1.1.1, retrieved 2026-09-10 — the file declares no `[dependencies]` section at all), so it cannot conflict with any other item's version choices. It is `#![forbid(unsafe_code)]` and `#![cfg_attr(not(feature = "std"), no_std)]` (`src/lib.rs:11-12`, master, 2026-09-10), which sits exactly on R06's settled policy line. Its API is two functions, so a fork that dislikes the dependency can vendor it.

##### Recommendation

**`shell-words = "1.1"`**, in the CLI binary crate only, no features beyond the default `std`.

##### Ranked runner-up

**`shlex = "2.0"`.** Switch to it if either of two things happens: `shell-words` stops responding to a correctness report (its 46.91-day median first response is the weak figure in its record), or the template later needs the *quoting* direction (`shlex::quote`) as well as splitting, where `shlex`'s post-1.3.0 API is the better-audited one. The migration is mechanical: `shell_words::split(s) -> Result<Vec<String>, ParseError>` becomes `shlex::split(s) -> Option<Vec<String>>`, and the single call site is the `spawn_pager` function shown above.

##### Tradeoffs

| Choosing `shell-words` gains | Choosing `shell-words` costs |
|---|---|
| Exact precedent: it is what `bat` and `delta` use for this identical job | A quiet maintainer with a 46.91-day median first response and 4 of 8 issues unanswered |
| Zero transitive dependencies; no version-resolution interaction with any other R## item | No CI in the repository, so "builds on ubuntu and macOS" rests on downstream evidence rather than a badge |
| `#![forbid(unsafe_code)]`, `no_std`-capable | No declared `rust-version`, so gate 2 is satisfied by inference plus the template's own MSRV job, not by the crate's metadata |
| An error type (`ParseError`) that routes a malformed command into the P3 fallback | `Result` handling at the call site is one more branch than `shlex`'s `Option` |

##### Parameters

`owns` — none. This member registers no shared parameter.
`assumes license = MIT OR Apache-2.0` — satisfied: `shell-words` 1.1.1 declares `license = "MIT/Apache-2.0"` (`Cargo.toml`, 2026-09-10) and ships both `LICENSE-APACHE` and `LICENSE-MIT` in the repository root.
`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the current floor is **1.96**, computed from `[pkg.rustc] version = "1.98.1 (48a229cea 2026-09-01)"` (`GET https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-10). See gate 2 under `### Confidence & re-verify trigger`.
`assumes rust-edition = 2024` — satisfied at the template level; the dependency declares no `edition` key at all, i.e. it compiles under the 2015 edition ruleset, which any 2024-edition crate may depend on.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied; see gate 4 below.
No `CONFLICT:` lines.

##### Migration implications

`crates/rslb-cli/Cargo.toml`: one line, `shell-words = "1.1"`. `Cargo.lock`: one new package entry with no transitive additions. Nothing else in the workspace changes; in particular `crates/rslb-core` (the library) and any web crate gain nothing.

##### Validation strategy

Proposed, not executed (no Rust template exists). Three checks: (1) `cargo tree -p rslb-cli -i shell-words` shows the crate with no children, and `cargo tree -p rslb-core | grep shell-words` finds nothing — proving A11; (2) a unit test asserting `shell_words::split("/opt/my pager/less -FRX")` and `shell_words::split("less \"-F\" -R")` produce the expected argv, and that `shell_words::split("less \"unterminated")` returns `Err` rather than panicking; (3) the MSRV CI job (`cargo +1.96 check -p rslb-cli`) as the empirical answer to the undeclared-MSRV question.

##### Confidence & re-verify trigger

**Gate-by-gate, before popularity was weighed:**

1. **License compatible with `MIT OR Apache-2.0`** — **pass.** `license = "MIT/Apache-2.0"` (old-style slash spelling of the dual licence), with `LICENSE-APACHE` and `LICENSE-MIT` both present in the repository tree (2026-09-10).
2. **MSRV within stable minus 2 minors (1.96)** — **pass with a qualification.** `shell-words` 1.1.1 declares **no** `rust-version` (`GET https://crates.io/api/v1/crates/shell-words/versions`, `rust_version: null`, 2026-09-10), so the policy's "declared as rust-version in Cargo.toml" clause is unmet *by the dependency*. The policy binds this template's own crates, which will declare `rust-version = "1.96"`. The dependency's actual floor is far below 1.96: it declares no `edition` (so, edition 2015), has zero dependencies, and its source uses no post-1.46 construct. The verification is empirical — the template's MSRV CI job compiles the whole tree on the floor toolchain — and that job is the mechanism the policy already requires.
3. **No open RustSec advisory; `unsafe` posture** — **pass.** `https://rustsec.org/packages/shell-words.html` → HTTP 404 (no advisory page; control verified against `time`, which returns 200). Posture: `#![forbid(unsafe_code)]` at `src/lib.rs:12` — the strongest possible statement, and consistent with R06's `unsafe_code = "forbid"` workspace lint (R06 `DECISION.md`), though R06 correctly notes dependencies compile under `--cap-lints allow` so the template makes no claim about them.
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — **pass by downstream evidence, not by a badge.** The repository has no CI workflow (tree listing, 2026-09-10), so there is no badge or stated platform list. The crate is pure Rust with no `cfg`-gated code and no dependencies, and it is compiled on both platforms on every release of `bat` (which ships macOS and Linux binaries) and `delta`. Windows: the crate compiles there, but its *behaviour* is POSIX word-splitting, which eats backslashes — `C:\tools\less.exe` tokenizes to `C:toolsless.exe`. py hit exactly this and added a `posix=False` branch with quote-stripping (`_pager_argv`, `output.py:63-79`, pin `b08bccfb`, whose docstring names the failure). `bat` and `delta` do not: they use `shell_words::split` unconditionally on every platform, so a Windows user spells the path with forward slashes or quotes it. This template inherits `bat`'s behaviour, and Windows is not in `target-os-matrix`, so this is documented rather than special-cased — adding py's second tokenizer branch would ship an untested code path for a platform CI never exercises.
5. **Default features and async-runtime coupling** — **stated.** Default feature set is `["std"]`; the only other feature is `std` itself, which when disabled makes the crate `no_std` (`GET https://crates.io/api/v1/crates/shell-words/versions`, `features`, 2026-09-10). **No async runtime coupling of any kind** — the crate is a pure function over a string.
6. **Binary-size and compile-time cost** — **stated qualitatively.** One ~100-line module with no dependencies and no generics instantiated across crate boundaries: compile time is a single small codegen unit (well under a second on the CI runners' hardware), and the linked size contribution is a few kilobytes of string-scanning code. No measurement was taken, and none is claimed — there is no Rust template to measure.

**Confidence: high** for the choice, **medium** for the maintenance outlook. The choice is high-confidence because two independent reference implementations use this exact crate for this exact job and the crate's surface is too small to hide a surprise. The maintenance outlook is medium because the maintainer is demonstrably slow to respond and the repository has no CI.

**Re-verify triggers.** (a) `shell-words` acquires a RustSec advisory, or (b) `GET https://api.github.com/repos/tmiasko/shell-words` shows `archived: true`, or (c) a correctness bug filed against `split` goes 90 days without a maintainer reply, or (d) `bat` or `delta` drops the dependency — any of these should re-open the `shlex` comparison. Routine re-check at P03 start and at each MSRV floor bump.

##### Sources

- `GET https://crates.io/api/v1/crates/shell-words` and `…/versions` and `…/reverse_dependencies?per_page=20` — 2026-09-10.
- `GET https://api.github.com/repos/tmiasko/shell-words`, `…/git/trees/master?recursive=1`, `…/commits?per_page=6`, `…/issues?state=all&sort=created&direction=desc&per_page=30`, `…/issues/<n>/comments?per_page=20` — 2026-09-10.
- `GET https://api.github.com/search/issues?q=repo:tmiasko/shell-words+is:issue+is:open` — 2026-09-10.
- <https://raw.githubusercontent.com/tmiasko/shell-words/master/Cargo.toml>, `…/src/lib.rs` — 2026-09-10.
- <https://raw.githubusercontent.com/sharkdp/bat/v0.26.1/Cargo.toml> (lines 36, 54) — 2026-09-10.
- <https://raw.githubusercontent.com/dandavison/delta/0.19.2/Cargo.toml> (line 51), `…/src/utils/bat/output.rs` (line 120) — 2026-09-10.
- <https://raw.githubusercontent.com/nextest-rs/nextest/main/cargo-nextest/Cargo.toml> (line 41) — 2026-09-10.
- `GET https://crates.io/api/v1/crates/shlex` and `…/versions`; <https://rustsec.org/packages/shlex.html>; <https://rustsec.org/advisories/RUSTSEC-2024-0006.html>; `GET https://api.github.com/repos/comex/rust-shlex` — 2026-09-10.
- <https://rustsec.org/packages/shell-words.html> (404) and <https://rustsec.org/packages/time.html> (200, control) — 2026-09-10.
- `GET https://static.rust-lang.org/dist/channel-rust-stable.toml` — 2026-09-10.
- `GET https://crates.io/api/v1/crates/grep-cli` — 2026-09-10.

#### Pager-command resolution policy (pattern: `--no-pager` → `RSLB_PAGER` → `PAGER` → `less -FRX`, empty disables, `LESS`/`LV` defaults injected)

##### Landscape

Bin: **established industry standard**, and specifically a *convention*, not a library. The category is "how a CLI discovers which pager the user wants". Every candidate on the map is a policy shape rather than a crate, so the three bins are populated by conventions and their reference implementations:

| Bin | Candidate policy | Reference implementation |
|---|---|---|
| Built-in / first-party toolchain | none — the Rust standard library offers `std::env::var` and nothing above it; the `rust-cli/book` has no guidance (verified, see `### Landscape`) | — |
| Established industry standard | **Two-tier chain: `<APP>_PAGER` then `PAGER`, then a built-in default; empty disables** | `git` (`GIT_PAGER` → `core.pager` → `PAGER` → `less`, empty or `"cat"` disables — `pager.c:85-106`, v2.51.0); `gh` ("GH_PAGER, PAGER (in order of precedence)"); `bat` (`--pager`/config → `BAT_PAGER` → `PAGER` → `less` — `src/pager.rs:100-108`, v0.26.1); `delta` (`DELTA_PAGER` → `BAT_PAGER` → `PAGER` → `less` — `src/env.rs:41-47`, 0.19.2); py (`PLBP_PAGER` → `PAGER` → `less -FRX` — `output.py:88,56`, pin `b08bccfb`) |
| Established industry standard (variant) | **App variable + config only; the generic `PAGER` deliberately ignored** | `jj`: "The `JJ_PAGER` environment variable overrides `ui.pager`… `PAGER` environment variable is ignored" (`docs/config.md:895-897`, v0.45.1) |
| Up-and-comer | none — no newer convention has appeared; `jj` (first release 2022) reproduces the two-tier shape and then subtracts a tier | — |

##### Principles and implementation

This member *is* principle P1 made concrete, and it is where the cross-repo agreement lives. Three sub-rules, each with an authority:

1. **App-specific variable outranks the generic one.** A user who sets `PAGER=most` for their whole shell should still be able to say "but for *this* program, use `less -R`". Every surveyed tool provides that escape hatch; `gh`'s manual states the ordering as a bare fact of the interface.
2. **A set-but-empty value disables paging.** `git(1)`: "GIT_PAGER … If it is set to an empty string or to the value `cat`, Git will not launch a pager" (<https://git-scm.com/docs/git>, 2026-09-10). py implements the empty half (`_resolve_pager_command` returns the stripped value, and `_render_text_paged` treats a falsy pager as "no paging", `output.py:82-91,180-183`). Adopting `"cat"` as well is a small, free compatibility win with the convention users already know.
3. **The default must carry raw-control-chars.** `clig.dev`: "A good sensible set of options to use for less is `less -FIRX`. This does not page if the content fills one screen, ignores case when you search, enables color and formatting, and leaves the contents on the screen when less quits." `git`'s built-in equivalent is `LESS=FRX` (`Makefile:2288`, v2.51.0). `jj`'s is `["less", "-FRXK"]` (`cli/src/config/misc.toml:39`, v0.45.1). py's is `less -FRX` (`output.py:56`). All four agree on `F`, `R` and `X`; they differ only on the optional `I` (ignore case in search) and `K` (quit on interrupt).

Flag semantics, from `less(1)` as installed here (`less` 668, `man less`, 2026-09-10): `-F` / `--quit-if-one-screen` "Causes less to automatically exit if the entire file can be displayed on the first screen"; `-R` / `--RAW-CONTROL-CHARS` "only ANSI 'color' escape sequences and OSC 8 hyperlink sequences are output in 'raw' form … the screen appearance is maintained correctly"; `-X` / `--no-init` "Disables sending the termcap initialization and deinitialization strings to the terminal", which is what leaves the output on screen after `less` exits; `-K` / `--quit-on-intr` "Causes less to exit immediately (with status 2) when an interrupt character (usually ^C) is typed".

A finding worth recording because it removes a hazard the two Rust reference implementations still carry: **`-X` *is* `--no-init`.** `bat` and `delta` both detect the installed `less` version and add `--no-init` when it is older than 530, to work around a `-F` bug (`bat` `src/output.rs:140-152`; `delta` `src/utils/bat/output.rs:186-199`; both cite <http://www.greenwoodsoftware.com/less/news.530.html>). A default of `less -FRX` already passes `--no-init` under its short name, so this template needs no version detection and no `retrieve_less_version` equivalent.

**How this member preserves each principle, and where an ecosystem needs a different design.** P1 is preserved identically in all three repos — the chain is a statement about environment variables, and Python, Node and Rust read environment variables the same way. P2 is preserved by keeping resolution *downstream* of the interactivity gate: resolution is only ever reached once the stream is known to be an interactive text-mode result stream, so a piped run never even reads `PAGER`. P3 is preserved by making every step of resolution fallible-into-fallback: an unset variable, an empty variable, `"cat"`, an unparsable string and a missing binary all converge on "write to stdout". No ecosystem needs a different design here; the only Rust-specific detail is that `std::env::var` returns `Result<String, VarError>` with distinct `NotPresent` and `NotUnicode` arms, and a non-UTF-8 pager setting should be treated as "present but unusable" → fall back, not panic.

**On `jj`'s variant.** Ignoring `PAGER` is defensible for `jj` (whose output is colour-heavy and whose maintainers wanted a pager they could pass structured argv to) but it is the wrong choice for a *template*: it makes the program surprising to a user whose `PAGER` works everywhere else, and it is the only one of five surveyed tools to do it. `jj`'s own documentation supplies the workaround for users who disagree — `ui.pager = ["sh", "-c", "exec ${PAGER:-less -FRXK}"]` (`docs/config.md:909`) — which is evidence that consulting `PAGER` is what users expect.

##### Dominant choice

The **two-tier chain with a built-in `less -FRX`-equivalent default** is dominant: 4 of the 5 surveyed tools (`git`, `gh`, `bat`, `delta`) implement it, py implements it, and the fifth (`jj`) documents its deviation and ships a documented workaround back to it.

**Figures.** Crate figures are **`inapplicable`** for this member and the reason is that it is a pattern member, not a crate: it introduces no dependency, so `crate.recent_downloads`, `crate.downloads`, `/versions`, `stargazers_count`, `archived`, `pushed_at`, RustSec advisories and reverse-dependency adopters have no subject to be measured against. The evidence that substitutes for them is the adoption table above, in which each row cites a pinned source file or maintainer document. **Maintenance state** is likewise `inapplicable` — a convention has no release cadence; the closest observable proxy is that all five reference implementations were pushed within the last 8 days (`pushed_at`: `git` — not queried; `bat` 2026-09-04, `delta` 2026-09-02, `jj` 2026-09-10; `GET https://api.github.com/repos/<o>/<r>`, 2026-09-10).

##### Qualified shortlist

| Policy | Evidence | Verdict |
|---|---|---|
| `RSLB_PAGER` → `PAGER` → `less -FRX`, empty/`cat` disables, `LESS=FRX`+`LV=-c` injected when unset | `git` `pager.c:85-130` + `Makefile:2288`; `gh` manual; `bat` `src/pager.rs`; py `output.py:56,88` | **Recommended** |
| Same chain but with a config-file tier between the app variable and `PAGER` (`git`'s `core.pager`, `bat`'s config, `jj`'s `ui.pager`) | `git` `pager.c:92-98`; `bat` `src/pager.rs:104-108`; `jj` `docs/config.md:891` | Qualified — see `### Migration implications`; the tier is worth adding **only if** R54 (`config-discovery-tiers`) lands a config file, and it slots in below the env variable without changing any acceptance criterion |
| Same chain, plus rewriting the argument list when the pager came from generic `PAGER` (add `-R`, `-F`, `-K`) | `bat` `src/output.rs:116-135`, v0.26.1 | Qualified runner-up to the `LESS` env injection; see `### Ranked runner-up` |

##### Excluded by gate

- **`jj`'s "ignore `PAGER`" variant** — excluded on **fit**, not on a numbered gate (gates 1–6 are crate gates and are `inapplicable` to a policy). Reason: it violates the principle this item exists to preserve (P1: obey the pager the user has already configured), it is a 1-of-5 minority, and `jj`'s own docs hand users a recipe to undo it.
- **`NOPAGER`-style opt-out as the only off switch** (the `pager` crate's mechanism, `src/lib.rs:73-75`, 0.16.1) — excluded on fit: an undiscoverable env variable is a worse off switch than a documented flag plus the git-standard empty-value convention, and it is not used by any surveyed tool.

##### Up-and-comers

None in this category. Recorded so the gap is explicit: the newest widely-adopted entrant, `jj` (2022), did not introduce a new resolution convention — it subtracted a tier from the existing one. There is no emerging alternative shape to watch.

##### Fit for this template

Fits, with two template-specific adaptations.

*The app-specific variable's name.* py uses `PLBP_PAGER`, derived from its app short name (py ADR 0001 `app-short-name-plbp`, ADR 0016 `app-short-name-placeholder`, pin `b08bccfb`). The rs equivalent is **`RSLB_PAGER`**, matching the `RSLB` prefix R67 already fixed for the error-code catalog (`docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes`). **No registered parameter owns the env-var prefix**: a grep of `docs/port/PARAMETERS.md` for `short-name`, `env-prefix` and `app-short` returns nothing, and the nearest ledger row, F324 ("typed env settings with an app-derived env-var prefix", R77), is scoped to the web tier. So `RSLB_PAGER` is stated here as a derived assumption, and if a later item registers an env-prefix parameter, this member follows it — no value has to change for that to work, so no `CONFLICT:` is raised.

*The off switch.* py reuses `--no-input` (ADR 0008: "a script that can't answer prompts can't quit `less` either"). That reasoning is sound and should be kept. A dedicated `--no-pager` flag should be added alongside it, matching `git --no-pager` and `jj --no-pager`, because a user who wants to see full output on a terminal without a pager has no other way to ask. Registering a global flag belongs to R60 (`cli-parsing-framework`); this member states the requirement and R60 owns the parser mechanics.

##### Recommendation

Resolve in this order, stopping at the first hit:

1. `--no-pager`, or `--no-input`, or a non-text output format, or a non-terminal result stream → **no pager**.
2. `RSLB_PAGER` if present in the environment → its value.
3. `PAGER` if present in the environment → its value.
4. otherwise → `less -FRX`.

Then: trim the resolved value; if it is empty or exactly `cat`, **no pager**. When spawning, set `LESS=FRX` and `LV=-c` in the child's environment **only if those variables are not already set in the parent's**, so that a bare `PAGER=less` still gets raw-control-chars and quit-if-one-screen without overriding a preference the user expressed deliberately. Document all of this in the generated `README`/`EXAMPLECLI` section, including the empty-value convention, since an undocumented off switch is not an off switch.

##### Ranked runner-up

**`bat`'s argument-rewriting mechanism** (`src/output.rs:116-135`, v0.26.1): when — and only when — the pager came from the generic `PAGER` variable, discard the user's flags and substitute `-R`, `-F`, `-K`. It solves the same defect the `LESS=FRX` injection solves. It is ranked second because it *discards* flags the user wrote (`PAGER="less -S"` loses `-S`), it requires classifying the pager binary (`bat`'s `PagerKind::from_bin`, `src/pager.rs:43-69`) so it knows the flags are `less` flags, and it therefore carries a table of known pagers the template would have to maintain. The `LESS` env approach is additive rather than destructive, is `git`'s own, and needs no pager classification.

##### Tradeoffs

| Decision | Gains | Costs |
|---|---|---|
| App variable above `PAGER` | Per-program override; matches `git`, `gh`, `bat`, `delta`, py | One more documented variable in the CLI's env surface |
| Empty (and `"cat"`) disables | The off switch users already know from `git`; scriptable without a flag | A user with a legitimately empty `PAGER` gets no paging — which is exactly what the convention means |
| Default `less -FRX` rather than `clig.dev`'s `less -FIRX` | Byte-identical to py's default, preserving cross-repo agreement at the value level; `-I` only affects case sensitivity of in-pager searches, which is a user preference their own `LESS` can set | Diverges by one flag from the guideline this item otherwise follows; recorded here rather than silently dropped |
| Default `less -FRX` rather than `jj`'s `less -FRXK` | Ctrl-C in the pager returns to the pager prompt (standard `less` behaviour) instead of exiting | The parent must not race the pager on `SIGINT`; that requirement is stated in member 3 and its mechanism belongs to R67 |
| Injecting `LESS=FRX` when unset | Fixes the `PAGER=less` colour defect (BASELINE-REVIEW: F285) without discarding user flags | Two more environment entries on the child; invisible unless the user is inspecting `/proc/<pid>/environ` |
| No config-file tier yet | No dependency on R54's outcome; the chain is complete and correct without it | If R54 lands a config file, one tier is added later — an additive change, no acceptance criterion moves |

##### Parameters

`owns` — none. R64's `owns:` field in `## Couplings` is empty, and this member registers no new shared parameter. The concrete values it fixes (`RSLB_PAGER`, `less -FRX`, empty-disables) are recorded in R64's `DECISION.md`, not in `docs/port/PARAMETERS.md`.
`assumes msrv-policy`, `assumes rust-edition = 2024`, `assumes license = MIT OR Apache-2.0`, `assumes target-os-matrix = ubuntu-latest, macos-latest` — all four fixed parameters are satisfied trivially: this member is a policy expressed in `std::env` calls, which are edition- and platform-independent and add no licensed code.
Derived, not registered: `assumes app-env-prefix = RSLB` — no parameter owns it (verified against `docs/port/PARAMETERS.md`, 2026-09-10); derived from R67's `RSLB` error-code prefix.
Related, not registry-consumed: R65 supplies the "is this stream a terminal" check that gates step 1; R66 supplies "is the active format the human text format"; R60 owns registration of the `--no-pager` global flag; R54 owns whether a config tier exists to slot in. None of these requires a consumed parameter to change value.
No `CONFLICT:` lines.

##### Migration implications

New file `crates/rslb-cli/src/pager.rs` holding `resolve_pager` (roughly 20 lines). One call site in the CLI's output/renderer module. Documentation: a "Paging" subsection in the generated CLI docs listing `RSLB_PAGER`, `PAGER`, the default, and the empty-value convention. If R54 later lands a config file, one additional arm between steps 2 and 3.

##### Validation strategy

Proposed. Acceptance criteria A3–A7 map one-to-one onto `assert_cmd` tests that set the environment explicitly and assert on the *argv of the process that was launched*, using a stub pager script (a shell script on PATH that writes its own `$0 $@` and its stdin to a temp file) rather than a real `less` — this is the only way to assert on the resolved command without a TTY. A7 (`RSLB_PAGER=""`) and the `cat` case assert that the stub is never invoked. The `LESS=FRX` injection is asserted by having the stub dump its own environment.

##### Confidence & re-verify trigger

Gates 1–6 are crate gates; for this pattern member they are **`inapplicable`**, each for the same reason — the member adds no crate, so there is no licence, no dependency-tree MSRV, no advisory record, no per-OS build, no feature set and no compiled artifact to measure. Stated individually so none is silently omitted: (1) licence — `inapplicable`, no third-party code; (2) MSRV — `inapplicable`, uses only `std::env`, stable since Rust 1.0, far below the 1.96 floor; (3) advisories and `unsafe` — `inapplicable` for advisories, and the `unsafe` posture is "none": the pattern is expressible entirely in safe Rust under R06's `unsafe_code = "forbid"`; (4) per-OS build — `inapplicable` as a crate check, though the *behaviour* is platform-dependent and is covered under member 3's gate 4; (5) default features / async coupling — `inapplicable`, no crate, and the resolution is synchronous with no runtime; (6) binary size / compile time — `inapplicable`, roughly 20 lines of non-generic code.

**Confidence: high.** Five independent implementations across three ecosystems agree on the shape, the owner has directed that the pattern be shared, and the two places where they disagree (`jj` on `PAGER`, the exact `less` flag set) are both documented with reasons rather than being silent drift.

**Re-verify triggers.** (a) A later item registers an app-env-prefix parameter with a value other than `RSLB` → rename `RSLB_PAGER` to match. (b) R54 lands a config file → insert the config tier. (c) R60 declines a `--no-pager` global flag → the off switch reduces to `--no-input` plus the empty-value convention, which is still complete. (d) `clig.dev` changes its recommended `less` flags → revisit the default string.

##### Sources

- <https://raw.githubusercontent.com/git/git/v2.51.0/pager.c> (lines 65-73, 85-106, 109-130) and <https://raw.githubusercontent.com/git/git/v2.51.0/Makefile> (lines 300, 2287-2288) — 2026-09-10.
- <https://git-scm.com/docs/git> (`GIT_PAGER` entry) — 2026-09-10.
- <https://cli.github.com/manual/gh_help_environment> (`GH_PAGER`, `PAGER` in order of precedence) — 2026-09-10.
- <https://clig.dev/> (Output section, paging paragraph) — 2026-09-10.
- <https://raw.githubusercontent.com/sharkdp/bat/v0.26.1/src/pager.rs> (lines 43-69, 100-133) and `…/src/output.rs` (lines 105-152) — 2026-09-10.
- <https://raw.githubusercontent.com/dandavison/delta/0.19.2/src/env.rs> (lines 11, 41-47) and `…/src/utils/bat/output.rs` (lines 101-121, 174-223) — 2026-09-10.
- <https://raw.githubusercontent.com/jj-vcs/jj/v0.45.1/docs/config.md> (lines 885-926) and `…/cli/src/config/misc.toml` (line 39) — 2026-09-10.
- `man less` on this host, `less` 668 (POSIX regular expressions) — flags `-F`, `-R`, `-X`, `-K` — 2026-09-10.
- py at pin `b08bccfb`: `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/cli/output.py` (lines 56, 85-92, 177-186) and `…:docs/adr/0008-pager-for-long-text-output.md` — 2026-09-10.
- <https://gitlab.com/imp/pager-rs/-/raw/master/src/lib.rs> (lines 20-30, 73-75) — 2026-09-10.
- `docs/port/PARAMETERS.md`, `docs/port/COMMONALITY.md:288-289,328`, `docs/port/OWNER-REVIEW.md:105`, `docs/port/DIVERGENCE-ANALYSIS.md:202,303` in this repository — 2026-09-10.

#### Spawn-and-pipe invocation (pattern: `std::process::Command` + `Stdio::piped()`, `Drop`-time close-and-`wait`, fall-through to `io::stdout()`)

##### Landscape

Bin: **built-in / first-party toolchain** — the recommended mechanism is `std::process::Command` from the Rust standard library, stable since Rust 1.0 (<https://doc.rust-lang.org/stable/std/process/struct.Command.html>, 2026-09-10). The category is "how the program hands its bytes to the pager process and cleans up afterwards". The three bins:

| Bin | Candidate | Status here |
|---|---|---|
| Built-in / first-party toolchain | `std::process::Command` with `.stdin(Stdio::piped()).spawn()`, write, drop the pipe, `wait()` | **Recommended** |
| Established industry standard | the `pager` crate 0.16.1 — `fork()` + `dup2()` + `exec`, replacing the *parent* with the pager | Excluded (see below) |
| Up-and-comer | `minus` 5.7.2 — in-process async pager | Excluded as the primary path; viable as an optional fallback |
| Up-and-comer | `sapling-streampager` 0.12.0 — in-process pager, Meta's fork of `markbt/streampager` | Excluded as the primary path |

##### Principles and implementation

This member carries P2 and P3. P2 (non-interactive invariance) is structural rather than conditional: the pager is not a mode the renderer switches into, it is a *different `Write` implementation the renderer is handed*. When the result stream is not an interactive text stream, the renderer receives `io::stdout()` and no pager code executes at all — which is why A11 (no paging behaviour when used as a library) holds by construction rather than by a runtime check. This is the same shape as `bat`'s `OutputType` enum (`Pager(Child) | BuiltinPager | Stdout(io::Stdout)`, `src/output.rs:54-61`, v0.26.1) and `jj`'s `UiOutput` (`cli/src/ui.rs`, v0.45.1).

P3 (never lose output, never change the exit status) needs four specific behaviours, each with a named failure mode:

| Failure | Detection | Response |
|---|---|---|
| Pager command is unparsable (unbalanced quote) | `shell_words::split` returns `Err(ParseError)` | Write to `io::stdout()` instead; optionally one line on stderr |
| Pager binary does not exist (`less` absent — minimal container images, Windows) | `Command::spawn()` returns `Err(e)` with `e.kind() == io::ErrorKind::NotFound` | Write to `io::stdout()` instead. `jj` does exactly this and adds a hint (`cli/src/ui.rs:399-407`, v0.45.1) |
| User quits the pager before all output is written | `write` to the child's stdin returns `Err` with `ErrorKind::BrokenPipe` | Stop writing; exit `0` with no error envelope. This is not a new rule — R67 already fixed it: "a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope" (`docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes`) |
| `SIGINT` arrives while the pager owns the terminal | signal handler | The parent must **not** exit `130` and return the shell prompt while `less` is still drawing. `git` pushes a handler that finishes the pager, pops itself and re-raises (`pager.c:65-73`, v2.51.0); `bat` and `jj` instead pass `less -K` so the pager exits first (`src/output.rs:135`, v0.26.1; `cli/src/config/misc.toml:39`, v0.45.1). R67 owns the signal mechanism (`RSLB901` SIGINT → 130, `signal-hook`); this member states the ordering requirement |

The lifecycle detail that is easy to get wrong and that both reference implementations encode in `Drop`: the child's stdin handle must be **dropped before** `wait()`. `less` reads until EOF, and EOF on the pipe is what dropping the write end produces; calling `wait()` while still holding the handle deadlocks. `bat` (`impl Drop for OutputType`, `src/output.rs:206-215`) and `delta` (`src/utils/bat/output.rs:59`) both call `child.wait()` from `Drop`, taking the stdin handle out first.

**Where a different ecosystem needs a different design.** py buffers: it renders into a `rich` capture buffer, measures the buffer against `Console.size.height`, and only then either prints or pipes (`output.py:184-196`, pin `b08bccfb`). That is a reasonable shape in Python, where the renderer is a `Console` object that owns its own file handle and cannot easily be re-pointed at a subprocess mid-render. Rust's `dyn Write` seam makes streaming the natural shape, and streaming is strictly better on two axes — peak memory is a write buffer rather than the whole result, and the user sees the first screen before the command has finished producing the last row. This is the "justified ecosystem difference" this item reports: **the principle (page long interactive text output through the user's pager) is shared; the buffering strategy is not, and does not need to be.** It is also the mechanical consequence of `BASELINE-REVIEW: F284` recorded under `### Principles and implementation`, since dropping the height check is what removes the reason to buffer.

##### Dominant choice

**`std::process::Command` + `Stdio::piped()` is dominant among Rust CLIs that page**, unanimously across the three surveyed:

- `bat` v0.26.1, `src/output.rs:169-172`: `p.stdin(Stdio::piped()).spawn().map(OutputType::Pager).unwrap_or_else(|_| OutputType::stdout())` — the fallback is written into the same expression as the spawn.
- `delta` 0.19.2, `src/utils/bat/output.rs:146-147`: `.stdin(Stdio::piped()).spawn()`.
- `jj` v0.45.1, `cli/src/ui.rs:77-78`: `tracing::info!(?cmd, "spawning pager"); let mut child = cmd.stdin(Stdio::piped()).spawn()?;`

**Figures.** Crate figures are **`inapplicable`** for the recommended mechanism, because it is the Rust standard library: it has no crates.io entry, so `crate.recent_downloads`, `crate.downloads` and `/versions` have no subject; it has no independent GitHub repository, so `stargazers_count`, `archived` and `pushed_at` have no subject; `https://rustsec.org/packages/std.html` has no subject because `std` is not a crates.io package and RustSec indexes crates.io packages. **Maintenance state: `active`**, on the only applicable evidence — `std` ships with every six-week Rust stable release, the current one being 1.98.1 dated 2026-09-01 (`GET https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rustc] version`, 2026-09-10). **Adopters**: `bat` (60,398 stars), `delta` (32,138 stars) and `jj` (31,500 stars), each cited to a pinned source line above; all three are relevant references because all three are widely installed Rust CLIs that page ANSI-coloured text through an external pager, which is precisely this template's problem.

##### Qualified shortlist

Only one candidate is qualified, and that is the finding: **`std::process::Command`**, figures and adopters as above. There is no maintained Rust crate that wraps external-pager invocation in the spawn-and-pipe shape. This was checked rather than assumed — four crates.io searches (`pager`, `external+pager`, `paging+terminal`, `less+pipe+output`, `sort=downloads` / `sort=recent-downloads`, `per_page=12..20`, all 2026-09-10) return exactly three pager-related libraries (`pager`, `minus`, `sapling-streampager`), all three of which implement a *different* architecture. The ecosystem's answer to "is there a maintained pager-invocation crate?" is **no, and the three biggest consumers hand-roll roughly 40 lines of `std::process` instead.**

##### Excluded by gate

**`pager` 0.16.1 — excluded.** Gate results, taken before popularity:

| Gate | Result |
|---|---|
| 1. Licence compatible with `MIT OR Apache-2.0` | **pass** — `license = "Apache-2.0/MIT"` (`Cargo.toml`, <https://gitlab.com/imp/pager-rs/-/raw/master/Cargo.toml>, 2026-09-10) |
| 2. MSRV within stable minus 2 minors (1.96) | **not verifiable** — no `rust-version` declared (`GET https://crates.io/api/v1/crates/pager/versions`, `rust_version: null`, 2026-09-10); `edition = "2018"` |
| 3. No open RustSec advisory; `unsafe` posture | advisories: **pass** (`https://rustsec.org/packages/pager.html` → HTTP 404; its dependency `errno` also 404). `unsafe` posture: **fail on fit** — the crate's whole mechanism is `libc` `fork`/`dup2`/`exec` (`src/lib.rs:15-18`: "this forks the current process, connects child' stdout to parent's stdin, and then replaces the parent with the pager of choice"), depending on `libc = "0.2"` and `errno = "0.2"`. R06's policy governs first-party code only and Cargo compiles dependencies with `--cap-lints allow`, so this is not a policy violation — but a template whose stated posture is `unsafe_code = "forbid"` taking a process-replacing `fork`/`exec` dependency for a cosmetic feature is a poor trade |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **pass for those two, with no CI evidence** — POSIX-only by construction; **Windows: unsupported**, which the matrix permits. The `[badges]` table still references `travis-ci` (`Cargo.toml`), a service retired years ago, so there is no live build signal |
| 5. Default features and async-runtime coupling | **stated** — the only feature is `pedantic` (a clippy lint toggle), no default features beyond the implicit empty set; no async runtime coupling |
| 6. Binary-size and compile-time cost | **stated qualitatively** — small in itself, but pulls `libc` and `errno 0.2` (the current `errno` major is 0.3.x), adding an outdated leaf to the tree |

Figures for the record (`GET https://crates.io/api/v1/crates/pager` and `…/versions`, 2026-09-10): 114,359 downloads in 90 days (`crate.recent_downloads`); 838,897 all-time (`crate.downloads`); newest unyanked `0.16.1`, `2022-09-22T15:56:55.250446Z`. GitHub figures are **`inapplicable`** — the crate is hosted on GitLab (`repository: https://gitlab.com/imp/pager-rs.git`), so `GET https://api.github.com/repos/...` has no subject. The GitLab substitute (`GET https://gitlab.com/api/v4/projects/imp%2Fpager-rs`, unauthenticated, 2026-09-10): `star_count` 6, `last_activity_at` `2025-08-19T18:33:15.154Z`, `forks_count` 7, `created_at` `2016-08-04`; `open_issues_count` returned `null` and `archived` returned `null` for an unauthenticated request, so **the open-issue count and archived flag could not be verified**, and **issue responsiveness could not be measured at all**. **Maintenance state: `at-risk`** — the concrete signals the rubric demands are the dead `travis-ci` badge, the `errno 0.2` pin against a current `0.3.x` line, and a four-year gap since the last release, against continued nonzero use; not `dormant`, because there is no unpatched advisory, no reported broken build on current stable, and no maintainer notice.

**The decisive exclusion is architectural, not a gate.** Even had every gate passed, `pager` cannot express this item's decision: (a) it replaces the parent process, so there is nothing to fall back to (P3 fails); (b) it is a whole-process side effect, so the library crate could not be guaranteed pager-free (A11 fails); (c) `Pager::with_env("MY_PAGER")` *substitutes* the variable consulted instead of layering it above `PAGER` (`src/lib.rs:20-30`), so the two-tier chain of member 2 is unrepresentable; (d) its built-in fallback pager is `more`, not `less` (`src/lib.rs:17-19`), and `more` does not reliably pass ANSI colour, so A9 fails by default.

**`minus` 5.7.2 — excluded on fit.** Gates: (1) licence `MIT OR Apache-2.0` — **pass**; (2) MSRV — `rust_version: null`, `edition = "2024"`, so it requires at least Rust 1.85 and is **not verifiable** beyond that; (3) advisories — `https://rustsec.org/packages/minus.html` → HTTP 404, **pass**; `unsafe` posture — not audited for this report, and not audited because the candidate is excluded on fit before popularity or safety is weighed (**stated as unverified**, not asserted); (4) platforms — `crossterm` supports Linux, macOS and Windows, so **pass**, but no CI badge was checked; (5) features — default feature set is empty; the optional features are `search` (`regex`), `static_output`, `dynamic_output`, `clipboard` (`arboard`); **no async runtime is required**, though the crate's own examples use `tokio` as a dev-dependency; (6) cost — the heaviest of the three, pulling `crossterm ^0.29`, `textwrap ~0.16`, `thiserror ^2`, `crossbeam-channel ^0.5` and `parking_lot 0.12.1` (`Cargo.toml`, `minus` 5.7.2, 2026-09-10). Figures: 436,903 downloads in 90 days, 1,592,326 all-time (`GET https://crates.io/api/v1/crates/minus`, 2026-09-10); newest unyanked `5.7.2`, `2026-07-15T06:58:43.195787Z` (`…/versions`); 372 stars, `archived: false`, `pushed_at` `2026-08-21T09:01:02Z` (`GET https://api.github.com/repos/AMythicDev/minus`, 2026-09-10); 10 open issues (`GET https://api.github.com/search/issues?q=repo:AMythicDev/minus+is:issue+is:open`, `total_count`, 2026-09-10); issue responsiveness median **70.87 days** over the 5 answered of the 9 issues returned, 4 unanswered (per-issue: #165 0.00 d, #142 0.36 d, #156 70.87 d, #147 405.43 d, #145 648.71 d; #150, #148, #146, #143 unanswered — `GET .../issues?state=all&sort=created&direction=desc&per_page=30` plus each issue's comments, 2026-09-10). **Maintenance state: `active`** — releases and pushes within the last two months, and the long tail of stale issues is a responsiveness weakness rather than an `at-risk` signal. Adopter: `bat`, which declares `minus = { version = "5.6", optional = true }` inside its `paging` feature (`Cargo.toml:36,55`, v0.26.1) and uses it only for `PAGER=builtin`. **Exclusion reason:** an in-process pager never consults the user's configured pager, so it contradicts P1 at the root. It remains the right *fallback* for a platform with no `less`, and that is exactly how `bat` and `jj` use it.

**`sapling-streampager` 0.12.0 — excluded on fit**, same reason as `minus`, plus a provenance qualification. Figures: 1,126,040 downloads in 90 days, 2,910,416 all-time (`GET https://crates.io/api/v1/crates/sapling-streampager`, 2026-09-10); newest unyanked `0.12.0`, `2026-01-15T18:58:13.235965Z`, `license: "MIT"`, `edition: "2024"`, `rust_version: null` (`…/versions`). Gate 1: MIT is compatible with a `MIT OR Apache-2.0` template (a permissive dependency imposes no obligation that either arm of the dual licence violates), so **pass** — noted because it is the one candidate here that is not itself dual-licensed. Gate 3: `https://rustsec.org/packages/sapling-streampager.html` → HTTP 404, **pass**. GitHub figures are **partly `inapplicable`**: the crate declares `repository: null` on crates.io, so there is no repository to query for *this published crate*; the code is published out of Meta's Sapling monorepo (`facebook/sapling`: 7,010 stars, `archived: false`, `pushed_at` `2026-09-10T14:32:08Z`, licence `GPL-2.0` for the monorepo as a whole — `GET https://api.github.com/repos/facebook/sapling`, 2026-09-10), and the original upstream `markbt/streampager` (65 stars, `archived: false`, `pushed_at` `2023-03-12T22:20:20Z`, licence MIT, 10 open issues — `GET https://api.github.com/repos/markbt/streampager` and the corresponding search endpoint, 2026-09-10) has not been pushed in over three years. Issue responsiveness for the *published crate* could not be measured, because no issue tracker corresponds to it. **Maintenance state: `stable-quiet`** for the published crate (regular releases out of an extremely active monorepo, no independent tracker), with the original upstream repository effectively `dormant` by the maintainer's own inactivity — recorded as two separate observations rather than merged into one verdict. Adopter: `jj`, as its `:builtin` pager (`docs/config.md:922-926`, v0.45.1).

##### Up-and-comers

`minus` and `sapling-streampager` are the up-and-comers in this category and are covered in full under `##### Excluded by gate` rather than repeated here; both are excluded as the *primary* mechanism on principle P1 and both are the correct shape for an optional built-in fallback. The one worth watching is `minus`, because `bat` already ships it behind a feature flag, which means a future template that wants a `RSLB_PAGER=builtin` escape hatch has a tested integration to copy (`bat` `Cargo.toml:36`, `src/output.rs:17-42`, v0.26.1). Nothing newer than these two exists: the crates.io searches described above surface no other entrant.

##### Fit for this template

Fits, and it is the only candidate that fits the template's *shape* rather than just its problem.

- **CLI + library + web service.** The mechanism is a choice of `Box<dyn Write>` made at the CLI's composition root. The library crate never sees it, satisfying both A11 and R67's already-settled constraint that the library crate "must write to no process stream or file" (`docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes`). Neither of the excluded architectures can make that guarantee: `pager` mutates the process, and an in-process pager would have to be linked wherever the renderer lives.
- **Zero new dependencies.** The only crate this member adds is the tokenizer already counted under member 1.
- **`target-os-matrix = ubuntu-latest, macos-latest`.** `less` is present on both: verified directly on this macOS host (`command -v less` → `/usr/bin/less`; `less --version` → `less 668 (POSIX regular expressions)`, 2026-09-10), and packaged on Ubuntu (<https://packages.ubuntu.com/noble/less>, `less 590-2ubuntu2.1`, 2026-09-10). **Not verified:** the GitHub Actions runner-image READMEs (`images/macos/macos-15-Readme.md`, `images/ubuntu/Ubuntu2404-Readme.md` in `actions/runner-images`, retrieved 2026-09-10) list only notable installed tooling and do **not** mention `less` either way, so the claim "`less` is present on the runners" rests on it being a base-system package on both platforms, not on a runner manifest. This matters little, because the design's answer to a missing `less` is the same as its answer to any other spawn failure: print normally.
- **Windows and minimal images (the LOW question).** No `#[cfg]` gating and no "POSIX-only" documentation caveat are needed. The code is portable `std::process`; on a machine with no `less` — Windows, `debian:slim`, `alpine` — `spawn()` returns `ErrorKind::NotFound` and the output prints normally, which is the correct behaviour rather than a degraded one. Conditional compilation would make the Windows path *less* tested, not more correct. This is also the answer for the container image R51 will build.

##### Recommendation

An enum-shaped output sink in the CLI crate, chosen once at the composition root:

- `PagedOut(Child)` when the result stream is an interactive terminal, the format is the human text format, paging is enabled, resolution yielded a command, and `spawn()` succeeded;
- `PlainOut(io::Stdout)` in every other case, including every failure of the above.

`PagedOut`'s `Write` impl writes to `child.stdin`; its `Drop` takes the stdin handle (closing the pipe), then calls `child.wait()`. A `BrokenPipe` from a write is not an error — it is A10's silent exit `0`, per R67.

**Requirement on R67 (one line, stated once so a synthesizer can lift it):** while a pager child is alive, the `SIGINT` path must finish the pager before the process returns its `ExitCode` — it must not exit `130` and hand the shell prompt back while `less` still owns the terminal. R67 already owns the mechanism (`RSLB901` SIGINT → 130, `signal-hook`); this is an ordering constraint on it, not a change to any value it fixed, so no `CONFLICT:` is raised. **Fallback if R67 declines the constraint:** change the default pager command to `less -FRXK`, `jj`'s exact default (`cli/src/config/misc.toml:39`, v0.45.1), whose `-K` / `--quit-on-intr` makes `less` exit on `^C` by itself. That removes the dependency on R67 entirely, at the cost of one flag of drift from py's `less -FRX`.

##### Ranked runner-up

**`bat`'s exact shape, including `grep_cli::resolve_binary` and `less`-version detection** (`src/output.rs:105`, `140-152`, v0.26.1). It is the same architecture with two extra behaviours: resolving the pager binary on `PATH` before spawning, and adding `--no-init` when the installed `less` predates version 530. Ranked second because both extras are unnecessary here — `Command::new` already searches `PATH` and its `spawn()` error is the fallback trigger, and the recommended default `less -FRX` already passes `--no-init` under its short name (`-X` *is* `--no-init`, `less(1)`). Adopt it only if the template later needs to classify the pager binary by name, which is the prerequisite `bat` needs for its argument-rewriting runner-up in member 2.

**The buffered variant, costed.** If the owner rejects `BASELINE-REVIEW: F284` and keeps py's terminal-height gate, the sink buffers the rendered result, compares its line count against the terminal height, and pages only above that threshold — which makes `terminal_size` a fourth member. Its figures are recorded here so that choice needs no new research (all `GET https://crates.io/api/v1/crates/terminal_size`, `…/versions`, `GET https://api.github.com/repos/eminence/terminal-size` and the open-issue search endpoint, 2026-09-10):

| Figure | Value |
|---|---|
| 90-day downloads | 37,832,505 (`crate.recent_downloads`) |
| All-time downloads | 201,468,090 (`crate.downloads`) |
| Last release | `0.4.4`, `2026-03-23T16:39:14.510986Z` (newest with `yanked: false`) |
| Stars / archived / last push | 119 / `false` / `2026-09-01T03:17:23Z` |
| Open issues | 3 (`search/issues?q=repo:eminence/terminal-size+is:issue+is:open`, `total_count`) |
| Issue responsiveness | median **0.79 days** over the 3 answered of the 5 issues returned; 2 unanswered (#76 0.79 d, #65 0.72 d, #59 1.01 d; #73, #72 unanswered) |
| Advisories | none — `https://rustsec.org/packages/terminal_size.html` → HTTP 404 |
| Adopters | `clap_builder` 4.6.6, `cargo-nextest` 0.9.143, `miette` 7.6.0, `starship` 1.26.0, `eza` 0.23.5 (reverse-dependencies page, 704 total) |

Gates: (1) licence `MIT OR Apache-2.0` — **pass**; (2) `rust-version = "1.71"` declared, well under the 1.96 floor — **pass**, and it is the one candidate in this report that satisfies gate 2's declaration clause outright; (3) no advisory — **pass**; `unsafe` posture — it wraps platform APIs, so `unsafe` appears once in `src/unix.rs` and five times in `src/windows.rs` and not at all in `src/lib.rs` (counted at `master`, 2026-09-10), which R06 permits in a dependency; (4) platforms — `rustix` on unix, `windows-sys` on windows, with a `docs.rs` target list covering aarch64/x86_64 macOS, Linux and Windows (`Cargo.toml`) — **pass**; (5) default features: none declared; no async coupling; (6) cost — two small platform shims, negligible. **Maintenance state: `active`** (released 2026-03-23, pushed 2026-09-01, 0.79-day median first response). It is a perfectly good crate; this report excludes it because the *design* does not need it, not because of anything in these figures.

Second runner-up, for a different situation: **`jj`'s dual path** — external pager by default, in-process `streampager` behind `ui.pager = ":builtin"` (`cli/src/ui.rs:83-114`, v0.45.1). Adopt if the template ever needs to page on a platform with no external pager at all.

##### Tradeoffs

| Decision | Gains | Costs |
|---|---|---|
| Spawn-and-pipe rather than self-redirect | Parent keeps its identity, exit code and error path; fallback is possible; library crate is untouched | One extra process and a pipe write, versus `git`'s in-place redirect |
| Stream rather than buffer (py buffers) | Peak memory is a write buffer, not the whole result; first screen appears before the last row is produced | Once bytes are in the pipe they cannot be re-printed, so a pager that dies *mid-stream* loses the remainder. Mitigation: the only realistic failure is at `spawn()`, which is still recoverable; `bat`, `delta` and `jj` all accept this |
| No `terminal_size` height check | One fewer dependency; no full buffering; `less -F` already provides quit-if-one-screen | A user whose `PAGER` is `more` sees short results paged — identical to `git`'s behaviour, and their own choice |
| No `grep-cli` binary resolution | One fewer dependency | The "pager not found" error surfaces at `spawn()` rather than one step earlier; the user-visible behaviour is the same |
| Portable code, no `#[cfg(unix)]` | Windows and minimal images degrade to plain output automatically; no untested platform-specific branch | The template makes no *promise* of paging on Windows; documented as best-effort |
| `Drop`-time `wait()` | Terminal is never left to a detached pager; mirrors `bat` and `delta` | Requires taking the stdin handle before `wait()`, or the process deadlocks — a real hazard, and the reason both references encode it in `Drop` rather than at call sites |

##### Parameters

`owns` — none.
`assumes rust-edition = 2024` — satisfied; `std::process` is edition-independent.
`assumes msrv-policy = stable minus 2 minors` — satisfied with room to spare: `Command`, `Stdio::piped`, `Child::wait` and `io::ErrorKind::BrokenPipe` are all stable since Rust 1.0, far below the current 1.96 floor (floor computed from `[pkg.rustc] version = "1.98.1 (48a229cea 2026-09-01)"`, `GET https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-10).
`assumes license = MIT OR Apache-2.0` — satisfied; no third-party code is added by this member.
`assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied; see gate 4 below.
Related, not registry-consumed: R65 (`color-enablement-chain`) owns F290's TTY-detection mechanism, and this member's gate reuses it rather than implementing a second check — with one requirement stated explicitly, since it is easy to get wrong: **colour must be resolved against the real stdout, before the pager child exists.** The pipe to the pager is not a terminal, so any auto-detecting colour wrapper applied to the *pipe* would strip the ANSI sequences that `less -R` exists to render, breaking A9. If R65 lands `anstream`, the `AutoStream` belongs on the process's stdout for the detection decision, and the bytes written into the pager must be the already-styled ones. R67 (`error-and-exit-code-contract`) owns the `BrokenPipe`-to-exit-0 rule and the SIGINT handler this member depends on; both already have the values this member needs, so nothing must change. R66 owns which formats exist; this member reads only "is the active format the human text one".
No `CONFLICT:` lines.

##### Migration implications

`crates/rslb-cli/src/pager.rs` gains the `PagedOut`/`PlainOut` sink and its `Write` and `Drop` impls (roughly 40 lines). The CLI's renderer changes signature to accept `&mut dyn Write` instead of writing to stdout directly — the single structural change this item causes, and the one worth doing early because retrofitting it later touches every command. The error boundary in `main` gains no new arm: `BrokenPipe` on the result stream is already R67's exit-0 path. No change to `crates/rslb-core`, no change to any web crate, no change to `Cargo.toml` beyond member 1's one line.

##### Validation strategy

Proposed; see `### Validation strategy` at the report level for the full command list and for the separation between proposed checks and the checks actually executed for this report.

##### Confidence & re-verify trigger

**Gate-by-gate for the recommended mechanism (`std::process::Command`), applied before popularity:**

1. **Licence compatible with `MIT OR Apache-2.0`** — **pass.** The Rust standard library is distributed under `MIT OR Apache-2.0`, and in any case adds no third-party licensed code to the dependency tree.
2. **MSRV within stable minus 2 minors (1.96)** — **pass.** Every API used is stable since Rust 1.0. The template declares `rust-version = "1.96"` in its own `Cargo.toml` and tests it in CI, satisfying the policy's declaration and testing clauses at the level the policy binds.
3. **No open RustSec advisory; `unsafe` posture** — advisories: **`inapplicable`** with the reason stated — RustSec indexes crates.io packages, and `std` is not one, so `https://rustsec.org/packages/<name>.html` has no subject. `unsafe` posture: the *template's* code for this member is entirely safe Rust and compiles under R06's `unsafe_code = "forbid"` workspace lint; `std` itself contains `unsafe` internally, which R06 explicitly places outside the policy's scope.
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — **pass**, with the runner qualification recorded above: `std::process::Command` compiles and runs on both, and `less` is a base-system package on both (verified directly on macOS here, `less` 668; packaged on Ubuntu noble). The runner-image READMEs do not list `less`, so that specific confirmation is **unverified**. Windows: the code compiles and runs; whether a pager exists there is the user's business, and the `NotFound` fallback covers its absence. Not required by the matrix.
5. **Default features and any async-runtime coupling** — **stated.** No features (standard library). **No async runtime coupling**: the write-and-`wait` sequence is synchronous and blocking, which is correct for a CLI. Should R05 (`sync-async-execution-model`) put the CLI on an async runtime, the pager write must run on a blocking-safe context (`spawn_blocking` under `tokio`) because `child.wait()` blocks the thread; that is a note for R05's consumer, not a conflict with any registered value.
6. **Binary-size and compile-time cost** — **stated qualitatively.** Zero measurable compile-time cost (`std` is precompiled and already linked) and a few kilobytes of monomorphized `Write`/`Drop` code. No measurement was taken and none is claimed: there is no Rust template to measure.

**Confidence: high.** Three independent, heavily-installed Rust CLIs implement this member the same way, down to the `Drop`-time `wait()`; the standard-library API involved has been stable for a decade; and the two excluded architectures are excluded on reasons that are structural rather than on a close reading of figures.

**Re-verify triggers.** (a) R65 selects a colour mechanism that wraps stdout in a way that would strip ANSI on the pager pipe → re-check A9 before P03 implements. (b) R05 puts the CLI on an async runtime → re-check the blocking `wait()`. (c) A maintained pager-invocation crate appears on crates.io with adopters among `bat`, `delta` or `jj` → re-open the shortlist. (d) `bat`, `delta` or `jj` moves away from spawn-and-pipe → re-open. Routine re-check at P03 start.

##### Sources

- <https://doc.rust-lang.org/stable/std/process/struct.Command.html> — 2026-09-10.
- <https://raw.githubusercontent.com/sharkdp/bat/v0.26.1/src/output.rs> (lines 17-42, 54-61, 81-173, 206-215) — 2026-09-10.
- <https://raw.githubusercontent.com/dandavison/delta/0.19.2/src/utils/bat/output.rs> (lines 7, 59, 101-147, 174-223) — 2026-09-10.
- <https://raw.githubusercontent.com/jj-vcs/jj/v0.45.1/cli/src/ui.rs> (lines 30, 48, 62, 77-78, 83-114, 123-129, 331-407) — 2026-09-10.
- <https://raw.githubusercontent.com/git/git/v2.51.0/pager.c> (lines 65-73) — 2026-09-10.
- `GET https://crates.io/api/v1/crates/pager`, `…/versions`; `GET https://gitlab.com/api/v4/projects/imp%2Fpager-rs`; <https://gitlab.com/imp/pager-rs/-/raw/master/src/lib.rs>, `…/Cargo.toml`; <https://rustsec.org/packages/pager.html> (404); <https://rustsec.org/packages/errno.html> (404) — 2026-09-10.
- `GET https://crates.io/api/v1/crates/minus`, `…/versions`; `GET https://api.github.com/repos/AMythicDev/minus` and its issues, comments and open-issue search endpoints; <https://raw.githubusercontent.com/AMythicDev/minus/main/Cargo.toml>; <https://rustsec.org/packages/minus.html> (404) — 2026-09-10.
- `GET https://crates.io/api/v1/crates/sapling-streampager`, `…/versions`; `GET https://api.github.com/repos/facebook/sapling`; `GET https://api.github.com/repos/markbt/streampager` and its open-issue search endpoint; <https://rustsec.org/packages/sapling-streampager.html> (404) — 2026-09-10.
- `GET https://crates.io/api/v1/crates/terminal_size`, `…/versions`, `…/reverse_dependencies?per_page=20`; `GET https://api.github.com/repos/eminence/terminal-size`, its issues, comments and open-issue search endpoints; <https://raw.githubusercontent.com/eminence/terminal-size/master/Cargo.toml>, `…/src/lib.rs`, `…/src/unix.rs`, `…/src/windows.rs` (`unsafe` occurrence counts); <https://rustsec.org/packages/terminal_size.html> (404) — 2026-09-10.
- `GET https://crates.io/api/v1/crates?q=pager&per_page=20&sort=downloads` and the three sibling searches — 2026-09-10.
- `GET https://static.rust-lang.org/dist/channel-rust-stable.toml` — 2026-09-10.
- `command -v less` and `less --version` on this macOS host; <https://packages.ubuntu.com/noble/less>; `actions/runner-images` READMEs `images/macos/macos-15-Readme.md` and `images/ubuntu/Ubuntu2404-Readme.md` (no `less` entry found) — 2026-09-10.
- py at pin `b08bccfb`: `output.py` (lines 169-200) — 2026-09-10.
- `research/topics/06-unsafe-code-policy/DECISION.md` in this repository — 2026-09-10.

### Compatibility

The three members are not merely compatible — **two production binaries already ship all three together**, which is the strongest form of proof this template's `### Compatibility` field can carry.

**Shared adopter 1 — `bat` v0.26.1.** Its `Cargo.toml` declares the paging capability as a single feature composed of exactly these parts: `paging = [ "shell-words", "grep-cli", "minus" ]` (line 36), with `shell-words = { version = "1.1.0", optional = true }` (line 54). The resolution policy lives in `src/pager.rs` (`get_pager`, the `--pager`/config → `BAT_PAGER` → `PAGER` → `less` chain) and calls `shell_words::split(cmd)` on the resolved string; the invocation lives in `src/output.rs` and takes the argv from that same call into `Command::new(...).args(args).stdin(Stdio::piped()).spawn()`, with `child.wait()` in `Drop`. Member 1 feeds member 2 feeds member 3, in one shipped binary, on Linux, macOS and Windows. (Retrieved 2026-09-10 at tag `v0.26.1`.)

**Shared adopter 2 — `delta` 0.19.2.** Independent codebase, same three parts: `shell-words = "1.0.0"` (`Cargo.toml:51`); the `DELTA_PAGER` → `BAT_PAGER` → `PAGER` → `less` chain in `src/env.rs:41-47`; `shell_words::split` at `src/utils/bat/output.rs:120` handing argv to `.stdin(Stdio::piped()).spawn()` at `:146-147`, with `command.wait()` in `Drop` at `:59`. (Retrieved 2026-09-10 at tag `0.19.2`.)

**Version matrix.** The one crate member has no transitive dependencies, so there is no version-resolution surface to matrix. What matters instead is the compiler and OS matrix, and it is satisfied by construction:

| Leg | `shell-words` 1.1.1 | resolution policy | spawn-and-pipe |
|---|---|---|---|
| Rust 1.96 (MSRV floor, from stable 1.98.1 minus 2 minors) | no `rust-version` declared; no post-1.46 construct in ~100 lines of dependency-free code; verified by the template's own MSRV CI job | `std::env::var`, stable since 1.0 | `std::process`, stable since 1.0 |
| Rust stable (1.98.1, 2026-09-01) | same | same | same |
| `ubuntu-latest` | platform-independent | platform-independent | `less` is an Ubuntu package (`less 590-2ubuntu2.1`, noble) |
| `macos-latest` | platform-independent | platform-independent | `/usr/bin/less`, `less 668`, verified on this host |
| `windows-latest` (not required by the matrix) | platform-independent | platform-independent | compiles; degrades to plain output when no pager exists |

**Third-party corroboration that the pair composes outside pagers**: `cargo-nextest` (`cargo-nextest/Cargo.toml:41`) uses `shell-words` alongside `std::process` spawning for its own external-command handling, and `terminal_size` and `shell-words` appear together in `cargo-nextest`'s tree — evidence that these standard-library-plus-tokenizer combinations are unremarkable in mainstream Rust CLIs (`GET https://crates.io/api/v1/crates/<name>/reverse_dependencies`, 2026-09-10).

### Parameters

**Owned.** None. R64's `## Couplings` block records an empty `owns:` field, and this answer registers no new row in `docs/port/PARAMETERS.md`. The concrete values fixed by this decision — the app-specific variable name `RSLB_PAGER`, the default command `less -FRX`, the empty-and-`cat` disable convention, and the `LESS=FRX`/`LV=-c` injection — belong in R64's `DECISION.md`, because no other item consumes them.

**Assumed (the four fixed owner parameters, `docs/port/PARAMETERS.md`, owner-decided 2026-09-02).**

- `assumes rust-edition = 2024` — satisfied by all three members; nothing here is edition-sensitive.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — the concrete floor today is **1.96**, computed from `[pkg.rustc] version = "1.98.1 (48a229cea 2026-09-01)"` (`GET https://static.rust-lang.org/dist/channel-rust-stable.toml`, 2026-09-10). Members 2 and 3 use only Rust-1.0-era standard-library APIs. Member 1's crate declares no `rust-version`; the policy's declaration clause binds this template's crates, and the dependency's floor is verified empirically by the MSRV CI job. Recorded as a qualification, not a pass by assertion.
- `assumes license = MIT OR Apache-2.0` — satisfied; the only added dependency is dual MIT/Apache-2.0.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — satisfied; both members run on both, and the design degrades correctly where no pager exists.

**Assumed but unregistered.** `assumes app-env-prefix = RSLB`. No parameter owns the application's environment-variable prefix: `docs/port/PARAMETERS.md` contains no `short-name`, `env-prefix` or `app-short` row (grepped 2026-09-10), and the nearest ledger row, F324 ("typed env settings with an app-derived env-var prefix", R77, `docs/port/COMMONALITY.md:328`), is scoped to the web tier's settings object. `RSLB` is derived from the `RSLB` error-code prefix R67 fixed (`docs/port/PARAMETERS.md`, `error-taxonomy-exit-codes`). If a later item registers a prefix parameter, this item follows it with a rename and no design change.

**Related, not registry-consumed** (stated because these are the couplings that decide whether the design works, even though none is a registered dependency): R65 supplies the "is this stream a terminal" check that this item's paging gate reuses, and must resolve colour against the real stdout rather than the pager pipe; R66 supplies "is the active format the human text format"; R67 already supplies the `BrokenPipe`-on-result-stream → exit `0` rule and the SIGINT handling this item depends on; R60 owns registering the `--no-pager` global flag; R54 owns whether a config-file tier exists to slot between the app variable and `PAGER`; R05 determines whether the CLI runs on an async runtime, in which case the blocking `child.wait()` needs a blocking-safe context; R51's container image is the place where a missing `less` will actually be observed. None of these requires a consumed parameter to take a different value than it currently has.

**No `CONFLICT:` lines.** Every parameter this recommendation depends on already holds the value the recommendation needs.

### Migration implications

The template does not exist yet, so "migration" means the file-level shape P03 builds.

| File | Change |
|---|---|
| `crates/rslb-cli/Cargo.toml` | one dependency line: `shell-words = "1.1"`. Nothing added to the library or web crates |
| `Cargo.lock` | one new package entry, no transitive additions |
| `crates/rslb-cli/src/pager.rs` (new, ~60 lines) | `resolve_pager(paging_enabled) -> Option<String>` implementing member 2's chain; `spawn_pager(&str) -> Option<Child>` implementing member 1's tokenization and member 3's spawn plus the `LESS`/`LV` injection; the `PagedOut`/`PlainOut` sink with its `Write` and `Drop` impls |
| `crates/rslb-cli/src/output.rs` (or wherever R66 puts the renderer) | the renderer takes `&mut dyn Write` instead of writing to stdout directly, and the composition root picks the sink. **This is the one structural change**, and it should be made when the renderer is first written rather than retrofitted, because retrofitting touches every command |
| `crates/rslb-cli/src/cli.rs` (R60's parser) | a global `--no-pager` flag alongside `--no-input` |
| `crates/rslb-cli/src/main.rs` | no new error arm — `BrokenPipe` on the result stream is already R67's exit-`0` path. The only requirement is that the sink is dropped (so the pager is waited on) before the process returns its `ExitCode` |
| generated docs (`README.md` / `EXAMPLECLI.md` equivalent) | a "Paging" subsection documenting `RSLB_PAGER`, `PAGER`, the `less -FRX` default, `--no-pager`, and that a set-but-empty value disables paging |
| `crates/rslb-cli/tests/` | the A1–A11 integration tests described below |
| `crates/rslb-core` (library), any web crate | **no change** — this is the property A11 asserts |

Nothing in this item changes an existing decision. It reads R65's TTY check, R66's format flag, R67's error boundary and R60's parser, and adds to none of them.

### Validation strategy

**Executed for this report** (these are the only checks actually run; everything under "Proposed" was not run, because no Rust template exists and this item must not scaffold one):

| Command / endpoint | Result | Purpose |
|---|---|---|
| `command -v less` on this macOS host | `/usr/bin/less` | gate 4: a pager exists on macOS without installation |
| `less --version` | `less 668 (POSIX regular expressions)` | pins the flag semantics cited |
| `man less` → `-F`, `-R`, `-X`, `-K` entries | `-F or --quit-if-one-screen`; `-R or --RAW-CONTROL-CHARS`; **`-X or --no-init`**; `-K or --quit-on-intr` | establishes that the recommended default already carries `--no-init`, so no `less`-version detection is needed |
| `man less` → ENVIRONMENT VARIABLES | `LESS   Options which are passed to less automatically.` | establishes that git's `LESS=FRX` injection mechanism works, i.e. that a flag-less `less` picks the options up |
| `https://rustsec.org/packages/time.html` | HTTP 200, lists RUSTSEC-2020-0071 and RUSTSEC-2026-0009 | control proving that the 404s recorded for the five candidate crates mean "no advisories", not "endpoint broken" |
| `curl https://static.rust-lang.org/dist/channel-rust-stable.toml` | `[pkg.rustc] version = "1.98.1 (48a229cea 2026-09-01)"` | fixes the MSRV floor at 1.96 rather than guessing it |
| the crates.io, GitHub, GitLab and raw-source endpoints listed in `### Sources` | as recorded per figure | every number in this report |

**Endpoints that failed or returned less than needed** (recorded rather than worked around): unauthenticated `GET https://api.github.com/...` returned `core.remaining: 0`, so every GitHub figure was taken through `gh api` with the user's token instead; `GET https://gitlab.com/api/v4/projects/imp%2Fpager-rs` returned `open_issues_count: null` and `archived: null`, so the `pager` crate's open-issue count and archived flag are **unverified** and its issue responsiveness was **not measurable**; the `actions/runner-images` READMEs for `macos-15` and `Ubuntu2404` contain no `less` entry, so runner presence of `less` is **unverified** (it rests on `less` being a base-system package on both platforms).

**Proposed** — the acceptance check for P03, mapping one-to-one onto A1–A11 in `### Principles and implementation`. All of it is `assert_cmd` + `predicates` integration tests in `crates/rslb-cli/tests/pager.rs` plus two shell probes, and none of it has been run:

```bash
# A1 / A2 / A3 — non-interactive invariance (P2). No pager, byte-identical output.
cargo run -q -p rslb-cli -- projects list | cat > /tmp/piped.txt
cargo run -q -p rslb-cli -- --no-pager projects list > /tmp/nopager.txt
cmp /tmp/piped.txt /tmp/nopager.txt          # expect: identical, exit 0
cargo run -q -p rslb-cli -- --format json projects list | jq -e . >/dev/null

# A4 / A5 / A6 / A7 — resolution precedence (P1), asserted on the launched argv.
# The stub is a script on PATH that appends "$0 $*" and its stdin to $STUB_LOG.
RSLB_PAGER=stub-pager PAGER=other-pager cargo run -q -p rslb-cli -- projects list
grep -q '^stub-pager' "$STUB_LOG"            # expect: RSLB_PAGER won
PAGER=stub-pager cargo run -q -p rslb-cli -- projects list
grep -q '^stub-pager' "$STUB_LOG"            # expect: PAGER used when RSLB_PAGER unset
RSLB_PAGER= cargo run -q -p rslb-cli -- projects list
test ! -s "$STUB_LOG"                        # expect: empty value disables paging

# A8 — never lose output, never change the exit code (P3).
RSLB_PAGER=/nonexistent/binary cargo run -q -p rslb-cli -- projects list > /tmp/fallback.txt
echo "exit=$?"                               # expect: 0
cmp /tmp/fallback.txt /tmp/nopager.txt       # expect: identical

# A9 — ANSI survives the pipe. The stub records its stdin verbatim.
RSLB_PAGER=stub-pager cargo run -q -p rslb-cli -- --color always projects list
grep -q $'\033\[' "$STUB_LOG"                # expect: SGR sequences present in what the pager received

# A10 — user quits early: the stub exits immediately, closing the pipe.
RSLB_PAGER=stub-pager-exits-now cargo run -q -p rslb-cli -- projects list
echo "exit=$?"                               # expect: 0, no error envelope on stderr

# A11 — the library never links or runs paging.
cargo tree -p rslb-core | grep -q shell-words && echo FAIL || echo PASS
cargo tree -p rslb-cli -i shell-words        # expect: present, with no children
```

Two notes on why the checks are shaped this way. First, every precedence assertion goes through a **stub pager script** rather than a real `less`, because `assert_cmd` gives the child no TTY and a real `less` would simply behave as `cat`; asserting on the stub's recorded argv is the only way to observe which command was *chosen*. Second, A1's `cmp` against the `--no-pager` run is the real test of P2 — comparing against a hand-written expectation would let a paging-only formatting change slip through unnoticed.

### Confidence & re-verify trigger

**Overall confidence: high for the architecture and the resolution policy; medium for one dependency's maintenance outlook; medium for the two BASELINE-REVIEW proposals.**

*High for the architecture (member 3) and the policy (member 2).* Three independent Rust CLIs with a combined 123,000+ GitHub stars implement the same spawn-and-pipe mechanism down to the `Drop`-time `wait()`, and five tools across three ecosystems agree on the resolution chain. The `git` reference implementation was read at a pinned tag rather than paraphrased. The one dissenter on the chain (`jj` ignoring `PAGER`) documents both its reason and the user-side workaround.

*Medium for `shell-words`' maintenance outlook (member 1).* The figures are honest: 46.91-day median first maintainer response over 4 answered of 8 issues, 4 unanswered, no CI in the repository, and releases in 2020, 2022 and 2025. The mitigations are that the crate is 100 lines with zero dependencies and `#![forbid(unsafe_code)]`, that a fully qualified runner-up (`shlex` 2.0.1) exists with a one-line migration, and that vendoring is trivial if both fail.

*Medium for the two BASELINE-REVIEW findings.* `BASELINE-REVIEW: F285` (the `PAGER=less` colour defect) is a **verified code-reading finding** against py at pin `b08bccfb` — `output.py:88` returns the user's bare `"less"` and `:194-196` runs it with no flags — and the fix is `git`'s own mechanism, so confidence in the finding is high; it is marked medium only because it proposes a change to a second repository, which is a follow-on project's decision to make, not this item's. `BASELINE-REVIEW: F284` (dropping the terminal-height gate) is a design judgement supported by four reference implementations and a `less(1)` flag, but it does trade a small behaviour change (`PAGER=more` now pages short output) for a simpler, streaming design; a reviewer could reasonably keep py's check, in which case `terminal_size` 0.4.4 becomes a fourth member and the sink buffers before deciding. That alternative is fully costed under member 3's `##### Ranked runner-up`, including `terminal_size` 0.4.4's complete figure set and gate results, so the reviewer can take it without new research.

**Re-verify triggers, consolidated.**

| Trigger | Action |
|---|---|
| R65 lands a colour mechanism that auto-detects on the *written* stream | re-check A9 before P03 implements: the pager pipe is not a TTY, so an auto-stream on the pipe would strip the colour `less -R` exists to show |
| R05 puts the CLI on an async runtime | the blocking `child.wait()` needs a blocking-safe context |
| R54 lands a config file | insert a config tier between `RSLB_PAGER` and `PAGER`, matching `git`'s `core.pager` and `bat`'s config tier |
| R60 declines a global `--no-pager` | the off switch reduces to `--no-input` plus the empty-value convention; still complete, but document it more prominently |
| A later item registers an app env-var prefix ≠ `RSLB` | rename `RSLB_PAGER`; no design change |
| `shell-words` gains an advisory, is archived, or lets a correctness report sit 90 days | switch to `shlex = "2.0"` (one call site) |
| `bat`, `delta` or `jj` abandons spawn-and-pipe, or a maintained pager-invocation crate gains one of them as an adopter | re-open member 3's shortlist |
| The owner rejects `BASELINE-REVIEW: F284` | add `terminal_size = "0.4"` as a fourth member and buffer before deciding; every other member is unaffected |
| Routine | re-check all figures at P03 start and at each MSRV floor bump |

### Sources

**Pinned source repositories, read through their pin.**
- py-launch-blueprint at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` (committed 2026-09-01 23:07:15 +0000), read as `git -C ~/c/py-launch-blueprint show b08bccfb:<path>`: `src/py_launch_blueprint/cli/output.py` (module docstring citing clig.dev; `DEFAULT_PAGER = "less -FRX"` at :56; `_pager_argv` at :63-79; `_resolve_pager_command` and its `for var in ("PLBP_PAGER", "PAGER")` at :82-91; `_isatty` at :94-107; the paging gate `if not (self.paging and self.out.is_terminal and _isatty(self.out)):` at :177; the empty-value check at :180-183, the capture buffer at :184-186, the height check at :187-190, and `subprocess.run` at :194-196) and `docs/adr/0008-pager-for-long-text-output.md` (Status Accepted, 2026-06-12, PR #400; Decision, Consequences and Alternatives-considered sections) — retrieved 2026-09-10.
- ts-launch-blueprint at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: **not read for this item, and not needed.** The prompt records the item as py-only ("ts ships no pager integration to compare against") and `docs/port/DIVERGENCE-ANALYSIS.md:202` records ts state as `absent` with "no recorded reason". No claim in this report cites ts source.

**This repository** (all retrieved 2026-09-10): `docs/port/COMMONALITY.md:288-289` (F284, F285) and `:328` (F324); `docs/port/PARAMETERS.md` (the four fixed rows; `error-taxonomy-exit-codes` for R67's settled values); `docs/port/OWNER-REVIEW.md:105` (R64 disposition `accept` and the owner's pattern direction); `docs/port/DIVERGENCE-ANALYSIS.md:202` (R64 row, class D, harmonize `partly`) and `:303` (the D-versus-F caveat); `docs/port/README.md` (verdict vocabulary); `research/RUNBOOK.md:22` (the `BASELINE-REVIEW:` line format); `research/topics/06-unsafe-code-policy/DECISION.md` (R06's settled `unsafe_code = "forbid"` policy and its dependency exemption).

**Reference implementations, read at pinned tags** (all retrieved 2026-09-10): `git` v2.51.0 — `pager.c` and `Makefile`; `bat` v0.26.1 — `src/pager.rs`, `src/output.rs`, `Cargo.toml`; `delta` 0.19.2 — `src/env.rs`, `src/utils/bat/output.rs`, `Cargo.toml`; `jj` v0.45.1 — `cli/src/ui.rs`, `cli/src/config/misc.toml`, `docs/config.md`; `cargo-nextest` — `cargo-nextest/Cargo.toml` (read at `main`, not a tag, and labelled as such).

**Documentation and guidelines** (all retrieved 2026-09-10): <https://clig.dev/>; <https://git-scm.com/docs/git>; <https://cli.github.com/manual/gh_help_environment>; <https://doc.rust-lang.org/stable/std/process/struct.Command.html>; <https://doc.rust-lang.org/stable/std/env/fn.var.html>; `man less` on this host (`less` 668); <https://packages.ubuntu.com/noble/less>; <https://raw.githubusercontent.com/rust-cli/book/master/src/tutorial/output.md> and `…/src/in-depth/human-communication.md` (searched for paging guidance, none found).

**Figure endpoints** (all retrieved 2026-09-10): `GET https://crates.io/api/v1/crates/<name>` and `…/versions` for `shell-words`, `shlex`, `terminal_size`, `pager`, `minus`, `sapling-streampager`, `grep-cli`, `bat`; `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=20` for `shell-words` and `terminal_size`; `GET https://crates.io/api/v1/crates?q=…` for the four landscape searches; `GET https://api.github.com/repos/<o>/<r>` (via `gh api`) for `tmiasko/shell-words`, `eminence/terminal-size`, `AMythicDev/minus`, `comex/rust-shlex`, `markbt/streampager`, `facebook/sapling`, `sharkdp/bat`, `dandavison/delta`, `jj-vcs/jj`; `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the three member-relevant repositories and `markbt/streampager`; `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=30` plus each issue's `…/comments?per_page=20` for responsiveness; `GET https://gitlab.com/api/v4/projects/imp%2Fpager-rs`; `https://rustsec.org/packages/<name>.html` for `shell-words`, `terminal_size`, `pager`, `minus`, `sapling-streampager`, `shlex`, `errno` and the `time` control; <https://rustsec.org/advisories/RUSTSEC-2024-0006.html>; `GET https://static.rust-lang.org/dist/channel-rust-stable.toml`.

**Method notes.** Every crate figure in this report comes from `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`) and `GET https://crates.io/api/v1/crates/<name>/versions` (newest entry with `yanked: false`, taking `num`, `created_at`, `rust_version`, `license`, `edition`, `features`), sent with a `User-Agent` header, on 2026-09-10. Every GitHub figure comes from `GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`) and, for open issues, from `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`, never `open_issues_count`). Issue responsiveness was computed from `GET .../issues?state=all&sort=created&direction=desc&per_page=30` with pull requests filtered out (entries carrying a `pull_request` key), taking each issue's first comment whose `author_association` is OWNER, MEMBER or COLLABORATOR and whose author is not the opener; medians are over answered issues only, with the unanswered count reported separately. Advisories come from `https://rustsec.org/packages/<name>.html`, with `time` used as a control to confirm that a 404 means "no advisory page" rather than a broken endpoint. The MSRV floor of 1.96 was derived from `[pkg.rustc] version` in `https://static.rust-lang.org/dist/channel-rust-stable.toml`, not assumed. Source files in `git`, `bat`, `delta` and `jj` were read at pinned tags via `raw.githubusercontent.com`; `cargo-nextest`'s manifest was read at `main` and is labelled as such. Reader beware, four things could not be verified: (1) unauthenticated `api.github.com` returned `core.remaining: 0`, so all GitHub figures were taken through `gh api` with the user's token — the endpoints and fields are identical, but they are not anonymous retrievals; (2) `GET https://gitlab.com/api/v4/projects/imp%2Fpager-rs` returned `open_issues_count: null` and `archived: null` unauthenticated, so the `pager` crate's open-issue count and archived flag are unverified and its issue responsiveness could not be measured at all; (3) the `actions/runner-images` READMEs for `macos-15` and `Ubuntu2404` do not mention `less`, so its presence on the CI runners rests on it being a base-system package (directly verified on macOS here as `/usr/bin/less`, `less` 668; packaged for Ubuntu noble) rather than on a runner manifest; (4) `minus`'s `unsafe` posture was not audited, because that candidate is excluded on principle before safety or popularity is weighed, and asserting a posture without reading the source would be inventing a figure. No performance benchmark was run for any candidate and none is claimed: there is no Rust template to measure, and inferring an absolute winner from unlike third-party benchmarks is exactly what the prompt forbids.
