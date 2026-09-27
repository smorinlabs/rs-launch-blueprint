# R77 raw report (Muse engine) — Web env settings (crate)

Research date (all live queries): 2026-09-25. Figures below are exact endpoint values on that date.

### Landscape

Category decided: typed, env-var-driven settings loading for the web service — a serde-deserializable settings struct populated from process environment under an app-derived prefix, constructed once at startup.

Three-bin map of the Rust field:

- Built-in / first-party toolchain: no settings crate exists in this bin. The toolchain ships `std::env` only (https://doc.rust-lang.org/std/env/, retrieved 2026-09-25); typed parsing above it is user or ecosystem code. The hand-rolled baseline (`std::env` + `serde`) is evaluated as an architecture in `### Principles and implementation`, not as a crate candidate.
- Established industry standard: `config` (layered builder, env/file/default sources), `figment` (provider-merge config engine behind Rocket), `envy` (flat prefixed env-to-struct deserialization), `dotenvy` (`.env`-file loader only — complement, not a typed-settings candidate), `serde` (shared deserialization foundation, not itself a settings loader).
- Up-and-comer: `envconfig` (derive-macro env mapping, 1520901 recent downloads), `confique` (derive-based file+env config, 166282 recent downloads), `twelf` (layered config on top of `envy`, 37391 recent downloads). Figures from `GET https://crates.io/api/v1/crates/<name>` field `crate.recent_downloads`, retrieved 2026-09-25.

Authority used, and why each counts:

1. Maintainers' own artifacts (normative for API behavior): `config`/`figment`/`envy` crate sources from `https://static.crates.io` tarballs (API signatures and `unsafe` posture verified by direct inspection, 2026-09-25); manifests from `https://raw.githubusercontent.com/rust-cli/config-rs/main/Cargo.toml`, `.../SergioBenitez/Figment/master/Cargo.toml`, `.../softprops/envy/master/Cargo.toml` (edition, license, MSRV, features, dependencies); reference docs at `https://docs.rs/config`, `https://docs.rs/figment`, `https://docs.rs/envy`.
2. Framework documentation (normative for the state/DI mechanism): `https://docs.rs/axum/latest/axum/extract/struct.State.html` and `https://docs.rs/actix-web/latest/actix_web/web/struct.Data.html` (both HTTP 200 with expected titles, retrieved 2026-09-25).
3. `crates.io` API (`/api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`, `/<crate>/<version>/dependencies`) — ecosystem adoption signal (downloads, reverse-dependency counts and edges), retrieved 2026-09-25.
4. Adopter repositories' own `Cargo.toml` files (production-use proof): `nextest-runner` workspace manifest pins `config` (https://raw.githubusercontent.com/nextest-rs/nextest/main/nextest-runner/Cargo.toml, line 29, retrieved 2026-09-25); Rocket `core/lib/Cargo.toml` pins `figment 0.10.17` with `toml, env` features (https://raw.githubusercontent.com/rwf2/Rocket/master/core/lib/Cargo.toml, line 64, retrieved 2026-09-25); `twelf 0.15.0 -> envy ^0.4.1` and `leptos_config 0.8.5 -> config ^0.15.13` normal-dependency edges verified via the crates.io dependencies API, 2026-09-25.
5. RustSec (`https://rustsec.org/packages/<name>.html`, retrieved 2026-09-25) — advisory ground truth. All six candidates return HTTP 404 (no advisory page); the 404-means-clean reading was verified against the control `https://rustsec.org/packages/ansi_term.html`, which renders advisories including RUSTSEC-2021-0139.
6. Upstream CI manifests (platform evidence): `rust-cli/config-rs/.github/workflows/ci.yml` (os matrix `ubuntu-latest, windows-latest, macos-latest`), `SergioBenitez/Figment/.github/workflows/ci.yml` (Linux/Windows/macOS matrix), `softprops/envy/.github/workflows/main.yml` (ubuntu-only), all retrieved 2026-09-25.
7. No blog post or single write-up is relied upon as authority; none was needed — every behavioral claim below traces to maintainer artifacts or executed probes.

Practice evidence (well-regarded projects surveyed):

- Rocket uses `figment` as its configuration engine (maintainer-authored: same author, Sergio Benitez; pinned in Rocket core). Rocket is the canonical production reference for `figment` by construction.
- cargo-nextest (`nextest-runner`) depends on `config` (workspace manifest, verified above). cargo-nextest is the de-facto next-generation Rust test runner; its adoption evidences `config`'s fitness for layered real-world configuration.
- Leptos (`leptos_config`) depends on `config ^0.15.13` (dependencies API, verified above). Leptos is a leading Rust full-stack web framework, directly relevant to the web-service use case.
- `twelf` (layered env/flag/file config) builds on `envy ^0.4.1` (dependencies API, verified above); `slatedb`, `cargo-lambda-metadata`, `tor-config` appear in `figment`'s reverse-dependency set (total 517) and `rumqttd`, `deadpool*`, `git-cliff-core` in `config`'s (total 1579), per the reverse-dependencies API, 2026-09-25. Reverse-dependency totals: `config` 1579, `figment` 517, `envy` 192.

Fit framing (used throughout): the web-only, env-only settings object with an app-derived prefix, matching py's `pydantic-settings`-based `WebSettings` (`ENV_PREFIX = f"{APP_NAME.upper()}_WEB_"`), threaded through an undecided framework's state/DI (R69 owns the framework). CLI layered config belongs to R53/R54/R55/R56; reuse of one crate across both is a valid finding, not a requirement.

### Principles and implementation

Shared requirement (source: owner direction 2026-09-04, "take the principles from the Python implementation and make sure there are equivalents in TypeScript and Rust"; py precedent `src/py_launch_blueprint/web/settings.py:38`): the web service loads its settings from environment variables into a typed, validated object under a prefix derived from the app name, constructed once at startup, and injected into request handlers — never read piecemeal from the environment inside handlers.

Agreement level: architectural pattern + capability, not shared low-level value. What must agree across py/ts/rs: (a) one typed settings object per app surface; (b) prefix derived from a single app-name constant by the rule `UPPER(APP_NAME) + "_WEB_"`; (c) construction once at startup (fail fast); (d) injection into handlers through the framework's state/DI mechanism; (e) malformed/missing values produce errors naming the field, the expected type and the offending value. What may vary justifiably: the loading library (no crate spans languages; `pydantic-settings` has no Rust twin), error-type shape (mapped into each repo's taxonomy), and layering/file support (Rust CLI layering is owned by R53–R56, not this item). ts has no web service (F303), so ts carries no implementation — a follow-on project applies this pattern if ts ever gains one; nothing in ts contradicts it today. No ledger change is proposed: F324 stays `DIVERGENT` at mechanism level with an agreed pattern, so no `BASELINE-REVIEW:` line is emitted.

Architectural alternatives compared before choosing libraries:

1. Layered builder (`config`): `Config::builder().add_source(Environment::with_prefix(..)).build()?.try_deserialize::<T>()`. Sources layer (env over file over defaults); prefix + separators are source options. Verified in `config-0.15.26/src/env.rs:113` (`with_prefix(&str)`), `:140` (`prefix_separator`), `:151` (`separator`), `src/builder.rs:190,230` (`add_source`, `build`).
2. Provider merge (`figment`): `Figment::new().merge(Env::prefixed(..)).extract::<T>()`, with profiles. Verified in `figment-0.10.19/src/providers/env.rs:198` (`Env::prefixed(&str)`). Richest error value (`src/error.rs:89`: profile, metadata, path, kind).
3. Flat prefixed mapping (`envy`): `envy::prefixed(prefix).from_env::<T>()`. Verified in `envy-0.4.2/src/lib.rs:364` (`prefixed<C: Into<Cow<str>>>`) and `:316` (`from_env`). Minimal error enum: `MissingValue(&'static str) | Custom(String)` (`src/error.rs:8`).
4. Hand-rolled `std::env` + `serde`: full control, zero new dependencies, but every fork re-implements prefix stripping, type parsing and error rendering — the exact logic this item exists to standardize. Rejected: highest fork-drift risk, no reuse with R53.

Compile-time prefix derivation (HIGH question): none of the three crates derives the prefix at compile time — all take a runtime `&str`/`Cow<str>`. The py semantic is preserved by building the prefix once at startup from the app-name constant (`format!("{}_WEB", APP_NAME.to_uppercase())`) and passing the resulting `String`. No per-fork string literal is needed; the constant remains the single source of truth. Verified pattern in executed probes (see `### Validation strategy`).

State/DI threading (MEDIUM question): all three candidates yield a plain owned struct with no framework coupling, so the threading path is identical and framework-agnostic: construct `WebSettings` once in the web binary's startup/factory path, wrap in `Arc` (or rely on the framework's clone-on-extract), and install into framework state — `axum::extract::State<T>` (`https://docs.rs/axum/latest/axum/extract/struct.State.html`, 2026-09-25) or `actix_web::web::Data<T>` (`https://docs.rs/actix-web/latest/actix_web/web/struct.Data.html`, 2026-09-25) — matching py's app-factory composition. No parsing logic is duplicated between CLI and web: the struct and its loader live in the library crate; each binary calls `load()` once. No R69 assumption is made beyond "a state/DI handle carrying a cloneable owned value", which both candidate frameworks provide.

Error-reporting shape (MEDIUM question), verified against sources and one executed probe:

- `config`: `ConfigError::{NotFound(key), Type{origin, unexpected, ..}, PathParse, FileParse, ..}` (`src/error.rs:43+`). Executed Display: `invalid type: string "not-a-port", expected an integer for key 'port' in the environment` — names field, expected type and offending value. Maps into R67's taxonomy via a thin `map_err` (Display string + key); no new taxonomy is designed here and none is needed.
- `envy`: `MissingValue(field)` names the field; all parse failures collapse into `Custom(String)` renderer output. Mappable to R67 but with less structure (no expected-type accessor).
- `figment`: `Error{profile, metadata, path, kind}` is the most structured; maps well but its `Kind` taxonomy is figment-specific and would need translation all the same.

Performance: config loading is a startup-once path (one process env scan per boot), so throughput benchmarking is inapplicable; no crate claims or needs a latency advantage here. Relative startup cost follows dependency weight: `envy` (serde only) < `figment` (serde + uncased) < trimmed `config` (serde_core + pathdiff + winnow) << full-default `config` (six file parsers + convert-case + async-trait). No absolute fastest option is inferred; workload stated (single load at boot), instrumentation none required.

Maintained reference implementations: Rocket's `Figment`-based configuration (https://github.com/rwf2/Rocket, `core/lib` pins `figment`, retrieved 2026-09-25) for provider-merge; cargo-nextest and Leptos for layered `config` (verified above); `twelf` for `envy`-under-layering. Maturity/dependability/integration-cost comparison is folded into `### Qualified shortlist` and `### Tradeoffs`.

Minimal realistic example (executed 2026-09-25, rustc 1.98.1, `config 0.15.26`, `serde 1.0.229`, probe in `/tmp/r77probe`):

```rust
use serde::Deserialize;
pub const APP_NAME: &str = "rs_launch_blueprint";
#[derive(Debug, Deserialize)]
pub struct WebSettings { pub host: String, pub port: u16 }
pub fn env_prefix() -> String { format!("{}_WEB", APP_NAME.to_uppercase()) }
pub fn load() -> Result<WebSettings, config::ConfigError> {
    config::Config::builder()
        .add_source(config::Environment::with_prefix(&env_prefix()).separator("_"))
        .build()?
        .try_deserialize()
}
```

Note the empirically discovered subtlety: `with_prefix` takes the prefix *without* the trailing separator (the crate appends `prefix_separator`, default `_`), so py's `"..._WEB_"` becomes Rust's `"..._WEB"`. Passing the trailing underscore yields `missing configuration field "host"` (reproduced before the fix). Executable acceptance check: `cargo test` with `RS_LAUNCH_BLUEPRINT_WEB_HOST/PORT` set asserts typed load; with `PORT=not-a-port` asserts the error names `port` — 3/3 passed (executed, not merely planned).

### Dominant choice

`config` — the layered configuration builder (`https://github.com/rust-cli/config-rs`, retrieved 2026-09-25). Rationale: largest adoption in the category (18868961 recent / 115883048 all-time downloads, 1579 reverse dependents, endpoints as in `### Qualified shortlist`), the only finalist with a release inside the last year (0.15.26, 2026-09-21, four days before retrieval), exact license match (`MIT OR Apache-2.0`), declared MSRV (1.88.0) with edition 2024, full ubuntu+macOS+Windows CI matrix, and direct fitness for both this item (env source with derived prefix) and future reuse (layering for R54, shared crate candidacy for R53).

### Qualified shortlist

All figures retrieved 2026-09-25. Download endpoints: `GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`); release endpoint: `GET https://crates.io/api/v1/crates/<name>/versions` (newest `yanked: false`); repo endpoint: `GET https://api.github.com/repos/<o>/<r>` (`stargazers_count`, `archived`, `pushed_at`); open-issue endpoint: `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`).

- `config` · role: layered builder; env source with derived prefix, file/default layering for future reuse · 90-day: 18868961 · all-time: 115883048 · stars: 3213 · last release: 0.15.26 @ 2026-09-21T13:08:27Z · maintenance: active (pushed 2026-09-25T01:17:15Z; open issues 110) · notable adopters: nextest-runner (cargo-nextest, workspace manifest line 29), leptos_config 0.8.5 (`config ^0.15.13` edge verified), rumqttd/deadpool/git-cliff-core (reverse-dependency set, total 1579) · trade-off: heaviest defaults; must be taken with `default-features = false` for this env-only use.
- `figment` · role: provider-merge engine with profiles; `Env::prefixed` source, richest error value · 90-day: 10545366 · all-time: 39686900 · stars: 913 · last release: 0.10.19 @ 2024-05-17T02:54:57.543501Z · maintenance: stable-quiet (16 months since release was the investigation trigger; pushed 2024-09-13T04:51:49Z; open issues 21; responsiveness 1/10 answered, 185 days to first maintainer response on #148, 9 unanswered — yet Rocket core pins `figment 0.10.17`, so breakage on current stable would block Rocket itself) · notable adopters: Rocket (author-flagship, core/lib line 64), slatedb, cargo-lambda-metadata, tor-config (reverse-dependency set, total 517) · trade-off: profiles and merge semantics are overkill for env-only settings; slowest maintainer response.
- `envy` · role: minimal flat env-to-struct mapping; `prefixed(..).from_env::<T>()` one-liner · 90-day: 3627334 · all-time: 21157795 · stars: 981 · last release: 0.4.2 @ 2021-01-04T00:17:01.205407Z · maintenance: stable-quiet (5.7 years since release was the investigation trigger; pushed 2024-06-07T23:13:52Z; open issues 14; responsiveness window partially unretrievable — GitHub API rate-limited after #82 with 0 comments; #76 "Is envy unmaintained?" is closed, author-level detail unverified — gap recorded; 3.6M recent downloads on a 2-file serde-only crate indicate feature-completeness rather than abandonment, but release staleness is real risk, see `### Tradeoffs`) · notable adopters: twelf 0.15.0 (`envy ^0.4.1` edge verified), esp-idf-sys / axum-client-ip (named in reverse-dependency set, total 192; edge versions unverified) · trade-off: thinnest error type and stalest release; leanest footprint.

Fitness gates, per candidate (answered before popularity was weighed):

1. License: `config` MIT OR Apache-2.0 (exact; version payload `license`, 2026-09-25) — pass. `figment` MIT OR Apache-2.0 — pass. `envy` MIT — pass (compatible with `MIT OR Apache-2.0`).
2. MSRV within stable-minus-2 (stable ≈ 1.98: local `rustc 1.98.1 (2026-09-01)` observed 2026-09-25; config-rs PR #769 "Update Rust Stable to v1.98", 2026-08-20): `config` declares `rust-version = 1.88.0`, edition 2024 (workspace manifest) — pass; trimmed dep tree is serde_core/pathdiff/winnow (see `### Validation strategy`), all older than the window — pass. `figment`/`envy` declare no `rust-version` (editions 2018/2021) — pass by construction age plus current-toolchain evidence: `envy 0.4.2` compiled and tested on rustc 1.98.1 in this research (executed); `figment` rides Rocket's active development on current stable (reasoning, labeled as such).
3. Advisories/`unsafe`: no open RustSec advisory for any of the three (HTTP 404 on advisory pages, control-verified, 2026-09-25) — pass. `unsafe` posture: zero `unsafe` matches in `src/` of all three version tarballs (direct grep, 2026-09-25) — pass.
4. OS matrix (ubuntu-latest, macos-latest; Windows noted): `config` CI tests all three (ci.yml os matrix) — pass. `figment` CI tests Linux/Windows/macOS — pass. `envy` upstream CI is ubuntu-only — gap closed by direct evidence: `envy 0.4.2` built and passed its probe test on macOS/arm64 (Darwin 25.4.0, rustc 1.98.1) in this research, 2026-09-25 — pass with that substitution recorded. All three are pure Rust with no target-gated dependencies (manifests inspected) — Windows expected fine, not required.
5. Default features / async coupling: `config` defaults are heavy (`toml, json, yaml, ini, ron, json5, convert-case, async` incl. async-trait) — the recommendation disables them (`default-features = false`), leaving no async coupling — pass as recommended. `figment` default `["env"]` is a documented no-op — pass, no async coupling. `envy` has no features at all — pass, no async coupling.
6. Binary size / compile time (qualitative): `envy` negligible (11 KB source, serde only); `figment` small (70 KB + uncased); trimmed `config` small (serde_core + pathdiff + winnow, `cargo tree` verified); full-default `config` heavy (six parsers) — avoided by the recommendation — pass as recommended.

### Excluded by gate

None. All three shortlisted candidates passed every applicable fitness gate (with the two recorded substitutions: `envy` macOS evidence via local build, `figment` MSRV via construction age plus Rocket-canary reasoning). `dotenvy` (47728423 recent / 171625531 all-time downloads, 0.15.7 @ 2023-03-22, MIT, 1252 stars, 33 open issues, endpoints as above, 2026-09-25) is not a gate failure — it is out of decision scope because it only loads `.env` files into the process environment and performs no typed deserialization or prefix mapping; it composes with any pick. Hand-rolled `std::env` + `serde` is an evaluated architecture, not a crate, so crate gates do not apply to it.

### Up-and-comers

- `envconfig` 0.11.1 @ 2025-12-10T06:58:38Z (1520901 recent / 10164682 all-time downloads; MIT; 232 stars; pushed 2025-12-10; 6 open issues; endpoints as above, 2026-09-25): derive-macro env mapping with prefix support. Not shortlisted: proc-macro-based field mapping is a larger conceptual commitment for a template, ecosystem footprint is an order of magnitude below `envy`, and it adds nothing over the pick for the env-only use case. Watch if derive-style config becomes the template-wide convention.
- `confique` 0.4.0 @ 2025-10-27T13:24:58Z (166282 recent / 505539 all-time; MIT OR Apache-2.0; rust-version 1.68.2; 223 stars; pushed 2025-10-27; 19 open issues; endpoints as above, 2026-09-25): derive-based layered (file + env) config from a respected single maintainer. Not shortlisted: smallest adoption of the set, single-maintainer bus factor without a flagship canary, and file-layering belongs to R53/R54's future decision.
- `twelf` 0.15.0 @ 2024-03-11 (37391 recent / 353282 all-time; endpoints as above, 2026-09-25): layers env/flags/files over `envy`. Not shortlisted: thinner adoption than its own foundation and last release 2.5 years ago; its `envy` edge is cited as adopter evidence instead.

### Fit for this template

- CLI: this item does not decide CLI config (R53–R56 own it). Fit note: if R53 also selects `config`, the template gets one config crate, one error type and one mental model across CLI file+env layering and web env-only settings — explicitly a valid finding per this item's couplings. If R53 goes elsewhere, the web pick stands alone (trimmed `config` adds only serde_core/pathdiff/winnow beyond serde). No action for R53 is assumed.
- Library: the `WebSettings` struct, `APP_NAME` constant, prefix derivation and `load()` live in the library crate as pure functions over an injected iterator or the process env; the library itself performs no framework I/O. This keeps the settings module unit-testable (prefix test needs no env) and shared by any binary. Fits all three candidates equally; `config`'s `from_iter`-friendly builder and `envy::from_iter` both support env injection in tests.
- Web: full fit for the recommended `config` path — env-only source, derived prefix, serde validation, single startup construction, `Arc<WebSettings>` (or framework clone) into `State`/`Data`, per-handler injection with zero per-request parsing. Matches py's `WebSettings` semantics field-for-field (string/host/port/optionals) and preserves the fail-fast startup behavior. `figment` additionally fits if R69 ever wants profile-based (dev/staging/prod) web configuration — not required today. `dotenvy` may be composed in front of any pick for local `.env` loading without affecting the decision.

### Recommendation

Use `config` for the web settings object:

```toml
config = { version = "0.15", default-features = false }
serde = { version = "1", features = ["derive"] }
```

Version range: caret `0.15` (verified against 0.15.26, released 2026-09-21; `rust-version 1.88.0`, edition 2024, `MIT OR Apache-2.0`). Construction pattern (executed): `format!("{}_WEB", APP_NAME.to_uppercase())` as `Environment::with_prefix(..)` with default `_` separators — note the missing trailing underscore versus py's `"..._WEB_"`, which the crate supplies. Load once at web startup via `Config::builder().add_source(...).build()?.try_deserialize::<WebSettings>()`; install the resulting struct into framework state (`State`/`Data`); map `ConfigError` into the R67 taxonomy with a thin `map_err` (Display already names field, expected type and offending value). Do not enable default features: the six file parsers plus `async`/`convert-case` are dead weight for env-only settings and widen the MSRV/compile-cost surface. Two template notes follow from executed evidence: (1) on edition 2024, `std::env::set_var/remove_var` are `unsafe` — tests mutating env need `unsafe` blocks or an injection seam (`from_iter`-style); (2) env-mutating tests must run `--test-threads=1` or use per-test process isolation.

### Ranked runner-up

`envy` 0.4 (verified 0.4.2; `envy = "0.4"`, MIT, serde-only). It wins instead of `config` if R53 selects a non-`config` CLI crate (removing the reuse premium) *and* the template prioritizes minimal web dependency footprint and a one-line loader (`envy::prefixed(prefix).from_env::<T>()`, trailing underscore included — opposite separator convention from `config`, verified in the executed probe) over active maintenance and structured errors. It also wins if `config` 0.x churn ever breaks the builder API and the template wants the smallest possible settings surface while waiting out the ecosystem.

### Tradeoffs

- Versus `envy` (runner-up): the pick accepts a larger dependency tree (serde_core + pathdiff + winnow vs serde alone) and a more verbose builder call in exchange for active maintenance (release 4 days before retrieval vs 5.7 years stale), an exact license match, a declared MSRV, structured errors (expected type + offending value, not just a field name), and layering/reuse headroom for R53/R54. The staleness risk of `envy` (unmerged PRs,ubuntu-only CI, closed-but-unverified "unmaintained?" thread) is the cost declined.
- Versus `figment`: the pick gives up profiles and the most structured error value (`profile`/`metadata`/`path`/`kind`) in exchange for a maintained release train, a declared MSRV, an exact-license+edition-2024 manifest, a full OS CI matrix, and an API whose only concept is "layered sources" rather than Rocket's profile/provider model. If R69 later requires profile-based web configuration, revisit `figment` (re-verify trigger below).
- Versus hand-rolled `std::env` + `serde`: the pick accepts an external crate (supply-chain and version-churn surface) in exchange for standardized prefix/separator handling, collection parsing, and error rendering that every fork would otherwise re-implement and drift on. The empirical separator subtlety (trailing-underscore conventions differ per crate) is exactly the kind of fork-divergent detail a shared crate absorbs once.

### Parameters

R77 owns no registry parameters and consumes none (`- owns:` and `- consumes:` are empty in `## Couplings`).

- `assumes rust-edition = 2024` (owner-fixed, `docs/port/PARAMETERS.md`)
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (owner-fixed)
- `assumes license = MIT OR Apache-2.0` (owner-fixed)
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (owner-fixed)
- No `CONFLICT:` lines — the recommendation satisfies every fixed parameter as stated.

### Migration implications

Template file-level changes (CLI + library + web service shape, R69 framework still open):

- `Cargo.toml` (web crate, or workspace root if unified): add `config = { version = "0.15", default-features = false }`; ensure `serde` with `derive` is available where `WebSettings` is defined.
- New settings module (suggested `src/web/settings.rs`, or library `settings` module if R53 converges on `config`): `APP_NAME` const, `WebSettings` struct with serde defaults/`Option`s, `env_prefix()`, `load() -> Result<WebSettings, config::ConfigError>`.
- Web binary startup (`main.rs` / app factory): call `load()` once, fail fast with the mapped R67 error, install into framework state (`with_state` / `app_data`); handlers take `State<WebSettings>` (or `Data`) — no direct `std::env` reads anywhere else.
- Tests: unit test for prefix derivation (no env needed); integration tests for typed load and malformed-value error (env-mutating; edition-2024 `unsafe` + single-threaded execution as noted).
- Docs/fixtures: `.env.example` documenting the `APP_WEB_*` variables; no new error taxonomy (R67 owns codes — this item only maps).
- No changes to CLI config discovery, file formats, error-code catalog, or any other item's owned surface.

### Validation strategy

Executed in this research (2026-09-25, macOS arm64 Darwin 25.4.0, rustc/cargo 1.98.1, `CARGO_HOME=/tmp/cargo-home`):

- `/tmp/r77probe` (`config 0.15.26` + `serde 1.0.229`, `default-features = false`): `cargo test -- --test-threads=1` → 3 passed, 0 failed: (1) prefix derives as `RS_LAUNCH_BLUEPRINT_WEB` from `APP_NAME`; (2) `HOST`/`PORT` env vars load into typed `WebSettings{host, port}`; (3) `PORT=not-a-port` errors and the message contains `port`. Observed error Display: `invalid type: string "not-a-port", expected an integer for key 'port' in the environment`. `cargo tree` confirms the trimmed tree is `config → pathdiff, serde_core, winnow` only. The trailing-underscore failure mode was reproduced first (`missing configuration field "host"`) and then fixed — the fix is the recommended pattern.
- `/tmp/r77envy` (`envy 0.4.2` + `serde 1.0.229`): `cargo test -- --test-threads=1` → 1 passed, 0 failed: `envy::prefixed("RS_LAUNCH_BLUEPRINT_WEB_").from_env::<WebSettings>()` round-trips (note: `envy` *does* take the trailing underscore — opposite convention from `config`). This same run is the macOS-build evidence for gate 4.
- Endpoint probes (executed, all 2026-09-25): crates.io crate/version/dependencies/reverse-dependencies payloads, GitHub repo + issue-search payloads, RustSec pages with `ansi_term` control, upstream CI manifests, static.crates.io tarball inspection (`unsafe` grep, API line citations).

Planned for synthesis/empirical audit (not executed here — framework choice is R69's): an axum (or R69-picked framework) integration test that boots the web binary with prefixed env vars, asserts a handler observes the injected settings via `State`, asserts nonzero exit plus the R67-mapped error on a malformed var, and asserts an unprefixed decoy var is ignored. Suggested commands: `cargo test -p <web-crate> settings` and `RS_LAUNCH_BLUEPRINT_WEB_PORT=bad cargo run -p <web-crate> ; echo $?` expecting fail-fast output naming `port`.

### Confidence & re-verify trigger

Confidence: high for the `config`-with-trimmed-features recommendation on the stated fixed parameters — adoption lead is decisive (18.9M recent downloads, 1579 reverse dependents), maintenance is current to the week, every fitness gate passed on primary evidence, and the exact recommended pattern (prefix derivation, typed load, error naming) was executed green on current stable. Medium residual on two points honestly recorded as gaps: (a) `config-rs` issue-responsiveness could not be attributed via GitHub `author_association` (0/10 maintainer-associated comments in the window despite 5/10 closed — triage channel unclear); (b) `envy` responsiveness is partially rate-limited/unverified.

Re-verify on: `config` 0.16 or 1.0 release (re-check builder/env API and `rust-version`); any new RustSec advisory for `config`/`figment`/`envy`; R69 framework selection requiring profile-based configuration (revisit `figment`); R53 CLI-crate decision if it changes the reuse calculus toward `envy`; or 2027-03-25 (six months) if none of the above fires first.

### Sources

Retrieval date for every URL below: 2026-09-25 (single research pass; GitHub issue-detail queries retried once, then rate-limited and recorded as gaps per instructions).

- `GET https://crates.io/api/v1/crates/config` → recent_downloads 18868961, downloads 115883048, repository `https://github.com/rust-cli/config-rs`
- `GET https://crates.io/api/v1/crates/config/versions` → 0.15.26 @ 2026-09-21T13:08:27Z, rust_version 1.88.0, license `MIT OR Apache-2.0`
- `GET https://crates.io/api/v1/crates/figment` → 10545366 / 39686900, `https://github.com/SergioBenitez/Figment`
- `GET https://crates.io/api/v1/crates/figment/versions` → 0.10.19 @ 2024-05-17T02:54:57Z, rust_version null, `MIT OR Apache-2.0`
- `GET https://crates.io/api/v1/crates/envy` → 3627334 / 21157795, `https://github.com/softprops/envy`
- `GET https://crates.io/api/v1/crates/envy/versions` → 0.4.2 @ 2021-01-04T00:17:01Z, rust_version null, `MIT`
- `GET https://crates.io/api/v1/crates/dotenvy` → 47728423 / 171625531, 0.15.7 @ 2023-03-22, `MIT`
- `GET https://crates.io/api/v1/crates/envconfig` → 1520901 / 10164682, 0.11.1 @ 2025-12-10, `MIT`
- `GET https://crates.io/api/v1/crates/confique` → 166282 / 505539, 0.4.0 @ 2025-10-27, rust_version 1.68.2, `MIT OR Apache-2.0`
- `GET https://crates.io/api/v1/crates/twelf` → 37391 / 353282, 0.15.0 @ 2024-03-11
- `GET https://api.github.com/repos/rust-cli/config-rs` → stars 3213, archived false, pushed 2026-09-25T01:17:15Z
- `GET https://api.github.com/repos/SergioBenitez/Figment` → stars 913, archived false, pushed 2024-09-13T04:51:49Z
- `GET https://api.github.com/repos/softprops/envy` → stars 981, archived false, pushed 2024-06-07T23:13:52Z
- `GET https://api.github.com/repos/allan2/dotenvy` → stars 1252, archived false, pushed 2026-08-18T01:50:26Z
- `GET https://api.github.com/repos/greyblake/envconfig-rs` → stars 232, archived false, pushed 2025-12-10T06:58:16Z
- `GET https://api.github.com/repos/LukasKalbertodt/confique` → stars 223, archived false, pushed 2025-10-27T13:27:11Z
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` → open totals: config-rs 110, Figment 21, envy 14, dotenvy 33, envconfig-rs 6, confique 19
- Issue windows (`.../search/issues?q=repo:<o>/<r>+is:issue+sort:created-desc`, comments via `.../repos/<o>/<r>/issues/<n>/comments`): config-rs #768/747/720/719/717/711/707/705/704/698; Figment #152/148/147/143/142/141/139/138/137/132; envy #82/76/75/74/67/66/65/62/61/60
- `https://rustsec.org/packages/{config,figment,envy,dotenvy,envconfig,confique}.html` → HTTP 404 (no advisories); control `https://rustsec.org/packages/ansi_term.html` → RUSTSEC-2021-0139 present
- `https://crates.io/api/v1/crates/{config,figment,envy}/reverse_dependencies` → totals 1579 / 517 / 192 with named dependents as cited
- `https://crates.io/api/v1/crates/twelf/0.15.0/dependencies` → `envy ^0.4.1` normal edge; `https://crates.io/api/v1/crates/leptos_config/0.8.5/dependencies` → `config ^0.15.13` normal edge
- `https://raw.githubusercontent.com/nextest-rs/nextest/main/nextest-runner/Cargo.toml` (line 29: `config.workspace = true`); `https://raw.githubusercontent.com/rwf2/Rocket/master/core/lib/Cargo.toml` (line 64: `figment 0.10.17`, features `toml, env`)
- `https://raw.githubusercontent.com/rust-cli/config-rs/main/Cargo.toml` (workspace: edition 2024, rust-version 1.88.0, license; features incl. heavy defaults + `async`; deps); `https://raw.githubusercontent.com/SergioBenitez/Figment/master/Cargo.toml` (edition 2018, default `["env"]` no-op); `https://raw.githubusercontent.com/softprops/envy/master/Cargo.toml` (edition 2021, MIT, serde-only)
- `https://raw.githubusercontent.com/rust-cli/config-rs/main/.github/workflows/ci.yml` (os matrix ubuntu/windows/macos); `https://raw.githubusercontent.com/SergioBenitez/Figment/master/.github/workflows/ci.yml` (Linux/Windows/macOS matrix); `https://raw.githubusercontent.com/softprops/envy/master/.github/workflows/main.yml` (ubuntu-only)
- `https://static.crates.io/crates/{config/0.15.26,figment/0.10.19,envy/0.4.2}/download` tarballs: `Environment::with_prefix` (`src/env.rs:113`), `prefix_separator` (`:140`), `separator` (`:151`), `ConfigError` (`src/error.rs:43`), `envy::prefixed` (`src/lib.rs:364`), `envy::Error` (`src/error.rs:8`), `Env::prefixed` (`src/providers/env.rs:198`), figment `Error` (`src/error.rs:89`); zero `unsafe` in all three `src/` trees
- `https://docs.rs/axum/latest/axum/extract/struct.State.html` and `https://docs.rs/actix-web/latest/actix_web/web/struct.Data.html` (HTTP 200, expected titles); `https://doc.rust-lang.org/std/env/` (first-party baseline); `https://docs.rs/config`, `https://docs.rs/figment`, `https://docs.rs/envy` (maintainer reference docs)
- Local execution: `rustc 1.98.1 (2026-09-01)` / `cargo 1.98.1`, Darwin 25.4.0 arm64; probes `/tmp/r77probe` (3/3 pass) and `/tmp/r77envy` (1/1 pass); config-rs PR #769 "Update Rust Stable to v1.98" (2026-08-20) as stable marker
