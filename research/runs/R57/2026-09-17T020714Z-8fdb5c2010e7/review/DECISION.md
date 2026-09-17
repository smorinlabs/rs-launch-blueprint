# 2026-09-17 — R57 — xdg-directory-set (pattern, Focused) — decision (revision 1)

## Decision

**`rs-launch-blueprint` resolves the full XDG-style directory set — config, data,
state and cache — as four accessors on one template-owned resolved-value type,
built on `etcetera` 0.11.0 through `choose_base_strategy()`, with every base
namespaced under the single segment `rslbp`. It exposes no runtime-directory
accessor and no free-function surface.**

This is not "py's four functions, ported". It is four *methods on one value* that
the composition root constructs once and hands down, which is a different design
from py's module-level free functions for a Rust-specific reason given under
`### Principles and implementation`.

**The four parts of that recommendation do not rest on the same strength of
evidence, and are stated separately so a reviewer can accept or reject them
separately.** Reading them as one undifferentiated "MUST" is the error this
decision is most at risk of.

| Part | Force | Ground |
|---|---|---|
| Per-user files are addressed by *kind*, at XDG locations, namespaced under the tool name, honouring `XDG_*` | **MUST**, org-locked | Org CLI Design Standard v1.4.14 `R5.3`, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, quoted verbatim in `## Empirical check` §1; provenance row 10 marks filesystem paths `org-locked` |
| A **state** directory exists now | **Required now**, by an already-accepted consumer | R67 is owner-accepted and its crash record's "location is not decided here and the default sink is a no-op until R57 answers" (`research/topics/67-error-and-exit-code-contract/DECISION.md:33`); `R5.3`'s own table files *logs and history* under State |
| A **config** directory exists | Required, but **not this item's to build** | `R5.1`/`R5.2`/`R5.3`; the config directory and its override mechanism are R54's and F247's, named out of scope by this item's prompt. This item supplies `config_dir()` as the single resolver so R54 does not resolve it a second time |
| **Data** and **cache** accessors ship now | **Recommended, not forced** | They are two `PathBuf::join` calls on a strategy the template already holds, so the marginal cost is zero; `R5.9` anticipates a documented cache location; and a root chosen *after* users have files elsewhere is a migration, which is the cost `uv` is visibly paying in `legacy_user_cache_dir()`/`legacy_user_state_dir()` |
| **Runtime** accessor is omitted | **Deliberate omission from a MUST table** | Nothing in the template opens a socket, FIFO or lock file; the XDG specification gives `XDG_RUNTIME_DIR` no fallback, and `etcetera` 0.11.0 returns `None` for it rather than inventing one (verified, `## Empirical check` §4 and §8); the crate's own trait documentation states it does not check the ownership, permission and persistence requirements the specification attaches to that directory |

The Runtime row is the honest test of the argument. `R5.3` tables five purposes,
and this decision ships four. So the MUST alone is not what makes the accessor
set unconditional — what `R5.3` fixes unconditionally is **where a file of a
given kind goes**, which is why F249's "contingent on whether R59 or R67 end up
needing a state/cache path" is wrong as a *rule* regardless of consumer timing.
Whether a given root is *resolved on day one* is then argued per row above:
State by an existing consumer, Config by R54's need, Data and Cache by cost, and
Runtime declined for want of any of the three. `R5.3`'s Runtime row becomes
satisfiable the day something needs it, by one method delegating to
`BaseStrategy::runtime_dir()`; the paths module should say so in a doc comment.

**Ledger rows settled.** `F249` (`docs/port/COMMONALITY.md:253`), origin
`py-only`, verdict `DIVERGENT` — unchanged. The verdict was already correct; the
decision supplies the Rust design that realizes the capability, and replaces the
row's contingency clause (see the `BASELINE-REVIEW:` line below). `F247`
(`:251`) is explicitly out of scope and is R54's to close; this decision only
records that the crate recommended here satisfies it rather than dropping it.

BASELINE-REVIEW: F249 — per-user files are addressed by kind, and the set of kinds a tool may use is fixed by the org CLI Design Standard rather than by what the template happens to write today — replace the row's contingency clause ("contingent on whether a file log sink (R59) or a crash log (see F302) end up needing a state/cache path") with a statement that `R5.3` is an org-locked MUST, so the *location rule* is unconditional and only which roots are resolved on day one remains a consumer question — evidence: org CLI Design Standard v1.4.14 blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, rule `R5.3` "(MUST)" with its five-row purpose table, and provenance row 10 marking filesystem paths `org-locked` (read 2026-09-16, `## Empirical check` §1); and the contingency has in any case already resolved affirmatively — R67 is owner-accepted with a crash record whose location it deferred to this item (`research/topics/67-error-and-exit-code-contract/DECISION.md:33`), while `R5.3` files logs under State.

Affected items: **R57** (this item — the accessor set); **R59** (`file-log-sink`,
F256–F261 — its default path stops being "possibly hardcoded/relative" and
becomes `state_dir().join("rslbp.log")`); **R67** (F302 — its default crash sink
stops being a no-op); **R54** (`config-discovery-tiers` — its user tier consumes
this item's `config_dir()` rather than resolving a second time). No second
`BASELINE-REVIEW:` line is raised.

**Status of this decision.** It is a **proposal validated in the implementation
phase** (owner ruling, 2026-09-10). It records what the research found and what
it recommends; P03 builds the template and its CI proves the recommendation.
`## Engines` lists what P03 must validate. A decision that does not survive
implementation is revised against this recorded research, not researched again
from scratch.

### Principles and implementation

**Shared requirement.** A user must be able to find, relocate, back up and delete
this tool's per-user files *by their kind*, through one mechanism that is the same
across the three template languages: configuration the user edits, data the user
would hate to lose, state the tool can regenerate but the user may want to read
(logs, history), and cache the user may delete at any moment without loss.

**Source and agreement level.** Two sources bind, at different levels, and they
disagree; the standard is the higher authority.

| # | Source | Agreement level | What it fixes |
|---|---|---|---|
| S1 | Org CLI Design Standard v1.4.14 `R5.3`, provenance row 10 | **standard**, marked `org-locked` | The location rule: XDG bases, namespaced under the tool name, honouring `XDG_*` overrides. Not discretionary for any of the three repositories |
| S2 | Ledger row F249, origin `py-only`, verdict `DIVERGENT` | contingent capability, as recorded | Whether Rust adopts data/state/cache at all — the clause this decision replaces |
| S3 | XDG Base Directory Specification v0.8 (08 May 2021), incorporated by reference by `R5.3` | standard | The base directories, their defaults, and the rule that a non-absolute value in an `XDG_*` variable is invalid and ignored |

**What must agree across py, ts and rs.**

- The four kinds exist as a named concept, and every file the tool writes is
  assigned to exactly one of them (`R5.3`; py's `paths.py` module docstring at
  pin `b08bccfb` divides them the same way).
- `XDG_*` variables are honoured on every POSIX platform **including macOS**, and
  ignored when empty or relative.
- One namespace segment, the *binary* name — py `APP_NAME = "plbp"`, ts
  `TOOL_DIR_NAME = 'ts-projects'`, rs `rslbp` (the `[[bin]]` name fixed by R49's
  `build-tool-output-shape`), never the package name `rs-launch-blueprint`.
- Resolve once; nothing else in the workspace reads a raw `XDG_*` variable.

**What may vary by ecosystem.**

- **The accessor surface** — free functions versus a resolved value. Rust has a
  constraint here that Python and TypeScript do not; see below.
- **Windows defaults.** py uses platform-native `%APPDATA%`/`%LOCALAPPDATA%`; ts
  uses `~/.config` everywhere and cites `R5.3` for it. `R5.3` permits both
  ("Native non-Linux equivalents are permitted deviations … but XDG paths are the
  canonical reference"). Windows is outside `target-os-matrix`, so **this item
  does not adjudicate Windows behaviour**; the Rust template inherits whatever
  `etcetera`'s `Windows` strategy does, untested.
- **Which roots are resolved on day one** — a consequence of what the template
  ships, argued row by row in the table under `## Decision`.

**Architectural alternatives, compared before any library.**

| Alternative | What it is | Verdict |
|---|---|---|
| **A. Hand-rolled over `std`** (py's shape ported literally) | Read `XDG_*` with `std::env::var_os`, validate `is_absolute()`, fall back to `std::env::home_dir().join(".local/state")`. Zero dependencies | **Rejected.** It is roughly 150 lines of platform logic the template must own, test and keep in sync with a specification it does not control, to reproduce a crate that is one dependency. The one thing it buys — an injectable environment — is obtainable under alternative C for free, because `etcetera`'s `BaseStrategy` is an ordinary unsealed public trait (verified, `## Empirical check` §4). Keep as the fallback if `etcetera` becomes unmaintained |
| **B. Let a config framework own the paths** (`confy`, `figment`, `config`) | The config crate discovers and reads the file; the template never names a directory | **Rejected on scope and on capability.** It answers only the *config* question, which is R54's and out of scope here, and gives no data/state/cache accessor at all, so `R5.3`'s other rows would be unimplementable. `confy` 2.0.0 itself depends on `etcetera`, so this is alternative C with a layer of indirection and less control |
| **C. A base-directory crate wrapped in one template-owned type** | A crate resolves the bases for the running platform; the template owns a small `Paths` value that appends the `rslbp` segment and hands out `&Path`s | **Selected.** It is what the well-regarded adopters do — `bat`'s wrapper is even named for it (`BatProjectDirs`, "Wrapper for 'etcetera'…"), `uv` has a whole `uv-dirs` crate — and py's `paths.py` is the same shape in Python. It preserves "resolve once" structurally and keeps the namespacing, the one piece that is genuinely this template's policy, in this template's source |

**Within alternative C, the library is chosen by one capability fact on a
required CI target, not by download count.** `macos-latest` is in
`target-os-matrix`, and read at each crate's own published source rather than at
a rendered documentation page:

- `directories` 6.0.0 assigns `state_dir: None` on the macOS path, at both of its
  construction sites, and resolves `config_dir` to
  `home_dir.join("Library/Application Support")` while reading no `XDG_`
  variable anywhere in that file (`src/mac.rs`, verified at tarball sha256
  `16f5094c…`, `## Empirical check` §5). On `macos-latest` it would therefore give
  the crash record **no location at all** and would drop the `XDG_CONFIG_HOME`
  behaviour F247 records as inherited — the trap `docs/port/BASELINE-REVIEW.md:113`
  already noted.
- `etcetera` 0.11.0's `choose_base_strategy()` selects the `Xdg` strategy on
  macOS and iOS (`create_strategies!(Apple, Xdg)`, verified at tarball sha256
  `de48cc4d…`), and its `Xdg` strategy ignores any override that is not absolute
  (`if path.is_absolute() { Some(path) } else { None }`) — verbatim the
  freedesktop rule, and verbatim py's own `is_absolute()` check, which ts does not
  implement.

That capability absence outranks `directories`' deeper adoption under the survey
method's gate-before-popularity rule. It is also **permanent by the maintainer's
own position**, not a backlog item: on `directories-rs` issue #117 (2026-06-16)
`soc` answers a request to support `XDG_*` on macOS with *"this is not going to be
supported"* — carried from `raw/opus.md` at its retrieval date 2026-09-17 and
**not independently re-fetched here** (see `## Engines`, unproven row U4).

**The accessor surface is a struct, and one edition-2024 fact decides it.**
Edition 2024 makes `std::env::set_var` and `std::env::remove_var` `unsafe`, and
R06 is resolved with `unsafe_code = "forbid"` in `[workspace.lints.rust]`,
inherited by every member (`research/topics/06-unsafe-code-policy/DECISION.md`,
verified at `## Empirical check` §2). A `forbid` cannot be lifted by a per-site
`#[allow]` or `#[expect]`, and it covers `#[cfg(test)]` modules and `tests/`
targets. **Free functions that read the process environment internally — py's
exact shape, and `etcetera`'s own `choose_base_strategy()` — therefore cannot be
unit-tested hermetically in this template at all.** A value constructed from an
*injected* strategy can. Python monkeypatches `os.environ`; TypeScript injects
`env` and `homedir` as parameters (`configDir(env, homedir)`); Rust must do the
TypeScript thing. The principle — resolve once, and the resolution is testable —
is preserved in all three; the mechanism differs because the language does.

The injection point costs nothing, because `BaseStrategy` is an ordinary public
trait with six methods and no sealing, verified in the published 0.11.0 source:

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

**Minimal realistic example.** Illustrative only — P03 writes the real thing, and
the crate/module placement is R02's.

```rust
// library crate, src/paths.rs — computes, never writes.
use std::path::{Path, PathBuf};
use etcetera::base_strategy::BaseStrategy;

/// The single namespace segment under every base. Equals the `[[bin]]` name
/// fixed by R49's `build-tool-output-shape`, not the package name.
pub const TOOL_NAME: &str = "rslbp";

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct Paths { config: PathBuf, data: PathBuf, state: PathBuf, cache: PathBuf }

impl Paths {
    /// Resolve once from any strategy. Pure: touches no filesystem.
    pub fn from_strategy(s: &impl BaseStrategy) -> Self {
        // `state_dir()` is `None` on the Windows and Apple strategies; collapsing
        // it onto the data dir keeps this accessor total on every platform and
        // reproduces py's documented Windows shape. It is unreachable under
        // `choose_base_strategy()` on ubuntu-latest and macos-latest, both of
        // which select `Xdg`, whose `state_dir()` is always `Some`.
        let data = s.data_dir().join(TOOL_NAME);
        Self {
            config: s.config_dir().join(TOOL_NAME),
            state:  s.state_dir().map(|p| p.join(TOOL_NAME)).unwrap_or_else(|| data.clone()),
            cache:  s.cache_dir().join(TOOL_NAME),
            data,
        }
    }

    /// Production entry point. Fallible: a home directory may be unresolvable.
    pub fn from_process_env() -> Result<Self, etcetera::HomeDirError> {
        Ok(Self::from_strategy(&etcetera::base_strategy::choose_base_strategy()?))
    }

    pub fn config_dir(&self) -> &Path { &self.config }
    pub fn data_dir(&self)   -> &Path { &self.data }
    pub fn state_dir(&self)  -> &Path { &self.state }
    pub fn cache_dir(&self)  -> &Path { &self.cache }
}
```

Consumers then read, and nothing else in the workspace touches an `XDG_*`
variable: R59's file sink defaults to `paths.state_dir().join("rslbp.log")`,
R67's crash record to `paths.state_dir().join("rslbp_crash.jsonl")`, R54's user
config tier to `paths.config_dir().join("rslbp_config.toml")` — the last being
`R5.2`'s canonical `<tool>_config.toml` filename. The `<app>_<kind>.<ext>`
filename shape is py's. Directory *creation* stays at each write site in the
binary crates, so the library crate keeps R67's layering promise that it "must
write to no process stream or file".

**Per target shape.** *CLI (`rslbp`)*: all four accessors, resolved once at the
composition root — this is where `R5.3` binds and where the consumers are.
*Library*: the `Paths` type lives here and only the type, because both binaries
need it, R01's composition root wants the value constructed at the root rather
than reached for from a static, and an embedding consumer needs to be able to
*supply* paths, which `from_strategy(&impl BaseStrategy)` gives it. *Web (the
`web` feature, R69)*: the service must **not** construct `Paths` in a shared
startup path. A container image (R51) can run as a numeric UID with no home
entry, and a service that resolved paths eagerly would fail to boot for a reason
unrelated to its configuration; the web surface's settings come from environment
variables (R77) and its logs go to stdout/stderr (R58's web profile). That is a
justified per-shape difference: the principle is about per-user files, and a
service has no user.

**Essential behaviours and observable acceptance criteria.** These are P03's to
prove in the real template; three of them are *already observed* here against the
pinned crate on the macOS leg (`## Empirical check` §8), and one is **corrected**
against what Opus proposed.

| # | Behaviour | Observable acceptance criterion | Status here |
|---|---|---|---|
| B1 | Four kinds resolve as distinct roots | the paths command emits four distinct absolute paths, each ending in the segment `rslbp` | proposed |
| B2 | An absolute `XDG_*` override is honoured on **both** runners | with `XDG_STATE_HOME=$TMP/s`, the state path is `$TMP/s/rslbp` | **observed on macOS** for the crate's half |
| B3 | An empty or relative `XDG_*` value is ignored | with `XDG_STATE_HOME=""` and with `XDG_STATE_HOME=rel/ative`, the state path falls back to `$HOME/.local/state/rslbp` | **observed on macOS** for the crate's half |
| B4 | The namespace segment is the binary name, once | paths are exactly `<base>/rslbp`, never `<base>/rs-launch-blueprint`, never `<base>/rslbp/config` | proposed |
| B5 | Resolution is pure: it creates no directory | after the command runs with a fresh `$HOME`, `$HOME/.local` does not exist | proposed |
| B6 | An unresolvable home directory is a typed failure, never a panic | **corrected — see below** | proposed, with the test construction changed |
| B7 | The library crate keeps R67's layering | `cargo tree -p <lib> -i anyhow` is empty, and the paths module contains no `std::fs` write and no `std::io` stream access | proposed |

**B6, corrected.** Opus specified this criterion as "with `HOME` unset and no
`XDG_*` set, a command that needs a path exits `1` with an `RSLB101` envelope".
**That test would pass vacuously.** `etcetera::home_dir()` is a thin wrapper over
`std::env::home_dir()`, which on Unix falls back to the `passwd` entry when `HOME`
is unset — so `env -i <binary>` on macOS resolves ordinary paths and returns no
error at all (observed, `## Empirical check` §8 case 5). The `Result` return type
is still right, because the `Err` arm is reachable where neither `HOME` nor a
`passwd` entry resolves — a container running a numeric UID absent from
`/etc/passwd`, which is exactly the R51 case that motivates the web-surface
caution above. But P03 must construct that state deliberately rather than by
unsetting `HOME`, or cover the error arm at the caller of `from_strategy` instead
of end to end. The *mapping* of that failure needs no new error code, but be
precise about whose mapping it is. R67 **defines** `RSLB101` as I/O → exit 1, and
does so in exactly one place: inside its owned parameter value at
`research/topics/67-error-and-exit-code-contract/DECISION.md:383`, the file's only
occurrence of that identifier (verified by count, `## Empirical check` §2). R67
does **not** say that an unresolvable path is an `RSLB101`; routing it there is
**this decision's proposal for P03**, and routing a user-tier config file that
cannot be located to `RSLB104` (config layer unreadable → exit 1, defined at
`:587`) is **R54's** to make, not this item's. Both candidates land on exit `1`,
so the observable contract is the same either way, no new catalogue row is needed,
and **no `CONFLICT:` line is raised against R67** — whose `ErrorCode` enum is
`#[non_exhaustive]` and append-only, so a dedicated row for environment
resolution would be R67's ordinary extension path rather than a conflict. For the crash
record itself, R67's AC7 already settles it: a crash-record write failure leaves
the exit code and the envelope unchanged, so an unresolvable state directory
leaves the sink silent.

A second, smaller correction for P03: `etcetera`'s defaults carry a trailing
separator — `config_dir()` returns `<home>/.config/`, not `<home>/.config`
(observed, §8). `join(TOOL_NAME)` normalizes it, but a naive string comparison
against `$HOME/.config` in a test will fail.

**Maintained reference implementations**, all cited from `raw/opus.md` at its
retrieval date 2026-09-17 and **not independently re-fetched here**: `bat`
(`src/bin/bat/directories.rs` — the wrapper-struct shape, though its closing
`Lazy::new(|| …expect("Could not get home directory"))` static turns a missing
home into a panic, which under R67 would surface as exit `101`; copy the wrapper,
not the static); `uv` (`crates/uv-dirs/src/lib.rs` — `choose_base_strategy()`,
`choose_native_strategy()` kept only for legacy migration, an explicit
`parse_xdg_path` absoluteness check); `jj` (the same crate depended on from both a
library and a CLI crate in one workspace, this template's exact topology).

**Maintenance state.** `etcetera` — `active`: 0.11.0 released 2025-10-28, which
under the rubric is a trigger to investigate, never a verdict; investigation finds
the repository not archived, pushed 2026-08-04, 2 open issues, a median first
maintainer response of 3.18 days over the prescribed 10 most recently opened
issues (1.82 days over the 7 answered, 3 unanswered) — a small-project profile
with no concrete `at-risk` signal. `directories` — `stable-quiet`: the GitHub
repository is archived but that is a relocation to Codeberg, not a maintainer
notice about the crate, and its sibling `dirs` shipped 7.0.0 on 2026-09-05. Both
figures are carried from `raw/opus.md` (retrieved 2026-09-17) and were not
re-collected here; the maintenance verdict does not discriminate between the two
candidates, because the macOS gap decides it either way.

**Fitness gates.**

| Gate | `etcetera` 0.11.0 | `directories` 6.0.0 | `xdg` 3.0.0 |
|---|---|---|---|
| 1. Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. Recorded for information only, never as a filter: `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. For information: `MIT OR Apache-2.0` | `inapplicable — owner ruling 2026-09-12 (Q7.B)`. For information: `Apache-2.0 OR MIT` |
| 2. MSRV within `stable minus 2 minor versions…` | **Pass**, verified in the published manifest: `rust-version = "1.87.0"`, against a floor of 1.96 from local stable 1.98.0. Tree on Linux/macOS is one crate, `cfg-if ^1` | **Unverifiable**, verified as such: the published manifest declares **no** `rust-version`, so the policy's "declared as `rust-version` in Cargo.toml" property does not hold for the dependency. Not scored a failure — the policy binds the template's own crates — but recorded | **Pass**, `rust_version` 1.60.0; carried from the raws, not re-verified here |
| 3. No open RustSec advisory; `unsafe` posture | **Pass, zero open.** `https://rustsec.org/packages/etcetera.html` → **404**, paired against the live control `anyhow` → **200**, so the 404 is absence and not a broken endpoint (executed, §7). `unsafe` posture: no FFI on Unix; the only platform FFI is `windows-sys` under `cfg(windows)` | **Pass, zero open.** The page returns 200 but carries only `RUSTSEC-2020-0054`, `informational = "unmaintained"`, **`withdrawn = "2021-04-19"`** (advisory read in full, §7); same for `dirs`/`RUSTSEC-2020-0053`. A withdrawn informational advisory is not an open advisory. FFI via `dirs-sys` → `libc`/`windows-sys` | **Pass, zero open**: 404 against the same control |
| 4. Builds and is tested on `ubuntu-latest, macos-latest` | **Pass, primary evidence read at the published version itself**: 0.11.0's own shipped `.github/workflows/ci.yaml` is `os: [macos-latest, ubuntu-latest, windows-latest]` × `toolchain: [beta, stable, 1.87.0]` (§4) | **Pass by stated platform support**; its CI was not read — recorded as unverified | **Unsettled between the engines.** Codex reports its published CI names Ubuntu only and fails it on that; Opus passes it on stated platform support without reading the workflow. Neither was re-checked here; immaterial, since `xdg` is not recommended |
| 5. Default features / async coupling | **Pass**, verified: 0.11.0 declares **no** `[features]` table at all; no async runtime, no executor; purely synchronous `PathBuf` arithmetic | **Pass.** No async coupling | **Pass.** One optional `serde` feature, off by default |
| 6. Binary-size and compile-time cost (qualitative) | **Negligible.** One crate plus `cfg-if`, a macro-only crate with no codegen; no build script, no proc-macro, no generics to monomorphise. `windows-sys` is declared under `[target."cfg(windows)".dependencies]` (verified, §4), so the Windows capability is never fetched, compiled or linked on either CI leg — it is literally free on this matrix | **Small but strictly larger**: adds `dirs-sys` and its tree; no build script | **Smallest**: zero mandatory dependencies with `serde` off |

**Excluded.** `directories` 6.0.0 / `dirs` 7.0.0 — not by a numbered gate, but on
the macOS capability absence above, which is a maintainer-stated permanent design
position. `xdg` 3.0.0 — not recommended: it implements the XDG specification and
nothing else, so a later fork that wanted Windows would have to replace the crate
rather than change a strategy; `etcetera` costs the same and keeps that door open.
`dirs-next` 2.0.0 (last release 2020-10-22), `platform-dirs` 0.3.0 (2020-09-26)
and `app_dirs2` 2.5.5 (2023-02-15) — `dormant`/`at-risk`, and all three are
*older* than the incumbents, not newer; there is no credible up-and-comer in this
category, which is itself the finding. `home` 0.5.12 resolves only a home
directory and carries no XDG semantics.

**Ranked runner-up: `directories` 6.0.0 / `dirs` 7.0.0.** It wins only if the
owner decides that **macOS should use Apple-native locations** —
`~/Library/Application Support/<tool>`, `~/Library/Caches/<tool>` — rather than
XDG ones. `R5.3` explicitly permits that deviation. Two consequences the owner
would have to accept: the Rust template would diverge from **both** py and ts on
macOS, which currently agree on `~/.config`; and there would still be **no state
directory on macOS**, so the crash log and file sink would need a separately
chosen home there. Because of that second consequence, even under the
Apple-native branch the better construction is `etcetera`'s
`choose_native_strategy()`, which returns the `Apple` strategy on macOS. So the
runner-up's winning condition is narrow: it wins only if the owner *also* wants
`directories`' extra accessors (`preference_dir`, the user-directories family),
which nothing in this template currently asks for. A distant third, `xdg` 3.0.0,
wins only if the template will never support Windows in any form.

**Tradeoffs.** Against `directories`: no `preference_dir`, no
`config_local_dir`/`data_local_dir` split, no user-directories family — accepted,
because `R5.3` asks for five purposes and nothing here wants the user's Downloads
folder; and roughly 2.4× less raw adoption — accepted under the explicit
gate-before-popularity rule, since a download count does not create a macOS state
directory. Against a hand-rolled `std` implementation: zero dependencies and total
control of the fallback table — accepted, and the second is a gain rather than a
loss, since the crate's fallbacks were verified here to be the specification's,
absoluteness rule included. The one real ergonomic cost: `Xdg::new()` is the sole
constructor and takes no injected environment (verified, §4), so the env-reading
path itself must be covered by a child-process integration test rather than a unit
test — which is precisely why the surface is a struct. Against ts's config-only
shape: three accessors and a crate the template could have deferred — accepted,
because `R5.3` fixes the rule and R67 removes the "for now"; and a slightly larger
public API surface for R04 to keep stable — four functions returning `&Path`, with
the caveat that `from_strategy(&impl BaseStrategy)` puts an `etcetera` type in the
public signature. If R04's enforcement objects, the escape is to take the four
`PathBuf`s directly and keep the `BaseStrategy` bridge private. Flagged for P03,
not decided here.

re-verify: on any of — R59 or R67 choosing a crash-log or file-sink location other than `state_dir()`; R54 selecting a config mechanism that resolves the config directory independently of this item's `config_dir()`; `etcetera` 0.12.0 releasing (it raises `rust-version` from 1.87.0 to 1.95.0 on `master`, cutting the headroom against the policy floor from 9 minors to 1); Rust stable advancing so that the `msrv-policy` floor exceeds `etcetera`'s declared `rust-version`; a RustSec advisory opening against `etcetera` or `cfg-if` (`https://rustsec.org/packages/etcetera.html` returned 404 on 2026-09-16); the org CLI Design Standard revising `R5.3` or its `org-locked` status, in which case re-read the blob rather than a cached quotation; `target-os-matrix` gaining `windows-latest`, which makes the untested Windows state/data collapse a tested path; or 2027-03-17, whichever comes first

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

**No owned parameter, and no consumed parameter.** This item's prompt declares
`- owns:` and `- consumes:` both empty (`inputs/prompt.md`, verified at
`## Empirical check` §3), so it registers no entry in `docs/port/PARAMETERS.md`
and carries exactly the four fixed rows above. The four `- assumes` values are
byte-identical to `docs/port/PARAMETERS.md` rows 7–10, which are themselves
byte-identical to the run's `inputs/PARAMETERS.md` (verified, §3). No `CONFLICT:`
line is raised.

How each bears on the decision: `rust-edition` is load-bearing and is the reason
the accessor surface is a struct rather than py's free functions, because edition
2024 makes `std::env::set_var` and `std::env::remove_var` `unsafe` and R06
forbids `unsafe`. `target-os-matrix` is load-bearing and is the entire reason
`directories` loses: `macos-latest` is a required leg, and `directories` has no
state directory there. `msrv-policy` evaluates to a floor of 1.96 against the
local stable 1.98.0 recorded in `review/evidence/toolchain.txt`, which
`etcetera` 0.11.0's declared `rust-version = "1.87.0"` clears by 9 minor
versions. `license` is recorded and **not** evaluated as a gate, under the owner
ruling of 2026-09-12 (Q7.B) that there is no licence check for anything the
template uses; nothing is excluded on licence here.

This item is *substantively* downstream of two published decisions that are not
parameters it consumes: R67 (`research/topics/67-error-and-exit-code-contract/DECISION.md`,
sha256 `16947ab16f8a7bbfe8f911f7d3450b94ec1b4c0e2e6ca79175e1b0b90e649497`, which
matches the hash recorded in `inputs/prerequisites.json` — verified, §2) supplies
the crash-record consumer, and the error codes this decision proposes routing an
unresolvable path onto — `RSLB101` and `RSLB104`, which R67 and R54 respectively
own, on the gradation stated under `### Principles and implementation`; R49's
`build-tool-output-shape` supplies the binary name `rslbp` that is the namespace
segment. Neither appears above, because neither is on this prompt's `- consumes:`
line and the packaging validator derives the expected `- assumes` set from the
fixed registry rows plus that line.

One registry observation, offered and not acted on: R67's own `## Parameters`
section records a Perplexity `CONFLICT:` line aimed at a parameter named
`R57 state-directory` that does not exist. If the owner wants this dependency
machine-checkable rather than prose-linked, the parameter to create would be
`xdg-directory-set`, owned by R57. Creating it is not this item's to do, and it
would change the byte-exact `- assumes` set that the validator enforces above.

## Empirical check

**Toolchain and platform.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, `Darwin arm64` — written by the
script to `review/evidence/toolchain.txt` and deliberately kept **out** of the
diffed log, so that the log carries no machine-dependent text.

**Working directory.** `research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/evidence`
(the script resolves every repository path from its own location, so it also runs
unchanged from any other directory and from a clean extraction).

**Command, and its observed status.**

```
$ bash r57-claims.sh > r57-claims.log 2>&1
$ echo $?
0
$ /usr/bin/grep -c '^PASS' r57-claims.log
53
$ /usr/bin/grep -c '^FAIL' r57-claims.log
0
$ /usr/bin/grep -c '^SKIP' r57-claims.log
0
```

53 assertions pass, none fail, nothing skipped; the script's last line is
`failed assertions: 0` and it exits non-zero if any assertion fails. Counts above
were produced with the binary at `/usr/bin/grep` and from the whole file, never
from output piped through `head` or `cut`.

**Reproducibility, checked rather than asserted.** Immediately before writing this
sentence the script was re-run and its output diffed against the log this decision
cites:

```
$ bash r57-claims.sh > /tmp/rerun2.txt 2>&1 && diff /tmp/rerun2.txt r57-claims.log && echo REPRODUCIBLE-BYTE-FOR-BYTE
REPRODUCIBLE-BYTE-FOR-BYTE
```

and, from a clean extraction with no `.git` directory anywhere, carrying only the
files this commit stages (so without the two gitignored `.crate` tarballs, which
the script therefore re-downloaded and sha256-checked):

```
$ git archive HEAD | tar -x -C <tmp>       # then only the staged review/ files copied in
$ bash <tmp>/research/runs/R57/.../review/evidence/r57-claims.sh > /tmp/arch2.txt 2>&1
$ echo $?; diff /tmp/arch2.txt r57-claims.log && echo ARCHIVE-WITHOUT-TARBALLS-IDENTICAL
0
ARCHIVE-WITHOUT-TARBALLS-IDENTICAL
```

The log is reproducible byte-for-byte, with **nothing varying**. That holds
because every drifting source is pinned or snapshotted: crate sources are the
immutable published `.crate` tarballs asserted against their sha256; the org
standard is read at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, never a
branch tip; HTTP JSON, HTTP status codes and the spike's output are snapshotted
once into `review/evidence/snap/` and read from the snapshot afterwards (delete
`snap/` to re-fetch and re-execute); and the toolchain lines go to a separate
file. Three sections would print `SKIP <name>` with a reason rather than fail if
what they need is absent — the `cli-standards` repository, the network, a Rust
toolchain — and none of them skipped on this run.

**Files.** `review/evidence/r57-claims.sh` (the script, `shellcheck`-clean),
`review/evidence/r57-claims.log` (its complete output, sha256
`fbbe9fae82267a67d220b71536095e82edc38776ed845bc4017b478252332143`),
`review/evidence/toolchain.txt`, and `review/evidence/snap/`. `snap/` holds 12
artifacts; **10 are committed and 2 are not** — the `.crate` tarballs match this
repository's `.gitignore:12` rule `research/runs/**/*.crate`, which is respected
rather than overridden. Their absence costs nothing, because the script re-fetches
each one and refuses to read it unless its sha256 equals the constant in the
script. That was checked rather than assumed: extracting `git archive HEAD` into a
clean directory, copying in only the files this commit stages, and running the
script there re-downloaded both tarballs and produced output identical to the
committed log.

**What it checks, section by section, and what was observed.**

*§1 — the org CLI Design Standard at the pinned blob.* Read with
`git -C /Users/stevemorin/c/cli-standards cat-file -p f9de0437baece3383e73ca2c5f48b7ab399b51c7`.
A blob sha is not a commit, so `git show <blob>:<path>` fails on it with
*"path 'cli-design-standard.md' exists on disk, but not in 'f9de0437…'"*; the
script uses `cat-file -p`. `R5.3` prints verbatim, including its heading
`**R5.3 — Filesystem locations (XDG). (MUST)**`, the rule sentence *"Per-user
paths **MUST** follow the XDG Base Directory Specification, namespaced under the
tool name, honoring `XDG_*` overrides and falling back to the defaults below"*,
its five-row purpose table with the **State (logs, history)** row at
`$XDG_STATE_HOME/acme/` and the **Runtime (sockets)** row at
`$XDG_RUNTIME_DIR/acme/`, the permitted-deviation sentence for native non-Linux
equivalents, and the counter-example *"❌ writing config to `~/.acme/`"*.
Provenance row 10 prints verbatim as
`| 10 | Filesystem paths | XDG Base Directory Specification | Modern standard; predictable | org-locked |`.
The document states `| **Version** | 1.4.14 |`. Appendix E's Rust sentence prints:
*"Pair with `figment`/`config` crates for the precedence chain and
`directories`/`etcetera` for XDG paths."* — so the standard's normative rule
selects between the two candidates its own advisory appendix offers. `R5.9` and
`R10.1` print as quoted above. 7 passing checks in this section.

*§2 — prerequisite decisions and ledger rows, read in this repository.*
`research/topics/67-error-and-exit-code-contract/DECISION.md:33` prints the
ledger-style row

```
| Crash record | `std::fs` behind an injected sink; **location deferred to R57** | CLI binary only |
```

`:126` prints AC7; `:587` prints the `RSLB104` row and its basis. `RSLB101` is
then counted rather than quoted, because the count is the finding: it occurs
**once** in the whole of R67, on line 383, inside the owned parameter value, as
the clause `` `RSLB101` I/O → 1 `` — which is why the B6 correction above is
careful to call the unresolvable-path mapping this decision's proposal rather than
R67's text. `docs/port/COMMONALITY.md:253`
prints the F249 row still carrying the contingency clause this decision replaces,
and `:251` prints F247. `research/topics/06-unsafe-code-policy/DECISION.md:24`
prints `unsafe_code = "forbid"`. The R67 decision hash on disk
(`16947ab1…`) is asserted equal to the hash recorded in
`inputs/prerequisites.json`; it matches, so the prerequisite is not stale.
9 passing checks in this section.

*§3 — parameters and couplings.* `diff` of `inputs/PARAMETERS.md` rows 7–10
against `docs/port/PARAMETERS.md` rows 7–10 is empty; the prompt's `- owns:` and
`- consumes:` lines print, both bare — asserted as **whole-line** matches, so
`- owns: something` would fail the check rather than satisfy it. 3 passing checks
in this section.

*§4 — `etcetera` 0.11.0, at the published artifact.* Tarball
`https://static.crates.io/crates/etcetera/etcetera-0.11.0.crate`, sha256 asserted
equal to `de48cc4d1c1d97a20fd819def54b890cadde72ed3ad0c614822a0a433361be96`; the
script refuses to read it on a mismatch. Observed in the manifest:
`edition = "2024"`, `rust-version = "1.87.0"`, `license = "MIT OR Apache-2.0"`,
`[dependencies.cfg-if] version = "1"` as the only unconditional dependency,
`[target."cfg(windows)".dependencies.windows-sys]` for the Windows FFI, and **no**
`[features]` table. Observed in `src/base_strategy.rs`: the six-method
`pub trait BaseStrategy` with `fn state_dir(&self) -> Option<PathBuf>;`, no
sealing; the dispatch
`} else if #[cfg(any(target_os = "macos", target_os = "ios"))] { create_strategies!(Apple, Xdg); }`,
with the macro's own doc comment *"This uses the `Windows` strategy on Windows,
and `Xdg` everywhere else. This is the convention used by most CLI
applications."*; and the `runtime_dir` doc note that the library *"does not check
these requirements"*. Observed in `src/base_strategy/xdg.rs`: `pub fn new() ->
Result<Self, HomeDirError>` as the sole constructor, the absoluteness check
`if path.is_absolute() { Some(path) } else { None }`, the four fallbacks
`.config/`, `.local/share/`, `.cache/`, `.local/state/`, and
`Self::env_var_or_none("XDG_RUNTIME_DIR")` — no runtime fallback. Observed in
`src/lib.rs`: `std::env::home_dir().ok_or(HomeDirError)`, which is what B6's
correction rests on. Observed in the workflow **shipped inside 0.11.0 itself**:
`os: [macos-latest, ubuntu-latest, windows-latest]` × `toolchain: [beta, stable, 1.87.0]`,
so gate 4 has primary evidence at the published version rather than at `master`.
18 passing checks in this section, the tarball sha256 included.

*§5 — `directories` 6.0.0, at the published artifact.* Tarball sha256 asserted
equal to `16f5094c54661b38d03bd7e50df373292118db60b585c08a411c6d840017fe7d`.
Observed in `src/mac.rs`: `state_dir:        None` at both construction sites;
`let config_dir       = home_dir.join("Library/Application Support");`; and zero
occurrences of the string `XDG_` anywhere in the file. Observed in its manifest:
**no** `rust-version` key, and `[dependencies.dirs-sys]`. 6 passing checks in this
section, the tarball sha256 included.

*§6 — crates.io figures.* `GET https://crates.io/api/v1/crates/etcetera`
(retrieved 2026-09-16) → `crate.recent_downloads` = **32,829,812**,
`crate.downloads` = **108,370,911**, `crate.max_stable_version` = **0.11.0**.
`GET https://crates.io/api/v1/crates/etcetera/versions`, newest with
`yanked: false` → `num` **0.11.0**, `created_at` **2025-10-28T13:28:11.765603Z**,
`rust_version` **1.87.0**, `license` **MIT OR Apache-2.0**.
`GET https://crates.io/api/v1/crates/etcetera/0.11.0/dependencies` prints the
dependency rows with their `kind`, `optional` and `target` fields.

*§7 — RustSec, with a live positive control.*
`https://rustsec.org/packages/etcetera.html` → **404**;
`https://rustsec.org/packages/directories.html` → **200**;
`https://rustsec.org/packages/anyhow.html` → **200** as the control, a crate known
to carry an advisory. The control settles what Codex could only call provisional:
the 404 is evidence of absence, not a broken endpoint. The two advisories the
`directories` family's 200 pages carry were read in full through
`gh api repos/rustsec/advisory-db/contents/crates/<name>/<id>.md`: both
`RUSTSEC-2020-0054` (`directories`) and `RUSTSEC-2020-0053` (`dirs`) are
`informational = "unmaintained"` with `withdrawn = "2021-04-19"` and
`patched = []`. A withdrawn informational advisory is not an open advisory, so
every candidate passes gate 3. 4 passing checks in this section. The `gh` invocation is authenticated
through the ambient CLI session; no token or environment is printed anywhere in
the script or the log.

*§8 — a throwaway macOS spike, run rather than reasoned about.* This is the one
place something was compiled, and it is permitted: it builds **nothing this
decision recommends** — no `Paths` type, no accessor, no template module, no
acceptance harness. It is a 14-line `main.rs` in a throwaway package **outside
this repository**, depending on the sha256-pinned `etcetera` 0.11.0 source
extracted in §4 by path (so no registry resolution is involved), which prints what
`choose_base_strategy()` resolves. It exists because `macos-latest` is where the
two engines disagree, and because a claim about macOS read from a documentation
page is weaker than the same claim observed on macOS. Run under `env -i` with a
fixed fake `HOME=/fixed/fake`, so its output carries no machine-dependent text.
Observed, in full in the log:

```
case 1 — HOME=/fixed/fake, no XDG_* set
config = /fixed/fake/.config/
data   = /fixed/fake/.local/share/
state  = Some("/fixed/fake/.local/state/")
cache  = /fixed/fake/.cache/
runtime= None

case 2 — HOME=/fixed/fake, XDG_STATE_HOME=/abs/state (absolute)
state  = Some("/abs/state")

case 3 — HOME=/fixed/fake, XDG_STATE_HOME= (empty)
state  = Some("/fixed/fake/.local/state/")

case 4 — HOME=/fixed/fake, XDG_STATE_HOME=rel/ative (relative)
state  = Some("/fixed/fake/.local/state/")

case 5 — no HOME and no XDG_* at all
config = <passwd-home>/.config/            [the real home is redacted; the shape is the point]
```

That is four findings, on the disputed platform, with a toolchain named above:
macOS **does** resolve a state directory under `choose_base_strategy()`, so
`directories`' `None` is a crate defect and not a platform limit; an absolute
`XDG_STATE_HOME` **is** honoured on macOS; an empty and a relative one are both
ignored in favour of the default, which is the freedesktop rule and py's
`is_absolute()` check; and no `XDG_RUNTIME_DIR` fallback is invented in any of the
five cases. Case 5 is the correction to B6 above: removing `HOME` produces no
`HomeDirError` at all, because `std::env::home_dir()` falls through to the
`passwd` entry. 6 passing checks in this section.

**What this check does not do.** It does not build the template, a paths module,
an accessor, a seam, a CI job or an acceptance script — P03 builds those. Every
criterion in the B1–B7 table is P03's to prove in the real template; §8 observes
only the *crate's* half of B2 and B3, on one of the two CI legs.

## Engines

- codex `raw/codex.md` — gpt-5.6-terra, sha256 `39dcb56937109b40d46a7efb31fcc47467cfbf2015e6ff7e1aeaedb7b75dd45d`, 15 H3 sections, collected 2026-09-17T04:08:14Z. Recommends **config-only now**: zero data/state/cache accessors and no directory crate, with `etcetera` 0.11.0 as a runner-up that wins only if R59 or R67 later names a persistent file.
- opus `raw/opus.md` — claude-opus-5, sha256 `1a115d2309f24957bb131ec2b0e34d17142e6d9423d0f8290e0124374dfc4857`, 15 H3 sections, collected 2026-09-17T04:35:15Z. Recommends the **full set, unconditionally**, via `etcetera` 0.11.0 `choose_base_strategy()` wrapped in a template-owned `Paths`, with `directories`/`dirs` excluded on the macOS `state_dir()` gap.
- No Doxa engine: Focused tier, two engines, no paid run (`manifest.json`, `remaining_budget: "no paid engine (Focused tier)"`).

**Disagreement 1 — config-only versus the full set. This decision takes Opus's
answer, on a ground neither engine's own reasoning supplies by itself.** Codex's
argument is that no consumer exists, so three accessors would have no caller. Its
`### Sources` section names the freedesktop specification, crates.io, GitHub,
RustSec, docs.rs and the two pinned source repositories — **and does not name the
org CLI Design Standard at all**. Codex therefore argued the question the prompt
posed ("should this be contingent?") without the document that removes the
contingency, and additionally read R67's *deferral* as the absence of a consumer
when it is the opposite: R67 is owner-accepted and its crash record is
unimplementable until this item answers. Settled by two pieces of evidence, both
executed here rather than taken from a raw: `R5.3` carries the MUST keyword and
provenance row 10 marks filesystem paths `org-locked` (§1), and
`R67 DECISION.md:33` defers the crash-record location to R57 (§2). Codex's
underlying instinct — do not invent public surface for an absent consumer — is
not discarded: it is what keeps the **Runtime** accessor out, and it is why the
`## Decision` table states the force of each row separately instead of collapsing
all four into the MUST.

**Disagreement 2 — which `BASELINE-REVIEW: F249` text the ledger row gets.** Both
engines emitted a line and the two texts differ. Codex's proposes keeping R57
config-only until R59 or R67 selects persistent disk output — that is, it proposes
*restating* the contingency rather than removing it. Opus's proposes replacing the
contingency clause because `R5.3` is an org-locked MUST. **Opus's disposition is
taken**, edited for the gradation above: the line carried into `## Decision`
replaces the clause and says the *location rule* is unconditional while which
roots are resolved on day one stays a consumer question. The ground is that
`R5.3` is a MUST — verified at the pinned blob in §1, not quoted from either raw.
Codex's text cannot stand on the same evidence, because it does not cite the
standard.

**Disagreement 3 — `directories` maintenance: `archived` (Codex) versus
`stable-quiet` after relocation to Codeberg (Opus).** Not settled here, and it
does not need to be: neither reading changes the outcome, because what excludes
the family is the macOS `state_dir() -> None` fact, which this decision verified
in the crate's own `src/mac.rs` at a pinned sha256 (§5) rather than inferring from
a documentation page or a maintenance verdict. Opus's account is the better
supported of the two — it names the live Codeberg repositories and a `dirs` 7.0.0
release on 2026-09-05 — and is carried as such, unverified here.

**Disagreement 4 — RustSec 404: "provisional, not a positive audit" (Codex)
versus "evidence of absence" (Opus).** Settled in Opus's favour, by reproducing
the paired control (§7): `anyhow` returns 200 from the same endpoint on the same
run, so the 404 for `etcetera` is absence rather than a broken endpoint. Codex was
right to refuse an unpaired 404; the control is what converts it.

**Disagreement 5 — `xdg` 3.0.0 gate 4.** Codex read its published CI workflow and
fails it for naming Ubuntu only; Opus passes it on stated platform support without
reading the workflow. **Not settled**: neither was re-checked here, and it is
immaterial, because `xdg` is not recommended under either reading. Recorded so a
later item that shortlists `xdg` knows the gate is open.

**Corrections this decision makes to the raw it otherwise follows.** Opus read
`etcetera`'s per-OS dispatch, its `[target.'cfg(windows)']` stanza and its CI
matrix from `master`, which is unreleased 0.12.0, and listed the version-skew as
something it could not verify. Reading the published 0.11.0 tarball closes that
(§4) and corrects two details: 0.11.0 is **already** edition 2024, not only
`master`, so only the MSRV number moves at 0.12.0; and 0.11.0's own shipped
workflow pins its MSRV row at **1.87.0**, matching its declared `rust-version`,
not `master`'s 1.95.0. Opus's acceptance criterion B6 is corrected outright — see
`### Principles and implementation` — because unsetting `HOME` does not produce
`HomeDirError` on Unix.

**Unproven, and what would prove each.**

| # | Claim | Why it is unproven | What would prove it |
|---|---|---|---|
| U1 | Every B1–B7 acceptance criterion | The template does not exist; P03 builds it. §8 observes only the crate's half of B2 and B3, on one leg | P03's `cargo test` on both `target-os-matrix` legs |
| U2 | The same macOS behaviour holds on `ubuntu-latest` | The spike ran on `Darwin arm64` only. The `Xdg` strategy is the same code path on both, and the dispatch selects `Xdg` on Linux as well (§4), so this is very likely — but it is inference, not observation | Running the same spike, or P03's V4/V5, on an `ubuntu-latest` runner |
| U3 | The adopter evidence — `uv`, `bat`, `fd`, `jj`, `ruff`, `cargo-nextest` manifests and star counts, and `etcetera`'s 197 reverse dependencies | Carried from `raw/opus.md` (endpoints `gh api repos/<o>/<r>` and `crates.io/api/v1/crates/etcetera/reverse_dependencies`, retrieved 2026-09-17); not re-fetched here | Re-querying those endpoints; the recommendation does not turn on them, since the macOS capability fact decides it |
| U4 | The `directories` maintainer's written refusal of XDG-on-macOS (issue #117, `soc`, 2026-06-16) | Carried from `raw/opus.md` at its retrieval date; the Codeberg issue was not re-fetched here, and Opus itself records that the rationale the reply links to was never opened | Re-fetching `codeberg.org/api/v1/repos/dirs/directories-rs/issues/117/comments`. It strengthens the exclusion from "currently absent" to "permanently declined"; the exclusion stands on the verified source either way |
| U5 | Issue-responsiveness and maintenance figures for both candidates | Carried from `raw/opus.md`; not re-collected | Re-running the prescribed 10-most-recent-issues procedure |
| U6 | Windows behaviour of the recommended design | Windows is outside `target-os-matrix` and nothing was run there. `state_dir()` would collapse onto the data directory | A `windows-latest` leg, which is a matrix change the owner has declined |
| U7 | Whether `xdg` 3.0.0 passes gate 4 | Disagreement 5 above | Reading `whitequark/rust-xdg`'s CI workflow |

**What P03 must validate.**

1. **V4/V5 on both legs.** An absolute `XDG_STATE_HOME` yields `<tmp>/s/rslbp`,
   and an empty or relative one falls back to `<tmp>/.local/state/rslbp`, on
   `ubuntu-latest` **and** `macos-latest`. These two must never be allowed to run
   on one leg only: the entire crate choice rests on their macOS result.
2. **B6's failure path, constructed deliberately** — not by unsetting `HOME`, per
   the correction above — and mapped to the code P03 settles on. This decision
   proposes `RSLB101`/exit 1; R67 defines that code but does not assign this
   failure to it, and R54 may instead claim the config-file case for `RSLB104`.
   Whichever is chosen, exit `1` and a byte-empty stdout are the fixed part.
3. **`Paths` under R04's public-API enforcement**, including whether
   `from_strategy(&impl BaseStrategy)` may carry an `etcetera` type in a public
   signature; the escape hatch is recorded under *Tradeoffs*.
4. **The web surface constructs `Paths` lazily or not at all**, so a container
   running without a resolvable home still boots (R51, R69, R77).
5. **B7's layering**: `cargo tree -p <lib> -i anyhow` empty, and no `std::fs`
   write or `std::io` stream access in the paths module.
6. **R82's docs gate**: the README's directory table and the paths module's doc
   comments name the same four paths the binary prints, so `R5.3`'s "documented"
   obligation cannot silently rot, and `R5.9`'s cache-location obligation is met
   before anything caches.
