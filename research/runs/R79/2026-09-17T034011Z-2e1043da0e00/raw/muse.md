# R79 raw answer (Muse engine) — Prometheus metrics crate

Item: R79 (Prometheus metrics, kind `crate`). Retrieval date for all live figures: 2026-09-25.

### Landscape

Category decided: RED (rate, errors, duration) request instrumentation plus Prometheus exposition for the template web service, on by default at `/metrics`.

Three-bin map of the Rust field (every shortlisted candidate comes from this map):

- Built-in or first-party toolchain: no std/tokio/axum built-in Prometheus exposition exists. The closest first-party pieces are `tokio-metrics` (Tokio runtime metrics only, not request RED; re-exported through the `metrics` facade by its users) and framework route handlers that can serve a rendered scrape body. No candidate is selected from this bin because none provides request RED + exposition alone.
- Established industry standard: `metrics` facade + `metrics-exporter-prometheus` (metrics-rs org); `prometheus` client (tikv/rust-prometheus, port of the Go client); `opentelemetry-prometheus` (OpenTelemetry Rust SIG exporter for OTel metrics pipelines).
- Up-and-comer: `axum-prometheus` (Axum-specific RED middleware built on the `metrics` facade); `autometrics` (SLO/objectives-focused macros over `metrics`, OTel, or Prometheus backends).

Authoritative sources used and why each counts:

- Maintainers' own documentation: metrics-rs crate docs (`metrics` facade: "single metrics API that abstracts over the actual metrics implementation"; exporter docs on Prometheus data-model/exposition compliance and `install_recorder` + `render` usage), `prometheus` crate README (states the Go-client port lineage), all retrieved 2026-09-25 from the published 0.24.6 / 0.18.3 / 0.14.0 sources.
- Published crate sources themselves (crates.io download endpoint, versions above): verified the `FilterMode::Ignore`-by-default-with-empty-router behavior, `PrometheusBuilder::install_recorder`, and `PrometheusHandle::render` signatures by reading the code, retrieved 2026-09-25.
- crates.io API (`GET /api/v1/crates/<name>`, `/versions`, `/reverse_dependencies`) for downloads, releases, licenses, rust-version, and adopter evidence, retrieved 2026-09-25.
- Prometheus exposition-format and data-model specifications (referenced by the exporter's own compliance notes) as the wire standard; OpenTelemetry metrics specification as the sibling-tracing context for R78 coherence.
- Practice evidence below from reverse-dependency download counts, not familiarity.

Well-regarded projects surveyed (adoption + why each is a relevant reference):

- `hickory-resolver` / `hickory-server` (81.0M / 4.4M dependent downloads) build on `metrics`: Hickory DNS is the standard pure-Rust DNS implementation, a relevant always-on-service reference.
- `tokio-metrics` (49.9M) composes with `metrics-exporter-prometheus`: the Tokio team's own runtime-metrics crate, a relevant async-service reference.
- `pingora` / `pingora-proxy` (9.3M / 9.5M, Cloudflare) and `poem` (5.8M) build on `prometheus`: production edge-proxy and web-framework references for the client-crate path.
- TiKV owns `tikv/rust-prometheus`: the crate exists to serve TiKV's own Prometheus monitoring, first-party production evidence.
- `axum-prometheus` (5.8M downloads, 30 reverse-dependency crates including `bgpkit-broker`) is the established Axum-middleware-shaped consumer of the `metrics` stack, relevant only if R69 selects Axum.
- OpenTelemetry Rust (`opentelemetry-prometheus` 0.33.0 released 2026-09-18) is the CNCF-governed metrics pipeline that R78 owns for traces; surveyed for coherence, not selected for the default-on path (see Principles).

### Principles and implementation

Shared requirement (source: py precedent `src/py_launch_blueprint/web/telemetry.py:48`, owner clarification 2026-09-04, F326): the web service exposes Prometheus RED metrics at `/metrics`, on by default with no env gate, excluded from its own measurements and from the generated OpenAPI schema.

Agreement levels, separated per the research mandate:

- Capability (must agree across py/ts/rs): every served request is measured for rate, errors, and duration with bounded-cardinality labels (route template or grouped path, never raw unbounded path; method; status class). This is the RED principle; ts has no web service (F303) so it inherits the principle only if it ever gains one.
- Standard (must agree): Prometheus text exposition format at `GET /metrics` (OpenMetrics-compatible output accepted). Scrape compatibility is the cross-ecosystem contract; dashboards and alerts port across repos.
- Architectural pattern (shared): collect in request middleware (or equivalent layer), expose via a dedicated route. Verified appropriate in Rust: tower/axum layers plus a `render()`-backed route is the mainstream shape (see adopters above).
- May vary (justified ecosystem differences): metric names (`http_requests_total` style in Rust vs `prometheus-fastapi-instrumentator` defaults in py), histogram bucket sets, and the crate that implements collection. No shared low-level value is recommended beyond the exposition standard: py's instrumentator defaults are not an owner requirement, and Rust's facade convention (`metrics`) vs a client registry is an ecosystem packaging difference that preserves the principle.

Architectural alternatives compared before choosing libraries:

1. Framework-specific instrumentator middleware (`axum-prometheus` / `actix-web-prom` / poem middleware): closest analog to `prometheus-fastapi-instrumentator` (RED out of the box). Rejected as the primary pick because R69 has not selected a framework; `axum-prometheus` pins `axum 0.8` and is single-maintainer (92 stars). It remains the ranked runner-up conditioned on R69 selecting Axum.
2. Framework-neutral facade + exporter (`metrics` + `metrics-exporter-prometheus`): the template owns a ~40-line middleware and a `render()` route. Selected: works with any R69 outcome, is the most-adopted Rust metrics stack (110.3M / 48.9M all-time downloads), and keeps the hot path decoupled from the exposition choice.
3. OTel metrics with Prometheus export (`opentelemetry-prometheus`): coherent with R78's tracing story but wrong for this item: R78 keeps OTel behind the optional `otel` feature while this item is on by default, so routing default-on RED through the OTel SDK would either force OTel into the default tree or split collection from exposition. Coherence is instead achieved by division: `metrics` handles default-on RED; the `otel` feature adds traces (and may add OTel metrics later) without disturbing `/metrics`.

How the recommended design preserves each principle: unconditional dependency + unconditional route registration preserves on-by-default; template middleware records counter + histogram with matched-route labels and skips the `/metrics` path, preserving self-exclusion; the route is registered outside the OpenAPI-generation path (R71), preserving schema exclusion; `render()` output follows the Prometheus exposition spec, preserving the wire standard.

Cross-repo comparison (py/ts/rs): py keeps `prometheus-fastapi-instrumentator` (native equivalent, no change proposed); ts has no web service so the principle is recorded as not-applicable rather than diverged; rs adopts the facade + exporter pair. No `BASELINE-REVIEW` finding: the inherited on-by-default direction stands, and no F326 change is proposed. Changes to py/ts remain a follow-on project; this answer supplies the rationale above.

Essential behaviors and observable acceptance criteria: `GET /metrics` returns 200 with `text/plain` exposition containing a request counter and duration histogram; successful and failed requests both increment the counter with distinguishing status labels; histogram observations grow with request latency; label cardinality stays bounded under distinct raw paths (route templates, not raw paths); scraping `/metrics` does not create measurements for `/metrics` itself; `/metrics` is absent from the generated OpenAPI document.

### Dominant choice

The `metrics` facade (`metrics` 0.24) composed with `metrics-exporter-prometheus` (0.18) is the dominant established choice for Prometheus exposition in Rust services: 20.9M / 13.5M 90-day downloads, 110.3M / 48.9M all-time, backed by the metrics-rs organization with releases in 2026-04/2026-05, and consumed by `tokio-metrics`, Hickory, `axum-prometheus`, and `autometrics` alike. The `prometheus` client crate has higher raw downloads (25.3M / 148.0M) but is a lower-level client registry, not a request-metrics solution on its own.

### Qualified shortlist

Up to five that passed every gate (fewer is a finding). Figures retrieved 2026-09-25; download endpoints `GET https://crates.io/api/v1/crates/<name>` (`recent_downloads` / `downloads`); stars via repo-page fallback (API rate-limited, see Sources); open issues via `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`).

- `metrics` 0.24.6 · role: framework-neutral metrics facade (counter/gauge/histogram macros + global recorder) · 90-day 20,873,393 · all-time 110,250,193 · stars 1486 (repo metrics-rs/metrics) · last release 0.24.6 on 2026-05-13 · maintenance: active · notable adopters: hickory-resolver, tokio-metrics, metrics-exporter-prometheus, axum-prometheus (reverse-dependency page) · trade-off: facade only, needs an exporter and template-owned middleware.
- `metrics-exporter-prometheus` 0.18.3 · role: Prometheus recorder + exposition (`install_recorder` + `render`, optional http-listener/push-gateway) · 90-day 13,458,086 · all-time 48,874,573 · stars 1486 (same repo) · last release 0.18.3 on 2026-04-30 · maintenance: active · notable adopters: tokio-metrics, axum-prometheus, autometrics, apalis (reverse-dependency page) · trade-off: default features pull tokio+hyper+rustls; template must use `default-features = false` with `render()`.
- `prometheus` 0.14.0 · role: Prometheus client registry (counter/gauge/histogram/summary, Go-client port) · 90-day 25,330,301 · all-time 148,010,748 · stars 1181 (tikv/rust-prometheus) · last release 0.14.0 on 2026-03-27 · maintenance: stable-quiet (last release >6 months before retrieval, investigated: no advisory, still widely consumed, mature API) · notable adopters: pingora, poem, opentelemetry-prometheus, mixtrics (reverse-dependency page) · trade-off: no facade and no request middleware; template hand-rolls registry + middleware + encoding.
- `axum-prometheus` 0.10.1 · role: Axum RED middleware + `PrometheusHandle::render` pairing · 90-day 1,439,447 · all-time 5,793,692 · stars 92 (Ptrskay3/axum-prometheus) · last release 0.10.1 on 2026-07-31 · maintenance: active · notable adopters: bgpkit-broker, sylvia-iot-* services (reverse-dependency page) · trade-off: Axum-only (pins `axum 0.8`), single maintainer, still needs hand-wired `/metrics` exclusion and manual route registration.
- `opentelemetry-prometheus` 0.33.0 · role: Prometheus exporter for the OTel metrics pipeline (R78-coherence path) · 90-day 2,626,994 · all-time 14,481,126 · stars 2717 (open-telemetry/opentelemetry-rust monorepo) · last release 0.33.0 on 2026-09-18 · maintenance: active · notable adopters: OTel Rust users bridging to Prometheus (reverse-dependency of the `prometheus` client) · trade-off: pulls the OTel SDK into the default tree, contradicting the owner-fixed optional `otel` feature.

Fitness gates per shortlisted candidate (answered before popularity was weighed):

1. License: `metrics` MIT; `metrics-exporter-prometheus` MIT AND Apache-2.0; `prometheus` Apache-2.0; `axum-prometheus` MIT; `opentelemetry-prometheus` Apache-2.0 (all from `/versions` endpoint `license` field). All compatible with `MIT OR Apache-2.0`.
2. MSRV: declared `rust-version` 1.71.1 (`metrics`, exporter), 1.75 (`axum-prometheus`), 1.81 (`prometheus`, `opentelemetry-prometheus`); current stable at retrieval is 1.98.1, so "stable minus 2" is satisfied with wide margin and all build on current stable (probe compiled on 1.98.1; dependents such as tokio-metrics/hickory build on current stable).
3. Advisories: 0 open vulnerabilities for all five via OSV `POST https://api.osv.dev/v1/query` (ecosystem crates.io), 2026-09-25; rustsec.org per-package pages are retired (HTTP 404 GitHub Pages shell), recorded as method gap with OSV substitution. `unsafe` posture from published sources: `metrics` 0.24.6 confines `unsafe` to its `Cow` primitive (`src/cow.rs`, pointer casts + `Send`/`Sync` impls); exporter 0.18.3 has one `unsafe` (`evmap::new_assert_stable` in `recorder.rs`); `axum-prometheus` 0.10.1 has zero `unsafe` in `src/`; `prometheus` 0.14.0 has five `unsafe` uses (atomics/FFI-adjacent helpers).
4. OS matrix: `metrics-rs/metrics` CI (`.github/workflows/ci.yml`) and `axum-prometheus` CI (`base.yml`) run on `ubuntu-latest`; tikv/rust-prometheus advertises a CI badge (`rust.yml`). macOS is not in the observed matrices (gap stated, not silently passed): all candidates are pure Rust with no OS-specific dependencies (`metrics` facade has zero mandatory deps; exporter without default features drops tokio/hyper), so `macos-latest` support follows from the dependency tree rather than from vendor CI. Windows noted as supported by the same reasoning, not required.
5. Default features / runtime coupling: `metrics` has no features (no coupling); exporter defaults are `http-listener + push-gateway` (tokio, hyper, rustls) — the template disables defaults and uses `install_recorder` + `render`, leaving only the web service's own runtime; `axum-prometheus` depends on the exporter with `default-features = false` already and on `tokio rt-multi-thread` (inherited from any Axum service); `prometheus` defaults are inert (`gen`, `process`, `push` opt-in); `opentelemetry-prometheus` couples to the OTel SDK.
6. Binary-size/compile-time cost (qualitative): facade + `render()`-only exporter adds a small recorder and no listener threads — the cheapest always-on shape; full-default exporter adds a hyper server + rustls (rejected for the default tree); `prometheus` client is comparable to the render-only shape; `axum-prometheus` adds only matchit/tower-http glue over the same stack; the OTel path is the heaviest (SDK + exporter).

### Excluded by gate

None of the five shortlisted candidates fails a fitness gate. No candidate is listed here; the selection among them is by fit (framework-neutrality, R78 feature split, maintainer breadth), not by gate failure.

### Up-and-comers

- `autometrics` 3.0.0 · SLO/objectives-focused metrics macros over `metrics` 0.24, OTel, or Prometheus backends · 90-day 534,563 · all-time 4,363,757 · stars 833 (autometrics-dev/autometrics-rs) · last release 3.0.0 on 2025-09-18 · maintenance: stable-quiet (last release >6 months before retrieval; no advisory; 3.0 was a major revision) · why not picked: objectives/SLO framing is richer than this item needs, and 3.0's backend-feature matrix adds template complexity for no F326 benefit; worth re-verifying if the template later wants SLO burn-rate alerts out of the box.

### Fit for this template

- CLI: the metrics stack is web-only. The `metrics` facade is harmless to the CLI (zero-cost when no recorder is installed) but the template must not install the Prometheus recorder in CLI binaries; no CLI surface change.
- Library: library code may emit `metrics!` facade calls (decoupled from any backend, per the facade's documented purpose); the exporter dependency and recorder installation live in the web-service binary/example only, never in the library root.
- Web: full fit. Unconditional `metrics` + `metrics-exporter-prometheus` (`default-features = false`) dependencies, a template-owned middleware recording `http_requests_total` (counter, labels: method, status, matched route) and `http_request_duration_seconds` (histogram, same labels), and an unconditional `GET /metrics` route returning `handle.render()`. Works with any R69 framework via its native middleware mechanism; if R69 selects Axum, `axum-prometheus` with `with_ignore_pattern("/metrics")` is an approved drop-in for the middleware half (see Ranked runner-up).

### Recommendation

Adopt `metrics` version `0.24` (req `^0.24`, verified against 0.24.6) plus `metrics-exporter-prometheus` version `0.18` (req `^0.18`, verified against 0.18.3) with `default-features = false`, wired on by default:

- Install once at web-service startup with `PrometheusBuilder::new().install_recorder()` (no `http-listener`, no push gateway, no env gate, no extra ports).
- Serve `GET /metrics` from the framework router with `PrometheusHandle::render()`; register the route outside the OpenAPI-generation path so schema exclusion is structural (requirement on R71's registration design, not an attribute in this item).
- Template-owned middleware records RED per request and skips the `/metrics` path itself (self-exclusion is hand-wired in the template, matching py semantics; neither shortlisted candidate excludes it out of the box — verified: `axum-prometheus` defaults to `FilterMode::Ignore` with an empty router and its own docs show `endpoint="/metrics"` series).
- Use matched-route labels (framework `MatchedPath` equivalent with a grouped-pattern fallback) to bound cardinality; method + status labels distinguish errors (status class `4xx`/`5xx`, not unbounded raw codes, is acceptable and preferred).

This preserves on-by-default, keeps R78's `otel` feature optional and intact, and attaches to any R69 framework.

### Ranked runner-up

`axum-prometheus` 0.10.1 (req `^0.10`), conditioned on R69 selecting Axum: it wins if and only if the framework decision is Axum 0.8 and the template prefers ready-made RED middleware over ~40 lines of owned middleware. Even then the template must still call `.with_ignore_pattern("/metrics")` on `PrometheusMetricLayerBuilder`, register `/metrics` manually with the paired handle's `render()`, and keep the route outside the OpenAPI path. It loses on framework-neutrality (pins `axum 0.8`), single-maintainer depth (92 stars, 10 open issues), and zero reduction in hand-wiring versus the pick.

### Tradeoffs

- Versus `axum-prometheus`: the pick gives up ready-made middleware (counter/pending/histogram wiring, `MatchedPath` labels, body-size histograms) and accepts ~40 lines of template-owned middleware; accepted because the pick works with any R69 framework and the runner-up still requires the same two hand-wiring steps (exclusion + route).
- Versus `prometheus` client: the pick gives up direct control of the Prometheus registry and protobuf exposition; accepted because the facade decouples library instrumentation from the backend and the exporter already implements exposition-format compliance (character sanitization, `_total` conventions).
- Versus `opentelemetry-prometheus`: the pick gives up a single OTel pipeline for metrics+traces; accepted because the owner fixed `otel` as optional while this item is default-on — a default-on OTel dependency would violate that split. Coherence is by division of labor, documented above.
- Versus `autometrics`: the pick gives up SLO/objective macros and function-level instrumentation; accepted as scope beyond F326.

### Parameters

- `assumes rust-edition = 2024` (owner-fixed; probe used edition 2021 only as a scratch default — the recommended crates are edition-agnostic dependencies and declare no conflicting edition; no conflict).
- `assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI` (all picks declare rust-version <= 1.81 against current stable 1.98.1; no conflict).
- `assumes license = MIT OR Apache-2.0` (pick is MIT / MIT AND Apache-2.0; no conflict).
- `assumes target-os-matrix = ubuntu-latest, macos-latest` (pick is pure Rust, vendor CI covers ubuntu-latest; macOS follows from the dependency tree; no conflict).
- No `CONFLICT:` lines. No `owns` parameters for this item (crate selection only; version reqs recorded in Recommendation).

### Migration implications

Template file-level changes (web service / example only; R69 owns framework files):

- `Cargo.toml` (web crate): add `metrics = "0.24"` and `metrics-exporter-prometheus = { version = "0.18", default-features = false }` as unconditional (non-optional) dependencies.
- New middleware module (e.g. `src/web/metrics_middleware.rs`, framework-native per R69): start timer, serve request, record `http_requests_total.increment(1)` and `http_request_duration_seconds.record(elapsed)` with method/status/matched-route labels; early-return without recording when `path == "/metrics"`.
- Router wiring: `let handle = PrometheusBuilder::new().install_recorder()?;` at startup; `GET /metrics` route returning `handle.render()` with `content-type: text/plain; version=0.0.4`, registered outside the R71 OpenAPI-generation path.
- No env vars, no feature flags, no config-file additions for this item. No CLI/library dependency changes beyond optional facade-only `metrics!` calls in library code.

### Validation strategy

Planned checks (full web acceptance; not yet executed — the integrated check runs after R69/R71 land):

1. Start the web example (default features, no env vars): `cargo run -p <web-example>`; assert `GET /metrics` returns 200 `text/plain` containing `http_requests_total` and `http_request_duration_seconds`.
2. Drive one successful and one failing request (e.g. `GET /health` then `GET /nonexistent`); re-scrape `/metrics`; assert the counter has distinct `status` label values for both and both histogram `_count` values increased.
3. Assert duration measurement: histogram `_sum`/`_count` for the driven route are positive and increase monotonically across scrapes.
4. Assert bounded cardinality: request 50 distinct raw paths under one route pattern (e.g. `/items/1..50`); assert the exposition contains the matched template (`/items/{id}` or grouped equivalent), not 50 distinct series.
5. Assert self-exclusion: scrape `/metrics` N times; assert no series carries a `/metrics` route label and counter values for application routes are unaffected by scrapes.
6. Assert OpenAPI exclusion: fetch the generated schema; assert no `/metrics` path entry.

Executed results (this research leg, 2026-09-25, rustc/cargo 1.98.1, macOS):

- Compiled and ran a scratch binary (`/tmp/r79probe`, `metrics = "0.24"`, `metrics-exporter-prometheus = { version = "0.18", default-features = false }`) calling `PrometheusBuilder::new().install_recorder()`, recording one counter increment and one histogram observation, and asserting both series appear in `handle.render()` output. Result: pass (`RENDER-OK bytes=648`). This verifies the core install/record/render API on current stable with default features disabled; it does not verify middleware behavior, label cardinality, or OpenAPI exclusion, which remain planned checks above.

### Confidence & re-verify trigger

Confidence: high in the crate pick (`metrics` 0.24 + `metrics-exporter-prometheus` 0.18, render-only): live-registry figures, published-source verification of the exclusion behavior and `render` API, adopter evidence, and an executed compile-and-render probe all agree. Medium in the middleware label design (matched-path availability depends on R69's framework; the grouped-pattern fallback covers frameworks without it).

Re-verify when: R69 selects the framework (confirm middleware mechanism + `MatchedPath` equivalent, and whether the `axum-prometheus` runner-up condition triggers); R71 defines route registration (confirm structural OpenAPI exclusion); either recommended crate releases a new minor/major (re-check `FilterMode`/builder defaults and feature flags); or quarterly per the repository controller.

Evidence gaps recorded (all public-query failures retried at most twice, then recorded): GitHub `repos` API rate-limited on shared egress IP (`x-ratelimit-remaining: 0`, reset after the research window) — stars/archived taken from repo-page embedded `stargazerCount` JSON plus archive-banner absence, retrieved 2026-09-25; issue-responsiveness medians (10 most recent issues) not collected for the same reason; rustsec.org per-package pages retired (404) — advisories checked via OSV API instead with 0 vulns for all candidates.

### Sources

All URLs retrieved 2026-09-25 unless noted.

- `GET https://crates.io/api/v1/crates/metrics` — `recent_downloads` 20873393, `downloads` 110250193.
- `GET https://crates.io/api/v1/crates/metrics-exporter-prometheus` — `recent_downloads` 13458086, `downloads` 48874573.
- `GET https://crates.io/api/v1/crates/axum-prometheus` — `recent_downloads` 1439447, `downloads` 5793692.
- `GET https://crates.io/api/v1/crates/prometheus` — `recent_downloads` 25330301, `downloads` 148010748.
- `GET https://crates.io/api/v1/crates/opentelemetry-prometheus` — `recent_downloads` 2626994, `downloads` 14481126.
- `GET https://crates.io/api/v1/crates/autometrics` — `recent_downloads` 534563, `downloads` 4363757.
- `GET https://crates.io/api/v1/crates/<name>/versions?per_page=5` — newest non-yanked: metrics 0.24.6 2026-05-13T17:50:59Z (license MIT, rust-version 1.71.1); metrics-exporter-prometheus 0.18.3 2026-04-30T13:36:08Z (license MIT AND Apache-2.0, rust-version 1.71.1); axum-prometheus 0.10.1 2026-07-31T07:08:44Z (license MIT, rust-version 1.75); prometheus 0.14.0 2025-03-27T08:38:33Z (license Apache-2.0, rust-version 1.81); opentelemetry-prometheus 0.33.0 2026-09-18T17:05:48Z (license Apache-2.0, rust-version 1.81.0); autometrics 3.0.0 2025-09-18T14:51:24Z (license MIT OR Apache-2.0, rust-version undeclared).
- `GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open` (`total_count`) — Ptrskay3/axum-prometheus 10; metrics-rs/metrics 51; tikv/rust-prometheus 66; open-telemetry/opentelemetry-rust 216 (monorepo-wide); autometrics-dev/autometrics-rs 14.
- `GET https://api.github.com/repos/<o>/<r>` — rate-limited (`x-ratelimit-remaining: 0` on shared IP 216.218.196.206, verified with response headers); fallback `https://github.com/<o>/<r>` repo pages, embedded `stargazerCount` JSON: Ptrskay3/axum-prometheus 92; metrics-rs/metrics 1486; tikv/rust-prometheus 1181; open-telemetry/opentelemetry-rust 2717; autometrics-dev/autometrics-rs 833; none archived (no archive banner in page HTML).
- `https://rustsec.org/packages/<name>.html` — retired; all six return the GitHub-Pages 404 shell (verified response body). Substituted with `POST https://api.osv.dev/v1/query` (package name + ecosystem crates.io): 0 vulns for axum-prometheus, metrics, metrics-exporter-prometheus, prometheus, opentelemetry-prometheus, autometrics.
- `GET https://crates.io/api/v1/crates/<name>/reverse_dependencies?per_page=100` — revdep crate totals: metrics 1218; metrics-exporter-prometheus 465; axum-prometheus 30; prometheus 922; top dependents cited in Landscape/Principles (hickory-resolver, tokio-metrics, pingora, poem, bgpkit-broker, apalis, mixtrics).
- `GET https://crates.io/api/v1/crates/<name>/<version>/download` — published sources inspected: axum-prometheus 0.10.1 (`src/lib.rs` FilterMode/ignores/`with_ignore_pattern`, builder.rs; `/metrics` measured by default per doc example), metrics 0.24.6 (facade docs, `src/cow.rs` unsafe audit), metrics-exporter-prometheus 0.18.3 (`src/lib.rs` install/render docs, `src/recorder.rs` `PrometheusHandle::render`, `Cargo.toml` features), prometheus 0.14.0 (dependency/unsafe survey).
- `https://raw.githubusercontent.com/metrics-rs/metrics/main/README.md` and `.github/workflows/ci.yml` (runs-on ubuntu-latest); `https://raw.githubusercontent.com/Ptrskay3/axum-prometheus/master/README.md` (CI badge `base.yml`) and `.../master/.github/workflows/base.yml` (runs-on ubuntu-latest); `https://raw.githubusercontent.com/tikv/rust-prometheus/master/README.md` (Go-client-port lineage, CI badge `rust.yml`).
- `rustc 1.98.1 / cargo 1.98.1` local toolchain version output and `https://static.rust-lang.org/dist/channel-rust-stable-date.txt` (2026-09-03) for the MSRV-policy evaluation baseline.
- Executed probe source: `/tmp/r79probe` (scratch, not part of the deliverable).
