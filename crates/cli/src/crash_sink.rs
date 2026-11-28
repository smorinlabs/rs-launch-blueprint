//! Best-effort `0600` NDJSON crash record sink and `anyhow` binary error boundary (`R67` F302).
//!
//! Only the `UNEXPECTED` (`RSLB000`) class ever reaches [`CrashSink`]. Records carry timestamp,
//! version, PID, stable code, and sanitized cause chain — NEVER argv, environment values,
//! headers, tokens, or configuration contents. Any sink write failure is swallowed and never
//! changes the stderr error envelope or process exit code (`R67` AC7).

use std::fs::{self, OpenOptions};
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::sync::atomic::{AtomicBool, Ordering};
use std::time::{SystemTime, UNIX_EPOCH};

use rs_launch_blueprint::{DomainError, ErrorCode, OutputFormat, VERSION};
use serde::{Deserialize, Serialize};

use crate::app::{CliError, emit_cli_error};
use crate::exit::{Exit, cli_hint_for_domain_error};
use crate::output::render_error;

/// Single sanitized NDJSON crash record written for `RSLB000` unexpected failures (`R67`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct CrashRecord {
    /// UTC ISO-8601 timestamp (`YYYY-MM-DDTHH:MM:SSZ`).
    pub timestamp: String,
    /// Package SemVer version (`rs_launch_blueprint::VERSION`).
    pub version: String,
    /// Process identifier.
    pub pid: u32,
    /// Stable error code (always `"RSLB000"`).
    pub code: String,
    /// Control-escaped cause chain (never argv, env, headers, tokens, or config contents).
    pub causes: Vec<String>,
}

impl CrashRecord {
    /// Construct a sanitized [`CrashRecord`] for an unexpected error.
    #[must_use]
    pub fn unexpected(causes: Vec<String>) -> Self {
        Self {
            timestamp: format_utc_now(),
            version: VERSION.to_owned(),
            pid: std::process::id(),
            code: ErrorCode::Unexpected.as_str().to_owned(),
            causes: causes.into_iter().map(|c| sanitize_cause(&c)).collect(),
        }
    }
}

/// Injected best-effort persistence sink for unexpected CLI failures (`R67`).
pub trait CrashSink: Send + Sync {
    /// Persist `record` on a best-effort basis; implementations must never panic or surface I/O errors.
    fn record(&self, record: &CrashRecord);
}

/// No-op [`CrashSink`] leaving the filesystem untouched (default when state dir is unavailable).
#[derive(Debug, Default, Clone, Copy)]
pub struct NoopCrashSink;

impl CrashSink for NoopCrashSink {
    fn record(&self, _record: &CrashRecord) {}
}

/// Appending `0600` NDJSON [`CrashSink`] writing to `<state_dir>/rslbp_crash.jsonl` (`R57`, `R67`).
#[derive(Debug, Clone)]
pub struct FileCrashSink {
    path: PathBuf,
}

impl FileCrashSink {
    /// Construct a [`FileCrashSink`] targeting `path`.
    #[must_use]
    pub fn new(path: impl Into<PathBuf>) -> Self {
        Self { path: path.into() }
    }

    /// Return the configured crash log file path.
    #[must_use]
    pub fn path(&self) -> &Path {
        &self.path
    }
}

impl CrashSink for FileCrashSink {
    fn record(&self, record: &CrashRecord) {
        let _ = append_record_0600(&self.path, record);
    }
}

fn append_record_0600(path: &Path, record: &CrashRecord) -> io::Result<()> {
    if let Some(parent) = path.parent()
        && !parent.as_os_str().is_empty()
    {
        let mut dir_builder = fs::DirBuilder::new();
        dir_builder.recursive(true);
        #[cfg(unix)]
        std::os::unix::fs::DirBuilderExt::mode(&mut dir_builder, 0o700);
        dir_builder.create(parent)?;
    }

    let mut opts = OpenOptions::new();
    opts.create(true).append(true);
    #[cfg(unix)]
    std::os::unix::fs::OpenOptionsExt::mode(&mut opts, 0o600);

    let mut file = opts.open(path)?;
    let mut line = serde_json::to_string(record)
        .map_err(|err| io::Error::new(io::ErrorKind::InvalidData, err))?;
    line.push('\n');
    file.write_all(line.as_bytes())?;
    file.flush()
}

/// Classify and handle a binary-boundary `anyhow::Result<Exit>` strictly following R67 precedence:
/// **signal -> broken pipe -> domain downcast -> unexpected (with crash sink)** (`R67`).
///
/// Flushes both `stdout` and `stderr` before returning [`Exit`] on every path (`R7.7`).
pub fn resolve_binary_boundary(
    outcome: anyhow::Result<Exit>,
    sigint_flag: &AtomicBool,
    sigterm_flag: &AtomicBool,
    crash_sink: &dyn CrashSink,
    stdout: &mut dyn Write,
    stderr: &mut dyn Write,
) -> Exit {
    // 1. Signal precedence (R67 essential behavior 6): signal wins over every error or broken pipe.
    if sigint_flag.load(Ordering::Acquire) {
        let _ = stdout.flush();
        let _ = stderr.flush();
        return Exit::SigInt;
    }
    if sigterm_flag.load(Ordering::Acquire) {
        let _ = stdout.flush();
        let _ = stderr.flush();
        return Exit::SigTerm;
    }

    let exit = match outcome {
        Ok(code) => code,
        Err(err) => handle_anyhow_error(&err, crash_sink, stderr),
    };

    let _ = stdout.flush();
    let _ = stderr.flush();
    exit
}

fn handle_anyhow_error(
    err: &anyhow::Error,
    crash_sink: &dyn CrashSink,
    stderr: &mut dyn Write,
) -> Exit {
    // 2. Broken pipe precedence on the result stream -> exit 0 silently, no envelope (R67 AC5).
    if let Some(CliError::BrokenPipe) = err.downcast_ref::<CliError>() {
        return Exit::Success;
    }
    for cause in err.chain() {
        if let Some(io_err) = cause.downcast_ref::<io::Error>()
            && io_err.kind() == io::ErrorKind::BrokenPipe
        {
            return Exit::Success;
        }
    }

    // 3. Typed CLI / Domain error downcast (R67 A3).
    if let Some(cli_err) = err.downcast_ref::<CliError>() {
        if let CliError::Unexpected {
            message, causes, ..
        } = cli_err
        {
            let mut all_causes = vec![message.clone()];
            all_causes.extend(causes.iter().cloned());
            crash_sink.record(&CrashRecord::unexpected(all_causes));
        }
        return emit_cli_error(cli_err, stderr);
    }

    if let Some(domain_err) = err.downcast_ref::<DomainError>() {
        let hint = cli_hint_for_domain_error(domain_err);
        let _ = render_error(
            domain_err.error_code(),
            &domain_err.to_string(),
            hint.as_deref(),
            OutputFormat::Table,
            false,
            stderr,
        );
        return Exit::from_domain_error(domain_err);
    }

    // 4. Unexpected fallback (`RSLB000`, exit `1`) + best-effort crash record sink (R67).
    let causes: Vec<String> = err.chain().map(ToString::to_string).collect();
    crash_sink.record(&CrashRecord::unexpected(causes));
    let _ = render_error(
        ErrorCode::Unexpected,
        &err.to_string(),
        None,
        OutputFormat::Table,
        false,
        stderr,
    );
    Exit::Runtime
}

fn sanitize_cause(input: &str) -> String {
    let mut out = String::with_capacity(input.len());
    for ch in input.chars() {
        if ch.is_control() {
            for esc in ch.escape_default() {
                out.push(esc);
            }
        } else {
            out.push(ch);
        }
    }
    out
}

fn format_utc_now() -> String {
    let secs = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map(|d| d.as_secs())
        .unwrap_or(0);
    format_unix_secs_utc(secs)
}

/// Convert unsigned Unix epoch seconds to UTC ISO-8601 `YYYY-MM-DDTHH:MM:SSZ`.
fn format_unix_secs_utc(secs: u64) -> String {
    let days = (secs / 86_400) as i64;
    let rem = secs % 86_400;
    let hour = rem / 3_600;
    let minute = (rem % 3_600) / 60;
    let second = rem % 60;

    // Howard Hinnant's civil-from-days algorithm (proleptic Gregorian calendar).
    let z = days + 719_468;
    let era = z.div_euclid(146_097);
    let doe = z.rem_euclid(146_097) as u64;
    let yoe = (doe - doe / 1_460 + doe / 36_524 - doe / 146_096) / 365;
    let y = (yoe as i64) + era * 400;
    let doy = doe - (365 * yoe + yoe / 4 - yoe / 100);
    let mp = (5 * doy + 2) / 153;
    let d = doy - (153 * mp + 2) / 5 + 1;
    let m = if mp < 10 { mp + 3 } else { mp - 9 };
    let year = if m <= 2 { y + 1 } else { y };

    format!("{year:04}-{m:02}-{d:02}T{hour:02}:{minute:02}:{second:02}Z")
}
