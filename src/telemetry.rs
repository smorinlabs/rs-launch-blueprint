//! Structured diagnostic logging pipeline (`R58`, `OV-09`) and rotating file sink (`R59`).
//!
//! All diagnostics emit exclusively to `stderr` or an opt-in rotating log file, never `stdout`.
//! Sensitive field names in [`SENSITIVE_KEY_PARTS`] are masked to [`REDACTED`] in both console
//! and JSON formatters (for event fields and span attributes alike).
//!
//! Boundary (`OV-09`): redaction is field-key-based; secrets embedded inside values of
//! non-sensitive keys are not regex-rewritten. Callers must wrap secret values in
//! [`rs_launch_blueprint_core::Token`] or `secrecy::SecretString`.

use std::ffi::OsString;
use std::fmt;
use std::fs::{self, File, OpenOptions};
use std::io::{self, IsTerminal, Write as _};
use std::path::{Path, PathBuf};
use std::str::FromStr;
use std::sync::Mutex;

use rs_launch_blueprint_core::{ConfigError, FileLogFormat, LogLevel};
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

/// Default maximum size in bytes before [`RotatingFile`] rotates (`10 MiB`, `R59`).
pub const ROTATE_MAX_BYTES: u64 = 10 * 1024 * 1024;

/// Default number of rotated backup files retained (`.1` through `.5`, `R59`).
pub const ROTATE_BACKUP_COUNT: usize = 5;

/// Return `true` if `name` matches any substring in [`SENSITIVE_KEY_PARTS`] case-insensitively.
#[must_use]
pub fn is_sensitive_key(name: &str) -> bool {
    let lower = name.to_ascii_lowercase();
    SENSITIVE_KEY_PARTS.iter().any(|part| lower.contains(part))
}

/// Requested console log format for CLI invocations (`R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub enum LogFormat {
    /// Human-readable console when `stderr` is a TTY, structured JSON otherwise (default).
    #[default]
    Auto,
    /// Human-readable console lines regardless of TTY state.
    Console,
    /// Newline-delimited structured JSON objects regardless of TTY state.
    Json,
}

impl LogFormat {
    /// Canonical lowercase representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Auto => "auto",
            Self::Console => "console",
            Self::Json => "json",
        }
    }

    /// Resolve [`LogFormat`] against whether `stderr` is attached to an interactive terminal.
    #[must_use]
    pub const fn resolve(self, stderr_is_tty: bool) -> ResolvedLogFormat {
        match self {
            Self::Auto => {
                if stderr_is_tty {
                    ResolvedLogFormat::Console
                } else {
                    ResolvedLogFormat::Json
                }
            }
            Self::Console => ResolvedLogFormat::Console,
            Self::Json => ResolvedLogFormat::Json,
        }
    }
}

impl fmt::Display for LogFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for LogFormat {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "auto" => Ok(Self::Auto),
            "console" => Ok(Self::Console),
            "json" => Ok(Self::Json),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "logging.format".to_owned(),
                detail: format!("expected one of: auto, console, json (got '{s}')"),
            }),
        }
    }
}

pub use rs_launch_blueprint_core::{ResolvedLogFormat, ServiceLogFormat};

/// Subscriber installation profile distinguishing CLI and service entrypoints (`R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum Profile {
    /// CLI profile supporting `auto`/`console`/`json`, optional ANSI, and debug source metadata.
    Cli {
        /// Requested log format (`auto` inspects `stderr.is_terminal()`).
        format: LogFormat,
        /// Initial console log level.
        level: LogLevel,
        /// Enable ANSI styling on console output (never applied to JSON or file sinks).
        ansi: bool,
        /// Include file/line/thread metadata when `--debug` is active.
        debug: bool,
    },
    /// Service/daemon profile defaulting to JSON without TTY auto-detection.
    Service {
        /// Initial service log level.
        level: LogLevel,
        /// Explicit format (`json` or `console`).
        format: ServiceLogFormat,
    },
}

/// Inputs to the seven-rung CLI console log-level precedence ladder (`R58`, CLI R5.1).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default)]
pub struct LevelLadderInput {
    /// Rung 1: `--debug` forces `trace`.
    pub debug: bool,
    /// Rung 2: explicit `--log-level <LEVEL>` flag.
    pub log_level_flag: Option<LogLevel>,
    /// Rung 3: `-q` / `--quiet` forces `error` (not `warn`).
    pub quiet: bool,
    /// Rung 4: `-v` count (`1` => `info`, `2` => `debug`, `>=3` => `trace`).
    pub verbose: u8,
    /// Rung 5: `RSLBP_LOG_LEVEL` environment variable.
    pub env_log_level: Option<LogLevel>,
    /// Rung 6: `[logging].level` from layered configuration.
    pub config_log_level: Option<LogLevel>,
}

/// Resolve the effective CLI console [`LogLevel`] using the seven-rung R58 ladder.
///
/// Precedence (highest to lowest):
/// 1. `--debug` => `Trace`
/// 2. `--log-level`
/// 3. `--quiet` => `Error`
/// 4. `-v` (`Info`), `-vv` (`Debug`), `-vvv`+ (`Trace`)
/// 5. `RSLBP_LOG_LEVEL`
/// 6. `[logging].level`
/// 7. Default `Warn`
#[must_use]
pub const fn resolve_console_level(input: &LevelLadderInput) -> LogLevel {
    if input.debug {
        return LogLevel::Trace;
    }
    if let Some(level) = input.log_level_flag {
        return level;
    }
    if input.quiet {
        return LogLevel::Error;
    }
    if input.verbose >= 3 {
        return LogLevel::Trace;
    }
    if input.verbose == 2 {
        return LogLevel::Debug;
    }
    if input.verbose == 1 {
        return LogLevel::Info;
    }
    if let Some(level) = input.env_log_level {
        return level;
    }
    if let Some(level) = input.config_log_level {
        return level;
    }
    LogLevel::Warn
}

/// Resolve CLI [`LogFormat`] (`--log-format` > `RSLBP_LOG_FORMAT` > `LogFormat::Auto`).
#[must_use]
pub const fn resolve_log_format(flag: Option<LogFormat>, env: Option<LogFormat>) -> LogFormat {
    if let Some(f) = flag {
        return f;
    }
    if let Some(e) = env {
        return e;
    }
    LogFormat::Auto
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

/// Escape ASCII and Unicode control characters (including ESC `0x1b` and BEL `0x07`) so untrusted
/// event fields cannot inject terminal escape sequences (`RUSTSEC-2025-0055`).
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

/// Redacting and control-character-escaping human field formatter for console and text file sinks
/// (`R58`, `RUSTSEC-2025-0055`).
#[derive(Debug, Default, Clone, Copy)]
pub struct HumanFields;

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
    fn record_f64(&mut self, field: &Field, value: f64) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            self.write_field_raw(field.name(), &value.to_string(), false);
        }
    }

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

    fn record_i128(&mut self, field: &Field, value: i128) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            self.write_field_raw(field.name(), &value.to_string(), false);
        }
    }

    fn record_u128(&mut self, field: &Field, value: u128) {
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

    fn record_error(&mut self, field: &Field, value: &(dyn std::error::Error + 'static)) {
        if is_sensitive_key(field.name()) {
            self.write_redacted(field.name());
        } else {
            let safe = escape_control_chars(&value.to_string());
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

impl<'writer> FormatFields<'writer> for HumanFields {
    fn format_fields<R: RecordFields>(&self, writer: Writer<'writer>, fields: R) -> fmt::Result {
        let mut visitor = HumanVisitor::new(writer);
        fields.record(&mut visitor);
        visitor.finish()
    }
}

/// Redacting field visitor producing ordered `(key, serde_json::Value)` pairs (`R58`).
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
    fn record_f64(&mut self, field: &Field, value: f64) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            let v = serde_json::Number::from_f64(value).map_or_else(
                || serde_json::Value::String(value.to_string()),
                serde_json::Value::Number,
            );
            self.push(field.name(), v);
        }
    }

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

    fn record_i128(&mut self, field: &Field, value: i128) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::String(value.to_string()));
        }
    }

    fn record_u128(&mut self, field: &Field, value: u128) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::String(value.to_string()));
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

    fn record_error(&mut self, field: &Field, value: &(dyn std::error::Error + 'static)) {
        if is_sensitive_key(field.name()) {
            self.push_redacted(field.name());
        } else {
            self.push(field.name(), serde_json::Value::String(value.to_string()));
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
pub struct JsonFields;

impl<'writer> FormatFields<'writer> for JsonFields {
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

/// Custom single-line JSON event formatter built directly on `serde_json` (`R58`).
///
/// Keeps `tracing-subscriber/json` disabled to avoid `serde_json`'s `raw_value` feature while
/// guaranteeing UTC ISO-8601 timestamps, deterministic R58 key ordering (`timestamp`, `level`,
/// `target`, event fields, `span`), and sensitive-key redaction across both events and spans.
#[derive(Debug, Default, Clone, Copy)]
pub struct JsonEvent {
    debug: bool,
}

impl JsonEvent {
    /// Construct a [`JsonEvent`] formatter; when `debug` is `true`, emits `file`, `line`, and
    /// `thread` metadata.
    #[must_use]
    pub const fn new(debug: bool) -> Self {
        Self { debug }
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

impl<S, N> FormatEvent<S, N> for JsonEvent
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

        // 1. UTC ISO-8601 timestamp via tracing_subscriber's built-in UTC SystemTime formatter.
        let mut ts = String::with_capacity(32);
        tracing_subscriber::fmt::time::SystemTime.format_time(&mut Writer::new(&mut ts))?;
        push_json_kv(&mut out, true, "timestamp", &serde_json::Value::String(ts))?;

        // 2. Level and target in exact R58 key order.
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

        if self.debug {
            if let Some(file) = meta.file() {
                push_json_kv(
                    &mut out,
                    false,
                    "file",
                    &serde_json::Value::String(file.to_owned()),
                )?;
            }
            if let Some(line) = meta.line() {
                push_json_kv(&mut out, false, "line", &serde_json::Value::from(line))?;
            }
            if let Some(thread_name) = std::thread::current().name() {
                push_json_kv(
                    &mut out,
                    false,
                    "thread",
                    &serde_json::Value::String(thread_name.to_owned()),
                )?;
            }
        }

        // R78 trace slot: when OpenTelemetry is wired in P11+, emit "trace_id" / "span_id" here.

        // 3. Redacted event fields (`message` first if present, then remaining fields in order).
        let mut visitor = JsonObjVisitor::default();
        event.record(&mut visitor);
        if let Some(pos) = visitor.fields.iter().position(|(k, _)| k == "message") {
            let (k, v) = visitor.fields.remove(pos);
            push_json_kv(&mut out, false, &k, &v)?;
        }
        for (k, v) in visitor.fields {
            let safe_key = if matches!(k.as_str(), "timestamp" | "level" | "target" | "span") {
                format!("field_{k}")
            } else {
                k
            };
            push_json_kv(&mut out, false, &safe_key, &v)?;
        }

        // 4. Merged active span attributes (outer -> inner, with innermost span name).
        if let Some(scope) = ctx.event_scope() {
            let mut merged_fields = serde_json::Map::new();
            let mut current_name: Option<&str> = None;
            for span in scope.from_root() {
                current_name = Some(span.name());
                let extensions = span.extensions();
                if let Some(formatted) = extensions.get::<FormattedFields<JsonFields>>()
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

/// Unbuffered size-rotating log file writer retaining `.1`..=`.N` backups (`R59`).
///
/// Creates parent directories with mode `0700` on Unix, opens files at mode `0600`, rotates on
/// record boundaries before writing, and returns `io::Result` errors without panicking.
#[derive(Debug)]
pub struct RotatingFile {
    path: PathBuf,
    file: File,
    written: u64,
    max_bytes: u64,
    backup_count: usize,
}

impl RotatingFile {
    /// Open or create a rotating log file at `path`, creating parent directories (`0700` on Unix).
    pub fn open(path: impl Into<PathBuf>, max_bytes: u64, backup_count: usize) -> io::Result<Self> {
        let path = path.into();
        if path.as_os_str().is_empty() {
            return Err(io::Error::new(
                io::ErrorKind::InvalidInput,
                "log file path must not be empty",
            ));
        }

        if let Some(parent) = path.parent()
            && !parent.as_os_str().is_empty()
        {
            let mut builder = fs::DirBuilder::new();
            builder.recursive(true);
            #[cfg(unix)]
            std::os::unix::fs::DirBuilderExt::mode(&mut builder, 0o700);
            builder.create(parent)?;
        }

        let file = open_log_file_append(&path)?;
        let written = file.metadata()?.len();
        Ok(Self {
            path,
            file,
            written,
            max_bytes,
            backup_count,
        })
    }

    fn backup_path(&self, index: usize) -> PathBuf {
        let mut os = self.path.as_os_str().to_os_string();
        os.push(format!(".{index}"));
        PathBuf::from(os)
    }

    fn rotate(&mut self) -> io::Result<()> {
        self.file.flush()?;
        if self.backup_count == 0 {
            self.file = open_log_file_truncate(&self.path)?;
            self.written = 0;
            return Ok(());
        }

        // Remove oldest backup if present.
        let oldest = self.backup_path(self.backup_count);
        if let Err(err) = fs::remove_file(&oldest)
            && err.kind() != io::ErrorKind::NotFound
        {
            return Err(err);
        }

        // Shift backups upward: .(n-1) -> .n down to .1 -> .2.
        for idx in (1..self.backup_count).rev() {
            let from = self.backup_path(idx);
            let to = self.backup_path(idx + 1);
            if let Err(err) = fs::rename(&from, &to)
                && err.kind() != io::ErrorKind::NotFound
            {
                return Err(err);
            }
        }

        // Move active file to .1.
        let first_backup = self.backup_path(1);
        if let Err(err) = fs::rename(&self.path, &first_backup)
            && err.kind() != io::ErrorKind::NotFound
        {
            return Err(err);
        }

        self.file = open_log_file_truncate(&self.path)?;
        self.written = 0;
        Ok(())
    }
}

fn open_log_file_append(path: &Path) -> io::Result<File> {
    let mut opts = OpenOptions::new();
    opts.create(true).append(true);
    #[cfg(unix)]
    std::os::unix::fs::OpenOptionsExt::mode(&mut opts, 0o600);
    opts.open(path)
}

fn open_log_file_truncate(path: &Path) -> io::Result<File> {
    let mut opts = OpenOptions::new();
    opts.create(true).write(true).truncate(true);
    #[cfg(unix)]
    std::os::unix::fs::OpenOptionsExt::mode(&mut opts, 0o600);
    opts.open(path)
}

impl io::Write for RotatingFile {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        let len = buf.len() as u64;
        if self.max_bytes > 0
            && self.written > 0
            && self.written.saturating_add(len) > self.max_bytes
        {
            self.rotate()?;
        }
        self.file.write_all(buf)?;
        self.written = self.written.saturating_add(len);
        Ok(buf.len())
    }

    fn flush(&mut self) -> io::Result<()> {
        self.file.flush()
    }
}

/// Resolve the opt-in rotating log file path across the eight R59 precedence cases (`P1`–`P8`):
///
/// - `flag`: `None` (absent), `Some(None)` (bare `--log-file` => default), `Some(Some(path))`
/// - `env`: `None` (unset), `Some("")` (present-but-empty `RSLBP_LOG_FILE=` => default), `Some(p)`
/// - `config`: `None` or `Some("")` => disabled; `Some(path)` => enabled
/// - `default_path`: lazy default path provider (typically `|| Some(paths.log_file())`)
#[must_use]
pub fn resolve_log_file<F>(
    flag: Option<Option<PathBuf>>,
    env: Option<OsString>,
    config: Option<&Path>,
    default_path: F,
) -> Option<PathBuf>
where
    F: FnOnce() -> Option<PathBuf>,
{
    if let Some(flag_val) = flag {
        return match flag_val {
            Some(path) if !path.as_os_str().is_empty() => Some(path),
            Some(_) => None,
            None => default_path(),
        };
    }

    if let Some(env_val) = env {
        if env_val.is_empty() {
            return default_path();
        }
        return Some(PathBuf::from(env_val));
    }

    if let Some(cfg_path) = config
        && !cfg_path.as_os_str().is_empty()
    {
        return Some(cfg_path.to_path_buf());
    }

    None
}

type FileSinkLayer = Option<Box<dyn Layer<Registry> + Send + Sync>>;
type FileSinkSlot = tracing_subscriber::filter::Filtered<
    reload::Layer<FileSinkLayer, Registry>,
    reload::Layer<LevelFilter, Registry>,
    Registry,
>;
type BaseSubscriber = tracing_subscriber::layer::Layered<FileSinkSlot, Registry>;

/// Reload handles returned by [`init_telemetry`] and [`build_scoped_subscriber`] (`R58`, `R59`).
#[derive(Clone)]
pub struct TelemetryHandles {
    console_filter: reload::Handle<EnvFilter, BaseSubscriber>,
    file_body: reload::Handle<FileSinkLayer, Registry>,
    file_filter: reload::Handle<LevelFilter, Registry>,
    log_bridge_refused: bool,
}

impl fmt::Debug for TelemetryHandles {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("TelemetryHandles")
            .field("log_bridge_refused", &self.log_bridge_refused)
            .finish_non_exhaustive()
    }
}

impl TelemetryHandles {
    /// Dynamically swap the console layer's diagnostic level (`R58`).
    pub fn reload_level(&self, level: LogLevel) -> Result<(), reload::Error> {
        self.console_filter.reload(level_to_env_filter(level))
    }

    /// Dynamically swap the console layer's full [`EnvFilter`].
    pub fn reload_filter(&self, filter: EnvFilter) -> Result<(), reload::Error> {
        self.console_filter.reload(filter)
    }

    /// Attach a rotating file sink at `path` with independent `level` and `format` using the
    /// default R59 limits ([`ROTATE_MAX_BYTES`] and [`ROTATE_BACKUP_COUNT`]).
    pub fn attach_file_sink(
        &self,
        path: impl Into<PathBuf>,
        level: LogLevel,
        format: FileLogFormat,
    ) -> io::Result<()> {
        self.attach_file_sink_with_limits(
            path,
            level,
            format,
            ROTATE_MAX_BYTES,
            ROTATE_BACKUP_COUNT,
        )
    }

    /// Attach a rotating file sink with explicit byte-limit and backup-count overrides.
    pub fn attach_file_sink_with_limits(
        &self,
        path: impl Into<PathBuf>,
        level: LogLevel,
        format: FileLogFormat,
        max_bytes: u64,
        backup_count: usize,
    ) -> io::Result<()> {
        let writer = RotatingFile::open(path, max_bytes, backup_count)?;
        let layer: Box<dyn Layer<Registry> + Send + Sync> = match format {
            FileLogFormat::Text => tracing_subscriber::fmt::layer()
                .with_writer(Mutex::new(writer))
                .with_ansi(false)
                .fmt_fields(HumanFields)
                .log_internal_errors(true)
                .boxed(),
            FileLogFormat::Json => tracing_subscriber::fmt::layer()
                .with_writer(Mutex::new(writer))
                .with_ansi(false)
                .fmt_fields(JsonFields)
                .event_format(JsonEvent::new(false))
                .log_internal_errors(true)
                .boxed(),
        };

        // R59: install body BEFORE enabling filter so no event hits an empty slot.
        self.file_body
            .reload(Some(layer))
            .map_err(|err| io::Error::other(err.to_string()))?;
        self.file_filter
            .modify(|f| *f = level_to_filter(level))
            .map_err(|err| io::Error::other(err.to_string()))?;
        Ok(())
    }

    /// Disable and drop any attached file sink.
    pub fn disable_file_sink(&self) -> Result<(), reload::Error> {
        self.file_filter.modify(|f| *f = LevelFilter::OFF)?;
        self.file_body.reload(None)
    }

    /// Return `true` if `tracing` installed successfully while the global `log` bridge was already
    /// owned by the embedding host (`R58`).
    #[must_use]
    pub const fn log_bridge_refused(&self) -> bool {
        self.log_bridge_refused
    }
}

/// Result of calling [`init_telemetry`] (`R58`).
#[derive(Debug)]
pub enum TelemetryInit {
    /// This process installed the global `tracing` subscriber and owns reload handles.
    Installed(TelemetryHandles),
    /// A host application had already installed a global subscriber; we left it untouched.
    HostOwned,
}

fn build_subscriber_inner<M>(
    profile: Profile,
    stderr_is_tty: bool,
    make_writer: M,
) -> (impl Subscriber + Send + Sync, TelemetryHandles)
where
    M: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    let (resolved_format, level, ansi, debug) = match profile {
        Profile::Cli {
            format,
            level,
            ansi,
            debug,
        } => (format.resolve(stderr_is_tty), level, ansi, debug),
        Profile::Service { level, format } => (format.resolved(), level, false, false),
    };

    let console_layer: Box<dyn Layer<BaseSubscriber> + Send + Sync> = match resolved_format {
        ResolvedLogFormat::Console => tracing_subscriber::fmt::layer()
            .with_writer(make_writer)
            .with_ansi(ansi)
            .with_file(debug)
            .with_line_number(debug)
            .with_thread_names(debug)
            .fmt_fields(HumanFields)
            .boxed(),
        ResolvedLogFormat::Json => tracing_subscriber::fmt::layer()
            .with_writer(make_writer)
            .with_ansi(false)
            .fmt_fields(JsonFields)
            .event_format(JsonEvent::new(debug))
            .boxed(),
    };

    // R59 S1: both console and file layers use independent per-layer reload filters stacked via
    // `.with(...)` on `Registry` so `max_level_hint()` computes `max(console, file)` and a file
    // sink at DEBUG receives debug events while console stays at WARN (and vice versa when the
    // file sink is OFF).
    let (file_body_layer, file_body_handle) = reload::Layer::<FileSinkLayer, Registry>::new(None);
    let (file_filter_layer, file_filter_handle) = reload::Layer::new(LevelFilter::OFF);
    let base: BaseSubscriber =
        Registry::default().with(file_body_layer.with_filter(file_filter_layer));

    let (console_filter_layer, console_filter_handle) =
        reload::Layer::new(level_to_env_filter(level));
    let subscriber = base.with(console_layer.with_filter(console_filter_layer));

    let handles = TelemetryHandles {
        console_filter: console_filter_handle,
        file_body: file_body_handle,
        file_filter: file_filter_handle,
        log_bridge_refused: false,
    };

    (subscriber, handles)
}

/// Build an isolated subscriber + [`TelemetryHandles`] writing to `make_writer` for hermetic tests
/// and scoped dispatch (`tracing::subscriber::set_default`).
#[must_use]
pub fn build_scoped_subscriber<M>(
    profile: Profile,
    make_writer: M,
) -> (impl Subscriber + Send + Sync, TelemetryHandles)
where
    M: for<'a> MakeWriter<'a> + Send + Sync + 'static,
{
    build_subscriber_inner(profile, false, make_writer)
}

/// Install the global `tracing` subscriber on `stderr` if no host subscriber is active (`R58`).
///
/// Checks [`tracing::dispatcher::has_been_set`] first and uses `try_init()` (never `init()`),
/// so embedding hosts that own the global subscriber never panic.
#[must_use]
pub fn init_telemetry(profile: Profile) -> TelemetryInit {
    if tracing::dispatcher::has_been_set() {
        return TelemetryInit::HostOwned;
    }

    let stderr_is_tty = io::stderr().is_terminal();
    let (subscriber, mut handles) = build_subscriber_inner(profile, stderr_is_tty, io::stderr);

    match subscriber.try_init() {
        Ok(()) => TelemetryInit::Installed(handles),
        Err(_) => {
            handles.log_bridge_refused = true;
            TelemetryInit::Installed(handles)
        }
    }
}
