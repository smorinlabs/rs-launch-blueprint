# R79 — prometheus-metrics — Opus raw research report

Engine: Claude Opus 5. Run: `research/runs/R79/2026-09-17T034011Z-2e1043da0e00/`.
All figures retrieved 2026-09-18 (UTC) unless a different date is stated beside them.
Toolchain used for every executed probe: `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0`, macOS arm64, 14 cores. Current stable is therefore **1.98**, and the
`msrv-policy` floor "stable minus 2 minor versions" is **1.96** — the same floor R69
revision 10 writes ("the next `msrv-policy` floor advance past 1.96").

### Landscape

**The category this item decides.** Not "a metrics library" in the abstract: the decision is
*how an HTTP server records the rate, error count and duration of each request under a
bounded label set, and how that recording is rendered in the Prometheus text exposition
format on a route the service serves itself*. Three separable concerns hide inside it, and
every candidate answers them in a different combination:

1. **Instrumentation API** — what the handler-side code calls to record a value.
2. **Storage and rendering** — what holds the counters/histograms and produces the
   `# HELP`/`# TYPE`/series text a Prometheus server scrapes.
3. **HTTP middleware** — what observes method, route template, status and elapsed time.

**Bin 1 — built-in or first-party toolchain: empty, and that emptiness is documented.**
Neither `std` nor the Rust project ships a metrics facade. Inside the web stack R69 selected,
`axum` 0.8.9 and `tower-http` have **no** metrics layer: the header comment of axum's own
worked example reads "Someday tower-http will hopefully have a metrics middleware, until then
you can track metrics like this"
(`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/prometheus-metrics/src/main.rs`,
retrieved 2026-09-18). What *is* first-party is the **shape** that example endorses: the
framework maintainers' own answer is `metrics` + `metrics-exporter-prometheus` behind
`Router::route_layer`, with `/metrics` served outside the instrumented routes. Its manifest
pins `metrics = { version = "0.23", default-features = false }` and
`metrics-exporter-prometheus = { version = "0.15", default-features = false }`
(`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/prometheus-metrics/Cargo.toml`,
retrieved 2026-09-18) — older majors than today's, but the same two crates and, notably, the
same `default-features = false`.

**Bin 2 — established industry standard (four families).**

- **`metrics` (facade) + `metrics-exporter-prometheus` (recorder/renderer)** — the
  `log`/`tracing`-style split: a zero-dependency-ish facade crate that application and library
  code calls, and a separately chosen recorder that decides storage and output format.
  `metrics` has **1,199** reverse dependencies on crates.io
  (`GET https://crates.io/api/v1/crates/metrics/reverse_dependencies?per_page=30`,
  `meta.total`, retrieved 2026-09-18); the exporter has **460**
  (same endpoint for `metrics-exporter-prometheus`).
- **`prometheus` (tikv/rust-prometheus)** — the long-standing registry-object client, born in
  TiKV; explicit `Registry`, `IntCounterVec`, `HistogramVec` handles, `TextEncoder`.
- **`prometheus-client` (prometheus/client_rust)** — the Prometheus organisation's own Rust
  client, typed labels via derive, OpenMetrics output, no global state.
- **OpenTelemetry metrics** — `opentelemetry` + `opentelemetry_sdk` meters, exported either
  over OTLP or, for scrape, through `opentelemetry-prometheus`.

**Bin 3 — up-and-comers.** `axum-prometheus` (a framework-specific middleware that wraps the
`metrics` facade and gives it an axum-shaped builder); `measured` (a from-scratch,
low-cardinality-by-construction design, still `0.0.x`); `axum-otel-metrics` (axum middleware
emitting OTel metrics with a Prometheus exporter); `autometrics` (attribute-macro
instrumentation — see *Excluded by gate*; its maintainers have retired it).

**Authoritative sources used, and why each counts as authority.**

| Source | Why authoritative | Retrieved |
|---|---|---|
| `https://prometheus.io/docs/practices/naming/` | The Prometheus project defines the exposition format and the naming rules this item must satisfy. It states plainly: "Do not use labels to store dimensions with high cardinality (many different label values), such as user IDs, email addresses, or other unbounded sets of values", and gives `http_request_duration_seconds` as the canonical cross-application name, with base units (seconds, not milliseconds). | 2026-09-18 |
| `https://prometheus.io/docs/practices/instrumentation/` | Same project, the quantified cardinality rule: "try to keep the cardinality of your metrics below 10 … The vast majority of your metrics should have no labels". | 2026-09-18 |
| `https://opentelemetry.io/docs/specs/semconv/http/http-metrics/` (and its `index.md`) | OpenTelemetry semantic conventions are the cross-language standard for HTTP server telemetry, and are the vocabulary R78's traces will carry, so they are the coordination point the prompt asks for. `http.server.request.duration` is marked **Stable**, Histogram, unit `s`; `http.request.method` is Required; `http.response.status_code` and `http.route` are Conditionally Required; `http.route` "MUST be low-cardinality and include all static path segments, with dynamic path segments represented with placeholders" and "MUST NOT be populated when this is not supported by the HTTP server framework". The advised `ExplicitBucketBoundaries` are `[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]`. | 2026-09-18 |
| `tokio-rs/axum` at tag `axum-v0.8.9`, `examples/prometheus-metrics/` | The framework maintainers' own worked answer for the exact framework R69 selected — the strongest available "fit" evidence, not a third-party blog. | 2026-09-18 |
| `metrics-exporter-prometheus` 0.18.3 crate source (`src/lib.rs` "Upkeep and maintenance", `src/exporter/builder.rs`) | The maintainers' own documentation of a contract that silently breaks memory behaviour if ignored (see *Principles*). | 2026-09-18 |
| `open-telemetry/opentelemetry-rust`, `opentelemetry-prometheus` 0.33.0 `README.md` | The OTel Rust SIG's own steer: "For new projects, consider using the `opentelemetry-otlp` crate instead — Prometheus supports native OTLP ingestion." A maintainer telling you not to use their crate for new work is first-class evidence. | 2026-09-18 |
| `prometheus/client_rust` | The Prometheus organisation's own client — authoritative on OpenMetrics semantics even where a fitness gate excludes it here. | 2026-09-18 |

**Evidence gap, stated rather than filled.** I did not retrieve an annual Rust survey question
that enumerates metrics/observability crates; the survey's ecosystem questions I am aware of do
not break the field down at that granularity, and I will not cite a figure I did not fetch.
Adoption evidence below is therefore registry counts plus named projects, not survey shares.

**Practice evidence — well-regarded projects surveyed, with the evidence that they are
well regarded.**

| Project | What it uses | Evidence of adoption and standing |
|---|---|---|
| **reth** (`paradigmxyz/reth`) — Paradigm's Rust Ethereum execution client, one of the most-watched Rust systems projects of the last three years | `metrics = "0.24.0"`, `metrics-exporter-prometheus = { version = "0.18.3", default-features = false }`, `metrics-util = { default-features = false, version = "0.20.3" }`, `metrics-process = "2.1.0"` | Workspace `Cargo.toml` lines 531–535, `https://raw.githubusercontent.com/paradigmxyz/reth/main/Cargo.toml`, retrieved 2026-09-18. It is running **the exact pin and the exact `default-features = false` shape** this report recommends. |
| **Vector** (`vectordotdev/vector`) — Datadog's observability data router; an observability vendor's own production agent | `metrics = "0.24.2"`, `metrics-tracing-context = { version = "0.18.1", default-features = false }`, `metrics-util = { version = "0.20.4", default-features = false, features = ["registry"] }` | Workspace `Cargo.toml` lines 197–199 and 302–303, `https://raw.githubusercontent.com/vectordotdev/vector/master/Cargo.toml`, retrieved 2026-09-18. An observability company choosing this facade for its own agent is strong domain evidence. |
| **Neon** (`neondatabase/neon`) — serverless Postgres | `measured = { version = "0.0.22", features = ["lasso"] }`, `measured-process`, `prometheus = { version = "0.13", default-features = false, features = ["process"] }` | Workspace `Cargo.toml` lines 136–137 and 158, `https://raw.githubusercontent.com/neondatabase/neon/main/Cargo.toml`, retrieved 2026-09-18. This is the one serious production user of `measured` I could verify — and its author works there, which is context the up-and-comer section states rather than hides. |
| **apalis** (background jobs), **rumqttd** (MQTT broker), **metrics-process**, **coerce**, **actix-web-metrics**, **axum-metrics**, **reqwest-metrics** | Depend on `metrics` and/or `metrics-exporter-prometheus` | crates.io reverse-dependency listings for both crates, retrieved 2026-09-18. `apalis` is also the crate the owner's reference architecture names at C8, so the facade is already inside the owner's own stack by transitive dependency. |

**Fit screen applied before any ranking (survey step 4).** This template is CLI + library +
web service, where the web surface is an **optional** Cargo feature (R69), the core library is
**synchronous** (R05 revision 2, handlers via `spawn_blocking`), and the metrics surface is
*on by default within the enabled web surface* (F326). That screen does three things
immediately: it rewards a facade whose no-op cost is zero when no recorder is installed (so the
CLI and the sync core can carry instrumentation calls without dragging in an exporter); it
penalises any design that requires a running async runtime merely to *record* a value; and it
makes "renders to a `String` I can hand to an axum handler" worth more than "spawns its own
HTTP listener", because the service already has a router and must not open a second port.

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

*Requirement (principle).* A service built from this template publishes, with no configuration
step, a scrape-able RED time series for every request it handles, keyed by a **route template**
rather than a request URI, and the endpoint that publishes those series neither measures itself
nor appears in the service's public API contract.

*Source.* Ledger row **F326** (`docs/port/COMMONALITY.md:330`), origin `py-only`, verdict
`DIVERGENT`, item R79. The py evidence is `src/py_launch_blueprint/web/telemetry.py` at the
pinned commit `b08bccfb55d05f15e46a83b52c5660b1881d19f5`:

```python
    Instrumentator(
        excluded_handlers=["/metrics", "/healthz", "/readyz"],
    ).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
```

Two facts the ledger row's one-line summary does not carry, and both matter here. First, the
exclusion set is **three paths, not one** — `/metrics`, `/healthz`, `/readyz` — so R80's probe
routes are inside this item's exclusion story, a coupling I state below rather than decide.
Second, `prometheus-fastapi-instrumentator` ships in py's **`web` extra**, not in a separate
one: `pyproject.toml` at the pin lists `"prometheus-fastapi-instrumentator>=7.0.0"` under
`[project.optional-dependencies] web`, while the heavier OTel dependencies sit in a separate
`otel` extra. ts has no web service at all (F303), so `TS_PORT_DECISIONS.md` has nothing to
say; I confirmed this by grepping `package.json` at the ts pin `cb1cbcb2e88b898e8c081b0abbfabc1630079c00`
for `prom|metric|otel|telemetry|express|fastify` — the only hit is `@inquirer/prompts`, a
substring false positive.

*Agreement level.* **Capability plus policy**, not library and not metric name.
- What must agree across py, ts and rs: the endpoint path `/metrics`; the three RED quantities;
  the on-by-default posture (no environment variable gates collection); exclusion of the
  metrics endpoint from its own measurements; exclusion from the generated OpenAPI schema;
  bounded label cardinality.
- What may justifiably vary per ecosystem: the crate/package; the metric **names** and label
  keys (py's come from `prometheus-fastapi-instrumentator`'s defaults, not from a standard);
  whether a redundant request counter is emitted alongside the duration histogram; and the
  packaging unit the capability travels in (a Python extra, a Cargo feature).

**Observable acceptance criteria** (each one is asserted by the executed check in
*Validation strategy*):

1. A successful request to a templated route produces a duration-histogram series whose
   route label is the **template** (`/v1/projects/{id}`), not the URI.
2. A failing request produces a series carrying its status code (`500`).
3. Buckets, `_sum` and `_count` are present, and `_count` is the rate signal.
4. 51 requests across 50 distinct path parameters produce exactly **one** route label value.
5. Two scrapes of `/metrics` produce **no** series labelled with `/metrics`.
6. A request matching no route produces no route-labelled series at all.

**Architectural alternatives, compared before any library is picked.**

| # | Architecture | How RED is collected | How exposition happens | Verdict for this template |
|---|---|---|---|---|
| A | **Framework middleware crate** (`axum-prometheus`) | A `tower::Layer` the crate owns | The crate hands back a `PrometheusHandle`; you route it | Viable; the ranked runner-up. Buys an in-flight gauge and a pattern-based ignore list; costs a framework-coupled version treadmill and a second `tower-http` major in the graph |
| B | **Framework-neutral facade + recorder + ~40 lines of middleware** (`metrics` + `metrics-exporter-prometheus`) | `axum::middleware::from_fn` in the template's own source | `handle.render()` inside a normal axum handler | **Recommended.** The framework maintainers' own example shape; the template owns the ~40 lines that decide its label set |
| C | **Registry-object client** (`prometheus`, `prometheus-client`) | You build and thread `HistogramVec`/`Family` handles through `AppState` | `TextEncoder`/`encode` into a `String` | Architecturally clean (no global state, typed labels) but pushes a registry into `AppState`, which R01's erased-service composition root then has to carry; and `prometheus-client` fails gate 2 |
| D | **OpenTelemetry metrics pipeline** (`opentelemetry` + `opentelemetry_sdk` + `opentelemetry-prometheus`) | OTel `Meter` instruments | A `prometheus::Registry` bridged out | Rejected on the maintainers' own advice (see below) and because it would make R79 structurally depend on the crate set R69 deliberately nested behind the **optional** `otel` feature |

**Why architecture B, stated as principle rather than preference.** The facade split is the
same architecture the Rust ecosystem already settled on for logging: `log`/`tracing` is a
facade, the subscriber is chosen at the binary. Three consequences fall out that this template
specifically needs. (i) **The core library can be instrumented without paying for an exporter**:
`metrics`' macros compile to a no-op when no recorder is installed, so an instrumentation call
in `rs-launch-blueprint-core` costs nothing in the CLI binary and needs no async runtime —
which is exactly what R05's synchronous core requires. (ii) **The template owns its label
set.** Cardinality is the one failure mode that turns a metrics endpoint into an outage, and
the Prometheus project's own guidance ("keep the cardinality of your metrics below 10") is a
rule about *your* labels; a middleware crate that decides them for you is a crate you must
audit anyway. (iii) **Recorder and exposition are replaceable independently** — swapping
`metrics-exporter-prometheus` for `metrics-exporter-otel` later changes one function, not every
call site.

**Why not D, in the maintainers' words.** `opentelemetry-prometheus` 0.33.0's own `README.md`
says: "For new projects, consider using the `opentelemetry-otlp` crate instead — Prometheus
supports native OTLP ingestion" (crate source retrieved 2026-09-18). It also depends on
`prometheus = { version = "0.14", default-features = false }`, so choosing D means adopting
architecture C transitively. This settles the R78 coordination question in the cleanest
possible way: **R78 exports traces over OTLP behind the optional `otel` feature; R79 exposes
metrics by native Prometheus scrape; the template ships no OTel-metrics-to-Prometheus bridge.**

**Coherence with R78 is bought with vocabulary, not with a shared library.** The prompt is
right that separate library choices do not excuse an incoherent example. The coherence
mechanism I recommend is that R79's metric and label names are the **Prometheus rendering of
the OpenTelemetry HTTP semantic conventions** R78's spans will already carry:
`http_server_request_duration_seconds` with labels `http_request_method`, `http_route`,
`http_response_status_code` — the conventional dotted-to-underscore mapping a Prometheus OTLP
receiver itself performs. A reader correlating a trace with a metric then uses one vocabulary,
and if the template ever switches to OTLP push for metrics, the series names do not move.

*This is a justified ecosystem difference from py, and it is the only one.* py emits
`http_requests_total` and `http_request_duration_seconds` with labels `handler`/`method`/`status`
because those are `prometheus-fastapi-instrumentator`'s defaults, not because a standard chose
them. The principle (RED, bounded cardinality, seconds) is preserved exactly; the names follow
a stable, versioned convention instead of one library's defaults. A follow-on project could
align py by passing `metric_name`/`labels` arguments to the instrumentator.

**Two counts, not three, and why.** `http.server.request.duration` is a histogram, and a
Prometheus histogram already publishes `_count` — which *is* the request counter, at the same
label set. Emitting a separate `http_requests_total` alongside it (as py does) doubles the
series count for no query that cannot be written against `_count`:
`rate(http_server_request_duration_seconds_count[5m])` is the R of RED, and the same expression
filtered on `http_response_status_code=~"5.."` is the E. The template therefore emits **one**
histogram plus **one** unlabelled counter for unmatched requests (below). This is a deliberate
reduction against py, argued on the Prometheus project's own cardinality guidance.

**The exclusion of `/metrics` from its own measurements is structural here, not configured.**
This is the sharpest difference between the two viable candidates, and I verified both
directions in source.

- With the recommended design, `/metrics` is registered on a router that is **merged after**
  `route_layer` has been applied, so the middleware is not in its service stack at all. There
  is no ignore list to keep in sync, and no way to forget it: adding the route inside the
  instrumented group would be a visible code change. My executed check asserts
  `!body.contains("http_route=\"/metrics\"")` after two scrapes and passes.
- `axum-prometheus` does **not** exclude `/metrics` out of the box. Its own crate
  documentation shows the opposite — the sample scrape printed at
  `axum-prometheus-0.10.1/src/lib.rs:73-81` contains
  `axum_http_requests_total{method="GET",endpoint="/metrics",status="200"} 5`. Exclusion is
  available but is an explicit call: `PrometheusMetricLayerBuilder::with_ignore_pattern("/metrics")`
  (`src/builder.rs:89`), or `with_ignore_patterns(&[...])` for the probe paths too. So the
  answer to the prompt's fourth HIGH question is: **neither candidate excludes it "for free"
  in the py sense — the recommended one excludes it by construction, the runner-up excludes it
  by a hand-written pattern list.**

**Bounded cardinality is enforced by `MatchedPath`, and by refusing the fallback.** axum
inserts `MatchedPath` into request extensions when a route matches; `route_layer` middleware
runs after matching, so the extension is present. Semconv says `http.route` "MUST NOT be
populated when this is not supported" — for an unmatched request there *is* no template, and
substituting `req.uri().path()` (which axum's own example does, and which `axum-prometheus`'s
default `EndpointLabel::MatchedPath` also does as a fallback, `src/builder.rs:29`) is precisely
the unbounded-label mistake the Prometheus naming guide warns about: any scanner spraying
random paths mints a new series per path, permanently. The recommended design therefore
records **no route-labelled series** for an unmatched request and increments a separate,
label-free counter `http_server_unmatched_requests_total`, so 404 volume stays visible at
cardinality 1. Executed: 51 requests across 50 distinct ids yielded exactly two `http_route`
values; the unmatched request yielded `http_server_unmatched_requests_total 1` and no route
label.

**The maintenance contract that silently breaks if ignored — upkeep.** The exporter's own
`src/lib.rs` (lines 98–110) states: "when using lower-level builder methods
`PrometheusBuilder::build_recorder` or `PrometheusBuilder::install_recorder`, this upkeep task
is *not* spawned automatically. Users are responsible for keeping a handle to the recorder
(`PrometheusHandle`) and calling the `run_upkeep` method at a regular interval." Upkeep drains
histogram buckets; without it, memory grows with distinct observations. `install()` and
`build()` — which do spawn it — are `#[cfg(any(feature = "http-listener", feature = "push-gateway",
feature = "push-gateway-no-tls-provider"))]` (`src/exporter/builder.rs:443-448`), i.e. exactly
the heavyweight features this template turns off. **`install_recorder()` and `build_recorder()`
are not feature-gated** and are available with `default-features = false` (verified at
`src/exporter/builder.rs:506` and `:605`). Consequence, and it is a real defect in the
otherwise-authoritative reference: **axum's own example calls `install_recorder()` and never
runs upkeep.** The template must spawn the 5-second upkeep ticker next to the server.
`axum-prometheus` gets this right — its `Handle::default()` spawns exactly that loop
(`src/lib.rs:885-891`) — which is a genuine point in the runner-up's favour and the reason the
recommended design copies that loop verbatim rather than copying axum's example verbatim.

**Owner reference architecture (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`) —
row-by-row disposition.** Only the C10 block overlaps this item.

| Reference row / clause | Position | Ground |
|---|---|---|
| C10 Observability detail, §"C10 Observability on GCP": "**Metrics**: start with log-based metrics/Cloud Monitoring; add the `metrics` crate + exporter only when needed" — the *posture* half | **DIFFER** | The reference is written for a Cloud Run deployment where Cloud Monitoring is already present and free. This template ships no deployment target, and F326 is an owner-recorded baseline: metrics on by default, no env gate, at `/metrics`. Log-based metrics also cannot supply a duration **histogram** with bucket boundaries — you get counts and derived rates, not quantiles — so "start with log-based metrics" would fail the D of RED outright. The difference is on sourced ground (F326 plus the histogram requirement), not on preference. |
| Same clause — the *crate family* half: "the `metrics` crate + exporter" | **AGREE** | When the reference does reach for metrics, it names exactly the family this report recommends. Independent agreement, recorded. |
| C10 table row "Logs/traces — tracing + tracing-subscriber (JSON) (+ tracing-stackdriver)" | **HAND-OFF** | R58 (`logging-pipeline-contract`) owns it; unpublished. Not decided here. |
| C10 table row "Error reporting — sentry + sentry-tower" | **HAND-OFF** | Not this item's; no P02 row assigns error reporting to R79. Not decided here. |

Tally: **1 agree, 1 differ, 2 hand-offs.**

**`BASELINE-REVIEW:` findings: none.** The recommended design preserves F326's principle
(`/metrics`, RED, on by default, excluded from its own measurements and from the OpenAPI
schema) without a ledger wording change. The two places a reviewer might expect one are
addressed in place rather than as ledger challenges: the packaging-level reading of "on by
default" is R69's settled value, discussed under *Recommendation*; and the reduction from two
instruments to one histogram is a metric-name-level choice the agreement level explicitly
leaves free to vary.

**Minimal realistic example** — the full composition, as built and executed. `crates/web` under
`--features metrics`:

```rust
// crates/web/src/obs/metrics.rs
const DURATION: &str = "http_server_request_duration_seconds";
const UNMATCHED: &str = "http_server_unmatched_requests_total";
/// OTel semconv ExplicitBucketBoundaries for `http.server.request.duration`.
const BUCKETS: &[f64] = &[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0];

static HANDLE: OnceLock<PrometheusHandle> = OnceLock::new();

pub fn recorder() -> &'static PrometheusHandle {
    HANDLE.get_or_init(|| {
        let handle = PrometheusBuilder::new()
            .set_buckets_for_metric(Matcher::Full(DURATION.to_string()), BUCKETS)
            .expect("bucket list is non-empty")
            .install_recorder()
            .expect("no other global recorder is installed");
        metrics::describe_histogram!(DURATION, metrics::Unit::Seconds, "Duration of HTTP server requests.");
        metrics::describe_counter!(UNMATCHED, "HTTP requests that matched no route template.");
        handle
    })
}

pub async fn run_upkeep(handle: &'static PrometheusHandle) {
    let mut ticker = tokio::time::interval(Duration::from_secs(5));
    loop { ticker.tick().await; handle.run_upkeep(); }
}

async fn track(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().as_str().to_owned();
    let route = req.extensions().get::<MatchedPath>().map(|p| p.as_str().to_owned());
    let response = next.run(req).await;
    let status = response.status().as_u16().to_string();
    if let Some(route) = route {
        metrics::histogram!(DURATION,
            "http_request_method" => method,
            "http_route" => route,
            "http_response_status_code" => status,
        ).record(start.elapsed().as_secs_f64());
    }
    response
}

pub fn count_unmatched() { metrics::counter!(UNMATCHED).increment(1); }

pub fn instrument(business: Router) -> Router {
    let handle = recorder();
    business
        .route_layer(middleware::from_fn(track))
        .merge(Router::new().route("/metrics", get(move || ready(handle.render()))))
}
```

`OnceLock` is not decoration: `metrics::set_global_recorder` succeeds once per process, and
`install_recorder()` returns `Err` on the second call. Building the router in two
`#[tokio::test]` functions in one integration-test binary would panic without it. This is the
test-isolation answer, and it is the reason the recommendation does not copy
`axum-prometheus`'s `Handle::default()`, which calls `.expect("Failed to set global recorder")`
unconditionally.

The verbatim scrape this produced (trimmed to the shape-bearing lines) is in
*Validation strategy*; `# HELP` and `# TYPE` render because of the two `describe_*` calls, and
the exposition is byte-valid Prometheus text format.

### Dominant choice

**`metrics` 0.24.x (facade) + `metrics-exporter-prometheus` 0.18.x with
`default-features = false` (recorder and renderer), driven by ~40 lines of
`axum::middleware::from_fn` the template owns.**

It is dominant on four independent axes, each measured rather than asserted.
**Volume:** `metrics` has 20,185,758 downloads in the last 90 days and 108,173,967 all-time;
the exporter 13,007,165 / 47,578,577 (`GET https://crates.io/api/v1/crates/<name>`,
`crate.recent_downloads` / `crate.downloads`, retrieved 2026-09-18) — more 90-day volume than
every other RED-capable candidate except the tikv `prometheus` client, which is a different
architecture and 18 months without a release.
**Reach:** 1,199 and 460 reverse dependencies respectively.
**Standing:** it is what axum's own example uses, what reth pins (at this exact version and
this exact `default-features = false` form), and what Datadog's Vector uses for its own agent.
**Gates:** it is the only family in which *both* crates declare a `rust-version` (1.71.1, 25
minors inside the 1.96 floor), carry no open RustSec advisory, and impose no async runtime on
the recording path.

### Qualified shortlist

All five passed every fitness gate. Figures from `GET https://crates.io/api/v1/crates/<name>`
(`crate.recent_downloads`, `crate.downloads`) and `/versions` (newest `yanked: false`), plus
`GET https://api.github.com/repos/<o>/<r>` and
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`
(`total_count`) — all retrieved 2026-09-18.

| Name | Role | 90-day downloads | All-time | Stars | Last release | Maintenance | Notable adopters | One-line trade-off |
|---|---|---|---|---|---|---|---|---|
| `metrics` 0.24.6 | Instrumentation facade | 20,185,758 | 108,173,967 | 1,486 (`metrics-rs/metrics`, shared monorepo) | 2026-05-13 | **active** — `pushed_at` 2026-09-18T14:54:13Z, 51 open issues, maintainer answering within a day (below) | reth, Vector, apalis, rumqttd | Global-recorder model: one recorder per process, so tests need a `OnceLock` or `with_local_recorder` |
| `metrics-exporter-prometheus` 0.18.3 | Recorder + Prometheus text renderer | 13,007,165 | 47,578,577 | 1,486 (same repo) | 2026-04-30 | **active** (same repo signals) | reth (`default-features = false`), apalis, coerce | Default features pull an entire HTTP/TLS stack you do not want (measured below); upkeep is the caller's job |
| `axum-prometheus` 0.10.1 | axum middleware over the `metrics` facade | 1,388,212 | 5,658,682 | 92 (`Ptrskay3/axum-prometheus`) | 2026-07-31 | **active** — `pushed_at` 2026-07-31T07:07:09Z, 10 open issues, single maintainer | `axum-metrics` and downstream service templates; 460-strong exporter reverse-dep set includes it | Gives you an in-flight gauge, body-size metric and ignore patterns; costs `tower-http` 0.7 in the graph and a per-axum-major upgrade treadmill |
| `prometheus` 0.14.0 | Registry-object client (tikv) | 24,842,546 | 145,764,833 | 1,181 (`tikv/rust-prometheus`) | 2025-03-27 | **stable-quiet** — 18 months since release and `pushed_at` 2025-12-31T07:01:42Z, 66 open issues, but no advisory, no maintainer notice and no broken build, so the rubric forbids `at-risk` | TiKV, Neon (0.13), `opentelemetry-prometheus` 0.33.0 depends on it | Highest raw volume of any candidate, but you thread `HistogramVec` handles through app state and it has the slowest release cadence here |
| `opentelemetry-prometheus` 0.33.0 | OTel-metrics → Prometheus bridge | 2,518,260 | 14,203,757 | 2,708 (`open-telemetry/opentelemetry-rust`, whole-project repo) | 2026-09-18 | **active** — released the day of retrieval, `pushed_at` 2026-09-18T17:44:05Z, 218 open issues across the whole OTel Rust project | OTel users needing scrape instead of OTLP | Passes every gate but its own README steers new projects to `opentelemetry-otlp`; also drags `prometheus` 0.14 in transitively |

**Issue responsiveness (rubric: 10 most recently opened issues; median days to first
maintainer response; unanswered count).** For both repositories the API returned **7** non-pull-request
issues among the 20 most recently created items; I report the 7 rather than pad to 10. First
maintainer reply means the first comment whose `author_association` is `MEMBER` or `OWNER`.

| Repository | Issues (newest first) | Days to first maintainer reply | Median (answered) | Unanswered |
|---|---|---|---|---|
| `metrics-rs/metrics` | #711, #708, #707, #699, #697, #695, #694 (2026-05-13 … 2026-09-17) | 0.75, 0.39, 2.81, —, —, —, 0.22 (all by `tobz`, `MEMBER`) | **0.57 days** | **3 of 7** |
| `Ptrskay3/axum-prometheus` | #94, #92, #89, #85, #83, #81, #76 (2024-12-18 … 2026-08-11) | 0.15, —, 19.2, 10.3, 25.3, —, 0.04 (all by `Ptrskay3`, `OWNER`) | **10.3 days** | **2 of 7** |

Read that as the difference between a funded multi-maintainer project and a good single-maintainer
one: `metrics` answers in hours when it answers, `axum-prometheus` answers in days to weeks, and
both leave roughly a third of issues untouched. Neither figure triggers `at-risk` under the rubric —
that needs a concrete signal, and there is none for either.

### Excluded by gate

Gate 2 is applied under the strict reading settled by the owner on 2026-09-11 and recorded in
`docs/planning/p02/owner-decisions.md` ("a candidate which declares no version is unproven
rather than failed … The ruling is withdrawn"), the same reading R69 revision 10 applied to
`warp`, `viz`, `pavex`, `tide` and `watchexec-cli`: **no declared `rust-version` fails the
gate.** Every declaration below was read from the crate's own published `Cargo.toml`, not from
memory.

| Candidate | Gate failed | Evidence |
|---|---|---|
| `prometheus-client` 0.25.1 (the Prometheus organisation's own Rust client) | **Gate 2** — no `rust-version` declared | `prometheus-client-0.25.1/Cargo.toml.orig` from `https://static.crates.io/crates/prometheus-client/prometheus-client-0.25.1.crate` has no `rust-version` key (`[package]` block read in full); crates.io `/versions` reports `rust_version: null` for 0.25.1, 0.25.0 and 0.24.1. Retrieved 2026-09-18. This is a painful exclusion — 606 stars, released 2026-09-01, `pushed_at` 2026-09-14, Apache-2.0 OR MIT, typed labels, no global state — and it is recorded as a re-verify trigger below. |
| `autometrics` 3.0.0 | **Gate 2** (no `rust-version`; crates.io `/versions` reports `null` for 3.0.0, 2.0.0 and 1.0.1) **and maintenance rubric `dormant`** | The repository README's second line is "## NOTE: Autometrics is no longer actively maintained." (`https://raw.githubusercontent.com/autometrics-dev/autometrics-rs/main/README.md`, retrieved 2026-09-18) — a maintainer's own notice, which the rubric names as sufficient for `dormant`. Last release 2025-09-18, `pushed_at` 2025-09-18T14:52:28Z. |
| `axum-otel-metrics` 0.14.1 | **Gate 2** — no `rust-version` (crates.io `/versions`, `rust_version: null` for 0.14.1, 0.14.0, 0.13.0) | Also the smallest candidate surveyed (40 stars, 1 open issue) and architecturally inside the rejected alternative D. |
| Log-based metrics / Cloud Monitoring (the owner reference's first suggestion) | **Capability**, not a fitness gate — it cannot produce a duration histogram with bucket boundaries, so it cannot satisfy the D of RED | Recorded as the `DIFFER` row in *Principles and implementation*. |

### Up-and-comers

- **`measured` 0.0.25** (`conradludgate/measured`) — 488,311 downloads in 90 days, 2,082,387
  all-time, 41 stars, last release 2026-04-14, `rust-version` 1.88, MIT OR Apache-2.0, 2 open
  issues, `pushed_at` 2026-04-14T09:32:12Z. It is the most interesting *design* in the field:
  label sets are types, so high cardinality is a compile-time conversation rather than a
  runtime surprise, and it is used in production by Neon
  (`measured = { version = "0.0.22", features = ["lasso"] }`). Two reasons it is not
  shortlisted for a **template**: the version is `0.0.25` — a ZeroVer crate offers no semver
  breakage protection at all, which is a poor default for code other people are meant to copy —
  and the one verified production adopter employs the author, so the "independent adoption"
  evidence is thin. Worth re-verifying at its 0.1.0.
- **Native histograms** in `metrics-exporter-prometheus` 0.18.x — the `protobuf` feature and
  `set_native_histogram_for_metric` (`src/exporter/builder.rs:379`) expose Prometheus native
  histograms, which remove the bucket-boundary choice entirely. The template should not enable
  them today (they add `prost`, `prost-build` and a build script, and require a Prometheus
  server with the feature flag on), but this is the direction the bucket constant will
  eventually be deleted in.
- **`metrics-exporter-otel`** (350,981 all-time downloads, in the `metrics` reverse-dep set) —
  the same facade, exported over OTLP. Named here because it is the seam that lets R78 and R79
  converge later without touching a single instrumentation call site.

### Fit for this template

**CLI (`rs-launch-blueprint-cli`, and the `rslbp` binary):** nothing is added. The
recommendation lives entirely behind the `metrics` feature, which requires `web`, which is
off by default; the CLI binary's dependency graph is unchanged. Should the CLI ever want its
own timings, the facade's macros are no-ops with no recorder installed, so the call sites cost
an atomic load and nothing links in — this is the property that makes the facade the right
architecture for a repository that ships three front ends from one workspace.

**Library (`rs-launch-blueprint-core`, synchronous per R05 revision 2):** the recommendation
places **no** metrics dependency in `core`, and does not need to. `metrics::histogram!` is a
plain synchronous call requiring no runtime, so if a later item wants to instrument a use case
it can add `metrics` to `core` without touching R05's sync model or R01's port trait. The one
piece that *does* need the runtime is the upkeep ticker, and it lives in the web front end
beside the server. Nothing in this design asks `core` to hold a registry, which is the specific
cost architecture C would have imposed on R01's composition root.

**Web (`rs-launch-blueprint-web` at `crates/web`, behind `metrics = ["web", ...]`):** the whole
design. Two dependencies, one `route_layer`, one merged route, one spawned ticker, one
integration test. The `/metrics` handler is an ordinary axum handler returning `String`, so it
composes with everything R70–R77 add, and it opens no second port — which matters because
R69's serve binary takes its bind address from a single R77-named environment variable and a
second listener would need a second one.

### Recommendation

**Adopt `metrics` `0.24.6` (range `^0.24.6`) and `metrics-exporter-prometheus` `0.18.3`
(range `^0.18.3`, `default-features = false`), declared in `crates/web/Cargo.toml` as optional
dependencies behind a `metrics` feature, with the RED middleware and the `/metrics` route
written in the template.**

*Version ranges.* `metrics = "0.24.6"` and `metrics-exporter-prometheus = "0.18.3"` — Cargo's
default caret on a `0.x` crate pins the minor, so these read as `>=0.24.6, <0.25.0` and
`>=0.18.3, <0.19.0`. The `.6` and `.3` floors are not cosmetic: the exporter 0.18.3 declares
`metrics = { version = "^0.24.5" }`, and 0.18.3 is the version reth pins.

*Feature graph, spelled out against R69 revision 10's topology.*

```toml
# rs-launch-blueprint/Cargo.toml (root package)
[features]
web     = ["dep:rs-launch-blueprint-web"]
metrics = ["web", "rs-launch-blueprint-web/metrics"]

# crates/web/Cargo.toml
[dependencies]
metrics = { version = "0.24.6", optional = true }
metrics-exporter-prometheus = { version = "0.18.3", optional = true, default-features = false }

[features]
metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]
```

**Executed check, because the shape looks illegal and is not:** a feature named `metrics`
coexisting with an optional dependency named `metrics` compiles, because naming `dep:metrics`
anywhere in `[features]` suppresses the implicit same-named feature. I built exactly that
manifest and ran `cargo check --features metrics` — it compiled cleanly. Without this check the
obvious defensive move would be to rename the feature (`prom-metrics`), diverging from R69's
recorded `metrics = ["web", ...]` for no reason.

**`default-features = false` is the single highest-value line in the recommendation, and the
cost of omitting it is measured.** The exporter's defaults are
`default = ["http-listener", "push-gateway"]` (`Cargo.toml.orig`, 0.18.3), which pull an HTTP
server, an HTTP client, TLS and a crypto provider. Executed `cargo tree -e normal` on two
otherwise identical probe manifests: **37 crates with `default-features = false`, 81 with the
defaults on** — 44 added, including `aws-lc-rs`, `aws-lc-sys`, `rustls`, `rustls-native-certs`,
`rustls-webpki`, `hyper`, `hyper-rustls`, `hyper-util`, `h2`, `tokio-rustls`, `security-framework`
and `ipnet`. `aws-lc-sys` alone is a C/assembly build. None of it is used: the template renders
into its own axum route.

**Metric surface.**

| Series | Type | Labels | Purpose |
|---|---|---|---|
| `http_server_request_duration_seconds` | histogram, buckets `[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]` | `http_request_method`, `http_route`, `http_response_status_code` | All three of RED: `_count` gives rate, the status label gives errors, the buckets give duration |
| `http_server_unmatched_requests_total` | counter | none | 404 volume at cardinality 1, with no route label to explode |

**Wiring, in order.** (1) `recorder()` installs the global recorder once via `OnceLock` and
declares both metrics' `# HELP`/unit. (2) The serve binary spawns `run_upkeep(handle)` next to
`axum::serve(...)`, ticking every 5 s — the interval `axum-prometheus` uses and the exporter's
own `upkeep_timeout` default (`src/exporter/builder.rs:88`). (3) `route_layer` applies the
middleware to matched routes only. (4) `/metrics` is merged **after** that layer and is
therefore outside it. (5) The router's fallback calls `count_unmatched()`.

**Answering the two MEDIUM questions directly.**

*On-by-default posture.* At the **runtime** level the answer is yes, and nothing about the
candidate fights it: no environment variable gates collection, the recorder is installed during
startup unconditionally, and the `/metrics` route is registered unconditionally — matching py's
posture exactly, and deliberately unlike R74's opt-in rate limiting. At the **packaging** level,
R69 revision 10 has already settled the shape as `metrics = ["web", ...]`, a separate feature
nesting on top of `web`. I flag one inaccuracy in the surrounding rationale rather than let a
later reader trip on it: R69's clause says this mirrors "py's `web` plus `otel` extras", which
is exactly right for R78's `otel` but **not** for metrics — py ships
`prometheus-fastapi-instrumentator` *inside* the `web` extra, so a py user installing
`[web]` gets metrics, while an rs user enabling only `--features web` will not. That is a real,
small divergence from the source, and it is **R69's owned value, not mine to re-decide**: this
item designs against it, does not raise a `CONFLICT`, and does not propose
`default = ["metrics"]` on `crates/web` (which would widen R69's `web` feature by the back
door). The consequence P03 must carry is documentation: the README's web quickstart should
show `--features metrics` (or `--all-features`), not `--features web`, so the default example a
reader copies is the instrumented one.

*OpenAPI exclusion.* Automatic, on one stated condition. R71 owns the generation pipeline; every
Rust OpenAPI generator in that space derives the document from annotated handler/route
registrations (a `utoipa`-style `#[utoipa::path]` plus `OpenApiRouter`, or an `aide`-style typed
route method). `/metrics` here is registered with plain `axum::routing::get` on a plain
`Router`, with no annotation and no typed registration, so there is nothing for the generator to
pick up — the py analogue of `include_in_schema=False` is "never in the schema's input set" rather
than "removed from its output". The condition is that R71 must not adopt a generator that
enumerates a live `axum::Router`'s route table; if it does, the route needs an explicit
exclusion and this paragraph must be revisited. That is recorded as a re-verify trigger, and the
requirement handed to R71 is one sentence: **the metrics route must be excludable from the
generated document, and is excluded today by being registered outside the annotated path.**

**Footprint (the LOW question), executed.** Probe: a `crates/web`-shaped package with
`axum 0.8.9` + `tokio 1.53.1` (R69's feature list), `edition = "2024"`, `rust-version = "1.96"`,
`[profile.release] strip = true`, built twice with `cargo clean` between runs on macOS arm64,
14 cores, rustc 1.98.0.

| Figure | Without `metrics` | With `metrics` | Delta |
|---|---|---|---|
| Crates in the normal dependency graph | 51 | 79 | **+28** |
| Stripped release binary | 1,256,896 B | 1,617,952 B | **+361,056 B (+28 %)** |
| Cold `cargo build --release` after `cargo clean` | 16 s (one run measured 23 s) | 24 s (one run measured 21 s) | roughly **+8 s** on a cold target directory, but run-to-run noise on a warm registry cache was of the same order, so I report the crate count and the binary bytes as the robust figures and the compile time as approximate |

For comparison, the runner-up's footprint on the identical base: `axum-prometheus` 0.10.1 adds
**+31 crates** (82 total), the extra edge over the recommended set being `tower-http` 0.7.1,
`bitflags` and the crate itself.

**Gate answers for the recommended pair, stated explicitly.**

| Gate | `metrics` 0.24.6 | `metrics-exporter-prometheus` 0.18.3 |
|---|---|---|
| 1. License compatible with `MIT OR Apache-2.0` | MIT — pass | `MIT AND Apache-2.0` — pass |
| 2. MSRV within stable-minus-2 (floor 1.96) | `rust-version = "1.71.1"` — pass, 25 minors of headroom | `rust-version` inherited from the workspace, published as `1.71.1` on crates.io `/versions` — pass |
| 3. RustSec advisories; `unsafe` posture | `https://rustsec.org/packages/metrics.html` → HTTP 404 (no advisory page exists, i.e. none filed). `unsafe` is present and confined: 34 occurrences, all in `src/cow.rs` (a borrowed-or-owned pointer type with two `unsafe impl Send/Sync`) | `https://rustsec.org/packages/metrics-exporter-prometheus.html` → HTTP 404. Exactly **one** `unsafe` in the crate: `evmap::new_assert_stable()` at `src/recorder.rs:38`. Its dependency `metrics-util` **does** have an advisory page — `RUSTSEC-2021-0113`, `AtomicBucket<T>` unconditionally implements `Send`/`Sync`, **patched `>=0.7.0`**; the resolved version is 0.20.4, unaffected. `cargo audit` (advisory DB of 1,251 advisories, 2026-09-18) over the probe's `Cargo.lock` of 119 crates reported no vulnerabilities |
| 4. Builds on `ubuntu-latest, macos-latest` | Both built and tested on macOS arm64 in this run; both are pure-Rust with no C dependency once `default-features = false` removes `aws-lc-sys` — which is precisely the gate-4 argument for turning the defaults off. Windows: not required; the graph contains only the usual `winapi` target-gated edges | same |
| 5. Default features and async-runtime coupling | `metrics` has **no** features at all (`features: {}` on crates.io) and no runtime coupling | Defaults are `["http-listener", "push-gateway"]` and **are turned off**; with them off the crate has no `tokio` edge. `install_recorder()`/`build_recorder()` are not feature-gated. The only async touch-point in the recommendation is the upkeep ticker the template spawns |
| 6. Binary-size and compile-time cost | measured above: +28 crates, +352 KiB stripped, ≈ +8 s cold | same measurement (the pair was measured together, as it ships together) |

*Resolved-tree MSRV, by R69 revision 10's method.* The probe manifest declaring
`edition = "2024"` and `rust-version = "1.96"` resolved with the MSRV-aware resolver:
`Locking 118 packages to latest Rust 1.96 compatible versions`. The highest `rust-version`
declared anywhere in the resolved non-dev tree, excluding target-gated wasm/Windows crates that
never build on `ubuntu-latest, macos-latest`, is `hashbrown` 0.17.1's **1.85.0** (with
`indexmap` 2.14.2 at 1.85 and `axum` 0.8.9 at 1.80) — 11 minors inside the floor. Twenty
packages in the tree declare no `rust-version` at all (`matchit`, `tower-layer`,
`tower-service`, `sync_wrapper`, `httparse`, `smallvec` and others), which is the same
situation R69 revision 10 accepted for axum's own graph: gate 2's strict "no declaration fails"
reading is applied to **candidates**, while the tree is assessed by the highest declared value
plus a successful MSRV-aware resolution.

### Ranked runner-up

**`axum-prometheus` 0.10.1** — 1,388,212 downloads in 90 days, 5,658,682 all-time, 92 stars,
released 2026-07-31, `rust-version = "1.75"`, MIT, `axum = "0.8"`, no RustSec page (HTTP 404),
zero `unsafe` in its own source, and it declares `metrics-exporter-prometheus = { version = "0.18.3",
optional = true, default-features = false }` — i.e. it independently reached the same
`default-features = false` conclusion.

**It wins under one clearly-stated condition:** if the template decides the RED trio is not
enough and it wants an in-flight gauge (`axum_http_requests_pending`) and response-body-size
histogram out of the box, plus a declarative ignore list that R80's probe paths and `/metrics`
can be added to in one line (`with_ignore_patterns(&["/metrics", "/healthz", "/readyz"])` —
which is, note, the closest thing in the field to py's `excluded_handlers` list). It is also the
right pick if the template would otherwise write and maintain the upkeep loop incorrectly:
`axum-prometheus` spawns it for you (`src/lib.rs:885-891`), which axum's own example does not.

What tips it to second place is a pair of facts the recommended design does not have to carry.
`Handle::default()` calls `metrics::set_global_recorder(recorder).expect("Failed to set global
recorder")`, so a second layer construction in the same test binary **panics** — the template
would have to build the pair once in a `OnceLock` anyway, at which point the crate's
convenience has mostly been re-implemented around it. And it adds `tower-http` 0.7.1 to the
graph, which R75 (`http-middleware-stack`) has not yet chosen a version of; the owner's
reference architecture names `tower-http 0.6` at C11. That is a version-skew risk between two
unpublished items, and this item should not create one.

### Tradeoffs

**Against `axum-prometheus` (runner-up), the recommendation gives up:** (i) the in-flight gauge
and the body-size histogram — accepted, because RED is what F326 requires and every extra
instrument multiplies the series count under the same labels; (ii) the declarative ignore-pattern
list — accepted, and arguably an improvement, because structural exclusion cannot be forgotten
whereas a pattern list can silently fall out of sync when R80 adds a probe path; (iii) the
pre-written upkeep loop — accepted at a cost of six lines, copied from that crate's own
implementation. **What it gains:** three fewer crates, no `tower-http` major pinned by a
third party ahead of R75, no panic-on-second-recorder, no dependency whose release cadence is
tied to axum's majors by a single maintainer, and a label set the template can read in its own
source.

**Against `prometheus` / `prometheus-client` (architecture C), the recommendation gives up:**
typed, compile-time-checked label sets and the absence of process-global state. `prometheus-client`
in particular would have been an attractive pick on design grounds — the Prometheus
organisation's own crate, OpenMetrics output, `Family<Labels, Histogram>` with a derived label
type. **The cost is accepted because** gate 2 excludes it outright (no `rust-version`), and
because threading a `Registry` through `AppState` puts an observability object into the
composition root R01 defines, where today only the erased `ProjectsService` lives. The global
recorder is a real downside — it is why the `OnceLock` exists — but it is confined to one
function in one file.

**Against OpenTelemetry metrics (architecture D), the recommendation gives up:** a single SDK
covering traces and metrics together. **Accepted because** the OTel Rust maintainers themselves
steer new projects away from `opentelemetry-prometheus`, because adopting it would make the
default-on metrics surface depend on the crate set R69 deliberately nested behind the *optional*
`otel` feature (inverting the two features' cost ordering), and because coherence with R78 is
obtainable more cheaply through shared semantic-convention names — which this recommendation
takes.

**Against py's exact metric names, the recommendation gives up** drop-in dashboard portability
between the py and rs templates. **Accepted because** there are no shipped dashboards to break,
the names it adopts are a stable, versioned standard rather than one library's defaults, and
the alternative — copying `prometheus-fastapi-instrumentator`'s label key `handler` into a Rust
service whose value is an axum route template — would encode a Python library's vocabulary in a
Rust template for no benefit. The cost is one paragraph of README and a note for the follow-on
py/ts harmonisation project.

**What everyone gives up, stated plainly:** 352 KiB of binary and 28 crates in the
`--features metrics` build. There is no zero-cost option that produces a Prometheus histogram.

### Parameters

This item owns no shared parameter (`owns:` is empty in the prompt's Couplings), so no
`owns <param> = <value>` line is written. The consumed values below are byte-identical to the
rows in `docs/port/PARAMETERS.md` as it stands on 2026-09-18.

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0
- assumes web-extra-surface = one additive, off-by-default Cargo feature named web, declared on whichever crate hosts the binary targets (R02 decides which); web = ["dep:axum", "dep:tokio"], with axum 0.8.9 optional and its default features on (form, http1, json, matched-path, original-uri, query, tokio, tower-log, tracing) and tokio 1.53.1 optional with features rt-multi-thread, net, signal, macros, time, sync; tower 0.5.3 is a dev-dependency only, for the ServiceExt::oneshot in-process test idiom, and is not gated by the feature; the feature gates exactly four things and nothing else - (1) the library module src/web/ containing AppState, build_router, the per-resource route modules, the handlers, shutdown_signal and serve_until, (2) one additional binary target [[bin]] name = "<app>-serve" with required-features = ["web"], the production entrypoint, which carries the org CLI Design Standard v1.4.14 R4.1 required global core and nothing beyond it - -h/--help and -V/--version printing to stdout and exiting 0, -v/--verbose, -q/--quiet, --config and --debug, parsed with the parser crate R60 selects for the CLI binary, which is a non-optional dependency of the package whichever crate R60 picks, so this feature adds none - while every service knob such as host, port, log format and drain deadline stays an environment variable named by R77, and which exits with the integers R67's accepted taxonomy has already settled: 143 after a SIGTERM-initiated drain, 130 after a SIGINT-initiated drain, 1 on an I/O failure, and 0 otherwise, returned as ExitCode from main rather than by calling process::exit, with the drain-deadline branch deliberately left out of this value pending R67's disposition of the request recorded under the Decision section, (3) the web integration tests, gated file-level with #![cfg(feature = "web")], and (4) every later web layer - R70's error envelope, R71's OpenAPI generation, R72 to R76's middleware, R77's settings, R80's probes - as modules inside that same gated src/web/ tree, so they are on when web is on and absent when it is off; it does not gate the CLI binary, the core library, R01's port and adapter seam, serde, serde_json, or the contributor-installed bacon 3.25.0 dev watcher, which is not a Cargo dependency; heavier opt-ins nest on top rather than widening it, as separate features that require web - otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel extras; consumers select the surface with --features web or --all-features and detect it by that feature name, and path-based skip-gating keys on src/web/**, the serve binary's source file and the web test files

**Registry bytes versus the accepted-unpublished revision.** The `web-extra-surface` line above
is the **published** registry value (R69 revision 9 wording, `src/web/`). R69 **revision 10** is
owner-accepted and not yet published; it moves the web tree to the optional workspace member
`crates/web` (`web = ["dep:rs-launch-blueprint-web"]`, the gated tree reading `crates/web/src/`,
integration tests in `crates/web/tests/` with no file-level `#![cfg(feature = "web")]`,
skip-gating keys on `crates/web/**`), under R02 revision 1's four-package workspace in which
`rs-launch-blueprint-web` depends on `core` only. **Every path in this report's design uses
revision 10's `crates/web` form**, and the `metrics = ["web", ...]` nesting clause is byte-identical
in both revisions, so nothing else in the design moves with it. R69's republication is recorded
as a re-verify trigger. No `CONFLICT:` line is raised by this item: the design needs no consumed
value changed.

**Couplings stated, not fixed.** R80 (`health-probe-endpoints`, in parallel): py excludes
`/healthz` and `/readyz` from measurement alongside `/metrics`, so R80's routes belong on the
**unmeasured** side of `route_layer` — merged after it, exactly like `/metrics`. This report
states the requirement and the mechanism; R80 chooses the paths. R77 (`web-env-settings`, in
parallel): this design needs **no** environment knob (that is the point of F326), but if R77
later wants one for the scrape path or the upkeep interval, the seam is the two constants in
`obs/metrics.rs`. R58 (`logging-pipeline-contract`, unpublished, registry value `—`): the
exporter is used without its `tracing` feature, so it emits no log lines and imposes nothing on
the pipeline. R75 (`http-middleware-stack`): the metrics middleware is an ordinary
`from_fn` layer and takes its place in R75's ordering; R75 also owns excluding `/metrics` from
**access-log** volume (F320), which this item does not touch.

### Migration implications

File-level changes in the template, against R69 revision 10 / R02 revision 1's four-package
workspace. No file outside `crates/web/` and the two manifests changes.

| File | Change |
|---|---|
| `Cargo.toml` (root package `rs-launch-blueprint`) | Add `metrics = ["web", "rs-launch-blueprint-web/metrics"]` to `[features]`. No new dependency on the root package |
| `crates/web/Cargo.toml` | Add `metrics = { version = "0.24.6", optional = true }` and `metrics-exporter-prometheus = { version = "0.18.3", optional = true, default-features = false }`; add `[features] metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]` |
| `crates/web/src/obs/metrics.rs` (new, ~70 lines) | `recorder()`, `run_upkeep()`, `track()`, `count_unmatched()`, `instrument()`, the two metric-name constants and the bucket constant |
| `crates/web/src/obs/mod.rs` (new) or `crates/web/src/lib.rs` | `#[cfg(feature = "metrics")] pub mod obs;` — one gated module declaration |
| `crates/web/src/lib.rs` (`build_router`) | Wrap the business router: `#[cfg(feature = "metrics")] let router = obs::metrics::instrument(router);`. The `metrics`-off build is byte-for-byte what R69 describes |
| `crates/web/src/` router fallback | The 404 fallback handler gains one gated line, `#[cfg(feature = "metrics")] obs::metrics::count_unmatched();` |
| `src/bin/<app>-serve.rs` (the R69 serve binary) | One gated `tokio::spawn(obs::metrics::run_upkeep(handle))` beside `axum::serve(...)`; it needs no shutdown handling — the task dies with the runtime and holds no state that must be flushed |
| `crates/web/tests/metrics.rs` (new) | The acceptance test in *Validation strategy*, gated `#![cfg(feature = "metrics")]` |
| `.github/workflows/ci.yml` (R11 owns the shape) | The web job's feature selector becomes `--features metrics` or `--all-features` so the new code and test are compiled and run; path-based skip-gating already keys on `crates/web/**` |
| `README.md` / web quickstart docs | The web example command becomes `cargo run --features metrics --bin <app>-serve`, because `--features web` alone does **not** enable metrics under R69's nesting |
| `docs/port/COMMONALITY.md` F326 | No wording change proposed; no `BASELINE-REVIEW:` raised |

### Validation strategy

**Executed in this run** (probe package under a `$TMPDIR` subdirectory, since deleted;
`rustc 1.98.0`, macOS arm64; the package declared `edition = "2024"`, `rust-version = "1.96"`,
`axum 0.8.9`, `tokio 1.53.1` with R69's feature list, `metrics 0.24.6`,
`metrics-exporter-prometheus 0.18.3` with `default-features = false`, and `tower 0.5.3` as a
dev-dependency for R69's `ServiceExt::oneshot` idiom):

| # | Command | Result |
|---|---|---|
| E1 | `cargo check --features metrics` on a manifest whose feature `metrics` and optional dependency `metrics` share a name | **Compiled** — `dep:metrics` suppresses the implicit feature; the R69 feature name is legal |
| E2 | `cargo tree -e normal --features metrics` with and without `default-features = false` on the exporter | **37 vs 81 crates**; the 44 added include `aws-lc-rs`, `aws-lc-sys`, `rustls`, `hyper`, `hyper-rustls`, `h2`, `tokio-rustls`, `ipnet` |
| E3 | `cargo build --release` (`strip = true`) with and without the feature, `cargo clean` between | **1,256,896 B → 1,617,952 B**; 51 → 79 crates; ≈ +8 s cold, noisy |
| E4 | `cargo generate-lockfile` under `rust-version = "1.96"` | `Locking 118 packages to latest Rust 1.96 compatible versions`; highest declared non-dev `rust-version` on the CI matrix's platforms is `hashbrown` 1.85.0 |
| E5 | `cargo audit` (1,251 advisories, DB of 2026-09-18) over the resolved lockfile | No vulnerabilities; `RUSTSEC-2021-0113` (`metrics-util`, patched `>=0.7.0`) does not apply to the resolved 0.20.4 |
| E6 | `cargo test --features metrics` — the acceptance test below | **1 passed**; assertions and the printed scrape quoted below |
| E7 | `cargo check` with the feature **off** | Compiled; the metrics module and its dependencies are absent |

**The acceptance check, as it ran.** One `#[tokio::test]` in an integration test, driving the
router in process with `tower::ServiceExt::oneshot` (R69's idiom, so no port is bound and the
test runs identically on both CI runners):

```rust
let app = build_router();
assert_eq!(call(&app, "/v1/projects/7").await.0, StatusCode::OK);                          // success
assert_eq!(call(&app, "/v1/boom").await.0, StatusCode::INTERNAL_SERVER_ERROR);             // failure
assert_eq!(call(&app, "/nope/deep/path").await.0, StatusCode::NOT_FOUND);                  // unmatched
for i in 0..50 { let _ = call(&app, &format!("/v1/projects/{i}")).await; }                 // cardinality
assert_eq!(call(&app, "/metrics").await.0, StatusCode::OK);                                // scrape once
let (status, body) = call(&app, "/metrics").await;                                         // scrape twice
assert_eq!(status, StatusCode::OK);
assert!(body.contains(
  "http_server_request_duration_seconds_count{http_request_method=\"GET\",\
   http_route=\"/v1/projects/{id}\",http_response_status_code=\"200\"} 51"));
assert!(body.contains("http_route=\"/v1/boom\",http_response_status_code=\"500\""));
assert!(body.contains("http_server_request_duration_seconds_bucket"));
assert!(body.contains("http_server_unmatched_requests_total 1"));
assert!(!body.contains("http_route=\"/metrics\""));
assert_eq!(distinct_http_route_values(&body).len(), 2);
```

Printed output: `distinct http_route label values = {"/v1/projects/{id}", "/v1/boom"}`, and the
scrape began:

```text
# HELP http_server_unmatched_requests_total HTTP requests that matched no route template.
# TYPE http_server_unmatched_requests_total counter
http_server_unmatched_requests_total 1

# HELP http_server_request_duration_seconds Duration of HTTP server requests.
# TYPE http_server_request_duration_seconds histogram
http_server_request_duration_seconds_bucket{http_request_method="GET",http_route="/v1/boom",http_response_status_code="500",le="0.005"} 1
...
http_server_request_duration_seconds_count{http_request_method="GET",http_route="/v1/projects/{id}",http_response_status_code="200"} 51
```

Every one of the six acceptance criteria in *Principles and implementation* is asserted there,
and criterion 4 is the interesting one: **50 distinct URIs, one label value.**

**Proposed for P03, not executed here** (each needs template code that does not exist yet):

1. `cargo hack --each-feature check --workspace` — proves `metrics` on and off both compile, and
   that `metrics` cannot be enabled without `web`.
2. `cargo deny --all-features check bans licenses advisories` — the `--all-features` form and its
   ordering are R02's executed finding (`CD5a`–`CD5d`); it must run with all features or the
   optional `crates/web` member, and therefore both metrics crates, are absent from the resolved
   graph entirely.
3. An end-to-end scrape against the real serve binary: start `<app>-serve` with `--features metrics`,
   `curl -sf http://127.0.0.1:$PORT/metrics | promtool check metrics` — this is the only check
   that validates the exposition text against the Prometheus project's own parser rather than
   against `String::contains`, and it belongs in the template's integration lane if `promtool`
   is acceptable as a CI-installed tool (R42 owns provisioning).
4. An OpenAPI-exclusion assertion once R71 publishes: `jq -e '.paths | has("/metrics") | not'`
   over the generated document, wired into R71's snapshot gate rather than duplicated here.
5. A memory-shape check for upkeep: record 10^6 observations across a handful of label sets, run
   the ticker, and assert the process RSS plateaus. This is the only claimed behaviour in the
   recommendation that the in-process acceptance test cannot reach, and it is the one whose
   absence would hurt most in production.

### Confidence & re-verify trigger

**High confidence** on the crate pair, the `default-features = false` requirement, the upkeep
obligation, the structural `/metrics` exclusion, and the cardinality behaviour: each is either
executed in this run (E1–E7) or quoted from the maintainers' own source. **Medium confidence**
on the metric-naming recommendation — semconv alignment is well-argued and standards-backed, but
it is the one place this report departs from py's observable output, and a synthesizer who
values byte-level cross-repo dashboard portability over vocabulary coherence with R78 could
reasonably land on py's `http_requests_total` / `http_request_duration_seconds` instead; the
rest of the design is unchanged either way. **Medium confidence** on the OpenAPI-exclusion
answer, which is conditional on R71's generator shape. Issue-responsiveness medians for both
shortlisted repositories are computed from fetched per-issue comment authorship and dates, not
estimated.

**Re-verify when any of these happens:**

- **R69 republishes** at revision 10 (or later) — confirm the `metrics = ["web", ...]` clause and
  the `crates/web` paths this design is written against survive verbatim.
- **R02 publishes** a topology other than the four-package workspace with `crates/web`.
- **R80 publishes** its probe paths — they must join `/metrics` on the unmeasured side of
  `route_layer`.
- **R71 publishes** a generator that enumerates a live `axum::Router` rather than annotated
  registrations — the automatic OpenAPI exclusion would then need an explicit mechanism.
- **R78 publishes** a decision that emits metrics (not only traces) through the OTel SDK — the
  two items would then need one recorder, not two pipelines.
- **`prometheus-client` declares a `rust-version`** — it would clear gate 2 and deserve a fresh
  head-to-head, on design grounds it currently wins on.
- **`metrics-exporter-prometheus` releases 0.19**, or **`metrics` releases 0.25** — both are
  semver-breaking under caret-on-`0.x`.
- **`axum` publishes 0.9** — `axum-prometheus` would need a new major, and `MatchedPath`/
  `route_layer` semantics must be re-checked.
- **Prometheus native histograms become the default advice**, retiring the bucket constant.
- At the next **`msrv-policy` floor advance past 1.96**, or by **2027-03-18**, whichever is first.

### Sources

Crate registry (all `GET https://crates.io/api/v1/crates/<name>` and `.../versions`, retrieved
2026-09-18): `metrics` (recent 20,185,758; all-time 108,173,967; 0.24.6, 2026-05-13;
`rust_version` 1.71.1; MIT), `metrics-exporter-prometheus` (13,007,165; 47,578,577; 0.18.3,
2026-04-30; 1.71.1; MIT AND Apache-2.0), `axum-prometheus` (1,388,212; 5,658,682; 0.10.1,
2026-07-31; 1.75; MIT), `prometheus` (24,842,546; 145,764,833; 0.14.0, 2025-03-27; 1.81;
Apache-2.0), `prometheus-client` (9,695,759; 43,412,696; 0.25.1, 2026-09-01; `rust_version`
null; Apache-2.0 OR MIT), `opentelemetry-prometheus` (2,518,260; 14,203,757; 0.33.0,
2026-09-18; 1.81.0; Apache-2.0), `autometrics` (544,649; 4,320,846; 3.0.0, 2025-09-18; null;
MIT OR Apache-2.0), `measured` (488,311; 2,082,387; 0.0.25, 2026-04-14; 1.88; MIT OR
Apache-2.0), `axum-otel-metrics` (189,163; 403,360; 0.14.1, 2026-07-11; null; MIT). Reverse
dependencies: `GET .../reverse_dependencies?per_page=30`, `meta.total` — `metrics` 1,199,
`metrics-exporter-prometheus` 460.

GitHub REST (retrieved 2026-09-18): `GET https://api.github.com/repos/<o>/<r>` —
`metrics-rs/metrics` 1,486 stars, `archived: false`, `pushed_at` 2026-09-18T14:54:13Z, MIT;
`Ptrskay3/axum-prometheus` 92, false, 2026-07-31T07:07:09Z, MIT; `prometheus/client_rust` 606,
false, 2026-09-14T11:44:30Z, Apache-2.0; `tikv/rust-prometheus` 1,181, false,
2025-12-31T07:01:42Z, Apache-2.0; `open-telemetry/opentelemetry-rust` 2,708, false,
2026-09-18T17:44:05Z, Apache-2.0; `autometrics-dev/autometrics-rs` 833, false,
2025-09-18T14:52:28Z, Apache-2.0; `conradludgate/measured` 41, false, 2026-04-14T09:32:12Z,
licence `null` in the API (crates.io reports MIT OR Apache-2.0); `ttys3/axum-otel-metrics` 40,
false, 2026-07-12T02:48:41Z, licence `null` (crates.io: MIT).
`GET https://api.github.com/search/issues?q=repo:<o>/<r>+is:issue+is:open`, `total_count` — 51,
10, 44, 66, 218, 14, 2, 1 in the same order. Issue responsiveness:
`GET https://api.github.com/repos/<o>/<r>/issues?state=all&sort=created&direction=desc&per_page=20`
filtered to non-PR items, then `.../issues/<n>/comments?per_page=5` per issue.

RustSec (retrieved 2026-09-18): `https://rustsec.org/packages/<name>.html` returned HTTP 404 —
no advisory page, hence no advisory — for `metrics`, `metrics-exporter-prometheus`,
`axum-prometheus`, `prometheus`, `prometheus-client`, `autometrics`, `measured`,
`opentelemetry-prometheus`, `quanta` and `evmap`; HTTP 200 for `metrics-util`, one advisory,
`https://rustsec.org/advisories/RUSTSEC-2021-0113.html`, "Patched >=0.7.0".

Crate sources, read from the published `.crate` tarballs at
`https://static.crates.io/crates/<name>/<name>-<version>.crate` (retrieved 2026-09-18):
`metrics-exporter-prometheus-0.18.3/Cargo.toml.orig` (feature map, `default = ["http-listener",
"push-gateway"]`), `src/lib.rs:98-110` (upkeep contract), `src/exporter/builder.rs:88, :379,
:414, :443-448, :506, :605` (defaults and cfg gates), `src/recorder.rs:38, :465`;
`metrics-0.24.6/Cargo.toml.orig` and `src/cow.rs`; `axum-prometheus-0.10.1/Cargo.toml.orig`
(`axum = "0.8"`, `tower-http = "0.7"`, `metrics-exporter-prometheus … default-features = false`),
`src/lib.rs:8-28, :73-81, :443-455, :870-895`, `src/builder.rs:23-38, :89, :114, :187-207`;
`prometheus-client-0.25.1/Cargo.toml.orig` (no `rust-version`);
`opentelemetry-prometheus-0.33.0/README.md` and `Cargo.toml.orig`.

Framework and standards documentation (retrieved 2026-09-18):
`https://raw.githubusercontent.com/tokio-rs/axum/axum-v0.8.9/examples/prometheus-metrics/src/main.rs`
and `.../Cargo.toml`; `https://prometheus.io/docs/practices/naming/`;
`https://prometheus.io/docs/practices/instrumentation/`;
`https://opentelemetry.io/docs/specs/semconv/http/http-metrics/` and its `/index.md`;
`https://raw.githubusercontent.com/autometrics-dev/autometrics-rs/main/README.md`.

Adopter manifests (retrieved 2026-09-18):
`https://raw.githubusercontent.com/paradigmxyz/reth/main/Cargo.toml` (lines 531–535);
`https://raw.githubusercontent.com/vectordotdev/vector/master/Cargo.toml` (lines 197–199,
302–303); `https://raw.githubusercontent.com/neondatabase/neon/main/Cargo.toml` (lines 136–137,
158).

Repository inputs: `docs/port/COMMONALITY.md:330` (F326), `:307` (F303), `:324` (F320);
`docs/port/areas/web-service.md:14, :26, :32, :56`; `docs/port/PARAMETERS.md` (the five consumed
rows, byte-copied); `docs/port/README.md` (verdict vocabulary);
`docs/planning/p02/owner-decisions.md` §11 and the strict-MSRV-reading ruling;
`inputs/owner-reference-axum-companion-stack-2026-09-16.md` (C10 table rows and the
"C10 Observability on GCP" paragraph); `research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md`
(revision 10, the `- owns web-extra-surface` line and the six moved clauses);
`research/runs/R02/2026-09-17T033527Z-40929a603f91/review/DECISION.md` (four-package workspace,
the `cargo deny --all-features` findings). Source repositories read **through their pins**:
`git -C ~/c/py-launch-blueprint show b08bccfb:src/py_launch_blueprint/web/telemetry.py` and
`:pyproject.toml`; `git -C ~/c/ts-launch-blueprint show cb1cbcb2:package.json`.

**Method notes.** Endpoints queried: crates.io `/api/v1/crates/<name>`, `/versions` and
`/reverse_dependencies` (via `curl` with a research User-Agent, ~1 request/second);
`https://static.crates.io/crates/...` for published crate tarballs, so every manifest, feature
map and source line above was read from the shipped artifact rather than from a rendered docs
page; GitHub REST via keyring-authenticated `gh api` at no more than one call per 20 seconds
(`/repos/<o>/<r>`, `/search/issues`, `/issues`, `/issues/<n>/comments`); `rustsec.org` package
and advisory pages; `prometheus.io` and `opentelemetry.io` documentation;
`raw.githubusercontent.com` for the axum example and the three adopter manifests. All
executable evidence ran in a throwaway directory under `$TMPDIR`, since deleted; no file outside
this report's own path was written.

**What I could not verify, stated rather than inferred.** (1) No Rust annual-survey figure
covering metrics-crate adoption was retrieved; adoption evidence is registry counts and named
projects only. (2) Only 7 non-pull-request issues appeared among the 20 most
recently created items for each shortlisted repository, so the responsiveness rubric's "10 most
recent" is reported over 7 in both cases, not padded; responsiveness for the three
non-shortlisted repositories was not collected. (3) Whether a `MEMBER`/`OWNER` reply is
substantive rather than triage was not judged; the figure is time-to-first-maintainer-comment. (4) Neither CI run was executed on `ubuntu-latest`: gate 4 for the recommended pair is
argued from both crates being pure Rust with no C dependency once `default-features = false`
removes `aws-lc-sys`, plus the executed macOS build — not from a green Linux job I watched.
(5) Compile-time figures are noisy at this scale and are reported as approximate; the crate
count and stripped-binary bytes are exact. (6) The `promtool check metrics` validation of the
exposition text is **proposed**, not executed — the format assertions that did run are
`String::contains` checks, not a conformance parse.
