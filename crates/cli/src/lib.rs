//! CLI binary crate and terminal front end for `rs-launch-blueprint` (`R60`–`R67`, `R85`,
//! `OV-18`).
//!
//! Depends on the standalone library crate `rs-launch-blueprint` and never on `crates/web`.
//! Direct `println!`/`print!` macros are lint-denied so every stdout/stderr write passes through
//! fallible locked handles (`R67`).
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::app::run;
//! let _ = run;
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::telemetry::JsonEvent;
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::clipboard::ArboardClipboard;
//! ```
//!
//! ```compile_fail,E0603
//! use rs_launch_blueprint_cli::crash_sink::FileCrashSink;
//! ```

#![deny(clippy::print_stdout, clippy::print_stderr)]

mod app;
mod args;
mod clipboard;
mod color;
mod crash_sink;
mod exit;
mod output;
mod pager;
mod prompter;
mod rich;
mod spinner;
mod telemetry;

pub use app::{
    CliError, CliRuntime, PortFactory, ResolvedTelemetryConfig, TelemetryHook, TerminalState,
    emit_cli_error, execute_cli, is_clipboard_daemon_argv, run, sniff_initial_log_settings,
};
pub use args::{
    BuildInfo, CURATED_ENV_VARS, Cli, ColorArg, Command, ConfigAction, ConfigCommand, GlobalArgs,
    LogFormatArg, LogLevelArg, OutputFormatArg, ParseShortCircuit, ParsedCli, ProjectAction,
    ProjectCommand, build_info, generate_completion, parse_cli, render_version_line,
};
pub use clipboard::{
    ArboardClipboard, ClipboardError, ClipboardPort, FailingClipboard, RecordingClipboard,
    run_clipboard_daemon,
};
pub use color::{EnvLookup, MapEnv, ProcessEnv, resolve_color, resolve_stream_color};
pub use crash_sink::{
    CrashRecord, CrashSink, FileCrashSink, NoopCrashSink, resolve_binary_boundary,
};
pub use exit::{Exit, cli_hint_for_domain_error};
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
pub use telemetry::{
    CliTelemetryProfile, HumanFields, JsonEvent, JsonFields, LevelLadderInput, LogFormat, REDACTED,
    ROTATE_BACKUP_COUNT, ROTATE_MAX_BYTES, ResolvedLogFormat, RotatingFile, SENSITIVE_KEY_PARTS,
    TelemetryHandles, TelemetryInit, build_scoped_subscriber, init_telemetry, is_sensitive_key,
    level_to_env_filter, level_to_filter, resolve_console_level, resolve_log_file,
    resolve_log_format,
};
