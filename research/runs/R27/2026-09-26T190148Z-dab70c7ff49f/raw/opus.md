# R27 — formatter-config-surface (bundle) — Opus raw research report

Engine: `claude-opus-5-5` (Opus seat, CLI run 2026-09-26). Run directory:
`research/runs/R27/2026-09-26T190148Z-dab70c7ff49f`. Every retrieval date is
**2026-09-26 (UTC)**. Source repositories are read at the programme pins:
`py-launch-blueprint` at `b08bccfb55d05f15e46a83b52c5660b1881d19f5` and
`ts-launch-blueprint` at `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`, via
`git -C <repo> show <sha>:<path> | nl -ba`, so each quoted line number is the
file's own. This leg is independent: no other engine's report for this run was
opened.

Labels used throughout: **executed** = run on this host during this leg, with the
observed output quoted; **read** = read from a pinned source file or a fetched
document; **proposed** = a check or file that P03 must create and run; **carried**
= taken from an accepted decision of another item (R11, R19, R42) and cited.

Host for every executed check: macOS 26.4 on Apple M4 Pro (14 cores, `arm64`).
Toolchains were selected by number through rustup under a restricted
`PATH=$HOME/.cargo/bin:/usr/bin:/bin`, because the default `PATH` resolves
Homebrew's `/opt/homebrew/bin/cargo-fmt` (rustfmt 1.9.0, not a rustup build)
ahead of the rustup proxy — the same hazard R42 recorded
(`research/topics/42-dev-toolchain-provisioning/DECISION.md:734`). Toolchains
exercised: **rustc 1.96.0** (rustfmt `1.9.0-stable (ac68faa20c 2026-05-25)`) and
**rustc 1.94.0** (rustfmt `1.8.0-stable (4a4ef493e3 2026-03-02)`; this is the
host's toolchain named `stable`, which is *not* current stable). Current stable
is **1.98.1**, published 2026-09-03T13:14:07Z (`GET
https://api.github.com/repos/rust-lang/rust/releases?per_page=4`, `tag_name`,
`published_at`), so today's MSRV floor under the fixed policy is **1.96** — the
exact toolchain exercised. 1.98.x was not installed and was not exercised (see
gaps). `lefthook` 2.1.14 (`/opt/homebrew/bin/lefthook`) ran the proposed hook.
Network use was limited to `api.github.com` (repository metadata, file contents
and search), `crates.io/api/v1` and `rustsec.org`. Scratch lived under
`$TMPDIR/r27opus`; nothing was written inside the repository except this file.

### Landscape

**Category decided.** The Rust *source-code formatter* and its surrounding
policy: which tool, which configuration keys, what scope it formats, how its
version is fixed, how the pre-commit hook invokes it, and whether the local
composite gate runs it. Non-Rust formatting (R29), the linter (R28), CI job
topology (R11) and invocation syntax (R42) are out of scope.

**Three-bin map (Rust source formatters).**

| Bin | Candidate | What it is | Evidence |
|---|---|---|---|
| Built-in / first-party toolchain | `rustfmt` + `cargo fmt` | The rustup component maintained by the Rust project's rustfmt team; implements the official Rust Style Guide | rust-lang/rustfmt: 6,974 stars, `archived: false`, `pushed_at` 2026-09-24T13:36:12Z (`GET https://api.github.com/repos/rust-lang/rustfmt`); ships in every rustup `default` profile and as the `rustfmt` component of `minimal` (R42 `DECISION.md:26`) |
| Established industry standard | none distinct from rustfmt | Every surveyed project (below) formats with rustfmt; the style guide itself is authored by the Rust style team and implemented by rustfmt | survey below: 16 of the 19 projects whose workflows were read run `cargo fmt`/`rustfmt` in CI, 0 use another Rust formatter |
| Up-and-comer / niche | `genemichaels` | An independent Rust formatter with different line-breaking philosophy, formats macros | crates.io `recent_downloads` 4,371, `downloads` 83,452, newest 0.12.4 at 2026-08-30T11:22:50Z, license `ISC`; GitHub 104 stars, 14 open issues |
| Up-and-comer / niche | `topiary` (`topiary-cli`) | Tree-sitter-based universal formatter; its query set includes `rust` | crates.io `recent_downloads` 156, `downloads` 5,047, newest 0.7.3 at 2026-01-05T14:38:59Z, license `MIT`; repo (now `topiary/topiary`) 869 stars, `pushed_at` 2026-09-18; `topiary-queries/queries` lists `rust` |
| Adjacent, not a replacement | `prettyplease` | A library that pretty-prints a `syn` AST for *generated* code (build scripts, macros); explicitly not a human-source formatter | crates.io `recent_downloads` 118,494,924, `downloads` 510,823,069, newest 0.3.0 at 2026-07-18T20:47:50Z, `MIT OR Apache-2.0`, `rust_version` 1.71 |
| Adjacent, not a replacement | `leptosfmt`, `rustfmt-wrapper` | `leptosfmt` formats `view!` macro bodies then defers to rustfmt; `rustfmt-wrapper` (Oxide) calls rustfmt from code | `leptosfmt` 7,877 / 102,195, newest 0.1.33 at 2025-01-30; `rustfmt-wrapper` 629,362 / 4,156,124, newest 0.2.1 at 2023-10-23 |
| Distribution artefact, not a candidate | `rustfmt-nightly` crate | The old crates.io publication of rustfmt; not the distribution channel | `recent_downloads` 8,368, newest 1.4.21 at 2020-09-06T02:08:44Z |

Figures: `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`,
`crate.downloads`) and `GET https://crates.io/api/v1/crates/<name>/versions`
(newest `yanked: false`), retrieved 2026-09-26. `dprint-plugin-rustfmt` does not
exist on crates.io (`"crate `dprint-plugin-rustfmt` does not exist"`); dprint's
Rust support is a Wasm/process plugin that *wraps* rustfmt, so it is not a
distinct formatter either. No Biome/Oxfmt-style Rust formatter exists: both of
those tools target web languages.

**Authoritative sources and why each counts.**

- *The Rust Style Guide* (`rust-lang/rust` `src/doc/style-guide/src/README.md`,
  `editions.md`, fetched via the contents API): the normative style owned by the
  Rust style team; it fixes "The maximum width for a line is 100 characters"
  (`README.md:55`) and defines style editions, including 2024's version-sort
  (`editions.md:33-44`).
- *RFC 2437 — rustfmt stability* (`rust-lang/rfcs` `text/2437-rustfmt-stability.md`):
  the accepted RFC that makes formatting output stable for default options on
  stable Rust (`:13`, `:32-38`); the governing source for F103.
- *RFC 3338 — style evolution* (`text/3338-style-evolution.md`): ties style
  changes to style editions and states how `cargo fmt` derives the edition from
  `Cargo.toml` while direct `rustfmt` reads it from `rustfmt.toml` or `--edition`
  (`:39-43`).
- *rustfmt `Configurations.md`* at tag `v1.9.0` and at `main`
  (`repos/rust-lang/rustfmt/contents/Configurations.md`): the maintainers' own
  per-option stability table (86 and 87 options respectively).
- *lefthook documentation and integration tests* (`evilmartians/lefthook`
  `docs/configuration/stage_fixed.md`, `fail_on_changes.md`,
  `tests/integration/hide_unstaged.txt`): the hook manager's own specification;
  latest release v2.1.14 at 2026-09-14.
- The *executed* behaviour of rustfmt 1.8.0 and 1.9.0 on this host, which is
  treated as the final authority where documentation lags (see `style_edition`).

**Practice evidence — 20 well-regarded Rust projects** (stars from `GET
https://api.github.com/repos/<o>/<r>`, `stargazers_count`; files via the contents
API; all 2026-09-26). Selection weights newer, heavily adopted projects (uv,
ruff, zed, deno, tauri) alongside Rust-project-owned references (cargo,
rust-analyzer, rustfmt) and long-standing CLI references (ripgrep, bat, just).

| Project | Stars | `rustfmt.toml` contents (non-comment keys) | `rust-toolchain.toml` channel | CI fmt command |
|---|---|---|---|---|
| tauri-apps/tauri | 111,414 | `max_width = 100`, `newline_style = "Unix"`, `edition = "2024"`, 10 more stable keys | — | `cargo fmt --all -- --check` |
| denoland/deno | 108,526 | `max_width = 80`, `tab_spaces = 2`, `edition = "2024"` (`.rustfmt.toml`) | `1.95.0` + `rustfmt`,`clippy` | via its own lint script (no literal match) |
| zed-industries/zed | 90,933 | `edition = "2024"`, `style_edition = "2024"` | `1.98.1`, `profile = "minimal"` | `cargo fmt --all -- --check` |
| astral-sh/uv | 90,201 | `edition = "2024"`, `style_edition = "2024"` | `1.98.1` | `cargo fmt --all --check` |
| BurntSushi/ripgrep | 68,628 | `max_width = 79`, `use_small_heuristics = "max"`, `edition = "2024"` | — | `cargo fmt --all --check` |
| sharkdp/bat | 60,582 | `# Defaults are used` | — | `cargo fmt -- --check` |
| astral-sh/ruff | 49,803 | `edition = "2024"`, `style_edition = "2024"` | `1.98.0` | `cargo fmt --all --check`; pre-commit `entry: rustfmt` |
| bevyengine/bevy | 48,400 | `use_field_init_shorthand`, `newline_style = "Unix"`, `style_edition = "2021"`; unstable keys commented out "may be uncommented on nightly" | — | via its `ci` tool |
| helix-editor/helix | 46,348 | none | `1.90.0` + `rustfmt` | `cargo fmt --all --check` |
| nushell/nushell | 40,579 | `edition = "2024"` | `1.96.1`, comment: "plan is to be 2 releases behind" | `cargo fmt --all --check` |
| casey/just | 36,026 | `edition = "2024"`, `max_width = 100`, `newline_style = "Unix"`, `tab_spaces = 2`, 2 shorthands | — | `cargo fmt --all -- --check` |
| tokio-rs/tokio | 33,246 | none | — | `rustfmt --check --edition 2021 $(git ls-files '*.rs')` (`ci.yml:846`) |
| tokio-rs/axum | 27,259 | none | — | `cargo fmt --all --check` |
| eza-community/eza | 23,381 | none | `1.90` + components | `cargo fmt --check` |
| rust-lang/rust-analyzer | 16,877 | `edition = "2024"`, `reorder_modules`, `use_small_heuristics = "Max"` | — | `cargo fmt -- --check` |
| clap-rs/clap | 16,725 | none | — | `cargo fmt --check` |
| rust-lang/cargo | 15,521 | `style_edition = "2024"` | — | `cargo fmt --all --check` |
| serde-rs/serde | 10,834 | none | — | none found in workflows |
| rust-lang/rustfmt | 6,974 | `style_edition = "2024"` + unstable keys (runs on nightly) | `nightly-2026-09-23` | not read |
| EmbarkStudios/cargo-deny | 2,434 | none | — | `cargo fmt -- --check --color always` |

Counts from that table: rustfmt config present in 13/20; `max_width` set in 4/20
(79, 80, 100, 100), so 16/20 run the 100-column default; `newline_style = "Unix"`
set in 3/20; **no project on a stable toolchain sets an unstable key** (bevy
comments them out explicitly); a toolchain file exists in 8/20 and **all 8 pin a
number or a dated nightly — none writes `channel = "stable"`**; CI runs a format
*check* in 16 of the 19 projects whose workflows were read (rustfmt's
own workflows were not read), with the remaining 3 either delegating to a
project tool (deno, bevy) or showing none (serde). Bare `cargo fmt`/`cargo fmt --all` hits in zed, ruff, nushell, helix and tauri workflows were not traced (they may be echo text or separate write steps). Hook templates: `cargo-husky`
(crates.io `downloads` 3,630,801) generates `cargo fmt` with `--check` under its
`run-cargo-fmt` feature (`rhysd/cargo-husky` `build.rs:141-142`);
`doublify/pre-commit-rust` (204 stars) defines `entry: cargo fmt`, `args: ["--"]`,
a write-mode hook under the pre-commit framework, which fails the commit when a
hook modifies files; ruff's local hook is `entry: rustfmt`, same framework
semantics. No surveyed Rust template restages automatically.

**Fit.** The template is CLI + library + web service in one Cargo workspace (R11's
carried parameter names the core, web and root packages). A formatter here must
format every member with one config, run without compiling (so it can live in
R11's `hygiene` job), and behave identically on `ubuntu-latest` and
`macos-latest`. rustfmt meets all three; the niche alternatives fail gates or
fit (see member 1).

### Principles and implementation

**Shared requirement and its level.** From `docs/port/DIVERGENCE-ANALYSIS.md:111-116`
(R27 "harmonize = partly"): *one dedicated, deterministic formatter owns source
layout, and the same tool and configuration run from three surfaces — a Justfile
recipe, a pre-commit hook and CI — so that code a contributor formats locally
passes CI unchanged.* Evidence: py `Justfile:203` (`uv run ruff format`),
`lefthook.yml:114` (`ruff format --check`), `.github/workflows/ci.yml:93`
(`ruff format --check .`); ts `Justfile:105` (`pnpm exec oxfmt`),
`lefthook.yml:32-33` (`oxfmt … {staged_files}`, `stage_fixed: true`),
`.github/workflows/ci.yml:85-86` (`just format-check`). Agreement is required at
the **policy** level (one tool, one config, three surfaces, CI authoritative) and,
for the six harmonize-yes rows, at the **value** level only where the tradeoff is
the same in every ecosystem.

**Essential behaviours (observable acceptance criteria).**

1. A1 — One config file governs every workspace member; `cargo fmt --all --check`
   exits 0 on a formatted tree and 1 on an unformatted one.
2. A2 — The config contains only keys the pinned stable rustfmt honours: running
   the check prints **zero** `Warning: can't set` lines. (Executed: an unstable
   key produces the warning but does *not* change the exit status, so without this
   criterion a silently-ignored key goes unnoticed.)
3. A3 — Line endings are LF in every formatted `.rs` file, independent of the
   contributor's OS or git `autocrlf` setting.
4. A4 — Imports are sorted by the formatter, not by a lint.
5. A5 — The pre-commit hook blocks a commit that stages unformatted Rust and never
   modifies a file.
6. A6 — The local composite gate and CI run the same check command.
7. A7 — The toolchain that provides rustfmt is fixed by a checked-in artefact so
   local and CI output agree (RFC 2437 `:13`).

**What must agree versus what may vary.**

| Row | Must agree across py/ts/rs | May vary | rs value |
|---|---|---|---|
| F084 tool | exactly one dedicated formatter | which tool | `rustfmt` via `cargo fmt` |
| F087 width | one width, enforced by the formatter only (py ignores `E501`, `pyproject.toml:171`) | the number: each ecosystem's norm | 100 (Rust Style Guide `README.md:55`); equals ts's 100 |
| F089 line ending | deterministic LF bytes in the repo | — (same tradeoff everywhere) | `newline_style = "Unix"` |
| F091 trailing comma | formatter decides deterministically | whether configurable | not configurable on stable; default `Vertical` |
| F092 import order | formatter-owned | grouping granularity | `reorder_imports` (default `true`), 2024 version-sort |
| F100 exclude scope | one scope, shared by formatter and linter | the mechanism | the Cargo workspace (`[workspace] exclude`) plus `#[rustfmt::skip]` |
| F102 composite | local composite runs what CI runs | recipe name | composite includes `cargo fmt --all --check` |
| F103 pinning | a checked-in artefact fixes the formatter version | the artefact | `rust-toolchain.toml` numeric `channel` |
| F104 hook mode | hook blocks unformatted commits and agrees with CI | block vs write+restage | check-and-block |
| F162 drift guard | nothing the hook excludes can differ from what the tool excludes | whether a test is needed | not needed (no per-tool list); replaced by the A2 unstable-key guard |

**Architectural alternatives compared before choosing mechanisms.**

- *Formatter topology.* (a) One first-party formatter with a checked-in config
  (selected); (b) a multi-language host (dprint) wrapping rustfmt, which adds a
  second tool and a plugin version without changing Rust output — rejected here
  and left to R29, which owns non-Rust formats; (c) an alternative engine
  (genemichaels, topiary), which forfeits the style guide and ecosystem-wide
  consistency — rejected.
- *Exclusion architecture.* (a) A config-level ignore list — **unavailable on
  stable**: `ignore` is unstable (`Configurations.md@v1.9.0`, tracking #3395) and
  executed on 1.96.0 and 1.94.0 it printed `Warning: can't set `ignore = …`,
  unstable features are only available in nightly channel.` and still reported
  the listed file's diff; (b) structural scope — `cargo fmt` formats exactly the
  module trees of workspace members, and `[workspace] exclude` removes a
  directory (executed); (c) item-level `#[rustfmt::skip]` for hand-aligned tables
  or checked-in generated modules (executed on `#[rustfmt::skip] mod generated;`).
  (b)+(c) selected.
- *Hook architecture.* (a) check-and-block; (b) write-and-restage (`stage_fixed`);
  (c) write-and-fail (`fail_on_changes: always`, pre-commit framework semantics).
  (a) selected — see member 5 for why Rust's tradeoff differs from ts's.
- *Version-fixing architecture.* (a) numeric `channel` in `rust-toolchain.toml`;
  (b) `channel = "stable"` plus the style-edition guarantee; (c) floor channel.
  (a) selected — member 4.

**How the design composes (minimal realistic example, executed).** A two-member
workspace (`crates/core`, `crates/web`) with `[workspace] exclude =
["vendor/legacy"]`, `edition = "2024"` and `rust-version = "1.96"` inherited from
`[workspace.package]`, the recommended `rustfmt.toml` (four keys, sha256
`68179803b2e7ab67c91e4c9071b0fb29c219addb94196fbfaffdfad8804d0168`) and a
`rust-toolchain.toml` pinning `1.96.0`. Observed on rustc 1.96.0:

```text
== 1 pre-format check        -> Diff in crates/core/src/lib.rs:1:, crates/web/src/lib.rs:1:  exit=1 warnings=0
== 2 write (cargo fmt --all) -> exit=0 warnings=0
== 3 re-check                -> exit=0 warnings=0
== 4 excluded dir untouched  -> pub fn   legacy( ) {}
== 5 same config on 1.94.0   -> exit=0 warnings=0
== 6 add imports_granularity -> exit=0 warnings=2   (the A2 guard catches it; the exit code does not)
```

`use std::io::{Write, Read};` became `use std::io::{Read, Write};` (A4), and the
edition-2024 let-chain in `crates/web` was formatted rather than rejected. The
proposed lefthook job then ran (executed, lefthook 2.1.14): staging an
unformatted `crates/core/src/lib.rs` gave `Diff in …/crates/core/src/lib.rs:1:`,
`hook exit=1`, and the file's bytes were unchanged (A5); staging a formatted
change gave `✔️ rustfmt (0.17 seconds)`, `hook exit=0`; staging only a non-Rust
file gave `rustfmt (skip) no matching staged files`, exit 0.

**Performance (executed; workload, configuration and instrumentation stated).**
`/usr/bin/time -p rustup run 1.96.0 cargo fmt --all --check`, three consecutive
runs, default config, on copies of two registry crates: `syn` 2.0.119 (97 `.rs`
files, 65,391 lines; `real` 0.33, 0.25, 0.25 s) and `tokio` 1.53.1 (555 `.rs`
files, 139,608 lines on disk, of which `cargo fmt` reached 251 files; `real` 0.26, 0.26, 0.26 s). For syn, `-v` printed 147 `Formatting` lines for 97 files, because some files are visited once per target. Single process, warm file
cache, M4 Pro. This template will be far smaller than either crate, so adding the
check to the composite gate costs well under a second. These are wall-clock
figures on one host, not a cross-tool benchmark.

**Scope hazard observed (executed).** `cargo fmt` only reaches files named by a
`mod` item it can see. On tokio it visited 251 of 555 files (`-v` "Formatting"
lines), because tokio declares many modules inside `cfg_*!` macros — the reason
tokio's CI runs `rustfmt` over `git ls-files '*.rs'` instead (`ci.yml:846`). In the
scratch crate a module declared inside a `macro_rules!` invocation and an orphan
file with no `mod` item were both left unformatted while the check exited 0. The
template must therefore not declare modules inside macros; a proposed guard is
listed under `### Validation strategy`.

**Production usage and reference implementations.** Maintained references for the
selected shape: `astral-sh/uv` and `astral-sh/ruff` (`rustfmt.toml` = `edition` +
`style_edition` 2024, numeric toolchain pin, `cargo fmt --all --check` in CI);
`zed-industries/zed` (same, plus `profile = "minimal"` and `components`); `casey/just`
and `tauri-apps/tauri` (explicit `max_width = 100`, `newline_style = "Unix"`). No
single maintained repository combines all six decisions with lefthook in
check mode; that composition is proven only by the executed scratch example here
(evidence gap recorded under `### Compatibility`).

**BASELINE-REVIEW findings** (follow-on rationale for py, per the harmonize-yes
rows; the same form R01's raw reports use for DIVERGENT rows).

BASELINE-REVIEW: F102 — the local composite gate must run what CI runs — py's `check` composite should add `ruff format --check` (follow-on for py) — py `Justfile:277` omits any format step while py `ci.yml:93` runs `ruff format --check .`, and py `.github/CONTRIBUTING.md:32` documents `just lint # ruff check + format --check` although `Justfile:225-228` shows `lint` runs only `ruff check`; the omission is accidental drift, not a principle.

BASELINE-REVIEW: F089 — repository bytes must be deterministic LF — py's `line-ending = "auto"` (`pyproject.toml:209`) should become `"lf"` (follow-on for py) — auto preserves whatever ending a file already has (executed rustfmt analogue: `newline_style = "Auto"` accepted a CRLF file, exit 0, while `"Unix"` reported `Incorrect newline style`, exit 1); ts already fixes `endOfLine: "lf"` (`.oxfmtrc.json:10`).

### Recommendation

Use **rustfmt through `cargo fmt`**, from the rustup `rustfmt` component of a
**numerically pinned** toolchain, configured by a four-key stable-only
`rustfmt.toml`:

```toml
edition = "2024"
style_edition = "2024"
max_width = 100
newline_style = "Unix"
```

Leave `trailing_comma`, `imports_granularity`, `group_imports` and `ignore`
**unset**, because they are unstable (A2). Pin `rust-toolchain.toml` to
`channel = "1.98.1"` (current stable on 2026-09-26), with R42's
`profile = "minimal"` and `components = ["rustfmt", "clippy"]`, and bump the
channel through a Dependabot `rust-toolchain` entry (R19's recorded trigger).
Scope formatting structurally: the Cargo workspace plus `[workspace] exclude`,
and `#[rustfmt::skip]` on the rare item or checked-in generated module. Write no
path list for rustfmt or the hook, and so need no F162 mirror test. Run
`cargo fmt --all --check` in three places: as the pre-commit job (check-and-block,
`glob: "*.rs"`, no `stage_fixed`), as the first dependency of the composite gate
recipe, and as a step of R11's `hygiene` job. Fixing is `cargo fmt --all` behind
the `format` recipe.

### Members

#### rustfmt (formatter tool, F084)

##### Landscape

Built-in: rustfmt, maintained by the Rust project, rustup component, implements
the official style guide. Established: rustfmt again. There is no second
standard. Up-and-comers: genemichaels (independent engine) and topiary
(tree-sitter, multi-language). Adjacent crates that are not source formatters:
prettyplease, leptosfmt, rustfmt-wrapper. Figures are in the top-level
`### Landscape`.

##### Principles and implementation

Principle: one dedicated formatter owns layout (py `Justfile:203`, ts
`Justfile:105`). py and ts had a real tool choice (ts D-014(1) picked beta Oxfmt
over Biome for multi-format coverage). Rust does not: the style guide is
normative, and rustfmt is its reference implementation, shipped with every
toolchain. R42 fixes the invocation as `cargo fmt` (carried parameter).
`cargo fmt` derives the edition from `Cargo.toml` (RFC 3338 `:41-43`) and formats
every workspace member with `--all`.

##### Dominant choice

`rustfmt` via `cargo fmt`. Every surveyed project that checks formatting in CI
uses it (16 of 19 workflow sets read; the other 3 delegate to a project tool or show none).

##### Qualified shortlist

1. `rustfmt` (rustup component).
2. None other qualifies: the remaining candidates fail gates or are not
   source formatters (next field).

Crate figures for rustfmt: **inapplicable** as a dependency metric, because
rustfmt is distributed as a rustup component, not a crates.io dependency. The
`rustfmt-nightly` crate (last release 1.4.21, 2020-09-06; 8,368 recent downloads)
is a dormant publication, not the channel. Repository figures stand in instead:
6,974 stars; `archived: false`; `pushed_at` 2026-09-24T13:36:12Z; open issues
**718** (`GET https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open`,
`total_count`). Tags reach `v1.10.0` and `v2.0.0-rc.2` (`/tags`). Issue
responsiveness, 10 most recently opened issues (#7114–#7138): 1 received a
comment from an account whose `author_association` is MEMBER/OWNER/COLLABORATOR
(after 0.6 days); 3 were closed without a comment; 6 are open with no qualifying
comment. The median over answered issues is 0.6 days, with 9 "unanswered" by that
rule. Caveat: `author_association` omits rust-lang members whose membership is
private, so this undercounts triage. Advisories: `https://rustsec.org/packages/rustfmt-nightly.html`
returns HTTP 404, so no advisory exists for that name. Maintenance state:
**active** (commits within 2 days; ships with every 6-week Rust release).

Fitness gates, rustfmt: (1) license — `LICENSE-APACHE` and `LICENSE-MIT` both at
the repository root (`/contents/`), dual MIT/Apache-2.0, compatible; (2) MSRV —
ships with each toolchain, so the floor is the toolchain itself; (3) no RustSec
advisory; `unsafe` posture irrelevant to the template because rustfmt is a
developer tool and is not linked into any artefact; (4) runs on
`ubuntu-latest` and `macos-latest` (tier-1 rustup component on both; executed on
macOS arm64 only); Windows support was not checked (informative only); (5) no features, no async runtime;
(6) zero binary-size or compile-time cost to the template, since nothing is
compiled.

##### Excluded by gate

- `genemichaels` — gate 1 caveat and fit: `ISC` is permissive and compatible in
  practice, but the tool implements its own style, not the Rust Style Guide, so
  it fails the "one ecosystem-wide style" principle (RFC 2437 `:24`); 104 stars.
- `topiary` — fit gate: Rust support is a community query set in a
  multi-language tool; 156 recent downloads; the output is not the style guide.
- `prettyplease` — category gate: it formats a `syn` AST for generated code and
  cannot check or rewrite human-edited source files in place.
- `leptosfmt`, `rustfmt-wrapper` — category gate: both delegate to rustfmt.
  `rustfmt-wrapper` is Apache-2.0 only, with its last release on 2023-10-23.

##### Up-and-comers

genemichaels (active: release 2026-08-30) and topiary (active: push 2026-09-18).
Neither shows adoption among the 20 surveyed projects.

##### Fit for this template

It formats CLI, library and web members alike and compiles nothing, so it fits
R11's `hygiene` job. It is already present through R42's `components`.

##### Recommendation

`rustfmt` via `cargo fmt --all`, version supplied by member 4.

##### Ranked runner-up

None credible. If one had to be named, genemichaels, but adopting it would break
parity with every editor's rust-analyzer format-on-save, which calls rustfmt.

##### Tradeoffs

rustfmt cannot format inside most macro invocations, and it cannot reach modules
declared inside macros (executed). Formatting knobs beyond the stable set need
nightly.

##### Parameters

None owned. Assumes `package-manager-invocation` (R42): rustfmt is invoked as
`cargo fmt`, and its presence is tested with `rustup component list --installed`.

##### Migration implications

No install recipe (R42 `DECISION.md:26`). The Justfile, lefthook and CI all call
`cargo fmt`.

##### Validation strategy

Proposed: `rustup component list --installed | grep -q '^rustfmt-'` in the
Justfile's presence check (R42's rule). Then `cargo fmt --version` under the
pinned toolchain must print the version bundled with the pinned channel.

##### Confidence & re-verify trigger

High. Re-verify if the Rust project deprecates rustfmt, or if a style-guide
implementation other than rustfmt becomes a rustup component.

##### Sources

`https://api.github.com/repos/rust-lang/rustfmt` (2026-09-26);
`https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open` (2026-09-26);
`https://api.github.com/repos/rust-lang/rustfmt/issues?state=all&sort=created&direction=desc` and per-issue `/comments` (2026-09-26);
`https://crates.io/api/v1/crates/{rustfmt-nightly,genemichaels,topiary-cli,prettyplease,leptosfmt,rustfmt-wrapper}` and `/versions` (2026-09-26);
`https://rustsec.org/packages/{rustfmt-nightly,genemichaels,prettyplease,leptosfmt,topiary-cli}.html` (all HTTP 404, 2026-09-26);
rust-lang/rfcs `text/2437-rustfmt-stability.md`, `text/3338-style-evolution.md` (2026-09-26);
py `Justfile:203`; ts `Justfile:105`, `docs/port/DIVERGENCE-ANALYSIS.md:112`.

#### rustfmt.toml style surface (F087, F089, F091, F092)

##### Landscape

Stable keys in rustfmt 1.9.0's table (27): `array_width`, `attr_fn_like_width`,
`chain_width`, `disable_all_formatting`, `edition`, `fn_args_layout`,
`fn_call_width`, `fn_params_layout`, `force_explicit_abi`, `hard_tabs`,
`match_arm_leading_pipes`, `match_block_trailing_comma`, `max_width`,
`merge_derives`, `newline_style`, `remove_nested_parens`, `reorder_imports`,
`reorder_modules`, `short_array_element_width_threshold`,
`single_line_if_else_max_width`, `single_line_let_else_max_width`,
`struct_lit_width`, `struct_variant_width`, `tab_spaces`,
`use_field_init_shorthand`, `use_small_heuristics`, `use_try_shorthand`. `main`
adds `hex_literal_case` and lists `style_edition` as stable, while the v1.9.0
document still marks `style_edition` "No". Executed: rustfmt 1.8.0 and 1.9.0 both
accepted `style_edition = "2024"` without a warning, so the binary is the
authority and the v1.9.0 document lags. Unstable keys relevant here:
`trailing_comma` (#3379), `imports_granularity` (#4991), `group_imports`
(#5083), `ignore` (#3395), `imports_layout`, `required_version`.

##### Principles and implementation

- **F087 width.** Principle: one width, enforced only by the formatter. py uses
  88, the Black/ruff norm (`pyproject.toml:148`, with lint `E501` ignored at
  `:171`); ts uses 100 from org precedent (D-014(2), `.oxfmtrc.json:3-6`). Rust's
  style guide fixes 100 (`README.md:55`), and 16/20 surveyed projects run it. The
  value is **not** harmonized to one number across all three repos: 88 is the
  justified Python norm. rs and ts coincide at 100. Writing `max_width = 100`
  explicitly changed nothing (executed: exit 0 after adding it) but makes the
  cross-repo value visible for audit. py's own rationale for explicit values
  ("prevents silent drift if defaults change", `pyproject.toml:204-205`) is
  already met in Rust by the style-edition guarantee.
- **F089 line ending.** Principle: deterministic LF. `newline_style = "Unix"`
  (executed: a CRLF file gave `Incorrect newline style in …/crlfmod.rs`, exit 1;
  under `"Auto"` the same file passed, exit 0). The same tradeoff holds in every
  ecosystem, so this is a harmonize-yes **shared value**: LF (see
  BASELINE-REVIEW F089).
- **F091 trailing comma.** `trailing_comma` is unstable (executed warning:
  `can't set `trailing_comma = Never`, unstable features are only available in
  nightly channel.`). The stable default, `Vertical`, puts a trailing comma after
  the last element of every multi-line list (executed: `pub struct S { pub a: u32,
  pub b: u32 }` became multi-line with `pub b: u32,`). That is the behaviour
  ts's `es5` approximates. Like py, whose ruff formatter has no option, rs
  configures nothing, and the principle "the formatter decides" holds.
- **F092 import ordering.** Formatter-owned, as in ts (`sortImports: true`,
  `.oxfmtrc.json:13`). No clippy lint that orders imports was found (unverified against the full clippy lint list; R28 owns clippy), so py's lint-rule shape
  (`"I"`, `pyproject.toml:153`) has no Rust mechanism. `reorder_imports` defaults
  to `true` and is stable. Style edition 2024 switches to version-sort
  (`editions.md:44`). Grouping (`group_imports`) and merging
  (`imports_granularity`) are unstable and are left unset. This is a
  harmonize-yes row whose shared value is the **ownership** — the formatter sorts
  imports — which ts already follows and py can adopt by moving isort into
  `ruff format`'s pipeline (follow-on, not decided here).
- `edition = "2024"` and `style_edition = "2024"` make bare `rustfmt` callers
  (editor plugins, ruff-style pre-commit entries) parse and style exactly as
  `cargo fmt` does. Executed: bare `rustfmt --check` on a let-chain file with no
  config failed `error: let chains are only allowed in Rust 2024 or later`; with
  `edition = "2024"` in `rustfmt.toml` it parsed and reported only a layout diff.

##### Dominant choice

A small stable-only file: `edition` + `style_edition` (uv, ruff, zed, cargo),
optionally plus `max_width`/`newline_style` (just, tauri, bevy).

##### Qualified shortlist

1. Four keys: `edition`, `style_edition`, `max_width = 100`,
   `newline_style = "Unix"` (recommended).
2. Two keys: `edition` + `style_edition` only (uv/ruff/zed shape). This leaves line
   endings as `Auto`.
3. No file at all (bat, tokio, axum, clap shape). Bare `rustfmt` then misparses
   2024 syntax.

Crate figures: **inapplicable** — configuration keys, not crates.

##### Excluded by gate

Any config that sets `trailing_comma`, `imports_granularity`, `group_imports`,
`ignore`, `wrap_comments`, `format_code_in_doc_comments` or `unstable_features`
fails the stable-Rust constraint. Executed: each such key is warned about and
ignored on 1.94.0 and 1.96.0.

##### Up-and-comers

Stabilization of `imports_granularity` (#4991) and `group_imports` (#5083)
would allow py-like grouping; they are not stable today.

##### Fit for this template

Four keys and zero nightly dependence. The keys are identical for every member.
CI on both OSes produces byte-identical LF output.

##### Recommendation

The four-key file quoted under `### Recommendation`.

##### Ranked runner-up

The two-key uv/ruff/zed file. It is the closest match to what leading projects
use, but it gives up the explicit LF guarantee.

##### Tradeoffs

Duplicating `edition` in `rustfmt.toml` must be bumped alongside `Cargo.toml` at
the next edition. The drift is harmless for `cargo fmt`, which passes the Cargo
edition. Pinning `style_edition` decouples style migration from the edition,
which the style guide explicitly allows (`editions.md:8-11`).

##### Parameters

Assumes `rust-edition = 2024`. No owned parameter.

##### Migration implications

Add root `rustfmt.toml` (four keys). No per-crate config files.

##### Validation strategy

Executed: A1–A4 on the scratch workspace (see `### Principles and implementation`).
Proposed in P03: the same commands against the real template.

##### Confidence & re-verify trigger

High. Re-verify when `imports_granularity`, `group_imports`, `trailing_comma` or
`ignore` is stabilized, or when a new style edition ships.

##### Sources

`repos/rust-lang/rustfmt/contents/Configurations.md?ref=v1.9.0` and `main`
(2026-09-26); `rust-lang/rust` `src/doc/style-guide/src/README.md:55`,
`editions.md:1-44` (2026-09-26); survey files listed in `### Landscape`
(2026-09-26); py `pyproject.toml:148,153,171,204-209`; ts
`.oxfmtrc.json:3-13`.

#### format scope and exclusion (F100, F162)

##### Landscape

Mechanisms: config `ignore` (unstable); Cargo workspace membership and
`[workspace] exclude`; `#[rustfmt::skip]` on items and `mod` declarations; running
bare `rustfmt` over a file list (tokio). Clippy has no path-exclude
configuration either — `clippy.toml` configures lint thresholds, not paths. R28
owns that question and remains open.

##### Principles and implementation

Principle (py `pyproject.toml:180`, one shared list): nothing is excluded from one
tool that the other still checks, and no list can drift. On stable Rust the
structural scope *is* shared: `cargo fmt --all` operates on the workspace members' module trees (executed), and `cargo clippy --workspace` compiles the same members (read from Cargo's workspace semantics; not executed here, because clippy is absent from the local 1.96.0). Executed:
`[workspace] exclude = ["vendor/legacy"]` left `pub fn   legacy( ) {}`
untouched, while both members were formatted. `#[rustfmt::skip] mod generated;`
left the generated file untouched. The ts F162 test exists only because ts keeps
a lefthook `exclude` list that must mirror each tool's `ignorePatterns`
(`tests/repo-hygiene.test.ts:76-99`). This corrects the framing in the prompt's MEDIUM question and in `docs/port/DIVERGENCE-ANALYSIS.md:116`: the ts test does not compare the formatter's list with the linter's list. It compares each lefthook job's `exclude` with that same tool's `ignorePatterns` (`.oxfmtrc.json` for `format`, `.oxlintrc.json` for `lint`, `:94-99`), because oxfmt exits 2 when every path it receives is ignore-listed (`:76-80`). The rs hook passes no file list
(`cargo fmt --all --check`), so there is no list to mirror.

For both R28 outcomes:
- (i) R28 uses no path list (expected, because clippy has none). Then the Cargo
  workspace is the single shared scope. That is py's principle realized
  structurally, and no F162 test is needed.
- (ii) R28 introduces a per-tool path mechanism (for example, a lefthook
  `exclude` on the clippy job). Then a repo-hygiene test must assert that the
  job's `exclude` set equals the directories named in `[workspace] exclude` —
  the ts F162 pattern, re-keyed to Cargo's list.

##### Dominant choice

Structural scope. None of the 12 surveyed `rustfmt.toml` files of projects on a
stable toolchain uses `ignore`.

##### Qualified shortlist

1. Workspace scope + `[workspace] exclude` + `#[rustfmt::skip]` (recommended).
2. tokio's `rustfmt --check --edition … $(git ls-files '*.rs')`. It reaches
   macro-hidden modules, but it violates R42's `cargo fmt` invocation rule, and it
   re-introduces an edition flag outside `Cargo.toml`.

Crate figures: **inapplicable** — Cargo and rustfmt mechanisms, not crates.

##### Excluded by gate

Config `ignore = [...]` fails the stable-only constraint (executed warning and
no effect).

##### Up-and-comers

Stabilization of `ignore` (#3395).

##### Fit for this template

The template has no vendored or generated `.rs` files planned. If R71's generated
OpenAPI types are checked in, they take `#[rustfmt::skip]` on their `mod`
declaration, or are simply formatted.

##### Recommendation

No exclude list anywhere. The scope is the Cargo workspace. A rare skip uses
`#[rustfmt::skip]`. Declare no modules inside macros.

##### Ranked runner-up

The `git ls-files` sweep, if the template ever must declare modules inside
macros. That case needs a CONFLICT against R42's invocation rule first.

##### Tradeoffs

Files unreachable from a crate root (orphans, macro-declared modules) are
silently skipped (executed: the check exited 0 with both left unformatted).
The proposed orphan guard under `### Validation strategy` covers this.

##### Parameters

None owned. Assumes R42's `cargo fmt` invocation.

##### Migration implications

No `ignore` key in `rustfmt.toml`, no lefthook `exclude` on the fmt job, and no
F162 test file. The unstable-key guard (A2) replaces F162 as the drift check.

##### Validation strategy

Executed: the workspace-exclude and `#[rustfmt::skip]` probes above. Proposed:
the hygiene step compares `git ls-files '*.rs'` with the files `cargo fmt --all
-- --check -v` reports as `Formatting`, and fails on any tracked `.rs` file that
is not reached.

##### Confidence & re-verify trigger

Medium-high. Re-verify when R28 decides clippy's config shape, or when `ignore`
stabilizes.

##### Sources

`Configurations.md@v1.9.0` (`ignore`, #3395); tokio `ci.yml:843-847`
(2026-09-26); ts `tests/repo-hygiene.test.ts:76-99`, `lefthook.yml:18-33`,
`.oxlintrc.json:69`; py `pyproject.toml:180-189`, `lefthook.yml:106-114`.

#### toolchain channel pin (F103, F190)

##### Landscape

Artefacts that can fix the formatter version: a `rust-toolchain.toml` numeric
`channel`; `channel = "stable"`; a dated nightly; or CI-only action inputs. The
unstable `required_version` key asserts a version but cannot obtain one (RFC
2437 `:83`).

##### Principles and implementation

Principle (py `pyproject.toml:78` + `uv.lock`; ts `package.json:55` exact `oxfmt`
pin + `pnpm-lock.yaml`): *a checked-in artefact fixes the formatter version so
local and CI output agree.* RFC 2437 states that exact goal (`:13`). In Rust the
artefact is `rust-toolchain.toml`. R42 fixed `profile = "minimal"` and
`components = ["rustfmt", "clippy"]`, and left `channel` to this item (R42
`DECISION.md:26`). R11 installs nothing "beyond what `rust-toolchain.toml`
triggers" (R11 `DECISION.md:298`), so a numeric pin reaches CI without an action
input. The MSRV floor is tested separately by R11's `msrv-floor` job, so the
development channel is **not** the floor (F190 baseline review). ts's reason for
exact-pinning, Oxfmt's beta status (D-014(1)), does not transfer. The reason that
does transfer is reproducibility: rustfmt output is stable for default options
anyway, but clippy's lint set changes every release, and both come from the same
channel.

##### Dominant choice

A numeric pin: 8/8 surveyed toolchain files (uv `1.98.1`, zed `1.98.1`, ruff
`1.98.0`, nushell `1.96.1`, deno `1.95.0`, helix `1.90.0`, eza `1.90`, rustfmt a
dated nightly). None uses `stable`.

##### Qualified shortlist

1. `channel = "1.98.1"` (current stable), bumped by Dependabot's `rust-toolchain`
   ecosystem (recommended).
2. `channel = "stable"`. Every contributor gets the newest toolchain; formatting
   is still stable within `style_edition`, but new clippy lints can turn CI red
   without any repository change.
3. `channel = "1.96"` (the floor). Rejected by the F190 baseline review: it would
   put local builds on the MSRV compiler.

Crate figures: **inapplicable** — a toolchain channel, not a crate.

##### Excluded by gate

Nightly or dated-nightly channels fail the stable-only constraint.

##### Up-and-comers

None.

##### Fit for this template

A template ages after generation. A numeric pin plus a Dependabot
`rust-toolchain` entry keeps it current through reviewed PRs. R19 documents that
Dependabot updates "Versioned toolchains such as `channel = "1.xx.yy"`" (R19
`DECISION.md:166`).

##### Recommendation

```toml
[toolchain]
channel = "1.98.1"
profile = "minimal"
components = ["rustfmt", "clippy"]
```

##### Ranked runner-up

`channel = "stable"` (R42's placeholder, R42 `DECISION.md:439`): zero maintenance,
but the local and CI toolchains are only as aligned as each machine's last
`rustup update`.

##### Tradeoffs

A numeric pin costs a toolchain download on runners whose preinstalled stable
differs (unmeasured; R11 `DECISION.md:383` records the same gap), plus one bump
PR per release. Rustup attempts to install a missing pinned channel on first use (partial evidence, executed: with clippy missing it printed `info: syncing channel updates for 1.96.0-aarch64-apple-darwin` before the sandbox blocked the write); a completed auto-install was not observed.

##### Parameters

Assumes `msrv-policy` (floor 1.96 today, tested by R11's `msrv-floor` job, not by
this channel). No owned parameter. No CONFLICT: R42's `profile` and `components`
are kept unchanged.

##### Migration implications

Set `channel = "1.98.1"` in R42's `rust-toolchain.toml`. This fires R19's
recorded re-verify trigger ("R27 fixes a numeric `rust-toolchain.toml` channel
(add a `rust-toolchain` entry)", R19 `DECISION.md:172`). R19, not this item,
adds the entry.

##### Validation strategy

Executed (with `channel = "1.96.0"`, because 1.98.1 was not installed):
`rustup show active-toolchain` printed `1.96.0-aarch64-apple-darwin (overridden
by '…/final/rust-toolchain.toml')`, and `cargo fmt --version` printed `rustfmt
1.9.0-stable (ac68faa20c 2026-05-25)`. Two deviations: the probe used
`components = ["rustfmt"]`, because the local 1.96.0 lacks `clippy` and rustup's
install attempt was blocked by the sandbox (`could not create temp file
…/.rustup/tmp/…`); and the pinned value itself is untested here. Proposed: repeat
with `1.98.1` and both components on `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

Medium. Re-verify at each Rust release (the bump PR), or if R42 changes
`profile`/`components`.

##### Sources

rust-lang/rfcs `text/2437-rustfmt-stability.md:13,83` (2026-09-26);
`https://api.github.com/repos/rust-lang/rust/releases?per_page=4` (2026-09-26);
survey toolchain files (2026-09-26); R42 `DECISION.md:26,439`; R11
`DECISION.md:298,383`; R19 `DECISION.md:166,172`; py `pyproject.toml:78`; ts
`package.json:55`.

#### pre-commit hook mode (F104)

##### Landscape

Three modes exist. Check-and-block (py `lefthook.yml:114`; cargo-husky
`build.rs:141-142`). Write-and-restage (ts `lefthook.yml:32-33`, `stage_fixed:
true`). Write-and-fail (the pre-commit framework's semantics for
`doublify/pre-commit-rust`'s `entry: cargo fmt` and ruff's `entry: rustfmt`;
lefthook's `fail_on_changes: always`). lefthook hides unstaged changes during
`pre-commit` (`tests/integration/hide_unstaged.txt`), and `stage_fixed` runs
`git add` on `{staged_files}` after filters (`docs/configuration/stage_fixed.md`).

##### Principles and implementation

Principle: the hook never lets unformatted code into a commit, and it agrees
with CI. Both py and ts satisfy it. ts's write mode is safe because `oxfmt`
accepts `{staged_files}`, so it rewrites only staged files. That is **not true
for Rust under R42**: rustfmt must be invoked as `cargo fmt`. Executed:
`cargo fmt -- --check src/zeta.rs --` still reported a diff in the unnamed
`src/crlfmod.rs`, and reported `zeta.rs` twice — `cargo fmt` always formats the
whole workspace. A write-mode hook would therefore rewrite files outside the
commit that `stage_fixed` never stages, leaving new working-tree changes. The
tradeoff differs from ts's, so the harmonize-yes row agrees at the principle
level, not the mode: rs blocks, ts may keep restaging.

##### Dominant choice

Among Rust hook templates, check mode (cargo-husky) or write-and-fail
(pre-commit framework hooks). None restages.

##### Qualified shortlist

1. `cargo fmt --all --check`, check-and-block (recommended).
2. `cargo fmt --all` with `fail_on_changes: always`. It fixes and fails, and the
   contributor re-stages, but it still mutates unstaged files.
3. `cargo fmt --all` + `stage_fixed: true`. It restages only the staged paths and
   leaves other rewrites unstaged.

Crate figures: **inapplicable** — hook configuration, not a crate.

##### Excluded by gate

A bare `rustfmt {staged_files}` hook would scope correctly, but it violates R42's
invocation rule (carried parameter), so it is excluded rather than raised as a
CONFLICT: the check mode achieves the principle without it.

##### Up-and-comers

None.

##### Fit for this template

The check costs about 0.15–0.3 s (executed hook runs: 0.17–0.31 s), so blocking
adds no noticeable delay. `just format` is the one-step fix.

##### Recommendation

```yaml
pre-commit:
  jobs:
    - name: rustfmt
      glob: "*.rs"
      run: cargo fmt --all --check
```

The `jobs` form is used because ts uses it (`lefthook.yml:23`). The hook tier and
its neighbours belong to R37/R40.

##### Ranked runner-up

Write-and-fail (`fail_on_changes: always`), for teams that prefer the formatter
to leave fixed files behind.

##### Tradeoffs

The contributor runs `just format` and re-stages by hand. In exchange, the hook
never changes files, and its output equals CI's.

##### Parameters

Assumes R42's `package-manager-invocation` (no runner prefix; `cargo fmt`).

##### Migration implications

The `lefthook.yml` fmt job as above: no `exclude`, no `stage_fixed`.

##### Validation strategy

Executed with lefthook 2.1.14. Unformatted staged file: `Diff in
…/crates/core/src/lib.rs:1:`, `hook exit=1`, bytes unchanged. Formatted staged
change: `✔️ rustfmt (0.17 seconds)`, exit 0. Non-Rust-only commit: `rustfmt
(skip) no matching staged files`, exit 0. Proposed: the same three cases through
`git commit` with installed hooks on both CI OSes.

##### Confidence & re-verify trigger

High. Re-verify if R42's invocation rule changes to allow bare `rustfmt`, which
would make file-scoped write mode viable.

##### Sources

`evilmartians/lefthook` `docs/configuration/stage_fixed.md`,
`fail_on_changes.md`, `tests/integration/hide_unstaged.txt`,
`/releases/latest` (v2.1.14) (2026-09-26); `rhysd/cargo-husky` `build.rs:135-142`
(2026-09-26); `doublify/pre-commit-rust` `.pre-commit-hooks.yaml` (2026-09-26);
astral-sh/ruff `.pre-commit-config.yaml:47-54` (2026-09-26); py
`lefthook.yml:112-114`; ts `lefthook.yml:18-33`.

#### composite recipe placement (F102)

##### Landscape

Placement options: (a) the composite gate recipe includes a format check (ts
`Justfile:178`, `@all: format-check lint typecheck test`); (b) it omits one (py
`Justfile:277`); (c) a format check lives only in CI.

##### Principles and implementation

Principle: the local composite runs what CI runs, so "all green locally" predicts
CI. py's omission is drift, not design: py CI runs `ruff format --check .`
(`ci.yml:93`), and py `CONTRIBUTING.md:32` claims `lint` includes it while
`Justfile:225-228` shows it does not (BASELINE-REVIEW F102). Measured cost is
negligible (0.25–0.33 s on 65k–140k-line crates, executed). Harmonize-yes shared
value: include the format check.

##### Dominant choice

Include it (ts precedent; 16 of 19 surveyed Rust projects run a format check in CI; cost is sub-second).

##### Qualified shortlist

1. Include `format-check` as the first dependency of the composite gate
   (recommended). A formatting failure is the cheapest to report, so it reports
   first.
2. Omit it (py shape). This rejects the principle.

Crate figures: **inapplicable** — recipe placement.

##### Excluded by gate

None.

##### Up-and-comers

None.

##### Fit for this template

It compiles nothing, so it runs before clippy/test in the composite, and as a
`hygiene` step in CI (R11).

##### Recommendation

```just
# Format Rust sources in place
format:
    cargo fmt --all

# Check Rust formatting without writing (CI parity)
format-check:
    cargo fmt --all --check
```

The composite gate recipe lists `format-check` first. Its other dependencies and
its name (`check` versus `all`) belong to their owning items.

##### Ranked runner-up

A CI-only check. It loses local predictability.

##### Tradeoffs

None material. The step adds under a second.

##### Parameters

Assumes `ci-job-structure` (R11): the check is a step of `hygiene`.

##### Migration implications

`Justfile`: add the `format` and `format-check` recipes, plus composite membership.
CI: `cargo fmt --all --check` step in `hygiene`.

##### Validation strategy

Executed: timing above, and exit semantics (1 on diff, 0 clean). Proposed: `just
<composite>` fails on an unformatted file before any compile starts.

##### Confidence & re-verify trigger

High. Re-verify if R11 moves non-compiling checks out of `hygiene`.

##### Sources

py `Justfile:225-228,277`, `.github/workflows/ci.yml:93`,
`.github/CONTRIBUTING.md:32`; ts `Justfile:100-116,176-178`,
`.github/workflows/ci.yml:85-86`; R11 parameter (`inputs/parameters.json`).

### Compatibility

The members are one tool (rustfmt) and its surrounding files, so version
compatibility reduces to "the pinned channel carries rustfmt, and the config uses
only that rustfmt's stable keys". Shared adopters of the core combination
(stable-only `rustfmt.toml` with `edition`/`style_edition` 2024 + numeric
`rust-toolchain.toml` + `cargo fmt --all --check` in CI): `astral-sh/uv`,
`astral-sh/ruff` and `zed-industries/zed` (files in `### Landscape`). The full
composition — including lefthook check mode and `[workspace] exclude` — was
executed together only in this leg's scratch workspace, on rustc 1.96.0 (all
steps) and 1.94.0 (config check). Version matrix actually observed:

| Toolchain | rustfmt | 4-key config warnings | check on formatted tree |
|---|---|---|---|
| 1.94.0 | 1.8.0-stable | 0 | exit 0 |
| 1.96.0 | 1.9.0-stable | 0 | exit 0 |
| 1.98.1 | not installed | not exercised | not exercised |

Evidence gap: no maintained public repository was found that combines rustfmt
check mode with lefthook specifically.

### Parameters

R27 owns no parameter (prompt `## Couplings`, `- owns:` empty).

- assumes rust-edition = 2024
- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes license = MIT OR Apache-2.0
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes package-manager-invocation = invoke a tool whose executable is named cargo-<sub> as cargo <sub>, including the rustup components rustfmt and clippy as cargo fmt and cargo clippy; invoke every other tool as a bare executable resolved on PATH; write Cargo's own built-in subcommands as they are; use no provisioner, runner or package-manager prefix in any Justfile recipe or lefthook job, and define no Cargo alias in the template; test presence by acquisition channel - command -v <executable> for a tool installed from crates.io or from a release, and the active toolchain's component state via rustup component list --installed for a tool rustup installs, never command -v for a rustup component

- assumes ci-job-structure = one .github/workflows/ci.yml whose jobs are partitioned by whether a check compiles Rust, never by which check it is. Tier 0 is a single always-run detector job named plan on ubuntu-latest carrying no toolchain, no cache action and no target/ directory: after actions/checkout with fetch-depth 0 and persist-credentials false it runs one bash step under set -euo pipefail that computes git diff --no-ext-diff --no-textconv --no-renames --name-only from BASE_SHA to HEAD, so the path list includes the source side of every rename, with BASE_SHA read from github.event.pull_request.base.sha through the step env block, treats every file name as data and never evaluates it, and writes exactly four job outputs - code, web, workflows, docs - as the literal strings true or false and never as any other value, publishing true on all four for every event whose name is not pull_request so that pushes to main and merge-queue entries are never skip-gated. Every output that gates a required check fails closed, whether the check compiles or not, so a path nobody anticipated runs the gate rather than skipping it, and the body makes that structural - code and web start true and are set false only on affirmative proof that every changed path is skippable, a grep exit of 1, never on a match, an error or a test cut short, and workflows and docs likewise start true and are set false only on a grep exit of 1, and every path test reads the whole list from a here-string rather than through a pipeline whose early-exiting grep can end it under pipefail: code is the negation of a skip-list of paths that cannot affect a compile, a package or an installed artifact, with every entry of the package include allow-list R49 owns forced non-skippable because each of them is a packaging input, and with no skip-list entry allowed to match a file any package contains - so the Markdown entry matches only root-level files. Markdown under docs/ and .github/ISSUE_TEMPLATE/ stays skippable through those directory entries, and no entry matches anything under src/ or a member directory, because src/ is packaged and a workspace member that names no include list packages its whole directory; web is fail-closed too - every change that sets code also sets web, because the web member depends on the core member and the root package that hosts the serve binary depends on every member, and web is additionally set by any change under the web member's directory, so the paths R69 names are a subset of the rule rather than its whole; workflows gates only workflow-lint and its pattern contains the whole input of every check in that job by construction - the workflow files, the local actions they call, which live under .github/actions/, and the workflow linter's own config file; docs keys on the prose tree and gates no job in this file, because R82's link check is a step of hygiene, so it is kept only as a literal output that no check whose input another item declares may consume; and a fifth key is added only when some job would be skipped by it that code does not already skip, and is itself written as the negation of a skip-list, or, if it gates only a job that compiles nothing, as a pattern containing that job's whole input. Tier 1 is the checks that compile nothing, each its own cheap job carrying no cache step: hygiene, which deliberately has no needs edge so that a formatter failure still reports on a pull request whose compile tier is skipped, and which hosts every non-compiling check whose input no key contains, R29's non-code formatting slot and R20's two action-pin checks included, as is R82's link check, while R82's rustdoc part is the doc build step of check; and workflow-lint, gated on workflows, which hosts only checks whose whole input is the workflow tree. Tier 2 is the checks that compile: ONE job named check per entry of target-os-matrix through a strategy matrix over os alone with fail-fast false - never a matrix dimension over Cargo features, because the cache action keys on the job id and not on matrix values - running clippy with the feature off, clippy with the feature on, a no-default-features check of the facade, cargo test with the feature off scoped by -p to the non-web packages so the feature-off property is proven rather than assumed, cargo test over the workspace with the feature on, a build of the serve binary and a doc build, as ordered steps sharing one target/, every cargo command carrying --locked, where each cargo step runs under !cancelled() so that one failing step does not hide the results of the steps after it; plus msrv-floor, a separate single-runner job rather than a matrix leg of check because the floor needs only the declared-floor check Cargo's own CI guide shows rather than check's whole step list, verifying the declared rust-version on ubuntu-latest, which widens to every runner by substituting the matrix os expression into runs-on if the owner answers the open F033 cross-product question that way; plus install-smoke, R50's one ubuntu-latest job, whose web leg is a step conditioned on the web output. Every gated job consumes the detector through needs: plan and a POSITIVE predicate of the form needs.plan.outputs.KEY == 'true', never a negated one, and carrying no status function, so that the platform's implicit success() skips every gated job whenever plan fails or is skipped, under either polarity; the positive form is kept for consistency with R18, R86 and the dorny/paths-filter example, because the one remaining empty-key case, a misspelled output name, is caught by lint on the consumer side and by the detector cases on the producer side, and because a consumer that opts out of skip propagation with always() or !cancelled() must read plan's result, never plan's outputs, as its condition; actionlint type-checks the output name and the needs edge but does NOT reject the negated form, so that rule travels in prose to every consumer rather than being left to lint. A failed plan skips every gated job and skipped is a successful check status, so a failed plan must itself fail a required check; this file hands that constraint on without deciding how it is met: either plan is itself a required check, or an aggregate, if R12 chooses one, includes plan in its needs and treats a failure or cancelled result of plan as failure. ci.yml carries no trigger-level paths or paths-ignore filter of any kind, because a workflow skipped by path filtering leaves its checks Pending and blocks merging while a job skipped by a conditional reports Success; its triggers are pull_request and push restricted to main, plus merge_group so a queue's speculative merge still reports; it declares an empty workflow-level permissions map with a per-job re-grant whose scopes are R08's; and it declares workflow-level concurrency with cancel-in-progress true on a group keyed to the workflow plus the pull-request number, falling back to the commit sha when there is no pull request, so a force-push cancels the superseded pull-request run while consecutive pushes to main never cancel one another and keep populating the cache. This file holds no aggregate required-status job, which is R12's, and no release, secret-scanning, devcontainer or AI-review job, which are separate workflow files. Every further check arrives as a named slot under one rule: a check that compiles nothing is a step of hygiene, or its own cheap job behind a path gate only when that gate's key contains the whole input of every check in the job; a check that compiles what check already compiles is an ordered step of check; and a check needing its own toolchain, its own runner or a target/ it must not share becomes its own job with needs: plan and a positive predicate, counted against a ceiling of roughly six cache-bearing job ids per runner, where the budget arithmetic is the sum over cache-bearing job ids of that job id's runner count. Any single-job workflow file that compiles no Rust, R17's scanner included, lands on ubuntu-latest, because it neither shares nor claims a target/ cache entry and gains nothing from a second runner

No `CONFLICT:` lines. Every recommendation fits the consumed values: `cargo fmt`
invocation (R42), a non-compiling `hygiene` step (R11), and R42's `profile` and
`components`.

### Migration implications

- `rustfmt.toml` (new, repository root): the four keys under `### Recommendation`.
- `rust-toolchain.toml` (R42's file): set `channel = "1.98.1"`; keep
  `profile = "minimal"`, `components = ["rustfmt", "clippy"]`.
- `Justfile`: add `format` (`cargo fmt --all`) and `format-check`
  (`cargo fmt --all --check`); list `format-check` first in the composite gate.
- `lefthook.yml`: a `pre-commit` job `rustfmt`, `glob: "*.rs"`, `run: cargo fmt
  --all --check`, no `exclude`, no `stage_fixed`.
- `.github/workflows/ci.yml`: a `cargo fmt --all --check` step in R11's `hygiene`
  job (R11 owns placement).
- `Cargo.toml`: use `[workspace] exclude` for any directory that must not be
  formatted; the template needs none today.
- `.github/dependabot.yml`: R19 adds a `rust-toolchain` entry (R19's recorded
  trigger).
- No F162 test file; add the unstable-key guard and the orphan guard below
  (proposed).
- Follow-on (not this item): py adds `ruff format --check` to `check` and moves to
  `line-ending = "lf"` (BASELINE-REVIEW F102, F089).

### Validation strategy

Executed on this host (scratch `$TMPDIR/r27opus/final`, rustc 1.96.0 unless noted):

```bash
cargo fmt --all --check            # before formatting: exit=1, diffs in both members, 0 warnings
cargo fmt --all                    # exit=0, 0 warnings
cargo fmt --all --check            # exit=0, 0 warnings; vendor/legacy untouched
rustup run 1.94.0 cargo fmt --all --check   # exit=0, 0 warnings (the host's 'stable' toolchain)
lefthook run pre-commit --no-tty   # unformatted staged: exit=1, file unchanged; formatted: exit=0
```

Planned (P03, both CI OSes, pinned 1.98.1):

1. `cargo fmt --all --check` → exit 0 on the template tree.
2. Unstable-key guard (replaces F162): `out=$(cargo fmt --all --check 2>&1 >/dev/null); ! grep -F "can't set" <<<"$out"`,
   which must pass. Adding `imports_granularity = "Crate"` must make it fail
   (executed analogue: 2 warnings, exit 0 from `cargo fmt`).
3. Line endings: write a CRLF copy of one module; `cargo fmt --all --check` →
   `Incorrect newline style`, exit 1.
4. Hook: a `git commit` staging an unformatted `.rs` file is rejected, and the
   file's hash is unchanged.
5. Orphan guard: every `git ls-files '*.rs'` path appears among `cargo fmt --all --
   --check -v` `Formatting` lines (catches macro-declared or orphan modules).
6. `rustup show active-toolchain` names `rust-toolchain.toml` as the override on
   both runners.

### Confidence & re-verify trigger

Confidence: **high** for the tool, the stable/unstable split, the hook mode and
the composite placement (each executed). **Medium** for the channel pin (the
value 1.98.1 was not exercised; runner download cost unmeasured). **Medium-high**
for exclusion scope (depends on R28).

Re-verify on the earliest of: 2027-03-26; stabilization of `ignore`,
`imports_granularity`, `group_imports` or `trailing_comma`; a new style edition;
R28's decision on clippy exclusion; any change to R42's invocation rule or R11's
`hygiene` job; lefthook changing `stage_fixed` or unstaged-hiding semantics.

Gaps recorded:
- G1: Not exercised on rustc 1.98.x or on `ubuntu-latest`. All runs were macOS
  arm64, on 1.94.0 and 1.96.0.
- G2: The toolchain-pin probe used `components = ["rustfmt"]`, because clippy is
  absent on the local 1.96.0 and the sandbox blocked rustup installs.
- G3: The download cost of a numeric pin on GitHub runners was not measured.
- G4: The issue-responsiveness figure undercounts rust-lang maintainers whose org
  membership is private.
- G5: No public repository combining lefthook check mode with rustfmt was found.
- G6: The doc/binary discrepancy on `style_edition` stability was resolved
  empirically for 1.8.0/1.9.0 only.
- G7: deno and bevy CI format steps were not traced through their wrapper tools.

### Sources

All retrieved 2026-09-26 unless marked as a pinned source read.

- `https://api.github.com/repos/rust-lang/rust/releases?per_page=4` — current stable 1.98.1.
- `https://api.github.com/repos/rust-lang/rustfmt` (+ `/tags`, `/contents/`, `/issues`, `/issues/<n>/comments`) and `https://api.github.com/search/issues?q=repo:rust-lang/rustfmt+is:issue+is:open`.
- `https://api.github.com/repos/rust-lang/rustfmt/contents/Configurations.md?ref=v1.9.0` and `main`.
- `https://api.github.com/repos/rust-lang/rfcs/contents/text/2437-rustfmt-stability.md`, `text/3338-style-evolution.md`.
- `https://api.github.com/repos/rust-lang/rust/contents/src/doc/style-guide/src/README.md`, `editions.md`.
- `https://api.github.com/repos/<o>/<r>` and `/contents/{rustfmt.toml,.rustfmt.toml,rust-toolchain.toml,.github/workflows/*,.pre-commit-config.yaml}` for the 20 surveyed projects in `### Landscape`.
- `https://api.github.com/repos/evilmartians/lefthook/contents/docs/configuration/{stage_fixed,fail_on_changes}.md`, `tests/integration/hide_unstaged.txt`, `/releases/latest`.
- `https://api.github.com/repos/rhysd/cargo-husky/contents/build.rs`; `https://api.github.com/repos/doublify/pre-commit-rust/contents/.pre-commit-hooks.yaml`.
- `https://api.github.com/repos/{andrewbaxter/genemichaels,dtolnay/prettyplease,tweag/topiary}`; `repos/topiary/topiary/contents/topiary-queries/queries`.
- `https://crates.io/api/v1/crates/{rustfmt-nightly,genemichaels,prettyplease,topiary-cli,leptosfmt,rustfmt-wrapper,cargo-husky,dprint-plugin-rustfmt}` and `/versions`.
- `https://rustsec.org/packages/{rustfmt-nightly,genemichaels,prettyplease,leptosfmt,topiary-cli}.html`.
- Pinned source reads: py `b08bccfb…` `pyproject.toml:75-80,145-212`, `Justfile:198-207,223-230,275-278`, `lefthook.yml:105-125`, `.github/workflows/ci.yml:77,93`, `.github/CONTRIBUTING.md:32`; ts `cb1cbcb2…` `.oxfmtrc.json:1-32`, `.oxlintrc.json:69`, `Justfile:100-116,176-180`, `lefthook.yml:18-33`, `package.json:55-56`, `tests/repo-hygiene.test.ts:76-100`, `.github/workflows/ci.yml:85-86`.
- Repository documents: `docs/port/DIVERGENCE-ANALYSIS.md:56,111-116`; `research/topics/42-dev-toolchain-provisioning/DECISION.md:26,298,439,734`; `research/topics/11-ci-workflow-job-structure/DECISION.md:298,383`; `research/topics/19-dependabot-config-shape/DECISION.md:166,172`; run inputs `inputs/prompt.md`, `inputs/parameters.json`.
