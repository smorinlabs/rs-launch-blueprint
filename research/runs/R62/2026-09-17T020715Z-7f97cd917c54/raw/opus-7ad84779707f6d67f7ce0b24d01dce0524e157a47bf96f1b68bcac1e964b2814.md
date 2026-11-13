# R62 — Clipboard integration (bundle) — Opus raw report

Engine: `research-opus-2026-09-17T020715Z-7f97cd917c54`, model `claude-opus-5`.
All endpoint figures retrieved **2026-09-17** (UTC), unless a different date is
stated on the line. Nothing in this report was compiled or executed: the run
constraint forbids scaffolding a Cargo project, so every command under
`### Validation strategy` is **planned**, not run, and every compile-time or
binary-size statement is qualitative and reasoned from the dependency graph
rather than measured. That limit is repeated in `Method notes`.

### Landscape

**The category this item decides.** Not "a clipboard crate". The category is
*an optional, best-effort side effect on the result sink of a short-lived CLI
process, in an environment that may not have the facility at all.* Naming it
that way matters, because it is what makes the headless case a first-class
design input rather than an error-handling afterthought, and because it is what
exposes the finding that dominates this item (the Linux selection-ownership
problem, below) — a finding invisible if the category is read as "pick a crate".

**Three-bin map of the Rust field.**

*Bin 1 — built-in or first-party toolchain.* **Empty.** Rust's standard library
has no clipboard API and no Rust project or working-group output proposes one.
`std` exposes process, filesystem and networking I/O; the clipboard is a
desktop-session facility owned by the windowing system (`NSPasteboard` on
macOS, the Win32 clipboard on Windows, X11 selections or the Wayland
`data-control` protocol extensions on Linux), and none of those is in `std`'s
scope. Confirmed by absence against the `std` module index
(`https://doc.rust-lang.org/std/`, HTTP 200, retrieved 2026-09-17): the page's
module list runs `alloc … os …` with no `clipboard`, `pasteboard` or `selection`
entry, and the single case-insensitive occurrence of the word "clipboard" on the
whole page is rustdoc's own **Copy item path to clipboard** UI button, not an
API. The consequence for the template is
that a third-party crate, an external binary, or a terminal escape sequence is
unavoidable — there is no "do it with `std`" option to compare against.

*Bin 2 — established industry standard.* One crate, plus its platform
substrate.

- **`arboard`** (`https://github.com/1Password/arboard`) — the de-facto
  cross-platform clipboard crate. 12,957,229 90-day downloads, 46,174,781
  all-time (`GET https://crates.io/api/v1/crates/arboard`, `crate.recent_downloads`
  / `crate.downloads`, retrieved 2026-09-17); **1,283** reverse dependencies
  (`GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10`,
  `meta.total`, retrieved 2026-09-17).
- **`copypasta`** (`https://github.com/alacritty/copypasta`) — Alacritty's
  maintained fork of the abandoned `rust-clipboard`. 857,282 / 5,559,318
  (same endpoint shape, retrieved 2026-09-17). Real, but an order of magnitude
  behind `arboard` and effectively a single-consumer crate.
- Platform substrate that `arboard` and `copypasta` both sit on, and that a
  hand-rolled stack would have to assemble directly: **`x11rb`** (17,870,431 /
  62,742,602), **`wl-clipboard-rs`** (5,563,908 / 14,218,368),
  **`smithay-clipboard`** (4,978,379 / 23,223,701), **`clipboard-win`**
  (14,919,611 / 58,832,374), **`objc2-app-kit`** (23,278,732 / 57,933,236) —
  all `GET https://crates.io/api/v1/crates/<name>`, retrieved 2026-09-17. These
  are transitive dependencies of the shortlist, not competitors to it; a
  template that assembled them by hand would be reimplementing `arboard`.

*Bin 3 — up-and-comers, and the long tail.* There is no credible rising
challenger. What exists is a tail of small, quiet or abandoned crates:
`cli-clipboard` 157,301 / 865,092 (last release 0.4.0, 2022-12-13),
`copypasta-ext` 38,694 / 476,609 (0.4.4, 2023-02-23, GitLab-hosted),
`terminal-clipboard` 7,453 / 82,190 (0.4.1, 2023-10-31), `clipboard`
(the original `rust-clipboard`) 107,484 / 1,758,083 (0.5.0, 2018-09-22),
`osc52` 24 / 1,528 (0.1.0, 2023-08-11) — all
`GET https://crates.io/api/v1/crates/<name>` and `/versions`, retrieved
2026-09-17. The genuinely interesting entry in this bin is not a crate at all:
the **OSC 52 terminal escape sequence**, treated as an architectural
alternative in `### Principles and implementation` rather than as a candidate
crate, because implementing it needs no dependency (`osc52`'s 24 90-day
downloads are the evidence that nobody takes the dependency).

**Authoritative sources used, and why each counts.**

| Source | Why it is authoritative | What it established here |
|---|---|---|
| `arboard` `README.md` (`https://github.com/1Password/arboard/blob/master/README.md`, retrieved 2026-09-17) | The maintainer's own documentation for the recommended crate, and unusually candid about its own limits | The Linux selection-ownership problem in the maintainer's words; that `wayland-data-control` is off by default and why; the MSRV badge (1.71.0); the volunteer-support posture |
| `arboard` source **at tag `v3.6.1`** — `src/common.rs`, `src/lib.rs`, `src/platform/linux/mod.rs`, `src/platform/linux/x11.rs`, `src/platform/linux/wayland.rs`, `examples/daemonize.rs` (read through `gh api "repos/1Password/arboard/contents/<path>?ref=v3.6.1"`, retrieved 2026-09-17) | Primary artifact; behaviour claims about a library are only as good as its source. **Every `arboard` line number in this report is at `v3.6.1`, the version recommended** — not at `master`, which is eight commits ahead and has shifted `src/platform/linux/mod.rs` by four lines | The exact error surface (`Error::Unknown { description }` for the headless case), the fail-fast `RustConnection::connect(None)` path, the `WaitConfig` semantics, the daemonize pattern |
| `arboard` `.github/workflows/test.yml` (same endpoint, retrieved 2026-09-17) | The project's own CI is the only non-self-reported evidence of which platforms it is *tested* on | That `arboard`'s tests deliberately exclude Linux, with the upstream reason stated in a comment |
| The org **CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` (read via `git -C /Users/stevemorin/c/cli-standards show f9de0437…`, retrieved 2026-09-17) | Normative and binding on this port by the task statement | R7.1, R7.3, R7.4, R6.1, R6.3, R8.2, R3.4, R5.6, R7.6, R7.8 — the stream, exit-status, non-interactive and flag-naming rules this item must satisfy. The standard contains **no clipboard rule**: grepping the blob for `clipboard`, `--copy`, `headless`, `DISPLAY`, `X11`, `Wayland` returns zero hits, so the rules applied below are the general ones, applied by their own terms |
| `wl-clipboard-rs` `README.md` (`gh api repos/YaLTeR/wl-clipboard-rs/contents/README.md`, retrieved 2026-09-17) and `src/copy.rs` | Maintainer documentation for the Wayland substrate `arboard` delegates to | That Wayland coverage is conditional on the compositor implementing `ext-data-control` or `wlr-data-control`; that non-`foreground` copy serves from a **thread**, not a forked process |
| R67 `DECISION.md` (owner-accepted, this repository) | The published prerequisite decision that owns `error-taxonomy-exit-codes` | The catalogue row and layering rule this item's failure path must use |
| `py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and its history; `ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` | The programme's two source implementations, read through their pins as the role file requires | The `--copy` precedent in both repos, including the py history the prompt's Context does not record (see `### Principles and implementation`) |

A note on what is *not* treated as authority: the Rust project's own blog index
(`https://blog.rust-lang.org/`, retrieved 2026-09-17) lists *2025 State of Rust
Survey Results* and topic surveys on debugging and compiler performance, none of
which publishes clipboard-library data, and no RFC or working-group output I
could find addresses the category. Saying so is part of
step 2 — the absence of ecosystem-level guidance here is itself a finding, and
it is why practice evidence carries proportionally more weight in this item
than it would in, say, an error-handling or async item.

**Practice evidence — well-regarded Rust projects surveyed.** Weighted toward
projects that are (a) recently active and (b) shaped like this template's CLI,
rather than toward raw star counts.

| Project | Evidence it is well regarded | What it uses | Source (retrieved 2026-09-17) |
|---|---|---|---|
| **`code2prompt`** (`mufeedvh/code2prompt`) | 7,656 stars, `pushed_at` 2026-09-11, not archived; a short-lived CLI whose headline feature is "copy the result to the clipboard" — the closest shape to this item that exists | `arboard`, behind a `wayland` feature mapping to `arboard/wayland-data-control`, with a Linux re-exec daemon | `gh api repos/mufeedvh/code2prompt`; `crates/code2prompt/src/clipboard.rs`; `crates/code2prompt/Cargo.toml` |
| **Nushell** (`nushell/nushell`, crate `nu-command`) | A widely adopted Rust shell; R67's own adopter table already cites it as a reference project | `arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }` | `gh api repos/nushell/nushell/contents/crates/nu-command/Cargo.toml` |
| **`reedline`** (`nushell/reedline`) | Nushell's line editor, used well beyond Nushell; `rust-version = "1.95.0"`, so it tracks recent stable closely | `arboard = { version = "3.3.0", optional = true, default-features = false, features = ["wayland-data-control"] }`, gated behind a `system_clipboard` feature | `gh api repos/nushell/reedline/contents/Cargo.toml` |
| **Bitwarden clients** (`bitwarden/clients`) | A security product with a dedicated desktop-native clipboard backend — evidence the crate is trusted where getting the clipboard wrong is a security bug | `arboard`, in `apps/desktop/desktop_native/core/src/clipboard/arboard_backend.rs` | `gh api "search/code?q=SetExtLinux+wait+language:Rust"` |
| **Tauri** (`tauri-plugin-clipboard-manager`), **egui** (`egui-winit`, `bevy_egui`), **Slint** (`i-slint-backend-winit`), **`minus`** (pager) | Each is the mainstream option in its own niche; their presence makes `arboard` the shared substrate across the GUI and TUI halves of the ecosystem, not just the CLI half | `arboard` | `GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10` |

The pattern across the four projects whose manifests I read is uniform and
specific: **`default-features = false` plus `features = ["wayland-data-control"]`**.
Three independent, well-regarded projects converge on the exact dependency line
recommended below. That is the strongest practice evidence in this item, and it
is stronger than the download figures, because it shows *how* the crate is
configured and not merely that it is pulled.

**Fit filter (step 4).** This template is CLI + library + web service. Two
consequences that a "best clipboard crate in general" survey would miss, and
that shaped the recommendation:

1. *Library, not just binary.* The clipboard write must not be reachable from
   the library crate's own code path in a way that makes the library depend on
   a desktop session. R67 already forbids the library crate from writing to any
   process stream or file; a clipboard is the same class of ambient resource.
   The seam therefore has to be a port (R01's shape), with the crate living in
   the binary.
2. *Web service.* The clipboard is meaningless in a server process. The crate
   must be excludable from the web build, which means an optional dependency
   behind a Cargo feature, not an unconditional one.

### Principles and implementation

**A correction to this prompt's `## Context`, recorded before anything is built on it**

The prompt states: *"this bundle is ts-only — py ships no clipboard integration
to compare against."* The first clause is correct **at the pin**; the second is
not correct as a statement about the py precedent, and the difference is
load-bearing for the question "should `--copy` exist at all".

`py-launch-blueprint` shipped a `--copy` flag backed by `pyperclip` for roughly
seventeen months. It was removed on **2026-06-09** in commit
`f587e48b41bcf6535ba1b62f348147294911c48d`, *"refactor: remove legacy
py-projects CLI and collapse command_name identity (#388)"*
(`git -C ~/c/py-launch-blueprint show f587e48`, retrieved 2026-09-17). The
commit message is explicit about why:

> the original single-command `py-projects` CLI (`src/py_launch_blueprint/projects.py`)
> duplicated the modern `plbp` noun-verb CLI: two HTTP clients, two config loaders,
> two test suites for one feature. remove it as a hard removal […]
> the legacy flat-flag features (`--format csv`, `--copy`/clipboard, `--output`,
> interactive config setup) have no `plbp` equivalent and are dropped.

Two facts follow, both citable.

1. **The ledger row is correct and needs no change.** At the pin
   `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `py-launch-blueprint` contains no
   `pyperclip` and no clipboard code in any `.py` file or in `pyproject.toml`
   (verified by iterating every tracked `*.py` and `pyproject.toml` through
   `git show b08bccfb:<path>`, retrieved 2026-09-17; zero hits). `F281`/`F282`
   origin `ts-only` is accurate as recorded. I therefore emit **no**
   `BASELINE-REVIEW:` line — the baseline is right, the prompt's gloss on it is
   what needed correcting.
2. **The removal is not evidence that `--copy` was rejected on its merits.** It
   is collateral of deleting an entire duplicated CLI. The commit's own wording —
   "have no `plbp` equivalent and are dropped" — records an unported feature, not
   a considered decision against clipboard integration. Reading it as a rejection
   would be reading drift as design.

The pre-removal py code is the third data point this item actually has, and it
is the one that establishes the principle by *failing* to honour it. At
`f587e48^`, `src/py_launch_blueprint/projects.py` reads:

    if copy:
        pyperclip.copy(result)
        console.print("[green]Results copied to clipboard[/green]")

(`git -C ~/c/py-launch-blueprint show f587e48^:src/py_launch_blueprint/projects.py`,
lines 397–399, retrieved 2026-09-17.) The write is unguarded. On headless Linux
`pyperclip.copy` raises `PyperclipException`, which the enclosing block catches
only as the generic `except Exception` arm that prints `Error: …` and exits —
so a py user with no display got a bare exception message after the result had
already been printed. ts D-016(7) is precisely the repair of that:
`clipboardy` behind a wrapped call whose failure becomes a `CliError` carrying a
remedy (`ts src/lib/adapters.ts:49`, `ts src/commands/projects.ts:193`, read
through the pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, retrieved
2026-09-17). Read across all three repositories, the trajectory is: py *had* the
capability and got the failure path wrong; ts kept the capability and fixed the
failure path; rs should keep both the capability and the fix, and — as this
report shows — must additionally fix a third thing that neither source repo ever
faced, because neither Python nor Node owns the selection.

**The shared requirement, its source, and the level at which agreement is required**

**Requirement.** A command that produces a textual result MAY additionally place
that result on the operating-system clipboard when the user asks for it with a
flag; the result MUST reach its primary sink regardless; and the clipboard write
MUST NOT be able to crash, hang, or silently mislead the user.

**Source.** `F281` and `F282` (`docs/port/COMMONALITY.md:285-286`), verdict
`DIVERGENT`, item `R62`; ts D-016(7); the pre-removal py implementation above.

**Agreement level: capability and policy, not library and not low-level value.**
Concretely:

| Must agree across py, ts and rs | May differ per ecosystem |
|---|---|
| That the capability is an *optional flag* on the result-emitting command, spelled `--copy` | The crate/package that performs the write |
| That the write happens *after* the result has reached its primary sink, and never replaces it | Whether the write is synchronous or handed to a helper process |
| That the success note goes to **stderr**, never stdout | The wording of the note |
| That a failure is a *typed, catchable* error with a remedy in its message — never a panic, an unhandled exception, or a silent no-op | The concrete error type, and which catalogue code it maps to |
| That the facility's absence is a normal, expected runtime state (headless Linux, CI), not an exceptional one | How absence is detected |

This is the "justified ecosystem difference" answer the owner clarification asks
for. The *principle* — an additive, best-effort side effect that degrades to a
clear diagnostic — ports unchanged. The *mechanism* cannot port, for a reason
specific to Rust that is developed next.

**The finding that dominates this item: Linux selection ownership**

Neither py nor ts ever had to solve this, because neither owns the selection.
Both source libraries are process wrappers, and both say so in their own source.
`pyperclip`'s module docstring lists its backends as *"pbcopy […] xclip […] xsel
[…] wl-copy/wl-paste"* and its macOS backend is literally
`subprocess.Popen(['pbcopy', 'w'], …)`
(`https://raw.githubusercontent.com/asweigart/pyperclip/master/src/pyperclip/__init__.py`,
lines 17–37 and 97–104, retrieved 2026-09-17). `clipboardy` runs
`execa('pbcopy', …)` on macOS
(`https://raw.githubusercontent.com/sindresorhus/clipboardy/main/lib/macos.js:8,13`)
and `xsel` on X11 — with a source comment explaining that it avoids `xclip`
*"because xclip does not properly close stdout/stderr when receiving input via
stdin, causing hangs in subprocess/pipe scenarios"* — plus a separate
`lib/wayland.js` backend
(`https://raw.githubusercontent.com/sindresorhus/clipboardy/main/lib/linux.js:8-10`;
`gh api repos/sindresorhus/clipboardy/contents/lib` lists `linux.js`,
`macos.js`, `termux.js`, `wayland.js`, `windows.js`, `wsl.js`; both retrieved
2026-09-17). Those external binaries **keep running after the caller exits** —
`wl-clipboard-rs` documents the fact about its own `wl-copy` counterpart in a
doc comment, *"potentially past a fork (which is how `wl-copy` uses it)"*
(`gh api repos/YaLTeR/wl-clipboard-rs/contents/src/copy.rs`, line 710, retrieved
2026-09-17); `xclip` and `xsel` behave the same way, which I did not verify in
their own sources. So the copy survives the Python or Node process exiting. A Rust
program that links `arboard` becomes the owner itself, and the copy dies with it.

In the maintainer's own words (`arboard` `README.md`, section
*Clipboard Ownership*, retrieved 2026-09-17):

> Some apps and users may notice that sometimes values copied to a Linux clipboard
> with this crate vanish before anyone gets the chance to paste […] X11 and Wayland
> put the responsibility for answering paste requests and serving data on the
> application which originally copied it onto the clipboard. […] Nothing you copy to
> the clipboard is sent anywhere to start. It stays inside `arboard` until something
> else on the system requests it, which is very different to how the clipboard works
> on other platforms like macOS or Windows.

and:

> If your application is exiting, you must make sure there is a clipboard manager
> running on the system. If nothing is listening for the clipboard ownership
> transfer, or made a copy previously, the data will be lost.

The same document, in `src/platform/linux/mod.rs`, is where `SetExtLinux::wait()`
is defined and where the remedy is named:

> This poses a problem for short-lived programs that just want to copy to the
> clipboard and then exit […] To resolve that, whenever the user copies something
> you can offload the actual work to a newly-spawned daemon process which will run
> in the background (potentially outliving the current process) and serve all the
> requests.

The Wayland path does **not** escape this. `arboard`'s Wayland backend calls
`wl_clipboard_rs::copy::Options::foreground(matches!(wait, WaitConfig::Forever))`
(`src/platform/linux/wayland.rs:118-126`, retrieved 2026-09-17), and
`wl-clipboard-rs` documents `foreground` as *"the flag for not spawning a separate
**thread** for serving copy requests"* (`src/copy.rs:385-393`, retrieved
2026-09-17). A thread, not a process — it dies with `exit()` exactly as the X11
serving thread does (`src/platform/linux/x11.rs:925`, `std::thread::spawn`).

So the platform matrix for a **short-lived CLI** is not the platform matrix for a
clipboard crate:

| Platform | Who stores the bytes | Does a one-shot write survive process exit? |
|---|---|---|
| macOS (`macos-latest`) | `NSPasteboard`, a system pasteboard server outside the process | **Yes.** Nothing further is needed |
| Windows (not in the matrix) | The Win32 clipboard, a kernel-managed store | Yes |
| Linux X11 / XWayland | The **copying process itself**, answering `SelectionRequest` events | **No**, unless a clipboard manager happens to be running and wins the race |
| Linux Wayland (`ext-data-control` / `wlr-data-control`) | The copying process, via a serving thread | **No**, same reason |
| Linux, headless (`ubuntu-latest`) | Nothing; no display server exists | N/A — the write correctly fails at `Clipboard::new()` |

This is why `### Recommendation` is a three-member stack and not a one-line
dependency: the crate answers the *portability* question, and a separate,
`cfg(target_os = "linux")`-only pattern answers the *persistence* question that
the crate explicitly declines to answer for you.

**The headless path, traced to source**

`arboard::Clipboard::new()` on Linux resolves to
`platform::linux::Clipboard::new()` (`src/platform/linux/mod.rs:128-146`). With
`wayland-data-control` enabled it first tests `std::env::var_os("WAYLAND_DISPLAY")`;
if that is unset — or set but `wayland::Clipboard::new()` fails, which is logged
through the `log` facade at `warn!` and then ignored — it falls through to
`x11::Clipboard::new()?`. That reaches
`RustConnection::connect(None)` (`src/platform/linux/x11.rs:142-144`), x11rb's
pure-Rust connection. With `DISPLAY` unset, `connect` returns `Err` immediately
from display-string parsing: `x11rb`'s `RustConnection::connect` maps a missing
name to `DisplayParsingError`
(`https://raw.githubusercontent.com/psychon/x11rb/master/x11rb/src/rust_connection/mod.rs`,
`fn connect` at line 112 and the mapping at line 156), whose `DisplayNotSet`
variant is documented as *"No explicit display was provided and the `$DISPLAY`
environment variable is not set."*
(`https://raw.githubusercontent.com/psychon/x11rb/master/x11rb-protocol/src/errors.rs`,
lines 82–85; both retrieved 2026-09-17). With `DISPLAY` set but no socket behind
it, it returns `Err` from the connect attempt instead. Neither path sleeps,
retries or blocks. Either way `arboard` maps
it with:

    .map_err(|_| Error::unknown("X11 server connection timed out because it was unreachable"))

Four properties of this path decide the wrapper design, and each is checkable
against the lines cited:

1. **It returns, it does not hang or panic.** `Clipboard::new()` yields
   `Result<Clipboard, Error>`. There is no blocking retry and no `unwrap` on the
   failure path. This directly answers the HIGH question about hanging.
2. **The failure is `Error::Unknown { description }`, not a dedicated variant.**
   `arboard::Error` (`src/common.rs:20-53`) is `#[non_exhaustive]` with exactly
   `ContentNotAvailable`, `ClipboardNotSupported`, `ClipboardOccupied`,
   `ConversionFailure`, `Unknown { description }`. The headless case lands in
   `Unknown`, and the crate's own doc comment says the `description` field *"is
   only meant to help the developer and should not be relied on as a means to
   identify an error case during runtime."* **The template must therefore not
   match on the message to detect headlessness**, and must not need to: every
   failure of `Clipboard::new()` means the same thing to a `--copy` user.
3. **The message `arboard` produces is wrong for this case.** There is no
   timeout; the connection is refused or the display string is unparsable. If
   the template forwards `arboard`'s `Display` output verbatim, a CI log reads
   *"X11 server connection timed out because it was unreachable"* for a machine
   that never had an X server. The wrapper must **supply its own message and
   hint** and carry `arboard::Error` as a `#[source]` for `--debug`. This is
   also what CLI Design Standard R7.6 requires — errors that *"name the offending
   input"* and *"state a next step"* — which a forwarded "timed out" does not do.
4. **`Error` implements `std::error::Error`** (`src/common.rs:67`), so it
   composes with `thiserror`'s `#[from]`/`#[source]` and with `anyhow` at the
   boundary under R67's layering rule with no adapter code.

`arboard`'s own CI is independent corroboration that this is the real Linux CI
behaviour, and it is unusually direct. `.github/workflows/test.yml` runs
`clippy` on `[macos-latest, windows-latest, ubuntu-latest]` but runs the test job
only on `[macos-latest, windows-latest]`, above this comment (retrieved
2026-09-17):

    # No Linux test for now as it just fails due to not having a desktop environment.

That is the same fact `clipboardy`'s upstream gave ts in D-016(7) — *"upstream
confirms headless Linux has no clipboard, so graceful degradation is mandatory"* —
arrived at independently in the Rust ecosystem. `clipboardy` now states it in its
own error text, which is worth quoting because it is the hint this item has to
write in Rust: *"Clipboard access requires a display server (X11 or Wayland).
This doesn't work in headless environments like CI servers, Docker containers, or
SSH sessions without X11 forwarding."*
(`https://raw.githubusercontent.com/sindresorhus/clipboardy/main/lib/linux.js`,
line 30, retrieved 2026-09-17). The principle ports because the
underlying platform reality is identical.

**Architectural alternatives, compared before libraries**

Four designs are genuinely available. Only the first is recommended; the other
three are compared on their merits, not dismissed.

**Alternative A — native crate (`arboard`), write in-process.** Links platform
APIs directly: `NSPasteboard` through `objc2-app-kit` on macOS, `x11rb` and
optionally `wl-clipboard-rs` on Linux. *No external binary on PATH.* Costs a
dependency subtree and inherits the selection-ownership problem on Linux.
**Recommended**, with Member 3 supplying the missing persistence.

**Alternative B — shell out to `pbcopy` / `wl-copy` / `xclip -selection clipboard`.**
This is literally what both source repos do — `clipboardy` and `pyperclip` are
both process wrappers — and it is also what `py-launch-blueprint` still does
today in its developer recipes: `Justfile:58` at the pin defines
`CLIPBOARD_CMD := if os_family() == "windows" { "clip" } else if os() == "linux" { "xclip -selection clipboard" } else { "pbcopy" }`
and `Justfile:608` degrades with
`echo "${local_cleanup_cmd}" | {{CLIPBOARD_CMD}} || echo "(Failed to copy command to clipboard)"`
(`git -C ~/c/py-launch-blueprint show b08bccfb:Justfile`, retrieved 2026-09-17).
*Advantages, and they are real:* zero new crate dependencies; the persistence
problem vanishes, because `xclip` and `wl-copy` fork on their own; the code is
about thirty lines of `std::process::Command`. *Disadvantages that decide it:*
it reintroduces a runtime PATH dependency that Rust otherwise lets this template
avoid — and the GitHub `ubuntu-latest` image (Ubuntu 24.04) does **not** ship
`xclip`, `xsel` or `wl-clipboard`
(`https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md`,
retrieved 2026-09-17; the installed-packages tables contain `xvfb` and none of
the three clipboard tools), so any CI test of the success path would need an
`apt-get install` step that Alternative A does not need. It also makes the error
surface worse, not better: a missing binary, a non-zero exit, and a signal death
are three distinct failure shapes to classify, against one `Result` in
Alternative A. **Ranked second**, and it is the design to fall back to if
`arboard` ever becomes unmaintainable.

**Alternative C — OSC 52 terminal escape sequence.** Write
`\x1b]52;c;<base64>\x07` to the terminal. *This is the only design that works
over SSH*, and it needs no dependency at all — `osc52`'s 24 90-day downloads
(retrieved 2026-09-17) show the ecosystem writes the four lines inline rather
than taking a crate. *Why it is not the recommendation:* it requires a terminal
that implements OSC 52 and, in tmux/screen, extra passthrough configuration; it
cannot be verified (the sequence is fire-and-forget — the program cannot learn
whether the terminal honoured it, so "degrade cleanly" becomes "cannot detect
failure at all", which is worse than the status quo, not better); and it is
useless in exactly the environment this item is being asked about, because CI
has no terminal either. **Recommendation: document it as a known extension point
in the template's docs and do not implement it.** It is the right answer to a
different question (remote-session copy), and a template that implements it
without a way to report failure would be shipping a silent no-op. For the
evidence that the ecosystem writes it inline rather than taking a crate: Helix
emits the sequence directly with `Osc::SetSelection(selection, content)` in
`helix-view/src/clipboard.rs:304-312`
(`gh api repos/helix-editor/helix/contents/helix-view/src/clipboard.rs`,
retrieved 2026-09-17), taking no clipboard-escape dependency.

**Alternative D — do not ship `--copy` at all.** The honest case for it: the
capability is a convenience; `rslbp projects … | pbcopy` already works on macOS
and `| xclip` on Linux; and py currently ships nothing. *Why it loses:* the
Objective puts the flag's existence on the table, but the evidence points the
other way once py's history is read correctly — py's removal was collateral, not
a judgement, and ts kept the capability deliberately after research (D-016(7)).
More decisively, dropping it would make this template *worse as a template*: the
`--copy` flag is the smallest realistic example of a **conditional, optional,
platform-dependent side effect that must degrade** — a pattern a template's users
will need for notifications, editor launching, and browser opening, and one that
is easy to get wrong. The value of shipping it is the pattern, not the
convenience. **Rejected**, with the reasoning recorded so the owner can overturn
it on a one-line change.

**How the recommended design preserves each principle**

- *Result first, clipboard second.* The write is invoked only after the result
  has reached stdout or the destination-file option, mirroring ts `src/commands/projects.ts:193`
  and pre-removal py `projects.py:397`. Under CLI Design Standard R7.1 the
  result is stdout's alone, and the confirmation note and every failure go to
  stderr.
- *Typed, catchable failure.* The library crate defines the error with
  `thiserror` per R67's layering rule; `arboard` is reached only through a
  binary-crate adapter, so the library crate never depends on `arboard` and
  never touches a desktop session. This also satisfies the fit constraint that
  the web build exclude the crate entirely.
- *Absence is normal, not exceptional.* The adapter treats every `Err` from
  `Clipboard::new()` identically, because `arboard` gives it no reliable way to
  distinguish them and tells it not to try.
- *Never silently mislead.* This is the principle that `code2prompt` — the best
  available reference implementation, and otherwise a model of the pattern —
  actually violates, which is why it is worth stating as a separate principle
  rather than folding it into "degrade cleanly". Detail in Member 3.

**Where the exit code lands (R67), and why no conflict line is emitted**

Out of scope per `## Out of scope`: this item decides only that the failure is a
typed, catchable error. For the record that the task statement asks for:
**R67's catalogue can express this failure as it stands.** A clipboard write
that fails because the session has no display server is a runtime I/O failure
against an ambient OS facility — `RSLB101` I/O → exit **1**. Cross-checking the
three neighbouring rows confirms the fit rather than assuming it: `RSLB102` is
scoped to network transport (DNS/connect/timeout/TLS) and does not reach a local
display server; `RSLB201` is usage/parse, and passing `--copy` on a headless
machine is not a malformed invocation; `RSLB205` is *required non-auth input*
that prompting cannot supply, and a clipboard is an output sink, not input. The
org standard agrees from the other direction: R8.2 assigns exit `1` to *"runtime
input failures"* as against the `2`/`4` cases, R6.1 makes `1` the generic
runtime error, and R6.3 exits `1` when the command did its main work but a
requested part of it failed. **No `CONFLICT:` line is emitted.** If the owner
later wants clipboard failures distinguishable by code, that is an append to
R67's append-only catalogue owned by R67 — not a change this item needs or is
entitled to make.

**Minimal realistic example**

Sketched, not built — the run constraint forbids scaffolding. The shape is a
port in the library crate and an adapter in the binary crate:

    // crates/rslb-core/src/ports/clipboard.rs  (library crate; no `arboard`)
    pub trait ClipboardPort: Send + Sync {
        fn write_text(&self, text: &str) -> Result<(), ClipboardError>;
    }

    #[derive(Debug, thiserror::Error)]
    #[error("could not copy to the clipboard")]
    pub struct ClipboardError {
        #[source]
        source: Box<dyn std::error::Error + Send + Sync + 'static>,
    }

    // crates/rslbp/src/adapters/clipboard.rs  (binary crate; owns `arboard`)
    pub struct SystemClipboard;
    impl ClipboardPort for SystemClipboard { /* probe, then platform split */ }

The library crate's error deliberately does **not** name `arboard`: the port is
the seam, and a fork substituting Alternative B changes one file. Member 2 gives
the full field set; Member 3 gives the Linux branch.

**Observable acceptance criteria**

| # | Criterion | How it is observed |
|---|---|---|
| AC1 | On `macos-latest`, `rslbp projects --copy` writes the result to stdout **and** places it on the pasteboard; the pasteboard still holds it after the process exits | `pbpaste` in a following step compares equal to stdout |
| AC2 | On `ubuntu-latest` with no `DISPLAY` and no `WAYLAND_DISPLAY`, the same command writes the result to stdout unchanged, writes one diagnostic to stderr naming the remedy, and exits non-zero — it does not panic, does not hang, and stdout is byte-identical to the run without `--copy` | exit status, `diff` of the two stdout captures, and a bounded-timeout wrapper proving no hang |
| AC3 | Under `--json`, the failure is the R67 envelope `{"error":{"code","message","hint"}}` on stderr with stdout byte-empty on the error path | `jq -e` on captured stderr |
| AC4 | On `ubuntu-latest` under `xvfb-run`, the copy round-trips and **survives the writing process exiting** | a second process reads the selection back after the first has exited |
| AC5 | Without the `clipboard` Cargo feature, `cargo tree` shows no `arboard` and the web build links none of it | `cargo tree -e normal` |
| AC6 | The library crate's dependency graph never contains `arboard` in any feature combination | `cargo tree -p rslb-core --all-features` |

AC4 is the criterion that neither source repo could have had, and it is the one
that catches the selection-ownership bug. AC2 and AC4 together are the pair that
a naive implementation passes half of.

**`BASELINE-REVIEW:`** — none emitted. The `F281`/`F282` rows are accurate at the
programme's pins; the correction recorded at the top of this section is to this
prompt's narrative gloss, not to the ledger.

### Recommendation

**One stack.** Adopt `--copy` on the result-emitting command, backed by:

    arboard = { version = "3.6.1", default-features = false, features = ["wayland-data-control"] }

as an **optional** dependency of the binary crate only, enabled by a
default-on `clipboard` Cargo feature; reached exclusively through a
`ClipboardPort` trait defined in the library crate (R01's trait-object seam),
whose failure is one `thiserror` type in the library carrying `arboard::Error`
as `#[source]`, and which the error boundary maps to R67's `RSLB101` → exit `1`
with a platform-specific hint; plus, on `cfg(target_os = "linux")` only, a
selection-ownership helper that probes `Clipboard::new()` in the foreground and,
only on success, re-executes the template's own binary with a hidden
`--clipboard-daemon` flag, handing the payload to the child over **stdin**, so
the copy outlives the command.

Three members: the crate, the write-and-degrade wrapper, and the Linux
persistence helper. The third is not optional polish — without it the feature is
broken on every Linux desktop, which is the majority of the CI matrix's Linux
half and a large share of the template's likely users.

### Members

#### arboard

##### Landscape

The category is *cross-platform OS-clipboard access from a Rust process*.
Bin 1 (built-in / first-party toolchain) is empty — `std` has no clipboard API
(`https://doc.rust-lang.org/std/`, retrieved 2026-09-17). Bin 2 (established
industry standard) holds `arboard` and, a long way behind, `copypasta`; the
platform crates they both wrap (`x11rb`, `wl-clipboard-rs`, `clipboard-win`,
`objc2-app-kit`, `smithay-clipboard`) are substrate rather than alternatives, as
a template assembling them by hand would be rewriting `arboard`. Bin 3
(up-and-comers) contains no rising challenger, only a quiet tail —
`cli-clipboard`, `copypasta-ext`, `terminal-clipboard`, the abandoned
`clipboard`, and `osc52`. The authoritative sources are `arboard`'s own README,
source and CI workflow; `wl-clipboard-rs`'s README and `src/copy.rs` for the
Wayland substrate; and, for practice, the manifests of `code2prompt`,
`nu-command` and `reedline` — three active, well-regarded projects whose
`arboard` lines are quoted verbatim in `### Landscape` and which converge on
the same configuration.

##### Principles and implementation

The principle this member carries is *platform coverage without a runtime PATH
dependency*. ts satisfied platform coverage by delegating to external binaries
(`clipboardy` shells out to `xsel`/`wl-clipboard`/`pbcopy`); Rust can satisfy it
by linking native APIs, which removes a class of runtime failure the source
repos simply live with — a missing `xclip` on a machine that has a display.
`arboard` realizes this: `NSPasteboard` via `objc2-app-kit` on macOS, the Win32
clipboard via `clipboard-win` on Windows, and on Linux the X11 protocol via
`x11rb` (pure Rust, no `libX11` link) with `ext-data-control`/`wlr-data-control`
via `wl-clipboard-rs` when `wayland-data-control` is enabled — none of which
spawns a process or resolves a binary on PATH. The countervailing fact, fully
developed in `### Principles and implementation` and in Member 3, is that
linking the API also means *owning the selection*, which the external binaries
were quietly doing for ts and py. Coverage is bought; persistence is not.

##### Dominant choice

**`arboard` 3.6.1.** The margin is not close.

| Figure | `arboard` | Endpoint / field |
|---|---|---|
| 90-day downloads | **12,957,229** | `GET https://crates.io/api/v1/crates/arboard` → `crate.recent_downloads` |
| All-time downloads | **46,174,781** | same → `crate.downloads` |
| Last release | **3.6.1, 2025-08-23T20:19:03Z** | `GET https://crates.io/api/v1/crates/arboard/versions`, newest `yanked: false` → `num`, `created_at`. Corroborated by `GET https://api.github.com/repos/1Password/arboard/releases?per_page=3` → tag `v3.6.1`, `published_at` 2025-08-23T20:15:46Z |
| Stars / archived / pushed | **967 / false / 2026-09-16T16:54:50Z** | `GET https://api.github.com/repos/1Password/arboard` → `stargazers_count`, `archived`, `pushed_at` |
| Open issues | **19** | `GET https://api.github.com/search/issues?q=repo:1Password/arboard+is:issue+is:open` → `total_count`. (The repo object's `open_issues_count` is 38; it counts pull requests and is not used, per the figure rule) |
| Advisories | **none** | `https://rustsec.org/packages/arboard.html` → HTTP 404 |
| Reverse dependencies | **1,283** | `GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10` → `meta.total` |
| Declared MSRV | **1.71.0** | `/versions` → `rust_version` on 3.6.1; corroborated by the README MSRV badge and by `Cargo.toml` `rust-version = "1.71.0"` |
| Licence | **MIT OR Apache-2.0** | `/versions` → `license`; `Cargo.toml` `license = "MIT OR Apache-2.0"` |

All figures retrieved 2026-09-17.

**Issue responsiveness.** Of the ten most recently opened issues (pull requests
excluded; `GET https://api.github.com/repos/1Password/arboard/issues?state=all&sort=created&direction=desc&per_page=100`,
then each issue's `/comments`, counting only a first comment whose
`author_association` is `OWNER`, `MEMBER` or `COLLABORATOR` and whose author is
not the issue's own author; retrieved 2026-09-17): **2 of 10 answered**,
**8 unanswered** — #230 opened 2026-08-21T09:05:03Z, first maintainer reply
2026-08-24T16:24:00Z (**3.0 days**); #218 opened 2026-05-05T23:39:48Z, first
maintainer reply 2026-05-06T01:14:39Z (**0.06 days**). The median days-to-first-
maintainer-response is **undefined**, because more than half the sample never
received one; that is the honest figure and it is reported as such rather than
computed over the answered subset alone.

**Adopters, with the evidence that each is a relevant, well-regarded reference.**

| Adopter | Why it is a relevant reference | Its `arboard` line | Source (retrieved 2026-09-17) |
|---|---|---|---|
| `mufeedvh/code2prompt` | 7,656 stars, `pushed_at` 2026-09-11, not archived; a short-lived CLI whose `--copy`-equivalent is its headline feature — the same shape as this item | `arboard = { workspace = true }`, with a crate feature `wayland = ["arboard/wayland-data-control"]` | `gh api repos/mufeedvh/code2prompt`; `crates/code2prompt/Cargo.toml` |
| `nushell/nushell` (`nu-command`) | A widely adopted Rust shell; already cited as a reference project by the accepted R67 decision, so its standing is established inside this programme and not only outside it | `arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }` | `gh api repos/nushell/nushell/contents/crates/nu-command/Cargo.toml` |
| `nushell/reedline` | Nushell's line editor, used by projects beyond Nushell; `rust-version = "1.95.0"` shows it tracks recent stable | `arboard = { version = "3.3.0", optional = true, default-features = false, features = ["wayland-data-control"] }`, behind a `system_clipboard` feature | `gh api repos/nushell/reedline/contents/Cargo.toml` |
| `bitwarden/clients` | A password manager's desktop-native layer — adoption where a clipboard bug is a security bug | `apps/desktop/desktop_native/core/src/clipboard/arboard_backend.rs` | `gh api "search/code?q=SetExtLinux+wait+language:Rust"` |
| `tauri-plugin-clipboard-manager`, `egui-winit`, `bevy_egui`, `i-slint-backend-winit`, `minus` | Tauri, egui, Bevy, Slint and a mainstream pager; breadth across the GUI and TUI halves of the ecosystem | `arboard` | `GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10` |

Three of these — `code2prompt`, `nu-command`, `reedline` — independently use
`default-features = false` with `wayland-data-control`. That convergence, not
the download count, is what makes the dependency line in `### Recommendation`
an evidenced choice rather than a preference.

**Maintenance state: `active`.** The rubric's six-month trigger fires — the last
crates.io release, 3.6.1, is dated **2025-08-23**, about 12.8 months before
retrieval — so it was investigated rather than scored. What the investigation
found: the repository is **not archived**; `pushed_at` is **2026-09-16**, the day
before retrieval; **8 commits** land after the 3.6.1 release date
(`GET https://api.github.com/repos/1Password/arboard/commits?since=2025-08-23T20:19:03Z&per_page=100`,
`length`, retrieved 2026-09-17), and they are not all housekeeping — they include
`Properly encode/decode MIME=text/uri-list` (2026-04-28), `bump windows-sys lower
bound` (2026-07-11) and `Apply GitHub Actions security best practices`
(2026-07-15). None of the concrete `at-risk` or `dormant` signals is present:
no open advisory, no broken build on current stable (CI runs `stable` and the
1.71.0 MSRV on three OSes), no maintainer stop-notice. Two things are recorded
plainly rather than smoothed over: **there has been no crates.io release since
2025-08-23**, so eight commits of fixes are unpublished; and the maintainers
have pre-announced their support posture in the README — *"Please note that this
is not an official 1Password product. Feature requests will be considered like
any other volunteer-based crate."* That sentence explains the 8-of-10 unanswered
issue rate without contradicting the `active` verdict, and it is the honest
frame for the re-verify trigger below.

##### Qualified shortlist

**`copypasta` 0.10.2** — the only other candidate that passes every gate.
857,282 90-day / 5,559,318 all-time downloads; last release **0.10.2,
2025-04-25T12:50:12Z**; 350 stars, `archived: false`, `pushed_at`
2025-05-09T16:33:48Z; **5** open issues (search endpoint); no RustSec page
(HTTP 404); declared MSRV **1.71.0**; licence `MIT / Apache-2.0` — all
endpoints as in the `arboard` table, retrieved 2026-09-17. Its issue
responsiveness is markedly *better* than `arboard`'s: **9 of the 10** most
recently opened issues received a maintainer reply, seven of them within an
hour (for example #82 opened 2025-07-28T19:28:39Z, replied 2025-07-28T20:08:04Z;
#65 opened 2023-11-20T12:54:58Z, replied 2023-11-20T12:56:43Z), giving a median
first-response time of roughly **0.03 days** with one unanswered. Maintenance
state: **`stable-quiet`** — no release in about 16.7 months and no push in about
16.3 months trips the trigger, but the crate is small, feature-complete for
Alacritty's needs, unarchived, with a low and promptly-answered issue queue and
no advisory; none of the concrete `at-risk` signals is present. It is a real
runner-up and is ranked as such below.

##### Excluded by gate

Gate 1 (licence) is **`inapplicable — owner ruling 2026-09-12 (Q7.B)`** for
every candidate, and nothing is excluded on licence. Exclusions below are on
gates 2–6 and on the maintenance rubric.

| Candidate | Excluded by | Evidence (retrieved 2026-09-17) |
|---|---|---|
| `clipboard` (`rust-clipboard`) | **Gate 3** — open RustSec advisory; and `dormant` by the rubric (unpatched advisory plus the maintainer's own notice that the crate is unmaintained, which is why `arboard` forked from it) | `https://rustsec.org/packages/clipboard.html` → HTTP **200**, listing **RUSTSEC-2022-0056**; last release 0.5.0, 2018-09-22 (`/versions`) |
| `cli-clipboard` | Maintenance rubric — **`dormant`**: last release **0.4.0, 2022-12-13**, no repository push since 2024-05-30, and a repository rename (`actuallyallie/cli-clipboard` → `allie-wake-up/cli-clipboard`) that silently broke its crates.io `repository` link. 24 stars, 8 open issues, no advisory (404). A fork of `copypasta` with no advantage over its upstream | `GET https://crates.io/api/v1/crates/cli-clipboard/versions`; `GET https://api.github.com/repos/allie-wake-up/cli-clipboard`; `GET https://api.github.com/search/issues?q=repo:allie-wake-up/cli-clipboard+is:issue+is:open` → 8. (The pre-rename search query returned HTTP 422 *"resources do not exist or you do not have permission"*, which is what surfaced the rename) |
| `copypasta-ext` | Maintenance rubric — **`dormant`**: last release **0.4.4, 2023-02-23**, 38,694 90-day downloads, GitLab-hosted so no GitHub star/issue/push figures exist for it (recorded as unavailable, not as zero). Its reason for existing — an X11 fork-and-serve extension — is exactly the problem Member 3 solves against current `arboard`, without a stale third-party layer | `GET https://crates.io/api/v1/crates/copypasta-ext` and `/versions`; repository `https://gitlab.com/timvisee/copypasta-ext` |
| `terminal-clipboard` | Maintenance rubric — **`dormant`**: last release **0.4.1, 2023-10-31**; `pushed_at` 2023-10-31T09:32:41Z; 11 stars; 6 open issues; **7,453** 90-day downloads, three orders of magnitude below `arboard`; and `license: null` on the GitHub repository object, which under a licence gate would have needed resolution and under the owner ruling simply is not evaluated | `GET https://crates.io/api/v1/crates/terminal-clipboard` and `/versions`; `GET https://api.github.com/repos/Canop/terminal-clipboard` |
| `osc52` | **Gate 6 and fitness**, not maintenance: **24** 90-day downloads and 1,528 all-time, last release 0.1.0 2023-08-11. Excluded as a *crate*; the OSC 52 technique it wraps is evaluated on its merits as Alternative C in `### Principles and implementation`, where it is recommended as a documented extension point rather than a dependency | `GET https://crates.io/api/v1/crates/osc52` and `/versions` |
| `clipboard-win`, `x11rb`, `wl-clipboard-rs`, `smithay-clipboard`, `objc2-app-kit` | Not excluded — **not candidates**. These are the substrate `arboard` and `copypasta` are built from; selecting them directly means hand-writing a cross-platform abstraction the template does not need. Recorded here so the map is complete. `clipboard-win` 5.4.1 is `BSL-1.0`, which is **noted and not excluded** — it is a Windows-only transitive dependency, Windows is outside `target-os-matrix`, and gate 1 is inapplicable regardless | `GET https://crates.io/api/v1/crates/<name>` and `/versions` |

##### Up-and-comers

**There are none, and that is the finding.** Every crate in bin 3 is older and
quieter than the bin-2 incumbents rather than newer and rising: the most recent
first release among them is `terminal-clipboard`'s line, last touched
2023-10-31. Sorting the whole candidate set by `created_at` of the newest
non-yanked version puts `arboard` (2025-08-23) and `copypasta` (2025-04-25)
ahead of everything else by more than a year. The category is consolidated, and
the practical read for a template is that there is no emerging option worth
hedging against — the re-verify trigger below watches `arboard`'s release
cadence, not a challenger's rise.

The one genuinely newer idea in this space is not a crate: OSC 52 adoption in
terminal applications, which implement the escape sequence inline. The verified
instance is Helix, whose `helix-view/src/clipboard.rs:304-312` writes
`Osc::SetSelection(selection, content)` with no clipboard-escape dependency
(`gh api repos/helix-editor/helix/contents/helix-view/src/clipboard.rs`,
retrieved 2026-09-17). It is treated as Alternative C, and the fact that a
project of Helix's standing implements it *without* taking `osc52` as a
dependency — against that crate's 24 90-day downloads — is itself the evidence
that no crate is emerging to serve it.

##### Fit for this template

Judged against CLI + library + web service and against the py/ts precedent, not
against "best in general".

*Gate-by-gate, before popularity was weighed.*

1. **Licence** — `inapplicable — owner ruling 2026-09-12 (Q7.B)`. (Recorded for
   completeness only: `Cargo.toml` declares `license = "MIT OR Apache-2.0"`,
   which happens to match `license` exactly.)
2. **MSRV** — **passes with wide headroom.** `arboard` 3.6.1 declares
   `rust-version = "1.71.0"`. Across the tree the recommended feature set
   actually resolves, the highest *declared* `rust-version` is also **1.71**:
   `objc2` 0.6.4 = 1.71, `objc2-app-kit` 0.3.2 = 1.71, `objc2-foundation` 0.3.2
   = 1.71, `parking_lot` 0.12.5 = 1.71, `log` 0.4.34 = 1.71.0, `x11rb` 0.13.2 =
   1.64, `percent-encoding` 2.3.2 = 1.51, `wl-clipboard-rs` 0.9.3 = none declared
   (all `GET https://crates.io/api/v1/crates/<name>/versions` → `rust_version`,
   retrieved 2026-09-17). Against the floor R67 recorded from its own executed
   resolution — Rust **1.96** at that run's date — 1.71 leaves twenty-five minor
   versions of headroom, so `msrv-policy`'s rolling `stable minus 2` will not
   collide with this crate in any foreseeable window. **This is a reason to
   disable default features and not only a preference:** with `image-data` on,
   `image` 0.25.10 declares **1.88.0**, which still passes but spends most of
   that headroom for a feature the template never uses. *Caveat stated honestly:*
   these are declared floors read from the registry, not a resolved lockfile —
   the run constraint forbids creating a Cargo project, so no `cargo tree` or
   `cargo msrv` was executed. The planned verification is in
   `### Validation strategy`.
3. **Advisories and `unsafe` posture** — **passes.** `https://rustsec.org/packages/arboard.html`
   returns HTTP **404**, as do `x11rb`, `wl-clipboard-rs`, `clipboard-win`,
   `objc2`, `objc2-foundation`, `parking_lot`, `log` and `percent-encoding`
   (retrieved 2026-09-17). A bare 404 proves nothing on its own, so it was
   paired with positive controls on the same endpoint in the same sweep:
   `https://rustsec.org/packages/image.html` returns **200** listing
   RUSTSEC-2019-0014 and RUSTSEC-2020-0073, and
   `https://rustsec.org/packages/clipboard.html` returns **200** listing
   RUSTSEC-2022-0056. The endpoint distinguishes, so the 404s are zero-advisory
   evidence. *`unsafe` posture:* `arboard` uses `unsafe` in its own code for the
   Objective-C bridge on macOS and the Win32 API on Windows; its Linux path is
   `x11rb` (a pure-Rust X11 protocol implementation — no `libX11` FFI) and
   `wl-clipboard-rs`, whose README states *"The code of the crate itself (and the
   code of the example utilities) is 100% safe Rust. This doesn't include the
   dependencies."* None of this conflicts with R06: its
   `unsafe_code = "forbid"` is declared in `[workspace.lints.rust]` and governs
   first-party crates only, because Cargo compiles dependencies with
   `--cap-lints allow`, and R06's own decision text says the template "makes no
   claim about `unsafe` inside its dependency tree". The template's own clipboard
   adapter contains no `unsafe` and compiles under `forbid`.
4. **Builds and is tested on `ubuntu-latest, macos-latest`** — **builds on both;
   tested on macOS only.** `arboard`'s `.github/workflows/test.yml` (retrieved
   2026-09-17) runs `clippy` across `os: [macos-latest, windows-latest,
   ubuntu-latest]` × `rust_version: [stable, "1.71.0"]`, and separately across
   `--no-default-features`, `--features image-data`, `--features
   wayland-data-control` and `--all-features` — so the exact configuration
   recommended here is a configuration upstream lints on `ubuntu-latest`. The
   `test` job, however, runs only on `os: [macos-latest, windows-latest]`, under
   this comment: `# No Linux test for now as it just fails due to not having a
   desktop environment.` Windows support is noted and not required. The candid
   reading: upstream *compiles* the Linux path in CI and *exercises* it nowhere,
   which is precisely why AC2 and AC4 below are this template's own tests and not
   an inherited guarantee.
5. **Default features and async coupling** — default is `["image-data"]`, which
   pulls `image` 0.25 plus its codec subtree; the recommendation sets
   `default-features = false` and adds only `wayland-data-control`. **No async
   coupling of any kind:** the API is synchronous (`Clipboard::new() ->
   Result<Clipboard, Error>`, `set_text(&mut self, …) -> Result<(), Error>`),
   there is no executor dependency and no `async fn`, so the crate composes with
   whatever execution model R05 and R69 select without constraining them. It does
   spawn an OS **thread** on the X11 path (`std::thread::spawn` at
   `src/platform/linux/x11.rs:925`) and `wl-clipboard-rs` spawns one on the
   Wayland path — threads, not tasks; no runtime is required, and Member 3
   exists because those threads die with the process.
6. **Binary size and compile time** — **qualitative, not measured; nothing was
   compiled in this run.** With `default-features = false`, the added tree is
   modest and codec-free: on macOS, `objc2`, `objc2-foundation` and
   `objc2-app-kit` (thin FFI bindings, no heavy monomorphization); on Linux,
   `x11rb`, `parking_lot`, `percent-encoding` and `log`, plus — with
   `wayland-data-control` — `wl-clipboard-rs` and its `wayland-client` /
   `wayland-backend` / `wayland-protocols` / `os_pipe` / `tempfile` subtree,
   which is the larger half of the Linux cost. The dominant cost is the one the
   recommendation removes: the default `image-data` feature pulls `image` 0.25
   with PNG, BMP and TIFF codecs, a materially larger compile and link than
   everything else in this member combined, for a capability (`ImageData`) the
   template never touches. The template's `clipboard` Cargo feature means a
   `--no-default-features` library or web build pays none of it. The planned
   measurement is in `### Validation strategy`.

*Fit beyond the gates.* The synchronous API sits behind R01's `dyn`-compatible
trait cleanly — `fn write_text(&self, text: &str) -> Result<(), ClipboardError>`
has no `async fn`, no generic method and no non-receiver `Self`, so the port is
dyn-compatible without `async-trait`. `arboard::Error` implements
`std::error::Error` (`src/common.rs:67`), so it drops straight into
`thiserror`'s `#[source]` under R67's layering. And the crate is *excludable*:
making it `optional = true` behind a `clipboard` feature is what keeps the web
service from linking a desktop-session dependency.

##### Recommendation

    [dependencies]
    arboard = { version = "3.6.1", default-features = false, features = ["wayland-data-control"], optional = true }

    [features]
    default = ["clipboard"]
    clipboard = ["dep:arboard"]

In the **binary crate only**. `default-features = false` drops `image-data` and
with it the `image` codec subtree and its 1.88.0 MSRV floor;
`wayland-data-control` is added because without it `arboard` speaks only X11
(`src/platform/linux/mod.rs:129-145` compiles the Wayland branch out entirely),
which would leave the template behind `clipboardy`'s `wl-clipboard` coverage on
a pure-Wayland desktop. `optional = true` behind a default-on `clipboard`
feature keeps the crate out of the library crate and out of a web-only build.
This is character-for-character the line `nu-command` and `reedline` ship, with
`optional` added for the feature gate `reedline` also uses.

**Parity with `clipboardy`'s platform matrix — the precise answer to the HIGH
question.** macOS: parity (both use the native pasteboard). Windows: parity
(both native; outside the matrix regardless). Linux X11: parity *in reach*, and
`arboard` is strictly better on dependencies because `x11rb` speaks the protocol
directly where `clipboardy` needs `xsel` installed. Linux Wayland: **conditional
parity, and this is the one place the answer is "not quite".** `wl-clipboard-rs`
requires the compositor to implement `ext-data-control` or `wlr-data-control`
(its README, retrieved 2026-09-17: *"The protocol used for clipboard interaction
is `ext-data-control` or `wlr-data-control`. When using the regular clipboard,
the compositor must support any version of either protocol."*), and `arboard`'s
own README says so too, adding: *"If you or a user's desktop doesn't support
these protocols, `arboard` won't function in a pure Wayland environment. It is
recommended to enable `XWayland` for these cases."* `clipboardy` has the same
dependency — `wl-copy` uses the same protocols — so this is a shared ecosystem
limit rather than a regression, but it is a real caveat and it is stated rather
than rounded up to "parity". **Unverified:** whether GNOME/Mutter, the desktop
Ubuntu ships, implements `ext-data-control` at a given version. I attempted to
establish this from `https://wayland.app/protocols/ext-data-control-v1` (HTTP
200, but the retrieved page did not contain a compositor-implementations
section I could parse) and from `GET https://api.github.com/search/code?q=ext_data_control+repo:GNOME/mutter`
and `GET https://api.github.com/search/issues?q=repo:GNOME/mutter+ext-data-control`,
both of which returned `total_count: 0` against what is a read-only mirror whose
code index is not reliable — a zero there is not evidence of absence. It is
recorded as unverified rather than asserted in either direction, and it does not
change the recommendation, because the XWayland fallback the maintainer names
covers it and because `ubuntu-latest` has no compositor at all.

##### Ranked runner-up

**`copypasta` 0.10.2**, and it is a genuine runner-up rather than a courtesy
entry: it passes every gate, its maintainers answer issues far faster
(9 of 10 versus 2 of 10), and Alacritty's continued reliance on it is real
adoption. It loses on four specifics. (i) **Scale**: 857,282 versus 12,957,229
90-day downloads, and 350 versus 967 stars — roughly a 15× gap in use. (ii)
**Purpose**: it is maintained *for Alacritty*, a long-lived GUI terminal, which
is the use case where selection ownership is a non-problem; a short-lived CLI is
not its design target, and it exposes no analogue of `SetExtLinux::wait()` for
the ownership case — grepping every file in its `src/` (`common.rs`, `lib.rs`,
`nop_clipboard.rs`, `osx_clipboard.rs`, `wayland_clipboard.rs`,
`windows_clipboard.rs`, `x11_clipboard.rs`) for `fn wait`, `fork` or `daemon`
returns nothing (`gh api repos/alacritty/copypasta/contents/src`, each file read,
retrieved 2026-09-17). (iii) **Wayland substrate**: it reaches Wayland through
`smithay-clipboard` — `Cargo.toml:18` declares the feature
`wayland = ["smithay-clipboard"]` and `:39` the dependency
`smithay-clipboard = { version = "0.7.0", default-features = false, optional = true }`
(`gh api repos/alacritty/copypasta/contents/Cargo.toml`, retrieved 2026-09-17) —
which the `wl-clipboard-rs` README explicitly scopes to
applications that *have a window* — *"This crate is intended to be used by
terminal applications, clipboard managers and other utilities which don't spawn
Wayland surfaces (windows). If your application has a window, please use […]
`smithay-clipboard`"* — the opposite of this template's shape. (iv) **Momentum**:
16.7 months without a release against `arboard`'s eight unreleased commits and
daily pushes. It is the crate to move to if `arboard` goes dormant *and* a
windowed shape ever applies; Alternative B (shell-out) is the better fallback
for this template's actual shape.

##### Tradeoffs

| Tradeoff | In `arboard`'s favour | Against |
|---|---|---|
| Native APIs vs. external binaries | No `xclip`/`xsel`/`wl-copy` on PATH; one `Result` instead of three failure shapes; works on a stock `ubuntu-latest`, which ships none of those three tools | A dependency subtree the template would not otherwise have, and platform code the template cannot inspect at its own call site |
| Selection ownership | The crate is honest about it and provides `SetExtLinux::wait()` plus a daemonize example | The crate does **not** solve it for you; Member 3 is unavoidable work that ts and py never had to do |
| Error surface | `Error` is `#[non_exhaustive]` and implements `std::error::Error`, composing with `thiserror`/`anyhow` at zero cost | The headless case is `Unknown { description }` with no dedicated variant, and the message it carries (*"connection timed out"*) is inaccurate for that case, so the wrapper must not forward it |
| Release cadence | Repository pushed the day before retrieval; 8 unreleased commits including a real fix | No crates.io release in ~12.8 months; fixes on `master` are not on the registry, and the template pins the registry version |
| Maintainer posture | 1Password staff plus the original author; security-sensitive adopters rely on it | *"not an official 1Password product […] like any other volunteer-based crate"*, and 8 of the last 10 issues unanswered |
| Default features | `image-data` off removes the largest compile and MSRV cost | A fork that wants image support must re-enable it and accept `image`'s 1.88.0 floor |

##### Parameters

This member owns no repository-wide parameter and needs no consumed parameter to
change. It **assumes** the four fixed values as recorded in `docs/port/PARAMETERS.md`:
`rust-edition = 2024` (`arboard` itself is edition 2021, which a 2024 workspace
consumes without issue — editions are per-crate), `msrv-policy = stable minus 2
minor versions, raised only in a minor release, declared as rust-version in
Cargo.toml and tested in CI` (satisfied with 25 minors of headroom),
`license = MIT OR Apache-2.0` (gate inapplicable per the owner ruling), and
`target-os-matrix = ubuntu-latest, macos-latest` (builds on both; see gate 4 for
what upstream tests). No `CONFLICT:` line.

##### Migration implications

The template has no Rust code yet, so every change is an addition. In the binary
crate's `Cargo.toml`: the `arboard` optional dependency line above, and the
`clipboard` feature in `[features]` with `default = ["clipboard"]`. Nothing in
the library crate's manifest, and nothing in a web-only feature set — that
absence is the point, and AC5/AC6 test it. In CI, one addition per OS leg is
described under `### Validation strategy`; `ubuntu-latest` needs no `apt-get`
step, which is one of this member's concrete advantages over Alternative B.

##### Validation strategy

Planned; nothing here was executed.

1. `cargo tree -e normal -p rslbp --no-default-features` — expect **no**
   `arboard` line. Proves the feature gate.
2. `cargo tree -e normal -p rslbp` on each of `macos-latest` and
   `ubuntu-latest` — expect `arboard v3.6.1` with `objc2-app-kit` on macOS and
   `x11rb` + `wl-clipboard-rs` on Linux, and **no** `image` on either. Proves
   `default-features = false` took effect.
3. `cargo tree -p rslbp -d` — expect empty output (no duplicate resolutions),
   the same control R67 ran against its own set.
4. `cargo +1.<floor> check -p rslbp` at the MSRV leg the CI matrix already runs
   under `msrv-policy` — expect success, confirming the declared 1.71 floors
   resolve in practice rather than only on paper.
5. `cargo audit` on the committed `Cargo.lock` — expect no findings for
   `arboard` or its subtree. Pair it with the control R67 established
   (`anyhow = "=1.0.102"` reproduces RUSTSEC-2026-0190) so a clean run is
   evidence the tool is working, not merely silent.
6. Compile-time and size, measured rather than asserted:
   `cargo build --release --timings` and `ls -l target/release/rslbp` with and
   without `--no-default-features`, on both runners. This is the measurement
   that replaces gate 6's qualitative statement above.

##### Confidence & re-verify trigger

**Confidence: high** on the crate selection; **medium-high** on the version pin.
High on selection because three independent, active, well-regarded projects ship
the identical configuration, the download and reverse-dependency margins are an
order of magnitude, every gate is answered from primary sources, and the
runner-up's own substrate documentation says it is built for a shape this
template does not have. Medium-high on the pin because 3.6.1 is ~12.8 months old
with eight unreleased commits behind it — the right version to depend on today,
but the thing most likely to move first.

Re-verify on any of: a crates.io release after 3.6.1 (re-read the changelog for
Linux-ownership or `wayland-data-control` changes and re-run the tree checks); a
RustSec advisory against `arboard`, `x11rb`, `wl-clipboard-rs` or the `objc2`
family; `arboard`'s `pushed_at` going quiet for six months *while* no release
lands, which would convert the current release-cadence note into an `at-risk`
signal; `arboard` enabling `wayland-data-control` by default, which would make
the explicit feature redundant; `1Password/arboard` becoming archived or a
maintainer notice appearing, which routes to Alternative B rather than to
`copypasta`; R05 or R69 selecting an execution model (no coupling is expected,
since the API is synchronous, but the assumption should be re-stated against the
chosen model); `target-os-matrix` gaining `windows-latest`, which brings
`clipboard-win`'s BSL-1.0 into a supported leg and is worth a fresh look even
under the owner's licence ruling; and, failing all of those, figure freshness by
**2027-03-17**.

##### Sources

- `GET https://crates.io/api/v1/crates/arboard` — `crate.recent_downloads` 12,957,229, `crate.downloads` 46,174,781, `crate.max_stable_version` 3.6.1. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/arboard/versions` — newest non-yanked 3.6.1, `created_at` 2025-08-23T20:19:03.127566Z, `rust_version` 1.71.0, `license` MIT OR Apache-2.0. Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10` — `meta.total` 1,283; page names `toon-format`, `mit-commit-msg`, `minus`, `rinf_cli`, `bevy_egui`, `reedline`, `nu-command`, `tauri-plugin-clipboard-manager`, `egui-winit`, `i-slint-backend-winit`. Retrieved 2026-09-17.
- `GET https://api.github.com/repos/1Password/arboard` — `stargazers_count` 967, `archived` false, `pushed_at` 2026-09-16T16:54:50Z, `open_issues_count` 38 (unused). Retrieved 2026-09-17.
- `GET https://api.github.com/search/issues?q=repo:1Password/arboard+is:issue+is:open` — `total_count` 19. Retrieved 2026-09-17.
- `GET https://api.github.com/repos/1Password/arboard/commits?since=2025-08-23T20:19:03Z&per_page=100` — 8 commits. Retrieved 2026-09-17.
- `GET https://api.github.com/repos/1Password/arboard/releases?per_page=3` — v3.6.1 2025-08-23T20:15:46Z, v3.6.0, v3.5.0. Retrieved 2026-09-17.
- `GET https://api.github.com/repos/1Password/arboard/issues?state=all&sort=created&direction=desc&per_page=100` plus each issue's `/comments` — responsiveness sample (#235, #234, #230, #226, #223, #218, #216, #212, #211, #207). Retrieved 2026-09-17.
- `arboard` `Cargo.toml`, `README.md`, `src/common.rs`, `src/lib.rs`, `src/platform/linux/mod.rs`, `src/platform/linux/x11.rs`, `src/platform/linux/wayland.rs`, `examples/daemonize.rs`, `.github/workflows/test.yml` — via `gh api "repos/1Password/arboard/contents/<path>?ref=v3.6.1"`, at the recommended version. Retrieved 2026-09-17.
- `https://rustsec.org/packages/arboard.html` → 404; `…/x11rb.html`, `…/wl-clipboard-rs.html`, `…/clipboard-win.html`, `…/objc2.html`, `…/objc2-foundation.html`, `…/parking_lot.html`, `…/log.html`, `…/percent-encoding.html` → 404. Positive controls: `…/image.html` → 200 (RUSTSEC-2019-0014, RUSTSEC-2020-0073); `…/clipboard.html` → 200 (RUSTSEC-2022-0056). Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/<name>/versions` for `x11rb` (0.13.2, 2025-08-29, MSRV 1.64), `wl-clipboard-rs` (0.9.3, 2025-12-13, MSRV none), `objc2` (0.6.4, MSRV 1.71), `objc2-app-kit` (0.3.2, MSRV 1.71), `objc2-foundation` (0.3.2, MSRV 1.71), `parking_lot` (0.12.5, MSRV 1.71), `log` (0.4.34, MSRV 1.71.0), `percent-encoding` (2.3.2, MSRV 1.51), `image` (0.25.10, MSRV 1.88.0), `clipboard-win` (5.4.1, BSL-1.0). Retrieved 2026-09-17.
- `GET https://crates.io/api/v1/crates/copypasta` and `/versions`; `GET https://api.github.com/repos/alacritty/copypasta`; `GET https://api.github.com/search/issues?q=repo:alacritty/copypasta+is:issue+is:open`; its issue/comment sample. Retrieved 2026-09-17.
- `gh api repos/nushell/nushell/contents/crates/nu-command/Cargo.toml`; `gh api repos/nushell/reedline/contents/Cargo.toml`; `gh api repos/mufeedvh/code2prompt` and `…/contents/crates/code2prompt/Cargo.toml`. Retrieved 2026-09-17.
- `wl-clipboard-rs` `README.md` and `src/copy.rs` — via `gh api repos/YaLTeR/wl-clipboard-rs/contents/<path>`. Retrieved 2026-09-17.
- `https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md` — `xvfb` 2:21.1.12-1ubuntu1.6 present; no `xclip`, `xsel` or `wl-clipboard` entry. Retrieved 2026-09-17.
- R06 `DECISION.md` (this repository) — `unsafe_code = "forbid"` scoped to first-party crates because Cargo passes `--cap-lints allow` to dependencies.

#### Clipboard write-and-degrade wrapper (`ClipboardPort`)

##### Landscape

This member is an **architectural pattern**, not a crate, so the three-bin map
is drawn over *designs for an optional side effect that may be unavailable*
rather than over registry packages.

*Bin 1 — built-in or first-party toolchain.* Rust's own facility for this is
`Result` plus a typed error, and the first-party guidance is the Rust API
Guidelines' error conventions (`https://rust-lang.github.io/api-guidelines/interoperability.html`,
retrieved 2026-09-17) together with the `std::error::Error` `source()` chain.
Unlike the clipboard-access category, this bin is *not* empty — the language
supplies exactly the mechanism needed, and the question is how to shape it.

*Bin 2 — established industry standard.* The `thiserror`-in-the-library /
`anyhow`-at-the-binary split, which the accepted R67 decision already selected
for this template on evidence from Cargo, Ruff, Nushell, `bat`, `ripgrep`, `fd`
and `cargo-nextest` (R67 `DECISION.md`, adopter table). Paired with it, the
ports-and-adapters seam R01 already selected: a `dyn`-compatible trait in the
library, the concrete adapter at the composition root. Both decisions are
published and binding here; this member's job is to *apply* them to a facility
that is allowed to be absent, not to re-litigate them.

*Bin 3 — up-and-comers.* `miette` and `color-eyre` for diagnostic rendering
(both appear in R67's adopter table — `cargo-nextest` uses `color-eyre` and
`miette`, Nushell uses `miette`). Neither is adopted here: R67 fixed the
envelope shape as `{"error":{"code","message","hint"?}}` and the rendering
question is R66's, not this item's.

**Authoritative sources.** The org CLI Design Standard v1.4.14 (blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`) for the stream, exit-status,
flag-naming and non-interactive rules; R67's accepted decision for the error
layering and envelope; R01's accepted parameter for the seam shape; and, for
practice, the same three well-regarded projects surveyed in Member 1 — with
`code2prompt` carrying particular weight here because it is the only one whose
shape (short-lived CLI, optional copy of the result) matches this item, and
because reading its wrapper is what exposed the failure mode this member is
designed to avoid.

##### Principles and implementation

The principle is stated in `### Principles and implementation` and repeated here
in the form this member must satisfy: **an optional side effect on the result
sink must never replace the result, never crash, never hang, and never claim
success it cannot verify.**

py got the first three roughly right by accident and the fourth by luck:
`pyperclip.copy(result)` ran after `console.print(result)`, so the result did
reach its sink, but the write was unguarded and a headless user got a bare
`Error: …` from a generic `except Exception` arm (`git -C ~/c/py-launch-blueprint
show f587e48^:src/py_launch_blueprint/projects.py`, lines 390–405, retrieved
2026-09-17). ts fixed it deliberately: the write is a `ClipboardWriter` injected
dependency (`ts src/lib/adapters.ts:49`, read through the pin
`cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, retrieved 2026-09-17), the call is
wrapped, and the catch re-raises a `CliError` whose message carries the remedy
(`ts src/commands/projects.ts:190-201`):

    if (cmdOpts.copy) {
      try {
        await deps.clipboard(result);
      } catch (err) {
        throw new CliError(
          `Could not copy to clipboard: ${err instanceof Error ? err.message : String(err)} ` +
            '(clipboard access needs a display; on headless Linux install xsel or wl-clipboard)'
        );
      }
      deps.stderr(`${colors.success('Results copied to clipboard')}\n`);
    }

Three things in that snippet port unchanged and one must not. **Ported:** the
write happens after the result reached its sink; the success note goes to
stderr; the failure carries a remedy, not just a cause. **Not ported:** the
interpolation of the underlying library's message into the user-facing string.
In Node that is harmless — `clipboardy` rejects with a spawn error that names
the missing binary. In Rust it is actively misleading, because `arboard` reports
the headless case as *"X11 server connection timed out because it was
unreachable"* (`src/platform/linux/x11.rs:142-144`) when nothing timed out and
no server ever existed. **The Rust wrapper composes its own message and hint and
carries `arboard::Error` as a `#[source]`**, visible under `--debug` and in the
`anyhow` chain, invisible in the one-line diagnostic. That is a justified
ecosystem difference: the same principle (*tell the user what to do next*)
requires opposite handling of the underlying error's text, because the two
underlying libraries report the same condition with opposite accuracy.

A second thing must not port, and it is subtler. ts detects failure by catching
a rejected promise from a process spawn — a real, synchronous-enough signal that
the copy did not happen. In Rust the equivalent signal exists on macOS and does
**not** exist on Linux once Member 3's helper is introduced, because the actual
write happens in a child process. That is why this member's contract is written
as *"never claim success it cannot verify"* rather than the weaker *"report
errors"*, and why the probe-before-spawn ordering in Member 3 is part of this
member's acceptance criteria and not an implementation detail.

##### Dominant choice

**A `dyn`-compatible port in the library crate, a `thiserror` error beside it,
and the `arboard` adapter in the binary crate — applying R01's seam and R67's
layering unchanged.**

    // crates/rslb-core/src/ports/clipboard.rs — library crate. No `arboard` here.
    pub trait ClipboardPort: Send + Sync {
        /// Place `text` on the OS clipboard. Best-effort by contract: callers
        /// must have already delivered the result to its primary sink.
        fn write_text(&self, text: &str) -> Result<(), ClipboardError>;
    }

    #[derive(Debug, thiserror::Error)]
    pub enum ClipboardError {
        /// No clipboard facility is reachable — typically a Linux session with
        /// no X11 or Wayland display server, which is the normal state in CI.
        #[error("the clipboard is unavailable")]
        Unavailable {
            #[source]
            source: Box<dyn std::error::Error + Send + Sync + 'static>,
        },
        /// The facility exists but the write did not complete.
        #[error("the clipboard write failed")]
        WriteFailed {
            #[source]
            source: Box<dyn std::error::Error + Send + Sync + 'static>,
        },
    }

Four properties, each load-bearing and each checkable:

1. **Dyn-compatible.** No `async fn`, no generic method, no associated const, no
   non-receiver `Self` — so `Arc<dyn ClipboardPort>` works, matching R01's
   recorded `http-transport-injection-seam` shape exactly and needing no
   `async-trait` even if R05 later selects an async model. If the CLI becomes
   async, the adapter is the place that wraps the blocking call (a
   `spawn_blocking`-shaped hop); the port does not change. *R05 is unresolved at
   the time of writing and this member does not depend on its outcome.*
2. **The library crate never names `arboard`.** The `#[source]` is a boxed
   `std::error::Error`, not `arboard::Error`. This is what lets the web build and
   the library build link none of Member 1, and what lets a fork swap in
   Alternative B by editing one adapter file. It costs one `Box` on a path taken
   at most once per command.
3. **Two variants, not one.** `Unavailable` and `WriteFailed` differ in the hint
   they deserve — "this machine has no clipboard" versus "it does and the write
   failed" — and mapping both to `RSLB101`/1 today does not make the distinction
   worthless, because it is the distinction a future R67 catalogue append would
   need. The adapter decides which: a failure of `Clipboard::new()` is
   `Unavailable`, a failure of `set_text` is `WriteFailed`.
4. **No matching on `arboard`'s text, anywhere.** `arboard::Error` is
   `#[non_exhaustive]` and its `Unknown { description }` doc comment states the
   field *"is only meant to help the developer and should not be relied on as a
   means to identify an error case during runtime"* (`src/common.rs:50-52`,
   retrieved 2026-09-17). The adapter classifies by **which call failed**, which
   is stable API, rather than by what the message said, which is not.

**The shipped test double.** Following R01's `InMemoryProjectsPort` precedent,
the library crate ships two doubles beside the port: a recording implementation
that captures the text, and one that always returns `ClipboardError::Unavailable`.
The second is what makes AC2 and AC3 testable on a developer's macOS laptop,
which does have a clipboard — without it, the headless path can only ever be
tested on a Linux runner.

**The call site.**

    // after the result has reached stdout or the destination-file option, never before
    if opts.copy {
        clipboard.write_text(&result)?;             // maps to RSLB101 / exit 1
        if !opts.quiet {
            writeln!(stderr, "results copied to the clipboard")?;
        }
    }

**Flag naming: `--copy`, long form only, no short flag.** It matches ts
(`ts src/commands/projects.ts:84` — `.option('--copy', 'copy results to clipboard', false)`)
and preserves the cross-repo agreement the principle table requires. CLI Design
Standard R3.4 says a short alias *"SHOULD be reserved for frequently used
options only"*; `--copy` is a convenience on one command, so it gets none. `-c`
is not in the standard's reserved set (`-h -V -v -q -o -f -y`, R4.1/R3.4), so
this is a judgement rather than a prohibition, and it is recorded as such. This
answers the LOW question: **keep `--copy`**, and defer to R60 only if the chosen
parser makes the long-only spelling awkward, which no mainstream Rust parser
does.

**Interaction with the standard's stream and mode rules, stated explicitly
because each is easy to get backwards:**

| Rule | What it requires here |
|---|---|
| **R7.1** (stdout = requested result, stderr = everything else) | The result goes to stdout; the `results copied to the clipboard` note and every clipboard diagnostic go to **stderr**. This also fixes the py wart where the note went through the same `console` as the result |
| **R7.3** (TTY-aware behaviour) | `--copy` is **not** a presentation nicety and **must not** be suppressed when stdout is a pipe. R7.3 suppresses spinners, pagers and prompts because they are *presentation*; `--copy` is an explicitly requested action. `rslbp projects --copy \| jq .` must still copy. Getting this backwards — gating `--copy` on `IsTerminal` — is the most likely misreading of R7.3 in this item, so it is written down |
| **R4.4** (`--quiet` suppresses informational stderr only) | `--quiet` suppresses the success note; it does **not** suppress the failure diagnostic and does **not** change the exit status |
| **R8.2** (fully usable without a TTY) | `--copy` requires no TTY and prompts for nothing. On a machine with no clipboard it fails with a clear message rather than blocking — which is the whole of this member |
| **R7.6** (errors to stderr, lowercase-first, no trailing period, name the offending input, state a next step) | Shapes the message and hint text below |
| **R7.8** / R67 envelope | Under `--json` or any machine format, the failure is the single stderr object `{"error":{"code","message","hint"}}` with stdout byte-empty on the error path |
| **R5.6** (secrets redacted in output) | The payload is never logged, never echoed into a diagnostic, and — Member 3 — never placed in `argv` |

**Message and hint.** Message: `could not copy the result to the clipboard`.
Hint, composed by the adapter per platform, naming the next step as R7.6
requires — on Linux: `no clipboard could be reached; is a display server
running? run without --copy, or pipe the result to a clipboard tool`; on macOS:
`the pasteboard rejected the write; try again, or run without --copy`. The Linux
wording is deliberately hedged rather than asserting that no display server
exists: as point 2 above establishes, `arboard` gives the adapter no way to
separate an absent display from a refused connection or an unreadable
`Xauthority`, and a hint that over-claimed would repeat on the user the exact
inaccuracy this report criticises in `arboard`'s own message. R67 makes `hint` optional, omitted
rather than `null` when absent, and rendered as its own line in human output;
its Rust return type is P03's and must be able to name the offending input, so a
borrowed-or-owned string rather than `&'static str` — exactly what a
platform-composed hint needs.

**Failure is fatal (exit non-zero), not a warning.** Two defensible policies
exist and the choice is recorded rather than assumed.

- *Fatal (recommended).* The user asked for the side effect; it did not happen;
  a script writing `rslbp projects --copy && pbpaste \| …` would otherwise be
  lied to. This is ts's behaviour (`throw new CliError`), it matches CLI Design
  Standard R6.3's shape — a command that did its main work but failed part of
  it exits `1` — and R8.2's assignment of exit `1` to runtime failures. The
  result still reaches stdout unchanged, so a pipeline that only wanted the data
  is unaffected except by the status.
- *Warning (rejected).* Print to stderr, exit `0`. It is friendlier for the
  common interactive case, and it is what py's `Justfile:608` does for its
  developer recipe (`|| echo "(Failed to copy command to clipboard)"`). It is
  rejected because a template should teach the stricter default, and because the
  friendlier behaviour is one line away for a fork that wants it.

This is a policy the owner can flip in the adapter's caller without touching the
port, the error type, or Member 1; it is called out here so the flip is a
decision rather than a discovery.

##### Qualified shortlist

**Alternative 2a — a free function, no port.** `pub fn copy_to_clipboard(text:
&str) -> Result<(), ClipboardError>` in the binary crate, called directly.
Simpler by one trait and one `Arc`. Rejected: the headless path then cannot be
tested anywhere that has a clipboard, which is every developer laptop and the
`macos-latest` runner; and it breaks the seam consistency R01 established for
the template's other driven I/O, so the template would teach two different
shapes for the same kind of boundary. This is `code2prompt`'s shape, and
`code2prompt` has no test for its clipboard module.

**Alternative 2b — `Result<bool, E>` or `Option`, distinguishing "no clipboard
here" from "the write failed".** Absence is modelled as a value rather than an
error, so the caller can choose to treat a headless machine as success. It has a
real argument behind it: on the fatal-versus-warning question above it makes the
warning policy natural. Rejected for this template because R03 owns the
*port absence versus failure* contract programme-wide and is **unresolved**; a
two-variant error keeps the information (the `Unavailable` variant *is* the
absence signal) without pre-empting R03's shape. If R03 later mandates an
absence-as-value contract, this member changes one signature and keeps
everything else. **Recorded as the coupling most likely to move this member.**

**Alternative 2c — return the error, let the caller print.** Equivalent to the
recommendation; the difference is only whether the hint is composed in the
adapter or at the boundary. Composing it in the adapter is preferred because the
adapter is the only layer that knows the platform.

##### Excluded by gate

Gate 1 (licence) — `inapplicable — owner ruling 2026-09-12 (Q7.B)`, and
doubly inapplicable in that this member adds **no dependency**: it uses
`thiserror`, already selected by the accepted R67 decision for the library
crate, and nothing else.

Nothing is excluded by gate here, because the candidates are designs rather than
packages and the rejections above are on fitness rather than on a gate. For
completeness against the tier rule that no gate be silently omitted:

| Gate | Answer for this member |
|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)` |
| 2 MSRV | **`inapplicable`** — a pattern declares no `rust-version`. The constructs used (trait objects, `thiserror` derive, `Box<dyn Error + Send + Sync>`) are all far below any plausible floor; `thiserror`'s own floor is 1.71 per R67's resolution |
| 3 advisories / `unsafe` | **`inapplicable`** for advisories — no package to file one against. `unsafe` posture: the pattern contains **no `unsafe`** and compiles under R06's `unsafe_code = "forbid"` |
| 4 OS matrix | **Applies and passes.** The pattern is OS-independent; the *adapter* it wraps is Member 1's, whose matrix answer is in Member 1 gate 4 |
| 5 default features / async coupling | **No async coupling.** The port is synchronous and dyn-compatible, so it is neutral to R05's outcome; the Cargo feature involved is Member 1's `clipboard` |
| 6 size / compile cost | **Negligible and unmeasured.** One trait, one enum, two doubles — no proc-macro beyond the `thiserror` derive already in the tree |

##### Up-and-comers

The genuinely newer idea in Rust error handling for CLIs is **rich diagnostic
rendering** — `miette` (used by Nushell and `cargo-nextest` per R67's adopter
table) and `color-eyre` — which would render this member's error with source
spans and coloured hints. It is not adopted, for a reason that is about
ownership rather than merit: R67 fixed the envelope at three keys and R66 owns
the human rendering. A clipboard failure has no source span to point at anyway —
there is no offending input text, only an absent facility — so the richest thing
`miette` could add here is colour, which R65 owns.

The second up-and-comer is the `#[non_exhaustive]` + `#[source]` idiom this
member uses, which is now standard practice rather than novel; naming it as
settled is the accurate read.

##### Fit for this template

This member is the reason the item is worth doing at all. The template's users
will need the same shape for every *optional, environment-dependent side effect*
they add — opening a browser, launching `$EDITOR`, posting a desktop
notification, writing to a socket that may not exist. `--copy` is the smallest
honest instance of it, and the pattern generalises without change: probe, act,
degrade with a remedy, never claim unverified success.

It fits the three shapes as follows. **Library:** defines the port and the error
and depends on nothing platform-specific, so `rslb-core` remains linkable in a
`wasm32` or server context. **CLI:** owns the adapter and the flag. **Web
service:** links neither, because the feature gate excludes the adapter and the
port is never constructed — AC5 and AC6 test exactly this.

Against the py and ts precedent: it preserves every behaviour ts's D-016(7)
established and repairs the one thing that does not survive translation (the
interpolated upstream message), while giving py's lost capability a better home
than it had.

##### Recommendation

Adopt the `ClipboardPort` trait, the two-variant `ClipboardError`, the shipped
test doubles, and the call-site ordering above; keep the flag spelled `--copy`
with no short form; send the success note to stderr and suppress it under
`--quiet`; compose the message and hint in the adapter and carry
`arboard::Error` only as `#[source]`; make failure fatal; and map it at the
boundary to R67's `RSLB101` → exit `1`.

##### Ranked runner-up

**Alternative 2b** (absence as a value rather than an error), ranked above 2a
and 2c because it is the one that a still-unresolved decision could make
correct. It wins if R03 settles the port-absence contract in favour of
absence-as-value, or if the owner flips the fatal-versus-warning policy — the
two changes travel together, since a warning policy wants a non-error absence
signal. The migration cost is one trait signature and one match arm.

##### Tradeoffs

| Tradeoff | For the recommendation | Against |
|---|---|---|
| Port versus free function | The headless path is testable on any machine; the seam matches R01 | One trait and one `Arc` more than the minimum; `code2prompt` ships without either |
| Boxed `#[source]` versus a typed `arboard::Error` | The library crate stays free of `arboard`, so the web and library builds link none of it | A `Box` allocation on the failure path, and the concrete type is only recoverable by `downcast_ref` |
| Two error variants versus one | Keeps the distinction a future R67 append would need; supports a per-variant hint | Both map to `RSLB101` today, so the distinction pays nothing yet |
| Fatal versus warning | Scripts are told the truth; matches ts and R6.3 | Less friendly interactively than py's `Justfile` recipe behaviour; a fork may want the other default |
| Composing the hint in the adapter | Only the adapter knows the platform, so the hint can be accurate | Platform strings live in the adapter rather than with the error type |

##### Parameters

Owns no repository-wide parameter. **Assumes** `error-taxonomy-exit-codes` as
published by R67 — specifically the `thiserror`-in-library / `anyhow`-in-binary
layering, the `{"error":{"code","message","hint"?}}` envelope with `hint`
omitted when absent, and `RSLB101` → exit `1` as the row this failure maps to —
and `http-transport-injection-seam` as published by R01, for the trait-object
port shape. Also assumes `rust-edition = 2024` and `license = MIT OR Apache-2.0`.
No `CONFLICT:` line: R67's catalogue expresses this failure as it stands, and no
consumed parameter needs to change.

##### Migration implications

New files in the library crate: `crates/rslb-core/src/ports/clipboard.rs` (the
trait, the error, the two test doubles) and a `pub mod clipboard;` line in the
ports module. New file in the binary crate:
`crates/rslbp/src/adapters/clipboard.rs` (the `arboard` adapter, feature-gated).
Edits: the composition root constructs the adapter and hands
`Arc<dyn ClipboardPort>` to the command; the command gains a `copy: bool` field
and the post-sink block above; the error boundary gains one match arm mapping
`ClipboardError` to `RSLB101`. `Cargo.toml` changes are Member 1's. No change to
the library crate's dependencies — `thiserror` is already there by R67.

##### Validation strategy

Planned; nothing here was executed.

1. **Headless degrade, library-level, runs anywhere.** A unit test injecting the
   shipped always-`Unavailable` double: assert the command returns
   `ClipboardError::Unavailable`, that the result value is unchanged, and that
   nothing was written to the captured stdout sink. Expected: passes on
   `macos-latest` and `ubuntu-latest` alike, which is the point of shipping the
   double.
2. **Headless degrade, end-to-end, `ubuntu-latest`.** With `DISPLAY` and
   `WAYLAND_DISPLAY` explicitly unset:
   `env -u DISPLAY -u WAYLAND_DISPLAY timeout 20 rslbp projects --copy > out.txt 2> err.txt; echo $?`
   Expected: exit `1`; `err.txt` contains the message and the hint naming the
   remedy; `out.txt` is byte-identical to the same command run without `--copy`
   (`diff out.txt baseline.txt` empty); `timeout` does not fire, which is the
   assertion that the call does not hang (AC2).
3. **Machine-format envelope.** `… --copy --json 2> err.json`, then
   `jq -e '.error.code == "RSLB101" and (.error.hint | length) > 0' err.json`,
   plus `[ ! -s out.txt ]` for the byte-empty stdout R67 requires on the error
   path (AC3).
4. **Positive path, `macos-latest`.** `rslbp projects --copy > out.txt`, then in
   a *following* step (a separate process, so process exit is exercised)
   `pbpaste \| diff - out.txt` — expected empty, exit `0` (AC1).
5. **Positive path, `ubuntu-latest`, with a real display.** `xvfb-run -a` around
   the same pair. `xvfb` **is** preinstalled on the GitHub Ubuntu 24.04 image
   (version 2:21.1.12-1ubuntu1.6;
   `https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md`,
   retrieved 2026-09-17), so this needs no `apt-get` step. This is the test that
   exercises Member 3 and is spelled out there (AC4).
6. **`--quiet` and stream separation.** `… --copy --quiet 2> err.txt` on a
   machine with a clipboard: expected `err.txt` empty, exit `0`, result on
   stdout. And `… --copy 2>/dev/null \| diff - baseline.txt` empty, proving the
   note never reached stdout.
7. **Feature exclusion.** `cargo tree -e normal -p rslbp --no-default-features`
   shows no `arboard`; `cargo tree -e normal -p rslb-core --all-features` shows
   no `arboard` under any feature combination (AC5, AC6).

Tests 1 and 7 are the two that would have caught the `code2prompt` defect
described in Member 3 if that project had them.

##### Confidence & re-verify trigger

**Confidence: high.** The pattern is ts's, validated in production there, with
one translation repair whose necessity is demonstrated from `arboard`'s source
rather than argued; every rule it leans on is quoted from the binding standard
or from an accepted decision of this programme; and it adds no dependency, so
there is nothing here that can rot on a registry.

The residual uncertainty is entirely in couplings, not in the design.
Re-verify on: **R03** settling the port-absence-versus-failure contract (which
could promote Alternative 2b); **R60** selecting a CLI parser, if its
conventions make a long-only boolean flag awkward — no mainstream Rust parser
does, so this is a formality; **R66** fixing the human rendering of `hint`;
**R05** selecting an async model, which would move the blocking hop into the
adapter without changing the port; a future R67 catalogue append giving clipboard
failures their own code; the owner flipping the fatal-versus-warning policy; and
figure freshness by **2027-03-17**.

##### Sources

- Crate figures: **`inapplicable`** — this member is a pattern and names no package of its own. It uses `thiserror`, whose figures and gates are recorded in the accepted R67 `DECISION.md` (350,390,985 90-day downloads, 2.0.20 of 2026-08-08, MSRV 1.71, MIT OR Apache-2.0, no advisory) and are not re-collected here.
- Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read via `git -C /Users/stevemorin/c/cli-standards show f9de0437baece3383e73ca2c5f48b7ab399b51c7` — R3.4 (short flags; reserved set `-h -V -v -q -o -f -y`), R4.1 (standard options table), R4.4 (`--quiet` scope), R6.1 (exit-code scheme), R6.3 (partial failure → exit 1), R7.1 (stdout/stderr), R7.3 (TTY-aware presentation, not format), R7.6 (error text shape), R7.8 (single-object JSON error schema), R8.2 (non-interactive exit mapping). Retrieved 2026-09-17. A grep of the blob for `clipboard`, `--copy`, `headless`, `DISPLAY`, `X11` and `Wayland` returns no matches — the standard has no clipboard-specific rule, and that absence is why the general rules are applied by their own terms here.
- R67 `DECISION.md` (this repository, owner-accepted) — `error-taxonomy-exit-codes`: the `RSLB101` I/O → exit 1 row, the `{"error":{"code","message","hint"?}}` envelope, `hint` omitted rather than `null`, byte-empty stdout on the error path, and the `thiserror`-library / `anyhow`-binary layering.
- R01 `http-transport-injection-seam` as recorded in `docs/port/PARAMETERS.md` — the `dyn`-compatible trait-object port erased at the composition root, with a shipped in-memory double.
- R06 `DECISION.md` (this repository) — `unsafe_code = "forbid"` in `[workspace.lints.rust]`, first-party crates only.
- `ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`: `src/commands/projects.ts:84` (the `--copy` option), `:190-201` (the wrapped call and `CliError`), `src/lib/adapters.ts:45-53` (`realClipboard` and its headless comment), `docs/port/TS_PORT_DECISIONS.md:167,176` (D-016(7) and its rationale). Read via `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`. Retrieved 2026-09-17.
- `py-launch-blueprint` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and at `f587e48^`: `Justfile:58,562,607-608` (the developer-recipe clipboard command and its `||` degrade) at the pin; `src/py_launch_blueprint/projects.py:390-405` (the unguarded `pyperclip.copy`) at `f587e48^`; commit `f587e48b41bcf6535ba1b62f348147294911c48d` of 2026-06-09 (the removal and its stated reason). Read via `git -C ~/c/py-launch-blueprint show <rev>:<path>`. Retrieved 2026-09-17.
- `arboard` `src/common.rs:20-67` (the `Error` enum, its `#[non_exhaustive]`-ness, the `Unknown { description }` doc comment, and the `std::error::Error` impl) and `src/platform/linux/x11.rs:142-144` (the inaccurate "timed out" message). Via `gh api "repos/1Password/arboard/contents/<path>?ref=v3.6.1"`. Retrieved 2026-09-17.
- `https://rust-lang.github.io/api-guidelines/interoperability.html` — the first-party error-interoperability conventions the port's error shape follows. Retrieved 2026-09-17.

#### Linux selection-ownership helper (probe, then re-exec with a stdin handoff)

##### Landscape

The category is *making a clipboard write outlive the process that made it on
X11 and Wayland*. It exists only on Linux, and it exists for this template only
because Rust links the clipboard API directly where Python and Node shelled out
to binaries that already solved it.

*Bin 1 — built-in or first-party toolchain.* `std::process::Command` with
`std::env::current_exe()`. This is the whole mechanism; no dependency is needed,
and the first-party API is sufficient. Notably, the *other* built-in route —
`libc::fork()` — is not in this bin for this template, for a reason given under
*Fit* below that turns on R06 rather than on taste.

*Bin 2 — established industry standard.* `arboard`'s own
`SetExtLinux::wait()` / `wait_until(Instant)` plus the re-exec pattern its
`examples/daemonize.rs` demonstrates. This is the maintainer-sanctioned answer,
and `code2prompt` is the production instance of it.

*Bin 3 — up-and-comers.* `copypasta-ext`, whose reason for existing is an X11
fork-and-serve extension to `copypasta` — the same idea, packaged. It is
`dormant` (last release 0.4.4, 2023-02-23; `GET https://crates.io/api/v1/crates/copypasta-ext/versions`,
retrieved 2026-09-17) and adds a stale dependency to solve a problem that is
sixty lines of `std`. Also in this bin: relying on a **clipboard manager** being
installed (GNOME's, KDE's Klipper, `clipmenu`, `cliphist`), which `arboard`'s
README names as the thing that sometimes makes a naive copy appear to work —
*"A clipboard manager can make contents available even after a process
previously owning it exits."* That is a property of the user's desktop, not a
design the template can adopt, and treating it as one is how this bug ships
undetected: it works on the developer's machine.

**Authoritative sources.** `arboard`'s `README.md` section *Clipboard Ownership*
and the `SetExtLinux::wait()` doc comment in `src/platform/linux/mod.rs:301-327`
— the maintainer's own statement of the problem and its remedy;
`arboard/examples/daemonize.rs` — the maintainer's own reference shape;
`wl-clipboard-rs` `src/copy.rs:384-393` — proof that the Wayland path does not
escape the problem; `code2prompt`'s `crates/code2prompt/src/clipboard.rs` — the
only production instance of this exact use case I found, and well-regarded on
independent evidence (7,656 stars, `pushed_at` 2026-09-11, not archived,
`gh api repos/mufeedvh/code2prompt`, retrieved 2026-09-17); and the org CLI
Design Standard R5.6 for the argv constraint.

**Practice evidence.** `gh api "search/code?q=SetExtLinux+wait+language:Rust&per_page=20"`
(retrieved 2026-09-17) reports `total_count` **220**. Filtering the first page
for genuine first-party uses rather than vendored copies of `arboard` itself —
five of the twenty hits are `arboard-3.6.1/src/platform/linux/mod.rs` inside
`.cargo/registry` or vendor directories — leaves: `mufeedvh/code2prompt`,
`bitwarden/clients` (`apps/desktop/desktop_native/core/src/clipboard/arboard_backend.rs`),
`ProtonMail/WebClients` (`applications/pass-desktop/native/napi/src/clipboards/linux.rs`),
`qarmin/czkawka`, `qarmin/szyszka`, `codesnap-rs/codesnap`, `kanban-rs/kanban`,
`SergioRibera/sss`, `nik-rev/peashot`, `ideaplexa/voicetypr`. Two password
managers are on that list, which is the strongest available signal that the
ownership problem is real rather than theoretical: Bitwarden and Proton both
carry Linux-specific clipboard code paths.

##### Principles and implementation

The principle is the fourth clause of this item's requirement — *never claim
success it cannot verify* — applied to the one platform where the write is not
synchronous.

The mechanism, stated as four ordered steps because the order is the design:

1. **Probe in the parent.** Call `arboard::Clipboard::new()`. If it returns
   `Err`, no clipboard is reachable: return `ClipboardError::Unavailable` and let
   Member 2's degrade path run. **Drop the probe handle immediately** — it is a
   connection test, not the write.

   *Why a construction-time probe is sufficient, and not merely convenient.* The
   probe only guarantees the child's write if every environmental reason a write
   could fail is already detectable at `Clipboard::new()`. It is, on both Linux
   backends, and this was checked in source rather than assumed. **Wayland:**
   `arboard`'s `wayland::Clipboard::new()` is nothing but a call to
   `wl_clipboard_rs::utils::is_primary_selection_supported()`, propagating its
   error (`src/platform/linux/wayland.rs:96-105`, retrieved 2026-09-17) — and
   that function's error enum carries a dedicated variant whose message is
   *"A required Wayland protocol (ext-data-control, or wlr-data-control version
   1) is not supported by the compositor"*, alongside `NoSeats`,
   `SocketOpenError`, `WaylandConnection` and `WaylandCommunication`
   (`gh api repos/YaLTeR/wl-clipboard-rs/contents/src/utils.rs`, `enum
   PrimarySelectionCheckError` at lines 120-140, `is_primary_selection_supported`
   at 177-204, retrieved 2026-09-17). So a compositor without data-control fails
   **at construction**; `arboard` logs a warning and falls through to X11
   (`src/platform/linux/mod.rs:129-145`), and the X11 attempt then succeeds under
   XWayland or fails at `RustConnection::connect(None)`. **X11:**
   `Clipboard::new()` connects and creates its window before returning
   (`src/platform/linux/x11.rs:914-933`, `:138-144`). Either way the parent
   learns the answer before it spawns anything. Had protocol absence surfaced
   only at `set()`, this member would reproduce on GNOME-without-XWayland exactly
   the false-success defect it charges `code2prompt` with — which is why the
   check was run rather than assumed.
2. **Only on `Ok`, spawn.** `std::process::Command::new(std::env::current_exe()?)`
   with exactly one argument, the hidden `--clipboard-daemon` flag; `stdin`
   piped; `stdout` and `stderr` to `Stdio::null()`.
3. **Hand the payload over stdin.** Write the bytes to the child's stdin and drop
   the handle so the child sees EOF. **Not over `argv`.**
4. **Do not `wait()` on the child.** The parent returns, `main` returns
   `ExitCode`, the child is reparented to PID 1 and keeps serving. Calling
   `child.wait()` would block the CLI forever, because the child blocks by
   design until something else takes the clipboard.

The child's entire job:

    // reached only when the hidden flag is present; short-circuits before any
    // other command parsing or work
    #[cfg(target_os = "linux")]
    fn run_clipboard_daemon() -> Result<(), ClipboardError> {
        use arboard::{Clipboard, LinuxClipboardKind, SetExtLinux};
        use std::io::Read;
        let mut text = String::new();
        std::io::stdin().read_to_string(&mut text)?;
        Clipboard::new()?
            .set()
            .clipboard(LinuxClipboardKind::Clipboard)
            .wait()                       // WaitConfig::Forever
            .text(text)?;
        Ok(())
    }

**Why stdin and not `argv`, stated as a rule rather than a preference.** CLI
Design Standard **R5.6** is unambiguous: *"Secrets (tokens, passwords, keys)
**MUST NOT** be accepted as plain command-line flags or positionals, because
argv is visible in process listings. Accept them via environment variable, a
file path, a credential helper, or stdin."* The payload here is *a command's
result*, which this template cannot promise is secret-free — a `projects` listing
today, an API response containing an identifier tomorrow. Putting it in `argv`
would publish it to every `ps` on the machine for as long as the daemon lives,
which is precisely the lifetime the daemon is designed to maximise. An
environment variable would be nearly as bad (`/proc/<pid>/environ`). Stdin is
the channel the standard names, and it also sidesteps `ARG_MAX`, which a large
result would otherwise hit.

**Why `std::process::Command` and not `libc::fork()`.** A real `fork()` is the
textbook daemonisation primitive and would avoid re-executing the binary. It is
rejected here on a hard constraint, not a soft one: `libc::fork` is an `unsafe
fn`, and R06's accepted decision declares `unsafe_code = "forbid"` in
`[workspace.lints.rust]` — a level that *"a per-site `#[allow]` or `#[expect]`
cannot override"*. Using `fork()` would require changing `forbid` to `deny`
across the whole workspace to accommodate one convenience. Independently, `fork()`
in a process that already has threads is only async-signal-safe for a narrow set
of operations, and by step 1 this process has run a probe that spawned an X11
serving thread. **R06 and correctness agree**, which is the comfortable case:
re-exec is both the permitted design and the right one.

##### Dominant choice

**Probe-then-re-exec with a stdin handoff**, as specified above, `cfg`-gated to
`target_os = "linux"`. On macOS the adapter performs a plain synchronous
`Clipboard::new()?.set_text(text)?` and this member compiles out entirely —
`NSPasteboard` copies the bytes into a system pasteboard server, so there is
nothing to keep alive.

The maintainer's own reference shape, `arboard/examples/daemonize.rs`
(retrieved 2026-09-17), is the skeleton:

    const DAEMONIZE_ARG: &str = "__internal_daemonize";

    fn main() -> Result<(), Box<dyn Error + Send + Sync>> {
        #[cfg(target_os = "linux")]
        if env::args().nth(1).as_deref() == Some(DAEMONIZE_ARG) {
            Clipboard::new()?.set().wait().text("Hello, world!")?;
            return Ok(());
        }
        env_logger::init();
        if cfg!(target_os = "linux") {
            process::Command::new(env::current_exe()?)
                .arg(DAEMONIZE_ARG)
                .stdin(process::Stdio::null())
                .stdout(process::Stdio::null())
                .stderr(process::Stdio::null())
                .current_dir("/")
                .spawn()?;
        } else {
            Clipboard::new()?.set_text("Hello, world!")?;
        }
        Ok(())
    }

Two deliberate departures from it. The example hardcodes its text, so it sets
`stdin` to `Stdio::null()`; the template must pipe. And the example spawns
without probing, which is the defect analysed next.

**The production reference implementation, and the bug it demonstrates.**
`code2prompt`'s `crates/code2prompt/src/clipboard.rs` (retrieved 2026-09-17) is
the closest production analogue of this item that exists, and most of it is
exactly right: the child reads the content from stdin (`std::io::stdin()
.read_to_string(&mut content_from_stdin)`), sets `LinuxClipboardKind::Clipboard`
explicitly rather than relying on the default, and calls `.wait()`. Its module
doc states the principle cleanly: *"On Linux, a background daemon process is
spawned to maintain clipboard content after the main application exits."*

But `spawn_clipboard_daemon` is unconditional:

    let mut child = Command::new(current_exe)
        .args(&args[1..])
        .stdin(Stdio::piped())
        .stdout(Stdio::null())
        .stderr(Stdio::null())
        .spawn()
        .context("Failed to launch clipboard daemon process")?;
    // … write content to child stdin …
    info!("Clipboard daemon launched successfully");
    Ok(())

and `copy_to_clipboard` on Linux is nothing but `spawn_clipboard_daemon(text)`.
The parent never calls `Clipboard::new()`. On a headless Linux machine the spawn
succeeds (the binary exists), the write to the child's stdin succeeds (the pipe
exists), the function returns `Ok(())`, and the CLI reports a successful copy —
while the child's `Clipboard::new()` fails and its error goes to
`Stdio::null()`. **On headless Linux, this implementation silently reports
success and copies nothing.** That is a strictly worse outcome than the crash
this item was chartered to prevent: a crash is visible. It is recorded here with
its source lines because it is the single most valuable thing the best available
reference implementation teaches, and because a template that copies the pattern
without the probe inherits it.

A second, smaller departure: `code2prompt` builds the child's argument list as
`let mut args: Vec<String> = std::env::args().collect(); args.push("--clipboard-daemon");`
and passes `&args[1..]`, re-handing the child every original argument. That works
only because the daemon branch short-circuits first, and it means the payload's
neighbours in `argv` are the user's original flags. The template passes **only**
the hidden flag, which is simpler and keeps `argv` minimal.

**The hidden flag.** `--clipboard-daemon`, hidden from `--help`. It is an
internal re-entry point, not public surface: it takes no user-supplied value,
does nothing a user would invoke deliberately, and reads its input from stdin.
The CLI Design Standard does not forbid hidden flags — R9.2 mandates keeping a
retired name working *"as a hidden alias"*, so hiding is an accepted device —
and R7.5's structured-help requirement is about the commands a user can
meaningfully run. It is documented in `CONTRIBUTING.md` instead of in help. Any
mainstream Rust argument parser supports hiding an argument, so this places no
constraint on R60 beyond "can hide a flag".

##### Qualified shortlist

**3a — probe, spawn, and wait for an acknowledgement (ranked runner-up).**
Identical, plus: the child writes one byte to a pipe after its own
`Clipboard::new()` succeeds, and the parent reads it with a bounded timeout
before reporting success. It closes the residual race that 3 (the
recommendation) accepts — that the display could vanish, or the child fail for
an unrelated reason, between the parent's probe and the child's write — and it
makes the success message literally true rather than true-modulo-a-race. It
costs an extra pipe, a timeout constant, and a decision about what to do when
the timeout fires. Genuinely close; see *Ranked runner-up*.

**3b — `wait_until(Instant::now() + D)` instead of `wait()`.** The daemon
self-terminates after a deadline rather than living until the clipboard is
overwritten. Bounds the worst case (a session where nothing ever takes the
clipboard, so a `wait()` daemon lives until logout) at the cost of the copy
silently expiring — a user who pastes after the deadline gets whatever was
there before. `arboard` exposes both (`SetExtLinux::wait` /
`wait_until`, `src/platform/linux/mod.rs:327,337`), so this is a one-token knob.
Not recommended as the default, because `arboard`'s own documentation explains
the daemon *"will then automatically and silently exit once the user copies
something else to their clipboard so it doesn't take up too many resources"* —
the common case is already self-limiting, and a second `rslbp --copy` displaces
the first daemon. Recorded because the deadline is the right choice for a fork
running in a long-lived kiosk or session-manager context.

**3c — no helper; accept that Linux copies vanish.** One `set_text` call on all
platforms, as the naive implementation would. Rejected: it produces the failure
mode `arboard`'s README opens with — *"values copied to a Linux clipboard with
this crate vanish before anyone gets the chance to paste"* — and it will appear
to work for any developer whose desktop runs a clipboard manager, so the bug
ships. It is listed because it is the design a reviewer will propose as a
simplification, and the answer to that proposal needs to be on record.

**3d — shell out to `xclip`/`wl-copy` on Linux only, `arboard` on macOS.** A
hybrid: use Alternative B exactly where the ownership problem lives, since those
binaries fork. Honestly attractive — it deletes this member entirely. Rejected
for the reasons in Alternative B: `ubuntu-latest` ships none of those tools
(`Ubuntu2404-Readme.md`, retrieved 2026-09-17), so CI gains an `apt-get` step
the recommendation does not need, and the template gains a runtime PATH
dependency on the platform where it also has the most failure modes. It is the
right fallback if `arboard` is ever abandoned, and it is recorded as such in
Member 1's re-verify trigger.

##### Excluded by gate

Gate 1 (licence) — `inapplicable — owner ruling 2026-09-12 (Q7.B)`. This member
adds **no dependency at all**: `std::process`, `std::env`, `std::io` and the
`arboard` already selected by Member 1.

| Gate | Answer |
|---|---|
| 1 licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; no package is introduced |
| 2 MSRV | **`inapplicable` as a separate floor.** Every API used — `std::env::current_exe` (stable since 1.0), `std::process::Command`/`Stdio::piped` (1.0), `std::io::Read::read_to_string` (1.0) — long predates any plausible floor. `arboard::SetExtLinux` carries Member 1's 1.71.0, which is the binding number |
| 3 advisories / `unsafe` | Advisories **`inapplicable`** — no package. **`unsafe` posture: none, and this is load-bearing.** The design uses `std::process::Command` specifically so that no `unsafe` is required; the `libc::fork()` alternative is an `unsafe fn` that R06's workspace-level `unsafe_code = "forbid"` rejects outright |
| 4 OS matrix | **Applies and passes.** `cfg(target_os = "linux")` means the helper compiles on `ubuntu-latest` and compiles *out* on `macos-latest`, where the plain `set_text` branch is used. Both legs build; the `xvfb-run` test under `### Validation strategy` is what exercises the Linux leg |
| 5 default features / async coupling | **None.** No Cargo feature of its own beyond Member 1's `clipboard`; no executor; the child blocks on an OS thread, not a task. Neutral to R05 |
| 6 size / compile cost | **Negligible, unmeasured.** Roughly sixty lines of `std` in one `cfg`-gated module; no proc macro, no new crate, no measurable link-size effect |

Nothing is *excluded* by a gate — the rejections above (3b, 3c, 3d, `libc::fork`,
`copypasta-ext`) are on fitness, the maintenance rubric, or R06, and each is
recorded with its reason rather than folded into a gate it does not belong to.

##### Up-and-comers

None in the design space. The re-exec pattern is settled: `arboard`'s example
has carried it since the crate's early versions and `code2prompt` ships it.
What is genuinely moving is *underneath* the pattern — Wayland's clipboard
protocols. `ext-data-control-v1` is the newer, non-`wlr`-namespaced successor to
`wlr-data-control-unstable-v1`, and `wl-clipboard-rs`'s README already names both
(*"The protocol used for clipboard interaction is `ext-data-control` or
`wlr-data-control`"*, retrieved 2026-09-17). As compositors adopt
`ext-data-control`, `arboard`'s Wayland coverage widens with no change to this
member — the pattern is protocol-agnostic. **Unverified:** the current adoption
state of `ext-data-control` in GNOME/Mutter specifically; see Member 1's
*Recommendation* for the two endpoints I tried and why their answers are not
evidence.

##### Fit for this template

This member is `cfg`-gated to one of the two target OSes, which is unusual for
this template and worth justifying rather than assuming. The justification is
that the *asymmetry is in the platforms, not in the code*: macOS and Windows
copy the bytes into a system-owned store, X11 and Wayland make the copying
process the store. A template that wrote one code path for both would be
choosing between a macOS that spawns a pointless child and a Linux that loses
the copy. The `cfg` is the honest encoding of a real difference, and it is the
kind of thing a template should demonstrate once, well, rather than hide.

For the three shapes: the **library** crate contains none of this (it is in the
binary's adapter, behind Member 2's port); the **CLI** contains all of it; the
**web service** links none of it, because the `clipboard` feature is off in that
build. The hidden `--clipboard-daemon` flag lives in the CLI's argument surface
only.

Against the py and ts precedent, this is the member with **no source-repo
analogue at all** — neither `pyperclip` nor `clipboardy` needed it, because
`xclip`, `xsel` and `wl-copy` each fork on their own behalf. That is the clearest
"justified ecosystem difference" in this item: the same observable behaviour
(*the copy is there after the command exits*) requires code in Rust that requires
none in Python or Node, because the language's approach to the platform API is
different. Preserving the principle **requires** the extra code; porting the
mechanism literally would silently drop the behaviour.

##### Recommendation

Adopt the probe-then-re-exec design with the stdin handoff, `cfg(target_os =
"linux")`, hidden `--clipboard-daemon` flag, `LinuxClipboardKind::Clipboard`
explicit, `SetExtLinux::wait()` in the child, and **no `child.wait()` in the
parent**. On macOS, a plain synchronous `set_text`. Document the daemon in
`CONTRIBUTING.md` and in the `--copy` flag's help text (one clause: on Linux the
copy is served by a short-lived background helper).

The probe is the non-negotiable part. It is what converts a silent lie on
headless Linux into Member 2's clean degrade, and it is the specific thing the
best available reference implementation gets wrong.

##### Ranked runner-up

**3a — probe, spawn, and wait for an acknowledgement byte.** Ranked first among
the alternatives because it strictly dominates the recommendation on
correctness: it closes the probe-to-write race, and it lets the success message
be unconditionally true. It is not the recommendation for two reasons, both
about a template rather than about correctness in the abstract. First, it
introduces a timeout constant that has no principled value — too short and a
loaded machine reports a false failure, too long and the CLI hangs after the
result has already been printed, and neither failure is one a template author
can tune for a user's machine. Second, the race it closes is narrow: the window
is the few milliseconds between the parent's successful `Clipboard::new()` and
the child's, during which the display server would have to disappear. The
recommendation accepts that window and says so in this report rather than
leaving it undocumented, which is the honest trade. **3a becomes the right
choice if the owner wants the fatal-versus-warning policy inverted** — a warning
policy needs to know reliably whether the copy happened, where a fatal policy
mostly needs to know that it *could* happen.

Ranked after it: **3b** (`wait_until` deadline) for long-lived-session forks,
then **3d** (Linux shell-out) as the fallback if `arboard` is abandoned, then
**3c** (no helper), which is not really a candidate so much as the bug.

##### Tradeoffs

| Tradeoff | For the recommendation | Against |
|---|---|---|
| Probe before spawn | Headless Linux degrades cleanly instead of reporting a false success; CI never spawns an orphan child | Two `Clipboard::new()` calls on the happy path, and a narrow race between them |
| Re-exec versus `libc::fork()` | No `unsafe`, so R06's `forbid` stands unchanged; safe in the presence of the probe's serving thread | Re-executes the binary (one extra `exec`), and needs a hidden flag in the CLI surface |
| stdin versus `argv` for the payload | R5.6 compliance; no `ps` exposure for the daemon's lifetime; no `ARG_MAX` ceiling | A pipe and an EOF to get right; slightly more code than `.arg(text)` |
| `wait()` (forever) versus `wait_until(deadline)` | Matches `arboard`'s example and `code2prompt`; self-limiting because the next copy displaces the daemon | A daemon can outlive the session if nothing ever takes the clipboard |
| Not calling `child.wait()` | The CLI returns immediately, as a CLI must | The child is reparented to PID 1; a reader of the code must be told why the missing `wait()` is deliberate, so it needs a comment |
| `cfg(target_os = "linux")` | Encodes a real platform asymmetry once, visibly | Two code paths to test, and only one runner exercises each |

##### Parameters

Owns no repository-wide parameter. **Assumes** `target-os-matrix = ubuntu-latest,
macos-latest` (the `cfg` split is written against exactly these two legs; adding
`windows-latest` would add a third branch that needs no helper, since the Win32
clipboard is kernel-managed), R06's `unsafe_code = "forbid"` (which selects
re-exec over `fork`), and Member 1's `arboard` selection. Relies on R60's parser
being able to hide a flag, which every mainstream Rust parser can — recorded as
an assumption, not a `CONFLICT:`. No `CONFLICT:` line.

##### Migration implications

One new `cfg`-gated module in the binary crate,
`crates/rslbp/src/adapters/clipboard_linux.rs`, containing the probe, the spawn
and the daemon entry point. One hidden argument in the CLI's argument
definition, and one early branch in `main` that dispatches to the daemon entry
point before any other work. One clause added to `--copy`'s help text. One
section in `CONTRIBUTING.md` explaining the helper, why the missing
`child.wait()` is deliberate, and why the payload travels over stdin. No new
dependency, no `Cargo.toml` change beyond Member 1's, nothing in the library
crate.

##### Validation strategy

Planned; nothing here was executed. Tests 2 and 3 are the ones that distinguish
this member from the `code2prompt` shape, and neither exists in that project.

1. **Persistence, `ubuntu-latest`, real display (AC4).** Inside one
   `xvfb-run -a bash -c '…'`: run `rslbp projects --copy > out.txt`, let the
   process exit, then in a *separate* process read the selection back and
   compare. Reading it back without adding a dependency can be done with a
   second invocation of the template's own binary if a paste path exists, or
   with `xclip -selection clipboard -o` after an `apt-get install -y xclip`
   confined to this test step. `xvfb` itself needs no install — it is
   preinstalled on the GitHub Ubuntu 24.04 image at 2:21.1.12-1ubuntu1.6
   (`https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md`,
   retrieved 2026-09-17). Expected: the read-back equals `out.txt`. **A naive
   implementation without this member fails exactly here and passes everything
   else**, which is why this test is the member's reason for existing.
2. **No false success when headless (the `code2prompt` defect).** With `DISPLAY`
   and `WAYLAND_DISPLAY` unset: `env -u DISPLAY -u WAYLAND_DISPLAY rslbp projects --copy; echo $?`
   Expected exit `1` and the degrade diagnostic on stderr. Paired assertion that
   makes it a real test of *this* member rather than of Member 2: immediately
   afterwards, `pgrep -f -- '--clipboard-daemon'` must find **nothing** — proving
   the parent probed and declined to spawn, rather than spawning a child that
   died quietly.
3. **No payload in `argv` (R5.6).** Under `xvfb-run`, copy a distinctive
   sentinel string, then while the daemon is alive run
   `ps -ww -o args= -p "$(pgrep -f -- '--clipboard-daemon')"` and assert the
   sentinel does **not** appear, and that the command line is the binary plus the
   single hidden flag.
4. **No hang.** Every invocation above runs under `timeout 20`; the assertion is
   that `timeout` never fires, on both the headless and the `xvfb` legs.
5. **Hidden flag is hidden.** `rslbp projects --help \| grep -c -- '--clipboard-daemon'`
   expected `0`, and `rslbp --help` likewise; the flag works when passed
   explicitly.
6. **macOS compiles the helper out.** `cargo build` on `macos-latest` with
   `-D warnings`; expected clean, with the Linux module gated out. Combined with
   AC1's `pbpaste` round-trip in a following step, this covers the macOS leg.

##### Confidence & re-verify trigger

**Confidence: high on the diagnosis, medium-high on the recommended shape.**
High on the diagnosis because it is stated by the crate's own maintainers in two
places, confirmed in the source of both the X11 backend
(`std::thread::spawn` at `src/platform/linux/x11.rs:925`) and the Wayland
backend (`Options::foreground(matches!(wait, WaitConfig::Forever))` at
`src/platform/linux/wayland.rs:126`), and independently corroborated by two
password managers carrying Linux-specific clipboard code. Medium-high on the
shape because the probe-then-spawn ordering, while clearly better than the only
production reference I could find, has **no** production instance I can point
to — I searched (`gh api "search/code?q=SetExtLinux+wait+language:Rust"`,
`total_count` 220, first page reviewed) and found the pattern used ten times and
probed zero times. **That is an evidence gap and it is stated as one rather than
papered over**: the recommendation is reasoned from the platform semantics and
from a defect analysis of the best available reference, not from an existing
implementation that does it this way. Alternative 3a would close the gap
differently, by making the success claim verifiable instead of probable.

Nothing in this member was compiled or run. The persistence behaviour in
particular is asserted from `arboard`'s and `wl-clipboard-rs`'s documentation
and source, not observed — I have no headless Linux environment in this run, and
the run constraint forbids creating a Cargo project to test one. Validation test
1 is the check that would confirm it.

Re-verify on: `arboard` gaining a first-party daemonisation helper, which would
replace this member with a call (watch its `CHANGELOG` and
`examples/daemonize.rs` at each release); `wl-clipboard-rs` changing
`foreground`'s semantics from a thread to a forked process, which would make the
Wayland path self-sufficient; a Wayland clipboard protocol that transfers
ownership to the compositor, which would end the problem on that half of Linux;
`target-os-matrix` gaining `windows-latest` (no helper needed, but a third branch
appears); R60 selecting a parser that cannot hide an argument; the owner
inverting the fatal-versus-warning policy, which promotes Alternative 3a; and
figure freshness by **2027-03-17**.

##### Sources

- Crate figures: **`inapplicable`** — this member is a pattern and introduces no package. The `arboard` figures that bound it are in Member 1; `copypasta-ext`, considered and rejected in bin 3, is at 38,694 90-day / 476,609 all-time downloads with last release 0.4.4 of 2023-02-23 (`GET https://crates.io/api/v1/crates/copypasta-ext` and `/versions`, retrieved 2026-09-17).
- `arboard` `README.md`, section *Clipboard Ownership* — the selection-ownership statement, the clipboard-manager caveat, and the guidance to use `wait` or keep the `Clipboard` alive. Via `gh api repos/1Password/arboard/contents/README.md`. Retrieved 2026-09-17.
- `arboard` `src/platform/linux/mod.rs:120-146` (backend selection and the `WAYLAND_DISPLAY` test), `:209-221` (`WaitConfig`), `:300-389` (`SetExtLinux`, the `wait()` doc comment quoted in `### Principles and implementation`, `wait_until` at `:337`, and the `impl`). Retrieved 2026-09-17.
- `arboard` `src/platform/linux/x11.rs:914-933` (`Clipboard::new`, the `std::thread::spawn` serving thread) and `:138-144` (`RustConnection::connect(None)` and the inaccurate error text). Retrieved 2026-09-17.
- `arboard` `src/platform/linux/wayland.rs:96-105` (`Clipboard::new`, the `is_primary_selection_supported()` probe) and `:118-126` (`set_text` and `Options::foreground(matches!(wait, WaitConfig::Forever))`). Retrieved 2026-09-17.
- `arboard` `examples/daemonize.rs` — the maintainer's reference re-exec shape, quoted in full above. Via `gh api repos/1Password/arboard/contents/examples/daemonize.rs`. Retrieved 2026-09-17.
- `wl-clipboard-rs` `src/copy.rs:384-393` — `foreground` documented as *"the flag for not spawning a separate thread for serving copy requests"*, and `serve_requests`; `README.md` — the `ext-data-control`/`wlr-data-control` requirement and the "100% safe Rust" statement. Via `gh api repos/YaLTeR/wl-clipboard-rs/contents/<path>`. Retrieved 2026-09-17.
- `mufeedvh/code2prompt` `crates/code2prompt/src/clipboard.rs` (all 129 lines read: `serve_clipboard_daemon`, `spawn_clipboard_daemon`, both `copy_to_clipboard` arms) and `crates/code2prompt/Cargo.toml`; repository metadata `gh api repos/mufeedvh/code2prompt` → 7,656 stars, `pushed_at` 2026-09-11T18:23:57Z, `archived` false. Retrieved 2026-09-17.
- `GET https://api.github.com/search/code?q=SetExtLinux+wait+language:Rust&per_page=20` — `total_count` 220; first page enumerated in `##### Landscape`. Retrieved 2026-09-17.
- Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` — **R5.6** (secrets must not be passed in argv; stdin is a named channel), R7.5 (structured help), R9.2 (hidden aliases are an accepted device). Retrieved 2026-09-17.
- R06 `DECISION.md` (this repository) — `unsafe_code = "forbid"` in `[workspace.lints.rust]`, which *"a per-site `#[allow]` or `#[expect]` cannot override"*; the basis for rejecting `libc::fork()`.
- `https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md` — `xvfb` 2:21.1.12-1ubuntu1.6 preinstalled; no `xclip`, `xsel` or `wl-clipboard` entry. Retrieved 2026-09-17.

### Compatibility

The three members are not three independently chosen things that have to be
shown to coexist; two of them are patterns written against the third, and the
third is the only package. What still needs proof is that the **configuration**
of Member 1 recommended here is a configuration real projects ship, and that the
Linux pattern is exercised against that configuration rather than against
`arboard`'s defaults.

**Shared adopters, with their exact lines.** Three active, well-regarded
projects ship the recommended dependency configuration, and one of them also
ships the Linux pattern.

| Project | `arboard` configuration | Linux ownership pattern | Source (retrieved 2026-09-17) |
|---|---|---|---|
| `nushell/nushell` (`nu-command`) | `arboard = { version = "3.6.0", default-features = false, features = ["wayland-data-control"] }` | n/a — a long-lived shell process, so ownership is not a problem for it | `gh api repos/nushell/nushell/contents/crates/nu-command/Cargo.toml` |
| `nushell/reedline` | `arboard = { version = "3.3.0", optional = true, default-features = false, features = ["wayland-data-control"] }` behind a `system_clipboard` feature | n/a — same reason; note the **optional + feature-gated** shape this stack also uses | `gh api repos/nushell/reedline/contents/Cargo.toml` |
| `mufeedvh/code2prompt` | `arboard = { workspace = true }`, with `wayland = ["arboard/wayland-data-control"]` | **Yes** — `SetExtLinux::wait()` in a re-exec'd child with a stdin handoff | `gh api repos/mufeedvh/code2prompt/contents/crates/code2prompt/Cargo.toml` and `…/crates/code2prompt/src/clipboard.rs` |

`code2prompt` is the compatibility proof that matters: it is a short-lived CLI
running Members 1 and 3 together in production, on the same
`wayland-data-control` configuration. The template departs from it in exactly one
respect — the probe in step 1 — and that departure adds a call to an API
`code2prompt` already uses (`Clipboard::new()`), so it cannot break the
combination.

**Version matrix.** The pieces compose because two of them are `arboard`'s own
public API and the third is `std`.

| Member | Version / API surface it needs | Where that comes from |
|---|---|---|
| 1 `arboard` | 3.6.1, `default-features = false`, `wayland-data-control` | crates.io; `rust-version = "1.71.0"`, licence `MIT OR Apache-2.0` |
| 2 `ClipboardPort` | `arboard::Error: std::error::Error` (`src/common.rs:67`); no other `arboard` API. Plus `thiserror`, already in the tree by R67 | `arboard` 3.x public API, stable across the 3 series |
| 3 Linux helper | `arboard::{SetExtLinux, LinuxClipboardKind}`, `Set::wait()`, `Set::clipboard()`, `Set::text()`; `std::process::Command`, `std::env::current_exe` | `arboard` 3.x public API (`SetExtLinux` is re-exported from the crate root, `src/lib.rs:28`); `std` since 1.0 |

The only version coupling is that Members 2 and 3 need `arboard` 3.x; both
`reedline` (3.3.0) and `nu-command` (3.6.0) demonstrate that the surfaces they
use are stable across that range.

**MSRV compatibility across the stack.** Highest declared `rust-version` in the
resolved-as-recommended set is **1.71.0** (`arboard` itself, and the `objc2`
family, `parking_lot` and `log`), against the 1.96 floor R67 recorded from its
own executed resolution. Members 2 and 3 declare none of their own and use only
long-stable `std`. *Caveat, stated because it is a real limit of this report:*
this is a check of declared floors read from the registry, **not** a resolved
lockfile — no Cargo project was created, so no `cargo tree`, `cargo tree -d` or
`cargo audit` was executed. `### Validation strategy` steps 1–5 are the planned
checks that would convert this into an executed result.

**What is not proven.** No combination was built or run anywhere in this report.
The compatibility evidence above is adopter manifests plus API-surface reading,
which is strong for "these versions work together" and silent on "this template's
particular composition compiles" — a question only P03 can close.

### Parameters

This item owns no repository-wide parameter. `research/CLAUDE.md` records R62's
`owns` column as `—`, and nothing in this recommendation needs a new one: the
crate choice, the port shape and the Linux helper are all internal to the
template rather than values other items must consume.

**Owned parameters.** None.

**Assumed parameters** (all consumed at their published values; none needs to
change):

- assumes `rust-edition` = `2024` — `arboard` 3.6.1 is itself edition 2021,
  which a 2024 workspace consumes without friction because editions are
  per-crate; the template's own clipboard code is edition 2024.
- assumes `msrv-policy` = `stable minus 2 minor versions, raised only in a minor
  release, declared as rust-version in Cargo.toml and tested in CI` — satisfied
  with wide headroom; highest declared floor in the recommended set is 1.71.0.
- assumes `license` = `MIT OR Apache-2.0` — gate 1 is
  `inapplicable — owner ruling 2026-09-12 (Q7.B)` and nothing was excluded on
  licence; recorded for completeness, `arboard` declares exactly this string.
- assumes `target-os-matrix` = `ubuntu-latest, macos-latest` — both legs build;
  Member 3's `cfg` split is written against exactly these two.
- assumes `error-taxonomy-exit-codes` = `error-contract/v1` as published by R67 —
  specifically the `RSLB101` I/O → exit `1` row, the
  `{"error":{"code","message","hint"?}}` envelope with `hint` omitted rather than
  `null` and stdout byte-empty on the error path, and the
  `thiserror`-in-library / `anyhow`-in-binary layering.
- assumes `http-transport-injection-seam` as published by R01 — the
  `dyn`-compatible trait-object port erased at the composition root, with a
  shipped in-memory double; Member 2's `ClipboardPort` is that shape applied to
  a second driven-I/O boundary.

**Conflict lines: none.** R67's catalogue expresses this item's only failure mode
as it stands (`RSLB101` → exit `1`; the reasoning, including why `RSLB102`,
`RSLB201` and `RSLB205` do not fit, is in `### Principles and implementation`),
so no row needs to change and no value of any consumed parameter needs to move.

**Not a parameter, but a coupling worth recording for the synthesiser:** R03
(`port-absence-vs-failure-contract`) is unresolved and, if it settles toward
modelling absence as a value rather than an error, would promote Member 2's
Alternative 2b. That is a design coupling, not a parameter conflict.

### Migration implications

Every change is an addition; the Rust template does not exist yet and P03 builds
it. Listed by file so the implementation plan can consume it directly.

**Library crate (`crates/rslb-core`)**

| File | Change |
|---|---|
| `src/ports/clipboard.rs` | **New.** `pub trait ClipboardPort: Send + Sync` with `fn write_text(&self, text: &str) -> Result<(), ClipboardError>`; `pub enum ClipboardError { Unavailable { #[source] .. }, WriteFailed { #[source] .. } }` deriving `thiserror::Error`; two shipped test doubles — a recording implementation and one that always returns `Unavailable` |
| `src/ports/mod.rs` | One `pub mod clipboard;` line |
| `Cargo.toml` | **No change.** `thiserror` is already a dependency by R67; `arboard` must never appear here, and AC6 tests that |

**Binary crate (`crates/rslbp`)**

| File | Change |
|---|---|
| `Cargo.toml` | `arboard = { version = "3.6.1", default-features = false, features = ["wayland-data-control"], optional = true }`; `[features] default = ["clipboard"]`, `clipboard = ["dep:arboard"]` |
| `src/adapters/clipboard.rs` | **New**, `#[cfg(feature = "clipboard")]`. `pub struct SystemClipboard` implementing `ClipboardPort`; macOS branch does a synchronous `Clipboard::new()?.set_text(text)?`; Linux branch delegates to the module below; classifies a `Clipboard::new()` failure as `Unavailable` and a `set_text` failure as `WriteFailed`; composes the per-platform hint; never matches on `arboard`'s message text |
| `src/adapters/clipboard_linux.rs` | **New**, `#[cfg(all(feature = "clipboard", target_os = "linux"))]`. The probe, the `Command::new(current_exe())` spawn with the hidden flag and piped stdin, and `run_clipboard_daemon()` reading stdin and calling `.set().clipboard(LinuxClipboardKind::Clipboard).wait().text(..)`. Carries the comment explaining why the parent deliberately does not `child.wait()` |
| CLI argument definition (R60's file) | `--copy` on the result-emitting command: boolean, long form only, no short flag, help text noting that on Linux a short-lived background helper serves the copy. Plus the hidden `--clipboard-daemon` flag |
| `src/main.rs` | An early branch dispatching to `run_clipboard_daemon()` when the hidden flag is present, before any other work; the composition root constructing `SystemClipboard` and handing `Arc<dyn ClipboardPort>` to the command |
| The command's handler | A `copy: bool` field, and the post-sink block: write the result to its sink first, then `clipboard.write_text(&result)?`, then the stderr note unless `--quiet` |
| The error boundary | One match arm mapping `ClipboardError` to `RSLB101` → `Exit(1)`, with the hint carried into the envelope's `hint` key |

**Web surface.** Nothing. The `clipboard` feature is off in that build, so no
file, dependency or flag from this item enters it — and AC5 tests it.

**Documentation**

| File | Change |
|---|---|
| `README.md` / the CLI's example doc | `--copy` in the flag list, with the headless caveat |
| `CONTRIBUTING.md` | A short section on the Linux helper: why it exists (selection ownership), why the payload travels over stdin (R5.6), why `child.wait()` is absent, and how to run the `xvfb-run` test locally |
| Wherever extension points are listed | OSC 52 recorded as a deliberate non-adoption with its reason, so a future contributor does not re-derive the analysis |

**CI (`ci-job-structure`, owned by the unresolved R11 — wire per its shape)**

| Leg | Addition |
|---|---|
| `macos-latest` | The AC1 pair: `rslbp … --copy > out.txt`, then a *following step* running `pbpaste \| diff - out.txt` |
| `ubuntu-latest` | The AC2/AC3 headless assertions (no display, exit 1, envelope under `--json`, stdout unchanged, `timeout` does not fire, no `--clipboard-daemon` process left behind) |
| `ubuntu-latest` | The AC4 persistence test under `xvfb-run -a`. `xvfb` is preinstalled on the image; only the read-back tool, if `xclip` is chosen for it, needs an `apt-get` confined to that step |

### Validation strategy

Everything below is **planned**. Nothing in this report was compiled, built or
executed: the run constraint is to write exactly one file and not to scaffold,
so there is no Cargo project, no lockfile and no test run behind any of it. What
*was* executed is evidence collection — registry and GitHub REST queries,
RustSec probes, and reads of pinned repository contents — and those results are
reported as retrieved figures throughout, each with its endpoint and date.

**Tier A — the principle holds (the checks that would fail on a wrong answer).**

| # | Command | Expected | Proves |
|---|---|---|---|
| A1 | `rslbp projects --copy > out.txt` on `macos-latest`, then in a **separate following step** `pbpaste \| diff - out.txt` | empty diff, exit `0` | AC1: the copy happens and survives process exit on macOS |
| A2 | `env -u DISPLAY -u WAYLAND_DISPLAY timeout 20 rslbp projects --copy > out.txt 2> err.txt; echo $?` on `ubuntu-latest` | exit `1`; `err.txt` names the cause and a next step; `diff out.txt baseline.txt` empty; `timeout` does not fire | AC2: clean degrade, result unharmed, no hang, no panic |
| A3 | `… --copy --json 2> err.json > out.txt`, then `jq -e '.error.code == "RSLB101" and ((.error.hint \| length) > 0)' err.json` and `[ ! -s out.txt ]` | both succeed | AC3: R67's envelope, byte-empty stdout on the error path |
| A4 | `xvfb-run -a bash -c 'rslbp projects --copy > out.txt'` then, **after that process has exited**, read the selection back in a new process and compare | read-back equals `out.txt` | AC4: selection ownership is actually solved — the one check a naive implementation fails while passing every other |
| A5 | `pgrep -f -- '--clipboard-daemon'` immediately after A2 | no match | the parent probed and declined to spawn, rather than spawning a child that died silently — the `code2prompt` defect |
| A6 | Under `xvfb-run`, copy a sentinel, then `ps -ww -o args= -p "$(pgrep -f -- '--clipboard-daemon')"` | the sentinel does **not** appear; the command line is the binary plus the single hidden flag | R5.6: the payload is never in `argv` |

**Tier B — structural checks.**

| # | Command | Expected |
|---|---|---|
| B1 | `cargo tree -e normal -p rslbp --no-default-features` | no `arboard` line (AC5) |
| B2 | `cargo tree -e normal -p rslb-core --all-features` | no `arboard` line under any feature combination (AC6) |
| B3 | `cargo tree -e normal -p rslbp` on each runner | `arboard v3.6.1`; `objc2-app-kit` on macOS; `x11rb` **and** `wl-clipboard-rs` on Linux; **no `image`** on either |
| B4 | `cargo tree -p rslbp -d` | empty — no duplicate resolutions, the same control R67 ran against its own set |
| B5 | `cargo +1.<floor> check -p rslbp` at the MSRV leg the CI matrix already runs | success — converts the declared-floor reading above into an executed result |
| B6 | `cargo audit` on the committed lockfile, **paired** with R67's established positive control (`anyhow = "=1.0.102"` must reproduce RUSTSEC-2026-0190) | no findings for `arboard` or its subtree, and the control fires — so a clean run is evidence the tool works rather than evidence it is silent |
| B7 | `cargo clippy --all-targets -- -D warnings` on both runners, with `unsafe_code = "forbid"` in effect | clean; confirms the clipboard code contains no `unsafe` and that R06's policy is unbroken by this item |

**Tier C — behavioural detail.**

| # | Command | Expected |
|---|---|---|
| C1 | Unit test injecting the shipped always-`Unavailable` double | the command returns `ClipboardError::Unavailable`, the result value is unchanged, the captured stdout sink is untouched — and it passes on **both** runners, which is the point of shipping the double |
| C2 | `… --copy --quiet 2> err.txt` on a machine with a clipboard | `err.txt` empty, exit `0`, result on stdout (R4.4) |
| C3 | `… --copy 2>/dev/null \| diff - baseline.txt` | empty — the success note never reached stdout (R7.1) |
| C4 | `rslbp projects --copy \| cat` with stdout piped | the copy still happens — `--copy` is a requested action, not a TTY-gated presentation nicety (R7.3) |
| C5 | `rslbp projects --help \| grep -c -- '--clipboard-daemon'` and `rslbp --help \| grep -c -- '--clipboard-daemon'` | `0` for both; the flag still works when passed explicitly |
| C6 | `cargo build --release --timings` and `ls -l target/release/rslbp`, with and without `--no-default-features`, on both runners | replaces gate 6's qualitative statement with a measured number |

**Which checks would catch which mistake**, since that is what makes the list
worth running rather than long: A4 alone catches a missing Member 3; A5 alone
catches the `code2prompt` false-success defect; A2 catches a forwarded,
inaccurate `arboard` message and a panicking `unwrap`; B1/B2 catch a library
crate or web build that accidentally links a desktop dependency; B3 catches a
forgotten `default-features = false`; C4 catches a `--copy` wrongly gated on
`IsTerminal`.

### Confidence & re-verify trigger

**Overall confidence: high on the crate and the pattern, medium-high on the
Linux helper's exact shape, and explicitly bounded by the fact that nothing was
executed.**

*High* on Member 1. Three independent, active, well-regarded projects ship the
exact dependency line recommended; the download and reverse-dependency margins
over the runner-up are roughly 15× and larger; every fitness gate is answered
from a primary source rather than from reputation; and the runner-up's own
Wayland substrate documents itself as built for windowed applications, which
this template is not.

*High* on Member 2. It is ts's design, validated in production there, carried
across with one repair whose necessity is shown from `arboard`'s source rather
than argued; it adds no dependency; and every rule it leans on is quoted from
the binding standard or from an accepted decision of this programme.

*Medium-high* on Member 3, for one reason stated plainly rather than hedged:
the **probe-before-spawn ordering has no production instance I could find**. I
searched (`gh api "search/code?q=SetExtLinux+wait+language:Rust"`, `total_count`
220, first page reviewed and classified) and found the re-exec pattern used ten
times and probed zero times; the closest production analogue, `code2prompt`,
demonstrably gets it wrong in a way that silently reports success on headless
Linux. The recommendation is therefore reasoned from documented platform
semantics plus a defect analysis, not copied from a working example. The
diagnosis it rests on — that a Linux copy dies with the process — is *high*
confidence, being stated by the maintainers in two places and visible in both
backends' source. One thing that could have sunk the design is now closed rather
than assumed: the probe's **sufficiency** is verified in source on both Linux
backends, because Wayland protocol absence surfaces at `Clipboard::new()` via
`is_primary_selection_supported()`'s `MissingProtocol` variant rather than at
`set()` (see `##### Principles and implementation`, step 1).

*Bounded throughout* by execution: no Cargo project was created, nothing was
compiled, no test was run, and I have no headless Linux environment in this
session. Every behavioural claim about `arboard` is read from its source,
documentation or CI configuration at tag `v3.6.1`, and every MSRV number is a
declared floor read from the registry rather than a resolved lockfile.

**Re-verify on any of the following.**

*Crate and ecosystem.* A crates.io release after `arboard` 3.6.1 — re-read the
changelog for Linux-ownership or `wayland-data-control` changes and re-run
`### Validation strategy` tier B. A RustSec advisory against `arboard`, `x11rb`,
`wl-clipboard-rs` or the `objc2` family. `arboard` going quiet — `pushed_at`
static for six months *while* no release lands would convert the current
release-cadence note into an `at-risk` signal, and the fallback is Alternative B
(shell-out), not `copypasta`. `arboard` enabling `wayland-data-control` by
default, or gaining a first-party daemonisation helper, either of which
simplifies this stack. `1Password/arboard` becoming archived or a maintainer
notice appearing. `wl-clipboard-rs` changing `foreground` from a thread to a
forked process, which would make the Wayland half self-sufficient.

*This programme.* **R03** settling the port-absence-versus-failure contract,
which could promote Member 2's Alternative 2b. **R60** selecting a CLI parser —
a formality, since every mainstream Rust parser can hide a flag and host a
long-only boolean, but the assumption should be restated against the chosen one.
**R66** fixing how `hint` renders in human output. **R05** and **R69** selecting
an execution model — no coupling is expected, the `arboard` API being fully
synchronous, but the adapter is where a blocking hop would go. **R11** fixing
`ci-job-structure`, which determines how the three CI additions are wired. A
future R67 catalogue append giving clipboard failures a dedicated code.

*Owner decisions.* Inverting the fatal-versus-warning policy on a failed copy,
which promotes Member 3's Alternative 3a (acknowledgement byte) because a warning
policy needs to know reliably whether the copy happened. `target-os-matrix`
gaining `windows-latest`, which brings `clipboard-win`'s BSL-1.0 into a supported
leg and adds a third `cfg` branch that needs no helper.

*Unverified items to close.* Whether GNOME/Mutter implements `ext-data-control`
at the version Ubuntu ships — it bounds how often the XWayland fallback is the
live path on a desktop Linux machine, though it changes nothing on `ubuntu-latest`,
which has no compositor at all.

*Failing all of the above,* figure freshness by **2027-03-17**.

### Sources

Every URL below was retrieved **2026-09-17** (UTC) unless stated otherwise.
Repository files in `py-launch-blueprint` and `ts-launch-blueprint` were read
**through their programme pins**, never from a working tree, as the role file
requires; each such line names the pin and the commit its claim comes from.

**Registry figures — `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`) and `/versions` (newest non-yanked `num`, `created_at`, `rust_version`, `license`)**

| Crate | 90-day | All-time | Last release | Declared MSRV | Licence |
|---|---|---|---|---|---|
| `arboard` | 12,957,229 | 46,174,781 | 3.6.1, 2025-08-23T20:19:03Z | 1.71.0 | MIT OR Apache-2.0 |
| `copypasta` | 857,282 | 5,559,318 | 0.10.2, 2025-04-25T12:50:12Z | 1.71.0 | MIT / Apache-2.0 |
| `clipboard-win` | 14,919,611 | 58,832,374 | 5.4.1, 2025-07-17T23:38:58Z | none | BSL-1.0 |
| `x11rb` | 17,870,431 | 62,742,602 | 0.14.0, 2026-07-16 (`arboard` pins 0.13; 0.13.2 of 2025-08-29, MSRV 1.64) | 1.68 (0.14) | MIT OR Apache-2.0 |
| `wl-clipboard-rs` | 5,563,908 | 14,218,368 | **see note** | none | MIT/Apache-2.0 |
| `smithay-clipboard` | 4,978,379 | 23,223,701 | 0.7.3 | — | — |
| `objc2-app-kit` | 23,278,732 | 57,933,236 | 0.3.2, 2025-10-04 | 1.71 | Zlib OR Apache-2.0 OR MIT |
| `cli-clipboard` | 157,301 | 865,092 | 0.4.0, 2022-12-13T01:31:14Z | none | MIT / Apache-2.0 |
| `copypasta-ext` | 38,694 | 476,609 | 0.4.4, 2023-02-23T09:00:02Z | none | MIT / Apache-2.0 |
| `terminal-clipboard` | 7,453 | 82,190 | 0.4.1, 2023-10-31T09:33:26Z | none | MIT |
| `clipboard` (`rust-clipboard`) | 107,484 | 1,758,083 | 0.5.0, 2018-09-22T21:58:38Z | none | MIT / Apache-2.0 |
| `osc52` | 24 | 1,528 | 0.1.0, 2023-08-11T21:01:47Z | none | — |
| `image` (dropped by `default-features = false`) | — | — | 0.25.10, 2026-03-10 | **1.88.0** | MIT OR Apache-2.0 |

**Note on `wl-clipboard-rs`, recorded rather than smoothed over.** The figure
rule says "newest with `yanked: false`: `num`, `created_at`". Applying it
literally to this crate gives **0.8.2 with `created_at` 2026-05-07T14:35:28Z**,
because several old versions (0.8.2, 0.7.1, 0.6.1, 0.4.2) all carry identical
`created_at` timestamps of 2026-05-07, which is a registry backfill artifact and
not a release event. The crate's `max_stable_version` is **0.9.3**, whose
`created_at` is **2025-12-13T08:05:19Z**, and `arboard` 3.6.1 depends on
`wl-clipboard-rs = "0.9.3"`. The substantive last release is therefore
**0.9.3, 2025-12-13**; both readings are recorded so the anomaly is visible to
the synthesiser rather than silently resolved.

**GitHub REST — `GET https://api.github.com/repos/<o>/<r>` and `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`**

| Repository | Stars | Archived | `pushed_at` | Open issues (search `total_count`) |
|---|---|---|---|---|
| `1Password/arboard` | 967 | false | 2026-09-16T16:54:50Z | 19 |
| `alacritty/copypasta` | 350 | false | 2025-05-09T16:33:48Z | 5 |
| `YaLTeR/wl-clipboard-rs` | 514 | false | 2026-06-11T06:00:43Z | 9 |
| `quininer/x11-clipboard` | 54 | false | 2026-06-19T04:34:42Z | 13 |
| `DoumanAsh/clipboard-win` | 74 | false | 2025-12-07T07:15:20Z | 3 |
| `Canop/terminal-clipboard` | 11 | false | 2023-10-31T09:32:41Z | 6 |
| `allie-wake-up/cli-clipboard` | 24 | false | 2024-05-30T09:41:15Z | 8 |
| `mufeedvh/code2prompt` | 7,656 | false | 2026-09-11T18:23:57Z | — (adopter evidence, not a candidate) |

The crates.io `repository` field for `cli-clipboard` points at
`actuallyallie/cli-clipboard`; the search endpoint returned HTTP **422**
(*"the resources do not exist or you do not have permission to view them"*)
against that name, and `GET https://api.github.com/repos/actuallyallie/cli-clipboard`
resolves to `allie-wake-up/cli-clipboard`. The rename is recorded because it is
the kind of stale-metadata signal the maintenance rubric is meant to surface.

**Issue responsiveness.** `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=100`,
pull requests excluded, the ten most recently opened taken, then each issue's
`/comments` read and the first comment counted whose `author_association` is
`OWNER`, `MEMBER` or `COLLABORATOR` and whose author is not the issue's own
author. `1Password/arboard`: **2 of 10 answered, 8 unanswered**; #230 in 3.0
days, #218 in 0.06 days; the median is **undefined** because the majority are
unanswered. `alacritty/copypasta`: **9 of 10 answered, 1 unanswered**; median
roughly **0.03 days**, with seven answered inside an hour.

**RustSec — `https://rustsec.org/packages/<name>.html`.** HTTP 404 (no
advisory): `arboard`, `copypasta`, `wl-clipboard-rs`, `x11rb`, `clipboard-win`,
`objc2`, `objc2-app-kit`, `objc2-foundation`, `parking_lot`, `log`,
`percent-encoding`, `cli-clipboard`, `copypasta-ext`, `terminal-clipboard`,
`osc52`. HTTP 200 (advisories present, used as positive controls so the 404s
carry meaning): `image` → RUSTSEC-2019-0014, RUSTSEC-2020-0073; `clipboard` →
RUSTSEC-2022-0056. Independent corroboration on the advisory database itself:
`gh api repos/rustsec/advisory-db/contents/crates/arboard` → 404, while
`gh api repos/rustsec/advisory-db/contents/crates/anyhow` → 200 listing
`RUSTSEC-2026-0190.md` (the control R67 established).

**`arboard` primary sources** — all via `gh api "repos/1Password/arboard/contents/<path>?ref=v3.6.1"`, i.e. **at the recommended version, not at `master`**: `Cargo.toml` (features, `rust-version`, per-target dependencies), `README.md` (*Backend Support*, *Clipboard Ownership*, the MSRV badge, the volunteer-support notice), `src/common.rs:20-67` (the `Error` enum, `#[non_exhaustive]`, the `Unknown { description }` doc comment at `:50-52`, the `std::error::Error` impl at `:67`), `src/lib.rs:28` (the `SetExtLinux` re-export), `src/platform/linux/mod.rs:120-146` (backend selection), `:209-221` (`WaitConfig`), `:300-389` (`SetExtLinux`, `wait()` at `:327`, `wait_until()` at `:337`), `src/platform/linux/x11.rs:138-144` (`RustConnection::connect(None)` and the inaccurate error text), `:914-933` (`Clipboard::new` and the serving thread), `src/platform/linux/wayland.rs:96-105` (`Clipboard::new`) and `:118-126` (`Options::foreground(…)`), `examples/daemonize.rs`, `.github/workflows/test.yml` (the clippy and test matrices and the Linux-exclusion comment). Plus `GET https://api.github.com/repos/1Password/arboard/commits?since=2025-08-23T20:19:03Z&per_page=100` → 8, and `GET …/releases?per_page=3` → v3.6.1 (2025-08-23T20:15:46Z), v3.6.0, v3.5.0.

**Adopter manifests and reference implementations** — `gh api repos/nushell/nushell/contents/crates/nu-command/Cargo.toml`; `gh api repos/nushell/reedline/contents/Cargo.toml`; `gh api repos/mufeedvh/code2prompt/contents/crates/code2prompt/Cargo.toml` and `…/crates/code2prompt/src/clipboard.rs` (all 129 lines); `GET https://crates.io/api/v1/crates/arboard/reverse_dependencies?per_page=10` (`meta.total` 1,283); `GET https://api.github.com/search/code?q=SetExtLinux+wait+language:Rust&per_page=20` (`total_count` 220, first page classified in Member 3's `Landscape`).

**`wl-clipboard-rs` primary sources** — `gh api repos/YaLTeR/wl-clipboard-rs/contents/README.md` (the `ext-data-control` / `wlr-data-control` requirement; the "100% safe Rust" statement; the scoping note that windowed applications should use `smithay-clipboard` instead) and `…/contents/src/copy.rs:384-403` (`foreground` and `serve_requests`).

**Org CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read with `git -C /Users/stevemorin/c/cli-standards show f9de0437baece3383e73ca2c5f48b7ab399b51c7` — R3.4 (short flags and the reserved set `-h -V -v -q -o -f -y`), R4.1 (standard options table), R4.4 (`--quiet` scope), R5.6 (secrets must not be passed in argv; stdin named as a channel), R6.1 (exit-code scheme), R6.3 (partial failure → exit 1), R7.1 (stdout carries the requested result, stderr everything else), R7.3 (TTY governs presentation, not format), R7.4 (progress on stderr, suppressed when not a TTY), R7.5 (structured help), R7.6 (error text: lowercase-first, no trailing period, name the offending input, state a next step), R7.8 (single-object JSON error schema), R9.2 (hidden aliases are an accepted device), R8.2 (non-interactive/CI behaviour and the 1/2/4 mapping). A grep of the blob for `clipboard`, `--copy`, `headless`, `DISPLAY`, `X11` and `Wayland` returns **no matches**: the standard defines no clipboard-specific rule, which is why the general rules above are applied by their own terms and cited individually.

**This programme's accepted decisions and pinned sources** — R67 `DECISION.md` (`error-taxonomy-exit-codes`: the `RSLB101` row, the envelope, the `thiserror`/`anyhow` layering, and the `cargo audit` control method reused in `### Validation strategy`); R06 `DECISION.md` (`unsafe_code = "forbid"`, first-party crates only, `--cap-lints allow` for dependencies); `docs/port/PARAMETERS.md` (the four fixed values and R01's `http-transport-injection-seam`); `docs/port/COMMONALITY.md:285-286` (rows F281 and F282, origin `ts-only`, verdict `DIVERGENT`, item R62); `research/CLAUDE.md` (R62 `owns` = `—`).

**`ts-launch-blueprint` at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`** (read with `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`) — `src/commands/projects.ts:84` (the `--copy` option declaration), `:190-201` (the wrapped call, the `CliError` with its remedy, the stderr success note, and the comment citing `projects.py:397-399`), `src/lib/adapters.ts:45-53` (`realClipboard`, the dynamic import, and the headless comment), `docs/port/TS_PORT_DECISIONS.md:167` (D-016(7)) and `:176` (its rationale, including the upstream confirmation that headless Linux has no clipboard).

**`py-launch-blueprint`** (read with `git -C ~/c/py-launch-blueprint show <rev>:<path>`) — **at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`**: no `pyperclip` or clipboard code in any tracked `*.py` or in `pyproject.toml` (verified by iterating every such path; zero hits), and `Justfile:58,562,607-608` (the developer-recipe `CLIPBOARD_CMD` and its `||` degrade). **At `f587e48^`**: `src/py_launch_blueprint/projects.py:390-405` (the unguarded `pyperclip.copy(result)` and the generic `except Exception` arm). **Commit `f587e48b41bcf6535ba1b62f348147294911c48d`**, 2026-06-09, *"refactor: remove legacy py-projects CLI and collapse command_name identity (#388)"* — the removal, its stated reason, and the `pyproject.toml` and `dependabot.yml` lines dropping `pyperclip`. Claims are labelled by commit throughout, per the role file's instruction about the two pins disagreeing.

**Source-library mechanism evidence (why py and ts never faced selection ownership)** — `https://raw.githubusercontent.com/asweigart/pyperclip/master/src/pyperclip/__init__.py` (HTTP 200): module docstring lines 17–37 naming `pbcopy`, `xclip`, `xsel`, `wl-copy`/`wl-paste`; `class PyperclipException(RuntimeError)` at line 85; `init_osx_pbcopy_clipboard` with `subprocess.Popen(['pbcopy', 'w'], …)` at lines 97–104. `https://raw.githubusercontent.com/sindresorhus/clipboardy/main/lib/macos.js` (HTTP 200): `execa('pbcopy', …)` at lines 8 and 13. `https://raw.githubusercontent.com/sindresorhus/clipboardy/main/lib/linux.js` (HTTP 200): the `xsel`-over-`xclip` note at line 8, `const xsel = 'xsel'` at line 9, the bundled fallback at line 10, and the headless error text at line 30 quoted in `### Principles and implementation`. `gh api repos/sindresorhus/clipboardy/contents/lib` → `linux.js`, `macos.js`, `termux.js`, `wayland.js`, `windows.js`, `wsl.js` — a separate Wayland backend exists. `gh api repos/YaLTeR/wl-clipboard-rs/contents/src/copy.rs` line 710 — *"potentially past a fork (which is how `wl-copy` uses it)"*. **Not verified:** that `xclip` and `xsel` themselves fork; asserted from their documented behaviour, not from their sources. All retrieved 2026-09-17.

**`wl-clipboard-rs` protocol-detection evidence** — `gh api repos/YaLTeR/wl-clipboard-rs/contents/src/utils.rs`: `enum PrimarySelectionCheckError` at lines 120–140, including `MissingProtocol` — *"A required Wayland protocol (ext-data-control, or wlr-data-control version 1) is not supported by the compositor"* — plus `NoSeats`, `SocketOpenError`, `WaylandConnection`, `WaylandCommunication`; `is_primary_selection_supported` at lines 177–204. Retrieved 2026-09-17. This is what makes Member 3's construction-time probe sufficient on Wayland.

**`x11rb` fail-fast evidence** — `https://raw.githubusercontent.com/psychon/x11rb/master/x11rb/src/rust_connection/mod.rs` (`fn connect` at line 112; the `DisplayParsingError::Unknown.into()` mapping at line 156) and `https://raw.githubusercontent.com/psychon/x11rb/master/x11rb-protocol/src/errors.rs` (`enum DisplayParsingError` at lines 82–88, `DisplayNotSet` documented as *"No explicit display was provided and the `$DISPLAY` environment variable is not set."*). Retrieved 2026-09-17.

**Runner-up and alternative evidence** — `gh api repos/alacritty/copypasta/contents/Cargo.toml` (`wayland = ["smithay-clipboard"]` at line 18; `smithay-clipboard = { version = "0.7.0", default-features = false, optional = true }` at line 39; `x11-clipboard` at 38; `objc2`/`objc2-app-kit` at 25–35) and `gh api repos/alacritty/copypasta/contents/src` (`common.rs`, `lib.rs`, `nop_clipboard.rs`, `osx_clipboard.rs`, `wayland_clipboard.rs`, `windows_clipboard.rs`, `x11_clipboard.rs`, each read and grepped for `fn wait`, `fork`, `daemon` — no match). `gh api repos/helix-editor/helix/contents/helix-view/src/clipboard.rs` (`Osc::SetSelection(selection, content)` at lines 304–312 — OSC 52 written inline, no clipboard-escape dependency). Retrieved 2026-09-17.

**Other** — `https://doc.rust-lang.org/std/` (HTTP 200; the module list contains no `clipboard`, `pasteboard` or `selection` entry, and the page's only occurrence of the word is rustdoc's **Copy item path to clipboard** button); `https://blog.rust-lang.org/` (HTTP 200; the index lists *2025 State of Rust Survey Results* and topic surveys on debugging and compiler performance, none covering clipboard libraries); `https://rust-lang.github.io/api-guidelines/interoperability.html` (HTTP 200; the first-party error-interoperability conventions, *"Error types are meaningful and well-behaved"*); `https://raw.githubusercontent.com/actions/runner-images/main/images/ubuntu/Ubuntu2404-Readme.md` (`xvfb` 2:21.1.12-1ubuntu1.6 preinstalled; no `xclip`, `xsel` or `wl-clipboard`); `https://wayland.app/protocols/ext-data-control-v1` (HTTP 200, but the retrieved page carried no parseable compositor-implementations section — see below).

**Method notes.** Endpoints queried: `https://crates.io/api/v1/crates/<name>` and `/versions` and `/reverse_dependencies` for all fourteen crates in the tables above (`curl -sS` with a `User-Agent` header); `https://api.github.com/repos/<o>/<r>`, `/commits`, `/releases`, `/issues`, `/issues/<n>/comments`, `/contents/<path>`, `/tags`, and `https://api.github.com/search/issues` and `/search/code`, all through the authenticated `gh api` on this machine (no token was printed and no environment was disclosed); `https://rustsec.org/packages/<name>.html` for fifteen packages plus two positive controls, corroborated against `repos/rustsec/advisory-db/contents/crates/<name>`; `https://raw.githubusercontent.com/actions/runner-images/…`; `https://wayland.app/protocols/ext-data-control-v1`; `https://doc.rust-lang.org/std/`; `https://blog.rust-lang.org/`; `https://rust-lang.github.io/api-guidelines/interoperability.html`; `https://raw.githubusercontent.com/asweigart/pyperclip/…`; `https://raw.githubusercontent.com/sindresorhus/clipboardy/…`; `https://raw.githubusercontent.com/psychon/x11rb/…`. Every URL cited with a retrieval date in this report was actually fetched in this session; where a page returned but did not contain what was sought, that is said rather than glossed. Local reads: the CLI Design Standard blob via `git show`, and both source repositories through their pins via `git show <pin>:<path>` — never from a working tree.

**Not verified, and therefore not asserted.** (1) *Nothing was compiled or run.* No Cargo project was created (the run constraint forbids scaffolding), so there is no `cargo tree`, `cargo tree -d`, `cargo audit`, `cargo build --timings` or test result behind any claim; MSRV figures are **declared floors read from the registry**, not a resolved lockfile, and the compile-time and binary-size statements under gate 6 are qualitative readings of the dependency graph, not measurements. (2) *No headless Linux environment was available in this session*, so the degrade behaviour, the `xvfb` round-trip and the selection-ownership persistence are reasoned from `arboard`'s and `wl-clipboard-rs`'s source, documentation and CI configuration rather than observed; `### Validation strategy` A2 and A4 are the checks that would confirm them. (3) *`ext-data-control` support in GNOME/Mutter is unresolved.* `https://wayland.app/protocols/ext-data-control-v1` returned HTTP 200 but the retrieved HTML contained no implementations section I could parse, and `GET https://api.github.com/search/code?q=ext_data_control+repo:GNOME/mutter` and `GET https://api.github.com/search/issues?q=repo:GNOME/mutter+ext-data-control` both returned `total_count: 0` against what is a read-only mirror whose code index is not dependable — a zero there is not evidence of absence, and it is recorded as unknown in both directions. It bounds how often `arboard`'s XWayland fallback is the live path on a desktop Ubuntu machine; it changes nothing on `ubuntu-latest`, which runs no compositor. (4) *The probe-before-spawn ordering in Member 3 has no production instance.* The `search/code` sweep found the re-exec pattern ten times and probed zero times; the recommendation is reasoned from platform semantics and from a defect analysis of `code2prompt`, and that evidence gap is stated in Member 3's confidence field rather than filled with an invented example. (5) *`wl-clipboard-rs`'s `created_at` ordering is anomalous* — several old versions share a 2026-05-07 timestamp, so the literal application of the figure rule disagrees with `max_stable_version`; both readings are recorded above. (6) *`cli-clipboard`'s open-issue count* required resolving a repository rename after the search endpoint returned HTTP 422 under the name crates.io advertises; the figure reported is against the current name. No figure in this report was fabricated or estimated: where an endpoint failed or an answer could not be established, that is said here.
