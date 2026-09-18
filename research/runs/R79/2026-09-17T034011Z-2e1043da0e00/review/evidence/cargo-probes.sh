#!/usr/bin/env bash
# R79 prometheus-metrics — synthesizer re-execution of the Opus report's cargo probes.
#
# Re-runs, independently of the raw report: the feature-name legality check (E1),
# the exporter default-feature dependency-tree delta (E2), the binary-size delta
# on an axum-shaped base (E3), the MSRV-aware lock (E4), cargo audit (E5), the
# in-process route-label acceptance test (E6) and the feature-off build (E7).
#
# It builds only throwaway probe packages under a $TMPDIR subdirectory it creates
# and deletes; it never builds the recommendation into this repository and never
# writes a target/ tree inside the worktree.
#
# Determinism: the resolved Cargo.lock for every probe package is snapshotted
# beside this script under locks/ on first run and reused with --locked on every
# later run, so crate counts and binary sizes are exact across reruns on the same
# toolchain. Delete locks/ to re-resolve against the live registry.
#
# Exits non-zero if any check FAILs. Every SKIP is named.

set -euo pipefail

here="$(cd "$(dirname "$0")" && pwd)"
locks="$here/locks"
mkdir -p "$locks"

GREP=/usr/bin/grep

METRICS_V=0.24.6
EXPORTER_V=0.18.3
AXUM_V=0.8.9
TOKIO_V=1.53.1
TOWER_V=0.5.3
AXUM_PROM_V=0.10.1
MSRV=1.96

pass_count=0
fail_count=0
skip_count=0

pass() { pass_count=$((pass_count + 1)); printf 'PASS  %s\n' "$*"; }
fail() { fail_count=$((fail_count + 1)); printf 'FAIL  %s\n' "$*"; }
skip() { skip_count=$((skip_count + 1)); printf 'SKIP  %s\n' "$*"; }

assert_contains() { # file needle label
  if [ -f "$1" ] && "$GREP" -qF -- "$2" "$1"; then
    pass "$3"
  else
    fail "$3 -- expected substring not found: $2"
  fi
}

assert_absent() { # file needle label
  if [ -f "$1" ] && "$GREP" -qF -- "$2" "$1"; then
    fail "$3 -- substring present but must be absent: $2"
  else
    pass "$3"
  fi
}

assert_eq() { # actual expected label
  if [ "$1" = "$2" ]; then
    pass "$3 (= $2)"
  else
    fail "$3 -- observed '$1', expected '$2'"
  fi
}

scratch="$(mktemp -d "${TMPDIR:-/tmp}/rslb-r79-probe.XXXXXX")"
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$scratch"; }
trap cleanup EXIT

echo "== toolchain and environment =="
rustc --version
cargo --version
"$GREP" --version | head -1
printf 'uname: %s %s\n' "$(uname -s)" "$(uname -m)"
printf 'date-utc: %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf 'scratch: %s\n' "$scratch"
echo

# Derive the msrv-policy floor from the live toolchain rather than asserting it.
stable_minor="$(rustc --version | sed -n 's/^rustc 1\.\([0-9][0-9]*\)\..*$/\1/p')"
if [ -n "$stable_minor" ]; then
  floor_minor=$((stable_minor - 2))
  printf 'derived: stable = 1.%s, msrv-policy floor (stable minus 2 minors) = 1.%s\n' \
    "$stable_minor" "$floor_minor"
  assert_eq "1.$floor_minor" "$MSRV" "floor derived from the live toolchain equals the probed MSRV"
else
  skip "msrv floor derivation (could not parse rustc --version)"
fi
echo

# ---------------------------------------------------------------- helpers ----

# count_tree <dir> <extra cargo tree args...> -> prints the distinct crate count
count_tree() {
  local dir="$1"
  shift
  ( cd "$dir" && cargo tree -e normal --prefix none "$@" ) \
    | sed 's/ (\*)$//' \
    | awk 'NF >= 2 { print $1" "$2 }' \
    | sort -u
}

# resolve <dir> <lockname> : reuse a snapshotted lock, or create one.
resolve() {
  local dir="$1" name="$2"
  if [ -f "$locks/$name.lock" ]; then
    cp "$locks/$name.lock" "$dir/Cargo.lock"
    printf 'lock: reused snapshot locks/%s.lock\n' "$name"
  else
    ( cd "$dir" && cargo generate-lockfile ) 2>&1 | sed 's/^/    /'
    cp "$dir/Cargo.lock" "$locks/$name.lock"
    printf 'lock: created snapshot locks/%s.lock\n' "$name"
  fi
}

# ------------------------------------------------- base A: exporter only ----
# Two manifests identical except `default-features` on the exporter. This is the
# report's "37 vs 81" base: the two metrics crates and nothing else.

for variant in nodefault default; do
  d="$scratch/baseA-$variant"
  mkdir -p "$d/src"
  if [ "$variant" = nodefault ]; then
    exporter_line="metrics-exporter-prometheus = { version = \"$EXPORTER_V\", default-features = false }"
  else
    exporter_line="metrics-exporter-prometheus = { version = \"$EXPORTER_V\" }"
  fi
  cat > "$d/Cargo.toml" <<EOF
[package]
name = "probe-a-$variant"
version = "0.0.0"
edition = "2024"
rust-version = "$MSRV"
publish = false

[dependencies]
metrics = "$METRICS_V"
$exporter_line
EOF
  echo 'pub fn probe() {}' > "$d/src/lib.rs"
  resolve "$d" "baseA-$variant"
  count_tree "$d" > "$scratch/treeA-$variant.txt"
done

a_off="$(wc -l < "$scratch/treeA-nodefault.txt" | tr -d ' ')"
a_on="$(wc -l < "$scratch/treeA-default.txt" | tr -d ' ')"

echo "== E2 : exporter default features, minimal base =="
printf 'crates with default-features = false : %s\n' "$a_off"
printf 'crates with the exporter defaults on : %s\n' "$a_on"
printf 'added by the defaults               : %s\n' "$((a_on - a_off))"
echo "-- crates the defaults add --"
comm -13 "$scratch/treeA-nodefault.txt" "$scratch/treeA-default.txt" | sed 's/^/    /'
echo

if [ "$a_on" -gt "$a_off" ]; then
  pass "E2 exporter defaults enlarge the graph ($a_off -> $a_on)"
else
  fail "E2 exporter defaults did not enlarge the graph ($a_off -> $a_on)"
fi
assert_contains "$scratch/treeA-default.txt" "aws-lc-sys" "E2 aws-lc-sys is pulled in by the exporter defaults"
assert_contains "$scratch/treeA-default.txt" "rustls" "E2 rustls is pulled in by the exporter defaults"
assert_contains "$scratch/treeA-default.txt" "hyper " "E2 hyper is pulled in by the exporter defaults"
assert_absent "$scratch/treeA-nodefault.txt" "aws-lc-sys" "E2 aws-lc-sys is absent with default-features = false"
assert_absent "$scratch/treeA-nodefault.txt" "rustls" "E2 rustls is absent with default-features = false"
assert_absent "$scratch/treeA-nodefault.txt" "tokio " "E2 no tokio edge with default-features = false"
echo

# --------------------------------------- base B: the crates/web-shaped probe --
# R69's axum + tokio feature list, plus an optional `metrics` feature whose name
# collides with an optional dependency name (E1), the acceptance test (E6), the
# binary-size delta (E3) and the feature-off build (E7).

d="$scratch/baseB"
mkdir -p "$d/src/bin" "$d/tests"
cat > "$d/Cargo.toml" <<EOF
[package]
name = "probe-web"
version = "0.0.0"
edition = "2024"
rust-version = "$MSRV"
publish = false

[lib]
name = "probe_web"
path = "src/lib.rs"

[[bin]]
name = "probe-serve"
path = "src/bin/probe-serve.rs"

[dependencies]
axum = { version = "$AXUM_V" }
tokio = { version = "$TOKIO_V", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
metrics = { version = "$METRICS_V", optional = true }
metrics-exporter-prometheus = { version = "$EXPORTER_V", optional = true, default-features = false }

[dev-dependencies]
tower = { version = "$TOWER_V", features = ["util"] }
http-body-util = "0.1"

[features]
metrics = ["dep:metrics", "dep:metrics-exporter-prometheus"]

[profile.release]
strip = true
EOF

cat > "$d/src/lib.rs" <<'RS'
use axum::{Router, routing::get};

#[cfg(feature = "metrics")]
pub mod obs;

async fn ok_handler() -> &'static str { "ok" }

async fn boom_handler() -> (axum::http::StatusCode, &'static str) {
    (axum::http::StatusCode::INTERNAL_SERVER_ERROR, "boom")
}

async fn not_found() -> axum::http::StatusCode {
    #[cfg(feature = "metrics")]
    obs::metrics::count_unmatched();
    axum::http::StatusCode::NOT_FOUND
}

pub fn build_router() -> Router {
    let business = Router::new()
        .route("/v1/projects/{id}", get(ok_handler))
        .route("/v1/boom", get(boom_handler));
    #[cfg(feature = "metrics")]
    let business = obs::metrics::instrument(business);
    business.fallback(not_found)
}
RS

mkdir -p "$d/src/obs"
cat > "$d/src/obs/mod.rs" <<'RS'
pub mod metrics;
RS

cat > "$d/src/obs/metrics.rs" <<'RS'
//! The recommended design, written out so the probe can assert its behaviour.
use axum::{
    Router,
    extract::{MatchedPath, Request},
    middleware::{self, Next},
    response::Response,
    routing::get,
};
use metrics_exporter_prometheus::{Matcher, PrometheusBuilder, PrometheusHandle};
use std::{sync::OnceLock, time::Instant};

pub const DURATION: &str = "http_server_request_duration_seconds";
pub const UNMATCHED: &str = "http_server_unmatched_requests_total";

/// OTel semconv advised ExplicitBucketBoundaries for http.server.request.duration.
pub const BUCKETS: &[f64] = &[
    0.005, 0.01, 0.025, 0.05, 0.075, 0.1, 0.25, 0.5, 0.75, 1.0, 2.5, 5.0, 7.5, 10.0,
];

static HANDLE: OnceLock<PrometheusHandle> = OnceLock::new();

pub fn recorder() -> &'static PrometheusHandle {
    HANDLE.get_or_init(|| {
        let handle = PrometheusBuilder::new()
            .set_buckets_for_metric(Matcher::Full(DURATION.to_string()), BUCKETS)
            .expect("bucket list is non-empty")
            .install_recorder()
            .expect("no other global recorder is installed");
        metrics::describe_histogram!(
            DURATION,
            metrics::Unit::Seconds,
            "Duration of HTTP server requests."
        );
        metrics::describe_counter!(UNMATCHED, "HTTP requests that matched no route template.");
        handle
    })
}

pub async fn run_upkeep(handle: &'static PrometheusHandle) {
    let mut ticker = tokio::time::interval(std::time::Duration::from_secs(5));
    loop {
        ticker.tick().await;
        handle.run_upkeep();
    }
}

async fn track(req: Request, next: Next) -> Response {
    let start = Instant::now();
    let method = req.method().as_str().to_owned();
    let route = req
        .extensions()
        .get::<MatchedPath>()
        .map(|p| p.as_str().to_owned());
    let response = next.run(req).await;
    let status = response.status().as_u16().to_string();
    if let Some(route) = route {
        metrics::histogram!(
            DURATION,
            "http_request_method" => method,
            "http_route" => route,
            "http_response_status_code" => status,
        )
        .record(start.elapsed().as_secs_f64());
    }
    response
}

pub fn count_unmatched() {
    metrics::counter!(UNMATCHED).increment(1);
}

pub fn instrument(business: Router) -> Router {
    let handle = recorder();
    business
        .route_layer(middleware::from_fn(track))
        .merge(Router::new().route("/metrics", get(move || async move { handle.render() })))
}
RS

# The size probe must link what a real serve binary links -- the tokio
# multi-thread runtime, the listener and axum::serve -- or the measured delta is
# taken against a binary that never pulls the server machinery in. The bind is
# behind an env guard that the probe never sets, so the binary is linked but the
# script never starts a listener.
cat > "$d/src/bin/probe-serve.rs" <<'RS'
#[tokio::main]
async fn main() -> std::process::ExitCode {
    let router = probe_web::build_router();
    #[cfg(feature = "metrics")]
    {
        tokio::spawn(probe_web::obs::metrics::run_upkeep(
            probe_web::obs::metrics::recorder(),
        ));
    }
    if std::env::var_os("PROBE_SERVE_BIND").is_none() {
        return std::process::ExitCode::from(0);
    }
    let listener = match tokio::net::TcpListener::bind("127.0.0.1:0").await {
        Ok(listener) => listener,
        Err(_) => return std::process::ExitCode::from(1),
    };
    match axum::serve(listener, router)
        .with_graceful_shutdown(async { let _ = tokio::signal::ctrl_c().await; })
        .await
    {
        Ok(()) => std::process::ExitCode::from(0),
        Err(_) => std::process::ExitCode::from(1),
    }
}
RS

cat > "$d/tests/metrics.rs" <<'RS'
#![cfg(feature = "metrics")]
use axum::{Router, body::Body, http::Request};
use http_body_util::BodyExt;
use std::collections::BTreeSet;
use tower::ServiceExt;

async fn call(app: &Router, uri: &str) -> (axum::http::StatusCode, String) {
    let response = app
        .clone()
        .oneshot(Request::builder().uri(uri).body(Body::empty()).unwrap())
        .await
        .unwrap();
    let status = response.status();
    let bytes = response.into_body().collect().await.unwrap().to_bytes();
    (status, String::from_utf8_lossy(&bytes).into_owned())
}

fn distinct_http_route_values(body: &str) -> BTreeSet<String> {
    let mut found = BTreeSet::new();
    for piece in body.split("http_route=\"").skip(1) {
        if let Some(end) = piece.find('"') {
            found.insert(piece[..end].to_string());
        }
    }
    found
}

#[tokio::test(flavor = "multi_thread")]
async fn red_metrics_acceptance() {
    let app = probe_web::build_router();

    assert_eq!(call(&app, "/v1/projects/7").await.0, axum::http::StatusCode::OK);
    assert_eq!(
        call(&app, "/v1/boom").await.0,
        axum::http::StatusCode::INTERNAL_SERVER_ERROR
    );
    assert_eq!(
        call(&app, "/nope/deep/path").await.0,
        axum::http::StatusCode::NOT_FOUND
    );
    for i in 0..50 {
        let _ = call(&app, &format!("/v1/projects/{i}")).await;
    }

    assert_eq!(call(&app, "/metrics").await.0, axum::http::StatusCode::OK);
    let (status, body) = call(&app, "/metrics").await;
    assert_eq!(status, axum::http::StatusCode::OK);

    // A1 route template, not URI; A3 _count is the rate signal; 51 = 1 + 50.
    assert!(
        body.contains(
            "http_server_request_duration_seconds_count{http_request_method=\"GET\",http_route=\"/v1/projects/{id}\",http_response_status_code=\"200\"} 51"
        ),
        "missing templated _count series; body was:\n{body}"
    );
    // A2 the failing request carries its status code.
    assert!(body.contains("http_route=\"/v1/boom\",http_response_status_code=\"500\""));
    // A3 buckets and _sum are present.
    assert!(body.contains("http_server_request_duration_seconds_bucket"));
    assert!(body.contains("http_server_request_duration_seconds_sum"));
    // A6 an unmatched request produces no route-labelled series.
    assert!(body.contains("http_server_unmatched_requests_total 1"));
    // A5 two scrapes leave no series labelled with /metrics.
    assert!(!body.contains("http_route=\"/metrics\""));
    // A4 51 requests over 50 distinct path parameters -> one route label value.
    let routes = distinct_http_route_values(&body);
    assert_eq!(
        routes,
        BTreeSet::from(["/v1/boom".to_string(), "/v1/projects/{id}".to_string()]),
        "unexpected http_route label set"
    );

    println!("PROBE distinct http_route label values = {routes:?}");
    // The whole body, so the exposition text can be handed to the Prometheus
    // project's own parser rather than only to String::contains.
    println!("SCRAPE-BEGIN");
    for line in body.lines() {
        println!("SCRAPE {line}");
    }
    println!("SCRAPE-END");
}
RS

echo "== E1 : a Cargo feature named \`metrics\` beside an optional dependency named \`metrics\` =="
resolve "$d" "baseB"
if ( cd "$d" && cargo check --locked --features metrics --all-targets ) > "$scratch/e1.log" 2>&1; then
  pass "E1 cargo check --features metrics compiled (dep:metrics suppresses the implicit feature)"
else
  fail "E1 cargo check --features metrics failed"
  tail -40 "$scratch/e1.log" | sed 's/^/    /'
fi
( cd "$d" && cargo tree -e normal --locked --features metrics --prefix none ) > "$scratch/e1-tree.txt"
assert_contains "$scratch/e1-tree.txt" "metrics v$METRICS_V" "E1 the optional dependency metrics $METRICS_V resolved"
assert_contains "$scratch/e1-tree.txt" "metrics-exporter-prometheus v$EXPORTER_V" "E1 the exporter $EXPORTER_V resolved"
echo

echo "== E3/E7 : dependency-graph and stripped-binary delta on R69's axum base =="
count_tree "$d" --locked > "$scratch/treeB-on.txt" --features metrics
count_tree "$d" --locked > "$scratch/treeB-off.txt"
b_on="$(wc -l < "$scratch/treeB-on.txt" | tr -d ' ')"
b_off="$(wc -l < "$scratch/treeB-off.txt" | tr -d ' ')"
printf 'crates, feature off : %s\n' "$b_off"
printf 'crates, feature on  : %s\n' "$b_on"
printf 'added by the feature: %s\n' "$((b_on - b_off))"
echo "-- crates the metrics feature adds to crates/web --"
comm -13 "$scratch/treeB-off.txt" "$scratch/treeB-on.txt" | sed 's/^/    /'
echo

assert_absent "$scratch/treeB-on.txt" "tower-http " "E3 tower-http does NOT join the runtime graph with metrics on"
assert_contains "$scratch/treeB-off.txt" "tower " "E3 tower is already a runtime crate of the axum base (not added by metrics)"
assert_contains "$scratch/treeB-on.txt" "metrics " "E3 the facade is in the runtime graph with the feature on"
assert_absent "$scratch/treeB-off.txt" "metrics-exporter-prometheus " "E7 the exporter is absent with the feature off"

if ( cd "$d" && cargo build --locked --release --bin probe-serve ) > "$scratch/build-off.log" 2>&1; then
  size_off="$(stat -f %z "$d/target/release/probe-serve" 2>/dev/null || stat -c %s "$d/target/release/probe-serve")"
  pass "E7 release build with the metrics feature off succeeded"
else
  size_off=""
  fail "E7 release build with the metrics feature off failed"
  tail -30 "$scratch/build-off.log" | sed 's/^/    /'
fi
if ( cd "$d" && cargo build --locked --release --features metrics --bin probe-serve ) > "$scratch/build-on.log" 2>&1; then
  size_on="$(stat -f %z "$d/target/release/probe-serve" 2>/dev/null || stat -c %s "$d/target/release/probe-serve")"
  pass "E3 release build with the metrics feature on succeeded"
else
  size_on=""
  fail "E3 release build with the metrics feature on failed"
  tail -30 "$scratch/build-on.log" | sed 's/^/    /'
fi
if [ -n "$size_off" ] && [ -n "$size_on" ]; then
  printf 'stripped release binary, feature off : %s B\n' "$size_off"
  printf 'stripped release binary, feature on  : %s B\n' "$size_on"
  printf 'delta                                : %s B\n' "$((size_on - size_off))"
  if [ "$size_on" -gt "$size_off" ]; then
    pass "E3 the metrics feature enlarges the stripped binary ($size_off -> $size_on B)"
  else
    fail "E3 the metrics feature did not enlarge the stripped binary ($size_off -> $size_on B)"
  fi
else
  skip "E3 binary-size delta (a release build failed above)"
fi
echo

echo "== E6 : the in-process RED acceptance test =="
if ( cd "$d" && cargo test --locked --features metrics --test metrics -- --nocapture ) > "$scratch/e6.log" 2>&1; then
  pass "E6 the acceptance test passed"
else
  fail "E6 the acceptance test failed"
fi
# The scrape body is timing-dependent in three ways that no amount of pinning
# removes: the exporter renders its two label sets in an unstable order, the
# observed `_sum` durations differ every run, and the occupancy of the smallest
# latency buckets moves when a request happens to take longer than 5 ms. So the
# LOG carries a canonical form -- sorted, with bucket occupancies and the `_sum`
# value redacted -- which is byte-stable, while the verbatim capture that
# promtool parses is written to evidence/scrape-sample.txt below. Series
# identities, the `_count` value and the counter value are all kept, because
# those are what the acceptance criteria assert.
sed -n '/running 1 test/,$p' "$scratch/e6.log" \
  | "$GREP" -v '^SCRAPE ' \
  | sed 's/finished in [0-9.]*s/finished in <elapsed>/' \
  | sed 's/^/    /'
echo "-- canonical scrape (sorted; bucket occupancy and _sum redacted; see scrape-sample.txt for the verbatim capture) --"
"$GREP" '^SCRAPE ' "$scratch/e6.log" \
  | sed 's/^SCRAPE //' \
  | sed 's/^\(http_server_request_duration_seconds_bucket{.*}\) [0-9][0-9]*$/\1 <occupancy>/' \
  | sed 's/^\(http_server_request_duration_seconds_sum{.*}\) [0-9.e-]*$/\1 <duration>/' \
  | sort \
  | sed 's/^/    /'
assert_contains "$scratch/e6.log" 'test red_metrics_acceptance ... ok' "E6 the named test reported ok"
assert_contains "$scratch/e6.log" 'PROBE distinct http_route label values = {"/v1/boom", "/v1/projects/{id}"}' \
  "E6 51 requests over 50 distinct ids produced exactly two route label values"
assert_contains "$scratch/e6.log" "1 passed" "E6 exactly one test passed"
echo

echo "== E8 : promtool conformance parse of the exposition text the test produced =="
# The Opus report left this check PROPOSED. It is executed here: the scrape the
# acceptance test printed is handed to the Prometheus project's own parser, which
# is the only thing that decides whether the bytes are valid exposition format.
sed -n '/^SCRAPE-BEGIN$/,/^SCRAPE-END$/p' "$scratch/e6.log" \
  | sed '1d;$d' \
  | sed 's/^SCRAPE //; s/^SCRAPE$//' > "$here/scrape-sample.txt"
sample_lines="$(wc -l < "$here/scrape-sample.txt" | tr -d ' ')"
printf 'scrape captured to evidence/scrape-sample.txt : %s lines\n' "$sample_lines"
if [ "$sample_lines" -lt 20 ]; then
  fail "E8 the captured scrape is implausibly short ($sample_lines lines)"
else
  pass "E8 captured a full scrape from the acceptance test ($sample_lines lines)"
fi
promtool_bin="${PROMTOOL:-$(command -v promtool || true)}"
if [ -z "$promtool_bin" ] && [ -x "${TMPDIR:-/tmp}/r79-promtool/prometheus-3.14.0.darwin-arm64/promtool" ]; then
  promtool_bin="${TMPDIR:-/tmp}/r79-promtool/prometheus-3.14.0.darwin-arm64/promtool"
fi
if [ -z "$promtool_bin" ]; then
  skip "E8 promtool check metrics (no promtool on PATH and none at \$PROMTOOL; install Prometheus or set PROMTOOL=<path> to run it)"
else
  "$promtool_bin" --version 2>&1 | head -1 | sed 's/^/    /'
  if "$promtool_bin" check metrics < "$here/scrape-sample.txt" > "$scratch/promtool.log" 2>&1; then
    pass "E8 promtool check metrics accepted the exposition text"
  else
    fail "E8 promtool check metrics rejected the exposition text"
  fi
  sed 's/^/    /' "$scratch/promtool.log"
  if "$GREP" -qiE "error|invalid|parse" "$scratch/promtool.log"; then
    fail "E8 promtool printed an error/invalid/parse line"
  else
    pass "E8 promtool printed no error, invalid or parse complaint"
  fi
fi
echo

echo "== E4 : the MSRV-aware lock at rust-version = $MSRV =="
e4="$scratch/baseB-msrv"
mkdir -p "$e4"
cp -R "$d/Cargo.toml" "$e4/Cargo.toml"
mkdir -p "$e4/src/bin" "$e4/tests"
cp "$d/src/lib.rs" "$e4/src/lib.rs"
cp -R "$d/src/obs" "$e4/src/obs"
cp "$d/src/bin/probe-serve.rs" "$e4/src/bin/probe-serve.rs"
cp "$d/tests/metrics.rs" "$e4/tests/metrics.rs"
( cd "$e4" && cargo generate-lockfile ) > "$scratch/e4.log" 2>&1 || true
sed 's/^/    /' "$scratch/e4.log"
if "$GREP" -qE "Locking [0-9]+ packages to latest Rust $MSRV compatible versions" "$scratch/e4.log"; then
  pass "E4 cargo resolved with the MSRV-aware resolver at Rust $MSRV"
elif "$GREP" -q "Locking" "$scratch/e4.log"; then
  fail "E4 cargo locked but not with the 'latest Rust $MSRV compatible versions' message"
else
  skip "E4 MSRV-aware resolution message (cargo printed no Locking line; see the log above)"
fi
locked_n="$("$GREP" -oE "Locking [0-9]+ packages" "$scratch/e4.log" | awk '{print $2}' | head -1)"
printf 'packages locked under rust-version = %s : %s\n' "$MSRV" "${locked_n:-unknown}"

echo "-- highest declared rust-version in the resolved non-dev tree, --features metrics --"
# The walk must be restricted to the crates the `cargo tree -e normal --features
# metrics` graph actually contains. A bare `cargo metadata` resolves the default
# feature set and includes dev-dependencies, so it would answer for a graph that
# is neither the one this decision ships nor the one gate 2 is asked about.
( cd "$e4" && cargo metadata --format-version 1 --features metrics \
    --filter-platform "$(rustc -vV | sed -n 's/^host: //p')" ) \
  > "$scratch/metadata.json" 2>/dev/null || true
if [ -s "$scratch/metadata.json" ]; then
  python3 - "$scratch/metadata.json" "$scratch/treeB-on.txt" <<'PY' > "$scratch/msrv.txt"
import json, sys
meta = json.load(open(sys.argv[1]))
wanted = set()
with open(sys.argv[2]) as handle:
    for line in handle:
        parts = line.split()
        if len(parts) >= 2:
            wanted.add((parts[0], parts[1].lstrip("v")))
rows = []
undeclared = []
for pkg in meta["packages"]:
    if (pkg["name"], pkg["version"]) not in wanted:
        continue
    if pkg["name"].startswith("probe-"):
        continue  # the probe package itself is not a dependency
    rv = pkg.get("rust_version")
    if rv:
        rows.append((tuple(int(x) for x in rv.split(".")), rv, pkg["name"], pkg["version"]))
    else:
        undeclared.append(pkg["name"])
rows.sort(reverse=True)
for key, rv, name, version in rows[:6]:
    print(f"    {rv:10} {name} {version}")
print(f"HIGHEST {rows[0][1]} {rows[0][2]} {rows[0][3]}")
print(f"UNDECLARED {len(undeclared)} packages declare no rust-version")
PY
  sed 's/^/    /' "$scratch/msrv.txt"
  highest="$("$GREP" '^HIGHEST ' "$scratch/msrv.txt" | awk '{print $2}')"
  hi_major="${highest%%.*}"
  hi_rest="${highest#*.}"
  hi_minor="${hi_rest%%.*}"
  floor_minor_cmp="${MSRV#*.}"
  if [ "$hi_major" = "1" ] && [ "$hi_minor" -le "$floor_minor_cmp" ]; then
    pass "E4 highest declared rust-version in the resolved tree ($highest) is inside the $MSRV floor"
  else
    fail "E4 highest declared rust-version in the resolved tree ($highest) exceeds the $MSRV floor"
  fi
else
  skip "E4 highest-declared-rust-version walk (cargo metadata produced no output)"
fi
echo

echo "== E5 : cargo audit over the resolved lockfile =="
if command -v cargo-audit > /dev/null 2>&1; then
  cargo audit --version
  if ( cd "$e4" && cargo audit --file Cargo.lock ) > "$scratch/audit.log" 2>&1; then
    pass "E5 cargo audit reported no vulnerable crates"
  else
    fail "E5 cargo audit reported findings"
  fi
  sed 's/^/    /' "$scratch/audit.log"
  assert_contains "$scratch/audit.log" "Scanning Cargo.lock for vulnerabilities" "E5 audit scanned the lockfile"
  if "$GREP" -qE "^error:|[0-9]+ vulnerabilit(y|ies) found" "$scratch/audit.log"; then
    fail "E5 the audit log reports vulnerabilities"
  else
    pass "E5 the audit log reports no vulnerabilities"
  fi
  assert_absent "$scratch/audit.log" "RUSTSEC-2021-0113" "E5 RUSTSEC-2021-0113 (metrics-util) does not apply to the resolved tree"
  "$GREP" -E "metrics-util" "$scratch/treeB-on.txt" | sed 's/^/    resolved: /' || true
else
  skip "E5 cargo audit (cargo-audit is not installed on this machine)"
fi
echo

# ------------------------------------------- base C: the ranked runner-up ----
echo "== runner-up footprint : axum-prometheus $AXUM_PROM_V on the same axum base =="
c="$scratch/baseC"
mkdir -p "$c/src"
cat > "$c/Cargo.toml" <<EOF
[package]
name = "probe-runner-up"
version = "0.0.0"
edition = "2024"
rust-version = "$MSRV"
publish = false

[dependencies]
axum = { version = "$AXUM_V" }
tokio = { version = "$TOKIO_V", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
axum-prometheus = "$AXUM_PROM_V"
EOF
echo 'pub fn probe() {}' > "$c/src/lib.rs"
resolve "$c" "baseC"
count_tree "$c" --locked > "$scratch/treeC.txt"
c_n="$(wc -l < "$scratch/treeC.txt" | tr -d ' ')"
printf 'crates, axum base + axum-prometheus : %s\n' "$c_n"
printf 'crates, axum base + recommended pair: %s\n' "$b_on"
echo "-- crates axum-prometheus adds that the recommended pair does not --"
comm -13 "$scratch/treeB-on.txt" "$scratch/treeC.txt" | sed 's/^/    /'
assert_contains "$scratch/treeC.txt" "tower-http " "runner-up adds tower-http to the runtime graph"
assert_contains "$scratch/treeC.txt" "metrics-exporter-prometheus " "runner-up carries the same exporter transitively"
if [ "$c_n" -gt "$b_on" ]; then
  pass "runner-up graph is larger than the recommended pair ($b_on -> $c_n)"
else
  fail "runner-up graph is not larger than the recommended pair ($b_on -> $c_n)"
fi
echo

# ------------------------------------------------------------- summary ------
echo "== summary =="
printf 'PASS=%s FAIL=%s SKIP=%s TOTAL=%s\n' \
  "$pass_count" "$fail_count" "$skip_count" "$((pass_count + fail_count + skip_count))"
if [ "$fail_count" -ne 0 ]; then
  exit 1
fi
exit 0
