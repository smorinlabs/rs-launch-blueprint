//! Single-source `clap` derive CLI grammar, global flags, and shell completion generator (`R60`).

use std::ffi::OsString;
use std::io::{self, Write};
use std::num::NonZeroU32;
use std::path::PathBuf;

use clap::error::ErrorKind;
use clap::parser::ValueSource;
use clap::{ArgAction, Args, CommandFactory, FromArgMatches, Parser, Subcommand, ValueEnum};
use clap_complete::Shell;
use rs_launch_blueprint_core::{ColorPreference, LogLevel, OutputFormat};
use serde::Serialize;

/// Static build metadata embedded at compile time by `build.rs` (`R60` F267).
#[derive(Debug, Clone, Copy, PartialEq, Eq, Serialize)]
pub struct BuildInfo {
    /// Crate SemVer version without leading `v` (`R22`, `R60` AC2).
    pub version: &'static str,
    /// Cargo compilation target triple (`TARGET`).
    pub target: &'static str,
    /// Compiler release string from `$RUSTC -vV`.
    pub rustc: &'static str,
}

/// Return compile-time build metadata for this `rslbp` binary.
#[must_use]
pub const fn build_info() -> BuildInfo {
    BuildInfo {
        version: env!("CARGO_PKG_VERSION"),
        target: env!("RSLBP_BUILD_TARGET"),
        rustc: env!("RSLBP_BUILD_RUSTC"),
    }
}

/// Curated list of `(arg_id, env_var)` pairs permitted on [`Cli::command`] (`R60` AC5 / R5.4).
pub const CURATED_ENV_VARS: &[(&str, &str)] = &[
    ("output", "RSLBP_OUTPUT"),
    ("log_level", "RSLBP_LOG_LEVEL"),
    ("log_format", "RSLBP_LOG_FORMAT"),
    ("config", "RSLBP_CONFIG"),
];

/// CLI value enum for `-o` / `--output` (`R66`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum OutputFormatArg {
    /// Human-readable aligned table.
    Table,
    /// Machine-readable JSON document.
    Json,
    /// GitHub-Flavored Markdown table.
    Markdown,
    /// Bare identifiers, one per line.
    Name,
}

impl From<OutputFormatArg> for OutputFormat {
    fn from(value: OutputFormatArg) -> Self {
        match value {
            OutputFormatArg::Table => Self::Table,
            OutputFormatArg::Json => Self::Json,
            OutputFormatArg::Markdown => Self::Markdown,
            OutputFormatArg::Name => Self::Name,
        }
    }
}

/// CLI value enum for `--color` (`R65`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum ColorArg {
    /// Enable color automatically when the stream is a terminal.
    Auto,
    /// Force ANSI color sequences even when redirected.
    Always,
    /// Disable ANSI color sequences.
    Never,
}

impl From<ColorArg> for ColorPreference {
    fn from(value: ColorArg) -> Self {
        match value {
            ColorArg::Auto => Self::Auto,
            ColorArg::Always => Self::Always,
            ColorArg::Never => Self::Never,
        }
    }
}

/// CLI value enum for `--log-level` (`R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum LogLevelArg {
    /// Disable diagnostic logging.
    Off,
    /// Errors only.
    Error,
    /// Warnings and errors.
    Warn,
    /// Operational info and above.
    Info,
    /// Debug diagnostics and above.
    Debug,
    /// Trace diagnostics and above.
    Trace,
}

impl From<LogLevelArg> for LogLevel {
    fn from(value: LogLevelArg) -> Self {
        match value {
            LogLevelArg::Off => Self::Off,
            LogLevelArg::Error => Self::Error,
            LogLevelArg::Warn => Self::Warn,
            LogLevelArg::Info => Self::Info,
            LogLevelArg::Debug => Self::Debug,
            LogLevelArg::Trace => Self::Trace,
        }
    }
}

/// CLI value enum for `--log-format` (`R58`).
#[derive(Debug, Clone, Copy, PartialEq, Eq, ValueEnum)]
pub enum LogFormatArg {
    /// Console when stderr is a terminal, JSON otherwise.
    Auto,
    /// Human-readable console lines.
    Console,
    /// Newline-delimited JSON events.
    Json,
}

/// Stackable global flags accepted before or after any subcommand (`R60` F270 / R4.5).
#[derive(Debug, Clone, Default, Args)]
pub struct GlobalArgs {
    /// Print version information and exit.
    #[arg(short = 'V', long = "version", global = true)]
    pub version: bool,

    /// Output format.
    #[arg(
        short = 'o',
        long = "output",
        value_enum,
        env = "RSLBP_OUTPUT",
        global = true
    )]
    pub output: Option<OutputFormatArg>,

    /// Shorthand for `--output json`.
    #[arg(long = "json", global = true)]
    pub json: bool,

    /// Write result output to a file path (`-` selects stdout).
    #[arg(long = "output-file", value_name = "PATH", global = true)]
    pub output_file: Option<PathBuf>,

    /// Refuse to overwrite an existing `--output-file` target.
    #[arg(long = "no-clobber", global = true)]
    pub no_clobber: bool,

    /// Copy rendered output to the system clipboard after writing primary output.
    #[arg(long = "copy", global = true)]
    pub copy: bool,

    /// Disable automatic terminal paging for table output.
    #[arg(long = "no-pager", global = true)]
    pub no_pager: bool,

    /// Never prompt interactively; fail when required input or consent is missing.
    #[arg(long = "no-input", global = true)]
    pub no_input: bool,

    /// Control terminal ANSI color emission.
    #[arg(long = "color", value_enum, global = true)]
    pub color: Option<ColorArg>,

    /// Disable terminal ANSI color emission (alias for `--color never`).
    #[arg(long = "no-color", global = true)]
    pub no_color: bool,

    /// Increase diagnostic log verbosity (`-v` info, `-vv` debug, `-vvv` trace).
    #[arg(short = 'v', long = "verbose", action = ArgAction::Count, global = true)]
    pub verbose: u8,

    /// Suppress progress indicators and non-essential stderr output.
    #[arg(short = 'q', long = "quiet", global = true)]
    pub quiet: bool,

    /// Enable trace-level diagnostics with source file, line, and thread metadata.
    #[arg(long = "debug", global = true)]
    pub debug: bool,

    /// Explicit console diagnostic log level.
    #[arg(long = "log-level", value_enum, env = "RSLBP_LOG_LEVEL", global = true)]
    pub log_level: Option<LogLevelArg>,

    /// Console diagnostic log format.
    #[arg(
        long = "log-format",
        value_enum,
        env = "RSLBP_LOG_FORMAT",
        global = true
    )]
    pub log_format: Option<LogFormatArg>,

    /// Write rotating diagnostic logs to a file (omit value for default XDG state path).
    #[arg(
        long = "log-file",
        value_name = "PATH",
        num_args = 0..=1,
        require_equals = true,
        default_missing_value = "",
        global = true
    )]
    pub log_file: Option<String>,

    /// Path to an explicit TOML configuration file (replaces layered discovery).
    #[arg(
        long = "config",
        value_name = "PATH",
        env = "RSLBP_CONFIG",
        global = true
    )]
    pub config: Option<PathBuf>,

    /// Read API token from a file path (`-` reads from stdin).
    #[arg(long = "token-file", value_name = "PATH", global = true)]
    pub token_file: Option<PathBuf>,
}

/// Top-level `rslbp` command-line interface (`R60`).
#[derive(Debug, Clone, Parser)]
#[command(
    name = "rslbp",
    version = env!("CARGO_PKG_VERSION"),
    about = "Command-line interface for rs-launch-blueprint.",
    long_about = "Command-line interface for rs-launch-blueprint.\n\nCommands follow a noun-verb structure (for example `rslbp project list`). Results are written to stdout; diagnostics, progress, prompts, and errors go to stderr.",
    disable_version_flag = true
)]
pub struct Cli {
    /// Internal hidden Linux clipboard selection-ownership daemon entrypoint (`R62`).
    #[arg(long = "clipboard-daemon", hide = true)]
    pub clipboard_daemon: bool,

    /// Global flags accepted at any command position.
    #[command(flatten)]
    pub global: GlobalArgs,

    /// Subcommand to execute.
    #[command(subcommand)]
    pub command: Option<Command>,
}

/// Top-level `rslbp` subcommands (`R60` AC8, AC9, AC10).
#[derive(Debug, Clone, Subcommand)]
pub enum Command {
    /// Manage project resources.
    #[command(name = "project", alias = "projects")]
    Project(ProjectCommand),

    /// Inspect and edit layered configuration.
    Config(ConfigCommand),

    /// Print version and build metadata.
    Version,

    /// Inspect environment, configuration, and credential readiness.
    #[command(name = "diagnostics", alias = "doctor")]
    Diagnostics {
        /// Emit a redacted diagnostics bundle safe to attach to bug reports.
        #[arg(long)]
        bundle: bool,
    },

    /// Print a shell completion script to stdout.
    Completion {
        /// Target shell (`bash`, `zsh`, `fish`, `elvish`, `powershell`).
        #[arg(value_enum)]
        shell: Shell,
    },
}

/// `rslbp project` subcommand group.
#[derive(Debug, Clone, Args)]
pub struct ProjectCommand {
    /// Action to perform on project resources.
    #[command(subcommand)]
    pub action: ProjectAction,
}

/// Verbs under `rslbp project`.
#[derive(Debug, Clone, Subcommand)]
pub enum ProjectAction {
    /// List project records, optionally filtered by workspace.
    List {
        /// Filter records by workspace name.
        #[arg(long)]
        workspace: Option<String>,

        /// Maximum number of records to retrieve.
        #[arg(long)]
        limit: Option<NonZeroU32>,

        /// Interactively narrow the fetched records via multi-select when on a TTY.
        #[arg(long)]
        select: bool,
    },

    /// Fetch a single project record by ID.
    Get {
        /// Project identifier.
        id: String,
    },

    /// Create a new project record.
    Create {
        /// Human-readable project name.
        name: String,

        /// Optional workspace owning the new record.
        #[arg(long)]
        workspace: Option<String>,

        /// Preview the creation without calling the remote API.
        #[arg(long)]
        dry_run: bool,
    },

    /// Delete a project record by ID.
    Delete {
        /// Project identifier to delete.
        id: String,

        /// Preview deletion without calling the remote API.
        #[arg(long)]
        dry_run: bool,

        /// Confirm deletion non-interactively without prompting.
        #[arg(short = 'y', long)]
        yes: bool,
    },
}

/// `rslbp config` subcommand group.
#[derive(Debug, Clone, Args)]
pub struct ConfigCommand {
    /// Action to perform on configuration.
    #[command(subcommand)]
    pub action: ConfigAction,
}

/// Verbs under `rslbp config`.
#[derive(Debug, Clone, Subcommand)]
pub enum ConfigAction {
    /// Show the effective merged configuration and contributing sources.
    Show,

    /// Show one resolved configuration key and its provenance.
    Get {
        /// Dotted configuration key (or `token` for masked credential status).
        key: String,
    },

    /// Write a non-secret configuration value while preserving TOML comments.
    Set {
        /// Dotted configuration key (for example `output.format`).
        key: String,

        /// Value to assign.
        value: String,

        /// Preview the write without touching disk.
        #[arg(long)]
        dry_run: bool,

        /// Overwrite an existing value without confirmation prompt.
        #[arg(short = 'y', long)]
        yes: bool,
    },

    /// Show the active configuration file path and whether it exists.
    Path,

    /// Create or update the configuration file via guided prompts.
    Init {
        /// Preview the configuration changes without writing to disk.
        #[arg(long)]
        dry_run: bool,

        /// Accept the currently resolved defaults without prompting.
        #[arg(short = 'y', long)]
        yes: bool,
    },
}

/// Successful parse result carrying CLI values plus explicit-flag provenance (`R66`).
#[derive(Debug, Clone)]
pub struct ParsedCli {
    /// Parsed command-line arguments.
    pub cli: Cli,
    /// `true` when `-o`/`--output` was supplied explicitly on the command line (not env).
    pub output_flag_explicit: bool,
    /// `true` when `--color` was supplied explicitly on the command line.
    pub color_flag_explicit: bool,
    /// `true` when `--config` was supplied explicitly on the command line (not `RSLBP_CONFIG`).
    pub config_flag_explicit: bool,
    /// `true` when `--log-level` was supplied explicitly on the command line (not `RSLBP_LOG_LEVEL`).
    pub log_level_flag_explicit: bool,
}

/// Non-command parse outcomes handled before command execution (`R60` AC7).
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ParseShortCircuit {
    /// `-h`/`--help` requested; print rendered help text to stdout and exit `0`.
    DisplayHelp(String),
    /// Parse or usage failure; emit `RSLB201` on stderr and exit `2`.
    UsageError {
        /// Rendered diagnostic message (without leading `error: ` duplication).
        message: String,
        /// Optional remediation hint.
        hint: Option<String>,
        /// Output format requested in raw argv (for machine vs human error envelope).
        error_format: OutputFormat,
    },
}

/// Parse `argv` (including `argv[0]`) with `clap::Command::try_get_matches_from` (`R60`).
pub fn parse_cli(argv: &[OsString]) -> Result<ParsedCli, ParseShortCircuit> {
    let cmd = Cli::command();
    match cmd.try_get_matches_from(argv) {
        Ok(matches) => {
            let output_flag_explicit =
                matches.value_source("output") == Some(ValueSource::CommandLine);
            let color_flag_explicit =
                matches.value_source("color") == Some(ValueSource::CommandLine);
            let config_flag_explicit =
                matches.value_source("config") == Some(ValueSource::CommandLine);
            let log_level_flag_explicit =
                matches.value_source("log_level") == Some(ValueSource::CommandLine);
            let cli =
                Cli::from_arg_matches(&matches).map_err(|err| ParseShortCircuit::UsageError {
                    message: clean_clap_message(&err.render().to_string()),
                    hint: Some("run `rslbp --help` for usage".to_owned()),
                    error_format: sniff_format_from_argv(argv),
                })?;
            Ok(ParsedCli {
                cli,
                output_flag_explicit,
                color_flag_explicit,
                config_flag_explicit,
                log_level_flag_explicit,
            })
        }
        Err(err) => match err.kind() {
            ErrorKind::DisplayHelp => Err(ParseShortCircuit::DisplayHelp(err.render().to_string())),
            _ => Err(ParseShortCircuit::UsageError {
                message: clean_clap_message(&err.render().to_string()),
                hint: Some("run `rslbp --help` for usage".to_owned()),
                error_format: sniff_format_from_argv(argv),
            }),
        },
    }
}

/// Render the conformant single-line `rslbp <semver>\n` version output via clap (`R60` F267).
#[must_use]
pub fn render_version_line() -> String {
    Cli::command().render_version()
}

/// Generate a shell completion script for `shell` into `out` (`R60` F268).
pub fn generate_completion(shell: Shell, out: &mut dyn Write) -> io::Result<()> {
    let mut cmd = Cli::command();
    let mut buf = Vec::new();
    clap_complete::aot::generate(shell, &mut cmd, "rslbp", &mut buf);
    out.write_all(&buf)
}

fn clean_clap_message(rendered: &str) -> String {
    let trimmed = rendered.trim();
    trimmed
        .strip_prefix("error: ")
        .unwrap_or(trimmed)
        .to_owned()
}

/// Best-effort raw-argv format sniffer used only when clap fails before matching (`R66` AC14).
fn sniff_format_from_argv(argv: &[OsString]) -> OutputFormat {
    let mut iter = argv.iter().skip(1).map(|s| s.to_string_lossy());
    while let Some(arg) = iter.next() {
        if arg == "--json" {
            return OutputFormat::Json;
        }
        if let Some(val) = arg
            .strip_prefix("--output=")
            .or_else(|| arg.strip_prefix("-o="))
        {
            return parse_format_token(val);
        }
        if (arg == "-o" || arg == "--output")
            && let Some(val) = iter.next()
        {
            return parse_format_token(&val);
        }
    }
    OutputFormat::Table
}

fn parse_format_token(token: &str) -> OutputFormat {
    match token.trim().to_ascii_lowercase().as_str() {
        "json" => OutputFormat::Json,
        "name" => OutputFormat::Name,
        "markdown" => OutputFormat::Markdown,
        _ => OutputFormat::Table,
    }
}
