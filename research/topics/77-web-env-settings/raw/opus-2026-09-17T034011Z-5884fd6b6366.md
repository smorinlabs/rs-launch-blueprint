# R77 — web-env-settings (crate, Focused) — Claude Opus 5 raw research report

Actor: Opus research worker, model `claude-opus-5`, run
`research/runs/R77/2026-09-17T034011Z-5884fd6b6366`. Item kind `crate`, effort tier
`focused`. The Codex leg of this run is deferred under owner ruling W1-CODEX3 of
2026-09-18 (the Codex account is at its usage limit), so this report is written to stand
alone for the synthesizer.

**Retrieval date for every figure and quotation below: 2026-09-18 (UTC).** The session
clock read `2026-09-18T22:01:04Z` when the first endpoint was called
(`date -u +%Y-%m-%dT%H:%M:%SZ`), and every call in this run was made after it.

**Everything marked *measured* was executed in this run** in a throwaway Cargo workspace
under a `$TMPDIR` subdirectory created and deleted by this run. No Rust file was written
into the repository; `rs-launch-blueprint` has no Rust source yet, so nothing here is an
implemented result. Toolchain used: `rustc 1.98.0 (88d9e12ae 2026-08-18)` /
`cargo 1.98.0 (797e8a9bc 2026-08-05)` on `aarch64-apple-darwin`.

### Landscape

**The category this item decides.** Not "a config crate". Precisely: *the mechanism that
turns the process environment into one typed, validated Rust value for the optional `web`
surface, under a prefix derived from the single app-name constant, plus the path by which
that value reaches request handlers.* Three properties make it a category of its own
rather than a slice of the general config problem, and each one eliminates candidates
below:

1. It is **env-only**. There is no file tier and no flag tier for these knobs. R69's
   owned `web-extra-surface` states it: the serve binary "carries the org CLI Design
   Standard v1.4.14 R4.1 required global core and nothing beyond it … while every service
   knob such as host, port, log format and drain deadline stays an environment variable
   named by R77".
2. It must be **constructible from an injected variable set**, not only from the real
   process environment — because Rust edition 2024 made `std::env::set_var` an `unsafe fn`
   (see below), so the template's own tests cannot set process environment to exercise the
   loader without breaking R06's unsafe policy.
3. Its failure message must **name the offending variable, its value and the expectation**,
   because R67's published envelope requires `hint` to "name the offending input per R7.6".

**Bin 1 — built-in or first-party toolchain.**
`std::env::vars_os` / `std::env::var_os` plus `str::FromStr`, with the template writing the
mapping. `serde` 1.0.229 sits beside it: it is already a **non-optional** dependency of this
template (R69's owned value says the `web` feature "does not gate … `serde`, `serde_json`"),
so using it costs nothing, but it is a *data-model* crate, not an environment reader — the
env-reading half always comes from one of the bin-2 wrappers or from template code.

**Bin 2 — established industry standard.**
`config` 0.15.25 (maintained in the `rust-cli` GitHub organisation — the same organisation
that hosts `clap`, the parser R60 selected); `figment` 0.10.19 (the configuration engine
Rocket is built on, by Rocket's author); `envy` 0.4.2 (the original serde-over-environment
idiom in Rust); `envconfig` 0.11.1 (derive-macro, per-field env names).

**Bin 3 — up-and-comers.**
`confique` 0.4.0 (derive-macro, per-field `#[config(env = "…")]`, layered, generates a
reference config file); `serde-env` 0.3.0; `envious` 0.3.0 (nested structures from env).

**Adjacent and excluded by category, not by a gate.** `dotenvy` 0.15.7 (90-day downloads
46,188,632 — `GET https://crates.io/api/v1/crates/dotenvy`, `crate.recent_downloads`,
2026-09-18) loads a `.env` file *into* the process environment. It answers a different
question and composes with every row above rather than competing with any of them. It is
named here so a reader does not mistake its download figure for evidence about this
category.

**Authorities used, and why each is authoritative.**

| Source | Why it counts | What it settles here |
|---|---|---|
| The Rust Edition Guide, *Newly unsafe functions* (`https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html`, 2026-09-18) | The Rust project's own edition documentation | `std::env::set_var` and `std::env::remove_var` are `unsafe` in edition 2024: "It can be unsound to call `std::env::set_var` or `std::env::remove_var` in a multithreaded program due to safety limitations of the way the process environment is handled on some platforms." |
| Org CLI Design Standard v1.4.14, blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` in `~/c/cli-standards` | Binding on this template by the programme's rules | `R5.1` precedence chain; `R5.4` **(MUST)** "Environment variables **MUST** use the uppercase `TOOL_*` prefix with a deterministic mapping … Only a **curated subset** of settings **SHOULD** read from the environment … the tool **MUST NOT** auto-expose every flag as an env var."; `R5.5` **(MUST NOT)** secrets in argv |
| The Twelve-Factor App, factor III *Config* (`https://12factor.net/config`, 2026-09-18) | The named source of the requirement py implements — py's module docstring says "12-factor configuration (WEB-30)" | "An app's config is everything that is likely to vary between deploys"; "The twelve-factor app stores config in environment variables"; the litmus test: "whether the codebase could be made open source at any moment, without compromising any credentials" |
| axum 0.8.9 maintainers' API documentation (`https://docs.rs/axum/0.8.9/axum/extract/struct.State.html`, 2026-09-18) | The framework's own published reference | `State` carries one state type; `FromRef` extracts substates; `.with_state(state)` supplies it — the exact mechanism R69 revision 10's `AppState` sketch uses |
| Each candidate's **published source at its exact version**, read from the local registry cache `~/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f/<crate>-<version>/` | The artifact that actually compiles, not a README | `figment`'s `Env` provider reads `std::env::vars_os()` at `src/providers/env.rs:505` and offers no injection point; `envy`'s `from_iter` at `src/lib.rs:301`/`:324` does; `envy` splits sequences on `,` at `src/lib.rs:153`; `confique` reads `std::env::var($key)` at `src/internal.rs:54` |
| crates.io REST and GitHub REST | The figure endpoints the prompt names | every number in this report |

A single blog post is not used as an authority anywhere in this report.

**Practice evidence — well-regarded projects, with the evidence that they are well
regarded.** Adoption was not asserted; each row was confirmed through
`GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies` on 2026-09-18, and
each adopter's own prominence is a crates.io download figure from
`GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`).

| Mechanism | Adopter, confirmed dependency | Why the adopter is a relevant, well-regarded reference |
|---|---|---|
| `config` `^0.15.25` (normal, required) | `nextest-runner` 0.124.0 | the library crate behind `cargo-nextest`, the Rust test runner: 1,900,760 90-day / 12,823,277 all-time downloads |
| `config` `^0.15` (normal, required) | `leptos_config` 0.8.10 | the config crate of Leptos, a mainstream Rust web framework: `leptos` 1,287,377 90-day / 4,746,674 all-time |
| `config` (normal, required) | `deadpool` 0.13.1, `rumqttd` 0.20.0 | widely used pool and MQTT-broker crates (reverse-dependency page, sorted by downloads) |
| `figment` `^0.10.6` (normal, required) | `rocket` 0.5.1 | 1,729,285 90-day / 13,490,433 all-time — but **the same maintainer authors both**, so it is adoption, not independent corroboration |
| `figment` `^0.10.18` (normal, required) | `tor-config` 0.46.0 | the Tor Project's Arti (`arti` 7,456 90-day / 96,746 all-time) — a security-critical, institutionally maintained Rust project, and genuinely independent of figment's author |
| `figment` `^0.10.19` (normal, required) | `apple-codesign` 0.29.0, `pijul` 0.15.0, `taplo-lsp` 0.8.0 | independent, widely cited tools |
| `envy` `^0.4.2` (**build**-dependency, required) | `esp-idf-sys` 0.38.1 | Espressif's own Rust bindings — note the kind: a build script, not a service's runtime settings |
| `envy` `^0.4` (normal) | `axum-client-ip` 1.3.1, `twelf` 0.15.0 | axum-ecosystem middleware and a config crate |
| `confique` `^0.4` (normal, required) | `mise` 2026.9.11 | jdx/mise, the polyglot tool-version manager (9,406 90-day / 444,163 all-time on crates.io, which understates it — mise is distributed mainly as a prebuilt binary and through Homebrew) |

**What the practice evidence does *not* show.** No surveyed project uses any of these
crates to do exactly what this item needs — an env-only, prefix-derived settings object
threaded through a web framework's state. `config`'s and `figment`'s adopters all use them
for *layered file + env* configuration, which is R54's problem, not this one; `envy`'s
most prominent adopter uses it in a build script. That gap is itself the finding that
opens `### Principles and implementation`.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

> **Principle (F324).** The web service's runtime knobs are a *single typed value*,
> resolved *once at process start* from the *environment only*, under a prefix *derived
> from the one app-name constant* — so a fork's rename carries without editing call sites,
> a misconfigured deployment fails loudly at boot instead of silently at request time, and
> no handler ever reads the environment.

Source: py `src/py_launch_blueprint/web/settings.py` at pin
`b08bccfb55d05f15e46a83b52c5660b1881d19f5`, whose own docstring states the intent —
"Every knob resolves from an env var with the ``<APP_NAME>_WEB_`` prefix (derived from the
single ``APP_NAME`` source in ``core/paths.py``, so a fork's rename keeps working).
Validation happens at construction, so a misconfigured deployment fails loudly at boot
instead of silently at request time." — and line 38, `ENV_PREFIX: str =
f"{APP_NAME.upper()}_WEB_"`, with `APP_NAME = "plbp"` at `core/paths.py:58` (same pin).
Ledger row F324 (`docs/port/COMMONALITY.md:328`), origin `py-only`, verdict `DIVERGENT`.

**Agreement level: architectural pattern and policy — not library, and not the wire
encoding of individual values.** What must agree across the three repositories:

| Must agree (pattern / policy) | May vary (ecosystem-native) |
|---|---|
| Web knobs come from the environment, never from the CLI's config file | which crate or standard-library facility decodes them |
| One typed value, constructed once at the composition root | whether decoding is derive-driven or hand-written |
| The prefix derives from the single app-name constant | how the derivation is spelled (f-string, `const fn`, code-gen) |
| Construction fails loudly, at boot, naming the variable | the concrete error type and message wording |
| The value reaches handlers through the framework's own state/DI mechanism, never a global | `Depends`/`app.state` in FastAPI, `State`/`FromRef` in axum |
| No secret is a field of this object | — |
| Empty string is unset (falls through to the default) | — |
| List-valued knobs have **one documented encoding** | **which** encoding (py's JSON vs Rust's comma-separated) |

**ts is not a harmonization target for this row, and the reason is structural, not a
preference.** `git ls-tree -r --name-only cb1cbcb2e88b898e8c081b0abbfabc1630079c00` in
`~/c/ts-launch-blueprint` lists no web or server source file, which is what ledger row F303
(`web service exists at all`, origin `py-only`) records. There is no ts `WebSettings` to
agree or disagree with, and `TS_PORT_DECISIONS.md` has no entry on the subject. **The
rationale this item supplies for the follow-on ts project** is therefore forward-looking:
if ts later grows a web service, it should realize the same pattern with its own idiom — a
`zod` schema (already ts's validation crate) over a small reader that takes an injected
`Record<string, string>` rather than reaching `process.env` inside the schema, with the
prefix built from ts's own app-name constant. It should **not** import py's library choice,
because `pydantic-settings` has no ts equivalent whose tradeoffs match. The divergence
analysis marked this row `harmonize: no`; this answer agrees with that label but, as the
prompt requires, on reasoned ground rather than by inheriting it: the *pattern* is shared
and should be stated in all three repos' docs; the *mechanism* is ecosystem-bound in each.

**Whether the inherited architectural pattern remains appropriate in Rust — checked, not
assumed.** Two halves, and only one of them ports.

*The env-only, prefix-derived, boot-validated settings object: ports, and is strengthened.*
The 12-factor argument that motivates it is language-neutral, and R5.4 independently
**requires** the `TOOL_*` prefix and a deterministic mapping. Rust adds a property py
cannot have: the settings type can be made *unconstructible* except through the loader, so
"validated at construction" is enforced by the type system rather than by a convention.

*The lazy-load fallback: does not port, and has already been adjudicated.* py's
`web/deps.py:37` (same pin) re-loads config when the lifespan has not run — "Falls back to
loading lazily when the lifespan hasn't run (raw ASGI callers like schemathesis)". R69
revision 10 raised and carried `BASELINE-REVIEW: F330` against exactly that, on the ground
that axum 0.8.9 makes the unconfigured state unrepresentable because `with_state` is what
turns a `Router<S>` into a service. **This item does not re-raise it; it is designed to
satisfy it**: `WebSettings` has no lazily-loadable global, no `OnceLock`, no
`Default`-on-read path, and the only way a handler sees one is through `AppState`, which
`build_router` requires.

**No `BASELINE-REVIEW:` finding is emitted by this item.** The `BASELINE-REVIEW:` process
adjudicates inherited `COMMON → REUSE` and `ADOPT` rows. F324 is `DIVERGENT` with origin
`py-only`: nothing is inherited, so there is no baseline to challenge. The one adjacent
challenge that exists (F330's lazy fallback) is R69's, is already recorded there, and is
satisfied rather than contested here.

#### Architectural alternatives, compared before any library is chosen

| # | Shape | What it is | Verdict |
|---|---|---|---|
| **A1** | **One layering engine owns web settings too** — `figment`/`config` takes defaults → file → env and produces `WebSettings` | the owner-reference C9 shape, and what py would look like if `WebSettings` reused `load_config()` | **Rejected.** It adds a *file* tier the surface does not have, and it collides with R54's published stack: R54 (revision 3, owner-accepted) rejected exactly this option for the CLI — "It takes ownership of three things already decided elsewhere: the parse (R52's `toml` 1.1.6), the typed pass (R53's per-key loop over `toml::Table`, `D06`), and the per-layer sanitize step and warning list (R55, `D01`, `D03`)". Adopting it for the web surface alone would put a rejected engine in the dependency tree for a surface that needs none of its layering. |
| **A2** | **Web settings reuse the CLI's `Config`** — one type, one loader, `RSLBP_*` names for everything | superficially DRY | **Rejected.** It breaks R5.4's curated-subset rule (host, port, drain deadline and log format would either become CLI flags — which R69's R4.1 table forbids — or unbacked env vars in the CLI's namespace), it puts a `token` field next to web knobs, contradicting R56, and it makes `--config` on `rslbp-serve` silently able to set a listen address, which `R5.2`'s file semantics were never meant to carry. |
| **A3** | **Two settings objects, disjoint namespaces** (recommended) | `WebSettings` env-only under `RSLBP_WEB_`; the core `Config` from R53/R54/R55 via the same composition root the CLI uses; `rslbp-serve` builds both | **Selected.** It is py's actual shape — `create_app` takes `WebSettings`, `_lifespan` calls `load_config()` — and it keeps each surface's rules intact. `--config` on the serve binary binds the **core** `Config`'s file, exactly as `R5.2` describes, and touches no web knob. |
| **A4** | **serde `Deserializer` over env** vs **explicit per-field parse** — a sub-choice inside A3 | (a) a derive maps struct fields to variables; (b) the loader names each variable and parses it with `FromStr` | **(b) selected**, and this is the choice a reasonable owner could weigh the other way. (b) gives an exact error per field, is trivially injectable, and makes the curated set literally readable in one function. (a) is shorter to write and harder to drift. The measured error strings below are the ground. |

**How the recommended design preserves each principle.**

```rust
// crates/web/src/settings.rs  — illustrative; P03 writes the real thing.
#![forbid(unsafe_code)]
use std::{collections::HashMap, ffi::OsString, net::IpAddr, time::Duration};

/// R57's single namespace segment, re-used, not re-declared.
use crate::TOOL_NAME;                       // = "rslbp"

const SUFFIX: &str = "_WEB_";
const PREFIX_LEN: usize = TOOL_NAME.len() + SUFFIX.len();

const fn upper_concat<const N: usize>(name: &str, suffix: &str) -> [u8; N] {
    let (n, s) = (name.as_bytes(), suffix.as_bytes());
    let mut out = [0u8; N];
    let mut i = 0;
    while i < n.len() { out[i] = n[i].to_ascii_uppercase(); i += 1; }
    let mut j = 0;
    while j < s.len() { out[i + j] = s[j].to_ascii_uppercase(); j += 1; }
    out
}
const PREFIX_BYTES: [u8; PREFIX_LEN] = upper_concat::<PREFIX_LEN>(TOOL_NAME, SUFFIX);

/// `"RSLBP_WEB_"`, derived at compile time from the one app-name constant.
pub const WEB_ENV_PREFIX: &str = match core::str::from_utf8(&PREFIX_BYTES) {
    Ok(s) => s,
    Err(_) => panic!("app name must be ASCII"),
};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WebSettings {
    pub host: IpAddr,
    pub port: u16,
    pub graceful_shutdown: Duration,
    // log_level / log_format: named here, valued by R58
    // cors_origins, rate_limit, idempotency_*, metrics_enabled, otel_enabled:
    // named here, semantics owned by R72-R79
}

impl WebSettings {
    /// The whole surface. `from_env` is the only caller that touches the process.
    pub fn from_vars<I>(vars: I) -> Result<Self, SettingsError>
    where I: IntoIterator<Item = (OsString, OsString)> { /* ... */ }

    pub fn from_env() -> Result<Self, SettingsError> { Self::from_vars(std::env::vars_os()) }
}
```

- *Derived prefix.* `WEB_ENV_PREFIX` is a `const`, computed from `TOOL_NAME` by a `const fn`
  with no `unsafe`. **Measured:** it compiles and evaluates on stable 1.98.0, edition 2024,
  and a fork changing `TOOL_NAME` to `"acme"` yields `"ACME_WEB_"` with no other edit
  (probe A, and probe C's `prefix_is_derived_from_the_single_app_name_constant`). The const
  path is available because `core::str::from_utf8` is const-stable, and the `match`/`panic!`
  form replaces `unwrap`, which is not const.
- *One value, once, at the composition root.* `from_env()` is called exactly once, in
  `src/bin/rslbp-serve.rs`, before the router exists. R69 revision 10's `AppState` holds it
  as `Arc<WebSettings>`; `impl FromRef<AppState> for Arc<WebSettings>` lets a handler write
  `State(cfg): State<Arc<WebSettings>>`. **Measured** in probe C against real axum 0.8.9.
- *Fails loudly, naming the input.* See the measured error table below. The error maps to
  R67's published `RSLB203` ("config value invalid" → exit `2`) with no translation layer:
  `SettingsError` carries `var`, `value`, `expected` and `cause`, which is exactly the
  material R67 says `hint` "must be able to name … per R7.6".
- *No handler reads the environment.* `std::env` appears once in `crates/web`, inside
  `from_env`. A `clippy` deny or a grep check in CI can enforce it.
- *No secret field.* R56 (revision 2, owner-accepted) fixes the credential chain as
  `--token-file` > `RSLBP_TOKEN` > stored credential and rules the config file out as a
  token source. `WebSettings` declares no credential of any kind, so the 12-factor litmus
  test holds for the whole web surface and `R5.6`'s redaction obligation has nothing to
  redact in it. The token stays with the core resolver, which the serve binary builds
  through the same composition root the CLI uses.
- *Empty is unset.* `Some(raw) if raw.is_empty() => Ok(default)`. F242 fixes this rule for
  the *token*; applying it to every `RSLBP_WEB_*` variable is a consistency choice this item
  makes, not an inherited requirement, and it is what makes an unset-but-exported shell
  variable behave the way an operator expects. **Measured** (probe C,
  `unprefixed_and_empty_are_ignored`).

#### Measured: error-reporting shape for a malformed variable

One input — `RSLBP_WEB_PORT=eighty`, everything else valid — through every candidate, with
`Display` quoted verbatim from the probe run:

| Mechanism | `Display` for `RSLBP_WEB_PORT=eighty` | names the variable? | the value? | the expectation? |
|---|---|---|---|---|
| **template code** | `RSLBP_WEB_PORT: invalid value "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)` | **yes, in full** | yes | **domain-level** |
| `confique` 0.4.0 | ``failed to deserialize value `WebSettings::port` from environment variable `RSLBP_WEB_PORT`: invalid value 'eighty' for type u16: invalid digit found in string`` | **yes, in full** | yes | `u16` |
| `figment` 0.10.19 | ``invalid type: found string "eighty", expected u16 for key "PORT" in `RSLBP_WEB_` environment variable(s)`` | yes (prefix + key) | yes | `u16` |
| `config` 0.15.25 | ``invalid type: string "eighty", expected an integer for key `port` in the environment`` | **no** — lowercased key `port` | yes | "an integer" |
| `envy` 0.4.2 | `invalid digit found in string while parsing value 'eighty' provided by PORT` | partial — `PORT`, no prefix | yes | **no** |

Two crates reconstruct the operator's variable name; two do not. `config`'s message is the
weakest of the five for this purpose: an operator reading the key name `port` must know the
crate's lowercasing rule to get back to `RSLBP_WEB_PORT`.

#### Measured: testability under edition 2024

`std::env::set_var("RSLBP_WEB_PORT", "8000")` in an edition-2024 crate fails to compile:

```
error[E0133]: call to unsafe function `set_var` is unsafe and requires unsafe block
```

That is not a style point. It means the loader's *signature* is a design decision: a loader
that only reads the real process environment cannot be unit-tested by template code that
honours R06's unsafe policy, and process-wide environment mutation is in any case
order-dependent under `cargo test`'s default thread-parallel harness.

| Mechanism | Injected variable set? | Evidence |
|---|---|---|
| **template code** | **yes** — `from_vars(impl IntoIterator<Item = (OsString, OsString)>)` | probe C: four tests pass, none touches process environment |
| `envy` 0.4.2 | yes — `Prefixed::from_iter` | `src/lib.rs:324`; measured working |
| `config` 0.15.25 | yes — `Environment::…​.source(Some(HashMap))` | measured working |
| `confique` 0.4.0 | **no** — `pub fn env(mut self) -> Self` takes no argument and the generated code calls `std::env::var($key)` | `src/builder.rs:38`, `src/internal.rs:54` |
| `figment` 0.10.19 | **no** — `Env::raw()`/`Env::prefixed()` only, both reading `std::env::vars_os()` | `src/providers/env.rs:171`, `:198`, `:505`; measured: the injected map was ignored and defaults were produced. Its test story is `figment::Jail`, behind the non-default `test` feature, which calls `std::env::set_var` itself (`src/jail.rs:353`) and serialises tests behind a lock |

#### Measured: cost

Clean `cargo build --release` of a minimal binary that *uses* each mechanism, profile
`strip = true, opt-level = "z", lto = true, codegen-units = 1, panic = "abort"`, target
`aarch64-apple-darwin`; and the normal-dependency package count of a crate that already has
`serde` with `derive` (baseline **8 packages**), counted the way R56 counts it
(`cargo tree --locked -e normal --prefix none | sed 's/ (\*)//' | sort -u | grep -c .`).

| Mechanism | packages (Δ over the 8-package baseline) | stripped binary | what the delta is made of |
|---|---|---|---|
| **template code** | **8 (+0)** | **302,704 B** | nothing |
| `envy` 0.4.2 | 9 (+1) | 302,624 B | `envy` alone |
| `confique` 0.4.0 | 12 (+4) | 302,528 B | `confique`, `confique-macro`, `heck`, `syn` |
| `config` 0.15.25 `default-features = false` | 11 (+3) | 369,232 B | `config`, `pathdiff`, `winnow` |
| `figment` 0.10.19 `features = ["env"]` | 16 (+8) | 385,968 B | `figment`, `pear`, `pear_codegen`, `proc-macro2-diagnostics`, `syn`, `uncased`, `inlinable_string`, `yansi` |
| `config` 0.15.25 **default features** | **55 (+47)** | — | adds `json5`, `ron`, `rust-ini`, `yaml-rust2`, `toml`, `serde_json`, `encoding_rs`, `pest`+`pest_derive`, `async-trait`, … |

Clean release build wall time on the same machine: baseline 8.48 s; `envy` 7.46 s;
`confique` 6.94 s; `config` (no default features) 6.97 s; `figment` 8.92 s; `config`
(default features) **25.88 s**. The first five are within this machine's noise of each
other — the machine was concurrently running network polling — and only the last is a real
signal. Report it qualitatively: everything except `config` with default features is
compile-time-free; `config`'s default feature set is not, and it pulls four document parsers
(`json5`, `ron`, `ini`, `yaml`) into a binary whose only configuration format is fixed by
`R5.2` to TOML, and whose web surface has no file at all.

#### A minimal realistic example, and the executable acceptance check

**Executed in this run** (probe C), against real `axum` 0.8.9 and `tokio` 1.53.1 with
R69's exact feature list, `tower` 0.5.3 as the dev-dependency for the `oneshot` idiom:

```
running 4 tests
test prefix_is_derived_from_the_single_app_name_constant ... ok
test unprefixed_and_empty_are_ignored ... ok
test malformed_port_names_variable_value_and_expectation ... ok
test settings_reach_a_handler_through_state_with_no_process_env ... ok

test result: ok. 4 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out
```

The fourth test is the one that answers the MEDIUM question end to end: it builds
`WebSettings` from an injected variable list, wraps it in `Arc`, puts it in R69's `AppState`,
calls `build_router`, drives one request through `ServiceExt::oneshot` and asserts the
handler saw `["0.0.0.0","9001"]` — with **no process environment touched anywhere**.

**Observable acceptance criteria** (AC1–AC8; AC1–AC5 executed here, AC6–AC8 proposed for
P03):

| # | Criterion | Status |
|---|---|---|
| AC1 | `WEB_ENV_PREFIX == "RSLBP_WEB_"`, and changing the app-name constant alone changes it | **executed** (probes A, C) |
| AC2 | `RSLBP_WEB_PORT=eighty` fails construction with a message naming the variable, the value and the expectation | **executed** (probe C) |
| AC3 | An unprefixed `PORT`, and a set-but-empty `RSLBP_WEB_PORT`, both leave the default in place | **executed** (probe C) |
| AC4 | A handler receives the settings through `State<Arc<WebSettings>>` with no process environment touched | **executed** (probe C) |
| AC5 | The template's own test suite never calls `std::env::set_var` (it cannot, without `unsafe`) | **executed** — the edition-2024 compile error is the enforcement |
| AC6 | `rslbp-serve` with a malformed `RSLBP_WEB_*` variable exits `2`, emits R67's one-line stderr envelope with `code: "RSLB203"`, and writes nothing to stdout | proposed |
| AC7 | `grep -rn 'std::env::' crates/web/src/` matches exactly one file, `settings.rs` | proposed |
| AC8 | `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS` is honoured: a SIGTERM during an in-flight request drains, then exits `143` within the window | proposed (the drain mechanism is R69's; only the variable and its default are this item's) |

#### The variable set, and who owns each value

The **naming rule** and the **mechanism** are this item's for every knob:
`<WEB_ENV_PREFIX><FIELD_IN_SCREAMING_SNAKE_CASE>`, i.e. `RSLBP_WEB_HOST`,
`RSLBP_WEB_PORT`, `RSLBP_WEB_LOG_LEVEL`, `RSLBP_WEB_LOG_FORMAT`,
`RSLBP_WEB_CORS_ORIGINS`, `RSLBP_WEB_RATE_LIMIT`, `RSLBP_WEB_METRICS_ENABLED`,
`RSLBP_WEB_OTEL_ENABLED`, `RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`,
`RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`, `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`,
`RSLBP_WEB_ROOT_PATH` — the same field set py has at
`src/py_launch_blueprint/web/settings.py` (pin `b08bccfb`), renamed by the rule. The
**values and semantics** are not all this item's:

| Knob | Value decided here | Owner of the semantics |
|---|---|---|
| `HOST`, `PORT` | `127.0.0.1`, `8000` — py's defaults, ported unchanged; loopback by default so a container must opt into `0.0.0.0` | this item |
| `GRACEFUL_SHUTDOWN_SECONDS` | **8**, not py's 10 — argued below | this item (the mechanism is R69's) |
| `LOG_LEVEL`, `LOG_FORMAT` | **not decided** — named only | R58 (`logging-pipeline-contract`, registry value `—`, unpublished). R69's dev recipe already exports `<APP>_WEB_LOG_FORMAT` and labels it "names owned by R58/R77" |
| `CORS_ORIGINS` | **not decided** — named only; its *encoding* is fixed below | R76 |
| `RATE_LIMIT` | not decided | R74 |
| `IDEMPOTENCY_*` | not decided | R73 |
| `METRICS_ENABLED`, `OTEL_ENABLED` | not decided | R79, R78 |
| `ROOT_PATH` | not decided | R69/R75 |

**The drain-deadline default is the one *value* this item owns, and it differs from py's on
a platform datum R69 handed over.** R69 revision 10 records, verified at Google's own page
and asserted in `review/evidence/owner-reference-check-r6.log` section E, that Cloud Run
"sends a SIGTERM signal to all the containers in an instance, indicating the start of a 10
second period before the actual shutdown occurs, at which point Cloud Run sends a SIGKILL
signal", and states the hand-off: "on that platform a drain deadline is honoured only if it
is strictly shorter than 10 seconds **measured from SIGTERM**, because the SIGKILL is
unconditional at the deadline and the process never reaches its own exit path — so R67's 143
would never be observed." py's default is `graceful_shutdown_seconds: int = 10`. Ported
literally it is the one value that can never be observed on the platform the programme's own
reference architecture names.

- **Recommended: `8`.** Strictly under the platform kill point, with margin for the drain's
  own completion, stream flush and R67's `ExitCode` return from `main`. It is safe on every
  platform, including the two in `target-os-matrix`, where nothing kills the process at all.
- **Alternative the owner could reasonably prefer: keep `10`** and document that on Cloud
  Run the operator must lower it. Rejected because a default whose only documented effect is
  to be overridden is not a default.
- Cloud Run is **not** adopted as a deployment target by this recommendation. R69 says so
  explicitly and `target-os-matrix` is `ubuntu-latest, macos-latest`. The datum is used as a
  constraint on a default, not as a platform commitment.

**List encoding — a justified difference from py, stated rather than left implicit.** py
encodes list-valued knobs as JSON: its docstring says "List values parse from JSON, e.g.::
`PLBP_WEB_CORS_ORIGINS='["https://app.example.com"]'`". This item fixes the Rust encoding as
**comma-separated, with an empty or unset variable meaning the empty list**:
`RSLBP_WEB_CORS_ORIGINS=https://a.example,https://b.example`. Grounds: it is the Rust
ecosystem's own convention for the same problem — `envy` splits sequences on `,`
(`src/lib.rs:153`), `config` exposes `list_separator`, `figment` exposes
`Env::split(pattern)` — and it is what `PATH`-shaped shell habits produce. Cost, recorded
honestly: JSON round-trips values containing the separator and comma-splitting does not;
no value in this field set (origins, header names) may contain a comma, so the cost is
nil *for this field set* and would have to be revisited if a later item adds a free-text
list. The principle — one documented encoding, validated at boot — is preserved; only the
encoding differs, and it differs on ecosystem-idiom ground.

#### Reconciliation with the owner-supplied reference architecture

`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, treated as a standing input
under `docs/planning/p02/owner-decisions.md` section 11 — not a standard, not a
pre-decision. Every row this item touches, with agreement or a ground for differing:

| Reference row | What it says | This item |
|---|---|---|
| **C9 Config** (table row and §*C9 Config & secrets*) | "**figment** 0.10.x" for layered config, "defaults → TOML file → env"; runner-up `config-rs`, rejected as "less ergonomic layering" | **Differ.** Three measured grounds: (i) `figment` 0.10.19 declares no `rust-version` and so fails fitness gate 2 under the strict reading settled 2026-09-11; (ii) its `Env` provider has no injected-source constructor (`src/providers/env.rs:171`, `:198`, `:505`), so under edition 2024's `unsafe set_var` the template cannot unit-test the loader without `figment::Jail`, which mutates process environment behind a lock; (iii) the *file* tier the row exists to provide is a tier this surface does not have, and R54 (owner-accepted revision 3) already rejected a layering engine for the surface that does. |
| **C9 Secrets** | "`--set-secrets` env-var injection from Secret Manager" is the default; runtime SDK fetch only for rotation | **Agree, and already settled elsewhere.** Secrets arriving as environment variables is exactly R56's `RSLBP_TOKEN` tier. This item adds the sharper rule that keeps the two apart: `WebSettings` declares **no** secret field at all, so the token never enters the web settings object and never appears in anything `R5.6` would have to redact. |
| **C13 Project layout** — `AppState` | "`AppState` holds `PgPool`, config, and shared clients; use `FromRef` to hand sub-state to extractors" | **Agree.** R69 revision 10's sketch is reused verbatim rather than redesigned: `pub config: Arc<WebConfig>` with `impl FromRef<AppState> for Arc<WebConfig>`; this item supplies the type in that slot and renames it `WebSettings` to match py's name and F324's wording. Measured working against axum 0.8.9 in probe C. |
| **C13 Project layout** — dependency injection | "Dependency injection via **traits behind concrete types** … keeps handlers testable without a DI framework" | **Agree.** No DI container; the settings value is constructed by plain code at the composition root and handed in. |
| **Sample `Cargo.toml`**, *Config / secrets* block: `figment = { version = "0.10", features = ["toml","env"] }` | a config crate in the web manifest | **Differ.** `crates/web/Cargo.toml` gains **no** configuration crate under this recommendation. |
| **Sample `main.rs`**: `let cfg = config::load()?;  // figment: defaults → file → env` | load once at startup, three tiers | **Partly agree.** Agree on *load once at startup, before anything that can log or serve* — that is the same invariant F330 and py's `create_app` carry. Differ on the tiers: **defaults → env**, no file tier, for the web knobs; the file tier belongs to the core `Config` the same binary also builds, through R54's stack. |
| **Sample layout**: `src/config.rs  # figment layered config` | one module owns settings | **Agree on the shape, differ on the engine.** One module owns settings: `crates/web/src/settings.rs`. |
| **C15 Cloud Run runbook**, *Graceful shutdown* | SIGTERM then SIGKILL after 10 s | **Agree, and it is load-bearing here** — it is the ground for the `8`-second drain default above. |

**Tally: 4 agree, 3 differ, 1 partly (agree on the invariant, differ on the tiers).** Every
"differ" rests on a measured fact from this run or on an owner-accepted decision, not on
preference.

### Dominant choice

**There is none, and that is the finding.** No crate dominates *this* category in Rust. The
two crates with dominant download figures are dominant in a *larger* category — layered
file-plus-environment configuration:

| Crate | 90-day downloads | all-time | what it actually dominates |
|---|---|---|---|
| `config` 0.15.25 | 18,581,807 | 114,271,945 | layered multi-format configuration |
| `figment` 0.10.19 | 10,072,166 | 38,648,096 | layered configuration, chiefly through Rocket |
| `envy` 0.4.2 | 3,574,490 | 20,877,399 | the thin serde-over-env idiom — the closest fit, and the least maintained |
| `envconfig` 0.11.1 | 1,472,437 | 10,008,963 | per-field derive over env |
| `serde-env` 0.3.0 | 944,262 | 2,883,110 | env → serde with nesting |
| `confique` 0.4.0 | 158,359 | 490,326 | per-field derive, layered, generates a reference config file |
| `envious` 0.3.0 | 66,319 | 570,440 | nested structures from env |

All figures: `GET https://crates.io/api/v1/crates/<name>`, fields `crate.recent_downloads`
and `crate.downloads`, retrieved 2026-09-18.

Read as a field map rather than a leaderboard, the category has a hole exactly where this
item sits: the crates that are *shaped* like the requirement (thin env-only mappers) are
small and lightly maintained, and the crates that are *maintained* like infrastructure are
layering engines whose extra tier this surface must not have. Rust has no
`pydantic-settings`. That is why the recommendation below is a design, not a purchase.

### Qualified shortlist

Four rows below, of which **only two are candidate crates that could decode the
environment** — `config` and `confique`. The other two (`std`, `serde`) are stated because the
recommendation rests on them and because the shortlist must say what the template already
carries. **The shortfall against the prompt's allowance of five is a finding, not an
omission**: fitness gate 2 removes the entire thin-env-mapper bin, because not one of `envy`,
`figment`, `envconfig`, `serde-env` or `envious` declares `rust-version` in its `Cargo.toml`.
The full six-gate table for every candidate, passers included, is under
`### Excluded by gate`.

1. **`std` — the Rust standard library (`std::env::vars_os`, `std::env::var_os`,
   `str::FromStr`)** · role: reads and decodes the environment; the template writes the
   ~40-line mapping · 90-day downloads `inapplicable — not a crates.io package; it ships with
   the toolchain` · all-time `inapplicable`, same reason · stars `inapplicable` · last release
   = the Rust release itself, **1.98.1 (2026-09-01)**, from
   `https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version`,
   retrieved 2026-09-18 · maintenance **active** (the Rust project's six-week train) ·
   notable adopters `inapplicable` · **trade-off:** zero dependency, zero binary cost, the
   best error message and the only shape that is trivially testable under edition 2024 — paid
   for by writing and maintaining one `FromStr` arm per field.
2. **`serde >= 1.0.229, < 2.0.0`, `features = ["derive"]`** · role: **not** the env decoder —
   it is already a non-optional dependency of this template (R69's owned value excludes it
   from the `web` gate) and it types the HTTP request and response bodies the settings object
   sits beside · 90-day **314,208,639** · all-time **1,410,307,353**
   (`GET https://crates.io/api/v1/crates/serde`, 2026-09-18) · stars `not collected — serde was
   not a candidate for the env-decoding slot and no GitHub call was spent on it` · last release
   **1.0.229, 2026-07-18**, declares `rust-version` **1.56** · maintenance **active** · notable adopters:
   effectively the whole ecosystem · **trade-off:** free here, but using it for *environment*
   decoding means adopting one of the wrapper crates below, which is the decision this item
   declines.
3. **`config >= 0.15.25, < 0.16.0`, `default-features = false`** · role: full layered
   configuration engine, used here for only its `Environment` source · 90-day **18,581,807** ·
   all-time **114,271,945** · stars **3,210** (`GET https://api.github.com/repos/rust-cli/config-rs`,
   `stargazers_count`, 2026-09-18) · last release **0.15.25, 2026-06-26** · maintenance
   **active** (`archived: false`, `pushed_at` 2026-09-15, 110 open issues from
   `GET https://api.github.com/search/issues?q=repo:rust-cli/config-rs+is:issue+is:open`,
   `total_count`) · notable adopters: `nextest-runner` 0.124.0, `leptos_config` 0.8.10,
   `deadpool` 0.13.1 · **trade-off:** the only gate-passing crate with an injected-source test
   seam, and the only one maintained at infrastructure scale — but its error names a
   lowercased key rather than the operator's variable, its default feature set pulls 47
   packages and four unused document parsers, and it is the engine R54 rejected for the CLI.
4. **`confique >= 0.4.0, < 0.5.0`** · role: derive-macro settings type with per-field env
   names and an optional file layer · 90-day **158,359** · all-time **490,326** · stars
   **223** (`GET https://api.github.com/repos/LukasKalbertodt/confique`, 2026-09-18) · last
   release **0.4.0, 2025-10-27**, declares `rust-version` **1.68.2** · maintenance
   **stable-quiet** — 11 months since release and `pushed_at` 2025-10-27, which the rubric
   makes a trigger to investigate, not a verdict; investigated below, no `at-risk` signal
   found · notable adopters: `mise` 2026.9.11 · **trade-off:** the best library error message
   measured in this run, and the smallest gate-passing footprint — but its env attribute
   requires a **string literal** (`error: expected string literal` when handed a `const`), so
   the prefix cannot be derived, which is the specific property F324 exists to preserve.

(Ordering note: the rows are given recommendation-first rather than popularity-first,
because the prompt requires every fitness gate to be answered before popularity is weighed
and gate 2 has already decided which crates may appear here at all.)

### Excluded by gate

**Fitness gate 1 (licence) is `inapplicable — owner ruling 2026-09-12 (Q7.B)`** for every
candidate in this report, per `docs/port/OWNER-REVIEW.md` and as applied by R53 revision 2
and R69 revision 10. Licence strings are recorded as metadata only, and nothing is excluded
on licence.

**Gate 2 is applied under the strict reading.** `docs/planning/p02/owner-decisions.md`,
"Two things you should know, which are not decisions", records the owner's provisional
ruling that an undeclared version was "unproven rather than failed", the auditors' argument
for the strict reading, and the withdrawal: "The ruling is withdrawn. One item's exclusions
stand; the other must switch to the runner-up it already recorded." R69 revision 10 applies
it by that name — "Excluded by gate 2, under the strict reading settled 2026-09-11" — and
excludes `watchexec-cli` 2.7.2 on exactly this ground. The *third, stricter* reading, under
which every transitive dependency at every depth must also declare a version, is the one the
same file says "is not on the table unless you put it there"; it is not applied here, which
is why `config`'s transitive `pathdiff` 0.2.3 (no declared `rust-version`) does not exclude
`config`.

**MSRV floor, re-derived in this run rather than carried:** current stable is **1.98.1
(48a229cea 2026-09-01)** (`https://static.rust-lang.org/dist/channel-rust-stable.toml`,
`[pkg.rust] version`, retrieved 2026-09-18), so `msrv-policy`'s "stable minus 2 minor
versions" puts the floor at **1.96**.

**The six gates, every candidate.** Every cell is executed evidence from this run unless the
cell says otherwise.

| Gate | `std` | `serde` 1.0.229 | `config` 0.15.25 | `confique` 0.4.0 | `envy` 0.4.2 | `figment` 0.10.19 | `envconfig` 0.11.1 | `serde-env` 0.3.0 | `envious` 0.3.0 |
|---|---|---|---|---|---|---|---|---|---|
| **1 · licence** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; metadata: the Rust toolchain is `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `Apache-2.0` | same ruling; `MIT OR Apache-2.0` |
| **2 · MSRV ≤ 1.96** | `inapplicable` — `std` *is* the toolchain; the floor is `msrv-policy`'s own | declares **1.56** — passes | declares **1.85.0** — passes | declares **1.68.2** — passes | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** |
| **3a · RustSec** | `inapplicable` (not a crates.io package) | none | none | none | none | none | none | none | none |
| **3b · `unsafe` posture** | the standard library contains `unsafe`; the template's own module compiles under `#![forbid(unsafe_code)]` — **measured**, and the recommended design contains none | not re-audited here; R53 revision 2 records 2 `unsafe` blocks, both `str::from_utf8_unchecked` | **0** `unsafe` lines in `config-0.15.25/src/`; no crate-level lint | **0** in `confique-0.4.0/src/` and `confique-macro-0.0.13/src/`; no crate-level lint | **0** in `envy-0.4.2/src/lib.rs` | **0** in `figment-0.10.19/src/` — but `Jail` mutates process environment (`src/jail.rs:353`), which is the hazard edition 2024 marks `unsafe` | not extracted | not extracted | not extracted |
| **4 · ubuntu-latest + macos-latest** | yes by construction | yes | yes — no platform `cfg` in the `Environment` source path; built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | not built here | not built here | not built here |
| **5 · default features / async coupling** | none | `derive` only; no runtime | default features are `toml, json, yaml, ini, ron, json5, convert-case, **async**` — the `async` default pulls `async-trait`, a proc macro, **not** a runtime; `default-features = false` drops all of it | no default features of consequence; no async coupling | none; no async coupling | `env` pulls `pear` + `parse-value`; `test` pulls `tempfile` + `parking_lot`; no async coupling | not extracted | not extracted | not extracted |
| **6 · binary size / compile time** | **+0 packages, 302,704 B** stripped baseline | already in the tree; no marginal cost | **+3 packages, 369,232 B** (+66 KB) with default features off; **+47 packages and ~3× clean build** with them on | **+4 packages, 302,528 B** — no measurable size cost | **+1 package, 302,624 B** | **+8 packages, 385,968 B** (+83 KB) | not measured | not measured | not measured |

**Excluded, with the ground.**

- **`envy` 0.4.2 — excluded by gate 2** (declares no `rust-version`;
  `GET https://crates.io/api/v1/crates/envy/versions`, newest non-yanked `0.4.2`,
  `created_at` 2021-01-04, `rust_version: null`). Maintenance **at-risk**, and the concrete
  signals the rubric demands are: no release in **5 years 8 months**; repository
  `pushed_at` **2024-06-07** — 2 years 3 months with no commit; 14 open issues
  (`GET https://api.github.com/search/issues?q=repo:softprops/envy+is:issue+is:open`,
  `total_count`, 2026-09-18); `archived: false`, 981 stars. Not `dormant`: it compiles and
  runs correctly on stable 1.98.0, measured here. **This is the crate the prompt's own
  candidate list names first, and the one whose shape fits best**; it is excluded on a
  declaration it never made rather than on behaviour, and that is worth recording plainly for
  the synthesizer.
- **`figment` 0.10.19 — excluded by gate 2** (no `rust-version`;
  `GET https://crates.io/api/v1/crates/figment/versions`, newest non-yanked `0.10.19`,
  `created_at` 2024-05-17). Maintenance **at-risk**: no release in **2 years 4 months**,
  repository `pushed_at` **2024-09-13** (2 years 0 months), 21 open issues, 913 stars,
  `archived: false`. It builds and runs on stable 1.98.0, measured. **This is the row the
  owner-supplied reference architecture names for C9**, which is why the exclusion is argued
  above on three independent grounds rather than on the gate alone.
- **`envconfig` 0.11.1 — excluded by gate 2** (no `rust-version`; release 2025-12-10;
  repository `greyblake/envconfig-rs`, 232 stars, `pushed_at` 2025-12-10, 6 open issues;
  maintenance **stable-quiet**). Its per-field attribute is `#[envconfig(from = "DB_HOST")]` with a
  **string-literal** value and no prefix support at all
  (`https://docs.rs/envconfig/0.11.1/envconfig/`, 2026-09-18), a stricter form of the same
  limitation `confique` has.
- **`serde-env` 0.3.0 — excluded by gate 2** (no `rust-version`; release 2026-04-15;
  `Xuanwo/serde-env`, 25 stars, `pushed_at` 2026-04-15, 1 open issue; **stable-quiet**).
- **`envious` 0.3.0 — excluded by gate 2** (no `rust-version`; release 2026-05-29;
  `TheNeikos/envious`, 60 stars, `pushed_at` 2026-05-30, 2 open issues; **stable-quiet**).
- **`dotenvy` 0.15.7 — not excluded by a gate; excluded by category.** It loads a `.env` file
  into the process environment and does not produce a typed value. It is compatible with the
  recommendation and with every alternative, and P03 may adopt it separately for developer
  convenience; it answers none of this item's questions.

### Up-and-comers

Ordered by how close each comes to the shape this item needs.

- **`confique` 0.4.0** — the strongest of the new generation and the only one that passes
  gate 2. 158,359 90-day / 490,326 all-time downloads; 223 stars; released 2025-10-27;
  declares `rust-version` 1.68.2; adopted by `mise` 2026.9.11 (confirmed as a required normal
  dependency through the crates.io dependencies endpoint). It produces the best library error
  message measured anywhere in this run, generates a documented reference config file, and
  layers env over file over default. Its two costs are structural: env names must be string
  literals (**measured:** `#[config(env = ENV_PORT)]` with `const ENV_PORT: &str` is rejected
  at compile time with `error: expected string literal`), and `builder().env()` takes no
  argument, so there is no injected-variable-set seam.
- **`serde-env` 0.3.0** — 944,262 90-day downloads on 25 stars, which is an unusual ratio
  worth flagging rather than reading as popularity; it is pulled transitively by a small
  number of high-volume crates. Released 2026-04-15, actively pushed, but declares no
  `rust-version`.
- **`envious` 0.3.0** — 66,319 90-day downloads, 60 stars, released 2026-05-29. Its
  distinguishing feature is *nested* structures from flat environment variables, which this
  item's flat field set does not need. No declared `rust-version`.

None of the three is recommended, and one honest reading of the up-and-comer bin is that it
exists because the established bin does not fit: every entry is someone re-solving
"typed struct from environment" because `config` and `figment` are larger than the problem.

### Fit for this template

**CLI (`crates/cli`, binary `rslbp`).** Nothing from this item ships in it. The CLI's
environment tier is R54's: `RSLBP_*` through `clap` 4.6.6's per-flag `env` attribute plus one
emptiness filter, over the six-rung `R5.1` chain with three file tiers. The two namespaces
are disjoint by construction — every variable this item names carries the `_WEB_` segment, so
`RSLBP_CONFIG` (R54) and `RSLBP_TOKEN` (R56) can never collide with a web knob, and no web
knob can ever be set by a CLI flag. `R5.4`'s curated-subset **MUST NOT** ("the tool **MUST
NOT** auto-expose every flag as an env var") is satisfied in the strongest possible way on
the web side: there are **no flags at all** for service knobs, so nothing can be
auto-exposed, and the curated set is literally the list of fields in one struct in one file.

**Library (`crates/core`).** Nothing from this item ships in it either, and that is a
positive requirement rather than an absence: the core library must contain **no**
`std::env` call. It receives values. Keeping `WebSettings` in `crates/web` is what makes
that checkable with a one-line grep, and it is consistent with R67's rule that the library
crate "must install no signal handler or panic hook, and must write to no process stream or
file".

**Web (`crates/web` plus the root package's serve binary).** This is the whole of the item.
`crates/web/src/settings.rs` holds `WEB_ENV_PREFIX`, `WebSettings`, `SettingsError`,
`from_vars` and `from_env`. `src/bin/rslbp-serve.rs` (root package) calls `from_env()` once,
before anything that can log or bind, maps a failure to R67's `RSLB203`/exit `2`, then builds
`AppState { config: Arc::new(settings), projects: … }` and hands it to `build_router`.
Handlers reach it as `State(cfg): State<Arc<WebSettings>>` through
`impl FromRef<AppState> for Arc<WebSettings>`. Because the whole member is optional under
R69's `web = ["dep:rs-launch-blueprint-web"]`, no `#[cfg(feature = "web")]` appears inside
the file, and with the feature off neither the settings type nor the environment read exists
in the binary at all.

**How this answers the framework-agnostic requirement.** The prompt forbids assuming R69's
framework, and the design does not depend on it. The settings value is a plain `Clone` struct
behind `Arc`. In `axum` it enters via `State`/`FromRef` (measured). In `actix-web` the same
`Arc<WebSettings>` enters via `App::app_data(web::Data::from(settings))` and is extracted as
`web::Data<WebSettings>`. In `poem` it is `AddData`. In every case the parsing lives outside
the framework and the framework only carries a value, which is exactly why the composition
root — not the framework — is where `from_env()` is called. That is the same shape py has:
`create_app(settings: WebSettings | None = None)` takes the value and only constructs one
itself as a fallback.

### Recommendation

**Adopt no new crate. The web service's settings are decoded by the template's own
`crates/web/src/settings.rs` over `std::env::vars_os` and `str::FromStr`, with the
environment prefix `RSLBP_WEB_` derived at compile time from R57's single `TOOL_NAME`
constant by a `const fn` ASCII-uppercase that contains no `unsafe`, and the resulting
`WebSettings` value is constructed exactly once in `src/bin/rslbp-serve.rs` and reaches
handlers as `Arc<WebSettings>` through the framework's own state mechanism — `axum`'s
`State`/`FromRef` under R69's accepted stack.**

The crate rows that make that a complete answer to a `crate`-kind item:

| Slot | Selection | Version range | Where declared |
|---|---|---|---|
| Environment reading and decoding | **`std`** — `std::env::vars_os`, `str::FromStr` | the toolchain; governed by `msrv-policy`, floor **1.96** against stable 1.98.1 | none — no manifest entry |
| The data model the settings sit beside (HTTP bodies, not the environment) | **`serde`**, `features = ["derive"]` | **`>= 1.0.229, < 2.0.0`** | already non-optional per R69's owned value; **this item adds nothing** |
| Environment→struct mapping crate | **none** | — | — |

**Why this, and not the crate the prompt names first.** Five grounds, in the order of their
force, each resting on something measured or on an owner-accepted decision rather than on
preference:

1. **The gate eliminates the whole matching bin.** Every crate whose *shape* matches this
   requirement — `envy`, `envconfig`, `serde-env`, `envious` — and the reference
   architecture's `figment` all fail fitness gate 2, because not one declares `rust-version`.
   The two survivors are layering engines. Recommending a layering engine for an env-only
   surface is a strictly worse answer than writing the forty lines.
2. **Edition 2024 turned the loader's signature into a design decision.** `set_var` is
   `unsafe`, measured. A loader that takes `impl IntoIterator<Item = (OsString, OsString)>`
   is testable by ordinary safe code, in parallel, with no global lock; a loader that reads
   only the real process environment is not. `confique` and `figment` offer no seam;
   `config` does, but only alongside everything else it brings.
3. **The error message is the deliverable, not a detail.** R67 requires `hint` to name the
   offending input. The template's own parse produces `RSLBP_WEB_PORT: invalid value
   "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)` — the full
   variable name as the operator typed it, the value, and a *domain* expectation rather than
   a Rust type name. `config`'s best effort is ``key `port` in the environment``. No
   translation layer is needed to reach `RSLB203` and exit `2`.
4. **The derived prefix survives.** F324's whole point is that a fork's rename carries.
   `envy`, `config` and `figment` take the prefix as a runtime string, so a derived `const`
   works with them; `confique` and `envconfig` require a literal per field and would make a
   fork edit twelve attributes. Template code takes the `const` directly. **Measured:**
   changing `TOOL_NAME` to `"acme"` yields `"ACME_WEB_"` with no other edit.
5. **It is the house shape, and consistency here has a concrete payoff.** R53 chose `serde`
   and no validation crate; R54 chose a six-rung chain with "no layering crate and no new
   dependency"; R55 sanitizes per layer in template code; R56 uses `std::os::unix::fs`
   directly. A reviewer reading `crates/web/src/settings.rs` after reading the CLI's config
   module meets the same idiom, and the template — whose product *is* the readable
   example — teaches one pattern rather than two.

**Cost of the recommendation, stated so it is not discovered later.** Roughly one `FromStr`
arm per field, twelve of them, each three lines; a `Default` impl; and a test per field. That
is the price of the error message, the test seam and the zero dependency. It is also code the
template exists to show, not code the template hides.

### Ranked runner-up

**`config >= 0.15.25, < 0.16.0` with `default-features = false`, used only for its
`Environment` source**, with the prefix supplied from the same derived
`WEB_ENV_PREFIX` const and the struct deserialized by `serde`:

```rust
let settings: WebSettings = config::Config::builder()
    .add_source(config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_'))
        .source(Some(injected)))      // None in production; Some(map) in tests
    .build()?
    .try_deserialize()?;
```

**The condition under which it wins.** It wins if either of two things turns out to be true
in P03:

- **the field set grows past hand-maintenance** — if R72–R79 add enough web knobs that
  twelve fields become thirty, the per-field arm stops being a readable list and becomes a
  chore, and `config`'s derive-driven mapping is the better trade; or
- **the web surface acquires a file tier** — if the owner later rules that `--config` on
  `rslbp-serve` should reach web knobs as well as the core `Config`, this item's env-only
  premise is gone and a layering engine is the right shape. `config` already provides the
  tier, is the engine R54 evaluated in detail (so the comparison is on the record), and is
  the only gate-passing candidate with an injected-source test seam.

It is ranked above `confique` despite `confique`'s better error message and smaller
footprint for one reason that outranks both: `confique` has no injected-variable-set seam,
so under edition 2024 the template could not unit-test its own settings loading without
`unsafe`. `confique` is the ranked *third*, and it wins over `config` only if the owner
values the generated reference config file and the sharper error more than testability —
a trade this report does not recommend but records as coherent.

### Tradeoffs

**Versus `config` 0.15.25 (runner-up) — what the recommendation gives up:**

- *A derive instead of twelve hand-written arms.* Real. Accepted because the arms are where
  the good error message and the domain-level expectation ("a TCP port in 0..=65535", not
  "an integer") come from, and because twelve is a number a reader can hold.
- *A file tier ready for free if the surface ever wants one.* Accepted because the surface
  is env-only by R69's owned value, and because adopting an engine for a tier that does not
  exist is the exact mistake R54 declined for the CLI.
- *3,210 stars and 18.6 M quarterly downloads of maintenance behind the parsing.* Accepted
  because `std::env::vars_os` and `u16::from_str` are maintained by the Rust project, and
  what `config` maintains beyond them is the layering this item does not use.
- *Cost avoided, measured:* +3 packages and +66 KB stripped with default features off, or
  +47 packages and roughly a 3× clean build with them on.

**Versus `confique` 0.4.0 — what the recommendation gives up:**

- *A marginally more precise error* (`WebSettings::port` field path alongside the variable
  name). Accepted; the template's message already carries the variable, the value and a
  better expectation, and the field path is recoverable from the variable name.
- *A generated reference configuration file.* Real and genuinely nice for documentation.
  Accepted because it documents a *file* this surface does not have; the equivalent artifact
  here is a table in the web README listing every `RSLBP_WEB_*` variable and its default,
  which a test can check against the struct.
- *Nothing on dependency cost:* `confique` measured +4 packages and **no** binary-size
  increase, so this is not a cost-based rejection. It is rejected on the derived prefix
  (literal-only attribute, measured) and on testability (no injected source).

**Versus `envy` 0.4.2 — what is given up, recorded even though the gate already excluded it:**

- *The shortest possible code.* `envy::prefixed(WEB_ENV_PREFIX).from_iter(vars)` is one
  line, keeps the derived prefix, and has the injected-iterator seam. It is the closest
  shape to `pydantic-settings` in the whole Rust field, and if the owner ever strikes gate 2
  the way gate 1 was struck, it deserves re-evaluation as the primary — with the maintenance
  signals above (no release since 2021-01-04, no commit since 2024-06-07) weighed openly,
  and with the knowledge that its error message names `PORT`, not `RSLBP_WEB_PORT`.

**Versus `figment` 0.10.19 — what is given up:**

- *Agreement with the owner-supplied reference architecture's C9 row.* The most significant
  cost in this report, and the one a reviewer should check hardest. Accepted on three
  independent measured grounds — the gate-2 failure, the absent injected source under
  edition 2024's `unsafe set_var`, and the file tier this surface does not have — any one of
  which would stand alone, and none of which is a preference.

### Parameters

**R77 owns no registry parameter.** The binding prompt's `## Couplings` block carries an
empty `- owns:` line, `research/CLAUDE.md`'s R77 row carries `—` in its `owns` column, and
`docs/port/PARAMETERS.md` lists no parameter owned by R77. What this item fixes — the
`RSLBP_WEB_` naming rule, the field set, the list encoding, the empty-is-unset rule and the
drain-deadline default — is recorded in this answer and in R77's `DECISION.md`, and is
consumed by R69's already-owned `web-extra-surface` clause "every service knob such as host,
port, log format and drain deadline stays an environment variable named by R77" rather than
by a registry row of its own.

Its `## Couplings` block also carries an empty `- consumes:` line, so no parameter is a
registry dependency of this item. The `assumes` lines below are declared because the
recommendation genuinely rests on those values, and each is reproduced **byte-identically**
from the row in the live `docs/port/PARAMETERS.md`.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.
- assumes build-tool-output-shape = no build backend or bundler crate; Cargo's own manifest is the entire declaration surface. Artifacts land in Cargo's default workspace-root target/ directory - target/debug/ for the dev and test profiles, target/release/ for release and bench, target/<name>/ for a user-defined profile, gaining a target/<triple>/<profile>/ level whenever --target is passed - relocatable by CARGO_TARGET_DIR, build.target-dir or --target-dir. Library target: exactly one, declared explicitly as [lib] with path src/lib.rs and Cargo's default crate name rs_launch_blueprint (the package name with dashes replaced by underscores); doctest is not set here and is R82's. Binary target: exactly one, declared explicitly as [[bin]] with path src/main.rs and name rslbp, a different string from the package name rs-launch-blueprint, so cargo install rs-launch-blueprint installs the command rslbp and integration tests resolve it through CARGO_BIN_EXE_rslbp; autobins = false so no src/bin/*.rs file becomes a second published command without a manifest edit; default-run unset while there is one binary; no build.rs and no build-orchestration crate. Packaged-file scope: an explicit [package] include allow-list - /src, /README.md, /LICENSE-MIT, /LICENSE-APACHE, /CHANGELOG.md - never exclude, the two being mutually exclusive; Cargo.toml and any license-file are included whatever include or exclude says, and a minimized Cargo.lock is likewise outside include/exclude selection - cargo package adds it, generating one when none is on disk - but not unconditionally: cargo package --exclude-lockfile omits it, an override cargo publish has no flag for and this template never passes. The optional web surface adds no target here: it is a Cargo feature per F017, and whether it also gets a second [[bin]] carrying required-features is R69's

**`web-extra-surface` — the registry bytes above are revision 9's; the design uses revision
10's paths, and that is deliberate.** The `assumes` line reproduces the live registry row,
which still reads "the library module `src/web/` containing AppState, build_router …" and
"path-based skip-gating keys on `src/web/**`". R69 **revision 10 is owner-accepted and
unpublished**
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`, the owned value at
line 1791; owner rulings W1-R02 / W0-R69c) and moves the gated tree to the optional
workspace member `crates/web`: `web = ["dep:rs-launch-blueprint-web"]` on the root package,
the library module at `crates/web/src/`, the web tests at `crates/web/tests/` with no
file-level `#![cfg(feature = "web")]`, and skip-gating on `crates/web/**`. **Every path in
this report is revision 10's** — `crates/web/src/settings.rs`, `crates/web/Cargo.toml`,
`src/bin/rslbp-serve.rs` in the root package — because that is the tree P03 will build. The
substance of the two revisions is identical for this item: the feature list is byte-identical
between them and only the manifest the crates are declared in moves. **R69's republication
is a re-verify trigger for this answer**, recorded below.

**No `CONFLICT:` line is raised by this item.** Nothing in the recommendation requires a
consumed value to change. Two places a reader might expect one, and why neither is:

- *R69's exit-code enumeration does not list a settings failure.* `web-extra-surface` names
  "143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O
  failure, and 0 otherwise". A malformed `RSLBP_WEB_*` variable is none of those; under
  R67's published catalog it is `RSLB203` ("config value invalid") at exit **2**. That is an
  answer R67 already supplies, not a change R69's value needs — R69's list enumerates
  run-phase exits and already leaves one branch open pending R67's disposition. Recorded, not
  conflicted.
- *R69's value says the web tree is `src/web/`.* Addressed above as an accepted-but-unpublished
  revision, per the run's instruction, not as a conflict.

**How the assumed parameters bear on the recommendation.** `rust-edition = 2024` is the
single most load-bearing value in this report: it is what makes `std::env::set_var` `unsafe`
and therefore what makes `from_vars` the required signature and eliminates `confique` and
`figment` on testability. `msrv-policy` fixes the gate-2 floor at **1.96** against stable
1.98.1 and, read strictly, is what excludes five of the eight candidate crates.
`target-os-matrix` keeps the design free of any platform `cfg` — `std::env::vars_os` and
`str::FromStr` are identical on both runners — and is also why Cloud Run's 10-second window
is used as a constraint on a default rather than as a platform commitment. `license` is
`inapplicable` here under the 2026-09-12 (Q7.B) ruling. `web-extra-surface` supplies the
feature gate, the serve binary, the `crates/web` tree the settings module lives in, and the
sentence that makes this item the namer of every service knob. `error-taxonomy-exit-codes`
supplies `RSLB203`/exit `2`, the single stderr JSON envelope `{"error":{"code","message",
"hint"?}}` the failure renders into, the requirement that `hint` "must be able to name the
offending input per R7.6" — which is what makes the variable name, the value and the
expectation load-bearing rather than cosmetic — and the `thiserror`-in-the-library rule that
`SettingsError` follows. `logging-pipeline-contract` is `—` (unset): R58 has published
nothing, so `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT` are **named** here and
**valued** there.

### Migration implications

`rs-launch-blueprint` has no Rust source, so these are the files P03 creates or changes, in
R69 revision 10's tree.

| Path | Change |
|---|---|
| `crates/web/src/settings.rs` | **new.** `WEB_ENV_PREFIX` (the `const fn` derivation from `TOOL_NAME`), `WebSettings`, its `Default`, `SettingsError` (`thiserror` in the library crate, per R67), `from_vars`, `from_env`. `#![forbid(unsafe_code)]` at module scope. The only `std::env` call in the whole member. |
| `crates/web/src/lib.rs` | `pub mod settings;` and `pub use settings::{WebSettings, WEB_ENV_PREFIX};`. `AppState` gains `pub config: Arc<WebSettings>` and `impl FromRef<AppState> for Arc<WebSettings>` — R69 revision 10 already reserves that slot as `Arc<WebConfig>`; this item supplies the type and the name. |
| `crates/web/Cargo.toml` | **no new dependency.** `serde` with `derive` if the HTTP types need it (they do, and R69 already has it non-optional). The `[dependencies]` block gains nothing from this item. |
| `crates/core/src/**` | **unchanged, and guarded**: no `std::env` call may appear here. |
| `src/bin/rslbp-serve.rs` (root package) | gains three lines before anything that can log: `let settings = WebSettings::from_env().map_err(…)?;` mapped to `RSLB203`/exit `2`; `let state = AppState { config: Arc::new(settings.clone()), projects: … };`; and the bind address / drain deadline read from `settings` rather than from constants. |
| `crates/web/tests/settings.rs` | **new.** The AC1–AC4 tests, all over injected variable lists, none touching process environment. |
| `crates/web/tests/web_api.rs` | gains the `oneshot` case that asserts a handler sees the injected settings through `State`. |
| `README.md` / `docs/` (web section) | **new table** listing every `RSLBP_WEB_*` variable, its type, its default and its owning item, plus the one-line statement of the naming rule required by `R5.4`'s documentation expectation. A test can assert the table's variable list equals the struct's field list. |
| `Justfile` | R69's `serve` / `serve-once` recipes already export `<APP>_WEB_HOST`, `<APP>_WEB_PORT` and `<APP>_WEB_LOG_FORMAT`; substitute `RSLBP` for `<APP>`. No other change. |
| `Dockerfile` (R51) | sets `RSLBP_WEB_HOST=0.0.0.0` explicitly, because the default is loopback — the same note py carries at `settings.py`. |
| `docs/port/COMMONALITY.md` | **untouched by this report.** F324's row is the owner's to update when R77 publishes. |

### Validation strategy

**Executed in this run** — a throwaway Cargo workspace under a `$TMPDIR` subdirectory
created and deleted by this run, against the real crates at the exact versions named:

| # | Command | Expected | Result |
|---|---|---|---|
| E1 | `cargo run` on a crate whose `main` derives `WEB_ENV_PREFIX` by `const fn` from `TOOL_NAME = "rslbp"` and asserts it | prints `WEB_ENV_PREFIX=RSLBP_WEB_`; a second constant from `"acme"` yields `ACME_WEB_` | **pass** — `PROBE-A OK (const-derived prefix, no unsafe, stable)` |
| E2 | `cargo build` on an edition-2024 crate calling `std::env::set_var` | compile error | **pass** — ``error[E0133]: call to unsafe function `set_var` is unsafe and requires unsafe block`` |
| E3 | one malformed variable (`RSLBP_WEB_PORT=eighty`) through `envy` 0.4.2, `config` 0.15.25, `figment` 0.10.19, `confique` 0.4.0 and the hand-written parse | five distinct `Display` strings | **pass** — quoted verbatim in the table above; `figment` produced **defaults instead of an error** when handed an injected map, which is the finding about its missing seam |
| E4 | `cargo test` on a crate with `axum` 0.8.9 + `tokio` 1.53.1 (R69's feature list) + `tower` 0.5.3 dev-dep, holding `Arc<WebSettings>` in `AppState` behind `FromRef`, driven by `ServiceExt::oneshot` | 4 tests pass, none touching process environment | **pass** — AC1–AC4 |
| E5 | `cargo tree --locked -e normal --prefix none \| sed 's/ (\*)//' \| sort -u \| grep -c .` for a baseline crate and one per candidate | a package delta per candidate | **pass** — 8 / 9 / 11 / 12 / 16 / 55, reported above |
| E6 | `cargo build --release` (`strip`, `opt-level = "z"`, `lto`, `codegen-units = 1`, `panic = "abort"`) of a binary that actually *uses* each mechanism, then `stat -f%z` | a binary-size delta per candidate | **pass** — 302,704 / 302,624 / 302,528 / 369,232 / 385,968 bytes |
| E7 | `#[config(env = ENV_PORT)]` with `const ENV_PORT: &str` on `confique` 0.4.0 | rejected or accepted | **pass (rejected)** — `error: expected string literal` |

**Proposed for P03, not run here** (no Rust exists in this repository to run them against):

```bash
# AC6 — a malformed knob is R67's RSLB203 at exit 2, envelope on stderr, stdout byte-empty
RSLBP_WEB_PORT=eighty cargo run --features web --bin rslbp-serve >out.txt 2>err.txt; echo "exit=$?"
#   expect: exit=2 ; out.txt is 0 bytes ; err.txt is one JSON object whose
#   .error.code == "RSLB203" and whose .error.hint names RSLBP_WEB_PORT and "eighty"

# AC7 — the environment is read in exactly one place in the whole member
grep -rn 'std::env::' crates/web/src/ | tee /dev/stderr | grep -cv 'settings.rs'
#   expect: 0

# AC7b — the core library never reads the environment
grep -rn 'std::env::' crates/core/src/ ; echo "expect no matches, exit 1 from grep"

# AC8 — the drain deadline is honoured and R67's 143 is observed
RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS=2 cargo run --features web --bin rslbp-serve &
#   send SIGTERM during an in-flight request; expect the request to complete and exit 143
#   within ~2 s of the signal (the drain mechanism itself is R69's; only the variable and
#   its default are this item's)

# AC9 — the documented variable table and the struct cannot drift
cargo test --features web --test settings -- documented_variables_match_struct_fields

# AC10 — the feature is genuinely additive: with `web` off, nothing of this exists
cargo build && ! nm -a target/debug/rslbp 2>/dev/null | grep -qi 'WebSettings'
```

**What is proven and what is only proposed.** E1–E7 are executed results of this run against
real published crates. AC6–AC10 are proposals: they name commands P03 can run once the
template exists, and this report does not claim any of them has been run. The whole
recommendation remains, per the programme's 2026-09-10 ruling, a proposal validated in the
implementation phase.

### Confidence & re-verify trigger

**High** on the three findings that decide the answer, because each was executed rather than
read: edition 2024's `unsafe set_var` (E2); `figment`'s and `confique`'s missing
injected-source seam (E3, source lines `figment/src/providers/env.rs:505` and
`confique/src/builder.rs:38` + `src/internal.rs:54`); and the compile-time prefix derivation
with no `unsafe` (E1, E4).

**High** on the gate-2 exclusions as a matter of *fact* — the `rust_version` field is `null`
for `envy` 0.4.2, `figment` 0.10.19, `envconfig` 0.11.1, `serde-env` 0.3.0 and `envious`
0.3.0 at the versions endpoint — and **medium** on their *force*, because the strict reading
that converts an absent declaration into an exclusion is an owner ruling recorded in prose
(`docs/planning/p02/owner-decisions.md`, "Two things you should know") rather than a
registry value, and it is doing a great deal of work here: it removes the reference
architecture's own C9 selection and the prompt's first-named candidate. **If the synthesizer
or the owner reads that ruling differently, `envy` 0.4.2 becomes the strongest single-crate
answer** — derived prefix, injected iterator, one added package — subject to its at-risk
maintenance, and `figment` becomes a live option again. The design recommended here does not
change under either reading; only the runner-up ordering does.

**Medium** on the `8`-second drain default. It is a judgement about margin, resting on a
platform datum for a platform this template does not target, and an owner could reasonably
set it to 5, 8 or 9, or keep py's 10 with a documented warning. The *rule* — strictly less
than the platform's SIGKILL point, measured from the signal — is high-confidence; the
number is not.

**Medium** on the comma-separated list encoding. It is the Rust idiom and it is safe for
this field set, but R76 owns CORS semantics and could need an encoding that survives commas.

**Not verified in this run, and stated as gaps:** `serde`'s own `unsafe` posture (carried
from R53 revision 2, not re-audited); the `unsafe` posture, default features and platform
support of `envconfig`, `serde-env` and `envious`, which were excluded on gate 2 before those
limbs were reached and whose sources were not extracted; whether `confique`'s declared
`rust-version = 1.68.2` is accurate against its current code, which was not compiled on an
old toolchain; and any Windows behaviour, which `target-os-matrix` does not require.

**Re-verify when any of these happens:**

- **R69 republishes** and `web-extra-surface`'s registry bytes move from `src/web/` to
  `crates/web` — the `assumes` line above must be re-copied and this report's paths
  re-checked against the published value;
- **R58 publishes** `logging-pipeline-contract` and fixes the value sets for
  `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`;
- **R67 revises** `RSLB203` or the envelope, changing what `SettingsError` must render into;
- **R54/R56 publish** and the CLI's `RSLBP_*` curated set is fixed, so the disjointness claim
  can be checked against a published list rather than an accepted-but-unpublished one;
- **the owner revisits the gate-2 strict reading**, which would readmit `envy` and `figment`;
- **`envy` or `figment` declares a `rust-version`** in a new release — `envy` would then be a
  serious primary candidate again;
- **the msrv-policy floor advances past 1.96** and `config`'s 1.85.0 or `confique`'s 1.68.2
  stops clearing it (neither is near);
- **a later item adds a web knob whose value may contain a comma**, which would reopen the
  list encoding;
- or by **2027-03-18**, whichever comes first.

### Sources

**Pinned source repositories**, read through the pin as the role requires, never from the
working tree.

- py-launch-blueprint at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:
  `git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/settings.py`
  (the docstring quoted above; `ENV_PREFIX` at line 38; the whole field set and every
  default, including `graceful_shutdown_seconds: int = 10`);
  `…:src/py_launch_blueprint/core/paths.py` (`APP_NAME = "plbp"`, line 58);
  `…:src/py_launch_blueprint/web/deps.py` (the lazy-load fallback, lines 37–47);
  `…:src/py_launch_blueprint/web/app.py` (`create_app(settings: WebSettings | None = None)`,
  `configure_web_logging(settings)` before anything that can log, and `_lifespan` calling
  `load_config()` — the two-settings-object shape).
- ts-launch-blueprint at pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`:
  `git -C ~/c/ts-launch-blueprint ls-tree -r --name-only cb1cbcb2…` — **no web or server
  source file exists**, which is what ledger row F303 records and why ts supplies no
  precedent for this item. Every ts claim in this report comes from this pin; every py claim
  from `b08bccfb`.

**Programme documents** (repository-relative, read in this run): `docs/port/README.md`
(verdict vocabulary); `docs/port/COMMONALITY.md` rows F303 (`:307`), F324 (`:328`), F330
(`:334`), F338, F241/F242 (`:245`, `:246`); `docs/port/PARAMETERS.md` (the seven `assumes`
rows, copied programmatically and verified to appear verbatim);
`docs/planning/p02/owner-decisions.md` section 11 (the reference architecture as a standing
input) and "Two things you should know, which are not decisions" (the withdrawn MSRV-gate
ruling); `docs/port/OWNER-REVIEW.md` (the 2026-09-12 Q7.B licence ruling, as applied by R53
revision 2 and R69 revision 10); `research/CLAUDE.md` (R77's row: kind `crate`, origin
`py-only`, verdict `DIVERGENT`, `owns` = `—`);
`research/runs/R77/2026-09-17T034011Z-5884fd6b6366/inputs/prompt.md` and
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` (rows C9, C13, C15 and the
sample `Cargo.toml`/`main.rs`/layout blocks).

**Accepted-but-unpublished decisions designed against**:
`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md` (revision 10 — the
owned value at line 1791, the `AppState` sketch reserving `Arc<WebConfig>`, the R4.1 option
table naming R77 for `--config`'s other half, the `BASELINE-REVIEW: F330` line, the Cloud Run
SIGTERM datum handed to this item, and the dev recipes exporting `<APP>_WEB_*`);
`research/runs/R56/2026-09-17T033528Z-785d25a9d608/review/DECISION.md` (revision 2 — the
config file is never a token source; `--token-file` > `RSLBP_TOKEN` > stored credential);
`research/runs/R54/2026-09-17T033527Z-8dfef31d60fc/review/DECISION.md` (revision 3 — the
six-rung chain, `RSLBP_*` through `clap`'s `env`, and the recorded rejection of `config`
0.15.25 / `figment` 0.10.19 as layering engines for the CLI);
`research/runs/R53/2026-09-17T020714Z-d0b567b4b9f1/review/DECISION.md` (revision 2 — `serde`
only, the gate-table format followed here, and the 1.96 floor);
`research/runs/R55/2026-09-17T020714Z-62a04ad8fee1/review/DECISION.md` and
`research/runs/R57/2026-09-17T020714Z-8fdb5c2010e7/review/DECISION.md`
(revision 2 — `pub const TOOL_NAME: &str = "rslbp";`, the single namespace segment this
item's prefix derives from).

**Org standard**: `git -C ~/c/cli-standards cat-file -p
f9de0437baece3383e73ca2c5f48b7ab399b51c7` — the rule headings at `R5.1` line **287**, `R5.2` line
**302**, `R5.3` line **307**, **`R5.4` line 321**, `R5.5` line **326**, `R5.6` line **331**,
and the required-global-core table row for `--config` at line **246**.

**Endpoints queried** (all 2026-09-18 UTC):

- `GET https://crates.io/api/v1/crates/<name>` for `envy`, `config`, `figment`, `confique`,
  `envconfig`, `serde-env`, `envious`, `dotenvy`, `cargo-nextest`, `mise`, `leptos`,
  `rocket`, `arti` — fields `crate.recent_downloads`, `crate.downloads`,
  `crate.max_stable_version`, `crate.repository`.
- `GET https://crates.io/api/v1/crates/<name>/versions` for the same crates plus `serde`,
  `winnow`, `pathdiff` — newest non-yanked `num`, `created_at`, `rust_version`, `license`.
- `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=12` for `config`,
  `figment`, `envy`, `confique`.
- `GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies` for
  `nextest-runner` 0.124.0, `leptos_config` 0.8.10, `rocket` 0.5.1, `tor-config` 0.46.0,
  `mise` 2026.9.11, `apple-codesign` 0.29.0, `esp-idf-sys` 0.38.1 — each adoption claim above
  is that endpoint's output, not a README.
- `GET https://api.github.com/repos/<o>/<r>` for `softprops/envy`, `rust-cli/config-rs`,
  `SergioBenitez/Figment`, `LukasKalbertodt/confique`, `greyblake/envconfig-rs`,
  `Xuanwo/serde-env`, `TheNeikos/envious` — `stargazers_count`, `archived`, `pushed_at`.
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` for the same
  seven — `total_count`, never `open_issues_count`.
- `GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc`
  and `…/issues/<n>/comments` for the four responsiveness samples below.
- `https://rustsec.org/packages/<name>.html` for `envy`, `config`, `figment`, `confique`,
  `serde`, `envconfig`, `serde-env`, `envious` — **HTTP 404 for every one**, with `atty` and
  `time` fetched in the same run as **HTTP 200 controls** carrying four `RUSTSEC-` mentions
  each, which is what makes the 404s readable as "no advisory" rather than as a broken
  method.
- `https://static.rust-lang.org/dist/channel-rust-stable.toml` — `[pkg.rust] version` =
  `1.98.1 (48a229cea 2026-09-01)`.
- `https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html`;
  `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html`;
  `https://docs.rs/confique/0.4.0/confique/`; `https://12factor.net/config`.

**Issue responsiveness** — the 10 most recently opened *issues* (pull requests filtered out),
first response by a user whose `author_association` is `OWNER`, `MEMBER`, `COLLABORATOR` or
`CONTRIBUTOR`:

| Repository | issues sampled | answered by a maintainer | unanswered | median days to first maintainer response |
|---|---|---|---|---|
| `rust-cli/config-rs` | 10 | **9** | 1 | **0.22** — nine of ten answered, eight of them inside 14 hours: 0.01, 0.01, 0.02, 0.05, 0.22, 0.32, 0.48, 0.55, 2.25 |
| `LukasKalbertodt/confique` | 10 | 7 | **3** | **68.06** — strongly bimodal: 0.01, 0.05, 1.84 days, then 68.06, 132.95, 236.45, 328.59 |
| `softprops/envy` | 10 | **1** | **9** | 73.42 (a single data point) |
| `SergioBenitez/Figment` | 10 | **1** | **9** | 185.0 (a single data point) |

`config-rs`'s row is why it is recorded as **active** without qualification, and it is the
sharpest single contrast in this report: `epage` (author of `clap`, the parser R60 selected)
answers within hours. `envy`'s and `figment`'s rows are the concrete signal the maintenance
rubric asks for before an `at-risk` verdict: nine of ten recently opened issues with no maintainer reply at all,
alongside release gaps of 5 years 8 months and 2 years 4 months respectively. `confique`'s
row is why it is recorded as **stable-quiet** rather than `at-risk` — the maintainer does
answer, sometimes within minutes, and the long tail reflects a small project's cadence, not
absence. Note the sampling artefact recorded honestly: `config-rs`'s issue tracker is
dominated by pull requests, so the first request (`per_page=30`) yielded only two non-PR
items and was re-run at `per_page=100`.

**Method notes.** Every figure in this report carries its endpoint and the retrieval date
2026-09-18 (UTC). GitHub REST was called no more often than once per 21 seconds throughout,
from a serialized background script. Every Rust claim marked *measured* was executed in a
throwaway Cargo workspace under a subdirectory of `$TMPDIR` created by this run and deleted
at its end; no Rust file was written into the repository and no nested git repository was
created. The candidate sources quoted by line (`figment-0.10.19/src/providers/env.rs`,
`figment-0.10.19/src/jail.rs`, `envy-0.4.2/src/lib.rs`, `confique-0.4.0/src/builder.rs`,
`confique-0.4.0/src/internal.rs`) were read from the local Cargo registry cache at the exact
published versions, not from a repository default branch. The seven `assumes` values were
copied out of `docs/port/PARAMETERS.md` by a script and then verified, by a second script,
to appear verbatim as a cell in that file.

**What could not be verified, or was not attempted.** (1) The `unsafe` posture, default
feature set and platform support of `envconfig` 0.11.1, `serde-env` 0.3.0 and `envious` 0.3.0
— their sources were not extracted, because gate 2 excluded them before those limbs were
reached; each is marked `not extracted` in the gate table rather than asserted. (2) `serde`'s
own `unsafe` posture, carried from R53 revision 2 rather than re-audited. (3) Whether
`confique`'s declared `rust-version = 1.68.2` actually builds on 1.68.2; only current stable
was exercised. (4) Windows behaviour of anything here, which `target-os-matrix` does not
require. (5) The binary-size figures are `aarch64-apple-darwin` only; `ubuntu-latest`'s
`x86_64-unknown-linux-gnu` was not measured, and the deltas should be read as ratios rather
than as absolute sizes. (6) The clean-build wall times were taken on a machine concurrently
running network polling; only the `config`-with-default-features figure exceeds that noise
and only it is reported as a signal. (7) No Codex evidence check was available for this run:
the Codex leg is deferred under owner ruling W1-CODEX3 of 2026-09-18, so nothing in this
report has been reproduced by a second engine.
