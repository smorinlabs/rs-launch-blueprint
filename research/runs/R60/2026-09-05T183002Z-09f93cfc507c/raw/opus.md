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
