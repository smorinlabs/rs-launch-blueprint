#!/usr/bin/env bash
# R74 — throwaway Cargo probes that verify what the raw reports assert.
#
# NOT a template scaffold. Every crate this script writes lives under a directory
# created inside $TMPDIR and is deleted when the script exits. Nothing is written
# into the repository except this script and its log.
#
# It re-derives, on R69's accepted pins (axum 0.8.9, tokio 1.53.1, tower 0.5.3 dev):
#   A. the seven behavioural tests of the recommended zero-crate GCRA design
#   B. the two measured tower_governor 0.8.0 defects (500 without ConnectInfo;
#      a Retry-After truncated by Duration::as_secs())
#   C. the +0 / +37 / +49 non-dev dependency-tree deltas
#   D. the gate-2 rust-version reads at the registry (unpacked published manifests)
#   E. what tower-rate-limiter 0.1.6 is (the openai leg's pick, which no other leg found)
#
# Every check asserts on CONTENT. Counts are printed and summed; a FAIL exits non-zero.
set -euo pipefail

PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
chk()  { # chk <label> <expected> <actual>
  if [ "$2" = "$3" ]; then ok "$1 == $2"; else bad "$1: expected [$2] got [$3]"; fi
}
has()  { # has <label> <needle> <file>
  if /usr/bin/grep -qF -- "$2" "$3"; then ok "$1"; else bad "$1 (missing: $2)"; fi
}
hasnt() { # hasnt <label> <needle> <file>
  if /usr/bin/grep -qF -- "$2" "$3"; then bad "$1 (unexpectedly present: $2)"; else ok "$1"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r74-probe.XXXXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

echo "toolchain: $(rustc --version)"
echo "cargo:     $(cargo --version)"
echo "os:        $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null || echo n-a)"
echo "grep:      $(/usr/bin/grep --version | head -1)"
echo "workdir:   $WORK (deleted on exit)"
echo

# ---------------------------------------------------------------------------
# D. Gate 2 — declared rust-version in the PUBLISHED manifests, read at the registry
# ---------------------------------------------------------------------------
echo "=== D. gate 2: declared rust-version in the published manifests ==="
REG="$HOME/.cargo/registry/src/index.crates.io-1949cf8c6b5b557f"
rv_of() { # rv_of <unpacked-dir>  -> the declared rust-version, or the literal NONE
  local m="$REG/$1/Cargo.toml"
  if [ ! -f "$m" ]; then echo "NO-MANIFEST"; return; fi
  local v
  v="$(/usr/bin/grep -m1 -E '^rust-version[[:space:]]*=' "$m" | sed -E 's/.*=[[:space:]]*"?([^"]*)"?.*/\1/')"
  if [ -z "$v" ]; then echo "NONE"; else echo "$v"; fi
}
ed_of() { /usr/bin/grep -m1 -E '^edition[[:space:]]*=' "$REG/$1/Cargo.toml" | sed -E 's/.*=[[:space:]]*"([^"]*)".*/\1/'; }

for pair in "tower_governor-0.8.0 NONE 2021" "governor-0.10.4 NONE 2018" "axum-governor-2.1.0 1.95 2024" "gcra-0.6.0 1.80.0 2021" "axum-0.8.9 1.80 2021" "tower-0.5.3 1.64.0 2018"; do
  read -r d want_rv want_ed <<< "$pair"
  if [ -d "$REG/$d" ]; then
    chk "D-rv $d" "$want_rv" "$(rv_of "$d")"
    chk "D-ed $d" "$want_ed" "$(ed_of "$d")"
  else
    skip "D $d — not unpacked in this CARGO_HOME registry cache"
    skip "D-ed $d — not unpacked in this CARGO_HOME registry cache"
  fi
done

# Control: the reader must be able to find a version when one is declared, so the
# two NONE results above cannot come from a broken reader.
if [ -d "$REG/axum-0.8.9" ]; then
  if [ "$(rv_of axum-0.8.9)" = "NONE" ]; then bad "D-control: reader returned NONE for a crate that declares 1.80"; else ok "D-control: reader finds a declared rust-version"; fi
else
  skip "D-control — axum-0.8.9 not unpacked"
fi

# ---------------------------------------------------------------------------
# tower_governor source facts the two defects rest on
# ---------------------------------------------------------------------------
echo
echo "=== D2. tower_governor 0.8.0 source facts ==="
TG="$REG/tower_governor-0.8.0"
if [ -d "$TG" ]; then
  # the truncation
  n_as_secs="$(/usr/bin/grep -c '\.as_secs()' "$TG/src/lib.rs" || true)"
  if [ "$n_as_secs" -ge 2 ]; then ok "D2a wait_time is computed with .as_secs() (truncating) at $n_as_secs sites in src/lib.rs"; else bad "D2a expected >=2 .as_secs() sites, got $n_as_secs"; fi
  has  "D2b retry-after IS inserted (correcting the 'x-ratelimit-after only' claim)" 'headers.insert("retry-after", wait_time.into());' "$TG/src/lib.rs"
  has  "D2c a new X- prefixed quota header is emitted"                               'headers.insert("x-ratelimit-after", wait_time.into());' "$TG/src/lib.rs"
  # the 500
  has  "D2d PeerIpKeyExtractor returns UnableToExtractKey when ConnectInfo is absent" 'maybe_connect_info(req).ok_or(GovernorError::UnableToExtractKey)' "$TG/src/key_extractor.rs"
  has  "D2e UnableToExtractKey renders INTERNAL_SERVER_ERROR"                         'parts.status = StatusCode::INTERNAL_SERVER_ERROR;' "$TG/src/errors.rs"
  # the rejection body is plain text with no content-type
  has  "D2f the 429 body is a plain string, not problem+json"                         'Response::new(format!("Too Many Requests! Wait for {}s", wait_time))' "$TG/src/errors.rs"
  # tonic is a DEFAULT feature
  if sed -n '/^\[features\]/,/^\[lib\]/p' "$TG/Cargo.toml" | /usr/bin/grep -q '"tonic"'; then ok "D2g tonic is in tower_governor's default feature set"; else bad "D2g tonic not found in the default feature set"; fi
else
  for l in D2a D2b D2c D2d D2e D2f D2g; do skip "$l — tower_governor-0.8.0 not unpacked"; done
fi

# ---------------------------------------------------------------------------
# A + B. Behavioural probes
# ---------------------------------------------------------------------------
BASE_DEPS='axum = { version = "=0.8.9" }
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }'

mk_manifest() { # mk_manifest <dir> <name> <extra-deps-block>
  mkdir -p "$1/src"
  cat > "$1/Cargo.toml" <<MANIFEST
[package]
name = "$2"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
$BASE_DEPS
$3

[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
MANIFEST
}

echo
echo "=== A. the recommended zero-crate GCRA design (7 tests) ==="
DESIGN="$WORK/probe-design"
mk_manifest "$DESIGN" "probe_design" ""
cat > "$DESIGN/src/lib.rs" <<'RUST'
//! Throwaway probe of R74's recommended design. Not template code.
use std::collections::HashMap;
use std::net::{IpAddr, SocketAddr};
use std::num::NonZeroU32;
use std::str::FromStr;
use std::sync::{Arc, Mutex, Once};
use std::time::{Duration, Instant};

use axum::Router;
use axum::extract::{ConnectInfo, Request, State};
use axum::http::{HeaderValue, StatusCode};
use axum::middleware::Next;
use axum::response::{IntoResponse, Response};

/// Sustained rate and burst are INDEPENDENT, because the org REST API Design Standard's
/// R8.10 rate-limit axis names "per-principal sustained + token-bucket burst" as two
/// things. GCRA carries both: emission interval T = period / rate, tolerance = (burst-1)*T.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct RateLimitPolicy {
    pub rate: NonZeroU32,
    pub period: Duration,
    pub burst: NonZeroU32,
}

#[derive(Debug, PartialEq, Eq)]
pub enum PolicyParseError {
    MissingSlash,
    BadCount,
    ZeroCount,
    UnknownPeriod,
}

impl FromStr for RateLimitPolicy {
    type Err = PolicyParseError;
    /// py's `limits` notation `"<count>/<period>"`. Burst defaults to the count; a
    /// separate variable raises it.
    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let (count, period) = s.split_once('/').ok_or(PolicyParseError::MissingSlash)?;
        let n: u32 = count.trim().parse().map_err(|_| PolicyParseError::BadCount)?;
        let rate = NonZeroU32::new(n).ok_or(PolicyParseError::ZeroCount)?;
        let period = match period.trim() {
            "second" | "sec" | "s" => Duration::from_secs(1),
            "minute" | "min" | "m" => Duration::from_secs(60),
            "hour" | "hr" | "h" => Duration::from_secs(3600),
            "day" | "d" => Duration::from_secs(86_400),
            _ => return Err(PolicyParseError::UnknownPeriod),
        };
        Ok(Self { rate, period, burst: rate })
    }
}

impl RateLimitPolicy {
    /// The shipped posture. R8.10's axis default starts at ~100 rps/account for an
    /// authenticated principal and puts an unauthenticated per-IP rate "an order of
    /// magnitude lower"; this surface has no principal, so 10/second is that figure.
    /// The burst of 20 is this template's starting choice, not the standard's.
    pub fn default_posture() -> Self {
        Self {
            rate: NonZeroU32::new(10).expect("nonzero"),
            period: Duration::from_secs(1),
            burst: NonZeroU32::new(20).expect("nonzero"),
        }
    }
    pub fn with_burst(mut self, burst: NonZeroU32) -> Self {
        self.burst = burst;
        self
    }
    pub fn emission_interval(&self) -> Duration {
        self.period / self.rate.get()
    }
    pub fn tolerance(&self) -> Duration {
        self.emission_interval() * (self.burst.get() - 1)
    }
}

#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum RateLimitKey {
    Peer(IpAddr),
    Global,
}

/// The named swap point: a distributed store is a second implementor, not a rewrite.
pub trait RateLimitStore: Send + Sync {
    /// `Ok(())` admitted; `Err(next_allowed_at)` refused.
    fn check(&self, key: &RateLimitKey, now: Instant) -> Result<(), Instant>;
}

pub struct InMemoryRateLimitStore {
    policy: RateLimitPolicy,
    capacity: usize,
    cells: Mutex<HashMap<RateLimitKey, Instant>>,
}

impl InMemoryRateLimitStore {
    pub fn new(policy: RateLimitPolicy, capacity: usize) -> Self {
        Self { policy, capacity, cells: Mutex::new(HashMap::new()) }
    }
    pub fn len(&self) -> usize {
        self.cells.lock().expect("poisoned").len()
    }
    pub fn is_empty(&self) -> bool {
        self.len() == 0
    }
}

impl RateLimitStore for InMemoryRateLimitStore {
    fn check(&self, key: &RateLimitKey, now: Instant) -> Result<(), Instant> {
        let interval = self.policy.emission_interval();
        let tolerance = self.policy.tolerance();
        let mut cells = self.cells.lock().expect("poisoned");
        if !cells.contains_key(key) && cells.len() >= self.capacity {
            cells.retain(|_, tat| *tat > now);
            if cells.len() >= self.capacity {
                return Ok(()); // bounded store saturated: fail OPEN, deliberately
            }
        }
        let stored = cells.get(key).copied().unwrap_or(now);
        let tat = if stored > now { stored } else { now };
        if tat > now + tolerance {
            Err(tat - tolerance)
        } else {
            cells.insert(*key, tat + interval);
            Ok(())
        }
    }
}

/// RFC 9110 s10.2.3: delay-seconds is a non-negative decimal integer. Ceiling, floored at 1,
/// so a client that obeys the header is never refused a second time for the same reason.
pub fn retry_after_seconds(next_allowed_at: Instant, now: Instant) -> u64 {
    let d = next_allowed_at.saturating_duration_since(now);
    let whole = d.as_secs();
    let ceiling = if d.subsec_nanos() > 0 { whole + 1 } else { whole };
    if ceiling == 0 { 1 } else { ceiling }
}

#[derive(Debug, Clone, Copy)]
pub struct RateLimited {
    pub retry_after: u64,
    pub policy: RateLimitPolicy,
}

impl IntoResponse for RateLimited {
    fn into_response(self) -> Response {
        // PLACEHOLDER body. R70 owns the problem+json envelope; this probe asserts
        // only the status and the headers this item is responsible for.
        let mut r = (StatusCode::TOO_MANY_REQUESTS, "rate limit exceeded").into_response();
        let h = r.headers_mut();
        h.insert("retry-after", HeaderValue::from(self.retry_after));
        // org REST API Design Standard R11.3, in the syntax of
        // draft-ietf-httpapi-ratelimit-headers-11. The draft's q/w pair describes the
        // SUSTAINED rate only; the burst tolerance has no field in it.
        let quota = self.policy.rate.get();
        let window = self.policy.period.as_secs();
        h.insert(
            "ratelimit",
            HeaderValue::from_str(&format!("\"default\";r=0;t={}", self.retry_after)).expect("ascii"),
        );
        h.insert(
            "ratelimit-policy",
            HeaderValue::from_str(&format!("\"default\";q={quota};w={window}")).expect("ascii"),
        );
        r
    }
}

#[derive(Clone)]
pub struct RateLimitState {
    pub store: Arc<dyn RateLimitStore>,
    pub policy: RateLimitPolicy,
}

static NO_CONNECT_INFO: Once = Once::new();

pub async fn rate_limit(
    State(state): State<RateLimitState>,
    req: Request,
    next: Next,
) -> Result<Response, RateLimited> {
    let key = match req.extensions().get::<ConnectInfo<SocketAddr>>() {
        Some(ConnectInfo(addr)) => RateLimitKey::Peer(addr.ip()),
        None => {
            NO_CONNECT_INFO.call_once(|| {
                eprintln!("rate limit: no ConnectInfo on the request; all callers share one bucket");
            });
            RateLimitKey::Global
        }
    };
    let now = Instant::now();
    match state.store.check(&key, now) {
        Ok(()) => Ok(next.run(req).await),
        Err(next_at) => Err(RateLimited {
            retry_after: retry_after_seconds(next_at, now),
            policy: state.policy,
        }),
    }
}

/// The whole gate: an unset policy means the layer is never registered.
pub fn install_rate_limit(
    router: Router,
    policy: Option<RateLimitPolicy>,
    capacity: usize,
) -> (Router, Option<Arc<InMemoryRateLimitStore>>) {
    match policy {
        None => (router, None),
        Some(p) => {
            let store = Arc::new(InMemoryRateLimitStore::new(p, capacity));
            let state = RateLimitState { store: store.clone(), policy: p };
            (router.layer(axum::middleware::from_fn_with_state(state, rate_limit)), Some(store))
        }
    }
}
RUST

cat > "$DESIGN/src/main.rs" <<'RUST'
fn main() {}
RUST

mkdir -p "$DESIGN/tests"
cat > "$DESIGN/tests/acceptance.rs" <<'RUST'
use std::net::SocketAddr;
use std::str::FromStr;
use std::time::{Duration, Instant};

use axum::Router;
use axum::body::Body;
use axum::extract::ConnectInfo;
use axum::http::{Request, StatusCode};
use axum::routing::get;
use probe_design::*;
use tower::ServiceExt;

fn app(policy: Option<&str>, capacity: usize) -> (Router, Option<std::sync::Arc<InMemoryRateLimitStore>>) {
    let r = Router::new().route("/", get(|| async { "ok" }));
    let p = policy.map(|s| RateLimitPolicy::from_str(s).expect("policy parses"));
    install_rate_limit(r, p, capacity)
}

async fn call(app: &Router, ip: Option<&str>) -> axum::response::Response {
    let mut req = Request::builder().uri("/").body(Body::empty()).unwrap();
    if let Some(ip) = ip {
        let addr: SocketAddr = format!("{ip}:40000").parse().unwrap();
        req.extensions_mut().insert(ConnectInfo(addr));
    }
    app.clone().oneshot(req).await.unwrap()
}

#[tokio::test]
async fn off_by_default_is_the_absence_of_the_layer() {
    let (app, store) = app(None, 16);
    assert!(store.is_none(), "no policy means no store exists at all");
    for i in 0..1000 {
        let r = call(&app, Some("10.0.0.1")).await;
        assert_eq!(r.status(), StatusCode::OK, "request {i} must be admitted");
    }
}

#[tokio::test]
async fn conditional_registration_is_the_gate() {
    let (off, _) = app(None, 16);
    for _ in 0..50 {
        assert_eq!(call(&off, Some("10.0.0.2")).await.status(), StatusCode::OK);
    }
    let (on, _) = app(Some("1/minute"), 16);
    assert_eq!(call(&on, Some("10.0.0.2")).await.status(), StatusCode::OK);
    assert_eq!(call(&on, Some("10.0.0.2")).await.status(), StatusCode::TOO_MANY_REQUESTS);
}

#[tokio::test]
async fn third_request_is_429_with_an_accurate_retry_after() {
    let (app, store) = app(Some("2/minute"), 16);
    let store = store.unwrap();
    assert_eq!(call(&app, Some("10.0.0.3")).await.status(), StatusCode::OK);
    assert_eq!(call(&app, Some("10.0.0.3")).await.status(), StatusCode::OK);
    let r = call(&app, Some("10.0.0.3")).await;
    assert_eq!(r.status(), StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(r.headers().get("retry-after").unwrap(), "30", "exact, not a range");
    // org REST API Design Standard R11.3 (draft-11 syntax), R11.2 (Retry-After present)
    assert_eq!(r.headers().get("ratelimit-policy").unwrap(), "\"default\";q=2;w=60");
    assert!(r.headers().get("ratelimit").unwrap().to_str().unwrap().starts_with("\"default\";r=0;t="));
    assert_eq!(store.len(), 1, "one cell per key");
}

#[tokio::test]
async fn keys_are_isolated_and_the_store_is_bounded() {
    let (app, store) = app(Some("1/minute"), 3);
    let store = store.unwrap();
    assert_eq!(call(&app, Some("10.0.0.4")).await.status(), StatusCode::OK);
    assert_eq!(call(&app, Some("10.0.0.4")).await.status(), StatusCode::TOO_MANY_REQUESTS);
    assert_eq!(call(&app, Some("10.0.0.5")).await.status(), StatusCode::OK, "a second key is unaffected");
    for n in 10..20 {
        let _ = call(&app, Some(&format!("10.0.1.{n}"))).await;
    }
    assert!(store.len() <= 3, "capacity 3 bounds the map, got {}", store.len());
}

#[tokio::test]
async fn the_shipped_default_posture_is_on_and_limits() {
    // R11.2 is a MUST and there is no variable that turns this off: the router is built
    // from the default posture with no override at all.
    let r0 = Router::new().route("/", get(|| async { "ok" }));
    let (app, store) = install_rate_limit(r0, Some(RateLimitPolicy::default_posture()), 65_536);
    assert!(store.is_some(), "the layer is always registered");
    for i in 0..20 {
        assert_eq!(call(&app, Some("10.0.9.1")).await.status(), StatusCode::OK, "burst request {i}");
    }
    let r = call(&app, Some("10.0.9.1")).await;
    assert_eq!(r.status(), StatusCode::TOO_MANY_REQUESTS, "the 21st exceeds a burst of 20");
    // sustained 10/s, burst 20: the deficit at the 21st request is one emission interval
    // (100 ms), so the ceiling is 1 s; 2 s only if the 21 in-process calls took over a second.
    let ra: u64 = r.headers().get("retry-after").unwrap().to_str().unwrap().parse().unwrap();
    assert!((1..=2).contains(&ra), "retry-after was {ra}");
    assert_eq!(r.headers().get("ratelimit-policy").unwrap(), "\"default\";q=10;w=1");
}

#[test]
fn policy_grammar_matches_py_limits_notation() {
    let p = RateLimitPolicy::from_str("100/minute").unwrap();
    assert_eq!(p.rate.get(), 100);
    assert_eq!(p.burst.get(), 100, "burst defaults to the count");
    assert_eq!(p.period, Duration::from_secs(60));
    // and a separate variable raises the burst without touching the sustained rate
    let b = p.with_burst(std::num::NonZeroU32::new(250).unwrap());
    assert_eq!((b.rate.get(), b.burst.get()), (100, 250));
    assert_eq!(b.emission_interval(), Duration::from_millis(600));
    assert_eq!(b.tolerance(), Duration::from_millis(600) * 249);
    assert_eq!(RateLimitPolicy::from_str("100").unwrap_err(), PolicyParseError::MissingSlash);
    assert_eq!(RateLimitPolicy::from_str("0/minute").unwrap_err(), PolicyParseError::ZeroCount);
    assert_eq!(RateLimitPolicy::from_str("100/fortnight").unwrap_err(), PolicyParseError::UnknownPeriod);
}

#[test]
fn retry_after_is_never_zero() {
    let now = Instant::now();
    assert_eq!(retry_after_seconds(now + Duration::from_millis(1), now), 1);
    assert_eq!(retry_after_seconds(now, now), 1);
    assert_eq!(retry_after_seconds(now + Duration::from_millis(1500), now), 2);
    // and it is a CEILING, so a client that obeys it is never refused again
    assert_eq!(retry_after_seconds(now + Duration::from_millis(29_990), now), 30);
}
RUST

( cd "$DESIGN" && cargo test --offline ) > "$WORK/design-test.txt" 2>&1 || true
echo "--- design test output ---"; cat "$WORK/design-test.txt"
for t in off_by_default_is_the_absence_of_the_layer conditional_registration_is_the_gate \
         third_request_is_429_with_an_accurate_retry_after keys_are_isolated_and_the_store_is_bounded \
         policy_grammar_matches_py_limits_notation retry_after_is_never_zero \
         the_shipped_default_posture_is_on_and_limits; do
  if /usr/bin/grep -qE "test ${t} \.\.\. ok" "$WORK/design-test.txt"; then ok "A $t"; else bad "A $t did not pass"; fi
done
if /usr/bin/grep -qE '^test result: ok\. 7 passed; 0 failed' "$WORK/design-test.txt"; then ok "A-total 7 passed 0 failed"; else bad "A-total: expected '7 passed; 0 failed'"; fi

( cd "$DESIGN" && cargo clippy --offline --all-targets -- -D warnings ) > "$WORK/design-clippy.txt" 2>&1 && CLIPPY_OK=1 || CLIPPY_OK=0
if [ "$CLIPPY_OK" = "1" ]; then ok "A-clippy clean under -D warnings"; else bad "A-clippy produced diagnostics"; sed -n '1,40p' "$WORK/design-clippy.txt"; fi

# ---------------------------------------------------------------------------
echo
echo "=== B. tower_governor 0.8.0 — the two measured defects ==="
TGP="$WORK/probe-tg"
mk_manifest "$TGP" "probe_tg" 'tower_governor = { version = "=0.8.0", default-features = false, features = ["axum"] }'
cat > "$TGP/src/lib.rs" <<'RUST'
//! Throwaway observation probe of tower_governor 0.8.0. Not template code.
RUST
cat > "$TGP/src/main.rs" <<'RUST'
fn main() {}
RUST
mkdir -p "$TGP/tests"
cat > "$TGP/tests/observed.rs" <<'RUST'
use std::net::SocketAddr;
use std::sync::Arc;

use axum::Router;
use axum::body::Body;
use axum::extract::ConnectInfo;
use axum::http::{Request, StatusCode};
use axum::routing::get;
use tower::ServiceExt;
use tower_governor::GovernorLayer;
use tower_governor::governor::GovernorConfigBuilder;

fn app() -> Router {
    let conf = Arc::new(
        GovernorConfigBuilder::default()
            .per_second(30)
            .burst_size(2)
            .use_headers()
            .finish()
            .unwrap(),
    );
    Router::new()
        .route("/", get(|| async { "ok" }))
        .layer(GovernorLayer::new(conf))
}

async fn call(app: &Router, ip: Option<&str>) -> axum::response::Response {
    let mut req = Request::builder().uri("/").body(Body::empty()).unwrap();
    if let Some(ip) = ip {
        let addr: SocketAddr = format!("{ip}:40000").parse().unwrap();
        req.extensions_mut().insert(ConnectInfo(addr));
    }
    app.clone().oneshot(req).await.unwrap()
}

#[tokio::test]
async fn without_connect_info_the_default_key_extractor_returns_500() {
    let app = app();
    let r = call(&app, None).await;
    assert_eq!(
        r.status(),
        StatusCode::INTERNAL_SERVER_ERROR,
        "R69's axum::serve(listener, app) and its oneshot idiom install no ConnectInfo"
    );
}

#[tokio::test]
async fn with_connect_info_the_third_request_is_429_and_carries_retry_after() {
    let app = app();
    assert_eq!(call(&app, Some("10.1.0.1")).await.status(), StatusCode::OK);
    assert_eq!(call(&app, Some("10.1.0.1")).await.status(), StatusCode::OK);
    let r = call(&app, Some("10.1.0.1")).await;
    assert_eq!(r.status(), StatusCode::TOO_MANY_REQUESTS);
    // the truncation: the true wait is 29.99...s, the header says 29
    assert_eq!(r.headers().get("retry-after").unwrap(), "29");
    assert_eq!(r.headers().get("x-ratelimit-after").unwrap(), "29");
    assert!(r.headers().get("content-type").is_none(), "no content-type: the body is bare text");
}
RUST

( cd "$TGP" && cargo test --offline ) > "$WORK/tg-test.txt" 2>&1 || true
echo "--- tower_governor observation output ---"; cat "$WORK/tg-test.txt"
for t in without_connect_info_the_default_key_extractor_returns_500 \
         with_connect_info_the_third_request_is_429_and_carries_retry_after; do
  if /usr/bin/grep -qE "test ${t} \.\.\. ok" "$WORK/tg-test.txt"; then ok "B $t"; else bad "B $t did not pass"; fi
done
if /usr/bin/grep -qE '^test result: ok\. 2 passed; 0 failed' "$WORK/tg-test.txt"; then ok "B-total 2 passed 0 failed"; else bad "B-total: expected '2 passed; 0 failed'"; fi

# ---------------------------------------------------------------------------
echo
echo "=== C. non-dev dependency-tree deltas ==="
# Counting rule, stated because it decides the figures: `cargo tree -e normal` prints one
# line per EDGE, repeating a shared subtree as `name vX.Y (*)`, so its raw line count is not a
# package count. The figure below is the set of DISTINCT name-and-version entries in the
# non-dev tree, with the probe's own root package removed. That is the rule the Opus report
# used ("counted as distinct name-and-version entries").
tree_entries() { # tree_entries <dir> -> distinct non-dev packages, root package excluded
  local b; b="$(basename "$1")"
  ( cd "$1" && cargo tree --offline -e normal --prefix none 2>/dev/null ) \
    | sed -e 's/ (\*)$//' -e 's/ (proc-macro)//' \
    | awk 'NF' | sort -u > "$WORK/tree-$b.txt"
  # the probe's own root package is the only path-dependency in the tree
  /usr/bin/grep -v -F ' v0.0.0 (' "$WORK/tree-$b.txt" > "$WORK/deps-$b.txt" || true
  local before after
  before="$(/usr/bin/grep -c . "$WORK/tree-$b.txt")"
  after="$(/usr/bin/grep -c . "$WORK/deps-$b.txt")"
  if [ "$((before - after))" -ne 1 ]; then
    echo "INTERNAL: removing the root package from $b removed $((before - after)) lines, not 1" >&2
    return 1
  fi
  echo "$after"
}

BASELINE="$WORK/probe-baseline"; mk_manifest "$BASELINE" "probe_baseline" ""
printf 'fn main() {}\n' > "$BASELINE/src/main.rs"; printf '\n' > "$BASELINE/src/lib.rs"
TRACING="$WORK/probe-tracing"; mk_manifest "$TRACING" "probe_tracing" 'tracing = { version = "0.1", default-features = false, features = ["std"] }'
printf 'fn main() {}\n' > "$TRACING/src/main.rs"; printf '\n' > "$TRACING/src/lib.rs"
TGND="$WORK/probe-tg-nodefault"; mk_manifest "$TGND" "probe_tg_nodefault" 'tower_governor = { version = "=0.8.0", default-features = false, features = ["axum"] }'
printf 'fn main() {}\n' > "$TGND/src/main.rs"; printf '\n' > "$TGND/src/lib.rs"
TGD="$WORK/probe-tg-default"; mk_manifest "$TGD" "probe_tg_default" 'tower_governor = "=0.8.0"'
printf 'fn main() {}\n' > "$TGD/src/main.rs"; printf '\n' > "$TGD/src/lib.rs"

N_BASE="$(tree_entries "$BASELINE")"
N_DESIGN="$(tree_entries "$DESIGN")"
N_TRACING="$(tree_entries "$TRACING")"
N_TGND="$(tree_entries "$TGND")"
N_TGD="$(tree_entries "$TGD")"
echo "baseline=$N_BASE design=$N_DESIGN tracing=$N_TRACING tg_nodefault=$N_TGND tg_default=$N_TGD"

chk "C0 baseline non-dev package count (axum 0.8.9 + tokio 1.53.1)" "50" "$N_BASE"
chk "C1 the recommended design adds 0 packages"                 "0"  "$((N_DESIGN - N_BASE))"
chk "C2 tracing(default-features=false,std) adds 0 packages"    "0"  "$((N_TRACING - N_BASE))"
chk "C3 tower_governor --no-default-features +axum adds"        "37" "$((N_TGND - N_BASE))"
chk "C4 tower_governor with its default features adds"          "49" "$((N_TGD - N_BASE))"
# the design's dependency set must be IDENTICAL to the baseline's, not merely the same size
if diff "$WORK/deps-probe-baseline.txt" "$WORK/deps-probe-design.txt" > "$WORK/tree-diff.txt" 2>&1; then
  ok "C5 design vs baseline non-dev package set: diff empty ($N_BASE packages each)"
else
  bad "C5 design vs baseline package set differs"; sed -n '1,20p' "$WORK/tree-diff.txt"
fi
# control: the tg set must NOT be identical, or C5's empty diff would be vacuous
if diff -q "$WORK/deps-probe-baseline.txt" "$WORK/deps-probe-tg-nodefault.txt" > /dev/null 2>&1; then
  bad "C5-control tg package set is identical to baseline — the diff test cannot discriminate"
else
  ok "C5-control tg package set differs from baseline, so C5's empty diff is not vacuous"
fi
for crate in "governor v0.10.4" "dashmap" "quanta" "parking_lot" "getrandom"; do
  has "C6 tower_governor pulls in $crate" "$crate" "$WORK/deps-probe-tg-nodefault.txt"
done
has  "C7 tower_governor's default features pull in tonic" "tonic" "$WORK/deps-probe-tg-default.txt"
hasnt "C8 the recommended design pulls in no governor"    "governor" "$WORK/deps-probe-design.txt"
# both thiserror majors, which is the concrete cost of the +37
has  "C9a tower_governor drags thiserror 1.x" "thiserror v1." "$WORK/deps-probe-tg-nodefault.txt"
has  "C9b tower_governor drags thiserror 2.x" "thiserror v2." "$WORK/deps-probe-tg-nodefault.txt"

# ---------------------------------------------------------------------------
# E. tower-rate-limiter 0.1.6 — the openai leg's recommendation, which no other
#    leg found. It is real. These checks establish what it is.
# ---------------------------------------------------------------------------
echo
echo "=== E. tower-rate-limiter 0.1.6 (the openai leg's pick) ==="
TRL="$REG/tower-rate-limiter-0.1.6"
if [ -d "$TRL" ]; then
  chk  "E1 declared rust-version"  "1.96.0" "$(rv_of tower-rate-limiter-0.1.6)"
  chk  "E2 declared edition"       "2024"   "$(ed_of tower-rate-limiter-0.1.6)"
  has  "E3 the store is a FIXED WINDOW, not GCRA"          'An asynchronous fixed-window rate-limit store.' "$TRL/src/limiter/store.rs"
  has  "E4 it emits the draft-11 RateLimit fields"         'Draft 11 represents both fields as lists of named items' "$TRL/src/limiter/response.rs"
  TRLP="$WORK/probe-trl"; mk_manifest "$TRLP" "probe_trl" 'tower-rate-limiter = "=0.1.6"'
  printf 'fn main() {}\n' > "$TRLP/src/main.rs"; printf '\n' > "$TRLP/src/lib.rs"
  N_TRL="$(tree_entries "$TRLP")"
  chk  "E5 tower-rate-limiter with its default features adds" "18" "$((N_TRL - N_BASE))"
  has  "E6 its default feature set pulls in moka" "moka" "$WORK/deps-probe-trl.txt"
else
  for l in E1 E2 E3 E4 E5 E6; do skip "$l — tower-rate-limiter-0.1.6 not unpacked in this CARGO_HOME"; done
fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
