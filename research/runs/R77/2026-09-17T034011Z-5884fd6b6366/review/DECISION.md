# 2026-09-18 — R77 — web-env-settings (crate, Focused) — decision (revision 1)

## Decision

**Adopt no new crate for this item.** The web service's runtime settings are decoded
by the template's own module `crates/web/src/settings.rs`, over `std::env::vars_os`
and `str::FromStr`, under the environment-variable prefix `RSLBP_WEB_` derived at
compile time from R57 revision 2's single `TOOL_NAME` constant by a `const fn`
ASCII-uppercase containing no `unsafe`; the resulting `WebSettings` value is
constructed exactly once, in the serve binary, before anything that can log or bind,
and reaches request handlers as `Arc<WebSettings>` through the web framework's own
state mechanism — `axum::extract::State` with `FromRef` under R69's accepted stack,
`actix_web::web::Data` or `poem`'s `AddData` under any other.

This is a `crate`-kind item, so the crate rows that make the answer complete:

| Slot | Selection | Version range | Where declared |
|---|---|---|---|
| Reading and decoding the environment | **`std`** — `std::env::vars_os`, `str::FromStr` | the toolchain itself, governed by `msrv-policy`; floor **1.96** against stable **1.98.1** | nowhere — no manifest entry |
| The data model the settings sit beside (HTTP bodies, not the environment) | **`serde`**, `features = ["derive"]` | **`>= 1.0.229, < 2.0.0`** | already non-optional under R69's owned `web-extra-surface`; **this item adds nothing** |
| Environment → struct mapping crate | **none** | — | — |

**Ledger row settled:** `F324` (`docs/port/COMMONALITY.md:328`, *typed env settings with
an app-derived env-var prefix*, origin `py-only`, verdict `DIVERGENT`). No other row is
touched. **No `BASELINE-REVIEW:` finding is raised** — `BASELINE-REVIEW:` adjudicates
inherited `COMMON → REUSE` and `ADOPT` rows, and F324 inherits nothing. **No `CONFLICT:`
line is raised**; nothing here needs a consumed parameter to change.

**This decision is a proposal validated in the implementation phase** (owner ruling,
2026-09-10). It records what the research found and what it recommends; P03 builds the
template and its CI proves the recommendation. What P03 must validate is listed under
`## Engines`. A decision that does not survive implementation is revised against this
recorded research, not researched again from scratch.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

> **Principle (F324).** The web service's runtime knobs are a *single typed value*,
> resolved *once at process start*, from the *environment only*, under a prefix
> *derived from the one app-name constant* — so a fork's rename carries without editing
> call sites, a misconfigured deployment fails loudly at boot instead of silently at
> request time, and no request handler ever reads the environment.

Source: py at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5`,
`src/py_launch_blueprint/web/settings.py`. Its own module docstring states the intent —
"Every knob resolves from an env var with the ``<APP_NAME>_WEB_`` prefix (derived from
the single ``APP_NAME`` source in ``core/paths.py``, so a fork's rename keeps working).
Validation happens at construction, so a misconfigured deployment fails loudly at boot
instead of silently at request time." — and line 38 is
`ENV_PREFIX: str = f"{APP_NAME.upper()}_WEB_"`, with `APP_NAME = "plbp"` at
`core/paths.py:58` in the same pin. Both lines and the docstring are asserted in
`review/evidence/sources.log`.

**Agreement level: architectural pattern and policy — not library, and not the wire
encoding of individual values.**

| Must agree (pattern / policy) | May vary (ecosystem-native) |
|---|---|
| Web knobs come from the environment, never from the CLI's config file | which crate or standard-library facility decodes them |
| One typed value, constructed once at the composition root | whether decoding is derive-driven or hand-written |
| The prefix derives from the single app-name constant | how the derivation is spelled (f-string, `const fn`, code generation) |
| Construction fails loudly, at boot, naming the offending variable | the concrete error type and the message wording |
| The value reaches handlers through the framework's own state/DI mechanism, never a global | `Depends`/`app.state` in FastAPI, `State`/`FromRef` in axum |
| No secret is a field of this object | — |
| An exported-but-empty variable means unset (the default stands) | — |
| List-valued knobs have **one documented encoding** | **which** encoding (py's JSON, Rust's comma-separated) |

**ts is not a harmonization target for this row, and the reason is structural rather
than a preference.** `git ls-tree -r --name-only cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
in `ts-launch-blueprint` lists no `web/` or `server/` source path — re-run in
`review/evidence/sources.log`, which asserts a match count of **0**. That absence is
what ledger row F303 (`docs/port/COMMONALITY.md:307`, *web service exists at all*,
origin `py-only`) records, and `TS_PORT_DECISIONS.md` has no entry on the subject.
There is no ts `WebSettings` to agree or disagree with. The rationale this item supplies
for the follow-on ts project is therefore forward-looking: if ts later grows a web
service it should realize the same *pattern* with its own idiom — a `zod` schema over a
small reader that takes an injected `Record<string, string>` rather than reaching
`process.env` inside the schema, with the prefix built from ts's own app-name constant —
and should not import py's library choice, because `pydantic-settings` has no ts
equivalent whose tradeoffs match. The divergence analysis marked this row
`harmonize: no`; this decision reaches the same label on reasoned ground rather than by
inheriting it: the pattern is shared and should be stated in all three repositories'
documentation, while the mechanism is ecosystem-bound in each.

**Whether the inherited pattern still holds in Rust — checked, not assumed. Two halves,
and only one of them ports.**

*The env-only, prefix-derived, boot-validated settings object ports, and is
strengthened.* The 12-factor argument that motivates it ("An app's config is everything
that is likely to vary between deploys"; "The twelve-factor app stores config in
environment variables" — `https://12factor.net/config`, retrieved 2026-09-18) is
language-neutral, and the org CLI Design Standard v1.4.14 independently **requires** the
prefix: `R5.4` at line 321 of blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7` reads
"Environment variables **MUST** use the uppercase `TOOL_*` prefix with a deterministic
mapping … Only a **curated subset** of settings **SHOULD** read from the environment …
and the tool **MUST NOT** auto-expose every flag as an env var." Rust adds a property py
cannot have: the settings type can be made unconstructible except through the loader, so
"validated at construction" is enforced by the type system rather than by convention.

*py's lazy-load fallback does not port, and has already been adjudicated elsewhere.*
py's `web/deps.py` re-loads configuration when the lifespan has not run — "Falls back to
loading lazily when the lifespan hasn't run (raw ASGI callers like schemathesis)". R69
revision 10 raised and carries `BASELINE-REVIEW: F330` against exactly that, on the
ground that axum 0.8.9 makes the unconfigured state unrepresentable because
`with_state` is what turns a `Router<S>` into a service. **This item does not re-raise
that finding; the design satisfies it**: `WebSettings` has no lazily-loadable global, no
`OnceLock` and no default-on-read path, and the only way a handler sees one is through
`AppState`, which `build_router` requires.

#### Architectural alternatives, compared before any library was chosen

| # | Shape | Verdict |
|---|---|---|
| **A1** | **One layering engine owns web settings too** — `figment` or `config` takes defaults → file → env and produces `WebSettings`. This is the owner-reference C9 shape. | **Rejected.** It adds a *file* tier the surface does not have, and it collides with R54 revision 3 (owner-accepted), which rejected exactly this engine for the CLI because "It takes ownership of three things already decided elsewhere: the parse (R52's `toml` 1.1.6), the typed pass (R53's per-key loop over `toml::Table`, `D06`), and the per-layer sanitize step and warning list (R55, `D01`, `D03`)". Adopting it for the web surface alone would put a rejected engine in the dependency tree for a surface that needs none of its layering. |
| **A2** | **Web settings reuse the CLI's `Config`** — one type, one loader, `RSLBP_*` for everything. | **Rejected.** It breaks `R5.4`'s curated-subset rule (host, port, drain deadline and log format would become either CLI flags, which R69's `R4.1` table forbids on the serve binary, or unbacked variables in the CLI's namespace); it puts a token field beside web knobs, contradicting R56 revision 2; and it makes `--config` on the serve binary silently able to set a listen address, which `R5.2`'s file semantics were never meant to carry. |
| **A3** | **Two settings objects in disjoint namespaces** — `WebSettings` env-only under `RSLBP_WEB_`, and the core `Config` from R53/R54/R55 through the same composition root the CLI uses; the serve binary builds both. | **Selected.** It is py's actual shape (`create_app` takes `WebSettings`; `_lifespan` calls `load_config()`), and it keeps each surface's rules intact. `--config` on the serve binary binds the **core** `Config`'s file, exactly as `R5.2` describes, and touches no web knob. |
| **A4** | Inside A3: **(a)** a serde `Deserializer` over the environment via a derive, versus **(b)** an explicit per-field parse naming each variable and parsing it with `FromStr`. | **(b) selected**, and this is the sub-choice a reasonable owner could weigh the other way. (b) yields an exact error per field, is trivially injectable, and makes the curated set literally readable in one function. (a) is shorter to write and harder to drift. The measured error strings below are the ground for choosing (b). |

#### How the recommended design preserves each principle

```rust
// crates/web/src/settings.rs — illustrative. P03 writes the real thing.
#![forbid(unsafe_code)]
use std::{collections::HashMap, ffi::OsString, net::IpAddr, time::Duration};

use crate::TOOL_NAME;                       // R57 revision 2's one segment: "rslbp"

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
    // cors_origins, rate_limit, idempotency_*, metrics_enabled, otel_enabled, root_path:
    // named here, semantics owned by R69 and R72-R80
}

impl WebSettings {
    /// The whole surface. `from_env` is the only caller that touches the process.
    pub fn from_vars<I>(vars: I) -> Result<Self, SettingsError>
    where I: IntoIterator<Item = (OsString, OsString)> { /* ... */ }

    pub fn from_env() -> Result<Self, SettingsError> { Self::from_vars(std::env::vars_os()) }
}
```

- *Derived prefix.* `WEB_ENV_PREFIX` is a `const` computed from `TOOL_NAME` by a
  `const fn` containing no `unsafe`. **Re-verified in this run** (`probes.log`, P1): it
  compiles and evaluates on stable 1.98.0 under edition 2024 and under
  `#![forbid(unsafe_code)]`; a fork changing the app-name constant to `"acme"` and
  nothing else yields `"ACME_WEB_"`. The const path exists because
  `core::str::from_utf8` is const-stable, and the `match`/`panic!` form replaces
  `unwrap`, which is not const.
- *One value, once, at the composition root.* `from_env()` is called exactly once, in
  the serve binary, before the router exists. R69 revision 10's `AppState` holds it as
  `Arc<WebSettings>` and `impl FromRef<AppState> for Arc<WebSettings>` lets a handler
  write `State(cfg): State<Arc<WebSettings>>`. **Re-verified against real axum 0.8.9**
  (`probes.log`, P4).
- *Fails loudly, naming the input.* See the measured error table below. The failure maps
  to R67's published `RSLB203` ("config value invalid" → exit `2`) with no translation
  layer, because `SettingsError` carries `var`, `value`, `expected` and `cause` — exactly
  the material R67's envelope says `hint` "must be able to name the offending input per
  R7.6".
- *No handler reads the environment.* `std::env` appears once in the whole `crates/web`
  member, inside `from_env`. A CI grep or a `clippy` deny can enforce it (AC7, proposed).
- *No secret field.* R56 revision 2 (owner-accepted) fixes the credential chain as
  `--token-file` > `RSLBP_TOKEN` > stored credential and rules the config file out as a
  token source. `WebSettings` declares no credential of any kind, so 12-factor's litmus
  test ("whether the codebase could be made open source at any moment, without
  compromising any credentials") holds for the whole web surface and `R5.6`'s redaction
  obligation has nothing to redact in this object. The token stays with the core
  resolver, which the serve binary builds through the same composition root the CLI uses.
- *An exported-but-empty variable is unset.* `Some(raw) if raw.is_empty() => Ok(default)`.
  F242 fixes this rule for the token; applying it to every `RSLBP_WEB_*` variable is a
  consistency choice **this item makes**, not an inherited requirement. **Re-verified**
  (`probes.log`, P4 `unprefixed_and_empty_are_ignored`).

#### Measured: the error shape for a malformed variable

One input — `RSLBP_WEB_PORT=eighty`, everything else valid — through every candidate.
Each `Display` string below was re-executed in this run and is asserted verbatim in
`review/evidence/probes.sh` (P3.1–P3.5); `probes.log` carries the output.

| Mechanism | `Display` for `RSLBP_WEB_PORT=eighty` | names the variable? | the value? | the expectation? |
|---|---|---|---|---|
| **template code** | `RSLBP_WEB_PORT: invalid value "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)` | **yes, in full** | yes | **domain-level** |
| `confique` 0.4.0 | ``failed to deserialize value `WebSettingsC::port` from environment variable `RSLBP_WEB_PORT`: invalid value 'eighty' for type u16: invalid digit found in string`` | **yes, in full** | yes | the Rust type `u16` |
| `figment` 0.10.19 | ``invalid type: found string "eighty", expected u16 for key "PORT" in `RSLBP_WEB_` environment variable(s)`` | yes (prefix + key, separately) | yes | the Rust type `u16` |
| `config` 0.15.25 | ``invalid type: string "eighty", expected an integer for key `port` in the environment`` | **no** — a lowercased key `port` | yes | "an integer" |
| `envy` 0.4.2 | `invalid digit found in string while parsing value 'eighty' provided by PORT` | partial — `PORT`, no prefix | yes | **none** |

The `confique` row names the struct as the probe declared it (`WebSettingsC`); the
struct name is the probe's, the rest of the string is the crate's. `config`'s message is
the weakest of the five for this purpose: an operator reading the key name `port` must
know the crate's lowercasing rule to recover `RSLBP_WEB_PORT`.

#### Measured: testability under edition 2024, and the injection seam

`std::env::set_var("RSLBP_WEB_PORT", "8000")` in an edition-2024 crate fails to compile
with ``error[E0133]: call to unsafe function `set_var` is unsafe and requires unsafe
block``. **Re-verified with a control** (`probes.log`, P2): the identical source compiles
and runs under edition 2021, so it is the edition — not a change of API — that converts
the call into an `unsafe` one. The Rust project's own edition documentation gives the
reason: "It can be unsound to call `std::env::set_var` or `std::env::remove_var` in a
multithreaded program due to safety limitations of the way the process environment is
handled on some platforms"
(`https://doc.rust-lang.org/edition-guide/rust-2024/newly-unsafe-functions.html`,
retrieved 2026-09-18).

That is not a style point. It makes the loader's *signature* a design decision: a loader
that can read only the real process environment cannot be unit-tested by template code
that honours R06's unsafe policy, and process-wide environment mutation is in any case
order-dependent under `cargo test`'s thread-parallel harness.

**Re-verified, and sharper than the raw report stated it** (`probes.log`, P3 run 2): with
the process environment *clean* and the malformed value present only in an injected map,
template code, `envy` and `config` all report the error, while `figment` and `confique`
silently return their defaults — they never saw the injected map at all.

| Mechanism | Injected variable set? | Evidence |
|---|---|---|
| **template code** | **yes** — `from_vars(impl IntoIterator<Item = (OsString, OsString)>)` | P4: four tests pass, none touching the process environment |
| `envy` 0.4.2 | yes — `from_iter` free and prefixed | `envy-0.4.2/src/lib.rs:301` and `:324`; measured working (P3.8) |
| `config` 0.15.25 | yes — `Environment::…​.source(Some(HashMap))` | measured working (P3.9) |
| `confique` 0.4.0 | **no** — `pub fn env(mut self) -> Self` takes no argument, and the generated code calls `std::env::var($key)` | `confique-0.4.0/src/builder.rs:38`, `src/internal.rs:54`; measured ignoring the map (P3.11) |
| `figment` 0.10.19 | **no** — only `Env::raw()` / `Env::prefixed()`, both reading `std::env::vars_os()` | `figment-0.10.19/src/providers/env.rs:171`, `:198`, `:505`; measured ignoring the map (P3.10). Its test story is `figment::Jail`, behind the non-default `test` feature, which calls `std::env::set_var` itself at `src/jail.rs:353` and serialises tests behind a lock |

Every line number in that table was re-read from the local Cargo registry cache at the
exact published version and is asserted in `review/evidence/sources.sh`.

#### Measured: dependency and binary cost

Package counts are `cargo tree --locked -e normal --prefix none | sed 's/ (\*)//' |
sort -u | grep -c .` — the way R56 counts them — over a crate that already has `serde`
with `derive`. Stripped sizes are `cargo build --release` under
`strip = true, opt-level = "z", lto = true, codegen-units = 1, panic = "abort"`,
target `aarch64-apple-darwin`, on 2026-09-18 with `rustc 1.98.0 (88d9e12ae 2026-08-18)`.

| Mechanism | packages (Δ over the 8-package baseline) | stripped size Δ over baseline | what the delta is made of |
|---|---|---|---|
| **template code** | **8 (+0)** | **0 B** (it *is* the baseline) | nothing |
| `envy` 0.4.2 | 9 (+1) | +16,576 B | `envy` alone |
| `confique` 0.4.0 | 12 (+4) | +16,480 B | `confique`, `confique-macro`, `heck`, `syn` |
| `config` 0.15.25, `default-features = false` | 11 (+3) | +83,200 B | `config`, `pathdiff`, `winnow` |
| `figment` 0.10.19, `features = ["env"]` | 16 (+8) | +99,920 B | `figment`, `pear`, `pear_codegen`, `proc-macro2-diagnostics`, `syn`, `uncased`, `inlinable_string`, `yansi` |
| `config` 0.15.25, **default features** | **55 (+47)** | +132,912 B | adds `json5`, `ron`, `rust-ini`, `yaml-rust2`, `toml`, `serde_json`, `encoding_rs`, `pest` + `pest_derive`, `async-trait`, … |

**The package counts are the reproducible figures and are asserted individually**
(`probes.sh`, P6). The *size* figures are deltas over a baseline whose source is in
`probes.sh` itself, printed there in one line and asserted as five thresholds:
`config` without default features and `figment` each cost **more than 50 KB** of stripped
binary over hand-written code; `envy` and `confique` each cost **less than 50 KB**;
`config` with default features costs **more than 100 KB**. Absolute byte counts are
specific to this machine, this toolchain, this date and the exact body of the baseline
program; they are reported so the deltas can be read, not as portable constants, and no
absolute figure is asserted anywhere.

Clean release build wall time on the same machine, one sample each: baseline 6.15 s;
`envy` 7.07 s; `confique` 7.30 s; `config` without default features 7.07 s; `figment`
14.11 s; `config` with default features 19.05 s. Only the last figure is treated as a
signal, and only as a ratio — roughly **3×** the baseline. It matters because `config`'s
default feature set pulls four document parsers (`json5`, `ron`, `ini`, `yaml`) into a
binary whose only configuration format is fixed by `R5.2` to TOML and whose web surface
has no file at all. The `figment` figure is a single sample on a machine also running
network polling and is not treated as a finding either way (see `## Engines`).

#### Fitness gates, answered per candidate before popularity was weighed

**Gate 1 (licence) is recorded for every candidate as:
`inapplicable — owner ruling 2026-09-12 (Q7.B)`: licence compatibility is not evaluated
for any dependency or tool** (`docs/port/OWNER-REVIEW.md`, "2026-09-12 — no licence check
for anything the template uses (Q4, superseded and widened by Q7.B)"). Licence strings
below are metadata only and nothing is excluded on them.

**Gate 2 is applied under the strict reading settled 2026-09-11.**
`docs/planning/p02/owner-decisions.md`, "Two things you should know, which are not
decisions", records the owner's provisional lenient ruling, the auditors' argument, and
the outcome: "The ruling is withdrawn. One item's exclusions stand; the other must
switch to the runner-up it already recorded." R69 revision 10 applies it by that name.
The *third*, stricter reading — under which every transitive dependency at every depth
must also declare a version — is the one the same file says "is not on the table unless
you put it there"; it is **not** applied here, which is why `config`'s transitive
dependency **`pathdiff` 0.2.3** (`rust_version: null`,
`GET https://crates.io/api/v1/crates/pathdiff/versions`, retrieved 2026-09-18) does not
exclude `config`. `config`'s other added package, `winnow` 1.0.4, declares `1.65.0`.

**MSRV floor, re-derived in this run rather than carried:** current stable is
**1.98.1 (48a229cea 2026-09-01)**
(`https://static.rust-lang.org/dist/channel-rust-stable.toml`, `[pkg.rust] version`,
retrieved 2026-09-18), so `msrv-policy`'s "stable minus 2 minor versions" puts the floor
at **1.96**.

| Gate | `std` | `serde` 1.0.229 | `config` 0.15.25 | `confique` 0.4.0 | `envy` 0.4.2 | `figment` 0.10.19 | `envconfig` 0.11.1 | `serde-env` 0.3.0 | `envious` 0.3.0 |
|---|---|---|---|---|---|---|---|---|---|
| **1 · licence** | `inapplicable — owner ruling 2026-09-12 (Q7.B)`; metadata `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `MIT OR Apache-2.0` | same ruling; `MIT` | same ruling; `Apache-2.0` | same ruling; `MIT OR Apache-2.0` |
| **2 · MSRV ≤ 1.96** | `inapplicable` — `std` *is* the toolchain; the floor is `msrv-policy`'s own | declares **1.56** — passes | declares **1.85.0** — passes | declares **1.68.2** — passes | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** | **declares none — fails** |
| **3a · RustSec** | `inapplicable` (not a crates.io package) | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page | no advisory page |
| **3b · `unsafe` posture** | the standard library contains `unsafe`; the recommended module contains none and compiles under `#![forbid(unsafe_code)]` — measured (P1) | **2** `unsafe` blocks in `src/`, both `str::from_utf8_unchecked` — re-audited here, not carried | **0** in `src/`; no crate-level lint | **0** in `confique` and `confique-macro` `src/`; no crate-level lint | **0** in `src/` | **0** in `src/` — but `Jail` mutates the process environment (`src/jail.rs:353`), the hazard edition 2024 marks `unsafe` | **0** in `envconfig` and `envconfig_derive` `src/` | **0** in `src/` | **0** in `src/` |
| **4 · ubuntu-latest + macos-latest** | yes by construction; `std::env::vars_os` and `str::FromStr` carry no platform `cfg` | yes | built here on `aarch64-apple-darwin`; no platform `cfg` on the `Environment` path | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | built here on `aarch64-apple-darwin` | fetched, not built here | fetched, not built here | fetched, not built here |
| **5 · default features / async coupling** | none | `derive` only; no runtime | defaults are `toml, json, yaml, ini, ron, json5, convert-case, async` — the `async` default pulls `async-trait`, a proc macro, **not** a runtime; `default-features = false` drops all of it | nothing of consequence; no async coupling | none; no async coupling | `env` pulls `pear` + `parse-value`; `test` pulls `tempfile` + `parking_lot`; no async coupling | edition 2021; derive only | edition 2021 | edition 2021 |
| **6 · binary size / compile time** | **+0 packages, the baseline** | already in the tree; no marginal cost | **+3 packages, +83,200 B** with default features off; **+47 packages and ≈3× clean build** with them on | **+4 packages, +16,480 B** | **+1 package, +16,576 B** | **+8 packages, +99,920 B** | not measured — excluded at gate 2 | not measured — excluded at gate 2 | not measured — excluded at gate 2 |

The RustSec row is a 404 on `https://rustsec.org/packages/<name>.html` for all eight
crates, retrieved 2026-09-18, with `atty` and `time` fetched in the same run as HTTP 200
controls carrying four `RUSTSEC-` mentions each — which is what makes the 404s readable
as "no advisory" rather than as a broken method. Both halves are asserted in
`review/evidence/figures.sh`.

**Excluded by gate, with the ground.**

- **`envy` 0.4.2 — excluded by gate 2.** No declared `rust-version`
  (`GET https://crates.io/api/v1/crates/envy/versions`, newest non-yanked `0.4.2`,
  `created_at` 2021-01-04, `rust_version: null`, retrieved 2026-09-18). Maintenance
  **at-risk**, on the concrete signals the rubric demands: no release in 5 years
  8 months; repository `pushed_at` **2024-06-07**; 14 open issues
  (`GET https://api.github.com/search/issues?q=repo:softprops/envy+is:issue+is:open`,
  `total_count`); `archived: false`; 981 stars. Not `dormant` — it compiles and runs
  correctly on stable 1.98.0, measured here. **This is the crate the prompt's own
  candidate list names first and the one whose shape fits best**; it is excluded on a
  declaration it never made rather than on behaviour, and that is recorded plainly
  because it is the exclusion most likely to be revisited.
- **`figment` 0.10.19 — excluded by gate 2.** No declared `rust-version` (same endpoint,
  newest non-yanked `0.10.19`, `created_at` 2024-05-17). Maintenance **at-risk**: no
  release in 2 years 4 months, `pushed_at` **2024-09-13**, 21 open issues, 913 stars,
  `archived: false`. It builds and runs on stable 1.98.0, measured. **This is the row the
  owner-supplied reference architecture names for C9**, which is why the exclusion is
  argued below on three independent grounds rather than on the gate alone.
- **`envconfig` 0.11.1 — excluded by gate 2** (no `rust-version`; released 2025-12-10;
  `greyblake/envconfig-rs`, 232 stars, `pushed_at` 2025-12-10, 6 open issues; maintenance
  **stable-quiet**). Its per-field attribute takes a **string-literal** value and offers
  no prefix support at all, a stricter form of `confique`'s limitation.
- **`serde-env` 0.3.0 — excluded by gate 2** (no `rust-version`; released 2026-04-15;
  `Xuanwo/serde-env`, 25 stars, `pushed_at` 2026-04-15, 1 open issue; **stable-quiet**).
- **`envious` 0.3.0 — excluded by gate 2** (no `rust-version`; released 2026-05-29;
  `TheNeikos/envious`, 60 stars, `pushed_at` 2026-05-30, 2 open issues; **stable-quiet**).
- **`dotenvy` 0.15.7 — not excluded by a gate; excluded by category.** It loads a `.env`
  file *into* the process environment and produces no typed value. It composes with the
  recommendation and with every alternative, and P03 may adopt it separately for
  developer convenience; it answers none of this item's questions. Its 46,188,632 90-day
  downloads are named here only so a reader does not mistake them for evidence about this
  category.

#### The landscape this decision sits in, and why it has no dominant choice

The category is not "a config crate". It is precisely: *the mechanism that turns the
process environment into one typed, validated Rust value for the optional `web` surface,
under a prefix derived from the single app-name constant, plus the path by which that
value reaches request handlers.* Three properties make it its own category: it is
**env-only** (R69's owned value puts every service knob in an environment variable and
gives the serve binary no flags for them); it must be **constructible from an injected
variable set** (edition 2024's `unsafe set_var`); and its failure message must **name the
offending variable, its value and the expectation** (R67's `hint`).

- **Bin 1 — built-in or first-party toolchain.** `std::env::vars_os` / `var_os` plus
  `str::FromStr`, with the template writing the mapping. `serde` 1.0.229 sits beside it
  as an already non-optional dependency, but it is a *data-model* crate, not an
  environment reader.
- **Bin 2 — established industry standard.** `config` 0.15.25 (maintained in the
  `rust-cli` GitHub organisation, which also hosts `clap`, the parser R60 selected);
  `figment` 0.10.19 (the engine Rocket is built on, by Rocket's author); `envy` 0.4.2
  (the original serde-over-environment idiom); `envconfig` 0.11.1.
- **Bin 3 — up-and-comers.** `confique` 0.4.0 (derive macro, per-field
  `#[config(env = "…")]`, layered, generates a reference config file); `serde-env` 0.3.0;
  `envious` 0.3.0 (nested structures from flat variables).

| Crate | 90-day downloads | all-time | what it actually dominates |
|---|---|---|---|
| `config` 0.15.25 | 18,581,807 | 114,271,945 | layered multi-format configuration |
| `figment` 0.10.19 | 10,072,166 | 38,648,096 | layered configuration, chiefly through Rocket |
| `envy` 0.4.2 | 3,574,490 | 20,877,399 | the thin serde-over-environment idiom — the closest fit, and the least maintained |
| `envconfig` 0.11.1 | 1,472,437 | 10,008,963 | per-field derive over the environment |
| `serde-env` 0.3.0 | 944,262 | 2,883,110 | environment → serde with nesting |
| `confique` 0.4.0 | 158,359 | 490,326 | per-field derive, layered, generates a reference config file |
| `envious` 0.3.0 | 66,319 | 570,440 | nested structures from the environment |

All figures: `GET https://crates.io/api/v1/crates/<name>`, fields
`crate.recent_downloads` and `crate.downloads`, retrieved 2026-09-18; each is asserted
against a committed snapshot in `review/evidence/figures.sh`.

**There is no dominant choice, and that is the finding.** Read as a field map rather than
a leaderboard, the category has a hole exactly where this item sits: the crates *shaped*
like the requirement (thin env-only mappers) are small and lightly maintained, and the
crates *maintained* like infrastructure are layering engines whose extra tier this
surface must not have. Rust has no `pydantic-settings`. That is why the recommendation is
a design rather than a purchase.

**Practice evidence.** Adoption was confirmed in the raw report through
`GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies` rather than
asserted: `config` `^0.15.25` is a required normal dependency of `nextest-runner`
0.124.0 (the library behind `cargo-nextest`) and `leptos_config` 0.8.10, and is used by
`deadpool` and `rumqttd`; `figment` `^0.10.18` is a required dependency of `tor-config`
0.46.0 (the Tor Project's Arti — genuinely independent of figment's author, unlike
`rocket` 0.5.1, which shares its maintainer) and of `apple-codesign`, `pijul` and
`taplo-lsp`; `envy` `^0.4.2` is a **build** dependency of `esp-idf-sys` 0.38.1 and a
normal dependency of `axum-client-ip` 1.3.1; `confique` `^0.4` is a required dependency
of `mise` 2026.9.11. **What the practice evidence does not show:** no surveyed project
uses any of these crates to do what this item needs. `config`'s and `figment`'s adopters
use them for layered file-plus-environment configuration, which is R54's problem;
`envy`'s most prominent adopter uses it in a build script.

**Issue responsiveness** (10 most recently opened issues per repository, first response
by a maintainer-class author) is carried from the raw report and was **not** re-sampled
here — see `## Engines`. It recorded `rust-cli/config-rs` 9 of 10 answered, median 0.22
days; `LukasKalbertodt/confique` 7 of 10, median 68.06 days, strongly bimodal;
`softprops/envy` 1 of 10, 73.42 days; `SergioBenitez/Figment` 1 of 10, 185.0 days. Those
figures are the ground for `envy` and `figment` being recorded `at-risk` rather than
merely quiet, and for `confique` being `stable-quiet` rather than `at-risk`.

#### Why the recommendation is no crate, and not the crate the prompt names first

Five grounds, in order of force, each resting on something measured in this run or on an
owner-accepted decision:

1. **The gate eliminates the whole matching bin.** Every crate whose *shape* matches this
   requirement — `envy`, `envconfig`, `serde-env`, `envious` — and the reference
   architecture's `figment` all fail fitness gate 2, because not one declares a
   `rust-version`. The two survivors are layering engines. Recommending a layering engine
   for an env-only surface is a strictly worse answer than writing the forty lines.
2. **Edition 2024 turned the loader's signature into a design decision.** A loader taking
   `impl IntoIterator<Item = (OsString, OsString)>` is testable by ordinary safe code, in
   parallel, with no global lock; a loader that reads only the real process environment is
   not. `confique` and `figment` offer no seam, measured; `config` does, but only
   alongside everything else it brings.
3. **The error message is the deliverable, not a detail.** R67 requires `hint` to name the
   offending input. The template's own parse produces the full variable name as the
   operator typed it, the value, and a *domain* expectation ("a TCP port in 0..=65535")
   rather than a Rust type name. `config`'s best effort is ``key `port` in the
   environment``. No translation layer is needed to reach `RSLB203` and exit `2`.
4. **The derived prefix survives.** F324's whole point is that a fork's rename carries.
   `envy`, `config` and `figment` take the prefix as a runtime string, so a derived
   `const` works with them; `confique` and `envconfig` require a literal per field, and a
   fork would have to edit twelve attributes. **Re-verified** (`probes.log`, P5):
   `#[config(env = ENV_PORT)]` with `const ENV_PORT: &str` is rejected at compile time
   with `error: expected string literal`.
5. **It is the house shape, and consistency here has a concrete payoff.** R53 revision 2
   chose `serde` and no validation crate; R54 revision 3 chose a six-rung chain with no
   layering crate and no new dependency; R55 revision 3 sanitizes per layer in template
   code; R56 revision 2 uses `std::os::unix::fs` directly. A reviewer reading
   `crates/web/src/settings.rs` after reading the CLI's config module meets the same
   idiom, and a template whose product *is* the readable example teaches one pattern
   rather than two.

**The cost, stated so it is not discovered later.** Roughly one `FromStr` arm per field,
twelve of them, each about three lines; a `Default` impl; and a test per field. That is
the price of the error message, the test seam and the zero dependency. It is also code
the template exists to show rather than code the template hides.

#### Ranked runner-up, and the condition under which it wins

**`config >= 0.15.25, < 0.16.0` with `default-features = false`, used only for its
`Environment` source**, with the prefix supplied from the same derived `WEB_ENV_PREFIX`
const and the struct deserialized by `serde`:

```rust
let settings: WebSettings = config::Config::builder()
    .add_source(config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_'))
        .source(Some(injected)))      // None in production; Some(map) in tests
    .build()?
    .try_deserialize()?;
```

It wins if either of two things turns out to be true in P03:

- **the field set grows past hand-maintenance** — if R72 to R80 add enough web knobs that
  twelve fields become thirty, the per-field arm stops being a readable list and becomes
  a chore, and derive-driven mapping is the better trade; or
- **the web surface acquires a file tier** — if the owner later rules that `--config` on
  the serve binary should reach web knobs as well as the core `Config`, this item's
  env-only premise is gone and a layering engine is the right shape. `config` already
  provides the tier, is the engine R54 evaluated in detail (so the comparison is on the
  record), and is the only gate-passing candidate with an injected-source test seam.

**`confique >= 0.4.0, < 0.5.0` is ranked third.** It produces the best library error
message measured anywhere in this run and the smallest gate-passing footprint
(+4 packages, +16,480 B), so it is not rejected on cost. It is ranked below `config` for
one reason that outranks both of its advantages: it has no injected-variable-set seam, so
under edition 2024 the template could not unit-test its own settings loading without
`unsafe`. It wins over `config` only if the owner values the generated reference config
file and the sharper error more than testability — a trade this decision does not
recommend but records as coherent.

#### Tradeoffs

**Versus `config` 0.15.25 — what the recommendation gives up:**

- *A derive instead of twelve hand-written arms.* Real. Accepted because the arms are
  where the good error message and the domain-level expectation come from, and because
  twelve is a number a reader can hold.
- *A file tier ready for free if the surface ever wants one.* Accepted because the surface
  is env-only under R69's owned value, and because adopting an engine for a tier that does
  not exist is the exact mistake R54 declined for the CLI.
- *3,210 stars and 18,581,807 quarterly downloads of maintenance behind the parsing.*
  Accepted because `std::env::vars_os` and `u16::from_str` are maintained by the Rust
  project, and what `config` maintains beyond them is the layering this item does not use.
- *Cost avoided, measured:* +3 packages and +83,200 B stripped with default features off,
  or +47 packages and roughly a 3× clean build with them on.

**Versus `confique` 0.4.0 — what the recommendation gives up:**

- *A marginally more precise error* (a struct field path beside the variable name).
  Accepted; the template's message already carries the variable, the value and a better
  expectation, and the field path is recoverable from the variable name.
- *A generated reference configuration file.* Real and genuinely useful for documentation.
  Accepted because it documents a *file* this surface does not have; the equivalent
  artifact here is a table in the web documentation listing every `RSLBP_WEB_*` variable
  and its default, which a test can check against the struct (AC9, proposed).
- *Nothing on dependency cost.* `confique` measured +4 packages and +16,480 B, close to
  `envy`'s +16,576 B, so this is not a cost-based rejection. It is rejected on the derived
  prefix (literal-only attribute, measured) and on testability (no injected source,
  measured).

**Versus `envy` 0.4.2 — recorded even though gate 2 already excluded it:**

- *The shortest possible code.* `envy::prefixed(WEB_ENV_PREFIX).from_iter(vars)` is one
  line, keeps the derived prefix, and has the injected-iterator seam. It is the closest
  shape to `pydantic-settings` in the whole Rust field. **If the owner ever strikes gate 2
  the way gate 1 was struck, it deserves re-evaluation as the primary** — with its
  maintenance signals weighed openly (no release since 2021-01-04, no commit since
  2024-06-07, 1 of 10 recent issues answered) and with the knowledge that its error
  message names `PORT`, not `RSLBP_WEB_PORT`.

**Versus `figment` 0.10.19 — what is given up:**

- *Agreement with the owner-supplied reference architecture's C9 row.* This is the most
  significant cost in this decision and the one a reviewer should check hardest. It is
  accepted on three independent grounds, each re-verified in this run, any one of which
  would stand alone: the gate-2 failure (`rust_version: null` at the versions endpoint);
  the absent injected source under edition 2024's `unsafe set_var`
  (`src/providers/env.rs:505`, and measured returning defaults from a clean environment);
  and the file tier this surface does not have.

#### Fit for this template

**CLI (`crates/cli`, binary `rslbp`).** Nothing from this item ships in it. The CLI's
environment tier is R54's: `RSLBP_*` through the parser R60 selected, over the six-rung
`R5.1` chain with three file tiers. The two namespaces are disjoint by construction —
every variable this item names carries the `_WEB_` segment, so `RSLBP_CONFIG` (R54) and
`RSLBP_TOKEN` (R56) can never collide with a web knob, and no web knob can be set by a
CLI flag. `R5.4`'s curated-subset **MUST NOT** ("the tool **MUST NOT** auto-expose every
flag as an env var") is satisfied in the strongest available way on the web side: the
serve binary has **no flags at all** for service knobs, so nothing can be auto-exposed,
and the curated set is literally the field list of one struct in one file.

**Library (`crates/core`).** Nothing from this item ships in it either, and that is a
positive requirement rather than an absence: the core library must contain no `std::env`
call — it receives values. Keeping `WebSettings` in `crates/web` is what makes that
checkable with a one-line grep (AC7b, proposed), and it is consistent with R67's rule
that the library crate "must install no signal handler or panic hook, and must write to
no process stream or file".

**Web (`crates/web`, plus the root package's serve binary).** This is the whole of the
item. `crates/web/src/settings.rs` holds `WEB_ENV_PREFIX`, `WebSettings`,
`SettingsError`, `from_vars` and `from_env`. `src/bin/rslbp-serve.rs` calls `from_env()`
once, before anything that can log or bind, maps a failure to `RSLB203` / exit `2`, then
builds `AppState { config: Arc::new(settings), projects: … }` and hands it to
`build_router`. Handlers reach it as `State(cfg): State<Arc<WebSettings>>` through
`impl FromRef<AppState> for Arc<WebSettings>`. Because the whole member is optional under
R69 revision 10's `web = ["dep:rs-launch-blueprint-web"]`, no `#[cfg(feature = "web")]`
appears inside the file, and with the feature off neither the settings type nor the
environment read exists in the binary at all.

**Framework-agnostic, as the prompt requires.** The settings value is a plain `Clone`
struct behind `Arc`. In `axum` it enters via `State`/`FromRef` — measured against real
axum 0.8.9 in this run. In `actix-web` the same `Arc<WebSettings>` enters via
`App::app_data(web::Data::from(settings))` and is extracted as `web::Data<WebSettings>`.
In `poem` it is `AddData`. In every case the parsing lives outside the framework and the
framework only carries a value, which is exactly why `from_env()` is called at the
composition root rather than by the framework. That is also py's shape:
`create_app(settings: WebSettings | None = None)` takes the value.

#### The variable set, and who owns each value

The **naming rule** and the **mechanism** are this item's for every knob:
`<WEB_ENV_PREFIX><FIELD_IN_SCREAMING_SNAKE_CASE>` — `RSLBP_WEB_HOST`, `RSLBP_WEB_PORT`,
`RSLBP_WEB_ROOT_PATH`, `RSLBP_WEB_LOG_LEVEL`, `RSLBP_WEB_LOG_FORMAT`,
`RSLBP_WEB_CORS_ORIGINS`, `RSLBP_WEB_METRICS_ENABLED`, `RSLBP_WEB_OTEL_ENABLED`,
`RSLBP_WEB_RATE_LIMIT`, `RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`,
`RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`, `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`. That is the
twelve-field set py declares at `web/settings.py` in pin `b08bccfb`, renamed by the rule;
the field count is asserted in `review/evidence/sources.sh`. The **values and semantics**
are not all this item's:

| Knob | Value decided here | Owner of the semantics |
|---|---|---|
| `HOST`, `PORT` | `127.0.0.1`, `8000` — py's defaults, ported unchanged; loopback by default so a container must opt into `0.0.0.0` | this item |
| `GRACEFUL_SHUTDOWN_SECONDS` | **8**, not py's 10 — argued below | this item (the mechanism is R69's) |
| `LOG_LEVEL`, `LOG_FORMAT` | **not decided** — named only | R58 (`logging-pipeline-contract`, registry value `—`, unpublished) |
| `CORS_ORIGINS` | **not decided** — named only; its *encoding* is fixed below | R76 |
| `RATE_LIMIT` | not decided | R74 |
| `IDEMPOTENCY_TTL_SECONDS`, `IDEMPOTENCY_MAX_ENTRIES` | not decided | R73 |
| `METRICS_ENABLED` | not decided | R79 |
| `OTEL_ENABLED` | not decided | R78 |
| `ROOT_PATH` | not decided | R69 / R75 |

**The drain-deadline default is the one *value* this item owns, and it departs from py's
on a platform datum R69 handed over.** R69 revision 10 records, verified at Google's own
page and asserted in its own evidence log, that Cloud Run "sends a SIGTERM signal to all
the containers in an instance, indicating the start of a 10 second period before the
actual shutdown occurs, at which point Cloud Run sends a SIGKILL signal", and states the
hand-off: "on that platform a drain deadline is honoured only if it is strictly shorter
than 10 seconds **measured from SIGTERM**, because the SIGKILL is unconditional at the
deadline and the process never reaches its own exit path — so R67's 143 would never be
observed." py's default is `graceful_shutdown_seconds: int = 10`; ported literally it is
the one value that can never be observed on the platform the programme's own reference
architecture names.

- **Recommended: `8`, read as a total shutdown budget measured from SIGTERM**, not as a
  pure drain deadline. It is strictly under the platform kill point, with margin for the
  drain's own completion, stream flush and R67's `ExitCode` return from `main`. It is
  safe on every platform, including the two in `target-os-matrix`, where nothing kills
  the process at all.
- **The alternative an owner could reasonably prefer: keep `10`** and document that on
  Cloud Run an operator must lower it. Rejected, because a default whose only documented
  effect is to be overridden is not a default.
- **Cloud Run is not adopted as a deployment target by this decision.** R69 says so
  explicitly and `target-os-matrix` is `ubuntu-latest, macos-latest`. The datum is used
  as a constraint on a default, not as a platform commitment.
- **Coupling, stated because R80 is being researched in parallel and its raw report
  changes how the number must be read.** R80's raw says of its pre-drain readiness pause:
  "R77 owns the window's value, and the mechanism is inert if that value is zero", and
  "Whatever window R77 chooses must hold *both* the readiness-propagation delay and the
  drain inside that budget". This decision therefore fixes **8 seconds as the budget**
  and records that, if R80 publishes a non-zero readiness pause, that pause is spent
  *from* the 8 seconds rather than added to them. R80 decides the split; this item
  decides the budget. R80's publication is a re-verify trigger.

**List encoding — a justified difference from py, stated rather than left implicit.** py
encodes list-valued knobs as JSON; its docstring says "List values parse from JSON,
e.g.:: `PLBP_WEB_CORS_ORIGINS='["https://app.example.com"]'`" (asserted in
`review/evidence/sources.log`). This item fixes the Rust encoding as **comma-separated,
with an empty or unset variable meaning the empty list**:
`RSLBP_WEB_CORS_ORIGINS=https://a.example,https://b.example`. Grounds: it is the Rust
ecosystem's own convention for the same problem — `envy` splits sequences on `,`
(`envy-0.4.2/src/lib.rs:153`, re-read in this run), `config` exposes `list_separator`,
`figment` exposes `Env::split(pattern)` — and it is what `PATH`-shaped shell habits
produce. It yields exactly what R76's raw asks of this item, "a possibly-empty ordered
collection of allowed origins". Cost, recorded honestly: JSON round-trips values
containing the separator and comma-splitting does not; no value in this field set
(origins, header names) may contain a comma, so the cost is nil *for this field set* and
would have to be revisited if a later item adds a free-text list. The principle — one
documented encoding, validated at boot — is preserved; only the encoding differs, and it
differs on ecosystem-idiom ground.

#### Observable acceptance criteria

AC1 to AC5 were executed in this run; AC6 to AC10 are proposed for P03 and nothing here
claims they have been run.

| # | Criterion | Status |
|---|---|---|
| AC1 | `WEB_ENV_PREFIX == "RSLBP_WEB_"`, and changing the app-name constant alone changes it | **executed** (`probes.log` P1, P4) |
| AC2 | `RSLBP_WEB_PORT=eighty` fails construction with a message naming the variable, the value and the expectation | **executed** (`probes.log` P3, P4) |
| AC3 | An unprefixed `PORT`, and a set-but-empty `RSLBP_WEB_PORT`, both leave the default in place | **executed** (`probes.log` P4) |
| AC4 | A handler receives the settings through `State<Arc<WebSettings>>` with no process environment touched | **executed** (`probes.log` P4) |
| AC5 | The template's own test suite cannot call `std::env::set_var` without `unsafe` | **executed** (`probes.log` P2 — the edition-2024 compile error is the enforcement, and the edition-2021 control shows the edition is the cause) |
| AC6 | The serve binary with a malformed `RSLBP_WEB_*` variable exits `2`, emits R67's one-line stderr envelope with `code: "RSLB203"`, and writes nothing to stdout | proposed |
| AC7 | `grep -rn 'std::env::' crates/web/src/` matches exactly one file, `settings.rs` | proposed |
| AC7b | `grep -rn 'std::env::' crates/core/src/` matches nothing | proposed |
| AC8 | `RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS` is honoured: a SIGTERM during an in-flight request drains, then the process exits `143` within the window | proposed (the drain mechanism is R69's; only the variable, its default and the budget reading are this item's) |
| AC9 | The documented `RSLBP_WEB_*` table and the struct's field list cannot drift | proposed |
| AC10 | With the `web` feature off, neither the settings type nor the environment read exists in the binary | proposed |

#### Reconciliation with the owner-supplied reference architecture

`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, treated as a standing input
under `docs/planning/p02/owner-decisions.md` section 11 — an owner-supplied research
input, not a binding standard and not a pre-decision. Its line 16 assigns "R77 — config
and secrets (C9)" to this item. Every row this item touches, with agreement or a ground
for differing; each quotation is asserted at its line in `review/evidence/sources.sh`.

| Reference row | What it says | This item |
|---|---|---|
| **C9 Config** (table row at line 66, prose at 108) | "**figment** 0.10.x" for layered config, "defaults → TOML file → env"; runner-up `config-rs`, rejected as "less ergonomic layering" | **Differ**, on three measured grounds: (i) `figment` 0.10.19 declares no `rust-version` and so fails gate 2 under the strict reading settled 2026-09-11; (ii) its `Env` provider has no injected-source constructor, so under edition 2024's `unsafe set_var` the template cannot unit-test the loader without `figment::Jail`, which mutates the process environment behind a lock; (iii) the *file* tier the row exists to provide is a tier this surface does not have, and R54 revision 3 already rejected a layering engine for the surface that does. |
| **C9 Secrets** (line 108) | "`--set-secrets` env-var injection from Secret Manager" is the default; a runtime SDK fetch only for rotation | **Agree, and already settled elsewhere.** Secrets arriving as environment variables is exactly R56's `RSLBP_TOKEN` tier. This item adds the sharper rule that keeps the two apart: `WebSettings` declares **no** secret field at all, so the token never enters the web settings object and nothing in it needs `R5.6` redaction. |
| **C13** — `AppState` (line 120) | "`AppState` holds `PgPool`, config, and shared clients; use `FromRef` to hand sub-state to extractors" | **Agree.** R69 revision 10's sketch is reused rather than redesigned: `pub config: Arc<WebConfig>` with `impl FromRef<AppState> for Arc<WebConfig>`. This item supplies the type in that slot and names it `WebSettings`, matching py's name and F324's wording. Measured working against axum 0.8.9. |
| **C13** — dependency injection (line 120) | "Dependency injection via **traits behind concrete types** … keeps handlers testable without a DI framework" | **Agree.** No DI container; the settings value is constructed by plain code at the composition root and handed in. |
| **Sample `Cargo.toml`** (line 174) | `figment = { version = "0.10", features = ["toml","env"] }` | **Differ.** `crates/web/Cargo.toml` gains **no** configuration crate under this recommendation. |
| **Sample `main.rs`** (line 325) | `let cfg = config::load()?;  // figment: defaults → file → env` | **Partly agree.** Agree on *load once at startup, before anything that can log or serve* — the same invariant F330 and py's `create_app` carry. Differ on the tiers: **defaults → env**, no file tier, for the web knobs; the file tier belongs to the core `Config` the same binary also builds through R54's stack. |
| **Sample layout** (line 237) | `src/config.rs  # figment layered config` | **Agree on the shape, differ on the engine.** One module owns settings: `crates/web/src/settings.rs`. |
| **C15 Cloud Run runbook** | SIGTERM, then SIGKILL after 10 s | **Agree, and it is load-bearing here** — it is the ground for the 8-second budget above. |

**Tally: 4 agree, 3 differ, 1 partly** (agree on the invariant, differ on the tiers).
Every "differ" rests on a measured fact re-verified in this run or on an owner-accepted
decision, not on preference.

#### Migration implications

`rs-launch-blueprint` has no Rust source yet, so these are the files P03 creates or
changes, in R69 revision 10's tree.

| Path | Change |
|---|---|
| `crates/web/src/settings.rs` | **new.** `WEB_ENV_PREFIX` (the `const fn` derivation from `TOOL_NAME`), `WebSettings`, its `Default`, `SettingsError` (`thiserror` in the library crate, per R67), `from_vars`, `from_env`. `#![forbid(unsafe_code)]` at module scope. The only `std::env` call in the whole member. |
| `crates/web/src/lib.rs` | `pub mod settings;` and `pub use settings::{WebSettings, WEB_ENV_PREFIX};`. `AppState` gains `pub config: Arc<WebSettings>` and `impl FromRef<AppState> for Arc<WebSettings>` — R69 revision 10 already reserves that slot as `Arc<WebConfig>`; this item supplies the type and the name. |
| `crates/web/Cargo.toml` | **no new dependency.** The `[dependencies]` block gains nothing from this item. |
| `crates/core/src/**` | **unchanged, and guarded**: no `std::env` call may appear here. |
| `src/bin/rslbp-serve.rs` (root package) | gains three lines before anything that can log: `let settings = WebSettings::from_env().map_err(…)?;` mapped to `RSLB203` / exit `2`; `let state = AppState { config: Arc::new(settings.clone()), projects: … };`; and the bind address and shutdown budget read from `settings` rather than from constants. |
| `crates/web/tests/settings.rs` | **new.** The AC1 to AC4 tests, all over injected variable lists, none touching the process environment. |
| `crates/web/tests/web_api.rs` | gains the `ServiceExt::oneshot` case asserting that a handler sees the injected settings through `State`. |
| `README.md` / `docs/` (web section) | **new table** listing every `RSLBP_WEB_*` variable, its type, its default and its owning item, plus the one-line statement of the naming rule `R5.4` expects to be documented. A test can assert the table's variable list equals the struct's field list (AC9). |
| `Justfile` | R69's `serve` / `serve-once` recipes already export `<APP>_WEB_HOST`, `<APP>_WEB_PORT` and `<APP>_WEB_LOG_FORMAT`; substitute `RSLBP` for `<APP>`. No other change. |
| `Dockerfile` (R51) | sets `RSLBP_WEB_HOST=0.0.0.0` explicitly, because the default is loopback — the same note py carries at `settings.py`. |
| `docs/port/COMMONALITY.md` | **untouched by this decision.** F324's row is the owner's to update when R77 publishes. |

re-verify: when R69 republishes and `web-extra-surface`'s registry bytes move from `src/web/` to `crates/web` (the `assumes` line below must then be re-copied and this decision's paths re-checked against the published value), when R58 publishes `logging-pipeline-contract` and fixes the value sets for `RSLBP_WEB_LOG_LEVEL` and `RSLBP_WEB_LOG_FORMAT`, when R80 publishes and fixes a readiness-propagation pause that must be spent from the 8-second budget, when R76 publishes an origins encoding that a comma cannot survive or any later item adds a web knob whose value may contain a comma, when R67 revises `RSLB203` or the error envelope, when R54 and R56 publish so the namespace-disjointness claim can be checked against a published curated set rather than an accepted-but-unpublished one, when the owner revisits the gate-2 strict reading (which would readmit `envy` and `figment`), when `envy` or `figment` declares a `rust-version` in a new release, at the next `msrv-policy` floor advance past 1.96 (which neither `config`'s 1.85.0 nor `confique`'s 1.68.2 is near), or by 2027-03-18, whichever comes first

## Parameters

R77 owns no registry parameter: the binding prompt's `## Couplings` block carries an
empty `- owns:` line, `research/CLAUDE.md`'s R77 row carries `—` in its `owns` column,
and `docs/port/PARAMETERS.md` lists no parameter owned by R77. Its `- consumes:` line is
empty too, so no parameter is a registry dependency of this item. The `assumes` lines
below are declared because the recommendation genuinely rests on those values; each was
extracted programmatically from the live `docs/port/PARAMETERS.md` row and is re-compared
byte-for-byte by `review/evidence/sources.sh`.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files
- assumes error-taxonomy-exit-codes = `error-contract/v1`: **Catalog** — `RSLB` + three digits, stable and append-only, sourced from an explicit `const fn ErrorCode::as_str(&self) -> &'static str` match on a `#[non_exhaustive]` enum in the library crate, never derived from a variant name, `Debug`, `Display`, `type_name`, a discriminant or a `strum` derive; a `pub const ErrorCode::ALL` lists every member and a pinned-row test enforces append-only. **Exit taxonomy** (`#[repr(u8)] enum Exit` → `std::process::ExitCode`, per the org CLI Design Standard R6.1, org-locked, unchanged from ts D-016(2)): `0` success, `1` generic runtime error, `2` usage/parse error, `3` not found, `4` auth required, `5` conflict, `130` SIGINT, `143` SIGTERM; unlisted failures collapse to `1`. **Initial catalog rows** (hundreds digit = exit code for the `1xx`–`5xx` blocks; `RSLB000` is the UNEXPECTED sentinel): `RSLB000` unexpected → 1; `RSLB101` I/O → 1; `RSLB102` transport (DNS/connect/timeout/TLS) → 1; `RSLB103` remote-API failure → 1; `RSLB104` config layer unreadable → 1; `RSLB201` usage/parse (including the CLI parser's own errors) → 2; `RSLB202` config document unparsable → 2; `RSLB203` config value invalid → 2 (**this template's choice, not derived from the standard — see `## Engines`, Disagreement 4**); `RSLB204` secret supplied through a prohibited channel → 2 (**likewise this template's choice; the standard assigns secrets no exit code**); `RSLB205` required non-auth input or consent missing because prompting is disabled or unavailable — `--no-input`, no TTY, or closed stdin — → 2; `RSLB301` resource not found → 3; `RSLB401` credentials absent → 4; `RSLB402` credentials rejected → 4; `RSLB501` conflict/precondition failed → 5; `RSLB901` SIGINT → 130; `RSLB902` SIGTERM → 143; `RSLB903` prompt interrupted by Ctrl-C → 130 (a closed prompt stdin is **not** this code: it is required input that prompting cannot supply, so it is `RSLB205`/2 — see `## Engines`, Disagreement 4). **Envelope** — a single stderr JSON object `{"error":{"code","message","hint"?}}`; `hint` is an optional structured string field carried beside `code` and `message`, omitted (not `null`) when absent and rendered as its own line in human output — its Rust return type is P03's choice and must be able to name the offending input per R7.6, so a borrowed-or-owned string is expected rather than a `&'static str`; stdout stays byte-empty on the error path. This item defines exactly those three keys and defines no trace, cause-array or diagnostic field; R7.8 permits further documented fields, and any such field is a separate addition owned by the item that needs it. What a *stack trace* may do is deliberately absent from this contract: it is F301's, and F301's acceptance criteria are an open owner question (see `## Decision`). **Broken pipe** — a `BrokenPipe` result on the *result* stream ends the process at `0`, silently, with no envelope; a `BrokenPipe` while writing an already-selected error envelope to stderr retains the original application exit status rather than overriding it; a `BrokenPipe` on any other application stream is `RSLB101`/1; no `SIGPIPE` handler is installed and `println!`/`print!` are lint-denied in binary crates. **Boundary precedence** — signal → broken pipe → domain downcast → unexpected; `main` returns `ExitCode` and does not call `process::exit` on the error path; all streams are flushed before exit on every path including signal. **Crash record** — CLI surface only, UNEXPECTED class only, an injected best-effort sink writing `0600` newline-delimited JSON with timestamp, version, PID, code and sanitized cause chain and never argv, environment, headers, tokens or config contents; a write failure never changes the envelope or the exit code; **the location is not decided here and the default sink is a no-op until R57 answers**. **Layering** — `thiserror` in the library crate, `anyhow` (`>= 1.0.103`) in binary crates only; the library crate must not depend on `anyhow`, must install no signal handler or panic hook, and must write to no process stream or file.

**How the assumed parameters bear on the decision.** `rust-edition = 2024` is the single
most load-bearing value here: it is what makes `std::env::set_var` `unsafe`, what makes
`from_vars` the required signature, and what eliminates `confique` and `figment` on
testability. `msrv-policy` fixes the gate-2 floor at 1.96 against stable 1.98.1 and, read
strictly, is what excludes five of the eight candidate crates. `target-os-matrix` keeps
the design free of any platform `cfg` — `std::env::vars_os` and `str::FromStr` are
identical on both runners — and is also why Cloud Run's 10-second window is used as a
constraint on a default rather than as a platform commitment. `license` is `inapplicable`
here under the 2026-09-12 (Q7.B) ruling. `web-extra-surface` supplies the feature gate,
the serve binary, the tree the settings module lives in, and the sentence that makes this
item the namer of every service knob. `error-taxonomy-exit-codes` supplies `RSLB203` and
exit `2`, the single stderr JSON envelope the failure renders into, and the requirement
that `hint` be able to name the offending input — which is what makes the variable name,
the value and the expectation load-bearing rather than cosmetic — as well as the
`thiserror`-in-the-library rule `SettingsError` follows.

**`web-extra-surface` — the bytes above are revision 9's, and the design uses revision
10's paths. That is deliberate, and it is not a `CONFLICT:`.** The `assumes` line
reproduces the live registry row, which still reads "the library module `src/web/`…" and
"path-based skip-gating keys on `src/web/**`". R69 **revision 10 is owner-accepted and
unpublished** (`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`,
owned value at line 1791) and moves the gated tree to the optional workspace member
`crates/web`: `web = ["dep:rs-launch-blueprint-web"]` on the root package, the library
module at `crates/web/src/`, the web tests at `crates/web/tests/` with no file-level
`#![cfg(feature = "web")]`, and skip-gating on `crates/web/**`. **Every path in this
decision is revision 10's.** The substance of the two revisions is identical for this
item — only the manifest the crates are declared in moves — so the registry bytes are
carried unchanged and R69's republication is recorded above as a re-verify trigger.

**Two parameters a reader might expect on this list, and why neither is there.**
`build-tool-output-shape` (R49) bears on the decision only through where the serve binary
target is declared, which is R69's to state and not this item's; R49's own revision 8 is
unpublished, so carrying its registry bytes here would add staleness risk without adding
an argument. `logging-pipeline-contract` (R58) has the registry value `—`: R58 has
published nothing, which is precisely why `RSLBP_WEB_LOG_LEVEL` and
`RSLBP_WEB_LOG_FORMAT` are **named** here and **valued** there.

**No `CONFLICT:` line is raised, and the raw report raised none.** Two places a reader
might expect one: R69's exit-code enumeration does not list a settings failure, but a
malformed `RSLBP_WEB_*` variable is `RSLB203` at exit `2` under R67's published catalog —
an answer R67 already supplies, not a change R69's value needs. And R69's value says the
web tree is `src/web/`, which is the accepted-but-unpublished revision addressed above.

## Empirical check

**Toolchain and environment.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`;
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`; `Darwin arm64`
(`aarch64-apple-darwin`); `bash 3.2.57(1)-release`; `/usr/bin/grep` is
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD`. All work on 2026-09-18 (UTC). Current
stable Rust is **1.98.1 (48a229cea 2026-09-01)** per the release channel; the local
toolchain is one patch behind it, which affects no claim here — the MSRV floor is derived
from the channel figure, not from the local one. **Nothing was implemented:** every Rust
crate below was created under a `mktemp -d` directory beneath `$TMPDIR` and deleted when
the script exited; no Rust file was written into this repository and no nested git
repository or `target/` tree was created.

**Working directory for every command:** the repository root,
`/Users/stevemorin/c/rs-launch-blueprint-p02-plan`. Each script also resolves its paths
from its own location, so it runs from anywhere.

| Script | Command | Log | Result |
|---|---|---|---|
| `review/evidence/figures.sh` | `bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/figures.sh` | `review/evidence/figures.log` | exit **0** |
| `review/evidence/sources.sh` | `bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/sources.sh` | `review/evidence/sources.log` | exit **0** |
| `review/evidence/probes.sh` | `bash research/runs/R77/2026-09-17T034011Z-5884fd6b6366/review/evidence/probes.sh` | `review/evidence/probes.log` | exit **0** |

`review/evidence/fetch-snapshots.sh` is **not** an evidence check and makes no
assertions: it is the one-shot retriever that wrote `review/evidence/snapshots/` on
2026-09-18, with GitHub REST called no more often than once per 21 seconds. Its output
is `review/evidence/fetch-snapshots.log`. **That log lists nine crates; the directory
holds eleven.** The two extra rows, `pathdiff` and `winnow`, were retrieved by hand later
the same day — same endpoints, same User-Agent, same date — when `config`'s transitive
dependencies became load-bearing for the gate-2 reading, and the script's crate list was
then extended to include them so that any future refresh covers all eleven. The committed
`fetch-snapshots.log` is therefore the record of the first fetch rather than of the
script's current list; `figures.sh` asserts against all eleven snapshots regardless of
which run produced each one.

**What each script proves.**

- **`figures.sh`** asserts every published figure this decision cites — crates.io
  `crate.recent_downloads` / `crate.downloads`, the newest non-yanked version's `num`,
  `created_at`, `rust_version` and `license`, GitHub `stargazers_count`, `archived`,
  `pushed_at` and open-issue `total_count` from `search/issues` (never
  `open_issues_count`), and `[pkg.rust] version` — against the committed snapshots, then
  re-fetches the **immutable** half live and asserts it again. Download counters are
  printed as `DRIFT` lines and never asserted, because they only move upward. The RustSec
  block asserts a 404 for all eight crates *and* asserts HTTP 200 with `RUSTSEC-` hits for
  two known-advisory controls, so a site-wide outage cannot pass as "no advisory".
- **`sources.sh`** asserts, at a named line or in a named file, every quotation this
  decision makes: the ledger rows, the owner rulings, the prompt's empty `owns`/`consumes`
  lines, the eight owner-reference rows, R69 revision 10's owned value and `AppState`
  sketch, R57 revision 2's `TOOL_NAME`, R76/R79/R80's coupling sentences, nine lines of
  the org CLI Design Standard at blob `f9de0437baece3383e73ca2c5f48b7ab399b51c7`, the four
  quotations this decision takes from R53, R54, R56 and R67, nine py claims and one ts
  claim at their pins, nine candidate source lines at exact published versions, the
  `unsafe` posture of eight crates, and each `- assumes` line against the live registry
  row.
- **`probes.sh`** re-executes the six Rust probes described above.

**Counts, in place.** `figures.sh` **PASS=121 FAIL=0 SKIP=0**; `sources.sh` **PASS=84
FAIL=0 SKIP=0**; `probes.sh` **PASS=34 FAIL=0 SKIP=0**. Total **239 PASS, 0 FAIL,
0 SKIP**.

**Reproducibility, established rather than asserted.** Each script was re-run
immediately after the run whose log is committed, and the second run's output was diffed
against that log; the diffs are recorded verbatim in `review/evidence/rerun-diff.log`.
**Every `PASS` / `FAIL` / `SKIP` line is identical across the two runs**, which is
asserted in that log by a second diff taken over those lines alone. Exactly three kinds
of line vary, and this is the rule for comparing across a re-run:

1. each script's own `# R77 … — <timestamp>` header line;
2. in `probes.log` only, three lines *inside* cargo's captured output — the `mktemp -d`
   scratch directory name, which is new on every run, and cargo's own
   `Finished … target(s) in N.NNs` wall-time line;
3. in `figures.log` only, the `DRIFT` lines, whose rule the script's own header states
   ("a SNAPSHOT line must match exactly; a DRIFT line may move upward for a counter and
   forward for a timestamp"). They happened not to move between these two runs; they are
   still not asserted, because a download counter is monotonic and will move.

Nothing else differs.

**Rerun from a clean extraction.** `git archive 484fd2e | tar -x -C <tmpdir>` extracted
commit `484fd2e`, the revision this paragraph was written against. The commit that
records this paragraph differs from `484fd2e` only by this text, four further `file_has`
lines added to `sources.sh`, and the regenerated logs. The extracted tree has no `.git`
at all — tested with `-e`, not `-d`, because a worktree's `.git` is a *file* rather than
a directory. All three scripts were re-run from that extraction and gave the same counts
as in place at that commit: `figures.sh` **PASS=121 FAIL=0 SKIP=0**, `sources.sh`
**PASS=80 FAIL=0 SKIP=0** — 84 after the four additions — and `probes.sh` **PASS=34
FAIL=0 SKIP=0**. The full output, with the extracted commit named in its header, is
`review/evidence/archive-rerun.log`.

**The SKIP branches, exercised rather than assumed.** That extraction SKIPped nothing,
because every out-of-repository input — the org CLI Design Standard clone, the py and ts
clones, the local Cargo registry cache — was still present on this machine. A run in
which nothing SKIPs proves nothing about the SKIP paths, so `sources.sh` was run once
more from the same extraction with `HOME` pointed at an empty directory, which hides all
three. It produced, at commit `484fd2e`, **PASS=43 FAIL=0 SKIP=4** with each group named
individually: the standard blob (9 checks), the py pin (9), the ts pin (1) and the
registry cache (18). 43 plus those 37 is 80, that commit's in-place total — so nothing is
lost silently, and a missing external input is a named SKIP rather than a FAIL or an
invisible pass.

**Answer-shape validation.** `validate_answer_text(text, "crate")` from
`scripts/research_validation.py` returns no diagnostics for this item's raw report,
`raw/opus.md`. It is not applied to `DECISION.md`, and would not pass there: that
validator requires the prompt's fifteen `###` answer fields in order, while a decision
follows the synthesizer role contract's four `##` sections with a single
`### Principles and implementation` inside `## Decision` — the same shape as the accepted
R68 decision. `bash scripts/check-research-tree.sh .` passes.

## Engines

- opus `raw/opus.md` — Claude Opus 5, sha256
  `a81c6372fe084f805fa4058c68e60af7064b354de69a2a0da0360b9c2a0ac533`, answer shape OK
  under `validate_answer_text(..., "crate")`. Recommends adopting no crate: template code
  over `std::env::vars_os` and `str::FromStr`, prefix `RSLBP_WEB_` derived by `const fn`
  from R57's `TOOL_NAME`, value threaded through the framework's own state mechanism;
  runner-up `config` 0.15.25 with default features off; `confique` third.
- codex — **absent.** The focused-tier Codex research leg is deferred by the controller
  under owner ruling **W1-CODEX3** of 2026-09-18 (the Codex account is at its usage
  limit), and the run manifest records `state: partial` with `required_engines:
  [codex, opus]`. **This decision is therefore synthesized from a single engine.** There
  are no inter-engine disagreements to settle, and nothing in the raw report has been
  corroborated by a second model. That is the reason every load-bearing claim below was
  re-executed or re-read at source by the synthesizer rather than carried on the report's
  word, and the reason the "carried" and "unproven" rows are listed explicitly.

**Re-verified in this run — claim by claim.**

| Claim | How it was re-verified | Outcome |
|---|---|---|
| Gate 2: `envy` 0.4.2, `figment` 0.10.19, `envconfig` 0.11.1, `serde-env` 0.3.0, `envious` 0.3.0 declare no `rust-version`; `config` declares 1.85.0, `confique` 1.68.2, `serde` 1.56 | crates.io `/versions`, snapshot **and** live re-fetch of the immutable per-version field | **reproduced exactly** |
| Every download, star, `archived`, `pushed_at` and open-issue figure cited | crates.io and GitHub REST, snapshot + live | **reproduced exactly** |
| Current stable is 1.98.1, so the floor is 1.96 | `channel-rust-stable.toml`, `[pkg.rust] version` | **reproduced exactly** |
| No RustSec advisory for any of the eight crates | 404 for all eight, with `atty` and `time` as HTTP 200 controls | **reproduced exactly** |
| The `const fn` prefix derivation compiles, evaluates in const context, and follows a renamed `TOOL_NAME` | probe P1, strengthened with `const _: () = assert!(…)` so a wrong value is a compile error | **reproduced** |
| Edition 2024 makes `set_var` unsafe | probe P2, strengthened with an edition-2021 control that compiles and runs | **reproduced, with a control the raw did not run** |
| The five `Display` strings for `RSLBP_WEB_PORT=eighty` | probe P3 run 1, asserted verbatim | **reproduced exactly** (the `confique` string names the probe's struct, `WebSettingsC`) |
| `figment` and `confique` have no injected-source seam | probe P3 run 2, with the process environment cleaned via `env -u`, plus the source lines at `figment/src/providers/env.rs:171,:198,:505` and `confique/src/builder.rs:38`, `src/internal.rs:54` | **reproduced, and sharper**: both silently return defaults while template code, `envy` and `config` report the error |
| The four axum tests, including `FromRef<AppState> for Arc<WebSettings>` | probe P4 against real axum 0.8.9 / tokio 1.53.1 / tower 0.5.3 | **reproduced** — 4 passed, 0 failed |
| `confique` rejects a non-literal env name | probe P5 | **reproduced** — `error: expected string literal` |
| Package counts 8 / 9 / 12 / 11 / 16 / 55 | probe P6, asserted individually | **reproduced exactly** |
| `unsafe` posture of `config`, `confique`, `envy`, `figment` | registry cache at exact versions | **reproduced** — 0 in each `src/` |
| Every quotation from the org CLI Design Standard, the owner rulings, the ledger, the owner-reference document, R69 revision 10, R57 revision 2, and the py and ts pins | `sources.sh`, at the cited line | **reproduced exactly**, every line number included |
| Each `- assumes` line | extracted from the live `docs/port/PARAMETERS.md` by script and compared | **byte-identical**; `inputs/PARAMETERS.md` and the live registry are also identical, so nothing moved during the run |

**Gaps the raw report stated, and what this run did about them.**

| Gap | Disposition |
|---|---|
| `unsafe` posture, default features and platform support of `envconfig`, `serde-env`, `envious` "not extracted" | **closed for `unsafe` and features.** The three crates were fetched and their `src/` trees audited: **0** `unsafe` in each; all three are edition 2021 with no async coupling. They were not *built*, so gate 4 remains stated rather than measured for them — they are excluded at gate 2 regardless. |
| `serde`'s own `unsafe` posture, carried from R53 revision 2 | **closed.** Re-audited here: exactly **2** `unsafe` blocks in `serde-1.0.229/src/`, both `str::from_utf8_unchecked`, matching R53's recorded figure. |
| `confique`'s declared `rust-version = 1.68.2` never compiled on 1.68.2 | **still unproven.** Only current stable was exercised; proving it needs an old toolchain. It does not bear on the recommendation, which does not adopt `confique`. |
| Windows behaviour | **still unproven, and not required.** `target-os-matrix` is `ubuntu-latest, macos-latest`. |
| Binary sizes are `aarch64-apple-darwin` only | **unchanged.** `x86_64-unknown-linux-gnu` was not measured; only the deltas and the three thresholds asserted in P6 are treated as findings. |

**Claims carried, not re-verified.**

- **Issue-responsiveness medians** (`config-rs` 0.22 days / 9 of 10 answered; `confique`
  68.06 / 7 of 10; `envy` 73.42 / 1 of 10; `figment` 185.0 / 1 of 10). Re-sampling them
  costs roughly 44 further GitHub calls at a 21-second floor and they do not decide the
  answer — gate 2 does. They are carried from `raw/opus.md` and labelled as carried
  wherever they support a maintenance verdict.
- **Adoption rows** (`nextest-runner`, `leptos_config`, `tor-config`, `mise`,
  `esp-idf-sys`, `axum-client-ip` and the rest). The raw report confirmed each through
  `GET https://crates.io/api/v1/crates/<adopter>/<version>/dependencies`; those calls were
  not repeated here. They inform the landscape, not the gates.
- **py's and the owner-reference document's wider content** beyond the lines asserted in
  `sources.log`.

**Claims from the raw report that this run could NOT reproduce.**

1. **The baseline stripped binary size of 302,704 B.** Re-measuring gave **286,048 B**
   for a baseline built here. The figure is not recoverable, because the raw report did
   not publish the body of its baseline program and a stripped size depends on it. The
   consequence is favourable rather than adverse: the raw reported template code as
   80 bytes *larger* than `envy`, while this run measures it **16,576 bytes smaller**.
   Because of this, `## Decision` cites only **deltas** over a baseline whose source is
   in `probes.sh`, and `probes.sh` asserts five size *thresholds* and never an absolute
   byte count.
2. **The raw's statement that the first five clean-build times "are within this machine's
   noise of each other".** This run measured `figment` at 14.11 s against a 6.15 s
   baseline — about 2.3× — which is outside anything this run can call noise. It is a
   single sample on a machine also running network polling, so it is not asserted either
   way and no conclusion is drawn from it; the sentence is simply not carried. The one
   build-time figure this decision does use is `config` with default features at
   roughly 3× the baseline, which reproduced in direction and magnitude (19.05 s versus
   the raw's 25.88 s, against baselines of 6.15 s and 8.48 s).

**One claim the raw stated with a qualifier this decision keeps.** `config`'s transitive
`pathdiff` 0.2.3 declares no `rust-version` (re-verified here at the versions endpoint).
`config` is not excluded for it only because the *third*, strictest reading of gate 2 is
the one `docs/planning/p02/owner-decisions.md` says "is not on the table unless you put
it there". If the owner ever puts it there, `config` — the ranked runner-up — falls too,
and template code becomes the only surviving answer rather than the preferred one.

**Where evidence is incomplete, stated plainly.** The 8-second shutdown budget is the
weakest-supported value in this decision: the *rule* (strictly less than the platform's
SIGKILL point, measured from the signal) is high-confidence, but the number is a judgement
about margin, resting on a platform datum for a platform this template does not target,
and R80's parallel research adds a second consumer of the same budget. An owner could
reasonably set 5, 8 or 9. The comma-separated list encoding is likewise medium-confidence:
it is the Rust idiom and it is safe for this field set, but R76 owns CORS semantics and
could need an encoding that survives a comma.

**What P03 must validate.** AC6 (a malformed variable exits `2` with R67's `RSLB203`
envelope on stderr and a byte-empty stdout); AC7 and AC7b (the environment is read in
exactly one file in `crates/web`, and never in `crates/core`); AC8 (a SIGTERM during an
in-flight request drains and the process exits `143` within the budget); AC9 (the
documented variable table and the struct's field list cannot drift); AC10 (with the `web`
feature off, neither the settings type nor the environment read exists in the binary);
and, once R80 publishes, that the readiness-propagation pause and the drain together fit
inside the 8-second budget rather than extending it.
