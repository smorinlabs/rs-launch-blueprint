//! Workspace architecture, manifest parameter, public API, unsafe-policy, and license tests.
//!
//! Enforces the P04 architectural invariants derived from R02, R04, R06, R22, R46, R49, and R69
//! without external test dependencies.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;

/// Minimal recursive-descent JSON value for parsing `cargo metadata` with zero dependencies.
#[derive(Debug, Clone, PartialEq)]
enum Json {
    Null,
    Bool(bool),
    Number(String),
    String(String),
    Array(Vec<Json>),
    Object(BTreeMap<String, Json>),
}

impl Json {
    fn as_object(&self) -> Result<&BTreeMap<String, Json>, String> {
        match self {
            Self::Object(map) => Ok(map),
            other => Err(format!("expected JSON object, got {other:?}")),
        }
    }

    fn as_array(&self) -> Result<&[Json], String> {
        match self {
            Self::Array(items) => Ok(items),
            other => Err(format!("expected JSON array, got {other:?}")),
        }
    }

    fn as_str(&self) -> Result<&str, String> {
        match self {
            Self::String(s) => Ok(s.as_str()),
            other => Err(format!("expected JSON string, got {other:?}")),
        }
    }

    fn as_bool(&self) -> Result<bool, String> {
        match self {
            Self::Bool(b) => Ok(*b),
            other => Err(format!("expected JSON bool, got {other:?}")),
        }
    }

    fn get(&self, key: &str) -> Result<&Json, String> {
        self.as_object()?
            .get(key)
            .ok_or_else(|| format!("missing JSON key `{key}`"))
    }
}

struct JsonParser<'a> {
    bytes: &'a [u8],
    pos: usize,
}

impl<'a> JsonParser<'a> {
    fn new(input: &'a str) -> Self {
        Self {
            bytes: input.as_bytes(),
            pos: 0,
        }
    }

    fn skip_ws(&mut self) {
        while self.pos < self.bytes.len() && self.bytes[self.pos].is_ascii_whitespace() {
            self.pos += 1;
        }
    }

    fn peek(&self) -> Option<u8> {
        self.bytes.get(self.pos).copied()
    }

    fn next_byte(&mut self) -> Result<u8, String> {
        let byte = self
            .peek()
            .ok_or_else(|| format!("unexpected EOF at byte {}", self.pos))?;
        self.pos += 1;
        Ok(byte)
    }

    fn parse_value(&mut self) -> Result<Json, String> {
        self.skip_ws();
        match self.peek() {
            Some(b'{') => self.parse_object(),
            Some(b'[') => self.parse_array(),
            Some(b'"') => self.parse_string().map(Json::String),
            Some(b't') => self.expect_literal(b"true", Json::Bool(true)),
            Some(b'f') => self.expect_literal(b"false", Json::Bool(false)),
            Some(b'n') => self.expect_literal(b"null", Json::Null),
            Some(b'-' | b'0'..=b'9') => self.parse_number(),
            other => Err(format!(
                "unexpected byte {other:?} at position {}",
                self.pos
            )),
        }
    }

    fn expect_literal(&mut self, lit: &[u8], value: Json) -> Result<Json, String> {
        if self.bytes.get(self.pos..self.pos + lit.len()) == Some(lit) {
            self.pos += lit.len();
            Ok(value)
        } else {
            Err(format!("invalid literal at position {}", self.pos))
        }
    }

    fn parse_number(&mut self) -> Result<Json, String> {
        let start = self.pos;
        while let Some(b) = self.peek() {
            if matches!(b, b'0'..=b'9' | b'-' | b'+' | b'.' | b'e' | b'E') {
                self.pos += 1;
            } else {
                break;
            }
        }
        let s = std::str::from_utf8(&self.bytes[start..self.pos])
            .map_err(|err| format!("invalid UTF-8 number: {err}"))?;
        Ok(Json::Number(s.to_owned()))
    }

    fn parse_string(&mut self) -> Result<String, String> {
        if self.next_byte()? != b'"' {
            return Err(format!("expected opening quote at {}", self.pos));
        }
        let mut out = String::new();
        while let Some(b) = self.peek() {
            match b {
                b'"' => {
                    self.pos += 1;
                    return Ok(out);
                }
                b'\\' => {
                    self.pos += 1;
                    let esc = self.next_byte()?;
                    match esc {
                        b'"' => out.push('"'),
                        b'\\' => out.push('\\'),
                        b'/' => out.push('/'),
                        b'b' => out.push('\u{0008}'),
                        b'f' => out.push('\u{000C}'),
                        b'n' => out.push('\n'),
                        b'r' => out.push('\r'),
                        b't' => out.push('\t'),
                        b'u' => {
                            let hex_end = self.pos + 4;
                            let hex_slice = self
                                .bytes
                                .get(self.pos..hex_end)
                                .ok_or_else(|| "truncated \\u escape".to_owned())?;
                            let hex_str = std::str::from_utf8(hex_slice)
                                .map_err(|err| format!("invalid \\u escape: {err}"))?;
                            let code = u32::from_str_radix(hex_str, 16)
                                .map_err(|err| format!("invalid \\u hex: {err}"))?;
                            self.pos = hex_end;
                            if (0xD800..=0xDBFF).contains(&code)
                                && self.bytes.get(self.pos..self.pos + 2) == Some(b"\\u")
                            {
                                self.pos += 2;
                                let low_slice = self
                                    .bytes
                                    .get(self.pos..self.pos + 4)
                                    .ok_or_else(|| "truncated surrogate pair".to_owned())?;
                                let low_str = std::str::from_utf8(low_slice)
                                    .map_err(|err| format!("invalid surrogate: {err}"))?;
                                let low = u32::from_str_radix(low_str, 16)
                                    .map_err(|err| format!("invalid surrogate hex: {err}"))?;
                                self.pos += 4;
                                let combined = 0x10000 + (((code - 0xD800) << 10) | (low - 0xDC00));
                                let ch = char::from_u32(combined)
                                    .ok_or_else(|| "invalid Unicode scalar".to_owned())?;
                                out.push(ch);
                            } else {
                                let ch = char::from_u32(code)
                                    .ok_or_else(|| "invalid Unicode scalar".to_owned())?;
                                out.push(ch);
                            }
                        }
                        other => return Err(format!("unsupported JSON escape: {other}")),
                    }
                }
                _ => {
                    let rest = std::str::from_utf8(&self.bytes[self.pos..])
                        .map_err(|err| format!("invalid UTF-8 in JSON string: {err}"))?;
                    let ch = rest
                        .chars()
                        .next()
                        .ok_or_else(|| "unexpected EOF in string".to_owned())?;
                    out.push(ch);
                    self.pos += ch.len_utf8();
                }
            }
        }
        Err("unterminated JSON string".to_owned())
    }

    fn parse_array(&mut self) -> Result<Json, String> {
        if self.next_byte()? != b'[' {
            return Err("expected '['".to_owned());
        }
        let mut items = Vec::new();
        self.skip_ws();
        if self.peek() == Some(b']') {
            self.pos += 1;
            return Ok(Json::Array(items));
        }
        loop {
            items.push(self.parse_value()?);
            self.skip_ws();
            match self.next_byte()? {
                b',' => continue,
                b']' => return Ok(Json::Array(items)),
                other => return Err(format!("expected ',' or ']', got {other}")),
            }
        }
    }

    fn parse_object(&mut self) -> Result<Json, String> {
        if self.next_byte()? != b'{' {
            return Err("expected '{'".to_owned());
        }
        let mut map = BTreeMap::new();
        self.skip_ws();
        if self.peek() == Some(b'}') {
            self.pos += 1;
            return Ok(Json::Object(map));
        }
        loop {
            self.skip_ws();
            let key = self.parse_string()?;
            self.skip_ws();
            if self.next_byte()? != b':' {
                return Err(format!("expected ':' after key `{key}`"));
            }
            let val = self.parse_value()?;
            map.insert(key, val);
            self.skip_ws();
            match self.next_byte()? {
                b',' => continue,
                b'}' => return Ok(Json::Object(map)),
                other => return Err(format!("expected ',' or '}}', got {other}")),
            }
        }
    }
}

fn parse_json(input: &str) -> Result<Json, String> {
    let mut parser = JsonParser::new(input);
    let value = parser.parse_value()?;
    parser.skip_ws();
    if parser.pos != parser.bytes.len() {
        return Err(format!("trailing JSON bytes at position {}", parser.pos));
    }
    Ok(value)
}

fn repo_root() -> PathBuf {
    // Prefer runtime CARGO_MANIFEST_DIR before compile-time env!("CARGO_MANIFEST_DIR"):
    // Blaze v2 normalizes compile-time manifest paths for cross-worktree cache sharing.
    if let Some(dir) = std::env::var_os("CARGO_MANIFEST_DIR") {
        let candidate = PathBuf::from(dir);
        if candidate.join("Cargo.toml").is_file() {
            return candidate;
        }
    }
    let compile_time = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    if compile_time.join("Cargo.toml").is_file() {
        return compile_time;
    }
    std::env::current_dir().expect("resolve workspace root from cwd")
}

fn cargo_metadata_no_deps() -> Result<Json, String> {
    let cargo = option_env!("CARGO").unwrap_or("cargo");
    let output = Command::new(cargo)
        .args([
            "metadata",
            "--no-deps",
            "--format-version",
            "1",
            "--offline",
        ])
        .current_dir(repo_root())
        .output()
        .map_err(|err| format!("failed to run cargo metadata: {err}"))?;
    if !output.status.success() {
        return Err(format!(
            "cargo metadata failed ({}): {}",
            output.status,
            String::from_utf8_lossy(&output.stderr)
        ));
    }
    let stdout = String::from_utf8(output.stdout)
        .map_err(|err| format!("cargo metadata output not UTF-8: {err}"))?;
    parse_json(&stdout)
}

fn collect_rs_files(dir: &Path, out: &mut Vec<PathBuf>) -> Result<(), String> {
    if !dir.exists() {
        return Ok(());
    }
    let entries = fs::read_dir(dir)
        .map_err(|err| format!("failed to read directory {}: {err}", dir.display()))?;
    for entry in entries {
        let entry = entry.map_err(|err| format!("dir entry error: {err}"))?;
        let path = entry.path();
        let file_name = entry.file_name();
        if file_name == "target" || file_name == ".git" {
            continue;
        }
        if path.is_dir() {
            collect_rs_files(&path, out)?;
        } else if path.extension().and_then(|ext| ext.to_str()) == Some("rs") {
            out.push(path);
        }
    }
    Ok(())
}

fn workspace_rs_files() -> Result<Vec<PathBuf>, String> {
    let root = repo_root();
    let mut files = Vec::new();
    for subdir in ["src", "tests", "crates"] {
        collect_rs_files(&root.join(subdir), &mut files)?;
    }
    files.sort();
    Ok(files)
}

#[test]
fn workspace_intra_edges_match_declared_topology() {
    let meta = cargo_metadata_no_deps().expect("cargo metadata must succeed");
    let packages = meta
        .get("packages")
        .and_then(Json::as_array)
        .expect("packages array");

    let mut names: Vec<String> = packages
        .iter()
        .map(|p| p.get("name").and_then(Json::as_str).unwrap().to_owned())
        .collect();
    names.sort();

    assert_eq!(
        names,
        vec![
            "rs-launch-blueprint",
            "rs-launch-blueprint-cli",
            "rs-launch-blueprint-core",
            "rs-launch-blueprint-web",
        ],
        "workspace must contain exactly the four R02 packages"
    );

    let mut observed: BTreeMap<String, Vec<String>> = BTreeMap::new();
    for pkg in packages {
        let pkg_name = pkg.get("name").and_then(Json::as_str).unwrap().to_owned();
        let deps = pkg
            .get("dependencies")
            .and_then(Json::as_array)
            .expect("dependencies array");
        let mut edges = Vec::new();
        for dep in deps {
            let dep_name = dep.get("name").and_then(Json::as_str).unwrap();
            if !names.iter().any(|n| n == dep_name) {
                continue;
            }
            let optional = dep.get("optional").and_then(Json::as_bool).unwrap_or(false);
            let kind_suffix = match dep.get("kind") {
                Ok(Json::Null) => String::new(),
                Ok(Json::String(k)) if k == "normal" => String::new(),
                Ok(Json::String(k)) => format!("[{k}]"),
                _ => String::new(),
            };
            let opt_suffix = if optional { "[opt]" } else { "" };
            edges.push(format!("{dep_name}{opt_suffix}{kind_suffix}"));
        }
        edges.sort();
        observed.insert(pkg_name, edges);
    }

    let expected: BTreeMap<String, Vec<String>> = BTreeMap::from([
        (
            "rs-launch-blueprint".to_owned(),
            vec!["rs-launch-blueprint-core".to_owned()],
        ),
        (
            "rs-launch-blueprint-cli".to_owned(),
            vec!["rs-launch-blueprint".to_owned()],
        ),
        ("rs-launch-blueprint-core".to_owned(), Vec::new()),
        (
            "rs-launch-blueprint-web".to_owned(),
            vec!["rs-launch-blueprint".to_owned()],
        ),
    ]);

    assert_eq!(
        observed, expected,
        "intra-workspace edge set drifted from OV-18 library-first workspace topology"
    );
}

#[test]
fn root_external_dependencies_within_allowlist() {
    // Standalone root library normal dependencies only (OV-18): zero CLI, web, or OTel crates.
    const ROOT_NORMAL_ALLOWLIST: &[&str] = &[
        "apple-native-keyring-store",
        "keyring-core",
        "linux-keyutils-keyring-store",
        "rs-launch-blueprint-core",
        "serde",
        "serde_json",
        "tracing",
        "ureq",
        "windows-native-keyring-store",
        "zbus-secret-service-keyring-store",
        "zeroize",
    ];
    const FORBIDDEN_CRATES: &[&str] = &[
        "anyhow",
        "arboard",
        "axum",
        "clap",
        "clap_complete",
        "indicatif",
        "inquire",
        "metrics",
        "opentelemetry",
        "opentelemetry_sdk",
        "problem_details",
        "rs-launch-blueprint-cli",
        "rs-launch-blueprint-web",
        "signal-hook",
        "tabled",
        "tokio",
        "tower",
        "tower-http",
        "tracing-opentelemetry",
        "tracing-subscriber",
        "utoipa",
    ];

    let meta = cargo_metadata_no_deps().expect("cargo metadata must succeed");
    let packages = meta
        .get("packages")
        .and_then(Json::as_array)
        .expect("packages array");
    let root_pkg = packages
        .iter()
        .find(|p| p.get("name").and_then(Json::as_str).ok() == Some("rs-launch-blueprint"))
        .expect("root package must exist");
    let deps = root_pkg
        .get("dependencies")
        .and_then(Json::as_array)
        .expect("root dependencies array");

    for dep in deps {
        let name = dep.get("name").and_then(Json::as_str).unwrap();
        let is_normal = matches!(dep.get("kind"), Ok(Json::Null) | Err(_))
            || dep.get("kind").and_then(Json::as_str).ok() == Some("normal");
        assert!(
            !FORBIDDEN_CRATES.contains(&name),
            "forbidden CLI/web/OTel dependency `{name}` found in standalone root library rs-launch-blueprint"
        );
        if is_normal {
            assert!(
                ROOT_NORMAL_ALLOWLIST.contains(&name),
                "unapproved normal dependency `{name}` in standalone root library rs-launch-blueprint"
            );
        }
    }
}

#[test]
fn standalone_library_dependency_trees_contain_zero_cli_or_web_crates() {
    let cargo = option_env!("CARGO").unwrap_or("cargo");
    let root = repo_root();

    let forbidden_always = [
        "anyhow ",
        "arboard ",
        "axum ",
        "clap ",
        "clap_complete ",
        "indicatif ",
        "inquire ",
        "metrics ",
        "opentelemetry ",
        "problem_details ",
        "rs-launch-blueprint-cli ",
        "rs-launch-blueprint-web ",
        "signal-hook ",
        "tabled ",
        "tokio ",
        "tower-http ",
        "tracing-subscriber ",
        "utoipa ",
    ];

    for extra_args in [
        &["--no-default-features"][..],
        &[][..],
        &["--all-features"][..],
    ] {
        let mut args = vec![
            "tree",
            "-p",
            "rs-launch-blueprint",
            "--edges",
            "normal",
            "--prefix",
            "none",
            "--offline",
        ];
        args.extend_from_slice(extra_args);
        let output = Command::new(cargo)
            .args(&args)
            .current_dir(&root)
            .output()
            .expect("cargo tree must execute");
        assert!(
            output.status.success(),
            "cargo {args:?} failed: {}",
            String::from_utf8_lossy(&output.stderr)
        );
        let tree = String::from_utf8_lossy(&output.stdout);
        for crate_prefix in forbidden_always {
            assert!(
                !tree.contains(crate_prefix),
                "standalone library tree ({extra_args:?}) must not contain `{crate_prefix}`:\n{tree}"
            );
        }
        if extra_args == ["--no-default-features"] {
            for opt_crate in ["ureq ", "toml ", "toml_edit ", "etcetera ", "keyring-core "] {
                assert!(
                    !tree.contains(opt_crate),
                    "--no-default-features library tree must omit optional `{opt_crate}`:\n{tree}"
                );
            }
        }
    }
}

#[test]
fn core_and_root_library_sources_contain_zero_cli_or_web_leaks() {
    let root = repo_root();
    let mut files = Vec::new();
    collect_rs_files(&root.join("crates/core/src"), &mut files).expect("collect core src");
    collect_rs_files(&root.join("src"), &mut files).expect("collect root src");
    assert!(!files.is_empty());

    let forbidden_tokens = [
        "Clipboard",
        "Idempotency",
        "ServiceLogFormat",
        "web_enabled",
        "run_cli",
        "rslbp auth login",
        "--token-file",
        "std::process::ExitCode",
        "std::process::exit",
        "pub enum Exit",
        "DomainError::PromptInterrupted",
        "axum::",
        "clap::",
        "arboard::",
        "inquire::",
        "anyhow::",
    ];

    for file in files {
        let content = fs::read_to_string(&file).expect("read library source");
        for token in forbidden_tokens {
            assert!(
                !content.contains(token),
                "{} contains forbidden CLI/web token `{token}` (OV-18 library isolation)",
                file.display()
            );
        }
    }
}

#[test]
fn core_external_dependencies_within_allowlist() {
    // Audited R## core dependencies only (R01, R02 F010, R48, R52, R53, R56, R57, R58, R67).
    const CORE_EXTERNAL_ALLOWLIST: &[&str] = &[
        "etcetera",
        "mockall",
        "secrecy",
        "serde",
        "thiserror",
        "toml",
        "toml_edit",
        "tracing",
        "zeroize",
    ];
    const FORBIDDEN_FRAMEWORKS: &[&str] = &[
        "axum",
        "tokio",
        "clap",
        "anyhow",
        "tracing-subscriber",
        "tower",
        "tower-http",
    ];

    let meta = cargo_metadata_no_deps().expect("cargo metadata must succeed");
    let packages = meta
        .get("packages")
        .and_then(Json::as_array)
        .expect("packages array");
    let core = packages
        .iter()
        .find(|p| p.get("name").and_then(Json::as_str).ok() == Some("rs-launch-blueprint-core"))
        .expect("rs-launch-blueprint-core package must exist");

    let deps = core
        .get("dependencies")
        .and_then(Json::as_array)
        .expect("core dependencies array");

    for dep in deps {
        let name = dep.get("name").and_then(Json::as_str).unwrap();
        assert!(
            !FORBIDDEN_FRAMEWORKS.contains(&name),
            "forbidden framework `{name}` found in rs-launch-blueprint-core dependencies"
        );
        assert!(
            CORE_EXTERNAL_ALLOWLIST.contains(&name),
            "unapproved external dependency `{name}` in rs-launch-blueprint-core; \
             update CORE_EXTERNAL_ALLOWLIST only for R##-approved core crates"
        );
    }
}

#[test]
fn workspace_packages_share_fixed_parameters() {
    let meta = cargo_metadata_no_deps().expect("cargo metadata must succeed");
    let packages = meta
        .get("packages")
        .and_then(Json::as_array)
        .expect("packages array");

    assert_eq!(packages.len(), 4);
    for pkg in packages {
        let name = pkg.get("name").and_then(Json::as_str).unwrap();
        assert_eq!(
            pkg.get("edition").and_then(Json::as_str).unwrap(),
            "2024",
            "package `{name}` must use edition 2024"
        );
        assert_eq!(
            pkg.get("license").and_then(Json::as_str).unwrap(),
            "MIT OR Apache-2.0",
            "package `{name}` must declare license MIT OR Apache-2.0"
        );
        assert_eq!(
            pkg.get("rust_version").and_then(Json::as_str).unwrap(),
            "1.98",
            "package `{name}` must declare MSRV rust-version 1.98 (stable 1.100 - 2 minors)"
        );
        assert_eq!(
            pkg.get("version").and_then(Json::as_str).unwrap(),
            rs_launch_blueprint::VERSION,
            "package `{name}` version must match rs_launch_blueprint::VERSION"
        );
    }
}

#[test]
fn workspace_package_targets_and_publish_settings_match_ov18() {
    let meta = cargo_metadata_no_deps().expect("cargo metadata must succeed");
    let packages = meta
        .get("packages")
        .and_then(Json::as_array)
        .expect("packages array");

    let find_pkg = |name: &str| {
        packages
            .iter()
            .find(|p| p.get("name").and_then(Json::as_str).ok() == Some(name))
            .unwrap_or_else(|| panic!("package `{name}` must exist"))
    };

    // 1. Root package: standalone [lib] ONLY (zero [[bin]], no default_run, no web/cli features).
    let root_pkg = find_pkg("rs-launch-blueprint");
    assert_eq!(
        root_pkg.get("default_run").ok(),
        Some(&Json::Null),
        "standalone library root package must not declare default-run"
    );

    let targets = root_pkg
        .get("targets")
        .and_then(Json::as_array)
        .expect("root targets array");
    let mut lib_targets = Vec::new();
    let mut root_bins = Vec::new();
    for target in targets {
        let name = target.get("name").and_then(Json::as_str).unwrap();
        let src_path = target.get("src_path").and_then(Json::as_str).unwrap();
        let kinds: Vec<&str> = target
            .get("kind")
            .and_then(Json::as_array)
            .unwrap()
            .iter()
            .map(|k| k.as_str().unwrap())
            .collect();
        if kinds.contains(&"lib") {
            lib_targets.push((name.to_owned(), src_path.to_owned()));
        }
        if kinds.contains(&"bin") {
            root_bins.push(name.to_owned());
        }
    }

    assert_eq!(lib_targets.len(), 1, "expected exactly one [lib] target");
    assert_eq!(lib_targets[0].0, "rs_launch_blueprint");
    assert!(
        lib_targets[0].1.ends_with("/src/lib.rs"),
        "lib target path must end with /src/lib.rs, got {}",
        lib_targets[0].1
    );
    assert!(
        root_bins.is_empty(),
        "standalone root library must declare zero [[bin]] targets, found {root_bins:?}"
    );

    let features = root_pkg
        .get("features")
        .and_then(Json::as_object)
        .expect("features map");
    for required_feat in ["default", "http", "config", "mock", "keychain"] {
        assert!(
            features.contains_key(required_feat),
            "root library missing expected feature `{required_feat}`"
        );
    }
    for forbidden_feat in ["web", "metrics", "otel", "clipboard"] {
        assert!(
            !features.contains_key(forbidden_feat),
            "standalone root library must not expose CLI/web feature `{forbidden_feat}`"
        );
    }

    // 2. CLI crate owns `rslbp` binary and `default-run = "rslbp"`.
    let cli_pkg = find_pkg("rs-launch-blueprint-cli");
    assert_eq!(
        cli_pkg.get("default_run").and_then(Json::as_str).unwrap(),
        "rslbp",
        "CLI crate must set default-run = \"rslbp\""
    );
    let cli_bins: Vec<&str> = cli_pkg
        .get("targets")
        .and_then(Json::as_array)
        .unwrap()
        .iter()
        .filter(|t| {
            t.get("kind")
                .and_then(Json::as_array)
                .unwrap()
                .iter()
                .any(|k| k.as_str().ok() == Some("bin"))
        })
        .map(|t| t.get("name").and_then(Json::as_str).unwrap())
        .collect();
    assert_eq!(cli_bins, vec!["rslbp"]);

    // 3. Web crate owns `rslbp-serve` binary and is explicitly `publish = false` (publish == []).
    let web_pkg = find_pkg("rs-launch-blueprint-web");
    let web_publish = web_pkg
        .get("publish")
        .and_then(Json::as_array)
        .expect("rs-launch-blueprint-web must set publish = false (empty array in metadata)");
    assert!(
        web_publish.is_empty(),
        "rs-launch-blueprint-web must be unpublishable (publish = false), got {web_publish:?}"
    );
    let web_bins: Vec<&str> = web_pkg
        .get("targets")
        .and_then(Json::as_array)
        .unwrap()
        .iter()
        .filter(|t| {
            t.get("kind")
                .and_then(Json::as_array)
                .unwrap()
                .iter()
                .any(|k| k.as_str().ok() == Some("bin"))
        })
        .map(|t| t.get("name").and_then(Json::as_str).unwrap())
        .collect();
    assert_eq!(web_bins, vec!["rslbp-serve"]);
}

#[test]
fn version_constant_matches_cargo_pkg_version() {
    let version = rs_launch_blueprint::VERSION;
    assert_eq!(version, env!("CARGO_PKG_VERSION"));
    assert!(!version.starts_with('v'), "VERSION must not start with 'v'");
    let core = version.split(['-', '+']).next().unwrap();
    let parts: Vec<&str> = core.split('.').collect();
    assert_eq!(parts.len(), 3, "VERSION must be SemVer MAJOR.MINOR.PATCH");
    for part in parts {
        assert!(
            !part.is_empty() && part.chars().all(|c| c.is_ascii_digit()),
            "invalid numeric SemVer component in {version}"
        );
    }
}

#[test]
fn unsafe_code_forbid_is_declared_once_in_workspace_manifest() {
    let root = repo_root();
    let root_manifest = fs::read_to_string(root.join("Cargo.toml")).expect("read root Cargo.toml");
    assert!(
        root_manifest.contains("[workspace.lints.rust]")
            && root_manifest.contains("unsafe_code = \"forbid\""),
        "root Cargo.toml must forbid unsafe_code in [workspace.lints.rust]"
    );
    assert!(
        root_manifest.contains("undocumented_unsafe_blocks = \"deny\"")
            && root_manifest.contains("multiple_unsafe_ops_per_block = \"deny\"")
            && root_manifest.contains("unnecessary_safety_comment = \"deny\""),
        "root Cargo.toml must pre-arm R06 clippy safety-comment lints"
    );

    for rel in [
        "Cargo.toml",
        "crates/core/Cargo.toml",
        "crates/cli/Cargo.toml",
        "crates/web/Cargo.toml",
    ] {
        let text = fs::read_to_string(root.join(rel)).expect("read manifest");
        assert!(
            text.contains("[lints]") && text.contains("workspace = true"),
            "{rel} must inherit workspace lints via [lints] workspace = true"
        );
    }

    let dup_attr = concat!("#![forbid(", "unsafe_code)]");
    let files = workspace_rs_files().expect("discover .rs files");
    assert!(
        !files.is_empty(),
        "expected at least one workspace .rs file"
    );
    for file in files {
        let text = fs::read_to_string(&file).expect("read .rs file");
        assert!(
            !text.contains(dup_attr),
            "{} must not duplicate `{dup_attr}`; [workspace.lints.rust] is the single source of truth (R06)",
            file.display()
        );
    }
}

#[test]
fn root_license_files_present_and_no_per_file_license_headers() {
    let root = repo_root();
    for file_name in ["LICENSE", "LICENSE-MIT"] {
        let path = root.join(file_name);
        let root_bytes = fs::read(&path)
            .unwrap_or_else(|err| panic!("missing root license file {file_name}: {err}"));
        assert!(
            !root_bytes.is_empty(),
            "root license file {file_name} must be non-empty"
        );
        for pkg_dir in ["crates/core", "crates/cli"] {
            let member_path = root.join(pkg_dir).join(file_name);
            let member_bytes = fs::read(&member_path).unwrap_or_else(|err| {
                panic!("missing published crate license file {pkg_dir}/{file_name}: {err}")
            });
            assert_eq!(
                member_bytes, root_bytes,
                "{pkg_dir}/{file_name} must stay byte-identical to root {file_name}"
            );
        }
    }

    // Assemble checked phrases so this test file does not contain literal boilerplate lines.
    let canonical_phrases = [
        concat!("SPDX-License-", "Identifier:"),
        concat!("Permission is hereby granted, ", "free of charge"),
        concat!("Licensed under the Apache License, ", "Version 2.0"),
    ];

    let files = workspace_rs_files().expect("discover .rs files");
    assert!(!files.is_empty(), "workspace must contain .rs files");

    for file in files {
        let content = fs::read_to_string(&file).expect("read .rs file");
        let first_40: Vec<&str> = content.lines().take(40).collect();
        for (idx, line) in first_40.iter().enumerate() {
            for phrase in &canonical_phrases {
                assert!(
                    !line.contains(phrase),
                    "{}:{} contains prohibited per-file license marker (R46)",
                    file.display(),
                    idx + 1
                );
            }
        }

        // Layer 2 (R46): leading plain-comment block before doc comments, attributes, or code.
        for (idx, raw_line) in first_40.iter().enumerate() {
            let trimmed = raw_line.trim_start();
            if idx == 0 && trimmed.starts_with("#!") && !trimmed.starts_with("#![") {
                continue;
            }
            if trimmed.is_empty() {
                continue;
            }
            let is_doc = trimmed.starts_with("//!")
                || trimmed.starts_with("///")
                || trimmed.starts_with("/*!")
                || trimmed.starts_with("/**");
            let is_plain_comment =
                !is_doc && (trimmed.starts_with("//") || trimmed.starts_with("/*"));
            if !is_plain_comment {
                break;
            }
            let lower = trimmed.to_ascii_lowercase();
            for marker in [
                concat!("licen", "se"),
                concat!("copy", "right"),
                concat!("sp", "dx"),
            ] {
                assert!(
                    !lower.contains(marker),
                    "{}:{} leading plain comment must not carry license/copyright header (R46)",
                    file.display(),
                    idx + 1
                );
            }
        }
    }
}

#[test]
fn unsafe_code_forbid_rejects_unsafe_and_allow_override_in_member() {
    use std::time::{SystemTime, UNIX_EPOCH};

    let nanos = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("clock")
        .as_nanos();
    let probe_dir = std::env::temp_dir().join(format!(
        "rslbp-unsafe-forbid-{}-{nanos}",
        std::process::id()
    ));
    let member_src = probe_dir.join("crates/demo/src");
    fs::create_dir_all(&member_src).expect("create probe dirs");

    let root_toml = "[workspace]\n\
        members = [\"crates/*\"]\n\
        resolver = \"3\"\n\n\
        [workspace.lints.rust]\n\
        unsafe_code = \"forbid\"\n";
    let member_toml = "[package]\n\
        name = \"demo\"\n\
        version = \"0.1.0\"\n\
        edition = \"2024\"\n\n\
        [lints]\n\
        workspace = true\n";
    let violating_src = "#[allow(unsafe_code)]\n\
        pub fn bad() -> u8 {\n\
            unsafe { 1 }\n\
        }\n";

    fs::write(probe_dir.join("Cargo.toml"), root_toml).expect("write probe root manifest");
    fs::write(probe_dir.join("crates/demo/Cargo.toml"), member_toml)
        .expect("write probe member manifest");
    fs::write(member_src.join("lib.rs"), violating_src).expect("write probe source");

    let cargo = option_env!("CARGO").unwrap_or("cargo");
    let target_dir = probe_dir.join("target");
    let output = Command::new(cargo)
        .args(["check", "--workspace", "--offline"])
        .current_dir(&probe_dir)
        .env("CARGO_TARGET_DIR", &target_dir)
        .output()
        .expect("cargo check probe must run");

    let _ = fs::remove_dir_all(&probe_dir);

    assert!(
        !output.status.success(),
        "member using unsafe with #[allow(unsafe_code)] must fail under workspace unsafe_code = \"forbid\""
    );
    let stderr = String::from_utf8_lossy(&output.stderr);
    assert!(
        stderr.contains("E0453") && stderr.contains("unsafe_code"),
        "expected E0453 forbid violation in stderr, got:\n{stderr}"
    );
}
