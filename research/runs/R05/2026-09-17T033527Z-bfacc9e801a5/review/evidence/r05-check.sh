#!/usr/bin/env bash
# R05 sync-async-execution-model — evidence checks for review/DECISION.md (revision 1).
#
# What this script proves, and what it does not.
#   It verifies the facts the R05 decision rests on: the repository rows and
#   published values it cites, the two mechanical Cargo/rustc facts that decide
#   the recommendation, the dependency-tree cost of each execution model, one
#   real HTTPS round trip through the recommended client both directly and
#   through the web-adapter bridge, and the registry/GitHub/RustSec figures it
#   quotes. It builds nothing that the decision recommends: every Rust artefact
#   it creates is a throwaway probe under a mktemp directory inside $TMPDIR,
#   deleted when the script exits. No template code exists and none is written.
#
# Reproducibility of the committed log (r05-check.log).
#   Every line is byte-stable on rerun EXCEPT the three named here:
#     * "retrieved-on:" — prints today's UTC date, so it advances daily;
#     * C00's "HEAD =" — the repository commit the content checks read, which
#       advances with every commit to this branch;
#     * C13's two "seconds=" figures — wall-clock compile times, which depend on
#       the machine, its cache state and its load. C13 asserts only the ordering
#       (sync build strictly faster), never the numbers.
#   Everything else is pinned: the two probe Cargo.lock files are committed
#   beside this script and reused with --locked, the GitHub read is at an
#   immutable tag, and the crates.io reads assert an exact version that only a
#   new release can change (which is a re-verify trigger, recorded as such).
#
# Rerunning from a clean `git archive HEAD` extraction.
#   Supported. C00 is the only check that needs .git (a directory in a clone, a
#   file in a worktree); without it C00 reports
#   SKIP by name and the run still exits 0 when every other check passes.
#
# Requirements: bash, cargo/rustc (1.96 or newer), curl, python3, gh
# (authenticated; this script never prints a token or any environment).
# Network access is required for C10-C17.

set -o pipefail
set -u

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
RUN_DIR="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"
ROOT="$(cd -- "${SCRIPT_DIR}/../../../../../.." && pwd)"
GREP=/usr/bin/grep
UA="rs-launch-blueprint-research/R05 (rs-launch-blueprint P02, no contact address)"

PASSED=0
FAILED=0
SKIPPED=0

pass() { PASSED=$((PASSED + 1)); printf 'PASS %s — %s\n' "$1" "$2"; }
fail() { FAILED=$((FAILED + 1)); printf 'FAIL %s — %s\n' "$1" "$2"; }
skip() { SKIPPED=$((SKIPPED + 1)); printf 'SKIP %s — %s\n' "$1" "$2"; }
note() { printf '     %s\n' "$1"; }

WORK="$(mktemp -d "${TMPDIR:-/tmp}/r05-check.XXXXXX")" || { echo "cannot create work dir"; exit 2; }
# shellcheck disable=SC2329  # invoked indirectly by the EXIT trap below
cleanup() { rm -rf "$WORK"; }
trap cleanup EXIT

printf '== R05 sync-async-execution-model — evidence checks ==\n'
printf 'repository root: %s\n' "$ROOT"
printf 'run directory:   %s\n' "$RUN_DIR"
printf 'toolchain:       %s\n' "$(rustc --version)"
printf 'cargo:           %s\n' "$(cargo --version)"
printf 'host:            %s %s %s\n' "$(uname -s)" "$(uname -r)" "$(uname -m)"
printf 'retrieved-on:    %s (UTC; the one line that advances on rerun)\n' "$(date -u +%Y-%m-%d)"
printf 'grep binary:     %s\n' "$GREP"
printf '\n'

# ---------------------------------------------------------------------------
# C00 — provenance of the tree the repository assertions read.
# ---------------------------------------------------------------------------
if [ -e "${ROOT}/.git" ]; then   # a directory in a normal clone, a file in a git worktree
  HEAD_SHA="$(git -C "$ROOT" rev-parse HEAD)"
  rc=$?
  if [ "$rc" -eq 0 ] && [ -n "$HEAD_SHA" ]; then
    pass C00 "repository HEAD resolved"
    note "HEAD = ${HEAD_SHA}"
  else
    fail C00 "git rev-parse HEAD failed (exit ${rc})"
  fi
else
  skip C00 "no .git entry (git archive extraction); repository-content checks C01-C06 still run"
fi

# ---------------------------------------------------------------------------
# C01 — the ledger rows this decision settles.
# ---------------------------------------------------------------------------
LEDGER="${ROOT}/docs/port/COMMONALITY.md"
f016="$($GREP -c '^| F016 | Sync/async execution model for the I/O boundary | workspace-architecture | different | DIVERGENT | R05 | bundle; decides F022 |$' "$LEDGER")"
f022="$($GREP -c '^| F022 | Async runtime selection for the async I/O boundary | workspace-architecture | none | RUST-ONLY | R05 | bundle; moot if F016 resolves sync |$' "$LEDGER")"
if [ "$f016" = "1" ] && [ "$f022" = "1" ]; then
  pass C01 "COMMONALITY.md carries F016 and F022 verbatim as cited"
  note "${GREP} exact-line matches: F016=${f016}, F022=${f022} in docs/port/COMMONALITY.md"
else
  fail C01 "expected exactly one exact-line match each; got F016=${f016}, F022=${f022}"
fi

# ---------------------------------------------------------------------------
# C02 — R69's published web-extra-surface value, which this decision must not break.
# ---------------------------------------------------------------------------
REGISTRY="${ROOT}/docs/port/PARAMETERS.md"
python3 - "$REGISTRY" > "${WORK}/web-extra-surface.txt" <<'PY'
import sys
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("| web-extra-surface |"):
        sys.stdout.write(line.split(" | ")[3])
        break
PY
rc=$?
dep_clause="$($GREP -c 'web = \["dep:axum", "dep:tokio"\]' "${WORK}/web-extra-surface.txt")"
tokio_opt="$($GREP -c 'tokio 1\.53\.1 optional with features rt-multi-thread, net, signal, macros, time, sync' "${WORK}/web-extra-surface.txt")"
axum_opt="$($GREP -c 'axum 0\.8\.9 optional' "${WORK}/web-extra-surface.txt")"
if [ "$rc" -eq 0 ] && [ "$dep_clause" = "1" ] && [ "$tokio_opt" = "1" ] && [ "$axum_opt" = "1" ]; then
  pass C02 "registry web-extra-surface (R69) declares dep:tokio, optional tokio 1.53.1 and optional axum 0.8.9"
  note "${GREP} matches in the extracted cell: dep-clause=${dep_clause}, optional-tokio=${tokio_opt}, optional-axum=${axum_opt}"
else
  fail C02 "extraction rc=${rc}; dep-clause=${dep_clause}, optional-tokio=${tokio_opt}, optional-axum=${axum_opt}"
fi

# ---------------------------------------------------------------------------
# C03 — R01's published port shape, which this decision must not break.
# ---------------------------------------------------------------------------
python3 - "$REGISTRY" > "${WORK}/seam.txt" <<'PY'
import sys
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("| http-transport-injection-seam |"):
        sys.stdout.write(line.split(" | ")[3])
        break
PY
rc=$?
no_async="$($GREP -c 'no async fn, generic methods, associated consts or non-receiver Self' "${WORK}/seam.txt")"
async_clause="$($GREP -c 'under an async R05 the trait keeps dyn compatibility with async-trait 0\.1\.92' "${WORK}/seam.txt")"
if [ "$rc" -eq 0 ] && [ "$no_async" = "1" ] && [ "$async_clause" = "1" ]; then
  pass C03 "registry http-transport-injection-seam (R01) forbids async fn on the port and makes async-trait conditional on R05"
  note "${GREP} matches in the extracted cell: no-async-fn=${no_async}, conditional-async-trait=${async_clause}"
else
  fail C03 "extraction rc=${rc}; no-async-fn=${no_async}, conditional-async-trait=${async_clause}"
fi

# ---------------------------------------------------------------------------
# C04 — R69 hands this question to R05 in its own words.
# ---------------------------------------------------------------------------
R69="${ROOT}/research/topics/69-web-framework-stack/DECISION.md"
hits="$($GREP -c "Whether the CLI and library join that world is R05's open question" "$R69")"
if [ "$hits" -ge 1 ]; then
  pass C04 "R69 DECISION.md hands the CLI/library runtime question to R05"
  note "${GREP} matches in research/topics/69-web-framework-stack/DECISION.md: ${hits}"
else
  fail C04 "expected at least one match, got ${hits}"
fi

# ---------------------------------------------------------------------------
# C05 — this item's prompt registers no owned and no consumed parameter.
# ---------------------------------------------------------------------------
PROMPT="${RUN_DIR}/inputs/prompt.md"
owns="$($GREP -c '^- owns:$' "$PROMPT")"
consumes="$($GREP -c '^- consumes:$' "$PROMPT")"
if [ "$owns" = "1" ] && [ "$consumes" = "1" ]; then
  pass C05 "prompt Couplings carry an empty owns: line and an empty consumes: line"
  note "${GREP} exact-line matches in inputs/prompt.md: '- owns:'=${owns}, '- consumes:'=${consumes}"
else
  fail C05 "expected one empty owns: and one empty consumes: line; got owns=${owns}, consumes=${consumes}"
fi

# ---------------------------------------------------------------------------
# C06 — the owner-reference document does not contain the phrase "tokio throughout".
# ---------------------------------------------------------------------------
REF="${RUN_DIR}/inputs/owner-reference-axum-companion-stack-2026-09-16.md"
tp="$($GREP -c -i 'throughout' "$REF")"
tt="$($GREP -c -i 'tokio throughout' "$REF")"
tp_line="$($GREP -n -i 'throughout' "$REF")"
rustls_hit="$(printf '%s' "$tp_line" | $GREP -c -i 'rustls')"
if [ "$tp" = "1" ] && [ "$tt" = "0" ] && [ "$rustls_hit" = "1" ]; then
  pass C06 "owner reference: one 'throughout' hit, about rustls; the phrase 'tokio throughout' does not appear"
  note "${GREP} case-insensitive counts in inputs/owner-reference-axum-companion-stack-2026-09-16.md: throughout=${tp}, 'tokio throughout'=${tt}"
  note "the single hit: ${tp_line}"
else
  fail C06 "throughout=${tp}, 'tokio throughout'=${tt}, rustls-on-that-line=${rustls_hit}"
fi

# ---------------------------------------------------------------------------
# C07 — the keystone: dep:tokio is illegal against a non-optional tokio.
#       This is what an async core would collide with in R69's owned value.
# ---------------------------------------------------------------------------
mkdir -p "${WORK}/p_dep_bad/src"
cat > "${WORK}/p_dep_bad/Cargo.toml" <<'EOF'
[package]
name = "p_dep_bad"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
tokio = { version = "1.53.1", features = ["rt-multi-thread"] }

[features]
web = ["dep:tokio"]
EOF
echo 'fn main() {}' > "${WORK}/p_dep_bad/src/main.rs"
( cd "${WORK}/p_dep_bad" && cargo metadata --no-deps --format-version 1 ) > /dev/null 2> "${WORK}/p_dep_bad.err"
rc=$?
# shellcheck disable=SC2016  # the backticks are literal text in cargo's diagnostic
msg="$($GREP -c 'feature `web` includes `dep:tokio`, but `tokio` is not an optional dependency' "${WORK}/p_dep_bad.err")"
if [ "$rc" -ne 0 ] && [ "$msg" = "1" ]; then
  pass C07 "cargo rejects web = [\"dep:tokio\"] when tokio is non-optional"
  note "cargo metadata exit=${rc}; ${GREP} matches for the expected diagnostic: ${msg}"
  note "diagnostic: $($GREP 'is not an optional dependency' "${WORK}/p_dep_bad.err" | head -1)"
else
  fail C07 "expected a non-zero exit and the optional-dependency diagnostic; exit=${rc}, matches=${msg}"
fi

# ---------------------------------------------------------------------------
# C08 — the same manifest parses once tokio is optional (the synchronous branch).
# ---------------------------------------------------------------------------
mkdir -p "${WORK}/p_dep_good/src"
cat > "${WORK}/p_dep_good/Cargo.toml" <<'EOF'
[package]
name = "p_dep_good"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread"] }

[features]
web = ["dep:tokio"]
EOF
echo 'fn main() {}' > "${WORK}/p_dep_good/src/main.rs"
( cd "${WORK}/p_dep_good" && cargo metadata --no-deps --format-version 1 ) > "${WORK}/p_dep_good.json" 2> "${WORK}/p_dep_good.err"
rc=$?
named="$($GREP -c '"name":"p_dep_good"' "${WORK}/p_dep_good.json")"
if [ "$rc" -eq 0 ] && [ "$named" -ge 1 ]; then
  pass C08 "the same manifest parses when tokio is optional"
  note "cargo metadata exit=${rc}; package name present in the emitted metadata: ${named}"
else
  fail C08 "expected exit 0 and the package in the metadata; exit=${rc}, name-matches=${named}, stderr: $(head -3 "${WORK}/p_dep_good.err")"
fi

# ---------------------------------------------------------------------------
# C09 — the second keystone: a native async fn in a trait is not dyn compatible,
#       so an async port cannot keep R01's erased Arc<dyn ProjectsPort> shape
#       without the async-trait macro R01 makes conditional on this item.
# ---------------------------------------------------------------------------
cat > "${WORK}/native_async_port.rs" <<'EOF'
use std::sync::Arc;
pub trait NativeAsyncPort: Send + Sync {
    async fn list(&self) -> Vec<String>;
}
pub fn erase(p: Arc<dyn NativeAsyncPort>) -> Arc<dyn NativeAsyncPort> { p }
EOF
rustc --edition 2024 --crate-type lib --emit=metadata -o /dev/null "${WORK}/native_async_port.rs" \
  > "${WORK}/native_async_port.out" 2>&1
rc=$?
# shellcheck disable=SC2016  # the backticks are literal text in rustc's diagnostic
e0038="$($GREP -c 'error\[E0038\]: the trait `NativeAsyncPort` is not dyn compatible' "${WORK}/native_async_port.out")"
if [ "$rc" -ne 0 ] && [ "$e0038" = "1" ]; then
  pass C09 "a trait with a native async fn cannot be erased to Arc<dyn _> (E0038)"
  note "rustc exit=${rc}; ${GREP} matches for E0038: ${e0038}"
else
  fail C09 "expected a non-zero exit and E0038; exit=${rc}, matches=${e0038}"
fi

# ---------------------------------------------------------------------------
# Scenario probes for C10-C13. Each is the template's declared shape, not its
# code: one Cargo.toml and an empty main. The committed Cargo.lock files pin
# every transitive version so the counts below are reproducible.
# ---------------------------------------------------------------------------
mkdir -p "${WORK}/p_scen_sync/src" "${WORK}/p_scen_async/src"
echo 'fn main() {}' > "${WORK}/p_scen_sync/src/main.rs"
echo 'fn main() {}' > "${WORK}/p_scen_async/src/main.rs"

cat > "${WORK}/p_scen_sync/Cargo.toml" <<'EOF'
[package]
name = "p_scen_sync"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
ureq = { version = "3.4.2", features = ["json"] }
serde = { version = "1.0.229", features = ["derive"] }
serde_json = "1.0.151"
axum = { version = "0.8.9", optional = true }
tokio = { version = "1.53.1", optional = true, features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }

[features]
web = ["dep:axum", "dep:tokio"]
EOF

cat > "${WORK}/p_scen_async/Cargo.toml" <<'EOF'
[package]
name = "p_scen_async"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
reqwest = { version = "0.13.5", default-features = false, features = ["rustls", "json"] }
tokio = { version = "1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
async-trait = "0.1.92"
serde = { version = "1.0.229", features = ["derive"] }
serde_json = "1.0.151"
axum = { version = "0.8.9", optional = true }

[features]
web = ["dep:axum"]
EOF

mkdir -p "${WORK}/p_scen_async_defaults/src"
echo 'fn main() {}' > "${WORK}/p_scen_async_defaults/src/main.rs"
sed -e 's/^name = "p_scen_async"$/name = "p_scen_async_defaults"/' \
    -e 's/^reqwest = .*$/reqwest = { version = "0.13.5", features = ["rustls", "json"] }/' \
    "${WORK}/p_scen_async/Cargo.toml" > "${WORK}/p_scen_async_defaults/Cargo.toml"

LOCKED=""
for scen in p_scen_sync p_scen_async p_scen_async_defaults; do
  if [ -f "${SCRIPT_DIR}/${scen}.Cargo.lock" ]; then
    cp "${SCRIPT_DIR}/${scen}.Cargo.lock" "${WORK}/${scen}/Cargo.lock"
  else
    ( cd "${WORK}/${scen}" && cargo generate-lockfile -q 2>> "${WORK}/cargo-tree.err" ) || { fail C10 "cannot generate a lockfile for ${scen}"; }
    cp "${WORK}/${scen}/Cargo.lock" "${SCRIPT_DIR}/${scen}.Cargo.lock"
    LOCKED="${LOCKED} ${scen}"
  fi
done
if [ -n "$LOCKED" ]; then
  note "first run: generated and snapshotted lockfiles for${LOCKED}; later runs reuse them with --locked"
fi

count_deps() {
  # unique normal dependencies including the root package, Opus's method.
  # cargo's own stderr is captured rather than printed: under concurrent agents
  # it emits "Blocking waiting for file lock on package cache", which would make
  # this log irreproducible. A real failure still shows, as a wrong count.
  ( cd "$1" && cargo tree --prefix none -e normal --locked "${@:2}" 2>> "${WORK}/cargo-tree.err" ) \
    | sed 's/ (\*)$//' | awk 'NF' | sort -u | wc -l | tr -d ' '
}

# ---------------------------------------------------------------------------
# C10 — the synchronous template shape: no runtime in the default tree.
# ---------------------------------------------------------------------------
sync_off="$(count_deps "${WORK}/p_scen_sync")"
sync_on="$(count_deps "${WORK}/p_scen_sync" --features web)"
( cd "${WORK}/p_scen_sync" && cargo tree -i tokio -e normal --locked ) > "${WORK}/sync_tokio_off.txt" 2>&1
sync_tokio_off_rc=$?
( cd "${WORK}/p_scen_sync" && cargo tree -i tokio -e normal --locked --features web ) > "${WORK}/sync_tokio_on.txt" 2>&1
sync_tokio_on_rc=$?
sync_tokio_on_hit="$($GREP -c '^tokio v1\.53\.1$' "${WORK}/sync_tokio_on.txt")"
if [ "$sync_off" = "38" ] && [ "$sync_on" = "71" ] && [ "$sync_tokio_off_rc" -ne 0 ] && [ "$sync_tokio_on_rc" -eq 0 ] && [ "$sync_tokio_on_hit" = "1" ]; then
  pass C10 "synchronous shape: 38 default deps, 71 with --features web, tokio absent by default and present only with the feature"
  note "cargo tree counts (unique normal deps, root included): feature-off=${sync_off}, feature-on=${sync_on}"
  note "cargo tree -i tokio: feature-off exit=${sync_tokio_off_rc} (not found), feature-on exit=${sync_tokio_on_rc} with ${GREP} matches for 'tokio v1.53.1'=${sync_tokio_on_hit}"
else
  fail C10 "off=${sync_off} (want 38), on=${sync_on} (want 71), tokio-off-rc=${sync_tokio_off_rc}, tokio-on-rc=${sync_tokio_on_rc}, tokio-on-hit=${sync_tokio_on_hit}"
  note "captured cargo tree stderr: $(head -3 "${WORK}/cargo-tree.err" 2>/dev/null)"
fi

# ---------------------------------------------------------------------------
# C11 — the asynchronous template shape: the runtime is in every build.
# ---------------------------------------------------------------------------
async_off="$(count_deps "${WORK}/p_scen_async")"
async_on="$(count_deps "${WORK}/p_scen_async" --features web)"
( cd "${WORK}/p_scen_async" && cargo tree -i tokio -e normal --locked ) > "${WORK}/async_tokio_off.txt" 2>&1
async_tokio_off_rc=$?
async_tokio_off_hit="$($GREP -c '^tokio v1\.53\.1$' "${WORK}/async_tokio_off.txt")"
if [ "$async_off" = "93" ] && [ "$async_on" = "101" ] && [ "$async_tokio_off_rc" -eq 0 ] && [ "$async_tokio_off_hit" = "1" ] && [ "$async_off" -gt "$sync_off" ]; then
  pass C11 "asynchronous shape: 93 default deps, 101 with --features web, tokio present in the default tree"
  note "cargo tree counts (unique normal deps, root included): feature-off=${async_off}, feature-on=${async_on}"
  note "the finding: the web feature costs the synchronous shape $((sync_on - sync_off)) extra crates only when it is on, while the asynchronous model costs $((async_off - sync_off)) extra crates in every build including the default one that has no web service"
else
  fail C11 "off=${async_off} (want 93), on=${async_on} (want 101), tokio-off-rc=${async_tokio_off_rc}, tokio-hit=${async_tokio_off_hit}"
  note "captured cargo tree stderr: $(head -3 "${WORK}/cargo-tree.err" 2>/dev/null)"
fi

# ---------------------------------------------------------------------------
# C12 — the owner reference's one-crypto-provider rule, checked in both trees.
# ---------------------------------------------------------------------------
( cd "${WORK}/p_scen_sync" && cargo tree --prefix none -e normal --locked --features web 2>> "${WORK}/cargo-tree.err" ) | sed 's/ (\*)$//' | awk 'NF' | sort -u \
  | $GREP -E '^(ring|aws-lc-rs|aws-lc-sys|openssl|openssl-sys|native-tls|rustls) ' > "${WORK}/sync_crypto.txt"
( cd "${WORK}/p_scen_async" && cargo tree --prefix none -e normal --locked --features web 2>> "${WORK}/cargo-tree.err" ) | sed 's/ (\*)$//' | awk 'NF' | sort -u \
  | $GREP -E '^(ring|aws-lc-rs|aws-lc-sys|openssl|openssl-sys|native-tls|rustls) ' > "${WORK}/async_crypto.txt"
sync_ring="$($GREP -c '^ring v' "${WORK}/sync_crypto.txt")"
sync_awslc="$($GREP -c '^aws-lc' "${WORK}/sync_crypto.txt")"
async_awslc="$($GREP -c '^aws-lc-rs v' "${WORK}/async_crypto.txt")"
async_ring="$($GREP -c '^ring v' "${WORK}/async_crypto.txt")"
if [ "$sync_ring" = "1" ] && [ "$sync_awslc" = "0" ] && [ "$async_awslc" = "1" ] && [ "$async_ring" = "0" ]; then
  pass C12 "one crypto provider in each feature-on tree: ring for the synchronous shape, aws-lc-rs for the asynchronous one"
  note "synchronous feature-on TLS crates: $(tr '\n' ' ' < "${WORK}/sync_crypto.txt")"
  note "asynchronous feature-on TLS crates: $(tr '\n' ' ' < "${WORK}/async_crypto.txt")"
  note "${GREP} counts: sync ring=${sync_ring} aws-lc=${sync_awslc}; async aws-lc-rs=${async_awslc} ring=${async_ring}"
else
  fail C12 "sync ring=${sync_ring} aws-lc=${sync_awslc}; async aws-lc-rs=${async_awslc} ring=${async_ring}"
fi

# ---------------------------------------------------------------------------
# C13 — clean release compile cost. INFORMATIONAL numbers; only the ordering
#       is asserted, because wall-clock time is machine- and load-dependent.
# ---------------------------------------------------------------------------
build_seconds() {
  ( cd "$1" && cargo clean -q ) || return 1
  local t0 t1
  t0="$(date +%s)"
  ( cd "$1" && cargo build --release -q --locked ) > /dev/null 2>&1 || return 1
  t1="$(date +%s)"
  echo $((t1 - t0))
}
sync_secs="$(build_seconds "${WORK}/p_scen_sync")"
sync_build_rc=$?
async_secs="$(build_seconds "${WORK}/p_scen_async")"
async_build_rc=$?
if [ "$sync_build_rc" -eq 0 ] && [ "$async_build_rc" -eq 0 ] && [ "$sync_secs" -lt "$async_secs" ]; then
  pass C13 "both shapes build clean in release; the synchronous one is strictly faster"
  note "INFORMATIONAL, varies per machine and run: p_scen_sync seconds=${sync_secs}, p_scen_async seconds=${async_secs}"
  note "only the ordering (sync < async) is asserted"
else
  fail C13 "sync rc=${sync_build_rc} seconds=${sync_secs}; async rc=${async_build_rc} seconds=${async_secs}"
fi

# ---------------------------------------------------------------------------
# C14 — the recommended client completes a real HTTPS round trip on this host,
#       directly and through the web-adapter bridge, with the same result.
#       This supplies the macOS leg that ureq's own CI does not run (C17).
# ---------------------------------------------------------------------------
mkdir -p "${WORK}/p_bridge/src"
cat > "${WORK}/p_bridge/Cargo.toml" <<'EOF'
[package]
name = "p_bridge"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"

[dependencies]
ureq = "3.4.2"
tokio = { version = "1.53.1", features = ["rt-multi-thread", "macros", "time", "sync"] }
EOF
cat > "${WORK}/p_bridge/src/main.rs" <<'EOF'
fn fetch() -> usize {
    ureq::get("https://example.com/")
        .call()
        .expect("request")
        .body_mut()
        .read_to_string()
        .expect("body")
        .len()
}

fn main() {
    println!("direct_blocking_len={}", fetch());
    let rt = tokio::runtime::Builder::new_multi_thread()
        .enable_all()
        .build()
        .expect("runtime");
    let n = rt.block_on(async { tokio::task::spawn_blocking(fetch).await.expect("join") });
    println!("spawn_blocking_len={}", n);
}
EOF
( cd "${WORK}/p_bridge" && cargo run --release -q ) > "${WORK}/p_bridge.out" 2> "${WORK}/p_bridge.err"
rc=$?
direct="$($GREP -o 'direct_blocking_len=[0-9]*' "${WORK}/p_bridge.out" | cut -d= -f2)"
bridged="$($GREP -o 'spawn_blocking_len=[0-9]*' "${WORK}/p_bridge.out" | cut -d= -f2)"
if [ "$rc" -eq 0 ] && [ -n "$direct" ] && [ "$direct" = "$bridged" ] && [ "$direct" -gt 0 ]; then
  pass C14 "ureq 3.4.2 fetched https://example.com/ on this host, directly and inside tokio::task::spawn_blocking, with identical results"
  note "binary p_bridge: direct_blocking_len=${direct}, spawn_blocking_len=${bridged} (bytes of body)"
  note "endpoint GET https://example.com/ ; the byte count is the live page's size and would change if that page changes"
else
  fail C14 "exit=${rc}, direct=${direct}, bridged=${bridged}, stderr: $(head -3 "${WORK}/p_bridge.err")"
fi

# ---------------------------------------------------------------------------
# C15 — crates.io: newest non-yanked version of each named crate.
#       Endpoint: GET https://crates.io/api/v1/crates/<name>/versions
#       Field rule: newest entry with yanked:false -> num, created_at.
#       Download counts are deliberately NOT printed: they move daily and would
#       make this log irreproducible. A version change here is a re-verify trigger.
# ---------------------------------------------------------------------------
crates_ok=1
: > "${WORK}/crates-io.txt"
check_version() {
  local name="$1" want="$2" got
  got="$(curl -sS -m 60 -H "User-Agent: ${UA}" "https://crates.io/api/v1/crates/${name}/versions" \
    | python3 -c 'import json,sys; d=json.load(sys.stdin); n=[v for v in d["versions"] if not v["yanked"]][0]; print(n["num"], n["created_at"])')" || return 1
  printf '%s newest-non-yanked %s\n' "$name" "$got" >> "${WORK}/crates-io.txt"
  case "$got" in
    "$want "*) return 0 ;;
    *) return 1 ;;
  esac
}
while IFS=' ' read -r crate_name crate_want; do
  [ -n "$crate_name" ] || continue
  check_version "$crate_name" "$crate_want" || crates_ok=0
done <<'CRATES'
ureq 3.4.2
tokio 1.53.1
axum 0.8.9
reqwest 0.13.5
CRATES
if [ "$crates_ok" = "1" ]; then
  pass C15 "crates.io newest non-yanked versions match the versions this decision names"
  while IFS= read -r line; do note "$line"; done < "${WORK}/crates-io.txt"
  note "endpoint GET https://crates.io/api/v1/crates/<name>/versions ; field: newest entry with yanked:false -> num, created_at"
else
  fail C15 "at least one crate's newest non-yanked version is not the named one: $(tr '\n' '; ' < "${WORK}/crates-io.txt")"
fi

# ---------------------------------------------------------------------------
# C16 — the tokio feature arithmetic the owner reference's `features = ["full"]`
#       row turns on, read at the immutable release tag.
#       Endpoint: GET https://api.github.com/repos/tokio-rs/tokio/contents/tokio/Cargo.toml?ref=tokio-1.53.1
# ---------------------------------------------------------------------------
gh api "repos/tokio-rs/tokio/contents/tokio/Cargo.toml?ref=tokio-1.53.1" --jq '.content' 2>"${WORK}/gh.err" \
  | base64 -d > "${WORK}/tokio-Cargo.toml"
rc=$?
if [ "$rc" -eq 0 ] && [ -s "${WORK}/tokio-Cargo.toml" ]; then
  default_empty="$($GREP -c '^default = \[\]$' "${WORK}/tokio-Cargo.toml")"
  full_members="$(awk '/^full = \[$/{f=1;next} f&&/^\]$/{exit} f&&/"/{n++} END{print n+0}' "${WORK}/tokio-Cargo.toml")"
  if [ "$default_empty" = "1" ] && [ "$full_members" = "12" ]; then
    pass C16 "tokio 1.53.1 declares default = [] and a full feature with 12 members"
    note "${GREP} exact-line matches for 'default = []': ${default_empty}; awk-counted members of full: ${full_members}"
    note "full = $(awk '/^full = \[$/{f=1;next} f&&/^\]$/{exit} f{printf "%s", $0}' "${WORK}/tokio-Cargo.toml" | tr -d ' ')"
    note "endpoint GET https://api.github.com/repos/tokio-rs/tokio/contents/tokio/Cargo.toml?ref=tokio-1.53.1 (immutable tag)"
  else
    fail C16 "default=[] matches=${default_empty} (want 1), full members=${full_members} (want 12)"
  fi
else
  fail C16 "could not read tokio's manifest at the tag (exit ${rc}): $(head -2 "${WORK}/gh.err")"
fi

# ---------------------------------------------------------------------------
# C17 — the two qualifications this decision carries about ureq, checked rather
#       than asserted: no RustSec advisory page, and no macOS job in its own CI.
#       Endpoints: https://rustsec.org/packages/<name>.html ;
#       GET https://api.github.com/repos/algesten/ureq/contents/.github/workflows/test.yml?ref=3.4.2
# ---------------------------------------------------------------------------
ureq_sec="$(curl -sS -o /dev/null -w '%{http_code}' -m 60 "https://rustsec.org/packages/ureq.html")"
tokio_sec="$(curl -sS -o /dev/null -w '%{http_code}' -m 60 "https://rustsec.org/packages/tokio.html")"
gh api "repos/algesten/ureq/contents/.github/workflows/test.yml?ref=3.4.2" --jq '.content' 2>"${WORK}/gh2.err" \
  | base64 -d > "${WORK}/ureq-test.yml"
rc=$?
if [ "$rc" -eq 0 ] && [ -s "${WORK}/ureq-test.yml" ]; then
  ureq_macos="$($GREP -c -i 'runs-on:.*macos' "${WORK}/ureq-test.yml")"
  ureq_ubuntu="$($GREP -c -i 'runs-on:.*ubuntu' "${WORK}/ureq-test.yml")"
else
  ureq_macos="unreadable"
  ureq_ubuntu="unreadable"
fi
if [ "$ureq_sec" = "404" ] && [ "$tokio_sec" = "200" ] && [ "$ureq_macos" = "0" ] && [ "$ureq_ubuntu" -gt 0 ] 2>/dev/null; then
  pass C17 "ureq has no RustSec advisory page and its own CI runs no macOS job"
  note "https://rustsec.org/packages/ureq.html http=${ureq_sec} (no advisory ever filed); https://rustsec.org/packages/tokio.html http=${tokio_sec} (page exists, control)"
  note "${GREP} counts in ureq 3.4.2 .github/workflows/test.yml: runs-on macos=${ureq_macos}, runs-on ubuntu=${ureq_ubuntu}"
  note "consequence, carried into the decision: gate 4's macOS leg for ureq rests on C14's single local run on this host, not on the project's CI"
else
  fail C17 "ureq rustsec http=${ureq_sec} (want 404), tokio rustsec http=${tokio_sec} (want 200), ureq macos jobs=${ureq_macos} (want 0), ubuntu jobs=${ureq_ubuntu} (want >0)"
fi

# ---------------------------------------------------------------------------
# C18 — the coverage gap that settles the engine disagreement: none of the three
#       Doxa provider reports priced the Cargo optional-dependency constraint,
#       the async-trait cost, or R69 at all. This is the grep the decision cites
#       under ## Engines, disagreement 1.
# ---------------------------------------------------------------------------
c18_ok=1
for provider in openai perplexity gemini; do
  body="${RUN_DIR}/raw/doxa-${provider}.normalized.md"
  if [ ! -f "$body" ]; then
    c18_ok=0
    note "missing provider body: raw/doxa-${provider}.normalized.md"
    continue
  fi
  n_dep="$($GREP -c 'dep:tokio' "$body")"
  n_r69="$($GREP -c 'R69' "$body")"
  n_at="$($GREP -c 'async-trait' "$body")"
  n_v_tokio="$($GREP -c '1\.53\.1' "$body")"
  n_v_reqwest="$($GREP -c '0\.13\.5' "$body")"
  n_v_ureq="$($GREP -c '3\.4\.2' "$body")"
  n_v_axum="$($GREP -c '0\.8\.9' "$body")"
  note "raw/doxa-${provider}.normalized.md — ${GREP} -c counts: 'dep:tokio'=${n_dep}, 'R69'=${n_r69}, 'async-trait'=${n_at}"
  note "raw/doxa-${provider}.normalized.md — ${GREP} -c version-string counts: '1.53.1'=${n_v_tokio}, '0.13.5'=${n_v_reqwest}, '3.4.2'=${n_v_ureq}, '0.8.9'=${n_v_axum}"
  [ "$n_dep" = "0" ] && [ "$n_r69" = "0" ] && [ "$n_at" = "0" ] || c18_ok=0
  case "$provider" in
    openai)
      # OpenAI is the one provider that pins all four versions
      [ "$n_v_tokio" -gt 0 ] && [ "$n_v_reqwest" -gt 0 ] && [ "$n_v_ureq" -gt 0 ] && [ "$n_v_axum" -gt 0 ] || c18_ok=0
      ;;
    perplexity)
      # Perplexity pins none of the three client/runtime versions
      [ "$n_v_tokio" = "0" ] && [ "$n_v_reqwest" = "0" ] && [ "$n_v_ureq" = "0" ] || c18_ok=0
      ;;
  esac
done
if [ "$c18_ok" = "1" ]; then
  pass C18 "no Doxa provider body mentions dep:tokio, R69 or async-trait; OpenAI pins all four versions and Perplexity pins none of the three client/runtime versions"
  note "consequence, carried into the decision: all three async recommendations were formed without the two owner-accepted constraints checks C02, C03, C07 and C09 establish"
else
  fail C18 "at least one provider body carries one of the three terms, or a body is missing; see the counts above"
fi

# ---------------------------------------------------------------------------
# C19 — the asynchronous figures in C11 use reqwest with default-features = false,
#       which is the LEANEST async configuration. With reqwest's defaults left on
#       the same package resolves larger still, so C11 understates rather than
#       overstates the asynchronous cost.
# ---------------------------------------------------------------------------
adef_off="$(count_deps "${WORK}/p_scen_async_defaults")"
adef_on="$(count_deps "${WORK}/p_scen_async_defaults" --features web)"
if [ "$adef_off" = "109" ] && [ "$adef_on" = "116" ] && [ "$adef_off" -gt "$async_off" ]; then
  pass C19 "with reqwest's default features on, the asynchronous shape resolves to 109 default deps and 116 with --features web"
  note "cargo tree counts (unique normal deps, root included): feature-off=${adef_off}, feature-on=${adef_on}"
  note "consequence: C11's 93/101 is the leanest asynchronous configuration, so the sync-versus-async comparison is conservative"
else
  fail C19 "off=${adef_off} (want 109), on=${adef_on} (want 116), C11 off=${async_off}"
fi

# ---------------------------------------------------------------------------
# C20 — the two remaining facts the owner-reference dispositions rest on:
#       R05-3 quotes R67's registered exit-code contract, and R05-4 asserts that
#       both reference Variants' handler heads are async fn axum handlers.
# ---------------------------------------------------------------------------
python3 - "$REGISTRY" > "${WORK}/exitcodes.txt" <<'EXITCODES'
import sys
for line in open(sys.argv[1], encoding="utf-8"):
    if line.startswith("| error-taxonomy-exit-codes |"):
        sys.stdout.write(line.split(" | ")[3])
        break
EXITCODES
rc=$?
# shellcheck disable=SC2016  # the backticks are literal text in the registry value
main_exitcode="$($GREP -c '`main` returns `ExitCode` and does not call `process::exit` on the error path' "${WORK}/exitcodes.txt")"
ref_tasks="$($GREP -c '^async fn tasks(' "$REF")"
ref_create="$($GREP -c '^async fn create(' "$REF")"
ref_ws="$($GREP -c '^async fn ws(' "$REF")"
if [ "$rc" -eq 0 ] && [ "$main_exitcode" = "1" ] && [ "$ref_tasks" = "1" ] && [ "$ref_create" = "1" ] && [ "$ref_ws" = "1" ]; then
  pass C20 "R67's registered contract says main returns ExitCode, and the owner reference's three Variant handler heads are async fn"
  note "${GREP} matches in the extracted error-taxonomy-exit-codes cell for the ExitCode sentence: ${main_exitcode}"
  note "${GREP} line-start matches in the owner reference: 'async fn tasks('=${ref_tasks}, 'async fn create('=${ref_create}, 'async fn ws('=${ref_ws}"
  note "consequence: dispositions R05-3 and R05-4 rest on verified text, not on a raw report's reading"
else
  fail C20 "extraction rc=${rc}; ExitCode sentence=${main_exitcode}, tasks=${ref_tasks}, create=${ref_create}, ws=${ref_ws}"
fi

printf '\n== summary ==\n'
printf 'passed=%d failed=%d skipped=%d\n' "$PASSED" "$FAILED" "$SKIPPED"
if [ "$FAILED" -gt 0 ]; then
  printf 'RESULT: FAIL\n'
  exit 1
fi
printf 'RESULT: PASS\n'
exit 0
