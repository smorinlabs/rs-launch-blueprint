#!/usr/bin/env bash
# R78 synthesis evidence 2 of 3 — census of the PUBLISHED crate sources at the exact
# recommended versions, settling the source-level claims the four engine reports
# disagree on. Opus read GitHub `main`; this reads the crates.io tarballs.
#
# Method: write a throwaway manifest pinning the exact versions under $TMPDIR, run
# `cargo fetch` (crates.io, into the private $CARGO_HOME), then grep the extracted
# sources by absolute path with /usr/bin/grep. Nothing is written into the repository.
#
# Usage: bash r78-source-census.sh > r78-source-census.log 2>&1
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

count() { # count <grep args...> -> number of matching lines (0 when none)
  local n
  n=$("$GREP" "$@" 2>/dev/null | wc -l | tr -d ' ')
  echo "${n:-0}"
}

show() { # show <label> <grep args...> -> print every matching line, labelled
  echo "  [$1]"
  "$GREP" "${@:2}" 2>/dev/null | cut -c1-220 | sed 's/^/    /'
}

WORK=$(mktemp -d "${TMPDIR:-/tmp}/r78-census.XXXXXX")
trap 'rm -rf "$WORK"' EXIT
mkdir -p "$WORK/src"
echo 'fn main() {}' > "$WORK/src/main.rs"
cat > "$WORK/Cargo.toml" <<'EOF'
[package]
name = "r78-census"
version = "0.0.0"
edition = "2024"
publish = false

[dependencies]
opentelemetry = "=0.33.0"
opentelemetry_sdk = "=0.33.0"
opentelemetry-otlp = "=0.33.0"
opentelemetry-http = "=0.33.0"
tracing-opentelemetry = "=0.34.0"
tracing-subscriber = "=0.3.23"
EOF

echo "# r78-source-census — run $(date -u +%Y-%m-%dT%H:%M:%SZ) (UTC)"
echo "# host: $(uname -srm); $(cargo -V); CARGO_HOME=${CARGO_HOME:-unset}"
( cd "$WORK" && cargo fetch --quiet ) || { echo "cargo fetch failed"; exit 99; }
REG=$(find "${CARGO_HOME:-$HOME/.cargo}/registry/src" -mindepth 1 -maxdepth 1 -type d -name 'index.crates.io-*' | head -n 1)
API="$REG/opentelemetry-0.33.0"
SDK="$REG/opentelemetry_sdk-0.33.0"
OTLP="$REG/opentelemetry-otlp-0.33.0"
HTTP="$REG/opentelemetry-http-0.33.0"
BR="$REG/tracing-opentelemetry-0.34.0"
TS="$REG/tracing-subscriber-0.3.23"
echo "# registry source root: $REG"
for d in "$API" "$SDK" "$OTLP" "$HTTP" "$BR" "$TS"; do
  check "X00-$(basename "$d")" "extracted source present" test -f "$d/Cargo.toml"
done
echo

echo "## 1. Unconfigured endpoint: what an otel build does with no OTEL_EXPORTER_OTLP_* set"
show "HTTP default endpoint constant" -n 'OTEL_EXPORTER_OTLP_HTTP_ENDPOINT_DEFAULT: &str' "$OTLP/src/exporter/mod.rs"
check S01 "otlp 0.33.0 defaults the HTTP endpoint to http://localhost:4318" \
  test "$(count -n 'OTEL_EXPORTER_OTLP_HTTP_ENDPOINT_DEFAULT: &str = "http://localhost:4318"' "$OTLP/src/exporter/mod.rs")" -eq 1
show "lib.rs:222 is the env-var table row, not the default" -n 'OTEL_EXPORTER_OTLP_ENDPOINT` | Target URL' "$OTLP/src/lib.rs"
show "0.33.0 CHANGELOG: invalid endpoint env var becomes a build error" -n 'Return an exporter build error for invalid OTLP/HTTP endpoint' "$OTLP/CHANGELOG.md"
check S02 "0.33.0 CHANGELOG records invalid OTLP/HTTP endpoint env vars as a build error" \
  test "$(sed -n '/^## 0.33.0/,/^## 0.32.0/p' "$OTLP/CHANGELOG.md" | "$GREP" -c 'Return an exporter build error for invalid OTLP/HTTP endpoint')" -eq 1
echo

echo "## 2. OTEL_SDK_DISABLED (standard kill switch) — honoured by any crate in the set?"
for d in "$API" "$SDK" "$OTLP" "$HTTP" "$BR"; do
  printf '  %-40s %s matches\n' "$(basename "$d")" "$(count -rn 'OTEL_SDK_DISABLED' "$d")"
done
check S03 "no crate in the recommended set reads OTEL_SDK_DISABLED" \
  test "$(count -rn 'OTEL_SDK_DISABLED' "$API" "$SDK" "$OTLP" "$HTTP" "$BR")" -eq 0
echo

echo "## 3. Retries in 0.33 (Opus: on by default; Doxa-OpenAI: experimental features, off)"
show "0.33.0 CHANGELOG retry section" -n 'Retries are now enabled by default\|remove those feature flags' "$OTLP/CHANGELOG.md"
show "RetryPolicy::recommended()" -n -A6 'pub fn recommended() -> Self' "$OTLP/src/retry_policy.rs"
check S04 "0.33.0 enables OTLP retries by default (CHANGELOG 0.33.0 section)" \
  test "$(sed -n '/^## 0.33.0/,/^## 0.32.0/p' "$OTLP/CHANGELOG.md" | "$GREP" -c 'Retries are now enabled by default for OTLP/HTTP')" -eq 1
check S05 "otlp 0.33.0 Cargo.toml declares no experimental retry feature" \
  test "$(count -n 'experimental-http-retry\|experimental-grpc-retry' "$OTLP/Cargo.toml")" -eq 0
echo

echo "## 4. global::shutdown_tracer_provider (Gemini's shutdown call) — present in 0.33.0?"
check S06 "no 'fn shutdown_tracer_provider' in opentelemetry 0.33.0 src" \
  test "$(count -rn 'fn shutdown_tracer_provider' "$API/src")" -eq 0
show "CHANGELOG removal note" -n 'shutdown_tracer_provider()` Removed' "$API/CHANGELOG.md"
echo

echo "## 5. Batch span processor: OS thread or Tokio? bounds and shutdown"
SP="$SDK/src/trace/span_processor.rs"
show "batch processor worker" -n 'let handle = thread::Builder::new()' "$SP"
check S07 "BatchSpanProcessor spawns an OS thread (thread::Builder) in 0.33.0" \
  test "$(count -n 'thread::Builder::new()' "$SP")" -ge 1
show "defaults" -n 'pub const OTEL_BSP_MAX_QUEUE_SIZE_DEFAULT\|pub const OTEL_BSP_EXPORT_TIMEOUT_DEFAULT\|pub const OTEL_BSP_SCHEDULE_DELAY_DEFAULT' "$SP"
check S08 "queue bound default is 2_048 spans" test "$(count -n 'pub const OTEL_BSP_MAX_QUEUE_SIZE_DEFAULT: usize = 2_048;' "$SP")" -eq 1
check S09 "export timeout default is 30_000 ms" test "$(count -n 'pub const OTEL_BSP_EXPORT_TIMEOUT_DEFAULT: Duration = Duration::from_millis(30_000);' "$SP")" -eq 1
check S10 "OTEL_BSP_SCHEDULE_DELAY is read from the environment" test "$(count -n 'env::var(OTEL_BSP_SCHEDULE_DELAY)' "$SP")" -ge 1
show "current-thread deadlock warning" -n -A3 'When using tokio.s current-thread runtime' "$SP"
check S11 "SDK documents shutdown() deadlock risk on a current-thread runtime" \
  test "$(count -n "current-thread runtime, \`shutdown()\`" "$SP")" -ge 1
show "provider lifecycle" -n 'pub fn shutdown_with_timeout\|pub fn force_flush\|pub fn shutdown(&self)' "$SDK/src/trace/provider.rs"
check S12 "SdkTracerProvider::shutdown_with_timeout(Duration) exists" \
  test "$(count -n 'pub fn shutdown_with_timeout(&self, timeout: Duration)' "$SDK/src/trace/provider.rs")" -eq 1
echo

echo "## 6. Blocking HTTP client construction off the async runtime"
show "exporter/http/mod.rs" -n 'std::thread::Builder::new()' "$OTLP/src/exporter/http/mod.rs"
check S13 "OTLP/HTTP builds its blocking client on a separately spawned OS thread" \
  test "$(count -n 'std::thread::Builder::new()' "$OTLP/src/exporter/http/mod.rs")" -ge 1
echo

echo "## 7. Propagation default and composition hooks"
show "global propagator default" -n 'GLOBAL_TEXT_MAP_PROPAGATOR.get_or_init' "$API/src/global/propagation.rs"
check S14 "the global text-map propagator defaults to NoopTextMapPropagator" \
  test "$(count -n 'NoopTextMapPropagator::new()' "$API/src/global/propagation.rs")" -ge 1
show "Option<L> is a Layer" -n 'impl<L, S> Layer<S> for Option<L>' "$TS/src/layer/mod.rs"
check S15 "tracing-subscriber 0.3.23 implements Layer<S> for Option<L>" \
  test "$(count -n 'impl<L, S> Layer<S> for Option<L>' "$TS/src/layer/mod.rs")" -eq 1
show "set_parent / context" -n 'fn set_parent(&self, cx: Context)\|fn context(&self) -> Context' "$BR/src/span_ext.rs"
check S16 "bridge 0.34.0 set_parent returns Result<(), SetParentError>" \
  test "$(count -n 'fn set_parent(&self, cx: Context) -> Result<(), SetParentError>;' "$BR/src/span_ext.rs")" -eq 1
show "HeaderExtractor / HeaderInjector" -n 'pub struct HeaderExtractor\|pub struct HeaderInjector' "$HTTP/src/lib.rs"
check S17 "opentelemetry-http 0.33.0 exports HeaderExtractor and HeaderInjector" \
  test "$(count -n 'pub struct HeaderExtractor\|pub struct HeaderInjector' "$HTTP/src/lib.rs")" -eq 2
echo

echo "## 8. unsafe census of each crate's src/ (word match)"
for d in "$API" "$SDK" "$OTLP" "$HTTP" "$BR"; do
  printf '  %-40s %s lines\n' "$(basename "$d")" "$(count -rnw 'unsafe' "$d/src")"
done
show "tracing-opentelemetry 0.34.0 unsafe lines" -rnw 'unsafe' "$BR/src"
check S18 "API/SDK/OTLP/HTTP 0.33.0 src contain no unsafe" \
  test "$(count -rnw 'unsafe' "$API/src" "$SDK/src" "$OTLP/src" "$HTTP/src")" -eq 0
check S19 "bridge 0.34.0 src has exactly 3 unsafe lines (2 downcast_raw fns + 1 block)" \
  test "$(count -rnw 'unsafe' "$BR/src")" -eq 3
echo

echo "## 9. Feature tables in the published manifests"
show "otlp [features] default/http-proto/reqwest-*" -n '^default = \|^http-proto = \|^reqwest-blocking-client = \|^reqwest-rustls = \|^grpc-tonic = ' "$OTLP/Cargo.toml"
show "bridge [features]" -n '^default = \|^metrics = \|^tracing-log = ' "$BR/Cargo.toml"
check S20 "otlp reqwest dependency declared with default-features = false (TLS is opt-in)" \
  test "$(awk '/^\[dependencies.reqwest\]/{f=1;next} /^\[/{f=0} f' "$OTLP/Cargo.toml" | "$GREP" -c 'default-features = false')" -eq 1
echo

echo "# TOTAL checks=$N pass=$PASS fail=$FAIL"
exit "$FAIL"
