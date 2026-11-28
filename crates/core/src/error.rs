//! Error taxonomy, stable `RSLB###` error catalog, exit codes, and typed library errors
//! (`R67`, `R03`, `R55`, `R56`).

use std::borrow::Cow;
use std::fmt;
use std::io;
use std::ops::Range;
use std::path::PathBuf;
use std::process::ExitCode;

use serde::{Deserialize, Serialize};
use thiserror::Error;

/// Process exit-code taxonomy from the org CLI Design Standard R6.1 (`R67`).
///
/// Unlisted failures collapse to [`Exit::Runtime`] (`1`).
#[repr(u8)]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum Exit {
    /// Successful completion (`0`).
    Success = 0,
    /// Generic runtime, I/O, transport, or unexpected failure (`1`).
    Runtime = 1,
    /// Command usage, argument parse, configuration, or input error (`2`).
    Usage = 2,
    /// Requested resource does not exist (`3`).
    NotFound = 3,
    /// Authentication or authorization required or rejected (`4`).
    Auth = 4,
    /// Resource conflict or precondition failure (`5`).
    Conflict = 5,
    /// Interrupted by `SIGINT` or Ctrl-C (`130`).
    SigInt = 130,
    /// Terminated by `SIGTERM` (`143`).
    SigTerm = 143,
}

impl Exit {
    /// Return the numeric POSIX exit code for this taxonomy variant.
    #[must_use]
    pub const fn code(self) -> u8 {
        self as u8
    }
}

impl From<Exit> for ExitCode {
    fn from(value: Exit) -> Self {
        Self::from(value.code())
    }
}

/// Stable, append-only `error-contract/v1` error code catalog (`R67`).
///
/// Wire tokens are produced exclusively by [`ErrorCode::as_str`] using explicit string literals,
/// never derived from variant names, `Debug`, or discriminants. New variants may only be appended
/// to [`ErrorCode::ALL`].
#[non_exhaustive]
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash)]
pub enum ErrorCode {
    /// `RSLB000` — unexpected/internal error (`Exit::Runtime`).
    Unexpected,
    /// `RSLB101` — local I/O or unavailable resource error (`Exit::Runtime`).
    Io,
    /// `RSLB102` — network transport failure (DNS/connect/timeout/TLS) (`Exit::Runtime`).
    Transport,
    /// `RSLB103` — remote API protocol/status/schema failure (`Exit::Runtime`).
    RemoteApi,
    /// `RSLB104` — explicit configuration layer unreadable (`Exit::Runtime`).
    ConfigUnreadable,
    /// `RSLB201` — CLI usage or argument parse error (`Exit::Usage`).
    Usage,
    /// `RSLB202` — explicit configuration document unparsable (`Exit::Usage`).
    ConfigUnparsable,
    /// `RSLB203` — configuration value or key invalid (`Exit::Usage`).
    ConfigInvalid,
    /// `RSLB204` — secret supplied through a prohibited channel (`Exit::Usage`).
    ProhibitedSecretChannel,
    /// `RSLB205` — required non-auth input or consent unavailable (`Exit::Usage`).
    InputUnavailable,
    /// `RSLB301` — requested resource not found (`Exit::NotFound`).
    NotFound,
    /// `RSLB401` — required credentials absent (`Exit::Auth`).
    CredentialsAbsent,
    /// `RSLB402` — credentials rejected by remote service (`Exit::Auth`).
    CredentialsRejected,
    /// `RSLB501` — conflict or precondition failed (`Exit::Conflict`).
    Conflict,
    /// `RSLB901` — process interrupted by `SIGINT` (`Exit::SigInt`).
    SigInt,
    /// `RSLB902` — process terminated by `SIGTERM` (`Exit::SigTerm`).
    SigTerm,
    /// `RSLB903` — interactive prompt interrupted by Ctrl-C (`Exit::SigInt`).
    PromptInterrupted,
}

impl ErrorCode {
    /// Every registered [`ErrorCode`] variant in append-only registration order (`R67`).
    pub const ALL: &'static [Self] = &[
        Self::Unexpected,
        Self::Io,
        Self::Transport,
        Self::RemoteApi,
        Self::ConfigUnreadable,
        Self::Usage,
        Self::ConfigUnparsable,
        Self::ConfigInvalid,
        Self::ProhibitedSecretChannel,
        Self::InputUnavailable,
        Self::NotFound,
        Self::CredentialsAbsent,
        Self::CredentialsRejected,
        Self::Conflict,
        Self::SigInt,
        Self::SigTerm,
        Self::PromptInterrupted,
    ];

    /// Return the stable wire code string (`RSLBddd`).
    #[must_use]
    pub const fn as_str(&self) -> &'static str {
        match self {
            Self::Unexpected => "RSLB000",
            Self::Io => "RSLB101",
            Self::Transport => "RSLB102",
            Self::RemoteApi => "RSLB103",
            Self::ConfigUnreadable => "RSLB104",
            Self::Usage => "RSLB201",
            Self::ConfigUnparsable => "RSLB202",
            Self::ConfigInvalid => "RSLB203",
            Self::ProhibitedSecretChannel => "RSLB204",
            Self::InputUnavailable => "RSLB205",
            Self::NotFound => "RSLB301",
            Self::CredentialsAbsent => "RSLB401",
            Self::CredentialsRejected => "RSLB402",
            Self::Conflict => "RSLB501",
            Self::SigInt => "RSLB901",
            Self::SigTerm => "RSLB902",
            Self::PromptInterrupted => "RSLB903",
        }
    }

    /// Return the [`Exit`] taxonomy status mapped to this error code.
    #[must_use]
    pub const fn exit(&self) -> Exit {
        match self {
            Self::Unexpected
            | Self::Io
            | Self::Transport
            | Self::RemoteApi
            | Self::ConfigUnreadable => Exit::Runtime,
            Self::Usage
            | Self::ConfigUnparsable
            | Self::ConfigInvalid
            | Self::ProhibitedSecretChannel
            | Self::InputUnavailable => Exit::Usage,
            Self::NotFound => Exit::NotFound,
            Self::CredentialsAbsent | Self::CredentialsRejected => Exit::Auth,
            Self::Conflict => Exit::Conflict,
            Self::SigInt | Self::PromptInterrupted => Exit::SigInt,
            Self::SigTerm => Exit::SigTerm,
        }
    }
}

impl fmt::Display for ErrorCode {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(self.as_str())
    }
}

/// Transport and adapter error vocabulary (`R03`, `R67`).
///
/// Deliberately carries **no** `NotFound` variant: absence on a by-identity read is returned as
/// `Ok(None)` and translated to [`DomainError::NotFound`] by the application use case.
#[non_exhaustive]
#[derive(Debug, Error)]
pub enum PortError {
    /// Local I/O error inside an adapter (`RSLB101`).
    #[error("local I/O error: {source}")]
    Io {
        /// Underlying I/O error.
        #[source]
        source: io::Error,
    },
    /// Transport failure such as DNS, connect, timeout, or TLS error (`RSLB102`).
    #[error("transport failed: {source}")]
    Transport {
        /// Type-erased underlying transport cause so no HTTP-client type leaks into `core`.
        #[source]
        source: Box<dyn std::error::Error + Send + Sync + 'static>,
    },
    /// Remote API error: unexpected HTTP status or unparsable/drifted payload (`RSLB103`).
    #[error("remote API failure: {detail}")]
    RemoteApi {
        /// Sanitized human-readable summary of the upstream failure.
        detail: String,
        /// Optional underlying decode or protocol cause.
        #[source]
        source: Option<Box<dyn std::error::Error + Send + Sync + 'static>>,
    },
    /// Remote API rejected credentials (`401` / `403`, `RSLB402`).
    #[error("authentication rejected by remote API: {detail}")]
    Unauthorized {
        /// Sanitized explanation.
        detail: String,
        /// Optional underlying cause.
        #[source]
        source: Option<Box<dyn std::error::Error + Send + Sync + 'static>>,
    },
    /// Remote API reported a conflict or failed precondition (`409`, `RSLB501`).
    #[error("remote API conflict: {detail}")]
    Conflict {
        /// Sanitized conflict description.
        detail: String,
        /// Optional underlying cause.
        #[source]
        source: Option<Box<dyn std::error::Error + Send + Sync + 'static>>,
    },
    /// Adapter internal state is unavailable (e.g., poisoned lock, `RSLB101`).
    #[error("adapter unavailable: {detail}")]
    Unavailable {
        /// Description of the unavailable state.
        detail: String,
    },
}

impl PortError {
    /// Return the stable [`ErrorCode`] for this port error.
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        match self {
            Self::Io { .. } | Self::Unavailable { .. } => ErrorCode::Io,
            Self::Transport { .. } => ErrorCode::Transport,
            Self::RemoteApi { .. } => ErrorCode::RemoteApi,
            Self::Unauthorized { .. } => ErrorCode::CredentialsRejected,
            Self::Conflict { .. } => ErrorCode::Conflict,
        }
    }

    /// Optional actionable next step for human and JSON error envelopes.
    #[must_use]
    pub fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::Unauthorized { .. } => Some(Cow::Borrowed(
                "check RSLBP_TOKEN or re-authenticate with `rslbp auth login`",
            )),
            Self::Transport { .. } => Some(Cow::Borrowed(
                "verify network connectivity and endpoint URL",
            )),
            Self::Io { .. }
            | Self::RemoteApi { .. }
            | Self::Conflict { .. }
            | Self::Unavailable { .. } => None,
        }
    }
}

/// Configuration read, parse, validation, and write errors (`R52`–`R56`, `R67`).
#[non_exhaustive]
#[derive(Debug, Error)]
pub enum ConfigError {
    /// An explicitly specified configuration file could not be read (`RSLB104`).
    #[error("cannot read config file '{}': {source}", path.display())]
    Unreadable {
        /// Path that failed to open or read.
        path: PathBuf,
        /// Underlying filesystem I/O error.
        #[source]
        source: io::Error,
    },
    /// An explicitly specified or writable configuration file failed TOML parsing (`RSLB202`).
    #[error("invalid TOML in config file '{}': {detail}", path.display())]
    Unparsable {
        /// Path of the unparsable file.
        path: PathBuf,
        /// Parser diagnostic message.
        detail: String,
        /// Optional byte range of the offending token.
        span: Option<Range<usize>>,
    },
    /// A configuration key's value violated schema constraints (`RSLB203`).
    #[error("invalid value for config key '{key}': {detail}")]
    InvalidValue {
        /// Optional path of the file containing the invalid value.
        path: Option<PathBuf>,
        /// Dotted configuration key name.
        key: String,
        /// Validation diagnostic message.
        detail: String,
    },
    /// An unknown configuration key was passed to a schema-checked operation (`RSLB203`).
    #[error("unknown config key '{key}'")]
    UnknownKey {
        /// Offending dotted key name.
        key: String,
        /// Allowed writable keys.
        valid_keys: Vec<&'static str>,
    },
    /// Caller attempted to write a secret into a layered configuration file (`RSLB204`).
    #[error("refusing to store secret key '{key}' in configuration file")]
    ProhibitedSecretChannel {
        /// Offending secret key name.
        key: String,
    },
    /// Writing the configuration file atomically failed (`RSLB101`).
    #[error("failed to write config file '{}': {source}", path.display())]
    WriteFailed {
        /// Target configuration file path.
        path: PathBuf,
        /// Underlying I/O error.
        #[source]
        source: io::Error,
    },
}

impl ConfigError {
    /// Return the stable [`ErrorCode`] for this configuration error.
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        match self {
            Self::Unreadable { .. } => ErrorCode::ConfigUnreadable,
            Self::Unparsable { .. } => ErrorCode::ConfigUnparsable,
            Self::InvalidValue { .. } | Self::UnknownKey { .. } => ErrorCode::ConfigInvalid,
            Self::ProhibitedSecretChannel { .. } => ErrorCode::ProhibitedSecretChannel,
            Self::WriteFailed { .. } => ErrorCode::Io,
        }
    }

    /// Optional actionable next step for human and JSON error envelopes.
    #[must_use]
    pub fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::ProhibitedSecretChannel { .. } => Some(Cow::Borrowed(
                "supply credentials via --token-file, RSLBP_TOKEN, or `rslbp auth login`",
            )),
            Self::UnknownKey { valid_keys, .. } if !valid_keys.is_empty() => Some(Cow::Owned(
                format!("settable keys: {}", valid_keys.join(", ")),
            )),
            Self::Unparsable { path, .. } => Some(Cow::Owned(format!(
                "fix the TOML syntax in '{}' or remove the file",
                path.display()
            ))),
            Self::Unreadable { .. }
            | Self::InvalidValue { .. }
            | Self::UnknownKey { .. }
            | Self::WriteFailed { .. } => None,
        }
    }
}

/// Credential storage and resolution errors (`R56`, `R67`).
#[non_exhaustive]
#[derive(Debug, Error)]
pub enum AuthError {
    /// Required credential is missing or empty (`RSLB401`).
    #[error("credentials absent: {detail}")]
    CredentialsAbsent {
        /// Explanation naming the missing credential source without revealing any secret.
        detail: String,
    },
    /// Local filesystem I/O failure while reading or writing credentials (`RSLB101`).
    #[error("credential file I/O error for '{}': {source}", path.display())]
    Io {
        /// Credential or token file path.
        path: PathBuf,
        /// Underlying filesystem I/O error.
        #[source]
        source: io::Error,
    },
    /// Credential backend (e.g., OS keychain) failed or is unavailable (`RSLB101`).
    #[error("credential store unavailable: {detail}")]
    StoreUnavailable {
        /// Sanitized backend error summary.
        detail: String,
    },
}

impl AuthError {
    /// Return the stable [`ErrorCode`] for this auth error.
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        match self {
            Self::CredentialsAbsent { .. } => ErrorCode::CredentialsAbsent,
            Self::Io { .. } | Self::StoreUnavailable { .. } => ErrorCode::Io,
        }
    }

    /// Optional actionable next step.
    #[must_use]
    pub fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::CredentialsAbsent { .. } => Some(Cow::Borrowed(
                "provide a token with --token-file, RSLBP_TOKEN, or `rslbp auth login`",
            )),
            Self::Io { .. } | Self::StoreUnavailable { .. } => None,
        }
    }
}

/// Top-level typed domain error returned by application services (`R03`, `R67`).
#[non_exhaustive]
#[derive(Debug, Error)]
pub enum DomainError {
    /// Requested resource was authoritatively absent (`RSLB301`, exit `3`).
    #[error("{kind} '{id}' not found")]
    NotFound {
        /// Resource kind (e.g., `"project"`).
        kind: &'static str,
        /// Offending resource identifier.
        id: String,
    },
    /// Driven-I/O port failure, preserving the underlying `source()` chain.
    #[error(transparent)]
    Port(#[from] PortError),
    /// Configuration loading or mutation error.
    #[error(transparent)]
    Config(#[from] ConfigError),
    /// Authentication or credential-resolution error.
    #[error(transparent)]
    Auth(#[from] AuthError),
    /// Invalid user input or domain usage error (`RSLB201`, exit `2`).
    #[error("{message}")]
    Usage {
        /// Human-readable error message.
        message: String,
        /// Optional remediation hint.
        hint: Option<String>,
    },
    /// Required non-auth input or confirmation unavailable (`RSLB205`, exit `2`).
    #[error("{message}")]
    InputUnavailable {
        /// Human-readable error message.
        message: String,
        /// Optional remediation hint.
        hint: Option<String>,
    },
    /// Resource or file conflict / precondition failed (`RSLB501`, exit `5`).
    #[error("{message}")]
    Conflict {
        /// Human-readable error message.
        message: String,
        /// Optional remediation hint.
        hint: Option<String>,
    },
    /// Clipboard backend failure after rendering (`RSLB101`, exit `1`, `R62`).
    #[error(transparent)]
    Clipboard(#[from] crate::clipboard::ClipboardError),
    /// Interactive prompt interrupted by Ctrl-C (`RSLB903`, exit `130`, `R61`, `R67`).
    #[error("prompt interrupted")]
    PromptInterrupted,
}

impl DomainError {
    /// Return the stable [`ErrorCode`] for this domain error.
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        match self {
            Self::NotFound { .. } => ErrorCode::NotFound,
            Self::Port(err) => err.error_code(),
            Self::Config(err) => err.error_code(),
            Self::Auth(err) => err.error_code(),
            Self::Usage { .. } => ErrorCode::Usage,
            Self::InputUnavailable { .. } => ErrorCode::InputUnavailable,
            Self::Conflict { .. } => ErrorCode::Conflict,
            Self::Clipboard(err) => err.error_code(),
            Self::PromptInterrupted => ErrorCode::PromptInterrupted,
        }
    }

    /// Return the process [`Exit`] code for this domain error.
    #[must_use]
    pub const fn exit(&self) -> Exit {
        self.error_code().exit()
    }

    /// Return an optional structured hint naming a concrete next step (`R67`, `R7.6`).
    #[must_use]
    pub fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::NotFound { .. } | Self::PromptInterrupted => None,
            Self::Port(err) => err.hint(),
            Self::Config(err) => err.hint(),
            Self::Auth(err) => err.hint(),
            Self::Clipboard(err) => err.hint(),
            Self::Usage { hint, .. }
            | Self::InputUnavailable { hint, .. }
            | Self::Conflict { hint, .. } => hint.as_deref().map(Cow::Borrowed),
        }
    }

    /// Build the canonical `error-contract/v1` JSON envelope for this error.
    #[must_use]
    pub fn to_envelope(&self) -> ErrorEnvelope {
        ErrorEnvelope::new(
            self.error_code(),
            self.to_string(),
            self.hint().map(Cow::into_owned),
        )
    }
}

/// Inner payload of [`ErrorEnvelope`] (`{"code","message","hint"?}`).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ErrorBody {
    /// Stable `RSLBddd` error code token.
    pub code: String,
    /// Human-readable error message.
    pub message: String,
    /// Optional structured next-step hint, omitted (never `null`) when absent.
    #[serde(skip_serializing_if = "Option::is_none")]
    pub hint: Option<String>,
}

/// Machine-readable stderr error envelope defined by `error-contract/v1` (`R67`, CLI R7.8).
#[derive(Debug, Clone, PartialEq, Eq, Serialize, Deserialize)]
pub struct ErrorEnvelope {
    /// Nested error object (`{"error": { ... }}`).
    pub error: ErrorBody,
}

impl ErrorEnvelope {
    /// Construct a new [`ErrorEnvelope`] from a stable [`ErrorCode`], message, and optional hint.
    #[must_use]
    pub fn new(code: ErrorCode, message: impl Into<String>, hint: Option<String>) -> Self {
        Self {
            error: ErrorBody {
                code: code.as_str().to_owned(),
                message: message.into(),
                hint,
            },
        }
    }
}
