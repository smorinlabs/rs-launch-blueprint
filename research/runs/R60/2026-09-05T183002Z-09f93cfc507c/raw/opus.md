# R60 — cli-parsing-framework (bundle, deep) — Opus raw report

Retrieval date for every figure and claim in this report: **2026-09-10** (single
session). Endpoints are named inline. Rust stable at the time of writing is
**1.98.1**, released 2026-09-03 (`GET https://api.github.com/repos/rust-lang/rust/releases/latest`,
`tag_name`, 2026-09-10), so the owner-fixed `msrv-policy` ("stable minus 2 minor
versions") puts this template's declared floor at **rust-version = 1.96** today.
Every MSRV gate below is judged against 1.96.

### Landscape

**Category decided.** The crate (or absence of a crate) that turns `argv` into a
typed command invocation for a Rust binary, plus the surface features that a
parser either supplies or forces the application to hand-write: subcommand
routing, `--help`, `--version`, shell-completion scripts, environment-variable
fallback for options, option scoping across subcommands, and unknown-command
suggestions. In the Rust ecosystem this is the crates.io category
`command-line-interface`.

**Bin 1 — built-in or first-party toolchain.**

| Candidate | What it is | Evidence |
|---|---|---|
| `std::env::args_os()` + hand-rolled parsing | The standard library gives an argument iterator and nothing else: no help, no subcommands, no completion | https://doc.rust-lang.org/std/env/fn.args_os.html, 2026-09-10 |
| `getopts` | POSIX/GNU `getopts` port owned by the `rust-lang` GitHub organization; flag parsing only, no subcommands, no completion | `GET https://api.github.com/repos/rust-lang/getopts` — `stargazers_count` 250, `archived` false, `pushed_at` 2026-07-17T18:35:40Z, 2026-09-10 |
| `clap_lex` (first-party to **clap**, not to the Rust toolchain — listed here only because it is usable standalone; bin 3 is its stricter home) | clap's own argument *lexer*, published separately and usable without clap; no help generation | rosetta table below; `GET https://crates.io/api/v1/crates/clap_lex` — `crate.recent_downloads` 195,864,291, 2026-09-10 |

**Bin 2 — established industry standard.**

| Candidate | Status | Evidence |
|---|---|---|
| `clap` (builder API and `derive` API in one crate) | The category's reference implementation | `GET https://crates.io/api/v1/crates?category=command-line-interface&sort=downloads` ranks `clap` first by all-time downloads in the category (1,119,879,906), 2026-09-10 |
| `clap_complete` | clap's first-party shell-completion generator | `GET https://crates.io/api/v1/crates/clap_complete` — 111,559,662 all-time, 2026-09-10 |
| `clap_mangen` | clap's first-party man-page generator (relevant to the org standard's R9.1, not to any ledger row here) | `GET https://crates.io/api/v1/crates/clap_mangen` — 15,144,881 all-time, 2026-09-10 |
| `structopt` | Superseded: the derive front-end that clap absorbed as `clap_derive` in clap 3 | `GET https://crates.io/api/v1/crates/structopt/versions` — newest unyanked `0.3.26`, `created_at` 2022-01-18; `GET https://api.github.com/repos/TeXitoi/structopt` — `pushed_at` 2024-01-07T23:29:29Z, 2026-09-10 |
| `docopt` | Archived | `GET https://api.github.com/repos/docopt/docopt.rs` — `archived` **true**, `pushed_at` 2021-04-25T07:04:29Z, 2026-09-10 |

**Bin 3 — up-and-comers and minimalists.**

| Candidate | Design | Evidence |
|---|---|---|
| `lexopt` | Minimal, correctness-pedantic argument lexer; no help generation | `GET https://crates.io/api/v1/crates/lexopt` — 12,530,446 all-time, newest unyanked `0.3.2` 2026-02-28, 2026-09-10 |
| `pico-args` | Minimal, ergonomic, deliberately lax about some argv edge cases | `GET https://crates.io/api/v1/crates/pico-args/versions` — newest unyanked `0.5.0` **2022-06-04**, 2026-09-10 |
| `bpaf` | Statically-typed combinator parser with an optional derive front-end | `GET https://crates.io/api/v1/crates/bpaf` — newest unyanked `0.9.27` 2026-07-29, 2026-09-10 |
| `argh` | Google's derive-only parser targeting small binaries | `GET https://api.github.com/repos/google/argh` — 1,954 stars, `pushed_at` 2026-05-27T23:18:03Z, 2026-09-10 |
| `xflags` | proc-macro parser by matklad | `GET https://crates.io/api/v1/crates/xflags/versions` — newest unyanked is a **pre-release**, `0.4.0-pre.2` 2024-10-31, 2026-09-10 |
| `gumdrop` | derive parser; present in the ecosystem benchmark, small adoption | rosetta table below, 2026-09-10 |

**Authorities used, and why each counts.**

1. **Rust CLI Working Group book** (`rust-cli/book`, the working group's own
   publication; `GET https://api.github.com/repos/rust-cli/book` — 1,049 stars,
   `archived` false, `pushed_at` 2026-09-01T12:01:07Z, 2026-09-10). Its argument
   chapter states: "The most popular library for parsing command-line arguments
   is called `clap`. It has all the functionality you'd expect, including support
   for sub-commands, shell completions, and great help messages"
   (`src/tutorial/cli-args.md:109-118`, read via
   `GET https://api.github.com/repos/rust-cli/book/contents/src/tutorial/cli-args.md`,
   2026-09-10). This is working-group output, not a blog post.
2. **The maintainers' own source**, read from the published artifacts rather
   than from documentation prose: `clap 4.6.6`, `clap_builder 4.6.6`,
   `clap_derive 4.6.4`, `clap_complete 4.6.9`, downloaded from
   `https://static.crates.io/crates/<name>/<name>-<version>.crate` and unpacked,
   2026-09-10. Every clap behavioral claim below cites a file and line in those
   tarballs.
3. **`rosetta-rs/argparse-rosetta-rs`** — the ecosystem's maintained
   compile-time/binary-size benchmark (`GET https://api.github.com/repos/rosetta-rs/argparse-rosetta-rs`
   — 195 stars, `archived` false, `pushed_at` 2026-09-01T02:15:46Z, 2026-09-10).
   Its `docs/tradeoffs.md` is explicitly "written by the maintainer of clap with
   input from the maintainer of bpaf", which makes it a cross-examined design
   comparison rather than a partisan one (read 2026-09-10).
4. **`blessed.rs`** curated crate list (https://blessed.rs/crates, retrieved
   2026-09-10) — corroboration for the three-bin shape, not proof: "Fully-featured
   … `clap` … Ergonomic, battle-tested, includes the kitchen sink, and is fast at
   runtime. However compile times can be slow"; `bpaf` "Faster compile times than
   clap while still being featureful. But still has some rough edges"; `lexopt`
   and `pico-args` under "Minimal".
5. **Primary counter-evidence**: BurntSushi's own migration rationale in
   ripgrep PR #2626, "various rollup + move off of Clap to lexopt", merged
   2023-11-21 (`GET https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626`,
   2026-09-10). Quoted and analyzed in *Principles and implementation*.
6. **Evidence gap, stated rather than papered over**: I found no annual Rust
   survey question that enumerates CLI-parsing crates, so no survey figure is
   used as authority anywhere in this report.

**Well-regarded projects surveyed, with the evidence that they are well
regarded.** Every star count and `pushed_at` from `GET https://api.github.com/repos/<o>/<r>`,
every dependency line from `GET https://api.github.com/repos/<o>/<r>/contents/Cargo.toml`
(base64-decoded), all 2026-09-10.

| Project | Why it is a relevant reference | Parser evidence |
|---|---|---|
| `rust-lang/cargo` | The Rust project's own package manager; 15,462 stars, `pushed_at` 2026-09-08 | `Cargo.toml:42-43` — `clap = "4.6.0"`, `clap_complete = { version = "4.6.0", features = ["unstable-dynamic"] }`; `:173` adds `features = ["wrap_help"]` |
| `rust-lang/rustup` | The Rust project's toolchain installer; 7,034 stars, `pushed_at` 2026-09-10 | `Cargo.toml:46-48` — `clap = { version = "4", features = ["derive", "wrap_help", "string"] }`, `clap_complete` with `unstable-dynamic` |
| `astral-sh/uv` | Newest high-adoption Rust CLI in the survey; 89,684 stars, `pushed_at` 2026-09-10 | `Cargo.toml:125,131` — `clap = { version = "4.5.17", features = [...] }`, `clap_complete_command = "0.6.1"` |
| `astral-sh/ruff` | 49,573 stars, `pushed_at` 2026-09-10 | `Cargo.toml:82-83` — `clap = { version = "4.5.3", features = ["derive"] }`, `clap_complete_command = "0.6.0"` |
| `starship/starship` | 59,846 stars, `pushed_at` 2026-09-10; tracks clap closely | `Cargo.toml:38-40` — `clap = { version = "4.6.6", features = ["derive","cargo","unicode"] }`, `clap_complete = "4.6.9"`, `clap_complete_nushell = "4.6.2"` |
| `sharkdp/fd` | 44,353 stars, `pushed_at` 2026-09-09 | `Cargo.toml:46,50-52` — `clap_complete` optional behind a `completions` feature; `clap 4.6.1` with `["suggestions","color","wrap_help","cargo","derive"]` |
| `casey/just` | 35,726 stars, `pushed_at` 2026-09-01 | `Cargo.toml:24-26` — `clap = { version = "4.0.0", features = ["derive","env","string","wrap_help"] }`, `clap_complete = "=4.6.8"`, `clap_mangen = "0.3.0"` |
| `BurntSushi/ripgrep` | 68,148 stars, `pushed_at` 2026-08-04 — the strongest counterexample | `Cargo.toml:63` — `lexopt = "0.3.0"`; no clap |

Weighting newer popular projects as the survey method requires: the two newest
high-adoption Rust CLIs in this list (`uv`, `ruff`, both Astral, both post-2022)
are clap adopters, as are both first-party Rust toolchain binaries.

### Principles and implementation

**The shared requirement.** Both source implementations declare the command
surface once, as data, and let the framework derive every derived artifact from
that one declaration — help text, the version flag, completion scripts,
environment fallback, and the unknown-command suggestion. py does this with
`click` decorators (py `src/py_launch_blueprint/cli/main.py:29` — `import click`,
read through the pin `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/cli/main.py`,
2026-09-10); ts does it with Commander (ts `src/router.ts:13` — `import { Command, CommanderError } from 'commander';`,
read through the pin `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/router.ts`,
2026-09-10). The principle is not "use a parser library"; it is **single-source
interface declaration**: the argv grammar has exactly one definition, and every
user-visible artifact is generated from it, so the artifacts cannot drift.

**Agreement level.** Mixed, and conflating the levels produces the wrong answer:

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | The argv grammar has one declaration, from which help/version/completions are generated | **capability** | that generation is derived, never hand-maintained in parallel | which crate does the generating; derive vs builder API |
| P2 | Command paths read noun-then-verb | **standard, one value for all three repos** (org CLI Design Standard R1.1, `(MUST, Standard profile)`) | the ordering itself | how deep the nesting goes, and the module layout that expresses it |
| P3 | `-V`/`--version` exists and prints the tool's version | **capability + standard** (ledger F266 `COMMON → REUSE`; standard R4.1 `(MUST)` and R4.6 `(SHOULD)`) | that the flag exists, that `-v` is *not* version | whether `--version` prints more than one line, and where the extra data comes from (R22) |
| P4 | A settings value exposed in more than one place uses one deterministic name | **standard** (R3.8 `(MUST)`, R5.4 `(MUST)`) | `--some-flag` ↔ `TOOL_SOME_FLAG`, and that env exposure is a **curated subset** | which options are in the curated subset |
| P5 | Global options work wherever the user puts them | **capability**, with the standard fixing the floor (R4.5 `(SHOULD)`: "Global flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted after it") | before-the-verb acceptance | whether after-the-verb acceptance is free or costs per-command declarations |
| P6 | An unknown command produces a suggestion, not a bare failure | **capability** (ledger F271 `COMMON → REUSE`) | that a suggestion appears | the string metric and threshold (F272) |
| P7 | The tool can print completion scripts for the user's shell | **capability** (standard R9.1 `(SHOULD)`) | that a `completion <shell>` surface exists for at least bash, zsh, fish | static script generation vs runtime completion |

The org CLI Design Standard referenced above is
`/Users/stevemorin/c/cli-standards/cli-design-standard.md` (read 2026-09-10). It
is the same document ts's D-016(2) reconciled onto, and the already-resolved R67
adjudicated its R6.1 as `(MUST)` and `org-locked`
(`research/topics/67-error-and-exit-code-contract/DECISION.md:76-82`, read
2026-09-10). Because R60's own prompt does not name it, I treat it here as an
**owner-side requirement input that the owner should confirm applies to R60 as
well as R67**, and I have kept the ecosystem case for every recommendation
independent of it: the standard and the ecosystem evidence agree at every point
below, and I say so where they do. One caveat I will not hide: the standard's
Appendix E is marked "informative only" (`:33`, `:754-759`) and already names
"Rust — Clap (derive)". I have deliberately **not** used Appendix E as evidence
for the framework choice; the case below stands on the ecosystem survey.

**Where the sources' own choices do not survive contact with the standard.**
Two of the seven decisions in this bundle should *not* be ported as-is:

- py's blanket env binding (F269, py `cli/main.py:66` — `"auto_envvar_prefix": APP_NAME.upper(),`,
  read through the pin 2026-09-10) makes *every* option env-settable. R5.4
  `(MUST)` says the opposite: "Only a **curated subset** of settings **SHOULD**
  read from the environment … and the tool **MUST NOT** auto-expose every flag as
  an env var." py's own code already hedges toward the curated form — five of its
  global options carry explicit `envvar=` names (`cli/options.py:62,89,98,107`
  — `PLBP_OUTPUT`, `PLBP_LOG_LEVEL`, `PLBP_LOG_FILE`, `PLBP_CONFIG`) and the
  prefix is described in its own comment as "the catch-all for any others"
  (`cli/main.py:63-66`). The Rust answer should keep the deterministic naming and
  drop the catch-all.
- py's extended `--version` prints three lines unconditionally (`cli/main.py:52-56`
  — tool, `python <ver>`, `platform <platform>`), whereas R4.6 `(SHOULD)` asks
  `--version` to print "a single line `acme <semver>`". clap resolves this
  better than either source, because it carries two separate version strings
  (below) — but the result is still a **deliberate deviation from R4.6's
  `SHOULD` for `--version` only**: R4.6 permits appended commit/date detail for
  pre-release builds, and this design prints target and rustc lines on every
  build. `-V` stays fully conformant. F267 is a `DIVERGENT` row this item owns
  and a `SHOULD` is waivable, so the deviation is recorded and justified by py's
  precedent rather than hidden; the fully conformant alternative is kept as the
  ranked runner-up in that member.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Representative | What it gives | What it costs here |
|---|---|---|---|---|
| A | Declarative single-source parser, derive front-end | `clap` + `clap_derive` | Subcommand routing, help, `-h`/`-V`, completions, env fallback, suggestions all generated from one type definition | Largest compile-time and binary cost of the field (figures below) |
| B | Same crate, builder front-end | `clap` builder | Runtime-composed commands (plugins, config-driven flags) | More code for a fixed command set; no compile-time typing of the result |
| C | Minimal lexer + hand-rolled everything | `lexopt`, `pico-args`, `clap_lex` | Smallest binary and fastest builds; total control over argv semantics | The template must hand-write help, version, man page, completion generators, and suggestion matching — see ripgrep below |
| D | Statically-typed combinator parser | `bpaf` | Compile-time-checked parsers, much faster builds than clap | Combinator style ("yoda-speak", per the maintainers' own trade-off doc); no first-party completion story equivalent to `clap_complete` |
| E | Small derive parser aimed at binary size | `argh`, `xflags` | Tiny overhead | `argh` rejects invalid UTF-8 argv (rosetta "Invalid UTF-8: N"), which loses file-path arguments on Unix; `xflags`'s newest release is a pre-release |

**The strongest argument for C, and why it does not transfer.** ripgrep left clap
for `lexopt` and its maintainer wrote down why (PR #2626, merged 2023-11-21,
retrieved 2026-09-10). Four reasons are given — migration-treadmill fatigue
across clap 2→3→4, admiration for lexopt's minimalism, a desire to shrink the
dependency tree, and this: "I perceived that Clap solves a more general problem
than what I actually need solved. Despite the vast number of flags that ripgrep
has, its requirements are actually pretty simple. We just need simple switches
and flags that support one value. **No multi-value flags. No sub-commands.**"
The same PR body enumerates the bill: "I had to write my own shell completion
generator. I had to write my own `-h/--help` output generator. I also had to
write my own man page generator." That bill is visible in the tree today —
`crates/core/flags/` contains `complete/{bash,fish,powershell,zsh}`,
`doc/{help,man,version}` and `parse.rs`
(`GET https://api.github.com/repos/BurntSushi/ripgrep/contents/crates/core/flags`
and `.../flags/mod.rs:17-39`, 2026-09-10). `rs-launch-blueprint` is the inverse
of ripgrep's case on the one axis that decided it: it *is* a subcommand tool
(F265), it *does* need a `completion` command (F268), and as a template it must
make adding a noun cheap for every downstream user. Architecture C is correctly
excluded on fit, not on popularity.

**Cost, with the workload stated.** From `rosetta-rs/argparse-rosetta-rs`
(README retrieved 2026-09-10; system line quoted verbatim: "Linux
6.17.9-76061709-generic (x86_64), rustc 1.94.0 (4a4ef493e 2026-03-02) w/ `-j 8`",
clap measured at v4.5.60):

| Crate | Overhead (release binary) | Build (debug, full) | Build (debug, incremental) | Parse (release) | Invalid UTF-8 argv |
|---|---|---|---|---|---|
| null baseline | 0 KiB | 163 ms | 115 ms | 1 ms | Y |
| `clap_derive` | 596 KiB | 4 s | 182 ms | 2 ms | Y |
| `clap` (builder) | 574 KiB | 3 s | 170 ms | 2 ms | Y |
| `clap-minimal` (no default features) | 377 KiB | 2 s | 155 ms | 2 ms | Y |
| `bpaf_derive` | 253 KiB | 4 s | 140 ms | 2 ms | Y |
| `argh` | 38 KiB | 4 s | 138 ms | 2 ms | **N** |
| `lexopt` | 37 KiB | 329 ms | 124 ms | 2 ms | Y |
| `pico-args` | 24 KiB | 300 ms | 123 ms | 2 ms | Y |

Read honestly, this table is the case *against* clap and it is a real cost: about
**0.58 MiB of release binary and roughly 3.8 s of additional full debug build**
over a bare binary, for the derive front-end. It is also the whole cost: runtime
parse latency is 2 ms for every entrant including the minimal ones, so no
candidate can be preferred on parsing throughput, and the incremental rebuild
delta (182 ms vs 123 ms) is ~59 ms — the number a template user actually feels
during development. I did not run these benchmarks; they are the upstream
project's published results on the stated system, and the clap row is one patch
series behind the 4.6.6 I recommend.

**Reference implementations that prove the composition.** `casey/just`
(`Cargo.toml:24-26`, 2026-09-10) ships exactly the composition recommended here —
`clap` with `derive`, `env`, `string` and `wrap_help`, plus `clap_complete` and
`clap_mangen` — in a single released binary, which is direct evidence that these
members are used together in production rather than only in theory.
`rust-lang/cargo` and `rust-lang/rustup` demonstrate the same pairing at first-party
scale.

**Minimal realistic example (proposed; not built — no Rust code exists yet).**
One `Cli` type carrying `#[command(flatten)] GlobalArgs` and
`#[command(subcommand)] Commands`; `Commands` is a nested enum whose variants are
nouns (`Project(ProjectArgs)`, `Config(ConfigArgs)`, `Completion { shell: Shell }`),
each noun's `Args` type holding its own `#[command(subcommand)]` verb enum;
`GlobalArgs` fields carry `global = true` and a curated `env = "<TOOL>_…"`;
`build.rs` emits the target triple and rustc version into
`cargo:rustc-env=<TOOL>_BUILD_TARGET=…` for `long_version`.

**Executable acceptance check (proposed; distinguished from anything run).** See
*Validation strategy*. Nothing in this report was executed against a Rust
project, because none exists; every clap behavior claimed here was verified by
reading the published crate source at the exact version cited.

**BASELINE-REVIEW findings.** None. The two inherited rows this item touches —
F266 (`-V`/`--version` exists) and F271 (a did-you-mean suggestion exists) — were
already adjudicated and marked `retained` in `docs/port/BASELINE-REVIEW.md:114`
and `:115` (read 2026-09-10), and my evidence confirms both are natively
available in the recommended stack rather than requiring the template to hand-build
them. I raise no challenge to either.

### Recommendation

One stack: **`clap 4.6.6` with the `derive` API** (features `derive`, `env`,
`string`, `wrap_help` on top of clap's defaults) as the parsing framework, plus
**`clap_complete 4.6.9`** (default features, static `aot` generation) for the
`completion <shell>` command, plus a **dependency-free `build.rs`** supplying the
build metadata that the extended `--version` prints — with **`built 0.8.1`** as
the ranked runner-up for that last member. `strsim 0.11.1` enters the tree
transitively through clap's default `suggestions` feature and is never a direct
dependency. On that framework the command surface is **noun-verb subcommand
groups expressed as a nested `Subcommand` enum**; the extended version output is
**`Command::long_version` for `--version` with a single-line `Command::version`
for `-V`**; global options are **one `#[derive(Args)] struct GlobalArgs`,
`#[command(flatten)]`-ed at the root, with `global = true` on each field**;
environment binding is **a curated per-option `env = "<TOOL>_<NAME>"`**, not a
blanket prefix; and did-you-mean matching is **clap's built-in `suggestions`
feature** (`strsim::jaro`, confidence > 0.7), with no hand-rolled matcher and no
extra dependency.

Resolved direct dependency lines for the template's CLI crate:

```toml
clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }
clap_complete = "4.6.9"
```

### Members

Seven members, one per ledger row this item decides. Two are crates with full
crate figures (`clap`, `clap_complete`); one is a hybrid pattern plus a companion
build-metadata decision (extended `--version`); four are patterns realized inside
`clap`, whose crate figures are marked `inapplicable` with the reason stated in
each member rather than omitted. F266 (`-V`/`--version` exists) and F271 (a
suggestion appears) are inherited `COMMON → REUSE` rows and are not members: this
item decides only which crate provides them and, for F272, the matching mechanism.

#### clap (argument-parsing framework, derive API) — ledger row F264

##### Landscape

Bin 2 (established industry standard). `clap` is the only entrant in the Rust
field that supplies subcommand routing, generated help, a version flag,
first-party completion generation, environment fallback, argument scoping and
built-in suggestion matching from a single declaration. `getopts` (bin 1) and
`lexopt`/`pico-args`/`clap_lex` (bins 1 and 3) supply flag parsing only; `bpaf`
(bin 3) supplies parsing plus help but has no first-party completion crate of
`clap_complete`'s standing; `argh` and `xflags` (bin 3) trade features for size.
Authorities: the Rust CLI Working Group book names clap as the most popular
argument parser and cites its subcommand and shell-completion support
(`rust-cli/book src/tutorial/cli-args.md:109-118`, 2026-09-10); blessed.rs lists
clap as the "Fully-featured" recommendation (https://blessed.rs/crates,
2026-09-10); the crates.io category endpoint ranks it first
(`GET https://crates.io/api/v1/crates?category=command-line-interface&sort=downloads`,
2026-09-10).

##### Principles and implementation

Realizes P1 (single-source interface declaration). The derive API makes the
argv grammar a Rust type: `#[derive(Parser)]` on a struct, `#[derive(Subcommand)]`
on an enum, `#[derive(Args)]` on a reusable option group, `#[command(flatten)]` to
compose them (`clap-4.6.6/examples/git-derive.rs:6-58`, read from the published
crate 2026-09-10). Help, `-h`/`-V`, usage, error context and suggestions are all
generated from that type — clap's default feature set is
`["std", "color", "help", "usage", "error-context", "suggestions"]`
(`clap-4.6.6/Cargo.toml`, `[features] default`, 2026-09-10). The builder API is
the same crate and remains available for a runtime-composed command (relevant if
a later item wants config-driven flags); choosing derive does not foreclose it,
because `Command` is reachable from a derived `Parser` via
`CommandFactory::command()`.

Two behaviors matter for composition with sibling items and are verified in
source rather than assumed:

- **Usage errors exit `2`.** `Error::exit_code()` returns `USAGE_CODE` when the
  error prints to stderr, and `USAGE_CODE: i32 = 2`
  (`clap_builder-4.6.6/src/error/mod.rs:229-244`,
  `clap_builder-4.6.6/src/util/mod.rs:26,32`, 2026-09-10). This matches the
  taxonomy R67 already resolved, so the template needs no exit-code shim for
  parse failures — though R67, not this item, owns that contract.
- **No prefix abbreviation by default.** `Command::infer_long_args` and
  `Command::infer_subcommands` are opt-in settings
  (`clap_builder-4.6.6/src/builder/command.rs:1786,1840`, 2026-09-10), so
  `--ver` does not silently resolve to `--verbose` unless the template asks for
  it. The org standard's R3.10 `(MUST)` forbids exactly that inference; clap's
  default is already conformant.

##### Dominant choice

`clap`, by a margin that is not close. `GET https://crates.io/api/v1/crates/clap`
(2026-09-10): `crate.recent_downloads` **226,398,266** (90-day),
`crate.downloads` **1,119,879,906** (all-time). Nearest full-featured
alternative `bpaf`: `recent_downloads` **1,646,479**, `downloads` **7,762,267**
(`GET https://crates.io/api/v1/crates/bpaf`, 2026-09-10) — clap has roughly 137×
bpaf's 90-day downloads. Popularity is reported *after* the gates below, per the
prompt's ordering, and is not the reason for the recommendation; fit is.

##### Qualified shortlist

Candidates that pass every gate and remain defensible choices: `clap` (derive or
builder), `bpaf`, `lexopt`. `bpaf` is the credible full-featured alternative on
build cost (253 KiB / 4 s derive, or 256 KiB / 831 ms combinatoric, vs clap
derive's 596 KiB / 4 s — rosetta, 2026-09-10) and its maintainer co-authored the
trade-off document that concedes: "If you want to just choose one with little
research that will cover the most use cases, that will most likely be `clap`"
(`rosetta-rs/argparse-rosetta-rs docs/tradeoffs.md`, 2026-09-10). `lexopt` passes
every gate and is the right answer for a different program shape (ripgrep's).

##### Excluded by gate

- **`docopt`** — gate 4 and maintenance: `archived: true`, `pushed_at`
  2021-04-25T07:04:29Z (`GET https://api.github.com/repos/docopt/docopt.rs`,
  2026-09-10); newest unyanked release `1.1.1`, 2021-03-12
  (`GET https://crates.io/api/v1/crates/docopt/versions`). Verdict `archived`.
- **`structopt`** — superseded rather than unfit, in its maintainer's own words:
  "As clap v3 is now out, and the structopt features are integrated into (almost
  as-is), structopt is now in maintenance mode: no new feature will be added"
  (`README.md`, "## Maintenance" section, via
  `GET https://api.github.com/repos/TeXitoi/structopt/contents/README.md`,
  2026-09-10). Newest unyanked `0.3.26`, released 2022-01-18. Adopting it would
  take a second, frozen copy of clap's own macro layer. Verdict `dormant` by
  supersession — on a maintainer's own notice, which is what the rubric requires.
- **`xflags`** — gate 2/maintenance: the newest unyanked version on crates.io is
  the pre-release `0.4.0-pre.2` (2024-10-31) and no `rust-version` is declared
  (`GET https://crates.io/api/v1/crates/xflags/versions`, 2026-09-10). A template
  cannot pin a pre-release as its argv contract.
- **`pico-args`** — gate 2 and maintenance: newest unyanked `0.5.0` released
  **2022-06-04**, repository `pushed_at` 2023-10-19T07:31:56Z
  (`GET https://api.github.com/repos/RazrFalcon/pico-args`, 2026-09-10), no
  declared `rust-version`. Two open issues, so this is `stable-quiet` rather than
  broken, but an undeclared MSRV cannot be tested against the owner's policy.
- **`argh`** — gate 1 (partial) and fit: license is `BSD-3-Clause`
  (`GET https://crates.io/api/v1/crates/argh`, 2026-09-10), which is permissive
  and legally compatible with a `MIT OR Apache-2.0` template but adds a third
  license text and a non-endorsement clause to a repository whose fixed `license`
  parameter is the dual pair; and it fails the argv-correctness column of the
  ecosystem benchmark ("Invalid UTF-8: N", rosetta 2026-09-10), meaning
  non-UTF-8 paths — legal on both `ubuntu-latest` and `macos-latest` — cannot be
  passed as arguments. Excluded on the second ground primarily.
- **`getopts`, `std::env::args_os`, `clap_lex`** — not excluded by a gate; they
  pass all six. They are excluded on **fit**: none supplies subcommands, help,
  completions or suggestions, so choosing them means implementing F265, F267,
  F268, F270 and F272 by hand in the template.

##### Up-and-comers

`lexopt` (newest unyanked `0.3.2`, 2026-02-28; 420 stars; 3 open issues) is the
notable recent arrival — ripgrep's maintainer describes it as demonstrating
"exactly how something new can arrive on the scene and just thoroughly solve a
problem minimalistically … It gets all the weird corner cases right that Clap
also gets right" (PR #2626, 2026-09-10). `bpaf` (0.9.27, 2026-07-29; 461 stars;
63 open issues) is the up-and-comer with genuine feature parity ambitions.
Neither displaces clap for a subcommand-shaped template, and both should be
re-checked at the trigger stated below.

##### Fit for this template

Gates, answered before popularity was weighed:

| # | Gate | `clap 4.6.6` |
|---|---|---|
| 1 | License compatible with `MIT OR Apache-2.0` | **Pass — identical.** `license = "MIT OR Apache-2.0"` (`clap-4.6.6/Cargo.toml:41`; also `GET https://crates.io/api/v1/crates/clap/versions`, 2026-09-10) |
| 2 | MSRV within stable minus 2 (= 1.96 today) | **Pass with 11 minors of headroom.** `rust-version = "1.85"` (`clap-4.6.6/Cargo.toml:14`), and clap's own CI runs a dedicated MSRV leg pinned to `rust: "1.85"` (`.github/workflows/ci.yml:122-125` at tag `v4.6.6`, 2026-09-10). Whole tree: `clap_builder` 1.85, `clap_derive` 1.85, `clap_lex` 1.85, `anstream` 1.66.0, `strsim` 1.56 (crates.io `/versions` `rust_version`, 2026-09-10) |
| 3 | No open RustSec advisory; `unsafe` posture | **Pass.** `https://rustsec.org/packages/clap.html` returns HTTP 404 (no advisory page), as do `clap_builder`, `clap_complete` and `strsim` (2026-09-10). `unsafe` posture: `clap`, `clap_builder` and `clap_derive` each carry `#![forbid(unsafe_code)]` (`clap-4.6.6/src/lib.rs:85`, `clap_builder-4.6.6/src/lib.rs:9`, `clap_derive-4.6.4/src/lib.rs:18`). Caveat stated rather than hidden: the default `color` feature pulls `anstream`, which uses `unsafe` and carries the historical INFO advisory RUSTSEC-2024-0404 ("Unsoundness in anstream", `str::from_utf8_unchecked` in `strip_str`), **Patched >=0.6.8** (https://rustsec.org/advisories/RUSTSEC-2024-0404.html, 2026-09-10); `clap_builder` requires `anstream` `1.0.0` (`clap_builder-4.6.6/Cargo.toml:105-107`), so the resolved tree is not affected |
| 4 | Builds and is tested on `ubuntu-latest, macos-latest` | **Pass.** clap's CI test matrix is `ubuntu-latest`, `windows-latest`, `macos-latest` on stable (`.github/workflows/ci.yml:34-64` at tag `v4.6.6`, 2026-09-10). Windows is supported and tested, though not required here |
| 5 | Default features and async-runtime coupling | **Stated.** Defaults: `std`, `color`, `help`, `usage`, `error-context`, `suggestions` (`clap-4.6.6/Cargo.toml [features] default`). Non-default features this template needs: `derive`, `env`, `string`, `wrap_help`. **No async runtime coupling of any kind** — the dependency set is `anstyle`, `clap_lex`, optional `anstream`/`strsim`/`terminal_size`/`unicode-width`/`unicase`/`backtrace` (`clap_builder-4.6.6/Cargo.toml:105-133`), so clap composes with whatever R05 decides about sync/async and with whatever R61 picks for prompts |
| 6 | Binary-size and compile-time cost | **Stated, and it is the real cost.** ~596 KiB release overhead and ~4 s full debug build for the derive front-end vs a 163 ms null baseline; ~377 KiB with default features off; incremental rebuild 182 ms vs 123 ms for `pico-args` (rosetta, clap v4.5.60, rustc 1.94.0, Linux x86_64, `-j 8`, 2026-09-10) |

Fit against the CLI + library + web-service shape: clap is a leaf dependency of
the **CLI crate only**. Because R02 is still open on crate boundaries, the
concrete recommendation is that `clap` never appears in the library crate's
manifest, so the ~596 KiB and the derive macro expansion are not paid by library
consumers or by the web-service binary. This is the same placement `just`,
`fd` and `cargo` use (their clap dependency sits in the binary's manifest).

##### Recommendation

`clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }`.
`derive` for P1; `env` because it is **not** a default feature and F269 needs it
(`clap-4.6.6/Cargo.toml` — `env = ["clap_builder/env"]`, not in `default`);
`string` because owned `String` values are needed for `long_version` built at
runtime and for any `mut_args` post-pass (`Str`/`OsStr` conversions from `String`
are `#[cfg(feature = "string")]`, `clap_builder-4.6.6/src/builder/str.rs:54-80`,
`os_str.rs:56-100`); `wrap_help` because help text must wrap to the terminal, the
same choice `cargo`, `rustup` and `just` make.

##### Ranked runner-up

1. **`bpaf 0.9.27`** — the only alternative that keeps generated help and a
   derive option while cutting binary overhead by more than half (253 KiB vs 596
   KiB). Take it if a future measurement shows clap's compile time is the
   template's binding constraint. Cost: no first-party completion crate of
   `clap_complete`'s standing, and the combinatoric API is harder for a template's
   downstream users to extend.
2. **`lexopt 0.3.2` + hand-written help/completion/version** — take it only if the
   template's command surface collapses to a flag-only tool with no subcommands.
   Cost is enumerated by ripgrep's own migration: three generators to write and
   own (PR #2626, 2026-09-10).

##### Tradeoffs

Accepted: ~0.58 MiB of release binary and ~3.8 s of extra full debug build in the
CLI binary; a proc-macro dependency (`clap_derive` → `syn`) in the build graph; a
dependency tree of six crates rather than one. Bought: F265, F267, F268, F269,
F270 and F272 all become configuration of one crate instead of six pieces of
template code that every downstream user inherits and must maintain. For a
*template*, the asymmetry is decisive — hand-written parsing code is copied into
every generated project, while a dependency is upgraded once.

##### Parameters

`assumes msrv-policy = stable minus 2 minor versions … (= rust-version 1.96 on
2026-09-10)`; `assumes rust-edition = 2024` (clap 4.6.6 is itself
`edition = "2024"`, `Cargo.toml:13`); `assumes license = MIT OR Apache-2.0`;
`assumes target-os-matrix = ubuntu-latest, macos-latest`. Owns no parameter. No
`CONFLICT:` line.

##### Migration implications

New `crates/<tool>-cli/src/cli.rs` holding `Cli`, `GlobalArgs` and `Commands`;
`Cargo.toml` gains the two dependency lines; the binary's `main.rs` shrinks to
`Cli::parse()` plus a dispatch call. No existing file changes, because no Rust
code exists yet.

##### Validation strategy

Proposed, not executed: `cargo build -p <tool>-cli` on `ubuntu-latest` and
`macos-latest`; `cargo tree -p <tool>-cli -i clap` to prove clap is absent from
the library crate; `cargo test` including a `debug_assert`-style startup test
that calls `<Cli as clap::CommandFactory>::command().debug_assert()`, which is
clap's own supported way to catch malformed command definitions at test time
(`rosetta-rs/argparse-rosetta-rs docs/tradeoffs.md`, 2026-09-10); and a
`cargo build --timings` capture to record the template's actual compile cost
rather than inheriting the benchmark's.

##### Confidence & re-verify trigger

**High.** Re-verify if any of these occur: clap announces a 5.x major (the
migration-treadmill risk ripgrep named); `bpaf` ships a first-party completion
crate with adoption comparable to `clap_complete`; clap's `rust-version` rises
above the template's floor; or a RustSec advisory is filed against `clap`,
`clap_builder`, `clap_lex`, `anstream` or `strsim`. Routine re-check at the next
template dependency sweep.

##### Sources

- `GET https://crates.io/api/v1/crates/clap` and `/versions` (2026-09-10).
- `GET https://api.github.com/repos/clap-rs/clap` — 16,697 stars, `archived` false, `pushed_at` 2026-09-09T22:30:08Z (2026-09-10).
- `GET https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` — `total_count` **369** (2026-09-10).
- Published crate sources `clap-4.6.6`, `clap_builder-4.6.6`, `clap_derive-4.6.4` from `https://static.crates.io/crates/…` (2026-09-10).
- `.github/workflows/ci.yml` at tag `v4.6.6` via `GET https://api.github.com/repos/clap-rs/clap/contents/.github/workflows/ci.yml?ref=v4.6.6` (2026-09-10).
- `https://rustsec.org/packages/clap.html` (HTTP 404) and `https://rustsec.org/advisories/RUSTSEC-2024-0404.html` (2026-09-10).
- `rust-cli/book src/tutorial/cli-args.md`; `https://blessed.rs/crates`; `rosetta-rs/argparse-rosetta-rs` README and `docs/tradeoffs.md` (all 2026-09-10).
- ripgrep PR #2626 body via `GET https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626` (2026-09-10).

**Maintenance state: `active`.** Newest unyanked release `4.6.6`, `created_at`
2026-08-06; repository `pushed_at` 2026-09-09 — one day before retrieval;
`archived` false. Issue responsiveness, measured over the 10 most recently opened
issues (`GET https://api.github.com/repos/clap-rs/clap/issues?state=all&sort=created&direction=desc&per_page=100`,
pull requests filtered out, first comment by an `OWNER`/`MEMBER`/`COLLABORATOR`,
2026-09-10): 5 of 10 answered, **median 1.29 days** among those answered
(0.01 d, 0.60 d, 1.29 d, 4.27 d, 42.07 d); **5 unanswered** (#6520 opened the day
of retrieval, #6511, #6481, #6466, #6442). 369 open issues against a
single-maintainer-led project is a real backlog signal, but it does not meet the
rubric's `at-risk` bar: there is no unpatched advisory, no broken build on
current stable, and no maintainer notice — and releases continue on a monthly
cadence.

#### Command surface shape: noun-verb subcommand groups — ledger row F265

##### Landscape

This member is a **pattern**, not a crate, so the crate figures (90-day
downloads, all-time downloads, last release, stars, open issues, issue
responsiveness, advisories) are **inapplicable**: a command-surface shape has no
crates.io entry. The maintenance rubric is likewise `inapplicable` for the same
reason; the shape's viability is carried entirely by its host crate `clap`, whose
figures are in the member above. The candidate map for the *shape* is:
(a) noun-verb subcommand groups — py's shape (`plbp projects list`); (b) one
default command plus standalone siblings — ts's shape (`ts-projects` bare,
`ts-projects config get`); (c) verb-first (`tool create project`); (d) flat
single-level subcommands (`tool list-projects`). Practice evidence for (a) in
Rust: `uv`, whose README documents `uv tool install ruff` and
`uv python install 3.12 3.13 3.14` (`README.md:170,192` via
`GET https://api.github.com/repos/astral-sh/uv/contents/README.md`, 2026-09-10) —
89,684 stars, and a clap adopter. Practice evidence for (d): `just`, `fd` (flag-only tools).

##### Principles and implementation

Realizes P2. Two independent lines of evidence point the same way.

*Owner-side.* The org CLI Design Standard's **R1.1 is `(MUST, Standard profile)`**:
"A command path **MUST** read *resource then action*: `acme <noun> <verb>`. This
is the de facto pattern of the most-praised multi-resource CLIs (gh, kubectl) and
scales as resources grow"
(`/Users/stevemorin/c/cli-standards/cli-design-standard.md:124-128`, read
2026-09-10), and the same document's org-decision table records "Command ordering
— Noun-verb default … org-locked" (`:64`, row 1). Two adjacent rules constrain
the shape further and should be carried into P03: **R1.3 `(MUST)`** — "Resource
nouns **MUST** be **singular** in their canonical form. The plural form **MAY** be
accepted as an undocumented alias but **MUST NOT** appear in help or docs"
(`:133-137`); and **R1.2 `(SHOULD)`** — depth after the binary should not exceed
three path elements (`:129-132`). Both source repositories use the *plural*
`projects` (py `cli/commands/__init__.py:26` — `COMMAND_GROUPS = [projects_group, config_group]`;
ts `src/commands/projects.ts:70` — `.command('projects', { isDefault: true })`,
both read through their pins 2026-09-10), so a literal port would carry a
documented plural noun that R1.3 forbids. My recommendation is `project` singular
with `projects` as a hidden alias — clap supports exactly that shape via
`#[command(alias = "projects")]`, and its own documentation states the
distinction R1.3 needs: "Aliases defined with this method are *hidden* from the
help message. If you're looking for aliases that will be displayed in the help
message, see `Command::visible_alias`"
(`clap_builder-4.6.6/src/builder/command.rs:2660-2666`, with the mirror note at
`:2862-2868`, read from the published crate 2026-09-10).

*Ecosystem-side.* Independently of the standard, clap's derive API makes shape
(a) the cheapest of the four. A noun group is a nested enum: the noun's variant
holds an `Args` struct that itself carries `#[command(subcommand)]` for the verb
enum — clap's own maintained example does this at
`clap-4.6.6/examples/git-derive.rs:57` (`Stash(StashArgs)`, whose `StashArgs`
holds a nested `StashCommands`), read from the published crate 2026-09-10.
Adding a noun is one enum variant plus one module: the same
"one import + one entry" property py's own module docstring advertises
(`cli/main.py:22-24`, read through the pin 2026-09-10).

The asymmetry that answers the prompt's HIGH question directly — *does the chosen
crate make one shape meaningfully cheaper?* — is **yes, and it favors noun-verb**.
clap has no equivalent of Commander's `{ isDefault: true }`. Reproducing ts's
default-command shape in clap requires `command: Option<Commands>` plus
`Command::args_conflicts_with_subcommands(true)` so the default command's own
flags do not collide with subcommand parsing, plus a hand-written match arm for
the `None` case (`clap_builder-4.6.6/src/builder/command.rs:3311`, 2026-09-10).
Shape (a) needs none of that, and the derive layer does the work: for a
`#[command(subcommand)]` field whose type is **not** `Option`, `clap_derive`
emits `.subcommand_required(true).arg_required_else_help(true)` automatically,
and emits nothing when the type *is* `Option`
(`clap_derive-4.6.4/src/derives/args.rs:198-205`, read from the published crate
2026-09-10; the same pair is emitted for a `Subcommand`-derived root at
`src/derives/into_app.rs:104-105`). So required-subcommand behavior is free in
shape (a) and must be re-established by hand in shape (b).

##### Dominant choice

Noun-verb subcommand groups (shape (a)), expressed as a nested `Subcommand` enum.
Dominant on both axes: the org standard makes it a `MUST`, and among the surveyed
Rust CLIs the tools with a growing set of resources use noun-verb, while the
flat-shape adopters (`fd`, `just`) are single-purpose tools with no resources at
all. Cited instance: `uv`'s own README documents `uv tool install ruff` and
`uv python install 3.12 3.13 3.14` (`README.md:170,192` via
`GET https://api.github.com/repos/astral-sh/uv/contents/README.md`, 2026-09-10).
`cargo` is **not** evidence for this shape and is not cited as such — its own
surface is verb-first (`cargo build`, `cargo add`); it appears in this report only
as a clap adopter.

##### Qualified shortlist

(a) noun-verb groups — recommended; (d) flat single-level subcommands — passes
every gate and is defensible only if the template ships exactly one noun, which it
does not (py ships two: `projects` and `config`).

##### Excluded by gate

`inapplicable` — the six fitness gates are crate properties (license, MSRV,
advisories, CI matrix, default features, binary size). A command-surface shape has
none of them; it inherits every one from `clap`, where they are answered in full.
Excluded on **fit** rather than gate: (b) ts's default-command shape, because it
costs `args_conflicts_with_subcommands` plus an `Option` match arm in clap for no
benefit the template needs, and because ts's own decision record explains the
shape as source-parity with an older flat py CLI (`ts src/commands/projects.ts:61-63`
— "Register the projects command as the program default, so bare `ts-projects`
runs it exactly like bare `py-projects` did", read through the pin 2026-09-10) —
that is history, not a design argument for Rust; and (c) verb-first, which R1.1
names as the counter-example (`❌ acme create project`).

##### Up-and-comers

None. Command-surface shape is a settled design space; the gh/kubectl noun-verb
convention that R1.1 cites has been stable for a decade, and no newer convention
has displaced it in the Rust CLIs surveyed.

##### Fit for this template

The template's whole purpose is that a downstream user adds their own nouns.
Noun-verb makes that a mechanical, reviewable edit: one file under
`src/cli/commands/<noun>.rs`, one variant in `Commands`, one `mod` line. The
default-command shape makes the template's *first* noun structurally different
from every noun added later, which is precisely the asymmetry a template should
not teach. Gates 1-6: `inapplicable` (inherited from `clap`).

##### Recommendation

Nested `Subcommand` enums, singular nouns, hidden plural aliases, depth capped at
`<binary> <noun> <verb>` (two path elements, inside R1.2's limit of three).
`completion` and `doctor` stay as top-level verbs without a noun, matching py
(`cli/main.py:83` `completion`, `:103` `doctor`, read through the pin 2026-09-10)
and matching R9.1's own example spelling `acme completion <shell>`
(`cli-design-standard.md:483-485`).

##### Ranked runner-up

1. Flat single-level subcommands (shape (d)) — take it only if the template
   deliberately ships zero resource nouns. Cost: every later noun forces a
   breaking rename of the flat commands.
2. Default command plus siblings (shape (b), ts's) — take it only if the owner
   wants bare-binary invocation to do useful work. Cost: `Option<Commands>`,
   `args_conflicts_with_subcommands`, and a shape R1.1 does not sanction.

##### Tradeoffs

Noun-verb costs one extra typed word for the user (`tool project list` vs
`tool list`) and one extra enum level in the code. It buys a surface that grows
without renaming anything and generates a two-level completion tree that
`clap_complete` emits for free.

##### Parameters

Owns no parameter. `assumes` the same four fixed parameters as the `clap` member.
No `CONFLICT:` line. Flagged for the owner, not as a conflict: R1.1/R1.3 of the
org CLI Design Standard bind this row if the owner confirms the standard applies
to R60 as it does to the resolved R67.

##### Migration implications

`src/cli/commands/mod.rs` (the `Commands` enum), `src/cli/commands/project.rs`,
`src/cli/commands/config.rs`, `src/cli/commands/completion.rs`,
`src/cli/commands/doctor.rs`. The template's README and generated help must spell
nouns singular.

##### Validation strategy

Proposed, not executed: a `trycmd`/`snapbox` snapshot suite asserting that
`<tool> project list --help` and `<tool> config set --help` both render, that
`<tool> projects list` works but does not appear in `<tool> --help` output (the
hidden-alias property R1.3 requires), and that `<tool>` with no arguments exits
`2` with usage text rather than running a default command.

##### Confidence & re-verify trigger

**High**, conditional on one owner confirmation: that the org CLI Design Standard
binds R60. Absent that confirmation the recommendation is unchanged but rests on
the ecosystem argument alone, where confidence is **medium-high**. Re-verify if
the owner narrows the template to a single-noun tool.

##### Sources

- py `src/py_launch_blueprint/cli/commands/__init__.py:26` and `cli/main.py:22-24,83,103` via `git -C ~/c/py-launch-blueprint show b08bccfb:<path>` (2026-09-10).
- ts `src/commands/projects.ts:61-70` via `git -C ~/c/ts-launch-blueprint show cb1cbcb2:<path>` (2026-09-10).
- `/Users/stevemorin/c/cli-standards/cli-design-standard.md:64,124-137,483-485` (2026-09-10).
- `clap-4.6.6/examples/git-derive.rs:6-58`; `clap_builder-4.6.6/src/builder/command.rs:2411,3153,3311` (published crates, 2026-09-10).
- Adopter manifests for `uv`, `rustup`, `cargo` via `GET https://api.github.com/repos/<o>/<r>/contents/Cargo.toml` (2026-09-10).

#### Extended `--version` output — ledger row F267

##### Landscape

Hybrid member: a **pattern** (which version string prints where) plus a
**companion crate decision** (where the build metadata comes from). Three-bin map
for the metadata source: **bin 1, built-in** — Cargo itself sets
`CARGO_PKG_VERSION` for the crate and `TARGET`/`HOST` for build scripts
("`TARGET` — the target triple that is being compiled for",
https://doc.rust-lang.org/cargo/reference/environment-variables.html, retrieved
2026-09-10), so a ~15-line `build.rs` needs no dependency at all; **bin 2,
established** — `built` and `rustc_version`; **bin 3, up-and-comers** — `vergen`
(v10, split into `vergen`, `vergen-gitcl` and sibling git back-ends) and
`shadow-rs`.

##### Principles and implementation

Realizes P3. clap places py's three-line output and the org standard's
single-line preference on **two different flags**, because it carries two
separate version strings: "Sets the version for the short version (`-V`) and help
messages. If `Command::long_version` is not specified, this message will be
displayed for `--version`" and "Sets the version for the long version
(`--version`) … If `Command::version` is not specified, this message will be
displayed for `-V`", with the documented example for `long_version` being a
multi-line string carrying commit, revision and build details
(`clap_builder-4.6.6/src/builder/command.rs:2098-2154`, read from the published
crate 2026-09-10). So: `-V` prints `<tool> <semver>` — R4.6's "single line `acme
<semver>` (GNU name-and-version style)"
(`cli-design-standard.md:275-279`, 2026-09-10) — and `--version` prints that line
plus the target triple and the rustc version, which is py's extended behavior
(`cli/main.py:52-56`, read through the pin 2026-09-10) placed on the flag that can
afford it. This answers the prompt's MEDIUM question affirmatively: the eager
callback py needs is unnecessary, because clap's `ArgAction::Version` already
prints a string chosen per-flag.

**The deviation, stated rather than glossed.** R4.6 is a `SHOULD`, and it reads
"`--version`/`-V` **SHOULD** print a single line `acme <semver>` … a build **MAY**
append commit/date for pre-release builds"
(`cli-design-standard.md:275-279`, 2026-09-10). Printing a target triple and a
rustc line on `--version` for *every* build, not only pre-release builds, is a
deliberate deviation from that `SHOULD` on the `--version` flag; `-V` remains
conformant. The justification is F267's own subject matter — the row exists
because py prints extended runtime information and the template must decide
whether to keep that capability — and a `SHOULD` is waivable where a recorded
reason exists. The fully conformant alternative is the first runner-up below.

One implementation constraint, verified rather than assumed: `long_version` takes
`impl IntoResettable<Str>`, and converting an owned `String` (which a
runtime-composed version banner is) into clap's `Str` is gated on the non-default
`string` feature (`clap_builder-4.6.6/src/builder/str.rs:54-80`, 2026-09-10) —
hence `string` in the recommended feature list. A `&'static str` produced by
`concat!`/`env!` at compile time needs no such feature; both routes work, and the
`string` feature buys the freedom to compose the banner at startup.

**Coupling to R22, stated and not crossed.** R22 (`runtime-version-accessor`,
ledger row F064) decides whether the template reads its version at compile time
via `env!("CARGO_PKG_VERSION")` or through a runtime metadata lookup. This member
decides only *what `--version` prints and on which flag*. Both R22 outcomes feed
`long_version` identically, because in either case the value is a string available
at startup. The build-metadata companion named below is therefore a
**recommendation contingent on R22**, not a decision that binds it. No
`CONFLICT:` line is warranted: R60 consumes no parameter, and nothing in this
recommendation requires R22 to choose one way.

##### Dominant choice

For the *pattern*: `Command::version` for `-V`, `Command::long_version` for
`--version`. For the *metadata source*: no single crate dominates. Adoption of the
three candidate crates (`GET https://crates.io/api/v1/crates/<name>`, 2026-09-10):
`built` `recent_downloads` 17,292,502 / `downloads` 60,961,741; `vergen`
7,989,499 / 50,980,313 (`vergen-gitcl` 2,821,301 / 7,552,571); `shadow-rs`
2,102,473 / 10,597,460; `rustc_version` 152,673,551 / 730,655,219 — though
`rustc_version`'s figures reflect its use as a build-script compatibility probe
across the whole ecosystem, not as a version-banner crate, so they are not
comparable to the other three.

##### Qualified shortlist

Dependency-free `build.rs` (recommended), `built 0.8.1`, `vergen 10.0.3` /
`vergen-gitcl 10.0.3`, `rustc_version 0.4.1`.

##### Excluded by gate

- **`shadow-rs 2.0.0`** — gate 2: no `rust_version` is declared on the published
  version (`GET https://crates.io/api/v1/crates/shadow-rs/versions`, 2026-09-10),
  so the crate cannot be shown to satisfy a policy whose text requires MSRV
  "declared as rust-version in Cargo.toml and tested in CI". Gate 1 note: its
  license expression is `MIT AND Apache-2.0` (conjunction — both apply), not the
  `OR` disjunction the template uses; permissive and compatible, but worth naming.
- **`vergen 10.0.3` / `vergen-gitcl 10.0.3`** — not excluded, but flagged with
  **zero MSRV headroom**: `rust_version` is `1.96.0`
  (`GET https://crates.io/api/v1/crates/vergen/versions`, 2026-09-10), exactly
  equal to this template's floor of 1.96 on 2026-09-10. It compiles today and
  fails gate 2 the moment the template's floor is anything older, or the moment
  vergen raises its MSRV before the next stable release. For a template whose MSRV
  is a tested, advertised property, that is an unacceptable coupling.

##### Up-and-comers

`vergen`'s v10 line (newest `10.0.3`, 2026-08-24; repository `pushed_at`
2026-09-06, `GET https://api.github.com/repos/rustyhorde/vergen`, 2026-09-10) is
the most actively developed of the three and the only one that splits git back-ends
into separate crates so a consumer picks its own git library. It is the crate to
re-check once its MSRV policy leaves more headroom.

##### Fit for this template

| # | Gate | Dependency-free `build.rs` | `built 0.8.1` | `vergen 10.0.3` |
|---|---|---|---|---|
| 1 | License | `inapplicable` — no third-party code; the file is the template's own, under `MIT OR Apache-2.0` | `MIT` — permissive, compatible | `MIT OR Apache-2.0` — identical |
| 2 | MSRV ≤ 1.96 | `inapplicable` — uses only `std` and Cargo-set environment variables | **Pass**, `rust_version` `1.87` (9 minors of headroom) | **Pass today, zero headroom** — `1.96.0` |
| 3 | Advisories / `unsafe` | No advisory surface; the file contains no `unsafe` | `https://rustsec.org/packages/built.html` HTTP 404 (no advisories) | `https://rustsec.org/packages/vergen.html` HTTP 404 (no advisories) |
| 4 | ubuntu + macOS | `TARGET`/`HOST` are set by Cargo on every platform (Cargo reference, 2026-09-10) | `GET https://api.github.com/repos/lukaslueg/built` — `archived` false, `pushed_at` 2026-06-07 | `GET https://api.github.com/repos/rustyhorde/vergen` — `archived` false, `pushed_at` 2026-09-06 |
| 5 | Default features / async coupling | None; no dependencies | Feature-gated git/dependency info; no async coupling | Feature-gated back-ends; no async coupling |
| 6 | Size / compile cost | Effectively zero — a build script that runs once and emits `cargo:rustc-env` lines | One extra build-dependency tree | One extra build-dependency tree, larger with a git back-end |

All three keep clap out of it: whichever wins, the value reaches clap as a string
passed to `long_version`.

##### Recommendation

A **~15-line `build.rs` with no dependency**, emitting
`cargo:rustc-env=<TOOL>_BUILD_TARGET=$TARGET` (the triple Cargo already exports to
build scripts) and a rustc version line obtained by running the compiler Cargo
names in `$RUSTC` with `-vV`. `--version` then prints
`env!("CARGO_PKG_VERSION")`, `env!("<TOOL>_BUILD_TARGET")` and the rustc line via
`Command::long_version`; `-V` prints the single semver line via
`Command::version`. Rationale: it satisfies gate 2 permanently (no third-party
MSRV to track), adds nothing to the dependency tree that a template's users
inherit, and is the smallest thing that produces py's information content.

##### Ranked runner-up

1. **The fully R4.6-conformant output shape** — `-V` *and* `--version` both print
   the single line `<tool> <semver>`, with the extended data moved to
   `<tool> --version -o json` (which R4.6 explicitly permits: "`--version` **MAY**
   honor `-o json`/`--output json` even when normal result-output options are
   otherwise command-scoped … `{"version":"1.4.0","commit":"abc123","built":"…"}`",
   `cli-design-standard.md:275-279`, 2026-09-10) or to the existing `doctor` verb
   (py `cli/main.py:103`, read through the pin 2026-09-10). Take this if the owner
   rules that R4.6's `SHOULD` is not waivable for R60. Cost: a user who wants the
   target triple must know a second flag or command; the build-metadata
   recommendation below is unchanged either way.
2. **`built 0.8.1`** — take it if the template later wants richer metadata
   (dependency list, git dirty state, build profile) than a hand-written script
   should own. MSRV 1.87 leaves real headroom.
3. **`vergen-gitcl 10.0.3`** — take it if git-derived metadata (commit SHA,
   describe output) becomes a requirement, and only once its MSRV sits clearly
   below the template's floor.
4. **`rustc_version 0.4.1`** — a narrow helper for just the rustc-version line,
   usable inside either of the above or inside the hand-written script.

##### Tradeoffs

The hand-written script is template code that downstream users inherit and could
break; the crates are code someone else maintains but whose MSRV the template must
track. For roughly fifteen lines with no branching, owning it wins. The cost of
being wrong is small and local: swapping to `built` later changes one build file
and one string expression.

##### Parameters

Owns no parameter. `assumes` the four fixed parameters. Related-not-consumed:
R22 (`runtime-version-accessor`, F064) supplies the version value itself; this
member is compatible with either R22 outcome and imposes no constraint on it. No
`CONFLICT:` line.

##### Migration implications

New `crates/<tool>-cli/build.rs`; `src/cli.rs` gains
`#[command(version, long_version = …)]` on the `Cli` type.

##### Validation strategy

Proposed, not executed: assert `<tool> -V` emits exactly one line matching
`^<tool> \d+\.\d+\.\d+$` (R4.6's shape) and exits `0`; assert `<tool> --version`
emits that line plus a target-triple line and a rustc line, and that the triple
differs between the `ubuntu-latest` and `macos-latest` CI legs — which is the
check that proves the build script read `TARGET` rather than a hard-coded string.

##### Confidence & re-verify trigger

**High** for the pattern (`version`/`long_version` is verified in clap's source);
**medium-high** for the metadata source, because it is the member most likely to
be revisited once R22 resolves. Re-verify when R22 resolves, or if `vergen`'s
MSRV drops far enough below the template floor to reconsider it.

##### Sources

- `clap_builder-4.6.6/src/builder/command.rs:2098-2154` and `src/builder/str.rs:54-80` (published crate, 2026-09-10).
- https://doc.rust-lang.org/cargo/reference/environment-variables.html — "`TARGET` — the target triple that is being compiled for" (2026-09-10).
- `GET https://crates.io/api/v1/crates/{built,vergen,vergen-gitcl,shadow-rs,rustc_version}` and `/versions` (2026-09-10).
- `GET https://api.github.com/repos/{lukaslueg/built,rustyhorde/vergen,baoyachi/shadow-rs,djc/rustc-version-rs}` (2026-09-10).
- `https://rustsec.org/packages/{built,vergen,shadow-rs}.html` — all HTTP 404 (2026-09-10).
- py `src/py_launch_blueprint/cli/main.py:48-56` via the pin (2026-09-10); `/Users/stevemorin/c/cli-standards/cli-design-standard.md:275-279` (2026-09-10).

**Maintenance state.** `built`: **active** — newest `0.8.1` 2026-05-21,
`pushed_at` 2026-06-07, 198 stars, 8 open issues
(`GET https://api.github.com/search/issues?q=repo:lukaslueg/built+is:issue+is:open`,
2026-09-10). `vergen`: **active** — newest `10.0.3` 2026-08-24, `pushed_at`
2026-09-06, 473 stars, 3 open issues. `shadow-rs`: **stable-quiet** — newest
`2.0.0` 2026-04-23, `pushed_at` 2026-05-19, 700 stars; no concrete at-risk signal,
but an undeclared MSRV. `rustc_version`: **stable-quiet** — newest `0.4.1`
2024-08-28, `pushed_at` 2026-06-10, 65 stars; a small, finished crate, which is
why no release in over a year is not a dormancy verdict here.

#### clap_complete (shell-completion generation) — ledger row F268

##### Landscape

Bin 2 (established industry standard), and specifically **first-party to the
chosen framework**: `clap_complete` is published from the same repository as
`clap` (`GET https://crates.io/api/v1/crates/clap_complete` — `crate.repository`
`https://github.com/clap-rs/clap`, 2026-09-10). Bin 1 (built-in) is empty: neither
the standard library nor Cargo generates shell completions for a third-party
binary. Bin 3 contains third-party conveniences layered on top of the same crate —
`clap_complete_command` (used by `uv` `Cargo.toml:131` and `ruff`
`Cargo.toml:83`, 2026-09-10) and `clap_complete_nushell` (used by `starship`
`Cargo.toml:40`) — plus the hand-written alternative, whose cost ripgrep
documented ("I had to write my own shell completion generator", PR #2626,
2026-09-10) and whose output lives in `crates/core/flags/complete/` as four
separate generators.

##### Principles and implementation

Realizes P7. py's `completion` command instantiates click's own completion class
and prints its script (`cli/main.py:83-100` — `comp_cls = get_completion_class(shell)`,
`click.echo(comp.source())`, read through the pin 2026-09-10); ts has no such
command at all. clap_complete's static path is the direct analogue: `Shell` is an
enum that already implements clap's `ValueEnum`, so the `shell` argument is a
one-line derive field, and `generate(shell, &mut cmd, name, &mut io::stdout())`
writes the script (`clap_complete-4.6.9/src/lib.rs:16-45`, the crate's own quick-start
example, read from the published crate 2026-09-10). Supported shells are `Bash`,
`Elvish`, `Fish`, `PowerShell`, `Zsh` (`clap_complete-4.6.9/src/aot/shells/shell.rs:15-26`,
2026-09-10) — a superset of py's `bash`/`zsh`/`fish` choice set and of R9.1's
"at least bash, zsh, and fish" (`cli-design-standard.md:483-485`, 2026-09-10).

**The architectural choice inside this member** is static versus dynamic
completion, and it is real:

| | Static (`aot`) | Dynamic (`CompleteEnv`) |
|---|---|---|
| Availability | Default features; `pub mod aot` is unconditional (`clap_complete-4.6.9/src/lib.rs:62`) | Gated behind the non-default `unstable-dynamic` feature (`src/lib.rs:63-79`; `[features]` in `clap_complete-4.6.9/Cargo.toml` shows `default = []` and `unstable-dynamic = ["dep:clap_lex","dep:shlex","dep:is_executable","clap/unstable-ext"]`) |
| What ships | A script the user sources; regenerating is the user's job after an upgrade | The binary completes itself at runtime, so completions never go stale |
| `unsafe` | None reachable | The only `unsafe` block in the crate is here: `std::env::remove_var` with the comment "SAFETY: should only be called during application initialization" (`src/env/mod.rs:220-229`) |
| Adoption | `fd` (`Cargo.toml:46`), `starship` (`:39`) | `cargo` (`:43`), `rustup` (`:48`), `just` (`:25`) — all pinning `unstable-dynamic` despite the name |

That three first-party or near-first-party tools enable an "unstable" feature is
informative about its real maturity, but a **template** must not pin its public
surface to a feature its own upstream labels unstable: a template's users inherit
the pin and the breakage. Static generation is the recommendation; dynamic is the
documented upgrade path.

##### Dominant choice

`clap_complete`. `GET https://crates.io/api/v1/crates/clap_complete` (2026-09-10):
`crate.recent_downloads` **27,337,048**, `crate.downloads` **111,559,662**;
newest unyanked version `4.6.9`, `created_at` 2026-08-06
(`/versions`, 2026-09-10). No competing general-purpose completion generator for
clap-based CLIs appears in the survey; the alternatives are wrappers around it.

##### Qualified shortlist

`clap_complete 4.6.9` (recommended); `clap_complete_command 0.6.1` as a thin
convenience layer; hand-written generators (the ripgrep route).

##### Excluded by gate

- **Hand-written generators** — no gate applies (they are template code, not a
  dependency), so this is a **fit** exclusion: four scripts to write, test on two
  operating systems, and keep in sync with every flag a downstream user adds. A
  template that ships stale completions is worse than one that ships none.
- **`clap_complete_command 0.6.1`** — not excluded, deferred: it is a
  third-party convenience wrapper (`0.x`, so semver-unstable by Cargo's rules) over
  the same generator. Its adopters (`uv`, `ruff`) use it to avoid writing the
  `Shell` enum plumbing, which is roughly five lines in the derive API. Not worth a
  `0.x` dependency in a template.

##### Up-and-comers

`clap_complete`'s own dynamic-completion engine (`unstable-dynamic`) is the
up-and-comer inside this member, plus `clap_complete_nushell 4.6.2` for shells
outside the built-in five. Both are re-verify triggers rather than current
recommendations.

##### Fit for this template

| # | Gate | `clap_complete 4.6.9` |
|---|---|---|
| 1 | License | **Pass — identical.** `license = "MIT OR Apache-2.0"` (`clap_complete-4.6.9/Cargo.toml:40`), and the crate ships both `LICENSE-APACHE` and `LICENSE-MIT` |
| 2 | MSRV ≤ 1.96 | **Pass.** `rust-version = "1.85"`, `edition = "2024"` (`Cargo.toml:13-14`), same floor as `clap`, tested by the same MSRV CI leg |
| 3 | Advisories / `unsafe` | **Pass.** `https://rustsec.org/packages/clap_complete.html` → HTTP 404, no advisories (2026-09-10). `unsafe`: none reachable with default features; the single `unsafe` block is inside `src/env/mod.rs`, compiled only under `unstable-dynamic` |
| 4 | ubuntu + macOS | **Pass.** Same repository and CI as `clap` (ubuntu/windows/macOS on stable), plus dedicated `Shell Integration` and `Nushell Integration` jobs that install real shells and exercise generated completions (`.github/workflows/ci.yml:87-105` at tag `v4.6.6`, 2026-09-10) |
| 5 | Default features / async | **Stated.** `default = []` — the static generator needs no features at all; no async runtime coupling |
| 6 | Size / compile cost | Small and, importantly, **avoidable at runtime cost**: `fd` gates it behind an optional `completions` feature (`Cargo.toml:46,96`, 2026-09-10), a pattern the template can copy if binary size becomes a constraint |

##### Recommendation

`clap_complete = "4.6.9"` with default features, exposed as a top-level
`<tool> completion <shell>` command whose argument is
`clap_complete::Shell` (a `ValueEnum`, so the choice set and its help text are
generated), writing to stdout. Stdout is required, not incidental: the org
standard's stream contract sends "requested output (help/version/results) → stdout"
(`cli-design-standard.md:64`, row 17, 2026-09-10), and py already does this
(`click.echo(comp.source())`).

##### Ranked runner-up

1. **`clap_complete` with `unstable-dynamic`** — take it when clap stabilizes the
   feature, or if stale completions become a reported problem. It is what `cargo`,
   `rustup` and `just` already ship.
2. **`clap_complete_command`** — take it only to avoid the `Shell` enum plumbing,
   which is not a cost worth a `0.x` dependency here.

##### Tradeoffs

Static generation means a user who upgrades the binary keeps yesterday's
completion script until they regenerate it. That is the accepted cost of not
pinning the template to an upstream-labelled-unstable feature. It also keeps the
`unsafe` block out of the build entirely.

##### Parameters

Owns no parameter. `assumes` the four fixed parameters. No `CONFLICT:` line.

##### Migration implications

`src/cli/commands/completion.rs`; one dependency line; a CI step that regenerates
completions and fails if the checked-in copies differ (if the template chooses to
check them in).

##### Validation strategy

Proposed, not executed: `<tool> completion bash | bash -n -` (bash parses the
generated script without executing it) on `ubuntu-latest` and `macos-latest`;
`<tool> completion zsh | zsh -n -`; `<tool> completion fish | fish --no-execute -`;
assert `<tool> completion nonsense` exits `2` with the generated choice list, which
also proves the `ValueEnum` wiring. clap's own repository runs a stronger version
of this check with real shells in its `Shell Integration` job — evidence the
approach is sound upstream, not evidence about this template.

##### Confidence & re-verify trigger

**High.** Re-verify when `unstable-dynamic` stabilizes (switch recommendation to
dynamic completion), if `clap_complete`'s version line diverges from `clap`'s
(they are versioned independently: `4.6.9` vs `4.6.6` today), or if the template
adds shells outside the built-in five.

##### Sources

- `GET https://crates.io/api/v1/crates/clap_complete` and `/versions` (2026-09-10).
- Published crate `clap_complete-4.6.9`: `Cargo.toml:13-14,40`, `[features]`; `src/lib.rs:16-45,62-79`; `src/aot/shells/shell.rs:15-26`; `src/env/mod.rs:220-229`; `README.md` (2026-09-10).
- `.github/workflows/ci.yml:87-105` at tag `v4.6.6` (2026-09-10).
- `https://rustsec.org/packages/clap_complete.html` → HTTP 404 (2026-09-10).
- Adopter manifests: `cargo:43`, `rustup:48`, `just:25`, `fd:46,96`, `starship:39-40`, `uv:131`, `ruff:83` (2026-09-10).
- py `src/py_launch_blueprint/cli/main.py:83-100` via the pin; `cli-design-standard.md:64,483-485` (2026-09-10).

**Maintenance state: `active`.** Newest release `4.6.9`, 2026-08-06; published
from `clap-rs/clap`, whose `pushed_at` is 2026-09-09 and whose `archived` is
false. Issue counts and responsiveness are **repo-level and shared with `clap`**
(369 open issues; 5 of 10 recent issues answered, median 1.29 days) — crates.io
publishes no per-crate issue tracker, so a separate figure is `inapplicable`.

#### Environment-variable binding for global options — ledger row F269

##### Landscape

A **pattern** decided inside `clap`, so crate figures are `inapplicable` for the
member itself (no separate crate is added; the `env` feature is part of `clap`,
whose figures are in the first member) and the maintenance rubric is likewise
`inapplicable`. The candidate map: (a) **blanket prefix** — one setting binds
every option to `PREFIX_<OPTION>`, py's shape via click's `auto_envvar_prefix`;
(b) **curated per-option declaration** — each env-readable option names its
variable; (c) **programmatic post-pass** — declare options normally, then rewrite
every one to add a prefix; (d) **none** — ts's shape, no env binding at all.

##### Principles and implementation

Realizes P4. The decisive finding is that **clap has no `auto_envvar_prefix`
analogue, and that this is the conformant behavior rather than a gap.**

*What clap actually does.* `Arg::env(name)` sets one variable per argument
(`clap_builder-4.6.6/src/builder/arg.rs:2205`), gated on the non-default `env`
feature (`clap-4.6.6/Cargo.toml` — `env = ["clap_builder/env"]`, absent from
`default`; the derive reference states "`env [= <str>]`: `Arg::env` (needs `env`
feature enabled)", `clap-4.6.6/src/_derive/mod.rs:248`, 2026-09-10). Written bare,
`#[arg(env)]` derives the variable name from the field name in the default
`ScreamingSnake` casing with **no prefix** (`clap_derive-4.6.4/src/item.rs:494-501`
applying `self.env_casing`; `rename_all_env` overrides the casing only,
`clap-4.6.6/src/_derive/mod.rs:170`, 2026-09-10). So `#[arg(env)]` on a
`log_level` field yields `LOG_LEVEL`, not `<TOOL>_LOG_LEVEL` — which is why the
template must write the names.

*Option (c) exists and was checked.* `Command::mut_args(|a| …)` applies a closure
to every argument and can add a computed `env` name to each
(`clap_builder-4.6.6/src/builder/command.rs:296-306`, whose own documented example
rewrites every long flag to a prefixed form). Composing an owned `String` name
requires the `string` feature, already in the recommended set. This is the exact
mechanical equivalent of py's blanket prefix, and it is technically available.

*Why (b) beats (c) anyway.* The org standard's **R5.4 is `(MUST)`**:
"Environment variables **MUST** use the uppercase `TOOL_*` prefix with a
deterministic mapping (`--some-flag` → `TOOL_SOME_FLAG`) … Only a **curated
subset** of settings **SHOULD** read from the environment — typically auth/token,
host/endpoint, output format, config path, and telemetry opt-out — and the tool
**MUST NOT** auto-expose every flag as an env var"
(`cli-design-standard.md`, §5 R5.4, read 2026-09-10); **R3.8 `(MUST)`** adds the
naming parity rule `--log-level` ↔ `ACME_LOG_LEVEL` ↔ `log-level` (`:220-224`).
py's own code already leans this way: five global options carry explicit
`envvar=` names (`cli/options.py:62,89,98,107` → `PLBP_OUTPUT`, `PLBP_LOG_LEVEL`,
`PLBP_LOG_FILE`, `PLBP_CONFIG`), and the blanket prefix is documented in its own
comment as "the catch-all for any others" (`cli/main.py:63-66`, read through the
pin 2026-09-10). Independently of the standard, a blanket prefix in a template is
an unbounded promise: every flag a downstream user adds silently becomes a
supported environment variable and therefore a compatibility surface they never
agreed to maintain. And there is a concrete safety edge the standard names
separately — R5.5 `(MUST)` requires secrets *not* to be command-line flags — so
`--token` (py `cli/options.py:110-114`) is precisely the option whose env binding
must be deliberate rather than automatic.

##### Dominant choice

Option (b), curated per-option `env = "<TOOL>_<NAME>"` declarations on the shared
global-options struct. Practice evidence that this is the ecosystem's normal
shape: `just` enables clap's `env` feature explicitly
(`Cargo.toml:24`, features `["derive","env","string","wrap_help"]`, 2026-09-10)
rather than reaching for a blanket mechanism, which none of the surveyed clap
adopters uses.

##### Qualified shortlist

(b) curated per-option declarations — recommended; (c) `mut_args` post-pass —
available and correct, kept as the runner-up if the template ever wants blanket
behavior; (d) no env binding — ts's shape, defensible only for a tool with no
config-like options.

##### Excluded by gate

`inapplicable` — no separate crate is introduced, so the six crate gates belong to
`clap` and are answered there. Excluded on **fit**: option (a), blanket binding,
because clap provides no such setting and because R5.4 `(MUST)` forbids
auto-exposing every flag; option (d), no binding, because the template has a
config path, an output format and a token — three of the five categories R5.4
itself names as the typical curated subset.

##### Up-and-comers

None inside clap. Adjacent crates that layer environment resolution over a parsed
CLI (`figment`, `config`) belong to the configuration items (R53-R56), not here;
this member decides only the parser-level binding.

##### Fit for this template

Gates 1-6: `inapplicable` for the pattern; inherited from `clap`, where all six
pass. The one concrete cost is that clap's `env` feature is **not** in the default
set, so the template must enable it — a one-word change already reflected in the
recommended dependency line. Fit against the CLI + library + web-service shape:
the web service's own environment configuration is R77's item, and nothing here
constrains it, because clap is not in the web binary's dependency path.

##### Recommendation

One `#[derive(Args)] struct GlobalArgs` whose env-readable fields carry explicit
names under a single uppercase tool prefix, deterministically derived from the
flag: `--output` → `<TOOL>_OUTPUT`, `--config` → `<TOOL>_CONFIG`, `--log-level` →
`<TOOL>_LOG_LEVEL`, `--log-file` → `<TOOL>_LOG_FILE`, `--token` →
`<TOOL>_TOKEN`. The curated set is exactly py's five explicit ones, which already
matches R5.4's named categories. Flags deliberately **not** env-bound: `--verbose`,
`--quiet`, `--no-color`, `--no-input`, `--json`, `--output-file` — presentation and
interaction switches whose env-binding would surprise a user in a pipeline.
(`--no-color` is R65's item; listing it here only records that this member does
not bind it.)

##### Ranked runner-up

1. **`Command::mut_args` post-pass** — take it if the owner overrules R5.4 and
   wants py's blanket behavior. It is ~6 lines, needs the `string` feature the
   template already enables, and applies uniformly. Cost: the unbounded
   compatibility promise described above.
2. **No env binding at all** (ts's shape) — take it only if the template drops
   `--config` and `--token`.

##### Tradeoffs

Curated binding costs one string per option and a docs table listing them. It buys
a bounded, documented environment surface that R9.3 `(MUST)` can treat as part of
the public interface contract, and it keeps a token out of any accidental
auto-exposure.

##### Parameters

Owns no parameter — notably, the **env-var prefix itself is not a registered
parameter** in `docs/port/PARAMETERS.md` (read 2026-09-10), and this item does not
create one; the prefix follows the binary name, which no resolved item has fixed.
`assumes` the four fixed parameters. No `CONFLICT:` line.

##### Migration implications

`src/cli/global.rs` (the `GlobalArgs` struct); `Cargo.toml` gains `"env"` to
clap's feature list; a documentation table of environment variables (R5.4's
deterministic mapping must be documented to be checkable).

##### Validation strategy

Proposed, not executed: assert `<TOOL>_OUTPUT=json <tool> project list` produces
the same output as `<tool> project list --output json`; assert the flag wins over
the variable when both are set (R5.1's precedence); assert that a *non*-curated
flag has no env binding — e.g. `<TOOL>_QUIET=1 <tool> project list` must **not**
suppress output — which is the check that proves no blanket prefix leaked in; and
a test that enumerates `<Cli as CommandFactory>::command()`'s arguments and fails
if any argument outside the documented curated list has an `env` set.

##### Confidence & re-verify trigger

**High** on the mechanism (clap has no blanket prefix; `mut_args` is the only
blanket route — both verified in source). **Medium-high** on the curated list
itself, which depends on the option set that R58 (logging), R65 (color) and R66
(output format) finally define. Re-verify when those items resolve, if clap adds
a first-party prefix setting, or if the owner rules that R5.4 does not bind R60.

##### Sources

- `clap-4.6.6/Cargo.toml` `[features]` (`env` not in `default`); `src/_derive/mod.rs:170,248` (published crate, 2026-09-10).
- `clap_builder-4.6.6/src/builder/arg.rs:2205`; `src/builder/command.rs:296-306` (2026-09-10).
- `clap_derive-4.6.4/src/item.rs:494-501` and `src/attr.rs:95-120` (2026-09-10).
- py `src/py_launch_blueprint/cli/main.py:63-66` and `cli/options.py:55-116` via `git -C ~/c/py-launch-blueprint show b08bccfb:<path>` (2026-09-10).
- ts `src/router.ts:112-137` via `git -C ~/c/ts-launch-blueprint show cb1cbcb2:src/router.ts` — no env binding present (2026-09-10).
- `/Users/stevemorin/c/cli-standards/cli-design-standard.md` §5 R5.4, R5.5, and `:220-224` (R3.8) (2026-09-10).
- `just Cargo.toml:24` via `GET https://api.github.com/repos/casey/just/contents/Cargo.toml` (2026-09-10).

#### Stackable global options — ledger row F270

##### Landscape

A **pattern** decided inside `clap`; crate figures and the maintenance rubric are
`inapplicable` for the same reason as the previous member (no crate is added; the
mechanism is a built-in, always-available `Arg` property in the crate whose figures
appear in the first member). The candidate map: (a) **native global propagation** —
declare once at the root, accepted anywhere; (b) **decorator/mixin reapplication** —
py's shape, the same option list re-attached to every command
(`cli/options.py:231-234` — `for option in reversed(_GLOBAL_OPTIONS): decorated = option(decorated)`,
read through the pin 2026-09-10); (c) **root-only declaration** — ts's shape,
options on the `program` object only (`src/router.ts:125-137`, read through the pin
2026-09-10), so a flag after the verb is a usage error.

##### Principles and implementation

Realizes P5, and answers the prompt's MEDIUM question with a clean **yes: clap
supports this natively; no per-subcommand redeclaration is required.**
`Arg::global(true)` "propagates down" to every subcommand, and clap's own
documentation states the property this member needs verbatim: "Global arguments
*only* propagate down, **not** up (to parent commands), however their values once
a user uses them will be propagated back up to parents. In effect, this means one
should *define* all global arguments at the top level, however it doesn't matter
where the user *uses* the global argument"
(`clap_builder-4.6.6/src/builder/arg.rs:880-914`, read from the published crate
2026-09-10). The documented example asserts exactly py's F270 behavior — a
`--verbose` declared once on the root, then used *after* a subcommand
(`get_matches_from(vec!["prog", "do-stuff", "--verbose"])`), read back from the
parent's matches (`arg.rs:896-911`).

In the derive API the property is a raw attribute, spelled `#[arg(global = true)]`
and shown in clap's own derive reference (`clap-4.6.6/src/_derive/mod.rs:107` —
"`global = true, // name = arg form, neat for one-arg methods`", 2026-09-10);
reading a global from a subcommand's own `Args` struct uses
`#[arg(from_global)]` ("Read a `Arg::global` argument (raw attribute), regardless
of what subcommand you are in", `src/_derive/mod.rs:251`, 2026-09-10). Combined
with `#[command(flatten)]`, this yields exactly one declaration site for the
global option set, which is a strictly better realization of P1 than py's
decorator reapplication: py re-attaches nine options to every command function,
so the option list exists once but is *applied* N times, whereas clap declares and
applies once.

The org standard's floor is met and exceeded: R4.5 `(SHOULD)` requires "Global
flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted
after it", with the worked example "`acme -o json widget list` and `acme widget
list -o json` both work" (`cli-design-standard.md:270-274`, 2026-09-10). clap's
`global(true)` delivers both positions from one declaration.

##### Dominant choice

Option (a), `Arg::global(true)` on a flattened `GlobalArgs` struct. This is the
mechanism every surveyed multi-noun clap adopter uses; nothing else in clap
produces position-independent options without redeclaring them.

##### Qualified shortlist

(a) native `global = true` — recommended. (b) redeclaring the same `Args` struct
on each subcommand via `#[command(flatten)]` without `global` — works, and is what
a template would need if it wanted *different* defaults per noun; costs one
flatten line per subcommand and loses parent-level reading.

##### Excluded by gate

`inapplicable` — no separate crate. Excluded on **fit**: option (b) as py
implements it (a decorator that re-applies the whole option list per command),
because clap makes it unnecessary; and option (c), ts's root-only declaration,
because it fails R4.5's `SHOULD` and because it is the one behavior the ledger
records as a py/ts divergence that Rust can resolve rather than inherit.

##### Up-and-comers

None. This is a settled, long-stable clap property, not an evolving area.

##### Fit for this template

Gates 1-6: `inapplicable` for the pattern; inherited from `clap`. One caveat
worth recording for P03 rather than discovering later: because global values
propagate *up* to the parent's `ArgMatches`, the derived `GlobalArgs` should be
read from the root `Cli` value, not re-parsed per subcommand — the derive
equivalent is to keep `#[command(flatten)] global: GlobalArgs` on `Cli` and pass
the struct into the dispatch function, using `#[arg(from_global)]` only where a
subcommand's own `Args` type genuinely needs the value inline.

##### Recommendation

```rust
#[derive(clap::Args, Debug, Clone)]
struct GlobalArgs {
    #[arg(short = 'o', long, global = true, env = "<TOOL>_OUTPUT", value_enum, default_value_t = OutputFormat::Table)]
    output: OutputFormat,
    // … --json, --config, --verbose, --quiet, --no-color, --no-input, --token
}
```

with `#[command(flatten)] global: GlobalArgs` on the root `Cli`. Every global
option is declared exactly once and works before or after any verb. (The specific
option set is owned by R58, R65 and R66; this member fixes only the mechanism.)

##### Ranked runner-up

1. **Per-subcommand `#[command(flatten)]` without `global`** — take it if a noun
   ever needs a different default for a shared option. Cost: one line per
   subcommand and no parent-level read-back.
2. **Root-only declaration** (ts's shape) — take it only if the CLI has no
   subcommands, in which case the distinction disappears.

##### Tradeoffs

`global = true` makes an option legal everywhere, including places where it is
meaningless — which is why R4.5 `(SHOULD)` restricts globals to flags "meaningful
on (nearly) every command" and the recommendation keeps behavior-shaping flags
local. The mechanism is free; the discipline about *which* options get it is the
real cost, and it is a review rule, not code.

##### Parameters

Owns no parameter. `assumes` the four fixed parameters. No `CONFLICT:` line.

##### Migration implications

`src/cli/global.rs` (shared with the env-binding member — the same struct carries
both `global = true` and the curated `env` names); each `src/cli/commands/<noun>.rs`
takes `&GlobalArgs` as a dispatch parameter rather than redeclaring options.

##### Validation strategy

Proposed, not executed: assert `<tool> --output json project list` and
`<tool> project list --output json` produce byte-identical stdout (R4.5's worked
example, transposed to this template's nouns); assert `<tool> project list -v`
raises verbosity identically to `<tool> -v project list`; and assert that a
*non*-global flag placed before its subcommand is a usage error exiting `2`,
which proves the global set is bounded rather than accidental.

##### Confidence & re-verify trigger

**High** — the behavior is asserted by clap's own documented, compiled example.
Re-verify if clap changes global-propagation semantics in a major release, or if
R58/R65/R66 introduce an option whose value must differ per subcommand.

##### Sources

- `clap_builder-4.6.6/src/builder/arg.rs:880-917` (including the compiled `global(true)` example) (published crate, 2026-09-10).
- `clap-4.6.6/src/_derive/mod.rs:107,251` (2026-09-10).
- py `src/py_launch_blueprint/cli/options.py:55-116,231-234` via the pin (2026-09-10).
- ts `src/router.ts:112-137` via the pin (2026-09-10).
- `/Users/stevemorin/c/cli-standards/cli-design-standard.md:270-274` (R4.5) (2026-09-10).

#### Did-you-mean matching implementation — ledger row F272

##### Landscape

A **pattern** realized by a clap feature that is **on by default**, so no crate is
added and the crate figures are `inapplicable` for the member; the transitive
crate it enables, `strsim`, does carry figures and they are given below. The
candidate map: (a) **framework built-in** — clap's `suggestions` feature; (b)
**hand-rolled with a string-distance crate** — `strsim` used directly, the Rust
analogue of py's `difflib` approach (`cli/groups.py:37-56`, read through the pin
2026-09-10); (c) **none** — a bare "unknown command" error, which ledger row F271
(`COMMON → REUSE`, retained) forbids.

##### Principles and implementation

Realizes P6. clap ships this and the template writes nothing.

*It is on by default.* `suggestions` appears in clap's `default` feature list
(`clap-4.6.6/Cargo.toml` — `default = ["std","color","help","usage","error-context","suggestions"]`)
and expands to `suggestions = ["dep:strsim", "error-context"]`
(`clap_builder-4.6.6/Cargo.toml [features]`, 2026-09-10).

*The matcher, exactly.* `did_you_mean` computes `strsim::jaro(v, candidate)` for
every possible value and keeps those with `confidence > 0.7`, returning them
sorted so the closest comes last
(`clap_builder-4.6.6/src/parser/features/suggestions.rs:1-37`, read from the
published crate 2026-09-10). The source carries its own rationale for the metric:
"GH #4660: using `jaro` because `jaro_winkler` implementation in `strsim-rs` is
wrong causing strings with common prefix >=10 to be considered perfectly similar"
(`suggestions.rs:19-20`). When the feature is off, the same function returns an
empty `Vec` (`suggestions.rs:39-46`) — so disabling it degrades gracefully rather
than failing to compile.

*How it compares to the two sources.* py uses `difflib.get_close_matches(name,
self.list_commands(ctx), n=3, cutoff=0.6)` inside a `click.Group` subclass it had
to write (`cli/groups.py:37-56`; the cutoff's own comment at `:33-35` explains 0.6
as difflib's default), and it applies to **commands only**. ts relies on
Commander's `showSuggestionAfterError(true)` (`src/router.ts:120`, read through
the pin 2026-09-10), which its D-016(8) recorded as superseding a hand-rolled
matcher. clap matches ts's "built-in wins" conclusion, and goes further than py in
one respect that matters for a template: `did_you_mean_flag`
(`suggestions.rs:48-62`) also suggests near-miss **long flags** and subcommands,
not just commands — so `<tool> project list --josn` gets a suggestion too, which
py's command-only implementation does not provide.

The metrics are genuinely different and the answer should not pretend otherwise:
difflib's `SequenceMatcher` ratio at cutoff 0.6 and Jaro similarity at 0.7 will
disagree on some inputs. The principle (F271: a suggestion appears) is preserved;
the exact suggestion set for a given typo is an ecosystem-native difference, which
is precisely what F272 is a `DIVERGENT` row to decide.

##### Dominant choice

Option (a), clap's built-in `suggestions` feature. It is the default in the
framework the stack already adopts; every clap adopter surveyed inherits it, and
`fd` names it explicitly in its feature list rather than relying on the default
(`Cargo.toml:52`, features `["suggestions", …]`, 2026-09-10) — evidence that the
behavior is valued enough to be pinned deliberately.

##### Qualified shortlist

(a) clap's `suggestions` — recommended. (b) direct `strsim 0.11.1` — passes every
gate and is the fallback if the template ever needs to suggest over a set clap does
not know about (config keys, for instance), which is R55's territory, not this
item's.

##### Excluded by gate

None excluded by a gate; both viable options pass all six. Excluded on **fit**:
(b) as the primary mechanism, because using `strsim` directly means re-implementing
clap's error path to inject the suggestion — strictly more code than the zero lines
option (a) requires; and (c) no suggestion, because ledger row F271 is a retained
`COMMON → REUSE` capability.

##### Up-and-comers

`rapidfuzz` (the organization that now maintains `strsim-rs` — `GET https://api.github.com/repos/rapidfuzz/strsim-rs`,
2026-09-10) publishes faster string-similarity implementations. Irrelevant here:
the matching workload is a handful of subcommand names per error, so no measurable
performance question exists, and no candidate should be selected on throughput
grounds for this member.

##### Fit for this template

| # | Gate | clap `suggestions` (and its transitive `strsim 0.11.1`) |
|---|---|---|
| 1 | License | **Pass.** `strsim` is `MIT` (`GET https://crates.io/api/v1/crates/strsim/versions`, 2026-09-10) — permissive, compatible with a `MIT OR Apache-2.0` template |
| 2 | MSRV ≤ 1.96 | **Pass** with wide headroom: `strsim` declares `rust-version` `1.56` (same endpoint, 2026-09-10) |
| 3 | Advisories / `unsafe` | **Pass.** `https://rustsec.org/packages/strsim.html` → HTTP 404, no advisories (2026-09-10); the calling code sits inside `clap_builder`, which is `#![forbid(unsafe_code)]` |
| 4 | ubuntu + macOS | **Pass** — pure-`std` string arithmetic with no platform-specific code; exercised on both by clap's own CI matrix |
| 5 | Default features / async | **Stated.** Enabled by clap's `default`; disabling it is a supported configuration that degrades to no suggestions. No async coupling |
| 6 | Size / compile cost | Small: one small pure-Rust crate. Turning `suggestions` off is part of what the rosetta `clap-minimal` row measures (377 KiB vs 574 KiB for the builder default) — so the feature is part of, not additional to, the cost already accounted |

##### Recommendation

Keep clap's default `suggestions` feature on; write no matching code. Do **not**
add `strsim` as a direct dependency. The template's own contribution is a test
that pins the behavior (below), not an implementation.

##### Ranked runner-up

1. **Direct `strsim 0.11.1`** — take it only when suggestions are needed over a
   value set clap does not own (config keys, profile names). Even then, keep clap's
   built-in for the command and flag surface.
2. **A custom matcher tuned to py's cutoff** — take it only if the owner requires
   byte-identical suggestion sets across the three repositories, which no ledger
   row asks for.

##### Tradeoffs

Accepting clap's Jaro-at-0.7 matcher means the Rust CLI will occasionally suggest
a different set than py's difflib-at-0.6 for the same typo. That is the cost.
It buys zero lines of template code, a matcher that also covers flags, and one
fewer thing for downstream users to maintain.

##### Parameters

Owns no parameter. `assumes` the four fixed parameters. No `CONFLICT:` line.

##### Migration implications

None beyond keeping clap's default features enabled — concretely, the template's
`Cargo.toml` must not set `default-features = false` on clap without re-adding
`suggestions`. One snapshot test file records the expected behavior.

##### Validation strategy

Proposed, not executed: assert `<tool> projct list` exits `2` and its stderr
contains a suggestion naming `project`; assert `<tool> project lst` suggests
`list` (the subcommand-level case py's implementation covers); assert
`<tool> project list --josn` suggests `--json` (the flag-level case py's
implementation does **not** cover, so this test documents a deliberate
improvement); and assert that a typo far from every command — `<tool> zzzzzz` —
produces a plain unknown-command error with no suggestion, which is the check that
proves the 0.7 threshold is doing something rather than suggesting indiscriminately.

##### Confidence & re-verify trigger

**High** — the matcher, its metric, its threshold and its default-on status were
each read in the shipped source. Re-verify if clap changes the metric or threshold
in a future release (the `suggestions.rs` comment shows they have changed the
metric once already, over strsim's `jaro_winkler` bug), or if the owner requires
suggestion parity with py's difflib output.

##### Sources

- `clap_builder-4.6.6/src/parser/features/suggestions.rs:1-62` (published crate, 2026-09-10).
- `clap-4.6.6/Cargo.toml` and `clap_builder-4.6.6/Cargo.toml` `[features]` (2026-09-10).
- `GET https://crates.io/api/v1/crates/strsim` and `/versions` — `recent_downloads` 214,874,401, `downloads` 1,058,928,430, newest unyanked `0.11.1` `created_at` 2024-04-02, `rust_version` `1.56`, `license` `MIT` (2026-09-10).
- `GET https://api.github.com/repos/rapidfuzz/strsim-rs` — 495 stars, `archived` false, `pushed_at` 2025-11-27T21:49:25Z (2026-09-10).
- `https://rustsec.org/packages/strsim.html` → HTTP 404 (2026-09-10).
- py `src/py_launch_blueprint/cli/groups.py:33-56` via the pin; ts `src/router.ts:120` via the pin (2026-09-10).
- `docs/port/BASELINE-REVIEW.md:115` (F271, `retained`) (2026-09-10).

**Maintenance state of `strsim`: `stable-quiet`.** Newest unyanked release
`0.11.1`, 2024-04-02 — more than 6 months old, which the rubric makes a trigger to
investigate, not a verdict. Investigated: the repository is not archived and was
pushed 2025-11-27; it is a small, finished algorithm crate now maintained by the
`rapidfuzz` organization; there is no unpatched advisory, no broken build on
current stable, and no maintainer notice of abandonment. Nothing meets the
`at-risk` or `dormant` bar. It is also not a direct dependency of the template.

### Compatibility

The members are proven together three ways, strongest first.

**1. A shared adopter running the exact composition, in production.**
`casey/just` (35,726 stars, `pushed_at` 2026-09-01,
`GET https://api.github.com/repos/casey/just`, 2026-09-10) declares, in one
manifest (`GET https://api.github.com/repos/casey/just/contents/Cargo.toml`,
2026-09-10):

```toml
clap = { version = "4.0.0", features = ["derive", "env", "string", "wrap_help"] }
clap_complete = { version = "=4.6.8", features = ["unstable-dynamic"] }
clap_mangen = "0.3.0"
```

That is the recommended feature set — `derive`, `env`, `string`, `wrap_help` —
plus `clap_complete`, shipped together in a released binary. The one difference
from this recommendation is `just`'s `unstable-dynamic`, which is the upgrade path
named in the `clap_complete` member rather than a contradiction of it.

**2. Two first-party Rust binaries running the same pairing.**
`rust-lang/cargo` (`Cargo.toml:42-43,173-174`) and `rust-lang/rustup`
(`Cargo.toml:46-48`) both pair `clap` 4.6/4.x with `clap_complete`, and `rustup`
additionally enables the `string` feature this stack requires for
`long_version` (2026-09-10).

**3. A version matrix, from the upstream repository itself.** `clap`,
`clap_complete`, `clap_builder`, `clap_derive` and `clap_lex` are published from
one repository (`crate.repository` = `https://github.com/clap-rs/clap` on each
crates.io response, 2026-09-10) and tested by one CI workflow whose matrix is
`ubuntu-latest`, `windows-latest`, `macos-latest` on stable plus a `1.85` MSRV leg
and dedicated `Shell Integration` / `Nushell Integration` jobs that install real
shells and exercise `clap_complete`'s generated scripts
(`.github/workflows/ci.yml:34-64,87-105` at tag `v4.6.6`, 2026-09-10). The
version pairing this stack pins — `clap 4.6.6` with `clap_complete 4.6.9` — is the
newest unyanked release of each as of 2026-09-10, and `clap_complete 4.6.9` was
published on the same day as `clap 4.6.6` (`created_at` 2026-08-06 for both,
crates.io `/versions`, 2026-09-10). They are versioned independently but released
together; `clap_complete 4.6.9` depends on `clap` within the 4.x line.

The build-metadata member composes with the rest by construction rather than by
adopter evidence: a `build.rs` emits `cargo:rustc-env` values that reach clap as an
ordinary string, so there is nothing to co-test beyond the acceptance check in
*Validation strategy*. That is the weakest compatibility claim in this report and
is labeled as such.

### Parameters

- `owns` — **none.** No entry in `docs/port/PARAMETERS.md` names R60 as owner
  (grep for `R60` over that file returns no match, read 2026-09-10), and this
  item's `## Couplings` block lists `owns:` empty.
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` — evaluated as **rust-version 1.96** on 2026-09-10, from Rust stable `1.98.1` (`GET https://api.github.com/repos/rust-lang/rust/releases/latest`, `tag_name`, 2026-09-10).
- `assumes rust-edition = 2024` — satisfied natively: `clap 4.6.6` and `clap_complete 4.6.9` are themselves `edition = "2024"` (`Cargo.toml:13` in each published crate, 2026-09-10).
- `assumes license = MIT OR Apache-2.0` — every recommended crate is `MIT OR Apache-2.0` except the transitive `strsim` (`MIT`), which is compatible.
- `assumes target-os-matrix = ubuntu-latest, macos-latest` — both are in clap's own CI matrix, alongside Windows.
- **No `CONFLICT:` lines.** No recommendation here requires a consumed parameter
  to change. `## Couplings` lists `consumes:` empty, and every fixed parameter is
  satisfied as-is.
- Related, not a conflict: R22 (`runtime-version-accessor`, F064) supplies the
  version value that `--version` prints. Either R22 outcome works unchanged.
- For the owner, not a conflict: the org CLI Design Standard
  (`/Users/stevemorin/c/cli-standards/cli-design-standard.md`) constrains four of
  the seven members through rules marked `(MUST)` — R1.1/R1.3 (noun-verb, singular
  nouns), R3.8 and R5.4 (env naming and curated subset), R4.1 (the standard option
  tiers) — and `(SHOULD)` rules R4.5, R4.6 and R9.1 constrain the rest. R67's
  resolved decision treats this document as org-locked. R60's prompt does not name
  it. Every recommendation above is unchanged either way, but the owner should
  confirm the binding so P03 knows whether R1.3's singular-noun `MUST` is a
  requirement or a suggestion.

### Migration implications

No file changes: no Rust code exists yet. File-level additions to the template,
assuming R02 has not yet fixed crate boundaries (paths shown for a `<tool>-cli`
crate; collapse them if R02 chooses a single crate):

| Path | Contents | Member |
|---|---|---|
| `crates/<tool>-cli/Cargo.toml` | `clap = { version = "4.6.6", features = ["derive","env","string","wrap_help"] }`, `clap_complete = "4.6.9"` | clap, clap_complete |
| `crates/<tool>-cli/build.rs` | ~15 lines emitting `cargo:rustc-env=<TOOL>_BUILD_TARGET` from `$TARGET` and a rustc-version line | extended `--version` |
| `crates/<tool>-cli/src/main.rs` | `Cli::parse()` and a dispatch call; nothing else | clap |
| `crates/<tool>-cli/src/cli.rs` | `#[derive(Parser)] struct Cli` with `#[command(version, long_version = …)]`, `#[command(flatten)] global: GlobalArgs`, `#[command(subcommand)] command: Commands` | clap, `--version`, global options |
| `crates/<tool>-cli/src/cli/global.rs` | `#[derive(Args)] struct GlobalArgs` — every field `global = true`, curated fields also `env = "<TOOL>_…"` | global options, env binding |
| `crates/<tool>-cli/src/cli/commands/mod.rs` | `#[derive(Subcommand)] enum Commands` — one variant per noun, singular, with hidden plural `alias` | command surface |
| `crates/<tool>-cli/src/cli/commands/project.rs` | the noun's `Args` type plus its nested verb enum (`list`, `get`, …) | command surface |
| `crates/<tool>-cli/src/cli/commands/config.rs` | same shape as `project.rs` | command surface |
| `crates/<tool>-cli/src/cli/commands/completion.rs` | `clap_complete::generate` over `clap_complete::Shell` to stdout | clap_complete |
| `crates/<tool>-cli/tests/cli.rs` | the snapshot and behavioral assertions listed below | all |
| `docs/…/environment.md` | the table of curated environment variables R5.4 requires to be documented | env binding |

The library crate's manifest gains **nothing**: `clap` and `clap_complete` belong
to the CLI binary only, so a library consumer and the web-service binary pay
neither the ~596 KiB nor the proc-macro build cost.

### Validation strategy

Everything below is **proposed, not executed.** Nothing in this report was run
against a Rust project, because none exists; the executed work in this session was
evidence retrieval (endpoints and pinned repositories) and reading the published
crate sources. Distinguishing the two matters: the clap behaviors asserted here
come from compiled documentation examples and source in the shipped crates, not
from a template that was built and run.

Build and gate checks:

| # | Command | Expected result | Proves |
|---|---|---|---|
| V1 | `cargo build -p <tool>-cli` on `ubuntu-latest` and `macos-latest` | success on both | gate 4 for the actual pin |
| V2 | `cargo +1.96 build -p <tool>-cli` | success | gate 2 against the template's declared floor |
| V3 | `cargo tree -p <tool>-cli -i clap` and `cargo tree -p <tool>-lib` | clap appears only under the CLI crate | the dependency-placement claim |
| V4 | `cargo deny check advisories` (or `cargo audit`) | no advisories | gate 3, continuously rather than once |
| V5 | `cargo build --timings -p <tool>-cli` | a recorded number | replaces the borrowed rosetta figure with the template's own |

Behavioral checks, one per ledger row this item decides:

| Row | Command | Expected behavior |
|---|---|---|
| F264 | `<tool> --help` | generated help listing every noun and every global option; exit `0` on stdout |
| F264 | `<tool> --bogus` | usage error on stderr, exit **`2`** (clap's `USAGE_CODE`) |
| F265 | `<tool> project list --help` / `<tool> config set --help` | both render; `<tool> projects list` works but `projects` is absent from `<tool> --help` |
| F266/F267 | `<tool> -V` | exactly one line, `<tool> <semver>`, exit `0` |
| F267 | `<tool> --version` | that line plus a target-triple line and a rustc line; the triple differs between the ubuntu and macOS CI legs |
| F268 | `<tool> completion bash \| bash -n -`, and the zsh/fish equivalents | each generated script parses; `<tool> completion nonsense` exits `2` listing the valid shells |
| F269 | `<TOOL>_OUTPUT=json <tool> project list` | identical to `<tool> project list --output json`; the flag wins when both are set |
| F269 | `<TOOL>_QUIET=1 <tool> project list` | **no** effect — proves no blanket env prefix leaked in |
| F270 | `<tool> --output json project list` vs `<tool> project list --output json` | byte-identical stdout |
| F272 | `<tool> projct list` | exit `2` with a suggestion naming `project` |
| F272 | `<tool> project list --josn` | a suggestion naming `--json` (clap covers flags; py's difflib implementation does not) |
| F272 | `<tool> zzzzzz` | unknown-command error with **no** suggestion — proves the 0.7 threshold is discriminating |

Harness: `trycmd`/`snapbox` for the snapshot assertions (both are clap's own
dev-dependencies — `clap-4.6.6/Cargo.toml:537,544` lists `snapbox` and `trycmd`,
2026-09-10 — so the harness choice is at least consistent with upstream practice),
plus one in-process test calling
`<Cli as clap::CommandFactory>::command().debug_assert()` to catch malformed
command definitions at test time rather than at a user's first run. The final
harness choice belongs to R32, not to this item.

### Confidence & re-verify trigger

**Overall confidence: high**, with the distribution stated rather than averaged:

| Member | Confidence | Why |
|---|---|---|
| `clap` | High | Dominance verified at the category endpoint; every gate answered from the shipped crate; the strongest counter-case (ripgrep) examined in the maintainer's own words and shown not to transfer |
| Command surface | High if the org standard binds R60; medium-high otherwise | R1.1 is a `MUST`; independently, clap makes noun-verb the cheaper shape |
| Extended `--version` | High for the pattern; medium-high for the metadata source | `version`/`long_version` verified in source; the companion crate is the member most likely to change when R22 resolves |
| `clap_complete` | High | First-party, gate-clean, with upstream shell-integration CI |
| Env binding | High on mechanism; medium-high on the curated list | The list depends on option sets R58/R65/R66 still own |
| Global options | High | Asserted by clap's own compiled documentation example |
| Did-you-mean | High | Metric, threshold and default-on status read in the shipped source |

Re-verify triggers, any one of which should reopen this item: (1) clap announces a
5.x major release; (2) `clap_complete` stabilizes `unstable-dynamic`, which would
change the F268 recommendation from static to dynamic generation; (3) any RustSec
advisory is filed against `clap`, `clap_builder`, `clap_lex`, `clap_complete`,
`anstream` or `strsim`; (4) clap's `rust-version` rises above the template's
floor, or the floor itself moves such that a companion crate (notably `vergen`,
at `1.96.0` today) falls outside it; (5) R22 resolves in a way that changes what
build metadata is available at startup; (6) R02 fixes crate boundaries in a way
that puts clap in the library crate's manifest; (7) the owner rules on whether the
org CLI Design Standard binds R60. Routine re-verification otherwise at the next
template dependency sweep, since every figure in this report is dated 2026-09-10.

### Sources

**Endpoints queried (all 2026-09-10).**

- crates.io metadata: `GET https://crates.io/api/v1/crates/<name>` and `GET https://crates.io/api/v1/crates/<name>/versions` for `clap`, `clap_builder`, `clap_derive`, `clap_lex`, `clap_complete`, `clap_mangen`, `anstream`, `strsim`, `argh`, `bpaf`, `lexopt`, `pico-args`, `xflags`, `getopts`, `structopt`, `docopt`, `vergen`, `vergen-gitcl`, `built`, `shadow-rs`, `rustc_version`. Fields used: `crate.recent_downloads` (90-day), `crate.downloads` (all-time), and on the newest `yanked: false` version `num`, `created_at`, `rust_version`, `license`.
- crates.io category ranking: `GET https://crates.io/api/v1/crates?category=command-line-interface&sort=downloads&per_page=15`.
- Published crate sources: `https://static.crates.io/crates/<name>/<name>-<version>.crate` for `clap-4.6.6`, `clap_builder-4.6.6`, `clap_derive-4.6.4`, `clap_complete-4.6.9`, unpacked and read locally. Every file:line citation in this report refers to these tarballs.
- GitHub REST: `GET https://api.github.com/repos/<o>/<r>` for `clap-rs/clap`, `google/argh`, `pacak/bpaf`, `blyxxyz/lexopt`, `RazrFalcon/pico-args`, `matklad/xflags`, `rust-lang/getopts`, `docopt/docopt.rs`, `TeXitoi/structopt`, `rustyhorde/vergen`, `lukaslueg/built`, `baoyachi/shadow-rs`, `rapidfuzz/strsim-rs`, `djc/rustc-version-rs`, `rosetta-rs/argparse-rosetta-rs`, `rust-cli/book`, and the eight adopter repositories. Fields used: `stargazers_count`, `archived`, `pushed_at`, `license.spdx_id`.
- Open-issue counts: `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, field `total_count` (never `open_issues_count`): `clap-rs/clap` 369, `google/argh` 64, `pacak/bpaf` 63, `blyxxyz/lexopt` 3, `RazrFalcon/pico-args` 2, `matklad/xflags` 10, `rust-lang/getopts` 10, `rustyhorde/vergen` 3, `lukaslueg/built` 8.
- Issue responsiveness: `GET https://api.github.com/repos/clap-rs/clap/issues?state=all&sort=created&direction=desc&per_page=100`, pull requests filtered out, then `GET /issues/<n>/comments` for each of the 10 most recently opened issues, first comment by `author_association` in {`OWNER`,`MEMBER`,`COLLABORATOR`}.
- File contents: `GET https://api.github.com/repos/<o>/<r>/contents/<path>` (base64-decoded) for the adopters' `Cargo.toml`, clap's `.github/workflows/ci.yml?ref=v4.6.6`, `rust-cli/book src/tutorial/cli-args.md`, `rosetta-rs/argparse-rosetta-rs README.md` and `docs/tradeoffs.md`, `BurntSushi/ripgrep crates/core/flags/mod.rs`.
- ripgrep migration rationale: `GET https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626` (merged 2023-11-21).
- RustSec: `https://rustsec.org/packages/{clap,clap_builder,clap_complete,strsim,vergen,built,shadow-rs}.html` (all HTTP 404 — no advisory page, i.e. no advisories) and `https://rustsec.org/packages/anstream.html` (HTTP 200) with `https://rustsec.org/advisories/RUSTSEC-2024-0404.html`.
- Rust release: `GET https://api.github.com/repos/rust-lang/rust/releases/latest` — `tag_name` `1.98.1`, published 2026-09-03.
- Toolchain documentation: `https://doc.rust-lang.org/cargo/reference/environment-variables.html`; `https://doc.rust-lang.org/std/env/fn.args_os.html`.
- Curated list: `https://blessed.rs/crates`.
- Pinned source repositories, read **through their pins**, never from the working tree: `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/cli/{main.py,options.py,groups.py,commands/__init__.py}` and `git -C ~/c/ts-launch-blueprint show cb1cbcb2:{src/router.ts,src/commands/projects.ts}`. Both pins were confirmed to resolve before reading (`git log -1 --format=%H <pin>`).
- Repository documents: `docs/port/COMMONALITY.md:268-276` (rows F264-F272), `docs/port/BASELINE-REVIEW.md:114-115` (F266, F271 — both `retained`), `docs/port/PARAMETERS.md:7-10`, `docs/port/DIVERGENCE-ANALYSIS.md:196`, `research/topics/67-error-and-exit-code-contract/DECISION.md:76-82`, and the org standard `/Users/stevemorin/c/cli-standards/cli-design-standard.md`.

**Method notes.** Every figure above was retrieved on 2026-09-10 from the
endpoints named in this section, and each is quoted next to the endpoint that
produced it. Behavioral claims about clap were deliberately **not** taken from
docs.rs prose: I downloaded the published `.crate` artifacts for `clap 4.6.6`,
`clap_builder 4.6.6`, `clap_derive 4.6.4` and `clap_complete 4.6.9` from
`static.crates.io` and read the shipped source, so every `file:line` citation
refers to code that is actually in the version this report recommends. Three
endpoint problems occurred and are recorded rather than papered over:
(1) `GET https://api.github.com/repos/clap-rs/clap` without authentication
returned **HTTP 403**, so all GitHub REST figures were retrieved through the
authenticated `gh api` client instead — same endpoints, same fields;
(2) `https://rustsec.org/packages/<name>.html` returns **HTTP 404** for a crate
with no advisories, which I have reported as "no advisory page, i.e. no
advisories" rather than as a failed retrieval — the one HTTP 200 (`anstream`) was
followed to its advisory page and analyzed; (3) my first attempt to read clap's
10 most recently opened issues with `per_page=20` returned only 2 issues after
filtering out pull requests, so the figure was re-taken with `per_page=100`.

Five things I could **not** verify, stated plainly:
1. **No benchmark was run by me.** The compile-time and binary-size table is the
   upstream `rosetta-rs/argparse-rosetta-rs` project's published result on its own
   stated system (Linux 6.17.9, rustc 1.94.0, `-j 8`), measuring clap v4.5.60 —
   one patch line behind the 4.6.6 recommended here. The template's real cost is
   check V5 in *Validation strategy*, which has not been run.
2. **No acceptance check was executed.** No Rust project exists, so every command
   in *Validation strategy* is proposed. I did not scaffold a crate, per the task's
   explicit instruction.
3. **The annual Rust survey** was not used as an authority because I found no
   survey question enumerating CLI-parsing crates. This is an evidence gap in the
   authority set, not a claim that the survey says nothing.
4. **Issue responsiveness was measured for `clap-rs/clap` only** (and therefore
   covers `clap_complete`, which shares that tracker). It was **not** measured for
   `bpaf`, `lexopt`, `built`, `vergen`, `argh`, `getopts` or `strsim`; for those,
   open-issue `total_count`, `pushed_at`, `archived` and release recency carry the
   maintenance verdict, and each verdict says so. The figure table asks for
   responsiveness per candidate; this is a partial answer, not a complete one.
5. **The org CLI Design Standard's binding status for R60** is not something
   research can settle. It is cited above as an owner-side input with its file and
   line numbers; whether it binds this item as it binds R67 is an owner decision,
   flagged in *Parameters*. No recommendation in this report changes if the answer
   is no.

`CONFLICT:` lines emitted: none. `BASELINE-REVIEW:` findings emitted: none — F266
and F271 were already adjudicated `retained` in `docs/port/BASELINE-REVIEW.md`
and my evidence corroborates both.
