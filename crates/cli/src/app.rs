//! CLI command dispatch, dependency-injected runtime seam, and full `rslbp` command handlers
//! (`R60`–`R67`, `R85`).

use std::collections::BTreeMap;
use std::ffi::OsString;
use std::fmt;
use std::io::{self, Write};
use std::path::{Path, PathBuf};
use std::process::ExitCode;
use std::str::FromStr;
use std::sync::Arc;

use anstream::{AutoStream, ColorChoice};

use rs_launch_blueprint_core::{
    AuthError, ClipboardPort, ColorPreference, ConfigDiscoveryInputs, CreateProjectInput,
    CredentialStore, DiagnosticsContext, DomainError, ErasedProjectsService, ErrorCode, Exit,
    FileCredentialStore, LogLevel, OutputFormat, Paths, PortError, ProjectQuery, ProjectsPort,
    ProjectsService, RecordingClipboard, ResolvedToken, TOKEN_ENV_VAR, Token,
    TokenResolutionInputs, WRITABLE_KEYS, WorkspaceInfo, get_config_value, load_config,
    read_config_file_key, resolve_token, run_diagnostics, set_config_value,
    validate_config_assignment,
};

use crate::args::{
    Cli, Command, ConfigAction, GlobalArgs, ParseShortCircuit, ProjectAction, build_info,
    generate_completion, parse_cli,
};
use crate::color::{EnvLookup, ProcessEnv, resolve_color, resolve_stream_color};
use crate::output::{
    CliView, ConfigPathView, ConfigShowView, ConfigValueView, DiagnosticCheck,
    DiagnosticsBundleView, DiagnosticsReportView, ProjectDeletedView, ProjectListView,
    is_machine_format, render_error, render_version, render_view, resolve_output_format,
    write_output_file_atomic,
};
use crate::pager::{PagerWriter, resolve_pager_argv};
use crate::prompter::{PromptError, Prompter, is_interactive};
use crate::rich::TermCaps;
use crate::spinner::{SpinnerGuard, should_show_spinner};

/// Keys walked by `rslbp config init` in prompt order (`R61` F279).
const INIT_KEYS: &[(&str, &[&str])] = &[
    ("output.format", &["table", "json", "markdown", "name"]),
    ("output.color", &["auto", "always", "never"]),
    (
        "logging.level",
        &["off", "error", "warn", "info", "debug", "trace"],
    ),
];

/// Sensitive env-var substrings redacted in `diagnostics --bundle`.
const SENSITIVE_ENV_MARKERS: &[&str] = &[
    "TOKEN", "SECRET", "KEY", "PASSWORD", "CRED", "PRIVATE", "COOKIE", "AUTH",
];

/// Stream terminal flags injected into [`CliRuntime`] for hermetic testing.
#[derive(Debug, Clone, Copy, Default)]
pub struct TerminalState {
    /// Whether stdin is a TTY.
    pub stdin_is_tty: bool,
    /// Whether stdout is a TTY.
    pub stdout_is_tty: bool,
    /// Whether stderr is a TTY.
    pub stderr_is_tty: bool,
    /// Explicit override for OSC-8 hyperlink support (`None` queries `supports-hyperlinks`).
    pub hyperlinks_override: Option<bool>,
}

/// Callback invoked once configuration and CLI logging flags are parsed so the root binary can
/// reload console log levels or attach the optional rotating file sink (`R58`, `R59`).
pub type TelemetryHook<'a> = dyn FnMut(&ResolvedTelemetryConfig) + 'a;

/// Resolved logging configuration handed from CLI parsing/config load back to root telemetry.
#[derive(Debug, Clone)]
pub struct ResolvedTelemetryConfig {
    /// `--debug` flag.
    pub debug: bool,
    /// Explicit `--log-level` flag.
    pub log_level_flag: Option<LogLevel>,
    /// `-q` / `--quiet` flag.
    pub quiet: bool,
    /// `-v` verbosity count.
    pub verbose: u8,
    /// `RSLBP_LOG_LEVEL` env value.
    pub env_log_level: Option<LogLevel>,
    /// Merged `[logging].level` from config files.
    pub config_log_level: LogLevel,
    /// Explicit `--log-file` flag (`Some(None)` = bare flag -> default path).
    pub log_file_flag: Option<Option<PathBuf>>,
    /// Raw `RSLBP_LOG_FILE` env value.
    pub env_log_file: Option<OsString>,
    /// Merged `[logging].file` from config files.
    pub config_log_file: Option<PathBuf>,
    /// Merged `[logging].file-format`.
    pub file_format: rs_launch_blueprint_core::FileLogFormat,
    /// Merged `[logging].file-level`.
    pub file_level: Option<LogLevel>,
    /// Resolved `Paths` for default state log file location.
    pub paths: Paths,
}

/// Factory producing a [`ProjectsPort`] when a project subcommand actually needs one.
pub type PortFactory<'a> = dyn Fn(Token) -> Arc<dyn ProjectsPort> + 'a;

/// All runtime dependencies injected into [`execute_cli`] (`R01`, `R32`, `R61`–`R67`).
pub struct CliRuntime<'a> {
    /// Environment variable lookup seam.
    pub env: &'a dyn EnvLookup,
    /// Current working directory for project-tier config discovery.
    pub cwd: PathBuf,
    /// Resolved XDG per-user directories (`R57`).
    pub paths: Paths,
    /// Terminal attachment metadata.
    pub terminal: TerminalState,
    /// Optional pre-read stdin token bytes (used for `--token-file -` in tests).
    pub stdin_token: Option<String>,
    /// Optional credential store override (defaults to `FileCredentialStore` under `state_dir`).
    pub credential_store: Option<&'a dyn CredentialStore>,
    /// Optional pre-wired port (used by in-process tests to bypass auth/HTTP).
    pub injected_port: Option<Arc<dyn ProjectsPort>>,
    /// Factory constructing the production HTTP port from a resolved token.
    pub port_factory: Option<&'a PortFactory<'a>>,
    /// Interactive prompt backend (`InquirePrompter` in prod, `ScriptedPrompter` in tests).
    pub prompter: &'a dyn Prompter,
    /// Clipboard backend (`ArboardClipboard` in prod, `RecordingClipboard` in tests).
    pub clipboard: &'a dyn ClipboardPort,
    /// Result output stream (stdout in production, buffer in tests).
    pub stdout: &'a mut dyn Write,
    /// Diagnostic/error stream (stderr in production, buffer in tests).
    pub stderr: &'a mut dyn Write,
    /// Optional hook to reload telemetry subscriber after config load (`R58`, `R59`).
    pub on_telemetry: Option<&'a mut TelemetryHook<'a>>,
    /// Whether spawning a real external pager subprocess is allowed (true in binary, false in buffer tests unless opted in).
    pub allow_spawn_pager: bool,
}

/// Typed CLI failure returned to the root binary boundary (`R67`: no `anyhow` in `crates/cli`).
#[derive(Debug)]
pub enum CliError {
    /// Benign `BrokenPipe` on the result output stream -> exit `0` silently (`R67` AC5).
    BrokenPipe,
    /// Typed domain error carrying its own stable `RSLB###` code and `Exit` status.
    Domain {
        /// Underlying domain error.
        error: DomainError,
        /// Active output format controlling JSON vs human error formatting.
        format: OutputFormat,
        /// Resolved stderr color enablement.
        stderr_color: bool,
    },
    /// Unexpected internal error -> `RSLB000` (exit `1`) + crash record sink (`R67`).
    Unexpected {
        /// Sanitized human-readable message.
        message: String,
        /// Active output format controlling JSON vs human error formatting.
        format: OutputFormat,
        /// Resolved stderr color enablement.
        stderr_color: bool,
        /// Cause chain strings for the crash record sink (never secrets/argv/env).
        causes: Vec<String>,
    },
}

impl fmt::Display for CliError {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::BrokenPipe => f.write_str("broken pipe"),
            Self::Domain { error, .. } => fmt::Display::fmt(error, f),
            Self::Unexpected { message, .. } => f.write_str(message),
        }
    }
}

impl std::error::Error for CliError {
    fn source(&self) -> Option<&(dyn std::error::Error + 'static)> {
        match self {
            Self::Domain { error, .. } => Some(error),
            Self::BrokenPipe | Self::Unexpected { .. } => None,
        }
    }
}

/// Execute `rslbp` against `argv` (including `argv[0]`) using `rt`.
///
/// Never calls `std::process::exit`, never installs signal handlers, and never uses `println!`.
pub fn execute_cli(rt: &mut CliRuntime<'_>, argv: &[OsString]) -> Result<Exit, CliError> {
    let parsed = match parse_cli(argv) {
        Ok(p) => p,
        Err(ParseShortCircuit::DisplayHelp(help)) => {
            return write_result_bytes_gated(rt.stdout, help.as_bytes(), false)
                .map(|()| Exit::Success);
        }
        Err(ParseShortCircuit::UsageError {
            message,
            hint,
            error_format,
        }) => {
            let color_choice = resolve_color(None, ColorPreference::Auto, rt.env);
            let stderr_color =
                resolve_stream_color(color_choice, rt.terminal.stderr_is_tty, rt.env);
            return Err(CliError::Domain {
                error: DomainError::Usage { message, hint },
                format: error_format,
                stderr_color,
            });
        }
    };

    let cli = parsed.cli;
    let global = &cli.global;

    // Validate mutually exclusive color flags early.
    if global.no_color
        && parsed.color_flag_explicit
        && global.color != Some(crate::args::ColorArg::Never)
    {
        let format = if global.json {
            OutputFormat::Json
        } else {
            global.output.map(Into::into).unwrap_or(OutputFormat::Table)
        };
        let stderr_color = resolve_stream_color(
            resolve_color(Some(ColorPreference::Never), ColorPreference::Auto, rt.env),
            rt.terminal.stderr_is_tty,
            rt.env,
        );
        return Err(CliError::Domain {
            error: DomainError::Usage {
                message: "conflicting flags: --no-color cannot be combined with --color".to_owned(),
                hint: Some("use either --no-color or --color <auto|always|never>".to_owned()),
            },
            format,
            stderr_color,
        });
    }

    let flag_color = if global.no_color {
        Some(ColorPreference::Never)
    } else if parsed.color_flag_explicit {
        global.color.map(Into::into)
    } else {
        None
    };

    let explicit_fmt = parsed
        .output_flag_explicit
        .then(|| global.output.map(Into::into))
        .flatten();
    let env_fmt = match parse_env_output_format(rt.env) {
        Ok(fmt) => fmt,
        Err(error) => {
            let color_choice = resolve_color(flag_color, ColorPreference::Auto, rt.env);
            let stderr_color =
                resolve_stream_color(color_choice, rt.terminal.stderr_is_tty, rt.env);
            return Err(CliError::Domain {
                error,
                format: if global.json {
                    OutputFormat::Json
                } else {
                    explicit_fmt.unwrap_or(OutputFormat::Table)
                },
                stderr_color,
            });
        }
    };

    // Fast path for `--version` / `-V` and `version` (R60 AC2, AC3): no config file I/O needed.
    if global.version || matches!(cli.command, Some(Command::Version)) {
        let format =
            match resolve_output_format(explicit_fmt, env_fmt, global.json, OutputFormat::Table) {
                Ok(f) => f,
                Err(error) => {
                    return Err(CliError::Domain {
                        error,
                        format: OutputFormat::Table,
                        stderr_color: false,
                    });
                }
            };
        let mut buf = Vec::new();
        if let Err(err) = render_version(format, &mut buf) {
            return Err(unexpected_io(err, format, false));
        }
        return deliver_output(rt, global, format, TermCaps::plain(), false, &buf);
    }

    // Fast path for `completion <shell>` (R60 AC4): no config file I/O needed.
    if let Some(Command::Completion { shell }) = cli.command {
        let mut buf = Vec::new();
        if let Err(err) = generate_completion(shell, &mut buf) {
            return Err(unexpected_io(err, OutputFormat::Table, false));
        }
        return deliver_output(
            rt,
            global,
            OutputFormat::Table,
            TermCaps::plain(),
            false,
            &buf,
        );
    }

    // Require an explicit subcommand — no default business command (R60 F265).
    let Some(command) = cli.command.clone() else {
        let format = if global.json {
            OutputFormat::Json
        } else {
            explicit_fmt.or(env_fmt).unwrap_or(OutputFormat::Table)
        };
        let color_choice = resolve_color(flag_color, ColorPreference::Auto, rt.env);
        let stderr_color = resolve_stream_color(color_choice, rt.terminal.stderr_is_tty, rt.env);
        return Err(CliError::Domain {
            error: DomainError::Usage {
                message: "a subcommand is required".to_owned(),
                hint: Some("run `rslbp --help` to see available commands".to_owned()),
            },
            format,
            stderr_color,
        });
    };

    let prelim_stderr_color = resolve_stream_color(
        resolve_color(flag_color, ColorPreference::Auto, rt.env),
        rt.terminal.stderr_is_tty,
        rt.env,
    );
    let prelim_format =
        match resolve_output_format(explicit_fmt, env_fmt, global.json, OutputFormat::Table) {
            Ok(f) => f,
            Err(error) => {
                return Err(CliError::Domain {
                    error,
                    format: if global.json {
                        OutputFormat::Json
                    } else {
                        OutputFormat::Table
                    },
                    stderr_color: prelim_stderr_color,
                });
            }
        };

    // Load layered configuration (R54, R55, R56).
    let explicit_flag_cfg = parsed
        .config_flag_explicit
        .then_some(global.config.as_deref())
        .flatten();
    let explicit_env_cfg = rt.env.var_os("RSLBP_CONFIG");
    let xdg_config_dirs = rt.env.var_os("XDG_CONFIG_DIRS");
    let loaded = match load_config(&ConfigDiscoveryInputs {
        explicit_flag: explicit_flag_cfg,
        explicit_env: explicit_env_cfg.as_deref(),
        cwd: &rt.cwd,
        paths: &rt.paths,
        xdg_config_dirs: xdg_config_dirs.as_deref(),
    }) {
        Ok(loaded) => loaded,
        Err(err) => {
            return Err(CliError::Domain {
                error: DomainError::Config(err),
                format: prelim_format,
                stderr_color: prelim_stderr_color,
            });
        }
    };

    let cfg = loaded.config.as_config();

    // Final format & color resolution combining flag > env > config > default.
    let format = match resolve_output_format(explicit_fmt, env_fmt, global.json, cfg.output.format)
    {
        Ok(f) => f,
        Err(error) => {
            return Err(CliError::Domain {
                error,
                format: prelim_format,
                stderr_color: prelim_stderr_color,
            });
        }
    };
    let color_choice = resolve_color(flag_color, cfg.output.color, rt.env);
    let stdout_color = resolve_stream_color(color_choice, rt.terminal.stdout_is_tty, rt.env);
    let stderr_color = resolve_stream_color(color_choice, rt.terminal.stderr_is_tty, rt.env);
    rt.prompter.set_color(stderr_color);
    let hyperlinks = match rt.terminal.hyperlinks_override {
        Some(v) => stdout_color && v,
        None => TermCaps::detect_stdout(stdout_color).hyperlinks,
    };
    let caps = TermCaps {
        color: stdout_color,
        hyperlinks,
    };
    let active_config_path = explicit_flag_cfg
        .map(Path::to_path_buf)
        .or_else(|| {
            explicit_env_cfg
                .as_deref()
                .filter(|s| !s.is_empty())
                .map(PathBuf::from)
        })
        .unwrap_or_else(|| rt.paths.config_file());

    // Notify root telemetry hook so console level and optional file sink activate (R58, R59).
    if let Some(hook) = rt.on_telemetry.as_deref_mut() {
        let log_file_flag = global.log_file.as_deref().map(|raw| {
            if raw.is_empty() {
                None
            } else {
                Some(PathBuf::from(raw))
            }
        });
        let env_log_level = rt
            .env
            .var_string("RSLBP_LOG_LEVEL")
            .and_then(|s| LogLevel::from_str(&s).ok());
        let log_level_flag = parsed
            .log_level_flag_explicit
            .then(|| global.log_level.map(Into::into))
            .flatten();
        hook(&ResolvedTelemetryConfig {
            debug: global.debug,
            log_level_flag,
            quiet: global.quiet,
            verbose: global.verbose,
            env_log_level,
            config_log_level: cfg.logging.level,
            log_file_flag,
            env_log_file: rt.env.var_os("RSLBP_LOG_FILE"),
            config_log_file: cfg.logging.file.clone(),
            file_format: cfg.logging.file_format,
            file_level: cfg.logging.file_level,
            paths: rt.paths.clone(),
        });
    }

    // Surface non-fatal config warnings to stderr (never stdout, suppressed under --quiet).
    if !global.quiet {
        for warning in &loaded.warnings {
            let _ = writeln!(rt.stderr, "warning: {warning}");
        }
    }

    tracing::debug!(
        format = format.as_str(),
        stdout_color,
        stderr_color,
        "executing cli command"
    );

    let ctx = DispatchCtx {
        loaded: &loaded,
        active_config_path: &active_config_path,
        format,
        caps,
        stderr_color,
    };

    match command {
        Command::Project(proj_cmd) => handle_project(rt, &cli, proj_cmd.action, &ctx),
        Command::Config(cfg_cmd) => handle_config(rt, &cli, cfg_cmd.action, &ctx),
        Command::Diagnostics { bundle } => handle_diagnostics(rt, &cli, bundle, &ctx),
        Command::Version | Command::Completion { .. } => Ok(Exit::Success),
    }
}

struct DispatchCtx<'a> {
    loaded: &'a rs_launch_blueprint_core::LoadedConfig,
    active_config_path: &'a Path,
    format: OutputFormat,
    caps: TermCaps,
    stderr_color: bool,
}

fn handle_project(
    rt: &mut CliRuntime<'_>,
    cli: &Cli,
    action: ProjectAction,
    ctx: &DispatchCtx<'_>,
) -> Result<Exit, CliError> {
    let global = &cli.global;
    let loaded = ctx.loaded;
    let format = ctx.format;
    let caps = ctx.caps;
    let stderr_color = ctx.stderr_color;
    let map_domain = |error: DomainError| CliError::Domain {
        error,
        format,
        stderr_color,
    };

    match action {
        ProjectAction::List {
            workspace,
            limit,
            select,
        } => {
            let service = build_service(rt, global).map_err(map_domain)?;
            let effective_limit = limit.or(loaded.config.as_config().output.limit);
            let query = ProjectQuery {
                workspace,
                limit: effective_limit,
            };

            let ci_env = rt.env.var_os("CI");
            let spin_enabled =
                should_show_spinner(rt.terminal.stderr_is_tty, ci_env.as_deref(), global.quiet);
            let spinner = SpinnerGuard::start("Fetching project records...", spin_enabled);
            let mut projects = service.list_projects(&query).map_err(map_domain)?;
            spinner.finish_and_clear();

            // R61 F280 + F360 narrowing rule: prompt only when interactive; otherwise proceed with
            // the complete unnarrowed list.
            if select
                && !projects.is_empty()
                && is_interactive(
                    global.no_input,
                    rt.terminal.stdin_is_tty,
                    rt.terminal.stderr_is_tty,
                )
            {
                let labels: Vec<String> = projects
                    .iter()
                    .map(|p| format!("{} ({})", p.name, p.id))
                    .collect();
                match rt.prompter.multi_select("Select project records:", &labels) {
                    Ok(Some(indices)) if !indices.is_empty() => {
                        projects = indices
                            .into_iter()
                            .filter_map(|idx| projects.get(idx).cloned())
                            .collect();
                    }
                    Ok(None) | Ok(Some(_)) => {
                        if !global.quiet {
                            let _ = writeln!(rt.stderr, "No project entries selected.");
                        }
                        return Ok(Exit::Success);
                    }
                    // Defence-in-depth narrowing fallback (R61 table): NotTty proceeds with all rows.
                    Err(PromptError::NotTty) => {}
                    Err(PromptError::Interrupted) => {
                        return Err(map_domain(DomainError::PromptInterrupted));
                    }
                    Err(PromptError::Io(source)) => {
                        return Err(map_domain(DomainError::Port(PortError::Io { source })));
                    }
                    Err(PromptError::Unexpected(message)) => {
                        return Err(CliError::Unexpected {
                            message,
                            format,
                            stderr_color,
                            causes: Vec::new(),
                        });
                    }
                }
            }

            let view = ProjectListView { projects };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ProjectAction::Get { id } => {
            let service = build_service(rt, global).map_err(map_domain)?;
            let project = service.get_project(&id).map_err(map_domain)?;
            let view = ProjectListView {
                projects: vec![project],
            };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ProjectAction::Create {
            name,
            workspace,
            dry_run,
        } => {
            if name.trim().is_empty() {
                return Err(map_domain(DomainError::Usage {
                    message: "project name must not be empty".to_owned(),
                    hint: Some("provide a non-empty project name".to_owned()),
                }));
            }
            if dry_run {
                if !global.quiet {
                    let _ = writeln!(
                        rt.stderr,
                        "[dry-run] would create project '{}'",
                        name.trim()
                    );
                }
                let preview = rs_launch_blueprint_core::Project {
                    id: "<dry-run>".to_owned(),
                    name: name.trim().to_owned(),
                    workspace,
                };
                let view = ProjectListView {
                    projects: vec![preview],
                };
                return render_and_deliver(rt, global, &view, format, caps, stderr_color);
            }
            let service = build_service(rt, global).map_err(map_domain)?;
            let created = service
                .create_project(&CreateProjectInput { name, workspace })
                .map_err(map_domain)?;
            let view = ProjectListView {
                projects: vec![created],
            };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ProjectAction::Delete { id, dry_run, yes } => {
            if dry_run {
                if !global.quiet {
                    let _ = writeln!(rt.stderr, "[dry-run] would delete project '{id}'");
                }
                let view = ProjectDeletedView { id, dry_run: true };
                return render_and_deliver(rt, global, &view, format, caps, stderr_color);
            }

            if !yes {
                if !is_interactive(
                    global.no_input,
                    rt.terminal.stdin_is_tty,
                    rt.terminal.stderr_is_tty,
                ) {
                    return Err(map_domain(DomainError::InputUnavailable {
                        message: format!("refusing to delete project '{id}' without confirmation"),
                        hint: Some("pass --yes to confirm non-interactively".to_owned()),
                    }));
                }
                match rt
                    .prompter
                    .confirm(&format!("Delete project '{id}'?"), false)
                {
                    Ok(Some(true)) => {}
                    Ok(Some(false)) | Ok(None) => {
                        if !global.quiet {
                            let _ = writeln!(rt.stderr, "Aborted.");
                        }
                        return Ok(Exit::Success);
                    }
                    Err(err) => {
                        return Err(map_prompt_err(
                            err,
                            "pass --yes to confirm non-interactively",
                            format,
                            stderr_color,
                        ));
                    }
                }
            }

            let service = build_service(rt, global).map_err(map_domain)?;
            service.delete_project(&id).map_err(map_domain)?;
            let view = ProjectDeletedView { id, dry_run: false };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
    }
}

fn handle_config(
    rt: &mut CliRuntime<'_>,
    cli: &Cli,
    action: ConfigAction,
    ctx: &DispatchCtx<'_>,
) -> Result<Exit, CliError> {
    let global = &cli.global;
    let loaded = ctx.loaded;
    let format = ctx.format;
    let caps = ctx.caps;
    let stderr_color = ctx.stderr_color;
    let map_domain = |error: DomainError| CliError::Domain {
        error,
        format,
        stderr_color,
    };
    let map_cfg = |err| map_domain(DomainError::Config(err));
    let active_config_path = ctx.active_config_path.to_path_buf();

    match action {
        ConfigAction::Path => {
            let exists = active_config_path.exists();
            let view = ConfigPathView {
                path: active_config_path,
                exists,
            };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ConfigAction::Show => {
            let source_label = if loaded.sources.is_empty() {
                "default"
            } else {
                "config"
            };
            let mut entries = Vec::with_capacity(WRITABLE_KEYS.len());
            for &key in WRITABLE_KEYS {
                let value = get_config_value(&loaded.config, key).map_err(&map_cfg)?;
                entries.push(ConfigValueView {
                    key: key.to_owned(),
                    value,
                    source: source_label.to_owned(),
                });
            }
            let sources = loaded
                .sources
                .iter()
                .map(|s| s.path.display().to_string())
                .collect();
            let view = ConfigShowView { entries, sources };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ConfigAction::Get { key } => {
            if key == "token" {
                let res = resolve_cli_token(rt, global).map_err(map_domain)?;
                let (value, source) = match res {
                    Some(tok) => (Some(tok.token.masked()), tok.source.as_str().to_owned()),
                    None => (None, "none".to_owned()),
                };
                let view = ConfigValueView { key, value, source };
                return render_and_deliver(rt, global, &view, format, caps, stderr_color);
            }
            let value = get_config_value(&loaded.config, &key).map_err(&map_cfg)?;
            let source = if loaded.sources.is_empty() {
                "default"
            } else {
                "config"
            }
            .to_owned();
            let view = ConfigValueView { key, value, source };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ConfigAction::Set {
            key,
            value,
            dry_run,
            yes,
        } => {
            // Validate key & value before any dry-run or prompt using core's rules.
            let canonical = validate_config_assignment(&key, &value).map_err(&map_cfg)?;

            // R61 revision 3: `config set` evaluates `--dry-run` BEFORE overwrite confirmation.
            if dry_run {
                if !global.quiet {
                    let _ = writeln!(
                        rt.stderr,
                        "[dry-run] would set {key} = {canonical} in {}",
                        active_config_path.display()
                    );
                }
                let view = ConfigValueView {
                    key,
                    value: Some(canonical),
                    source: "dry-run".to_owned(),
                };
                return render_and_deliver(rt, global, &view, format, caps, stderr_color);
            }

            // Check whether the target file already holds a different value for `key`.
            let existing = read_config_file_key(&active_config_path, &key).map_err(&map_cfg)?;
            if let Some(prev) = existing
                && prev != canonical
                && !yes
            {
                if !is_interactive(
                    global.no_input,
                    rt.terminal.stdin_is_tty,
                    rt.terminal.stderr_is_tty,
                ) {
                    return Err(map_domain(DomainError::InputUnavailable {
                        message: format!(
                            "refusing to overwrite {key} ({prev} -> {canonical}) without confirmation"
                        ),
                        hint: Some("pass --yes to confirm non-interactively".to_owned()),
                    }));
                }
                match rt.prompter.confirm(
                    &format!(
                        "Overwrite {key} ({prev} -> {canonical}) in {}?",
                        active_config_path.display()
                    ),
                    false,
                ) {
                    Ok(Some(true)) => {}
                    Ok(Some(false)) | Ok(None) => {
                        if !global.quiet {
                            let _ = writeln!(rt.stderr, "Aborted.");
                        }
                        return Ok(Exit::Success);
                    }
                    Err(err) => {
                        return Err(map_prompt_err(
                            err,
                            "pass --yes to confirm non-interactively",
                            format,
                            stderr_color,
                        ));
                    }
                }
            }

            let written = set_config_value(&active_config_path, &key, &value).map_err(&map_cfg)?;
            if !global.quiet && !is_machine_format(format) {
                let _ = writeln!(
                    rt.stderr,
                    "Set {key} = {written} in {}",
                    active_config_path.display()
                );
            }
            let view = ConfigValueView {
                key,
                value: Some(written),
                source: "file".to_owned(),
            };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
        ConfigAction::Init { dry_run, yes } => {
            let mut chosen: Vec<(&'static str, String)> = Vec::with_capacity(INIT_KEYS.len());

            if yes {
                for &(key, _) in INIT_KEYS {
                    let current = get_config_value(&loaded.config, key)
                        .map_err(&map_cfg)?
                        .unwrap_or_default();
                    chosen.push((key, current));
                }
            } else if !is_interactive(
                global.no_input,
                rt.terminal.stdin_is_tty,
                rt.terminal.stderr_is_tty,
            ) {
                return Err(map_domain(DomainError::InputUnavailable {
                    message: "config init cannot prompt interactively".to_owned(),
                    hint: Some(
                        "pass --yes to write the current defaults non-interactively".to_owned(),
                    ),
                }));
            } else {
                for &(key, allowed) in INIT_KEYS {
                    let current = get_config_value(&loaded.config, key)
                        .map_err(&map_cfg)?
                        .unwrap_or_default();
                    let default_idx = allowed.iter().position(|&v| v == current).unwrap_or(0);
                    match rt.prompter.select(key, allowed, default_idx) {
                        Ok(Some(val)) => chosen.push((key, val)),
                        Ok(None) => {
                            if !global.quiet {
                                let _ = writeln!(rt.stderr, "Aborted.");
                            }
                            return Ok(Exit::Success);
                        }
                        Err(err) => {
                            return Err(map_prompt_err(
                                err,
                                "pass --yes to write the current defaults non-interactively",
                                format,
                                stderr_color,
                            ));
                        }
                    }
                }
            }

            // R61 revision 3: `config init` evaluates `--dry-run` AFTER guided values.
            if dry_run {
                if !global.quiet {
                    for (key, val) in &chosen {
                        let _ = writeln!(
                            rt.stderr,
                            "[dry-run] would set {key} = {val} in {}",
                            active_config_path.display()
                        );
                    }
                }
                let exists = active_config_path.exists();
                let view = ConfigPathView {
                    path: active_config_path,
                    exists,
                };
                return render_and_deliver(rt, global, &view, format, caps, stderr_color);
            }

            for (key, val) in &chosen {
                set_config_value(&active_config_path, key, val).map_err(&map_cfg)?;
            }
            if !global.quiet && !is_machine_format(format) {
                let _ = writeln!(rt.stderr, "Wrote {}", active_config_path.display());
            }
            let view = ConfigPathView {
                path: active_config_path,
                exists: true,
            };
            render_and_deliver(rt, global, &view, format, caps, stderr_color)
        }
    }
}

fn handle_diagnostics(
    rt: &mut CliRuntime<'_>,
    cli: &Cli,
    bundle: bool,
    ctx: &DispatchCtx<'_>,
) -> Result<Exit, CliError> {
    let global = &cli.global;
    let loaded = ctx.loaded;
    let format = ctx.format;
    let caps = ctx.caps;
    let stderr_color = ctx.stderr_color;
    let info = build_info();
    let cfg_path = ctx.active_config_path.to_path_buf();
    let cfg_exists = cfg_path.exists();

    let token_result = resolve_cli_token(rt, global);
    let (token_present, token_source, token_error) = match token_result {
        Ok(Some(resolved)) => (true, Some(resolved.source.as_str().to_owned()), None),
        Ok(None) => (false, None, None),
        Err(err) => (false, None, Some(err.to_string())),
    };

    let core_diag = run_diagnostics(&DiagnosticsContext {
        config_path: &cfg_path,
        token_source: token_source.as_deref(),
        token_error: token_error.as_deref(),
    });
    let checks: Vec<DiagnosticCheck> = core_diag
        .checks
        .into_iter()
        .map(|c| DiagnosticCheck {
            name: c.name.to_owned(),
            status: c.status.as_str(),
            detail: c.detail,
        })
        .collect();

    let report = DiagnosticsReportView { checks };
    let has_error = report.has_error();

    let exit = if bundle {
        let mut redacted_env = BTreeMap::new();
        for (k, v) in rt.env.iter_prefixed("RSLBP_") {
            let upper = k.to_ascii_uppercase();
            let is_secret = SENSITIVE_ENV_MARKERS
                .iter()
                .any(|marker| upper.contains(marker));
            redacted_env.insert(
                k,
                if is_secret {
                    "[REDACTED]".to_owned()
                } else {
                    v
                },
            );
        }
        let bundle_view = DiagnosticsBundleView {
            version: info.version.to_owned(),
            target: info.target.to_owned(),
            rustc: info.rustc.to_owned(),
            checks: report.checks,
            config_path: cfg_path.display().to_string(),
            config_exists: cfg_exists,
            loaded_paths: loaded
                .sources
                .iter()
                .map(|s| s.path.display().to_string())
                .collect(),
            token_present,
            token_source,
            env: redacted_env,
            log_file: rt.paths.log_file().display().to_string(),
        };
        render_and_deliver(rt, global, &bundle_view, format, caps, stderr_color)?
    } else {
        render_and_deliver(rt, global, &report, format, caps, stderr_color)?
    };

    if has_error {
        Ok(Exit::Runtime)
    } else {
        Ok(exit)
    }
}

fn build_service(
    rt: &mut CliRuntime<'_>,
    global: &GlobalArgs,
) -> Result<ErasedProjectsService, DomainError> {
    if let Some(port) = &rt.injected_port {
        return Ok(ProjectsService::new(Arc::clone(port)));
    }
    let resolved = resolve_cli_token(rt, global)?.ok_or_else(|| {
        DomainError::Auth(AuthError::CredentialsAbsent {
            detail: "no API token configured (never stored in rslbp_config.toml)".to_owned(),
        })
    })?;
    let factory = rt.port_factory.ok_or_else(|| {
        DomainError::Port(PortError::Unavailable {
            detail: "no ProjectsPort factory configured".to_owned(),
        })
    })?;
    Ok(ProjectsService::new(factory(resolved.token)))
}

fn resolve_cli_token(
    rt: &mut CliRuntime<'_>,
    global: &GlobalArgs,
) -> Result<Option<ResolvedToken>, DomainError> {
    let env_token = rt.env.var_string(TOKEN_ENV_VAR);
    let stdin_owned = if global.token_file.as_deref() == Some(Path::new("-")) {
        if let Some(pre) = &rt.stdin_token {
            Some(pre.clone())
        } else {
            let mut buf = String::new();
            io::Read::read_to_string(&mut io::stdin().lock(), &mut buf)
                .map_err(|source| DomainError::Port(PortError::Io { source }))?;
            Some(buf)
        }
    } else {
        None
    };

    let default_store = FileCredentialStore::new(rt.paths.credentials_file());
    let store: &dyn CredentialStore = rt.credential_store.unwrap_or(&default_store);

    let resolution = resolve_token(&TokenResolutionInputs {
        token_file: global.token_file.as_deref(),
        stdin_token: stdin_owned.as_deref(),
        env_token: env_token.as_deref(),
        store: Some(store),
    })?;

    if !global.quiet {
        for warning in &resolution.warnings {
            let _ = writeln!(rt.stderr, "warning: {warning}");
        }
    }

    Ok(resolution.resolved)
}

fn render_and_deliver(
    rt: &mut CliRuntime<'_>,
    global: &GlobalArgs,
    view: &dyn CliView,
    format: OutputFormat,
    caps: TermCaps,
    stderr_color: bool,
) -> Result<Exit, CliError> {
    let mut rendered = Vec::new();
    if let Err(err) = render_view(view, format, caps, &mut rendered) {
        return Err(unexpected_io(err, format, stderr_color));
    }
    deliver_output(rt, global, format, caps, stderr_color, &rendered)
}

fn deliver_output(
    rt: &mut CliRuntime<'_>,
    global: &GlobalArgs,
    format: OutputFormat,
    caps: TermCaps,
    stderr_color: bool,
    bytes: &[u8],
) -> Result<Exit, CliError> {
    // 1. Primary sink FIRST (R62: additive clipboard write happens strictly after primary sink).
    let target_file = global
        .output_file
        .as_deref()
        .filter(|p| *p != Path::new("-"));

    if let Some(path) = target_file {
        write_output_file_atomic(path, bytes, global.no_clobber).map_err(|error| {
            CliError::Domain {
                error,
                format,
                stderr_color,
            }
        })?;
    } else {
        let pager_disabled = global.no_pager || global.no_input || !rt.allow_spawn_pager;
        if let Some(argv) =
            resolve_pager_argv(pager_disabled, format, rt.terminal.stdout_is_tty, rt.env)
            && let Some(mut pager) = PagerWriter::try_spawn(&argv, rt.env)
        {
            match pager.write_all(bytes).and_then(|()| pager.flush()) {
                Ok(()) => pager.finish(),
                Err(err) if err.kind() == io::ErrorKind::BrokenPipe => {
                    pager.finish();
                    return Err(CliError::BrokenPipe);
                }
                Err(_) => {
                    // Never lose output if the pager dies unexpectedly.
                    pager.finish();
                    write_result_bytes_gated(
                        rt.stdout,
                        bytes,
                        caps.color && !is_machine_format(format),
                    )?;
                }
            }
        } else {
            write_result_bytes_gated(rt.stdout, bytes, caps.color && !is_machine_format(format))?;
        }
    }

    // 2. Optional additive `--copy` after primary sink succeeds (R62, owner ruling W1-R62).
    if global.copy {
        let text = String::from_utf8_lossy(bytes);
        rt.clipboard
            .set_text(&text)
            .map_err(|err| CliError::Domain {
                error: DomainError::Clipboard(err),
                format,
                stderr_color,
            })?;
        if !global.quiet {
            let _ = writeln!(rt.stderr, "Copied to clipboard.");
        }
    }

    Ok(Exit::Success)
}

fn write_result_bytes_gated(
    out: &mut (dyn Write + '_),
    bytes: &[u8],
    allow_ansi: bool,
) -> Result<(), CliError> {
    let choice = if allow_ansi {
        ColorChoice::Always
    } else {
        ColorChoice::Never
    };
    let mut filtered = AutoStream::new(Vec::with_capacity(bytes.len()), choice);
    let _ = filtered.write_all(bytes);
    let _ = filtered.flush();
    let final_bytes = filtered.into_inner();
    match out.write_all(&final_bytes).and_then(|()| out.flush()) {
        Ok(()) => Ok(()),
        Err(err) if err.kind() == io::ErrorKind::BrokenPipe => Err(CliError::BrokenPipe),
        Err(source) => Err(CliError::Domain {
            error: DomainError::Port(PortError::Io { source }),
            format: OutputFormat::Table,
            stderr_color: false,
        }),
    }
}

fn parse_env_output_format(env: &dyn EnvLookup) -> Result<Option<OutputFormat>, DomainError> {
    let Some(raw) = env.var_string("RSLBP_OUTPUT") else {
        return Ok(None);
    };
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return Ok(None);
    }
    OutputFormat::from_str(trimmed)
        .map(Some)
        .map_err(|_| DomainError::Usage {
            message: format!("invalid RSLBP_OUTPUT value '{trimmed}'"),
            hint: Some("valid values: table, json, markdown, name".to_owned()),
        })
}

fn map_prompt_err(
    err: PromptError,
    missing_hint: &str,
    format: OutputFormat,
    stderr_color: bool,
) -> CliError {
    match err.into_required_domain_error(missing_hint) {
        Ok(error) => CliError::Domain {
            error,
            format,
            stderr_color,
        },
        Err(message) => CliError::Unexpected {
            message,
            format,
            stderr_color,
            causes: Vec::new(),
        },
    }
}

fn unexpected_io(err: io::Error, format: OutputFormat, stderr_color: bool) -> CliError {
    if err.kind() == io::ErrorKind::BrokenPipe {
        return CliError::BrokenPipe;
    }
    CliError::Unexpected {
        message: err.to_string(),
        format,
        stderr_color,
        causes: vec![err.to_string()],
    }
}

/// Convenience compatibility entrypoint running `rslbp` against a default process environment
/// and an injected-or-none port (`R04`).
pub fn run(info: WorkspaceInfo, args: &[String]) -> ExitCode {
    let _ = info;
    let mut argv = Vec::with_capacity(args.len() + 1);
    argv.push(OsString::from("rslbp"));
    argv.extend(args.iter().map(OsString::from));

    let env = ProcessEnv;
    let cwd = std::env::current_dir().unwrap_or(PathBuf::from("."));
    let paths = match Paths::from_process_env() {
        Ok(p) => p,
        Err(_) => Paths::from_roots(
            cwd.join(".config"),
            cwd.join(".local/share"),
            cwd.join(".local/state"),
            cwd.join(".cache"),
        ),
    };
    let prompter = crate::prompter::InquirePrompter::new(false);
    let clipboard = RecordingClipboard::new();
    let mut stdout = io::stdout().lock();
    let mut stderr = io::stderr().lock();
    let mut runtime = CliRuntime {
        env: &env,
        cwd,
        paths,
        terminal: TerminalState::default(),
        stdin_token: None,
        credential_store: None,
        injected_port: None,
        port_factory: None,
        prompter: &prompter,
        clipboard: &clipboard,
        stdout: &mut stdout,
        stderr: &mut stderr,
        on_telemetry: None,
        allow_spawn_pager: false,
    };

    match execute_cli(&mut runtime, &argv) {
        Ok(exit) => exit.into(),
        Err(err) => emit_cli_error(&err, runtime.stderr).into(),
    }
}

/// Render a [`CliError`] to `stderr`, returning the mapped process [`Exit`] code (`R67`).
///
/// A `BrokenPipe` while writing the error envelope to `stderr` preserves the original
/// application exit code rather than overriding it (`R67`).
#[must_use]
pub fn emit_cli_error(error: &CliError, stderr: &mut dyn Write) -> Exit {
    match error {
        CliError::BrokenPipe => Exit::Success,
        CliError::Domain {
            error,
            format,
            stderr_color,
        } => {
            let hint = error.hint();
            let _ = render_error(
                error.error_code(),
                &error.to_string(),
                hint.as_deref(),
                *format,
                *stderr_color,
                stderr,
            );
            let _ = stderr.flush();
            error.exit()
        }
        CliError::Unexpected {
            message,
            format,
            stderr_color,
            ..
        } => {
            let _ = render_error(
                ErrorCode::Unexpected,
                message,
                None,
                *format,
                *stderr_color,
                stderr,
            );
            let _ = stderr.flush();
            Exit::Runtime
        }
    }
}

/// Check whether raw `argv` invokes the hidden Linux `--clipboard-daemon` helper (`R62`).
#[must_use]
pub fn is_clipboard_daemon_argv(argv: &[OsString]) -> bool {
    argv.iter().skip(1).any(|arg| arg == "--clipboard-daemon")
}

/// Inspect raw `argv` for initial CLI log format/level/debug settings before full execution (`R58`).
#[must_use]
pub fn sniff_initial_log_settings(argv: &[OsString]) -> (bool, Option<crate::args::LogFormatArg>) {
    let mut debug = false;
    let mut log_format = None;
    let mut iter = argv.iter().skip(1).map(|s| s.to_string_lossy());
    while let Some(arg) = iter.next() {
        if arg == "--debug" {
            debug = true;
        } else if let Some(val) = arg.strip_prefix("--log-format=") {
            log_format = parse_log_format_arg(val);
        } else if arg == "--log-format"
            && let Some(val) = iter.next()
        {
            log_format = parse_log_format_arg(&val);
        }
    }
    (debug, log_format)
}

fn parse_log_format_arg(token: &str) -> Option<crate::args::LogFormatArg> {
    match token.trim().to_ascii_lowercase().as_str() {
        "auto" => Some(crate::args::LogFormatArg::Auto),
        "console" => Some(crate::args::LogFormatArg::Console),
        "json" => Some(crate::args::LogFormatArg::Json),
        _ => None,
    }
}
