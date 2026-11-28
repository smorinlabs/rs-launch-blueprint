//! Built-binary CLI acceptance tests via `assert_cmd` (`R32`, `R60`–`R67`, `R85`).

use std::fs;
use std::io::Read;
use std::process::{Command, Stdio};
use std::time::Duration;

use assert_cmd::cargo::cargo_bin_cmd;
use predicates::str::contains;
use tempfile::TempDir;

use crate::support::{StubHttpServer, StubResponse};

const CMD_TIMEOUT: Duration = Duration::from_secs(10);

fn isolated_cmd(tmp: &TempDir) -> assert_cmd::Command {
    let mut cmd = cargo_bin_cmd!("rslbp");
    cmd.timeout(CMD_TIMEOUT)
        .env_remove("RSLBP_TOKEN")
        .env_remove("RSLBP_CONFIG")
        .env_remove("RSLBP_OUTPUT")
        .env_remove("RSLBP_LOG_LEVEL")
        .env_remove("RSLBP_LOG_FORMAT")
        .env_remove("RSLBP_LOG_FILE")
        .env_remove("RSLBP_PAGER")
        .env_remove("PAGER")
        .env_remove("NO_COLOR")
        .env_remove("FORCE_COLOR")
        .env_remove("CLICOLOR")
        .env_remove("CLICOLOR_FORCE")
        .env("XDG_CONFIG_HOME", tmp.path().join("config"))
        .env("XDG_DATA_HOME", tmp.path().join("data"))
        .env("XDG_STATE_HOME", tmp.path().join("state"))
        .env("XDG_CACHE_HOME", tmp.path().join("cache"))
        .env("XDG_CONFIG_DIRS", tmp.path().join("sys"))
        .current_dir(tmp.path());
    cmd
}

#[test]
fn version_flags_are_byte_identical_single_line_and_json_emits_build_metadata() {
    let tmp = TempDir::new().expect("temp dir");

    let short = isolated_cmd(&tmp)
        .arg("-V")
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let long = isolated_cmd(&tmp)
        .arg("--version")
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();

    assert_eq!(
        short, long,
        "R60 AC2: -V and --version must be byte-identical"
    );
    let text = String::from_utf8(long).expect("utf-8 version");
    let expected = format!("rslbp {}\n", rs_launch_blueprint::VERSION);
    assert_eq!(
        text, expected,
        "R60 AC2: exact single-line `rslbp <semver>`"
    );
    assert!(
        !rs_launch_blueprint::VERSION.starts_with('v'),
        "R60 AC2: version must not carry leading v"
    );

    // R60 AC3: `--version -o json` and `--version --json` and `version --json` emit build JSON.
    let json_dash_o = isolated_cmd(&tmp)
        .args(["--version", "-o", "json"])
        .assert()
        .success()
        .stderr("")
        .get_output()
        .stdout
        .clone();
    let json_alias = isolated_cmd(&tmp)
        .args(["--version", "--json"])
        .assert()
        .success()
        .stderr("")
        .get_output()
        .stdout
        .clone();
    assert_eq!(json_dash_o, json_alias, "R66 AC2: --json == -o json");

    let val: serde_json::Value = serde_json::from_slice(&json_dash_o).expect("valid JSON");
    assert_eq!(val["version"], rs_launch_blueprint::VERSION);
    assert!(
        !val["target"].as_str().unwrap_or("").is_empty(),
        "R60 AC3: target must be populated by build.rs"
    );
    assert!(
        !val["rustc"].as_str().unwrap_or("").is_empty(),
        "R60 AC3: rustc must be populated by build.rs"
    );
    assert!(
        val.get("commit").is_none() && val.get("built").is_none(),
        "R60 AC3: commit and built must be omitted when unknown: {val}"
    );

    let subcmd_json = isolated_cmd(&tmp)
        .args(["version", "--json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert_eq!(subcmd_json, json_dash_o);
}

#[test]
fn completion_generates_non_empty_scripts_for_bash_zsh_fish() {
    let tmp = TempDir::new().expect("temp dir");
    for shell in ["bash", "zsh", "fish"] {
        let out = isolated_cmd(&tmp)
            .args(["completion", shell])
            .assert()
            .success()
            .get_output()
            .stdout
            .clone();
        let script = String::from_utf8(out).expect("utf-8 completion");
        assert!(
            !script.trim().is_empty() && script.contains("rslbp"),
            "completion {shell} must emit non-empty rslbp script"
        );
    }
}

#[test]
fn unknown_command_and_prefix_exit_2_with_suggestion_and_empty_stdout() {
    let tmp = TempDir::new().expect("temp dir");

    // R60 AC6: mistyped noun suggests `project` and exits 2 with RSLB201.
    let misspelled_noun = concat!("proj", "ct");
    isolated_cmd(&tmp)
        .args([misspelled_noun, "list"])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB201"))
        .stderr(contains("project"));

    // R60 AC6 / R3.10: bare prefix `proj` must NOT silently resolve to `project`.
    isolated_cmd(&tmp)
        .args(["proj", "list"])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB201"));

    // Machine error envelope on parse failure when --json is passed.
    let err_out = isolated_cmd(&tmp)
        .args(["--json", misspelled_noun, "list"])
        .assert()
        .code(2)
        .stdout("")
        .get_output()
        .stderr
        .clone();
    let envelope: serde_json::Value =
        serde_json::from_slice(&err_out).expect("stderr must be single JSON envelope");
    assert_eq!(envelope["error"]["code"], "RSLB201");
}

#[test]
fn output_format_flag_conflicts_validation_and_file_redirection() {
    let tmp = TempDir::new().expect("temp dir");

    // R66 AC3: --json + explicit -o <anything> fails with exit 2 and RSLB201 naming both flags.
    for other in ["markdown", "json", "table", "name"] {
        isolated_cmd(&tmp)
            .args(["config", "path", "--json", "-o", other])
            .assert()
            .code(2)
            .stdout("")
            .stderr(contains("RSLB201"))
            .stderr(contains("--json"))
            .stderr(contains("--output"));
    }

    // R66 AC8: invalid format enum exits 2 listing valid values.
    isolated_cmd(&tmp)
        .args(["config", "path", "-o", "xml"])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("table"))
        .stderr(contains("json"))
        .stderr(contains("markdown"))
        .stderr(contains("name"));

    // R66 AC1, AC2, AC5, AC6, AC12, AC13: -o json == --output json == --json, --output-file, --no-clobber.
    let via_short = isolated_cmd(&tmp)
        .args(["config", "path", "-o", "json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let via_long = isolated_cmd(&tmp)
        .args(["config", "path", "--output", "json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let via_alias = isolated_cmd(&tmp)
        .args(["config", "path", "--json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert_eq!(via_short, via_long);
    assert_eq!(via_short, via_alias);

    let out_file = tmp.path().join("result.json");
    isolated_cmd(&tmp)
        .args([
            "config",
            "path",
            "-o",
            "json",
            "--output-file",
            out_file.to_str().unwrap(),
        ])
        .assert()
        .success()
        .stdout("");
    assert_eq!(fs::read(&out_file).expect("read out_file"), via_short);

    // R66 AC13: --no-clobber refuses existing file with exit 5 / RSLB501 and leaves file untouched.
    fs::write(&out_file, b"ORIGINAL_BYTES").expect("seed existing");
    isolated_cmd(&tmp)
        .args([
            "config",
            "path",
            "--json",
            "--no-clobber",
            "--output-file",
            out_file.to_str().unwrap(),
        ])
        .assert()
        .code(5)
        .stdout("")
        .stderr(contains("RSLB501"));
    assert_eq!(
        fs::read(&out_file).expect("read preserved"),
        b"ORIGINAL_BYTES"
    );

    // R66 AC6: `--output-file -` writes to stdout.
    let via_dash = isolated_cmd(&tmp)
        .args(["config", "path", "-o", "markdown", "--output-file", "-"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert!(String::from_utf8_lossy(&via_dash).contains("| Config path | Exists |"));
}

#[test]
fn projects_crud_formats_aliases_and_error_envelopes_via_http_stub() {
    let tmp = TempDir::new().expect("temp dir");
    let server = StubHttpServer::start(|req| match (req.method.as_str(), req.path.as_str()) {
        ("GET", path) if path.starts_with("/v1/projects") && !path.starts_with("/v1/projects/") => {
            if req.authorization.as_deref() == Some("Bearer bad-token") {
                return StubResponse::status(401, r#"{"error":"unauthorized"}"#);
            }
            StubResponse::ok_json(
                r#"{"data":[
                    {"gid":"p1","name":"Alpha | One","workspace":{"name":"Core\\Team"}},
                    {"gid":"p2","name":"Beta\nTwo","workspace":null}
                ]}"#,
            )
        }
        ("GET", "/v1/projects/p1") => StubResponse::ok_json(
            r#"{"data":{"gid":"p1","name":"Alpha | One","workspace":{"name":"Core\\Team"}}}"#,
        ),
        ("GET", "/v1/projects/missing") => StubResponse::status(404, r#"{"error":"not found"}"#),
        ("POST", "/v1/projects") => {
            if req.body.contains("ConflictName") {
                StubResponse::status(409, r#"{"error":"conflict"}"#)
            } else {
                StubResponse::status(
                    201,
                    r#"{"data":{"gid":"p3","name":"Gamma","workspace":{"name":"Core"}}}"#,
                )
            }
        }
        ("DELETE", "/v1/projects/p1") => StubResponse::status(204, ""),
        ("DELETE", "/v1/projects/missing") => StubResponse::status(404, ""),
        _ => StubResponse::status(500, r#"{"error":"boom"}"#),
    });

    // Missing credentials -> exit 4 / RSLB401 in both human and machine JSON modes.
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .args(["project", "list"])
        .assert()
        .code(4)
        .stdout("")
        .stderr(contains("error[RSLB401]:"))
        .stderr(contains("hint:"));

    let auth_json_err = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .args(["project", "list", "--json"])
        .assert()
        .code(4)
        .stdout("")
        .get_output()
        .stderr
        .clone();
    let env_val: serde_json::Value = serde_json::from_slice(&auth_json_err).expect("json error");
    assert_eq!(env_val["error"]["code"], "RSLB401");
    assert!(env_val["error"]["hint"].is_string());

    // Machine formats carry zero 0x1b bytes even under FORCE_COLOR=1 (R66 AC11).
    let json_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .env("FORCE_COLOR", "1")
        .args(["project", "list", "--json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert!(!json_bytes.contains(&0x1b), "JSON must never contain ESC");
    let list_val: serde_json::Value = serde_json::from_slice(&json_bytes).expect("valid json");
    assert_eq!(list_val["projects"].as_array().unwrap().len(), 2);

    // Hidden plural alias `projects` and global flag before verb both work identically (R60 AC1, AC10).
    let plural_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["--json", "projects", "list"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert_eq!(plural_bytes, json_bytes);

    // RSLBP_OUTPUT=json env var works (R60 AC5).
    let env_out_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .env("RSLBP_OUTPUT", "json")
        .args(["project", "list"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert_eq!(env_out_bytes, json_bytes);

    // Markdown escapes `|`, `\`, and newlines, with zero ESC bytes (R66 AC10, AC11).
    let md_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .env("FORCE_COLOR", "1")
        .args(["project", "list", "-o", "markdown"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert!(!md_bytes.contains(&0x1b), "Markdown must never contain ESC");
    let md = String::from_utf8(md_bytes).expect("utf-8 md");
    assert!(md.contains(r"Alpha \| One"), "pipe must be escaped: {md}");
    assert!(
        md.contains(r"Core\\Team"),
        "backslash must be escaped: {md}"
    );
    assert!(md.contains("Beta Two"), "newline must be collapsed: {md}");

    // Name format emits bare IDs one per line, zero ESC (R66).
    let name_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .env("FORCE_COLOR", "1")
        .args(["project", "list", "-o", "name"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert!(!name_bytes.contains(&0x1b));
    assert_eq!(String::from_utf8(name_bytes).unwrap(), "p1\np2\n");

    // Table format renders headers and rows.
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "list", "-o", "table"])
        .assert()
        .success()
        .stdout(contains("Name"))
        .stdout(contains("p1"))
        .stdout(contains("p2"));

    // Narrowing `--select --no-input` proceeds with full unnarrowed list (R61 F360).
    let narrow_bytes = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "list", "--select", "--no-input", "--json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    assert_eq!(narrow_bytes, json_bytes);

    // Get existing & missing (exit 3 / RSLB301, hint omitted not null).
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "get", "p1", "--json"])
        .assert()
        .success()
        .stdout(contains("Alpha | One"));

    let nf_err = isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "get", "missing", "--json"])
        .assert()
        .code(3)
        .stdout("")
        .get_output()
        .stderr
        .clone();
    let nf_val: serde_json::Value = serde_json::from_slice(&nf_err).expect("nf json");
    assert_eq!(nf_val["error"]["code"], "RSLB301");
    assert!(
        nf_val["error"].get("hint").is_none(),
        "absent hint must be omitted, not null: {nf_val}"
    );

    // Unauthorized (401 -> exit 4 / RSLB402).
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "bad-token")
        .args(["project", "list", "--json"])
        .assert()
        .code(4)
        .stdout("")
        .stderr(contains("RSLB402"));

    // Create + conflict (409 -> exit 5 / RSLB501).
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args([
            "project",
            "create",
            "Gamma",
            "--workspace",
            "Core",
            "--json",
        ])
        .assert()
        .success()
        .stdout(contains("p3"));

    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "create", "ConflictName", "--json"])
        .assert()
        .code(5)
        .stdout("")
        .stderr(contains("RSLB501"));

    // Delete under --no-input without --yes refuses with exit 2 / RSLB205; --yes succeeds.
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "delete", "p1", "--no-input"])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB205"));

    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .env("RSLBP_TOKEN", "sk_test_good")
        .args(["project", "delete", "p1", "--yes", "--json"])
        .assert()
        .success()
        .stdout(contains("p1"));

    // Token via `--token-file -` (stdin).
    isolated_cmd(&tmp)
        .env("RSLBP_API_BASE_URL", server.base_url())
        .args(["project", "list", "--token-file", "-", "--json"])
        .write_stdin("sk_from_stdin\n")
        .assert()
        .success();
    assert!(
        server
            .requests()
            .iter()
            .any(|r| r.authorization.as_deref() == Some("Bearer sk_from_stdin")),
        "expected Bearer token read from stdin"
    );
}

#[test]
fn config_commands_and_no_input_prompts_follow_r56_and_r61() {
    let tmp = TempDir::new().expect("temp dir");
    let cfg = tmp.path().join("custom.toml");
    let cfg_str = cfg.to_str().unwrap();

    // config init --no-input without --yes fails with RSLB205 / exit 2 (R61 AC5).
    isolated_cmd(&tmp)
        .args(["config", "init", "--config", cfg_str, "--no-input"])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB205"));

    // config init --yes --dry-run previews without creating file.
    isolated_cmd(&tmp)
        .args([
            "config",
            "init",
            "--config",
            cfg_str,
            "--yes",
            "--dry-run",
            "--no-input",
        ])
        .assert()
        .success()
        .stderr(contains("[dry-run]"));
    assert!(!cfg.exists());

    // config init --yes writes config file.
    isolated_cmd(&tmp)
        .args(["config", "init", "--config", cfg_str, "--yes", "--no-input"])
        .assert()
        .success();
    assert!(cfg.exists());

    // config set --dry-run --no-input succeeds before overwrite confirm (R61 AC10).
    isolated_cmd(&tmp)
        .args([
            "config",
            "set",
            "output.format",
            "json",
            "--config",
            cfg_str,
            "--dry-run",
            "--no-input",
        ])
        .assert()
        .success()
        .stderr(contains("[dry-run]"));

    // config set overwriting existing value under --no-input without --yes fails RSLB205 / exit 2.
    isolated_cmd(&tmp)
        .args([
            "config",
            "set",
            "output.format",
            "json",
            "--config",
            cfg_str,
            "--no-input",
        ])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB205"));

    // config set with --yes writes and config get/show reflect it.
    isolated_cmd(&tmp)
        .args([
            "config",
            "set",
            "output.format",
            "json",
            "--config",
            cfg_str,
            "--yes",
        ])
        .assert()
        .success();

    let got = isolated_cmd(&tmp)
        .args([
            "config",
            "get",
            "output.format",
            "--config",
            cfg_str,
            "--json",
        ])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let got_val: serde_json::Value = serde_json::from_slice(&got).expect("get json");
    assert_eq!(got_val["key"], "output.format");
    assert_eq!(got_val["value"], "json");

    isolated_cmd(&tmp)
        .args(["config", "show", "--config", cfg_str, "--json"])
        .assert()
        .success()
        .stdout(contains("output.format"));

    // R56 AC7: config set token fails with RSLB204 / exit 2.
    isolated_cmd(&tmp)
        .args([
            "config",
            "set",
            "token",
            "sk_live_forbidden",
            "--config",
            cfg_str,
            "--yes",
        ])
        .assert()
        .code(2)
        .stdout("")
        .stderr(contains("RSLB204"));
}

#[test]
fn diagnostics_and_bundle_redact_secrets() {
    let tmp = TempDir::new().expect("temp dir");
    let secret = "sk_live_SUPER_SECRET_DIAG_9999";

    isolated_cmd(&tmp)
        .env("RSLBP_TOKEN", secret)
        .args(["diagnostics", "--json"])
        .assert()
        .success()
        .stdout(contains("\"checks\""));

    let bundle_bytes = isolated_cmd(&tmp)
        .env("RSLBP_TOKEN", secret)
        .args(["diagnostics", "--bundle", "--json"])
        .assert()
        .success()
        .get_output()
        .stdout
        .clone();
    let bundle_text = String::from_utf8(bundle_bytes).expect("utf-8 bundle");
    assert!(
        !bundle_text.contains(secret),
        "diagnostics --bundle must NEVER leak raw secret: {bundle_text}"
    );
    let val: serde_json::Value = serde_json::from_str(&bundle_text).expect("valid bundle json");
    assert_eq!(val["version"], rs_launch_blueprint::VERSION);
    assert_eq!(val["token_present"], true);
    assert_eq!(val["env"]["RSLBP_TOKEN"], "[REDACTED]");
}

#[test]
fn broken_pipe_on_stdout_exits_0_silently() {
    let tmp = TempDir::new().expect("temp dir");
    let bin = env!("CARGO_BIN_EXE_rslbp");

    let mut child = Command::new(bin)
        .args(["completion", "bash"])
        .env("XDG_CONFIG_HOME", tmp.path().join("config"))
        .env("XDG_STATE_HOME", tmp.path().join("state"))
        .stdout(Stdio::piped())
        .stderr(Stdio::piped())
        .spawn()
        .expect("spawn rslbp");

    // Close stdout reader immediately so writing the completion script hits EPIPE.
    drop(child.stdout.take());

    let mut stderr_bytes = Vec::new();
    if let Some(mut err) = child.stderr.take() {
        let _ = err.read_to_end(&mut stderr_bytes);
    }
    let status = child.wait().expect("wait child");
    assert_eq!(
        status.code(),
        Some(0),
        "R67 AC5: broken pipe on result stream must exit 0, got {status:?}, stderr={}",
        String::from_utf8_lossy(&stderr_bytes)
    );
    assert!(
        stderr_bytes.is_empty(),
        "R67 AC5: broken pipe must leave stderr empty, got: {}",
        String::from_utf8_lossy(&stderr_bytes)
    );
}

#[test]
fn telemetry_flags_config_token_and_clipboard_daemon_paths() {
    let tmp = TempDir::new().expect("temp dir");
    let log_path = tmp.path().join("rslbp-test.log");
    let log_arg = format!("--log-file={}", log_path.display());

    // Exercise --debug, --log-format=json, --log-file=<path>, and config get token.
    isolated_cmd(&tmp)
        .env("RSLBP_TOKEN", "sk_live_masked_token_123456")
        .args([
            "--debug",
            "--log-format",
            "json",
            &log_arg,
            "config",
            "get",
            "token",
            "--json",
        ])
        .assert()
        .success()
        .stdout(contains("***3456"));
    assert!(
        log_path.exists(),
        "--log-file must create rotating log file"
    );

    // Exercise --log-format=console, --log-format=auto, bare --log-file, and unwritable log file warning.
    isolated_cmd(&tmp)
        .args(["--log-format=console", "--log-file=", "config", "path"])
        .assert()
        .success();
    let blocker = tmp.path().join("log-blocker");
    fs::write(&blocker, b"x").unwrap();
    let bad_log = format!("--log-file={}", blocker.join("sub.log").display());
    isolated_cmd(&tmp)
        .args(["--log-format=auto", &bad_log, "config", "path"])
        .assert()
        .success();

    // Exercise env-var RSLBP_LOG_FORMAT and HOME/XDG unset fallback cleanly.
    isolated_cmd(&tmp)
        .env("RSLBP_LOG_FORMAT", "console")
        .env_remove("HOME")
        .env_remove("XDG_CONFIG_HOME")
        .env_remove("XDG_DATA_HOME")
        .env_remove("XDG_STATE_HOME")
        .env_remove("XDG_CACHE_HOME")
        .args(["config", "path"])
        .assert()
        .success();

    // Exercise hidden --clipboard-daemon entrypoint on non-Linux hosts.
    #[cfg(not(target_os = "linux"))]
    isolated_cmd(&tmp)
        .arg("--clipboard-daemon")
        .assert()
        .success();
}

#[cfg(feature = "web")]
#[test]
fn serve_binary_version_exits_zero() {
    let mut cmd = cargo_bin_cmd!("rslbp-serve");
    cmd.timeout(CMD_TIMEOUT)
        .arg("--version")
        .assert()
        .success()
        .stdout(contains(format!(
            "rslbp-serve {}",
            rs_launch_blueprint::VERSION
        )));
}
