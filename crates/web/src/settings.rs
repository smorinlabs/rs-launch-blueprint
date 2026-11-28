//! Environment-driven web service settings parsed once at startup (`R77`, `OV-04`).
//!
//! This module is the **only** file in `crates/web/src/` allowed to read process environment
//! variables (`std::env::vars_os`). All configuration validation runs via [`WebSettings::from_vars`]
//! so tests exercise every validation branch hermetically without mutating process state.

use std::collections::HashMap;
use std::ffi::OsString;
use std::net::{IpAddr, Ipv4Addr, SocketAddr};
use std::num::{NonZeroU32, NonZeroUsize};
use std::str::FromStr;
use std::time::Duration;

use axum::http::HeaderValue;
use rs_launch_blueprint::{ErrorCode, LogLevel, TOOL_NAME};
use thiserror::Error;

use crate::idempotency_store::{
    DEFAULT_IDEMPOTENCY_IN_FLIGHT, DEFAULT_IDEMPOTENCY_MAX_ENTRIES, DEFAULT_IDEMPOTENCY_TTL,
};
use crate::rate_limit::{
    DEFAULT_RATE_LIMIT_BURST, DEFAULT_RATE_LIMIT_MAX_ENTRIES, RateLimitPolicy,
};
use crate::telemetry::ServiceLogFormat;

const PREFIX_LEN: usize = TOOL_NAME.len() + "_WEB_".len();
const PREFIX_BYTES: [u8; PREFIX_LEN] = {
    let mut buf = [0u8; PREFIX_LEN];
    let tool = TOOL_NAME.as_bytes();
    let suffix = b"_WEB_";
    let mut i = 0;
    while i < tool.len() {
        buf[i] = tool[i].to_ascii_uppercase();
        i += 1;
    }
    let mut j = 0;
    while j < suffix.len() {
        buf[i + j] = suffix[j];
        j += 1;
    }
    buf
};

/// Compile-time derived environment variable prefix (`RSLBP_WEB_`, derived from [`TOOL_NAME`], `R77`).
pub const WEB_ENV_PREFIX: &str = match std::str::from_utf8(&PREFIX_BYTES) {
    Ok(s) => s,
    Err(_) => panic!("TOOL_NAME must be valid UTF-8"),
};

/// Default RFC 2606 `.invalid` placeholder URI base for RFC 9457 `type` fields (`R70`, `R77`).
pub const DEFAULT_PROBLEM_BASE_URI: &str = "https://problems.rs-launch-blueprint.invalid";

/// Default maximum buffered HTTP request body size (`1 MiB`, `R75`).
pub const DEFAULT_MAX_BODY_BYTES: usize = 1_048_576;

/// Default request timeout (`30 s`, `R75`).
pub const DEFAULT_REQUEST_TIMEOUT_SECONDS: u64 = 30;

/// Default graceful shutdown budget (`8 s`, `R69`, `R77`).
pub const DEFAULT_GRACEFUL_SHUTDOWN_SECONDS: u64 = 8;

/// Every registered `RSLBP_WEB_*` environment variable name (`R77` AC11, AC13).
///
/// Deliberately contains no secret-shaped variables and no applicability-switch variables.
pub const WEB_ENV_VARS: &[&str] = &[
    "RSLBP_WEB_HOST",
    "RSLBP_WEB_PORT",
    "RSLBP_WEB_ROOT_PATH",
    "RSLBP_WEB_LOG_LEVEL",
    "RSLBP_WEB_LOG_FORMAT",
    "RSLBP_WEB_CORS_ORIGINS",
    "RSLBP_WEB_REQUEST_TIMEOUT_SECONDS",
    "RSLBP_WEB_MAX_BODY_BYTES",
    "RSLBP_WEB_RATE_LIMIT_PER_IP",
    "RSLBP_WEB_RATE_LIMIT_PER_IP_BURST",
    "RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES",
    "RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS",
    "RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS",
    "RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES",
    "RSLBP_WEB_PROBLEM_BASE_URI",
    "RSLBP_WEB_METRICS_ENABLED",
    "RSLBP_WEB_OTEL_ENABLED",
    "RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS",
    "RSLBP_WEB_READINESS_PAUSE_SECONDS",
];

/// Validation failure raised while loading [`WebSettings`] (`R77`, maps to `RSLB203` / exit `2`).
#[derive(Debug, Clone, PartialEq, Eq, Error)]
pub enum SettingsError {
    /// Environment variable held a non-UTF-8 value.
    #[error("invalid non-UTF-8 value for {var}: expected valid UTF-8")]
    NonUtf8 {
        /// Full environment variable name.
        var: String,
    },
    /// Environment variable failed parsing or constraint validation.
    #[error("invalid value '{value}' for {var}: expected {expected}")]
    InvalidValue {
        /// Full environment variable name.
        var: String,
        /// Offending string value.
        value: String,
        /// Human-readable expectation description.
        expected: String,
    },
    /// Cross-field configuration invariant failed.
    #[error("{message}")]
    InvalidCombination {
        /// Diagnostic message naming all involved environment variables.
        message: String,
    },
}

impl SettingsError {
    /// Stable catalog code for web settings failures (`RSLB203` / `Exit::Usage`).
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        ErrorCode::ConfigInvalid
    }
}

/// Complete, validated configuration for the optional HTTP web service (`R77`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct WebSettings {
    /// Listen IP address (`RSLBP_WEB_HOST`, default `127.0.0.1`).
    pub host: IpAddr,
    /// Listen TCP port (`RSLBP_WEB_PORT`, default `8000`, `0` selects an ephemeral OS port).
    pub port: u16,
    /// Optional reverse-proxy mount prefix (e.g. `"/api"`, never containing a version segment).
    pub root_path: String,
    /// Service diagnostic log level (`RSLBP_WEB_LOG_LEVEL`, default `info`).
    pub log_level: LogLevel,
    /// Concrete service log format (`RSLBP_WEB_LOG_FORMAT`, default `json`, rejects `auto`).
    pub log_format: ServiceLogFormat,
    /// Allowed browser CORS origins (`RSLBP_WEB_CORS_ORIGINS`, empty disables CORS middleware).
    pub cors_origins: Vec<HeaderValue>,
    /// End-to-end request timeout (`RSLBP_WEB_REQUEST_TIMEOUT_SECONDS`, default `30 s`).
    pub request_timeout: Duration,
    /// Maximum buffered request/response body cap (`RSLBP_WEB_MAX_BODY_BYTES`, default `1 MiB`).
    pub max_body_bytes: usize,
    /// Sustained per-IP rate limit policy (`RSLBP_WEB_RATE_LIMIT_PER_IP`, default `10/second`).
    pub rate_limit_per_ip: RateLimitPolicy,
    /// Burst ceiling paired with `rate_limit_per_ip` (`RSLBP_WEB_RATE_LIMIT_PER_IP_BURST`, default `20`).
    pub rate_limit_per_ip_burst: NonZeroU32,
    /// Maximum tracked client IP buckets (`RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES`, default `10_000`).
    pub rate_limit_max_entries: NonZeroUsize,
    /// Retention TTL for completed idempotency entries (`RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS`).
    pub idempotency_ttl: Duration,
    /// In-flight claim expiry deadline (`RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS`).
    pub idempotency_in_flight: Duration,
    /// Maximum idempotency store entry capacity (`RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES`).
    pub idempotency_max_entries: NonZeroUsize,
    /// HTTPS base URI prefix for RFC 9457 `type` fields (`RSLBP_WEB_PROBLEM_BASE_URI`).
    pub problem_base_uri: String,
    /// Whether `/metrics` telemetry endpoint is enabled when `metrics` feature is built (P09).
    pub metrics_enabled: bool,
    /// Whether OpenTelemetry tracing export is enabled when `otel` feature is built (P09).
    pub otel_enabled: bool,
    /// Total graceful shutdown deadline (`RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS`, default `8 s`).
    pub graceful_shutdown: Duration,
    /// Pre-drain readiness pause while `/readyz` returns `503` (`RSLBP_WEB_READINESS_PAUSE_SECONDS`).
    pub readiness_pause: Duration,
}

impl Default for WebSettings {
    fn default() -> Self {
        let burst = NonZeroU32::new(DEFAULT_RATE_LIMIT_BURST).unwrap_or(NonZeroU32::MIN);
        let rl_cap = NonZeroUsize::new(DEFAULT_RATE_LIMIT_MAX_ENTRIES).unwrap_or(NonZeroUsize::MIN);
        let idem_cap =
            NonZeroUsize::new(DEFAULT_IDEMPOTENCY_MAX_ENTRIES).unwrap_or(NonZeroUsize::MIN);
        Self {
            host: IpAddr::V4(Ipv4Addr::LOCALHOST),
            port: 8000,
            root_path: String::new(),
            log_level: LogLevel::Info,
            log_format: ServiceLogFormat::Json,
            cors_origins: Vec::new(),
            request_timeout: Duration::from_secs(DEFAULT_REQUEST_TIMEOUT_SECONDS),
            max_body_bytes: DEFAULT_MAX_BODY_BYTES,
            rate_limit_per_ip: RateLimitPolicy::default(),
            rate_limit_per_ip_burst: burst,
            rate_limit_max_entries: rl_cap,
            idempotency_ttl: DEFAULT_IDEMPOTENCY_TTL,
            idempotency_in_flight: DEFAULT_IDEMPOTENCY_IN_FLIGHT,
            idempotency_max_entries: idem_cap,
            problem_base_uri: DEFAULT_PROBLEM_BASE_URI.to_owned(),
            metrics_enabled: true,
            otel_enabled: false,
            graceful_shutdown: Duration::from_secs(DEFAULT_GRACEFUL_SHUTDOWN_SECONDS),
            readiness_pause: Duration::ZERO,
        }
    }
}

impl WebSettings {
    /// Load and validate [`WebSettings`] from the current process environment (`R77`).
    pub fn from_env() -> Result<Self, SettingsError> {
        Self::from_vars(std::env::vars_os())
    }

    /// Parse and validate [`WebSettings`] from an arbitrary `(key, value)` iterator (`R77`).
    ///
    /// Variables without [`WEB_ENV_PREFIX`] and exported-but-empty values are ignored, leaving
    /// defaults intact.
    pub fn from_vars<I>(vars: I) -> Result<Self, SettingsError>
    where
        I: IntoIterator<Item = (OsString, OsString)>,
    {
        let mut map: HashMap<String, String> = HashMap::new();
        for (raw_k, raw_v) in vars {
            let Ok(k) = raw_k.into_string() else {
                continue;
            };
            if !k.starts_with(WEB_ENV_PREFIX) {
                continue;
            }
            let Ok(v) = raw_v.into_string() else {
                return Err(SettingsError::NonUtf8 { var: k });
            };
            let trimmed = v.trim();
            if trimmed.is_empty() {
                continue;
            }
            map.insert(k, trimmed.to_owned());
        }

        let mut s = Self::default();

        if let Some(val) = map.get("RSLBP_WEB_HOST") {
            s.host = IpAddr::from_str(val).map_err(|_| SettingsError::InvalidValue {
                var: "RSLBP_WEB_HOST".to_owned(),
                value: val.clone(),
                expected: "a valid IPv4 or IPv6 address (e.g. 127.0.0.1 or ::1)".to_owned(),
            })?;
        }

        if let Some(val) = map.get("RSLBP_WEB_PORT") {
            s.port = val
                .parse::<u16>()
                .map_err(|_| SettingsError::InvalidValue {
                    var: "RSLBP_WEB_PORT".to_owned(),
                    value: val.clone(),
                    expected: "an integer in 0..=65535".to_owned(),
                })?;
        }

        if let Some(val) = map.get("RSLBP_WEB_ROOT_PATH") {
            validate_root_path(val)?;
            s.root_path = val.clone();
        }

        if let Some(val) = map.get("RSLBP_WEB_LOG_LEVEL") {
            s.log_level = LogLevel::from_str(val).map_err(|_| SettingsError::InvalidValue {
                var: "RSLBP_WEB_LOG_LEVEL".to_owned(),
                value: val.clone(),
                expected: "one of: off, error, warn, info, debug, trace".to_owned(),
            })?;
        }

        if let Some(val) = map.get("RSLBP_WEB_LOG_FORMAT") {
            s.log_format =
                ServiceLogFormat::from_str(val).map_err(|_| SettingsError::InvalidValue {
                    var: "RSLBP_WEB_LOG_FORMAT".to_owned(),
                    value: val.clone(),
                    expected: "one of: json, console ('auto' is rejected for services)".to_owned(),
                })?;
        }

        if let Some(val) = map.get("RSLBP_WEB_CORS_ORIGINS") {
            s.cors_origins = parse_cors_origins(val)?;
        }

        if let Some(val) = map.get("RSLBP_WEB_REQUEST_TIMEOUT_SECONDS") {
            let secs = parse_positive_u64("RSLBP_WEB_REQUEST_TIMEOUT_SECONDS", val)?;
            s.request_timeout = Duration::from_secs(secs);
        }

        if let Some(val) = map.get("RSLBP_WEB_MAX_BODY_BYTES") {
            s.max_body_bytes = parse_positive_usize("RSLBP_WEB_MAX_BODY_BYTES", val)?;
        }

        if let Some(val) = map.get("RSLBP_WEB_RATE_LIMIT_PER_IP") {
            let parsed =
                RateLimitPolicy::from_str(val).map_err(|err| SettingsError::InvalidValue {
                    var: "RSLBP_WEB_RATE_LIMIT_PER_IP".to_owned(),
                    value: val.clone(),
                    expected: format!(
                        "a positive '<count>/<unit>' rate (e.g. 10/second; {err}); rate limiting cannot be disabled"
                    ),
                })?;
            s.rate_limit_per_ip = parsed;
        }

        if let Some(val) = map.get("RSLBP_WEB_RATE_LIMIT_PER_IP_BURST") {
            let burst = parse_positive_u32("RSLBP_WEB_RATE_LIMIT_PER_IP_BURST", val)?;
            s.rate_limit_per_ip_burst = burst;
        }

        if let Some(val) = map.get("RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES") {
            let cap = parse_positive_usize("RSLBP_WEB_RATE_LIMIT_MAX_ENTRIES", val)?;
            if let Some(nz) = NonZeroUsize::new(cap) {
                s.rate_limit_max_entries = nz;
            }
        }

        if let Some(val) = map.get("RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS") {
            let secs = parse_positive_u64("RSLBP_WEB_IDEMPOTENCY_TTL_SECONDS", val)?;
            s.idempotency_ttl = Duration::from_secs(secs);
        }

        if let Some(val) = map.get("RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS") {
            let secs = parse_positive_u64("RSLBP_WEB_IDEMPOTENCY_IN_FLIGHT_SECONDS", val)?;
            s.idempotency_in_flight = Duration::from_secs(secs);
        }

        if let Some(val) = map.get("RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES") {
            let cap = parse_positive_usize("RSLBP_WEB_IDEMPOTENCY_MAX_ENTRIES", val)?;
            if let Some(nz) = NonZeroUsize::new(cap) {
                s.idempotency_max_entries = nz;
            }
        }

        if let Some(val) = map.get("RSLBP_WEB_PROBLEM_BASE_URI") {
            s.problem_base_uri = validate_problem_base_uri(val)?;
        }

        if let Some(val) = map.get("RSLBP_WEB_METRICS_ENABLED") {
            s.metrics_enabled = parse_bool("RSLBP_WEB_METRICS_ENABLED", val)?;
        }

        if let Some(val) = map.get("RSLBP_WEB_OTEL_ENABLED") {
            s.otel_enabled = parse_bool("RSLBP_WEB_OTEL_ENABLED", val)?;
        }

        if let Some(val) = map.get("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS") {
            let secs = parse_positive_u64("RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS", val)?;
            s.graceful_shutdown = Duration::from_secs(secs);
        }

        if let Some(val) = map.get("RSLBP_WEB_READINESS_PAUSE_SECONDS") {
            let secs = val
                .parse::<u64>()
                .map_err(|_| SettingsError::InvalidValue {
                    var: "RSLBP_WEB_READINESS_PAUSE_SECONDS".to_owned(),
                    value: val.clone(),
                    expected: "a non-negative integer number of seconds".to_owned(),
                })?;
            s.readiness_pause = Duration::from_secs(secs);
        }

        if s.readiness_pause >= s.graceful_shutdown {
            return Err(SettingsError::InvalidCombination {
                message: format!(
                    "RSLBP_WEB_READINESS_PAUSE_SECONDS ({}s) must be strictly less than RSLBP_WEB_GRACEFUL_SHUTDOWN_SECONDS ({}s)",
                    s.readiness_pause.as_secs(),
                    s.graceful_shutdown.as_secs()
                ),
            });
        }

        Ok(s)
    }

    /// Remaining graceful drain budget after subtracting [`Self::readiness_pause`] (`R77` AC15).
    #[must_use]
    pub fn drain_budget(&self) -> Duration {
        self.graceful_shutdown.saturating_sub(self.readiness_pause)
    }

    /// Combine [`Self::rate_limit_per_ip`] and [`Self::rate_limit_per_ip_burst`] into the active
    /// [`RateLimitPolicy`].
    #[must_use]
    pub fn effective_rate_limit_policy(&self) -> RateLimitPolicy {
        self.rate_limit_per_ip
            .with_burst(self.rate_limit_per_ip_burst)
    }

    /// Combine [`Self::host`] and [`Self::port`] into a TCP [`SocketAddr`].
    #[must_use]
    pub const fn bind_addr(&self) -> SocketAddr {
        SocketAddr::new(self.host, self.port)
    }
}

fn validate_root_path(val: &str) -> Result<(), SettingsError> {
    if !val.starts_with('/') {
        return Err(SettingsError::InvalidValue {
            var: "RSLBP_WEB_ROOT_PATH".to_owned(),
            value: val.to_owned(),
            expected: "a path starting with '/' without a trailing slash or API version segment"
                .to_owned(),
        });
    }
    if val == "/" || val.ends_with('/') {
        return Err(SettingsError::InvalidValue {
            var: "RSLBP_WEB_ROOT_PATH".to_owned(),
            value: val.to_owned(),
            expected: "a non-root prefix with no trailing '/' (e.g. /api)".to_owned(),
        });
    }
    for segment in val.split('/').skip(1) {
        if segment.is_empty() || is_version_segment(segment) {
            return Err(SettingsError::InvalidValue {
                var: "RSLBP_WEB_ROOT_PATH".to_owned(),
                value: val.to_owned(),
                expected: "a path prefix containing no empty or version segments (e.g. /v1, /v2)"
                    .to_owned(),
            });
        }
    }
    Ok(())
}

fn is_version_segment(seg: &str) -> bool {
    let lower = seg.to_ascii_lowercase();
    let Some(rest) = lower.strip_prefix('v') else {
        return false;
    };
    !rest.is_empty()
        && rest
            .split('.')
            .all(|part| !part.is_empty() && part.bytes().all(|b| b.is_ascii_digit()))
}

fn validate_problem_base_uri(val: &str) -> Result<String, SettingsError> {
    if val.eq_ignore_ascii_case("about:blank") {
        return Err(SettingsError::InvalidValue {
            var: "RSLBP_WEB_PROBLEM_BASE_URI".to_owned(),
            value: val.to_owned(),
            expected: "an https:// base URI ('about:blank' is forbidden by R5.13.5)".to_owned(),
        });
    }
    let Some(rest) = val.strip_prefix("https://") else {
        return Err(SettingsError::InvalidValue {
            var: "RSLBP_WEB_PROBLEM_BASE_URI".to_owned(),
            value: val.to_owned(),
            expected: "an https:// base URI (e.g. https://errors.example.com/problems)".to_owned(),
        });
    };
    let host = rest.split('/').next().unwrap_or("");
    if host.is_empty()
        || val.contains('?')
        || val.contains('#')
        || val.chars().any(char::is_whitespace)
    {
        return Err(SettingsError::InvalidValue {
            var: "RSLBP_WEB_PROBLEM_BASE_URI".to_owned(),
            value: val.to_owned(),
            expected: "a valid https:// base URI with non-empty host and no query or fragment"
                .to_owned(),
        });
    }
    Ok(val.trim_end_matches('/').to_owned())
}

fn parse_cors_origins(raw: &str) -> Result<Vec<HeaderValue>, SettingsError> {
    let mut out = Vec::new();
    for item in raw.split(',') {
        let origin = item.trim();
        if origin.is_empty() {
            continue;
        }
        let authority = origin
            .strip_prefix("https://")
            .or_else(|| origin.strip_prefix("http://"));
        let valid_shape = authority.is_some_and(|rest| {
            !rest.is_empty()
                && !rest.contains('/')
                && !rest.contains('?')
                && !rest.contains('#')
                && !rest.chars().any(char::is_whitespace)
        });
        if !valid_shape {
            return Err(SettingsError::InvalidValue {
                var: "RSLBP_WEB_CORS_ORIGINS".to_owned(),
                value: origin.to_owned(),
                expected: "comma-separated http(s)://host[:port] origins with no path or wildcard"
                    .to_owned(),
            });
        }
        let hv = HeaderValue::from_str(origin).map_err(|_| SettingsError::InvalidValue {
            var: "RSLBP_WEB_CORS_ORIGINS".to_owned(),
            value: origin.to_owned(),
            expected: "valid HTTP header value origins".to_owned(),
        })?;
        out.push(hv);
    }
    Ok(out)
}

fn parse_positive_u64(var: &str, raw: &str) -> Result<u64, SettingsError> {
    match raw.parse::<u64>() {
        Ok(n) if n > 0 => Ok(n),
        _ => Err(SettingsError::InvalidValue {
            var: var.to_owned(),
            value: raw.to_owned(),
            expected: "a positive integer >= 1".to_owned(),
        }),
    }
}

fn parse_positive_u32(var: &str, raw: &str) -> Result<NonZeroU32, SettingsError> {
    match raw.parse::<u32>().ok().and_then(NonZeroU32::new) {
        Some(n) => Ok(n),
        None => Err(SettingsError::InvalidValue {
            var: var.to_owned(),
            value: raw.to_owned(),
            expected: "a positive integer >= 1".to_owned(),
        }),
    }
}

fn parse_positive_usize(var: &str, raw: &str) -> Result<usize, SettingsError> {
    match raw.parse::<usize>() {
        Ok(n) if n > 0 => Ok(n),
        _ => Err(SettingsError::InvalidValue {
            var: var.to_owned(),
            value: raw.to_owned(),
            expected: "a positive integer >= 1".to_owned(),
        }),
    }
}

fn parse_bool(var: &str, raw: &str) -> Result<bool, SettingsError> {
    match raw.to_ascii_lowercase().as_str() {
        "true" | "1" => Ok(true),
        "false" | "0" => Ok(false),
        _ => Err(SettingsError::InvalidValue {
            var: var.to_owned(),
            value: raw.to_owned(),
            expected: "one of: true, false, 1, 0".to_owned(),
        }),
    }
}
