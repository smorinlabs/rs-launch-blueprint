### Landscape

**Category.** This item selects a typed Rust command-line parser and the small
supporting stack that turns one command schema into help, completion scripts,
version metadata, environment configuration, and typo diagnostics.  The
three-bin map below was made before choosing a framework.  Retrieval date for
every linked source and endpoint in this report is **2026-09-05**.

| Bin | Candidates found | Why they are in this bin |
|---|---|---|
| Built-in or first-party toolchain | `std::env::args_os`; Cargo's `rust-version` contract | `args_os` supplies only raw OS strings, so it supplies none of schema validation, generated help, completions, environment mapping, or suggestions.  Cargo owns the MSRV declaration and resolver contract, not CLI parsing. [Rust std `args_os`](https://doc.rust-lang.org/std/env/fn.args_os.html); [Cargo `rust-version`](https://doc.rust-lang.org/cargo/reference/rust-version.html). |
| Established industry standard | `clap` 4.6.6; `clap_complete` 4.6.9; `argh` 0.1.19; `bpaf` 0.9.27 | The Rust CLI Book names `clap` the most popular parser and documents subcommands, completions, and help.  `clap`'s maintained documentation is the framework authority; `argh` and `bpaf` are established alternatives with current registry releases. [Rust CLI Book](https://rust-cli.github.io/book/tutorial/cli-args.html); [clap docs](https://docs.rs/clap/latest/clap/); [argh registry endpoint](https://crates.io/api/v1/crates/argh); [bpaf registry endpoint](https://crates.io/api/v1/crates/bpaf). |
| Up-and-comer or deliberately minimal | `lexopt` 0.3.2; `pico-args` 0.5.0; a custom parser on `args_os` | These crates intentionally leave help, completion, environment, and suggestion policy to the application.  They are valid for a very small single-purpose binary, but their missing capabilities would make this template reimplement the bundle. [lexopt registry endpoint](https://crates.io/api/v1/crates/lexopt); [pico-args registry endpoint](https://crates.io/api/v1/crates/pico-args). |

**Authorities and why they count.** The Rust project publishes Cargo's
`rust-version` behavior, which is the authoritative statement of the target's
MSRV mechanism.  The Rust CLI Book is a maintained Rust-community CLI guide and
explicitly teaches Clap.  `clap` and `vergen` documentation is primary
maintainer documentation for their public APIs.  crates.io's API is the
registry's source of download, release, license, and declared-MS RV figures;
GitHub's REST API is the source for repository activity, stars, archival state,
and open-issue counts. [Cargo Book](https://doc.rust-lang.org/cargo/reference/rust-version.html); [Rust CLI Book](https://rust-cli.github.io/book/tutorial/cli-args.html); [clap docs](https://docs.rs/clap/latest/clap/); [vergen docs](https://docs.rs/vergen/latest/vergen/); [crates.io API](https://crates.io/data-access); [GitHub repository API](https://docs.github.com/en/rest/repos/repos#get-a-repository).

**Practice evidence, rather than familiarity.** Rust's own Cargo workspace
declares `clap = "4.6.0"` and `clap_complete = "4.6.0"`; rustup declares
`clap` plus `clap_complete`; these are maintained Rust-project tools rather than
toy examples. [Cargo manifest](https://github.com/rust-lang/cargo/blob/master/Cargo.toml); [rustup manifest](https://github.com/rust-lang/rustup/blob/master/Cargo.toml).
The maintained Typstyle CLI composes `clap` with `derive` and `env`,
`clap_complete`, and `vergen` with `build`, `cargo`, and `rustc` features, making
it a direct whole-stack reference pattern even though it currently pins the 9.x
Vergen line. [Typstyle manifest](https://github.com/typstyle-rs/typstyle/blob/master/Cargo.toml).
These examples are relevant because each ships a multi-command Rust binary;
Cargo and rustup additionally demonstrate long-lived Rust-project maintenance.

Registry comparison figures below are direct responses from the specified
endpoints, not estimates.  "Release" means the newest non-yanked version in
the versions endpoint.  The MSRV column is the crate metadata declaration; a
missing value is not proof that the candidate satisfies this template's MSRV
gate.

| Candidate | 90-day / all-time downloads | Release / declared MSRV | GitHub stars; archived; pushed | Open issues | Result before popularity |
|---|---:|---|---|---:|---|
| `clap` | 227,534,664 / 1,106,521,607 | 4.6.6, 2026-08-06; 1.85 | 16,686; false; 2026-09-02 | 369 | Qualifies provisionally; complete feature match. [crate](https://crates.io/api/v1/crates/clap), [versions](https://crates.io/api/v1/crates/clap/versions), [repo](https://api.github.com/repos/clap-rs/clap), [issues](https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open). |
| `argh` | 2,585,370 / 15,826,225 | 0.1.19, 2026-03-16; undeclared | 1,954; false; 2026-05-27 | 64 | Excluded by MSRV-evidence gate and bundle-capability gap. [crate](https://crates.io/api/v1/crates/argh), [versions](https://crates.io/api/v1/crates/argh/versions), [repo](https://api.github.com/repos/google/argh), [issues](https://api.github.com/search/issues?q=repo:google/argh+is:issue+is:open). |
| `bpaf` | 1,669,335 / 7,677,791 | 0.9.27, 2026-07-29; 1.68 | 461; false; 2026-09-05 | 62 | Qualified runner-up; completion feature exists, but no equivalent integrated environment/suggestion stack was verified. [crate](https://crates.io/api/v1/crates/bpaf), [versions](https://crates.io/api/v1/crates/bpaf/versions), [repo](https://api.github.com/repos/pacak/bpaf), [issues](https://api.github.com/search/issues?q=repo:pacak/bpaf+is:issue+is:open). |
| `lexopt` | 2,656,842 / 12,285,660 | 0.3.2, 2026-02-28; undeclared | 419; false; 2026-02-28 | endpoint returned no count | Excluded by MSRV-evidence gate and deliberate low-level scope. [crate](https://crates.io/api/v1/crates/lexopt), [versions](https://crates.io/api/v1/crates/lexopt/versions), [repo](https://api.github.com/repos/blyxxyz/lexopt), [issues](https://api.github.com/search/issues?q=repo:blyxxyz/lexopt+is:issue+is:open). |
| `pico-args` | 17,193,945 / 71,795,790 | 0.5.0, 2022-06-04; undeclared | 648; false; 2023-10-19 | endpoint returned no count | Excluded by MSRV-evidence gate, feature gap, and stale release/activity requiring investigation. [crate](https://crates.io/api/v1/crates/pico-args), [versions](https://crates.io/api/v1/crates/pico-args/versions), [repo](https://api.github.com/repos/RazrFalcon/pico-args), [issues](https://api.github.com/search/issues?q=repo:RazrFalcon/pico-args+is:issue+is:open). |

No candidate is selected from download count alone.  In particular, the
documented compile-time and binary-size cost of a full parser is accepted only
because this template needs the framework's generated UX and shared schema;
the parser runs once at process startup, not in the library or web-service hot
path.  Clap's documentation identifies its intended polished CLI facilities,
including suggestions and completions. [clap aspirations and related crates](https://docs.rs/clap/latest/clap/).

### Principles and implementation

**Shared requirement and agreement level.** F266 and F271 are `COMMON → REUSE`:
the product must expose `-V`/`--version` and an unknown-command
did-you-mean diagnostic.  The agreement is capability-level, not a requirement
to reuse Click's callback or Commander's implementation.  F264, F265, F267,
F268, F269, F270, and F272 are `DIVERGENT`; their source facts are recorded in
[the CLI-framework ledger evidence](https://github.com/smorinlabs/rs-launch-blueprint/blob/main/docs/port/areas/cli-framework-ux.md), retrieved 2026-09-05.

The preserved principle is: **declare the whole public CLI once as typed input,
then derive consistent discoverability and validation from that declaration
while keeping business operations independent of the parser.** The source
blueprints agree on discoverable commands, version access, configuration flags,
and typo recovery, but disagree on the parser and command geometry.  Clap's
derive and builder APIs are both suitable; use derive for the static command
tree and keep a `command()` factory for completion generation and parser tests.
The CLI Book's guidance to parse into a type, together with Clap's `Parser` and
`CommandFactory` APIs, supports that native pattern. [CLI Book typed-input
example](https://rust-cli.github.io/book/tutorial/cli-args.html); [Clap derive
reference](https://docs.rs/clap/latest/clap/_derive/).

**Architectural alternatives.** A flat default command reduces one word for a
single primary operation, but it makes `projects` exceptional and turns future
top-level operations into a crowded root.  A noun-verb tree (`projects list`,
`projects add`, `config set`) places each resource's verbs in an enum/module,
makes help and completions disclose the hierarchy, and gives the library a
typed command value to translate into an application use case.  Neither
architecture changes HTTP or library APIs.  Clap does not make the tree
materially more expensive: nested `Subcommand` enums are first-class. [Clap
subcommand derive reference](https://docs.rs/clap/latest/clap/_derive/).

Adopt the noun-verb tree, with no default command.  This is a deliberate choice
for the current py surface, not an assertion that the py parser is the winner;
the ledger notes that the TypeScript shape came from an older flat py CLI.

`--version` needs two outputs, not an eager callback: configure Clap's short
`version` for `-V` and `long_version` for `--version`.  Clap renders the latter
for its built-in version action.  A build script uses Vergen to emit Cargo
environment values, and a small local `build_info` module builds a static long
version containing package version from R22 plus `VERGEN_CARGO_TARGET_TRIPLE`
and `VERGEN_RUSTC_SEMVER`.  Vergen's documented `cargo` and `rustc` features
emit `cargo:rustc-env` values that `env!` or `option_env!` can read. [Clap
`Command::long_version`](https://docs.rs/clap/latest/clap/struct.Command.html#method.long_version); [Vergen usage](https://docs.rs/vergen/latest/vergen/); [Vergen keys](https://docs.rs/vergen-lib/latest/vergen_lib/enum.VergenKey.html).

For F268, implement the regular `completion <shell>` subcommand and call
`clap_complete::generate` against a fresh `Cli::command()`.  It emits Bash,
Zsh, and Fish scripts from the same command declaration, so generated scripts
cannot drift from the parser. [clap_complete AOT API](https://docs.rs/clap_complete/latest/clap_complete/aot/); [supported shells](https://docs.rs/clap_complete/latest/clap_complete/aot/enum.Shell.html).

For F270, each global field lives once at the root and has
`#[arg(global = true)]`; Clap documents that global arguments apply to child
subcommands and can be used wherever the user is in that tree.  Thus
`plbp projects list --json` and `plbp --json projects list` are both accepted
without redeclaring `--json` for every leaf. [Clap `Arg::global`](https://docs.rs/clap/latest/clap/struct.Arg.html#method.global).

For F272, retain Clap's default `suggestions` feature; do not add `strsim` as a
direct dependency and do not enable `infer_subcommands`.  The former offers a
diagnostic for an invalid name; the latter would silently accept prefixes and
changes the public command contract.  The integration test must assert a
suggestion for `project` while rejecting it. Clap classifies this as
`InvalidSubcommand`. [Clap features](https://crates.io/api/v1/crates/clap/versions); [Clap error kinds](https://docs.rs/clap/latest/clap/error/enum.ErrorKind.html).

BASELINE-REVIEW: F269 — environment-driven configuration must be explicit,
auditable, and able to exclude unsafe or interactive flags — replace Click's
implicit `PLBP_*` auto-prefix behavior with one `#[arg(env = "PLBP_...")]`
mapping for every approved global option, generated or checked by a local
table/test — Clap's `env` feature documents per-argument binding, not a global
prefix switch; an explicit table prevents a newly added global flag from
silently becoming an environment API and makes secret handling reviewable
(affected item: R60). [Clap derive `env`](https://docs.rs/clap/latest/clap/_derive/); [Clap `Arg::env`](https://docs.rs/clap/latest/clap/struct.Arg.html#method.env).

**Minimal realistic example (proposed; not executed in this empty Rust
template).** `src/cli/mod.rs` defines `Cli { global: GlobalArgs, command:
Command }`; `Command` contains `Projects(ProjectsCommand)`,
`Config(ConfigCommand)`, and `Completion { shell }`. `src/main.rs` parses once,
turns the enum into a library-facing request, and maps the application result to
the R67 contract. `build.rs` calls Vergen's `Emitter` with `cargo` and `rustc`.
The library and web-service crates never depend on `clap`.

### Recommendation

Adopt this one stack and reference pattern:

```toml
[dependencies]
clap = { version = "4.6.6", features = ["derive", "env"] }
clap_complete = "4.6.9"

[build-dependencies]
vergen = { version = "10.0.3", features = ["cargo", "rustc"] }
```

Use Clap derive types for a noun-verb command tree with no default command;
root-only, `global = true` options; explicit `PLBP_*` environment names per
approved option; Clap's built-in suggestions; `version` plus `long_version`;
and a `completion bash|zsh|fish` subcommand generated by `clap_complete`.
Use Vergen only at build time for target triple and rustc version.  Keep the
CLI adapter in the binary crate; pass typed command/use-case input to the
library so the web service has no CLI-parser dependency.  Versions are the
latest non-yanked releases observed at their registry endpoints on 2026-09-05.

### Members

#### clap 4.6.6

##### Landscape

`clap` is the established full-schema parser in this survey.  Its 227,534,664
90-day and 1,106,521,607 all-time downloads, 4.6.6 release on 2026-08-06, and
declared MSRV 1.85 come from the registry endpoints. [crate](https://crates.io/api/v1/crates/clap); [versions](https://crates.io/api/v1/crates/clap/versions).
GitHub reports 16,686 stars, `archived: false`, and push activity on
2026-09-02; its issue-search endpoint reports 369 open issues. [repo](https://api.github.com/repos/clap-rs/clap); [issues](https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open).
Maintenance state: **active** (recent release and push), not inferred from
stars alone.

##### Principles and implementation

Clap provides typed parsing, nested subcommands, help, version actions,
per-argument environment values, global arguments, and suggestions from one
schema.  `derive` maps the stable static command tree into Rust types; its
builder API remains available for `long_version` and test construction. [Clap
docs](https://docs.rs/clap/latest/clap/); [derive reference](https://docs.rs/clap/latest/clap/_derive/).

##### Dominant choice

Use `clap = { version = "4.6.6", features = ["derive", "env"] }`.  The
registry reports default features `std`, `color`, `help`, `usage`,
`error-context`, and `suggestions`; `derive` and `env` are opt-in.  It has no
async-runtime coupling. [features endpoint](https://crates.io/api/v1/crates/clap/versions).

##### Qualified shortlist

`bpaf` 0.9.27 is the qualified framework runner-up: 1,669,335 90-day,
7,677,791 all-time downloads; release 2026-07-29; declared MSRV 1.68; MIT OR
Apache-2.0; 461 stars; active push on 2026-09-05; 62 open issues. [crate](https://crates.io/api/v1/crates/bpaf); [versions](https://crates.io/api/v1/crates/bpaf/versions); [repo](https://api.github.com/repos/pacak/bpaf); [issues](https://api.github.com/search/issues?q=repo:pacak/bpaf+is:issue+is:open).
Its `autocomplete` and `derive` features show a viable smaller alternative,
but its documented all-bundle parity was not established in this run. [bpaf
features](https://crates.io/api/v1/crates/bpaf/versions).

##### Excluded by gate

`argh` 0.1.19 is BSD-3-Clause-compatible but has no declared `rust_version` in
the registry, so it fails this template's evidence gate before popularity is
weighed; its crate figures are 2,585,370 / 15,826,225 downloads and a
2026-03-16 release. [argh crate](https://crates.io/api/v1/crates/argh); [argh versions](https://crates.io/api/v1/crates/argh/versions).
`lexopt` 0.3.2 and `pico-args` 0.5.0 likewise omit `rust_version`; they also
intentionally leave the required generated UX to application code. Pico-args'
2022-06-04 release and 2023-10-19 last push require investigation under the
maintenance rubric. [lexopt](https://crates.io/api/v1/crates/lexopt/versions); [pico-args](https://crates.io/api/v1/crates/pico-args/versions); [pico-args repo](https://api.github.com/repos/RazrFalcon/pico-args).

##### Up-and-comers

`lexopt` and `pico-args` remain useful for a dependency-minimal, manually
designed binary, not for the template's schema-derived command tree.  Their
compact compile and binary footprint is the tradeoff for reimplementing this
item's completion, environment, and suggestion behavior. [lexopt docs](https://docs.rs/lexopt/latest/lexopt/); [pico-args docs](https://docs.rs/pico-args/latest/pico_args/).

##### Fit for this template

License gate: pass, `MIT OR Apache-2.0`. MSRV gate: declared 1.85 is below the
current local Rust 1.98.0's stable-minus-two floor (1.96); the final lockfile
still must be compiled under the declared floor, because a top-level declaration
does not prove every resolved dependency's MSRV. [clap versions](https://crates.io/api/v1/crates/clap/versions); [Cargo MSRV behavior](https://doc.rust-lang.org/cargo/reference/rust-version.html).
Security gate: unverified for the final dependency graph; the requested
`https://rustsec.org/packages/clap.html` endpoint returned HTTP 404, and this
empty template has no lockfile for `cargo audit`. Unsafe posture: Clap need not
introduce application `unsafe`; transitive unsafe review is unverified and
belongs in the selected dependency graph/security checks. OS gate: unexecuted;
require the proposed Ubuntu and macOS CI legs. Cost: higher compile time and
binary size than `lexopt` because `derive`, help, diagnostics, and suggestions
are compiled; it is isolated to the binary crate and is not on service request
paths. Default features and async coupling are stated above.

##### Recommendation

Select Clap.  Do not make `strsim` a direct dependency: Clap's default
`suggestions` feature owns the matching implementation.  Do not enable prefix
acceptance through `infer_subcommands`. [Clap features](https://crates.io/api/v1/crates/clap/versions); [Clap command API](https://docs.rs/clap/latest/clap/struct.Command.html).

##### Ranked runner-up

`bpaf` 0.9.27 ranks second.  It is active and MSRV-compatible on its declared
metadata, but it leaves more bundle composition to local code and has far less
observed adoption for this exact stack. [bpaf registry](https://crates.io/api/v1/crates/bpaf); [bpaf repository](https://api.github.com/repos/pacak/bpaf).

##### Tradeoffs

Clap's cost is compilation and output size, especially from `derive`; its
benefit is one maintained source of truth for help, validation, completion
generation, global option placement, and suggestions.  Parsing is a one-time
startup workload, so no throughput or request-latency claim is made.  The
template must measure stripped release binary size and cold `cargo build` time
against a no-parser baseline rather than claim an absolute performance winner.

##### Parameters

No R60-owned parameter is registered. Assumes `rust-edition = 2024`,
`msrv-policy = stable minus 2 minor versions`, `license = MIT OR Apache-2.0`,
and `target-os-matrix = ubuntu-latest, macos-latest`; no conflict found.

##### Migration implications

Add the Clap dependency only to the binary package's `Cargo.toml`; create
`src/cli/mod.rs`, `src/cli/global.rs`, `src/cli/projects.rs`, and
`src/cli/config.rs`; keep `src/lib.rs` free of Clap types.  This is proposed
template structure, not an edit to the current research-only repository.

##### Validation strategy

Planned integration tests invoke the built binary with `projects list --json`,
`--json projects list`, an invalid `project` subcommand, `-V`, and `--version`.
Expected results are identical parsed global values in the first two cases, a
nonzero invalid-subcommand result with a suggestion, a short version for `-V`,
and multiline build information for `--version`.  No command was executed:
there is no Rust template to compile.

##### Confidence & re-verify trigger

High confidence in framework fit; medium confidence in the future locked
dependency-tree MSRV/security gate. Re-verify on a Clap minor/major update, an
MSRV-policy floor change, a RustSec advisory, or a failed Ubuntu/macOS parser
fixture.

##### Sources

Primary sources: [clap registry](https://crates.io/api/v1/crates/clap), [clap
versions](https://crates.io/api/v1/crates/clap/versions), [clap repository](https://api.github.com/repos/clap-rs/clap), [clap open-issue search](https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open), [Clap documentation](https://docs.rs/clap/latest/clap/), all retrieved 2026-09-05.

#### clap_complete 4.6.9

##### Landscape

`clap_complete` is Clap's maintained companion for shell-completion generation.
Its registry figures are 27,238,115 90-day and 109,918,829 all-time downloads;
the newest non-yanked release is 4.6.9 from 2026-08-06 with declared MSRV 1.85.
[crate](https://crates.io/api/v1/crates/clap_complete); [versions](https://crates.io/api/v1/crates/clap_complete/versions).
It shares the active, unarchived Clap repository: 16,686 stars, push activity
on 2026-09-02, and 369 open issues at the repository-wide search endpoint.
[repo](https://api.github.com/repos/clap-rs/clap); [issues](https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open).
Maintenance state: **active**.

##### Principles and implementation

Generate scripts from the exact `Command` schema used to parse input.  The
maintained AOT API exposes `generate` and `Shell`, including Bash, Zsh, and
Fish.  This meets F268 without hand-maintained scripts. [AOT API](https://docs.rs/clap_complete/latest/clap_complete/aot/); [Shell enum](https://docs.rs/clap_complete/latest/clap_complete/aot/enum.Shell.html).

##### Dominant choice

Use `clap_complete = "4.6.9"` with its empty default feature set.  It has no
async-runtime coupling.  Do not enable `unstable-dynamic`: the required
`completion <shell>` command is AOT script emission, not runtime programmable
completion. [features endpoint](https://crates.io/api/v1/crates/clap_complete/versions).

##### Qualified shortlist

The qualified alternative is hand-written scripts or invoking shell-specific
generators.  It has no crate figures because it is an architectural pattern,
not a crate candidate; it fails the one-schema principle because every command
change needs duplicated shell work. Clap's own documentation lists
`clap_complete` as its completion companion. [Clap related crates](https://docs.rs/clap/latest/clap/).

##### Excluded by gate

No separate completion crate was selected.  A hand-maintained pattern is
excluded by the schema-drift acceptance criterion, not by license or MSRV.

##### Up-and-comers

Environment-activated completions in the same project are deliberately out of
scope for this command surface: they ask the shell to invoke the CLI during
completion rather than write an explicit script. [clap_complete environment API](https://docs.rs/clap_complete/latest/clap_complete/env/).

##### Fit for this template

License gate: pass, `MIT OR Apache-2.0`. MSRV gate: declared 1.85 is below the
current 1.96 floor described above; final locked-graph compilation remains
required. Security gate: unverified; the requested RustSec package URL returned
HTTP 404 and no lockfile exists. Unsafe posture: unverified transitively; no
application unsafe is required. OS gate: planned Ubuntu/macOS script-generation
and shell syntax checks. Default features: empty; async runtime: none. Cost:
the generator is linked into the CLI binary, adding compile/binary cost only to
support a command that emits scripts; it is not linked into the library/service.
[versions endpoint](https://crates.io/api/v1/crates/clap_complete/versions).

##### Recommendation

Select 4.6.9 and implement `plbp completion bash|zsh|fish`, writing only the
script to stdout.  The command calls `Cli::command()` anew before `generate`,
so it has the complete root command tree. [generation example](https://docs.rs/clap_complete/latest/clap_complete/aot/).

##### Ranked runner-up

No crate runner-up: generated scripts from the maintained framework companion
are preferable to a second independent completion model.

##### Tradeoffs

The runtime generator adds a dependency and binary code.  The alternative
saves that cost but introduces manual script maintenance and risks a command
surface that parses differently from what shells complete.  No comparative
latency or throughput figure was collected because script generation is an
operator-invoked, non-hot-path command.

##### Parameters

No owned or consumed registry parameter and no conflict.  Assumes the fixed
edition, MSRV policy, license, and Ubuntu/macOS CI matrix.

##### Migration implications

Add `src/cli/completion.rs` (or a `Completion` command arm) and a test fixture
directory for Bash, Zsh, and Fish outputs.  No library or web-service file
imports this crate.

##### Validation strategy

Planned commands are `plbp completion bash`, `plbp completion zsh`, and
`plbp completion fish`; capture stdout and run each available shell's syntax
check in its matching CI fixture. Expected behavior: every script names
`projects`, `config`, their verbs, and global flags from the same Clap schema.
No output was generated in this research-only checkout.

##### Confidence & re-verify trigger

High for the required three shells. Re-verify on a Clap/clap_complete major
change or if a generated script fails its shell syntax/completion fixture.

##### Sources

Primary sources: [registry](https://crates.io/api/v1/crates/clap_complete),
[versions](https://crates.io/api/v1/crates/clap_complete/versions), [AOT docs](https://docs.rs/clap_complete/latest/clap_complete/aot/), [shell list](https://docs.rs/clap_complete/latest/clap_complete/aot/enum.Shell.html), retrieved 2026-09-05.

#### vergen 10.0.3

##### Landscape

`vergen` is a build-dependency candidate for extended version/build metadata,
not a parser.  Its registry reports 8,046,848 90-day and 50,513,645 all-time
downloads; the newest non-yanked release is 10.0.3 from 2026-08-24 with
declared MSRV 1.96. [crate](https://crates.io/api/v1/crates/vergen); [versions](https://crates.io/api/v1/crates/vergen/versions).
GitHub reports 473 stars, `archived: false`, a 2026-08-25 push, and 3 open
issues. [repo](https://api.github.com/repos/rustyhorde/vergen); [issues](https://api.github.com/search/issues?q=repo:rustyhorde/vergen+is:issue+is:open).
Maintenance state: **active**.

##### Principles and implementation

Build metadata must be generated once per artifact, be available to `--version`,
and not require a runtime probe of the installed Rust toolchain. Vergen emits
`cargo:rustc-env` instructions for selected `cargo` and `rustc` fields, which
the binary reads with `env!`/`option_env!`; the documented keys include target
triple and rustc semver. [Vergen docs](https://docs.rs/vergen/latest/vergen/); [key list](https://docs.rs/vergen-lib/latest/vergen_lib/enum.VergenKey.html).

##### Dominant choice

Use `vergen = { version = "10.0.3", features = ["cargo", "rustc"] }` under
`[build-dependencies]`.  Its default feature set is empty, and the two enabled
features avoid timestamp, system-information, and Git metadata that this item
does not require. It has no async-runtime coupling. [features endpoint](https://crates.io/api/v1/crates/vergen/versions).

##### Qualified shortlist

`built` 0.8.1 is a qualified alternative: 17,163,161 90-day and 59,880,222
all-time downloads; release 2026-05-21; declared MSRV 1.87; MIT license; 198
stars; unarchived repository last pushed 2026-06-07. Its GitHub open-issue
search endpoint did not return a numeric `total_count` during retrieval.
[crate](https://crates.io/api/v1/crates/built); [versions](https://crates.io/api/v1/crates/built/versions); [repo](https://api.github.com/repos/lukaslueg/built); [issues](https://api.github.com/search/issues?q=repo:lukaslueg/built+is:issue+is:open).
It can generate a Rust source file with build information, but Vergen directly
models the target/rustc environment fields needed here.

##### Excluded by gate

No metadata crate is excluded for license.  `vergen` 10.0.3 is admitted exactly
at the 1.96 policy floor; if the current floor changes downward or a transitive
dependency exceeds it, it must be excluded rather than forced. The lightweight
custom `build.rs` alternative has no crate figures; it is not selected because
it would own tool invocation, parsing, and reproducibility semantics locally.

##### Up-and-comers

`vergen-gitcl` and other Vergen Git-provider adapters are out of scope: a Git
SHA/dirty state was not requested, and adding it would create a source-checkout
availability policy. Vergen's opt-in feature design permits the narrower
`cargo` plus `rustc` selection. [Vergen features](https://docs.rs/vergen/latest/vergen/).

##### Fit for this template

License gate: pass, `MIT OR Apache-2.0`. MSRV gate: 1.96 exactly matches the
stable-minus-two floor calculated from locally verified Rust 1.98.0; it requires
a locked 1.96 CI build to prove the complete tree. Security gate: unverified;
the requested RustSec page returned HTTP 404 and no lockfile exists. Unsafe
posture: unverified transitively; Vergen does not require application unsafe.
OS gate: planned `build.rs` compilation on Ubuntu and macOS. Default features:
empty; enabled features: `cargo`, `rustc`; async runtime: none. Cost: build-time
only dependency, so it adds build-script/dependency resolution work but no
runtime parser or web-service request cost. [versions endpoint](https://crates.io/api/v1/crates/vergen/versions); [Vergen design](https://docs.rs/vergen/latest/vergen/).

##### Recommendation

Select 10.0.3 with only `cargo` and `rustc`. `build.rs` should emit target
triple and rustc semver, while R22 remains the authority for the package-version
source. Build a static long-version string for Clap from those values; do not
read a compiler or OS dynamically when `--version` runs.

##### Ranked runner-up

`built` 0.8.1 ranks second: it has a comfortably lower declared MSRV and a
smaller focused surface, but its generated-file pattern is an extra local
module for fields Vergen exposes directly as Cargo environment values. [built docs](https://docs.rs/built/latest/built/).

##### Tradeoffs

Vergen adds a build script and makes build metadata provenance explicit.  The
cost is more build configuration and a declared-floor edge: version 10.0.3
requires 1.96.  A local script avoids the dependency but makes the template
maintain rustc parsing and failure behavior. No throughput comparison is
applicable; this member is evaluated on build work, not runtime throughput.

##### Parameters

Assumes `R22 runtime-version-accessor` supplies the package version. No R60
parameter is owned. No conflict: Vergen's 1.96 declared MSRV fits the current
stable-minus-two floor, but the proposed MSRV CI check is mandatory.

##### Migration implications

Add `build.rs`, the Vergen build dependency, and `src/build_info.rs` (or an
equivalent private module).  Set Clap's `long_version` from the static build
information. Do not expose Vergen types from the library or web-service.

##### Validation strategy

Planned checks compile the binary with the declared MSRV and run `plbp
--version` on Ubuntu and macOS. Expected output includes the R22 package
version, `VERGEN_CARGO_TARGET_TRIPLE`, and `VERGEN_RUSTC_SEMVER`; `-V` remains
the short form. Use an environment-controlled Vergen fixture only if a
reproducible build test requires deterministic metadata. No build script ran in
this report because no Rust package exists yet.

##### Confidence & re-verify trigger

Medium-high. Re-verify at each Vergen major/minor upgrade, if the policy floor
changes, when R22 chooses its accessor, or when reproducible-build policy
rejects the selected Vergen output.

##### Sources

Primary sources: [registry](https://crates.io/api/v1/crates/vergen),
[versions](https://crates.io/api/v1/crates/vergen/versions), [repository](https://api.github.com/repos/rustyhorde/vergen), [open-issue search](https://api.github.com/search/issues?q=repo:rustyhorde/vergen+is:issue+is:open), [documentation](https://docs.rs/vergen/latest/vergen/), retrieved 2026-09-05.

### Compatibility

The maintained Typstyle project is the shared reference implementation for the
composition: its manifest uses `clap` with `derive`/`env`, `clap_complete`, and
Vergen's `build`, `cargo`, and `rustc` features. It demonstrates the three
members coexist in a production CLI, though it uses Vergen 9.1 rather than this
report's 10.0.3 recommendation. [Typstyle manifest](https://github.com/typstyle-rs/typstyle/blob/master/Cargo.toml), retrieved 2026-09-05.

The recommended version matrix is `clap` 4.6.6 (MSRV 1.85),
`clap_complete` 4.6.9 (MSRV 1.85), and Vergen 10.0.3 (MSRV 1.96).  The maximum
declared member MSRV is 1.96, matching the current stable-minus-two floor based
on local Rust 1.98.0.  This is compatibility evidence, not a completed
resolution: a clean locked build on Rust 1.96 and both target operating systems
is still required. [clap versions](https://crates.io/api/v1/crates/clap/versions); [clap_complete versions](https://crates.io/api/v1/crates/clap_complete/versions); [vergen versions](https://crates.io/api/v1/crates/vergen/versions).

### Parameters

owns: none.

assumes `rust-edition = 2024`.

assumes `msrv-policy = stable minus 2 minor versions, declared as rust-version
in Cargo.toml and tested in CI`.

assumes `license = MIT OR Apache-2.0`.

assumes `target-os-matrix = ubuntu-latest, macos-latest`.

assumes `R22 runtime-version-accessor` determines the package-version value
printed in `--version`; R60 determines only how extended CLI output obtains and
formats the additional build fields.

No `CONFLICT:` line: all selected crate licenses and declared MSRVs fit the
current fixed parameters, subject to the locked-graph verification stated
above.

### Migration implications

The implementation plan should add, in the binary package only: `Cargo.toml`
dependencies and build-dependency; `build.rs`; `src/build_info.rs`;
`src/cli/mod.rs`; `src/cli/global.rs`; `src/cli/projects.rs`;
`src/cli/config.rs`; `src/cli/completion.rs`; and black-box fixtures under
`tests/cli/`.  `src/main.rs` becomes the thin parser-to-library adapter.

`GlobalArgs` declares every approved global option once with both
`global = true` and an explicit `env = "PLBP_..."` name. A table-driven test
must compare that allowlist with the global fields, so a new field cannot acquire
or lose environment configuration accidentally. `ProjectsCommand` and
`ConfigCommand` become nested `Subcommand` enums; there is no root default
command. The completion arm calls a fresh command factory. The build-info module
is private and consumes the R22 version value plus the two Vergen outputs.

### Validation strategy

These are **planned acceptance checks, not executed results**; the current
repository contains no Rust package.

```sh
# From the future Rust template root: resolve and build at the policy floor.
cargo +1.96.0 check --workspace --all-targets --locked

# From the future Rust template root: exercise both positions of root global args.
cargo run --bin plbp -- projects list --json
cargo run --bin plbp -- --json projects list

# From the future Rust template root: prove explicit environment mapping.
PLBP_JSON=true cargo run --bin plbp -- projects list

# From the future Rust template root: prove discovery and non-acceptance of prefixes.
cargo run --bin plbp -- project; test $? -ne 0

# From the future Rust template root: prove short/extended versions and all required scripts.
cargo run --bin plbp -- -V
cargo run --bin plbp -- --version
cargo run --bin plbp -- completion bash > /tmp/plbp.bash
cargo run --bin plbp -- completion zsh > /tmp/_plbp
cargo run --bin plbp -- completion fish > /tmp/plbp.fish
```

Expected observations: the two `--json` placements produce the same typed
global value; the environment invocation does too only for a listed global;
`project` fails and includes a suggestion for `projects`; `-V` is short while
`--version` contains package version, target triple, and rustc version; each
completion output includes `projects`, `config`, global flags, and its verbs.
Run the same test suite on `ubuntu-latest` and `macos-latest`, then run
`cargo audit` on the generated lockfile.  Measure release binary bytes and
clean/cached build durations with the exact command line and machine recorded;
compare to a committed no-parser micro-baseline only if binary cost becomes a
decision concern.

### Confidence & re-verify trigger

**Decision confidence: high** for Clap's architectural fit and command-tree
pattern; **medium** for final security/MSRV/OS evidence because no template
lockfile or CI run exists yet.  The evidence does not support a throughput or
absolute binary-size winner claim.

Re-run the selection gate when any of these occurs: Clap, clap_complete, or
Vergen ships a major/minor upgrade; Cargo's stable-minus-two floor changes;
RustSec reports an advisory; a locked Rust-1.96 build fails; an Ubuntu/macOS
fixture fails; R22 selects a version accessor that cannot produce a static
Clap long-version string; or the future measured binary-size budget rejects the
full parser cost.

### Sources

All sources were retrieved 2026-09-05. Primary technical guidance: [Rust CLI
Book parser chapter](https://rust-cli.github.io/book/tutorial/cli-args.html),
[Cargo MSRV reference](https://doc.rust-lang.org/cargo/reference/rust-version.html),
[Clap documentation](https://docs.rs/clap/latest/clap/), [Clap derive
reference](https://docs.rs/clap/latest/clap/_derive/), [clap_complete AOT
documentation](https://docs.rs/clap_complete/latest/clap_complete/aot/), and
[Vergen documentation](https://docs.rs/vergen/latest/vergen/).

Figures: [clap crate](https://crates.io/api/v1/crates/clap), [clap
versions](https://crates.io/api/v1/crates/clap/versions), [clap_complete
crate](https://crates.io/api/v1/crates/clap_complete), [clap_complete
versions](https://crates.io/api/v1/crates/clap_complete/versions), [vergen
crate](https://crates.io/api/v1/crates/vergen), [vergen
versions](https://crates.io/api/v1/crates/vergen/versions), [Clap GitHub
repository](https://api.github.com/repos/clap-rs/clap), [Vergen GitHub
repository](https://api.github.com/repos/rustyhorde/vergen), and the linked
GitHub issue-search endpoints in each member section.

Method notes: queried the required crates.io crate and versions endpoints and
GitHub repository/open-issue-search endpoints directly. The RustSec package
URLs specified by the prompt returned HTTP 404 for each surveyed crate, so this
report does **not** claim a final no-advisory result; audit the future locked
graph. GitHub's public issue list does not expose a stable maintainer-roster
field, so median first-maintainer-response and unanswered counts were not
invented; recent issue lists were inspected only as maintenance context. No
Rust code or empirical CLI acceptance command was run because the repository is
still research-only.
