//! Clipboard port seam, typed error, and shipped test doubles (`R62` Member 2).
//!
//! Keeps platform clipboard crates (`arboard`) completely out of `crates/core`
//! while letting CLI commands and tests inject fakes without a display server.

use std::borrow::Cow;
use std::sync::Mutex;

use thiserror::Error;

use crate::error::ErrorCode;

/// Failure returned when copying command output to the OS clipboard fails (`R62`, `R67`).
///
/// Maps to [`ErrorCode::Io`] (`RSLB101`, exit `1`) and carries an optional boxed underlying
/// platform error (`#[source]`) without leaking desktop crate types into `crates/core`.
#[non_exhaustive]
#[derive(Debug, Error)]
pub enum ClipboardError {
    /// No usable OS clipboard is available (e.g. headless Linux, disabled feature, backend error).
    #[error("clipboard unavailable: {detail}")]
    Unavailable {
        /// Human-readable summary suitable for the error envelope.
        detail: String,
        /// Optional concrete remediation hint.
        hint: Option<String>,
        /// Optional underlying platform/backend error.
        #[source]
        source: Option<Box<dyn std::error::Error + Send + Sync + 'static>>,
    },
}

impl ClipboardError {
    /// Construct an [`ClipboardError::Unavailable`] without an underlying source error.
    #[must_use]
    pub fn unavailable(detail: impl Into<String>, hint: Option<String>) -> Self {
        Self::Unavailable {
            detail: detail.into(),
            hint,
            source: None,
        }
    }

    /// Construct an [`ClipboardError::Unavailable`] wrapping a platform backend error.
    #[must_use]
    pub fn with_source(
        detail: impl Into<String>,
        hint: Option<String>,
        source: Box<dyn std::error::Error + Send + Sync + 'static>,
    ) -> Self {
        Self::Unavailable {
            detail: detail.into(),
            hint,
            source: Some(source),
        }
    }

    /// Stable [`ErrorCode`] (`RSLB101`, exit `1` per `R62`).
    #[must_use]
    pub const fn error_code(&self) -> ErrorCode {
        match self {
            Self::Unavailable { .. } => ErrorCode::Io,
        }
    }

    /// Optional actionable hint.
    #[must_use]
    pub fn hint(&self) -> Option<Cow<'_, str>> {
        match self {
            Self::Unavailable { hint, .. } => hint.as_deref().map(Cow::Borrowed),
        }
    }
}

/// Driven-I/O port for writing textual command output to the system clipboard (`R62`).
pub trait ClipboardPort: Send + Sync {
    /// Copy `text` to the system clipboard.
    fn set_text(&self, text: &str) -> Result<(), ClipboardError>;
}

/// Shipped test double recording every payload written via [`ClipboardPort::set_text`] (`R62`).
#[derive(Debug, Default)]
pub struct RecordingClipboard {
    copied: Mutex<Vec<String>>,
}

impl RecordingClipboard {
    /// Construct an empty [`RecordingClipboard`].
    #[must_use]
    pub fn new() -> Self {
        Self::default()
    }

    /// Return a snapshot of every payload written so far, in call order.
    #[must_use]
    pub fn copied(&self) -> Vec<String> {
        self.copied
            .lock()
            .map(|guard| guard.clone())
            .unwrap_or_default()
    }
}

impl ClipboardPort for RecordingClipboard {
    fn set_text(&self, text: &str) -> Result<(), ClipboardError> {
        let mut guard = self
            .copied
            .lock()
            .map_err(|_| ClipboardError::unavailable("recording clipboard mutex poisoned", None))?;
        guard.push(text.to_owned());
        Ok(())
    }
}

/// Shipped test double that always fails with [`ClipboardError::Unavailable`] (`R62`).
#[derive(Debug, Clone)]
pub struct FailingClipboard {
    detail: String,
    hint: Option<String>,
}

impl FailingClipboard {
    /// Construct a [`FailingClipboard`] emitting `detail` and optional `hint`.
    #[must_use]
    pub fn new(detail: impl Into<String>, hint: Option<String>) -> Self {
        Self {
            detail: detail.into(),
            hint,
        }
    }
}

impl Default for FailingClipboard {
    fn default() -> Self {
        Self::new(
            "no display server or clipboard backend available",
            Some("rerun without --copy or pipe stdout to your clipboard tool".to_owned()),
        )
    }
}

impl ClipboardPort for FailingClipboard {
    fn set_text(&self, _text: &str) -> Result<(), ClipboardError> {
        Err(ClipboardError::unavailable(
            self.detail.clone(),
            self.hint.clone(),
        ))
    }
}
