//! Interactive prompts behind the template-owned [`Prompter`] seam (`R61`, `OV-02`).
//!
//! This is the ONLY file in the workspace that imports `inquire`. Every prompt uses
//! `.prompt_skippable()` so ESC returns `Ok(None)`, and explicit `RenderConfig` so R65's
//! resolved color policy governs prompts rather than `inquire`'s narrower `NO_COLOR`-only check.

use std::collections::VecDeque;
use std::io::{self, IsTerminal};
use std::sync::Mutex;
use std::sync::atomic::{AtomicBool, Ordering};

use inquire::error::InquireError;
use inquire::ui::RenderConfig;
use inquire::{Confirm, MultiSelect, Select, Text};
use rs_launch_blueprint::{DomainError, PortError};

/// Single call-site interactivity gate evaluated BEFORE any prompt type is constructed (`R61`).
#[must_use]
pub const fn is_interactive(no_input: bool, stdin_is_tty: bool, stderr_is_tty: bool) -> bool {
    !no_input && stdin_is_tty && stderr_is_tty
}

/// Typed prompt failure mapped onto `R67`'s published catalog by callers (`R61`).
#[derive(Debug)]
pub enum PromptError {
    /// Raw mode refused / terminal unavailable (defence in depth behind [`is_interactive`]).
    NotTty,
    /// User pressed Ctrl-C during a prompt (`RSLB903` -> exit `130`).
    Interrupted,
    /// Underlying terminal I/O failure (`RSLB101` -> exit `1`).
    Io(io::Error),
    /// Prompt configuration or internal failure (`RSLB000` -> exit `1`).
    Unexpected(String),
}

impl PromptError {
    /// Convert a non-interrupt [`PromptError`] on a consent or required-value prompt into a
    /// [`DomainError`]; `Ok(None)` signals [`PromptError::Interrupted`] (`RSLB903`, exit `130`).
    pub fn into_required_domain_error(
        self,
        missing_hint: &str,
    ) -> Result<Option<DomainError>, String> {
        match self {
            Self::NotTty => Ok(Some(DomainError::InputUnavailable {
                message: "interactive prompt unavailable (no TTY)".to_owned(),
                hint: Some(missing_hint.to_owned()),
            })),
            Self::Interrupted => Ok(None),
            Self::Io(source) => Ok(Some(DomainError::Port(PortError::Io { source }))),
            Self::Unexpected(detail) => Err(detail),
        }
    }
}

/// Interactive prompt abstraction keeping `inquire` behind a one-file seam (`R61`).
pub trait Prompter: Send + Sync {
    /// Update resolved stderr color enablement once configuration has loaded (`R61`, `R65`).
    fn set_color(&self, _enabled: bool) {}

    /// Yes/no confirmation prompt (F276). `Ok(None)` indicates ESC cancellation.
    fn confirm(&self, message: &str, default: bool) -> Result<Option<bool>, PromptError>;

    /// Free-text value prompt (F279). `Ok(None)` indicates ESC cancellation.
    fn text(&self, message: &str, default: Option<&str>) -> Result<Option<String>, PromptError>;

    /// Single-choice selection prompt over a closed list (F279). `Ok(None)` indicates ESC.
    fn select(
        &self,
        message: &str,
        options: &[&str],
        default_index: usize,
    ) -> Result<Option<String>, PromptError>;

    /// Multi-select prompt returning zero-based selected indices (F280). `Ok(None)` indicates ESC.
    fn multi_select(
        &self,
        message: &str,
        options: &[String],
    ) -> Result<Option<Vec<usize>>, PromptError>;
}

/// Production [`Prompter`] backed by `inquire` 0.9.4 with R65 color control (`R61`).
#[derive(Debug)]
pub struct InquirePrompter {
    stderr_color: AtomicBool,
}

impl InquirePrompter {
    /// Construct an [`InquirePrompter`] honoring R65's resolved stderr color decision.
    #[must_use]
    pub const fn new(stderr_color: bool) -> Self {
        Self {
            stderr_color: AtomicBool::new(stderr_color),
        }
    }

    fn render_config(&self) -> RenderConfig<'static> {
        if self.stderr_color.load(Ordering::Relaxed) {
            RenderConfig::default_colored()
        } else {
            RenderConfig::empty()
        }
    }
}

fn map_inquire_err<T>(res: Result<Option<T>, InquireError>) -> Result<Option<T>, PromptError> {
    match res {
        Ok(val) => Ok(val),
        // Exhaustive safety net (R61): OperationCanceled matches prompt_skippable's Ok(None).
        Err(InquireError::OperationCanceled) => Ok(None),
        Err(InquireError::OperationInterrupted) => Err(PromptError::Interrupted),
        Err(InquireError::NotTTY) => Err(PromptError::NotTty),
        Err(InquireError::IO(err)) => Err(PromptError::Io(err)),
        Err(InquireError::InvalidConfiguration(msg)) => Err(PromptError::Unexpected(msg)),
        Err(InquireError::Custom(err)) => Err(PromptError::Unexpected(err.to_string())),
    }
}

fn ensure_tty() -> Result<(), PromptError> {
    if !io::stdin().is_terminal() || !io::stderr().is_terminal() {
        return Err(PromptError::NotTty);
    }
    Ok(())
}

impl Prompter for InquirePrompter {
    fn set_color(&self, enabled: bool) {
        self.stderr_color.store(enabled, Ordering::Relaxed);
    }

    fn confirm(&self, message: &str, default: bool) -> Result<Option<bool>, PromptError> {
        ensure_tty()?;
        let prompt = Confirm::new(message)
            .with_default(default)
            .with_render_config(self.render_config());
        map_inquire_err(prompt.prompt_skippable())
    }

    fn text(&self, message: &str, default: Option<&str>) -> Result<Option<String>, PromptError> {
        ensure_tty()?;
        let mut prompt = Text::new(message).with_render_config(self.render_config());
        if let Some(def) = default {
            prompt = prompt.with_default(def);
        }
        map_inquire_err(prompt.prompt_skippable())
    }

    fn select(
        &self,
        message: &str,
        options: &[&str],
        default_index: usize,
    ) -> Result<Option<String>, PromptError> {
        ensure_tty()?;
        let owned: Vec<String> = options.iter().map(|s| (*s).to_owned()).collect();
        let cursor = default_index.min(owned.len().saturating_sub(1));
        let prompt = Select::new(message, owned)
            .with_starting_cursor(cursor)
            .with_render_config(self.render_config());
        map_inquire_err(prompt.prompt_skippable())
    }

    fn multi_select(
        &self,
        message: &str,
        options: &[String],
    ) -> Result<Option<Vec<usize>>, PromptError> {
        ensure_tty()?;
        let prompt =
            MultiSelect::new(message, options.to_vec()).with_render_config(self.render_config());
        match prompt.raw_prompt_skippable() {
            Ok(Some(selected)) => Ok(Some(selected.into_iter().map(|opt| opt.index).collect())),
            other => map_inquire_err(other.map(|_| None)),
        }
    }
}

/// Scripted answer entry for [`ScriptedPrompter`] (`R61`).
#[derive(Debug)]
pub enum ScriptedAnswer {
    /// Answer for `confirm`.
    Confirm(Result<Option<bool>, PromptError>),
    /// Answer for `text`.
    Text(Result<Option<String>, PromptError>),
    /// Answer for `select`.
    Select(Result<Option<String>, PromptError>),
    /// Answer for `multi_select`.
    MultiSelect(Result<Option<Vec<usize>>, PromptError>),
}

/// Deterministic test double for [`Prompter`] requiring no terminal (`R61`).
///
/// Panics if a prompt is invoked when its queue is empty (or when configured with
/// [`ScriptedPrompter::forbid_all`]), discharging R61 revision 6's CI gate criteria.
#[derive(Debug, Default)]
pub struct ScriptedPrompter {
    queue: Mutex<VecDeque<ScriptedAnswer>>,
    forbid_calls: bool,
}

impl ScriptedPrompter {
    /// Construct a [`ScriptedPrompter`] pre-loaded with scripted answers.
    #[must_use]
    pub fn new(answers: impl IntoIterator<Item = ScriptedAnswer>) -> Self {
        Self {
            queue: Mutex::new(answers.into_iter().collect()),
            forbid_calls: false,
        }
    }

    /// Construct a [`ScriptedPrompter`] that panics immediately if any prompt method is called.
    #[must_use]
    pub fn forbid_all() -> Self {
        Self {
            queue: Mutex::new(VecDeque::new()),
            forbid_calls: true,
        }
    }

    fn pop(&self, expected: &str) -> ScriptedAnswer {
        assert!(
            !self.forbid_calls,
            "prompt method `{expected}` was invoked even though prompting must be gated off"
        );
        self.queue
            .lock()
            .expect("lock scripted prompter")
            .pop_front()
            .unwrap_or_else(|| {
                panic!("ScriptedPrompter exhausted while awaiting `{expected}` answer")
            })
    }
}

impl Prompter for ScriptedPrompter {
    fn confirm(&self, _message: &str, _default: bool) -> Result<Option<bool>, PromptError> {
        match self.pop("confirm") {
            ScriptedAnswer::Confirm(res) => res,
            other => panic!("expected Confirm scripted answer, got {other:?}"),
        }
    }

    fn text(&self, _message: &str, _default: Option<&str>) -> Result<Option<String>, PromptError> {
        match self.pop("text") {
            ScriptedAnswer::Text(res) => res,
            other => panic!("expected Text scripted answer, got {other:?}"),
        }
    }

    fn select(
        &self,
        _message: &str,
        _options: &[&str],
        _default_index: usize,
    ) -> Result<Option<String>, PromptError> {
        match self.pop("select") {
            ScriptedAnswer::Select(res) => res,
            other => panic!("expected Select scripted answer, got {other:?}"),
        }
    }

    fn multi_select(
        &self,
        _message: &str,
        _options: &[String],
    ) -> Result<Option<Vec<usize>>, PromptError> {
        match self.pop("multi_select") {
            ScriptedAnswer::MultiSelect(res) => res,
            other => panic!("expected MultiSelect scripted answer, got {other:?}"),
        }
    }
}

#[cfg(test)]
mod tests {
    use std::io;

    use inquire::error::InquireError;

    use super::{
        InquirePrompter, PromptError, Prompter, ScriptedAnswer, ScriptedPrompter, map_inquire_err,
    };

    #[test]
    fn map_inquire_err_covers_every_variant_and_scripted_text() {
        assert!(matches!(
            map_inquire_err::<bool>(Ok(Some(true))),
            Ok(Some(true))
        ));
        assert!(matches!(map_inquire_err::<bool>(Ok(None)), Ok(None)));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::OperationCanceled)),
            Ok(None)
        ));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::OperationInterrupted)),
            Err(PromptError::Interrupted)
        ));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::NotTTY)),
            Err(PromptError::NotTty)
        ));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::IO(io::Error::other("io")))),
            Err(PromptError::Io(_))
        ));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::InvalidConfiguration("cfg".to_owned()))),
            Err(PromptError::Unexpected(_))
        ));
        assert!(matches!(
            map_inquire_err::<bool>(Err(InquireError::Custom("custom".into()))),
            Err(PromptError::Unexpected(_))
        ));

        let scripted = ScriptedPrompter::new([ScriptedAnswer::Text(Ok(Some("hi".to_owned())))]);
        scripted.set_color(true);
        assert_eq!(
            scripted.text("Name", Some("def")).unwrap(),
            Some("hi".to_owned())
        );

        let prompter = InquirePrompter::new(false);
        let _ = prompter.render_config();
        prompter.set_color(true);
        let _ = prompter.render_config();
        // Defence-in-depth non-TTY guard fails fast without opening /dev/tty.
        if !std::io::IsTerminal::is_terminal(&io::stdin())
            || !std::io::IsTerminal::is_terminal(&io::stderr())
        {
            assert!(matches!(
                prompter.confirm("Proceed?", false),
                Err(PromptError::NotTty)
            ));
            assert!(matches!(
                prompter.text("Value", Some("d")),
                Err(PromptError::NotTty)
            ));
            assert!(matches!(
                prompter.select("Pick", &["a", "b"], 0),
                Err(PromptError::NotTty)
            ));
            assert!(matches!(
                prompter.multi_select("Pick many", &["a".to_owned()]),
                Err(PromptError::NotTty)
            ));
        }
    }
}
