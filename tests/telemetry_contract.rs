//! Contract tests for the logging pipeline (`R58`, `OV-09`) and rotating file sink (`R59`).

use std::ffi::OsString;
use std::fs;
use std::io::{self, Write};
use std::os::unix::fs::PermissionsExt;
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::sync::atomic::{AtomicU64, Ordering};
use std::sync::{Arc, Mutex};
use std::time::{SystemTime, UNIX_EPOCH};

use rs_launch_blueprint::{
    ErrorCode, FileLogFormat, LevelLadderInput, LogFormat, LogLevel, Profile, REDACTED,
    ResolvedLogFormat, RotatingFile, SENSITIVE_KEY_PARTS, ServiceLogFormat, TelemetryInit,
    build_scoped_subscriber, init_telemetry, is_sensitive_key, resolve_console_level,
    resolve_log_file, resolve_log_format,
};
use secrecy::SecretString;
use tracing::{debug, info, info_span, warn};

static NEXT_TEMP: AtomicU64 = AtomicU64::new(0);

struct TempDir {
    path: PathBuf,
}

impl TempDir {
    fn new(label: &str) -> Self {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock")
            .as_nanos();
        let seq = NEXT_TEMP.fetch_add(1, Ordering::Relaxed);
        let path = std::env::temp_dir().join(format!(
            "rslbp-p06-log-{label}-{}-{nanos}-{seq}",
            std::process::id()
        ));
        fs::create_dir_all(&path).expect("create temp dir");
        Self { path }
    }

    fn path(&self) -> &Path {
        &self.path
    }
}

impl Drop for TempDir {
    fn drop(&mut self) {
        let _ = fs::remove_dir_all(&self.path);
    }
}

#[derive(Clone, Default)]
struct CaptureBuf(Arc<Mutex<Vec<u8>>>);

impl CaptureBuf {
    fn bytes(&self) -> Vec<u8> {
        self.0.lock().expect("lock buf").clone()
    }

    fn text(&self) -> String {
        String::from_utf8_lossy(&self.bytes()).into_owned()
    }
}

impl Write for CaptureBuf {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.0.lock().expect("lock buf").extend_from_slice(buf);
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

#[test]
fn sensitive_key_vocabulary_matches_f252_verbatim() {
    assert_eq!(
        SENSITIVE_KEY_PARTS,
        [
            "token",
            "password",
            "secret",
            "authorization",
            "api_key",
            "apikey",
            "credential",
            "cookie",
        ]
    );
    assert_eq!(REDACTED, "[REDACTED]");

    for key in [
        "token",
        "access_TOKEN",
        "Password",
        "client_secret",
        "Authorization",
        "my_api_key",
        "APIKEY_header",
        "user_credential",
        "Set_Cookie",
    ] {
        assert!(is_sensitive_key(key), "expected `{key}` to be sensitive");
    }
    for safe in ["request_id", "user", "workspace", "status", "limit"] {
        assert!(!is_sensitive_key(safe), "expected `{safe}` to be safe");
    }
}

#[test]
fn json_formatter_redacts_event_and_span_fields_with_utc_timestamp_and_key_order() {
    let buf = CaptureBuf::default();
    let writer_buf = buf.clone();
    let (subscriber, _handles) = build_scoped_subscriber(
        Profile::Service {
            level: LogLevel::Info,
            format: ServiceLogFormat::Json,
        },
        move || writer_buf.clone(),
    );

    let typed_secret = SecretString::from("sk_live_TYPED_SECRET".to_owned());
    let _guard = tracing::subscriber::set_default(subscriber);
    {
        let span = info_span!(
            "http_request",
            request_id = "req-abc-123",
            api_key = "sk_span_LEAK"
        );
        let _enter = span.enter();
        info!(
            user = "alice",
            token = "sk_live_EVENT_TOKEN",
            password = "hunter2",
            authorization = "Bearer xyz",
            cookie = "sid=secret",
            secret_box = ?typed_secret,
            "processing request"
        );
    }
    drop(_guard);

    let output = buf.text();
    let line = output.trim();
    assert!(!line.is_empty(), "expected JSON log line");

    // Must never contain any secret bytes.
    for leaked in [
        "sk_span_LEAK",
        "sk_live_EVENT_TOKEN",
        "hunter2",
        "Bearer xyz",
        "sid=secret",
        "sk_live_TYPED_SECRET",
    ] {
        assert!(
            !line.contains(leaked),
            "JSON output leaked `{leaked}`: {line}"
        );
    }

    // Must parse as valid JSON with UTC ISO-8601 timestamp and redacted values.
    let val: serde_json::Value = serde_json::from_str(line).expect("valid JSON log line");
    let ts = val["timestamp"].as_str().expect("timestamp string");
    assert!(
        ts.ends_with('Z') && ts.contains('T'),
        "timestamp must be UTC ISO-8601, got: {ts}"
    );
    assert_eq!(val["level"], "INFO");
    assert_eq!(val["user"], "alice");
    assert_eq!(val["token"], "[REDACTED]");
    assert_eq!(val["password"], "[REDACTED]");
    assert_eq!(val["authorization"], "[REDACTED]");
    assert_eq!(val["cookie"], "[REDACTED]");
    assert_eq!(val["span"]["request_id"], "req-abc-123");
    assert_eq!(val["span"]["api_key"], "[REDACTED]");

    // Verify exact R58 key ordering: level -> target -> event fields -> span.
    let idx_level = line.find("\"level\":").expect("level key");
    let idx_target = line.find("\"target\":").expect("target key");
    let idx_user = line.find("\"user\":").expect("event field");
    let idx_span = line.find("\"span\":").expect("span key");
    assert!(idx_level < idx_target && idx_target < idx_user && idx_user < idx_span);
}

#[test]
fn console_formatter_redacts_fields_escapes_control_bytes_and_documents_ov09_boundary() {
    let buf = CaptureBuf::default();
    let writer_buf = buf.clone();
    let (subscriber, _handles) = build_scoped_subscriber(
        Profile::Cli {
            format: LogFormat::Console,
            level: LogLevel::Info,
            ansi: false,
            debug: false,
        },
        move || writer_buf.clone(),
    );

    let _guard = tracing::subscriber::set_default(subscriber);
    {
        let span = info_span!("req", request_id = "r1", secret = "span_secret");
        let _enter = span.enter();
        info!(
            token = "event_secret",
            untrusted = "\u{1b}[31mRED\u{1b}[0m\u{7}",
            url = "https://api.example.com/v1/x?token=in_value_ov09",
            "console test"
        );
    }
    drop(_guard);

    let bytes = buf.bytes();
    assert!(
        !bytes.contains(&0x1b),
        "raw ESC byte must never be emitted (RUSTSEC-2025-0055)"
    );
    assert!(
        !bytes.contains(&0x07),
        "raw BEL byte must never be emitted (RUSTSEC-2025-0055)"
    );

    let text = String::from_utf8_lossy(&bytes);
    assert!(!text.contains("span_secret"), "{text}");
    assert!(!text.contains("event_secret"), "{text}");
    assert!(text.contains("[REDACTED]"), "{text}");
    assert!(
        text.contains("request_id=\"r1\"") || text.contains("request_id=r1"),
        "{text}"
    );
    // OV-09 boundary check: non-sensitive key values are not regex-rewritten.
    assert!(
        text.contains("in_value_ov09"),
        "OV-09 boundary check: {text}"
    );
}

#[test]
fn level_ladder_follows_seven_rung_r58_order() {
    // Rung 7: default WARN.
    assert_eq!(
        resolve_console_level(&LevelLadderInput::default()),
        LogLevel::Warn
    );

    // Rung 6: config beats default.
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            config_log_level: Some(LogLevel::Info),
            ..LevelLadderInput::default()
        }),
        LogLevel::Info
    );

    // Rung 5: env beats config.
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            env_log_level: Some(LogLevel::Debug),
            config_log_level: Some(LogLevel::Error),
            ..LevelLadderInput::default()
        }),
        LogLevel::Debug
    );

    // Rung 4: -v/-vv/-vvv beats env (R5.1 MUST: flags > env!).
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            verbose: 1,
            env_log_level: Some(LogLevel::Error),
            ..LevelLadderInput::default()
        }),
        LogLevel::Info
    );
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            verbose: 2,
            env_log_level: Some(LogLevel::Error),
            ..LevelLadderInput::default()
        }),
        LogLevel::Debug
    );
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            verbose: 3,
            env_log_level: Some(LogLevel::Error),
            ..LevelLadderInput::default()
        }),
        LogLevel::Trace
    );

    // Rung 3: -q beats -v and env (maps to ERROR, not WARN).
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            quiet: true,
            verbose: 3,
            env_log_level: Some(LogLevel::Trace),
            ..LevelLadderInput::default()
        }),
        LogLevel::Error
    );

    // Rung 2: --log-level beats -q and -v.
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            log_level_flag: Some(LogLevel::Off),
            quiet: true,
            verbose: 2,
            ..LevelLadderInput::default()
        }),
        LogLevel::Off
    );

    // Rung 1: --debug beats --log-level and --quiet.
    assert_eq!(
        resolve_console_level(&LevelLadderInput {
            debug: true,
            log_level_flag: Some(LogLevel::Error),
            quiet: true,
            ..LevelLadderInput::default()
        }),
        LogLevel::Trace
    );
}

#[test]
fn format_resolution_and_service_format_validation_match_r58() {
    assert_eq!(LogFormat::Auto.resolve(true), ResolvedLogFormat::Console);
    assert_eq!(LogFormat::Auto.resolve(false), ResolvedLogFormat::Json);
    assert_eq!(
        LogFormat::Console.resolve(false),
        ResolvedLogFormat::Console
    );
    assert_eq!(LogFormat::Json.resolve(true), ResolvedLogFormat::Json);

    assert_eq!(
        resolve_log_format(Some(LogFormat::Json), Some(LogFormat::Console)),
        LogFormat::Json
    );
    assert_eq!(
        resolve_log_format(None, Some(LogFormat::Console)),
        LogFormat::Console
    );
    assert_eq!(resolve_log_format(None, None), LogFormat::Auto);

    assert_eq!(
        ServiceLogFormat::from_str("json").expect("json"),
        ServiceLogFormat::Json
    );
    assert_eq!(
        ServiceLogFormat::from_str("console").expect("console"),
        ServiceLogFormat::Console
    );
    let err_auto = ServiceLogFormat::from_str("auto").expect_err("service rejects auto");
    assert_eq!(err_auto.error_code(), ErrorCode::ConfigInvalid);
}

#[test]
fn reload_handle_swaps_level_and_file_sink_slot_has_independent_level_and_redaction() {
    let tmp = TempDir::new("sink-slot");
    let text_log = tmp.path().join("logs/app-text.log");
    let json_log = tmp.path().join("logs/app-json.log");

    // 1. Text file sink with independent DEBUG level while console is WARN.
    {
        let buf = CaptureBuf::default();
        let writer_buf = buf.clone();
        let (subscriber, handles) = build_scoped_subscriber(
            Profile::Cli {
                format: LogFormat::Console,
                level: LogLevel::Warn,
                ansi: true,
                debug: false,
            },
            move || writer_buf.clone(),
        );

        let _guard = tracing::subscriber::set_default(subscriber);
        info!("BEFORE-RELOAD-DROPPED");

        // Attach file sink at DEBUG while console stays WARN (R59 AC5).
        handles
            .attach_file_sink(&text_log, LogLevel::Debug, FileLogFormat::Text)
            .expect("attach text file sink");

        debug!(token = "file_secret_1", "FILE-ONLY-DEBUG");
        warn!(api_key = "file_secret_2", "BOTH-WARN");

        // Reload console level to INFO and verify console starts receiving info!.
        handles
            .reload_level(LogLevel::Info)
            .expect("reload console level");
        info!("AFTER-RELOAD-INFO");
        drop(_guard);

        let console = buf.text();
        assert!(!console.contains("BEFORE-RELOAD-DROPPED"), "{console}");
        assert!(
            !console.contains("FILE-ONLY-DEBUG"),
            "console at WARN must not receive file's DEBUG event: {console}"
        );
        assert!(console.contains("BOTH-WARN"), "{console}");
        assert!(console.contains("AFTER-RELOAD-INFO"), "{console}");

        let file_bytes = fs::read(&text_log).expect("read text log");
        assert!(
            !file_bytes.contains(&0x1b),
            "file sink must have zero ANSI ESC bytes (R59 AC6)"
        );
        let file_text = String::from_utf8_lossy(&file_bytes);
        assert!(file_text.contains("FILE-ONLY-DEBUG"), "{file_text}");
        assert!(file_text.contains("BOTH-WARN"), "{file_text}");
        assert!(!file_text.contains("file_secret_1"), "{file_text}");
        assert!(!file_text.contains("file_secret_2"), "{file_text}");
        assert!(file_text.contains("[REDACTED]"), "{file_text}");
    }

    // 2. JSON file sink redacts events and emits valid JSON lines.
    {
        let buf = CaptureBuf::default();
        let writer_buf = buf.clone();
        let (subscriber, handles) = build_scoped_subscriber(
            Profile::Cli {
                format: LogFormat::Console,
                level: LogLevel::Warn,
                ansi: false,
                debug: false,
            },
            move || writer_buf.clone(),
        );

        let _guard = tracing::subscriber::set_default(subscriber);
        handles
            .attach_file_sink(&json_log, LogLevel::Debug, FileLogFormat::Json)
            .expect("attach json file sink");

        debug!(password = "json_secret_9", user = "bob", "JSON-FILE-EVENT");
        drop(_guard);

        let file_text = fs::read_to_string(&json_log).expect("read json log");
        assert!(!file_text.contains("json_secret_9"), "{file_text}");
        let line = file_text.trim();
        let val: serde_json::Value = serde_json::from_str(line).expect("valid json file line");
        assert_eq!(val["level"], "DEBUG");
        assert_eq!(val["user"], "bob");
        assert_eq!(val["password"], "[REDACTED]");
    }
}

#[test]
fn rotating_file_rotates_by_size_keeps_five_backups_and_returns_errors_without_panicking() {
    let tmp = TempDir::new("rotate");
    let log_dir = tmp.path().join("state-dir");
    let log_path = log_dir.join("rslbp.log");

    let mut writer = RotatingFile::open(&log_path, 4096, 5).expect("open rotating file");

    // Parent dir created at mode 0700 on Unix (R59).
    let dir_mode = fs::metadata(&log_dir)
        .expect("stat dir")
        .permissions()
        .mode()
        & 0o7777;
    assert_eq!(dir_mode, 0o700);

    // Write 400 fixed-length 73-byte records -> triggers multiple rotations.
    for i in 0..400u32 {
        let record =
            format!("REC-{i:04}-0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcde\n");
        assert_eq!(record.len(), 73);
        writer.write_all(record.as_bytes()).expect("write record");
    }
    writer.flush().expect("flush");

    // Base + .1..=.5 exist; .6 does NOT exist (R59 AC4).
    assert!(log_path.is_file());
    for n in 1..=5 {
        let b = PathBuf::from(format!("{}.{n}", log_path.display()));
        assert!(b.is_file(), "expected backup .{n} to exist");
        let meta = fs::metadata(&b).expect("stat backup");
        assert!(
            meta.len() <= 4096,
            "backup .{n} exceeded 4096: {}",
            meta.len()
        );
        let text = fs::read_to_string(&b).expect("read backup");
        for line in text.lines() {
            assert_eq!(line.len(), 72, "record must never be torn across files");
        }
    }
    let b6 = PathBuf::from(format!("{}.6", log_path.display()));
    assert!(!b6.exists(), "backup .6 must not exist");

    // Verify .1 is newer than .5.
    let first_of_1 = fs::read_to_string(format!("{}.1", log_path.display()))
        .expect("read .1")
        .lines()
        .next()
        .unwrap()
        .to_owned();
    let first_of_5 = fs::read_to_string(format!("{}.5", log_path.display()))
        .expect("read .5")
        .lines()
        .next()
        .unwrap()
        .to_owned();
    assert!(
        first_of_1 > first_of_5,
        ".1 ({first_of_1}) must be newer than .5 ({first_of_5})"
    );

    // Error handling: opening a directory or blocked parent returns Err, never panics (R59 B8).
    assert!(RotatingFile::open(&log_dir, 4096, 5).is_err());
    let blocker = tmp.path().join("blocker");
    fs::write(&blocker, "file").expect("write blocker");
    assert!(RotatingFile::open(blocker.join("child.log"), 4096, 5).is_err());
}

#[test]
fn resolve_log_file_matches_r59_eight_precedence_cases() {
    let default = || Some(PathBuf::from("/state/rslbp/rslbp.log"));

    // P1: nothing -> off
    assert_eq!(resolve_log_file(None, None, None, default), None);
    // P2: config path used
    assert_eq!(
        resolve_log_file(None, None, Some(Path::new("/c.log")), default),
        Some(PathBuf::from("/c.log"))
    );
    // P3: empty config -> off
    assert_eq!(
        resolve_log_file(None, None, Some(Path::new("")), default),
        None
    );
    // P4: env beats config
    assert_eq!(
        resolve_log_file(
            None,
            Some(OsString::from("/e.log")),
            Some(Path::new("/c.log")),
            default
        ),
        Some(PathBuf::from("/e.log"))
    );
    // P5: present-but-empty env selects default
    assert_eq!(
        resolve_log_file(
            None,
            Some(OsString::from("")),
            Some(Path::new("/c.log")),
            default
        ),
        Some(PathBuf::from("/state/rslbp/rslbp.log"))
    );
    // P6: explicit flag beats env
    assert_eq!(
        resolve_log_file(
            Some(Some(PathBuf::from("/f.log"))),
            Some(OsString::from("/e.log")),
            None,
            default
        ),
        Some(PathBuf::from("/f.log"))
    );
    // P7: bare flag selects default
    assert_eq!(
        resolve_log_file(Some(None), Some(OsString::from("/e.log")), None, default),
        Some(PathBuf::from("/state/rslbp/rslbp.log"))
    );
    // P8: bare flag with unresolvable state dir -> off
    assert_eq!(resolve_log_file(Some(None), None, None, || None), None);
}

#[test]
fn init_telemetry_never_panics_when_called_twice_and_renders_sample_lines() {
    // Print sample JSON and console lines (visible under `--nocapture` for manual inspection).
    let json_buf = CaptureBuf::default();
    let json_writer = json_buf.clone();
    let (json_sub, _) = build_scoped_subscriber(
        Profile::Service {
            level: LogLevel::Info,
            format: ServiceLogFormat::Json,
        },
        move || json_writer.clone(),
    );
    let _g1 = tracing::subscriber::set_default(json_sub);
    {
        let span = info_span!(
            "projects_list",
            request_id = "req-42",
            api_key = "sk_span_secret"
        );
        let _e = span.enter();
        info!(user = "alice", token = "sk_live_secret", "fetched projects");
    }
    drop(_g1);
    let json_line = json_buf.text();
    println!("SAMPLE_JSON: {}", json_line.trim());
    assert!(json_line.contains("[REDACTED]"));
    assert!(!json_line.contains("sk_live_secret"));
    assert!(!json_line.contains("sk_span_secret"));

    let console_buf = CaptureBuf::default();
    let console_writer = console_buf.clone();
    let (console_sub, _) = build_scoped_subscriber(
        Profile::Cli {
            format: LogFormat::Console,
            level: LogLevel::Info,
            ansi: false,
            debug: false,
        },
        move || console_writer.clone(),
    );
    let _g2 = tracing::subscriber::set_default(console_sub);
    {
        let span = info_span!(
            "projects_list",
            request_id = "req-42",
            api_key = "sk_span_secret"
        );
        let _e = span.enter();
        info!(user = "alice", token = "sk_live_secret", "fetched projects");
    }
    drop(_g2);
    let console_line = console_buf.text();
    println!("SAMPLE_CONSOLE: {}", console_line.trim());
    assert!(console_line.contains("[REDACTED]"));
    assert!(!console_line.contains("sk_live_secret"));
    assert!(!console_line.contains("sk_span_secret"));

    // Global `init_telemetry` never panics; a second call always reports `HostOwned` (R58).
    let first = init_telemetry(Profile::Cli {
        format: LogFormat::Console,
        level: LogLevel::Warn,
        ansi: false,
        debug: false,
    });
    assert!(matches!(
        first,
        TelemetryInit::Installed(_) | TelemetryInit::HostOwned
    ));
    let second = init_telemetry(Profile::Service {
        level: LogLevel::Info,
        format: ServiceLogFormat::Json,
    });
    assert!(matches!(second, TelemetryInit::HostOwned));
}
