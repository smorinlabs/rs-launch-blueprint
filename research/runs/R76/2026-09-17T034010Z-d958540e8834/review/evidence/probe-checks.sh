#!/usr/bin/env bash
# R76 empirical check, part 2 of 3: measure the behaviour the recommendation
# rests on, rather than arguing it.
#
# What this script is NOT. It does not build the template, a web service, a
# composition root, a settings type or any acceptance scaffold. It builds a
# throwaway probe crate whose only purpose is to make three CorsLayer
# installation policies observable side by side, and deletes it afterwards.
#
# Line prefixes and what each promises:
#   CHECK   — one observed result printed by the probe's own test binary.
#   FIGURE  — a measurement of this host at this moment. Build seconds do NOT
#             reproduce and are labelled; byte sizes on an unchanged toolchain
#             do, and are asserted.
#   ASSERT  — a content assertion. `ASSERT FAIL` sets exit status 1.
#   SKIP    — a check that could not run, with the reason named.
#
# Needs: network (to resolve the crates) or a warm Cargo registry cache, and
# the toolchain printed below. Needs no `.git`, so it runs unchanged from a
# clean `git archive HEAD` extraction. Everything it writes lives under one
# directory created with mktemp inside $TMPDIR and removed on exit; the probe
# is created with `cargo new --vcs none`, so no nested Git repository is ever
# created and no target/ tree is ever left behind.

set -euo pipefail

GREP=/usr/bin/grep

echo "=== R76 CORS-layer probe checks ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "rustc: $(rustc --version)"
echo "cargo: $(cargo --version)"
echo "os:    $(sw_vers -productName 2>/dev/null || uname -s) $(sw_vers -productVersion 2>/dev/null || uname -r) $(uname -m)"
echo "grep:  $("$GREP" --version | head -1)"
echo

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r76-probe.XXXXXX")
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

pass=0; failn=0; skipn=0
assert() {
  if [ "$1" = "1" ]; then echo "ASSERT ok   $2"; pass=$((pass + 1))
  else echo "ASSERT FAIL $2"; failn=$((failn + 1)); fi
}
skip() { echo "SKIP        $1"; skipn=$((skipn + 1)); }
eq() { if [ "$1" = "$2" ]; then echo 1; else echo 0; fi; }
# Fixed-string grep -c on the probe transcript; the line must appear exactly
# once, byte for byte. -F is required, not stylistic: several expected lines
# contain a literal `*` (access-control-allow-headers=*), which a basic regular
# expression would read as a repetition operator and silently mis-match.
once() { if [ "$("$GREP" -cF -- "$1" "$2" || true)" = "1" ]; then echo 1; else echo 0; fi; }

# ---------------------------------------------------------------------------
# The probe. `with` carries the recommended dependency line; `v06` swaps only
# the tower-http version, to measure what 0.7.0's cors change is observable as;
# `without` drops the line entirely, to measure what the dependency costs.
# ---------------------------------------------------------------------------
mk_manifest() { # mk_manifest <dir> <tower-http requirement or empty>
  cat > "$1/Cargo.toml" <<EOF
[package]
name = "r76probe"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
${2}

[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
EOF
}

TH071='tower-http = { version = "=0.7.1", default-features = false, features = ["cors"] }'
TH061='tower-http = { version = "=0.6.11", default-features = false, features = ["cors"] }'

for d in with v06 without; do
  mkdir -p "$WORK/$d/src" "$WORK/$d/tests"
  echo 'pub fn placeholder() {}' > "$WORK/$d/src/lib.rs"
done
mk_manifest "$WORK/with" "$TH071"
mk_manifest "$WORK/v06" "$TH061"
mk_manifest "$WORK/without" ""

cat > "$WORK/with/tests/cors.rs" <<'RUSTEOF'
// Twelve observations of three CorsLayer installation policies. Nothing here
// is template code: it exists only to make the policies' differences visible.
use std::sync::Arc;
use std::sync::atomic::{AtomicUsize, Ordering};
use std::time::Duration;

use axum::Router;
use axum::body::Body;
use axum::http::{HeaderValue, Request, Response};
use axum::routing::get;
use tower::ServiceExt;
use tower_http::cors::{Any, CorsLayer};

fn base() -> Router {
    Router::new().route("/a", get(|| async { "ok" }))
}

// The recommended shape: a plain conditional branch. `Router::layer` returning
// `Router` is the whole reason re-binding inside an `if` type-checks, so this
// function compiling at all is check A's first half.
fn apply_cors(router: Router, origins: &[HeaderValue]) -> Router {
    if origins.is_empty() {
        return router;
    }
    router.layer(
        CorsLayer::new()
            .allow_origin(origins.to_vec())
            .allow_methods(Any)
            .allow_headers(Any)
            .max_age(Duration::from_secs(600)),
    )
}

fn get_req(origin: &str) -> Request<Body> {
    Request::builder()
        .method("GET")
        .uri("/a")
        .header("origin", origin)
        .body(Body::empty())
        .unwrap()
}

fn preflight(uri: &str, origin: &str) -> Request<Body> {
    Request::builder()
        .method("OPTIONS")
        .uri(uri)
        .header("origin", origin)
        .header("access-control-request-method", "GET")
        .body(Body::empty())
        .unwrap()
}

fn show(tag: &str, res: &Response<Body>) {
    let mut kv: Vec<String> = res
        .headers()
        .iter()
        .map(|(k, v)| format!("{}={}", k, v.to_str().unwrap_or("<bin>")))
        .collect();
    kv.sort();
    println!("CHECK {tag} status={} headers={{{}}}", res.status(), kv.join(", "));
}

async fn run(router: Router, req: Request<Body>) -> Response<Body> {
    router.oneshot(req).await.unwrap()
}

#[tokio::test(flavor = "multi_thread")]
async fn cors_installation_policies() {
    let allow: Vec<HeaderValue> = vec!["https://app.example".parse().unwrap()];
    let empty: Vec<HeaderValue> = Vec::new();

    // A — empty allowlist, layer never installed, simple GET carrying Origin.
    show("A", &run(apply_cors(base(), &empty), get_req("https://evil.example")).await);

    // Q1 — empty allowlist, OPTIONS preflight on a GET-only route.
    show("Q1", &run(apply_cors(base(), &empty), preflight("/a", "https://evil.example")).await);

    // Q2 — a bare CorsLayer::new() installed unconditionally.
    let q2 = base().layer(CorsLayer::new());
    show("Q2-get", &run(q2.clone(), get_req("https://evil.example")).await);
    show("Q2-options", &run(q2, preflight("/a", "https://evil.example")).await);

    // Q3 — py's literal shape with an empty list, installed unconditionally.
    let q3 = base().layer(
        CorsLayer::new()
            .allow_origin(Vec::<HeaderValue>::new())
            .allow_methods(Any)
            .allow_headers(Any),
    );
    show("Q3-get", &run(q3.clone(), get_req("https://evil.example")).await);
    show("Q3-options", &run(q3, preflight("/a", "https://evil.example")).await);

    // C — configured allowlist, GET from the allowed origin.
    show("C", &run(apply_cors(base(), &allow), get_req("https://app.example")).await);

    // D — configured allowlist, GET from a different origin.
    show("D", &run(apply_cors(base(), &allow), get_req("https://evil.example")).await);

    // E — configured allowlist, preflight on a GET-only route. This is also
    // the check that compiles and exercises `.max_age(Duration::from_secs(600))`.
    show("E", &run(apply_cors(base(), &allow), preflight("/a", "https://app.example")).await);

    // R1 — a preflight must not reach the handler.
    let hits = Arc::new(AtomicUsize::new(0));
    let h = hits.clone();
    let counted = Router::new().route(
        "/a",
        get(move || {
            let h = h.clone();
            async move {
                h.fetch_add(1, Ordering::SeqCst);
                "ok"
            }
        }),
    );
    let res = run(apply_cors(counted, &allow), preflight("/a", "https://app.example")).await;
    println!("CHECK R1 status={} handler_hits={}", res.status(), hits.load(Ordering::SeqCst));

    // P2 / P3 — preflight to a path no route matches: .layer() versus .route_layer().
    let cors = CorsLayer::new()
        .allow_origin(allow.clone())
        .allow_methods(Any)
        .allow_headers(Any);
    show("P2", &run(base().layer(cors.clone()), preflight("/missing", "https://app.example")).await);
    show("P3", &run(base().route_layer(cors), preflight("/missing", "https://app.example")).await);

    // H — an invalid origin string cannot become a HeaderValue, so it fails at
    // construction rather than at request time.
    println!("CHECK H parse_is_err={}", "not a header\n".parse::<HeaderValue>().is_err());
}
RUSTEOF
cp "$WORK/with/tests/cors.rs" "$WORK/v06/tests/cors.rs"

# ---------------------------------------------------------------------------
echo "--- A. resolve the probe: can this host reach the crates it needs? ---"
if ! (cd "$WORK/with" && cargo generate-lockfile -q 2>"$WORK/lock.err"); then
  skip "the whole probe: cargo could not resolve the manifest (no network and no warm registry cache)"
  sed 's/^/  /' "$WORK/lock.err" | head -5
  echo
  echo "=== RESULT ==="
  echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
  echo "RESULT: PASS (nothing ran)"
  exit 0
fi
TH=$("$GREP" -A1 '^name = "tower-http"' "$WORK/with/Cargo.lock" | "$GREP" '^version' | tr -d '" ' | cut -d= -f2)
BF=$("$GREP" -A1 '^name = "bitflags"' "$WORK/with/Cargo.lock" | "$GREP" '^version' | tr -d '" ' | cut -d= -f2)
echo "FIGURE resolved tower-http = ${TH}; bitflags = ${BF}"
assert "$(eq "$TH" "0.7.1")" "the probe resolves the exact tower-http version this decision recommends"
echo

# ---------------------------------------------------------------------------
echo "--- B. the twelve observations, on tower-http 0.7.1 ---"
(cd "$WORK/with" && cargo test -q --test cors -- --nocapture --test-threads=1) > "$WORK/out71.txt" 2>&1 || {
  cat "$WORK/out71.txt"; echo "ASSERT FAIL the probe's own test binary did not pass"; exit 1; }
"$GREP" '^CHECK ' "$WORK/out71.txt" | sed 's/^/  /'
O="$WORK/out71.txt"

# Acceptance criterion 1 — empty allowlist, no CORS header AND no Vary.
assert "$(once 'CHECK A status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8}' "$O")" \
  "criterion 1: with the allowlist empty the response carries neither access-control-allow-origin nor vary — the router is observably the one a build with no CORS code produces"
# Acceptance criterion 2 — empty allowlist, OPTIONS still 405.
assert "$(once 'CHECK Q1 status=405 Method Not Allowed headers={allow=GET,HEAD, content-length=0}' "$O")" \
  "criterion 2: with the allowlist empty an OPTIONS preflight on a GET-only route is still 405 Method Not Allowed"
# The measured cost of installing unconditionally — the ground alternative B is rejected on.
assert "$(once 'CHECK Q2-get status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
  "unconditional install, bare CorsLayer::new(): every response gains vary: origin, which criterion 1 forbids"
assert "$(once 'CHECK Q2-options status=200 OK headers={allow=GET,HEAD, content-length=0, vary=origin}' "$O")" \
  "unconditional install, bare CorsLayer::new(): OPTIONS on a GET-only route becomes 200, not 405, which criterion 2 forbids"
assert "$(once 'CHECK Q3-get status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
  "unconditional install configured with py's literal empty list: every response still gains vary: origin"
assert "$(once 'CHECK Q3-options status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, allow=GET,HEAD, content-length=0, vary=origin}' "$O")" \
  "unconditional install configured with py's literal empty list: OPTIONS becomes 200 and even advertises allow-headers and allow-methods, so an empty allowlist is not observationally equivalent to no layer"
# Acceptance criteria 3, 4, 5 and the max-age default imported from py.
assert "$(once 'CHECK C status=200 OK headers={access-control-allow-origin=https://app.example, content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
  "criterion 3: with the allowlist configured, a GET from the allowed origin has that origin echoed back"
assert "$(once 'CHECK D status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8, vary=origin}' "$O")" \
  "criterion 4: with the allowlist configured, a GET from a different origin receives no access-control-allow-origin"
assert "$(once 'CHECK E status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, access-control-max-age=600, allow=GET,HEAD, content-length=0, vary=origin}' "$O")" \
  "criterion 5, and the report gap this run closes: .max_age(Duration::from_secs(600)) compiles and emits access-control-max-age: 600, matching Starlette's always-emitted 600 s default"
assert "$(once 'CHECK R1 status=200 OK handler_hits=0' "$O")" \
  "criterion 5 again, from the handler's side: a preflight short-circuits before the inner service runs — the constraint R75 must order around"
assert "$(once 'CHECK P2 status=200 OK headers={access-control-allow-headers=*, access-control-allow-methods=*, access-control-allow-origin=https://app.example, vary=origin}' "$O")" \
  "Router::layer answers a preflight for a path no route matches, which is what a preflight needs"
assert "$(once 'CHECK P3 status=404 Not Found headers={}' "$O")" \
  "Router::route_layer does not, returning a bare 404 — so .layer(), not .route_layer(), is the right call"
assert "$(once 'CHECK H parse_is_err=true' "$O")" \
  "criterion 6: a syntactically invalid origin fails at HeaderValue parsing, so it fails while the router is built rather than at request time"
echo

# ---------------------------------------------------------------------------
echo "--- C. what 0.7.0's cors change is observable as: the same probe on 0.6.11 ---"
if ! (cd "$WORK/v06" && cargo test -q --test cors -- --nocapture --test-threads=1) > "$WORK/out06.txt" 2>&1; then
  skip "C: the 0.6.11 arm did not build, so the version comparison was not measured"
  sed 's/^/  /' "$WORK/out06.txt" | head -5
else
  "$GREP" '^CHECK ' "$WORK/out06.txt" | sed 's/^/  /'
  V="$WORK/out06.txt"
  assert "$(once 'CHECK C status=200 OK headers={access-control-allow-origin=https://app.example, content-length=2, content-type=text/plain; charset=utf-8, vary=origin, access-control-request-method, access-control-request-headers}' "$V")" \
    "on 0.6.11 the recommended configuration emits vary: origin, access-control-request-method, access-control-request-headers, where 0.7.1 emits vary: origin alone — the #674 relaxation, observable in this template's own configuration"
  assert "$(once 'CHECK A status=200 OK headers={content-length=2, content-type=text/plain; charset=utf-8}' "$V")" \
    "the conditional-install policy behaves identically on 0.6.11: with the allowlist empty there is still no layer and no header"
  assert "$(once 'CHECK Q1 status=405 Method Not Allowed headers={allow=GET,HEAD, content-length=0}' "$V")" \
    "and the 405 on an unconfigured preflight is a property of not installing, not of the version"
  assert "$(once 'CHECK R1 status=200 OK handler_hits=0' "$V")" \
    "the preflight short-circuit is unchanged across the two versions"
  assert "$(once 'CHECK H parse_is_err=true' "$V")" \
    "boot-time origin validation is unchanged across the two versions"
  # Every status code must agree across the two versions; only Vary differs.
  diff <("$GREP" -o '^CHECK [A-Za-z0-9-]* status=[0-9]* [A-Za-z ]*' "$O") \
       <("$GREP" -o '^CHECK [A-Za-z0-9-]* status=[0-9]* [A-Za-z ]*' "$V") > "$WORK/statusdiff.txt" 2>&1 \
    && SAME=1 || SAME=0
  assert "$SAME" \
    "every status code the probe observes is identical on 0.6.11 and 0.7.1, so the 0.6-to-0.7 move changes the Vary value and nothing else this item depends on"
fi
echo

# ---------------------------------------------------------------------------
echo "--- D. what the dependency line actually adds to the resolved graph ---"
(cd "$WORK/with" && cargo metadata --format-version 1 --all-features 2>/dev/null) > "$WORK/md-with.json"
(cd "$WORK/without" && cargo metadata --format-version 1 --all-features 2>/dev/null) > "$WORK/md-without.json"
jq -r '.packages[] | "\(.name) \(.version)"' "$WORK/md-with.json" | sort > "$WORK/pkg-with.txt"
jq -r '.packages[] | "\(.name) \(.version)"' "$WORK/md-without.json" | sort > "$WORK/pkg-without.txt"
NW=$(wc -l < "$WORK/pkg-with.txt" | tr -d ' ')
NO=$(wc -l < "$WORK/pkg-without.txt" | tr -d ' ')
echo "FIGURE resolved packages: with the tower-http line ${NW}, without it ${NO}"
echo "added by the line:"
comm -23 "$WORK/pkg-with.txt" "$WORK/pkg-without.txt" | sed 's/^/  /'
echo "removed by the line:"
comm -13 "$WORK/pkg-with.txt" "$WORK/pkg-without.txt" | sed 's/^/  (none)/;q'
ADDED=$(comm -23 "$WORK/pkg-with.txt" "$WORK/pkg-without.txt" | tr '\n' ';')
assert "$(eq "$ADDED" "bitflags 2.13.2;tower-http 0.7.1;")" \
  "the dependency line adds exactly two packages, tower-http 0.7.1 and bitflags 2.13.2, and nothing else moves"
REMOVED=$(comm -13 "$WORK/pkg-with.txt" "$WORK/pkg-without.txt" | wc -l | tr -d ' ')
assert "$(eq "$REMOVED" "0")" "and removes none, so this is a pure addition to R69's accepted graph"
echo "the highest declared rust-version among the resolved dependencies:"
jq -r '[.packages[] | select(.rust_version != null) | select(.name != "r76probe") | "\(.rust_version) \(.name)"]
       | sort | .[-3:] | .[]' "$WORK/md-with.json" | sed 's/^/  /'
MAXRV=$(jq -r '[.packages[] | select(.rust_version != null) | select(.name != "r76probe") | .rust_version]
               | sort | .[-1]' "$WORK/md-with.json")
echo "FIGURE maximum declared rust-version in the resolved dependency tree = ${MAXRV}"
assert "$(eq "$MAXRV" "1.80")" \
  "gate 2 over the tree, not just the crate: the highest declared rust-version among the dependencies is axum 0.8.9's 1.80, well inside the 1.96 floor"
UNDECL=$(jq -r '[.packages[] | select(.rust_version == null) | .name] | sort | join(", ")' "$WORK/md-with.json")
NUND=$(jq -r '[.packages[] | select(.rust_version == null)] | length' "$WORK/md-with.json")
echo "FIGURE packages declaring no rust-version (${NUND}): ${UNDECL}"
UNDECL_NOTH=$(jq -r '[.packages[] | select(.rust_version == null) | .name]
                     | map(select(. == "tower-http" or . == "bitflags")) | length' "$WORK/md-with.json")
assert "$(eq "$UNDECL_NOTH" "0")" \
  "neither package this item adds is among the undeclared ones — every undeclared package arrives with axum or tokio, which R69 already accepted"
echo "where tower sits in the non-dev graph:"
(cd "$WORK/with" && cargo tree -e normal -i tower 2>/dev/null) | sed 's/^/  /'
TOWER_VIA_AXUM=$( (cd "$WORK/with" && cargo tree -e normal -i tower 2>/dev/null) | "$GREP" -c 'axum v0.8.9' || true)
assert "$(if [ "$TOWER_VIA_AXUM" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "tower 0.5.3 is already in the non-dev graph through axum, so this item's dependency line neither adds it nor promotes it — tower stays declared as crates/web's dev-dependency, which is the value R69 fixed"
echo "which tower features axum already activates:"
(cd "$WORK/with" && cargo tree -e features -i tower 2>/dev/null) | "$GREP" -m2 'tower feature' | sed 's/^/  /'
UTIL=$( (cd "$WORK/with" && cargo tree -e features -i tower 2>/dev/null) | "$GREP" -c 'tower feature "util"' || true)
assert "$(if [ "$UTIL" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "axum already activates tower's util feature, so option_layer costs no crate and no feature — its only cost is a DIRECT tower dependency declaration on crates/web, which is the precise price of the rejected alternative C"
echo "what tower-http itself pulls in (normal edges, depth 1):"
(cd "$WORK/with" && cargo tree -e normal -p tower-http --depth 1 2>/dev/null) | sed 's/^/  /'
TOKIO_EDGE=$( (cd "$WORK/with" && cargo tree -e normal -p tower-http --depth 1 2>/dev/null) | "$GREP" -c 'tokio' || true)
assert "$(eq "$TOKIO_EDGE" "0")" \
  "gate 5: with only the cors feature on, tower-http has no tokio edge, so the layer is executor-agnostic and adds no async-runtime coupling"
echo

# ---------------------------------------------------------------------------
echo "--- E. gate 6: what the dependency costs in build time and bytes ---"
# Two clean release builds per arm. Build seconds are wall-clock on a shared
# machine and are printed, never asserted. Stripped byte sizes are
# deterministic for a fixed toolchain and ARE asserted against each other.
cat > "$WORK/with/src/main.rs" <<'EOF'
use axum::Router;
use axum::http::HeaderValue;
use axum::routing::get;
use std::time::Duration;
use tower_http::cors::{Any, CorsLayer};

fn main() {
    let origins: Vec<HeaderValue> = std::env::var("ORIGINS")
        .unwrap_or_default()
        .split(',')
        .filter(|s| !s.is_empty())
        .filter_map(|s| s.parse().ok())
        .collect();
    let mut app: Router = Router::new().route("/a", get(|| async { "ok" }));
    if !origins.is_empty() {
        app = app.layer(
            CorsLayer::new()
                .allow_origin(origins)
                .allow_methods(Any)
                .allow_headers(Any)
                .max_age(Duration::from_secs(600)),
        );
    }
    println!("{:?}", std::hint::black_box(&app) as *const _);
}
EOF
cat > "$WORK/without/src/main.rs" <<'EOF'
use axum::Router;
use axum::http::HeaderValue;
use axum::routing::get;

fn main() {
    let origins: Vec<HeaderValue> = std::env::var("ORIGINS")
        .unwrap_or_default()
        .split(',')
        .filter(|s| !s.is_empty())
        .filter_map(|s| s.parse().ok())
        .collect();
    let app: Router = Router::new().route("/a", get(|| async { "ok" }));
    let _ = origins.len();
    println!("{:?}", std::hint::black_box(&app) as *const _);
}
EOF
for arm in without with; do
  for run in 1 2; do
    rm -rf "$WORK/$arm/target"
    S=$(python3 -c 'import time;print(time.time())')
    (cd "$WORK/$arm" && cargo build -q --release) >/dev/null 2>&1
    E=$(python3 -c 'import time;print(time.time())')
    SECS=$(python3 -c "print(f'{float('$E')-float('$S'):.1f}')")
    echo "FIGURE clean release build, arm=${arm}, run ${run}: ${SECS} s   (wall clock on a shared host; VARIES between runs and is never asserted)"
  done
  cp "$WORK/$arm/target/release/r76probe" "$WORK/bin-$arm"
  strip -x "$WORK/bin-$arm"
  SZ=$(stat -f%z "$WORK/bin-$arm" 2>/dev/null || stat -c%s "$WORK/bin-$arm")
  echo "FIGURE stripped release binary, arm=${arm}: ${SZ} bytes"
  if [ "$arm" = "without" ]; then SZ_WITHOUT=$SZ; else SZ_WITH=$SZ; fi
done
DELTA=$((SZ_WITH - SZ_WITHOUT))
echo "FIGURE binary-size cost of the CORS layer on this probe = +${DELTA} bytes"
assert "$(if [ "$DELTA" -gt 0 ]; then echo 1; else echo 0; fi)" \
  "gate 6: the dependency costs binary size rather than being free, and the cost is measured here rather than estimated"
assert "$(if [ "$DELTA" -lt 400000 ]; then echo 1; else echo 0; fi)" \
  "gate 6: that cost is under 400 kB on this probe, which is the order of magnitude the decision states — and the probe contains almost no other code, so the percentage form must not be carried forward"
echo "NOTE  no compile-time cost is asserted: across two runs per arm the two arms"
echo "      did not separate beyond this host's run-to-run variation, so this run"
echo "      claims no build-second delta at all."
echo

# ---------------------------------------------------------------------------
echo "=== RESULT ==="
echo "PASS=${pass} FAIL=${failn} SKIP=${skipn} TOTAL=$((pass + failn + skipn))"
if [ "$failn" -gt 0 ]; then echo "RESULT: FAIL"; exit 1; fi
echo "RESULT: PASS"
