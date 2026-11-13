#!/usr/bin/env bash
# R02 crate-boundary-enforcement -- compile-tier probe.
#
# Verifies the claims the Opus raw report makes about where a Rust architectural
# boundary is actually enforced, and adds two cases that report did not run.
# Builds a throwaway Cargo workspace under $TMPDIR, asserts on the *content* of
# every command's output, and deletes the workspace on exit. Nothing is written
# outside $TMPDIR; no template code is created anywhere in the repository.
#
# Every package is path-only with zero external dependencies, so every cargo
# invocation runs with --offline and needs no network and no registry index.
#
# Exit 0 only when FAILURES is 0.

set -euo pipefail
set -o pipefail

GREP=/usr/bin/grep
CHECKS=0
FAILURES=0

note() { printf '\n=== %s ===\n' "$1"; }

# ok NAME EXPECTATION ACTUAL_FILE PATTERN...   -- every pattern must be present
ok() {
  local name="$1" what="$2" file="$3"
  shift 3
  CHECKS=$((CHECKS + 1))
  local pat missing=0
  for pat in "$@"; do
    if ! "$GREP" -qF -- "$pat" "$file"; then
      printf 'FAIL %s: %s -- missing substring: %s\n' "$name" "$what" "$pat"
      missing=1
    fi
  done
  if [ "$missing" -eq 0 ]; then
    printf 'PASS %s: %s\n' "$name" "$what"
  else
    FAILURES=$((FAILURES + 1))
  fi
}

# absent NAME EXPECTATION FILE PATTERN -- the pattern must NOT be present
absent() {
  local name="$1" what="$2" file="$3" pat="$4"
  CHECKS=$((CHECKS + 1))
  if "$GREP" -qF -- "$pat" "$file"; then
    printf 'FAIL %s: %s -- unexpected substring present: %s\n' "$name" "$what" "$pat"
    FAILURES=$((FAILURES + 1))
  else
    printf 'PASS %s: %s (absent: %s)\n' "$name" "$what" "$pat"
  fi
}

# count NAME EXPECTATION FILE PATTERN EXPECTED_COUNT
count() {
  local name="$1" what="$2" file="$3" pat="$4" want="$5" got
  CHECKS=$((CHECKS + 1))
  got=$("$GREP" -cF -- "$pat" "$file" || true)
  if [ "$got" = "$want" ]; then
    printf 'PASS %s: %s (%s occurrences of %s, by %s)\n' "$name" "$what" "$got" "$pat" "$GREP"
  else
    printf 'FAIL %s: %s -- wanted %s occurrences of %s, got %s (by %s)\n' \
      "$name" "$what" "$want" "$pat" "$got" "$GREP"
    FAILURES=$((FAILURES + 1))
  fi
}

note "C0 toolchain"
command -v cargo >/dev/null || { echo "FATAL: no cargo on PATH"; exit 2; }
cargo --version
rustc --version
cargo clippy --version
uname -sm
printf 'sw_vers: %s %s\n' "$(sw_vers -productName 2>/dev/null || echo unknown)" \
  "$(sw_vers -productVersion 2>/dev/null || echo unknown)"

PROBE=$(mktemp -d "${TMPDIR:-/tmp}/r02-probe.XXXXXX")
LOGD="$PROBE/logs"
mkdir -p "$LOGD"
cleanup() { rm -rf "$PROBE"; }
trap cleanup EXIT
printf 'probe workspace: %s (deleted on exit)\n' "$PROBE"

############################################################################
# A. Single package: does module visibility enforce dependency direction?
############################################################################
note "A single package, core module names the cli module"
mkdir -p "$PROBE/single/src"
cat > "$PROBE/single/Cargo.toml" <<'TOML'
[package]
name = "single-demo"
version = "0.1.0"
edition = "2024"
TOML
cat > "$PROBE/single/src/lib.rs" <<'RS'
pub mod core_layer;
pub(crate) mod cli_layer;
RS
cat > "$PROBE/single/src/cli_layer.rs" <<'RS'
pub struct CliThing;
RS
cat > "$PROBE/single/src/core_layer.rs" <<'RS'
use crate::cli_layer::CliThing;
pub fn reach_upward() -> Option<CliThing> { None }
RS
( cd "$PROBE/single" && cargo build --offline ) > "$LOGD/a.log" 2>&1 || true
cat "$LOGD/a.log"
ok A "core->cli inside one package COMPILES: pub(crate) grants naming rights crate-wide" \
  "$LOGD/a.log" "Finished"
absent A "no compiler error is raised for the upward dependency" "$LOGD/a.log" "error["

############################################################################
# Root-package workspace: facade + crates/{core,cli,web}
############################################################################
note "workspace scaffold"
W="$PROBE/ws"
mkdir -p "$W/src/bin" "$W/crates/core/src" "$W/crates/cli/src" "$W/crates/web/src"

write_manifests() {
  cat > "$W/Cargo.toml" <<'TOML'
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"

[workspace.lints.rust]
unreachable_pub = "allow"

[workspace.lints.clippy]
disallowed_types = "deny"

[package]
name = "rs-launch-blueprint"
version.workspace = true
edition.workspace = true
license.workspace = true
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
web = ["dep:rs-launch-blueprint-web"]

[dependencies]
rs-launch-blueprint-core = { path = "crates/core", version = "0.1.0" }
rs-launch-blueprint-cli = { path = "crates/cli", version = "0.1.0" }
rs-launch-blueprint-web = { path = "crates/web", version = "0.1.0", optional = true }

[lints]
workspace = true
TOML
  cat > "$W/crates/core/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-core"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]

[lints]
workspace = true
TOML
  cat > "$W/crates/cli/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-cli"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]
rs-launch-blueprint-core = { path = "../core", version = "0.1.0" }

[lints]
workspace = true
TOML
  cat > "$W/crates/web/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-web"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]
rs-launch-blueprint-core = { path = "../core", version = "0.1.0" }

[lints]
workspace = true
TOML
}

# core_lib writes the standard core member, faithful to R01's published value
# (dyn-compatible port trait, blanket impl for Arc<T>, shipped in-memory fake),
# with any extra lines appended. Callers append the boundary violation.
core_lib() {
  cat > "$W/crates/core/src/lib.rs" <<'RS'
pub struct Project { pub id: u32 }
pub trait ProjectsPort: Send + Sync { fn count(&self) -> u32; }
impl<T: ProjectsPort + ?Sized> ProjectsPort for std::sync::Arc<T> {
    fn count(&self) -> u32 { (**self).count() }
}
pub struct InMemoryProjectsPort;
impl ProjectsPort for InMemoryProjectsPort { fn count(&self) -> u32 { 0 } }
RS
  if [ "$#" -gt 0 ]; then
    printf '%s\n' "$@" >> "$W/crates/core/src/lib.rs"
  fi
}

write_sources() {
  core_lib
  cat > "$W/crates/cli/src/lib.rs" <<'RS'
use rs_launch_blueprint_core::ProjectsPort;
pub fn run<P: ProjectsPort>(p: &P) -> u32 { p.count() }
RS
  cat > "$W/crates/web/src/lib.rs" <<'RS'
use rs_launch_blueprint_core::ProjectsPort;
pub fn router<P: ProjectsPort>(p: &P) -> u32 { p.count() }
RS
  cat > "$W/src/lib.rs" <<'RS'
pub mod composition {
    use rs_launch_blueprint_core::{InMemoryProjectsPort, ProjectsPort};
    pub fn production_service() -> std::sync::Arc<dyn ProjectsPort> {
        std::sync::Arc::new(InMemoryProjectsPort)
    }
}
RS
  cat > "$W/src/main.rs" <<'RS'
fn main() {
    let svc = rs_launch_blueprint::composition::production_service();
    let _ = rs_launch_blueprint_cli::run(&svc);
}
RS
  cat > "$W/src/bin/serve.rs" <<'RS'
fn main() {
    let svc = rs_launch_blueprint::composition::production_service();
    let _ = rs_launch_blueprint_web::router(&svc);
}
RS
}

write_manifests
write_sources

note "B1 default build (root package scope, web feature off)"
( cd "$W" && cargo build --offline ) > "$LOGD/b1.log" 2>&1 || true
cat "$LOGD/b1.log"
ok B1 "the default root-scoped build succeeds" "$LOGD/b1.log" "Finished"
absent B1 "the optional web member is not compiled by a root-scoped default build" \
  "$LOGD/b1.log" "Compiling rs-launch-blueprint-web"

note "B2 --features web (root package scope)"
( cd "$W" && cargo build --offline --features web ) > "$LOGD/b2.log" 2>&1 || true
cat "$LOGD/b2.log"
ok B2 "enabling the feature pulls the optional member in" "$LOGD/b2.log" \
  "Compiling rs-launch-blueprint-web" "Finished"

note "B3 cargo build --workspace with the web feature OFF (case the Opus raw did not run)"
( cd "$W" && cargo clean --offline >/dev/null 2>&1 || true )
( cd "$W" && cargo build --offline --workspace ) > "$LOGD/b3.log" 2>&1 || true
cat "$LOGD/b3.log"
ok B3 "a workspace-scoped build succeeds" "$LOGD/b3.log" "Finished"
ok B3 "workspace membership, not the root feature, decides that crates/web is built: --workspace compiles it with web off" \
  "$LOGD/b3.log" "Compiling rs-launch-blueprint-web"

note "B4 binary targets actually produced by the default build"
( cd "$W" && cargo clean --offline >/dev/null 2>&1 || true )
( cd "$W" && cargo build --offline ) > /dev/null 2>&1 || true
ls "$W/target/debug" > "$LOGD/b4.log" 2>&1 || true
cat "$LOGD/b4.log"
ok B4 "the rslbp binary is built by default" "$LOGD/b4.log" "rslbp"
absent B4 "the feature-gated serve binary is skipped by default (required-features)" \
  "$LOGD/b4.log" "rslbp-serve"

############################################################################
# C. The four boundary violations
############################################################################
note "C1 F004 -- core names the cli crate in code"
core_lib 'pub fn oops() -> u32 { rs_launch_blueprint_cli::run(&InMemoryProjectsPort) }'
( cd "$W" && cargo build --offline ) > "$LOGD/c1.log" 2>&1 || true
cat "$LOGD/c1.log"
ok C1 "F004 is a build error at the code tier" "$LOGD/c1.log" \
  "error[E0433]" "rs_launch_blueprint_cli" "could not compile"
write_sources

note "C2 F004 -- core declares the cli crate in its manifest"
cat > "$W/crates/core/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-core"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]
rs-launch-blueprint-cli = { path = "../cli", version = "0.1.0" }

[lints]
workspace = true
TOML
( cd "$W" && cargo build --offline ) > "$LOGD/c2.log" 2>&1 || true
cat "$LOGD/c2.log"
ok C2 "F004 is refused by Cargo resolution before rustc runs" "$LOGD/c2.log" \
  "cyclic package dependency"
write_manifests

note "C3 F005 -- cli names the web crate"
cat > "$W/crates/cli/src/lib.rs" <<'RS'
use rs_launch_blueprint_core::ProjectsPort;
pub fn run<P: ProjectsPort>(p: &P) -> u32 { rs_launch_blueprint_web::router(p) }
RS
( cd "$W" && cargo build --offline ) > "$LOGD/c3.log" 2>&1 || true
cat "$LOGD/c3.log"
ok C3 "F005 is a build error" "$LOGD/c3.log" "error[E0433]" "rs_launch_blueprint_web"
write_sources

note "C4 F003 -- core names the facade's composition root"
core_lib 'pub fn oops() { let _ = rs_launch_blueprint::composition::production_service(); }'
( cd "$W" && cargo build --offline ) > "$LOGD/c4.log" 2>&1 || true
cat "$LOGD/c4.log"
ok C4 "F003 is a build error" "$LOGD/c4.log" "error[E0433]" "rs_launch_blueprint"
write_sources

note "C5 baseline restored"
( cd "$W" && cargo build --offline ) > "$LOGD/c5.log" 2>&1 || true
cat "$LOGD/c5.log"
ok C5 "the restored workspace builds clean" "$LOGD/c5.log" "Finished"
absent C5 "no error survives the restore" "$LOGD/c5.log" "error["

############################################################################
# D. clippy.toml scope -- F009's fast mirror
############################################################################
note "D1 package-root clippy.toml in the SINGLE package flags every layer"
cat > "$PROBE/single/clippy.toml" <<'TOML'
disallowed-types = [
  { path = "std::collections::HashMap", reason = "probe" },
]
TOML
cat > "$PROBE/single/src/core_layer.rs" <<'RS'
use std::collections::HashMap;
pub fn m() -> HashMap<u32, u32> { HashMap::new() }
RS
cat > "$PROBE/single/src/cli_layer.rs" <<'RS'
use std::collections::HashMap;
pub struct CliThing;
pub fn m() -> HashMap<u32, u32> { HashMap::new() }
RS
( cd "$PROBE/single" && cargo clippy --offline -- -D clippy::disallowed_types ) \
  > "$LOGD/d1.log" 2>&1 || true
cat "$LOGD/d1.log"
ok D1 "a package-root clippy.toml cannot be scoped to one layer" "$LOGD/d1.log" \
  "disallowed type" "src/core_layer.rs" "src/cli_layer.rs"

note "D2 a nested src/clippy.toml (py's subtree shape) is IGNORED"
mv "$PROBE/single/clippy.toml" "$PROBE/single/src/clippy.toml"
( cd "$PROBE/single" && cargo clean --offline >/dev/null 2>&1 || true )
( cd "$PROBE/single" && cargo clippy --offline -- -D clippy::disallowed_types ) \
  > "$LOGD/d2.log" 2>&1 || true
cat "$LOGD/d2.log"
count D2 "a subtree-scoped clippy.toml produces no disallowed-type diagnostic" \
  "$LOGD/d2.log" "disallowed type" 0
ok D2 "the crate still compiles, so the zero is not a compile failure" "$LOGD/d2.log" "Finished"
rm -f "$PROBE/single/src/clippy.toml"

note "D3 a per-member crates/core/clippy.toml flags ONLY that member"
cat > "$W/crates/core/clippy.toml" <<'TOML'
disallowed-types = [
  { path = "std::collections::HashMap", reason = "core is framework- and container-agnostic (F009)" },
]
TOML
core_lib 'pub fn m() -> std::collections::HashMap<u32, u32> { std::collections::HashMap::new() }'
cat > "$W/crates/cli/src/lib.rs" <<'RS'
use std::collections::HashMap;
use rs_launch_blueprint_core::ProjectsPort;
pub fn run<P: ProjectsPort>(p: &P) -> u32 { p.count() }
pub fn m() -> HashMap<u32, u32> { HashMap::new() }
RS
( cd "$W" && cargo clean --offline >/dev/null 2>&1 || true )
( cd "$W" && cargo clippy --offline --workspace ) > "$LOGD/d3.log" 2>&1 || true
cat "$LOGD/d3.log"
ok D3 "the rule fires inside the protected member" "$LOGD/d3.log" \
  "disallowed type" "crates/core/src/lib.rs"
absent D3 "the identical use in the CLI member is untouched" "$LOGD/d3.log" "crates/cli/src/lib.rs"
rm -f "$W/crates/core/clippy.toml"
write_sources

############################################################################
# E. [workspace.lints] inheritance
############################################################################
note "E workspace.lints reaches a member from one place"
/usr/bin/sed -i '' 's/^unreachable_pub = "allow"$/unreachable_pub = "deny"/' "$W/Cargo.toml"
core_lib 'mod private_mod { pub struct Leaked; }'
( cd "$W" && cargo clean --offline >/dev/null 2>&1 || true )
( cd "$W" && cargo build --offline -p rs-launch-blueprint-core ) > "$LOGD/e.log" 2>&1 || true
cat "$LOGD/e.log"
ok E "a root [workspace.lints] deny reaches the member through [lints] workspace = true" \
  "$LOGD/e.log" "unreachable" "could not compile"
write_manifests
write_sources

############################################################################
# F. cargo metadata --no-deps is the declared edge set (F010)
############################################################################
note "F cargo metadata --no-deps intra-workspace edge set"
( cd "$W" && cargo metadata --offline --format-version 1 --no-deps ) > "$LOGD/f.json" 2>&1
python3 - "$LOGD/f.json" > "$LOGD/f.log" <<'PY'
import json, sys
meta = json.load(open(sys.argv[1]))
names = {p["name"] for p in meta["packages"]}
for p in sorted(meta["packages"], key=lambda p: p["name"]):
    edges = sorted(
        "%s%s%s" % (d["name"], "[opt]" if d.get("optional") else "",
                    "" if d.get("kind") in (None, "normal") else "[%s]" % d["kind"])
        for d in p["dependencies"] if d["name"] in names
    )
    print("%-28s -> %s" % (p["name"], edges))
PY
cat "$LOGD/f.log"
ok F "the manifests project to exactly the intended four-row edge set" "$LOGD/f.log" \
  "rs-launch-blueprint          -> ['rs-launch-blueprint-cli', 'rs-launch-blueprint-core', 'rs-launch-blueprint-web[opt]']" \
  "rs-launch-blueprint-cli      -> ['rs-launch-blueprint-core']" \
  "rs-launch-blueprint-core     -> []" \
  "rs-launch-blueprint-web      -> ['rs-launch-blueprint-core']"

############################################################################
# G. cargo tree -i on a crate that is not in the tree
############################################################################
note "G cargo tree -i axum on a clean tree"
set +e
( cd "$W" && cargo tree --offline -p rs-launch-blueprint-core -i axum ) > "$LOGD/g.log" 2>&1
G_STATUS=$?
set -e
cat "$LOGD/g.log"
printf 'exit status: %s\n' "$G_STATUS"
CHECKS=$((CHECKS + 1))
if [ "$G_STATUS" -ne 0 ]; then
  printf 'PASS G: a CLEAN tree makes cargo tree -i exit non-zero (%s), so the check must be inverted\n' "$G_STATUS"
else
  printf 'FAIL G: expected a non-zero exit from cargo tree -i on a clean tree, got 0\n'
  FAILURES=$((FAILURES + 1))
fi
ok G "and it says why" "$LOGD/g.log" "did not match any packages"

############################################################################
# H. Option 2 of the OVERRIDE: does R69's value survive without crates/web?
############################################################################
note "H R69-literal shape -- web module and its optional deps inside the binary-hosting package"
H="$PROBE/r69"
mkdir -p "$H/src/web" "$H/src/bin" "$H/crates/core/src" "$H/crates/cli/src"
cat > "$H/Cargo.toml" <<'TOML'
[workspace]
members = ["crates/*"]
resolver = "3"

[workspace.package]
version = "0.1.0"
edition = "2024"
license = "MIT OR Apache-2.0"

[package]
name = "rs-launch-blueprint"
version.workspace = true
edition.workspace = true
license.workspace = true
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
web = []

[dependencies]
rs-launch-blueprint-core = { path = "crates/core", version = "0.1.0" }
rs-launch-blueprint-cli = { path = "crates/cli", version = "0.1.0" }
TOML
cat > "$H/crates/core/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-core"
version.workspace = true
edition.workspace = true
license.workspace = true
TOML
cat > "$H/crates/cli/Cargo.toml" <<'TOML'
[package]
name = "rs-launch-blueprint-cli"
version.workspace = true
edition.workspace = true
license.workspace = true

[dependencies]
rs-launch-blueprint-core = { path = "../core", version = "0.1.0" }
TOML
cat > "$H/crates/core/src/lib.rs" <<'RS'
pub trait ProjectsPort: Send + Sync { fn count(&self) -> u32; }
RS
cat > "$H/crates/cli/src/lib.rs" <<'RS'
use rs_launch_blueprint_core::ProjectsPort;
pub fn run<P: ProjectsPort>(p: &P) -> u32 { p.count() }
RS
cat > "$H/src/web/mod.rs" <<'RS'
pub struct AppState;
pub fn build_router() -> u32 { rs_launch_blueprint_cli::run(&Fake) as u32 }
struct Fake;
impl rs_launch_blueprint_core::ProjectsPort for Fake { fn count(&self) -> u32 { 0 } }
RS
cat > "$H/src/lib.rs" <<'RS'
#[cfg(feature = "web")]
pub mod web;
pub mod composition {
    pub fn production_service() -> u32 { 0 }
}
RS
cat > "$H/src/main.rs" <<'RS'
fn main() { let _ = rs_launch_blueprint::composition::production_service(); }
RS
cat > "$H/src/bin/serve.rs" <<'RS'
fn main() { let _ = rs_launch_blueprint::web::build_router(); }
RS
( cd "$H" && cargo build --offline --features web ) > "$LOGD/h.log" 2>&1 || true
cat "$LOGD/h.log"
ok H "the R69-literal shape builds: src/web/ is a gated module of the binary-hosting package" \
  "$LOGD/h.log" "Finished"
absent H "and nothing stops that web module naming the CLI front-end crate, so F005's web->cli half is NOT a build error under this shape" \
  "$LOGD/h.log" "error["

note "SUMMARY"
printf 'CHECKS RUN: %s FAILURES: %s\n' "$CHECKS" "$FAILURES"
[ "$FAILURES" -eq 0 ]
