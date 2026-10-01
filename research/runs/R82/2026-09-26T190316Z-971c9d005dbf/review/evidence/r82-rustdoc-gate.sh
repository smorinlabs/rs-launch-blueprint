#!/usr/bin/env bash
# R82 revision 1 synthesis: rustdoc API-reference gate (member F353).
# Builds two offline fixture workspaces and runs one mutation per case on the
# current stable (Homebrew 1.98.1) and the MSRV floor (rustup 1.96.0).
#   Layout A = R69 revision 9 as registered: the root package hosts the binaries
#              and declares feature `web`, which gates the in-crate module src/web/.
#              One member, crates/core.
#   Layout B = the member layout R11's note describes for R69 revision 10 (and
#              the Opus leg's fixture): root facade + crates/{core,cli,web}, feature
#              `web = ["dep:rslb-web"]`, plus a nested `otel = ["web"]` feature
#              standing in for R78.
# axum/tokio are not fetched (no registry access); the `web` feature is modelled
# by what it gates, not by its dependencies.
# Usage: bash r82-rustdoc-gate.sh > r82-rustdoc-gate.log 2>&1
# shellcheck disable=SC2016 # backticks in mutations are literal rustdoc link syntax
set -euo pipefail

export CARGO_HOME="${CARGO_HOME:?private CARGO_HOME must be set}"
export CARGO_NET_OFFLINE=true
export CARGO_TERM_COLOR=never
unset RUSTDOCFLAGS RUSTFLAGS

scratch="$(mktemp -d)"
trap 'rm -rf "$scratch"' EXIT

toolchains=("stable-homebrew" "floor-1.96.0")

tc_run() { # tc_run <toolchain> <cmd...>
  local tc="$1"; shift
  case "$tc" in
    stable-homebrew)
      PATH="/opt/homebrew/bin:$PATH" RUSTC=/opt/homebrew/bin/rustc RUSTDOC=/opt/homebrew/bin/rustdoc "$@" ;;
    floor-1.96.0)
      rustup run 1.96.0 "$@" ;;
  esac
}

scrub() { sed -e "s#$scratch#<scratch>#g"; }

echo "# r82-rustdoc-gate — run $(date -u +%Y-%m-%dT%H:%M:%SZ)"
echo "# host: $(uname -srm)"
echo "# CARGO_HOME set: yes (private); CARGO_NET_OFFLINE=true"
for tc in "${toolchains[@]}"; do
  echo "# $tc: $(tc_run "$tc" cargo --version) | $(tc_run "$tc" rustdoc --version)"
done
echo

# ---------- fixture A (R69 revision 9 layout) ----------
mkA() {
  local d="$1"
  mkdir -p "$d/src/web" "$d/src/bin" "$d/crates/core/src"
  cat > "$d/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/core"]
resolver = "3"

[package]
name = "rslb"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[features]
web = []

[dependencies]
rslb-core = { path = "crates/core" }

[[bin]]
name = "rslb-serve"
path = "src/bin/serve.rs"
required-features = ["web"]
EOF
  cat > "$d/src/lib.rs" <<'EOF'
//! Facade for the template. See [`rslb_core::greet`].
pub use rslb_core::greet;

#[cfg(feature = "web")]
pub mod web;
EOF
  cat > "$d/src/web/mod.rs" <<'EOF'
//! Web surface, gated by the `web` feature.

/// Serve the router. Uses [`crate::greet`].
pub fn serve() {}
EOF
  cat > "$d/src/main.rs" <<'EOF'
fn main() { println!("{}", rslb::greet()); }
EOF
  cat > "$d/src/bin/serve.rs" <<'EOF'
fn main() { rslb::web::serve(); }
EOF
  cat > "$d/crates/core/Cargo.toml" <<'EOF'
[package]
name = "rslb-core"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
EOF
  cat > "$d/crates/core/src/lib.rs" <<'EOF'
//! Core library.

/// Returns a greeting. See [`helper`].
///
/// ```
/// assert_eq!(rslb_core::greet(), "hello");
/// ```
pub fn greet() -> &'static str { helper() }

/// Internal helper.
pub fn helper() -> &'static str { "hello" }
EOF
  (cd "$d" && tc_run stable-homebrew cargo generate-lockfile --offline -q)
}

# ---------- fixture B (member layout, R69 revision 10 / Opus fixture) ----------
mkB() {
  local d="$1"
  mkdir -p "$d/src" "$d/crates/core/src" "$d/crates/cli/src" "$d/crates/web/src"
  cat > "$d/Cargo.toml" <<'EOF'
[workspace]
members = ["crates/core", "crates/cli", "crates/web"]
resolver = "3"

[package]
name = "rslb"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"

[features]
web = ["dep:rslb-web"]
otel = ["web"]

[dependencies]
rslb-core = { path = "crates/core" }
rslb-web = { path = "crates/web", optional = true }
EOF
  cat > "$d/src/lib.rs" <<'EOF'
//! Facade. See [`rslb_core::greet`].
pub use rslb_core::greet;

#[cfg(feature = "web")]
pub use rslb_web as web;

/// Telemetry hooks, gated by `otel` (stands in for R78).
#[cfg(feature = "otel")]
pub mod otel {
    /// Install the exporter. See [`crate::greet`].
    pub fn install() {}
}
EOF
  for m in core cli web; do
    cat > "$d/crates/$m/Cargo.toml" <<EOF
[package]
name = "rslb-$m"
version = "0.1.0"
edition = "2024"
rust-version = "1.96"
license = "MIT OR Apache-2.0"
EOF
  done
  cat > "$d/crates/core/src/lib.rs" <<'EOF'
//! Core library.

/// Returns a greeting.
pub fn greet() -> &'static str { "hello" }
EOF
  cat > "$d/crates/cli/src/lib.rs" <<'EOF'
//! CLI library.

/// Run the CLI.
pub fn run() {}
EOF
  cat > "$d/crates/web/src/lib.rs" <<'EOF'
//! Web member.

/// Serve the router.
pub fn serve() {}
EOF
  (cd "$d" && tc_run stable-homebrew cargo generate-lockfile --offline -q)
}

mkA "$scratch/cleanA"
mkB "$scratch/cleanB"

# case <id> <toolchain> <layout> <mutation-fn|none> <RUSTDOCFLAGS or -> <cargo args...>
case_run() {
  local id="$1" tc="$2" layout="$3" mut="$4" flags="$5"; shift 5
  local d="$scratch/$id-$tc"
  cp -R "$scratch/clean$layout" "$d"
  if [ "$mut" != none ]; then "$mut" "$d"; fi
  local rc=0 out
  if [ "$flags" = - ]; then
    out="$(cd "$d" && tc_run "$tc" cargo "$@" 2>&1)" || rc=$?
  else
    out="$(cd "$d" && RUSTDOCFLAGS="$flags" tc_run "$tc" cargo "$@" 2>&1)" || rc=$?
  fi
  printf '%-4s %-16s layout=%s mut=%-18s RUSTDOCFLAGS=%-12q cargo %s\n' "$id" "$tc" "$layout" "$mut" "$flags" "$*"
  printf '     exit=%s\n' "$rc"
  printf '%s\n' "$out" | grep -E '^(error|warning)(\[|:)|^note: `-D|implied by' | sort -u | scrub | sed 's/^/     | /' || true
  rm -rf "$d"
}

# mutations
m_core_broken()    { sed -i '' 's/See \[`helper`\]/See [`Nope`]/' "$1/crates/core/src/lib.rs"; }
m_web_broken()     { sed -i '' 's/Uses \[`crate::greet`\]/Uses [`crate::Missing`]/' "$1/src/web/mod.rs"; }
m_private_broken() { printf '\n/// Private. See [`AlsoNope`].\nfn _private() {}\n' >> "$1/crates/core/src/lib.rs"; }
m_unused_import()  { printf '\nuse std::collections::HashMap;\n' >> "$1/crates/core/src/lib.rs"; }
m_bare_url()       { printf '\n/// See https://example.com/spec for details.\npub fn spec() {}\n' >> "$1/crates/core/src/lib.rs"; }
m_pub_to_private() { printf '\n/// Links to [`hidden`].\npub fn exposed() {}\nfn hidden() {}\n' >> "$1/crates/core/src/lib.rs"; }
m_otel_broken()    { sed -i '' 's/See \[`crate::greet`\]/See [`crate::NoExporter`]/' "$1/src/lib.rs"; }
m_core_broken_b()  { sed -i '' 's/Returns a greeting\./Returns a greeting. See [`Nope`]./' "$1/crates/core/src/lib.rs"; }
m_facade_webref()  { printf '\n/// Entry point: [`web::serve`].\npub fn entry() {}\n' >> "$1/src/lib.rs"; }

DOC=(doc --locked --workspace --no-deps)

for tc in "${toolchains[@]}"; do
  echo "## toolchain $tc"
  echo "### G0 rustdoc lint inventory (rustdoc -W help)"
  lints="$(tc_run "$tc" rustdoc -W help | grep -E '^ +rustdoc::[a-z-]+ ' || true)"
  echo "G0   rustdoc:: lints: $(printf '%s\n' "$lints" | grep -vc 'rustdoc::all' || true) (allow: $(printf '%s\n' "$lints" | grep -c ' allow ' || true), warn: $(printf '%s\n' "$lints" | grep -c ' warn ' || true))"
  printf '%s\n' "$lints" | awk '$2=="warn"{print "     | warn-by-default " $1}'
  echo "### G1 baseline and the -D warnings gate (both legs agree)"
  case_run G1a "$tc" A none           "-D warnings" "${DOC[@]}" --all-features
  case_run G1b "$tc" A m_core_broken  -             "${DOC[@]}" --all-features
  case_run G1c "$tc" A m_core_broken  "-D warnings" "${DOC[@]}" --all-features
  echo "### G2 --workspace (the Muse command omits it; broken link in member crates/core)"
  case_run G2a "$tc" A m_core_broken  "-D warnings" doc --no-deps --all-features
  case_run G2b "$tc" A m_core_broken  "-D warnings" doc --locked --no-deps --all-features
  case_run G2c "$tc" B m_core_broken_b "-D warnings" doc --locked --no-deps --all-features
  case_run G2d "$tc" B m_core_broken_b "-D warnings" "${DOC[@]}" --all-features
  echo "### G3 feature-gated in-crate module (layout A, R69 revision 9)"
  case_run G3a "$tc" A m_web_broken   "-D warnings" "${DOC[@]}"
  case_run G3b "$tc" A m_web_broken   "-D warnings" "${DOC[@]}" --features web
  case_run G3c "$tc" A m_web_broken   "-D warnings" "${DOC[@]}" --all-features
  echo "### G4 facade link into the web re-export (layout B)"
  case_run G4a "$tc" B m_facade_webref "-D warnings" "${DOC[@]}"
  case_run G4b "$tc" B m_facade_webref "-D warnings" "${DOC[@]}" --features web
  case_run G4c "$tc" B m_facade_webref "-D warnings" "${DOC[@]}" --all-features
  echo "### G5 nested feature (otel = [\"web\"], stands in for R78): --features web vs --all-features"
  case_run G5a "$tc" B m_otel_broken  "-D warnings" "${DOC[@]}" --features web
  case_run G5b "$tc" B m_otel_broken  "-D warnings" "${DOC[@]}" --all-features
  echo "### G6 private items"
  case_run G6a "$tc" A m_private_broken "-D warnings" "${DOC[@]}" --all-features
  case_run G6b "$tc" A m_private_broken "-D warnings" "${DOC[@]}" --all-features --document-private-items
  case_run G6c "$tc" A m_pub_to_private "-D warnings" "${DOC[@]}" --all-features
  case_run G6d "$tc" A m_pub_to_private "-D warnings" "${DOC[@]}" --all-features --document-private-items
  echo "### G7 does -D warnings on the doc build deny rustc lints (Muse claim)? unused import"
  case_run G7a "$tc" A m_unused_import "-D warnings" "${DOC[@]}" --all-features
  case_run G7b "$tc" A m_unused_import "-D warnings" "${DOC[@]}" --all-features --document-private-items
  echo "### G8 bare URL (warn-by-default rustdoc lint)"
  case_run G8a "$tc" A m_bare_url     "-D warnings" "${DOC[@]}" --all-features
  echo "### G9 RUSTDOCFLAGS reaches the doctest step (job-level env would leak into it)"
  case_run G9a "$tc" A m_bare_url     -             test --locked --doc -p rslb-core
  case_run G9b "$tc" A m_bare_url     "-D warnings" test --locked --doc -p rslb-core
  d="$scratch/G9c-$tc"; cp -R "$scratch/cleanA" "$d"
  n="$(cd "$d" && RUSTDOCFLAGS="-D warnings" tc_run "$tc" cargo test --locked --doc -p rslb-core -v 2>&1 | grep -E 'Running `.*rustdoc.* --test ' | grep -c -- '-D warnings' || true)"
  echo "G9c  $tc rustdoc --test argv lines carrying -D warnings: $n"
  rm -rf "$d"
  echo "### G10 --features web vs --all-features share one doc unit when they resolve to the same feature set (layout A)"
  d="$scratch/G10-$tc"; cp -R "$scratch/cleanA" "$d"
  (cd "$d" && RUSTDOCFLAGS="-D warnings" tc_run "$tc" cargo "${DOC[@]}" --features web -q 2>&1) >/dev/null
  out="$(cd "$d" && RUSTDOCFLAGS="-D warnings" tc_run "$tc" cargo "${DOC[@]}" --all-features -v 2>&1)"
  echo "G10  $tc second run (--all-features after --features web): Fresh=$(printf '%s\n' "$out" | grep -c '^ *Fresh ' || true) Documenting=$(printf '%s\n' "$out" | grep -c '^ *Documenting ' || true)"
  rm -rf "$d"
  echo
done

