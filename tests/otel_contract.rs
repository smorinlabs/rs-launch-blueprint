//! Contract tests for OpenTelemetry integration (`R78`, `R58`, py `P10` enabled & disabled
//! trace-correlation paths) and the production container recipe (`R51`, owner `1a-A` override).

use std::fs;
use std::io::{self, Write};
use std::path::PathBuf;
use std::sync::{Arc, Mutex};

#[cfg(not(feature = "otel"))]
use rs_launch_blueprint::build_scoped_subscriber;
use rs_launch_blueprint::{LogLevel, Profile, ServiceLogFormat};
use tracing::{info, info_span};

fn repo_root() -> PathBuf {
    if let Some(dir) = std::env::var_os("CARGO_MANIFEST_DIR") {
        let candidate = PathBuf::from(dir);
        if candidate.join("Cargo.toml").is_file() {
            return candidate;
        }
    }
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
}

#[derive(Clone, Default)]
struct CaptureBuf(Arc<Mutex<Vec<u8>>>);

impl CaptureBuf {
    fn text(&self) -> String {
        let guard = self.0.lock().expect("lock capture buf");
        String::from_utf8_lossy(&guard).into_owned()
    }
}

impl Write for CaptureBuf {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        self.0
            .lock()
            .expect("lock capture buf")
            .extend_from_slice(buf);
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        Ok(())
    }
}

#[test]
fn dockerfile_and_dockerignore_satisfy_r51_and_1a_a_contract() {
    let root = repo_root();
    let dockerfile = fs::read_to_string(root.join("Dockerfile")).expect("read Dockerfile");

    assert!(
        dockerfile.starts_with("# syntax=docker/dockerfile:1\n"),
        "Dockerfile must declare BuildKit frontend syntax=docker/dockerfile:1 (R51)"
    );

    // Every FROM must resolve via a digest-pinned ARG (@sha256:).
    let mut from_count = 0usize;
    let mut pinned_args = 0usize;
    for line in dockerfile.lines() {
        let trimmed = line.trim();
        if trimmed.starts_with("ARG ") && trimmed.contains("@sha256:") {
            pinned_args += 1;
        }
        if let Some(rest) = trimmed.strip_prefix("FROM ") {
            from_count += 1;
            assert!(
                rest.starts_with("${"),
                "every FROM must reference a digest-pinned ARG (R51 B5): `{trimmed}`"
            );
        }
    }
    assert_eq!(
        from_count, 3,
        "expected probe, builder, and runtime FROM stages"
    );
    assert_eq!(pinned_args, 3, "expected 3 digest-pinned image ARGs");

    for required in [
        "busybox:1.38.0-musl@sha256:",
        "slim-trixie@sha256:",
        "gcr.io/distroless/cc-debian13:nonroot@sha256:",
        "--mount=type=cache,target=/usr/local/cargo/registry,sharing=locked",
        "--mount=type=cache,target=/src/target,sharing=locked",
        "cargo build --release --locked",
        "--bin rslbp-serve",
        "install -D -m 0755 target/release/rslbp-serve /out/rslbp-serve",
        "ENV RSLBP_WEB_HOST=0.0.0.0",
        "EXPOSE 8000",
        "USER nonroot:nonroot",
        "HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3",
        "\"/bin/busybox\"",
        "\"-T\"",
        "\"2\"",
        "\"http://127.0.0.1:8000/healthz\"",
        "ENTRYPOINT [\"/usr/local/bin/rslbp-serve\"]",
        "org.opencontainers.image.source=",
    ] {
        assert!(
            dockerfile.contains(required),
            "Dockerfile missing required R51/1a-A token `{required}`"
        );
    }
    assert!(
        !dockerfile.lines().any(|line| {
            let trimmed = line.trim();
            !trimmed.starts_with('#') && trimmed.contains("RSLBP_WEB_PORT")
        }),
        "Dockerfile must NOT set RSLBP_WEB_PORT; port 8000 stays R77's single source of truth (R51 C15h)"
    );
    assert!(
        !dockerfile.contains("localhost:8000"),
        "HEALTHCHECK must use 127.0.0.1, never localhost (R51 C2c)"
    );

    let dockerignore = fs::read_to_string(root.join(".dockerignore")).expect("read .dockerignore");
    let lines: Vec<&str> = dockerignore
        .lines()
        .map(str::trim)
        .filter(|l| !l.is_empty() && !l.starts_with('#'))
        .collect();
    assert!(lines.contains(&".git"), ".dockerignore must ignore .git");
    assert!(
        lines.contains(&"target"),
        ".dockerignore must ignore target"
    );
    assert!(
        lines.contains(&"**/target"),
        ".dockerignore must ignore **/target"
    );
    assert!(
        !lines.iter().any(|l| l.contains("Cargo.lock")),
        ".dockerignore must NOT ignore Cargo.lock (--locked requires it, R51 C15l)"
    );
}

#[cfg(not(feature = "otel"))]
mod otel_disabled {
    use super::*;
    use std::process::Command;

    #[test]
    fn otel_disabled_graph_log_correlation_and_env_warning() {
        // 1. Feature-off normal dependency graph contains zero opentelemetry crates (R78 T01).
        let cargo = option_env!("CARGO").unwrap_or("cargo");
        let out = Command::new(cargo)
            .args([
                "tree",
                "--features",
                "web",
                "--edges",
                "normal",
                "--prefix",
                "none",
            ])
            .current_dir(repo_root())
            .output()
            .expect("cargo tree --features web must run");
        assert!(
            out.status.success(),
            "cargo tree failed: {}",
            String::from_utf8_lossy(&out.stderr)
        );
        let tree = String::from_utf8_lossy(&out.stdout);
        for forbidden in [
            "opentelemetry ",
            "opentelemetry_sdk ",
            "tracing-opentelemetry ",
        ] {
            assert!(
                !tree.contains(forbidden),
                "web-only build must not pull `{forbidden}`:\n{tree}"
            );
        }

        // 2. JsonEvent omits trace_id/span_id cleanly when otel feature is not compiled in,
        //    and warn_if_otlp_env_ignored emits one diagnostic warning when OTLP env is set.
        let buf = CaptureBuf::default();
        let writer = buf.clone();
        let (sub, _handles) = build_scoped_subscriber(
            Profile::Service {
                level: LogLevel::Info,
                format: ServiceLogFormat::Json,
            },
            move || writer.clone(),
        );
        let _guard = tracing::subscriber::set_default(sub);
        {
            let span = info_span!("http.server.request", request_id = "req-no-otel");
            let _e = span.enter();
            info!(status = 200u16, "handled without otel");
        }
        rs_launch_blueprint::warn_if_otlp_env_ignored(false, None);
        rs_launch_blueprint::warn_if_otlp_env_ignored(true, Some("http://127.0.0.1:4318"));
        drop(_guard);

        let text = buf.text();
        let lines: Vec<serde_json::Value> = text
            .lines()
            .filter(|l| !l.trim().is_empty())
            .map(|l| serde_json::from_str(l).expect("valid json log line"))
            .collect();
        assert_eq!(
            lines.len(),
            2,
            "expected 1 info line + 1 otel warning: {text}"
        );
        assert!(lines[0].get("trace_id").is_none());
        assert!(lines[0].get("span_id").is_none());
        assert_eq!(lines[1]["level"], "WARN");
        assert!(
            lines[1]["message"].as_str().unwrap_or("").contains("otel"),
            "expected otel warning message: {}",
            lines[1]
        );
    }
}

#[cfg(feature = "otel")]
mod otel_enabled {
    use super::*;
    use std::collections::BTreeMap;
    use std::time::Duration;

    use httpmock::prelude::*;
    use opentelemetry::global;
    use opentelemetry_http::HeaderExtractor;
    use opentelemetry_sdk::error::OTelSdkResult;
    use opentelemetry_sdk::trace::{SpanData, SpanExporter};
    use rs_launch_blueprint::{
        HttpProjectsPort, OtelConfig, OtelInit, ProjectQuery, ProjectsPort, RedactingSpanExporter,
        Token, build_otel_layer_with_exporter, build_scoped_subscriber_with_otel,
        init_otel_from_config, inject_trace_context,
    };
    use tracing_opentelemetry::OpenTelemetrySpanExt as _;

    #[derive(Debug, Clone, Default)]
    struct InMemoryExporter {
        spans: Arc<Mutex<Vec<SpanData>>>,
    }

    impl InMemoryExporter {
        fn spans(&self) -> Vec<SpanData> {
            self.spans.lock().expect("lock spans").clone()
        }
    }

    impl SpanExporter for InMemoryExporter {
        async fn export(&self, batch: Vec<SpanData>) -> OTelSdkResult {
            self.spans.lock().expect("lock spans").extend(batch);
            Ok(())
        }
    }

    #[test]
    fn otel_enabled_exports_redacted_spans_correlates_json_logs_and_injects_outbound_http() {
        let incoming_trace_id = "4bf92f3577b34da6a3ce929d0e0e4736";
        let incoming_parent_id = "00f067aa0ca902b7";
        let traceparent = format!("00-{incoming_trace_id}-{incoming_parent_id}-01");

        // Local mock upstream HTTP server asserting HttpProjectsPort injects W3C traceparent
        // carrying the incoming trace ID (R78 point 5).
        let mock_server = MockServer::start();
        let expected_tp_prefix = format!("00-{incoming_trace_id}-");
        let list_mock = mock_server.mock(|when, then| {
            when.method(GET)
                .path("/projects")
                .header_exists("traceparent");
            then.status(200)
                .header("content-type", "application/json")
                .body(r#"{"data":[{"id":"p1","name":"Alpha","workspace":"eng"}]}"#);
        });

        let exporter = InMemoryExporter::default();
        let (otel_layer, otel_guard) =
            build_otel_layer_with_exporter("rslbp-web", exporter.clone(), Duration::from_secs(2));

        let log_buf = CaptureBuf::default();
        let writer = log_buf.clone();
        let (subscriber, _handles) = build_scoped_subscriber_with_otel(
            Profile::Service {
                level: LogLevel::Info,
                format: ServiceLogFormat::Json,
            },
            move || writer.clone(),
            Some(otel_layer),
        );

        let mut outbound_headers = ureq::http::HeaderMap::new();
        {
            let _sub_guard = tracing::subscriber::set_default(subscriber);

            // Simulate incoming HTTP server span with remote W3C traceparent parent.
            let mut inbound = ureq::http::HeaderMap::new();
            inbound.insert(
                "traceparent",
                ureq::http::HeaderValue::from_str(&traceparent).unwrap(),
            );
            let parent_cx =
                global::get_text_map_propagator(|p| p.extract(&HeaderExtractor(&inbound)));

            let server_span = info_span!(
                "http.server.request",
                otel.kind = "server",
                http.route = "/v1/projects",
                request_id = "req-otel-1"
            );
            let _ = server_span.set_parent(parent_cx);
            let _server_enter = server_span.enter();

            // Emit a child span carrying sensitive attributes & event fields to prove
            // RedactingSpanExporter masks both span and event attributes (R78 rev 3, R58).
            let work_span = info_span!(
                "demo.work",
                token = "sk_live_SPAN_SECRET",
                api_key = "ak_SPAN_KEY",
                safe_attr = "visible"
            );
            let _work_enter = work_span.enter();
            info!(
                password = "EVENT_SECRET_PW",
                authorization = "Bearer EVENT_AUTH",
                user = "alice",
                "correlated event"
            );
            inject_trace_context(&mut outbound_headers);

            // Execute a real outbound HTTP call via HttpProjectsPort inside the traced request.
            let port = HttpProjectsPort::new(
                mock_server.base_url(),
                Token::new("sk_test_outbound_secret".to_owned()),
            );
            let projects = port.list(&ProjectQuery::default()).expect("mock list ok");
            assert_eq!(projects.len(), 1);
        }

        otel_guard.shutdown_blocking().expect("otel shutdown");
        list_mock.assert();

        // 1. Outbound header injection carries W3C traceparent with the SAME incoming trace ID.
        let injected = outbound_headers
            .get("traceparent")
            .and_then(|v| v.to_str().ok())
            .expect("inject_trace_context must write W3C traceparent");
        assert!(
            injected.starts_with(&expected_tp_prefix) && injected.split('-').count() == 4,
            "injected traceparent `{injected}` must preserve trace id `{incoming_trace_id}`"
        );

        // 2. JSON log correlation: event line carries incoming trace_id + valid 16-hex span_id
        //    in exact R58 key order (level < target < trace_id < span_id < event fields < span).
        let log_text = log_buf.text();
        let corr_line = log_text
            .lines()
            .find(|l| l.contains("correlated event"))
            .unwrap_or_else(|| panic!("expected correlated event log line in:\n{log_text}"));
        let parsed: serde_json::Value = serde_json::from_str(corr_line).unwrap();
        assert_eq!(
            parsed["trace_id"].as_str(),
            Some(incoming_trace_id),
            "log line must correlate with incoming traceparent: {corr_line}"
        );
        let span_id = parsed["span_id"].as_str().expect("span_id string");
        assert_eq!(span_id.len(), 16, "span_id must be 16 hex chars: {span_id}");
        assert_eq!(parsed["password"], "[REDACTED]");
        assert_eq!(parsed["authorization"], "[REDACTED]");

        let idx_level = corr_line.find("\"level\":").unwrap();
        let idx_target = corr_line.find("\"target\":").unwrap();
        let idx_trace = corr_line.find("\"trace_id\":").unwrap();
        let idx_span_id = corr_line.find("\"span_id\":").unwrap();
        let idx_user = corr_line.find("\"user\":").unwrap();
        let idx_span = corr_line.find("\"span\":").unwrap();
        assert!(
            idx_level < idx_target
                && idx_target < idx_trace
                && idx_trace < idx_span_id
                && idx_span_id < idx_user
                && idx_user < idx_span,
            "R58 key ordering violated in: {corr_line}"
        );

        // 3. Exported spans: server span carries remote parent + route, client span shares trace,
        //    and RedactingSpanExporter masked sensitive attributes on both spans and span events!
        let spans = exporter.spans();
        let server_span = spans
            .iter()
            .find(|s| s.name == "http.server.request")
            .unwrap_or_else(|| panic!("missing http.server.request span in: {spans:?}"));
        assert_eq!(
            server_span.span_context.trace_id().to_string(),
            incoming_trace_id
        );
        assert_eq!(server_span.parent_span_id.to_string(), incoming_parent_id);

        let client_span = spans
            .iter()
            .find(|s| s.name == "http.client.request")
            .unwrap_or_else(|| panic!("missing http.client.request span in: {spans:?}"));
        assert_eq!(
            client_span.span_context.trace_id().to_string(),
            incoming_trace_id
        );

        let work = spans
            .iter()
            .find(|s| s.name == "demo.work")
            .unwrap_or_else(|| panic!("missing demo.work span in: {spans:?}"));
        let attrs: BTreeMap<String, String> = work
            .attributes
            .iter()
            .map(|kv| (kv.key.as_str().to_owned(), kv.value.as_str().into_owned()))
            .collect();
        assert_eq!(attrs.get("safe_attr").map(String::as_str), Some("visible"));
        assert_eq!(attrs.get("token").map(String::as_str), Some("[REDACTED]"));
        assert_eq!(attrs.get("api_key").map(String::as_str), Some("[REDACTED]"));

        let dumped = format!("{work:?}");
        for leaked in [
            "sk_live_SPAN_SECRET",
            "ak_SPAN_KEY",
            "EVENT_SECRET_PW",
            "Bearer EVENT_AUTH",
        ] {
            assert!(
                !dumped.contains(leaked),
                "RedactingSpanExporter leaked `{leaked}` in exported SpanData: {dumped}"
            );
        }
    }

    #[test]
    fn otel_runtime_disabled_kill_switch_and_invalid_endpoint_degrade_cleanly() {
        // Gate 2a: otel_enabled = false -> Disabled, no panic, no OTel layer.
        let disabled = init_otel_from_config(&OtelConfig {
            enabled: false,
            sdk_disabled: false,
            service_name: "rslbp-web".to_owned(),
            shutdown_timeout: Duration::from_secs(2),
            endpoint_override: None,
        });
        assert!(matches!(disabled, OtelInit::Disabled));

        // Gate 2b: OTEL_SDK_DISABLED=true overrides otel_enabled = true (R78 D06/D07).
        let killed = init_otel_from_config(&OtelConfig {
            enabled: true,
            sdk_disabled: true,
            service_name: "rslbp-web".to_owned(),
            shutdown_timeout: Duration::from_secs(2),
            endpoint_override: None,
        });
        assert!(matches!(killed, OtelInit::Disabled));

        // Gate 3: invalid OTLP endpoint returns Unavailable (never panics, R78 D08/D09).
        let bad_ep = init_otel_from_config(&OtelConfig {
            enabled: true,
            sdk_disabled: false,
            service_name: "rslbp-web".to_owned(),
            shutdown_timeout: Duration::from_secs(2),
            endpoint_override: Some("::not a valid url".to_owned()),
        });
        assert!(
            matches!(bad_ep, OtelInit::Unavailable { .. }),
            "expected Unavailable for invalid endpoint, got {bad_ep:?}"
        );

        // When OTel layer is None even under `--features otel`, JsonEvent omits trace_id/span_id.
        let buf = CaptureBuf::default();
        let writer = buf.clone();
        let (sub, _handles) = build_scoped_subscriber_with_otel(
            Profile::Service {
                level: LogLevel::Info,
                format: ServiceLogFormat::Json,
            },
            move || writer.clone(),
            None,
        );
        let _guard = tracing::subscriber::set_default(sub);
        {
            let span = info_span!("http.server.request", request_id = "req-flag-off");
            let _e = span.enter();
            info!(status = 200u16, "otel flag off");
        }
        drop(_guard);
        let line = buf.text();
        let parsed: serde_json::Value = serde_json::from_str(line.trim()).unwrap();
        assert!(parsed.get("trace_id").is_none());
        assert!(parsed.get("span_id").is_none());

        // Direct RedactingSpanExporter wrapper compiles cleanly on arbitrary SpanExporter.
        let _wrapped = RedactingSpanExporter::new(InMemoryExporter::default());
        let _cfg = OtelConfig::from_process_env(false, Duration::from_secs(2));
        rs_launch_blueprint::warn_if_otlp_env_ignored(true, Some("http://127.0.0.1:4318"));
    }

    #[derive(Debug)]
    struct SecretInnerError;

    impl std::fmt::Display for SecretInnerError {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.write_str("INNER_SECRET_SOURCE_VALUE")
        }
    }

    impl std::error::Error for SecretInnerError {}

    #[derive(Debug)]
    struct SecretOuterError(SecretInnerError);

    impl std::fmt::Display for SecretOuterError {
        fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
            f.write_str("OUTER_SECRET_DISPLAY_VALUE")
        }
    }

    impl std::error::Error for SecretOuterError {
        fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
            Some(&self.0)
        }
    }

    #[test]
    fn otel_redacts_sensitive_typed_errors_and_correlates_explicit_event_parents() {
        let exporter = InMemoryExporter::default();
        let (otel_layer, otel_guard) =
            build_otel_layer_with_exporter("rslbp-web", exporter.clone(), Duration::from_secs(2));

        let log_buf = CaptureBuf::default();
        let writer = log_buf.clone();
        let (subscriber, _handles) = build_scoped_subscriber_with_otel(
            Profile::Service {
                level: LogLevel::Info,
                format: ServiceLogFormat::Json,
            },
            move || writer.clone(),
            Some(otel_layer),
        );

        let err = SecretOuterError(SecretInnerError);
        {
            let _sub_guard = tracing::subscriber::set_default(subscriber);

            // Create two independent root spans A and B; enter A, emit explicit parent: &B and
            // explicit parent: None events, plus sensitive typed errors on span and event.
            let span_a = info_span!("span_a", token = &err as &dyn std::error::Error);
            let span_b = info_span!("span_b");

            let _enter_a = span_a.enter();
            info!(secret = &err as &dyn std::error::Error, "error in span_a");
            info!(parent: &span_b, "explicit parent span_b");
            info!(parent: None, "explicit parentless event");
        }

        otel_guard.shutdown_blocking().expect("otel shutdown");

        // 1. Sensitive typed error on both span and event MUST NOT leak into exported SpanData
        //    (including via tracing-opentelemetry's exception.message / exception.stacktrace).
        let spans = exporter.spans();
        let dumped = format!("{spans:?}");
        for leaked in ["OUTER_SECRET_DISPLAY_VALUE", "INNER_SECRET_SOURCE_VALUE"] {
            assert!(
                !dumped.contains(leaked),
                "sensitive typed error leaked `{leaked}` into exported SpanData: {dumped}"
            );
        }

        let span_a_data = spans
            .iter()
            .find(|s| s.name == "span_a")
            .expect("exported span_a");
        let span_b_data = spans
            .iter()
            .find(|s| s.name == "span_b")
            .expect("exported span_b");
        let trace_a = span_a_data.span_context.trace_id().to_string();
        let span_id_a = span_a_data.span_context.span_id().to_string();
        let trace_b = span_b_data.span_context.trace_id().to_string();
        let span_id_b = span_b_data.span_context.span_id().to_string();
        assert_ne!(
            trace_a, trace_b,
            "independent roots must have distinct trace IDs"
        );

        // 2. JSON log correlation matches each event's effective parent span (not just entered).
        let log_text = log_buf.text();
        let parse_msg = |needle: &str| -> serde_json::Value {
            let line = log_text
                .lines()
                .find(|l| l.contains(needle))
                .unwrap_or_else(|| panic!("missing `{needle}` in:\n{log_text}"));
            serde_json::from_str(line).expect("parse json log line")
        };

        let ev_a = parse_msg("error in span_a");
        assert_eq!(ev_a["trace_id"].as_str(), Some(trace_a.as_str()));
        assert_eq!(ev_a["span_id"].as_str(), Some(span_id_a.as_str()));
        assert_eq!(ev_a["secret"], "[REDACTED]");

        let ev_b = parse_msg("explicit parent span_b");
        assert_eq!(ev_b["span"]["name"], "span_b");
        assert_eq!(ev_b["trace_id"].as_str(), Some(trace_b.as_str()));
        assert_eq!(ev_b["span_id"].as_str(), Some(span_id_b.as_str()));

        let ev_none = parse_msg("explicit parentless event");
        assert!(ev_none.get("span").is_none());
        assert!(
            ev_none.get("trace_id").is_none() && ev_none.get("span_id").is_none(),
            "parent: None event must omit trace_id/span_id: {ev_none}"
        );
    }

    #[test]
    fn otel_exporter_lifecycle_debug_and_active_otlp_init() {
        let mut redacting = RedactingSpanExporter::new(InMemoryExporter::default());
        let resource = opentelemetry_sdk::Resource::builder()
            .with_service_name("rslbp-test")
            .build();
        redacting.set_resource(&resource);
        redacting.force_flush().expect("force_flush delegates");
        redacting.shutdown().expect("shutdown delegates");

        let disabled = OtelInit::Disabled;
        assert_eq!(format!("{disabled:?}"), "OtelInit::Disabled");
        let unavailable = OtelInit::Unavailable {
            reason: "bad endpoint".to_owned(),
        };
        assert!(format!("{unavailable:?}").contains("bad endpoint"));

        let cfg = OtelConfig {
            enabled: true,
            sdk_disabled: false,
            service_name: "rslbp-web-test".to_owned(),
            shutdown_timeout: Duration::from_millis(50),
            endpoint_override: Some("http://127.0.0.1:1/v1/traces".to_owned()),
        };
        let init = init_otel_from_config(&cfg);
        let debug_repr = format!("{init:?}");
        assert!(
            debug_repr.contains("OtelInit::Active") && debug_repr.contains("OtelGuard"),
            "expected Active OtelInit debug representation, got: {debug_repr}"
        );
        match init {
            OtelInit::Active { guard, .. } => {
                // Bounded shutdown on a blocking/main OS thread (R78 point 7).
                let _ = guard.shutdown_blocking();
            }
            other => panic!("expected OtelInit::Active, got {other:?}"),
        }
    }
}
