### Landscape

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

### Principles and implementation

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

### Recommendation

Adopt this stack:

1. **A small, std-only `ConfigDiscovery` adapter** implementing the exact XDG system/user contract, nearest-project search, explicit-file replacement, and ordered `Layer` metadata.
2. **`config` 0.15.25**, with `default-features = false` and `features = ["toml"]`, for ordered source composition and typed deserialization.
3. **`clap` 4.6.7**, with `features = ["derive", "env"]`, for the CLI and `<TOOL>_CONFIG` selector alias.
4. Existing **Serde derive** for the typed `Settings` model; it is foundational serialization infrastructure rather than an R54-specific selection.

Do not add `directories`, `etcetera`, or `xdg` as runtime dependencies for R54. Keep `xdg` 3.0.0 as the maintained reference and first fallback if the custom adapter grows beyond the narrow specified surface.

This recommendation is conditional on the mechanical pre-merge MSRV, advisory, and API-metric checks listed below; no functional candidate currently displaces it.

---

### Members

#### std-only `ConfigDiscovery` adapter

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

#### `config` 0.15.25

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

#### `clap` 4.6.7 with `derive` and `env`

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

### Compatibility

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

### Parameters

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

### Migration implications

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

### Validation strategy

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

### Confidence & re-verify trigger

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

### Sources

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

## Sources

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
