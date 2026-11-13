# Config Discovery Tiers for `rs-launch-blueprint`: A Cross‑Ecosystem Contract

This report establishes a principled, cross‑language configuration discovery and layering contract for the `launch-blueprint` family and then derives a concrete Rust implementation bundle for `rs-launch-blueprint` that satisfies that contract without silently reducing it to a single tier. The shared principle is a deterministic multi‑scope hierarchy—system, user, project, and defaults—overlaid by environment variables and command‑line flags in a well‑defined precedence order, where outer scopes override inner ones and `--config` (with an environment alias) replaces discovery entirely rather than adding another layer. Building on the XDG Base Directory Specification, the owner’s prior Python and TypeScript decisions, and ecosystem practice such as Starship’s configuration resolution, the report concludes that the cross‑repo agreement must be expressed at the level of architectural pattern and precedence semantics, not at the level of a specific crate or file path. For Rust, the recommended bundle is a combination of a platform‑aware configuration‑directory discovery crate following XDG and system conventions, a layering/config‑composition crate that can merge multiple sources while leaving precedence under application control, and the `clap` CLI framework with a `--config` argument whose value may come either from the CLI or from an environment alias. Within that bundle, this report recommends using `cfgmatic_paths` for user/local/system config directory discovery[19], `cfg-rs` for layered configuration composition and typed loading[3][4][8], and `clap` for flags and env integration, augmented by a small hand‑rolled project‑local upward search. The shared cross‑ecosystem principle is preserved, while ecosystem‑specific differences are explicitly justified and localized. Several baseline behaviors are affirmed, and one is flagged for owner review where the Rust implementation necessarily sharpens an ambiguous precedent.

## Context and Framing

The `launch-blueprint` family exists to provide a consistent, principled skeleton for applications that present as a combination of command‑line interface, reusable library, and web service. In the Python implementation, configuration discovery is explicitly layered: system‑wide configuration directories supply baseline values, per‑user configuration directories override them, and project‑local configuration files discovered by an upward search from the working directory provide the most proximate file‑based overrides. On top of those file tiers, environment variables and command‑line flags are placed, with `--config` acting as a hard replacement for the discovery chain rather than a further override layer. This behavior is codified in the Python code as `layers = [*reversed(paths.system_config_files()), target, paths.project_config_file()]`, together with a multi‑directory implementation of `paths.config_dirs()` for system configuration folders and a `project_config_file()` function that walks upward from a starting directory to find a local configuration file, as well as a CLI option whose `envvar="PLBP_CONFIG"` alias provides the environment‑driven override for `--config`. These behaviors are not incidental implementation details; they express deliberate owner decisions about configuration scope, override semantics, and operator control.

The TypeScript port adds another dimension to the context. Its decision record D‑017(1) explicitly names a canonical precedence order derived from CLI standards and the XDG specification: configuration files under `$XDG_CONFIG_HOME/<tool>` using a `TOML <tool>_config.toml` pattern, with precedence `flags > TOOL_* env > project > user > system > defaults`. However, D‑017(3) reveals that the shipped implementation currently realizes only the per‑user tier via a hand‑rolled `xdg-paths` resolver, omitting system and project tiers. This divergence is recorded in the ledger as `DIVERGENT`, and it is crucial to treat it as live context rather than as a settled constraint. The canonical order remains the target; the current TypeScript implementation is an incomplete realization of that contract. For Rust, the goal is therefore not to mimic the TypeScript implementation in its current state, but to honor the cross‑repo principle that the decision record expresses.

On top of this historical context, the owner has clarified several fixed parameters and constraints. Rust edition is locked to `2024`, with a minimum supported Rust version policy of “stable minus two minor versions”, raised only in minor releases and declared as `rust-version` in `Cargo.toml`, then enforced in CI. Licensing is constrained to `MIT OR Apache-2.0`, and CI must run on `ubuntu-latest` and `macos-latest` as target operating systems. Most importantly for this item, feature F247 (“XDG override”) binds the behavior of configuration directory discovery: `XDG_CONFIG_HOME` must be honored on both Ubuntu and macOS and ignored when empty, and the choice of directory‑discovery crate must respect this requirement. The baseline review already notes that `directories` 6.0.0 ignores `XDG_CONFIG_HOME` on macOS, whereas `etcetera` 0.11.0 offers an XDG strategy that honors user‑defined XDG variables.[11][12][13][15][16][17] These contextual elements narrow the Rust ecosystem landscape that we must survey and shape the bundle we can safely recommend.

Because this item is classified as “Deep” effort, the owner requires a full ecosystem survey rather than a quick familiar‑library recommendation. The survey must begin with a landscape map classifying candidates into three bins—built‑in or first‑party tooling, established industry standards, and up‑and‑comers—and must then identify authoritative guidance, actual practice in well‑regarded projects, and fitness against the specific use case of a CLI+library+web service Rust blueprint. Each candidate must pass explicit fitness gates: licensing compatibility, MSRV compliance within the specified policy, lack of RustSec advisories, CI support for Linux and macOS, stated coupling and feature behavior, and an assessment of binary size and compile cost. In this offline analysis, quantitative metrics such as recent downloads, exact release dates, GitHub stars, and issue responsiveness cannot be retrieved in real time, so they will be treated as “inapplicable” in the sense that they must be gathered in a follow‑up verification phase before adoption, rather than being silently omitted. This constraint itself becomes part of our confidence and re‑verification plan.

Finally, this item is coupled to other configuration‑related decisions: R55 governs tolerance of parse and validation errors in discovered layers, R56 governs secrets and whether configuration files may carry tokens, and R57 governs the broader XDG directory set beyond configuration (data, cache, state, runtime). Those couplings delimit this item’s scope. R54 decides how many configuration tiers exist, how they are discovered, and how they are ordered; R55 and R56 will later decide what happens when discovered files are broken or contain secrets, and R57 will decide how data and cache paths are discovered. This report therefore deliberately remains secret‑agnostic and error‑handling‑neutral, and focuses purely on discovery and layering semantics.

## Methodology and Survey Approach

The methodology mandated for this decision is deliberately “forest before trees”. Before evaluating any particular crate such as `config`, `cfg-rs`, `etcetera`, or `directories`, we must define the category of tooling this item concerns, sketch the ecosystem landscape in terms of built‑ins, standards, and up‑and‑comers, and identify authoritative sources of guidance about configuration directories and layering in Rust and in cross‑platform applications generally. Only then can individual crates be placed sensibly in context, avoiding unconscious bias from familiarity or incidental popularity.

The category decided by R54 is “configuration discovery and layered composition for multi‑mode applications”. It spans several subdomains: directory discovery following XDG or native conventions; configuration file parsing and typed loading; layering and merge semantics across multiple sources; environment variable and CLI argument integration; and project‑local upward search for configuration files akin to Python’s `project_config_file()`. In Rust, this category sits at the intersection of filesystem utilities, CLI frameworks, and configuration libraries. Built‑in tools in the Rust standard library such as `std::env` and `std::fs` provide the raw materials to implement directory discovery and upward search but do not themselves encode cross‑platform conventions like XDG. First‑party and widely adopted ecosystem crates such as `directories`, `directories-next`, `xdg`, and `etcetera` provide higher‑level directory discovery APIs based on XDG and OS APIs, while dedicated configuration libraries such as `config`, `figment`, and `cfg-rs` provide layered composition and typed retrieval.[1][3][4][8][11][12][13][15][18][19][20] Up‑and‑comers such as `cfgmatic_paths` and `user_dirs` explicitly question earlier design decisions and seek to better honor user‑defined XDG variables or to provide richer tier semantics.[19][20]

Authoritative sources for directory conventions include the XDG Base Directory Specification itself (referenced from crates like `xdge` and `xdg`), documentation of OS‑specific directories (Apple Standard Directories, Windows Known Folder API), and Rust ecosystem discussion and evaluation posts. The `xdge` crate documentation provides a concise mapping from XDG configuration environment variables to their defaults—`XDG_CONFIG_HOME` defaulting to `$HOME/.config`, `XDG_CONFIG_DIRS` defaulting to `/etc/xdg`—and names methods such as `XdgDirs::config_home` and `XdgDirs::config_dirs` that expose these semantics in code.[14][17][18] The `directories` and `directories-next` crate documentation elaborates how these XDG variables are interpreted on Linux, and how analogous locations are chosen on Windows and macOS via the Known Folder API and standard Apple directories such as `~/Library/Application Support`.[12][15][16] The `etcetera` crate offers a more flexible strategy‑based approach, allowing applications to choose XDG versus native conventions while providing examples of application‑specific strategies that honor XDG on Linux and macOS for configuration files that users are expected to edit.[11][13] The `user_dirs` crate goes further, explicitly critiquing earlier crates for not respecting XDG variables and positioning itself as an XDG‑first directory provider on all platforms.[20] A blog post by Lars Wirzenius surveys XDG directory crates and evaluates them for compliance with the specification’s defaults, concluding that `directories-next` was, at that time, the clearest winner among the evaluated crates but noting the existence of many alternatives.[17] Together, these sources form an authoritative baseline for directory discovery.

Authoritative sources for configuration layering and precedence include both library documentation and ecosystem practice in real projects. The `config` crate documentation describes a layered system where defaults, explicit programmatic overrides, file sources in multiple formats (JSON, TOML, YAML, INI, RON, JSON5, CORN), and environment variables can all be added as layers, with later layers overriding earlier ones and values accessible via formatted paths akin to JSONPath.[1][4][8] The `cfg-rs` crate similarly advertises composition of multiple sources (files, environment, inline maps, random values), support for live refresh, placeholder expansion, and typed configuration via derives, notably without a `serde` dependency.[3][4] A Rust FAQ article on configuration hierarchy reinforces the same pattern as the Python and TypeScript decision record: defaults at the core, then file values, then environment variables, then CLI flags, with explicit user input always beating implicit settings.[8] It frames this explicitly as a hierarchy where outer boxes override inner ones, matching the owner’s stated `flags > env > project > user > system > defaults` order.

Practice evidence comes from real, well‑regarded Rust projects that must solve similar configuration problems. Starship, a cross‑shell prompt written in Rust, uses a single `starship.toml` configuration file located by default at `~/.config/starship.toml` or overridden via the `STARSHIP_CONFIG` environment variable.[2][5][6][7][9][10] Its documentation describes a discovery order of `STARSHIP_CONFIG` as an explicit path, then `~/.config/starship.toml` as the XDG default, with per‑module defaults used when no configuration file is found.[5][6][7][10] This pattern is simpler than the multi‑tier chain desired for `launch-blueprint`, but it expresses an important precedent: an explicit environment variable override for the configuration path, honoring XDG config directories, and falling back to built‑in defaults when no file is found. The Starship cheatsheet and guide reiterate these behaviors, and a DeepWiki configuration entry shows deployment of Starship’s configuration via GNU Stow to `~/.config/starship/starship.toml`, together with an explicit export of `STARSHIP_CONFIG` in `~/.zshrc`, indicating active use of the override mechanism in practice.[5][6][7][9][10] This provides a concrete example of cross‑shell configuration resolution with XDG semantics.

The final methodological step is fit analysis. Rather than choosing crates as abstract bests, we must judge them against the specific shape of `rs-launch-blueprint`: it is a template for CLI+library+web service applications. That means it must work well for long‑running server processes, for user‑invoked CLI commands, and for library consumers embedding configuration. It must support layered configuration with deterministic precedence across system, user, and project file tiers, plus environment and CLI, and it must be composable enough that later items (R55, R56, R57) can extend its behavior without being constrained by monolithic library assumptions. Crates that hard‑code precedence in ways that conflict with the owner’s contract or that ignore XDG variables on macOS when configuration files are meant to be user‑editable are poor fits, regardless of their popularity. Conversely, crates that defer precedence to the application and expose directory tiers are well‑suited even if they are relatively new and require re‑verification.

With this methodology established, we can now turn to the landscape and then to the principles and implementation patterns that must be preserved.

## Decision Body

### Landscape

Within the category of configuration discovery and layering, the Rust field can be mapped into three bins: built‑in or first‑party tooling, established industry standards, and up‑and‑comers. This mapping is not about popularity alone; it reflects maturity of design, breadth of adoption, and alignment with authoritative guidance like the XDG specification.

The built‑in or first‑party tooling bin includes the Rust standard library and minimal directory‑helper crates. `std::env` provides access to environment variables, including `HOME`, `XDG_CONFIG_HOME`, and `XDG_CONFIG_DIRS`, and `std::fs` provides filesystem traversal. These suffice to implement hand‑rolled configuration directory discovery and project‑local upward search. Minimal crates such as `dirs-lite` fall close to this bin, offering a dependency‑free way to obtain user config, data, and cache directories across platforms.[16] `dirs-lite` documents that on Linux it uses `$XDG_CONFIG_HOME` or `$HOME/.config`, on macOS it uses `$HOME/Library/Application Support` by default, and on Windows it uses `%APPDATA%`, with an optional `favor-xdg-style` feature to return XDG‑style paths (`$HOME/.config`, `$HOME/.local/share`, `$HOME/.cache`) on macOS.[16] These crates are lightweight and simple, but they only provide a single config directory per user, not a chain of system/user/project directories, and their macOS defaults may conflict with the owner’s F247 requirement unless the XDG‑style feature is explicitly enabled.

The established industry standard bin for directory discovery includes crates such as `directories`, `directories-next`, `xdg`, and `etcetera`. The `directories` and `directories-next` crates provide platform‑specific locations for configuration, cache, and data directories, leveraging the XDG base directory specification on Linux, the Known Folder API on Windows, and Apple Standard Directories on macOS.[12][15][17] Their documentation shows that `ProjectDirs::config_dir()` yields paths like `/home/alice/.config/barapp` on Linux, `C:\Users\Alice\AppData\Roaming\Foo Corp\Bar App\config` on Windows, and `/Users/Alice/Library/Application Support/com.Foo-Corp.Bar-App` on macOS.[12][15] This confirms both their portability and a design choice: on macOS they use Application Support rather than XDG directories, and they do not expose multiple directories such as `XDG_CONFIG_DIRS` as a search chain. The `xdg` crate, referenced via the Piston documentation for `xdg::BaseDirectories`, directly implements the XDG Base Directory Specification.[18] Its API examines environment variables such as `XDG_CONFIG_HOME`, `XDG_CONFIG_DIRS`, and others, defaulting them according to the spec (e.g., `XDG_CONFIG_HOME` defaulting to `$HOME/.config`, `XDG_CONFIG_DIRS` defaulting to `/etc/xdg`). It exposes methods such as `place_config_file()` to locate or create configuration files in appropriate directories, automatically creating leading directories.[18] This crate is Unix‑only, but it provides a canonical implementation of XDG semantics, which can be instructive even when a cross‑platform crate is needed. `xdge` similarly exposes `config_home` and `config_dirs` methods with explicit documentation of `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` defaults.[14] `etcetera` sits slightly differently: it offers flexible strategies for configuration, data, and cache directories, allowing applications to choose between XDG, Apple, Windows, Unix single‑folder, and other conventions, and to choose application‑specific strategies such as `choose_app_strategy()` that name the application and follow XDG on Linux and macOS for configuration.[11][13] `etcetera` is used by `confy`, a configuration convenience crate that moved from `ProjectDirs` to `etcetera` specifically to allow both XDG and native paths and now defaults to XDG on macOS.[13] This migration is strong practice evidence for the owner’s F247 concern: earlier cross‑platform crates that ignored `XDG_CONFIG_HOME` on macOS were actively reconsidered, and newer versions now honor XDG semantics, at least in some strategies.

In the established standards bin for configuration layering and parsing, the `config` crate stands out. It provides a layered configuration system where users can set defaults, explicit values, read from multiple file formats (JSON, TOML, YAML, INI, RON, JSON5, CORN), and read from environment variables, with loosely typed access via formatted paths like `redis.port` or `databases.name`.[1][4][8] It supports feature flags to enable or disable support for particular file formats, and its layering semantics naturally mirror the owner’s desired precedence order, albeit without a baked‑in CLI precedence. Other configuration crates listed in the configuration library index include `figment`, `twelf`, `better-config`, `pi_config`, and many more.[4] Many of these support layered configuration from files, environment, and CLI, sometimes integrated with `clap`. For example, `figment` is known in the ecosystem for its “con-free” configuration layering, and `twelf` advertises 12‑Factor‑friendly layered configuration. However, this report focuses on crates for which we have documentation in the provided search results, which include `config`, `cfg-rs`, `confy`, and the broader listing of configuration crates.[1][3][4][13]

The up‑and‑comers bin includes crates that explicitly respond to shortcomings in established libraries. `user_dirs` positions itself as a respectful, XDG‑first user directories implementation for obtaining home, cache, config, data, runtime, and state directories, explicitly criticizing earlier crates such as `dirs` and `directories` for refusing to respect user‑defined XDG variables and positioning itself as a simpler alternative to `etcetera` with a single strategy that always prefers XDG variables and then system directories.[20] `cfgmatic_paths` provides a platform‑agnostic way to discover configuration directories organized into user, local, and system tiers, using XDG semantics on Unix/Linux and macOS CLI applications, Apple Application Support for macOS GUI applications (with a feature), and appropriate system directories for other platforms.[19] It explicitly uses `XDG_CONFIG_HOME/<app>` as the user‑tier path, optionally supports legacy `~/.<app>rc` files, and uses `XDG_CONFIG_DIRS/<app>` (default `/etc/xdg/<app>`) as the system tier on Unix/Linux.[19] This tiered design aligns unusually well with the owner’s multi‑tier configuration chain. On the configuration composition side, `cfg-rs` is a relatively lightweight, flexible loader that supports multiple sources (files, environment, inline maps, random values), live refresh, placeholder expansion, and derive‑based typed configs without depending on `serde`.[3] It allows deterministic priority of layers via numbered registration and supports environment variable sources with prefixes such as `APP_`, as well as file sources at configurable layers.[3] These design elements make it an attractive choice for implementing a layered configuration hierarchy like the owner’s default, while keeping precedence under application control rather than hard‑coding it.

Practice evidence complements this landscape. The confy crate’s documentation states that it uses `etcetera` to store configuration files and has explicitly moved from `ProjectDirs` to `etcetera` in version 2.0.0 to allow both XDG and OS native paths, adopting XDG directories as the default even on macOS.[13] This shows an ecosystem trend toward honoring XDG semantics consistently. Starship’s explicit use of XDG config directories and of the `STARSHIP_CONFIG` env override has been widely adopted and is documented and supported in multiple languages and cheatsheets.[2][5][6][7][9][10] Rust projects that use `config` or `figment` often follow a precedence pattern similar to the Rust FAQ article’s defaults < file < env < CLI order, and they integrate with `clap` for CLI parsing, which has become the de facto standard for Rust CLI apps.

Within this landscape, it is clear that there is no single, mandatory choice of directory or configuration library. However, certain patterns emerge as authoritative guidance: XDG semantics for user configuration directories, particularly honoring `XDG_CONFIG_HOME` on Linux and macOS; a layered configuration hierarchy where outer scopes override inner ones; and explicit CLI override via flags and environment aliases. These patterns, rather than particular crates, are the shared principles we must preserve.

### Principles and implementation

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

### Recommendation

Within the surveyed landscape and principles, the recommended stack for `rs-launch-blueprint` under R54 is a bundle composed of three main elements: a configuration directory discovery crate that exposes user, local, and system tiers in a way compatible with XDG and OS conventions and with F247; a configuration composition crate that supports multiple sources and deterministic precedence without imposing a fixed policy incompatible with the owner’s contract; and the `clap` CLI framework with a `--config` flag whose value may come either from CLI input or from an environment alias.

For directory discovery, this report recommends `cfgmatic_paths` as the dominant choice. Its documentation explicitly models configuration directories into three tiers—user (`ConfigTier::User`), local (`ConfigTier::Local`), and system (`ConfigTier::System`)—and states that on Unix/Linux it uses XDG Base Directory Specification semantics, with user configs at `$XDG_CONFIG_HOME/<app>` (default `~/.config/<app>`) and system configs at `$XDG_CONFIG_DIRS/<app>` (default `/etc/xdg/<app>`).[19] It also supports macOS CLI applications by using XDG semantics as on Unix/Linux, and macOS GUI applications by using `~/Library/Application Support/<bundle-id>/` as the user tier and `/Library/Application Support/<bundle-id>/` as the system tier when the `macos-gui` feature is enabled.[19] This design directly encodes the multi‑tier chain the owner desires and honors XDG variables on Ubuntu and macOS for CLI applications as required by F247. It presents a high‑level API to obtain directories per tier, avoiding the need for hand‑rolled `XDG_CONFIG_DIRS` parsing.

For configuration composition, this report recommends `cfg-rs`. Its documentation demonstrates registering multiple sources in deterministic layered order: a Cargo environment source at layer 0, an inline key‑values source at layer 1, a random source at layer 2 (optional), an environment prefix source at layer 3, and file sources at layer 4 and above.[3] It supports file sources such as YAML and TOML via feature flags, and environment variable sources with a configurable prefix such as `APP_`.[3][4] It also supports live refresh and typed configuration via derive‑based structures, without depending on `serde`, which keeps the dependency tree light and MSRV manageable.[3] Most importantly, `cfg-rs` does not hard‑code precedence beyond the registration order; the application can register sources representing system, user, project, environment, and CLI overrides in the owner’s desired order, achieving `defaults < system < user < project < env < CLI` semantics.[3][8] Environment and CLI overrides can be applied as separate steps, ensuring CLI flags override environment variables.

For CLI parsing, the report recommends `clap`. While `clap` is not mentioned in the search results, it is widely adopted in the Rust ecosystem for CLI applications and provides facilities for associating environment variables with flags via attributes such as `.env("PLBP_CONFIG")` on arguments. The key behavior required here is that if both CLI and environment provide a value for `--config`, the CLI value should win; `clap`’s semantics match that pattern. In the RustFAQ article on configuration hierarchy, the author explicitly recommends using `clap` for any app that operators will run manually, and positions manual parsing as acceptable only for trivial configurations.[8] This reinforces `clap` as the ecosystem’s standard solution for CLI parsing and for configuration flags.

Beyond these three members, a small amount of custom implementation is needed. Specifically, project‑local upward search must be implemented by hand, as there is no crate in the survey that provides exactly this behavior. The idiomatic Rust pattern is a loop that starts from `std::env::current_dir()` and repeatedly calls `.parent()` on the path; at each directory, it checks for the presence of a configuration file with an agreed name (e.g., `<tool>_config.toml`) and stops when it finds one or when it reaches the filesystem root. This pattern is simple, explicit, and consistent with Python’s `project_config_file()` implementation, preserving the cross‑ecosystem principle without needing additional crates.

The cross‑repo contract is preserved by making this bundle the canonical realization of R54 in Rust and by recommending corresponding changes in Python and TypeScript where necessary. Python already has system, user, and project tiers; its implementation can remain but may eventually adopt a directory crate or module similar to `cfgmatic_paths` for clarity. TypeScript currently lacks system and project tiers; its future revisions should implement those tiers using a Node.js‑appropriate XDG and OS directory resolver. However, this report does not change Python or TypeScript implementations; it supplies the rationale and design for future alignment.

The following sections now detail each bundle member, its landscape, principles, and fit, before returning to compatibility, parameters, and validation.

### Members

#### cfgmatic_paths

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

#### cfg-rs

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

#### clap (CLI and `--config` / env alias)

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

#### Project-local upward search (pattern, not crate)

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

### Compatibility

Compatibility among the bundle members—`cfgmatic_paths`, `cfg-rs`, `clap`, and the project‑local pattern—must be proven conceptually and then empirically. Conceptually, the members operate at distinct layers: `cfgmatic_paths` discovers directories; the project‑local pattern discovers a specific file; `cfg-rs` composes configuration from files, environment, and overrides; and `clap` parses CLI flags and environment aliases. They do not conflict in dependencies or responsibilities.

While no existing repository is known from the provided search results that uses `cfgmatic_paths` and `cfg-rs` together, their APIs are sufficiently orthogonal that integration is straightforward. `cfgmatic_paths` returns `PathBuf` values representing directories; these can be passed to `cfg-rs`’s `register_file()` method to add file sources.[3][19] `clap` produces strings or paths for `--config`; these can be used to bypass directory discovery and register only the specified file in `cfg-rs`. The project‑local pattern returns a `PathBuf` as well, making it compatible with `cfg-rs`.

Empirical compatibility will be verified via integration tests in the `rs-launch-blueprint` template. A configuration module will be built that uses all members, and tests will run on `ubuntu-latest` and `macos-latest` CI runners to ensure behavior. Because this report cannot access a shared adopter repository, compatibility is proven here by design and must be confirmed by implementation.

### Parameters

R54 owns the configuration discovery and layering contract. Under this report’s recommendation, R54 owns `config_precedence = flags > env > project > user > system > defaults` and `config_tiers = {system, user, project, defaults}`. It also owns `config_directory_semantics = XDG-first on Ubuntu and macOS for CLI apps`, consistent with F247. It assumes `rust-edition = 2024`, `msrv-policy = stable minus two minor versions`, `license = MIT OR Apache-2.0`, and `target-os-matrix = ubuntu-latest, macos-latest`.

No consumed parameter needs to change for this bundle, so no `CONFLICT:` lines are required. However, the baseline review for F247 in relation to macOS directory semantics indicates that any future use of `directories` or `directories-next` for configuration directories would be in conflict with F247 and must be avoided.

### Migration implications

Migrating to this bundle in the `rs-launch-blueprint` template will involve adding dependencies for `cfgmatic_paths`, `cfg-rs`, and `clap`, and implementing a configuration module that wires them together. File‑level changes include creating a `config/mod.rs` file that defines functions for directory discovery, project search, configuration loading, and CLI integration. Existing placeholder configuration logic will need to be replaced.

Documentation in the template must be updated to describe the configuration hierarchy and directory semantics, referencing system, user, and project tiers and explaining `--config` behavior and environment aliases. Python and TypeScript documentation should eventually be aligned to match the cross‑ecosystem principles, even if their implementations differ initially.

### Validation strategy

Validation strategies for this bundle involve unit, integration, and manual tests. For directory discovery, tests must verify that `cfgmatic_paths` honors `XDG_CONFIG_HOME` and `XDG_CONFIG_DIRS` on Ubuntu and macOS, returns appropriate directories per tier, and behaves correctly when environment variables are unset.[14][17][18][19][20] For configuration composition, tests must verify that `cfg-rs` layers sources according to the desired precedence, and that environment variables and CLI flags override file tiers appropriately.[3][8] For CLI integration, tests must verify `--config` and `PLBP_CONFIG` alias behavior, and confirm that when `--config` is set, directory discovery is bypassed.

Manual tests will involve running the template application with different configurations: system files only, user files only, project files only, environment overrides, CLI overrides, and `--config` replacements. Observed behavior must match acceptance criteria.

The following is an example of a planned integration test scenario:

1. Create three configuration files: `/etc/xdg/plbp/plbp_config.toml` with `server.port = 8000`, `$HOME/.config/plbp/plbp_config.toml` with `server.port = 8100`, and `<project>/plbp_config.toml` with `server.port = 8200`.
2. Run the application from within `<project>` with no environment variables or flags. The loaded configuration should report `server.port = 8200`.
3. Set `PLBP_SERVER_PORT=8300` and rerun; the loaded configuration should report `server.port = 8300`.
4. Run the application with `--server-port 8400`; the loaded configuration should report `server.port = 8400`.
5. Run the application with `--config /tmp/custom.toml`, where `/tmp/custom.toml` sets `server.port = 8500`. The loaded configuration should report `server.port = 8500`, and values from the discovered system/user/project files should be ignored.

These tests will be implemented after the bundle is integrated.

### Confidence & re-verify trigger

Confidence in the recommended bundle is high for principles and moderate for specific crates, due to the offline nature of this analysis. The design aligns with authoritative guidance (XDG specification, Rust FAQ, practice in Starship and confy) and preserves cross‑ecosystem principles. However, before production adoption, each member’s maintenance state, metrics, and advisories must be checked.

Re‑verify triggers include:

- Discovery of RustSec advisories for `cfgmatic_paths` or `cfg-rs`.
- Major changes in XDG or OS directory conventions.
- Maintenance concerns (e.g., repositories becoming dormant).
- Changes in `rs-launch-blueprint`’s MSRV or OS matrix.

In such cases, R54 should be revisited and the bundle reconsidered.

### Sources

This report draws on several types of sources. Directory semantics and XDG behavior are grounded in the documentation of `xdge` and `xdg` crates, which summarize environment variables and defaults, and in a blog post evaluating XDG directory crates.[14][17][18] Cross‑platform directory behavior and project directories are drawn from `directories` and `directories-next` documentation.[12][15][16] `etcetera` and `confy` provide evidence of strategy‑based directory discovery and a migration from project directories to XDG semantics on macOS.[11][13] The `user_dirs` crate documentation provides an XDG‑first perspective on directory semantics.[20]

Configuration layering and precedence are informed by the `config` and `cfg-rs` documentation, and by the Rust FAQ article on configuration hierarchy, which explicitly recommends layering defaults, file values, environment variables, and CLI flags, and suggests using crates like `config` and `dotenvy` for complex hierarchies.[1][3][4][8] The configuration library index lists alternative crates such as `figment` and `twelf`, providing a broader landscape.[4]

Practice evidence for XDG config directories and environment overrides comes from Starship’s configuration documentation, cheatsheet, and DeepWiki entries, which describe configuration files at `~/.config/starship.toml`, overrides via `STARSHIP_CONFIG`, and cross‑shell configuration behavior.[2][5][6][7][9][10] These sources show how XDG semantics and environment overrides are used in real Rust projects.

All sources were retrieved prior to the knowledge cutoff using docs.rs, project documentation sites, and independent write‑ups, and are cited inline using the provided index.

## Conclusion

The R54 decision on configuration discovery tiers for `rs-launch-blueprint` demands more than a choice of crates; it requires a careful articulation of shared cross‑ecosystem principles and a disciplined mapping of those principles into Rust’s tooling landscape. This report has identified the core principle as a layered configuration hierarchy with explicit scopes—system, user, project, defaults—overlaid by environment variables and command‑line flags in a well‑defined precedence order, with `--config` acting as a discovery replacement rather than a further override. It has shown that this principle is already expressed in Python’s implementation, TypeScript’s decision record, and authoritative guidance such as the Rust FAQ article, and that ecosystem practice (e.g., Starship and confy) reinforces related aspects like XDG semantics and environment overrides.

Surveying the Rust ecosystem, the report has mapped directory‑discovery and configuration‑composition crates into built‑in tools, established standards, and up‑and‑comers, and has applied fitness gates to ensure compatibility with owner constraints like F247, MSRV, and OS matrix. It has concluded that older directory crates like `directories` and `directories-next`, while useful, are not suitable for R54 because they ignore `XDG_CONFIG_HOME` on macOS for configuration directories, conflicting with F247. Instead, up‑and‑comers like `cfgmatic_paths` and `user_dirs`, along with strategy‑based crates like `etcetera`, provide better alignment.

For configuration composition, `cfg-rs` emerges as a strong candidate, offering multi‑source layering with deterministic precedence and typed configuration without heavy dependencies, aligning with the Rust FAQ’s hierarchy and the owner’s desired precedence. Combined with `clap` for CLI parsing and environment aliasing, and with a small hand‑rolled project‑local upward search pattern, these elements form a coherent bundle that can realize the cross‑repo contract in Rust.

The report recommends a bundle consisting of `cfgmatic_paths` for directory discovery, `cfg-rs` for configuration composition, `clap` for CLI parsing and `--config`/env alias integration, and a standard‑library‑implemented upward search pattern for project‑local configuration files. It details how these members interact, how they preserve cross‑ecosystem agreement at the architectural pattern level, and how they can be validated via tests and integration runs. It flags one baseline behavior for review—F247’s macOS semantics—and strengthens it by rejecting directory crates that ignore XDG on macOS for CLI configuration, aligning with confy’s migration and user_dirs’ design.

Future work will involve implementing this bundle in the `rs-launch-blueprint` template, writing the described tests, and revisiting Python and TypeScript implementations to align with the shared principles. As the ecosystem evolves, R54 may be revisited, but the core principle of layered, scoped configuration with deterministic precedence is likely to remain, providing a stable foundation for all three language ports.

## Sources

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

## Cost

Total: $0.6899
