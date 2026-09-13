### Landscape

**Decision category:** an optional, application-level async HTTP adapter bundle for a Rust CLI + library + web-service template. It covers framework, server/runtime, application state, startup/shutdown lifecycle, feature gating, in-process testing, and development restart tooling—not business middleware or OpenAPI/telemetry library selection.

**Research date:** September 12, 2026. Rust stable is **1.98.1**, making the owner’s “stable minus two minor versions” floor **Rust 1.96**. `rust-version = "1.96"` is therefore the required manifest value. Source: `https://blog.rust-lang.org/releases/` and `https://doc.rust-lang.org/releases.html` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))

> **Evidence-completeness note:** the official documentation, repositories, release pages, RustSec index, adopter manifests, and benchmark pages were retrieved. The raw JSON bodies from the mandated crates.io and GitHub API endpoints were not obtainable in this research execution, so I have not invented download counts, API star counts, API open-issue totals, or issue-response medians. Those fields are marked pending and the exact collection commands are included under `### Validation strategy`. Consequently, the architectural recommendation is decision-ready, but the §7.6 quantitative ledger is not acceptance-ready until those commands are run.

#### Three-bin map

| Bin | Landscape | Relevance |
|---|---|---|
| **Built-in or first-party toolchain** | Rust `std` has networking primitives but no production async HTTP framework. Within the dominant async ecosystem, Tokio supplies runtime/network/signal/time facilities; Hyper supplies HTTP; Tower supplies `Service`/`Layer`; Axum is the Tokio project’s first-party ergonomic web layer over them. | Best composability and lowest architectural distance from the broader Tokio ecosystem. Axum explicitly states that it is designed for Tokio and Hyper and uses Tower rather than inventing a middleware system. Source: `https://docs.rs/axum/0.8.9/axum/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| **Established industry standard** | **Axum 0.8.9**, **Actix Web 4.15.0**, Warp 0.4.3, and Rocket 0.5.x. Axum and Actix are the serious finalists; Warp and Rocket remain credible but fit this template less well. | Axum and Actix both have mature JSON, state, middleware, testing, and production server stories. Actix has a more integrated server; Axum has stronger Tower/Hyper/Tonic interoperability. Current version evidence: `https://github.com/tokio-rs/axum`, `https://docs.rs/actix-web/latest/actix_web/`, and `https://docs.rs/crate/warp/latest` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/axum)) |
| **Up-and-comer** | Poem and its OpenAPI companion, Salvo, Pavex, Xitca Web, and higher-level Axum frameworks such as Loco. | Worth monitoring. Poem is the closest functional alternative where tightly integrated OpenAPI is the primary selection criterion; Pavex offers a distinctive build-time architecture. Their production-adopter and prescribed macOS-CI evidence was weaker in this survey. Source leads: `https://docs.rs/poem/latest/poem/` and the maintained comparison map at `https://github.com/flosse/rust-web-framework-comparison` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/poem/latest/poem/)) |

#### Authorities used

| Authority | Why it counts |
|---|---|
| Rust Release Team and annual Rust survey | Primary evidence for the supported stable toolchain and broader ecosystem practice—not a framework ranking. Sources: `https://blog.rust-lang.org/releases/` and `https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/releases/)) |
| Tokio/Axum maintainers’ docs and repository | Primary evidence for runtime coupling, state, Tower integration, serving, release state, and official examples. Sources: `https://docs.rs/axum/0.8.9/axum/`, `https://docs.rs/tokio/1.53.1/tokio/`, and `https://github.com/tokio-rs/axum` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| Actix, Warp, and Poem maintainers’ docs | Primary evidence for the alternative frameworks’ current APIs and releases. Sources: `https://docs.rs/actix-web/latest/actix_web/`, `https://docs.rs/crate/warp/latest`, and `https://docs.rs/poem/latest/poem/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/actix-web/latest/actix_web/)) |
| RustSec | Authoritative advisory index. Package counts include historical advisories and are not equivalent to an advisory affecting the current lockfile; `cargo audit` remains the acceptance test. Source: `https://rustsec.org/packages/` (retrieved 2026-09-12). ([rustsec.org](https://rustsec.org/packages/)) |
| TechEmpower | Widely cited independent throughput evidence, useful only as a performance ceiling/cross-check. Its workloads do not include this template’s complete validation, configuration, OpenTelemetry, metrics, error, and graceful-shutdown path. Source: `https://www.techempower.com/benchmarks/` (retrieved 2026-09-12). ([techempower.com](https://www.techempower.com/benchmarks/)) |
| Current adopter source trees | Direct evidence of actual framework use. The Rust package registry migrated to Axum; its OpenAPI description is generated through an Axum integration. Qdrant’s current lockfile resolves Actix Web. Sources: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`, `https://github.com/rust-lang/crates.io`, and `https://github.com/qdrant/qdrant/blob/master/Cargo.lock` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/)) |

#### Practice evidence

- **Axum:** crates.io is an unusually relevant adopter because it is a production Rust HTTP service maintained inside the Rust project, handles uploads, authentication, background work and API traffic, and reports having migrated to Axum. It also demonstrates that Axum does not prevent generated OpenAPI: crates.io uses an Axum-compatible OpenAPI integration. Source: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))
- **Actix Web:** Qdrant’s current source resolution includes `actix-web`, demonstrating continuing use in a substantial network service. Source: `https://github.com/qdrant/qdrant/blob/master/Cargo.lock` (retrieved 2026-09-12). ([github.com](https://github.com/qdrant/qdrant/blob/master/Cargo.lock))
- **Warp and Poem:** both remain maintained framework lines, but this survey did not establish an equally strong current adopter reference satisfying the owner’s adopter-evidence rule. That evidence gap counts against them; it is not proof of non-use.

#### Fitness gates before popularity

| Candidate | License | MSRV | Advisory/unsafe posture | Prescribed OSs | Runtime/defaults | Cost and result |
|---|---|---|---|---|---|---|
| **Axum 0.8.9** | MIT; compatible | Published MSRV 1.80, below floor 1.96 | Historical `axum-core` advisory exists; current lock must pass `cargo audit`. Template code forbids unsafe; transitive unsafe is audited rather than assumed absent. | Tokio explicitly supports Linux and macOS; Axum also has cross-target docs builds. | Tokio/Hyper coupled by design; defaults disabled in the recommendation. | Moderate compile/binary cost with selected features. **Pass, pending lock audit.** ([github.com](https://github.com/tokio-rs/axum)) |
| **Actix Web 4.15.0** | MIT OR Apache-2.0 | Upstream states Rust 1.88+, below floor 1.96 | Historical advisories exist in the Actix family; current lock must pass `cargo audit`. | Cross-platform Tokio-compatible stack; template matrix still must prove Ubuntu/macOS. | Integrated Actix server/service middleware; feature-rich defaults should be trimmed. | Somewhat broader baseline dependency surface. **Pass, pending lock audit.** ([github.com](https://github.com/actix/actix-web)) |
| **Warp 0.4.3** | MIT | Below current floor | Historical fixed advisory; resolved lock still audited. | Tokio/Hyper based; expected on both required Unix hosts. | Filter-combinator API; Tokio runtime. | Compile-time type complexity and rejection composition reduce template clarity. **Passes basic gates; loses on fit.** ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099)) |
| **Poem 3.x** | Compatible upstream line | Appears compatible | Lock audit required | No sufficiently authoritative upstream macOS test statement was established in this pass. | Tokio-based, more batteries included. | Attractive OpenAPI integration, but weaker production/adopter evidence. **Provisionally excluded by gate 4 evidence.** ([docs.rs](https://docs.rs/poem/latest/poem/)) |
| **cargo-watch 8.5.3** | CC0-compatible | Old but buildable | External tool | Shipped cross-platform | Cargo-specific watcher | Repository archived January 18, 2025. **Excluded: archived.** ([github.com](https://github.com/watchexec/cargo-watch)) |
| **Bacon 3.24.x** | AGPL-3.0 | MSRV 1.85 | External tool | Cross-platform | TUI/job runner | Active and capable, but fails the owner’s strict dependency/tool license rubric. **Excluded by gate 1.** ([github.com](https://github.com/Canop/bacon)) |
| **Watchexec CLI 2.5.1** | Apache-compatible upstream license; recheck manifest before pin | Rust 1.93, below floor 1.96 | External process; not linked | Release artifacts include Apple Darwin and Linux | Runtime-independent process watcher | Active, supports graceful stop/restart and bounded stop timeout. **Pass.** ([github.com](https://github.com/watchexec/watchexec/releases)) |

### Principles and implementation

#### Shared requirement and agreement levels

| Principle | Required agreement level | Observable behavior |
|---|---|---|
| Optional web capability | **Policy/capability**, already owner-fixed | Base CLI/library builds without the web adapter; one documented opt-in enables the complete base HTTP surface. |
| Explicit composition root | **Architectural pattern** | One function assembles routes and application state; one production `main` loads settings and resources. |
| One validated configuration snapshot | **Behavioral standard** | Configuration is loaded and validated once before binding; handlers never read the environment or invoke the loader. Tests can supply independent configurations. |
| Framework-native dependency access | **Architectural pattern**, mechanism may vary | FastAPI dependencies, Hono/tRPC context, and Axum state may differ while preserving explicit request-scoped access to app-owned dependencies. |
| In-process testability | **Capability** | Handler/router tests run without binding a TCP port or starting a separate process. |
| Bounded graceful shutdown | **Behavioral standard** | SIGTERM/Ctrl-C stops admission, drains in-flight work, and force-ends after a configured duration. |
| Fast development loop | **Developer policy** | Source edits rebuild and restart the server; development defaults to readable console logs while production defaults to structured JSON. |
| Instrumentation compatibility | **Capability/interface standard** | R75/R78/R79 can wrap the router with ordered HTTP middleware, traces, and metrics without handlers depending on exporter implementations. |

What **must not** be standardized across languages is a low-level DI container, lifecycle callback API, watcher, or server executable. Python’s lifespan/dependency system, Hono/tRPC context factories, and Axum state are justified ecosystem differences.

The TypeScript snapshot’s missing server is a missing capability relative to the later Hono/tRPC owner direction, not evidence that Rust should omit its already-approved web feature.

#### Architectural alternatives

1. **Global/lazy configuration singleton**  
   Rejected. It makes parallel tests configuration-order-dependent and can create two snapshots if startup and fallback paths race.

2. **Explicit app state passed to router construction**  
   Selected. Axum’s `State<S>` and `Router::with_state` are its documented mechanism; merged/nested routers share a state type. Source: `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

3. **Integrated server with framework-owned lifecycle**  
   Actix’s approach is excellent and gives shorter bounded-shutdown configuration. It is the runner-up architecture.

4. **Composable Router/Service plus an explicit process lifecycle**  
   Selected. `axum::serve` exposes graceful shutdown; Tokio supplies signals and timeouts. This keeps the app factory independently testable and avoids another server crate for plain HTTP. Source: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))

5. **Public nested Cargo features for every web layer**  
   Rejected for the base surface. Cargo features are additive and public; a `web-openapi`/`web-metrics` hierarchy would multiply CI combinations and make the nine downstream consumers guess which combination constitutes “the web service.”

6. **One public `web` umbrella gate**  
   Selected. Later research items may add their web-only dependencies to this feature. A new independently user-visible compile-time capability requires its owner to justify a separate feature explicitly.

#### Framework comparison

| Framework | Maturity/dependability | Middleware | Testing/configuration | Performance evidence | Fit |
|---|---|---|---|---|---|
| **Axum** | Active Tokio-project framework; current stable line 0.8.9, with 0.9 under development but no fixed release date. Production use includes crates.io. | Native Tower `Service`/`Layer`; reusable with Hyper/Tonic and compatible instrumentation layers. | `State<S>`, `with_state`, `Router::merge/nest`, and `ServiceExt::oneshot`. | TechEmpower places representative Axum implementations in the high-throughput Rust tier, but not with this template’s full instrumentation. | **Best overall.** ([github.com](https://github.com/tokio-rs/axum)) |
| **Actix Web** | Active 4.x stable line, mature integrated server and service factory. | Strong but Actix-specific `Transform`/service ecosystem. | `web::Data`, application factory closure, and Actix test service utilities. | Historically competitive in narrow HTTP benchmarks; must be tested on the actual workload rather than assumed faster. | **Runner-up.** Wins when integrated server controls or measured resource efficiency dominate. ([docs.rs](https://docs.rs/crate/actix-web/latest)) |
| **Warp** | Current 0.4.3 line but lower architectural momentum than Axum. | Filter composition rather than Tower-first app composition. | `warp::test` is good, but state and errors commonly become closure/filter plumbing. | Capable, but no representative instrumented advantage established. | Qualified but not preferred for a teaching template. ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099)) |
| **Poem** | Maintained, full-featured, good companion OpenAPI story. | Framework-specific middleware/endpoint model. | Explicit data and test client. | Insufficient comparable production/instrumented evidence in this survey. | Best challenger if R71 decides first-party-style OpenAPI integration outweighs Tower interoperability. ([docs.rs](https://docs.rs/poem/latest/poem/)) |

#### Performance conclusion and limitation

No public benchmark found compares these frameworks using all of the required path: representative inbound JSON, semantic validation, typed errors, R01 application call, route-aware tracing, metrics recording, and production-equivalent middleware. TechEmpower is useful to reject the claim that Axum is intrinsically slow, but it cannot select the winner for this template. Its implementations, hardware, database paths, feature sets, and instrumentation differ from the proposed service. Source: `https://www.techempower.com/benchmarks/` (retrieved 2026-09-12). ([techempower.com](https://www.techempower.com/benchmarks/))

The required follow-up benchmark should have two workloads:

- **Adapter ceiling:** 1 KiB `POST` JSON, semantic validation, in-memory R01 fake, success/error serialization.
- **Service-like:** same route plus a 1 ms simulated async application dependency, selected R75/R78/R79 layers and a local telemetry collector.

Measure throughput, p50/p95/p99 latency, CPU-seconds per million requests, peak RSS, release binary size, and clean/incremental compilation on identical hardware. Actix replaces Axum only if it produces a material SLO or resource improvement in that workload—not merely a higher plaintext/JSON microbenchmark rank.

#### Configuration lifecycle

Load and validate the R77 settings type once in the web binary. Derive:

- process-only server settings: bind address and graceful-shutdown duration;
- an immutable `Arc<ValidatedWebConfig>` projection containing only handler-relevant values;
- the R01 application service/port implementation.

Pass those into `WebState`, then call `build_router(state)`. Handlers use `State<WebState<_>>`. Tests construct their own `ValidatedWebConfig` and fake application boundary. There is no hidden startup hook and therefore no need for Python’s lazy fallback.

This is stronger than a fallback: direct calls to the public router factory cannot omit state, while handler functions remain private to discourage bypassing the composition root.

#### Minimal Cargo shape

```toml
[package]
edition = "2024"
rust-version = "1.96"

[features]
default = []
web = [
  "dep:axum",
  "dep:tokio",
  "dep:tower",
]

[dependencies]
axum = {
  version = "0.8.9",
  optional = true,
  default-features = false,
  features = [
    "http1",
    "json",
    "matched-path",
    "original-uri",
    "query",
    "tokio",
    "tracing",
  ],
}
tokio = {
  version = "1.53.1",
  optional = true,
  default-features = false,
  features = [
    "macros",
    "net",
    "rt-multi-thread",
    "signal",
    "sync",
    "time",
  ],
}
tower = {
  version = "0.5.2",
  optional = true,
  default-features = false,
  features = ["util"],
}

[[bin]]
name = "rs-launch-blueprint-web"
path = "src/bin/rs-launch-blueprint-web.rs"
required-features = ["web"]

[[test]]
name = "web"
path = "tests/web.rs"
required-features = ["web"]
```

`matched-path` is included so R78/R79 can use route templates rather than raw, high-cardinality URLs. `query` anticipates the separately owned pagination layer. HTTP/2, WebSockets, multipart, form handling, TLS, and Axum macros are not in the base surface.

No direct `hyper` dependency is declared: Axum owns the compatible Hyper 1.x relationship. No `tower-http`, OpenAPI, validation, OpenTelemetry, or metrics implementation crate is selected here.

#### Minimal endpoint and R01 boundary

```rust
// src/web/app.rs
use std::{future::Future, sync::Arc};

use axum::{
    extract::State,
    http::StatusCode,
    routing::post,
    Json, Router,
};
use serde::{Deserialize, Serialize};

#[derive(Debug)]
pub struct ApplicationError;

#[derive(Debug)]
pub struct ValidationError;

// Illustrative application boundary. R01 may supply a generic implementation
// or an Arc-backed dynamic adapter without changing the handler contract.
pub trait WidgetApplication: Clone + Send + Sync + 'static {
    fn create(
        &self,
        command: CreateWidgetCommand,
    ) -> impl Future<Output = Result<Widget, ApplicationError>> + Send;
}

#[derive(Clone)]
pub struct ValidatedWebConfig {
    pub max_widget_name_bytes: usize,
}

#[derive(Clone)]
pub struct WebState<A> {
    pub config: Arc<ValidatedWebConfig>,
    pub application: A,
}

#[derive(Deserialize)]
pub struct CreateWidgetRequest {
    pub name: String,
}

pub struct CreateWidgetCommand {
    pub name: String,
}

impl CreateWidgetRequest {
    fn validate(
        self,
        config: &ValidatedWebConfig,
    ) -> Result<CreateWidgetCommand, ValidationError> {
        if self.name.is_empty()
            || self.name.len() > config.max_widget_name_bytes
        {
            return Err(ValidationError);
        }

        Ok(CreateWidgetCommand { name: self.name })
    }
}

pub struct Widget {
    pub id: String,
    pub name: String,
}

#[derive(Serialize)]
pub struct CreateWidgetResponse {
    pub id: String,
    pub name: String,
}

// The concrete envelope and status mapping are owned by R70.
pub struct WebError;

impl WebError {
    fn validation(_: ValidationError) -> Self {
        Self
    }

    fn application(_: ApplicationError) -> Self {
        Self
    }
}

async fn create_widget<A>(
    State(state): State<WebState<A>>,
    Json(input): Json<CreateWidgetRequest>,
) -> Result<(StatusCode, Json<CreateWidgetResponse>), WebError>
where
    A: WidgetApplication,
{
    let command = input
        .validate(&state.config)
        .map_err(WebError::validation)?;

    let widget = state
        .application
        .create(command)
        .await
        .map_err(WebError::application)?;

    Ok((
        StatusCode::CREATED,
        Json(CreateWidgetResponse {
            id: widget.id,
            name: widget.name,
        }),
    ))
}

pub fn build_router<A>(state: WebState<A>) -> Router
where
    A: WidgetApplication,
{
    let v1 = Router::new()
        .route("/widgets", post(create_widget::<A>));

    Router::new()
        .nest("/v1", v1)
        .with_state(state)
}
```

The returned `Router` is the integration point. R75 owns middleware ordering; R78 and R79 supply their chosen Tower-compatible trace and metrics layers. The endpoint contains no exporter, registry, or global telemetry singleton. Axum’s use of Tower is an explicit framework design point. Source: `https://docs.rs/axum/0.8.9/axum/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))

#### Bounded graceful shutdown

Axum supplies graceful draining but not a duration parameter. Tokio already supplies OS signals, channels, and timeout; no extra signal or cancellation crate is required for the minimal server.

```rust
// src/web/server.rs
use std::{future::Future, time::Duration};

use axum::Router;
use tokio::{
    net::TcpListener,
    sync::oneshot,
    time::timeout,
};

#[derive(Debug)]
pub enum ServeError {
    Io(std::io::Error),
    GracefulShutdownTimedOut(Duration),
}

pub async fn serve_until<S>(
    listener: TcpListener,
    app: Router,
    shutdown: S,
    grace: Duration,
) -> Result<(), ServeError>
where
    S: Future<Output = ()> + Send + 'static,
{
    let (shutdown_started_tx, mut shutdown_started_rx) =
        oneshot::channel::<()>();

    let server = async move {
        axum::serve(listener, app)
            .with_graceful_shutdown(async move {
                shutdown.await;
                let _ = shutdown_started_tx.send(());
            })
            .await
    };

    tokio::pin!(server);

    tokio::select! {
        result = &mut server => result.map_err(ServeError::Io),
        _ = &mut shutdown_started_rx => {
            timeout(grace, &mut server)
                .await
                .map_err(|_| {
                    ServeError::GracefulShutdownTimedOut(grace)
                })?
                .map_err(ServeError::Io)
        }
    }
}

pub async fn os_shutdown_signal() {
    let ctrl_c = async {
        let _ = tokio::signal::ctrl_c().await;
    };

    #[cfg(unix)]
    let terminate = async {
        use tokio::signal::unix::{signal, SignalKind};

        if let Ok(mut signal) = signal(SignalKind::terminate()) {
            signal.recv().await;
        }
    };

    #[cfg(not(unix))]
    let terminate = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {}
        _ = terminate => {}
    }
}
```

`serve_until` accepts an injected shutdown future, so tests use a one-shot channel rather than sending process-wide signals. Production passes `os_shutdown_signal()`. Axum documents `with_graceful_shutdown`; Tokio documents signal, timer and Linux/macOS support. Sources: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` and `https://docs.rs/tokio/1.53.1/tokio/` (retrieved 2026-09-12). ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))

#### Production entrypoint

```rust
// src/bin/rs-launch-blueprint-web.rs
use std::{error::Error, sync::Arc};

use rs_launch_blueprint::{
    application::build_application, // R01 composition output
    config::Settings,               // R77-owned concrete type
    logging,
    web::{
        app::{build_router, ValidatedWebConfig, WebState},
        server::{os_shutdown_signal, serve_until},
    },
};
use tokio::net::TcpListener;

#[tokio::main]
async fn main() -> Result<(), Box<dyn Error>> {
    let settings = Settings::load_and_validate()?;
    let _logging_guard = logging::init(&settings.logging)?;

    let application = build_application(&settings)?;
    let handler_config = Arc::new(ValidatedWebConfig::from(&settings));

    let state = WebState {
        config: handler_config,
        application,
    };

    let app = build_router(state);

    // R75/R78/R79 wrap `app` here after those items select their layers.

    let listener = TcpListener::bind(settings.web.bind_addr()).await?;

    serve_until(
        listener,
        app,
        os_shutdown_signal(),
        settings.web.graceful_shutdown_duration(),
    )
    .await?;

    // The R78 telemetry guard remains alive until requests have drained.
    Ok(())
}
```

The binary accepts no operational CLI flags. Host, port, log profile, and graceful timeout come from the validated R77 settings. It loads configuration exactly once and binds only after validation and resource construction.

#### Dev-server recipe

```just
serve host="127.0.0.1" port="8000":
    RS_LAUNCH_BLUEPRINT__WEB__HOST="{{host}}" \
    RS_LAUNCH_BLUEPRINT__WEB__PORT="{{port}}" \
    RS_LAUNCH_BLUEPRINT__LOG__FORMAT="console" \
    watchexec \
      --restart \
      --stop-signal TERM \
      --stop-timeout 20s \
      --watch src \
      --watch Cargo.toml \
      --watch Cargo.lock \
      --exts rs,toml \
      -- \
      cargo run --features web --bin rs-launch-blueprint-web
```

The final environment-variable spelling belongs to R77, but the semantic contract is fixed here: development overrides log format to `console`; production retains R58’s structured default. Watchexec’s restart mode terminates the running process, waits for its configured graceful stop timeout, then starts the rebuilt command. Sources: `https://github.com/watchexec/watchexec` and `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` (retrieved 2026-09-12). ([github.com](https://github.com/watchexec/watchexec))

#### Baseline reviews

`BASELINE-REVIEW: F330 — one validated, application-scoped configuration snapshot — do not port Python’s lazy-load fallback; require build_router(WebState) and Router::with_state — Axum state is supplied during explicit service construction, and raw in-process callers can use the same factory rather than bypassing a hidden lifespan. Affects R32, R71, R77 and R82/R83/R84.` ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

`BASELINE-REVIEW: F331 — explicit and inspectable resource registration — replace a Python-style router registry list with direct Router::merge/nest calls in build_router — Axum natively composes routers sharing one state type, preserving straightforward registration without registry indirection. Affects R71’s route/OpenAPI composition and R75/R78/R79’s outer middleware boundary.` ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

### Recommendation

Use this stack:

- **Framework/server façade:** `axum = 0.8.9`, using first-party `axum::serve`; Hyper 1.x remains transitive.
- **Runtime and lifecycle:** `tokio = 1.53.1` with only `macros`, `net`, `rt-multi-thread`, `signal`, `sync`, and `time`.
- **Middleware/test contract:** `tower = 0.5.2` with `util`; later R75/R78/R79 libraries must compose as Tower layers/services but remain unselected here.
- **Development restart runner:** externally pinned `watchexec-cli = 2.5.1`.
- **Distribution boundary:** one non-default public Cargo feature named **`web`**, no nested R69-owned web features.
- **Configuration:** validated once in the web binary; immutable handler-facing projection injected through `State<WebState<_>>`.
- **Production entrypoint:** `rs-launch-blueprint-web`, guarded by `required-features = ["web"]`, calling `axum::serve(...).with_graceful_shutdown(...)` with a Tokio-enforced configured drain deadline.
- **Development entrypoint:** `just serve`, Watchexec restart loop, `console` logs; production remains JSON.

Axum is the best overall fit because Tower interoperability, explicit state, in-process `Service` testing, and production evidence outweigh Actix’s more integrated server lifecycle. Actix Web wins instead if the representative benchmark or a direct server-control requirement demonstrates a meaningful operational advantage.

### Members

#### axum 0.8.9

##### Landscape

Axum is the established Tokio-project framework in the Tokio/Hyper/Tower branch of the landscape. Version 0.8.9 is the released stable line; upstream’s main branch is preparing 0.9 and maintainers had no fixed 0.9 release date as of June 30, 2026. Sources: `https://github.com/tokio-rs/axum` and `https://github.com/tokio-rs/axum/discussions/3813` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/axum))

Mandated crate downloads, GitHub API fields, and ten-issue response median: **pending exact endpoint collection; not inferred from scraped substitutes**.

##### Principles and implementation

Axum realizes the shared principles through explicit `Router` construction, typed extractors, `State<S>`, Tower middleware, and an app object that is itself a testable `Service`. The agreement is on explicit composition and state ownership, not on reproducing FastAPI’s DI syntax. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))

##### Dominant choice

Dominant for new Tokio/Tower-oriented API services and the strongest fit for a template expected to compose later with tracing, metrics, OpenAPI, and potentially Tonic.

##### Qualified shortlist

1. Axum 0.8.9  
2. Actix Web 4.15.0  
3. Warp 0.4.3  
4. Poem 3.x, conditional on stronger CI/adopter evidence

##### Excluded by gate

No confirmed hard gate excludes Actix or current Warp. Poem and Pavex remain provisionally unqualified because this pass did not establish all required macOS CI, adopter, and exact maintenance evidence. Missing evidence is treated as a failed gate rather than presumed success.

##### Up-and-comers

Poem, Pavex, Salvo, and Xitca. Poem is the most relevant because its OpenAPI companion could reduce R71 integration work, but selecting it here would couple the foundational framework choice to an OpenAPI decision owned elsewhere.

##### Fit for this template

Excellent:

- small app factory returning `Router`;
- immutable state shared cheaply with `Arc`;
- no socket required for endpoint tests;
- framework-neutral R01 application boundary;
- Tower extension point for R75/R78/R79;
- production use by crates.io, including generated OpenAPI integration. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))

##### Recommendation

Pin the 0.8 line at `0.8.9`, disable defaults, and enable only the listed HTTP/JSON/routing/observability-support features.

##### Ranked runner-up

**Actix Web 4.15.0.** Choose it if integrated server controls, native bounded shutdown, or measured resource performance outweigh Tower interoperability.

##### Tradeoffs

- Axum 0.x minor upgrades can be breaking; pinning and deliberate upgrades are necessary.
- `axum::serve` has graceful draining but no built-in duration, requiring the small Tokio orchestration shown above.
- OpenAPI is not first-party; however, crates.io proves maintained integration is viable.
- Tower’s generic types can make advanced middleware signatures verbose, although ordinary `Router::layer` use remains straightforward.

##### Parameters

```toml
axum = {
  version = "0.8.9",
  optional = true,
  default-features = false,
  features = [
    "http1",
    "json",
    "matched-path",
    "original-uri",
    "query",
    "tokio",
    "tracing",
  ],
}
```

Maintenance state: **active**.

Unsafe posture: template-owned web code uses `#![forbid(unsafe_code)]`; resolved transitive unsafe is recorded with `cargo geiger` and screened through advisories.

Compile/binary cost: **moderate**, deliberately reduced by excluding HTTP/2, TLS, WebSockets, multipart, forms, and Axum macros.

##### Migration implications

Add `src/web/app.rs`, expose `web::build_router`, replace any proposed global configuration getter with `WebState`, and make resource route functions return native Axum routers.

##### Validation strategy

- Compile at Rust 1.96 with selected features.
- Test router via `tower::ServiceExt::oneshot`.
- Run resolved lock through `cargo audit`.
- Verify two routers with different configs run concurrently without global-state leakage.
- Execute R75/R78/R79 middleware contract tests against the returned Router.

##### Confidence & re-verify trigger

**High architectural confidence.** Reverify when Axum 0.9 is released, if 0.8 enters security-only maintenance, or if R71’s selected OpenAPI architecture cannot operate without wrapping/replacing native router construction.

##### Sources

- `https://github.com/tokio-rs/axum` — retrieved 2026-09-12. ([github.com](https://github.com/tokio-rs/axum))
- `https://docs.rs/axum/0.8.9/axum/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))
- `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))
- Required figure endpoints: `https://crates.io/api/v1/crates/axum`, `https://crates.io/api/v1/crates/axum/versions`, `https://api.github.com/repos/tokio-rs/axum`, and `https://api.github.com/search/issues?q=repo:tokio-rs/axum+is:issue+is:open`.

#### tokio 1.53.1

##### Landscape

Tokio is the established general-purpose asynchronous runtime and Axum’s intended runtime. Version 1.53.1 was released July 20, 2026. Tokio explicitly lists Linux and macOS among its supported platforms. Sources: `https://github.com/tokio-rs/tokio/releases` and `https://docs.rs/tokio/1.53.1/tokio/` (retrieved 2026-09-12). ([github.com](https://github.com/tokio-rs/tokio/releases))

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

Tokio supplies only process/runtime capabilities here: runtime, `TcpListener`, OS signals, synchronization, and timeout. Configuration, application state, and telemetry ownership remain outside the runtime.

##### Dominant choice

Tokio is effectively mandatory because Axum states that runtime independence is not a goal. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))

##### Qualified shortlist

No runtime alternative remains after selecting Axum. Async-std or Smol would require a different framework or adaptation layer with no benefit to this template.

##### Excluded by gate

- Glommio/Monoio: specialized runtime architectures and weaker fit for the required Ubuntu/macOS general-purpose template.
- Async-std/Smol: not a fitness failure in isolation, but incompatible with the selected framework’s intended architecture.

##### Up-and-comers

Specialized io_uring runtimes are relevant to dedicated Linux services, not a portable CLI/library/web blueprint.

##### Fit for this template

Excellent: all required production lifecycle functions are in one maintained runtime, so no separate signal-handling or cancellation dependency is needed for the minimal server.

##### Recommendation

Use Tokio 1.53.1 with a narrow feature list rather than `full`.

##### Ranked runner-up

Not applicable after the framework decision. If Actix is selected, its Tokio-compatible runtime/server façade becomes the runner-up bundle.

##### Tradeoffs

- Tokio is a material compile-time dependency, reinforcing why the entire web surface must remain optional.
- Enabling `full` would obscure the actual capability boundary and increase dependency/build cost.
- Runtime shutdown drops remaining tasks, so the bounded server drain must complete before `main` returns.

##### Parameters

```toml
tokio = {
  version = "1.53.1",
  optional = true,
  default-features = false,
  features = [
    "macros",
    "net",
    "rt-multi-thread",
    "signal",
    "sync",
    "time",
  ],
}
```

Maintenance state: **active**.

OS support: Linux, macOS and Windows are stated upstream; Windows is noted but not required. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))

##### Migration implications

The web feature becomes the owner of Tokio runtime features unless another accepted item makes Tokio a shared non-optional dependency. Even then, `web` remains the gate for network/signal/server code.

##### Validation strategy

- Build the complete resolved graph using Rust 1.96.
- Test `serve_until` with injected shutdown futures.
- Exercise SIGTERM on Ubuntu and macOS.
- Confirm configured timeout starts when shutdown is requested, not when the server starts.

##### Confidence & re-verify trigger

**High.** Reverify if Axum adds runtime independence, Tokio changes its MSRV beyond the project floor, or a current RustSec advisory applies to the resolved version.

##### Sources

- `https://docs.rs/tokio/1.53.1/tokio/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))
- `https://github.com/tokio-rs/tokio/releases` — retrieved 2026-09-12. ([github.com](https://github.com/tokio-rs/tokio/releases))
- Required figure endpoints: `https://crates.io/api/v1/crates/tokio`, `https://crates.io/api/v1/crates/tokio/versions`, `https://api.github.com/repos/tokio-rs/tokio`, and `https://api.github.com/search/issues?q=repo:tokio-rs/tokio+is:issue+is:open`.

#### tower 0.5.2

##### Landscape

Tower is the established service/middleware abstraction used by Axum. It is not a second web framework; it is the contract that makes middleware and in-process service testing composable.

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

Tower preserves agreement at the architectural-pattern level: cross-cutting behavior wraps the HTTP adapter rather than entering application handlers. `ServiceExt::oneshot` also allows the same production Router to be tested without a listener.

##### Dominant choice

Tower is the dominant middleware/service abstraction within the selected Axum architecture.

##### Qualified shortlist

- Tower `Service`/`Layer`
- Actix `Service`/`Transform`, but only if the framework changes to Actix
- Framework-specific test clients, which add another dependency and test a less general contract

##### Excluded by gate

No separate candidate is needed. A bespoke middleware trait would fail the dependability and integration-cost test because it would duplicate Tower without ecosystem benefit.

##### Up-and-comers

Inapplicable: this member is a protocol abstraction rather than a product category requiring a broad challenger survey.

##### Fit for this template

Strong:

- R75 can own layer ordering.
- R78/R79 can supply trace and metrics layers.
- R32 can run in-process HTTP tests.
- R01 remains below the adapter and does not depend on Tower.

##### Recommendation

Declare Tower directly under `web` with `util`. Do not add `tower-http` in R69; its individual layers belong to the later middleware/observability decisions.

##### Ranked runner-up

Actix’s middleware contracts, conditional on selecting Actix Web.

##### Tradeoffs

- Advanced generic layer stacks can expose long compiler types.
- A direct dependency slightly enlarges the compile graph, though Axum already depends on Tower’s core abstractions.
- Feature-level API compatibility must stay aligned with Axum’s Tower major version.

##### Parameters

```toml
tower = {
  version = "0.5.2",
  optional = true,
  default-features = false,
  features = ["util"],
}
```

Maintenance state: **stable-quiet** unless the final endpoint audit shows fresh release activity. No at-risk signal was established.

##### Migration implications

Web tests should replace socket-based test setup with `Router::oneshot`. Middleware modules selected later should expose ordinary Tower layers instead of framework-global registration.

##### Validation strategy

- Compile a request/response test using only `tower::ServiceExt`.
- Verify the production Router and tested Router are constructed by the same factory.
- Verify R75/R78/R79 layers can wrap the Router without changing handler signatures.

##### Confidence & re-verify trigger

**High while Axum remains Tower-based.** Reverify on Axum major upgrades or Tower 0.6.

##### Sources

- Axum’s Tower integration: `https://docs.rs/axum/0.8.9/axum/` — retrieved 2026-09-12. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- Required figure endpoints: `https://crates.io/api/v1/crates/tower`, `https://crates.io/api/v1/crates/tower/versions`, `https://api.github.com/repos/tower-rs/tower`, and the corresponding GitHub issue-search endpoint. Verify repository ownership because Tower has moved between organizations historically.

#### watchexec-cli 2.5.1

##### Landscape

The development-restart category contains Cargo-specific watchers, general process watchers, and TUI job runners:

- `cargo-watch`: familiar but archived.
- Bacon: active and polished, but AGPL-3.0 under the strict owner gate.
- Watchexec: active general watcher with restart, signal, process-group and stop-timeout controls.

Version 2.5.1 was released March 30, 2026 and requires Rust 1.93 when built from source. Sources: `https://github.com/watchexec/watchexec/releases` and `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` (retrieved 2026-09-12). ([github.com](https://github.com/watchexec/watchexec/releases))

Mandated crate and GitHub API figures: **pending exact endpoint collection**.

##### Principles and implementation

The shared principle is a short feedback loop with deterministic, graceful restart—not Cargo-specific syntax. Watchexec sends the configured stop signal and waits before force termination, allowing the same production shutdown path to run during development.

##### Dominant choice

Watchexec is the strongest maintained, license-compatible process runner for this use case.

##### Qualified shortlist

1. Watchexec CLI 2.5.1  
2. Bacon, if the owner relaxes the strict tool-license gate  
3. A shell loop using `cargo check` and process management, rejected as unnecessarily bespoke

##### Excluded by gate

- `cargo-watch`: **archived** January 18, 2025. ([github.com](https://github.com/watchexec/cargo-watch))
- Bacon: **AGPL-3.0**, failing the stated strict compatibility rubric even though merely using the tool would not normally relicense generated binaries. ([github.com](https://github.com/Canop/bacon))

##### Up-and-comers

Small watcher replacements exist, but none had comparable maintenance, process-group handling and distribution evidence.

##### Fit for this template

Very good:

- direct `cargo run --features web --bin ...`;
- sends `TERM` on Ubuntu/macOS;
- configurable graceful-stop deadline;
- watches Rust and manifest files;
- independent of framework and Cargo subcommand conventions.

##### Recommendation

Pin/install `watchexec-cli` 2.5.1 as a development tool, but do not add it to application dependencies or the `web` Cargo feature.

##### Ranked runner-up

Bacon, only under a recorded license-policy exception.

##### Tradeoffs

- More verbose than `cargo watch -x run`.
- Tool installation must be managed separately, preferably by the template’s existing tool manager or bootstrap recipe.
- Watchexec’s timeout must exceed the default application grace period so normal development restarts are not killed early.

##### Parameters

- Tool package: `watchexec-cli = 2.5.1`
- Executable: `watchexec`
- Restart mode: `--restart`
- Stop signal on required hosts: `TERM`
- Development stop timeout: 20 seconds
- Cargo dependency: none
- Cargo feature membership: none

Maintenance state: **active**.

##### Migration implications

Add the tool pin to the repository’s tool manifest/bootstrap path and replace any proposed `cargo watch` invocation in the Justfile.

##### Validation strategy

- Start the server through `just serve`.
- Save a Rust source file.
- Assert old PID receives SIGTERM, exits through graceful shutdown, and a new PID binds successfully.
- Assert console-formatted application logs remain visible across restarts.
- Test spaces in repository paths on both Ubuntu and macOS.

##### Confidence & re-verify trigger

**High.** Reverify if Watchexec is archived, raises source-build MSRV above the template’s supported stable toolchain, changes signal semantics, or its license changes.

##### Sources

- `https://github.com/watchexec/watchexec` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec))
- `https://github.com/watchexec/watchexec/releases` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec/releases))
- `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md` — retrieved 2026-09-12. ([github.com](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md))
- Required figure endpoints: `https://crates.io/api/v1/crates/watchexec-cli`, `https://crates.io/api/v1/crates/watchexec-cli/versions`, `https://api.github.com/repos/watchexec/watchexec`, and its GitHub issue-search endpoint.

### Compatibility

| Member | Selected line | Compatibility proof |
|---|---|---|
| Rust | `rust-version = "1.96"`; stable 1.98.1 | Selected direct crates publish lower MSRVs; the resolved graph must be tested under 1.96. |
| Axum | 0.8.9 | Official documentation says Axum is designed around Tokio, Hyper and Tower. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)) |
| Tokio | 1.53.1 | Current 1.x runtime; Axum examples and serve APIs use Tokio listener/runtime primitives. ([github.com](https://github.com/tokio-rs/axum)) |
| Tower | 0.5.2 | Matches Axum 0.8’s Tower service ecosystem and provides `util` testing helpers. |
| Hyper | Transitive 1.x | Intentionally owned by Axum’s dependency resolution; no direct version split. |
| Watchexec | CLI 2.5.1 | Process boundary only; it has no Rust ABI or dependency-resolution relationship with the service. |

**Shared adopter:** crates.io demonstrates Axum running with Tokio/Tower and a generated OpenAPI integration in a production Rust service. It does not prove the Watchexec component, which is intentionally process-external. Source: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/` (retrieved 2026-09-12). ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))

### Parameters

`owns web-extra-surface = one non-default Cargo feature named web; enabling web compiles rs_launch_blueprint::web::{app, server, handlers}, enables optional direct dependencies axum 0.8.9, tokio 1.53.1 and tower 0.5.2 with the feature sets specified above, enables the rs-launch-blueprint-web binary through required-features = ["web"], and enables web-only unit/integration/OpenAPI/doc test targets. Hyper 1.x remains transitive through Axum. There are no R69-owned nested public web-* features. Watchexec CLI 2.5.1 is a pinned external development tool and is not a Cargo dependency or feature member. R71/R75/R78/R79 may add their selected web-only dependencies to web, but a separate public feature requires an explicit decision by that owner.`

`assumes http-transport-injection-seam = unresolved by R01; the web adapter receives an R01-built application service/port in WebState. A concrete Clone generic and an Arc-backed dynamic adapter both fit. Handlers do not receive reqwest, hyper-client, or other driven-transport types.`

No `CONFLICT:` is identified.

### Migration implications

1. **`Cargo.toml`**
   - Add the `web` feature and three optional direct dependencies.
   - Add `rs-launch-blueprint-web` with `required-features = ["web"]`.
   - Add the gated web integration-test target.
   - Set `rust-version = "1.96"` and edition 2024.

2. **`src/lib.rs`**
   ```rust
   #[cfg(feature = "web")]
   pub mod web;
   ```

3. **`src/web/mod.rs`**
   - Export `build_router`, handler-facing state/config types, and `serve_until`.
   - Keep concrete route handlers private.

4. **`src/web/app.rs`**
   - Define `WebState`.
   - Define explicit native router composition.
   - Wire the R01 application boundary.

5. **`src/web/server.rs`**
   - Implement injected shutdown future, OS signal future, graceful drain and configured timeout.

6. **`src/bin/rs-launch-blueprint-web.rs`**
   - Load/validate R77 settings once.
   - Initialize R58 logging/telemetry ownership.
   - Construct R01 application resources.
   - Build router, bind listener and serve.
   - Accept no operational CLI flags.

7. **`tests/web.rs`**
   - Use `tower::ServiceExt::oneshot`.
   - Test config isolation, typed input/errors and fake R01 application behavior.

8. **`Justfile`**
   - Add `serve host="127.0.0.1" port="8000"`.
   - Set console logging and invoke Watchexec with graceful TERM restart.

9. **Tool manifest/bootstrap**
   - Pin Watchexec CLI 2.5.1.

10. **Downstream wiring**
    - R11: dedicated `--features web` CI job.
    - R32: in-process router tier plus real-listener lifecycle tier.
    - R37/R71/R82/R83/R84: run web/OpenAPI checks with `--features web`.
    - R51: build only `rs-launch-blueprint-web --features web`.
    - R58: production JSON default; `just serve` console override.
    - R75/R78/R79: apply selected Tower layers outside `build_router`’s handlers.

No Python or TypeScript repository change is made by R69; their rationale is supplied as follow-on guidance only.

### Validation strategy

The following are **planned acceptance checks; none were executed against an `rs-launch-blueprint` checkout during this research**.

#### Feature and MSRV proof

```bash
rustup toolchain install 1.96.0

cargo +1.96.0 check \
  --locked \
  --no-default-features \
  --all-targets

cargo +1.96.0 check \
  --locked \
  --features web \
  --bin rs-launch-blueprint-web

cargo +1.96.0 test \
  --locked \
  --features web \
  --all-targets

cargo +stable test \
  --locked \
  --all-features \
  --all-targets
```

Expected:

- default build does not expose or build the web binary;
- `cargo run --bin rs-launch-blueprint-web` without `--features web` fails with the required-feature explanation;
- Rust 1.96 compiles the complete resolved graph;
- the same commands pass on `ubuntu-latest` and `macos-latest`.

#### Dependency and security proof

```bash
cargo tree --features web -e features
cargo audit --deny warnings
cargo geiger --all-features
cargo license --avoid-build-deps
```

Expected:

- no direct Hyper version is introduced;
- no open RustSec advisory applies to the lockfile;
- template-owned crates contain no unsafe block;
- every distributed dependency is license-compatible;
- Watchexec remains an external tool rather than a linked dependency.

#### Configuration lifecycle proof

Create a counting test loader and send multiple requests through the same router:

- assert loader count is exactly one;
- assert handlers perform no environment reads;
- construct two routers with different maximum-name settings and exercise them concurrently;
- assert each router consistently observes only its injected config.

#### Endpoint and R01 proof

```rust
let response = build_router(test_state)
    .oneshot(request)
    .await
    .expect("router response");
```

Cover:

- valid request reaches the R01 fake exactly once;
- malformed JSON follows the R70 typed error path;
- semantic validation uses injected configuration;
- application errors follow the R70 error path;
- no TCP listener is required.

#### Graceful-shutdown proof

Use `TcpListener::bind("127.0.0.1:0")` and an injected one-shot shutdown future:

1. Begin a request blocked in a controllable R01 fake.
2. Trigger shutdown.
3. Verify the in-flight request can complete.
4. Verify `serve_until` returns successfully before the deadline.
5. Repeat with a permanently blocked fake and verify return at the configured deadline with `GracefulShutdownTimedOut`.
6. Run a process-level Ubuntu/macOS check sending SIGTERM to the production binary.

#### R75/R78/R79 integration checks

After those items select libraries:

- one request creates one server span with low-cardinality route `/v1/widgets`;
- metrics use the matched route, method and status—not raw IDs in URLs;
- validation and application-error responses are both observed;
- layer ordering matches R75;
- telemetry flush remains possible after the server drains and before `main` drops the provider;
- no handler depends on a concrete OpenTelemetry exporter or metrics recorder.

#### Dev-server proof

```bash
just serve
```

Then:

1. Capture PID and request the endpoint.
2. Modify a Rust source file.
3. Observe SIGTERM/graceful-exit logging for the old PID.
4. Observe a new PID and successful response.
5. Verify application logs are human-readable console output.
6. Start the binary outside the recipe with production settings and verify every log line is valid JSON according to R58.

#### Representative performance check

After R75/R78/R79 land, build equivalent Axum and Actix adapter branches and run, on identical hardware:

```bash
oha \
  --duration 180s \
  --connections 128 \
  --method POST \
  --header 'content-type: application/json' \
  --body-file benchmark/create-widget.json \
  http://127.0.0.1:8000/v1/widgets
```

Record warm-up separately and report p50/p95/p99, throughput, CPU, RSS, binary size, clean build, and one-file incremental rebuild. Do not combine results from different hardware, allocators, middleware sets, or exporter configurations.

#### Mandatory exact §7.6 figure collection

```bash
for crate in \
  axum actix-web warp poem tokio tower watchexec-cli
do
  curl -fsS "https://crates.io/api/v1/crates/${crate}" \
    | jq '{
        crate: .crate.name,
        recent_downloads: .crate.recent_downloads,
        downloads: .crate.downloads
      }'

  curl -fsS "https://crates.io/api/v1/crates/${crate}/versions" \
    | jq '[
        .versions[]
        | select(.yanked == false)
      ]
      | sort_by(.created_at)
      | last
      | {
          num,
          created_at
        }'
done
```

GitHub fields:

```bash
for repo in \
  tokio-rs/axum \
  actix/actix-web \
  seanmonstar/warp \
  poem-web/poem \
  tokio-rs/tokio \
  tower-rs/tower \
  watchexec/watchexec
do
  gh api "repos/${repo}" \
    --jq '{
      stargazers_count,
      archived,
      pushed_at
    }'

  gh api search/issues \
    -f q="repo:${repo} is:issue is:open" \
    --jq '{open_issues: .total_count}'
done
```

For responsiveness, fetch the ten newest `is:issue` records, then each issue’s comments/timeline. The first response is the earliest non-bot event by an upstream `OWNER`, `MEMBER`, or `COLLABORATOR`; report median elapsed calendar days and unanswered count. Attach raw JSON and the calculation script to the research ledger.

Finally, inspect each crate’s reverse-dependencies page and verify named adopters against their checked-in `Cargo.toml`/`Cargo.lock`, rather than inferring adoption from search results.

### Confidence & re-verify trigger

**Architectural confidence: high.** Axum’s explicit state, Tower composition, production adoption and in-process test model closely match the shared principles while remaining idiomatic Rust.

**Version and quantitative-ledger confidence: moderate until the mandatory raw API collection and lockfile audit are attached.**

Reopen R69 if any of the following occurs:

- Axum 0.9 is released before implementation begins.
- Axum 0.8 receives only security maintenance.
- An open RustSec advisory affects the resolved Axum/Tokio/Tower graph.
- Any selected dependency’s MSRV exceeds Rust 1.96.
- R71 demonstrates that its selected OpenAPI architecture cannot compose with native Axum routers without a registry or duplicate route declaration.
- R75/R78/R79 cannot implement the required middleware ordering or low-cardinality instrumentation as Tower layers.
- The representative benchmark shows Actix delivering a material p99-latency, CPU or RSS advantage at the same behavior and observability level.
- Watchexec is archived, changes license, or raises its source-build MSRV above the supported development toolchain.

### Sources

Primary and authoritative sources, all retrieved September 12, 2026:

- Rust releases: `https://blog.rust-lang.org/releases/`. ([blog.rust-lang.org](https://blog.rust-lang.org/releases/))
- 2025 Rust annual survey report: `https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf`. ([raw.githubusercontent.com](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf))
- Axum repository and release state: `https://github.com/tokio-rs/axum`. ([github.com](https://github.com/tokio-rs/axum))
- Axum framework documentation: `https://docs.rs/axum/0.8.9/axum/`. ([docs.rs](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html))
- Axum state: `https://docs.rs/axum/0.8.9/axum/extract/struct.State.html`. ([docs.rs](https://docs.rs/axum/latest/axum/extract/struct.State.html))
- Axum serving/graceful shutdown: `https://docs.rs/axum/0.8.9/axum/serve/struct.Serve.html`. ([docs.rs](https://docs.rs/axum/latest/axum/serve/struct.Serve.html))
- Tokio documentation/platforms: `https://docs.rs/tokio/1.53.1/tokio/`. ([docs.rs](https://docs.rs/tokio/latest/tokio/index.html))
- Tokio releases: `https://github.com/tokio-rs/tokio/releases`. ([github.com](https://github.com/tokio-rs/tokio/releases))
- Actix Web documentation: `https://docs.rs/actix-web/4.15.0/actix_web/`. ([docs.rs](https://docs.rs/crate/actix-web/latest))
- Warp current build: `https://docs.rs/crate/warp/latest`. ([docs.rs](https://docs.rs/crate/warp/latest/builds/3228099))
- Poem documentation: `https://docs.rs/poem/latest/poem/`. ([docs.rs](https://docs.rs/poem/latest/poem/))
- crates.io’s Axum migration and OpenAPI integration: `https://blog.rust-lang.org/2025/02/05/crates-io-development-update/`. ([blog.rust-lang.org](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/))
- Qdrant Actix dependency evidence: `https://github.com/qdrant/qdrant/blob/master/Cargo.lock`. ([github.com](https://github.com/qdrant/qdrant/blob/master/Cargo.lock))
- RustSec packages/advisories: `https://rustsec.org/packages/` and `https://rustsec.org/advisories/`. ([rustsec.org](https://rustsec.org/packages/))
- TechEmpower Round 23: `https://www.techempower.com/benchmarks/`. ([techempower.com](https://www.techempower.com/benchmarks/))
- Watchexec repository: `https://github.com/watchexec/watchexec`. ([github.com](https://github.com/watchexec/watchexec))
- Watchexec manual: `https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md`. ([github.com](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md))
- Watchexec releases: `https://github.com/watchexec/watchexec/releases`. ([github.com](https://github.com/watchexec/watchexec/releases))
- Cargo Watch archival evidence: `https://github.com/watchexec/cargo-watch`. ([github.com](https://github.com/watchexec/cargo-watch))
- Bacon license and release evidence: `https://github.com/Canop/bacon` and `https://github.com/Canop/bacon/blob/main/CHANGELOG.md`. ([github.com](https://github.com/Canop/bacon))

## Sources

- [https://blog.rust-lang.org/releases/](https://blog.rust-lang.org/releases/)
- [https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html](https://docs.rs/axum/latest/i686-pc-windows-msvc/axum/index.html)
- [https://github.com/tokio-rs/axum](https://github.com/tokio-rs/axum)
- [https://docs.rs/poem/latest/poem/](https://docs.rs/poem/latest/poem/)
- [https://docs.rs/actix-web/latest/actix_web/](https://docs.rs/actix-web/latest/actix_web/)
- [https://rustsec.org/packages/](https://rustsec.org/packages/)
- [https://www.techempower.com/benchmarks/](https://www.techempower.com/benchmarks/)
- [https://blog.rust-lang.org/2025/02/05/crates-io-development-update/](https://blog.rust-lang.org/2025/02/05/crates-io-development-update/)
- [https://github.com/qdrant/qdrant/blob/master/Cargo.lock](https://github.com/qdrant/qdrant/blob/master/Cargo.lock)
- [https://github.com/actix/actix-web](https://github.com/actix/actix-web)
- [https://docs.rs/crate/warp/latest/builds/3228099](https://docs.rs/crate/warp/latest/builds/3228099)
- [https://github.com/watchexec/cargo-watch](https://github.com/watchexec/cargo-watch)
- [https://github.com/Canop/bacon](https://github.com/Canop/bacon)
- [https://github.com/watchexec/watchexec/releases](https://github.com/watchexec/watchexec/releases)
- [https://docs.rs/axum/latest/axum/extract/struct.State.html](https://docs.rs/axum/latest/axum/extract/struct.State.html)
- [https://docs.rs/axum/latest/axum/serve/struct.Serve.html](https://docs.rs/axum/latest/axum/serve/struct.Serve.html)
- [https://docs.rs/crate/actix-web/latest](https://docs.rs/crate/actix-web/latest)
- [https://github.com/watchexec/watchexec](https://github.com/watchexec/watchexec)
- [https://github.com/tokio-rs/tokio/releases](https://github.com/tokio-rs/tokio/releases)
- [https://docs.rs/tokio/latest/tokio/index.html](https://docs.rs/tokio/latest/tokio/index.html)
- [https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md](https://github.com/watchexec/watchexec/blob/main/doc/watchexec.1.md)
- [https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf](https://raw.githubusercontent.com/rust-lang/surveys/main/surveys/2025/annual-survey/report/annual-survey-2025-report.pdf)
