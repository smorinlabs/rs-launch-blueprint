#!/usr/bin/env bash
# R84 revision 4 — executed probe of the recommended generator, openapi-to-rust,
# driven through the exact `just client-rust` recipe the decision recommends,
# against the committed OpenAPI 3.1.0 fixture fixtures/api-3.1.json.
# Revision 4 changes: the tool cache is version-keyed ($CACHE/o2r-$TOOL_VERSION),
# so a 0.19.0 leg run after a 0.17.0 leg installs its own binary instead of
# reusing the older one (r3 audits JF-8-A/EF-1).
# Revision 3 changes (r2: byte-identical to r1): TOOL_VERSION and the T10
# generator-header match are parametric (${TOOL_VERSION:-0.17.0}); volatile
# timings honour $R84_TIMINGS, so a rerun only overwrites the cited
# snapshots/openapi-to-rust-timings.txt when the override is unset.
#
# It proves, or refutes, each load-bearing claim about the pick:
#   T01-T05  the tool, its direct mode and what it emits (a module tree, no crate)
#   T06-T12  the recommended recipe: a standalone package outside any workspace,
#            edition 2024, compiling on current stable and on the 1.96 floor
#   T13-T16  --check drift detection, determinism, missing-operationId fallback
#   T17-T18  what the generated tree pulls in (tokio) and leaves out (unsafe)
#   R01-R09  the binding REST API Design Standard v2.0.0 section 12 client
#            obligations, executed against a local HTTP listener (R12.3, R12.4,
#            R12.6, R12.7) plus the inert `timeout_seconds` configuration key
#   AU01     cargo audit over the generated client's lockfile
#
# Reproducibility: the log carries no timestamp, duration, PID or temporary
# path, so two runs on one host and one day are byte-identical. Volatile
# numbers (durations) go to snapshots/openapi-to-rust-timings.txt instead.
# Prerequisites, each with a named SKIP when absent: cargo, rustup (for the
# 1.96.0 floor), just, jq, network access to crates.io and github.com.
# Cache (tool binary, advisory database): $R84_CACHE, default
# ${TMPDIR:-/tmp}/r84-synth-cache — reused across runs, never inside the repo.
# Reruns that must not disturb the cited evidence set R84_TIMINGS to a path
# outside the tree; the log is byte-identical either way.

set -uo pipefail

GREP=/usr/bin/grep
PASS=0; FAIL=0; SKIP=0
ok()   { PASS=$((PASS+1)); echo "PASS  $1"; }
bad()  { FAIL=$((FAIL+1)); echo "FAIL  $1"; }
skip() { SKIP=$((SKIP+1)); echo "SKIP  $1"; }
check() { # check <id-and-claim> <command...>
  local label=$1; shift
  if "$@" >/dev/null 2>&1; then ok "$label"; else bad "$label"; fi
}
summary() {
  echo
  echo "PASS=$PASS FAIL=$FAIL SKIP=$SKIP TOTAL=$((PASS+FAIL+SKIP))"
  exit "$FAIL"
}

HERE=$(unset CDPATH; cd -- "$(dirname -- "$0")" && pwd)
FIXTURE="$HERE/fixtures/api-3.1.json"
SNAP="${R84_TIMINGS:-$HERE/snapshots/openapi-to-rust-timings.txt}"
CACHE=${R84_CACHE:-${TMPDIR:-/tmp}/r84-synth-cache}
TOOL_VERSION=${TOOL_VERSION:-0.17.0}
FLOOR=1.96.0
mkdir -p "$CACHE/cargo-home" "${SNAP%/*}"
# A private CARGO_HOME keeps registry downloads out of ~/.cargo (sandboxed
# agent shells refuse writes there) and makes the run independent of it.
export CARGO_HOME="$CACHE/cargo-home"
WORK=$(mktemp -d "${TMPDIR:-/tmp}/r84-o2r.XXXXXX")
trap 'rm -rf "$WORK"' EXIT

echo "R84 openapi-to-rust probe (revision 4)"
echo "grep: $($GREP --version | head -1)"
echo "fixture: fixtures/api-3.1.json, openapi $(jq -r .openapi "$FIXTURE"), sha256 $(shasum -a 256 "$FIXTURE" | cut -d' ' -f1)"
echo "host: $(uname -s) $(uname -m)"
echo "rustc: $(rustc --version 2>/dev/null || echo absent)"
echo "cargo: $(cargo --version 2>/dev/null || echo absent)"
echo "just: $(just --version 2>/dev/null || echo absent)"
echo

for t in cargo jq just shasum; do
  command -v "$t" >/dev/null 2>&1 || { skip "S0 required tool '$t' is absent — every check below needs it"; summary; }
done

: > "$SNAP"
stamp() { date +%s; }

# ------------------------------------------------------------------ the tool
# The install root is version-keyed: each TOOL_VERSION gets its own binary, so
# a 0.19.0 leg never reuses a 0.17.0 install left in a shared cache (JF-8-A).
O2R_ROOT="$CACHE/o2r-$TOOL_VERSION"
BIN="$O2R_ROOT/bin/openapi-to-rust"
if [ ! -x "$BIN" ]; then
  t0=$(stamp)
  cargo install --locked --quiet --root "$O2R_ROOT" openapi-to-rust --version "$TOOL_VERSION" >/dev/null 2>&1
  echo "cargo install openapi-to-rust $TOOL_VERSION: $(( $(stamp) - t0 )) s" >> "$SNAP"
fi
[ -x "$BIN" ] || { skip "S1 openapi-to-rust $TOOL_VERSION could not be installed (crates.io unreachable?)"; summary; }
export PATH="$O2R_ROOT/bin:$PATH"

check "T01 the installed tool reports 'openapi-to-rust $TOOL_VERSION'" \
  test "$(openapi-to-rust --version)" = "openapi-to-rust $TOOL_VERSION"
check "T02 'generate --help' offers --check, the staleness gate the drift discussion relies on" \
  $GREP -q -- '--check' <(openapi-to-rust generate --help)

D="$WORK/direct"
openapi-to-rust generate "$FIXTURE" --output-dir "$D" --module-name api --quiet >/dev/null 2>&1
check "T03 direct-mode generation from the OpenAPI 3.1.0 fixture exits 0" test -f "$D/client.rs"
LISTING=$(cd "$D" && find . -type f | sed 's|^\./||' | LC_ALL=C sort | tr '\n' ' ')
echo "      emitted: $LISTING"
check "T04 the output is a MODULE tree (mod.rs client.rs types.rs REQUIRED_DEPS.toml) and no Cargo.toml" \
  test "$LISTING" = "REQUIRED_DEPS.toml client.rs mod.rs types.rs "
check "T05 REQUIRED_DEPS.toml names reqwest 0.13 with default features off and rustls on" \
  $GREP -q '^reqwest = { version = "0.13", default-features = false, features = \["query", "rustls", "stream"\] }$' "$D/REQUIRED_DEPS.toml"
$GREP -E '^    pub (async )?fn [a-z0-9_]+\(' "$D/client.rs" | sed -E 's/^ +//; s/\(.*//' | LC_ALL=C sort | sed 's/^/      /'
check "T06 curated operationIds become ops_healthz / projects_list_projects / projects_get_project" \
  test "$($GREP -c -E '^    pub async fn (ops_healthz|projects_list_projects|projects_get_project)\(' "$D/client.rs")" = 3
KINDS=$(awk '/^    pub async fn /{k="async"} /^    pub fn /{k="sync"} /-> Result<.*ApiOpError</{n[k]++} END{printf "async=%d sync=%d", n["async"], n["sync"]}' "$D/client.rs")
check "T07 every generated operation is async: of the methods returning ApiOpError, $KINDS" \
  test "$KINDS" = "async=3 sync=0"

# ------------------------------------------------ the recommended recipe, run by just
T="$WORK/tpl"
mkdir -p "$T/docs/api" "$T/src"
cp "$FIXTURE" "$T/docs/api/openapi.json"
cat > "$T/Cargo.toml" <<'EOF'
[package]
name = "rs-launch-blueprint"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false

[workspace]
EOF
echo 'pub fn placeholder() {}' > "$T/src/lib.rs"
cat > "$T/openapi-to-rust.toml" <<'EOF'
# Generator input for `just client-rust` (F335). The snapshot is R71's; the
# output directory is never committed.
[generator]
spec_path = "docs/api/openapi.json"
output_dir = "clients/rust/src"
module_name = "api"

[features]
enable_async_client = true

# Outbound-request tracing is R58's and R78's concern, not this recipe's:
# switched off so the generated tree carries no reqwest-tracing.
[http_client.tracing]
enabled = false

# REST API Design Standard R12.4 / R4.9: every enum the contract documents as
# open is listed here, so an unknown value becomes `Custom(String)`.
[extensible_enums]
ProjectState = true
EOF
cat > "$T/Justfile" <<'EOF'
# Generate a typed Rust client from the OpenAPI snapshot (F335) — never hand-write one
[group('build')]
client-rust:
    rm -rf clients/rust
    openapi-to-rust generate --config openapi-to-rust.toml --quiet
    printf '%s\n' '[package]' 'name = "rs-launch-blueprint-client"' 'version = "0.0.0"' 'edition = "2024"' 'rust-version = "1.96"' 'license = "MIT OR Apache-2.0"' 'publish = false' '' '[lib]' 'path = "src/mod.rs"' '' '[workspace]' '' > clients/rust/Cargo.toml
    sed -n '/^\[dependencies\]/,$p' clients/rust/src/REQUIRED_DEPS.toml >> clients/rust/Cargo.toml
    echo "client written to clients/rust"
EOF

C="$T/clients/rust"
check "T08 'just client-rust' exits 0 and prints its completion line" \
  $GREP -qx 'client written to clients/rust' <(cd "$T" && just client-rust 2>/dev/null)
check "T09 the recipe's package declares edition 2024, rust-version 1.96 and an empty [workspace] table" \
  bash -c "$GREP -qx 'edition = \"2024\"' '$C/Cargo.toml' && $GREP -qx 'rust-version = \"1.96\"' '$C/Cargo.toml' && $GREP -qx '\[workspace\]' '$C/Cargo.toml'"
check "T10 no hand-written Rust file: every .rs file under clients/rust carries the generator's own header" \
  test "$(find "$C/src" -name '*.rs' | wc -l | tr -d ' ')" = "$($GREP -l "Generated by openapi-to-rust v$TOOL_VERSION" "$C"/src/*.rs | wc -l | tr -d ' ')"

t0=$(stamp)
if (cd "$C" && cargo check --quiet >/dev/null 2>&1); then ok "T11 the generated package compiles on the current stable toolchain ($(rustc --version | cut -d' ' -f2))"; else bad "T11 the generated package compiles on current stable"; fi
echo "clean cargo check of generated client, stable: $(( $(stamp) - t0 )) s" >> "$SNAP"
if command -v rustup >/dev/null 2>&1 && rustup run "$FLOOR" rustc --version >/dev/null 2>&1; then
  t0=$(stamp)
  if (cd "$C" && CARGO_TARGET_DIR="$WORK/target-floor" rustup run "$FLOOR" cargo check --quiet >/dev/null 2>&1); then
    ok "T12 the generated package compiles on the $FLOOR floor (msrv-policy: stable 1.98 minus 2)"
  else bad "T12 the generated package compiles on the $FLOOR floor"; fi
  echo "clean cargo check of generated client, $FLOOR: $(( $(stamp) - t0 )) s" >> "$SNAP"
else
  skip "T12 rustup toolchain $FLOOR is not installed, so the floor build was not run"
fi
check "T13 the template root is untouched: cargo metadata lists exactly one workspace member, the root package" \
  test "$(cd "$T" && cargo metadata --no-deps --format-version 1 2>/dev/null | jq -r '[.workspace_members[]] | length')" = 1
check "T14 tokio IS in the generated client's normal tree (reqwest -> hyper), which is why it stays outside the workspace" \
  $GREP -q '^tokio v' <(cd "$C" && cargo tree -e normal --prefix none 2>/dev/null)
check "T15 the template root's normal tree has no tokio at all after the recipe ran" \
  bash -c "! (cd '$T' && cargo tree -e normal --prefix none 2>/dev/null | $GREP -q '^tokio v')"

cp -R "$C" "$WORK/first"
(cd "$T" && just client-rust >/dev/null 2>&1)
check "T16 regeneration is deterministic: two recipe runs produce byte-identical trees (target/ and Cargo.lock excluded)" \
  diff -r -x target -x Cargo.lock "$WORK/first" "$C"

# ------------------------------------------------------------------ --check
(cd "$T" && openapi-to-rust generate --config openapi-to-rust.toml --check --quiet >/dev/null 2>&1); rc=$?
check "T17 --check on freshly generated output exits 0" test "$rc" = 0
cp "$T/docs/api/openapi.json" "$WORK/snapshot.bak"
jq '.paths["/readyz"] = {"get":{"operationId":"ops-readyz","responses":{"200":{"description":"ready"}}}}' \
  "$WORK/snapshot.bak" > "$T/docs/api/openapi.json"
(cd "$T" && openapi-to-rust generate --config openapi-to-rust.toml --check --quiet >/dev/null 2>&1); rc=$?
check "T18 --check exits non-zero once the snapshot gains an operation the output lacks (rc=$rc)" test "$rc" != 0
cp "$WORK/snapshot.bak" "$T/docs/api/openapi.json"
echo '// hand edit' >> "$C/src/client.rs"
(cd "$T" && openapi-to-rust generate --config openapi-to-rust.toml --check --quiet >/dev/null 2>&1); rc=$?
check "T19 --check exits non-zero once a generated file is hand-edited (rc=$rc)" test "$rc" != 0
(cd "$T" && just client-rust >/dev/null 2>&1)

N="$WORK/noopid"
jq 'del(.paths[][].operationId)' "$FIXTURE" > "$WORK/noopid.json"
openapi-to-rust generate "$WORK/noopid.json" --output-dir "$N" --module-name api --quiet >/dev/null 2>&1; rc=$?
check "T20 with every operationId removed, generation still exits 0 (no hard failure, unlike progenitor)" test "$rc" = 0
$GREP -E '^    pub async fn [a-z0-9_]+\(' "$N/client.rs" 2>/dev/null | sed -E 's/^ +pub async fn //; s/\(.*//' | LC_ALL=C sort | sed 's/^/      fallback name: /'
check "T21 the fallback names are method_path derived: get_healthz, get_v1_projects, get_v1_projects_project_id" \
  test "$($GREP -E '^    pub async fn [a-z0-9_]+\(' "$N/client.rs" | sed -E 's/^ +pub async fn //; s/\(.*//' | LC_ALL=C sort | tr '\n' ' ')" = "get_healthz get_v1_projects get_v1_projects_project_id "

UNSAFE=$(cat "$C"/src/*.rs | $GREP -c -w 'unsafe')
check "T22 the generated client contains 0 lines with the token 'unsafe' (counted: $UNSAFE)" test "$UNSAFE" = 0

# ------------------------------------------- REST standard section 12, executed
T30="$WORK/t30"; T1="$WORK/t1"
for pair in "$T30:30" "$T1:1"; do
  dir=${pair%%:*}; secs=${pair##*:}
  mkdir -p "$dir"; cp "$FIXTURE" "$dir/api.json"
  printf '%s\n' '[generator]' 'spec_path = "api.json"' 'output_dir = "out"' 'module_name = "api"' '' \
    '[features]' 'enable_async_client = true' '' '[http_client]' "timeout_seconds = $secs" > "$dir/openapi-to-rust.toml"
  (cd "$dir" && openapi-to-rust generate --config openapi-to-rust.toml --quiet >/dev/null 2>&1)
done
check "R01 [http_client] timeout_seconds is accepted but inert: output for 30 s and for 1 s is byte-identical" \
  bash -c "test -f '$T30/out/client.rs' && diff -r '$T30/out' '$T1/out'"
check "R02 the generated client builds its reqwest client with reqwest::Client::new() and no .timeout(...) call" \
  bash -c "$GREP -q 'reqwest::Client::new()' '$T30/out/client.rs' && ! $GREP -q '\.timeout(' '$T30/out/client.rs'"

# Static reads of the recipe's own output, which hold whether or not the HTTP
# half below can run: they are what R07-R09 then observe on the wire.
CL="$C/src/client.rs"
check "R11 R12.7 (static): the Problem body is parsed only inside the 404u16 arm of a match on the status code" \
  bash -c "test \"\$($GREP -c 'serde_json::from_str::<Problem>' '$CL')\" = 1 && $GREP -A1 '404u16 => {' '$CL' | $GREP -q 'serde_json::from_str::<Problem>(&body_text)'"
check "R12 R12.6 (static): each of the 3 operations drops a caller's Accept header and sets Accept: application/json" \
  bash -c "test \"\$($GREP -c 'if !name.eq_ignore_ascii_case(\"accept\") {' '$CL')\" = 3 && test \"\$($GREP -c 'req = req.header(reqwest::header::ACCEPT, \"application/json\");' '$CL')\" = 3"
check "R13 R12.1/R12.2 (static): the recipe's client installs no retry middleware, so it never retries on its own" \
  bash -c "! $GREP -q -E 'reqwest_retry|RetryTransientMiddleware|with_retry' '$CL' && ! $GREP -q 'reqwest-retry' '$C/Cargo.toml'"

P="$WORK/probe"
mkdir -p "$P/src"
cp -R "$D" "$P/src/closed"
{
  printf '%s\n' '[package]' 'name = "r84-probe"' 'version = "0.0.0"' 'edition = "2024"' 'publish = false' '' '[workspace]' ''
  sed -n '/^\[dependencies\]/,$p' "$D/REQUIRED_DEPS.toml"
  printf '%s\n' 'tokio = { version = "1", features = ["rt", "macros", "time", "net"] }' \
    "client = { path = \"$C\", package = \"rs-launch-blueprint-client\" }"
} > "$P/Cargo.toml"
cat > "$P/src/main.rs" <<'EOF'
// Throwaway probe: `closed` is the generator's default output, `client` is the
// output of the recommended recipe (with [extensible_enums] ProjectState).
#[allow(dead_code, clippy::all)]
#[path = "closed/mod.rs"]
mod closed;

use std::io::{Read, Write};
use std::net::TcpListener;
use std::sync::{Arc, Mutex};
use std::time::Duration;

const PROJECT: &str = r#"{"id":"p1","name":"demo","state":"suspended","visibility":"internal","description":null,"extra_field":42}"#;
const KNOWN: &str = r#"{"id":"p1","name":"demo","state":"active","visibility":"public","extra_field":42}"#;

fn serve(listener: TcpListener, accepts: Arc<Mutex<Vec<String>>>) {
    std::thread::spawn(move || {
        for stream in listener.incoming() {
            let Ok(mut s) = stream else { continue };
            let mut buf = Vec::new();
            let mut chunk = [0u8; 1024];
            loop {
                let n = match s.read(&mut chunk) {
                    Ok(0) | Err(_) => break,
                    Ok(n) => n,
                };
                buf.extend_from_slice(&chunk[..n]);
                if buf.windows(4).any(|w| w == b"\r\n\r\n") {
                    break;
                }
            }
            let req = String::from_utf8_lossy(&buf).to_string();
            let path = req.split_whitespace().nth(1).unwrap_or("").to_string();
            for line in req.lines() {
                if let Some((k, v)) = line.split_once(':') {
                    if k.eq_ignore_ascii_case("accept") {
                        accepts.lock().unwrap().push(v.trim().to_string());
                    }
                }
            }
            let (status, ctype, body) = match path.as_str() {
                "/v1/projects/p1" => ("200 OK", "application/json", PROJECT),
                "/v1/projects/gone" => (
                    "404 Not Found",
                    "application/problem+json",
                    r#"{"type":"about:blank","title":"Not Found","status":404,"detail":"no project gone"}"#,
                ),
                "/v1/projects/proxy" => ("404 Not Found", "text/plain", "upstream proxy says no"),
                _ => ("500 Internal Server Error", "text/plain", "unexpected"),
            };
            let resp = format!(
                "HTTP/1.1 {status}\r\nContent-Type: {ctype}\r\nContent-Length: {}\r\nConnection: close\r\n\r\n{body}",
                body.len()
            );
            let _ = s.write_all(resp.as_bytes());
        }
    });
}

#[tokio::main(flavor = "current_thread")]
async fn main() {
    match serde_json::from_str::<closed::Project>(KNOWN) {
        Ok(_) => println!("DEFAULT_UNKNOWN_FIELD=accepted"),
        Err(e) => println!("DEFAULT_UNKNOWN_FIELD=rejected {e}"),
    }
    match serde_json::from_str::<closed::Project>(PROJECT) {
        Ok(_) => println!("DEFAULT_UNKNOWN_STATE=accepted"),
        Err(e) => println!("DEFAULT_UNKNOWN_STATE=rejected {e}"),
    }
    match serde_json::from_str::<client::Project>(PROJECT) {
        Ok(p) => println!("RECIPE_UNKNOWN_VALUES=accepted state={:?} visibility={:?}", p.state, p.visibility),
        Err(e) => println!("RECIPE_UNKNOWN_VALUES=rejected {e}"),
    }

    let accepts = Arc::new(Mutex::new(Vec::new()));
    // A sandboxed shell may refuse even a loopback bind; say so and stop.
    let listener = match TcpListener::bind("127.0.0.1:0") {
        Ok(l) => l,
        Err(e) => {
            println!("RT_BIND=refused {:?}", e.kind());
            return;
        }
    };
    let base = format!("http://{}", listener.local_addr().unwrap());
    serve(listener, accepts.clone());
    let c = client::HttpClient::new()
        .with_base_url(base)
        .with_header("Accept", "application/problem+json");

    match c.projects_get_project("p1").await {
        Ok(p) => println!("RT_200=typed id={} state={:?} visibility={:?}", p.id, p.state, p.visibility),
        Err(e) => println!("RT_200=error {e}"),
    }
    match c.projects_get_project("gone").await {
        Err(client::ApiOpError::Api(e)) => println!(
            "RT_404_PROBLEM=api status={} typed_status404={}",
            e.status,
            matches!(e.typed, Some(client::ProjectsGetProjectApiError::Status404(_)))
        ),
        Err(client::ApiOpError::Transport(e)) => println!("RT_404_PROBLEM=transport {e}"),
        Ok(_) => println!("RT_404_PROBLEM=ok"),
    }
    match c.projects_get_project("proxy").await {
        Err(client::ApiOpError::Api(e)) => println!(
            "RT_404_NON_PROBLEM=api status={} typed_none={} parse_error_some={} body={}",
            e.status,
            e.typed.is_none(),
            e.parse_error.is_some(),
            e.body
        ),
        Err(client::ApiOpError::Transport(e)) => println!("RT_404_NON_PROBLEM=transport {e}"),
        Ok(_) => println!("RT_404_NON_PROBLEM=ok"),
    }
    let mut seen = accepts.lock().unwrap().clone();
    seen.sort();
    seen.dedup();
    println!("RT_ACCEPT_SENT={}", seen.join(" | "));

    let hang = TcpListener::bind("127.0.0.1:0").unwrap();
    let hang_base = format!("http://{}", hang.local_addr().unwrap());
    std::thread::spawn(move || {
        let mut held = Vec::new();
        for s in hang.incoming().flatten() {
            held.push(s);
        }
    });
    let slow = client::HttpClient::new().with_base_url(hang_base);
    let r = tokio::time::timeout(Duration::from_millis(500), slow.ops_healthz()).await;
    println!("RT_CALLER_DEADLINE={}", if r.is_err() { "elapsed" } else { "completed" });
}
EOF
t0=$(stamp)
if OUT=$(cd "$P" && cargo run --quiet 2>/dev/null); then
  echo "clean build+run of the section-12 probe, stable: $(( $(stamp) - t0 )) s" >> "$SNAP"
  while IFS= read -r line; do echo "      $line"; done <<<"$OUT"
  check "R03 R12.4 unknown response FIELD: the default output ignores it" \
    $GREP -qx 'DEFAULT_UNKNOWN_FIELD=accepted' <<<"$OUT"
  check "R04 R12.4 unknown ENUM VALUE, default output: a plain 'enum' schema renders closed and rejects 'suspended'" \
    $GREP -q "^DEFAULT_UNKNOWN_STATE=rejected unknown variant .suspended." <<<"$OUT"
  check "R05 R12.4 with the recipe's [extensible_enums] entry AND the anyOf-open Visibility, both unknown values are kept" \
    $GREP -qx 'RECIPE_UNKNOWN_VALUES=accepted state=Custom("suspended") visibility=Custom("internal")' <<<"$OUT"
  if $GREP -q '^RT_BIND=refused' <<<"$OUT"; then
    for r in "R06 end-to-end typed 200" "R07 R12.7 problem+json 404" "R08 R12.7 non-problem 404" "R09 R12.6 Accept header" "R10 R12.3 caller deadline"; do
      skip "$r — this shell refused a loopback TCP bind, so the HTTP half of the probe could not run"
    done
  else
  check "R06 end to end over HTTP: the 200 body with an unknown field and two unknown values deserializes into the typed Project" \
    $GREP -qx 'RT_200=typed id=p1 state=Custom("suspended") visibility=Custom("internal")' <<<"$OUT"
  check "R07 R12.7 a problem+json 404 is branched on status and parsed into the typed Status404(Problem)" \
    $GREP -qx 'RT_404_PROBLEM=api status=404 typed_status404=true' <<<"$OUT"
  check "R08 R12.7 a text/plain 404 from 'infrastructure' still surfaces as status 404 with the raw body, typed=None, parse_error kept" \
    $GREP -qx 'RT_404_NON_PROBLEM=api status=404 typed_none=true parse_error_some=true body=upstream proxy says no' <<<"$OUT"
  check "R09 R12.6 DEPARTS (SHOULD): even with a caller-supplied Accept, only 'application/json' reaches the server — OVERRIDE (OV-11)" \
    $GREP -qx 'RT_ACCEPT_SENT=application/json' <<<"$OUT"
  check "R10 R12.3 is met by the caller: tokio::time::timeout around a call to a never-answering listener elapses" \
    $GREP -qx 'RT_CALLER_DEADLINE=elapsed' <<<"$OUT"
  fi
else
  bad "R03-R10 the section-12 probe crate failed to build or run"
fi

# ------------------------------------------------------------------ advisories
if command -v cargo-audit >/dev/null 2>&1; then
  DB="$CACHE/advisory-db"
  if [ ! -d "$DB/.git" ]; then git clone --quiet --depth 1 https://github.com/rustsec/advisory-db "$DB" >/dev/null 2>&1; fi
  if [ -d "$DB/.git" ]; then
    (cd "$C" && cargo generate-lockfile --quiet >/dev/null 2>&1)
    if (cd "$C" && cargo audit --db "$DB" --no-fetch --file Cargo.lock >/dev/null 2>&1); then
      ok "AU01 cargo audit over the generated client's resolved lockfile reports no vulnerability"
    else
      bad "AU01 cargo audit over the generated client's resolved lockfile reports a finding"
    fi
    echo "advisory-db HEAD at audit: $(git -C "$DB" rev-parse HEAD)" >> "$SNAP"
  else
    skip "AU01 the RustSec advisory database could not be cloned from github.com"
  fi
else
  skip "AU01 cargo-audit is not installed"
fi

summary
