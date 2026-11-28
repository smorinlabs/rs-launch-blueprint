//! Spawn-and-pipe terminal pager integration with two-tier env precedence (`R64`).
//!
//! Uses `shlex::split` exclusively (never `quote`/`join`), injects `LESS=FRX` and `LV=-c`
//! only when unset in the parent environment, drops the child's stdin handle before calling
//! `child.wait()`, and falls through to stdout on any resolution, tokenization, or spawn failure.

use std::ffi::OsStr;
use std::io::{self, Write};
use std::path::Path;
use std::process::{Child, ChildStdin, Command, Stdio};

use rs_launch_blueprint_core::OutputFormat;

use crate::color::EnvLookup;

/// Built-in default pager command (`-F` quit-if-one-screen, `-R` raw ANSI, `-X` no init/clear).
pub const DEFAULT_PAGER: &str = "less -FRX";

/// Resolve the pager argv from `RSLBP_PAGER` > `PAGER` > [`DEFAULT_PAGER`] (`R64`).
///
/// Returns `None` (no pager spawned) when:
/// - `disabled` is true (`--no-pager`, `--no-input`, or `--output-file` set),
/// - `format` is not `OutputFormat::Table`,
/// - `stdout_is_tty` is false,
/// - the resolved value is empty or exactly `"cat"`, or
/// - `shlex::split` rejects unbalanced quotes.
#[must_use]
pub fn resolve_pager_argv(
    disabled: bool,
    format: OutputFormat,
    stdout_is_tty: bool,
    env: &dyn EnvLookup,
) -> Option<Vec<String>> {
    if disabled || format != OutputFormat::Table || !stdout_is_tty {
        return None;
    }

    let raw = if let Some(val) = env.var_string("RSLBP_PAGER") {
        val
    } else if let Some(val) = env.var_string("PAGER") {
        val
    } else {
        DEFAULT_PAGER.to_owned()
    };

    let trimmed = raw.trim();
    if trimmed.is_empty() || trimmed == "cat" {
        return None;
    }

    let argv = shlex::split(trimmed)?;
    if argv.is_empty()
        || (argv.len() == 1 && Path::new(&argv[0]).file_name() == Some(OsStr::new("cat")))
    {
        return None;
    }
    Some(argv)
}

/// Streaming writer piping rendered table output into a spawned pager child (`R64`).
///
/// On [`Drop`], drops the child's `stdin` handle (sending EOF) BEFORE calling `child.wait()`
/// so the pager never deadlocks waiting for input.
pub struct PagerWriter {
    stdin: Option<ChildStdin>,
    child: Child,
}

impl PagerWriter {
    /// Attempt to spawn the resolved pager argv, returning `None` on any spawn failure so the
    /// caller falls through seamlessly to stdout (`R64` P3 / A8).
    #[must_use]
    pub fn try_spawn(argv: &[String], env: &dyn EnvLookup) -> Option<Self> {
        let (program, args) = argv.split_first()?;
        let mut cmd = Command::new(program);
        cmd.args(args).stdin(Stdio::piped());

        // R64 git PAGER_ENV convention: set LESS=FRX and LV=-c only when unset in parent.
        if env.var_os("LESS").is_none() {
            cmd.env("LESS", "FRX");
        }
        if env.var_os("LV").is_none() {
            cmd.env("LV", "-c");
        }

        let mut child = cmd.spawn().ok()?;
        let stdin = child.stdin.take()?;
        Some(Self {
            stdin: Some(stdin),
            child,
        })
    }

    /// Explicitly close the pipe and wait for the pager child to exit.
    pub fn finish(mut self) {
        drop(self.stdin.take());
        let _ = self.child.wait();
    }
}

impl Write for PagerWriter {
    fn write(&mut self, buf: &[u8]) -> io::Result<usize> {
        match self.stdin.as_mut() {
            Some(stdin) => stdin.write(buf),
            None => Err(io::Error::new(
                io::ErrorKind::BrokenPipe,
                "pager stdin already closed",
            )),
        }
    }

    fn flush(&mut self) -> io::Result<()> {
        match self.stdin.as_mut() {
            Some(stdin) => stdin.flush(),
            None => Ok(()),
        }
    }
}

impl Drop for PagerWriter {
    fn drop(&mut self) {
        // R64 critical lifecycle rule: close write end (EOF) BEFORE waiting on the child.
        drop(self.stdin.take());
        let _ = self.child.wait();
    }
}
