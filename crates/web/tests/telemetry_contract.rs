//! Contract tests for web service structured telemetry, composition wiring, and `Exit` mapping
//! (`R58`, `R67`, `R69`, `R77`, `OV-18`).

use std::io::{self, Write};
use std::process::ExitCode;
use std::str::FromStr;
use std::sync::{Arc, Mutex};

use rs_launch_blueprint::{Diagnostics, ErrorCode, LogLevel, Token, in_memory_service};
use rs_launch_blueprint_web::{
    DiagnosticsRunner, Exit, REDACTED, SENSITIVE_KEY_PARTS, ServiceLogFormat, ServiceTelemetryInit,
    ServiceTelemetryProfile, WebSettings, build_router, build_service_subscriber,
    build_web_app_state, init_service_telemetry, is_sensitive_key, web_http_projects_port,
    web_production_service,
};
use tracing::{info, info_span};

#[derive(Clone, Default)]
struct CaptureBuf(Arc<Mutex<Vec<u8>>>);

impl CaptureBuf {
    fn text(&self) -> String {
        let guard = self.0.lock().expect("lock buf");
        String::from_utf8_lossy(&guard).into_owned()
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
fn service_log_format_and_sensitive_vocabulary_match_r58_and_r77() {
    assert_eq!(REDACTED, "[REDACTED]");
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
    assert!(is_sensitive_key("Authorization"));
    assert!(is_sensitive_key("api_key"));
    assert!(!is_sensitive_key("request_id"));

    assert_eq!(
        ServiceLogFormat::from_str("json").expect("json"),
        ServiceLogFormat::Json
    );
    assert_eq!(
        ServiceLogFormat::from_str("console").expect("console"),
        ServiceLogFormat::Console
    );
    assert_eq!(ServiceLogFormat::Json.as_str(), "json");
    assert_eq!(ServiceLogFormat::Json.to_string(), "json");
    assert_eq!(ServiceLogFormat::Console.as_str(), "console");
    assert_eq!(ServiceLogFormat::Console.to_string(), "console");

    let err_auto = ServiceLogFormat::from_str("auto").expect_err("service rejects auto");
    assert_eq!(err_auto.error_code(), ErrorCode::ConfigInvalid);
    assert!(ServiceLogFormat::from_str("xml").is_err());
}

#[test]
fn service_subscribers_redact_fields_support_reload_and_never_panic_on_reinit() {
    for (format, expect_json) in [
        (ServiceLogFormat::Json, true),
        (ServiceLogFormat::Console, false),
    ] {
        let buf = CaptureBuf::default();
        let writer = buf.clone();
        let (sub, handles) = build_service_subscriber(
            ServiceTelemetryProfile {
                level: LogLevel::Warn,
                format,
            },
            move || writer.clone(),
        );
        assert!(format!("{handles:?}").contains("ServiceTelemetryHandles"));

        let _guard = tracing::subscriber::set_default(sub);
        info!("DROPPED-BEFORE-RELOAD");
        handles
            .reload_level(LogLevel::Trace)
            .expect("reload service level");

        let span = info_span!(
            "http_req",
            request_id = tracing::field::Empty,
            api_key = tracing::field::Empty
        );
        let _enter = span.enter();
        span.record("request_id", "req-99");
        span.record("api_key", "SPAN_SECRET_99");

        info!(
            i = -42_i64,
            u = 42_u64,
            flag = true,
            spaced = "hello \"world\"\x1b[31m",
            dbg_val = ?vec![1, 2],
            token_i = -1_i64,
            token_u = 1_u64,
            token_b = false,
            token_s = "SECRET_STR",
            token_d = ?("SECRET_DBG"),
            timestamp = "collision",
            level = "collision",
            "service event"
        );
        drop(_enter);
        drop(_guard);

        let output = buf.text();
        assert!(!output.contains("DROPPED-BEFORE-RELOAD"), "{output}");
        assert!(!output.contains("SPAN_SECRET_99"), "{output}");
        assert!(!output.contains("SECRET_STR"), "{output}");
        assert!(!output.contains("SECRET_DBG"), "{output}");
        assert!(output.contains("[REDACTED]"), "{output}");
        assert!(output.contains("service event"), "{output}");

        if expect_json {
            assert!(output.contains("field_timestamp") && output.contains("field_level"));
            let parsed: serde_json::Value =
                serde_json::from_str(output.trim()).expect("valid json line");
            assert_eq!(parsed["i"], -42);
            assert_eq!(parsed["u"], 42);
            assert_eq!(parsed["flag"], true);
            assert_eq!(parsed["span"]["request_id"], "req-99");
            assert_eq!(parsed["span"]["api_key"], "[REDACTED]");
        } else {
            assert!(!output.as_bytes().contains(&0x1b), "{output}");
        }
    }

    let first = init_service_telemetry(ServiceTelemetryProfile {
        level: LogLevel::Info,
        format: ServiceLogFormat::Json,
    });
    assert!(matches!(
        first,
        ServiceTelemetryInit::Installed(_) | ServiceTelemetryInit::HostOwned
    ));
    let second = init_service_telemetry(ServiceTelemetryProfile {
        level: LogLevel::Warn,
        format: ServiceLogFormat::Console,
    });
    assert!(matches!(second, ServiceTelemetryInit::HostOwned));
}

#[test]
fn web_composition_and_exit_mapping_work() {
    let svc = in_memory_service([]);
    let settings = WebSettings::default();
    let diag: DiagnosticsRunner = Arc::new(|| Diagnostics { checks: Vec::new() });
    let state = build_web_app_state(svc, settings, diag);
    assert!(state.readiness.is_ready());
    let _router = build_router(state);

    let port = web_http_projects_port("http://127.0.0.1:1", Token::new("tok"));
    assert_eq!(port.base_url(), "http://127.0.0.1:1");
    let _prod = web_production_service("http://127.0.0.1:1", Token::new("tok"));

    assert_eq!(Exit::Success.code(), 0);
    assert_eq!(Exit::Runtime.code(), 1);
    assert_eq!(Exit::Usage.code(), 2);
    assert_eq!(Exit::SigInt.code(), 130);
    assert_eq!(Exit::SigTerm.code(), 143);
    let _code: ExitCode = Exit::SigTerm.into();

    assert_eq!(Exit::from_error_code(ErrorCode::Usage), Exit::Usage);
    assert_eq!(Exit::from_error_code(ErrorCode::ConfigInvalid), Exit::Usage);
    assert_eq!(Exit::from_error_code(ErrorCode::SigInt), Exit::SigInt);
    assert_eq!(Exit::from_error_code(ErrorCode::SigTerm), Exit::SigTerm);
    assert_eq!(Exit::from_error_code(ErrorCode::Io), Exit::Runtime);
}
