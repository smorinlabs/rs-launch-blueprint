#!/usr/bin/env bash
# R35 revision 1 — the recommended coverage stack, executed on a realistic fixture.
# Fixture: a Cargo workspace shaped like the template — a core library member, a
# root package with the CLI binary `rslbp`, and an off-by-default `web` feature
# (axum 0.8.9 + tokio 1.53.1, tower 0.5.3 for tests, per the web-extra-surface
# row in inputs/PARAMETERS.md) gating a router module and the `rslbp-serve`
# binary. Tests: unit tests, CLI subprocess tests through CARGO_BIN_EXE_rslbp,
# in-process router tests, and two subprocess tests of the serve binary: one
# prints its version, one drives bind -> serve -> SIGINT drain -> exit 0.
# The Justfile `coverage` recipe is the one the DECISION recommends.
#
# Toolchain: rustup 1.93.0, the only local toolchain carrying llvm-tools-preview
# (see DECISION ## Empirical check for why no component was added to another).
# Usage: bash r35-coverage.sh   (CARGO_HOME must hold cargo-llvm-cov 0.9.1)
set -euo pipefail

: "${CARGO_HOME:?CARGO_HOME must point at the private cargo home}"
export PATH="$HOME/.cargo/bin:$CARGO_HOME/bin:$PATH"
export RUSTUP_TOOLCHAIN=1.93.0
export CARGO_LLVM_COV_SETUP=no
export CARGO_TERM_COLOR=never
unset CARGO_TARGET_DIR RUSTFLAGS LLVM_COV LLVM_PROFDATA
fx="$(mktemp -d)/fixture"
trap 'rm -rf "$(dirname "$fx")"' EXIT

pass=0; fail=0
ok()  { pass=$((pass + 1)); echo "PASS $1 — $2"; }
bad() { fail=$((fail + 1)); echo "FAIL $1 — $2"; }
info() { echo "INFO $*"; }
check() { local id="$1" desc="$2"; shift 2; if "$@"; then ok "$id" "$desc"; else bad "$id" "$desc"; fi; }

info "date_utc=$(date -u +%Y-%m-%dT%H:%M:%SZ) host=$(uname -srm)"
info "cargo=$(command -v cargo) $(cargo --version) | $(rustc --version) | $(rustc -vV | /usr/bin/grep '^LLVM version')"
info "just=$(command -v just) $(just --version) | $(cargo llvm-cov --version)"
sysroot="$(rustc --print sysroot)"
check C0a "active toolchain is rustup 1.93.0" test "$(rustc --version | cut -d' ' -f2)" = 1.93.0
check C0b "llvm-tools-preview present in that sysroot (llvm-cov and llvm-profdata)" \
  test -x "$sysroot/lib/rustlib/aarch64-apple-darwin/bin/llvm-cov" -a -x "$sysroot/lib/rustlib/aarch64-apple-darwin/bin/llvm-profdata"
check C0c "cargo-llvm-cov 0.9.1 on PATH" test "$(cargo llvm-cov --version)" = "cargo-llvm-cov 0.9.1"

# ---------------------------------------------------------------- fixture
mkdir -p "$fx/src/bin" "$fx/tests" "$fx/crates/core/src"
cat >"$fx/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/core"]
resolver = "3"

[package]
name = "rslbp"
version = "0.1.0"
edition = "2024"
# 1.93, not the template's 1.96 floor: this fixture runs on 1.93.0, and the
# MSRV-aware resolver then picks dependency versions that toolchain can build.
rust-version = "1.93"
license = "MIT OR Apache-2.0"
publish = false

[features]
web = ["dep:axum", "dep:tokio"]

[dependencies]
rslbp-core = { path = "crates/core" }
axum = { version = "=0.8.9", optional = true }
tokio = { version = "=1.53.1", optional = true, features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }

[dev-dependencies]
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "macros", "sync", "net"] }
tower = { version = "=0.5.3", features = ["util"] }

[[bin]]
name = "rslbp"
path = "src/main.rs"

[[bin]]
name = "rslbp-serve"
path = "src/bin/rslbp-serve.rs"
required-features = ["web"]
EOF
cat >"$fx/crates/core/Cargo.toml" <<'EOF'
[package]
name = "rslbp-core"
version = "0.1.0"
edition = "2024"
rust-version = "1.93"
license = "MIT OR Apache-2.0"
publish = false
EOF
cat >"$fx/crates/core/src/lib.rs" <<'EOF'
//! Core library of the R35 coverage fixture.

/// Returns a greeting.
///
/// ```
/// assert_eq!(rslbp_core::greet("ada"), "hello, ada");
/// ```
pub fn greet(name: &str) -> String {
    format!("hello, {name}")
}

/// Parses a repeat count between 1 and 10.
pub fn parse_count(raw: &str) -> Result<u32, String> {
    let n: u32 = raw.trim().parse().map_err(|_| format!("not a number: {raw}"))?;
    if (1..=10).contains(&n) {
        Ok(n)
    } else {
        Err(format!("out of range: {n}"))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn greets() {
        assert_eq!(greet("x"), "hello, x");
    }

    #[test]
    fn parses() {
        assert_eq!(parse_count(" 3 "), Ok(3));
    }

    #[test]
    fn rejects_text() {
        assert!(parse_count("x").is_err());
    }

    #[test]
    fn rejects_out_of_range() {
        assert!(parse_count("11").is_err());
    }
}
EOF
cat >"$fx/src/lib.rs" <<'EOF'
//! Facade of the R35 coverage fixture. `run` is exercised only through the
//! CLI subprocess tests, so its coverage proves the binary is instrumented.
pub use rslbp_core::{greet, parse_count};

#[cfg(feature = "web")]
pub mod web;

/// Runs the CLI over `args` (program name removed); returns (exit code, text).
pub fn run(args: &[String]) -> (u8, String) {
    match args {
        [name] => (0, greet(name)),
        [name, count] => match parse_count(count) {
            Ok(n) => (0, vec![greet(name); n as usize].join("\n")),
            Err(e) => (2, e),
        },
        _ => (2, "usage: rslbp NAME [COUNT]".to_string()),
    }
}
EOF
cat >"$fx/src/main.rs" <<'EOF'
use std::process::ExitCode;

fn main() -> ExitCode {
    let args: Vec<String> = std::env::args().skip(1).collect();
    let (code, text) = rslbp::run(&args);
    if code == 0 {
        println!("{text}");
    } else {
        eprintln!("{text}");
    }
    ExitCode::from(code)
}
EOF
cat >"$fx/src/web.rs" <<'EOF'
//! Web surface, compiled only with the `web` feature.
use axum::{Router, extract::Path, routing::get};

/// Builds the service router.
pub fn build_router() -> Router {
    Router::new()
        .route("/health", get(health))
        .route("/greet/{name}", get(greet_handler))
}

async fn health() -> &'static str {
    "ok"
}

async fn greet_handler(Path(name): Path<String>) -> String {
    crate::greet(&name)
}

/// Serves the router on `listener` until `shutdown` resolves.
pub async fn serve_until(
    listener: tokio::net::TcpListener,
    shutdown: impl std::future::Future<Output = ()> + Send + 'static,
) -> std::io::Result<()> {
    axum::serve(listener, build_router())
        .with_graceful_shutdown(shutdown)
        .await
}
EOF
cat >"$fx/src/bin/rslbp-serve.rs" <<'EOF'
use std::process::ExitCode;

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("--version") {
        println!("rslbp-serve {}", env!("CARGO_PKG_VERSION"));
        return ExitCode::SUCCESS;
    }
    let runtime = tokio::runtime::Runtime::new().expect("tokio runtime");
    let served = runtime.block_on(async {
        let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await?;
        // Registered before readiness is announced, so no SIGINT is lost.
        let mut interrupt =
            tokio::signal::unix::signal(tokio::signal::unix::SignalKind::interrupt())?;
        println!("listening on {}", listener.local_addr()?);
        rslbp::web::serve_until(listener, async move {
            interrupt.recv().await;
        })
        .await
    });
    if served.is_ok() { ExitCode::SUCCESS } else { ExitCode::FAILURE }
}
EOF
cat >"$fx/tests/cli.rs" <<'EOF'
use std::process::{Command, Output};

fn rslbp(args: &[&str]) -> Output {
    Command::new(env!("CARGO_BIN_EXE_rslbp")).args(args).output().expect("spawn rslbp")
}

#[test]
fn greets_once() {
    let out = rslbp(&["ada"]);
    assert!(out.status.success());
    assert_eq!(String::from_utf8_lossy(&out.stdout), "hello, ada\n");
}

#[test]
fn greets_twice() {
    let out = rslbp(&["ada", "2"]);
    assert_eq!(String::from_utf8_lossy(&out.stdout), "hello, ada\nhello, ada\n");
}

#[test]
fn rejects_bad_count() {
    assert_eq!(rslbp(&["ada", "x"]).status.code(), Some(2));
}

#[test]
fn prints_usage() {
    assert_eq!(rslbp(&[]).status.code(), Some(2));
}
EOF
cat >"$fx/tests/web.rs" <<'EOF'
#![cfg(feature = "web")]
use axum::{
    body::Body,
    http::{Request, StatusCode},
};
use tower::ServiceExt;

async fn get(uri: &str) -> (StatusCode, String) {
    let request = Request::get(uri).body(Body::empty()).unwrap();
    let response = rslbp::web::build_router().oneshot(request).await.unwrap();
    let status = response.status();
    let body = axum::body::to_bytes(response.into_body(), 1024).await.unwrap();
    (status, String::from_utf8(body.to_vec()).unwrap())
}

#[tokio::test]
async fn health() {
    assert_eq!(get("/health").await, (StatusCode::OK, "ok".to_string()));
}

#[tokio::test]
async fn greets() {
    assert_eq!(get("/greet/ada").await, (StatusCode::OK, "hello, ada".to_string()));
}

#[tokio::test]
async fn serves_until_shutdown() {
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    let (stop, stopped) = tokio::sync::oneshot::channel::<()>();
    let server = tokio::spawn(rslbp::web::serve_until(listener, async {
        let _ = stopped.await;
    }));
    stop.send(()).unwrap();
    server.await.unwrap().unwrap();
}

#[test]
fn serve_binary_reports_version() {
    let out = std::process::Command::new(env!("CARGO_BIN_EXE_rslbp-serve"))
        .arg("--version")
        .output()
        .unwrap();
    assert!(out.status.success());
}
EOF
cat >"$fx/tests/serve_signal.rs" <<'EOF'
#![cfg(feature = "web")]
use std::io::{BufRead, BufReader};
use std::process::{Command, Stdio};

#[test]
fn serve_binary_drains_on_sigint() {
    let mut child = Command::new(env!("CARGO_BIN_EXE_rslbp-serve"))
        .stdout(Stdio::piped())
        .spawn()
        .expect("spawn rslbp-serve");
    let mut line = String::new();
    BufReader::new(child.stdout.take().unwrap()).read_line(&mut line).unwrap();
    assert!(line.starts_with("listening on "), "{line}");
    let pid = child.id().to_string();
    assert!(Command::new("kill").args(["-INT", &pid]).status().unwrap().success());
    assert!(child.wait().unwrap().success());
}
EOF
# The recipe under test, as recommended in the DECISION.
cat >"$fx/Justfile" <<'EOF'
# Coverage floors (LLVM metrics). The ONLY place the threshold values live.
coverage_fail_under := "--fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90"

# Uninstrumented inner loop (R32 owns the real one).
test:
    cargo test --locked --workspace --all-features

# One instrumented run, three reports, gate last so reports exist when it fails.
coverage:
    cargo llvm-cov clean --workspace
    cargo llvm-cov --no-report --locked --workspace --all-features
    cargo llvm-cov report --workspace --html
    cargo llvm-cov report --workspace --lcov --output-path target/llvm-cov/lcov.info
    cargo llvm-cov report --workspace --show-missing-lines {{coverage_fail_under}}
EOF
printf 'target/\n' >"$fx/.gitignore"
cd "$fx"
fxr="$(pwd -P)"   # macOS: /var/folders is /private/var/folders in LLVM's paths
info "fixture at $fx (removed on exit); files: $(find . -type f -not -path './target/*' | sort | tr '\n' ' ')"

if cargo generate-lockfile >"$fx/../lock.log" 2>&1; then
  ok C1 "cargo generate-lockfile resolved the fixture (axum/tokio/tower from crates.io)"
else
  tail -20 "$fx/../lock.log"; bad C1 "lockfile generation failed"
fi
info "resolved: $(/usr/bin/grep -A1 -E '^name = "(axum|tokio|tower)"$' Cargo.lock | /usr/bin/grep -E '^(name|version)' | paste - - | tr '\n' ';')"

# ---------------------------------------------------------------- inner loop (AC5)
t0=$(date +%s)
if just test >"$fx/../test.log" 2>&1; then
  ok C2a "just test (uninstrumented cargo test --locked --workspace --all-features) exits 0 in $(( $(date +%s) - t0 ))s cold"
else
  tail -30 "$fx/../test.log"; bad C2a "just test failed"
fi
/usr/bin/grep -E '^test result:' "$fx/../test.log" | sed 's/^/INFO just test: /'
check C2b "inner loop leaves no instrumented tree (target/llvm-cov-target absent)" test ! -e target/llvm-cov-target

# ---------------------------------------------------------------- positive run (AC1, AC3)
touch "$fx/../marker"; sleep 1
t0=$(date +%s)
if just coverage >"$fx/../cov.log" 2>&1; then
  ok C3a "just coverage exits 0 on the fixture in $(( $(date +%s) - t0 ))s (instrumented build cold, same host)"
else
  tail -40 "$fx/../cov.log"; bad C3a "just coverage failed on the intact fixture"
fi
sed -n '/^Filename/,$p' "$fx/../cov.log" | sed 's/^/INFO report: /'
check C3b "terminal report carries Regions, Functions and Lines columns and a TOTAL row" \
  /usr/bin/grep -q '^TOTAL' "$fx/../cov.log"
check C3d "HTML report at target/llvm-cov/html/index.html" test -s target/llvm-cov/html/index.html
check C3e "LCOV report at target/llvm-cov/lcov.info" test -s target/llvm-cov/lcov.info
check C3f "instrumented build isolated in target/llvm-cov-target" test -d target/llvm-cov-target
check C3g "no report file written outside target/ (nothing new for .gitignore)" \
  test -z "$(find . -path ./target -prune -o -newer "$fx/../marker" -type f -print)"
summary() { cargo llvm-cov report --workspace --json --summary-only 2>/dev/null | jq -r '.data[0].totals | "lines=\(.lines.percent) functions=\(.functions.percent) regions=\(.regions.percent)"'; }
base="$(summary)"; info "intact fixture totals: $base"

# ---------------------------------------------------------------- scope (AC3, F135)
lcov=target/llvm-cov/lcov.info
/usr/bin/grep '^SF:' "$lcov" | sed "s|$fxr/||; s/^/INFO lcov /"
check C4a "every SF: record is a src/ file of the root package or a member" \
  test -z "$(/usr/bin/grep '^SF:' "$lcov" | sed 's/^SF://' | /usr/bin/grep -v -E "^$fxr/(src|crates/core/src)/" || true)"
check C4b "no tests/, registry or toolchain path is counted" \
  test -z "$(/usr/bin/grep -E '^SF:.*(/tests/|/registry/|/rustlib/|/\.cargo/)' "$lcov" || true)"
check C4c "the web module and serve binary are measured (feature web on)" \
  bash -c "/usr/bin/grep -q '^SF:.*/src/web.rs$' '$lcov' && /usr/bin/grep -q '^SF:.*/src/bin/rslbp-serve.rs$' '$lcov'"
check C4d "the workspace member crates/core is measured when report carries --workspace" \
  /usr/bin/grep -q '^SF:.*/crates/core/src/lib.rs$' "$lcov"
nows="$(cargo llvm-cov report --summary-only 2>&1)"
/usr/bin/grep -E '^(TOTAL|.*lib\.rs)' <<<"$nows" | sed 's/^/INFO report without --workspace: /'
drops_member() { ! /usr/bin/grep -q 'crates/core' <<<"$nows"; }
check C4e "WITHOUT --workspace, report silently drops the member (the defect in raw/opus.md:138-140)" drops_member

# ---------------------------------------------------------------- subprocess tier (F135, V4)
hits() { local lcov="${lcov:?}"; awk -v p="$fxr/$1" '$0 == "SF:" p {on=1; next} /^end_of_record/ {on=0} on && /^DA:/ {split(substr($0,4),a,","); if (a[2]>0) h++; else m++} END {printf "%d %d", h+0, m+0}' "$lcov"; }
read -r mh mm <<<"$(hits 'src/main.rs')"; info "src/main.rs executed_lines=$mh unexecuted_lines=$mm"
check C5a "src/main.rs is covered by the CARGO_BIN_EXE_rslbp subprocess tests (no exclusion needed)" test "$mh" -gt 0 -a "$mm" -eq 0
read -r lh lm <<<"$(hits 'src/lib.rs')"; info "src/lib.rs (run, reached only via subprocess) executed_lines=$lh unexecuted_lines=$lm"
check C5b "lib code reached only through the spawned binary is counted" test "$lh" -gt 0
read -r sh sm <<<"$(hits 'src/bin/rslbp-serve.rs')"; info "src/bin/rslbp-serve.rs executed_lines=$sh unexecuted_lines=$sm"
check C5c "with the SIGINT subprocess test, the serve binary's bind/serve/drain path is counted too" test "$sh" -gt 0 -a "$sm" -eq 0

# ---------------------------------------------------------------- gate negative control (AC2, V2)
cp crates/core/src/lib.rs "$fx/../lib.rs.orig"
cat >>crates/core/src/lib.rs <<'EOF'

/// Untested on purpose: the gate's negative control.
pub fn classify(n: i64) -> &'static str {
    if n < -1000 {
        "very negative"
    } else if n < -100 {
        "negative hundreds"
    } else if n < -10 {
        "negative tens"
    } else if n < 0 {
        "negative"
    } else if n == 0 {
        "zero"
    } else if n < 10 {
        "small"
    } else if n < 100 {
        "tens"
    } else if n < 1000 {
        "hundreds"
    } else if n < 10_000 {
        "thousands"
    } else if n < 100_000 {
        "ten-thousands"
    } else {
        "large"
    }
}
EOF
touch -t 200001010000 target/llvm-cov/lcov.info target/llvm-cov/html/index.html
set +e; just coverage >"$fx/../neg.log" 2>&1; neg=$?; set -e
info "negative-control totals: $(summary); just coverage exit=$neg"
/usr/bin/grep -E '^TOTAL|fail|error' "$fx/../neg.log" | tail -5 | sed 's/^/INFO neg: /'
check C6a "an untested 25-line function drops coverage below the floor and just coverage exits non-zero" test "$neg" -ne 0
/usr/bin/grep -A2 'Uncovered Lines:' "$fx/../neg.log" | sed 's/^/INFO neg: /'
check C6d "--show-missing-lines lists the uncovered lines of the untested function" \
  /usr/bin/grep -q 'crates/core/src/lib.rs: ' "$fx/../neg.log"
check C6b "the failure comes from the gate line (reports were regenerated before it)" \
  bash -c "[ target/llvm-cov/lcov.info -nt '$fx/../lib.rs.orig' ] && [ target/llvm-cov/html/index.html -nt '$fx/../lib.rs.orig' ]"
cp "$fx/../lib.rs.orig" crates/core/src/lib.rs
if just coverage >"$fx/../rev.log" 2>&1; then ok C6c "reverting the function restores a passing run"; else bad C6c "revert did not restore a pass"; fi

# ---------------------------------------------------------------- functions metric (Opus raw :114)
cat >>crates/core/src/lib.rs <<'EOF'

/// Public generic API that no test instantiates.
pub fn describe<T: std::fmt::Debug>(value: T) -> String {
    format!("{value:?}")
}
EOF
cargo llvm-cov clean --workspace >/dev/null 2>&1
cargo llvm-cov --no-report --locked --workspace --all-features >"$fx/../gen.log" 2>&1
gen="$(summary)"; info "with one uninstantiated public generic: $gen (intact: $base)"
cargo llvm-cov report --workspace --lcov --output-path "$fx/../gen.info" >/dev/null 2>&1
{ /usr/bin/grep -E '^FN(DA)?:.*describe' "$fx/../gen.info" || true; } | sed 's/^/INFO gen lcov: /'
check C7a "the uninstantiated generic is recorded as a function with zero executions" \
  /usr/bin/grep -q -E '^FNDA:0,.*describe' "$fx/../gen.info"
fb="${base#*functions=}"; fb="${fb%% *}"; fg="${gen#*functions=}"; fg="${fg%% *}"
check C7b "one unused public generic lowers the functions percentage ($fb -> $fg)" \
  awk -v a="$fb" -v b="$fg" 'BEGIN{exit !(b < a)}'
cp "$fx/../lib.rs.orig" crates/core/src/lib.rs

# ---------------------------------------------------------------- thin entry file without a signal test (F135)
mv tests/serve_signal.rs "$fx/../serve_signal.rs"
cargo llvm-cov clean --workspace >/dev/null 2>&1
cargo llvm-cov --no-report --locked --workspace --all-features >"$fx/../thin.log" 2>&1
thin="$(summary)"; info "without the SIGINT test: $thin (with it: $base)"
cargo llvm-cov report --workspace --lcov --output-path "$fx/../thin.info" >/dev/null 2>&1
read -r th tm <<<"$(lcov="$fx/../thin.info" hits 'src/bin/rslbp-serve.rs')"
info "without the SIGINT test src/bin/rslbp-serve.rs executed_lines=$th unexecuted_lines=$tm"
check C8a "without a signal-driven test, the serve binary's entry path is unexecuted" test "$tm" -gt 0
set +e; cargo llvm-cov report --workspace --fail-under-lines 95 --fail-under-functions 95 --fail-under-regions 90 >/dev/null 2>&1; g95=$?
cargo llvm-cov report --workspace --fail-under-lines 80 >/dev/null 2>&1; g80=$?; set -e
info "without the SIGINT test: 95/95/90 gate exit=$g95; lines-80 gate exit=$g80"
check C8b "without it, the recommended 95/95/90 floor fails the run" test "$g95" -ne 0
check C8c "without it, the runner-up lines-80 floor still passes (it cannot see the untested entry path)" test "$g80" -eq 0
mv "$fx/../serve_signal.rs" tests/serve_signal.rs

echo "SUMMARY PASS=$pass FAIL=$fail"
[ "$fail" -eq 0 ]
