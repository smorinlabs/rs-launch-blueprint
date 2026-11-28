//! POSIX process exit-code taxonomy and CLI-specific error hints (`R67`, `OV-18`).
//!
//! Kept in `crates/cli` so `crates/core` and the standalone root library remain free of
//! `std::process::ExitCode` and CLI flag names.

use std::borrow::Cow;
use std::process::ExitCode;

use rs_launch_blueprint::{AuthError, ConfigError, DomainError, ErrorCode, PortError};

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

    /// Map a stable [`ErrorCode`] to its POSIX [`Exit`] status (`R67`).
    #[must_use]
    pub const fn from_error_code(code: ErrorCode) -> Self {
        match code {
            ErrorCode::Unexpected
            | ErrorCode::Io
            | ErrorCode::Transport
            | ErrorCode::RemoteApi
            | ErrorCode::ConfigUnreadable => Self::Runtime,
            ErrorCode::Usage
            | ErrorCode::ConfigUnparsable
            | ErrorCode::ConfigInvalid
            | ErrorCode::ProhibitedSecretChannel
            | ErrorCode::InputUnavailable => Self::Usage,
            ErrorCode::NotFound => Self::NotFound,
            ErrorCode::CredentialsAbsent | ErrorCode::CredentialsRejected => Self::Auth,
            ErrorCode::Conflict => Self::Conflict,
            ErrorCode::SigInt | ErrorCode::PromptInterrupted => Self::SigInt,
            ErrorCode::SigTerm => Self::SigTerm,
            _ => Self::Runtime,
        }
    }

    /// Map a [`DomainError`] to its POSIX [`Exit`] status.
    #[must_use]
    pub const fn from_domain_error(error: &DomainError) -> Self {
        Self::from_error_code(error.error_code())
    }
}

impl From<Exit> for ExitCode {
    fn from(value: Exit) -> Self {
        Self::from(value.code())
    }
}

/// Return a CLI-contextualized remediation hint for `error`, enriching transport-neutral library
/// hints with concrete `rslbp` flags where helpful (`OV-18`, `R67`).
#[must_use]
pub fn cli_hint_for_domain_error(error: &DomainError) -> Option<Cow<'_, str>> {
    match error {
        DomainError::Auth(AuthError::CredentialsAbsent { .. }) => Some(Cow::Borrowed(
            "provide a token with --token-file, RSLBP_TOKEN, or a credential store",
        )),
        DomainError::Config(ConfigError::ProhibitedSecretChannel { .. }) => Some(Cow::Borrowed(
            "supply credentials via --token-file, RSLBP_TOKEN, or a credential store",
        )),
        DomainError::Port(PortError::Unauthorized { .. }) => Some(Cow::Borrowed(
            "check RSLBP_TOKEN or refresh the token supplied via --token-file",
        )),
        other => other.hint(),
    }
}
