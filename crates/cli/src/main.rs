//! CLI binary entrypoint (`rslbp`) for `rs-launch-blueprint` (`R58`, `R59`, `R62`, `R67`,
//! `OV-18`).
//!
//! Owns process-wide signal registration (`SIGINT` -> 130, `SIGTERM` -> 143), telemetry
//! initialization, the `anyhow` error boundary, and best-effort `0600` crash record persistence.
//! Direct `println!`/`print!` macros are denied so every write uses fallible locked handles.

#![deny(clippy::print_stdout, clippy::print_stderr)]

use std::env;
use std::ffi::OsString;
use std::io::{self, IsTerminal};
use std::path::PathBuf;
use std::process::ExitCode;
use std::str::FromStr;
use std::sync::Arc;
use std::sync::atomic::AtomicBool;

use rs_launch_blueprint::{
    ColorPreference, DEFAULT_API_BASE_URL, HttpProjectsPort, LogLevel, Paths, ProjectsPort, Token,
};
use rs_launch_blueprint_cli::{
    ArboardClipboard, CliRuntime, CliTelemetryProfile, CrashSink, EnvLookup, Exit, FileCrashSink,
    InquirePrompter, LevelLadderInput, LogFormat, LogFormatArg, NoopCrashSink, ProcessEnv,
    ResolvedTelemetryConfig, TelemetryInit, TerminalState, execute_cli, init_telemetry,
    is_clipboard_daemon_argv, resolve_binary_boundary, resolve_color, resolve_console_level,
    resolve_log_file, resolve_log_format, resolve_stream_color, run_clipboard_daemon,
    sniff_initial_log_settings,
};

fn main() -> ExitCode {
    let argv: Vec<OsString> = env::args_os().collect();

    // R62 Member 3: hidden Linux selection-ownership helper entrypoint.
    if is_clipboard_daemon_argv(&argv) {
        return run_clipboard_daemon();
    }

    // R67 P4: cooperative signal flags (distinct SIGINT 130 vs SIGTERM 143); binary-only!
    let sigint_flag = Arc::new(AtomicBool::new(false));
    let sigterm_flag = Arc::new(AtomicBool::new(false));
    #[cfg(unix)]
    {
        let _ = signal_hook::flag::register(signal_hook::consts::SIGINT, Arc::clone(&sigint_flag));
        let _ =
            signal_hook::flag::register(signal_hook::consts::SIGTERM, Arc::clone(&sigterm_flag));
    }

    let env_lookup = ProcessEnv;
    let stdin_is_tty = io::stdin().is_terminal();
    let stdout_is_tty = io::stdout().is_terminal();
    let stderr_is_tty = io::stderr().is_terminal();

    // R58: initialize telemetry FIRST before anything that can log.
    let (debug_hint, log_fmt_flag) = sniff_initial_log_settings(&argv);
    let env_log_fmt = env_lookup
        .var_string("RSLBP_LOG_FORMAT")
        .and_then(|s| LogFormat::from_str(&s).ok());
    let flag_log_fmt = log_fmt_flag.map(|f| match f {
        LogFormatArg::Auto => LogFormat::Auto,
        LogFormatArg::Console => LogFormat::Console,
        LogFormatArg::Json => LogFormat::Json,
    });
    let initial_log_format = resolve_log_format(flag_log_fmt, env_log_fmt);
    let initial_color_choice = resolve_color(None, ColorPreference::Auto, &env_lookup);
    let initial_stderr_color =
        resolve_stream_color(initial_color_choice, stderr_is_tty, &env_lookup);
    let telemetry_handles = match init_telemetry(CliTelemetryProfile {
        format: initial_log_format,
        level: if debug_hint {
            LogLevel::Trace
        } else {
            LogLevel::Warn
        },
        ansi: initial_stderr_color,
        debug: debug_hint,
    }) {
        TelemetryInit::Installed(handles) => Some(handles),
        TelemetryInit::HostOwned => None,
    };

    let cwd = env::current_dir().unwrap_or_else(|_| PathBuf::from("."));
    let resolved_paths = Paths::from_process_env().ok();
    let crash_sink_box: Box<dyn CrashSink> = match &resolved_paths {
        Some(paths) => Box::new(FileCrashSink::new(paths.crash_log_file())),
        None => Box::new(NoopCrashSink),
    };
    let paths = resolved_paths.unwrap_or_else(|| {
        Paths::from_roots(
            cwd.join(".config"),
            cwd.join(".local/share"),
            cwd.join(".local/state"),
            cwd.join(".cache"),
        )
    });

    let base_url = env_lookup
        .var_string("RSLBP_API_BASE_URL")
        .filter(|s| !s.trim().is_empty())
        .unwrap_or_else(|| DEFAULT_API_BASE_URL.to_owned());
    let port_factory = move |token: Token| -> Arc<dyn ProjectsPort> {
        Arc::new(HttpProjectsPort::new(base_url.clone(), token))
    };

    let prompter = InquirePrompter::new(initial_stderr_color);
    let clipboard = ArboardClipboard::new();

    let mut telemetry_hook = |resolved: &ResolvedTelemetryConfig| {
        if let Some(handles) = &telemetry_handles {
            let level = resolve_console_level(&LevelLadderInput {
                debug: resolved.debug,
                log_level_flag: resolved.log_level_flag,
                quiet: resolved.quiet,
                verbose: resolved.verbose,
                env_log_level: resolved.env_log_level,
                config_log_level: Some(resolved.config_log_level),
            });
            let _ = handles.reload_level(level);

            if let Some(log_path) = resolve_log_file(
                resolved.log_file_flag.clone(),
                resolved.env_log_file.clone(),
                resolved.config_log_file.as_deref(),
                || Some(resolved.paths.log_file()),
            ) {
                let file_level = resolved.file_level.unwrap_or(LogLevel::Debug);
                if let Err(err) =
                    handles.attach_file_sink(&log_path, file_level, resolved.file_format)
                {
                    tracing::warn!(
                        path = %log_path.display(),
                        error = %err,
                        "could not open rotating log file; continuing without file sink"
                    );
                }
            }
        }
    };

    let mut stdout = io::stdout().lock();
    let mut stderr = io::stderr().lock();

    let outcome: anyhow::Result<Exit> = {
        let mut runtime = CliRuntime {
            env: &env_lookup,
            cwd,
            paths,
            terminal: TerminalState {
                stdin_is_tty,
                stdout_is_tty,
                stderr_is_tty,
                hyperlinks_override: None,
            },
            stdin_token: None,
            credential_store: None,
            injected_port: None,
            port_factory: Some(&port_factory),
            prompter: &prompter,
            clipboard: &clipboard,
            stdout: &mut stdout,
            stderr: &mut stderr,
            on_telemetry: Some(&mut telemetry_hook),
            allow_spawn_pager: true,
        };
        execute_cli(&mut runtime, &argv).map_err(anyhow::Error::new)
    };

    resolve_binary_boundary(
        outcome,
        &sigint_flag,
        &sigterm_flag,
        crash_sink_box.as_ref(),
        &mut stdout,
        &mut stderr,
    )
    .into()
}
