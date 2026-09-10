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
| `clap_lex` | clap's own argument *lexer*, published separately and usable without clap; no help generation | rosetta table below; `GET https://crates.io/api/v1/crates/clap_lex` — `crate.recent_downloads` 195,864,291, 2026-09-10 |

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
  without a compromise, because it has two separate version strings (below).

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
**0.57 MiB of release binary and roughly 3.8 s of additional full debug build**
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
