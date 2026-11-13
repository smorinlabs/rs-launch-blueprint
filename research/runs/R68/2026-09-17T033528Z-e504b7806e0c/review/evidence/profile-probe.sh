#!/usr/bin/env bash
# R68 empirical check, part 1 of 2: reproduce the Cargo release-profile size
# deltas this decision relies on, at the pinned toolchain, on this macOS host.
#
# It builds a throwaway stand-in crate under a directory it creates below
# ${TMPDIR} and deletes on exit. It builds NOTHING inside the repository and
# writes nothing outside its own temporary directory.
#
# Reproduction rule: every `SIZE`, `DELTA`, `BACKTRACE` and `ASSERT` line
# reproduces byte-for-byte on a rerun at the same toolchain. Every `TIME` line
# is wall-clock seconds on a shared machine and does NOT reproduce; the only
# build-time claims DECISION.md makes from them are the two separations that
# exceed the noise floor stated there.
#
# Needs: network once (`cargo fetch`), then every build runs `--offline`.
# Needs no `.git`, so it runs from a clean `git archive HEAD` extraction.

set -euo pipefail

GREP=/usr/bin/grep
AWK=/usr/bin/awk
STRIP=/usr/bin/strip
STAT=/usr/bin/stat

PINNED_RUSTC="rustc 1.98.0"
PINNED_CARGO="cargo 1.98.0"

echo "=== R68 profile probe ==="
echo "date(UTC): $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "rustc: $(rustc -V)"
echo "cargo: $(cargo -V)"
echo "os: $(sw_vers -productName) $(sw_vers -productVersion) ($(sw_vers -buildVersion))"
echo "arch: $(uname -m)"
echo "cpu: $(sysctl -n machdep.cpu.brand_string)"
echo

# A check that cannot fail is not evidence: refuse to produce figures at a
# toolchain other than the one the decision names.
if ! rustc -V | "$GREP" -q -- "$PINNED_RUSTC"; then
  echo "ASSERT FAIL: rustc is not ${PINNED_RUSTC}" >&2
  exit 1
fi
if ! cargo -V | "$GREP" -q -- "$PINNED_CARGO"; then
  echo "ASSERT FAIL: cargo is not ${PINNED_CARGO}" >&2
  exit 1
fi
echo "ASSERT ok   toolchain is the pinned ${PINNED_RUSTC} / ${PINNED_CARGO}"
echo

PROBE_ROOT=$(mktemp -d "${TMPDIR:-/tmp}/r68-probe.XXXXXX")
cleanup() { rm -rf "$PROBE_ROOT"; }
trap cleanup EXIT
echo "probe root: created under \$TMPDIR, deleted on exit"
echo

mkdir -p "$PROBE_ROOT/src/bin"

# Stand-in composition, stated so its unlikeness to the real template is on the
# record: it mirrors R49's target shape (one [lib] rs_launch_blueprint, one
# [[bin]] rslbp, autobins = false) and R69's feature shape (a `web` feature
# adding a second binary), and carries a port trait, an in-memory adapter, a
# clap parser and three axum routes. It has no domain logic, no error catalog,
# no config layering and no observability stack, so it is SMALLER than the
# template will be: absolute byte counts are floors, percentages transfer.
cat >"$PROBE_ROOT/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint"
version = "0.0.0"
edition = "2024"
rust-version = "1.96"
publish = false
autobins = false

[lib]
name = "rs_launch_blueprint"
path = "src/lib.rs"

[[bin]]
name = "rslbp"
path = "src/main.rs"

[[bin]]
name = "rslbp-serve"
path = "src/bin/serve.rs"
required-features = ["web"]

[features]
default = []
web = ["dep:axum", "dep:tokio"]

[dependencies]
anyhow = "1"
clap = { version = "4", features = ["derive"] }
serde = { version = "1", features = ["derive"] }
serde_json = "1"
thiserror = "2"
tracing = "0.1"
tracing-subscriber = { version = "0.3", features = ["env-filter"] }
axum = { version = "0.8", optional = true }
tokio = { version = "1", features = ["rt-multi-thread", "macros"], optional = true }
TOML

cat >"$PROBE_ROOT/src/lib.rs" <<'RS'
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Project {
    pub id: u64,
    pub name: String,
}

#[derive(Debug, thiserror::Error)]
pub enum PortError {
    #[error("not found: {0}")]
    NotFound(u64),
}

pub trait ProjectsPort: Send + Sync {
    fn get(&self, id: u64) -> Result<Project, PortError>;
    fn list(&self) -> Result<Vec<Project>, PortError>;
}

#[derive(Default)]
pub struct InMemoryProjectsPort {
    items: Vec<Project>,
}

impl InMemoryProjectsPort {
    pub fn seeded() -> Self {
        Self {
            items: (0..8)
                .map(|i| Project { id: i, name: format!("project-{i}") })
                .collect(),
        }
    }
}

impl ProjectsPort for InMemoryProjectsPort {
    fn get(&self, id: u64) -> Result<Project, PortError> {
        self.items.iter().find(|p| p.id == id).cloned().ok_or(PortError::NotFound(id))
    }
    fn list(&self) -> Result<Vec<Project>, PortError> {
        Ok(self.items.clone())
    }
}

/// The deliberate panic site every backtrace row below is measured against.
pub fn deliberate_panic(tag: &str) -> ! {
    tracing::debug!(tag, "about to panic");
    panic!("r68 probe panic: {tag}");
}
RS

cat >"$PROBE_ROOT/src/main.rs" <<'RS'
use clap::{Parser, Subcommand};
use rs_launch_blueprint::{InMemoryProjectsPort, ProjectsPort, deliberate_panic};

#[derive(Parser)]
#[command(name = "rslbp")]
struct Cli {
    #[command(subcommand)]
    cmd: Cmd,
}

#[derive(Subcommand)]
enum Cmd {
    List,
    Get { id: u64 },
    Panic,
}

fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt().with_env_filter("info").init();
    let cli = Cli::parse();
    let port = InMemoryProjectsPort::seeded();
    match cli.cmd {
        Cmd::List => println!("{}", serde_json::to_string(&port.list()?)?),
        Cmd::Get { id } => println!("{}", serde_json::to_string(&port.get(id)?)?),
        Cmd::Panic => deliberate_panic("cli"),
    }
    Ok(())
}
RS

cat >"$PROBE_ROOT/src/bin/serve.rs" <<'RS'
use axum::{Json, Router, extract::Path, routing::get};
use rs_launch_blueprint::{InMemoryProjectsPort, Project, ProjectsPort};

async fn healthz() -> &'static str {
    "ok"
}

async fn list() -> Json<Vec<Project>> {
    Json(InMemoryProjectsPort::seeded().list().unwrap_or_default())
}

async fn one(Path(id): Path<u64>) -> Json<Option<Project>> {
    Json(InMemoryProjectsPort::seeded().get(id).ok())
}

#[tokio::main]
async fn main() {
    let app = Router::new()
        .route("/healthz", get(healthz))
        .route("/projects", get(list))
        .route("/projects/{id}", get(one));
    let listener = tokio::net::TcpListener::bind("127.0.0.1:0").await.unwrap();
    axum::serve(listener, app).await.unwrap();
}
RS

cd "$PROBE_ROOT"

echo "--- resolving and fetching the dependency tree (the only online step) ---"
cargo generate-lockfile >/dev/null 2>&1
cargo fetch --quiet
DEPS_DEFAULT=$(cargo tree --edges normal --prefix none --offline 2>/dev/null | sort -u | "$GREP" -c .)
DEPS_ALL=$(cargo tree --edges normal --prefix none --all-features --offline 2>/dev/null | sort -u | "$GREP" -c .)
echo "probe dependency tree, unique lines of cargo tree: default=${DEPS_DEFAULT} all-features=${DEPS_ALL}"
echo "resolved versions of the named direct dependencies:"
for c in anyhow clap serde serde_json thiserror tracing tracing-subscriber axum tokio; do
  # shellcheck disable=SC2016  # $0 and $1 below are awk fields, not shell variables
  v=$("$AWK" -v c="$c" 'f == 1 { sub(/^version = /, ""); gsub(/"/, ""); print; exit } $0 == "name = \"" c "\"" { f = 1 }' Cargo.lock)
  echo "  ${c} ${v}"
done
echo

rows_name=()
rows_size=()

build_row() {
  label="$1"
  shift
  slug=$(printf '%s' "$label" | tr -c 'A-Za-z0-9' '_')
  td="${PROBE_ROOT}/t_${slug}"
  args=()
  for kv in "$@"; do
    args+=(--config "profile.release.${kv}")
  done
  s0=$SECONDS
  CARGO_TARGET_DIR="$td" cargo build --release --offline --quiet --features web ${args[@]+"${args[@]}"}
  clean=$((SECONDS - s0))
  size=$("$STAT" -f%z "${td}/release/rslbp")
  cp "${td}/release/rslbp" "${PROBE_ROOT}/strip_probe"
  "$STRIP" -S -x "${PROBE_ROOT}/strip_probe"
  stripped=$("$STAT" -f%z "${PROBE_ROOT}/strip_probe")
  rm -f "${PROBE_ROOT}/strip_probe"
  rows_name+=("$label")
  rows_size+=("$size")
  printf 'SIZE %-38s %10s bytes  (after external strip -S -x: %10s)\n' "$label" "$size" "$stripped"
  printf 'TIME %-38s %4s s clean (wall clock, does not reproduce)\n' "$label" "$clean"
  case "$slug" in
    baseline*|strip_symbols|panic_abort|debug_line_tables_only|fat_cu1*) : ;;
    *) rm -rf "$td" ;;
  esac
}

echo "--- size matrix: one clean build per row, fresh CARGO_TARGET_DIR, --features web, measured binary is rslbp ---"
build_row 'baseline (release defaults)'
build_row 'lto=thin' 'lto="thin"'
build_row 'lto=fat' 'lto="fat"'
build_row 'codegen-units=1' 'codegen-units=1'
build_row 'thin+cu1 (owner reference)' 'lto="thin"' 'codegen-units=1'
build_row 'fat+cu1 (recommended)' 'lto="fat"' 'codegen-units=1'
build_row 'opt-level=s' 'opt-level="s"'
build_row 'opt-level=z' 'opt-level="z"'
build_row 'strip=symbols' 'strip="symbols"'
build_row 'strip=debuginfo' 'strip="debuginfo"'
build_row 'panic=abort' 'panic="abort"'
build_row 'debug=line-tables-only' 'debug="line-tables-only"'
echo

size_of() {
  want="$1"
  i=0
  while [ "$i" -lt "${#rows_name[@]}" ]; do
    if [ "${rows_name[$i]}" = "$want" ]; then
      echo "${rows_size[$i]}"
      return 0
    fi
    i=$((i + 1))
  done
  echo "ASSERT FAIL: no row named ${want}" >&2
  exit 1
}

BASE=$(size_of 'baseline (release defaults)')
THIN=$(size_of 'lto=thin')
FAT=$(size_of 'lto=fat')
CU1=$(size_of 'codegen-units=1')
THINCU=$(size_of 'thin+cu1 (owner reference)')
FATCU=$(size_of 'fat+cu1 (recommended)')
OPTS=$(size_of 'opt-level=s')
OPTZ=$(size_of 'opt-level=z')
STRIPSYM=$(size_of 'strip=symbols')
STRIPDBG=$(size_of 'strip=debuginfo')
ABORT=$(size_of 'panic=abort')
LINETAB=$(size_of 'debug=line-tables-only')

pct() { "$AWK" -v a="$1" -v b="$2" 'BEGIN { printf "%+.1f", (a - b) * 100.0 / b }'; }

echo "--- deltas versus the Cargo release-defaults baseline of ${BASE} bytes ---"
i=0
while [ "$i" -lt "${#rows_name[@]}" ]; do
  printf 'DELTA %-38s %8s%%\n' "${rows_name[$i]}" "$(pct "${rows_size[$i]}" "$BASE")"
  i=$((i + 1))
done
echo

fail=0
assert() {
  if [ "$1" = "1" ]; then
    echo "ASSERT ok   $2"
  else
    echo "ASSERT FAIL $2"
    fail=1
  fi
}

lt() { if [ "$1" -lt "$2" ]; then echo 1; else echo 0; fi; }
gt() { if [ "$1" -gt "$2" ]; then echo 1; else echo 0; fi; }
eq() { if [ "$1" -eq "$2" ]; then echo 1; else echo 0; fi; }

assert "$(lt "$FATCU" "$THINCU")" \
  "fat+cu1 (${FATCU} B) is smaller than thin+cu1 (${THINCU} B), the owner reference architecture's row"
assert "$("$AWK" -v a="$FATCU" -v b="$BASE" 'BEGIN { print (a <= b * 0.80) ? 1 : 0 }')" \
  "fat+cu1 is at least 20% under the baseline ($(pct "$FATCU" "$BASE")%)"
assert "$("$AWK" -v a="$THINCU" -v b="$BASE" 'BEGIN { print (a > b * 0.80) ? 1 : 0 }')" \
  "thin+cu1 does NOT reach a 20% reduction ($(pct "$THINCU" "$BASE")%) — the measured ground for differing with the reference"
assert "$("$AWK" -v a="$THIN" -v b="$BASE" 'BEGIN { print (a > b * 0.95) ? 1 : 0 }')" \
  "lto=thin alone stays within 5% of the baseline ($(pct "$THIN" "$BASE")%)"
assert "$(lt "$FAT" "$BASE")" "lto=fat alone is smaller than the baseline ($(pct "$FAT" "$BASE")%)"
assert "$(lt "$CU1" "$BASE")" "codegen-units=1 alone is smaller than the baseline ($(pct "$CU1" "$BASE")%)"
assert "$(gt "$OPTS" "$BASE")" "opt-level=s is LARGER than the baseline ($(pct "$OPTS" "$BASE")%)"
assert "$(gt "$OPTZ" "$BASE")" "opt-level=z is LARGER than the baseline ($(pct "$OPTZ" "$BASE")%)"
assert "$(eq "$STRIPDBG" "$BASE")" \
  "strip=debuginfo is byte-identical to the baseline (${STRIPDBG} == ${BASE}) — a no-op, because the release profile carries no debuginfo"
assert "$("$AWK" -v a="$STRIPSYM" -v b="$BASE" 'BEGIN { print (a < b * 0.85) ? 1 : 0 }')" \
  "strip=symbols is more than 15% under the baseline ($(pct "$STRIPSYM" "$BASE")%) — the largest single size win measured"
assert "$(gt "$LINETAB" "$BASE")" "debug=line-tables-only is LARGER than the baseline ($(pct "$LINETAB" "$BASE")%)"
assert "$(lt "$ABORT" "$BASE")" "panic=abort is smaller than the baseline ($(pct "$ABORT" "$BASE")%)"
echo

echo "--- backtrace and exit status of the BUILT binary: RUST_BACKTRACE=1 rslbp panic ---"
frames_of() {
  set +e
  out=$(RUST_BACKTRACE=1 "${1}/release/rslbp" panic 2>&1)
  rc=$?
  set -e
  frames=$(printf '%s\n' "$out" | "$GREP" -c -E '^ *[0-9]+: ' || true)
  echo "${frames} ${rc}"
}

read -r F_BASE RC_BASE <<<"$(frames_of "${PROBE_ROOT}/t_baseline__release_defaults_")"
read -r F_FATCU RC_FATCU <<<"$(frames_of "${PROBE_ROOT}/t_fat_cu1__recommended_")"
read -r F_STRIP RC_STRIP <<<"$(frames_of "${PROBE_ROOT}/t_strip_symbols")"
read -r F_ABORT RC_ABORT <<<"$(frames_of "${PROBE_ROOT}/t_panic_abort")"
read -r F_LINE RC_LINE <<<"$(frames_of "${PROBE_ROOT}/t_debug_line_tables_only")"

printf 'BACKTRACE %-26s frames=%-3s exit=%s\n' 'baseline' "$F_BASE" "$RC_BASE"
printf 'BACKTRACE %-26s frames=%-3s exit=%s\n' 'fat+cu1 (recommended)' "$F_FATCU" "$RC_FATCU"
printf 'BACKTRACE %-26s frames=%-3s exit=%s\n' 'strip=symbols' "$F_STRIP" "$RC_STRIP"
printf 'BACKTRACE %-26s frames=%-3s exit=%s\n' 'panic=abort' "$F_ABORT" "$RC_ABORT"
printf 'BACKTRACE %-26s frames=%-3s exit=%s\n' 'debug=line-tables-only' "$F_LINE" "$RC_LINE"
echo

assert "$(eq "$F_STRIP" 0)" \
  "strip=symbols prints ZERO backtrace frames (frames=${F_STRIP}) — the diagnostic cost that refuses the largest size win"
assert "$(gt "$F_BASE" 0)" "the default profile prints ${F_BASE} backtrace frames"
assert "$(gt "$F_FATCU" 0)" "the RECOMMENDED fat+cu1 profile still prints ${F_FATCU} backtrace frames"
assert "$(eq "$RC_BASE" 101)" "an unwinding panic exits 101 (observed ${RC_BASE})"
assert "$(eq "$RC_FATCU" 101)" "the recommended profile also exits 101 on panic (observed ${RC_FATCU})"
if [ "$RC_ABORT" -ne 101 ]; then abort_differs=1; else abort_differs=0; fi
assert "$abort_differs" \
  "panic=abort does NOT exit 101 (observed ${RC_ABORT}); neither status is in R67's taxonomy, and abort additionally skips the flush-before-exit path"

LINE_TD="${PROBE_ROOT}/t_debug_line_tables_only"
cp "${LINE_TD}/release/rslbp" "${PROBE_ROOT}/rslbp-travelled"
IN_TREE_BEFORE=$(printf '%s\n' "$(RUST_BACKTRACE=1 "${LINE_TD}/release/rslbp" panic 2>&1 || true)" | "$GREP" -c 'at ./src/' || true)
rm -rf "${LINE_TD}"
IN_TREE_AFTER=$(printf '%s\n' "$(RUST_BACKTRACE=1 "${PROBE_ROOT}/rslbp-travelled" panic 2>&1 || true)" | "$GREP" -c 'at ./src/' || true)
echo "BACKTRACE debug=line-tables-only: 'at ./src/' lines in tree=${IN_TREE_BEFORE}, after copying the binary out and deleting its target/=${IN_TREE_AFTER}"
assert "$(gt "$IN_TREE_BEFORE" 0)" "in the build tree, debug=line-tables-only does print file:line (${IN_TREE_BEFORE} lines)"
assert "$(eq "$IN_TREE_AFTER" 0)" \
  "once the binary travels away from target/, the file:line information is GONE (${IN_TREE_AFTER} lines) — macOS split-debuginfo is unpacked, so an end user never receives it"
echo

echo "--- incremental cost: touch src/main.rs, rebuild the two profiles that were kept ---"
touch src/main.rs
s0=$SECONDS
CARGO_TARGET_DIR="${PROBE_ROOT}/t_baseline__release_defaults_" cargo build --release --offline --quiet --features web
printf 'TIME %-38s %4s s bin-only rebuild (wall clock, does not reproduce)\n' 'baseline (release defaults)' "$((SECONDS - s0))"
touch src/main.rs
s0=$SECONDS
CARGO_TARGET_DIR="${PROBE_ROOT}/t_fat_cu1__recommended_" cargo build --release --offline --quiet --features web \
  --config 'profile.release.lto="fat"' --config 'profile.release.codegen-units=1'
printf 'TIME %-38s %4s s bin-only rebuild (wall clock, does not reproduce)\n' 'fat+cu1 (recommended)' "$((SECONDS - s0))"
echo

if [ "$fail" -ne 0 ]; then
  echo "RESULT: FAIL — at least one assertion did not hold"
  exit 1
fi
echo "RESULT: PASS — every assertion held"
