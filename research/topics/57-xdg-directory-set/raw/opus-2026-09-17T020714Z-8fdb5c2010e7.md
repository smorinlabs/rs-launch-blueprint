# R57 — XDG directory set (pattern) — Opus raw report

Engine identity `research-opus-2026-09-17T020714Z-8fdb5c2010e7`, model `claude-opus-5`.
All endpoint retrievals in this report were performed on **2026-09-17** (UTC; `date -u` →
`2026-09-17T04:18:16Z`). Local stable toolchain observed for the MSRV gate:
`rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`, so the `msrv-policy` floor
("stable minus 2 minor versions") evaluates to **1.96** throughout.

### Landscape

**The category this item decides.** Not "which directory crate" but *how many
per-user filesystem roots the template resolves, and by what rule a given file is
assigned to one of them*. The candidate set is therefore two-layered: first the
architectural alternatives (hand-rolled std resolution · a base-directory crate ·
a config-framework crate that hides the paths), then the crates inside the chosen
alternative.

**Decisive finding, stated before the map because it collapses the question.** The
org CLI Design Standard v1.4.14 (blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`,
`/Users/stevemorin/c/cli-standards/cli-design-standard.md`, "Last updated 2026-06-28",
read 2026-09-17) makes the full directory set a **MUST**, not a contingency:

> **R5.3 — Filesystem locations (XDG). (MUST)** Per-user paths **MUST** follow the
> XDG Base Directory Specification, namespaced under the tool name, honoring `XDG_*`
> overrides and falling back to the defaults below.

and then tables five purposes — Config `$XDG_CONFIG_HOME/acme/`, Data
`$XDG_DATA_HOME/acme/`, **State (logs, history)** `$XDG_STATE_HOME/acme/`, Cache
`$XDG_CACHE_HOME/acme/`, Runtime `$XDG_RUNTIME_DIR/acme/` — with the explicit
counter-example "❌ writing config to `~/.acme/` (a dotdir in `$HOME`) by default".
The standard's own provenance table, row 10, records `Filesystem paths | XDG Base
Directory Specification | Modern standard; predictable | **org-locked**`, and its
Principle 1 places the specification in the standard's *layered* modern guidance
rather than in its base: *"POSIX Utility Syntax Guidelines and GNU long-options are
the non-negotiable foundation. Modern guidance (clig.dev, the 12-Factor CLI essay,
the XDG Base Directory Specification) layers on top."* The MUST force therefore comes
from `R5.3`'s own conformance language and from provenance row 10's `org-locked`
marking, not from Principle 1, which situates XDG rather than mandating it. `R5.3`
is also reachable from three other rules the template already owes: `R5.1`/`R5.2`
(user config at `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`), `R5.9` (a caching tool
SHOULD document its cache location), and `R10.1` (stored credentials fall back to
"a `0600` file under `$XDG_STATE_HOME/acme/` (R5.3)").

That is the authority answer to this item's second HIGH question. It is not a
choice between "resolve the full set now" and "default to ts's minimal shape and
let R59/R67 add accessors later": an org-locked MUST binds the port, and the
only discretion left is *which* directories the template writes into on day one.
And that discretion is already spent — see `### Principles and implementation`,
where R67's accepted decision has a crash record whose location it deferred here,
and `R5.3` files logs under State.

**Three-bin map of the Rust field.**

| Bin | Candidates | Why in this bin |
|---|---|---|
| **Built-in / first-party toolchain** | `std::env::home_dir` + `std::env::var_os` (hand-rolled, py's own shape); `home` 0.5.12 (`rust-lang/cargo`, home-dir only, no XDG semantics) | `std::env::home_dir` is `pub fn home_dir() -> Option<PathBuf>`, stable since 1.0.0 and carrying **no deprecation notice** on the current documentation, whose own note directs Unix callers to the XDG Base Directories specification and Windows callers to `LOCALAPPDATA`/`APPDATA` (https://doc.rust-lang.org/std/env/fn.home_dir.html, retrieved 2026-09-17); `home` lives in the `rust-lang/cargo` repository (https://crates.io/api/v1/crates/home → `crate.repository` = `https://github.com/rust-lang/cargo`, retrieved 2026-09-17) |
| **Established industry standard** | `directories` 6.0.0 + its low-level sibling `dirs` 7.0.0 (Codeberg org `dirs`); `etcetera` 0.11.0 (`lunacookies/etcetera`); `xdg` 3.0.0 (`whitequark/rust-xdg`) | All four are named in the ecosystem's own guidance and/or carry eight-figure all-time download counts; the org standard's Appendix E names two of them by name (below) |
| **Up-and-comer** | none with meaningful adoption; the newest movement in this category is *within* `etcetera` (unreleased 0.12.0 on `master`) and *relocation* of the `dirs`/`directories` family to Codeberg, not a new entrant | `app_dirs2` 2.5.5 (last release 2023-02-15), `platform-dirs` 0.3.0 (2020-09-26) and `dirs-next` 2.0.0 (2020-10-22) are the only other library-shaped entrants and all three are older than the incumbents, not newer (crates.io `/versions`, retrieved 2026-09-17) |

Every shortlisted candidate below comes from that map.

**Authoritative sources, and why each counts.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` (`R5.1`, `R5.2`, `R5.3`, `R5.9`, `R10.1`, provenance row 10, Appendix E "Rust — Clap (derive)") | The owner's own normative standard; it binds this port by the task statement, and marks filesystem paths `org-locked` | 2026-09-17 |
| freedesktop.org XDG Base Directory Specification, **version 0.8, 08 May 2021** (https://specifications.freedesktop.org/basedir/latest/) | The specification the standard incorporates by reference; it is the definition of the four bases and of the absolute-path rule | 2026-09-17 |
| `etcetera` maintainers' documentation and source (https://docs.rs/etcetera/0.11.0/etcetera/, `base_strategy/trait.BaseStrategy.html`, `src/etcetera/base_strategy/xdg.rs.html`; https://raw.githubusercontent.com/lunacookies/etcetera/master/src/base_strategy.rs) | Maintainer's own documentation — the primary statement of what the API does, read alongside the source rather than trusted as prose | 2026-09-17 |
| `directories` / `dirs` maintainers' documentation (https://docs.rs/directories/6.0.0/directories/struct.ProjectDirs.html; https://docs.rs/dirs/7.0.0/dirs/fn.state_dir.html) | Same standing, for the competing family; it is where the macOS capability gap is stated by its own authors | 2026-09-17 |
| Rust CLI working group, *Command Line Applications in Rust* (https://rust-cli.github.io/book/in-depth/config-files.html) | The Rust project-adjacent working group's book. Cited here for what it does **not** say: it recommends `confy` and carries a `TODO` where XDG guidance would go, discussing no directory crate and no XDG layout. A working-group silence is evidence that the ecosystem has no competing published pattern, not evidence against XDG | 2026-09-17 |
| RustSec advisory database (https://rustsec.org/packages/<n>.html and `gh api repos/rustsec/advisory-db/contents/crates/<n>`) | The Rust Secure Code WG's database; used with the paired 200/404 control described under `### Sources`, *Method notes* | 2026-09-17 |
| py-launch-blueprint at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`, `src/py_launch_blueprint/core/paths.py`; ts-launch-blueprint at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, `src/lib/xdg-paths.ts` | The port's own evidence base, read through the pins as the role file requires | 2026-09-17 |

A single blog post is nowhere load-bearing in this report; the one web search I ran
(on `bat`'s macOS directory history) produced only leads, and the claim it suggested
was then verified against `bat`'s own source, cited below.

**Practice evidence — well-regarded Rust projects, and why they are well regarded.**
Reverse dependencies of `etcetera` (`GET https://crates.io/api/v1/crates/etcetera/reverse_dependencies?per_page=60`,
`meta.total` = **197**, retrieved 2026-09-17), with the adoption then confirmed in
each project's own manifest or source:

| Project | Evidence of adoption | Evidence it is well regarded |
|---|---|---|
| **uv** (Astral) | `crates/uv-dirs/Cargo.toml:21` `etcetera = { workspace = true }`; `crates/uv-dirs/src/lib.rs` uses `etcetera::base_strategy::choose_base_strategy()` (https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv-dirs/src/lib.rs) | `gh api repos/astral-sh/uv` → `stargazers_count` **89,889**, `archived` false, `pushed_at` 2026-09-17 |
| **ruff** (Astral) | `ruff_db` 0.0.14 depends on `etcetera ^0.11.0` (reverse-dependencies listing) | `gh api repos/astral-sh/ruff` → **49,651** stars, `pushed_at` 2026-09-17 |
| **bat** | `Cargo.toml:67` `etcetera = { version = "0.11.0", optional = true }`; `src/bin/bat/directories.rs` — see the quoted comment under *Dominant choice* | `gh api repos/sharkdp/bat` → **60,472** stars, `pushed_at` 2026-09-04 |
| **fd** | `Cargo.toml:43` `etcetera = "0.11"` | `gh api repos/sharkdp/fd` → **44,543** stars, `pushed_at` 2026-09-16 |
| **jj (Jujutsu)** | `lib/Cargo.toml:36` and `cli/Cargo.toml:79` both `etcetera = { workspace = true }` | `gh api repos/jj-vcs/jj` → **31,623** stars, `pushed_at` 2026-09-17 |
| **cargo-nextest** | `nextest-runner/Cargo.toml:37` `etcetera.workspace = true` | `gh api repos/nextest-rs/nextest` → **3,293** stars, `pushed_at` 2026-09-17; the de-facto Rust test runner, and R32's likely subject |
| **sqlx**, **testcontainers**, **git-cliff**, **zizmor**, **tokei**, **tealdeer**, **fnm**, **topgrade**, **confy**, **tree-sitter** (`tree-sitter-loader`, `tree-sitter-config`) | all appear in the reverse-dependencies listing at `^0.8`–`^0.11` | breadth evidence: the list spans a database driver, a test-infrastructure crate, a release-notes generator, a CI linter, and the config crate the Rust CLI book itself recommends |

The weighting the survey method asks for — "newer popular ones" — points the same
way: `uv` and `ruff` are the two most recently ascendant Rust CLIs in the list, and
both are on `etcetera`. `uv` is the strongest single datapoint because it kept a
`legacy_user_cache_dir()` / `legacy_user_state_dir()` pair on
`choose_native_strategy()` purely to migrate users off the macOS-native layout,
commenting in its own source: *"Uses `/Users/user/Library/Application Support/uv`
on macOS, in contrast to the new preference for using the XDG directories on all
Unix platforms."* That is a production project paying a migration cost to move
**toward** the shape this item recommends.

### Principles and implementation

**The shared requirement.** A user must be able to find, relocate, back up and
delete this tool's per-user files by their *kind*, using one mechanism that is the
same across the three template languages: configuration the user edits, data the
user would hate to lose, state the tool can regenerate but the user may want to
read (logs, history), and cache the user may delete at any moment without loss.

**Source and agreement level.** Two sources, and they bind at different levels.

1. *Org CLI Design Standard `R5.3`* — **MUST**, marked `org-locked` in provenance
   row 10. Agreement level: **standard**. This is the higher authority and it is
   not discretionary for any of the three repositories.
2. *Ledger row F249* (`docs/port/COMMONALITY.md:253`), origin `py-only`, verdict
   `DIVERGENT`. Agreement level as recorded: contingent capability.

Those two disagree, and the standard wins. See the `BASELINE-REVIEW:` line below.

**What must agree, and what may vary.** Agreeing across py, ts and rs:

- **The four kinds exist as a named concept** and each file the tool writes is
  assigned to exactly one of them (`R5.3`; py `paths.py` module docstring lines
  22–27 at pin: config / "data you'd hate to lose" / "logs/history (recoverable)" /
  "regenerable cache").
- **The `XDG_*` variables are honoured on every POSIX platform including macOS**,
  ignored when empty. py `paths.py:65-75` at pin (`_xdg_override`: non-empty **and**
  `is_absolute()`); ts `xdg-paths.ts:23` at pin (non-empty only), whose file header
  at lines 1–10 states the reason in terms of this very standard: *"the config lives
  at `%USERPROFILE%\.config\ts-projects` — deliberately NOT `%APPDATA%`, for parity
  with the source and cli-standards R5.3"*, and *"No env-paths: its platform-native
  dirs (`~/Library/Preferences` on macOS, `%APPDATA%` on Windows) would break the
  documented `~/.config/<tool>` UX."*
- **One namespace segment, the tool name.** py `APP_NAME = "plbp"` (`paths.py:56` at
  pin); ts `TOOL_DIR_NAME = 'ts-projects'` (`xdg-paths.ts:13` at pin). Both use the
  *binary* name, not the package name. `R5.3` says "namespaced under the tool name".
- **Resolve once, never read the raw variables elsewhere** — py's docstring states
  this as a rule (`paths.py` line 49 at pin: "Resolve once; never read the raw env
  vars elsewhere").

May vary by ecosystem:

- **The accessor surface** (free functions vs. a resolved value) — see the MEDIUM
  question below; Rust has a hard constraint here that Python and TypeScript do not.
- **Windows defaults** — py and ts already disagree (py: platform-native
  `%APPDATA%`/`%LOCALAPPDATA%`; ts: `~/.config` everywhere). `R5.3` permits both
  ("Native non-Linux equivalents are permitted deviations … but XDG paths are the
  canonical reference"). Windows is outside `target-os-matrix`, so this item does
  not adjudicate it; see *Fit* and *Tradeoffs*.
- **Which directories are written into on day one** — a consequence of what the
  template ships, not of the principle.

**Is the shared architectural pattern still appropriate in Rust?** Yes, and more
strongly than in either source, because Rust's ecosystem has an explicit,
widely-adopted crate for exactly the base-directory abstraction that py hand-rolls
in 170 lines and ts hand-rolls in 30. The one place the pattern needs a *different
design* in Rust is the accessor surface, for a reason that does not exist in the
other two languages — see MEDIUM below.

**Architectural alternatives, compared before any library.**

| Alternative | What it is | Verdict |
|---|---|---|
| **A. Hand-rolled over `std`** (py's shape ported literally) | Read `XDG_*` with `std::env::var_os`, validate `is_absolute()`, fall back to `std::env::home_dir().join(".local/state")` etc. Zero dependencies. | **Rejected.** It is ~150 lines of platform logic the template must own, test and keep in sync with a spec it does not control, to reproduce a crate that is one dependency and ~400 lines. The one thing it buys — an injectable environment — is obtainable for free under alternative C (below), because `etcetera`'s `BaseStrategy` is an ordinary unsealed public trait. Keep it as the fallback if `etcetera` ever becomes unmaintained. |
| **B. Let a config framework own the paths** (`confy`, `figment`, `config`) | The config crate discovers and reads the file; the template never names a directory. | **Rejected on scope and on capability.** It answers only the *config* question — which is R54's, explicitly out of scope here — and gives no data/state/cache accessor at all, so `R5.3`'s other three rows would be unimplementable. (`confy` 2.0.0 itself depends on `etcetera ^0.10.0`, so this alternative is alternative C with a layer of indirection and less control.) |
| **C. A base-directory crate wrapped in one template-owned type** | A crate resolves the four bases for the running platform; the template owns a small `Paths` value that appends the `rslbp` namespace segment and hands out `&Path`s. | **Selected.** It is what every well-regarded adopter surveyed actually does, `bat` most explicitly (its wrapper is even named for the fact: `BatProjectDirs`, "Wrapper for 'etcetera'…"). It preserves the "resolve once" principle structurally, and it keeps the namespacing — the one piece that is genuinely this template's policy — in this template's source. |

**Within alternative C, the library choice is decided by one capability fact, not
by popularity.** `macos-latest` is in the fixed `target-os-matrix`, and:

- `directories` 6.0.0 `ProjectDirs::state_dir() -> Option<&Path>` returns **`None`
  on macOS and on Windows**; only Linux yields `$XDG_STATE_HOME/<project>` or
  `$HOME/.local/state/<project>` (https://docs.rs/directories/6.0.0/directories/struct.ProjectDirs.html,
  retrieved 2026-09-17). `dirs` 7.0.0 `state_dir()` is the same function underneath
  and its own platform table shows `–` for macOS and Windows
  (https://docs.rs/dirs/7.0.0/dirs/fn.state_dir.html, retrieved 2026-09-17).
- The same page records that `directories` `config_dir()` on macOS is
  `$HOME/Library/Application Support/<project>` and **does not consult
  `$XDG_CONFIG_HOME`** — the trap `docs/port/BASELINE-REVIEW.md:113` already
  recorded against F247.
- `etcetera` 0.11.0's `choose_base_strategy()` returns the **`Xdg` strategy on
  macOS**. From the crate's own source: the `cfg` dispatch is
  `any(target_os = "macos", target_os = "ios") => create_strategies!(Apple, Xdg);`,
  with the doc comment *"Returns the current OS's default `BaseStrategy`. This uses
  the `Windows` strategy on Windows, and `Xdg` everywhere else. This is the
  convention used by most CLI applications."*
  (https://raw.githubusercontent.com/lunacookies/etcetera/master/src/base_strategy.rs,
  retrieved 2026-09-17; same dispatch documented for 0.11.0 at
  https://docs.rs/etcetera/0.11.0/etcetera/base_strategy/, retrieved 2026-09-17).

So on `macos-latest` — a required CI target — `directories` would give the crash
log **no location at all** and would break the XDG override the port already
treats as inherited behaviour. That is a capability absence on a required OS, and
it outranks `directories`' respectable download figures under the survey method's
gate-before-popularity rule.

**`etcetera` also matches py's stricter override rule for free.** py validates
absoluteness (`paths.py:73` at pin, `candidate.is_absolute()`), ts validates only
non-emptiness. `etcetera`'s Xdg strategy validates absoluteness:

```
fn env_var_or_none(env_var: &str) -> Option<PathBuf> {
    std::env::var_os(env_var).and_then(|path| {
        let path = PathBuf::from(path);
        if path.is_absolute() { Some(path) } else { None }
    })
}
```

(https://docs.rs/etcetera/0.11.0/src/etcetera/base_strategy/xdg.rs.html, retrieved
2026-09-17), with fallbacks `.config/`, `.local/share/`, `.local/state/`, `.cache/`
joined to the home directory and no fallback for `XDG_RUNTIME_DIR`. That is
verbatim the freedesktop rule — *"All paths set in these environment variables must
be absolute. If an implementation encounters a relative path in any of these
variables it should consider the path invalid and ignore it."* (XDG Base Directory
Specification v0.8, 08 May 2021, retrieved 2026-09-17) — and verbatim py's
behaviour. `uv` reimplements the identical check in `parse_xdg_path`, quoting the
same spec sentence in a doc comment. So the Rust choice settles the open
absoluteness question (`docs/port/BASELINE-REVIEW.md:354`) in py's favour at zero
implementation cost, rather than leaving it to be adjudicated later.

**Essential behaviours and observable acceptance criteria.**

| # | Behaviour | Observable acceptance criterion |
|---|---|---|
| B1 | Four kinds are resolvable as distinct roots | `rslbp debug paths -o json` (or the equivalent P03 affordance) emits four distinct absolute paths for config, data, state, cache, all four ending in the segment `rslbp` |
| B2 | `XDG_*` overrides are honoured on **both** `ubuntu-latest` and `macos-latest` | with `XDG_STATE_HOME=$TMP/s`, the state path is `$TMP/s/rslbp` on both runners |
| B3 | An empty or relative `XDG_*` value is ignored | with `XDG_STATE_HOME=""` and with `XDG_STATE_HOME=rel/ative`, the state path is `$HOME/.local/state/rslbp` on both runners |
| B4 | The namespace segment is the binary name, once, with no extra nesting | the four paths are exactly `<base>/rslbp`, never `<base>/rs-launch-blueprint` and never `<base>/rslbp/config` |
| B5 | Resolution is pure: computing a path creates no directory and writes no file | after the acceptance command runs with a fresh `$HOME`, `$HOME/.local` does not exist |
| B6 | An unresolvable home directory is an ordinary, typed failure — never a panic | with `HOME` unset and no `XDG_*` set, a command that needs a path exits `1` with an `RSLB101` envelope; the crash sink stays silent and changes neither (R67 AC7) |
| B7 | The library crate can compute paths without violating R67's layering | `cargo tree -p <lib> -i anyhow` is empty, and the paths module contains no `std::fs` write and no `std::io` stream access |

**MEDIUM question — free functions or a struct? A struct, and one Rust-2024 fact
decides it.** Edition 2024 makes `std::env::set_var` and `std::env::remove_var`
`unsafe` — two of the exactly three functions on the edition's newly-unsafe list,
"because it can be unsound to call [them] in a multithreaded program due to safety
limitations of the way the process environment is handled on some platforms"
(https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html,
retrieved 2026-09-17) — and **R06 is resolved with `unsafe_code = "forbid"` in
`[workspace.lints.rust]`, inherited by every member through `[lints] workspace = true`**
(`research/topics/06-unsafe-code-policy/DECISION.md`). A `forbid` cannot be lifted
by a per-site `#[allow]` or `#[expect]`, and it applies to `#[cfg(test)]` modules
and `tests/` targets as much as to `src/`. Therefore **free functions that read the
process environment internally — py's exact shape, and `etcetera`'s own
`choose_base_strategy()` — cannot be unit-tested hermetically in this template at
all.** A resolved value that can be constructed from an injected strategy can.

That is a justified ecosystem difference of precisely the kind the research mandate
asks to be distinguished from drift: Python monkeypatches `os.environ` freely
(py's own tests rely on it, `paths.py:58-60` at pin explains `_WINDOWS` is
module-level "so tests can exercise both branches by monkeypatching"), TypeScript
injects `env` and `homedir` as parameters (`xdg-paths.ts:22`,
`configDir(env, homedir)`), and Rust must do the TypeScript thing rather than the
Python thing. The principle — "resolve once, and the resolution is testable" — is
preserved in all three; the mechanism differs because the language differs.

The injection point is free, because `etcetera::base_strategy::BaseStrategy` is an
ordinary public trait with six methods and **no sealing** (full trait source, 71-line
file, retrieved 2026-09-17):

```rust
pub trait BaseStrategy {
    fn home_dir(&self) -> &Path;
    fn config_dir(&self) -> PathBuf;
    fn data_dir(&self) -> PathBuf;
    fn cache_dir(&self) -> PathBuf;
    fn state_dir(&self) -> Option<PathBuf>;
    fn runtime_dir(&self) -> Option<PathBuf>;
}
```

**Minimal realistic example** (illustrative; P03 writes the real thing, and the
crate/module placement is R02's):

```rust
// crates/rslbp-core/src/paths.rs  — library crate; computes, never writes.
use std::path::{Path, PathBuf};
use etcetera::base_strategy::BaseStrategy;

/// The tool name, and the single namespace segment under every base.
/// Equals the `[[bin]]` name fixed by R49's `build-tool-output-shape`.
pub const TOOL_NAME: &str = "rslbp";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths { config: PathBuf, data: PathBuf, state: PathBuf, cache: PathBuf }

impl Paths {
    /// Resolve once from any strategy. Pure: touches no filesystem.
    pub fn from_strategy(s: &impl BaseStrategy) -> Self {
        // `state_dir()` is `None` on the Windows and Apple strategies; collapsing
        // it onto the data dir reproduces py's documented Windows behaviour
        // ("Windows has no data/state split", paths.py docstring at pin) and keeps
        // this accessor total on every platform.
        let data = s.data_dir().join(TOOL_NAME);
        Self {
            config: s.config_dir().join(TOOL_NAME),
            state:  s.state_dir().map(|p| p.join(TOOL_NAME)).unwrap_or_else(|| data.clone()),
            cache:  s.cache_dir().join(TOOL_NAME),
            data,
        }
    }

    /// Production entry point. Fallible: a container may have no `HOME`.
    pub fn from_process_env() -> Result<Self, etcetera::HomeDirError> {
        Ok(Self::from_strategy(&etcetera::base_strategy::choose_base_strategy()?))
    }

    pub fn config_dir(&self) -> &Path { &self.config }   // resolution of the
    pub fn data_dir(&self)   -> &Path { &self.data }     // *config* tiers is R54's
    pub fn state_dir(&self)  -> &Path { &self.state }
    pub fn cache_dir(&self)  -> &Path { &self.cache }
}
```

Consumers then read, and nothing else in the workspace touches an `XDG_*` variable:

```rust
// R59's file sink default:      paths.state_dir().join("rslbp.log")
// R67's crash record default:   paths.state_dir().join("rslbp_crash.jsonl")
```

The `<app>_<kind>.<ext>` filename shape is py's, stated in its docstring at pin
("files are named `<app>_<kind>.<ext>` so a stray file on disk announces both its
owner and its purpose"), and `R5.2` uses the same shape for the config file.
Directory *creation* stays at each write site in the binary crates, so the library
crate keeps R67's layering promise ("must write to no process stream or file").

**Maintained reference implementations.** Three, all read at source on 2026-09-17:

- **`bat`**, `src/bin/bat/directories.rs` — the closest match to the recommended
  design, a template-owned wrapper struct over `etcetera`:
  *"Wrapper for 'etcetera' that checks BAT_CACHE_PATH and BAT_CONFIG_DIR and falls
  back to the Windows known folder locations on Windows & the XDG Base Directory
  Specification everywhere else."* It calls `etcetera::choose_base_strategy()` once
  and stores `cache_dir`/`config_dir` as fields — resolve-once, as a value.
- **`uv`**, `crates/uv-dirs/src/lib.rs` — the fullest treatment: `choose_base_strategy()`
  for the current layout, `choose_native_strategy()` retained only for legacy
  migration, an explicit `parse_xdg_path` absoluteness check quoting the spec, and
  `Option`-returning accessors because "`$HOME` cannot be resolved" is a real case.
- **`jj`**, `lib/Cargo.toml` + `cli/Cargo.toml` — the same crate depended on from
  both a library and a CLI crate in one workspace, which is this template's exact
  topology question.

BASELINE-REVIEW: F249 — per-user files are addressed by kind, and the set of kinds is fixed by the org CLI Design Standard rather than by what the template happens to write today — replace the row's contingency clause ("contingent on whether a file log sink (R59) or a crash log (see F302) end up needing a state/cache path") with a statement that R5.3 is an org-locked MUST and that the accessor set is therefore unconditional, leaving only which directories are written into as a consumer question — evidence: org CLI Design Standard v1.4.14 blob f9de0437baece3383e73ca2c5f48b7ab399b51c7, rule R5.3 "(MUST)" with its five-row purpose table, and provenance row 10 marking filesystem paths org-locked (retrieved 2026-09-17); and the contingency has in any case already resolved affirmatively — R67 is owner-accepted with a crash record whose location it deferred to this item (research/topics/67-error-and-exit-code-contract/DECISION.md:33, "Crash record | std::fs behind an injected sink; location deferred to R57"), while R5.3 files logs under State.

Affected items: R57 (this item, the accessor set), R59 (`file-log-sink`, F256–F261 —
its default path stops being "possibly hardcoded/relative" and becomes
`state_dir().join("rslbp.log")`), R67 (F302 — its default crash sink stops being a
no-op), R54 (`config-discovery-tiers` — its user tier should consume this item's
`config_dir()` rather than resolve a second time, and the crate recommended here
removes the `directories`-on-macOS trap that `docs/port/BASELINE-REVIEW.md:113`
recorded against F247).

No second `BASELINE-REVIEW:` line is raised. F247's own disposition is already open
in `docs/port/BASELINE-REVIEW.md:193` and is R54's to close; this item only notes
that the crate recommended here satisfies both of F247's criteria and py's
absoluteness check, which is evidence for that open question rather than a new
challenge to it.

### Dominant choice

**`etcetera` 0.11.0, used through `choose_base_strategy()`, wrapped in one
template-owned resolved-value type.** This is dominant on two independent measures.

*By authority:* the org CLI Design Standard's own Rust guidance names it — Appendix E,
"Rust — Clap (derive)": *"Pair with `figment`/`config` crates for the precedence chain
and `directories`/`etcetera` for XDG paths."* Of that pair, only `etcetera` can
satisfy `R5.3`'s State row on `macos-latest`, so the standard's normative rule
selects between the two candidates its own advisory appendix offers.

*By the competitor's own position:* the `directories` maintainer has declined
XDG-on-macOS in writing — issue #117, 2026-06-16, `soc`: *"this is not going to be
supported"* — so the gap is permanent by design, not a backlog item that a future
release might close.

*By practice:* it is what the newest well-regarded Rust CLIs use, with 197 reverse
dependencies on crates.io and adoption confirmed in the manifests of `uv` (89,889
stars), `bat` (60,472), `ruff` (49,651), `fd` (44,543), `jj` (31,623) and
`cargo-nextest` (3,293) — all figures `gh api repos/<o>/<r>` → `stargazers_count`,
retrieved 2026-09-17.

The wrapper is part of the dominant choice, not an embellishment: `bat`'s
`BatProjectDirs`, `uv`'s `uv-dirs` crate and py's own `paths.py` are all the same
shape — a thin, project-owned layer that owns the namespace segment and the
filenames, over a library that owns the platform rules.

### Options

| Option | Where documented | Adopters that practice it | Most recent authoritative write-up |
|---|---|---|---|
| **Full XDG set via `etcetera` + a template-owned resolved value** | Org CLI Design Standard `R5.3` (MUST) and Appendix E; https://docs.rs/etcetera/0.11.0/etcetera/; XDG Base Directory Specification v0.8 | uv (`crates/uv-dirs/src/lib.rs`), bat (`src/bin/bat/directories.rs`), fd (`Cargo.toml:43`), jj (`lib/`+`cli/Cargo.toml`), cargo-nextest (`nextest-runner/Cargo.toml:37`), ruff (`ruff_db`), sqlx, git-cliff, zizmor, tealdeer, confy | `etcetera` 0.11.0 release 2025-10-28; `etcetera` master commit "Drop cfg-if dependency (#43)" 2026-08-04 |
| **Full set via `directories`/`dirs` (`ProjectDirs`)** | https://docs.rs/directories/6.0.0/directories/struct.ProjectDirs.html; named in the standard's Appendix E | very broad legacy adoption across the ecosystem; figures in `### Sources` | `dirs` 7.0.0 released 2026-09-05; `directories` 6.0.0 released 2025-01-12 |
| **Full set hand-rolled over `std`** | XDG Base Directory Specification v0.8; py `src/py_launch_blueprint/core/paths.py` at pin | py-launch-blueprint itself; `uv` partially (it hand-rolls `parse_xdg_path` *on top of* `etcetera`) | py pin `b08bccfb`, read 2026-09-17 |
| **Config-only, hand-rolled** (ts's shape) | ts `src/lib/xdg-paths.ts` at pin, whose header cites `cli-standards R5.3` | ts-launch-blueprint itself | ts pin `cb1cbcb2`, read 2026-09-17 |
| **Paths owned by a config framework** (`confy`) | https://rust-cli.github.io/book/in-depth/config-files.html — the Rust CLI book's only named recommendation | `confy` 2.0.0 (which itself depends on `etcetera ^0.10.0`) | the book page carries an unresolved `TODO` where XDG guidance would go; read 2026-09-17 |
| **Linux-only XDG via `xdg`** | https://docs.rs/xdg/3.0.0/xdg/ | `whitequark/rust-xdg`, 197 GitHub stars | `xdg` 3.0.0 released 2025-05-04 |

### Excluded by gate

**No candidate is excluded by a numbered fitness gate.** Gate-by-gate, for the
three shortlisted crates (`etcetera` 0.11.0, `directories` 6.0.0, `xdg` 3.0.0),
with `dirs` 7.0.0 carried alongside `directories` because it is the same codebase:

| Gate | `etcetera` 0.11.0 | `directories` 6.0.0 / `dirs` 7.0.0 | `xdg` 3.0.0 |
|---|---|---|---|
| **1. Licence compatible with `MIT OR Apache-2.0`** | **`inapplicable — owner ruling 2026-09-12 (Q7.B)`** (`docs/port/OWNER-REVIEW.md`: no licence check for anything the template uses). Recorded for information only, never as a filter: crates.io reports `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. For information: `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. For information: `Apache-2.0 OR MIT` |
| **2. MSRV within "stable minus 2 minors" (= 1.96, from local stable 1.98.0)** | **Pass.** `rust_version` = **1.87.0** (crates.io `/versions`, 2026-09-17), 9 minors of headroom. Dependency tree on Linux/macOS is one crate, `cfg-if ^1` (declares no `rust-version`; a macro-only crate that has built on every stable for years). `windows-sys ^0.61` is `target = cfg(windows)` and never enters an ubuntu/macOS resolve for compilation. Unreleased master raises the crate to `rust-version = "1.95.0"` and edition 2024 — still inside the 1.96 floor, but this is a **re-verify trigger**, not a current fact | **Cannot be verified from the manifest: neither `directories` 6.0.0 nor `dirs` 7.0.0 declares `rust-version`** (crates.io `/versions`, 2026-09-17), so no floor claim is checkable and the policy's "declared as rust-version in Cargo.toml" property does not hold for the dependency. Not scored as a gate failure — the policy binds the template's own crates — but recorded as an unverifiable. Tree: `dirs-sys ^0.5.0` → `option-ext ^0.2.0`, `libc ^0.2` (`cfg(unix)`), `redox_users ^0.5` (`cfg(target_os="redox")`), `windows-sys >=0.59.0` (`cfg(windows)`) | **Pass.** `rust_version` = **1.60.0**. Sole dependency `serde ^1.0` is **`optional: true`** (crates.io `/dependencies`, 2026-09-17), so the default build has none |
| **3. No open RustSec advisory; `unsafe` posture** | **Pass — zero open.** `https://rustsec.org/packages/etcetera.html` → **404**, and `gh api repos/rustsec/advisory-db/contents/crates/etcetera` → 404. Both paired against the live control `anyhow`, which returns **200** / lists `RUSTSEC-2026-0190.md`, so the 404 is evidence rather than an artefact. `unsafe` posture: none on Unix — the crate's only platform FFI is `windows-sys` under `cfg(windows)`; CI runs `cargo miri test` with `-Zmiri-strict-provenance` | **Pass — zero open.** Both pages return **200**, but the advisories they carry are `RUSTSEC-2020-0054` (`directories`) and `RUSTSEC-2020-0053` (`dirs`), each `informational = "unmaintained"` and each **`withdrawn = "2021-04-19"`** with `patched = []` (advisory TOML read via `gh api repos/rustsec/advisory-db/contents/crates/<n>/<id>.md`, 2026-09-17). A withdrawn informational advisory is not an open advisory. `unsafe` posture: FFI via `dirs-sys` → `libc`/`windows-sys` | **Pass — zero open.** 404, same paired control |
| **4. Builds and is tested on `ubuntu-latest, macos-latest`** | **Pass, with primary evidence.** `.github/workflows/ci.yaml` on master: `matrix.os: [macos-latest, ubuntu-latest, windows-latest]` × `toolchain: [beta, stable, 1.95.0]`, running `cargo clippy -- -Dwarnings` and `cargo test`, plus separate `miri` and `rustfmt` jobs (retrieved 2026-09-17). Windows supported and tested, though not required here | **Pass by stated platform support** (the crate's entire purpose is the three-platform table, and its docs state per-platform values for every accessor). Its CI configuration was not read — the canonical repository moved to Codeberg and I did not fetch its workflow; recorded as unverified | **Pass by stated platform support**; its CI was not read — recorded as unverified. Note `xdg` is XDG-only by design and offers no Windows semantics |
| **5. Default features / async-runtime coupling** | **Pass.** No Cargo features at all in `0.11.0`; no async runtime, no `tokio`, no executor. Purely synchronous `PathBuf` arithmetic | **Pass.** No async coupling; `directories` has no features, `dirs` exposes none that matter here | **Pass.** One optional feature, `serde`; off by default; no async coupling |
| **6. Binary-size and compile-time cost (qualitative)** | **Negligible.** On Linux/macOS the added tree is one crate plus `cfg-if` (a macro-only crate with no codegen); master has dropped `cfg-if` entirely. No build script, no proc-macro, no generics to monomorphise; the emitted code is a handful of `PathBuf::join` calls and env reads. Expect single-digit KB of binary and well under a second of cold compile | **Small but larger.** Adds `dirs-sys` + `option-ext` + `libc`; `libc` is usually already in the tree, `option-ext` is tiny; no build script. Still small, but strictly more than `etcetera` | **Smallest.** Zero mandatory dependencies with `serde` off |

Excluded on **maintenance or capability** rather than by a numbered gate, recorded
here so the survey is complete:

- **`dirs-next` 2.0.0** — last release **2020-10-22**; repository `xdg-rs/dirs`
  (`gh api repos/xdg-rs/dirs`, 212 stars, `pushed_at` **2023-04-08**, retrieved
  2026-09-17). Maintenance: **dormant** — it exists only because of the 2020
  `unmaintained` advisories that were themselves withdrawn in 2021, and its reason
  to exist has therefore lapsed. Excluded.
- **`platform-dirs` 0.3.0** — last release **2020-09-26**; `cjbassi/platform-dirs-rs`,
  41 stars, `pushed_at` **2021-04-12**. Maintenance: **dormant**. Excluded.
- **`app_dirs2` 2.5.5** — last release **2023-02-15**; `app-dirs-rs/app_dirs2`,
  37 stars, `pushed_at` **2024-09-05**, 90-day downloads 75,512. Maintenance:
  **at-risk** (a maintained fork of an abandoned project, with no release in 3½
  years and two-figure star count). Excluded on adoption and maintenance.
- **`directories` 6.0.0 / `dirs` 7.0.0** — **not** excluded by a gate; excluded from
  the recommendation on the macOS capability absence documented above. See
  *Ranked runner-up* for the condition under which the family wins anyway.
- **`xdg` 3.0.0** — not excluded by a gate; excluded on fit (see below).
- **`home` 0.5.12** — not a candidate for the directory set; it resolves only the
  home directory and carries no XDG semantics. Noted because `etcetera`'s own
  manifest says *"We should keep this in sync with the `home` crate"*, which is a
  useful signal that the two track the same home-resolution behaviour.

**Maintenance state by rubric, for the shortlist.**

- **`etcetera` — `active`.** Release 0.11.0 on 2025-10-28 (10.6 months before
  retrieval, which under the rubric is a trigger to investigate, never a verdict).
  Investigation: repository `pushed_at` **2026-08-04**, not archived, with a
  substantive commit that month ("Drop cfg-if dependency (#43)"); `master` carries
  an unreleased 0.12.0 at edition 2024 / MSRV 1.95.0; issue volume is genuinely low
  (only **2** open issues, `gh api "search/issues?q=repo:lunacookies/etcetera+is:issue+is:open"`
  → `total_count` 2, retrieved 2026-09-17). Issue responsiveness over the
  prescribed **10 most recently opened issues** (`gh api "repos/lunacookies/etcetera/issues?state=all&per_page=100&sort=created&direction=desc"`
  filtered on `.pull_request == null`; the repository has **14** non-PR issues in
  total, so the 10 are #42, #41, #37, #35, #28, #27, #26, #24, #23, #21). Days to
  first maintainer response — maintainers taken as `utkarshgupta137`, `lunacookies`
  and `gennyble`, all three established by merge/release commits, `utkarshgupta137`
  by the `v0.11.0` release commit and the merges of #38/#39/#40 — were: #42 **0.006**,
  #24 **0.007**, #37 **0.267**, #41 **1.817**, #28 **4.55**, #27 **36.95**,
  #26 **42.94**; #35, #23 and #21 are **unanswered**. **Median over the 10 = 3.18
  days** (unanswered ranked last, so the 5th/6th values are 1.817 and 4.55);
  median over the 7 answered = **1.82 days**; **unanswered count 3**. That is a
  materially worse picture than the 4-issue sample would have shown, and it is a
  small-project profile: fast when the maintainer is present (#42 in 8.5 minutes,
  #24 in 9 minutes), with 2025-01/02 issues cleared in a single batch on 2025-02-27
  and three feature requests never answered.
  Verdict `active`: recent repository work, sub-day median response, no `at-risk`
  signal.
- **`directories` — `stable-quiet`.** Last release 2025-01-12, which triggers
  investigation. Investigation finds a **relocation, not an abandonment**:
  `gh api repos/soc/directories-rs` reports `archived: true`, `pushed_at`
  2025-01-12, 837 stars — but that GitHub repository is now a stale mirror, and the
  live project is `https://codeberg.org/dirs/directories-rs` (`archived: false`,
  49 stars, `updated_at` 2026-03-22, **17** open issues; Codeberg API, retrieved
  2026-09-17), whose sibling `dirs` shipped **7.0.0 on 2026-09-05** from
  `https://codeberg.org/dirs/dirs-rs` (`archived: false`, `updated_at` 2026-09-05,
  13 open issues). The rubric's `dormant` bar (an unpatched advisory, a broken build
  on current stable, or a maintainer's own notice) is not met, and the GitHub
  `archived` flag is a hosting artefact rather than a maintainer notice about the
  crate. Issue responsiveness over the prescribed 10 most recently opened issues
  (`GET https://codeberg.org/api/v1/repos/dirs/directories-rs/issues?state=all&type=issues&limit=10&sort=created&order=desc`
  plus each issue's `/comments`, maintainer taken as `soc`, retrieved 2026-09-17):
  #89 **0.16** days, #84 **0.30**, #83 **0.44**, #117 **0.67**, #88 **0.89**,
  #116 **9.05**, #92 **137.5**, #85 **899.8**; #90 and #87 **unanswered**.
  **Median over the 10 = 4.97 days**; median over the 8 answered = **0.78 days**;
  **unanswered count 2**. Verdict `stable-quiet`. **Caveat: the GitHub issue-count
  endpoint the figure table prescribes cannot be used here** — `gh api "search/issues?q=repo:soc/directories-rs+is:issue+is:open"`
  returns HTTP **422 Validation Failed** for the archived repository, so the open-issue
  and responsiveness figures above come from the Codeberg API instead and are
  labelled as such.

  **What those ten issues contain is more decisive than how fast they were answered.**
  Four of the ten are users asking for exactly the behaviour this item needs, and the
  maintainer has declined it in writing: #117 "Request/Discussion: Support `XDG_*` on
  macOS" (2026-06-16) — maintainer `soc`, same day: *"this is not going to be
  supported, see https://codeberg.org/dirs/directories-rs/issues/47#issuecomment-2842344.
  Thanks, Simon"*; #89 "Optionally use XDG directories on mac" (2024-08-08, closed);
  #84 "Feature Request: Force MacOS to behave like Linux" (2023-07-06, closed); and
  #116 "Feature Request: ProjectDirs.runtime_dir() on MacOS" (2026-03-24, closed).
  This upgrades the macOS gap from *currently absent* to **a maintainer's stated,
  permanent design position**, which is the strongest possible form of the argument
  against picking this family for a port whose CI matrix includes `macos-latest`.
- **`dirs` — `active`.** 7.0.0 released 2026-09-05, twelve days before retrieval.
- **`xdg` — `stable-quiet`.** 3.0.0 released 2025-05-04; `whitequark/rust-xdg`
  `pushed_at` 2025-05-04, not archived, 197 stars, **4** open issues. A small,
  finished, single-purpose crate; no `at-risk` signal.

### Up-and-comers

**There is no credible up-and-comer in this category, and that is itself the
finding.** Three independent checks agree:

1. The crates.io category `config` surfaces no new base-directory entrant; the only
   library-shaped alternatives to the two incumbent families (`app_dirs2`,
   `platform-dirs`, `dirs-next`) are all **older** than the incumbents, with last
   releases in 2020, 2020 and 2023 respectively.
2. The Rust CLI working group's book has an unfilled `TODO` where XDG guidance would
   go and names only `confy` — which is itself built on `etcetera`. A working group
   would be the natural incubator for a new pattern here; it has none.
3. The actual movement in the category is *consolidation*, not novelty: `uv`
   migrating off macOS-native paths onto XDG (visible as its `legacy_user_*_dir`
   functions), and the `dirs`/`directories` family relocating to Codeberg.

The closest thing to an up-and-comer is `etcetera`'s own unreleased **0.12.0** on
`master` — edition 2024, `rust-version = "1.95.0"`, `cfg-if` dropped in favour of
`cfg_select!`. It changes no API this item depends on. It is listed as a re-verify
trigger, not as a candidate.

### Fit for this template

Argued per target shape, as required.

**CLI (`rslbp`).** The full set, all four accessors, resolved once at the
composition root. This is where the org standard binds hardest — `R5.3` is a CLI
standard — and where the consumers actually are: R67's crash record (CLI surface
only, per its decision), R59's file log sink, R54's user-tier config file, and any
future cache. `R5.9` ("a tool that caches remote data SHOULD document cache
location … and SHOULD offer a cache-clearing command") is the reason `cache_dir()`
ships even before anything caches: a `rslbp cache clear` added later must not have
to invent a location retroactively, since the location would already be in users'
filesystems. Failure mode to design for: the CLI can be run by a daemon user with no
`HOME`, so `Paths::from_process_env()` must be `Result`, not a panic or a
`lazy_static` unwrap. **`bat` gets this wrong-ish and is instructive**: its
`BatProjectDirs::new()` returns `Option`, but the crate then forces it through a
static — `pub static PROJECT_DIRS: Lazy<BatProjectDirs> = Lazy::new(|| BatProjectDirs::new().expect("Could not get home directory"));`
(`src/bin/bat/directories.rs`, final two lines, retrieved 2026-09-17) — so a missing
home directory is a panic, which under R67's contract surfaces as exit `101` rather
than a typed envelope. Copy the wrapper struct; do not copy the static.

**Library (`rs_launch_blueprint`).** The `Paths` type lives here, and only the
type. Three reasons it belongs in the library rather than the CLI crate: both
binaries need it; R01's composition root pattern wants the value constructed at the
root and handed down rather than reached for from a static; and a library consumer
embedding the template's engine needs to be able to *supply* paths rather than have
them discovered behind its back — which the `from_strategy(&impl BaseStrategy)`
constructor gives it for free. R67's layering rule is respected exactly: the module
computes and returns paths, opens nothing, creates no directory, and adds no
`anyhow` dependency (`etcetera` returns its own `HomeDirError`, which the library's
`thiserror` enum wraps as `RSLB101`). This is the one place where a *free-function*
surface would actively hurt: a library whose paths come from process env cannot be
embedded twice in one process with different roots.

**Web (`web` Cargo feature, R69).** **The web surface must not construct `Paths` at
startup, and should generally not use them at all.** A container image (R51) commonly
runs as a numeric UID with no `HOME` entry, in which case
`choose_base_strategy()` returns `Err(HomeDirError)`; a service that resolved paths
eagerly in its composition root would fail to boot for a reason that has nothing to
do with its configuration. The web surface's configuration comes from environment
variables (R77, `web-env-settings`), its logs go to stdout/stderr for the platform to
collect (R58's web profile), and its state belongs in a database or a mounted volume,
not in `$XDG_STATE_HOME`. Concretely: `Paths::from_process_env()` is called lazily at
the CLI call sites that need a path, never unconditionally in a shared startup path.
This is a *justified per-shape difference*, not a weakening of the principle — the
principle is about per-user files, and a service has no user.

**Why not `xdg` 3.0.0 despite its excellent gate profile.** It implements the XDG
spec and nothing else: on Windows it has no semantics at all. `target-os-matrix`
excludes Windows from CI but the template is not thereby *forbidden* to run there,
and a fork that adds Windows would have to replace the crate rather than change a
strategy. `etcetera` costs the same and keeps that door open, so `xdg` gives up
optionality for no gain.

**MEDIUM question — is Windows-analogue capability free?** Yes, on both counts asked.
Dependency cost: `windows-sys ^0.61` is declared under `[target.'cfg(windows)'.dependencies]`
(etcetera's own `Cargo.toml`, retrieved 2026-09-17), so it is never fetched, compiled
or linked in an `ubuntu-latest` or `macos-latest` build — the Windows capability is
literally free on the CI matrix. Complexity cost: one branch, and the branch is inside
the crate, not in this template. What it buys: `choose_base_strategy()` on Windows
returns the `Windows` strategy (`%FOLDERID_RoamingAppData%` etc.), whose `state_dir()`
is `None` — which is why the wrapper collapses state onto data, reproducing exactly
what py already documents for Windows ("state — `%LOCALAPPDATA%\plbp` (Windows has
no data/state split)", `paths.py` docstring at pin). **This item does not adjudicate
Windows behaviour**, because py and ts genuinely disagree (py platform-native, ts
`~/.config` everywhere citing `R5.3`) and `R5.3` permits both; the disagreement is
recorded, the Rust template inherits whatever `etcetera`'s `Windows` strategy does,
and that path is untested because Windows is off-matrix.

**LOW question — do published Rust CLI templates or style guides document a full XDG
directory-set pattern?** For **style guides**, no, and I verified it: the Rust CLI
working group's book discusses config files only, recommends `confy`, names no
directory crate, and leaves an unresolved `TODO` where XDG guidance would go
(https://rust-cli.github.io/book/in-depth/config-files.html, retrieved 2026-09-17).
For **templates**, this item surveyed none — no `cargo-generate` template was fetched
or read here, and I decline to borrow R06's template survey, which examined
`rust-github/template` and `ratatui/templates` for an `unsafe` policy and says
nothing about directories. The template half of this question is therefore an
**evidence gap**, recorded rather than filled; it is also low-value, because the
answer does not turn on it. What the recommendation rests on instead is the org's
own standard (`R5.3`) plus production practice in `uv`, `bat` and `jj` — an argument
for this template shipping the pattern, not against.

### Recommendation

**Resolve the full XDG-style directory set — config, data, state and cache — as four
accessors on one template-owned `Paths` value, built on `etcetera` 0.11.0's
`choose_base_strategy()`. Do not expose a runtime directory. Namespace every base
under the single segment `rslbp`.**

Unconditional, not contingent on R59 or R67. Four reasons, in decreasing force:

1. **`R5.3` is a MUST and `org-locked`.** The contingent framing in this item's
   prompt and in ledger row F249 predates that constraint being applied; an
   org-locked MUST is not something this item may trade against convenience.
2. **A consumer already exists.** R67 is owner-accepted with a crash record whose
   "location is not decided here and the default sink is a no-op until R57 answers".
   Answering "config-only" would leave an accepted decision permanently unimplementable,
   and `R5.3` puts logs in State.
3. **The cost of being early is measurably near zero** — one dependency, one
   `cfg-if`, no build script, no features, no async coupling, `rust-version` 1.87.0
   against a 1.96 floor, and the Windows code target-gated out of the CI matrix
   entirely. The cost of being late is not zero: a state directory chosen after users
   have files in a different place is a migration, which is exactly the cost `uv` is
   visibly paying in `legacy_user_state_dir()`.
4. **It restores agreement at the declared level.** py has the four kinds; ts has one
   because it had nothing to put in the other three and said so. Rust has a crash
   log and a file sink on the way, so the Rust template is in py's situation, not
   ts's. Agreement here is about *the principle and the standard*, not about the
   accessor count — and the follow-on project that revisits ts would add the kinds
   when ts grows a consumer, using the same rule.

Deliberately **not** recommended: a runtime-directory accessor. The template has no
socket, FIFO or lock file; the spec gives `XDG_RUNTIME_DIR` no fallback; and
`etcetera`'s own trait documentation warns that *"The XDG Base Directory Specification
places additional requirements on this directory related to ownership, permissions,
and persistence. This library does not check these requirements."* Shipping an
accessor to an unchecked-contract directory that nothing uses is a liability.
`R5.3`'s Runtime row is satisfiable the day something needs it, by one method
delegating to `BaseStrategy::runtime_dir()`; document that in the paths module.

### Ranked runner-up

**`directories` 6.0.0 (`ProjectDirs`), or its low-level sibling `dirs` 7.0.0.**
It ranks second on every axis except the one that decides this item: it is named in
the standard's own Appendix E, it has the deeper adoption history (`dirs` 90-day
downloads **77,979,289** vs `etcetera`'s **32,829,812**), it shipped a release
twelve days before retrieval, and it gives a richer accessor set (`preference_dir`,
`config_local_dir`, `data_local_dir`, plus the user-directories family).

Note that the winning condition below is the *only* one available, because the
family's maintainer has ruled out the alternative: on issue #117 (2026-06-16) `soc`
answers a request to "Support `XDG_*` on macOS" with *"this is not going to be
supported"*. A future `directories` release will not close the gap.

**The condition under which it wins:** if the owner decides that *macOS should use
Apple-native locations* — `~/Library/Application Support/<tool>` for config and
data, `~/Library/Caches/<tool>` for cache — rather than XDG locations. `R5.3`
explicitly permits that deviation ("Native non-Linux equivalents are permitted
deviations … but XDG paths are the canonical reference"), and if it were taken,
`directories`' macOS behaviour becomes the feature rather than the defect. Two
consequences the owner would have to accept with it: the template would **diverge
from both py and ts on macOS**, which currently agree on `~/.config` (py's module
docstring covers "POSIX (Linux, macOS)" with XDG; ts's header states `~/.config`
"on ALL platforms … for parity with the source and cli-standards R5.3"); and there
would still be **no state directory on macOS**, so the crash log and file sink would
need a separately-chosen home there. Because of that second consequence, even under
the Apple-native branch the better construction is `etcetera`'s
`choose_native_strategy()` — which returns the `Apple` strategy on macOS — rather
than `directories`. So the runner-up's winning condition is narrow: it wins only if
the owner *also* wants `directories`' extra accessors (`preference_dir`, the
user-directories family), which nothing in this template currently asks for.

A distant third, `xdg` 3.0.0, wins only if the owner decides the template will never
support Windows in any form, in which case its zero-dependency default build is a
marginal simplification.

### Tradeoffs

**What the recommendation gives up versus `directories`/`dirs`.**
1. *Accessor breadth.* No `preference_dir()`, no `config_local_dir()`/`data_local_dir()`
   split, no user-directories family (`download_dir`, `document_dir`, …). Accepted:
   `R5.3` asks for five purposes, not nineteen; nothing in a CLI + library + web
   template wants the user's Downloads folder, and a roaming/local split is a
   Windows concept on a matrix that excludes Windows.
2. *Raw adoption depth.* `dirs` has ~2.4× the 90-day downloads. Accepted under the
   survey method's explicit rule that gates and fit precede popularity: download
   count does not create a macOS state directory.
3. *Familiarity.* `directories` is the name most Rust developers reach for first, and
   a contributor may propose it in review. Mitigated by a comment in the paths module
   citing the macOS `state_dir() -> None` fact and the docs.rs URL, so the question is
   answered once in the source rather than repeatedly in review.

**What it gives up versus a hand-rolled `std` implementation (py's literal shape).**
1. *Zero dependencies.* Accepted: one dependency with one transitive macro crate, no
   build script, target-gated Windows FFI.
2. *Total control of the fallback table.* Accepted, and it is a gain rather than a
   loss — the crate's fallbacks were verified above to be character-for-character
   the spec's, including the absoluteness rule that py implements and ts does not.
3. *A directly injectable environment.* Partially given up: `etcetera`'s `Xdg` has
   exactly one constructor, `Xdg::new() -> Result<Self, HomeDirError>`, with no
   `with_home_dir` and no injected env lookup (docs.rs 0.11.0, retrieved 2026-09-17).
   Recovered at the template's own layer, because `BaseStrategy` is unsealed and a
   test fake implements it in six lines; the env-reading path itself is then covered
   by a child-process integration test instead of a unit test. This is the single
   real ergonomic cost of the pick and it is the reason the surface is a struct.

**What it gives up versus ts's config-only shape.**
1. *Three accessors and a crate the template could have done without for now.*
   Accepted: `R5.3` removes the option, and R67 removes the "for now".
2. *A slightly larger public API surface to keep stable* (R04's concern). Accepted:
   four total functions returning `&Path`, with no generic parameters leaking —
   `from_strategy` takes `&impl BaseStrategy`, which does put `etcetera` in the public
   API. If R04's enforcement objects to a dependency type in a public signature, the
   escape is to make `from_strategy` take the four `PathBuf`s directly and keep the
   `BaseStrategy` bridge private with a `#[doc(hidden)]` or test-only constructor.
   Flagged for P03 rather than decided here.

**What it gives up on Windows.** Untested behaviour, by construction: `state_dir()`
falls back to the data directory, which matches py's documented Windows shape but is
not exercised by CI. Accepted because Windows is outside `target-os-matrix`; recorded
so that widening the matrix has a known first test to write.

### Parameters

**Owned parameters: none.** R57's `owns:` field is empty in its `## Couplings`
block and `research/CLAUDE.md` shows `owns: —` for R57, so **this item registers no
entry in `docs/port/PARAMETERS.md`**. The decision content above is the answer; it is
consumed by reading this item's `DECISION.md`, not by resolving a parameter name.

That is a registry gap worth the owner's attention, because R67's accepted decision
says its crash sink stays a no-op "until R57 answers" and its `## Parameters` section
records (and correctly declines to escalate) a Perplexity `CONFLICT:` line aimed at a
parameter named `R57 state-directory` that does not exist. If the owner wants the
dependency machine-checkable rather than prose-linked, the parameter to create would
be **`xdg-directory-set`**, owned by R57, with the value being the four-accessor
contract, the `rslbp` namespace segment and the `etcetera`-`choose_base_strategy`
mechanism. **I cannot create it**; naming it is the most this item may do.

Assumed (consumed) parameters, none of which this item asks to change:

- `assumes rust-edition = 2024` (fixed). Load-bearing: it is why `std::env::set_var`
  is `unsafe` and therefore why the accessor surface is a struct.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed). Evaluated at 1.96 against local stable 1.98.0; `etcetera` 0.11.0's 1.87.0 clears it.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). Load-bearing: `macos-latest` is the entire reason `directories` loses.
- `assumes license = MIT OR Apache-2.0` (fixed). Recorded; not evaluated as a gate, per the owner ruling.
- `assumes build-tool-output-shape = …[[bin]] … name rslbp…` (researched, R49). Load-bearing: it supplies the tool name that `R5.3` namespaces under, and `CARGO_BIN_EXE_rslbp` is how the acceptance test finds the binary.
- `assumes error-taxonomy-exit-codes = error-contract/v1 …` (researched, R67). Used for the failure mapping below.
- `assumes commit-message-convention`, `package-manager-invocation` — not consulted.

**R67 catalogue check — no `CONFLICT:` line is raised.** The one new failure this
item introduces is *the home directory cannot be resolved* (`etcetera::HomeDirError`:
no `HOME`, no `XDG_*`, no platform home). R67's catalogue expresses it without a new
row, in two places, both already owner-accepted:

- For the **crash record**, R67 AC7 settles it: "A crash-record write failure leaves
  the exit code and the envelope unchanged." An unresolvable state directory is a
  write failure by another name; the sink stays silent and nothing in the catalogue
  is consulted.
- For **every other consumer**, the failure is `RSLB101` (I/O → exit `1`) when a
  command needs a path it cannot compute, or `RSLB104` (config layer unreadable →
  exit `1`) when it is the user-tier config file specifically that cannot be located —
  a choice that belongs to R54, not here. Both land on exit `1`, so the observable
  contract is the same either way and no new exit code is needed.

R67's `ErrorCode` enum is `#[non_exhaustive]` and append-only by design, so if P03
later wants a dedicated row for environment resolution, adding one is R67's ordinary
extension path and not a conflict with what R67 decided.

### Migration implications

File-level changes in the template. Nothing here is scaffolded — the Rust template
does not exist and P03 builds it; this is the change list a P03 task would execute.

| File | Change |
|---|---|
| root `Cargo.toml` | add `etcetera = "0.11"` to `[workspace.dependencies]` (pinned as a caret requirement; the lockfile is what actually pins, per R23/R41) |
| library crate `Cargo.toml` | add `etcetera = { workspace = true }` to `[dependencies]` |
| `crates/<lib>/src/paths.rs` **(new)** | the `Paths` type, `TOOL_NAME`, `from_strategy`, `from_process_env`, four `&Path` accessors, and a doc comment recording (a) why `state_dir()` collapses onto the data directory when the strategy returns `None`, (b) why no runtime accessor is exposed and the one-line addition that would add it, and (c) the `directories`-on-macOS fact with its docs.rs URL, so the question is not re-litigated in review |
| `crates/<lib>/src/lib.rs` | `pub mod paths;` — and an R04 decision on whether `paths::Paths` is part of the committed public surface (recommended: yes, it is the seam the web/CLI/embedding consumer needs) |
| `crates/<lib>/src/error.rs` | one `thiserror` variant wrapping `etcetera::HomeDirError`, mapped to `RSLB101` |
| `crates/<cli>/src/main.rs` (composition root) | one `Paths::from_process_env()?` at the root, passed down; nothing else in the workspace reads an `XDG_*` variable |
| `crates/<cli>/tests/paths.rs` **(new)** | the `assert_cmd` integration tests in `### Validation strategy` |
| `crates/<lib>/src/paths.rs` `#[cfg(test)]` | the `FakeStrategy` unit tests |
| `README.md` | a "Files and directories" section reproducing `R5.3`'s table with `rslbp` substituted, as `R5.3`'s "documented" obligation and `R5.9`'s cache-location obligation |
| `CHANGELOG.md` | nothing at this stage — a template-internal addition ahead of first release |

Changes this item **enables** in other items, which those items make, not this one:

- **R67 / F302** — the crash sink's default becomes `paths.state_dir().join("rslbp_crash.jsonl")` instead of a no-op; its `0600` permission, NDJSON format and sanitization rules are unchanged and remain R67's.
- **R59 / F256–F261** — the file sink's default becomes `paths.state_dir().join("rslbp.log")` instead of a hardcoded or relative path; rotation and precedence remain R59's.
- **R54 / F231, F247** — the user config tier consumes `paths.config_dir().join("rslbp_config.toml")` rather than resolving a second time, and inherits `etcetera`'s macOS-XDG behaviour, which is the behaviour F247 requires and `directories` would have dropped. `$XDG_CONFIG_DIRS` and the system tier stay R54's; `etcetera` does not model them (`uv` hand-rolls `locate_system_config_xdg` for exactly this reason, which is a ready reference for R54).
- **R51 (container image)** — nothing to change, provided the web surface does not resolve paths eagerly; worth one line in the image documentation saying the service needs no `HOME`.

### Validation strategy

**Every check below is proposed, not executed.** No Rust code exists in this
repository to run them against; this item is research, and P03 writes the template.
The one thing actually *executed* in producing this report was endpoint retrieval and
source reading, enumerated under `### Sources`.

*Proposed — unit, hermetic, no `unsafe`, runs on both CI legs* (`cargo test -p <lib>`):

```rust
struct FakeStrategy { home: PathBuf, state: Option<PathBuf> }
impl etcetera::base_strategy::BaseStrategy for FakeStrategy {
    fn home_dir(&self) -> &Path { &self.home }
    fn config_dir(&self) -> PathBuf { self.home.join(".config") }
    fn data_dir(&self)   -> PathBuf { self.home.join(".local/share") }
    fn cache_dir(&self)  -> PathBuf { self.home.join(".cache") }
    fn state_dir(&self)  -> Option<PathBuf> { self.state.clone() }
    fn runtime_dir(&self)-> Option<PathBuf> { None }
}
```

- **V1 (B1, B4).** `Paths::from_strategy(&FakeStrategy{ home: "/h", state: Some("/h/.local/state") })`
  yields exactly `/h/.config/rslbp`, `/h/.local/share/rslbp`, `/h/.local/state/rslbp`,
  `/h/.cache/rslbp`. Expected: four distinct paths, each ending in one `rslbp` segment.
- **V2 (Windows-shape totality).** the same with `state: None` yields
  `state_dir() == data_dir()`. Expected: equal, and `/h/.local/share/rslbp`.
- **V3 (B5).** after V1, `Path::new("/h").exists()` is false — the constructor created
  nothing. Expected: no filesystem effect.

*Proposed — integration, through the built binary, the only way to exercise the real
environment without `unsafe`* (`cargo test -p <cli> --test paths`; uses
`assert_cmd::Command::cargo_bin("rslbp")`, which resolves through `CARGO_BIN_EXE_rslbp`
per R49's `build-tool-output-shape`). These are the checks that would fail under
`directories` and are therefore the ones that matter most:

- **V4 (B2) — the macOS-critical check.**
  `.env("HOME", tmp).env("XDG_STATE_HOME", tmp.join("s")).args(["debug","paths","-o","json"])`
  → the `state` field equals `<tmp>/s/rslbp`. Expected identical output on
  `ubuntu-latest` **and** `macos-latest`. Under `directories` this test cannot pass on
  macOS at all, because `state_dir()` is `None` there.
- **V5 (B3) — empty and relative overrides.** the same with
  `XDG_STATE_HOME=""` and then `XDG_STATE_HOME="rel/ative"` → both yield
  `<tmp>/.local/state/rslbp`. Expected: identical on both runners; this is the
  freedesktop absoluteness rule and py's `is_absolute()` check.
- **V6 (B6) — no home.** `.env_remove("HOME")` with every `XDG_*` removed, running a
  subcommand that needs a path → exit status `1`, stderr a single JSON object whose
  `error.code` is `"RSLB101"`, stdout byte-empty (R67's envelope contract).
- **V7 (B5, end-to-end).** after V4, assert that `<tmp>/s/rslbp` does **not** exist —
  resolution alone creates nothing; only a write site does.
- **V8 (B7) — layering.** `cargo tree -p <lib> -i anyhow` produces no output, and a
  `grep` gate (or a `clippy` `disallowed_methods` entry) confirms `std::fs` write APIs
  appear nowhere in `paths.rs`.

*Proposed — CI wiring.* V1–V8 run on both legs of `target-os-matrix` inside whatever
job shape R11 selects; no new job is needed. V4 and V5 are the two that must not be
allowed to run on only one leg, since the entire crate choice rests on their macOS
result.

*Proposed — documentation check.* R82's docs gate asserts that the README's
directory table and the `paths.rs` doc comments name the same four paths the binary
prints, so the `R5.3` "documented" obligation cannot silently rot.

### Confidence & re-verify trigger

**Confidence: high** on the decision (resolve the full set) and **high** on the
mechanism (`etcetera` via `choose_base_strategy()`, wrapped).

The decision rests on a MUST-level, org-locked rule read directly from the pinned
blob, plus an already-accepted downstream consumer in R67 — two independent grounds,
either of which alone would be sufficient. The mechanism rests on a capability fact
about a competitor (`state_dir() -> None` on macOS) that is stated by that
competitor's own documentation for both crates in the family, corroborated by the
port's own `BASELINE-REVIEW.md:113`, and on an absoluteness-check behaviour read from
`etcetera`'s source rather than inferred from prose.

**Moderate** confidence on two sub-points, flagged as such:
- Whether `Paths::from_strategy(&impl BaseStrategy)` survives R04's public-API
  enforcement with an `etcetera` type in the signature. An alternative construction is
  given under *Tradeoffs*; it does not change the recommendation.
- Whether the acceptance surface is spelled `rslbp debug paths` — the subcommand name
  is R60's and the `-o json` surface is R66's. The *check* is what matters; the spelling
  is P03's.

**Re-verify by 2027-03-17, or earlier on any of:**
- a RustSec advisory opening against `etcetera`, `cfg-if`, or (if the runner-up is
  taken) `dirs-sys`/`option-ext` — `https://rustsec.org/packages/etcetera.html` returned
  404 on 2026-09-17;
- **`etcetera` 0.12.0 releasing** — it raises `rust-version` to `1.95.0` and edition to
  2024 on `master`; still inside the 1.96 floor today, but the headroom drops from 9
  minors to 1, so a future bump could cross the floor;
- Rust stable advancing such that the `msrv-policy` floor rises above `etcetera`'s
  declared `rust-version` (today: floor 1.96 vs declared 1.87.0, ample; after 0.12.0:
  floor 1.96 vs declared 1.95.0, one minor of margin — this becomes the live trigger);
- the org CLI Design Standard revising `R5.3` or its `org-locked` status — re-read the
  blob, not a cached quotation;
- `target-os-matrix` gaining `windows-latest`, which makes the untested Windows
  state/data collapse a tested path and requires a test for it;
- R54 selecting a config-discovery mechanism that resolves the config directory
  independently — the two must not both resolve it, and this item's `config_dir()`
  should be the single source;
- R67 or R59 choosing a crash-log or file-sink location other than `state_dir()`,
  which would mean one of us misread `R5.3`'s "State (logs, history)" row;
- `etcetera` showing an `at-risk` signal — the concrete one to watch is issue #35
  ("Support User Directories?", open and unanswered since 2025-04-05) being joined by
  a cluster of unanswered issues, or `utkarshgupta137` ceasing to merge.

### Sources

Every URL below was retrieved on **2026-09-17** (UTC). Figures carry the endpoint
that produced them.

*Binding standard and specification*
1. Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `/Users/stevemorin/c/cli-standards` — read with `git -C /Users/stevemorin/c/cli-standards show f9de0437baece3383e73ca2c5f48b7ab399b51c7`. Rules quoted: Principle 1; provenance row 10 (`Filesystem paths | XDG Base Directory Specification | org-locked`); `R5.1`; `R5.2`; `R5.3` (MUST, five-row table); `R5.8`; `R5.9`; `R10.1`; Appendix E "Rust — Clap (derive)"; Appendix C checklist line for `R5.3`.
2. XDG Base Directory Specification, **version 0.8, 08 May 2021** — https://specifications.freedesktop.org/basedir/latest/ (the `…/basedir-spec/latest/` URL 301-redirects here).

*Pinned source repositories, read through their pins*
3. py-launch-blueprint at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` — `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/core/paths.py`. Cited: module docstring lines 20–49; `APP_NAME = "plbp"` (:56); `_WINDOWS` (:58-60); `_xdg_override` (:65-75, the `is_absolute()` check); `config_home`/`data_home`/`state_home`/`cache_home`; `config_dir`/`data_dir`/`state_dir`/`cache_dir`; `CONFIG_FILENAME`; `log_file`; `database_file`.
4. ts-launch-blueprint at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` — `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/lib/xdg-paths.ts`. Cited: header comment lines 1–10 (the `cli-standards R5.3` citation and the env-paths rejection); `TOOL_DIR_NAME` (:13); `configDir(env, homedir)` (:22-28).
5. This repository — `docs/port/COMMONALITY.md:251` (F247), `:253` (F249); `docs/port/BASELINE-REVIEW.md:105,113,152,193,354,427,453`; `docs/port/PARAMETERS.md`; `research/topics/67-error-and-exit-code-contract/DECISION.md:33,43,50-51,126,194,278-288,379,383,394-409,846-848`; `research/topics/06-unsafe-code-policy/DECISION.md`; `research/CLAUDE.md`.

*Crate figures — `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`) and `…/versions` (newest unyanked `num`, `created_at`, `rust_version`, `license`), User-Agent header sent*

| Crate | 90-day downloads | All-time | Latest unyanked | `rust_version` | Licence |
|---|---:|---:|---|---|---|
| `etcetera` | 32,829,812 | 108,370,911 | 0.11.0 · 2025-10-28 | 1.87.0 | MIT OR Apache-2.0 |
| `dirs` | 77,979,289 | 329,160,223 | 7.0.0 · 2026-09-05 | *(none declared)* | MIT OR Apache-2.0 |
| `directories` | 12,362,480 | 70,441,621 | 6.0.0 · 2025-01-12 | *(none declared)* | MIT OR Apache-2.0 |
| `xdg` | 3,767,479 | 22,571,082 | 3.0.0 · 2025-05-04 | 1.60.0 | Apache-2.0 OR MIT |
| `home` | 80,968,594 | 422,664,946 | 0.5.12 · 2025-10-23 | 1.88 | MIT OR Apache-2.0 |
| `dirs-next` | 17,480,202 | 166,134,300 | 2.0.0 · 2020-10-22 | *(none)* | MIT OR Apache-2.0 |
| `platform-dirs` | 251,211 | 1,641,378 | 0.3.0 · 2020-09-26 | *(none)* | MIT |
| `app_dirs2` | 75,512 | 1,088,773 | 2.5.5 · 2023-02-15 | *(none)* | MIT |

Dependency listings: `GET https://crates.io/api/v1/crates/etcetera/0.11.0/dependencies` → `cfg-if ^1` (no target) and `windows-sys ^0.61` (`target = cfg(windows)`); `…/directories/6.0.0/dependencies` → `dirs-sys ^0.5.0` (+ `bencher` dev); `…/dirs-sys/0.5.0/dependencies` → `libc ^0.2` (`cfg(unix)`), `option-ext ^0.2.0`, `redox_users ^0.5` (`cfg(target_os="redox")`), `windows-sys >=0.59.0` (`cfg(windows)`); `…/xdg/3.0.0/dependencies` → `serde ^1.0`, `optional: true`.
Reverse dependencies: `GET https://crates.io/api/v1/crates/etcetera/reverse_dependencies?per_page=60` → `meta.total` = 197.

*GitHub — `gh api repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`) and `gh api "search/issues?q=repo:<o>/<r>+is:issue+is:open"` (`total_count`)*

| Repository | Stars | Archived | `pushed_at` | Open issues |
|---|---:|---|---|---:|
| `lunacookies/etcetera` | 150 | false | 2026-08-04 | 2 |
| `soc/directories-rs` | 837 | **true** | 2025-01-12 | search API → **HTTP 422** (archived repo) |
| `whitequark/rust-xdg` | 197 | false | 2025-05-04 | 4 |
| `xdg-rs/dirs` (`dirs-next`) | 212 | false | 2023-04-08 | not queried |
| `app-dirs-rs/app_dirs2` | 37 | false | 2024-09-05 | not queried |
| `cjbassi/platform-dirs-rs` | 41 | false | 2021-04-12 | not queried |
| `astral-sh/uv` | 89,889 | false | 2026-09-17 | not queried (adopter evidence only) |
| `sharkdp/bat` | 60,472 | false | 2026-09-04 | " |
| `astral-sh/ruff` | 49,651 | false | 2026-09-17 | " |
| `sharkdp/fd` | 44,543 | false | 2026-09-16 | " |
| `jj-vcs/jj` | 31,623 | false | 2026-09-17 | " |
| `nextest-rs/nextest` | 3,293 | false | 2026-09-17 | " |

Codeberg (the live homes of the `dirs` family), `GET https://codeberg.org/api/v1/repos/<o>/<r>`: `dirs/dirs-rs` — 48 stars, `archived` false, `updated_at` 2026-09-05, **13** open issues; `dirs/directories-rs` — 49 stars, `archived` false, `updated_at` 2026-03-22, **17** open issues. Maintainer position on XDG-on-macOS: `GET https://codeberg.org/api/v1/repos/dirs/directories-rs/issues/117/comments` → `soc`, 2026-06-16, *"this is not going to be supported, see https://codeberg.org/dirs/directories-rs/issues/47#issuecomment-2842344. Thanks, Simon"* (the linked comment on issue #47 was **not** opened; the quoted reply stands on its own).

**Issue responsiveness — the 10 most recently opened issues per candidate, as the figure table prescribes.**

`etcetera`, via `gh api "repos/lunacookies/etcetera/issues?state=all&per_page=100&sort=created&direction=desc"` filtered on `.pull_request == null` (14 non-PR issues exist in total), with first-maintainer-response times from `…/issues/<n>/comments`, maintainers `utkarshgupta137` / `lunacookies` / `gennyble`:

| Issue | Opened | Days to first maintainer response |
|---|---|---:|
| #42 | 2026-03-27 | 0.006 |
| #41 | 2025-11-29 | 1.817 |
| #37 | 2025-09-02 | 0.267 |
| #35 | 2025-04-05 | unanswered |
| #28 | 2025-02-22 | 4.55 |
| #27 | 2025-01-21 | 36.95 |
| #26 | 2025-01-15 | 42.94 |
| #24 | 2024-12-21 | 0.007 |
| #23 | 2024-10-26 | unanswered |
| #21 | 2024-04-06 | unanswered |

**Median over the 10 = 3.18 days** (unanswered ranked last); median over the 7 answered = **1.82 days**; **unanswered 3**. Maintainer identity (`utkarshgupta137`) established from `gh api repos/lunacookies/etcetera/commits` — the `v0.11.0` release commit and the merges of #38, #39, #40.

`directories`, via `GET https://codeberg.org/api/v1/repos/dirs/directories-rs/issues?state=all&type=issues&limit=10&sort=created&order=desc` plus each issue's `/comments`, maintainer `soc`: #89 **0.16** d · #84 **0.30** · #83 **0.44** · #117 **0.67** · #88 **0.89** · #116 **9.05** · #92 **137.5** · #85 **899.8** · #90 and #87 **unanswered**. **Median over the 10 = 4.97 days**; median over the 8 answered = **0.78 days**; **unanswered 2**. Four of these ten ask for XDG or `runtime_dir` support on macOS — #117, #116, #89, #84 — and the maintainer's reply on #117 (`soc`, 2026-06-16) is *"this is not going to be supported, see https://codeberg.org/dirs/directories-rs/issues/47#issuecomment-2842344. Thanks, Simon"*.

Issue responsiveness for `xdg`, `dirs`, `home` and the three excluded dormant crates was **not** collected; they are not shortlisted for the recommendation.

*Advisories — `https://rustsec.org/packages/<n>.html` with the paired control, plus `gh api repos/rustsec/advisory-db/contents/crates/<n>`*
`etcetera` 404/404 · `xdg` 404/404 · `home` 404 · `dirs-sys` 404 · **control `anyhow` 200**, advisory-db listing `RUSTSEC-2026-0190.md` — so a 404 here is evidence of absence, not of a broken endpoint. `directories` 200 → `RUSTSEC-2020-0054` and `dirs` 200 → `RUSTSEC-2020-0053`, both read in full: `informational = "unmaintained"`, `withdrawn = "2021-04-19"`, `patched = []` — **withdrawn, therefore zero open advisories for every candidate**.

*Maintainer documentation and source*
- https://docs.rs/etcetera/0.11.0/etcetera/ · `…/base_strategy/trait.BaseStrategy.html` (six methods; `state_dir`/`runtime_dir` return `Option<PathBuf>`; implementors `Apple`, `Windows`, `Xdg`) · `…/base_strategy/struct.Xdg.html` (sole constructor `new() -> Result<Self, HomeDirError>`) · `…/app_strategy/struct.AppStrategyArgs.html` (`top_level_domain`, `author`, `app_name`; `bundle_id()`, `unixy_name()`) · `https://docs.rs/etcetera/0.11.0/src/etcetera/base_strategy/xdg.rs.html` (the `env_var_or_none` absoluteness check and the four fallbacks).
- https://raw.githubusercontent.com/lunacookies/etcetera/master/src/base_strategy.rs (full 71-line trait file and the `cfg_select!` dispatch) · `…/master/Cargo.toml` (unreleased 0.12.0, `rust-version = "1.95.0"`, edition 2024, `[target.'cfg(windows)'.dependencies] windows-sys`, and the comment "We should keep this in sync with the `home` crate") · `…/master/.github/workflows/ci.yaml` (the `[macos-latest, ubuntu-latest, windows-latest]` × `[beta, stable, 1.95.0]` matrix, plus `miri` and `rustfmt` jobs).
- https://docs.rs/directories/6.0.0/directories/struct.ProjectDirs.html (every accessor's platform table; `state_dir()` and `runtime_dir()` `None` on macOS/Windows; `config_dir()` = `$HOME/Library/Application Support/<project>` on macOS) · https://docs.rs/dirs/7.0.0/dirs/ and `…/fn.state_dir.html` (macOS and Windows rows `–`).
- https://rust-cli.github.io/book/in-depth/config-files.html (recommends `confy`; no XDG guidance; a `TODO` in place of it).

*Production reference implementations*
- https://raw.githubusercontent.com/astral-sh/uv/main/crates/uv-dirs/src/lib.rs (`choose_base_strategy`, `choose_native_strategy` for legacy migration, `parse_xdg_path` quoting the spec, `locate_system_config_xdg`) and `…/main/crates/uv-dirs/Cargo.toml:21`.
- https://raw.githubusercontent.com/sharkdp/bat/master/src/bin/bat/directories.rs (the `BatProjectDirs` wrapper, its "XDG … everywhere else" doc comment, and the closing `Lazy::new(|| BatProjectDirs::new().expect("Could not get home directory"))` static) and `…/master/Cargo.toml:29,67`.
- https://raw.githubusercontent.com/sharkdp/fd/master/Cargo.toml:43 · https://raw.githubusercontent.com/jj-vcs/jj/main/lib/Cargo.toml:36 and `…/main/cli/Cargo.toml:79` · https://raw.githubusercontent.com/nextest-rs/nextest/main/nextest-runner/Cargo.toml:37.

*Rust language reference*
- https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html — the edition-2024 newly-unsafe list is exactly `std::env::set_var`, `std::env::remove_var` and `std::os::unix::process::CommandExt::before_exec`, "because it can be unsound to call `std::env::set_var` or `std::env::remove_var` in a multithreaded program due to safety limitations of the way the process environment is handled on some platforms".
- https://doc.rust-lang.org/std/env/fn.home_dir.html — `pub fn home_dir() -> Option<PathBuf>`, stable since 1.0.0, no deprecation notice, with a documentation note pointing Unix callers at the XDG Base Directories specification.

**Method notes.** Endpoints queried: `https://crates.io/api/v1/crates/<name>`,
`…/<name>/versions`, `…/<name>/<version>/dependencies` and
`…/etcetera/reverse_dependencies` (all with a `User-Agent` header, via `curl -sS`);
GitHub REST through the authenticated `gh api` for `repos/<o>/<r>`,
`search/issues?q=repo:…+is:issue+is:open`, `repos/<o>/<r>/issues`,
`…/issues/<n>/comments`, `repos/<o>/<r>/commits`, `repos/<o>/<r>/contents/…` and
`repos/rustsec/advisory-db/contents/crates/<n>`; `https://rustsec.org/packages/<n>.html`
by HTTP status with `anyhow` as a live positive control; the Codeberg API at
`https://codeberg.org/api/v1/repos/<o>/<r>` and `…/issues`; `raw.githubusercontent.com`
for manifests and source; `docs.rs` and `specifications.freedesktop.org` by fetch.
The two pinned source repositories were read only through `git show <pin>:<path>`,
never from a working tree. The local toolchain version came from `rustc --version`.
No git command that modifies anything was run, and nothing outside this run
directory was written.

**What I could not verify, stated plainly.**
1. **Open-issue count for `directories` from the prescribed endpoint.** The figure
   table specifies `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`;
   for `soc/directories-rs` it returns **HTTP 422 Validation Failed** because the
   repository is archived. The 17/13 figures reported for the `dirs` family come
   from the Codeberg API instead and are labelled as such wherever they appear.
2. **CI platform evidence for `directories`, `dirs` and `xdg`.** Gate 4 is recorded
   for those three on their documented platform support, not on a workflow file I
   read. Only `etcetera`'s CI matrix was read directly.
3. **Whether `etcetera` 0.11.0's tagged `Cargo.toml` matches `master`.** The MSRV,
   licence and edition figures for 0.11.0 come from the crates.io `/versions`
   endpoint, which is authoritative for the published artefact; the workflow file,
   the trait source file and the `[target.'cfg(windows)']` dependency stanza were
   read from `master`, which is at unreleased 0.12.0. The trait shape and the
   `choose_base_strategy` → `Xdg`-on-macOS dispatch were independently confirmed
   against the docs.rs pages for 0.11.0, so the load-bearing claims are not
   master-only; the CI matrix's `1.95.0` toolchain row is master's and does not
   describe what 0.11.0 was tested against.
4. **Nothing in `### Validation strategy` was executed.** No Rust code exists in this
   repository to run it against; every check there is proposed.
5. **`bat`'s historical migration motive.** A web search surfaced
   `sharkdp/bat` PR #491 and issue #151 as leads about macOS directory placement; I
   did not read those threads, and no claim in this report rests on them. The `bat`
   evidence used is its current source file and manifest, read directly.
6. **No Rust project template was surveyed for an XDG directory pattern.** The LOW
   question is answered for *style guides* (the Rust CLI book, read directly) and
   left as a recorded evidence gap for *templates*; no `cargo-generate` template was
   fetched. R06's template survey is deliberately not reused, because it examined
   those repositories for an `unsafe` policy, not for directories.
7. **Issue responsiveness was collected only for `etcetera` and `directories`.**
   `xdg`, `dirs`, `home` and the three dormant crates have no responsiveness figure
   here; none of them is shortlisted for the recommendation, and `dirs`'s
   maintenance state rests on its 2026-09-05 release rather than on issue latency.
8. **The `directories` maintainer's linked rationale was not opened.** The reply on
   issue #117 points at `…/issues/47#issuecomment-2842344`; I quoted the reply and
   did not follow the link, so the *reasoning* behind the refusal is unread — only
   the refusal itself is evidenced.
9. **Advisory-free status for the excluded dormant crates.** `dirs-next`,
   `platform-dirs` and `app_dirs2` were not queried against RustSec; they are
   excluded on maintenance, so the gate was never reached.
10. **Intermediate JSON responses and fetched source files** were cached under the
   session scratchpad (`/private/tmp/claude-501/…/scratchpad/`), outside this
   repository. Nothing was written anywhere in the repository except
   `research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/raw/opus.md`.
