#!/usr/bin/env bash
# shellcheck disable=SC2016
#   File-wide: the expected-output strings asserted below are literals, quoted
#   exactly as rustc and the crates print them (they contain `backticks` and
#   $-free text that must never expand).
# R77 — empirical check, part 3 of 3: the Rust probes.
#
# Re-verifies, against real published crates at exact versions, the executed
# claims raw/opus.md makes and that R77's DECISION.md relies on:
#   P1  the const-fn derivation of RSLBP_WEB_ from R57 revision 2's TOOL_NAME
#   P2  edition 2024 makes std::env::set_var unsafe (with an edition-2021 control)
#   P3  the Display string of one malformed variable through five mechanisms,
#       once with the process environment carrying it and once with only an
#       injected map carrying it (the injection-seam test)
#   P4  four tests over real axum 0.8.9 + tokio 1.53.1 + tower 0.5.3
#   P5  confique 0.4.0 rejects a non-literal env attribute
#   P6  normal-dependency package counts and stripped release binary sizes
#
# It builds nothing in the repository and writes no Rust file into it: every
# crate below is created under a $TMPDIR directory this script makes and
# removes. It is a verification of the research, NOT an implementation of the
# recommendation.
set -euo pipefail
set -o pipefail

pass=0; fail=0; skip=0
ok()   { pass=$((pass+1)); printf 'PASS %s\n' "$1"; }
no()   { fail=$((fail+1)); printf 'FAIL %s\n' "$1"; }
sk()   { skip=$((skip+1)); printf 'SKIP %s\n' "$1"; }
# assert <label> <expected-substring> <actual>
assert_has() {
  if printf '%s' "$3" | /usr/bin/grep -qF -- "$2"; then ok "$1"; else
    no "$1"; printf '     expected substring: %s\n     actual: %s\n' "$2" "$3"; fi
}
assert_eq() {
  if [ "$2" = "$3" ]; then ok "$1"; else
    no "$1"; printf '     expected: %s\n     actual:   %s\n' "$2" "$3"; fi
}

printf '# R77 probes — %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
printf '# /usr/bin/grep version: %s\n' "$(/usr/bin/grep --version | head -1)"

if ! command -v cargo >/dev/null 2>&1 || ! command -v rustc >/dev/null 2>&1; then
  sk "P1..P6 — cargo/rustc not on PATH"
  printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
  [ "$fail" -eq 0 ] || exit 1
  exit 0
fi
printf '# rustc: %s\n# cargo: %s\n# host: %s\n' \
  "$(rustc --version)" "$(cargo --version)" "$(uname -sm)"

W=$(mktemp -d "${TMPDIR:-/tmp}/r77-probes.XXXXXX")
trap 'rm -rf "$W"' EXIT

# cargo needs the registry; prefer the local cache, fall back to the network.
OFF=--offline
probe_dep_ok=1
mkdir -p "$W/net/src"; printf 'fn main() {}\n' > "$W/net/src/main.rs"
cat > "$W/net/Cargo.toml" <<'EOF'
[package]
name = "netprobe"
version = "0.0.0"
edition = "2024"
publish = false
[dependencies]
serde = { version = "=1.0.229", features = ["derive"] }
envy = "=0.4.2"
config = { version = "=0.15.25", default-features = false }
figment = { version = "=0.10.19", features = ["env"] }
confique = "=0.4.0"
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
http-body-util = "0.1"
[workspace]
EOF
if ! cargo fetch --offline --manifest-path "$W/net/Cargo.toml" >/dev/null 2>&1; then
  if cargo fetch --manifest-path "$W/net/Cargo.toml" >/dev/null 2>&1; then OFF=""; else probe_dep_ok=0; fi
fi

# The shared const-fn prelude, written once to a file (bash 3.2 here: a
# heredoc inside $( ) is not reliable, so no command substitution is used).
cat > "$W/prelude.rs" <<'RS'
pub const TOOL_NAME: &str = "rslbp";   // R57 revision 2's single namespace segment
const SUFFIX: &str = "_WEB_";
const fn upper_concat<const N: usize>(name: &str, suffix: &str) -> [u8; N] {
    let (n, s) = (name.as_bytes(), suffix.as_bytes());
    let mut out = [0u8; N];
    let mut i = 0;
    while i < n.len() { out[i] = n[i].to_ascii_uppercase(); i += 1; }
    let mut j = 0;
    while j < s.len() { out[i + j] = s[j].to_ascii_uppercase(); j += 1; }
    out
}
const PREFIX_LEN: usize = TOOL_NAME.len() + SUFFIX.len();
const PREFIX_BYTES: [u8; PREFIX_LEN] = upper_concat::<PREFIX_LEN>(TOOL_NAME, SUFFIX);
pub const WEB_ENV_PREFIX: &str = match core::str::from_utf8(&PREFIX_BYTES) {
    Ok(s) => s,
    Err(_) => panic!("app name must be ASCII"),
};
RS

manifest() { # $1 dir  $2 name  $3 extra-deps  $4 extra-sections
  mkdir -p "$W/$1/src"
  { printf '[package]\nname = "%s"\nversion = "0.0.0"\nedition = "2024"\npublish = false\n' "$2"
    printf '[[bin]]\nname = "%s"\npath = "src/main.rs"\n[dependencies]\n%s\n%s\n[workspace]\n' "$2" "$3" "$4"
  } > "$W/$1/Cargo.toml"
}

############################################################################
echo; echo '## P1 — const-fn prefix derived from R57 revision 2 TOOL_NAME'
manifest p1 p1 '' ''
{ printf '#![forbid(unsafe_code)]\n'; cat "$W/prelude.rs"
  cat <<'RS'
const FORK_NAME: &str = "acme";           // a fork renames the one constant
const FORK_LEN: usize = FORK_NAME.len() + SUFFIX.len();
const FORK_BYTES: [u8; FORK_LEN] = upper_concat::<FORK_LEN>(FORK_NAME, SUFFIX);
pub const FORK_ENV_PREFIX: &str = match core::str::from_utf8(&FORK_BYTES) {
    Ok(s) => s, Err(_) => panic!("app name must be ASCII"),
};
// evaluated in const context: a wrong value is a compile error, not a test failure
const _: () = assert!(matches!(WEB_ENV_PREFIX.as_bytes(), b"RSLBP_WEB_"));
const _: () = assert!(matches!(FORK_ENV_PREFIX.as_bytes(), b"ACME_WEB_"));
fn main() {
    println!("WEB_ENV_PREFIX={WEB_ENV_PREFIX}");
    println!("FORK_ENV_PREFIX={FORK_ENV_PREFIX}");
    println!("PROBE-P1 OK (const-derived prefix, no unsafe, stable)");
}
RS
} > "$W/p1/src/main.rs"
p1out=$(cargo run --quiet $OFF --manifest-path "$W/p1/Cargo.toml" 2>&1 || true)
printf '%s\n' "$p1out"
assert_has "P1.a WEB_ENV_PREFIX is RSLBP_WEB_"            'WEB_ENV_PREFIX=RSLBP_WEB_'  "$p1out"
assert_has "P1.b renaming TOOL_NAME alone gives ACME_WEB_" 'FORK_ENV_PREFIX=ACME_WEB_' "$p1out"
assert_has "P1.c compiles under #![forbid(unsafe_code)]"   'PROBE-P1 OK'               "$p1out"

############################################################################
echo; echo '## P2 — edition 2024 makes std::env::set_var unsafe (2021 control)'
manifest p2 p2 '' ''
printf 'fn main() {\n    std::env::set_var("RSLBP_WEB_PORT", "8000");\n    println!("{:?}", std::env::var("RSLBP_WEB_PORT"));\n}\n' > "$W/p2/src/main.rs"
p2out=$(cargo build --quiet $OFF --manifest-path "$W/p2/Cargo.toml" 2>&1 || true)
printf '%s\n' "$p2out" | head -8
assert_has "P2.a edition 2024 rejects set_var" \
  'error[E0133]: call to unsafe function `set_var` is unsafe and requires unsafe block' "$p2out"
/usr/bin/sed -i.bak 's/edition = "2024"/edition = "2021"/' "$W/p2/Cargo.toml"
p2ctl=$(cargo run --quiet $OFF --manifest-path "$W/p2/Cargo.toml" 2>&1 || true)
printf 'edition-2021 control: %s\n' "$p2ctl"
assert_has "P2.b the same source compiles under edition 2021 (the edition, not the API, is the change)" \
  'Ok("8000")' "$p2ctl"

############################################################################
echo; echo '## P5 — confique 0.4.0 requires a string literal in #[config(env = ...)]'
if [ "$probe_dep_ok" -eq 0 ]; then sk "P5 — candidate crates unavailable (no cache, no network)"; else
manifest p5 p5 'serde = { version = "=1.0.229", features = ["derive"] }
confique = "=0.4.0"' ''
cat > "$W/p5/src/main.rs" <<'RS'
const ENV_PORT: &str = "RSLBP_WEB_PORT";
#[derive(Debug, confique::Config)]
struct S { #[config(env = ENV_PORT, default = 8000)] port: u16 }
fn main() { println!("{:?}", <S as confique::Config>::builder().env().load()); }
RS
p5out=$(cargo build --quiet $OFF --manifest-path "$W/p5/Cargo.toml" 2>&1 || true)
printf '%s\n' "$p5out" | head -6
assert_has "P5 confique rejects a const env name" 'error: expected string literal' "$p5out"
fi

############################################################################
echo; echo '## P3 — one malformed variable through five mechanisms'
if [ "$probe_dep_ok" -eq 0 ]; then sk "P3 — candidate crates unavailable (no cache, no network)"; else
manifest p3 p3 'serde = { version = "=1.0.229", features = ["derive"] }
envy = "=0.4.2"
config = { version = "=0.15.25", default-features = false }
figment = { version = "=0.10.19", features = ["env"] }
confique = "=0.4.0"' ''
{ printf '#![forbid(unsafe_code)]\nuse std::collections::HashMap;\nuse std::net::IpAddr;\n'; cat "$W/prelude.rs"
  cat <<'RS'
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WebSettings { pub host: IpAddr, pub port: u16 }
impl Default for WebSettings {
    fn default() -> Self { Self { host: "127.0.0.1".parse().unwrap(), port: 8000 } }
}
#[derive(Debug)]
pub struct SettingsError { pub var: String, pub value: String, pub expected: &'static str, pub cause: String }
impl std::fmt::Display for SettingsError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: invalid value {:?}: expected {} ({})", self.var, self.value, self.expected, self.cause)
    }
}
fn one<T: std::str::FromStr>(v: &HashMap<String, String>, name: &str, expected: &'static str, default: T)
    -> Result<T, SettingsError> where T::Err: std::fmt::Display {
    let var = format!("{WEB_ENV_PREFIX}{name}");
    match v.get(&var) {
        None => Ok(default),
        Some(raw) if raw.is_empty() => Ok(default),
        Some(raw) => raw.parse::<T>().map_err(|e| SettingsError {
            var, value: raw.clone(), expected, cause: e.to_string() }),
    }
}
fn template_from_vars(v: &HashMap<String, String>) -> Result<WebSettings, SettingsError> {
    let d = WebSettings::default();
    Ok(WebSettings { host: one(v, "HOST", "an IP address to bind", d.host)?,
                     port: one(v, "PORT", "a TCP port in 0..=65535", d.port)? })
}
#[derive(Debug, serde::Deserialize)]
struct SerdeSettings { #[serde(default = "dh")] host: String, #[serde(default = "dp")] port: u16 }
fn dh() -> String { "127.0.0.1".into() }
fn dp() -> u16 { 8000 }
#[derive(Debug, confique::Config)]
struct WebSettingsC {
    #[config(env = "RSLBP_WEB_HOST", default = "127.0.0.1")] host: String,
    #[config(env = "RSLBP_WEB_PORT", default = 8000)] port: u16,
}
fn show(label: &str, r: Result<String, String>) {
    match r { Ok(v) => println!("{label} | OK | {v}"), Err(e) => println!("{label} | ERR | {e}") }
}
fn main() {
    let injected: HashMap<String, String> = [
        ("RSLBP_WEB_HOST".to_string(), "127.0.0.1".to_string()),
        ("RSLBP_WEB_PORT".to_string(), "eighty".to_string()),
    ].into_iter().collect();
    println!("process RSLBP_WEB_PORT={:?}", std::env::var("RSLBP_WEB_PORT").ok());
    show("template-code", template_from_vars(&injected).map(|s| format!("{s:?}")).map_err(|e| e.to_string()));
    show("envy-0.4.2", envy::prefixed(WEB_ENV_PREFIX).from_iter::<_, SerdeSettings>(injected.clone())
        .map(|s| format!("{s:?}")).map_err(|e| e.to_string()));
    show("config-0.15.25", config::Config::builder()
        .add_source(config::Environment::with_prefix(WEB_ENV_PREFIX.trim_end_matches('_'))
            .source(Some(injected.clone())))
        .build().and_then(|c| c.try_deserialize::<SerdeSettings>())
        .map(|s| format!("{s:?}")).map_err(|e| e.to_string()));
    show("figment-0.10.19", figment::Figment::from(figment::providers::Env::prefixed(WEB_ENV_PREFIX))
        .extract::<SerdeSettings>().map(|s| format!("{s:?}")).map_err(|e| e.to_string()));
    show("confique-0.4.0", <WebSettingsC as confique::Config>::builder().env().load()
        .map(|s| format!("{s:?}")).map_err(|e| e.to_string()));
}
RS
} > "$W/p3/src/main.rs"
cargo build --quiet $OFF --manifest-path "$W/p3/Cargo.toml" 2>/dev/null || true

echo '--- P3 run 1: the process environment carries RSLBP_WEB_PORT=eighty ---'
p3a=$(env RSLBP_WEB_HOST=127.0.0.1 RSLBP_WEB_PORT=eighty \
      cargo run --quiet $OFF --manifest-path "$W/p3/Cargo.toml" 2>/dev/null || true)
printf '%s\n' "$p3a"
assert_has "P3.1 template code names variable, value and a domain expectation" \
  'template-code | ERR | RSLBP_WEB_PORT: invalid value "eighty": expected a TCP port in 0..=65535 (invalid digit found in string)' "$p3a"
assert_has "P3.2 envy names PORT without the prefix and gives no expectation" \
  "envy-0.4.2 | ERR | invalid digit found in string while parsing value 'eighty' provided by PORT" "$p3a"
assert_has "P3.3 config names a lowercased key, not the operator's variable" \
  'config-0.15.25 | ERR | invalid type: string "eighty", expected an integer for key `port` in the environment' "$p3a"
assert_has "P3.4 figment names prefix + key" \
  'figment-0.10.19 | ERR | invalid type: found string "eighty", expected u16 for key "PORT" in `RSLBP_WEB_` environment variable(s)' "$p3a"
assert_has "P3.5 confique names the field path and the full variable" \
  "confique-0.4.0 | ERR | failed to deserialize value \`WebSettingsC::port\` from environment variable \`RSLBP_WEB_PORT\`: invalid value 'eighty' for type u16: invalid digit found in string" "$p3a"

echo '--- P3 run 2: the process environment is clean; only the injected map carries it ---'
p3b=$(env -u RSLBP_WEB_HOST -u RSLBP_WEB_PORT \
      cargo run --quiet $OFF --manifest-path "$W/p3/Cargo.toml" 2>/dev/null || true)
printf '%s\n' "$p3b"
assert_has "P3.6 process environment really is clean"  'process RSLBP_WEB_PORT=None' "$p3b"
assert_has "P3.7 template code still fails from the injected map alone" \
  'template-code | ERR | RSLBP_WEB_PORT:' "$p3b"
assert_has "P3.8 envy has an injected-iterator seam"   'envy-0.4.2 | ERR |'     "$p3b"
assert_has "P3.9 config has an injected-source seam"   'config-0.15.25 | ERR |' "$p3b"
assert_has "P3.10 figment has NO injected seam: it silently returns defaults" \
  'figment-0.10.19 | OK | SerdeSettings { host: "127.0.0.1", port: 8000 }' "$p3b"
assert_has "P3.11 confique has NO injected seam: it silently returns defaults" \
  'confique-0.4.0 | OK | WebSettingsC { host: "127.0.0.1", port: 8000 }' "$p3b"
fi

############################################################################
echo; echo '## P4 — four tests over real axum 0.8.9 / tokio 1.53.1 / tower 0.5.3'
if [ "$probe_dep_ok" -eq 0 ]; then sk "P4 — axum/tokio/tower unavailable (no cache, no network)"; else
mkdir -p "$W/p4/src" "$W/p4/tests"
cat > "$W/p4/Cargo.toml" <<'EOF'
[package]
name = "p4"
version = "0.0.0"
edition = "2024"
publish = false
[lib]
name = "p4"
path = "src/lib.rs"
[dependencies]
axum = "=0.8.9"
tokio = { version = "=1.53.1", features = ["rt-multi-thread", "net", "signal", "macros", "time", "sync"] }
[dev-dependencies]
tower = { version = "=0.5.3", features = ["util"] }
http-body-util = "0.1"
[workspace]
EOF
{ printf '#![forbid(unsafe_code)]\nuse std::{collections::HashMap, ffi::OsString, net::IpAddr, sync::Arc};\nuse axum::{Router, extract::{FromRef, State}, routing::get};\n'; cat "$W/prelude.rs"
  cat <<'RS'
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WebSettings { pub host: IpAddr, pub port: u16 }
impl Default for WebSettings {
    fn default() -> Self { Self { host: "127.0.0.1".parse().unwrap(), port: 8000 } }
}
#[derive(Debug, PartialEq, Eq)]
pub struct SettingsError { pub var: String, pub value: String, pub expected: &'static str, pub cause: String }
impl std::fmt::Display for SettingsError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{}: invalid value {:?}: expected {} ({})", self.var, self.value, self.expected, self.cause)
    }
}
fn one<T: std::str::FromStr>(v: &HashMap<String, String>, name: &str, expected: &'static str, default: T)
    -> Result<T, SettingsError> where T::Err: std::fmt::Display {
    let var = format!("{WEB_ENV_PREFIX}{name}");
    match v.get(&var) {
        None => Ok(default),
        Some(raw) if raw.is_empty() => Ok(default),
        Some(raw) => raw.parse::<T>().map_err(|e| SettingsError {
            var, value: raw.clone(), expected, cause: e.to_string() }),
    }
}
impl WebSettings {
    pub fn from_vars<I>(vars: I) -> Result<Self, SettingsError>
    where I: IntoIterator<Item = (OsString, OsString)> {
        let map: HashMap<String, String> = vars.into_iter()
            .filter_map(|(k, v)| Some((k.into_string().ok()?, v.into_string().ok()?)))
            .filter(|(k, _)| k.starts_with(WEB_ENV_PREFIX))
            .collect();
        let d = Self::default();
        Ok(Self { host: one(&map, "HOST", "an IP address to bind", d.host)?,
                  port: one(&map, "PORT", "a TCP port in 0..=65535", d.port)? })
    }
    pub fn from_env() -> Result<Self, SettingsError> { Self::from_vars(std::env::vars_os()) }
}
/// R69 revision 10's AppState slot (DECISION.md line for `Arc<WebConfig>`), with R77's type in it.
#[derive(Clone)]
pub struct AppState { pub config: Arc<WebSettings> }
impl FromRef<AppState> for Arc<WebSettings> {
    fn from_ref(state: &AppState) -> Self { Arc::clone(&state.config) }
}
async fn show(State(cfg): State<Arc<WebSettings>>) -> String {
    format!("[\"{}\",\"{}\"]", cfg.host, cfg.port)
}
pub fn build_router(state: AppState) -> Router {
    Router::new().route("/settings", get(show)).with_state(state)
}
RS
} > "$W/p4/src/lib.rs"
cat > "$W/p4/tests/settings.rs" <<'RS'
use std::{ffi::OsString, sync::Arc};
use p4::{AppState, WEB_ENV_PREFIX, WebSettings, build_router};

fn vars(pairs: &[(&str, &str)]) -> Vec<(OsString, OsString)> {
    pairs.iter().map(|(k, v)| (OsString::from(*k), OsString::from(*v))).collect()
}

#[test]
fn prefix_is_derived_from_the_single_app_name_constant() {
    assert_eq!(WEB_ENV_PREFIX, "RSLBP_WEB_");
    assert_eq!(WEB_ENV_PREFIX, format!("{}_WEB_", p4::TOOL_NAME.to_uppercase()));
}

#[test]
fn unprefixed_and_empty_are_ignored() {
    let s = WebSettings::from_vars(vars(&[("PORT", "9999"), ("RSLBP_WEB_PORT", "")])).unwrap();
    assert_eq!(s, WebSettings::default());
    assert_eq!(s.port, 8000);
}

#[test]
fn malformed_port_names_variable_value_and_expectation() {
    let e = WebSettings::from_vars(vars(&[("RSLBP_WEB_PORT", "eighty")])).unwrap_err();
    assert_eq!(e.to_string(),
        "RSLBP_WEB_PORT: invalid value \"eighty\": expected a TCP port in 0..=65535 (invalid digit found in string)");
    assert_eq!(e.var, "RSLBP_WEB_PORT");
    assert_eq!(e.value, "eighty");
}

#[tokio::test]
async fn settings_reach_a_handler_through_state_with_no_process_env() {
    use http_body_util::BodyExt;
    use tower::ServiceExt;
    let settings = WebSettings::from_vars(vars(&[
        ("RSLBP_WEB_HOST", "0.0.0.0"), ("RSLBP_WEB_PORT", "9001")])).unwrap();
    let app = build_router(AppState { config: Arc::new(settings) });
    let res = app.oneshot(axum::http::Request::builder().uri("/settings")
        .body(axum::body::Body::empty()).unwrap()).await.unwrap();
    assert_eq!(res.status(), axum::http::StatusCode::OK);
    let body = res.into_body().collect().await.unwrap().to_bytes();
    assert_eq!(&body[..], br#"["0.0.0.0","9001"]"#);
}
RS
p4out=$(cargo test $OFF --manifest-path "$W/p4/Cargo.toml" --test settings 2>&1 || true)
printf '%s\n' "$p4out" | tail -12
for t in prefix_is_derived_from_the_single_app_name_constant \
         unprefixed_and_empty_are_ignored \
         malformed_port_names_variable_value_and_expectation \
         settings_reach_a_handler_through_state_with_no_process_env; do
  assert_has "P4 $t" "test $t ... ok" "$p4out"
done
assert_has "P4 all four passed, none failed" 'test result: ok. 4 passed; 0 failed' "$p4out"
# The suite must not touch the process environment at all.
envcalls=$(/usr/bin/grep -c 'std::env::' "$W/p4/tests/settings.rs" || true)
assert_eq "P4 the test file contains no std::env call" "0" "$envcalls"
fi

############################################################################
echo; echo '## P6 — normal-dependency package count and stripped release size'
if [ "$probe_dep_ok" -eq 0 ]; then sk "P6 — candidate crates unavailable (no cache, no network)"; else
COMMON='#[derive(Debug, serde::Deserialize)]
struct S { #[serde(default = "dh")] host: String, #[serde(default = "dp")] port: u16 }
fn dh() -> String { "127.0.0.1".into() }
fn dp() -> u16 { 8000 }'
mkcost() { # $1 dir/name  $2 extra deps  $3 body
  mkdir -p "$W/c_$1/src"
  { printf '[package]\nname = "c_%s"\nversion = "0.0.0"\nedition = "2024"\npublish = false\n' "$1"
    printf '[[bin]]\nname = "c_%s"\npath = "src/main.rs"\n' "$1"
    printf '[dependencies]\nserde = { version = "=1.0.229", features = ["derive"] }\n%s\n' "$2"
    printf '[profile.release]\nstrip = true\nopt-level = "z"\nlto = true\ncodegen-units = 1\npanic = "abort"\n[workspace]\n'
  } > "$W/c_$1/Cargo.toml"
  printf '%s\n' "$3" > "$W/c_$1/src/main.rs"
}
mkcost baseline '' "$COMMON
fn main() {
    let mut s = S { host: dh(), port: dp() };
    for (k, v) in std::env::vars() {
        if let Some(f) = k.strip_prefix(\"RSLBP_WEB_\") {
            match f { \"HOST\" => s.host = v, \"PORT\" => s.port = v.parse().unwrap_or(dp()), _ => {} }
        }
    }
    println!(\"{s:?}\");
}"
mkcost envy 'envy = "=0.4.2"' "$COMMON
fn main() { println!(\"{:?}\", envy::prefixed(\"RSLBP_WEB_\").from_env::<S>()); }"
mkcost confique 'confique = "=0.4.0"' '#[derive(Debug, confique::Config)]
struct S {
    #[config(env = "RSLBP_WEB_HOST", default = "127.0.0.1")] host: String,
    #[config(env = "RSLBP_WEB_PORT", default = 8000)] port: u16,
}
fn main() { println!("{:?}", <S as confique::Config>::builder().env().load()); }'
mkcost confignodefault 'config = { version = "=0.15.25", default-features = false }' "$COMMON
fn main() { println!(\"{:?}\", config::Config::builder()
    .add_source(config::Environment::with_prefix(\"RSLBP_WEB\"))
    .build().and_then(|c| c.try_deserialize::<S>())); }"
mkcost figment 'figment = { version = "=0.10.19", features = ["env"] }' "$COMMON
fn main() { println!(\"{:?}\", figment::Figment::from(figment::providers::Env::prefixed(\"RSLBP_WEB_\"))
    .extract::<S>()); }"
mkcost configdefault 'config = "=0.15.25"' "$COMMON
fn main() { println!(\"{:?}\", config::Config::builder()
    .add_source(config::Environment::with_prefix(\"RSLBP_WEB\"))
    .build().and_then(|c| c.try_deserialize::<S>())); }"

names="baseline envy confique confignodefault figment configdefault"
want_pkgs="8 9 12 11 16 55"
sizes=""      # space-separated, same order as $names
printf '%-18s %9s %14s\n' mechanism packages stripped_bytes
i=1
for n in $names; do
  want=$(echo "$want_pkgs" | cut -d' ' -f"$i")
  cargo generate-lockfile $OFF --quiet --manifest-path "$W/c_$n/Cargo.toml" >/dev/null 2>&1 || true
  cnt=$(cargo tree --locked $OFF -e normal --prefix none --manifest-path "$W/c_$n/Cargo.toml" 2>/dev/null \
        | /usr/bin/sed 's/ (\*)//' | sort -u | /usr/bin/grep -c . || true)
  cargo build --release --quiet $OFF --manifest-path "$W/c_$n/Cargo.toml" >/dev/null 2>&1 || true
  bytes=$(stat -f%z "$W/c_$n/target/release/c_$n" 2>/dev/null || stat -c%s "$W/c_$n/target/release/c_$n" 2>/dev/null || echo 0)
  printf '%-18s %9s %14s\n' "$n" "$cnt" "$bytes"
  assert_eq "P6 package count for $n" "$want" "$cnt"
  sizes="$sizes $bytes"
  i=$((i+1))
done
sz_baseline=$(echo "$sizes" | awk '{print $1}')
sz_envy=$(echo "$sizes" | awk '{print $2}')
sz_confique=$(echo "$sizes" | awk '{print $3}')
sz_confignodefault=$(echo "$sizes" | awk '{print $4}')
sz_figment=$(echo "$sizes" | awk '{print $5}')
sz_configdefault=$(echo "$sizes" | awk '{print $6}')
# The size claims that carry weight are DELTAS, not absolute bytes.
# (Absolute bytes are machine-, toolchain- and date-specific; see DECISION.md.)
d_envy=$(( sz_envy - sz_baseline ))
d_confique=$(( sz_confique - sz_baseline ))
d_config=$(( sz_confignodefault - sz_baseline ))
d_figment=$(( sz_figment - sz_baseline ))
d_configdefault=$(( sz_configdefault - sz_baseline ))
printf 'stripped-size deltas over the hand-written baseline: envy=%s confique=%s config-no-default=%s figment=%s config-default=%s\n' \
  "$d_envy" "$d_confique" "$d_config" "$d_figment" "$d_configdefault"
if [ "$d_config" -gt 50000 ]; then
  ok "P6 config(no-default) costs > 50 KB of stripped binary over the hand-written baseline (${d_config} B)"
else
  no "P6 config(no-default) stripped-size delta was ${d_config} B, expected > 50000"
fi
if [ "$d_figment" -gt 50000 ]; then
  ok "P6 figment costs > 50 KB of stripped binary over the hand-written baseline (${d_figment} B)"
else
  no "P6 figment stripped-size delta was ${d_figment} B, expected > 50000"
fi
if [ "$d_envy" -lt 50000 ]; then
  ok "P6 envy costs under 50 KB of stripped binary (${d_envy} B) — it is not excluded on size"
else
  no "P6 envy stripped-size delta was ${d_envy} B, expected < 50000"
fi
if [ "$d_confique" -lt 50000 ]; then
  ok "P6 confique costs under 50 KB of stripped binary (${d_confique} B) — it is not rejected on cost"
else
  no "P6 confique stripped-size delta was ${d_confique} B, expected < 50000"
fi
if [ "$d_configdefault" -gt 100000 ]; then
  ok "P6 config with default features costs > 100 KB of stripped binary (${d_configdefault} B)"
else
  no "P6 config-default stripped-size delta was ${d_configdefault} B, expected > 100000"
fi
fi

printf '\nPASS=%d FAIL=%d SKIP=%d TOTAL=%d\n' "$pass" "$fail" "$skip" "$((pass+fail+skip))"
[ "$fail" -eq 0 ] || exit 1
