//! Structured service diagnostic logging pipeline (`R58`, `R77`, `R78`, `OV-09`, `OV-18`).
//!
//! Emits structured JSON or console logs exclusively to `stderr` (never `stdout`) with sensitive
//! field redaction and optional OpenTelemetry `trace_id`/`span_id` log correlation.

use std::fmt;
use std::io;
use std::str::FromStr;

use rs_launch_blueprint::{ConfigError, LogLevel};
use serde::{Deserialize, Serialize};
use tracing::Subscriber;
use tracing::field::{Field, Visit};
use tracing::level_filters::LevelFilter;
use tracing_subscriber::field::RecordFields;
use tracing_subscriber::fmt::format::Writer;
use tracing_subscriber::fmt::time::FormatTime;
use tracing_subscriber::fmt::{FmtContext, FormatEvent, FormatFields, FormattedFields, MakeWriter};
use tracing_subscriber::layer::{Layer, SubscriberExt};
use tracing_subscriber::registry::LookupSpan;
use tracing_subscriber::util::SubscriberInitExt;
use tracing_subscriber::{EnvFilter, Registry, reload};

/// Replacement token emitted for every sensitive field key (`R58`).
pub const REDACTED: &str = "[REDACTED]";

/// Substring vocabulary matching sensitive tracing field names case-insensitively (`R58` F252).
pub const SENSITIVE_KEY_PARTS: [&str; 8] = [
    "token",
    "password",
    "secret",
    "authorization",
    "api_key",
    "apikey",
    "credential",
    "cookie",
];

/// Return `true` if `name` matches any substring in [`SENSITIVE_KEY_PARTS`] case-insensitively.
#[must_use]
pub fn is_sensitive_key(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    SENSITIVE_KEY_PARTS.iter().any(|part| lower.contains(part))
}

/// Concrete log format accepted by the web/service profile (`R58`, `R77`).
///
/// Deliberately rejects `auto` (`RSLB203` / `ConfigError::InvalidValue`) so service deployments
/// never silently switch formats based on container TTY allocation.
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ServiceLogFormat {
    /// Newline-delimited structured JSON objects (default for services).
    #[default]
    Json,
    /// Human-readable console lines for local development.
    Console,
}

impl ServiceLogFormat {
    /// Canonical lowercase representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Json => "json",
            Self::Console => "console",
        }
    }
}

impl fmt::Display for ServiceLogFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for ServiceLogFormat {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "json" => Ok(Self::Json),
            "console" => Ok(Self::Console),
            "auto" => Err(ConfigError::InvalidValue {
                path: None,
                key: "logging.format".to_owned(),
                detail: "service profile does not accept 'auto'; choose 'json' or 'console'"
                    .to_owned(),
            }),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "logging.format".to_owned(),
                detail: format!("expected one of: json, console (got '{s}')"),
            }),
        }
    }
}

/// Service telemetry subscriber configuration (`R58`, `R77`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct ServiceTelemetryProfile {
    /// Initial service log level.
    pub level: LogLevel,
    /// Explicit concrete format (`json` or `console`).
    pub format: ServiceLogFormat,
}

/// Convert [`LogLevel`] to a [`LevelFilter`].
#[must_use]
pub const fn level_to_filter(level: LogLevel) -> LevelFilter {
    match level {
        LogLevel::Off => LevelFilter::OFF,
        LogLevel::Error => LevelFilter::ERROR,
        LogLevel::Warn => LevelFilter::WARN,
        LogLevel::Info => LevelFilter::INFO,
        LogLevel::Debug => LevelFilter::DEBUG,
        LogLevel::Trace => LevelFilter::TRACE,
    }
}

/// Convert [`LogLevel`] to a single-directive [`EnvFilter`].
#[must_use]
pub fn level_to_env_filter(level: LogLevel) -> EnvFilter {
    EnvFilter::default().add_directive(level_to_filter(level).into())
}

fn escape_control_chars(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    for ch in input.chars() {
        if ch.is_control() {
            for escaped in ch.escape_default() {
                out.push(escaped);
            }
        } else {
            out.push(ch);
        }
    }
    out
}

/// Redacting and control-character-escaping human field formatter for console service logs (`R58`).
#[derive(Debug, Default, Clone, Copy)]
pub struct ServiceHumanFields;

struct HumanVisitor<'a> {
    writer: Writer<'a>,
    has_written: bool,
    result: fmt::Result,
}

impl<'a> HumanVisitor<'a> {
    fn new(writer: Writer<'a>) -> Self {
        Self {
            writer,
            has_written: false,
            result: Ok(()),
        }
    }

    fn write_field_raw(&mut self, name: &str, text: &str, quote_if_spaced: bool) {
        if self.result.is_err() {
            return;
        }
        let res = (|| -> fmt::Result {
            if self.has_written {
                self.writer.write_char(' ')?;
            }
            self.has_written = true;
            if name == "message" {
                self.writer.write_str(text)
            } else if quote_if_spaced
                && (text.is_empty() || text.chars().any(|c| c.is_whitespace() || c == '"'))
            {
                write!(self.writer, "{name}=\"{}\"", text.replace('"', "\\\""))
            } else {
                write!(self.writer, "{name}={text}")
            }
        })();
        self.result = res;
    }

    fn write_redacted(&mut self, name: &str) {
        self.write_field_raw(name, REDACTED, false);
    }

    fn finish(self) -> fmt::Result {
        self.result
    }
}

impl Visit for HumanVisitor<'_> {
    fn record_i64(&mut self, field: &Field, value: i64) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            self.write_field_raw(field.name(), &value.to_string(), false);
        }
    }

    fn record_u64(&mut self, field: &Field, value: u64) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            self.write_field_raw(field.name(), &value.to_string(), false);
        }
    }

    fn record_bool(&mut self, field: &Field, value: bool) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            self.write_field_raw(field.name(), if value { "true" } else { "false" }, false);
        }
    }

    fn record_str(&mut self, field: &Field, value: &str) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            let safe = escape_control_chars(value);
            self.write_field_raw(field.name(), &safe, true);
        }
    }

    fn record_debug(&mut self, field: &Field, value: &dyn fmt::Debug) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            let safe = escape_control_chars(&format!("{value:?}"));
            self.write_field_raw(field.name(), &safe, field.name() != "message");
        }
    }
}

impl<'writer> FormatFields<'writer> for ServiceHumanFields {
    fn format_fields<R: RecordFields>(&self, writer: Writer<'writer>, fields: R) -> fmt::Result {
        let mut visitor = HumanVisitor::new(writer);
        fields.record(&mut visitor);
        visitor.finish()
    }
}

#[derive(Default)]
struct JsonObjVisitor {
    fields: Vec<(String, serde_json::Value)>,
}

impl JsonObjVisitor {
    fn push(&mut self, name: &str, value: serde_json::Value) {
        if let Some(slot) = self.fields.iter_mut().find(|(k, _)| k == name) {
            slot.1 = value;
        } else {
            self.fields.push((name.to_owned(), value));
        }
    }

    fn push_redacted(&mut self, name: &str) {
        self.push(name, serde_json::Value::String(REDACTED.to_owned()));
    }
}

impl Visit for JsonObjVisitor {
    fn record_i64(&mut self, field: &Field, value: i64) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::from(value));
        }
    }

    fn record_u64(&mut self, field: &Field, value: u64) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::from(value));
        }
    }

    fn record_bool(&mut self, field: &Field, value: bool) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::Bool(value));
        }
    }

    fn record_str(&mut self, field: &Field, value: &str) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::String(value.to_owned()));
        }
    }

    fn record_debug(&mut self, field: &Field, value: &dyn fmt::Debug) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(
                field.name(),
                serde_json::Value::String(format!("{value:?}")),
            );
        }
    }
}

/// Redacting span field formatter storing span attributes as serialized JSON objects (`R58`).
#[derive(Debug, Default, Clone, Copy)]
pub struct ServiceJsonFields;

impl<'writer> FormatFields<'writer> for ServiceJsonFields {
    fn format_fields<R: RecordFields>(
        &self,
        mut writer: Writer<'writer>,
        fields: R,
    ) -> fmt::Result {
        let mut visitor = JsonObjVisitor::default();
        fields.record(&mut visitor);
        let map: serde_json::Map<String, serde_json::Value> = visitor.fields.into_iter().collect();
        let rendered = serde_json::to_string(&map).map_err(|_| fmt::Error)?;
        writer.write_str(&rendered)
    }

    fn add_fields(
        &self,
        current: &'writer mut FormattedFields<Self>,
        fields: &tracing::span::Record<'_>,
    ) -> fmt::Result {
        let mut map = if current.fields.is_empty() {
            serde_json::Map::new()
        } else {
            serde_json::from_str::<serde_json::Map<String, serde_json::Value>>(&current.fields)
                .unwrap_or_default()
        };
        let mut visitor = JsonObjVisitor::default();
        fields.record(&mut visitor);
        for (k, v) in visitor.fields {
            map.insert(k, v);
        }
        current.fields = serde_json::to_string(&map).map_err(|_| fmt::Error)?;
        Ok(())
    }
}

#[cfg(feature = "otel")]
type OtelDispatchSlot = std::sync::Arc<std::sync::OnceLock<tracing::dispatcher::WeakDispatch>>;

#[cfg(feature = "otel")]
struct DispatchCaptureLayer {
    slot: Option<OtelDispatchSlot>,
}

#[cfg(feature = "otel")]
impl<S: Subscriber> Layer<S> for DispatchCaptureLayer {
    fn on_register_dispatch(&self, collector: &tracing::Dispatch) {
        if let Some(slot) = &self.slot {
            let _ = slot.set(collector.downgrade());
        }
    }
}

/// Single-line JSON event formatter for the web service with optional OTel `trace_id`/`span_id`
/// correlation (`R58`, `R78`).
#[derive(Debug, Default, Clone)]
pub struct ServiceJsonEvent {
    otel_enabled: bool,
    #[cfg(feature = "otel")]
    otel_dispatch: Option<OtelDispatchSlot>,
}

impl ServiceJsonEvent {
    /// Construct a [`ServiceJsonEvent`] formatter.
    #[must_use]
    pub const fn new(otel_enabled: bool) -> Self {
        Self {
            otel_enabled,
            #[cfg(feature = "otel")]
            otel_dispatch: None,
        }
    }

    #[cfg(feature = "otel")]
    fn with_otel_dispatch(otel_dispatch: Option<OtelDispatchSlot>) -> Self {
        Self {
            otel_enabled: otel_dispatch.is_some(),
            otel_dispatch,
        }
    }
}

fn push_json_kv(
    out: &mut String,
    first: bool,
    key: &str,
    value: &serde_json::Value,
) -> fmt::Result {
    if !first {
        out.push(',');
    }
    let k = serde_json::to_string(key).map_err(|_| fmt::Error)?;
    let v = serde_json::to_string(value).map_err(|_| fmt::Error)?;
    out.push_str(&k);
    out.push(':');
    out.push_str(&v);
    Ok(())
}

impl<S, N> FormatEvent<S, N> for ServiceJsonEvent
where
    S: Subscriber + for<'a> LookupSpan<'a>,
    N: for<'a> FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &tracing::Event<'_>,
    ) -> fmt::Result {
        let meta = event.metadata();
        let mut out = String::with_capacity(256);
        out.push('{');

        let mut ts = String::with_capacity(32);
        tracing_subscriber::fmt::time::SystemTime.format_time(&mut Writer::new(&mut ts))?;
        push_json_kv(&mut out, true, "timestamp", &serde_json::Value::String(ts))?;

        push_json_kv(
            &mut out,
            false,
            "level",
            &serde_json::Value::String(meta.level().as_str().to_owned()),
        )?;
        push_json_kv(
            &mut out,
            false,
            "target",
            &serde_json::Value::String(meta.target().to_owned()),
        )?;

        #[cfg(feature = "otel")]
        let emitted_trace_slot = if self.otel_enabled {
            use opentelemetry::trace::TraceContextExt as _;

            let parent_span_id = ctx
                .event_scope()
                .and_then(|mut scope| scope.next().map(|span| span.id()));
            let otel_cx = parent_span_id.and_then(|span_id| {
                if let Some(dispatch) = self
                    .otel_dispatch
                    .as_ref()
                    .and_then(|slot| slot.get())
                    .and_then(tracing::dispatcher::WeakDispatch::upgrade)
                {
                    tracing_opentelemetry::get_otel_context(&span_id, &dispatch)
                } else if ctx.lookup_current().is_some_and(|cur| cur.id() == span_id) {
                    Some(opentelemetry::Context::current())
                } else {
                    None
                }
            });

            if let Some(cx) = otel_cx {
                let span_ref = cx.span();
                let sc = span_ref.span_context();
                if sc.is_valid() {
                    push_json_kv(
                        &mut out,
                        false,
                        "trace_id",
                        &serde_json::Value::String(sc.trace_id().to_string()),
                    )?;
                    push_json_kv(
                        &mut out,
                        false,
                        "span_id",
                        &serde_json::Value::String(sc.span_id().to_string()),
                    )?;
                    true
                } else {
                    false
                }
            } else {
                false
            }
        } else {
            false
        };
        #[cfg(not(feature = "otel"))]
        let emitted_trace_slot = {
            let _ = self.otel_enabled;
            false
        };

        let mut visitor = JsonObjVisitor::default();
        event.record(&mut visitor);
        if let Some(pos) = visitor.fields.iter().position(|(k, _)| k == "message") {
            let (k, v) = visitor.fields.remove(pos);
            push_json_kv(&mut out, false, &k, &v)?;
        }
        for (k, v) in visitor.fields {
            let is_reserved = matches!(k.as_str(), "timestamp" | "level" | "target" | "span")
                || (emitted_trace_slot && matches!(k.as_str(), "trace_id" | "span_id"));
            let safe_key = if is_reserved { format!("field_{k}") } else { k };
            push_json_kv(&mut out, false, &safe_key, &v)?;
        }

        if let Some(scope) = ctx.event_scope() {
            let mut merged_fields = serde_json::Map::new();
            let mut current_name: Option<&str> = None;
            for span in scope.from_root() {
                current_name = Some(span.name());
                let extensions = span.extensions();
                if let Some(formatted) = extensions.get::<FormattedFields<ServiceJsonFields>>()
                    && let Ok(serde_json::Value::Object(obj)) =
                        serde_json::from_str::<serde_json::Value>(formatted.as_str())
                {
                    for (k, v) in obj {
                        merged_fields.insert(k, v);
                    }
                }
            }
            if let Some(name) = current_name {
                let mut span_obj = serde_json::Map::new();
                span_obj.insert(
                    "name".to_owned(),
                    serde_json::Value::String(name.to_owned()),
                );
                for (k, v) in merged_fields {
                    span_obj.insert(k, v);
                }
                push_json_kv(
                    &mut out,
                    false,
                    "span",
                    &serde_json::Value::Object(span_obj),
                )?;
            }
        }

        out.push_str("}\n");
        writer.write_str(&out)
    }
}

type OtelSlot = Option<Box<dyn Layer<Registry> + Send + Sync>>;
type RootSubscriber = tracing_subscriber::layer::Layered<OtelSlot, Registry>;

/// Reload handle returned by [`init_service_telemetry`] (`R58`).
#[derive(Clone)]
pub struct ServiceTelemetryHandles {
    console_filter: reload::Handle<EnvFilter, RootSubscriber>,
}

impl fmt::Debug for ServiceTelemetryHandles {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("ServiceTelemetryHandles")
            .finish_non_exhaustive()
    }
}

impl ServiceTelemetryHandles {
    /// Dynamically swap the service console layer's diagnostic level (`R58`).
    pub fn reload_level(&self, level: LogLevel) -> Result<(), reload::Error> {
        self.console_filter.reload(level_to_env_filter(level))
    }
}

/// Result of calling [`init_service_telemetry`] (`R58`).
#[derive(Debug)]
pub enum ServiceTelemetryInit {
    /// This process installed the global `tracing` subscriber.
    Installed(ServiceTelemetryHandles),
    /// A host application had already installed a global subscriber; we left it untouched.
    HostOwned,
}

fn build_subscriber_inner<M>(
    profile: ServiceTelemetryProfile,
    make_writer: M,
    otel_layer: OtelSlot,
) -> (impl Subscriber + Send + Sync, ServiceTelemetryHandles)
where
    M: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    #[cfg(not(feature = "otel"))]
    let otel_enabled = otel_layer.is_some();

    #[cfg(feature = "otel")]
    let otel_dispatch: Option<OtelDispatchSlot> = otel_layer
        .is_some()
        .then(|| std::sync::Arc::new(std::sync::OnceLock::new()));

    let console_layer: Box<dyn Layer<RootSubscriber> + Send + Sync> = match profile.format {
        ServiceLogFormat::Console => tracing_subscriber::fmt::layer()
            .with_writer(make_writer)
            .with_ansi(false)
            .fmt_fields(ServiceHumanFields)
            .boxed(),
        ServiceLogFormat::Json => {
            #[cfg(feature = "otel")]
            let event_fmt = ServiceJsonEvent::with_otel_dispatch(otel_dispatch.clone());
            #[cfg(not(feature = "otel"))]
            let event_fmt = ServiceJsonEvent::new(otel_enabled);
            tracing_subscriber::fmt::layer()
                .with_writer(make_writer)
                .with_ansi(false)
                .fmt_fields(ServiceJsonFields)
                .event_format(event_fmt)
                .boxed()
        }
    };

    let root: RootSubscriber = Registry::default().with(otel_layer);
    let (console_filter_layer, console_filter_handle) =
        reload::Layer::new(level_to_env_filter(profile.level));
    let subscriber = root.with(console_layer.with_filter(console_filter_layer));

    #[cfg(feature = "otel")]
    let subscriber = subscriber.with(DispatchCaptureLayer {
        slot: otel_dispatch,
    });

    (
        subscriber,
        ServiceTelemetryHandles {
            console_filter: console_filter_handle,
        },
    )
}

/// Build an isolated service subscriber + [`ServiceTelemetryHandles`] writing to `make_writer`.
#[must_use]
pub fn build_service_subscriber<M>(
    profile: ServiceTelemetryProfile,
    make_writer: M,
) -> (impl Subscriber + Send + Sync, ServiceTelemetryHandles)
where
    M: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    build_subscriber_inner(profile, make_writer, None)
}

/// Build an isolated service subscriber with an optional OpenTelemetry layer attached (`otel`
/// feature required).
///
/// When attaching an OpenTelemetry layer inside a multi-threaded `cargo test` binary, serialize
/// tests that call `tracing::subscriber::set_default` (or run under process-isolated
/// `cargo-nextest`) to avoid a `tracing-core` / `opentelemetry_sdk` re-entrant drop deadlock on
/// `LOCKED_DISPATCHERS`.
#[cfg(feature = "otel")]
#[must_use]
pub fn build_service_subscriber_with_otel<M>(
    profile: ServiceTelemetryProfile,
    make_writer: M,
    otel_layer: Option<crate::otel::OtelLayer>,
) -> (impl Subscriber + Send + Sync, ServiceTelemetryHandles)
where
    M: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    build_subscriber_inner(profile, make_writer, otel_layer)
}

/// Install the global `tracing` subscriber on `stderr` if no host subscriber is active (`R58`).
#[must_use]
pub fn init_service_telemetry(profile: ServiceTelemetryProfile) -> ServiceTelemetryInit {
    init_telemetry_inner(profile, None)
}

/// Install the global `tracing` subscriber on `stderr` with an optional OpenTelemetry layer
/// (`otel` feature required).
#[cfg(feature = "otel")]
#[must_use]
pub fn init_service_telemetry_with_otel(
    profile: ServiceTelemetryProfile,
    otel_layer: Option<crate::otel::OtelLayer>,
) -> ServiceTelemetryInit {
    init_telemetry_inner(profile, otel_layer)
}

fn init_telemetry_inner(
    profile: ServiceTelemetryProfile,
    otel_layer: OtelSlot,
) -> ServiceTelemetryInit {
    if tracing::dispatcher::has_been_set() {
        return ServiceTelemetryInit::HostOwned;
    }

    let (subscriber, handles) = build_subscriber_inner(profile, io::stderr, otel_layer);
    let _ = subscriber.try_init();
    ServiceTelemetryInit::Installed(handles)
}

/// Emit one diagnostic warning when a caller requests OpenTelemetry or configures an
/// `OTEL_EXPORTER_OTLP_*` endpoint against a build without `--features otel` (`R78` Gate 1).
pub fn warn_if_otlp_env_ignored(otel_enabled_flag: bool, otlp_endpoint: Option<&str>) {
    #[cfg(not(feature = "otel"))]
    {
        let endpoint_set = otlp_endpoint.is_some_and(|v| !v.trim().is_empty());
        if otel_enabled_flag || endpoint_set {
            tracing::warn!(
                otel_enabled = otel_enabled_flag,
                endpoint_configured = endpoint_set,
                "otel export ignored: binary built without `--features otel`"
            );
        }
    }
    #[cfg(feature = "otel")]
    {
        let _ = (otel_enabled_flag, otlp_endpoint);
    }
}
