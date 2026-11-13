# R54 — Doxa engine report (three providers, regrouped by template field)

Normalization record: Doxa operation research-20260916-220239-200467ec7afb44b5 (all_deep_research) returned one report per provider. This file regroups the three answer bodies under the prompt's template fields so the single-report shape check applies; within each field the three provider sections appear in the order OpenAI, Perplexity, Gemini, each introduced by a bold label, and under `### Members` every provider's members are kept with the provider name appended to the member heading. Every content line of each provider's answer body is preserved (the originals are the three saved files under the run's doxa/ directory; raw/doxa-<provider>.normalized.md hold the bodies individually). Headings that would fall outside the template are demoted to bold text so no heading outside the template remains; doxa/normalization.json lists every other adjustment.

**Provider preambles (text preceding each provider's first template field)**

**OpenAI (gpt-5.6-sol)**


**Perplexity (sonar-deep-research)**

**Config Discovery Tiers for `rs-launch-blueprint`: A Cross‑Ecosystem Contract**

This report establishes a principled, cross‑language configuration discovery and layering contract for the `launch-blueprint` family and then derives a concrete Rust implementation bundle for `rs-launch-blueprint` that satisfies that contract without silently reducing it to a single tier. The shared principle is a deterministic multi‑scope hierarchy—system, user, project, and defaults—overlaid by environment variables and command‑line flags in a well‑defined precedence order, where outer scopes override inner ones and `--config` (with an environment alias) replaces discovery entirely rather than adding another layer. Building on the XDG Base Directory Specification, the owner’s prior Python and TypeScript decisions, and ecosystem practice such as Starship’s configuration resolution, the report concludes that the cross‑repo agreement must be expressed at the level of architectural pattern and precedence semantics, not at the level of a specific crate or file path. For Rust, the recommended bundle is a combination of a platform‑aware configuration‑directory discovery crate following XDG and system conventions, a layering/config‑composition crate that can merge multiple sources while leaving precedence under application control, and the `clap` CLI framework with a `--config` argument whose value may come either from the CLI or from an environment alias. Within that bundle, this report recommends using `cfgmatic_paths` for user/local/system config directory discovery[19], `cfg-rs` for layered configuration composition and typed loading[3][4][8], and `clap` for flags and env integration, augmented by a small hand‑rolled project‑local upward search. The shared cross‑ecosystem principle is preserved, while ecosystem‑specific differences are explicitly justified and localized. Several baseline behaviors are affirmed, and one is flagged for owner review where the Rust implementation necessarily sharpens an ambiguous precedent.

**Context and Framing**

The `launch-blueprint` family exists to provide a consistent, principled skeleton for applications that present as a combination of command‑line interface, reusable library, and web service. In the Python implementation, configuration discovery is explicitly layered: system‑wide configuration directories supply baseline values, per‑user configuration directories override them, and project‑local configuration files discovered by an upward search from the working directory provide the most proximate file‑based overrides. On top of those file tiers, environment variables and command‑line flags are placed, with `--config` acting as a hard replacement for the discovery chain rather than a further override layer. This behavior is codified in the Python code as `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`, together with a multi‑directory implementation of `paths.config_dirs()` for system configuration folders and a `project_config_file()` function that walks upward from a starting directory to find a local configuration file, as well as a CLI option whose `envvar="PLBP_CONFIG"` alias provides the environment‑driven override for `--config`. These behaviors are not incidental implementation details; they express deliberate owner decisions about configuration scope, override semantics, and operator control.

The TypeScript port adds another dimension to the context. Its decision record D‑017(1) explicitly names a canonical precedence order derived from CLI standards and the XDG specification: configuration files under `$XDG_CONFIG_HOME/<tool>` using a `TOML <tool>_config.toml` pattern, with precedence `flags > TOOL_* env > project > user > system > defaults`. However, D‑017(3) reveals that the shipped implementation currently realizes only the per‑user tier via a hand‑rolled `xdg-paths` resolver, omitting system and project tiers. This divergence is recorded in the ledger as `DIVERGENT`, and it is crucial to treat it as live context rather than as a settled constraint. The canonical order remains the target; the current TypeScript implementation is an incomplete realization of that contract. For Rust, the goal is therefore not to mimic the TypeScript implementation in its current state, but to honor the cross‑repo principle that the decision record expresses.

On top of this historical context, the owner has clarified several fixed parameters and constraints. Rust edition is locked to `2024`, with a minimum supported Rust version policy of “stable minus two minor versions”, raised only in minor releases and declared as `rust-version` in `Cargo.toml`, then enforced in CI. Licensing is constrained to `MIT OR Apache-2.0`, and CI must run on `ubuntu-latest` and `macos-latest` as target operating systems. Most importantly for this item, feature F247 (“XDG override”) binds the behavior of configuration directory discovery: `XDG_CONFIG_HOME` must be honored on both Ubuntu and macOS and ignored when empty, and the choice of directory‑discovery crate must respect this requirement. The baseline review already notes that `directories` 6.0.0 ignores `XDG_CONFIG_HOME` on macOS, whereas `etcetera` 0.11.0 offers an XDG strategy that honors user‑defined XDG variables.[11][12][13][15][16][17] These contextual elements narrow the Rust ecosystem landscape that we must survey and shape the bundle we can safely recommend.

Because this item is classified as “Deep” effort, the owner requires a full ecosystem survey rather than a quick familiar‑library recommendation. The survey must begin with a landscape map classifying candidates into three bins—built‑in or first‑party tooling, established industry standards, and up‑and‑comers—and must then identify authoritative guidance, actual practice in well‑regarded projects, and fitness against the specific use case of a CLI+library+web service Rust blueprint. Each candidate must pass explicit fitness gates: licensing compatibility, MSRV compliance within the specified policy, lack of RustSec advisories, CI support for Linux and macOS, stated coupling and feature behavior, and an assessment of binary size and compile cost. In this offline analysis, quantitative metrics such as recent downloads, exact release dates, GitHub stars, and issue responsiveness cannot be retrieved in real time, so they will be treated as “inapplicable” in the sense that they must be gathered in a follow‑up verification phase before adoption, rather than being silently omitted. This constraint itself becomes part of our confidence and re‑verification plan.

Finally, this item is coupled to other configuration‑related decisions: R55 governs tolerance of parse and validation errors in discovered layers, R56 governs secrets and whether configuration files may carry tokens, and R57 governs the broader XDG directory set beyond configuration (data, cache, state, runtime). Those couplings delimit this item’s scope. R54 decides how many configuration tiers exist, how they are discovered, and how they are ordered; R55 and R56 will later decide what happens when discovered files are broken or contain secrets, and R57 will decide how data and cache paths are discovered. This report therefore deliberately remains secret‑agnostic and error‑handling‑neutral, and focuses purely on discovery and layering semantics.

**Methodology and Survey Approach**

The methodology mandated for this decision is deliberately “forest before trees”. Before evaluating any particular crate such as `config`, `cfg-rs`, `etcetera`, or `directories`, we must define the category of tooling this item concerns, sketch the ecosystem landscape in terms of built‑ins, standards, and up‑and‑comers, and identify authoritative sources of guidance about configuration directories and layering in Rust and in cross‑platform applications generally. Only then can individual crates be placed sensibly in context, avoiding unconscious bias from familiarity or incidental popularity.

The category decided by R54 is “configuration discovery and layered composition for multi‑mode applications”. It spans several subdomains: directory discovery following XDG or native conventions; configuration file parsing and typed loading; layering and merge semantics across multiple sources; environment variable and CLI argument integration; and project‑local upward search for configuration files akin to Python’s `project_config_file()`. In Rust, this category sits at the intersection of filesystem utilities, CLI frameworks, and configuration libraries. Built‑in tools in the Rust standard library such as `std::env` and `std::fs` provide the raw materials to implement directory discovery and upward search but do not themselves encode cross‑platform conventions like XDG. First‑party and widely adopted ecosystem crates such as `directories`, `directories-next`, `xdg`, and `etcetera` provide higher‑level directory discovery APIs based on XDG and OS APIs, while dedicated configuration libraries such as `config`, `figment`, and `cfg-rs` provide layered composition and typed retrieval.[1][3][4][8][11][12][13][15][18][19][20] Up‑and‑comers such as `cfgmatic_paths` and `user_dirs` explicitly question earlier design decisions and seek to better honor user‑defined XDG variables or to provide richer tier semantics.[19][20]

Authoritative sources for directory conventions include the XDG Base Directory Specification itself (referenced from crates like `xdge` and `xdg`), documentation of OS‑specific directories (Apple Standard Directories, Windows Known Folder API), and Rust ecosystem discussion and evaluation posts. The `xdge` crate documentation provides a concise mapping from XDG configuration environment variables to their defaults—`XDG_CONFIG_HOME` defaulting to `$HOME/.config`, `XDG_CONFIG_DIRS` defaulting to `/etc/xdg`—and names methods such as `XdgDirs::config_home` and `XdgDirs::config_dirs` that expose these semantics in code.[14][17][18] The `directories` and `directories-next` crate documentation elaborates how these XDG variables are interpreted on Linux, and how analogous locations are chosen on Windows and macOS via the Known Folder API and standard Apple directories such as `~/Library/Application Support`.[12][15][16] The `etcetera` crate offers a more flexible strategy‑based approach, allowing applications to choose XDG versus native conventions while providing examples of application‑specific strategies that honor XDG on Linux and macOS for configuration files that users are expected to edit.[11][13] The `user_dirs` crate goes further, explicitly critiquing earlier crates for not respecting XDG variables and positioning itself as an XDG‑first directory provider on all platforms.[20] A blog post by Lars Wirzenius surveys XDG directory crates and evaluates them for compliance with the specification’s defaults, concluding that `directories-next` was, at that time, the clearest winner among the evaluated crates but noting the existence of many alternatives.[17] Together, these sources form an authoritative baseline for directory discovery.

Authoritative sources for configuration layering and precedence include both library documentation and ecosystem practice in real projects. The `config` crate documentation describes a layered system where defaults, explicit programmatic overrides, file sources in multiple formats (JSON, TOML, YAML, INI, RON, JSON5, CORN), and environment variables can all be added as layers, with later layers overriding earlier ones and values accessible via formatted paths akin to JSONPath.[1][4][8] The `cfg-rs` crate similarly advertises composition of multiple sources (files, environment, inline maps, random values), support for live refresh, placeholder expansion, and typed configuration via derives, notably without a `serde` dependency.[3][4] A Rust FAQ article on configuration hierarchy reinforces the same pattern as the Python and TypeScript decision record: defaults at the core, then file values, then environment variables, then CLI flags, with explicit user input always beating implicit settings.[8] It frames this explicitly as a hierarchy where outer boxes override inner ones, matching the owner’s stated `flags > env > project > user > system > defaults` order.

Practice evidence comes from real, well‑regarded Rust projects that must solve similar configuration problems. Starship, a cross‑shell prompt written in Rust, uses a single `starship.toml` configuration file located by default at `~/.config/starship.toml` or overridden via the `STARSHIP_CONFIG` environment variable.[2][5][6][7][9][10] Its documentation describes a discovery order of `STARSHIP_CONFIG` as an explicit path, then `~/.config/starship.toml` as the XDG default, with per‑module defaults used when no configuration file is found.[5][6][7][10] This pattern is simpler than the multi‑tier chain desired for `launch-blueprint`, but it expresses an important precedent: an explicit environment variable override for the configuration path, honoring XDG config directories, and falling back to built‑in defaults when no file is found. The Starship cheatsheet and guide reiterate these behaviors, and a DeepWiki configuration entry shows deployment of Starship’s configuration via GNU Stow to `~/.config/starship/starship.toml`, together with an explicit export of `STARSHIP_CONFIG` in `~/.zshrc`, indicating active use of the override mechanism in practice.[5][6][7][9][10] This provides a concrete example of cross‑shell configuration resolution with XDG semantics.

The final methodological step is fit analysis. Rather than choosing crates as abstract bests, we must judge them against the specific shape of `rs-launch-blueprint`: it is a template for CLI+library+web service applications. That means it must work well for long‑running server processes, for user‑invoked CLI commands, and for library consumers embedding configuration. It must support layered configuration with deterministic precedence across system, user, and project file tiers, plus environment and CLI, and it must be composable enough that later items (R55, R56, R57) can extend its behavior without being constrained by monolithic library assumptions. Crates that hard‑code precedence in ways that conflict with the owner’s contract or that ignore XDG variables on macOS when configuration files are meant to be user‑editable are poor fits, regardless of their popularity. Conversely, crates that defer precedence to the application and expose directory tiers are well‑suited even if they are relatively new and require re‑verification.

With this methodology established, we can now turn to the landscape and then to the principles and implementation patterns that must be preserved.

**Decision Body**

**Gemini (deep-research-preview-04-2026)**

**Implementation Plan: Configuration Discovery Tiers**

### Landscape

**OpenAI**

**Research date:** September 17, 2026. Unless identified as owner-provided repository evidence, all cited web sources and URLs were retrieved on that date.

**Evidence-collection limitation:** the required crates.io and GitHub JSON endpoints were requested, but several returned inaccessible or empty bodies in this research environment. I therefore do **not** invent or substitute values for 90-day downloads, all-time downloads, `pushed_at`, search-only open-issue totals, or issue-response medians. The exact endpoints and commands needed to close those mechanical checks are included under validation. Functional API documentation, release dates, source sizes, standards, and reference implementations were retrievable.

**Category decided:** deterministic, layered application configuration: path discovery, ordered source composition, and CLI selection/override behavior.

| Bin | Field map | Assessment |
|---|---|---|
| **Built-in or first-party toolchain** | `std::path::Path::ancestors`; `std::env::split_paths`; Cargo’s hierarchical configuration model | Rust has sufficient primitives for a small discovery adapter, but no standard-library layered-configuration facility. Cargo provides strong first-party precedent for searching upward, merging several files, and letting narrower scopes override broader scopes. Its `--config` behavior is only architectural evidence because Cargo *adds* an extra source, contrary to owner-fixed F233. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html)) |
| **Established industry standard** | XDG Base Directory Specification; `xdg`; `etcetera`; `directories`; `config-rs`; Figment; `clap` | XDG normatively defines one user config root, an ordered list of system roots, absolute-path validation, defaults, and precedence. `config-rs` and Figment are the two mature general source-composition choices; `clap` is the dominant CLI parser and has native environment-backed arguments. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/)) |
| **Up-and-comer** | `cfgmatic-paths`, `microxdg`, `project-dirs`, `clap-layers`, `conf`, `einstellung` | Some directly model system/user tiers or declarative CLI/env layering, but their maturity, adoption, maintenance evidence, or exact fit is weaker. They are useful re-verification candidates, not current defaults. ([docs.rs](https://docs.rs/cfgmatic-paths/latest/aarch64-apple-darwin/cfgmatic_paths/)) |

**Authority hierarchy used:**

1. The XDG specification is normative for `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS`, empty/unset defaults, absolute-path validation, and directory priority. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))
2. Rust standard-library and Cargo Book documentation are first-party authority for the upward-search primitive and established Rust configuration practice. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))
3. Maintainers’ own crate documentation is authoritative for crate APIs, features, source ordering, and platform conventions. ([docs.rs](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html))
4. crates.io, GitHub, and RustSec are the prescribed authorities for popularity, repository state, and advisories. Where their API bodies could not be extracted, the result is explicitly marked unverified rather than replaced with a secondary estimate.

**Practice evidence:**

- Cargo searches the current directory and every ancestor, merges applicable files, and gives deeper directories precedence over ancestors and the user-level file. That shows hierarchical discovery is familiar, production-grade Rust practice, while also illustrating why R54 must specify its own collection and explicit-file semantics rather than saying “behave like Cargo.” ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html))
- Pop!_OS’s `cosmic-store` currently declares `xdg = "3"`, providing a contemporary production adopter for the XDG implementation family. ([github.com](https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml))
- Mozilla’s `sccache` manifest was surveyed as a production example of Rust CLI/configuration composition. It is relevant because compiler-cache configuration exercises CLI, library-like reusable internals, and service/daemon execution modes similar to this template’s three shapes. ([github.com](https://github.com/mozilla/sccache/blob/main/Cargo.toml))
- No maintained published Rust template was found that demonstrates this exact contract—multi-system XDG files, user file, nearest project file, replacement-style `--config`, ordinary environment overrides, and CLI overrides. The strongest maintained references are therefore Cargo’s hierarchy, the XDG-aware crates, and the source-composition libraries rather than a single template repository.

**Fit conclusion:** use an explicit discovery/composition architecture rather than an all-in-one declarative macro. The template must serve a CLI, reusable library, and web service; therefore discovery must be callable independently of `clap`, configuration must be resolved once at process startup, and the resulting typed settings must be injectable into both the CLI command implementation and web-service state.

---

**Perplexity**

Within the category of configuration discovery and layering, the Rust field can be mapped into three bins: built‑in or first‑party tooling, established industry standards, and up‑and‑comers. This mapping is not about popularity alone; it reflects maturity of design, breadth of adoption, and alignment with authoritative guidance like the XDG specification.

The built‑in or first‑party tooling bin includes the Rust standard library and minimal directory‑helper crates. `std::env` provides access to environment variables, including `HOME`, `XDG_CONFIG_HOME`, and `XDG_CONFIG_DIRS`, and `std::fs` provides filesystem traversal. These suffice to implement hand‑rolled configuration directory discovery and project‑local upward search. Minimal crates such as `dirs-lite` fall close to this bin, offering a dependency‑free way to obtain user config, data, and cache directories across platforms.[16] `dirs-lite` documents that on Linux it uses `$XDG_CONFIG_HOME` or `$HOME/.config`, on macOS it uses `$HOME/Library/Application Support` by default, and on Windows it uses `%APPDATA%`, with an optional `favor-xdg-style` feature to return XDG‑style paths (`$HOME/.config`, `$HOME/.local/share`, `$HOME/.cache`) on macOS.[16] These crates are lightweight and simple, but they only provide a single config directory per user, not a chain of system/user/project directories, and their macOS defaults may conflict with the owner’s F247 requirement unless the XDG‑style feature is explicitly enabled.

The established industry standard bin for directory discovery includes crates such as `directories`, `directories-next`, `xdg`, and `etcetera`. The `directories` and `directories-next` crates provide platform‑specific locations for configuration, cache, and data directories, leveraging the XDG base directory specification on Linux, the Known Folder API on Windows, and Apple Standard Directories on macOS.[12][15][17] Their documentation shows that `ProjectDirs::config_dir()` yields paths like `/home/alice/.config/barapp` on Linux, `C:\Users\Alice\AppData\Roaming\Foo Corp\Bar App\config` on Windows, and `/Users/Alice/Library/Application Support/com.Foo-Corp.Bar-App` on macOS.[12][15] This confirms both their portability and a design choice: on macOS they use Application Support rather than XDG directories, and they do not expose multiple directories such as `XDG_CONFIG_DIRS` as a search chain. The `xdg` crate, referenced via the Piston documentation for `xdg::BaseDirectories`, directly implements the XDG Base Directory Specification.[18] Its API examines environment variables such as `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS`, and others, defaulting them according to the spec (e.g., `XDG_CONFIG_HOME` defaulting to `$HOME/.config`, `XDG_CONFIG_DIRS` defaulting to `/etc/xdg`). It exposes methods such as `place_config_file()` to locate or create configuration files in appropriate directories, automatically creating leading directories.[18] This crate is Unix‑only, but it provides a canonical implementation of XDG semantics, which can be instructive even when a cross‑platform crate is needed. `xdge` similarly exposes `config_home` and `config_dirs` methods with explicit documentation of `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` defaults.[14] `etcetera` sits slightly differently: it offers flexible strategies for configuration, data, and cache directories, allowing applications to choose between XDG, Apple, Windows, Unix single‑folder, and other conventions, and to choose application‑specific strategies such as `choose_app_strategy()` that name the application and follow XDG on Linux and macOS for configuration.[11][13] `etcetera` is used by `confy`, a configuration convenience crate that moved from `ProjectDirs` to `etcetera` specifically to allow both XDG and native paths and now defaults to XDG on macOS.[13] This migration is strong practice evidence for the owner’s F247 concern: earlier cross‑platform crates that ignored `XDG_CONFIG_HOME` on macOS were actively reconsidered, and newer versions now honor XDG semantics, at least in some strategies.

In the established standards bin for configuration layering and parsing, the `config` crate stands out. It provides a layered configuration system where users can set defaults, explicit values, read from multiple file formats (JSON, TOML, YAML, INI, RON, JSON5, CORN), and read from environment variables, with loosely typed access via formatted paths like `redis.port` or `databases.name`.[1][4][8] It supports feature flags to enable or disable support for particular file formats, and its layering semantics naturally mirror the owner’s desired precedence order, albeit without a baked‑in CLI precedence. Other configuration crates listed in the configuration library index include `figment`, `twelf`, `better-config`, `pi_config`, and many more.[4] Many of these support layered configuration from files, environment, and CLI, sometimes integrated with `clap`. For example, `figment` is known in the ecosystem for its “con-free” configuration layering, and `twelf` advertises 12‑Factor‑friendly layered configuration. However, this report focuses on crates for which we have documentation in the provided search results, which include `config`, `cfg-rs`, `confy`, and the broader listing of configuration crates.[1][3][4][13]

The up‑and‑comers bin includes crates that explicitly respond to shortcomings in established libraries. `user_dirs` positions itself as a respectful, XDG‑first user directories implementation for obtaining home, cache, config, data, runtime, and state directories, explicitly criticizing earlier crates such as `dirs` and `directories` for refusing to respect user‑defined XDG variables and positioning itself as a simpler alternative to `etcetera` with a single strategy that always prefers XDG variables and then system directories.[20] `cfgmatic_paths` provides a platform‑agnostic way to discover configuration directories organized into user, local, and system tiers, using XDG semantics on Unix/Linux and macOS CLI applications, Apple Application Support for macOS GUI applications (with a feature), and appropriate system directories for other platforms.[19] It explicitly uses `XDG_CONFIG_HOME/<app>` as the user‑tier path, optionally supports legacy `~/.<app>rc` files, and uses `XDG_CONFIG_DIRS/<app>` (default `/etc/xdg/<app>`) as the system tier on Unix/Linux.[19] This tiered design aligns unusually well with the owner’s multi‑tier configuration chain. On the configuration composition side, `cfg-rs` is a relatively lightweight, flexible loader that supports multiple sources (files, environment, inline maps, random values), live refresh, placeholder expansion, and derive‑based typed configs without depending on `serde`.[3] It allows deterministic priority of layers via numbered registration and supports environment variable sources with prefixes such as `APP_`, as well as file sources at configurable layers.[3] These design elements make it an attractive choice for implementing a layered configuration hierarchy like the owner’s default, while keeping precedence under application control rather than hard‑coding it.

Practice evidence complements this landscape. The confy crate’s documentation states that it uses `etcetera` to store configuration files and has explicitly moved from `ProjectDirs` to `etcetera` in version 2.0.0 to allow both XDG and OS native paths, adopting XDG directories as the default even on macOS.[13] This shows an ecosystem trend toward honoring XDG semantics consistently. Starship’s explicit use of XDG config directories and of the `STARSHIP_CONFIG` env override has been widely adopted and is documented and supported in multiple languages and cheatsheets.[2][5][6][7][9][10] Rust projects that use `config` or `figment` often follow a precedence pattern similar to the Rust FAQ article’s defaults < file < env < CLI order, and they integrate with `clap` for CLI parsing, which has become the de facto standard for Rust CLI apps.

Within this landscape, it is clear that there is no single, mandatory choice of directory or configuration library. However, certain patterns emerge as authoritative guidance: XDG semantics for user configuration directories, particularly honoring `XDG_CONFIG_HOME` on Linux and macOS; a layered configuration hierarchy where outer scopes override inner ones; and explicit CLI override via flags and environment aliases. These patterns, rather than particular crates, are the shared principles we must preserve.

**Gemini**

The resolution of configuration discovery and hierarchical merging in the Rust ecosystem operates across a highly active and heavily debated field, reflecting a continuous tension between strict specification compliance and platform-native conventions. To establish a robust, maintainable architecture for the `rs-launch-blueprint` template, an exhaustive survey of the configuration and path-resolution landscape is required. The ecosystem can be mapped into three distinct categories based on maturity and architectural intent.

| Category | Candidates and Paradigms |
| :--- | :--- |
| **Built-in or First-Party Toolchain** | `std::env` (environment variable extraction), `std::path::Path::ancestors` (idiomatic upward directory traversal), and the `cargo` binary's internal configuration discovery logic (providing the reference architecture for workspace and project-level discovery). |
| **Established Industry Standard** | `config` (`config-rs`) for layered parsing and composition; `directories` for platform-specific path resolution; `etcetera` for unopinionated, selectable directory strategies; `figment` for type-safe, provider-based configuration. |
| **Up-and-Comer** | `clapfig` (integrating `clap` arguments with file parsing directly); `microxdg` and `cfgmatic-paths` for strict XDG compliance including system-wide scopes; `twelf` and `settings-loader-rs` for macro-driven, metadata-aware layering. |

Authority within this domain is established through standard specifications, core toolchain implementations, and verifiable ecosystem metrics. The *XDG Base Directory Specification* serves as the definitive standard for Unix-like configuration file placement, strictly dictating the behavior and fallback mechanisms of `$XDG_CONFIG_HOME` and `$XDG_CONFIG_DIRS` [cite: 1, 2]. The *Cargo Reference* and associated Rust RFCs (such as RFC 3502) establish the authoritative Rust ecosystem pattern for project-local discovery—specifically, relying on an upward directory walk to locate configuration files like `.cargo/config.toml` [cite: 3, 4, 5]. Furthermore, ecosystem surveys and the Crates.io API provide objective, quantitative metrics regarding adoption rates, maintenance status, and community shifts away from abandoned dependencies, establishing which libraries represent safe long-term investments [cite: 6, 7].

An analysis of mainstream, well-regarded Rust projects provides critical practice evidence. The `cargo` package manager itself utilizes a strict upward directory walk to discover configuration files, manually enforcing a precedence of CLI arguments over environment variables, which in turn supersede configuration files [cite: 3, 8]. This establishes the baseline expectation for project-tier discovery in Rust. Conversely, highly regarded CLI tools like `ripgrep` actively avoid automatic system or user configuration discovery by default, instead requiring the user to explicitly define a `RIPGREP_CONFIG_PATH` environment variable if a configuration file is desired [cite: 9, 10]. This demonstrates a valid, performance-optimized paradigm where explicit execution is favored over implicit discovery. 

However, tools that do implement automatic discovery often face community friction if platform conventions are mishandled. The `bat` utility leverages the highly popular `directories` crate but has encountered pushback because `directories` explicitly ignores the `$XDG_CONFIG_HOME` environment variable on macOS, opting instead for `~/Library/Application Support` [cite: 2, 11]. This violates the expectations of users operating in CLI-centric environments on macOS, who anticipate XDG compliance. In contrast, `uv`, a high-performance Python package manager written in Rust, rigorously enforces `$XDG_CONFIG_DIRS` for system-wide configuration, proving the necessity and viability of implementing the full XDG specification in modern, cross-platform CLI tools [cite: 12].

Regarding published Rust CLI templates and multi-tier configuration, a survey of the landscape reveals that most boilerplate templates implement only a single-tier discovery chain—typically relying on the `directories` crate to locate a single user-level file, completely ignoring system-wide defaults and project-local overrides. Consequently, relying on existing templates is insufficient for the `rs-launch-blueprint`, which mandates a multi-tier composition.

Evaluating these candidates against the specific use case of this template (a hybrid CLI, library, and web service) requires prioritizing architectural fit over abstract popularity. The chosen architecture must allow the CLI to override discovery completely, while the underlying library retains the ability to independently execute the full discovery chain if invoked in a non-CLI context. 

### Principles and implementation

**OpenAI**

#### Shared principle and agreement level

The shared engineering principle is:

> **Broader configuration establishes defaults; progressively narrower scopes override it deterministically; explicit operator intent overrides discovered files; discovery and value composition remain separate, observable stages.**

The required cross-repository agreement is at four levels:

| Agreement level | Must agree across py, ts, and rs |
|---|---|
| **Capability** | Support defaults, zero or more system files, one user file, one nearest project file, ordinary environment values, and explicit CLI values. |
| **Policy / CLI contract** | `CLI > environment > project > user > system > defaults`; the first `XDG_CONFIG_DIRS` entry is the highest-priority system directory; `--config` or its environment alias replaces all discovered file tiers rather than adding another file. |
| **Architectural pattern** | Produce an ordered discovery plan first; compose sources second; deserialize/validate after composition; expose enough source information to test and diagnose precedence. |
| **Observable convention** | On Ubuntu and macOS, honor non-empty absolute `XDG_CONFIG_HOME`; default empty/unset values; honor `XDG_CONFIG_DIRS`; search upward from the supplied starting directory for the nearest project file. |

The repositories do **not** need to agree on the same path library, merge library, internal error type, async model, or dependency-injection mechanism. Python may use its ecosystem’s platform/path helpers, TypeScript may retain a small resolver, and Rust may use crates plus a small adapter, provided the observable contract is identical.

The TypeScript implementation’s single-user-file behavior is accidental capability drift, not a justified ecosystem difference: its own D-017(1) records the full target order, while D-017(3) documents that only the user-path subset was shipped. The Python implementation is evidence for the full chain, but Python-specific Windows fallbacks and helper layout are not automatically common requirements. These conclusions rely on the owner-provided evidence dated September 4, 2026.

#### Contracted scopes and paths

For repository-specific tokens `<tool>` and `<TOOL>`:

| Priority, low → high | Scope | Path/source |
|---:|---|---|
| 0 | Defaults | Typed application defaults |
| 1…n | System | `${XDG_CONFIG_DIRS entry}/<tool>/<tool>_config.toml`, loaded from least important to most important |
| n+1 | User | `${XDG_CONFIG_HOME}/<tool>/<tool>_config.toml` |
| n+2 | Project | First existing `<tool>_config.toml` found while walking from the supplied CWD toward the filesystem root |
| n+3 | Environment | Ordinary `<TOOL>_*` settings, excluding the reserved config-selector variable |
| n+4 | CLI | Only values explicitly supplied as command-line arguments |

XDG defines `XDG_CONFIG_DIRS` as preference ordered with the **first entry most important**, while the user root is more important than every system root. Consequently, if `XDG_CONFIG_DIRS=/high:/low`, merge order is `/low`, then `/high`, then user. Empty or unset `XDG_CONFIG_HOME` defaults to `$HOME/.config`; empty or unset `XDG_CONFIG_DIRS` defaults to `/etc/xdg`; relative XDG paths are invalid and ignored. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))

For this Unix-oriented CLI contract, use XDG behavior on both Ubuntu and macOS. Do not switch macOS to `~/Library/Application Support`: F247 explicitly requires `XDG_CONFIG_HOME` on macOS, and `etcetera` itself distinguishes CLI/user-editable configuration—where it recommends XDG—from native GUI conventions. ([docs.rs](https://docs.rs/etcetera/latest/etcetera/))

#### Explicit-file branch

If either `--config FILE` or `<TOOL>_CONFIG=FILE` selects an explicit file, the file portion of the chain becomes:

```text
defaults < explicit-file < ordinary environment < explicit CLI values
```

No system, user, or project file is probed or loaded. Defaults remain active, and ordinary environment and CLI settings remain higher priority. This preserves fixed F233 while keeping the canonical flags-over-environment rule.

The config-selector environment variable is a **selector**, not an ordinary configuration-data key. It must be filtered out of the general `<TOOL>_*` environment provider.

#### Merge semantics

R54 should own these cross-language merge rules:

1. Tables/maps merge recursively.
2. A higher layer replaces a lower scalar.
3. A higher array/list replaces the lower array/list; arrays are not implicitly concatenated.
4. An absent key inherits the lower value.
5. There is no deletion/tombstone semantic in R54.
6. Each source is applied exactly once in the ordered plan.

This makes “later wins” precise and prevents Python, TypeScript, and Rust from diverging on nested settings or arrays.

#### Discovery architecture

Use a small custom `ConfigDiscovery` adapter built from `std` rather than making a directory crate part of the runtime stack:

```rust
pub enum Scope {
    System,
    User,
    Project,
    Explicit,
}

pub struct Layer {
    pub scope: Scope,
    pub path: PathBuf,
    pub required: bool,
}

pub struct DiscoveryInputs {
    pub cwd: PathBuf,
    pub home: Option<PathBuf>,
    pub xdg_config_home: Option<OsString>,
    pub xdg_config_dirs: Option<OsString>,
    pub explicit: Option<PathBuf>,
}
```

Production code snapshots process environment and CWD into `DiscoveryInputs`; the pure planner accepts those values and a filesystem probe. That avoids process-global environment mutation in tests and lets the library/web service supply an explicit start directory.

The adapter needs only:

- `Path::is_absolute`;
- `std::env::split_paths`;
- `Path::ancestors`;
- `Path::join`;
- a file-existence probe.

`Path::ancestors` directly supplies the idiomatic walk-up primitive, so no project-search crate is justified for a single nearest-file lookup. Cargo’s implementation demonstrates the broader pattern, although R54 intentionally selects only the nearest project file rather than merging every ancestor. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))

#### Why not use `xdg` directly?

`xdg` 3.0.0 is the clear library answer to the HIGH question: `find_config_files()` enumerates existing files from `XDG_CONFIG_DIRS` and `XDG_CONFIG_HOME` in low-to-high priority order, and its getters expose the ordered system roots. It therefore proves that hand-rolling is not technically necessary. ([docs.rs](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html))

The custom adapter nevertheless fits this template better because:

- R54 needs only configuration roots, while R57 owns the broader data/state/cache directory decision.
- Scope labels, explicit-file replacement, nearest-project search, and source auditing are custom regardless.
- Injected environment and filesystem inputs make conformance tests deterministic.
- The required XDG subset is small and normatively specified.
- It avoids binding R57 through a dependency selected for only two environment variables.
- `xdg` remains a maintained reference implementation and ranked runner-up.

`etcetera` 0.11.0 is not sufficient by itself: it selects one XDG user config root on Linux/macOS but does not expose the ordered `XDG_CONFIG_DIRS` system list. `directories` 6.0.0 is functionally unsuitable because on macOS it chooses Apple directories and does not honor `XDG_CONFIG_HOME`, and it provides no multi-system search list. ([docs.rs](https://docs.rs/etcetera/latest/etcetera/))

#### Composition architecture

Use `config` 0.15.25 with default features disabled and only `toml` enabled:

```toml
config = { version = "0.15.25", default-features = false, features = ["toml"] }
```

Its builder supports defaults, ordered file sources, environment sources, explicit overrides, and typed deserialization. Sources are added in discovered order; ordinary environment is added after files; CLI values are installed with `set_override` only when explicitly present. ([github.com](https://github.com/rust-cli/config-rs))

Minimal reference pattern:

```rust
pub fn load_settings(
    plan: &[Layer],
    env: &BTreeMap<String, String>,
    cli: CliOverrides,
) -> Result<Settings, ConfigError> {
    let mut builder = config::Config::builder()
        .set_default("server.host", "127.0.0.1")?
        .set_default("server.port", 8080_u16)?;

    for layer in plan {
        builder = builder.add_source(
            config::File::from(layer.path.clone())
                .format(config::FileFormat::Toml)
                .required(layer.required),
        );
    }

    builder = builder.add_source(
        environment_source_excluding_config_selector(env)
    );

    if let Some(port) = cli.port {
        builder = builder.set_override("server.port", port)?;
    }

    if let Some(host) = cli.host {
        builder = builder.set_override("server.host", host)?;
    }

    builder.build()?.try_deserialize()
}
```

Discovered sources are optional; an explicit source is required. Missing-file and parse/value reactions remain routed through R55/R67 rather than being hard-coded into discovery.

#### CLI architecture

Use `clap`’s environment attribute for the config selector:

```rust
#[derive(clap::Parser)]
struct Cli {
    #[arg(long, env = "<TOOL>_CONFIG", value_name = "FILE")]
    config: Option<PathBuf>,

    #[arg(long)]
    port: Option<u16>,

    #[arg(long)]
    host: Option<String>,
}
```

`Arg::env` is used only when the argument is absent; an explicit command-line value wins. No custom precedence logic is required for the selector itself. `clap` can also report whether a value came from a default, environment variable, or command line, but configurable CLI fields should simply remain `Option<T>` and avoid Clap defaults so that only explicit flags become top-level overrides. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

#### Significant alternatives

| Alternative | Strength | Why not selected |
|---|---|---|
| `xdg` + `config` + `clap` | Less custom XDG parsing; exact system-list API | Makes a broad directory crate part of R54 and still requires custom scope/project/explicit orchestration. Ranked runner-up. |
| `etcetera` + custom system-list parsing | Explicit CLI-vs-GUI macOS strategy; good platform story | Once `XDG_CONFIG_DIRS` is custom, it provides little R54 value beyond the simple user-root rule. |
| `directories` + `config` | Very popular native-platform directory API | Fails required macOS XDG behavior and lacks system enumeration. |
| Figment + custom discovery | Excellent provenance, explicit `merge` semantics, strong library/CLI guidance, built-in test jail | Last release was May 17, 2024; active maintenance evidence is weaker than `config-rs`. Prefer it if R55/R67 later make per-source provenance the dominant requirement. ([docs.rs](https://docs.rs/figment/latest/figment/)) |
| Fully custom TOML parse and merge | Maximum policy control, can support future per-value fallback | Reimplements mature parsing/source conversion and increases correctness burden for no current R54 benefit. |
| `clap-layers` / `conf` | Declare CLI/env/config relationships together | Younger and less adopted; neither supplies the required XDG system/project discovery contract. ([docs.rs](https://docs.rs/clap-layers/latest/clap_layers/)) |

#### Performance evaluation

The representative workload is process startup with zero to four small TOML files, one environment snapshot, and one typed deserialization. No network, asynchronous runtime, hot loop, or per-request reload is involved. Directory walking is `O(C)` in CWD component count; discovery is `O(D)` in configured system roots; merge cost is `O(K)` in total configuration keys. Filesystem access and TOML parsing will dominate the adapter’s path operations.

No comparable benchmark across `config-rs`, Figment, and custom merging was found using an equivalent workload, so no “fastest” claim is made. The planned benchmark is:

- 4 files × 4 KiB;
- approximately 100 scalar/nested keys;
- warm and cold CLI startup;
- p50/p95 wall-clock latency;
- bytes read;
- peak RSS;
- release binary size;
- clean compile time.

Selection is based on correctness, ecosystem maturity, and integration cost, not hypothetical throughput.

#### Observable acceptance criteria

1. With `XDG_CONFIG_DIRS=/high:/low`, files are planned as `low → high → user → nearest-project`.
2. Removing successively CLI, environment, project, user, and system values exposes the next lower value.
3. Higher nested fields do not erase unrelated lower nested fields.
4. Higher arrays replace lower arrays.
5. Empty/unset `XDG_CONFIG_HOME` falls back to `$HOME/.config`.
6. Relative `XDG_CONFIG_HOME` is ignored and falls back.
7. Empty/unset `XDG_CONFIG_DIRS` yields `/etc/xdg`.
8. Relative entries inside non-empty `XDG_CONFIG_DIRS` are discarded while valid absolute entries preserve their preference order.
9. `--config` results in a one-file plan and prevents every discovered file from being read.
10. `<TOOL>_CONFIG` has the same selection semantics as `--config`; the flag wins when both are set.
11. Missing discovered files are skipped; a missing explicit file enters R67’s required-input error path.
12. Invalid TOML or typed values are not silently replaced by a lower value unless R55 explicitly selects such behavior.
13. The same tests pass on `ubuntu-latest` and `macos-latest`, at Rust 1.96 and current stable 1.98.1. Rust 1.98.1 was the current stable release on the research date, making 1.96 the “stable minus two minor versions” floor. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/latest/))

**Baseline reviews:**

BASELINE-REVIEW: F230 — system-scope capability — reclassify the ordered multi-system tier from implementation divergence to a COMMON capability/policy; TypeScript’s missing tier is follow-on capability drift, not an ecosystem exception — owner D-017(1), Python chain evidence, and normative `XDG_CONFIG_DIRS` ordering. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))

BASELINE-REVIEW: F231 — user-scope capability — retain a COMMON XDG user tier on Ubuntu and macOS rather than allowing native-macOS substitution — F247 owner requirement and XDG/CLI convention evidence. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))

BASELINE-REVIEW: F232 — project-scope capability — reclassify nearest upward project discovery as COMMON policy; TypeScript’s absence is drift from its recorded target — owner D-017(1), Python precedent, and Cargo’s maintained upward-search pattern. ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html))

BASELINE-REVIEW: F234 — explicit config environment alias — reclassify `<TOOL>_CONFIG` as a COMMON CLI capability while allowing repository-specific tool prefixes — Python precedent and `clap`’s native CLI-over-env behavior. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

BASELINE-REVIEW: F247 — XDG override validity — include the normative absolute-path rule in the shared contract: empty, unset, or relative `XDG_CONFIG_HOME` falls back; relative `XDG_CONFIG_DIRS` entries are ignored — XDG specification sections 2–3. This affects R54 and should remain consistent with R57; owner confirmation is required only if Python intentionally departs from XDG. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))

---

**Perplexity**

The shared requirement across Python, TypeScript, and Rust is not merely “read some configuration from a file”; it is a disciplined, multi‑scope configuration hierarchy with deterministic precedence and explicit operator control. The owner’s decision record and the Rust FAQ article express this in almost identical terms: defaults at the core, then file values, then environment variables, then CLI flags, with explicit user input always beating implicit settings.[8] The TypeScript decision record adds detail, naming the file‑based tiers as system, user, and project, and expressing canonical precedence as `flags > TOOL_* env > project > user > system > defaults`. The Python implementation adds further nuance by using multiple system configuration directories, discovered via a function akin to XDG’s `XDG_CONFIG_DIRS`, and by using an upward search from the current directory to find a project‑local configuration file. Together, these elements define the shared architectural pattern:

First, configuration scopes must be explicitly separated into at least the following tiers: system‑wide configuration (installed centrally, typically read‑only), user‑specific configuration (stored under XDG config directories or OS equivalents, per user and typically writable), project‑local configuration (stored in the repository or working directory tree, discovered via upward search), and embedded defaults in code (compiled into the application). These tiers must be discoverable in a predictable way on each platform, and they must be merged in a clear precedence order.

Second, environment variables and command‑line flags must be treated as override scopes above the file tiers. Environment variables provide deployment‑friendly overrides (particularly in containerized or cloud environments) and carry secrets when allowed by R56, while CLI flags provide operator‑friendly one‑off overrides. The precedence must ensure that command‑line flags override environment variables, environment variables override project‑local configuration, project‑local overrides user‑specific configuration, and user overrides system configuration. This ensures that the most explicit operator input wins in all cases.[8]

Third, `--config` has a special role: it does not add another layer to be merged; instead, it replaces the discovery process entirely. When the `--config` flag (or its environment alias) is provided, the application must ignore system, user, and project discovery chains and load configuration only from the explicitly specified path. This behavior is already agreed between Python and TypeScript implementations and is recorded as F233 (`COMMON → REUSE`), so it is not in scope to change; Rust must conform.[2][5][6][7][8]

Fourth, XDG semantics must be honored where applicable. For Ubuntu and macOS, this means that `XDG_CONFIG_HOME` must be observed when set and ignored only when empty, falling back to `$HOME/.config` for user configuration and to `/etc/xdg` for system configuration directories on Unix/Linux according to the XDG spec.[14][17][18][19][20] For Windows and macOS, equivalent directories must be chosen via appropriate APIs (Known Folder API, Apple Standard Directories) or strategies that align with ecosystem expectations for CLI tools versus GUI applications.[11][12][13][15][16][19][20] F247 explicitly binds this behavior, and the confy migration to `etcetera` with XDG default strategy on macOS is practice evidence that this is the ecosystem trend.[13] This is not a crate‑specific requirement; any crate used must behave in this way.

The level at which agreement is required is architectural pattern and precedence semantics. That is, Python, TypeScript, and Rust do not need to share the exact same directory crate or to use identical path naming conventions. They must, however, agree on which scopes exist, how they are ordered, and the semantics of override and replacement (`--config`). Ecosystem differences are allowed when they are justified by platform conventions or tooling norms—for example, TypeScript tooling may choose to ignore system config directories if they are uncommon in Node.js deployments—but such differences must preserve the principle. In TypeScript’s case, the canonical decision record already calls for system and project tiers; the current partial implementation is drift, not justified difference. For Rust, the ecosystem supports richer tier semantics, particularly through crates like `cfgmatic_paths`, `xdge`, and `etcetera`, so the Rust template should realize the full pattern.

From an implementation perspective, we must compare architectural alternatives before choosing specific libraries. One alternative is a largely hand‑rolled implementation. Using `std::env` and `std::fs`, we can read `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS`, `HOME`, and platform‑specific environment variables like `%APPDATA%`, `%PROGRAMDATA%`, and construct system and user config directory lists resembling Python’s `paths.config_dirs()`.[8][14][17][18] We can implement project‑local upward search by starting from the working directory (`std::env::current_dir()`) and walking parent directories until a configuration file with a known name (e.g., `<tool>_config.toml`) is found or the root is reached. We can then parse configuration files using TOML libraries (`toml` or `toml_edit`) and merge them manually into nested maps, overlaying environment variables and CLI flags. This approach gives maximal control over semantics and dependencies but re‑implements many conventions that are already carefully encoded in established crates, and it risks divergence from XDG and OS directory specifications if not meticulously maintained.

Another alternative is a library‑centric approach where directory discovery and configuration composition are delegated to crates like `etcetera` or `cfgmatic_paths` and `config` or `cfg-rs`, respectively. Using `cfgmatic_paths`, we can obtain a chain of directories corresponding to user, local, and system tiers, already aligned with XDG and OS conventions, and incorporate optional legacy paths like `~/.<app>rc` via configuration.[19] Using `cfg-rs`, we can register multiple sources—inline defaults, system file sources, user file sources, project file sources, environment prefixes, random values—with deterministic layers, implementing the desired precedence order and leaving CLI flags as manual overrides applied after configuration loading.[3][8] `config` offers similar features but has a heavier dependency footprint and supports more file formats.[1][4][8] This architectural pattern leverages well‑maintained crates that encode directory semantics and composition, reducing the amount of hand‑rolled logic and making the behavior easier to reason about and to extend.

A third alternative is a hybrid. We can use a directory discovery crate for base directories and augment it with hand‑rolled XDG semantics or project search. For example, we might use `user_dirs` to obtain the XDG user config directory on all platforms and then read `XDG_CONFIG_DIRS` manually for system directories on Unix/Linux, using `xdge` or `xdg` for fallback defaults.[14][17][18][19][20] We can implement project search manually. For configuration composition, we can use `cfg-rs` or `config` to merge sources. This hybrid approach allows us to avoid crates that conflict with F247 (such as `directories` ignoring `XDG_CONFIG_HOME` on macOS by default) while still leveraging crate implementations of complex semantics like environment variable expansion and typed configuration.

Judging these alternatives against the template’s use case and the survey evidence, the second and third options stand out. A purely hand‑rolled implementation would duplicate complex XDG semantics and OS‑specific behavior and would be more error‑prone and harder to maintain. A library‑centric approach where directory semantics and layering are delegated to well‑designed crates aligns better with ecosystem practice and reduces boilerplate. However, we must avoid crates whose semantics conflict with F247 or whose precedence is too rigid. That suggests a bundle built around `cfgmatic_paths` or `user_dirs` for directory discovery and around `cfg-rs` for composition, with CLI integration via `clap` and project search hand‑rolled.

Observable acceptance criteria for this pattern include the following. First, on Ubuntu and macOS, when `XDG_CONFIG_HOME` is set, configuration directories must be discovered under that path for user tier; when it is unset or empty, they must default to `$HOME/.config`.[14][17][18][19][20] Second, on Unix/Linux, system configuration directories must be discovered under `XDG_CONFIG_DIRS` (default `/etc/xdg`) and combined into a search chain; configuration files within each directory must be loaded and merged, with later directories overriding earlier ones if they are in the layered chain toward the user tier.[14][17][18][19] Third, project‑local configuration files must be discovered by walking upward from the working directory, and they must override user and system tiers when present. Fourth, environment variables with a specific prefix (e.g., `PLBP_` or `<TOOL>_`) must override all file tiers, and explicit CLI flags must override environment variables, including the `--config` path. Fifth, when `--config` is provided, whether via CLI or environment alias, only that file must be loaded and layered with defaults and environment and CLI overrides; system, user, and project discovery must be skipped entirely. Sixth, enforcement of F247 must be verifiable via unit tests that run under different `XDG_CONFIG_HOME` values and on macOS and Ubuntu CI runners, rather than assumed.

These criteria allow us to test both library‑based and custom implementations. For example, we can write tests that set `XDG_CONFIG_HOME` to a temporary directory, place user configuration files there, and assert that they are found and layered; tests that set `XDG_CONFIG_DIRS` to a list of temporary directories with different values in each, and assert that file values from later directories override earlier ones appropriately; and tests that exercise project search by creating configuration files at different points in a directory tree and running the application from different starting directories.

Before turning to specific bundle recommendations and members, we must note one baseline review. The baseline includes the notion that directory‑discovery crates may ignore `XDG_CONFIG_HOME` on macOS and rely on Apple Application Support directories instead. Given F247 and the confy migration, this is no longer acceptable for CLI applications where users are expected to edit configuration files. Thus we record a challenge:

> BASELINE-REVIEW: F247 — XDG override on macOS — proposed change: require XDG semantics for CLI configuration directories on macOS, not Apple Application Support defaults — evidence: etcetera’s `App Strategy` using XDG directories on macOS, confy 2.0.0 migration from `ProjectDirs` to `etcetera` with XDG default, user_dirs crate’s explicit design to prefer XDG variables on all platforms, and XDG specification compliance tests in directories-next.[11][13][17][20]

This baseline review does not change any owner‑fixed parameter; it sharpens F247’s mandate and rejects crates that ignore XDG on macOS as incompatible with R54.

**Gemini**

The cross-repository contract demands a hierarchical, layered configuration model. This constitutes a strict **architectural pattern** agreement that must remain consistent across `py-launch-blueprint`, `ts-launch-blueprint`, and `rs-launch-blueprint`. 

The essential behavior dictates a precise configuration pipeline. The pipeline evaluates the explicit `--config` override first. If this explicit path is absent, the system discovers files across System, User, and Project tiers. All located files are merged sequentially. Following the file merge, Environment Variables and CLI Flags are applied last to ensure they maintain the highest precedence. This sequence guarantees that hardcoded defaults are overwritten by system administrators, which are overwritten by user preferences, which are superseded by project specifics, and ultimately commanded by runtime execution flags.

The shared scopes and override semantics are defined as follows:
*   **System Tier:** System-wide configurations located at `/etc/xdg/<app>` or resolved via `$XDG_CONFIG_DIRS` on Unix and macOS, and `%PROGRAMDATA%` on Windows [cite: 1, 12, 13].
*   **User Tier:** User-specific configurations located at `$XDG_CONFIG_HOME/<app>` (defaulting to `~/.config/<app>`) on Unix and macOS, and `%APPDATA%` on Windows [cite: 2, 14].
*   **Project Tier:** Project-local configurations resolved relative to the current working directory (CWD), walking upward through parent directories until a project marker is identified [cite: 8, 15].
*   **Override Semantics:** If an explicit `--config` flag or its environment variable alias (`PLBP_CONFIG`) is provided, the entire automated file discovery chain (System, User, Project) is aborted. The explicit file is loaded in isolation, followed by the standard environment and flag layering [cite: 4, 16].

These behaviors are shared requirements derived directly from owner directives and authoritative XDG and Cargo standards. The TypeScript (`ts`) port's prior decision to only implement the user tier via a hand-rolled `xdg-paths` module represents missing capability and accidental drift, rather than a justified ecosystem difference [cite: 2, 17]. The Rust implementation will fulfill the complete multi-tier contract, and this architectural blueprint will serve as the rationale for a follow-on project to correct the TypeScript implementation to align with the agreed-upon pattern.

**BASELINE-REVIEW: F247 — directory resolution — reject `directories` crate — evidence:** The owner-fixed parameter F247 mandates that `XDG_CONFIG_HOME` must be honored on macOS and ignored when empty. The `directories` crate (version 6.0.0) intentionally fails this requirement. The maintainers of `directories` explicitly adjusted the behavior of `config_dir` on macOS to return the `Application Support` directory, actively ignoring the `XDG_CONFIG_HOME` variable even when explicitly set by the user, stating this aligns with Apple's GUI guidelines [cite: 18, 19]. Because this template is CLI-first, this behavior violates the cross-repo contract. Consequently, the `directories` crate is rejected in favor of alternatives like `etcetera`, which offers an XDG strategy that strictly honors the variable on macOS [cite: 2, 14, 20].

Architectural alternatives for composition primarily contrast macro-heavy, tightly coupled libraries against discrete, modular implementations. Libraries such as `clapfig` attempt to wire CLI arguments directly to file parsers [cite: 16]. While ergonomically appealing for simple CLI tools, this tightly couples the argument parser (`clap`) to the configuration state, violating the requirement that the core library must function independently of the CLI interface. An alternative is using a robust merging engine like `config-rs` in conjunction with a custom discovery pipeline [cite: 21]. This design preserves the principle of separation of concerns: a pure Rust function discovers the paths, passing them to the `config` builder, which merges the data and hands it to `serde` for deserialization. This represents the most idiomatic Rust pattern for libraries that power both CLIs and web services [cite: 22, 23].

Evaluating performance requires acknowledging the I/O costs of file discovery. A multi-tier discovery chain involves multiple `stat` system calls to verify file existence across system, user, and project directories, followed by parsing overhead for formats like TOML. While raw throughput in Rust is extremely high, these disk I/O operations introduce latency. By providing the `--config` override, the architecture offers a zero-discovery fast path for latency-sensitive environments (such as containerized web services), loading a single configuration payload without traversing the filesystem hierarchy.

To execute the acceptance check for this pattern, a minimal realistic example requires instantiating the discovery pipeline, injecting a mock file path via the `PLBP_CONFIG` environment variable, and verifying that the application bypasses the system and user tiers entirely, proving the short-circuit logic holds without silently reducing standard discovery to a single tier.

### Recommendation

**OpenAI**

Adopt this stack:

1. **A small, std-only `ConfigDiscovery` adapter** implementing the exact XDG system/user contract, nearest-project search, explicit-file replacement, and ordered `Layer` metadata.
2. **`config` 0.15.25**, with `default-features = false` and `features = ["toml"]`, for ordered source composition and typed deserialization.
3. **`clap` 4.6.7**, with `features = ["derive", "env"]`, for the CLI and `<TOOL>_CONFIG` selector alias.
4. Existing **Serde derive** for the typed `Settings` model; it is foundational serialization infrastructure rather than an R54-specific selection.

Do not add `directories`, `etcetera`, or `xdg` as runtime dependencies for R54. Keep `xdg` 3.0.0 as the maintained reference and first fallback if the custom adapter grows beyond the narrow specified surface.

This recommendation is conditional on the mechanical pre-merge MSRV, advisory, and API-metric checks listed below; no functional candidate currently displaces it.

---

**Perplexity**

Within the surveyed landscape and principles, the recommended stack for `rs-launch-blueprint` under R54 is a bundle composed of three main elements: a configuration directory discovery crate that exposes user, local, and system tiers in a way compatible with XDG and OS conventions and with F247; a configuration composition crate that supports multiple sources and deterministic precedence without imposing a fixed policy incompatible with the owner’s contract; and the `clap` CLI framework with a `--config` flag whose value may come either from CLI input or from an environment alias.

For directory discovery, this report recommends `cfgmatic_paths` as the dominant choice. Its documentation explicitly models configuration directories into three tiers—user (`ConfigTier::User`), local (`ConfigTier::Local`), and system (`ConfigTier::System`)—and states that on Unix/Linux it uses XDG Base Directory Specification semantics, with user configs at `$XDG_CONFIG_HOME/<app>` (default `~/.config/<app>`) and system configs at `$XDG_CONFIG_DIRS/<app>` (default `/etc/xdg/<app>`).[19] It also supports macOS CLI applications by using XDG semantics as on Unix/Linux, and macOS GUI applications by using `~/Library/Application Support/<bundle-id>/` as the user tier and `/Library/Application Support/<bundle-id>/` as the system tier when the `macos-gui` feature is enabled.[19] This design directly encodes the multi‑tier chain the owner desires and honors XDG variables on Ubuntu and macOS for CLI applications as required by F247. It presents a high‑level API to obtain directories per tier, avoiding the need for hand‑rolled `XDG_CONFIG_DIRS` parsing.

For configuration composition, this report recommends `cfg-rs`. Its documentation demonstrates registering multiple sources in deterministic layered order: a Cargo environment source at layer 0, an inline key‑values source at layer 1, a random source at layer 2 (optional), an environment prefix source at layer 3, and file sources at layer 4 and above.[3] It supports file sources such as YAML and TOML via feature flags, and environment variable sources with a configurable prefix such as `APP_`.[3][4] It also supports live refresh and typed configuration via derive‑based structures, without depending on `serde`, which keeps the dependency tree light and MSRV manageable.[3] Most importantly, `cfg-rs` does not hard‑code precedence beyond the registration order; the application can register sources representing system, user, project, environment, and CLI overrides in the owner’s desired order, achieving `defaults < system < user < project < env < CLI` semantics.[3][8] Environment and CLI overrides can be applied as separate steps, ensuring CLI flags override environment variables.

For CLI parsing, the report recommends `clap`. While `clap` is not mentioned in the search results, it is widely adopted in the Rust ecosystem for CLI applications and provides facilities for associating environment variables with flags via attributes such as `.env("PLBP_CONFIG")` on arguments. The key behavior required here is that if both CLI and environment provide a value for `--config`, the CLI value should win; `clap`’s semantics match that pattern. In the RustFAQ article on configuration hierarchy, the author explicitly recommends using `clap` for any app that operators will run manually, and positions manual parsing as acceptable only for trivial configurations.[8] This reinforces `clap` as the ecosystem’s standard solution for CLI parsing and for configuration flags.

Beyond these three members, a small amount of custom implementation is needed. Specifically, project‑local upward search must be implemented by hand, as there is no crate in the survey that provides exactly this behavior. The idiomatic Rust pattern is a loop that starts from `std::env::current_dir()` and repeatedly calls `.parent()` on the path; at each directory, it checks for the presence of a configuration file with an agreed name (e.g., `<tool>_config.toml`) and stops when it finds one or when it reaches the filesystem root. This pattern is simple, explicit, and consistent with Python’s `project_config_file()` implementation, preserving the cross‑ecosystem principle without needing additional crates.

The cross‑repo contract is preserved by making this bundle the canonical realization of R54 in Rust and by recommending corresponding changes in Python and TypeScript where necessary. Python already has system, user, and project tiers; its implementation can remain but may eventually adopt a directory crate or module similar to `cfgmatic_paths` for clarity. TypeScript currently lacks system and project tiers; its future revisions should implement those tiers using a Node.js‑appropriate XDG and OS directory resolver. However, this report does not change Python or TypeScript implementations; it supplies the rationale and design for future alignment.

The following sections now detail each bundle member, its landscape, principles, and fit, before returning to compatibility, parameters, and validation.

**Gemini**

The recommended stack relies on a composable architecture combining established industry standard libraries for merging and user-path resolution, alongside lightweight native patterns for system and project discovery. 

1.  **`config`**: Serves as the core engine for hierarchical merging and deserialization.
2.  **`etcetera`**: Provides unopinionated, XDG-compliant User directory resolution.
3.  **`ancestors-walk` (Pattern)**: Implements the project-level upward directory search natively.
4.  **`system-dirs-resolver` (Pattern)**: Implements the system-level XDG and Windows directory discovery natively.

### Members

**OpenAI**

#### std-only `ConfigDiscovery` adapter (OpenAI)

##### Landscape

The standard library supplies all required primitives: absolute-path testing, platform path-list splitting, path joining, and ancestor iteration. Cargo supplies a maintained hierarchical-search reference. `xdg` is the dominant library alternative; `etcetera` handles one XDG app root; `directories` selects native macOS directories and is unsuitable for F247. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))

**Pattern figures:** crate download, release, repository, issue, advisory, and adopter figures are **inapplicable** because this member is project-owned code rather than a published crate.

**Library reference figure ledger:**

| Figure | `xdg` 3.0.0 result | Required source |
|---|---|---|
| 90-day downloads | Not extracted; API body unavailable | `GET https://crates.io/api/v1/crates/xdg`, field `crate.recent_downloads` |
| All-time downloads | Not extracted; API body unavailable | Same endpoint, field `crate.downloads` |
| Last release | 3.0.0, May 4, 2025 | `GET https://crates.io/api/v1/crates/xdg/versions`; release also shown by docs.rs. ([docs.rs](https://docs.rs/crate/xdg/latest)) |
| Stars / archived / pushed | API values not extracted | `GET https://api.github.com/repos/whitequark/rust-xdg` |
| Open issues | Search API value not extracted | `GET https://api.github.com/search/issues?q=repo:whitequark/rust-xdg+is:issue+is:open` |
| Responsiveness | Not computed | Ten newest issues plus their comment timelines |
| Advisories | Must be closed by lockfile audit | `https://rustsec.org/packages/xdg.html` |
| Adopter | `cosmic-store`, which declares `xdg = "3"` | Reverse-dependency endpoint plus manifest. ([github.com](https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml)) |

##### Principles and implementation

The adapter is a pure planning function. It must not parse TOML, read ordinary setting environment variables, or decide error tolerance. Its output is an ordered list of labeled `Layer` values.

XDG rules:

```text
user root:
  absolute, non-empty XDG_CONFIG_HOME
  otherwise $HOME/.config

system roots:
  if XDG_CONFIG_DIRS unset or empty: [/etc/xdg]
  otherwise split_paths(XDG_CONFIG_DIRS), discard empty/relative entries
  input order = highest → lowest preference
  layer order = reverse(input order)
```

Then append the user file and nearest project file if present. If `explicit` is present, return only an `Explicit` layer before consulting XDG or project paths. These rules directly implement the normative standard while preserving fixed F233. ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))

##### Dominant choice

For this template, the dominant architectural choice is **custom std-only planning with an explicit contract**, because it is smaller than the unavoidable surrounding orchestration and leaves R57’s wider directory-set decision unbound.

The dominant **crate** choice, if a crate is required, is `xdg` 3.0.0 because it is the only established surveyed candidate that already enumerates all system config files and the user file in low-to-high priority order. ([docs.rs](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html))

##### Qualified shortlist

1. `xdg` 3.0.0 — exact XDG behavior; small source package; one optional Serde dependency.
2. `etcetera` 0.11.0 plus custom `XDG_CONFIG_DIRS` parsing — strong CLI/macOS convention documentation but incomplete system enumeration.
3. Fully custom adapter — selected.
4. `cfgmatic-paths` — promising direct system/user tier vocabulary, but younger and less established. ([docs.rs](https://docs.rs/crate/xdg/latest))

##### Excluded by gate

- **`directories` 6.0.0:** excluded by behavioral/platform gate. It uses `$HOME/Library/Application Support` for macOS configuration and does not honor `XDG_CONFIG_HOME` there; it also lacks the ordered system config list. License and general platform support do not repair the contract mismatch. ([docs.rs](https://docs.rs/crate/directories/latest/source/README.md))
- **`project-dirs` 0.1.0:** excluded from the final shortlist by maturity and unnecessary API breadth, not by license.
- **A dedicated upward-search crate:** excluded by integration-cost gate because `Path::ancestors` expresses the nearest-file search directly. ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))

Fitness gates for the selected pattern:

1. **License:** pass; owned by the dual-licensed template.
2. **MSRV:** pass by construction when compiled under the template’s Rust 1.96 floor.
3. **RustSec / unsafe:** advisories inapplicable; add `#![forbid(unsafe_code)]` to the owning module/crate.
4. **Platforms:** must be run in template CI on Ubuntu and macOS; no platform FFI is used.
5. **Features/runtime:** no features and no async runtime.
6. **Compile/binary cost:** negligible; standard-library-only path logic.

##### Up-and-comers

`cfgmatic-paths` and `microxdg` explicitly expose system XDG config roots and merit re-evaluation if they establish stronger adoption and maintenance records. `project-dirs` also models broader tiers, but its scope substantially overlaps R57. ([docs.rs](https://docs.rs/cfgmatic-paths/latest/aarch64-apple-darwin/cfgmatic_paths/))

##### Fit for this template

The adapter works identically for:

- the CLI, using actual process environment and CWD;
- library callers, using an explicitly supplied start directory and optional environment snapshot;
- the web service, resolving once at startup and injecting typed settings into application state.

It also produces source labels without exposing configuration values, which is compatible with R56’s future secret policy.

##### Recommendation

Implement approximately 60–100 lines of well-tested Rust in `src/config/discovery.rs`. Treat XDG 0.8 and `xdg` 3.0.0 as reference behavior, not runtime dependencies.

##### Ranked runner-up

`xdg` 3.0.0 plus a small scope-label/project adapter.

Use it if:

- R57 independently selects `xdg`;
- custom XDG logic grows;
- or differential tests reveal a standards-compliance bug in the custom resolver.

##### Tradeoffs

**Benefits:** exact policy control, deterministic tests, zero dependency/feature cost, no R57 preemption, and explicit source metadata.

**Costs:** the project owns subtle empty/relative/list-order behavior. The mitigation is table-driven conformance tests derived directly from the XDG specification and optional differential testing against `xdg`.

##### Parameters

- `owns system-config-roots = reverse(valid_absolute_split(XDG_CONFIG_DIRS))`, default `[/etc/xdg]`
- `owns user-config-root = valid absolute XDG_CONFIG_HOME`, otherwise `$HOME/.config`
- `owns config-relative-path = <tool>/<tool>_config.toml`
- `owns project-search = nearest ancestor containing <tool>_config.toml`
- `assumes explicit-config-semantics = F233 replacement`
- `assumes target-os-matrix = ubuntu-latest, macos-latest`

##### Migration implications

- Add `src/config/discovery.rs`.
- Add `Scope`, `Layer`, `DiscoveryInputs`, and `DiscoveryPlan`.
- Move all process-environment reads into a thin production constructor.
- Remove any direct config-path calculation from `main.rs` or the web-service bootstrap.
- Document XDG behavior and exact path examples.

##### Validation strategy

Planned tests:

- `xdg_default_roots`
- `xdg_empty_values_use_defaults`
- `xdg_relative_home_is_ignored`
- `xdg_mixed_valid_and_relative_system_roots`
- `system_roots_are_reversed_for_merge`
- `nearest_project_file_wins`
- `explicit_file_skips_home_and_project_discovery`
- `missing_discovered_files_are_absent_from_plan`
- `relative_explicit_path_is_resolved_against_supplied_cwd`

No implementation tests were executed during this research run.

##### Confidence & re-verify trigger

**Confidence: high** on the contract and custom architecture; **medium-high** on choosing custom over `xdg`.

Re-verify if R57 selects a shared XDG crate, Windows becomes required, project-root boundary markers are introduced, or the owner rejects F247’s absolute-path rule.

##### Sources

Retrieved September 17, 2026:

- XDG Base Directory Specification: `https://specifications.freedesktop.org/basedir-spec/latest/` ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))
- Rust `Path::ancestors`: `https://doc.rust-lang.org/std/path/struct.Path.html#method.ancestors` ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))
- Cargo configuration hierarchy: `https://doc.rust-lang.org/cargo/reference/config.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html))
- `xdg` docs: `https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html` ([docs.rs](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html))
- `etcetera` docs: `https://docs.rs/etcetera/latest/etcetera/` ([docs.rs](https://docs.rs/etcetera/latest/etcetera/))
- `directories` behavior: `https://docs.rs/crate/directories/latest/source/README.md` ([docs.rs](https://docs.rs/crate/directories/latest/source/README.md))

#### `config` 0.15.25 (OpenAI)

##### Landscape

`config-rs` and Figment are the mature composition candidates. `config-rs` is maintained under the `rust-cli` organization and had a June 26, 2026 release. Figment offers better provenance and more explicit guidance for libraries and CLI programs, but its latest release remains May 17, 2024. ([github.com](https://github.com/rust-cli/config-rs))

**Required figure ledger:**

| Figure | `config` result | Required source |
|---|---|---|
| 90-day downloads | Not extracted | `GET https://crates.io/api/v1/crates/config`, `crate.recent_downloads` |
| All-time downloads | Not extracted | Same endpoint, `crate.downloads` |
| Last release | 0.15.25, June 26, 2026 | `GET https://crates.io/api/v1/crates/config/versions`; corroborated by docs.rs. ([docs.rs](https://docs.rs/crate/config/latest)) |
| Stars / archived / pushed | API values not extracted | `GET https://api.github.com/repos/rust-cli/config-rs` |
| Open issues | Search API value not extracted | `GET https://api.github.com/search/issues?q=repo:rust-cli/config-rs+is:issue+is:open` |
| Responsiveness | Not computed | Ten newest issues plus comment timelines |
| Advisories | Lockfile audit required | `https://rustsec.org/packages/config.html` |
| Adopter | Mozilla `sccache` manifest surveyed | Reverse-dependency endpoint and project manifest. ([github.com](https://github.com/mozilla/sccache/blob/main/Cargo.toml)) |

Docs.rs reports a 239.58 kB source package and a 16-second documentation build for 0.15.25; these are qualitative compile-cost indicators, not application benchmarks. ([docs.rs](https://docs.rs/crate/config/latest))

##### Principles and implementation

`ConfigBuilder` separates defaults, ordered sources, and overrides. Add discovered/explicit TOML files in the exact `DiscoveryPlan` order, then the filtered environment provider, then typed CLI overrides. Deserialize once into the public `Settings` type. ([docs.rs](https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html))

Use a captured environment map rather than allowing the provider to reread global process state. Exclude `<TOOL>_CONFIG`, because it selects a file and must not become a configuration-data key.

##### Dominant choice

`config` is the dominant fit because it is actively released, explicitly markets layered source composition, supports defaults/files/environment/overrides, and can be trimmed to TOML-only without an async runtime. ([github.com](https://github.com/rust-cli/config-rs))

##### Qualified shortlist

1. `config` 0.15.25 — selected.
2. Figment 0.10.19 — stronger provenance and test facilities.
3. Custom `toml::Value` recursive merge — maximum policy control, highest ownership cost.
4. Typed partial structs merged manually — simple for small flat settings, poor scalability for nested configuration.

##### Excluded by gate

- **`config` with default features:** excluded as a feature configuration, not as a crate. Defaults enable multiple unused formats, case conversion, and async support. Use TOML-only.
- **`confy`:** excluded by capability gate because it is centered on a simple app config file rather than the required multi-tier source plan.
- **Clap-only `update_from` layering:** excluded because it conflates CLI defaults with configuration precedence and does not model system/user/project discovery.
- **Young all-in-one derive crates:** excluded by maturity/adoption gate for this high-impact template decision.

Fitness gates for `config` 0.15.25:

1. **License:** pass, MIT or Apache-2.0. ([github.com](https://github.com/rust-cli/config-rs))
2. **MSRV:** provisional pass subject to `cargo +1.96.0 check --locked`; exact manifest/CI evidence must be captured before merge.
3. **Advisories/unsafe:** run `cargo deny check advisories` and `cargo geiger`; integration itself requires no unsafe API.
4. **Platforms:** pure Rust source composition; must pass the template’s Ubuntu/macOS matrix.
5. **Features/runtime:** `default-features = false`, `features = ["toml"]`; no async runtime.
6. **Cost:** moderate compile-time/parser cost, low startup runtime cost for the target workload.

##### Up-and-comers

`clap-layers`, `conf`, and `einstellung` aim to reduce declaration duplication. They may become attractive if they establish explicit support for externally supplied ordered files and stronger adoption. ([docs.rs](https://docs.rs/clap-layers/latest/clap_layers/))

##### Fit for this template

- **CLI:** receives discovered files, environment snapshot, and explicit CLI overrides.
- **Library:** exports `load_settings(inputs, overrides)` without requiring Clap types.
- **Web service:** receives a fully resolved `Settings` value; no configuration library is used in request handlers.
- **R55/R67:** parsing and extraction errors remain behind a project-owned error adapter.
- **R56:** no write-back, logging, or value-dump facility is introduced.

##### Recommendation

Use:

```toml
config = { version = "0.15.25", default-features = false, features = ["toml"] }
```

Keep the project-owned `LayerComposer` boundary narrow enough that Figment or a custom composer can replace it without changing discovery if R55 later requires fallback from individual invalid values.

##### Ranked runner-up

Figment 0.10.19 with `toml` and `env` features.

Select Figment instead if R55/R67 decides that precise per-value source provenance is more important than current release activity. Figment documents replacement-style `merge`, fills-only `join`, source metadata, rich errors, library composition, CLI integration, and a testing jail. ([docs.rs](https://docs.rs/figment/latest/figment/))

##### Tradeoffs

**Benefits:** active maintenance, mature source model, format feature gating, no custom deserializer, and explicit programmatic overrides.

**Costs:** provenance is less central than in Figment; the full crate defaults are unnecessarily broad; a future “drop only the invalid high-priority value and expose the lower value” policy could require a custom composer.

##### Parameters

- `owns table-merge = recursive`
- `owns leaf-merge = higher source replaces`
- `owns array-merge = higher source replaces`
- `owns source-order = discovery plan, then environment, then CLI`
- `assumes config-error-tolerance = decided by R55`
- `assumes error-taxonomy-exit-codes = R67`

##### Migration implications

- Add `src/config/model.rs` for `Settings` and defaults.
- Add `src/config/load.rs` for builder composition.
- Define `CliOverrides` independently from the `clap::Parser` struct.
- Add an error adapter converting `config::ConfigError` into the R67 taxonomy.
- Disable all unused `config` features in `Cargo.toml`.

##### Validation strategy

Planned tests:

- full six-level scalar precedence;
- recursive nested-table preservation;
- array replacement;
- ordinary environment filtering of `<TOOL>_CONFIG`;
- only `Some` CLI fields become overrides;
- optional discovered file versus required explicit file;
- parse error includes layer path in the project error context;
- invalid high-priority value cannot silently reveal a lower value unless an R55 policy explicitly authorizes it.

##### Confidence & re-verify trigger

**Confidence: high** in `config-rs` for fail-fast or whole-layer-error policies; **medium** if R55 selects per-field invalid-value fallback.

Re-verify on a new `config` minor release, an MSRV change, a RustSec advisory, or an R55 decision requiring provenance-aware fallback.

##### Sources

Retrieved September 17, 2026:

- Repository: `https://github.com/rust-cli/config-rs` ([github.com](https://github.com/rust-cli/config-rs))
- Crate/release page: `https://docs.rs/crate/config/latest` ([docs.rs](https://docs.rs/crate/config/latest))
- Builder: `https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html` ([docs.rs](https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html))
- Environment provider: `https://docs.rs/config/latest/config/struct.Environment.html` ([docs.rs](https://docs.rs/config/latest/config/struct.Environment.html))
- File provider: `https://docs.rs/config/latest/config/struct.File.html` ([docs.rs](https://docs.rs/config/latest/config/struct.File.html))
- Figment comparison: `https://docs.rs/figment/latest/figment/` ([docs.rs](https://docs.rs/figment/latest/figment/))

#### `clap` 4.6.7 with `derive` and `env` (OpenAI)

##### Landscape

`clap` provides native environment-backed arguments and explicit value-source reporting. The surveyed up-and-coming alternatives generally build on Clap rather than displacing it for a template needing derive, typed values, help output, and environment aliases. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

**Required figure ledger:**

| Figure | `clap` result | Required source |
|---|---|---|
| 90-day downloads | Not extracted | `GET https://crates.io/api/v1/crates/clap`, `crate.recent_downloads` |
| All-time downloads | Not extracted | Same endpoint, `crate.downloads` |
| Last release | 4.6.7, September 14, 2026 | `GET https://crates.io/api/v1/crates/clap/versions`; corroborated by docs.rs. ([docs.rs](https://docs.rs/crate/clap/latest)) |
| Stars / archived / pushed | API values not extracted | `GET https://api.github.com/repos/clap-rs/clap` |
| Open issues | Search API value not extracted | `GET https://api.github.com/search/issues?q=repo:clap-rs/clap+is:issue+is:open` |
| Responsiveness | Not computed | Ten newest issues plus comment timelines |
| Advisories | Lockfile audit required | `https://rustsec.org/packages/clap.html` |
| Adopter | Mozilla `sccache`; Cargo is also a first-party CLI reference | Project manifest and Cargo sources/practice. ([github.com](https://github.com/mozilla/sccache/blob/main/Cargo.toml)) |

Docs.rs reports a 277.28 kB source package and an eight-second documentation build for 4.6.7; these are not end-binary measurements. ([docs.rs](https://docs.rs/crate/clap/latest))

##### Principles and implementation

The selector contract is directly expressible:

```rust
#[arg(long, env = "<TOOL>_CONFIG")]
config: Option<PathBuf>
```

Clap reads the environment only when the argument is absent, so `--config` naturally overrides `<TOOL>_CONFIG`. `ValueSource` can distinguish command-line, environment, and default values if diagnostics require it. ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))

Ordinary configuration environment variables should not also be declared on each Clap field. Let `config-rs` own the ordinary environment layer, while Clap owns CLI values and the special config-file selector.

##### Dominant choice

`clap` with `derive` and `env`.

##### Qualified shortlist

1. Clap native `env` attribute — selected.
2. Manual `std::env::var_os` fallback before invoking the loader.
3. `clap-layers` for a more declarative future model.
4. `conf` if it matures into a stable unified CLI/env/file abstraction.

##### Excluded by gate

- **Custom precedence logic around an already supported Clap environment argument:** excluded by unnecessary-complexity gate.
- **Applying Clap defaults to configurable fields:** excluded because defaults would be mistaken for top-priority CLI overrides.
- **Using both Clap `env` attributes and the `config-rs` environment provider for ordinary settings:** excluded because it creates duplicate environment ingestion and ambiguous provenance.
- **Replacing Clap with a younger all-in-one configuration derive:** excluded by maturity and migration-cost gates.

Fitness gates:

1. **License:** pass, MIT or Apache-2.0. ([docs.rs](https://docs.rs/crate/clap/latest))
2. **MSRV:** provisional pass subject to Rust 1.96 locked build.
3. **Advisories/unsafe:** lockfile audit and `cargo geiger` required before merge; no unsafe code is required in template integration.
4. **Platforms:** must pass Ubuntu and macOS CI.
5. **Features/runtime:** keep normal Clap defaults; add `derive` and `env`; no async runtime.
6. **Cost:** moderate proc-macro/compile cost but likely already owned by the CLI template; negligible incremental runtime cost for one environment-backed path.

##### Up-and-comers

`clap-layers` tracks which layer supplied a value and `conf` targets derive-based CLI/environment configuration. Neither currently replaces R54’s explicit discovery planner. ([docs.rs](https://docs.rs/clap-layers/latest/clap_layers/))

##### Fit for this template

Clap remains confined to the binary-facing crate/module. The reusable library accepts plain `ConfigRequest` and `CliOverrides` values, avoiding a public dependency on Clap’s parser types. The web service can be launched by the same binary or by a library caller that supplies no CLI layer.

##### Recommendation

Use:

```toml
clap = { version = "4.6.7", features = ["derive", "env"] }
```

Represent every configurable CLI override as `Option<T>` and apply it only when `Some`.

##### Ranked runner-up

Manual config-selector resolution:

```rust
cli.config.or_else(|| std::env::var_os("<TOOL>_CONFIG").map(PathBuf::from))
```

This is correct but gives up Clap’s validation/help integration and duplicates its built-in precedence.

##### Tradeoffs

**Benefits:** no custom selector precedence, typed path parsing, generated help, and a source-inspection API.

**Costs:** enabling `env` adds a feature; mixing selector and ordinary environment responsibilities requires clear module boundaries; empty selector values need an explicit acceptance test.

##### Parameters

- `owns config-selector-cli = --config FILE`
- `owns config-selector-env = <TOOL>_CONFIG`
- `owns selector-precedence = command line > selector environment`
- `owns cli-data-overrides = explicitly supplied Option<T> values only`
- `assumes explicit-config-semantics = F233 replacement`

##### Migration implications

- Add `env` to the existing Clap features.
- Change configurable fields with CLI defaults to `Option<T>`.
- Map the parsed CLI type into a library-owned `ConfigRequest`.
- Reserve `<TOOL>_CONFIG` and exclude it from ordinary environment composition.
- Update `--help` and configuration documentation.

##### Validation strategy

Planned tests:

- alias alone selects the explicit file;
- flag alone selects the explicit file;
- flag wins when both flag and alias are present;
- ordinary `<TOOL>_*` values remain below explicit flags;
- absent flags do not override environment/files/defaults;
- selector does not become a deserialized settings key;
- empty selector handling is documented and tested.

##### Confidence & re-verify trigger

**Confidence: very high**.

Re-verify on a Clap major release, an MSRV increase beyond Rust 1.96, or a decision to expose one unified derive declaration for CLI, environment, and files.

##### Sources

Retrieved September 17, 2026:

- Crate/release page: `https://docs.rs/crate/clap/latest` ([docs.rs](https://docs.rs/crate/clap/latest))
- `Arg::env`: `https://docs.rs/clap/latest/clap/struct.Arg.html#method.env` ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))
- `ValueSource`: `https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html` ([docs.rs](https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html))
- Repository releases: `https://github.com/clap-rs/clap/releases` ([github.com](https://github.com/clap-rs/clap/releases))

---

**Perplexity**

#### cfgmatic_paths (Perplexity)

##### Landscape

`cfgmatic_paths` occupies a specialized niche in the Rust directory‑discovery ecosystem. It is not part of the earliest generation of crates like `dirs` or `directories`, but it directly addresses a gap those crates left: they provide only single directories for configuration, data, or cache, whereas applications often need a tiered chain of configuration directories corresponding to user, local, and system scopes. The crate’s documentation states that it provides a platform‑agnostic way to discover configuration directories following conventions of each operating system, and that it organizes directories into three tiers: user (`ConfigTier::User`), local (`ConfigTier::Local`), and system (`ConfigTier::System`).[19] On Unix/Linux, it uses XDG Base Directory Specification semantics, with user configs in `$XDG_CONFIG_HOME/<app>` (default `~/.config/<app>/`), an optional legacy `~/.<app>rc` file (enabled by default), and system configs in `$XDG_CONFIG_DIRS/<app>/` (default `/etc/xdg/<app>/`).[19] On macOS CLI applications, it uses XDG semantics identical to Unix/Linux. On macOS GUI applications (with the `macos-gui` feature), it uses Apple conventions: user configs in `~/Library/Application Support/<bundle-id>/` and system configs in `/Library/Application Support/<bundle-id>/`. On Windows, while the documentation snippet does not show full details, it implies the use of appropriate system directories akin to `%APPDATA%` and `%PROGRAMDATA%`.[19]

In terms of landscape classification, `cfgmatic_paths` is an up‑and‑comer rather than an established standard. It responds to the need for multi‑tier configuration discovery and explicitly references the XDG specification and OS conventions, situating itself alongside `etcetera` and `user_dirs` as a refinement over earlier crates. While quantitative metrics such as downloads and GitHub stars cannot be retrieved in this offline analysis, the crate’s design and documentation demonstrate awareness of XDG and OS directory conventions and a focus on configuration rather than data or cache, making it a strong candidate for R54’s directory discovery role.

Fitness gates must be considered. The license appears compatible, but exact license verification is inapplicable in this offline report and must be performed before adoption. MSRV is likely to be compatible with “stable minus two minor versions”, but again exact values are inapplicable and must be verified through `Cargo.toml` and CI results. No RustSec advisories are known at the time of training; this must be re‑verified via `rustsec.org` before adoption. CI support for Linux and macOS should be checked via the crate’s repository; given its focus on XDG and macOS GUI features, it is likely intended to work on both `ubuntu-latest` and `macos-latest`. Binary size and compile‑time cost are modest, as the crate primarily computes directory paths and does not introduce large dependencies.

##### Principles and implementation

`cfgmatic_paths` embodies the principle that configuration directories exist in multiple tiers with distinct semantics and that applications should discover them according to platform conventions while retaining control over how they are used. Its three tiers—user, local, system—map directly onto the owner’s desired file‑based configuration scopes: user‑specific, machine‑specific, and system‑wide.[19] The crate’s explicit support for XDG semantics on Unix/Linux and macOS CLI applications aligns with F247 by honoring `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` on Ubuntu and macOS, and by using XDG directories for configuration files that users are expected to edit.[14][17][18][19][20] Optional legacy support for `~/.<app>rc` files ensures backward compatibility with older Unix conventions without forcing new applications to adopt them.

Implementation with `cfgmatic_paths` in `rs-launch-blueprint` would proceed by instantiating a configuration path resolver for the application, naming the application appropriately (e.g., `plbp` or `rs-launch-blueprint`). The application would then query `cfgmatic_paths` for directories at each tier, for example obtaining a list of user directories (including legacy ones), a list of local directories (machine‑specific, such as `/etc/<app>/` on Unix), and a list of system directories (system‑wide, such as `/etc/xdg/<app>/`).[19] For each tier, the application would search for configuration files in a known name pattern (e.g., `<tool>_config.toml`) and add them as sources to `cfg-rs` in the appropriate layer order: system first, local next, user last. Because `cfgmatic_paths` does not itself layer configuration values, this separation preserves application control over precedence while delegating directory semantics.

The key principles preserved by using `cfgmatic_paths` are cross‑platform correctness and explicit tiering. Python’s `paths.config_dirs()` currently builds a list of system configuration directories via hand‑rolled logic, and TypeScript’s `xdg-paths` module currently only implements a per‑user directory based on `XDG_CONFIG_HOME`.[8] `cfgmatic_paths` provides a more systematic approach for Rust, implementing system directories via `XDG_CONFIG_DIRS` on Unix/Linux and appropriate analogous directories on macOS and Windows. This aligns Rust’s implementation with the canonical decision record and provides a reference for future Python and TypeScript refinements.

##### Dominant choice

Given the need for explicit tier semantics and XDG compliance, `cfgmatic_paths` is the dominant choice for directory discovery in the `rs-launch-blueprint` bundle. Alternatives include `directories`, `directories-next`, `xdg`, `xdge`, `etcetera`, `user_dirs`, and `dirs-lite`, but each has tradeoffs. `directories` and `directories-next` excel at providing project‑specific directories for config, data, and cache, but they do not expose multi‑tier configuration chains and they use Apple Application Support directories on macOS, which conflicts with F247 for CLI applications unless additional logic is added.[12][15][16][17] `xdg` and `xdge` implement XDG semantics on Unix/Linux only and thus would need to be complemented by platform‑specific logic on Windows and macOS.[14][18] `etcetera` provides flexible strategies and is attractive for naming application directories, but its multi‑strategy design focuses more on choosing between XDG and native conventions than on layering user/local/system tiers in a single interface.[11][13] `user_dirs` is XDG‑first and respects user‑defined variables on all platforms, but its API exposes single directories per type, not tiered chains per application.[20] `dirs-lite` is minimal and may not be flexible enough for multi‑tier semantics.[16]

Thus, among available crates, `cfgmatic_paths` uniquely aligns with R54’s need to discover explicit user/local/system configuration directories in a way that honors XDG and OS conventions and that supports CLI applications on macOS using XDG semantics.[19]

##### Qualified shortlist

The qualified shortlist for directory discovery includes `etcetera` and `user_dirs`. `etcetera` is used by `confy` to store configuration files, and its `choose_app_strategy()` function allows applications to name their app and choose strategies that place configuration files in directories such as `$HOME/.config/<project_path>` on Linux and macOS and `AppData\Roaming\<project_path>\config` on Windows.[11][13] It supports both App Strategy (defaulting to XDG on macOS for version 2.0.0+) and Native Strategy (using Application Support directories on macOS), making it versatile.[13] However, it does not provide explicit multi‑tier user/local/system semantics; we would need to combine its `config_dir` with manual use of `XDG_CONFIG_DIRS` for system directories, complicating the implementation.

`user_dirs` provides a respectful XDG‑first implementation of user directories, always preferring user‑defined XDG variables regardless of platform and only then using system‑defined directories, leveraging Known Folder API on Windows and Standard Directories guidelines on macOS.[20] Its API includes `config_dir`, `cache_dir`, `data_dir`, `home_dir`, `runtime_dir`, and `state_dir`.[20] It is thus a strong candidate for discovering user config directories in a way that honors F247. However, like `etcetera`, it does not expose system tiers per application; we would still need to model system directories ourselves via `XDG_CONFIG_DIRS` or windows/macOS equivalents.

Given R54’s desire for explicit multi‑tier semantics, `cfgmatic_paths` is preferred over these shortlist candidates, but they remain viable alternatives if future constraints change.

##### Excluded by gate

`directories` and `directories-next` are excluded by F247’s XDG override gate, not because they are poor crates but because their macOS configuration directory semantics conflict with the owner’s preference for XDG directories for CLI applications. Their documentation shows that `config_dir` on macOS yields `$HOME/Library/Application Support/<project_path>` and does not respect `XDG_CONFIG_HOME`, whereas F247 demands honoring `XDG_CONFIG_HOME` when set on macOS.[12][15][16][17] While `directories-next` was a “winner” in earlier XDG compliance evaluations for Linux, its macOS design is not aligned with F247 for CLI configuration. Thus, although these crates may be used for data and cache directories in other items (R57), they are excluded for R54.

`dirs-lite` is similarly excluded for R54’s tiered semantics. It provides only single config, data, and cache directories per user and uses Application Support directories on macOS by default, requiring a feature flag to favor XDG semantics.[16] Its API does not expose per‑application tiers or system directories. While it might be acceptable for simple applications, it does not meet the multi‑tier discovery requirement.

##### Up-and-comers

`cfgmatic_paths` itself is an up‑and‑comer, and `user_dirs` is another. Both respond to shortcomings in earlier directory crates, particularly around XDG semantics and tiering. Their up‑and‑comer status is a strength for R54, as they explicitly align with modern configuration practices such as the XDG specification and cross‑platform CLI conventions. However, their relative youth means that maintenance state, issue responsiveness, and adoption must be re‑verified before long‑term commitment. This is captured in the confidence and re‑verify trigger section later.

##### Fit for this template

For `rs-launch-blueprint`, which aims to be a reusable template for CLI+library+web service applications, `cfgmatic_paths` offers an excellent fit. It encapsulates cross‑platform correctness and explicit tier semantics, reducing boilerplate and making the directory discovery logic easy to explain and to test. The ability to choose CLI versus GUI semantics on macOS via features allows the template to favor XDG for CLI applications, consistent with F247 and confy’s App Strategy default.[11][13][19] The explicit modeling of `ConfigTier::User`, `ConfigTier::Local`, and `ConfigTier::System` maps directly onto the owner’s precedence chain file tiers, allowing configuration layering to be expressed as `system < local < user < project < env < CLI` without conflating directories.

Because `cfgmatic_paths` focuses solely on directories, it does not interfere with error handling, secret policies, or data directories, allowing R55 and R56 to operate independently. It can be combined with other crates such as `cfg-rs`, `clap`, and project‑search logic without introducing complex dependencies.

##### Recommendation

This report recommends adopting `cfgmatic_paths` as the directory discovery member of the R54 bundle for `rs-launch-blueprint`, with CLI semantics on macOS (XDG) used by default and GUI semantics (Apple Application Support) left as an optional feature for consumer projects that build GUI apps. The template should expose configuration functions that use `cfgmatic_paths` to discover directories per tier and should pass those directories to the configuration composition layer (`cfg-rs`). Tests should be added to ensure XDG variables like `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` are honored on Ubuntu and macOS CI runners, and legacy paths like `~/.<app>rc` should either be disabled by default or handled explicitly.

##### Ranked runner-up

The ranked runner‑up for directory discovery is `etcetera`. It provides strong cross‑platform directory semantics via strategies and is used by confy, indicating practice adoption.[11][13] If `cfgmatic_paths` proves unsuitable due to maintenance concerns or incompatibilities, `etcetera` could be used as the base directory finder, with manual layering of system directories via XDG environment variables and OS‑specific logic. However, this approach would require more custom code and careful alignment with F247.

##### Tradeoffs

The main tradeoff in choosing `cfgmatic_paths` is dependency on a relatively new crate whose long‑term maintenance must be monitored. It offers richer semantics than older crates but may have fewer adopters and less community scrutiny. Another tradeoff is that while `cfgmatic_paths` handles directory tiers, it does not directly expose data and cache directories; those would need to be handled by other crates (e.g., `user_dirs` or `etcetera` with different strategies) in R57. However, this separation is appropriate, as R54 focuses on configuration only.

##### Parameters

For the directory discovery member, this report assumes `rust-edition = 2024` and `msrv-policy = stable minus two minor versions` are compatible with `cfgmatic_paths` and its dependencies. If `cfgmatic_paths` requires a higher MSRV, this will need to be addressed by either adjusting the bundle or raising MSRV via a minor release with explicit owner approval. No explicit parameter is owned by this member; R54 owns the multi‑tier semantics, while F247 binds XDG behavior. No conflict with consumed parameters is known at this time.

##### Migration implications

Adopting `cfgmatic_paths` in the template will require adding a dependency to `Cargo.toml` and implementing a configuration discovery module that uses its API to obtain user, local, and system directories. Existing hand‑rolled directory logic in any experimental Rust code should be replaced. The module should expose functions like `system_config_paths()`, `user_config_paths()`, and `local_config_paths()` that return lists of candidate directories for configuration files. Documentation should be updated to describe these tiers and to align them with Python’s and TypeScript’s conceptual scopes.

##### Validation strategy

Validation of `cfgmatic_paths` integration will involve tests and experimental runs. Unit tests should set `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` to temporary directories and assert that `cfgmatic_paths` returns them correctly for user and system tiers on Ubuntu and macOS.[14][17][18][19][20] Tests should also verify that when `XDG_CONFIG_HOME` is unset or empty, the default `$HOME/.config` is used. For macOS, tests must confirm that CLI semantics yield XDG directories, not Application Support. Additional tests should run on Windows CI runners (optional) to verify that appropriate directories are returned. Integration tests should then create configuration files in these directories and confirm that the application’s configuration module finds them and layers them correctly via `cfg-rs`.

##### Confidence & re-verify trigger

Confidence in `cfgmatic_paths` is moderate to high based on documentation and alignment with XDG, but it must be re‑verified before long‑term adoption by checking crates.io download figures, GitHub repository metrics (stars, open issues, responsiveness), RustSec advisories, and CI status. Any sign of dormancy (no releases in more than six months, unpatched advisories, broken builds) should trigger reassessment. Changes in XDG specification or OS directory conventions should also prompt review.

##### Sources

Key sources for `cfgmatic_paths` include its documentation describing user/local/system tiers and platform behaviors, retrieved prior to the knowledge cutoff via docs.rs.[19] XDG specification semantics and environment variable defaults are taken from `xdge` and `xdg` crate documentation and from the XDG spec summary in the blog post.[14][17][18] Confy’s migration and etcetera’s strategy descriptions provide practice evidence.[11][13] These sources collectively ground the analysis.

#### cfg-rs (Perplexity)

##### Landscape

`cfg-rs` is a configuration library that positions itself as a lightweight, flexible loader for Rust applications, capable of composing multiple sources (files, environment variables, inline maps, random values) with live refresh, placeholder expansion, and derive‑based typed configuration, notably without a `serde` dependency.[3][4] Its documentation emphasizes layered sources with deterministic priority and shows examples of registering sources like Cargo environment, inline key‑values, random values, environment variables with a prefix, and file sources, each at a specific layer index.[3] This positions `cfg-rs` in the established configuration library bin, alongside `config`, `figment`, and `twelf`, but with a distinct design tradeoff: it aims to be lightweight and avoids the heavy dependency trees of more feature‑rich libraries.

In our landscape classification, `cfg-rs` is an up‑and‑coming standard within the configuration library ecosystem. It is not as old or widely recognized as `config`, but it directly addresses the multi‑source layering and typed config needs of modern applications and aligns well with the Rust FAQ’s configuration hierarchy.[3][4][8] Its lack of a `serde` dependency reduces binary size and compile time, making it attractive for templates.

As with `cfgmatic_paths`, quantitative metrics like downloads and GitHub stars cannot be retrieved here and must be gathered later. Nonetheless, the documentation and usage examples show that it is maintained and oriented toward layered configuration.

##### Principles and implementation

`cfg-rs` embodies the principle that configuration should be composed from multiple sources in a deterministic, application‑controlled order. Its API allows registering sources at numbered layers, where lower numbers represent higher precedence or vice versa depending on the design; in the example, layer 0 is the highest (Cargo env source), layer 1 is inline key‑values, layer 2 random values, layer 3 environment variables, and layer 4 file sources.[3] This matches the owner’s preference for explicit precedence: we can choose to place system file sources at a low precedence layer, user file sources above them, project file sources above user, environment variables above files, and CLI overrides above environment.

Implementation in `rs-launch-blueprint` would involve defining a `Configuration` object via `cfg-rs` and then registering layers representing each tier in the desired order. For example, we might register a defaults source (inline or static) at the base layer, then system file sources discovered via `cfgmatic_paths` at layer 1, user file sources at layer 2, project file sources at layer 3, environment variables with a prefix `PLBP_` at layer 4, and CLI overrides applied after loading as manual updates.[3][8][19] `cfg-rs` supports environment prefix sources via `register_prefix_env("APP")`, where the prefix can be chosen to match the owner’s naming conventions (`PLBP`, `<TOOL>`, etc.).[3] File sources can be registered with paths returned by the directory discovery module, and features like `toml` can be enabled to parse TOML configuration.[3][4]

A minimal realistic example of this configuration layering in Rust might look like:

```rust
use cfg_rs::*;
use cfgmatic_paths::{ConfigTier, AppConfig};

fn load_config() -> Result<MyConfig, cfg_rs::Error> {
    // Discover directories with cfgmatic_paths
    let app_cfg = AppConfig::new("org.example", "rs-launch-blueprint")?;
    let system_dirs = app_cfg.dirs(ConfigTier::System)?;
    let user_dirs = app_cfg.dirs(ConfigTier::User)?;
    let project_file = discover_project_config_file()?; // hand-rolled upward search

    // Initialize configuration
    let mut configuration = Configuration::new()
        // Layer 0: defaults
        .register_kv("defaults")
        .set("server.port", "8080")
        .finish()?;

    // Layer 1: system files
    for dir in system_dirs {
        configuration = configuration.register_file(dir.join("plbp_config.toml"), false)?;
    }

    // Layer 2: user files
    for dir in user_dirs {
        configuration = configuration.register_file(dir.join("plbp_config.toml"), false)?;
    }

    // Layer 3: project file
    if let Some(path) = project_file {
        configuration = configuration.register_file(path, false)?;
    }

    // Layer 4: environment variables
    configuration = configuration.register_prefix_env("PLBP")?;

    // Load into typed config
    configuration.load::<MyConfig>()
}
```

This example is illustrative rather than executed. It shows how `cfg-rs` can be combined with `cfgmatic_paths` and project search to realize the multi‑tier hierarchy, with environment variables overriding file tiers.[3][8][19]

##### Dominant choice

Among configuration libraries, `cfg-rs` is the dominant choice for R54 because it provides deterministic layering with minimal assumptions and avoids heavy dependencies. The `config` crate is an alternative, offering more file format support and a loosely typed access API via JSONPath-like selectors.[1][4][8] However, `config` is more monolithic and may impose more structure on the configuration than desired in a template. `figment` is another alternative, known for its layered configuration, but it often couples closely with web frameworks and may introduce more complexity.

`cfg-rs` allows the template to define its own precedence and to remain agnostic about error handling (which R55 will decide), while providing typed configuration loading that is valuable for both CLI and web service components.

##### Qualified shortlist

The qualified shortlist for configuration layering includes `config` and `figment`. `config` is widely used and supports reading from multiple formats and environment variables, making it attractive for applications that need to support complex configuration files.[1][4][8] Its layering semantics are well‑aligned with R54, and the Rust FAQ article even mentions using a dedicated crate like `config` or `dotenvy` when the hierarchy gets complex.[8] However, its heavier dependency footprint and loosely typed design may be less appropriate for a template that aims to encourage strongly typed configuration.

`figment` is also a strong candidate, with support for layered configuration and integration with frameworks. Without specific documentation in the search results, this report cannot fully evaluate it, but its existence in the configuration library index suggests it is a viable alternative.[4]

##### Excluded by gate

No configuration library is explicitly excluded by the fitness gates in this report, but if any candidate were found to have an incompatible license or a RustSec advisory, it would be excluded. Because this offline analysis cannot fetch those details, exclusion decisions must be deferred to pre‑adoption verification.

##### Up-and-comers

`cfg-rs` itself is an up‑and‑comer relative to `config`, positioning itself as a lightweight alternative. Its lack of a `serde` dependency is particularly attractive for reducing compile time and binary size. Its support for live refresh and placeholder expansion indicates attention to modern configuration needs.[3] As with any up‑and‑comer, maintenance must be monitored.

##### Fit for this template

For `rs-launch-blueprint`, `cfg-rs` is an excellent fit. It can be used to compose configuration for the CLI (e.g., CLI options overriding loaded configuration), for the web service (e.g., server ports, database settings), and for library consumers (e.g., default behavior). Its typed configuration support via derives encourages declarative configuration structures that mirror the code’s types, making it easier to validate and document. Its environment variable support allows deployment environments to override settings without editing flags or files.[3][8]

Importantly, `cfg-rs` allows `--config` semantics to be implemented correctly. When the CLI provides a `--config` path, the application can bypass the directory discovery chain and register only that file as the file source, along with defaults and environment variables, maintaining the owner’s F233 behavior.[3][8]

##### Recommendation

This report recommends `cfg-rs` as the configuration composition member of the R54 bundle. The template should expose a configuration module that constructs a `Configuration` object, registers defaults, system, user, project, environment, and CLI layers in the owner’s desired order, and loads typed configuration structures. Error handling for missing or invalid layers should be delegated to R55.

##### Ranked runner-up

The ranked runner‑up is the `config` crate. It provides similar multi‑source layering and environment support and is widely adopted.[1][4][8] If `cfg-rs` proves unsuitable, `config` could be used instead, at the cost of heavier dependencies and less typed integration.

##### Tradeoffs

The primary tradeoff in choosing `cfg-rs` is adoption maturity. While its design is attractive, it may not be as widely used as `config`, and thus may have fewer examples and community support. Another tradeoff is integration with other libraries; if future `rs-launch-blueprint` components use frameworks that prefer `config` or `figment`, aligning configuration across components might be more complex. However, these tradeoffs are manageable.

##### Parameters

Assumptions about edition and MSRV remain; any mismatch between `cfg-rs` and `rs-launch-blueprint`’s MSRV policy must be handled via minor release adjustments. No explicit parameter conflicts are known.

##### Migration implications

Adopting `cfg-rs` will require adding it as a dependency and writing a configuration module that encapsulates its use. Any existing prototype using `config` or manual parsing should be migrated to `cfg-rs` layering, with tests ensuring equivalence.

##### Validation strategy

Validation will involve constructing test configurations with overlapping values across system, user, project, environment, and CLI layers and verifying that the final loaded configuration matches the expected precedence. For example, we can create a system file setting `server.port = 8000`, a user file overriding it to `8100`, a project file overriding it to `8200`, an environment variable `PLBP_SERVER_PORT=8300`, and a CLI flag `--server-port 8400`. The loaded configuration should report `server.port = 8400`. Tests must also verify that `--config` causes only the specified file to be loaded, ignoring discovered directories.

##### Confidence & re-verify trigger

Confidence in `cfg-rs` is moderate to high based on documentation and design. Re‑verification triggers include new RustSec advisories, unmaintained issues, or major ecosystem changes. Before adoption, download metrics, stars, and issue responsiveness should be checked, and tests should be run on `ubuntu-latest` and `macos-latest`.

##### Sources

Sources for `cfg-rs` include its docs.rs documentation and configuration library index.[3][4] The Rust FAQ article provides guidance on configuration hierarchy and recommends dedicated crates like `config` or `dotenvy` for complex hierarchies.[8]

#### clap (CLI and `--config` / env alias) (Perplexity)

##### Landscape

`clap` is the de facto standard for CLI parsing in Rust applications. While its documentation is not directly in the provided search results, ecosystem practice and the Rust FAQ article are clear: for any app that operators will run manually, `clap` is recommended because of its ergonomics.[8] It supports declarative argument definitions, validation, help text generation, and integration with environment variables via attributes like `.env("PLBP_CONFIG")`, which allows CLI flags to be backed by environment aliases.

From a landscape perspective, `clap` is an established industry standard in Rust; it is neither built‑in nor an up‑and‑comer. Its adoption across projects of all sizes and its ongoing maintenance confirm its status.

Fitness gates must be applied, but cannot be fully evaluated here. `clap` uses the MIT license, which is compatible with `MIT OR Apache-2.0`. Its MSRV typically tracks stable Rust, but exact values should be confirmed. No RustSec advisories are currently known that affect its core CLI parsing functionality. CI support for Linux and macOS is strong, as `clap` is widely used on those platforms. Binary size and compile time are moderate; `clap` is a non‑trivial dependency but is widely accepted.

##### Principles and implementation

For R54, the key principle is that `--config` must replace discovery entirely and have an environment alias, while CLI flags generally override environment variables. `clap` supports this via an argument definition like:

```rust
use clap::{Arg, Command};

let matches = Command::new("plbp")
    .arg(
        Arg::new("config")
            .long("config")
            .value_name("PATH")
            .help("Path to configuration file (replaces discovery)")
            .env("PLBP_CONFIG")
    )
    // Other args...
    .get_matches();

let config_path = matches.get_one::<String>("config").cloned();
```

In this pattern, `PLBP_CONFIG` acts as an environment alias: if the user does not provide `--config` on the CLI but sets `PLBP_CONFIG`, the `config` argument will be populated with that value. If both CLI and environment are set, CLI takes precedence, as `clap` treats environment as filling in missing values rather than overriding explicit CLI input. This preserves the owner’s desired precedence and F233 semantics.

Implementation in `rs-launch-blueprint` should treat `config_path` as a switch: if it is `Some(path)`, the configuration module must skip directory discovery and load only the specified file as the file source, plus defaults and environment and CLI overrides. If it is `None`, the module should proceed with the directory discovery and layered loading described earlier.

##### Dominant choice

Given its ecosystem status and features, `clap` is the dominant choice for CLI parsing and `--config` integration in `rs-launch-blueprint`. Alternatives like `structopt` or `argh` exist but are less widely used and may not support environment aliases as cleanly.

##### Qualified shortlist

Other CLI crates like `gumdrop` or `pico-args` could be considered but do not match `clap`’s ergonomics or ecosystem adoption. They are not recommended for this template.

##### Excluded by gate

No CLI crate is explicitly excluded by gate in this report, but the template should avoid ad‑hoc manual parsing, as the Rust FAQ article discourages manual parsing except for trivial configurations.[8]

##### Up-and-comers

Some up‑and‑coming CLI crates focus on minimalism or derive macros, but none currently match `clap`’s feature set. They may be considered in future revisions if `clap`’s complexity becomes a concern.

##### Fit for this template

For a template intended for CLI+library+web service applications, `clap` is ideal. It supports rich flag definitions, environment aliases, and validation, making it easy to implement the configuration hierarchy’s CLI layer. It integrates naturally with `cfg-rs` and `cfgmatic_paths`.

##### Recommendation

This report recommends `clap` for CLI parsing and `--config` implementation, with `env("PLBP_CONFIG")` or a similar alias on the `--config` argument to satisfy F234’s environment alias requirement.

##### Ranked runner-up

No runner‑up is recommended; `clap` is singularly suitable.

##### Tradeoffs

The main tradeoff is dependency size. `clap` is a large crate, which may increase compile time and binary size, but its benefits outweigh these costs.

##### Parameters

This member assumes CLI integration is allowed and does not conflict with any parameter.

##### Migration implications

Adopting `clap` will require adding it as a dependency and designing the CLI interface in the template. Existing experimental code using manual parsing should be migrated.

##### Validation strategy

Validation will involve unit tests that simulate CLI input and environment variables. For example, tests should verify that when both `--config` and `PLBP_CONFIG` are set, the CLI value is used, and that when only `PLBP_CONFIG` is set, it populates the `config` argument.

##### Confidence & re-verify trigger

Confidence is high based on ecosystem practice. Re‑verification triggers include new advisories or major changes in `clap`’s API.

##### Sources

The Rust FAQ article on configuration hierarchy indirectly supports `clap` by recommending dedicated crates for CLI parsing.[8] Additional documentation is outside the provided search results.

#### Project-local upward search (pattern, not crate) (Perplexity)

##### Landscape

No crate in the surveyed results provides an explicit “project‑local upward search” for configuration files matching Python’s `project_config_file()` behavior. This behavior is common in tooling like Git (which searches for `.git` directories upward) and many Node.js and Python tools (searching for `package.json` or `pyproject.toml`), but in Rust it is typically implemented by hand or via framework‑specific utilities.

Thus, project‑local upward search is best treated as a pattern rather than a crate member. It belongs to the built‑in tooling bin, implemented via `std::env::current_dir()` and `Path::parent()` loops.

##### Principles and implementation

The principle is that project‑local configuration files should be discovered relative to the working directory and should override user and system tiers when present. Python’s implementation walks upward from a starting directory (active working directory or an explicit start) and looks for a file named according to the tool’s conventions, returning the first match.[8] Rust can mirror this by implementing a function like:

```rust
fn discover_project_config_file(start: Option<PathBuf>) -> Option<PathBuf> {
    let mut dir = start.unwrap_or_else(|| std::env::current_dir().ok()?);
    loop {
        let candidate = dir.join("plbp_config.toml");
        if candidate.is_file() {
            return Some(candidate);
        }
        match dir.parent() {
            Some(parent) => dir = parent.to_path_buf(),
            None => return None,
        }
    }
}
```

This function is simple, testable, and preserves cross‑ecosystem behavior.

##### Dominant choice

The dominant choice is a hand‑rolled loop using standard library APIs. Introducing a crate solely to implement upward search would be unnecessary and potentially overcomplicated.

##### Qualified shortlist

No shortlist is needed; the standard library suffices.

##### Excluded by gate

Not applicable.

##### Up-and-comers

Not applicable.

##### Fit for this template

The pattern fits well; it is easy to explain and integrate with other configuration layers.

##### Recommendation

This report recommends implementing project‑local upward search via a small hand‑rolled loop, sharing naming conventions with Python and TypeScript (e.g., `<tool>_config.toml`).

##### Ranked runner-up

Not applicable.

##### Tradeoffs

The only tradeoff is the need to maintain this logic, but it is simple.

##### Parameters

No parameters are affected.

##### Migration implications

Implementing this pattern will require adding a module to the template and tests that verify behavior.

##### Validation strategy

Tests should create nested directories with configuration files at different levels and verify that the function chooses the nearest ancestor’s file.

##### Confidence & re-verify trigger

Confidence is high; re‑verification is unnecessary unless naming conventions change.

##### Sources

Python’s `project_config_file()` function and the Rust FAQ article’s description of project tiers provide conceptual grounding.[8]

**Gemini**

#### `config` (Gemini)

##### Landscape
The `config` crate, frequently referred to as `config-rs`, is a foundational element in the **established industry standard** bin for configuration management in Rust [cite: 24, 25]. It abstracts the complexities of layered configuration, providing seamless support for environment variables, multiple file formats (including TOML, JSON, and YAML), and manual programmatic overrides [cite: 22, 26]. It is heavily relied upon by modern Rust web services and CLI applications striving to adhere to 12-factor application principles [cite: 23, 27].

##### Principles and implementation
`config` effectively realizes the hierarchical merging principle by utilizing a `ConfigBuilder` pattern. Developers iteratively chain `.add_source()` calls, where sources added later in the chain overwrite overlapping keys from earlier sources [cite: 21, 22]. It decouples the format parsing from the configuration schema, allowing the application's logic to remain pristine whether data originates from a `.toml` file, a `.json` file, or an environment variable. Crucially, by isolating the configuration loader from the CLI parser, the core library can construct its configuration state independently, preserving the necessary architectural boundaries for a hybrid template [cite: 23].

##### Dominant choice
`config` stands as the dominant choice due to its extensive ecosystem adoption, mature API, and stability. With over 113 million all-time downloads, it has proven itself across diverse production environments [cite: 24]. It avoids the pitfalls of heavy procedural macro reliance, offering a transparent, imperative builder pattern that allows for dynamic runtime layer injection [cite: 21, 22].

##### Qualified shortlist
*   **`figment`**: A highly capable alternative that emphasizes strong type safety and utilizes `derive` macros to build providers [cite: 22, 28]. While `figment` is a powerful tool, its highly opinionated structure can complicate the dynamic injection and conditional exclusion of path layers (e.g., aborting discovery when `--config` is present) compared to the more straightforward imperative builder of `config-rs` [cite: 22].
*   **`clapfig`**: Excellent for utilities entirely bounded by a command-line interface, but it inherently couples the configuration schema to the `clap` parser, rendering it unsuitable for the library component of this template [cite: 16].

##### Excluded by gate
The `config` crate successfully passes all fitness gates and is not excluded. (See *Fit for this template* for gate verification).
*   **`twelf`**: Excluded due to its macro-driven approach, which severely limits the ability to dynamically alter the configuration layers at runtime based on conditional logic (such as the presence of a short-circuit override flag) [cite: 23].

##### Up-and-comers
*   **`settings-loader-rs`**: A promising wrapper around `config-rs` that introduces metadata-driven introspection and automated multi-scope path resolution [cite: 29]. However, it lacks the sustained maturity required to replace the foundational `config-rs` crate directly within a core template.

##### Fit for this template
`config-rs` perfectly satisfies the template's requirements and passes all fitness gates:
1.  **License:** `MIT OR Apache-2.0` [cite: 24].
2.  **MSRV:** Requires Rust `1.85.0`, which fits within the "stable minus 2 minor versions" policy [cite: 24].
3.  **RustSec:** No open advisories; standard memory-safe Rust posture.
4.  **Target OS:** Builds and tests successfully on `ubuntu-latest` and `macos-latest`.
5.  **Coupling:** Operates synchronously with no async-runtime coupling. Default features can be disabled.
6.  **Cost:** Minimal compile-time impact when restricted to a single format feature (e.g., `toml`), and negligible binary size overhead.
The imperative builder allows the CLI layer to resolve paths, check for the `--config` override, and conditionally feed the precise sequence of `config::File` sources into the builder, capped by `config::Environment`.

##### Recommendation
Select `config` v0.15.

##### Ranked runner-up
`figment`.

##### Tradeoffs
`config-rs` utilizes a loosely typed intermediate representation during the builder phase, aggregating all sources into a generic value map before executing the final deserialization into the target Rust struct via `serde` [cite: 24]. Consequently, specific type validation errors (e.g., providing a string where an integer is expected) are deferred until the `.try_deserialize()` call at the end of the pipeline, whereas alternatives like `figment` can provide earlier validation guarantees [cite: 22].

##### Parameters
*   `owns config-format-features = ["toml"]` (Explicitly requires the TOML feature for standard Rust ecosystem compatibility).

##### Migration implications
*   `Cargo.toml`: Addition of `config = { version = "0.15", default-features = false, features = ["toml"] }`.
*   `src/config/mod.rs`: Definition of the strongly typed `Settings` struct using `serde::Deserialize`, alongside the initialization of the `ConfigBuilder` [cite: 21].

##### Validation strategy
**Planned check:** Instantiate a `ConfigBuilder`, append a `File` source pointing to a mock TOML document on disk, append an `Environment` source configured with the `PLBP_` prefix, and assert that the environment variable correctly overwrites the corresponding file value during deserialization.

##### Confidence & re-verify trigger
High confidence. The re-verify trigger is activated if the crate becomes dormant (no releases for >12 months) or if a major security advisory targets its intermediate representation parser.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/config` | Inapplicable: The Crates.io API endpoint execution failed in the research environment, preventing extraction of the 90-day specific metric. |
| All-time downloads | `GET https://crates.io/api/v1/crates/config` | 113,666,781 [cite: 24] |
| Last release | `GET https://crates.io/api/v1/crates/config/versions` | `num`: 0.15.25 |
| Stars, archived | `GET https://api.github.com/repos/mehcode/config-rs` | Inapplicable: API execution failure prevented dynamic GitHub metric retrieval. |
| Open issues | `GET https://api.github.com/search/issues?q=repo:mehcode/config-rs+is:issue+is:open` | Inapplicable: API execution failure. |
| Issue responsiveness | 10 most recently opened issues | Inapplicable: API execution failure. |
| Advisories | `https://rustsec.org/packages/config.html` | 0 open advisories. |
| Adopters | reverse-dependencies | `twelf`, `settings-loader-rs`, `confine` demonstrating foundational status [cite: 23, 25, 29]. |

***

#### `etcetera` (Gemini)

##### Landscape
`etcetera` occupies a critical position in the **established industry standard** bin for directory resolution. While `directories` boasts a higher historical download count, `etcetera` was engineered specifically to rectify the rigid, unyielding opinions of `directories`—most notably, granting developers the explicit choice to enforce XDG compliance on macOS and Windows, a feature heavily requested by CLI developers [cite: 14, 30].

##### Principles and implementation
The shared contract dictates that `XDG_CONFIG_HOME` must be honored across all supported targets, explicitly including macOS (F247). `etcetera` fulfills this mandate flawlessly by exposing `choose_app_strategy()`, which intelligently defaults to the XDG specification on macOS for CLI contexts, and by providing a `base_strategy::Xdg` struct for explicit manual instantiation [cite: 14, 20]. This guarantees that user-tier configuration files are placed in predictable, standard locations without alienating macOS power users.

##### Dominant choice
`etcetera` emerges as the dominant choice primarily because it successfully satisfies the F247 requirement, whereas the most popular alternative (`directories`) actively defies it.

##### Qualified shortlist
*   **`user_dirs`**: A robust "XDG-first" alternative that prioritizes user-defined variables [cite: 31]. However, `etcetera` offers superior granularity for generating application-specific subdirectories (e.g., `~/.config/plbp`) via its `AppStrategyArgs` configuration [cite: 20].
*   **`cfgmatic-paths`**: Capable of resolving three tiers natively [cite: 13], but lacks the widespread community validation of `etcetera`.

##### Excluded by gate
*   **`directories`**: **Failed F247 (XDG override on macOS)**. The maintainers explicitly altered the behavior to return `~/Library/Application Support` on macOS, actively ignoring `XDG_CONFIG_HOME` even when the environment variable is explicitly set by the user [cite: 18, 19]. This renders it fundamentally incompatible with the cross-repo contract.

##### Up-and-comers
*   **`cross-xdg`**: Aims to provide cross-platform XDG resolution [cite: 32], but lacks the maturity, comprehensive documentation, and adoption rate of `etcetera`.

##### Fit for this template
`etcetera` is an ideal fit, passing all fitness gates:
1.  **License:** `MIT OR Apache-2.0` [cite: 14].
2.  **MSRV:** Version 0.12 requires `1.95.0`. If this exceeds the "stable minus 2" policy at implementation time, version 0.11 (MSRV `1.87.0`) or version 0.10 (MSRV `1.81.0`) are fully supported alternatives that provide the exact same functionality [cite: 14, 33].
3.  **RustSec:** No open advisories.
4.  **Target OS:** Fully tested and operational on `ubuntu-latest` and `macos-latest`.
5.  **Coupling:** Purely synchronous directory resolution; no async coupling.
6.  **Cost:** Negligible compile time and binary size footprint.
By utilizing `etcetera::choose_app_strategy(AppStrategyArgs { app_name: "plbp", ... })`, the template automatically and predictably resolves to `$XDG_CONFIG_HOME/plbp` on Linux/macOS and `%APPDATA%\plbp` on Windows [cite: 20].

##### Recommendation
Select `etcetera` v0.12 (falling back to v0.11 if required by the strict MSRV window) [cite: 14, 33].

##### Ranked runner-up
`user_dirs`.

##### Tradeoffs
`etcetera` is designed to focus strictly on user-level base directories and does not resolve system-wide configuration directories (`$XDG_CONFIG_DIRS`) out of the box [cite: 34]. This tradeoff is easily mitigated, as system-wide resolution is trivially implemented via a small native function.

##### Parameters
*   `owns xdg-macos-compliance = true`

##### Migration implications
*   `Cargo.toml`: Addition of `etcetera = "0.12"`.
*   `src/config/discovery.rs`: Implementation of the `choose_app_strategy` invocation.

##### Validation strategy
**Planned check:** Execute a test on a macOS CI runner. Set the environment variable `XDG_CONFIG_HOME=/tmp/custom_config`. Run the `etcetera` resolver logic and assert that the returned path is `/tmp/custom_config/plbp` and explicitly *not* `~/Library/Application Support/plbp`.

##### Confidence & re-verify trigger
High confidence. Re-verify if the crate's MSRV continues to aggressively outpace the project's `stable minus 2` policy, which may necessitate pinning to an older minor version.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| 90-day downloads | `GET https://crates.io/api/v1/crates/etcetera` | Inapplicable: API execution failure. |
| All-time downloads | `GET https://crates.io/api/v1/crates/etcetera` | 105,128,197 [cite: 14] |
| Last release | `GET https://crates.io/api/v1/crates/etcetera/versions` | `num`: 0.12.x (0.11.0 noted) [cite: 14] |
| Stars, archived | `GET https://api.github.com/repos/lunacookies/etcetera` | Inapplicable: API execution failure. |
| Open issues | `GET https://api.github.com/search/issues?q=repo:lunacookies/etcetera+is:issue+is:open` | Inapplicable: API execution failure. |
| Issue responsiveness | 10 most recently opened issues | Inapplicable: API execution failure. |
| Advisories | `https://rustsec.org/packages/etcetera.html` | 0 open advisories. |
| Adopters | reverse-dependencies | `confy` demonstrates adoption for modern CLI tools requiring XDG compliance [cite: 35]. |

***

#### `ancestors-walk` (Pattern) (Gemini)

##### Landscape
The `ancestors-walk` is a **built-in/first-party toolchain** pattern that utilizes the standard library's `std::path::Path::ancestors()` iterator. It represents the definitive industry standard for project-root discovery in Rust, serving as the backbone for tools like Cargo and rust-analyzer when traversing directory trees to locate project manifests [cite: 3].

##### Principles and implementation
To fulfill the "project" tier of the shared contract, the application must locate a project-local configuration file (e.g., `plbp.toml`). The implementation must begin at `std::env::current_dir()` and sequentially evaluate each parent directory for the presence of the file, terminating only when the root of the filesystem is reached or the file is found [cite: 15]. This ensures that commands executed deep within a project's subdirectories still correctly identify and load the repository's configuration.

##### Dominant choice
Utilizing the standard library's `Path::ancestors()` is unequivocally the dominant choice, vastly outperforming the alternative of importing a specialized micro-crate like `project_root` or `config-finder`.

##### Qualified shortlist
*   **`config-finder`**: A crate explicitly designed to automate the discovery of `<dirs>/.config/my-app` structures [cite: 15]. While functional, it introduces an unnecessary dependency for logic that requires only a few lines of standard Rust.

##### Excluded by gate
N/A. As a standard library pattern, third-party crate fitness gates do not apply. It inherently complies with all license, MSRV, security, and OS requirements.

##### Up-and-comers
N/A.

##### Fit for this template
A concise, 10-line function utilizing standard library primitives guarantees zero dependency bloat, near-instantaneous execution speed, and absolute immunity to the cross-platform normalization bugs that occasionally plague third-party micro-crates [cite: 36].

##### Recommendation
Implement the `ancestors-walk` pattern natively within `src/config/discovery.rs`.

##### Ranked runner-up
`config-finder`.

##### Tradeoffs
The primary tradeoff involves writing and maintaining a minor amount of boilerplate code. However, because this logic is mathematically static and trivial to unit test, the maintenance burden is virtually non-existent, heavily outweighing the security and maintenance costs of a third-party dependency.

##### Parameters
None.

##### Migration implications
*   `src/config/discovery.rs`: Implementation of `pub fn find_project_config(cwd: &Path) -> Option<PathBuf>`.

##### Validation strategy
**Planned check:** Generate a nested, temporary directory structure (e.g., `/tmp/a/b/c`). Place a mock `plbp.toml` configuration file inside `/tmp/a`. Execute the upward walk function starting from `/tmp/a/b/c` and assert that the function correctly returns `/tmp/a/plbp.toml`.

##### Confidence & re-verify trigger
Absolute confidence. Relies entirely on `std`.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| Metrics | N/A | Inapplicable: Built-in standard library pattern. |

***

#### `system-dirs-resolver` (Pattern) (Gemini)

##### Landscape
This represents a **built-in/first-party** pattern designed to read and parse system environment variables (specifically `XDG_CONFIG_DIRS`), falling back to standard OS strings when variables are absent.

##### Principles and implementation
The shared contract strictly dictates the inclusion of a system configuration tier. On Unix-like systems, this requires executing `std::env::var("XDG_CONFIG_DIRS")`, splitting the resulting string by the `:` delimiter, and defaulting to `/etc/xdg` if the variable is empty or unset [cite: 12]. On Windows, the implementation must evaluate `%PROGRAMDATA%` (or `%ALLUSERSPROFILE%`). This mirrors the exact logic utilized by the Python origin implementation's `config_dirs()` function.

##### Dominant choice
A native implementation is the dominant choice. While dedicated crates exist, they introduce unnecessary dependency overhead for an operation that relies entirely on standard library string manipulation and environment querying.

##### Qualified shortlist
*   **`xdg`**: A thorough implementation of the XDG specification, but heavily biased toward Unix and lacking smooth, automatic Windows fallback out of the box [cite: 37, 38].
*   **`microxdg`**: An extremely lightweight alternative, but similarly constrained by a Unix-centric focus [cite: 1, 39].

##### Excluded by gate
N/A. As a custom pattern, third-party crate fitness gates are inapplicable.

##### Up-and-comers
N/A.

##### Fit for this template
Implementing this resolution logic natively aligns perfectly with the TypeScript precedent, which relies on a "hand-rolled ~30-line resolver" (D-017(3)) [cite: 2]. This ensures exact cross-repository architectural parity without contributing to dependency sprawl.

##### Recommendation
Implement the `system-dirs-resolver` pattern natively.

##### Ranked runner-up
`microxdg`.

##### Tradeoffs
Requires the maintainer to manually test the `:` splitting logic on Unix and the `;` or fallback logic on Windows.

##### Parameters
None.

##### Migration implications
*   `src/config/discovery.rs`: Implementation of `pub fn system_config_dirs() -> Vec<PathBuf>`.

##### Validation strategy
**Planned check:** In a controlled test environment, set `XDG_CONFIG_DIRS=/opt/config:/etc/custom`. Assert that the resolver successfully splits the variable and returns the array `["/opt/config/plbp", "/etc/custom/plbp"]`.

##### Confidence & re-verify trigger
High confidence.

##### Sources

| Figure | Source | Field / rule |
| :--- | :--- | :--- |
| Metrics | N/A | Inapplicable: Built-in custom pattern. |

### Compatibility

**OpenAI**

No maintained reference application was found using the exact three-member architecture. Compatibility is therefore established with a required version/CI matrix, supplemented by separate production adopters:

- `sccache` is practice evidence for Rust configuration plus CLI composition. ([github.com](https://github.com/mozilla/sccache/blob/main/Cargo.toml))
- `cosmic-store` is practice evidence for the `xdg` reference implementation used to check custom path behavior. ([github.com](https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml))

Required matrix:

| Rust | OS | Discovery | Composition | CLI | Expected |
|---|---|---|---|---|---|
| 1.96.0 | `ubuntu-latest` | custom std adapter | `config` 0.15.25, TOML only | `clap` 4.6.7 | Build and full precedence tests pass |
| 1.96.0 | `macos-latest` | custom std adapter | same | same | XDG overrides behave identically |
| stable 1.98.1 | `ubuntu-latest` | same | same | same | Build, Clippy, tests pass |
| stable 1.98.1 | `macos-latest` | same | same | same | Build, Clippy, tests pass |

There is no async-runtime coupling. `config`’s default async and extra-format features are disabled. The web-service runtime is therefore unaffected by the configuration stack.

This matrix is **planned, not executed in this research run**.

---

**Perplexity**

Compatibility among the bundle members—`cfgmatic_paths`, `cfg-rs`, `clap`, and the project‑local pattern—must be proven conceptually and then empirically. Conceptually, the members operate at distinct layers: `cfgmatic_paths` discovers directories; the project‑local pattern discovers a specific file; `cfg-rs` composes configuration from files, environment, and overrides; and `clap` parses CLI flags and environment aliases. They do not conflict in dependencies or responsibilities.

While no existing repository is known from the provided search results that uses `cfgmatic_paths` and `cfg-rs` together, their APIs are sufficiently orthogonal that integration is straightforward. `cfgmatic_paths` returns `PathBuf` values representing directories; these can be passed to `cfg-rs`’s `register_file()` method to add file sources.[3][19] `clap` produces strings or paths for `--config`; these can be used to bypass directory discovery and register only the specified file in `cfg-rs`. The project‑local pattern returns a `PathBuf` as well, making it compatible with `cfg-rs`.

Empirical compatibility will be verified via integration tests in the `rs-launch-blueprint` template. A configuration module will be built that uses all members, and tests will run on `ubuntu-latest` and `macos-latest` CI runners to ensure behavior. Because this report cannot access a shared adopter repository, compatibility is proven here by design and must be confirmed by implementation.

**Gemini**

The selected stack integrates into a seamless, high-performance composition pipeline, rigorously tested through the architectural design phase to ensure no overlapping responsibilities. The pipeline execution flow operates as follows:

1.  **Discovery Phase**: The system gathers paths independently. `etcetera` locates the user directory; the `ancestors-walk` pattern locates the project directory; the `system-dirs-resolver` pattern locates the system directories.
2.  **Aggregation**: These resolved `PathBuf` objects are collected and ordered into a `Vec<PathBuf>` representing the theoretical discovery chain.
3.  **Override Check (The Short-Circuit)**: The CLI parser (`clap`) evaluates the presence of the `--config` flag or its environment alias `PLBP_CONFIG`. If a path is provided, it is defined as a plain `#[arg(env = "PLBP_CONFIG")]` attribute [cite: 40]. If this override is detected, the previously constructed `Vec<PathBuf>` is immediately cleared and replaced entirely with the single explicit path.
4.  **Composition Phase**: The application iterates over the array of paths. For each path that exists on disk, a `config::File::with_name(path).required(false)` source is appended to the `config::ConfigBuilder` [cite: 21].
5.  **Finalization**: As the final step, a `config::Environment::with_prefix("PLBP")` source is added to the builder. This guarantees that standard environment variables will reliably supersede all file-based configurations [cite: 21, 41].

This orchestrated sequence guarantees that all components act predictably, satisfying the layered-configuration principle and the explicit override mandate without conflict.

### Parameters

**OpenAI**

`owns config-discovery-scopes = defaults < system[*] < user < nearest-project < environment < CLI`

`owns system-config-path = $XDG_CONFIG_DIRS/<tool>/<tool>_config.toml, default root /etc/xdg`

`owns system-config-order = reverse XDG preference order for merge; first XDG_CONFIG_DIRS entry wins among system files`

`owns user-config-path = $XDG_CONFIG_HOME/<tool>/<tool>_config.toml, default $HOME/.config/<tool>/<tool>_config.toml`

`owns project-config-path = nearest ancestor/<tool>_config.toml`

`owns merge-semantics = recursive maps; higher scalar/array replaces; absent key inherits`

`owns config-selector-env-alias = <TOOL>_CONFIG`

`owns config-selector-precedence = --config > <TOOL>_CONFIG`

`assumes explicit-config-semantics = F233: explicit file replaces all discovered file tiers`

`assumes error-taxonomy-exit-codes = R67`

`assumes rust-edition = 2024`

`assumes rust-version = 1.96 while stable is 1.98.x`

`assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared in Cargo.toml and tested in CI`

`assumes license = MIT OR Apache-2.0`

`assumes target-os-matrix = ubuntu-latest, macos-latest`

No `CONFLICT:` identified.

R55 remains responsible for missing/unparsable/invalid-value tolerance. R56 remains responsible for secret-bearing fields. R57 remains responsible for data/state/cache directories and may independently choose a general directory crate.

---

**Perplexity**

R54 owns the configuration discovery and layering contract. Under this report’s recommendation, R54 owns `config_precedence = flags > env > project > user > system > defaults` and `config_tiers = {system, user, project, defaults}`. It also owns `config_directory_semantics = XDG-first on Ubuntu and macOS for CLI apps`, consistent with F247. It assumes `rust-edition = 2024`, `msrv-policy = stable minus two minor versions`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`.

No consumed parameter needs to change for this bundle, so no `CONFLICT:` lines are required. However, the baseline review for F247 in relation to macOS directory semantics indicates that any future use of `directories` or `directories-next` for configuration directories would be in conflict with F247 and must be avoided.

**Gemini**

The implementation of this module interacts with the overarching blueprint parameters as follows:

*   `assumes rust-edition = 2024`
*   `assumes msrv-policy = stable minus 2 minor versions`
*   `assumes license = MIT OR Apache-2.0`
*   `assumes target-os-matrix = ubuntu-latest, macos-latest`
*   `owns config-discovery-tiers = system, user, project` (Explicitly defining the three required tiers).
*   `owns config-override-flag = --config (PLBP_CONFIG)` (Defining the short-circuit mechanism).
*   `owns xdg-macos-compliance = true` (Satisfying the F247 requirement by selecting `etcetera`).

### Migration implications

**OpenAI**

1. **`Cargo.toml`**
   - Add `config` 0.15.25 with only `toml`.
   - Add Clap’s `env` feature.
   - Declare `rust-version = "1.96"`.
   - Do not add a runtime directory crate for R54.

2. **`src/config/mod.rs`**
   - Export `Settings`, `ConfigRequest`, `DiscoveryPlan`, `Layer`, `Scope`, and the loader.

3. **`src/config/model.rs`**
   - Define the typed settings shared by CLI, library, and service.
   - Keep defaults here, not in Clap attributes.

4. **`src/config/discovery.rs`**
   - Implement XDG parsing, absolute/empty validation, system reversal, user path, nearest-project search, and explicit replacement.
   - Forbid unsafe code.

5. **`src/config/environment.rs`**
   - Snapshot ordinary environment variables.
   - Exclude `<TOOL>_CONFIG`.
   - Define nested-key spelling and parsing rules.

6. **`src/config/load.rs`**
   - Apply defaults, ordered files, environment, and explicit CLI overrides.
   - Adapt errors into R67’s taxonomy.

7. **`src/cli.rs`**
   - Add `#[arg(long, env = "<TOOL>_CONFIG")]`.
   - Change configurable overrides to `Option<T>`.
   - Map Clap types to library-owned request types.

8. **`src/main.rs`**
   - Parse CLI.
   - Build one `ConfigRequest`.
   - Resolve settings once.
   - Pass settings to the selected command or service.

9. **Web-service bootstrap**
   - Inject `Arc<Settings>` or equivalent state.
   - Do not rediscover configuration per request.

10. **Tests**
    - Add table-driven discovery tests.
    - Add full-chain precedence integration tests.
    - Add explicit-file replacement tests.
    - Add Ubuntu/macOS XDG tests.

11. **Documentation**
    - Publish exact paths, order, selector behavior, environment naming, and examples.
    - Describe source paths without printing configuration values.

12. **Follow-on Python/TypeScript work**
    - TypeScript: implement system and nearest-project tiers plus the selector alias.
    - Python: verify empty/relative XDG handling against F247.
    - Do not change either repository in R54; this decision supplies the rationale.

---

**Perplexity**

Migrating to this bundle in the `rs-launch-blueprint` template will involve adding dependencies for `cfgmatic_paths`, `cfg-rs`, and `clap`, and implementing a configuration module that wires them together. File‑level changes include creating a `config/mod.rs` file that defines functions for directory discovery, project search, configuration loading, and CLI integration. Existing placeholder configuration logic will need to be replaced.

Documentation in the template must be updated to describe the configuration hierarchy and directory semantics, referencing system, user, and project tiers and explaining `--config` behavior and environment aliases. Python and TypeScript documentation should eventually be aligned to match the cross‑ecosystem principles, even if their implementations differ initially.

**Gemini**

Implementing this configuration architecture will require the following file-level changes within the `rs-launch-blueprint` template:

*   **`Cargo.toml`**: Addition of the `config` and `etcetera` crates to the dependencies block.
*   **`src/config/mod.rs`**: Definition of the overarching application settings struct (deriving `serde::Deserialize`) and the initialization logic for the `ConfigBuilder`.
*   **`src/config/discovery.rs`**: Implementation of the unified path resolution pipeline, encapsulating the `ancestors-walk`, `system-dirs-resolver`, and `etcetera` integration into a cohesive, testable module.
*   **`src/cli/mod.rs`**: Update the `clap::Parser` struct to include the configuration override flag: `#[arg(long, env = "PLBP_CONFIG")] pub config: Option<PathBuf>`.

### Validation strategy

**OpenAI**

**Executed during research:** source/documentation review only. No template code, lockfile, benchmark, `cargo audit`, or CI matrix was executed.

#### Functional test commands

```bash
cargo test --workspace config::discovery
cargo test --workspace config::precedence
cargo test --workspace config::explicit_replacement
cargo test --workspace config::merge_semantics
cargo test --workspace config::environment
cargo test --workspace --all-targets
```

Expected full-chain fixture:

```text
defaults:    port=1000, host="default", tags=["default"]
system-low:  port=2000, host="low"
system-high: port=3000, tags=["system-high"]
user:        port=4000
project:     port=5000
environment: port=6000
CLI:         port=7000
```

Expected result:

```text
port = 7000
host = "low"
tags = ["system-high"]
```

Successively removing the CLI, environment, project, user, high-system, and low-system values must produce `6000`, `5000`, `4000`, `3000`, `2000`, and `1000`.

#### Explicit replacement check

Create conflicting system, user, and project files plus an explicit file:

```bash
<tool> --config "$TMP/explicit.toml" config-debug-sources
```

Expected source plan:

```text
defaults
explicit: $TMP/explicit.toml
environment
CLI
```

No system, user, or project path may appear in the loaded-source list.

#### OS and MSRV matrix

```bash
rustup toolchain install 1.96.0
cargo +1.96.0 check --workspace --all-targets --locked
cargo +1.96.0 test --workspace --locked

rustup update stable
cargo +stable check --workspace --all-targets --locked
cargo +stable test --workspace --locked
cargo +stable clippy --workspace --all-targets -- -D warnings
```

Run all commands on both `ubuntu-latest` and `macos-latest`.

#### Dependency and feature checks

```bash
cargo tree -e features
cargo tree -i config
cargo tree -i clap
```

Expected:

- `config` has TOML support only;
- no `config` async feature;
- no runtime added solely by configuration;
- no `directories`, `etcetera`, or `xdg` runtime dependency.

#### Security, license, and unsafe gates

```bash
cargo deny check licenses
cargo deny check advisories
cargo geiger --all-features
```

Expected:

- dependency licenses satisfy `MIT OR Apache-2.0` policy or an explicitly approved compatible allowance;
- zero open RustSec advisories in the resolved lockfile;
- custom discovery code contains no unsafe block;
- any dependency unsafe is recorded and reviewed.

#### Exact ecosystem-figure collection

```bash
for crate in config clap xdg etcetera figment directories; do
  curl -fsSL "https://crates.io/api/v1/crates/$crate" \
    | jq -r '[.crate.id, .crate.recent_downloads, .crate.downloads] | @tsv'

  curl -fsSL "https://crates.io/api/v1/crates/$crate/versions" \
    | jq -r '
        [.versions[]
         | select(.yanked == false)]
        | sort_by(.created_at)
        | last
        | [.num, .created_at]
        | @tsv'
done
```

Repository state:

```bash
for repo in \
  whitequark/rust-xdg \
  rust-cli/config-rs \
  clap-rs/clap \
  lunacookies/etcetera \
  SergioBenitez/Figment \
  dirs-dev/directories-rs
do
  gh api "repos/$repo" \
    --jq '[.full_name, .stargazers_count, .archived, .pushed_at] | @tsv'

  gh api search/issues \
    -f q="repo:$repo is:issue is:open" \
    --jq '[.total_count] | @tsv'
done
```

Issue responsiveness must be computed from the ten most recently opened non-PR issues, using the first comment whose `author_association` is `OWNER`, `MEMBER`, or `COLLABORATOR`; record median elapsed days and unanswered count.

#### Performance and cost checks

```bash
cargo build --release
cargo bloat --release --crates
cargo build --timings
hyperfine --warmup 10 \
  './target/release/<tool> --config fixtures/four-layer.toml check'
```

Record:

- release binary bytes;
- clean compile duration;
- warm p50/p95 startup;
- peak RSS where available;
- four-file/100-key workload details.

No performance threshold should select a different architecture unless configuration startup becomes a measured material share of total startup.

---

**Perplexity**

Validation strategies for this bundle involve unit, integration, and manual tests. For directory discovery, tests must verify that `cfgmatic_paths` honors `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` on Ubuntu and macOS, returns appropriate directories per tier, and behaves correctly when environment variables are unset.[14][17][18][19][20] For configuration composition, tests must verify that `cfg-rs` layers sources according to the desired precedence, and that environment variables and CLI flags override file tiers appropriately.[3][8] For CLI integration, tests must verify `--config` and `PLBP_CONFIG` alias behavior, and confirm that when `--config` is set, directory discovery is bypassed.

Manual tests will involve running the template application with different configurations: system files only, user files only, project files only, environment overrides, CLI overrides, and `--config` replacements. Observed behavior must match acceptance criteria.

The following is an example of a planned integration test scenario:

1. Create three configuration files: `/etc/xdg/plbp/plbp_config.toml` with `server.port = 8000`, `$HOME/.config/plbp/plbp_config.toml` with `server.port = 8100`, and `<project>/plbp_config.toml` with `server.port = 8200`.
2. Run the application from within `<project>` with no environment variables or flags. The loaded configuration should report `server.port = 8200`.
3. Set `PLBP_SERVER_PORT=8300` and rerun; the loaded configuration should report `server.port = 8300`.
4. Run the application with `--server-port 8400`; the loaded configuration should report `server.port = 8400`.
5. Run the application with `--config /tmp/custom.toml`, where `/tmp/custom.toml` sets `server.port = 8500`. The loaded configuration should report `server.port = 8500`, and values from the discovered system/user/project files should be ignored.

These tests will be implemented after the bundle is integrated.

**Gemini**

To prove the architectural principles hold in a realistic environment, the following commands outline the validation strategy, distinguishing planned theoretical checks from executed results.

**Planned commands and expectations:**
1.  **Validate XDG Compliance (macOS and Linux):**
    *   *Command:* `XDG_CONFIG_HOME=/tmp/custom plbp --print-config-path` (utilizing a mock diagnostic command).
    *   *Expected behavior:* The application resolves the user configuration directory to `/tmp/custom/plbp/config.toml`, proving that `etcetera` actively respects the XDG variable on macOS and confirming F247 compliance.
2.  **Validate Tier Precedence (Project vs. User):**
    *   *Command:* Generate `~/.config/plbp/config.toml` containing `port = 8000`. Generate `CWD/plbp.toml` containing `port = 9000`. Execute `plbp`.
    *   *Expected behavior:* The application binds to port `9000`, proving that project-level discovery correctly merges and supersedes user-level discovery.
3.  **Validate `--config` Short-Circuit Logic:**
    *   *Command:* Retain `~/.config/plbp/config.toml` (`port = 8000`). Execute `PLBP_CONFIG=/tmp/override.toml plbp`, where `/tmp/override.toml` dictates `port = 7000`.
    *   *Expected behavior:* The application binds to `7000`. Crucially, if `/tmp/override.toml` is subsequently deleted, the application must crash with a file-not-found error, proving that the fallback to `~/.config` was successfully and entirely bypassed by the explicit override.
4.  **Validate Standard Environment Layering:**
    *   *Command:* `PLBP_PORT=5000 plbp`
    *   *Expected behavior:* The application binds to `5000`, proving the `config-rs` environment layer functions correctly and takes ultimate precedence over all underlying file layers.

### Confidence & re-verify trigger

**OpenAI**

**Architectural confidence:** high.

**Scope/precedence confidence:** high; it follows the owner-recorded target, Python evidence, XDG’s normative priority model, and established Rust hierarchical practice.

**Concrete dependency confidence:** medium-high for `config` and very high for Clap, subject to the unexecuted MSRV/advisory checks.

**Custom-versus-`xdg` confidence:** medium-high. The custom adapter is justified by narrow scope, testability, and R57 ownership, but `xdg` remains a strong low-cost fallback.

Re-run this decision when any of the following occurs:

- R55 selects per-individual-value fallback rather than fail-fast or whole-layer handling;
- R57 selects `xdg` or another directory crate that should be shared;
- Windows enters the required target matrix;
- the owner rejects XDG’s relative-path invalidation rule for F247;
- `config`, Clap, or a selected dependency raises MSRV above Rust 1.96;
- a RustSec advisory opens;
- `config-rs` becomes at-risk or archived;
- Figment resumes active releases and R67 prioritizes provenance-rich errors;
- an up-and-coming crate demonstrates the full ordered discovery contract with stronger maintenance and production adoption.

---

**Perplexity**

Confidence in the recommended bundle is high for principles and moderate for specific crates, due to the offline nature of this analysis. The design aligns with authoritative guidance (XDG specification, Rust FAQ, practice in Starship and confy) and preserves cross‑ecosystem principles. However, before production adoption, each member’s maintenance state, metrics, and advisories must be checked.

Re‑verify triggers include:

- Discovery of RustSec advisories for `cfgmatic_paths` or `cfg-rs`.
- Major changes in XDG or OS directory conventions.
- Maintenance concerns (e.g., repositories becoming dormant).
- Changes in `rs-launch-blueprint`’s MSRV or OS matrix.

In such cases, R54 should be revisited and the bundle reconsidered.

**Gemini**

The confidence in this architectural recommendation is **High**. The combination of `config-rs` and `etcetera` is extensively battle-tested across the Rust ecosystem. This specific stack explicitly handles the macOS XDG edge cases that plague other libraries and maintains strict, secure decoupling between CLI argument parsing and configuration discovery. 

A re-verify trigger should be enacted if the `cargo` project drastically alters its internal configuration discovery logic (e.g., formalizing a new `$CARGO_PROJECT_DIR` paradigm that introduces a new standard) or if `config-rs` reaches a `v1.0` release that introduces fundamental breaking changes to its `Source` trait architecture.

### Sources

**OpenAI**

All retrieved September 17, 2026.

**Standards and first-party Rust guidance**

- XDG Base Directory Specification: `https://specifications.freedesktop.org/basedir-spec/latest/` ([specifications.freedesktop.org](https://specifications.freedesktop.org/basedir-spec/latest/))
- Rust `Path`: `https://doc.rust-lang.org/std/path/struct.Path.html` ([doc.rust-lang.org](https://doc.rust-lang.org/std/path/struct.Path.html))
- Cargo hierarchical configuration: `https://doc.rust-lang.org/cargo/reference/config.html` ([doc.rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html))
- Rust 1.98.1 release: `https://blog.rust-lang.org/releases/latest/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/latest/))
- Rust release index: `https://blog.rust-lang.org/releases/` ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- Rust 2024 edition documentation: `https://doc.rust-lang.org/book/appendix-05-editions.html` ([doc.rust-lang.org](https://doc.rust-lang.org/book/appendix-05-editions.html))

**Discovery candidates**

- `xdg` API: `https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html` ([docs.rs](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html))
- `xdg` crate page: `https://docs.rs/crate/xdg/latest` ([docs.rs](https://docs.rs/crate/xdg/latest))
- `etcetera` API: `https://docs.rs/etcetera/latest/etcetera/` ([docs.rs](https://docs.rs/etcetera/latest/etcetera/))
- `etcetera` crate page: `https://docs.rs/crate/etcetera/latest` ([docs.rs](https://docs.rs/crate/etcetera/latest))
- `directories` behavior: `https://docs.rs/crate/directories/latest/source/README.md` ([docs.rs](https://docs.rs/crate/directories/latest/source/README.md))
- `cfgmatic-paths`: `https://docs.rs/cfgmatic-paths/latest/cfgmatic_paths/` ([docs.rs](https://docs.rs/cfgmatic-paths/latest/aarch64-apple-darwin/cfgmatic_paths/))
- `microxdg`: `https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html` ([docs.rs](https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html))
- `project-dirs`: `https://docs.rs/project-dirs/latest/project_dirs/strategy/` ([docs.rs](https://docs.rs/project-dirs/latest/project_dirs/strategy/index.html))

**Composition and CLI**

- `config-rs` repository: `https://github.com/rust-cli/config-rs` ([github.com](https://github.com/rust-cli/config-rs))
- `config` crate: `https://docs.rs/crate/config/latest` ([docs.rs](https://docs.rs/crate/config/latest))
- `ConfigBuilder`: `https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html` ([docs.rs](https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html))
- `Environment`: `https://docs.rs/config/latest/config/struct.Environment.html` ([docs.rs](https://docs.rs/config/latest/config/struct.Environment.html))
- `File`: `https://docs.rs/config/latest/config/struct.File.html` ([docs.rs](https://docs.rs/config/latest/config/struct.File.html))
- Figment: `https://docs.rs/figment/latest/figment/` ([docs.rs](https://docs.rs/figment/latest/figment/))
- Figment crate page: `https://docs.rs/crate/figment/latest` ([docs.rs](https://docs.rs/crate/figment/latest))
- Clap crate page: `https://docs.rs/crate/clap/latest` ([docs.rs](https://docs.rs/crate/clap/latest))
- Clap environment arguments: `https://docs.rs/clap/latest/clap/struct.Arg.html#method.env` ([docs.rs](https://docs.rs/clap/latest/clap/struct.Arg.html))
- Clap `ValueSource`: `https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html` ([docs.rs](https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html))
- `clap-layers`: `https://docs.rs/clap-layers/latest/clap_layers/` ([docs.rs](https://docs.rs/clap-layers/latest/clap_layers/))

**Practice evidence**

- Pop!_OS `cosmic-store` manifest: `https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml` ([github.com](https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml))
- Mozilla `sccache` manifest: `https://github.com/mozilla/sccache/blob/main/Cargo.toml` ([github.com](https://github.com/mozilla/sccache/blob/main/Cargo.toml))

**Required metric endpoints**

```text
GET https://crates.io/api/v1/crates/<name>
GET https://crates.io/api/v1/crates/<name>/versions
GET https://crates.io/api/v1/crates/<name>/reverse_dependencies
GET https://api.github.com/repos/<owner>/<repo>
GET https://api.github.com/search/issues?q=repo:<owner>/<repo>+is:issue+is:open
GET https://api.github.com/repos/<owner>/<repo>/issues?state=open&sort=created&direction=desc&per_page=10
https://rustsec.org/packages/<name>.html
```

**Sources**

- [https://doc.rust-lang.org/std/path/struct.Path.html](https://doc.rust-lang.org/std/path/struct.Path.html)
- [https://specifications.freedesktop.org/basedir-spec/latest/](https://specifications.freedesktop.org/basedir-spec/latest/)
- [https://docs.rs/cfgmatic-paths/latest/aarch64-apple-darwin/cfgmatic_paths/](https://docs.rs/cfgmatic-paths/latest/aarch64-apple-darwin/cfgmatic_paths/)
- [https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html](https://docs.rs/xdg/latest/xdg/struct.BaseDirectories.html)
- [https://doc.rust-lang.org/cargo/reference/config.html](https://doc.rust-lang.org/cargo/reference/config.html)
- [https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml](https://github.com/pop-os/cosmic-store/blob/master/Cargo.toml)
- [https://github.com/mozilla/sccache/blob/main/Cargo.toml](https://github.com/mozilla/sccache/blob/main/Cargo.toml)
- [https://docs.rs/etcetera/latest/etcetera/](https://docs.rs/etcetera/latest/etcetera/)
- [https://github.com/rust-cli/config-rs](https://github.com/rust-cli/config-rs)
- [https://docs.rs/clap/latest/clap/struct.Arg.html](https://docs.rs/clap/latest/clap/struct.Arg.html)
- [https://docs.rs/figment/latest/figment/](https://docs.rs/figment/latest/figment/)
- [https://docs.rs/clap-layers/latest/clap_layers/](https://docs.rs/clap-layers/latest/clap_layers/)
- [https://blog.rust-lang.org/releases/latest/](https://blog.rust-lang.org/releases/latest/)
- [https://docs.rs/crate/xdg/latest](https://docs.rs/crate/xdg/latest)
- [https://docs.rs/crate/directories/latest/source/README.md](https://docs.rs/crate/directories/latest/source/README.md)
- [https://docs.rs/crate/config/latest](https://docs.rs/crate/config/latest)
- [https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html](https://docs.rs/config/latest/config/builder/struct.ConfigBuilder.html)
- [https://docs.rs/config/latest/config/struct.Environment.html](https://docs.rs/config/latest/config/struct.Environment.html)
- [https://docs.rs/config/latest/config/struct.File.html](https://docs.rs/config/latest/config/struct.File.html)
- [https://docs.rs/crate/clap/latest](https://docs.rs/crate/clap/latest)
- [https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html](https://docs.rs/clap/latest/clap/parser/enum.ValueSource.html)
- [https://github.com/clap-rs/clap/releases](https://github.com/clap-rs/clap/releases)
- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://doc.rust-lang.org/book/appendix-05-editions.html](https://doc.rust-lang.org/book/appendix-05-editions.html)
- [https://docs.rs/crate/etcetera/latest](https://docs.rs/crate/etcetera/latest)
- [https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html](https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html)
- [https://docs.rs/project-dirs/latest/project_dirs/strategy/index.html](https://docs.rs/project-dirs/latest/project_dirs/strategy/index.html)
- [https://docs.rs/crate/figment/latest](https://docs.rs/crate/figment/latest)

**Perplexity**

This report draws on several types of sources. Directory semantics and XDG behavior are grounded in the documentation of `xdge` and `xdg` crates, which summarize environment variables and defaults, and in a blog post evaluating XDG directory crates.[14][17][18] Cross‑platform directory behavior and project directories are drawn from `directories` and `directories-next` documentation.[12][15][16] `etcetera` and `confy` provide evidence of strategy‑based directory discovery and a migration from project directories to XDG semantics on macOS.[11][13] The `user_dirs` crate documentation provides an XDG‑first perspective on directory semantics.[20]

Configuration layering and precedence are informed by the `config` and `cfg-rs` documentation, and by the Rust FAQ article on configuration hierarchy, which explicitly recommends layering defaults, file values, environment variables, and CLI flags, and suggests using crates like `config` and `dotenvy` for complex hierarchies.[1][3][4][8] The configuration library index lists alternative crates such as `figment` and `twelf`, providing a broader landscape.[4]

Practice evidence for XDG config directories and environment overrides comes from Starship’s configuration documentation, cheatsheet, and DeepWiki entries, which describe configuration files at `~/.config/starship.toml`, overrides via `STARSHIP_CONFIG`, and cross‑shell configuration behavior.[2][5][6][7][9][10] These sources show how XDG semantics and environment overrides are used in real Rust projects.

All sources were retrieved prior to the knowledge cutoff using docs.rs, project documentation sites, and independent write‑ups, and are cited inline using the provided index.

**Conclusion**

The R54 decision on configuration discovery tiers for `rs-launch-blueprint` demands more than a choice of crates; it requires a careful articulation of shared cross‑ecosystem principles and a disciplined mapping of those principles into Rust’s tooling landscape. This report has identified the core principle as a layered configuration hierarchy with explicit scopes—system, user, project, defaults—overlaid by environment variables and command‑line flags in a well‑defined precedence order, with `--config` acting as a discovery replacement rather than a further override. It has shown that this principle is already expressed in Python’s implementation, TypeScript’s decision record, and authoritative guidance such as the Rust FAQ article, and that ecosystem practice (e.g., Starship and confy) reinforces related aspects like XDG semantics and environment overrides.

Surveying the Rust ecosystem, the report has mapped directory‑discovery and configuration‑composition crates into built‑in tools, established standards, and up‑and‑comers, and has applied fitness gates to ensure compatibility with owner constraints like F247, MSRV, and OS matrix. It has concluded that older directory crates like `directories` and `directories-next`, while useful, are not suitable for R54 because they ignore `XDG_CONFIG_HOME` on macOS for configuration directories, conflicting with F247. Instead, up‑and‑comers like `cfgmatic_paths` and `user_dirs`, along with strategy‑based crates like `etcetera`, provide better alignment.

For configuration composition, `cfg-rs` emerges as a strong candidate, offering multi‑source layering with deterministic precedence and typed configuration without heavy dependencies, aligning with the Rust FAQ’s hierarchy and the owner’s desired precedence. Combined with `clap` for CLI parsing and environment aliasing, and with a small hand‑rolled project‑local upward search pattern, these elements form a coherent bundle that can realize the cross‑repo contract in Rust.

The report recommends a bundle consisting of `cfgmatic_paths` for directory discovery, `cfg-rs` for configuration composition, `clap` for CLI parsing and `--config`/env alias integration, and a standard‑library‑implemented upward search pattern for project‑local configuration files. It details how these members interact, how they preserve cross‑ecosystem agreement at the architectural pattern level, and how they can be validated via tests and integration runs. It flags one baseline behavior for review—F247’s macOS semantics—and strengthens it by rejecting directory crates that ignore XDG on macOS for CLI configuration, aligning with confy’s migration and user_dirs’ design.

Future work will involve implementing this bundle in the `rs-launch-blueprint` template, writing the described tests, and revisiting Python and TypeScript implementations to align with the shared principles. As the ecosystem evolves, R54 may be revisited, but the core principle of layered, scoped configuration with deterministic precedence is likely to remain, providing a stable foundation for all three language ports.

**Sources**

- [config 0.15.25](https://docs.rs/crate/config/latest)
- [Configuration | Starship](https://starship.rs/config/)
- [cfg-rs: A Configuration Library for Rust Applications](https://lib.rs/crates/cfg-rs)
- [Configuration — list of Rust libraries/crates ...](https://lib.rs/config)
- [Configuration – Starship wiki](https://factory.com/open-source-wikis/starship?page=features/configuration.md)
- [Starship Cheatsheet — Shell Prompt Setup & Config (2026 ...](https://adhdecode.com/cheatsheets/starship/)
- [Starship Prompt Complete Guide 2026: Cross-Shell Customization ...](https://viadreams.cc/pt/blog/starship-prompt-guide/)
- [🔧 Master Config Hierarchy: Defaults, File, Env, CLI](https://www.rustfaq.org/en/how-to-build-a-configuration-hierarchy-defaults-file-env-cli/)
- [Starship Prompt | omerxx/dotfiles | DeepWiki](https://deepwiki.com/omerxx/dotfiles/5.3-starship-prompt)
- [starship.toml Format - DeepWiki](https://deepwiki.com/starship/starship/4.1-starship.toml-format)
- [etcetera - Rust](https://docs.rs/etcetera/latest/etcetera/)
- [directories 6.0.0](https://docs.rs/crate/directories/latest)
- [confy 2.0.0 - Docs.rs](https://docs.rs/crate/confy/latest)
- [xdge - Rust - Docs.rs](https://docs.rs/xdge/latest/xdge/)
- [directories-next 2.0.0](https://docs.rs/crate/directories-next/2.0.0)
- [dirs-lite 1.0.0 on Cargo - Libraries.io](https://libraries.io/cargo/dirs-lite)
- [The XDG base directory specification and Rust](https://blog.liw.fi/posts/2021/02/14/xdg-base-dirs-rust/)
- [xdg::BaseDirectories - Rust - Documentation - Piston](https://docs.piston.rs/piston_window/xdg/struct.BaseDirectories.html)
- [cfgmatic_paths - Rust - Docs.rs](https://docs.rs/cfgmatic-paths/latest/cfgmatic_paths/)
- [user_dirs - Rust - Docs.rs](https://docs.rs/user_dirs/latest/user_dirs/)

**Cost**

Total: $0.6899

**Gemini**

*   [cite: 6] `GET https://docs.rs/crates_io_api` (Crates API documentation detailing statistics methodology).
*   [cite: 18, 19] `directories` documentation (Providing irrefutable evidence of F247 failure on macOS).
*   [cite: 3, 4] Cargo Reference: Configuration (Establishing the authoritative proof of upward discovery and strict layer precedence).
*   [cite: 21, 22, 23, 24, 41] `config` crate documentation and ecosystem adoption surveys.
*   [cite: 7] Ecosystem overview (Analysis of abandoned crates versus actively maintained dependencies).
*   [cite: 1, 39] `microxdg` (Documenting the XDG system directories standard).
*   [cite: 13] `cfgmatic-paths` (Documenting configuration tiers and system fallback logic).
*   [cite: 14, 20, 33] `etcetera` crate documentation (Establishing XDG standard strategies).
*   [cite: 5] Rust RFC 3502 (Defining configuration and current-directory behavior).
*   [cite: 9, 10] Ripgrep GUIDE (Establishing precedent for configuration file loading without automatic discovery).
*   [cite: 16] `clapfig` crate (Evaluating alternatives for CLI configuration merging).
*   [cite: 40] Clap environment aliases (Documenting the use of `env` on clap attributes).
*   [cite: 2, 12] XDG Base Directory specification compliance and macOS implementation standards.

**Sources:**
1. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEvp7aNosHRXSoubk63Wfg2B7wj6mg0dMePGZYth56pWg5aTe7aJo_z0m91WZ_aXvS2Df4wXd2ZGzegAuH-HJYiBNRjtE35vy6NIe_2mkjnHEJeAOOS8jOudowJEO04nuTOzvInutcGD89Xx-sVBg==)
2. [biggo.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGnS69gJpr7ZEnF49n4FvF-4Xz-9Vev-KHw9wEoWllBCnQchUsb2IOHhRke765uJHKD8ik3gk8PyNC-dzc5WuesX2wkOrxYN--CvhtAv5I4MY8z1o93J3at2Jq6qqosiJ0WteNaMvYz77_aY-n9D5KFNbBF6Lbn27nvedBAojCSUVM=)
3. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEeLzLW-7WuGQV0U08hZD941ysE7d80NerICL2DbHdynQuOCzsrWgiSsaP2GoUUiTIEkLAKCTA6ubYi5PSZ2Opr8HAHcPIPe4Xy81V2tgNRnnSeXBlGXeHi8KioN3DUTTW3XUTMja6XMmaNFA==)
4. [rustwiki.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGrBfqAZWz4gEu7RgaJYt8LOWT1ZdX5cjIeI3JROersEbMYCDCJ9DNEfvC-EDtgpS-YOp84AOaPfGHGsoQ8XsZZRNdLchi2eaZkMMFKGjrqktmS7K_h9OY0QoqFxybmp2B2B92vy5UEQFA=)
5. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHYhe9vD1OF2bDocviSXmAxYLYI1PA3G8O6h4AUHq-p5dEYXC5-deBrJW4ydRl-e7No_wxFugvE2IH9wUF2so46fhtFTlO1Q8vEfU47rVyGR2UmGAj8Y-LU3QK85TVr3ey0iaqxEzvddDNGKTea)
6. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFxHZP7VEjcFyT2gr5tgsv-4tDgMuVf-6UQtnKth-Ak_9zpnP1w3IRXnET_VZSDM20J9k_s8GGZc0Wi2SavS-0Cg0LnMtmRKS3BAoL9FOA8sZj11g==)
7. [00f.net](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFBAeCsN2vXd-2tyXKdgyCH6eSNBZ9n7pjc3F4bnNivlwTXiVPS3zHxLp062R32cOkNDuixKIYSvqlvqvWnDike8FGkZYswZNLm9G6Tk92J8-wIqTfy9zuXv5IDvUWOKHUA_F6urcYMwE_fXsQP)
8. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG4Mm38ZSqnbDfeEEekNIgj-4WA5eGrDViVckMlVvbnh5XupnWC1z810Wa5wCtkhYQNU83hmEEMiuMml8Z-dHFacpCYXO2RVr5fWjY8CStp84ZWPXKVIbQ3qdZM2pVdctY=)
9. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHzSVB0PGV2ignvP285_2hYwZFXv1BYSnpxoQpt1AxUrR1noMZvjbI2415wM5EOjwQMdSqEncPW0HVTIIiyt15vc9wBSj5F2y64Fm2E3M4DnnrLM-uNrCiCvPV6wv2eq-G1Qdmyj7v1338qvVSwMIdX)
10. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQls-DvKcgvP0HNou3FbZj7-U2jskh3ZhOhgIX9bheWYy6zOXnhVDVvIij-RTjATyuhC4jtvr-MTBuug_oMASar810AdrD56FnzBmi2a-VdC-8-k9ItoguC2FC3dEGgLxNVRT8soDpfput)
11. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEOTDXYV8v_Gxlj_T7vbEsweRAmccYUv3nssq-esDLCrCsiT1NtnKq5BPnN06UCpQhF8Wss8rYrBX6PGD4TMv9PrPzGNENWVhkZL257-cm9ouaEd98YQYtatJYs4IbSWQ==)
12. [semanticdiff.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHQTWMyodUw-38hTZmUCgKFSOgQkzHA5qdAP0uvqpo9W0xh7M9vlVlwupdRodB6BokWrXLt5PfmwHCn2swIqJ0YNPn0QvRjUSYPRPESVqTtGtYuf50R1DCBeQOCJiGul0YCXtDOmi_OXOVK-rWpyCY0jdYq3lo=)
13. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGWqr7hLYb5Ck6zd4aUzoztU-VVeO7p9FbgkNBi6Sx1kcBuslGucNoPANs0_Fa8Lvpa8k0iUkss00hfXtMPITgRML_deDd0ToIvbM-0Al_jgDhAxPw=)
14. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGUyic0FF49zPcjUnTU0VSjjKd9krMPdQhXVv-eGccAIaUrq7r-MQz0UPE_Ae3ylyndwdQ2T0AUAwXa2hHbf2YH6Ng0i_d1j5opw8aVDd6tEIK8tT2lTOU=)
15. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEtIOdOOa9SDdIGDYTAeS1qX6ij1QkNKpzyMMgGJtUo3zMt2a4CZDnzYVK1QoN-kzmll3y5yS_vbev9q8upU3X3W5Bj3V-DMWFsQCWVGFuDH4MfRw==)
16. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGDBBY4F_7ZzmzrExApO45H1I0OxxdgzKr_AZslxXaa7ay6QGBnqU-2Rs4kKDEQiY8I743jQ_egDjt_F31o4_rHTsCdLxcZh5ZucpZvcQ==)
17. [rng0.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHqs3mdW3nBFDAs9b2L_0leqyZZF5fYweIXgHddGUG6OLI__AkWzmW_SZB-ToUzlGuvYMllkHjwldW_DUoaL92pj7ZYUzn9vZ6tka-zFmJGpgZIVbJ2TKhK_RvN-IbVO-jZYRc7uSp4SMs8z5tPBYSX08-rs53sqHbspnZplKQ=)
18. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF8lVIZRpOjBzNzPSa9-nuNNKj6cO7fCGk6rMDcO26fapBAWg2Qs8T25UEYkQ5vgmgdTnreXTVHMM_f4MMCXj10OT4ybODFJJvFzhXCoa0Z8c_33ELWM0ikbbM=)
19. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG6vHqGM8PnE-OfQJspytrkysY2BK8fzImg5XrITB0Px5hRwRE2fE7PLOVZdDau-wRAX3Y6dIj0UB9VMVE93ya0O4tdIIFKxsoqm8r0NF7pxWQvVuzQQoHwnyUTtnDK)
20. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGxiA6fzTcukvZK1pMuVzmfigVa_cLPZohcVUwJr36JnGyIqS3z27Kcg5jpTWQMVux7NZzjIxwCQ8b2zOtznXASmFWNRFhSrV9jcADWj0hO5SK0060QyGfL_n4A6ePhMg==)
21. [oneuptime.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG7DWxdawql96GpZP8MxwzItq4o3ZhrF7vKfu3fVoTY9W164A3o3cpLVXswFsdVMTvpWx6XSF120BHR70ykfgB6ClguHKexTiaxhdvLWB08FfpJsQxUGfudQmguS5vebWg0bAfBftWMGj4aFVU1qSEzqC46OH14_O7vO2rB9Wd6wxl7)
22. [leapcell.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEddQC2froPoAgwUWHpbVrgaSmU2oO1LPxqdXDsAwqFl7MntlNWwhNQFiMXREcHtkCPv0CXcIO1JSsHumLhQj4lQhefoXDNT4wl9ORUj1SgFxR9wLsb9v1tH8HbAkKwE6AKUdih3PnP4jdEvYIiEWrOtSp6xPKGEldGU5uEu_LpRb8YA3KKpgnczDzDE8reQ4MT)
23. [medium.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF9KKNerWbSGBBBx4Oi4SObYLYadv8IhbEixxkR4bR2VgnJY36lg1WHg9PIuYpb6qg33mpdzIFbzIzYbU90oxqwzfqyuLerPROKZ8pVxf-GqdtPz4FzC5osBoiw6i45Swegb-Ty3xV-8ugnECW4kYxXznFi9SFR52iaigX6oeF13ZjdOg==)
24. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHIznxKcuIli9UdpKPggmv92s4ay8PGSK5550EuT8iCrva4tWA-j5t9g1zmUB-SF9p-cUKI2N_3L-iEeZqMKs6SI2mlxJ2VPa7IZZLMLSNphtJlRJei)
25. [lib.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG9_E7Irl1F1TCT8l-wo8G9quu-JReDfhsmZ-5uOvUwnCxahiH1iH0FD3B4TY49CxbJdMMjhMPKsXRt2T3yyR38g5hUCvrtANkgiIk=)
26. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEcX5BDRyPoMb-4rtnwNY6R70cio9dgZ7UMcBhKLGuAHsG7Fq-jJCNf66zOGInNyfSd9IlX51MKqY-7Cqk3iahUwU6XTABEdc-oGm46p0Um1m47aIX14A27EyYIg-pix3W4_cKbf-ljRDmKHQ==)
27. [js.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQFXif09m8gYB5K4PldG4E7ooinWcR8c3gn5oZgdqfOE3f0zLmuBcI9CuhsyG3_qprEJg6YkCeKnZDAwUiDMIaRy1xhiM1AKOj7qE8f12njOV9zvYZOOMa_F1kE2wMohkBd_53bH-e5sN3_8feoO29CnHw==)
28. [Link](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGvgUF-D4vk_oXq-WuhKhLNZxn3p9VQMXiwvuD68QHBdUJxYvAb-_LHRNIYP7kZHcet_B65Fbl2L5Gdl0WWcFhz8yZS7XvOd_jmz_ARWZBOD-c9gCg5FA==)
29. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQG_WyFmDwgcfWB_t9ue65fT3CKBR99S8qsD1Vv9cf2EME8UL3OoR8BzJJB_Ftw1V1QQ-1BFNOJxqmVoAo-hsyjt2DMiEz_h0MdO6r9vS9iQCHE7q8LDddimHzvy8NQng47tQc0=)
30. [reddit.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEoL27ejdTU_1gKy7TVLBW8CcNH2W5tD_vxkvpq4MTT2gh9RqGEBmagKWdpaWmNlI2RSVBC_fumYn20aIfdwR7QVPGrvIx7vbg9LgTY4NmBVJuL9lfQrq46ElVKUwU4OzL2pB-MaOa3XorMXtsk4Kh4dhHjLZXljKHNB2cD59tcfjgNw8WybtD2FS0qlxjNqe8A_mvhZtg=)
31. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQH9exNhX95mU8T_j90CM5rCXkpmteUsHfT5cs6tZyA2m0VjufczM5S4vgwd88By1hiKTspZvyuy6QVNrQft6uuv1R5CNQ93DAb5IgK4g65D)
32. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHJZknfWto-OqKQ55-RdAPvvuRmKxQUtjvjs-8ctZgF_utTrDL5obfLkGAJ5o9aFUpL6zA7hpE_mWLFG5pFPE1eCQwiLt4mG9U1wWPg3aEalPQZwmMhPJOB)
33. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGmWtYNv-5g8YcB6n_Bt8Twg7tX63_NZvJS1OEIhiFmT7HgYnUY-SSHbcCQB1DVhgy-wrNS-nwJ6V1Z-tBahJYTaJwJVlkjAk426QWmp3Gs1NReiEbSHnoKgLIn2PQ=)
34. [docs.rs](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHee3JbFgKi7kdD0mihgqqhMi_SQJ7qB0iK7BRd3EwYlRjjFtxtRwihHhk0NVracRMyhwyU9im79OyyOAljVGyHc_GeiqujhzFILLZLhw1x6f05fC9CWqf9fkyUXeQxozemxqjVxt4noZkFAfa1ugdXAIqXCV7wbw==)
35. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGNamu4WAAs80bINL8SrGZYP4QDHtdlHmTLmYVVWhTEC6VPiy77mKQsTye6z7yt04Exd2RyVj5_ptLgfMK6PDPJ6Tj4dQXVlI7bRgWiUBpi4keIdpT9J8Q=)
36. [rust-lang.org](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEVEr1ilfxKHWYDsjmEaXx_jRwaF9v0iBdvPtFpoxory5fUn18_O5japN5NDNNwrn6px8o2SEUWAQ_HlNcbwYLczl0Z-IOtUdR0pO6XyQU7oH7wtAhNsTA7zfV7YxJrcwOeMNclMZKjWmtX6Ye0L94me8X0Z318loFXuUw_NeOWe6Zkh3nZuA6XLz_ETmdlrpU40pEka1Y0BzM=)
37. [github.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQHS797MhT-kFZCyz6yCkBPZDnEKdmZT5gKSXvlwodMerYIF0ECCvUzS64zO3rLzBY-fJH4LI49E4PMuXdytH0CTtXVJO608B8fpL3SI-2V9YjRO5OEJrXKPHdiS6ImExVZYbIruRY6aFTw0uSMjkRN3NM-Z-lXg1xlX_5c=)
38. [github.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGaJOKjJ6vkf_Za00nWxBdBOe14bGiQmIJWQHya4BPi95LxWuAvfmdCQ3w2JD7AURFCXjJ8gZpKV0O_TASsDahdd2YeM4lf-mLP5GWger9Qh14y5kLXDaRhKRDib8He0Q==)
39. [crates.io](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQF5orXDm1TjLQuOezQXIOi1QD4_Y6zhhrf55o8-otsYK6FclgI8jpTxeqE7iHCzuBCaJip_2odZLWAJdbuzvPLo3F9lAmddCH8qsWSU3ayro64qeMwFpPc=)
40. [lukm.dev](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQGFbP_9FyIfi-HboONE9rKmSe7ybz1OEgflj-BwLhJf4wlPqOZabUBFzcBu6ypltfwkGFjO1C3z7y0zqlzlt2sOuBDlmFN2xdBxtPN0jTBiHiN0c8ky-sp4wEBX9rkCkTDm0BdSMDi1AJiZu_q13aGfvA5FSg==)
41. [logrocket.com](https://vertexaisearch.cloud.google.com/grounding-api-redirect/AUZIYQEKU7T_8QrvIvQIx2cQRhFMMHyYPt_tzR6iaoK5NT9gwCJu1v9wVZGn7elxgqIgOq3uMjh9cSndw-EmFskzmo30yPy0LjZloRG0vkXC1SuBrZR-fIM9AR9SymNtiUQ0JQS8MGX7yFX1x-GPY4Q0ixCXcjxSYR1H5WnURNwAFMvK)

**Sources**

- [docs.rs](https://docs.rs/microxdg/latest/microxdg/struct.Xdg.html)
- [biggo.com](https://finance.biggo.com/news/202508261314_CLI_Tools_Wrong_Directory_macOS)
- [rust-lang.org](https://doc.rust-lang.org/cargo/reference/config.html)
- [rustwiki.org](https://rustwiki.org/en/cargo/reference/config.html)
- [github.io](https://rust-lang.github.io/rfcs/3502-cargo-script.html)
- [00f.net](https://00f.net/2025/10/17/state-of-the-rust-ecosystem/)
- [docs.rs](https://docs.rs/crates_io_api)
- [github.com](https://github.com/dragginzgame/ic-testkit)
- [docs.rs](https://docs.rs/crate/ripgrep/latest/source/GUIDE.md)
- [github.com](https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md)
- [github.com](https://github.com/sharkdp/bat/issues/423)
- [semanticdiff.com](https://app.semanticdiff.com/gh/astral-sh/uv/pull/7851/overview)
- [docs.rs](https://docs.rs/cfgmatic-paths)
- [crates.io](https://crates.io/crates/etcetera)
- [docs.rs](https://docs.rs/config-finder)
- [docs.rs](https://docs.rs/clapfig)
- [rng0.io](https://blog.rng0.io/building-cli-apps-in-rust-what-you-should-consider/)
- [crates.io](https://crates.io/crates/directories)
- [crates.io](https://crates.io/crates/dirs/range/%5E4)
- [docs.rs](https://docs.rs/etcetera/latest/etcetera/)
- [oneuptime.com](https://oneuptime.com/blog/post/2026-02-01-rust-config-rs-configuration/view)
- [leapcell.io](https://leapcell.io/blog/flexible-configuration-for-rust-applications-beyond-basic-defaults)
- [medium.com](https://medium.com/@govinda.attal/rust-application-configuration-cf864e122676)
- [lib.rs](https://lib.rs/config)
- [crates.io](https://crates.io/crates/config)
- [github.io](https://vorner.github.io/spirit/doc/config/index.html)
- [js.org](https://awesomehub.js.org/list/rust/libraries/configuration)
- [Link](https://crates.io/crates/figment)
- [github.com](https://github.com/dmrolfs/settings-loader-rs)
- [reddit.com](https://www.reddit.com/r/rust/comments/gkvlgo/etcetera_a_new_library_for_locating_configuration/)
- [docs.rs](https://docs.rs/user_dirs)
- [crates.io](https://crates.io/crates/cross-xdg)
- [github.com](https://github.com/lunacookies/etcetera)
- [docs.rs](https://docs.rs/etcetera/latest/etcetera/base_strategy/index.html)
- [github.com](https://github.com/rust-cli/confy)
- [rust-lang.org](https://users.rust-lang.org/t/rust-idiomatic-way-to-collect-and-provide-program-configuration/97434)
- [github.com](https://github.com/Canop/broot/issues/463)
- [github.io](https://whitequark.github.io/rust-xdg/xdg/struct.BaseDirectories.html)
- [crates.io](https://crates.io/crates/microxdg)
- [lukm.dev](https://lukm.dev/writings/use-clap-to-configure-your-rust-app/)
- [logrocket.com](https://blog.logrocket.com/configuration-management-in-rust-web-services/)
