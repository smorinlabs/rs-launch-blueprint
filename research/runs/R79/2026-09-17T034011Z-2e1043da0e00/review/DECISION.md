# 2026-09-18 — R79 — prometheus-metrics (crate, Focused) — decision (revision 2)

Item R79 (`prometheus-metrics`, kind `crate`, Focused tier, owns nothing). Run
`research/runs/R79/2026-09-17T034011Z-2e1043da0e00`.

**Revision note (revision 2).** Revision 2 is a **pre-audit revision** occasioned by owner
ruling **W2-REST** of 2026-09-18 (`docs/port/OWNER-REVIEW.md:187`, heading "2026-09-18 — the
REST API Design Standard binds the HTTP surface (W2-REST)"), which was made after revision 1
(sha256 `2e804161b9fbe65c7d33be04de5e024612ce628e1ea914c4e636443e0f0885c3`) was written. The
ruling holds that the organisation's REST API Design Standard v2.0.0 —
`/Users/stevemorin/c/rest-standards/rest-api-standard.md`, commit
`0850d43e45d919ef5e37f7174c4212b46013c49f`, file blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
— governs this template's optional HTTP surface the way the CLI Design Standard governs its
CLI, and that every departure is recorded as an `OVERRIDE (OV-nn)` in the shape of the
standard's own §1.9 deviation note.

**The crate pair, the version pins, the feature graph, the metric names, the label set, the
architecture comparison, the gate answers, every ledger and reference-row disposition and all
four `- assumes` lines do not move.** What moves is the `/metrics` endpoint's HTTP behaviour:
revision 2 adds three requirements the standard imposes and records two departures it cannot
meet. Moving the recommendation is allowed here and is stated plainly rather than deferred —
this decision has not been accepted, so a conformance repair lands in the recommendation
itself rather than as a follow-on.

**Note on the ruling's own enumeration.** W2-REST names "Every web item (R70 R72 R73 R74 R76
R77 R80 and the later R71 R83 R84)" at `docs/port/OWNER-REVIEW.md:198`. **R79 is not in that
list**, yet R79 registers an HTTP route on exactly the surface the ruling binds. This revision
treats the omission as an enumeration gap rather than an exemption, on the ground the ruling
itself states — the standard "governs this template's optional HTTP surface" — and because
§1.8 of the standard refuses to let a missing declaration act as an exemption. The controller
may wish to correct the enumeration; nothing in this decision depends on that correction.

**Every revision-1 artifact is byte-identical**: `review/evidence/cargo-probes.sh`,
`cargo-probes.log`, `crate-sources.sh`, `crate-sources.log`, `github-api.sh`, `github-api.log`,
`decision-self-check.sh`, `decision-self-check.log`, `scrape-sample.txt`, the four files under
`locks/` and the fourteen under `snapshots/`. Their sha256 values are pinned and printed by
the new script so an auditor does not take that on trust. The new artifacts are new files:
`review/evidence/rest-conformance-r2.sh`, `review/evidence/rest-conformance-r2.log` and
`review/evidence/snapshots/rest-standard-rules.txt`.

**`review/evidence/decision-self-check.sh` is superseded, and it is superseded loudly.** It
asserts revision 1's H1 line and revision 1's sha256 by construction, so re-running it against
revision 2 fails on exactly those two checks — by design, not by rot. Its committed log stands
as the record of the revision-1 run. `rest-conformance-r2.sh` re-executes its whole check set
against revision 2 and adds the standard's rules on top, so nothing the r1 script proved is
lost and an auditor reruns the r2 script.

There is no `## Supersedes` because no revision of this decision has been published.

## Decision

**Adopt `metrics` `0.24.6` (range `^0.24.6`) as the instrumentation facade and
`metrics-exporter-prometheus` `0.18.3` (range `^0.18.3`, `default-features = false`) as the
recorder and Prometheus text renderer, declared as optional dependencies of the `crates/web`
member behind a Cargo feature named `metrics`, with the RED middleware (about forty lines of
`axum::middleware::from_fn`) and the `/metrics` handler written in the template itself rather
than taken from a framework-specific middleware crate.**

This is a **proposal validated in the implementation phase** (owner ruling, 2026-09-10). It
records what the research found and what it recommends; P03 builds the template and its CI
proves the recommendation. `## Engines` lists what P03 must validate. A recommendation that
does not survive implementation is revised against this recorded research, not researched
again from scratch.

**Ledger rows settled.** **F326** — `docs/port/COMMONALITY.md:330`, verbatim:

> `| F326 | Prometheus RED metrics exposed at /metrics, on by default | web-service | py-only | DIVERGENT | R79 | standalone; whether Rust adopts a metrics crate/exporter (e.g. \`metrics\` + \`metrics-exporter-prometheus\`) for RED metrics at \`/metrics\` |`

F326 is settled in the affirmative and with no wording change: the template adopts a metrics
crate and exporter, exposes RED series at `/metrics`, and does so on by default within the
enabled web surface. **No `BASELINE-REVIEW:` finding is raised by this item**, and no
`CONFLICT:` line: the design needs no consumed parameter changed. F303 (no web service in ts)
and F320 (probe exclusion from *access-log* volume, R75's) are named as context, not settled
here.

**The metric surface, in full.**

| Series | Type | Labels | Which of RED it carries |
|---|---|---|---|
| `http_server_request_duration_seconds` | histogram, explicit buckets `[0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1, 2.5, 5, 7.5, 10]` | `http_request_method`, `http_route`, `http_response_status_code` | all three: `_count` is the rate, the status-code label is the error split, the buckets are the duration |
| `http_server_unmatched_requests_total` | counter | none | 404 volume at cardinality 1, kept out of the route-labelled space on purpose |

**Two instruments, not three, and the reason is the Prometheus project's own cardinality
rule.** py emits a separate `http_requests_total` counter alongside its duration histogram. A
Prometheus histogram already publishes `_count` at the same label set, so
`rate(http_server_request_duration_seconds_count[5m])` is the R of RED and the same expression
filtered on `http_response_status_code=~"5.."` is the E. Emitting a redundant counter doubles
the series count for no query that cannot already be written. This is a deliberate reduction
against the source, argued on the naming guide's own ground rather than on preference.

**Metric names follow the OpenTelemetry HTTP semantic conventions, not py's library
defaults — a position this synthesis takes rather than a hedge it relays.** The Opus report
recorded this as its one medium-confidence recommendation and named the alternative (py's
`http_requests_total` / `http_request_duration_seconds` with labels `handler`/`method`/`status`).
The decision is to adopt the semconv names, for one reason: the agreement level F326 requires
is *capability plus policy*, not metric name, and semconv is a versioned cross-language
standard that R78's spans will carry anyway, whereas py's names are one Python library's
defaults with no shipped dashboard to break. `http.server.request.duration` is marked
**Stable** in the conventions, with unit `s`, `http.request.method` Required,
`http.response.status_code` and `http.route` Conditionally Required, and the dotted-to-underscore
mapping used above is the one a Prometheus OTLP receiver performs itself
(`https://opentelemetry.io/docs/specs/semconv/http/http-metrics/`, retrieved 2026-09-18). One
paragraph of README and a note for the follow-on py/ts harmonisation project is the whole cost.

**What the `metrics` feature actually adds to `crates/web`, measured.** Twenty-eight runtime
crates, named in full in `review/evidence/cargo-probes.log`: `metrics`,
`metrics-exporter-prometheus`, `metrics-util`, `quanta`, `evmap`, `left-right`, `hashbag`,
`sketches-ddsketch`, `indexmap`, two `hashbrown` majors (0.16.1 and 0.17.1), `foldhash`,
`equivalent`, `rapidhash`, `crossbeam-epoch`, `crossbeam-utils`, `thiserror` and
`thiserror-impl`, `rand`, `rand_chacha`, `rand_core`, `rand_xoshiro`, `ppv-lite86`,
`getrandom`, `zerocopy`, `base64`, `cfg-if` and `rustversion`. **`tower` is already in the
runtime graph through `axum` and is not added by this feature; `tower-http` does not join the
runtime graph at all**, and the recommendation needs no direct `tower` manifest entry, because
`axum::middleware::from_fn` is axum's own re-export and the probe compiled with `tower` present
only as a `[dev-dependencies]` entry (checks E1, E3). That matters because R69 records `tower`
0.5.3 as `crates/web`'s dev-dependency *not gated by the feature*, and hands `tower-http` to
R75; the ranked runner-up would break both, adding `tower-http` 0.7.1 to the runtime graph
(check: runner-up footprint).

### Principles and implementation

**The shared requirement, its source, and the level at which agreement is required.**

*Requirement (principle).* A service built from this template publishes, with no configuration
step, a scrape-able RED time series for every request it handles, keyed by a **route template**
rather than a request URI, and the endpoint that publishes those series neither measures itself
nor appears in the service's public API contract.

*Source.* Ledger row **F326** (`docs/port/COMMONALITY.md:330`), origin `py-only`, verdict
`DIVERGENT`, item R79. The py evidence was re-read at its pin
(`git -C ~/c/py-launch-blueprint show b08bccfb55d05f15e46a83b52c5660b1881d19f5:src/py_launch_blueprint/web/telemetry.py`,
2026-09-18), lines 46–48:

```python
    Instrumentator(
        excluded_handlers=["/metrics", "/healthz", "/readyz"],
    ).instrument(app).expose(app, endpoint="/metrics", include_in_schema=False)
```

Two facts the ledger row's one-line summary does not carry, both confirmed at the pin and both
load-bearing here. First, the exclusion set is **three paths, not one** — `/metrics`,
`/healthz` and `/readyz` — so R80's probe routes are inside this item's exclusion story, which
is stated below as a requirement handed to R80 rather than decided for it. Second,
`prometheus-fastapi-instrumentator>=7.0.0` ships in py's **`web` extra**, not in a separate
one (`pyproject.toml:62` at the same pin, under `[project.optional-dependencies]` `web` at
`:56`), while the heavier OpenTelemetry dependencies sit in a separate `otel` extra at `:64`.
ts has no web service at all (F303, `docs/port/COMMONALITY.md:307`), so `TS_PORT_DECISIONS.md`
has nothing to say.

*Agreement level.* **Capability plus policy** — not library, and not metric name.

| Must agree across py, ts and rs | May justifiably vary per ecosystem |
|---|---|
| the endpoint path `/metrics` | the crate or package that provides it |
| the three RED quantities | the metric **names** and label keys |
| on-by-default posture: no environment variable gates collection | whether a redundant request counter accompanies the histogram |
| the metrics endpoint is excluded from its own measurements | the packaging unit the capability travels in (a Python extra, a Cargo feature) |
| the metrics endpoint is excluded from the generated OpenAPI schema | the exclusion *mechanism* (a handler list, or structural placement) |
| bounded label cardinality | the bucket boundaries, where a standard does not fix them |

**Observable acceptance criteria.** Each is asserted by the executed check recorded under
`## Empirical check`, not proposed:

1. A successful request to a templated route produces a duration-histogram series whose route
   label is the **template** (`/v1/projects/{id}`), never the URI.
2. A failing request produces a series carrying its status code (`500`).
3. Buckets, `_sum` and `_count` are all present, and `_count` is the rate signal.
4. 51 requests across 50 distinct path-parameter values produce exactly **one** route label
   value for that route.
5. Two scrapes of `/metrics` produce **no** series labelled with `/metrics`.
6. A request matching no route produces no route-labelled series at all, and increments the
   label-free unmatched counter instead.
7. The exposition text parses under the Prometheus project's own parser
   (`promtool check metrics`), not merely under `String::contains`.

**Architecture alternatives, compared before any library was picked.**

| # | Architecture | How RED is collected | How exposition happens | Verdict for this template |
|---|---|---|---|---|
| A | Framework middleware crate (`axum-prometheus`) | a `tower::Layer` the crate owns | the crate returns a `PrometheusHandle`; you route it | Viable; the **ranked runner-up**. Buys an in-flight gauge, a body-size histogram and a declarative ignore list; costs `tower-http` 0.7.1 in the runtime graph ahead of R75, a per-axum-major upgrade treadmill under one maintainer, and a panic on a second layer construction |
| B | **Framework-neutral facade + recorder + about forty lines of middleware the template owns** (`metrics` + `metrics-exporter-prometheus`) | `axum::middleware::from_fn` in the template's own source | `handle.render()` inside an ordinary axum handler | **Recommended.** The framework maintainers' own example shape, and the template owns the code that decides its label set |
| C | Registry-object client (`prometheus`, `prometheus-client`) | build and thread `HistogramVec` / `Family` handles through `AppState` | `TextEncoder` / `encode` into a `String` | Architecturally clean — typed labels, no process-global state — but pushes an observability object into R01's composition root, where today only the erased `ProjectsService` lives; and `prometheus-client` fails gate 2 |
| D | OpenTelemetry metrics pipeline (`opentelemetry` + `opentelemetry_sdk` + `opentelemetry-prometheus`) | OTel `Meter` instruments | a `prometheus::Registry` bridged out | **Rejected on the maintainers' own advice**, and because it would make a default-on surface structurally depend on the crate set R69 deliberately nested behind the *optional* `otel` feature |

**Why architecture B, stated as principle rather than preference.** The facade split is the
architecture the Rust ecosystem already settled on for diagnostics: `log` and `tracing` are
facades, and the subscriber is chosen at the binary. Three consequences fall out that this
template specifically needs.

1. **The core library can be instrumented without paying for an exporter.** `metrics`' macros
   compile to a no-op when no recorder is installed, and recording a value requires no async
   runtime — which is what R05 revision 3's synchronous core requires ("Adopt a synchronous,
   blocking execution model for the library crate and the CLI binary, and confine async to
   R69's optional `web` feature"). Nothing in this design asks `crates/core` to hold a
   registry, so R02 revision 2's core external-dependency allow-list is untouched.
2. **The template owns its label set.** Cardinality is the one failure mode that turns a
   metrics endpoint into an outage, and the Prometheus project's own guidance — "Do not use
   labels to store dimensions with high cardinality" and "try to keep the cardinality of your
   metrics below 10" (`https://prometheus.io/docs/practices/naming/` and
   `.../instrumentation/`, retrieved 2026-09-18) — is a rule about *your* labels. A middleware
   crate that decides them for you is a crate you must audit anyway.
3. **Recorder and exposition are replaceable independently.** Swapping
   `metrics-exporter-prometheus` for `metrics-exporter-otel` later changes one function, not
   every call site — which is the seam that lets R78 and R79 converge without touching
   instrumentation.

**Why not D, in the maintainers' own words.** `opentelemetry-prometheus` 0.33.0's own
`README.md` steers new projects to `opentelemetry-otlp` instead (re-read from the published
tarball, sha256 recorded in `review/evidence/crate-sources.log`, 2026-09-18), and its
`Cargo.toml.orig` declares `prometheus = { version = "0.14", default-features = false }` — so
choosing D means adopting architecture C transitively and carrying two client libraries in one
graph. This settles the R78 coordination question cleanly: **R78 exports traces over OTLP
behind the optional `otel` feature; R79 exposes metrics by native Prometheus scrape; the
template ships no OTel-metrics-to-Prometheus bridge.** Coherence with R78 is bought with a
shared vocabulary — the semconv names above — rather than with a shared library.

**The exclusion of `/metrics` from its own measurements is structural here, not configured,
and this is the sharpest difference between the two viable candidates.** Both directions were
re-read at source.

- With the recommended design, `/metrics` is registered on a router **merged after**
  `route_layer` has been applied, so the middleware is not in its service stack at all. There
  is no ignore list to keep in sync and no way to forget it: registering the route inside the
  instrumented group would be a visible code change. The executed check asserts
  `!body.contains("http_route=\"/metrics\"")` after two scrapes, and passes.
- `axum-prometheus` does **not** exclude `/metrics` out of the box. Its own crate
  documentation shows the opposite: the sample scrape at `src/lib.rs:73` reads
  `axum_http_requests_total{method="GET",endpoint="/metrics",status="200"} 5`, and
  `:74`–`:88` carry the pending gauge and the whole duration histogram for `/metrics` as well.
  Exclusion is available but is an explicit call —
  `MetricLayerBuilder::with_ignore_pattern` at `src/builder.rs:89`, or `with_ignore_patterns`
  at `:114` for the probe paths too.

So the direct answer to the prompt's fourth HIGH question is: **neither candidate excludes it
"for free" in py's sense. The recommended design excludes it by construction; the runner-up
excludes it by a hand-written pattern list — which is, note, the closest thing in the field to
py's `excluded_handlers`.**

**Bounded cardinality is enforced by `MatchedPath`, and by refusing the fallback.** axum
inserts `MatchedPath` into request extensions when a route matches, and `route_layer`
middleware runs after matching, so the extension is present. The conventions say `http.route`
"MUST NOT be populated when this is not supported by the HTTP server framework"; for an
unmatched request there *is* no template, and substituting `req.uri().path()` — which axum's
own example does, and which `axum-prometheus`'s default `EndpointLabel::MatchedPath` also does
as a fallback (`src/builder.rs:28`, "first trying to extract and return
`axum::extract::MatchedPath`") — is exactly the unbounded-label mistake the naming guide warns
about: a scanner spraying random paths mints a new series per path, permanently. The
recommended design therefore records **no route-labelled series** for an unmatched request and
increments the label-free `http_server_unmatched_requests_total` instead.

**The maintenance contract that silently breaks if ignored — upkeep — and a real defect in the
otherwise-authoritative reference.** The exporter's own `src/lib.rs:108`–`:110` states that
when the lower-level `PrometheusBuilder::build_recorder` or `install_recorder` is used, the
upkeep task "is _not_ spawned" automatically and the caller must hold a `PrometheusHandle` and
call `run_upkeep` at a regular interval. Upkeep drains histogram buckets; without it memory
grows with distinct observations. `install()` and `build()`, which *do* spawn it, sit behind a
real multi-line compilation gate `#[cfg(any(feature = "http-listener", feature =
"push-gateway", feature = "push-gateway-no-tls-provider"))]` at `src/exporter/builder.rs:443`
and `:531` — exactly the heavyweight features this template turns off. `install_recorder`
(`:506`) and `build_recorder` (`:605`) carry no such gate and are available with
`default-features = false`; that was verified by walking the attribute block above each
declaration, not by a line regex. Consequence: **axum's own worked example calls
`install_recorder()` and never runs upkeep** — `run_upkeep` does not appear anywhere in
`examples/prometheus-metrics/src/main.rs` at tag `axum-v0.8.9`. The template must spawn the
upkeep ticker next to the server, at the exporter's own 5-second default
(`let upkeep_timeout = Duration::from_secs(5);`, `src/exporter/builder.rs:88`).
`axum-prometheus` gets this right (`src/lib.rs:889`), which is a genuine point in the
runner-up's favour and the reason the recommended design copies that loop rather than copying
axum's example verbatim.

**The minimal realistic example.** One new module under `crates/web/src/obs/`, about seventy
lines. `OnceLock` is not decoration: `metrics::set_global_recorder` succeeds once per process
and `install_recorder()` returns `Err` on a second call, so building the router in two
`#[tokio::test]` functions in one integration-test binary would otherwise panic — which is
also why the design does not copy `axum-prometheus`'s `Handle::default()`, whose
`metrics::set_global_recorder(recorder).expect("Failed to set global recorder")`
(`src/lib.rs:892`) is unconditional.

```rust
// crates/web/src/obs/metrics.rs
const DURATION: &str = "http_server_request_duration_seconds";
const UNMATCHED: &str = "http_server_unmatched_requests_total";
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
        .merge(Router::new().route("/metrics", get(move || async move { handle.render() })))
}
```

**Feature graph, spelled out against R69 revision 10's topology.**

```toml
# Cargo.toml (root package rs-launch-blueprint)
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

A Cargo feature named `metrics` coexisting with an optional dependency named `metrics` looks
illegal and is not: naming `dep:metrics` anywhere in `[features]` suppresses the implicit
same-named feature. That was compiled, not assumed (check E1), which is what keeps this design
on R69's recorded `metrics = ["web", …]` spelling instead of defensively renaming the feature.

**`default-features = false` is the single highest-value line in the recommendation, and the
cost of omitting it is measured.** The exporter's defaults are
`default = ["http-listener", "push-gateway"]` (`Cargo.toml.orig:19`, 0.18.3), which pull an
HTTP server, an HTTP client, TLS and a crypto provider. On a minimal two-crate base the
resolved normal graph is **37 crates with `default-features = false` and 81 with the defaults
on** — 44 added, including `aws-lc-rs`, `aws-lc-sys` (a C and assembly build), `rustls`,
`rustls-native-certs`, `rustls-webpki`, `hyper`, `hyper-rustls`, `hyper-util`, `h2`,
`tokio-rustls`, `security-framework` and `ipnet`. None of it is used: the template renders into
its own axum route and opens no second port. Both reth and `axum-prometheus` independently
reached the same `default-features = false` conclusion.

**Answering the two MEDIUM questions directly.**

*On-by-default posture.* At the **runtime** level, yes, and nothing about the candidate fights
it: no environment variable gates collection, the recorder is installed during startup
unconditionally, and the `/metrics` route is registered unconditionally — matching py exactly,
and deliberately unlike R74's opt-in rate limiting. **R77's `RSLBP_WEB_METRICS_ENABLED` is
disposed of here, because R77 names it and defers its semantics to this item** (R77's raw
report names the variable at `raw/opus.md:364`, records "`METRICS_ENABLED`, `OTEL_ENABLED` |
not decided | R79, R78" at `:379`, and leaves the field commented out of `WebSettings` at
`:220`). The disposition is: **the template defines no such variable.** F326's "on by default,
no env gate" is an owner-recorded baseline, and a knob that can turn RED collection off is the
thing F326 exists to forbid. At the **packaging** level the shape is already R69's settled
value, `metrics = ["web", …]`, byte-identical in published revision 9 and accepted revision 10.
One consequence P03 must carry, and it is a real if small divergence from py: py ships the
instrumentator *inside* the `web` extra, so a py user installing `[web]` gets metrics, while an
rs user enabling only `--features web` will not. That is **R69's owned value, not this item's
to re-decide**; this decision designs against it, raises no `CONFLICT`, and does not propose
`default = ["metrics"]` on `crates/web`, which would widen R69's `web` feature by the back
door. What it asks of P03 is documentation: the README's web quickstart shows
`--features metrics` (or `--all-features`), so the default example a reader copies is the
instrumented one.

*OpenAPI exclusion.* Automatic, on one stated condition. R71 owns the generation pipeline;
every Rust OpenAPI generator in that space derives the document from annotated handler or route
registrations (a `utoipa`-style `#[utoipa::path]` plus `OpenApiRouter`, or an `aide`-style typed
route method). `/metrics` here is registered with plain `axum::routing::get` on a plain
`Router`, with no annotation and no typed registration, so there is nothing for the generator to
pick up — the py analogue of `include_in_schema=False` is "never in the schema's input set"
rather than "removed from its output". The condition is that R71 must not adopt a generator
that enumerates a live `axum::Router`'s route table; if it does, the route needs an explicit
exclusion and this paragraph must be revisited. The requirement handed to R71 is one sentence:
**the metrics route must be excludable from the generated document, and is excluded today by
being registered outside the annotated path.**

**Owner reference architecture — the C10 rows, re-checked at source.** Only the C10 block
overlaps this item (`inputs/owner-reference-axum-companion-stack-2026-09-16.md`, section
"### C10 Observability on GCP" at line 110, the paragraph at line 111).

| Reference row or clause | Position | Ground |
|---|---|---|
| "**Metrics**: start with log-based metrics/Cloud Monitoring; add the `metrics` crate + exporter only when needed" — the *posture* half | **DIFFER** | The reference is written for a Cloud Run deployment where Cloud Monitoring is already present. This template ships no deployment target, and F326 (`docs/port/COMMONALITY.md:330`, quoted verbatim above) is an owner-recorded baseline: RED metrics at `/metrics`, on by default. Log-based metrics also cannot supply a duration **histogram** with bucket boundaries — you get counts and derived rates, not quantiles — so "start with log-based metrics" would fail the D of RED outright. The difference rests on sourced ground, not preference |
| The same clause's *crate family* half: "the `metrics` crate + exporter" | **AGREE** | When the reference does reach for metrics, it names exactly the family recommended here. Independent agreement, recorded |
| C10 table row, line 68: "Logs/traces — **tracing + tracing-subscriber (JSON)** (+ tracing-stackdriver)" | **HAND-OFF** | R58 (`logging-pipeline-contract`) owns it; unpublished, registry value `—`. Not decided here |
| C10 table row, line 69: "Error reporting — **sentry + sentry-tower**" | **HAND-OFF** | No P02 row assigns error reporting to R79. Not decided here |

Tally: **1 agree, 1 differ, 2 hand-offs** — the same disposition the Opus report reached,
re-checked line by line rather than carried.

**Couplings stated, not decided.**

- **R80 (`health-probe-endpoints`, in parallel).** py excludes `/healthz` and `/readyz` from
  measurement alongside `/metrics`, so R80's probe routes belong on the **unmeasured** side of
  `route_layer`. R80's own raw report puts them in `crates/web/src/routes/ops.rs` and merges
  them with `.merge(ops::router())` into the one shared `Router` (`raw/opus.md:1030`–`:1034`,
  `:1084`–`:1089`), rejects a second admin listener (`:166`), and explicitly takes "**No
  position**" on observability, assigning only the *access-log* exclusion to R75 and F320
  (`:357`). **No item currently owns excluding the probes from metrics measurement.** The
  requirement this item states, and which R80 or R75 must land: `route_layer` applies to the
  `/v1` nested business router; `ops::router()` and the `/metrics` route are both merged
  **after** it. R80 chooses the paths; this item owns only where they sit relative to the
  layer.
- **R77 (`web-env-settings`, in parallel).** Disposed of above: no environment knob, and
  `RSLBP_WEB_METRICS_ENABLED` is not defined. Should a later item want a knob for the scrape
  path or the upkeep interval, the seam is the two name constants and the ticker interval in
  `obs/metrics.rs`.
- **R58 (`logging-pipeline-architecture`, Wave 3, unpublished, registry value `—`).** The
  exporter is used without its `tracing` feature, so it emits no log lines and imposes nothing
  on the pipeline. R58's current raw material mentions neither R79 nor `/metrics`.
- **R78 (`opentelemetry-integration`).** **No run directory exists**; R78 is unresearched. The
  `otel`/`metrics` sibling relationship is asserted only by R69's owned value. This decision
  therefore fixes the interface rather than the counterpart: R79 does not emit through the OTel
  SDK, and coherence is carried by the semconv names above.
- **R75 (`http-middleware-stack`).** The metrics middleware is an ordinary `from_fn` layer and
  takes its place in R75's ordering; R75 owns excluding `/metrics` from access-log volume
  (F320), which this item does not touch.
- **R01, R02, R05.** No metrics dependency enters `crates/core`; no registry enters R01's
  composition root; nothing on the recording path needs a runtime. The one piece that does need
  the runtime is the upkeep ticker, and it lives beside the server.

**Conformance with the REST API Design Standard v2.0.0 (owner ruling W2-REST, 2026-09-18).**

Every rule below was read from the pinned blob `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`
(`git -C /Users/stevemorin/c/rest-standards show 71bd813c…`), quoted at its line, and asserted
by `review/evidence/rest-conformance-r2.sh` against a committed snapshot of those lines.

**The finding that frames every row: the standard has no vocabulary for an operational
endpoint.** Searched case-insensitively over all 3,427 lines of the blob, the words
`Prometheus`, `telemetry`, `scrape`, `exposition`, `healthz`, `readyz`, `liveness`,
`readiness`, `monitoring` and `instrumentation` are **absent**, and `metrics` appears exactly
once in a rule — R3.3 at `:599`, "**Exception:** logging and metrics side effects do not
violate safety". There is therefore no carve-out to invoke. Three facts close that door
deliberately rather than by oversight: the applicability-switch vocabulary at `:237`–`:238` is
closed to `webhooks · async-operations · bulk-operations · streaming`, and `:238`–`:239` says
it "grows only when a new rule needs a switch"; §1.2 shows what an explicit exclusion looks
like when the standard means one — WebSockets at `:99`–`:105`, "neither conformant nor
nonconformant on it" — and no such sentence exists for operational paths; and R2.1 at `:447`
ends "There is no RPC carve-out for any service class." R1.5 at `:219` adds that "Every rule in
this standard applies at every tier unless the rule itself states a tier scope", and none of
the rules below carries a tier annotation. So `/metrics` is inside the standard's reach, and
where it cannot conform the departure is written down — which is what R1.7 at `:271` requires:
"silent deviation from any rule strength is nonconformance regardless of the deviation's
merits."

| Rule | Line | Rule text, quoted | Disposition |
|---|---|---|---|
| **R1.8** | `:312` | "A conforming API MUST NOT use a reserved name for any purpose other than the meaning registered here" | **CONFORMS.** `metrics` appears in none of §1.10's six registers. The only reserved path segments are the seven action verbs at `:383`–`:387` (`cancel`, `archive`/`restore`, `approve`/`reject`, `publish`/`unpublish`, `duplicate`); `metrics` is not among them |
| **R1.9** | `:318` | "a **mutating** request carrying the `dry_run` parameter … MUST be rejected with `400`" | **N/A with reason** (the §1.8 `:232`–`:235` discipline): the guard is scoped to mutating requests and `GET /metrics` is safe. Recorded, not omitted |
| **R2.1** | `:443` | "An API MUST present a resource-oriented surface: noun resources … There is no RPC carve-out for any service class" | **CONFORMS.** `/metrics` is a noun resource read with `GET`, not an RPC method overlay |
| **R2.2** | `:456` | "Collection resources MUST use plural nouns" | **CONFORMS.** `metrics` is plural |
| **R2.4** | `:477` | "Path segments MUST use kebab-case … pattern `^[a-z][a-z\-0-9]*$`" | **CONFORMS.** Asserted by running the pattern against the literal segment in the check script |
| **R2.5** | `:487` | "a path MUST NOT reference more than three resources" | **CONFORMS.** One segment |
| **R2.6** | `:499` | "Canonical URIs have no trailing slash … a request with a trailing slash SHOULD receive `308 Permanent Redirect`" | **MOVED.** The template registers `/metrics` and never `/metrics/`; the 308 belongs to R75's stack and is handed to it as a requirement |
| **R2.9** | `:525` | "an operation modifier MUST NOT be encoded as a path segment" | **CONFORMS.** No modifier in the path |
| **R2.10** | `:533` | "Personally identifiable information MUST NOT appear in any URI" | **CONFORMS.** No PII in the path, and none in the label set either — see R8.12 |
| **R2.11**–**R2.13** | `:542`, `:562`, `:569` | the `POST /{collection}/{id}/{action}` action form | **N/A with reason.** `/metrics` is a `GET` of a representation, not a non-CRUD action |
| **R4.1** | `:742` | "Every API MUST publish an OpenAPI document as the contract source of truth" | **CONFORMS.** The obligation binds the API to publish a document — R71's — not every path to appear in it. A case-insensitive search of the blob for a per-endpoint coverage rule ("every operation", "undocumented") finds none. The residual is recorded as a re-verify trigger rather than argued away |
| **R4.3** | `:762` | "Every JSON response body MUST have an object at the top level … **Exception:** non-JSON media types" | **CONFORMS by the rule's own exception.** The Prometheus exposition body is not JSON |
| **R4.4**–**R4.9**, **R4.16** | `:768`–`:834`, `:779` | JSON body-content rules | **N/A with reason.** No JSON body and no query parameters on this endpoint |
| **R4.10** | `:846` | "The default media type — served when a request carries no `Accept` header — is `application/json`, encoded UTF-8. Media-type selection MUST use HTTP content negotiation, never a `format` query parameter. A request whose `Accept` header excludes every representation the endpoint supports SHOULD receive `406 Not Acceptable`" | **OVERRIDE (OV-07)(a)**, below. The middle clause conforms — the endpoint selects nothing by `format` — and the first and third are the departure |
| **R4.11** | `:856` | "Every response whose content was selected by a request header MUST send `Vary` … **Exception:** responses with no negotiation" | **CONFORMS by the rule's own exception**, and the exception is earned rather than assumed: the handler returns one representation unconditionally, so no request header influences selection and no `Vary` is owed |
| **R4.17** | `:864` | `Access-Control-Expose-Headers` for cross-origin browser clients | **N/A with reason.** A Prometheus server is not a browser client; CORS is R76's, and this endpoint asks nothing of it |
| **R7.1** | `:1259` | "Every response MUST carry an explicit `Cache-Control` header — stating freshness, `no-cache`, or `no-store` per the R7.3 posture — because silence is not a decision" | **MOVED.** Revision 1 set no caching header, which violates an unconditional MUST that carries no exception, no tier scope and no switch scope. The handler now sets one |
| **R7.3** | `:1281` | tier 1: "Authenticated or mutable resources default to `Cache-Control: private, no-cache`, revalidating via the strong `ETag` machinery of R3.10"; tier 2: "`no-store` is reserved for genuinely sensitive payloads. Blanket `no-store` is a named anti-pattern" | **MOVED to tier 1.** A scrape is mutable, so tier 1 applies and the header is **`Cache-Control: private, no-cache`**. `no-store` is rejected on the rule's own words: the payload is not sensitive. The `ETag` half of tier 1 does not bind, because R3.10 at `:693` scopes it to "A resource that supports conditional update" and carries "**Exception:** resources never updated by clients" — a scrape is never updated by a client |
| **R8.1** | `:1317` | "APIs MUST be served only over TLS 1.2 or higher" | **Handed on, and it binds this path like every other.** The listener is R69's and the deployment R51's; R79 adds no plaintext-only requirement |
| **R8.2** | `:1323` | "Access tokens MUST NOT be accepted or emitted in URI query parameters" | **CONFORMS.** The endpoint accepts no query parameter at all |
| **R8.6** | `:1356` | "Every request MUST be authorized against the specific object, not only the endpoint … deny-by-default, never gateway-enforced" | **OVERRIDE (OV-07)(b)**, below |
| **R8.12** | `:1422` | "Secrets, credentials, and PII MUST NOT appear in … any other response content" | **CONFORMS**, and it is the REST standard's twin of R56 revision 2's rule. The label set is `http_request_method`, `http_route` (a route template) and `http_response_status_code`; none can carry a caller value. The refusal to fall back to `req.uri().path()` is what keeps it true |
| **R11.7** | `:1752` | "Every response, including errors, MUST carry the `request-id` correlation header" | **MOVED**, and this is the correction with the most structural reach. Revision 1 said `/metrics` sits outside the middleware; that is true only of the **RED measurement layer**, which is applied with `route_layer` to the business router. R75's request-id layer must be applied with `.layer()` to the **merged** router so that it covers `/metrics` and R80's probes too. Stated as a requirement handed to R75, and as a constraint on where `instrument()` sits in `build_router` |
| **R11.8** | `:1759` | "W3C Trace Context `traceparent` MUST be propagated" | **MOVED.** Same placement argument as R11.7; the propagation mechanism is R75's and R78's, and this decision records only that `/metrics` is inside it |
| **R13.3** | `:1935` | "An endpoint that does not implement streaming and receives `stream` — as a query parameter or a request-body member, with any value — MUST reject the request with `400`" | **MOVED.** §1.8 at `:258`–`:264` singles this rule out as binding **per endpoint** whatever the API's `streaming` switch says, so `GET /metrics?stream=1` must answer `400`. A Prometheus scrape never sends it, which is precisely why it would have been forgotten |
| **R9.1** | `:1435` | "An API MUST use one uniform version-marker placement: the major version in the path (`/v1`), never `/v1.0`" | **CONFORMS, with the argument shown rather than assumed.** The rule constrains the *placement and form* of the version marker, not its presence on every path; a search of the blob for a universality clause ("every path") finds none, and R2.5's counting rule at `:491` treats the version segment as separate from the resource segments. The API's resources live under `/v1` and the marker never appears as `/v1.0`. This is the weakest row here and is recorded as a re-verify trigger |

**What the recommendation adds, concretely.** Three lines in `instrument()` and one requirement
on `build_router`:

```rust
// R13.3 guard, R7.1/R7.3 posture, on the /metrics handler.
async fn scrape(RawQuery(query): RawQuery, handle: &'static PrometheusHandle) -> Response {
    // R13.3 (:1935): a reserved request modifier an endpoint does not implement is a 400,
    // never a silently non-streamed answer.
    if query.as_deref().is_some_and(|q| q.split('&').any(|p| p == "stream" || p.starts_with("stream="))) {
        return (StatusCode::BAD_REQUEST, [(header::CACHE_CONTROL, "private, no-cache")]).into_response();
    }
    // R7.1 (:1259) + R7.3 tier 1 (:1281): mutable resource, explicit header, never silence.
    ([(header::CACHE_CONTROL, "private, no-cache"),
      (header::CONTENT_TYPE, "text/plain; version=0.0.4; charset=utf-8")],
     handle.render()).into_response()
}
```

and, in `build_router`, the RED layer stays a `route_layer` on the business router while R75's
cross-cutting stack is applied to the merged router, so `/metrics` is **outside the metrics
measurement layer and inside the request-id and trace layer** — two different layers that
revision 1 collapsed into one sentence.

**OVERRIDE (OV-07) — R79's single allocated override, covering two independent departures.**

The controller allocated `OV-07` to R79 and allocates override numbers centrally from now on
(controller notice, 2026-09-18, issued after two syntheses collided on `OV-04` by searching
concurrently). R79 records **two** departures, and they do not share a fact: one is about the
response media type, the other about authentication. They are kept as separate arguments under
the one allocated number rather than merged into a single argument, because merging two
unrelated deviations into one would hide one of them — which is the outcome R1.7 exists to
prevent. **A decision the controller owns:** either `OV-07` carries both rows, as written here,
or R79 needs a second number. The §1.9 conformance note records deviations per rule ID in any
case, so the two rows below land in it either way; only this repository's tracking handle is at
stake. The precedent for one number carrying several rule rows is R80's `OV-04`, which covers
four MUST rules — though there a single fact created all four.

**OV-07(a) — the response media type is the Prometheus text exposition format, not
`application/json`.**

**Argument:** R4.10 at `:846` fixes `application/json` as the media type served to a request
carrying no `Accept` header, and asks for `406 Not Acceptable` when a client's `Accept`
excludes every supported representation. A Prometheus server scrapes with
`Accept: text/plain;version=0.0.4;q=0.5,*/*;q=0.1` and parses the text exposition format; a
`curl` with no `Accept` must receive the same bytes or the endpoint is useless to the tool it
exists for. The format is fixed by the Prometheus project, not by this template, and
`metrics-exporter-prometheus` 0.18.3 renders only that format — `PrometheusHandle::render`
returns a `String` of it, with no JSON path to select. Conformance was attempted first, as
Appendix B `:2799` requires: serving JSON by default and the exposition format only on an
explicit `Accept` would mean every scrape works and every human `curl` silently gets a
different document, which trades a tool-facing break for a human-facing one and satisfies no
reader. The standard already records the identical structural hole for the analogous case, at
`:2218`: a no-`Accept` request to an always-streaming resource "cannot produce" JSON, and
"R4.10's default clause carries no BCP 14 keyword, so this is a taxonomy hole rather than a
live conflict." That release is granted explicitly to streaming resources by R13.2 and not to
this one, so it is cited as the standard's own acknowledgement of the shape of the problem,
not as an exemption this endpoint may borrow. **Strengths, stated exactly:** the default-media-type
clause carries no BCP 14 keyword and so is not a MUST; the `406` clause is a **SHOULD**. This
override therefore records one SHOULD-strength deviation plus a position on a keyword-less
clause, not a MUST violation.

**Options:**
- **(a) Serve the exposition format unconditionally — recommended, and taken.** `/metrics`
  answers `200` with `Content-Type: text/plain; version=0.0.4; charset=utf-8` whatever the
  `Accept` header says, and never `406`. Cost: the two R4.10 clauses above. Benefit: the
  endpoint works with every Prometheus server and every `curl`, and matches py byte for byte.
- **(b) Negotiate: JSON by default, exposition format on an explicit `Accept`.** Conforms to
  R4.10 literally. Cost: a `curl /metrics` returns a JSON document no Prometheus tool reads,
  the template must invent and maintain a JSON rendering of a histogram the exporter does not
  produce, and R4.11's `Vary: Accept` becomes owed. Rejected: it manufactures a second
  representation to satisfy a default nobody requests.
- **(c) Move the endpoint off the API surface onto a second port,** which R80 evaluated and
  rejected as its alternative D. Cost: a second bound listener, a second address in R77's
  settings, a second row in R51's container contract, and it does not actually make the
  standard stop applying — it relocates the same bytes. Rejected.

*Recorded in §1.9 template form for the template's conformance note:*
`- R4.10 · SHOULD (the 406 clause; the default-media-type clause carries no BCP 14 keyword) · /metrics serves text/plain; version=0.0.4 for every Accept and never 406 · the Prometheus exposition format is fixed by the Prometheus project and is the endpoint's whole purpose · approver: owner (pending) · date: 2026-09-18 · review: at the next major version of the template's HTTP surface`

**OV-07(b) — `/metrics` is unauthenticated.**

**Argument:** R8.6 at `:1356` requires that "Every request MUST be authorized against the
specific object, not only the endpoint", centralized and deny-by-default. An unauthenticated
scrape endpoint has no principal for that decision to run against. The standard grants no
exception: a case-insensitive search of the blob for `anonymous` and `public endpoint` returns
nothing, and the four occurrences of `unauthenticated` are a rate-limit axis row at `:1397`
that prices unauthenticated traffic without permitting or forbidding it. Against that, F326 is
an owner-recorded baseline — RED metrics at `/metrics`, on by default, with no configuration
step — and py's instrumentator is unauthenticated at the pin. Requiring a credential would
make the endpoint unusable without one, which is a configuration step, which is what F326
forbids. Conformance was attempted first: an API-key gate under R8.3 was considered and
rejected because the template ships no deployment target and therefore no key issuer, so the
gate would have to ship disabled — a rule satisfied in text and not in fact, which R1.7 treats
as worse than a recorded deviation. **Strength: MUST.** Under R1.7 at `:273` this makes the
surface nonconformant unless recorded, and Appendix B `:2803`–`:2806` routes a
requirement-strength deviation to the standard's owner. It is recorded here and flagged for
that approval; R79 does not grant itself the exception.

**Options:**
- **(a) Unauthenticated `/metrics`, on by default — recommended, and taken.** Cost: R8.6, at
  MUST strength, pending the owner's approval. Benefit: F326 is met exactly; the scrape works
  with a stock Prometheus server; py and rs behave identically. Mitigation the template can
  carry without a configuration step: the exposition carries no secrets by construction
  (R8.12, R56), and the served bind address is loopback by default under R77's proposed
  `RSLBP_WEB_HOST` default of `127.0.0.1`, so a container must opt into `0.0.0.0` before the
  endpoint is reachable off-host.
- **(b) Require an API key on `/metrics`.** Conforms to R8.6. Cost: the endpoint is off until
  configured, contradicting F326's "no configuration step"; the template ships no key issuer,
  so the shipped default would be a disabled gate. Rejected.
- **(c) Bind `/metrics` to a separate loopback-only listener.** Reduces exposure without a
  credential, but still has no principal, so R8.6 is equally unmet — and it costs the second
  port R80 already rejected. Rejected as not addressing the rule it appears to address.

*Recorded in §1.9 template form:*
`- R8.6 · MUST · /metrics is served without authentication or authorization · F326 requires RED metrics on by default with no configuration step, and the template ships no credential issuer; the payload carries no secrets (R8.12) and the default bind address is loopback · approver: standard owner (required by Appendix B step 3, pending) · date: 2026-09-18 · review: at the next major version of the template's HTTP surface`

**The override number is the controller's allocation, and this synthesis's own search was
wrong — both facts recorded rather than the second quietly dropped.**

Override numbers are allocated centrally as of 2026-09-18. `docs/planning/p02/execution-ledger.md:1073`
records why and what: "R77 revision 2 (`d36492b`) and R80 revision 2 (`ce291fe`) both allocated
OV-04 by concurrent 'next free number' searches. Resolution: OV numbers are allocated by the
controller from now on." The same line carries the allocation table, and R79's entry in it is
**`OV-07`**, reserved "whether or not used (gaps are acceptable)". This decision takes that
number and runs no allocation search of its own; `OV-08` through `OV-15` are reserved to R76,
R58, R73, R74, R84, R72, R51 and R83, so a search would have collided with any of them.

**The search this synthesis did run before that notice was a truncated search reported as a
census, and it was false.** It ran
`/usr/bin/grep -rnoE "\bOV-[0-9]+\b" research docs` over the whole working tree; that walks
132,859 files, exceeded its timeout, and returned **no output** — read as "no `OV-nn` is in
use". `OV-01` through `OV-06` were in fact already held. A scoped rerun over the 7,344 markdown
files where an override can actually be recorded —
`find research docs -type f -name '*.md' -print0 | xargs -0 /usr/bin/grep -noE "\bOV-[0-9]+\b"` —
completes in seconds and returns the true set. An intermediate draft of this revision then
allocated `OV-10` and `OV-11` from that corrected census; the controller's notice supersedes
that choice, and both were renumbered to `OV-07` before committing. A second miss followed and
is recorded for the same reason: the renumbering at first left `OV-10` and `OV-11` standing in
two conformance-walk table rows, because the enumeration grep was piped through `cut -c1-135`
and the references sat past that column. The evidence script caught it, which is what it is
for, and the repair is the corrected enumeration shown here rather than a re-read.

`review/evidence/rest-conformance-r2.sh` still executes the scoped census and prints it — not
to allocate, which is no longer this item's job, but to assert that no OVERRIDE heading here
carries a number other than `OV-07`, that no other **item** claims `OV-07` (the controller's
ledger naturally names it, and is excluded as the allocator's own register), and that the
census never comes back empty again, since an empty result now means the search is broken
rather than that the numbers are free.

**What R79 contributes to the template's conformance note.** The note itself is one document
per API and is R71's or R69's to hold, not R79's to create. R79 supplies four rows for it: the
two deviation rows quoted above, and two N/A rows — `- R1.9 · the dry_run guard binds mutating
requests; /metrics is safe` and `- R2.11–R2.13 · /metrics is a GET of a representation, not a
non-CRUD action`. R1.5 at `:210` requires the note to declare one conformance tier; that
declaration is the API's, and none of the rules above changes with it, because none carries a
tier annotation.

re-verify: on any of these, whichever comes first — (1) **R69 republishes** at revision 10 or later, confirming that the `metrics = ["web", …]` clause and the `crates/web` paths this design is written against survive verbatim; (2) **R02 publishes** a topology other than the four-package workspace with `crates/web`; (3) **R80 publishes** its probe paths, which must join `/metrics` on the unmeasured side of `route_layer`; (4) **R71 publishes** a generator that enumerates a live `axum::Router` rather than annotated registrations, which would make the automatic OpenAPI exclusion need an explicit mechanism; (5) **R77 publishes** a settings surface that still defines `RSLBP_WEB_METRICS_ENABLED`, which would contradict the no-env-gate disposition recorded here; (6) **R78 publishes** a decision that emits metrics, not only traces, through the OTel SDK, at which point the two items need one recorder rather than two pipelines; (7) **`prometheus-client` declares a `rust-version`**, clearing gate 2 and deserving a fresh head-to-head it currently wins on design grounds; (8) **`metrics-exporter-prometheus` releases 0.19 or `metrics` releases 0.25**, both semver-breaking under caret-on-`0.x`; (9) **`axum` publishes 0.9**, re-opening `MatchedPath` and `route_layer` semantics; (10) **Prometheus native histograms become the default advice**, retiring the bucket constant; (11) at the next **`msrv-policy` floor advance past 1.96**, re-running `review/evidence/cargo-probes.sh` at the new toolchain; (12) **the REST API Design Standard publishes a blob other than `71bd813c1cf61286586b4ee41ed83ff065e5c8d9`**, which re-opens every rule line number and rule text quoted in the conformance walk, and in particular any change to R4.10, R8.6, R7.1, R7.3, R11.7, R11.8 or R13.3; (13) **the standard's owner rules on OV-07(b)**, whose MUST-strength deviation is recorded pending that approval under Appendix B step 3, or on OV-07(a); (14) **the controller rules on whether the single allocated number `OV-07` may carry both of R79's departures or whether a second number is issued**, the open question recorded under the override; (15) **R71 publishes a reading of R4.1 that requires every path to appear in the OpenAPI document**, or **R75 publishes a middleware stack that does not place `/metrics` inside its `request-id` and `traceparent` layers**, either of which turns a row recorded above as CONFORMS or MOVED into an override; or (16) by **2027-03-18**.

## Parameters

- assumes msrv-policy = stable minus 2 minor versions, raised only in a minor release, declared as rust-version in Cargo.toml and tested in CI
- assumes rust-edition = 2024
- assumes target-os-matrix = ubuntu-latest, macos-latest
- assumes license = MIT OR Apache-2.0

This item owns no shared parameter: its prompt's `- owns:` line is empty, so no
`- owns <param> = <value>` line is written.

**Why there is no `- assumes web-extra-surface` line, which is a departure from the controller's
task message and is recorded rather than made quietly.** R79's prompt carries an **empty**
`- consumes:` line, and `inputs/parameters.json` lists exactly the four fixed parameters above
and no consumed one. `scripts/research_validation.py` computes
`expected_assumptions = expected_fixed | expected_consumed` and reports
`"DECISION.md current assumed parameter set does not match fixed and consumed values"` whenever
the declared set differs (`:762`–`:766`). A fifth `- assumes` line would therefore fail strict
acceptance validation at publication. R69 is a **research prerequisite** of this run
(`inputs/prerequisites.json` records its decision hash `d4507f5b…`), not a parameter coupling,
so its value is consumed in prose instead. The clause this design rests on is byte-identical in
R69's published revision 9 and its accepted revision 10, and is quoted here from the live
registry row `web-extra-surface` in `docs/port/PARAMETERS.md`:

> heavier opt-ins nest on top rather than widening it, as separate features that require web -
> otel = ["web", ...] for R78 and metrics = ["web", ...] for R79 - mirroring py's web plus otel
> extras

The same registry row records `tower 0.5.3 is a dev-dependency only, for the
ServiceExt::oneshot in-process test idiom, and is not gated by the feature`, and that is the
clause the `from_fn` middleware choice above is written to respect. **Revision 10 of R69 is
owner-accepted and not yet published**, and it moves six clauses of that value — most
consequentially the gated tree from `src/web/` to `crates/web/src/`, the feature body from
`web = ["dep:axum", "dep:tokio"]` to `web = ["dep:rs-launch-blueprint-web"]`, and the tests
from `tests/` to `crates/web/tests/` with no file-level `#![cfg(feature = "web")]`
(`research/runs/R69/2026-09-18T020601Z-f304731ab06f/review/DECISION.md:1791`, with the
clause-by-clause substitution table at `:54`–`:61`). **Every path in this decision uses
revision 10's `crates/web` form**, while the quotation above keeps the published registry bytes;
R69's republication is the first re-verify trigger recorded above. That is a stated forward
dependency, not a conflict, so no `CONFLICT:` line is raised.

The fixed parameters bear on the decision as follows. `msrv-policy` sets the floor at **1.96**
for the `rustc 1.98.0` stable of 2026-09-18, derived in the check script rather than asserted;
both recommended crates publish `rust-version` `1.71.1`, and the resolved `--features metrics`
tree's highest declared value is `hashbrown` 0.17.1's **1.85.0**, eleven minors inside the
floor. `rust-edition = 2024` is the probe manifest's declared edition throughout.
`target-os-matrix` is the reason `default-features = false` is not optional: it removes
`aws-lc-sys`, the only C and assembly build in the graph, leaving two pure-Rust crates that
carry no platform-gated code path — but see `## Engines`, because **nothing was built on
`ubuntu-latest` in this run**. `license` is recorded and not evaluated, because fitness gate 1
is struck from every item's evaluation by the owner's ruling; the gate is recorded, not
deleted, and its verdict is:

`inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`

## Empirical check

**Toolchain and environment.** `rustc 1.98.0 (88d9e12ae 2026-08-18) (Homebrew)`,
`cargo 1.98.0 (797e8a9bc 2026-08-05) (Homebrew)`, macOS 26.4 on arm64,
`grep (BSD grep, GNU compatible) 2.6.0-FreeBSD` invoked as `/usr/bin/grep`,
`cargo-audit-audit 0.22.1`, `promtool, version 3.14.0`, `curl 8.7.1`. All figures retrieved
2026-09-18 (UTC). Working directory for every script:
`research/runs/R79/2026-09-17T034011Z-2e1043da0e00/review/evidence/`. Every cargo probe built
only throwaway packages under a `$TMPDIR` subdirectory the script creates and deletes; no
`target/` tree was written inside this worktree and the recommendation was not implemented
anywhere in the repository.

| Script | Command | PASS | FAIL | SKIP | Log |
|---|---|---|---|---|---|
| Cargo probes | `./cargo-probes.sh` | 34 | 0 | 0 | `review/evidence/cargo-probes.log` |
| Crate sources and registry figures | `./crate-sources.sh` | 66 | 0 | 0 | `review/evidence/crate-sources.log` |
| GitHub repository figures | `./github-api.sh` | 5 | 0 | 0 | `review/evidence/github-api.log` |
| Decision self-check (revision 1; **superseded**) | `./decision-self-check.sh` | 70 | 0 | 0 | `review/evidence/decision-self-check.log` |
| REST-standard conformance (revision 2) | `./rest-conformance-r2.sh` | 122 | 0 | 0 | `review/evidence/rest-conformance-r2.log` |
| **Total, revision 2** | | **297** | **0** | **0** | |

**Revision 2's check counts, and which script an auditor reruns.** The four revision-1 scripts
and their logs are byte-identical to revision 1 and their counts are carried unchanged: 34, 66,
5 and 70. `decision-self-check.sh` is the one that no longer reruns green, and it is superseded
rather than broken — it asserts revision 1's H1 line and revision 1's sha256 by construction, so
a pass against revision 2 would mean it had been edited, which the revision rules forbid. Its
whole check set is re-executed inside `rest-conformance-r2.sh` against revision 2, which is why
that script's count is 122 rather than the 52 the REST work alone would need. **The script an
auditor reruns for revision 2 is `rest-conformance-r2.sh`**; `decision-self-check.log` stands as
the record of the revision-1 run, and its digest is printed by the r2 script.

**What the revision-2 script executed.** It reads the REST API Design Standard at the blob the
owner ruling pins, re-derives the blob id from the bytes with `git hash-object` so the identity
is content-addressed rather than filename-addressed, asserts each of the **45 quoted rule
lines** at its exact line number, and diffs the whole extraction against the committed snapshot
`review/evidence/snapshots/rest-standard-rules.txt`. It then re-executes the ten-term
absent-vocabulary sweep that grounds the no-carve-out finding, runs the standard's own
kebab-case pattern against the literal path segment `metrics`, checks the segment against the
eight reserved action verbs, asserts every disposition the conformance walk claims is actually
written in the decision, re-executes the OV allocation census and asserts the controller's ledgered `OV-07 R79` row, and re-runs the revision-1
decision-shape, parameter-byte, gate-1 and hygiene checks against revision 2.

Each script exits non-zero on any FAIL, asserts on content rather than on an exit code alone,
carries `set -euo pipefail`, invokes `grep` as `/usr/bin/grep` with its version printed beside
the counts, names every SKIP, and is shellcheck-clean under ShellCheck 0.11.0. The self-check
locates the repository root by walking up from its own path rather than from the working
directory and shells out to `git` nowhere, so it runs unchanged inside a `git archive HEAD`
extraction; it tests for `.git` with `-e`, because a worktree's `.git` is a file.

**What the cargo probes executed, and what each observed.**

| # | Command | Observed |
|---|---|---|
| E1 | `cargo check --locked --features metrics --all-targets` on a manifest whose feature `metrics` and optional dependency `metrics` share a name | compiled; `dep:metrics` suppresses the implicit feature, so R69's feature spelling is legal |
| E2 | `cargo tree -e normal` on two two-crate manifests differing only in `default-features` on the exporter | **37 versus 81** distinct crates; the 44 added include `aws-lc-rs`, `aws-lc-sys`, `rustls`, `hyper`, `hyper-rustls`, `h2`, `tokio-rustls`, `ipnet`; with the defaults off there is no `tokio` edge at all |
| E3 | `cargo tree -e normal` and `cargo build --locked --release` (`strip = true`) with and without the feature, on an axum 0.8.9 + tokio 1.53.1 base carrying R69's feature list | **51 → 79** crates (**+28**, listed by name in the log); stripped binary **1,307,968 B → 1,686,016 B** (**+378,048 B, +28.9%**); `tower-http` absent from both graphs; `tower` present in both, added by `axum`, not by this feature |
| E4 | `cargo generate-lockfile` under `rust-version = "1.96"`, then `cargo metadata --features metrics --filter-platform <host>` joined against the `-e normal --features metrics` crate list | `Locking 118 packages to latest Rust 1.96 compatible versions`; highest declared `rust-version` in the resolved runtime tree is `hashbrown 0.17.1` at **1.85.0**, then `indexmap 2.14.2`, then `axum 0.8.9` at 1.80; **12** packages in that graph declare none |
| E5 | `cargo audit --file Cargo.lock` over the resolved lockfile | `Loaded 1251 security advisories`; `Scanning Cargo.lock for vulnerabilities (119 crate dependencies)`; no vulnerabilities; `RUSTSEC-2021-0113` does not appear — the resolved `metrics-util` is 0.20.4, past that advisory's `>=0.7.0` patch |
| E6 | `cargo test --locked --features metrics --test metrics -- --nocapture` | 1 passed. `distinct http_route label values = {"/v1/boom", "/v1/projects/{id}"}` — 51 requests over 50 distinct ids, **two** label values; `http_server_unmatched_requests_total 1`; no `http_route="/metrics"` after two scrapes |
| E7 | `cargo build --locked --release` with the feature **off** | compiled; `metrics-exporter-prometheus` absent from the normal graph |
| E8 | `promtool check metrics < scrape-sample.txt` — **the check the Opus report left proposed** | **accepted**; 41 lines of exposition text, captured verbatim from the E6 test into `review/evidence/scrape-sample.txt`, parse under the Prometheus project's own parser with no error, invalid or parse complaint |

The acceptance test drives the router in process with `tower::ServiceExt::oneshot` — R69's
recorded idiom — so no port is bound and the test would run identically on both CI runners. The
scrape it produced begins:

```text
# HELP http_server_unmatched_requests_total HTTP requests that matched no route template.
# TYPE http_server_unmatched_requests_total counter
http_server_unmatched_requests_total 1

# HELP http_server_request_duration_seconds Duration of HTTP server requests.
# TYPE http_server_request_duration_seconds histogram
http_server_request_duration_seconds_bucket{http_request_method="GET",http_route="/v1/boom",http_response_status_code="500",le="0.005"} 1
```

**What the source and registry checks executed.** Every crate manifest, feature map and source
line cited in this decision was read from the **published `.crate` tarball** at
`https://static.crates.io/crates/<name>/<name>-<version>.crate`, whose sha256 the log records,
rather than from a rendered documentation page: `metrics` 0.24.6,
`metrics-exporter-prometheus` 0.18.3, `axum-prometheus` 0.10.1, `prometheus-client` 0.25.1,
`prometheus` 0.14.0 and `opentelemetry-prometheus` 0.33.0. crates.io figures came from
`GET https://crates.io/api/v1/crates/<name>` (`crate.recent_downloads`, `crate.downloads`),
`.../versions` (newest `yanked: false`) and `.../reverse_dependencies?per_page=30`
(`meta.total`), at roughly one request per second with the repository URL as User-Agent. RustSec
was read as `https://rustsec.org/packages/<name>.html`, where HTTP 404 means no advisory page
exists. GitHub came from keyring-authenticated `gh api` at one call per 20 seconds, using
`GET /repos/<o>/<r>` and `GET /search/issues?q=repo:<o>/<r>+is:issue+is:open` — the search
endpoint's `total_count`, which the prompt requires, not the repository object's
`open_issues_count`, which it forbids; both are printed in the log so the gap between them is
visible (for `metrics-rs/metrics`, 51 against 83).

**Reproducibility, stated exactly rather than asserted.** Every script above was re-run twice
before this sentence was written: once in place, and once from a clean `git archive HEAD`
extraction into `$TMPDIR` that contains no `.git` at all, with each rerun's output diffed
against the committed log. All four pass from the extraction — 34, 66, 5 and 70 PASS, with
**no FAIL and no SKIP in any of them**. What varies between a rerun and the committed log is
named below, per file, with the rule for comparing across it.

- `cargo-probes.log` is **byte-reproducible except for two header lines: the `$TMPDIR` scratch
  path and the UTC timestamp.** That claim was earned rather than asserted — the script was
  re-run from a clean `git archive HEAD` extraction and the two logs diffed. The first such
  diff **failed**, and the reason is recorded here rather than papered over: the scrape body is
  timing-dependent in three ways that no amount of version pinning removes — the exporter
  renders its two label sets in an unstable order, the observed `_sum` durations differ every
  run, and the occupancy of the smallest latency buckets moves when a request happens to take
  longer than five milliseconds. The script was therefore changed to print a **canonical** form
  of the scrape into the log — sorted, with bucket occupancies and the `_sum` value redacted to
  `<occupancy>` and `<duration>`, and the test's wall time to `<elapsed>` — while keeping every
  series identity, the `_count` value of 51 and the unmatched counter's value of 1, which are
  what the acceptance criteria actually assert. Every crate count, package name and binary byte
  figure is exact, because each probe package's resolved `Cargo.lock` is snapshotted under
  `review/evidence/locks/` on first run and reused with `--locked` afterwards. Deleting
  `locks/` re-resolves against the live registry, and the counts may then move. A second
  extraction rerun surfaced one further difference and it too was fixed rather than excused:
  cargo writes `Blocking waiting for file lock on package cache` to stderr whenever another
  agent in this shared worktree holds the registry lock, so that line is now dropped from the
  log while every other stderr line still reaches it, and a real cargo error is not hidden.
- `review/evidence/scrape-sample.txt` is the **verbatim** capture the promtool parse consumed,
  and it is the one artefact here that is deliberately *not* byte-stable: it is rewritten on
  every run, and its `_sum` values and low-bucket occupancies differ each time for the reasons
  above. What is stable in it is the series identity set, the `_count` value and the absence of
  any `http_route="/metrics"` series. It is committed as the exact bytes promtool accepted in
  the run whose log sits beside it.
- `crate-sources.log` is **byte-reproducible for every tarball sha256 and every quoted source
  line**, because a published `.crate` artifact is immutable. The crates.io counters are not:
  the comparison rule the script enforces is that `num`, `created_at`, `rust_version` and
  `license` must equal the snapshot under `review/evidence/snapshots/` byte-for-byte, and the
  all-time `downloads` counter must not fall. `recent_downloads` is a rolling 90-day window that
  legitimately falls, so it is printed and never asserted.
- `github-api.log` asserts only `full_name` and `archived` against its snapshot — `archived`
  flipping to true is the maintenance signal the check exists to catch. Stars, `pushed_at` and
  the issue `total_count` all move in both directions and are printed as direction of travel
  without assertion, so an honest rerun cannot fail on them.
- `decision-self-check.log` is **byte-reproducible except for its three header lines** — the
  UTC timestamp, the resolved repository root, and the line reporting whether a `.git` is
  present and of what kind. The script reaches `docs/port/PARAMETERS.md`, `research/CLAUDE.md`
  and `docs/port/COMMONALITY.md` through a root it derives by walking up from its own path, so
  it verifies the four parameter lines against the live registry, the F326 line number, and the
  research index row from inside an extraction as readily as from the worktree. Its one
  external dependency is ShellCheck; where that is absent the check is a **named** SKIP rather
  than a silent pass, and it did not fire in either of the two runs recorded here.

**Gate answers for the recommended pair.** Gate 1 is recorded once here and referred to from
the shortlist table below by that reference rather than restated.

| Gate | `metrics` 0.24.6 | `metrics-exporter-prometheus` 0.18.3 |
|---|---|---|
| 1. Licence | `inapplicable — owner ruling 2026-09-12 (Q7.B): licence compatibility is not evaluated for any dependency or tool`. The declared field is recorded without evaluation: crates.io reports `MIT` | Same ruling, same reference. crates.io reports `MIT AND Apache-2.0` |
| 2. MSRV within stable minus 2 (floor 1.96) | The shipped `Cargo.toml.orig:5` reads `rust-version = { workspace = true }`, so the crate's own manifest carries **no literal value**; crates.io `/versions` resolves and publishes it as **1.71.1**. This decision takes the position, explicitly rather than leaving it for an auditor to argue, that a workspace inheritance the registry resolves to a concrete version **is** a declaration for gate 2's purposes: the strict reading settled on 2026-09-11 fails a candidate that declares *nothing*, and a consumer resolving this crate gets 1.71.1 enforced by Cargo exactly as a literal would be — unlike `prometheus-client`, whose `/versions` reports `rust_version: null`. **Pass**, 25 minors of headroom | published `rust-version` **1.71.1** — pass |
| 3. RustSec advisory; `unsafe` posture | `https://rustsec.org/packages/metrics.html` → HTTP 404, so no advisory. `unsafe` posture **corrected against the raw report**: 35 occurrences across **three** files — 27 in `src/cow.rs`, 5 in `src/recorder/cell.rs`, 3 in `src/recorder/mod.rs` — not 34 confined to `src/cow.rs`. All are in a borrowed-or-owned pointer type and the recorder cell, none is a foreign-function call, and the crate carries no `unsafe` on the macro path | `https://rustsec.org/packages/metrics-exporter-prometheus.html` → HTTP 404. **Exactly one** `unsafe` occurrence in the crate, at `src/recorder.rs`. Its dependency `metrics-util` does have an advisory page — `RUSTSEC-2021-0113`, patched `>=0.7.0` — and the resolved 0.20.4 is unaffected (E5) |
| 4. Builds on `ubuntu-latest, macos-latest` | Built, linked and tested on macOS arm64 in this run. **Not built on Linux here** — see `## Engines`. Pure Rust with no C dependency once `default-features = false` removes `aws-lc-sys`, which is the gate-4 argument for turning the defaults off | same |
| 5. Default features and async-runtime coupling | **no `[features]` table at all** in the shipped manifest, and no `tokio` dependency — verified by asserting the absence of both keys | `default = ["http-listener", "push-gateway"]`, **turned off**; with them off there is no `tokio` edge (E2), and `install_recorder` / `build_recorder` are not feature-gated (verified by walking the attribute block above each declaration). The only async touch-point is the upkeep ticker the template spawns |
| 6. Binary-size and compile-time cost | measured jointly (E2, E3): +28 crates and +378,048 B stripped on R69's axum base. Compile time was **not** re-measured here; the Opus report's approximate +8 s on a cold target directory is carried, with its own caveat that run-to-run noise was of the same order | same measurement — the pair ships together and was measured together |

**Qualified shortlist.** Five candidates cleared gate 2 and carry no RustSec advisory. Gate 1
is `inapplicable` for every row by the ruling recorded above. Evidence depth is not uniform and
each row says how far it reaches.

| Candidate | Role | 90-day downloads | All-time | Stars | Last release | Maintenance | Notable adopters | Trade-off, in one line |
|---|---|---|---|---|---|---|---|---|
| `metrics` 0.24.6 | instrumentation facade | 20,185,758 | 108,173,967 | 1,486 (`metrics-rs/metrics`) | 2026-05-13 | **active** — `pushed_at` 2026-09-18T14:54:13Z, 51 open issues, not archived | reth, Vector, apalis, rumqttd | one global recorder per process, so tests need a `OnceLock` |
| `metrics-exporter-prometheus` 0.18.3 | recorder and Prometheus text renderer | 13,007,165 | 47,578,577 | 1,486 (same repository) | 2026-04-30 | **active** (same signals) | reth, at this exact pin and this exact `default-features = false` form | the defaults pull a whole HTTP and TLS stack you do not want, and upkeep is the caller's job |
| `axum-prometheus` 0.10.1 | axum middleware over the `metrics` facade | 1,388,212 | 5,658,682 | 92 (`Ptrskay3/axum-prometheus`) | 2026-07-31 | **active** — `pushed_at` 2026-07-31T07:07:09Z, 10 open issues, single maintainer | downstream service templates | gives an in-flight gauge, a body-size histogram and ignore patterns; costs `tower-http` 0.7.1 in the runtime graph (measured) and a per-axum-major treadmill |
| `prometheus` 0.14.0 | registry-object client (tikv) | 24,842,546 | 145,764,833 | 1,181 (`tikv/rust-prometheus`) | 2025-03-27 | **stable-quiet** — 18 months since release, `pushed_at` 2025-12-31T07:01:42Z, 66 open issues, **but** no advisory, no maintainer notice and no broken build, so the rubric forbids `at-risk` | TiKV, Neon; `opentelemetry-prometheus` 0.33.0 depends on it | highest raw volume in the field, but you thread `HistogramVec` handles through app state, and `default = ["protobuf"]` (read at source) |
| `opentelemetry-prometheus` 0.33.0 | OTel-metrics to Prometheus bridge | 2,518,260 | 14,203,757 | 2,708 (`open-telemetry/opentelemetry-rust`, whole-project repository) | 2026-09-18 | **active** — released the day of retrieval, 218 open issues across the whole project | OTel users needing scrape instead of OTLP | passes every gate, but its own README steers new projects to `opentelemetry-otlp`, and it drags `prometheus` 0.14 in transitively |

`prometheus` and `opentelemetry-prometheus` were assessed from their published manifests and
sources only; they were not built or tree-walked in this run, and the rows say so rather than
implying uniform depth. The `metrics` pair and `axum-prometheus` were all three resolved and
tree-walked, and the first two were built and tested.

**Excluded by gate.** Gate 2 is applied under the strict reading settled by the owner on
2026-09-11 and recorded in `docs/planning/p02/owner-decisions.md`: a candidate that declares no
`rust-version` fails the gate.

| Candidate | Gate failed | Evidence, re-read at source |
|---|---|---|
| `prometheus-client` 0.25.1 — the Prometheus organisation's own Rust client | **Gate 2**, no `rust-version` declared | `prometheus-client-0.25.1/Cargo.toml.orig` from the published tarball has no `rust-version` key, asserted as an absence; crates.io `/versions` reports `rust_version: null`. A painful exclusion — 606 stars, `pushed_at` 2026-09-14T11:44:30Z, typed labels, OpenMetrics output, no global state — and it is recorded as a re-verify trigger |
| `autometrics` 3.0.0 | **Gate 2** (crates.io `/versions` reports `rust_version: null`) **and maintenance rubric `dormant`** | the repository README's own notice, "Autometrics is no longer actively maintained" — a maintainer's own statement, which the rubric names as sufficient for `dormant` |
| `axum-otel-metrics` 0.14.1 | **Gate 2**, no `rust-version` (crates.io `/versions`, `rust_version: null`) | also the smallest candidate surveyed, and architecturally inside the rejected alternative D |
| Log-based metrics / Cloud Monitoring, the owner reference's first suggestion | **Capability**, not a fitness gate | it cannot produce a duration histogram with bucket boundaries, so it cannot satisfy the D of RED. Recorded as the `DIFFER` row above |

**Ranked runner-up, and the condition under which it wins.** `axum-prometheus` 0.10.1 —
`rust-version = "1.75"` (`Cargo.toml.orig:8`), `default = ["prometheus"]` (`:32`), zero
`unsafe` in `src/lib.rs`, no RustSec page, and it independently pins
`metrics-exporter-prometheus = { version = "0.18.3", optional = true, default-features = false }`
(`:18`) — i.e. it reached the same `default-features = false` conclusion. **It wins if the
template decides RED is not enough** and wants the in-flight gauge and body-size histogram out
of the box, plus a declarative ignore list that R80's probe paths and `/metrics` join in one
line. What tips it to second place is measured, not argued: it adds `tower-http` 0.7.1,
`bitflags` and itself to the runtime graph (**82 crates against the recommended 79** on the
identical base), and R75 has not chosen a `tower-http` version — the owner reference names
`tower-http 0.6` at C11, so adopting 0.7.1 here would create a version-skew risk between two
unpublished items. Its `tokio = { version = "1.53", features = ["rt-multi-thread", "macros"] }`
(`:21`) is non-optional, and its `Handle::default()` calls
`metrics::set_global_recorder(recorder).expect("Failed to set global recorder")`
(`src/lib.rs:892`) unconditionally, so a second layer construction in one test binary panics —
at which point the template would wrap it in a `OnceLock` anyway and have re-implemented most of
the convenience.

**Up-and-comer worth a later look.** `measured` 0.0.25 is the most interesting *design* in the
field — label sets are types, so high cardinality becomes a compile-time conversation — and it
has one verifiable production user in Neon. Two reasons it is not shortlisted for a **template**:
`0.0.25` offers no semver breakage protection, which is a poor default for code other people
copy, and the one verified adopter employs the author, so the independent-adoption evidence is
thin. Worth re-verifying at its 0.1.0.

**Migration implications — file-level changes in the template**, written against R69 revision
10 and R02 revision 2's four-package workspace. No file outside `crates/web/`, the serve binary
and the two manifests changes.

| File | Change |
|---|---|
| `Cargo.toml` (root package `rs-launch-blueprint`) | add `metrics = ["web", "rs-launch-blueprint-web/metrics"]` to `[features]`. No new dependency on the root package |
| `crates/web/Cargo.toml` | add the two optional dependencies and `[features] metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]` exactly as shown above |
| `crates/web/src/obs/metrics.rs` (new, about 70 lines) | `recorder()`, `run_upkeep()`, `track()`, `count_unmatched()`, `instrument()`, the two name constants and the bucket constant. `recorder()` and `run_upkeep()` must be `pub`, because the ticker is spawned from the root package's serve binary |
| `crates/web/src/obs/mod.rs` (new) | `pub mod metrics;`, declared from `crates/web/src/lib.rs` as `#[cfg(feature = "metrics")] pub mod obs;` |
| `crates/web/src/lib.rs` (`build_router`) | wrap the business router: `#[cfg(feature = "metrics")] let router = obs::metrics::instrument(router);`, applied to the `/v1` nested router **before** `ops::router()` is merged. The `metrics`-off build is byte-for-byte what R69 describes |
| `crates/web/src/` router fallback | the 404 fallback handler gains one gated line, `#[cfg(feature = "metrics")] obs::metrics::count_unmatched();` |
| `src/bin/<app>-serve.rs` (the R69 serve binary, in the **root** package) | one gated `tokio::spawn(rs_launch_blueprint_web::obs::metrics::run_upkeep(handle))` beside `axum::serve(...)`. It needs no shutdown handling: the task dies with the runtime and holds no state that must be flushed |
| `crates/web/tests/metrics.rs` (new) | the acceptance test above, with no file-level `#![cfg(feature = "web")]` because the whole member is optional (R69 revision 10) |
| `.github/workflows/ci.yml` (R11 owns the shape) | the web job's feature selector becomes `--features metrics` or `--all-features`, so the new code and its test are compiled and run; path-based skip-gating already keys on `crates/web/**` |
| `README.md` / web quickstart | the web example command becomes `cargo run --features metrics --bin <app>-serve`, because `--features web` alone does **not** enable metrics under R69's nesting |
| `docs/port/COMMONALITY.md` F326 | no wording change proposed; no `BASELINE-REVIEW:` raised |

`cargo deny` must run as `cargo deny --all-features check bans` — R02 revision 2's executed
finding, `CD5a`–`CD5d` — or the optional `crates/web` member and therefore both metrics crates
are absent from the resolved graph entirely.

## Engines

- **Claude Opus 5** — `raw/opus.md`, sha256
  `c1d02b81cd0929881f66c7810af782496a84f73a8f45472e86e773a0300145ac`, 15 H3 sections, passing
  `validate_answer_text(text, "crate")` with no diagnostics.
- **Codex — absent, by the controller's deferral under owner ruling W1-CODEX3 of 2026-09-18**
  (the Codex account is at its usage limit; the ruling is to proceed without it). This Focused
  item's prompt requires the engines `codex, opus`; **one of the two ran**. The consequence is
  recorded rather than papered over: there is no independent second model family on this item,
  so nothing in the report was checked by an adversarial lens before reaching this synthesis.
  **Every load-bearing claim was therefore re-verified at source by this synthesizer**, and the
  two tables below say exactly which claims were re-executed and which are carried on the single
  engine's word.

**A note on validation shape, because the task message names a validator the artefact is not
shaped for.** `validate_answer_text(text, "crate")` checks the fifteen H3 answer fields of a
*raw report*; a `DECISION.md` carries the four H2 sections `synthesizer.md` mandates plus one
`### Principles and implementation`, which is what `_validate_decision_text` in the same module
checks (`scripts/research_validation.py:489`–`:507`) and what the accepted R68 decision follows.
The validator was run against `raw/opus.md`, where it applies, and returned no diagnostics; the
decision's shape follows the role contract.

**Re-verified at source by this synthesis — reproduced exactly.**

| Claim | How it was re-verified | Result |
|---|---|---|
| crates.io figures for all nine surveyed crates (downloads, newest non-yanked version, `created_at`, `rust_version`, `license`) | `GET https://crates.io/api/v1/crates/<name>` and `.../versions`, 2026-09-18 | every figure in the shortlist and exclusion tables reproduced exactly **as retrieved on 2026-09-18**. The 90-day download column is a rolling window and a later rerun will legitimately differ from the numbers printed in those tables; the comparison rule recorded above is what a rerun enforces instead |
| reverse-dependency totals: `metrics` 1,199, `metrics-exporter-prometheus` 460 | `.../reverse_dependencies?per_page=30`, `meta.total` | exact |
| GitHub stars, `archived`, `pushed_at` and open-issue `total_count` for all five shortlisted repositories | keyring-authenticated `gh api`, one call per 20 s | 1,486/51, 92/10, 1,181/66, 606/44, 2,708/218 — all exact; none archived |
| exporter `default = ["http-listener", "push-gateway"]`; the upkeep contract; the `#[cfg(any(...))]` gate on `install()`/`build()` at `:443` and `:531`; `install_recorder` at `:506` and `build_recorder` at `:605` ungated; the 5-second `upkeep_timeout` default at `:88` | published tarball, sha256 recorded | every line number and every claim exact. The report's `:443-448` citation is the multi-line attribute at `:443`–`:447` |
| `axum-prometheus`: `tower-http = "0.7"`, non-optional `tokio`, `default = ["prometheus"]`, the `/metrics` sample scrape at `src/lib.rs:73`, the unconditional `set_global_recorder(...).expect(...)` at `:892`, `run_upkeep` at `:889`, `with_ignore_pattern` at `src/builder.rs:89`, the `EndpointLabel::MatchedPath` fallback at `:28` | published tarball | exact |
| `prometheus-client` 0.25.1 declares no `rust-version`; `prometheus` 0.14.0 `default = ["protobuf"]`; `opentelemetry-prometheus` depends on `prometheus` 0.14 and its README steers to `opentelemetry-otlp`; the `autometrics` retirement notice | published tarballs and `raw.githubusercontent.com` | exact — this discharges the report's own "gates 3–6 read, not built" gap for these three |
| axum's own example at tag `axum-v0.8.9`: the "tower-http will hopefully have a metrics middleware" comment, `PrometheusBuilder`/`install_recorder`, `route_layer`, and the **absence** of `run_upkeep` | `raw.githubusercontent.com`, sha256 of both files recorded | exact, including the defect |
| RustSec: HTTP 404 for `metrics`, `metrics-exporter-prometheus`, `axum-prometheus`, `prometheus`, `prometheus-client`, `opentelemetry-prometheus`, `autometrics`, `measured`, `quanta`; HTTP 200 with `RUSTSEC-2021-0113` for `metrics-util` | `https://rustsec.org/packages/<name>.html` | exact |
| 37 versus 81 crates on the exporter default-feature delta | E2 | exact |
| 51 → 79 crates (+28) for the `metrics` feature on R69's axum base | E3 | exact |
| `Locking 118 packages to latest Rust 1.96 compatible versions`; highest declared tree `rust-version` is `hashbrown` 0.17.1 at 1.85.0 | E4 | exact |
| `cargo audit`: 1,251 advisories, 119 crate dependencies, no vulnerabilities | E5 | exact |
| the six acceptance criteria, including 50 distinct URIs producing one label value and no `/metrics` series after two scrapes | E6 | exact |
| `axum-prometheus` footprint of 82 crates on the identical base | runner-up probe | exact |
| py's `excluded_handlers=["/metrics", "/healthz", "/readyz"]`, `include_in_schema=False`, and `prometheus-fastapi-instrumentator>=7.0.0` inside the `web` extra | `git show` at pin `b08bccfb55d05f15e46a83b52c5660b1881d19f5` | exact, including that the exclusion set is three paths and that the dependency is in `web`, not `otel` |

**Claims found wrong, not reproduced, or reproduced only in part.**

| Report claim | What was observed | Disposition |
|---|---|---|
| `metrics`' `unsafe` is "34 occurrences, all in `src/cow.rs`" | **35** occurrences across **three** files: 27 in `src/cow.rs`, 5 in `src/recorder/cell.rs`, 3 in `src/recorder/mod.rs` | **Wrong, and the confinement half is the load-bearing half.** Gate 3 is restated above with the measured figures. It does not change the recommendation: none of the eight occurrences outside `src/cow.rs` is a foreign-function call, and the crate still carries no `unsafe` on the macro path |
| stripped binary `1,256,896 B → 1,617,952 B`, delta `+361,056 B` | `1,307,968 B → 1,686,016 B`, delta **+378,048 B** | **Not reproduced exactly, and could not be**: the two probe binaries are not the same program. Both were built with `strip = true` on the same axum and tokio pins. The load-bearing figure is the delta, and it agrees to 4.7%: the cost is **about +0.36 to +0.38 MB, roughly +29%**. Both figures are shown rather than one silently preferred |
| "Twenty packages in the tree declare no `rust-version`" | **12**, in the `cargo tree -e normal --features metrics` runtime graph | **Different scope, not reconciled by guessing.** The report's 20 is over a wider set (the 118-package lock includes dev-dependencies and both feature states); this decision's 12 is the graph gate 2 is actually asked about, and the figure is reported with that scope stated |
| "it is the only family in which *both* crates declare a `rust-version` (1.71.1)" | `metrics` 0.24.6's shipped `Cargo.toml.orig:5` reads `rust-version = { workspace = true }` — **no literal value in the crate's own manifest**; 1.71.1 is what crates.io `/versions` resolves it to | **Half-wrong at source, and it touches a gate.** It does not change the verdict: the gate-2 cell above now takes an explicit position that a registry-resolved workspace inheritance is a declaration, and says why that is different from `prometheus-client`'s `rust_version: null` |
| compile time approximately +8 s cold, "noisy" | **not re-measured** | **Carried on the single engine's word**, with its own caveat that run-to-run noise on a warm registry cache was of the same order. The crate count and the binary bytes are the robust figures and both were re-measured |
| issue-responsiveness medians (0.57 days for `metrics-rs/metrics` over 7 answered-or-not issues; 10.3 days for `Ptrskay3/axum-prometheus`) | **not re-collected** | **Carried.** Re-collecting them needs a per-issue comment walk at one call per 20 s across 14 issues, which was not run. Neither figure triggers `at-risk` under the rubric, which needs a concrete signal, and none exists for either repository |
| reth, Vector and Neon adopter manifests at `raw.githubusercontent.com` | **not re-fetched** | **Carried**, with their retrieval date. The claim that reth pins this exact version in this exact `default-features = false` form is the report's, not this synthesis's retrieval |

**Unproven, and left for P03 to prove in the real template.**

1. **Nothing was built on `ubuntu-latest`.** Gate 4 for the recommended pair rests on the
   executed macOS build plus both crates being pure Rust with no C dependency once
   `default-features = false` removes `aws-lc-sys` — not on a green Linux job anyone watched.
   P03 proves it by running the same `--features metrics` job on both matrix runners.
2. **`cargo hack --each-feature check --workspace`** — proves `metrics` on and off both compile
   and that `metrics` cannot be enabled without `web`. Needs the real workspace.
3. **`cargo deny --all-features check bans licenses advisories`** in the real four-package
   workspace, in R02's executed argument order.
4. **An end-to-end scrape against the real serve binary.** E8 parsed the in-process scrape under
   `promtool check metrics` and it passed, which retires the exposition-format question; what
   remains unproven is the same check against a bound listener with the upkeep ticker running.
5. **An OpenAPI-exclusion assertion once R71 publishes** — `jq -e '.paths | has("/metrics") | not'`
   over the generated document, wired into R71's snapshot gate rather than duplicated here.
6. **A memory-shape check for upkeep**: record a large number of observations across a handful of
   label sets, run the ticker, and assert that process RSS plateaus. This is the only claimed
   behaviour the in-process acceptance test cannot reach, and the one whose absence would hurt
   most in production.
7. **No adoption survey figure.** No Rust annual-survey question enumerating metrics crates was
   retrieved by either the report or this synthesis; adoption evidence is registry counts and
   named projects, and that limit is stated rather than filled.
8. **Whether a `MEMBER`/`OWNER` issue reply is substantive rather than triage** was not judged by
   either the report or this synthesis; the responsiveness figure is time to first maintainer
   comment.

**Revision history.**

| Revision | sha256 | What it changed |
|---|---|---|
| 1 | `2e804161b9fbe65c7d33be04de5e024612ce628e1ea914c4e636443e0f0885c3` | The decision as first written from `raw/opus.md`, with the Codex leg absent under W1-CODEX3 and every load-bearing claim re-verified at source. Checks 34 / 66 / 5 / 70 = 175 PASS. Committed at `fca40a5` after three repairs to its own reproducibility claims |
| 2 | this file | **Pre-audit revision** under owner ruling W2-REST (2026-09-18). Adds the conformance walk against the REST API Design Standard v2.0.0 at blob `71bd813c…`: 45 rule lines quoted at their line numbers, 21 dispositions, three **MOVED** rows that change the recommendation's HTTP behaviour, two departures recorded under the controller-allocated `OV-07`. Extends the re-verify line with five W2-REST triggers. Records, rather than drops, a false OV census caused by a truncated search, and takes the controller's central allocation over it. **No crate, version, feature name, metric name, label, parameter line, ledger disposition or gate answer moves.** Adds `rest-conformance-r2.sh` (122 PASS) and supersedes `decision-self-check.sh` |

**Disagreements between engines: none to settle.** With one registered engine there is no
inter-engine disagreement. The disagreements recorded above are between the single report and
this synthesis's own re-execution, and each is settled by the executed check named beside it.
Three additions this synthesis makes that the report did not carry are flagged as such: the
disposition of R77's `RSLBP_WEB_METRICS_ENABLED`; the finding that **no item currently owns**
excluding R80's probe paths from metrics measurement, since R80 takes "No position" and R75 owns
only the access-log exclusion; and the executed `promtool` conformance parse, which the report
proposed and did not run.
