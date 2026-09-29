#!/usr/bin/env bash
# R74 revision 2 — throwaway Cargo probes that verify what the raw reports assert.
#
# NOT a template scaffold. Every crate this script writes lives under a directory
# created inside $TMPDIR and is deleted when the script exits. The only files it writes
# next to itself are the dependency lockfiles under probe-locks/, and only when asked
# to record them (R74_RECORD_LOCKS=1).
#
# Revision 2 changes, each answering an audit finding against revision 1's r74-probe.sh
# (kept unchanged beside this script, with its log):
#   - the registry path is derived from ${CARGO_HOME:-$HOME/.cargo}, never hard-coded (EA-2);
#   - section L resolves and fetches every probe crate ONLINE before any --offline call,
#     so a cold, private CARGO_HOME works (EA-2);
#   - every probe crate is resolved from a committed lockfile, probe-locks/<crate>.lock,
#     replayed with --locked, so the C-section package counts are pinned (EA-3);
#   - the toolchain is recorded and asserted only to be at or above the MSRV floor (T1);
#     cross-run comparison excludes the toolchain lines by rule (EA-4);
#   - the design ships a non-Option install_rate_limit; the Option form survives as
#     install_rate_limit_conditional, evidence only (JF-1, audit-fable finding 6);
#   - section F reads the source claims the Muse leg makes, and axum-governor's
#     Retry-After arithmetic, which revision 1 left unproven.
#
# Sections: L lockfiles and fetch; T toolchain; D gate-2 manifest reads; D2 tower_governor
# source facts; A the recommended design (9 tests + clippy); B tower_governor observations;
# C dependency-set deltas; E tower-rate-limiter; F Muse-leg and axum-governor source reads.
#
# Every check asserts on CONTENT. Counts are printed and summed; a FAIL exits non-zero.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCKS="$HERE/probe-locks"

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
at()   { # at <label> <file> <line> <needle> — the needle must be on exactly that line
  if sed -n "${3}p" "$2" | /usr/bin/grep -qF -- "$4"; then ok "$1 (line $3)"; else bad "$1: line $3 of $(basename "$2") does not carry [$4]"; fi
}

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r74-probe.XXXXXXXX")"
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

CARGO_HOME_EFF="${CARGO_HOME:-$HOME/.cargo}"
REG="$CARGO_HOME_EFF/registry/src/index.crates.io-1949cf8c6b5b557f"

echo "toolchain: $(rustc --version)"
echo "cargo:     $(cargo --version)"
echo "os:        $(uname -sm) / macOS $(sw_vers -productVersion 2>/dev/null || echo n-a)"
echo "grep:      $(/usr/bin/grep --version | head -1)"
echo "workdir:   $WORK (deleted on exit)"
echo "cargo home: $CARGO_HOME_EFF"
echo

# ---------------------------------------------------------------------------
# Every probe crate's manifest is written first, so section L can resolve them all.
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
  printf 'fn main() {}\n' > "$1/src/main.rs"
  printf '\n' > "$1/src/lib.rs"
}

DESIGN="$WORK/probe-design";        mk_manifest "$DESIGN"   "probe_design" ""
TGP="$WORK/probe-tg";               mk_manifest "$TGP"      "probe_tg" 'tower_governor = { version = "=0.8.0", default-features = false, features = ["axum"] }'
BASELINE="$WORK/probe-baseline";    mk_manifest "$BASELINE" "probe_baseline" ""
TRACING="$WORK/probe-tracing";      mk_manifest "$TRACING"  "probe_tracing" 'tracing = { version = "0.1", default-features = false, features = ["std"] }'
TGND="$WORK/probe-tg-nodefault";    mk_manifest "$TGND"     "probe_tg_nodefault" 'tower_governor = { version = "=0.8.0", default-features = false, features = ["axum"] }'
TGD="$WORK/probe-tg-default";       mk_manifest "$TGD"      "probe_tg_default" 'tower_governor = "=0.8.0"'
TRLP="$WORK/probe-trl";             mk_manifest "$TRLP"     "probe_trl" 'tower-rate-limiter = "=0.1.6"'
SRCS="$WORK/probe-sources";         mk_manifest "$SRCS"     "probe_sources" 'axum-governor = "=2.1.0"
gcra = "=0.6.0"
tower-resilience-ratelimiter = "=0.13.0"'

# ---------------------------------------------------------------------------
echo "=== L. lockfiles: every probe crate resolves from a committed lock, then fetches ==="
# The only network phase. Everything after it runs --offline --locked.
lock_in() { # lock_in <dir> <crate-name>
  local dir="$1" name="$2" lock="$LOCKS/$2.lock"
  if [ -f "$lock" ]; then
    cp "$lock" "$dir/Cargo.lock"
    if ( cd "$dir" && cargo fetch --locked ) > "$WORK/fetch-$name.txt" 2>&1; then
      ok "L $name resolves from probe-locks/$name.lock under --locked and fetches"
    else
      bad "L $name: --locked fetch failed"; sed -n '1,20p' "$WORK/fetch-$name.txt"
    fi
  elif [ "${R74_RECORD_LOCKS:-0}" = "1" ]; then
    mkdir -p "$LOCKS"
    if ( cd "$dir" && cargo generate-lockfile && cargo fetch --locked ) > "$WORK/fetch-$name.txt" 2>&1; then
      cp "$dir/Cargo.lock" "$lock"
      skip "L $name: lockfile RECORDED this run as probe-locks/$name.lock; rerun without R74_RECORD_LOCKS to replay it"
    else
      bad "L $name: resolution failed"; sed -n '1,20p' "$WORK/fetch-$name.txt"
    fi
  else
    bad "L $name: no committed lockfile probe-locks/$name.lock (R74_RECORD_LOCKS=1 records one)"
  fi
}
for pair in "$DESIGN probe_design" "$TGP probe_tg" "$BASELINE probe_baseline" "$TRACING probe_tracing" \
            "$TGND probe_tg_nodefault" "$TGD probe_tg_default" "$TRLP probe_trl" "$SRCS probe_sources"; do
  read -r d n <<< "$pair"
  lock_in "$d" "$n"
done
if [ -d "$LOCKS" ]; then
  echo "     lockfile sha256:"
  ( cd "$LOCKS" && shasum -a 256 ./*.lock | sed 's/^/       /' )
fi

# ---------------------------------------------------------------------------
echo
echo "=== T. toolchain ==="
rminor="$(rustc --version | sed -E 's/^rustc 1\.([0-9]+)\..*/\1/')"
if [ "$rminor" -ge 96 ]; then ok "T1 the probe toolchain (rustc 1.$rminor) is at or above the 1.96 MSRV floor"; else bad "T1 rustc 1.$rminor is below the 1.96 floor"; fi

# ---------------------------------------------------------------------------
# D. Gate 2 — declared rust-version in the PUBLISHED manifests, read at the registry
# ---------------------------------------------------------------------------
echo
echo "=== D. gate 2: declared rust-version in the published manifests ==="
rv_of() { # rv_of <unpacked-dir>  -> the declared rust-version, or the literal NONE
  local m="$REG/$1/Cargo.toml"
  if [ ! -f "$m" ]; then echo "NO-MANIFEST"; return; fi
  local v
  v="$(/usr/bin/grep -m1 -E '^rust-version[[:space:]]*=' "$m" | sed -E 's/.*=[[:space:]]*"?([^"]*)"?.*/\1/')"
  if [ -z "$v" ]; then echo "NONE"; else echo "$v"; fi
}
ed_of() { /usr/bin/grep -m1 -E '^edition[[:space:]]*=' "$REG/$1/Cargo.toml" | sed -E 's/.*=[[:space:]]*"([^"]*)".*/\1/'; }

for pair in "tower_governor-0.8.0 NONE 2021" "governor-0.10.4 NONE 2018" "axum-governor-2.1.0 1.95 2024" "gcra-0.6.0 1.80.0 2021" "axum-0.8.9 1.80 2021" "tower-0.5.3 1.64.0 2018" "tower-resilience-ratelimiter-0.13.0 1.85.0 2021"; do
  read -r d want_rv want_ed <<< "$pair"
  if [ -d "$REG/$d" ]; then
    chk "D-rv $d" "$want_rv" "$(rv_of "$d")"
    chk "D-ed $d" "$want_ed" "$(ed_of "$d")"
  else
    bad "D $d — not unpacked in $REG after section L"
    bad "D-ed $d — not unpacked in $REG after section L"
  fi
done

# Control: the reader must be able to find a version when one is declared, so the
# two NONE results above cannot come from a broken reader.
if [ "$(rv_of axum-0.8.9)" = "NONE" ]; then bad "D-control: reader returned NONE for a crate that declares 1.80"; else ok "D-control: reader finds a declared rust-version"; fi

# ---------------------------------------------------------------------------
echo
echo "=== D2. tower_governor 0.8.0 source facts ==="
TG="$REG/tower_governor-0.8.0"
n_as_secs="$(/usr/bin/grep -c '\.as_secs()' "$TG/src/lib.rs" || true)"
if [ "$n_as_secs" -ge 2 ]; then ok "D2a wait_time is computed with .as_secs() (truncating) at $n_as_secs sites in src/lib.rs"; else bad "D2a expected >=2 .as_secs() sites, got $n_as_secs"; fi
has  "D2b retry-after IS inserted (correcting the 'x-ratelimit-after only' claim)" 'headers.insert("retry-after", wait_time.into());' "$TG/src/lib.rs"
has  "D2c a new X- prefixed quota header is emitted"                               'headers.insert("x-ratelimit-after", wait_time.into());' "$TG/src/lib.rs"
has  "D2d PeerIpKeyExtractor returns UnableToExtractKey when ConnectInfo is absent" 'maybe_connect_info(req).ok_or(GovernorError::UnableToExtractKey)' "$TG/src/key_extractor.rs"
has  "D2e UnableToExtractKey renders INTERNAL_SERVER_ERROR"                         'parts.status = StatusCode::INTERNAL_SERVER_ERROR;' "$TG/src/errors.rs"
has  "D2f the 429 body is a plain string, not problem+json"                         'Response::new(format!("Too Many Requests! Wait for {}s", wait_time))' "$TG/src/errors.rs"
if sed -n '/^\[features\]/,/^\[lib\]/p' "$TG/Cargo.toml" | /usr/bin/grep -q '"tonic"'; then ok "D2g tonic is in tower_governor's default feature set"; else bad "D2g tonic not found in the default feature set"; fi

# ---------------------------------------------------------------------------
echo
echo "=== A. the recommended zero-crate GCRA design (9 tests) ==="
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

/// SHIPPED form (revision 2). It takes a `RateLimitPolicy`, not an `Option`, so no
/// configuration value can reach it as "off": the layer is registered on every router this
/// function builds. The store is constructed at the composition root and erased to
/// `Arc<dyn RateLimitStore>` (R01's seam), then handed in.
pub fn install_rate_limit(
    router: Router,
    policy: RateLimitPolicy,
    store: Arc<dyn RateLimitStore>,
) -> Router {
    let state = RateLimitState { store, policy };
    router.layer(axum::middleware::from_fn_with_state(state, rate_limit))
}

/// EVIDENCE ONLY, not shipped: the `Option` form that answers the prompt's HIGH question 2
/// and that the F323 and OV-17 reversal options would restore. An unset policy means the
/// layer is never registered.
pub fn install_rate_limit_conditional(
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

/// The invariant handed to R77 (revision 2): the settings value for the per-IP member maps
/// to a policy, never to "off". Unset and exported-but-empty both mean the default posture
/// (R77's empty-means-unset rule); a non-empty invalid value is a startup error.
pub fn policy_from_setting(raw: Option<&str>) -> Result<RateLimitPolicy, PolicyParseError> {
    match raw {
        None => Ok(RateLimitPolicy::default_posture()),
        Some("") => Ok(RateLimitPolicy::default_posture()),
        Some(s) => s.parse(),
    }
}
RUST

mkdir -p "$DESIGN/tests"
cat > "$DESIGN/tests/acceptance.rs" <<'RUST'
use std::net::SocketAddr;
use std::num::NonZeroU32;
use std::str::FromStr;
use std::sync::Arc;
use std::time::{Duration, Instant};

use axum::Router;
use axum::body::Body;
use axum::extract::ConnectInfo;
use axum::http::{Request, StatusCode};
use axum::routing::get;
use probe_design::*;
use tower::ServiceExt;

fn base() -> Router {
    Router::new().route("/", get(|| async { "ok" }))
}

/// The SHIPPED path: the composition root builds the store and erases it; the router
/// always gets the layer.
fn shipped(policy: RateLimitPolicy, capacity: usize) -> (Router, Arc<InMemoryRateLimitStore>) {
    let store = Arc::new(InMemoryRateLimitStore::new(policy, capacity));
    let erased: Arc<dyn RateLimitStore> = store.clone();
    (install_rate_limit(base(), policy, erased), store)
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
    // Control, not a shipped behaviour: a router built WITHOUT the layer admits everything,
    // so the refusals asserted below are the layer's doing.
    let app = base();
    for i in 0..1000 {
        let r = call(&app, Some("10.0.0.1")).await;
        assert_eq!(r.status(), StatusCode::OK, "request {i} must be admitted");
    }
}

#[tokio::test]
async fn conditional_registration_is_the_gate() {
    // EVIDENCE for the prompt's HIGH question 2 only: the Option form is not shipped.
    let (off, store) = install_rate_limit_conditional(base(), None, 16);
    assert!(store.is_none(), "no policy means no store exists at all");
    for _ in 0..50 {
        assert_eq!(call(&off, Some("10.0.0.2")).await.status(), StatusCode::OK);
    }
    let p = RateLimitPolicy::from_str("1/minute").unwrap();
    let (on, _) = install_rate_limit_conditional(base(), Some(p), 16);
    assert_eq!(call(&on, Some("10.0.0.2")).await.status(), StatusCode::OK);
    assert_eq!(call(&on, Some("10.0.0.2")).await.status(), StatusCode::TOO_MANY_REQUESTS);
}

#[tokio::test]
async fn third_request_is_429_with_an_accurate_retry_after() {
    let (app, store) = shipped(RateLimitPolicy::from_str("2/minute").unwrap(), 16);
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
    let (app, store) = shipped(RateLimitPolicy::from_str("1/minute").unwrap(), 3);
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
    // R11.2 is a MUST and no variable turns this off: the router is built from the
    // default posture through the shipped, non-Option install.
    let (app, _) = shipped(RateLimitPolicy::default_posture(), 65_536);
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

#[tokio::test]
async fn settings_values_tune_but_never_disable() {
    // B2 on the shipped form: every settings value yields a policy; none yields "off".
    assert_eq!(policy_from_setting(None).unwrap(), RateLimitPolicy::default_posture());
    assert_eq!(policy_from_setting(Some("")).unwrap(), RateLimitPolicy::default_posture());
    assert_eq!(policy_from_setting(Some("off")).unwrap_err(), PolicyParseError::MissingSlash);
    assert_eq!(policy_from_setting(Some("0/second")).unwrap_err(), PolicyParseError::ZeroCount);
    // a tuned value changes the quota on the same shipped call site, with no recompilation
    let tuned = policy_from_setting(Some("1/minute")).unwrap();
    let (app, _) = shipped(tuned, 16);
    assert_eq!(call(&app, Some("10.0.0.6")).await.status(), StatusCode::OK);
    assert_eq!(call(&app, Some("10.0.0.6")).await.status(), StatusCode::TOO_MANY_REQUESTS);
}

#[test]
fn rate_and_burst_are_independent_over_simulated_time() {
    // One request per millisecond for 10 s (t = 0 ..= 10_000 ms), with the clock injected
    // through `check`'s `now`. Two parameters give sustained 10/s after a burst of 20 (120
    // admissions). A single-parameter GCRA, where the emission interval is period / burst,
    // cannot: "10/second" admits 110 (burst 10) and "20/second" admits 220 (sustained 20/s).
    fn admitted(p: RateLimitPolicy) -> u32 {
        let store = InMemoryRateLimitStore::new(p, 4);
        let base = Instant::now();
        let key = RateLimitKey::Global;
        (0..=10_000u64)
            .filter(|ms| store.check(&key, base + Duration::from_millis(*ms)).is_ok())
            .count() as u32
    }
    let two = RateLimitPolicy::from_str("10/second").unwrap().with_burst(NonZeroU32::new(20).unwrap());
    assert_eq!(two, RateLimitPolicy::default_posture());
    assert_eq!(admitted(two), 120);
    assert_eq!(admitted(RateLimitPolicy::from_str("10/second").unwrap()), 110);
    assert_eq!(admitted(RateLimitPolicy::from_str("20/second").unwrap()), 220);
}

#[test]
fn policy_grammar_matches_py_limits_notation() {
    let p = RateLimitPolicy::from_str("100/minute").unwrap();
    assert_eq!(p.rate.get(), 100);
    assert_eq!(p.burst.get(), 100, "burst defaults to the count");
    assert_eq!(p.period, Duration::from_secs(60));
    // and a separate variable raises the burst without touching the sustained rate
    let b = p.with_burst(NonZeroU32::new(250).unwrap());
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

( cd "$DESIGN" && cargo test --offline --locked ) > "$WORK/design-test.txt" 2>&1 || true
echo "--- design test output ---"; cat "$WORK/design-test.txt"
for t in off_by_default_is_the_absence_of_the_layer conditional_registration_is_the_gate \
         third_request_is_429_with_an_accurate_retry_after keys_are_isolated_and_the_store_is_bounded \
         the_shipped_default_posture_is_on_and_limits settings_values_tune_but_never_disable \
         rate_and_burst_are_independent_over_simulated_time \
         policy_grammar_matches_py_limits_notation retry_after_is_never_zero; do
  if /usr/bin/grep -qE "test ${t} \.\.\. ok" "$WORK/design-test.txt"; then ok "A $t"; else bad "A $t did not pass"; fi
done
if /usr/bin/grep -qE '^test result: ok\. 9 passed; 0 failed' "$WORK/design-test.txt"; then ok "A-total 9 passed 0 failed"; else bad "A-total: expected '9 passed; 0 failed'"; fi
# the shipped signature takes no Option, so "off" is not expressible at the call site
has   "A-sig the shipped install_rate_limit takes a RateLimitPolicy, not an Option" 'policy: RateLimitPolicy,' "$DESIGN/src/lib.rs"
hasnt "A-sig-control the design's tests never call install_rate_limit( with None" 'install_rate_limit(base(), None' "$DESIGN/tests/acceptance.rs"

( cd "$DESIGN" && cargo clippy --offline --locked --all-targets -- -D warnings ) > "$WORK/design-clippy.txt" 2>&1 && CLIPPY_OK=1 || CLIPPY_OK=0
if [ "$CLIPPY_OK" = "1" ]; then ok "A-clippy clean under -D warnings"; else bad "A-clippy produced diagnostics"; /usr/bin/grep -A14 -E '^(error|warning)' "$WORK/design-clippy.txt" | head -60; fi

# ---------------------------------------------------------------------------
echo
echo "=== B. tower_governor 0.8.0 — the two measured defects ==="
printf '//! Throwaway observation probe of tower_governor 0.8.0. Not template code.\n' > "$TGP/src/lib.rs"
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

( cd "$TGP" && cargo test --offline --locked ) > "$WORK/tg-test.txt" 2>&1 || true
echo "--- tower_governor observation output ---"; cat "$WORK/tg-test.txt"
for t in without_connect_info_the_default_key_extractor_returns_500 \
         with_connect_info_the_third_request_is_429_and_carries_retry_after; do
  if /usr/bin/grep -qE "test ${t} \.\.\. ok" "$WORK/tg-test.txt"; then ok "B $t"; else bad "B $t did not pass"; fi
done
if /usr/bin/grep -qE '^test result: ok\. 2 passed; 0 failed' "$WORK/tg-test.txt"; then ok "B-total 2 passed 0 failed"; else bad "B-total: expected '2 passed; 0 failed'"; fi

# ---------------------------------------------------------------------------
echo
echo "=== C. non-dev dependency-tree deltas (pinned by the committed lockfiles) ==="
# Counting rule, stated because it decides the figures: `cargo tree -e normal` prints one
# line per EDGE, repeating a shared subtree as `name vX.Y (*)`, so its raw line count is not a
# package count. The figure below is the set of DISTINCT name-and-version entries in the
# non-dev tree, with the probe's own root package removed. That is the rule the Opus report
# used ("counted as distinct name-and-version entries").
tree_entries() { # tree_entries <dir> -> distinct non-dev packages, root package excluded
  local b; b="$(basename "$1")"
  ( cd "$1" && cargo tree --offline --locked -e normal --prefix none 2>/dev/null ) \
    | sed -e 's/ (\*)$//' -e 's/ (proc-macro)//' \
    | awk 'NF' | sort -u > "$WORK/tree-$b.txt"
  /usr/bin/grep -v -F ' v0.0.0 (' "$WORK/tree-$b.txt" > "$WORK/deps-$b.txt" || true
  local before after
  before="$(/usr/bin/grep -c . "$WORK/tree-$b.txt" || true)"
  after="$(/usr/bin/grep -c . "$WORK/deps-$b.txt" || true)"
  if [ "$((before - after))" -ne 1 ]; then
    echo "INTERNAL: removing the root package from $b removed $((before - after)) lines, not 1" >&2
    return 1
  fi
  echo "$after"
}

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
if diff "$WORK/deps-probe-baseline.txt" "$WORK/deps-probe-design.txt" > "$WORK/tree-diff.txt" 2>&1; then
  ok "C5 design vs baseline non-dev package set: diff empty ($N_BASE packages each)"
else
  bad "C5 design vs baseline package set differs"; sed -n '1,20p' "$WORK/tree-diff.txt"
fi
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
has  "C9a tower_governor drags thiserror 1.x" "thiserror v1." "$WORK/deps-probe-tg-nodefault.txt"
has  "C9b tower_governor drags thiserror 2.x" "thiserror v2." "$WORK/deps-probe-tg-nodefault.txt"

# ---------------------------------------------------------------------------
echo
echo "=== E. tower-rate-limiter 0.1.6 (the openai leg's pick) ==="
TRL="$REG/tower-rate-limiter-0.1.6"
chk  "E1 declared rust-version"  "1.96.0" "$(rv_of tower-rate-limiter-0.1.6)"
chk  "E2 declared edition"       "2024"   "$(ed_of tower-rate-limiter-0.1.6)"
has  "E3 the store is a FIXED WINDOW, not GCRA"          'An asynchronous fixed-window rate-limit store.' "$TRL/src/limiter/store.rs"
has  "E4 it emits the draft-11 RateLimit fields"         'Draft 11 represents both fields as lists of named items' "$TRL/src/limiter/response.rs"
N_TRL="$(tree_entries "$TRLP")"
chk  "E5 tower-rate-limiter with its default features adds" "18" "$((N_TRL - N_BASE))"
has  "E6 its default feature set pulls in moka" "moka" "$WORK/deps-probe-trl.txt"

# ---------------------------------------------------------------------------
echo
echo "=== F. the Muse leg's source readings, and axum-governor's Retry-After ==="
at  "F1a tower_governor src/lib.rs truncates with .as_secs() (Muse :125-127)" "$TG/src/lib.rs" 127 '.as_secs();'
at  "F1b tower_governor src/lib.rs truncates with .as_secs() (Muse :293-295)" "$TG/src/lib.rs" 295 '.as_secs();'
at  "F1c tower_governor inserts retry-after (Muse :143-144)"                  "$TG/src/lib.rs" 144 'headers.insert("retry-after", wait_time.into());'
at  "F1d tower_governor inserts retry-after (Muse :312-313)"                  "$TG/src/lib.rs" 313 'headers.insert("retry-after", wait_time.into());'
at  "F1e missing ConnectInfo -> UnableToExtractKey (Muse key_extractor.rs:76)" "$TG/src/key_extractor.rs" 76 'ok_or(GovernorError::UnableToExtractKey)'
at  "F1f missing key -> UnableToExtractKey (Muse key_extractor.rs:113)"        "$TG/src/key_extractor.rs" 113 'ok_or(GovernorError::UnableToExtractKey)'
at  "F1g UnableToExtractKey -> 500 (Muse errors.rs:58-61)"                    "$TG/src/errors.rs" 61 'StatusCode::INTERNAL_SERVER_ERROR'
TRLR="$TRL/src/limiter/response.rs"
at  "F2a tower-rate-limiter maps a key-extraction error to 500 (Muse, response.rs)" "$TRLR" 62 'RateLimitError::Key(_, _)'
at  "F2b ... and the arm's status is INTERNAL_SERVER_ERROR"                          "$TRLR" 63 'StatusCode::INTERNAL_SERVER_ERROR'
AG="$REG/axum-governor-2.1.0"
has "F3a axum-governor depends on governor (Muse: '[dependencies.governor] version = \"0.10\"')" '[dependencies.governor]' "$AG/Cargo.toml"
if sed -n '/^\[dependencies\.governor\]/,/^\[/p' "$AG/Cargo.toml" | /usr/bin/grep -qF 'version = "0.10"'; then ok "F3b ... at version 0.10, the gate-excluded engine"; else bad "F3b axum-governor's governor requirement is not 0.10"; fi
has "F3c axum-governor emits the draft-11 RateLimit field (Muse, src/headers.rs)" 'HeaderName::from_static("ratelimit")' "$AG/src/headers.rs"
has "F3d axum-governor also emits a new X- quota header"                     'HeaderName::from_static("x-ratelimit-limit")' "$AG/src/headers.rs"
at  "F3e axum-governor's Retry-After is wait.as_secs() — truncating, not exact"  "$AG/src/service.rs" 496 'let delta = wait.as_secs();'
at  "F3f ... floored at 1, so 29.99 s renders as 29"                          "$AG/src/service.rs" 497 'let retry_after = delta.max(1);'
TRR="$REG/tower-resilience-ratelimiter-0.13.0"
has "F4a tower-resilience-ratelimiter's rate-limited error carries no retry-after (Muse)" 'ResilienceError::RateLimited { retry_after: None }' "$TRR/src/error.rs"
has "F4b its docs leave the 429 to the caller (Muse: 'could' be returned)"                '// Could return 429 Too Many Requests in HTTP context' "$TRR/src/lib.rs"
# Control: the line locator must be able to fail.
if sed -n '1p' "$TG/src/lib.rs" | /usr/bin/grep -qF 'headers.insert("retry-after"'; then bad "F-control line 1 of tower_governor src/lib.rs unexpectedly carries the insert"; else ok "F-control the line locator is positional and can fail"; fi

echo
echo "CHECKS RUN: $((PASS + FAIL + SKIP))  PASS: $PASS  FAILURES: $FAIL  SKIPPED: $SKIP"
[ "$FAIL" -eq 0 ]
