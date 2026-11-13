# R60 — CLI parsing framework (bundle, Deep) — revision 1, 2026-09-10

Synthesized 2026-09-10 by a fresh context that produced none of this item's raw
reports, from three engine reports (five provider bodies) plus the verification
run recorded under `## Empirical check`. No template code exists and none was
written here.

## Decision

**Status.** This is a **proposal**, to be validated in the implementation phase
(P03) against the real template (owner ruling, 2026-09-10). Everything below
rests on registry and GitHub queries, reads of the published crate sources at
their exact versions, reads of the org CLI Design Standard, reads of the two
source repositories through their pins, and one MSRV-aware dependency
resolution — not on a working command-line interface, which does not exist yet.
P03 builds the template and its CI proves the recommendation. Where a
recommendation here does not survive contact with the built template, the
correction is made **against this recorded research** — its principles, its
compared alternatives and its verified mechanisms — rather than by researching
the item again from scratch. The owner has not reviewed R60; no acceptance is
claimed or implied.

Adopt **`clap` with its `derive` API** as the single declaration of the argv
grammar, and take every one of this bundle's six derived surfaces from that one
declaration rather than from application code. The named stack, at the versions
that resolved and audited clean on 2026-09-10:

| Slot | Selection | Where it goes |
|---|---|---|
| Argument parser | `clap = { version = "4.6.6", features = ["derive", "env", "string", "wrap_help"] }` | CLI binary crate only |
| Shell completions | `clap_complete = "4.6.9"` (default features; `aot` generation) | CLI binary crate only |
| Build metadata for extended `--version` | a dependency-free `build.rs` reading Cargo's `TARGET` and running `$RUSTC -vV` | CLI binary crate only |
| Did-you-mean matcher | `strsim`, **transitive** through clap's default `suggestions` feature — never a direct dependency | resolved at `0.11.1` on 2026-09-10 |

The library crate and the web crate depend on none of these.

The six surfaces this bundle decides, and the mechanism chosen for each:

| Ledger row | Surface | Mechanism |
|---|---|---|
| F264 | parsing framework | `clap` 4.6.6, `derive` API; a `Cli::command()` factory kept for completion generation and parser tests |
| F265 | command surface shape | noun-verb subcommand groups as nested `Subcommand` enums; **no default business command** |
| F267 | extended `--version` | `Command::version` (one line) for `-V`; `Command::long_version` (extended) for `--version` — **see OVERRIDE (OV-01)** |
| F268 | completion generation | a regular `completion <shell>` subcommand calling `clap_complete::aot::generate` against a fresh `Cli::command()` |
| F269 | env-var binding | a **curated** per-option `#[arg(env = "<TOOL>_<NAME>")]`; **no blanket prefix** — py's `auto_envvar_prefix` is not ported |
| F270 | stackable global options | one `#[derive(Args)] struct GlobalArgs`, `#[command(flatten)]`-ed at the root, `global = true` on each field |
| F272 | did-you-mean matching | clap's default `suggestions` feature (`strsim::jaro`, confidence `> 0.7`); no hand-rolled matcher, no direct `strsim`, `infer_subcommands` left off |

F266 (`-V`/`--version` exists) and F271 (a suggestion appears) are inherited
`COMMON → REUSE` rows adjudicated `retained` in
`docs/port/BASELINE-REVIEW.md:114` and `:115` (read 2026-09-10). This item
decides only which crate provides them and, for F272, the matching mechanism.
Both are natively available in the recommended stack: verified in the crate
source, cited below.

**Integration point with the already-published R67.** R67 requires `main` to
return `ExitCode`, a usage/parse failure to be `RSLB201` → exit `2`, a single
JSON envelope on stderr, and stdout byte-empty on the error path
(`research/topics/67-error-and-exit-code-contract/DECISION.md`, read
2026-09-10). `Cli::parse()` does not compose with that: it prints clap's own
message and terminates the process itself. So the template calls
**`Cli::try_parse()`** and routes the `clap::Error` by `kind()`: exactly two
kinds — `ErrorKind::DisplayHelp` and `ErrorKind::DisplayVersion` — are
successful output on stdout at exit `0`; every other kind is `RSLB201` → `2`.
Those two and no others, because that is the exact match arm clap itself uses:
`stream()` is `ErrorKind::DisplayHelp | ErrorKind::DisplayVersion =>
Stream::Stdout, _ => Stream::Stderr`, and `exit_code()` returns `USAGE_CODE`
for every stderr kind and `SUCCESS_CODE` otherwise, those constants being `2`
and `0` (`clap_builder-4.6.6/src/error/mod.rs:222-237`,
`clap_builder-4.6.6/src/util/mod.rs:26,32`, read 2026-09-10). Note the one kind
that reads as if it belonged in the exit-`0` list and does not:
`DisplayHelpOnMissingArgumentOrSubcommand` (`error/kind.rs:300`) falls in the
`_` arm, so clap sends it to stderr at `2`. Whether the template overrides that
is not decided here — it depends on `Command::arg_required_else_help`, which
this item does not set. clap's numbering therefore agrees with R67 at both
ends, but agreement of values is not composition: the envelope and the
`ExitCode` return are the template's, and P03 must build them. Rendering clap's usage text *inside* R67's
JSON envelope is not decided here and is listed under `## Engines` as work P03
must resolve.

### Principles and implementation

**The shared requirement.** Both source implementations declare the command
surface once, as data, and generate every user-visible artifact from that one
declaration — help text, the version flag, the completion script, the
environment fallback and the unknown-command suggestion. py does this with
`click` (py `src/py_launch_blueprint/cli/main.py:29` — `import click`); ts does
it with Commander (ts `src/router.ts:13` — `import { Command, CommanderError }
from 'commander';`). Both lines were read through the pins on 2026-09-10 (`git
-C ~/c/py-launch-blueprint show b08bccfb…:<path>`, `git -C
~/c/ts-launch-blueprint show cb1cbcb2…:<path>`; full output in the evidence
log, section Y/Z). The principle is not "use a parser library". It is
**single-source interface declaration**: the argv grammar has exactly one
definition, and no derived artifact is maintained by hand alongside it. The
residual drift risk is confined to an artifact that is *committed* rather than
emitted at run time — the completion scripts, if the template ever checks them
in — which is what acceptance criterion AC4 is for.

**Source and agreement level.** Five levels are in play, and conflating them
produces the wrong answer. Where a row's source is the org CLI Design Standard,
the citation is `/Users/stevemorin/c/cli-standards/cli-design-standard.md:<line>`,
read 2026-09-10.

| # | Principle | Agreement level | Must agree across py/ts/rs | May vary per ecosystem |
|---|---|---|---|---|
| P1 | The argv grammar has one declaration; help, version and completions are generated from it | **capability** (ledger F264 `DIVERGENT`) | that generation is derived, never hand-maintained in parallel | which crate generates; derive vs builder front-end |
| P2 | A command path reads noun then verb | **standard, one value for all three repos** — R1.1 `(MUST, Standard profile)` (`:124`), org-locked (`:70` row 1) | the ordering itself | nesting depth (R1.2 `SHOULD` ≤ 3, `:129`) and the module layout |
| P3 | `-V`/`--version` exists and reports the tool's version | **capability + standard** — ledger F266 `COMMON → REUSE`; R4.1 `(MUST)` required global core (`:237`), R4.6 `(SHOULD)` output shape (`:275`) | that the flag exists, and that `-v` is verbose, not version (`:70` row 3, org-locked) | whether `--version` prints more than one line, and where the extra data comes from (R22) |
| P4 | A setting exposed in more than one place uses one deterministic name, and env exposure is curated | **standard** — R3.8 `(MUST)` (`:220`), R5.4 `(MUST)` (`:321`), org-locked (`:70` row 7) | `--some-flag` ↔ `TOOL_SOME_FLAG`, and that the env surface is a curated subset | which options are in the curated subset |
| P5 | Global options work wherever the user puts them | **capability**, floor fixed by R4.5 `(SHOULD)`: "Global flags **MUST** be accepted before the subcommand and **SHOULD** also be accepted after it" (`:270-271`) | before-the-verb acceptance | whether after-the-verb acceptance is free or costs per-command declarations |
| P6 | An unknown command produces a suggestion, not a bare failure | **capability** (ledger F271 `COMMON → REUSE`) | that a suggestion appears | the string metric and threshold (F272) |
| P7 | The tool can print completion scripts for the user's shell | **capability** — R9.1 `(SHOULD)` "at least bash, zsh, and fish" (`:483`) | that a `completion <shell>` surface exists for those three shells | static script generation vs runtime completion |

**The standard binds this item, on the same footing as R67.** R60's own prompt
does not name the org CLI Design Standard, and the Opus raw report therefore
treats its applicability as an open owner question. It is not open. The
already-published R67 rests on the same document, adjudicating its R6.1 as a
`(MUST)` that is `org-locked` and quoting its exit-code table verbatim
(`research/topics/67-error-and-exit-code-contract/DECISION.md:76-82`, read
2026-09-10). This decision follows that treatment: every rule cited above is
cited by file and line with its retrieval date, and a `MUST` marked org-locked
in the design-principles table at `:70` is binding, not advisory. The ts port
already reconciled onto the same document in code — its router carries the
comment "Usage errors must exit 2 (cli-standards R6.1)" (ts `src/router.ts:117`,
read through the pin 2026-09-10).

Two consequences follow, and they are different in kind:

- **The template is in the Standard profile, so R1.1 is a `MUST` here.** The
  standard defines two profiles (`:50-53`); the verb-first Small-CLI profile
  requires *all three* of its entry criteria to hold (`:578-581`), the first
  being a small fixed command set acting on "a **single implicit resource** or
  no resource at all". This template ships two resource groups (`projects`,
  `config`) and exists to be extended, so criteria 1 and 2 both fail. The
  standard's own counter-example is decisive: "a platform tool managing
  `projects`, `deploys`, `tokens`, and `users` — that **MUST** use noun-verb"
  (`:586`). F265 is therefore settled by the standard, not by a preference
  between the two ports. The ecosystem evidence agrees rather than conflicts, so
  no override is filed.
- **R4.6 is a `SHOULD` that this design deviates from.** Recorded as OVERRIDE
  (OV-01) below.

**What the standard excludes, and why the exclusion is not a clap limitation.**
py binds *every* option to an env var through one prefix (py
`cli/main.py:60-66` — `"auto_envvar_prefix": APP_NAME.upper(),`, whose own
comment calls the prefix "the catch-all for any others"; read through the pin
2026-09-10). R5.4 `(MUST)` says the opposite: "Only a **curated subset** of
settings **SHOULD** read from the environment … and the tool **MUST NOT**
auto-expose every flag as an env var" (`:321-323`). py's own code already hedges
toward the curated form — four of its global options carry explicit `envvar=`
names (`PLBP_OUTPUT`, `PLBP_LOG_LEVEL`, `PLBP_LOG_FILE`, `PLBP_CONFIG`, py
`cli/options.py:62,89,98,107`, read through the pin 2026-09-10). So F269 is
decided by the standard: keep the deterministic `--some-flag` ↔
`<TOOL>_SOME_FLAG` naming that R3.8 `(MUST)` requires, drop the catch-all.

**`<TOOL>`/`<tool>` is a placeholder throughout this decision, and deliberately
so.** py's tool is named `plbp` and its variables are `PLBP_*`; the Rust
template's binary name is **not this item's to set**. It follows from R49
(`build-tool-output-shape`), whose registry value is still `—`
(`docs/port/PARAMETERS.md`, read 2026-09-10), and R9.3 `(MUST)` makes env-var
names part of the tool's public contract — "command names, flag names, exit
codes, env-var names, and machine-readable output shape" (`:491-493`, read
2026-09-10) — so writing
`PLBP_` here would propagate py's name into a Rust interface this item has no
authority over. Every `<TOOL>_` and `<tool>` below resolves to R49's binary name
uppercased and as-is respectively; the *rule* this item fixes is the
deterministic transform, not the string. Where `PLBP_` appears without a
placeholder it is quoting py's own source or a raw report, and says so.

State the reason precisely, because a wrong reason here would propagate. clap
**can** do blanket binding: `Command::mut_args` takes an `FnMut(Arg) -> Arg`
over every argument (`clap_builder-4.6.6/src/builder/command.rs:296-302`, read
2026-09-10), so a builder post-pass that derives `<TOOL>_<UPPER_SNAKE>` from
each long name — which is what the Doxa OpenAI body proposes — is mechanically
constructible. What clap does not ship is a *declarative* prefix switch: a grep
of `clap_builder 4.6.6` and `clap_derive 4.6.4` for `env_prefix`, `auto_env` and
`envvar_prefix` returns nothing, and the only env API is per-argument
`Arg::env` / `Arg::env_os` (`arg.rs:2205,2221`). The blanket design is therefore
excluded **because R5.4 forbids it**, not because clap cannot express it.

**Architectural alternatives, compared before libraries.**

| # | Architecture | Representative | What it gives | What it costs for this template |
|---|---|---|---|---|
| A | Declarative single-source parser, derive front-end | `clap` + `clap_derive` | subcommand routing, help, `-h`/`-V`, completions, env fallback and suggestions from one type definition | the largest compile-time and binary cost among the candidates surveyed (figures and their limits below) |
| B | Same crate, builder front-end | `clap` builder | commands composed at runtime (plugins, config-driven flags) | more code for a fixed command set; no compile-time typing of the parse result |
| C | Minimal lexer, everything else hand-written | `lexopt`, `pico-args`, `clap_lex` | smallest binary, fastest builds, total control over argv semantics | the template must hand-write help, version, man page, completion generators and suggestion matching |
| D | Statically-typed combinator parser | `bpaf` | compile-time-checked parsers; smaller release overhead than clap in the upstream benchmark (qualification 3 below) | combinator style; its completion support was not verified here (see `## Engines`) |
| E | Small derive parser aimed at binary size | `argh`, `xflags` | tiny overhead | `argh` is BSD-3-Clause and declares no `rust-version`; `xflags`'s newest release is a pre-release |

Architecture C is excluded **on fit, not on popularity**, and the strongest
argument for it is worth stating in full because it is real. ripgrep left clap
for `lexopt`, and its maintainer wrote down why (PR #2626, merged 2023-11-21;
quoted in the Opus raw report from `GET
https://api.github.com/repos/BurntSushi/ripgrep/pulls/2626`, retrieved
2026-09-10): "I perceived that Clap solves a more general problem than what I
actually need solved … **No multi-value flags. No sub-commands.**" The same PR
body enumerates the bill: "I had to write my own shell completion generator. I
had to write my own `-h/--help` output generator. I also had to write my own man
page generator." `rs-launch-blueprint` is the inverse of ripgrep's case on the
axis that decided it: it *is* a subcommand tool (F265, and R1.1 makes that a
`MUST`), it *does* need a `completion` command (F268, R9.1), and as a template
it must make adding a noun cheap for every downstream user. ripgrep's
`Cargo.toml:63` still reads `lexopt = "0.3.0"` and names no clap (verified
2026-09-10, evidence log section AA) — the counterexample is genuine, and it
does not transfer.

**Fitness gates, answered per candidate before popularity was weighed.** Every
figure below is from the run recorded in `## Empirical check`, retrieved
2026-09-10.

| Candidate | 1. license | 2. MSRV (floor 1.96) | 3. advisory / `unsafe` | 4. OS matrix | 5. default features | 6. size & build cost | Gate result |
|---|---|---|---|---|---|---|---|
| `clap 4.6.6` | `MIT OR Apache-2.0` | declares `1.85` — 11 minors of headroom | no RustSec page; `cargo audit` clean on the resolved tree | see qualification 2 | `std,color,help,usage,error-context,suggestions` | largest of the surveyed field in the upstream benchmark (qualification 3) | **pass** |
| `clap_complete 4.6.9` | `MIT OR Apache-2.0` | declares `1.85` | no RustSec page | see qualification 2 | `default = []`; requires `clap >= 4.5.20` | not separately measured in the upstream benchmark; adds five shell writers | **pass** |
| `strsim` — `0.11.1` at the 2026-09-10 resolution, and transitive, so the version floats | `MIT` | declares `1.56` | no RustSec page | see qualification 2 | n/a — pulled by clap's `suggestions` | not separately measured | **pass** |
| `vergen 10.0.3` | `MIT OR Apache-2.0` | declares **`1.96.0` — exactly the floor, zero headroom** | no RustSec page | not assessed | `cargo`, `rustc` features needed | build-time only | **pass today, at risk** — see below |
| `built 0.8.1` | `MIT` | declares `1.87` | no RustSec page | not assessed | build-time only | build-time only | **pass** (runner-up) |
| `shadow-rs 2.0.0` | `MIT AND Apache-2.0` | **declares none** | no RustSec page | not assessed | build-time only | build-time only | **excluded by gate 2** (no MSRV evidence) |
| `bpaf 0.9.27` | `MIT OR Apache-2.0` | declares `1.68` | no RustSec page | not assessed | not assessed | smaller than clap in the upstream benchmark (qualification 3) | passes gates; loses on fit (D above) |
| `argh 0.1.19` | **`BSD-3-Clause`** | **declares none** | no RustSec page | not assessed | not assessed | 38 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also rejects invalid-UTF-8 argv per that same benchmark's own column |
| `lexopt 0.3.2` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 37 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; also architecture C |
| `pico-args 0.5.0` | `MIT` | **declares none** | no RustSec page | not assessed | not assessed | 24 KiB in the upstream benchmark (qualification 3) | **excluded by gate 2**; newest release 2022-06-04, repo `pushed_at` 2023-10-19 |

Four qualifications on that table, each of which limits exactly one column:

1. **Gate 3, advisories.** "No RustSec page" means `GET
   https://rustsec.org/packages/<name>.html` returned HTTP 404 for all eight
   crates queried. That reading was validated against two controls that do carry
   advisories — `anyhow` (HTTP 200, `RUSTSEC-2026-0190`, the advisory R67 cites)
   and `atty` (HTTP 200, two IDs) — so a 404 here is absence of an advisory page,
   not a failed request. `cargo audit` (advisory DB of 1,243 advisories, fetched
   2026-09-10) scanned the resolved 29-crate tree and exited `0`. **The `unsafe`
   posture of these crates was not assessed in this run** and is carried to
   `## Engines` as unproven.
2. **Gate 4, the OS matrix.** No CI configuration was read in this run. The
   resolution and the crate reads were performed on macOS 26.4 `aarch64` only.
   That `clap`, `clap_complete` and `strsim` build and are tested on
   `ubuntu-latest` and `macos-latest` is **not established by this decision**; it
   is carried to `## Engines` as unproven with what would prove it. What *is*
   established here is that the recommended pins resolve at the declared MSRV
   floor on one host.
3. **Gate 6, size and build cost.** The only figures available are the upstream
   `rosetta-rs/argparse-rosetta-rs` benchmark's published results, quoted in the
   Opus raw report from that project's README (retrieved 2026-09-10). They were
   measured **by that project, on its own stated system — "Linux 6.17.9-76061709-generic
   (x86_64), rustc 1.94.0 (4a4ef493e 2026-03-02) w/ `-j 8`" — with clap at
   v4.5.60, which is not the 4.6.6 recommended here, and on neither CI runner.**
   No benchmark was run by the Opus report and none was run by this decision.
   Within those limits the published numbers are: `clap_derive` ~596 KiB release
   overhead and ~4 s full debug build against a null baseline of 0 KiB / 163 ms;
   `clap` builder 574 KiB / 3 s; `bpaf_derive` 253 KiB / 4 s; `argh` 38 KiB;
   `lexopt` 37 KiB; `pico-args` 24 KiB. Two readings matter and both are
   qualified the same way: parse latency is 2 ms for *every* entrant in that
   run including the minimal ones, so **on those figures** no candidate can be
   preferred on parsing throughput; and the incremental-rebuild delta the
   template's users would feel is 182 ms vs 123 ms, ~59 ms, **on that system at
   that version**. The cost at 4.6.6 with this template's feature set, on
   `ubuntu-latest` and `macos-latest`, is unmeasured — see `## Engines`.
4. **Gate 2, `vergen`.** `vergen 10.0.3` declares `rust-version = 1.96.0`,
   which is *exactly* today's floor (stable `1.98.1`, published 2026-09-03,
   minus two minors). Resolution at `rust-version = "1.96"` succeeds; resolution
   at `rust-version = "1.95"` — the floor as it stood one Rust release ago —
   makes Cargo report "Adding vergen v10.0.3 (requires Rust 1.96.0)". A
   build-dependency whose MSRV tracks current stable will therefore sit outside
   this template's floor whenever the floor lags, and the template would have to
   pin `vergen` back. That is the concrete reason the dependency-free `build.rs`
   is preferred over the Codex raw report's `vergen` recommendation, and it is a
   maintenance cost the Codex report does not state.

**Practice evidence, verified rather than asserted.** Every manifest line below
was read in this run via `GET
https://api.github.com/repos/<o>/<r>/contents/Cargo.toml`, base64-decoded,
2026-09-10; star counts are from the Opus raw report at the same retrieval date.

| Project | Why it is a relevant reference | Manifest evidence |
|---|---|---|
| `rust-lang/cargo` | the Rust project's own package manager | `Cargo.toml:42-43` — `clap = "4.6.0"`, `clap_complete = { version = "4.6.0", features = ["unstable-dynamic"] }`; `:173` adds `wrap_help` |
| `rust-lang/rustup` | the Rust project's toolchain installer | `Cargo.toml:46,48` — `clap = { version = "4", features = ["derive","wrap_help","string"] }`, `clap_complete` |
| `astral-sh/uv` | one of the newest high-adoption Rust CLIs (89,684 stars per the Opus report) | `Cargo.toml:125,131` — `clap = { version = "4.5.17", … }`, `clap_complete_command = "0.6.1"` |
| `astral-sh/ruff` | same maintainer, 49,573 stars per the Opus report | `Cargo.toml:82-83` — `clap = { version = "4.5.3", features = ["derive"] }` |
| `casey/just` | ships **exactly** this decision's feature set | `Cargo.toml:24-26` — `clap = { version = "4.0.0", features = ["derive","env","string","wrap_help"] }`, `clap_complete = "=4.6.8"`, `clap_mangen = "0.3.0"` |
| `starship/starship` | tracks clap closely; also the adopter of the *rejected* metadata crate | `Cargo.toml:38-39` — `clap = { version = "4.6.6", … }`, `clap_complete = "4.6.9"`; `:79` — `shadow-rs = "2.0.0"` |
| `BurntSushi/ripgrep` | the strongest counterexample | `Cargo.toml:63` — `lexopt = "0.3.0"`; no clap |

`casey/just` is the composition evidence for this feature set: one released
binary carrying `clap` with `derive`+`env`+`string`+`wrap_help` alongside
`clap_complete`. State its limit exactly — its manifest requests `clap =
"4.0.0"` and pins `clap_complete = "=4.6.8"`, so it demonstrates that this
*feature combination* ships in production, not that it ships at the 4.6.6 and
4.6.9 recommended here. The version matrix is proved independently in the
crate metadata — `clap_complete 4.6.9` declares `clap >= 4.5.20`
(`clap_complete-4.6.9/Cargo.toml:127-130`), so `clap 4.6.6` satisfies it, and
the resolution in `## Empirical check` produced a single `clap v4.6.6` node
shared by both.

**Essential behaviors** — each verified by reading the published crate source at
the version cited, 2026-09-10:

1. `--version` renders `Command::long_version` and `-V` renders
   `Command::version`. This is not configuration; it is how the parser
   dispatches `ArgAction::Version`: `Identifier::Long` sets `use_long = true`
   and `Identifier::Short` sets `use_long = false`
   (`clap_builder-4.6.6/src/parser/parser.rs:1322-1330`), and `_render_version`
   then prefers `long_version` or `version` accordingly, each falling back to
   the other (`command.rs:4898-4914`).
2. The rendered string is `format!("{display_name} {ver}\n")`
   (`command.rs:4913`). So the version string is *appended* to the display name
   on one line rather than replacing it: give `long_version` a value whose first
   line is the bare semver, and the **first line of `--version` is
   `<tool> <semver>`**, in R4.6's GNU name-and-version shape, with the extra
   lines coming from newlines inside the `long_version` value. A `long_version`
   whose first line is not the semver would not have that property.
3. A `global = true` argument matches on every child subcommand: "Global
   arguments *only* propagate down … it doesn't matter where the user *uses* the
   global argument" (`arg.rs:877-886`, with the doctest at `:894-911` asserting
   `prog do-stuff --verbose`). This satisfies R4.5's `MUST` (before the verb)
   and its `SHOULD` (after the verb) from one declaration.
4. `Arg::env` is per-argument and reads the process environment at declaration
   time (`arg.rs:2205-2210`), gated on the `env` feature. No prefix or
   auto-binding API exists (grep, above).
5. Unknown-command matching is `strsim::jaro` with the literal threshold
   `confidence > 0.7`, sorted most-similar-last
   (`clap_builder-4.6.6/src/parser/features/suggestions.rs:17-35`). The source
   carries the maintainers' own reason for `jaro` over `jaro_winkler`: "GH
   #4660: using `jaro` because `jaro_winkler` implementation in `strsim-rs` is
   wrong causing strings with common prefix >=10 to be considered perfectly
   similar" (`:17-18`). With the `suggestions` feature off, `did_you_mean`
   returns an empty `Vec` (`:38-45`) — so the feature, which is on by default
   (`clap-4.6.6/Cargo.toml`, `default = [… "suggestions"]`), must stay on.
6. `infer_subcommands` is opt-in (`command.rs:1840`), so exact matching is the
   default. Leave it off: R3.10 `(MUST)` forbids automatic prefix abbreviation
   because "adding a flag later silently breaks scripts that relied on the
   shorter form" (`:229-230`). A suggestion that *names* `projects` after a typo
   is the conformant behavior; silently *accepting* `project` is not.
7. `clap_complete 4.6.9`'s `Shell` enum is `Bash`, `Elvish`, `Fish`,
   `PowerShell`, `Zsh` (`clap_complete-4.6.9/src/aot/shells/shell.rs:15-26`),
   covering R9.1's required three, and `aot::generate` writes to any
   `dyn Write` (`src/aot/generator/mod.rs:284-291`) — so the `completion`
   subcommand can print to stdout rather than to a file.

**Observable acceptance criteria — every one is a proposal for P03; none was
executed here** (see `## Empirical check` for what was and was not run):

| # | Criterion |
|---|---|
| AC1 | `<tool> projects list --json` and `<tool> --json projects list` both parse, and the flag is declared exactly once (R4.5) |
| AC2 | `<tool> -V` emits exactly one line matching `^<tool> \d+\.\d+\.\d+$` and exits `0` (R4.6's shape) |
| AC3 | `<tool> --version` emits that same first line plus a target-triple line and a rustc line, and the triple differs between the `ubuntu-latest` and `macos-latest` CI legs — which is what distinguishes a build script that read Cargo's `TARGET` from one carrying a hard-coded string |
| AC4 | `<tool> completion bash`, `… zsh` and `… fish` each write a non-empty script to stdout and exit `0`; a golden-file test detects drift between the parser and the emitted scripts |
| AC5 | `<TOOL>_OUTPUT=json <tool> projects list` honors the env var; a global option deliberately left out of the curated set is **not** readable from `<TOOL>_*`, asserted by a test over `Cli::command()` that enumerates every argument carrying an `env` and compares it to a pinned list (R5.4) |
| AC6 | `<tool> project list` (singular, unknown) exits `2`, prints a suggestion naming `projects` on stderr, keeps stdout byte-empty, and does **not** execute the `projects` command (R3.10 + R67) |
| AC7 | `<tool> --help` and `<tool> --version` exit `0` with output on stdout; every other parse failure exits `2` inside R67's JSON envelope on stderr |
| AC8 | every command path is `<noun> <verb>` at depth ≤ 3, asserted by walking `Cli::command().get_subcommands()` (R1.1, R1.2) |

**OVERRIDE (OV-01) — F267 extended `--version` output deviates from R4.6
`(SHOULD)`.**

**Argument:** R4.6 (`:275-279`, read 2026-09-10) says `--version`/`-V`
"**SHOULD** print a single line `acme <semver>` … a build **MAY** append
commit/date for pre-release builds". Printing a target-triple line and a rustc
line on *every* build is more than that `MAY` permits, so the recommended shape
is a deviation. It is a `SHOULD`, and the standard's own conformance clause
makes such a deviation legitimate only when recorded: "A SHOULD waiver **MUST**
name the rule ID, describe the deviation, explain the rationale, and record the
owner/date or equivalent review record" (`:50`). That owner record does not
exist yet, so this is filed as an override rather than settled. The deviation is
narrow in three ways worth stating exactly: it applies to `--version` only, `-V`
stays fully conformant, and the first line of `--version` is still
`<tool> <semver>` because clap formats `{display_name} {ver}` (essential
behavior 2 above). py's precedent for the extended content is real but is not
itself a reason — py prints three lines on *both* spellings unconditionally (py
`cli/main.py:48-56`, read through the pin 2026-09-10), which is further from
R4.6 than what is recommended here.

**Options:**

| | Option | Effect | Conformance |
|---|---|---|---|
| a | **Recommended.** `-V` one line; `--version` prints that line plus a target line and a rustc line, via `Command::long_version` | F267's information content is available from the flag a user already knows; one `long_version` string, no new command | R4.6 deviation, waiver required per `:50` |
| b | `-V` *and* `--version` both one line; extended data behind `<tool> --version -o json`, which R4.6 explicitly permits (`:277-279`) | fully conformant; costs the user a second flag to discover, and couples F267 to R66's output-format surface, which R60's prompt puts out of scope | conformant |
| c | `-V` and `--version` both one line; extended data moved to a `doctor` verb (py has one at `cli/main.py:103`) | fully conformant; separates "what version" from "what build", which is arguably the cleaner split | conformant |

The owner's ruling is needed because only the owner can record a `SHOULD`
waiver. **If the ruling is (b) or (c), nothing else in this decision changes**:
the build-metadata mechanism, the `version`/`long_version` API and every other
member are unaffected, and only the acceptance criteria AC2/AC3 are rewritten.

**BASELINE-REVIEW findings.** None. F266 and F271, the two inherited rows this
item touches, are marked `retained` in `docs/port/BASELINE-REVIEW.md:114-115`
(read 2026-09-10), and the crate-source reads above confirm both capabilities
are native to the recommended stack rather than hand-built. The Codex raw report
emits a `BASELINE-REVIEW: F269` line; that line is not carried, for the reason
given in `## Engines`.

re-verify: 2027-03-10, or earlier on any of — clap releasing a 5.x line; the `clap_complete` `unstable-dynamic` completion path stabilizing; a RustSec advisory opening against `clap`, `clap_builder`, `clap_derive`, `clap_complete` or `strsim`; R22 (`runtime-version-accessor`) resolving and changing where the version value comes from; Rust stable advancing far enough that the MSRV floor rises above a recommended crate's declared `rust-version` (the highest declared `rust-version` among the 28 dependency crates is **1.85**, shared by the five `clap`-family crates, so the current 1.96 floor has eleven minors of headroom and this trigger is remote); or the owner ruling on OVERRIDE (OV-01).

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item's prompt carries an empty `- owns:` line and an empty `- consumes:`
line, so it owns no registry parameter and consumes none; the four lines above
are the fixed parameters, copied from `docs/port/PARAMETERS.md`. No `CONFLICT:`
line is raised.

How each bears on the decision. **msrv-policy** fixes the floor at `1.96` today
(stable `1.98.1`, published 2026-09-03, minus two minors) and is what excludes
`shadow-rs`, `argh`, `lexopt` and `pico-args` at gate 2 for declaring no
`rust-version` at all, and what demotes `vergen 10.0.3` — whose declared
`1.96.0` sits exactly on the floor with no headroom — beneath a dependency-free
`build.rs`. **rust-edition** is satisfied without action: `clap 4.6.6` and
`clap_complete 4.6.9` both declare `edition = "2024"` themselves.
**license** is satisfied by the whole resolved tree — all 28 dependency crates
are MIT-or-Apache-compatible (full list in the evidence log, section W), the
only single-licensed one being `strsim` at MIT. **target-os-matrix** is the gate
this run did *not* discharge: nothing here was executed on `ubuntu-latest`, and
that gap is recorded under `## Engines`.

Three parameter-shaped notes that are deliberately **not** parameter lines.
R22 (`runtime-version-accessor`, ledger F064) supplies the version *value* that
F267 prints; it is listed in this item's prompt as "related (not a registry
dependency)", and this decision is compatible with either R22 outcome and
imposes no constraint on it. R67 owns `error-taxonomy-exit-codes`; this item
consumes none of it as a parameter, but its parser-error routing must satisfy
R67's contract, as described in `## Decision`. All three Doxa provider bodies
wrote `owns` lines for names such as `cli-parsing-framework`,
`command-surface`, `extended-version` and `blanket-global-env-binding`; no such
row exists in `docs/port/PARAMETERS.md`, and the prompt's `- owns:` line is
empty, so none of them appears above.

## Empirical check

**Toolchain and host.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; macOS 26.4, `aarch64`.
Rust stable at the retrieval date is `1.98.1`, published 2026-09-03 (`GET
https://api.github.com/repos/rust-lang/rust/releases/latest`, `tag_name`), so
the local toolchain is one patch behind stable and the MSRV floor is `1.96`.

**Working directory** for every command:
`/private/tmp/claude-501/…/scratchpad/r60` (a scratch directory). Nothing was
written into the template repository. **Nothing here implements the
recommendation**: no command surface, no `completion` command, no `build.rs`, no
CLI of any kind was written. The only Rust files created are two
resolution-only manifests, each with an empty `src/lib.rs`, which exist solely
so that `cargo` will resolve the pins.

**Full output: `review/evidence/r60-cli-parsing-verification.log`** (1,142
lines; the section numbers and letters below match the headings in that file).

| § | What it checks | Command | Result |
|---|---|---|---|
| 01 | version, license, declared MSRV, downloads for 13 candidates | `GET https://crates.io/api/v1/crates/<name>` and `/versions`, newest unyanked | `clap 4.6.6` MSRV `1.85`, `MIT OR Apache-2.0`, 226,398,266 recent / 1,119,879,906 all-time; `clap_complete 4.6.9` MSRV `1.85`; `vergen 10.0.3` MSRV **`1.96.0`**; `shadow-rs`/`argh`/`lexopt`/`pico-args` declare **no** `rust_version`; `argh` is `BSD-3-Clause` |
| 02 | repository state and open issues | `GET https://api.github.com/repos/<o>/<r>`; `GET /search/issues?q=repo:<o>/<r>+is:issue+is:open` | `clap-rs/clap` 16,697 stars, `archived` false, `pushed_at` 2026-09-09, **369** open issues; `pico-args` `pushed_at` 2023-10-19 |
| 02–03 | advisories, with the 404 reading validated | `GET https://rustsec.org/packages/<name>.html` | 404 for all eight recommended-or-runner-up crates; controls `anyhow` → 200 `RUSTSEC-2026-0190` and `atty` → 200 (two IDs) confirm 404 means "no advisory page" |
| 04 | clap behavior, read in the published tarball | `curl https://static.crates.io/crates/clap/clap-4.6.6.crate` (sha256 `473c7e07f409a8d772161724aa8db6a765a2532a70f9667eeb7b49d3d02fbdca`) and the three companion tarballs, unpacked | the seven essential behaviors listed in `## Decision`, each at a cited file and line; `default = [std,color,help,usage,error-context,suggestions]`; **no** `env_prefix`/`auto_env`/`envvar_prefix` symbol anywhere in `clap_builder` or `clap_derive` |
| 05 | completion generator | read `clap_complete-4.6.9` | `Shell` = Bash/Elvish/Fish/PowerShell/Zsh; depends on `clap >= 4.5.20` with `default-features = false` |
| 06 | build-metadata mechanism | `rustc -vV`; `GET https://doc.rust-lang.org/cargo/reference/environment-variables.html` | `rustc -vV` prints `release:`, `host:`, `commit-hash:`; the Cargo reference lists `TARGET`, `HOST`, `RUSTC`, `PROFILE` among the variables Cargo sets **for build scripts** — the two facts the dependency-free `build.rs` relies on |
| 07 | do the recommended pins resolve at the floor | `cargo generate-lockfile` and `cargo tree -e normal` on a manifest with `rust-version = "1.96"`, `edition = "2024"` and the two dependency lines | **exit 0** — "Locking 28 packages to latest Rust 1.96 compatible versions"; one shared `clap v4.6.6` node under both dependencies; `strsim v0.11.1` present transitively under `clap_builder`, never direct |
| 08 | advisories and licenses of the resolved tree | `cargo audit`; per-crate registry license lookup for all 28 | `cargo audit` **exit 0**, 1,243 advisories loaded, 29 crate dependencies scanned, nothing reported; every license MIT-or-Apache-compatible, `strsim` MIT the only single-licensed one |
| 09 | `vergen` MSRV headroom | the same resolution with `rust-version` `1.96`, then `1.95` | resolves at `1.96`; at `1.95` Cargo reports "Adding vergen v10.0.3 (requires Rust 1.96.0)" |
| 10 | the two source repositories, through their pins | `git -C ~/c/py-launch-blueprint show b08bccfb…:<path>`; `git -C ~/c/ts-launch-blueprint show cb1cbcb2…:<path>` | every `## Context` line confirmed: py `import click`, the three-line eager `_print_version`, `"auto_envvar_prefix": APP_NAME.upper()` with its "catch-all" comment, `COMMAND_GROUPS`, four explicit `envvar=` names, the `_GLOBAL_OPTIONS` re-application loop, `difflib.get_close_matches`; ts `import { Command, CommanderError }`, `.showSuggestionAfterError(true)`, root-only `.option(…)`, `.command('projects', { isDefault: true })`, and the comment "Usage errors must exit 2 (cli-standards R6.1)" |
| 11 | adopter manifests | `GET /repos/<o>/<r>/contents/Cargo.toml`, base64-decoded, for seven projects | the practice-evidence table in `## Decision`; `casey/just` carries this decision's exact feature set; `starship` carries `shadow-rs`; `ripgrep` carries `lexopt` and no clap |
| 12 | MSRV of the whole resolved tree | `cargo metadata --format-version 1 --all-features` | 28 of the 29 packages declare a `rust-version`; the highest among the dependencies is **1.85**, shared by `clap`, `clap_builder`, `clap_complete`, `clap_derive` and `clap_lex`; `utf8parse` declares none |

**Headline command and exit status.** `cargo generate-lockfile` on the
recommended pins at `rust-version = "1.96"` → **exit 0**, followed by
`cargo audit` on the resulting lockfile → **exit 0**.

**What this run does not establish**, stated so it is not read as more: it did
not build or run any CLI; it did not execute any acceptance criterion; it ran no
benchmark; it ran nothing on `ubuntu-latest`; and it did not audit any crate's
`unsafe` usage. Each of those is carried to `## Engines`.

## Engines

- codex `raw/codex-99cfaa33b3ae00b921df4ad482e3b1a73a9f787eaa4d138197f544d3491cfb05.md` — figures retrieved 2026-09-05; three members (`clap 4.6.6`, `clap_complete 4.6.9`, `vergen 10.0.3`); states it could not compute issue responsiveness.
- opus `raw/opus-26f8720eb4b2714cb14fdca45302b55449205a5c3889909e881aa7116aff7735.md` — figures retrieved 2026-09-10; seven members, one per ledger row; the most complete report, and the only one that read the crate source rather than the documentation.
- doxa `raw/doxa.normalized.md` — three provider bodies regrouped by template field (`doxa-openai.normalized.md`, `doxa-perplexity.normalized.md`, `doxa-gemini.normalized.md`; repairs recorded in `doxa/normalization.json`), retrieved 2026-09-09.

**Where the engines agreed.** All three name `clap` as the framework and
`clap_complete` for F268; all three choose noun-verb subcommand groups over ts's
default-command shape for F265; all three choose `global = true` on a flattened
`GlobalArgs` for F270; and all three keep clap's built-in suggestions for F272
with no direct `strsim`. That agreement is not itself the evidence — the source
reads and the fitness gates in `## Decision` are — but no disagreement had to be
resolved on those four rows.

**Disagreement 1 — where the extended `--version` metadata comes from.** Codex
recommends `vergen 10.0.3` (`cargo` + `rustc` features); Opus recommends a
dependency-free `build.rs` with `built 0.8.1` ranked second; the Doxa OpenAI
body also recommends a plain `build.rs`; the Doxa Gemini body recommends
`shadow-rs`. **Settled by the registry and by resolution**, both in this run:
`shadow-rs 2.0.0` declares no `rust-version`, so it fails gate 2 on evidence;
`vergen 10.0.3` declares `1.96.0`, exactly today's floor, and Cargo reports it
as out of range the moment the floor is one minor lower — a permanent
maintenance coupling that Codex's report does not mention; the Cargo reference
plus `rustc -vV` confirm that `TARGET` and the rustc version are both reachable
from a build script with no crate at all. Hence the dependency-free script, with
`built 0.8.1` (MSRV `1.87`, real headroom) as the ranked runner-up and `vergen`
available if git-derived metadata later becomes a requirement. Note that
`starship/starship`, a well-regarded adopter, does ship `shadow-rs 2.0.0`
(`Cargo.toml:79`, verified 2026-09-10) — the exclusion is on declared-MSRV
evidence under this template's policy, not on the crate's quality.

**Disagreement 2 — blanket versus curated env binding (F269).** The Doxa OpenAI
body recommends automatic `PLBP_<UPPER_SNAKE_LONG_NAME>` binding generated by a
command-graph post-pass "for every application-defined global", and the Doxa
Perplexity body likewise recommends "blanket env-var binding using a standard
prefix such as `PLBP_` … via a small helper or macro that applies the prefix
automatically to each global option". Codex and Opus both recommend a curated
per-option mapping. **Settled by the org CLI Design Standard**, R5.4 `(MUST)`:
"the tool **MUST NOT** auto-expose every flag as an env var"
(`/Users/stevemorin/c/cli-standards/cli-design-standard.md:321-323`, read
2026-09-10), org-locked at `:70` row 7, and already treated as binding by the
published R67. The blanket designs are excluded on that rule alone. Both
blanket proposals are *mechanically* sound — `Command::mut_args` exists and
would do exactly what they describe — and this decision says so rather than
resting the exclusion on a capability claim that the source does not support.

**Disagreement 3 — is the standard binding on R60 at all?** The Opus report
raises this explicitly, treating the standard as "an owner-side requirement
input that the owner should confirm applies to R60 as well as R67", and keeps
its ecosystem case independent of it. **Settled against that framing**, on the
task's direction and on precedent: the published R67 adjudicates the same
document's R6.1 as an org-locked `MUST` and quotes its table verbatim, and ts's
own router cites `cli-standards R6.1` in a code comment. This decision therefore
cites the standard by file, line and retrieval date as R67 did. The practical
effect is confined: it makes F265 a `MUST` rather than a preference, it decides
F269, and it turns F267 into a recorded override — every other row lands where
all three engines already put it.

**Disagreement 4 — Codex's `BASELINE-REVIEW: F269` line is not carried.** The
prompt reserves `BASELINE-REVIEW:` for a *challenged baseline*. F269 is a
`DIVERGENT`, py-only row owned by this item
(`docs/port/COMMONALITY.md:273`), not an inherited baseline; the only baseline
rows this item touches are F266 and F271, both already `retained`. Deciding F269
against a curated mapping is this item's job, so it is recorded as the decision
rather than as a challenge to a baseline. The substance of Codex's line — that
an implicit prefix would silently turn every newly added global flag into a
public environment API — is preserved in `## Decision` and in acceptance
criterion AC5.

**Disagreement 5 — Doxa's parameter lines.** All three Doxa bodies write `owns`
lines for names that do not exist in `docs/port/PARAMETERS.md`, and the OpenAI
body additionally writes `assumes current rust-version = 1.96.0`. This item's
prompt carries an empty `- owns:` line, so `## Parameters` above carries only
the four fixed `assumes` values. No engine raised a `CONFLICT:`; none is raised
here.

**Doxa's own evidence gap, carried rather than repaired.** The regrouped Doxa
report opens with an "Evidence-completeness warning" stating that its transport
did not expose the crates.io JSON bodies, so its download, star and
responsiveness cells are marked pending rather than invented
(`doxa.normalized.md:38`). Its architecture reasoning is used above; none of its
figures is. Every registry and GitHub figure in this decision comes from the run
in `## Empirical check` or, where attributed, from the Opus report at its stated
retrieval date.

**Unproven claims, and what would prove each.** P03 must validate all of these
in the real template:

| # | Unproven | What would prove it |
|---|---|---|
| U1 | That `clap 4.6.6`, `clap_complete 4.6.9` and the transitive tree build and test on **`ubuntu-latest`** — gate 4. Nothing in this run executed on Linux; the resolution and the crate reads were done on macOS 26.4 `aarch64` only. | the template's own CI matrix running `cargo test` on both runners |
| U2 | The compile-time and binary-size cost **at 4.6.6, with the `derive`/`env`/`string`/`wrap_help` feature set, on this template's two runners**. The only figures cited anywhere in this decision are upstream `rosetta-rs` results measured by that project on Linux `x86_64` with `rustc 1.94.0` at clap **v4.5.60**; neither Opus nor this decision ran a benchmark. | `cargo bloat` or `cargo build --timings` on the built template, on each runner |
| U3 | The `unsafe` posture of `clap`, `clap_builder`, `clap_derive`, `clap_complete` and `strsim` — gate 3's second half, not assessed in this run. | `cargo geiger`, or reading each crate's `#![forbid(unsafe_code)]`/`unsafe` blocks at the pinned versions |
| U4 | That clap's usage text can be rendered **inside** R67's JSON envelope without losing clap's own formatting, and what the envelope's `message` and `hint` carry for a parse failure. This decision fixes the routing (`try_parse` + `kind()`) and the codes; it does not fix the rendering. | AC6/AC7 executed against the built CLI |
| U5 | Every acceptance criterion AC1–AC8. None was executed: no Rust CLI exists. | P03's integration tests |
| U6 | Issue responsiveness for every candidate except `clap-rs/clap`. The Opus report measured the 10 most recently opened issues for that one repository (5 of 10 answered, median 1.29 days among those answered, 5 unanswered, retrieved 2026-09-10) and states it measured no other; that figure also covers `clap_complete`, which shares the tracker. For `bpaf`, `built`, `vergen`, `argh`, `lexopt`, `pico-args` and `strsim`, the maintenance verdicts above rest on open-issue `total_count`, `pushed_at`, `archived` and release recency only. | the same 10-issue procedure run per candidate |
| U7 | That `bpaf` lacks a completion story equivalent to `clap_complete`. Opus asserts it does; Codex asserts a completion feature exists. Neither was verified here, and `bpaf` is excluded on fit (architecture D) rather than on this point, so the disagreement does not change the recommendation. | reading `bpaf 0.9.27`'s published source and feature table |

**Uncertainty that is not an evidence gap.** `clap-rs/clap` carries 369 open
issues against a project led by a single primary maintainer, which is a real
backlog signal. It does not meet the rubric's `at-risk` bar — no unpatched
advisory, no broken build on current stable, no maintainer notice, and releases
continuing (newest `4.6.6`, `created_at` 2026-08-06; repository `pushed_at`
2026-09-09) — so the maintenance verdict recorded here is **`active`**. If a
future re-verification finds the release cadence broken *and* the backlog
growing, architecture D (`bpaf`) is the shortlisted successor and U7 becomes the
first thing to settle.
