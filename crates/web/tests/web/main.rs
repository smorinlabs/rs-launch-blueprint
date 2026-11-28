//! Web integration-test tier (`R32` F129, `R69`–`R77`, `R80`).
//!
//! Lives in `crates/web/tests/web/main.rs` with no file-level `#![cfg(feature = "web")]`
//! because `rs-launch-blueprint-web` is an optional workspace member (`R69` revision 11).

mod idempotency;
mod middleware_settings_probes;
mod problems;
mod projects_and_pagination;
mod rate_limit_and_cors;
mod settings_and_edges;

use std::collections::BTreeMap;
use std::sync::{Arc, Mutex, Once};

use axum::body::{Body, to_bytes};
use axum::http::Response;
use serde_json::Value;
use tracing::field::{Field, Visit};
use tracing::metadata::LevelFilter;
use tracing::{Event, Id, Metadata, Subscriber};

/// Decode a response body as JSON, asserting valid UTF-8 and valid JSON syntax.
pub(crate) async fn response_json(res: Response<Body>) -> Value {
    let bytes = to_bytes(res.into_body(), usize::MAX)
        .await
        .expect("read response body");
    serde_json::from_slice(&bytes).unwrap_or_else(|err| {
        panic!(
            "expected valid JSON body, got error `{err}` on bytes: {:?}",
            String::from_utf8_lossy(&bytes)
        )
    })
}

/// Captured tracing event record for testing access logs and panic events without adding
/// `tracing-subscriber` to `crates/web` (`R58`, `R75`).
#[derive(Debug, Clone)]
pub(crate) struct CapturedEvent {
    pub(crate) target: String,
    pub(crate) level: tracing::Level,
    pub(crate) fields: BTreeMap<String, String>,
}

#[derive(Default)]
struct MapVisitor(BTreeMap<String, String>);

impl Visit for MapVisitor {
    fn record_debug(&mut self, field: &Field, value: &dyn std::fmt::Debug) {
        self.0.insert(field.name().to_owned(), format!("{value:?}"));
    }

    fn record_str(&mut self, field: &Field, value: &str) {
        self.0.insert(field.name().to_owned(), value.to_owned());
    }

    fn record_u64(&mut self, field: &Field, value: u64) {
        self.0.insert(field.name().to_owned(), value.to_string());
    }

    fn record_i64(&mut self, field: &Field, value: i64) {
        self.0.insert(field.name().to_owned(), value.to_string());
    }

    fn record_f64(&mut self, field: &Field, value: f64) {
        self.0.insert(field.name().to_owned(), value.to_string());
    }

    fn record_bool(&mut self, field: &Field, value: bool) {
        self.0.insert(field.name().to_owned(), value.to_string());
    }
}

tokio::task_local! {
    static ACTIVE_CAPTURE: CapturingSubscriber;
}

static GLOBAL_SUBSCRIBER_INIT: Once = Once::new();

struct TaskLocalRouterSubscriber;

impl Subscriber for TaskLocalRouterSubscriber {
    fn enabled(&self, _metadata: &Metadata<'_>) -> bool {
        true
    }

    fn max_level_hint(&self) -> Option<LevelFilter> {
        Some(LevelFilter::TRACE)
    }

    fn new_span(&self, _span: &tracing::span::Attributes<'_>) -> Id {
        Id::from_u64(1)
    }

    fn record(&self, _span: &Id, _values: &tracing::span::Record<'_>) {}

    fn record_follows_from(&self, _span: &Id, _follows: &Id) {}

    fn event(&self, event: &Event<'_>) {
        let _ = ACTIVE_CAPTURE.try_with(|cap| cap.record_event(event));
    }

    fn enter(&self, _span: &Id) {}

    fn exit(&self, _span: &Id) {}
}

/// Minimal thread-safe capturing recorder for scoped async test assertions without adding
/// `tracing-subscriber` to `crates/web` (`R58`, `R75`).
#[derive(Clone, Default)]
pub(crate) struct CapturingSubscriber {
    events: Arc<Mutex<Vec<CapturedEvent>>>,
}

impl CapturingSubscriber {
    pub(crate) fn new() -> Self {
        GLOBAL_SUBSCRIBER_INIT.call_once(|| {
            let _ = tracing::subscriber::set_global_default(TaskLocalRouterSubscriber);
        });
        Self::default()
    }

    pub(crate) fn events(&self) -> Vec<CapturedEvent> {
        self.events.lock().expect("events lock").clone()
    }

    fn record_event(&self, event: &Event<'_>) {
        let mut visitor = MapVisitor::default();
        event.record(&mut visitor);
        let meta = event.metadata();
        self.events
            .lock()
            .expect("events lock")
            .push(CapturedEvent {
                target: meta.target().to_owned(),
                level: *meta.level(),
                fields: visitor.0,
            });
    }

    /// Run `fut` with all tracing events emitted on this task routed exclusively into `self`.
    pub(crate) async fn capture<F: std::future::Future>(&self, fut: F) -> F::Output {
        GLOBAL_SUBSCRIBER_INIT.call_once(|| {
            let _ = tracing::subscriber::set_global_default(TaskLocalRouterSubscriber);
        });
        tracing::callsite::rebuild_interest_cache();
        ACTIVE_CAPTURE.scope(self.clone(), fut).await
    }
}
