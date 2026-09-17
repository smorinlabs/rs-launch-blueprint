# 2026-09-17 — R54 — config-discovery-tiers (bundle, Deep) — decision (revision 1)

## Decision

**Status.** This decision is a **proposal validated in the implementation phase**
(owner ruling, 2026-09-10). It records what the research found and what it
recommends; **P03 builds the template and its CI proves the recommendation.** No
Rust source exists in `rs-launch-blueprint` — it is still a research tree — so
nothing here is an implemented result. The one piece of Rust this synthesis
compiled is a throwaway probe built under `$TMPDIR` and deleted at the end of the
run (`## Empirical check`, check group `PR`); it tests the project-tier boundary
rule stated below and is not template code. `## Engines` lists what P03 must
validate. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for
every candidate named in this decision. Nothing is excluded on licence; licence
strings are reported as metadata only.

### The recommendation — one stack

**`rs-launch-blueprint` implements the org CLI Design Standard's six-rung
precedence chain with no layering crate and no new dependency: the user tier comes
from `etcetera` 0.11.0 *through R57's template-owned `Paths`*, the system and
project tiers are two small `std`-only resolvers the template owns, the
`RSLBP_CONFIG` alias is `clap` 4.6.6's `env` attribute plus one emptiness filter,
and the discovered layers compose by a recursive-table merge over the
per-layer-sanitized `toml::Table`s that R55's published loader already produces.**

| Rung | Tier | Location this template searches | Mechanism | Who owns the dependency |
|---|---|---|---|---|
| 1 | Flags | `argv` | `clap` 4.6.6 derive | R60 (owner-reviewed) |
| 2 | Environment | `RSLBP_*`, and `RSLBP_CONFIG` for the path | `clap` `env` feature **plus one emptiness filter** | R60 |
| 3 | Project | nearest `.rslbp/rslbp_config.toml`, walking up from the working directory, stopping *inclusively* at the first ancestor carrying a boundary marker | `std::path::Path::ancestors` — template code, ~10 lines | none added |
| 4 | User | `<Paths::config_dir()>/rslbp_config.toml` = `$XDG_CONFIG_HOME/rslbp/rslbp_config.toml` | `etcetera` 0.11.0 `choose_base_strategy()`, reached through R57's `Paths` | R57 (owner-accepted) |
| 5 | System | each `$XDG_CONFIG_DIRS` entry as `rslbp/rslbp_config.toml`; first entry highest; `/etc/xdg` when the variable is unset, empty, or yields no absolute entry | `std::env::var_os` + `std::env::split_paths` + `Path::is_absolute` — template code, ~10 lines | none added |
| 6 | Defaults | the `Default` impl on the finalized config type | `serde` | R53 |

Four decisions inside that table carry the weight, and they do not rest on the same
kind of evidence. They are separated so a reviewer can accept or reject them
independently.

| # | What is decided | Force | Ground |
|---|---|---|---|
| J1 | The tier set (three files) and the six-rung precedence order | **MUST, org-locked** — not a research finding | Org CLI Design Standard v1.4.14 `R5.1`, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, quoted verbatim below and asserted at `## Empirical check` `S01`–`S04` |
| J2 | `etcetera` 0.11.0 supplies rung 4, and R54 declares no dependency of its own for it | **Follows from an owner-accepted decision** | R57 selected it and states "This item supplies `config_dir()` as the single resolver so R54 does not resolve it a second time" (`D05`); `etcetera`'s macOS arm is what makes F247 satisfiable on `macos-latest` (`E03`) |
| J3 | Rung 5 is hand-rolled on `std` rather than taken from `xdg` 3.0.0 | **Recommended, not forced** — an architectural judgement a reasonable owner could weigh the other way | No crate in the recommended stack enumerates `$XDG_CONFIG_DIRS` at all (`E01`, `E05`); `xdg` 3.0.0 does it correctly (`X02`–`X04`) but is `#![cfg(any(unix, target_os = "redox"))]` (`X01`) and would put a second `XDG_CONFIG_HOME` resolver in the binary beside R57's |
| J4 | The project-tier boundary is `.git` always, plus a `Cargo.toml` **only when it declares a top-level `workspace` table** | **Recommended, and measured** — `R5.2` calls its marker list "a non-exhaustive baseline" and delegates the choice | `R5.2` (`S06`); the naive reading (any `Cargo.toml` stops) was **executed and shown to fail** on this template's own workspace shape — `## Empirical check` case `P2-any-cargo-toml-loses-root` |

**`--config` and `RSLBP_CONFIG` do not add a layer.** A non-empty explicit path
collapses rungs 3, 4 and 5 to that single file and leaves rungs 1, 2 and 6 intact.
That is F233 (`COMMON → REUSE`, already agreed, not this item's decision) and
`R5.2`'s `MUST` (`S05`). An empty `RSLBP_CONFIG` is **not** an explicit path: it is
unset, and ordinary discovery runs (F242).

**Ledger rows this settles.** **F230** (`docs/port/COMMONALITY.md:234`) — the
layered chain exists in Rust, with three file tiers, later-nearer wins. **F231**
(`:235`) — the system tier is `$XDG_CONFIG_DIRS`, resolved by template code, not by
a directory crate. **F232** (`:236`) — the project tier is an upward search for a
dot-*directory*, which is **not** the shape the row currently records; see the
`BASELINE-REVIEW:` line below. **F234** (`:238`) — the env alias is a plain `clap`
`env` attribute plus an emptiness filter. **F233** (`:237`) and **F242** (`:246`)
are inherited `COMMON → REUSE` rows, consumed and not re-litigated. **F247**
(`:251`) is not settled by this decision alone — it is a `COMMON → REUSE`
behavioural requirement whose acceptance criteria this item now carries (AC6), and
its open owner question is answered below as a proposal.

### Two `BASELINE-REVIEW:` findings, carried verbatim from `raw/opus.md`

Both are raised for the owner. Neither changes another item, the ledger, the index
or the registry, and this decision does not act as though either has been accepted.

> `BASELINE-REVIEW: F232 — project-local config discovery must be an upward search for a dot-*directory*, not a cwd-only dot-*file* — replace the row's parenthetical "(`./<tool>_config.toml`, dotfile preferred)" with the standard's `.<tool>/<tool>_config.toml` walked up from the working directory and stopped at a repository/workspace boundary, and record that the py shape the parenthetical describes is not adoptable — evidence: py `src/py_launch_blueprint/core/paths.py:184-191` at pin `b08bccfb` inspects only `Path.cwd()` and returns a dotfile, while org CLI Design Standard R5.1 rung 3 (`MUST`) and R5.2 (`SHOULD`) at blob `f9de0437` both specify the dot-directory form discovered "in the current directory and then each parent directory"; affected items R54 (this item, which must implement the standard) and R55 (whose F236 discovered-layer clause applies to whichever project file this tier names)`

**Disposition: accepted and acted on within this item's own scope.** Re-verified
independently here: `R5.1` rung 3 and `R5.2` carry the dot-directory walk-up
(`S02`, `S06`), and py's `project_config_file` contains no parent walk at the pin
(`Y01`, `Y02`). This decision therefore implements the standard's shape rather than
py's. The ledger edit the line asks for is the owner's to make; nothing in
`docs/port/COMMONALITY.md` was touched.

> `BASELINE-REVIEW: F247 — the absoluteness requirement is normative, not a py nuance — drop "py additionally requires absoluteness, a minor same-origin implementation nuance, not a verdict-changing difference" and record absoluteness as part of the acceptance criteria, closing the open owner question at `docs/port/BASELINE-REVIEW.md:113` in favour of "required" — evidence: the XDG Base Directory Specification states "All paths set in these environment variables must be absolute. If an implementation encounters a relative path in any of these variables it should consider the path invalid and ignore it" (`https://gitlab.freedesktop.org/xdg/xdg-specs/-/raw/master/basedir/basedir-spec.xml`, retrieved 2026-09-17), and `etcetera` 0.11.0 `src/base_strategy/xdg.rs:175-183` implements it, so adopting it costs nothing; affected items R54 (this item) and R57 (which owns the `Paths` type carrying the behaviour)`

**Disposition: accepted, and offered to the owner as the answer to the open
question at `docs/port/BASELINE-REVIEW.md:113`** — "whether py's absoluteness check
(`src/py_launch_blueprint/core/paths.py:73`) is part of the inherited contract or a
py-only nuance". Both halves were re-verified here: the specification sentence
(`Z01`) and `etcetera`'s implementation of it (`E02`). The reason this is a cheap
"yes" is that the template gets the behaviour **whether or not the owner rules**:
`etcetera` filters a non-absolute `XDG_CONFIG_HOME` unconditionally, and
`PathBuf::from("")` is not absolute, so the empty case F247 already requires and the
relative case py adds fall out of the same test. This decision's system-tier
resolver applies the same rule to each `$XDG_CONFIG_DIRS` entry, matching both the
specification and `xdg` 3.0.0 (`X04`). The consolidated question at
`docs/port/BASELINE-REVIEW.md:354` records the reviewer's recommendation to
"include it as an acceptance criterion in R54"; AC6 is that criterion. **It remains
the owner's ruling to make** — this item cannot close an owner question, and the
ledger note at `:251` is untouched.

### Principles and implementation

**The shared requirement.** A user must be able to put a setting at the scope that
matches their authority — the machine, their account, or the checkout they are
standing in — and the tool must resolve a conflict between scopes by one published,
deterministic rule with no silent tie.

**Its source and agreement level, and why py is not the source.** The prompt's
`## Context` offers py as precedent and the research mandate (spec §2, owner
amendment A5) makes it evidence rather than a winner. The actual source of the
requirement is the owner's own normative document, and it is binding rather than
weighable. Org CLI Design Standard v1.4.14, blob
`f9de0437baece3383e73ca2c5f48b7ab399b51c7`, read with
`git -C /Users/stevemorin/c/cli-standards cat-file blob f9de0437baece3383e73ca2c5f48b7ab399b51c7`
on 2026-09-17 (`S01`–`S09`):

> **R5.1 — Precedence chain. (MUST)**
> Configuration **MUST** resolve in this order, highest priority first, and the tool **MUST** document it verbatim:
>
> 1. Command-line flags
> 2. Environment variables (`TOOL_*`)
> 3. Project/local config file: nearest `.<tool>/<tool>_config.toml`, discovered by walking up from the working directory
> 4. User config file: `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`
> 5. System config file: each `$XDG_CONFIG_DIRS/<tool>/<tool>_config.toml`
> 6. Built-in defaults

and, on composition:

> Where more than one config file in the chain sets the same key, maps/tables **MUST** merge recursively by default. Scalar values replace scalar values, arrays **replace** arrays (not concatenate), and the nearer scope wins. A tool **MAY** use a different merge strategy (e.g., array concatenation, cargo-style) where its domain requires it, but **MUST** document the strategy clearly.

`R5.2` fixes the filenames, the boundary stop and the override semantics:

> The canonical discovered config filename **SHOULD** be `<tool>_config.toml` for findability: project/local discovery looks for `.<tool>/<tool>_config.toml` in the current directory and then each parent directory, user config is `$XDG_CONFIG_HOME/<tool>/<tool>_config.toml`, and system config is searched under each `$XDG_CONFIG_DIRS` entry as `<tool>/<tool>_config.toml`. Project discovery **SHOULD** stop at a repository/workspace boundary when detectable — for example a `.git` directory or a language/workspace root marker such as `Cargo.toml`, `go.mod`, `package.json`, or `pyproject.toml` (a non-exhaustive baseline) — otherwise at the filesystem root. An explicit `--config <path>` **MUST** **replace** the discovered project/user/system config files — it becomes the sole config file in the chain — while command-line flags and environment variables still layer above it and built-in defaults below it (R5.1). It does **not** merge with the files it overrides.

`R5.3` supplies the system default — "System-wide config search uses
`$XDG_CONFIG_DIRS` (default `/etc/xdg`)" (`S07`) — and `R5.4` settles F234 without
research: it names `ACME_CONFIG` in the curated environment subset (`S09`) while
requiring that "the tool **MUST NOT** auto-expose every flag as an env var"
(`S08`).

**This changes the shape of the answer.** The tier set and the precedence order are
**not** research findings; they are a contract this item implements. What R54
researches is the *mechanism*: which crate or pattern realizes each rung, and which
composition preserves the decisions the rest of the config stack has already
published.

**What must agree across py, ts and rs, and what may vary.**

| # | Principle | Agreement level | Must agree | May vary |
|---|---|---|---|---|
| C1 | Configuration resolves through a documented, total precedence chain with no silent tie | **standard, one value for all three repos** (`R5.1` is a `MUST` binding every tool the standard governs) | the six-rung order, and that it is documented verbatim | nothing |
| C2 | Three file scopes exist: system, user, project | **standard** (`R5.1` rungs 3–5) | that all three are searched, and their relative order | the directory API used to find them |
| C3 | Per-user paths follow XDG and honour `XDG_*`; an unusable value is ignored | **capability + standard** (F247, `R5.3`) | `XDG_CONFIG_HOME` honoured on `ubuntu-latest` and `macos-latest`; empty ignored; **and, proposed here, relative ignored** | the crate; macOS uses XDG rather than `~/Library/Application Support` in all three repos already |
| C4 | An explicit `--config` replaces the discovered chain rather than adding to it | **architectural pattern** (F233, `COMMON → REUSE`, already agreed) | the replace-not-add semantics | the control flow implementing it |
| C5 | The config path has one documented environment alias named after the tool | **policy/mechanism** (F234, `R5.4`) | that the alias exists and is tool-named | its spelling — `PLBP_CONFIG` / `TS_PROJECTS_CONFIG` / `RSLBP_CONFIG` |
| C6 | Tables merge recursively; scalars and arrays replace; the nearer scope wins | **standard** (`R5.1`) | the merge *semantics* | the merge *implementation*, and where in the pipeline it sits |

C6 is the row where the ecosystems genuinely differ, and it is where this decision
departs from its own strongest raw report. py and ts merge untyped dictionaries and
then validate once, which is natural in a language whose native map type *is* the
parsed document. Rust has the same move available — merge `toml::Table`s, then
deserialize — and the question is whether merging before validating destroys
information the config stack has already promised to keep. **In this template it
does not, because R55 has already published a loader that validates each layer
before the merge.**

**The architectural alternatives, compared before any library was chosen.**

| Alt | Shape | Verdict |
|---|---|---|
| **A1 — a layer-merging engine owns everything** | `config` 0.15.25 or `figment` 0.10.19 takes a source list, merges dynamic value trees, and produces one `T` by a single final `deserialize` | **Rejected on fit.** It takes ownership of three things already decided elsewhere: the parse (R52's `toml` 1.1.6), the typed pass (R53's per-key loop over `toml::Table`, `D06`), and the per-layer sanitize step and warning list (R55, `D01`, `D03`). Adopting it does not add a tier; it replaces three published decisions with a framework's own pipeline. Secondary and real but not decisive: `config`'s default feature set pulls four parsers the template will never use into a binary whose format `R5.2` fixes to TOML. |
| **A2 — merge `toml::Table`s, then one typed pass, with *no* per-layer validation** | parse each layer, merge tables recursively, deserialize the merged document once | **Rejected, and this is the alternative R55 already rejected for the whole stack.** A bad leaf fails the single final deserialize and takes the document with it, and the failure cannot name the file it came from. R55's `BASELINE-REVIEW: F238` is exactly this finding — "validate each layer's leaves before precedence merge rather than Python's merge-then-pop" (`D03`). |
| **A2′ — merge the *sanitized* `toml::Table`s, then R55's single final pass** | per-layer read → R53's per-key loop → prune each rejected leaf and each unconsumed key, emitting a warning that names the file → recursive table merge **in R54's precedence order** → one final typed pass | **Chosen.** It is not a new design: it is the loader R55 has already published, with R54 supplying the ordered layer list and the merge rule. R55's own words: "the merge over sanitized tables in R54's order followed by the single final pass" (`D01`). Provenance survives because sanitization happens *before* the merge, not because the merge carries metadata. It satisfies `R5.1`'s recursive-table `MUST` directly, at any nesting depth, with no constraint on how R53 shapes its type. |
| **A3 — per-layer typed parse into an all-`Option` partial struct, then a field-wise fold** | each layer deserialized into a recursively-partial `PartialConfig`; later `Some` replaces earlier | **Rejected — this is `raw/opus.md`'s recommendation, and the ground for rejecting it is a published sibling decision that report did not read.** It would require R53's schema to become a recursively-partial generated type; R53 revision 2 instead validates **per key over R52's `toml::Table`** (`D06`), and R55's sanitize step prunes from that same table. A3 would reopen R53 to buy provenance that A2′ already has. See `## Engines`, Disagreement 1. |
| **A4 — a derive-macro layered loader** (`confique` 0.4.0, `twelf` 0.15.0) | the layers are attributes on the config struct | **Rejected.** Neither implements *discovery*; the caller still supplies the paths, so the crate replaces the easy half of this item and not the hard half. `twelf`'s last release was 2024-03-11. |
| **A5 — a single user tier plus `--config`** | ts's shipped shape | **Rejected: it violates `R5.1`, a `MUST`.** Recorded because it is what ts ships despite ts's own D-017(1) naming the full chain; the prompt calls that gap live context and the standard closes it. |

**Why the selected design preserves each principle.** C1 and C2 are satisfied by
construction — the six rungs are enumerated in the loader and the template
documents them verbatim (AC9). C3 is satisfied by `etcetera`'s XDG strategy on both
target runners plus its absoluteness filter, neither of which the template
reimplements (`E02`, `E03`). C4 is a one-line change to the *path list* before any
parsing, which is why `--config` needs no special case inside a merge engine. C5 is
one `clap` attribute. C6 is satisfied by A2′, whose merge is over `toml::Table`s and
therefore recurses into nested tables naturally, with arrays replacing because a
`Vec` value replaces wholesale — the `R5.1` default, and the one place the template
deliberately differs from Cargo, whose arrays join.

**The system tier: the decisive mechanism finding, re-verified here.** No crate in
the recommended stack enumerates `$XDG_CONFIG_DIRS`. A recursive census of
`etcetera` 0.11.0's extracted source for `CONFIG_DIRS` or `DATA_DIRS` returns zero
matches (`E01`), and its `BaseStrategy` trait declares a singular
`fn config_dir(&self) -> PathBuf;` (`E05`). `directories` 6.0.0 and `dirs` 7.0.0
expose the same singular accessor. The one crate in the field that does the job is
`xdg` 3.0.0 — `get_config_dirs()` (`X02`), `env::split_paths` (`X04`), and the
`/etc/xdg` default (`X03`) — and its implementation is correct. It is not
recommended for two architectural reasons, neither of which is a gate failure:
it compiles to an empty crate off Unix (`#![cfg(any(unix, target_os = "redox"))]`,
`X01`), which forecloses a future Windows row the template would otherwise only
widen a matrix for; and adding it beside `etcetera` puts **two independent
resolvers for `XDG_CONFIG_HOME`** in one binary, contradicting R57's single
directory authority at the design level. J3 records that this is a judgement.

The mechanism the template owns instead is four `std` calls:
`std::env::var_os("XDG_CONFIG_DIRS")` → `std::env::split_paths` (the platform-correct
`PATH`-style split, the same call `xdg` 3.0.0 makes) → `filter(Path::is_absolute)`
(the specification's relative-path rule, `Z01`) → `/etc/xdg` when the result is
empty (`Z02`). **Order is the part that is easy to get backwards.** The
specification says the first directory listed is the most important (`Z03`) and that
`$XDG_CONFIG_HOME` outranks every `$XDG_CONFIG_DIRS` entry (`Z04`), so a
later-wins fold must walk the list **last to first**. py implements exactly this by
reversing (`core/config.py:135`, `*reversed(paths.system_config_files())`); AC2
exists because a naive forward loop silently inverts it.

**The project tier: the boundary rule, and the defect in the obvious reading.**
`R5.2` delegates the marker list ("a non-exhaustive baseline", `S06`), so the
template chooses. Taking `Cargo.toml` at face value **breaks in this template's own
shape**: `rs-launch-blueprint` is a Cargo workspace, so every member crate carries
its own `Cargo.toml`, and a walk from `crates/<member>/src/` would stop at the
member directory and never see a `.rslbp/` at the repository root. The rule is
therefore:

1. `.git` is **always** a boundary, whether it is a directory (an ordinary clone) or
   a **file** (a `git worktree` checkout or a submodule) — so the test is
   `exists()`, not `is_dir()`; and
2. `Cargo.toml` is a boundary **only when its document declares a top-level
   `workspace` table**, which makes it the workspace root rather than a member.

Nothing else on `R5.2`'s list applies to a Rust repository. The stop is
**inclusive** — the boundary directory is itself searched — so a `.rslbp/` at the
repository root is found. Only the **nearest** hit is taken: `R5.1` rung 3 says
"nearest", singular, giving one project layer rather than Cargo's merged ancestor
chain.

**This rule was executed rather than asserted.** The probe under `## Empirical
check` runs both policies over nine tree shapes. The two lines that matter:

```
PASS P1-workspace-qualified-finds-root cwd=A/crates/foo/src got=A/.rslbp/rslbp_config.toml want=A/.rslbp/rslbp_config.toml
PASS P2-any-cargo-toml-loses-root      cwd=A/crates/foo/src got=None                        want=None
```

`P2` is the defect, reproduced: under "any `Cargo.toml` stops", the workspace-root
config file is unreachable from a member crate. `P5` proves the `.git`-as-a-file
case (the shape this repository is itself checked out as), `P6` proves a boundary
below the file blocks it, `P7` proves nearest-only, and `P9` proves that
`[workspace.package]` alone counts as a declaration. **What the probe does not
prove** is the detection method: it matches the section header by line, whereas P03
should parse the manifest with R52's `toml` and test for a top-level `workspace`
key. The probe is an approximation of that test, and is labelled so in its source.

**Reference implementations — this composition is shipping, not hypothetical.**
Each fact below was re-fetched in this run rather than carried from the raw report.
`uv` (astral-sh) depends on `etcetera` 0.11.0 (`U01`) and documents a
`$XDG_CONFIG_DIRS` system tier (`U02`) that `etcetera` provably cannot supply
(`E01`), plus an upward project search (`U03`) — that is this decision's exact
composition, in production, on Linux and macOS. `ruff` (astral-sh) depends on
`etcetera` 0.11.0 (`U04`). `raw/opus.md` additionally surveyed `jj`, `helix`, `bat`
and `starship` and reports that none of the six depends on a layering crate
(2026-09-17); that census is **carried from the raw report and was not re-run
here** — see `## Engines`.

**Essential behaviours and observable acceptance criteria.** These are proposals
for P03; **none was executed in this run**, because the template does not exist.

| # | Criterion |
|---|---|
| AC1 | With one key set in all three discovered tiers, the resolved value is the project one; remove the project file and it is the user one; remove that and it is the first `$XDG_CONFIG_DIRS` entry's. |
| AC2 | With two entries in `$XDG_CONFIG_DIRS` both setting the key, the **first** entry wins. |
| AC3 | A `[table]` set partly in the user file and partly in the project file merges recursively at every nesting depth; a scalar and an array each replace wholesale. |
| AC4 | `--config <path>` makes the three discovered files invisible: a key set only in the project file is absent from the resolved config, while an `RSLBP_*` variable and a flag still override the explicit file. |
| AC5 | `RSLBP_CONFIG=<path>` behaves as AC4; an explicit `--config` on the command line beats it; `RSLBP_CONFIG=` (set but empty) is ignored and ordinary discovery runs. |
| AC6 | **F247.** `XDG_CONFIG_HOME` set to an absolute path relocates the user tier on **both** `ubuntu-latest` and `macos-latest`; set to `""` **or to a relative path** it is ignored and `~/.config/rslbp/` is used. The relative half is the open owner question this decision proposes answering "required". |
| AC7 | Project discovery finds `.rslbp/rslbp_config.toml` in an ancestor directory, and does not find one that sits above the nearest boundary marker. `.git` is exercised as a directory **and** as a file. |
| AC7b | **Nested-manifest case.** In `root/{Cargo.toml with [workspace], .rslbp/rslbp_config.toml}` plus `root/crates/foo/{Cargo.toml without [workspace], src/}`, running from `root/crates/foo/src/` finds the root file. Executed here as probe case `P1`; its negative twin is `P2`. |
| AC8 | A missing file in any *discovered* tier produces no warning, no stderr output and no exit-code change — absence is not a fault (R55 clause 1). |
| AC9 | The precedence chain printed in the generated documentation is byte-compared against `R5.1`'s six rungs by a test, because `R5.1` says "MUST document it verbatim". |
| AC10 | A library-crate test proves the library reads no environment variable and touches no filesystem path on import: discovery runs only when the composition root calls it, with `cwd`, the environment view and R57's `Paths` passed in. |
| AC11 | The merge strategy — tables recurse, scalars replace, arrays replace — is stated in a doc comment that a test pins, satisfying `R5.1`'s "MUST document the strategy clearly". |

AC10 is inherited rather than invented: R57's revision-2 finding JF-4 established
that edition 2024 makes `std::env::set_var` `unsafe` and R06 forbids `unsafe`, so
the environment is **injected**. R54 takes the same shape, which is also what makes
AC1–AC8 hermetic and parallel-safe.

**Couplings, stated as constraints and not decided here.**

- **R52** (`toml` 1.1.6+spec-1.1.0 + `toml_edit` 0.25.15, published): R54 parses each
  discovered layer with `toml` and adds nothing. `config set` writes through
  `toml_edit` to the **user** tier, `Paths::config_dir()/rslbp_config.toml`, which is
  py's write target (`core/config.py:131-133`). R54 changes neither crate nor feature.
- **R53** (`serde` only, per-key loop over `toml::Table`, owner-accepted at revision
  2): R54 **adds no constraint to R53**. This is a change from `raw/opus.md`, which
  would have required R53's partial type to become recursively partial; A2′ needs no
  such type. What R54 supplies R53 is the ordered list of layers its loop runs over.
- **R55** (two-phase loader, no added crate, revision 2 under judgment): R55 states
  that R54 "owns merge depth and precedence order" while R55 "fixes only the
  *sequence*" (`D02`). This decision supplies exactly that: depth is **recursive at
  every level** for tables, replace for scalars and arrays; order is `R5.1`'s. R55
  also asks R54 to tag each discovered layer with provenance; the tier column of the
  rung table is that tag, and R55's `ConfigSource`/`Discovered { path, tier }` is
  where it lives. R55's re-verify trigger "R54 publishing" fires with this document,
  and the answer to its conditional is: **three discovered tiers exist, so clause 2's
  tolerant limb and F236 have three Rust instances.**
- **R57** (XDG via `etcetera` 0.11.0 on a template-owned `Paths`, namespace `rslbp`,
  owner-accepted at revision 2): R54 consumes `Paths::config_dir()` and appends
  `rslbp_config.toml`. **R54 does not re-select the crate and declares no
  `etcetera` dependency of its own.** One gap is real and is named rather than
  papered over: R57's four accessors do not include a `$XDG_CONFIG_DIRS` list, and
  R57's decision explicitly "exposes no runtime-directory accessor and no
  free-function surface" (`D04`). **This decision's disposition is that R54's own
  discovery module owns the system list**, for three reasons: `$XDG_CONFIG_DIRS` is a
  system-wide *search path*, not one of the per-user kinds R57 scopes itself to; it
  is a **different environment variable** from `XDG_CONFIG_HOME`, so no second
  authority for R57's variable is created; and it leaves an owner-accepted decision
  unopened. `raw/opus.md` prefers the other disposition — a fifth `Paths` accessor —
  on a single-authority argument; that is recorded under `## Engines` as a
  disagreement, and if the owner prefers it, only *where* the eight lines live
  changes, not what they do.
- **R60** (`clap` 4.6.6 with `derive`, `env`, `wrap_help`, owner-reviewed): the
  `env` feature is already in R60's set, so F234 costs no `Cargo.toml` change.
- **R67** (error taxonomy, owner-accepted, consumed as a parameter): R54 introduces
  no new failure. An explicit path that is unreadable is `RSLB104`/1 and one that is
  unparsable is `RSLB202`/2 — rows R55 has already bound to the explicit-versus-
  discovered distinction. A file simply absent from a discovered tier is not a
  failure at all (AC8).
- **R49** (`build-tool-output-shape`): supplies the binary name `rslbp`, which is the
  `<tool>` segment in every path above. R57 already consumes it for the same reason.

re-verify: 2027-03-17, or earlier on any of — the org CLI Design Standard moving past blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in §5, since the whole tier set and precedence order are downstream of `R5.1`/`R5.2`; `etcetera` publishing any version above 0.11.0 — checks `F01` and `F02` assert that none exists as of 2026-09-17, and `raw/opus.md` reports (carried, not re-verified here) that its HEAD already holds an unreleased "Drop cfg-if dependency" commit, so the next release is likely to move the dependency closure; **R57 being revised** in a way that changes the `Paths` accessor set or adds the `config_dirs()` accessor this decision declines to ask for; **R55 being revised** in a way that changes the sanitize-then-merge sequence, which is the entire ground for choosing A2′ over A3; **R53 being revised** away from the per-key loop over `toml::Table`; `clap` adding an emptiness filter to its env path, which would make this template's filter redundant but harmless (`C02` is the assertion that would flip); R52 replacing `toml` with a parser that exposes no addressable intermediate table; or the owner ruling on either `BASELINE-REVIEW:` line above, since F232's ledger text and F247's absoluteness question are both still open.

## Parameters

R54 owns no registry parameter. The binding prompt's `## Couplings` block carries an
empty `- owns:` line, `docs/port/PARAMETERS.md` lists no `R54` owner, and
`research/CLAUDE.md`'s R54 row shows `owns: —`. Its one consumed parameter is
R67's, named on the prompt's `- consumes: R67: error-taxonomy-exit-codes` line.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**No `CONFLICT:` line is raised.** No raw report raised one, and nothing in this
recommendation needs a consumed parameter to change. `raw/opus.md` states "No
`CONFLICT:` line"; the Doxa/OpenAI twin states "No `CONFLICT:` identified"; the
Doxa/Perplexity twin states "no `CONFLICT:` lines are required"; the Doxa/Gemini
twin contains no `CONFLICT:` string at all, which is an absence rather than a
statement and is recorded as such. Every failure this item's tiers can produce is
already expressible in R67's published catalogue.

The five lines above are byte-identical to their `docs/port/PARAMETERS.md` rows,
asserted mechanically at `## Empirical check` checks `P01`–`P05`. The run's
`inputs/PARAMETERS.md` differs from the current registry in exactly one row —
`web-extra-surface`, owned by R69 and **not consumed here** — which check `P06`
asserts, so no consumed value moved under this synthesis.

**How each parameter bears on the decision.** `rust-edition = 2024` is
load-bearing twice: it makes `std::env::set_var` and `std::env::remove_var`
`unsafe`, which is why the environment view is an *injected argument* rather than a
process read (AC10, R57's finding JF-4), and it is the edition the walk-up probe
compiled under. `target-os-matrix = ubuntu-latest, macos-latest` is load-bearing
three times: it is why `etcetera`'s macOS→XDG arm is required rather than merely
nice (`E03`, F247); it is why `xdg` 3.0.0's Unix-only `#![cfg]` (`X01`) is *not* a
gate-4 failure, only a forward-looking cost; and it is the gate this synthesis
could not discharge itself, because every check here ran on one macOS host and
`ubuntu-latest` was not exercised — P03's own CI is the receipt. `msrv-policy`
evaluates to a floor of **1.96** against the local stable **1.98.0** recorded
below; `etcetera` 0.11.0 declares `rust-version = "1.87.0"` (`E04`), clearing it by
nine minor versions, and every other mechanism in the stack is `std`. `license` is
recorded and **not evaluated as a gate**, under the owner ruling of 2026-09-12
(Q7.B); nothing is excluded on licence here, and `etcetera`'s metadata happens to
read `MIT OR Apache-2.0`. `error-taxonomy-exit-codes` bears in one place only:
R54's three discovered tiers are the "discovered" side of the explicit-versus-
discovered split R55 built on R67's `RSLB104` / `RSLB202` / `RSLB203` rows. R54
routes to no row of its own and defines none.

## Empirical check

**Nothing in the recommendation was implemented.** The template does not exist; the
checks below verify what the raw reports assert, and they verify it against the
standard's blob, published crate sources at exact versions, live registry and
repository endpoints, the pinned py source, and the sibling decisions this
synthesis must not contradict. One throwaway Rust probe was compiled to test the
project-tier boundary rule; it lives entirely under `$TMPDIR` and the script
deletes it.

**Toolchain and host.**

```
rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)
cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)
Darwin 25.4.0 (macOS, arm64)
/usr/bin/grep — grep (BSD grep, GNU compatible) 2.6.0-FreeBSD
shellcheck 0.11.0
```

**Working directory and commands.** From
`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/evidence/` in a checkout
of this repository:

```bash
shellcheck check.sh                 # → exit 0, no output; saved as shellcheck.log
./check.sh > check.log 2>&1         # the run cited throughout this decision
./check.sh > check-rerun.log 2>&1   # the reproducibility rerun
diff check.log check-rerun.log      # → no differences
```

**Observed result: 62 checks, 62 `PASS`, 0 `FAIL`, 0 `SKIP`; `failures=0
skipped=0`; exit status 0.** The full output is `review/evidence/check.log`. The
probe's nine cases are printed inside it, indented, under `PR1`.

**What each group proves, and which claim in `## Decision` it carries.**

| Group | Checks | What it settles |
|---|---|---|
| `S01`–`S09` | 9 | The org CLI Design Standard v1.4.14 text quoted in `### Principles and implementation` is present verbatim at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`: `R5.1`'s six rungs and its merge sentence, `R5.2`'s dot-directory walk-up, boundary stop and `--config` replacement, `R5.3`'s `/etc/xdg` default, and `R5.4`'s curated subset including the config path. This is the ground for J1. |
| `E01`–`E05` | 5 | `etcetera` 0.11.0, read from `https://static.crates.io/crates/etcetera/etcetera-0.11.0.crate`: **zero** matches for `CONFIG_DIRS`/`DATA_DIRS` across its whole `src` tree; a singular `fn config_dir(&self) -> PathBuf;` on `BaseStrategy`; the `create_strategies!(Apple, Xdg)` macOS arm; the `is_absolute` filter; `rust-version = "1.87.0"`. The first two are the reason rung 5 needs a template-owned resolver; the third and fourth are F247 on `macos-latest` and the absoluteness half of the F247 `BASELINE-REVIEW:` line. |
| `X01`–`X04` | 4 | `xdg` 3.0.0 does enumerate the system tier correctly (`get_config_dirs`, `split_paths`, the `/etc/xdg` default) and is Unix-only. This is the runner-up's evidence, and the honest counterweight to J3. |
| `C01`–`C03` | 3 | `clap_builder` 4.6.6: env is applied **only when the flag is absent** (flag beats env, `R5.1` rungs 1–2, free), and the env value is tested for **presence only** — there is no emptiness filter on that path, which is why F242 needs one line of template code. |
| `F01`–`F06` | 6 | Registry figures. `etcetera`'s `max_stable_version` is `0.11.0` and **no 0.12.x version exists** — which settles the Doxa/Gemini provider's `etcetera = "0.12"` recommendation. `xdg`'s is `3.0.0`. `cfgmatic-paths` and `cfg-rs`, the two crates the Doxa/Perplexity provider recommends in place of `etcetera`, both **exist** but carry all-time download counts of **874** and **69,755** against `etcetera`'s **108,625,667** on the same endpoint in the same run. |
| `G01`, `G02`, `R01`, `R02` | 4 | `lunacookies/etcetera` is not archived; `soc/directories-rs` **is** archived, which is the gate-4 exclusion for `directories` 6.0.0 quite apart from its macOS behaviour. `rustsec.org/packages/etcetera.html` is HTTP 404 — no advisory — with `anyhow.html` as the control proving the site serves pages. |
| `Z01`–`Z04` | 4 | The XDG Base Directory Specification, read from the DocBook source: paths in the `XDG_*` variables must be absolute; `/etc/xdg` is the `XDG_CONFIG_DIRS` default; the first directory listed is the most important; `$XDG_CONFIG_HOME` outranks every `$XDG_CONFIG_DIRS` entry. The last two are the ordering rule AC2 pins. |
| `U01`–`U04` | 4 | The composition is shipping: `uv` depends on `etcetera` 0.11.0 while documenting an `$XDG_CONFIG_DIRS` system tier and an upward project search; `ruff` depends on `etcetera` 0.11.0. |
| `D00a`–`D08` | 12 | The sibling decisions, by sha256, and the three sentences this synthesis rests on: R55's "the merge over sanitized tables in R54's order followed by the single final pass", its assignment of "merge depth and precedence order" to R54, and its F238 finding that layers are validated before the merge; R57's fixed four-accessor surface and its handover of `config_dir()`; R53's per-key loop over R52's `toml::Table`. `D08` records that `raw/opus.md` cites R55 at **revision 1**, which is the ground for Disagreement 1. |
| `P01`–`P06` | 6 | The five `- assumes` values are byte-identical to `docs/port/PARAMETERS.md`, and the run's `inputs/PARAMETERS.md` differs from the current registry only in the `web-extra-surface` row. |
| `Y01`–`Y03` | 3 | The pinned py source at `b08bccfb55d05f15e46a83b52c5660b1881d19f5`: `project_config_file` exists and contains **no** parent walk, and `config_dirs()` enumerates the system tier. This is the F232 `BASELINE-REVIEW:` line's py half, re-verified rather than carried. |
| `PR1` | 1 (9 cases) | The bounded walk-up, executed. |
| `H01` | 1 | The Codex engine's absence has a recorded cause in the run itself. |

**The probe, in full.** `review/evidence/walkup_probe.rs` is a single dependency-free
file compiled with `rustc --edition 2024 -O` into the script's `$TMPDIR` working
directory and run against nine temporary trees it builds there. It implements the
walk under two policies — `WorkspaceQualified` (this decision's rule) and
`AnyCargoToml` (the naive reading of `R5.2`'s example list) — and prints paths
relative to the tree root so the output is byte-stable. Observed:

```
PASS P1-workspace-qualified-finds-root cwd=A/crates/foo/src got=A/.rslbp/rslbp_config.toml want=A/.rslbp/rslbp_config.toml
PASS P2-any-cargo-toml-loses-root cwd=A/crates/foo/src got=None want=None
PASS P3-workspace-root-inclusive cwd=A got=A/.rslbp/rslbp_config.toml want=A/.rslbp/rslbp_config.toml
PASS P4-git-dir-root-found cwd=B/a/b got=B/.rslbp/rslbp_config.toml want=B/.rslbp/rslbp_config.toml
PASS P5-git-file-root-found cwd=C/a/b got=C/.rslbp/rslbp_config.toml want=C/.rslbp/rslbp_config.toml
PASS P6-boundary-below-blocks cwd=D/a/b got=None want=None
PASS P7-nearest-only cwd=E/a/b got=E/a/.rslbp/rslbp_config.toml want=E/a/.rslbp/rslbp_config.toml
PASS P8-no-marker-no-file cwd=F/a/b got=None want=None
PASS P9-workspace-package-counts cwd=G/crates/bar/src got=G/.rslbp/rslbp_config.toml want=G/.rslbp/rslbp_config.toml
PROBE-FAILURES 0
```

`P2` is the one case whose `want` is a **failure of the rejected policy**: it
asserts that "stop at any `Cargo.toml`" loses the workspace-root config file from a
member crate, which is why J4 qualifies the marker. The probe's limitation is stated
in its own source and repeated here: it detects `[workspace]` by matching the
section header on a line, while P03 should parse the manifest with R52's `toml` and
test for a top-level `workspace` key. A manifest that declared the table by some
other syntax would fool the probe and not fool P03.

**Reproducibility, stated precisely because a saved log is a claim.** `check.sh`
was run, this section was written from its output, and then the script was **run
again and diffed against the committed log**: `diff check.log check-rerun.log`
produced no differences, on 2026-09-17, between the two runs committed here. That
is the claim, and it is narrower than "this log reproduces forever". Most of the
log is deterministic by construction — every line is a `PASS`/`SKIP`/`FAIL`
assertion or a sha256, and no timestamp or fetched body is printed into it — but
**three lines carry a live counter**: `F03`, `F04` and `F06` print
`crate.downloads` for `cfgmatic-paths`, `cfg-rs` and `etcetera`. Those numbers
only rise, so a later rerun will very probably differ on exactly those three lines
while their assertions (each count on the correct side of its threshold) continue
to hold. The rule for comparing across a rerun is therefore: the `PASS`/`FAIL`
verdict of every check must match, and only the three download integers may move.
The volatile material lives in `review/evidence/snapshots/`, written by the same
run on **2026-09-17**:
`crates-etcetera.json`, `crates-etcetera-versions.json`, `crates-xdg.json`,
`crates-cfgmatic-paths.json`, `crates-cfg-rs.json`,
`gh-lunacookies-etcetera.json`, `gh-soc-directories-rs.json`,
`xdg-basedir-spec.xml`, `uv-Cargo.toml`, `uv-configuration-files.md`,
`ruff-Cargo.toml`, `cli-design-standard-f9de0437.md` and `py-paths-b08bccfb.py`.
Three things would change a check's **verdict** on a future rerun, and each is a
re-verify trigger rather than a flaw: a new `etcetera` release (`F01`, `F02`), a
download count crossing one of the three thresholds `F03`/`F04`/`F06` assert, and
either adopter editing its `Cargo.toml` or its documentation (`U01`–`U04`). The `gh api`
calls run through an already-authenticated `gh`; no token was printed, inspected or
written, and no environment was emitted into any artifact.

**Figures, with endpoint and retrieval date.** All retrieved **2026-09-17**.

| Crate | 90-day (`crate.recent_downloads`) | All-time (`crate.downloads`) | Latest unyanked | `rust_version` | Endpoint |
|---|---|---|---|---|---|
| `etcetera` | 33,084,740 | 108,625,667 | 0.11.0 (2025-10-28) | 1.87.0 | `GET https://crates.io/api/v1/crates/etcetera` and `/versions` |
| `xdg` | 3,787,325 | 22,590,920 | 3.0.0 (2025-05-04) | 1.60.0 | `GET https://crates.io/api/v1/crates/xdg` |
| `cfg-rs` | 478 | 69,755 | 1.0.5 (2026-08-05) | — | `GET https://crates.io/api/v1/crates/cfg-rs` |
| `cfgmatic-paths` | 262 | 874 | 5.0.1 (2026-04-12) | — | `GET https://crates.io/api/v1/crates/cfgmatic-paths` |

| Repository | Stars | Archived | `pushed_at` | Endpoint |
|---|---|---|---|---|
| `lunacookies/etcetera` | 150 | false | 2026-08-04T20:53:17Z | `GET https://api.github.com/repos/lunacookies/etcetera` |
| `soc/directories-rs` | 837 | **true** | 2025-01-12T19:35:58Z | `GET https://api.github.com/repos/soc/directories-rs` |

Advisories: `https://rustsec.org/packages/etcetera.html` → HTTP 404 on 2026-09-17,
with `https://rustsec.org/packages/anyhow.html` → HTTP 200 as the control, so the
404 is the no-advisory result and not an outage. `unsafe` posture, maintenance
verdicts, issue responsiveness, dependency-closure size and the six-project
layering-crate census are **carried from `raw/opus.md` and were not re-derived
here**; they are listed under `## Engines` as unproven-by-this-synthesis.
`cfgmatic-paths` is hosted on `https://gitlab.opentc.ru/opentc/rust-cfgmatic`, so
the prompt's GitHub figures are `inapplicable — not hosted on GitHub` for it.

**Fitness gates.** Gate 1 (licence) is
`inapplicable — owner ruling 2026-09-12 (Q7.B)` for every candidate; nothing is
excluded on licence. For the two `std`-only members (the system-tier resolver and
the project-tier walk-up) gates 2–6 and the crate figures are
`inapplicable — no crate is added by this member`, and gate 4 rests on `std`
availability on both runners. For `etcetera` 0.11.0 the gates were answered by
**R57**, which selected it, and are re-verified here only where F247 depends on
them (`E02`–`E04`); R54 adds no dependency, so it opens no new gate. For `clap`
4.6.6 the gates were answered by **R60**. *Excluded by gate:* `directories` 6.0.0 —
gate 4, its repository is archived (`G02`) so it can demonstrate no current CI
matrix, and F247 records that its macOS `config_dir()` ignores `$XDG_CONFIG_HOME`.
`xdg` 3.0.0 fails **no** gate; recording it as an exclusion would misstate why it
was not chosen (J3).

## Engines

| Engine | Report | sha256 |
|---|---|---|
| Claude Opus 5 | `raw/opus.md` | `7356d9d786122df6c27474ef4e8b4af112cccdd0a6c9161f2d62cbaa35070d8d` |
| Doxa (op `research-20260916-220239-200467ec7afb44b5`) | `raw/doxa.md` | `a414c72f8391972c902c48def851c3a97c1ae9c9138afddbfd3de328bc074f2b` |
| Doxa, normalized | `raw/doxa.normalized.md` | `b79e8db77b294eefdcba4bb4d3dc7f74b8008a47c4c11496b69fb716b06eec5e` |
| Doxa / OpenAI twin | `raw/doxa-openai.normalized.md` | `ff2d29891039ff6d880931c5ea69e5ef80071817f8c12bac8ec21e170727a32d` |
| Doxa / Perplexity twin | `raw/doxa-perplexity.normalized.md` | `b42d668cedf9fe0b6fa6055d803147e1e59fe2abb983f70a8d570ee20d5f9744` |
| Doxa / Gemini twin | `raw/doxa-gemini.normalized.md` | `58521eb96f646f2ff3a7ad62190b0dc179e2b9731578b21f74cdda3c2696a693` |
| **Codex** | **ABSENT** | — |

**Codex is absent by owner direction** — `docs/planning/p02/owner-decisions.md`
section 12, `W1-CODEX`. The run directory also carries the mechanical cause:
`raw/codex-exit.txt` is `1` and `raw/codex-transcript.txt` ends with the provider's
refusal, "You've hit your usage limit" (`H01`). No Codex report exists for this
item, so no Codex position is represented below; the adversarial second lens this
item would normally carry is missing, and that is a real reduction in confidence,
most sharply on J3 and J4, which are judgements rather than `MUST` clauses.

**Disagreement 1 — where the merge happens. Opus (A3) versus this decision (A2′).**
`raw/opus.md` recommends a per-layer typed parse into a *recursively partial*
struct followed by a field-wise fold, and states a constraint on R53: "the partial
type must be **recursively** partial (nested tables `Option<PartialSub>` with
`Option` fields)". It rejects the merge-tables-then-deserialize shape because "a bad
leaf fails the single final deserialize, taking the whole merged document with it"
and because provenance is lost by merge time. **Settled against Opus, on a
published sibling decision that report did not read.** Its own `### Sources` cites
R55 at "(revision 1, `## Decision`, clauses 1–3)" (`D08`); R55 is at revision 2,
which publishes the loader as "the merge over sanitized tables in R54's order
followed by the single final pass" (`D01`), with every invalid leaf and unknown key
already pruned *per layer*, each pruning emitting a warning that names its file
(`D03`). Both of Opus's objections assume an **unsanitized** merge; R55 removed that
premise. And R53 revision 2 validates **per key over R52's `toml::Table`** (`D06`),
not through a generated partial type, so Opus's constraint would reopen an
owner-accepted decision to buy provenance A2′ already has. Opus's reasoning is
sound on its inputs; its inputs were one revision stale.

**Disagreement 2 — a layering crate. All three Doxa providers add one; Opus and this
decision add none.** Doxa/OpenAI recommends
`config = { version = "0.15.25", default-features = false, features = ["toml"] }`;
Doxa/Gemini recommends `config` 0.15 as member #1 of its stack; Doxa/Perplexity
recommends `cfg-rs` with `config` as runner-up. **Settled against all three, on
scope rather than on quality.** A layer-merging engine owns the parse, the merge and
the final `deserialize`; in this template those three are already owned by R52
(`toml` 1.1.6), R54 (this decision's merge rule) and R53/R55 (the per-key loop and
the sanitize step). None of the three providers could have known that: the Doxa
prompt is `inputs/prompt.md`, which names R52, R53, R55 and R57 as *related items*
without carrying their decisions. Two further grounds are independent of the
sibling decisions. First, Doxa/OpenAI and Doxa/Gemini both route the ordinary
`RSLBP_*` environment layer through `config::Environment::with_prefix`, which binds
the whole prefix; `R5.4` says "the tool **MUST NOT** auto-expose every flag as an
env var" and requires a curated subset (`S08`), so that mechanism is not usable as
specified. Second, `raw/opus.md`'s six-project manifest census found no layering
crate in helix, ruff, uv, bat, jj or starship — carried, not re-run.

**Disagreement 3 — which crate resolves the user tier.** Opus and Doxa/Gemini say
`etcetera`; Doxa/OpenAI says "Do not add `directories`, `etcetera`, or `xdg` as
runtime dependencies for R54" and hand-rolls the whole path layer; Doxa/Perplexity
demotes `etcetera` to runner-up behind `cfgmatic_paths`. **Settled by R57, plus
adoption evidence.** R57 is owner-accepted and already selected `etcetera` 0.11.0 on
a template-owned `Paths`; R54 is instructed to build on that value rather than
re-select, so Doxa/OpenAI's exclusion would reopen R57 to save a dependency the
template already carries. Its stated defect — "`etcetera` 0.11.0 … does not expose
the ordered `XDG_CONFIG_DIRS` system list" — is **correct** (`E01`) and is exactly
why this decision adds a `std` member for rung 5; it is not a reason to drop the
crate from rung 4. Doxa/Perplexity's `cfgmatic_paths` was checked rather than
dismissed: the crate exists as `cfgmatic-paths`, published 2026-02-05, with **874
all-time downloads** against `etcetera`'s **108,625,667** on the same endpoint in
the same run (`F03`, `F06`), hosted outside GitHub, and that provider's own report
states its licence, MSRV, advisories and CI were never verified. All four
engine positions agree on one thing worth recording: `directories` 6.0.0 is out,
on F247.

**Disagreement 4 — the `etcetera` version.** Doxa/Gemini recommends
`etcetera = "0.12"` with an MSRV of 1.95.0, "falling back to v0.11 if required by
the strict MSRV window". **Settled empirically: no 0.12.x version of `etcetera`
exists.** `crate.max_stable_version` is `0.11.0` and the `/versions` endpoint lists
no `0.12` at all (`F01`, `F02`, 2026-09-17). That provider's report carries no
retrieval date on any figure and reports every GitHub metric as an execution
failure, so the version and its MSRV appear to be unsourced.

**Disagreement 5 — the project tier's shape.** All three Doxa providers propose a
**bare filename** walked up (`plbp.toml`, `<tool>_config.toml`), and none proposes a
boundary marker: Doxa/OpenAI and Doxa/Perplexity walk "toward the filesystem root",
and Doxa/Gemini contradicts itself, saying both "until a project marker is
identified" and "terminating only when the root of the filesystem is reached",
never defining the marker. Opus proposes the dot-*directory* with a bounded walk.
**Settled by the standard, which none of the Doxa providers was given.** `R5.1`
rung 3 and `R5.2` both specify `.<tool>/<tool>_config.toml` and a boundary stop
(`S02`, `S06`). The unbounded variants would let a walk started in a user's home
directory reach configuration the user never associated with the checkout. The
marker *list* is delegated by the standard and is this decision's J4.

**Disagreement 6 — extra tiers and owned parameters.** Doxa/Perplexity introduces a
fifth file tier (`ConfigTier::Local`, ordering `system < local < user < project <
env < CLI`); Doxa/OpenAI declares four owned parameters
(`config-discovery-scopes`, `config-selector-precedence`, `project-search`,
`project-config-path`). **Both rejected as out of contract.** `R5.1` enumerates six
rungs and no `local` tier, and the prompt's `## Couplings` carries an empty
`- owns:` line, so R54 registers no parameter; those four values live in this
decision's prose, where they bind P03 without entering the registry.

**Every `BASELINE-REVIEW:` line raised by any engine, with its disposition.** Two
came from `raw/opus.md` and are carried **verbatim** in `## Decision` (F232, F247),
both accepted. The Doxa twins raised five more, none of which is carried into
`## Decision`, for the reasons given here. Doxa/OpenAI: **F230** ("reclassify the
ordered multi-system tier from implementation divergence to a COMMON
capability/policy"), **F231** ("retain a COMMON XDG user tier on Ubuntu and macOS"),
**F232** ("reclassify nearest upward project discovery as COMMON policy") and
**F234** ("reclassify `<TOOL>_CONFIG` as a COMMON CLI capability") all propose
changing a ledger row's **verdict** from `DIVERGENT` to `COMMON`. That is not a
legal move on these rows: `docs/port/README.md`'s verdict table restricts
`COMMON → *` to origin `same`, and F230, F231, F232 and F234 all carry origin
`py-only` (`docs/port/COMMONALITY.md:234-238`) because ts implements none of them.
The underlying observation — that ts's absence is capability drift rather than a
justified ecosystem difference — is recorded in this decision's C1–C6 table and in
the prompt's own framing of D-017(1)/D-017(3), and the follow-on project is where
py and ts change. Doxa/OpenAI's **F247** line and Doxa/Gemini's and
Doxa/Perplexity's single **F247** lines all say, in different words, what Opus's
F247 line says and what this decision accepts: `XDG_CONFIG_HOME` must be honoured
on macOS, relative and empty values ignored, and `directories` rejected for
ignoring it. They are subsumed rather than dropped; Opus's is carried because it is
the one that cites the specification sentence and the crate line that implement it.

**What P03 must validate.** This decision is a proposal; these are the things its
CI is the first real test of.

1. **AC1–AC11 in full.** None was executed here. AC6 is the F247 gate and must run
   on **both** `ubuntu-latest` and `macos-latest`; this synthesis ran on one macOS
   host and exercised neither runner.
2. **J4's boundary rule against a real workspace.** The probe used a synthetic tree
   and a line-matched `[workspace]` header. P03 should detect the table with R52's
   `toml` parser and re-run AC7/AC7b against the template's own layout.
3. **A2′'s merge, against R55's loader as built.** The claim that a recursive merge
   over sanitized `toml::Table`s satisfies `R5.1` at every nesting depth is read
   from R55's and R53's published designs, not compiled. If R55's sanitize step
   turns out not to run per layer in the implementation, A3 comes back into scope.
4. **The `figment`/`config` provenance argument.** `raw/opus.md` states that a
   merge-then-deserialize engine cannot give R55 per-leaf, per-file provenance, and
   labels it an architectural argument rather than a measurement; it was not
   compiled there and not compiled here. A ten-line `figment` probe would falsify or
   confirm it, and A1's rejection in this decision does not depend on it — the scope
   argument stands alone.
5. **The empty-`RSLBP_CONFIG` filter.** `C02` proves `clap` does not filter it; only
   a test proves the template does (AC5's third clause).
6. **`ubuntu-latest`.** Every check in this decision ran on macOS.

**Unproven by this synthesis, carried from `raw/opus.md` and labelled as carried**
(each is that report's own claim at its stated retrieval date of 2026-09-17, not a
finding re-derived here): the six-project layering-crate census and the adopter
manifest line numbers for helix, jj, bat and starship; `etcetera`'s issue
responsiveness (median 0.27 days over three answered issues, one unanswered) and
its `active` maintenance verdict; the `unsafe` posture of `etcetera` (two sites,
both in the Windows FFI module, so none on this matrix); the dependency-closure
claim that `etcetera` pulls only `cfg-if` on the target matrix; `config` 0.15.20's
default feature list; and the maintenance verdicts for `xdg`, `figment`,
`confique`, `twelf` and `confy`. No binary-size or compile-time measurement was
taken by any engine, and none is claimed: the runtime cost of this item is a
bounded number of `stat` calls at process start, and no latency, throughput or
resource figure is reported because none was measured.
