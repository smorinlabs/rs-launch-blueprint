use std::fmt::{self, Write as _};
use std::sync::{Arc, Mutex};

use tracing::field::{Field, Visit};
use tracing::{Event, Subscriber, debug, info, info_span};
use tracing_subscriber::field::MakeVisitor;
use tracing_subscriber::fmt::format::{DefaultFields, FormatEvent, FormatFields, Writer};
use tracing_subscriber::fmt::{FmtContext, FormattedFields};
use tracing_subscriber::field::RecordFields;
use tracing_subscriber::prelude::*;
use tracing_subscriber::registry::LookupSpan;
use tracing_subscriber::{EnvFilter, Registry, reload};

const REDACTED: &str = "[REDACTED]";
const SENSITIVE: [&str; 8] = [
    "token",
    "password",
    "secret",
    "authorization",
    "api_key",
    "apikey",
    "credential",
    "cookie",
];

fn is_sensitive(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    SENSITIVE.iter().any(|k| lower.contains(k))
}

// ---------- JSON object visitor (template-owned) ----------
struct JsonObjVisitor {
    out: String,
    first: bool,
}

impl JsonObjVisitor {
    fn new() -> Self {
        Self { out: String::new(), first: true }
    }
    fn push(&mut self, name: &str, value: String) {
        if !self.first {
            self.out.push(',');
        }
        self.first = false;
        let k = serde_json::to_string(name).unwrap_or_else(|_| "\"?\"".into());
        let v = serde_json::to_string(&value).unwrap_or_else(|_| "\"?\"".into());
        let _ = write!(self.out, "{k}:{v}");
    }
}

impl Visit for JsonObjVisitor {
    fn record_str(&mut self, field: &Field, value: &str) {
        let name = field.name();
        if is_sensitive(name) {
            self.push(name, REDACTED.to_string());
        } else {
            self.push(name, value.to_string());
        }
    }
    fn record_debug(&mut self, field: &Field, value: &dyn fmt::Debug) {
        let name = field.name();
        if is_sensitive(name) {
            self.push(name, REDACTED.to_string());
        } else {
            self.push(name, format!("{value:?}"));
        }
    }
}

/// Template-owned JSON `FormatFields`. Emits a complete JSON object, which is
/// what `tracing-subscriber`'s stock `Format<Json>` requires of span fields.
struct OwnedJsonFields;

impl<'w> FormatFields<'w> for OwnedJsonFields {
    fn format_fields<R: RecordFields>(&self, mut writer: Writer<'w>, fields: R) -> fmt::Result {
        let mut v = JsonObjVisitor::new();
        fields.record(&mut v);
        write!(writer, "{{{}}}", v.out)
    }
}

/// Template-owned JSON `FormatEvent`.
struct OwnedJsonEvent;

impl<S, N> FormatEvent<S, N> for OwnedJsonEvent
where
    S: Subscriber + for<'a> LookupSpan<'a>,
    N: for<'a> FormatFields<'a> + 'static,
{
    fn format_event(
        &self,
        ctx: &FmtContext<'_, S, N>,
        mut writer: Writer<'_>,
        event: &Event<'_>,
    ) -> fmt::Result {
        let meta = event.metadata();
        let mut v = JsonObjVisitor::new();
        event.record(&mut v);

        let span_fields: Option<String> = ctx.lookup_current().and_then(|span| {
            let ext = span.extensions();
            ext.get::<FormattedFields<N>>().map(|f| f.fields.clone())
        });

        let target = serde_json::to_string(meta.target()).unwrap_or_else(|_| "\"?\"".into());
        write!(writer, "{{\"level\":\"{}\",\"target\":{}", meta.level(), target)?;
        // R78 hook point: trace_id / span_id would be serialised here.
        if !v.out.is_empty() {
            write!(writer, ",{}", v.out)?;
        }
        if let Some(sf) = span_fields {
            write!(writer, ",\"span\":{sf}")?;
        }
        writeln!(writer, "}}")
    }
}

// ---------- human profile: thin wrapper over DefaultFields ----------
struct HumanFields(DefaultFields);

struct HumanVisitor<'a> {
    inner: tracing_subscriber::fmt::format::DefaultVisitor<'a>,
}

impl Visit for HumanVisitor<'_> {
    fn record_str(&mut self, field: &Field, value: &str) {
        if is_sensitive(field.name()) {
            self.inner.record_str(field, REDACTED);
        } else {
            self.inner.record_str(field, value);
        }
    }
    fn record_debug(&mut self, field: &Field, value: &dyn fmt::Debug) {
        if is_sensitive(field.name()) {
            self.inner.record_str(field, REDACTED);
        } else {
            self.inner.record_debug(field, value);
        }
    }
}

impl<'w> FormatFields<'w> for HumanFields {
    fn format_fields<R: RecordFields>(&self, writer: Writer<'w>, fields: R) -> fmt::Result {
        let mut v = HumanVisitor { inner: self.0.make_visitor(writer) };
        fields.record(&mut v);
        Ok(())
    }
}

// ---------- shared capture writer ----------
#[derive(Clone, Default)]
struct Buf(Arc<Mutex<Vec<u8>>>);

impl std::io::Write for Buf {
    fn write(&mut self, b: &[u8]) -> std::io::Result<usize> {
        self.0.lock().unwrap().extend_from_slice(b);
        Ok(b.len())
    }
    fn flush(&mut self) -> std::io::Result<()> {
        Ok(())
    }
}

impl<'a> tracing_subscriber::fmt::MakeWriter<'a> for Buf {
    type Writer = Buf;
    fn make_writer(&'a self) -> Self::Writer {
        self.clone()
    }
}

fn dump(label: &str, buf: &Buf) {
    let bytes = buf.0.lock().unwrap().clone();
    print!("{label}{}", String::from_utf8_lossy(&bytes));
}

fn emit() {
    let span = info_span!("request", request_id = "abc-123", api_key = "sk_span_SECRET");
    let _g = span.enter();
    info!(
        user = "alice",
        token = "sk_live_EVENTSECRET",
        password = "hunter2",
        "processing request"
    );
}

fn main() {
    let which = std::env::args().nth(1).unwrap_or_default();
    match which.as_str() {
        // S1: the stock `.json()` event formatter with a redacting FormatFields.
        "json-stock-leak" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .json()
                .with_timer(())
                .fmt_fields(OwnedJsonFields)
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            emit();
            drop(_g);
            dump("S1:", &buf);
        }
        // S2: template-owned FormatEvent + FormatFields.
        "json-owned" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .event_format(OwnedJsonEvent)
                .fmt_fields(OwnedJsonFields)
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            emit();
            drop(_g);
            println!("S2-STDOUT:RESULT-ON-STDOUT");
            dump("S2:", &buf);
        }
        // S3: human profile with the DefaultFields wrapper.
        "human-redact" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .fmt_fields(HumanFields(DefaultFields::new()))
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            emit();
            drop(_g);
            dump("S3:", &buf);
        }
        // S4: the global dispatcher can be installed once.
        "second-init" => {
            let first = tracing_subscriber::fmt().with_writer(std::io::stderr).try_init();
            let second = tracing_subscriber::fmt().with_writer(std::io::stderr).try_init();
            println!("S4:FIRST_IS_OK={}", first.is_ok());
            println!("S4:SECOND_IS_ERR={}", second.is_err());
        }
        // S5: reload swaps the filter after installation.
        "reload" => {
            let buf = Buf::default();
            let (filter, handle) = reload::Layer::new(EnvFilter::new("warn"));
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(
                Registry::default().with(filter).with(layer),
            );
            info!("BEFORE-SWAP-INFO");
            handle.modify(|f| *f = EnvFilter::new("debug")).unwrap();
            info!("AFTER-SWAP-INFO");
            debug!("AFTER-SWAP-DEBUG");
            drop(_g);
            dump("S5:", &buf);
        }
        // S6: the log bridge is installed by try_init, with no explicit call.
        "logbridge" => {
            tracing_subscriber::fmt()
                .with_timer(())
                .with_ansi(false)
                .with_writer(std::io::stderr)
                .try_init()
                .expect("first try_init");
            log::info!("S6:LOG-CRATE-RECORD");
            info!("S6:TRACING-RECORD");
        }
        // S7: a secrecy::SecretString never renders its value.
        "secrecy" => {
            use secrecy::SecretString;
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            let s = SecretString::from("sk_live_TOPSECRET".to_string());
            info!(secret_value = ?s, "secrecy check");
            drop(_g);
            dump("S7:", &buf);
        }
        // S8: ESC / BEL bytes in a field value are escaped, not emitted raw.
        "ansi-escape" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .fmt_fields(HumanFields(DefaultFields::new()))
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            info!(untrusted = "\u{1b}[31mRED\u{1b}[0m\u{7}", "ansi check");
            drop(_g);
            let bytes = buf.0.lock().unwrap().clone();
            println!("S8:RAW_ESC_PRESENT={}", bytes.contains(&0x1bu8));
            println!("S8:RAW_BEL_PRESENT={}", bytes.contains(&0x07u8));
            print!("S8:{}", String::from_utf8_lossy(&bytes));
        }
        // S9: a `log` record carries no field keys, so key-based redaction has
        // nothing to bind to. Settles the "log as the library facade" leg.
        "log-facade-fields" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .fmt_fields(HumanFields(DefaultFields::new()))
                .with_writer(buf.clone());
            tracing::subscriber::set_global_default(Registry::default().with(layer))
                .expect("set global");
            tracing_log::LogTracer::init().expect("bridge");
            log::info!(target: "dep", "connecting token=sk_live_LOGFACADE password=hunter2");
            tracing::info!(token = "sk_live_TRACINGFIELD", "tracing side");
            dump("S9:", &buf);
        }
        // S10: the residual gap in key-based masking - a secret carried inside a
        // NON-sensitive field's value is not masked. Grounds OVERRIDE (OV-09).
        "redaction-gap" => {
            let buf = Buf::default();
            let layer = tracing_subscriber::fmt::layer()
                .with_timer(())
                .with_ansi(false)
                .fmt_fields(HumanFields(DefaultFields::new()))
                .with_writer(buf.clone());
            let _g = tracing::subscriber::set_default(Registry::default().with(layer));
            info!(
                url = "https://api.example.com/v1/x?token=sk_live_INURL",
                token = "sk_live_INKEY",
                "redaction gap"
            );
            drop(_g);
            let bytes = buf.0.lock().unwrap().clone();
            let text = String::from_utf8_lossy(&bytes).to_string();
            println!("S10:KEYED_SECRET_MASKED={}", !text.contains("sk_live_INKEY"));
            println!("S10:IN_VALUE_SECRET_MASKED={}", !text.contains("sk_live_INURL"));
            print!("S10:{text}");
        }
        other => {
            eprintln!("unknown scenario: {other}");
            std::process::exit(2);
        }
    }
}
