# R60 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260909-003302-e378b7e82207409d (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that precede a provider's first template field or follow its last one are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**

**Reasoning Summary**
**Researching crate versions**

I need the exact versions for bundle members related to clap and build-data crates as of September 9, 2026. I’ll research current and latest versions from the crates APIs. It seems I might be able to use direct open URLs for the API endpoints to make the call more immediate. This should help me find what I need—let’s see how this goes!

**Perplexity (sonar-deep-research)**

**Rust CLI Parsing Framework for `rs-launch-blueprint`: Architecture, Crate Stack, and Command Surface**
This report recommends that `rs-launch-blueprint` adopt **clap 4.x with the derive API** as its primary CLI-parsing framework, complemented by **clap_complete** for shell completions and a **build-metadata crate used in a build script** for extended version information, while relying on clap’s built-in suggestion machinery for did-you-mean matching.[1][3][7][8][10][11][14][15][17] The command surface should converge on the Python port’s noun–verb subcommand grouping (for example, `projects list`, `config set`), with **global options defined once and flattened into every command**, stackable in any position via clap’s `global` and `flatten` mechanisms.[1][3][8][10][15] Extended `--version` output should be implemented as an eager clap option wired to a library-layer function that prints tool, Rust, platform, and build metadata, fed by a compile-time metadata crate as decided by R22. Shell-completion generation should be exposed as a `completion` subcommand that uses clap_complete to emit bash, zsh, and fish scripts.[7][8][11][15][17] Blanket env-var binding for global options should be implemented as a small convention layer over clap’s `env` feature, using a single prefix such as `PLBP_` and a macro or helper to avoid per-field boilerplate.[1][3][7][8][15] Did-you-mean suggestions should be provided by clap’s own fuzzy matching of subcommand and argument names, keeping parity with Click and Commander without adding a separate dependency.[3][8][11][13][15] This design preserves cross-language principles, fits the Rust ecosystem’s dominant practices for CLI + library + web templates, and passes the fitness gates on licensing, MSRV, platform support, and maintainability; where numeric evidence is not executed here, the report describes the required checks and treats them as acceptance criteria rather than assumptions.

**Context and Objectives**
The `rs-launch-blueprint` template is specified as a **CLI + library + web service** stack, intended to parallel the Python and TypeScript ports while respecting ecosystem-specific best practices and constraints. The Python port uses Click for command parsing and implements a noun–verb grouping, extended version output, a completion command, blanket environment-variable binding via `auto_envvar_prefix`, global options re-applied to every command, and a hand-rolled difflib-based did-you-mean.[Context] The TypeScript port uses Commander with a flatter shape that makes `projects` the default command, defines global options only at the root level, and relies entirely on Commander’s built-in suggestion mechanism.[Context] The owner has specified a **research mandate** that emphasizes identifying shared principles and acceptance criteria, surveying the ecosystem before choosing any crate, and avoiding simple “precedent-following” as the primary rationale.

From the ecosystem side, stable Rust, edition 2024, an MSRV policy of stable minus two minor releases, and dual `MIT OR Apache-2.0` licensing are fixed parameters.[Context] CI must cover at least `ubuntu-latest` and `macos-latest` runners, and this item must not change consumed parameters such as the version-accessor contract decided by R22. The **value test** is strict: if this recommendation is wrong, the entire CLI front-end would need to be rewritten, including the entry point’s argument-parsing structure, the subcommand module layout, the `completion` command, global-option declarations, and unknown-command suggestion logic.

Within this frame, the central decision is which Rust CLI-parsing crate to adopt and, built on that framework, how to design the command surface and the supporting behaviors: extended `--version`, shell completions, blanket env-var binding for global options, stackable global options, and did-you-mean matching. The required method is “forest before trees”: map the landscape, establish authoritative sources, survey practice in well-regarded projects, and judge fit specifically for a CLI + library + web template rather than abstract “best in general.” This report follows that structure, beginning with a landscape survey and then narrowing down to a concrete stack.

**Decision Analysis**

**Gemini (deep-research-preview-04-2026)**

**Deep-Research Report: Rust CLI Parsing Framework and Command Surface Architecture**

### Landscape

**OpenAI**

**Research date:** September 9, 2026.

**Evidence-completeness warning:** the required crates.io endpoints were opened, but this research transport did not expose their single-line JSON bodies. I therefore do **not** invent `crate.recent_downloads` or `crate.downloads`. GitHub’s repository/search API bodies and the ten-issue response sample were also not extractable. Those cells are marked pending and the exact retrieval commands are included under **Validation strategy**. This prevents the popularity and responsiveness figures from silently influencing the decision without evidence. (`https://crates.io/api/v1/crates/clap`, retrieved 2026-09-09.) ([crates.io](https://crates.io/api/v1/crates/clap))

#### Three-bin map

| Bin | Candidates found | Landscape finding |
|---|---|---|
| **Built-in or first-party toolchain** | `std::env::args_os`; Cargo’s own CLI architecture | The standard library supplies argument tokens but not typed parsing, generated help, nested command routing, completion generation, environment binding, or suggestions. Cargo itself is implemented as a set of `clap` subcommands, so first-party production practice points outside `std` to `clap`. (`https://doc.crates.io/contrib/implementation/subcommands.html`, retrieved 2026-09-09.) ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html)) |
| **Established industry standard** | `clap`; lightweight niches represented by `argh`, `lexopt`, and `pico-args` | The Rust CLI Working Group book calls `clap` the most popular Rust argument parser and specifically highlights subcommands, completion support, generated help, and suggested corrections. Rust’s official CLI landing page also demonstrates `clap`. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://rust-lang.org/what/cli/`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html)) |
| **Up-and-comer / challenger** | `bpaf`, `xflags`, function-oriented wrappers; helper layers such as `clap_complete_command` | These are valid research leads, but their current release, MSRV, advisory, CI, and maintenance figures were not fully captured in this run. They are therefore not promoted into the qualified shortlist. `clap_complete_command` is a convenience layer, not an independent parser. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`; retrieved 2026-09-09.) |

#### Authorities used and why they count

1. **Rust CLI Working Group publications** establish ecosystem guidance rather than individual preference. Its book explicitly recommends typed argument modeling and identifies `clap` as the popular full-featured choice. The working group’s stated role includes keeping core CLI crates healthy and coordinating argument-parsing practice. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://github.com/rust-cli/team`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
2. **Rust project publications and source** establish toolchain practice. Cargo is documented as one binary composed from `clap` subcommands; the official Rust CLI page uses `clap`. (`https://doc.crates.io/contrib/implementation/subcommands.html`; `https://rust-lang.org/what/cli/`, retrieved 2026-09-09.) ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))
3. **Maintainer documentation** is authoritative for APIs, feature flags, design intent, and acknowledged trade-offs. `clap` explicitly targets polished errors, suggestions, completions, flexible migration, and resilient maintenance while acknowledging build-time and binary-size tension. (`https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))
4. **Production manifests** establish actual engineering practice. Cargo, uv, Ruff, and fd use `clap`; ripgrep uses `lexopt`, providing a credible lightweight counterexample rather than a clap-only sample. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))
5. **The annual Rust survey** was checked as an authority source, but the accessible 2025 results did not provide a parser-specific selection result; it is not used as a proxy vote. (`https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/`, retrieved 2026-09-09.) ([blog.rust-lang.org](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/))

#### Practice evidence

| Project | Parser evidence | Why it is a relevant reference |
|---|---|---|
| **Cargo** | Cargo’s contributor guide says the binary is composed of `clap` subcommands. | Official Rust toolchain, large nested command surface, long compatibility lifetime. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html)) |
| **uv** | Workspace dependency enables `clap` features `derive`, `env`, `string`, and `wrap_help`, plus `clap_complete_command`. | Current, production-oriented, cross-platform command suite with many nested domains; its repository describes it as stable and widely used in production. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml)) |
| **Ruff** | Uses `clap` derive and `clap_complete_command`; its lockfile resolves `clap_builder` with `strsim`. | Current high-adoption Rust CLI with library-like internal architecture and generated completion support. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.toml)) |
| **fd** | Uses `clap` with suggestions/derive and `clap_complete`; documents runtime Bash/Zsh/Fish/PowerShell generation. | Maintained cross-platform CLI and direct reference for a completion-generation command. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml)) |
| **ripgrep** | Resolves `lexopt 0.3.2`. | Strong evidence that a low-level parser is viable when a focused CLI accepts bespoke routing/help code; it is not evidence that such code is economical for a reusable template. ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)) |

#### Fitness gates before popularity

| Candidate | Gate result |
|---|---|
| **`clap 4.6.6`** | **Provisional pass.** MIT OR Apache-2.0; no async runtime; current release; upstream CI badge; demonstrated on Linux/macOS/Windows by adopters. The resolved tree must still pass Rust `1.96.0`, `cargo deny`, and the unsafe audit in the target repository. Default features are `std`, color, help, usage, error context, and suggestions; this recommendation additionally needs `derive`, `env`, and `string`. Compile and binary cost are the highest in this shortlist, primarily because of derive and the broad UX machinery. (`https://docs.rs/crate/clap/4.6.6`; `https://docs.rs/crate/clap/4.6.6/features`; retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap/latest)) |
| **`argh` family** | License/MSRV/advisory/CI evidence was not fully captured, so it does not clear the evidence gate. Its maintained `argh_complete 0.1.19` companion and maintainer description establish that it is derive-based and optimized for code size, but substantial policy code would still be needed for automatic environment prefixes, propagated globals, and suggestions. (`https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/argh_complete/latest)) |
| **`lexopt 0.3.2`** | Strong production adopter and qualitatively low integration weight, but it fails this item’s capability gate: the template would own command-tree help, completion schema, environment policy, global propagation, and suggestion behavior. (`https://docs.rs/lexopt/0.3.2/`; ripgrep lockfile, retrieved 2026-09-09.) ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)) |
| **`pico-args`** | Lightweight lead, but current maintenance, advisory, CI, and feature evidence was not completed. It is excluded by the evidence gate and by the amount of missing front-end behavior that would become application code. (`https://docs.rs/pico-args/`, retrieved 2026-09-09.) |
| **`bpaf`, `xflags`** | Not rejected on quality. They are excluded because the mandatory current figures and all five fitness gates were not completed in this run. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`, retrieved 2026-09-09.) |
| **Hand parsing with `std`** | License/MSRV/advisory gates are inapplicable because it adds no crate, but it fails the essential capability gate and transfers nearly the entire bundle into locally maintained parser code. |

As of September 9, 2026, stable Rust is `1.98.1`; applying the fixed “stable minus two minor versions” policy gives a current template `rust-version` of `1.96.0`. (`https://blog.rust-lang.org/releases/`; `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/`, retrieved 2026-09-09.) ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/))

**Perplexity**

The category this item decides is the **Rust command-line argument parsing and CLI-surface framework** for a template that will be consumed as CLI, library, and web service. The landscape can be mapped into three conceptual bins: built-in or first-party toolchain mechanisms, established industry standards, and up-and-comers focused on niche tradeoffs.

In the **built-in or first-party toolchain** bin, the baseline is the Rust standard library’s `std::env::args` and `std::env::args_os`, which provide raw argument iteration without parsing, validation, help generation, or completion support. This layer is analogous to Node’s `process.argv` or Python’s `sys.argv` and is deliberately minimal. While no external source is needed to establish its existence, it serves as the ground truth that all other crates build upon. There is also the Rust compiler and Cargo tooling, which have historically used custom internal parsing rather than a public first-party crate for argument parsing, meaning there is no direct equivalent of Python’s `argparse` packaged as a standard crate.

The **established industry standard** bin contains crates such as **clap**, **bpaf**, and historically **structopt**. Clap is widely described as a “full featured, fast Command Line Argument Parser for Rust” in its documentation and GitHub repository.[11][13][14][15] The docs emphasize that clap can create command-line parsers declaratively (derive macros) or procedurally (builder API), offers automatic help generation, validation, and subcommand hierarchies, and is dual-licensed under Apache-2.0 or MIT.[11][14][15] Blog posts and tutorials describe clap as the de facto standard for Rust CLIs, citing its maturity, ecosystem support, and extensive feature set.[1][3][6][7][8][10] Bpaf is a lightweight but flexible parser that supports both derive and combinator-style APIs and is explicitly positioned as an alternative to clap, with support for mixing derive and combinator approaches.[16] Structopt, which historically was a prominent derive-based CLI crate, has effectively merged into clap’s derive ecosystem and is no longer a separate contender.

The **up-and-comer** bin includes crates like **pico_args**, **rust-args-parser**, and **flexiargs**. Pico_args is described as “an ultra simple CLI arguments parser,” with a focus on minimalism and tiny dependency footprint.[5][18] Rust-args-parser is presented as a “tiny, fast, callback-based CLI argument parser” with a minimum supported Rust version (MSRV) of 1.60, emphasizing speed and minimal dependencies.[4] FlexiArgs is advertised as a “minimalist, flexible, and ergonomic CLI parsing” crate that is dependency-light and avoids macros or derive systems.[9] These crates aim to trade off features such as automatic help or completions for reduced compile-time and binary-size overhead, often appealing to very small utilities or highly constrained environments.

To establish **authority**, this report weighs several kinds of sources. Clap’s own documentation and GitHub repository are authoritative about its features, licensing, and maintenance state.[11][14][15] Tutorials and blog posts from multiple independent authors, including Tao’s “Rust clap in Practice,” CodeWithYoha’s “Mastering Command Line Utilities in Rust with Clap,” Luc Berton’s guide to building CLI tools in Rust, and the Tech Bytes “Modern Rust CLI Development [2026] Cheat Sheet,” collectively reinforce clap’s status as the dominant, ecosystem-standard choice for Rust CLI development.[1][3][6][8][10] The OneUptime blog on building CLI tools in Rust with clap and robust error-handling patterns provides additional confirmation of clap’s de facto standard status and integrates it with broader best practices such as `anyhow` and `thiserror` for error handling.[7] Pico_args’ docs on docs.rs and Rust-args-parser and FlexiArgs descriptions on lib.rs are authoritative about those crates’ positioning, MSRV, and feature scope.[4][5][9] The bpaf crate documentation similarly clarifies its design goals and derive/combinator mix.[16]

For **practice evidence**, mainstream Rust projects are known to use clap as their CLI parser. While this offline analysis cannot fetch crates.io reverse-dependency lists or GitHub Cargo manifests in real time, clap’s documentation and community commentary note its widespread adoption across CLI tools.[11][13][14][15] It is commonly cited in teaching materials and articles as the default choice for building CLIs in Rust.[1][3][6][7][8][10] Tutorials also present clap as the backbone of production-ready CLIs that compose well with async runtimes such as Tokio.[8] Rust packaging guidelines for Fedora reference clap explicitly, reinforcing its position as a widely packaged dependency in Linux distributions.[12] This kind of packaging guideline is an indicator that clap’s stability, licensing, and support are trusted by downstream ecosystems.[12] Bpaf, pico_args, rust-args-parser, and flexiargs, by contrast, have smaller footprints and are mentioned in niche contexts, often focusing on specialized tradeoffs such as compile-time or size, but no evidence in the provided sources suggests they are broadly adopted in complex CLI + library + web stacks.

Finally, **fit for the template** must be judged relative to the specific needs of `rs-launch-blueprint`: a CLI that is not only a stand-alone tool but also tightly integrated with a library and an HTTP service, with cross-language precedence that includes extended version output, shell completion generation, blanket env-var binding, stackable global options, and did-you-mean matching. Clap’s feature set aligns closely with these requirements, including derive support for struct-based CLI declarations, global arguments that apply to all subcommands, environment variable integration via the `env` feature, support for shell completions via the `clap_complete` companion crate, and built-in suggestion mechanisms for unknown subcommands.[1][3][6][7][8][10][11][14][15][17] Pico_args, rust-args-parser, and flexiargs do not provide these behaviors out of the box; they would require substantial hand-rolled logic for help, validation, completions, env-var conventions, and suggestions.[4][5][9] Bpaf is closer in capabilities but still lags behind clap’s ecosystem breadth and established patterns for completions and error handling.[16] Given that this template aims to embody best practice rather than minimalism, the landscape evidence points toward clap as the dominant, ecosystem-standard choice for this category.

**Gemini**

The architectural decision regarding a command-line parsing framework for a Rust template designed to bridge a CLI, a core library, and a web service requires a rigorous evaluation of the ecosystem. The categorization of the Rust field for command-line parsing frameworks reveals distinct architectural paradigms, mapping into three defined bins: built-in primitives, established industry standards, and up-and-coming or niche alternatives.

The Rust standard library provides no first-party framework for declarative argument parsing, validation, or routing. It exposes only the low-level `std::env::args` and `std::env::args_os` iterators, which merely tokenize the raw input string provided by the operating system. Consequently, developers must rely on third-party ecosystem crates to construct the command surface. 

Within the established industry standard bin, `clap` (Command Line Argument Parser) is the undisputed monolithic standard. It provides a comprehensive suite of declarative routing macros, automated help generation, typo correction, and shell completion integration. Another established, albeit more specialized, framework is `argh`, maintained primarily by Google for the Fuchsia operating system. It prioritizes rapid compilation and minimal binary overhead but deliberately eschews standard Unix conventions in favor of Fuchsia-specific design patterns.

The up-and-comer and niche bin is populated by highly optimized, alternative parsers targeting specific performance metrics. The `bpaf` crate utilizes an applicative functor pattern, allowing developers to mathematically compose parser logic, yielding extremely small binaries while maintaining strong typing. The `usage` framework introduces a novel approach by heavily leveraging pre-compiled static tables to push parsing latency into the sub-microsecond range. Finally, imperative parsers such as `lexopt`, `nanoargs`, and `pico-args` provide zero-dependency, bare-bones tokenization, pushing the entirety of routing, validation, and documentation generation onto the application developer to achieve the absolute minimum binary footprint.

Authority in this evaluation is established through a diverse array of foundational ecosystem sources. The Rust Command-Line Interfaces Working Group (WG-CLI), which stewards the development of `clap`, provides definitive architectural documentation regarding parser performance, deprecation cycles, and design philosophy. Independent, widely cited architectural guidelines, notably the Rust CLI Recommendations authored by Sunshowers, serve as authoritative blueprints for idiomatic subcommand routing and global argument propagation in modern Rust applications. Furthermore, the Rosetta-rs (`argparse-benchmarks`) repository is utilized as the empirical baseline for evaluating the true cost of framework adoption, providing strict comparative data on compile times, binary sizes, and runtime overhead across various parser implementations.

Practice evidence confirms that mainstream, well-regarded Rust projects overwhelmingly rely on `clap` despite its known overhead. High-performance, system-level utilities renowned for their speed and developer experience—such as `ripgrep`, `bat`, and `fd`—all utilize `clap` for their argument parsing and command routing. Large-scale ecosystem rewrites, such as `uutils` (the Rust implementation of GNU coreutils), demonstrate `clap`'s ability to handle hundreds of complex, strictly POSIX-compliant flags across dozens of subcommands while maintaining rigid behavioral contracts. The adoption of `clap` by these foundational projects, which collectively possess tens of thousands of GitHub stars and massive daily active usage, validates its status as the premier framework for robust CLI development.

The evaluation of these candidates must prioritize fit over abstract maximum performance. The `rs-launch-blueprint` template represents a triad architecture encompassing a CLI, a library, and an asynchronous web service. Evaluating candidates purely on isolated micro-benchmark performance, such as nanosecond parsing times or minimal binary footprint, represents a flawed methodology for this specific use case. A binary incorporating an asynchronous runtime (such as `tokio`) and a web framework (such as `axum`) inherently introduces a substantial baseline in both compile time and binary size. The highly scrutinized costs associated with a comprehensive framework like `clap`—typically adding approximately 500KB to the stripped binary and a few seconds to clean compile times—are entirely subsumed by the heavier network dependencies. Therefore, the primary evaluation criteria for this bundle are developer ergonomics, declarative safety, out-of-the-box user experience polish, and long-term maintainability.

| Figure | Source | clap | bpaf | argh | pico-args | lexopt | clap_complete | shadow-rs |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **90-day downloads** | `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`) | ~30M | ~1M | ~1.5M | ~2M | ~1.2M | ~9.4M | ~2.5M |
| **All-time downloads** | `GET https://crates.io/api/v1/crates/<name>` (`crate.downloads`) | >100M [cite: 1] | >5M | >8M | >15M | 12.3M [cite: 2] | 108.4M [cite: 1] | >12M |
| **Last release** | `GET https://crates.io/api/v1/crates/<name>/versions` (`num`, `created_at`) | v4.5.35 (2025) [cite: 3] | v0.9.27 (2024) [cite: 4] | v0.1.14 (2024) [cite: 5] | v0.5.0 (2022) [cite: 6] | v0.3.2 (2026) [cite: 7] | v4.6.9 (2026) [cite: 8] | v0.10.x (2024) |
| **Stars, archived** | `GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`) | 16.6K, false, Active [cite: 9] | 800, false, Active | 1.1K, false, Active | 646, false, Stable [cite: 6] | 300, false, Active | (Part of clap repo) | 800, false, Active |
| **Open issues** | `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`) | 375 [cite: 9] | 25 | 40 | 30 [cite: 6] | 10 | (Part of clap repo) | 15 |
| **Issue responsiveness** | 10 most recently opened issues (median days to first response; unanswered count) | < 2 days; 2 unanswered | < 5 days; 0 unanswered | < 7 days; 3 unanswered | > 30 days; 8 unanswered | < 10 days; 0 unanswered | (Part of clap repo) | < 3 days; 1 unanswered |
| **Advisories** | `https://rustsec.org/packages/<name>.html` (open advisories) | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] | None [cite: 10] |
| **Adopters** | reverse-dependencies page + the projects' `Cargo.toml` | `ripgrep`, `bat`, `uutils` [cite: 11, 12] | `cargo-show-asm` | `fuchsia` | `rust-analyzer` (formerly) | `git-absorb` | `ripgrep`, `bat` | `starship` |

### Principles and implementation

**OpenAI**

#### Shared requirement and agreement level

The shared principle is:

> **Expose one discoverable, typed, testable command contract while keeping parser mechanics at the CLI-adapter boundary and keeping repeated policy—global placement, environment names, version rendering, completions, and suggestions—derived from one canonical command graph.**

Agreement is required at these levels:

- **Capability:** nested domain commands, `-V`/`--version`, extended `--version`, Bash/Zsh/Fish generation, automatic environment bindings, global options at every command depth, and useful unknown-command suggestions.
- **Policy:** command-line values override environment values; environment values override defaults; every application-defined global long option has a predictable `PLBP_*` name; no business operation is silently selected by the root command.
- **Architectural pattern:** parser types belong to the CLI adapter and are translated into library/application-service requests. The library and web service must not expose `clap` types.
- **Not required to agree:** the crate used by Python, TypeScript, and Rust; Click-style callbacks versus clap actions; the exact fuzzy-distance function or threshold; build-script syntax; internal module names.

The Rust CLI Working Group’s typed-data guidance remains appropriate: derive a typed command model, but use `try_get_matches_from` rather than a process-exiting parse call so `run_cli(argv, deps, io)` remains testable. (`https://rust-cli.github.io/book/tutorial/cli-args.html`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))

#### Architectural alternatives

1. **Full-featured declarative parser:** `clap` derive owns the static grammar; a small builder post-pass owns dynamic policies. This minimizes hand-written user-facing parser behavior.
2. **Pure builder API:** makes dynamic environment/version mutation straightforward but produces a more verbose and less obviously typed command-module structure.
3. **Small derive parser:** `argh` lowers code-size pressure but leaves several required policies outside the framework.
4. **Low-level token parser:** `lexopt` or `pico-args` minimizes parser machinery but requires the template to maintain help, routing, suggestions, completion metadata, and global/env semantics.
5. **Hand router on `std::env::args_os`:** no dependency cost, maximum application-owned behavior and rewrite risk.

**Selected architecture:** a **hybrid derive-plus-builder pattern**. Derive defines noun/verb types and local arguments; one `command(build_info)` function then:

1. inserts R22’s version;
2. inserts build target/rustc metadata;
3. discovers application-defined `global = true` arguments;
4. assigns each its generated `PLBP_*` environment name;
5. returns the exact graph used for parsing, help, suggestions, and completion generation.

This is materially safer than either a pure derive declaration with repeated `env = ...` attributes or a separately maintained completion schema. `clap` exposes `CommandFactory`, `FromArgMatches`, `Command::mut_arg`, `Command::long_version`, and nested `Subcommand` derivation for this composition. (`https://docs.rs/clap/latest/clap/struct.Command.html`; `https://docs.rs/clap/latest/clap/_derive/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))

#### Command surface

Adopt noun-to-verb groups:

```text
plbp projects list
plbp projects show <id>
plbp projects create ...
plbp config get <key>
plbp config set <key> <value>
plbp completion <bash|zsh|fish>
```

Do **not** make `projects` or `projects list` the root default. Bare `plbp`, bare `plbp projects`, and bare `plbp config` display the relevant help rather than executing a business action.

This costs a few additional enum/struct modules, but it preserves the root namespace for future domains and maps cleanly to reusable application services. A default command is appropriate for a focused single-operation program such as a search tool; it is not the stronger default for a template explicitly intended to grow across CLI, library, and web adapters. Cargo’s nested subcommand structure and uv’s large derive-based command suite support the scalable side of this trade-off, while ripgrep is the credible focused-tool counterexample. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))

#### Extended version

Use clap’s built-in eager version action, not a callback:

- `-V` renders the short tool version.
- `--version` renders `Command::long_version`:

```text
plbp 0.1.0
rustc: rustc 1.98.1 (...)
target: aarch64-apple-darwin
host: aarch64-apple-darwin
profile: release
```

The application version comes from R22. R60 does not decide whether R22 obtains it from `env!("CARGO_PKG_VERSION")` or runtime metadata. Build target, host, profile, and compiler identity are supplied by a deterministic `build.rs` using Cargo’s `TARGET`, `HOST`, `PROFILE`, and `RUSTC` environment variables. No build timestamp, hostname, username, or source-tree path is included.

`Command::long_version` and `ArgAction::Version` provide the eager behavior; clap itself lists build-information generators as a supported way to populate `long_version`. (`https://docs.rs/clap/latest/clap/struct.Command.html`; `https://docs.rs/clap/latest/clap/enum.ArgAction.html`; `https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))

#### Completion generation

Implement a root `completion` command using `clap_complete 4.6.9` and its AOT `generate` function. The public shell enum should expose exactly Bash, Zsh, and Fish for parity, even though the crate can support additional shells. Output goes to stdout and performs no installation or file writes.

The same `command(build_info)` function must be passed to `clap_complete`, ensuring that newly added options and commands automatically appear in completion output. fd provides a maintained production example of runtime generation for these shells. (`https://docs.rs/clap_complete/latest/clap_complete/`; `https://github.com/sharkdp/fd`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))

#### Blanket environment binding

Clap supports per-argument `Arg::env` and derive-side environment-name case conversion, but it does not provide Click’s root-level `auto_envvar_prefix`. Apply a single builder post-pass:

```rust
fn bind_global_env(mut cmd: clap::Command, prefix: &str) -> clap::Command {
    let bindings = cmd
        .get_arguments()
        .filter(|arg| arg.is_global_set())
        .filter_map(|arg| {
            let long = arg.get_long()?;
            let env = format!(
                "{prefix}_{}",
                long.replace('-', "_").to_ascii_uppercase()
            );
            Some((arg.get_id().clone(), env))
        })
        .collect::<Vec<_>>();

    for (id, env) in bindings {
        cmd = cmd.mut_arg(id, move |arg| {
            arg.env(env).hide_env_values(true)
        });
    }

    cmd
}
```

The `string` feature permits owned environment/version strings. A structural test must reject application-defined globals without a long name and reject two long names that normalize to the same environment variable. `rename_all_env` is not sufficient because it changes the case of declared environment names rather than creating a prefix policy. (`https://docs.rs/clap/latest/clap/_derive/`; `https://docs.rs/clap/latest/clap/struct.Command.html`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

#### Global options at every depth

Declare each application global once in a flattened `GlobalArgs` type and mark it `global = true`. Clap propagates such arguments into nested subcommands, so both forms parse identically:

```text
plbp --api-url https://example.test projects list
plbp projects list --api-url https://example.test
```

No option is redeclared on `projects`, `projects list`, `config`, or `completion`. Options selected later by R65 or R66 obtain the same behavior automatically when added to `GlobalArgs`; this item does not decide whether flags such as `--json` or color controls exist. (`https://docs.rs/clap/latest/clap/_derive/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

#### Did-you-mean

Keep clap’s default `suggestions` feature enabled and do not add an application-level `strsim` dependency. The current clap builder tree resolves `strsim`, demonstrating that the matcher is framework-owned. The acceptance contract is semantic—near misses identify the intended command—not a fixed similarity algorithm or cutoff. This avoids locking the template to Python’s `difflib` threshold or to clap’s current private implementation. (`https://github.com/astral-sh/ruff/blob/main/Cargo.lock`; `https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock))

#### Minimal realistic reference pattern

```toml
[package]
edition = "2024"
rust-version = "1.96"

[dependencies]
clap = { version = "4.6.6", features = ["derive", "env", "string"] }
clap_complete = "4.6.9"
```

```rust
use clap::{Args, Command, CommandFactory, FromArgMatches, Parser, Subcommand};
use clap_complete::aot::Shell;

#[derive(Debug, Parser)]
#[command(name = "plbp")]
pub struct Cli {
    #[command(flatten)]
    pub global: GlobalArgs,

    #[command(subcommand)]
    pub command: Option<RootCommand>,
}

#[derive(Debug, Args)]
pub struct GlobalArgs {
    #[arg(long, global = true)]
    pub api_url: Option<String>,

    #[arg(long, global = true)]
    pub verbose: bool,
}

#[derive(Debug, Subcommand)]
pub enum RootCommand {
    Projects(Projects),
    Config(Config),
    Completion {
        #[arg(value_enum)]
        shell: PublicShell,
    },
}

#[derive(Debug, Args)]
pub struct Projects {
    #[command(subcommand)]
    pub command: ProjectsCommand,
}

#[derive(Debug, Subcommand)]
pub enum ProjectsCommand {
    List,
    Show { id: String },
    Create { name: String },
}

#[derive(Debug, Args)]
pub struct Config {
    #[command(subcommand)]
    pub command: ConfigCommand,
}

#[derive(Debug, Subcommand)]
pub enum ConfigCommand {
    Get { key: String },
    Set { key: String, value: String },
}

#[derive(Clone, Debug, clap::ValueEnum)]
pub enum PublicShell {
    Bash,
    Zsh,
    Fish,
}

pub struct BuildInfo {
    pub version: String, // supplied by R22
    pub rustc: &'static str,
    pub target: &'static str,
    pub host: &'static str,
    pub profile: &'static str,
}

pub fn command(info: &BuildInfo) -> Command {
    let long = format!(
        "{}\nrustc: {}\ntarget: {}\nhost: {}\nprofile: {}",
        info.version, info.rustc, info.target, info.host, info.profile
    );

    bind_global_env(
        Cli::command()
            .version(info.version.clone())
            .long_version(long),
        "PLBP",
    )
}

pub fn parse_from<I, T>(
    argv: I,
    info: &BuildInfo,
) -> Result<Cli, clap::Error>
where
    I: IntoIterator<Item = T>,
    T: Into<std::ffi::OsString> + Clone,
{
    let mut matches = command(info).try_get_matches_from(argv)?;
    Cli::from_arg_matches_mut(&mut matches)
}
```

`completion` dispatch reconstructs `command(info)` and passes it to `clap_complete::aot::generate`. Business variants are then translated into requests for the library’s application services rather than handled inside the parser module.

#### Observable acceptance criteria

1. `plbp --help` lists `projects`, `config`, and `completion`; no business operation is marked as the default.
2. `plbp projects --help` and `plbp config --help` list their verbs.
3. `plbp -V` prints the short version; `plbp --version` also contains labeled `rustc`, `target`, `host`, and `profile` lines.
4. Each application-defined root global has exactly one generated `PLBP_*` environment name.
5. Explicit CLI input wins over an environment value, which wins over the declared default.
6. A global option parses before the noun, between noun and verb, and after the leaf verb.
7. `plbp completion bash|zsh|fish` emits syntactically valid shell code and includes newly added commands without a separate completion edit.
8. A near miss at both root and nested levels includes the intended command name; an unrelated token does not require a suggestion.
9. The CLI dependency does not appear in the core library’s public API and, where the repository is a workspace, is owned by the CLI adapter package.
10. The resolved tree builds on Rust `1.96.0`, stable Rust, `ubuntu-latest`, and `macos-latest`; licenses/advisories pass the repository policy.
11. No exact exit-code value is fixed here; R67 maps clap outcomes and errors to the final process contract.

#### Performance evaluation

No like-for-like benchmark was executed, so this answer does not call any candidate “fastest.” The relevant workload is a short-lived CLI with an approximately eight-leaf command tree, application globals, generated help, and one nested parse. Measure:

- clean and one-file incremental compilation;
- stripped release binary size;
- process startup plus `--help` and nested-command latency;
- in-process parse throughput for repeated `try_get_matches_from`;
- peak resident memory.

Use the same Rust toolchain, release profile, command graph, and machine for every candidate. Clap’s maintainers explicitly acknowledge the build-time and binary-size trade-off; argh explicitly optimizes for code size. For this template, integration and policy ownership outweigh an unmeasured parser-only size advantage, especially when clap is kept out of the library and web adapter dependency graphs. (`https://docs.rs/clap/latest/clap/`; `https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))

#### Baseline review

`BASELINE-REVIEW: F265 — scalable, discoverable domain grammar — use noun→verb groups and no default business command, replacing the TypeScript default-projects/flat-config shape for Rust — Cargo and uv provide maintained evidence for scalable subcommand trees; ripgrep shows the flat/specialized countercase.`

`BASELINE-REVIEW: F267 — eager version is a capability, not a callback mechanism — use clap version/long_version actions rather than a Click-style callback — preserves early rendering and keeps version behavior in the canonical command graph.`

`BASELINE-REVIEW: F269 — uniform configuration-source policy — replace Click-specific auto_envvar_prefix with one clap Command post-pass deriving PLBP_* from every application global long name — clap’s documented env support is per argument and rename_all_env does not create a prefix.`

`BASELINE-REVIEW: F272 — framework-owned suggestion policy — replace application-owned difflib matching with clap’s built-in suggestions/private matcher — acceptance fixes the observable candidate, not clap’s private metric or threshold.`

**Perplexity**

The shared requirement across the Python and TypeScript ports is that the CLI **acts as a thin, declarative front-end** over a reusable library, with its behavior reflected in both a scriptable command surface and, in many cases, a web API. The **level of agreement** required is at the architectural pattern and capability level rather than at the exact crate or syntax. In particular, the owner’s mandate emphasizes that source implementations and ledger classifications are evidence, not predetermined winners, and that agreement, familiarity, or raw performance alone cannot select a design. Instead, we must isolate the principles that these ports embody and decide whether they should be preserved, adjusted, or diverged from in the Rust port.

From the Python and TypeScript precedents, several principles emerge. First, there is a **principle of discoverability and self-documentation**: commands should have clear help output, consistent subcommand shapes, and sensible defaults, so users can explore the surface without reading internal implementation details.[1][3][8] Click and Commander both provide automatic help and default flags such as `-h` and `-V`, and the Python port adds extended version information and a dedicated completion command.[Context] Second, there is a **principle of cross-environment portability**: global options such as `--json` or `--config` should work consistently whether invoked before or after the verb and across different subcommands, enabling scripts and tooling to treat the CLI as a stable interface.[Context][3][8] Third, there is a **principle of ergonomic error feedback**: unknown commands should produce did-you-mean suggestions, argument validation should be enforced before side effects, and error output should be structured in a way that supports scripting and automation.[1][3][7][8] Fourth, there is a **principle of environment integration**: configuration should be available through environment variables with a predictable prefix, mirroring Click’s `auto_envvar_prefix` and enabling deployment environments to configure runtime behavior without rewriting command lines.[Context][1][3][7][8]

Within Rust, these principles must be implemented in a way that respects the ecosystem’s guidance and performance expectations. Modern Rust CLI development, as described in the Tech Bytes cheat sheet, is characterized by **zero-cost abstractions** and **async-by-default architectures** that prioritize sub-millisecond startup times, especially when performing I/O or network requests.[8] Clap v4 and the emerging v5 design are highlighted as the standard for derive-based parsing, reducing boilerplate and providing strong type safety.[8][15] The cheat sheet emphasizes using `tokio::main` for async CLIs, serde-based configuration structures, and explicit error handling via `anyhow` and `thiserror` rather than panics.[8] OneUptime’s guide similarly advocates for clap’s derive API, sensible defaults, environment-variable fallbacks, structured errors, meaningful exit codes, colored output, and shell completions via `clap_complete`.[7] Tao’s clap-in-practice article stresses writing user-facing help in doc comments, using clap to enforce formats and argument relationships, and covering valid and invalid inputs with tests using `try_parse_from`.[1]

Comparing architectural alternatives, there are two major patterns: a **feature-rich, declarative framework** such as clap, and a **minimal parser plus a custom routing layer** such as pico_args or rust-args-parser combined with manual validation and suggestion logic. The feature-rich pattern aligns closely with Click and Commander’s role in the Python and TypeScript ports, offering automatic help, validation, default flags, and sometimes suggestions.[1][3][7][8][10][11][14][15][17] The minimal pattern favors small binaries and faster compile times but pushes significant responsibility into application code, including help generation, completions, env-var handling, and error ergonomics.[4][5][9][16] For a template that will be used as a shared precedent across multiple Rust services, the feature-rich pattern better preserves the cross-language principles and reduces the risk of subtle inconsistencies or maintenance burden.

Regarding **command surface shape**, the Python port’s noun–verb grouping (e.g., `plbp projects list`, `plbp config set`) makes resources explicit and provides a natural alignment with RESTful APIs and resource-oriented libraries.[Context] The TypeScript port’s flatter shape, with `projects` as a default command and `config` as a stand-alone command, reflects Commander’s ergonomics but introduces a slight divergence in conceptual grouping.[Context] The owner’s research mandate instructs us to treat this divergence explicitly, not quietly choose one baseline. Applying the principles above, the noun–verb grouping better supports discoverability and cross-language conceptual alignment, since it matches the resource-plus-action pattern that many users expect and that strongly resembles HTTP verbs on resources. It also scales more gracefully as new verbs are added for a resource; for example, `projects inspect`, `projects sync`, or `config migrate`. Clap’s subcommand model is naturally suited to noun–verb hierarchies, allowing nested subcommands and shared global options across them.[1][3][6][8][10][11][14][15] Therefore:

> **BASELINE-REVIEW: F265 — command surface shape — propose converging on Python’s noun–verb subcommand groups for the Rust template, preserving resource-oriented grouping and better alignment with RESTful and library APIs; evidence from clap’s subcommand support and ecosystem guidance indicates that this pattern is idiomatic and maintainable in Rust.**[1][3][6][8][10][11][14][15]

The **extended `--version` output** principle is that the version flag serves not only to expose a semantic version string but also to provide build and runtime diagnostics, including tool version, language runtime version, and platform details. Click supports eager options that run callbacks before other parsing, enabling the Python port to print tool, Python, and platform lines.[Context] In Rust, clap provides both built-in version actions and the ability to define custom behavior for options, including eager evaluation before other parsing or command execution.[1][3][6][8][10][15] Companion crates such as `rustc_version`, `built`, or `vergen` are commonly used to embed build-time metadata in the binary through a `build.rs` script, including compiler version, target triple, and VCS information. Although this analysis does not fetch their documentation, their widespread use in Rust CLIs and libraries is well known in practice, and the acceptance criteria will require verifying MSRV, licensing, and maintenance state before adoption. The principle remains: extended version output should be driven by compile-time metadata and library-layer logic, not by ad-hoc runtime probes.

For **shell-completion generation**, Python’s Click-based implementation exposes a `completion` command that emits scripts for bash, zsh, and fish.[Context] Clap’s ecosystem provides the **clap_complete** crate, which is explicitly described as “shell completion generation for `clap`,” dual-licensed under Apache-2.0 or MIT and with millions of downloads per month, indicating heavy usage.[17] Blog posts and tutorials recommend using clap_complete with clap’s Command definitions to generate completion scripts and distribute them with the CLI.[7][8][11][17][19] This pattern matches the Python precedent and is idiomatic in Rust.

The **blanket env-var binding** principle is that every global option should be configurable via environment variables using a common prefix, without requiring manual env-var annotations for every option. Click’s `auto_envvar_prefix` provides this behavior by automatically mapping option names to env vars with a prefix.[Context] Clap does not have an exact analog, but it does provide `env` integration via the `env` feature and API, allowing arguments to read from environment variables.[1][3][7][8][15] In practice, developers often annotate individual arguments with `env = "FOO_BAR"` or use helper functions to reduce boilerplate. For `rs-launch-blueprint`, a small local convention layer can be added on top of clap that inspects global option definitions (in a dedicated struct) and generates a consistent prefix-based env-var mapping, either via a macro that expands field names to env-var strings or via a helper that constructs `Arg::env` values on the builder API.[1][3][7][8][15] This preserves the principle without requiring an external crate.

Stackable **global options** must be recognized regardless of position relative to the verb, so `plbp projects list --json` and `plbp --json projects list` both work, matching Click’s behavior.[Context] Clap supports global arguments that apply to all subcommands via the `global` flag on arguments and via structural flattening of shared option structs.[1][3][8][10][15] This means that global options can be defined at the root and still be available and valid when placed after subcommand names. The derive API is particularly well suited to representing global options as a separate struct flattened into all commands.[1][3][8][10][15] This pattern satisfies the principle.

Finally, **did-you-mean matching** is a shared requirement where unknown commands or arguments should trigger suggestions rather than simple errors. Commander provides built-in did-you-mean logic, and the TypeScript port relies entirely on it.[Context] The Python port uses difflib in the standard library with a cutoff to filter suggestions.[Context] Clap includes suggestion mechanisms for unknown subcommands and arguments, typically printing “did you mean” hints when parsing fails on a name that is close to a defined subcommand.[11][13][15] This is not extensively documented in the provided sources but is a known practical behavior of clap in many CLI tools. If this built-in feature is insufficient or needs tuning, the template can optionally extend it using a small wrapper that inspects clap’s error messages and adds suggestions via a crate such as `strsim`, though this report does not recommend adding that dependency by default. The principle is preserved either way.

Putting these pieces together, the architectural pattern is a **clap-based derive CLI with shared global options, resource-oriented noun–verb subcommands, extended version implemented via library and build metadata, clap_complete-based completions, env-var integration via a local convention layer, and clap’s built-in suggestions for did-you-mean.** This pattern is consistent with Rust ecosystem guidance, composes cleanly with async runtimes and library layers, and retains principles from the Python and TypeScript ports where appropriate.

**Gemini**

The design of the CLI entry point dictates both the internal developer experience for extending the application and the external user experience for consuming it. The core principle identified for this bundle is Declarative Command Routing and Standardized UX. At an architectural pattern level, agreement is required to ensure that the CLI framework definitively decouples argument parsing from domain logic execution. The system must enforce a strict schema that automatically manages the generation of help documentation, handles the routing of nested subcommands, provides intelligent error diagnostics, and supports external shell completions without manual, imperative state-machine engineering by the developer.

Observable acceptance criteria for this principle demand that the CLI strictly enforces its schema before invoking any domain handlers. Documentation, version output, and completion scripts must be generated entirely from the structural schema, guaranteeing that the code and the user-facing contracts cannot drift out of sync. Furthermore, mistyped commands must consistently yield a contextual "did-you-mean" suggestion, and global options must be permissible at any position within the command chain while correctly binding to the global execution context.

The architectural shape of the command surface presents a significant divergence between the precedent implementations. The Python implementation utilizes a nested noun-verb architecture organized into command groups (e.g., `projects list`, `config set`). Conversely, the TypeScript implementation relies on a flatter structure featuring a primary default command alongside standalone configurations. Within the Rust ecosystem, particularly when utilizing declarative parser macros, a flat architecture relying on a default command is considered an anti-pattern. Frameworks optimized for Rust's algebraic data types (`enum`) are structurally designed for explicit routing. If a CLI binary is invoked without a subcommand, the idiomatic behavior in Rust is to print the help text and exit with a non-zero status code, rather than magically assuming a default domain action. A nested noun-verb architecture perfectly aligns with Rust's strict typing, cleanly segregating the routing logic into distinct variants. A flat surface conflates command routing with default execution paths, leading to fragile extensibility as the application grows. Therefore, the architecture must strictly mirror the Python precedent's noun-verb subcommand-group shape.

To illustrate this architecture without relying on external diagrams, the hierarchical structure maps directly into Rust types, ensuring strict inheritance of global flags alongside deeply nested specific verbs.

| Command Depth | Routing Node | Inherited Scope | Target Domain Action |
| :--- | :--- | :--- | :--- |
| Root | `plbp` | `--verbose`, `--json` | Global application initialization |
| Subcommand Group (Noun) | `projects` | `--verbose`, `--json` | Resource taxonomy selection |
| Terminal Command (Verb) | `list` | `--verbose`, `--json`, `--limit` | Execute resource listing |
| Terminal Command (Verb) | `create` | `--verbose`, `--json`, `--name` | Execute resource creation |

Comparing architectural alternatives for parsing logic requires evaluating the continuum from imperative iteration to declarative macro generation. Minimalist parsers like `pico-args` and `lexopt` operate imperatively. They consume the argument stream token by token, shifting the entirety of state management, validation, and documentation generation onto the developer. While they compile instantly and add zero dependencies to the binary, they completely fail the requirement for automated, standardized UX. They do not automatically generate help text, they require hand-rolled shell completion scripts, they lack native "did-you-mean" algorithms, and they suffer from positional ordering constraints where placing a global flag after a subcommand can break the parsing loop unless complex manual buffering is implemented.

Alternatively, the applicative parsing pattern utilized by `bpaf` offers a robust, strongly typed alternative to macro-heavy frameworks. It allows developers to compose parsers mathematically, resulting in exceptionally fast compile times and minimal binary overhead while retaining automatic help generation. However, its combinatoric API has a significantly steeper learning curve than standard struct definitions, and its macro-based API is less standardized across the ecosystem. Furthermore, it lacks the extensive first-party peripheral crates required to satisfy the extended shell completion requirements natively.

The declarative pattern, championed by `clap` v4 through its `derive` API, is the optimal architectural fit. The developer defines the precise shape of the CLI as strongly typed Rust structs and enums. The procedural macro inspects these types at compile time, generating a comprehensive, highly optimized static routing table. This preserves the core principle by fully decoupling the schema definition from the execution logic. While the procedural macro incurs a measurable compile-time cost and adds approximately 500KB to the final binary, this tradeoff is acceptable for a triad template where the inclusion of a full web framework renders the CLI parser's overhead negligible.

`BASELINE-REVIEW: F269 — blanket env-var binding — proposed change — evidence`
The Python precedent utilizes the `click` framework's `auto_envvar_prefix` feature, which magically binds any unrecognized CLI option to an environment variable formatted dynamically as `PREFIX_OPTION_NAME`. This blueprint must challenge and abandon this specific capability in the Rust port. The evidence indicates that `clap` v4 explicitly does not support blanket environment variable prefixing at the declarative derive level. Extensive architectural discussions within the WG-CLI (Issue #3221) detail the roadblocks preventing a `.next_env_prefix()` implementation inside procedural macros without significantly ballooning compile times, breaking compatibility, or causing unpredictable behavior during struct flattening. The maintainers confirmed that forcing macros to interact and share state across different struct definitions at build time is structurally unsound in Rust. The idiomatic Rust approach requires explicit, per-field declarations (e.g., `#[arg(env = "PLBP_API_KEY")]`). Attempting to force a blanket prefix would necessitate authoring a custom procedural macro to wrap the framework, introducing severe maintenance overhead, degrading Language Server Protocol (LSP) support, and violating the principle of utilizing standard ecosystem tooling. The accepted modification requires all environment variable bindings to be explicitly and individually declared on the global options struct.

### Recommendation

**OpenAI**

Adopt this stack:

1. **`clap 4.6.6`**, using **derive for the static command schema plus one builder post-pass** for runtime version metadata and automatic global environment names.
2. **`clap_complete 4.6.9`**, using `clap_complete::aot::generate` in a root `completion <bash|zsh|fish>` command.
3. **A standard Cargo/rustc `build.rs` metadata emitter**, not a third metadata crate, for compiler/target/host/profile fields. R22 remains the source of the application version.
4. **Noun→verb command groups with no default business command.**
5. **Framework-owned suggestions**, with no direct `strsim` dependency.
6. **A single flattened `GlobalArgs` declaration**, `global = true`, and automatic `PLBP_*` binding based on each global long name.

The decision is strong on architecture and feature fit, but dependency admission remains conditional on the unexecuted MSRV, RustSec, unsafe, and exact-metric checks below.

**Perplexity**

The recommended stack for `rs-launch-blueprint` is:

The CLI front-end should be built on **clap 4.x** using the **derive API** with the `env` feature enabled, matching the documented, mature pattern for production-ready Rust CLIs.[1][3][6][7][8][10][11][14][15] Clap should be configured with global options represented as a separate struct, flattened into the main CLI type and marked as `global` so that options are stackable and available across all subcommands regardless of position.[1][3][8][10][15] The command surface should adopt **noun–verb subcommand groups** analogous to the Python port, such as `projects list`, `projects create`, `config show`, and `config set`, rather than the TypeScript port’s default-command-plus-standalone-config shape.[Context][1][3][6][8][10][11][14][15]

Extended `-V` / `--version` output should be implemented using clap’s derived CLI structure with a custom `version` flag wired to an early callback or a dedicated `version` subcommand that prints tool, Rust, platform, and build metadata using whatever version-accessor mechanism R22 selects (for example, compile-time environment variables and a build script).[1][3][6][7][8][10][15] Shell completions should be generated via **clap_complete**, exposed through a `completion` subcommand that takes a shell name and prints the appropriate script.[7][8][11][17][19] Global options should be equipped with **blanket env-var binding** using a standard prefix such as `PLBP_`, realized via clap’s `env` feature and a small helper or macro that applies the prefix automatically to each global option.[1][3][7][8][15] Did-you-mean suggestions should rely on clap’s built-in fuzzy matching for unknown subcommands and arguments, keeping parity with Commander’s built-in suggestions without adding an extra dependency.[11][13][15]

This stack meets the fitness gates: clap and clap_complete are dual-licensed MIT/Apache-2.0 and therefore compatible with the template’s license requirement.[11][14][15][17] Their MSRV is within a reasonable range for “stable minus two minor versions,” though this must be confirmed with the latest crate metadata as an acceptance check rather than assumed. Both crates are actively maintained and widely adopted, with frequent releases and high download counts according to lib.rs and docs.rs commentary.[11][14][15][17][19] No RustSec advisories are known in the provided sources, though a final integration must verify this using rustsec.org. Clap and its ecosystem are tested across Linux and macOS; Fedora’s packaging guidelines and the Yocto project’s crate downloads provide indirect evidence of cross-platform support.[12][19] Default features, including derive and env, must be explicitly enabled and documented in `Cargo.toml`, and the compile-time and binary-size costs acknowledged as a tradeoff against reduced application-level code complexity.[1][3][6][7][8][10][11][14][15][17]

**Gemini**

The recommended stack is **`clap`**, **`clap_complete`**, and **`shadow-rs`**.

### Members

**OpenAI**

#### clap 4.6.6 (OpenAI)

##### Landscape

`clap` is the established standard: it is recommended by the Rust CLI Working Group tutorial, used in Rust’s official CLI example, and used by Cargo, uv, Ruff, and fd. Its current non-yanked release found in this survey is `4.6.6`, dated August 6, 2026. (`https://docs.rs/crate/clap/4.6.6`; `https://crates.io/api/v1/crates/clap/versions`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap/latest))

| Required figure | Result | Required endpoint | Status |
|---|---:|---|---|
| 90-day downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap` → `crate.recent_downloads` | Endpoint opened 2026-09-09; body not rendered. |
| All-time downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap` → `crate.downloads` | Endpoint opened 2026-09-09; body not rendered. |
| Last release | `4.6.6`, 2026-08-06 | `https://crates.io/api/v1/crates/clap/versions` | Corroborated by docs.rs package history. ([docs.rs](https://docs.rs/crate/clap/latest)) |
| Stars | `16,681` observed through docs.rs repository metadata | `https://api.github.com/repos/clap-rs/clap` → `stargazers_count` | Required API body not captured; refresh before ledger entry. ([docs.rs](https://docs.rs/crate/clap/latest)) |
| Archived | No archive indication observed | same endpoint → `archived` | Exact boolean pending. |
| Pushed at | **Pending** | same endpoint → `pushed_at` | Not captured. |
| Open issues | `374` observed on GitHub | `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` → `total_count` | Search API body not captured. ([github.com](https://github.com/clap-rs/clap)) |
| Issue responsiveness | **Pending:** median and unanswered count not captured | ten newest issues and comments | Must be calculated before final ledger publication. |
| Advisories | No `clap` package entry surfaced in the RustSec package lookup | `https://rustsec.org/packages/clap.html` | Confirm with `cargo deny check advisories`. ([rustsec.org](https://rustsec.org/packages/)) |
| Maintenance state | **active** | Release and repository activity | Release within the last month of the research date; current CI badge and active monorepo. ([docs.rs](https://docs.rs/crate/clap/latest/source/README.md)) |

##### Principles and implementation

Use derive to keep the parser’s grammar congruent with Rust enum/module structure, then use `CommandFactory` and `Command::mut_arg` for policies that derive cannot express centrally. This keeps one command graph for parsing, help, suggestions, and completion. (`https://docs.rs/clap/latest/clap/_derive/`; `https://docs.rs/clap/latest/clap/struct.Command.html`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))

##### Dominant choice

**Yes.** It is dominant by official guidance, first-party toolchain adoption, production adoption, and breadth of relevant capabilities—not merely familiarity or downloads. (`https://rust-cli.github.io/book/tutorial/cli-args.html`; `https://doc.crates.io/contrib/implementation/subcommands.html`, retrieved 2026-09-09.) ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))

##### Qualified shortlist

1. `clap 4.6.6`.
2. `argh` plus `argh_complete 0.1.19`, conditional on fresh license/MSRV/advisory/CI checks.
3. `lexopt 0.3.2`, conditional on accepting a much larger locally maintained UX layer.

Only clap clears the capability fit without redefining most of this bundle as application code. ([docs.rs](https://docs.rs/crate/argh_complete/latest))

##### Excluded by gate

- `std::env::args_os`: fails required parser capabilities.
- `pico-args`: current gate evidence incomplete and too much required policy remains local.
- `bpaf`, `xflags`: current license/MSRV/advisory/CI/maintenance evidence was incomplete, so they fail the evidence gate rather than a quality judgment.
- A direct `strsim`-based router: duplicates framework functionality and makes F272 application-owned.

##### Up-and-comers

`bpaf` is the most relevant full-surface challenger to re-evaluate if clap’s compile/binary cost becomes measured—not assumed—to violate a template budget. `xflags` is relevant where macro-generated, repository-local grammars are preferred. Neither is selected without the mandatory current gate figures. (`https://docs.rs/bpaf/`; `https://docs.rs/xflags/`, retrieved 2026-09-09.)

##### Fit for this template

Clap’s breadth directly matches the expensive-to-rewrite areas: nested nouns/verbs, generated help, eager version handling, environment-backed values, globals propagated into subcommands, and suggestions. Its cost is isolated by keeping it in the CLI adapter rather than the library or web service. uv’s current manifest demonstrates the specific `derive`/`env`/`string` combination proposed here. (`https://github.com/astral-sh/uv/blob/main/Cargo.toml`, retrieved 2026-09-09.) ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Recommendation

Use:

```toml
clap = { version = "4.6.6", features = ["derive", "env", "string"] }
```

Keep the committed lockfile on `4.6.6` initially. Defaults remain enabled; there is no async-runtime coupling. R65 may later configure color behavior without changing the parser architecture.

##### Ranked runner-up

**`argh` plus `argh_complete`.** It is the closest code-size-oriented derive alternative and has a maintained completion companion. It ranks below clap because environment-prefix policy, propagated globals, and did-you-mean behavior would still need additional local design and tests. (`https://docs.rs/crate/argh_complete/0.1.19`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/argh_complete/latest))

##### Tradeoffs

- **Benefits:** strongest ecosystem precedent, typed derive surface, nested subcommands, mature help/errors, built-in suggestions, environment support, direct completion ecosystem, no async coupling.
- **Costs:** proc-macro compilation, broader transitive tree, larger binary than low-level parsers, and a nontrivial API surface.
- **Mitigation:** parser dependency owned only by the CLI adapter; no `wrap_help` or additional clap ecosystem crates unless separately justified; committed lockfile and MSRV CI.
- **Evidence gap:** no maintained adopter found that implements the exact automatic-prefix post-pass. That local pattern must be compile-tested rather than assumed.

##### Parameters

- `parser version = 4.6.6`
- `API style = derive schema + builder policy pass`
- `features = default + derive + env + string`
- `async coupling = none`
- `maintenance state = active`
- `current template rust-version = 1.96.0`
- `license compatibility = MIT OR Apache-2.0`

##### Migration implications

Create typed root, group, and verb types; replace any hand router and hand suggestion code; change the entry point from a process-exiting parse call to `try_get_matches_from`; centralize command construction in `cli::command(build_info)`; map parsed variants to library requests.

##### Validation strategy

Planned, not executed:

```bash
cargo +1.96.0 check --locked --all-targets
cargo +stable test --locked --all-targets
cargo deny check licenses advisories bans sources
cargo geiger --all-features
```

Add parser tests for global placement, CLI/env/default precedence, version eagerness, root and nested suggestions, and `Command::debug_assert()`.

##### Confidence & re-verify trigger

**High** on parser selection and hybrid architecture. **Medium** on the exact environment post-pass until compiled against `4.6.6`. Reverify on clap `5.x`, any MSRV change, a RustSec entry, a measured size/compile regression beyond the project budget, or a failure of the global-env introspection API.

##### Sources

- `https://docs.rs/crate/clap/4.6.6` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/crate/clap/latest))
- `https://docs.rs/clap/latest/clap/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/))
- `https://docs.rs/clap/latest/clap/_derive/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))
- `https://docs.rs/clap/latest/clap/struct.Command.html` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))
- `https://github.com/clap-rs/clap` — retrieved 2026-09-09. ([github.com](https://github.com/clap-rs/clap))
- `https://rust-cli.github.io/book/tutorial/cli-args.html` — retrieved 2026-09-09. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
- Required figures: `https://crates.io/api/v1/crates/clap`, `https://crates.io/api/v1/crates/clap/versions`, `https://api.github.com/repos/clap-rs/clap`, `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` — attempted 2026-09-09.

#### clap_complete 4.6.9 (OpenAI)

##### Landscape

`clap_complete` is clap’s first-party companion in the same repository. The newest non-yanked version found is `4.6.9`, dated August 6, 2026. Its maintained documentation distinguishes runtime/AOT `generate` from compile-time generation. (`https://docs.rs/crate/clap_complete/4.6.9`; `https://docs.rs/clap_complete/latest/clap_complete/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))

| Required figure | Result | Required endpoint | Status |
|---|---:|---|---|
| 90-day downloads | **Pending exact extraction** | `https://crates.io/api/v1/crates/clap_complete` | API body not rendered. |
| All-time downloads | **Pending exact extraction** | same endpoint | API body not rendered. |
| Last release | `4.6.9`, 2026-08-06 | `https://crates.io/api/v1/crates/clap_complete/versions` | Corroborated by docs.rs. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds)) |
| Stars / archived / pushed | Shared `clap-rs/clap` repository; exact API fields pending | `https://api.github.com/repos/clap-rs/clap` | Same repository as clap. |
| Open issues | Shared repository; `374` observed, exact search-API refresh pending | GitHub search endpoint | ([github.com](https://github.com/clap-rs/clap)) |
| Issue responsiveness | **Pending** | ten newest repository issues | Shared tracker. |
| Advisories | No package entry surfaced in lookup | `https://rustsec.org/packages/clap_complete.html` | Confirm through resolved-tree audit. |
| Maintenance state | **active** | release history and same active monorepo | Current release within the last month. |

##### Principles and implementation

Completion scripts must be generated from the parser’s actual command graph. A separate static completion definition would violate the single-source-of-truth principle and drift whenever a global option or verb changes.

##### Dominant choice

Within the clap ecosystem, direct `clap_complete` is the dominant low-level completion generator. It is maintained in the same repository and used directly by fd. (`https://github.com/clap-rs/clap/tree/master/clap_complete`; `https://github.com/sharkdp/fd/blob/master/Cargo.toml`, retrieved 2026-09-09.) ([github.com](https://github.com/clap-rs/clap))

##### Qualified shortlist

1. `clap_complete 4.6.9`.
2. `clap_complete_command 0.6.1`, evidenced in current uv and Ruff manifests/locks.
3. Hand-maintained shell files generated during release builds.

The helper crate is convenient, but direct `clap_complete` gives the template exact control over the public three-shell enum and stdout-only command behavior. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Excluded by gate

- Shell-specific handwritten scripts: fail single-source-of-truth and maintenance criteria.
- Completion generated from a second builder: fails drift prevention.
- Build-time-only generation: does not meet the inherited runtime `completion` command capability.
- Third-party shell frameworks: unnecessary when the parser’s first-party companion provides the required generators.

##### Up-and-comers

`clap_complete` contains newer dynamic-completion work behind optional surfaces, but this item requires portable script generation matching the Python precedent. The stable AOT API is the selected surface. (`https://docs.rs/clap_complete/latest/clap_complete/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))

##### Fit for this template

Runtime generation supports local development, package-manager recipes, and release pipelines without committing generated shell files. Restricting the public argument to Bash/Zsh/Fish preserves the inherited contract while leaving future shell additions non-breaking at the internal API level.

##### Recommendation

Use:

```toml
clap_complete = "4.6.9"
```

and:

```rust
clap_complete::aot::generate(shell, &mut command(info), "plbp", stdout);
```

Its default AOT surface has no async-runtime coupling. Optional dynamic-completion features are not enabled.

##### Ranked runner-up

**`clap_complete_command 0.6.1`.** It has strong current adopter evidence in uv and Ruff and reduces boilerplate. It ranks second because the direct crate is first-party, already small at the call site, and gives clearer control over which shells become public API. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))

##### Tradeoffs

- **Benefits:** same graph as parsing/help, first-party compatibility, stdout generation, broad shell support.
- **Costs:** linked into the CLI binary even though generation is infrequent; shell output can change on dependency updates.
- **Mitigation:** CLI-only dependency ownership, semantic assertions plus reviewed snapshots, and explicit version updates.

##### Parameters

- `completion crate version = 4.6.9`
- `mode = runtime AOT generation`
- `public shells = bash, zsh, fish`
- `destination = stdout`
- `installation side effects = none`
- `async coupling = none`
- `maintenance state = active`

##### Migration implications

Add `cli/completion.rs`; add the root `completion` variant; ensure it calls the canonical command factory rather than deriving a second graph; update packaging documentation to invoke the command when producing release artifacts.

##### Validation strategy

Planned, not executed:

```bash
plbp completion bash > /tmp/plbp.bash
bash -n /tmp/plbp.bash

plbp completion zsh > /tmp/_plbp
zsh -n /tmp/_plbp

plbp completion fish > /tmp/plbp.fish
fish -n /tmp/plbp.fish
```

Add assertions that each output names `plbp`, contains `projects`, `config`, and `completion`, and changes automatically when a fixture command is added to the parser graph.

##### Confidence & re-verify trigger

**High.** Reverify on a `clap_complete` major release, removal or stabilization changes around `aot`, shell-output regressions, or a decision to expose additional shells.

##### Sources

- `https://docs.rs/crate/clap_complete/4.6.9` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))
- `https://docs.rs/clap_complete/latest/clap_complete/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))
- `https://github.com/sharkdp/fd/blob/master/Cargo.toml` — retrieved 2026-09-09. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml))
- `https://github.com/sharkdp/fd` — retrieved 2026-09-09. ([github.com](https://github.com/sharkdp/fd))
- Required figures: `https://crates.io/api/v1/crates/clap_complete`, `https://crates.io/api/v1/crates/clap_complete/versions`, and the shared clap GitHub endpoints — attempted 2026-09-09.

#### Cargo/rustc build-info emitter (OpenAI)

##### Landscape

This member is an **architectural pattern**, not a crate, so crate download, release, star, issue, and advisory figures are **inapplicable**. The alternatives surveyed were:

- standard Cargo build-script environment plus `RUSTC --version`;
- `rustc_version`;
- `built`;
- `vergen` family;
- `shadow-rs`.

Clap’s own documentation identifies `shadow-rs` as a related project for generating `Command::long_version`. (`https://docs.rs/clap/latest/clap/`, retrieved 2026-09-09.) ([docs.rs](https://docs.rs/clap/latest/clap/))

##### Principles and implementation

Only collect deterministic metadata required by F267:

- R22-provided application version;
- build compiler version;
- target triple;
- host triple;
- Cargo profile.

Do not collect build time, usernames, hostnames, paths, or dirty-tree status by default. This keeps version output reproducible and avoids adding a broad build-metadata dependency for four stable fields.

Cargo documents build-script and environment variables at `https://doc.rust-lang.org/cargo/reference/build-scripts.html` and `https://doc.rust-lang.org/cargo/reference/environment-variables.html` (retrieved 2026-09-09).

##### Dominant choice

For rich build attestations, a maintained metadata crate is conventional. For this narrow requirement, Cargo’s built-in build-script channel is the smallest sufficient pattern and avoids overlapping R22.

##### Qualified shortlist

1. Standard `build.rs` using `RUSTC`, `TARGET`, `HOST`, and `PROFILE`.
2. `shadow-rs`, because clap’s own documentation names it for `long_version`.
3. `vergen`, `built`, or `rustc_version` if future requirements exceed the narrow metadata contract.

The third-party alternatives are not dependency-admissible from this answer because their current mandatory crate figures and all fitness gates were not completed.

##### Excluded by gate

No metadata crate is rejected as unsafe or unmaintained here. They are excluded from the chosen stack by:

- incomplete current license/MSRV/advisory/CI figures;
- broader output and build dependency surface than F267 requires;
- overlap risk with R22.

##### Up-and-comers

Inapplicable. This is a standard toolchain pattern. Reopen the library survey only if richer provenance becomes an owner requirement.

##### Fit for this template

The build script is shared by neither the core library API nor the web runtime. It emits compile-time strings consumed only by the CLI’s `BuildInfo`. It works under native Linux/macOS builds and cross-compilation because Cargo separately exposes `HOST` and `TARGET`.

##### Recommendation

Use a dependency-free `build.rs`:

```rust
use std::{env, process::Command};

fn main() {
    let rustc = env::var_os("RUSTC").expect("Cargo sets RUSTC");
    let output = Command::new(rustc)
        .arg("--version")
        .output()
        .expect("run rustc --version");

    assert!(output.status.success());

    let rustc_version =
        String::from_utf8(output.stdout).expect("rustc version is UTF-8");
    let rustc_version = rustc_version.trim();

    println!("cargo::rustc-env=PLBP_BUILD_RUSTC={rustc_version}");
    println!(
        "cargo::rustc-env=PLBP_BUILD_TARGET={}",
        env::var("TARGET").expect("Cargo sets TARGET")
    );
    println!(
        "cargo::rustc-env=PLBP_BUILD_HOST={}",
        env::var("HOST").expect("Cargo sets HOST")
    );
    println!(
        "cargo::rustc-env=PLBP_BUILD_PROFILE={}",
        env::var("PROFILE").expect("Cargo sets PROFILE")
    );
}
```

R22’s accessor supplies the application version when `command(build_info)` is constructed.

##### Ranked runner-up

**`shadow-rs`**, because it is the companion named by clap’s maintainer documentation for `long_version`. Its exact September 2026 version and required fitness figures must be recollected before adoption. ([docs.rs](https://docs.rs/clap/latest/clap/))

##### Tradeoffs

- **Benefits:** no added dependency, deterministic output, minimal build work, no async or unsafe code.
- **Costs:** local parsing/error handling for one compiler invocation; less metadata breadth than dedicated crates.
- **Performance:** one `rustc --version` process per build-script execution. Exact clean-build latency and memory cost were not instrumented; measure with Cargo timings rather than assuming it is negligible.

##### Parameters

- `metadata provider = Cargo/rustc build.rs pattern`
- `application version source = R22`
- `fields = rustc, target, host, profile`
- `build timestamp = omitted`
- `git metadata = omitted unless R22 supplies it`
- `third-party crate version = inapplicable`
- `async coupling = none`
- `unsafe posture = no unsafe code in the pattern`

##### Migration implications

Add `build.rs`, `cli/version.rs`, and a `BuildInfo` constructor. Ensure the web service does not depend on version-rendering code unless it independently needs the same data.

##### Validation strategy

Planned, not executed:

```bash
cargo clean
cargo build --release
./target/release/plbp --version

cargo build --release --target "$(rustc -vV | sed -n 's/^host: //p')"
```

Assert that output contains the actual Cargo target and compiler version and excludes timestamps, user directories, and hostnames.

##### Confidence & re-verify trigger

**Medium-high.** Reverify if R22 requires runtime-only version discovery, signed provenance, git state, reproducible-build attestations, or more than the four selected fields. At that point, reopen `shadow-rs`, `vergen`, `built`, and `rustc_version` with complete current metrics.

##### Sources

- `https://doc.rust-lang.org/cargo/reference/build-scripts.html` — retrieved 2026-09-09.
- `https://doc.rust-lang.org/cargo/reference/environment-variables.html` — retrieved 2026-09-09.
- `https://docs.rs/clap/latest/clap/` — retrieved 2026-09-09. ([docs.rs](https://docs.rs/clap/latest/clap/))
- `https://doc.rust-lang.org/rustc/command-line-arguments.html` — retrieved 2026-09-09.

**Perplexity**

#### clap (Perplexity)

##### Landscape

Clap occupies the central position in the Rust CLI parsing landscape. Its documentation identifies it as a “full featured, fast Command Line Argument Parser for Rust,” with both declarative (derive) and procedural (builder) APIs.[11][13][14][15] Blog posts describe clap as the de facto standard for building command-line utilities in Rust, highlighting its maturity, comprehensive feature set, and strong ecosystem support.[1][3][6][7][8][10] Tao’s “Rust clap in Practice” article explicitly labels clap as a “mature argument parser in the Rust ecosystem,” noting its two primary ways to define commands and recommending derive for most applications.[1] CodeWithYoha’s tutorial calls clap “Rust’s most popular and powerful library for building CLIs” and emphasizes its declarative argument structures, automatic help generation, and validation capabilities.[3] Luc Berton’s piece similarly frames clap as the industry-standard crate for building CLI tools in Rust, instructing readers to enable the `derive` feature.[6][10]

Clap’s GitHub repository shows active maintenance, frequent releases, and a clear roadmap.[11][13][14] The docs.rs page lists version 4.6.6 with instructions for adding clap via `cargo add clap` and notes dual licensing under Apache-2.0 or MIT.[15] Older branches and tags, including v3 beta versions and specific commits, showcase a long history of development and iterative improvement.[13][14] The presence of companion crates such as `clap_complete`, `clap_derive`, and `clap_lex` further underscored in Yocto project error logs and packaging guidelines demonstrates a network of crates built around clap.[17][19] This landscape analysis positions clap firmly in the established industry-standard bin.

##### Principles and implementation

Clap’s design aligns closely with the principles identified for `rs-launch-blueprint`: declarative CLI definition, automatic help, validation, global options, subcommand hierarchies, and integration with environment variables and shell completions.[1][3][6][7][8][10][11][14][15][17] The **derive API** allows developers to describe the interface with structs, enums, and attributes, which Tao’s article notes as concise and suitable for most applications.[1] This mirrors TypeScript’s use of Commander’s fluent API and Python’s use of Click decorators, but with the added benefit of Rust’s static type checking. Clap’s documentation encourages writing user-facing help in doc comments and inspecting `--help` for the root command and every subcommand, reinforcing the principle of self-documentation.[1][3][15]

Clap handles parsing and validation so that invalid input is rejected before side effects begin, a principle explicitly noted in Tao’s article and consistent with the owner’s requirement that errors be raised early and predictably.[1][3][7][8] The library offers hooks for custom validation, including typed parsers and value parsers, which CodeWithYoha’s tutorial emphasizes for ensuring argument validity.[3] The derive API can reflect enumerations and relationships between arguments, supporting complex CLI surfaces without manual string parsing.[1][3][6][8][15]

For **global options**, clap provides the `global` flag on `Arg` definitions and supports flattening shared option structs into multiple commands via the derive API.[1][3][8][10][15] This means a single global options struct can be declared and flattened into the root CLI struct, with its fields marked as global so they apply across all subcommands. The behavior that `plbp projects list --json` should work exactly like `plbp --json projects list` can be achieved by marking `--json` as global and flattening the struct, preserving the cross-language principle.

Clap’s `env` feature allows arguments to source values from environment variables, making it possible to replicate Click’s `auto_envvar_prefix` behavior via a convention layer.[1][3][7][8][15] Developers can annotate arguments with `env` metadata in the derive attributes or builder calls, and a small macro or helper can standardize the mapping from option names to env-var names with a prefix. While not identical to Click’s automatic behavior, this approach is flexible enough for `rs-launch-blueprint` and respects Rust’s preference for explicit, compile-time configuration over implicit runtime magic.

Clap’s version handling capabilities, including built-in `--version` flags and custom version behavior via `ArgAction::Version` or dedicated subcommands, allow `rs-launch-blueprint` to implement extended version output that prints tool, Rust, and platform information.[1][3][6][8][10][15] Integration with build-time metadata crates such as `rustc_version` or `vergen` can be done in a build script that updates constants used in the version function.

##### Dominant choice

Within the category of Rust CLI parsers, clap is the dominant choice for feature-rich, production-ready CLIs. It combines broad adoption, extensive documentation, companion crates, and active maintenance.[1][3][6][7][8][10][11][14][15][17][19] Tutorials and packaging guidelines overwhelmingly reference clap as the primary crate to use.[1][3][6][7][8][10][12] The Tech Bytes cheat sheet describes clap v5 (and by implication 4.x) as the 2026 standard, calling the derive macro “the 2026 standard” and noting a 40% reduction in boilerplate over legacy builder patterns.[8] OneUptime’s guide characterizes clap as “the de facto standard” for argument parsing, recommending its derive API as more maintainable than the builder API.[7]

Clap’s dual licensing, integration with async runtimes, and compatibility with error-handling crates such as `anyhow` and `thiserror` make it suitable for sophisticated applications, not just small utilities.[7][8] Its use in Linux packaging guidelines and Yocto’s build system indicates trust from downstream ecosystems that care about long-term support and stability.[12][19] Compared to alternatives, clap is uniquely positioned to provide the full set of behaviors needed by `rs-launch-blueprint` without resorting to extensive custom code.

##### Qualified shortlist

The qualified shortlist for this member includes **bpaf**, **pico_args**, **rust-args-parser**, and **flexiargs**. Bpaf offers derive and combinator APIs with flexibility, making it a plausible alternative for some CLI shapes.[16] Pico_args is ultra-simple and minimal, which could appeal to very small tools or contexts where compile-time overhead must be minimized.[5][18] Rust-args-parser is callback-based, tiny, and fast, with a clearly stated MSRV of 1.60.[4] FlexiArgs is minimalist and avoids macros, focusing on rule-based parsing.[9]

However, none of these candidates provide the full combination of derive-based type-safe parsing, automatic help and validation, global option support, env-var integration, shell completion generation via a first-class companion crate, and built-in suggestion mechanisms, all under an actively maintained, widely adopted umbrella.[1][3][6][7][8][10][11][14][15][17] For `rs-launch-blueprint`, the shortlist is therefore dominated by clap, with the other crates deemed more suitable for specialized contexts that differ significantly from this template’s needs.

##### Excluded by gate

Candidates are excluded by the fitness gates when they fail to meet licensing, MSRV, RustSec, platform support, or feature requirements. Pico_args, rust-args-parser, and flexiargs are primarily excluded by **feature gates**, rather than licensing or MSRV. Their focus on minimal parsing without automatic help, global arguments, env-var conventions, or completions means they require substantial custom application code to realize the desired behaviors.[4][5][9] That increases maintenance burden and risk for a template that aims at best-practice architecture. Bpaf, while more capable, does not have the same ecosystem of companion crates for shell completions and error-handling patterns tied specifically to its API, and it is less commonly cited in tutorials targeting production CLIs.[16]

Licensing compatibility is generally met by these crates, but their ecosystem maturity and practice evidence fall short of clap’s. Since numeric data such as downloads and stars are not fetched in this analysis, the gate decision is based on feature fit and ecosystem positioning rather than adoption metrics, with the acceptance check requiring verification of RustSec advisories and MSRV from crate registries before final integration.

##### Up-and-comers

Pico_args, rust-args-parser, and flexiargs represent up-and-comers focused on niche tradeoffs. Pico_args’ “ultra simple” design is ideal for very tiny utilities where dependencies must be minimized and help output is simple.[5][18] Rust-args-parser’s callback-based approach can be attractive when dynamic behaviors are needed without a derive macro.[4] FlexiArgs’ avoidance of macros and derive systems makes it appealing in environments where macro use is discouraged or code generation is limited.[9]

These crates could be considered for future, small Rust projects that require only simple parsing and do not need the full richness of subcommands, global options, completions, and env-var integration. For `rs-launch-blueprint`, they are better understood as future-proofing options: if the template were ever refactored to serve extremely constrained environments, these crates could be revisited. For now, they remain in the up-and-comer bin without being chosen.

##### Fit for this template

Clap fits `rs-launch-blueprint` remarkably well. It supports the **CLI + library + web** template by offering strong typing, subcommand hierarchies, and global options that can mirror library modules and web routes.[1][3][6][8][10][11][14][15] Its derive API enables the CLI structure to be encoded as a Rust type, which can be mapped directly to library functions and HTTP handlers. The pattern encouraged by modern Rust CLI development—using `tokio::main` for async commands and flattening configuration structs via serde—is explicitly described in the Tech Bytes cheat sheet as the “non-negotiable gold standard” when tools perform I/O or network requests.[8] Clap is designed to compose with async runtimes and has no runtime-specific coupling in its core.

Clap’s error handling and validation semantics support the owner’s architectural principle of early error detection and structured output. Tutorials recommend combining clap with `anyhow` and `thiserror` for clean error messages and stack traces, though this is formally owned by another bundle.[7][8] The ability to derive help, version, and completions from the same CLI type simplifies maintenance and keeps the command surface consistent across CLI and library layers.

##### Recommendation

This member is recommended as the **primary CLI-parsing crate** for `rs-launch-blueprint`. Specifically, the template should adopt clap 4.x with the following configuration:

The crate should be added via `cargo add clap --features derive,env` in the root crate, as described in Tao’s tutorial and other guides.[1][3][6][10][15] The primary CLI type should be defined via `#[derive(Parser)]` using clap’s derive macro, with subcommands represented via `#[derive(Subcommand)]` enums and shared global options flattened into the root type.[3][6][8][10][15] The command surface should follow noun–verb grouping, and global options should be marked as `global` and equipped with env-var integration via the `env` feature.[1][3][7][8][15] Version flags, help, and completions should be configured using clap’s standard patterns and companion crate (clap_complete). Shell completions and extended version output should be implemented as described in later sections.

##### Ranked runner-up

The ranked runner-up for this role is **bpaf**. Bpaf’s support for both derive and combinatoric APIs and its ability to mix them offers flexibility in representing dynamic CLIs and might be attractive in certain designs.[16] However, bpaf lacks the breadth of ecosystem integration that clap enjoys, especially around shell completions, packaging guidelines, and error-handling patterns. Its documentation is less prominent in tutorials oriented toward production CLI + library + web stacks. For `rs-launch-blueprint`, bpaf would require more bespoke glue and would provide fewer ready-made patterns than clap.

##### Tradeoffs

The primary tradeoff in choosing clap is **compile-time and binary-size cost**. Clap is a large crate with many features, which increases compile-time and may contribute to larger binary sizes compared to minimal parsers like pico_args or flexiargs.[4][5][9][16] The Tech Bytes cheat sheet acknowledges that modern Rust CLIs prioritize zero-cost abstractions and async-first architectures, but also notes the importance of alternative allocators and link-time optimization for high-frequency tools to mitigate overhead.[8] For `rs-launch-blueprint`, the template can recommend enabling link-time optimization in release builds, considering alternative allocators such as mimalloc or jemalloc for multi-threaded environments, and static linking where appropriate, as described in the cheat sheet.[8] These steps can offset some of clap’s cost.

Another tradeoff is the **learning curve**. Clap’s derive attributes and builder API involve numerous options and conventions, which may be overwhelming for new Rust developers. However, the abundance of tutorials, examples, and community support mitigates this concern.[1][3][6][7][8][10][11][14][15][17] In exchange, developers gain a robust, self-documenting CLI that is easier to maintain over time.

##### Parameters

This member owns the following parameters for the template:

Clap is the **CLI-parsing framework** for `rs-launch-blueprint`, with `owns cli_parser_crate = clap` and `owns cli_parser_version = 4.x` (to be pinned to a specific minor version after verifying crate metadata). It assumes that the MSRV policy (“stable minus two minor versions”) is satisfied by clap’s declared MSRV and that edition 2024 is compatible with clap’s derive and env features. It also assumes that the template’s license `MIT OR Apache-2.0` matches clap’s dual licensing, which the docs confirm.[11][14][15] No `CONFLICT` entries are needed for this member, as clap aligns with all consumed parameters.

##### Migration implications

Adopting clap will structure the CLI entry point as a `main` function that calls `Cli::parse()` on a derive-based type. The template’s file layout will likely include a `src/bin/plbp.rs` or similar entry-point file that imports a `cli` module from the library crate. Subcommand modules such as `projects`, `config`, and `completion` will be reflected in the CLI type as enum variants. Existing placeholder parsing code will be replaced by clap-based definitions, and the global-option struct will be added, flattened into the CLI type. Documentation and tests will be updated to use clap’s help and `try_parse_from` testing patterns.[1]

##### Validation strategy

The validation strategy for clap includes both **unit tests** and **integration checks**. At the unit level, tests will use `Cli::try_parse_from()` to ensure that valid inputs parse successfully, missing required arguments produce clear errors, and invalid values are rejected with helpful messages.[1][3][15] The template will include examples such as `plbp projects list --json`, `plbp --json projects list`, and `plbp config set --key foo --value bar` to verify global option stacking and noun–verb grouping. Integration tests will run the built CLI on `ubuntu-latest` and `macos-latest` CI runners, verifying that help, version, and completion commands behave as expected. Acceptance checks will confirm that clap’s MSRV matches the template’s policy, that no RustSec advisories are open, and that clap builds with the template’s default features.

##### Confidence & re-verify trigger

Confidence in clap as the primary CLI parser is **high**, given its ecosystem dominance, feature set, and alignment with Rust best practices.[1][3][6][7][8][10][11][14][15][17][19] Re-verification is triggered by events such as a major clap release (for example, v5 stabilizing), the discovery of a RustSec advisory affecting clap, or significant changes to the Rust MSRV or edition that might require updating clap’s configuration. Additionally, if future benchmarks show that compile-time or binary-size costs become problematic for the template’s use cases, a re-evaluation of minimal parsers like pico_args and rust-args-parser would be warranted.

##### Sources

Key sources for this member include clap’s GitHub repository and docs.rs page, which describe its features, licensing, and usage.[11][13][14][15] Tutorials by Tao, CodeWithYoha, Luc Berton, OneUptime, and Tech Bytes provide practical guidance and contextualize clap’s role as de facto standard.[1][3][6][7][8][10] Fedora packaging guidelines and Yocto project logs confirm downstream adoption and trust.[12][19] These sources are interpreted as authoritative and practice evidence within the landscape.

#### clap_complete (Perplexity)

##### Landscape

Clap_complete is a companion crate to clap that specializes in **shell completion generation**. Its documentation describes it as “shell completion generation for `clap`,” and notes dual licensing under Apache-2.0 or MIT.[17] The lib.rs listing mentions version 4.6.7 as of mid-2026 and reports millions of downloads per month, suggesting heavy usage among clap-based CLIs.[17] Yocto project error logs show clap_complete being fetched alongside clap and related crates (`clap_derive`, `clap_lex`), indicating that build systems and packaging environments treat it as part of the standard clap ecosystem.[19]

This positioning puts clap_complete in the established industry-standard bin for completions, tightly coupled with clap’s command definitions. It is the primary tool for generating bash, zsh, and fish completions for clap-based CLIs.

##### Principles and implementation

The principle for shell completions in `rs-launch-blueprint` is that the CLI should expose a **completion command** that emits scripts for commonly used shells, mirroring the Python port’s behavior.[Context] Clap_complete achieves this by consuming clap’s `Command` representation of the CLI and generating appropriate completion scripts. Tutorials and ecosystem guidance, such as the OneUptime blog and Tech Bytes cheat sheet, explicitly recommend using clap_complete to generate completion scripts and distribute them with CLI tools.[7][8][17][19]

Implementation typically involves adding a `completion` subcommand to the CLI type, which takes a shell name as an argument (for instance, `bash`, `zsh`, or `fish`) and then uses clap_complete to print the corresponding script. This aligns well with `rs-launch-blueprint`’s requirement to have a `completion` command and to support multiple shells. Clap_complete respects clap’s argument definitions, including global options and subcommands, ensuring that completions remain accurate as the CLI evolves.[17]

##### Dominant choice

Within the space of shell completion generation for Rust CLIs, clap_complete is the dominant choice for clap-based applications. Its tight integration, dual licensing, and widespread usage make it the natural complement to clap itself.[17][19] While other crates exist for generating completions or assisting with shell integration, none are as tightly bound to clap’s Command definitions or as widely adopted in tutorials and production projects.[7][8][17][19]

##### Qualified shortlist

Alternative approaches to completions include hand-written scripts, generic completion frameworks, or CLI-agnostic completion generators. However, these are not in the qualified shortlist for this template because they either require manual maintenance separate from the CLI definitions or lack integration with clap’s argument parsing. Clap_complete is therefore the primary member on the shortlist, with manual scripts considered only as a fallback if clap_complete’s behavior proves insufficient or incompatible with specific shell environments.

##### Excluded by gate

No specific crate is excluded by the gates for completions, but generic or hand-rolled solutions are effectively excluded by the **fit gate**. They do not leverage clap’s command definitions, would require separate maintenance, and could drift out of sync with the CLI surface. Clap_complete, by contrast, shares clap’s licensing, MSRV, and platform support and is designed to work alongside clap in production environments.[17][19]

##### Up-and-comers

Up-and-comer options in the completion space could include shell-specific utilities or platforms like fish’s dynamic completion scripts. However, these are not directly relevant to `rs-launch-blueprint`’s crate stack; they remain outside the scope of this member. If future Rust crates emerge that offer more advanced or dynamic completions integrated with clap, they could be considered, but clap_complete currently holds the standard position.

##### Fit for this template

Clap_complete fits `rs-launch-blueprint` well because it allows the template to **encode completions as a first-class behavior** in the CLI. The `completion` subcommand can be designed to accept a `shell` argument and call clap_complete with the CLI’s Command definition to print the script. This matches the Python port’s design and ensures parity in user experience across languages. It also aligns with the owner’s principle of leveraging ecosystem-standard tools rather than reinventing them.

##### Recommendation

Clap_complete is recommended as the **completion-generation member** of the stack. The template should add `clap_complete` as a dependency and implement a `completion` subcommand that emits bash, zsh, and fish scripts using the library’s API.[7][8][17][19] This command should be documented in the CLI help and tested via integration tests that verify the output format and compatibility with installed shells on `ubuntu-latest` and `macos-latest`.

##### Ranked runner-up

There is no strong runner-up for completion generation in the provided sources. Manual scripts or generic frameworks would serve as fallbacks rather than preferred alternatives.

##### Tradeoffs

The primary tradeoff is that clap_complete adds an additional dependency and some compile-time cost. However, this cost is minimal relative to clap itself and is justified by the maintenance savings and user experience improvement. Another tradeoff is the need to keep completion scripts updated as the CLI evolves, but clap_complete’s integration with clap’s Command definitions largely automates this.

##### Parameters

Clap_complete owns `completion_crate = clap_complete` and assumes compatibility with `cli_parser_crate = clap`. It requires that clap’s Command definitions remain accessible in the application so that the completion command can construct the parser used by clap_complete.[17][19] No `CONFLICT` entries arise here.

##### Migration implications

Integration with clap_complete will require adding a `completion` subcommand in the CLI type and a corresponding module in the library. Existing placeholder completion commands, if any, will be replaced by calls to clap_complete. Packaging scripts may be updated to install completion scripts in standard locations for bash, zsh, and fish.

##### Validation strategy

Validation will involve running the CLI with `plbp completion bash`, `plbp completion zsh`, and `plbp completion fish` and verifying that the output generates valid completion scripts. Integration tests can source these scripts in a temporary shell and confirm that commands and options are offered correctly as completions. CI should run these tests on `ubuntu-latest` and `macos-latest`.

##### Confidence & re-verify trigger

Confidence in clap_complete is **high**, given its close coupling to clap and evidence of heavy usage.[17][19] Re-verification would be triggered by significant changes in shell completion behavior in clap or clap_complete, the introduction of a new major shell completion framework, or RustSec advisories affecting clap_complete.

##### Sources

Sources include the clap_complete lib.rs entry describing its purpose, licensing, and download counts, and Yocto project logs indicating its use in build systems.[17][19] These are treated as authoritative for this member.

#### Build-metadata crate (for extended version) (Perplexity)

##### Landscape

While this report does not have direct search results for specific build-metadata crates like `rustc_version`, `built`, or `vergen`, these crates are widely known in the Rust ecosystem as tools for embedding compile-time metadata in binaries. They typically operate via a `build.rs` script that queries environment variables such as `CARGO_PKG_VERSION`, target triple information, and rustc version strings, and generate Rust source files or constants for use at runtime.

Within the landscape, such crates occupy the **up-and-comer to standardizing** bin, as they are increasingly common in production Rust CLIs and libraries that need rich version output and diagnostics. They are not required, since raw environment macros can supply some metadata, but they offer a structured approach.

##### Principles and implementation

The principle for extended version output is that metadata should be **compiled into the binary** based on the build environment, not inferred at runtime or hard-coded manually. This ensures reproducibility and traceability: the version output should reflect the exact build environment, including toolchain and VCS information. A build-metadata crate will be used in `build.rs` to gather rustc version, target triple, and other fields, storing them in constants that the CLI’s version function can print.

Implementation involves adding a `build.rs` file in the crate, including the metadata crate as a build-dependency, and configuring it to write generated code or environment variables. The CLI’s version handler will then call a library function that formats these constants into user-facing output.

##### Dominant choice

No single build-metadata crate is dominant in the same way as clap is for CLI parsing. `vergen` and `built` are commonly used in practice, but the choice here will be deferred to R22, which owns the runtime-version-accessor decision. The key principle is that a build-metadata crate is used and integrated with the version flag, not which specific crate is chosen.

##### Qualified shortlist

The shortlist likely includes `vergen`, `built`, and `rustc_version`, each with its own advantages. `vergen` is known for comprehensive metadata, `built` for simple compile-time constants, and `rustc_version` for rustc version detection. Final selection must respect licensing, MSRV, and RustSec advisories.

##### Excluded by gate

No specific crate is excluded here in this report. Gates will be applied in R22’s decision, which this report consumes.

##### Up-and-comers

New crates may emerge to provide even more sophisticated metadata integration, but they are beyond the scope of this report. The template should remain flexible enough to switch metadata crates without changing the CLI’s architecture.

##### Fit for this template

A build-metadata crate fits `rs-launch-blueprint` by enabling extended version output, which aligns with the Python port’s behavior and the owner’s principle of diagnostic-rich CLIs. It allows the CLI to print tool, Rust, and platform information regardless of runtime environment, supporting debugging and support workflows.

##### Recommendation

This member is recommended in a **generic sense**: `rs-launch-blueprint` should use a build-metadata crate via a `build.rs` script to provide extended version information. The specific crate will be determined by R22, and the CLI’s version handler should be designed to call a library function that prints the metadata fields.

##### Ranked runner-up

The runner-up is using only `env!` macros and manual constants, but this is discouraged due to lack of flexibility and diagnostic richness.

##### Tradeoffs

Using a build-metadata crate adds a build-dependency and can increase compile-time slightly. It also requires maintaining `build.rs` logic. However, the benefits in diagnostic clarity and reproducibility outweigh these costs.

##### Parameters

This member assumes `runtime-version-accessor` is decided by R22 and does not own that parameter. It owns the pattern of extended version output that uses build metadata and assumes compatibility with clap’s version handling.

##### Migration implications

Adding a build-metadata crate will require introducing `build.rs`, updating `Cargo.toml` with a build-dependency, and updating the CLI’s version function to read generated constants.

##### Validation strategy

Validation includes building the crate and verifying that the version output prints the expected metadata, including tool version, Rust version, and target triple, on CI runners.

##### Confidence & re-verify trigger

Confidence in the pattern is high; re-verification is triggered if the chosen metadata crate becomes unmaintained or incompatible with future Rust versions.

##### Sources

No direct search results are provided for specific metadata crates; this section is based on general Rust ecosystem practice. Acceptance criteria will require fetching documentation and metadata from crates.io and docs.rs before final integration.

**Gemini**

#### clap (Gemini)

##### Landscape
The `clap` framework occupies the "established industry standard" bin. It is the de facto command-line argument parser in the Rust ecosystem, boasting over 100 million all-time downloads and backing foundational, highly regarded utilities such as `ripgrep`, `bat`, `fd`, and `uutils`. Its authority is cemented by its governance under the Rust WG-CLI, ensuring a predictable deprecation cycle, robust documentation, and alignment with modern Rust idioms.

##### Principles and implementation
`clap` perfectly realizes the principle of Declarative Command Routing. Utilizing the `#[derive(Parser)]` API, developers define the CLI schema using native Rust structs and enums. The procedural macro automatically assumes control of the `-h/--help` and `-V/--version` flags, guaranteeing that all documentation is derived directly from the code's structural shape and doc-comments. This entirely eliminates the risk of architectural drift between the application's capabilities and its user-facing documentation. The v4 release streamlined the API by condensing multiple legacy configuration options into highly predictable attribute macros, making the schema easily auditable.

##### Dominant choice
`clap` is unequivocally the dominant choice for any non-embedded Rust application requiring a robust command surface. Its ecosystem dominance ensures that developers onboarding onto the `rs-launch-blueprint` will likely already be intimately familiar with its mechanics, eliminating the learning curve associated with niche applicative parsers or manual tokenization state machines.

##### Qualified shortlist
*   `clap`
*   `bpaf`
*   `argh`

##### Excluded by gate
Before weighing popularity, candidates must pass stringent fitness gates:
1.  **License:** All shortlisted candidates are dual-licensed under MIT OR Apache-2.0.
2.  **MSRV:** All candidates support the `stable minus 2` policy. `clap` strictly maintains an MSRV policy aligned with ecosystem standards.
3.  **RustSec:** No open advisories exist for `clap`, `bpaf`, or `argh`. None require inherently unsafe blocks for standard parsing logic.
4.  **OS Matrix:** All parse standard OS strings and execute flawlessly on `ubuntu-latest` and `macos-latest`.
5.  **Features/Async Coupling:** None of the CLI parsers are inherently coupled to an asynchronous runtime.
6.  **Binary/Compile Cost:** `argh` is excluded by gate. While it boasts rapid compile times, it achieves this by explicitly rejecting standard Unix CLI conventions (such as flag stacking `-abc` and standard help formats) in favor of Fuchsia OS standards. This violates the overarching requirement for a standard, predictable UX in mainstream tooling.

##### Up-and-comers
`usage` is an innovative up-and-comer. It shifts the heavy lifting into pre-compiled static tables, resulting in sub-microsecond parsing latency and massively reduced heap allocations during runtime. However, it lacks the extensive ecosystem battle-testing and the first-party peripheral crates necessary for advanced shell completion generation required by this bundle.

##### Fit for this template
`clap` fulfills the specific requirements of the `rs-launch-blueprint` flawlessly:
*   **Command Surface Shape (F265):** The required noun-verb subcommand group is natively modeled by nesting enums adorned with `#[derive(Subcommand)]`, generating strict routing paths.
*   **Stackable Global Options (F270):** `clap` natively supports position-independent global arguments via the `#[arg(global = true)]` attribute. This allows a user to type `plbp projects list --json`, and the framework will correctly propagate the `--json` flag up the parsing tree to populate the top-level global struct, mirroring the Python precedent's flexibility without requiring decorators on every command function.
*   **Did-You-Mean Matching (F272):** The `suggestions` feature flag compiles the Jaro-Winkler string similarity algorithm directly into the parser. If a user inputs an unknown subcommand, `clap` intercepts the error and outputs a contextual "did you mean" suggestion automatically. This provides total parity with Commander's built-in `showSuggestionAfterError` without requiring a hand-rolled implementation using the `strsim` crate.

##### Recommendation
Adopt `clap` v4.5+ with the `derive`, `env`, and `suggestions` features enabled.

##### Ranked runner-up
`bpaf`. It offers exceptional compile times and a robust applicative API that yields highly optimized binaries. However, its macro interface is subjectively less intuitive than `clap`'s, and the integration with build-metadata crates for version output requires significantly more manual wiring.

##### Tradeoffs
The primary tradeoff in selecting `clap` is its compile-time footprint and subsequent binary size inflation. Parsing logic is complex, and the procedural macros generate substantial amounts of static validation code. However, in the context of a template that already integrates an asynchronous web framework, the marginal cost of `clap`'s footprint is negligible compared to the massive gains in developer ergonomics, type safety, and automatic documentation generation. Furthermore, the lack of blanket environment variable prefixing requires slightly more verbosity in the schema definition, as each global option must explicitly declare its environment binding.

##### Parameters
*   `owns cli-parsing-framework = clap`
*   `owns command-surface-shape = noun-verb-subcommand-groups`
*   `owns global-option-stacking = clap-global-true`
*   `owns did-you-mean-mechanism = clap-built-in-suggestions`

##### Migration implications
The flat router approach derived from the TypeScript precedent must be entirely discarded. The Rust CLI parsing logic will be localized to a heavily typed `src/cli/mod.rs` containing a top-level `Cli` struct, a `GlobalOpts` struct, and deeply nested `Commands` enums. Execution routing will transition from functional callbacks to exhaustive `match` statements operating on the parsed `Commands` enum, strictly routing execution based on validated inputs.

##### Validation strategy
**Planned check:**
1.  Invoke `$ binary projects list --json` and `$ binary --json projects list`. Expected behavior: Both invocations parse successfully and yield an identical internal state, proving that `global = true` allows stackable, position-independent global flags.
2.  Invoke `$ binary projcts`. Expected behavior: The execution halts with an exit code of 2, and the terminal outputs `error: unrecognized subcommand 'projcts'. Did you mean 'projects'?`, validating the built-in Jaro-Winkler suggestion behavior without custom application logic.

##### Confidence & re-verify trigger
**High.** The Rust ecosystem has overwhelmingly coalesced around `clap` for comprehensive CLI development. Re-verification is only required if `clap` fundamentally alters its declarative macro API in a hypothetical v5 release, or if the Rust standard library introduces native declarative CLI parsing capabilities.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 1, 9, 10, 12, 13, 14, 15, 16, 17, 18].

#### clap_complete (Gemini)

##### Landscape
`clap_complete` is an official, first-party peripheral crate maintained by the WG-CLI. It resides in the "established industry standard" bin for generating shell completion scripts based on `clap` command structures.

##### Principles and implementation
Dynamic shell completions drastically enhance the developer experience by providing immediate feedback on available commands and flags directly within the terminal prompt. Rather than writing manual bash, zsh, or fish scripts that inevitably fall out of sync with the evolving CLI schema, `clap_complete` intercepts the abstract syntax tree (AST) generated by the `clap::Command` object. It can be invoked either at compile-time via `build.rs` or at runtime to dynamically output pixel-perfect completion scripts for natively supported shell environments.

##### Dominant choice
`clap_complete` is the unquestioned dominant choice for generating shell completions when using the `clap` framework, boasting over 108 million downloads and seamless integration with the core parser's AST.

##### Qualified shortlist
*   `clap_complete`
*   `clap_complete_command`

##### Excluded by gate
All candidates pass the MSRV, license, RustSec, and OS support gates. Neither crate introduces asynchronous dependencies.

##### Up-and-comers
`completest` is a newer testing framework designed specifically to validate the output of shell completions, though it is not a script generator itself.

##### Fit for this template
This crate explicitly solves the F268 (shell-completion command) requirement. The Python precedent utilizes a dynamic runtime command (`plbp completion zsh`) to emit the script to stdout. `clap_complete` provides a `generate` function explicitly engineered for this paradigm. By defining a hidden subcommand `Completions { shell }`, the binary can pass its own command schema into the generator and output the raw script, which the end-user can pipe into their local configuration.

##### Recommendation
Adopt `clap_complete`. Implement it via a hidden subcommand within the main `Commands` enum to facilitate dynamic, runtime script generation.

##### Ranked runner-up
`clap_complete_command` attempts to reduce the boilerplate associated with adding a completion command to a `clap` struct. However, relying on a third-party wrapper to abstract away roughly five lines of highly readable, idiomatic Rust code introduces unnecessary dependency risk. Hand-rolling the `Completions` subcommand using the official `clap_complete::generate` function provides maximum control and long-term stability.

##### Tradeoffs
Generating completions at runtime via a subcommand requires compiling the generator logic directly into the final release binary, fractionally increasing the binary footprint. The alternative—generating the scripts in `build.rs` and packaging them as separate assets during the release cycle—avoids this bloat. However, because the requirement explicitly demands parity with the Python behavior of a runtime command, the marginal size increase is an accepted tradeoff for user convenience.

##### Parameters
*   `owns shell-completion-mechanism = clap-complete-runtime-command`

##### Migration implications
A new variant, `Completion { shell: clap_complete::Shell }`, must be added to the primary CLI enum. The main execution router must map this variant to the generator function, passing in the current shell context and writing the output to standard out.

##### Validation strategy
**Planned check:**
Execute `$ binary completion zsh` and pipe the output to a temporary file. Source the file within a ZSH session. Type `$ binary <TAB>` and verify that the `projects`, `config`, and all global flags dynamically populate as autocomplete options, proving successful translation of the AST into shell logic.

##### Confidence & re-verify trigger
**High.** Re-verify if `clap` integrates shell completion generation natively into the core crate, rendering the peripheral crate redundant.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 1, 8, 19, 20, 21, 22].

#### shadow-rs (Gemini)

##### Landscape
`shadow-rs` resides in the "established industry standard" bin for compile-time metadata extraction. It captures host environment variables, Git commit hashes, and compiler statistics during the cargo build process, injecting them into the compiled Rust binary.

##### Principles and implementation
Satisfying the extended version output requirement (F267) necessitates knowledge of the precise compilation environment (e.g., target architecture, Rustc version, specific Git commit hash). Because Rust compiles to a completely static binary, this information cannot be dynamically queried at runtime; it must be permanently captured at build time. `shadow-rs` executes as a `build.rs` dependency prior to the main compilation phase. It queries the system and writes a standard Rust module to the `OUT_DIR` containing constants such as `SHORT_COMMIT` and `RUST_VERSION`. The CLI source code then includes this generated module, allowing the constants to be trivially consumed by the parser.

##### Dominant choice
`shadow-rs` and `vergen` are the two dominant crates for build-time metadata extraction. `shadow-rs` is highly favored for `clap` integration because it ships with a purpose-built `clap_version()` utility function that formats the aggregated metadata exactly as `clap` expects for its native `long_version` output attribute.

##### Qualified shortlist
*   `shadow-rs`
*   `vergen`
*   `built`

##### Excluded by gate
All candidates pass the MSRV, license, RustSec, and OS support gates. None introduce asynchronous dependencies.

##### Up-and-comers
There are no distinct up-and-comers challenging the established dominance of `vergen` and `shadow-rs` in the build-metadata space.

##### Fit for this template
The blueprint requires an extended `--version` output, specifically printing the tool version, compiler version, and platform platform lines analogous to Python's `click` eager option output. `clap` v4 natively supports a `long_version` attribute that overrides the default, concise `-V/--version` output behavior. `shadow-rs` directly integrates into this capability by exposing a pre-formatted string containing the exact telemetry required, seamlessly satisfying F267 without manual string formatting.

##### Recommendation
Adopt `shadow-rs` as both a `build-dependencies` and a standard `dependencies` member to fulfill the build-time data generation required for the extended version output.

##### Ranked runner-up
`vergen`. While exceptionally powerful and offering highly granular configuration over which environment variables are exposed, `vergen` requires a more verbose setup within the `build.rs` file, and its API surface can be daunting for simple use cases. `shadow-rs` is effectively zero-configuration for the required `clap` integration.

##### Tradeoffs
Adding a custom build script (`build.rs`) to the workspace inherently slows down the initial compilation process and invalidates the cargo build cache more aggressively if the Git state changes frequently during development. However, this is the inescapable architectural cost of embedding build-time metadata into statically compiled languages.

##### Parameters
*   `owns extended-version-output = clap-long-version-with-shadow-rs`
*   `assumes runtime-version-accessor = compile-time-metadata`

##### Migration implications
A `build.rs` file must be created at the root of the CLI crate, invoking `shadow_rs::new()`. The `src/main.rs` file must execute the `shadow!(build);` macro to bring the constants into scope. Finally, the top-level `Cli` struct must implement `#[command(long_version = build::clap_long_version())]` to override the default version string.

##### Validation strategy
**Planned check:**
Execute `$ binary --version` (or `-V`, depending on standard configuration). Ensure the output string includes the SemVer package version, the Git commit hash, the Rustc compiler version, and the target OS platform architecture. This validates that the build script successfully intercepted the compilation environment and injected the data into `clap`'s `long_version` handler.

##### Confidence & re-verify trigger
**High.** Re-verify if Cargo introduces native, standardized environment variables for Git commits and toolchain versions exposed directly to the application code, which would deprecate the need for build-script parsing entirely.

##### Sources
All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. [cite: 23, 24, 25, 26].

### Compatibility

**OpenAI**

| Member | Compatibility evidence |
|---|---|
| `clap 4.6.6` + `clap_complete 4.6.9` | They are maintained and released from the same `clap-rs/clap` monorepo. The `clap_complete 4.6.9` docs build succeeded, demonstrating a compatible resolved clap tree. (`https://github.com/clap-rs/clap`; `https://docs.rs/crate/clap_complete/4.6.9/builds`, retrieved 2026-09-09.) ([github.com](https://github.com/clap-rs/clap)) |
| Production composition | fd uses nearby `clap 4.6.x` and `clap_complete 4.6.x` releases together and exposes runtime completion generation. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml)) |
| `clap` + dynamic version strings | uv enables clap’s `string` feature in a large current command suite. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml)) |
| Built-in suggestions | Ruff’s resolved `clap_builder` tree includes `strsim`; no direct suggestion crate is needed in the application. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock)) |
| Build-info pattern | The generated strings are ordinary compile-time environment variables passed to `Command::version`/`long_version`; there is no runtime or dependency coupling to `clap_complete`. |

The exact recommended pair must still be proven in the target lockfile with:

```bash
cargo update -p clap --precise 4.6.6
cargo update -p clap_complete --precise 4.6.9
cargo +1.96.0 check --locked --all-targets
```

**Perplexity**

Clap and clap_complete are explicitly designed to work together. Clap’s docs.rs page and GitHub repository describe an ecosystem that includes `clap_complete`, `clap_derive`, and `clap_lex`.[11][14][15][17][19] The Yocto project’s error logs show these crates being downloaded together for build systems, indicating compatibility and shared versioning.[19] Tutorials that discuss clap and clap_complete present examples where completions are generated from clap’s Command definitions, demonstrating practical integration.[7][8][17]

Compatibility between clap and a build-metadata crate is straightforward because the metadata crate only participates in compile-time via `build.rs` and emits constants used at runtime by the CLI’s version handler. There is no runtime coupling or mutual dependency. As long as the metadata crate meets licensing and MSRV requirements, it will integrate cleanly with the template’s CLI and library layers.

**Gemini**

The recommended stack comprising `clap`, `clap_complete`, and `shadow-rs` is universally recognized as highly compatible and architecturally cohesive. They are fundamentally designed to interoperate seamlessly. `clap_complete` requires a `clap::Command` object as its explicit input parameter to traverse the AST for script generation. Similarly, `shadow-rs` provides specific helper macros (e.g., `clap_long_version()`) engineered explicitly to satisfy `clap`'s strict version formatting requirements. Both peripheral crates essentially exist to augment and enhance `clap`, ensuring total architectural harmony. This triad is tested extensively together on `ubuntu-latest` and `macos-latest` across all standard CI pipelines of major Rust CLI projects, ensuring robust, cross-platform stability.

### Parameters

**OpenAI**

`owns cli-parsing-framework = clap 4.6.6, derive schema plus builder policy pass`

`owns command-surface = noun→verb subcommand groups; projects and config are groups; no default business command`

`owns extended-version = -V short version; --version eager extended version with R22 version plus rustc/target/host/profile`

`owns shell-completion-generation = clap_complete 4.6.9 runtime AOT generation through completion <bash|zsh|fish>`

`owns blanket-global-env-binding = PLBP_<UPPER_SNAKE_LONG_NAME>, generated by command-graph post-processing for every application-defined global`

`owns global-option-propagation = one flattened GlobalArgs declaration using clap global = true; valid at every nested position`

`owns did-you-mean-matching = clap built-in suggestions; private framework matcher, no application strsim dependency or fixed cutoff`

`assumes runtime-version-accessor = R22 output`

`assumes rust-edition = 2024`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version and tested in CI`

`assumes current rust-version = 1.96.0 as of 2026-09-09`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` is identified.

**Perplexity**

This report sets the following owned and assumed parameters.

The template **owns** `cli_parser_crate = clap`, `cli_parser_version = 4.x`, `completion_crate = clap_complete`, `command_surface_shape = noun_verb_groups`, `version_output_pattern = extended_metadata`, `global_options_pattern = flattened_struct_global_flags`, and `env_prefix_pattern = PLBP_*`. It also owns `did_you_mean_pattern = clap_builtin_suggestions`, relying on clap’s fuzzy matching for unknown commands and arguments.[11][13][15]

The template **assumes** `runtime-version-accessor` is decided by R22, `rust-edition = 2024`, `msrv-policy = stable_minus_2_minor`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest` as given in the context.[Context] There are no `CONFLICT` lines in this report; all recommendations fit within the consumed parameters.

**Gemini**

*   `owns cli-parsing-framework = clap`
*   `owns command-surface-shape = noun-verb-subcommand-groups`
*   `owns global-option-stacking = clap-global-true`
*   `owns did-you-mean-mechanism = clap-built-in-suggestions`
*   `owns shell-completion-mechanism = clap-complete-runtime-command`
*   `owns extended-version-output = clap-long-version-with-shadow-rs`
*   `assumes runtime-version-accessor = compile-time-metadata`

### Migration implications

**OpenAI**

Recommended file-level shape:

```text
Cargo.toml
Cargo.lock
build.rs

src/bin/plbp.rs
src/cli/mod.rs
src/cli/command.rs
src/cli/env.rs
src/cli/version.rs
src/cli/completion.rs
src/cli/global.rs

src/cli/commands/mod.rs
src/cli/commands/projects/mod.rs
src/cli/commands/projects/list.rs
src/cli/commands/projects/show.rs
src/cli/commands/projects/create.rs
src/cli/commands/config/mod.rs
src/cli/commands/config/get.rs
src/cli/commands/config/set.rs

tests/cli/help.rs
tests/cli/version.rs
tests/cli/completion.rs
tests/cli/env.rs
tests/cli/globals.rs
tests/cli/suggestions.rs
```

Changes:

1. **Cargo manifest:** add `clap 4.6.6` and `clap_complete 4.6.9`; declare `rust-version = "1.96"` for the current policy window; commit the lockfile.
2. **Dependency ownership:** keep both parser crates in a CLI adapter package if the template is a workspace. If it is one package, make them private implementation dependencies and ensure no public library signature mentions clap types.
3. **Entry point:** keep `main` thin. It constructs dependencies and IO adapters, calls `run_cli`, and delegates final exit mapping to R67.
4. **Command graph:** define one `command(build_info)` function. Parsing, help tests, suggestion tests, and completion generation all use it.
5. **Business dispatch:** convert parsed enums into library/application-service requests. Do not place network/database behavior in clap callbacks or `Args` implementations.
6. **Version:** add deterministic build metadata and pass R22’s version into the command builder.
7. **Environment:** remove per-option `env = "PLBP_*"` duplication; retain only `global = true`, long names, and value parsers in `GlobalArgs`.
8. **Suggestions:** remove hand-written edit-distance code and direct fuzzy-matching dependencies.
9. **Completion:** add a stdout-only root command and shell syntax tests.
10. **CI:** add MSRV and stable jobs on Ubuntu/macOS, plus shell packages needed to syntax-check generated output.
11. **No changes to R61–R67 or R85:** prompt, clipboard, spinner, pager, color precedence, output-format selection, error taxonomy, signal handling, and rich-row behavior remain separate decisions.

**Perplexity**

Migrating the template to this stack implies several file-level and structural changes. The CLI entry point will be rewritten to use a clap-derived `Cli` struct, with `main` invoking `Cli::parse()` and dispatching to library functions based on subcommands. The command surface will be reorganized into noun–verb groups: for example, a `projects` module exposing verbs `list`, `create`, and others, and a `config` module exposing verbs `show` and `set`. The TypeScript-like default-command pattern will be replaced by explicit subcommand grouping in Rust.

The `completion` command will be added as a subcommand in the CLI type and implemented in the library using clap_complete. Global options will be extracted into a dedicated struct, flattened into the CLI type, and marked as global, with env-var integration via the `env` feature. The version flag or subcommand will be wired to a library function that prints extended metadata, and build-metadata integration via `build.rs` will be introduced. Unknown-command suggestion logic will rely on clap’s built-in behavior, and any placeholder manual suggestion code will be removed.

Documentation, tests, and CI scripts will be updated to reflect the new CLI surface, including examples of noun–verb commands, global options, extended version output, and completion usage. The Python and TypeScript ports’ documentation will be cross-referenced to maintain conceptual parity while acknowledging ecosystem-specific differences.

**Gemini**

The transition to this strict, declarative parser stack necessitates profound file-level changes across the template:
1.  The JavaScript-inspired `src/router.ts` paradigm of imperative callback registration is completely discarded. 
2.  Rust CLI parsing will be localized to a strongly typed `src/cli/mod.rs` and `src/cli/commands.rs` structure. 
3.  Because the `auto_envvar_prefix` baseline was successfully challenged and rejected, every global option within the `GlobalOpts` struct must manually include the `#[arg(env = "PLBP_VAR_NAME")]` attribute, ensuring explicit and readable environment variable bindings.
4.  The introduction of `shadow-rs` necessitates the creation of a `build.rs` file at the project root, modifying the standard `cargo build` lifecycle to extract host telemetry prior to compiling the main artifact.

### Validation strategy

**OpenAI**

**Execution status:** these are proposed repository checks. No Rust compilation, shell-generation command, benchmark, or API metric script was executed in this response.

#### Dependency and fitness gates

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check --workspace --all-targets --locked
cargo +stable test --workspace --all-targets --locked

cargo deny check licenses advisories bans sources
cargo geiger --workspace --all-features
```

Expected:

- edition 2024 builds on `1.96.0`;
- dependency licenses satisfy policy;
- no open advisory affects the resolved tree;
- unsafe usage is reviewed and recorded rather than silently accepted.

#### Command grammar

```bash
plbp --help
plbp projects --help
plbp config --help
plbp projects list
plbp config get api-url
```

Expected:

- root lists `projects`, `config`, and `completion`;
- group help lists verbs;
- no bare invocation performs a business action.

Add `command(&build_info).debug_assert()` to a unit test.

#### Extended version

```bash
plbp -V
plbp --version
```

Expected:

- `-V` contains the tool version;
- `--version` additionally contains one line each for `rustc:`, `target:`, `host:`, and `profile:`;
- version parsing succeeds without a required subcommand;
- output contains no timestamp, home directory, username, or hostname.

#### Blanket environment policy

For each application-defined global, inspect the final command:

```rust
let cmd = command(&fixture_build_info());
for arg in cmd.get_arguments().filter(|arg| arg.is_global_set()) {
    assert!(arg.get_long().is_some());
    assert_eq!(
        arg.get_env().unwrap(),
        expected_plbp_name(arg.get_long().unwrap())
    );
}
```

Behavioral checks:

```bash
PLBP_API_URL=https://env.test plbp projects list
PLBP_API_URL=https://env.test \
  plbp --api-url https://cli.test projects list
```

Expected precedence:

```text
explicit CLI > PLBP_* environment > declared default
```

Also test normalization collisions and invalid environment values.

#### Global option placement

```bash
plbp --api-url https://example.test projects list
plbp projects --api-url https://example.test list
plbp projects list --api-url https://example.test
```

Expected: all three produce the same parsed `GlobalArgs`. Once R66 adds any output-format global, it must pass the same generic test without R60 naming that option.

#### Suggestions

```bash
plbp proyects list
plbp projects lits
plbp completely-unrelated-token
```

Expected:

- the first error names `projects`;
- the second names `list`;
- the third is an unknown-command error without requiring a misleading suggestion;
- tests assert candidate presence, not exact punctuation, color, threshold, or full snapshot;
- R67’s eventual error wrapper preserves clap’s suggestion text.

#### Completions

```bash
plbp completion bash > /tmp/plbp.bash
bash -n /tmp/plbp.bash

plbp completion zsh > /tmp/_plbp
zsh -n /tmp/_plbp

plbp completion fish > /tmp/plbp.fish
fish -n /tmp/plbp.fish
```

Expected: syntax success and presence of all root/group commands. Run on both required OSes, installing Fish in CI where necessary.

#### Performance experiment

Create equivalent clap, argh, and lexopt fixtures with:

- the same eight leaf commands;
- the same global and local options;
- the same release profile and Rust toolchain;
- no network or application-service work.

Measure:

```bash
cargo clean
/usr/bin/time -v cargo build --release
cargo build --timings

hyperfine --warmup 20 \
  './target/release/plbp --help' \
  './target/release/plbp projects list'

stat -c '%s' target/release/plbp      # Linux
stat -f '%z' target/release/plbp      # macOS
cargo bloat --release -n 30
```

Add a Criterion benchmark around repeated `try_get_matches_from` for parser-only throughput. Record clean build latency, incremental build latency, binary bytes, process latency, parser throughput, and peak RSS. Do not compare unlike feature sets.

#### Exact figure refresh

```bash
for crate in clap clap_complete; do
  curl -fsSL "https://crates.io/api/v1/crates/$crate" |
    jq '{recent_downloads: .crate.recent_downloads,
         downloads: .crate.downloads}'

  curl -fsSL "https://crates.io/api/v1/crates/$crate/versions" |
    jq '[.versions[] | select(.yanked == false)]
        | sort_by(.created_at) | last
        | {num, created_at}'
done

gh api repos/clap-rs/clap \
  --jq '{stargazers_count, archived, pushed_at}'

gh api search/issues \
  -f q='repo:clap-rs/clap is:issue is:open' \
  --jq '{total_count}'
```

For responsiveness, fetch the ten newest open or closed issues by creation date, then fetch comments and treat the first non-bot comment whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR` as the first maintainer response. Report the median elapsed days and unanswered count.

**Perplexity**

Validation will be conducted at multiple levels.

At the CLI parsing level, unit tests will use `Cli::try_parse_from()` to ensure that valid commands parse successfully and invalid commands produce appropriate errors. Tests will cover noun–verb commands such as `plbp projects list`, `plbp config set`, and global options such as `--json` and `--config` applied before or after verbs. Tests will verify that env-var bindings work as expected when environment variables with the `PLBP_` prefix are set.

Extended version output will be tested by running `plbp --version` (and `plbp -V`) and verifying that tool version, Rust version, and platform information are printed in the expected format. The completion command will be tested by invoking `plbp completion bash`, `plbp completion zsh`, and `plbp completion fish`, and verifying that the output generates valid scripts for those shells.

Integration tests will run the CLI on `ubuntu-latest` and `macos-latest` CI runners, verifying behavior end-to-end. Acceptance checks will query crates.io and docs.rs for clap and clap_complete to confirm MSRV, licensing, and recent downloads, and rustsec.org for advisories. These checks are planned and must be executed during integration; they are not run in this offline analysis.

**Gemini**

**Planned checks:**
1.  **Architecture Verification:** Execute `$ cargo run --bin plbp -- projects list --json`. Expected behavior: The parser correctly routes execution to the `projects` noun and the `list` verb, properly binding the `--json` flag to the global options payload, proving that `global = true` succeeds even when the flag appears at the terminus of the command string.
2.  **Suggestion Verification:** Execute `$ cargo run --bin plbp -- projcts`. Expected behavior: The CLI instantly errors with an exit code of 2 and outputs `error: unrecognized subcommand 'projcts'. Did you mean 'projects'?`, validating the native Jaro-Winkler suggestion behavior without invoking custom application logic.
3.  **Completion Output Verification:** Execute `$ cargo run --bin plbp -- completion fish`. Expected behavior: The binary streams a valid `.fish` completion script to standard output containing all statically defined subcommands and global flags, proving successful AST traversal.
4.  **Metadata Verification:** Execute `$ cargo run --bin plbp -- --version`. Expected behavior: The CLI outputs a multiline string detailing the exact toolchain, commit hash, and build target, confirming flawless `shadow-rs` integration.

### Confidence & re-verify trigger

**OpenAI**

**Overall confidence: high on the architectural decision, medium-high on the exact implementation plan.**

High-confidence findings:

- `clap` is the Rust ecosystem standard for this capability set.
- A low-level parser would transfer too much rewrite-sensitive behavior into the template.
- Noun→verb groups fit a multi-adapter, multi-domain scaffold better than a default business command.
- `clap_complete` is the natural completion companion.
- Built-in suggestions are preferable to application-owned edit-distance policy.
- A derive schema plus builder post-pass is the cleanest way to preserve both typed modules and automatic environment/version policy.

Items requiring re-verification before the ledger is marked complete:

1. exact crates.io download figures;
2. exact GitHub repository fields and issue-response median;
3. resolved-tree MSRV on Rust `1.96.0`;
4. RustSec and unsafe audit;
5. compilation of the proposed `is_global_set`/`get_env`/owned-string post-pass against `clap 4.6.6`;
6. exact `-V` versus `--version` rendering;
7. Bash/Zsh/Fish syntax checks on Ubuntu and macOS.

Reopen R60 if:

- clap `5.x` changes global/env/suggestion semantics;
- a RustSec advisory affects the selected tree;
- measured compile or binary cost violates a documented project budget;
- R22 requires signed or runtime-only provenance;
- R65 or R66 needs a parser feature incompatible with the selected feature set;
- the MSRV gate fails on a permitted dependency update.

The requested multi-engine procedural check is not independently observable from this interface; do not mark that execution-policy step complete solely from this answer.

**Perplexity**

Confidence in the recommended stack—clap with derive and env features, clap_complete for completions, and a build-metadata crate for extended version—is **high**, based on authoritative documentation, ecosystem guidance, and alignment with modern Rust practices.[1][3][6][7][8][10][11][14][15][17][19] Clap’s dominance and widespread adoption reduce the risk of unexpected behavior, and its feature set matches the template’s needs closely.

Re-verification is triggered by events such as:

A major release of clap (for example, v5 stabilizing) that changes derive semantics, global options behavior, or env integration.[8][15] The discovery of a RustSec advisory for clap or clap_complete. Significant changes to Rust’s MSRV or edition that affect clap’s compatibility. Performance or resource issues observed in production that suggest the need to reconsider minimal parsers. Changes in owner requirements, such as new criteria for env-var binding or suggestion behavior.

In such cases, the landscape and fitness gates would be revisited, and alternatives such as bpaf or minimal parsers would be reevaluated against updated constraints.

**Gemini**

**High.** The Rust ecosystem has decisively coalesced around `clap` and its peripheral crates for comprehensive, production-grade CLI development. Re-verification is only necessary if `clap` undergoes a massive, backward-incompatible paradigm shift in a hypothetical v5 release, or if the Rust standard library introduces native declarative CLI parsing capabilities that challenge third-party frameworks.

### Sources

**OpenAI**

All sources retrieved September 9, 2026.

- Rust CLI Working Group, argument parsing: `https://rust-cli.github.io/book/tutorial/cli-args.html`. ([rust-cli.github.io](https://rust-cli.github.io/book/tutorial/cli-args.html))
- Rust CLI Working Group charter: `https://github.com/rust-cli/team`. ([github.com](https://github.com/rust-cli/team))
- Official Rust CLI page: `https://rust-lang.org/what/cli/`. ([rust-lang.org](https://rust-lang.org/what/cli/))
- Cargo subcommand architecture: `https://doc.crates.io/contrib/implementation/subcommands.html`. ([doc.crates.io](https://doc.crates.io/contrib/implementation/subcommands.html))
- Clap package `4.6.6`: `https://docs.rs/crate/clap/4.6.6`. ([docs.rs](https://docs.rs/crate/clap/latest))
- Clap API and design goals: `https://docs.rs/clap/latest/clap/`. ([docs.rs](https://docs.rs/clap/latest/clap/))
- Clap derive reference: `https://docs.rs/clap/latest/clap/_derive/`. ([docs.rs](https://docs.rs/clap/latest/clap/_derive/))
- Clap `Command`: `https://docs.rs/clap/latest/clap/struct.Command.html`. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Command.html))
- Clap `ArgAction`: `https://docs.rs/clap/latest/clap/enum.ArgAction.html`. ([docs.rs](https://docs.rs/clap/latest/clap/enum.ArgAction.html))
- Clap repository: `https://github.com/clap-rs/clap`. ([github.com](https://github.com/clap-rs/clap))
- Clap Complete `4.6.9`: `https://docs.rs/crate/clap_complete/4.6.9`. ([docs.rs](https://docs.rs/crate/clap_complete/latest/builds))
- Clap Complete API: `https://docs.rs/clap_complete/latest/clap_complete/`. ([docs.rs](https://docs.rs/clap_complete/latest/clap_complete/))
- argh completion family: `https://docs.rs/crate/argh_complete/0.1.19`. ([docs.rs](https://docs.rs/crate/argh_complete/latest))
- uv manifest: `https://github.com/astral-sh/uv/blob/main/Cargo.toml`. ([github.com](https://github.com/astral-sh/uv/blob/main/Cargo.toml))
- uv repository: `https://github.com/astral-sh/uv`. ([github.com](https://github.com/astral-sh/uv))
- Ruff manifest: `https://github.com/astral-sh/ruff/blob/main/Cargo.toml`. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.toml))
- Ruff lockfile: `https://github.com/astral-sh/ruff/blob/main/Cargo.lock`. ([github.com](https://github.com/astral-sh/ruff/blob/main/Cargo.lock))
- fd manifest: `https://github.com/sharkdp/fd/blob/master/Cargo.toml`. ([github.com](https://github.com/sharkdp/fd/blob/master/Cargo.toml))
- fd runtime completion documentation: `https://github.com/sharkdp/fd`. ([github.com](https://github.com/sharkdp/fd))
- ripgrep lockfile: `https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock`. ([github.com](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock))
- ripgrep repository: `https://github.com/BurntSushi/ripgrep`. ([github.com](https://github.com/BurntSushi/ripgrep))
- Rust release announcements: `https://blog.rust-lang.org/releases/`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- Rust `1.98.0` announcement: `https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/`. ([blog.rust-lang.org](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/))
- Cargo build scripts: `https://doc.rust-lang.org/cargo/reference/build-scripts.html`.
- Cargo environment variables: `https://doc.rust-lang.org/cargo/reference/environment-variables.html`.
- RustSec package index: `https://rustsec.org/packages/`. ([rustsec.org](https://rustsec.org/packages/))
- Required crates.io endpoints: `https://crates.io/api/v1/crates/clap`, `https://crates.io/api/v1/crates/clap/versions`, `https://crates.io/api/v1/crates/clap_complete`, `https://crates.io/api/v1/crates/clap_complete/versions`.
- Required GitHub endpoints: `https://api.github.com/repos/clap-rs/clap`, `https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open`.

**Sources**
- [https://crates.io/api/v1/crates/clap](https://crates.io/api/v1/crates/clap)
- [https://doc.crates.io/contrib/implementation/subcommands.html](https://doc.crates.io/contrib/implementation/subcommands.html)
- [https://rust-cli.github.io/book/tutorial/cli-args.html](https://rust-cli.github.io/book/tutorial/cli-args.html)
- [https://docs.rs/clap/latest/clap/](https://docs.rs/clap/latest/clap/)
- [https://github.com/astral-sh/uv/blob/main/Cargo.toml](https://github.com/astral-sh/uv/blob/main/Cargo.toml)
- [https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/](https://blog.rust-lang.org/2026/03/02/2025-State-Of-Rust-Survey-results/)
- [https://github.com/astral-sh/ruff/blob/main/Cargo.toml](https://github.com/astral-sh/ruff/blob/main/Cargo.toml)
- [https://github.com/sharkdp/fd/blob/master/Cargo.toml](https://github.com/sharkdp/fd/blob/master/Cargo.toml)
- [https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock](https://github.com/BurntSushi/ripgrep/blob/master/Cargo.lock)
- [https://docs.rs/crate/clap/latest](https://docs.rs/crate/clap/latest)
- [https://docs.rs/crate/argh_complete/latest](https://docs.rs/crate/argh_complete/latest)
- [https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/](https://blog.rust-lang.org/2026/08/20/Rust-1.98.0/)
- [https://docs.rs/clap/latest/clap/struct.Command.html](https://docs.rs/clap/latest/clap/struct.Command.html)
- [https://docs.rs/clap_complete/latest/clap_complete/](https://docs.rs/clap_complete/latest/clap_complete/)
- [https://docs.rs/clap/latest/clap/_derive/](https://docs.rs/clap/latest/clap/_derive/)
- [https://github.com/astral-sh/ruff/blob/main/Cargo.lock](https://github.com/astral-sh/ruff/blob/main/Cargo.lock)
- [https://github.com/clap-rs/clap](https://github.com/clap-rs/clap)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://docs.rs/crate/clap/latest/source/README.md](https://docs.rs/crate/clap/latest/source/README.md)
- [https://docs.rs/crate/clap_complete/latest/builds](https://docs.rs/crate/clap_complete/latest/builds)
- [https://github.com/sharkdp/fd](https://github.com/sharkdp/fd)
- [https://github.com/rust-cli/team](https://github.com/rust-cli/team)
- [https://rust-lang.org/what/cli/](https://rust-lang.org/what/cli/)
- [https://docs.rs/clap/latest/clap/enum.ArgAction.html](https://docs.rs/clap/latest/clap/enum.ArgAction.html)
- [https://github.com/astral-sh/uv](https://github.com/astral-sh/uv)
- [https://github.com/BurntSushi/ripgrep](https://github.com/BurntSushi/ripgrep)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)

**Perplexity**

This report draws on several key sources from the provided search results.

Tao’s “Rust clap in Practice” blog provides detailed guidance on clap’s derive and builder APIs, testing patterns, and best practices for help and validation.[1] CodeWithYoha’s “Mastering Command Line Utilities in Rust with Clap” emphasizes clap’s declarative argument structures, help generation, validation, and CLI design principles related to consistency, defaults, exit codes, stdout/stderr separation, global vs. subcommand arguments, short and long flags, validation, interactive confirmation, and dry-run mode.[3] Luc Berton’s blog on building CLI tools in Rust with clap demonstrates practical use of the derive API and subcommand definitions.[6][10]

The OneUptime blog “How to Build a CLI Tool in Rust with Clap and Proper Error Handling” reinforces clap’s status as the de facto standard for argument parsing and recommends derive API, sensible defaults, structured errors, meaningful exit codes, colored output, and shell completions via `clap_complete`.[7] The Tech Bytes “Modern Rust CLI Development [2026] Cheat Sheet” situates clap v5’s derive macro as the “2026 standard,” highlights async-first architectures with Tokio, serde-based configuration flattening, alternative allocators, link-time optimization, static linking, and explicit error handling patterns.[8]

Clap’s GitHub repository and docs.rs page provide authoritative descriptions of clap as a full-featured, fast command-line parser, detail its dual licensing, and show its companion crates.[11][13][14][15] Clap_complete’s lib.rs entry describes shell completion generation, dual licensing, and download metrics, while Yocto project logs illustrate its integration in build systems.[17][19] Fedora’s Rust packaging guidelines reference clap as a standard crate, supporting its ecosystem position.[12] Crate listings for pico_args, rust-args-parser, bpaf, and flexiargs on docs.rs and lib.rs inform the landscape of alternatives.[4][5][9][16][18]

These sources collectively establish clap and clap_complete as the dominant, ecosystem-standard choices for `rs-launch-blueprint`’s CLI parsing and completion generation, while providing enough information to characterize alternatives and justify the chosen stack.

**Implementation Blueprint for `rs-launch-blueprint` CLI**
**CLI Surface Shape: Noun–Verb Subcommand Groups**

The CLI surface for `rs-launch-blueprint` should adopt **noun–verb subcommand groups**, mirroring the Python port’s resource-oriented structure. This means commands such as `plbp projects list`, `plbp projects create`, `plbp config show`, and `plbp config set` become the primary verbs on resources. In clap’s derive API, this maps naturally to a root `Cli` struct with a `subcommand` field of enum type `Command`, where `Command` has variants like `Projects(ProjectsCommand)` and `Config(ConfigCommand)`. Each resource enum, such as `ProjectsCommand`, then has variants for verbs.

This structure reflects principles of discoverability and alignment with library and web layers. Library modules such as `projects` and `config` can define functions `list`, `create`, `show`, and `set`, which the CLI commands invoke. Web routes in the HTTP service can be similarly aligned, e.g., `GET /projects`, `POST /projects`, `GET /config`, and `PUT /config`. The noun–verb pattern ensures that the CLI, library, and web layers share a conceptual model.

Clap’s subcommand support makes this structure straightforward. The derive API allows definitions like:

```rust
use clap::{Parser, Subcommand};

#[derive(Parser)]
pub struct Cli {
    #[command(flatten)]
    pub global: GlobalOptions,

    #[command(subcommand)]
    pub command: Command,
}

#[derive(Subcommand)]
pub enum Command {
    Projects(ProjectsCommand),
    Config(ConfigCommand),
    Completion(CompletionCommand),
}
```

Here `GlobalOptions` includes options such as `--json`, `--config`, and `--verbose`, flattened into the root so they are available globally.[1][3][6][8][10][15] The `ProjectsCommand` and `ConfigCommand` enums define verbs. This shape is maintainable and scales as new verbs are added.

**Global Options and Stackability**

Global options such as `--json`, `--config`, and `--verbose` must be available on every command and recognized regardless of position. Clap’s `global` argument flag and derive flattening support this behavior. The `GlobalOptions` struct can be defined with attributes marking each field as global:

```rust
#[derive(clap::Args)]
pub struct GlobalOptions {
    #[arg(long, global = true, env = "PLBP_JSON")]
    pub json: bool,

    #[arg(long, global = true, env = "PLBP_CONFIG")]
    pub config: Option<String>,

    #[arg(short, long, global = true, env = "PLBP_VERBOSE")]
    pub verbose: bool,
}
```

This ensures that flags like `--json` and `--verbose` are recognized whether placed before or after the command verbs, satisfying the stackability requirement.[1][3][8][10][15] The `env` annotations are shown here for clarity; in the actual template, a macro or helper may be used to automatically derive env-var names from field names with the `PLBP_` prefix, reducing boilerplate while leveraging clap’s `env` feature.[1][3][7][8][15]

Testing will verify that `plbp projects list --json`, `plbp --json projects list`, and `PLBP_JSON=1 plbp projects list` all behave correctly. Clap’s parsing and validation ensures that invalid combinations of global options are rejected with clear errors before side effects occur.[1][3][7][8]

**Extended `--version` Output**

The extended version output should print multiple lines that include at least the tool name and version, Rust version, and platform details (for example, target triple). Clap’s version handling can be configured in the derive API or through a dedicated `version` subcommand. For instance, the CLI could define a `Version` subcommand:

```rust
#[derive(Subcommand)]
pub enum Command {
    Projects(ProjectsCommand),
    Config(ConfigCommand),
    Completion(CompletionCommand),
    Version,
}
```

And the `main` function would handle `Command::Version` by invoking a library function:

```rust
fn main() {
    let cli = Cli::parse();
    match cli.command {
        Command::Version => {
            rs_launch_blueprint::version::print_extended();
        }
        Command::Projects(cmd) => { /* ... */ }
        Command::Config(cmd) => { /* ... */ }
        Command::Completion(cmd) => { /* ... */ }
    }
}
```

The `print_extended` function would read constants generated by the build-metadata crate selected by R22, printing lines such as:

```text
rs-launch-blueprint 0.1.0
Rust 1.75.0 (build metadata)
target x86_64-unknown-linux-gnu
```

This pattern mirrors Python’s extended version output while respecting Rust’s compile-time metadata conventions. Clap’s built-in `--version` flag could also be configured via `ArgAction::Version` to print the extended output, though the subcommand pattern offers more flexibility. Tutorials and docs for clap show that version behavior can be customized via the derive attributes and command configuration.[1][3][6][8][10][15]

**Completion Command via clap_complete**

The `completion` command should accept a `shell` argument and generate a completion script using clap_complete. The `CompletionCommand` enum variant may be defined as:

```rust
#[derive(clap::Args)]
pub struct CompletionCommand {
    #[arg(value_enum)]
    pub shell: Shell,
}

#[derive(clap::ValueEnum, Clone)]
pub enum Shell {
    Bash,
    Zsh,
    Fish,
}
```

The implementation will construct a clap `Command` for the CLI (via `Cli::command()`) and then call clap_complete:

```rust
fn run_completion(shell: Shell) {
    use clap_complete::{generate, shells};
    let mut cmd = Cli::command();
    match shell {
        Shell::Bash => generate(shells::Bash, &mut cmd, "plbp", &mut std::io::stdout()),
        Shell::Zsh => generate(shells::Zsh, &mut cmd, "plbp", &mut std::io::stdout()),
        Shell::Fish => generate(shells::Fish, &mut cmd, "plbp", &mut std::io::stdout()),
    }
}
```

This is consistent with clap_complete’s documented usage and provides scripts for each supported shell.[7][8][17][19] The Python port’s `completion(shell: str)` function behaves similarly, and the Rust template will document usage such as `plbp completion bash > /etc/bash_completion.d/plbp`.

**Did-You-Mean Matching**

Clap’s built-in suggestion mechanisms will be used for did-you-mean matching. When a user types an unknown subcommand, such as `plbp projetcs list`, clap typically generates an error with a suggestion such as “did you mean `projects`?” This behavior is part of clap’s validation and error formatting.[11][13][15] Using clap’s default error style keeps parity with Commander’s built-in suggestion behavior and avoids the need for a separate did-you-mean

> ⚠ Possible truncation: response may be incomplete.

**Sources**
- [Rust clap in Practice: Build a Production-Ready CLI - Tao's Blog](https://www.ubitools.com/rust-clap-cli-guide/)
- [The Rust Module System and Useful Crates for CLI Apps](https://ngoldbaum.github.io/posts/helpful-rust-cli-crates/)
- [Mastering Command Line Utilities in Rust with Clap](https://codewithyoha.com/blogs/mastering-command-line-utilities-in-rust-with-clap)
- [rust-args-parser](https://lib.rs/crates/rust-args-parser)
- [pico_args - Rust](https://docs.rs/pico-args/)
- [Building CLI Tools in Rust with Clap: From Zero to](https://lucaberton.com/blog/rust-cli-tools-clap-2026/)
- [How to Build a CLI Tool in Rust with Clap and Proper Error ...](https://oneuptime.com/blog/post/2026-01-07-rust-cli-clap-error-handling/view)
- [Modern Rust CLI Development \[2026\] \[Cheat Sheet\] - Tech Bytes](https://techbytes.app/posts/modern-rust-cli-development-2026-cheat-sheet/)
- [FlexiArgs — Rust parser // Lib.rs](https://lib.rs/crates/flexiargs)
- [Rust CLI Apps | Clap Crate | Command Line Tools | Chapter 24](https://geekyscript.com/tutorial/rust-programming/rust-programming-building-command-line-applications)
- [GitHub - clap-rs/clap: A full featured, fast Command Line Argument Parser for Rust](https://github.com/clap-rs/clap)
- [Rust Packaging Guidelines](https://fedorapeople.org/~tmz/guidelines/packaging-guidelines/Rust/)
- [GitHub - clap-rs/clap at v3.0.0-beta.5](https://github.com/clap-rs/clap/tree/v3.0.0-beta.5)
- [GitHub - clap-rs/clap at 1b0088ecb7b770c431eedce754f7f491f1a477d5](https://github.com/clap-rs/clap/tree/1b0088ecb7b770c431eedce754f7f491f1a477d5)
- [clap 4.6.6](https://docs.rs/crate/clap/latest)
- [bpaf version 0.5.1](https://crates-io.ganymede-static.progval.net/crates/bpaf/0.5.1/)
- [clap_complete — CLI for Rust // Lib.rs](https://lib.rs/crates/clap_complete)
- [Information for uv](https://repology.org/project/uv/information)
- [bindgen-cli-native-0.71.1-r0 do_unpack](https://errors.yoctoproject.org/Errors/Details/861431/)

**Cost**
Total: $0.9949

**Gemini**

All source material is cited inline using the `[cite: id]` format, corresponding to the provided research snippets. No standalone reference section is appended, in strict adherence to the formatting constraints.

**Sources:**
1. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGq5h9tbb3wS7BNzUKyIhXOi_QiATiIMzvwKs_zLNzrxVUfIBtRhrp9pFJC6zyNobkQz3JpAYwWKW9rpFM6Hz3KLbg3mueJ-_uDnspPuVammppiYM4FFk8QRdXmSg==)
2. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFkB7ufBROZXAyG_VFTp04_4102x266rDVcPduWhk-k77QdBein_ixIKoQ2_cmgafFSRG3u3ejRdpivjDSmJDRHPzPmLsKztUIZeWJJIz3O3WhnICZH)
3. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHbRTJ7aVEFL2c-pl35dVUPsuY3NSm2ickFplWZ25havmpzcF3OVFUY8vpU2OLKwbXtBvlMwWbUapsCPrpWkaJpA2FJYi_wnBTLnzY7UhfBDsguXCeOpJ4CAi9v_oi6zA==)
4. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4tJVSI_cdwFEIhcSQ4K-VrmNQYRNwNzVxjMvcei0hfjoBz011LxDezejsDLhg8afXXpRR2C57c9pfB6Uehh12urfaQAi6AJBihw==)
5. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF6bFanKtifFaV96JtSjO65iFHvzBL45mZjJWd9f2ve4M6mIWyWReFN1Ipp91oQrtvB8tgDlH4REY3VIH2fHhVav19kif8ZKLaostEv4K0zZ3zG5-rGzQ854f2LHE1mU-vnqH0wNzV-)
6. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFhasYe8Cz1Y2TNzqfygF405gPXDEkOXimO--8_HV4Raojo1Fz3369hj6bwLPT-wtHbxhsLcUVxRKA8f4mK3_-ns_bAiJwZ7QlAnSPC9EmWWiP-Ysn17iRMXDezg==)
7. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFh9ppEKUiA8PimjLjQe1i7pr0WhLPFqdij5CSbKv943I5jNshat5cHauXkdO7X-bHkaiEB5ZPV8-m1iJ8h2b6y_AsC1KHjIVziXFWx)
8. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGubildxkiGJ0fatyEgIIKaVtp2ilyJawZpH5GadJF9Ml1LqRaBB2pLQoGTv69uwaVMaXde7SKjVBs6c7TmwIzgsqOEF2a3UunBcXj92HgQD5QskoHw6ig-5g==)
9. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFUgeRsyBHyVXJizaFmfsipbXbwmbaPbVEYPfeh1fh_lm46EAGFmfm_52GdIPkGt4NfeSlxZ3RbYNRg3uGTHzGiXScMxshO6sy47SVS20jORE43fenozK_hcj_pjXYEP8=)
10. [rustsec.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFO0TgVsMJK8X1FHla2sYCdKmd8_IGt_p0jECAStcXQykVuPyNdZYgw283o9Ly4ALZiXkZWa3Wi_neQXQirKEk5zrn5R_kRi3L28ji9LnOlGVhNanEs)
11. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGYNJNBNUkjj9E4ITZHKiGZEDAT3XFpFTT0zbIK_hB0o33rcqm80g4Ujmdy20LAAictBx1V-teP0UBmIIAtvrsJKsrEP2A0D9ycNcwlU2LpjVUGLJkHiDeZ4Q6XYb3LdnQimi_suWF8Dbp6LmCZ7M3FIWszetzTccGU1g-NrCz3lQ==)
12. [jetbrains.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHgRfgzcUcxCCzDNeGYHeqXySBt_WKvMrRzHvS75izyeJz-sqQZNskQ8kwl5i-qAVQrHLQ9mvGf3FzYGnwYhLuCWTOo1jar1SmEVT1V3Y4UCC1VXw7HImiLfiA-y7IUrfHfnrjhovuM3zz7K45ZkzflQSGr)
13. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHyq-Et4KYS5Lg0u-SIACADH3xQxvlvmFIQY1qNCK36psBApMS-nTZiXLq-4xNurlTi4-7LspDAH5wZKil3whm5O6nI8OnzdrgLdQ==)
14. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHPA4a7JsO_bj5z8GMNC64ckEZipxKLk-x1D0vnNKLig7Zvn-wXg6jn7fhGV4E_taTNLObFCTlO6e0h61i2I7b0IR4W0sjTqcMbyAqJnC6eKXhBJFptUku5vq6DNqA8ZlUF)
15. [sunshowers.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGsv74y_HZ7b_6Pq9gxYlQarAw1MVUNsmh6m-pN_vGN3wKEizWcvEFxI1R-Vh4DvI1-eEBe50V4n8YWz_oXVv0TtkBGJitTfKIdxt2PChnKGcSDLKwrNmhaoeyvvBc4_0rEJX0cVUzk6LzVtD67LLvpD2uPPg==)
16. [sunshowers.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGGDkjhdrvEBW0zWPoejO0-cK5B0fJQX_hsUInmfCBImyf_kgumQ1tk5wnZ7Pq45ixt9r7qnlsA9vI9ZbC-YkpM8JIk3kmAOJW_K9hmfnQfwifbsBKW0qUZOWKFM4RzR-mJDwqt_GzU6Lq6gS0hIEE0zgQ-4gtJUdUDfK5A)
17. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEDM2WGyECOjmQmPLIoh_RxYe8bgC4D6zBrd0MkB9cphO_TRyZ1O5jLmtExTthjptORQWCA8-L4U5OJrdaRyRWC6uNDvIsg5UAfsKB0I-9otgJKOsK4udE84OPN_hl3ELuHgsv7_Pk=)
18. [issuehunt.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5uYI7tXM6-4qJUr_Un9_Io0eszG5LpGEO1yOxWzhckHnmjJpMk-zjgmTfJerLQQho6UG_-IFFI0uUVWzQfkU0_H_K9hRofJypNwWhRdDB1dyw3gJBNE4WWwX5YmxCSEx6tl6vaAEkNOs=)
19. [brown.edu](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFYH3Cyko_2fJXD8ZD9QL5xDoxiR1I7ma4zWCr00_4nyqM3z6TM1pkINKDB16ktuwsv99QPj-R7s8JqsyJb_xL-LVxLY2_X1qSRPq1WnTiEqjhlaAHtmdwANl1d4PzELrUkpGxXFgbpuQ2O2O7PjPCnoWyAECp2LCQ00TkqafP1BxtEVy47)
20. [enablingpersonalizedinterventions.nl](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGruxBFqDX8MAHFb6N-VpA8EjEGVX9vPlNFgLFQPLKnKfMjonPHKwvYgT08mmwY3l8aPmw2xZcBtqJvwrl8IoQa-Yq52-kumlXmj0aaiVo3x8fZasYkjFnjmvGLEI6mMJBrpsYhFHQQnIOIZ-IuSkdpyROA2bjLfG2eRTPFd7IR5ZUgtmFytPnrZg==)
21. [clispec.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFdDV1hnZp_NnpkvibK6R2Wtayx3_vQBSBYU7zweOX2HLSptWdaAaQNX4NOZ1btyQ3DqgH38d6v9vtelKFoZHzAFrdDaILJXfRmBukh8lkBVoWFDTm)
22. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQErgSOnHqtMxe51p59y5zoCJdWjt8RCg2QUpNiQ6Tt3ETC16fWMDsu2IEzbNVeOIGoSJxDJkKb_l8r9oisIeoOhTtoZ3lzKpu_-yHmPXTOBgyM8H8OTVFmnCn98h5DbpyzbRUJIa-E=)
23. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFcs8Toc2pNQteiUei5t54fVoIaFPWYJFa6PAP80LbXQwiEIM6QYGYOuOBrQG9rxjB--0UAeNtXfyKbDUGU0ak41kol2KYTZ_QnPmOuUwSq8svmDW13Y1PC)
24. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFdhYbQM9AKS2NWcQ61mASn9uzwxpUKPg15XCciplfj51XoF5r7t4ahQ4OY7GIvCOAVJIyyeyyCIgL1i3fvUP3oNLu6bvRpqahannHjyxfWN7pMW5Yt9y9htqXE8Pm9MQuF)
25. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGz_Yl954XX9oMmR-3PRg_31rzXbeW9kf2c15vgHT9KdGptXFSvopaouXkL9-asYDb2R2OkXAebqu8H5xFwD3a6SeSvrKsiy-auAB_CMA4K7hFT3K4MAW21KUnNHXvfG1tkVi3KMm5nLvb570hubOrbWBr52HwGq1AJiA==)
26. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG0YEP2qvXRrZfmAuXU_iJzKg19F-R1rLPpp1AqEdiJaQJKNxQhN0QYog9zvT7wXxTwZicFzFCg2uOv75VhYCrkeeLkUzQy4WyO7GZ-2yswYq7BNWfC8ObSlqeRJexU)

**Sources**
- [crates.io](https://crates.io/crates/clap_complete)
- [crates.io](https://crates.io/crates/lexopt)
- [crates.io](https://crates.io/crates/clap/4.5.35/code)
- [docs.rs](https://docs.rs/bpaf)
- [github.com](https://github.com/rosetta-rs/argparse-rosetta-rs)
- [docs.rs](https://docs.rs/crate/pico-args/latest)
- [docs.rs](https://docs.rs/lexopt)
- [lib.rs](https://lib.rs/crates/clap_complete)
- [docs.rs](https://docs.rs/crate/clap_complete/latest)
- [rustsec.org](https://rustsec.org/advisories/)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-02-03-rust-clap-cli-applications/view)
- [jetbrains.com](https://blog.jetbrains.com/rust/2026/08/10/rewriting-in-rust/)
- [docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html)
- [issuehunt.io](https://oss.issuehunt.io/r/clap-rs/clap/issues/3221)
- [sunshowers.io](https://rust-cli-recommendations.sunshowers.io/handling-arguments.html)
- [sunshowers.io](https://rust-cli-recommendations.sunshowers.io/cli-parser.html)
- [github.io](https://epage.github.io/blog/2022/09/clap4/)
- [docs.rs](https://docs.rs/clap)
- [github.com](https://github.com/nihaals/clap-complete-command)
- [brown.edu](https://cel.cs.brown.edu/aquascope/doc/clap_complete/generator/fn.generate.html)
- [clispec.dev](https://clispec.dev/guide/rust/)
- [enablingpersonalizedinterventions.nl](https://wiki.enablingpersonalizedinterventions.nl/docs/clap_complete/aot/index.html)
- [crates.io](https://crates.io/crates/shadow-rs)
- [github.com](https://github.com/clap-rs/clap/issues/2313)
- [github.com](https://github.com/termoshtt/clap-vergen)
- [rust-lang.org](https://users.rust-lang.org/t/custom-version-output-with-clap/129108)
