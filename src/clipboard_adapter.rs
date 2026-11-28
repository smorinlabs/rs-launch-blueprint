//! Production OS clipboard adapter backed by `arboard` (`R62` Members 1 & 3).
//!
//! Lives in the root binary package behind the default-on `clipboard` feature so `crates/core`
//! and `crates/web` never link desktop clipboard crates. On Linux, probes `Clipboard::new()` in
//! the foreground and re-executes the current binary with `--clipboard-daemon` passing payload
//! bytes via stdin (never argv) so X11/Wayland selection ownership survives CLI exit.

use std::process::ExitCode;

use rs_launch_blueprint_core::{ClipboardError, ClipboardPort};

#[cfg(feature = "clipboard")]
const CLIPBOARD_HINT: &str = "rerun without --copy or pipe stdout to your clipboard tool";

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
