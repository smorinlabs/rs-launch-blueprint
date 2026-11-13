#!/usr/bin/env bash
# R78 synthesis evidence 3 of 3 — the executed OpenTelemetry web example.
#
# Builds a throwaway two-crate workspace under $TMPDIR and runs it end to end:
#   svc        axum 0.8.9 / tokio 1.53.1 service (R69's registered versions) with the
#              recommended `otel` feature set: opentelemetry, opentelemetry_sdk,
#              opentelemetry-otlp, opentelemetry-http >= 0.33.0, < 0.34.0 and
#              tracing-opentelemetry >= 0.34.0, < 0.35.0, all default-features = false.
#              GET /demo -> instrumented internal work -> outbound GET /downstream on
#              itself with an injected W3C traceparent.
#   collector  a real OTLP/HTTP receiver: POST /v1/traces, protobuf decoded with
#              opentelemetry-proto 0.33.0 (prost), one JSON line per received span.
# The collector is a separate crate so the service's dependency graph is measured alone.
#
# Scenarios: feature absence (cargo tree + binary strings), one OTel line, MSRV floor
# (rustup 1.96.0), end-to-end trace chain with a fixed incoming traceparent and the
# shutdown flush, runtime flag off, unconfigured endpoint, OTEL_SDK_DISABLED, invalid
# endpoint, unreachable collector with bounded shutdown, web-only build.
#
# Usage: bash r78-probe.sh > r78-probe.log 2>&1       (R78_KEEP=1 keeps the workspace)
# Exit status: number of failed checks (0 = all passed).

set -uo pipefail

GREP=/usr/bin/grep
PASS=0
FAIL=0
N=0
check() { # check <id> <description> <command...>
  local id=$1 desc=$2
  shift 2
  N=$((N + 1))
  if "$@"; then
    PASS=$((PASS + 1))
    printf 'PASS %s %s\n' "$id" "$desc"
  else
    FAIL=$((FAIL + 1))
    printf 'FAIL %s %s\n' "$id" "$desc"
  fi
}

# Hermetic: no inherited OpenTelemetry configuration reaches any scenario.
while IFS= read -r v; do unset "$v"; done < <(env | sed -n 's/^\(OTEL_[A-Z0-9_]*\)=.*/\1/p')

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r78-probe.XXXXXX")
PIDS=()
# shellcheck disable=SC2329 # invoked by the EXIT trap
cleanup() {
  for p in "${PIDS[@]:-}"; do [ -n "$p" ] && kill "$p" 2>/dev/null; done
  if [ "${R78_KEEP:-0}" = 1 ]; then echo "# kept workspace: $WORK"; else rm -rf "$WORK"; fi
}
trap cleanup EXIT

echo "# r78-probe — run $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
echo "# host: $(uname -srm); $(sw_vers -productName 2>/dev/null) $(sw_vers -productVersion 2>/dev/null)"
echo "# $(rustc -V); $(cargo -V); rustup 1.96.0: $(rustup run 1.96.0 rustc -V 2>/dev/null || echo absent)"
echo "# CARGO_HOME=${CARGO_HOME:-unset}"
echo

# ---------------------------------------------------------------- workspace
mkdir -p "$WORK/svc/src" "$WORK/collector/src"
cat > "$WORK/Cargo.toml" <<'EOF'
[workspace]
members = ["svc", "collector"]
resolver = "3"
EOF

cat > "$WORK/svc/Cargo.toml" <<'EOF'
[package]
name = "svc"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[features]
default = []
web = ["dep:axum", "dep:tokio", "dep:reqwest"]
otel = [
    "web",
    "dep:opentelemetry",
    "dep:opentelemetry_sdk",
    "dep:opentelemetry-otlp",
    "dep:opentelemetry-http",
    "dep:tracing-opentelemetry",
]

[dependencies]
tracing = "0.1.44"
tracing-subscriber = "0.3.23"
axum = { version = "=0.8.9", optional = true }
tokio = { version = "=1.53.1", optional = true, features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
# The example's outbound client. Not selected by R78; reqwest 0.13 is already in the otel
# tree through the exporter's blocking client, so this adds features, not a crate.
reqwest = { version = "0.13", optional = true, default-features = false }
opentelemetry = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false, features = ["trace"] }
opentelemetry_sdk = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false, features = ["trace"] }
opentelemetry-otlp = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false, features = ["trace", "http-proto", "reqwest-blocking-client", "internal-logs"] }
opentelemetry-http = { version = ">= 0.33.0, < 0.34.0", optional = true, default-features = false }
tracing-opentelemetry = { version = ">= 0.34.0, < 0.35.0", optional = true, default-features = false }
EOF

cat > "$WORK/svc/src/main.rs" <<'EOF'
// R78 probe service. Throwaway evidence code, not template code.
use std::net::SocketAddr;
use std::process::ExitCode;
use std::time::Duration;

use axum::extract::{MatchedPath, Request, State};
use axum::middleware::{self, Next};
use axum::response::Response;
use axum::routing::get;
use axum::Router;
use tracing::{info, info_span, warn, Instrument};
use tracing_subscriber::filter::{LevelFilter, Targets};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::Layer;

#[derive(Clone)]
struct AppState {
    port: u16,
    client: reqwest::Client,
}

#[cfg(feature = "otel")]
mod telemetry {
    use opentelemetry::trace::TracerProvider as _;
    use opentelemetry_sdk::propagation::TraceContextPropagator;
    use opentelemetry_sdk::trace::{SdkTracer, SdkTracerProvider};
    use opentelemetry_sdk::Resource;

    pub enum OtelInit {
        Off(&'static str),
        Unavailable(String),
        On(SdkTracer, SdkTracerProvider),
    }

    // Gate 2 (runtime flag, plus the standard kill switch the SDK does not read) and
    // gate 3 (exporter build failure degrades to a value, never a panic).
    pub fn init(enabled: bool, honor_sdk_disabled: bool) -> OtelInit {
        if !enabled {
            return OtelInit::Off("runtime flag unset");
        }
        if honor_sdk_disabled
            && std::env::var("OTEL_SDK_DISABLED").is_ok_and(|v| v.trim().eq_ignore_ascii_case("true"))
        {
            return OtelInit::Off("OTEL_SDK_DISABLED=true");
        }
        let exporter = match opentelemetry_otlp::SpanExporter::builder().with_http().build() {
            Ok(e) => e,
            Err(e) => return OtelInit::Unavailable(e.to_string()),
        };
        let provider = SdkTracerProvider::builder()
            .with_batch_exporter(exporter)
            .with_resource(Resource::builder().with_service_name("probe-web").build())
            .build();
        // The global default is a no-op propagator; without this an incoming
        // traceparent is ignored.
        opentelemetry::global::set_text_map_propagator(TraceContextPropagator::new());
        OtelInit::On(provider.tracer("r78-probe"), provider)
    }

    pub fn current_trace_id() -> String {
        use opentelemetry::trace::TraceContextExt;
        use tracing_opentelemetry::OpenTelemetrySpanExt;
        tracing::Span::current().context().span().span_context().trace_id().to_string()
    }

    pub fn set_remote_parent(span: &tracing::Span, headers: &axum::http::HeaderMap) {
        use tracing_opentelemetry::OpenTelemetrySpanExt;
        let parent = opentelemetry::global::get_text_map_propagator(|p| {
            p.extract(&opentelemetry_http::HeaderExtractor(headers))
        });
        if let Err(e) = span.set_parent(parent) {
            tracing::debug!(error = %e, "set_parent failed");
        }
    }

    pub fn inject(headers: &mut axum::http::HeaderMap) {
        use tracing_opentelemetry::OpenTelemetrySpanExt;
        let cx = tracing::Span::current().context();
        opentelemetry::global::get_text_map_propagator(|p| {
            p.inject_context(&cx, &mut opentelemetry_http::HeaderInjector(headers))
        });
    }
}

// Server span, created before it is entered; only the parent extraction is feature-gated.
async fn otel_context(req: Request, next: Next) -> Response {
    let route = req
        .extensions()
        .get::<MatchedPath>()
        .map(|p| p.as_str().to_owned())
        .unwrap_or_default();
    let span = info_span!(
        "http.server.request",
        otel.kind = "server",
        http.request.method = %req.method(),
        http.route = %route,
        http.response.status_code = tracing::field::Empty,
    );
    #[cfg(feature = "otel")]
    telemetry::set_remote_parent(&span, req.headers());
    let resp = next.run(req).instrument(span.clone()).await;
    span.record("http.response.status_code", resp.status().as_u16());
    resp
}

#[tracing::instrument(name = "demo.work")]
async fn do_work() -> u64 {
    tokio::time::sleep(Duration::from_millis(5)).await;
    42
}

async fn demo(State(st): State<AppState>) -> String {
    #[cfg(feature = "otel")]
    let tid = telemetry::current_trace_id();
    #[cfg(not(feature = "otel"))]
    let tid = String::from("none");
    let v = do_work().await;
    let url = format!("http://127.0.0.1:{}/downstream", st.port);
    let client_span = info_span!(
        "http.client.request",
        otel.kind = "client",
        http.request.method = "GET",
        url.full = %url,
        http.response.status_code = tracing::field::Empty,
    );
    let cs = client_span.clone();
    let status = async move {
        #[allow(unused_mut)]
        let mut headers = axum::http::HeaderMap::new();
        #[cfg(feature = "otel")]
        telemetry::inject(&mut headers);
        match st.client.get(&url).headers(headers).send().await {
            Ok(r) => {
                let s = r.status().as_u16();
                cs.record("http.response.status_code", s);
                s
            }
            Err(e) => {
                warn!(error = %e, "outbound request failed");
                0
            }
        }
    }
    .instrument(client_span)
    .await;
    info!(trace_id = %tid, downstream_status = status, "demo request completed");
    format!("demo ok work={v} downstream={status} trace_id={tid}\n")
}

async fn downstream() -> &'static str {
    "downstream ok\n"
}

fn env_or(key: &str, default: &str) -> String {
    std::env::var(key).unwrap_or_else(|_| default.to_owned())
}

#[tokio::main]
async fn main() -> ExitCode {
    let port: u16 = env_or("PROBE_PORT", "38080").parse().expect("PROBE_PORT");
    let enabled = env_or("PROBE_OTEL_ENABLED", "0") == "1";
    let honor = env_or("PROBE_HONOR_SDK_DISABLED", "1") == "1";
    let budget = Duration::from_millis(env_or("PROBE_OTEL_SHUTDOWN_MS", "2000").parse().expect("ms"));

    let fmt_layer = tracing_subscriber::fmt::layer()
        .with_ansi(false)
        .with_writer(std::io::stderr)
        .with_filter(Targets::new().with_default(LevelFilter::INFO));

    #[cfg(feature = "otel")]
    let (otel_layer, guard, off_reason, unavailable) = match telemetry::init(enabled, honor) {
        telemetry::OtelInit::On(tracer, provider) => (
            Some(
                tracing_opentelemetry::layer().with_tracer(tracer).with_filter(
                    // Per-layer filter against telemetry-induced telemetry.
                    Targets::new()
                        .with_default(LevelFilter::INFO)
                        .with_target("hyper", LevelFilter::OFF)
                        .with_target("hyper_util", LevelFilter::OFF)
                        .with_target("h2", LevelFilter::OFF)
                        .with_target("reqwest", LevelFilter::OFF)
                        .with_target("opentelemetry", LevelFilter::OFF)
                        .with_target("opentelemetry_sdk", LevelFilter::OFF)
                        .with_target("opentelemetry_otlp", LevelFilter::OFF),
                ),
            ),
            Some(provider),
            None,
            None,
        ),
        telemetry::OtelInit::Off(r) => (None, None, Some(r), None),
        telemetry::OtelInit::Unavailable(e) => (None, None, None, Some(e)),
    };
    #[cfg(not(feature = "otel"))]
    let (otel_layer, off_reason, unavailable): (
        Option<tracing_subscriber::layer::Identity>,
        Option<&str>,
        Option<String>,
    ) = {
        let _ = (enabled, honor, budget);
        (None, Some("feature otel not compiled"), None)
    };

    tracing_subscriber::registry().with(fmt_layer).with(otel_layer).init();

    // Warnings are emitted only after the subscriber exists, or they go nowhere.
    if let Some(r) = off_reason {
        info!(reason = r, "otel_off");
    }
    if let Some(e) = unavailable {
        warn!(error = %e, "otel_unavailable");
    }
    #[cfg(not(feature = "otel"))]
    if std::env::var_os("OTEL_EXPORTER_OTLP_ENDPOINT").is_some() {
        warn!("otel_ignored: OTEL_EXPORTER_OTLP_ENDPOINT is set but this binary was built without the otel feature");
    }

    let state = AppState { port, client: reqwest::Client::new() };
    let app = Router::new()
        .route("/demo", get(demo))
        .route("/downstream", get(downstream))
        .layer(middleware::from_fn(otel_context))
        .with_state(state);
    let listener = tokio::net::TcpListener::bind(SocketAddr::from(([127, 0, 0, 1], port)))
        .await
        .expect("bind");
    info!(port, "probe listening");

    let (tx, rx) = tokio::sync::oneshot::channel::<u8>();
    let shutdown = async move {
        let mut term = tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("sigterm handler");
        let code = tokio::select! {
            _ = term.recv() => 143u8,
            _ = tokio::signal::ctrl_c() => 130u8,
        };
        let _ = tx.send(code);
    };
    if let Err(e) = axum::serve(listener, app).with_graceful_shutdown(shutdown).await {
        warn!(error = %e, "serve failed");
        return ExitCode::from(1);
    }
    let code = rx.await.unwrap_or(1);

    #[cfg(feature = "otel")]
    if let Some(provider) = guard {
        // Bounded, off the async workers; failure is a warning, never an exit-code change.
        let t0 = std::time::Instant::now();
        let r = tokio::task::spawn_blocking(move || provider.shutdown_with_timeout(budget)).await;
        let elapsed_ms = t0.elapsed().as_millis() as u64;
        match r {
            Ok(Ok(())) => info!(elapsed_ms, "otel_shutdown_ok"),
            Ok(Err(e)) => warn!(elapsed_ms, error = %e, "otel_shutdown_failed"),
            Err(e) => warn!(elapsed_ms, error = %e, "otel_shutdown_join_failed"),
        }
    }
    info!(exit_code = code, "probe exiting");
    ExitCode::from(code)
}
EOF

cat > "$WORK/collector/Cargo.toml" <<'EOF'
[package]
name = "collector"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "macros"] }
prost = "0.14"
opentelemetry-proto = { version = "=0.33.0", default-features = false, features = ["gen-tonic-messages", "trace"] }
EOF

cat > "$WORK/collector/src/main.rs" <<'EOF'
// Minimal OTLP/HTTP trace receiver: decodes ExportTraceServiceRequest protobuf bodies
// and appends one JSON line per span. Throwaway evidence code.
use std::io::Write;
use std::sync::{Arc, Mutex};

use axum::body::Bytes;
use axum::extract::State;
use axum::http::header::CONTENT_TYPE;
use axum::routing::post;
use axum::Router;
use opentelemetry_proto::tonic::collector::trace::v1::{ExportTraceServiceRequest, ExportTraceServiceResponse};
use opentelemetry_proto::tonic::common::v1::{any_value, KeyValue};
use prost::Message;

fn hex(b: &[u8]) -> String {
    b.iter().map(|x| format!("{x:02x}")).collect()
}

fn attr(kvs: &[KeyValue], key: &str) -> String {
    kvs.iter()
        .find(|kv| kv.key == key)
        .and_then(|kv| kv.value.as_ref())
        .and_then(|v| match &v.value {
            Some(any_value::Value::StringValue(s)) => Some(s.clone()),
            Some(any_value::Value::IntValue(i)) => Some(i.to_string()),
            _ => None,
        })
        .unwrap_or_default()
}

async fn traces(State(out): State<Arc<Mutex<std::fs::File>>>, body: Bytes) -> ([(axum::http::HeaderName, &'static str); 1], Vec<u8>) {
    let req = ExportTraceServiceRequest::decode(body).expect("decode ExportTraceServiceRequest");
    let mut f = out.lock().expect("lock");
    for rs in req.resource_spans {
        let svc = rs.resource.as_ref().map(|r| attr(&r.attributes, "service.name")).unwrap_or_default();
        for ss in rs.scope_spans {
            let scope = ss.scope.map(|s| s.name).unwrap_or_default();
            for sp in ss.spans {
                writeln!(
                    f,
                    "{{\"service\":\"{svc}\",\"scope\":\"{scope}\",\"name\":\"{}\",\"kind\":{},\"traceId\":\"{}\",\"spanId\":\"{}\",\"parentSpanId\":\"{}\",\"route\":\"{}\",\"status\":\"{}\"}}",
                    sp.name,
                    sp.kind,
                    hex(&sp.trace_id),
                    hex(&sp.span_id),
                    hex(&sp.parent_span_id),
                    attr(&sp.attributes, "http.route"),
                    attr(&sp.attributes, "http.response.status_code"),
                )
                .expect("write");
            }
        }
    }
    f.flush().expect("flush");
    ([(CONTENT_TYPE, "application/x-protobuf")], ExportTraceServiceResponse::default().encode_to_vec())
}

#[tokio::main]
async fn main() {
    let mut args = std::env::args().skip(1);
    let port: u16 = args.next().expect("port").parse().expect("port number");
    let path = args.next().expect("output file");
    let file = std::fs::OpenOptions::new().create(true).append(true).open(path).expect("open output");
    let app = Router::new().route("/v1/traces", post(traces)).with_state(Arc::new(Mutex::new(file)));
    let listener = tokio::net::TcpListener::bind(("127.0.0.1", port)).await.expect("bind collector");
    axum::serve(listener, app).await.expect("serve collector");
}
EOF

# ---------------------------------------------------------------- build
cd "$WORK" || exit 99
# Pin the target directory inside the workspace; an inherited CARGO_TARGET_DIR would
# otherwise put the binaries elsewhere.
export CARGO_TARGET_DIR="$WORK/target"
echo "## 1. Build"
cargo generate-lockfile --quiet || { echo "generate-lockfile failed"; exit 99; }
echo "resolved: $(cargo tree -p svc --features otel -e normal --prefix none --depth 1 2>/dev/null | $GREP -E '^(opentelemetry|tracing-opentelemetry|axum|tokio|reqwest|tracing-subscriber) ' | sort -u | paste -sd';' -)"
t0=$(date +%s)
cargo build --locked --quiet -p collector 2> build-collector.err
check B01 "collector (OTLP/HTTP protobuf receiver) builds" test -x target/debug/collector
cargo build --locked --quiet -p svc --features otel 2> build-otel.err
check B02 "svc builds with --features otel (web + recommended OTel set) on local stable" test -x target/debug/svc
cp target/debug/svc svc-otel 2>/dev/null
cargo build --locked --quiet -p svc --features web 2> build-web.err
check B03 "svc builds with --features web only" test -x target/debug/svc
cp target/debug/svc svc-web 2>/dev/null
echo "build wall time (debug, collector + both svc builds, warm or cold cache): $(( $(date +%s) - t0 )) s"
for f in build-collector.err build-otel.err build-web.err; do
  [ -s "$f" ] && { echo "--- $f"; cat "$f"; }
done
if [ ! -x target/debug/collector ] || [ ! -x svc-otel ] || [ ! -x svc-web ]; then
  echo "# ABORT: a build failed; no runtime scenario can be meaningful"
  echo "# TOTAL checks=$N pass=$PASS fail=$FAIL"
  exit 98
fi
echo "binary sizes (debug, unstripped, bytes): svc-web $(stat -f %z svc-web 2>/dev/null) ; svc-otel $(stat -f %z svc-otel 2>/dev/null)"
echo

echo "## 2. Feature absence and a single OTel line (cargo tree)"
cargo tree --locked -p svc --features web -e normal --prefix none > tree-web.txt 2>&1
cargo tree --locked -p svc --features otel -e normal --prefix none > tree-otel.txt 2>&1
check T00 "both cargo tree listings are non-empty" test -s tree-web.txt -a -s tree-otel.txt
leak=$($GREP -cE '^(opentelemetry|opentelemetry_sdk|opentelemetry-otlp|opentelemetry-http|opentelemetry-proto|tracing-opentelemetry) ' tree-web.txt)
echo "OTel crates in the web-only tree: $leak"
check T01 "web-only dependency tree contains no OpenTelemetry crate" test "$leak" -eq 0
cargo tree --locked -p svc --features web -e normal -i opentelemetry > inv-web.txt 2>&1
echo "cargo tree -i opentelemetry (web only): exit $? — $(head -n 1 inv-web.txt)"
otel_lines=$($GREP -E '^opentelemetry v' tree-otel.txt | sed 's/ (\*)$//' | sort -u)
echo "opentelemetry versions in the otel tree: $(echo "$otel_lines" | paste -sd' ' -)"
check T02 "exactly one opentelemetry version, and it is 0.33.x" bash -c "[[ \$(printf '%s\n' '$otel_lines' | wc -l | tr -d ' ') == 1 && '$otel_lines' == 'opentelemetry v0.33.'* ]]"
tro=$($GREP -E '^tracing-opentelemetry v' tree-otel.txt | sed 's/ (\*)$//' | sort -u)
echo "tracing-opentelemetry in the otel tree: $tro"
check T03 "tracing-opentelemetry resolves to 0.34.x" bash -c "[[ '$tro' == 'tracing-opentelemetry v0.34.'* ]]"
cargo tree --locked -p svc --features otel -e normal -d --prefix depth > dups.txt 2>&1
echo "duplicated crates (depth-0 roots of cargo tree -d): $($GREP -E '^0' dups.txt | sed 's/^0//' | paste -sd';' -)"
dupl=$($GREP -cE '^0(opentelemetry|opentelemetry_sdk|http|reqwest|hyper|tracing-subscriber) v' dups.txt)
echo "duplicate (opentelemetry|opentelemetry_sdk|http|reqwest|hyper|tracing-subscriber) entries: $dupl"
check T04 "no duplicate opentelemetry/http/reqwest/hyper/tracing-subscriber versions in the otel tree" test "$dupl" -eq 0
echo "tower-http in the otel tree (arrives through reqwest; R75 selects tower-http): $($GREP -E '^tower-http v' tree-otel.txt | sed 's/ (\*)$//' | sort -u | paste -sd' ' -)"
echo "tower-http in the web-only tree: $($GREP -E '^tower-http v' tree-web.txt | sed 's/ (\*)$//' | sort -u | paste -sd' ' -)"
metrics_on=$(cargo tree --locked -p svc --features otel -e features -i opentelemetry_sdk 2>/dev/null | $GREP -c 'opentelemetry_sdk feature "metrics"')
echo "opentelemetry_sdk feature \"metrics\" activations in the otel tree: $metrics_on"
check T05 "http-proto switches on opentelemetry_sdk/metrics despite default-features = false" test "$metrics_on" -ge 1
syms=$(strings svc-web | $GREP -c 'opentelemetry')
echo "strings svc-web | grep -c opentelemetry: $syms"
check T06 "the web-only binary contains no 'opentelemetry' string" test "$syms" -eq 0
echo

echo "## 3. MSRV floor: rustup 1.96.0 compiles the locked otel tree"
if rustup run 1.96.0 rustc -V > /dev/null 2>&1; then
  rustup run 1.96.0 cargo check --locked --quiet -p svc --features otel --target-dir target-msrv 2> msrv.err
  rc=$?
  echo "rustup run 1.96.0 cargo check -p svc --features otel: exit $rc"
  [ -s msrv.err ] && cat msrv.err
  check M01 "the recommended set compiles under Rust 1.96.0 (the stable-minus-2 floor)" test "$rc" -eq 0
else
  check M01 "rustup toolchain 1.96.0 is installed" false
fi
echo

# ---------------------------------------------------------------- runtime helpers
free_port() { # prints a TCP port with no listener on 127.0.0.1
  local p
  while :; do
    p=$((20000 + RANDOM % 20000))
    nc -z 127.0.0.1 "$p" 2>/dev/null || { echo "$p"; return; }
  done
}
wait_http() { # wait_http <url> — up to 15 s for any HTTP answer
  for _ in $(seq 1 150); do
    curl -s -o /dev/null "$1" && return 0
    sleep 0.1
  done
  return 1
}
wait_port() { # wait_port <port> — up to 10 s
  for _ in $(seq 1 100); do
    nc -z 127.0.0.1 "$1" 2>/dev/null && return 0
    sleep 0.1
  done
  return 1
}
start_collector() { # start_collector <port> <file> -> sets CPID
  : > "$2"
  "$WORK/target/debug/collector" "$1" "$2" &
  CPID=$!
  PIDS+=("$CPID")
  wait_port "$1"
}
stop_pid() { kill "$1" 2>/dev/null; wait "$1" 2>/dev/null; }
start_svc() { # start_svc <binary> <port> <logfile> [VAR=value ...] -> sets SPID
  local bin=$1 port=$2 log=$3
  shift 3
  env "$@" PROBE_PORT="$port" "$bin" 2> "$log" &
  SPID=$!
  PIDS+=("$SPID")
  wait_http "http://127.0.0.1:$port/downstream"
}
term_svc() { # term_svc -> sets RC (exit status) and TERM_MS (ms from SIGTERM to exit)
  local t0 t1
  t0=$(perl -MTime::HiRes=time -e 'printf "%d", time*1000')
  kill -TERM "$SPID"
  wait "$SPID"
  RC=$?
  t1=$(perl -MTime::HiRes=time -e 'printf "%d", time*1000')
  TERM_MS=$((t1 - t0))
}
hit() { # hit <port> <count> [traceparent] -> prints count of HTTP 200 responses
  local ok=0 code
  for _ in $(seq 1 "$2"); do
    if [ -n "${3:-}" ]; then
      code=$(curl -s -o /dev/null -w '%{http_code}' -H "traceparent: $3" "http://127.0.0.1:$1/demo")
    else
      code=$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$1/demo")
    fi
    [ "$code" = 200 ] && ok=$((ok + 1))
  done
  echo "$ok"
}
ms_now() { perl -MTime::HiRes=time -e 'printf "%d", time*1000'; }

TRACE=4bf92f3577b34da6a3ce929d0e0e4736
PARENT=00f067aa0ba902b7
TP="00-$TRACE-$PARENT-01"
SVC_OTEL="$WORK/svc-otel"
SVC_WEB="$WORK/svc-web"

# ---------------------------------------------------------------- E2E
echo "## 4. End to end: incoming traceparent -> server span -> work -> outbound -> downstream -> OTLP/HTTP export"
echo "#    OTEL_BSP_SCHEDULE_DELAY=60000 so no periodic export fires: spans reach the collector only through the SIGTERM shutdown flush."
C=$(free_port); S=$(free_port)
start_collector "$C" "$WORK/e2e.jsonl"
start_svc "$SVC_OTEL" "$S" "$WORK/e2e.log" PROBE_OTEL_ENABLED=1 OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$C" OTEL_BSP_SCHEDULE_DELAY=60000
body=$(curl -s -H "traceparent: $TP" "http://127.0.0.1:$S/demo")
echo "response: $body"
pre=$(wc -l < "$WORK/e2e.jsonl" | tr -d ' ')
echo "spans at the collector before SIGTERM: $pre"
term_svc
echo "exit status after SIGTERM: $RC (shutdown took ${TERM_MS} ms)"
sleep 0.3
stop_pid "$CPID"
echo "--- collector received:"
cat "$WORK/e2e.jsonl"
echo "--- service log:"
cat "$WORK/e2e.log"
J="$WORK/e2e.jsonl"
jqs() { jq -r -s "$1" "$J"; }
# Every selector is scoped to the incoming trace id: the readiness probe's own
# /downstream request is a separate root trace and must not be picked up.
srv_demo=$(jqs "map(select(.traceId==\"$TRACE\" and .name==\"http.server.request\" and .route==\"/demo\"))[0]")
srv_id=$(echo "$srv_demo" | jq -r '.spanId // ""')
work_parent=$(jqs "map(select(.traceId==\"$TRACE\" and .name==\"demo.work\"))[0].parentSpanId // \"\"")
cli=$(jqs "map(select(.traceId==\"$TRACE\" and .name==\"http.client.request\"))[0]")
cli_id=$(echo "$cli" | jq -r '.spanId // ""')
down_parent=$(jqs "map(select(.traceId==\"$TRACE\" and .name==\"http.server.request\" and .route==\"/downstream\"))[0].parentSpanId // \"\"")
echo "readiness-probe spans in their own root traces: $(jqs "map(select(.traceId != \"$TRACE\" and .parentSpanId == \"\")) | length")"
check E01 "response is 200 with the downstream call succeeding" bash -c "[[ '$body' == 'demo ok work=42 downstream=200 trace_id=$TRACE'* ]]"
check E02 "no span reached the collector before SIGTERM (batch delay 60 s)" test "$pre" -eq 0
check E03 "SIGTERM exit status is 143 (R69/R67 registered value)" test "$RC" -eq 143
check E04 "exactly 4 spans carry the incoming trace id (server, work, client, downstream server)" \
  test "$(jqs "map(select(.traceId==\"$TRACE\")) | length")" -eq 4
check E05 "the /demo SERVER span (kind 2) has parentSpanId = incoming parent $PARENT" \
  test "$(echo "$srv_demo" | jq -r '"\(.kind) \(.parentSpanId)"')" = "2 $PARENT"
check E06 "demo.work is a child of the /demo server span" test -n "$srv_id" -a "$work_parent" = "$srv_id"
check E07 "the outbound CLIENT span (kind 3) is a child of the /demo server span" \
  test "$(echo "$cli" | jq -r '"\(.kind) \(.parentSpanId)"')" = "3 $srv_id"
check E08 "the /downstream SERVER span's parent is the CLIENT span (header injected and re-extracted)" \
  test -n "$cli_id" -a "$down_parent" = "$cli_id"
check E09 "resource service.name = probe-web on every span" \
  test "$(jqs 'map(select(.service != "probe-web")) | length')" -eq 0
check E10 "only the probe's own spans were exported (no hyper/reqwest/h2/opentelemetry spans)" \
  test "$(jqs 'map(select(.name | test("^(http\\.server\\.request|http\\.client\\.request|demo\\.work)$") | not)) | length')" -eq 0
check E11 "the /demo span recorded http.response.status_code = 200" test "$(echo "$srv_demo" | jq -r '.status')" = 200
check E12 "the request's log line carries trace_id = the incoming trace id (log correlation)" \
  test "$($GREP -c "demo request completed.*trace_id=$TRACE\|trace_id=$TRACE.*demo request completed" "$WORK/e2e.log")" -ge 1
check E13 "shutdown flush reported ok" test "$($GREP -c 'otel_shutdown_ok' "$WORK/e2e.log")" -eq 1
echo

# ---------------------------------------------------------------- degrade paths
echo "## 5. Runtime flag off: otel compiled in, endpoint set, PROBE_OTEL_ENABLED unset"
C=$(free_port); S=$(free_port)
start_collector "$C" "$WORK/off.jsonl"
start_svc "$SVC_OTEL" "$S" "$WORK/off.log" OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$C" OTEL_BSP_SCHEDULE_DELAY=100
ok=$(hit "$S" 20 "$TP")
term_svc; sleep 0.3; stop_pid "$CPID"
echo "200s: $ok/20; exit $RC; spans at collector: $(wc -l < "$WORK/off.jsonl" | tr -d ' ')"
$GREP -E 'otel_|WARN' "$WORK/off.log" | sed 's/^/  log: /'
check D01 "flag off: all 20 requests 200" test "$ok" -eq 20
check D02 "flag off: the collector receives nothing" test ! -s "$WORK/off.jsonl"
check D03 "flag off: no WARN line at all" test "$($GREP -c 'WARN' "$WORK/off.log")" -eq 0
check D04 "flag off: SIGTERM exit 143" test "$RC" -eq 143
echo

echo "## 6. Unconfigured endpoint: flag on, no OTEL_EXPORTER_OTLP_* variable at all"
if nc -z 127.0.0.1 4318 2>/dev/null; then
  echo "port 4318 is in use on this host; the behavioural half is skipped and S01 in r78-source-census.log carries the claim"
  check D05 "localhost:4318 free for the unconfigured-endpoint run" false
else
  S=$(free_port)
  start_collector 4318 "$WORK/default.jsonl"
  start_svc "$SVC_OTEL" "$S" "$WORK/default.log" -u OTEL_EXPORTER_OTLP_ENDPOINT -u OTEL_EXPORTER_OTLP_TRACES_ENDPOINT PROBE_OTEL_ENABLED=1
  ok=$(hit "$S" 3 "$TP")
  term_svc; sleep 0.3; stop_pid "$CPID"
  got=$(jq -s "map(select(.traceId==\"$TRACE\")) | length" "$WORK/default.jsonl")
  echo "200s: $ok/3; exit $RC; spans received on 127.0.0.1:4318 with the incoming trace id: $got"
  check D05 "an otel build with the flag on and NO endpoint variable exports to localhost:4318" test "$got" -ge 4
fi
echo

echo "## 7. OTEL_SDK_DISABLED=true: SDK alone vs the template's one-line guard"
C=$(free_port); S=$(free_port)
start_collector "$C" "$WORK/sdkoff-raw.jsonl"
start_svc "$SVC_OTEL" "$S" "$WORK/sdkoff-raw.log" PROBE_OTEL_ENABLED=1 PROBE_HONOR_SDK_DISABLED=0 OTEL_SDK_DISABLED=true OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$C"
ok=$(hit "$S" 2 "$TP"); term_svc; sleep 0.3; stop_pid "$CPID"
raw=$(wc -l < "$WORK/sdkoff-raw.jsonl" | tr -d ' ')
echo "guard off: 200s $ok/2; spans exported despite OTEL_SDK_DISABLED=true: $raw"
check D06 "the SDK itself ignores OTEL_SDK_DISABLED=true (spans still exported)" test "$raw" -ge 1
C=$(free_port); S=$(free_port)
start_collector "$C" "$WORK/sdkoff-guard.jsonl"
start_svc "$SVC_OTEL" "$S" "$WORK/sdkoff-guard.log" PROBE_OTEL_ENABLED=1 PROBE_HONOR_SDK_DISABLED=1 OTEL_SDK_DISABLED=true OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$C"
ok=$(hit "$S" 2 "$TP"); term_svc; sleep 0.3; stop_pid "$CPID"
echo "guard on: 200s $ok/2; spans exported: $(wc -l < "$WORK/sdkoff-guard.jsonl" | tr -d ' ')"
check D07 "with the template guard, OTEL_SDK_DISABLED=true exports nothing and serves" test ! -s "$WORK/sdkoff-guard.jsonl" -a "$ok" -eq 2
echo

echo "## 8. Invalid endpoint: exporter build error degrades to one warning"
S=$(free_port)
start_svc "$SVC_OTEL" "$S" "$WORK/invalid.log" PROBE_OTEL_ENABLED=1 OTEL_EXPORTER_OTLP_ENDPOINT='::not a url'
ok=$(hit "$S" 20 "$TP"); term_svc
$GREP -E 'otel_|WARN|ERROR' "$WORK/invalid.log" | sed 's/^/  log: /'
echo "200s: $ok/20; exit $RC"
check D08 "invalid endpoint: exactly one otel_unavailable warning" test "$($GREP -c 'WARN.*otel_unavailable' "$WORK/invalid.log")" -eq 1
check D09 "invalid endpoint: all 20 requests 200 and SIGTERM exit 143" test "$ok" -eq 20 -a "$RC" -eq 143
echo

echo "## 9. Collector unreachable (closed port): serving is unaffected, shutdown is bounded"
S=$(free_port); DEAD=$(free_port)
start_svc "$SVC_OTEL" "$S" "$WORK/flagoff-lat.log"
t0=$(ms_now); ok_base=$(hit "$S" 100); base_ms=$(( $(ms_now) - t0 )); term_svc
S=$(free_port)
start_svc "$SVC_OTEL" "$S" "$WORK/dead.log" PROBE_OTEL_ENABLED=1 OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$DEAD" OTEL_BSP_SCHEDULE_DELAY=200 PROBE_OTEL_SHUTDOWN_MS=2000
t0=$(ms_now); ok=$(hit "$S" 100 "$TP"); dead_ms=$(( $(ms_now) - t0 ))
sleep 1
term_svc
echo "flag-off baseline: $ok_base/100 200s in ${base_ms} ms; unreachable collector: $ok/100 200s in ${dead_ms} ms"
echo "exit $RC; SIGTERM-to-exit ${TERM_MS} ms with PROBE_OTEL_SHUTDOWN_MS=2000"
echo "exporter diagnostics in the log: $($GREP -ci 'opentelemetry' "$WORK/dead.log") lines mentioning opentelemetry; first three:"
$GREP -i 'opentelemetry' "$WORK/dead.log" | head -n 3 | cut -c1-240 | sed 's/^/  log: /'
$GREP -E 'otel_shutdown' "$WORK/dead.log" | cut -c1-240 | sed 's/^/  log: /'
check D10 "unreachable collector: all 100 requests 200" test "$ok" -eq 100
check D11 "unreachable collector: 100 requests take under 3x the flag-off baseline + 2 s" test "$dead_ms" -lt $(( base_ms * 3 + 2000 ))
check D12 "unreachable collector: SIGTERM exit 143" test "$RC" -eq 143
check D13 "unreachable collector: SIGTERM-to-exit under 2 s budget + 3 s slack" test "$TERM_MS" -lt 5000
check D14 "unreachable collector: export failure is visible in the log" test "$($GREP -ci 'opentelemetry' "$WORK/dead.log")" -ge 1
echo

echo "## 10. Web-only build with OTel configuration present"
C=$(free_port); S=$(free_port)
start_collector "$C" "$WORK/webonly.jsonl"
start_svc "$SVC_WEB" "$S" "$WORK/webonly.log" PROBE_OTEL_ENABLED=1 OTEL_EXPORTER_OTLP_ENDPOINT="http://127.0.0.1:$C"
ok=$(hit "$S" 10 "$TP"); term_svc; sleep 0.3; stop_pid "$CPID"
$GREP -E 'otel_|WARN' "$WORK/webonly.log" | sed 's/^/  log: /'
echo "200s: $ok/10; exit $RC; spans at collector: $(wc -l < "$WORK/webonly.jsonl" | tr -d ' ')"
check W01 "web-only build serves all 10 requests and exits 143" test "$ok" -eq 10 -a "$RC" -eq 143
check W02 "web-only build exports nothing" test ! -s "$WORK/webonly.jsonl"
check W03 "web-only build warns once that OTel configuration is ignored" test "$($GREP -c 'WARN.*otel_ignored' "$WORK/webonly.log")" -eq 1
echo

echo "# TOTAL checks=$N pass=$PASS fail=$FAIL"
exit "$FAIL"
