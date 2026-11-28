//! Call-site-gated stderr progress spinner backed by `indicatif` (`R63` revision 4).

use std::ffi::OsStr;
use std::time::Duration;

use indicatif::{ProgressBar, ProgressDrawTarget, ProgressStyle};

/// Three-clause spinner suppression predicate (`R63` revision 4 / CLI Design Standard R7.4).
///
/// Progress renders ONLY when:
/// 1. `stderr` is attached to an interactive terminal, AND
/// 2. `CI` is absent or empty (any non-empty value suppresses), AND
/// 3. `--quiet` is not in effect.
///
/// `--no-input` is deliberately NOT a clause (`R63`).
#[must_use]
pub fn should_show_spinner(stderr_is_tty: bool, ci_env: Option<&OsStr>, quiet: bool) -> bool {
    let ci_set = ci_env.is_some_and(|v| !v.is_empty());
    stderr_is_tty && !ci_set && !quiet
}

/// RAII progress-spinner guard that clears stderr cleanly on both success and error paths (`R63`).
#[derive(Debug)]
pub struct SpinnerGuard {
    bar: Option<ProgressBar>,
}

impl SpinnerGuard {
    /// Start a stderr spinner when `enabled` is true; construct nothing (hidden) otherwise.
    #[must_use]
    pub fn start(message: impl Into<String>, enabled: bool) -> Self {
        Self::start_with_target(message, enabled, ProgressDrawTarget::stderr())
    }

    /// Start a spinner writing to an explicit [`ProgressDrawTarget`] (for `InMemoryTerm` tests).
    #[must_use]
    pub fn start_with_target(
        message: impl Into<String>,
        enabled: bool,
        target: ProgressDrawTarget,
    ) -> Self {
        if !enabled {
            return Self { bar: None };
        }
        let bar = ProgressBar::with_draw_target(None, target);
        if let Ok(style) = ProgressStyle::with_template("{spinner} {msg}") {
            bar.set_style(style);
        }
        bar.set_message(message.into());
        bar.enable_steady_tick(Duration::from_millis(80));
        Self { bar: Some(bar) }
    }

    /// Return `true` when an active visible spinner was constructed.
    #[must_use]
    pub fn is_active(&self) -> bool {
        self.bar.as_ref().is_some_and(|b| !b.is_hidden())
    }

    /// Explicitly stop and clear the spinner line before normal output begins.
    pub fn finish_and_clear(mut self) {
        if let Some(bar) = self.bar.take() {
            bar.finish_and_clear();
        }
    }
}

impl Drop for SpinnerGuard {
    fn drop(&mut self) {
        if let Some(bar) = self.bar.take() {
            bar.finish_and_clear();
        }
    }
}
