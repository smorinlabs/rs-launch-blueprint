//! Clipboard port seam, typed error, shipped test doubles, and `arboard` OS adapter (`R62`,
//! `OV-18`).
//!
//! Lives exclusively in `crates/cli` so `crates/core`, the standalone root library, and
//! `crates/web` never carry desktop clipboard types or link `arboard`. On Linux, probes
//! `Clipboard::new()` in the foreground and re-executes the current binary with
//! `--clipboard-daemon` passing payload bytes via stdin (never argv) so X11/Wayland selection
//! ownership survives CLI exit.

use std::borrow::Cow;
use std::process::ExitCode;
use std::sync::Mutex;

use rs_launch_blueprint::ErrorCode;
use thiserror::Error;

#[cfg(feature = "clipboard")]
const CLIPBOARD_HINT: &str = "rerun without --copy or pipe stdout to your clipboard tool";

/// Failure returned when copying command output to the OS clipboard fails (`R62`, `R67`).
///
/// Maps to [`ErrorCode::Io`] (`RSLB101`, exit `1`) and carries an optional boxed underlying
/// platform error (`#[source]`).
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
    /// Construct a [`ClipboardError::Unavailable`] without an underlying source error.
    #[must_use]
    pub fn unavailable(detail: impl Into<String>, hint: Option<String>) -> Self {
        Self::Unavailable {
            detail: detail.into(),
            hint,
            source: None,
        }
    }

    /// Construct a [`ClipboardError::Unavailable`] wrapping a platform backend error.
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

/// Production [`ClipboardPort`] backed by `arboard` when the `clipboard` feature is enabled.
#[derive(Debug, Default, Clone, Copy)]
pub struct ArboardClipboard;

impl ArboardClipboard {
    /// Construct a new [`ArboardClipboard`].
    #[must_use]
    pub const fn new() -> Self {
        Self
    }
}

#[cfg(all(feature = "clipboard", target_os = "linux"))]
impl ClipboardPort for ArboardClipboard {
    fn set_text(&self, text: &str) -> Result<(), ClipboardError> {
        use std::io::Write;
        use std::process::{Command, Stdio};

        // R62 Member 3: probe clipboard access in the foreground first; fail fast on headless Linux.
        let probe = arboard::Clipboard::new().map_err(|err| {
            ClipboardError::with_source(
                "unable to connect to Linux display server clipboard",
                Some(CLIPBOARD_HINT.to_owned()),
                Box::new(err),
            )
        })?;
        drop(probe);

        let exe = std::env::current_exe().map_err(|err| {
            ClipboardError::with_source(
                "unable to locate current executable for Linux clipboard helper",
                Some(CLIPBOARD_HINT.to_owned()),
                Box::new(err),
            )
        })?;

        let mut child = Command::new(exe)
            .arg("--clipboard-daemon")
            .stdin(Stdio::piped())
            .stdout(Stdio::null())
            .stderr(Stdio::null())
            .spawn()
            .map_err(|err| {
                ClipboardError::with_source(
                    "failed to spawn Linux clipboard selection helper",
                    Some(CLIPBOARD_HINT.to_owned()),
                    Box::new(err),
                )
            })?;

        if let Some(mut stdin) = child.stdin.take() {
            stdin.write_all(text.as_bytes()).map_err(|err| {
                ClipboardError::with_source(
                    "failed to hand payload to Linux clipboard helper",
                    Some(CLIPBOARD_HINT.to_owned()),
                    Box::new(err),
                )
            })?;
        }
        // Deliberately do NOT wait() in the parent; the helper stays alive until overwritten.
        Ok(())
    }
}

#[cfg(all(feature = "clipboard", not(target_os = "linux")))]
impl ClipboardPort for ArboardClipboard {
    fn set_text(&self, text: &str) -> Result<(), ClipboardError> {
        let mut clipboard = arboard::Clipboard::new().map_err(|err| {
            ClipboardError::with_source(
                "unable to access system clipboard",
                Some(CLIPBOARD_HINT.to_owned()),
                Box::new(err),
            )
        })?;
        clipboard.set_text(text.to_owned()).map_err(|err| {
            ClipboardError::with_source(
                "failed to write text to system clipboard",
                Some(CLIPBOARD_HINT.to_owned()),
                Box::new(err),
            )
        })
    }
}

#[cfg(not(feature = "clipboard"))]
impl ClipboardPort for ArboardClipboard {
    fn set_text(&self, _text: &str) -> Result<(), ClipboardError> {
        Err(ClipboardError::unavailable(
            "clipboard support was disabled at compile time",
            Some(
                "rebuild with the `clipboard` feature or pipe stdout to your clipboard tool"
                    .to_owned(),
            ),
        ))
    }
}

/// Entrypoint for the hidden Linux `--clipboard-daemon` selection-ownership helper (`R62`).
pub fn run_clipboard_daemon() -> ExitCode {
    #[cfg(all(feature = "clipboard", target_os = "linux"))]
    {
        use arboard::SetExtLinux;
        use std::io::Read;

        let mut payload = String::new();
        if std::io::stdin().read_to_string(&mut payload).is_err() {
            return ExitCode::FAILURE;
        }
        let Ok(mut clipboard) = arboard::Clipboard::new() else {
            return ExitCode::FAILURE;
        };
        if clipboard.set().wait().text(payload).is_err() {
            return ExitCode::FAILURE;
        }
        ExitCode::SUCCESS
    }
    #[cfg(not(all(feature = "clipboard", target_os = "linux")))]
    {
        ExitCode::SUCCESS
    }
}
