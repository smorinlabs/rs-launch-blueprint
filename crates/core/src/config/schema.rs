//! Typed configuration schema, enums, overrides, and typestate validation wrapper (`R55`).

use std::fmt;
use std::num::NonZeroU32;
use std::path::PathBuf;
use std::str::FromStr;

use serde::{Deserialize, Serialize};

use crate::config::validate;
use crate::error::ConfigError;

/// Default human/machine output format (`[output].format`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum OutputFormat {
    /// Human-readable table output (default).
    #[default]
    Table,
    /// Machine-readable JSON output.
    Json,
    /// One resource name per line.
    Name,
    /// Markdown table output.
    Markdown,
}

impl OutputFormat {
    /// Canonical lowercase wire representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Table => "table",
            Self::Json => "json",
            Self::Name => "name",
            Self::Markdown => "markdown",
        }
    }
}

impl fmt::Display for OutputFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for OutputFormat {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "table" => Ok(Self::Table),
            "json" => Ok(Self::Json),
            "name" => Ok(Self::Name),
            "markdown" => Ok(Self::Markdown),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "output.format".to_owned(),
                detail: format!("expected one of: table, json, name, markdown (got '{s}')"),
            }),
        }
    }
}

/// Terminal color policy (`[output].color`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum ColorPreference {
    /// Enable color when stderr/stdout is a TTY and `NO_COLOR` is unset (default).
    #[default]
    Auto,
    /// Force ANSI color output.
    Always,
    /// Disable ANSI color output.
    Never,
}

impl ColorPreference {
    /// Canonical lowercase wire representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Auto => "auto",
            Self::Always => "always",
            Self::Never => "never",
        }
    }
}

impl fmt::Display for ColorPreference {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for ColorPreference {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "auto" => Ok(Self::Auto),
            "always" => Ok(Self::Always),
            "never" => Ok(Self::Never),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "output.color".to_owned(),
                detail: format!("expected one of: auto, always, never (got '{s}')"),
            }),
        }
    }
}

/// Diagnostic log level (`[logging].level`, `[logging].file-level`, `R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum LogLevel {
    /// Disable all diagnostic logging.
    Off,
    /// Errors only.
    Error,
    /// Warnings and errors (default CLI baseline).
    #[default]
    Warn,
    /// Informational operational milestones and above.
    Info,
    /// Detailed debugging diagnostics and above.
    Debug,
    /// Verbose trace-level diagnostics and above.
    Trace,
}

impl LogLevel {
    /// Canonical lowercase wire representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Off => "off",
            Self::Error => "error",
            Self::Warn => "warn",
            Self::Info => "info",
            Self::Debug => "debug",
            Self::Trace => "trace",
        }
    }
}

impl fmt::Display for LogLevel {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for LogLevel {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "off" => Ok(Self::Off),
            "error" => Ok(Self::Error),
            "warn" | "warning" => Ok(Self::Warn),
            "info" => Ok(Self::Info),
            "debug" => Ok(Self::Debug),
            "trace" => Ok(Self::Trace),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "logging.level".to_owned(),
                detail: format!(
                    "expected one of: off, error, warn, info, debug, trace (got '{s}')"
                ),
            }),
        }
    }
}

/// File sink serialization format (`[logging].file-format`, `R59`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(rename_all = "lowercase")]
pub enum FileLogFormat {
    /// Plain ANSI-free human-readable text lines (default).
    #[default]
    Text,
    /// Newline-delimited structured JSON objects.
    Json,
}

impl FileLogFormat {
    /// Canonical lowercase wire representation.
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Text => "text",
            Self::Json => "json",
        }
    }
}

impl fmt::Display for FileLogFormat {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

impl FromStr for FileLogFormat {
    type Err = ConfigError;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.trim().to_ascii_lowercase().as_str() {
            "text" => Ok(Self::Text),
            "json" => Ok(Self::Json),
            _ => Err(ConfigError::InvalidValue {
                path: None,
                key: "logging.file-format".to_owned(),
                detail: format!("expected one of: text, json (got '{s}')"),
            }),
        }
    }
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

/// Resolved concrete console log format after TTY detection (`R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ResolvedLogFormat {
    /// Human-readable console lines.
    Console,
    /// Newline-delimited structured JSON objects.
    Json,
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

    /// Convert into [`ResolvedLogFormat`].
    #[must_use]
    pub const fn resolved(self) -> ResolvedLogFormat {
        match self {
            Self::Json => ResolvedLogFormat::Json,
            Self::Console => ResolvedLogFormat::Console,
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

/// `[output]` configuration section.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct OutputConfig {
    /// Default output format.
    pub format: OutputFormat,
    /// Color preference.
    pub color: ColorPreference,
    /// Optional positive cap on list results.
    pub limit: Option<NonZeroU32>,
}

/// `[logging]` configuration section (`R58`, `R59`).
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct LoggingConfig {
    /// Default console diagnostic log level.
    pub level: LogLevel,
    /// Optional rotating file log destination.
    pub file: Option<PathBuf>,
    /// File sink format (`text` or `json`).
    #[serde(rename = "file-format")]
    pub file_format: FileLogFormat,
    /// Optional independent file sink diagnostic level.
    #[serde(rename = "file-level")]
    pub file_level: Option<LogLevel>,
}

/// Top-level typed configuration document (`R55`).
///
/// Deliberately contains no `token` or secret field (`R56`) and uses no `#[serde(flatten)]`.
#[derive(Debug, Clone, PartialEq, Eq, Default, Serialize, Deserialize)]
#[serde(default)]
pub struct ConfigFile {
    /// `[output]` settings.
    pub output: OutputConfig,
    /// `[logging]` settings.
    pub logging: LoggingConfig,
}

/// Sparse overrides applied from environment variables (rung 2) or CLI flags (rung 1).
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct ConfigOverrides {
    /// Override for `[output].format`.
    pub output_format: Option<OutputFormat>,
    /// Override for `[output].color`.
    pub output_color: Option<ColorPreference>,
    /// Override for `[output].limit`.
    pub output_limit: Option<NonZeroU32>,
    /// Override for `[logging].level`.
    pub logging_level: Option<LogLevel>,
    /// Override for `[logging].file`.
    pub logging_file: Option<PathBuf>,
    /// Override for `[logging].file-format`.
    pub logging_file_format: Option<FileLogFormat>,
    /// Override for `[logging].file-level`.
    pub logging_file_level: Option<LogLevel>,
}

/// Unvalidated TOML configuration table prior to schema validation (`R55`).
#[derive(Debug, Clone)]
pub struct UnvalidatedConfig {
    table: toml::Table,
}

impl UnvalidatedConfig {
    /// Wrap a parsed `toml::Table` for schema validation.
    #[must_use]
    pub const fn from_table(table: toml::Table) -> Self {
        Self { table }
    }

    /// Parse a raw TOML string into an [`UnvalidatedConfig`].
    pub fn parse_str(raw: &str) -> Result<Self, toml::de::Error> {
        let table: toml::Table = toml::from_str(raw)?;
        Ok(Self { table })
    }

    /// Borrow the underlying raw `toml::Table`.
    #[must_use]
    pub const fn as_table(&self) -> &toml::Table {
        &self.table
    }

    /// Validate every key in deterministic sorted order, collecting all issues and unknown keys.
    #[must_use]
    pub fn validate(self) -> ValidationReport {
        validate::validate_table(&self.table)
    }
}

/// Validated configuration guaranteed to have passed schema validation (`R55` typestate gate).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValidConfig {
    inner: ConfigFile,
}

impl ValidConfig {
    /// Construct a [`ValidConfig`] holding built-in defaults (rung 6).
    #[must_use]
    pub fn defaults() -> Self {
        Self {
            inner: ConfigFile::default(),
        }
    }

    /// Construct from a validated [`ConfigFile`] inside the config subsystem.
    pub(crate) const fn from_validated(inner: ConfigFile) -> Self {
        Self { inner }
    }

    /// Borrow the underlying typed [`ConfigFile`].
    #[must_use]
    pub const fn as_config(&self) -> &ConfigFile {
        &self.inner
    }

    /// Consume the wrapper and return the owned [`ConfigFile`].
    #[must_use]
    pub fn into_inner(self) -> ConfigFile {
        self.inner
    }

    /// Return a new [`ValidConfig`] with any `Some` fields in `overrides` applied on top.
    #[must_use]
    pub fn apply_overrides(&self, overrides: &ConfigOverrides) -> Self {
        let mut next = self.inner.clone();
        if let Some(format) = overrides.output_format {
            next.output.format = format;
        }
        if let Some(color) = overrides.output_color {
            next.output.color = color;
        }
        if let Some(limit) = overrides.output_limit {
            next.output.limit = Some(limit);
        }
        if let Some(level) = overrides.logging_level {
            next.logging.level = level;
        }
        if let Some(file) = &overrides.logging_file {
            next.logging.file = Some(file.clone());
        }
        if let Some(file_format) = overrides.logging_file_format {
            next.logging.file_format = file_format;
        }
        if let Some(file_level) = overrides.logging_file_level {
            next.logging.file_level = Some(file_level);
        }
        Self { inner: next }
    }
}

/// A single schema validation diagnostic anchored to a dotted TOML key path (`R55`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValidationIssue {
    /// Dotted configuration key path (for example, `"output.format"` or `"output"`).
    pub path: String,
    /// Diagnostic reason describing why the value failed validation.
    pub message: String,
}

impl fmt::Display for ValidationIssue {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}: {}", self.path, self.message)
    }
}

/// Aggregated validation outcome produced by [`UnvalidatedConfig::validate`] (`R55`).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ValidationReport {
    /// Validated configuration with invalid leaves fallen back to defaults.
    pub config: ValidConfig,
    /// Schema issues in deterministic sorted key order.
    pub issues: Vec<ValidationIssue>,
    /// Unrecognized keys in deterministic sorted key order.
    pub unknown_keys: Vec<String>,
    /// Prohibited secret keys detected in the config table (values never captured).
    pub prohibited_secret_keys: Vec<String>,
}

impl ValidationReport {
    /// Return `true` if validation produced no issues, no unknown keys, and no secret keys.
    #[must_use]
    pub fn is_clean(&self) -> bool {
        self.issues.is_empty()
            && self.unknown_keys.is_empty()
            && self.prohibited_secret_keys.is_empty()
    }
}
