//! Optional OpenTelemetry tracing bridge, self-redacting OTLP exporter, W3C Trace Context
//! propagation, and three-gate degrade contract (`R78` rev 3, `R58` rev 4, `OV-09`).
//!
//! Compiled only when the `otel` feature (`otel = ["web", ...]`) is enabled.

use std::env;
use std::fmt;
use std::time::Duration;

use opentelemetry::trace::{TraceContextExt as _, TracerProvider as _};
use opentelemetry::{KeyValue, Value, global};
use opentelemetry_http::HeaderInjector;
use opentelemetry_otlp::{SpanExporter as OtlpSpanExporter, WithExportConfig as _};
use opentelemetry_sdk::Resource;
use opentelemetry_sdk::error::OTelSdkResult;
use opentelemetry_sdk::propagation::TraceContextPropagator;
use opentelemetry_sdk::trace::{SdkTracerProvider, SpanData, SpanExporter};
use rs_launch_blueprint_core::TOOL_NAME;
use tracing::level_filters::LevelFilter;
use tracing_opentelemetry::OpenTelemetrySpanExt as _;
use tracing_subscriber::Registry;
use tracing_subscriber::filter::Targets;
use tracing_subscriber::layer::Layer;

use crate::telemetry::{REDACTED, is_sensitive_key};

/// Type-erased, per-layer filtered OpenTelemetry bridge layer attached to `Registry` (`R78`).
pub type OtelLayer = Box<dyn Layer<Registry> + Send + Sync>;

/// Wrapper around any [`SpanExporter`] that redacts sensitive span and event attribute keys
/// before span data leaves the process (`R78` rev 3, `R58` rev 4, `OV-09`).
///
/// Uses the exact F252 key vocabulary ([`crate::SENSITIVE_KEY_PARTS`]) and `[REDACTED]` mask.
/// Inherits `OV-09`: values under non-sensitive attribute keys are not regex-rewritten.
#[derive(Debug, Clone)]
pub struct RedactingSpanExporter<E> {
    inner: E,
}

impl<E> RedactingSpanExporter<E> {
    /// Wrap `inner` so every exported [`SpanData`] batch has sensitive attributes masked.
    #[must_use]
    pub const fn new(inner: E) -> Self {
        Self { inner }
    }
}

fn redact_attributes(attrs: &mut [KeyValue]) {
    for kv in attrs {
        if is_sensitive_key(kv.key.as_str()) {
            kv.value = Value::String(REDACTED.into());
        }
    }
}

fn redact_batch(mut batch: Vec<SpanData>) -> Vec<SpanData> {
    for span in &mut batch {
        redact_attributes(&mut span.attributes);
        for event in &mut span.events.events {
            redact_attributes(&mut event.attributes);
        }
    }
    batch
}

impl<E> SpanExporter for RedactingSpanExporter<E>
where
    E: SpanExporter,
{
    async fn export(&self, batch: Vec<SpanData>) -> OTelSdkResult {
        let sanitized = redact_batch(batch);
        self.inner.export(sanitized).await
    }

    fn shutdown_with_timeout(&self, timeout: Duration) -> OTelSdkResult {
        self.inner.shutdown_with_timeout(timeout)
    }

    fn shutdown(&self) -> OTelSdkResult {
        self.inner.shutdown()
    }

    fn force_flush(&self) -> OTelSdkResult {
        self.inner.force_flush()
    }

    fn set_resource(&mut self, resource: &Resource) {
        self.inner.set_resource(resource);
    }
}

/// Configuration inputs for Gate 2 & Gate 3 OpenTelemetry initialization (`R78`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct OtelConfig {
    /// Explicit runtime enable switch from `RSLBP_WEB_OTEL_ENABLED` (default `false`).
    pub enabled: bool,
    /// Standard kill switch from `OTEL_SDK_DISABLED` (the OTel Rust SDK does not check it itself).
    pub sdk_disabled: bool,
    /// Resource `service.name` value (defaults to `<TOOL_NAME>-web`, i.e. `"rslbp-web"`).
    pub service_name: String,
    /// Bounded shutdown flush budget (capped to the service's drain budget).
    pub shutdown_timeout: Duration,
    /// Optional explicit OTLP/HTTP endpoint override (primarily for hermetic degrade tests).
    pub endpoint_override: Option<String>,
}

impl OtelConfig {
    /// Build [`OtelConfig`] from `WebSettings.otel_enabled`, `shutdown_timeout`, and standard
    /// `OTEL_SDK_DISABLED` environment variable (`R78` Gate 2).
    #[must_use]
    pub fn from_process_env(otel_enabled: bool, shutdown_timeout: Duration) -> Self {
        let sdk_disabled = env::var("OTEL_SDK_DISABLED").is_ok_and(|raw| {
            let trimmed = raw.trim();
            trimmed.eq_ignore_ascii_case("true") || trimmed == "1"
        });
        Self {
            enabled: otel_enabled,
            sdk_disabled,
            service_name: format!("{TOOL_NAME}-web"),
            shutdown_timeout,
            endpoint_override: None,
        }
    }
}

/// Guard owning the [`SdkTracerProvider`] for bounded graceful flush on shutdown (`R78` point 7).
pub struct OtelGuard {
    provider: SdkTracerProvider,
    shutdown_timeout: Duration,
}

impl fmt::Debug for OtelGuard {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("OtelGuard")
            .field("shutdown_timeout", &self.shutdown_timeout)
            .finish_non_exhaustive()
    }
}

impl OtelGuard {
    /// Flush and shut down the tracer provider within its configured timeout budget.
    ///
    /// Call on a blocking/main OS thread (never directly on an async Tokio worker thread, per
    /// `R78` S11/S12). Note that `Ok(())` reports bounded shutdown completion; export loss on an
    /// unreachable collector is surfaced through `opentelemetry_sdk` internal logs.
    pub fn shutdown_blocking(self) -> Result<(), String> {
        self.provider
            .shutdown_with_timeout(self.shutdown_timeout)
            .map_err(|err| err.to_string())
    }
}

/// Outcome of initializing the optional OpenTelemetry pipeline (`R78` Gates 2 & 3).
pub enum OtelInit {
    /// OpenTelemetry tracing is active; attach `layer` to `init_telemetry_with_otel` and flush
    /// `guard` during graceful shutdown.
    Active {
        /// Per-layer filtered `tracing-opentelemetry` bridge layer.
        layer: OtelLayer,
        /// Shutdown guard owning the `SdkTracerProvider`.
        guard: OtelGuard,
    },
    /// OpenTelemetry is compiled in but explicitly disabled via runtime flag or
    /// `OTEL_SDK_DISABLED=true` (no export, no warning).
    Disabled,
    /// OTLP exporter construction failed (e.g. malformed `OTEL_EXPORTER_OTLP_ENDPOINT`); emit one
    /// `otel_unavailable` warning after subscriber initialization and continue serving.
    Unavailable {
        /// Human-readable reason from the exporter builder.
        reason: String,
    },
}

impl fmt::Debug for OtelInit {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Active { guard, .. } => f
                .debug_struct("OtelInit::Active")
                .field("guard", guard)
                .finish_non_exhaustive(),
            Self::Disabled => f.write_str("OtelInit::Disabled"),
            Self::Unavailable { reason } => f
                .debug_struct("OtelInit::Unavailable")
                .field("reason", reason)
                .finish(),
        }
    }
}

/// Build the per-layer [`Targets`] filter that keeps exporter HTTP and SDK internals from
/// recursively generating exported spans (`R78` point 2).
#[must_use]
pub fn otel_feedback_filter() -> Targets {
    Targets::new()
        .with_default(LevelFilter::TRACE)
        .with_target("hyper", LevelFilter::OFF)
        .with_target("hyper_util", LevelFilter::OFF)
        .with_target("h2", LevelFilter::OFF)
        .with_target("reqwest", LevelFilter::OFF)
        .with_target("opentelemetry", LevelFilter::OFF)
        .with_target("opentelemetry_sdk", LevelFilter::OFF)
        .with_target("opentelemetry_otlp", LevelFilter::OFF)
        .with_target("opentelemetry_http", LevelFilter::OFF)
}

fn build_layer_from_provider(
    provider: SdkTracerProvider,
    service_name: &str,
    shutdown_timeout: Duration,
) -> (OtelLayer, OtelGuard) {
    global::set_text_map_propagator(TraceContextPropagator::new());
    let tracer = provider.tracer(service_name.to_owned());
    let layer = tracing_opentelemetry::layer()
        .with_tracer(tracer)
        .with_error_fields_to_exceptions(false)
        .with_error_records_to_exceptions(false)
        .with_filter(otel_feedback_filter())
        .boxed();
    let guard = OtelGuard {
        provider,
        shutdown_timeout,
    };
    (layer, guard)
}

/// Build an OpenTelemetry bridge layer and guard backed by a custom [`SpanExporter`] wrapped in
/// [`RedactingSpanExporter`] using a synchronous simple processor for hermetic tests (`R78`).
#[must_use]
pub fn build_otel_layer_with_exporter<E>(
    service_name: &str,
    exporter: E,
    shutdown_timeout: Duration,
) -> (OtelLayer, OtelGuard)
where
    E: SpanExporter + 'static,
{
    let resource = Resource::builder()
        .with_service_name(service_name.to_owned())
        .build();
    let provider = SdkTracerProvider::builder()
        .with_resource(resource)
        .with_simple_exporter(RedactingSpanExporter::new(exporter))
        .build();
    build_layer_from_provider(provider, service_name, shutdown_timeout)
}

/// Initialize the production OTLP/HTTP tracing pipeline according to `config` (`R78` Gates 2 & 3).
///
/// Never panics: disabled flags return [`OtelInit::Disabled`] and malformed OTLP configuration
/// returns [`OtelInit::Unavailable`].
#[must_use]
pub fn init_otel_from_config(config: &OtelConfig) -> OtelInit {
    if !config.enabled || config.sdk_disabled {
        return OtelInit::Disabled;
    }

    let mut builder = OtlpSpanExporter::builder().with_http();
    if let Some(endpoint) = &config.endpoint_override {
        builder = builder.with_endpoint(endpoint.clone());
    }

    let otlp_exporter = match builder.build() {
        Ok(exp) => exp,
        Err(err) => {
            return OtelInit::Unavailable {
                reason: err.to_string(),
            };
        }
    };

    let resource = Resource::builder()
        .with_service_name(config.service_name.clone())
        .build();
    let provider = SdkTracerProvider::builder()
        .with_resource(resource)
        .with_batch_exporter(RedactingSpanExporter::new(otlp_exporter))
        .build();

    let (layer, guard) =
        build_layer_from_provider(provider, &config.service_name, config.shutdown_timeout);
    OtelInit::Active { layer, guard }
}

/// Inject the current active tracing span's OpenTelemetry W3C Trace Context (`traceparent` /
/// `tracestate`) into outbound HTTP `headers` (`R78` point 5).
pub fn inject_trace_context(headers: &mut ureq::http::HeaderMap) {
    let cx = tracing::Span::current().context();
    if !cx.span().span_context().is_valid() {
        return;
    }
    global::get_text_map_propagator(|prop| {
        prop.inject_context(&cx, &mut HeaderInjector(headers));
    });
}
