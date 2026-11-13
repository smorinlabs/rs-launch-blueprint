# R54 — config-discovery-tiers (bundle, Deep) — raw report

Engine identity `research-opus-2026-09-17T033527Z-8dfef31d60fc`, model `claude-opus-5`,
item kind `bundle`, effort tier `deep`. Independent engine: no other engine's report was
read or listed.

**Retrieval date for every figure and quotation below: 2026-09-17 (UTC).** The harness
reports the local date as 2026-09-16; every endpoint call in this run was made after
06:00 UTC on 2026-09-17 (`date -u` → `2026-09-17T06:07:21Z`), so the UTC date is the one
to re-verify against.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate in this report. Nothing is excluded on licence; licence strings are reported as
metadata only. The ruling is `docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check
for anything the template uses (Q4, superseded and widened by Q7.B)".

**Status.** This is research for P03 to implement. No Rust source exists in
`rs-launch-blueprint`; nothing here is an implemented result. One throwaway probe
directory under `$TMPDIR` was created to extract published crate sources and was deleted
at the end of the run; it contained no template code.

### Landscape

**The category this item decides.** Not "which config crate". The category is
**configuration *discovery and composition*** — the set of filesystem locations a process
searches for its configuration file, the order in which the found layers override one
another, and the mechanism that merges them into one typed value. It is separable from
three neighbouring categories that other items own: the *serialization format and its
parser* (R52 — `toml` 1.1.6 + `toml_edit` 0.25.15), the *typed schema and its validation*
(R53 — `serde` only, per-key loop), and the *failure policy for a bad layer* (R55 —
provenance-aware two-phase loader). R54 decides how many tiers exist, where each one
lives, and how they compose.

**The three-bin map of the Rust field.**

| Bin | Candidates found | What each actually provides |
|---|---|---|
| **Built-in / first-party toolchain** | `std::env::var_os`, `std::env::split_paths`, `std::path::Path::is_absolute`, `std::path::Path::ancestors`; **Cargo's own hierarchical config** as the first-party *reference design* | `split_paths` does the platform-correct `PATH`-style split that `$XDG_CONFIG_DIRS` needs; `ancestors()` is the walk-up iterator. Cargo is not a library here — it is the toolchain's own worked example of walk-up discovery, cited below as authority. |
| **Established industry standard** | `config` (config-rs) 0.15.25 · `figment` 0.10.19 · `etcetera` 0.11.0 · `directories` 6.0.0 · `dirs` 7.0.0 · `xdg` 3.0.0 · `clap` 4.6.7 (`env` feature) | Two distinct sub-categories that are routinely confused. `config`/`figment` are **layer-merging engines** (they own the merge and the final deserialize). `etcetera`/`directories`/`dirs`/`xdg` are **directory resolvers** (they answer "where is the user config dir", nothing more). Only one of the seven — `xdg` — enumerates `$XDG_CONFIG_DIRS`. |
| **Up-and-comer** | `confique` 0.4.0 · `twelf` 0.15.0 · `ortho_config` 0.9.0 · `confy` 2.0.0 | `confique` is a derive-based layered loader with template generation; `twelf` is a derive-based multi-source layerer; `ortho_config` (0 GitHub stars) explicitly targets the "CLI + env + file" ortho-precedence problem this item names; `confy` is deliberately single-file, single-tier. |

Candidates were taken from this map. `directories` and `dirs` entered it because the
ledger row F247 names `directories` by name; `xdg` entered because it is the one crate in
the field that enumerates the system tier; `ortho_config` entered on a `categories=config`
registry sweep rather than on familiarity.

**Authoritative sources used, and why each is authoritative.**

| Source | Why it is authoritative here |
|---|---|
| **The org CLI Design Standard v1.4.14**, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, `git -C /Users/stevemorin/c/cli-standards cat-file blob f9de0437…` (read 2026-09-17) | It is the owner's own normative document and it is *binding on this item*: R5.1 is `(MUST)` and fixes the precedence chain verbatim; R5.2 is `(MUST / SHOULD)` and fixes the filenames and the `--config` semantics. It is not evidence to weigh — it is the contract. |
| **XDG Base Directory Specification**, source-of-truth DocBook at `https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml` (retrieved 2026-09-17, HTTP 200, 15,498 bytes) | The specification the standard's R5.3 defers to ("XDG paths are the canonical reference"). Used directly because `https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html` now returns a 158-byte meta-refresh stub with no spec text (verified 2026-09-17), so the rendered page is not quotable. |
| **The Cargo Book, "Configuration"**, `https://doc.rust-lang.org/cargo/reference/config.html` (retrieved 2026-09-17, HTTP 200, 103,191 bytes) | Rust-project publication describing the toolchain's own discovery algorithm. First-party, and the single most-executed config-discovery implementation in the ecosystem. |
| **Published crate sources at exact versions**, downloaded from `https://static.crates.io/crates/<name>/<name>-<ver>.crate` and read locally (2026-09-17) | Maintainer-authored ground truth. Every mechanism claim below is a line citation into an extracted `.crate`, never a docs.rs summary. |
| **crates.io and GitHub REST APIs** (2026-09-17) | The figure endpoints the prompt's evidence table names. |
| Maintainers' own documentation: jj `docs/config.md` (`https://raw.githubusercontent.com/jj-vcs/jj/main/docs/config.md`, HTTP 200, 87,486 bytes, 2026-09-17) | The adopter's own normative description of its tier chain — stronger than inferring tiers from source. |

A single blog post was not used as authority anywhere in this report.

**Well-regarded projects surveyed, with the evidence that they are well regarded.** Each
manifest was fetched raw and grepped; the line numbers are in the fetched file.

| Project | Manifest evidence (retrieved 2026-09-17) | Why it is a relevant, well-regarded reference |
|---|---|---|
| **Cargo** | n/a — cited as the *documented algorithm*, not a dependency | The Rust project's own package manager; its config discovery is the de-facto ecosystem convention. |
| **helix** | `Cargo.toml:58` `etcetera = "0.11"`; `helix-loader/Cargo.toml:23` `etcetera.workspace = true` | A top-tier Rust editor with a workspace-local (`.helix/`) plus user-config tier split; large contributor base; consumes `toml = "1.1"` at `Cargo.toml:54`. |
| **ruff** (astral-sh) | `Cargo.toml:99` `etcetera = { version = "0.11.0" }`; `:198` `toml = { version = "1.0.0" }` | The dominant Python linter, written in Rust; hierarchical per-directory config discovery is its core product behaviour. |
| **uv** (astral-sh) | `Cargo.toml:158` `etcetera = { version = "0.11.0", default-features = false }`; `:311` `toml`; `:318` `toml_edit` | The fastest-growing Rust CLI of the last two years; implements user + project + workspace config tiers. Note it disables `etcetera`'s default features. |
| **bat** | `Cargo.toml:67` `etcetera = { version = "0.11.0", optional = true }`, gated by the `etcetera` feature at `:29`; `:122` `toml` | A widely installed terminal tool. It carries `etcetera` and **no `dirs` dependency at all** (`/usr/bin/grep -n -E '^\[dependencies\.dirs\]|^dirs' bat/Cargo.toml` → no match, 2026-09-17). A `dirs` → `etcetera` *migration* is often asserted for bat; this run **could not verify it** — `CHANGELOG.md` (65,162 bytes, 2026-09-17) mentions neither crate — so only the current state is claimed. |
| **jj (jujutsu)** | `Cargo.toml:60` `etcetera = "0.11.0"`; `:131` `toml = "1.1.0"`; `:132` `toml_edit`. **No `config`, no `figment`, no `dirs`, no `directories`, no `xdg`** (grep for `^config|^figment|^etcetera|^dirs|^directories|^xdg` returned only line 60) | The most architecturally ambitious new Rust VCS; and the *only* surveyed project that documents a **full six-tier chain** — see `### Principles and implementation`. It is this item's closest production analogue. |
| **starship** | `Cargo.toml:41` `dirs = "7.0.0"`; `:88` `toml = { version = "1.1.6", features = ["preserve_order"] }`; `:89` `toml_edit = "0.25.15"` | A very widely installed prompt; cited here as the **counterexample** — it resolves its config directory with `dirs`, not `etcetera`, and carries no layering crate. Its tier count was not verified from its documentation in this run and is not claimed. |

The survey's finding, stated before any gate or figure is weighed: **five of the six
modern, well-regarded Rust CLIs that resolve a user config directory use `etcetera`
0.11.x, and none of the six depends on a layering crate.** The second half is a census,
not an impression: `/usr/bin/grep -n -E '^(config|figment|confique|twelf|ortho_config|confy)[ =]'`
run by absolute path over each of the six fetched manifests — helix (74 lines), ruff (363),
uv (541), bat (133), jj (197), starship (140) — returns **zero matches in all six**
(2026-09-17). No `head`, no `cut`, no comment filter. The layer-merging engines are widely
downloaded but are not what this class of CLI reaches for.

**And the strongest single datapoint is uv, which documents the exact chain this item must
build.** From uv's own `docs/concepts/configuration-files.md`
(`https://raw.githubusercontent.com/astral-sh/uv/main/docs/concepts/configuration-files.md`,
HTTP 200, retrieved 2026-09-17):

> uv supports persistent configuration files at both the project- and user-level.
> Specifically, uv will search for a `pyproject.toml` or `uv.toml` file in the current
> directory, or in the nearest parent directory. … uv will also discover `uv.toml`
> configuration files in the user- and system-level configuration directories … If
> project-, user-, and system-level configuration files are found, the settings will be
> merged, with project-level configuration taking precedence over the user-level
> configuration, and user-level configuration taking precedence over the system-level
> configuration. (If multiple system-level configuration files are found, e.g., at both
> `/etc/uv/uv.toml` and `$XDG_CONFIG_DIRS/uv/uv.toml`, only the first-discovered file will
> be used, with XDG taking priority.) … Settings provided via environment variables take
> precedence over persistent configuration, and settings provided via the command line take
> precedence over both. … uv also accepts a `--config-file` command-line argument … When
> provided, this file will be used in place of _any_ discovered configuration files.

That is R5.1's six rungs and R5.2's replace-not-merge `--config`, shipped — **including a
`$XDG_CONFIG_DIRS` system tier that uv hand-rolls, because the `etcetera` 0.11.0 it depends
on cannot provide one.** uv is the existence proof for this item's recommendation, not an
analogy to it. It differs in exactly one documented place: "If an array is present in both
tables, the arrays will be concatenated" — R5.1 makes arrays *replace* by default and
permits concatenation only as a documented deviation, so the template takes the default and
uv takes the `MAY`.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required**

The shared engineering principle is **layered configuration with documented, total
precedence**: a user can place settings at the scope that matches their authority — the
machine, their account, or the checkout they are standing in — and the tool resolves a
conflict between scopes by one published, deterministic rule.

The source of the requirement is **not** py. py is evidence. The source is the org CLI
Design Standard, whose **R5.1 is marked `(MUST)`** and reads verbatim at blob
`f9de0437`:

> Configuration **MUST** resolve in this order, highest priority first, and the tool
> **MUST** document it verbatim:
> 1. Command-line flags
> 2. Environment variables (`TOOL_*`)
> 3. Project/local config file: nearest `.<tool>/<tool>_config.toml`, discovered by walking up from the working directory
> 4. User config file: `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`
> 5. System config file: each `$XDG_CONFIG_DIRS/<tool>/<tool>_config.toml`
> 6. Built-in defaults

and, on merging:

> Where more than one config file in the chain sets the same key, maps/tables **MUST**
> merge recursively by default. Scalar values replace scalar values, arrays **replace**
> arrays (not concatenate), and the nearer scope wins. A tool **MAY** use a different
> merge strategy (e.g., array concatenation, cargo-style) where its domain requires it,
> but **MUST** document the strategy clearly.

**R5.2 `(MUST / SHOULD)`** fixes the locations and the override semantics:

> The canonical discovered config filename **SHOULD** be `<tool>_config.toml` for
> findability: project/local discovery looks for `.<tool>/<tool>_config.toml` in the
> current directory and then each parent directory, user config is
> `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`, and system config is searched under each
> `$XDG_CONFIG_DIRS` entry as `<tool>/<tool>_config.toml`. Project discovery **SHOULD**
> stop at a repository/workspace boundary when detectable — for example a `.git`
> directory or a language/workspace root marker such as `Cargo.toml`, `go.mod`,
> `package.json`, or `pyproject.toml` (a non-exhaustive baseline) — otherwise at the
> filesystem root. An explicit `--config <path>` **MUST** **replace** the discovered
> project/user/system config files — it becomes the sole config file in the chain — while
> command-line flags and environment variables still layer above it and built-in defaults
> below it (R5.1). It does **not** merge with the files it overrides.

**R5.4 `(MUST)`** settles F234 without research: it names `ACME_CONFIG` explicitly in the
curated environment subset — "typically auth/token, host/endpoint, output format, config
path, and telemetry opt-out" — so `RSLBP_CONFIG` is standard-mandated, not merely
py-inherited.

This changes the shape of the answer. **The tier set and the precedence order are not a
research finding; they are a contract R54 must implement.** What R54 researches is the
*mechanism*: which Rust crate or pattern realizes each tier, and whether a layering
library or a custom composition preserves the rest of the config stack's decisions.

**What must agree across py, ts and rs, and what may vary.**

| # | Principle | Agreement level | Must agree across the three repos | May vary per ecosystem |
|---|---|---|---|---|
| C1 | Configuration resolves through a documented, total precedence chain with no silent ties | **standard, one value for all three repos** (R5.1 is `MUST` and applies to every tool the standard governs) | the six-rung order and the fact that it is documented verbatim | nothing — this is the org-locked rung |
| C2 | Three file scopes exist: system, user, project | **standard** | that all three scopes are searched, and their relative order | the *directory API* used to find them |
| C3 | Per-user paths follow XDG, honouring `XDG_*` overrides | **capability + standard** | `XDG_CONFIG_HOME` honoured, and an unusable value ignored (F247) | the crate; macOS may use XDG rather than `~/Library/Application Support` (both sources already do) |
| C4 | An explicit `--config` replaces the discovered file chain rather than adding to it | **architectural pattern** (F233, `COMMON → REUSE`, already agreed — not this item's decision) | the replace-not-add semantics | the control flow implementing it |
| C5 | The config path has one documented environment alias | **policy/mechanism** | that an alias exists and is named after the tool | the variable's spelling (`PLBP_CONFIG` / `TS_PROJECTS_CONFIG` / `RSLBP_CONFIG`) |
| C6 | Tables merge recursively; scalars and arrays replace | **standard** | the merge semantics | the merge *implementation* — a value-tree walk (py/ts) or a typed per-field fold (Rust) |

C6 is where the ecosystems genuinely must differ, and stating why is the core of this
item's Rust-specific reasoning. py and ts merge **untyped dictionaries** and then validate
once; that is natural in a language whose native map type *is* the parsed document. Rust's
equivalent move — merge `toml::Table`s, then deserialize once — is available and is what
`config`/`figment` do, but it discards the two properties R53 and R55 already bought. See
the architectural comparison below.

**Where the ledger, the sources and the standard disagree — two baseline reviews**

**py does not walk up.** The prompt's MEDIUM question asks for "the idiomatic Rust pattern
for a project-local upward directory search (matching py's `project_config_file()`
cwd-relative discovery)". Read at the pin, py performs **no upward search at all**:

```
py src/py_launch_blueprint/core/paths.py:184-191 (git show b08bccfb:…)
def project_config_file(start: Path | None = None) -> Path:
    base = start or Path.cwd()
    dotfile = base / f".{CONFIG_FILENAME}"
    return dotfile if dotfile.exists() else base / CONFIG_FILENAME
```

It inspects exactly one directory (the cwd) and prefers a **dotfile**
`./.plbp_config.toml` over `./plbp_config.toml`. The standard requires a **dot-directory**
`.<tool>/<tool>_config.toml` found by walking up with a boundary stop. These are different
designs, and the ledger row currently records py's.

> `BASELINE-REVIEW: F232 — project-local config discovery must be an upward search for a dot-*directory*, not a cwd-only dot-*file* — replace the row's parenthetical "(`./<tool>_config.toml`, dotfile preferred)" with the standard's `.<tool>/<tool>_config.toml` walked up from the working directory and stopped at a repository/workspace boundary, and record that the py shape the parenthetical describes is not adoptable — evidence: py `src/py_launch_blueprint/core/paths.py:184-191` at pin `b08bccfb` inspects only `Path.cwd()` and returns a dotfile, while org CLI Design Standard R5.1 rung 3 (`MUST`) and R5.2 (`SHOULD`) at blob `f9de0437` both specify the dot-directory form discovered "in the current directory and then each parent directory"; affected items R54 (this item, which must implement the standard) and R55 (whose F236 discovered-layer clause applies to whichever project file this tier names)`

**py's absoluteness check is the specification, not a py nuance.** F247's ledger note calls
it "a minor same-origin implementation nuance, not a verdict-changing difference", and
`docs/port/BASELINE-REVIEW.md:113` leaves it as an open owner question. The XDG
specification settles it, verbatim:

> All paths set in these environment variables must be absolute. If an implementation
> encounters a relative path in any of these variables it should consider the path invalid
> and ignore it.
> — XDG Base Directory Specification, `https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml`, retrieved 2026-09-17

And the recommended crate already implements exactly that, with the empty case falling out
of the same test:

```
etcetera-0.11.0/src/base_strategy/xdg.rs:175-183
    fn env_var_or_none(env_var: &str) -> Option<PathBuf> {
        std::env::var_os(env_var).and_then(|path| {
            let path = PathBuf::from(path);
            // Return None if the path obtained from the environment variable isn’t absolute.
            if path.is_absolute() { Some(path) } else { None }
        })
    }
```

`PathBuf::from("")` is not absolute, so `XDG_CONFIG_HOME=` (set but empty) and
`XDG_CONFIG_HOME=foo/` (relative) both fall through to the default — F247's "honoured on
ubuntu-latest and macos-latest and ignored when empty" **plus** py's absoluteness check,
from one crate, with no template code.

> `BASELINE-REVIEW: F247 — the absoluteness requirement is normative, not a py nuance — drop "py additionally requires absoluteness, a minor same-origin implementation nuance, not a verdict-changing difference" and record absoluteness as part of the acceptance criteria, closing the open owner question at `docs/port/BASELINE-REVIEW.md:113` in favour of "required" — evidence: the XDG Base Directory Specification states "All paths set in these environment variables must be absolute. If an implementation encounters a relative path in any of these variables it should consider the path invalid and ignore it" (`https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml`, retrieved 2026-09-17), and `etcetera` 0.11.0 `src/base_strategy/xdg.rs:175-183` implements it, so adopting it costs nothing; affected items R54 (this item) and R57 (which owns the `Paths` type carrying the behaviour)`

Neither review changes another item or the ledger; both are recorded for the owner.

**The system tier: the decisive mechanism finding**

**HIGH question 1, answered from source: no directory crate in the recommended stack
enumerates the system tier, and the one crate that does is not usable alongside it.**

A census of the entire extracted `etcetera` 0.11.0 source tree for `CONFIG_DIRS` or
`DATA_DIRS` — `/usr/bin/grep -rn "CONFIG_DIRS\|DATA_DIRS" etcetera-0.11.0/src` — returns
**zero matches** (2026-09-17). The `BaseStrategy` trait at
`etcetera-0.11.0/src/base_strategy.rs:7-32` declares exactly six methods: `home_dir`,
`config_dir`, `data_dir`, `cache_dir`, `state_dir`, `runtime_dir`. All are singular. The
`$XDG_CONFIG_DIRS` multi-directory search has no representation in the crate at all.

The same is true of `directories` 6.0.0 and `dirs` 7.0.0, which expose a single
`config_dir()`. The **one** crate in the field that does the job is `xdg` 3.0.0:

```
xdg-3.0.0/src/base_directories.rs:288-298
        fn abspaths(paths: OsString) -> Option<Vec<PathBuf>> {
            let paths: Vec<PathBuf> = env::split_paths(&paths)
                .map(PathBuf::from)
                .filter(|path| path.is_absolute())
                .collect::<Vec<_>>();
            if paths.is_empty() { None } else { Some(paths) }
        }
…
xdg-3.0.0/src/base_directories.rs:321-323
        let config_dirs = env_var("XDG_CONFIG_DIRS")
            .and_then(abspaths)
            .unwrap_or(vec![PathBuf::from("/etc/xdg")]);
…
xdg-3.0.0/src/base_directories.rs:725-731
    pub fn get_config_dirs(&self) -> Vec<PathBuf> { … }
```

That is semantically identical to py `core/paths.py:108-128` — platform-separator split,
non-absolute entries filtered, `/etc/xdg` default. It is a genuine, correct
implementation. It is nonetheless **not** recommended, for two reasons that are
architectural rather than metric:

1. `xdg-3.0.0/src/lib.rs:1` is `#![cfg(any(unix, target_os = "redox"))]`. The crate
   compiles to an empty crate on Windows. `target-os-matrix` is `ubuntu-latest,
   macos-latest`, so this passes gate 4 — but it forecloses a future Windows row that the
   template would otherwise only have to widen a matrix for.
2. **Two sources of truth for `XDG_CONFIG_HOME`.** Adding `xdg` alongside `etcetera` puts
   two independent resolvers for the *same* variable in one binary: `etcetera`'s
   `env_var_or_none` (`xdg.rs:175-183`) and `xdg`'s `abspath` (`base_directories.rs:279-286`).
   They agree today, byte for byte. A divergence in either crate would become a silent
   split between which directory `config set` writes to and which directory the user tier
   reads from. R57 already made `etcetera` the template's single directory authority; a
   second resolver contradicts that at the design level, not at the metric level.

The system tier is therefore **hand-rolled on `std`**, and it is small. The complete
mechanism, with the two `std` functions it rests on:

- `std::env::var_os("XDG_CONFIG_DIRS")` → `Option<OsString>`.
- `std::env::split_paths(&v)` → the platform-correct `PATH`-style iterator (`:` on Unix).
  This is the same function `xdg` 3.0.0 uses at `base_directories.rs:289`; using it rather
  than a literal `':'` is the reason this is not "reimplementing a crate badly".
- `.filter(|p| p.is_absolute())` → the spec's relative-path rule, quoted above.
- empty result → `[PathBuf::from("/etc/xdg")]`, the spec's default.

**Ordering within the system tier, stated explicitly because it is easy to get backwards.**
The XDG specification says:

> The order of base directories denotes their importance; the first directory listed is
> the most important. When the same information is defined in multiple places the
> information defined relative to the more important base directory takes precedent. …
> The base directory defined by `$XDG_CONFIG_HOME` is considered more important than any
> of the base directories defined by `$XDG_CONFIG_DIRS`.

So among system directories the **first** `$XDG_CONFIG_DIRS` entry wins, and every system
directory loses to the user directory. py implements exactly this by reversing the list
into a later-wins fold — `config.py:135` `*reversed(paths.system_config_files()),  # system
(lowest first)` — and `paths.py:108-116`'s docstring says so ("Returned highest-precedence
first, matching the spec"). The template reproduces the same outcome; the report states it
because a naive `for dir in config_dirs { merge(dir) }` over a later-wins fold silently
inverts it.

**Architectural alternatives, compared before any library was chosen**

| Alt | Shape | Verdict and the principle at stake |
|---|---|---|
| **A1** | **A layer-merging engine owns everything** — `config` 0.15.25 or `figment` 0.10.19 takes a list of sources, merges dynamic value trees, and produces one `T` by a single final `deserialize`. | **Rejected on fit, not on a gate.** The merge happens *outside* serde, over an untyped value tree, and the final `deserialize` sees one synthetic document with no file of origin. R55's decision — already made — requires that a leaf the typed pass rejects is "dropped from its own layer with a warning naming the file and the dotted key path". Under A1 the layer is gone by the time deserialization runs, so "its own layer" is not recoverable from the failing error; `figment`'s `Metadata` and `config`'s origin tracking attach provenance to a *source*, not to the surviving value of a key after the merge. Choosing A1 would force R55 to be re-opened. Secondary costs are real but secondary: `config` 0.15.20's `default` feature set is `["toml","json","yaml","ini","ron","json5","convert-case","async"]` (`config-0.15.20/Cargo.toml:89-98`), pulling five parsers the template does not want and `async-trait` (`:86`, `:158`) into a binary whose format is fixed to TOML by R5.2 and R52 — mitigable with `default-features = false, features = ["toml"]`, but it means the crate's out-of-the-box shape is wrong for this template. |
| **A2** | **`toml::Table` recursive merge, then one deserialize.** Parse each layer with R52's `toml` into a `toml::Table`, merge tables recursively in precedence order, deserialize the result once. | **Rejected for the same reason as A1, in the template's own code.** It satisfies R5.1's recursive-table `MUST` most directly, and it is genuinely the smallest thing that could work — but it re-creates A1's provenance loss inside the template instead of inside a dependency, and it additionally loses R53's per-key typed rejection: a bad leaf fails the single final deserialize, taking the whole merged document with it. |
| **A3** | **Provenance-carrying per-layer typed parse, then a field-wise fold** — discover the ordered layer paths; parse each layer independently into an all-`Option` `PartialConfig` via `serde` (R53) instrumented by `serde_path_to_error`/`serde_ignored` (R55); fold the partials in precedence order with "a later `Some` replaces an earlier value"; finalize against built-in defaults. | **Chosen.** Every layer keeps its identity right through deserialization, which is exactly what R55's clauses 2 and 3 need; R53's per-key loop is what the fold folds; the `--config` replacement of C4/F233 is a one-line change to the *path list*, before any parsing, rather than a special case inside a merge engine; and the merge rule is template code, so R5.1's "MUST document the strategy clearly" is satisfied by a doc comment the tests pin. |
| **A4** | **Derive-macro layered loader** — `confique` 0.4.0 or `twelf` 0.15.0 declares the layers as attributes on the config struct. | **Rejected.** `confique`'s layering is per-source-file and its `Partial` type is generated — attractive, and genuinely the same shape as A3 — but the crate cannot express the *discovery* half at all (the search path is still the caller's), so it replaces the easy half of this item and not the hard half. `twelf` last released 2024-03-11 and its repository was last pushed 2024-05-27, both over two years before this retrieval. |
| **A5** | **Single tier only** — user config file plus `--config`, ts's shipped shape and starship's. | **Rejected: it violates R5.1, a `MUST`.** Recorded because it is what ts actually ships despite ts's own D-017(1) naming the full chain. The prompt calls that gap live context; the standard closes it. |

**How A3 satisfies R5.1's recursive-table `MUST`, and the coupling that makes it true.**
A field-wise fold merges recursively **only if nested tables are themselves `Option`-wrapped
partial structs** — a fold over `Option<SubTable>` replaces the whole sub-table, which is
scalar semantics applied to a table and would violate R5.1. The requirement is therefore
that R53's `PartialConfig` is *recursively* partial: every nested table is
`Option<PartialSub>` where `PartialSub`'s own fields are `Option` too, and the fold
recurses into `Some`/`Some` pairs. **That is a coupling for R53, not a decision R54 makes**;
it is stated here so R53 knows the constraint exists. Arrays are `Option<Vec<T>>` and
replace wholesale, which is what R5.1 requires ("arrays **replace** arrays (not
concatenate)") and is where the template deliberately differs from Cargo, whose arrays
join.

**The project tier: what the first-party reference actually does**

Cargo is the toolchain's own worked example, and it is quotable:

> Cargo allows local configuration for a particular package as well as global
> configuration. It looks for configuration files in the current directory and all parent
> directories. If, for example, Cargo were invoked in `/projects/foo/bar/baz`, then the
> following configuration files would be probed for and unified in this order:
> `/projects/foo/bar/baz/.cargo/config.toml` … `/.cargo/config.toml`, `$CARGO_HOME/config.toml`
> … If a key is specified in multiple config files, the values will get merged together.
> Numbers, strings, and booleans will use the value in the deeper config directory taking
> precedence over ancestor directories, where the home directory is the lowest priority.
> Arrays will be joined together with higher precedence items being placed later in the
> merged array.
> — The Cargo Book, "Configuration", retrieved 2026-09-17

Three things the template takes, and two it does not.

**Takes:** the dot-directory form (`.cargo/` ↔ `.rslbp/`), which is exactly R5.2's
`.<tool>/<tool>_config.toml` shape and is why the standard's dot-*directory* is idiomatic
rather than arbitrary; the walk-up over `Path::ancestors()`; and deeper-wins.

**Does not take:** (1) Cargo **merges every ancestor**, producing an unbounded number of
project layers. R5.1 rung 3 says "**nearest** `.<tool>/<tool>_config.toml`" — singular. The
template stops at the first hit, giving exactly one project layer and a six-layer maximum
chain. (2) Cargo walks to the filesystem root with no boundary stop; R5.2 says project
discovery **SHOULD** stop at a repository/workspace boundary. The template stops at the
first directory containing a **boundary marker** — *inclusive* of that directory, so a
`.rslbp/` at the repository root is found — and otherwise at the filesystem root.

**Which markers, and a defect in the obvious answer.** R5.2's example list is `.git`,
`Cargo.toml`, `go.mod`, `package.json`, `pyproject.toml`, and it calls that list "a
non-exhaustive baseline", so the template chooses. Taking `Cargo.toml` at face value
**breaks in this template's own shape**: `rs-launch-blueprint` is a Cargo *workspace*, so
every member crate carries its own `Cargo.toml`. A user standing in `crates/rslbp-cli/src/`
would have the walk stop at `crates/rslbp-cli/` — the first ancestor holding a
`Cargo.toml` — and a `.rslbp/rslbp_config.toml` at the repository root would **never be
found**, which is the opposite of "a checkout carries its own settings". The marker rule is
therefore:

1. `.git` (a directory **or** a file — a `git worktree` and a submodule both write `.git`
   as a file), **always** a boundary; and
2. `Cargo.toml` **only when it contains a `[workspace]` table**, which makes it the
   workspace root rather than any member crate.

Nothing else from R5.2's list applies to a Rust repository. This rule is stated as a
recommendation for P03 rather than as a certainty: it is the one place in this item where
the standard delegates and the obvious reading is wrong, so AC7 carries a nested-manifest
case specifically to pin it.

This is the answer to MEDIUM question 1: **a hand-rolled walk-up, not a crate.** No crate
in the map implements a bounded upward search for an arbitrary relative path; `ignore` and
`locate-cargo-manifest` solve adjacent problems (directory traversal; Cargo-manifest
location), and their closures were not measured here. The loop is roughly six lines over
`std::path::Path::ancestors()` and is directly testable against a `tempfile` directory
tree, which is why each of the four surveyed adopters with a project tier writes its own —
verified from their own documentation, not inferred: ruff "supports hierarchical
configuration, such that the 'closest' config file in the directory hierarchy is used"
(`docs/configuration.md:253-254`, 2026-09-17); uv "will search for a `pyproject.toml` or
`uv.toml` file in the current directory, or in the nearest parent directory"
(`docs/concepts/configuration-files.md:5-6`); helix "you can have a `config.toml` … local
to a project by putting it under a `.helix` directory in your repository. Its settings will
be merged with the configuration directory and the built-in configuration"
(`book/src/configuration.md:33-34`); jj's repo and workspace tiers (`docs/config.md:15-21`).

**The `--config` env alias: MEDIUM question 2, answered from clap's source**

`clap` 4.6.6's `env` feature is *almost* the whole answer, and the gap is precisely
measurable. `Arg::env` captures the variable's value at declaration time:

```
clap_builder-4.6.6/src/builder/arg.rs:2205-2211
    pub fn env(mut self, name: impl IntoResettable<OsStr>) -> Self {
        if let Some(name) = name.into_resettable().into_option() {
            let value = env::var_os(&name);
            self.env = Some((name, value));
        } …
```

and the parser consumes it by testing **presence only**:

```
clap_builder-4.6.6/src/parser/parser.rs:1417-1426
            // Use env only if the arg was absent among command line args,
            // early return if this is not the case.
            if matcher.contains(&arg.id) { … continue; }
            if let Some((_, Some(ref val))) = arg.env {
```

There is no emptiness filter anywhere on that path. So:

- **Flag-beats-env precedence is free and correct**: `matcher.contains` makes an explicit
  `--config` win over `RSLBP_CONFIG`, which is R5.1 rungs 1 and 2 with no custom logic.
- **Empty is not filtered**: `RSLBP_CONFIG=` yields `Some(OsString::from(""))` and becomes
  a `--config ""`. F242 ("empty-string env/flag treated as unset", `COMMON → REUSE`)
  requires it to be treated as unset and fall through to discovery. This needs **one
  explicit check**, and it belongs in the template, not in clap.
- **No interaction with the discovery layers is needed beyond that.** Because F233/R5.2
  make `--config` *replace* the file chain, the env alias never participates in layering —
  it only selects which of two path lists the loader builds. That is the answer to the
  question's second half: a plain `env(...)` attribute plus an emptiness filter, not
  custom precedence logic.

clap also records `ValueSource::EnvVariable` (`parser.rs:1431`), which is the provenance
R5.7's `--show-origin` would need if the template later adds `config view`. Noted, not
adopted — R5.7 is a `SHOULD` and no ledger row claims it.

**Observable acceptance criteria**

Proposals for P03; none was executed in this run (no template exists).

| # | Criterion |
|---|---|
| AC1 | With a key set in all three discovered tiers, the resolved value is the project one; removing the project file yields the user one; removing that yields the first `$XDG_CONFIG_DIRS` entry's. |
| AC2 | With two entries in `$XDG_CONFIG_DIRS` both setting the key, the **first** entry wins. |
| AC3 | A `[table]` set partially in the user file and partially in the project file merges recursively; a scalar and an array each replace wholesale. |
| AC4 | `--config <path>` makes the three discovered files invisible: a key set only in the project file is absent from the resolved config, while a `RSLBP_*` env var and a flag still override the explicit file. |
| AC5 | `RSLBP_CONFIG=<path>` behaves as AC4; `--config` on the command line beats it; `RSLBP_CONFIG=` (empty) is ignored and normal discovery runs. |
| AC6 | `XDG_CONFIG_HOME` set to an absolute path relocates the user tier on **both** ubuntu-latest and macos-latest; set to `""` or to a relative path it is ignored and `~/.config` is used. |
| AC7 | Project discovery finds `.rslbp/rslbp_config.toml` in an ancestor directory, and does **not** find one that sits above the nearest boundary marker. |
| AC7b | **Nested-manifest case.** In a Cargo workspace laid out as `root/{Cargo.toml with [workspace], .rslbp/rslbp_config.toml}` and `root/crates/foo/{Cargo.toml without [workspace], src/}`, running from `root/crates/foo/src/` **finds the root file**. A rule that stopped at any `Cargo.toml` would fail this case. |
| AC8 | A missing file in any discovered tier produces no warning, no stderr output and no exit-code change (absence is not a fault — R55 clause 1). |
| AC9 | The documented precedence chain in the generated `--help`/docs is byte-compared against R5.1's six rungs by a test, satisfying R5.1's "MUST document it verbatim". |
| AC10 | A library-only test proves the library crate reads no environment variable and touches no filesystem path on import; discovery runs only when the composition root calls it. |

AC10 exists because R57's revision-2 finding JF-4 established that edition 2024 plus
`forbid` rules out internal environment reads, forcing **injection**. R54 inherits that:
the discovery function takes its inputs (`cwd`, the environment view, and R57's `Paths`)
as arguments.

### Recommendation

**One stack: `etcetera` 0.11.0 for the user tier (through R57's template-owned `Paths`),
two small `std`-only resolvers for the system and project tiers, and `clap` 4.6.6's `env`
feature with an explicit emptiness filter for the `RSLBP_CONFIG` alias — composed as a
provenance-carrying, per-layer typed parse and field-wise fold (A3). No layering crate.**

Concretely, the six-rung chain R5.1 mandates, realized:

| Rung | Tier | Location | Mechanism |
|---|---|---|---|
| 1 | Flags | argv | `clap` 4.6.6 derive (R60) |
| 2 | Env | `RSLBP_*` | `clap` `env` feature + emptiness filter |
| 3 | Project | nearest `.rslbp/rslbp_config.toml`, walking up from cwd, stopping inclusively at a boundary marker — `.git`, or a `Cargo.toml` that contains `[workspace]` | `std::path::Path::ancestors` — custom, ~6 lines |
| 4 | User | `<Paths::config_dir()>/rslbp_config.toml` = `$XDG_CONFIG_HOME/rslbp/rslbp_config.toml` | `etcetera` 0.11.0 `choose_base_strategy()` via R57's `Paths` |
| 5 | System | each `$XDG_CONFIG_DIRS` entry as `rslbp/rslbp_config.toml`, first entry highest, `/etc/xdg` default | `std::env::var_os` + `split_paths` + `is_absolute` — custom, ~8 lines |
| 6 | Defaults | `Default` impl on the finalized config type | `serde` / R53 |

`--config <path>` or a non-empty `RSLBP_CONFIG` collapses rungs 3–5 to that single path
(F233, R5.2), leaving rungs 1, 2 and 6 intact.

### Members

#### etcetera

##### Landscape
Bin: **established industry standard**, sub-category *directory resolver*. It is the
incumbent for this role in modern Rust CLIs, having displaced `dirs`/`directories` in
several: `bat` carries it as an explicitly named optional feature
(`bat/Cargo.toml:29`, `:67`), and helix, ruff, uv and jj all depend on it at 0.11.x
(manifests cited under `### Landscape`). Its competitors in the same bin are `directories`
6.0.0 (archived), `dirs` 7.0.0 (platform-native on macOS) and `xdg` 3.0.0 (Unix-only, but
the only one with a system tier).

##### Principles and implementation
Realizes C3 (XDG per-user paths with `XDG_*` overrides honoured) and rung 4 of C1. The
governing mechanism is the platform dispatch at
`etcetera-0.11.0/src/base_strategy.rs:53-60`:

```
    if #[cfg(target_os = "windows")] {
        create_strategies!(Windows, Windows);
    } else if #[cfg(any(target_os = "macos", target_os = "ios"))] {
        create_strategies!(Apple, Xdg);
    } else {
        create_strategies!(Xdg, Xdg);
    }
```

The macro's two arguments are `(native, base)` — so on macOS `choose_native_strategy()`
returns `Apple` (`~/Library/Application Support`) and **`choose_base_strategy()` returns
`Xdg`**. That single line is what makes F247 satisfiable on macos-latest, and it is the
documented intent: `src/lib.rs:57` reads "`choose_base_strategy()` and
`choose_app_strategy()` will use the `XDG` strategy on Linux & macOS, and the `Windows`
strategy on Windows." `config_dir()` is `self.env_var_or_default("XDG_CONFIG_HOME",
".config/")` at `src/base_strategy/xdg.rs:194-196`, over the absoluteness filter quoted
earlier. R57 has already selected `choose_base_strategy()` and the `rslbp` namespace
segment; this member states that coupling and does not re-decide it.

##### Dominant choice
Yes, for the user tier, on practice evidence rather than downloads: five of the six
well-regarded projects surveyed depend on it at 0.11.x, and one of them (`bat`) arrived
there without any `dirs` dependency (bat's migration history was not verifiable — see `### Landscape`).

##### Qualified shortlist
`xdg` 3.0.0 — 3,767,479 ninety-day downloads / 22,571,181 all-time
(`GET https://crates.io/api/v1/crates/xdg`, `crate.recent_downloads` / `crate.downloads`,
2026-09-17); latest unyanked `3.0.0` created 2025-05-04T10:42:18Z
(`GET …/xdg/versions`, 2026-09-17); 197 stars, `archived=false`, `pushed_at`
2025-05-04T10:42:14Z, 4 open issues (`GET https://api.github.com/repos/whitequark/rust-xdg`
and `GET https://api.github.com/search/issues?q=repo:whitequark/rust-xdg+is:issue+is:open`,
2026-09-17); licence `Apache-2.0 OR MIT`; `rust-version = "1.60.0"`, edition 2021. It is
the **only** shortlisted crate that resolves the system tier, and its implementation is
correct. Not chosen for the two architectural reasons given above (Unix-only `#![cfg]` at
`src/lib.rs:1`; a second `XDG_CONFIG_HOME` resolver in the same binary).
`dirs` 7.0.0 — 77,979,289 ninety-day / 329,160,353 all-time downloads (same endpoint,
2026-09-17), the most-downloaded of the group and starship's choice; not shortlisted for
the user tier because it resolves macOS to `~/Library/Application Support` rather than
XDG, which would fail F247 on macos-latest. Its repository has moved to
`https://codeberg.org/dirs/dirs-rs`, so the GitHub figures in the prompt's table are
`inapplicable — the project is not hosted on GitHub` for this crate.

##### Excluded by gate
`directories` 6.0.0 — **excluded by gate 4 (maintenance/platform verification) and on the
F247 behavioural requirement.** `GET https://api.github.com/repos/soc/directories-rs`
(2026-09-17) returns `archived=true`, `stargazers_count=837`, `pushed_at`
2025-01-12T19:35:58Z; latest unyanked `6.0.0` created 2025-01-12T17:19:05Z
(`GET https://crates.io/api/v1/crates/directories/versions`, 2026-09-17). An archived
repository cannot demonstrate a current CI matrix for ubuntu-latest and macos-latest, and
F247 records that its macOS `config_dir()` ignores `$XDG_CONFIG_HOME`. R67 independently
rejected it as archived on 2026-09-09; this run re-verified the `archived` field.
No candidate is excluded by gate 1 (`inapplicable — owner ruling 2026-09-12 (Q7.B)`),
gate 2, gate 3, gate 5 or gate 6.

##### Up-and-comers
None displacing it. `etcetera` *is* the up-and-comer that won this slot; the next
generation in the directory-resolver bin has not appeared.

##### Fit for this template
CLI: direct — the user tier. Library: the crate is called only from the composition root,
so the library crate never depends on it (AC10, and R57's injection finding). Web service:
unused; a web process reads `RSLBP_*` environment variables (R77), not a user config
directory. The dependency closure on ubuntu-latest and macos-latest is **`cfg-if` alone**
(`etcetera-0.11.0/Cargo.toml`: `[dependencies.cfg-if] version = "1"`;
`[target."cfg(windows)".dependencies.windows-sys]`), which is why it is cheap enough to
carry in a template.

##### Recommendation
Adopt `etcetera = "0.11.0"` — **as R57's dependency, surfaced through R57's `Paths` type,
not as a second direct dependency declared by R54**. R54 consumes `Paths::config_dir()`
and appends `rslbp_config.toml` to it.

##### Ranked runner-up
`xdg` 3.0.0. If the owner later decides that a single crate must own both the user and the
system tier and Windows is permanently out of scope, `xdg` replaces `etcetera` **and** the
custom system-tier resolver in one move, at the cost of reopening R57.

##### Tradeoffs
Gains: XDG on macOS (the F247 requirement), the spec's absoluteness rule for free, a
one-crate closure, and the largest body of comparable production practice. Costs: no
system tier at all (the decisive finding, forcing a `std` member); `state_dir()` and
`runtime_dir()` return `Option`, which R57 already handled; and 150 GitHub stars is a
small number for a crate this widely depended on — the adoption signal lives in the
reverse dependencies, not the stars.

##### Parameters
`assumes license = MIT OR Apache-2.0` (crate metadata: `MIT OR Apache-2.0`).
`assumes msrv-policy = stable minus 2 minor versions…` — `rust-version = "1.87.0"`,
`edition = "2024"` (`etcetera-0.11.0/Cargo.toml`), comfortably below the floor R67 used on
2026-09-09 (Rust 1.96.0).
`assumes rust-edition = 2024`. `assumes target-os-matrix = ubuntu-latest, macos-latest`.
No `CONFLICT:` line.

##### Migration implications
None beyond R57's: the crate is already in the template's dependency set by R57's
decision. R54 adds no new `Cargo.toml` entry for it.

##### Validation strategy
Planned (not executed — no template exists): a test that sets `XDG_CONFIG_HOME` to a
`tempfile::TempDir` and asserts the resolved user config file is
`$TMP/rslbp/rslbp_config.toml` on both runners; a second that sets it to `""` and a third
to `"relative/"`, both asserting `~/.config/rslbp/rslbp_config.toml` (AC6). Because
`std::env::set_var` is `unsafe` in edition 2024 and process-global, the environment must be
injected into the discovery function rather than mutated in-test — this is the same
constraint R57 recorded, and it makes these tests hermetic and parallel-safe.

##### Confidence & re-verify trigger
**High** on mechanism (read from the published source at the exact version). Re-verify if:
`etcetera` releases 0.12 or 1.0 (HEAD already carries `Drop cfg-if dependency (#43)`,
committed 2026-08-04T20:53:17Z and unreleased as of 2026-09-17 — the next release changes
the closure); the `cfg_if` dispatch at `base_strategy.rs:53-60` changes the macOS arm; or
`archived` flips on `lunacookies/etcetera`.

##### Sources
`https://crates.io/api/v1/crates/etcetera` and `/versions` (2026-09-17):
`recent_downloads=32829812`, `downloads=108370946`, latest unyanked `0.11.0` created
2025-10-28T13:28:11Z, `rust_version=1.87.0`, `license=MIT OR Apache-2.0`.
`https://api.github.com/repos/lunacookies/etcetera` (2026-09-17): `stargazers_count=150`,
`archived=false`, `pushed_at=2026-08-04T20:53:17Z`, `license.spdx_id=Apache-2.0`.
`https://api.github.com/search/issues?q=repo:lunacookies/etcetera+is:issue+is:open`
(2026-09-17): `total_count=2`.
Issue responsiveness (`https://api.github.com/repos/lunacookies/etcetera/issues?state=all&sort=created&direction=desc&per_page=12`
plus each issue's `/comments`, 2026-09-17): the endpoint returned **four** non-PR issues among the 12 most recent
issue-or-PR records (the page size requested); older closed issues may exist below that
window and were not retrieved — #42 opened 2026-03-27T21:19:52Z, first maintainer reply `utkarshgupta137`
2026-03-27T21:28:25Z (**0.006 d**); #41 opened 2025-11-29T22:39:43Z, first reply
2025-12-01T18:16:23Z (**1.82 d**); #37 opened 2025-09-02T06:51:33Z, first reply
2025-09-02T13:16:21Z (**0.27 d**); #35 opened 2025-04-05T23:18:18Z, **no comments,
unanswered, still open**. Median over the three answered: **0.27 days**; unanswered
count: **1**. `utkarshgupta137` is a crate owner
(`https://crates.io/api/v1/crates/etcetera/owners`, 2026-09-17: `lunacookies,
utkarshgupta137`), so these are maintainer responses.
Advisories: `https://rustsec.org/packages/etcetera.html` returned **HTTP 404** on
2026-09-17 — RustSec publishes a package page only for crates with advisories, so 404 is
the no-advisory result. `unsafe` posture: `/usr/bin/grep -rn -w unsafe` over the extracted
`etcetera-0.11.0/src` finds exactly two non-doc sites, both in
`src/base_strategy/windows.rs` (`:146` `unsafe extern "C" {`, `:156` `unsafe {`) for the
`SHGetKnownFolderPath` FFI. **On ubuntu-latest and macos-latest the crate's own build path
contains no `unsafe`.** Default features: the crate declares no `[features]` table at all,
so there are none to enable or disable; `uv` nonetheless passes
`default-features = false`, which is a no-op. **Async coupling: none** — neither
`cfg-if` nor `windows-sys` is async, and no executor appears in the closure. Binary size and
compile time: qualitatively negligible — one proc-macro-free dependency (`cfg-if`, a
compile-time `macro_rules!` shim) and roughly 500 lines of source across five modules.
Maintenance state: **active** — commits on 2026-08-04 and 2025-11-08, a release 2025-10-28,
median first response 0.27 days, one unanswered issue from 2025-04.

#### System-tier resolver (custom, std)

##### Landscape
Bin: **built-in / first-party toolchain**. The candidate set for this slot is exactly two:
the `xdg` 3.0.0 crate (surveyed under the `etcetera` member) and `std`. No other crate in
the established or up-and-comer bins exposes `$XDG_CONFIG_DIRS` — verified by a
zero-match census of `etcetera` 0.11.0's source and by the single-`config_dir()` surfaces
of `directories` 6.0.0 and `dirs` 7.0.0.

##### Principles and implementation
Realizes rung 5 of C1 and the system half of C2. Mechanism, entirely `std`:
`std::env::var_os("XDG_CONFIG_DIRS")` → `std::env::split_paths` (platform-correct `PATH`
splitting, the same call `xdg-3.0.0/src/base_directories.rs:289` makes) → filter on
`Path::is_absolute` (the XDG spec's relative-path rule, quoted in
`### Principles and implementation`) → default to `["/etc/xdg"]` when the result is empty
(the spec's stated default) → append `rslbp/rslbp_config.toml` to each (R5.2's system form)
→ preserve order, first entry highest priority, and fold **last-to-first** into a
later-wins accumulation (the spec: "the first directory listed is the most important"; py
does the identical reversal at `core/config.py:135`).

##### Dominant choice
`inapplicable — this is a pattern member, not a crate.` The dominant *pattern* among
surveyed adopters is to hard-code a system path rather than enumerate `$XDG_CONFIG_DIRS`:
jj documents "`/etc/jj/config.toml`" and "`/etc/jj/conf.d/*.toml`" as its system tier
(jj `docs/config.md`, "System config files", 2026-09-17) with no mention of
`XDG_CONFIG_DIRS`. The template does **not** follow that, because R5.1 rung 5 says "each
`$XDG_CONFIG_DIRS/<tool>/<tool>_config.toml`" and is a `MUST`. jj's `/etc/jj` is the
`$XDG_CONFIG_DIRS` *default* with the variable ignored — a strict subset of the required
behaviour.

##### Qualified shortlist
`xdg` 3.0.0, figures and rejection reasons under the `etcetera` member's
*Qualified shortlist*.

##### Excluded by gate
None. The `std` implementation passes every gate trivially and `xdg` 3.0.0 fails none —
its rejection is architectural, and recording it as an exclusion would misstate why.
Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`.

##### Up-and-comers
None. No crate published in this space since `xdg` 3.0.0 (2025-05-04) addresses the
system tier.

##### Fit for this template
CLI: the system tier is meaningful (a machine administrator's defaults). Library: the
resolver is a pure function of an injected environment view, so it is testable without
touching the real process environment — which matters because `std::env::set_var` is
`unsafe` under edition 2024. Web service: unused. On macOS, `$XDG_CONFIG_DIRS` is not a
native concept and will usually be unset, so the tier resolves to `/etc/xdg` and the file
will normally be absent — which AC8 makes silent, not an error.

##### Recommendation
Hand-roll it on `std`. Approximately eight lines; no dependency.

##### Ranked runner-up
`xdg` 3.0.0's `BaseDirectories::get_config_dirs()` / `find_config_files()`.

##### Tradeoffs
Gains: one authority for `XDG_CONFIG_HOME` (etcetera's), no Unix-only `#![cfg]` in the
tree, no new dependency, and a Windows widening path that is a `#[cfg]` arm rather than an
empty crate. Costs: the template owns eight lines of spec-sensitive code, so the XDG
spec's reading must be pinned by tests rather than delegated; and the ordering inversion
(first-listed wins, folded last-first) is exactly the kind of detail a future edit can
silently reverse — AC2 exists to catch that.

##### Parameters
`assumes target-os-matrix = ubuntu-latest, macos-latest`; `assumes rust-edition = 2024`;
`assumes msrv-policy = stable minus 2 minor versions…` — `std::env::split_paths`,
`var_os` and `Path::is_absolute` are all long-stable and far below any plausible floor.
Crate figures are `inapplicable — no crate is added by this member`. No `CONFLICT:` line.

##### Migration implications
One new module in the CLI binary crate (or in a template-internal `config` module the
composition root calls), roughly eight lines plus its tests.

##### Validation strategy
Planned: AC2 (two entries, first wins); a case with `XDG_CONFIG_DIRS` unset asserting the
`/etc/xdg` default; a case with a relative entry (`XDG_CONFIG_DIRS=rel:/abs`) asserting the
relative entry is dropped and `/abs` kept; a case with `XDG_CONFIG_DIRS=` asserting the
default is used. All four inject the environment as a map rather than mutating the process.

##### Confidence & re-verify trigger
**High.** Re-verify if the XDG Base Directory Specification changes its
`$XDG_CONFIG_DIRS` default or its relative-path rule, or if the standard's R5.1 rung 5 is
revised.

##### Sources
XDG Base Directory Specification,
`https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml`
(retrieved 2026-09-17, HTTP 200, 15,498 bytes) — "All paths set in these environment
variables must be absolute…"; "If `$XDG_CONFIG_DIRS` is either not set or empty, a value
equal to `/etc/xdg` should be used"; "The order of base directories denotes their
importance; the first directory listed is the most important."
Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, R5.1
rung 5 and R5.3's "System-wide config search uses `$XDG_CONFIG_DIRS` (default
`/etc/xdg`)" (read 2026-09-17).
`xdg-3.0.0/src/base_directories.rs:288-298, 321-323, 725-731` and `src/lib.rs:1`, from
`https://static.crates.io/crates/xdg/xdg-3.0.0.crate` (retrieved 2026-09-17).
py `src/py_launch_blueprint/core/paths.py:108-128` and `core/config.py:135` at pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`.
jj `docs/config.md` ("System config files"),
`https://raw.githubusercontent.com/jj-vcs/jj/main/docs/config.md` (2026-09-17).

#### Project-tier bounded walk-up (custom, std)

##### Landscape
Bin: **built-in / first-party toolchain**, with **Cargo** as the first-party reference
design. No crate in any bin implements a bounded upward search for an arbitrary relative
path. Adjacent crates exist (`ignore`, `locate-cargo-manifest`) but solve different
problems — directory traversal and manifest location respectively; their dependency
closures were **not measured in this run**, so no size comparison is claimed.

##### Principles and implementation
Realizes rung 3 of C1 and the project half of C2. Mechanism: iterate
`std::path::Path::ancestors()` from the injected working directory; at each ancestor test
for `<ancestor>/.rslbp/rslbp_config.toml`; return the **first** hit (R5.1 says "nearest",
singular — one project layer, not Cargo's merged chain); stop after testing the first
ancestor that contains a boundary marker — `.git` (directory or file), or a `Cargo.toml`
carrying a `[workspace]` table — inclusive, so a repository-root `.rslbp/` is found, otherwise at the filesystem root.

##### Dominant choice
`inapplicable — this is a pattern member, not a crate.` The dominant *pattern* is
unambiguous and first-party: the Cargo Book documents the algorithm verbatim (quoted in
`### Principles and implementation`), and every surveyed adopter with a project tier —
ruff, uv, jj, helix — writes its own walk-up rather than importing one.

##### Qualified shortlist
`confique` 0.4.0 — 155,962 ninety-day / 487,226 all-time downloads
(`https://crates.io/api/v1/crates/confique`, 2026-09-17); 223 stars, `archived=false`,
`pushed_at` 2025-10-27T13:27:11Z (`https://api.github.com/repos/LukasKalbertodt/confique`,
2026-09-17). Shortlisted because its generated `Partial` type is precisely A3's shape and
it would remove hand-written fold code; **not chosen** because it does not implement
discovery at all — the caller still supplies the paths — so it replaces the easy half of
this item, and because adopting it would move R53's schema derivation under a second macro
crate that R53 did not choose.

##### Excluded by gate
None. Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`. `twelf` 0.15.0 is not
excluded by a gate either but is not shortlisted: 37,057 ninety-day downloads, last release
2024-03-11T09:39:05Z, `pushed_at` 2024-05-27T06:09:57Z (endpoints as above, 2026-09-17) —
a two-year quiet period with no maintainer notice, giving **stable-quiet at best and no
positive signal**, against a crate whose whole function the template can write in six
lines.

##### Up-and-comers
`ortho_config` 0.9.0 — 20,223 ninety-day / 30,209 all-time downloads; **0 GitHub stars**,
`pushed_at` 2026-09-16T21:58:21Z, licence `ISC`
(`https://api.github.com/repos/leynos/ortho-config`, 2026-09-17). It targets exactly this
item's problem (CLI + env + file precedence) and is actively developed, but 0 stars and a
30k all-time download count are no adoption evidence at all. Recorded as a watch item, not
a candidate.

##### Fit for this template
CLI: the project tier is the highest-value tier for a developer tool — it is what makes a
checkout carry its own settings. Library: pure function over an injected cwd; no process
state. Web service: unused. The boundary stop matters here specifically because
`rs-launch-blueprint` **is** a Cargo workspace: the walk must not escape into a developer's
home directory, and it must not stop early at a *member* crate's `Cargo.toml` — see the
marker rule and AC7b in `### Principles and implementation`.

##### Recommendation
Hand-roll it on `std::path::Path::ancestors()`. Approximately six lines; no dependency.

##### Ranked runner-up
`confique` 0.4.0, for the fold rather than the discovery — and only if R53 is reopened.

##### Tradeoffs
Gains: matches the first-party reference design; no dependency; the boundary rule is
explicit and testable. Costs: the template owns the loop; and the deliberate divergences
from Cargo (nearest-only rather than all-ancestors, bounded rather than root-walking) will
surprise a reader who expects Cargo semantics, so the doc comment must state both — which
R5.1's "MUST document the strategy clearly" requires anyway.

##### Parameters
`assumes rust-edition = 2024`; `assumes msrv-policy = stable minus 2 minor versions…`
(`Path::ancestors` is long-stable); `assumes target-os-matrix = ubuntu-latest,
macos-latest`. Crate figures `inapplicable — no crate is added by this member`. No
`CONFLICT:` line.

##### Migration implications
One function beside the system-tier resolver, roughly six lines plus tests; and the
template ships a `.rslbp/rslbp_config.toml` example (or documents its absence) so the tier
is visible to a user who reads the repository.

##### Validation strategy
Planned: AC7b first, because it is the regression test for the marker defect described in
`### Principles and implementation` — a workspace tree with a member crate's own
`Cargo.toml` between the cwd and the root file, asserting the root file is still found.
Then AC7 in two halves — a `tempfile` tree `root/.rslbp/rslbp_config.toml` + `root/a/b/`
with cwd at `b` finds the root file; the same tree with `root/a/.git` present does **not**
find it, because the walk stops at `a`. `.git` is exercised both as a directory and as a
file. A third case places a file in both
`root/a/.rslbp/` and `root/.rslbp/` and asserts only the nearer one is read (nearest-wins,
not merged).

##### Confidence & re-verify trigger
**High** on the mechanism, **medium** on the boundary-marker list — R5.2 calls its list
"a non-exhaustive baseline", so P03 may need to extend `.git`/`Cargo.toml`. Re-verify if
R5.2's boundary sentence changes or if the owner adds a marker.

##### Sources
The Cargo Book, "Configuration", `https://doc.rust-lang.org/cargo/reference/config.html`
(retrieved 2026-09-17, HTTP 200, 103,191 bytes) — the `.cargo/config.toml` probe list,
"looks for configuration files in the current directory and all parent directories", and
the deeper-wins/arrays-join merge paragraph.
Org CLI Design Standard v1.4.14, blob `f9de0437…`, R5.1 rung 3 and R5.2's boundary
sentence (read 2026-09-17).
py `src/py_launch_blueprint/core/paths.py:184-191` at pin `b08bccfb` (the cwd-only,
dotfile-preferring shape this member departs from — see `BASELINE-REVIEW: F232`).
`https://crates.io/api/v1/crates/confique`, `/twelf`, `/ortho_config` and the matching
`https://api.github.com/repos/…` records (2026-09-17).

#### clap (env feature) — the RSLBP_CONFIG alias

##### Landscape
Bin: **established industry standard**. `clap` is already the template's parser by R60's
owner-reviewed decision (`clap = { version = "4.6.6", features = ["derive", "env",
"wrap_help"] }`), and the `env` feature is already in that set. This member decides only
how F234's alias is wired, not whether `clap` is used.

##### Principles and implementation
Realizes C5 and rung 2 of C1. `Arg::env` (`clap_builder-4.6.6/src/builder/arg.rs:2205-2211`)
snapshots `env::var_os(name)` into `Option<OsString>`; the parser
(`src/parser/parser.rs:1417-1426`) applies it **only when the argument is absent from
argv** (`if matcher.contains(&arg.id) { continue; }`), which is R5.1's flag-beats-env rung
with no custom code, and then tests **presence only** — there is no emptiness filter on
that path. So `RSLBP_CONFIG=` becomes `--config ""`. F242 requires the opposite. The
template therefore adds one explicit filter: treat an empty `RSLBP_CONFIG` as unset and
fall through to discovery. Beyond that no custom precedence logic is needed, because
F233/R5.2 keep `--config` out of layering entirely — it selects a path list, it does not
add a layer.

##### Dominant choice
Yes. `clap` 4.6.7: 229,745,692 ninety-day / 1,138,667,633 all-time downloads
(`https://crates.io/api/v1/crates/clap`, 2026-09-17); it is the ecosystem's default
argument parser and was independently selected by R60.

##### Qualified shortlist
`inapplicable — the parser is fixed by R60 (owner-reviewed), so this member has no
alternative parser to shortlist.` The only real alternative for the alias itself is a
direct `std::env::var_os("RSLBP_CONFIG")` read in the composition root, which is strictly
more code for the same result and loses clap's `ValueSource::EnvVariable` provenance and
its automatic `--help` mention of the variable.

##### Excluded by gate
None. Gate 1 `inapplicable — owner ruling 2026-09-12 (Q7.B)`; gates 2–6 were answered for
`clap` 4.6.6 by R60 and are not re-litigated here.

##### Up-and-comers
None relevant; R60 surveyed the parser field.

##### Fit for this template
CLI only. The library crate and the web crate depend on no part of `clap` (R60's decision),
so the alias exists only on the CLI path; a web process reads `RSLBP_*` variables through
R77's mechanism, not through `clap`.

##### Recommendation
Declare `#[arg(long = "config", env = "RSLBP_CONFIG", value_name = "PATH")]` on the global
option, and apply one post-parse emptiness filter (`Option<PathBuf>` → `None` when the
value is empty) before the loader builds its path list.

##### Ranked runner-up
A direct `std::env::var_os("RSLBP_CONFIG")` read in the composition root.

##### Tradeoffs
Gains: flag-beats-env for free and correct; the variable is documented in `--help`
automatically, which R5.4's curated-subset rule wants; provenance is recorded for a future
R5.7 `--show-origin`. Costs: exactly one behaviour must be corrected in template code
(empty is not unset), and it is invisible unless tested — AC5's third clause exists for it.

##### Parameters
`assumes error-taxonomy-exit-codes = …` (R67) — an explicit path that is present but
unreadable or unparsable maps to `RSLB104`/1 and `RSLB202`/2 respectively, which **R55
already assigned**; R54 introduces no new failure and needs no new code. `assumes` the
four fixed parameters as for the other members. No `CONFLICT:` line.

##### Migration implications
One attribute on the existing global `--config` option in the CLI crate's derive struct,
plus the emptiness filter in the composition root. No `Cargo.toml` change — `env` is
already in R60's feature set.

##### Validation strategy
Planned: AC5 in three parts — `RSLBP_CONFIG=<path>` alone selects the explicit file;
`--config <other>` together with `RSLBP_CONFIG=<path>` selects `<other>`; `RSLBP_CONFIG=`
runs normal discovery. The third is the regression test for clap's presence-only check and
must be written even though it looks redundant.

##### Confidence & re-verify trigger
**High** — read from `clap_builder` 4.6.6's own source. Re-verify if clap changes
`add_env`'s `if let Some((_, Some(ref val))) = arg.env` to filter empty values (which would
make the template's filter redundant but harmless), or if R60's feature set changes.

##### Sources
`clap_builder-4.6.6/src/builder/arg.rs:2205-2211` and `src/parser/parser.rs:1417-1431`,
from `https://static.crates.io/crates/clap_builder/clap_builder-4.6.6.crate` (retrieved
2026-09-17).
`https://crates.io/api/v1/crates/clap` (2026-09-17): `recent_downloads=229745692`,
`downloads=1138667633`, `max_stable_version=4.6.7`.
Org CLI Design Standard v1.4.14, blob `f9de0437…`, R5.4 (`ACME_CONFIG` in the curated
subset) and R5.2 (`--config` replaces discovery), read 2026-09-17.
py `src/py_launch_blueprint/cli/options.py:103,107` (`"--config"`, `envvar="PLBP_CONFIG"`)
at pin `b08bccfb`; py `core/config.py:28` documents the same pair.
Ledger rows F233 (`COMMON → REUSE`), F234, F242 (`COMMON → REUSE`),
`docs/port/COMMONALITY.md:237-238,246`.

### Compatibility

The four members are proven together by **shared adopters at the exact versions**, not by
a constructed matrix.

Every cell below was produced by `/usr/bin/grep` run by absolute path over the manifest or
documentation file named in its Evidence column, fetched 2026-09-17. Cells that were not
verified say so rather than carrying an unsourced "yes".

| Project | `etcetera` | `clap` | `toml` (R52) | Layering crate | Multi-tier discovery | Evidence (all retrieved 2026-09-17) |
|---|---|---|---|---|---|---|
| **jj (jujutsu)** | `0.11.0` (`Cargo.toml:60`) | `4.6.1` (`:39`) | `1.1.0` (`:131`), `toml_edit` `0.25.12` (`:132`) | **none** | **yes — six documented tiers**: defaults → `/etc/jj` system → XDG user (`$XDG_CONFIG_HOME` on Linux *and* macOS) → repo → workspace → CLI, plus `JJ_CONFIG` and `--config-file` | `Cargo.toml`; `docs/config.md:15-21` and §"User config files", §"System config files" |
| **uv** | `0.11.0` (`:158`) | `4.5.17` (`:131`) | `1.1.0` (`:311`), `toml_edit` `0.25.8` (`:318`) | **none** | **yes — project (nearest parent) → user → system, with `$XDG_CONFIG_DIRS` named explicitly**, env above files, CLI above env, and `--config-file` replacing all discovered files | `Cargo.toml`; `docs/concepts/configuration-files.md:3-6,44-72` |
| **ruff** | `0.11.0` (`:99`) | `4.5.3` (`:82`) | `1.0.0` (`:198`) | **none** | **yes — "closest" config in the directory hierarchy, with a user-level fallback resolved "via `etcetera`'s base strategy"**, and a direct `--config` that applies to all files | `Cargo.toml`; `docs/configuration.md:252-271` |
| **helix** | `0.11` (`:58`) | **no `clap` dependency at all** (`/usr/bin/grep -n -i clap helix/Cargo.toml` → no match) | `1.1` (`:54`) | **none** | **yes — `.helix/` project dir merged with the config dir and the built-in config** | `Cargo.toml`, `helix-loader/Cargo.toml:22-23`; `book/src/configuration.md:3-6,29,33-34` |
| **bat** | `0.11.0`, optional (`:67`, feature at `:29`) | yes — `[dependencies.clap]` (`:89`), plus `[build-dependencies.clap]` (`:125`) | `1.1.1` (`:122`) | **none** | **not verified in this run** — no bat documentation was read; no tier count is claimed | `Cargo.toml` |
| **starship** | — (uses `dirs = "7.0.0"`, `:41`) | `4.6.6` (`:38`) | `1.1.6` (`:88`), `toml_edit` `0.25.15` (`:89`) | **none** | **not verified in this run** | `Cargo.toml` |

The "Layering crate" column is the census result: `/usr/bin/grep -n -E
'^(config|figment|confique|twelf|ortho_config|confy)[ =]'` over all six fetched manifests
returned **zero matches**, with no output filtering.

**uv and jj are the compatibility proof, and uv is the stronger of the two.** Each ships
`etcetera` 0.11.0, `clap` 4.x and `toml` 1.1.x in one binary, with a hand-rolled multi-tier
chain and an explicit config-file override, on Linux and macOS, and neither depends on any
layering crate. uv goes further than jj in the one place that matters most here: its own
documentation names `$XDG_CONFIG_DIRS/uv/uv.toml` as a system-level source, which
`etcetera` 0.11.0 provably cannot supply — so uv is shipping, in production, exactly the
`etcetera`-plus-hand-rolled-system-tier composition this item recommends. That is this
item's recommended stack running in a well-regarded project. It differs from the recommendation in exactly two
documented places — its system tier is a fixed `/etc/jj` rather than `$XDG_CONFIG_DIRS`,
and `JJ_CONFIG=` (empty) means "load nothing" where F242 makes empty mean "unset" — and
both differences are the template following its own standard where jj follows its own
product decision.

The version compatibility surface is trivially small because the members do not interact
at the type level: `etcetera` yields a `PathBuf`, the two `std` resolvers yield `PathBuf`s,
`clap` yields an `Option<PathBuf>`, and R52's `toml` consumes a `&str`. There is no shared
trait, no shared error type and no feature-unification risk between them.

### Parameters

R54 owns no parameter in `docs/port/PARAMETERS.md` (the registry's `owns` column for R54
is `—`, and `research/CLAUDE.md`'s R54 row likewise).

- `assumes rust-edition = 2024` (fixed, owner 2026-09-02). Load-bearing: it makes
  `std::env::set_var` `unsafe`, which forces the injected-environment design in AC6/AC10
  rather than in-test mutation.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (fixed). `etcetera` 0.11.0 declares `rust-version = "1.87.0"`; every other mechanism is `std`.
- `assumes license = MIT OR Apache-2.0` (fixed). Gate 1 is `inapplicable — owner ruling 2026-09-12 (Q7.B)`; `etcetera`'s metadata happens to be `MIT OR Apache-2.0`.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (fixed). Load-bearing twice: it is why `choose_base_strategy()`'s macOS→XDG arm is required (F247), and why `xdg` 3.0.0's Unix-only `#![cfg]` is not a gate failure.
- `assumes error-taxonomy-exit-codes = …` (R67, owner-accepted). R54 needs three of R67's rows and introduces none: `RSLB104` config layer unreadable → 1, `RSLB202` config document unparsable → 2, `RSLB203` config value invalid → 2. R55 has already bound those to the explicit/discovered distinction; R54's tier set supplies the "discovered" side and nothing more. A file that is simply **absent** from a discovered tier is not a failure at all and consumes no code — R55 clause 1, and AC8.
- `assumes http-transport-injection-seam`, `build-tool-output-shape`: not consumed.

**No `CONFLICT:` line.** Every failure this item's tiers can produce is expressible in
R67's published catalog.

Sibling couplings stated, not decided:
- **R52** (`toml` 1.1.6 + `toml_edit` 0.25.15, owner-accepted): R54 parses each discovered layer with `toml`, and `config set` writes through `toml_edit` to the **user** tier — `Paths::config_dir()/rslbp_config.toml` — which is py's write target (`core/config.py:131-133`, `target = paths.config_file()`). R54 does not change R52's crates or features.
- **R53** (`serde` only, per-key loop): R54's fold operates on R53's type. The constraint R54 adds, for R53 to absorb or refuse, is that the partial type must be **recursively** partial (nested tables `Option<PartialSub>` with `Option` fields) so that R5.1's recursive-table `MUST` holds. R54 does not choose R53's crate.
- **R55** (provenance-aware two-phase loader): R54 supplies the "discovered" tiers that R55's clause-2 warning branch applies to. R55's own text says "if R54 adopts none, this clause has no target and F236 has no Rust instance" — **R54 adopts three, so F236 has three Rust instances.**
- **R57** (XDG via `etcetera` on a template-owned `Paths`, owner-accepted): R54 consumes `Paths::config_dir()`. **R54's system tier needs something R57's four accessors do not provide** — a `config_dirs() -> Vec<PathBuf>` for `$XDG_CONFIG_DIRS`. Two dispositions are available and **R57 owns the choice**: (a) R57 adds a fifth accessor to `Paths`, keeping one directory authority; or (b) R54 owns a separate discovery type that *takes* a `Paths` and resolves the system list itself. This report proposes (a) on the single-authority argument, and records it as a coupling rather than a decision. Either way `etcetera` remains R57's dependency, declared once.

### Migration implications

File-level changes in the template (which does not yet exist; P03 creates these):

| File | Change |
|---|---|
| `Cargo.toml` (CLI binary crate) | **No new dependency.** `etcetera` arrives via R57; `clap` with `env` via R60; `toml`/`serde` via R52/R53. |
| new `src/config/discovery.rs` (CLI crate, or a template-internal module the composition root calls) | The three resolvers: `system_config_files(env) -> Vec<PathBuf>` (~8 lines), `user_config_file(paths) -> PathBuf` (1 line over R57's `Paths`), `project_config_file(cwd) -> Option<PathBuf>` (~6 lines over `Path::ancestors`). Plus `layer_paths(explicit: Option<&Path>, …) -> Vec<PathBuf>` implementing F233's collapse. All take injected inputs; none reads the process environment directly. |
| new `src/config/merge.rs` | The field-wise fold over R53's recursively-partial type, and the documented merge rule (tables recurse, scalars replace, arrays replace) as a doc comment the tests pin. |
| `src/cli/args.rs` (or R60's derive struct) | `#[arg(long = "config", env = "RSLBP_CONFIG", value_name = "PATH")]` on the global option; one emptiness filter where it is consumed. |
| R57's `Paths` type | **Proposed** fifth accessor `config_dirs() -> Vec<PathBuf>` — R57's call, see `### Parameters`. |
| `docs/` (R81's surface) and `--help` | The six-rung chain reproduced **verbatim** from R5.1, with a test that byte-compares it (AC9), because R5.1 says "MUST document it verbatim". |
| `.rslbp/rslbp_config.toml` (repository root) | A committed example project-tier file, or a documented statement that the template ships none — otherwise rung 3 is invisible to a reader of the repository. |
| `tests/` | The ten acceptance criteria, all hermetic via injected environment and `tempfile` trees. |

### Validation strategy

**Nothing in this section was executed.** No Rust code exists in `rs-launch-blueprint` and
none was written; the only code touched in this run was published crate source extracted
into a `$TMPDIR` subdirectory for reading and deleted afterwards. Every command below is a
**planned** check for P03.

```bash
# Planned — P03, from the template root.
cargo test -p rslbp --test config_discovery       # AC1, AC2, AC3, AC7, AC8
cargo test -p rslbp --test config_explicit        # AC4, AC5
cargo test -p rslbp --test xdg_override           # AC6, on both runners
cargo test -p rslbp --test precedence_doc         # AC9 (byte-compare against R5.1)
cargo test -p rslbp-lib --test no_ambient_io      # AC10
```

Expected behaviour, stated so a failure is diagnosable rather than merely red:

- `config_discovery` builds a `tempfile::TempDir` holding a fake `$XDG_CONFIG_DIRS` pair, a fake `$XDG_CONFIG_HOME`, and a project tree with `.rslbp/rslbp_config.toml` behind a `.git` boundary. It asserts project > user > `$XDG_CONFIG_DIRS[0]` > `$XDG_CONFIG_DIRS[1]` > defaults, that a nested `[table]` merges key-wise while an array replaces, and that deleting any layer file changes nothing but that layer's contribution and prints nothing.
- `config_explicit` asserts that `--config <path>` makes a key set **only** in the project file absent from the resolved config — the single most important negative assertion in this item, because a merge-based implementation would silently keep it.
- `xdg_override` runs on `ubuntu-latest` and `macos-latest` and is the F247 gate: absolute honoured, empty ignored, relative ignored, on both.
- `precedence_doc` is the guard against documentation drift on a `MUST`.
- `no_ambient_io` is the guard against the library crate acquiring an environment read, which would break the injection design and R57's JF-4 finding.

The two checks that are **executed and reproducible today**, because they validate this
report rather than the template:

```bash
# Executed 2026-09-17 in this run; reproducible.
curl -sSL https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml \
  | /usr/bin/grep -c "must be absolute"          # → 1 (the spec's relative-path rule)
/usr/bin/grep -rn "CONFIG_DIRS" etcetera-0.11.0/src   # → no matches (the decisive finding)
```

### Confidence & re-verify trigger

**High** on the tier set and precedence — they are `MUST` clauses of a pinned standard
blob, not a judgement. **High** on the mechanism findings (etcetera has no system tier;
clap does not filter empty env values; py does not walk up) — each is a line citation into
source read at an exact version or pin, and each is independently reproducible by the
commands above. **Medium** on the recommendation to hand-roll rather than adopt `xdg`
3.0.0: the crate is correct and the argument against it is architectural (single authority
for `XDG_CONFIG_HOME`, Windows-widening path) rather than empirical, and a reasonable owner
could weigh it the other way. **Medium** on the boundary-marker rule: R5.2 calls its list non-exhaustive and delegates,
and the `[workspace]`-qualified `Cargo.toml` rule is this report's reasoning about a defect
it found in the obvious reading, not a quotation from any source. It is the finding in this
report most likely to need adjustment in P03, and AC7b is what would catch it.

Re-verify if any of these changes:

1. The org CLI Design Standard moves past blob `f9de0437` (v1.4.14) in §5 — the whole tier
   set is downstream of R5.1/R5.2.
2. `etcetera` releases past 0.11.0 — HEAD already carries `Drop cfg-if dependency (#43)`
   (2026-08-04T20:53:17Z, unreleased as of 2026-09-17), and a 0.12/1.0 could add or remove
   the strategy dispatch this item depends on.
3. R57 declines disposition (a) for the `config_dirs()` accessor, which changes where the
   system-tier code lives (not what it does).
4. R53 declines the recursively-partial constraint, which would break R5.1's recursive
   table merge and force a re-comparison of A2 against A3.
5. `clap` adds an emptiness filter to `Parser::add_env`, making the template's filter
   redundant.
6. The owner rules on the two `BASELINE-REVIEW:` lines — F232 (walk-up and dot-directory
   versus py's cwd-only dotfile) and F247 (absoluteness as a requirement).

### Sources

**Binding standard.** Org CLI Design Standard v1.4.14, blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read 2026-09-17 via
`git -C /Users/stevemorin/c/cli-standards cat-file blob f9de0437baece3383e73ca2c5f48b7ab399b51c7`:
R5.1 (precedence chain and merge semantics, `MUST`), R5.2 (format, filenames, walk-up,
boundary stop, `--config` replacement), R5.3 (XDG locations and the `$XDG_CONFIG_DIRS`
default), R5.4 (`TOOL_*` curated subset including the config path), R5.7 (`config view
--show-origin`, `SHOULD`, not adopted), plus the Appendix C checklist line naming
`.<tool>/<tool>_config.toml`.

**Specifications.** XDG Base Directory Specification,
`https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml`
(retrieved 2026-09-17, HTTP 200, 15,498 bytes).

**Rust project publications.** The Cargo Book, "Configuration",
`https://doc.rust-lang.org/cargo/reference/config.html` (retrieved 2026-09-17, HTTP 200,
103,191 bytes).

**Crate sources read at exact versions**, each downloaded from `https://static.crates.io/crates/<name>/<name>-<version>.crate` on 2026-09-17 and extracted locally:
`etcetera-0.11.0` (`src/lib.rs:57`, `src/base_strategy.rs:7-32,47,53-60`,
`src/base_strategy/xdg.rs:163,175-183,184-187,194-196`, `Cargo.toml`);
`xdg-3.0.0` (`src/lib.rs:1`, `src/base_directories.rs:279-286,288-298,321-323,725-731`,
`Cargo.toml`); `config-0.15.20` (`Cargo.toml:85-112` features, `:158-214` dependency
list); `figment-0.10.19` (`Cargo.toml:75-102` dependencies, `:122-133` features — note
**no `default` feature key**); `clap_builder-4.6.6`
(`src/builder/arg.rs:2205-2211`, `src/parser/parser.rs:1417-1431`).

**Registry figures**, `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `GET …/versions` (newest `yanked: false`), all 2026-09-17:

| Crate | 90-day | All-time | Latest unyanked | Created | `rust_version` | Licence |
|---|---|---|---|---|---|---|
| `etcetera` | 32,829,812 | 108,370,946 | 0.11.0 | 2025-10-28T13:28:11Z | 1.87.0 | MIT OR Apache-2.0 |
| `xdg` | 3,767,479 | 22,571,181 | 3.0.0 | 2025-05-04T10:42:18Z | 1.60.0 | Apache-2.0 OR MIT |
| `config` | 18,162,896 | 113,759,215 | 0.15.25 | 2026-06-26T17:42:54Z | 1.85.0 | MIT OR Apache-2.0 |
| `figment` | 9,802,644 | 38,332,059 | 0.10.19 | 2024-05-17T02:54:57Z | (none declared) | MIT OR Apache-2.0 |
| `directories` | 12,362,480 | 70,443,494 | 6.0.0 | 2025-01-12T17:19:05Z | (none declared) | MIT OR Apache-2.0 |
| `dirs` | 77,979,289 | 329,160,353 | 7.0.0 | — | — | — |
| `confique` | 155,962 | 487,226 | 0.4.0 | — | — | — |
| `twelf` | 37,057 | 349,380 | 0.15.0 | — | — | — |
| `ortho_config` | 20,223 | 30,209 | 0.9.0 | — | — | — |
| `confy` | 254,553 | 2,796,150 | 2.0.0 | — | — | — |
| `toml` | 217,379,722 | 912,258,028 | 1.1.6+spec-1.1.0 | — | — | — |
| `clap` | 229,745,692 | 1,138,667,633 | 4.6.7 | — | — | — |

**Repository figures**, `GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, all 2026-09-17:

| Repo | Stars | Archived | `pushed_at` | Open issues | Maintenance verdict |
|---|---|---|---|---|---|
| `lunacookies/etcetera` | 150 | false | 2026-08-04T20:53:17Z | 2 | **active** |
| `whitequark/rust-xdg` | 197 | false | 2025-05-04T10:42:14Z | 4 | **stable-quiet** — 16 months since the last push is a trigger, not a verdict; no unpatched advisory, no maintainer notice, and the crate's surface is a frozen specification, so quiet is the expected state |
| `soc/directories-rs` | 837 | **true** | 2025-01-12T19:35:58Z | (not queried) | **archived** — the `archived` field is the verdict |
| `rust-cli/config-rs` | 3,210 | false | 2026-09-15T17:13:57Z | 110 | **active** |
| `SergioBenitez/Figment` | 913 | false | 2024-09-13T04:51:49Z | 21 | **stable-quiet** — no release since 2024-05-17 and no push since 2024-09-13, both triggers; not `at-risk`, because `at-risk` needs a concrete signal and none was found (no unpatched advisory, no maintainer notice, and it remains Rocket's config layer) |
| `LukasKalbertodt/confique` | 223 | false | 2025-10-27T13:27:11Z | (not queried) | **active** |
| `bnjjj/twelf` | 122 | false | 2024-05-27T06:09:57Z | (not queried) | **stable-quiet** — two triggers, no concrete at-risk signal found |
| `leynos/ortho-config` | 0 | false | 2026-09-16T21:58:21Z | (not queried) | **active**, but with no adoption evidence |
| `rust-cli/confy` | 1,041 | false | 2026-04-13T12:46:24Z | (not queried) | **active** |

**Advisories.** `https://rustsec.org/packages/etcetera.html`, `/xdg.html`, `/config.html`
and `/figment.html` each returned **HTTP 404** on 2026-09-17. RustSec publishes a package
page only where an advisory exists, so 404 is the no-open-advisory result for all four.

**Adopter documentation**, fetched raw on 2026-09-17, used for every multi-tier claim:
`https://raw.githubusercontent.com/astral-sh/uv/main/docs/concepts/configuration-files.md`
(HTTP 200) — the project/user/system chain, `$XDG_CONFIG_DIRS`, env-over-files,
CLI-over-env, `--config-file` replacement and the array-concatenation deviation;
`https://raw.githubusercontent.com/astral-sh/ruff/main/docs/configuration.md`
(HTTP 200, 31,240 bytes) — hierarchical "closest" config and the
"`${config_dir}` … determined via `etcetera`'s base strategy" user fallback;
`https://raw.githubusercontent.com/helix-editor/helix/master/book/src/configuration.md`
(HTTP 200) — `.helix/` project config "merged with the configuration directory and the
built-in configuration"; `https://raw.githubusercontent.com/jj-vcs/jj/main/docs/config.md`
(HTTP 200, 87,486 bytes). `https://raw.githubusercontent.com/sharkdp/bat/master/CHANGELOG.md`
(HTTP 200, 65,162 bytes) was fetched to test the widely repeated `dirs` → `etcetera`
migration claim and **mentions neither crate**, so that claim is not made in this report.
`https://raw.githubusercontent.com/astral-sh/uv/main/docs/configuration/files.md` returned
**HTTP 404**; the correct path is the `docs/concepts/` one above.

**Adopter manifests**, fetched raw on 2026-09-17:
`https://raw.githubusercontent.com/helix-editor/helix/master/Cargo.toml` and
`.../helix-loader/Cargo.toml`;
`https://raw.githubusercontent.com/astral-sh/ruff/main/Cargo.toml`;
`https://raw.githubusercontent.com/astral-sh/uv/main/Cargo.toml`;
`https://raw.githubusercontent.com/sharkdp/bat/master/Cargo.toml`;
`https://raw.githubusercontent.com/jj-vcs/jj/main/Cargo.toml`;
`https://raw.githubusercontent.com/starship/starship/master/Cargo.toml`.
Adopter documentation: `https://raw.githubusercontent.com/jj-vcs/jj/main/docs/config.md`
(HTTP 200, 87,486 bytes).

**Source repositories, read through their pins, never from a working tree.**
py at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` via
`git -C ~/c/py-launch-blueprint show b08bccfb:<path>`:
`src/py_launch_blueprint/core/paths.py:58` (`APP_NAME = "plbp"`), `:65-75` (`_xdg_override`,
non-empty **and** absolute), `:108-128` (`config_dirs()`, `$XDG_CONFIG_DIRS` split,
non-absolute filtered, `/etc/xdg` default, "highest-precedence first"), `:171`
(`CONFIG_FILENAME`), `:179-181` (`system_config_files()`), `:184-191`
(`project_config_file()` — **cwd only, dotfile preferred, no walk-up**);
`src/py_launch_blueprint/core/config.py:28`, `:107-121` (`_read_explicit` — a missing
explicit file is fine, an unparsable one raises), `:124-139` (`_discovery_paths`, with
`*reversed(paths.system_config_files())` at `:135`);
`src/py_launch_blueprint/cli/options.py:103,107` (`"--config"`, `envvar="PLBP_CONFIG"`).
ts at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00` via
`git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>`: `src/lib/xdg-paths.ts` in full —
`TOOL_DIR_NAME = 'ts-projects'`, `configDir(env, homedir)` honouring `XDG_CONFIG_HOME` when
"not undefined and not `''`" (**no absoluteness check**, the gap this report's F247 review
names), `~/.config/<tool>` on all platforms, and the header comment recording D-017(3)'s
"hand-rolled ~30 lines" — **no system tier, no project tier, no env alias**.

**Repository documents.** `docs/port/COMMONALITY.md:234-238` (F230, F231, F232, F233,
F234), `:246` (F242), `:251` (F247); `docs/port/BASELINE-REVIEW.md:107` (F233), `:113`
(F247, "blocked pending R54"), `:152` (the F247 review line), `:179` (the F247 citation
correction); `docs/port/PARAMETERS.md` (the four fixed parameters and
`error-taxonomy-exit-codes`); `research/topics/67-error-and-exit-code-contract/DECISION.md`
(revision 4, the catalog rows R54 consumes); `research/topics/52-toml-crate/DECISION.md`
(revision 1, `## Decision`); `research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md`
(revision 2, `## Decision`); `research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md`
(revision 1, `## Decision`, clauses 1–3); `research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md`
(revision 2, `## Decision` and finding JF-4); `research/topics/60-cli-parsing-framework/DECISION.md`
(`## Decision`, the clap version and feature set).

**Method notes.** Endpoints queried in this run: `https://crates.io/api/v1/crates/<name>`
and `/versions` for `etcetera`, `xdg`, `directories`, `dirs`, `config`, `figment`,
`confique`, `twelf`, `ortho_config`, `confy`, `toml`, `serde`, `clap`, plus
`/crates/etcetera/owners`; `https://api.github.com/repos/<o>/<r>` for nine repositories and
`https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for four, through the
authenticated `gh api` (no token was printed or inspected);
`https://api.github.com/repos/lunacookies/etcetera/issues` and four `/issues/<n>/comments`
for the responsiveness figure; `https://rustsec.org/packages/<name>.html` for four crates;
`https://static.crates.io/crates/…` for five `.crate` archives; seven
`raw.githubusercontent.com` manifest URLs and one documentation URL; the XDG spec source on
`gitlab.freedesktop.org`; and `https://doc.rust-lang.org/cargo/reference/config.html`.
Counts reported above come from `/usr/bin/grep` invoked by absolute path over extracted
files, never from output passed through `head` or `cut`.

**What could not be verified, stated rather than inferred.**
(1) `https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html` no
longer serves spec text — it returns a 158-byte meta-refresh stub and the redirect target
`https://specifications.freedesktop.org/basedir/basedir-spec-latest.html` returned no
matching prose — so every XDG quotation comes from the DocBook source on
`gitlab.freedesktop.org` instead. The two should be reconciled before this report's XDG
citations are treated as the canonical URL.
(2) **Issue responsiveness was measured only for `etcetera`**, the one crate member R54
would add if R57 had not already added it. The prompt's rubric asks for the ten most
recently opened issues; a single `per_page=12` page of `lunacookies/etcetera`'s
issue-or-PR records contained only four non-PR issues, so the median rests on three
answered issues — a small sample, and one that did not page back far enough to prove ten
issues do not exist. Stated as such rather than rounded up. The
figure was **not** computed for `xdg`, `config`, `figment`, `confique`, `twelf`,
`ortho_config` or `confy`; for those, maintenance verdicts rest on release dates,
`pushed_at`, `archived` and open-issue counts only.
(3) **No CI badge or platform list was read** for any crate; gate 4 rests on the `#![cfg]`
attributes in the sources (decisive for `xdg` 3.0.0), on the `[target."cfg(windows)"]`
dependency partition in `etcetera`'s manifest, and on the adopter evidence that helix,
ruff, uv, bat and jj all ship `etcetera` on macOS and Linux.
(4) **Binary-size and compile-time costs are qualitative only.** No build was run and no
`cargo bloat`/`cargo build --timings` measurement was taken; the claims rest on dependency
closure size (`etcetera` → `cfg-if` alone on the target matrix) and on `config`'s declared
default feature set. No absolute "fastest" or "smallest" claim is made from unlike
benchmarks, and no latency, throughput or resource figure is reported, because none was
measured — the performance question is not load-bearing for this item, whose entire
runtime cost is a bounded number of `stat` calls at process start.
(5) **`figment`'s and `config`'s provenance capabilities were assessed from their manifests
and from the architecture of a merge-then-deserialize pipeline, not from a compiled
experiment.** The claim that A1 cannot give R55 per-leaf, per-file provenance after the
merge is an architectural argument, and P03 should falsify it with a ten-line `figment`
probe before the recommendation is treated as closed on that point.
(6) **Nothing in `### Validation strategy` was executed** beyond the two reproducible
verification commands explicitly marked as executed. No Rust was compiled in this run.
(7) `dirs` 7.0.0's repository is on `https://codeberg.org/dirs/dirs-rs`, so its GitHub
figures are `inapplicable — not hosted on GitHub`; only its crates.io figures are reported.
