//! CLI front-end crate for `rs-launch-blueprint` (`R60`–`R67`, `R85`).
//!
//! Depends strictly on `rs-launch-blueprint-core` (`R02`). Direct `println!`/`print!` macros
//! are lint-denied so every stdout/stderr write passes through fallible locked handles (`R67`).
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::app::run;
//! let _ = run;
//! ```

#![deny(clippy::print_stdout, clippy::print_stderr)]

mod app;
mod args;
mod color;
mod output;
mod pager;
mod prompter;
mod rich;
mod spinner;

pub use app::{
    CliError, CliRuntime, PortFactory, ResolvedTelemetryConfig, TelemetryHook, TerminalState,
    emit_cli_error, execute_cli, is_clipboard_daemon_argv, run, sniff_initial_log_settings,
};
pub use args::{
    BuildInfo, CURATED_ENV_VARS, Cli, ColorArg, Command, ConfigAction, ConfigCommand, GlobalArgs,
    LogFormatArg, LogLevelArg, OutputFormatArg, ParseShortCircuit, ParsedCli, ProjectAction,
    ProjectCommand, build_info, generate_completion, parse_cli, render_version_line,
};
pub use color::{EnvLookup, MapEnv, ProcessEnv, resolve_color, resolve_stream_color};
pub use output::{
    CliView, ConfigPathView, ConfigShowView, ConfigValueView, DiagnosticCheck,
    DiagnosticsBundleView, DiagnosticsReportView, ProjectDeletedView, ProjectListView, VersionView,
    escape_markdown_cell, is_machine_format, render_error, render_version, render_view,
    resolve_output_format, write_output_file_atomic,
};
pub use pager::{DEFAULT_PAGER, PagerWriter, resolve_pager_argv};
pub use prompter::{
    InquirePrompter, PromptError, Prompter, ScriptedAnswer, ScriptedPrompter, is_interactive,
};
pub use rich::{
    TermCaps, escape_label, format_file_link, format_osc8_link, relative_time, sanitize_url,
};
pub use spinner::{SpinnerGuard, should_show_spinner};
