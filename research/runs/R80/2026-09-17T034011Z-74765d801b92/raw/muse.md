# R80 health probe endpoints — Muse raw answer (bundle)

Engine: muse (Meta). Retrieval date for all live figures: 2026-09-25.

### Landscape

Category: Kubernetes-style ops probe endpoints (`/healthz` liveness, `/readyz` readiness) plus build-time version stamping and a shared diagnostics core, for a Rust CLI + library + web-service template.

Three-bin map of the Rust field:

- Built-in / first-party toolchain: `std::env!("CARGO_PKG_VERSION")` and other `CARGO_PKG_*` compile-time env vars (no dependency); `rustc --version` via `RUSTC_VERSION` is not built-in — it needs a build script; `std::time::Instant` for uptime (no dependency); plain `async fn` handlers returning framework response types (no probe crate needed).
- Established industry standard: `serde` 1.x response types serialized to JSON (used by every major framework); `built` 0.8 (build script writes a full `built_info` module: version, git sha, rustc version, timestamps); `vergen` 10 (build script emits `cargo:rustc-env` instructions consumed via `env!`); RFC 9457 `application/problem+json` envelope for the 503 (owned by R70, consumed here, not chosen here).
- Up-and-comer: `vergen-gitcl` 10 (gitoxide-based git backend for vergen, avoids shelling to git); framework-specific probe helpers (none found as a maintained standalone health-probe crate — see LOW question below, recorded as a gap with the search performed).

Candidates shortlisted from this map: `built`, `vergen` (+`vergen-gitcl` backend), `serde`, and the no-crate options (`CARGO_PKG_*` env, hand-written core diagnostics module).

Authoritative sources and why each counts: (1) Rust project documentation — `doc.rust-lang.org/cargo/reference/build-scripts.html` and `environment-variables` (normative for build-script outputs and `CARGO_PKG_*` availability); (2) Kubernetes documentation on liveness/readiness probes (normative for the probe semantics this item mirrors); (3) RFC 9457 (normative for the problem envelope `/readyz` reuses); (4) maintainers' own docs — `docs.rs/built`, `docs.rs/vergen`, `serde.rs` (authoritative for API shape and MSRV); (5) crates.io API (authoritative for downloads, releases, licenses, rust-version).

Practice evidence: `serde` is a dependency of effectively the whole web ecosystem (124928 reverse dependencies, `GET https://crates.io/api/v1/crates/serde/reverse_dependencies`, 2026-09-25); `built` has 237 reverse dependencies and `vergen` 203 (same endpoint family, 2026-09-25). Well-regarded standing: `serde` is maintained by dtolnay/erickt (serde-rs org) and is the de-facto serialization standard; `built` (lukaslueg) and `vergen` (rustyhorde/Craxert) are the two long-lived build-info crates, both with releases in 2026 (figures under members). No standalone maintained health-probe crate was found: a crates.io search for health/probe crates surfaces only application-specific or archived helpers, so the survey concludes the idiomatic Rust practice is hand-written handlers plus `serde` types (gap: exhaustive search log not preserved; framework docs of axum/actix/rocket ship no probe extension — R69 owns the framework choice).

Fit framing: py precedent puts diagnostics in `core/diagnostics.py` (`run_diagnostics`) shared by CLI `doctor` and `/readyz`, and reports version/runtime info on `/healthz` (F328/F329). ts has no web service (missing capability, not a design position). The Rust design must reproduce the pattern (shared sync core, cheap liveness, diagnostic readiness with 503 problem doc) with Rust-idiomatic pieces.

### Principles and implementation

Shared requirement (source: owner clarification 2026-09-04, py F328/F329): the template's web service exposes unversioned `GET /healthz` (liveness: version + runtime info, the web analog of `--version`) and `GET /readyz` (readiness: reruns the same diagnostics as the CLI `doctor` command; 503 with an RFC 9457 problem document on failure). Agreement level: architectural pattern + observable endpoint contract (paths, status codes, envelope), not shared code or shared field names. What must agree across py/ts/rs: two distinct probes; liveness is cheap, static, and never fails closed on dependencies; readiness reuses the CLI diagnostics as one source of truth and fails with 503 + problem document. What may vary: exact JSON field names, which build metadata is reported, and the crate used to stamp it.

Essential behaviors and acceptance criteria: (1) `GET /healthz` returns 200 with JSON containing at minimum `version` (semver of the binary) and `rustc_version`, plus `uptime_seconds`, without touching any external dependency; (2) `GET /readyz` calls the same `run_diagnostics` function the CLI `doctor` command calls, returns 200 with per-check results when all pass, and returns 503 with an RFC 9457 problem document (R70 envelope) naming the failed checks when any fail; (3) adding a diagnostic check in the core module changes both CLI and web behavior with no web-side edit.

Architectural alternatives compared: (A) Recommended — synchronous core diagnostics module in the library crate (`core::diagnostics::run_diagnostics() -> DiagnosticsReport`), called directly by the `doctor` CLI command and by the `/readyz` handler (via `tokio::task::spawn_blocking` only if a check blocks; R69 owns the runtime). Liveness reads a `built_info` module generated at compile time plus a process-start `Instant`. (B) Async diagnostics core (`async fn` with framework-agnostic futures) — rejected: it would couple the library core to an executor choice and complicate the sync CLI path for checks that are fast local probes; async boundary stays at the handler. (C) Framework-provided probe extension — rejected: no maintained standalone crate exists (see Landscape gap note), and R69 owns the framework; hand-written handlers attach to any router in ~20 lines. (D) `vergen` env-var stamping instead of `built` — ranked runner-up: equivalent capability, slightly higher integration cost (one `env!` per field, feature-gated emitters) and a higher MSRV floor (rust-version 1.96.0 vs `built` 1.87).

How the design preserves each principle: liveness/readiness split is preserved structurally (two handlers, two contracts); one-source-of-truth is preserved by placing `run_diagnostics` in the lib core behind plain Rust types with no web or CLI dependency (works regardless of the R01 port/adapter seam shape — the seam wraps this core later); unversioned ops paths apply F308 (`/healthz`, `/readyz` with no `/v1` prefix). Cross-ecosystem note (HIGH question): py already realizes the pattern; ts has no web service so there is no ts design to preserve — the justified difference is "missing capability", and ts gains the pattern if it ever builds a service; rs realizes it with `built` + `serde` + a sync core module. No shared low-level value (field names, crate) is forced across ecosystems: the agreement level is pattern + contract. No `BASELINE-REVIEW:` finding: no inherited baseline is challenged; F308 is applied as instructed.

Minimal realistic example: library `src/core/diagnostics.rs` defines `pub struct Check { pub name: String, pub ok: bool, pub detail: String }`, `pub struct DiagnosticsReport { pub checks: Vec<Check> }` with `pub fn passed(&self) -> bool`, and `pub fn run_diagnostics() -> DiagnosticsReport` running two stub checks (config load, storage writable). CLI `doctor` prints the report and exits nonzero on failure. Web `GET /readyz` maps `passed()==true` to 200 JSON and `false` to 503 problem JSON via the R70 envelope. `GET /healthz` returns `HealthzBody { version: built_info::PKG_VERSION, rustc_version: built_info::RUSTC_VERSION, git_sha: Option, uptime_seconds: u64 }` serialized with serde. Proposed acceptance check (planned, not executed in this research leg): `cargo test` on the core module plus an integration test that boots the web app, GETs both endpoints, and asserts 200 on `/healthz` and 200-vs-503 parity between `doctor` and `/readyz` by toggling one stub check.

MEDIUM answers: (1) No new crate is needed for readiness failure beyond R70's envelope + R69's framework + `serde` + the core module — `/readyz` is pure composition. (2) Yes, use `serde`-derived response types for both probes: they compose with the R71 OpenAPI-schema conventions at zero marginal cost since `serde` is already in the tree, and typed bodies are unit-testable; a schema-agnostic string response would save nothing and break schema uniformity. LOW answer: no first-class liveness/readiness crate worth adopting was found (see Landscape).

### Recommendation

One stack: `built` 0.8.1 (build-info stamping) + `serde` 1.0.229 with `derive` (probe response types) + a hand-written synchronous `core::diagnostics` library module shared by CLI `doctor` and `GET /readyz`, with `GET /healthz` returning `built` metadata plus process uptime as JSON and `GET /readyz` returning 200 JSON on success or 503 RFC 9457 problem document (R70 envelope) on failure. `vergen` 10.0.3 is the ranked runner-up for build stamping.

### Members

#### built

##### Landscape

Bin: established industry standard for build-time info stamping. Category peers: `vergen` (established), `CARGO_PKG_*` env vars (built-in), `vergen-gitcl` (up-and-comer backend). `built` generates a complete Rust module (`built_info`) from a one-line `build.rs`, covering package version, git sha, rustc version, timestamps, and target triple.

##### Principles and implementation

Supplies the liveness endpoint's static half: version and runtime/build metadata baked at compile time, readable without I/O at request time. Integrates as a build-dependency plus `include!` of the generated file; the `/healthz` handler reads constants from it and adds runtime uptime from a process-start `Instant`. Maturity: crate age 10+ years, latest release 0.8.1 on 2026-05-21 (`GET https://crates.io/api/v1/crates/built/versions`, 2026-09-25). Dependability: 237 reverse dependencies (same family as above); pure build-time code generation with no runtime failure modes. Performance: zero request-time cost (constants); compile-time cost is one build-script execution (~ms). Integration cost: minimal — 3 lines of `build.rs`, one `include!`.

##### Dominant choice

`built` 0.8.1 is the dominant build-stamping choice for this template: 90-day downloads 19003082, all-time 65076989 (`GET https://crates.io/api/v1/crates/built`, 2026-09-25), roughly 2x `vergen`'s 90-day volume, with a lower MSRV floor (1.87 vs 1.96.0) and a simpler one-call API for the small field set `/healthz` needs.

##### Qualified shortlist

`vergen` 10.0.3 (see Ranked runner-up); `std::env!("CARGO_PKG_VERSION")` alone — qualified only if the template wants zero build dependencies, at the cost of losing rustc version and git sha, which the prompt's HIGH question explicitly asks `/healthz` to report.

##### Excluded by gate

None. (`built` passes all six fitness gates — see Fit for this template.)

##### Up-and-comers

`vergen-gitcl` 10.0.3 (gitoxide-based git backend: 90-day 2990460, total 8099649, `GET https://crates.io/api/v1/crates/vergen-gitcl`, 2026-09-25) — relevant only if the template adopts `vergen` and wants git metadata without a git binary; not needed under `built`, which shells to git optionally and degrades gracefully.

##### Fit for this template

Fitness gates: (1) license MIT (crates.io versions endpoint, 2026-09-25) — compatible with `MIT OR Apache-2.0`; (2) rust-version 1.87, within any plausible stable-minus-2 window for a 2026 template; dependency tree is build-time only; (3) no open RustSec advisory — `https://rustsec.org/packages/built.html` returns 404 (no advisory page), 2026-09-25; `unsafe` posture: none used (pure codegen); (4) build script runs on ubuntu-latest and macos-latest (pure Rust + optional git invocation; no platform-specific code); Windows noted as supported upstream but not required; (5) default features: none required; `dependency-tree` optional; no async-runtime coupling (build-time only); (6) binary-size cost zero (constants only); compile-time cost negligible. Open GitHub issues: 8 (`GET https://api.github.com/search/issues?q=repo:lukaslueg/built+is:issue+is:open`, 2026-09-25). Maintenance state: active (release 2026-05-21). Gaps: stars/archived/pushed_at and issue-responsiveness medians unavailable — GitHub REST `repos` endpoint rate-limited (60/hr quota exhausted, `GET https://api.github.com/rate_limit`, 2026-09-25); retried once, same result; recorded as gap, does not block the recommendation given crates.io evidence.

##### Recommendation

Adopt `built` 0.8.1 as a build-dependency for `/healthz` version/runtime stamping.

##### Ranked runner-up

`vergen` 10.0.3: 90-day 9061345, total 53257922, license `MIT OR Apache-2.0`, rust-version 1.96.0 (crates.io endpoints, 2026-09-25); 4 open issues (GitHub search endpoint, 2026-09-25); no RustSec page (404, 2026-09-25). Loses on higher MSRV floor and higher integration cost for this small field set; wins if the template later wants fine-grained per-field feature flags.

##### Tradeoffs

`built` vs `vergen`: simpler API and lower MSRV vs finer feature control. `built` vs `CARGO_PKG_*` alone: full metadata (rustc, git, target) vs zero build dependency. Chosen tradeoff favors complete `/healthz` metadata at negligible build cost.

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest.

##### Migration implications

Add `built = "0.8"` under `[build-dependencies]` in the binary/web crate; add `build.rs` calling `built::write_built_file()`; add `pub mod built_info` via `include!` in the web or core crate; read `built_info::PKG_VERSION`, `RUSTC_VERSION`, `GIT_COMMIT_HASH_SHORT` in the `/healthz` handler.

##### Validation strategy

Planned (not executed): `cargo build` then assert `GET /healthz` JSON contains the `Cargo.toml` version and a non-empty `rustc_version`; `cargo build` with git metadata absent (tarball) must still compile with `GIT_*` fields `None`. Distinguishes planned from executed: no command was run in this leg.

##### Confidence & re-verify trigger

Confidence: high — crates.io figures are live-dated and the API is stable across 0.8.x. Re-verify if `built` 0.9 changes the generated-module API or if the MSRV window drops below 1.87.

##### Sources

`https://crates.io/api/v1/crates/built` (2026-09-25); `https://crates.io/api/v1/crates/built/versions` (2026-09-25); `https://crates.io/api/v1/crates/built/reverse_dependencies` (2026-09-25, total 237); `https://docs.rs/built` (2026-09-25); `https://github.com/lukaslueg/built` (repo link from crates.io; REST fields rate-limited, gap noted); `https://api.github.com/search/issues?q=repo:lukaslueg/built+is:issue+is:open` (2026-09-25, total_count 8); `https://rustsec.org/packages/built.html` (2026-09-25, 404 = no advisory page); `https://doc.rust-lang.org/cargo/reference/build-scripts.html` (2026-09-25).

#### shared-diagnostics

##### Landscape

Bin: built-in (hand-written library module; no crate). Category: the shared diagnostics core analogous to py `core/diagnostics.py::run_diagnostics`. Peers considered: async diagnostics core (rejected, see top-level Principles), framework health extensions (none maintained found). This member is a pattern, not a crate: crate figures (downloads, stars, advisories) are inapplicable because no third-party code ships; fitness is judged on the pattern's gate impact instead.

##### Principles and implementation

One source of truth: `core::diagnostics::run_diagnostics() -> DiagnosticsReport` with plain owned types (`Check { name, ok, detail }`), synchronous, depending only on `std` (+`serde` derives for the web rendering). Both the CLI `doctor` command and the `/readyz` handler call it; the handler maps the report to 200 JSON or 503 problem JSON. Works behind any R01 seam shape because the seam wraps this core rather than replacing it. Maturity evidence: mirrors the proven py `run_diagnostics` split (F329) and the universal liveness/readiness split from Kubernetes probe guidance; sync-core-behind-async-handler is standard Rust practice (handlers may `spawn_blocking` if a check ever blocks).

##### Dominant choice

Hand-written sync core module in the library crate — dominant because no maintained crate provides template-shaped diagnostics, and the logic is inherently application-specific (checks differ per template).

##### Qualified shortlist

Async core (`async fn run_diagnostics`) — qualified only if checks become I/O-bound (database ping); today the checks are fast local probes, so sync wins on CLI simplicity.

##### Excluded by gate

None — a hand-written `std`-only module trivially satisfies license, MSRV, advisory, OS, runtime-coupling, and cost gates.

##### Up-and-comers

None applicable — this is template-owned code, not an ecosystem pick.

##### Fit for this template

Fitness gates: (1) license: template-owned, ships under the template's `MIT OR Apache-2.0`; (2) MSRV: `std`-only code, no floor impact; (3) advisories: inapplicable (no dependency); `unsafe`: none; (4) OS: portable `std`, runs on ubuntu-latest and macos-latest; (5) features/runtime: none; sync, executor-agnostic; (6) cost: zero binary/compile impact beyond a few functions. Crate-figure fields (downloads, stars, issues, adopters) are inapplicable with reason stated here per tier guidance.

##### Recommendation

Implement `core::diagnostics` as a sync `std`(+`serde` derive)-only module in the library crate; call it from both `doctor` and `/readyz`.

##### Ranked runner-up

Async diagnostics core — adopt only if a future check requires async I/O; migration is a contained signature change plus `spawn_blocking` removal.

##### Tradeoffs

Sync core vs async core: CLI simplicity and executor independence vs direct async I/O in checks. Sync core vs crate: full control and zero dependency vs writing ~60 lines of template code.

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest.

##### Migration implications

New file `src/core/diagnostics.rs` (`Check`, `DiagnosticsReport`, `run_diagnostics`, unit tests); CLI `doctor` command calls it and maps failure to nonzero exit; web `/readyz` handler calls it and maps failure to 503 via the R70 envelope.

##### Validation strategy

Planned (not executed): unit tests assert each stub check's pass/fail; an integration test toggles one check and asserts `doctor` exit code and `/readyz` status (200 vs 503) agree in both states. No command was run in this leg.

##### Confidence & re-verify trigger

Confidence: high — the pattern is proven in py (F329) and trivially portable. Re-verify if R01's seam decision forces diagnostics behind an async trait, which would flip the sync/async choice.

##### Sources

Py precedent `src/py_launch_blueprint/web/app.py:184` and `core/diagnostics.py` (prompt-stated, not re-fetched); `https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/` (probe semantics, 2026-09-25). No registry endpoints apply to template-owned code.

#### serde-response-types

##### Landscape

Bin: established industry standard — the de-facto Rust serialization framework. Category peers for probe bodies: hand-written JSON strings (built-in, rejected: untestable, schema-inconsistent), `serde_json::json!` macro values (established, rejected for top-level bodies: untyped). `serde` with `derive` gives typed `HealthzBody`/`ReadyzBody` structs shared by handlers, tests, and R71 OpenAPI schemas.

##### Principles and implementation

Typed probe bodies preserve schema uniformity (R71 conventions) at zero marginal cost: `serde` is already in every candidate web tree. `HealthzBody { version: String, rustc_version: String, git_sha: Option<String>, uptime_seconds: u64 }` and the `/readyz` success body derive `Serialize`; deserialization derives support round-trip tests. Maturity: 1.x stable since 2017-era, latest 1.0.229 on 2026-07-18 (crates.io versions endpoint, 2026-09-25). Dependability: 124928 reverse dependencies (reverse_dependencies endpoint, 2026-09-25) — the most depended-upon crate in the ecosystem. Performance: serialization of a 4-field struct is sub-microsecond; irrelevant at probe traffic. Integration cost: zero — already required by any JSON web service.

##### Dominant choice

`serde` 1.0.229 with `derive` is the uncontested dominant choice: 90-day downloads 324724704, all-time 1439926984 (`GET https://crates.io/api/v1/crates/serde`, 2026-09-25). No alternative is credible for typed JSON bodies.

##### Qualified shortlist

None — `serde_json::json!` is acceptable for ad-hoc test fixtures but not for the served bodies, so it is not shortlisted as the body strategy.

##### Excluded by gate

None. Hand-written string bodies are excluded by design quality (untestable, schema-inconsistent), not by a fitness gate.

##### Up-and-comers

None — `serde` 1.x is stable-quiet by design; no successor is relevant to this template.

##### Fit for this template

Fitness gates: (1) license `MIT OR Apache-2.0` (crates.io versions endpoint, 2026-09-25); (2) rust-version 1.56, far inside the MSRV window; (3) no open RustSec advisory — `https://rustsec.org/packages/serde.html` returns 404 (no advisory page), 2026-09-25; `unsafe` posture: `serde` core uses no unsafe in the derive path relevant here (stated qualitatively; full audit out of scope); (4) tested on ubuntu-latest and macos-latest (serde CI matrix; Windows also supported); (5) default features `std`; `derive` enabled explicitly; no async-runtime coupling; (6) binary/compile cost negligible relative to any web framework already in the tree. Open issues: 319 (GitHub search endpoint, 2026-09-25) — normal volume for a crate of this scale, not a risk signal. Maintenance state: stable-quiet (maintained, intentionally slow-moving). Gaps: stars/archived/pushed_at and issue-responsiveness unavailable — GitHub REST `repos` endpoint rate-limited (quota exhausted, 2026-09-25); retried once; gap recorded, non-blocking.

##### Recommendation

Derive `serde` `Serialize` (and `Deserialize` for tests) on the `/healthz` and `/readyz` response types; depend on `serde` 1.0.229 with `derive` and `serde_json` for rendering.

##### Ranked runner-up

None credible; the fallback is untyped `serde_json::Value` bodies, which sacrifice compile-time shape checks for no benefit.

##### Tradeoffs

Typed structs vs untyped JSON: compile-time shape safety and OpenAPI reuse vs marginally less code. The tradeoff favors types unanimously at this scale.

##### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest.

##### Migration implications

Add `serde = { version = "1", features = ["derive"] }` and `serde_json = "1"` to the web/lib crates if not already present (R69/R71 almost certainly add them); define `HealthzBody`/`ReadyzBody` in the web or core crate.

##### Validation strategy

Planned (not executed): round-trip serialization unit tests plus an integration assertion that `GET /healthz` returns `Content-Type: application/json` with the expected fields. No command was run in this leg.

##### Confidence & re-verify trigger

Confidence: high — `serde` 1.x API stability is a settled ecosystem fact. Re-verify only on a `serde` 2.0 release, which has no announced date.

##### Sources

`https://crates.io/api/v1/crates/serde` (2026-09-25); `https://crates.io/api/v1/crates/serde/versions` (2026-09-25); `https://crates.io/api/v1/crates/serde/reverse_dependencies` (2026-09-25, total 124928); `https://serde.rs` (2026-09-25); `https://api.github.com/search/issues?q=repo:serde-rs/serde+is:issue+is:open` (2026-09-25, total_count 319); `https://rustsec.org/packages/serde.html` (2026-09-25, 404 = no advisory page).

### Compatibility

Proof the members compose: all three meet in the two probe handlers with no version coupling between them. `built` is build-time only (emits constants; no runtime API surface to conflict with `serde`). `serde` derives apply to the response structs regardless of where field values originate (`built_info` constants, `Instant`-derived uptime, diagnostics report). The shared-diagnostics module depends only on `std` + `serde` derives, so it compiles inside any R69 framework choice and any R01 seam shape. Shared-adopter evidence: `built` + `serde` co-occur across the ecosystem (237 and 124928 reverse-dependency totals from the crates.io reverse_dependencies endpoints, 2026-09-25); a single named co-adopter `Cargo.toml` was not fetched in this one-pass leg — recorded as a minor gap, mitigated by the absence of any shared API surface (build-time constants + serialization derives cannot conflict). No version matrix is needed beyond `built 0.8.1` + `serde 1.0.229`, which share no dependency.

### Parameters

assumes rust-edition = 2024; assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI; assumes license = MIT OR Apache-2.0; assumes target-os-matrix = ubuntu-latest, macos-latest. No owned parameters. No `CONFLICT:` lines — the recommendation fits all consumed values.

### Migration implications

Template file changes: (1) `Cargo.toml`: add `[build-dependencies] built = "0.8"` and ensure `serde`/`serde_json` are present; (2) new `build.rs` calling `built::write_built_file()`; (3) new `src/core/diagnostics.rs` with `Check`/`DiagnosticsReport`/`run_diagnostics` + unit tests; (4) CLI `doctor` command mapping the report to human output + exit code; (5) web routes `GET /healthz` (200 JSON `HealthzBody`, unversioned per F308) and `GET /readyz` (200 JSON on pass, 503 R70 problem document on fail), attachable to any R69 router; (6) process-start `Instant` captured in `main` and shared with the `/healthz` handler for `uptime_seconds`. R51 probes `/healthz` for its container `HEALTHCHECK`; R75 excludes both paths from access logs; R70 supplies the 503 envelope.

### Validation strategy

Commands proving the principle in a realistic example (all planned, none executed in this research leg — stated explicitly per RUNBOOK honesty rules): (1) `cargo test -p rs-launch-blueprint-core diagnostics` — unit tests for pass/fail of each check; (2) `cargo run -- doctor` with a failing stub check — expect nonzero exit and the failed check named; (3) boot the web service and run `curl -s -o /dev/null -w "%{http_code}" localhost:PORT/healthz` — expect 200 with JSON containing `version` equal to the `Cargo.toml` version; (4) same against `/readyz` with the stub check failing — expect 503 with `Content-Type: application/problem+json`; flip the stub to passing — expect 200; (5) parity assertion: `doctor` exit code and `/readyz` status agree in both states, proving one source of truth. Expected behavior: liveness never fails closed; readiness mirrors the CLI exactly.

### Confidence & re-verify trigger

Confidence: high for the stack shape (sync shared core + `built` + `serde` types + 503 problem composition); medium for the `built`-over-`vergen` margin, which rests on MSRV floor and API simplicity rather than a decisive capability gap. Re-verify triggers: R01 seam decision forcing async diagnostics (revisit sync core); R69 framework choice introducing a first-class probe extension (revisit hand-written handlers); R70 envelope shape landing (confirm the 503 mapping); `built` 0.9 API change or MSRV window movement.

### Sources

All endpoint + date citations appear inline under each member. Consolidated: `https://crates.io/api/v1/crates/{built,vergen,vergen-gitcl,serde}` and `/versions` and `/reverse_dependencies` (2026-09-25); `https://docs.rs/built`, `https://docs.rs/vergen`, `https://serde.rs` (2026-09-25); `https://api.github.com/search/issues?q=repo:{lukaslueg/built,rustyhorde/vergen,serde-rs/serde}+is:issue+is:open` (2026-09-25); `https://rustsec.org/packages/{built,vergen,serde}.html` (2026-09-25, all 404 = no advisory page); `https://api.github.com/rate_limit` (2026-09-25, quota exhausted — stars/pushed/responsiveness gap); `https://doc.rust-lang.org/cargo/reference/build-scripts.html` (2026-09-25); `https://kubernetes.io/docs/tasks/configure-pod-container/configure-liveness-readiness-startup-probes/` (2026-09-25).
